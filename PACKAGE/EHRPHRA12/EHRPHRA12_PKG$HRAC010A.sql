
USE MIS
GO
 IF NOT EXISTS(SELECT * FROM sys.schemas WHERE [name] = N'hrp')      
     EXEC (N'CREATE SCHEMA hrp')                                   
 GO                                                               

USE MIS
GO
IF  EXISTS (SELECT * FROM sys.objects so JOIN sys.schemas sc ON so.schema_id = sc.schema_id WHERE so.name = N'EHRPHRA12_PKG$HRAC010A'  AND sc.name=N'hrp'  AND type in (N'P',N'PC'))
 DROP PROCEDURE [hrp].[EHRPHRA12_PKG$HRAC010A]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE HRP.EHRPHRA12_PKG$HRAC010A  
   @P_OTM_NO varchar(max),
   @P_EMP_NO varchar(max),
   @P_START_DATE varchar(max),
   @P_START_TIME varchar(max),
   @P_END_DATE varchar(max),
   @P_END_TIME varchar(max),
   @P_START_DATE_TMP varchar(max),
   @P_ON_CALL varchar(max),
   @P_STATUS varchar(max),
   @ORGANTYPE_IN varchar(max),
   @P_OTM_HRS varchar(max),
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
         /*
         *   SSMA warning messages:
         *   O2SS0356: Conversion from NUMBER datatype can cause data loss.
         */

         @NCNT float(53), 
         @SORGANTYPE varchar(10) = @ORGANTYPE_IN, 
         @SSTART varchar(20) = ISNULL(@P_START_DATE, '') + ISNULL(@P_START_TIME, ''), 
         @SEND varchar(20) = ISNULL(@P_END_DATE, '') + ISNULL(@P_END_TIME, ''), 
         /*
         *   SSMA warning messages:
         *   O2SS0356: Conversion from NUMBER datatype can cause data loss.
         */

         @SOTMHRS float(53) = CAST(@P_OTM_HRS AS numeric(38, 10)), 
         @SCLASS_CODE varchar(3), 
         @I_END_DATE varchar(10), 
         /*
         *   SSMA warning messages:
         *   O2SS0356: Conversion from NUMBER datatype can cause data loss.
         */

         @ICNT float(53), 
         @ICNT2 int, 
         @SCLASSKIND varchar(3), 
         @SLASTCLASSKIND varchar(3), 
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
         @ICHECKCARD varchar(1)/*註記是否為加班打卡,預設N(非加班打卡) 20181219 by108482*/, 
         @IPOSLEVEL varchar(1)/*確認職等，7職等(含)以上人員不能自行申請加班 20190306 by108482*/, 
         @LIMITDAY varchar(2), 
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

      DECLARE
         /*因 BETWEEN 會比較前後值,故 START + 1 分鐘 , END -1 分鐘 來跳過*/
         @SSTART1 varchar(20) 
            /*
            *   SSMA warning messages:
            *   O2SS0425: Dateadd operation may cause bad performance.
            */
= ssma_oracle.to_char_date(ssma_oracle.dateadd(0.000695, ssma_oracle.to_date2(@SSTART, 'YYYY-MM-DDHH24MI')), 'YYYY-MM-DDHH24MI'), 
         @SEND1 varchar(20) 
            /*
            *   SSMA warning messages:
            *   O2SS0425: Dateadd operation may cause bad performance.
            */
= ssma_oracle.to_char_date(ssma_oracle.dateadd(-0.000694, ssma_oracle.to_date2(@SEND, 'YYYY-MM-DDHH24MI')), 'YYYY-MM-DDHH24MI'), 
         @IRESTSTART varchar(4), 
         @IRESTEND varchar(4), 
         @ICHKINWKTM varchar(4), 
         @ICHKOUTWKTM varchar(4), 
         @SNEXTCLASS_CODE varchar(3), 
         @PCHKINREA varchar(2), 
         @PCHKOUTREA varchar(2), 
         @PWKINTM varchar(20), 
         @PWKOUTTM varchar(20)

      SET @RTNCODE = 0

      SET @SWORKHRS = 0

      SET @STOTADDHRS = 0

      SET @STOTMONADD = 0

      SET @SOTMSIGNHRS = 0

      SET @SMONCLASSADD = 0

      SET @ICHECKCARD = 'N'

      /*現有的加班單時間介於新加班單*/
      BEGIN

         BEGIN TRY
            SELECT @NCNT = count_big(*)
            FROM HRP.HRA_OTMSIGN
            WHERE 
               HRA_OTMSIGN.EMP_NO = @P_EMP_NO AND 
               HRA_OTMSIGN.ORG_BY = @SORGANTYPE AND 
               HRA_OTMSIGN.OTM_NO LIKE 'OTM%' AND 
               ((@SSTART1 BETWEEN ISNULL(ssma_oracle.to_char_date(HRA_OTMSIGN.START_DATE, 'YYYY-MM-DD'), '') + ISNULL(HRA_OTMSIGN.START_TIME, '') AND ISNULL(ssma_oracle.to_char_date(HRA_OTMSIGN.END_DATE, 'YYYY-MM-DD'), '') + ISNULL(HRA_OTMSIGN.END_TIME, '')) OR (@SEND1 BETWEEN ISNULL(ssma_oracle.to_char_date(HRA_OTMSIGN.START_DATE, 'YYYY-MM-DD'), '') + ISNULL(HRA_OTMSIGN.START_TIME, '') AND ISNULL(ssma_oracle.to_char_date(HRA_OTMSIGN.END_DATE, 'YYYY-MM-DD'), '') + ISNULL(HRA_OTMSIGN.END_TIME, ''))) AND 
               HRA_OTMSIGN.STATUS <> 'N' AND 
               HRA_OTMSIGN.OTM_NO <> @P_OTM_NO
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
               SET @NCNT = 0
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

      IF @NCNT = 0
         /*新加班單介於現有的加班單時間*/
         BEGIN

            BEGIN TRY
               SELECT @NCNT = count_big(*)
               FROM HRP.HRA_OTMSIGN
               WHERE 
                  HRA_OTMSIGN.EMP_NO = @P_EMP_NO AND 
                  HRA_OTMSIGN.ORG_BY = @SORGANTYPE AND 
                  HRA_OTMSIGN.OTM_NO LIKE 'OTM%' AND 
                  ((ISNULL(ssma_oracle.to_char_date(HRA_OTMSIGN.START_DATE, 'YYYY-MM-DD'), '') + ISNULL(HRA_OTMSIGN.START_TIME, '') BETWEEN @SSTART1 AND @SEND1) OR (ISNULL(ssma_oracle.to_char_date(HRA_OTMSIGN.END_DATE, 'YYYY-MM-DD'), '') + ISNULL(HRA_OTMSIGN.END_TIME, '') BETWEEN @SSTART1 AND @SEND1)) AND 
                  HRA_OTMSIGN.STATUS <> 'N' AND 
                  HRA_OTMSIGN.OTM_NO <> @P_OTM_NO
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
                  SET @NCNT = 0
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

      IF @NCNT > 0
         BEGIN

            IF @P_START_DATE_TMP <> 'N/A'
               SET @SCLASS_CODE = HRP.EHRPHRAFUNC_PKG$F_GETCLASSKIND(@P_EMP_NO, ssma_oracle.to_date2(@P_START_DATE_TMP, 'yyyy-mm-dd'), @SORGANTYPE)
            ELSE 
               SET @SCLASS_CODE = HRP.EHRPHRAFUNC_PKG$F_GETCLASSKIND(@P_EMP_NO, ssma_oracle.to_date2(@P_START_DATE, 'yyyy-mm-dd'), @SORGANTYPE)

            BEGIN

               BEGIN TRY
                  SELECT @IRESTSTART = HRA_CLASSDTL.START_REST, @IRESTEND = HRA_CLASSDTL.END_REST
                  FROM HRP.HRA_CLASSDTL
                  WHERE HRA_CLASSDTL.CLASS_CODE = @SCLASS_CODE AND HRA_CLASSDTL.SHIFT_NO = '1'
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
                     BEGIN

                        SET @IRESTSTART = '0'

                        SET @IRESTEND = '0'

                     END
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

            IF @P_START_TIME BETWEEN @IRESTSTART AND @IRESTEND AND @P_END_TIME BETWEEN @IRESTSTART AND @IRESTEND
               
               /*
               *   20180801 108978 這段有問題,要嚴格一點不能申請！
               *   nCnt := nCnt -1;
               */
               SET @NCNT = @NCNT
            ELSE 
               BEGIN
                  IF 
                     @IRESTSTART = '0' AND 
                     @IRESTEND = '0' AND 
                     /* AND sCLASS_CODE='ZZ' 20161219 新增班別 ZX,ZY  20180725 108978 增加ZQ*/@SCLASS_CODE IN ( 'ZZ', 'ZX', 'ZY', 'ZQ' )
                     /*20180516 108978 這段有問題，同時段不能申請才對！*/
                     SET @NCNT = @NCNT
               END

            IF @NCNT > 0
               BEGIN

                  SET @RTNCODE = 1

                  GOTO CONTINUE_FOREACH1

               END

         END

      BEGIN

         BEGIN TRY
            SELECT @IPOSLEVEL = HRE_POSMST.POS_LEVEL
            FROM HRP.HRE_POSMST
            WHERE HRE_POSMST.POS_NO = 
               (
                  SELECT HRE_EMPBAS.POS_NO
                  FROM HRP.HRE_EMPBAS
                  WHERE HRE_EMPBAS.EMP_NO = @P_EMP_NO
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
               SET @IPOSLEVEL = NULL
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

      /*----------------------- 加班簽到 -------------------------*/
      BEGIN

         BEGIN TRY
            SELECT @NCNT = count_big(*)
            FROM HRP.HRA_OTMSIGN
            WHERE 
               HRA_OTMSIGN.EMP_NO = @P_EMP_NO AND 
               HRA_OTMSIGN.ORG_BY = @SORGANTYPE AND 
               ((@SSTART BETWEEN ISNULL(ssma_oracle.to_char_date(HRA_OTMSIGN.START_DATE, 'YYYY-MM-DD'), '') + ISNULL(HRA_OTMSIGN.START_TIME, '') AND ISNULL(ssma_oracle.to_char_date(HRA_OTMSIGN.END_DATE, 'YYYY-MM-DD'), '') + ISNULL(HRA_OTMSIGN.END_TIME, '')) AND (@SEND BETWEEN ISNULL(ssma_oracle.to_char_date(HRA_OTMSIGN.START_DATE, 'YYYY-MM-DD'), '') + ISNULL(HRA_OTMSIGN.START_TIME, '') AND ISNULL(ssma_oracle.to_char_date(HRA_OTMSIGN.END_DATE, 'YYYY-MM-DD'), '') + ISNULL(HRA_OTMSIGN.END_TIME, ''))) AND 
               substring(HRA_OTMSIGN.OTM_NO, 1, 3) = 'OTS'
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
               SET @NCNT = 0
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

      IF @NCNT = 0
         SET @RTNCODE = 2/* 無簽到時間*/
      ELSE 
         SET @ICHECKCARD = 'Y'/*nCnt<>0,有加班簽到 20181219 by108482*/

      
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

                  SET @SCLASS_CODE = HRP.EHRPHRAFUNC_PKG$F_GETCLASSKIND(@P_EMP_NO, ssma_oracle.to_date2(@P_START_DATE_TMP, 'yyyy-mm-dd'), @SORGANTYPE)

                  BEGIN

                     BEGIN TRY
                        SELECT @ICHKINWKTM = HRA_CLASSDTL.CHKIN_WKTM, @ICHKOUTWKTM = HRA_CLASSDTL.CHKOUT_WKTM
                        FROM HRP.HRA_CLASSDTL
                        WHERE HRA_CLASSDTL.CLASS_CODE = @SCLASS_CODE AND HRA_CLASSDTL.SHIFT_NO = '1'
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
                           BEGIN

                              SET @ICHKINWKTM = 0

                              SET @ICHKOUTWKTM = 0

                           END
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

                  BEGIN

                     BEGIN TRY
                        SELECT @NCNT = count_big(*)
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
                              WHEN @ICHKINWKTM > @ICHKOUTWKTM AND HRA_CADSIGN.CHKIN_CARD > HRA_CADSIGN.CHKOUT_CARD THEN /*20201202增CHKIN_CARD > CHKOUT_CARD條件 by108482 嚴謹檢核*/ISNULL(ssma_oracle.to_char_date(DATEADD(D, 1, HRA_CADSIGN.ATT_DATE), 'yyyy-mm-dd'), '') + ISNULL(HRA_CADSIGN.CHKOUT_CARD, '')
                              ELSE ISNULL(ssma_oracle.to_char_date(HRA_CADSIGN.ATT_DATE, 'yyyy-mm-dd'), '') + ISNULL(HRA_CADSIGN.CHKOUT_CARD, '')
                           END)
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
                           SET @NCNT = 0
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

                  
                  /*
                  *   若查無記錄且申請起始時間>結束時間再次檢核
                  *   IF nCnt = 0 AND p_start_time > p_end_time THEN
                  *   20250718 by108482區分RN班和其他跨夜班打卡檢核
                  */
                  IF @NCNT = 0
                     /*by108482 20211215 不卡時間條件*/
                     SELECT @NCNT = count_big(*)
                     FROM HRP.HRA_CADSIGN
                     WHERE 
                        HRA_CADSIGN.EMP_NO = @P_EMP_NO AND 
                        ssma_oracle.to_char_date(HRA_CADSIGN.ATT_DATE, 'yyyy-mm-dd') = @P_START_DATE_TMP AND 
                        HRA_CADSIGN.CHKIN_CARD > HRA_CADSIGN.CHKOUT_CARD/*20221123增 by108482 嚴謹檢核*/ AND 
                        @SSTART >= 
                        CASE HRA_CADSIGN.CLASS_CODE
                           WHEN 'RN' THEN ISNULL(ssma_oracle.to_char_date(DATEADD(D, -1, HRA_CADSIGN.ATT_DATE), 'yyyy-mm-dd'), '') + ISNULL(HRA_CADSIGN.CHKIN_CARD, '')
                           ELSE ISNULL(ssma_oracle.to_char_date(HRA_CADSIGN.ATT_DATE, 'yyyy-mm-dd'), '') + ISNULL(HRA_CADSIGN.CHKIN_CARD, '')
                        END AND 
                        @SEND <= 
                        CASE HRA_CADSIGN.CLASS_CODE
                           WHEN 'RN' THEN ISNULL(ssma_oracle.to_char_date(HRA_CADSIGN.ATT_DATE, 'yyyy-mm-dd'), '') + ISNULL(HRA_CADSIGN.CHKIN_CARD, '')
                           ELSE ISNULL(ssma_oracle.to_char_date(DATEADD(D, 1, HRA_CADSIGN.ATT_DATE), 'yyyy-mm-dd'), '') + ISNULL(HRA_CADSIGN.CHKOUT_CARD, '')
                        END

               END
            ELSE 
               BEGIN

                  /*108978 20180913 RN班申請加班，和ZZ/ZX/ZY+RN申請加班*/
                  SET @SCLASS_CODE = HRP.EHRPHRAFUNC_PKG$F_GETCLASSKIND(@P_EMP_NO, ssma_oracle.to_date2(@P_START_DATE, 'yyyy-mm-dd'), @SORGANTYPE)

                  SET @SNEXTCLASS_CODE = HRP.EHRPHRAFUNC_PKG$F_GETCLASSKIND(@P_EMP_NO, DATEADD(D, 1, ssma_oracle.to_date2(@P_START_DATE, 'yyyy-mm-dd')), @SORGANTYPE)

                  /*108482 20190125 RN班提前或延後加班，start_time都不會是0000，若start_time為0000則需跑else的SQL*/
                  IF ((@SCLASS_CODE = 'RN' OR @SNEXTCLASS_CODE = 'RN') AND @P_START_TIME <> '0000')
                     BEGIN

                        BEGIN TRY
                           SELECT @NCNT = count_big(*)
                           FROM HRP.HRA_CADSIGN
                           WHERE 
                              HRA_CADSIGN.EMP_NO = @P_EMP_NO AND 
                              (@SEND BETWEEN ISNULL(ssma_oracle.to_char_date(DATEADD(D, -1, HRA_CADSIGN.ATT_DATE), 'yyyy-mm-dd'), '') + ISNULL(HRA_CADSIGN.CHKIN_CARD, '') AND (ISNULL(ssma_oracle.to_char_date(HRA_CADSIGN.ATT_DATE, 'yyyy-mm-dd'), '') + ISNULL(HRA_CADSIGN.CHKOUT_CARD, ''))) AND 
                              (@SSTART >= ISNULL(ssma_oracle.to_char_date(DATEADD(D, -1, HRA_CADSIGN.ATT_DATE), 'yyyy-mm-dd'), '') + ISNULL(HRA_CADSIGN.CHKIN_CARD, ''))
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
                              SET @NCNT = 0
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
                  ELSE 
                     BEGIN

                        BEGIN TRY
                           SELECT @NCNT = count_big(*)
                           FROM HRP.HRA_CADSIGN
                           WHERE 
                              HRA_CADSIGN.EMP_NO = @P_EMP_NO AND 
                              HRA_CADSIGN.ORG_BY = @SORGANTYPE AND 
                              (@SEND BETWEEN ISNULL(ssma_oracle.to_char_date(HRA_CADSIGN.ATT_DATE, 'yyyy-mm-dd'), '') + ISNULL(HRA_CADSIGN.CHKIN_CARD, '') AND 
                              CASE 
                                 WHEN HRA_CADSIGN.NIGHT_FLAG = 'Y' THEN (ISNULL(ssma_oracle.to_char_date(DATEADD(D, 1, HRA_CADSIGN.ATT_DATE), 'yyyy-mm-dd'), '') + ISNULL(HRA_CADSIGN.CHKOUT_CARD, ''))
                                 ELSE ISNULL(ssma_oracle.to_char_date(HRA_CADSIGN.ATT_DATE, 'yyyy-mm-dd'), '') + ISNULL(HRA_CADSIGN.CHKOUT_CARD, '')
                              END) AND 
                              (@SSTART >= ISNULL(ssma_oracle.to_char_date(HRA_CADSIGN.ATT_DATE, 'yyyy-mm-dd'), '') + ISNULL(HRA_CADSIGN.CHKIN_CARD, ''))
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
                              SET @NCNT = 0
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

               END

            IF @NCNT = 0
               BEGIN

                  SET @RTNCODE = 2/* 無簽到時間*/

                  GOTO CONTINUE_FOREACH1

               END

         END

      
      /*
      *   檢核是否有因公才能申請 20181116 108978
      *   非加班打卡才檢核一般打卡因公因私 20181219 by108482
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
                        @errornumber$10 int

                     SET @errornumber$10 = ERROR_NUMBER()

                     DECLARE
                        @errormessage$10 nvarchar(4000)

                     SET @errormessage$10 = ERROR_MESSAGE()

                     DECLARE
                        @exceptionidentifier$10 nvarchar(4000)

                     SELECT @exceptionidentifier$10 = ssma_oracle.db_error_get_oracle_exception_id(@errormessage$10, @errornumber$10)

                     IF (@exceptionidentifier$10 LIKE N'ORA-00100%')
                        BEGIN

                           SET @PCHKINREA = '15'

                           SET @PCHKOUTREA = '25'

                           SET @PWKOUTTM = @SSTART

                           SET @PWKINTM = @SEND

                        END
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
            ELSE 
               BEGIN

                  BEGIN TRY
                     /*108482 20190125 RN班提前或延後加班，start_time都不會是0000，若start_time為0000則需跑else的SQL*/
                     IF ((@SCLASS_CODE = 'RN' OR @SNEXTCLASS_CODE = 'RN') AND @P_START_TIME <> '0000')
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
                           (@SEND BETWEEN ISNULL(
                           CASE 
                              WHEN HRA_CADSIGN.CHKIN_CARD BETWEEN '0000' AND '0800' THEN ssma_oracle.to_char_date(HRA_CADSIGN.ATT_DATE, 'yyyy-mm-dd')
                              ELSE ssma_oracle.to_char_date(DATEADD(D, -1, HRA_CADSIGN.ATT_DATE), 'yyyy-mm-dd')
                           END, '') + ISNULL(HRA_CADSIGN.CHKIN_CARD, '') AND (ISNULL(ssma_oracle.to_char_date(HRA_CADSIGN.ATT_DATE, 'yyyy-mm-dd'), '') + ISNULL(HRA_CADSIGN.CHKOUT_CARD, ''))) AND 
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
                        @errornumber$11 int

                     SET @errornumber$11 = ERROR_NUMBER()

                     DECLARE
                        @errormessage$11 nvarchar(4000)

                     SET @errormessage$11 = ERROR_MESSAGE()

                     DECLARE
                        @exceptionidentifier$11 nvarchar(4000)

                     SELECT @exceptionidentifier$11 = ssma_oracle.db_error_get_oracle_exception_id(@errormessage$11, @errornumber$11)

                     IF (@exceptionidentifier$11 LIKE N'ORA-00100%')
                        BEGIN

                           SET @PCHKINREA = '15'

                           SET @PCHKOUTREA = '25'

                           SET @PWKOUTTM = @SSTART

                           SET @PWKINTM = @SEND

                        END
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

            /*延後加班狀況*/
            IF (@SSTART >= @PWKOUTTM AND @PCHKOUTREA < '25')
               BEGIN

                  SET @RTNCODE = 13/* 非因公務加班不可申請加班換補休*/

                  GOTO CONTINUE_FOREACH1

               END

            /*提前加班狀況*/
            IF (@SEND <= @PWKINTM AND @PCHKINREA < '15')
               BEGIN

                  SET @RTNCODE = 13/* 非因公務加班不可申請加班換補休*/

                  GOTO CONTINUE_FOREACH1

               END

         END

      
      /*
      *   ----加班不可申請積休-------
      *   20180612 108978 IMP201806109 同日加班申請方式只能同一種申請方式」規則
      */
      BEGIN

         BEGIN TRY
            IF @P_START_DATE_TMP <> 'N/A'
               SELECT @NCNT = count_big(HRA_OFFREC.EMP_NO)
               FROM HRP.HRA_OFFREC
               WHERE 
                  HRA_OFFREC.EMP_NO = @P_EMP_NO AND 
                  HRA_OFFREC.ORG_BY = @SORGANTYPE AND 
                  HRA_OFFREC.ITEM_TYPE = 'A' AND 
                  HRA_OFFREC.STATUS NOT IN (  'N'/*排除不准*/ ) AND 
                  (@P_START_DATE_TMP = ssma_oracle.to_char_date(HRA_OFFREC.START_DATE_TMP, 'YYYY-MM-DD') OR (@P_END_DATE = ssma_oracle.to_char_date(HRA_OFFREC.END_DATE, 'YYYY-MM-DD') AND @P_START_DATE = ssma_oracle.to_char_date(HRA_OFFREC.START_DATE, 'yyyy-mm-dd')))
            ELSE 
               SELECT @NCNT = count_big(HRA_OFFREC.EMP_NO)
               FROM HRP.HRA_OFFREC
               WHERE 
                  HRA_OFFREC.EMP_NO = @P_EMP_NO AND 
                  HRA_OFFREC.ORG_BY = @SORGANTYPE AND 
                  HRA_OFFREC.ITEM_TYPE = 'A' AND 
                  HRA_OFFREC.STATUS NOT IN (  'N'/*排除不准*/ ) AND 
                  @P_END_DATE = ssma_oracle.to_char_date(HRA_OFFREC.END_DATE, 'YYYY-MM-DD')
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
               SET @NCNT = 0
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

      IF @NCNT > 0
         BEGIN

            SET @RTNCODE = 10

            GOTO CONTINUE_FOREACH1

         END

      
      /*
      *   ---------------------------
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

      IF ssma_oracle.trunc_date(sysdatetime()) > CONVERT(datetime2, ISNULL(ssma_oracle.to_char_date(dateadd(m, 1, CONVERT(datetime2, @P_START_DATE, 111)), 'YYYY-MM'), '') + '-' + ISNULL(@LIMITDAY, ''), 111)
         BEGIN

            SET @RTNCODE = 3

            GOTO CONTINUE_FOREACH1

         END

      /*check 積休開放日*/
      IF @P_END_TIME = '0000'
         SET @I_END_DATE = @P_START_DATE
      ELSE 
         SET @I_END_DATE = @P_END_DATE

      /*查是否為上班時間內申請 108978 20190109*/
      IF @ICNT = 0
         BEGIN

            /*須修正機構別*/
            IF @P_START_DATE_TMP <> 'N/A'
               SET @RTNCODE = HRP.EHRPHRA12_PKG$CHECKCLASS(
                  @P_EMP_NO, 
                  @P_START_DATE_TMP, 
                  @P_START_TIME, 
                  @P_END_DATE, 
                  @P_END_TIME, 
                  @SORGANTYPE)
            ELSE 
               SET @RTNCODE = HRP.EHRPHRA12_PKG$CHECKCLASS(
                  @P_EMP_NO, 
                  @P_START_DATE, 
                  @P_START_TIME, 
                  @P_END_DATE, 
                  @P_END_TIME, 
                  @SORGANTYPE)

            /*20180913 108978 修正RtnCode IS NULL的問題*/
            IF (@RTNCODE IS NULL)
               SET @RTNCODE = 8

         END

      
      /*
      *   END IF;
      *    OnCall 判斷
      */
      IF @RTNCODE = 0 AND @P_ON_CALL = 'Y'
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
                     @errornumber$13 int

                  SET @errornumber$13 = ERROR_NUMBER()

                  DECLARE
                     @errormessage$13 nvarchar(4000)

                  SET @errormessage$13 = ERROR_MESSAGE()

                  DECLARE
                     @exceptionidentifier$13 nvarchar(4000)

                  SELECT @exceptionidentifier$13 = ssma_oracle.db_error_get_oracle_exception_id(@errormessage$13, @errornumber$13)

                  IF (@exceptionidentifier$13 LIKE N'ORA-00100%')
                     SET @ICNT2 = 0
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

            IF @ICNT2 > 0
               BEGIN

                  SET @RTNCODE = 4/* 住宿不可申請OnCall*/

                  GOTO CONTINUE_FOREACH1

               END

            BEGIN

               BEGIN TRY
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
                     @errornumber$14 int

                  SET @errornumber$14 = ERROR_NUMBER()

                  DECLARE
                     @errormessage$14 nvarchar(4000)

                  SET @errormessage$14 = ERROR_MESSAGE()

                  DECLARE
                     @exceptionidentifier$14 nvarchar(4000)

                  SELECT @exceptionidentifier$14 = ssma_oracle.db_error_get_oracle_exception_id(@errormessage$14, @errornumber$14)

                  IF (@exceptionidentifier$14 LIKE N'ORA-00100%')
                     SET @ICNT2 = 0
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

            IF @ICNT2 = 0
               BEGIN

                  BEGIN TRY
                     SELECT @ICNT2 = count_big(*)
                     FROM HRP.HR_CODEDTL
                     WHERE HR_CODEDTL.CODE_TYPE = 'HRA79' AND HR_CODEDTL.CODE_NO = 
                        (
                           SELECT HRE_EMPBAS.DEPT_NO
                           FROM HRP.HRE_EMPBAS
                           WHERE HRE_EMPBAS.EMP_NO = @P_EMP_NO
                        )
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
                        SET @ICNT2 = 0
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

            IF @ICNT2 = 0
               BEGIN

                  SET @RTNCODE = 5/* 申請OnCall之積休日班別須為on call班*/

                  GOTO CONTINUE_FOREACH1

               END

            BEGIN

               BEGIN TRY
                  IF @P_START_DATE_TMP <> 'N/A'
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
                     @errornumber$16 int

                  SET @errornumber$16 = ERROR_NUMBER()

                  DECLARE
                     @errormessage$16 nvarchar(4000)

                  SET @errormessage$16 = ERROR_MESSAGE()

                  DECLARE
                     @exceptionidentifier$16 nvarchar(4000)

                  SELECT @exceptionidentifier$16 = ssma_oracle.db_error_get_oracle_exception_id(@errormessage$16, @errornumber$16)

                  IF (@exceptionidentifier$16 LIKE N'ORA-00100%')
                     SET @ICNT2 = 0
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
                           @errornumber$17 int

                        SET @errornumber$17 = ERROR_NUMBER()

                        DECLARE
                           @errormessage$17 nvarchar(4000)

                        SET @errormessage$17 = ERROR_MESSAGE()

                        DECLARE
                           @exceptionidentifier$17 nvarchar(4000)

                        SELECT @exceptionidentifier$17 = ssma_oracle.db_error_get_oracle_exception_id(@errormessage$17, @errornumber$17)

                        IF (@exceptionidentifier$17 LIKE N'ORA-00100%')
                           SET @ICNT2 = 0
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

      /*20180508比照加班換加班費的邏輯判斷判別是否為上班時間 108978*/
      IF @ICNT IS NULL
         SET @ICNT = 0

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

               END

            BEGIN

               BEGIN TRY
                  SELECT @ICNT = count_big(*)
                  FROM HRP.HRA_CLASSDTL
                  WHERE 
                     HRA_CLASSDTL.CHKIN_WKTM > 
                     CASE 
                        WHEN HRA_CLASSDTL.CHKOUT_WKTM = '0000' THEN '2400'
                        ELSE HRA_CLASSDTL.CHKOUT_WKTM
                     END AND 
                     HRA_CLASSDTL.SHIFT_NO <> '4' AND 
                     HRA_CLASSDTL.CLASS_CODE = @SLASTCLASSKIND
               END TRY

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

            IF @SCLASSKIND = 'N/A'
               BEGIN

                  SET @RTNCODE = 7

                  GOTO CONTINUE_FOREACH1

               END
            ELSE 
               IF @P_START_DATE_TMP <> 'N/A' AND @SCLASSKIND IN ( 'ZZ', 'ZX', 'ZY', 'ZQ' )
                  GOTO CONTINUE_FOREACH3
               ELSE 
                  IF @SCLASSKIND IN ( 'ZZ', 'ZX', 'ZY', 'ZQ' ) AND @ICNT = 0
                     GOTO CONTINUE_FOREACH3
                  ELSE 
                     BEGIN

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

                              SET @RTNCODE = 8/*上班時間不可申請加班!!存檔失敗!*/

                              GOTO CONTINUE_FOREACH1

                           END
                        ELSE 
                           IF (@RTNCODE IS NULL)
                              BEGIN

                                 SET @RTNCODE = 8

                                 GOTO CONTINUE_FOREACH1

                              END
                           ELSE 
                              IF @RTNCODE = 7
                                 /*您尚未排班!!存檔失敗!*/
                                 GOTO CONTINUE_FOREACH1
                              ELSE 
                                 BEGIN
                                    IF @RTNCODE = 8
                                       GOTO CONTINUE_FOREACH1
                                 END

                     END

         END

      DECLARE
         @db_null_statement int

      CONTINUE_FOREACH3:

      DECLARE
         @db_null_statement$2 int

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
               @errornumber$19 int

            SET @errornumber$19 = ERROR_NUMBER()

            DECLARE
               @errormessage$19 nvarchar(4000)

            SET @errormessage$19 = ERROR_MESSAGE()

            DECLARE
               @exceptionidentifier$19 nvarchar(4000)

            SELECT @exceptionidentifier$19 = ssma_oracle.db_error_get_oracle_exception_id(@errormessage$19, @errornumber$19)

            IF (@exceptionidentifier$19 LIKE N'ORA-00100%')
               SET @SWORKHRS = 0
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

      BEGIN

         BEGIN TRY
            IF @P_START_DATE_TMP <> 'N/A'
               SELECT @STOTADDHRS/* 當日加班單時數*/ = sum(HRA_OTMSIGN.OTM_HRS)
               FROM HRP.HRA_OTMSIGN
               WHERE 
                  ssma_oracle.to_char_date(isnull(HRA_OTMSIGN.START_DATE_TMP, HRA_OTMSIGN.START_DATE), 'yyyy-mm-dd') = @P_START_DATE_TMP AND 
                  HRA_OTMSIGN.STATUS <> 'N' AND 
                  HRA_OTMSIGN.OTM_FLAG = 'B' AND 
                  HRA_OTMSIGN.EMP_NO = @P_EMP_NO AND 
                  HRA_OTMSIGN.OTM_NO <> @P_OTM_NO
            ELSE 
               SELECT @STOTADDHRS/* 當日加班單時數*/ = sum(HRA_OTMSIGN.OTM_HRS)
               FROM HRP.HRA_OTMSIGN
               WHERE 
                  ssma_oracle.to_char_date(isnull(HRA_OTMSIGN.START_DATE_TMP, HRA_OTMSIGN.START_DATE), 'yyyy-mm-dd') = @P_START_DATE AND 
                  HRA_OTMSIGN.STATUS <> 'N' AND 
                  HRA_OTMSIGN.OTM_FLAG = 'B' AND 
                  HRA_OTMSIGN.EMP_NO = @P_EMP_NO AND 
                  HRA_OTMSIGN.OTM_NO <> @P_OTM_NO
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
               SET @STOTADDHRS = 0
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

      BEGIN

         BEGIN TRY
            /*20180725 108978 增加ZQ*/
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
                  WHERE /*20250219 用應出勤日年月確認加班時數*/
                     ssma_oracle.to_char_date(isnull(HRA_OFFREC.START_DATE_TMP, HRA_OFFREC.START_DATE), 'yyyy-mm') = substring(@P_START_DATE_TMP, 1, 7) AND 
                     HRA_OFFREC.STATUS <> 'N' AND 
                     HRA_OFFREC.ITEM_TYPE = 'A' AND 
                     HRA_OFFREC.EMP_NO = @P_EMP_NO
               )  AS TT
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
               SET @STOTMONADD = 0
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

      IF @STOTADDHRS IS NULL
         SET @STOTADDHRS = 0

      BEGIN

         BEGIN TRY
            SELECT @SMONCLASSADD/*當月排班超時*/ = (HRA_ATTVAC_VIEW.MON_GETADD + HRA_ATTVAC_VIEW.MON_ADDHRS + HRA_ATTVAC_VIEW.MON_SPCOTM - HRA_ATTVAC_VIEW.MON_CUTOTM + HRA_ATTVAC_VIEW.MON_DUTYHRS)
            FROM HRP.HRA_ATTVAC_VIEW
            WHERE /*20250219 用應出勤日年月確認加班時數*/HRA_ATTVAC_VIEW.SCH_YM = substring(@P_START_DATE_TMP, 1, 7) AND HRA_ATTVAC_VIEW.EMP_NO = @P_EMP_NO
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
               SET @SMONCLASSADD = 0
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

      BEGIN

         BEGIN TRY
            SELECT @SOTMSIGNHRS/* 當月加班單總時數(含在途)*/ = isnull(sum(HRA_OTMSIGN.OTM_HRS), 0)
            FROM HRP.HRA_OTMSIGN
            WHERE /*20250219 用應出勤日年月確認加班時數*/
               ssma_oracle.to_char_date(isnull(HRA_OTMSIGN.START_DATE_TMP, HRA_OTMSIGN.START_DATE), 'yyyy-mm') = substring(@P_START_DATE_TMP, 1, 7) AND 
               HRA_OTMSIGN.STATUS <> 'N' AND 
               HRA_OTMSIGN.OTM_FLAG = 'B' AND 
               HRA_OTMSIGN.EMP_NO = @P_EMP_NO
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
               SET @SOTMSIGNHRS = 0
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

      
      /*
      *   0301開始加班每月不能超過54HR 108978
      *   20190301 by108482 因改四週排班，排除班表超時工時
      */
      IF ((@SOTMHRS + @SWORKHRS + @STOTADDHRS) > 12 OR (@STOTMONADD + @SOTMSIGNHRS + /*sMonClassAdd+*/@SOTMHRS > 54))
         BEGIN

            SET @RTNCODE = 15

            GOTO CONTINUE_FOREACH1

         END

      IF (@RTNCODE = 0)
         /*20250219 用應出勤日年月確認加班時數*/
         SET @RTNCODE = HRP.EHRPHRA12_PKG$CHECK3MONTHOTMHRS(@P_EMP_NO, @P_START_DATE_TMP, @P_OTM_HRS, @SORGANTYPE)

      DECLARE
         @db_null_statement$3 int

      CONTINUE_FOREACH1:

      DECLARE
         @db_null_statement$4 int

   END
GO
BEGIN TRY
    EXEC sp_addextendedproperty
        N'MS_SSMA_SOURCE', N'HRP.EHRPHRA12_PKG.hraC010a',
        N'SCHEMA', N'hrp',
        N'PROCEDURE', N'EHRPHRA12_PKG$HRAC010A'
END TRY
BEGIN CATCH
    IF (@@TRANCOUNT > 0) ROLLBACK
    PRINT ERROR_MESSAGE()
END CATCH
GO
