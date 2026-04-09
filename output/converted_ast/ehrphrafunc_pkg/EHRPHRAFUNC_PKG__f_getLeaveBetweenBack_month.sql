CREATE OR ALTER FUNCTION [ehrphrafunc_pkg].[f_getLeaveBetweenBack_month]
(    @empno NVARCHAR(MAX),
    @leaveday NVARCHAR(MAX),
    @backday NVARCHAR(MAX)
)
RETURNS NVARCHAR(MAX)
AS
BEGIN
DECLARE @dLeave NVARCHAR(10) = @leaveday;
DECLARE @dBack NVARCHAR(4) = @backday;
DECLARE @dEmpNo NVARCHAR(10) = @empno;
DECLARE @sRtnType NVARCHAR(2);
  
    SET @sRtnType = 12;
  
    RETURN(@sRtnType);
END
GO
