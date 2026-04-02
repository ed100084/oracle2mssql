
USE MIS
GO
 IF NOT EXISTS(SELECT * FROM sys.schemas WHERE [name] = N'hrp')      
     EXEC (N'CREATE SCHEMA hrp')                                   
 GO                                                               

USE MIS
GO
IF  EXISTS (SELECT * FROM sys.objects so JOIN sys.schemas sc ON so.schema_id = sc.schema_id WHERE so.name = N'EHRPHRA12_PKG$HRAC030'  AND sc.name=N'hrp'  AND type in (N'P',N'PC'))
 DROP PROCEDURE [hrp].[EHRPHRA12_PKG$HRAC030]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE HRP.EHRPHRA12_PKG$HRAC030  
   @P_ITEM_TYPE varchar(max),
   @P_EMP_NO varchar(max),
   @P_START_DATE varchar(max),
   @P_START_TIME varchar(max),
   @P_END_DATE varchar(max),
   @P_END_TIME varchar(max),
   @P_ON_CALL varchar(max),
   @P_POSTED_STARTDATE varchar(max),
   @P_POSTED_STARTTIME varchar(max),
   @P_POSTED_STATUS varchar(max),
   @P_START_DATE_TMP varchar(max),
   @P_OTM_HRS varchar(max),
   @ORGANTYPE_IN varchar(max),
   /*
   *   SSMA warning messages:
   *   O2SS0356: Conversion from NUMBER datatype can cause data loss.
   */

   @RTNCODE float(53)  OUTPUT
AS 
   BEGIN

      SET @RTNCODE = NULL

      EXECUTE ssma_oracle.db_check_init_package 'HRP', 'EHRPHRA12_PKG'

      DECLARE
         @SITEMTYPE varchar(1) = @P_ITEM_TYPE, 
         @SEMPNO varchar(20) = @P_EMP_NO, 
         @SSTART varchar(20) = ISNULL(@P_START_DATE, '') + ISNULL(@P_START_TIME, ''), 
         @SEND varchar(20) = ISNULL(@P_END_DATE, '') + ISNULL(@P_END_TIME, ''), 
         @SONCALL varchar(1) = @P_ON_CALL, 
         /*
         *   SSMA warning messages:
         *   O2SS0356: Conversion from NUMBER datatype can cause data loss.
         */

         @SOFFREST float(53), 
         @SORGANTYPE varchar(10) = @ORGANTYPE_IN, 
         /*
         *   SSMA warning messages:
         *   O2SS0356: Conversion from NUMBER datatype can cause data loss.
         */

         /*20113-03-22 modify by weihun VACHAR2(3) -> NUMBER(5,1)*/
         @SOTMHRS float(53) = CAST(@P_OTM_HRS AS numeric(38, 10)), 
         @SCLASSKIND varchar(3), 
         @SLASTCLASSKIND varchar(3), 
         @SNEXTCLASSKIND varchar(3), 
         @ICNT int, 
         @ICNT2 int, 
         @I_END_DATE varchar(10), 
         @ICHECKCARD varchar(1)/*註記是否為加班打卡,預設N(非加班打卡) 20181219 by108482*/, 
         @IPOSLEVEL varchar(1)/*確認職等，7職等(含)以上人員不能自行申請加班 20190306 by108482*/, 
         @ICHKINWKTM varchar(4), 
         @ICHKOUTWKTM varchar(4), 
         @LIMITDAY varchar(2), 
         /*
         *   SSMA warning messages:
         *   O2SS0356: Conversion from NUMBER datatype can cause data loss.
         */

         /*上限加舊結算*/
         @SOLDSUMARY float(53), 
         @PCHKINREA varchar(2), 
         @PCHKOUTREA varchar(2), 
         @PWKINTM varchar(20), 
         @PWKOUTTM varchar(20), 
         /*
         *   SSMA warning messages:
         *   O2SS0356: Conversion from NUMBER datatype can cause data loss.
         */

         @SWORKHRS float(53)/* 當日班表時數*/, 
         /*
         *   SSMA warning messages:
         *   O2SS0356: Conversion from NUMBER datatype can cause data loss.
         */

         @STOTADDHRS float(53)/*當日在途積休單申請時數*/, 
         /*
         *   SSMA warning messages:
         *   O2SS0356: Conversion from NUMBER datatype can cause data loss.
         */

         @STOTMONADD float(53)/*當月積休單總時數(含在途)*/, 
         /*
         *   SSMA warning messages:
         *   O2SS0356: Conversion from NUMBER datatype can cause data loss.
         */

         @SOTMSIGNHRS float(53)/*當日加班單時數*/, 
         /*
         *   SSMA warning messages:
         *   O2SS0356: Conversion from NUMBER datatype can cause data loss.
         */

         @SMONCLASSADD float(53)/* 當月班表超時*/

      SET @SOLDSUMARY = 0

      SET @RTNCODE = 0

      SET @SWORKHRS = 0

      SET @STOTADDHRS = 0

      SET @STOTMONADD = 0

      SET @SOTMSIGNHRS = 0

      SET @SMONCLASSADD = 0

      SET @ICHECKCARD = 'N'

      
      /*
      *   IF SYSDATE  > TO_DATE(p_start_date,'YYYY-MM-DD')+7 THEN 20151110 修改 14天 可申請
      *   IF SYSDATE  > TO_DATE(p_start_date,'YYYY-MM-DD')+14 THEN
      *           RtnCode := 11 ;
      *           GOTO Continue_ForEach1 ;
      *         END IF;
      *   20210113 by108482 申請不卡14天申請期限,超過五天才申請違規記點
      *   20210204 by108482 每月申請最多至隔月5號(5號當天可以申請)
      *   20241007 by108482 每月申請最多至隔月幾號抓參數HRA89的設定
      */
      BEGIN

         BEGIN TRY
            SELECT @LIMITDAY = HR_CODEDTL.CODE_NAME
            FROM HRP.HR_CODEDTL
            WHERE HR_CODEDTL.CODE_TYPE = 'HRA89' AND HR_CODEDTL.CODE_NO = 'DAY'
         END TRY

         BEGIN CATCH
            BEGIN
               SET @LIMITDAY = '5'
            END
         END CATCH

      END

      
      /*
      *   IF trunc(SYSDATE) > trunc(ADD_MONTHS(TO_DATE(p_start_date, 'yyyy/mm/dd'), 1), 'mm') +9 THEN
      *           RtnCode := 11 ;
      *           GOTO Continue_ForEach1 ;
      *         END IF;
      */
      IF ssma_oracle.trunc_date(sysdatetime()) > CONVERT(datetime2, ISNULL(ssma_oracle.to_char_date(dateadd(m, 1, CONVERT(datetime2, @P_START_DATE, 111)), 'YYYY-MM'), '') + '-' + ISNULL(@LIMITDAY, ''), 111)
         BEGIN

            SET @RTNCODE = 11

            GOTO CONTINUE_FOREACH1

         END

      /*IF 借休該日班表時數為0時,不可存檔*/
      IF @SITEMTYPE = 'O'
         BEGIN

            SET @SCLASSKIND = HRP.EHRPHRAFUNC_PKG$F_GETCLASSKIND(@P_EMP_NO, ssma_oracle.to_date2(@P_START_DATE, 'YYYY-MM-DD'), @SORGANTYPE)

            BEGIN
               SELECT @ICNT = count_big(*)
               FROM HRP.HRA_CLASSMST
               WHERE HRA_CLASSMST.CLASS_CODE = @SCLASSKIND AND HRA_CLASSMST.WORK_HRS = 0
            END

            IF @ICNT > 0
               BEGIN

                  SET @RTNCODE = 12

                  GOTO CONTINUE_FOREACH1

               END

         END

      IF @SITEMTYPE = 'O' AND @P_START_DATE_TMP <> @P_START_DATE
         SET @SSTART = ISNULL(ssma_oracle.to_char_date(DATEADD(D, 1, ssma_oracle.to_date2(@P_START_DATE, 'YYYY-MM-DD')), 'YYYY-MM-DD'), '') + ISNULL(@P_START_TIME, '')

      
      /*
      *   ----------------------- 積休單 -------------------------
      *   (檢核在資料庫中除''不准''以外的積休單申請時間是否重疊)
      */
      IF @SITEMTYPE = 'A'
         BEGIN

            BEGIN

               BEGIN TRY
                  SELECT @IPOSLEVEL = HRE_POSMST.POS_LEVEL
                  FROM HRP.HRE_POSMST
                  WHERE HRE_POSMST.POS_NO = 
                     (
                        SELECT HRE_EMPBAS.POS_NO
                        FROM HRP.HRE_EMPBAS
                        WHERE HRE_EMPBAS.EMP_NO = @SEMPNO
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
                     SET @IPOSLEVEL = NULL
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

            /*108482 20190306 7職等(含)以上人員不能自行申請加班*/
            IF @IPOSLEVEL IS NULL OR @IPOSLEVEL = ''
               BEGIN

                  SET @RTNCODE = 99

                  GOTO CONTINUE_FOREACH1

               END
            ELSE 
               BEGIN
                  IF @IPOSLEVEL >= 7
                     BEGIN

                        SET @RTNCODE = 17

                        GOTO CONTINUE_FOREACH1

                     END
               END

            BEGIN

               BEGIN TRY
                  SELECT @ICNT = count_big(ROWID)
                  FROM HRP.HRA_OFFREC
                  WHERE 
                     HRA_OFFREC.EMP_NO = @SEMPNO AND 
                     HRA_OFFREC.ITEM_TYPE = @SITEMTYPE AND 
                     (
                     ((@SSTART >= ISNULL(ssma_oracle.to_char_date(HRA_OFFREC.START_DATE, 'YYYY-MM-DD'), '') + ISNULL(HRA_OFFREC.START_TIME, '') AND @SSTART < ISNULL(ssma_oracle.to_char_date(HRA_OFFREC.END_DATE, 'YYYY-MM-DD'), '') + ISNULL(HRA_OFFREC.END_TIME, '')) OR (@SEND > ISNULL(ssma_oracle.to_char_date(HRA_OFFREC.START_DATE, 'YYYY-MM-DD'), '') + ISNULL(HRA_OFFREC.START_TIME, '') AND @SEND <= ISNULL(ssma_oracle.to_char_date(HRA_OFFREC.END_DATE, 'YYYY-MM-DD'), '') + ISNULL(HRA_OFFREC.END_TIME, ''))) OR 
                     (ISNULL(ssma_oracle.to_char_date(HRA_OFFREC.START_DATE, 'YYYY-MM-DD'), '') + ISNULL(HRA_OFFREC.START_TIME, '') >= @SSTART AND ISNULL(ssma_oracle.to_char_date(HRA_OFFREC.END_DATE, 'YYYY-MM-DD'), '') + ISNULL(HRA_OFFREC.END_TIME, '') < @SSTART) OR 
                     (ISNULL(ssma_oracle.to_char_date(HRA_OFFREC.START_DATE, 'YYYY-MM-DD'), '') + ISNULL(HRA_OFFREC.START_TIME, '') > @SEND AND ISNULL(ssma_oracle.to_char_date(HRA_OFFREC.END_DATE, 'YYYY-MM-DD'), '') + ISNULL(HRA_OFFREC.END_TIME, '') <= @SEND) OR 
                     (ISNULL(ssma_oracle.to_char_date(HRA_OFFREC.START_DATE, 'YYYY-MM-DD'), '') + ISNULL(HRA_OFFREC.START_TIME, '') >= @SSTART AND ISNULL(ssma_oracle.to_char_date(HRA_OFFREC.END_DATE, 'YYYY-MM-DD'), '') + ISNULL(HRA_OFFREC.END_TIME, '') <= @SEND)) AND 
                     /*20200410 by108482 檢核更精確  OR (to_char(start_date, 'YYYY-MM-DD') || start_time = sStart AND to_char(end_date, 'YYYY-MM-DD')||end_time = sEnd))*/HRA_OFFREC.STATUS IN ( 'U', '1', '2', 'Y' ) AND 
                     HRA_OFFREC.ORG_BY = @SORGANTYPE
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
                     SET @ICNT = 0
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

            IF @ICNT > 0
               SET @RTNCODE = 1

            /*判斷是否為更改原資料*/
            IF 
               @ICNT > 0 AND 
               @P_POSTED_STARTDATE <> 'N/A' AND 
               @P_POSTED_STARTTIME <> 'N/A' AND 
               @P_POSTED_STATUS <> 'N/A'
               BEGIN

                  BEGIN

                     BEGIN TRY
                        SELECT @ICNT = count_big(*)
                        FROM HRP.HRA_OFFREC
                        WHERE 
                           HRA_OFFREC.EMP_NO = @SEMPNO AND 
                           HRA_OFFREC.ITEM_TYPE = @SITEMTYPE AND 
                           HRA_OFFREC.START_DATE = ssma_oracle.to_date2(@P_POSTED_STARTDATE, 'yyyy-mm-dd') AND 
                           HRA_OFFREC.START_TIME = @P_POSTED_STARTTIME AND 
                           HRA_OFFREC.STATUS = @P_POSTED_STATUS AND 
                           HRA_OFFREC.ORG_BY = @SORGANTYPE
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
                           SET @ICNT = 0
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

                  IF @ICNT >= 1
                     SET @RTNCODE = 0

               END

         END
      ELSE 
         BEGIN

            /*sItemType = 'O'*/
            BEGIN

               BEGIN TRY
                  SELECT @ICNT = count_big(ROWID)
                  FROM HRP.HRA_OFFREC
                  WHERE 
                     HRA_OFFREC.EMP_NO = @SEMPNO AND 
                     HRA_OFFREC.ITEM_TYPE = @SITEMTYPE AND 
                     (HRA_OFFREC.START_DATE = HRA_OFFREC.START_DATE_TMP AND ((
                     ((@SSTART >= ISNULL(ssma_oracle.to_char_date(HRA_OFFREC.START_DATE, 'YYYY-MM-DD'), '') + ISNULL(HRA_OFFREC.START_TIME, '') AND @SSTART < ISNULL(ssma_oracle.to_char_date(HRA_OFFREC.END_DATE, 'YYYY-MM-DD'), '') + ISNULL(HRA_OFFREC.END_TIME, '')) OR (@SEND > ISNULL(ssma_oracle.to_char_date(HRA_OFFREC.START_DATE, 'YYYY-MM-DD'), '') + ISNULL(HRA_OFFREC.START_TIME, '') AND @SEND <= ISNULL(ssma_oracle.to_char_date(HRA_OFFREC.END_DATE, 'YYYY-MM-DD'), '') + ISNULL(HRA_OFFREC.END_TIME, ''))) OR 
                     (ISNULL(ssma_oracle.to_char_date(HRA_OFFREC.START_DATE, 'YYYY-MM-DD'), '') + ISNULL(HRA_OFFREC.START_TIME, '') >= @SSTART AND ISNULL(ssma_oracle.to_char_date(HRA_OFFREC.END_DATE, 'YYYY-MM-DD'), '') + ISNULL(HRA_OFFREC.END_TIME, '') < @SSTART) OR 
                     (ISNULL(ssma_oracle.to_char_date(HRA_OFFREC.START_DATE, 'YYYY-MM-DD'), '') + ISNULL(HRA_OFFREC.START_TIME, '') > @SEND AND ISNULL(ssma_oracle.to_char_date(HRA_OFFREC.END_DATE, 'YYYY-MM-DD'), '') + ISNULL(HRA_OFFREC.END_TIME, '') <= @SEND) OR 
                     (ISNULL(ssma_oracle.to_char_date(HRA_OFFREC.START_DATE, 'YYYY-MM-DD'), '') + ISNULL(HRA_OFFREC.START_TIME, '') = @SSTART AND ISNULL(ssma_oracle.to_char_date(HRA_OFFREC.END_DATE, 'YYYY-MM-DD'), '') + ISNULL(HRA_OFFREC.END_TIME, '') = @SEND))) OR (HRA_OFFREC.START_DATE <> HRA_OFFREC.START_DATE_TMP AND (
                     ((@SSTART >= ISNULL(ssma_oracle.to_char_date(HRA_OFFREC.START_DATE_TMP, 'YYYY-MM-DD'), '') + ISNULL(HRA_OFFREC.START_TIME, '') AND @SSTART < ISNULL(ssma_oracle.to_char_date(HRA_OFFREC.END_DATE, 'YYYY-MM-DD'), '') + ISNULL(HRA_OFFREC.END_TIME, '')) OR (@SEND > ISNULL(ssma_oracle.to_char_date(HRA_OFFREC.START_DATE_TMP, 'YYYY-MM-DD'), '') + ISNULL(HRA_OFFREC.START_TIME, '') AND @SEND <= ISNULL(ssma_oracle.to_char_date(HRA_OFFREC.END_DATE, 'YYYY-MM-DD'), '') + ISNULL(HRA_OFFREC.END_TIME, ''))) OR 
                     (ISNULL(ssma_oracle.to_char_date(HRA_OFFREC.START_DATE_TMP, 'YYYY-MM-DD'), '') + ISNULL(HRA_OFFREC.START_TIME, '') >= @SSTART AND ISNULL(ssma_oracle.to_char_date(HRA_OFFREC.END_DATE, 'YYYY-MM-DD'), '') + ISNULL(HRA_OFFREC.END_TIME, '') < @SSTART) OR 
                     (ISNULL(ssma_oracle.to_char_date(HRA_OFFREC.START_DATE_TMP, 'YYYY-MM-DD'), '') + ISNULL(HRA_OFFREC.START_TIME, '') > @SEND AND ISNULL(ssma_oracle.to_char_date(HRA_OFFREC.END_DATE, 'YYYY-MM-DD'), '') + ISNULL(HRA_OFFREC.END_TIME, '') <= @SEND) OR 
                     (ISNULL(ssma_oracle.to_char_date(HRA_OFFREC.START_DATE_TMP, 'YYYY-MM-DD'), '') + ISNULL(HRA_OFFREC.START_TIME, '') = @SSTART AND ISNULL(ssma_oracle.to_char_date(HRA_OFFREC.END_DATE, 'YYYY-MM-DD'), '') + ISNULL(HRA_OFFREC.END_TIME, '') = @SEND)))) AND 
                     HRA_OFFREC.STATUS IN ( 'U', '1', '2', 'Y' ) AND 
                     HRA_OFFREC.ORG_BY = @SORGANTYPE
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
                     SET @ICNT = 0
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

            IF @ICNT > 0
               SET @RTNCODE = 1

            /*判斷是否為更改原資料*/
            IF 
               @ICNT > 0 AND 
               @P_POSTED_STARTDATE <> 'N/A' AND 
               @P_POSTED_STARTTIME <> 'N/A' AND 
               @P_POSTED_STATUS <> 'N/A'
               BEGIN

                  BEGIN

                     BEGIN TRY
                        SELECT @ICNT = count_big(*)
                        FROM HRP.HRA_OFFREC
                        WHERE 
                           HRA_OFFREC.EMP_NO = @SEMPNO AND 
                           HRA_OFFREC.ITEM_TYPE = @SITEMTYPE AND 
                           HRA_OFFREC.START_DATE_TMP = ssma_oracle.to_date2(@P_POSTED_STARTDATE, 'yyyy-mm-dd') AND 
                           HRA_OFFREC.START_TIME = @P_POSTED_STARTTIME AND 
                           HRA_OFFREC.STATUS = @P_POSTED_STATUS AND 
                           HRA_OFFREC.ORG_BY = @SORGANTYPE
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
                           SET @ICNT = 0
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

                  IF @ICNT >= 1
                     SET @RTNCODE = 0

               END

         END

      IF @RTNCODE = 1
         GOTO CONTINUE_FOREACH1

      /*-借休不可申請 OnCall---*/
      IF @SITEMTYPE = 'O' AND @SONCALL = 'Y'
         BEGIN

            SET @RTNCODE = 7

            GOTO CONTINUE_FOREACH1

         END

      /*-借休不可申請 超過 24 小時 (工讀生,兼職不必)---*/
      IF 
         @SITEMTYPE = 'O' AND 
         @P_EMP_NO NOT LIKE 'P%' AND 
         @P_EMP_NO NOT LIKE 'S%'
         BEGIN

            BEGIN

               BEGIN TRY
                  SELECT @SOFFREST = (
                     HRA_ATTVAC_VIEW.MON_GETADD
                      + 
                     HRA_ATTVAC_VIEW.MON_ADDHRS
                      + 
                     HRA_ATTVAC_VIEW.MON_OTMHRS
                      - 
                     HRA_ATTVAC_VIEW.MON_OFFHRS
                      + 
                     HRA_ATTVAC_VIEW.MON_SPCOTM
                      - 
                     HRA_ATTVAC_VIEW.MON_CUTOTM
                      + 
                     HRA_ATTVAC_VIEW.MON_DUTYHRS) + 
                     (
                        SELECT isnull(sum(HRA_ATTDTL1.ATT_VALUE), 0) AS expr
                        FROM HRP.HRA_ATTDTL1
                        WHERE 
                           HRA_ATTDTL1.EMP_NO = @SEMPNO AND 
                           HRA_ATTDTL1.ATT_CODE = '204' AND 
                           HRA_ATTDTL1.DISABLED = 'N' AND 
                           HRA_ATTDTL1.TRN_YM < ssma_oracle.to_char_date(sysdatetime(), 'YYYY-MM')
                     )
                  FROM HRP.HRA_ATTVAC_VIEW
                  WHERE (HRA_ATTVAC_VIEW.EMP_NO = @SEMPNO) AND (HRA_ATTVAC_VIEW.SCH_YM = ssma_oracle.to_char_date(sysdatetime(), 'YYYY-MM'))
               END TRY

               BEGIN CATCH

                  DECLARE
                     @errornumber$6 int

                  SET @errornumber$6 = ERROR_NUMBER()

                  DECLARE
                     @errormessage$6 nvarchar(4000)

                  SET @errormessage$6 = ERROR_MESSAGE()

                  DECLARE
                     @exceptionidentifier$6 nvarchar(4000)

                  SELECT @exceptionidentifier$6 = ssma_oracle.db_error_get_oracle_exception_id(@errormessage$6, @errornumber$6)

                  IF (@exceptionidentifier$6 LIKE N'ORA-00100%')
                     SET @ICNT = 0
                  ELSE 
                     BEGIN
                        IF (@exceptionidentifier$6 IS NOT NULL)
                           BEGIN
                              IF @errornumber$6 = 59998
                                 RAISERROR(59998, 16, 1, @exceptionidentifier$6)
                              ELSE 
                                 RAISERROR(59999, 16, 1, @exceptionidentifier$6)
                           END
                        ELSE 
                           BEGIN
                              EXECUTE ssma_oracle.ssma_rethrowerror
                           END
                     END

               END CATCH

            END

            SET @SOFFREST = @SOFFREST

            
            /*
            *    需包含此次申請的時數 by szuhao 2007.7.16
            *   2010-11-24 modify by weichun 因要加上結算後再計算上限 for 需求 2011-05-19關閉
            *   select nvl(case when (select hrs_alloffym from hrs_ym where rownum = 1) = '2010-09' then
            *    (select clos_hrs from hra_offclos where clos_ym = '2010-9' and emp_no = sEmpNo) else 0 end,0)
            *     into sOldSumary
            *     from dual;
            *    IF  (sOffrest - sOtmhrs) + sOldSumary < -24 THEN
            *   2010-02-01 修改調成績核時數由24改為超過9999時不可借休(即不稽核)
            *   IF  (sOffrest - sOtmhrs) + sOldSumary < -9999 THEN
            *   2014-04-28 修改為無稽休不能借休
            */
            IF (@SOFFREST - @SOTMHRS) + @SOLDSUMARY < 0
               BEGIN

                  SET @RTNCODE = 9

                  GOTO CONTINUE_FOREACH1

               END

         END

      
      /*
      *   判斷是否為借休 或 OnCall
      *   IF   p_item_type ='O' OR ( p_item_type ='A' AND p_on_call='Y') THEN
      *   20190312 by108482 加班費需KEY應出勤日,20190823 by108482 sStart依照人員填入的時間
      *   IF p_item_type ='O' OR ( p_item_type ='A' AND p_start_date_tmp <> 'N/A') THEN
      */
      IF @P_ITEM_TYPE = 'O' OR (@P_ITEM_TYPE = 'A' AND @P_ON_CALL = 'Y')
         /*sStart := p_start_date_tmp || p_start_time;*/
         SET @SSTART = ISNULL(@P_START_DATE, '') + ISNULL(@P_START_TIME, '')

      SET @RTNCODE = 0

      /*----------------------- 積休單 -------------------------*/
      IF @SITEMTYPE = 'A'
         BEGIN

            
            /*
            *   -積休不可申請加班----多機構沒差一並判斷
            *   20180612 108978 IMP201806109 同日加班申請方式只能同一種申請方式」規則
            */
            BEGIN

               BEGIN TRY
                  IF @P_START_DATE_TMP <> 'N/A'
                     SELECT @ICNT = count_big(ROWID)
                     FROM HRP.HRA_OTMSIGN
                     WHERE 
                        HRA_OTMSIGN.EMP_NO = @SEMPNO AND 
                        HRA_OTMSIGN.OTM_NO LIKE 'OTM%' AND 
                        HRA_OTMSIGN.STATUS NOT IN (  'N'/*排除不准*/ ) AND 
                        (@P_START_DATE_TMP = ssma_oracle.to_char_date(HRA_OTMSIGN.START_DATE_TMP, 'yyyy-mm-dd') OR (@P_END_DATE = ssma_oracle.to_char_date(HRA_OTMSIGN.END_DATE, 'yyyy-mm-dd') AND @P_START_DATE = ssma_oracle.to_char_date(HRA_OTMSIGN.START_DATE, 'yyyy-mm-dd')))
                  ELSE 
                     SELECT @ICNT = count_big(ROWID)
                     FROM HRP.HRA_OTMSIGN
                     WHERE 
                        HRA_OTMSIGN.EMP_NO = @SEMPNO AND 
                        HRA_OTMSIGN.OTM_NO LIKE 'OTM%' AND 
                        HRA_OTMSIGN.STATUS NOT IN (  'N'/*排除不准*/ ) AND 
                        @P_END_DATE = ssma_oracle.to_char_date(HRA_OTMSIGN.END_DATE, 'yyyy-mm-dd')
                  /*AND (p_start_date || p_start_time) BETWEEN (to_char(start_date,'yyyy-mm-dd')|| start_time) AND  (to_char(END_date,'yyyy-mm-dd')||end_time);*/
               END TRY

               BEGIN CATCH

                  DECLARE
                     @errornumber$7 int

                  SET @errornumber$7 = ERROR_NUMBER()

                  DECLARE
                     @errormessage$7 nvarchar(4000)

                  SET @errormessage$7 = ERROR_MESSAGE()

                  DECLARE
                     @exceptionidentifier$7 nvarchar(4000)

                  SELECT @exceptionidentifier$7 = ssma_oracle.db_error_get_oracle_exception_id(@errormessage$7, @errornumber$7)

                  IF (@exceptionidentifier$7 LIKE N'ORA-00100%')
                     SET @ICNT = 0
                  ELSE 
                     BEGIN
                        IF (@exceptionidentifier$7 IS NOT NULL)
                           BEGIN
                              IF @errornumber$7 = 59998
                                 RAISERROR(59998, 16, 1, @exceptionidentifier$7)
                              ELSE 
                                 RAISERROR(59999, 16, 1, @exceptionidentifier$7)
                           END
                        ELSE 
                           BEGIN
                              EXECUTE ssma_oracle.ssma_rethrowerror
                           END
                     END

               END CATCH

            END

            IF @ICNT > 0
               BEGIN

                  SET @RTNCODE = 10

                  GOTO CONTINUE_FOREACH1

               END

            /*-積休申請不可請產假-多機構沒差一並判斷*/
            BEGIN

               BEGIN TRY
                  SELECT @ICNT = count_big(ROWID)
                  FROM HRP.HRA_EVCREC
                  WHERE 
                     HRA_EVCREC.EMP_NO = @SEMPNO AND 
                     (ISNULL(@P_START_DATE, '') + ISNULL(@P_START_TIME, '')) BETWEEN (ISNULL(ssma_oracle.to_char_date(HRA_EVCREC.START_DATE, 'yyyy-mm-dd'), '') + ISNULL(HRA_EVCREC.START_TIME, '')) AND (ISNULL(ssma_oracle.to_char_date(HRA_EVCREC.END_DATE, 'yyyy-mm-dd'), '') + ISNULL(HRA_EVCREC.END_TIME, '')) AND 
                     HRA_EVCREC.STATUS IN ( 'U', 'Y' ) AND 
                     HRA_EVCREC.VAC_TYPE = 'I'
               END TRY

               BEGIN CATCH

                  DECLARE
                     @errornumber$8 int

                  SET @errornumber$8 = ERROR_NUMBER()

                  DECLARE
                     @errormessage$8 nvarchar(4000)

                  SET @errormessage$8 = ERROR_MESSAGE()

                  DECLARE
                     @exceptionidentifier$8 nvarchar(4000)

                  SELECT @exceptionidentifier$8 = ssma_oracle.db_error_get_oracle_exception_id(@errormessage$8, @errornumber$8)

                  IF (@exceptionidentifier$8 LIKE N'ORA-00100%')
                     SET @ICNT = 0
                  ELSE 
                     BEGIN
                        IF (@exceptionidentifier$8 IS NOT NULL)
                           BEGIN
                              IF @errornumber$8 = 59998
                                 RAISERROR(59998, 16, 1, @exceptionidentifier$8)
                              ELSE 
                                 RAISERROR(59999, 16, 1, @exceptionidentifier$8)
                           END
                        ELSE 
                           BEGIN
                              EXECUTE ssma_oracle.ssma_rethrowerror
                           END
                     END

               END CATCH

            END

            IF @ICNT > 0
               BEGIN

                  SET @RTNCODE = 14

                  GOTO CONTINUE_FOREACH1

               END

            /*103.09 by sphinx 當日應出勤班時數+當日加班單時數 +該筆積休單時數不可大於12小時*/
            BEGIN

               BEGIN TRY
                  /* 當日班表應出勤時數*/
                  IF @P_START_DATE_TMP <> 'N/A'
                     SELECT @SWORKHRS = HRA_CLASSMST.WORK_HRS
                     FROM HRP.HRA_CLASSMST
                     WHERE HRA_CLASSMST.CLASS_CODE = HRP.EHRPHRAFUNC_PKG$F_GETCLASSKIND(@P_EMP_NO, ssma_oracle.to_date2(@P_START_DATE_TMP, 'YYYY-MM-DD'), @SORGANTYPE)
                  ELSE 
                     SELECT @SWORKHRS = HRA_CLASSMST.WORK_HRS
                     FROM HRP.HRA_CLASSMST
                     WHERE HRA_CLASSMST.CLASS_CODE = HRP.EHRPHRAFUNC_PKG$F_GETCLASSKIND(@P_EMP_NO, ssma_oracle.to_date2(@P_START_DATE, 'YYYY-MM-DD'), @SORGANTYPE)
               END TRY

               BEGIN CATCH

                  DECLARE
                     @errornumber$9 int

                  SET @errornumber$9 = ERROR_NUMBER()

                  DECLARE
                     @errormessage$9 nvarchar(4000)

                  SET @errormessage$9 = ERROR_MESSAGE()

                  DECLARE
                     @exceptionidentifier$9 nvarchar(4000)

                  SELECT @exceptionidentifier$9 = ssma_oracle.db_error_get_oracle_exception_id(@errormessage$9, @errornumber$9)

                  IF (@exceptionidentifier$9 LIKE N'ORA-00100%')
                     SET @SWORKHRS = 0
                  ELSE 
                     BEGIN
                        IF (@exceptionidentifier$9 IS NOT NULL)
                           BEGIN
                              IF @errornumber$9 = 59998
                                 RAISERROR(59998, 16, 1, @exceptionidentifier$9)
                              ELSE 
                                 RAISERROR(59999, 16, 1, @exceptionidentifier$9)
                           END
                        ELSE 
                           BEGIN
                              EXECUTE ssma_oracle.ssma_rethrowerror
                           END
                     END

               END CATCH

            END

            /*當日積休單時數*/
            BEGIN

               BEGIN TRY
                  IF @P_START_DATE_TMP <> 'N/A'
                     SELECT @STOTADDHRS = sum(HRA_OFFREC.SOTM_HRS)
                     FROM HRP.HRA_OFFREC
                     WHERE 
                        ssma_oracle.to_char_date(isnull(HRA_OFFREC.START_DATE_TMP, HRA_OFFREC.START_DATE), 'yyyy-mm-dd') = @P_START_DATE_TMP AND 
                        HRA_OFFREC.STATUS <> 'N' AND 
                        HRA_OFFREC.ITEM_TYPE = 'A' AND 
                        HRA_OFFREC.EMP_NO = @P_EMP_NO
                  ELSE 
                     SELECT @STOTADDHRS = sum(HRA_OFFREC.SOTM_HRS)
                     FROM HRP.HRA_OFFREC
                     WHERE 
                        ssma_oracle.to_char_date(isnull(HRA_OFFREC.START_DATE_TMP, HRA_OFFREC.START_DATE), 'yyyy-mm-dd') = @P_START_DATE AND 
                        HRA_OFFREC.STATUS <> 'N' AND 
                        HRA_OFFREC.ITEM_TYPE = 'A' AND 
                        HRA_OFFREC.EMP_NO = @P_EMP_NO
               END TRY

               BEGIN CATCH

                  DECLARE
                     @errornumber$10 int

                  SET @errornumber$10 = ERROR_NUMBER()

                  DECLARE
                     @errormessage$10 nvarchar(4000)

                  SET @errormessage$10 = ERROR_MESSAGE()

                  DECLARE
                     @exceptionidentifier$10 nvarchar(4000)

                  SELECT @exceptionidentifier$10 = ssma_oracle.db_error_get_oracle_exception_id(@errormessage$10, @errornumber$10)

                  IF (@exceptionidentifier$10 LIKE N'ORA-00100%')
                     SET @STOTADDHRS = 0
                  ELSE 
                     BEGIN
                        IF (@exceptionidentifier$10 IS NOT NULL)
                           BEGIN
                              IF @errornumber$10 = 59998
                                 RAISERROR(59998, 16, 1, @exceptionidentifier$10)
                              ELSE 
                                 RAISERROR(59999, 16, 1, @exceptionidentifier$10)
                           END
                        ELSE 
                           BEGIN
                              EXECUTE ssma_oracle.ssma_rethrowerror
                           END
                     END

               END CATCH

            END

            IF @STOTADDHRS IS NULL
               SET @STOTADDHRS = 0

            
            /*
            *    20170427 調整 一例一休 休息日:<4 列入4 ,>4 <8 列入8,>8  列入12.  國定假日:>8之後列入
            *   20180725 108978 增加ZQ
            */
            BEGIN

               BEGIN TRY
                  SELECT @STOTMONADD/* 當月積休單總時數(含在途)*/ = isnull(sum(
                     CASE 
                        WHEN TT.S_CLASS = 'ZZ' OR isnull(TT.S_CLASS, 'ZZ') IS NULL THEN (TT.SONEOTT + TT.SONEOSS + TT.SONEUU)
                        WHEN TT.S_CLASS = 'ZQ' OR isnull(TT.S_CLASS, 'ZQ') IS NULL THEN (TT.SONEOTT + TT.SONEOSS + TT.SONEUU)
                        WHEN TT.S_CLASS = 'ZY' OR isnull(TT.S_CLASS, 'ZY') IS NULL THEN (TT.SONEOTT + TT.SONEOSS + TT.SONEUU)
                        ELSE TT.SOTM_HRS
                     END), 0)
                  FROM 
                     (
                        SELECT 
                           
                              (
                                 SELECT HRA_CLASSSCH_VIEW.CLASS_CODE
                                 FROM HRP.HRA_CLASSSCH_VIEW
                                 WHERE HRA_CLASSSCH_VIEW.EMP_NO = HRA_OFFREC.EMP_NO AND HRA_CLASSSCH_VIEW.ATT_DATE = ssma_oracle.to_char_date(isnull(HRA_OFFREC.START_DATE_TMP, HRA_OFFREC.START_DATE), 'yyyy-mm-dd')
                              ) AS S_CLASS, 
                           HRA_OFFREC.OTM_HRS, 
                           HRA_OFFREC.SONEO, 
                           HRA_OFFREC.SONEOTT, 
                           HRA_OFFREC.SONEOSS, 
                           HRA_OFFREC.SOTM_HRS, 
                           HRA_OFFREC.SONEUU
                        FROM HRP.HRA_OFFREC
                        WHERE /*20250219 用應出勤日年月確認加班時數  WHERE TO_CHAR(NVL(Start_Date_Tmp,start_date),'yyyy-mm') = SUBSTR(p_start_date, 1, 7)*/
                           ssma_oracle.to_char_date(isnull(HRA_OFFREC.START_DATE_TMP, HRA_OFFREC.START_DATE), 'yyyy-mm') = substring(@P_START_DATE_TMP, 1, 7) AND 
                           HRA_OFFREC.STATUS <> 'N' AND 
                           HRA_OFFREC.ITEM_TYPE = 'A' AND 
                           HRA_OFFREC.EMP_NO = @P_EMP_NO
                     )  AS TT
               END TRY

               BEGIN CATCH

                  DECLARE
                     @errornumber$11 int

                  SET @errornumber$11 = ERROR_NUMBER()

                  DECLARE
                     @errormessage$11 nvarchar(4000)

                  SET @errormessage$11 = ERROR_MESSAGE()

                  DECLARE
                     @exceptionidentifier$11 nvarchar(4000)

                  SELECT @exceptionidentifier$11 = ssma_oracle.db_error_get_oracle_exception_id(@errormessage$11, @errornumber$11)

                  IF (@exceptionidentifier$11 LIKE N'ORA-00100%')
                     SET @STOTMONADD = 0
                  ELSE 
                     BEGIN
                        IF (@exceptionidentifier$11 IS NOT NULL)
                           BEGIN
                              IF @errornumber$11 = 59998
                                 RAISERROR(59998, 16, 1, @exceptionidentifier$11)
                              ELSE 
                                 RAISERROR(59999, 16, 1, @exceptionidentifier$11)
                           END
                        ELSE 
                           BEGIN
                              EXECUTE ssma_oracle.ssma_rethrowerror
                           END
                     END

               END CATCH

            END

            
            /*
            *    
            *           BEGIN
            *       	    SELECT SUM(SOTM_HRS)
            *       		   INTO  sTotMonAdd  -- 當月積休單總時數(含在途)
            *       		   FROM HRA_OFFREC
            *             WHERE TO_CHAR(start_date,'yyyy-mm')=  SUBSTR(p_start_date ,1,7)
            *               AND status<>'N'
            *               AND item_type='A'
            *               AND emp_no=p_emp_no;
            *       		EXCEPTION WHEN NO_DATA_FOUND THEN
            *             sTotMonAdd := 0 ;
            *       	  END;
            *
            */
            BEGIN

               BEGIN TRY
                  SELECT @SOTMSIGNHRS/* 當月加班單總時數(含在途)*/ = isnull(sum(HRA_OTMSIGN.OTM_HRS), 0)
                  FROM HRP.HRA_OTMSIGN
                  WHERE /*20250219 用應出勤日年月確認加班時數  WHERE TO_CHAR(NVL(Start_Date_Tmp,start_date),'yyyy-mm')=  SUBSTR(p_start_date ,1,7)*/
                     ssma_oracle.to_char_date(isnull(HRA_OTMSIGN.START_DATE_TMP, HRA_OTMSIGN.START_DATE), 'yyyy-mm') = substring(@P_START_DATE_TMP, 1, 7) AND 
                     HRA_OTMSIGN.STATUS <> 'N' AND 
                     HRA_OTMSIGN.OTM_FLAG = 'B' AND 
                     HRA_OTMSIGN.EMP_NO = @P_EMP_NO
               END TRY

               BEGIN CATCH

                  DECLARE
                     @errornumber$12 int

                  SET @errornumber$12 = ERROR_NUMBER()

                  DECLARE
                     @errormessage$12 nvarchar(4000)

                  SET @errormessage$12 = ERROR_MESSAGE()

                  DECLARE
                     @exceptionidentifier$12 nvarchar(4000)

                  SELECT @exceptionidentifier$12 = ssma_oracle.db_error_get_oracle_exception_id(@errormessage$12, @errornumber$12)

                  IF (@exceptionidentifier$12 LIKE N'ORA-00100%')
                     SET @SOTMSIGNHRS = 0
                  ELSE 
                     BEGIN
                        IF (@exceptionidentifier$12 IS NOT NULL)
                           BEGIN
                              IF @errornumber$12 = 59998
                                 RAISERROR(59998, 16, 1, @exceptionidentifier$12)
                              ELSE 
                                 RAISERROR(59999, 16, 1, @exceptionidentifier$12)
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
                  SELECT @SMONCLASSADD/*當月排班超時*/ = (HRA_ATTVAC_VIEW.MON_GETADD + HRA_ATTVAC_VIEW.MON_ADDHRS + HRA_ATTVAC_VIEW.MON_SPCOTM - HRA_ATTVAC_VIEW.MON_CUTOTM + HRA_ATTVAC_VIEW.MON_DUTYHRS)
                  FROM HRP.HRA_ATTVAC_VIEW
                  WHERE /*WHERE hra_attvac_view.sch_ym = SUBSTR(p_start_date ,1,7)*/HRA_ATTVAC_VIEW.SCH_YM = substring(@P_START_DATE_TMP, 1, 7) AND HRA_ATTVAC_VIEW.EMP_NO = @P_EMP_NO
               END TRY

               BEGIN CATCH

                  DECLARE
                     @errornumber$13 int

                  SET @errornumber$13 = ERROR_NUMBER()

                  DECLARE
                     @errormessage$13 nvarchar(4000)

                  SET @errormessage$13 = ERROR_MESSAGE()

                  DECLARE
                     @exceptionidentifier$13 nvarchar(4000)

                  SELECT @exceptionidentifier$13 = ssma_oracle.db_error_get_oracle_exception_id(@errormessage$13, @errornumber$13)

                  IF (@exceptionidentifier$13 LIKE N'ORA-00100%')
                     SET @SMONCLASSADD = 0
                  ELSE 
                     BEGIN
                        IF (@exceptionidentifier$13 IS NOT NULL)
                           BEGIN
                              IF @errornumber$13 = 59998
                                 RAISERROR(59998, 16, 1, @exceptionidentifier$13)
                              ELSE 
                                 RAISERROR(59999, 16, 1, @exceptionidentifier$13)
                           END
                        ELSE 
                           BEGIN
                              EXECUTE ssma_oracle.ssma_rethrowerror
                           END
                     END

               END CATCH

            END

            /*0301開始加班每月不能超過54HR 108978*/
            IF sysdatetime() >= ssma_oracle.to_date2('20180315', 'YYYY-MM-DD')
               BEGIN
                  
                  /*
                  *   IF  ((sOtmhrs+sWorkHrs+sTotAddHrs)> 12) OR (sOtmsignHrs+sTotMonAdd+sMonClassAdd+sOtmhrs>54) THEN
                  *   20190301 by108482 因改四週排班，排除班表超時工時
                  */
                  IF ((@SOTMHRS + @SWORKHRS + @STOTADDHRS) > 12) OR (@SOTMSIGNHRS + @STOTMONADD + /*sMonClassAdd+*/@SOTMHRS > 54)
                     BEGIN

                        SET @RTNCODE = 15

                        GOTO CONTINUE_FOREACH1

                     END
               END
            ELSE 
               BEGIN
                  IF ((@SOTMHRS + @SWORKHRS + @STOTADDHRS) > 12) OR (@STOTMONADD + @SMONCLASSADD + @SOTMHRS > 46)
                     BEGIN

                        SET @RTNCODE = 15

                        GOTO CONTINUE_FOREACH1

                     END
               END

            IF (@RTNCODE = 0)
               BEGIN

                  
                  /*
                  *   20250219 用應出勤日年月確認加班時數
                  *   RtnCode := Check3MonthOtmhrs(p_emp_no,p_start_date, p_otm_hrs,SOrganType);
                  */
                  SET @RTNCODE = HRP.EHRPHRA12_PKG$CHECK3MONTHOTMHRS(@P_EMP_NO, @P_START_DATE_TMP, @P_OTM_HRS, @SORGANTYPE)

                  IF (@RTNCODE = 16)
                     BEGIN

                        SET @RTNCODE = 16

                        GOTO CONTINUE_FOREACH1

                     END

               END

            
            /*
            *   -判別是否為上班時間積休
            *   check 積休開放日
            */
            IF @P_END_TIME = '0000'
               SET @I_END_DATE = @P_START_DATE
            ELSE 
               SET @I_END_DATE = @P_END_DATE

            BEGIN

               BEGIN TRY
                  SELECT @ICNT = count_big(ROWID)
                  FROM HRP.HR_CODEDTL
                  WHERE 
                     HR_CODEDTL.CODE_TYPE = 'HRA53' AND 
                     HR_CODEDTL.CODE_NAME = @P_START_DATE AND 
                     HR_CODEDTL.CODE_NAME = @I_END_DATE
               END TRY

               BEGIN CATCH

                  DECLARE
                     @errornumber$14 int

                  SET @errornumber$14 = ERROR_NUMBER()

                  DECLARE
                     @errormessage$14 nvarchar(4000)

                  SET @errormessage$14 = ERROR_MESSAGE()

                  DECLARE
                     @exceptionidentifier$14 nvarchar(4000)

                  SELECT @exceptionidentifier$14 = ssma_oracle.db_error_get_oracle_exception_id(@errormessage$14, @errornumber$14)

                  IF (@exceptionidentifier$14 LIKE N'ORA-00100%')
                     SET @ICNT = 0
                  ELSE 
                     BEGIN
                        IF (@exceptionidentifier$14 IS NOT NULL)
                           BEGIN
                              IF @errornumber$14 = 59998
                                 RAISERROR(59998, 16, 1, @exceptionidentifier$14)
                              ELSE 
                                 RAISERROR(59999, 16, 1, @exceptionidentifier$14)
                           END
                        ELSE 
                           BEGIN
                              EXECUTE ssma_oracle.ssma_rethrowerror
                           END
                     END

               END CATCH

            END

            IF @ICNT = 0
               BEGIN

                  IF @P_START_DATE_TMP <> 'N/A'
                     BEGIN

                        SET @SCLASSKIND = HRP.EHRPHRAFUNC_PKG$F_GETCLASSKIND(@P_EMP_NO, ssma_oracle.to_date2(@P_START_DATE_TMP, 'YYYY-MM-DD'), @SORGANTYPE)

                        SET @SLASTCLASSKIND = HRP.EHRPHRAFUNC_PKG$F_GETCLASSKIND(@P_EMP_NO, DATEADD(D, -1, ssma_oracle.to_date2(@P_START_DATE_TMP, 'YYYY-MM-DD')), @SORGANTYPE)

                     END
                  ELSE 
                     BEGIN

                        SET @SCLASSKIND = HRP.EHRPHRAFUNC_PKG$F_GETCLASSKIND(@P_EMP_NO, ssma_oracle.to_date2(@P_START_DATE, 'YYYY-MM-DD'), @SORGANTYPE)

                        SET @SLASTCLASSKIND = HRP.EHRPHRAFUNC_PKG$F_GETCLASSKIND(@P_EMP_NO, DATEADD(D, -1, ssma_oracle.to_date2(@P_START_DATE, 'YYYY-MM-DD')), @SORGANTYPE)

                        SET @SNEXTCLASSKIND = HRP.EHRPHRAFUNC_PKG$F_GETCLASSKIND(@P_EMP_NO, DATEADD(D, 1, ssma_oracle.to_date2(@P_START_DATE, 'YYYY-MM-DD')), @SORGANTYPE)

                        /*RN提前上班 20181205 108978*/
                        IF (@P_START_TIME >= '2000' AND @P_END_TIME = '0000')
                           BEGIN
                              IF (@SNEXTCLASSKIND = HRP.EHRPHRAFUNC_PKG$F_GETCLASSKIND(@P_EMP_NO, ssma_oracle.to_date2(@P_END_DATE, 'YYYY-MM-DD'), @SORGANTYPE))
                                 SET @SCLASSKIND = HRP.EHRPHRAFUNC_PKG$F_GETCLASSKIND(@P_EMP_NO, ssma_oracle.to_date2(@P_END_DATE, 'YYYY-MM-DD'), @SORGANTYPE)
                           END

                     END

                  BEGIN

                     BEGIN TRY

                        /* 
                        *   SSMA error messages:
                        *   O2SS0404: ROWID column can not be converted in this context because the referenced table has no triggers and ROWID column will not be generated.

                        SELECT @ICNT = count_big(ROWID)
                        FROM HRP.HRA_CLASSDTL
                        WHERE 
                           HRA_CLASSDTL.CHKIN_WKTM > 
                           CASE 
                              WHEN HRA_CLASSDTL.CHKOUT_WKTM = '0000' THEN '2400'
                              ELSE HRA_CLASSDTL.CHKOUT_WKTM
                           END AND 
                           HRA_CLASSDTL.SHIFT_NO <> '4' AND 
                           HRA_CLASSDTL.CLASS_CODE = @SLASTCLASSKIND
                        */



                        DECLARE
                           @db_null_statement int

                     END TRY

                     BEGIN CATCH

                        DECLARE
                           @errornumber$15 int

                        SET @errornumber$15 = ERROR_NUMBER()

                        DECLARE
                           @errormessage$15 nvarchar(4000)

                        SET @errormessage$15 = ERROR_MESSAGE()

                        DECLARE
                           @exceptionidentifier$15 nvarchar(4000)

                        SELECT @exceptionidentifier$15 = ssma_oracle.db_error_get_oracle_exception_id(@errormessage$15, @errornumber$15)

                        IF (@exceptionidentifier$15 LIKE N'ORA-00100%')
                           SET @ICNT = 0
                        ELSE 
                           BEGIN
                              IF (@exceptionidentifier$15 IS NOT NULL)
                                 BEGIN
                                    IF @errornumber$15 = 59998
                                       RAISERROR(59998, 16, 1, @exceptionidentifier$15)
                                    ELSE 
                                       RAISERROR(59999, 16, 1, @exceptionidentifier$15)
                                 END
                              ELSE 
                                 BEGIN
                                    EXECUTE ssma_oracle.ssma_rethrowerror
                                 END
                           END

                     END CATCH

                  END

                  IF @SCLASSKIND = 'N/A'
                     BEGIN

                        SET @RTNCODE = 8

                        GOTO CONTINUE_FOREACH1

                     END
                  ELSE 
                     IF @P_START_DATE_TMP <> 'N/A' AND @SCLASSKIND IN ( 'ZZ', 'ZX', 'ZY', 'ZQ' )
                        GOTO CONTINUE_FOREACH2
                     ELSE 
                        IF @SCLASSKIND IN ( 'ZZ', 'ZX', 'ZY', 'ZQ' ) AND @ICNT = 0
                           GOTO CONTINUE_FOREACH2
                        ELSE 
                           BEGIN

                              
                              /*
                              *   RtnCode :=  ehrphrafunc_pkg.checkClassTime2(p_emp_no,p_start_date,p_start_time,p_end_date,p_end_time,sClassKind,sLastClassKind);
                              *   by108482 20190109 因checkClassTime2判斷有問題，改用checkclass
                              *   RtnCode := checkclass(p_emp_no, p_start_date, p_start_time, p_end_date, p_end_time,SOrganType);
                              *   by108482 20190110 因checkclass判斷有問題，改用checkClassTime
                              */
                              SET @RTNCODE = HRP.EHRPHRAFUNC_PKG$CHECKCLASSTIME(
                                 @P_EMP_NO, 
                                 @P_START_DATE, 
                                 @P_START_TIME, 
                                 @P_END_DATE, 
                                 @P_END_TIME, 
                                 @SCLASSKIND, 
                                 @SLASTCLASSKIND)

                              IF @RTNCODE = 1
                                 BEGIN

                                    SET @RTNCODE = 3/*申請時間不符合班表!!存檔失敗!*/

                                    GOTO CONTINUE_FOREACH1

                                 END
                              ELSE 
                                 IF (@RTNCODE IS NULL)
                                    BEGIN

                                       SET @RTNCODE = 3

                                       GOTO CONTINUE_FOREACH1

                                    END
                                 ELSE 
                                    IF @RTNCODE = 7
                                       BEGIN

                                          SET @RTNCODE = 8/*您尚未排班!!存檔失敗!*/

                                          GOTO CONTINUE_FOREACH1

                                       END
                                    ELSE 
                                       BEGIN
                                          IF @RTNCODE = 8
                                             BEGIN

                                                SET @RTNCODE = 3

                                                GOTO CONTINUE_FOREACH1

                                             END
                                       END

                           END

               END

            DECLARE
               @db_null_statement$2 int

            CONTINUE_FOREACH2:

            DECLARE
               @db_null_statement$3 int

            /*----------------------- 加班簽到 -------------------------*/
            BEGIN

               BEGIN TRY
                  SELECT @ICNT = count_big(*)
                  FROM HRP.HRA_OTMSIGN
                  WHERE 
                     HRA_OTMSIGN.EMP_NO = @SEMPNO AND 
                     ((@SSTART BETWEEN ISNULL(ssma_oracle.to_char_date(HRA_OTMSIGN.START_DATE, 'YYYY-MM-DD'), '') + ISNULL(HRA_OTMSIGN.START_TIME, '') AND ISNULL(ssma_oracle.to_char_date(HRA_OTMSIGN.END_DATE, 'YYYY-MM-DD'), '') + ISNULL(HRA_OTMSIGN.END_TIME, '')) AND (@SEND BETWEEN ISNULL(ssma_oracle.to_char_date(HRA_OTMSIGN.START_DATE, 'YYYY-MM-DD'), '') + ISNULL(HRA_OTMSIGN.START_TIME, '') AND ISNULL(ssma_oracle.to_char_date(HRA_OTMSIGN.END_DATE, 'YYYY-MM-DD'), '') + ISNULL(HRA_OTMSIGN.END_TIME, ''))) AND 
                     substring(HRA_OTMSIGN.OTM_NO, 1, 3) = 'OTS'
               END TRY

               BEGIN CATCH

                  DECLARE
                     @errornumber$16 int

                  SET @errornumber$16 = ERROR_NUMBER()

                  DECLARE
                     @errormessage$16 nvarchar(4000)

                  SET @errormessage$16 = ERROR_MESSAGE()

                  DECLARE
                     @exceptionidentifier$16 nvarchar(4000)

                  SELECT @exceptionidentifier$16 = ssma_oracle.db_error_get_oracle_exception_id(@errormessage$16, @errornumber$16)

                  IF (@exceptionidentifier$16 LIKE N'ORA-00100%')
                     SET @ICNT = 0
                  ELSE 
                     BEGIN
                        IF (@exceptionidentifier$16 IS NOT NULL)
                           BEGIN
                              IF @errornumber$16 = 59998
                                 RAISERROR(59998, 16, 1, @exceptionidentifier$16)
                              ELSE 
                                 RAISERROR(59999, 16, 1, @exceptionidentifier$16)
                           END
                        ELSE 
                           BEGIN
                              EXECUTE ssma_oracle.ssma_rethrowerror
                           END
                     END

               END CATCH

            END

            IF @ICNT = 0
               SET @RTNCODE = 2/* 無簽到時間*/
            ELSE 
               SET @ICHECKCARD = 'Y'/*iCnt<>0,有加班簽到 20181219 by108482*/

            
            /*
            *   ----------------------- 加班簽到 -------------------------
            *   ----------------------- 一般簽到 -------------------------
            */
            IF @RTNCODE = 2
               BEGIN

                  /*-----------Check OnCall-----------*/
                  SET @RTNCODE = 0

                  IF @P_START_DATE_TMP <> 'N/A'
                     BEGIN

                        SET @SCLASSKIND = HRP.EHRPHRAFUNC_PKG$F_GETCLASSKIND(@P_EMP_NO, ssma_oracle.to_date2(@P_START_DATE_TMP, 'yyyy-mm-dd'), @SORGANTYPE)

                        BEGIN

                           BEGIN TRY
                              SELECT @ICHKINWKTM = HRA_CLASSDTL.CHKIN_WKTM, @ICHKOUTWKTM = HRA_CLASSDTL.CHKOUT_WKTM
                              FROM HRP.HRA_CLASSDTL
                              WHERE HRA_CLASSDTL.CLASS_CODE = @SCLASSKIND AND HRA_CLASSDTL.SHIFT_NO = '1'
                           END TRY

                           BEGIN CATCH

                              DECLARE
                                 @errornumber$17 int

                              SET @errornumber$17 = ERROR_NUMBER()

                              DECLARE
                                 @errormessage$17 nvarchar(4000)

                              SET @errormessage$17 = ERROR_MESSAGE()

                              DECLARE
                                 @exceptionidentifier$17 nvarchar(4000)

                              SELECT @exceptionidentifier$17 = ssma_oracle.db_error_get_oracle_exception_id(@errormessage$17, @errornumber$17)

                              IF (@exceptionidentifier$17 LIKE N'ORA-00100%')
                                 BEGIN

                                    SET @ICHKINWKTM = 0

                                    SET @ICHKOUTWKTM = 0

                                 END
                              ELSE 
                                 BEGIN
                                    IF (@exceptionidentifier$17 IS NOT NULL)
                                       BEGIN
                                          IF @errornumber$17 = 59998
                                             RAISERROR(59998, 16, 1, @exceptionidentifier$17)
                                          ELSE 
                                             RAISERROR(59999, 16, 1, @exceptionidentifier$17)
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
                              SELECT @ICNT = count_big(*)
                              FROM HRP.HRA_CADSIGN
                              WHERE 
                                 HRA_CADSIGN.EMP_NO = @P_EMP_NO AND 
                                 ssma_oracle.to_char_date(HRA_CADSIGN.ATT_DATE, 'yyyy-mm-dd') = @P_START_DATE_TMP AND 
                                 @SSTART >= 
                                 CASE 
                                    WHEN @ICHKINWKTM < @ICHKOUTWKTM AND HRA_CADSIGN.CHKIN_CARD > HRA_CADSIGN.CHKOUT_CARD THEN ISNULL(ssma_oracle.to_char_date(DATEADD(D, -1, HRA_CADSIGN.ATT_DATE), 'yyyy-mm-dd'), '') + ISNULL(HRA_CADSIGN.CHKIN_CARD, '')
                                    ELSE ISNULL(ssma_oracle.to_char_date(HRA_CADSIGN.ATT_DATE, 'yyyy-mm-dd'), '') + ISNULL(HRA_CADSIGN.CHKIN_CARD, '')
                                 END AND 
                                 (@SEND BETWEEN 
                                 CASE 
                                    WHEN @ICHKINWKTM < @ICHKOUTWKTM AND HRA_CADSIGN.CHKIN_CARD > HRA_CADSIGN.CHKOUT_CARD THEN ISNULL(ssma_oracle.to_char_date(DATEADD(D, -1, HRA_CADSIGN.ATT_DATE), 'yyyy-mm-dd'), '') + ISNULL(HRA_CADSIGN.CHKIN_CARD, '')
                                    ELSE ISNULL(ssma_oracle.to_char_date(HRA_CADSIGN.ATT_DATE, 'yyyy-mm-dd'), '') + ISNULL(HRA_CADSIGN.CHKIN_CARD, '')
                                 END AND 
                                 CASE 
                                    WHEN @ICHKINWKTM > @ICHKOUTWKTM THEN ISNULL(ssma_oracle.to_char_date(DATEADD(D, 1, HRA_CADSIGN.ATT_DATE), 'yyyy-mm-dd'), '') + ISNULL(HRA_CADSIGN.CHKOUT_CARD, '')
                                    ELSE ISNULL(ssma_oracle.to_char_date(HRA_CADSIGN.ATT_DATE, 'yyyy-mm-dd'), '') + ISNULL(HRA_CADSIGN.CHKOUT_CARD, '')
                                 END)
                           END TRY

                           
                           /*
                           *   20191014 by108482 原寫法僅檢核當天是否有打卡記錄，未檢核申請的時間起迄是否符合打卡的時間
                           *   SELECT COUNT(*)
                           *                 INTO iCnt
                           *                 FROM hra_cadsign
                           *                WHERE emp_no = p_emp_no
                           *                  AND to_char(att_date, 'yyyy-mm-dd') = p_start_date_tmp;
                           */
                           BEGIN CATCH

                              DECLARE
                                 @errornumber$18 int

                              SET @errornumber$18 = ERROR_NUMBER()

                              DECLARE
                                 @errormessage$18 nvarchar(4000)

                              SET @errormessage$18 = ERROR_MESSAGE()

                              DECLARE
                                 @exceptionidentifier$18 nvarchar(4000)

                              SELECT @exceptionidentifier$18 = ssma_oracle.db_error_get_oracle_exception_id(@errormessage$18, @errornumber$18)

                              IF (@exceptionidentifier$18 LIKE N'ORA-00100%')
                                 SET @ICNT = 0
                              ELSE 
                                 BEGIN
                                    IF (@exceptionidentifier$18 IS NOT NULL)
                                       BEGIN
                                          IF @errornumber$18 = 59998
                                             RAISERROR(59998, 16, 1, @exceptionidentifier$18)
                                          ELSE 
                                             RAISERROR(59999, 16, 1, @exceptionidentifier$18)
                                       END
                                    ELSE 
                                       BEGIN
                                          EXECUTE ssma_oracle.ssma_rethrowerror
                                       END
                                 END

                           END CATCH

                        END

                        
                        /*
                        *   若查無記錄再次檢核
                        *   IF iCnt = 0 AND p_start_time > p_end_time THEN by108482 20210820 不卡時間條件
                        *   20250718 by108482區分RN班和其他跨夜班打卡檢核
                        */
                        IF @ICNT = 0
                           SELECT @ICNT = count_big(*)
                           FROM HRP.HRA_CADSIGN
                           WHERE 
                              HRA_CADSIGN.EMP_NO = @P_EMP_NO AND 
                              ssma_oracle.to_char_date(HRA_CADSIGN.ATT_DATE, 'yyyy-mm-dd') = @P_START_DATE_TMP AND 
                              HRA_CADSIGN.CHKIN_CARD > HRA_CADSIGN.CHKOUT_CARD/*20230922增 by108482 嚴謹檢核*/ AND 
                              @SSTART >= 
                              CASE HRA_CADSIGN.CLASS_CODE
                                 WHEN 'RN' THEN ISNULL(ssma_oracle.to_char_date(DATEADD(D, -1, HRA_CADSIGN.ATT_DATE), 'yyyy-mm-dd'), '') + ISNULL(HRA_CADSIGN.CHKIN_CARD, '')
                                 ELSE ISNULL(ssma_oracle.to_char_date(HRA_CADSIGN.ATT_DATE, 'yyyy-mm-dd'), '') + ISNULL(HRA_CADSIGN.CHKIN_CARD, '')
                              END AND 
                              @SEND <= 
                              CASE HRA_CADSIGN.CLASS_CODE
                                 WHEN 'RN' THEN ISNULL(ssma_oracle.to_char_date(HRA_CADSIGN.ATT_DATE, 'yyyy-mm-dd'), '') + ISNULL(HRA_CADSIGN.CHKOUT_CARD, '')
                                 ELSE ISNULL(ssma_oracle.to_char_date(DATEADD(D, 1, HRA_CADSIGN.ATT_DATE), 'yyyy-mm-dd'), '') + ISNULL(HRA_CADSIGN.CHKOUT_CARD, '')
                              END

                     END
                  ELSE 
                     BEGIN

                        /*108154 20181207 RN班申請加班費*/
                        SET @SCLASSKIND = HRP.EHRPHRAFUNC_PKG$F_GETCLASSKIND(@P_EMP_NO, ssma_oracle.to_date2(@P_START_DATE, 'yyyy-mm-dd'), @SORGANTYPE)

                        SET @SNEXTCLASSKIND = HRP.EHRPHRAFUNC_PKG$F_GETCLASSKIND(@P_EMP_NO, DATEADD(D, 1, ssma_oracle.to_date2(@P_START_DATE, 'yyyy-mm-dd')), @SORGANTYPE)

                        /*108482 20190121 RN班提前或延後加班，start_time都不會是0000，若start_time為0000則需跑else的SQL*/
                        IF ((@SCLASSKIND = 'RN' OR @SNEXTCLASSKIND = 'RN') AND @P_START_TIME <> '0000')
                           BEGIN

                              BEGIN TRY
                                 SELECT @ICNT = count_big(*)
                                 FROM HRP.HRA_CADSIGN
                                 WHERE 
                                    HRA_CADSIGN.EMP_NO = @P_EMP_NO AND 
                                    (@SEND BETWEEN ISNULL(ssma_oracle.to_char_date(DATEADD(D, -1, HRA_CADSIGN.ATT_DATE), 'yyyy-mm-dd'), '') + ISNULL(HRA_CADSIGN.CHKIN_CARD, '') AND (ISNULL(ssma_oracle.to_char_date(HRA_CADSIGN.ATT_DATE, 'yyyy-mm-dd'), '') + ISNULL(HRA_CADSIGN.CHKOUT_CARD, ''))) AND 
                                    (@SSTART >= ISNULL(ssma_oracle.to_char_date(DATEADD(D, -1, HRA_CADSIGN.ATT_DATE), 'yyyy-mm-dd'), '') + ISNULL(HRA_CADSIGN.CHKIN_CARD, ''))
                              END TRY

                              BEGIN CATCH

                                 DECLARE
                                    @errornumber$19 int

                                 SET @errornumber$19 = ERROR_NUMBER()

                                 DECLARE
                                    @errormessage$19 nvarchar(4000)

                                 SET @errormessage$19 = ERROR_MESSAGE()

                                 DECLARE
                                    @exceptionidentifier$19 nvarchar(4000)

                                 SELECT @exceptionidentifier$19 = ssma_oracle.db_error_get_oracle_exception_id(@errormessage$19, @errornumber$19)

                                 IF (@exceptionidentifier$19 LIKE N'ORA-00100%')
                                    SET @ICNT = 0
                                 ELSE 
                                    BEGIN
                                       IF (@exceptionidentifier$19 IS NOT NULL)
                                          BEGIN
                                             IF @errornumber$19 = 59998
                                                RAISERROR(59998, 16, 1, @exceptionidentifier$19)
                                             ELSE 
                                                RAISERROR(59999, 16, 1, @exceptionidentifier$19)
                                          END
                                       ELSE 
                                          BEGIN
                                             EXECUTE ssma_oracle.ssma_rethrowerror
                                          END
                                    END

                              END CATCH

                           END
                        ELSE 
                           BEGIN

                              BEGIN TRY
                                 SELECT @ICNT = count_big(*)
                                 FROM HRP.HRA_CADSIGN
                                 WHERE 
                                    HRA_CADSIGN.EMP_NO = @P_EMP_NO AND 
                                    (@SEND BETWEEN ISNULL(ssma_oracle.to_char_date(HRA_CADSIGN.ATT_DATE, 'yyyy-mm-dd'), '') + ISNULL(HRA_CADSIGN.CHKIN_CARD, '') AND 
                                    CASE 
                                       WHEN HRA_CADSIGN.NIGHT_FLAG = 'Y' THEN (ISNULL(ssma_oracle.to_char_date(DATEADD(D, 1, HRA_CADSIGN.ATT_DATE), 'yyyy-mm-dd'), '') + ISNULL(HRA_CADSIGN.CHKOUT_CARD, ''))
                                       ELSE ISNULL(ssma_oracle.to_char_date(HRA_CADSIGN.ATT_DATE, 'yyyy-mm-dd'), '') + ISNULL(HRA_CADSIGN.CHKOUT_CARD, '')
                                    END) AND 
                                    (@SSTART >= ISNULL(ssma_oracle.to_char_date(HRA_CADSIGN.ATT_DATE, 'yyyy-mm-dd'), '') + ISNULL(HRA_CADSIGN.CHKIN_CARD, ''))
                              END TRY

                              BEGIN CATCH

                                 DECLARE
                                    @errornumber$20 int

                                 SET @errornumber$20 = ERROR_NUMBER()

                                 DECLARE
                                    @errormessage$20 nvarchar(4000)

                                 SET @errormessage$20 = ERROR_MESSAGE()

                                 DECLARE
                                    @exceptionidentifier$20 nvarchar(4000)

                                 SELECT @exceptionidentifier$20 = ssma_oracle.db_error_get_oracle_exception_id(@errormessage$20, @errornumber$20)

                                 IF (@exceptionidentifier$20 LIKE N'ORA-00100%')
                                    SET @ICNT = 0
                                 ELSE 
                                    BEGIN
                                       IF (@exceptionidentifier$20 IS NOT NULL)
                                          BEGIN
                                             IF @errornumber$20 = 59998
                                                RAISERROR(59998, 16, 1, @exceptionidentifier$20)
                                             ELSE 
                                                RAISERROR(59999, 16, 1, @exceptionidentifier$20)
                                          END
                                       ELSE 
                                          BEGIN
                                             EXECUTE ssma_oracle.ssma_rethrowerror
                                          END
                                    END

                              END CATCH

                           END

                     END

                  IF @ICNT = 0
                     BEGIN

                        SET @RTNCODE = 2/* 無簽到時間*/

                        GOTO CONTINUE_FOREACH1

                     END

               END

            
            /*
            *   非加班打卡才檢核一般打卡因公因私 20181219 by108482
            *   IF (sStart > '2011-09-010000') THEN
            */
            IF (@SSTART > '2011-09-010000') AND @ICHECKCARD = 'N'
               BEGIN

                  IF @P_START_DATE_TMP <> 'N/A'
                     BEGIN

                        BEGIN TRY
                           SELECT @PCHKINREA = isnull(HRA_CADSIGN.CHKIN_REA, 10), @PCHKOUTREA = isnull(HRA_CADSIGN.CHKOUT_REA, 20), @PWKINTM = ISNULL(ssma_oracle.to_char_date(HRA_CADSIGN.ATT_DATE, 'yyyy-mm-dd'), '') + ISNULL(
                              (
                                 SELECT HRA_CLASSDTL.CHKIN_WKTM
                                 FROM HRP.HRA_CLASSDTL
                                 WHERE HRA_CLASSDTL.CLASS_CODE = HRA_CADSIGN.CLASS_CODE AND HRA_CLASSDTL.SHIFT_NO = HRA_CADSIGN.SHIFT_NO
                              ), ''), @PWKOUTTM = 
                              /*
                              *   TO_CHAR(ATT_DATE, 'yyyy-mm-dd') ||
                              *                      (SELECT CHKOUT_WKTM
                              *                         FROM HRA_CLASSDTL
                              *                        WHERE CLASS_CODE = HRA_CADSIGN.CLASS_CODE
                              *                          AND SHIFT_NO = HRA_CADSIGN.SHIFT_NO)
                              *   108482 20190506 跨夜班需調整日期
                              */
                              CASE 
                                 WHEN 
                                    (
                                       SELECT HRA_CLASSDTL$2.CHKOUT_WKTM
                                       FROM HRP.HRA_CLASSDTL  AS HRA_CLASSDTL$2
                                       WHERE HRA_CLASSDTL$2.CLASS_CODE = HRA_CADSIGN.CLASS_CODE AND HRA_CLASSDTL$2.SHIFT_NO = HRA_CADSIGN.SHIFT_NO
                                    ) < 
                                    (
                                       SELECT HRA_CLASSDTL$3.CHKIN_WKTM
                                       FROM HRP.HRA_CLASSDTL  AS HRA_CLASSDTL$3
                                       WHERE HRA_CLASSDTL$3.CLASS_CODE = HRA_CADSIGN.CLASS_CODE AND HRA_CLASSDTL$3.SHIFT_NO = HRA_CADSIGN.SHIFT_NO
                                    ) THEN ISNULL(ssma_oracle.to_char_date(DATEADD(D, 1, HRA_CADSIGN.ATT_DATE), 'yyyy-mm-dd'), '') + ISNULL(
                                    (
                                       SELECT HRA_CLASSDTL$4.CHKOUT_WKTM
                                       FROM HRP.HRA_CLASSDTL  AS HRA_CLASSDTL$4
                                       WHERE HRA_CLASSDTL$4.CLASS_CODE = HRA_CADSIGN.CLASS_CODE AND HRA_CLASSDTL$4.SHIFT_NO = HRA_CADSIGN.SHIFT_NO
                                    ), '')
                                 ELSE ISNULL(ssma_oracle.to_char_date(HRA_CADSIGN.ATT_DATE, 'yyyy-mm-dd'), '') + ISNULL(
                                    (
                                       SELECT HRA_CLASSDTL$5.CHKOUT_WKTM
                                       FROM HRP.HRA_CLASSDTL  AS HRA_CLASSDTL$5
                                       WHERE HRA_CLASSDTL$5.CLASS_CODE = HRA_CADSIGN.CLASS_CODE AND HRA_CLASSDTL$5.SHIFT_NO = HRA_CADSIGN.SHIFT_NO
                                    ), '')
                              END
                           FROM HRP.HRA_CADSIGN
                           WHERE 
                              HRA_CADSIGN.EMP_NO = @P_EMP_NO AND 
                              ssma_oracle.to_char_date(HRA_CADSIGN.ATT_DATE, 'yyyy-mm-dd') = @P_START_DATE_TMP AND 
                              @SSTART >= 
                              CASE 
                                 WHEN @ICHKINWKTM < @ICHKOUTWKTM AND HRA_CADSIGN.CHKIN_CARD > HRA_CADSIGN.CHKOUT_CARD THEN ISNULL(ssma_oracle.to_char_date(DATEADD(D, -1, HRA_CADSIGN.ATT_DATE), 'yyyy-mm-dd'), '') + ISNULL(HRA_CADSIGN.CHKIN_CARD, '')
                                 ELSE ISNULL(ssma_oracle.to_char_date(HRA_CADSIGN.ATT_DATE, 'yyyy-mm-dd'), '') + ISNULL(HRA_CADSIGN.CHKIN_CARD, '')
                              END AND 
                              (@SEND BETWEEN 
                              CASE 
                                 WHEN @ICHKINWKTM < @ICHKOUTWKTM AND HRA_CADSIGN.CHKIN_CARD > HRA_CADSIGN.CHKOUT_CARD THEN ISNULL(ssma_oracle.to_char_date(DATEADD(D, -1, HRA_CADSIGN.ATT_DATE), 'yyyy-mm-dd'), '') + ISNULL(HRA_CADSIGN.CHKIN_CARD, '')
                                 ELSE ISNULL(ssma_oracle.to_char_date(HRA_CADSIGN.ATT_DATE, 'yyyy-mm-dd'), '') + ISNULL(HRA_CADSIGN.CHKIN_CARD, '')
                              END AND 
                              CASE 
                                 WHEN @ICHKINWKTM > @ICHKOUTWKTM THEN ISNULL(ssma_oracle.to_char_date(DATEADD(D, 1, HRA_CADSIGN.ATT_DATE), 'yyyy-mm-dd'), '') + ISNULL(HRA_CADSIGN.CHKOUT_CARD, '')
                                 ELSE ISNULL(ssma_oracle.to_char_date(HRA_CADSIGN.ATT_DATE, 'yyyy-mm-dd'), '') + ISNULL(HRA_CADSIGN.CHKOUT_CARD, '')
                              END)
                        END TRY

                        BEGIN CATCH

                           DECLARE
                              @errornumber$21 int

                           SET @errornumber$21 = ERROR_NUMBER()

                           DECLARE
                              @errormessage$21 nvarchar(4000)

                           SET @errormessage$21 = ERROR_MESSAGE()

                           DECLARE
                              @exceptionidentifier$21 nvarchar(4000)

                           SELECT @exceptionidentifier$21 = ssma_oracle.db_error_get_oracle_exception_id(@errormessage$21, @errornumber$21)

                           IF (@exceptionidentifier$21 LIKE N'ORA-00100%')
                              BEGIN

                                 SET @PCHKINREA = '15'

                                 SET @PCHKOUTREA = '25'

                                 SET @PWKOUTTM = @SSTART

                                 SET @PWKINTM = @SEND

                              END
                           ELSE 
                              BEGIN
                                 IF (@exceptionidentifier$21 IS NOT NULL)
                                    BEGIN
                                       IF @errornumber$21 = 59998
                                          RAISERROR(59998, 16, 1, @exceptionidentifier$21)
                                       ELSE 
                                          RAISERROR(59999, 16, 1, @exceptionidentifier$21)
                                    END
                                 ELSE 
                                    BEGIN
                                       EXECUTE ssma_oracle.ssma_rethrowerror
                                    END
                              END

                        END CATCH

                     END
                  ELSE 
                     BEGIN

                        BEGIN TRY
                           
                           /*
                           *   108482 20190125 與檢核是否有打卡記錄的判斷統一
                           *   IF (sClassKind = 'RN') THEN
                           */
                           IF ((@SCLASSKIND = 'RN' OR @SNEXTCLASSKIND = 'RN') AND @P_START_TIME <> '0000')
                              SELECT @PCHKINREA = isnull(HRA_CADSIGN.CHKIN_REA, 10), @PCHKOUTREA = isnull(HRA_CADSIGN.CHKOUT_REA, 20), @PWKINTM = ISNULL(ssma_oracle.to_char_date(HRA_CADSIGN.ATT_DATE, 'yyyy-mm-dd'), '') + ISNULL(
                                 (
                                    SELECT HRA_CLASSDTL.CHKIN_WKTM
                                    FROM HRP.HRA_CLASSDTL
                                    WHERE HRA_CLASSDTL.CLASS_CODE = HRA_CADSIGN.CLASS_CODE AND HRA_CLASSDTL.SHIFT_NO = HRA_CADSIGN.SHIFT_NO
                                 ), ''), @PWKOUTTM = ISNULL(ssma_oracle.to_char_date(HRA_CADSIGN.ATT_DATE, 'yyyy-mm-dd'), '') + ISNULL(
                                 (
                                    SELECT HRA_CLASSDTL$2.CHKOUT_WKTM
                                    FROM HRP.HRA_CLASSDTL  AS HRA_CLASSDTL$2
                                    WHERE HRA_CLASSDTL$2.CLASS_CODE = HRA_CADSIGN.CLASS_CODE AND HRA_CLASSDTL$2.SHIFT_NO = HRA_CADSIGN.SHIFT_NO
                                 ), '')
                              FROM HRP.HRA_CADSIGN
                              WHERE 
                                 HRA_CADSIGN.EMP_NO = @P_EMP_NO AND 
                                 (@SEND BETWEEN ISNULL(ssma_oracle.to_char_date(DATEADD(D, -1, HRA_CADSIGN.ATT_DATE), 'yyyy-mm-dd'), '') + ISNULL(HRA_CADSIGN.CHKIN_CARD, '') AND (ISNULL(ssma_oracle.to_char_date(HRA_CADSIGN.ATT_DATE, 'yyyy-mm-dd'), '') + ISNULL(HRA_CADSIGN.CHKOUT_CARD, ''))) AND 
                                 (@SSTART >= ISNULL(ssma_oracle.to_char_date(DATEADD(D, -1, HRA_CADSIGN.ATT_DATE), 'yyyy-mm-dd'), '') + ISNULL(HRA_CADSIGN.CHKIN_CARD, ''))
                           ELSE 
                              SELECT @PCHKINREA = isnull(HRA_CADSIGN.CHKIN_REA, 10), @PCHKOUTREA = isnull(HRA_CADSIGN.CHKOUT_REA, 20), @PWKINTM = ISNULL(ssma_oracle.to_char_date(HRA_CADSIGN.ATT_DATE, 'yyyy-mm-dd'), '') + ISNULL(
                                 (
                                    SELECT HRA_CLASSDTL.CHKIN_WKTM
                                    FROM HRP.HRA_CLASSDTL
                                    WHERE HRA_CLASSDTL.CLASS_CODE = HRA_CADSIGN.CLASS_CODE AND HRA_CLASSDTL.SHIFT_NO = HRA_CADSIGN.SHIFT_NO
                                 ), ''), @PWKOUTTM = ISNULL(
                                 CASE 
                                    WHEN HRA_CADSIGN.NIGHT_FLAG = 'Y' OR HRA_CADSIGN.CLASS_CODE = 'JB' THEN ssma_oracle.to_char_date(DATEADD(D, 1, HRA_CADSIGN.ATT_DATE), 'yyyy-mm-dd')
                                    ELSE ssma_oracle.to_char_date(HRA_CADSIGN.ATT_DATE, 'yyyy-mm-dd')
                                 END, '') + ISNULL(
                                 (
                                    SELECT HRA_CLASSDTL$2.CHKOUT_WKTM
                                    FROM HRP.HRA_CLASSDTL  AS HRA_CLASSDTL$2
                                    WHERE HRA_CLASSDTL$2.CLASS_CODE = HRA_CADSIGN.CLASS_CODE AND HRA_CLASSDTL$2.SHIFT_NO = HRA_CADSIGN.SHIFT_NO
                                 ), '')
                              FROM HRP.HRA_CADSIGN
                              WHERE 
                                 HRA_CADSIGN.EMP_NO = @P_EMP_NO AND 
                                 (@SEND BETWEEN ISNULL(ssma_oracle.to_char_date(HRA_CADSIGN.ATT_DATE, 'yyyy-mm-dd'), '') + ISNULL(HRA_CADSIGN.CHKIN_CARD, '') AND 
                                 CASE 
                                    WHEN HRA_CADSIGN.NIGHT_FLAG = 'Y' THEN (ISNULL(ssma_oracle.to_char_date(DATEADD(D, 1, HRA_CADSIGN.ATT_DATE), 'yyyy-mm-dd'), '') + ISNULL(HRA_CADSIGN.CHKOUT_CARD, ''))
                                    ELSE ISNULL(ssma_oracle.to_char_date(HRA_CADSIGN.ATT_DATE, 'yyyy-mm-dd'), '') + ISNULL(HRA_CADSIGN.CHKOUT_CARD, '')
                                 END) AND 
                                 (@SSTART >= ISNULL(ssma_oracle.to_char_date(HRA_CADSIGN.ATT_DATE, 'yyyy-mm-dd'), '') + ISNULL(HRA_CADSIGN.CHKIN_CARD, ''))
                        END TRY

                        BEGIN CATCH

                           DECLARE
                              @errornumber$22 int

                           SET @errornumber$22 = ERROR_NUMBER()

                           DECLARE
                              @errormessage$22 nvarchar(4000)

                           SET @errormessage$22 = ERROR_MESSAGE()

                           DECLARE
                              @exceptionidentifier$22 nvarchar(4000)

                           SELECT @exceptionidentifier$22 = ssma_oracle.db_error_get_oracle_exception_id(@errormessage$22, @errornumber$22)

                           IF (@exceptionidentifier$22 LIKE N'ORA-00100%')
                              BEGIN

                                 SET @PCHKINREA = '15'

                                 SET @PCHKOUTREA = '25'

                                 SET @PWKOUTTM = @SSTART

                                 SET @PWKINTM = @SEND

                              END
                           ELSE 
                              BEGIN
                                 IF (@exceptionidentifier$22 IS NOT NULL)
                                    BEGIN
                                       IF @errornumber$22 = 59998
                                          RAISERROR(59998, 16, 1, @exceptionidentifier$22)
                                       ELSE 
                                          RAISERROR(59999, 16, 1, @exceptionidentifier$22)
                                    END
                                 ELSE 
                                    BEGIN
                                       EXECUTE ssma_oracle.ssma_rethrowerror
                                    END
                              END

                        END CATCH

                     END

                  /*延後加班狀況*/
                  IF (@SSTART >= @PWKOUTTM AND @PCHKOUTREA < '25')
                     BEGIN

                        SET @RTNCODE = 13/* 非因公務加班不可申請積休*/

                        GOTO CONTINUE_FOREACH1

                     END

                  /*提前加班狀況*/
                  IF (@SEND <= @PWKINTM AND @PCHKINREA < '15')
                     BEGIN

                        SET @RTNCODE = 13/* 非因公務加班不可申請積休*/

                        GOTO CONTINUE_FOREACH1

                     END

               END

            /*-----------Check OnCall-----------*/
            IF @RTNCODE = 0 AND @SONCALL = 'Y'
               BEGIN

                  SET @RTNCODE = HRP.EHRPHRA12_PKG$CHECKONCALL(
                     @P_EMP_NO, 
                     @P_START_DATE, 
                     @P_START_TIME, 
                     @P_END_DATE, 
                     @P_START_DATE_TMP, 
                     @SORGANTYPE)

                  BEGIN

                     BEGIN TRY
                        SELECT @ICNT2 = count_big(*)
                        FROM HRP.GESD_DORMMST
                        WHERE GESD_DORMMST.EMP_NO = @P_EMP_NO AND GESD_DORMMST.USE_FLAG = 'Y'
                     END TRY

                     BEGIN CATCH

                        DECLARE
                           @errornumber$23 int

                        SET @errornumber$23 = ERROR_NUMBER()

                        DECLARE
                           @errormessage$23 nvarchar(4000)

                        SET @errormessage$23 = ERROR_MESSAGE()

                        DECLARE
                           @exceptionidentifier$23 nvarchar(4000)

                        SELECT @exceptionidentifier$23 = ssma_oracle.db_error_get_oracle_exception_id(@errormessage$23, @errornumber$23)

                        IF (@exceptionidentifier$23 LIKE N'ORA-00100%')
                           SET @ICNT2 = 0
                        ELSE 
                           BEGIN
                              IF (@exceptionidentifier$23 IS NOT NULL)
                                 BEGIN
                                    IF @errornumber$23 = 59998
                                       RAISERROR(59998, 16, 1, @exceptionidentifier$23)
                                    ELSE 
                                       RAISERROR(59999, 16, 1, @exceptionidentifier$23)
                                 END
                              ELSE 
                                 BEGIN
                                    EXECUTE ssma_oracle.ssma_rethrowerror
                                 END
                           END

                     END CATCH

                  END

                  IF @ICNT2 > 0
                     BEGIN

                        SET @RTNCODE = 4/* 住宿不可申請OnCall*/

                        GOTO CONTINUE_FOREACH1

                     END

                  
                  /*
                  *    IF p_start_date_tmp <> 'N/A' AND p_start_date_tmp <> p_start_date 代表 為跨夜申請
                  *    故 ClassKin 要以 p_start_date_tmp 為基準
                  */
                  IF @P_START_DATE_TMP <> 'N/A' AND @P_START_DATE_TMP <> @P_START_DATE
                     SET @SCLASSKIND = HRP.EHRPHRAFUNC_PKG$F_GETCLASSKIND(@P_EMP_NO, ssma_oracle.to_date2(@P_START_DATE_TMP, 'YYYY-MM-DD'), @SORGANTYPE)
                  ELSE 
                     SET @SCLASSKIND = HRP.EHRPHRAFUNC_PKG$F_GETCLASSKIND(@P_EMP_NO, ssma_oracle.to_date2(@P_START_DATE, 'YYYY-MM-DD'), @SORGANTYPE)

                  BEGIN

                     BEGIN TRY

                        PRINT @SCLASSKIND

                        IF @SCLASSKIND = 'N/A'
                           BEGIN

                              SET @RTNCODE = 8/* 申請OnCall之積休日班別須為on call班*/

                              GOTO CONTINUE_FOREACH1

                           END

                        SELECT @ICNT2 = 
                           CASE 
                              WHEN HRA_CLASSDTL.CHKIN_WKTM < HRA_CLASSDTL.CHKOUT_WKTM THEN 
                                 CASE 
                                    WHEN @P_START_TIME BETWEEN HRA_CLASSDTL.CHKIN_WKTM AND HRA_CLASSDTL.CHKOUT_WKTM THEN 1
                                    ELSE 0
                                 END
                              ELSE 
                                 CASE 
                                    WHEN (@P_START_TIME BETWEEN HRA_CLASSDTL.CHKIN_WKTM AND '2400') OR (@P_START_TIME BETWEEN '0000' AND HRA_CLASSDTL.CHKOUT_WKTM) THEN 1
                                    ELSE 0
                                 END
                           END
                        FROM HRP.HRA_CLASSDTL
                        WHERE HRA_CLASSDTL.SHIFT_NO = '4' AND HRA_CLASSDTL.CLASS_CODE = @SCLASSKIND

                     END TRY

                     BEGIN CATCH

                        DECLARE
                           @errornumber$24 int

                        SET @errornumber$24 = ERROR_NUMBER()

                        DECLARE
                           @errormessage$24 nvarchar(4000)

                        SET @errormessage$24 = ERROR_MESSAGE()

                        DECLARE
                           @exceptionidentifier$24 nvarchar(4000)

                        SELECT @exceptionidentifier$24 = ssma_oracle.db_error_get_oracle_exception_id(@errormessage$24, @errornumber$24)

                        IF (@exceptionidentifier$24 LIKE N'ORA-00100%')
                           SET @ICNT2 = 0
                        ELSE 
                           BEGIN
                              IF (@exceptionidentifier$24 IS NOT NULL)
                                 BEGIN
                                    IF @errornumber$24 = 59998
                                       RAISERROR(59998, 16, 1, @exceptionidentifier$24)
                                    ELSE 
                                       RAISERROR(59999, 16, 1, @exceptionidentifier$24)
                                 END
                              ELSE 
                                 BEGIN
                                    EXECUTE ssma_oracle.ssma_rethrowerror
                                 END
                           END

                     END CATCH

                  END

                  IF @ICNT2 = 0
                     BEGIN

                        BEGIN TRY
                           SELECT @ICNT2 = count_big(*)
                           FROM HRP.HR_CODEDTL
                           WHERE HR_CODEDTL.CODE_TYPE = 'HRA79' AND HR_CODEDTL.CODE_NO = 
                              (
                                 SELECT HRE_EMPBAS.DEPT_NO
                                 FROM HRP.HRE_EMPBAS
                                 WHERE HRE_EMPBAS.EMP_NO = @SEMPNO
                              )
                        END TRY

                        BEGIN CATCH

                           DECLARE
                              @errornumber$25 int

                           SET @errornumber$25 = ERROR_NUMBER()

                           DECLARE
                              @errormessage$25 nvarchar(4000)

                           SET @errormessage$25 = ERROR_MESSAGE()

                           DECLARE
                              @exceptionidentifier$25 nvarchar(4000)

                           SELECT @exceptionidentifier$25 = ssma_oracle.db_error_get_oracle_exception_id(@errormessage$25, @errornumber$25)

                           IF (@exceptionidentifier$25 LIKE N'ORA-00100%')
                              SET @ICNT2 = 0
                           ELSE 
                              BEGIN
                                 IF (@exceptionidentifier$25 IS NOT NULL)
                                    BEGIN
                                       IF @errornumber$25 = 59998
                                          RAISERROR(59998, 16, 1, @exceptionidentifier$25)
                                       ELSE 
                                          RAISERROR(59999, 16, 1, @exceptionidentifier$25)
                                    END
                                 ELSE 
                                    BEGIN
                                       EXECUTE ssma_oracle.ssma_rethrowerror
                                    END
                              END

                        END CATCH

                     END

                  IF @ICNT2 = 0
                     BEGIN

                        SET @RTNCODE = 5/* 申請OnCall之積休日班別須為on call班*/

                        GOTO CONTINUE_FOREACH1

                     END

                  
                  /*
                  *   -如果有上班打卡就驗證
                  *    IF p_start_date_tmp <> 'N/A' AND p_start_date_tmp <> p_start_date 代表 為跨夜申請
                  *    以 p_end_date 為基準
                  */
                  BEGIN

                     BEGIN TRY
                        IF @P_START_DATE_TMP <> 'N/A' AND @P_START_DATE_TMP <> @P_START_DATE
                           SELECT @ICNT2 = count_big(*)
                           FROM HRP.HRA_CADSIGN
                           WHERE HRA_CADSIGN.EMP_NO = @P_EMP_NO AND ssma_oracle.to_char_date(HRA_CADSIGN.ATT_DATE, 'YYYY-MM-DD') = @P_START_DATE_TMP
                        ELSE 
                           SELECT @ICNT2 = count_big(*)
                           FROM HRP.HRA_CADSIGN
                           WHERE HRA_CADSIGN.EMP_NO = @P_EMP_NO AND ssma_oracle.to_char_date(HRA_CADSIGN.ATT_DATE, 'YYYY-MM-DD') = @P_START_DATE
                     END TRY

                     BEGIN CATCH

                        DECLARE
                           @errornumber$26 int

                        SET @errornumber$26 = ERROR_NUMBER()

                        DECLARE
                           @errormessage$26 nvarchar(4000)

                        SET @errormessage$26 = ERROR_MESSAGE()

                        DECLARE
                           @exceptionidentifier$26 nvarchar(4000)

                        SELECT @exceptionidentifier$26 = ssma_oracle.db_error_get_oracle_exception_id(@errormessage$26, @errornumber$26)

                        IF (@exceptionidentifier$26 LIKE N'ORA-00100%')
                           SET @ICNT2 = 0
                        ELSE 
                           BEGIN
                              IF (@exceptionidentifier$26 IS NOT NULL)
                                 BEGIN
                                    IF @errornumber$26 = 59998
                                       RAISERROR(59998, 16, 1, @exceptionidentifier$26)
                                    ELSE 
                                       RAISERROR(59999, 16, 1, @exceptionidentifier$26)
                                 END
                              ELSE 
                                 BEGIN
                                    EXECUTE ssma_oracle.ssma_rethrowerror
                                 END
                           END

                     END CATCH

                  END

                  IF @ICNT2 > 0
                     BEGIN

                        BEGIN

                           BEGIN TRY
                              
                              /*
                              *   ON CALL VALIDATE
                              *    IF p_start_date_tmp <> 'N/A' AND p_start_date_tmp <> p_start_date 代表 為跨夜申請
                              *    故 ATT_DATE 要加 1 , 並以 p_end_date 為基準
                              */
                              IF @P_START_DATE_TMP <> 'N/A' AND @P_START_DATE_TMP <> @P_START_DATE
                                 SELECT @ICNT2 = 
                                    CASE 
                                       WHEN ssma_oracle.datediff(ssma_oracle.to_date2(ISNULL(ssma_oracle.to_char_date(max(HRA_OTMSIGN.START_DATE), 'YYYY-MM-DD'), '') + ISNULL(max(HRA_OTMSIGN.START_TIME), ''), 'YYYY-MM-DD HH24MI'), ssma_oracle.to_date2(ISNULL(ssma_oracle.to_char_date(max(HRA_CADSIGN.ATT_DATE), 'YYYY-MM-DD'), '') + ISNULL(max(HRA_CADSIGN.CHKOUT_CARD), ''), 'YYYY-MM-DD HH24MI')) * 60 * 24 > 30 THEN 0
                                       ELSE 1
                                    END
                                 FROM HRP.HRA_OTMSIGN, HRP.HRA_CADSIGN
                                 WHERE 
                                    HRA_CADSIGN.EMP_NO = HRA_OTMSIGN.EMP_NO AND 
                                    ssma_oracle.to_char_date(DATEADD(D, 1, HRA_CADSIGN.ATT_DATE), 'YYYY-MM-DD') = ssma_oracle.to_char_date(HRA_OTMSIGN.START_DATE, 'YYYY-MM-DD') AND 
                                    HRA_OTMSIGN.EMP_NO = @P_EMP_NO AND 
                                    ssma_oracle.to_char_date(HRA_OTMSIGN.START_DATE, 'YYYY-MM-DD') = @P_END_DATE
                              ELSE 
                                 SELECT @ICNT2 = 
                                    CASE 
                                       WHEN isnull(ssma_oracle.datediff(ssma_oracle.to_date2(ISNULL(ssma_oracle.to_char_date(max(HRA_OTMSIGN.START_DATE), 'YYYY-MM-DD'), '') + ISNULL(max(HRA_OTMSIGN.START_TIME), ''), 'YYYY-MM-DD HH24MI'), ssma_oracle.to_date2(ISNULL(ssma_oracle.to_char_date(max(HRA_CADSIGN.ATT_DATE), 'YYYY-MM-DD'), '') + ISNULL(max(HRA_CADSIGN.CHKOUT_CARD), ''), 'YYYY-MM-DD HH24MI')), 0) * 60 * 24 > 30 THEN 0
                                       ELSE 1
                                    END
                                 FROM HRP.HRA_OTMSIGN, HRP.HRA_CADSIGN
                                 WHERE 
                                    HRA_CADSIGN.EMP_NO = HRA_OTMSIGN.EMP_NO AND 
                                    ssma_oracle.to_char_date(HRA_CADSIGN.ATT_DATE, 'YYYY-MM-DD') = ssma_oracle.to_char_date(HRA_OTMSIGN.START_DATE, 'YYYY-MM-DD') AND 
                                    HRA_OTMSIGN.EMP_NO = @P_EMP_NO AND 
                                    ssma_oracle.to_char_date(HRA_OTMSIGN.START_DATE, 'YYYY-MM-DD') = @P_START_DATE
                           END TRY

                           BEGIN CATCH

                              DECLARE
                                 @errornumber$27 int

                              SET @errornumber$27 = ERROR_NUMBER()

                              DECLARE
                                 @errormessage$27 nvarchar(4000)

                              SET @errormessage$27 = ERROR_MESSAGE()

                              DECLARE
                                 @exceptionidentifier$27 nvarchar(4000)

                              SELECT @exceptionidentifier$27 = ssma_oracle.db_error_get_oracle_exception_id(@errormessage$27, @errornumber$27)

                              IF (@exceptionidentifier$27 LIKE N'ORA-00100%')
                                 SET @ICNT2 = 0
                              ELSE 
                                 BEGIN
                                    IF (@exceptionidentifier$27 IS NOT NULL)
                                       BEGIN
                                          IF @errornumber$27 = 59998
                                             RAISERROR(59998, 16, 1, @exceptionidentifier$27)
                                          ELSE 
                                             RAISERROR(59999, 16, 1, @exceptionidentifier$27)
                                       END
                                    ELSE 
                                       BEGIN
                                          EXECUTE ssma_oracle.ssma_rethrowerror
                                       END
                                 END

                           END CATCH

                        END

                        IF @ICNT2 = 0
                           BEGIN

                              SET @RTNCODE = 0

                              GOTO CONTINUE_FOREACH1

                           END
                        ELSE 
                           BEGIN

                              SET @RTNCODE = 6/* 申請OnCall失敗*/

                              GOTO CONTINUE_FOREACH1

                           END

                     END

               END

         END

      /*----------------------- 補休單 -------------------------*/
      DECLARE
         @db_null_statement$4 int

      CONTINUE_FOREACH1:

      DECLARE
         @db_null_statement$5 int

   END
GO
BEGIN TRY
    EXEC sp_addextendedproperty
        N'MS_SSMA_SOURCE', N'HRP.EHRPHRA12_PKG.hraC030',
        N'SCHEMA', N'hrp',
        N'PROCEDURE', N'EHRPHRA12_PKG$HRAC030'
END TRY
BEGIN CATCH
    IF (@@TRANCOUNT > 0) ROLLBACK
    PRINT ERROR_MESSAGE()
END CATCH
GO
