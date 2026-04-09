CREATE OR ALTER FUNCTION [ehrphrafunc_pkg].[f_getsupout]
(    @SchYm_IN NVARCHAR(MAX),
    @EmpNo_IN NVARCHAR(MAX)
)
RETURNS DECIMAL(38,10)
AS
BEGIN
DECLARE @sSchYm NVARCHAR(7) = @SchYm_IN;
DECLARE @sEmpNo NVARCHAR(20) = @EmpNo_IN;
DECLARE @nAttValue DECIMAL(38,10);
DECLARE @nSupHrs DECIMAL(38,10);
DECLARE @nDiffHrs DECIMAL(38,10);
  
    -- EXCEPTION block removed: TRY/CATCH not allowed in T-SQL scalar function

    SELECT @nAttValue = SUM(ATT_VALUE)
    FROM HRA_ATTDTL1
       WHERE TRN_YM < @sSchYm
         AND EMP_NO = @sEmpNo
         AND ATT_CODE = '108';

  
    IF @nAttValue IS NULL BEGIN
      SET @nAttValue = 0;
    END
  
    -- EXCEPTION block removed: TRY/CATCH not allowed in T-SQL scalar function

    SELECT @nSupHrs = SUM(SUP_HRS)
    FROM Hra_Classsch_View
       WHERE SCH_YM = @sSchYm
         AND EMP_NO = @sEmpNo;

  
    IF @nSupHrs IS NULL BEGIN
      SET @nSupHrs = 0;
    END
  
    SET @nDiffHrs = ROUND(@nAttValue + @nSupHrs, 0);
  
    IF @nDiffHrs > 0 BEGIN
      RETURN(@nDiffHrs);
    END
    ELSE
    BEGIN
      RETURN(0);
    END
    RETURN 0; -- safety fallback for error 455
END
GO
