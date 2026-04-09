CREATE OR ALTER FUNCTION [ehrphrafunc_pkg].[f_time_continuous]
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
  
    SET @nDay = DATEDIFF(DAY, CONVERT(DATE, @p_start_date), CONVERT(DATE, @p_end_date));
    SET @RtnCode = 0;
  
    IF @nDay = 0 BEGIN
      --同一天 視為連續請假
    
      SET @iSCH1 = [ehrphrafunc_pkg].[f_getClassKind](@sEmpNO,
                                              CONVERT(DATETIME2, @sStartDate),
                                              @SOrganType);
      SET @iSCH2 = [ehrphrafunc_pkg].[f_getClassKind](@sEmpNO,
                                              CONVERT(DATETIME2, @sEndDate),
                                              @SOrganType);
    
      SELECT @sClassTime1 = MAX(CHKOUT_WKTM)
    FROM HRP.HRA_CLASSDTL
       Where CLASS_CODE = @iSCH1;
    
      SELECT @sClassTime2 = MIN(CHKIN_WKTM)
    FROM HRP.HRA_CLASSDTL
       Where CLASS_CODE = @iSCH2;
    
      IF @sStartTime >= @sClassTime1 AND @sEndTime <= @sClassTime2 BEGIN
        SET @RtnCode = 1;
      END
    
    END
ELSE IF @nDay = 1 BEGIN
      -- 間隔一天
      SET @iSCH1 = [ehrphrafunc_pkg].[f_getClassKind](@sEmpNO,
                                              CONVERT(DATETIME2, @sStartDate),
                                              @SOrganType);
      SET @iSCH2 = [ehrphrafunc_pkg].[f_getClassKind](@sEmpNO,
                                              CONVERT(DATETIME2, @sEndDate),
                                              @SOrganType);
    
      --IF @iSCH1 = 'ZZ' OR @iSCH2 = 'ZZ' THEN 20161219班別新增 ZX,ZY
      --20180725 108978 增加ZQ
      IF @iSCH1 IN ('ZZ', 'ZX', 'ZX', 'ZQ') OR
         @iSCH2 IN ('ZZ', 'ZY', 'ZX', 'ZQ') BEGIN
        SET @RtnCode = 1;
      END
      ELSE
      BEGIN
        SELECT @sClassTime1 = MAX(CHKOUT_WKTM)
    FROM HRP.HRA_CLASSDTL
         Where CLASS_CODE = @iSCH1;
      
        SELECT @sClassTime2 = MIN(CHKIN_WKTM)
    FROM HRP.HRA_CLASSDTL
         Where CLASS_CODE = @iSCH2;
      
        IF @sStartTime >= @sClassTime1 AND @sEndTime <= @sClassTime2 BEGIN
          SET @RtnCode = 1;
        END
      END
    END
    ELSE
    BEGIN
      -- 間隔二天以上,需判斷班表有無 ZZ 班
      SET @nCnt = 0;
      DECLARE @i INT = (1);
WHILE @i <= @nDay BEGIN
      
        SET @iSCH = [ehrphrafunc_pkg].[f_getClassKind](@sEmpNO,
                                               DATEADD(DAY, @i, CONVERT(DATETIME2, @p_start_date)),
                                               @SOrganType);
      
        --IF @iSCH = 'ZZ' THEN 20161219 班別新增 ZX,ZY
        --20180725 108978 增加ZQ
        IF @iSCH in ('ZZ', 'ZX', 'ZY', 'ZQ') BEGIN
          SET @nCnt = @nCnt + 1;
        END
      
      END
    
      IF @nCnt = @nDay - 1 BEGIN
      
        SET @iSCH1 = [ehrphrafunc_pkg].[f_getClassKind](@sEmpNO,
                                                CONVERT(DATETIME2, @sStartDate),
                                                @SOrganType);
        SET @iSCH2 = [ehrphrafunc_pkg].[f_getClassKind](@sEmpNO,
                                                CONVERT(DATETIME2, @sEndDate),
                                                @SOrganType);
      
        SELECT @sClassTime1 = MAX(CHKOUT_WKTM)
    FROM HRP.HRA_CLASSDTL
         Where CLASS_CODE = @iSCH1;
      
        SELECT @sClassTime2 = MIN(CHKIN_WKTM)
    FROM HRP.HRA_CLASSDTL
         Where CLASS_CODE = @iSCH2;
      
        IF @sStartTime >= @sClassTime1 AND @sEndTime <= @sClassTime2 BEGIN
          SET @RtnCode = 1;
        END
      
      END
    END
    Continue_ForEach1:
    RETURN @RtnCode;
END
GO
