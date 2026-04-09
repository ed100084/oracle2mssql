CREATE OR ALTER FUNCTION [ehrphra12_pkg].[getOtmhrs_T]
(    @p_start_date NVARCHAR(MAX),
    @p_start_date_tmp NVARCHAR(MAX),
    @p_start_time NVARCHAR(MAX),
    @p_end_date NVARCHAR(MAX),
    @p_end_time NVARCHAR(MAX),
    @p_emp_no NVARCHAR(MAX),
    @OrganType_IN NVARCHAR(MAX)
)
RETURNS DECIMAL(38,10)
AS
BEGIN
DECLARE @RtnCode SMALLINT;
DECLARE @iSMin SMALLINT;
DECLARE @iEMin SMALLINT;
DECLARE @iSrest SMALLINT;
DECLARE @iErest SMALLINT;
DECLARE @sClassKind NVARCHAR(3);
DECLARE @iRestStartTime NVARCHAR(4);
DECLARE @iEndRestTime NVARCHAR(4);
DECLARE @SOrganType NVARCHAR(10) = @OrganType_IN;
    SET @RtnCode = 0;
    SET @iSMin = SUBSTRING(@p_start_time,1,2)*60 + SUBSTRING(@p_start_time,3,4);
    SET @iEMin = SUBSTRING(@p_end_time,1,2)*60 + SUBSTRING(@p_end_time,3,4);

    --SET @sClassKind = [ehrphrafunc_pkg].[f_getClassKind] (@p_emp_no , CONVERT(DATETIME2, @p_start_date),@SOrganType);
    SET @sClassKind = [ehrphrafunc_pkg].[f_getClassKind] (@p_emp_no , CONVERT(DATETIME2, @p_start_date_tmp),@SOrganType);

    -- EXCEPTION block removed: TRY/CATCH not allowed in T-SQL scalar function

    SELECT @iRestStartTime = START_REST, @iEndRestTime = END_REST
    FROM HRP.HRA_CLASSDTL Tbl
       Where CLASS_CODE = @sClassKind
         AND SHIFT_NO IN ('1');  -- 僅取時段1的休息時間



    IF  @iRestStartTime <>'0' AND @iRestStartTime<>'0' BEGIN
    SET @iSrest = SUBSTRING(@iRestStartTime,1,2)*60 + SUBSTRING(@iRestStartTime,3,4);
    SET @iErest = SUBSTRING(@iEndRestTime,1,2)*60 + SUBSTRING(@iEndRestTime,3,4);
    END
    ELSE
    BEGIN
      --扣 中午午休 BY SZUHAO AT 2007-06-06
      SET @iRestStartTime = '1200';
      SET @iEndRestTime = '1300';
      SET @iSrest = 12 * 60;
      SET @iErest = 13 * 60;
    /*  REMARK BY SZUHAO AT 2007-06-06
    SET @iSrest = '0';
    SET @iErest = '0';
    */
    END



    --當日
    IF @p_start_date = @p_end_date BEGIN
    -- 介於 1200~1330 之間
    IF (@p_start_time BETWEEN @iRestStartTime AND @iEndRestTime) AND (@p_end_time BETWEEN @iRestStartTime AND @iEndRestTime) BEGIN

    SET @RtnCode = @iEMin -@iSMin;

    END
ELSE IF (@p_start_time BETWEEN @iRestStartTime AND @iEndRestTime) BEGIN  -- 起始時間介於 @iRestStartTime~@iEndRestTime

    SET @RtnCode = @iEMin -  @iErest;

    END
ELSE IF (@p_end_time BETWEEN @iRestStartTime AND @iEndRestTime) BEGIN    -- 結束時間介於 @iRestStartTime~@iEndRestTime

    SET @RtnCode = @iSrest - @iSMin;

    END
ELSE IF (@iRestStartTime BETWEEN @p_start_time AND @p_end_time) BEGIN  -- Stime 及 Etiem 介於 @iRestStartTime~@iEndRestTime

    SET @RtnCode = @iSrest - @iSMin +  @iEMin -  @iErest;

    END
    ELSE
    BEGIN
    SET @RtnCode = @iEMin -@iSMin;
    END

    END
    ELSE
    BEGIN

    --跨天

    IF @p_start_time BETWEEN @iEndRestTime AND '2400' BEGIN
    SET @RtnCode = 1440 - @iSMin;
    END
ELSE IF @p_start_time BETWEEN @iRestStartTime AND @iEndRestTime BEGIN
    SET @RtnCode = 1440 - @iErest;
    END
    ELSE
    BEGIN
    SET @RtnCode = 1440 - @iSMin - (@iErest - @iSrest);
    END

    IF @p_end_time BETWEEN '0000' AND @iRestStartTime BEGIN
    SET @RtnCode = @RtnCode + @iEMin;
    END
ELSE IF @p_end_time BETWEEN @iRestStartTime AND @iEndRestTime BEGIN
    SET @RtnCode = @RtnCode + @iSrest;
    END
    ELSE
    BEGIN
    SET @RtnCode = @RtnCode + @iSrest +  @iEMin - @iErest;
    END

    END

    return @RtnCode;
END
GO
