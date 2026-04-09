CREATE OR ALTER FUNCTION [ehrphrafunc_pkg].[f_getworktime]
(    @SchYm_IN NVARCHAR(MAX)
)
RETURNS DECIMAL(38,10)
AS
BEGIN
DECLARE @sSchYm NVARCHAR(7) = @SchYm_IN;
DECLARE @iDays INT;
DECLARE @dStartDate DATETIME2(0);
DECLARE @dEndDate DATETIME2(0);
DECLARE @iHoliHrs INT;
DECLARE @iTotalHrs INT;
    SET @dStartDate = CONVERT(DATETIME2, @sSchYm + '-01');
    SET @dEndDate = EOMONTH(@dStartDate);
    SET @iDays = CAST(FORMAT(@dEndDate, 'dd') AS DECIMAL(38,10));
  
    SET @iTotalHrs = @iDays * 8;
  
    -- EXCEPTION block removed: TRY/CATCH not allowed in T-SQL scalar function

    SELECT @iHoliHrs = SUM(HOLI_HRS)
    FROM HRA_HOLIDAY
       WHERE FORMAT(HOLI_DATE, 'yyyy-MM') = @sSchYm;

  
    IF @iHoliHrs IS NULL BEGIN
      SET @iHoliHrs = 0;
    END
  
    RETURN(@iTotalHrs - @iHoliHrs);
END
GO
