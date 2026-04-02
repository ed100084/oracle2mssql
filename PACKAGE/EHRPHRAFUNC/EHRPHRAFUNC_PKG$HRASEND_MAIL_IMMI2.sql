
USE MIS
GO
 IF NOT EXISTS(SELECT * FROM sys.schemas WHERE [name] = N'hrp')      
     EXEC (N'CREATE SCHEMA hrp')                                   
 GO                                                               

USE MIS
GO
IF  EXISTS (SELECT * FROM sys.objects so JOIN sys.schemas sc ON so.schema_id = sc.schema_id WHERE so.name = N'EHRPHRAFUNC_PKG$HRASEND_MAIL_IMMI2'  AND sc.name=N'hrp'  AND type in (N'P',N'PC'))
 DROP PROCEDURE [hrp].[EHRPHRAFUNC_PKG$HRASEND_MAIL_IMMI2]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE HRP.EHRPHRAFUNC_PKG$HRASEND_MAIL_IMMI2  
AS 
   BEGIN

      EXECUTE ssma_oracle.db_check_init_package 'HRP', 'EHRPHRAFUNC_PKG'

      DECLARE
         @PEVCNO varchar(20), 
         @PEMPNO varchar(20), 
         @PCHNAME varchar(200), 
         @PEMAIL varchar(60), 
         @PSTARTDATE varchar(20), 
         @IMSG_NO varchar(20), 
         @SSEQNO varchar(20)

      DECLARE
          CURSOR1 CURSOR LOCAL FOR 
            SELECT T1.EMP_NO, T2.CH_NAME, 
               CASE 
                  WHEN substring(T2.EMP_NO, 1, 1) NOT IN ( 'S', 'P', 'R' ) THEN 'ed' + ISNULL(T2.EMP_NO, '') + '@edah.org.tw'
                  ELSE 'ed' + ISNULL(T2.EMP_NO, '') + '@edah.org.tw'
               END AS E_MAIL, ssma_oracle.to_char_date(T1.START_DATE, 'yyyy-mm-dd') AS START_DATE
            FROM HRP.HRA_EVCREC  AS T1, HRP.HRE_EMPBAS  AS T2
            WHERE 
               T1.EMP_NO = T2.EMP_NO AND 
               T1.STATUS IN ( 'Y', 'U' ) AND 
               (T1.EVC_REA = '0010' OR T1.ABROAD = 'Y') AND 
               CONVERT(varchar(6), T1.END_DATE, 112) >= '200906' AND 
               CAST(ssma_oracle.trunc_date(sysdatetime()) - ssma_oracle.trunc_date(T1.END_DATE) AS float(53)) = 3 AND 
               T1.EVC_NO NOT IN 
               (
                  SELECT T1$2.EVC_NO
                  FROM HRP.HRA_EVCREC  AS T1$2, HRP.HRA_IMMIDTL  AS T2$2, HRP.HRA_IMMIMST  AS T3
                  WHERE 
                     T2$2.EVC_NO = T3.EVC_NO AND 
                     (CONVERT(varchar(max), T1$2.START_DATE, 112) BETWEEN CONVERT(varchar(max), T2$2.OUTDATE, 112) AND CONVERT(varchar(max), T2$2.INDATE, 112) OR CONVERT(varchar(max), T1$2.END_DATE, 112) BETWEEN CONVERT(varchar(max), T2$2.OUTDATE, 112) AND CONVERT(varchar(max), T2$2.INDATE, 112)) AND 
                     T1$2.EMP_NO = T3.EMP_NO AND 
                     CONVERT(varchar(6), T1$2.END_DATE, 112) >= '200906' AND 
                     (T1$2.EVC_REA = '0010' OR T1$2.ABROAD = 'Y')
               )
             UNION ALL
            SELECT T1.EMP_NO, T2.CH_NAME, 
               CASE 
                  WHEN substring(T2.EMP_NO, 1, 1) NOT IN ( 'S', 'P', 'R' ) THEN 'ed' + ISNULL(T2.EMP_NO, '') + '@edah.org.tw'
                  ELSE 'ed' + ISNULL(T2.EMP_NO, '') + '@edah.org.tw'
               END AS E_MAIL, ssma_oracle.to_char_date(T1.START_DATE, 'yyyy-mm-dd') AS START_DATE
            FROM HRP.HRA_OFFREC  AS T1, HRP.HRE_EMPBAS  AS T2
            WHERE 
               T1.EMP_NO = T2.EMP_NO AND 
               T1.STATUS IN ( 'Y', 'U' ) AND 
               T1.ABROAD = 'Y' AND 
               CONVERT(varchar(6), T1.END_DATE, 112) >= '200906' AND 
               T1.ITEM_TYPE = 'O' AND 
               CAST(ssma_oracle.trunc_date(sysdatetime()) - ssma_oracle.trunc_date(T1.END_DATE) AS float(53)) = 3 AND 
               
               NOT EXISTS 
                  (
                     SELECT *
                     FROM 
                        (
                           SELECT T1$2.EMP_NO, T1$2.START_DATE, T1$2.START_TIME
                           FROM HRP.HRA_OFFREC  AS T1$2, HRP.HRA_IMMIDTL  AS T2$2, HRP.HRA_IMMIMST  AS T3
                           WHERE 
                              T2$2.EVC_NO = T3.EVC_NO AND 
                              (CONVERT(varchar(max), T1$2.START_DATE, 112) BETWEEN CONVERT(varchar(max), T2$2.OUTDATE, 112) AND CONVERT(varchar(max), T2$2.INDATE, 112) OR CONVERT(varchar(max), T1$2.END_DATE, 112) BETWEEN CONVERT(varchar(max), T2$2.OUTDATE, 112) AND CONVERT(varchar(max), T2$2.INDATE, 112)) AND 
                              T1$2.EMP_NO = T3.EMP_NO AND 
                              CONVERT(varchar(6), T1$2.END_DATE, 112) >= '200906' AND 
                              T1$2.ITEM_TYPE = 'O' AND 
                              T1$2.ABROAD = 'Y'
                        )  AS il(ilc, ilc$2, ilc$3)
                     WHERE 
                        (il.ilc = ( T1.EMP_NO ) OR il.ilc IS NULL OR ( T1.EMP_NO ) IS NULL) AND 
                        (il.ilc$2 = ( T1.START_DATE ) OR il.ilc$2 IS NULL OR ( T1.START_DATE ) IS NULL) AND 
                        (il.ilc$3 = ( T1.START_TIME ) OR il.ilc$3 IS NULL OR ( T1.START_TIME ) IS NULL)
                  )
             UNION ALL
            SELECT T1.EMP_NO, T2.CH_NAME, 
               CASE 
                  WHEN substring(T2.EMP_NO, 1, 1) NOT IN ( 'S', 'P', 'R' ) THEN 'ed' + ISNULL(T2.EMP_NO, '') + '@edah.org.tw'
                  ELSE 'ed' + ISNULL(T2.EMP_NO, '') + '@edah.org.tw'
               END AS E_MAIL, ssma_oracle.to_char_date(T1.START_DATE, 'yyyy-mm-dd') AS START_DATE
            FROM HRP.HRA_SUPMST  AS T1, HRP.HRE_EMPBAS  AS T2
            WHERE 
               T1.EMP_NO = T2.EMP_NO AND 
               T1.STATUS IN ( 'Y', 'U' ) AND 
               T1.ABROAD = 'Y' AND 
               CONVERT(varchar(6), T1.END_DATE, 112) >= '200906' AND 
               CAST(ssma_oracle.trunc_date(sysdatetime()) - ssma_oracle.trunc_date(T1.END_DATE) AS float(53)) = 3 AND 
               
               NOT EXISTS 
                  (
                     SELECT *
                     FROM 
                        (
                           SELECT T1$2.EMP_NO, T1$2.START_DATE, T1$2.START_TIME
                           FROM HRP.HRA_SUPMST  AS T1$2, HRP.HRA_IMMIDTL  AS T2$2, HRP.HRA_IMMIMST  AS T3
                           WHERE 
                              T2$2.EVC_NO = T3.EVC_NO AND 
                              (CONVERT(varchar(max), T1$2.START_DATE, 112) BETWEEN CONVERT(varchar(max), T2$2.OUTDATE, 112) AND CONVERT(varchar(max), T2$2.INDATE, 112) OR CONVERT(varchar(max), T1$2.END_DATE, 112) BETWEEN CONVERT(varchar(max), T2$2.OUTDATE, 112) AND CONVERT(varchar(max), T2$2.INDATE, 112)) AND 
                              T1$2.EMP_NO = T3.EMP_NO AND 
                              CONVERT(varchar(6), T1$2.END_DATE, 112) >= '200906' AND 
                              T1$2.ABROAD = 'Y'
                        )  AS il(ilc, ilc$2, ilc$3)
                     WHERE 
                        (il.ilc = ( T1.EMP_NO ) OR il.ilc IS NULL OR ( T1.EMP_NO ) IS NULL) AND 
                        (il.ilc$2 = ( T1.START_DATE ) OR il.ilc$2 IS NULL OR ( T1.START_DATE ) IS NULL) AND 
                        (il.ilc$3 = ( T1.START_TIME ) OR il.ilc$3 IS NULL OR ( T1.START_TIME ) IS NULL)
                  )
             UNION ALL
            SELECT T1.EMP_NO, T2.CH_NAME, 
               CASE 
                  WHEN substring(T2.EMP_NO, 1, 1) NOT IN ( 'S', 'P', 'R' ) THEN 'ed' + ISNULL(T2.EMP_NO, '') + '@edah.org.tw'
                  ELSE 'ed' + ISNULL(T2.EMP_NO, '') + '@edah.org.tw'
               END AS E_MAIL, ssma_oracle.to_char_date(T1.START_DATE, 'yyyy-mm-dd') AS START_DATE
            FROM HRP.HRA_DEVCREC  AS T1, HRP.HRE_EMPBAS  AS T2
            WHERE 
               T1.EMP_NO = T2.EMP_NO AND 
               T1.STATUS IN ( 'Y', 'U' ) AND 
               (T1.EVC_REA = '0010' OR T1.ABROAD = 'Y') AND 
               CONVERT(varchar(6), T1.END_DATE, 112) >= '200906' AND 
               CAST(ssma_oracle.trunc_date(sysdatetime()) - ssma_oracle.trunc_date(T1.END_DATE) AS float(53)) = 3 AND 
               T1.DIS_ALL <> 'Y'/*20200604 108482 醫師假卡全部銷假不列入*/ AND 
               T1.EVC_NO NOT IN 
               (
                  SELECT T1$2.EVC_NO
                  FROM HRP.HRA_DEVCREC  AS T1$2, HRP.HRA_IMMIDTL  AS T2$2, HRP.HRA_IMMIMST  AS T3
                  WHERE 
                     T2$2.EVC_NO = T3.EVC_NO AND 
                     (CONVERT(varchar(max), T1$2.START_DATE, 112) BETWEEN CONVERT(varchar(max), T2$2.OUTDATE, 112) AND CONVERT(varchar(max), T2$2.INDATE, 112) OR CONVERT(varchar(max), T1$2.END_DATE, 112) BETWEEN CONVERT(varchar(max), T2$2.OUTDATE, 112) AND CONVERT(varchar(max), T2$2.INDATE, 112)) AND 
                     T1$2.EMP_NO = T3.EMP_NO AND 
                     CONVERT(varchar(6), T1$2.END_DATE, 112) >= '200906' AND 
                     (T1$2.EVC_REA = '0010' OR T1$2.ABROAD = 'Y')
               )

      OPEN CURSOR1

      WHILE 1 = 1
      
         BEGIN

            FETCH CURSOR1
                INTO @PEMPNO, @PCHNAME, @PEMAIL, @PSTARTDATE

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

            INSERT HRP.PUS_MSGMST(
               MSG_NO, 
               MSG_FROM, 
               MSG_TO, 
               SUBJECT, 
               MSG_DESC, 
               MSG_DATE)
               VALUES (
                  @IMSG_NO, 
                  '感控', 
                  ISNULL(@PCHNAME, '') + '(' + ISNULL(@PEMPNO, '') + ')', 
                  '出入境管理-請假出國未填管理資料通知', 
                  '您有填寫假卡(請假起日' + ISNULL(@PSTARTDATE, '') + ')出國,但未填寫出入境管理相關資料,請至MIS 公用服務系統->公用出勤程式->出入境管理 中填寫相關資料', 
                  sysdatetime())

            INSERT HRP.PUS_MSGBAS(MSG_NO, EMP_NO)
               VALUES (@IMSG_NO, @PEMPNO)

            IF @PEMAIL IS NOT NULL AND @PEMAIL != ''
               BEGIN

                  DECLARE
                     @temp varchar(8000)

                  SET @temp = '您有填寫假卡(請假起日' + ISNULL(@PSTARTDATE, '') + ')出國,但未填寫出入境管理相關資料,請至MIS 公用服務系統->公用出勤程式->出入境管理 中填寫相關資料'

                  EXECUTE HRP.EHRPHRAFUNC_PKG$POST_HTML_MAIL 
                     @SENDER = 'system@edah.org.tw', 
                     @RECIPIENT = @PEMAIL, 
                     @CC_RECIPIENT = 'ed108482@edah.org.tw', 
                     @MAILTYPE = '1', 
                     @SUBJECT = '出入境管理-請假出國未填管理資料通知', 
                     @MESSAGE = @temp

               END

            UPDATE HRP.HR_SEQCTL
               SET 
                  SEQNO_NEXT = 
                     CASE 
                        WHEN HR_SEQCTL.SEQNO_NEXT + 1 > 100000 THEN 10000
                        ELSE HR_SEQCTL.SEQNO_NEXT + 1
                     END
            WHERE HR_SEQCTL.SEQNO_TYPE = 'HRA'

         END

      IF @@TRANCOUNT > 0
         COMMIT TRANSACTION 

      EXECUTE HRP.EHRPHRAFUNC_PKG$DOCUNSIGNAUTOMSG 

   END
GO
BEGIN TRY
    EXEC sp_addextendedproperty
        N'MS_SSMA_SOURCE', N'HRP.EHRPHRAFUNC_PKG.HRASEND_MAIL_IMMI2',
        N'SCHEMA', N'hrp',
        N'PROCEDURE', N'EHRPHRAFUNC_PKG$HRASEND_MAIL_IMMI2'
END TRY
BEGIN CATCH
    IF (@@TRANCOUNT > 0) ROLLBACK
    PRINT ERROR_MESSAGE()
END CATCH
GO
