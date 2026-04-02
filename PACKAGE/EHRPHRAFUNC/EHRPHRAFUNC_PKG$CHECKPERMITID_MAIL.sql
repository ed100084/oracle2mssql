
USE MIS
GO
 IF NOT EXISTS(SELECT * FROM sys.schemas WHERE [name] = N'hrp')      
     EXEC (N'CREATE SCHEMA hrp')                                   
 GO                                                               

USE MIS
GO
IF  EXISTS (SELECT * FROM sys.objects so JOIN sys.schemas sc ON so.schema_id = sc.schema_id WHERE so.name = N'EHRPHRAFUNC_PKG$CHECKPERMITID_MAIL'  AND sc.name=N'hrp'  AND type in (N'P',N'PC'))
 DROP PROCEDURE [hrp].[EHRPHRAFUNC_PKG$CHECKPERMITID_MAIL]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE HRP.EHRPHRAFUNC_PKG$CHECKPERMITID_MAIL  
AS 
   BEGIN

      EXECUTE ssma_oracle.db_check_init_package 'HRP', 'EHRPHRAFUNC_PKG'

      DECLARE
         @PEMPNO varchar(20), 
         @PDATE varchar(20), 
         @PPERMITID varchar(20), 
         @STITLE varchar(100), 
         @SEEMAIL varchar(120), 
         @SMESSAGE varchar(max)

      SET @SMESSAGE = NULL

      SET @SEEMAIL = NULL

      SET @STITLE = '確認加班單審核者'

      DECLARE
          CURSOR1 CURSOR LOCAL FOR 
            SELECT HRA_OFFREC.EMP_NO, ssma_oracle.to_char_date(HRA_OFFREC.START_DATE, 'yyyy-mm-dd') AS START_DATE, HRA_OFFREC.PERMIT_ID
            FROM HRP.HRA_OFFREC
            WHERE 
               HRA_OFFREC.PERMIT_ID = '100005' AND 
               HRA_OFFREC.STATUS NOT IN ( 'Y', 'N' ) AND 
               HRA_OFFREC.EMP_NO <> '100102'
             UNION
            SELECT HRA_OTMSIGN.EMP_NO, ssma_oracle.to_char_date(HRA_OTMSIGN.START_DATE, 'yyyy-mm-dd') AS START_DATE, HRA_OTMSIGN.PERMIT_ID
            FROM HRP.HRA_OTMSIGN
            WHERE 
               HRA_OTMSIGN.PERMIT_ID = '100005' AND 
               HRA_OTMSIGN.STATUS NOT IN ( 'Y', 'N' ) AND 
               HRA_OTMSIGN.OTM_FLAG = 'B' AND 
               HRA_OTMSIGN.EMP_NO <> '100102'

      OPEN CURSOR1

      WHILE 1 = 1
      
         BEGIN

            FETCH CURSOR1
                INTO @PEMPNO, @PDATE, @PPERMITID

            /*
            *   SSMA warning messages:
            *   O2SS0113: The value of @@FETCH_STATUS might be changed by previous FETCH operations on other cursors, if the cursors are used simultaneously.
            */

            IF @@FETCH_STATUS <> 0
               BREAK

            IF @SMESSAGE IS NULL OR @SMESSAGE = ''
               SET @SMESSAGE = 
                  '<table border="1"><tr><td>工號</td><td>日期</td><td>審核者</td></tr>'
                   + 
                  '<tr><td>'
                   + 
                  ISNULL(@PEMPNO, '')
                   + 
                  '</td><td>'
                   + 
                  ISNULL(@PDATE, '')
                   + 
                  '</td><td>'
                   + 
                  ISNULL(@PPERMITID, '')
                   + 
                  '</td></tr>'
            ELSE 
               SET @SMESSAGE = 
                  ISNULL(@SMESSAGE, '')
                   + 
                  '<tr><td>'
                   + 
                  ISNULL(@PEMPNO, '')
                   + 
                  '</td><td>'
                   + 
                  ISNULL(@PDATE, '')
                   + 
                  '</td><td>'
                   + 
                  ISNULL(@PPERMITID, '')
                   + 
                  '</td></tr>'

         END

      CLOSE CURSOR1

      DEALLOCATE CURSOR1

      IF (@SMESSAGE IS NOT NULL AND @SMESSAGE != '')
         BEGIN

            SET @SMESSAGE = ISNULL(@SMESSAGE, '') + '</table>'

            DECLARE
                CURSOR2 CURSOR LOCAL FOR 
                  /*收件人*/
                  SELECT 'ed108154@edah.org.tw'/*李采柔*/
                   UNION ALL
                  SELECT 'ed108482@edah.org.tw'/*葉鈴雅*/
                   UNION ALL
                  SELECT 'ed100037@edah.org.tw'/*鄭淑宏*/

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
                     @CC_RECIPIENT = NULL, 
                     @MAILTYPE = '1', 
                     @SUBJECT = @STITLE, 
                     @MESSAGE = @SMESSAGE

               END

            CLOSE CURSOR2

            DEALLOCATE CURSOR2

         END

   END
GO
BEGIN TRY
    EXEC sp_addextendedproperty
        N'MS_SSMA_SOURCE', N'HRP.EHRPHRAFUNC_PKG.CHECKPERMITID_MAIL',
        N'SCHEMA', N'hrp',
        N'PROCEDURE', N'EHRPHRAFUNC_PKG$CHECKPERMITID_MAIL'
END TRY
BEGIN CATCH
    IF (@@TRANCOUNT > 0) ROLLBACK
    PRINT ERROR_MESSAGE()
END CATCH
GO
