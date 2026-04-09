CREATE OR ALTER FUNCTION [ehrphra12_pkg].[getCountDocSUPhrs_fun]
(    @p_start_date NVARCHAR(MAX),
    @p_start_time NVARCHAR(MAX),
    @p_end_date NVARCHAR(MAX),
    @p_end_time NVARCHAR(MAX)
)
RETURNS DECIMAL(38,10)
AS
BEGIN
DECLARE @sStartDate NVARCHAR(10) = @p_start_date;
DECLARE @sStartTime NVARCHAR(4) = @p_start_time;
DECLARE @sEndDate NVARCHAR(10) = @p_end_date;
DECLARE @sEndTime NVARCHAR(10) = @p_end_time;
DECLARE @CntMin INT;
DECLARE @nCnt INT;
DECLARE @iSTime NVARCHAR(4);
DECLARE @iETime NVARCHAR(4);
      SET @CntMin = 0;


    --是否為假日
    -- EXCEPTION block removed: TRY/CATCH not allowed in T-SQL scalar function

    SELECT  @nCnt = COUNT(*)
    FROM HRP.HRA_HOLIDAY
    Where FORMAT(holi_date, 'yyyy-mm-dd')= @sStartDate
      and STOP_WORK = 'Y'
      and HOLI_WEEK <> 'SAT';


    IF @nCnt > 0 BEGIN
    GOTO Continue_ForEach1;
    END

    --是否為週六

    -- EXCEPTION block removed: TRY/CATCH not allowed in T-SQL scalar function

    SELECT  @nCnt = COUNT(*)
    FROM HRP.HRA_HOLIDAY
    Where FORMAT(holi_date, 'yyyy-mm-dd')= @sStartDate
      and HOLI_WEEK = 'SAT';


     --計算時數

    IF @sStartTime BETWEEN '0800' AND '1700' BEGIN
    SET @iSTime = @sStartTime;
    END
ELSE IF @sStartTime < '0800' BEGIN
    SET @iSTime = '0800';
    END
    ELSE
    BEGIN
    SET @iSTime = '0800';
    END

    IF @sEndTime BETWEEN '0800' AND '1700' BEGIN
    SET @iETime = @sEndTime;
    END
ELSE IF @sEndTime > '1700' BEGIN
    SET @iETime = '1700';
    END
    ELSE
    BEGIN
    SET @iETime = '0800';
    END

    IF @nCnt > 0 AND  @iETime > '1200' BEGIN --星期六上半天
    SET @iETime = '1200';
    END

    IF @iETime BETWEEN '1200' AND '1300' BEGIN
    SET @CntMin = [ehrphrafunc_pkg].[f_count_time](CONVERT(DATETIME2, @sStartDate),@iSTime,CONVERT(DATETIME2, @sStartDate),'1200');
    END
ELSE IF @iETime BETWEEN '1300' AND '1700'  AND @sStartTime <= '1200' BEGIN
    SET @CntMin = [ehrphrafunc_pkg].[f_count_time](CONVERT(DATETIME2, @sStartDate),@iSTime,CONVERT(DATETIME2, @sStartDate),@iETime);
    SET @CntMin = @CntMin - 60;
    END
ELSE IF @iETime BETWEEN '1300' AND '1700'  AND @sStartTime >= '1300' BEGIN
    SET @CntMin = [ehrphrafunc_pkg].[f_count_time](CONVERT(DATETIME2, @sStartDate),@iSTime,CONVERT(DATETIME2, @sStartDate),@iETime);
    END
ELSE IF @iETime BETWEEN '0800' AND '1200' BEGIN
    SET @CntMin = [ehrphrafunc_pkg].[f_count_time](CONVERT(DATETIME2, @sStartDate),@iSTime,CONVERT(DATETIME2, @sStartDate),@iETime);
    END
    Continue_ForEach1:
    return @CntMin;
END
GO
