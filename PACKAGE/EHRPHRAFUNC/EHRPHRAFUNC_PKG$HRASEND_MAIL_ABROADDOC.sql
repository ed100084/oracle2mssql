
USE MIS
GO
 IF NOT EXISTS(SELECT * FROM sys.schemas WHERE [name] = N'hrp')      
     EXEC (N'CREATE SCHEMA hrp')                                   
 GO                                                               

USE MIS
GO
IF  EXISTS (SELECT * FROM sys.objects so JOIN sys.schemas sc ON so.schema_id = sc.schema_id WHERE so.name = N'EHRPHRAFUNC_PKG$HRASEND_MAIL_ABROADDOC'  AND sc.name=N'hrp'  AND type in (N'P',N'PC'))
 DROP PROCEDURE [hrp].[EHRPHRAFUNC_PKG$HRASEND_MAIL_ABROADDOC]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE HRP.EHRPHRAFUNC_PKG$HRASEND_MAIL_ABROADDOC  
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
         @SEEMAIL varchar(120), 
         @SMESSAGE varchar(max), 
         @SMESSAGEDOC varchar(max), 
         @SMESSAGEDOC2 varchar(max), 
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

         SET @SMESSAGE = NULL

         SET @SMESSAGEDOC = NULL

         SET @SMESSAGEDOC2 = NULL

         DECLARE
             CURSOR3 CURSOR LOCAL FOR 
               /*醫師*/
               SELECT 
                  A.EMP_NO, 
                  B.CH_NAME, 
                  C.CH_NAME AS DEPT_NAME, 
                  E.CH_NAME AS POS_NAME, 
                  D.VAC_NAME, 
                  CASE A.STATUS
                     WHEN 'Y' THEN '准'
                     WHEN 'U' THEN '申請'
                     ELSE NULL
                  END/*statusName*/ AS STATUSNAME, 
                  ssma_oracle.to_char_date(A.START_DATE, 'YYYY-MM-DD'), 
                  A.START_TIME, 
                  ssma_oracle.to_char_date(A.END_DATE, 'YYYY-MM-DD'), 
                  A.END_TIME, 
                  F.RUL_NAME/*pevcrea*/, 
                  A.VAC_DAYS, 
                  A.VAC_HRS, 
                  A.REMARK, 
                  NULL/*pevcday*/, 
                  NULL/*plastvacday*/, 
                  NULL/*pevc_u*/, 
                  NULL/*pevc_s*/, 
                  NULL/*pevc_f*/, 
                  A.ABROAD, 
                  CASE 
                     WHEN B.ORGAN_TYPE = 'ED' OR isnull(B.ORGAN_TYPE, 'ED') IS NULL THEN '義大'
                     WHEN B.ORGAN_TYPE = 'EC' OR isnull(B.ORGAN_TYPE, 'EC') IS NULL THEN '癌醫'
                     WHEN B.ORGAN_TYPE = 'EF' OR isnull(B.ORGAN_TYPE, 'EF') IS NULL THEN '大昌'
                  END AS ORGANTYPE, 
                  E.POS_LEVEL, 
                  A.CONTI_EVCNO
               FROM 
                  HRP.HRA_DEVCREC  AS A, 
                  HRP.HRE_EMPBAS  AS B, 
                  HRP.HRE_ORGBAS  AS C, 
                  HRP.HRA_DVCRLMST  AS D, 
                  HRP.HRE_POSMST  AS E, 
                  HRP.HRA_DVCRLDTL  AS F
               WHERE 
                  A.STATUS <> 'N' AND 
                  ((ssma_oracle.to_char_date(A.START_DATE, 'YYYY-MM-DD') BETWEEN ssma_oracle.to_char_date(sysdatetime(), 'YYYY-MM-DD') AND ssma_oracle.to_char_date(DATEADD(D, 7, sysdatetime()), 'YYYY-MM-DD')) OR (ssma_oracle.to_char_date(A.END_DATE, 'YYYY-MM-DD') BETWEEN ssma_oracle.to_char_date(sysdatetime(), 'YYYY-MM-DD') AND ssma_oracle.to_char_date(DATEADD(D, 7, sysdatetime()), 'YYYY-MM-DD')) OR (ssma_oracle.to_char_date(A.START_DATE, 'YYYY-MM-DD') <= ssma_oracle.to_char_date(sysdatetime(), 'YYYY-MM-DD') AND ssma_oracle.to_char_date(A.END_DATE, 'YYYY-MM-DD') >= ssma_oracle.to_char_date(DATEADD(D, 7, sysdatetime()), 'YYYY-MM-DD'))) AND 
                  A.EMP_NO = B.EMP_NO AND 
                  B.DEPT_NO = C.DEPT_NO AND 
                  A.VAC_TYPE = D.VAC_TYPE AND 
                  D.VAC_TYPE = F.VAC_TYPE AND 
                  A.VAC_RUL = F.VAC_RUL AND 
                  B.POS_NO = E.POS_NO AND 
                  A.ABROAD = 'Y' AND 
                  A.DIS_ALL = 'N' AND 
                  ((A.DIS_SD IS NULL) OR ((ssma_oracle.to_char_date(A.DIS_SD, 'YYYY-MM-DD') > ssma_oracle.to_char_date(sysdatetime(), 'YYYY-MM-DD')) OR (ssma_oracle.to_char_date(A.DIS_ED, 'YYYY-MM-DD') < ssma_oracle.to_char_date(sysdatetime(), 'YYYY-MM-DD'))))
               ORDER BY A.START_DATE, E.POS_LEVEL DESC, A.EMP_NO

         OPEN CURSOR3

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
                     @PRM, 
                     @PEVCDAY, 
                     @PLASTVACDAY, 
                     @PEVC_U, 
                     @PEVC_S, 
                     @PEVC_F, 
                     @PABROAD, 
                     @PORGANTYPE, 
                     @PPOSLEVEL, 
                     @PCONTIEVCNO

               /*
               *   SSMA warning messages:
               *   O2SS0113: The value of @@FETCH_STATUS might be changed by previous FETCH operations on other cursors, if the cursors are used simultaneously.
               */

               IF @@FETCH_STATUS <> 0
                  BREAK

               SET @NCONTI = 0

               SET @NCONTI2 = 0

               /*check 跨月出國假單*/
               SELECT @NCONTI = count_big(*)
               FROM HRP.HRA_DEVCREC
               WHERE 
                  HRA_DEVCREC.EMP_NO = @PEMPNO AND 
                  HRA_DEVCREC.START_DATE > sysdatetime() AND 
                  HRA_DEVCREC.ABROAD = 'Y' AND 
                  ssma_oracle.to_char_date(HRA_DEVCREC.START_DATE, 'yyyy-mm-dd') = @PSD AND 
                  HRA_DEVCREC.CONTI_EVCNO IN 
                  (
                     SELECT HRA_DEVCREC$2.EVC_NO
                     FROM HRP.HRA_DEVCREC  AS HRA_DEVCREC$2
                     WHERE HRA_DEVCREC$2.EVC_NO = @PCONTIEVCNO AND HRA_DEVCREC$2.DIS_ALL = 'N'
                  )

               /*20221018 by108482 check 連續假卡是否已經出國*/
               IF @PCONTIEVCNO IS NOT NULL AND @PCONTIEVCNO != ''
                  BEGIN

                     BEGIN

                        BEGIN TRY
                           SELECT @PSD2 = ssma_oracle.to_char_date(HRA_DEVCREC.START_DATE, 'yyyy-mm-dd')
                           FROM HRP.HRA_DEVCREC
                           WHERE HRA_DEVCREC.EVC_NO = @PCONTIEVCNO AND HRA_DEVCREC.DIS_ALL = 'N'
                        END TRY

                        BEGIN CATCH
                           BEGIN
                              SET @PSD2 = NULL
                           END
                        END CATCH

                     END

                     IF @PSD > @PSD2
                        IF @PSD2 <= ssma_oracle.to_char_date(sysdatetime(), 'yyyy-mm-dd')
                           SET @NCONTI2 = 1
                        ELSE 
                           SET @NCONTI2 = 0
                     ELSE 
                        IF @PSD <= ssma_oracle.to_char_date(sysdatetime(), 'yyyy-mm-dd')
                           SET @NCONTI2 = 1
                        ELSE 
                           SET @NCONTI2 = 0

                  END

               IF @PSD <= ssma_oracle.to_char_date(sysdatetime(), 'yyyy-mm-dd') OR (@NCONTI <> 0 AND @NCONTI2 <> 0)
                  SET @PABROAD = ISNULL(@PABROAD, '') + '-已出'
               ELSE 
                  SET @PABROAD = ISNULL(@PABROAD, '') + '-未出'

               IF @SMESSAGEDOC IS NULL OR @SMESSAGEDOC = ''
                  BEGIN

                     SET @SMESSAGEDOC = '<table border="1" width="100%">'

                     SET @SMESSAGEDOC = ISNULL(@SMESSAGEDOC, '') + '<tr><td colspan="17" ><BR>' + '==========(醫師出國假單)==========' + '<BR><BR></tr></tr>'

                     SET @SMESSAGEDOC = ISNULL(@SMESSAGEDOC, '') + '<TR><TD>機構</td><TD>工號</td><TD>姓名</td><TD>部門名稱</td><TD>職稱</td><TD>職等</td><TD>假別</td>'

                     SET @SMESSAGEDOC = ISNULL(@SMESSAGEDOC, '') + '<TD>狀態</td><TD>開始日期</td><TD>開始時間</td><TD>結束日期</td><TD>結束時間</td>'

                     SET @SMESSAGEDOC = ISNULL(@SMESSAGEDOC, '') + '<TD>天數</td><TD>時數</td><TD>請假理由</td><TD>其他原因</td><TD>出國</td>'

                     SET @SMESSAGEDOC = 
                        ISNULL(@SMESSAGEDOC, '')
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

                     SET @SMESSAGEDOC = 
                        ISNULL(@SMESSAGEDOC, '')
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

                     SET @SMESSAGEDOC = 
                        ISNULL(@SMESSAGEDOC, '')
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

                     SET @SMESSAGEDOC = 
                        ISNULL(@SMESSAGEDOC, '')
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

                     SET @SMESSAGEDOC = 
                        ISNULL(@SMESSAGEDOC, '')
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
                  IF ssma_oracle.length_varchar(@SMESSAGEDOC) < 19000
                     BEGIN

                        SET @SMESSAGEDOC = 
                           ISNULL(@SMESSAGEDOC, '')
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

                        SET @SMESSAGEDOC = 
                           ISNULL(@SMESSAGEDOC, '')
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

                        SET @SMESSAGEDOC = 
                           ISNULL(@SMESSAGEDOC, '')
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

                        SET @SMESSAGEDOC = 
                           ISNULL(@SMESSAGEDOC, '')
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

                        SET @SMESSAGEDOC = 
                           ISNULL(@SMESSAGEDOC, '')
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
                        IF ssma_oracle.length_varchar(@SMESSAGEDOC) > 19000
                           IF @SMESSAGEDOC2 IS NULL OR @SMESSAGEDOC2 = ''
                              BEGIN

                                 SET @SMESSAGEDOC2 = '<table border="1" width="100%">'

                                 SET @SMESSAGEDOC2 = ISNULL(@SMESSAGEDOC2, '') + '<tr><td colspan="17" ><BR>' + '==========(醫師出國假單,接續前一封)==========' + '<BR><BR></tr></tr>'

                                 SET @SMESSAGEDOC2 = ISNULL(@SMESSAGEDOC2, '') + '<TR><TD>機構</td><TD>工號</td><TD>姓名</td><TD>部門名稱</td><TD>職稱</td><TD>職等</td><TD>假別</td>'

                                 SET @SMESSAGEDOC2 = ISNULL(@SMESSAGEDOC2, '') + '<TD>狀態</td><TD>開始日期</td><TD>開始時間</td><TD>結束日期</td><TD>結束時間</td>'

                                 SET @SMESSAGEDOC2 = ISNULL(@SMESSAGEDOC2, '') + '<TD>天數</td><TD>時數</td><TD>請假理由</td><TD>其他原因</td><TD>出國</td>'

                                 SET @SMESSAGEDOC2 = 
                                    ISNULL(@SMESSAGEDOC2, '')
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

                                 SET @SMESSAGEDOC2 = 
                                    ISNULL(@SMESSAGEDOC2, '')
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

                                 SET @SMESSAGEDOC2 = 
                                    ISNULL(@SMESSAGEDOC2, '')
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

                                 SET @SMESSAGEDOC2 = 
                                    ISNULL(@SMESSAGEDOC2, '')
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

                                 SET @SMESSAGEDOC2 = 
                                    ISNULL(@SMESSAGEDOC2, '')
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

                                 SET @SMESSAGEDOC2 = 
                                    ISNULL(@SMESSAGEDOC2, '')
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

                                 SET @SMESSAGEDOC2 = 
                                    ISNULL(@SMESSAGEDOC2, '')
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

                                 SET @SMESSAGEDOC2 = 
                                    ISNULL(@SMESSAGEDOC2, '')
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

                                 SET @SMESSAGEDOC2 = 
                                    ISNULL(@SMESSAGEDOC2, '')
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

                                 SET @SMESSAGEDOC2 = 
                                    ISNULL(@SMESSAGEDOC2, '')
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

            END

         /*sMessageDoc := sMessageDoc|| '</table>';*/
         CLOSE CURSOR3

         DEALLOCATE CURSOR3

         SET @STITLE = '未來一週請假出國人員名單(醫師)(' + ISNULL(ssma_oracle.to_char_date(sysdatetime(), 'yyyy-mm-dd'), '') + ')'

         IF @SMESSAGEDOC IS NULL OR @SMESSAGEDOC = ''
            IF @SMESSAGE IS NULL OR @SMESSAGE = ''
               /*無醫師無一般*/
               SET @SMESSAGEMAIL = '截至上午07:10，無未來一週請假出國假卡。'
            ELSE 
               BEGIN

                  /*無醫師有一般*/
                  SET @SMESSAGE = ISNULL(@SMESSAGE, '') + '</table>'

                  SET @SMESSAGEMAIL = @SMESSAGE

               END
         ELSE 
            BEGIN

               SET @SMESSAGEDOC = ISNULL(@SMESSAGEDOC, '') + '</table>'

               IF @SMESSAGE IS NULL OR @SMESSAGE = ''
                  /*有醫師無一般*/
                  SET @SMESSAGEMAIL = @SMESSAGEDOC
               ELSE 
                  BEGIN

                     /*有醫師有一般*/
                     SET @SMESSAGE = ISNULL(@SMESSAGE, '') + '</table>'

                     SET @SMESSAGEMAIL = ISNULL(@SMESSAGEDOC, '') + '<br><br>' + ISNULL(@SMESSAGE, '')

                  END

            END

         IF @SMESSAGEDOC2 IS NOT NULL AND @SMESSAGEDOC2 != ''
            SET @SMESSAGEDOC2 = ISNULL(@SMESSAGEDOC2, '') + '</table>'

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

               IF @SMESSAGEDOC2 IS NOT NULL AND @SMESSAGEDOC2 != ''
                  BEGIN

                     DECLARE
                        @temp varchar(8000)

                     SET @temp = ISNULL(@STITLE, '') + '_1'

                     EXECUTE HRP.EHRPHRAFUNC_PKG$POST_HTML_MAIL 
                        @SENDER = 'system@edah.org.tw', 
                        @RECIPIENT = @SEEMAIL, 
                        @CC_RECIPIENT = NULL, 
                        @MAILTYPE = '1', 
                        @SUBJECT = @temp, 
                        @MESSAGE = @SMESSAGEMAIL

                     DECLARE
                        @temp$2 varchar(8000)

                     SET @temp$2 = ISNULL(@STITLE, '') + '_2'

                     EXECUTE HRP.EHRPHRAFUNC_PKG$POST_HTML_MAIL 
                        @SENDER = 'system@edah.org.tw', 
                        @RECIPIENT = @SEEMAIL, 
                        @CC_RECIPIENT = NULL, 
                        @MAILTYPE = '1', 
                        @SUBJECT = @temp$2, 
                        @MESSAGE = @SMESSAGEDOC2

                  END
               ELSE 
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

            SET @ERRORCODE = @PEMPNO

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
                  '未來一週請假出國人員名單通知執行異常(醫師)', 
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
        N'MS_SSMA_SOURCE', N'HRP.EHRPHRAFUNC_PKG.HRASEND_MAIL_ABROADDOC',
        N'SCHEMA', N'hrp',
        N'PROCEDURE', N'EHRPHRAFUNC_PKG$HRASEND_MAIL_ABROADDOC'
END TRY
BEGIN CATCH
    IF (@@TRANCOUNT > 0) ROLLBACK
    PRINT ERROR_MESSAGE()
END CATCH
GO
