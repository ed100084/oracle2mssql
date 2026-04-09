CREATE OR ALTER PROCEDURE [ehrphra12_pkg].[hraC030]
(    @p_item_type NVARCHAR(MAX),
    @p_emp_no NVARCHAR(MAX),
    @p_start_date NVARCHAR(MAX),
    @p_start_time NVARCHAR(MAX),
    @p_end_date NVARCHAR(MAX),
    @p_end_time NVARCHAR(MAX),
    @p_on_call NVARCHAR(MAX),
    @p_posted_startdate NVARCHAR(MAX),
    @p_posted_starttime NVARCHAR(MAX),
    @p_posted_status NVARCHAR(MAX),
    @p_start_date_tmp NVARCHAR(MAX),
    @p_otm_hrs NVARCHAR(MAX),
    @OrganType_IN NVARCHAR(MAX),
    @RtnCode DECIMAL(38,10) OUTPUT
)
AS
DECLARE @sItemType NVARCHAR(MAX) /*hra_offrec.item_type%TYPE*/ = @p_item_type;
DECLARE @sEmpNo NVARCHAR(MAX) /*hra_offrec.emp_no%TYPE*/ = @p_emp_no;
DECLARE @sStart NVARCHAR(20) = @p_start_date + @p_start_time;
DECLARE @sEnd NVARCHAR(20) = @p_end_date + @p_end_time;
DECLARE @sOnCall NVARCHAR(1) = @p_on_call;
DECLARE @sOffrest DECIMAL(5,1);
DECLARE @SOrganType NVARCHAR(10) = @OrganType_IN;
DECLARE @sOtmhrs DECIMAL(5,1) = CAST(@p_otm_hrs AS DECIMAL(38,10));
DECLARE @sClassKind NVARCHAR(3);
DECLARE @sLastClassKind NVARCHAR(3);
DECLARE @sNextClassKind NVARCHAR(3);
DECLARE @iCnt INT;
DECLARE @iCnt2 INT;
DECLARE @i_end_date NVARCHAR(10);
DECLARE @iCheckCard NVARCHAR(1);
DECLARE @iposlevel NVARCHAR(1);
DECLARE @iChkinWktm NVARCHAR(4);
DECLARE @iChkoutWktm NVARCHAR(4);
DECLARE @LimitDay NVARCHAR(2);
DECLARE @sOldSumary DECIMAL(5,1);
DECLARE @pchkinrea NVARCHAR(2);
DECLARE @pchkoutrea NVARCHAR(2);
DECLARE @pwkintm NVARCHAR(20);
DECLARE @pwkouttm NVARCHAR(20);
DECLARE @sWorkHrs DECIMAL(5,1);
DECLARE @sTotAddHrs DECIMAL(5,1);
DECLARE @sTotMonAdd DECIMAL(5,1);
DECLARE @sOtmsignHrs DECIMAL(5,1);
DECLARE @sMonClassAdd DECIMAL(5,1);
BEGIN
      SET @sOldSumary = 0;
      SET @RtnCode = 0;

      SET @sWorkHrs = 0;
	    SET @sTotAddHrs = 0;
	    SET @sTotMonAdd = 0;
      SET @sOtmsignHrs = 0;
	    SET @sMonClassAdd = 0;
      SET @iCheckCard = 'N';

       --IF GETDATE()  > DATEADD(DAY, 7, CONVERT(DATETIME2, @p_start_date)) THEN 20151110 修改 14天 可申請
      /*IF GETDATE()  > DATEADD(DAY, 14, CONVERT(DATETIME2, @p_start_date)) BEGIN
        SET @RtnCode = 11;
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
        SET @RtnCode = 11;
        GOTO Continue_ForEach1 ;
      END*/
      IF CAST(GETDATE() AS DATE) > 
         CONVERT(DATETIME2, FORMAT(DATEADD(MONTH, 1, CONVERT(DATETIME2, @p_start_date)), 'yyyy-MM')+'-'+@LimitDay) BEGIN
        SET @RtnCode = 11;
        GOTO Continue_ForEach1 ;
      END

      --IF 借休該日班表時數為0時,不可存檔
      IF @sItemType ='O' BEGIN
        SET @sClassKind = [ehrphrafunc_pkg].[f_getClassKind](@p_emp_no,CONVERT(DATETIME2, @p_start_date),@SOrganType);
      BEGIN
       SELECT @iCnt = COUNT(*)
    FROM HRP.HRA_CLASSMST
        WHERE CLASS_CODE = @sClassKind
          AND WORK_HRS = 0;
      END

      IF @iCnt > 0 BEGIN
        SET @RtnCode = 12;
        GOTO Continue_ForEach1 ;
      END
      END

      IF @sItemType ='O' AND @p_start_date_tmp <> @p_start_date  BEGIN
        SET @sStart = FORMAT(DATEADD(DAY, 1, CONVERT(DATETIME2, @p_start_date)), 'yyyy-MM-dd') +@p_start_time;
      END

      ------------------------- 積休單 -------------------------
      --(檢核在資料庫中除''不准''以外的積休單申請時間是否重疊)
      IF @sItemType = 'A' BEGIN
       
      BEGIN TRY
    SELECT @iposlevel = pos_level
    FROM HRE_POSMST
         WHERE pos_no = (SELECT pos_no FROM hre_empbas WHERE emp_no = @sEmpNo);
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

      BEGIN TRY
    SELECT @iCnt = COUNT(ROWID)
    FROM hra_offrec
         WHERE emp_no = @sEmpNo
           AND item_type = @sItemType
           AND (((@sStart >=  FORMAT(start_date, 'yyyy-MM-dd') + start_time AND @sStart < FORMAT(end_date, 'yyyy-MM-dd')+end_time)
                OR (@sEnd > FORMAT(start_date, 'yyyy-MM-dd') + start_time AND @sEnd <= FORMAT(end_date, 'yyyy-MM-dd')+end_time ))
      		      OR (FORMAT(start_date, 'yyyy-MM-dd') + start_time >= @sStart AND FORMAT(end_date, 'yyyy-MM-dd') +end_time < @sStart)
                OR (FORMAT(start_date, 'yyyy-MM-dd') + start_time > @sEnd AND FORMAT(end_date, 'yyyy-MM-dd') +end_time <= @sEnd)
			          OR (FORMAT(start_date, 'yyyy-MM-dd') + start_time >= @sStart AND FORMAT(end_date, 'yyyy-MM-dd')+end_time <= @sEnd))
                --20200410 by108482 檢核更精確
                --OR (FORMAT(start_date, 'yyyy-MM-dd') + start_time = @sStart AND FORMAT(end_date, 'yyyy-MM-dd')+end_time = @sEnd))
           AND status in ('U','1','2','Y') AND ORG_BY = @SOrganType;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() IN (1403, 100) BEGIN
        SET @iCnt = 0;
    END
END CATCH

      IF @iCnt > 0 BEGIN
        SET @RtnCode = 1;
      END
      
      --判斷是否為更改原資料
      IF @iCnt > 0 AND @p_posted_startdate<>'N/A' AND  @p_posted_starttime<>'N/A' AND @p_posted_status<>'N/A' BEGIN

        BEGIN TRY
    SELECT @iCnt = COUNT(*)
    FROM hra_offrec
           WHERE emp_no    = @sEmpNo
             AND item_type = @sItemType
             AND start_date = CONVERT(DATETIME2, @p_posted_startdate)
             AND start_time = @p_posted_starttime
             AND status = @p_posted_status
             AND org_by = @SOrganType;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() IN (1403, 100) BEGIN
        SET @iCnt = 0;
    END
END CATCH

        IF @iCnt >= 1 BEGIN
          SET @RtnCode = 0;
        END
      END
      
      END
      ELSE
      BEGIN --@sItemType = 'O'
        BEGIN TRY
    SELECT @iCnt = COUNT(ROWID)
    FROM hra_offrec
           WHERE emp_no = @sEmpNo
             AND item_type = @sItemType
             AND (start_date = start_date_tmp AND
		             (
                 (((@sStart >=  FORMAT(start_date, 'yyyy-MM-dd') +start_time and @sStart <  FORMAT(end_date, 'yyyy-MM-dd')+end_time)
                 OR (@sEnd  >  FORMAT(start_date, 'yyyy-MM-dd') +start_time and @sEnd <=  FORMAT(end_date, 'yyyy-MM-dd')+end_time ))
      		       OR (FORMAT(start_date, 'yyyy-MM-dd') +start_time >= @sStart And  FORMAT(end_date, 'yyyy-MM-dd') +end_time < @sStart)
                 OR (FORMAT(start_date, 'yyyy-MM-dd') +start_time > @sEnd And  FORMAT(end_date, 'yyyy-MM-dd') +end_time <= @sEnd)
			           OR (FORMAT(start_date, 'yyyy-MM-dd') +start_time = @sStart And  FORMAT(end_date, 'yyyy-MM-dd')+end_time = @sEnd))
			           ) OR
			           (start_date <> start_date_tmp AND
		              (((@sStart >=  FORMAT(start_date_tmp, 'yyyy-MM-dd') +start_time and @sStart <  FORMAT(end_date, 'yyyy-MM-dd')+end_time)
                  OR (@sEnd  >  FORMAT(start_date_tmp, 'yyyy-MM-dd') +start_time and @sEnd <=  FORMAT(end_date, 'yyyy-MM-dd')+end_time ))
      		        OR (FORMAT(start_date_tmp, 'yyyy-MM-dd') +start_time >= @sStart And  FORMAT(end_date, 'yyyy-MM-dd') +end_time < @sStart)
                  OR (FORMAT(start_date_tmp, 'yyyy-MM-dd') +start_time > @sEnd And  FORMAT(end_date, 'yyyy-MM-dd') +end_time <= @sEnd)
			            OR (FORMAT(start_date_tmp, 'yyyy-MM-dd') +start_time = @sStart And  FORMAT(end_date, 'yyyy-MM-dd')+end_time = @sEnd))
			           ))
             AND status in ('U','1','2','Y')
             AND ORG_BY = @SOrganType;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() IN (1403, 100) BEGIN
        SET @iCnt = 0;
    END
END CATCH

        IF @iCnt > 0 BEGIN
          SET @RtnCode = 1;
        END
        
        --判斷是否為更改原資料
        IF @iCnt > 0 AND @p_posted_startdate<>'N/A' AND  @p_posted_starttime<>'N/A' AND @p_posted_status<>'N/A' BEGIN

          BEGIN TRY
    SELECT @iCnt = COUNT(*)
    FROM hra_offrec
             WHERE emp_no    = @sEmpNo
               AND item_type = @sItemType
               AND start_date_tmp = CONVERT(DATETIME2, @p_posted_startdate)
               AND start_time = @p_posted_starttime
               AND status = @p_posted_status
               AND org_by = @SOrganType;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() IN (1403, 100) BEGIN
        SET @iCnt = 0;
    END
END CATCH

          IF @iCnt >= 1 BEGIN
            SET @RtnCode = 0;
          END
        END

      END

      IF @RtnCode = 1 BEGIN
        GOTO Continue_ForEach1 ;
      END
      
      ---借休不可申請 OnCall---
      IF @sItemType = 'O' AND @sOnCall ='Y' BEGIN
        SET @RtnCode = 7;
        GOTO Continue_ForEach1 ;
      END

      ---借休不可申請 超過 24 小時 (工讀生,兼職不必)---
      IF @sItemType = 'O' AND  @p_emp_no NOT LIKE 'P%' AND @p_emp_no NOT LIKE 'S%' BEGIN
        BEGIN TRY
    SELECT @sOffrest = (mon_getadd + mon_addhrs + mon_otmhrs - mon_offhrs + mon_spcotm - mon_cutotm + mon_dutyhrs) +
                 (SELECT ISNULL(SUM(ATT_VALUE),0) FROM HRA_ATTDTL1 Where EMP_NO = @sEmpNo AND ATT_CODE = '204' AND DISABLED = 'N' AND TRN_YM < FORMAT(GETDATE(), 'yyyy-MM'))
    FROM hra_attvac_view
	         WHERE (hra_attvac_view.emp_no = @sEmpNo)
             AND (hra_attvac_view.sch_ym = FORMAT(GETDATE(), 'yyyy-MM'));
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() IN (1403, 100) BEGIN
        SET @iCnt = 0;
    END
END CATCH
        
        SET @sOffrest = @sOffrest;

        -- 需包含此次申請的時數 by szuhao 2007.7.16
        --2010-11-24 modify by weichun 因要加上結算後再計算上限 for 需求 2011-05-19關閉
        --select ISNULL(case when (select hrs_alloffym from hrs_ym where 1=1 /* TODO: converted ROWNUM=1 → use TOP 1 */) = '2010-09' then
        -- (select clos_hrs from hra_offclos where clos_ym = '2010-9' and emp_no = @sEmpNo) else 0 end,0)
        --  into @sOldSumary
        --  from dual;
       
        -- IF  (@sOffrest - @sOtmhrs) + @sOldSumary < -24 THEN
        --2010-02-01 修改調成績核時數由24改為超過9999時不可借休(即不稽核)
        --IF  (@sOffrest - @sOtmhrs) + @sOldSumary < -9999 THEN
        --2014-04-28 修改為無稽休不能借休
        IF  (@sOffrest - @sOtmhrs) + @sOldSumary < 0 BEGIN 
          SET @RtnCode = 9;
          GOTO Continue_ForEach1 ;
        END
      END

      --判斷是否為借休 或 OnCall
      --IF   @p_item_type ='O' OR ( @p_item_type ='A' AND @p_on_call='Y') THEN
      --20190312 by108482 加班費需KEY應出勤日,20190823 by108482 sStart依照人員填入的時間
      --IF @p_item_type ='O' OR ( @p_item_type ='A' AND @p_start_date_tmp <> 'N/A') THEN
      IF @p_item_type ='O' OR ( @p_item_type ='A' AND @p_on_call='Y') BEGIN
        --SET @sStart = @p_start_date_tmp + @p_start_time;
        SET @sStart = @p_start_date + @p_start_time;
      END
      
      SET @RtnCode = 0;

      ------------------------- 積休單 -------------------------
      IF @sItemType = 'A' BEGIN
        ---積休不可申請加班----多機構沒差一並判斷
        --20180612 108978 IMP201806109 同日加班申請方式只能同一種申請方式」規則
        BEGIN TRY
    IF @p_start_date_tmp <> 'N/A' BEGIN
            SELECT @iCnt = COUNT(ROWID)
    FROM HRP.HRA_OTMSIGN
             WHERE emp_no = @sEmpNo
               AND otm_no LIKE 'OTM%'
               AND STATUS NOT IN ('N') --排除不准
               AND (@p_start_date_tmp = FORMAT(Start_Date_Tmp, 'yyyy-mm-dd') OR 
                    (@p_end_date = FORMAT(end_date, 'yyyy-mm-dd') AND @p_start_date = FORMAT(start_date, 'yyyy-mm-dd')));
          END
          ELSE
          BEGIN
            SELECT @iCnt = COUNT(ROWID)
    FROM HRP.HRA_OTMSIGN
             WHERE emp_no = @sEmpNo
               AND otm_no LIKE 'OTM%'
               AND STATUS NOT IN ('N') --排除不准
               AND @p_end_date = FORMAT(end_date, 'yyyy-mm-dd');
               --AND (@p_start_date + @p_start_time) BETWEEN (FORMAT(start_date, 'yyyy-mm-dd')+ start_time) AND  (FORMAT(END_date, 'yyyy-mm-dd')+end_time);
          END
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() IN (1403, 100) BEGIN
        SET @iCnt = 0;
    END
END CATCH

        IF @iCnt > 0 BEGIN
          SET @RtnCode = 10;
          GOTO Continue_ForEach1 ;
        END
 
        ---積休申請不可請產假-多機構沒差一並判斷
        BEGIN TRY
    SELECT @iCnt = COUNT(ROWID)
    FROM HRP.HRA_EVCREC
           WHERE emp_no = @sEmpNo
             AND (@p_start_date + @p_start_time) BETWEEN (FORMAT(start_date, 'yyyy-mm-dd')+ start_time) AND (FORMAT(END_date, 'yyyy-mm-dd')+end_time)
             AND STATUS IN ('U','Y')
             AND VAC_TYPE = 'I';
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() IN (1403, 100) BEGIN
        SET @iCnt = 0;
    END
END CATCH

        IF @iCnt > 0 BEGIN
          SET @RtnCode = 14;
          GOTO Continue_ForEach1 ;
        END

        --103.09 by sphinx 當日應出勤班時數+當日加班單時數 +該筆積休單時數不可大於12小時
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

	      --當日積休單時數
        BEGIN TRY
    IF @p_start_date_tmp <> 'N/A' BEGIN
          SELECT @sTotAddHrs = SUM(SOTM_HRS)
    FROM HRA_OFFREC
           WHERE FORMAT(ISNULL(Start_Date_Tmp,Start_Date), 'yyyy-mm-dd') = @p_start_date_tmp
             AND status<>'N'
             AND item_type='A'
             AND emp_no=@p_emp_no;
          END
          ELSE
          BEGIN
	        SELECT @sTotAddHrs = SUM(SOTM_HRS)
    FROM HRA_OFFREC
           WHERE FORMAT(ISNULL(Start_Date_Tmp,start_date), 'yyyy-mm-dd') = @p_start_date
             AND status<>'N'
             AND item_type='A'
             AND emp_no=@p_emp_no;
          END
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() IN (1403, 100) BEGIN
        SET @sTotAddHrs = 0;
    END
END CATCH

	      IF @sTotAddHrs IS NULL BEGIN
	        SET @sTotAddHrs = 0;
	      END
     
        -- 20170427 調整 一例一休 休息日:<4 列入4 ,>4 <8 列入8,>8  列入12.  國定假日:>8之後列入
        --20180725 108978 增加ZQ
        BEGIN TRY
    SELECT @sTotMonAdd = ISNULL(sum(CASE WHEN s_class = 'ZZ' THEN (soneott+soneoss+soneuu) WHEN s_class = 'ZQ' THEN (soneott+soneoss+soneuu) WHEN s_class = 'ZY' THEN (soneott+soneoss+soneuu) ELSE sotm_Hrs END),0)
    FROM (SELECT (SELECT class_code
                            FROM hra_classsch_view
                           WHERE emp_no = HRA_OFFREC.Emp_No
                             AND att_date = FORMAT(ISNULL(Start_Date_Tmp,start_date), 'yyyy-mm-dd')) as s_class,                
                         otm_hrs,
                         soneo,
                         soneott,
                         soneoss,
                         sotm_hrs,
                         soneuu
                    FROM HRA_OFFREC
                   WHERE FORMAT(ISNULL(Start_Date_Tmp,start_date), 'yyyy-mm') = SUBSTRING(@p_start_date, 1, 7)
                     AND status <> 'N'
                     AND item_type = 'A'
                     AND emp_no=@p_emp_no) tt;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() IN (1403, 100) BEGIN
        SET @sTotMonAdd = 0;
    END
END CATCH  
           
  	    /* 
        BEGIN
    	    SELECT @sTotMonAdd = SUM(SOTM_HRS)
    FROM HRA_OFFREC
          WHERE FORMAT(start_date, 'yyyy-mm')=  SUBSTRING(@p_start_date ,1,7)
            AND status<>'N'
            AND item_type='A'
            AND emp_no=@p_emp_no;
    		EXCEPTION WHEN NO_DATA_FOUND THEN
          SET @sTotMonAdd = 0;
    	  END
        */

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

	      BEGIN TRY
    SELECT @sMonClassAdd = (mon_getadd + mon_addhrs   + mon_spcotm -  mon_cutotm + mon_dutyhrs )
    FROM hra_attvac_view
           WHERE hra_attvac_view.sch_ym = SUBSTRING(@p_start_date ,1,7)
		         AND hra_attvac_view.emp_no = @p_emp_no ;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() IN (1403, 100) BEGIN
        SET @sMonClassAdd = 0;
    END
END CATCH
     
        --0301開始加班每月不能超過54HR 108978
        IF GETDATE()  >= CONVERT(DATETIME2, '20180315') BEGIN
          --IF  ((@sOtmhrs+@sWorkHrs+@sTotAddHrs)> 12) OR (@sOtmsignHrs+@sTotMonAdd+@sMonClassAdd+@sOtmhrs>54) THEN
          --20190301 by108482 因改四週排班，排除班表超時工時
          IF ((@sOtmhrs+@sWorkHrs+@sTotAddHrs)> 12) OR (@sOtmsignHrs+@sTotMonAdd+/*@sMonClassAdd+*/@sOtmhrs>54) BEGIN
	          SET @RtnCode = 15;
            GOTO Continue_ForEach1 ;
          END
        END
        ELSE
        BEGIN
          IF ((@sOtmhrs+@sWorkHrs+@sTotAddHrs)> 12) OR (@sTotMonAdd+@sMonClassAdd+@sOtmhrs>46) BEGIN
	          SET @RtnCode = 15;
            GOTO Continue_ForEach1 ;
          END
        END

        IF (@RtnCode = 0 ) BEGIN 
          SET @RtnCode = [ehrphra12_pkg].[Check3MonthOtmhrs](@p_emp_no,@p_start_date, @p_otm_hrs,@SOrganType);
          IF (@RtnCode = 16 ) BEGIN
            SET @RtnCode = 16;
            GOTO Continue_ForEach1 ;
          END 
        END

        ---判別是否為上班時間積休
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

        IF @iCnt = 0 BEGIN
          IF @p_start_date_tmp <> 'N/A' BEGIN
            SET @sClassKind = [ehrphrafunc_pkg].[f_getClassKind](@p_emp_no,CONVERT(DATETIME2, @p_start_date_tmp),@SOrganType);
            SET @sLastClassKind = [ehrphrafunc_pkg].[f_getClassKind](@p_emp_no,DATEADD(DAY, -1, CONVERT(DATETIME2, @p_start_date_tmp)),@SOrganType);
          END
          ELSE
          BEGIN
            SET @sClassKind = [ehrphrafunc_pkg].[f_getClassKind](@p_emp_no,CONVERT(DATETIME2, @p_start_date),@SOrganType);
            SET @sLastClassKind = [ehrphrafunc_pkg].[f_getClassKind](@p_emp_no,DATEADD(DAY, -1, CONVERT(DATETIME2, @p_start_date)),@SOrganType);
            SET @sNextClassKind = [ehrphrafunc_pkg].[f_getClassKind](@p_emp_no,DATEADD(DAY, 1, CONVERT(DATETIME2, @p_start_date)),@SOrganType);
            
            --RN提前上班 20181205 108978
            IF ( @p_start_time >='2000' AND @p_end_time = '0000' ) BEGIN
              IF (@sNextClassKind = [ehrphrafunc_pkg].[f_getClassKind](@p_emp_no,CONVERT(DATETIME2, @p_end_date),@SOrganType)) BEGIN
                SET @sClassKind = [ehrphrafunc_pkg].[f_getClassKind](@p_emp_no,CONVERT(DATETIME2, @p_end_date),@SOrganType);  
              END
            END
          END

          BEGIN TRY
    SELECT @iCnt = COUNT(ROWID)
    FROM HRP.HRA_CLASSDTL
             WHERE CHKIN_WKTM > CASE WHEN CHKOUT_WKTM ='0000' THEN '2400' ELSE CHKOUT_WKTM END
               AND SHIFT_NO <> '4'
               AND CLASS_CODE = @sLastClassKind;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() IN (1403, 100) BEGIN
        SET @iCnt = 0;
    END
END CATCH
      
          IF @sClassKind ='N/A' BEGIN
            SET @RtnCode = 8;
            GOTO Continue_ForEach1 ;
          --@sClassKind='ZZ'  20161219 新增班別 ZX,ZY
          --20180725 108978 增加ZQ
          END
ELSE IF @p_start_date_tmp <> 'N/A' AND @sClassKind IN ('ZZ','ZX','ZY','ZQ') BEGIN
            GOTO Continue_ForEach2 ;
          END
ELSE IF @sClassKind IN ('ZZ','ZX','ZY','ZQ') AND @iCnt=0 BEGIN
            GOTO Continue_ForEach2 ;
          END
          ELSE
          BEGIN
          --SET @RtnCode = [ehrphrafunc_pkg].[checkClassTime2](@p_emp_no,@p_start_date,@p_start_time,@p_end_date,@p_end_time,@sClassKind,@sLastClassKind);
          --by108482 20190109 因checkClassTime2判斷有問題，改用checkclass
          --SET @RtnCode = [ehrphra12_pkg].[checkClass](@p_emp_no, @p_start_date, @p_start_time, @p_end_date, @p_end_time,@SOrganType);
          --by108482 20190110 因checkclass判斷有問題，改用checkClassTime
            SET @RtnCode = [ehrphrafunc_pkg].[checkClassTime](@p_emp_no,@p_start_date,@p_start_time,@p_end_date,@p_end_time,@sClassKind,@sLastClassKind);

            IF @RtnCode = 1 BEGIN
              SET @RtnCode = 3; --申請時間不符合班表!!存檔失敗!
              GOTO Continue_ForEach1 ;
            END
ELSE IF (@RtnCode IS NULL ) BEGIN 
              SET @RtnCode = 3;
              GOTO Continue_ForEach1 ;
            END
ELSE IF @RtnCode = 7 BEGIN
              SET @RtnCode = 8; --您尚未排班!!存檔失敗!
              GOTO Continue_ForEach1 ;
            END
ELSE IF @RtnCode = 8 BEGIN 
              SET @RtnCode = 3;
              GOTO Continue_ForEach1 ;
            END
          END
        END
        Continue_ForEach2:
        ------------------------- 加班簽到 -------------------------
        BEGIN TRY
    SELECT @iCnt = COUNT(*)
    FROM hra_otmsign
           WHERE emp_no = @sEmpNo
             AND ((@sStart BETWEEN FORMAT(start_date, 'yyyy-MM-dd') + start_time
                              AND FORMAT(end_date, 'yyyy-MM-dd') + end_time)
             AND  (@sEnd   BETWEEN FORMAT(start_date, 'yyyy-MM-dd') + start_time
                              AND FORMAT(end_date, 'yyyy-MM-dd') + end_time))
             AND SUBSTRING(otm_no, 1, 3) = 'OTS';
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() IN (1403, 100) BEGIN
        SET @iCnt = 0;
    END
END CATCH

        IF @iCnt = 0 BEGIN
          SET @RtnCode = 2;     -- 無簽到時間
        END
        ELSE
        BEGIN 
          SET @iCheckCard = 'Y'; --@iCnt<>0,有加班簽到 20181219 by108482
        END

        ------------------------- 加班簽到 -------------------------

        ------------------------- 一般簽到 -------------------------
        IF @RtnCode = 2 BEGIN
        -------------Check OnCall-----------
          SET @RtnCode = 0;
        IF @p_start_date_tmp <> 'N/A' BEGIN
          SET @sClassKind = [ehrphrafunc_pkg].[f_getClassKind](@p_emp_no,CONVERT(DATETIME2, @p_start_date_tmp),@SOrganType);
          BEGIN TRY
    SELECT @iChkinWktm = CHKIN_WKTM, @iChkoutWktm = CHKOUT_WKTM
    FROM HRA_CLASSDTL
             WHERE CLASS_CODE = @sClassKind
               AND SHIFT_NO = '1';
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() IN (1403, 100) BEGIN
        SET @iChkinWktm = 0;
            SET @iChkoutWktm = 0;
    END
END CATCH
          BEGIN TRY
    SELECT @iCnt = COUNT(*)
    FROM hra_cadsign
             WHERE emp_no = @p_emp_no
               AND FORMAT(att_date, 'yyyy-mm-dd') = @p_start_date_tmp
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
                    FORMAT(ATT_DATE, 'yyyy-mm-dd') + CHKOUT_CARD END)) ;
            --20191014 by108482 原寫法僅檢核當天是否有打卡記錄，未檢核申請的時間起迄是否符合打卡的時間
            /*SELECT COUNT(*)
              INTO @iCnt
              FROM hra_cadsign
             WHERE emp_no = @p_emp_no
               AND FORMAT(att_date, 'yyyy-mm-dd') = @p_start_date_tmp;*/
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() IN (1403, 100) BEGIN
        SET @iCnt = 0;
    END
END CATCH
          --若查無記錄再次檢核
          --IF @iCnt = 0 AND @p_start_time > @p_end_time THEN by108482 20210820 不卡時間條件
          IF @iCnt = 0 BEGIN
            SELECT @iCnt = COUNT(*)
    FROM hra_cadsign
             WHERE emp_no = @p_emp_no
               AND FORMAT(att_date, 'yyyy-mm-dd') = @p_start_date_tmp
               AND CHKIN_CARD > CHKOUT_CARD --20230922增 by108482 嚴謹檢核
               AND @sStart >= FORMAT(ATT_DATE, 'yyyy-mm-dd') + CHKIN_CARD
               AND @sEnd BETWEEN FORMAT(ATT_DATE, 'yyyy-mm-dd') + CHKIN_CARD
                            AND FORMAT(ATT_DATE + 1, 'yyyy-mm-dd') + CHKOUT_CARD;
          END
        END
        ELSE
        BEGIN
        --108154 20181207 RN班申請加班費
          SET @sClassKind = [ehrphrafunc_pkg].[f_getClassKind](@p_emp_no,CONVERT(DATETIME2, @p_start_date),@SOrganType);
          SET @sNextClassKind = [ehrphrafunc_pkg].[f_getClassKind](@p_emp_no,DATEADD(DAY, 1, CONVERT(DATETIME2, @p_start_date)),@SOrganType);
        --108482 20190121 RN班提前或延後加班，start_time都不會是0000，若start_time為0000則需跑else的SQL
          IF ((@sClassKind ='RN' OR @sNextClassKind='RN') AND @p_start_time <> '0000') BEGIN
            BEGIN TRY
    SELECT @iCnt = COUNT(*)
    FROM hra_cadsign
               WHERE emp_no = @p_emp_no
                 AND (@sEnd BETWEEN FORMAT(att_date-1, 'yyyy-mm-dd') + chkin_card AND (FORMAT(att_date, 'yyyy-mm-dd') + chkout_card))                                           
                 AND (@sStart >= FORMAT(att_date-1, 'yyyy-mm-dd') + chkin_card );
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() IN (1403, 100) BEGIN
        SET @iCnt = 0;
    END
END CATCH
          END
          ELSE
          BEGIN
            BEGIN TRY
    SELECT @iCnt = COUNT(*)
    FROM hra_cadsign
               WHERE emp_no = @p_emp_no
                 AND (@sEnd BETWEEN FORMAT(att_date, 'yyyy-mm-dd') + chkin_card  AND CASE WHEN Night_Flag='Y' THEN (FORMAT(att_date+1, 'yyyy-mm-dd') + chkout_card)
                                                ELSE FORMAT(att_date, 'yyyy-mm-dd') + chkout_card
                                                END)
                 AND (@sStart >= FORMAT(att_date, 'yyyy-mm-dd') + chkin_card );
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() IN (1403, 100) BEGIN
        SET @iCnt = 0;
    END
END CATCH
          END
        END
          IF @iCnt = 0 BEGIN
            SET @RtnCode = 2;     -- 無簽到時間
            GOTO Continue_ForEach1 ;
          END
        END

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
               AND FORMAT(att_date, 'yyyy-mm-dd') = @p_start_date_tmp
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
                    FORMAT(ATT_DATE, 'yyyy-mm-dd') + CHKOUT_CARD END)) ;
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
    --108482 20190125 與檢核是否有打卡記錄的判斷統一
            --IF (@sClassKind = 'RN') THEN
            IF ((@sClassKind ='RN' OR @sNextClassKind='RN') AND @p_start_time <> '0000') BEGIN
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
                 AND (@sEnd BETWEEN FORMAT(ATT_DATE - 1, 'yyyy-mm-dd') + CHKIN_CARD AND
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
            SET @RtnCode = 13;     -- 非因公務加班不可申請積休
            GOTO Continue_ForEach1 ;
          END
          --提前加班狀況
          IF (@sEnd <= @pwkintm AND @pchkinrea < '15') BEGIN
            SET @RtnCode = 13;     -- 非因公務加班不可申請積休
            GOTO Continue_ForEach1 ;
          END
        END
        

        -------------Check OnCall-----------
        IF  @RtnCode = 0 AND @sOnCall ='Y' BEGIN
          SET @RtnCode = [ehrphra12_pkg].[checkOncall](@p_emp_no, @p_start_date, @p_start_time, @p_end_date, @p_start_date_tmp,@SOrganType);

          BEGIN TRY
    SELECT @iCnt2 = COUNT(*)
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

          IF @p_start_date_tmp <> 'N/A' AND @p_start_date_tmp <> @p_start_date BEGIN
            SET @sClassKind = [ehrphrafunc_pkg].[f_getClassKind](@p_emp_no,CONVERT(DATETIME2, @p_start_date_tmp),@SOrganType);
          END
          ELSE
          BEGIN
            SET @sClassKind = [ehrphrafunc_pkg].[f_getClassKind](@p_emp_no,CONVERT(DATETIME2, @p_start_date),@SOrganType);
          END
          BEGIN TRY
    PRINT @sClassKind;
            IF @sClassKind ='N/A' BEGIN
              SET @RtnCode = 8;     -- 申請OnCall之積休日班別須為on call班
              GOTO Continue_ForEach1 ;
            END

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
                                 WHERE emp_no = @sEmpNo);
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
    IF @p_start_date_tmp <> 'N/A' AND @p_start_date_tmp <> @p_start_date BEGIN
              SELECT @iCnt2 = COUNT(*)
    FROM HRA_CADSIGN
               WHERE HRA_CADSIGN.EMP_NO = @p_emp_no
                 AND FORMAT(HRA_CADSIGN.ATT_DATE, 'yyyy-MM-dd') = @p_start_date_tmp;
            END
            ELSE
            BEGIN
              SELECT @iCnt2 = COUNT(*)
    FROM HRA_CADSIGN
               WHERE HRA_CADSIGN.EMP_NO = @p_emp_no
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
               WHERE HRA_CADSIGN.EMP_NO = HRA_OTMSIGN.EMP_NO
                 AND FORMAT(ATT_DATE+1, 'yyyy-MM-dd') = FORMAT(START_DATE, 'yyyy-MM-dd')
                 AND HRA_OTMSIGN.EMP_NO = @p_emp_no
                 AND FORMAT(HRA_OTMSIGN.START_DATE, 'yyyy-MM-dd') = @p_end_date;
            END
            ELSE
            BEGIN
              SELECT @iCnt2 = (case when (  ISNULL(CONVERT(DATETIME2, FORMAT(MAX(HRA_OTMSIGN.START_DATE), 'yyyy-MM-dd')+MAX(HRA_OTMSIGN.START_TIME)) - CONVERT(DATETIME2, FORMAT(MAX(HRA_CADSIGN.ATT_DATE), 'yyyy-MM-dd')+MAX(HRA_CADSIGN.CHKOUT_CARD)),0))*60*24 > 30 then 0 else 1 end )
    FROM HRA_OTMSIGN , HRA_CADSIGN
               WHERE HRA_CADSIGN.EMP_NO = HRA_OTMSIGN.EMP_NO
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
      END
      
      ------------------------- 補休單 -------------------------
      Continue_ForEach1:
END
GO
