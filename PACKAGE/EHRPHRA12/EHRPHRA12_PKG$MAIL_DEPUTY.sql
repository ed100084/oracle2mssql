
USE MIS
GO
 IF NOT EXISTS(SELECT * FROM sys.schemas WHERE [name] = N'hrp')      
     EXEC (N'CREATE SCHEMA hrp')                                   
 GO                                                               

USE MIS
GO
IF  EXISTS (SELECT * FROM sys.objects so JOIN sys.schemas sc ON so.schema_id = sc.schema_id WHERE so.name = N'EHRPHRA12_PKG$MAIL_DEPUTY'  AND sc.name=N'hrp'  AND type in (N'P',N'PC'))
 DROP PROCEDURE [hrp].[EHRPHRA12_PKG$MAIL_DEPUTY]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE HRP.EHRPHRA12_PKG$MAIL_DEPUTY  
   @P_D_EMP_NO varchar(max)/*代理人*/,
   @P_START_DATE varchar(max),
   @P_END_DATE varchar(max),
   @P_P_EMP_NO varchar(max)/*審核者*/,
   @P_EMP_NO varchar(max)/*申請者*/,
   @P_ORGANTYPE_IN varchar(max)
AS 
   BEGIN

      EXECUTE ssma_oracle.db_check_init_package 'HRP', 'EHRPHRA12_PKG'

      DECLARE
         @S_EMPNAME varchar(200), 
         @S_POSNAME varchar(100), 
         @S_D_EMPNAME varchar(200), 
         @S_D_POSNAME varchar(100), 
         @S_P_EMPNAME varchar(20), 
         @S_D_EMAIL varchar(120), 
         @S_P_EMAIL varchar(120), 
         @ICNT int, 
         @MESSAGE varchar(max), 
         @IPADDRESS varchar(16), 
         @SORGANTYPE varchar(10)

      SET @SORGANTYPE = @P_ORGANTYPE_IN

      SET @ICNT = 0

      /* 
      *   SSMA error messages:
      *   O2SS0560: Identifier utl_inaddr.get_host_address cannot be converted because it was not resolved.
      *   This may happen because system package that defines the identifier was excluded from loading in Project Settings.

      SELECT @IPADDRESS = UTL_INADDR.GET_HOST_ADDRESS
      */



      SELECT @S_EMPNAME = HRE_EMPBAS.CH_NAME, @S_POSNAME = 
         (
            SELECT HRE_POSMST.CH_NAME
            FROM HRP.HRE_POSMST
            WHERE HRE_POSMST.POS_NO = HRE_EMPBAS.POS_NO
         )
      FROM HRP.HRE_EMPBAS
      WHERE HRE_EMPBAS.EMP_NO = @P_EMP_NO

      /*and organ_type = sOrganType;*/
      BEGIN

         BEGIN TRY
            SELECT @S_D_EMPNAME = HRE_EMPBAS.CH_NAME, @S_D_EMAIL = /*(CASE WHEN substr(Emp_No,1,1) IN ('P', 'R', 'S') THEN Emp_No||'@edah.org.tw' ELSE 'ed'||Emp_No||'@edah.org.tw' END) EMail,*/'ed' + ISNULL(HRE_EMPBAS.EMP_NO, '') + '@edah.org.tw', @S_D_POSNAME = 
               (
                  SELECT HRE_POSMST.CH_NAME
                  FROM HRP.HRE_POSMST
                  WHERE HRE_POSMST.POS_NO = HRE_EMPBAS.POS_NO
               )
            FROM HRP.HRE_EMPBAS
            WHERE HRE_EMPBAS.EMP_NO = @P_D_EMP_NO AND HRE_EMPBAS.DISABLED = 'N'
         END TRY

         /*and organ_type = sOrganType;*/
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
               SET @ICNT = 1
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

      IF @ICNT = 0
         IF @S_D_EMAIL IS NULL OR @S_D_EMAIL = '' OR @S_D_EMAIL = NULL
            DECLARE
               @db_null_statement int
         ELSE 
            BEGIN

               SET @MESSAGE = 
                  ISNULL(@S_D_EMPNAME, '')
                   + 
                  ISNULL(@S_D_POSNAME, '')
                   + 
                  ' 您好 :<br><br> '
                   + 
                  ISNULL(@S_EMPNAME, '')
                   + 
                  ISNULL(@S_POSNAME, '')
                   + 
                  '('
                   + 
                  ISNULL(@P_EMP_NO, '')
                   + 
                  ') 於 '
                   + 
                  ISNULL(@P_START_DATE, '')
                   + 
                  ' 至 '
                   + 
                  ISNULL(@P_END_DATE, '')
                   + 
                  ' 請假'
                   + 
                  ' <br>謹此通知您是他(她)的指定代理人 <br><br> 感謝您的參與配合!<br><br>人事課敬啟 '
                   + 
                  ISNULL(ssma_oracle.to_char_date(sysdatetime(), 'YYYY-MM-DD HH24:MI'), '')
                   + 
                  '<br><br> '
                   + 
                  ISNULL(@IPADDRESS, '')

               /* 
               *   SSMA error messages:
               *   O2SS0083: Identifier hrpuser.MAILQUEUE.insertMailQueue cannot be converted because it was not resolved.

               /* ehrphrafunc_pkg.POST_HTML_MAIL('edhr@edah.org.tw',s_D_EMail,'ed108978@edah.org.tw','1','請假代理人通知',Message);*/
               EXECUTE HRPUSER.MAILQUEUE.INSERTMAILQUEUE
               */



            END

   END
GO
BEGIN TRY
    EXEC sp_addextendedproperty
        N'MS_SSMA_SOURCE', N'HRP.EHRPHRA12_PKG.mail_deputy',
        N'SCHEMA', N'hrp',
        N'PROCEDURE', N'EHRPHRA12_PKG$MAIL_DEPUTY'
END TRY
BEGIN CATCH
    IF (@@TRANCOUNT > 0) ROLLBACK
    PRINT ERROR_MESSAGE()
END CATCH
GO
