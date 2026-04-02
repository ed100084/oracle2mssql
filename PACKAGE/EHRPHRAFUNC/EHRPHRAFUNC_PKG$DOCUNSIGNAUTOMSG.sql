
USE MIS
GO
 IF NOT EXISTS(SELECT * FROM sys.schemas WHERE [name] = N'hrp')      
     EXEC (N'CREATE SCHEMA hrp')                                   
 GO                                                               

USE MIS
GO
IF  EXISTS (SELECT * FROM sys.objects so JOIN sys.schemas sc ON so.schema_id = sc.schema_id WHERE so.name = N'EHRPHRAFUNC_PKG$DOCUNSIGNAUTOMSG'  AND sc.name=N'hrp'  AND type in (N'P',N'PC'))
 DROP PROCEDURE [hrp].[EHRPHRAFUNC_PKG$DOCUNSIGNAUTOMSG]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE HRP.EHRPHRAFUNC_PKG$DOCUNSIGNAUTOMSG  
AS 
   BEGIN

      EXECUTE ssma_oracle.db_check_init_package 'HRP', 'EHRPHRAFUNC_PKG'

      DECLARE
         @PMSG varchar(max), 
         @PEMPNO varchar(20), 
         @PCHNAME varchar(200), 
         @PCREATIONDATE varchar(10), 
         @PSTATUS varchar(20), 
         /*
         *   SSMA warning messages:
         *   O2SS0356: Conversion from NUMBER datatype can cause data loss.
         */

         @PCNT float(53), 
         @PORGBY varchar(10), 
         /*
         *   SSMA warning messages:
         *   O2SS0356: Conversion from NUMBER datatype can cause data loss.
         */

         @SSEQNO float(53), 
         @IMSG_NO varchar(20), 
         @PVACNO varchar(20), 
         @PVACNAME varchar(40), 
         @PVACDATE varchar(40)

      SET @PMSG = NULL

      DECLARE
          CURSOR1 CURSOR LOCAL FOR 
            SELECT 
               T1.EMP_NO, 
               
                  (
                     SELECT HRE_EMPBAS.CH_NAME
                     FROM HRP.HRE_EMPBAS
                     WHERE HRE_EMPBAS.EMP_NO = T1.EMP_NO
                  ) AS CHNAME, 
               ssma_oracle.to_char_date(ssma_oracle.trunc_date(T1.CREATION_DATE), 'yyyy-mm-dd'), 
               CASE 
                  WHEN ssma_oracle.trunc_date(T1.CREATION_DATE) = ssma_oracle.trunc_date(DATEADD(D, -3, sysdatetime())) THEN '代理人'
                  ELSE '代理人或主管'
               END AS MSGFOR, 
               count_big(T1.EMP_NO) AS CNT, 
               T1.ORG_BY
            FROM HRP.HRA_DEVCREC  AS T1
            WHERE 
               T1.DEPUTY_ALL = 'N' AND 
               T1.DIS_ALL = 'N' AND 
               ssma_oracle.trunc_date(T1.CREATION_DATE) = ssma_oracle.trunc_date(DATEADD(D, -3, sysdatetime())) OR (
               (T1.STATUS = 'U' OR T1.DEPUTY_ALL = 'N') AND 
               T1.DIS_ALL = 'N' AND 
               ssma_oracle.trunc_date(T1.CREATION_DATE) = ssma_oracle.trunc_date(DATEADD(D, -7, sysdatetime())))
            GROUP BY 
               T1.EMP_NO, 
               ssma_oracle.trunc_date(T1.CREATION_DATE), 
               T1.ORG_BY

      OPEN CURSOR1

      WHILE 1 = 1
      
         BEGIN

            FETCH CURSOR1
                INTO 
                  @PEMPNO, 
                  @PCHNAME, 
                  @PCREATIONDATE, 
                  @PSTATUS, 
                  @PCNT, 
                  @PORGBY

            /*
            *   SSMA warning messages:
            *   O2SS0113: The value of @@FETCH_STATUS might be changed by previous FETCH operations on other cursors, if the cursors are used simultaneously.
            */

            IF @@FETCH_STATUS <> 0
               BREAK

            SELECT @SSEQNO = HR_SEQCTL.SEQNO_NEXT
            FROM HRP.HR_SEQCTL
            WHERE HR_SEQCTL.SEQNO_TYPE = 'HRA'

            SET @IMSG_NO = 'HRA' + ISNULL(ssma_oracle.to_char_date(sysdatetime(), 'YYMM'), '') + ISNULL(CAST(@SSEQNO AS varchar(max)), '')

            SET @PMSG = 
               '提醒您於'
                + 
               ISNULL(@PCREATIONDATE, '')
                + 
               '申請之'
                + 
               ISNULL(CAST(@PCNT AS varchar(max)), '')
                + 
               '筆假卡，尚未通過'
                + 
               ISNULL(@PSTATUS, '')
                + 
               '簽核：<br><br><table border="1"><tr><th>假卡單號</th><th>假別</th><th>請假起訖</th></tr>'

            DECLARE
                CURSOR1DETAILS CURSOR LOCAL FOR 
                  SELECT T1.EVC_NO, 
                     (
                        SELECT HRA_DVCRLMST.VAC_NAME
                        FROM HRP.HRA_DVCRLMST
                        WHERE HRA_DVCRLMST.VAC_TYPE = T1.VAC_TYPE
                     ) AS VAC_NAME, 
                     ISNULL(ssma_oracle.to_char_date(T1.START_DATE, 'yyyy-mm-dd'), '')
                      + 
                     ' '
                      + 
                     ISNULL(T1.START_TIME, '')
                      + 
                     ' ~ '
                      + 
                     ISNULL(ssma_oracle.to_char_date(T1.END_DATE, 'yyyy-mm-dd'), '')
                      + 
                     ' '
                      + 
                     ISNULL(T1.END_TIME, '') AS VAC_DATE
                  FROM HRP.HRA_DEVCREC  AS T1
                  WHERE 
                     ((
                     T1.DEPUTY_ALL = 'N' AND 
                     T1.DIS_ALL = 'N' AND 
                     ssma_oracle.trunc_date(T1.CREATION_DATE) = ssma_oracle.trunc_date(DATEADD(D, -3, sysdatetime()))) OR (
                     (T1.STATUS = 'U' OR T1.DEPUTY_ALL = 'N') AND 
                     T1.DIS_ALL = 'N' AND 
                     ssma_oracle.trunc_date(T1.CREATION_DATE) = ssma_oracle.trunc_date(DATEADD(D, -7, sysdatetime())))) AND 
                     T1.EMP_NO = @PEMPNO AND 
                     ssma_oracle.to_char_date(T1.CREATION_DATE, 'yyyy-mm-dd') = @PCREATIONDATE

            OPEN CURSOR1DETAILS

            WHILE 1 = 1
            
               BEGIN

                  FETCH CURSOR1DETAILS
                      INTO @PVACNO, @PVACNAME, @PVACDATE

                  /*
                  *   SSMA warning messages:
                  *   O2SS0113: The value of @@FETCH_STATUS might be changed by previous FETCH operations on other cursors, if the cursors are used simultaneously.
                  */

                  IF @@FETCH_STATUS <> 0
                     BREAK

                  SET @PMSG = 
                     ISNULL(@PMSG, '')
                      + 
                     '<tr><td>'
                      + 
                     ISNULL(@PVACNO, '')
                      + 
                     '</td><td>'
                      + 
                     ISNULL(@PVACNAME, '')
                      + 
                     '</td><td>'
                      + 
                     ISNULL(@PVACDATE, '')
                      + 
                     '</td></tr>'

               END

            CLOSE CURSOR1DETAILS

            DEALLOCATE CURSOR1DETAILS

            SET @PMSG = ISNULL(@PMSG, '') + '</table>'

            INSERT HRP.PUS_MSGMST(
               MSG_NO, 
               MSG_FROM, 
               MSG_TO, 
               SUBJECT, 
               MSG_DESC, 
               MSG_DATE, 
               ORGAN_TYPE, 
               ORG_BY)
               VALUES (
                  @IMSG_NO, 
                  '人力資源室', 
                  ISNULL(@PEMPNO, '') + '(' + ISNULL(@PCHNAME, '') + ')', 
                  '假卡未簽通知', 
                  @PMSG, 
                  sysdatetime(), 
                  @PORGBY, 
                  @PORGBY)

            INSERT HRP.PUS_MSGBAS(MSG_NO, EMP_NO, ORGAN_TYPE, ORG_BY)
               VALUES (@IMSG_NO, @PEMPNO, @PORGBY, @PORGBY)

            UPDATE HRP.HR_SEQCTL
               SET 
                  SEQNO_NEXT = 
                     CASE 
                        WHEN HR_SEQCTL.SEQNO_NEXT + 1 > 100000 THEN 10000
                        ELSE HR_SEQCTL.SEQNO_NEXT + 1
                     END
            WHERE HR_SEQCTL.SEQNO_TYPE = 'HRA'

         END

      CLOSE CURSOR1

      DEALLOCATE CURSOR1

      IF @@TRANCOUNT > 0
         COMMIT TRANSACTION 

   END
GO
BEGIN TRY
    EXEC sp_addextendedproperty
        N'MS_SSMA_SOURCE', N'HRP.EHRPHRAFUNC_PKG.DOCUNSIGNAUTOMSG',
        N'SCHEMA', N'hrp',
        N'PROCEDURE', N'EHRPHRAFUNC_PKG$DOCUNSIGNAUTOMSG'
END TRY
BEGIN CATCH
    IF (@@TRANCOUNT > 0) ROLLBACK
    PRINT ERROR_MESSAGE()
END CATCH
GO
