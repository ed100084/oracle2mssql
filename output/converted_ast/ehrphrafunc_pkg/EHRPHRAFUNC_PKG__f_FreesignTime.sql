CREATE OR ALTER FUNCTION [ehrphrafunc_pkg].[f_FreesignTime]
(    @EmpNo_IN NVARCHAR(MAX),
    @Date_IN DATETIME2(0),
    @Type_IN NVARCHAR(MAX),
    @CheckTime NVARCHAR(MAX),
    @Class_IN NVARCHAR(MAX)
)
RETURNS NVARCHAR(MAX)
AS
BEGIN
DECLARE @suphrs DECIMAL(38,10);
DECLARE @evchrs DECIMAL(38,10);
DECLARE @output NVARCHAR(70);
DECLARE @supstart NVARCHAR(4);
DECLARE @supend NVARCHAR(4);
DECLARE @evcstart NVARCHAR(4);
DECLARE @evcend NVARCHAR(4);
DECLARE @rec_evcdata NVARCHAR(MAX) /*cur_evcdata%ROWTYPE*/;
DECLARE @vactype NVARCHAR(100);
DECLARE cur_evcdata CURSOR FOR
    SELECT DISTINCT CASE WHEN A.VAC_TYPE IN ('E','P','S','U') 
           THEN ISNULL(SUBSTRING(M.VAC_NAME, 1, CHARINDEX('(', M.VAC_NAME) - 1), M.VAC_NAME)+'('+D.RUL_NAME+')'
           ELSE ISNULL(SUBSTRING(M.VAC_NAME, 1, CHARINDEX('(', M.VAC_NAME) - 1), M.VAC_NAME) END AS VACNAME
      FROM HRA_EVCREC A, HRA_VCRLMST M, HRA_VCRLDTL D
     WHERE EMP_NO = @EmpNo_IN
       AND @Date_IN BETWEEN START_DATE AND END_DATE
       AND STATUS NOT IN ('N','D')
       AND A.VAC_TYPE = M.VAC_TYPE
       AND A.VAC_RUL = D.VAC_RUL;
    SET @output = NULL;
    SET @vactype = NULL;
    
    IF @Class_IN LIKE 'Z%' BEGIN
      -- EXCEPTION block removed: TRY/CATCH not allowed in T-SQL scalar function

    SELECT @output = HOLI_NAME
    FROM HRA_HOLIDAY
       WHERE HOLI_DATE = @Date_IN;

      IF @output IS NOT NULL BEGIN
        GOTO Continue_ForEach1;
      END
    END
    
    SELECT @suphrs = ISNULL(SUM(SUP_HRS),0)
    FROM HRA_SUPMST
     WHERE EMP_NO = @EmpNo_IN
       AND START_DATE = @Date_IN
       AND STATUS <> 'N';
       
    SELECT @evchrs = ISNULL(SUM(VAC_DAYS*8+VAC_HRS),0)
    FROM HRA_EVCREC
     WHERE EMP_NO = @EmpNo_IN
       AND START_DATE = @Date_IN
       AND STATUS NOT IN ('N','D');
    
    IF @suphrs <> 0 BEGIN
      SELECT @supstart = START_TIME, @supend = END_TIME
    FROM HRA_SUPMST
       WHERE EMP_NO = @EmpNo_IN
         AND START_DATE = @Date_IN
         AND STATUS <> 'N';
    END
    
    IF @evchrs <> 0 BEGIN
      SELECT @evcstart = MIN(START_TIME), @evcend = MAX(END_TIME)
    FROM HRA_EVCREC
       WHERE EMP_NO = @EmpNo_IN
         AND START_DATE = @Date_IN
         AND STATUS <> 'N';
      OPEN cur_evcdata;
      WHILE 1=1 BEGIN
      FETCH NEXT FROM cur_evcdata INTO @rec_evcdata;
      IF @@FETCH_STATUS <> 0 BREAK;
        IF @vactype IS NULL BEGIN
          SET @vactype = @rec_evcdata;
        END
        ELSE
        BEGIN
          SET @vactype = @vactype+','+@rec_evcdata;
        END
      END
      CLOSE cur_evcdata;
    DEALLOCATE cur_evcdata
    END
    ELSE
    BEGIN
      SELECT @evchrs = ISNULL(SUM(VAC_DAYS*8+VAC_HRS),0)
    FROM HRA_EVCREC
       WHERE EMP_NO = @EmpNo_IN
         AND END_DATE = @Date_IN
         AND STATUS NOT IN ('N','D');
      IF @evchrs <> 0 BEGIN
        SELECT @evcstart = MIN(START_TIME), @evcend = MAX(END_TIME)
    FROM HRA_EVCREC
         WHERE EMP_NO = @EmpNo_IN
           AND END_DATE = @Date_IN
           AND STATUS <> 'N';
        OPEN cur_evcdata;
        WHILE 1=1 BEGIN
        FETCH NEXT FROM cur_evcdata INTO @rec_evcdata;
        IF @@FETCH_STATUS <> 0 BREAK;
          IF @vactype IS NULL BEGIN
            SET @vactype = @rec_evcdata;
          END
          ELSE
          BEGIN
            SET @vactype = @vactype+','+@rec_evcdata;
          END
        END
        CLOSE cur_evcdata;
    DEALLOCATE cur_evcdata
      END
      ELSE
      BEGIN
        SELECT @evchrs = ISNULL(SUM(VAC_DAYS*8+VAC_HRS),0)
    FROM HRA_EVCREC
         WHERE EMP_NO = @EmpNo_IN
           AND START_DATE < @Date_IN
           AND END_DATE > @Date_IN
           AND STATUS NOT IN ('N','D');
        IF @evchrs <> 0 BEGIN
          SELECT @evcstart = MIN(START_TIME), @evcend = MAX(END_TIME)
    FROM HRA_EVCREC
           WHERE EMP_NO = @EmpNo_IN
             AND START_DATE < @Date_IN
             AND END_DATE > @Date_IN
             AND STATUS <> 'N';
          OPEN cur_evcdata;
          WHILE 1=1 BEGIN
          FETCH NEXT FROM cur_evcdata INTO @rec_evcdata;
          IF @@FETCH_STATUS <> 0 BREAK;
            IF @vactype IS NULL BEGIN
              SET @vactype = @rec_evcdata;
            END
            ELSE
            BEGIN
              SET @vactype = @vactype+','+@rec_evcdata;
            END
          END
          CLOSE cur_evcdata;
    DEALLOCATE cur_evcdata
        END
      END
    END
    
    IF @suphrs <> 0 AND @evchrs = 0 BEGIN
      IF @suphrs >= 8 BEGIN
        SET @output = 'NO';
        IF @Type_IN IN ('inreadesc', 'outreadesc') BEGIN
          SET @output = '補休假';
        END
      END
      ELSE
      BEGIN
        IF @Type_IN IN ('in', 'inreadesc') BEGIN
          IF @supstart = @CheckTime BEGIN --從上班時間開始休
            SET @output = @supend;
            IF @Class_IN = 'DK' AND @supend BETWEEN '1200' AND '1330' BEGIN
              SET @output = '1330';
            END
ELSE IF @Class_IN = 'BE' AND @supend BETWEEN '1200' AND '1300' BEGIN
              SET @output = '1300';
            END
            IF @Type_IN IN ('inreadesc') BEGIN
              SET @output = '補休假';
            END
          END
          ELSE
          BEGIN
            SET @output = @CheckTime;
          END
        END
ELSE IF @Type_IN IN ('out', 'outreadesc') BEGIN 
          IF @supend = @CheckTime BEGIN --休到下班時間
            SET @output = @supstart;
            IF @Class_IN = 'DK' AND @supstart BETWEEN '1200' AND '1330' BEGIN
              SET @output = '1200';
            END
ELSE IF @Class_IN = 'BE' AND @supstart BETWEEN '1200' AND '1300' BEGIN
              SET @output = '1200';
            END
            IF @Type_IN IN ('outreadesc') BEGIN
              SET @output = '補休假';
            END
          END
          ELSE
          BEGIN
            SET @output = @CheckTime;
          END
        END
      END
    END
ELSE IF @suphrs = 0 AND @evchrs <> 0 BEGIN
      IF @evchrs < 8 BEGIN --確定只請一天內
        IF @Type_IN IN ('in', 'inreadesc') BEGIN
          IF @evcstart = @CheckTime BEGIN --從上班時間開始休
            SET @output = @evcend;
            IF @Class_IN = 'DK' AND @evcend BETWEEN '1200' AND '1330' BEGIN
              SET @output = '1330';
            END
ELSE IF @Class_IN = 'BE' AND @evcend BETWEEN '1200' AND '1300' BEGIN
              SET @output = '1300';
            END
            IF @Type_IN IN ('inreadesc') BEGIN
              SET @output = @vactype;
            END
          END
          ELSE
          BEGIN
            SET @output = @CheckTime;
          END
        END
ELSE IF @Type_IN IN ('out', 'outreadesc') BEGIN 
          IF @evcend = @CheckTime BEGIN --休到下班時間
            SET @output = @evcstart;
            IF @Class_IN = 'DK' AND @evcstart BETWEEN '1200' AND '1330' BEGIN
              SET @output = '1200';
            END
ELSE IF @Class_IN = 'BE' AND @evcstart BETWEEN '1200' AND '1300' BEGIN
              SET @output = '1200';
            END
            IF @Type_IN IN ('outreadesc') BEGIN
              SET @output = @vactype;
            END
          END
          ELSE
          BEGIN
            SET @output = @CheckTime;
          END
        END
      END
      ELSE
      BEGIN --請一天(含)以上，該天不需打卡
        SET @output = 'NO';
        IF @Type_IN IN ('inreadesc', 'outreadesc') BEGIN
          SET @output = @vactype;
        END
      END
    END
ELSE IF @suphrs <> 0 AND @evchrs <> 0 BEGIN
      IF NOT (@suphrs + @evchrs < 8) BEGIN --請一天(含)以上，該天不需打卡
        SET @output = 'NO';
        IF @Type_IN IN ('inreadesc', 'outreadesc') BEGIN
          SET @output = @vactype;
        END
      END
    END
ELSE IF @suphrs = 0 AND @evchrs = 0 BEGIN
      SET @output = @CheckTime;
    END
    
    IF @output IS NULL BEGIN
      SET @output = @CheckTime;
    END
    Continue_ForEach1:
    RETURN @output;
END
GO
