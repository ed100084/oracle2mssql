CREATE OR ALTER FUNCTION [ehrphrafunc_pkg].[f_GetHraTime]
(    @empno_in NVARCHAR(MAX),
    @date_in NVARCHAR(MAX),
    @flag_in NVARCHAR(MAX),
    @type_in NVARCHAR(MAX),
    @num_in DECIMAL(38,10)
)
RETURNS NVARCHAR(MAX)
AS
BEGIN
DECLARE @Putout1 NVARCHAR(50);
DECLARE @Putout2 NVARCHAR(50);
DECLARE @Putout3 NVARCHAR(50);
DECLARE @Putout NVARCHAR(50);
DECLARE @Ptmp NVARCHAR(50);
DECLARE @Ptmp2 NVARCHAR(50);
DECLARE @Phrs NVARCHAR(50);
DECLARE @Phrs2 NVARCHAR(50);
DECLARE @Pcount DECIMAL(38,10);
DECLARE @Prun DECIMAL(38,10);
DECLARE CUR_OTM_A_S CURSOR FOR
    SELECT START_TIME
        FROM HRA_OTMSIGN
       WHERE EMP_NO = @empno_in
         AND FORMAT(START_DATE, 'yyyy-mm-dd') = @date_in
         AND OTM_FLAG = @flag_in;
DECLARE CUR_OTM_A_E CURSOR FOR
    SELECT END_TIME
        FROM HRA_OTMSIGN
       WHERE EMP_NO = @empno_in
         AND FORMAT(END_DATE, 'yyyy-mm-dd') = @date_in
         AND OTM_FLAG = @flag_in;
DECLARE CUR_ADD CURSOR FOR
    SELECT START_TIME + '-' + END_TIME,
             (CASE
               WHEN OTM_HRS < 1 THEN
                '0' + OTM_HRS
               ELSE
                CAST(OTM_HRS AS NVARCHAR)
             END),
             (CASE
               WHEN OTM_HRS < 1 THEN
                '0' + OTM_HRS
               ELSE
                CAST(OTM_HRS AS NVARCHAR)
             END),
             '補休' + CASE WHEN STATUS = 'Y' THEN 'Y' ELSE 'U' END
        FROM HRA_OTMSIGN
       WHERE EMP_NO = @empno_in
         AND FORMAT(ISNULL(START_DATE_TMP, START_DATE), 'yyyy-mm-dd') =
             @date_in
         AND STATUS <> 'N'
         AND OTM_FLAG = 'B'
      UNION ALL
      SELECT START_TIME + '-' + END_TIME,
             (CASE
               WHEN OTM_HRS < 1 THEN
                '0' + OTM_HRS
               ELSE
                CAST(OTM_HRS AS NVARCHAR)
             END),
             (CASE
               WHEN SOTM_HRS < 1 THEN
                '0' + SOTM_HRS
               ELSE
                CAST(SOTM_HRS AS NVARCHAR)
             END),
             '加班費' + CASE WHEN STATUS = 'Y' THEN 'Y' ELSE 'U' END
        FROM HRA_OFFREC
       WHERE EMP_NO = @empno_in
         AND FORMAT(ISNULL(START_DATE_TMP, START_DATE), 'yyyy-mm-dd') =
             @date_in
         AND STATUS <> 'N'
         AND ITEM_TYPE = 'A'
       ORDER BY 1;
DECLARE CUR_VAC CURSOR FOR
    SELECT (CASE
               WHEN START_DATE = END_DATE THEN
                FORMAT(START_DATE, 'yyyy-mm-dd') + ' ' + START_TIME + '~' +
                END_TIME
               ELSE
                FORMAT(START_DATE, 'yyyy-mm-dd') + ' ' + START_TIME + '~' +
                FORMAT(END_DATE, 'yyyy-mm-dd') + ' ' + END_TIME
             END),
             VAC_TYPE +
             (SELECT VAC_NAME
                FROM HRA_VCRLMST
               WHERE VAC_TYPE = HRA_EVCREC.VAC_TYPE) +
             CASE WHEN STATUS = 'Y' THEN 'Y' ELSE 'U' END,
             CAST(VAC_DAYS * 8 + VAC_HRS AS NVARCHAR)
        FROM HRA_EVCREC
       WHERE EMP_NO = @empno_in
            
         AND @date_in BETWEEN FORMAT(START_DATE, 'yyyy-mm-dd') AND
             FORMAT(END_DATE, 'yyyy-mm-dd')
         AND STATUS NOT IN ('N', 'D')
      UNION ALL
      SELECT (CASE
               WHEN START_DATE = END_DATE THEN
                FORMAT(START_DATE, 'yyyy-mm-dd') + ' ' + START_TIME + '~' +
                END_TIME
               ELSE
                FORMAT(START_DATE, 'yyyy-mm-dd') + ' ' + START_TIME + '~' +
                FORMAT(END_DATE, 'yyyy-mm-dd') + ' ' + END_TIME
             END),
             '用補休' + CASE WHEN STATUS = 'Y' THEN 'Y' ELSE 'U' END,
             (CASE
               WHEN SUP_HRS < 1 THEN
                '0' + SUP_HRS
               ELSE
                CAST(SUP_HRS AS NVARCHAR)
             END)
        FROM HRA_SUPMST
       WHERE EMP_NO = @empno_in
         AND FORMAT(START_DATE_TMP, 'yyyy-mm-dd') = @date_in
         AND STATUS <> 'N'
      UNION ALL
      SELECT (CASE
               WHEN START_DATE = END_DATE THEN
                FORMAT(START_DATE, 'yyyy-mm-dd') + ' ' + START_TIME + '~' +
                END_TIME
               ELSE
                FORMAT(START_DATE, 'yyyy-mm-dd') + ' ' + START_TIME + '~' +
                FORMAT(END_DATE, 'yyyy-mm-dd') + ' ' + END_TIME
             END),
             '外出單' + CASE WHEN STATUS = 'Y' THEN 'Y' ELSE 'U' END,
             CAST(OUT_DAYS * 8 + OUT_HRS AS NVARCHAR)
        FROM HRA_OUTREC
       WHERE EMP_NO = @empno_in
         AND FORMAT(START_DATE, 'yyyy-mm-dd') = @date_in
         AND STATUS <> 'N'
         AND PERMIT_HR <> 'Y'
       ORDER BY 1;
    SET @Ptmp = '';
    SET @Ptmp2 = '';
    SET @Putout1 = '';
    SET @Putout2 = '';
    SET @Putout3 = '';
    SET @Putout = '';
    SET @Pcount = 0;
    SET @Prun = 0;
  
    IF @flag_in = 'A' BEGIN
      IF @type_in = 'IN' BEGIN
        SELECT @Pcount = COUNT(emp_no)
    FROM HRA_OTMSIGN
         WHERE EMP_NO = @empno_in
           AND FORMAT(START_DATE, 'yyyy-mm-dd') = @date_in
           AND OTM_FLAG = @flag_in;
        OPEN CUR_OTM_A_S;
        WHILE 1=1 BEGIN
          FETCH NEXT FROM CUR_OTM_A_S INTO @Ptmp;
          IF @@FETCH_STATUS <> 0 BREAK;
          SET @Prun = @Prun + 1;
          IF @num_in <= @Pcount AND @num_in <= @Prun BEGIN
            IF @Prun = @num_in AND @num_in = 1 BEGIN
              SET @Putout1 = @Ptmp;
            END
ELSE IF @Prun = @num_in AND @num_in = 2 BEGIN
              SET @Putout2 = @Ptmp;
            END
ELSE IF @Prun = @num_in AND @num_in = 3 BEGIN
              SET @Putout3 = @Ptmp;
              IF @Pcount > 3 BEGIN
                SET @Putout3 = @Putout3 + '有' + @Pcount + '筆';
              END
            END
          END
        END
        CLOSE CUR_OTM_A_S;
    DEALLOCATE CUR_OTM_A_S
      END
      ELSE
      BEGIN
        SELECT @Pcount = COUNT(emp_no)
    FROM HRA_OTMSIGN
         WHERE EMP_NO = @empno_in
           AND FORMAT(END_DATE, 'yyyy-mm-dd') = @date_in
           AND OTM_FLAG = @flag_in;
        OPEN CUR_OTM_A_E;
        WHILE 1=1 BEGIN
          FETCH NEXT FROM CUR_OTM_A_E INTO @Ptmp2;
          IF @@FETCH_STATUS <> 0 BREAK;
          SET @Prun = @Prun + 1;
          IF @num_in <= @Pcount AND @num_in <= @Prun BEGIN
            IF @Prun = @num_in AND @num_in = 1 BEGIN
              SET @Putout1 = @Ptmp2;
            END
ELSE IF @Prun = @num_in AND @num_in = 2 BEGIN
              SET @Putout2 = @Ptmp2;
            END
ELSE IF @Prun = @num_in AND @num_in = 3 BEGIN
              SET @Putout3 = @Ptmp2;
              IF @Pcount > 3 BEGIN
                SET @Putout3 = @Putout3 + '有' + @Pcount + '筆';
              END
            END
          END
        END
        CLOSE CUR_OTM_A_E;
    DEALLOCATE CUR_OTM_A_E
      END
    
      /*SELECT COUNT(emp_no)
        INTO @Pcount
        FROM HRA_OTMSIGN
       WHERE EMP_NO = @empno_in
         AND FORMAT(START_DATE, 'yyyy-mm-dd') = @date_in
         AND OTM_FLAG = @flag_in;
      
      OPEN CUR_OTM_A;
      WHILE 1=1 BEGIN
      FETCH NEXT FROM CUR_OTM_A INTO @Ptmp, @Ptmp2;
      IF @@FETCH_STATUS <> 0 BREAK;
        SET @Prun = @Prun+1;
        IF @num_in <= @Pcount AND @num_in <= @Prun BEGIN
          IF @Prun = @num_in AND @num_in = 1 BEGIN
            IF @type_in = 'IN' BEGIN SET @Putout1 = @Ptmp;
            END
            ELSE
            BEGIN
                SET @Putout1 = @Ptmp2;
            END
          END
ELSE IF @Prun = @num_in AND @num_in = 2 BEGIN
            IF @type_in = 'IN' BEGIN SET @Putout2 = @Ptmp;
            END
            ELSE
            BEGIN
                SET @Putout2 = @Ptmp2;
            END
          END
ELSE IF @Prun = @num_in AND @num_in = 3 BEGIN
            IF @type_in = 'IN' BEGIN SET @Putout3 = @Ptmp;
            END
            ELSE
            BEGIN
                SET @Putout3 = @Ptmp2;
            END
            IF @Pcount > 3 BEGIN
              SET @Putout3 = @Putout3+'有'+@Pcount+'筆';
            END
          END
        END
      END
      CLOSE CUR_OTM_A;
    DEALLOCATE CUR_OTM_A*/
    
    END
ELSE IF @flag_in = 'ADD' BEGIN
      SELECT @Pcount = COUNT(*)
    FROM (SELECT EMP_NO
                FROM HRA_OTMSIGN
               WHERE EMP_NO = @empno_in
                 AND FORMAT(ISNULL(START_DATE_TMP, START_DATE), 'yyyy-mm-dd') =
                     @date_in
                 AND STATUS <> 'N'
                 AND OTM_FLAG = 'B'
              UNION ALL
              SELECT EMP_NO
                FROM HRA_OFFREC
               WHERE EMP_NO = @empno_in
                 AND FORMAT(ISNULL(START_DATE_TMP, START_DATE), 'yyyy-mm-dd') =
                     @date_in
                 AND STATUS <> 'N'
                 AND ITEM_TYPE = 'A') AS _dt1;
      IF @type_in = 'CON' BEGIN
        SET @Putout = @Pcount;
      END
      ELSE
      BEGIN
        OPEN CUR_ADD;
        WHILE 1=1 BEGIN
          FETCH NEXT FROM CUR_ADD INTO @Ptmp, @Phrs, @Phrs2, @Ptmp2;
          IF @@FETCH_STATUS <> 0 BREAK;
          SET @Prun = @Prun + 1;
          IF @num_in <= @Pcount AND @num_in <= @Prun BEGIN
            IF @Prun = @num_in AND @num_in = 1 BEGIN
              IF @type_in = 'T' BEGIN
                SET @Putout1 = @Ptmp; --時間
              END
ELSE IF @type_in = 'H' BEGIN
                SET @Putout1 = @Phrs; --加班(成)時數
              END
ELSE IF @type_in = 'N' BEGIN
                SET @Putout1 = @Ptmp2; --類別(補休 or 加班費)
              END
              ELSE
              BEGIN
                SET @Putout1 = @Phrs2; --原時數(補休原時數為0)
              END
            END
ELSE IF @Prun = @num_in AND @num_in = 2 BEGIN
              IF @type_in = 'T' BEGIN
                SET @Putout2 = @Ptmp;
              END
ELSE IF @type_in = 'H' BEGIN
                SET @Putout2 = @Phrs; --加班(成)時數
              END
ELSE IF @type_in = 'N' BEGIN
                SET @Putout2 = @Ptmp2; --類別(補休 or 加班費)
              END
              ELSE
              BEGIN
                SET @Putout2 = @Phrs2; --原時數(補休原時數為0)
              END
            END
ELSE IF @Prun = @num_in AND @num_in = 3 BEGIN
              IF @type_in = 'T' BEGIN
                SET @Putout3 = @Ptmp;
                IF @Pcount > 3 BEGIN
                  SET @Putout3 = @Putout3 + '有' + @Pcount + '筆';
                END
              END
ELSE IF @type_in = 'H' BEGIN
                SET @Putout3 = @Phrs; --加班(成)時數
              END
ELSE IF @type_in = 'N' BEGIN
                SET @Putout3 = @Ptmp2; --類別(補休 or 加班費)
              END
              ELSE
              BEGIN
                SET @Putout3 = @Phrs2; --原時數(補休原時數為0)
              END
            END
          END
        END
        CLOSE CUR_ADD;
    DEALLOCATE CUR_ADD
      END
    END
ELSE IF @flag_in = 'VAC' BEGIN
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
                 AND STATUS <> 'N'
              UNION ALL
              SELECT EMP_NO
                FROM HRA_OUTREC
               WHERE EMP_NO = @empno_in
                 AND FORMAT(START_DATE, 'yyyy-mm-dd') = @date_in
                 AND STATUS <> 'N'
                 AND PERMIT_HR <> 'Y') AS _dt2;
    
      OPEN CUR_VAC;
      WHILE 1=1 BEGIN
        FETCH NEXT FROM CUR_VAC INTO @Ptmp, @Ptmp2, @Phrs;
        IF @@FETCH_STATUS <> 0 BREAK;
        SET @Prun = @Prun + 1;
        IF @num_in <= @Pcount AND @num_in <= @Prun BEGIN
          IF @Prun = @num_in AND @num_in = 1 BEGIN
            IF @type_in = 'T' BEGIN
              SET @Putout1 = @Ptmp;
            END
ELSE IF @type_in = 'N' BEGIN
              SET @Putout1 = @Ptmp2; --類別(假卡 or 用補休)
            END
            ELSE
            BEGIN
              SET @Putout1 = @Phrs; --時數
            END
          END
ELSE IF @Prun = @num_in AND @num_in = 2 BEGIN
            IF @type_in = 'T' BEGIN
              SET @Putout2 = @Ptmp;
            END
ELSE IF @type_in = 'N' BEGIN
              SET @Putout2 = @Ptmp2; --類別(假卡 or 用補休)
            END
            ELSE
            BEGIN
              SET @Putout2 = @Phrs; --時數
            END
          END
ELSE IF @Prun = @num_in AND @num_in = 3 BEGIN
            IF @type_in = 'T' BEGIN
              SET @Putout3 = @Ptmp;
              IF @Pcount > 3 BEGIN
                SET @Putout3 = @Putout3 + '有' + @Pcount + '筆';
              END
            END
ELSE IF @type_in = 'N' BEGIN
              SET @Putout3 = @Ptmp2; --類別(假卡 or 用補休)
            END
            ELSE
            BEGIN
              SET @Putout3 = @Phrs; --時數
            END
          END
        END
      END
      CLOSE CUR_VAC;
    DEALLOCATE CUR_VAC
    END
    ELSE
    BEGIN
      SET @Putout = '無可取值代碼';
    END
  
    IF @Putout1 IS NOT NULL BEGIN
      SET @Putout = @Putout1;
    END
ELSE IF @Putout2 IS NOT NULL BEGIN
      SET @Putout = @Putout2;
    END
ELSE IF @Putout3 IS NOT NULL BEGIN
      SET @Putout = @Putout3;
    END
  
    RETURN @Putout;
END
GO
