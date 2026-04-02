
USE MIS
GO
 IF NOT EXISTS(SELECT * FROM sys.schemas WHERE [name] = N'hrp')      
     EXEC (N'CREATE SCHEMA hrp')                                   
 GO                                                               

USE MIS
GO
IF  EXISTS (SELECT * FROM sys.objects so JOIN sys.schemas sc ON so.schema_id = sc.schema_id WHERE so.name = N'EHRPHRAFUNC_PKG$POST_MISMSG_MAIL'  AND sc.name=N'hrp'  AND type in (N'P',N'PC'))
 DROP PROCEDURE [hrp].[EHRPHRAFUNC_PKG$POST_MISMSG_MAIL]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE HRP.EHRPHRAFUNC_PKG$POST_MISMSG_MAIL  
   @MSGNO varchar(max),
   @SENDER varchar(max),
   @RECIPIENT varchar(max),
   @SUBJECT varchar(max),
   @MESSAGE varchar(max),
   @MSGDATE varchar(max)
AS 
   BEGIN

      EXECUTE ssma_oracle.db_check_init_package 'HRP', 'EHRPHRAFUNC_PKG'

      DECLARE
         @REC_EMP$EMPPOS varchar(max), 
         @REC_EMP$ORGAN_TYPE varchar(max), 
         @REALMESSAGE varchar(max), 
         @EMAIL varchar(120)

      DECLARE
          CURSOR1 CURSOR LOCAL FOR 
            SELECT ISNULL(E.CH_NAME, '') + ISNULL(P.CH_NAME, '') AS EMPPOS, E.ORGAN_TYPE
            FROM HRP.HRE_EMPBAS  AS E, HRP.HRE_POSMST  AS P
            WHERE E.POS_NO = P.POS_NO AND E.EMP_NO = @RECIPIENT

      OPEN CURSOR1

      WHILE 1 = 1
      
         BEGIN

            FETCH CURSOR1
                INTO @REC_EMP$EMPPOS, @REC_EMP$ORGAN_TYPE

            /*
            *   SSMA warning messages:
            *   O2SS0113: The value of @@FETCH_STATUS might be changed by previous FETCH operations on other cursors, if the cursors are used simultaneously.
            */

            IF @@FETCH_STATUS <> 0
               BREAK

            SET @REALMESSAGE = ISNULL(@REC_EMP$EMPPOS, '') + ' 您好：<br><br>' + ISNULL(@MESSAGE, '')

            INSERT HRP.PUS_MSGMST(
               MSG_NO, 
               MSG_FROM, 
               MSG_TO, 
               SUBJECT, 
               MSG_DESC, 
               MSG_DATE, 
               ORG_BY, 
               ORGAN_TYPE)
               VALUES (
                  @MSGNO, 
                  @SENDER, 
                  @RECIPIENT, 
                  @SUBJECT, 
                  @REALMESSAGE, 
                  ssma_oracle.to_date2(@MSGDATE, 'yyyy-mm-dd'), 
                  @REC_EMP$ORGAN_TYPE, 
                  @REC_EMP$ORGAN_TYPE)

            INSERT HRP.PUS_MSGBAS(MSG_NO, EMP_NO, ORG_BY, ORGAN_TYPE)
               VALUES (@MSGNO, @RECIPIENT, @REC_EMP$ORGAN_TYPE, @REC_EMP$ORGAN_TYPE)

         END

      IF @@TRANCOUNT > 0
         COMMIT TRANSACTION 

      CLOSE CURSOR1

      DEALLOCATE CURSOR1

      
      /*
      *   IF substr(recipient,1,1) <> '1' THEN
      *         Email := recipient || '@edah.org.tw';
      *       ELSE
      *         Email := 'ed' || recipient || '@edah.org.tw';
      *       END IF;
      */
      SET @EMAIL = 'ed' + ISNULL(@RECIPIENT, '') + '@edah.org.tw'

      IF @RECIPIENT LIKE 'IBM%'
         SET @EMAIL = 'ed108482@edah.org.tw'

      /* 
      *   SSMA error messages:
      *   O2SS0083: Identifier hrpuser.MAILQUEUE.insertMailQueue cannot be converted because it was not resolved.

      EXECUTE HRPUSER.MAILQUEUE.INSERTMAILQUEUE
      */



   END
GO
BEGIN TRY
    EXEC sp_addextendedproperty
        N'MS_SSMA_SOURCE', N'HRP.EHRPHRAFUNC_PKG.POST_MISMSG_MAIL',
        N'SCHEMA', N'hrp',
        N'PROCEDURE', N'EHRPHRAFUNC_PKG$POST_MISMSG_MAIL'
END TRY
BEGIN CATCH
    IF (@@TRANCOUNT > 0) ROLLBACK
    PRINT ERROR_MESSAGE()
END CATCH
GO
