CREATE OR ALTER FUNCTION [ehrphrafunc_pkg].[checkClassTime]
(    @p_emp_no NVARCHAR(MAX),
    @p_start_date NVARCHAR(MAX),
    @p_start_time NVARCHAR(MAX),
    @p_end_date NVARCHAR(MAX),
    @p_end_time NVARCHAR(MAX),
    @p_class_code NVARCHAR(MAX),
    @p_Last_Class_code NVARCHAR(MAX)
)
RETURNS DECIMAL(38,10)
AS
BEGIN
DECLARE @sClassCode NVARCHAR(3);
DECLARE @sLastClassKind NVARCHAR(3);
DECLARE @iCnt INT;
DECLARE @RtnCode SMALLINT;
DECLARE @iCHKIN_WKTM NVARCHAR(4);
DECLARE @iCHKOUT_WKTM NVARCHAR(4);
DECLARE @iSTART_REST NVARCHAR(4);
DECLARE @iEND_REST NVARCHAR(4);
DECLARE @iSTARTTIME DATETIME2(0);
DECLARE @iENDTIME DATETIME2(0);
DECLARE cursor1 CURSOR FOR
    SELECT CHKIN_WKTM, CHKOUT_WKTM, START_REST, END_REST
        FROM HRP.HRA_CLASSDTL
       Where CLASS_CODE = @p_class_code
         AND SHIFT_NO <> '4';
  
    SET @RtnCode = 0;
  
    OPEN cursor1;
    WHILE 1=1 BEGIN
      FETCH NEXT FROM cursor1 INTO @iCHKIN_WKTM, @iCHKOUT_WKTM, @iSTART_REST, @iEND_REST;
      IF @@FETCH_STATUS <> 0 BREAK;
    
      --是否為跨夜班
      -- EXCEPTION block removed: TRY/CATCH not allowed in T-SQL scalar function

    SELECT @iCnt = COUNT(ROWID)
    FROM HRP.HRA_CLASSDTL
         WHERE CHKIN_WKTM > CASE WHEN CHKOUT_WKTM = '0000' THEN '2400' ELSE CHKOUT_WKTM END AND SHIFT_NO <> '4' AND CLASS_CODE = @p_class_code;

    
      IF @iCnt > 0 BEGIN
        --如果為跨夜班,下班日期+1
        SET @iENDTIME = DATEADD(DAY, 1, CONVERT(DATETIME2, @p_start_date + @iCHKOUT_WKTM));
      END
      ELSE
      BEGIN
        SET @iENDTIME = CONVERT(DATETIME2, @p_start_date + @iCHKOUT_WKTM);
      END
    
      --ini
      SET @iCnt = 0;
      --是否為0000上班
      -- EXCEPTION block removed: TRY/CATCH not allowed in T-SQL scalar function

    SELECT @iCnt = COUNT(ROWID)
    FROM HRP.HRA_CLASSDTL
         WHERE CHKIN_WKTM = '0000'
           AND CHKIN_FLAG = 'Y'
           AND CLASS_CODE = @p_class_code;

    
      /*IF  @iCnt > 0 BEGIN
      SET @iSTARTTIME = DATEADD(DAY, 1, CONVERT(DATETIME2, @p_start_date +  @iCHKIN_WKTM));
      SET @iENDTIME = DATEADD(DAY, 1, CONVERT(DATETIME2, @p_start_date +  @iCHKOUT_WKTM));
      END
      ELSE
      BEGIN
      SET @iSTARTTIME = CONVERT(DATETIME2, @p_start_date +  @iCHKIN_WKTM);
      END*/
      --20190110 調整同checkClassTime2的處理 by108482
      IF @iCnt > 0 BEGIN
        SET @iSTARTTIME = DATEADD(DAY, 1, CONVERT(DATETIME2, @p_start_date + @iCHKIN_WKTM));
      END
      ELSE
      BEGIN
        SET @iSTARTTIME = CONVERT(DATETIME2, @p_start_date + @iCHKIN_WKTM);
        SET @iENDTIME = CONVERT(DATETIME2, @p_start_date + @iCHKOUT_WKTM);
      END
    
      --比較上班時間
      IF ((DATEADD(MILLISECOND, 8640, CONVERT(DATETIME2, @p_start_date + @p_start_time))
         BETWEEN @iSTARTTIME AND @iENDTIME) OR
         (DATEADD(MILLISECOND, -8640, CONVERT(DATETIME2, @p_end_date + @p_end_time))
         BETWEEN @iSTARTTIME AND @iENDTIME)) OR
         (DATEADD(MILLISECOND, 8640, @iSTARTTIME)
         BETWEEN CONVERT(DATETIME2, @p_start_date + @p_start_time) AND
         CONVERT(DATETIME2, @p_end_date + @p_end_time))
      
       BEGIN
        SET @RtnCode = 1;
      END
    
      --比較休息時間
      IF @RtnCode > 0 BEGIN
        IF @iSTART_REST <> '0' AND @iEND_REST <> '0' BEGIN
          IF (@p_start_time BETWEEN @iSTART_REST AND @iEND_REST AND
             @p_end_time BETWEEN @iSTART_REST AND @iEND_REST) BEGIN
            SET @RtnCode = 0;
          END
        END
      END
    
    END
    CLOSE cursor1;
    DEALLOCATE cursor1
    RETURN @RtnCode;
END
GO
