CREATE OR ALTER FUNCTION [ehrphrafunc_pkg].[f_time_continuous4nosch]
(    @p_emp_no NVARCHAR(MAX),
    @p_start_date NVARCHAR(MAX),
    @p_start_time NVARCHAR(MAX),
    @p_end_date NVARCHAR(MAX),
    @P_end_time NVARCHAR(MAX),
    @OrganType_IN NVARCHAR(MAX)
)
RETURNS DECIMAL(38,10)
AS
BEGIN
DECLARE @sEmpNO NVARCHAR(10) = @p_emp_no;
DECLARE @sStartDate NVARCHAR(10) = @p_start_date;
DECLARE @sEndDate NVARCHAR(10) = @p_end_date;
DECLARE @sStartTime NVARCHAR(10) = @p_start_time;
DECLARE @sEndTime NVARCHAR(10) = @P_end_time;
DECLARE @SOrganType NVARCHAR(10) = @OrganType_IN;
DECLARE @iSCH NVARCHAR(4);
DECLARE @iSCH1 NVARCHAR(4);
DECLARE @iSCH2 NVARCHAR(4);
DECLARE @sClassTime1 NVARCHAR(4);
DECLARE @sClassTime2 NVARCHAR(4);
DECLARE @nDay DECIMAL(38,10);
DECLARE @RtnCode DECIMAL(38,10);
DECLARE @nCnt DECIMAL(38,10);
DECLARE @v_lower DECIMAL(38,10) = 1;
DECLARE @v_upper DECIMAL(38,10);
DECLARE @CheckEndCnt DECIMAL(38,10);
DECLARE @CheckEndTime NVARCHAR(10);
  
    SELECT @CheckEndCnt = COUNT(*)
    FROM HR_CODEDTL
     WHERE CODE_TYPE = 'HRA78'
       AND CODE_NO = (SELECT dept_no FROM hre_empbas WHERE emp_no = @sEmpNO);
    --20210507 108482 部門在參數裡的下班時間為1700
    IF @CheckEndCnt = 0 BEGIN
      SET @CheckEndTime = '1730';
    END
    ELSE
    BEGIN
      SET @CheckEndTime = '1700';
    END
  
    --20181210 108978 修正開始時間大於結束時間日期會判斷?負數的bug      
    IF (CONVERT(DATETIME2, @p_start_date) >
       CONVERT(DATETIME2, @p_end_date)) BEGIN
      SET @sStartDate = @p_end_date;
      SET @sEndDate = @p_start_date;
      SET @nDay = DATEDIFF(DAY, CONVERT(DATE, @p_end_date), CONVERT(DATE, @p_start_date));
    END
    ELSE
    BEGIN
      SET @nDay = DATEDIFF(DAY, CONVERT(DATE, @p_start_date), CONVERT(DATE, @p_end_date));
    END
  
    SET @v_upper = @nDay;
    SET @RtnCode = 0;
  
    IF @nDay = 0 BEGIN
      --同一天 視為連續請假
    
      /*    SET @iSCH1 = [ehrphrafunc_pkg].[f_getClassKind] (@sEmpNO , CONVERT(DATETIME2, @sStartDate),@SOrganType);
      SET @iSCH2 = [ehrphrafunc_pkg].[f_getClassKind] (@sEmpNO , CONVERT(DATETIME2, @sEndDate),@SOrganType);
      
      SELECT @sClassTime1 = MAX(CHKOUT_WKTM)
    FROM HRP.HRA_CLASSDTL
       Where CLASS_CODE = @iSCH1;
      
      SELECT @sClassTime2 = MIN(CHKIN_WKTM)
    FROM HRP.HRA_CLASSDTL
       Where CLASS_CODE = @iSCH2;*/
    
      --IF @sStartTime >= '1730' AND @sEndTime <= '0800' THEN
      IF @sStartTime >= @CheckEndTime AND @sEndTime <= '0800' BEGIN
        SET @RtnCode = 1;
      END
ELSE IF @sStartTime = '1200' AND (@sEndTime BETWEEN '1200' AND '1330') BEGIN
        SET @RtnCode = 1;
      END
ELSE IF @sStartTime = @sEndTime BEGIN
        SET @RtnCode = 1;
      END
    
    END
ELSE IF @nDay = 1 BEGIN
      -- 間隔一天
      /*    SET @iSCH1 = [ehrphrafunc_pkg].[f_getClassKind] (@sEmpNO , CONVERT(DATETIME2, @sStartDate),@SOrganType);
      SET @iSCH2 = [ehrphrafunc_pkg].[f_getClassKind] (@sEmpNO , CONVERT(DATETIME2, @sEndDate),@SOrganType);*/
    
      --IF @iSCH1 = 'ZZ' OR @iSCH2 = 'ZZ' THEN 20161219班別新增 ZX,ZY
      /*     IF @iSCH1 IN('ZZ','ZX','ZY') OR @iSCH2 IN ('ZZ','ZY','ZX') BEGIN
       SET @RtnCode = 1;
       END
       ELSE
       BEGIN
      SELECT @sClassTime1 = MAX(CHKOUT_WKTM)
    FROM HRP.HRA_CLASSDTL
       Where CLASS_CODE = @iSCH1;
      
      SELECT @sClassTime2 = MIN(CHKIN_WKTM)
    FROM HRP.HRA_CLASSDTL
       Where CLASS_CODE = @iSCH2;*/
    
      --IF @sStartTime >= '1730' AND @sEndTime <= '0800' THEN
      IF @sStartTime >= @CheckEndTime AND @sEndTime <= '0800' BEGIN
        SET @RtnCode = 1;
      END
    
    END
    ELSE
    BEGIN
      --間隔1天以上判斷是否有假日 20181210 108978
      DECLARE @i INT = @v_lower;
WHILE @i <= @v_upper - 1 BEGIN
        SELECT @nCnt = COUNT(*)
    FROM hra_holiday
         WHERE holi_yy =
               FORMAT(CONVERT(DATETIME2, @sStartDate) + i, 'yyyy')
           AND holi_date = CONVERT(DATETIME2, @sStartDate) + i;
      
        IF (@nCnt = 0) BEGIN
          SET @RtnCode = @nCnt;
          GOTO Continue_ForEach1;
        END
      
        SET @RtnCode = @nCnt;
        IF @sStartTime >= @CheckEndTime AND @sEndTime <= '0800' BEGIN
          SET @RtnCode = 1;
        END
        ELSE
        BEGIN
          SET @RtnCode = 0;
        END
      END
    
    END
    Continue_ForEach1:
    RETURN @RtnCode;
END
GO
