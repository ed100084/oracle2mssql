
USE MIS
GO
 IF NOT EXISTS(SELECT * FROM sys.schemas WHERE [name] = N'hrp')      
     EXEC (N'CREATE SCHEMA hrp')                                   
 GO                                                               

USE MIS
GO
IF  EXISTS (SELECT * FROM sys.objects so JOIN sys.schemas sc ON so.schema_id = sc.schema_id WHERE so.name = N'EHRPHRAFUNC_PKG$HRASEND_MAIL_EF'  AND sc.name=N'hrp'  AND type in (N'P',N'PC'))
 DROP PROCEDURE [hrp].[EHRPHRAFUNC_PKG$HRASEND_MAIL_EF]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE HRP.EHRPHRAFUNC_PKG$HRASEND_MAIL_EF  
AS 
   BEGIN

      EXECUTE ssma_oracle.db_check_init_package 'HRP', 'EHRPHRAFUNC_PKG'

      DECLARE
         @PEMPNO varchar(100), 
         @PCHNAME varchar(200), 
         @PDEPTNAME varchar(100), 
         @PPOSNAME varchar(100), 
         @PVACNAME varchar(100), 
         @PSTATUSNAME varchar(100), 
         @PSD varchar(100), 
         @PST varchar(104), 
         @PED varchar(100), 
         @PET varchar(40), 
         @PEVCREA varchar(100), 
         @PVACDAYS numeric(3), 
         @PVACHRS numeric(4, 1), 
         @PRM varchar(300), 
         @STITLE varchar(100), 
         @SEEMAIL varchar(120), 
         @SMESSAGE varchar(max), 
         @STITLER varchar(100), 
         @SMESSAGER varchar(max), 
         @N_TOTAL_1 numeric(3), 
         @N_TOTA3_1 numeric(3), 
         @N_RANG numeric(3), 
         @N_START numeric(3), 
         @N_END numeric(3)

      SET @SMESSAGE = NULL

      SET @SMESSAGER = NULL

      /* 
      *   SSMA error messages:
      *   O2SS0276: Column 'HRP.HRA_EVCREC.DEPT_NO' is invalid in ORDER BY clause.
      *   O2SS0276: Column 'HRP.HRA_EVCREC.EMP_NO' is invalid in ORDER BY clause.

      DECLARE
          CURTOTAL_1 CURSOR LOCAL FOR 
            SELECT count_big(*)
            FROM 
               (
                  SELECT 
                     HRA_EVCREC.ORG_BY, 
                     HRA_EVCREC.EMP_NO, 
                     HRA_EVCREC.DEPT_NO, 
                     HRA_EVCREC.VAC_TYPE, 
                     HRA_EVCREC.VAC_RUL, 
                     HRA_EVCREC.STATUS, 
                     ssma_oracle.to_char_date(HRA_EVCREC.START_DATE, 'yyyy-mm-dd') AS SD, 
                     HRA_EVCREC.START_TIME AS ST, 
                     ssma_oracle.to_char_date(HRA_EVCREC.END_DATE, 'yyyy-mm-dd') AS ED, 
                     HRA_EVCREC.END_TIME AS ET, 
                     HRA_EVCREC.EVC_REA, 
                     HRA_EVCREC.VAC_DAYS, 
                     HRA_EVCREC.VAC_HRS, 
                     HRA_EVCREC.REMARK
                  FROM HRP.HRA_EVCREC
                  WHERE 
                     HRA_EVCREC.STATUS IN ( 'Y', 'U' ) AND 
                     HRA_EVCREC.START_DATE <= ssma_oracle.trunc_date(sysdatetime()) AND 
                     HRA_EVCREC.END_DATE >= ssma_oracle.trunc_date(sysdatetime())
                   UNION ALL
                  SELECT 
                     HRA_OFFREC.ORG_BY, 
                     HRA_OFFREC.EMP_NO, 
                     HRA_OFFREC.DEPT_NO, 
                     'O1' AS VAC_TYPE, 
                     'O1' AS VAC_RUL, 
                     HRA_OFFREC.STATUS, 
                     ssma_oracle.to_char_date(HRA_OFFREC.START_DATE, 'yyyy-mm-dd') AS SD, 
                     HRA_OFFREC.START_TIME AS ST, 
                     ssma_oracle.to_char_date(HRA_OFFREC.END_DATE, 'yyyy-mm-dd') AS ED, 
                     HRA_OFFREC.END_TIME AS ET, 
                     HRA_OFFREC.OTM_REA AS EVC_REA, 
                     0 AS VAC_DAYS, 
                     HRA_OFFREC.OTM_HRS AS VAC_HRS, 
                     HRA_OFFREC.REMARK
                  FROM HRP.HRA_OFFREC
                  WHERE 
                     HRA_OFFREC.ITEM_TYPE = 'O' AND 
                     HRA_OFFREC.STATUS IN ( 'Y', 'U' ) AND 
                     HRA_OFFREC.START_DATE <= ssma_oracle.trunc_date(sysdatetime()) AND 
                     HRA_OFFREC.END_DATE >= ssma_oracle.trunc_date(sysdatetime())
                   UNION ALL
                  SELECT 
                     HRA_SUPMST.ORG_BY, 
                     HRA_SUPMST.EMP_NO, 
                     HRA_SUPMST.DEPT_NO, 
                     'B0' AS VAC_TYPE, 
                     'B0' AS VAC_RUL, 
                     HRA_SUPMST.STATUS, 
                     ssma_oracle.to_char_date(HRA_SUPMST.START_DATE, 'yyyy-mm-dd') AS SD, 
                     HRA_SUPMST.START_TIME AS ST, 
                     ssma_oracle.to_char_date(HRA_SUPMST.END_DATE, 'yyyy-mm-dd') AS ED, 
                     HRA_SUPMST.END_TIME AS ET, 
                     HRA_SUPMST.SUP_REA AS EVC_REA, 
                     0 AS VAC_DAYS, 
                     HRA_SUPMST.SUP_HRS AS VAC_HRS, 
                     HRA_SUPMST.REMARK
                  FROM HRP.HRA_SUPMST
                  WHERE 
                     HRA_SUPMST.STATUS IN ( 'Y', 'U' ) AND 
                     HRA_SUPMST.START_DATE <= ssma_oracle.trunc_date(sysdatetime()) AND 
                     HRA_SUPMST.END_DATE >= ssma_oracle.trunc_date(sysdatetime())
               )  AS TA, HRP.HRE_EMPBAS  AS TB
            WHERE TA.EMP_NO = TB.EMP_NO AND TB.ORGAN_TYPE = 'EF'
            ORDER BY TA.DEPT_NO, TA.EMP_NO
      */



      OPEN CURTOTAL_1

      WHILE 1 = 1
      
         BEGIN

            FETCH CURTOTAL_1
                INTO @N_TOTAL_1

            /*
            *   SSMA warning messages:
            *   O2SS0113: The value of @@FETCH_STATUS might be changed by previous FETCH operations on other cursors, if the cursors are used simultaneously.
            */

            IF @@FETCH_STATUS <> 0
               BREAK

            SET @N_RANG = ceiling(@N_TOTAL_1 / 12)

            DECLARE
               @I int

            SET @I = 1

            DECLARE
               @loop$bound int

            SET @loop$bound = @N_RANG

            WHILE @I <= @loop$bound
            
               BEGIN

                  IF @I = 1
                     IF @N_TOTAL_1 <= 12
                        BEGIN

                           SET @N_START = 1

                           SET @N_END = @N_TOTAL_1

                        END
                     ELSE 
                        BEGIN

                           SET @N_START = 1

                           SET @N_END = 12

                        END
                  ELSE 
                     BEGIN

                        SET @N_START = @N_END + 1

                        SET @N_END = @N_END + 12

                     END

                  SET @SMESSAGE = NULL

                  DECLARE
                     @CURSOR_PARAM_CURSOR1_N_START varchar(max), 
                     @CURSOR_PARAM_CURSOR1_N_END varchar(max)

                  SET @CURSOR_PARAM_CURSOR1_N_START = @N_START

                  SET @CURSOR_PARAM_CURSOR1_N_END = @N_END

                  DECLARE
                      CURSOR1 CURSOR LOCAL FOR 
                        SELECT 
                           fci.EMP_NO, 
                           fci.CH_NAME, 
                           fci.DEPTNAME, 
                           fci.POSNAME, 
                           fci.VACNAME, 
                           fci.STATUSNAME, 
                           fci.ST, 
                           fci.SD, 
                           fci.ED, 
                           fci.ET, 
                           fci.EVCREA, 
                           fci.VAC_DAYS, 
                           fci.VAC_HRS, 
                           fci.REMARK
                        FROM 
                           (
                              SELECT TOP 9223372036854775807 
                                 row_number() OVER(
                                    ORDER BY TA.DEPT_NO, TA.EMP_NO) AS NUM1, 
                                 TA.EMP_NO, 
                                 TB.CH_NAME, 
                                 
                                    (
                                       SELECT HRE_ORGBAS.CH_NAME
                                       FROM HRP.HRE_ORGBAS
                                       WHERE HRE_ORGBAS.DEPT_NO = TA.DEPT_NO
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
                                          SELECT HR_CODEDTL.CODE_NAME
                                          FROM HRP.HR_CODEDTL
                                          WHERE HR_CODEDTL.CODE_TYPE = 'HRA22' AND HR_CODEDTL.CODE_NO = TA.EVC_REA
                                       )
                                    WHEN 'O1' THEN 
                                       (
                                          SELECT HR_CODEDTL$2.CODE_NAME
                                          FROM HRP.HR_CODEDTL  AS HR_CODEDTL$2
                                          WHERE HR_CODEDTL$2.CODE_TYPE = 'HRA51' AND HR_CODEDTL$2.CODE_NO = TA.EVC_REA
                                       )
                                    ELSE 
                                       (
                                          SELECT HR_CODEDTL$3.CODE_NAME
                                          FROM HRP.HR_CODEDTL  AS HR_CODEDTL$3
                                          WHERE HR_CODEDTL$3.CODE_TYPE = 'HRA08' AND HR_CODEDTL$3.CODE_NO = TA.EVC_REA
                                       )
                                 END AS EVCREA, 
                                 TA.VAC_DAYS, 
                                 TA.VAC_HRS, 
                                 TA.REMARK
                              FROM 
                                 (
                                    SELECT 
                                       HRA_EVCREC.ORG_BY, 
                                       HRA_EVCREC.EMP_NO, 
                                       HRA_EVCREC.DEPT_NO, 
                                       HRA_EVCREC.VAC_TYPE, 
                                       HRA_EVCREC.VAC_RUL, 
                                       HRA_EVCREC.STATUS, 
                                       ssma_oracle.to_char_date(HRA_EVCREC.START_DATE, 'yyyy-mm-dd') AS SD, 
                                       HRA_EVCREC.START_TIME AS ST, 
                                       ssma_oracle.to_char_date(HRA_EVCREC.END_DATE, 'yyyy-mm-dd') AS ED, 
                                       HRA_EVCREC.END_TIME AS ET, 
                                       HRA_EVCREC.EVC_REA, 
                                       HRA_EVCREC.VAC_DAYS, 
                                       HRA_EVCREC.VAC_HRS, 
                                       HRA_EVCREC.REMARK
                                    FROM HRP.HRA_EVCREC
                                    WHERE 
                                       HRA_EVCREC.STATUS IN ( 'Y', 'U' ) AND 
                                       HRA_EVCREC.START_DATE <= ssma_oracle.trunc_date(sysdatetime()) AND 
                                       HRA_EVCREC.END_DATE >= ssma_oracle.trunc_date(sysdatetime())
                                     UNION ALL
                                    SELECT 
                                       HRA_OFFREC.ORG_BY, 
                                       HRA_OFFREC.EMP_NO, 
                                       HRA_OFFREC.DEPT_NO, 
                                       'O1' AS VAC_TYPE, 
                                       'O1' AS VAC_RUL, 
                                       HRA_OFFREC.STATUS, 
                                       ssma_oracle.to_char_date(HRA_OFFREC.START_DATE, 'yyyy-mm-dd') AS SD, 
                                       HRA_OFFREC.START_TIME AS ST, 
                                       ssma_oracle.to_char_date(HRA_OFFREC.END_DATE, 'yyyy-mm-dd') AS ED, 
                                       HRA_OFFREC.END_TIME AS ET, 
                                       HRA_OFFREC.OTM_REA AS EVC_REA, 
                                       0 AS VAC_DAYS, 
                                       HRA_OFFREC.OTM_HRS AS VAC_HRS, 
                                       HRA_OFFREC.REMARK
                                    FROM HRP.HRA_OFFREC
                                    WHERE 
                                       HRA_OFFREC.ITEM_TYPE = 'O' AND 
                                       HRA_OFFREC.STATUS IN ( 'Y', 'U' ) AND 
                                       HRA_OFFREC.START_DATE <= ssma_oracle.trunc_date(sysdatetime()) AND 
                                       HRA_OFFREC.END_DATE >= ssma_oracle.trunc_date(sysdatetime())
                                     UNION ALL
                                    SELECT 
                                       HRA_SUPMST.ORG_BY, 
                                       HRA_SUPMST.EMP_NO, 
                                       HRA_SUPMST.DEPT_NO, 
                                       'B0' AS VAC_TYPE, 
                                       'B0' AS VAC_RUL, 
                                       HRA_SUPMST.STATUS, 
                                       ssma_oracle.to_char_date(HRA_SUPMST.START_DATE, 'yyyy-mm-dd') AS SD, 
                                       HRA_SUPMST.START_TIME AS ST, 
                                       ssma_oracle.to_char_date(HRA_SUPMST.END_DATE, 'yyyy-mm-dd') AS ED, 
                                       HRA_SUPMST.END_TIME AS ET, 
                                       HRA_SUPMST.SUP_REA AS EVC_REA, 
                                       0 AS VAC_DAYS, 
                                       HRA_SUPMST.SUP_HRS AS VAC_HRS, 
                                       HRA_SUPMST.REMARK
                                    FROM HRP.HRA_SUPMST
                                    WHERE 
                                       HRA_SUPMST.STATUS IN ( 'Y', 'U' ) AND 
                                       HRA_SUPMST.START_DATE <= ssma_oracle.trunc_date(sysdatetime()) AND 
                                       HRA_SUPMST.END_DATE >= ssma_oracle.trunc_date(sysdatetime())
                                 )  AS TA, HRP.HRE_EMPBAS  AS TB
                              WHERE TA.EMP_NO = TB.EMP_NO AND TB.ORGAN_TYPE = 'EF'
                              ORDER BY TA.DEPT_NO, TA.EMP_NO
                           )  AS fci
                        WHERE fci.NUM1 > @CURSOR_PARAM_CURSOR1_N_START AND fci.NUM1 <= @CURSOR_PARAM_CURSOR1_N_END

                  OPEN CURSOR1

                  SET @PEMPNO = NULL

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
                              @PRM

                        /*
                        *   SSMA warning messages:
                        *   O2SS0113: The value of @@FETCH_STATUS might be changed by previous FETCH operations on other cursors, if the cursors are used simultaneously.
                        */

                        IF @@FETCH_STATUS <> 0
                           BREAK

                        IF @SMESSAGE IS NULL OR @SMESSAGE = ''
                           SET @SMESSAGE = '<table border="1" width="100%">' + '<tr><th>工號</th><th>姓名</th><th>部門名稱</th><th>職稱</th><th>假別</th>' + '<th>狀態</th><th>開始日期</th><th>開始時間</th><th>結束日期</th><th>結束時間</th>' + '<th>天數</th><th>時數</th><th>請假理由</th><th>其他原因</th></tr>'

                        IF @PEMPNO IS NOT NULL AND @PEMPNO != ''
                           SET @SMESSAGE = 
                              ISNULL(@SMESSAGE, '')
                               + 
                              '<tr><td>'
                               + 
                              ISNULL(@PEMPNO, '')
                               + 
                              '</td><td>'
                               + 
                              ISNULL(@PCHNAME, '')
                               + 
                              '</td><td>'
                               + 
                              ISNULL(@PDEPTNAME, '')
                               + 
                              '</td>'
                               + 
                              '<td>'
                               + 
                              ISNULL(@PPOSNAME, '')
                               + 
                              '</td><td>'
                               + 
                              ISNULL(@PVACNAME, '')
                               + 
                              '</td><td>'
                               + 
                              ISNULL(@PSTATUSNAME, '')
                               + 
                              '</td>'
                               + 
                              '<td>'
                               + 
                              ISNULL(@PSD, '')
                               + 
                              '</td><td>'
                               + 
                              ISNULL(@PST, '')
                               + 
                              '</td><td>'
                               + 
                              ISNULL(@PED, '')
                               + 
                              '</td><td>'
                               + 
                              ISNULL(@PET, '')
                               + 
                              '</td>'
                               + 
                              '<td>'
                               + 
                              ISNULL(CAST(@PVACDAYS AS nvarchar(max)), '')
                               + 
                              '</td><td>'
                               + 
                              ISNULL(CAST(@PVACHRS AS nvarchar(max)), '')
                               + 
                              '</td><td>'
                               + 
                              ISNULL(@PEVCREA, '')
                               + 
                              '</td><td>'
                               + 
                              ISNULL(@PRM, '')
                               + 
                              '</td></tr>'
                        ELSE 
                           SET @SMESSAGE = ISNULL(@SMESSAGE, '') + '<tr><td colspan="14">無人員請假</td></tr>'

                     END

                  CLOSE CURSOR1

                  DEALLOCATE CURSOR1

                  SET @STITLE = '今日（非醫師）請假通知_大昌醫院(' + ISNULL(ssma_oracle.to_char_date(sysdatetime(), 'yyyy-mm-dd'), '') + ')'

                  IF @SMESSAGE IS NULL OR @SMESSAGE = ''
                     SET @SMESSAGE = '<table border="1" width="100%">' + '<tr><th>工號</th><th>姓名</th><th>部門名稱</th><th>職稱</th><th>假別</th>' + '<th>狀態</th><th>開始日期</th><th>開始時間</th><th>結束日期</th><th>結束時間</th>' + '<th>天數</th><th>時數</th><th>請假理由</th><th>其他原因</th></tr>' + '<tr><td colspan="14">無人員請假</td></tr>'

                  IF (@SMESSAGE IS NOT NULL AND @SMESSAGE != '')
                     BEGIN

                        SET @SMESSAGE = ISNULL(@SMESSAGE, '') + '</table>'

                        DECLARE
                            CURSOR2 CURSOR LOCAL FOR 
                              SELECT HR_CODEDTL.CODE_NAME
                              FROM HRP.HR_CODEDTL
                              WHERE 
                                 HR_CODEDTL.CODE_TYPE = 'HRA99' AND 
                                 HR_CODEDTL.CODE_NO LIKE 'D%' AND 
                                 HR_CODEDTL.DISABLED = 'N'

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

                  SET @I = @I + 1

               END

         END

      CLOSE CURTOTAL_1

      DEALLOCATE CURTOTAL_1

      /* 
      *   SSMA error messages:
      *   O2SS0276: Column 'HRP.HRA_DEVCREC.DEPT_NO' is invalid in ORDER BY clause.
      *   O2SS0276: Column 'HRP.HRE_EMPBAS.POS_NO' is invalid in ORDER BY clause.
      *   O2SS0276: Column 'HRP.HRA_DEVCREC.EMP_NO' is invalid in ORDER BY clause.

      DECLARE
          CURTOTA3_1 CURSOR LOCAL FOR 
            SELECT count_big(*)
            FROM 
               (
                  SELECT 
                     HRA_DEVCREC.ORG_BY, 
                     HRA_DEVCREC.EMP_NO, 
                     HRA_DEVCREC.DEPT_NO, 
                     HRA_DEVCREC.VAC_TYPE, 
                     HRA_DEVCREC.VAC_RUL, 
                     HRA_DEVCREC.STATUS, 
                     ssma_oracle.to_char_date(HRA_DEVCREC.START_DATE, 'yyyy-mm-dd') AS SD, 
                     HRA_DEVCREC.START_TIME AS ST, 
                     ssma_oracle.to_char_date(HRA_DEVCREC.END_DATE, 'yyyy-mm-dd') AS ED, 
                     HRA_DEVCREC.END_TIME AS ET, 
                     HRA_DEVCREC.EVC_REA, 
                     HRA_DEVCREC.VAC_DAYS, 
                     HRA_DEVCREC.VAC_HRS, 
                     HRA_DEVCREC.REMARK
                  FROM HRP.HRA_DEVCREC
                  WHERE 
                     HRA_DEVCREC.STATUS IN ( 'Y', 'U' ) AND 
                     HRA_DEVCREC.START_DATE <= ssma_oracle.trunc_date(sysdatetime()) AND 
                     HRA_DEVCREC.END_DATE >= ssma_oracle.trunc_date(sysdatetime()) AND 
                     HRA_DEVCREC.DIS_ALL <> 'Y'
               )  AS TA, HRP.HRE_EMPBAS  AS TB
            WHERE TA.EMP_NO = TB.EMP_NO AND TB.ORGAN_TYPE = 'EF'
            ORDER BY TA.DEPT_NO, TB.POS_NO DESC, TA.EMP_NO
      */



      OPEN CURTOTA3_1

      WHILE 1 = 1
      
         BEGIN

            FETCH CURTOTA3_1
                INTO @N_TOTA3_1

            /*
            *   SSMA warning messages:
            *   O2SS0113: The value of @@FETCH_STATUS might be changed by previous FETCH operations on other cursors, if the cursors are used simultaneously.
            */

            IF @@FETCH_STATUS <> 0
               BREAK

            SET @N_RANG = ceiling(@N_TOTA3_1 / 10)

            DECLARE
               @I$2 int

            SET @I$2 = 1

            DECLARE
               @loop$bound$2 int

            SET @loop$bound$2 = @N_RANG

            WHILE @I$2 <= @loop$bound$2
            
               BEGIN

                  IF @I$2 = 1
                     IF @N_TOTA3_1 <= 10
                        BEGIN

                           SET @N_START = 1

                           SET @N_END = @N_TOTA3_1

                        END
                     ELSE 
                        BEGIN

                           SET @N_START = 1

                           SET @N_END = 10

                        END
                  ELSE 
                     BEGIN

                        SET @N_START = @N_END + 1

                        SET @N_END = @N_END + 10

                     END

                  DECLARE
                     @CURSOR_PARAM_CURSOR3_N_START varchar(max), 
                     @CURSOR_PARAM_CURSOR3_N_END varchar(max)

                  SET @CURSOR_PARAM_CURSOR3_N_START = @N_START

                  SET @CURSOR_PARAM_CURSOR3_N_END = @N_END

                  DECLARE
                      CURSOR3 CURSOR LOCAL FOR 
                        SELECT 
                           fci.EMP_NO, 
                           fci.CH_NAME, 
                           fci.DEPTNAME, 
                           fci.POSNAME, 
                           fci.VACNAME, 
                           fci.STATUSNAME, 
                           fci.SD, 
                           fci.ST, 
                           fci.ED, 
                           fci.ET, 
                           fci.EVCREA, 
                           fci.VAC_DAYS, 
                           fci.VAC_HRS, 
                           fci.REMARK
                        FROM 
                           (
                              SELECT 
                                 row_number() OVER(
                                    ORDER BY TA.DEPT_NO, TB.POS_NO DESC, TA.EMP_NO) AS NUM1, 
                                 TA.EMP_NO, 
                                 TB.CH_NAME, 
                                 
                                    (
                                       SELECT HRE_ORGBAS.CH_NAME
                                       FROM HRP.HRE_ORGBAS
                                       WHERE HRE_ORGBAS.DEPT_NO = TA.DEPT_NO
                                    ) AS DEPTNAME, 
                                 
                                    (
                                       SELECT HRE_POSMST.CH_NAME
                                       FROM HRP.HRE_POSMST
                                       WHERE HRE_POSMST.POS_NO = TB.POS_NO
                                    ) AS POSNAME, 
                                 
                                    (
                                       SELECT HRA_DVCRLMST.VAC_NAME
                                       FROM HRP.HRA_DVCRLMST
                                       WHERE HRA_DVCRLMST.VAC_TYPE = TA.VAC_TYPE
                                    ) AS VACNAME, 
                                 CASE TA.STATUS
                                    WHEN 'Y' THEN '准'
                                    WHEN 'U' THEN '申請'
                                    ELSE NULL
                                 END AS STATUSNAME, 
                                 TA.SD, 
                                 TA.ST, 
                                 TA.ED, 
                                 TA.ET, 
                                 
                                    (
                                       SELECT HR_CODEDTL.CODE_NAME
                                       FROM HRP.HR_CODEDTL
                                       WHERE HR_CODEDTL.CODE_TYPE = 'HRA08' AND HR_CODEDTL.CODE_NO = TA.EVC_REA
                                    ) AS EVCREA, 
                                 TA.VAC_DAYS, 
                                 TA.VAC_HRS, 
                                 TA.REMARK
                              FROM 
                                 (
                                    SELECT 
                                       HRA_DEVCREC.ORG_BY, 
                                       HRA_DEVCREC.EMP_NO, 
                                       HRA_DEVCREC.DEPT_NO, 
                                       HRA_DEVCREC.VAC_TYPE, 
                                       HRA_DEVCREC.VAC_RUL, 
                                       HRA_DEVCREC.STATUS, 
                                       ssma_oracle.to_char_date(HRA_DEVCREC.START_DATE, 'yyyy-mm-dd') AS SD, 
                                       HRA_DEVCREC.START_TIME AS ST, 
                                       ssma_oracle.to_char_date(HRA_DEVCREC.END_DATE, 'yyyy-mm-dd') AS ED, 
                                       HRA_DEVCREC.END_TIME AS ET, 
                                       HRA_DEVCREC.EVC_REA, 
                                       HRA_DEVCREC.VAC_DAYS, 
                                       HRA_DEVCREC.VAC_HRS, 
                                       HRA_DEVCREC.REMARK
                                    FROM HRP.HRA_DEVCREC
                                    WHERE 
                                       HRA_DEVCREC.STATUS IN ( 'Y', 'U' ) AND 
                                       HRA_DEVCREC.START_DATE <= ssma_oracle.trunc_date(sysdatetime()) AND 
                                       HRA_DEVCREC.END_DATE >= ssma_oracle.trunc_date(sysdatetime()) AND 
                                       HRA_DEVCREC.DIS_ALL <> 'Y'
                                 )  AS TA, HRP.HRE_EMPBAS  AS TB
                              WHERE TA.EMP_NO = TB.EMP_NO AND TB.ORGAN_TYPE = 'EF'
                           )  AS fci
                        WHERE fci.NUM1 >= @CURSOR_PARAM_CURSOR3_N_START AND fci.NUM1 <= @CURSOR_PARAM_CURSOR3_N_END

                  OPEN CURSOR3

                  SET @PEMPNO = NULL

                  WHILE 1 = 1
                  
                     BEGIN

                        FETCH CURSOR3
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
                              @PRM

                        /*
                        *   SSMA warning messages:
                        *   O2SS0113: The value of @@FETCH_STATUS might be changed by previous FETCH operations on other cursors, if the cursors are used simultaneously.
                        */

                        IF @@FETCH_STATUS <> 0
                           BREAK

                        IF @SMESSAGER IS NULL OR @SMESSAGER = ''
                           SET @SMESSAGER = '<table border="1" width="100%">' + '<tr><th>工號</th><th>姓名</th><th>部門名稱</th><th>職稱</th><th>假別</th>' + '<th>狀態</th><th>開始日期</th><th>開始時間</th><th>結束日期</th><th>結束時間</th>' + '<th>天數</th><th>時數</th><th>請假理由</th><th>其他原因</th></tr>'

                        IF @PEMPNO IS NOT NULL AND @PEMPNO != ''
                           SET @SMESSAGER = 
                              ISNULL(@SMESSAGER, '')
                               + 
                              '<tr><td>'
                               + 
                              ISNULL(@PEMPNO, '')
                               + 
                              '</td><td>'
                               + 
                              ISNULL(@PCHNAME, '')
                               + 
                              '</td><td>'
                               + 
                              ISNULL(@PDEPTNAME, '')
                               + 
                              '</td>'
                               + 
                              '<td>'
                               + 
                              ISNULL(@PPOSNAME, '')
                               + 
                              '</td><td>'
                               + 
                              ISNULL(@PVACNAME, '')
                               + 
                              '</td><td>'
                               + 
                              ISNULL(@PSTATUSNAME, '')
                               + 
                              '</td>'
                               + 
                              '<td>'
                               + 
                              ISNULL(@PSD, '')
                               + 
                              '</td><td>'
                               + 
                              ISNULL(@PST, '')
                               + 
                              '</td><td>'
                               + 
                              ISNULL(@PED, '')
                               + 
                              '</td><td>'
                               + 
                              ISNULL(@PET, '')
                               + 
                              '</td>'
                               + 
                              '<td>'
                               + 
                              ISNULL(CAST(@PVACDAYS AS nvarchar(max)), '')
                               + 
                              '</td><td>'
                               + 
                              ISNULL(CAST(@PVACHRS AS nvarchar(max)), '')
                               + 
                              '</td><td>'
                               + 
                              ISNULL(@PEVCREA, '')
                               + 
                              '</td><td>'
                               + 
                              ISNULL(@PRM, '')
                               + 
                              '</td></tr>'
                        ELSE 
                           SET @SMESSAGER = ISNULL(@SMESSAGER, '') + '<tr><td colspan="14">無醫師請假</td></tr>'

                     END

                  CLOSE CURSOR3

                  DEALLOCATE CURSOR3

                  SET @STITLER = '今日醫師請假通知_大昌醫院(' + ISNULL(ssma_oracle.to_char_date(sysdatetime(), 'yyyy-mm-dd'), '') + ')'

                  IF @SMESSAGER IS NULL OR @SMESSAGER = ''
                     SET @SMESSAGER = '<table border="1" width="100%">' + '<tr><th>工號</th><th>姓名</th><th>部門名稱</th><th>職稱</th><th>假別</th>' + '<th>狀態</th><th>開始日期</th><th>開始時間</th><th>結束日期</th><th>結束時間</th>' + '<th>天數</th><th>時數</th><th>請假理由</th><th>其他原因</th></tr>' + '<tr><td colspan="14">無醫師請假</td></tr>'

                  IF (@SMESSAGER IS NOT NULL AND @SMESSAGER != '')
                     BEGIN

                        SET @SMESSAGER = ISNULL(@SMESSAGER, '') + '</table>'

                        DECLARE
                            CURSOR2 CURSOR LOCAL FOR 
                              SELECT HR_CODEDTL.CODE_NAME
                              FROM HRP.HR_CODEDTL
                              WHERE 
                                 HR_CODEDTL.CODE_TYPE = 'HRA99' AND 
                                 HR_CODEDTL.CODE_NO LIKE 'D%' AND 
                                 HR_CODEDTL.DISABLED = 'N'

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
                                 @SUBJECT = @STITLER, 
                                 @MESSAGE = @SMESSAGER

                           END

                        CLOSE CURSOR2

                        DEALLOCATE CURSOR2

                     END

                  SET @SMESSAGER = NULL

                  SET @I$2 = @I$2 + 1

               END

         END

      CLOSE CURTOTA3_1

      DEALLOCATE CURTOTA3_1

   END
GO
BEGIN TRY
    EXEC sp_addextendedproperty
        N'MS_SSMA_SOURCE', N'HRP.EHRPHRAFUNC_PKG.HRASEND_MAIL_EF',
        N'SCHEMA', N'hrp',
        N'PROCEDURE', N'EHRPHRAFUNC_PKG$HRASEND_MAIL_EF'
END TRY
BEGIN CATCH
    IF (@@TRANCOUNT > 0) ROLLBACK
    PRINT ERROR_MESSAGE()
END CATCH
GO
