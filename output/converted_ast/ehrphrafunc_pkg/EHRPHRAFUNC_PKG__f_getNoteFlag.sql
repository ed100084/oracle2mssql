CREATE OR ALTER FUNCTION [ehrphrafunc_pkg].[f_getNoteFlag]
(    @startdate NVARCHAR(MAX)
)
RETURNS NVARCHAR(MAX)
AS
BEGIN
DECLARE @rNoteFlag NVARCHAR(1);
DECLARE @iHOLI_TYPE NVARCHAR(3);
DECLARE @iHOLI_WEEK NVARCHAR(3);
  
    -- EXCEPTION block removed: TRY/CATCH not allowed in T-SQL scalar function

    SELECT @iHOLI_TYPE = HOLI_TYPE, @iHOLI_WEEK = HOLI_WEEK
    FROM HRP.HRA_HOLIDAY
       WHERE FORMAT(HOLI_DATE, 'yyyy-MM-dd') = @startdate;

  
    -- IF @iHOLI_TYPE = 'D' THEN 20161227 新增例假日，休息日
    IF @iHOLI_TYPE IN ('D', 'X') BEGIN
      IF @iHOLI_WEEK = 'SAT' BEGIN
        SET @rNoteFlag = 'D';
      END
      ELSE
      BEGIN
        SET @rNoteFlag = 'C';
      END
    END
ELSE IF @iHOLI_TYPE = 'A' BEGIN
      SET @rNoteFlag = 'B';
    END
  
    return @rNoteFlag;
END
GO
