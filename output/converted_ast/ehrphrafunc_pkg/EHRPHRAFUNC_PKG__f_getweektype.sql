CREATE OR ALTER FUNCTION [ehrphrafunc_pkg].[f_getweektype]
(    @Attdate_IN DATETIME2(0)
)
RETURNS NVARCHAR(MAX)
AS
BEGIN
DECLARE @dAttdate DATETIME2(0) = @Attdate_IN;
DECLARE @sRtnType VARCHAR(1);
DECLARE @sDay VARCHAR(1);
DECLARE @iCnt INT;
  
    -- EXCEPTION block removed: TRY/CATCH not allowed in T-SQL scalar function

    SELECT @iCnt = COUNT(*)
    FROM HRA_HOLIDAY
       WHERE HOLI_DATE = @dAttdate
         AND HOLI_TYPE = 'A';

  
    IF @iCnt > 0 BEGIN
      SET @sRtnType = 'H';
    END
    ELSE
    BEGIN
      SET @sDay = FORMAT(@dAttdate, 'D');
      IF @sDay = '7' BEGIN
        SET @sRtnType = 'W';
      END
ELSE IF @sDay = '1' BEGIN
        SET @sRtnType = 'H';
      END
      ELSE
      BEGIN
        SET @sRtnType = 'N';
      END
    END
  
    RETURN(@sRtnType);
END
GO
