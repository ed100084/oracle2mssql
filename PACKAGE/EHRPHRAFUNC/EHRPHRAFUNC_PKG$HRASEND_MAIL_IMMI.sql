
USE MIS
GO
 IF NOT EXISTS(SELECT * FROM sys.schemas WHERE [name] = N'hrp')      
     EXEC (N'CREATE SCHEMA hrp')                                   
 GO                                                               

USE MIS
GO
IF  EXISTS (SELECT * FROM sys.objects so JOIN sys.schemas sc ON so.schema_id = sc.schema_id WHERE so.name = N'EHRPHRAFUNC_PKG$HRASEND_MAIL_IMMI'  AND sc.name=N'hrp'  AND type in (N'P',N'PC'))
 DROP PROCEDURE [hrp].[EHRPHRAFUNC_PKG$HRASEND_MAIL_IMMI]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE HRP.EHRPHRAFUNC_PKG$HRASEND_MAIL_IMMI  
   @EMPNO_IN varchar(max),
   /*
   *   SSMA warning messages:
   *   O2SS0356: Conversion from NUMBER datatype can cause data loss.
   */

   @RTNCODE float(53)  OUTPUT
AS 
   BEGIN

      SET @RTNCODE = NULL

      EXECUTE ssma_oracle.db_check_init_package 'HRP', 'EHRPHRAFUNC_PKG'

      DECLARE
         @SEMPNAME varchar(200), 
         @SEEMAIL varchar(120), 
         @SMESSAGE varchar(255), 
         @SDEPTNAME varchar(60), 
         @SPOSNAME varchar(60), 
         @STITLE varchar(50), 
         @SORGAN varchar(120)

      BEGIN

         BEGIN TRY
            SELECT @SEMPNAME = HRE_EMPBAS.CH_NAME, @SDEPTNAME = HRE_ORGBAS.CH_NAME, @SPOSNAME = HRE_POSMST.CH_NAME, @SORGAN = 
               (
                  SELECT PUS_ORGSYS.BAN_NM
                  FROM HRP.PUS_ORGSYS
                  WHERE PUS_ORGSYS.ORGAN_TYPE = HRP.F_FLOW_ORGAN(HRE_EMPBAS.EMP_NO, HRE_EMPBAS.ORGAN_TYPE)
               )
            FROM HRP.HRE_EMPBAS, HRP.HRE_ORGBAS, HRP.HRE_POSMST
            WHERE 
               HRE_EMPBAS.DEPT_NO = HRE_ORGBAS.DEPT_NO AND 
               HRE_EMPBAS.POS_NO = HRE_POSMST.POS_NO AND 
               HRE_EMPBAS.EMP_NO = @EMPNO_IN
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
               BEGIN

                  SET @SEMPNAME = NULL

                  SET @SDEPTNAME = NULL

               END
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

      SET @STITLE = '出入境管理-輸入症狀通知'

      SET @SMESSAGE = 
         'MIS出入境管理,'
          + 
         ISNULL(@SORGAN, '')
          + 
         ' '
          + 
         ISNULL(@EMPNO_IN, '')
          + 
         '('
          + 
         ISNULL(@SEMPNAME, '')
          + 
         ')'
          + 
         '輸入相關症狀資料,請進入MIS出入境管理相關報表查詢'

      DECLARE
          CURSOR2 CURSOR LOCAL FOR 
            SELECT HR_CODEDTL.CODE_NAME
            FROM HRP.HR_CODEDTL
            WHERE 
               HR_CODEDTL.CODE_TYPE = 'HRA99' AND 
               HR_CODEDTL.CODE_NO LIKE 'A%' AND 
               HR_CODEDTL.DISABLED = 'N'

      /*抓通知人員的資訊*/
      OPEN CURSOR2

      WHILE 1 = 1
      
         BEGIN

            FETCH CURSOR2
                INTO @SEEMAIL

            /*
            *   SSMA warning messages:
            *   O2SS0113: The value of @@FETCH_STATUS might be changed by previous FETCH operations on other cursors, if the cursors are used simultaneously.
            */

            IF @@FETCH_STATUS <> 0
               BREAK

            EXECUTE HRP.EHRPHRAFUNC_PKG$POST_HTML_MAIL 
               @SENDER = 'system@edah.org.tw', 
               @RECIPIENT = @SEEMAIL, 
               @CC_RECIPIENT = 'ed108482@edah.org.tw', 
               @MAILTYPE = '1', 
               @SUBJECT = @STITLE, 
               @MESSAGE = @SMESSAGE

         END

      CLOSE CURSOR2

      DEALLOCATE CURSOR2

      SET @RTNCODE = 0

   END
GO
BEGIN TRY
    EXEC sp_addextendedproperty
        N'MS_SSMA_SOURCE', N'HRP.EHRPHRAFUNC_PKG.HRASEND_MAIL_IMMI',
        N'SCHEMA', N'hrp',
        N'PROCEDURE', N'EHRPHRAFUNC_PKG$HRASEND_MAIL_IMMI'
END TRY
BEGIN CATCH
    IF (@@TRANCOUNT > 0) ROLLBACK
    PRINT ERROR_MESSAGE()
END CATCH
GO
