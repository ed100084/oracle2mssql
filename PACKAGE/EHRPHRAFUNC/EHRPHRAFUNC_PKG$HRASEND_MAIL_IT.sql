
USE MIS
GO
 IF NOT EXISTS(SELECT * FROM sys.schemas WHERE [name] = N'hrp')      
     EXEC (N'CREATE SCHEMA hrp')                                   
 GO                                                               

USE MIS
GO
IF  EXISTS (SELECT * FROM sys.objects so JOIN sys.schemas sc ON so.schema_id = sc.schema_id WHERE so.name = N'EHRPHRAFUNC_PKG$HRASEND_MAIL_IT'  AND sc.name=N'hrp'  AND type in (N'P',N'PC'))
 DROP PROCEDURE [hrp].[EHRPHRAFUNC_PKG$HRASEND_MAIL_IT]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE HRP.EHRPHRAFUNC_PKG$HRASEND_MAIL_IT  
AS 
   BEGIN

      EXECUTE ssma_oracle.db_check_init_package 'HRP', 'EHRPHRAFUNC_PKG'

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
         @PRM2 varchar(50), 
         @STITLE varchar(100), 
         @SEEMAIL varchar(120), 
         @SMESSAGE varchar(max), 
         @SMESSAGE2 varchar(max), 
         @SMESSAGE3 varchar(500), 
         /*
         *   SSMA warning messages:
         *   O2SS0356: Conversion from NUMBER datatype can cause data loss.
         */

         @ICNTTIME float(53)/*共多少居隔人次(一人隔離過幾次算幾次)*/, 
         /*
         *   SSMA warning messages:
         *   O2SS0356: Conversion from NUMBER datatype can cause data loss.
         */

         @ICNTNOW float(53)/*正在居隔中人數*/, 
         /*
         *   SSMA warning messages:
         *   O2SS0356: Conversion from NUMBER datatype can cause data loss.
         */

         @ICNTCOVID float(53)/*本人確診人數*/, 
         /*
         *   SSMA warning messages:
         *   O2SS0356: Conversion from NUMBER datatype can cause data loss.
         */

         @ICNTPERSON float(53)/*共多少人居隔過*/, 
         /*
         *   SSMA warning messages:
         *   O2SS0356: Conversion from NUMBER datatype can cause data loss.
         */

         @ICNTALL float(53)/*資訊部總人數*/, 
         /*
         *   SSMA warning messages:
         *   O2SS0356: Conversion from NUMBER datatype can cause data loss.
         */

         @IPERCENT float(53)/*居隔率(iCntPerson/iCntAll)*100 百分比四捨五入至整數*/, 
         /*
         *   SSMA warning messages:
         *   O2SS0356: Conversion from NUMBER datatype can cause data loss.
         */

         @IPERCENTC float(53)/*確診率(iCntCovid/iCntAll)*100 百分比四捨五入至整數*/

      SET @SMESSAGE = NULL

      /* 
      *   SSMA error messages:
      *   O2SS0083: Identifier TA.ED cannot be converted because it was not resolved.
      *   O2SS0083: Identifier TA.ST cannot be converted because it was not resolved.
      *   O2SS0083: Identifier TA.ET cannot be converted because it was not resolved.

      DECLARE
          CURSOR1 CURSOR LOCAL FOR 
            /* 
            *   SSMA error messages:
            *   O2SS0083: Identifier TA.ST cannot be converted because it was not resolved.
            *   O2SS0083: Identifier TA.ED cannot be converted because it was not resolved.
            *   O2SS0083: Identifier TA.ET cannot be converted because it was not resolved.
            *   O2SS0083: Identifier TA.REMARK cannot be converted because it was not resolved.

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
                        *   O2SS0083: Identifier TA.EVC_REA cannot be converted because it was not resolved.

                        SELECT HR_CODEDTL.CODE_NAME
                        FROM HRP.HR_CODEDTL
                        WHERE HR_CODEDTL.CODE_TYPE = 'HRA22' AND HR_CODEDTL.CODE_NO = TA.EVC_REA
                        */


                     )
                  ELSE 
                     (
                        /* 
                        *   SSMA error messages:
                        *   O2SS0083: Identifier TA.EVC_REA cannot be converted because it was not resolved.

                        SELECT HR_CODEDTL$2.CODE_NAME
                        FROM HRP.HR_CODEDTL  AS HR_CODEDTL$2
                        WHERE HR_CODEDTL$2.CODE_TYPE = 'HRA08' AND HR_CODEDTL$2.CODE_NO = TA.EVC_REA
                        */


                     )
               END AS EVCREA, 
               TA.VAC_DAYS, 
               TA.VAC_HRS, 
               TA.REMARK, 
               
                  (
                     SELECT PUS_CODEBAS.CODE_NAME
                     FROM HRP.PUS_CODEBAS
                     WHERE 
                        PUS_CODEBAS.CODE_TYPE = 'IT01' AND 
                        PUS_CODEBAS.CODE_NO = TA.EMP_NO AND 
                        CONVERT(datetime2, PUS_CODEBAS.CODE_DTL, 111) >= ssma_oracle.trunc_date(sysdatetime())
                  ) AS REMARK2
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
                     (
                        SELECT PUS_CODEBAS$2.CODE_NO
                        FROM HRP.PUS_CODEBAS  AS PUS_CODEBAS$2
                        WHERE PUS_CODEBAS$2.CODE_TYPE = 'IT01' AND CONVERT(datetime2, PUS_CODEBAS$2.CODE_DTL, 111) >= ssma_oracle.trunc_date(sysdatetime())
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
                           'B0' AS VAC_TYPE, 
                           'B0' AS VAC_RUL, 
                           T1$2.STATUS, 
                           ssma_oracle.to_char_date(T1$2.START_DATE, 'yyyy-mm-dd') AS SD, 
                           T1$2.START_TIME AS ST, 
                           ssma_oracle.to_char_date(T1$2.END_DATE, 'yyyy-mm-dd') AS ED, 
                           T1$2.END_TIME AS ET, 
                           T1$2.SUP_REA AS EVC_REA, 
                           0 AS VAC_DAYS, 
                           T1$2.SUP_HRS AS VAC_HRS, 
                           T1$2.REMARK, 
                           T1$2.ABROAD
                        FROM HRP.HRA_SUPMST  AS T1$2
                        WHERE T1$2.STATUS IN ( 'Y', 'U' )
                     )  AS fci$2
                  WHERE 
                     fci$2.SD <= ssma_oracle.to_char_date(sysdatetime(), 'yyyy-mm-dd') AND 
                     fci$2.ED >= ssma_oracle.to_char_date(sysdatetime(), 'yyyy-mm-dd') AND 
                     fci$2.EMP_NO IN 
                     (
                        SELECT PUS_CODEBAS$3.CODE_NO
                        FROM HRP.PUS_CODEBAS  AS PUS_CODEBAS$3
                        WHERE PUS_CODEBAS$3.CODE_TYPE = 'IT01' AND CONVERT(datetime2, PUS_CODEBAS$3.CODE_DTL, 111) >= ssma_oracle.trunc_date(sysdatetime())
                     )
               )  AS TA, HRP.HRE_EMPBAS  AS TB
            WHERE TA.EMP_NO = TB.EMP_NO
            */


            ORDER BY 
               TA.SD, 
               TA.ED, 
               TA.ST, 
               TA.ET
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
                  @PRM2

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

                  SET @SMESSAGE = ISNULL(@SMESSAGE, '') + '<TD>天數</td><TD>時數</td><TD>請假理由</td><TD>其他原因</td><TD>備註</td></tr>'

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
                     ISNULL(@PRM2, '')
                      + 
                     '</td></tr>'

               END
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
                     ISNULL(@PRM2, '')
                      + 
                     '</td></tr>'

               END

         END

      CLOSE CURSOR1

      DEALLOCATE CURSOR1

      DECLARE
          CURSOR3 CURSOR LOCAL FOR 
            SELECT 
               A.CODE_NO, 
               B.CH_NAME, 
               
                  (
                     SELECT HRE_ORGBAS.CH_NAME
                     FROM HRP.HRE_ORGBAS
                     WHERE HRE_ORGBAS.DEPT_NO = B.DEPT_NO
                  ) AS DEPTNAME, 
               
                  (
                     SELECT HRE_POSMST.CH_NAME
                     FROM HRP.HRE_POSMST
                     WHERE HRE_POSMST.POS_NO = B.POS_NO
                  ) AS POSNAME, 
               '人員尚未申請假卡或補休' AS REMARK, 
               A.CODE_NAME AS REMARK2
            FROM HRP.PUS_CODEBAS  AS A, HRP.HRE_EMPBAS  AS B
            WHERE 
               A.CODE_NO = B.EMP_NO AND 
               A.CODE_TYPE = 'IT01' AND 
               0 = 
               (
                  SELECT count_big(*) AS expr
                  FROM HRP.HRA_EVCREC
                  WHERE 
                     HRA_EVCREC.START_DATE <= ssma_oracle.trunc_date(sysdatetime()) AND 
                     HRA_EVCREC.END_DATE >= ssma_oracle.trunc_date(sysdatetime()) AND 
                     HRA_EVCREC.EMP_NO = A.CODE_NO AND 
                     ssma_oracle.to_char_date(sysdatetime(), 'yyyy-mm-dd') <= A.CODE_DTL
               ) AND 
               0 = 
               (
                  SELECT count_big(*) AS expr
                  FROM HRP.HRA_SUPMST
                  WHERE 
                     HRA_SUPMST.START_DATE <= ssma_oracle.trunc_date(sysdatetime()) AND 
                     HRA_SUPMST.END_DATE >= ssma_oracle.trunc_date(sysdatetime()) AND 
                     HRA_SUPMST.EMP_NO = A.CODE_NO AND 
                     ssma_oracle.to_char_date(sysdatetime(), 'yyyy-mm-dd') <= A.CODE_DTL
               ) AND 
               ssma_oracle.to_char_date(sysdatetime(), 'yyyy-mm-dd') <= A.CODE_DTL
            ORDER BY A.CODE_NAME

      OPEN CURSOR3

      WHILE 1 = 1
      
         BEGIN

            FETCH CURSOR3
                INTO 
                  @PEMPNO, 
                  @PCHNAME, 
                  @PDEPTNAME, 
                  @PPOSNAME, 
                  @PRM, 
                  @PRM2

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

                  SET @SMESSAGE = ISNULL(@SMESSAGE, '') + '<TD>天數</td><TD>時數</td><TD>請假理由</td><TD>其他原因</td><TD>備註</td></tr>'

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
                     '</td><TD colspan="10">'
                      + 
                     ISNULL(@PRM, '')
                      + 
                     '</td><TD>'
                      + 
                     ISNULL(@PRM2, '')
                      + 
                     '</td></tr>'

               END
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
                     '</td><TD colspan="10">'
                      + 
                     ISNULL(@PRM, '')
                      + 
                     '</td><TD>'
                      + 
                     ISNULL(@PRM2, '')
                      + 
                     '</td></tr>'

               END

         END

      CLOSE CURSOR3

      DEALLOCATE CURSOR3

      DECLARE
          CURSOR4 CURSOR LOCAL FOR 
            SELECT 
               A.CODE_NO, 
               B.CH_NAME, 
               
                  (
                     SELECT HRE_ORGBAS.CH_NAME
                     FROM HRP.HRE_ORGBAS
                     WHERE HRE_ORGBAS.DEPT_NO = B.DEPT_NO
                  ) AS DEPTNAME, 
               
                  (
                     SELECT HRE_POSMST.CH_NAME
                     FROM HRP.HRE_POSMST
                     WHERE HRE_POSMST.POS_NO = B.POS_NO
                  ) AS POSNAME, 
               A.CODE_NAME
            FROM HRP.PUS_CODEBAS  AS A, HRP.HRE_EMPBAS  AS B
            WHERE 
               A.CODE_NO = B.EMP_NO AND 
               A.CODE_TYPE = 'IT01' AND 
               ssma_oracle.to_char_date(sysdatetime(), 'yyyy-mm-dd') > A.CODE_DTL AND 
               B.DISABLED = 'N'
            ORDER BY A.CODE_DTL DESC

      OPEN CURSOR4

      WHILE 1 = 1
      
         BEGIN

            FETCH CURSOR4
                INTO 
                  @PEMPNO, 
                  @PCHNAME, 
                  @PDEPTNAME, 
                  @PPOSNAME, 
                  @PRM

            /*
            *   SSMA warning messages:
            *   O2SS0113: The value of @@FETCH_STATUS might be changed by previous FETCH operations on other cursors, if the cursors are used simultaneously.
            */

            IF @@FETCH_STATUS <> 0
               BREAK

            IF @SMESSAGE2 IS NULL OR @SMESSAGE2 = ''
               SET @SMESSAGE2 = 
                  '<table border="1" width="50%"><TR><TD>工號</td><TD>姓名</td><TD>部門名稱</td><TD>職稱</td><TD>備註</td></tr>'
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
                  '</td><TD>'
                   + 
                  ISNULL(@PPOSNAME, '')
                   + 
                  '</td><TD>'
                   + 
                  ISNULL(@PRM, '')
                   + 
                  '</td></tr>'
            ELSE 
               SET @SMESSAGE2 = 
                  ISNULL(@SMESSAGE2, '')
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
                  '</td><TD>'
                   + 
                  ISNULL(@PPOSNAME, '')
                   + 
                  '</td><TD>'
                   + 
                  ISNULL(@PRM, '')
                   + 
                  '</td></tr>'

         END

      CLOSE CURSOR4

      DEALLOCATE CURSOR4

      SET @STITLE = '今日資訊部COVID-19人員請假彙總表(' + ISNULL(ssma_oracle.to_char_date(sysdatetime(), 'yyyy-mm-dd'), '') + ')'

      BEGIN

         BEGIN TRY
            SELECT @ICNTTIME = count_big(*)
            FROM HRP.PUS_CODEBAS
            WHERE PUS_CODEBAS.CODE_TYPE = 'IT01' AND PUS_CODEBAS.CODE_NO IN 
               (
                  SELECT HRE_EMPBAS.EMP_NO
                  FROM HRP.HRE_EMPBAS
                  WHERE HRE_EMPBAS.DISABLED = 'N'
               )
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
               SET @ICNTTIME = 0
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

      BEGIN

         BEGIN TRY
            SELECT @ICNTNOW = count_big(*)
            FROM HRP.PUS_CODEBAS
            WHERE 
               PUS_CODEBAS.CODE_TYPE = 'IT01' AND 
               PUS_CODEBAS.CODE_NO IN 
               (
                  SELECT HRE_EMPBAS.EMP_NO
                  FROM HRP.HRE_EMPBAS
                  WHERE HRE_EMPBAS.DISABLED = 'N'
               ) AND 
               CONVERT(datetime2, PUS_CODEBAS.CODE_DTL, 111) >= ssma_oracle.trunc_date(sysdatetime())
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
               SET @ICNTNOW = 0
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

      BEGIN

         BEGIN TRY
            SELECT @ICNTCOVID = count_big(*)
            FROM 
               (
                  SELECT DISTINCT PUS_CODEBAS.CODE_NO
                  FROM HRP.PUS_CODEBAS
                  WHERE 
                     PUS_CODEBAS.CODE_TYPE = 'IT01' AND 
                     PUS_CODEBAS.CODE_NO IN 
                     (
                        SELECT HRE_EMPBAS.EMP_NO
                        FROM HRP.HRE_EMPBAS
                        WHERE HRE_EMPBAS.DISABLED = 'N'
                     ) AND 
                     PUS_CODEBAS.CODE_VALUE = 1
               )  AS fci
         END TRY

         BEGIN CATCH

            DECLARE
               @errornumber$3 int

            SET @errornumber$3 = ERROR_NUMBER()

            DECLARE
               @errormessage$3 nvarchar(4000)

            SET @errormessage$3 = ERROR_MESSAGE()

            DECLARE
               @exceptionidentifier$3 nvarchar(4000)

            SELECT @exceptionidentifier$3 = ssma_oracle.db_error_get_oracle_exception_id(@errormessage$3, @errornumber$3)

            IF (@exceptionidentifier$3 LIKE N'ORA-00100%')
               SET @ICNTCOVID = 0
            ELSE 
               BEGIN
                  IF (@exceptionidentifier$3 IS NOT NULL)
                     BEGIN
                        IF @errornumber$3 = 59998
                           RAISERROR(59998, 16, 1, @exceptionidentifier$3)
                        ELSE 
                           RAISERROR(59999, 16, 1, @exceptionidentifier$3)
                     END
                  ELSE 
                     BEGIN
                        EXECUTE ssma_oracle.ssma_rethrowerror
                     END
               END

         END CATCH

      END

      BEGIN

         BEGIN TRY
            SELECT @ICNTPERSON = count_big(*)
            FROM HRP.PUS_CODEDTL
            WHERE PUS_CODEDTL.CODE_TYPE = 'IT01' AND PUS_CODEDTL.CODE_NO IN 
               (
                  SELECT HRE_EMPBAS.EMP_NO
                  FROM HRP.HRE_EMPBAS
                  WHERE HRE_EMPBAS.DISABLED = 'N'
               )
         END TRY

         BEGIN CATCH

            DECLARE
               @errornumber$4 int

            SET @errornumber$4 = ERROR_NUMBER()

            DECLARE
               @errormessage$4 nvarchar(4000)

            SET @errormessage$4 = ERROR_MESSAGE()

            DECLARE
               @exceptionidentifier$4 nvarchar(4000)

            SELECT @exceptionidentifier$4 = ssma_oracle.db_error_get_oracle_exception_id(@errormessage$4, @errornumber$4)

            IF (@exceptionidentifier$4 LIKE N'ORA-00100%')
               SET @ICNTPERSON = 0
            ELSE 
               BEGIN
                  IF (@exceptionidentifier$4 IS NOT NULL)
                     BEGIN
                        IF @errornumber$4 = 59998
                           RAISERROR(59998, 16, 1, @exceptionidentifier$4)
                        ELSE 
                           RAISERROR(59999, 16, 1, @exceptionidentifier$4)
                     END
                  ELSE 
                     BEGIN
                        EXECUTE ssma_oracle.ssma_rethrowerror
                     END
               END

         END CATCH

      END

      BEGIN

         BEGIN TRY
            SELECT @ICNTALL = count_big(*)
            FROM HRP.HRE_EMPBAS
            WHERE HRE_EMPBAS.DEPT_NO IN ( 
               '5500', 
               '5510', 
               '5511', 
               '5512', 
               '5513', 
               '5520', 
               '5521', 
               '5522', 
               '5530', 
               '5531', 
               '5532', 
               'CA5000', 
               'CA5100', 
               'CA5110', 
               'CA5120', 
               'CA5200', 
               'CA5210', 
               'CA5220', 
               'CA5300', 
               'CA5310', 
               'CA5320', 
               'CA5330', 
               'DA5000', 
               'DA5010' ) AND HRE_EMPBAS.DISABLED = 'N'
         END TRY

         BEGIN CATCH

            DECLARE
               @errornumber$5 int

            SET @errornumber$5 = ERROR_NUMBER()

            DECLARE
               @errormessage$5 nvarchar(4000)

            SET @errormessage$5 = ERROR_MESSAGE()

            DECLARE
               @exceptionidentifier$5 nvarchar(4000)

            SELECT @exceptionidentifier$5 = ssma_oracle.db_error_get_oracle_exception_id(@errormessage$5, @errornumber$5)

            IF (@exceptionidentifier$5 LIKE N'ORA-00100%')
               SET @ICNTALL = 0
            ELSE 
               BEGIN
                  IF (@exceptionidentifier$5 IS NOT NULL)
                     BEGIN
                        IF @errornumber$5 = 59998
                           RAISERROR(59998, 16, 1, @exceptionidentifier$5)
                        ELSE 
                           RAISERROR(59999, 16, 1, @exceptionidentifier$5)
                     END
                  ELSE 
                     BEGIN
                        EXECUTE ssma_oracle.ssma_rethrowerror
                     END
               END

         END CATCH

      END

      SET @IPERCENT = ssma_oracle.round_numeric_0((@ICNTPERSON / @ICNTALL) * 100)

      SET @IPERCENTC = ssma_oracle.round_numeric_0((@ICNTCOVID / @ICNTALL) * 100)

      SET @SMESSAGE3 = 
         '資訊部今日隔離中人數共'
          + 
         ISNULL(CAST(@ICNTNOW AS nvarchar(max)), '')
          + 
         '人，累計共'
          + 
         ISNULL(CAST(@ICNTCOVID AS nvarchar(max)), '')
          + 
         '人確診，確診率：'
          + 
         ISNULL(CAST(@IPERCENTC AS nvarchar(max)), '')
          + 
         '%。<br>'
          + 
         '累計居家隔離共'
          + 
         ISNULL(CAST(@ICNTPERSON AS nvarchar(max)), '')
          + 
         '人('
          + 
         ISNULL(CAST(@ICNTTIME AS nvarchar(max)), '')
          + 
         '人次)，居隔率：'
          + 
         ISNULL(CAST(@IPERCENT AS nvarchar(max)), '')
          + 
         '%。'

      
      /*
      *   sMessage3 := '資訊部目前居家隔離總計'||iCntTime||'人次，共'||iCntPerson||
      *       '人隔離(含隔離中'||iCntNow||'人)，居隔率：'||iPercent||'%；'||
      *       iCntCovid||'人確診，確診率：'||iPercentC||'%。';
      */
      IF (@SMESSAGE IS NOT NULL AND @SMESSAGE != '')
         BEGIN

            SET @SMESSAGE = ISNULL(@SMESSAGE3, '') + '<br><br>今日隔離人員：<br>' + ISNULL(@SMESSAGE, '') + '</table>'

            IF (@SMESSAGE2 IS NOT NULL AND @SMESSAGE2 != '')
               SET @SMESSAGE = ISNULL(@SMESSAGE, '') + '<br><br>已解除隔離人員：<br>' + ISNULL(@SMESSAGE2, '') + '</table>'

            DECLARE
                CURSOR2 CURSOR LOCAL FOR 
                  SELECT 'ed100009@edah.org.tw'
                   UNION ALL
                  SELECT 'ed100014@edah.org.tw'
                   UNION ALL
                  SELECT 'ed100037@edah.org.tw'
                   UNION ALL
                  SELECT 'ed104857@edah.org.tw'
                   UNION ALL
                  SELECT 'ed100084@edah.org.tw'
                   UNION ALL
                  SELECT 'ed100052@edah.org.tw'
                   UNION ALL
                  SELECT 'ed107403@edah.org.tw'
                   UNION ALL
                  SELECT 'ed108024@edah.org.tw'
                   UNION ALL
                  SELECT 'ed108154@edah.org.tw'
                   UNION ALL
                  SELECT 'ed108482@edah.org.tw'

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

            SET @SMESSAGE = ISNULL(@SMESSAGE3, '') + '<br><br>截至上午07:00，今日(' + ISNULL(ssma_oracle.to_char_date(sysdatetime(), 'yyyy-mm-dd'), '') + ')'

            SET @SMESSAGE = ISNULL(@SMESSAGE, '') + '資訊部無COVID-19居隔中人員通報。'

            IF (@SMESSAGE2 IS NOT NULL AND @SMESSAGE2 != '')
               SET @SMESSAGE = ISNULL(@SMESSAGE, '') + '<br><br>已解除隔離人員：<br>' + ISNULL(@SMESSAGE2, '') + '</table>'

            DECLARE
                CURSOR2 CURSOR LOCAL FOR 
                  SELECT 'ed100009@edah.org.tw'
                   UNION ALL
                  SELECT 'ed100014@edah.org.tw'
                   UNION ALL
                  SELECT 'ed100037@edah.org.tw'
                   UNION ALL
                  SELECT 'ed104857@edah.org.tw'
                   UNION ALL
                  SELECT 'ed100084@edah.org.tw'
                   UNION ALL
                  SELECT 'ed100052@edah.org.tw'
                   UNION ALL
                  SELECT 'ed107403@edah.org.tw'
                   UNION ALL
                  SELECT 'ed108024@edah.org.tw'
                   UNION ALL
                  SELECT 'ed108154@edah.org.tw'
                   UNION ALL
                  SELECT 'ed108482@edah.org.tw'

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
        N'MS_SSMA_SOURCE', N'HRP.EHRPHRAFUNC_PKG.HRASEND_MAIL_IT',
        N'SCHEMA', N'hrp',
        N'PROCEDURE', N'EHRPHRAFUNC_PKG$HRASEND_MAIL_IT'
END TRY
BEGIN CATCH
    IF (@@TRANCOUNT > 0) ROLLBACK
    PRINT ERROR_MESSAGE()
END CATCH
GO
