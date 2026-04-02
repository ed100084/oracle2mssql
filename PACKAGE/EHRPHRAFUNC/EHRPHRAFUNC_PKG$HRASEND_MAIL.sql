
USE MIS
GO
 IF NOT EXISTS(SELECT * FROM sys.schemas WHERE [name] = N'hrp')      
     EXEC (N'CREATE SCHEMA hrp')                                   
 GO                                                               

USE MIS
GO
IF  EXISTS (SELECT * FROM sys.objects so JOIN sys.schemas sc ON so.schema_id = sc.schema_id WHERE so.name = N'EHRPHRAFUNC_PKG$HRASEND_MAIL'  AND sc.name=N'hrp'  AND type in (N'P',N'PC'))
 DROP PROCEDURE [hrp].[EHRPHRAFUNC_PKG$HRASEND_MAIL]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE HRP.EHRPHRAFUNC_PKG$HRASEND_MAIL  
   @EMPNO_IN varchar(max),
   @PROCTYPE_IN varchar(max),
   @PROCMSG_IN varchar(max),
   @EXUSERID_IN varchar(max),
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
         @SCOMEDATE datetime2(0), 
         @STITLE varchar(50), 
         @PMSGNO varchar(20)

      BEGIN

         BEGIN TRY

            EXECUTE HRP.EHRPHRAFUNC_PKG$POST_HTML_MAIL 
               @SENDER = 'system@edah.org.tw', 
               @RECIPIENT = 'ed101961@edah.org.tw', 
               @CC_RECIPIENT = 'ed101961@edah.org.tw', 
               @MAILTYPE = '2', 
               @SUBJECT = 'ㄧ級主管假卡劉協理審核test', 
               @MESSAGE = 'ㄧ級主管假卡劉協理審核test'

            /*抓該名員工的資訊*/
            SELECT @SEMPNAME = /*hre_empbas.e_mail,*/HRE_EMPBAS.CH_NAME, @SDEPTNAME = HRE_ORGBAS.CH_NAME, @SPOSNAME = HRE_POSMST.CH_NAME, @SCOMEDATE = HRE_EMPBAS.COME_DATE
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

                  /*sEMail    := NULL;*/
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

      /*抓通知人員的資訊*/
      BEGIN

         BEGIN TRY
            /*抓該名員工簽核者或人事課人員的資訊*/
            SELECT @SEEMAIL = HRE_EMPBAS.E_MAIL
            FROM HRP.HRE_EMPBAS, HRP.HRE_ORGBAS
            WHERE (HRE_EMPBAS.DEPT_NO = HRE_ORGBAS.DEPT_NO) AND (HRE_EMPBAS.EMP_NO = @EXUSERID_IN)
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

            IF (@exceptionidentifier$2 LIKE N'ORA-00100%')
               BEGIN

                  SET @SEEMAIL = NULL

                  SET @SEMPNAME = NULL

                  SET @SDEPTNAME = NULL

               END
            ELSE 
               BEGIN
                  IF (@exceptionidentifier$2 IS NOT NULL)
                     BEGIN
                        IF @errornumber$2 = 59998
                           RAISERROR(59998, 16, 1, @exceptionidentifier$2)
                        ELSE 
                           RAISERROR(59999, 16, 1, @exceptionidentifier$2)
                     END
                  ELSE 
                     BEGIN
                        EXECUTE ssma_oracle.ssma_rethrowerror
                     END
               END

         END CATCH

      END

      IF (@PROCTYPE_IN = '1')
         SET @SEEMAIL = 'ed100003@edah.org.tw'

      SET @SMESSAGE = 
         CASE @PROCTYPE_IN
            WHEN /*被通知人(ㄧ級主管假卡劉協理審核完成) WHEN '1'*/'1' THEN 
               '僅通知您一級主管請假審核已完成-'
                + 
               ISNULL(@SDEPTNAME, '')
                + 
               ':'
                + 
               ISNULL(@EMPNO_IN, '')
                + 
               '('
                + 
               ISNULL(@SEMPNAME, '')
                + 
               ')申請'
                + 
               ISNULL(@PROCMSG_IN, '')
                + 
               '審核完成'
         END

      SET @STITLE = 
         CASE @PROCTYPE_IN
            WHEN '1' THEN '出勤通知-一級主管請假審核完成通知'
         END

      IF ssma_oracle.trim2_varchar(3, @SEEMAIL) IS NOT NULL AND ssma_oracle.trim2_varchar(3, @SEEMAIL) != ''
         EXECUTE HRP.EHRPHRAFUNC_PKG$POST_HTML_MAIL 
            @SENDER = 'system@edah.org.tw', 
            @RECIPIENT = @SEEMAIL, 
            @CC_RECIPIENT = 'ed101961@edah.org.tw', 
            @MAILTYPE = '2', 
            @SUBJECT = @STITLE, 
            @MESSAGE = @SMESSAGE

      SET @RTNCODE = 0

   END
GO
BEGIN TRY
    EXEC sp_addextendedproperty
        N'MS_SSMA_SOURCE', N'HRP.EHRPHRAFUNC_PKG.HRASEND_MAIL',
        N'SCHEMA', N'hrp',
        N'PROCEDURE', N'EHRPHRAFUNC_PKG$HRASEND_MAIL'
END TRY
BEGIN CATCH
    IF (@@TRANCOUNT > 0) ROLLBACK
    PRINT ERROR_MESSAGE()
END CATCH
GO
