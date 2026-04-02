
USE MIS
GO
 IF NOT EXISTS(SELECT * FROM sys.schemas WHERE [name] = N'hrp')      
     EXEC (N'CREATE SCHEMA hrp')                                   
 GO                                                               

USE MIS
GO
IF  EXISTS (SELECT * FROM sys.objects so JOIN sys.schemas sc ON so.schema_id = sc.schema_id WHERE so.name = N'EHRPHRAFUNC_PKG$HRASEND_MAIL_ABROAD'  AND sc.name=N'hrp'  AND type in (N'P',N'PC'))
 DROP PROCEDURE [hrp].[EHRPHRAFUNC_PKG$HRASEND_MAIL_ABROAD]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE HRP.EHRPHRAFUNC_PKG$HRASEND_MAIL_ABROAD  
AS 
   BEGIN

      DECLARE
         @PEMPNO varchar(20), 
         @PCHNAME varchar(200), 
         @PDEPTNAME varchar(60), 
         @PPOSNAME varchar(60), 
         @PVACNAME varchar(60), 
         @PSTATUSNAME varchar(10), 
         @PSD varchar(10), 
         @PST varchar(4), 
         @PED varchar(10), 
         @PET varchar(4), 
         @PEVCREA varchar(200), 
         @PVACDAYS numeric(3), 
         @PVACHRS numeric(4, 1), 
         @PRM varchar(300), 
         @PEVCDAY varchar(100), 
         @PLASTVACDAY varchar(100)/*20190130 108978 增加遞延天數顯示*/, 
         @PEVC_U varchar(100), 
         @PEVC_F varchar(100), 
         @PEVC_S varchar(100), 
         @PABROAD varchar(10)/*20200214 108154 增加出國註記*/, 
         @PORGANTYPE varchar(100), 
         @PPOSLEVEL numeric(3), 
         @STITLE varchar(100), 
         @STITLE2 varchar(100), 
         @SEEMAIL varchar(120), 
         @SMESSAGE varchar(max), 
         @SMESSAGE2 varchar(max)/*一般人員第二封*/, 
         @SMESSAGEDOC varchar(max), 
         @SMESSAGEMAIL varchar(max), 
         @NCONTI numeric(1), 
         @PCONTIEVCNO varchar(20), 
         @PSD2 varchar(10), 
         @NCONTI2 numeric(1), 
         /*
         *   SSMA warning messages:
         *   O2SS0356: Conversion from NUMBER datatype can cause data loss.
         */

         @ERRORCODE float(53)/*20220715 108482 記錄異常代碼*/, 
         @ERRORMESSAGE varchar(500)/*20220715 108482 記錄異常訊息*/

      BEGIN TRY

         EXECUTE ssma_oracle.db_check_init_package 'HRP', 'EHRPHRAFUNC_PKG'

         SET @SMESSAGE = '<table border="1" width="100%">'

         SET @SMESSAGE = ISNULL(@SMESSAGE, '') + '<tr><td colspan="17" ><BR>' + '==========(一般人員出國假單)==========' + '<BR><BR></tr></tr>'

         SET @SMESSAGE = ISNULL(@SMESSAGE, '') + '<TR><TD>機構</td><TD>工號</td><TD>姓名</td><TD>部門名稱</td><TD>職稱</td><TD>職等</td><TD>假別</td>'

         SET @SMESSAGE = ISNULL(@SMESSAGE, '') + '<TD>狀態</td><TD>開始日期</td><TD>開始時間</td><TD>結束日期</td><TD>結束時間</td>'

         SET @SMESSAGE = ISNULL(@SMESSAGE, '') + '<TD>天數</td><TD>時數</td><TD>請假理由</td><TD>其他原因</td><TD>出國</td>'

         /* 
         *   SSMA error messages:
         *   O2SS0083: Identifier ta.st cannot be converted because it was not resolved.
         *   O2SS0083: Identifier ta.ed cannot be converted because it was not resolved.
         *   O2SS0083: Identifier ta.et cannot be converted because it was not resolved.
         *   O2SS0083: Identifier ta.remark cannot be converted because it was not resolved.

         DECLARE
             CURSOR1 CURSOR LOCAL FOR 
               /*一般人員*/
               SELECT 
                  TA.EMP_NO, 
                  TB.CH_NAME, 
                  
                     (
                        SELECT HRE_ORGBAS.CH_NAME
                        FROM HRP.HRE_ORGBAS
                        WHERE HRE_ORGBAS.DEPT_NO = TA.DEPT_NO AND HRE_ORGBAS.ORGAN_TYPE = TA.ORG_BY
                     ) AS DEPTNAME, 
                  
                     (
                        SELECT HRE_POSMST.CH_NAME
                        FROM HRP.HRE_POSMST
                        WHERE HRE_POSMST.POS_NO = TB.POS_NO
                     ) AS POSNAME, 
                  CASE TA.VAC_TYPE
                     WHEN 'O1' THEN '借休'
                     WHEN 'B0' THEN '補休'
                     WHEN 'B1' THEN '補休'
                     ELSE 
                        (
                           SELECT HRA_VCRLMST.VAC_NAME
                           FROM HRP.HRA_VCRLMST
                           WHERE HRA_VCRLMST.VAC_TYPE = TA.VAC_TYPE
                        )
                  END AS VACNAME, 
                  CASE TA.STATUS
                     WHEN 'Y' THEN '准'
                     WHEN 'U' THEN '申請'
                     ELSE NULL
                  END AS STATUSNAME, 
                  TA.SD, 
                  TA.ST, 
                  TA.ED, 
                  TA.ET, 
                  CASE TA.VAC_TYPE
                     WHEN 'B0' THEN 
                        (
                           /* 
                           *   SSMA error messages:
                           *   O2SS0083: Identifier ta.evc_rea cannot be converted because it was not resolved.

                           SELECT HR_CODEDTL.CODE_NAME
                           FROM HRP.HR_CODEDTL
                           WHERE HR_CODEDTL.CODE_TYPE = 'HRA22' AND HR_CODEDTL.CODE_NO = TA.EVC_REA
                           */


                        )
                     WHEN '01' THEN 
                        (
                           /* 
                           *   SSMA error messages:
                           *   O2SS0083: Identifier ta.evc_rea cannot be converted because it was not resolved.

                           SELECT HR_CODEDTL$2.CODE_NAME
                           FROM HRP.HR_CODEDTL  AS HR_CODEDTL$2
                           WHERE HR_CODEDTL$2.CODE_TYPE = 'HRA51' AND HR_CODEDTL$2.CODE_NO = TA.EVC_REA
                           */


                        )
                     ELSE 
                        (
                           /* 
                           *   SSMA error messages:
                           *   O2SS0083: Identifier ta.evc_rea cannot be converted because it was not resolved.

                           SELECT HR_CODEDTL$3.CODE_NAME
                           FROM HRP.HR_CODEDTL  AS HR_CODEDTL$3
                           WHERE HR_CODEDTL$3.CODE_TYPE = 'HRA08' AND HR_CODEDTL$3.CODE_NO = TA.EVC_REA
                           */


                        )
                  END AS EVCREA, 
                  TA.VAC_DAYS, 
                  TA.VAC_HRS, 
                  TA.REMARK, 
                  TC.VAC_DAY, 
                  TC.LAST_VAC_DAY, 
                  
                     (
                        SELECT CAST(isnull(floor(sum(HRA_EVCREC.VAC_DAYS * 8 + HRA_EVCREC.VAC_HRS) / 8), '0') AS nvarchar(max)) + '天' + CAST(isnull(((sum(HRA_EVCREC.VAC_DAYS * 8 + HRA_EVCREC.VAC_HRS)) % (8)), '0') AS nvarchar(max)) + '時'
                        FROM HRP.HRA_EVCREC
                        WHERE 
                           HRA_EVCREC.VAC_TYPE = 'V' AND 
                           HRA_EVCREC.EMP_NO = TA.EMP_NO AND 
                           HRA_EVCREC.ORG_BY = TA.ORG_BY AND 
                           HRA_EVCREC.STATUS IN ( 'Y', 'U' ) AND 
                           CONVERT(varchar(4), HRA_EVCREC.START_DATE, 102) = CONVERT(varchar(4), sysdatetime(), 102) AND 
                           HRA_EVCREC.TRANS_FLAG = 'N'
                     ) AS V_U_DAY, 
                  
                     (
                        SELECT CAST(isnull(floor(sum(HRA_EVCREC$2.VAC_DAYS * 8 + HRA_EVCREC$2.VAC_HRS) / 8), '0') AS nvarchar(max)) + '天' + CAST(isnull(((sum(HRA_EVCREC$2.VAC_DAYS * 8 + HRA_EVCREC$2.VAC_HRS)) % (8)), '0') AS nvarchar(max)) + '時'
                        FROM HRP.HRA_EVCREC  AS HRA_EVCREC$2
                        WHERE 
                           HRA_EVCREC$2.VAC_TYPE = 'S' AND 
                           HRA_EVCREC$2.EMP_NO = TA.EMP_NO AND 
                           HRA_EVCREC$2.ORG_BY = TA.ORG_BY AND 
                           HRA_EVCREC$2.STATUS IN ( 'Y', 'U' ) AND 
                           CONVERT(varchar(4), HRA_EVCREC$2.START_DATE, 102) = CONVERT(varchar(4), sysdatetime(), 102) AND 
                           HRA_EVCREC$2.TRANS_FLAG = 'N'
                     ) AS S_U_DAY, 
                  
                     (
                        SELECT CAST(isnull(floor(sum(HRA_EVCREC$3.VAC_DAYS * 8 + HRA_EVCREC$3.VAC_HRS) / 8), '0') AS nvarchar(max)) + '天' + CAST(isnull(((sum(HRA_EVCREC$3.VAC_DAYS * 8 + HRA_EVCREC$3.VAC_HRS)) % (8)), '0') AS nvarchar(max)) + '時'
                        FROM HRP.HRA_EVCREC  AS HRA_EVCREC$3
                        WHERE 
                           HRA_EVCREC$3.VAC_TYPE = 'F' AND 
                           HRA_EVCREC$3.EMP_NO = TA.EMP_NO AND 
                           HRA_EVCREC$3.ORG_BY = TA.ORG_BY AND 
                           HRA_EVCREC$3.STATUS IN ( 'Y', 'U' ) AND 
                           CONVERT(varchar(4), HRA_EVCREC$3.START_DATE, 102) = CONVERT(varchar(4), sysdatetime(), 102) AND 
                           HRA_EVCREC$3.TRANS_FLAG = 'N'
                     ) AS F_U_DAY, 
                  TA.ABROAD, 
                  CASE 
                     WHEN TB.ORGAN_TYPE = 'ED' OR isnull(TB.ORGAN_TYPE, 'ED') IS NULL THEN '義大'
                     WHEN TB.ORGAN_TYPE = 'EC' OR isnull(TB.ORGAN_TYPE, 'EC') IS NULL THEN '癌醫'
                     WHEN TB.ORGAN_TYPE = 'EF' OR isnull(TB.ORGAN_TYPE, 'EF') IS NULL THEN '大昌'
                     WHEN TB.ORGAN_TYPE = 'EG' OR isnull(TB.ORGAN_TYPE, 'EG') IS NULL THEN '護理之家'
                     WHEN TB.ORGAN_TYPE = 'EK' OR isnull(TB.ORGAN_TYPE, 'EK') IS NULL THEN '產後護理'
                     WHEN TB.ORGAN_TYPE = 'EH' OR isnull(TB.ORGAN_TYPE, 'EH') IS NULL THEN '居護所'
                     WHEN TB.ORGAN_TYPE = 'EL' OR isnull(TB.ORGAN_TYPE, 'EL') IS NULL THEN '貝思諾'
                     WHEN TB.ORGAN_TYPE = 'EN' OR isnull(TB.ORGAN_TYPE, 'EN') IS NULL THEN '幼兒園'
                  END AS ORGANTYPE, 
                  
                     (
                        SELECT HRE_POSMST$2.POS_LEVEL
                        FROM HRP.HRE_POSMST  AS HRE_POSMST$2
                        WHERE HRE_POSMST$2.POS_NO = TB.POS_NO
                     ) AS POSLEVEL
               FROM 
                  (
                     SELECT 
                        fci.ORG_BY, 
                        fci.EMP_NO, 
                        fci.DEPT_NO, 
                        fci.VAC_TYPE, 
                        fci.VAC_RUL, 
                        fci.STATUS, 
                        fci.SD, 
                        fci.ST, 
                        fci.ED, 
                        fci.ET, 
                        fci.EVC_REA, 
                        fci.VAC_DAYS, 
                        fci.VAC_HRS, 
                        fci.REMARK, 
                        fci.ABROAD
                     FROM 
                        (
                           SELECT 
                              T1.ORG_BY, 
                              T1.EMP_NO, 
                              T1.DEPT_NO, 
                              T1.VAC_TYPE, 
                              T1.VAC_RUL, 
                              T1.STATUS, 
                              ssma_oracle.to_char_date(T1.START_DATE, 'yyyy-mm-dd') AS SD, 
                              T1.START_TIME AS ST, 
                              ssma_oracle.to_char_date(T1.END_DATE, 'yyyy-mm-dd') AS ED, 
                              T1.END_TIME AS ET, 
                              T1.EVC_REA, 
                              T1.VAC_DAYS, 
                              T1.VAC_HRS, 
                              T1.REMARK, 
                              T1.ABROAD
                           FROM HRP.HRA_EVCREC  AS T1
                           WHERE T1.STATUS IN ( 'Y', 'U' )
                        )  AS fci
                     WHERE ((fci.SD BETWEEN ssma_oracle.to_char_date(sysdatetime(), 'yyyy-mm-dd') AND ssma_oracle.to_char_date(DATEADD(D, 7, sysdatetime()), 'yyyy-mm-dd')) OR (fci.ED BETWEEN ssma_oracle.to_char_date(sysdatetime(), 'yyyy-mm-dd') AND ssma_oracle.to_char_date(DATEADD(D, 7, sysdatetime()), 'yyyy-mm-dd')) OR (fci.SD <= ssma_oracle.to_char_date(sysdatetime(), 'yyyy-mm-dd') AND fci.ED >= ssma_oracle.to_char_date(DATEADD(D, 7, sysdatetime()), 'yyyy-mm-dd'))) AND fci.ABROAD IN (  ('Y') )
                      UNION ALL
                     SELECT 
                        fci$2.ORG_BY, 
                        fci$2.EMP_NO, 
                        fci$2.DEPT_NO, 
                        fci$2.VAC_TYPE, 
                        fci$2.VAC_RUL, 
                        fci$2.STATUS, 
                        fci$2.SD, 
                        fci$2.ST, 
                        fci$2.ED, 
                        fci$2.ET, 
                        fci$2.EVC_REA, 
                        fci$2.VAC_DAYS, 
                        fci$2.VAC_HRS, 
                        fci$2.REMARK, 
                        fci$2.ABROAD
                     FROM 
                        (
                           SELECT 
                              T1$2.ORG_BY, 
                              T1$2.EMP_NO, 
                              T1$2.DEPT_NO, 
                              'O1' AS VAC_TYPE, 
                              'O1' AS VAC_RUL, 
                              T1$2.STATUS, 
                              ssma_oracle.to_char_date(T1$2.START_DATE, 'yyyy-mm-dd') AS SD, 
                              T1$2.START_TIME AS ST, 
                              ssma_oracle.to_char_date(T1$2.END_DATE, 'yyyy-mm-dd') AS ED, 
                              T1$2.END_TIME AS ET, 
                              T1$2.OTM_REA AS EVC_REA, 
                              0 AS VAC_DAYS, 
                              T1$2.OTM_HRS AS VAC_HRS, 
                              T1$2.REMARK, 
                              T1$2.ABROAD
                           FROM HRP.HRA_OFFREC  AS T1$2
                           WHERE T1$2.ITEM_TYPE = 'O' AND T1$2.STATUS IN ( 'Y', 'U' )
                        )  AS fci$2
                     WHERE ((fci$2.SD BETWEEN ssma_oracle.to_char_date(sysdatetime(), 'yyyy-mm-dd') AND ssma_oracle.to_char_date(DATEADD(D, 7, sysdatetime()), 'yyyy-mm-dd')) OR (fci$2.ED BETWEEN ssma_oracle.to_char_date(sysdatetime(), 'yyyy-mm-dd') AND ssma_oracle.to_char_date(DATEADD(D, 7, sysdatetime()), 'yyyy-mm-dd')) OR (fci$2.SD <= ssma_oracle.to_char_date(sysdatetime(), 'yyyy-mm-dd') AND fci$2.ED >= ssma_oracle.to_char_date(DATEADD(D, 7, sysdatetime()), 'yyyy-mm-dd'))) AND fci$2.ABROAD IN (  ('Y') )
                      UNION ALL
                     SELECT 
                        fci$3.ORG_BY, 
                        fci$3.EMP_NO, 
                        fci$3.DEPT_NO, 
                        fci$3.VAC_TYPE, 
                        fci$3.VAC_RUL, 
                        fci$3.STATUS, 
                        fci$3.SD, 
                        fci$3.ST, 
                        fci$3.ED, 
                        fci$3.ET, 
                        fci$3.EVC_REA, 
                        fci$3.VAC_DAYS, 
                        fci$3.VAC_HRS, 
                        fci$3.REMARK, 
                        fci$3.ABROAD
                     FROM 
                        (
                           SELECT 
                              T1$3.ORG_BY, 
                              T1$3.EMP_NO, 
                              T1$3.DEPT_NO, 
                              'B0' AS VAC_TYPE, 
                              'B0' AS VAC_RUL, 
                              T1$3.STATUS, 
                              ssma_oracle.to_char_date(T1$3.START_DATE, 'yyyy-mm-dd') AS SD, 
                              T1$3.START_TIME AS ST, 
                              ssma_oracle.to_char_date(T1$3.END_DATE, 'yyyy-mm-dd') AS ED, 
                              T1$3.END_TIME AS ET, 
                              T1$3.SUP_REA AS EVC_REA, 
                              0 AS VAC_DAYS, 
                              T1$3.SUP_HRS AS VAC_HRS, 
                              T1$3.REMARK, 
                              T1$3.ABROAD
                           FROM HRP.HRA_SUPMST  AS T1$3
                           WHERE T1$3.STATUS IN ( 'Y', 'U' )
                        )  AS fci$3
                     WHERE ((fci$3.SD BETWEEN ssma_oracle.to_char_date(sysdatetime(), 'yyyy-mm-dd') AND ssma_oracle.to_char_date(DATEADD(D, 7, sysdatetime()), 'yyyy-mm-dd')) OR (fci$3.ED BETWEEN ssma_oracle.to_char_date(sysdatetime(), 'yyyy-mm-dd') AND ssma_oracle.to_char_date(DATEADD(D, 7, sysdatetime()), 'yyyy-mm-dd')) OR (fci$3.SD <= ssma_oracle.to_char_date(sysdatetime(), 'yyyy-mm-dd') AND fci$3.ED >= ssma_oracle.to_char_date(DATEADD(D, 7, sysdatetime()), 'yyyy-mm-dd'))) AND fci$3.ABROAD IN (  ('Y') )
                  )  AS TA, HRP.HRE_EMPBAS  AS TB, HRP.HRA_YEARVAC  AS TC
               WHERE 
                  TA.EMP_NO = TB.EMP_NO AND 
                  TA.ORG_BY = TB.ORGAN_TYPE AND 
                  TA.EMP_NO = TC.EMP_NO AND 
                  TC.VAC_YEAR = CONVERT(varchar(4), sysdatetime(), 102)
               ORDER BY TA.SD, 
                  (
                     SELECT HRE_POSMST.POS_LEVEL
                     FROM HRP.HRE_POSMST
                     WHERE HRE_POSMST.POS_NO = TB.POS_NO
                  ) DESC, TA.EMP_NO
         */



         OPEN CURSOR1

         WHILE 1 = 1
         
            BEGIN

               FETCH CURSOR1
                   INTO 
                     @PEMPNO, 
                     @PCHNAME, 
                     @PDEPTNAME, 
                     @PPOSNAME, 
                     @PVACNAME, 
                     @PSTATUSNAME, 
                     @PSD, 
                     @PST, 
                     @PED, 
                     @PET, 
                     @PEVCREA, 
                     @PVACDAYS, 
                     @PVACHRS, 
                     @PRM, 
                     @PEVCDAY, 
                     @PLASTVACDAY, 
                     @PEVC_U, 
                     @PEVC_S, 
                     @PEVC_F, 
                     @PABROAD, 
                     @PORGANTYPE, 
                     @PPOSLEVEL

               /*
               *   SSMA warning messages:
               *   O2SS0113: The value of @@FETCH_STATUS might be changed by previous FETCH operations on other cursors, if the cursors are used simultaneously.
               */

               IF @@FETCH_STATUS <> 0
                  BREAK

               SET @NCONTI = 0

               
               /*
               *   check 電子假卡vs補休
               *   仍有盲點
               */
               SELECT @NCONTI = count_big(*)
               FROM 
                  (
                     SELECT min(fci$2.START_DATE) AS STARDATE
                     FROM 
                        (
                           SELECT T1.EMP_NO, T1.START_DATE, T1.END_DATE
                           FROM HRP.HRA_EVCREC  AS T1
                           WHERE 
                              T1.STATUS IN ( 'Y', 'U' ) AND 
                              T1.ABROAD = 'Y' AND 
                              ((ssma_oracle.to_char_date(T1.START_DATE, 'yyyy-mm-dd') BETWEEN ssma_oracle.to_char_date(sysdatetime(), 'yyyy-mm-dd') AND ssma_oracle.to_char_date(DATEADD(D, 7, sysdatetime()), 'yyyy-mm-dd')) OR (ssma_oracle.to_char_date(T1.END_DATE, 'yyyy-mm-dd') BETWEEN ssma_oracle.to_char_date(sysdatetime(), 'yyyy-mm-dd') AND ssma_oracle.to_char_date(DATEADD(D, 7, sysdatetime()), 'yyyy-mm-dd')) OR (ssma_oracle.to_char_date(T1.START_DATE, 'yyyy-mm-dd') <= ssma_oracle.to_char_date(sysdatetime(), 'yyyy-mm-dd') AND ssma_oracle.to_char_date(T1.END_DATE, 'yyyy-mm-dd') >= ssma_oracle.to_char_date(sysdatetime(), 'yyyy-mm-dd')))
                            UNION ALL
                           SELECT T1$2.EMP_NO, T1$2.START_DATE, T1$2.END_DATE
                           FROM HRP.HRA_SUPMST  AS T1$2
                           WHERE 
                              T1$2.STATUS IN ( 'Y', 'U' ) AND 
                              ((ssma_oracle.to_char_date(T1$2.START_DATE, 'yyyy-mm-dd') BETWEEN ssma_oracle.to_char_date(sysdatetime(), 'yyyy-mm-dd') AND ssma_oracle.to_char_date(DATEADD(D, 7, sysdatetime()), 'yyyy-mm-dd')) OR (ssma_oracle.to_char_date(T1$2.END_DATE, 'yyyy-mm-dd') BETWEEN ssma_oracle.to_char_date(sysdatetime(), 'yyyy-mm-dd') AND ssma_oracle.to_char_date(DATEADD(D, 7, sysdatetime()), 'yyyy-mm-dd')) OR (ssma_oracle.to_char_date(T1$2.START_DATE, 'yyyy-mm-dd') <= ssma_oracle.to_char_date(sysdatetime(), 'yyyy-mm-dd') AND ssma_oracle.to_char_date(T1$2.END_DATE, 'yyyy-mm-dd') >= ssma_oracle.to_char_date(DATEADD(D, 7, sysdatetime()), 'yyyy-mm-dd'))) AND 
                              T1$2.ABROAD IN (  'Y' )
                        )  AS fci$2
                     WHERE fci$2.EMP_NO = @PEMPNO
                  )  AS fci
               WHERE ssma_oracle.to_char_date(fci.STARDATE, 'yyyy-mm-dd') <= ssma_oracle.to_char_date(sysdatetime(), 'yyyy-mm-dd')

               IF @PSD <= ssma_oracle.to_char_date(sysdatetime(), 'yyyy-mm-dd') OR @NCONTI <> 0
                  SET @PABROAD = ISNULL(@PABROAD, '') + '-已出'
               ELSE 
                  SET @PABROAD = ISNULL(@PABROAD, '') + '-未出'

               /*2023-4-11 拆2封 by108154*/
               IF (ssma_oracle.length_varchar(@SMESSAGE) < 19000)
                  BEGIN

                     SET @SMESSAGE = 
                        ISNULL(@SMESSAGE, '')
                         + 
                        '<TR><TD>'
                         + 
                        ISNULL(@PORGANTYPE, '')
                         + 
                        '</td><TD>'
                         + 
                        ISNULL(@PEMPNO, '')
                         + 
                        '</td><TD>'
                         + 
                        ISNULL(@PCHNAME, '')
                         + 
                        '</td><TD>'
                         + 
                        ISNULL(@PDEPTNAME, '')
                         + 
                        '</td>'

                     SET @SMESSAGE = 
                        ISNULL(@SMESSAGE, '')
                         + 
                        '<TD>'
                         + 
                        ISNULL(@PPOSNAME, '')
                         + 
                        '</td><TD>'
                         + 
                        ISNULL(CAST(@PPOSLEVEL AS nvarchar(max)), '')
                         + 
                        '</td><TD>'
                         + 
                        ISNULL(@PVACNAME, '')
                         + 
                        '</td><TD>'
                         + 
                        ISNULL(@PSTATUSNAME, '')
                         + 
                        '</td>'

                     SET @SMESSAGE = 
                        ISNULL(@SMESSAGE, '')
                         + 
                        '<TD>'
                         + 
                        ISNULL(@PSD, '')
                         + 
                        '</td><TD>'
                         + 
                        ISNULL(@PST, '')
                         + 
                        '</td><TD>'
                         + 
                        ISNULL(@PED, '')
                         + 
                        '</td>'

                     SET @SMESSAGE = 
                        ISNULL(@SMESSAGE, '')
                         + 
                        '<TD>'
                         + 
                        ISNULL(@PET, '')
                         + 
                        '</td><TD>'
                         + 
                        ISNULL(CAST(@PVACDAYS AS nvarchar(max)), '')
                         + 
                        '</td><TD>'
                         + 
                        ISNULL(CAST(@PVACHRS AS nvarchar(max)), '')
                         + 
                        '</td>'

                     SET @SMESSAGE = 
                        ISNULL(@SMESSAGE, '')
                         + 
                        '<TD>'
                         + 
                        ISNULL(@PEVCREA, '')
                         + 
                        '</td><TD>'
                         + 
                        ISNULL(@PRM, '')
                         + 
                        '</td><TD>'
                         + 
                        ISNULL(@PABROAD, '')
                         + 
                        '</td></tr>'

                  END
               ELSE 
                  IF @SMESSAGE2 IS NULL OR @SMESSAGE2 = ''
                     BEGIN

                        SET @SMESSAGE2 = '<table border="1" width="100%">'

                        SET @SMESSAGE2 = ISNULL(@SMESSAGE2, '') + '<tr><td colspan="17" ><BR>' + '==========(一般人員出國假單)==========' + '<BR><BR></tr></tr>'

                        SET @SMESSAGE2 = ISNULL(@SMESSAGE2, '') + '<TR><TD>機構</td><TD>工號</td><TD>姓名</td><TD>部門名稱</td><TD>職稱</td><TD>職等</td><TD>假別</td>'

                        SET @SMESSAGE2 = ISNULL(@SMESSAGE2, '') + '<TD>狀態</td><TD>開始日期</td><TD>開始時間</td><TD>結束日期</td><TD>結束時間</td>'

                        SET @SMESSAGE2 = ISNULL(@SMESSAGE2, '') + '<TD>天數</td><TD>時數</td><TD>請假理由</td><TD>其他原因</td><TD>出國</td>'

                        SET @SMESSAGE2 = 
                           ISNULL(@SMESSAGE2, '')
                            + 
                           '<TR><TD>'
                            + 
                           ISNULL(@PORGANTYPE, '')
                            + 
                           '</td><TD>'
                            + 
                           ISNULL(@PEMPNO, '')
                            + 
                           '</td><TD>'
                            + 
                           ISNULL(@PCHNAME, '')
                            + 
                           '</td><TD>'
                            + 
                           ISNULL(@PDEPTNAME, '')
                            + 
                           '</td>'

                        SET @SMESSAGE2 = 
                           ISNULL(@SMESSAGE2, '')
                            + 
                           '<TD>'
                            + 
                           ISNULL(@PPOSNAME, '')
                            + 
                           '</td><TD>'
                            + 
                           ISNULL(CAST(@PPOSLEVEL AS nvarchar(max)), '')
                            + 
                           '</td><TD>'
                            + 
                           ISNULL(@PVACNAME, '')
                            + 
                           '</td><TD>'
                            + 
                           ISNULL(@PSTATUSNAME, '')
                            + 
                           '</td>'

                        SET @SMESSAGE2 = 
                           ISNULL(@SMESSAGE2, '')
                            + 
                           '<TD>'
                            + 
                           ISNULL(@PSD, '')
                            + 
                           '</td><TD>'
                            + 
                           ISNULL(@PST, '')
                            + 
                           '</td><TD>'
                            + 
                           ISNULL(@PED, '')
                            + 
                           '</td>'

                        SET @SMESSAGE2 = 
                           ISNULL(@SMESSAGE2, '')
                            + 
                           '<TD>'
                            + 
                           ISNULL(@PET, '')
                            + 
                           '</td><TD>'
                            + 
                           ISNULL(CAST(@PVACDAYS AS nvarchar(max)), '')
                            + 
                           '</td><TD>'
                            + 
                           ISNULL(CAST(@PVACHRS AS nvarchar(max)), '')
                            + 
                           '</td>'

                        SET @SMESSAGE2 = 
                           ISNULL(@SMESSAGE2, '')
                            + 
                           '<TD>'
                            + 
                           ISNULL(@PEVCREA, '')
                            + 
                           '</td><TD>'
                            + 
                           ISNULL(@PRM, '')
                            + 
                           '</td><TD>'
                            + 
                           ISNULL(@PABROAD, '')
                            + 
                           '</td></tr>'

                     END
                  ELSE 
                     BEGIN

                        SET @SMESSAGE2 = 
                           ISNULL(@SMESSAGE2, '')
                            + 
                           '<TR><TD>'
                            + 
                           ISNULL(@PORGANTYPE, '')
                            + 
                           '</td><TD>'
                            + 
                           ISNULL(@PEMPNO, '')
                            + 
                           '</td><TD>'
                            + 
                           ISNULL(@PCHNAME, '')
                            + 
                           '</td><TD>'
                            + 
                           ISNULL(@PDEPTNAME, '')
                            + 
                           '</td>'

                        SET @SMESSAGE2 = 
                           ISNULL(@SMESSAGE2, '')
                            + 
                           '<TD>'
                            + 
                           ISNULL(@PPOSNAME, '')
                            + 
                           '</td><TD>'
                            + 
                           ISNULL(CAST(@PPOSLEVEL AS nvarchar(max)), '')
                            + 
                           '</td><TD>'
                            + 
                           ISNULL(@PVACNAME, '')
                            + 
                           '</td><TD>'
                            + 
                           ISNULL(@PSTATUSNAME, '')
                            + 
                           '</td>'

                        SET @SMESSAGE2 = 
                           ISNULL(@SMESSAGE2, '')
                            + 
                           '<TD>'
                            + 
                           ISNULL(@PSD, '')
                            + 
                           '</td><TD>'
                            + 
                           ISNULL(@PST, '')
                            + 
                           '</td><TD>'
                            + 
                           ISNULL(@PED, '')
                            + 
                           '</td>'

                        SET @SMESSAGE2 = 
                           ISNULL(@SMESSAGE2, '')
                            + 
                           '<TD>'
                            + 
                           ISNULL(@PET, '')
                            + 
                           '</td><TD>'
                            + 
                           ISNULL(CAST(@PVACDAYS AS nvarchar(max)), '')
                            + 
                           '</td><TD>'
                            + 
                           ISNULL(CAST(@PVACHRS AS nvarchar(max)), '')
                            + 
                           '</td>'

                        SET @SMESSAGE2 = 
                           ISNULL(@SMESSAGE2, '')
                            + 
                           '<TD>'
                            + 
                           ISNULL(@PEVCREA, '')
                            + 
                           '</td><TD>'
                            + 
                           ISNULL(@PRM, '')
                            + 
                           '</td><TD>'
                            + 
                           ISNULL(@PABROAD, '')
                            + 
                           '</td></tr>'

                     END

            END

         CLOSE CURSOR1

         DEALLOCATE CURSOR1

         SET @STITLE = '未來一週請假出國人員名單(一般人員)(' + ISNULL(ssma_oracle.to_char_date(sysdatetime(), 'yyyy-mm-dd'), '') + ')'

         SET @STITLE2 = '未來一週請假出國人員名單(一般人員)(第2封/共2封)(' + ISNULL(ssma_oracle.to_char_date(sysdatetime(), 'yyyy-mm-dd'), '') + ')'

         IF @SMESSAGE IS NULL OR @SMESSAGE = ''
            BEGIN

               SET @SMESSAGEMAIL = '截至上午07:10，無未來一週請假出國假卡。'

               DECLARE
                   CURSOR2 CURSOR LOCAL FOR 
                     
                     /*
                     *   收件人
                     *   SELECT CODE_NAME
                     *                                                 FROM HR_CODEDTL
                     *                                                WHERE CODE_TYPE = 'HRA62'
                     *                                                  AND DISABLED = 'N';
                     */
                     SELECT 'ed108154@edah.org.tw'/*李采柔*/
                      UNION ALL
                     SELECT 'ed108482@edah.org.tw'/*葉鈴雅*/
                      UNION ALL
                     SELECT 'ed100037@edah.org.tw'/*鄭淑宏*/
                      UNION ALL
                     SELECT 'ed100054@edah.org.tw'/*蔡易庭*/
                      UNION ALL
                     SELECT 'ed100005@edah.org.tw'/*洪行政長*/
                      UNION ALL
                     SELECT 'ed105094@edah.org.tw'/*許菀齡副行政長*/

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
                        @MESSAGE = @SMESSAGEMAIL

                  END

               CLOSE CURSOR2

               DEALLOCATE CURSOR2

            END
         ELSE 
            /*無醫師有一般(一封)*/
            IF @SMESSAGE2 IS NULL OR @SMESSAGE2 = ''
               BEGIN

                  SET @SMESSAGE = ISNULL(@SMESSAGE, '') + '</table>'

                  SET @SMESSAGEMAIL = @SMESSAGE

                  DECLARE
                      CURSOR2 CURSOR LOCAL FOR 
                        
                        /*
                        *   收件人
                        *   SELECT CODE_NAME
                        *                                                 FROM HR_CODEDTL
                        *                                                WHERE CODE_TYPE = 'HRA62'
                        *                                                  AND DISABLED = 'N';
                        */
                        SELECT 'ed108154@edah.org.tw'/*李采柔*/
                         UNION ALL
                        SELECT 'ed108482@edah.org.tw'/*葉鈴雅*/
                         UNION ALL
                        SELECT 'ed100037@edah.org.tw'/*鄭淑宏*/
                         UNION ALL
                        SELECT 'ed100054@edah.org.tw'/*蔡易庭*/
                         UNION ALL
                        SELECT 'ed100005@edah.org.tw'/*洪行政長*/
                         UNION ALL
                        SELECT 'ed105094@edah.org.tw'/*許菀齡副行政長*/

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
            ELSE 
               BEGIN

                  SET @STITLE = '未來一週請假出國人員名單(一般人員)(第1封/共2封)(' + ISNULL(ssma_oracle.to_char_date(sysdatetime(), 'yyyy-mm-dd'), '') + ')'

                  SET @SMESSAGE = ISNULL(@SMESSAGE, '') + '</table>'

                  SET @SMESSAGEMAIL = @SMESSAGE

                  DECLARE
                      CURSOR2 CURSOR LOCAL FOR 
                        
                        /*
                        *   收件人
                        *   SELECT CODE_NAME
                        *                                                 FROM HR_CODEDTL
                        *                                                WHERE CODE_TYPE = 'HRA62'
                        *                                                  AND DISABLED = 'N';
                        */
                        SELECT 'ed108154@edah.org.tw'/*李采柔*/
                         UNION ALL
                        SELECT 'ed108482@edah.org.tw'/*葉鈴雅*/
                         UNION ALL
                        SELECT 'ed100037@edah.org.tw'/*鄭淑宏*/
                         UNION ALL
                        SELECT 'ed100054@edah.org.tw'/*蔡易庭*/
                         UNION ALL
                        SELECT 'ed100005@edah.org.tw'/*洪行政長*/
                         UNION ALL
                        SELECT 'ed105094@edah.org.tw'/*許菀齡副行政長*/

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
                           @MESSAGE = @SMESSAGEMAIL

                     END

                  CLOSE CURSOR2

                  DEALLOCATE CURSOR2

                  SET @SMESSAGE2 = ISNULL(@SMESSAGE2, '') + '</table>'

                  DECLARE
                      CURSOR2 CURSOR LOCAL FOR 
                        
                        /*
                        *   收件人
                        *   SELECT CODE_NAME
                        *                                                 FROM HR_CODEDTL
                        *                                                WHERE CODE_TYPE = 'HRA62'
                        *                                                  AND DISABLED = 'N';
                        */
                        SELECT 'ed108154@edah.org.tw'/*李采柔*/
                         UNION ALL
                        SELECT 'ed108482@edah.org.tw'/*葉鈴雅*/
                         UNION ALL
                        SELECT 'ed100037@edah.org.tw'/*鄭淑宏*/
                         UNION ALL
                        SELECT 'ed100054@edah.org.tw'/*蔡易庭*/
                         UNION ALL
                        SELECT 'ed100005@edah.org.tw'/*洪行政長*/
                         UNION ALL
                        SELECT 'ed105094@edah.org.tw'/*許菀齡副行政長*/

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
                           @SUBJECT = @STITLE2, 
                           @MESSAGE = @SMESSAGE2

                     END

                  CLOSE CURSOR2

                  DEALLOCATE CURSOR2

               END

      END TRY

      BEGIN CATCH

         DECLARE
            @errornumber int

         SET @errornumber = ERROR_NUMBER()

         DECLARE
            @errormessage$2 nvarchar(4000)

         SET @errormessage$2 = ERROR_MESSAGE()

         DECLARE
            @exceptionidentifier nvarchar(4000)

         SELECT @exceptionidentifier = ssma_oracle.db_error_get_oracle_exception_id(@errormessage$2, @errornumber)

         BEGIN

            SET @ERRORCODE = ssma_oracle.db_error_sqlcode(@exceptionidentifier, @errornumber)

            SET @ERRORMESSAGE = ssma_oracle.db_error_sqlerrm_0(@exceptionidentifier, @errornumber)

            INSERT HRP.HRA_UNNORMAL_LOG(
               LOG_SEQ, 
               PROG_NAME, 
               SYS_DATE, 
               LOG_CODE, 
               LOG_MSG, 
               LOG_INFO, 
               CREATED_BY, 
               CREATION_DATE, 
               LAST_UPDATED_BY, 
               LAST_UPDATE_DATE)
               VALUES (
                  ssma_oracle.to_char_date(sysdatetime(), 'MMDDHH24MISS'), 
                  '請假出國人員通知', 
                  sysdatetime(), 
                  @ERRORCODE, 
                  '未來一週請假出國人員名單通知執行異常(一般人員)', 
                  @ERRORMESSAGE, 
                  'MIS', 
                  sysdatetime(), 
                  'MIS', 
                  sysdatetime())

            IF @@TRANCOUNT > 0
               COMMIT TRANSACTION 

         END

      END CATCH

   END
GO
BEGIN TRY
    EXEC sp_addextendedproperty
        N'MS_SSMA_SOURCE', N'HRP.EHRPHRAFUNC_PKG.HRASEND_MAIL_ABROAD',
        N'SCHEMA', N'hrp',
        N'PROCEDURE', N'EHRPHRAFUNC_PKG$HRASEND_MAIL_ABROAD'
END TRY
BEGIN CATCH
    IF (@@TRANCOUNT > 0) ROLLBACK
    PRINT ERROR_MESSAGE()
END CATCH
GO
