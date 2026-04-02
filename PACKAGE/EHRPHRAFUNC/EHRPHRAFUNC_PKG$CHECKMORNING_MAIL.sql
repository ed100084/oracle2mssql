
USE MIS
GO
 IF NOT EXISTS(SELECT * FROM sys.schemas WHERE [name] = N'hrp')      
     EXEC (N'CREATE SCHEMA hrp')                                   
 GO                                                               

USE MIS
GO
IF  EXISTS (SELECT * FROM sys.objects so JOIN sys.schemas sc ON so.schema_id = sc.schema_id WHERE so.name = N'EHRPHRAFUNC_PKG$CHECKMORNING_MAIL'  AND sc.name=N'hrp'  AND type in (N'P',N'PC'))
 DROP PROCEDURE [hrp].[EHRPHRAFUNC_PKG$CHECKMORNING_MAIL]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE HRP.EHRPHRAFUNC_PKG$CHECKMORNING_MAIL  
AS 
   BEGIN

      EXECUTE ssma_oracle.db_check_init_package 'HRP', 'EHRPHRAFUNC_PKG'

      DECLARE
         /*
         *   SSMA warning messages:
         *   O2SS0356: Conversion from NUMBER datatype can cause data loss.
         */

         @ICNT float(53)

      BEGIN

         BEGIN TRY
            SELECT @ICNT = count_big(*)
            FROM HRP.HRA_UNNORMAL_LOG
            WHERE ssma_oracle.trunc_date(HRA_UNNORMAL_LOG.SYS_DATE) = ssma_oracle.trunc_date(sysdatetime())
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
               SET @ICNT = 0
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

      /*20220715僅確認收件者有行政長的一級主管假卡、醫師假卡、出國假卡三項通知*/
      IF @ICNT <> 0
         BEGIN

            DECLARE
               @temp varchar(8000)

            SET @temp = '請確認HRA_UNNORMAL_LOG記錄的異常訊息<br>' + 'SELECT * FROM HRA_UNNORMAL_LOG WHERE TRUNC(SYS_DATE) = TRUNC(SYSDATE);'

            EXECUTE HRP.EHRPHRAFUNC_PKG$POST_HTML_MAIL 
               @SENDER = 'system@edah.org.tw', 
               @RECIPIENT = 'ed108482@edah.org.tw', 
               @CC_RECIPIENT = NULL, 
               @MAILTYPE = '1', 
               @SUBJECT = '上午7點信件發送異常', 
               @MESSAGE = @temp

            DECLARE
               @temp$2 varchar(8000)

            SET @temp$2 = '請確認HRA_UNNORMAL_LOG記錄的異常訊息<br>' + 'SELECT * FROM HRA_UNNORMAL_LOG WHERE TRUNC(SYS_DATE) = TRUNC(SYSDATE);'

            EXECUTE HRP.EHRPHRAFUNC_PKG$POST_HTML_MAIL 
               @SENDER = 'system@edah.org.tw', 
               @RECIPIENT = 'ed108154@edah.org.tw', 
               @CC_RECIPIENT = NULL, 
               @MAILTYPE = '1', 
               @SUBJECT = '上午7點信件發送異常', 
               @MESSAGE = @temp$2

            DECLARE
               @temp$3 varchar(8000)

            SET @temp$3 = '請確認HRA_UNNORMAL_LOG記錄的異常訊息<br>' + 'SELECT * FROM HRA_UNNORMAL_LOG WHERE TRUNC(SYS_DATE) = TRUNC(SYSDATE);'

            EXECUTE HRP.EHRPHRAFUNC_PKG$POST_HTML_MAIL 
               @SENDER = 'system@edah.org.tw', 
               @RECIPIENT = 'ed100037@edah.org.tw', 
               @CC_RECIPIENT = NULL, 
               @MAILTYPE = '1', 
               @SUBJECT = '上午7點信件發送異常', 
               @MESSAGE = @temp$3

         END

      /* 
      *   SSMA error messages:
      *   O2SS0083: Identifier ehrphra7_pkg.hra9000 cannot be converted because it was not resolved.

      EXECUTE EHRPHRA7_PKG.HRA9000
      */



   END
GO
BEGIN TRY
    EXEC sp_addextendedproperty
        N'MS_SSMA_SOURCE', N'HRP.EHRPHRAFUNC_PKG.CHECKMORNING_MAIL',
        N'SCHEMA', N'hrp',
        N'PROCEDURE', N'EHRPHRAFUNC_PKG$CHECKMORNING_MAIL'
END TRY
BEGIN CATCH
    IF (@@TRANCOUNT > 0) ROLLBACK
    PRINT ERROR_MESSAGE()
END CATCH
GO
