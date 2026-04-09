CREATE OR ALTER FUNCTION [ehrphra12_pkg].[getOffhrs]
(    @p_start_date NVARCHAR(MAX),
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
DECLARE @sEmpNo NVARCHAR(10) = @p_emp_no;
DECLARE @sTotal SMALLINT;
DECLARE @sStartDate NVARCHAR(10) = @p_start_date;
DECLARE @sStartTime NVARCHAR(4) = @p_start_time;
DECLARE @sEndDate NVARCHAR(10) = @p_end_date;
DECLARE @sEndTime NVARCHAR(4) = @p_end_time;
DECLARE @sclassCode NVARCHAR(3);
DECLARE @SOrganType NVARCHAR(10) = @OrganType_IN;
DECLARE @iSMin SMALLINT;
DECLARE @iEMin SMALLINT;
DECLARE @iSrest SMALLINT;
DECLARE @iErest SMALLINT;
DECLARE @sClassKind NVARCHAR(3);
DECLARE @iRestStartTime NVARCHAR(4);
DECLARE @iEndRestTime NVARCHAR(4);
DECLARE @ichkin NVARCHAR(4);
DECLARE @ichkout NVARCHAR(4);
DECLARE cursor1 CURSOR FOR
    SELECT START_REST, END_REST
        FROM HRP.HRA_CLASSDTL
       Where CLASS_CODE = arg_class_code
       ORDER BY START_REST;
    SET @RtnCode = 0;

     IF CONVERT(DATETIME2, @sStartDate +@sStartTime) > CONVERT(DATETIME2, @sEndDate +@sEndTime) BEGIN
      SET @RtnCode = 0;
      GOTO Continue_ForEach2;
     END

    SET @sclassCode = [ehrphrafunc_pkg].[f_getClassKind] (@sEmpNo , CONVERT(DATETIME2, @sStartDate) ,@SOrganType);
    SET @sTotal = [ehrphrafunc_pkg].[f_count_time](CONVERT(DATETIME2, @sStartDate),@sStartTime,CONVERT(DATETIME2, @sEndDate),@sEndTime);

    --無排班
    IF @sclassCode = 'N/A' BEGIN
    GOTO Continue_ForEach2 ;
    END


    OPEN cursor1;
    WHILE 1=1 BEGIN
      FETCH cursor1
--        INTO @ichkin, @ichkout ,@iRestStartTime ,@iEndRestTime  ;
        INTO @iRestStartTime ,@iEndRestTime  ;
      IF @@FETCH_STATUS <> 0 BREAK;

     IF  @iRestStartTime = '0' OR @iEndRestTime ='0' BEGIN

     SET @RtnCode = @sTotal -0;

     END
ELSE IF @sStartTime between @iRestStartTime and @iEndRestTime AND  @sEndTime NOT between @iRestStartTime and @iEndRestTime BEGIN

     SET @RtnCode = @sTotal - [ehrphrafunc_pkg].[f_count_time](CONVERT(DATETIME2, @sStartDate),@sStartTime,CONVERT(DATETIME2, @sEndDate),@iEndRestTime);
	 --SET @RtnCode = @sTotal - [ehrphrafunc_pkg].[f_count_time](CONVERT(DATETIME2, @sStartDate),@sStartTime,CONVERT(DATETIME2, '2008-05-21'),@iEndRestTime);

     END
ELSE IF @sEndTime between @iRestStartTime and @iEndRestTime and @sStartTime not between @iRestStartTime and @iEndRestTime BEGIN

     SET @RtnCode = @sTotal - [ehrphrafunc_pkg].[f_count_time](CONVERT(DATETIME2, @sStartDate),@iRestStartTime,CONVERT(DATETIME2, @sEndDate),@sEndTime);

     END
ELSE IF @sStartTime < @iRestStartTime and @sEndTime > @iEndRestTime BEGIN

     SET @RtnCode = @sTotal - [ehrphrafunc_pkg].[f_count_time](CONVERT(DATETIME2, @sStartDate),@iRestStartTime,CONVERT(DATETIME2, @sEndDate),@iEndRestTime);

     END
ELSE IF @sStartTime between @iRestStartTime and @iEndRestTime AND  @sEndTime between @iRestStartTime and @iEndRestTime BEGIN

     SET @RtnCode = @sTotal;

     END
     ELSE
     BEGIN
     SET @RtnCode = @sTotal -0;

     END
      Continue_ForEach1:
    END
    CLOSE cursor1;
    DEALLOCATE cursor1
      Continue_ForEach2:
    return @RtnCode;
END
GO
