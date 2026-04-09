CREATE OR ALTER FUNCTION [ehrphrafunc_pkg].[f_userSignman]
(    @EmpNo_IN NVARCHAR(MAX)
)
RETURNS NVARCHAR(MAX)
AS
BEGIN
DECLARE @vEmpno NVARCHAR(20) = @EmpNo_IN;
DECLARE @vSignMan NVARCHAR(20);
DECLARE @vDeptChief NVARCHAR(2);
DECLARE @vOut NVARCHAR(50);
    SET @vOut = NULL;
    WHILE 1=1 BEGIN
      SELECT @vSignMan = USER_SIGNMAN, @vDeptChief = DEPT_CHIEF
    FROM HRE_EMPBAS
       WHERE EMP_NO = @vEmpno;
    
      IF @vDeptChief <> 'Y' BEGIN
        IF @vOut IS NULL BEGIN
          SET @vOut = @vEmpno + ',' + @vSignMan;
        END
        ELSE
        BEGIN
          SET @vOut = @vOut + ',' + @vSignMan;
        END
        SET @vEmpno = @vSignMan;
      END
      IF @vDeptChief = 'Y' BREAK;
    END
  
    RETURN @vOut;
END
GO
