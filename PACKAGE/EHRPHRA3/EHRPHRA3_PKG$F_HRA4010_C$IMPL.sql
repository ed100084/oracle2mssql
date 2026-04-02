
USE MIS
GO
 IF NOT EXISTS(SELECT * FROM sys.schemas WHERE [name] = N'hrp')      
     EXEC (N'CREATE SCHEMA hrp')                                   
 GO                                                               

USE MIS
GO
IF  EXISTS (SELECT * FROM sys.objects so JOIN sys.schemas sc ON so.schema_id = sc.schema_id WHERE so.name = N'EHRPHRA3_PKG$F_HRA4010_C$IMPL'  AND sc.name=N'hrp'  AND type in (N'P',N'PC'))
 DROP PROCEDURE [hrp].[EHRPHRA3_PKG$F_HRA4010_C$IMPL]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE HRP.EHRPHRA3_PKG$F_HRA4010_C$IMPL  
   @TRNYM_IN varchar(max),
   @TRNSHIFT_IN varchar(max),
   @EMPNO_IN varchar(max),
   @STRARTDATE_IN datetime2(0),
   @ENDDATE_IN datetime2(0),
   @ORGTYPE_IN varchar(max),
   @UPDATEBY_IN varchar(max),
   /*
   *   SSMA warning messages:
   *   O2SS0356: Conversion from NUMBER datatype can cause data loss.
   */

   @return_value_argument float(53)  OUTPUT
AS 
   BEGIN

      DECLARE
         @STRNYM varchar(7) = @TRNYM_IN, 
         @STRNSHIFT varchar(2) = @TRNSHIFT_IN, 
         @SEMPNO varchar(20) = @EMPNO_IN, 
         @DSTRARTDATE datetime2(0) = @STRARTDATE_IN, 
         @DENDDATE datetime2(0) = @ENDDATE_IN, 
         @SORGANTYPE varchar(10) = @ORGTYPE_IN, 
         @SUPDATEBY varchar(20) = @UPDATEBY_IN, 
         @DATTDATE datetime2(0), 
         @DATTDATE1 varchar(10), 
         @IEVCCNT int, 
         /*
         *   SSMA warning messages:
         *   O2SS0356: Conversion from NUMBER datatype can cause data loss.
         */

         @NTOTALABS float(53), 
         /*
         *   SSMA warning messages:
         *   O2SS0356: Conversion from NUMBER datatype can cause data loss.
         */

         @NTOTALABS1 float(53), 
         @ICNT int = 0, 
         /*
         *   SSMA warning messages:
         *   O2SS0356: Conversion from NUMBER datatype can cause data loss.
         */

         @RTNCODE float(53) = 0, 
         @SCNTNO varchar(1), 
         @SDD varchar(2), 
         @SFIELDNO varchar(3), 
         /*
         *   SSMA warning messages:
         *   O2SS0356: Conversion from NUMBER datatype can cause data loss.
         */

         @NWORKHRS float(53)

      BEGIN TRY

         EXECUTE ssma_oracle.db_fn_check_init_package 'HRP', 'EHRPHRA3_PKG'

         /* 
         *   SSMA error messages:
         *   O2SS0151: The INTO clause cannot be converted in the current context. 
         *   INTO nTotalAbs, dAttDate

         
         /*
         *       CURSOR cur_absence IS
         *       SELECT SUM(absence)  absence
         *            , att_date
         *         INTO nTotalAbs
         *            , dAttDate
         *         FROM (SELECT COUNT(*) absence
         *                    , att_date
         *   			 FROM HRA_CARDABNORMAL_VIEW
         *                WHERE (emp_no = sEmpNo)
         *   			   AND (ORGAN_TYPE= sOrganType ) -- 機構
         *                  AND (att_date BETWEEN dStrartDate AND dEndDate)
         *   			   --and to_char(att_date,'yyyy-mm-dd')<='2006-03-29' -- sphinx  95.03.30
         *   			   AND ((chkin1 IN ('1','5')) OR (chkin2 IN ('1','5')) OR (chkin3 IN ('1','5')) OR (chkout1 IN ('1','3')) OR (chkout2 IN ('1','3')) OR (chkout3 IN ('1','3')) )
         *   			   --AND ((chkin1='5') OR (chkin2='5') OR (chkin3='5'))
         *                GROUP BY att_date )
         *         GROUP BY att_date ;
         *   20180710 108978 曠職改核實計算
         */
         DECLARE
             CUR_ABSENCE CURSOR LOCAL FOR 
               SELECT sum(fci.ABSENCE_HRS), fci.ATT_DATE
               FROM 
                  (
                     SELECT (
                        CASE 
                           WHEN fci$2.ABSENCE_HRS < 0 THEN fci$2.INV_TM1
                           ELSE fci$2.ABSENCE_HRS
                        END) AS ABSENCE_HRS, fci$2.ATT_DATE
                     FROM 
                        
                        /*
                        *   -step4 begin
                        *   計算曠職時數：
                        *   1.當忘打卡時曠職時數?工時的1/2
                        *   2.應班工時減出勤時數
                        */
                        (
                           SELECT (
                              CASE 
                                 WHEN (fci$3.CHKIN_CARD IS NULL OR fci$3.CHKIN_CARD = '') AND (fci$3.CHKOUT_CARD IS NULL OR fci$3.CHKOUT_CARD = '') THEN fci$3.INV_TM1
                                 WHEN fci$3.CHKOUT_CARD IS NULL OR fci$3.CHKOUT_CARD = '' THEN (fci$3.INV_TM1) / 2
                                 WHEN fci$3.CHKIN_CARD IS NULL OR fci$3.CHKIN_CARD = '' THEN (fci$3.INV_TM1) / 2
                                 ELSE CAST(fci$3.INV_TM1 AS float(53)) - (
                                    CASE 
                                       WHEN fci$3.HRS > 4 THEN CAST(fci$3.HRS AS float(53)) - CAST(fci$3.INV_REST AS float(53))
                                       ELSE (
                                          CASE 
                                             WHEN fci$3.HRS < 0 THEN 0
                                             ELSE fci$3.HRS
                                          END)/*避免人員輸入錯誤*/
                                    END)
                              END)/*曠職時數*/ AS ABSENCE_HRS, fci$3.ATT_DATE/*應出勤日*/, fci$3.INV_TM1/*應班工時*/
                           FROM 
                              
                              /*
                              *   -step3 begin
                              *   計算出勤時數 HRS,判斷是否跨夜
                              *   曠職最小單位?0.5小時，將調整後出勤簽到退時間再調整?整點後計算間隔時間。
                              */
                              (
                                 /* 
                                 *   SSMA error messages:
                                 *   O2SS0557: SUBSTR function with non-positive position parameter cannot be converted.
                                 *   O2SS0557: SUBSTR function with non-positive position parameter cannot be converted.
                                 *   O2SS0557: SUBSTR function with non-positive position parameter cannot be converted.
                                 *   O2SS0557: SUBSTR function with non-positive position parameter cannot be converted.
                                 *   O2SS0557: SUBSTR function with non-positive position parameter cannot be converted.
                                 *   O2SS0557: SUBSTR function with non-positive position parameter cannot be converted.
                                 *   O2SS0557: SUBSTR function with non-positive position parameter cannot be converted.

                                 SELECT 
                                    fci$4.ATT_DATE, 
                                    fci$4.CHKIN_CARD, 
                                    fci$4.CHKOUT_CARD, 
                                    fci$4.INV_TM1, 
                                    fci$4.INV_REST, 
                                    (ssma_oracle.datediff((
                                       CASE 
                                          WHEN fci$4.REAL_WKOUT < fci$4.REAL_WKIN THEN ssma_oracle.to_date2((
                                             CASE 
                                                WHEN substring(fci$4.REAL_WKOUT, 3, 2) >= '00' AND substring(fci$4.REAL_WKOUT, 3, 2) < '30' THEN ISNULL(ssma_oracle.to_char_date(DATEADD(D, 1, sysdatetime()), 'MMDD'), '') + ISNULL(CAST(substring(fci$4.REAL_WKOUT, 0, 2) AS nvarchar(max)), '') + '00'
                                                ELSE ISNULL(ssma_oracle.to_char_date(DATEADD(D, 1, sysdatetime()), 'MMDD'), '') + ISNULL(CAST(substring(fci$4.REAL_WKOUT, 0, 2) AS nvarchar(max)), '') + '30'
                                             END), 'MMDD HH24MI')
                                          ELSE ssma_oracle.to_date2((
                                             CASE 
                                                WHEN substring(fci$4.REAL_WKOUT, 3, 2) >= '00' AND substring(fci$4.REAL_WKOUT, 3, 2) < '30' THEN ISNULL(ssma_oracle.to_char_date(sysdatetime(), 'MMDD'), '') + ISNULL(CAST(substring(fci$4.REAL_WKOUT, 0, 2) AS nvarchar(max)), '') + '00'
                                                ELSE ISNULL(ssma_oracle.to_char_date(sysdatetime(), 'MMDD'), '') + ISNULL(CAST(substring(fci$4.REAL_WKOUT, 0, 2) AS nvarchar(max)), '') + '30'
                                             END), 'MMDD HH24MI')
                                       END), ((
                                       CASE 
                                          WHEN substring(fci$4.REAL_WKIN, 3, 2) = '00' THEN ssma_oracle.to_date2(ISNULL(ssma_oracle.to_char_date(sysdatetime(), 'MMDD'), '') + ISNULL(CAST(substring(fci$4.REAL_WKIN, 0, 2) AS nvarchar(max)), '') + '00', 'MMDD HH24MI')
                                          WHEN substring(fci$4.REAL_WKIN, 3, 2) > '00' AND substring(fci$4.REAL_WKIN, 3, 2) <= '30' THEN ssma_oracle.to_date2(ISNULL(ssma_oracle.to_char_date(sysdatetime(), 'MMDD'), '') + ISNULL(CAST(substring(fci$4.REAL_WKIN, 0, 2) AS nvarchar(max)), '') + '30', 'MMDD HH24MI')
                                          ELSE DATEADD(D, CAST(1 AS float(53)) / 24, ssma_oracle.to_date2(ISNULL(ssma_oracle.to_char_date(sysdatetime(), 'MMDD'), '') + ISNULL(CAST((substring(fci$4.REAL_WKIN, 0, 2)) AS nvarchar(max)), '') + '00', 'MMDD HH24MI'))
                                       END)))) * 24 AS HRS
                                 FROM 
                                    
                                    /*
                                    *   -step2 begin
                                    *   取工號，出勤日，班表，簽到退異常狀態，實際簽到退時間，班表應簽到退時間，應班工時，中午休息時間，調整後出勤簽退到時間
                                    *   2次調整，判斷簽到退時間是否在中午休息時間內
                                    */
                                    (
                                       SELECT 
                                          fci$5.EMP_NO, 
                                          fci$5.ATT_DATE, 
                                          fci$5.CLASS_CODE, 
                                          fci$5.CHKIN, 
                                          fci$5.CHKOUT, 
                                          fci$5.CHKIN_CARD, 
                                          fci$5.CHKOUT_CARD, 
                                          fci$5.CHKIN_WKTM, 
                                          fci$5.CHKOUT_WKTM, 
                                          fci$5.INV_TM1, 
                                          fci$5.INV_REST, 
                                          (CASE 
                                             WHEN fci$5.REAL_WKIN >= fci$5.START_REST AND fci$5.REAL_WKIN <= fci$5.END_REST THEN fci$5.END_REST
                                             ELSE fci$5.REAL_WKIN
                                          END) AS REAL_WKIN, 
                                          (CASE 
                                             WHEN fci$5.REAL_WKOUT >= fci$5.START_REST AND fci$5.REAL_WKOUT <= fci$5.END_REST THEN fci$5.START_REST
                                             ELSE fci$5.REAL_WKOUT
                                          END) AS REAL_WKOUT
                                       FROM 
                                          
                                          /*
                                          *   -step1 begin
                                          *    SQL_NAME : f_hra3010
                                          *    Private type declarations
                                          *   出勤異常, 0->正常, 1->未打卡, 2->遲到, 3->早退, 4->免簽, 5->曠職
                                          *   上下班簽到
                                          *   取基本資料，班表工時，
                                          *   1次調整，依chkin/chkout回傳值判斷實際簽到退時間為調整後簽到退時間
                                          *   20211104 by108482 chkin=2,REAL_WKIN帶入CHKIN_WKTM,避免曠職多算0.5小時
                                          */
                                          (
                                             SELECT 
                                                A.EMP_NO, 
                                                A.DEPT_NO, 
                                                A.CLASS_KIND, 
                                                A.ATT_DATE, 
                                                A.CLASS_CODE, 
                                                A.SHIFT_NO, 
                                                A.CHKIN, 
                                                A.CHKIN_CARD, 
                                                A.CHKIN_WKTM, 
                                                A.CHKOUT, 
                                                A.CHKOUT_CARD, 
                                                A.CHKOUT_WKTM, 
                                                A.ORG_BY, 
                                                A.ORGAN_TYPE, 
                                                B.WORK_HRS AS INV_TM1, 
                                                (ssma_oracle.datediff(ssma_oracle.to_date2(C.END_REST, 'HH24MI'), ssma_oracle.to_date2(C.START_REST, 'HH24MI'))) * 24 AS INV_REST, 
                                                (CASE 
                                                   WHEN A.CHKIN IN ( 0, 2 ) THEN A.CHKIN_WKTM
                                                   ELSE A.CHKIN_CARD
                                                END) AS REAL_WKIN, 
                                                (CASE 
                                                   WHEN A.CHKOUT = 3 THEN A.CHKOUT_CARD
                                                   ELSE A.CHKOUT_WKTM
                                                END) AS REAL_WKOUT, 
                                                C.START_REST, 
                                                C.END_REST
                                             FROM HRP.HRA_CARDATT_VIEW  AS A, HRP.HRA_CLASSDTL  AS C, HRP.HRA_CLASSMST  AS B
                                             WHERE 
                                                (A.ATT_DATE BETWEEN @DSTRARTDATE AND @DENDDATE) AND 
                                                (A.EMP_NO = @SEMPNO) AND 
                                                (A.ORGAN_TYPE = @SORGANTYPE) AND 
                                                (
                                                (A.CHKIN = '5' OR A.CHKOUT = '3') OR 
                                                (A.CHKIN = '1' AND A.CHKOUT = '0') OR 
                                                (A.CHKIN = '1' AND A.CHKOUT = '1') OR 
                                                (A.CHKIN = '0' AND A.CHKOUT = '1') OR 
                                                (A.CHKIN = '2' AND A.CHKOUT = '1')) AND 
                                                A.CLASS_CODE = C.CLASS_CODE AND 
                                                C.CLASS_CODE = B.CLASS_CODE AND 
                                                A.SHIFT_NO = C.SHIFT_NO/*於20201013新增by108482,避免多段班曠職時數重複計算*/
                                          )/*step1 end*/  AS fci$5
                                    )/*step2 end*/  AS fci$4
                                 */


                              )/*step3 end*/  AS fci$3
                        )/*step4 end*/  AS fci$2
                  )  AS fci
               GROUP BY fci.ATT_DATE
         */



         
         /*
         *   CURSOR cur_absence1 IS
         *         SELECT 1
         *            , '2015-03-01'
         *         INTO nTotalAbs
         *            , dAttDate1
         *         FROM (SELECT COUNT(*) absence
         *                    , att_date
         *                 FROM hra_after_abnormal_view
         *                WHERE trim(hra_after_abnormal_view.emp_no) = sEmpNo
         *   			   AND (ORGAN_TYPE= sOrganType ) -- 機構
         *                  AND hra_after_abnormal_view.att_date BETWEEN TO_CHAR(dStrartDate,'YYYY-MM-DD') AND TO_CHAR(dEndDate,'YYYY-MM-DD')
         *                GROUP BY att_date  )
         *         GROUP BY att_date ;
         *   ------------------------------For義大--------------------------------
         */
         OPEN CUR_ABSENCE

         WHILE 1 = 1
         
            BEGIN

               FETCH CUR_ABSENCE
                   INTO @NTOTALABS, @DATTDATE

               /*
               *   SSMA warning messages:
               *   O2SS0113: The value of @@FETCH_STATUS might be changed by previous FETCH operations on other cursors, if the cursors are used simultaneously.
               */

               IF @@FETCH_STATUS <> 0
                  BREAK

               IF @NTOTALABS <> 0
                  BEGIN

                     /*nTotalAbs1:= nTotalAbs * 4;*/
                     SET @NTOTALABS1 = @NTOTALABS/*20180710 108978 曠職改核實計算*/

                     SET @RTNCODE = HRP.EHRPHRA3_PKG$F_HRA4010_INS(
                        @STRNYM, 
                        @STRNSHIFT, 
                        @SEMPNO, 
                        '2030', 
                        @NTOTALABS1, 
                        /*, attunit_in  => 'T'*/'H', 
                        @SORGANTYPE, 
                        @SUPDATEBY)

                     IF @RTNCODE <> 0
                        GOTO CONTINUE_FOREACH1/*  曠職次數INSERT失敗*/

                     SET @ICNT = @ICNT + 1

                  END

               DECLARE
                  @db_null_statement int

               CONTINUE_FOREACH2:

               DECLARE
                  @db_null_statement$2 int

            END

         /* 
         *   SSMA error messages:
         *   O2SS0151: The INTO clause cannot be converted in the current context. 
         *   INTO nTotalAbs, dAttDate1

         /*20180716 沒有簽到和簽退記錄 108978*/
         DECLARE
             CUR_ABSENCE1 CURSOR LOCAL FOR 
               SELECT sum(fci.ABSENCE) AS ABSENCE, fci.ATT_DATE
               FROM 
                  (
                     SELECT count_big(*) AS ABSENCE, HRA_AFTER_ABNORMAL_VIEW.ATT_DATE
                     FROM HRP.HRA_AFTER_ABNORMAL_VIEW
                     WHERE 
                        ssma_oracle.trim2_varchar(3, HRA_AFTER_ABNORMAL_VIEW.EMP_NO) = @SEMPNO AND 
                        (HRA_AFTER_ABNORMAL_VIEW.ORGAN_TYPE = @SORGANTYPE) AND 
                        HRA_AFTER_ABNORMAL_VIEW.ATT_DATE BETWEEN ssma_oracle.to_char_date(@DSTRARTDATE, 'YYYY-MM-DD') AND ssma_oracle.to_char_date(@DENDDATE, 'YYYY-MM-DD')
                     GROUP BY HRA_AFTER_ABNORMAL_VIEW.ATT_DATE
                  )  AS fci
               GROUP BY fci.ATT_DATE
         */



         /*沒有簽到和簽退記錄*/
         OPEN CUR_ABSENCE1

         WHILE 1 = 1
         
            BEGIN

               FETCH CUR_ABSENCE1
                   INTO @NTOTALABS, @DATTDATE1

               /*
               *   SSMA warning messages:
               *   O2SS0113: The value of @@FETCH_STATUS might be changed by previous FETCH operations on other cursors, if the cursors are used simultaneously.
               */

               IF @@FETCH_STATUS <> 0
                  BREAK

               IF @NTOTALABS <> 0
                  BEGIN

                     /*sDd:=SUBSTR(TO_CHAR(dAttDate,'YYYY-MM-DD'),9,2);*/
                     SET @SDD = substring(@DATTDATE1, 9, 2)

                     BEGIN

                        BEGIN TRY

                           SELECT @SFIELDNO = 
                              CASE 
                                 WHEN @SDD = '01' OR isnull(@SDD, '01') IS NULL THEN HRA_CLASSSCH.SCH_01
                                 WHEN @SDD = '02' OR isnull(@SDD, '02') IS NULL THEN HRA_CLASSSCH.SCH_02
                                 WHEN @SDD = '03' OR isnull(@SDD, '03') IS NULL THEN HRA_CLASSSCH.SCH_03
                                 WHEN @SDD = '04' OR isnull(@SDD, '04') IS NULL THEN HRA_CLASSSCH.SCH_04
                                 WHEN @SDD = '05' OR isnull(@SDD, '05') IS NULL THEN HRA_CLASSSCH.SCH_05
                                 WHEN @SDD = '06' OR isnull(@SDD, '06') IS NULL THEN HRA_CLASSSCH.SCH_06
                                 WHEN @SDD = '07' OR isnull(@SDD, '07') IS NULL THEN HRA_CLASSSCH.SCH_07
                                 WHEN @SDD = '08' OR isnull(@SDD, '08') IS NULL THEN HRA_CLASSSCH.SCH_08
                                 WHEN @SDD = '09' OR isnull(@SDD, '09') IS NULL THEN HRA_CLASSSCH.SCH_09
                                 WHEN @SDD = '10' OR isnull(@SDD, '10') IS NULL THEN HRA_CLASSSCH.SCH_10
                                 WHEN @SDD = '11' OR isnull(@SDD, '11') IS NULL THEN HRA_CLASSSCH.SCH_11
                                 WHEN @SDD = '12' OR isnull(@SDD, '12') IS NULL THEN HRA_CLASSSCH.SCH_12
                                 WHEN @SDD = '13' OR isnull(@SDD, '13') IS NULL THEN HRA_CLASSSCH.SCH_13
                                 WHEN @SDD = '14' OR isnull(@SDD, '14') IS NULL THEN HRA_CLASSSCH.SCH_14
                                 WHEN @SDD = '15' OR isnull(@SDD, '15') IS NULL THEN HRA_CLASSSCH.SCH_15
                                 WHEN @SDD = '16' OR isnull(@SDD, '16') IS NULL THEN HRA_CLASSSCH.SCH_16
                                 WHEN @SDD = '17' OR isnull(@SDD, '17') IS NULL THEN HRA_CLASSSCH.SCH_17
                                 WHEN @SDD = '18' OR isnull(@SDD, '18') IS NULL THEN HRA_CLASSSCH.SCH_18
                                 WHEN @SDD = '19' OR isnull(@SDD, '19') IS NULL THEN HRA_CLASSSCH.SCH_19
                                 WHEN @SDD = '20' OR isnull(@SDD, '20') IS NULL THEN HRA_CLASSSCH.SCH_20
                                 WHEN @SDD = '21' OR isnull(@SDD, '21') IS NULL THEN HRA_CLASSSCH.SCH_21
                                 WHEN @SDD = '22' OR isnull(@SDD, '22') IS NULL THEN HRA_CLASSSCH.SCH_22
                                 WHEN @SDD = '23' OR isnull(@SDD, '23') IS NULL THEN HRA_CLASSSCH.SCH_23
                                 WHEN @SDD = '24' OR isnull(@SDD, '24') IS NULL THEN HRA_CLASSSCH.SCH_24
                                 WHEN @SDD = '25' OR isnull(@SDD, '25') IS NULL THEN HRA_CLASSSCH.SCH_25
                                 WHEN @SDD = '26' OR isnull(@SDD, '26') IS NULL THEN HRA_CLASSSCH.SCH_26
                                 WHEN @SDD = '27' OR isnull(@SDD, '27') IS NULL THEN HRA_CLASSSCH.SCH_27
                                 WHEN @SDD = '28' OR isnull(@SDD, '28') IS NULL THEN HRA_CLASSSCH.SCH_28
                                 WHEN @SDD = '29' OR isnull(@SDD, '29') IS NULL THEN HRA_CLASSSCH.SCH_29
                                 WHEN @SDD = '30' OR isnull(@SDD, '30') IS NULL THEN HRA_CLASSSCH.SCH_30
                                 WHEN @SDD = '31' OR isnull(@SDD, '31') IS NULL THEN HRA_CLASSSCH.SCH_31
                              END
                           FROM HRP.HRA_CLASSSCH
                           WHERE 
                              HRA_CLASSSCH.SCH_YM = @STRNYM AND 
                              HRA_CLASSSCH.EMP_NO = @SEMPNO AND 
                              HRA_CLASSSCH.ORG_BY = @SORGANTYPE

                           SELECT @NWORKHRS = HRA_CLASSMST.WORK_HRS
                           FROM HRP.HRA_CLASSMST
                           WHERE HRA_CLASSMST.CLASS_CODE = @SFIELDNO

                        END TRY

                        BEGIN CATCH
                           BEGIN
                              SET @NWORKHRS = 8
                           END
                        END CATCH

                     END

                     SET @NTOTALABS1 = @NTOTALABS * @NWORKHRS

                     SET @RTNCODE = HRP.EHRPHRA3_PKG$F_HRA4010_INS(
                        @STRNYM, 
                        @STRNSHIFT, 
                        @SEMPNO, 
                        '2030', 
                        @NTOTALABS1, 
                        /*, attunit_in  => 'T'*/'H', 
                        @SORGANTYPE, 
                        @SUPDATEBY)

                     IF @RTNCODE <> 0
                        GOTO CONTINUE_FOREACH1/*  曠職次數INSERT失敗*/

                     SET @ICNT = @ICNT + 1

                  END

               DECLARE
                  @db_null_statement$3 int

               CONTINUE_FOREACH2$2:

               DECLARE
                  @db_null_statement$4 int

            END

         /* 
         *   SSMA error messages:
         *   O2SS0151: The INTO clause cannot be converted in the current context. 
         *   INTO nTotalAbs, dAttDate1

         /*20180716 時段2沒有簽到和簽退記錄 108978*/
         DECLARE
             CUR_ABSENCE3 CURSOR LOCAL FOR 
               SELECT sum(fci.ABSENCE) AS ABSENCE, fci.ATT_DATE
               FROM 
                  (
                     SELECT count_big(*) AS ABSENCE, HRA_CARDABNORMAL_VIEW.ATT_DATE
                     FROM HRP.HRA_CARDABNORMAL_VIEW
                     WHERE 
                        (HRA_CARDABNORMAL_VIEW.EMP_NO = @SEMPNO) AND 
                        (HRA_CARDABNORMAL_VIEW.ORGAN_TYPE = @SORGANTYPE) AND 
                        (HRA_CARDABNORMAL_VIEW.ATT_DATE BETWEEN @DSTRARTDATE AND @DENDDATE) AND 
                        (/*and to_char(att_date,'yyyy-mm-dd')<='2006-03-29' -- sphinx  95.03.30*/HRA_CARDABNORMAL_VIEW.CHKIN2 = '1' AND HRA_CARDABNORMAL_VIEW.CHKOUT2 IN (  '1' ))
                     /*AND ((chkin1='5') OR (chkin2='5') OR (chkin3='5'))*/
                     GROUP BY HRA_CARDABNORMAL_VIEW.ATT_DATE
                  )  AS fci
               GROUP BY fci.ATT_DATE
         */



         /*時段2沒有簽到和簽退記錄*/
         OPEN CUR_ABSENCE3

         WHILE 1 = 1
         
            BEGIN

               FETCH CUR_ABSENCE3
                   INTO @NTOTALABS, @DATTDATE1

               /*
               *   SSMA warning messages:
               *   O2SS0113: The value of @@FETCH_STATUS might be changed by previous FETCH operations on other cursors, if the cursors are used simultaneously.
               */

               IF @@FETCH_STATUS <> 0
                  BREAK

               IF @NTOTALABS <> 0
                  BEGIN

                     /*sDd:=SUBSTR(TO_CHAR(dAttDate,'YYYY-MM-DD'),9,2);*/
                     SET @SDD = substring(@DATTDATE1, 9, 2)

                     BEGIN

                        BEGIN TRY

                           SELECT @SFIELDNO = 
                              CASE 
                                 WHEN @SDD = '01' OR isnull(@SDD, '01') IS NULL THEN HRA_CLASSSCH.SCH_01
                                 WHEN @SDD = '02' OR isnull(@SDD, '02') IS NULL THEN HRA_CLASSSCH.SCH_02
                                 WHEN @SDD = '03' OR isnull(@SDD, '03') IS NULL THEN HRA_CLASSSCH.SCH_03
                                 WHEN @SDD = '04' OR isnull(@SDD, '04') IS NULL THEN HRA_CLASSSCH.SCH_04
                                 WHEN @SDD = '05' OR isnull(@SDD, '05') IS NULL THEN HRA_CLASSSCH.SCH_05
                                 WHEN @SDD = '06' OR isnull(@SDD, '06') IS NULL THEN HRA_CLASSSCH.SCH_06
                                 WHEN @SDD = '07' OR isnull(@SDD, '07') IS NULL THEN HRA_CLASSSCH.SCH_07
                                 WHEN @SDD = '08' OR isnull(@SDD, '08') IS NULL THEN HRA_CLASSSCH.SCH_08
                                 WHEN @SDD = '09' OR isnull(@SDD, '09') IS NULL THEN HRA_CLASSSCH.SCH_09
                                 WHEN @SDD = '10' OR isnull(@SDD, '10') IS NULL THEN HRA_CLASSSCH.SCH_10
                                 WHEN @SDD = '11' OR isnull(@SDD, '11') IS NULL THEN HRA_CLASSSCH.SCH_11
                                 WHEN @SDD = '12' OR isnull(@SDD, '12') IS NULL THEN HRA_CLASSSCH.SCH_12
                                 WHEN @SDD = '13' OR isnull(@SDD, '13') IS NULL THEN HRA_CLASSSCH.SCH_13
                                 WHEN @SDD = '14' OR isnull(@SDD, '14') IS NULL THEN HRA_CLASSSCH.SCH_14
                                 WHEN @SDD = '15' OR isnull(@SDD, '15') IS NULL THEN HRA_CLASSSCH.SCH_15
                                 WHEN @SDD = '16' OR isnull(@SDD, '16') IS NULL THEN HRA_CLASSSCH.SCH_16
                                 WHEN @SDD = '17' OR isnull(@SDD, '17') IS NULL THEN HRA_CLASSSCH.SCH_17
                                 WHEN @SDD = '18' OR isnull(@SDD, '18') IS NULL THEN HRA_CLASSSCH.SCH_18
                                 WHEN @SDD = '19' OR isnull(@SDD, '19') IS NULL THEN HRA_CLASSSCH.SCH_19
                                 WHEN @SDD = '20' OR isnull(@SDD, '20') IS NULL THEN HRA_CLASSSCH.SCH_20
                                 WHEN @SDD = '21' OR isnull(@SDD, '21') IS NULL THEN HRA_CLASSSCH.SCH_21
                                 WHEN @SDD = '22' OR isnull(@SDD, '22') IS NULL THEN HRA_CLASSSCH.SCH_22
                                 WHEN @SDD = '23' OR isnull(@SDD, '23') IS NULL THEN HRA_CLASSSCH.SCH_23
                                 WHEN @SDD = '24' OR isnull(@SDD, '24') IS NULL THEN HRA_CLASSSCH.SCH_24
                                 WHEN @SDD = '25' OR isnull(@SDD, '25') IS NULL THEN HRA_CLASSSCH.SCH_25
                                 WHEN @SDD = '26' OR isnull(@SDD, '26') IS NULL THEN HRA_CLASSSCH.SCH_26
                                 WHEN @SDD = '27' OR isnull(@SDD, '27') IS NULL THEN HRA_CLASSSCH.SCH_27
                                 WHEN @SDD = '28' OR isnull(@SDD, '28') IS NULL THEN HRA_CLASSSCH.SCH_28
                                 WHEN @SDD = '29' OR isnull(@SDD, '29') IS NULL THEN HRA_CLASSSCH.SCH_29
                                 WHEN @SDD = '30' OR isnull(@SDD, '30') IS NULL THEN HRA_CLASSSCH.SCH_30
                                 WHEN @SDD = '31' OR isnull(@SDD, '31') IS NULL THEN HRA_CLASSSCH.SCH_31
                              END
                           FROM HRP.HRA_CLASSSCH
                           WHERE 
                              HRA_CLASSSCH.SCH_YM = @STRNYM AND 
                              HRA_CLASSSCH.EMP_NO = @SEMPNO AND 
                              HRA_CLASSSCH.ORG_BY = @SORGANTYPE

                           SELECT @NWORKHRS = HRA_CLASSMST.WORK_HRS
                           FROM HRP.HRA_CLASSMST
                           WHERE HRA_CLASSMST.CLASS_CODE = @SFIELDNO

                        END TRY

                        BEGIN CATCH
                           BEGIN
                              SET @NWORKHRS = 8
                           END
                        END CATCH

                     END

                     SET @NTOTALABS1 = @NTOTALABS * @NWORKHRS

                     SET @RTNCODE = HRP.EHRPHRA3_PKG$F_HRA4010_INS(
                        @STRNYM, 
                        @STRNSHIFT, 
                        @SEMPNO, 
                        '2030', 
                        @NTOTALABS1, 
                        /*, attunit_in  => 'T'*/'H', 
                        @SORGANTYPE, 
                        @SUPDATEBY)

                     IF @RTNCODE <> 0
                        GOTO CONTINUE_FOREACH1/*  曠職次數INSERT失敗*/

                     SET @ICNT = @ICNT + 1

                  END

               DECLARE
                  @db_null_statement$5 int

               CONTINUE_FOREACH2$3:

               DECLARE
                  @db_null_statement$6 int

            END

         /* 
         *   SSMA error messages:
         *   O2SS0151: The INTO clause cannot be converted in the current context. 
         *   INTO nTotalAbs, dAttDate

         
         /*
         *   20180716 請假時數不足 108978
         *   20180914 遲到不列入曠職  108978
         */
         DECLARE
             CUR_ABSENCE2 CURSOR LOCAL FOR 
               SELECT sum(HRA_DAILYTRAN.INSUFFICIENT_TIME) AS ABSENCE, HRA_DAILYTRAN.VAC_DATE
               FROM HRP.HRA_DAILYTRAN
               WHERE 
                  ssma_oracle.trim2_varchar(3, HRA_DAILYTRAN.EMP_NO) = @SEMPNO AND 
                  (HRA_DAILYTRAN.ORGAN_TYPE = @SORGANTYPE) AND 
                  HRA_DAILYTRAN.VAC_DATE BETWEEN @DSTRARTDATE AND @DENDDATE AND 
                  /*AND LATE_FLAG='N'*/HRA_DAILYTRAN.LATE_FLAG <> 'Y'
               GROUP BY HRA_DAILYTRAN.VAC_DATE
         */



         /*20180716 108978 加入請假時數不足*/
         OPEN CUR_ABSENCE2

         WHILE 1 = 1
         
            BEGIN

               FETCH CUR_ABSENCE2
                   INTO @NTOTALABS, @DATTDATE

               /*
               *   SSMA warning messages:
               *   O2SS0113: The value of @@FETCH_STATUS might be changed by previous FETCH operations on other cursors, if the cursors are used simultaneously.
               */

               IF @@FETCH_STATUS <> 0
                  BREAK

               IF @NTOTALABS <> 0
                  BEGIN

                     SET @NTOTALABS1 = @NTOTALABS

                     SET @RTNCODE = HRP.EHRPHRA3_PKG$F_HRA4010_INS(
                        @STRNYM, 
                        @STRNSHIFT, 
                        @SEMPNO, 
                        '2030', 
                        @NTOTALABS1, 
                        'H', 
                        @SORGANTYPE, 
                        @SUPDATEBY)

                     IF @RTNCODE <> 0
                        GOTO CONTINUE_FOREACH1

                     SET @ICNT = @ICNT + 1

                  END

               DECLARE
                  @db_null_statement$7 int

               CONTINUE_FOREACH2$4:

               DECLARE
                  @db_null_statement$8 int

            END

         DECLARE
            @db_null_statement$9 int

         CONTINUE_FOREACH1:

         DECLARE
            @db_null_statement$10 int

         IF CURSOR_STATUS('local', N'CUR_ABSENCE') > -1
            BEGIN

               CLOSE CUR_ABSENCE

               DEALLOCATE CUR_ABSENCE

            END

         SET @return_value_argument = @RTNCODE

         RETURN 

         SET @return_value_argument = @ICNT

         /*------------------------------For義大--------------------------------*/
         RETURN 

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

         BEGIN

            IF @@TRANCOUNT > 0
               ROLLBACK WORK 

            SET @return_value_argument = ssma_oracle.db_error_sqlcode(@exceptionidentifier, @errornumber)

            RETURN 

            DECLARE
               @db_null_statement$11 int

         END

      END CATCH

   END
GO
BEGIN TRY
    EXEC sp_addextendedproperty
        N'MS_SSMA_SOURCE', N'HRP.EHRPHRA3_PKG.f_hra4010_C',
        N'SCHEMA', N'hrp',
        N'PROCEDURE', N'EHRPHRA3_PKG$F_HRA4010_C$IMPL'
END TRY
BEGIN CATCH
    IF (@@TRANCOUNT > 0) ROLLBACK
    PRINT ERROR_MESSAGE()
END CATCH
GO
