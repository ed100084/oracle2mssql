CREATE OR ALTER PROCEDURE [ehrphra12_pkg].[hraC010a]
(    @p_otm_no NVARCHAR(MAX),
    @p_emp_no NVARCHAR(MAX),
    @p_start_date NVARCHAR(MAX),
    @p_start_time NVARCHAR(MAX),
    @p_end_date NVARCHAR(MAX),
    @p_end_time NVARCHAR(MAX),
    @p_start_date_tmp NVARCHAR(MAX),
    @p_on_call NVARCHAR(MAX),
    @p_status NVARCHAR(MAX),
    @OrganType_IN NVARCHAR(MAX),
    @p_otm_hrs NVARCHAR(MAX),
    @RtnCode DECIMAL(38,10) OUTPUT
)
AS
DECLARE @nCnt DECIMAL(38,10);
DECLARE @SOrganType NVARCHAR(10) = @OrganType_IN;
DECLARE @sStart NVARCHAR(20) = @p_start_date + @p_start_time;
DECLARE @sEnd NVARCHAR(20) = @p_end_date + @p_end_time;
DECLARE @sOtmhrs DECIMAL(5,1) = CAST(@p_otm_hrs AS DECIMAL(38,10));
DECLARE @sCLASS_CODE NVARCHAR(3);
DECLARE @i_end_date NVARCHAR(10);
DECLARE @iCnt DECIMAL(38,10);
DECLARE @iCnt2 INT;
DECLARE @sClassKind NVARCHAR(3);
DECLARE @sLastClassKind NVARCHAR(3);
DECLARE @sWorkHrs DECIMAL(5,1);
DECLARE @sTotAddHrs DECIMAL(5,1);
DECLARE @iCheckCard NVARCHAR(1);
DECLARE @iposlevel NVARCHAR(1);
DECLARE @LimitDay NVARCHAR(2);
DECLARE @sTotMonAdd DECIMAL(5,1);
DECLARE @sOtmsignHrs DECIMAL(5,1);
DECLARE @sMonClassAdd DECIMAL(5,1);
DECLARE @sStart1 NVARCHAR(20) = FORMAT(DATEADD(MINUTE, 1, CONVERT(DATETIME2, @sStart)), 'yyyy-MM-ddhhmm');
DECLARE @sEnd1 NVARCHAR(20) = FORMAT(DATEADD(MINUTE, -1, CONVERT(DATETIME2, @sEnd)), 'yyyy-MM-ddhhmm');
DECLARE @iRestStart NVARCHAR(4);
DECLARE @iRestEnd NVARCHAR(4);
DECLARE @iChkinWktm NVARCHAR(4);
DECLARE @iChkoutWktm NVARCHAR(4);
DECLARE @sNextCLASS_CODE NVARCHAR(3);
DECLARE @pchkinrea NVARCHAR(2);
DECLARE @pchkoutrea NVARCHAR(2);
DECLARE @pwkintm NVARCHAR(20);
DECLARE @pwkouttm NVARCHAR(20);
BEGIN
       SET @RtnCode = 0;
       SET @sWorkHrs = 0;
       SET @sTotAddHrs = 0;
   	   SET @sTotMonAdd = 0;
       SET @sOtmsignHrs = 0;
	     SET @sMonClassAdd = 0;
       SET @iCheckCard = 'N';
       
 
       --現有的加班單時間介於新加班單
       BEGIN TRY
    SELECT @nCnt = COUNT(*)
    FROM hra_otmsign
           WHERE emp_no = @p_emp_no
             AND ORG_BY = @SOrganType
             AND otm_no LIKE 'OTM%'
             AND ((@sStart1  BETWEEN FORMAT(start_date, 'yyyy-MM-dd') + start_time AND FORMAT(end_date, 'yyyy-MM-dd') + end_time)
              OR  (@sEnd1    BETWEEN FORMAT(start_date, 'yyyy-MM-dd') + start_time AND FORMAT(end_date, 'yyyy-MM-dd') + end_time ))
             AND status <> 'N'
             AND OTM_NO <> @p_otm_no;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() IN (1403, 100) BEGIN
        SET @nCnt = 0;
    END
END CATCH

       IF @nCnt = 0 BEGIN

       --新加班單介於現有的加班單時間
       BEGIN TRY
    SELECT @nCnt = COUNT(*)
    FROM hra_otmsign
           WHERE emp_no = @p_emp_no
             AND ORG_BY = @SOrganType
             AND otm_no like 'OTM%'
             AND ((FORMAT(start_date, 'yyyy-MM-dd') + start_time BETWEEN @sStart1 AND @sEnd1)
              OR  (FORMAT(end_date, 'yyyy-MM-dd')   + end_time   BETWEEN @sStart1 AND @sEnd1))
             AND status <> 'N'
             AND OTM_NO <> @p_otm_no;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() IN (1403, 100) BEGIN
        SET @nCnt = 0;
    END
END CATCH
       END


       IF @nCnt > 0 BEGIN
         IF @p_start_date_tmp <> 'N/A' BEGIN
           SET @sCLASS_CODE = [ehrphrafunc_pkg].[f_getClassKind](@p_emp_no,CONVERT(DATETIME2, @p_start_date_tmp),@SOrganType);
         END
         ELSE
         BEGIN
           SET @sCLASS_CODE = [ehrphrafunc_pkg].[f_getClassKind](@p_emp_no,CONVERT(DATETIME2, @p_start_date),@SOrganType);
         END

       BEGIN TRY
    SELECT @iRestStart = START_REST, @iRestEnd = END_REST
    FROM HRP.HRA_CLASSDTL
          WHERE CLASS_CODE = @sCLASS_CODE
            AND SHIFT_NO = '1';
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() IN (1403, 100) BEGIN
        SET @iRestStart = '0';
       SET @iRestEnd = '0';
    END
END CATCH

       IF @p_start_time BETWEEN  @iRestStart AND  @iRestEnd
       AND @p_end_time BETWEEN @iRestStart AND  @iRestEnd BEGIN

       --20180801 108978 這段有問題,要嚴格一點不能申請！
       --SET @nCnt = @nCnt -1;
       SET @nCnt = @nCnt;
       END
ELSE IF @iRestStart ='0' 
             AND @iRestEnd ='0' 
            -- AND @sCLASS_CODE='ZZ' 20161219 新增班別 ZX,ZY
            --20180725 108978 增加ZQ
             AND @sCLASS_CODE IN ('ZZ','ZX','ZY','ZQ') 
             BEGIN
       --20180516 108978 這段有問題，同時段不能申請才對！
       --SET @nCnt = @nCnt -1;
       SET @nCnt = @nCnt;

       --IF @iRestStart ='0' AND @iRestEnd ='0' AND @sCLASS_CODE<>'ZZ' THEN
       --SET @nCnt = @nCnt -1;
      -- END IF;

       END


       IF @nCnt > 0 BEGIN
       SET @RtnCode = 1;
       GOTO Continue_ForEach1 ;
       END

       END
       
       BEGIN TRY
    SELECT @iposlevel = pos_level
    FROM HRE_POSMST
        WHERE pos_no = (SELECT pos_no FROM hre_empbas WHERE emp_no = @p_emp_no);
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() IN (1403, 100) BEGIN
        SET @iposlevel = NULL;
    END
END CATCH
       --108482 20190306 7職等(含)以上人員不能自行申請加班
       
       IF @iposlevel IS NULL BEGIN
         SET @RtnCode = 99;
         GOTO Continue_ForEach1 ;
       END
ELSE IF @iposlevel >= 7 BEGIN
         SET @RtnCode = 17;
         GOTO Continue_ForEach1 ;
       END

        ------------------------- 加班簽到 -------------------------
       -- IF @p_start_date_tmp <> 'N/A' AND @p_start_date_tmp <> @p_start_date 代表 為跨夜申請
       -- 故 @sStart = @p_end_date + p_start_tim
       /*IF @p_start_date_tmp <> 'N/A' AND @p_start_date_tmp <> @p_start_date BEGIN
       SET @sStart = @p_end_date + @p_start_time;
       END*/

       BEGIN TRY
    SELECT @nCnt = count(*)
    FROM hra_otmsign
           WHERE emp_no = @p_emp_no
             AND ORG_BY = @SOrganType
             AND ((@sStart between FORMAT(start_date, 'yyyy-MM-dd') + start_time
                              and FORMAT(end_date, 'yyyy-MM-dd') + end_time)
             AND  (@sEnd   between FORMAT(start_date, 'yyyy-MM-dd') + start_time
                              and FORMAT(end_date, 'yyyy-MM-dd') + end_time))
             AND SUBSTRING(otm_no, 1, 3) = 'OTS';
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() IN (1403, 100) BEGIN
        SET @nCnt = 0;
    END
END CATCH

       IF @nCnt = 0 BEGIN
         SET @RtnCode = 2;     -- 無簽到時間
         --GOTO Continue_ForEach1 ;
       END
       ELSE
       BEGIN 
         SET @iCheckCard = 'Y'; --@nCnt<>0,有加班簽到 20181219 by108482
       END

       ------------------------- 加班簽到 -------------------------


       ------------------------- 一般簽到 -------------------------
       IF @RtnCode = 2 BEGIN
       -------------Check OnCall-----------
       SET @RtnCode = 0;
       
       IF @p_start_date_tmp <> 'N/A' BEGIN
         SET @sCLASS_CODE = [ehrphrafunc_pkg].[f_getClassKind](@p_emp_no,CONVERT(DATETIME2, @p_start_date_tmp),@SOrganType);
         BEGIN TRY
    SELECT @iChkinWktm = CHKIN_WKTM, @iChkoutWktm = CHKOUT_WKTM
    FROM HRA_CLASSDTL
            WHERE CLASS_CODE = @sCLASS_CODE
              AND SHIFT_NO = '1';
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() IN (1403, 100) BEGIN
        SET @iChkinWktm = 0;
           SET @iChkoutWktm = 0;
    END
END CATCH
         BEGIN TRY
    SELECT @nCnt = COUNT(*)
    FROM HRA_CADSIGN
            WHERE EMP_NO = @p_emp_no
              AND FORMAT(ATT_DATE, 'yyyy-mm-dd') = @p_start_date_tmp
              AND @sStart >=
                  (CASE WHEN @iChkinWktm < @iChkoutWktm AND CHKIN_CARD > CHKOUT_CARD THEN
                   FORMAT(ATT_DATE - 1, 'yyyy-mm-dd') + CHKIN_CARD ELSE
                   FORMAT(ATT_DATE, 'yyyy-mm-dd') + CHKIN_CARD END)
              AND (@sEnd BETWEEN
                  (CASE WHEN @iChkinWktm < @iChkoutWktm AND CHKIN_CARD > CHKOUT_CARD THEN
                   FORMAT(ATT_DATE - 1, 'yyyy-mm-dd') + CHKIN_CARD ELSE
                   FORMAT(ATT_DATE, 'yyyy-mm-dd') + CHKIN_CARD END) AND
                  (CASE WHEN @iChkinWktm > @iChkoutWktm AND CHKIN_CARD > CHKOUT_CARD THEN
                   --20201202增CHKIN_CARD > CHKOUT_CARD條件 by108482 嚴謹檢核
                   FORMAT(ATT_DATE + 1, 'yyyy-mm-dd') + CHKOUT_CARD ELSE
                   FORMAT(ATT_DATE, 'yyyy-mm-dd') + CHKOUT_CARD END));
           --20191014 by108482 原寫法僅檢核當天是否有打卡記錄，未檢核申請的時間起迄是否符合打卡的時間
           /*SELECT COUNT(*)
             INTO @nCnt
             FROM hra_cadsign
            WHERE emp_no = @p_emp_no
              AND FORMAT(att_date, 'yyyy-mm-dd') = @p_start_date_tmp;*/
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() IN (1403, 100) BEGIN
        SET @nCnt = 0;
    END
END CATCH
         --若查無記錄且申請起始時間>結束時間再次檢核
         --IF @nCnt = 0 AND @p_start_time > @p_end_time THEN
         IF @nCnt = 0 BEGIN --by108482 20211215 不卡時間條件
           SELECT @nCnt = COUNT(*)
    FROM hra_cadsign
            WHERE emp_no = @p_emp_no
              AND FORMAT(att_date, 'yyyy-mm-dd') = @p_start_date_tmp
              AND CHKIN_CARD > CHKOUT_CARD --20221123增 by108482 嚴謹檢核
              AND @sStart >= FORMAT(ATT_DATE, 'yyyy-mm-dd') + CHKIN_CARD
              AND @sEnd BETWEEN FORMAT(ATT_DATE, 'yyyy-mm-dd') + CHKIN_CARD
                           AND FORMAT(ATT_DATE + 1, 'yyyy-mm-dd') + CHKOUT_CARD;
         END
       END
       ELSE
       BEGIN
       --108978 20180913 RN班申請加班，和ZZ/ZX/ZY+RN申請加班
       SET @sCLASS_CODE = [ehrphrafunc_pkg].[f_getClassKind](@p_emp_no,CONVERT(DATETIME2, @p_start_date),@SOrganType);
       SET @sNextCLASS_CODE = [ehrphrafunc_pkg].[f_getClassKind](@p_emp_no,DATEADD(DAY, 1, CONVERT(DATETIME2, @p_start_date)),@SOrganType);
       --108482 20190125 RN班提前或延後加班，start_time都不會是0000，若start_time為0000則需跑else的SQL
       IF ((@sCLASS_CODE ='RN' OR @sNextCLASS_CODE='RN') AND @p_start_time<>'0000') BEGIN
        BEGIN TRY
    SELECT @nCnt = count(*)
    FROM hra_cadsign
               WHERE emp_no = @p_emp_no
                 AND (@sEnd BETWEEN FORMAT(att_date-1, 'yyyy-mm-dd') + chkin_card  AND  (FORMAT(att_date, 'yyyy-mm-dd') + chkout_card))                                           
                 AND (@sStart >= FORMAT(att_date-1, 'yyyy-mm-dd') + chkin_card );
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() IN (1403, 100) BEGIN
        SET @nCnt = 0;
    END
END CATCH
        
       END
       ELSE
       BEGIN
       
        BEGIN TRY
    SELECT @nCnt = count(*)
    FROM hra_cadsign
               WHERE emp_no = @p_emp_no
                 AND ORG_BY = @SOrganType
                 AND (@sEnd BETWEEN FORMAT(att_date, 'yyyy-mm-dd') + chkin_card  AND  case when Night_Flag='Y' then (FORMAT(att_date+1, 'yyyy-mm-dd') + chkout_card)
                                                else FORMAT(att_date, 'yyyy-mm-dd') + chkout_card
                                                end)
                 AND (@sStart >= FORMAT(att_date, 'yyyy-mm-dd') + chkin_card );
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() IN (1403, 100) BEGIN
        SET @nCnt = 0;
    END
END CATCH
       END
       END
       IF @nCnt = 0 BEGIN
          SET @RtnCode = 2;     -- 無簽到時間
          GOTO Continue_ForEach1 ;
       END
       END
       
       --檢核是否有因公才能申請 20181116 108978
       --非加班打卡才檢核一般打卡因公因私 20181219 by108482
         --IF (@sStart > '2011-09-010000') THEN
         IF (@sStart > '2011-09-010000') AND @iCheckCard = 'N' BEGIN
         IF @p_start_date_tmp <> 'N/A' BEGIN
           BEGIN TRY
    SELECT @pchkinrea = ISNULL(CHKIN_REA, 10), @pchkoutrea = ISNULL(CHKOUT_REA, 20), @pwkintm = FORMAT(ATT_DATE, 'yyyy-mm-dd') +
                    (SELECT CHKIN_WKTM
                       FROM HRA_CLASSDTL
                      WHERE CLASS_CODE = HRA_CADSIGN.CLASS_CODE
                        AND SHIFT_NO = HRA_CADSIGN.SHIFT_NO), @pwkouttm = /*FORMAT(ATT_DATE, 'yyyy-mm-dd') +
                    (SELECT CHKOUT_WKTM
                       FROM HRA_CLASSDTL
                      WHERE CLASS_CODE = HRA_CADSIGN.CLASS_CODE
                        AND SHIFT_NO = HRA_CADSIGN.SHIFT_NO)*/

                    (CASE
                      WHEN (SELECT CHKOUT_WKTM
                              FROM HRA_CLASSDTL
                             WHERE CLASS_CODE = HRA_CADSIGN.CLASS_CODE
                               AND SHIFT_NO = HRA_CADSIGN.SHIFT_NO) <
                           (SELECT CHKIN_WKTM
                              FROM HRA_CLASSDTL
                             WHERE CLASS_CODE = HRA_CADSIGN.CLASS_CODE
                               AND SHIFT_NO = HRA_CADSIGN.SHIFT_NO) THEN
                       FORMAT(ATT_DATE + 1, 'yyyy-mm-dd') +
                       (SELECT CHKOUT_WKTM
                          FROM HRA_CLASSDTL
                         WHERE CLASS_CODE = HRA_CADSIGN.CLASS_CODE
                           AND SHIFT_NO = HRA_CADSIGN.SHIFT_NO)
                      ELSE
                       FORMAT(ATT_DATE, 'yyyy-mm-dd') +
                       (SELECT CHKOUT_WKTM
                          FROM HRA_CLASSDTL
                         WHERE CLASS_CODE = HRA_CADSIGN.CLASS_CODE
                           AND SHIFT_NO = HRA_CADSIGN.SHIFT_NO)
                    END)
    FROM HRA_CADSIGN
              WHERE EMP_NO = @p_emp_no
                AND FORMAT(ATT_DATE, 'yyyy-mm-dd') = @p_start_date_tmp
                AND @sStart >=
                  (CASE WHEN @iChkinWktm < @iChkoutWktm AND CHKIN_CARD > CHKOUT_CARD THEN
                   FORMAT(ATT_DATE - 1, 'yyyy-mm-dd') + CHKIN_CARD ELSE
                   FORMAT(ATT_DATE, 'yyyy-mm-dd') + CHKIN_CARD END)
                AND (@sEnd BETWEEN
                  (CASE WHEN @iChkinWktm < @iChkoutWktm AND CHKIN_CARD > CHKOUT_CARD THEN
                   FORMAT(ATT_DATE - 1, 'yyyy-mm-dd') + CHKIN_CARD ELSE
                   FORMAT(ATT_DATE, 'yyyy-mm-dd') + CHKIN_CARD END) AND
                  (CASE WHEN @iChkinWktm > @iChkoutWktm THEN
                   FORMAT(ATT_DATE + 1, 'yyyy-mm-dd') + CHKOUT_CARD ELSE
                   FORMAT(ATT_DATE, 'yyyy-mm-dd') + CHKOUT_CARD END));
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() IN (1403, 100) BEGIN
        SET @pchkinrea = '15';
             SET @pchkoutrea = '25';
             SET @pwkouttm = @sStart;
             SET @pwkintm = @sEnd;
    END
END CATCH
         END
         ELSE
         BEGIN
           BEGIN TRY
    --108482 20190125 RN班提前或延後加班，start_time都不會是0000，若start_time為0000則需跑else的SQL
             IF ((@sCLASS_CODE ='RN' OR @sNextCLASS_CODE='RN') AND @p_start_time<>'0000') BEGIN
               SELECT @pchkinrea = ISNULL(CHKIN_REA, 10), @pchkoutrea = ISNULL(CHKOUT_REA, 20), @pwkintm = FORMAT(ATT_DATE, 'yyyy-mm-dd') +
                     (SELECT CHKIN_WKTM
                        FROM HRA_CLASSDTL
                       WHERE CLASS_CODE = HRA_CADSIGN.CLASS_CODE
                         AND SHIFT_NO = HRA_CADSIGN.SHIFT_NO), @pwkouttm = FORMAT(ATT_DATE, 'yyyy-mm-dd') +
                     (SELECT CHKOUT_WKTM
                        FROM HRA_CLASSDTL
                       WHERE CLASS_CODE = HRA_CADSIGN.CLASS_CODE
                         AND SHIFT_NO = HRA_CADSIGN.SHIFT_NO)
    FROM HRA_CADSIGN
               WHERE EMP_NO = @p_emp_no
                 AND (@sEnd BETWEEN CASE WHEN CHKIN_CARD BETWEEN '0000' AND '0800' THEN
                      FORMAT(ATT_DATE, 'yyyy-mm-dd') ELSE
                      FORMAT(ATT_DATE - 1, 'yyyy-mm-dd') END + CHKIN_CARD AND
                     (FORMAT(ATT_DATE, 'yyyy-mm-dd') + CHKOUT_CARD))
                 AND (@sStart >= FORMAT(ATT_DATE - 1, 'yyyy-mm-dd') + CHKIN_CARD);
             END
             ELSE
             BEGIN 
              SELECT @pchkinrea = ISNULL(chkin_rea,10), @pchkoutrea = ISNULL(chkout_rea,20), @pwkintm = FORMAT(att_date, 'yyyy-mm-dd') + (select chkin_wktm from hra_classdtl where class_code = hra_cadsign.class_code and shift_no = hra_cadsign.shift_no), @pwkouttm = case when Night_Flag='Y' OR CLASS_CODE ='JB' then FORMAT(att_date+1, 'yyyy-mm-dd')
                                                else FORMAT(att_date, 'yyyy-mm-dd')
                                                end +
                     (select chkout_wktm from hra_classdtl where class_code = hra_cadsign.class_code and shift_no = hra_cadsign.shift_no)
    FROM hra_cadsign
               WHERE emp_no = @p_emp_no
                 AND (@sEnd BETWEEN FORMAT(att_date, 'yyyy-mm-dd') + chkin_card  AND  case when Night_Flag='Y' then (FORMAT(att_date+1, 'yyyy-mm-dd') + chkout_card)
                                                else FORMAT(att_date, 'yyyy-mm-dd') + chkout_card
                                                end)
                 AND (@sStart >= FORMAT(att_date, 'yyyy-mm-dd') + chkin_card );
             END
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() IN (1403, 100) BEGIN
        SET @pchkinrea = '15';
             SET @pchkoutrea = '25';
             SET @pwkouttm = @sStart;
             SET @pwkintm = @sEnd;
    END
END CATCH
           END

            --延後加班狀況
           IF (@sStart >= @pwkouttm AND @pchkoutrea < '25') BEGIN
              SET @RtnCode = 13;     -- 非因公務加班不可申請加班換補休
              GOTO Continue_ForEach1 ;
           END
           --提前加班狀況
           IF (@sEnd <= @pwkintm AND @pchkinrea < '15') BEGIN
              SET @RtnCode = 13;     -- 非因公務加班不可申請加班換補休
              GOTO Continue_ForEach1 ;
           END
         END

       ------加班不可申請積休-------
       --20180612 108978 IMP201806109 同日加班申請方式只能同一種申請方式」規則
       BEGIN TRY
    IF @p_start_date_tmp <> 'N/A' BEGIN
           SELECT @nCnt = count(EMP_NO)
    FROM HRP.HRA_OFFREC
            WHERE emp_no = @p_emp_no
              AND ORG_BY = @SOrganType
              AND ITEM_TYPE = 'A'
              AND STATUS NOT IN ('N') --排除不准
              AND (@p_start_date_tmp = FORMAT(START_DATE_TMP, 'yyyy-MM-dd') OR
                   (@p_end_date = FORMAT(END_DATE, 'yyyy-MM-dd') AND @p_start_date = FORMAT(start_date, 'yyyy-mm-dd')));
         END
         ELSE
         BEGIN
           SELECT @nCnt = count(EMP_NO)
    FROM HRP.HRA_OFFREC
            WHERE emp_no = @p_emp_no
              AND ORG_BY = @SOrganType
              AND ITEM_TYPE = 'A'
              AND STATUS NOT IN ('N') --排除不准
              AND @p_end_date = FORMAT(END_DATE, 'yyyy-MM-dd');
              --AND @p_start_date BETWEEN FORMAT(START_DATE, 'yyyy-MM-dd')AND FORMAT(END_DATE, 'yyyy-MM-dd') ;
         END
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() IN (1403, 100) BEGIN
        SET @nCnt = 0;
    END
END CATCH

       IF @nCnt > 0 BEGIN
          SET @RtnCode = 10;
          GOTO Continue_ForEach1 ;
       END


       -----------------------------
       --春節期間不檢核
      --20181130 108978 取消用狀態判斷是否為人資，因?護理長也有權限去使用進階加班換補休作業代人員申請
      --IF  @p_status <> 'P' THEN -- 人事系統輸入不檢查

       --IF DATEADD(DAY, 7, CONVERT(DATETIME2, @p_start_date))  < GETDATE() then 20151110 修改超過14日申請
       /*IF DATEADD(DAY, 14, CONVERT(DATETIME2, @p_start_date))  < GETDATE() BEGIN
         SET @RtnCode = 3;     -- 超過七日申請
          GOTO Continue_ForEach1 ;
       END*/
       --20210113 by108482 申請不卡14天申請期限,超過五天才申請違規記點
       --20210204 by108482 每月申請最多至隔月5號(5號當天可以申請)
       --20241007 by108482 每月申請最多至隔月幾號抓參數HRA89的設定
       BEGIN TRY
    SELECT @LimitDay = CODE_NAME
    FROM HR_CODEDTL
          WHERE CODE_TYPE = 'HRA89'
            AND CODE_NO = 'DAY';
END TRY
BEGIN CATCH
    -- WHEN OTHERS
    SET @LimitDay = '5';
END CATCH
       /*IF CAST(GETDATE() AS DATE) > CAST(DATEADD(MONTH, 1, CONVERT(DATETIME2, @p_start_date)) AS DATE) +9 BEGIN
         SET @RtnCode = 3;     
         GOTO Continue_ForEach1 ;
       END*/
       IF CAST(GETDATE() AS DATE) > 
          CONVERT(DATETIME2, FORMAT(DATEADD(MONTH, 1, CONVERT(DATETIME2, @p_start_date)), 'yyyy-MM')+'-'+@LimitDay) BEGIN
         SET @RtnCode = 3;     
         GOTO Continue_ForEach1 ;
       END

       --END IF;


       --20181130 108978 取消用狀態判斷是否為人資，因?護理長也有權限去使用進階加班換補休作業代人員申請 
       -- 檢核班表
       --IF  @p_status <> 'P' THEN -- 人事系統輸入不檢查


       --check 積休開放日
        IF @p_end_time ='0000' BEGIN
        SET @i_end_date = @p_start_date;
        END
        ELSE
        BEGIN
            SET @i_end_date = @p_end_date;
        END


      BEGIN TRY
    SELECT @iCnt = COUNT(ROWID)
    FROM HRP.HR_CODEDTL
           WHERE CODE_TYPE = 'HRA53'
             AND CODE_NAME = @p_start_date
             AND CODE_NAME = @i_end_date;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() IN (1403, 100) BEGIN
        SET @iCnt = 0;
    END
END CATCH


--查是否為上班時間內申請 108978 20190109
       IF @iCnt = 0 BEGIN
       --須修正機構別
         IF @p_start_date_tmp <> 'N/A' BEGIN
           SET @RtnCode = [ehrphra12_pkg].[checkClass](@p_emp_no, @p_start_date_tmp, @p_start_time, @p_end_date, @p_end_time, @SOrganType);
         END
         ELSE
         BEGIN
           SET @RtnCode = [ehrphra12_pkg].[checkClass](@p_emp_no, @p_start_date, @p_start_time, @p_end_date, @p_end_time, @SOrganType);
         END
       --20180913 108978 修正RtnCode IS NULL的問題
        IF (@RtnCode IS NULL ) BEGIN 
          SET @RtnCode = 8;
        END
       END
       --END IF;


       -- OnCall 判斷
       IF  @RtnCode = 0 AND @p_on_call ='Y' BEGIN
         SET @RtnCode = [ehrphra12_pkg].[checkOncall](@p_emp_no, @p_start_date, @p_start_time, @p_end_date, @p_start_date_tmp,@SOrganType);

         BEGIN TRY
    SELECT @iCnt2 = count(*)
    FROM GESD_DORMMST
               WHERE emp_no = @p_emp_no
                 AND USE_FLAG = 'Y';
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() IN (1403, 100) BEGIN
        SET @iCnt2 = 0;
    END
END CATCH

           IF @iCnt2 > 0 BEGIN
              SET @RtnCode = 4;     -- 住宿不可申請OnCall
              GOTO Continue_ForEach1 ;
           END


           -- IF @p_start_date_tmp <> 'N/A' AND @p_start_date_tmp <> @p_start_date 代表 為跨夜申請
           -- 故 ClassKin 要以 @p_start_date_tmp 為基準

/*           IF @p_start_date_tmp <> 'N/A' AND @p_start_date_tmp <> @p_start_date BEGIN
           SET @sClassKind = [ehrphrafunc_pkg].[f_getClassKind](@p_emp_no,CONVERT(DATETIME2, @p_start_date_tmp),@SOrganType);
           END
           ELSE
           BEGIN
           SET @sClassKind = [ehrphrafunc_pkg].[f_getClassKind](@p_emp_no,CONVERT(DATETIME2, @p_start_date),@SOrganType);
           END*/
           BEGIN TRY
    /*           IF @sClassKind ='N/A' BEGIN
                SET @RtnCode = 8;     -- 申請OnCall之積休日班別須為on call班
                GOTO Continue_ForEach1 ;
           END*/

           SELECT @iCnt2 = (CASE WHEN CHKIN_WKTM < CHKOUT_WKTM THEN ( CASE WHEN @p_start_time between CHKIN_WKTM AND CHKOUT_WKTM  THEN 1 ELSE 0 END )

	                      ELSE ( CASE WHEN  (@p_start_time between CHKIN_WKTM AND '2400') OR (@p_start_time between '0000' AND CHKOUT_WKTM )  THEN 1 ELSE 0 END )END
                   )
    FROM HRP.HRA_CLASSDTL
           WHERE SHIFT_NO='4'
             AND CLASS_CODE= @sClassKind;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() IN (1403, 100) BEGIN
        SET @iCnt2 = 0;
    END
END CATCH
            
            IF @iCnt2 = 0 BEGIN
              BEGIN TRY
    SELECT @iCnt2 = COUNT(*)
    FROM hr_codedtl
                 WHERE code_type = 'HRA79'
                   AND code_no = (SELECT dept_no
                                    FROM hre_empbas
                                   WHERE emp_no = @p_emp_no);
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() IN (1403, 100) BEGIN
        SET @iCnt2 = 0;
    END
END CATCH
            END

             IF @iCnt2 = 0 BEGIN
                SET @RtnCode = 5;     -- 申請OnCall之積休日班別須為on call班
                GOTO Continue_ForEach1 ;
             END

            ---如果有上班打卡就驗證
            -- IF @p_start_date_tmp <> 'N/A' AND @p_start_date_tmp <> @p_start_date 代表 為跨夜申請
            -- 以 @p_end_date 為基準
            BEGIN TRY
    IF @p_start_date_tmp <> 'N/A' BEGIN

            SELECT @iCnt2 = COUNT(*)
    FROM  HRA_CADSIGN
            Where HRA_CADSIGN.EMP_NO = @p_emp_no
              AND FORMAT(HRA_CADSIGN.ATT_DATE, 'yyyy-MM-dd') = @p_start_date_tmp;

            END
            ELSE
            BEGIN
            SELECT @iCnt2 = COUNT(*)
    FROM  HRA_CADSIGN
            Where HRA_CADSIGN.EMP_NO = @p_emp_no
              AND FORMAT(HRA_CADSIGN.ATT_DATE, 'yyyy-MM-dd') = @p_start_date;

            END
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() IN (1403, 100) BEGIN
        SET @iCnt2 = 0;
    END
END CATCH

            IF @iCnt2 >0 BEGIN

            BEGIN TRY
    --ON CALL VALIDATE
            -- IF @p_start_date_tmp <> 'N/A' AND @p_start_date_tmp <> @p_start_date 代表 為跨夜申請
            -- 故 ATT_DATE 要加 1 , 並以 @p_end_date 為基準

            IF @p_start_date_tmp <> 'N/A' AND @p_start_date_tmp <> @p_start_date BEGIN

            SELECT @iCnt2 = (case when (  CONVERT(DATETIME2, FORMAT(MAX(HRA_OTMSIGN.START_DATE), 'yyyy-MM-dd')+MAX(HRA_OTMSIGN.START_TIME)) - CONVERT(DATETIME2, FORMAT(MAX(HRA_CADSIGN.ATT_DATE), 'yyyy-MM-dd')+MAX(HRA_CADSIGN.CHKOUT_CARD)))*60*24 > 30 then 0 else 1 end )
    FROM HRA_OTMSIGN , HRA_CADSIGN
            Where HRA_CADSIGN.EMP_NO = HRA_OTMSIGN.EMP_NO
              AND FORMAT(ATT_DATE+1, 'yyyy-MM-dd') = FORMAT(START_DATE, 'yyyy-MM-dd')
              AND HRA_OTMSIGN.EMP_NO = @p_emp_no
              AND FORMAT(HRA_OTMSIGN.START_DATE, 'yyyy-MM-dd') = @p_end_date;

            END
            ELSE
            BEGIN

            SELECT @iCnt2 = (case when (  ISNULL(CONVERT(DATETIME2, FORMAT(MAX(HRA_OTMSIGN.START_DATE), 'yyyy-MM-dd')+MAX(HRA_OTMSIGN.START_TIME)) - CONVERT(DATETIME2, FORMAT(MAX(HRA_CADSIGN.ATT_DATE), 'yyyy-MM-dd')+MAX(HRA_CADSIGN.CHKOUT_CARD)),0))*60*24 > 30 then 0 else 1 end )
    FROM HRA_OTMSIGN , HRA_CADSIGN
            Where HRA_CADSIGN.EMP_NO = HRA_OTMSIGN.EMP_NO
              AND FORMAT(ATT_DATE, 'yyyy-MM-dd') = FORMAT(START_DATE, 'yyyy-MM-dd')
              AND HRA_OTMSIGN.EMP_NO = @p_emp_no
              AND FORMAT(HRA_OTMSIGN.START_DATE, 'yyyy-MM-dd') = @p_start_date;

            END
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() IN (1403, 100) BEGIN
        SET @iCnt2 = 0;
    END
END CATCH

            IF @iCnt2 = 0 BEGIN
                SET @RtnCode = 0;
                GOTO Continue_ForEach1 ;
                END
                ELSE
                BEGIN
                 SET @RtnCode = 6;     -- 申請OnCall失敗
                GOTO Continue_ForEach1 ;
            END
           END
          END

--20180508比照加班換加班費的邏輯判斷判別是否為上班時間 108978

      IF @iCnt = 0 BEGIN
        IF @p_start_date_tmp <> 'N/A' BEGIN
          SET @sClassKind = [ehrphrafunc_pkg].[f_getClassKind](@p_emp_no,CONVERT(DATETIME2, @p_start_date_tmp),@SOrganType);
          SET @sLastClassKind = [ehrphrafunc_pkg].[f_getClassKind](@p_emp_no,DATEADD(DAY, -1, CONVERT(DATETIME2, @p_start_date_tmp)),@SOrganType);
        END
        ELSE
        BEGIN
          SET @sClassKind = [ehrphrafunc_pkg].[f_getClassKind](@p_emp_no,CONVERT(DATETIME2, @p_start_date),@SOrganType);
          SET @sLastClassKind = [ehrphrafunc_pkg].[f_getClassKind](@p_emp_no,DATEADD(DAY, -1, CONVERT(DATETIME2, @p_start_date)),@SOrganType);
        END
      BEGIN TRY
    SELECT  @iCnt = COUNT(ROWID)
    FROM HRP.HRA_CLASSDTL
        Where CHKIN_WKTM  > CASE WHEN CHKOUT_WKTM ='0000' THEN '2400' ELSE CHKOUT_WKTM END
          AND SHIFT_NO <> '4'
          AND CLASS_CODE = @sLastClassKind;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() IN (1403, 100) BEGIN
        SET @iCnt = 0;
    END
END CATCH
      
--PRINT '@sLastClassKind'+@sLastClassKind;
--PRINT '@sClassKind'+@sClassKind;

      IF @sClassKind ='N/A' BEGIN
        SET @RtnCode = 7;
        GOTO Continue_ForEach1 ;
      --@sClassKind='ZZ'  20161219 新增班別 ZX,ZY
      --20180725 108978 增加ZQ
      END
ELSE IF @p_start_date_tmp <> 'N/A' AND @sClassKind IN ('ZZ','ZX','ZY','ZQ') BEGIN
        GOTO Continue_ForEach3 ;
      END
ELSE IF @sClassKind IN ('ZZ','ZX','ZY','ZQ') AND @iCnt=0 BEGIN
        GOTO Continue_ForEach3 ;
      END
      ELSE
      BEGIN

                  --SET @RtnCode = [ehrphrafunc_pkg].[checkClassTime2](@p_emp_no,@p_start_date,@p_start_time,@p_end_date,@p_end_time,@sClassKind,@sLastClassKind);
                  --by108482 20190109 因checkClassTime2判斷有問題，改用checkclass
                  --SET @RtnCode = [ehrphra12_pkg].[checkClass](@p_emp_no, @p_start_date, @p_start_time, @p_end_date, @p_end_time,@SOrganType);
                  --by108482 20190110 因checkclass判斷有問題，改用checkClassTime
                  SET @RtnCode = [ehrphrafunc_pkg].[checkClassTime](@p_emp_no,@p_start_date,@p_start_time,@p_end_date,@p_end_time,@sClassKind,@sLastClassKind);

                  IF @RtnCode = 1 BEGIN
                    SET @RtnCode = 8; --上班時間不可申請加班!!存檔失敗!
                    GOTO Continue_ForEach1 ;
                  END
ELSE IF (@RtnCode IS NULL ) BEGIN 
                    SET @RtnCode = 8;
                    GOTO Continue_ForEach1 ;
                  END
ELSE IF @RtnCode = 7 BEGIN --您尚未排班!!存檔失敗!
                    GOTO Continue_ForEach1 ;
                  END
ELSE IF @RtnCode = 8 BEGIN 
                    GOTO Continue_ForEach1 ;
                  END
                  
      END 

      END      
      Continue_ForEach3:
       BEGIN TRY
    -- 當日班表應出勤時數
  	     IF @p_start_date_tmp <> 'N/A' BEGIN
           SELECT @sWorkHrs = WORK_HRS
    FROM HRA_CLASSMST
            WHERE CLASS_CODE= [ehrphrafunc_pkg].[f_getClassKind](@p_emp_no,CONVERT(DATETIME2, @p_start_date_tmp),@SOrganType);
         END
         ELSE
         BEGIN
           SELECT @sWorkHrs = WORK_HRS
    FROM HRA_CLASSMST
            WHERE CLASS_CODE= [ehrphrafunc_pkg].[f_getClassKind](@p_emp_no,CONVERT(DATETIME2, @p_start_date),@SOrganType);
         END
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() IN (1403, 100) BEGIN
        SET @sWorkHrs = 0;
    END
END CATCH
  
  	   BEGIN TRY
    IF @p_start_date_tmp <> 'N/A' BEGIN
          SELECT @sTotAddHrs = SUM(OTM_HRS)
    FROM HRA_OTMSIGN
              WHERE FORMAT(ISNULL(Start_Date_Tmp,start_date), 'yyyy-mm-dd') = @p_start_date_tmp
              AND status<>'N'
              AND otm_flag = 'B'
              AND emp_no=@p_emp_no
              AND OTM_NO <> @p_otm_no;
         END
         ELSE
         BEGIN
  	      SELECT @sTotAddHrs = SUM(OTM_HRS)
    FROM HRA_OTMSIGN
              WHERE FORMAT(ISNULL(Start_Date_Tmp,start_date), 'yyyy-mm-dd')=  @p_start_date
              AND status<>'N'
              AND otm_flag = 'B'
              AND emp_no=@p_emp_no
              AND OTM_NO <> @p_otm_no;
         END
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() IN (1403, 100) BEGIN
        SET @sTotAddHrs = 0;
    END
END CATCH

      BEGIN TRY
    --20180725 108978 增加ZQ
  	      SELECT  @sTotMonAdd = ISNULL(sum(CASE WHEN s_class = 'ZZ' THEN (soneott+soneoss+soneuu) WHEN s_class = 'ZQ' THEN (soneott+soneoss+soneuu) WHEN s_class = 'ZY' THEN (soneott+soneoss+soneuu) ELSE sotm_Hrs END),0)
    FROM  (
          SELECT (select class_code
                    from hra_classsch_view
                   where emp_no = HRA_OFFREC.Emp_No
                     and att_date = FORMAT(ISNULL(Start_Date_Tmp,start_date), 'yyyy-mm-dd')) as s_class,                
                 otm_hrs,
                 soneo,
                 soneott,
                 soneoss,
                 sotm_hrs,
                 soneuu
            FROM HRA_OFFREC
            WHERE FORMAT(ISNULL(Start_Date_Tmp,start_date), 'yyyy-mm')=  SUBSTRING(@p_start_date ,1,7)
             AND status <> 'N'
             AND item_type = 'A'
             AND emp_no=@p_emp_no) tt;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() IN (1403, 100) BEGIN
        SET @sTotMonAdd = 0;
    END
END CATCH  
  
  	   IF @sTotAddHrs IS NULL BEGIN
  	     SET @sTotAddHrs = 0;
  	   END

	   BEGIN TRY
    SELECT @sMonClassAdd = (mon_getadd + mon_addhrs   + mon_spcotm -  mon_cutotm + mon_dutyhrs )
    FROM hra_attvac_view
         WHERE  hra_attvac_view.sch_ym = SUBSTRING(@p_start_date ,1,7)
		  AND hra_attvac_view.emp_no = @p_emp_no ;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() IN (1403, 100) BEGIN
        SET @sMonClassAdd = 0;
    END
END CATCH

  	   
        BEGIN TRY
    SELECT @sOtmsignHrs = ISNULL(SUM(OTM_HRS),0)
    FROM HRA_OTMSIGN
              WHERE FORMAT(ISNULL(Start_Date_Tmp,start_date), 'yyyy-mm')=  SUBSTRING(@p_start_date ,1,7)
              AND status<>'N'
              AND otm_flag = 'B'
              AND emp_no=@p_emp_no;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() IN (1403, 100) BEGIN
        SET @sOtmsignHrs = 0;
    END
END CATCH
--0301開始加班每月不能超過54HR 108978
       --IF ((@sOtmhrs+@sWorkHrs+@sTotAddHrs)> 12 OR (@sTotMonAdd+@sOtmsignHrs+@sMonClassAdd+@sOtmhrs>54)) THEN
       --20190301 by108482 因改四週排班，排除班表超時工時
       IF ((@sOtmhrs+@sWorkHrs+@sTotAddHrs)> 12 OR (@sTotMonAdd+@sOtmsignHrs+/*@sMonClassAdd+*/@sOtmhrs>54)) BEGIN
	        SET @RtnCode = 15;
       GOTO Continue_ForEach1 ;
       END
       
       IF (@RtnCode = 0 )  BEGIN 
       SET @RtnCode = [ehrphra12_pkg].[Check3MonthOtmhrs](@p_emp_no,@p_start_date, @p_otm_hrs,@SOrganType);
       END
       Continue_ForEach1:
END
GO
