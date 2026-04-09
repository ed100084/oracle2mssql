CREATE OR ALTER FUNCTION [ehrphrafunc_pkg].[f_getFlowmergeVacData]
(    @flowevcno_in NVARCHAR(MAX),
    @type_in NVARCHAR(MAX)
)
RETURNS NVARCHAR(MAX)
AS
BEGIN
DECLARE @startdate DATETIME2(0);
DECLARE @enddate DATETIME2(0);
DECLARE @starttime NVARCHAR(4);
DECLARE @endtime NVARCHAR(4);
    SELECT @startdate = MIN(start_date), @enddate = MAX(end_date)
    FROM hra_evcrec
     WHERE flow_merge_no = @flowevcno_in;
    
    SELECT TOP 1 @starttime = start_time
    FROM hra_evcrec
     WHERE flow_merge_no = @flowevcno_in
       AND start_date = @startdate
       ORDER BY start_time;

    SELECT TOP 1 @endtime = end_time
    FROM hra_evcrec
     WHERE flow_merge_no = @flowevcno_in
       AND end_date = @enddate
       ORDER BY end_time DESC;
    IF @type_in = 's' BEGIN
      RETURN @starttime;
    END
ELSE IF @type_in = 'e' BEGIN
      RETURN @endtime;
    END
    ELSE
    BEGIN
      RETURN '';
    END
    RETURN NULL; -- safety fallback for error 455
END
GO
