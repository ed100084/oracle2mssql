CREATE OR ALTER FUNCTION [ehrphrafunc_pkg].[f_getShift]
(    @ClassCode NVARCHAR(MAX),
    @Startime NVARCHAR(MAX),
    @Endtime NVARCHAR(MAX)
)
RETURNS NVARCHAR(MAX)
AS
BEGIN
DECLARE @rShift NVARCHAR(3);
DECLARE @iShift NVARCHAR(1);
DECLARE cursor1 CURSOR FOR
    SELECT SHIFT_NO
        FROM HRP.HRA_CLASSDTL
       Where CLASS_CODE = @ClassCode
         AND (@Startime > chkin_wktm OR @Endtime > chkin_wktm)
            
         AND SHIFT_NO < 4
       ORDER BY SHIFT_NO ASC;
DECLARE cursor2 CURSOR FOR
    SELECT SHIFT_NO
        FROM HRP.HRA_CLASSDTL
       Where CLASS_CODE = @ClassCode
         AND (@Startime > chkin_wktm OR @Endtime < chkin_wktm)
         AND SHIFT_NO < 4
       ORDER BY SHIFT_NO ASC;
  
    IF @Startime < @Endtime BEGIN
    
      OPEN cursor1;
      WHILE 1=1 BEGIN
        FETCH NEXT FROM cursor1 INTO @iShift;
      
        IF @@FETCH_STATUS <> 0 BREAK;
      
        SET @rShift = @rShift + @iShift;
        Continue_ForEach1_1:
      END
      CLOSE cursor1;
    DEALLOCATE cursor1
    
    END
    ELSE
    BEGIN
      OPEN cursor2;
      WHILE 1=1 BEGIN
        FETCH NEXT FROM cursor2 INTO @iShift;
      
        IF @@FETCH_STATUS <> 0 BREAK;
      
        SET @rShift = @rShift + @iShift;
        Continue_ForEach1_2:
      END
      CLOSE cursor2;
    DEALLOCATE cursor2
    END
    return @rShift;
END
GO
