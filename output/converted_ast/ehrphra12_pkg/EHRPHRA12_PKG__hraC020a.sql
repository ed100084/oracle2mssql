CREATE OR ALTER PROCEDURE [ehrphra12_pkg].[hraC020a]
(    @p_otm_date NVARCHAR(MAX),
    @p_sup_date NVARCHAR(MAX),
    @RtnCode DECIMAL(38,10) OUTPUT
)
AS
DECLARE @basedate DATETIME2(0) = DATEADD(MONTH, -1, CONVERT(DATETIME2, SUBSTRING(@p_sup_date,1,7)+'-01'));
BEGIN
    SET @RtnCode = 0;

    IF @p_otm_date > @p_sup_date BEGIN
    SET @RtnCode = 1;
    GOTO Continue_ForEach1 ;
    END

    if @p_otm_date not between FORMAT(@basedate, 'yyyy-mm-dd')and @p_otm_date  BEGIN
    SET @RtnCode = 2;
    GOTO Continue_ForEach1 ;
    END
    Continue_ForEach1:
END
GO
