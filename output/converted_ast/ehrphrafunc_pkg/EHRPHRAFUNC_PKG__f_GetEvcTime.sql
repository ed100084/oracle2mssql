CREATE OR ALTER FUNCTION [ehrphrafunc_pkg].[f_GetEvcTime]
(    @empno_in NVARCHAR(MAX),
    @date_in NVARCHAR(MAX)
)
RETURNS NVARCHAR(MAX)
AS
BEGIN
DECLARE @Putout NVARCHAR(500);
DECLARE @Ptmp NVARCHAR(100);
DECLARE @Pcount DECIMAL(38,10);
DECLARE @Dcount DECIMAL(38,10);
DECLARE CUR_VAC CURSOR FOR
    SELECT (SELECT VAC_NAME
                FROM HRA_VCRLMST
               WHERE VAC_TYPE = HRA_EVCREC.VAC_TYPE) + ',' + (CASE
               WHEN START_DATE = END_DATE THEN
                FORMAT(START_DATE, 'yyyy-mm-dd') + ' ' + START_TIME + '~' +
                END_TIME
               ELSE
                FORMAT(START_DATE, 'yyyy-mm-dd') + ' ' + START_TIME + '~' +
                FORMAT(END_DATE, 'yyyy-mm-dd') + ' ' + END_TIME
             END) + ',' + VAC_DAYS + '天' + VAC_HRS + '小時'
        FROM HRA_EVCREC
       WHERE EMP_NO = @empno_in
         AND @date_in BETWEEN FORMAT(START_DATE, 'yyyy-mm-dd') AND
             FORMAT(END_DATE, 'yyyy-mm-dd')
         AND STATUS NOT IN ('N', 'D')
      UNION ALL
      SELECT '用補休,' + (CASE
               WHEN START_DATE = END_DATE THEN
                FORMAT(START_DATE, 'yyyy-mm-dd') + ' ' + START_TIME + '~' +
                END_TIME
               ELSE
                FORMAT(START_DATE, 'yyyy-mm-dd') + ' ' + START_TIME + '~' +
                FORMAT(END_DATE, 'yyyy-mm-dd') + ' ' + END_TIME
             END) + ',' + (CASE
               WHEN SUP_HRS < 1 THEN
                '0' + SUP_HRS
               ELSE
                CAST(SUP_HRS AS NVARCHAR)
             END) + '小時'
        FROM HRA_SUPMST
       WHERE EMP_NO = @empno_in
         AND FORMAT(START_DATE_TMP, 'yyyy-mm-dd') = @date_in
         AND STATUS <> 'N';
DECLARE CUR_DOCVAC CURSOR FOR
    SELECT (SELECT VAC_NAME
                FROM HRA_DVCRLMST
               WHERE VAC_TYPE = HRA_DEVCREC.VAC_TYPE) + ',' + (CASE
               WHEN START_DATE = END_DATE THEN
                FORMAT(START_DATE, 'yyyy-mm-dd') + ' ' + START_TIME + '~' +
                END_TIME
               ELSE
                FORMAT(START_DATE, 'yyyy-mm-dd') + ' ' + START_TIME + '~' +
                FORMAT(END_DATE, 'yyyy-mm-dd') + ' ' + END_TIME
             END) + ',' + VAC_DAYS + '天' + VAC_HRS + '小時'
        FROM HRA_DEVCREC
       WHERE EMP_NO = @empno_in
         AND @date_in BETWEEN FORMAT(START_DATE, 'yyyy-mm-dd') AND
             FORMAT(END_DATE, 'yyyy-mm-dd')
         AND STATUS NOT IN ('N')
         AND DIS_AGENT NOT IN ('Y');
    SET @Ptmp = '';
    SET @Putout = '';
    SET @Pcount = 0;
    SET @Dcount = 0;
  
    SELECT @Pcount = COUNT(*)
    FROM (SELECT EMP_NO
              FROM HRA_EVCREC
             WHERE EMP_NO = @empno_in
               AND @date_in BETWEEN FORMAT(START_DATE, 'yyyy-mm-dd') AND
                   FORMAT(END_DATE, 'yyyy-mm-dd')
               AND STATUS NOT IN ('N', 'D')
            UNION ALL
            SELECT EMP_NO
              FROM HRA_SUPMST
             WHERE EMP_NO = @empno_in
               AND FORMAT(START_DATE_TMP, 'yyyy-mm-dd') = @date_in
               AND STATUS <> 'N') AS _dt1;
  
    SELECT @Dcount = COUNT(*)
    FROM HRA_DEVCREC
     WHERE EMP_NO = @empno_in
       AND @date_in BETWEEN FORMAT(START_DATE, 'yyyy-mm-dd') AND
           FORMAT(END_DATE, 'yyyy-mm-dd')
       AND STATUS NOT IN ('N')
       AND DIS_AGENT NOT IN ('Y');
  
    IF @Pcount > 0 BEGIN
      OPEN CUR_VAC;
      WHILE 1=1 BEGIN
        FETCH NEXT FROM CUR_VAC INTO @Ptmp;
        IF @@FETCH_STATUS <> 0 BREAK;
        IF @Putout IS NULL BEGIN
          SET @Putout = @Ptmp;
        END
        ELSE
        BEGIN
          SET @Putout = @Putout + ';' + @Ptmp;
        END
      END
      CLOSE CUR_VAC;
    DEALLOCATE CUR_VAC
    END
ELSE IF @Dcount > 0 BEGIN
      OPEN CUR_DOCVAC;
      WHILE 1=1 BEGIN
        FETCH NEXT FROM CUR_DOCVAC INTO @Ptmp;
        IF @@FETCH_STATUS <> 0 BREAK;
        IF @Putout IS NULL BEGIN
          SET @Putout = @Ptmp;
        END
        ELSE
        BEGIN
          SET @Putout = @Putout + ';' + @Ptmp;
        END
      END
      CLOSE CUR_DOCVAC;
    DEALLOCATE CUR_DOCVAC
    END
  
    RETURN @Putout;
END
GO
