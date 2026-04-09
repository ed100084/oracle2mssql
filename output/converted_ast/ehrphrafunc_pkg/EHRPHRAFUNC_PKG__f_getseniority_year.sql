CREATE OR ALTER FUNCTION [ehrphrafunc_pkg].[f_getseniority_year]
(    @comeday NVARCHAR(MAX),
    @vacyear NVARCHAR(MAX)
)
RETURNS NVARCHAR(MAX)
AS
BEGIN
DECLARE @dcomeday NVARCHAR(10) = @comeday;
DECLARE @dvacyear NVARCHAR(4) = @vacyear;
DECLARE @sRtnType BIGINT;
    SET @sRtnType = CAST(@dvacyear AS DECIMAL(38,10)) -
                CAST(SUBSTRING(@dcomeday, 1, 4) AS DECIMAL(38,10)) - 1;
  
    IF ((12 - CAST(SUBSTRING(@dcomeday, 6, 2) AS DECIMAL(38,10)) + 1) >= 12) BEGIN
      SET @sRtnType = @sRtnType + 1;
    END
  
    IF (@sRtnType < 0) BEGIN
      SET @sRtnType = 0;
    END
  
    RETURN(FORMAT(@sRtnType, '999'));
END
GO
