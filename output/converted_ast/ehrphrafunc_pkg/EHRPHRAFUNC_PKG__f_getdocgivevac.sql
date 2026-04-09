CREATE OR ALTER FUNCTION [ehrphrafunc_pkg].[f_getdocgivevac]
(    @EmpNo_IN NVARCHAR(MAX),
    @VacYear_IN NVARCHAR(MAX),
    @VacType_IN NVARCHAR(MAX),
    @VacRule_IN NVARCHAR(MAX)
)
RETURNS DECIMAL(38,10)
AS
BEGIN
DECLARE @sEmpNo NVARCHAR(20) = @EmpNo_IN;
DECLARE @sVacYear NVARCHAR(4) = @VacYear_IN;
DECLARE @sVacType NVARCHAR(1) = @VacType_IN;
DECLARE @sVacRule NVARCHAR(10) = @VacRule_IN;
DECLARE @nVacHrs DECIMAL(38,10);
DECLARE @nVacQty DECIMAL(38,10);
DECLARE @dComeDate DATETIME2(0);
DECLARE @sVacYM NVARCHAR(7);
  
    -- EXCEPTION block removed: TRY/CATCH not allowed in T-SQL scalar function

    SELECT @dComeDate = COME_DATE
    FROM HRE_EMPBAS
       WHERE EMP_NO = @sEmpNo;

  
    IF @dComeDate IS NULL BEGIN
      RETURN(0);
    END
  
    -- EXCEPTION block removed: TRY/CATCH not allowed in T-SQL scalar function

    SELECT @nVacQty = VAC_QTY
    FROM HRA_VCRLDTL
       WHERE VAC_TYPE = @sVacType
         AND VAC_RUL = @sVacRule;

  
    IF @nVacQty IS NULL BEGIN
      SET @nVacQty = 0;
    END
  
    SET @sVacYM = @sVacYear + '-' + @sVacRule;
  
    IF @sVacType = 'K' BEGIN
      IF FORMAT(@dComeDate, 'yyyy-MM') > @sVacYM BEGIN
        SET @nVacHrs = 0;
      END
      ELSE
      BEGIN
        SET @nVacHrs = @nVacQty * 8;
      END
    END
  
    IF @sVacType = 'L' BEGIN
      IF FORMAT(@dComeDate, 'yyyy') > @sVacYear BEGIN
        SET @nVacHrs = 0;
      END
      ELSE
      BEGIN
        SET @nVacHrs = @nVacQty * 8;
      END
    END
  
    RETURN(@nVacHrs);
END
GO
