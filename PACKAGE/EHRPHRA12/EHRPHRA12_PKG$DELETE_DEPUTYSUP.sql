
USE MIS
GO
 IF NOT EXISTS(SELECT * FROM sys.schemas WHERE [name] = N'hrp')      
     EXEC (N'CREATE SCHEMA hrp')                                   
 GO                                                               

USE MIS
GO
IF  EXISTS (SELECT * FROM sys.objects so JOIN sys.schemas sc ON so.schema_id = sc.schema_id WHERE so.name = N'EHRPHRA12_PKG$DELETE_DEPUTYSUP'  AND sc.name=N'hrp'  AND type in (N'P',N'PC'))
 DROP PROCEDURE [hrp].[EHRPHRA12_PKG$DELETE_DEPUTYSUP]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE HRP.EHRPHRA12_PKG$DELETE_DEPUTYSUP  
   @EMPNO_IN varchar(max),
   @STARTDATE_IN varchar(max),
   @ENDDATE_IN varchar(max)
AS 
   BEGIN

      EXECUTE ssma_oracle.db_check_init_package 'HRP', 'EHRPHRA12_PKG'

      DECLARE
         /*
         *   SSMA warning messages:
         *   O2SS0356: Conversion from NUMBER datatype can cause data loss.
         */

         @CNT float(53)/*確認是否有代理資料*/

      SET @CNT = 0

      BEGIN

         BEGIN TRY
            SELECT @CNT = count_big(*)
            FROM HRP.HRE_DEPUTY
            WHERE 
               HRE_DEPUTY.EMP_NO = @EMPNO_IN AND 
               ssma_oracle.to_char_date(HRE_DEPUTY.EFFECT_DATE, 'yyyy-mm-dd') = @STARTDATE_IN AND 
               ssma_oracle.to_char_date(HRE_DEPUTY.EXPIRE_DATE, 'yyyy-mm-dd') = @ENDDATE_IN
         END TRY

         BEGIN CATCH
            BEGIN
               SET @CNT = 0
            END
         END CATCH

      END

      IF @CNT <> 0
         BEGIN

            DELETE HRP.HRE_DEPUTY
            WHERE 
               HRE_DEPUTY.EMP_NO = @EMPNO_IN AND 
               ssma_oracle.to_char_date(HRE_DEPUTY.EFFECT_DATE, 'yyyy-mm-dd') = @STARTDATE_IN AND 
               ssma_oracle.to_char_date(HRE_DEPUTY.EXPIRE_DATE, 'yyyy-mm-dd') = @ENDDATE_IN

            IF @@TRANCOUNT > 0
               COMMIT TRANSACTION 

         END

   END
GO
BEGIN TRY
    EXEC sp_addextendedproperty
        N'MS_SSMA_SOURCE', N'HRP.EHRPHRA12_PKG.Delete_DeputySup',
        N'SCHEMA', N'hrp',
        N'PROCEDURE', N'EHRPHRA12_PKG$DELETE_DEPUTYSUP'
END TRY
BEGIN CATCH
    IF (@@TRANCOUNT > 0) ROLLBACK
    PRINT ERROR_MESSAGE()
END CATCH
GO
