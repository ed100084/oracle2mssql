CREATE OR ALTER FUNCTION [ehrphra3_pkg].[f_hra4010_C_MIN]
(    @TrnYm_IN NVARCHAR(MAX),
    @TrnShift_IN NVARCHAR(MAX),
    @EmpNo_IN NVARCHAR(MAX),
    @StrartDate_IN DATETIME2(0),
    @EndDate_IN DATETIME2(0),
    @Orgtype_IN NVARCHAR(MAX),
    @UpdateBy_IN NVARCHAR(MAX)
)
RETURNS DECIMAL(38,10)
AS
BEGIN
DECLARE @sTrnYm NVARCHAR(7) = @TRNYM_IN;
DECLARE @sTrnShift NVARCHAR(2) = @TRNSHIFT_IN;
DECLARE @sEmpNo NVARCHAR(20) = @EMPNO_IN;
DECLARE @dStrartDate DATETIME2(0) = @STRARTDATE_IN;
DECLARE @dEndDate DATETIME2(0) = @ENDDATE_IN;
DECLARE @sOrganType NVARCHAR(10) = @ORGTYPE_IN;
DECLARE @sUpdateBy NVARCHAR(20) = @UPDATEBY_IN;
DECLARE @dAttDate DATETIME2(0);
DECLARE @dAttDate1 NVARCHAR(10);
DECLARE @iEvcCnt INT;
DECLARE @nTotalAbs DECIMAL(38,10);
DECLARE @nTotalAbs1 DECIMAL(38,10);
DECLARE @iCnt INT = 0;
DECLARE @RtnCode DECIMAL(38,10) = 0;
DECLARE @sCntNo NVARCHAR(1);
DECLARE @sDd NVARCHAR(2);
DECLARE @sFieldNo NVARCHAR(3);
DECLARE @nWorkHrs DECIMAL(38,10);
DECLARE cur_absence CURSOR FOR
    SELECT SUM(absence_HRS) ,ATT_DATE
   
   FROM
   (SELECT (CASE WHEN absence_HRS <0 THEN INV_TM1 ELSE absence_HRS END) absence_HRS,
    ATT_DATE FROM 




    (SELECT  
      (CASE WHEN CHKIN_CARD IS NULL AND  CHKOUT_CARD IS NULL THEN INV_TM1
            WHEN CHKOUT_CARD IS NULL THEN (INV_TM1)/2
            WHEN CHKIN_CARD IS NULL THEN (INV_TM1)/2
            ELSE INV_TM1-(CASE WHEN HRS>(4*60) THEN HRS-INV_REST ELSE (CASE WHEN HRS <0 THEN 0 ELSE  HRS END)  END ) END )absence_HRS, 
      ATT_DATE, 
      INV_TM1 
      FROM



      (SELECT ATT_DATE,CHKIN_CARD,CHKOUT_CARD,INV_TM1,INV_REST,
      ((CASE WHEN REAL_WKOUT < REAL_WKIN THEN CONVERT(DATETIME2, FORMAT(GETDATE()+1, 'MMdd')+REAL_WKOUT)
             ELSE CONVERT(DATETIME2, FORMAT(GETDATE(), 'MMdd')+REAL_WKOUT) END)-
      (CONVERT(DATETIME2, FORMAT(GETDATE(), 'MMdd')+REAL_WKIN)))*24*60 HRS
       FROM



       (SELECT EMP_NO,ATT_DATE,CLASS_CODE,CHKIN,CHKOUT,CHKIN_CARD,CHKOUT_CARD,CHKIN_WKTM,CHKOUT_WKTM,INV_TM1,INV_REST,
       (CASE WHEN REAL_WKIN >=START_REST AND REAL_WKIN <=END_REST THEN END_REST ELSE REAL_WKIN END) REAL_WKIN,
       (CASE WHEN REAL_WKOUT >=START_REST AND REAL_WKOUT <=END_REST THEN START_REST ELSE REAL_WKOUT END)REAL_WKOUT
         FROM








         (SELECT A.*,
          B.WORK_HRS*60 INV_TM1,
         (CONVERT(DATETIME2, C.END_REST)-CONVERT(DATETIME2, C.START_REST))*24*60 INV_REST,
         (CASE WHEN A.chkin IN (0, 2)  THEN A.CHKIN_WKTM  ELSE A.CHKIN_CARD END)REAL_WKIN,
         (CASE WHEN A.chkout = 3  THEN A.CHKOUT_CARD ELSE A.CHKOUT_WKTM END)REAL_WKOUT,
         C.START_REST,C.END_REST 
         FROM hra_cardatt_view A,HRA_CLASSDTL C,HRA_CLASSMST B
         WHERE (att_date BETWEEN @dStrartDate AND @dEndDate)
         AND (emp_no = @sEmpNo)
         AND (a.ORGAN_TYPE= @sOrganType ) 
         AND ((chkin ='5' OR chkout='3' )
          OR (chkin ='1' AND chkout='0' )
          OR (chkin ='1' AND chkout='1' )
          OR (chkin ='0' AND chkout='1' )
          OR (chkin ='2' AND chkout='1' ))
         AND A.class_code=C.CLASS_CODE 
         AND C.CLASS_CODE =B.CLASS_CODE
         AND A.SHIFT_NO = C.SHIFT_NO ) AS _dt1 
       ) AS _dt2
       ) AS _dt3
       ) AS _dt4
       ) AS _dt5 GROUP BY ATT_DATE;
DECLARE cur_absence3 CURSOR FOR
    SELECT SUM(absence)  absence
         , att_date
      
      FROM (SELECT COUNT(*) absence
                 , att_date
      FROM HRA_CARDABNORMAL_VIEW
             WHERE (emp_no = @sEmpNo)
			   AND (ORGAN_TYPE= @sOrganType ) 
               AND (att_date BETWEEN @dStrartDate AND @dEndDate)
         
         AND (chkin2 ='1' AND chkout2 IN ('1') )
         
             GROUP BY att_date ) AS _dt6
      GROUP BY att_date;
DECLARE cur_absence1 CURSOR FOR
    SELECT SUM(absence)  absence
         , att_date
      
      FROM (SELECT COUNT(*) absence
                 , att_date
              FROM hra_after_abnormal_view
             WHERE LTRIM(RTRIM(hra_after_abnormal_view.emp_no)) = @sEmpNo
			   AND (ORGAN_TYPE= @sOrganType ) 
               AND hra_after_abnormal_view.att_date BETWEEN FORMAT(@dStrartDate, 'yyyy-MM-dd') AND FORMAT(@dEndDate, 'yyyy-MM-dd')
             GROUP BY att_date  ) AS _dt7
      GROUP BY att_date;
DECLARE cur_absence2 CURSOR FOR
    SELECT SUM(INSUFFICIENT_MIN) absence
                 , VAC_date
         
         FROM hra_dailytran
         WHERE LTRIM(RTRIM(hra_dailytran.emp_no)) = @sEmpNo
			   AND (ORGAN_TYPE= @sOrganType ) 
         AND hra_dailytran.VAC_date BETWEEN @dStrartDate AND @dEndDate
         
         AND LATE_FLAG <> 'Y'
         GROUP BY VAC_date;
-- EXCEPTION block removed: TRY/CATCH not allowed in T-SQL scalar function

     OPEN cur_absence;
       WHILE 1=1 BEGIN
          FETCH NEXT FROM cur_absence INTO @nTotalAbs, @dAttDate;
          IF @@FETCH_STATUS <> 0 BREAK;


          IF @nTotalAbs <> 0  BEGIN
          SET @nTotalAbs1 = @nTotalAbs; --20180710 108978 曠職改核實計算
             SET @RtnCode = [ehrphra3_pkg].[f_hra4010_ins](@sTrnYm
                                                 , @sTrnShift
                                                 , @sEmpNo
                                                 , '2030'
                                                 , @nTotalAbs1
                                                 --, 'T'
												 , 'M'
												 , @sOrganType
                                                 , @sUpdateBy );
             IF @RtnCode <> 0 BEGIN
                 GOTO Continue_ForEach1 ;   --  曠職次數INSERT失敗
             END
             SET @iCnt = @iCnt + 1;
          END
          Continue_ForEach2_1:
       END
--沒有簽到和簽退記錄
	   OPEN cur_absence1;
       WHILE 1=1 BEGIN
          FETCH NEXT FROM cur_absence1 INTO @nTotalAbs, @dAttDate1;
          IF @@FETCH_STATUS <> 0 BREAK;


          IF @nTotalAbs <> 0  BEGIN
             SET @sDd = SUBSTRING(@dAttDate1,9,2);
		     -- EXCEPTION block removed: TRY/CATCH not allowed in T-SQL scalar function

    SELECT @sFieldNo = CASE WHEN @sDd = '01' THEN sch_01 WHEN @sDd = '02' THEN sch_02 WHEN @sDd = '03' THEN sch_03 WHEN @sDd = '04' THEN sch_04 WHEN @sDd = '05' THEN sch_05 WHEN @sDd = '06' THEN sch_06 WHEN @sDd = '07' THEN sch_07 WHEN @sDd = '08' THEN sch_08 WHEN @sDd = '09' THEN sch_09 WHEN @sDd = '10' THEN sch_10 WHEN @sDd = '11' THEN sch_11 WHEN @sDd = '12' THEN sch_12 WHEN @sDd = '13' THEN sch_13 WHEN @sDd = '14' THEN sch_14 WHEN @sDd = '15' THEN sch_15 WHEN @sDd = '16' THEN sch_16 WHEN @sDd = '17' THEN sch_17 WHEN @sDd = '18' THEN sch_18 WHEN @sDd = '19' THEN sch_19 WHEN @sDd = '20' THEN sch_20 WHEN @sDd = '21' THEN sch_21 WHEN @sDd = '22' THEN sch_22 WHEN @sDd = '23' THEN sch_23 WHEN @sDd = '24' THEN sch_24 WHEN @sDd = '25' THEN sch_25 WHEN @sDd = '26' THEN sch_26 WHEN @sDd = '27' THEN sch_27 WHEN @sDd = '28' THEN sch_28 WHEN @sDd = '29' THEN sch_29 WHEN @sDd = '30' THEN sch_30 WHEN @sDd = '31' THEN sch_31 END
    FROM HRA_CLASSSCH
			  WHERE SCH_YM = @sTrnYm
			  AND EMP_NO = @sEmpNo
			  AND ORG_BY = @sOrganType;

			  SELECT @nWorkHrs = WORK_HRS*60
    FROM HRA_CLASSMST
			  WHERE CLASS_CODE = @sFieldNo;

    	     SET @nTotalAbs1 = @nTotalAbs * @nWorkHrs;
             SET @RtnCode = [ehrphra3_pkg].[f_hra4010_ins](@sTrnYm
                                                 , @sTrnShift
                                                 , @sEmpNo
                                                 , '2030'
                                                 , @nTotalAbs1
                                                 --, 'T'
												                         , 'M'
                                                 , @sOrganType
												                         , @sUpdateBy );
             IF @RtnCode <> 0 BEGIN
                 GOTO Continue_ForEach1 ;   --  曠職次數INSERT失敗
             END
             SET @iCnt = @iCnt + 1;
          END
          Continue_ForEach2_2:
       END
       
--時段2沒有簽到和簽退記錄      
     OPEN cur_absence3;
       WHILE 1=1 BEGIN
          FETCH NEXT FROM cur_absence3 INTO @nTotalAbs, @dAttDate;
          IF @@FETCH_STATUS <> 0 BREAK;


          IF @nTotalAbs <> 0  BEGIN
             SET @sDd = SUBSTRING(@dAttDate1,9,2);
         -- EXCEPTION block removed: TRY/CATCH not allowed in T-SQL scalar function

    SELECT @sFieldNo = CASE WHEN @sDd = '01' THEN sch_01 WHEN @sDd = '02' THEN sch_02 WHEN @sDd = '03' THEN sch_03 WHEN @sDd = '04' THEN sch_04 WHEN @sDd = '05' THEN sch_05 WHEN @sDd = '06' THEN sch_06 WHEN @sDd = '07' THEN sch_07 WHEN @sDd = '08' THEN sch_08 WHEN @sDd = '09' THEN sch_09 WHEN @sDd = '10' THEN sch_10 WHEN @sDd = '11' THEN sch_11 WHEN @sDd = '12' THEN sch_12 WHEN @sDd = '13' THEN sch_13 WHEN @sDd = '14' THEN sch_14 WHEN @sDd = '15' THEN sch_15 WHEN @sDd = '16' THEN sch_16 WHEN @sDd = '17' THEN sch_17 WHEN @sDd = '18' THEN sch_18 WHEN @sDd = '19' THEN sch_19 WHEN @sDd = '20' THEN sch_20 WHEN @sDd = '21' THEN sch_21 WHEN @sDd = '22' THEN sch_22 WHEN @sDd = '23' THEN sch_23 WHEN @sDd = '24' THEN sch_24 WHEN @sDd = '25' THEN sch_25 WHEN @sDd = '26' THEN sch_26 WHEN @sDd = '27' THEN sch_27 WHEN @sDd = '28' THEN sch_28 WHEN @sDd = '29' THEN sch_29 WHEN @sDd = '30' THEN sch_30 WHEN @sDd = '31' THEN sch_31 END
    FROM HRA_CLASSSCH
        WHERE SCH_YM = @sTrnYm
        AND EMP_NO = @sEmpNo
        AND ORG_BY = @sOrganType;

        SELECT @nWorkHrs = WORK_HRS*60
    FROM HRA_CLASSMST
        WHERE CLASS_CODE = @sFieldNo;

           SET @nTotalAbs1 = @nTotalAbs * @nWorkHrs;
             SET @RtnCode = [ehrphra3_pkg].[f_hra4010_ins](@sTrnYm
                                                 , @sTrnShift
                                                 , @sEmpNo
                                                 , '2030'
                                                 , @nTotalAbs1
                                                 , 'M'
                                                 , @sOrganType
                                                 , @sUpdateBy );
             IF @RtnCode <> 0 BEGIN
                 GOTO Continue_ForEach1 ;   --  曠職次數INSERT失敗
             END
             SET @iCnt = @iCnt + 1;
          END
          Continue_ForEach2_3:
       END
       CLOSE cur_absence3;
    DEALLOCATE cur_absence3
       
--20180716 108978 加入請假時數不足
     OPEN cur_absence2;
       WHILE 1=1 BEGIN
          FETCH NEXT FROM cur_absence2 INTO @nTotalAbs, @dAttDate;
          IF @@FETCH_STATUS <> 0 BREAK;

  
          IF @nTotalAbs <> 0  BEGIN
             SET @nTotalAbs1 = @nTotalAbs; 
             SET @RtnCode = [ehrphra3_pkg].[f_hra4010_ins](@sTrnYm
                                                 , @sTrnShift
                                                 , @sEmpNo
                                                 , '2030'
                                                 , @nTotalAbs1
                                                 , 'M'
                                                 , @sOrganType
                                                 , @sUpdateBy );
             IF @RtnCode <> 0 BEGIN
                 GOTO Continue_ForEach1 ;   
             END
             SET @iCnt = @iCnt + 1;
          END
          Continue_ForEach2_4:
       END
       CLOSE cur_absence2;
    DEALLOCATE cur_absence2
       Continue_ForEach1:
       IF 1=1 /*%ISOPEN*/ BEGIN
         CLOSE cur_absence;
    DEALLOCATE cur_absence
       END


       RETURN @RtnCode ;
   --------------------------------For義大--------------------------------

    RETURN @iCnt;

END
GO
