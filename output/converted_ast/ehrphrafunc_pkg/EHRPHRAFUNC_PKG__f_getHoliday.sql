CREATE OR ALTER FUNCTION [ehrphrafunc_pkg].[f_getHoliday]
(    @p_day NVARCHAR(MAX)
)
RETURNS NVARCHAR(MAX)
AS
BEGIN
DECLARE @RtnCode NVARCHAR(1);
DECLARE @sDay NVARCHAR(10) = @p_day;
DECLARE @iHOLI_TYPE NVARCHAR(10);
DECLARE @iHOLI_WEEK NVARCHAR(10);
    -- EXCEPTION block removed: TRY/CATCH not allowed in T-SQL scalar function

    SELECT @iHOLI_TYPE = HOLI_TYPE, @iHOLI_WEEK = HOLI_WEEK
    FROM HRP.HRA_HOLIDAY
       WHERE FORMAT(HOLI_DATE, 'yyyy-MM-dd') = @sDay;
    
      --IF @iHOLI_TYPE = 'D' THEN  --  IF 週休 20161227 區分例假日，休息日
      IF @iHOLI_TYPE IN ('D', 'X') BEGIN
        --  IF 週休
      
        IF @iHOLI_WEEK = 'SAT' BEGIN
          -- IF 週六
        
          SET @RtnCode = 'D';
        END
      
        IF @iHOLI_WEEK = 'SUN' BEGIN
          -- IF 週日
        
          SET @RtnCode = 'C';
        END
      
      END
ELSE IF @iHOLI_TYPE = 'A' BEGIN
        -- IF 國定假日
        SET @RtnCode = 'B';
      END

  
    return @RtnCode;
END
GO
