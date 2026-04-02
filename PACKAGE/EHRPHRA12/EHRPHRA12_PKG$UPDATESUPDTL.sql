
USE MIS
GO
 IF NOT EXISTS(SELECT * FROM sys.schemas WHERE [name] = N'hrp')      
     EXEC (N'CREATE SCHEMA hrp')                                   
 GO                                                               

USE MIS
GO
IF  EXISTS (SELECT * FROM sys.objects so JOIN sys.schemas sc ON so.schema_id = sc.schema_id WHERE so.name = N'EHRPHRA12_PKG$UPDATESUPDTL'  AND sc.name=N'hrp'  AND type in (N'P',N'PC'))
 DROP PROCEDURE [hrp].[EHRPHRA12_PKG$UPDATESUPDTL]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE HRP.EHRPHRA12_PKG$UPDATESUPDTL  
   @SUPNO_IN varchar(max),
   @EMPNO_IN varchar(max)
AS 
   BEGIN

      DECLARE
         /*
         *   SSMA warning messages:
         *   O2SS0356: Conversion from NUMBER datatype can cause data loss.
         */

         @CCUNT float(53)

      BEGIN TRY

         EXECUTE ssma_oracle.db_check_init_package 'HRP', 'EHRPHRA12_PKG'

         SET @CCUNT = 0

         BEGIN

            BEGIN TRY
               SELECT @CCUNT = count_big(*)
               FROM HRP.HRA_SUPDTL
               WHERE HRA_SUPDTL.STATUS = 'Y' AND HRA_SUPDTL.SUP_NO = @SUPNO_IN
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

               IF (@exceptionidentifier LIKE N'ORA-00100%')
                  SET @CCUNT = 0
               ELSE 
                  BEGIN
                     IF (@exceptionidentifier IS NOT NULL)
                        BEGIN
                           IF @errornumber = 59998
                              RAISERROR(59998, 16, 1, @exceptionidentifier)
                           ELSE 
                              RAISERROR(59999, 16, 1, @exceptionidentifier)
                        END
                     ELSE 
                        BEGIN
                           EXECUTE ssma_oracle.ssma_rethrowerror
                        END
                  END

            END CATCH

         END

         IF @CCUNT <> 0
            UPDATE HRP.HRA_SUPDTL
               SET 
                  STATUS = 'N', 
                  LAST_UPDATED_BY = @EMPNO_IN, 
                  LAST_UPDATE_DATE = sysdatetime()
            WHERE HRA_SUPDTL.SUP_NO = @SUPNO_IN

         IF @@TRANCOUNT > 0
            COMMIT TRANSACTION 

      END TRY

      BEGIN CATCH

         DECLARE
            @errornumber$2 int

         SET @errornumber$2 = ERROR_NUMBER()

         DECLARE
            @errormessage$2 nvarchar(4000)

         SET @errormessage$2 = ERROR_MESSAGE()

         DECLARE
            @exceptionidentifier$2 nvarchar(4000)

         SELECT @exceptionidentifier$2 = ssma_oracle.db_error_get_oracle_exception_id(@errormessage$2, @errornumber$2)

         BEGIN

            IF @@TRANCOUNT > 0
               ROLLBACK WORK 

            DECLARE
               @temp nvarchar(4000)

            SET @temp = '執行EHRPHRA12_PKG.PROCEDURE UpdateSupdtl，但SQLCODE=' + ISNULL(CAST(ssma_oracle.db_error_sqlcode(@exceptionidentifier$2, @errornumber$2) AS nvarchar(max)), '')

            EXECUTE HRP.EHRPHRAFUNC_PKG$POST_HTML_MAIL 
               @SENDER = 'system@edah.org.tw', 
               @RECIPIENT = 'ed108482@edah.org.tw', 
               @CC_RECIPIENT = NULL, 
               @MAILTYPE = '1', 
               @SUBJECT = '補休退回調整明細作業(異常)', 
               @MESSAGE = @temp

         END

      END CATCH

   END
GO
BEGIN TRY
    EXEC sp_addextendedproperty
        N'MS_SSMA_SOURCE', N'HRP.EHRPHRA12_PKG.UpdateSupdtl',
        N'SCHEMA', N'hrp',
        N'PROCEDURE', N'EHRPHRA12_PKG$UPDATESUPDTL'
END TRY
BEGIN CATCH
    IF (@@TRANCOUNT > 0) ROLLBACK
    PRINT ERROR_MESSAGE()
END CATCH
GO
