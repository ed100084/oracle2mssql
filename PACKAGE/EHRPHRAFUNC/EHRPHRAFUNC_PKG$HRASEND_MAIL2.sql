
USE MIS
GO
 IF NOT EXISTS(SELECT * FROM sys.schemas WHERE [name] = N'hrp')      
     EXEC (N'CREATE SCHEMA hrp')                                   
 GO                                                               

USE MIS
GO
IF  EXISTS (SELECT * FROM sys.objects so JOIN sys.schemas sc ON so.schema_id = sc.schema_id WHERE so.name = N'EHRPHRAFUNC_PKG$HRASEND_MAIL2'  AND sc.name=N'hrp'  AND type in (N'P',N'PC'))
 DROP PROCEDURE [hrp].[EHRPHRAFUNC_PKG$HRASEND_MAIL2]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE HRP.EHRPHRAFUNC_PKG$HRASEND_MAIL2  
AS 
   BEGIN

      DECLARE
         @PEMPNO varchar(20), 
         @PCHNAME varchar(200), 
         @PDEPTNAME varchar(60), 
         @PPOSNAME varchar(60), 
         @PVACNAME varchar(40), 
         @PSTATUSNAME varchar(10), 
         @PSD varchar(10), 
         @PST varchar(4), 
         @PED varchar(10), 
         @PET varchar(4), 
         @PEVCREA varchar(100), 
         @PVACDAYS numeric(3), 
         @PVACHRS numeric(4, 1), 
         @PRM varchar(300), 
         @PEVCDAY varchar(100), 
         @PLASTVACDAY varchar(100)/*20190130 108978 增加遞延天數顯示*/, 
         @PEVC_U varchar(100), 
         @PEVC_F varchar(100), 
         @PEVC_S varchar(100), 
         @PABROAD varchar(2)/*20200214 108154 增加出國註記*/, 
         @PEVC_P varchar(100)/*20220317 108482 增加年度公假*/, 
         @PSUP_HR varchar(100)/*20220317 108482 增加年度補休*/, 
         @STITLE varchar(100), 
         @SEEMAIL varchar(120), 
         @SMESSAGE varchar(max), 
         /*
         *   SSMA warning messages:
         *   O2SS0356: Conversion from NUMBER datatype can cause data loss.
         */

         @ERRORCODE float(53)/*20220715 108482 記錄異常代碼*/, 
         @ERRORMESSAGE varchar(500)/*20220715 108482 記錄異常訊息*/

      BEGIN TRY

         EXECUTE ssma_oracle.db_check_init_package 'HRP', 'EHRPHRAFUNC_PKG'

         /* SELECT 'ed108154@edah.org.tw' FROM dual;*/
         SET @SMESSAGE = NULL

         /* 
         *   SSMA error messages:
         *   O2SS0083: Identifier ta.st cannot be converted because it was not resolved.

         DECLARE
             CURSOR1 CURSOR LOCAL FOR 
               /* 
               *   SSMA error messages:
               *   O2SS0083: Identifier ta.st cannot be converted because it was not resolved.
               *   O2SS0083: Identifier ta.ed cannot be converted because it was not resolved.
               *   O2SS0083: Identifier ta.et cannot be converted because it was not resolved.
               *   O2SS0083: Identifier ta.remark cannot be converted because it was not resolved.

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
                     ELSE 
                        (
                           SELECT HRA_VCRLMST.VAC_NAME
                           FROM HRP.HRA_VCRLMST
                           WHERE HRA_VCRLMST.VAC_TYPE = TA.VAC_TYPE
                        )
                  END AS VACNAME, 
                  CASE TA.STATUS
                     WHEN 'Y' THEN '准'
                     WHEN 'U' THEN CASE 
                        WHEN 
                           (
                              SELECT count_big(*)
                              FROM HRP.HRA_EVCFLOW
                              WHERE HRA_EVCFLOW.EVC_NO = TA.EVC_NO
                           ) = 0 THEN '申請'
                        WHEN 
                           (
                              SELECT count_big(*)
                              FROM HRP.HRA_EVCFLOW  AS HRA_EVCFLOW$2
                              WHERE HRA_EVCFLOW$2.EVC_NO = TA.EVC_NO
                           ) = 1 THEN '初審'
                        ELSE '覆審'
                     END
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
                  
                     (
                        SELECT CAST(isnull(floor(sum(HRA_EVCREC$4.VAC_DAYS * 8 + HRA_EVCREC$4.VAC_HRS) / 8), '0') AS nvarchar(max)) + '天' + CAST(isnull(((sum(HRA_EVCREC$4.VAC_DAYS * 8 + HRA_EVCREC$4.VAC_HRS)) % (8)), '0') AS nvarchar(max)) + '時'
                        FROM HRP.HRA_EVCREC  AS HRA_EVCREC$4
                        WHERE 
                           HRA_EVCREC$4.VAC_TYPE = 'P' AND 
                           HRA_EVCREC$4.EMP_NO = TA.EMP_NO AND 
                           HRA_EVCREC$4.ORG_BY = TA.ORG_BY AND 
                           HRA_EVCREC$4.STATUS IN ( 'Y', 'U' ) AND 
                           CONVERT(varchar(4), HRA_EVCREC$4.START_DATE, 102) = CONVERT(varchar(4), sysdatetime(), 102) AND 
                           HRA_EVCREC$4.TRANS_FLAG = 'N'
                     ) AS P_U_DAY, 
                  
                     (
                        SELECT CAST(isnull(floor(sum(HRA_SUPMST.SUP_HRS) / 8), '0') AS nvarchar(max)) + '天' + CAST(isnull(((sum(HRA_SUPMST.SUP_HRS)) % (8)), '0') AS nvarchar(max)) + '時'
                        FROM HRP.HRA_SUPMST
                        WHERE 
                           HRA_SUPMST.EMP_NO = TA.EMP_NO AND 
                           HRA_SUPMST.ORG_BY = TA.ORG_BY AND 
                           HRA_SUPMST.STATUS IN ( 'Y', 'U' ) AND 
                           CONVERT(varchar(4), HRA_SUPMST.START_DATE, 102) = CONVERT(varchar(4), sysdatetime(), 102)
                     ) AS SUP_U_HR
               FROM 
                  (
                     SELECT 
                        fci.EVC_NO, 
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
                              T1.EVC_NO, 
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
                     WHERE 
                        fci.SD <= ssma_oracle.to_char_date(sysdatetime(), 'yyyy-mm-dd') AND 
                        fci.ED >= ssma_oracle.to_char_date(sysdatetime(), 'yyyy-mm-dd') AND 
                        fci.EMP_NO IN 
                        /* (SELECT code_no FROM HR_CODEDTL WHERE code_type = 'HRA67')*/
                        (
                           SELECT HRE_EMPBAS.EMP_NO
                           FROM HRP.HRE_EMPBAS
                           WHERE 
                              HRE_EMPBAS.POS_NO IN 
                              (
                                 SELECT HRE_POSMST$2.POS_NO
                                 FROM HRP.HRE_POSMST  AS HRE_POSMST$2
                                 WHERE HRE_POSMST$2.POS_LEVEL >= 7/*BETWEEN 7 AND 11*/
                              ) AND 
                              HRE_EMPBAS.DISABLED = 'N' AND 
                              HRE_EMPBAS.EMP_FLAG = '01' AND 
                              isnull(HRE_EMPBAS.JOB_LEV, 'Z') <> 'R' AND 
                              HRE_EMPBAS.EMP_NO <> '100003'/*排除執副(需求單)*/
                        )
                      UNION ALL
                     SELECT 
                        NULL, 
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
                     WHERE 
                        fci$2.SD <= ssma_oracle.to_char_date(sysdatetime(), 'yyyy-mm-dd') AND 
                        fci$2.ED >= ssma_oracle.to_char_date(sysdatetime(), 'yyyy-mm-dd') AND 
                        fci$2.EMP_NO IN 
                        /*    (SELECT code_no FROM HR_CODEDTL WHERE code_type = 'HRA67')*/
                        (
                           SELECT HRE_EMPBAS$2.EMP_NO
                           FROM HRP.HRE_EMPBAS  AS HRE_EMPBAS$2
                           WHERE 
                              HRE_EMPBAS$2.POS_NO IN 
                              (
                                 SELECT HRE_POSMST$3.POS_NO
                                 FROM HRP.HRE_POSMST  AS HRE_POSMST$3
                                 WHERE HRE_POSMST$3.POS_LEVEL >= 7/*BETWEEN 7 AND 11*/
                              ) AND 
                              HRE_EMPBAS$2.DISABLED = 'N' AND 
                              HRE_EMPBAS$2.EMP_FLAG = '01' AND 
                              isnull(HRE_EMPBAS$2.JOB_LEV, 'Z') <> 'R' AND 
                              HRE_EMPBAS$2.EMP_NO <> '100003'/*排除執副(需求單)*/
                        )
                      UNION ALL
                     SELECT 
                        NULL, 
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
                     WHERE 
                        fci$3.SD <= ssma_oracle.to_char_date(sysdatetime(), 'yyyy-mm-dd') AND 
                        fci$3.ED >= ssma_oracle.to_char_date(sysdatetime(), 'yyyy-mm-dd') AND 
                        fci$3.EMP_NO IN 
                        /*(SELECT code_no FROM HR_CODEDTL WHERE code_type = 'HRA67')*/
                        (
                           SELECT HRE_EMPBAS$3.EMP_NO
                           FROM HRP.HRE_EMPBAS  AS HRE_EMPBAS$3
                           WHERE 
                              HRE_EMPBAS$3.POS_NO IN 
                              (
                                 SELECT HRE_POSMST$4.POS_NO
                                 FROM HRP.HRE_POSMST  AS HRE_POSMST$4
                                 WHERE HRE_POSMST$4.POS_LEVEL >= 7/*BETWEEN 7 AND 11*/
                              ) AND 
                              HRE_EMPBAS$3.DISABLED = 'N' AND 
                              HRE_EMPBAS$3.EMP_FLAG = '01' AND 
                              isnull(HRE_EMPBAS$3.JOB_LEV, 'Z') <> 'R' AND 
                              HRE_EMPBAS$3.EMP_NO <> '100003'/*排除執副(需求單)*/
                        )
                  )  AS TA 
                     LEFT OUTER JOIN HRP.HRA_YEARVAC  AS TC 
                     ON TA.EMP_NO = TC.EMP_NO AND TC.VAC_YEAR = CONVERT(varchar(4), sysdatetime(), 102), 
                  HRP.HRE_EMPBAS  AS TB
               WHERE TA.EMP_NO = TB.EMP_NO AND TA.ORG_BY = TB.ORGAN_TYPE
               */


               
               /*
               *     AND ta.emp_no ='108154' --test
               *   AND ta.emp_no = tc.emp_no
               *   AND tc.vac_year = TO_CHAR(SYSDATE, 'yyyy')
               */
               ORDER BY TA.EMP_NO, TA.SD, TA.ST
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
                     @PEVC_P, 
                     @PSUP_HR

               /*
               *   SSMA warning messages:
               *   O2SS0113: The value of @@FETCH_STATUS might be changed by previous FETCH operations on other cursors, if the cursors are used simultaneously.
               */

               IF @@FETCH_STATUS <> 0
                  BREAK

               IF @SMESSAGE IS NULL OR @SMESSAGE = ''
                  BEGIN

                     SET @SMESSAGE = '<table border="1" width="100%"><TR><TD>工號</td><TD>姓名</td><TD>部門名稱</td><TD>職稱</td><TD>假別</td>'

                     SET @SMESSAGE = ISNULL(@SMESSAGE, '') + '<TD>狀態</td><TD>開始日期</td><TD>開始時間</td><TD>結束日期</td><TD>結束時間</td>'

                     SET @SMESSAGE = ISNULL(@SMESSAGE, '') + '<TD>天數</td><TD>時數</td><TD>請假理由</td><TD>其他原因</td><TD>出國</td><TD>可休特休</td><TD>已請特休</td><TD>事假</td><TD>病假</td></tr>'

                     /*'<TD>天數</td><TD>時數</td><TD>請假理由</td><TD>其他原因</td><TD>出國</td><TD>可休特休</td><TD>已休特休</td><TD>事假</td><TD>病假</td><TD>公假</td><TD>補休</td></tr>';*/
                     SET @SMESSAGE = 
                        ISNULL(@SMESSAGE, '')
                         + 
                        '<TR><TD>'
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
                        '</td><TD>'
                         + 
                        ISNULL(@PEVCDAY, '')
                         + 
                        '<font color="red">(含遞延'
                         + 
                        ISNULL(@PLASTVACDAY, '')
                         + 
                        '天)</font></td><TD>'
                         + 
                        ISNULL(@PEVC_U, '')
                         + 
                        '</td><TD>'
                         + 
                        ISNULL(@PEVC_F, '')
                         + 
                        '</td><TD>'
                         + 
                        ISNULL(@PEVC_S, '')
                         + 
                        '</td></tr>'

                  END
               /*'</td><TD>' || pevc_s || '</td><td>'|| pevc_p || '</td><td>'|| psup_hr ||'</td></tr>';*/
               ELSE 
                  BEGIN

                     SET @SMESSAGE = 
                        ISNULL(@SMESSAGE, '')
                         + 
                        '<TR><TD>'
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
                        '</td><TD>'
                         + 
                        ISNULL(@PEVCDAY, '')
                         + 
                        '<font color="red">(含遞延'
                         + 
                        ISNULL(@PLASTVACDAY, '')
                         + 
                        '天)</font></td><TD>'
                         + 
                        ISNULL(@PEVC_U, '')
                         + 
                        '</td><TD>'
                         + 
                        ISNULL(@PEVC_F, '')
                         + 
                        '</td><TD>'
                         + 
                        ISNULL(@PEVC_S, '')
                         + 
                        '</td></tr>'/*'</td><TD>' || pevc_s || '</td><td>'|| pevc_p || '</td><td>'|| psup_hr ||'</td></tr>';*/

                  END

            END

         CLOSE CURSOR1

         DEALLOCATE CURSOR1

         SET @STITLE = '今日一級主管請假彙總表(' + ISNULL(ssma_oracle.to_char_date(sysdatetime(), 'yyyy-mm-dd'), '') + ')'

         IF (@SMESSAGE IS NOT NULL AND @SMESSAGE != '')
            BEGIN

               SET @SMESSAGE = ISNULL(@SMESSAGE, '') + '</table>'

               DECLARE
                   CURSOR2 CURSOR LOCAL FOR 
                     SELECT HR_CODEDTL.CODE_NAME
                     FROM HRP.HR_CODEDTL
                     WHERE HR_CODEDTL.CODE_TYPE = 'HRA62' AND HR_CODEDTL.DISABLED = 'N'

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

               SET @SMESSAGE = '截至上午07:00，無今日(' + ISNULL(ssma_oracle.to_char_date(sysdatetime(), 'yyyy-mm-dd'), '') + ')'

               SET @SMESSAGE = ISNULL(@SMESSAGE, '') + '一級主管電子假卡、補休申請單。'

               DECLARE
                   CURSOR2 CURSOR LOCAL FOR 
                     SELECT HR_CODEDTL.CODE_NAME
                     FROM HRP.HR_CODEDTL
                     WHERE HR_CODEDTL.CODE_TYPE = 'HRA62' AND HR_CODEDTL.DISABLED = 'N'

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
                  '一級主管請假彙總', 
                  sysdatetime(), 
                  @ERRORCODE, 
                  '今日一級主管請假彙總表通知執行異常', 
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
        N'MS_SSMA_SOURCE', N'HRP.EHRPHRAFUNC_PKG.HRASEND_MAIL2',
        N'SCHEMA', N'hrp',
        N'PROCEDURE', N'EHRPHRAFUNC_PKG$HRASEND_MAIL2'
END TRY
BEGIN CATCH
    IF (@@TRANCOUNT > 0) ROLLBACK
    PRINT ERROR_MESSAGE()
END CATCH
GO
