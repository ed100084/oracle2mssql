
USE MIS
GO
 IF NOT EXISTS(SELECT * FROM sys.schemas WHERE [name] = N'hrp')      
     EXEC (N'CREATE SCHEMA hrp')                                   
 GO                                                               

USE MIS
GO
IF  EXISTS (SELECT * FROM sys.objects so JOIN sys.schemas sc ON so.schema_id = sc.schema_id WHERE so.name = N'EHRPHRAFUNC_PKG$POST_HTML_MAIL2'  AND sc.name=N'hrp'  AND type in (N'P',N'PC'))
 DROP PROCEDURE [hrp].[EHRPHRAFUNC_PKG$POST_HTML_MAIL2]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE HRP.EHRPHRAFUNC_PKG$POST_HTML_MAIL2  
   @SENDER varchar(max),
   @RECIPIENT varchar(max),
   @CC_RECIPIENT varchar(max),
   @MAILTYPE varchar(max),
   @SUBJECT varchar(max),
   @MESSAGE varchar(max)
AS 
   BEGIN

      /*mailhost VARCHAR2(30) := '10.6.3.12';*/
      DECLARE
         @MAILHOST varchar(30) = 'ntexcas01.edah.org.tw', 
         /* 
         *   SSMA error messages:
         *   O2SS0005: The source datatype 'utl_smtp.connection' was not recognized.
         */

         @MAIL_CONN varchar(8000), 
         @CRLF varchar(2) = ISNULL(char(13), '') + ISNULL(char(10), ''), 
         /*
         *   SSMA warning messages:
         *   O2SS0356: Conversion from NUMBER datatype can cause data loss.
         */

         @ERRNUM float(53), 
         @MESG varchar(max)

      BEGIN TRY

         EXECUTE ssma_oracle.db_check_init_package 'HRP', 'EHRPHRAFUNC_PKG'

         /* 
         *   SSMA error messages:
         *   O2SS0560: Identifier utl_smtp.open_connection cannot be converted because it was not resolved.
         *   This may happen because system package that defines the identifier was excluded from loading in Project Settings.

         SET @MAIL_CONN = UTL_SMTP.OPEN_CONNECTION
         */



         /* 
         *   SSMA error messages:
         *   O2SS0560: Identifier utl_smtp.helo cannot be converted because it was not resolved.
         *   This may happen because system package that defines the identifier was excluded from loading in Project Settings.

         EXECUTE UTL_SMTP.HELO
         */



         /* 
         *   SSMA error messages:
         *   O2SS0560: Identifier utl_smtp.mail cannot be converted because it was not resolved.
         *   This may happen because system package that defines the identifier was excluded from loading in Project Settings.

         EXECUTE UTL_SMTP.MAIL
         */



         /* 
         *   SSMA error messages:
         *   O2SS0560: Identifier utl_smtp.rcpt cannot be converted because it was not resolved.
         *   This may happen because system package that defines the identifier was excluded from loading in Project Settings.

         EXECUTE UTL_SMTP.RCPT
         */



         IF (@MAILTYPE = 2 OR @MAILTYPE = 3)
            /* 
            *   SSMA error messages:
            *   O2SS0560: Identifier utl_smtp.rcpt cannot be converted because it was not resolved.
            *   This may happen because system package that defines the identifier was excluded from loading in Project Settings.

            EXECUTE UTL_SMTP.RCPT
            */


            DECLARE
               @db_null_statement int

         SET @MESG = @MESSAGE

         /* 
         *   SSMA error messages:
         *   O2SS0560: Identifier UTL_SMTP.OPEN_DATA cannot be converted because it was not resolved.
         *   This may happen because system package that defines the identifier was excluded from loading in Project Settings.

         EXECUTE UTL_SMTP.OPEN_DATA
         */



         /* 
         *   SSMA error messages:
         *   O2SS0560: Identifier UTL_smtp.write_raw_data cannot be converted because it was not resolved.
         *   This may happen because system package that defines the identifier was excluded from loading in Project Settings.

         /*主旨*/
         EXECUTE UTL_SMTP.WRITE_RAW_DATA
         */



         /* 
         *   SSMA error messages:
         *   O2SS0560: Identifier UTL_SMTP.WRITE_DATA cannot be converted because it was not resolved.
         *   This may happen because system package that defines the identifier was excluded from loading in Project Settings.

         /*編碼*/
         EXECUTE UTL_SMTP.WRITE_DATA
         */



         /* 
         *   SSMA error messages:
         *   O2SS0560: Identifier UTL_SMTP.WRITE_DATA cannot be converted because it was not resolved.
         *   This may happen because system package that defines the identifier was excluded from loading in Project Settings.

         EXECUTE UTL_SMTP.WRITE_DATA
         */



         /* 
         *   SSMA error messages:
         *   O2SS0560: Identifier UTL_SMTP.WRITE_DATA cannot be converted because it was not resolved.
         *   This may happen because system package that defines the identifier was excluded from loading in Project Settings.

         /*寄件人*/
         EXECUTE UTL_SMTP.WRITE_DATA
         */



         /* 
         *   SSMA error messages:
         *   O2SS0560: Identifier UTL_SMTP.WRITE_DATA cannot be converted because it was not resolved.
         *   This may happen because system package that defines the identifier was excluded from loading in Project Settings.

         /*收件人*/
         EXECUTE UTL_SMTP.WRITE_DATA
         */



         IF (@MAILTYPE = 3)
            /* 
            *   SSMA error messages:
            *   O2SS0560: Identifier UTL_SMTP.WRITE_DATA cannot be converted because it was not resolved.
            *   This may happen because system package that defines the identifier was excluded from loading in Project Settings.

            EXECUTE UTL_SMTP.WRITE_DATA
            */


            DECLARE
               @db_null_statement$2 int

         /* 
         *   SSMA error messages:
         *   O2SS0560: Identifier UTL_SMTP.WRITE_DATA cannot be converted because it was not resolved.
         *   This may happen because system package that defines the identifier was excluded from loading in Project Settings.

         EXECUTE UTL_SMTP.WRITE_DATA
         */



         /* 
         *   SSMA error messages:
         *   O2SS0560: Identifier UTL_SMTP.WRITE_DATA cannot be converted because it was not resolved.
         *   This may happen because system package that defines the identifier was excluded from loading in Project Settings.

         EXECUTE UTL_SMTP.WRITE_DATA
         */



         /* 
         *   SSMA error messages:
         *   O2SS0560: Identifier UTL_SMTP.CLOSE_DATA cannot be converted because it was not resolved.
         *   This may happen because system package that defines the identifier was excluded from loading in Project Settings.

         EXECUTE UTL_SMTP.CLOSE_DATA
         */



         /* 
         *   SSMA error messages:
         *   O2SS0560: Identifier UTL_SMTP.quit cannot be converted because it was not resolved.
         *   This may happen because system package that defines the identifier was excluded from loading in Project Settings.

         EXECUTE UTL_SMTP.QUIT
         */



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

            DECLARE
               @db_null_statement$3 int

            SET @ERRNUM = ssma_oracle.db_error_sqlcode(@exceptionidentifier, @errornumber)

         END

      END CATCH

   END
GO
BEGIN TRY
    EXEC sp_addextendedproperty
        N'MS_SSMA_SOURCE', N'HRP.EHRPHRAFUNC_PKG.POST_HTML_MAIL2',
        N'SCHEMA', N'hrp',
        N'PROCEDURE', N'EHRPHRAFUNC_PKG$POST_HTML_MAIL2'
END TRY
BEGIN CATCH
    IF (@@TRANCOUNT > 0) ROLLBACK
    PRINT ERROR_MESSAGE()
END CATCH
GO
