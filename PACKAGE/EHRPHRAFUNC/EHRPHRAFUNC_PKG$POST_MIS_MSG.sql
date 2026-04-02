
USE MIS
GO
 IF NOT EXISTS(SELECT * FROM sys.schemas WHERE [name] = N'hrp')      
     EXEC (N'CREATE SCHEMA hrp')                                   
 GO                                                               

USE MIS
GO
IF  EXISTS (SELECT * FROM sys.objects so JOIN sys.schemas sc ON so.schema_id = sc.schema_id WHERE so.name = N'EHRPHRAFUNC_PKG$POST_MIS_MSG'  AND sc.name=N'hrp'  AND type in (N'P',N'PC'))
 DROP PROCEDURE [hrp].[EHRPHRAFUNC_PKG$POST_MIS_MSG]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE HRP.EHRPHRAFUNC_PKG$POST_MIS_MSG  
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
         @ORGANTYPE varchar(10)

      BEGIN

         BEGIN TRY
            SELECT @ORGANTYPE = HRE_EMPBAS.ORGAN_TYPE
            FROM HRP.HRE_EMPBAS
            WHERE HRE_EMPBAS.EMP_NO = @RECIPIENT
         END TRY

         BEGIN CATCH
            BEGIN
               SET @ORGANTYPE = 'ED'
            END
         END CATCH

      END

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
            @MESSAGE, 
            ssma_oracle.to_date2(@MSGDATE, 'yyyy-mm-dd'), 
            @ORGANTYPE, 
            @ORGANTYPE)

      INSERT HRP.PUS_MSGBAS(MSG_NO, EMP_NO, ORG_BY, ORGAN_TYPE)
         VALUES (@MSGNO, @RECIPIENT, @ORGANTYPE, @ORGANTYPE)

      IF @@TRANCOUNT > 0
         COMMIT TRANSACTION 

   END
GO
BEGIN TRY
    EXEC sp_addextendedproperty
        N'MS_SSMA_SOURCE', N'HRP.EHRPHRAFUNC_PKG.POST_MIS_MSG',
        N'SCHEMA', N'hrp',
        N'PROCEDURE', N'EHRPHRAFUNC_PKG$POST_MIS_MSG'
END TRY
BEGIN CATCH
    IF (@@TRANCOUNT > 0) ROLLBACK
    PRINT ERROR_MESSAGE()
END CATCH
GO
