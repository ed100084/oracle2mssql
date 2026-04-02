
USE MIS
GO
 IF NOT EXISTS(SELECT * FROM sys.schemas WHERE [name] = N'hrp')      
     EXEC (N'CREATE SCHEMA hrp')                                   
 GO                                                               

USE MIS
GO
IF  EXISTS (SELECT * FROM sys.objects so JOIN sys.schemas sc ON so.schema_id = sc.schema_id WHERE so.name = N'EHRPHRA12_PKG$HRAC060'  AND sc.name=N'hrp'  AND type in (N'P',N'PC'))
 DROP PROCEDURE [hrp].[EHRPHRA12_PKG$HRAC060]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE HRP.EHRPHRA12_PKG$HRAC060  
   @EMPNO_IN varchar(max),
   @STARTDATE_IN varchar(max),
   @MERGE_IN varchar(max),
   @USER_IN varchar(max),
   /*
   *   SSMA warning messages:
   *   O2SS0356: Conversion from NUMBER datatype can cause data loss.
   */

   @RTNCODE float(53)  OUTPUT
AS 
   BEGIN

      DECLARE
         /*
         *   SSMA warning messages:
         *   O2SS0356: Conversion from NUMBER datatype can cause data loss.
         */

         @ICNT float(53)

      BEGIN TRY

         SET @RTNCODE = NULL

         EXECUTE ssma_oracle.db_check_init_package 'HRP', 'EHRPHRA12_PKG'

         SELECT @ICNT = count_big(*)
         FROM HRP.HRA_OFFREC
         WHERE HRA_OFFREC.EMP_NO = @EMPNO_IN AND ssma_oracle.to_char_date(HRA_OFFREC.START_DATE_TMP, 'yyyy-mm-dd') = @STARTDATE_IN

         IF @ICNT - CAST(@MERGE_IN AS float(53)) <> 0
            UPDATE HRP.HRA_OFFREC
               SET 
                  MERGE = CAST(HRA_OFFREC.MERGE AS float(53)) - 1, 
                  LAST_UPDATE_DATE = sysdatetime(), 
                  LAST_UPDATED_BY = @USER_IN
            WHERE 
               HRA_OFFREC.EMP_NO = @EMPNO_IN AND 
               ssma_oracle.to_char_date(HRA_OFFREC.START_DATE_TMP, 'yyyy-mm-dd') = @STARTDATE_IN AND 
               HRA_OFFREC.MERGE > @MERGE_IN

         IF @@TRANCOUNT > 0
            COMMIT TRANSACTION 

         SET @RTNCODE = @ICNT

      END TRY

      BEGIN CATCH

         DECLARE
            @errornumber int

         SET @errornumber = ERROR_NUMBER()

         DECLARE
            @errormessage nvarchar(4000)

         SET @errormessage = ERROR_MESSAGE()

         DECLARE
            @exceptionidentifier nvarchar(4000)

         SELECT @exceptionidentifier = ssma_oracle.db_error_get_oracle_exception_id(@errormessage, @errornumber)

         BEGIN

            IF @@TRANCOUNT > 0
               ROLLBACK WORK 

            SET @RTNCODE = ssma_oracle.db_error_sqlcode(@exceptionidentifier, @errornumber)

         END

      END CATCH

   END
GO
BEGIN TRY
    EXEC sp_addextendedproperty
        N'MS_SSMA_SOURCE', N'HRP.EHRPHRA12_PKG.hraC060',
        N'SCHEMA', N'hrp',
        N'PROCEDURE', N'EHRPHRA12_PKG$HRAC060'
END TRY
BEGIN CATCH
    IF (@@TRANCOUNT > 0) ROLLBACK
    PRINT ERROR_MESSAGE()
END CATCH
GO
