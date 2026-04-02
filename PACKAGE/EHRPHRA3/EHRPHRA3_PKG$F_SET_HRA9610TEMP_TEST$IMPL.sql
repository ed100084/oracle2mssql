
USE MIS
GO
 IF NOT EXISTS(SELECT * FROM sys.schemas WHERE [name] = N'hrp')      
     EXEC (N'CREATE SCHEMA hrp')                                   
 GO                                                               

USE MIS
GO
IF  EXISTS (SELECT * FROM sys.objects so JOIN sys.schemas sc ON so.schema_id = sc.schema_id WHERE so.name = N'EHRPHRA3_PKG$F_SET_HRA9610TEMP_TEST$IMPL'  AND sc.name=N'hrp'  AND type in (N'P',N'PC'))
 DROP PROCEDURE [hrp].[EHRPHRA3_PKG$F_SET_HRA9610TEMP_TEST$IMPL]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE HRP.EHRPHRA3_PKG$F_SET_HRA9610TEMP_TEST$IMPL  
   @SSTARTDATE varchar(max),
   @SENDDATE varchar(max),
   /*
   *   SSMA warning messages:
   *   O2SS0356: Conversion from NUMBER datatype can cause data loss.
   */

   @return_value_argument float(53)  OUTPUT
AS 
   BEGIN

      EXECUTE ssma_oracle.db_fn_check_init_package 'HRP', 'EHRPHRA3_PKG'

      DECLARE
         /*
         *   SSMA warning messages:
         *   O2SS0356: Conversion from NUMBER datatype can cause data loss.
         */

         @SSEQ float(53) = 0, 
         @SEMP_NO varchar(10), 
         @SSTART_DATE varchar(10), 
         @SEND_DATE varchar(10), 
         @SSTART_TIME varchar(4), 
         @SEND_TIME varchar(4), 
         /*
         *   SSMA warning messages:
         *   O2SS0356: Conversion from NUMBER datatype can cause data loss.
         */

         @SVAC_DAYS float(53), 
         @SVAC_HRS numeric(3, 1), 
         @SORGANTYPE varchar(10), 
         @SEMP_NAME varchar(200), 
         @SDEPT_NO varchar(10), 
         @SDEPT_NAME varchar(60), 
         /*
         *   SSMA warning messages:
         *   O2SS0356: Conversion from NUMBER datatype can cause data loss.
         */

         @SDAYCNT float(53), 
         /*
         *   SSMA warning messages:
         *   O2SS0356: Conversion from NUMBER datatype can cause data loss.
         */

         @ICLASSCNT float(53), 
         @ICLASSKIND varchar(3), 
         /*
         *   SSMA warning messages:
         *   O2SS0356: Conversion from NUMBER datatype can cause data loss.
         */

         @IWORKMIN float(53), 
         @SCHKIN_WKTM varchar(4), 
         @SCHKOUT_WKTM varchar(4), 
         @SSTART_REST varchar(4), 
         @SEND_REST varchar(4), 
         @SWORK_HRS varchar(4), 
         @SVALIDDATE datetime2(0), 
         /*
         *   SSMA warning messages:
         *   O2SS0356: Conversion from NUMBER datatype can cause data loss.
         */

         @IREALYWORKMIN float(53), 
         @SCHKIN_CARD varchar(4), 
         @SCHKOUT_CARD varchar(4), 
         @SNIGHT_FLAG varchar(1), 
         /*
         *   SSMA warning messages:
         *   O2SS0356: Conversion from NUMBER datatype can cause data loss.
         */

         @SVACMIN float(53), 
         @ICNT int, 
         @ICARDSIGNCNT int, 
         @ICHECKDATE int, 
         @VSTART_DATE varchar(10), 
         @VEND_DATE varchar(10), 
         @VSTART_TIME varchar(4), 
         @VEND_TIME varchar(4), 
         /*
         *   SSMA warning messages:
         *   O2SS0356: Conversion from NUMBER datatype can cause data loss.
         */

         @RTNCODE float(53), 
         /*
         *   SSMA warning messages:
         *   O2SS0356: Conversion from NUMBER datatype can cause data loss.
         */

         /*itest       NUMBER :=0;*/
         @INSUFFICIENT_TIME float(53), 
         /*
         *   SSMA warning messages:
         *   O2SS0356: Conversion from NUMBER datatype can cause data loss.
         */

         @INSUFFICIENT_TIME_TMP float(53), 
         /*
         *   SSMA warning messages:
         *   O2SS0356: Conversion from NUMBER datatype can cause data loss.
         */

         @INSUFFICIENT_MIN float(53), 
         @LATE_FLAG varchar(1) = 'N', 
         /*
         *   SSMA warning messages:
         *   O2SS0356: Conversion from NUMBER datatype can cause data loss.
         */

         @LATE_TIME float(53)

      DECLARE
          CURSOR1 CURSOR LOCAL FOR 
            SELECT 
               fci.EMP_NO, 
               ssma_oracle.to_char_date(fci.START_DATE, 'yyyy-mm-dd') AS START_DATE, 
               ssma_oracle.to_char_date(fci.END_DATE, 'yyyy-mm-dd') AS END_DATE, 
               fci.START_TIME, 
               fci.END_TIME, 
               fci.ORG_BY
            FROM 
               (
                  SELECT 
                     HRA_EVCREC.EMP_NO, 
                     HRA_EVCREC.START_DATE, 
                     HRA_EVCREC.END_DATE, 
                     HRA_EVCREC.START_TIME, 
                     HRA_EVCREC.END_TIME, 
                     HRA_EVCREC.ORG_BY
                  FROM HRP.HRA_EVCREC
                  WHERE HRA_EVCREC.STATUS = 'Y' AND /*and emp_no='109233' -- test*/HRA_EVCREC.EMP_NO NOT IN 
                     (
                        SELECT HRE_PROFILE.EMP_NO
                        FROM HRP.HRE_PROFILE
                        WHERE HRE_PROFILE.ITEM_NO IN ( 'EMP01', 'EMP02' )
                     )
                   UNION ALL
                  /*20190115 108978 20180301無借休資料*/
                  SELECT 
                     HRA_OFFREC.EMP_NO, 
                     HRA_OFFREC.START_DATE, 
                     HRA_OFFREC.END_DATE, 
                     HRA_OFFREC.START_TIME, 
                     HRA_OFFREC.END_TIME, 
                     HRA_OFFREC.ORG_BY
                  FROM HRP.HRA_OFFREC
                  WHERE 
                     HRA_OFFREC.STATUS = 'Y' AND 
                     HRA_OFFREC.EMP_NO NOT IN 
                     (
                        SELECT HRE_PROFILE$2.EMP_NO
                        FROM HRP.HRE_PROFILE  AS HRE_PROFILE$2
                        WHERE HRE_PROFILE$2.ITEM_NO IN ( 'EMP01', 'EMP02' )
                     ) AND 
                     HRA_OFFREC.ITEM_TYPE = 'O'
                   UNION ALL
                  SELECT 
                     HRA_SUPMST.EMP_NO, 
                     HRA_SUPMST.START_DATE, 
                     HRA_SUPMST.END_DATE, 
                     HRA_SUPMST.START_TIME, 
                     HRA_SUPMST.END_TIME, 
                     HRA_SUPMST.ORG_BY
                  FROM HRP.HRA_SUPMST
                  WHERE HRA_SUPMST.STATUS = 'Y' AND /*and emp_no='109233'--test*/HRA_SUPMST.EMP_NO NOT IN 
                     (
                        SELECT HRE_PROFILE$3.EMP_NO
                        FROM HRP.HRE_PROFILE  AS HRE_PROFILE$3
                        WHERE HRE_PROFILE$3.ITEM_NO IN ( 'EMP01', 'EMP02' )
                     )
               )  AS fci
            WHERE ssma_oracle.to_char_date(fci.START_DATE, 'yyyy-mm-dd') BETWEEN @SSTARTDATE AND @SENDDATE/*where to_char(start_date,'yyyy-mm-dd') = '2011-10-13' --test       and emp_no = '101756'*/

      OPEN CURSOR1

      WHILE 1 = 1
      
         BEGIN

            FETCH CURSOR1
                INTO 
                  @SEMP_NO, 
                  @SSTART_DATE, 
                  @SEND_DATE, 
                  @SSTART_TIME, 
                  @SEND_TIME, 
                  @SORGANTYPE

            /*
            *   SSMA warning messages:
            *   O2SS0113: The value of @@FETCH_STATUS might be changed by previous FETCH operations on other cursors, if the cursors are used simultaneously.
            */

            IF @@FETCH_STATUS <> 0
               BREAK

            
            /*
            *       TEST
            *         itest := itest +1;
            *   
            *         INSERT INTO HRP.HRE_EMP_TEST  (EMP_NO,I) VALUES  (sEMP_NO,itest);
            *         COMMIT;
            *
            *    EndDate - StartDate +1 => 要跑的迴圈次數
            */
            SET @SDAYCNT = ssma_oracle.datediff(ssma_oracle.to_date2(@SEND_DATE, 'yyyy-mm-dd'), ssma_oracle.to_date2(@SSTART_DATE, 'yyyy-mm-dd')) + 1

            IF @SEND_TIME = '0000'
               SET @SDAYCNT = @SDAYCNT - 1

            DECLARE
               @I int

            SET @I = 1

            DECLARE
               @loop$bound int

            SET @loop$bound = @SDAYCNT

            
            /*
            *   20180430 108978 增加判斷有跨天的時候結束時間大於0000 ，如NK(1/1 2100- 1/2 0700)
            *    請假起時 ~ 班表下班時
            */
            WHILE @I <= @loop$bound
            
               BEGIN

                  SET @LATE_FLAG = 'N'

                  SET @IREALYWORKMIN = 0

                  SET @SVALIDDATE = DATEADD(D, -1, DATEADD(D, @I, ssma_oracle.to_date2(@SSTART_DATE, 'yyyy-mm-dd')))

                  /* 班表*/
                  SET @ICLASSKIND = HRP.EHRPHRAFUNC_PKG$F_GETCLASSKIND(@SEMP_NO, @SVALIDDATE, @SORGANTYPE)

                  
                  /*
                  *           dbms_output.put_line('iClassKind'||iClassKind||sValidDate);
                  *    當日班別時段數,不含 OnCall
                  */
                  SELECT @ICLASSCNT = count_big(*)
                  FROM HRP.HRA_CLASSDTL
                  WHERE HRA_CLASSDTL.CLASS_CODE = @ICLASSKIND AND HRA_CLASSDTL.SHIFT_NO <> 4

                  DECLARE
                     @J int

                  SET @J = 1

                  DECLARE
                     @loop$bound$2 int

                  SET @loop$bound$2 = @ICLASSCNT

                  WHILE @J <= @loop$bound$2
                  
                     BEGIN

                        /* 當日上班時段出勤*/
                        SELECT @SCHKIN_WKTM = HRA_CLASSDTL.CHKIN_WKTM, @SCHKOUT_WKTM = HRA_CLASSDTL.CHKOUT_WKTM, @SSTART_REST = HRA_CLASSDTL.START_REST, @SEND_REST = HRA_CLASSDTL.END_REST
                        FROM HRP.HRA_CLASSDTL
                        WHERE HRA_CLASSDTL.CLASS_CODE = @ICLASSKIND AND HRA_CLASSDTL.SHIFT_NO = @J

                        
                        /*
                        *   20260116 by108482 確認人員實際排班日
                        *   SELECT (CASE
                        *                      WHEN TO_DATE('2023-04-220000', 'yyyy/mm/ddHH24MI') BETWEEN
                        *                           TO_DATE('2023-04-222200', 'yyyy/mm/ddHH24MI') AND
                        *                           TO_DATE('2023-04-230800', 'yyyy/mm/ddHH24MI') THEN
                        *                       1
                        *                      ELSE
                        *                       2
                        *                    END)
                        *               INTO iCheckDate
                        *               FROM DUAL;
                        *    當日上班
                        */
                        BEGIN

                           BEGIN TRY
                              SELECT @SCHKIN_CARD = HRA_CADSIGN.CHKIN_CARD, @SCHKOUT_CARD = HRA_CADSIGN.CHKOUT_CARD, @SNIGHT_FLAG = HRA_CADSIGN.NIGHT_FLAG
                              FROM HRP.HRA_CADSIGN
                              WHERE 
                                 HRA_CADSIGN.EMP_NO = @SEMP_NO AND 
                                 ssma_oracle.to_char_date(HRA_CADSIGN.ATT_DATE, 'YYYY-MM-DD') = ssma_oracle.to_char_date(@SVALIDDATE, 'yyyy-mm-dd') AND 
                                 HRA_CADSIGN.SHIFT_NO = @J AND 
                                 HRA_CADSIGN.ORG_BY = @SORGANTYPE
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
                                 BEGIN

                                    SET @SCHKIN_CARD = NULL

                                    SET @SCHKOUT_CARD = NULL

                                    SET @SNIGHT_FLAG = NULL

                                 END
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

                        
                        /*
                        *    sCHKIN_CARD,sCHKOUT_CARD,sNIGHT_FLAG 有可能是 null , 必需考慮
                        *    sCHKIN_CARD 打卡時間
                        *    sCHKIN_WKTM 班別時間
                        */
                        IF (@SCHKIN_CARD IS NOT NULL AND @SCHKIN_CARD != '') AND (@SCHKOUT_CARD IS NOT NULL AND @SCHKOUT_CARD != '')
                           BEGIN

                              /* 上班*/
                              IF @SCHKIN_CARD <= CAST(@SCHKIN_WKTM AS float(53)) + 2
                                 SET @SCHKIN_CARD = @SCHKIN_WKTM
                              ELSE 
                                 BEGIN
                                    /*跨夜班*/
                                    IF @SCHKIN_WKTM BETWEEN '0000' AND '0800'
                                       BEGIN
                                          IF @SCHKIN_CARD BETWEEN '1600' AND '2400'
                                             SET @SCHKIN_CARD = @SCHKIN_WKTM
                                       END
                                 END

                              
                              /*
                              *   20180910 108978 增加記錄遲到註記
                              *   20260114 108482 2026年度開始遲到改30分鐘(含)內
                              */
                              IF CONVERT(varchar(4), @SVALIDDATE, 102) <= '2025'
                                 BEGIN
                                    IF (
                                       (@SEND_TIME IS NOT NULL AND @SEND_TIME != '') AND 
                                       CAST(@SCHKIN_CARD AS numeric(38, 10)) <= CAST(@SCHKIN_WKTM AS numeric(38, 10)) + 15 AND 
                                       CAST(@SCHKIN_CARD AS numeric(38, 10)) > CAST(@SCHKIN_WKTM AS numeric(38, 10)) + 2)
                                       SET @LATE_FLAG = 'Y'
                                 END
                              ELSE 
                                 BEGIN
                                    IF (
                                       (@SEND_TIME IS NOT NULL AND @SEND_TIME != '') AND 
                                       CAST(@SCHKIN_CARD AS numeric(38, 10)) <= CAST(@SCHKIN_WKTM AS numeric(38, 10)) + 30 AND 
                                       CAST(@SCHKIN_CARD AS numeric(38, 10)) > CAST(@SCHKIN_WKTM AS numeric(38, 10)) + 2)
                                       SET @LATE_FLAG = 'Y'
                                 END

                              /* 下班*/
                              IF @SCHKOUT_CARD >= 
                                 CASE 
                                    WHEN @SCHKOUT_WKTM = '0000' THEN '2400'
                                    ELSE @SCHKOUT_WKTM
                                 END
                                 SET @SCHKOUT_CARD = @SCHKOUT_WKTM
                              ELSE 
                                 BEGIN
                                    IF ((@SCHKOUT_CARD BETWEEN '1600' AND '2400') OR (@SCHKOUT_CARD = '0000'))
                                       BEGIN
                                          /*IF ((sCHKOUT_WKTM BETWEEN '1600' AND '2400') OR (sCHKOUT_WKTM = '0000')) THEN*/
                                          IF @SCHKOUT_CARD BETWEEN '0000' AND '0800'
                                             SET @SCHKOUT_CARD = @SCHKOUT_WKTM
                                       END
                                 END

                              SET @IREALYWORKMIN = @IREALYWORKMIN + HRP.EHRPHRA12_PKG$GETOFFHRS(
                                 ssma_oracle.to_char_date(@SVALIDDATE, 'yyyy-mm-dd'), 
                                 @SCHKIN_CARD, 
                                 
                                    CASE 
                                       WHEN (@SNIGHT_FLAG = 'Y' OR @SCHKOUT_WKTM = '0800'/*RN*/) THEN ssma_oracle.to_char_date(DATEADD(D, 1, @SVALIDDATE), 'yyyy-mm-dd')
                                       ELSE ssma_oracle.to_char_date(@SVALIDDATE, 'yyyy-mm-dd')
                                    END, 
                                 /*(CASE WHEN (sNIGHT_FLAG = 'Y' AND (sCHKIN_WKTM > sCHKOUT_WKTM)) THEN TO_CHAR(sValidDate + 1, 'yyyy-mm-dd') ELSE TO_CHAR(sValidDate, 'yyyy-mm-dd') END),*/@SCHKOUT_CARD, 
                                 @SEMP_NO, 
                                 @SORGANTYPE)

                           END
                        ELSE 
                           BEGIN

                              BEGIN

                                 BEGIN TRY
                                    SELECT @ICARDSIGNCNT = count_big(*)
                                    FROM HRP.HRA_CADSIGN
                                    WHERE 
                                       HRA_CADSIGN.EMP_NO = @SEMP_NO AND 
                                       ssma_oracle.to_char_date(HRA_CADSIGN.ATT_DATE, 'YYYY-MM-DD') = ssma_oracle.to_char_date(@SVALIDDATE, 'yyyy-mm-dd') AND 
                                       HRA_CADSIGN.SHIFT_NO = 1 AND 
                                       HRA_CADSIGN.ORG_BY = @SORGANTYPE
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
                                       SET @ICARDSIGNCNT = 0
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

                              IF (@ICARDSIGNCNT > 0)
                                 BEGIN

                                    /*增加判斷打卡異常的sCHKIN_CARD或sCHKOUT_CARD是 null,工作時數為應班工時/2,在算曠職的時候已經計算，所以在請假時數不足的時候不要在計算進去，避免扣兩次。 20181106 108978*/
                                    BEGIN

                                       BEGIN TRY
                                          SELECT @IWORKMIN = HRA_CLASSMST.WORK_HRS * 60
                                          FROM HRP.HRA_CLASSMST
                                          WHERE HRA_CLASSMST.CLASS_CODE = @ICLASSKIND
                                       END TRY

                                       BEGIN CATCH
                                          BEGIN
                                             SET @IWORKMIN = 0
                                          END
                                       END CATCH

                                    END

                                    SET @IREALYWORKMIN = @IREALYWORKMIN + (@IWORKMIN / 2)

                                 END

                           END

                        SET @J = @J + 1

                     END

                  /* 借休單*/
                  BEGIN

                     BEGIN TRY
                        SELECT @SVACMIN = isnull(sum(HRA_OFFREC.OTM_HRS) * 60, 0)
                        FROM HRP.HRA_OFFREC
                        WHERE 
                           HRA_OFFREC.EMP_NO = @SEMP_NO AND 
                           ssma_oracle.to_char_date(@SVALIDDATE, 'YYYY-MM-DD') = ssma_oracle.to_char_date(HRA_OFFREC.START_DATE, 'YYYY-MM-DD') AND 
                           HRA_OFFREC.STATUS = 'Y' AND 
                           HRA_OFFREC.ITEM_TYPE = 'O' AND 
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
                           SET @SVACMIN = 0
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

                  SET @IREALYWORKMIN = @IREALYWORKMIN + @SVACMIN

                  /*補休單*/
                  BEGIN

                     BEGIN TRY
                        SELECT @SVACMIN = isnull(sum(HRA_SUPMST.SUP_HRS) * 60, 0)
                        FROM HRP.HRA_SUPMST
                        WHERE 
                           HRA_SUPMST.EMP_NO = @SEMP_NO AND 
                           ssma_oracle.to_char_date(@SVALIDDATE, 'YYYY-MM-DD') = ssma_oracle.to_char_date(HRA_SUPMST.START_DATE, 'YYYY-MM-DD') AND 
                           HRA_SUPMST.STATUS = 'Y' AND 
                           HRA_SUPMST.ORG_BY = @SORGANTYPE
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
                           SET @SVACMIN = 0
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

                  SET @IREALYWORKMIN = @IREALYWORKMIN + @SVACMIN

                  
                  /*
                  *    電子假卡 時數 -- 可 "跨天" 要注意
                  *    頭尾 注意 即可!!
                  */
                  BEGIN

                     BEGIN TRY
                        SELECT @ICNT = count_big(*)
                        FROM HRP.HRA_EVCREC
                        WHERE 
                           HRA_EVCREC.EMP_NO = @SEMP_NO AND 
                           (ssma_oracle.to_char_date(@SVALIDDATE, 'YYYY-MM-DD') BETWEEN ssma_oracle.to_char_date(HRA_EVCREC.START_DATE, 'YYYY-MM-DD') AND ssma_oracle.to_char_date(HRA_EVCREC.END_DATE, 'YYYY-MM-DD')) AND 
                           HRA_EVCREC.STATUS = 'Y' AND 
                           HRA_EVCREC.ORG_BY = @SORGANTYPE
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

                  IF @ICNT > 0
                     BEGIN

                        DECLARE
                           @CURSOR_PARAM_CURSOR2_SEMPNO varchar(max), 
                           @CURSOR_PARAM_CURSOR2_SVALIDDATE datetime2(0)

                        SET @CURSOR_PARAM_CURSOR2_SEMPNO = @SEMP_NO

                        SET @CURSOR_PARAM_CURSOR2_SVALIDDATE = @SVALIDDATE

                        DECLARE
                            CURSOR2 CURSOR LOCAL FOR 
                              SELECT 
                                 ssma_oracle.to_char_date(HRA_EVCREC.START_DATE, 'YYYY-MM-DD'), 
                                 HRA_EVCREC.START_TIME, 
                                 ssma_oracle.to_char_date(HRA_EVCREC.END_DATE, 'YYYY-MM-DD'), 
                                 HRA_EVCREC.END_TIME, 
                                 HRA_EVCREC.ORG_BY
                              FROM HRP.HRA_EVCREC
                              WHERE 
                                 HRA_EVCREC.EMP_NO = @CURSOR_PARAM_CURSOR2_SEMPNO AND 
                                 (ssma_oracle.to_char_date(@CURSOR_PARAM_CURSOR2_SVALIDDATE, 'YYYY-MM-DD') BETWEEN ssma_oracle.to_char_date(HRA_EVCREC.START_DATE, 'YYYY-MM-DD') AND ssma_oracle.to_char_date(HRA_EVCREC.END_DATE, 'YYYY-MM-DD')) AND 
                                 HRA_EVCREC.STATUS = 'Y'

                        OPEN CURSOR2

                        WHILE 1 = 1
                        
                           BEGIN

                              FETCH CURSOR2
                                  INTO 
                                    @VSTART_DATE, 
                                    @VSTART_TIME, 
                                    @VEND_DATE, 
                                    @VEND_TIME, 
                                    @SORGANTYPE

                              /*
                              *   SSMA warning messages:
                              *   O2SS0113: The value of @@FETCH_STATUS might be changed by previous FETCH operations on other cursors, if the cursors are used simultaneously.
                              */

                              IF @@FETCH_STATUS <> 0
                                 BREAK

                              IF ssma_oracle.to_char_date(@SVALIDDATE, 'yyyy-mm-dd') = @VSTART_DATE OR (ssma_oracle.to_char_date(DATEADD(D, 1, @SVALIDDATE), 'yyyy-mm-dd') = @VEND_DATE AND @VEND_TIME = '0000')
                                 BEGIN

                                    BEGIN

                                       BEGIN TRY
                                          SELECT @SCHKIN_WKTM = T1.CHKIN_WKTM, @SCHKOUT_WKTM = T1.CHKOUT_WKTM, @SSTART_REST = T1.START_REST, @SEND_REST = T1.END_REST, @SWORK_HRS = 
                                             (
                                                SELECT HRA_CLASSMST.WORK_HRS
                                                FROM HRP.HRA_CLASSMST
                                                WHERE HRA_CLASSMST.CLASS_CODE = T1.CLASS_CODE
                                             )
                                          FROM HRP.HRA_CLASSDTL  AS T1
                                          WHERE T1.CLASS_CODE = @ICLASSKIND AND T1.SHIFT_NO = 
                                             (
                                                SELECT max(HRA_CLASSDTL.SHIFT_NO) AS expr
                                                FROM HRP.HRA_CLASSDTL
                                                WHERE HRA_CLASSDTL.CLASS_CODE = @ICLASSKIND AND HRA_CLASSDTL.SHIFT_NO <> '4'
                                             )
                                       END TRY

                                       BEGIN CATCH
                                          BEGIN
                                             DECLARE
                                                @db_null_statement int
                                          END
                                       END CATCH

                                    END

                                    /*請假是同一天*/
                                    IF @VSTART_DATE = @VEND_DATE
                                       SET @VEND_TIME = @VEND_TIME
                                    ELSE 
                                       /*結束時間為班表時間*/
                                       SET @VEND_TIME = @SCHKOUT_WKTM

                                    /*JB班休假多天，最後一天檢核開始時間抓班表開始時間 20210901 by108482*/
                                    IF (ssma_oracle.to_char_date(DATEADD(D, 1, @SVALIDDATE), 'yyyy-mm-dd') = @VEND_DATE AND @VEND_TIME = '0000') AND ssma_oracle.to_char_date(@SVALIDDATE, 'yyyy-mm-dd') <> @VSTART_DATE
                                       SET @VSTART_TIME = @SCHKIN_WKTM

                                    
                                    /*
                                    *   開始時間需判斷，取整點
                                    *   IF SUBSTR(vSTART_TIME,3,4) BETWEEN '00' AND '29' THEN
                                    *                 vSTART_TIME := SUBSTR(vSTART_TIME,1,2) || '00';
                                    *                 ELSIF SUBSTR(vSTART_TIME,3,4) BETWEEN '30' AND '59' THEN
                                    *                 vSTART_TIME := SUBSTR(vSTART_TIME,1,2) || '30';
                                    *                 END IF;
                                    *   20231108 by108482 調整開始時間應往後判斷整點 EX:1333應認定為1400
                                    */
                                    IF substring(@VSTART_TIME, 3, 4) BETWEEN '01' AND '29'
                                       SET @VSTART_TIME = ISNULL(substring(@VSTART_TIME, 1, 2), '') + '30'
                                    ELSE 
                                       BEGIN
                                          IF substring(@VSTART_TIME, 3, 4) BETWEEN '31' AND '59'
                                             SET @VSTART_TIME = ISNULL(CAST(CAST(substring(@VSTART_TIME, 1, 2) AS numeric(38, 10)) + 1 AS nvarchar(max)), '') + '00'
                                       END

                                    
                                    /*
                                    *   結束時間需判斷，取整點(因假卡是半小時為單位,避免誤算曠職) 20210629 by108482
                                    *   IF SUBSTR(vEND_TIME,3,4) BETWEEN '01' AND '29' THEN
                                    *                   vEND_TIME := SUBSTR(vEND_TIME,1,2) || '30';
                                    *                 ELSIF SUBSTR(vEND_TIME,3,4) BETWEEN '31' AND '59' THEN
                                    *                   vEND_TIME := to_number(SUBSTR(vEND_TIME,1,2))+1 || '00';
                                    *                 END IF;
                                    *   20240409 by108482 調整結束時間應往前判斷整點 EX:2359應認定為2330
                                    */
                                    IF substring(@VEND_TIME, 3, 4) BETWEEN '01' AND '29'
                                       SET @VEND_TIME = ISNULL(substring(@VEND_TIME, 1, 2), '') + '00'
                                    ELSE 
                                       BEGIN
                                          IF substring(@VEND_TIME, 3, 4) BETWEEN '31' AND '59'
                                             SET @VEND_TIME = ISNULL(substring(@VEND_TIME, 1, 2), '') + '30'
                                       END

                                    IF @VEND_TIME = '2400'
                                       BEGIN

                                          SET @VEND_TIME = '0000'

                                          SET @VEND_DATE = ssma_oracle.to_char_date(DATEADD(D, 1, CONVERT(datetime2, @VEND_DATE, 111)), 'yyyy-mm-dd')

                                       END

                                    IF ssma_oracle.length_varchar(@VSTART_TIME) = 3
                                       SET @VSTART_TIME = '0' + ISNULL(@VSTART_TIME, '')

                                    IF ssma_oracle.length_varchar(@VEND_TIME) = 3
                                       SET @VEND_TIME = '0' + ISNULL(@VEND_TIME, '')

                                    /*JB班的工時判斷*/
                                    IF ssma_oracle.to_char_date(DATEADD(D, 1, @SVALIDDATE), 'yyyy-mm-dd') <= @VEND_DATE AND @VEND_TIME = '0000'
                                       SET @IREALYWORKMIN = @IREALYWORKMIN + HRP.EHRPHRA12_PKG$GETOFFHRS(
                                          ssma_oracle.to_char_date(@SVALIDDATE, 'yyyy-mm-dd'), 
                                          @VSTART_TIME, 
                                          ssma_oracle.to_char_date(DATEADD(D, 1, @SVALIDDATE), 'yyyy-mm-dd'), 
                                          @VEND_TIME, 
                                          @SEMP_NO, 
                                          @SORGANTYPE)
                                    ELSE 
                                       IF ssma_oracle.to_char_date(DATEADD(D, 1, @SVALIDDATE), 'yyyy-mm-dd') <= @VEND_DATE AND @VEND_TIME >= '0000'
                                          SET @IREALYWORKMIN = @IREALYWORKMIN + HRP.EHRPHRA12_PKG$GETOFFHRS(
                                             ssma_oracle.to_char_date(@SVALIDDATE, 'yyyy-mm-dd'), 
                                             @VSTART_TIME, 
                                             ssma_oracle.to_char_date(DATEADD(D, 1, @SVALIDDATE), 'yyyy-mm-dd'), 
                                             @VEND_TIME, 
                                             @SEMP_NO, 
                                             @SORGANTYPE)
                                       ELSE 
                                          SET @IREALYWORKMIN = @IREALYWORKMIN + HRP.EHRPHRA12_PKG$GETOFFHRS(
                                             ssma_oracle.to_char_date(@SVALIDDATE, 'yyyy-mm-dd'), 
                                             @VSTART_TIME, 
                                             ssma_oracle.to_char_date(@SVALIDDATE, 'yyyy-mm-dd'), 
                                             @VEND_TIME, 
                                             @SEMP_NO, 
                                             @SORGANTYPE)

                                 END
                              ELSE 
                                 IF ssma_oracle.to_char_date(@SVALIDDATE, 'yyyy-mm-dd') = @VEND_DATE
                                    BEGIN

                                       BEGIN

                                          BEGIN TRY
                                             SELECT @SCHKIN_WKTM = T1.CHKIN_WKTM, @SCHKOUT_WKTM = T1.CHKOUT_WKTM, @SSTART_REST = T1.START_REST, @SEND_REST = T1.END_REST, @SWORK_HRS = 
                                                (
                                                   SELECT HRA_CLASSMST.WORK_HRS
                                                   FROM HRP.HRA_CLASSMST
                                                   WHERE HRA_CLASSMST.CLASS_CODE = T1.CLASS_CODE
                                                )
                                             FROM HRP.HRA_CLASSDTL  AS T1
                                             WHERE T1.CLASS_CODE = @ICLASSKIND AND T1.SHIFT_NO = 
                                                (
                                                   SELECT min(HRA_CLASSDTL.SHIFT_NO) AS expr
                                                   FROM HRP.HRA_CLASSDTL
                                                   WHERE HRA_CLASSDTL.CLASS_CODE = @ICLASSKIND AND HRA_CLASSDTL.SHIFT_NO <> '4'
                                                )
                                          END TRY

                                          BEGIN CATCH
                                             BEGIN
                                                DECLARE
                                                   @db_null_statement$2 int
                                             END
                                          END CATCH

                                       END

                                       SET @VSTART_TIME = @SCHKIN_WKTM

                                       SET @IREALYWORKMIN = @IREALYWORKMIN + HRP.EHRPHRA12_PKG$GETOFFHRS(
                                          ssma_oracle.to_char_date(@SVALIDDATE, 'yyyy-mm-dd'), 
                                          @VSTART_TIME, 
                                          ssma_oracle.to_char_date(@SVALIDDATE, 'yyyy-mm-dd'), 
                                          @VEND_TIME, 
                                          @SEMP_NO, 
                                          @SORGANTYPE)

                                    END
                                 /*班表上班日 ~ 請假迄時*/
                                 ELSE 
                                    BEGIN

                                       BEGIN

                                          BEGIN TRY
                                             SELECT @SCHKIN_WKTM = T1.CHKIN_WKTM, @SCHKOUT_WKTM = T1.CHKOUT_WKTM, @SSTART_REST = T1.START_REST, @SEND_REST = T1.END_REST, @SWORK_HRS = 
                                                (
                                                   SELECT HRA_CLASSMST.WORK_HRS
                                                   FROM HRP.HRA_CLASSMST
                                                   WHERE HRA_CLASSMST.CLASS_CODE = T1.CLASS_CODE
                                                )
                                             FROM HRP.HRA_CLASSDTL  AS T1
                                             WHERE T1.CLASS_CODE = @ICLASSKIND AND T1.SHIFT_NO = 
                                                (
                                                   SELECT min(HRA_CLASSDTL.SHIFT_NO) AS expr
                                                   FROM HRP.HRA_CLASSDTL
                                                   WHERE HRA_CLASSDTL.CLASS_CODE = @ICLASSKIND AND HRA_CLASSDTL.SHIFT_NO <> '4'
                                                )
                                          END TRY

                                          BEGIN CATCH
                                             BEGIN
                                                DECLARE
                                                   @db_null_statement$3 int
                                             END
                                          END CATCH

                                       END

                                       SET @IREALYWORKMIN = @IREALYWORKMIN + @SWORK_HRS * 60

                                    END

                           END

                        CLOSE CURSOR2

                        DEALLOCATE CURSOR2

                     END

                  
                  /*
                  *     dbms_output.put_line('------->' || iClassKind || sEMP_NO);
                  *    應上班分鐘
                  */
                  BEGIN

                     BEGIN TRY
                        SELECT @IWORKMIN = HRA_CLASSMST.WORK_HRS * 60
                        FROM HRP.HRA_CLASSMST
                        WHERE HRA_CLASSMST.CLASS_CODE = @ICLASSKIND
                     END TRY

                     BEGIN CATCH
                        BEGIN
                           SET @IWORKMIN = 0
                        END
                     END CATCH

                  END

                  /*20200115 by108482 ZA班工時歸零*/
                  IF @ICLASSKIND = 'ZA'
                     SET @IWORKMIN = 0

                  /* 應出勤時間是否小於等於 總上班時間(出勤+假單)*/
                  IF @IWORKMIN > @IREALYWORKMIN
                     BEGIN

                        SET @INSUFFICIENT_MIN = @IWORKMIN - @IREALYWORKMIN

                        SET @INSUFFICIENT_TIME = @IWORKMIN - @IREALYWORKMIN

                        SET @INSUFFICIENT_TIME_TMP = @INSUFFICIENT_TIME - ssma_oracle.trunc(@INSUFFICIENT_TIME / 60, DEFAULT) * 60

                        SET @INSUFFICIENT_TIME = ssma_oracle.trunc(@INSUFFICIENT_TIME / 60, DEFAULT)

                        /*曠職時數最小單位為0.5小時 108978*/
                        IF (@INSUFFICIENT_TIME_TMP = 0)
                           SET @INSUFFICIENT_TIME_TMP = 0
                        ELSE 
                           IF (@INSUFFICIENT_TIME_TMP <= 30)
                              SET @INSUFFICIENT_TIME_TMP = 0.5
                           ELSE 
                              SET @INSUFFICIENT_TIME_TMP = 1

                        SET @INSUFFICIENT_TIME = @INSUFFICIENT_TIME + @INSUFFICIENT_TIME_TMP

                        IF @LATE_FLAG = 'Y'
                           SET @LATE_TIME = CAST(@SCHKIN_CARD AS float(53)) - CAST(@SCHKIN_WKTM AS float(53))
                        ELSE 
                           SET @LATE_TIME = 0

                        SELECT @SEMP_NAME = T1.CH_NAME, @SDEPT_NO = T1.DEPT_NO, @SDEPT_NAME = 
                           (
                              SELECT HRE_ORGBAS.CH_NAME
                              FROM HRP.HRE_ORGBAS
                              WHERE HRE_ORGBAS.DEPT_NO = T1.DEPT_NO AND HRE_ORGBAS.ORGAN_TYPE = T1.ORGAN_TYPE
                           )
                        FROM HRP.HRE_EMPBAS  AS T1
                        WHERE T1.EMP_NO = @SEMP_NO

                        
                        /*
                        *        AND ORGAN_TYPE = sOrganType;
                        *   201908 by108482 時數不足超過0.5小時且有遲到者改註記Z,避免曠職未計算到
                        *   IF Insufficient_time > 0.5 AND late_flag = 'Y' THEN
                        */
                        IF (@INSUFFICIENT_TIME / 60) > 0.5 AND @LATE_FLAG = 'Y'
                           SET @LATE_FLAG = 'Z'

                        SET @INSUFFICIENT_MIN = @INSUFFICIENT_MIN - @LATE_TIME

                        IF @INSUFFICIENT_MIN < 0
                           SET @INSUFFICIENT_MIN = 0

                        IF (CONVERT(varchar(max), @SVALIDDATE, 112) < CONVERT(varchar(max), sysdatetime(), 112))
                           BEGIN

                              BEGIN TRY
                                 
                                 /*
                                 *   排除100812 跨天請假且結束時間0000 之資料
                                 *   IF (sEMP_NO = '101029' AND TO_CHAR(sValidDate, 'YYYY-MM-DD') = '2011-10-13') THEN
                                 *     NULL;
                                 *   ELSE
                                 *   排除2024-07-25颱風假資料 IF TO_CHAR(sValidDate, 'YYYY-MM-DD') IN ('2024-07-25','2024-07-26') THEN
                                 *   排除2024-10-02,2024-10-03,2024-10-04,2024-10-31颱風假資料 IF TO_CHAR(sValidDate, 'YYYY-MM-DD') IN ('2024-10-02','2024-10-03','2024-10-04','2024-10-31') THEN
                                 *   排除2025-07-29颱風(豪雨)假資料, 2025-08-13颱風部分資料
                                 */
                                 IF ssma_oracle.to_char_date(@SVALIDDATE, 'YYYY-MM-DD') IN (  '2025-07-29' )
                                    DECLARE
                                       @db_null_statement$4 int
                                 ELSE 
                                    IF ssma_oracle.to_char_date(@SVALIDDATE, 'YYYY-MM-DD') IN (  '2025-08-13' ) AND @SEMP_NO = '103725'
                                       DECLARE
                                          @db_null_statement$5 int
                                    ELSE 
                                       BEGIN

                                          
                                          /*
                                          *   INSERT INTO PUR_MED
                                          *               (MED_ID, PUR_MED.INSU_CODE, PUR_MED.MED_DESC, PUR_MED.ALISE_DESC, PUR_MED.QTY_DESC, PUR_MED.CREATION_DATE, 
                                          *                PUR_MED.ORGAN_TYPE, PUR_MED.NUMBER1, PUR_MED.NUMBER2, PUR_MED.FLOAT1, PUR_MED.BRAND,
                                          *                PUR_MED.VENDOR_ID, PUR_MED.MECHANISM, PUR_MED.DOSAGE, PUR_MED.INDUCATION, PUR_MED.UNLABCL_USE, PUR_MED.INSU_DATA)
                                          *             VALUES
                                          *               (sSeq,
                                          *                sEMP_NO,
                                          *                sEMP_NAME,
                                          *                sDEPT_NO,
                                          *                sDEPT_NAME,
                                          *                sValidDate,
                                          *                sOrganType,
                                          *                Insufficient_time,
                                          *                Insufficient_min,
                                          *                late_time,
                                          *                late_flag,
                                          *                sCHKIN_CARD,
                                          *                sCHKOUT_CARD,
                                          *                sCHKIN_WKTM,
                                          *                sCHKOUT_WKTM,
                                          *                sSTART_REST,
                                          *                sEND_REST);
                                          */
                                          IF @@TRANCOUNT > 0
                                             COMMIT TRANSACTION 

                                          SET @SSEQ = @SSEQ + 1

                                          INSERT HRP.HRA_9610_TEMP(
                                             EMP_NO, 
                                             EMP_NAME, 
                                             DEPT_NO, 
                                             DEPT_NAME, 
                                             VAC_DATE, 
                                             ORGAN_TYPE, 
                                             INSUFFICIENT_TIME, 
                                             LATE_FLAG, 
                                             INSUFFICIENT_MIN, 
                                             LATE_MINUTE, 
                                             CHKIN_CARD, 
                                             CHKOUT_CARD, 
                                             CHKIN_REAL, 
                                             CHKOUT_REAL, 
                                             START_TIME_S, 
                                             END_TIME_S)
                                             VALUES (
                                                @SEMP_NO, 
                                                @SEMP_NAME, 
                                                @SDEPT_NO, 
                                                @SDEPT_NAME, 
                                                ssma_oracle.to_char_date(@SVALIDDATE, 'YYYY-MM-DD'), 
                                                @SORGANTYPE, 
                                                @INSUFFICIENT_TIME, 
                                                @LATE_FLAG, 
                                                @INSUFFICIENT_MIN, 
                                                @LATE_TIME, 
                                                @SCHKIN_CARD, 
                                                @SCHKOUT_CARD, 
                                                @SCHKIN_WKTM, 
                                                @SCHKOUT_WKTM, 
                                                @SSTART_REST, 
                                                @SEND_REST)

                                       END
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

                                 BEGIN
                                    SET @RTNCODE = ssma_oracle.db_error_sqlcode(@exceptionidentifier$6, @errornumber$6)
                                 END

                              END CATCH

                           END

                     END

                  SET @I = @I + 1

               END
            
            /*
            *    sphinx  94.09.28
            *   JB班的結算時間判斷
            */

         END

      CLOSE CURSOR1

      DEALLOCATE CURSOR1

      SET @RTNCODE = 0

      SET @return_value_argument = @RTNCODE

      RETURN 

      DECLARE
         @db_null_statement$6 int

      CONTINUE_FOREACH2:

      DECLARE
         @db_null_statement$7 int

   END
GO
BEGIN TRY
    EXEC sp_addextendedproperty
        N'MS_SSMA_SOURCE', N'HRP.EHRPHRA3_PKG.f_set_hra9610temp_test',
        N'SCHEMA', N'hrp',
        N'PROCEDURE', N'EHRPHRA3_PKG$F_SET_HRA9610TEMP_TEST$IMPL'
END TRY
BEGIN CATCH
    IF (@@TRANCOUNT > 0) ROLLBACK
    PRINT ERROR_MESSAGE()
END CATCH
GO
