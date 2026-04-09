CREATE OR ALTER FUNCTION [ehrphrafunc_pkg].[f_getworkhrs]
(    @SchYm_IN NVARCHAR(MAX),
    @EmpNo_IN NVARCHAR(MAX)
)
RETURNS DECIMAL(38,10)
AS
BEGIN
DECLARE @sSchYm NVARCHAR(7) = @SchYm_IN;
DECLARE @sEmpNo NVARCHAR(20) = @EmpNo_IN;
DECLARE @iDays INT;
DECLARE @dStartDate DATETIME2(0);
DECLARE @dEndDate DATETIME2(0);
DECLARE @nHoliHrs DECIMAL(38,10);
DECLARE @nTotalHrs DECIMAL(38,10);
    SET @dStartDate = CONVERT(DATETIME2, @sSchYm + '-01');
    SET @dEndDate = EOMONTH(@dStartDate);
    SET @iDays = CAST(FORMAT(@dEndDate, 'dd') AS DECIMAL(38,10));
  
    SET @nTotalHrs = @iDays * 8;
  
    -- EXCEPTION block removed: TRY/CATCH not allowed in T-SQL scalar function

    SELECT @nHoliHrs = sum(add_hrs + sup_hrs + vac_hrs + otm_hrs - off_hrs +
                 cutotm_hrs + cutsup_hrs)
    FROM hra_classsch_view
       WHERE sch_ym = @sSchYm
         AND emp_no = @sEmpNo;

  
    IF @nHoliHrs IS NULL BEGIN
      SET @nHoliHrs = 0;
    END
  
    RETURN(@nTotalHrs + @nHoliHrs);
END
GO
