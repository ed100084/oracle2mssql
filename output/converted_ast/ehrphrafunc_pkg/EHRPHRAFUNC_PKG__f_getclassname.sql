CREATE OR ALTER FUNCTION [ehrphrafunc_pkg].[f_getclassname]
(    @ClassCode_IN NVARCHAR(MAX)
)
RETURNS NVARCHAR(MAX)
AS
BEGIN
DECLARE @sClassCode NVARCHAR(10) = @ClassCode_IN;
DECLARE @sClassName NVARCHAR(60);
    -- EXCEPTION block removed: TRY/CATCH not allowed in T-SQL scalar function

    SELECT @sClassName = CLASS_NAME
    FROM HRA_CLASSMST
       WHERE CLASS_CODE = @sClassCode;

    RETURN(@sClassName);
END
GO
