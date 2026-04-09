CREATE OR ALTER FUNCTION [ehrphrafunc_pkg].[f_getseniority_month]
(    @comeday NVARCHAR(MAX),
    @vacyear NVARCHAR(MAX)
)
RETURNS NVARCHAR(MAX)
AS
BEGIN
DECLARE @dcomeday NVARCHAR(10) = @comeday;
DECLARE @dvacyear NVARCHAR(4) = @vacyear;
DECLARE @sRtnType NVARCHAR(2);
  
    SET @sRtnType = 12 - CAST(SUBSTRING(@dcomeday, 6, 2) AS DECIMAL(38,10)) + 1;
  
    IF (CAST(@dvacyear AS DECIMAL(38,10)) - CAST(SUBSTRING(@dcomeday, 1, 4) AS DECIMAL(38,10)) - 1 < 0 OR
       @sRtnType >= 12) BEGIN
      SET @sRtnType = 0;
    END
  
    RETURN(@sRtnType);
END
GO
