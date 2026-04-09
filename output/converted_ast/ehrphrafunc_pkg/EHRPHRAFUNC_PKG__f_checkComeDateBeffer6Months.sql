CREATE OR ALTER FUNCTION [ehrphrafunc_pkg].[f_checkComeDateBeffer6Months]
(    @emp_no NVARCHAR(MAX)
)
RETURNS NVARCHAR(MAX)
AS
BEGIN
DECLARE @iemp_no NVARCHAR(10) = @emp_no;
DECLARE @iCOME_DATE DATETIME2(0);
DECLARE @rEffect NVARCHAR(5) = 'NULL';
  
    -- EXCEPTION block removed: TRY/CATCH not allowed in T-SQL scalar function

    SELECT @iCOME_DATE = COME_DATE
    FROM HRE_EMPBAS
       WHERE @emp_no = @iemp_no;

  
    IF DATEADD(MONTH, 6, @iCOME_DATE) < GETDATE() BEGIN
      SET @rEffect = '1';
    END
    ELSE
    BEGIN
    
      SET @rEffect = '0';
    
    END
  
    return @rEffect;
END
GO
