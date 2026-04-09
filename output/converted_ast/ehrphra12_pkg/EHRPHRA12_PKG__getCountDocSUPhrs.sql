CREATE OR ALTER FUNCTION [ehrphra12_pkg].[getCountDocSUPhrs]
(    @p_start_date NVARCHAR(MAX),
    @p_start_time NVARCHAR(MAX),
    @p_end_date NVARCHAR(MAX),
    @p_end_time NVARCHAR(MAX)
)
RETURNS DECIMAL(38,10)
AS
BEGIN
DECLARE @sTotal DECIMAL(5,1);
DECLARE @sStartDate NVARCHAR(10) = @p_start_date;
DECLARE @sStartTime NVARCHAR(4) = @p_start_time;
DECLARE @sEndDate NVARCHAR(10) = @p_end_date;
DECLARE @sEndTime NVARCHAR(10) = @p_end_time;
DECLARE @sClassKind NVARCHAR(3);
DECLARE @iRestStartTime NVARCHAR(4);
DECLARE @iEndRestTime NVARCHAR(4);
DECLARE @CntMin INT;
DECLARE @CntHrs DECIMAL(5,1);
DECLARE @nCnt INT;
DECLARE @iSTime NVARCHAR(4);
DECLARE @iETime NVARCHAR(4);
DECLARE @iDate NVARCHAR(10);
      SET @CntHrs = 0;
      SET @CntMin = 0;
    --同一天
    IF @sEndDate =  @sStartDate BEGIN

    SET @CntMin = [ehrphra12_pkg].[getCountDocSUPhrs_fun]( @sStartDate, @sStartTime, @sEndDate, @sEndTime);
    --跨天
    END
ELSE IF CONVERT(DATETIME2, @sEndDate) = DATEADD(DAY, 1, CONVERT(DATETIME2, @sStartDate)) BEGIN

    SET @CntMin = [ehrphra12_pkg].[getCountDocSUPhrs_fun]( @sStartDate, @sStartTime, @sStartDate, '1700');
    SET @CntMin = @CntMin + [ehrphra12_pkg].[getCountDocSUPhrs_fun]( @sEndDate, '0800', @sEndDate, @sEndTime);

    --跨兩天以上
    END
    ELSE
    BEGIN

    SET @CntMin = [ehrphra12_pkg].[getCountDocSUPhrs_fun]( @sStartDate, @sStartTime, @sStartDate, '1700');
    SET @CntMin = @CntMin + [ehrphra12_pkg].[getCountDocSUPhrs_fun]( @sEndDate, '0800', @sEndDate, @sEndTime);


    SET @nCnt = DATEDIFF(DAY, CONVERT(DATE, @sStartDate), CONVERT(DATE, @sEndDate)) - 1;

    DECLARE @i INT = (1);
WHILE @i <= @nCnt BEGIN
    SET @iDate = FORMAT(DATEADD(DAY, @i, CONVERT(DATE, @sStartDate)), 'yyyy-mm-dd');
    SET @CntMin = @CntMin + [ehrphra12_pkg].[getCountDocSUPhrs_fun]( @iDate , '0800', @iDate, '1700');


    END


    END
      Continue_ForEach1:
    SET @CntHrs = CEILING(@CntMin / 30) * 0.5;



    return @CntHrs;
END
GO
