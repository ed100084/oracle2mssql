CREATE OR ALTER FUNCTION [ehrphrafunc_pkg].[f_getyearenday]
(    @comeday NVARCHAR(MAX),
    @vacyear NVARCHAR(MAX)
)
RETURNS NVARCHAR(MAX)
AS
BEGIN
DECLARE @dcomeday NVARCHAR(10) = @comeday;
DECLARE @dvacyear NVARCHAR(4) = @vacyear;
DECLARE @sRtnType VARCHAR(10);
  
    IF (CAST(SUBSTRING(@dcomeday, 1, 4) AS DECIMAL(38,10)) + 1 <
       CAST(@dvacyear AS DECIMAL(38,10))) BEGIN
      SET @sRtnType = @dvacyear + '-01-01';
    END
    ELSE
    BEGIN
      SET @sRtnType = FORMAT(DATEADD(DAY, 365, CONVERT(DATETIME2, @dcomeday)), 'yyyy-mm-dd');
    END
  
    RETURN(@sRtnType);
END
GO
