
USE MIS
GO
 IF NOT EXISTS(SELECT * FROM sys.schemas WHERE [name] = N'hrp')      
     EXEC (N'CREATE SCHEMA hrp')                                   
 GO                                                               

USE MIS
GO
IF  EXISTS (SELECT * FROM sys.objects so JOIN sys.schemas sc ON so.schema_id = sc.schema_id WHERE so.name = N'EHRPHRA12_PKG$UPDATE_DEPUTYSUP'  AND sc.name=N'hrp'  AND type in (N'P',N'PC'))
 DROP PROCEDURE [hrp].[EHRPHRA12_PKG$UPDATE_DEPUTYSUP]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE HRP.EHRPHRA12_PKG$UPDATE_DEPUTYSUP  
   @EMPNO_IN varchar(max),
   @STARTDATE_IN varchar(max),
   @ENDDATE_IN varchar(max),
   @STATUS_IN varchar(max),
   @UPDATE_IN varchar(max)
AS 
   BEGIN

      EXECUTE ssma_oracle.db_check_init_package 'HRP', 'EHRPHRA12_PKG'

      DECLARE
         /*
         *   SSMA warning messages:
         *   O2SS0356: Conversion from NUMBER datatype can cause data loss.
         */

         @CNT float(53)

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

      IF @CNT <> 0 AND @STATUS_IN IN ( 'D', 'N' )
         UPDATE HRP.HRE_DEPUTY
            SET 
               DISABLED = 'Y', 
               LAST_UPDATED_BY = @UPDATE_IN, 
               LAST_UPDATE_DATE = sysdatetime()
         WHERE 
            HRE_DEPUTY.EMP_NO = @EMPNO_IN AND 
            ssma_oracle.to_char_date(HRE_DEPUTY.EFFECT_DATE, 'yyyy-mm-dd') = @STARTDATE_IN AND 
            ssma_oracle.to_char_date(HRE_DEPUTY.EXPIRE_DATE, 'yyyy-mm-dd') = @ENDDATE_IN
      ELSE 
         BEGIN
            IF @CNT <> 0 AND @STATUS_IN IN (  'Y' )
               UPDATE HRP.HRE_DEPUTY
                  SET 
                     DISABLED = 'N', 
                     LAST_UPDATED_BY = @UPDATE_IN, 
                     LAST_UPDATE_DATE = sysdatetime()
               WHERE 
                  HRE_DEPUTY.EMP_NO = @EMPNO_IN AND 
                  ssma_oracle.to_char_date(HRE_DEPUTY.EFFECT_DATE, 'yyyy-mm-dd') = @STARTDATE_IN AND 
                  ssma_oracle.to_char_date(HRE_DEPUTY.EXPIRE_DATE, 'yyyy-mm-dd') = @ENDDATE_IN
         END

      IF @@TRANCOUNT > 0
         COMMIT TRANSACTION 

   END
GO
BEGIN TRY
    EXEC sp_addextendedproperty
        N'MS_SSMA_SOURCE', N'HRP.EHRPHRA12_PKG.Update_DeputySup',
        N'SCHEMA', N'hrp',
        N'PROCEDURE', N'EHRPHRA12_PKG$UPDATE_DEPUTYSUP'
END TRY
BEGIN CATCH
    IF (@@TRANCOUNT > 0) ROLLBACK
    PRINT ERROR_MESSAGE()
END CATCH
GO
