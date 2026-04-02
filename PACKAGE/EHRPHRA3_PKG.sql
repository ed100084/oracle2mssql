
  CREATE OR REPLACE PACKAGE "HRP"."EHRPHRA3_PKG" is

  -- Author  : EDWIN
  -- Created : 2004/10/23 上午 09:40:27
  -- Purpose : 出勤統計

  -- Public function and procedure declarations
  -- 103.01.13 新增機構參數 ORGTYPE_IN
  PROCEDURE hra4010(TrnYm_IN        VARCHAR2
                  , TrnShift_IN     VARCHAR2
                  , UpdateBy_IN     VARCHAR2
				          , Orgtype_IN      VARCHAR2
                  , RtnCode     OUT NUMBER);

  --請假統計結轉
  -- 103.01.15 新增機構參數 ORGTYPE_IN
  FUNCTION f_hra4010_A(TrnYm_IN      VARCHAR2,
                       TrnShift_IN   VARCHAR2,
                       EmpNo_IN      VARCHAR2,
					   Orgtype_IN    VARCHAR2,
                       UpdateBy_IN   VARCHAR2) RETURN NUMBER;

  --未打卡次數統計
  -- 103.01.13 新增機構參數 ORGTYPE_IN
  FUNCTION f_hra4010_B(TrnYm_IN      VARCHAR2,
                       TrnShift_IN   VARCHAR2,
                       EmpNo_IN      VARCHAR2,
                       StrartDate_IN DATE,
                       EndDate_IN    DATE,
					   Orgtype_IN    VARCHAR2,
                       UpdateBy_IN   VARCHAR2) RETURN NUMBER;

  -- 曠職次數統計
  -- 103.01.13 新增機構參數 ORGTYPE_IN
  FUNCTION f_hra4010_C(TrnYm_IN      VARCHAR2,
                       TrnShift_IN   VARCHAR2,
                       EmpNo_IN      VARCHAR2,
                       StrartDate_IN DATE,
                       EndDate_IN    DATE,
					             Orgtype_IN    VARCHAR2,
                       UpdateBy_IN   VARCHAR2) RETURN NUMBER;
  -- 114.01 曠職調整為計算至分鐘數
  FUNCTION f_hra4010_C_min(TrnYm_IN      VARCHAR2,
                           TrnShift_IN   VARCHAR2,
                           EmpNo_IN      VARCHAR2,
                           StrartDate_IN DATE,
                           EndDate_IN    DATE,
					                 Orgtype_IN    VARCHAR2,
                           UpdateBy_IN   VARCHAR2) RETURN NUMBER;
                       

  -- 遲到分數統計
  -- 103.01.13 新增機構參數 ORGTYPE_IN
  FUNCTION f_hra4010_D(TrnYm_IN      VARCHAR2,
                       TrnShift_IN   VARCHAR2,
                       EmpNo_IN      VARCHAR2,
                       StrartDate_IN DATE,
                       EndDate_IN    DATE,
					   Orgtype_IN    VARCHAR2,
                       UpdateBy_IN   VARCHAR2) RETURN NUMBER;

  -- 早退分數統計
  -- 103.01.15 新增機構參數 ORGTYPE_IN
  FUNCTION f_hra4010_E(TrnYm_IN      VARCHAR2,
                       TrnShift_IN   VARCHAR2,
                       EmpNo_IN      VARCHAR2,
                       StrartDate_IN DATE,
                       EndDate_IN    DATE,
					   Orgtype_IN    VARCHAR2,
                       UpdateBy_IN   VARCHAR2) RETURN NUMBER;

  --超時積假時數統計
  -- 103.01.15 新增機構參數 ORGTYPE_IN
  FUNCTION f_hra4010_F(TrnYm_IN      VARCHAR2,
                       TrnShift_IN   VARCHAR2,
                       EmpNo_IN      VARCHAR2,
					   Orgtype_IN    VARCHAR2,
                       UpdateBy_IN   VARCHAR2) RETURN NUMBER;



  --積借休時數統計
  -- 103.01.15 新增機構參數 ORGTYPE_IN
  FUNCTION f_hra4010_H(TrnYm_IN      VARCHAR2,
                       TrnShift_IN   VARCHAR2,
                       EmpNo_IN      VARCHAR2,
					             Orgtype_IN    VARCHAR2,
                       UpdateBy_IN   VARCHAR2) RETURN NUMBER;



  --加班時數統計
  -- 103.01.15 新增機構參數 ORGTYPE_IN
  FUNCTION f_hra4010_J(TrnYm_IN      VARCHAR2,
                       TrnShift_IN   VARCHAR2,
                       EmpNo_IN      VARCHAR2,
					             Orgtype_IN    VARCHAR2,
                       UpdateBy_IN   VARCHAR2) RETURN NUMBER;


  -- insert/update hra_attdtl
  --103.01.15 SPHINX 新增機構參數 ORGTYPE_IN
  FUNCTION f_hra4010_Ins(TrnYm_IN      VARCHAR2
                       , TrnShift_IN   VARCHAR2
                       , EmpNo_IN      VARCHAR2
                       , AttCode_IN    VARCHAR2
                       , AttValue_IN   NUMBER
                       , AttUnit_IN    VARCHAR2
					             , Orgtype_IN    VARCHAR2
                       , UpdateBy_IN   VARCHAR2) RETURN NUMBER ;
--測試曠職核實計算
  /*FUNCTION f_hra4010_Ins_T(TrnYm_IN      VARCHAR2
                       , TrnShift_IN   VARCHAR2
                       , EmpNo_IN      VARCHAR2
                       , AttCode_IN    VARCHAR2
                       , AttValue_IN   NUMBER
                       , AttUnit_IN    VARCHAR2
					             , Orgtype_IN    VARCHAR2
                       , UpdateBy_IN   VARCHAR2) RETURN NUMBER ;*/


 --曠職次數統計 wayne--
/*FUNCTION f_hra4015_C(
                       EmpNo_IN      VARCHAR2,
                       StrartDate_IN DATE,
                       EndDate_IN    DATE,
                       Orgtype_IN    VARCHAR2) RETURN NUMBER ;*/

--計算請假時數不足
FUNCTION  f_set_hra9610temp_table(sStartDate VARCHAR2, sEndDate VARCHAR2)RETURN NUMBER;

--計算請假時數不足(多部門參數)
FUNCTION  f_set_hra9610temp_deptno(sStartDate VARCHAR2, sEndDate VARCHAR2, sDeptNo VARCHAR2)RETURN NUMBER;

--計算請假時數不足_傳工號測試用
FUNCTION  f_set_hra9610temp_test(sStartDate VARCHAR2, sEndDate VARCHAR2)RETURN NUMBER;

--計算請假時數不足 debug用 108978
FUNCTION  f_set_hra9610temp_without_i(sStartDate VARCHAR2, sEndDate VARCHAR2, sEMP_NO_I VARCHAR2)RETURN NUMBER;

--20190115 108978 查無用到的地方，故取消
--PROCEDURE p_set_hra9610temp_table(sStartDate VARCHAR2, sEndDate VARCHAR2);
end ehrphra3_pkg;

CREATE OR REPLACE PACKAGE BODY "HRP"."EHRPHRA3_PKG" IS
/**********************************************
  --出勤統計匯總(結轉時段)
  --103.01.13 SPHINX 新增機構參數條件 Orgtype_IN
**********************************************/
PROCEDURE hra4010(TrnYm_IN        VARCHAR2
                , TrnShift_IN     VARCHAR2
                , UpdateBy_IN     VARCHAR2
				        , Orgtype_IN      VARCHAR2
                , RtnCode     OUT NUMBER) AS

    sTrnYm      VARCHAR2(7) := TrnYm_IN;
    sTrnShift   VARCHAR2(2) := TrnShift_IN;
    sOrganType VARCHAR2(10) := Orgtype_IN;
    sUpdateBy   VARCHAR2(20) := UpdateBy_IN;

    sStartDay   VARCHAR2(2);
    sEndDay     VARCHAR2(2);
    dStrartDate DATE;
    dEndDate    DATE;
    sEmpNo      VARCHAR2(20);
    sDeptNo     VARCHAR2(10);
    iCnt        INTEGER;
    nSalary     NUMBER;

    sDay        VARCHAR2(2) ;
    i           INTEGER ;

    CURSOR cursor1 IS
    SELECT EMP_NO FROM HRA_CLASSSCH
     WHERE SCH_YM = sTrnYm
	     AND ORG_BY= sOrganType; --103.01.13 機構


    CURSOR cursor2 IS
    SELECT DISTINCT HRA_ATTDTL.emp_no, HRE_EMPBAS.dept_no
      FROM HRA_ATTDTL, HRE_EMPBAS
     WHERE (HRA_ATTDTL.emp_no = HRE_EMPBAS.emp_no)
       AND ((HRA_ATTDTL.trn_ym = sTrnYm)
       AND (HRA_ATTDTL.trn_shift = sTrnShift))
	     AND (HRA_ATTDTL.ORGAN_TYPE= sOrganType)
	     AND (HRA_ATTDTL.ORGAN_TYPE=HRE_EMPBAS.ORGAN_TYPE);

    BEGIN
       RtnCode := 0;
       
       --紀錄此時段是否開始執行
       INSERT INTO HRA_ATTDTL_AUDIT
       (TRN_YM, TASK, SHIFT_NO, CREATED_BY, CREATION_DATE, LAST_UPDATED_BY, LAST_UPDATE_DATE, ORG_BY, ORGAN_TYPE)
       VALUES
       (sTrnYm, 'hra4010', sTrnShift, sUpdateBy, SYSDATE, sUpdateBy, SYSDATE, sOrganType, sOrganType);
       COMMIT WORK;

       --清檔
       DELETE FROM HRA_ATTDTL
        WHERE TRN_YM = sTrnYm AND TRN_SHIFT = sTrnShift
		      AND ORGAN_TYPE= sOrganType;
       COMMIT WORK;
       SAVEPOINT SP1;

       BEGIN
          SELECT START_DAY, END_DAY
            INTO sStartDay, sEndDay
            FROM HRA_TRNSHIFT
           WHERE TRN_SHIFT = sTrnShift;
       EXCEPTION
       WHEN NO_DATA_FOUND THEN
            sStartDay := NULL;
            sEndDay   := NULL;
       END;


	  -- SPHINX 95.06.12 提前結算取最後日期要註記掉
       /*IF sTrnShift = 'A3' THEN
         sEndDay := TO_CHAR(LAST_DAY(TO_DATE(sTrnYm || '-01', 'YYYY-MM-DD')), 'DD');
       END IF;*/

       IF sStartDay IS NULL OR sEndDay IS NULL THEN
          RtnCode := 2;
          GOTO Continue_ForEach1;
       END IF;

       -- 結轉日期
       dStrartDate := TO_DATE(sTrnYm || '-' || sStartDay, 'YYYY-MM-DD');
       dEndDate    := TO_DATE(sTrnYm || '-' || sEndDay, 'YYYY-MM-DD');

       OPEN cursor1;
       LOOP
          FETCH cursor1
           INTO sEmpNo;
          EXIT WHEN cursor1%NOTFOUND;

          --未打卡次數統計
          IF f_hra4010_B(sTrnYm, sTrnShift, sEmpNo
                       , dStrartDate, dEndDate,sOrganType, sUpdateBy) <> 0 THEN
             RtnCode := 0;
             GOTO Continue_ForEach1;
          END IF;

          -- 曠職次數統計
          /*IF f_hra4010_C(sTrnYm, sTrnShift, sEmpNo
                       , dStrartDate, dEndDate, sOrganType , sUpdateBy) <> 0 THEN*/
          -- 2026.01 曠職次數統計
          IF f_hra4010_C_MIN(sTrnYm, sTrnShift, sEmpNo
                           , dStrartDate, dEndDate, sOrganType , sUpdateBy) <> 0 THEN
             RtnCode := 4;
             GOTO Continue_ForEach1;
          END IF;


          -- 遲到分數統計(for 義大 以次數計)
          IF f_hra4010_D(sTrnYm, sTrnShift, sEmpNo
                       , dStrartDate, dEndDate, sOrganType ,sUpdateBy) <> 0 THEN
             RtnCode := 0;
             GOTO Continue_ForEach1;
          END IF;

          -- 早退分數統計(for 義大 以次數計)
          IF f_hra4010_E(sTrnYm, sTrnShift, sEmpNo
                       , dStrartDate, dEndDate, sOrganType ,sUpdateBy) <> 0 THEN
             RtnCode := 6;
             GOTO Continue_ForEach1;
          END IF;

          IF sTrnShift IN ('A3') THEN
             --請假統計結轉
             IF f_hra4010_A(sTrnYm, sTrnShift, sEmpNo, sOrganType ,sUpdateBy) <> 0 THEN
                 RtnCode := 0;
                GOTO Continue_ForEach1;
             END IF;

             --超時積假時數統計
             IF f_hra4010_F(sTrnYm, sTrnShift, sEmpNo, sOrganType , sUpdateBy) <> 0 THEN
                RtnCode := 0;
                GOTO Continue_ForEach1;
             END IF;

             --批OFF時數統計(積借休時數統計)
			 -- ONCALL交通費待人事公告後再由細統計算 94.12.26 SPHINX
             IF f_hra4010_H(sTrnYm, sTrnShift, sEmpNo, sOrganType ,sUpdateBy) <> 0 THEN
                RtnCode := 10;
                GOTO Continue_ForEach1;
             END IF;

             -- 加班時數統計
             IF f_hra4010_J(sTrnYm, sTrnShift, sEmpNo, sOrganType ,sUpdateBy) <> 0 THEN
                RtnCode := 12;
                GOTO Continue_ForEach1;
             END IF;
          END IF;

          --出勤統計主檔
          OPEN cursor2;
          LOOP
             FETCH cursor2
              INTO sEmpNo, sDeptNo;
             EXIT WHEN cursor2%NOTFOUND;

            BEGIN
               SELECT NVL(SUM(SAL_AMT), 0)
                 INTO nSalary
                 FROM HRS_ACNTMST, HRS_ACNTDTL
                WHERE HRS_ACNTMST.EMP_NO = HRS_ACNTDTL.EMP_NO
                  AND HRS_ACNTMST.EMP_ID = HRS_ACNTDTL.EMP_ID
                  AND HRS_ACNTMST.EMP_NO = sEmpNo
                  AND HRS_ACNTMST.MAIN_FLAG = 'Y' AND HRS_ACNTMST.DISABLED = 'N'
				  AND HRS_ACNTMST.ORGAN_TYPE = sOrganType ;
            EXCEPTION
            WHEN NO_DATA_FOUND THEN
                 nSalary := 0;
            END;

            BEGIN
               SELECT COUNT(*)
                 INTO iCnt
                 FROM HRA_ATTMST
                WHERE TRN_YM = sTrnYm
				AND EMP_NO = sEmpNo
				AND ORGAN_TYPE = sOrganType ;
            EXCEPTION
            WHEN NO_DATA_FOUND THEN
                 iCnt := 0;
            END;

            IF iCnt = 0 THEN
               INSERT INTO HRA_ATTMST(TRN_YM
                                    , EMP_NO
                                    , DEPT_NO
                                    , SALARY
                                    , DISABLED
                                    , CREATED_BY
                                    , CREATION_DATE
                                    , LAST_UPDATED_BY
                                    , LAST_UPDATE_DATE
									, ORG_BY
									, ORGAN_TYPE )
                               VALUES(sTrnYm
                                    , sEmpNo
                                    , sDeptNo
                                    , nSalary
                                    , 'N'
                                    , sUpdateBy
                                    , SYSDATE
                                    , sUpdateBy
                                    , SYSDATE
									, sOrganType
									, sOrganType );

             ELSE
                UPDATE HRA_ATTMST
                   SET DEPT_NO = sDeptNo
                 WHERE TRN_YM = sTrnYm AND EMP_NO = sEmpNo AND ORGAN_TYPE = sOrganType;
             END IF;
             NULL;
          END LOOP;
          CLOSE cursor2;


          NULL;
       END LOOP;
       CLOSE cursor1;


       COMMIT WORK;
       NULL;

       RtnCode := 0;

       NULL;
       <<Continue_ForEach1>>
       NULL;

    EXCEPTION
    WHEN OTHERS THEN
         ROLLBACK WORK;
         RtnCode := SQLCODE;

    END hra4010;
    
  

/**********************************************
  --請假統計結轉
**********************************************/
  FUNCTION f_hra4010_A(TrnYm_IN      VARCHAR2,
                       TrnShift_IN   VARCHAR2,
                       EmpNo_IN      VARCHAR2,
                       Orgtype_IN    VARCHAR2,
                       UpdateBy_IN   VARCHAR2) RETURN NUMBER IS

    sTrnYm      VARCHAR2(7) := TrnYm_IN;
    sTrnShift   VARCHAR2(2) := TrnShift_IN;
    sEmpNo      VARCHAR2(20) := EmpNo_IN;
    sOrganType VARCHAR2(10) :=  Orgtype_IN;
    sUpdateBy   VARCHAR2(20) := UpdateBy_IN;

    sVacType     VARCHAR2(10);
    sAttCode     VARCHAR2(10);
    nVacDays     NUMBER;
    nVacHrs      NUMBER;
    nHoliHrs     NUMBER;
    nEvcTotalHrs NUMBER;
    nOffVacDays  NUMBER;
    nOffVacHrs   NUMBER;
    nOffTotalHrs NUMBER;
    nTotalHrs    NUMBER;
    iCnt         INTEGER   := 0;
    sSalCode     VARCHAR(10);
    iValue       INTEGER :=0 ;

    CURSOR cursor1 IS
      SELECT VAC_TYPE FROM HRA_VCRLMST ;

    BEGIN
       OPEN cursor1;
       LOOP
          FETCH cursor1
           INTO sVacType;
          EXIT WHEN cursor1%NOTFOUND;
          NULL;

          -- 電子請假時數
          BEGIN
             SELECT SUM(VAC_DAYS), SUM(VAC_HRS),SUM(HOLI_HRS)
               INTO nVacDays, nVacHrs,nHoliHrs
               FROM HRA_EVCREC
              WHERE EMP_NO = sEmpNo
			  AND VAC_TYPE = sVacType
			  AND TO_CHAR(START_DATE, 'YYYY-MM') = sTrnYm
			  AND STATUS = 'Y'
        AND TO_CHAR(start_date,'yyyy-mm-dd') BETWEEN '2026-03-01' AND '2026-03-30'  -- 提前結算
			  AND ORG_BY = sOrganType;
			 
          EXCEPTION
          WHEN NO_DATA_FOUND THEN
               nVacDays := 0;
               nVacHrs  := 0;
          END;

          IF nVacDays IS NULL THEN
             nVacDays := 0;
          END IF;

          IF nVacHrs IS NULL THEN
             nVacHrs := 0;
          END IF;

          nEvcTotalHrs := nVacDays * 8 + nVacHrs;

		  --100.07.27 產假,流產假 扣除假日時數
      --2020.02 與人資確認 ,須扣薪的產假不用排除非出勤日
		  IF (sVacType='J') AND (nEvcTotalHrs>0) THEN
             nEvcTotalHrs := nVacDays * 8 + nVacHrs - nHoliHrs;
		  END IF;

           nTotalHrs := nEvcTotalHrs;

          IF nTotalHrs = 0 THEN
             GOTO Continue_ForEach1;
          END IF;

          BEGIN
             SELECT ATT_CODE
               INTO sAttCode
               FROM HRA_ATTRUL
              WHERE ORG_CODE = sVacType AND ATT_KIND = '2';    -- att_kind = 2  請假
          EXCEPTION
          WHEN NO_DATA_FOUND THEN
               sAttCode := NULL;
          END;

          IF sAttCode IS NULL THEN
             GOTO Continue_ForEach1;
          END IF;

          IF Ehrphra3_Pkg.f_hra4010_ins(trnym_in    => sTrnYm
                                      , trnshift_in => sTrnShift
                                      , empno_in    => sEmpNo
                                      , attcode_in  => sAttCode
                                      , attvalue_in => nTotalHrs
                                      , attunit_in  => 'H'
									  , Orgtype_IN  => sOrganType
									  , updateby_in => sUpdateBy ) <> 0 THEN
             iCnt := 1 ;   --  請假時數INSERT失敗
          END IF;

          NULL;
          <<Continue_ForEach1>>
          NULL;
       END LOOP;
       CLOSE cursor1;
       NULL;

       ----------------------- 404全勤 405不休假 -----------------------
	   -- 94.11.07 SPHINX  薪資結構有此津貼才寫入
	   BEGIN
	     SELECT COUNT(*)
		 INTO iValue
		 FROM HRS_ACNTDTL
		 WHERE EMP_NO = sEmpNo
		 AND DISABLED='N'
		 AND SAL_CODE IN ('AA0G','AA0F')
     AND SAL_AMT>0
		 AND ORGAN_TYPE= sOrganType ;
	   EXCEPTION
	     WHEN OTHERS THEN
		      iValue :=0 ;
	   END;

	   IF iValue>0 THEN

	     IF Ehrphra3_Pkg.f_hra4010_ins(trnym_in    => sTrnYm
                                   , trnshift_in => sTrnShift
                                   , empno_in    => sEmpNo
                                   , attcode_in  => '4040'
                                   , attvalue_in => 1
                                   , attunit_in  => 'T'
								   , Orgtype_IN  => sOrganType
                                   , updateby_in => sUpdateBy ) <> 0 THEN
           iCnt := 1 ;   --  請假時數INSERT失敗
           GOTO Continue_ForEach2 ;
         END IF;


         IF Ehrphra3_Pkg.f_hra4010_ins(trnym_in    => sTrnYm
                                   , trnshift_in => sTrnShift
                                   , empno_in    => sEmpNo
                                   , attcode_in  => '4050'
                                   , attvalue_in => 1
                                   , attunit_in  => 'T'
								   , Orgtype_IN  => sOrganType
                                   , updateby_in => sUpdateBy ) <> 0 THEN
           iCnt := 1 ;   --  請假時數INSERT失敗
         END IF;
        END IF ;-- END iValue =0

       NULL;
       <<Continue_ForEach2>>
       NULL;

    ----------------------- 404全勤 405不休假 -----------------------

       RETURN iCnt;

    EXCEPTION
    WHEN OTHERS THEN
         ROLLBACK WORK;
         RETURN SQLCODE;
         NULL;
    END f_hra4010_A;

/**********************************************
  --未打卡次數統計
**********************************************/
  FUNCTION f_hra4010_B(TrnYm_IN      VARCHAR2,
                       TrnShift_IN   VARCHAR2,
                       EmpNo_IN      VARCHAR2,
                       StrartDate_IN DATE,
                       EndDate_IN    DATE,
					             Orgtype_IN    VARCHAR2,
                       UpdateBy_IN   VARCHAR2) RETURN NUMBER IS

    sTrnYm      VARCHAR2(7) := TrnYm_IN;
    sTrnShift   VARCHAR2(2) := TrnShift_IN;
    sEmpNo      VARCHAR2(20) := EmpNo_IN;
    dStrartDate DATE := StrartDate_IN;
    dEndDate    DATE := EndDate_IN;
	sOrganType VARCHAR2(10) := Orgtype_IN;
    sUpdateBy   VARCHAR2(20) := UpdateBy_IN;

    iChkIn1Cnt   INTEGER := 0;
    iChkOut1Cnt  INTEGER := 0;
    iChkIn2Cnt   INTEGER := 0;
    iChkOut2Cnt  INTEGER := 0;
    iChkIn3Cnt   INTEGER := 0;
    iChkOut3Cnt  INTEGER := 0;
    nTotalUnCard INTEGER := 0;
    iChkCardCnt  INTEGER := 0;
    iCnt         INTEGER := 0;

  BEGIN

    ------------------------- new 寫法  -------------------------
	-- 忘打卡未處理
     SELECT SUM(uncard)  uncard
      INTO nTotalUnCard
      FROM (SELECT SUM(DECODE(chkin1,  '1', 1, 0) + DECODE(chkout1, '1', 1, 0) + DECODE(chkin2,  '1', 1, 0)
                 +     DECODE(chkout2, '1', 1, 0) + DECODE(chkin3,  '1', 1, 0) + DECODE(chkout3, '1', 1, 0)
          			 +     0) uncard
              FROM HRA_CARDABNORMAL_VIEW
             WHERE EMP_NO =sEmpNo
			   AND ORGAN_TYPE= sOrganType
			   AND (ATT_DATE BETWEEN dStrartDate AND dEndDate)
			   AND (chkin1 = '1' OR chkin2 = '1' OR chkin3 = '1' OR chkout1 = '1' OR chkout2 = '1' OR chkout3 = '1')
			   ) ;


   IF nTotalUnCard>0 THEN

    IF Ehrphra3_Pkg.f_hra4010_ins(trnym_in    => sTrnYm
                                , trnshift_in => sTrnShift
                                , empno_in    => sEmpNo
                                , attcode_in  => '2010'
								, attvalue_in => nTotalUnCard
                                , attunit_in  => 'T'
   								, Orgtype_IN  => sOrganType
								, updateby_in => sUpdateBy ) <> 0 THEN
       iCnt := 1 ;   --  未打卡次數INSERT失敗
    END IF;
   END IF;

   --- 忘打卡單
   nTotalUnCard:=0;

   SELECT SUM(uncard)  uncard
     INTO nTotalUnCard
   FROM (SELECT COUNT(*) uncard
            FROM HRA_UNCARD
            WHERE emp_no =sEmpNo
			AND otm_rea LIKE '1%'
			AND (CLASS_DATE BETWEEN dStrartDate AND dEndDate)
            AND status = 'Y'
			AND ORG_BY= sOrganType  ) ;

    IF nTotalUnCard = 0 THEN
      GOTO Continue_ForEach1;
    END IF;

	  IF Ehrphra3_Pkg.f_hra4010_ins(trnym_in  => sTrnYm
                                , trnshift_in => sTrnShift
                                , empno_in    => sEmpNo
                                , attcode_in  => '2050'
                                , attvalue_in => nTotalUnCard
                                , attunit_in  => 'T'
								, Orgtype_IN  => sOrganType
                                , updateby_in => sUpdateBy ) <> 0 THEN
         iCnt := 1 ;   --  未打卡次數INSERT失敗
      END IF;


    NULL;
    <<Continue_ForEach1>>
    RETURN iCnt;
    NULL;

    ------------------------- new 寫法  -------------------------

  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK WORK;
      RETURN SQLCODE;
      NULL;
  END f_hra4010_B;

/**********************************************
  -- 曠職次數統計(曠職 + 缺席人員)
**********************************************/
  FUNCTION f_hra4010_C(TrnYm_IN      VARCHAR2,
                       TrnShift_IN   VARCHAR2,
                       EmpNo_IN      VARCHAR2,
                       StrartDate_IN DATE,
                       EndDate_IN    DATE,
                       Orgtype_IN    VARCHAR2,
                       UpdateBy_IN   VARCHAR2) RETURN NUMBER IS

    sTrnYm      VARCHAR2(7)  := TrnYm_IN;
    sTrnShift   VARCHAR2(2)  := TrnShift_IN;
    sEmpNo      VARCHAR2(20) := EmpNo_IN;
    dStrartDate DATE         := StrartDate_IN;
    dEndDate    DATE         := EndDate_IN;
   	sOrganType VARCHAR2(10) := Orgtype_IN;
    sUpdateBy   VARCHAR2(20) := UpdateBy_IN;

    dAttDate    DATE ;
    dAttDate1   VARCHAR2(10) ;
    iEvcCnt     INTEGER ;

    nTotalAbs   NUMBER;
	nTotalAbs1  NUMBER;
    iCnt        INTEGER   := 0 ;
    RtnCode     NUMBER    := 0 ;
	sCntNo      VARCHAR2(1);
	sDd         VARCHAR2(2);
	sFieldNo    VARCHAR2(3);
	nWorkHrs    NUMBER;

/*    CURSOR cur_absence IS
    SELECT SUM(absence)  absence
         , att_date
      INTO nTotalAbs
         , dAttDate
      FROM (SELECT COUNT(*) absence
                 , att_date
			 FROM HRA_CARDABNORMAL_VIEW
             WHERE (emp_no = sEmpNo)
			   AND (ORGAN_TYPE= sOrganType ) -- 機構
               AND (att_date BETWEEN dStrartDate AND dEndDate)
			   --and to_char(att_date,'yyyy-mm-dd')<='2006-03-29' -- sphinx  95.03.30
			   AND ((chkin1 IN ('1','5')) OR (chkin2 IN ('1','5')) OR (chkin3 IN ('1','5')) OR (chkout1 IN ('1','3')) OR (chkout2 IN ('1','3')) OR (chkout3 IN ('1','3')) )
			   --AND ((chkin1='5') OR (chkin2='5') OR (chkin3='5'))
             GROUP BY att_date )
      GROUP BY att_date ;*/

--20180710 108978 曠職改核實計算
   CURSOR cur_absence IS
   SELECT SUM(absence_HRS) ,ATT_DATE
   INTO nTotalAbs , dAttDate 
   FROM
   (SELECT (CASE WHEN absence_HRS <0 THEN INV_TM1 ELSE absence_HRS END) absence_HRS,
    ATT_DATE FROM 
---step4 begin
--計算曠職時數：
--1.當忘打卡時曠職時數?工時的1/2
--2.應班工時減出勤時數
    (SELECT  
      (CASE WHEN CHKIN_CARD IS NULL AND  CHKOUT_CARD IS NULL THEN INV_TM1
            WHEN CHKOUT_CARD IS NULL THEN (INV_TM1)/2
            WHEN CHKIN_CARD IS NULL THEN (INV_TM1)/2
            ELSE INV_TM1-(CASE WHEN HRS>4 THEN HRS-INV_REST ELSE (CASE WHEN HRS <0 THEN 0 ELSE  HRS END) /*避免人員輸入錯誤*/ END ) END )absence_HRS, --曠職時數
      ATT_DATE, --應出勤日
      INV_TM1 --應班工時
      FROM
---step3 begin
--計算出勤時數 HRS,判斷是否跨夜
--曠職最小單位?0.5小時，將調整後出勤簽到退時間再調整?整點後計算間隔時間。
      (SELECT ATT_DATE,CHKIN_CARD,CHKOUT_CARD,INV_TM1,INV_REST,
      ((CASE WHEN REAL_WKOUT<REAL_WKIN THEN  
               TO_DATE((CASE WHEN SUBSTR(REAL_WKOUT,3,2) >='00' AND SUBSTR(REAL_WKOUT,3,2) <'30' THEN TO_CHAR(SYSDATE+1,'MMDD')||SUBSTR(REAL_WKOUT,0,2)||'00' 
                        ELSE TO_CHAR(SYSDATE+1,'MMDD')||SUBSTR(REAL_WKOUT,0,2)||'30' END ),'MMDD HH24MI')
        ELSE TO_DATE((CASE WHEN SUBSTR(REAL_WKOUT,3,2) >='00' AND SUBSTR(REAL_WKOUT,3,2) <'30' THEN TO_CHAR(SYSDATE,'MMDD')||SUBSTR(REAL_WKOUT,0,2)||'00' 
                      ELSE TO_CHAR(SYSDATE,'MMDD')||SUBSTR(REAL_WKOUT,0,2)||'30' END ),'MMDD HH24MI') END)-
      ((CASE WHEN  SUBSTR(REAL_WKIN,3,2) ='00' THEN  TO_DATE(TO_CHAR(SYSDATE,'MMDD')||SUBSTR(REAL_WKIN,0,2)||'00','MMDD HH24MI') 
             WHEN  SUBSTR(REAL_WKIN,3,2) >'00' AND SUBSTR(REAL_WKIN,3,2) <='30' THEN  TO_DATE(TO_CHAR(SYSDATE,'MMDD')||SUBSTR(REAL_WKIN,0,2)||'30','MMDD HH24MI')
             ELSE TO_DATE(TO_CHAR(SYSDATE,'MMDD')||(SUBSTR(REAL_WKIN,0,2))||'00','MMDD HH24MI')+1/24 END )))*24 HRS
       FROM
---step2 begin
--取工號，出勤日，班表，簽到退異常狀態，實際簽到退時間，班表應簽到退時間，應班工時，中午休息時間，調整後出勤簽退到時間
--2次調整，判斷簽到退時間是否在中午休息時間內
       (SELECT EMP_NO,ATT_DATE,CLASS_CODE,CHKIN,CHKOUT,CHKIN_CARD,CHKOUT_CARD,CHKIN_WKTM,CHKOUT_WKTM,INV_TM1,INV_REST,
       (CASE WHEN REAL_WKIN >=START_REST AND REAL_WKIN <=END_REST THEN END_REST ELSE REAL_WKIN END) REAL_WKIN,
       (CASE WHEN REAL_WKOUT >=START_REST AND REAL_WKOUT <=END_REST THEN START_REST ELSE REAL_WKOUT END)REAL_WKOUT
         FROM
---step1 begin
-- SQL_NAME : f_hra3010
-- Private type declarations
--出勤異常, 0->正常, 1->未打卡, 2->遲到, 3->早退, 4->免簽, 5->曠職
--上下班簽到
--取基本資料，班表工時，
--1次調整，依chkin/chkout回傳值判斷實際簽到退時間為調整後簽到退時間
--20211104 by108482 chkin=2,REAL_WKIN帶入CHKIN_WKTM,避免曠職多算0.5小時
         (SELECT A.*,
          B.WORK_HRS INV_TM1,
         (TO_DATE(C.END_REST,'HH24MI')-TO_DATE(C.START_REST,'HH24MI'))*24 INV_REST,
         (CASE WHEN A.chkin IN (0, 2)  THEN A.CHKIN_WKTM  ELSE A.CHKIN_CARD END)REAL_WKIN,
         (CASE WHEN A.chkout = 3  THEN A.CHKOUT_CARD ELSE A.CHKOUT_WKTM END)REAL_WKOUT,
         C.START_REST,C.END_REST 
         FROM hra_cardatt_view A,HRA_CLASSDTL C,HRA_CLASSMST B
         WHERE (att_date BETWEEN dStrartDate AND dEndDate)
         AND (emp_no = sEmpNo)
         AND (a.ORGAN_TYPE= sOrganType ) -- 機構
         AND ((chkin ='5' OR chkout='3' )
          OR (chkin ='1' AND chkout='0' )
          OR (chkin ='1' AND chkout='1' )
          OR (chkin ='0' AND chkout='1' )
          OR (chkin ='2' AND chkout='1' ))
         AND A.class_code=C.CLASS_CODE 
         AND C.CLASS_CODE =B.CLASS_CODE
         AND A.SHIFT_NO = C.SHIFT_NO /*於20201013新增by108482,避免多段班曠職時數重複計算*/) --step1 end
       )--step2 end
       )--step3 end
       )--step4 end
       ) GROUP BY ATT_DATE;

--20180716 時段2沒有簽到和簽退記錄 108978
  CURSOR cur_absence3 IS
      SELECT SUM(absence)  absence
         , att_date
      INTO nTotalAbs
         , dAttDate1
      FROM (SELECT COUNT(*) absence
                 , att_date
      FROM HRA_CARDABNORMAL_VIEW
             WHERE (emp_no = sEmpNo)
			   AND (ORGAN_TYPE= sOrganType ) -- 機構
               AND (att_date BETWEEN dStrartDate AND dEndDate)
         --and to_char(att_date,'yyyy-mm-dd')<='2006-03-29' -- sphinx  95.03.30
         AND (chkin2 ='1' AND chkout2 IN '1' )
         --AND ((chkin1='5') OR (chkin2='5') OR (chkin3='5'))
             GROUP BY att_date )
      GROUP BY att_date ;
      
--20180716 沒有簽到和簽退記錄 108978
  CURSOR cur_absence1 IS
      SELECT SUM(absence)  absence
         , att_date
      INTO nTotalAbs
         , dAttDate1
      FROM (SELECT COUNT(*) absence
                 , att_date
              FROM hra_after_abnormal_view
             WHERE trim(hra_after_abnormal_view.emp_no) = sEmpNo
			   AND (ORGAN_TYPE= sOrganType ) -- 機構
               AND hra_after_abnormal_view.att_date BETWEEN TO_CHAR(dStrartDate,'YYYY-MM-DD') AND TO_CHAR(dEndDate,'YYYY-MM-DD')
             GROUP BY att_date  )
      GROUP BY att_date ;
     
--20180716 請假時數不足 108978
--20180914 遲到不列入曠職  108978
  CURSOR cur_absence2 IS
         SELECT SUM(INSUFFICIENT_TIME) absence
                 , VAC_date
         INTO nTotalAbs
              , dAttDate
         FROM hra_dailytran
         WHERE trim(hra_dailytran.emp_no) = sEmpNo
			   AND (ORGAN_TYPE= sOrganType ) -- 機構
         AND hra_dailytran.VAC_date BETWEEN dStrartDate AND dEndDate
         --AND LATE_FLAG='N'
         AND LATE_FLAG <> 'Y'
         GROUP BY VAC_date ;
   


/*CURSOR cur_absence1 IS
      SELECT 1
         , '2015-03-01'
      INTO nTotalAbs
         , dAttDate1
      FROM (SELECT COUNT(*) absence
                 , att_date
              FROM hra_after_abnormal_view
             WHERE trim(hra_after_abnormal_view.emp_no) = sEmpNo
			   AND (ORGAN_TYPE= sOrganType ) -- 機構
               AND hra_after_abnormal_view.att_date BETWEEN TO_CHAR(dStrartDate,'YYYY-MM-DD') AND TO_CHAR(dEndDate,'YYYY-MM-DD')
             GROUP BY att_date  )
      GROUP BY att_date ; */
   --------------------------------For義大--------------------------------
    BEGIN




     OPEN cur_absence;
       LOOP
          FETCH cur_absence
           INTO nTotalAbs, dAttDate;
          EXIT WHEN cur_absence%NOTFOUND;


          IF nTotalAbs <> 0  THEN
    	     /*nTotalAbs1:= nTotalAbs * 4; */
          nTotalAbs1:= nTotalAbs; --20180710 108978 曠職改核實計算
             RtnCode := Ehrphra3_Pkg.f_hra4010_ins(trnym_in    => sTrnYm
                                                 , trnshift_in => sTrnShift
                                                 , empno_in    => sEmpNo
                                                 , attcode_in  => '2030'
                                                 , attvalue_in => nTotalAbs1
                                                 --, attunit_in  => 'T'
												 , attunit_in  => 'H'
												 , Orgtype_IN  => sOrganType
                                                 , updateby_in => sUpdateBy ) ;
             IF RtnCode <> 0 THEN
                 GOTO Continue_ForEach1 ;   --  曠職次數INSERT失敗
             END IF;
             iCnt := iCnt + 1 ;
          END IF;

          NULL;
          <<Continue_ForEach2>>
          NULL;
       END LOOP ;
--沒有簽到和簽退記錄
	   OPEN cur_absence1;
       LOOP
          FETCH cur_absence1
           INTO nTotalAbs, dAttDate1;
          EXIT WHEN cur_absence1%NOTFOUND;


          IF nTotalAbs <> 0  THEN
		     --sDd:=SUBSTR(TO_CHAR(dAttDate,'YYYY-MM-DD'),9,2);
             sDd:=SUBSTR(dAttDate1,9,2);
		     BEGIN
			  SELECT DECODE(sDd,'01',sch_01,'02',sch_02,'03',sch_03,'04',sch_04,'05',sch_05,

                     '06',sch_06,'07',sch_07,'08',sch_08,'09',sch_09,'10',sch_10,

                     '11',sch_11,'12',sch_12,'13',sch_13,'14',sch_14,'15',sch_15,

                     '16',sch_16,'17',sch_17,'18',sch_18,'19',sch_19,'20',sch_20,

                     '21',sch_21,'22',sch_22,'23',sch_23,'24',sch_24,'25',sch_25,

                     '26',sch_26,'27',sch_27,'28',sch_28,'29',sch_29,'30',sch_30,'31',sch_31)

			   INTO sFieldNo
			  FROM HRA_CLASSSCH
			  WHERE SCH_YM = sTrnYm
			  AND EMP_NO = sEmpNo
			  AND ORG_BY = sOrganType;

			  SELECT WORK_HRS
			   INTO nWorkHrs
			  FROM HRA_CLASSMST
			  WHERE CLASS_CODE = sFieldNo;
			 EXCEPTION
			   WHEN OTHERS THEN
			    nWorkHrs := 8 ;
			 END;
    	     nTotalAbs1:= nTotalAbs * nWorkHrs;
             RtnCode := Ehrphra3_Pkg.f_hra4010_ins(trnym_in    => sTrnYm
                                                 , trnshift_in => sTrnShift
                                                 , empno_in    => sEmpNo
                                                 , attcode_in  => '2030'
                                                 , attvalue_in => nTotalAbs1
                                                 --, attunit_in  => 'T'
												                         , attunit_in  => 'H'
                                                 , Orgtype_IN  => sOrganType
												                         , updateby_in => sUpdateBy ) ;
             IF RtnCode <> 0 THEN
                 GOTO Continue_ForEach1 ;   --  曠職次數INSERT失敗
             END IF;
             iCnt := iCnt + 1 ;
          END IF;

          NULL;
          <<Continue_ForEach2>>
          NULL;
       END LOOP ;
       
--時段2沒有簽到和簽退記錄      
     OPEN cur_absence3;
       LOOP
          FETCH cur_absence3
           INTO nTotalAbs, dAttDate1;
          EXIT WHEN cur_absence3%NOTFOUND;


          IF nTotalAbs <> 0  THEN
         --sDd:=SUBSTR(TO_CHAR(dAttDate,'YYYY-MM-DD'),9,2);
             sDd:=SUBSTR(dAttDate1,9,2);
         BEGIN
        SELECT DECODE(sDd,'01',sch_01,'02',sch_02,'03',sch_03,'04',sch_04,'05',sch_05,

                     '06',sch_06,'07',sch_07,'08',sch_08,'09',sch_09,'10',sch_10,

                     '11',sch_11,'12',sch_12,'13',sch_13,'14',sch_14,'15',sch_15,

                     '16',sch_16,'17',sch_17,'18',sch_18,'19',sch_19,'20',sch_20,

                     '21',sch_21,'22',sch_22,'23',sch_23,'24',sch_24,'25',sch_25,

                     '26',sch_26,'27',sch_27,'28',sch_28,'29',sch_29,'30',sch_30,'31',sch_31)

         INTO sFieldNo
        FROM HRA_CLASSSCH
        WHERE SCH_YM = sTrnYm
        AND EMP_NO = sEmpNo
        AND ORG_BY = sOrganType;

        SELECT WORK_HRS
         INTO nWorkHrs
        FROM HRA_CLASSMST
        WHERE CLASS_CODE = sFieldNo;
       EXCEPTION
         WHEN OTHERS THEN
          nWorkHrs := 8 ;
       END;
           nTotalAbs1:= nTotalAbs * nWorkHrs;
             RtnCode := Ehrphra3_Pkg.f_hra4010_ins(trnym_in    => sTrnYm
                                                 , trnshift_in => sTrnShift
                                                 , empno_in    => sEmpNo
                                                 , attcode_in  => '2030'
                                                 , attvalue_in => nTotalAbs1
                                                 --, attunit_in  => 'T'
                                                 , attunit_in  => 'H'
                                                 , Orgtype_IN  => sOrganType
                                                 , updateby_in => sUpdateBy ) ;
             IF RtnCode <> 0 THEN
                 GOTO Continue_ForEach1 ;   --  曠職次數INSERT失敗
             END IF;
             iCnt := iCnt + 1 ;
          END IF;

          NULL;
          <<Continue_ForEach2>>
          NULL;
       END LOOP ;
       
--20180716 108978 加入請假時數不足
     OPEN cur_absence2;
       LOOP
          FETCH cur_absence2
           INTO nTotalAbs, dAttDate;
          EXIT WHEN cur_absence2%NOTFOUND;

  
          IF nTotalAbs <> 0  THEN
             nTotalAbs1:= nTotalAbs; 
             RtnCode := Ehrphra3_Pkg.f_hra4010_ins(trnym_in    => sTrnYm
                                                 , trnshift_in => sTrnShift
                                                 , empno_in    => sEmpNo
                                                 , attcode_in  => '2030'
                                                 , attvalue_in => nTotalAbs1
                                                 , attunit_in  => 'H'
                                                 , Orgtype_IN  => sOrganType
                                                 , updateby_in => sUpdateBy ) ;
             IF RtnCode <> 0 THEN
                 GOTO Continue_ForEach1 ;   
             END IF;
             iCnt := iCnt + 1 ;
          END IF;

          NULL;
          <<Continue_ForEach2>>
          NULL;
       END LOOP ;

       NULL;
       <<Continue_ForEach1>>
       NULL;

       IF cur_absence%ISOPEN THEN
         CLOSE cur_absence ;
       END IF ;


       RETURN RtnCode ;
   --------------------------------For義大--------------------------------

    RETURN iCnt;

  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK WORK;
      RETURN SQLCODE;
      NULL;

  END f_hra4010_C;
  
  FUNCTION f_hra4010_C_MIN(TrnYm_IN      VARCHAR2,
                           TrnShift_IN   VARCHAR2,
                           EmpNo_IN      VARCHAR2,
                           StrartDate_IN DATE,
                           EndDate_IN    DATE,
                           Orgtype_IN    VARCHAR2,
                           UpdateBy_IN   VARCHAR2) RETURN NUMBER IS

    sTrnYm      VARCHAR2(7)  := TrnYm_IN;
    sTrnShift   VARCHAR2(2)  := TrnShift_IN;
    sEmpNo      VARCHAR2(20) := EmpNo_IN;
    dStrartDate DATE         := StrartDate_IN;
    dEndDate    DATE         := EndDate_IN;
   	sOrganType  VARCHAR2(10) := Orgtype_IN;
    sUpdateBy   VARCHAR2(20) := UpdateBy_IN;

    dAttDate    DATE ;
    dAttDate1   VARCHAR2(10) ;
    iEvcCnt     INTEGER ;

    nTotalAbs   NUMBER;
  	nTotalAbs1  NUMBER;
    iCnt        INTEGER   := 0 ;
    RtnCode     NUMBER    := 0 ;
	  sCntNo      VARCHAR2(1);
	  sDd         VARCHAR2(2);
	  sFieldNo    VARCHAR2(3);
	  nWorkHrs    NUMBER;

--20180710 108978 曠職改核實計算
   CURSOR cur_absence IS
   SELECT SUM(absence_HRS) ,ATT_DATE
   --INTO nTotalAbs , dAttDate 
   FROM
   (SELECT (CASE WHEN absence_HRS <0 THEN INV_TM1 ELSE absence_HRS END) absence_HRS,
    ATT_DATE FROM 
---step4 begin
--計算曠職時數：
--1.當忘打卡時曠職時數?工時的1/2
--2.應班工時減出勤時數
    (SELECT  
      (CASE WHEN CHKIN_CARD IS NULL AND  CHKOUT_CARD IS NULL THEN INV_TM1
            WHEN CHKOUT_CARD IS NULL THEN (INV_TM1)/2
            WHEN CHKIN_CARD IS NULL THEN (INV_TM1)/2
            ELSE INV_TM1-(CASE WHEN HRS>(4*60) THEN HRS-INV_REST ELSE (CASE WHEN HRS <0 THEN 0 ELSE  HRS END) /*避免人員輸入錯誤*/ END ) END )absence_HRS, --曠職時數
      ATT_DATE, --應出勤日
      INV_TM1 --應班工時
      FROM
---step3 begin
--計算出勤時數 HRS,判斷是否跨夜
--曠職最小單位為0.5小時，將調整後出勤簽到退時間再調整?整點後計算間隔時間。
      (SELECT ATT_DATE,CHKIN_CARD,CHKOUT_CARD,INV_TM1,INV_REST,
      ((CASE WHEN REAL_WKOUT < REAL_WKIN THEN TO_DATE(TO_CHAR(SYSDATE+1,'MMDD')||REAL_WKOUT,'MMDD HH24MI')
             ELSE TO_DATE(TO_CHAR(SYSDATE,'MMDD')||REAL_WKOUT,'MMDD HH24MI') END)-
      (TO_DATE(TO_CHAR(SYSDATE,'MMDD')||REAL_WKIN,'MMDD HH24MI')))*24*60 HRS
       FROM
---step2 begin
--取工號，出勤日，班表，簽到退異常狀態，實際簽到退時間，班表應簽到退時間，應班工時，中午休息時間，調整後出勤簽退到時間
--2次調整，判斷簽到退時間是否在中午休息時間內
       (SELECT EMP_NO,ATT_DATE,CLASS_CODE,CHKIN,CHKOUT,CHKIN_CARD,CHKOUT_CARD,CHKIN_WKTM,CHKOUT_WKTM,INV_TM1,INV_REST,
       (CASE WHEN REAL_WKIN >=START_REST AND REAL_WKIN <=END_REST THEN END_REST ELSE REAL_WKIN END) REAL_WKIN,
       (CASE WHEN REAL_WKOUT >=START_REST AND REAL_WKOUT <=END_REST THEN START_REST ELSE REAL_WKOUT END)REAL_WKOUT
         FROM
---step1 begin
-- SQL_NAME : f_hra3010
-- Private type declarations
--出勤異常, 0->正常, 1->未打卡, 2->遲到, 3->早退, 4->免簽, 5->曠職
--上下班簽到
--取基本資料，班表工時，
--1次調整，依chkin/chkout回傳值判斷實際簽到退時間為調整後簽到退時間
--20211104 by108482 chkin=2,REAL_WKIN帶入CHKIN_WKTM,避免曠職多算0.5小時
         (SELECT A.*,
          B.WORK_HRS*60 INV_TM1,
         (TO_DATE(C.END_REST,'HH24MI')-TO_DATE(C.START_REST,'HH24MI'))*24*60 INV_REST,
         (CASE WHEN A.chkin IN (0, 2)  THEN A.CHKIN_WKTM  ELSE A.CHKIN_CARD END)REAL_WKIN,
         (CASE WHEN A.chkout = 3  THEN A.CHKOUT_CARD ELSE A.CHKOUT_WKTM END)REAL_WKOUT,
         C.START_REST,C.END_REST 
         FROM hra_cardatt_view A,HRA_CLASSDTL C,HRA_CLASSMST B
         WHERE (att_date BETWEEN dStrartDate AND dEndDate)
         AND (emp_no = sEmpNo)
         AND (a.ORGAN_TYPE= sOrganType ) -- 機構
         AND ((chkin ='5' OR chkout='3' )
          OR (chkin ='1' AND chkout='0' )
          OR (chkin ='1' AND chkout='1' )
          OR (chkin ='0' AND chkout='1' )
          OR (chkin ='2' AND chkout='1' ))
         AND A.class_code=C.CLASS_CODE 
         AND C.CLASS_CODE =B.CLASS_CODE
         AND A.SHIFT_NO = C.SHIFT_NO /*於20201013新增by108482,避免多段班曠職時數重複計算*/) --step1 end
       )--step2 end
       )--step3 end
       )--step4 end
       ) GROUP BY ATT_DATE;

--20180716 時段2沒有簽到和簽退記錄 108978
  CURSOR cur_absence3 IS
      SELECT SUM(absence)  absence
         , att_date
      /*INTO nTotalAbs
         , dAttDate1*/
      FROM (SELECT COUNT(*) absence
                 , att_date
      FROM HRA_CARDABNORMAL_VIEW
             WHERE (emp_no = sEmpNo)
			   AND (ORGAN_TYPE= sOrganType ) -- 機構
               AND (att_date BETWEEN dStrartDate AND dEndDate)
         --and to_char(att_date,'yyyy-mm-dd')<='2006-03-29' -- sphinx  95.03.30
         AND (chkin2 ='1' AND chkout2 IN '1' )
         --AND ((chkin1='5') OR (chkin2='5') OR (chkin3='5'))
             GROUP BY att_date )
      GROUP BY att_date ;
      
--20180716 沒有簽到和簽退記錄 108978
  CURSOR cur_absence1 IS
      SELECT SUM(absence)  absence
         , att_date
      /*INTO nTotalAbs
         , dAttDate1*/
      FROM (SELECT COUNT(*) absence
                 , att_date
              FROM hra_after_abnormal_view
             WHERE trim(hra_after_abnormal_view.emp_no) = sEmpNo
			   AND (ORGAN_TYPE= sOrganType ) -- 機構
               AND hra_after_abnormal_view.att_date BETWEEN TO_CHAR(dStrartDate,'YYYY-MM-DD') AND TO_CHAR(dEndDate,'YYYY-MM-DD')
             GROUP BY att_date  )
      GROUP BY att_date ;
     
--20180716 請假時數不足 108978
--20180914 遲到不列入曠職  108978
  CURSOR cur_absence2 IS
         --SELECT SUM(INSUFFICIENT_TIME) absence
         SELECT SUM(INSUFFICIENT_MIN) absence
                 , VAC_date
         /*INTO nTotalAbs
              , dAttDate*/
         FROM hra_dailytran
         WHERE trim(hra_dailytran.emp_no) = sEmpNo
			   AND (ORGAN_TYPE= sOrganType ) -- 機構
         AND hra_dailytran.VAC_date BETWEEN dStrartDate AND dEndDate
         --AND LATE_FLAG='N'
         AND LATE_FLAG <> 'Y'
         GROUP BY VAC_date ;
   
   --------------------------------For義大--------------------------------
    BEGIN




     OPEN cur_absence;
       LOOP
          FETCH cur_absence
           INTO nTotalAbs, dAttDate;
          EXIT WHEN cur_absence%NOTFOUND;


          IF nTotalAbs <> 0  THEN
          nTotalAbs1:= nTotalAbs; --20180710 108978 曠職改核實計算
             RtnCode := Ehrphra3_Pkg.f_hra4010_ins(trnym_in    => sTrnYm
                                                 , trnshift_in => sTrnShift
                                                 , empno_in    => sEmpNo
                                                 , attcode_in  => '2030'
                                                 , attvalue_in => nTotalAbs1
                                                 --, attunit_in  => 'T'
												 , attunit_in  => 'M'
												 , Orgtype_IN  => sOrganType
                                                 , updateby_in => sUpdateBy ) ;
             IF RtnCode <> 0 THEN
                 GOTO Continue_ForEach1 ;   --  曠職次數INSERT失敗
             END IF;
             iCnt := iCnt + 1 ;
          END IF;

          NULL;
          <<Continue_ForEach2>>
          NULL;
       END LOOP ;
--沒有簽到和簽退記錄
	   OPEN cur_absence1;
       LOOP
          FETCH cur_absence1
           INTO nTotalAbs, dAttDate1;
          EXIT WHEN cur_absence1%NOTFOUND;


          IF nTotalAbs <> 0  THEN
             sDd:=SUBSTR(dAttDate1,9,2);
		     BEGIN
			  SELECT DECODE(sDd,'01',sch_01,'02',sch_02,'03',sch_03,'04',sch_04,'05',sch_05,

                     '06',sch_06,'07',sch_07,'08',sch_08,'09',sch_09,'10',sch_10,

                     '11',sch_11,'12',sch_12,'13',sch_13,'14',sch_14,'15',sch_15,

                     '16',sch_16,'17',sch_17,'18',sch_18,'19',sch_19,'20',sch_20,

                     '21',sch_21,'22',sch_22,'23',sch_23,'24',sch_24,'25',sch_25,

                     '26',sch_26,'27',sch_27,'28',sch_28,'29',sch_29,'30',sch_30,'31',sch_31)

			   INTO sFieldNo
			  FROM HRA_CLASSSCH
			  WHERE SCH_YM = sTrnYm
			  AND EMP_NO = sEmpNo
			  AND ORG_BY = sOrganType;

			  SELECT WORK_HRS*60
			   INTO nWorkHrs
			  FROM HRA_CLASSMST
			  WHERE CLASS_CODE = sFieldNo;
			 EXCEPTION
			   WHEN OTHERS THEN
			    nWorkHrs := 8 ;
			 END;
    	     nTotalAbs1:= nTotalAbs * nWorkHrs;
             RtnCode := Ehrphra3_Pkg.f_hra4010_ins(trnym_in    => sTrnYm
                                                 , trnshift_in => sTrnShift
                                                 , empno_in    => sEmpNo
                                                 , attcode_in  => '2030'
                                                 , attvalue_in => nTotalAbs1
                                                 --, attunit_in  => 'T'
												                         , attunit_in  => 'M'
                                                 , Orgtype_IN  => sOrganType
												                         , updateby_in => sUpdateBy ) ;
             IF RtnCode <> 0 THEN
                 GOTO Continue_ForEach1 ;   --  曠職次數INSERT失敗
             END IF;
             iCnt := iCnt + 1 ;
          END IF;

          NULL;
          <<Continue_ForEach2>>
          NULL;
       END LOOP ;
       
--時段2沒有簽到和簽退記錄      
     OPEN cur_absence3;
       LOOP
          FETCH cur_absence3
           INTO nTotalAbs, dAttDate;
          EXIT WHEN cur_absence3%NOTFOUND;


          IF nTotalAbs <> 0  THEN
             sDd:=SUBSTR(dAttDate1,9,2);
         BEGIN
        SELECT DECODE(sDd,'01',sch_01,'02',sch_02,'03',sch_03,'04',sch_04,'05',sch_05,

                     '06',sch_06,'07',sch_07,'08',sch_08,'09',sch_09,'10',sch_10,

                     '11',sch_11,'12',sch_12,'13',sch_13,'14',sch_14,'15',sch_15,

                     '16',sch_16,'17',sch_17,'18',sch_18,'19',sch_19,'20',sch_20,

                     '21',sch_21,'22',sch_22,'23',sch_23,'24',sch_24,'25',sch_25,

                     '26',sch_26,'27',sch_27,'28',sch_28,'29',sch_29,'30',sch_30,'31',sch_31)

         INTO sFieldNo
        FROM HRA_CLASSSCH
        WHERE SCH_YM = sTrnYm
        AND EMP_NO = sEmpNo
        AND ORG_BY = sOrganType;

        SELECT WORK_HRS*60
         INTO nWorkHrs
        FROM HRA_CLASSMST
        WHERE CLASS_CODE = sFieldNo;
       EXCEPTION
         WHEN OTHERS THEN
          nWorkHrs := 8 ;
       END;
           nTotalAbs1:= nTotalAbs * nWorkHrs;
             RtnCode := Ehrphra3_Pkg.f_hra4010_ins(trnym_in    => sTrnYm
                                                 , trnshift_in => sTrnShift
                                                 , empno_in    => sEmpNo
                                                 , attcode_in  => '2030'
                                                 , attvalue_in => nTotalAbs1
                                                 , attunit_in  => 'M'
                                                 , Orgtype_IN  => sOrganType
                                                 , updateby_in => sUpdateBy ) ;
             IF RtnCode <> 0 THEN
                 GOTO Continue_ForEach1 ;   --  曠職次數INSERT失敗
             END IF;
             iCnt := iCnt + 1 ;
          END IF;

          NULL;
          <<Continue_ForEach2>>
          NULL;
       END LOOP ;
       CLOSE cur_absence3;
       
--20180716 108978 加入請假時數不足
     OPEN cur_absence2;
       LOOP
          FETCH cur_absence2
           INTO nTotalAbs, dAttDate;
          EXIT WHEN cur_absence2%NOTFOUND;

  
          IF nTotalAbs <> 0  THEN
             nTotalAbs1:= nTotalAbs; 
             RtnCode := Ehrphra3_Pkg.f_hra4010_ins(trnym_in    => sTrnYm
                                                 , trnshift_in => sTrnShift
                                                 , empno_in    => sEmpNo
                                                 , attcode_in  => '2030'
                                                 , attvalue_in => nTotalAbs1
                                                 , attunit_in  => 'M'
                                                 , Orgtype_IN  => sOrganType
                                                 , updateby_in => sUpdateBy ) ;
             IF RtnCode <> 0 THEN
                 GOTO Continue_ForEach1 ;   
             END IF;
             iCnt := iCnt + 1 ;
          END IF;

          NULL;
          <<Continue_ForEach2>>
          NULL;
       END LOOP ;
       CLOSE cur_absence2;

       NULL;
       <<Continue_ForEach1>>
       NULL;

       IF cur_absence%ISOPEN THEN
         CLOSE cur_absence ;
       END IF ;


       RETURN RtnCode ;
   --------------------------------For義大--------------------------------

    RETURN iCnt;

  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK WORK;
      RETURN SQLCODE;
      NULL;

  END f_hra4010_C_min;

/**********************************************
  -- 遲到分數統計(義大以次數)
**********************************************/
FUNCTION f_hra4010_D(TrnYm_IN      VARCHAR2,
                       TrnShift_IN   VARCHAR2,
                       EmpNo_IN      VARCHAR2,
                       StrartDate_IN DATE,
                       EndDate_IN    DATE,
					             Orgtype_IN    VARCHAR2,
                       UpdateBy_IN   VARCHAR2) RETURN NUMBER IS

    sTrnYm      VARCHAR2(7) := TrnYm_IN;
    sTrnShift   VARCHAR2(2) := TrnShift_IN;
    sEmpNo      VARCHAR2(20) := EmpNo_IN;
    dStrartDate DATE := StrartDate_IN;
    dEndDate    DATE := EndDate_IN;
	  sOrganType VARCHAR2(10) := Orgtype_IN;
    sUpdateBy   VARCHAR2(20) := UpdateBy_IN;

    iLate      INTEGER;
    iCnt       INTEGER;
    iLate_DAILYTRAN INTEGER:=0;

    --------------------------------For義大--------------------------------
    BEGIN

       BEGIN
          SELECT COUNT(*)
            INTO iLate
            FROM hra_cardatt_view
           WHERE (hra_cardatt_view.emp_no = sEmpNo)
             AND (hra_cardatt_view.att_date BETWEEN dStrartDate AND dEndDate)
             AND (hra_cardatt_view.chkin = '2');
       EXCEPTION
       WHEN NO_DATA_FOUND THEN
            iLate := 0 ;
       END ;
       
--20180914 108978 加入請假時數不足列入遲到的人       
       BEGIN
          SELECT COUNT(*)
            INTO iLate_DAILYTRAN
            FROM HRA_DAILYTRAN
           WHERE HRA_DAILYTRAN.EMP_NO = sEmpNo
             AND HRA_DAILYTRAN.LATE_FLAG = 'Y'
             AND (HRA_DAILYTRAN.VAC_DATE BETWEEN dStrartDate AND dEndDate);
       EXCEPTION
       WHEN NO_DATA_FOUND THEN
            iLate_DAILYTRAN := 0 ;
       END ; 
             
       iLate :=iLate+iLate_DAILYTRAN;
       
       IF iLate > 0 THEN
          IF Ehrphra3_Pkg.f_hra4010_ins(trnym_in    => sTrnYm
                                      , trnshift_in => sTrnShift
                                      , empno_in    => sEmpNo
									                    , attcode_in  => '2060'
                                      , attvalue_in => iLate
                                      , attunit_in  => 'T'
									                    , Orgtype_IN  => sOrganType
                                      , updateby_in => sUpdateBy ) <> 0 THEN
             iCnt := 1 ;   --  遲到次數INSERT失敗
          END IF;
       END IF;
       --------------------------------For義大--------------------------------
       NULL;
       RETURN iCnt;

    EXCEPTION
    WHEN OTHERS THEN
         ROLLBACK WORK;
         RETURN SQLCODE;
         NULL;

    END f_hra4010_D;


/**********************************************
  -- 早退分數統計(義大以次數計)
**********************************************/
  FUNCTION f_hra4010_E(TrnYm_IN      VARCHAR2,
                       TrnShift_IN   VARCHAR2,
                       EmpNo_IN      VARCHAR2,
                       StrartDate_IN DATE,
                       EndDate_IN    DATE,
					   Orgtype_IN    VARCHAR2,
                       UpdateBy_IN   VARCHAR2) RETURN NUMBER IS

    sTrnYm      VARCHAR2(7)  := TrnYm_IN;
    sTrnShift   VARCHAR2(2)  := TrnShift_IN;
    sEmpNo      VARCHAR2(20) := EmpNo_IN;
    dStrartDate DATE         := StrartDate_IN;
    dEndDate    DATE         := EndDate_IN;
	sOrganType VARCHAR2(10) := Orgtype_IN;
    sUpdateBy   VARCHAR2(20) := UpdateBy_IN;

    iEarly     INTEGER;
    iCnt       INTEGER;

     --------------------------------For義大--------------------------------
    BEGIN
       BEGIN
          SELECT COUNT(*)
            INTO iEarly
            FROM hra_cardatt_view
           WHERE (hra_cardatt_view.emp_no = sEmpNo)
             AND (hra_cardatt_view.att_date BETWEEN dStrartDate AND dEndDate)
             AND (hra_cardatt_view.chkout = '3')
			 AND (hra_cardatt_view.organ_type=sOrganType );
       EXCEPTION
       WHEN NO_DATA_FOUND THEN
            iEarly := 0 ;
       END ;

       IF iEarly > 0 THEN
          IF Ehrphra3_Pkg.f_hra4010_ins(trnym_in    => sTrnYm
                                      , trnshift_in => sTrnShift
                                      , empno_in    => sEmpNo
                                      , attcode_in  => '2021'
                                      , attvalue_in => iEarly
                                      , attunit_in  => 'T'
									  , Orgtype_IN  => sOrganType
									  , updateby_in => sUpdateBy ) <> 0 THEN
             iCnt := 1 ;   --  早退次數INSERT失敗
          END IF ;
       END IF;
       --------------------------------For義大--------------------------------

       NULL;
       RETURN iCnt ;

    EXCEPTION
    WHEN OTHERS THEN
         ROLLBACK WORK;
         RETURN SQLCODE;
         NULL;

  END f_hra4010_E;

/**********************************************
  --積假時數統計_班別 年度行事曆 積借休單
**********************************************/
  FUNCTION f_hra4010_F(TrnYm_IN      VARCHAR2,
                       TrnShift_IN   VARCHAR2,
                       EmpNo_IN      VARCHAR2,
					             Orgtype_IN    VARCHAR2,
                       UpdateBy_IN   VARCHAR2) RETURN NUMBER IS

    sTrnYm      VARCHAR2(7) := TrnYm_IN;
    sTrnShift   VARCHAR2(2) := TrnShift_IN;
    sEmpNo      VARCHAR2(20) := EmpNo_IN;
    sOrganType VARCHAR2(10) := Orgtype_IN;
    sUpdateBy   VARCHAR2(20) := UpdateBy_IN;

    nOverTime NUMBER;
    iCnt      INTEGER;
    nMonAddhrs NUMBER;
    iCnt_1  INTEGER;
    sDeptNo   VARCHAR2(10);

  BEGIN

    BEGIN
--20180731 108978 修改積休時數不計排班時數不平，nMonAddhrs 給0
      SELECT 
        mon_otmhrs-mon_otmhrs_n,0,dept_no --提前結算要解開，然後下一行要註釋，記得修改HRA_ATTVAC_VIEW mon_otmhrs_n的日期區間 20190122 108978
        --mon_otmhrs,0,dept_no
        INTO nOverTime,nMonAddhrs,sDeptNo
        FROM hra_attvac_view
       WHERE (hra_attvac_view.sch_ym = sTrnYm) AND
	         (hra_attvac_view.emp_no = sEmpNo) AND
			  (hra_attvac_view.ORGAN_TYPE= sOrganType ) ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        nOverTime := 0;
		nMonAddhrs:=0;
    END;

    IF nOverTime IS NULL THEN
      nOverTime := 0;
	  nMonAddhrs:=0;
    END IF;

    IF Ehrphra3_Pkg.f_hra4010_ins(trnym_in    => sTrnYm
                                , trnshift_in => sTrnShift
                                , empno_in    => sEmpNo
                                , attcode_in  => '2040'
                                , attvalue_in => nOverTime
                                , attunit_in  => 'H'
								, Orgtype_IN  => sOrganType
                                , updateby_in => sUpdateBy ) <> 0 THEN
         iCnt := 1 ;   --  積假時數INSERT失敗
    END IF ;


-- 99.09.28  SPHINX 班表超時時數
    BEGIN
      SELECT COUNT(*)
        INTO iCnt_1
        FROM HRA_OFFREC_CAL
       WHERE SCH_YM= sTrnYm
	   AND EMP_NO = sEmpNo
	   AND ORGAN_TYPE= sOrganType ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        iCnt_1 := 0;
    END;

    IF iCnt_1 = 0 THEN

      INSERT INTO HRA_OFFREC_CAL
        (SCH_YM,
         EMP_NO,
         MON_ADDHRS,
         MON_SPECAL,
         DISABLED,
         CREATED_BY,
         CREATION_DATE,
         LAST_UPDATED_BY,
         LAST_UPDATE_DATE,
		 DEPT_NO,
		 ORG_BY,
		 ORGAN_TYPE )
      VALUES
        (sTrnYm,
         sEmpNo,
         nMonAddhrs,
         0,
         'N',
         sUpdateBy,
         SYSDATE,
         sUpdateBy,
         SYSDATE,
		 sDeptNo,
		 sOrganType,
		 sOrganType );

    ELSE
      UPDATE HRA_OFFREC_CAL
         SET MON_ADDHRS= nMonAddhrs,LAST_UPDATED_BY=sUpdateBy,LAST_UPDATE_DATE=SYSDATE
       WHERE SCH_YM = sTrnYm  AND EMP_NO = sEmpNo AND ORGAN_TYPE= sOrganType ;

    END IF;

    NULL;
    RETURN iCnt;

  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK WORK;
      RETURN SQLCODE;
      NULL;

  END f_hra4010_F;

/**********************************************
  --積借休時數統計_積借休單
  --20180323 加入加班單
**********************************************/
  FUNCTION f_hra4010_H(TrnYm_IN      VARCHAR2,
                       TrnShift_IN   VARCHAR2,
                       EmpNo_IN      VARCHAR2,
                       Orgtype_IN    VARCHAR2,
                       UpdateBy_IN   VARCHAR2) RETURN NUMBER IS

    sTrnYm      VARCHAR2(7) := TrnYm_IN;
    sTrnShift   VARCHAR2(2) := TrnShift_IN;
    sEmpNo      VARCHAR2(20) := EmpNo_IN;
    sOrganType VARCHAR2(10) := Orgtype_IN;
    sUpdateBy   VARCHAR2(20) := UpdateBy_IN;

    nOffTime    NUMBER;
    nTrafficfee NUMBER;
    RtnCode     NUMBER ;
--    iCnt        INTEGER;

    BEGIN

      BEGIN
        SELECT SUM(A. otm_hrs),SUM(traffic_fee) 
          INTO nOffTime, nTrafficfee
          FROM (
            SELECT NVL(SUM(DECODE(item_type, 'A', otm_hrs , otm_hrs * -1)), 0) otm_hrs,
                   NVL(SUM((SELECT NVL(code_value, 0) FROM HR_CODEDTL
                             WHERE code_type = 'HRA40'
                               AND code_no = traffic_fee)), 0) traffic_fee
              FROM HRA_OFFREC
             WHERE EMP_NO = sEmpNo
               AND trn_ym = sTrnYm
		           AND TO_CHAR(START_DATE,'YYYY-MM-DD') BETWEEN '2026-03-01' AND '2026-03-30' -- 提前結算
               AND STATUS = 'Y'
			         AND ORG_BY = sOrganType 
            UNION ALL
            SELECT NVL(SUM( otm_hrs), 0) otm_hrs,
                   NVL(SUM((SELECT NVL(code_value, 0) FROM HR_CODEDTL
                             WHERE code_type = 'HRA40'
                               AND code_no = traffic_fee)), 0) traffic_fee
              FROM HRA_OTMSIGN
             WHERE EMP_NO = sEmpNo
               AND trn_ym1 = sTrnYm
               AND OTM_NO LIKE ('OTM%')
               AND TO_CHAR(START_DATE,'YYYY-MM-DD') BETWEEN '2026-03-01' AND '2026-03-30' -- 提前結算
               AND STATUS = 'Y'
               AND ORG_BY = sOrganType 
          ) A ;
      EXCEPTION WHEN NO_DATA_FOUND THEN
        nOffTime := 0;
        ntrafficfee := 0;
      END;

       --------------------------ONCALL交通費--------------------------
       IF nTrafficfee = 0 THEN
          GOTO Continue_ForEach2 ;
       END IF;

       IF Ehrphra3_Pkg.f_hra4010_ins(trnym_in    => sTrnYm
                                   , trnshift_in => sTrnShift
                                   , empno_in    => sEmpNo
                                   , attcode_in  => '3051'
                                   , attvalue_in => nTrafficfee
                                   , attunit_in  => 'N'
								   , Orgtype_IN  => sOrganType
                                   , updateby_in => sUpdateBy ) <> 0 THEN
          RtnCode := 2 ;   -- 交通費INSERT失敗
          GOTO Continue_ForEach2 ;
       END IF ;

       NULL ;
       <<Continue_ForEach2>>
       NULL ;
       --------------------------交通費--------------------------

    NULL;
    RETURN RtnCode;

  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK WORK;
      RETURN SQLCODE;
      NULL;

  END f_hra4010_H;


/**********************************************
  --加班時數統計結轉
**********************************************/
FUNCTION f_hra4010_J(TrnYm_IN      VARCHAR2
                   , TrnShift_IN   VARCHAR2
                   , EmpNo_IN      VARCHAR2
				           , Orgtype_IN    VARCHAR2
                   , UpdateBy_IN   VARCHAR2) RETURN NUMBER IS

    sTrnYm      VARCHAR2(7) := TrnYm_IN;
    sTrnShift   VARCHAR2(2) := TrnShift_IN;
    sEmpNo      VARCHAR2(20) := EmpNo_IN;
	  sOrganType  VARCHAR2(10) := Orgtype_IN;
    sUpdateBy   VARCHAR2(20) := UpdateBy_IN;
    RtnCode     NUMBER ;

    nFee        NUMBER;
	  nFeeCount   NUMBER;

    CURSOR cur_otmsign IS
    --20231212 by108482 先每月彙總後再加總
    SELECT A.EMP_NO, SUM(A.OTM_FEE) AS OTM_FEE, SUM(A.ONCALL_FEE) AS ONCALL_FEE
      FROM (SELECT EMP_NO,
                   TO_CHAR(START_DATE, 'yyyy-mm'),
                   CEIL(NVL(SUM(OTM_FEE), 0)) OTM_FEE,
                   CEIL(NVL(SUM(ONCALL_FEE), 0)) ONCALL_FEE
              FROM HRA_OTMSIGN
             WHERE HRA_OTMSIGN.STATUS = 'Y'
               AND OTM_NO LIKE 'OTM%'
               AND HRA_OTMSIGN.EMP_NO = sEmpNo
               AND HRA_OTMSIGN.TRN_YM = sTrnYm
               AND HRA_OTMSIGN.ORG_BY = sOrganType
             GROUP BY EMP_NO, TO_CHAR(START_DATE, 'yyyy-mm')) A
    GROUP BY A.EMP_NO;

    cur_getotmsign   cur_otmsign%ROWTYPE ;


    BEGIN
       OPEN cur_otmsign ;
       LOOP
          FETCH cur_otmsign
           INTO cur_getotmsign;
          EXIT WHEN cur_otmsign%NOTFOUND;

          --------------------------加班時數--------------------------
          RtnCode := 0 ;


          IF cur_getotmsign.oncall_fee>0 THEN
             IF Ehrphra3_Pkg.f_hra4010_ins(trnym_in   => sTrnYm
                                     , trnshift_in => sTrnShift
                                     , empno_in    => sEmpNo
                                     , attcode_in  => '3041'
                                     , attvalue_in => cur_getotmsign.oncall_fee
                                     , attunit_in  => 'N'
									                   , Orgtype_IN  => sOrganType
                                     , updateby_in => sUpdateBy ) <> 0 THEN

                RtnCode := 1 ;   -- 加班時數INSERT失敗
                GOTO Continue_ForEach2 ;
             END IF ;
          END IF;

          -- 免稅
          IF cur_getotmsign.otm_fee = 0  THEN
             GOTO Continue_ForEach1 ;
          END IF;

          IF Ehrphra3_Pkg.f_hra4010_ins(trnym_in   => sTrnYm
                                     , trnshift_in => sTrnShift
                                     , empno_in    => sEmpNo
                                     , attcode_in  => '3031'
                                     , attvalue_in => cur_getotmsign.otm_fee
                                     , attunit_in  => 'N'
									                   , Orgtype_IN  => sOrganType
                                     , updateby_in => sUpdateBy ) <> 0 THEN
             RtnCode := 1 ;   -- 加班時數INSERT失敗
             GOTO Continue_ForEach2 ;
          END IF ;

          <<Continue_ForEach1>>
          NULL ;
          --------------------------加班時數--------------------------

          --------------------------交通費--------------------------
       
           NULL ;
           <<Continue_ForEach2>>
           NULL ;
          --------------------------交通費--------------------------

       END LOOP ;
       CLOSE cur_otmsign ;

       NULL;
       RETURN RtnCode;
       NULL;

    EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK WORK;
      RtnCode := SQLCODE;

      RETURN RtnCode;
      NULL;
    END f_hra4010_J;


/**********************************************
  --inset/update hra_attdtl
**********************************************/
FUNCTION f_hra4010_Ins(TrnYm_IN      VARCHAR2
                     , TrnShift_IN   VARCHAR2
                     , EmpNo_IN      VARCHAR2
                     , AttCode_IN    VARCHAR2
                     , AttValue_IN   NUMBER
                     , AttUnit_IN    VARCHAR2
					           , Orgtype_IN    VARCHAR2
                     , UpdateBy_IN   VARCHAR2) RETURN NUMBER IS


    sTrnYm      VARCHAR2(7) := TrnYm_IN;
    sTrnShift   VARCHAR2(2) := TrnShift_IN;
    sEmpNo      VARCHAR2(20) := EmpNo_IN;
    sAttCode    VARCHAR2(4)  := AttCode_IN ;
    sAttValue   NUMBER       := AttValue_IN ;
    sAttUnit    VARCHAR2(1)  := AttUnit_IN ;
	sOrganType VARCHAR2(10) := Orgtype_IN;
    sUpdateBy   VARCHAR2(20) := UpdateBy_IN;

    iCnt        INTEGER ;

    BEGIN
       BEGIN
          SELECT COUNT(*)
            INTO iCnt
            FROM HRA_ATTDTL
           WHERE TRN_YM = sTrnYm
		   AND TRN_SHIFT = sTrnShift
		   AND EMP_NO = sEmpNo
           AND ATT_CODE = sAttCode
		   AND ORGAN_TYPE = sOrganType ;
       EXCEPTION
       WHEN NO_DATA_FOUND THEN
            iCnt := 0;
       END;

       IF iCnt = 0 THEN
          INSERT INTO HRA_ATTDTL(TRN_YM
                               , TRN_SHIFT
                               , EMP_NO
                               , ATT_CODE
                               , ATT_VALUE
                               , ATT_UNIT
                               , CREATED_BY
                               , CREATION_DATE
                               , LAST_UPDATED_BY
                               , LAST_UPDATE_DATE
							   , ORG_BY
							   , ORGAN_TYPE )
                          VALUES(sTrnYm
                               , sTrnShift
                               , sEmpNo
                               , sAttCode
                               , sAttValue
                               , sAttUnit
                               , sUpdateBy
                               , SYSDATE
                               , sUpdateBy
                               , SYSDATE
							   , sOrganType
							   , sOrganType );

       ELSE
          UPDATE HRA_ATTDTL
             SET ATT_VALUE = ATT_VALUE + sAttValue
           WHERE TRN_YM = sTrnYm AND TRN_SHIFT = sTrnShift AND EMP_NO = sEmpNo
             AND ATT_CODE = sAttCode AND ORGAN_TYPE= sOrganType ;
       END IF;

       NULL;
       RETURN 0;

    EXCEPTION
    WHEN OTHERS THEN
         ROLLBACK WORK;
         RETURN SQLCODE;
         NULL;
    END f_hra4010_Ins;

/*FUNCTION f_hra4010_Ins_T(TrnYm_IN      VARCHAR2
                     , TrnShift_IN   VARCHAR2
                     , EmpNo_IN      VARCHAR2
                     , AttCode_IN    VARCHAR2
                     , AttValue_IN   NUMBER
                     , AttUnit_IN    VARCHAR2
                     , Orgtype_IN    VARCHAR2
                     , UpdateBy_IN   VARCHAR2) RETURN NUMBER IS


    sTrnYm      VARCHAR2(7) := TrnYm_IN;
    sTrnShift   VARCHAR2(2) := TrnShift_IN;
    sEmpNo      VARCHAR2(20) := EmpNo_IN;
    sAttCode    VARCHAR2(4)  := AttCode_IN ;
    sAttValue   NUMBER       := AttValue_IN ;
    sAttUnit    VARCHAR2(1)  := AttUnit_IN ;
    sOrganType VARCHAR2(10) := Orgtype_IN;
    sUpdateBy   VARCHAR2(20) := UpdateBy_IN;

    iCnt        INTEGER ;

    BEGIN
       BEGIN
          SELECT COUNT(*)
            INTO iCnt
            FROM HRA_ATTDTL_T
           WHERE TRN_YM = sTrnYm
       AND TRN_SHIFT = sTrnShift
       AND EMP_NO = sEmpNo
           AND ATT_CODE = sAttCode
       AND ORGAN_TYPE = sOrganType ;
       EXCEPTION
       WHEN NO_DATA_FOUND THEN
            iCnt := 0;
       END;

       IF iCnt = 0 THEN
          INSERT INTO HRA_ATTDTL_T(TRN_YM
                               , TRN_SHIFT
                               , EMP_NO
                               , ATT_CODE
                               , ATT_VALUE
                               , ATT_UNIT
                               , CREATED_BY
                               , CREATION_DATE
                               , LAST_UPDATED_BY
                               , LAST_UPDATE_DATE
                 , ORG_BY
                 , ORGAN_TYPE )
                          VALUES(sTrnYm
                               , sTrnShift
                               , sEmpNo
                               , sAttCode
                               , sAttValue
                               , sAttUnit
                               , sUpdateBy
                               , SYSDATE
                               , sUpdateBy
                               , SYSDATE
                 , sOrganType
                 , sOrganType );

       ELSE
          UPDATE HRA_ATTDTL_T
             SET ATT_VALUE = ATT_VALUE + sAttValue
           WHERE TRN_YM = sTrnYm AND TRN_SHIFT = sTrnShift AND EMP_NO = sEmpNo
             AND ATT_CODE = sAttCode AND ORGAN_TYPE= sOrganType ;
       END IF;

       NULL;
       RETURN 0;

    EXCEPTION
    WHEN OTHERS THEN
         ROLLBACK WORK;
         RETURN SQLCODE;
         NULL;
    END f_hra4010_Ins_T;*/
/**********************************************
-- f_hra4010_class.sql
-- update hra_classsch(月中到/月中離)
**********************************************/
/*
FUNCTION f_hra4010_class(TrnYm_IN      VARCHAR2
                       , EmpNo_IN      VARCHAR2
                       , SchDay_IN     VARCHAR2
                       , UpdateBy_IN   VARCHAR2) RETURN NUMBER IS

    sTrnYm        VARCHAR2(7)   := TrnYm_IN;
    sDay          VARCHAR2(2)   := trim(SchDay_IN);
    sEmpNo        VARCHAR2(20)  := EmpNo_IN;
    sClassCode    VARCHAR2(10)  := 'ZA' ;
    sUpdateBy     VARCHAR2(20) := UpdateBy_IN;

    BEGIN
       UPDATE hra_classsch
          SET sch_01 = decode(sDay, '01', sClassCode, sch_01)
            , sch_02 = decode(sDay, '02', sClassCode, sch_02)
            , sch_03 = decode(sDay, '03', sClassCode, sch_03)
            , sch_04 = decode(sDay, '04', sClassCode, sch_04)
            , sch_05 = decode(sDay, '05', sClassCode, sch_05)
            , sch_06 = decode(sDay, '06', sClassCode, sch_06)
            , sch_07 = decode(sDay, '07', sClassCode, sch_07)
            , sch_08 = decode(sDay, '08', sClassCode, sch_08)
            , sch_09 = decode(sDay, '09', sClassCode, sch_09)
            , sch_10 = decode(sDay, '10', sClassCode, sch_10)
            , sch_11 = decode(sDay, '11', sClassCode, sch_11)
            , sch_12 = decode(sDay, '12', sClassCode, sch_12)
            , sch_13 = decode(sDay, '13', sClassCode, sch_13)
            , sch_14 = decode(sDay, '14', sClassCode, sch_14)
            , sch_15 = decode(sDay, '15', sClassCode, sch_15)
            , sch_16 = decode(sDay, '16', sClassCode, sch_16)
            , sch_17 = decode(sDay, '17', sClassCode, sch_17)
            , sch_18 = decode(sDay, '18', sClassCode, sch_18)
            , sch_19 = decode(sDay, '19', sClassCode, sch_19)
            , sch_20 = decode(sDay, '20', sClassCode, sch_20)
            , sch_21 = decode(sDay, '21', sClassCode, sch_21)
            , sch_22 = decode(sDay, '22', sClassCode, sch_22)
            , sch_23 = decode(sDay, '23', sClassCode, sch_23)
            , sch_24 = decode(sDay, '24', sClassCode, sch_24)
            , sch_25 = decode(sDay, '25', sClassCode, sch_25)
            , sch_26 = decode(sDay, '26', sClassCode, sch_26)
            , sch_27 = decode(sDay, '27', sClassCode, sch_27)
            , sch_28 = decode(sDay, '28', sClassCode, sch_28)
            , sch_29 = decode(sDay, '29', sClassCode, sch_29)
            , sch_30 = decode(sDay, '30', sClassCode, sch_30)
            , sch_31 = decode(sDay, '31', sClassCode, sch_31)
            , last_updated_by  =  sUpdateBy
            , last_update_date = sysdate
        WHERE sch_ym = sTrnYm
          AND emp_no = sEmpNo ;


       RETURN 0 ;
    END f_hra4010_class ;
*/

  /***********************************
  曠職次數統計 wayne--
  多機構FOR 報表 By weichun
  ***********************************/
  /*FUNCTION f_hra4015_C(
                       EmpNo_IN      VARCHAR2,
                       StrartDate_IN DATE,
                       EndDate_IN    DATE,
                       Orgtype_IN    VARCHAR2) RETURN NUMBER IS


    sEmpNo      VARCHAR2(20) := EmpNo_IN;
    dStrartDate DATE         := StrartDate_IN;
    dEndDate    DATE         := EndDate_IN;
  	sOrganType VARCHAR2(10) := Orgtype_IN;
    nTotalAbs NUMBER;
    iCnt      INTEGER;
BEGIN

       BEGIN
          SELECT SUM(absence)  absence
            INTO nTotalAbs
            FROM (SELECT COUNT(*) absence
                    FROM hra_cardatt_view
                   WHERE (emp_no = sEmpNo)
                     AND (ORGAN_TYPE = sOrganType)
                     AND (att_date BETWEEN dStrartDate AND dEndDate)
                     AND (chkin = '5')
                  UNION
                  SELECT COUNT(*) absence
                    FROM hra_after_abnormal_view
                   WHERE trim(emp_no) = sEmpNo
                     AND (ORGAN_TYPE = sOrganType)
                     AND att_date BETWEEN dStrartDate AND dEndDate) ;
       EXCEPTION
       WHEN OTHERS THEN
            nTotalAbs := 0 ;
       END ;



    RETURN nTotalAbs;

  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK WORK;
      RETURN SQLCODE;
      NULL;

  END f_hra4015_C;*/

/*
--計算請假時數不足
--多機構修改為INSERT入TEMP TABLE後再做篩選,其中取得時數等功能仍須分離多機構帶入篩選
*/
--若有修改程式,f_set_hra9610temp_deptno須同步調整
FUNCTION f_set_hra9610temp_table(sStartDate VARCHAR2,
                                 sEndDate   VARCHAR2) RETURN NUMBER IS

    sEMP_NO     VARCHAR2(10);
    sSTART_DATE VARCHAR2(10);
    sEND_DATE   VARCHAR2(10);
    sSTART_TIME VARCHAR2(4);
    sEND_TIME   VARCHAR2(4);
    sVAC_DAYS   NUMBER;
    sVAC_HRS    NUMBER(3, 1);
    sOrganType  VARCHAR2(10);

    sEMP_NAME  VARCHAR2(200);
    sDEPT_NO   VARCHAR2(10);
    sDEPT_NAME VARCHAR2(60);

    sDayCnt    NUMBER;
    iClassCnt  NUMBER;
    iClassKind VARCHAR2(3);
    iWorkMin   NUMBER;

    sCHKIN_WKTM  VARCHAR2(4);
    sCHKOUT_WKTM VARCHAR2(4);
    sSTART_REST  VARCHAR2(4);
    sEND_REST    VARCHAR2(4);
    sWORK_HRS    VARCHAR2(4);
    sValidDate   DATE;

    iRealyWorkMin NUMBER;

    sCHKIN_CARD  VARCHAR2(4);
    sCHKOUT_CARD VARCHAR2(4);
    sNIGHT_FLAG  VARCHAR2(1);

    sVacMin NUMBER;
    iCnt    INTEGER;
    iCardSignCnt INTEGER;

    vSTART_DATE VARCHAR2(10);
    vEND_DATE   VARCHAR2(10);
    vSTART_TIME VARCHAR2(4);
    vEND_TIME   VARCHAR2(4);
    RtnCode     NUMBER;
   --itest       NUMBER :=0;
    Insufficient_time NUMBER;
    Insufficient_time_tmp NUMBER;
    late_flag VARCHAR2(1):='N';
    Insufficient_min NUMBER;
    late_time NUMBER;
    
    CURSOR cursor1 IS
      SELECT emp_no,
             TO_CHAR(start_date, 'yyyy-mm-dd') START_DATE,
             TO_CHAR(end_date, 'yyyy-mm-dd') END_DATE,START_TIME , END_TIME, ORG_BY
        FROM (SELECT emp_no, START_DATE, END_DATE,START_TIME , END_TIME, ORG_BY
                FROM hrp.HRA_EVCREC
               WHERE status = 'Y'
			   --and emp_no='109233' -- test
                 AND emp_no NOT IN
                     (SELECT EMP_NO
                        FROM HRP.HRE_PROFILE
                       WHERE ITEM_NO IN ('EMP01', 'EMP02'))
                       
              UNION ALL --20190115 108978 20180301無借休資料
              SELECT emp_no, START_DATE, END_DATE,START_TIME , END_TIME, ORG_BY
                FROM hrp.HRA_OFFREC
               WHERE status = 'Y'
                 AND emp_no NOT IN
                     (SELECT EMP_NO
                        FROM HRP.HRE_PROFILE
                       WHERE ITEM_NO IN ('EMP01', 'EMP02'))
                 AND item_type = 'O'
              UNION ALL
              SELECT emp_no, START_DATE, END_DATE,START_TIME , END_TIME, ORG_BY
                FROM hrp.HRA_SUPMST
               WHERE status = 'Y'
			    --and emp_no='109233'--test
                 AND emp_no NOT IN
                     (SELECT EMP_NO
                        FROM HRP.HRE_PROFILE
                       WHERE ITEM_NO IN ('EMP01', 'EMP02')))
     WHERE TO_CHAR(start_date, 'yyyy-mm-dd') BETWEEN sStartDate AND sEndDate
     --where to_char(start_date,'yyyy-mm-dd') = '2011-10-13' --test
/*     and emp_no = '101756'*/
       ;

    CURSOR cursor2(sEmpNo VARCHAR2, sValidDate DATE) IS
      SELECT TO_CHAR(START_DATE, 'YYYY-MM-DD'),
             START_TIME,
             TO_CHAR(END_DATE, 'YYYY-MM-DD'),
             END_TIME, ORG_BY
        FROM HRA_EVCREC
       WHERE EMP_NO = sEmpNo
         AND (TO_CHAR(sValidDate, 'YYYY-MM-DD') BETWEEN
             TO_CHAR(START_DATE, 'YYYY-MM-DD') AND
             TO_CHAR(END_DATE, 'YYYY-MM-DD'))
         AND STATUS = 'Y';

  BEGIN
    OPEN cursor1;
    LOOP
      FETCH cursor1
        INTO sEMP_NO, sSTART_DATE, sEND_DATE ,sSTART_TIME, sEND_TIME, sOrganType;
      EXIT WHEN cursor1%NOTFOUND;
     /*    TEST
      itest := itest +1;

      INSERT INTO HRP.HRE_EMP_TEST  (EMP_NO,I) VALUES  (sEMP_NO,itest);
      COMMIT;
      */
      -- EndDate - StartDate +1 => 要跑的迴圈次數
      sDayCnt := TO_DATE(sEND_DATE, 'yyyy-mm-dd') -
                 TO_DATE(sSTART_DATE, 'yyyy-mm-dd') + 1;

      IF sEND_TIME = '0000' THEN

       sDayCnt := sDayCnt -1;

      END IF;

      FOR i IN 1 .. sDayCnt LOOP
        late_flag :='N';
        iRealyWorkMin := 0;
        sValidDate    := TO_DATE(sSTART_DATE, 'yyyy-mm-dd') + i - 1;
        -- 班表
        iClassKind := Ehrphrafunc_Pkg.f_getClassKind(sEMP_NO, sValidDate,sOrganType);
/*        dbms_output.put_line('iClassKind'||iClassKind||sValidDate);*/
        -- 當日班別時段數,不含 OnCall

        SELECT COUNT(*)
          INTO iClassCnt
          FROM HRP.HRA_CLASSDTL
         WHERE CLASS_CODE = iClassKind
           AND SHIFT_NO <> 4;

        FOR j IN 1 .. iClassCnt LOOP

          -- 當日上班時段出勤
          SELECT CHKIN_WKTM, CHKOUT_WKTM, START_REST, END_REST
            INTO sCHKIN_WKTM, sCHKOUT_WKTM, sSTART_REST, sEND_REST
            FROM HRP.HRA_CLASSDTL
           WHERE CLASS_CODE = iClassKind
             AND SHIFT_NO = j;

          -- 當日上班

          BEGIN

            SELECT CHKIN_CARD, CHKOUT_CARD, NIGHT_FLAG
              INTO sCHKIN_CARD, sCHKOUT_CARD, sNIGHT_FLAG
              FROM HRP.HRA_CADSIGN
             WHERE EMP_NO = sEMP_NO
               AND TO_CHAR(ATT_DATE, 'YYYY-MM-DD') =
                   TO_CHAR(sValidDate, 'yyyy-mm-dd')
               AND SHIFT_NO = j
               AND ORG_BY = sOrganType;

          EXCEPTION
            WHEN NO_DATA_FOUND THEN

              sCHKIN_CARD  := NULL;
              sCHKOUT_CARD := NULL;
              sNIGHT_FLAG  := NULL;
          END;

          -- sCHKIN_CARD,sCHKOUT_CARD,sNIGHT_FLAG 有可能是 null , 必需考慮

          -- sCHKIN_CARD 打卡時間
          -- sCHKIN_WKTM 班別時間

          IF sCHKIN_CARD IS NOT NULL AND sCHKOUT_CARD IS NOT NULL THEN

            -- 上班
            IF sCHKIN_CARD <= sCHKIN_WKTM + 2 THEN

              sCHKIN_CARD := sCHKIN_WKTM;
            
            ELSE
              --跨夜班
              IF sCHKIN_WKTM BETWEEN '0000' AND '0800' THEN

                IF sCHKIN_CARD BETWEEN '1600' AND '2400' THEN

                  sCHKIN_CARD := sCHKIN_WKTM;

                END IF;

              END IF;

            END IF;
            
       
        --20180910 108978 增加記錄遲到註記
        --20260114 108482 2026年度開始遲到改30分鐘(含)內
          IF TO_CHAR(sValidDate, 'yyyy') <= '2025' THEN
            IF (sEND_TIME IS NOT NULL AND to_number(sCHKIN_CARD) <=to_number(sCHKIN_WKTM)+15 AND to_number(sCHKIN_CARD) > to_number(sCHKIN_WKTM)+2 )THEN
              late_flag :='Y';
            END IF;
          ELSE
            IF (sEND_TIME IS NOT NULL AND to_number(sCHKIN_CARD) <=to_number(sCHKIN_WKTM)+30 AND to_number(sCHKIN_CARD) > to_number(sCHKIN_WKTM)+2 )THEN
              late_flag :='Y';
            END IF;
          END IF;
            

            -- 下班
            IF sCHKOUT_CARD >= (CASE WHEN sCHKOUT_WKTM = '0000' THEN '2400' ELSE sCHKOUT_WKTM END ) THEN

              sCHKOUT_CARD := sCHKOUT_WKTM;

            ELSE

              IF ((sCHKOUT_CARD BETWEEN '1600' AND '2400') OR (sCHKOUT_CARD = '0000')) THEN
              /*IF ((sCHKOUT_WKTM BETWEEN '1600' AND '2400') OR (sCHKOUT_WKTM = '0000')) THEN*/

                IF sCHKOUT_CARD BETWEEN '0000' AND '0800' THEN

                  sCHKOUT_CARD := sCHKOUT_WKTM;

                END IF;

              END IF;

            END IF;

            iRealyWorkMin := iRealyWorkMin + Ehrphra12_Pkg.getoffhrs(TO_CHAR(sValidDate,'yyyy-mm-dd'), 
                                                                     sCHKIN_CARD,
                                                                     (CASE WHEN (sNIGHT_FLAG = 'Y' OR sCHKOUT_WKTM ='0800' /*RA*/) THEN TO_CHAR(sValidDate + 1, 'yyyy-mm-dd') ELSE TO_CHAR(sValidDate, 'yyyy-mm-dd') END),
                                                                     /*(CASE WHEN (sNIGHT_FLAG = 'Y' AND (sCHKIN_WKTM > sCHKOUT_WKTM)) THEN TO_CHAR(sValidDate + 1, 'yyyy-mm-dd') ELSE TO_CHAR(sValidDate, 'yyyy-mm-dd') END),*/
                                                                     sCHKOUT_CARD, 
                                                                     sEMP_NO,
                                                                     sOrganType);
          ELSE
           BEGIN

            SELECT COUNT(*)
              INTO iCardSignCnt
              FROM HRP.HRA_CADSIGN
             WHERE EMP_NO = sEMP_NO
               AND TO_CHAR(ATT_DATE, 'YYYY-MM-DD') =
                   TO_CHAR(sValidDate, 'yyyy-mm-dd')
               AND SHIFT_NO = 1
               AND ORG_BY = sOrganType;

          EXCEPTION
            WHEN NO_DATA_FOUND THEN
            iCardSignCnt := 0;
          END;
          
          IF(iCardSignCnt >0)THEN
            --增加判斷打卡異常的sCHKIN_CARD或sCHKOUT_CARD是 null,工作時數為應班工時/2,在算曠職的時候已經計算，所以在請假時數不足的時候不要在計算進去，避免扣兩次。 20181106 108978
            BEGIN
            SELECT WORK_HRS * 60
              INTO iWorkMin
              FROM HRP.HRA_CLASSMST
             WHERE CLASS_CODE = iClassKind;
            EXCEPTION
            WHEN OTHERS THEN
              iWorkMin := 0;
            END;
            iRealyWorkMin := iRealyWorkMin + (iWorkMin/2);
          END IF;
          
          END IF;

        END LOOP;

        -- 借休單

        BEGIN
          SELECT NVL(SUM(OTM_HRS) * 60, 0)
            INTO sVacMin
            FROM HRA_OFFREC
           WHERE EMP_NO = sEMP_NO
             AND TO_CHAR(sValidDate, 'YYYY-MM-DD') =
                 TO_CHAR(START_DATE, 'YYYY-MM-DD')
             AND STATUS = 'Y'
             AND item_type = 'O'
             AND ORG_BY = sOrganType;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            sVacMin := 0;
        END;

        iRealyWorkMin := iRealyWorkMin + sVacMin;

        --補休單
        BEGIN
          SELECT NVL(SUM(SUP_HRS) * 60, 0)
            INTO sVacMin
            FROM HRA_SUPMST
           WHERE EMP_NO = sEMP_NO
             AND TO_CHAR(sValidDate, 'YYYY-MM-DD') =
                 TO_CHAR(START_DATE, 'YYYY-MM-DD')
             AND STATUS = 'Y'
             AND ORG_BY = sOrganType;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            sVacMin := 0;
        END;

        iRealyWorkMin := iRealyWorkMin + sVacMin;

        -- 電子假卡 時數 -- 可 "跨天" 要注意
        -- 頭尾 注意 即可!!
        BEGIN
          SELECT COUNT(*)
            INTO iCnt
            FROM HRA_EVCREC
           WHERE EMP_NO = sEMP_NO
             AND (TO_CHAR(sValidDate, 'YYYY-MM-DD') BETWEEN
                 TO_CHAR(START_DATE, 'YYYY-MM-DD') AND
                 TO_CHAR(END_DATE, 'YYYY-MM-DD')) -- sphinx  94.09.28
             AND STATUS = 'Y'
             AND ORG_BY = sOrganType;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            iCnt := 0;
        END;

        IF iCnt > 0 THEN
          OPEN cursor2(sEMP_NO, sValidDate);
          LOOP
            FETCH cursor2
              INTO vSTART_DATE, vSTART_TIME, vEND_DATE, vEND_TIME, sOrganType;
            EXIT WHEN cursor2%NOTFOUND;

            IF TO_CHAR(sValidDate, 'yyyy-mm-dd') = vSTART_DATE
             OR( TO_CHAR(sValidDate + 1, 'yyyy-mm-dd') = vEND_DATE AND vEND_TIME = '0000' ) --JB班的結算時間判斷
            THEN

              BEGIN
              SELECT CHKIN_WKTM,
                     CHKOUT_WKTM,
                     START_REST,
                     END_REST,
                     (SELECT WORK_HRS
                        FROM HRP.HRA_CLASSMST
                       WHERE CLASS_CODE = T1.CLASS_CODE) WORK_HRS
                INTO sCHKIN_WKTM,
                     sCHKOUT_WKTM,
                     sSTART_REST,
                     sEND_REST,
                     sWORK_HRS
                FROM HRP.HRA_CLASSDTL T1
               WHERE CLASS_CODE = iClassKind
                 AND SHIFT_NO = (SELECT MAX(SHIFT_NO)
                                   FROM HRP.HRA_CLASSDTL
                                  WHERE CLASS_CODE = iClassKind  AND SHIFT_NO <> '4');
              EXCEPTION
                WHEN OTHERS THEN
                NULL;
              END;
              
              --請假是同一天
              IF vSTART_DATE = vEND_DATE THEN
                vEND_TIME := vEND_TIME;
              ELSE
              --結束時間為班表時間
                vEND_TIME := sCHKOUT_WKTM;
              END IF;
              
              --JB班休假多天，最後一天檢核開始時間抓班表開始時間 20210901 by108482
              IF (TO_CHAR(sValidDate + 1, 'yyyy-mm-dd') = vEND_DATE AND vEND_TIME = '0000') AND
                 TO_CHAR(sValidDate, 'yyyy-mm-dd') <> vSTART_DATE THEN
                vSTART_TIME := sCHKIN_WKTM;
              END IF;

              --開始時間需判斷，取整點
              /*IF SUBSTR(vSTART_TIME,3,4) BETWEEN '00' AND '29' THEN
              vSTART_TIME := SUBSTR(vSTART_TIME,1,2) || '00';
              ELSIF SUBSTR(vSTART_TIME,3,4) BETWEEN '30' AND '59' THEN
              vSTART_TIME := SUBSTR(vSTART_TIME,1,2) || '30';
              END IF;*/
              --20231108 by108482 調整開始時間應往後判斷整點 EX:1333應認定為1400
              IF SUBSTR(vSTART_TIME,3,4) BETWEEN '01' AND '29' THEN
                vSTART_TIME := SUBSTR(vSTART_TIME,1,2) || '30';
              ELSIF SUBSTR(vSTART_TIME,3,4) BETWEEN '31' AND '59' THEN
                vSTART_TIME := to_number(SUBSTR(vSTART_TIME,1,2))+1 || '00';
              END IF;
              
              --結束時間需判斷，取整點(因假卡是半小時為單位,避免誤算曠職) 20210629 by108482
              /*IF SUBSTR(vEND_TIME,3,4) BETWEEN '01' AND '29' THEN
                vEND_TIME := SUBSTR(vEND_TIME,1,2) || '30';
              ELSIF SUBSTR(vEND_TIME,3,4) BETWEEN '31' AND '59' THEN
                vEND_TIME := to_number(SUBSTR(vEND_TIME,1,2))+1 || '00';
              END IF;*/
              --20240409 by108482 調整結束時間應往前判斷整點 EX:2359應認定為2330
              IF SUBSTR(vEND_TIME,3,4) BETWEEN '01' AND '29' THEN
                vEND_TIME := SUBSTR(vEND_TIME,1,2) || '00';
              ELSIF SUBSTR(vEND_TIME,3,4) BETWEEN '31' AND '59' THEN
                vEND_TIME := SUBSTR(vEND_TIME,1,2) || '30';
              END IF;
              
              IF vEND_TIME = '2400' THEN 
                vEND_TIME := '0000';
                vEND_DATE := to_char(to_date(vEND_DATE,'yyyy/mm/dd')+1, 'yyyy-mm-dd');
              END IF;
              IF LENGTH(vSTART_TIME) = 3 THEN
                vSTART_TIME := '0'||vSTART_TIME;
              END IF;
              IF LENGTH(vEND_TIME) = 3 THEN
                vEND_TIME := '0'||vEND_TIME;
              END IF;

             --JB班的工時判斷
             IF TO_CHAR(sValidDate + 1, 'yyyy-mm-dd') <= vEND_DATE AND vEND_TIME = '0000' THEN

              iRealyWorkMin := iRealyWorkMin +
                               Ehrphra12_Pkg.getoffhrs(TO_CHAR(sValidDate,
                                                               'yyyy-mm-dd'),
                                                       vSTART_TIME,
                                                       TO_CHAR(sValidDate+1,
                                                               'yyyy-mm-dd'),
                                                       vEND_TIME,
                                                       sEMP_NO,sOrganType);
             --20180430 108978 增加判斷有跨天的時候結束時間大於0000 ，如NK(1/1 2100- 1/2 0700)
             ELSIF TO_CHAR(sValidDate+1 , 'yyyy-mm-dd') <= vEND_DATE AND vEND_TIME >= '0000' THEN
              iRealyWorkMin := iRealyWorkMin +              
                               Ehrphra12_Pkg.getoffhrs(TO_CHAR(sValidDate,
                                                               'yyyy-mm-dd'),
                                                       vSTART_TIME,
                                                       TO_CHAR(sValidDate+1,
                                                               'yyyy-mm-dd'),
                                                       vEND_TIME,
                                                       sEMP_NO,sOrganType);  
             ELSE
              iRealyWorkMin := iRealyWorkMin +
                               Ehrphra12_Pkg.getoffhrs(TO_CHAR(sValidDate,
                                                               'yyyy-mm-dd'),
                                                       vSTART_TIME,
                                                       TO_CHAR(sValidDate,
                                                               'yyyy-mm-dd'),
                                                       vEND_TIME,
                                                       sEMP_NO,sOrganType);
             END IF;

              -- 請假起時 ~ 班表下班時

            ELSIF TO_CHAR(sValidDate, 'yyyy-mm-dd') = vEND_DATE THEN
              BEGIN
              SELECT CHKIN_WKTM,
                     CHKOUT_WKTM,
                     START_REST,
                     END_REST,
                     (SELECT WORK_HRS
                        FROM HRP.HRA_CLASSMST
                       WHERE CLASS_CODE = T1.CLASS_CODE) WORK_HRS
                INTO sCHKIN_WKTM,
                     sCHKOUT_WKTM,
                     sSTART_REST,
                     sEND_REST,
                     sWORK_HRS
                FROM HRP.HRA_CLASSDTL T1
               WHERE CLASS_CODE = iClassKind
                 AND SHIFT_NO = (SELECT MIN(SHIFT_NO)
                                   FROM HRP.HRA_CLASSDTL
                                  WHERE CLASS_CODE = iClassKind  AND SHIFT_NO <> '4')
                 ;
              EXCEPTION
                WHEN OTHERS THEN
                NULL;
              END;

              vSTART_TIME   := sCHKIN_WKTM;
              iRealyWorkMin := iRealyWorkMin +
                               Ehrphra12_Pkg.getoffhrs(TO_CHAR(sValidDate,
                                                               'yyyy-mm-dd'),
                                                       vSTART_TIME,
                                                       TO_CHAR(sValidDate,
                                                               'yyyy-mm-dd'),
                                                       vEND_TIME,
                                                       sEMP_NO,sOrganType);

              --班表上班日 ~ 請假迄時

            ELSE
              BEGIN
              SELECT CHKIN_WKTM,
                     CHKOUT_WKTM,
                     START_REST,
                     END_REST,
                     (SELECT WORK_HRS
                        FROM HRP.HRA_CLASSMST
                       WHERE CLASS_CODE = T1.CLASS_CODE) WORK_HRS
                INTO sCHKIN_WKTM,
                     sCHKOUT_WKTM,
                     sSTART_REST,
                     sEND_REST,
                     sWORK_HRS
                FROM HRP.HRA_CLASSDTL T1
               WHERE CLASS_CODE = iClassKind
                 AND SHIFT_NO = (SELECT MIN(SHIFT_NO)
                                   FROM HRP.HRA_CLASSDTL
                                  WHERE CLASS_CODE = iClassKind  AND SHIFT_NO <> '4')
                ;
              EXCEPTION
                WHEN OTHERS THEN
                NULL;
              END;

              iRealyWorkMin := iRealyWorkMin + sWORK_HRS * 60;

            END IF;

          END LOOP;
          CLOSE cursor2;
        END IF;
    --  dbms_output.put_line('------->' || iClassKind || sEMP_NO);
        -- 應上班分鐘
        BEGIN
        SELECT WORK_HRS * 60
          INTO iWorkMin
          FROM HRP.HRA_CLASSMST
         WHERE CLASS_CODE = iClassKind;
        EXCEPTION
        WHEN OTHERS THEN
                iWorkMin := 0;
        END;
        
        --20200115 by108482 ZA班工時歸零
        IF iClassKind = 'ZA' THEN
          iWorkMin := 0;
        END IF;

        -- 應出勤時間是否小於等於 總上班時間(出勤+假單)
        IF iWorkMin > iRealyWorkMin THEN
          Insufficient_min := iWorkMin - iRealyWorkMin;
          Insufficient_time := iWorkMin - iRealyWorkMin;        
          Insufficient_time_tmp := Insufficient_time - trunc(Insufficient_time/60)*60;
          Insufficient_time := trunc(Insufficient_time/60);
          --曠職時數最小單位為0.5小時 108978
          IF (Insufficient_time_tmp =0) THEN
            Insufficient_time_tmp :=0;
          ELSIF (Insufficient_time_tmp <=30) THEN
            Insufficient_time_tmp :=0.5;
          ELSE
            Insufficient_time_tmp :=1;
          END IF;
          Insufficient_time := Insufficient_time + Insufficient_time_tmp;
          IF late_flag = 'Y' THEN
            late_time := sCHKIN_CARD - sCHKIN_WKTM;
          ELSE
            late_time := 0;
          END IF;
          SELECT CH_NAME, (SELECT CH_NAME FROM HRE_ORGBAS WHERE DEPT_NO = t1.DEPT_NO AND ORGAN_TYPE = t1.ORGAN_TYPE) DEPT_NAME,
           DEPT_NO
            INTO sEMP_NAME, sDEPT_NAME, sDEPT_NO
            FROM HRE_EMPBAS t1
           WHERE EMP_NO = sEMP_NO;
        --     AND ORGAN_TYPE = sOrganType;
        --201908 by108482 時數不足超過0.5小時且有遲到者改註記Z,避免曠職未計算到
        IF Insufficient_time > 0.5 AND late_flag = 'Y' THEN
          late_flag := 'Z';
        END IF;
        Insufficient_min := Insufficient_min - late_time;
        IF Insufficient_min < 0 THEN
          Insufficient_min := 0;
        END IF;
        IF (TO_CHAR(sValidDate, 'YYYYMMDD') < TO_CHAR(SYSDATE, 'YYYYMMDD')) THEN
        BEGIN
          --排除100812 跨天請假且結束時間0000 之資料
          --IF (sEMP_NO = '101029' AND TO_CHAR(sValidDate, 'YYYY-MM-DD') = '2011-10-13') THEN
          --  NULL;
          --ELSE
          --排除2024-07-25颱風假資料 IF TO_CHAR(sValidDate, 'YYYY-MM-DD') IN ('2024-07-25','2024-07-26') THEN
          --排除2024-10-02,2024-10-03,2024-10-04,2024-10-31颱風假資料 IF TO_CHAR(sValidDate, 'YYYY-MM-DD') IN ('2024-10-02','2024-10-03','2024-10-04','2024-10-31') THEN
          --排除2025-07-29颱風(豪雨)假資料, 2025-08-13颱風部分資料
          IF TO_CHAR(sValidDate, 'YYYY-MM-DD') IN ('2025-07-29') THEN
            NULL;
          ELSIF TO_CHAR(sValidDate, 'YYYY-MM-DD') IN ('2025-08-13') AND sEMP_NO = '103725' THEN
            NULL;
          ELSIF TO_CHAR(sValidDate, 'YYYY-MM-DD') IN ('2025-01-15') AND sEMP_NO = '114425' THEN
            NULL;
          ELSIF TO_CHAR(sValidDate, 'YYYY-MM-DD') IN ('2025-05-20') AND sEMP_NO = '115083' THEN
            NULL;
          ELSE
          INSERT INTO HRA_9610_TEMP
            (EMP_NO, EMP_NAME, DEPT_NO, DEPT_NAME, VAC_DATE, ORGAN_TYPE, INSUFFICIENT_TIME, LATE_FLAG, 
             INSUFFICIENT_MIN, LATE_MINUTE, CHKIN_CARD, CHKOUT_CARD, CHKIN_REAL, CHKOUT_REAL, START_TIME_S, END_TIME_S)
          VALUES
            (sEMP_NO,
             sEMP_NAME,
             sDEPT_NO,
             sDEPT_NAME,
             TO_CHAR(sValidDate, 'YYYY-MM-DD'),
             sOrganType,
             Insufficient_time,
             late_flag,
             Insufficient_min,
             late_time,
             sCHKIN_CARD,
             sCHKOUT_CARD,
             sCHKIN_WKTM,
             sCHKOUT_WKTM,
             sSTART_REST,
             sEND_REST);
          END IF;
        EXCEPTION
          WHEN OTHERS THEN
          RtnCode := 0;
        END;
        END IF;
       
        END IF;

      END LOOP;

    END LOOP;
    CLOSE cursor1;
    RtnCode := 0;
    RETURN RtnCode;
    NULL;
    <<Continue_ForEach2>>
    NULL;

  END f_set_hra9610temp_table;
  
  FUNCTION f_set_hra9610temp_deptno(sStartDate VARCHAR2,
                                    sEndDate   VARCHAR2,
                                    sDeptNo    VARCHAR2) RETURN NUMBER IS

    sEMP_NO     VARCHAR2(10);
    sSTART_DATE VARCHAR2(10);
    sEND_DATE   VARCHAR2(10);
    sSTART_TIME VARCHAR2(4);
    sEND_TIME   VARCHAR2(4);
    sVAC_DAYS   NUMBER;
    sVAC_HRS    NUMBER(3, 1);
    sOrganType  VARCHAR2(10);

    sEMP_NAME  VARCHAR2(200);
    sDEPT_NO   VARCHAR2(10);
    sDEPT_NAME VARCHAR2(60);

    sDayCnt    NUMBER;
    iClassCnt  NUMBER;
    iClassKind VARCHAR2(3);
    iWorkMin   NUMBER;

    sCHKIN_WKTM  VARCHAR2(4);
    sCHKOUT_WKTM VARCHAR2(4);
    sSTART_REST  VARCHAR2(4);
    sEND_REST    VARCHAR2(4);
    sWORK_HRS    VARCHAR2(4);
    sValidDate   DATE;

    iRealyWorkMin NUMBER;

    sCHKIN_CARD  VARCHAR2(4);
    sCHKOUT_CARD VARCHAR2(4);
    sNIGHT_FLAG  VARCHAR2(1);

    sVacMin NUMBER;
    iCnt    INTEGER;
    iCardSignCnt INTEGER;

    vSTART_DATE VARCHAR2(10);
    vEND_DATE   VARCHAR2(10);
    vSTART_TIME VARCHAR2(4);
    vEND_TIME   VARCHAR2(4);
    RtnCode     NUMBER;
   --itest       NUMBER :=0;
    Insufficient_time NUMBER;
    Insufficient_time_tmp NUMBER;
    late_flag VARCHAR2(1):='N';
    CURSOR cursor1 IS

      SELECT emp_no,
             TO_CHAR(start_date, 'yyyy-mm-dd') START_DATE,
             TO_CHAR(end_date, 'yyyy-mm-dd') END_DATE,START_TIME , END_TIME, ORG_BY
        FROM (SELECT emp_no, START_DATE, END_DATE,START_TIME , END_TIME, ORG_BY
                FROM hrp.HRA_EVCREC
               WHERE status = 'Y'
                 AND emp_no NOT IN
                     (SELECT EMP_NO
                        FROM HRP.HRE_PROFILE
                       WHERE ITEM_NO IN ('EMP01', 'EMP02'))
                 AND dept_no = sDeptNo
              UNION ALL --20190115 108978 20180301無借休資料
              SELECT emp_no, START_DATE, END_DATE,START_TIME , END_TIME, ORG_BY
                FROM hrp.HRA_OFFREC
               WHERE status = 'Y'
                 AND emp_no NOT IN
                     (SELECT EMP_NO
                        FROM HRP.HRE_PROFILE
                       WHERE ITEM_NO IN ('EMP01', 'EMP02'))
                 AND item_type = 'O'
                 AND dept_no = sDeptNo
              UNION ALL
              SELECT emp_no, START_DATE, END_DATE,START_TIME , END_TIME, ORG_BY
                FROM hrp.HRA_SUPMST
               WHERE status = 'Y'
                 AND emp_no NOT IN
                     (SELECT EMP_NO
                        FROM HRP.HRE_PROFILE
                       WHERE ITEM_NO IN ('EMP01', 'EMP02'))
                 AND dept_no = sDeptNo)
     WHERE TO_CHAR(start_date, 'yyyy-mm-dd') BETWEEN sStartDate AND sEndDate;

    CURSOR cursor2(sEmpNo VARCHAR2, sValidDate DATE) IS
      SELECT TO_CHAR(START_DATE, 'YYYY-MM-DD'),
             START_TIME,
             TO_CHAR(END_DATE, 'YYYY-MM-DD'),
             END_TIME, ORG_BY
        FROM HRA_EVCREC
       WHERE EMP_NO = sEmpNo
         AND (TO_CHAR(sValidDate, 'YYYY-MM-DD') BETWEEN
             TO_CHAR(START_DATE, 'YYYY-MM-DD') AND
             TO_CHAR(END_DATE, 'YYYY-MM-DD'))
         AND STATUS = 'Y';

  BEGIN
    OPEN cursor1;
    LOOP
      FETCH cursor1
        INTO sEMP_NO, sSTART_DATE, sEND_DATE ,sSTART_TIME, sEND_TIME, sOrganType;
      EXIT WHEN cursor1%NOTFOUND;
     /*    TEST
      itest := itest +1;

      INSERT INTO HRP.HRE_EMP_TEST  (EMP_NO,I) VALUES  (sEMP_NO,itest);
      COMMIT;
      */
      -- EndDate - StartDate +1 => 要跑的迴圈次數
      sDayCnt := TO_DATE(sEND_DATE, 'yyyy-mm-dd') -
                 TO_DATE(sSTART_DATE, 'yyyy-mm-dd') + 1;

      IF sEND_TIME = '0000' THEN

       sDayCnt := sDayCnt -1;

      END IF;

      FOR i IN 1 .. sDayCnt LOOP
        late_flag :='N';
        iRealyWorkMin := 0;
        sValidDate    := TO_DATE(sSTART_DATE, 'yyyy-mm-dd') + i - 1;
        -- 班表
        iClassKind := Ehrphrafunc_Pkg.f_getClassKind(sEMP_NO, sValidDate,sOrganType);
/*        dbms_output.put_line('iClassKind'||iClassKind||sValidDate);*/
        -- 當日班別時段數,不含 OnCall

        SELECT COUNT(*)
          INTO iClassCnt
          FROM HRP.HRA_CLASSDTL
         WHERE CLASS_CODE = iClassKind
           AND SHIFT_NO <> 4;

        FOR j IN 1 .. iClassCnt LOOP

          -- 當日上班時段出勤
          SELECT CHKIN_WKTM, CHKOUT_WKTM, START_REST, END_REST
            INTO sCHKIN_WKTM, sCHKOUT_WKTM, sSTART_REST, sEND_REST
            FROM HRP.HRA_CLASSDTL
           WHERE CLASS_CODE = iClassKind
             AND SHIFT_NO = j;

          -- 當日上班

          BEGIN

            SELECT CHKIN_CARD, CHKOUT_CARD, NIGHT_FLAG
              INTO sCHKIN_CARD, sCHKOUT_CARD, sNIGHT_FLAG
              FROM HRP.HRA_CADSIGN
             WHERE EMP_NO = sEMP_NO
               AND TO_CHAR(ATT_DATE, 'YYYY-MM-DD') =
                   TO_CHAR(sValidDate, 'yyyy-mm-dd')
               AND SHIFT_NO = j
               AND ORG_BY = sOrganType;

          EXCEPTION
            WHEN NO_DATA_FOUND THEN

              sCHKIN_CARD  := NULL;
              sCHKOUT_CARD := NULL;
              sNIGHT_FLAG  := NULL;
          END;

          -- sCHKIN_CARD,sCHKOUT_CARD,sNIGHT_FLAG 有可能是 null , 必需考慮

          -- sCHKIN_CARD 打卡時間
          -- sCHKIN_WKTM 班別時間

          IF sCHKIN_CARD IS NOT NULL AND sCHKOUT_CARD IS NOT NULL THEN

            -- 上班
            IF sCHKIN_CARD <= sCHKIN_WKTM + 2 THEN

              sCHKIN_CARD := sCHKIN_WKTM;
            
            ELSE
              --跨夜班
              IF sCHKIN_WKTM BETWEEN '0000' AND '0800' THEN

                IF sCHKIN_CARD BETWEEN '1600' AND '2400' THEN

                  sCHKIN_CARD := sCHKIN_WKTM;

                END IF;

              END IF;

            END IF;
            
       
        --20180910 108978 增加記錄遲到註記                           
        --20260114 108482 2026年度開始遲到改30分鐘(含)內
          IF TO_CHAR(sValidDate, 'yyyy') <= '2025' THEN
            IF (sEND_TIME IS NOT NULL AND to_number(sCHKIN_CARD) <=to_number(sCHKIN_WKTM)+15 AND to_number(sCHKIN_CARD) > to_number(sCHKIN_WKTM)+2 )THEN
              late_flag :='Y';
            END IF;
          ELSE
            IF (sEND_TIME IS NOT NULL AND to_number(sCHKIN_CARD) <=to_number(sCHKIN_WKTM)+30 AND to_number(sCHKIN_CARD) > to_number(sCHKIN_WKTM)+2 )THEN
              late_flag :='Y';
            END IF;
          END IF;
            

            -- 下班
            IF sCHKOUT_CARD >= (CASE WHEN sCHKOUT_WKTM = '0000' THEN '2400' ELSE sCHKOUT_WKTM END ) THEN

              sCHKOUT_CARD := sCHKOUT_WKTM;

            ELSE

              IF ((sCHKOUT_CARD BETWEEN '1600' AND '2400') OR (sCHKOUT_CARD = '0000')) THEN
              /*IF ((sCHKOUT_WKTM BETWEEN '1600' AND '2400') OR (sCHKOUT_WKTM = '0000')) THEN*/

                IF sCHKOUT_CARD BETWEEN '0000' AND '0800' THEN

                  sCHKOUT_CARD := sCHKOUT_WKTM;

                END IF;

              END IF;

            END IF;

            iRealyWorkMin := iRealyWorkMin + Ehrphra12_Pkg.getoffhrs(TO_CHAR(sValidDate,'yyyy-mm-dd'), 
                                                                     sCHKIN_CARD,
                                                                     (CASE WHEN (sNIGHT_FLAG = 'Y' OR sCHKOUT_WKTM ='0800' /*RA*/) THEN TO_CHAR(sValidDate + 1, 'yyyy-mm-dd') ELSE TO_CHAR(sValidDate, 'yyyy-mm-dd') END),
                                                                     /*(CASE WHEN (sNIGHT_FLAG = 'Y' AND (sCHKIN_WKTM > sCHKOUT_WKTM)) THEN TO_CHAR(sValidDate + 1, 'yyyy-mm-dd') ELSE TO_CHAR(sValidDate, 'yyyy-mm-dd') END),*/
                                                                     sCHKOUT_CARD, 
                                                                     sEMP_NO,
                                                                     sOrganType);
          ELSE
           BEGIN

            SELECT COUNT(*)
              INTO iCardSignCnt
              FROM HRP.HRA_CADSIGN
             WHERE EMP_NO = sEMP_NO
               AND TO_CHAR(ATT_DATE, 'YYYY-MM-DD') =
                   TO_CHAR(sValidDate, 'yyyy-mm-dd')
               AND SHIFT_NO = 1
               AND ORG_BY = sOrganType;

          EXCEPTION
            WHEN NO_DATA_FOUND THEN
            iCardSignCnt := 0;
          END;
          
          IF(iCardSignCnt >0)THEN
            --增加判斷打卡異常的sCHKIN_CARD或sCHKOUT_CARD是 null,工作時數為應班工時/2,在算曠職的時候已經計算，所以在請假時數不足的時候不要在計算進去，避免扣兩次。 20181106 108978
            BEGIN
            SELECT WORK_HRS * 60
              INTO iWorkMin
              FROM HRP.HRA_CLASSMST
             WHERE CLASS_CODE = iClassKind;
            EXCEPTION
            WHEN OTHERS THEN
              iWorkMin := 0;
            END;
            iRealyWorkMin := iRealyWorkMin + (iWorkMin/2);
          END IF;
          
          END IF;

        END LOOP;

        -- 借休單

        BEGIN
          SELECT NVL(SUM(OTM_HRS) * 60, 0)
            INTO sVacMin
            FROM HRA_OFFREC
           WHERE EMP_NO = sEMP_NO
             AND TO_CHAR(sValidDate, 'YYYY-MM-DD') =
                 TO_CHAR(START_DATE, 'YYYY-MM-DD')
             AND STATUS = 'Y'
             AND item_type = 'O'
             AND ORG_BY = sOrganType;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            sVacMin := 0;
        END;

        iRealyWorkMin := iRealyWorkMin + sVacMin;

        --補休單
        BEGIN
          SELECT NVL(SUM(SUP_HRS) * 60, 0)
            INTO sVacMin
            FROM HRA_SUPMST
           WHERE EMP_NO = sEMP_NO
             AND TO_CHAR(sValidDate, 'YYYY-MM-DD') =
                 TO_CHAR(START_DATE, 'YYYY-MM-DD')
             AND STATUS = 'Y'
             AND ORG_BY = sOrganType;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            sVacMin := 0;
        END;

        iRealyWorkMin := iRealyWorkMin + sVacMin;

        -- 電子假卡 時數 -- 可 "跨天" 要注意
        -- 頭尾 注意 即可!!
        BEGIN
          SELECT COUNT(*)
            INTO iCnt
            FROM HRA_EVCREC
           WHERE EMP_NO = sEMP_NO
             AND (TO_CHAR(sValidDate, 'YYYY-MM-DD') BETWEEN
                 TO_CHAR(START_DATE, 'YYYY-MM-DD') AND
                 TO_CHAR(END_DATE, 'YYYY-MM-DD')) -- sphinx  94.09.28
             AND STATUS = 'Y'
             AND ORG_BY = sOrganType;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            iCnt := 0;
        END;

        IF iCnt > 0 THEN
          OPEN cursor2(sEMP_NO, sValidDate);
          LOOP
            FETCH cursor2
              INTO vSTART_DATE, vSTART_TIME, vEND_DATE, vEND_TIME, sOrganType;
            EXIT WHEN cursor2%NOTFOUND;

            IF TO_CHAR(sValidDate, 'yyyy-mm-dd') = vSTART_DATE
             OR( TO_CHAR(sValidDate + 1, 'yyyy-mm-dd') = vEND_DATE AND vEND_TIME = '0000' ) --JB班的結算時間判斷
            THEN

              BEGIN
              SELECT CHKIN_WKTM,
                     CHKOUT_WKTM,
                     START_REST,
                     END_REST,
                     (SELECT WORK_HRS
                        FROM HRP.HRA_CLASSMST
                       WHERE CLASS_CODE = T1.CLASS_CODE) WORK_HRS
                INTO sCHKIN_WKTM,
                     sCHKOUT_WKTM,
                     sSTART_REST,
                     sEND_REST,
                     sWORK_HRS
                FROM HRP.HRA_CLASSDTL T1
               WHERE CLASS_CODE = iClassKind
                 AND SHIFT_NO = (SELECT MAX(SHIFT_NO)
                                   FROM HRP.HRA_CLASSDTL
                                  WHERE CLASS_CODE = iClassKind  AND SHIFT_NO <> '4');
              EXCEPTION
                WHEN OTHERS THEN
                NULL;
              END;
              
              --請假是同一天
              IF vSTART_DATE = vEND_DATE THEN
              vEND_TIME     := vEND_TIME;
              ELSE
              --結束時間為班表時間
              vEND_TIME  := sCHKOUT_WKTM;
              END IF;
              
              --JB班休假多天，最後一天檢核開始時間抓班表開始時間 20210901 by108482
              IF (TO_CHAR(sValidDate + 1, 'yyyy-mm-dd') = vEND_DATE AND vEND_TIME = '0000') AND
                 TO_CHAR(sValidDate, 'yyyy-mm-dd') <> vSTART_DATE THEN
                vSTART_TIME := sCHKIN_WKTM;
              END IF;

              --開始時間需判斷，取整點
              /*IF SUBSTR(vSTART_TIME,3,4) BETWEEN '00' AND '29' THEN
              vSTART_TIME := SUBSTR(vSTART_TIME,1,2) || '00';
              ELSIF SUBSTR(vSTART_TIME,3,4) BETWEEN '30' AND '59' THEN
              vSTART_TIME := SUBSTR(vSTART_TIME,1,2) || '30';
              END IF;*/
              --20231108 by108482 調整開始時間應往後判斷整點 EX:1333應認定為1400
              IF SUBSTR(vSTART_TIME,3,4) BETWEEN '01' AND '29' THEN
                vSTART_TIME := SUBSTR(vSTART_TIME,1,2) || '30';
              ELSIF SUBSTR(vSTART_TIME,3,4) BETWEEN '31' AND '59' THEN
                vSTART_TIME := to_number(SUBSTR(vSTART_TIME,1,2))+1 || '00';
              END IF;
              
              --結束時間需判斷，取整點(因假卡是半小時為單位,避免誤算曠職) 20210629 by108482
              /*IF SUBSTR(vEND_TIME,3,4) BETWEEN '01' AND '29' THEN
                vEND_TIME := SUBSTR(vEND_TIME,1,2) || '30';
              ELSIF SUBSTR(vEND_TIME,3,4) BETWEEN '31' AND '59' THEN
                vEND_TIME := to_number(SUBSTR(vEND_TIME,1,2))+1 || '00';
              END IF;*/
              --20240409 by108482 調整結束時間應往前判斷整點 EX:2359應認定為2330
              IF SUBSTR(vEND_TIME,3,4) BETWEEN '01' AND '29' THEN
                vEND_TIME := SUBSTR(vEND_TIME,1,2) || '00';
              ELSIF SUBSTR(vEND_TIME,3,4) BETWEEN '31' AND '59' THEN
                vEND_TIME := SUBSTR(vEND_TIME,1,2) || '30';
              END IF;
              
              IF vEND_TIME = '2400' THEN 
                vEND_TIME := '0000';
                vEND_DATE := to_char(to_date(vEND_DATE,'yyyy/mm/dd')+1, 'yyyy-mm-dd');
              END IF;
              IF LENGTH(vSTART_TIME) = 3 THEN
                vSTART_TIME := '0'||vSTART_TIME;
              END IF;
              IF LENGTH(vEND_TIME) = 3 THEN
                vEND_TIME := '0'||vEND_TIME;
              END IF;

             --JB班的工時判斷
             IF TO_CHAR(sValidDate + 1, 'yyyy-mm-dd') <= vEND_DATE AND vEND_TIME = '0000' THEN

              iRealyWorkMin := iRealyWorkMin +
                               Ehrphra12_Pkg.getoffhrs(TO_CHAR(sValidDate,
                                                               'yyyy-mm-dd'),
                                                       vSTART_TIME,
                                                       TO_CHAR(sValidDate+1,
                                                               'yyyy-mm-dd'),
                                                       vEND_TIME,
                                                       sEMP_NO,sOrganType);
             --20180430 108978 增加判斷有跨天的時候結束時間大於0000 ，如NK(1/1 2100- 1/2 0700)
             ELSIF TO_CHAR(sValidDate+1 , 'yyyy-mm-dd') <= vEND_DATE AND vEND_TIME >= '0000' THEN
              iRealyWorkMin := iRealyWorkMin +              
                               Ehrphra12_Pkg.getoffhrs(TO_CHAR(sValidDate,
                                                               'yyyy-mm-dd'),
                                                       vSTART_TIME,
                                                       TO_CHAR(sValidDate+1,
                                                               'yyyy-mm-dd'),
                                                       vEND_TIME,
                                                       sEMP_NO,sOrganType);  
             ELSE
              iRealyWorkMin := iRealyWorkMin +
                               Ehrphra12_Pkg.getoffhrs(TO_CHAR(sValidDate,
                                                               'yyyy-mm-dd'),
                                                       vSTART_TIME,
                                                       TO_CHAR(sValidDate,
                                                               'yyyy-mm-dd'),
                                                       vEND_TIME,
                                                       sEMP_NO,sOrganType);
             END IF;

              -- 請假起時 ~ 班表下班時

            ELSIF TO_CHAR(sValidDate, 'yyyy-mm-dd') = vEND_DATE THEN
              BEGIN
              SELECT CHKIN_WKTM,
                     CHKOUT_WKTM,
                     START_REST,
                     END_REST,
                     (SELECT WORK_HRS
                        FROM HRP.HRA_CLASSMST
                       WHERE CLASS_CODE = T1.CLASS_CODE) WORK_HRS
                INTO sCHKIN_WKTM,
                     sCHKOUT_WKTM,
                     sSTART_REST,
                     sEND_REST,
                     sWORK_HRS
                FROM HRP.HRA_CLASSDTL T1
               WHERE CLASS_CODE = iClassKind
                 AND SHIFT_NO = (SELECT MIN(SHIFT_NO)
                                   FROM HRP.HRA_CLASSDTL
                                  WHERE CLASS_CODE = iClassKind  AND SHIFT_NO <> '4')
                 ;
              EXCEPTION
                WHEN OTHERS THEN
                NULL;
              END;

              vSTART_TIME   := sCHKIN_WKTM;
              iRealyWorkMin := iRealyWorkMin +
                               Ehrphra12_Pkg.getoffhrs(TO_CHAR(sValidDate,
                                                               'yyyy-mm-dd'),
                                                       vSTART_TIME,
                                                       TO_CHAR(sValidDate,
                                                               'yyyy-mm-dd'),
                                                       vEND_TIME,
                                                       sEMP_NO,sOrganType);

              --班表上班日 ~ 請假迄時

            ELSE
              BEGIN
              SELECT CHKIN_WKTM,
                     CHKOUT_WKTM,
                     START_REST,
                     END_REST,
                     (SELECT WORK_HRS
                        FROM HRP.HRA_CLASSMST
                       WHERE CLASS_CODE = T1.CLASS_CODE) WORK_HRS
                INTO sCHKIN_WKTM,
                     sCHKOUT_WKTM,
                     sSTART_REST,
                     sEND_REST,
                     sWORK_HRS
                FROM HRP.HRA_CLASSDTL T1
               WHERE CLASS_CODE = iClassKind
                 AND SHIFT_NO = (SELECT MIN(SHIFT_NO)
                                   FROM HRP.HRA_CLASSDTL
                                  WHERE CLASS_CODE = iClassKind  AND SHIFT_NO <> '4')
                ;
              EXCEPTION
                WHEN OTHERS THEN
                NULL;
              END;

              iRealyWorkMin := iRealyWorkMin + sWORK_HRS * 60;

            END IF;

          END LOOP;
          CLOSE cursor2;
        END IF;
    --  dbms_output.put_line('------->' || iClassKind || sEMP_NO);
        -- 應上班分鐘
        BEGIN
        SELECT WORK_HRS * 60
          INTO iWorkMin
          FROM HRP.HRA_CLASSMST
         WHERE CLASS_CODE = iClassKind;
        EXCEPTION
        WHEN OTHERS THEN
                iWorkMin := 0;
        END;
        
        --20200115 by108482 ZA班工時歸零
        IF iClassKind = 'ZA' THEN
          iWorkMin := 0;
        END IF;

        -- 應出勤時間是否小於等於 總上班時間(出勤+假單)
        IF iWorkMin > iRealyWorkMin THEN
        Insufficient_time := iWorkMin - iRealyWorkMin;        
        Insufficient_time_tmp := Insufficient_time - trunc(Insufficient_time/60)*60;
        Insufficient_time := trunc(Insufficient_time/60);
        --曠職時數最小單位?0.5小時 108978
        IF (Insufficient_time_tmp =0) THEN
          Insufficient_time_tmp :=0;
        ELSIF (Insufficient_time_tmp <=30) THEN
          Insufficient_time_tmp :=0.5;
        ELSE
          Insufficient_time_tmp :=1;
        END IF;
           Insufficient_time := Insufficient_time + Insufficient_time_tmp;
          SELECT CH_NAME, (SELECT CH_NAME FROM HRE_ORGBAS WHERE DEPT_NO = t1.DEPT_NO AND ORGAN_TYPE = t1.ORGAN_TYPE) DEPT_NAME,
           DEPT_NO
            INTO sEMP_NAME, sDEPT_NAME, sDEPT_NO
            FROM HRE_EMPBAS t1
           WHERE EMP_NO = sEMP_NO;
        --     AND ORGAN_TYPE = sOrganType;
        --201908 by108482 時數不足超過0.5小時且有遲到者改註記Z,避免曠職未計算到
        IF Insufficient_time > 0.5 AND late_flag = 'Y' THEN
          late_flag := 'Z';
        END IF;
        IF (TO_CHAR(sValidDate, 'YYYYMMDD') < TO_CHAR(SYSDATE, 'YYYYMMDD')) THEN
        BEGIN
          --排除100812 跨天請假且結束時間0000 之資料
          --IF (sEMP_NO = '101029' AND TO_CHAR(sValidDate, 'YYYY-MM-DD') = '2011-10-13') THEN
          --  NULL;
          --ELSE
          --部門資料即時計算，舊的颱風日期不能移除
          --排除2024-07-25,2024-07-26,2024-10-02,2024-10-03,2024-10-04,2024-10-31颱風假資料 IF TO_CHAR(sValidDate, 'YYYY-MM-DD') IN ('2024-07-25','2024-07-26','2024-10-02','2024-10-03','2024-10-04','2024-10-31') THEN
          --排除2025-07-29颱風(豪雨)假資料, 2025-08-13颱風部分資料
          IF TO_CHAR(sValidDate, 'YYYY-MM-DD') IN ('2025-07-29') THEN
            NULL;
          ELSIF TO_CHAR(sValidDate, 'YYYY-MM-DD') IN ('2025-08-13') AND sEMP_NO = '103725' THEN
            NULL;
          ELSIF TO_CHAR(sValidDate, 'YYYY-MM-DD') IN ('2025-01-15') AND sEMP_NO = '114425' THEN
            NULL;
          ELSIF TO_CHAR(sValidDate, 'YYYY-MM-DD') IN ('2025-05-20') AND sEMP_NO = '115083' THEN
            NULL;
          ELSE
          INSERT INTO HRA_9610_TEMP
            (EMP_NO, EMP_NAME, DEPT_NO, DEPT_NAME, VAC_DATE, ORGAN_TYPE,Insufficient_time,late_flag)
          VALUES
            (sEMP_NO,
             sEMP_NAME,
             sDEPT_NO,
             sDEPT_NAME,
             TO_CHAR(sValidDate, 'YYYY-MM-DD'),
             sOrganType,
             Insufficient_time,
             late_flag);
          END IF;
        EXCEPTION
          WHEN OTHERS THEN
          RtnCode := 0;
        END;
        END IF;
       
        END IF;

      END LOOP;

    END LOOP;
    CLOSE cursor1;
    RtnCode := 0;
    RETURN RtnCode;
    NULL;
    <<Continue_ForEach2>>
    NULL;
  
  EXCEPTION WHEN OTHERS THEN
    RETURN to_number(sEMP_NO);
  END f_set_hra9610temp_deptno;
  
  --20260115更新
  FUNCTION f_set_hra9610temp_test(sStartDate VARCHAR2,
                                  sEndDate   VARCHAR2) RETURN NUMBER IS
    sSeq NUMBER := 0;
    
    sEMP_NO     VARCHAR2(10);
    sSTART_DATE VARCHAR2(10);
    sEND_DATE   VARCHAR2(10);
    sSTART_TIME VARCHAR2(4);
    sEND_TIME   VARCHAR2(4);
    sVAC_DAYS   NUMBER;
    sVAC_HRS    NUMBER(3, 1);
    sOrganType  VARCHAR2(10);

    sEMP_NAME  VARCHAR2(200);
    sDEPT_NO   VARCHAR2(10);
    sDEPT_NAME VARCHAR2(60);

    sDayCnt    NUMBER;
    iClassCnt  NUMBER;
    iClassKind VARCHAR2(3);
    iWorkMin   NUMBER;

    sCHKIN_WKTM  VARCHAR2(4);
    sCHKOUT_WKTM VARCHAR2(4);
    sSTART_REST  VARCHAR2(4);
    sEND_REST    VARCHAR2(4);
    sWORK_HRS    VARCHAR2(4);
    sValidDate   DATE;

    iRealyWorkMin NUMBER;

    sCHKIN_CARD  VARCHAR2(4);
    sCHKOUT_CARD VARCHAR2(4);
    sNIGHT_FLAG  VARCHAR2(1);

    sVacMin NUMBER;
    iCnt    INTEGER;
    iCardSignCnt INTEGER;
    iCheckDate   INTEGER;

    vSTART_DATE VARCHAR2(10);
    vEND_DATE   VARCHAR2(10);
    vSTART_TIME VARCHAR2(4);
    vEND_TIME   VARCHAR2(4);
    RtnCode     NUMBER;
   --itest       NUMBER :=0;
    Insufficient_time NUMBER;
    Insufficient_time_tmp NUMBER;
    Insufficient_min NUMBER;
    late_flag VARCHAR2(1):='N';
    late_time NUMBER;
    
    CURSOR cursor1 IS
      SELECT EMP_NO,
             TO_CHAR(start_date, 'yyyy-mm-dd') START_DATE,
             TO_CHAR(end_date, 'yyyy-mm-dd') END_DATE, START_TIME, END_TIME, ORG_BY
        FROM (SELECT emp_no, START_DATE, END_DATE,START_TIME , END_TIME, ORG_BY
                FROM hrp.HRA_EVCREC
               WHERE status = 'Y'
			   --and emp_no='109233' -- test
                 AND emp_no NOT IN
                     (SELECT EMP_NO
                        FROM HRP.HRE_PROFILE
                       WHERE ITEM_NO IN ('EMP01', 'EMP02'))
                       
              UNION ALL --20190115 108978 20180301無借休資料
              SELECT emp_no, START_DATE, END_DATE,START_TIME , END_TIME, ORG_BY
                FROM hrp.HRA_OFFREC
               WHERE status = 'Y'
                 AND emp_no NOT IN
                     (SELECT EMP_NO
                        FROM HRP.HRE_PROFILE
                       WHERE ITEM_NO IN ('EMP01', 'EMP02'))
                 AND item_type = 'O'
              UNION ALL
              SELECT emp_no, START_DATE, END_DATE,START_TIME , END_TIME, ORG_BY
                FROM hrp.HRA_SUPMST
               WHERE status = 'Y'
			    --and emp_no='109233'--test
                 AND emp_no NOT IN
                     (SELECT EMP_NO
                        FROM HRP.HRE_PROFILE
                       WHERE ITEM_NO IN ('EMP01', 'EMP02')))
     WHERE TO_CHAR(start_date, 'yyyy-mm-dd') BETWEEN sStartDate AND sEndDate
     --where to_char(start_date,'yyyy-mm-dd') = '2011-10-13' --test
/*     and emp_no = '101756'*/
       ;

    CURSOR cursor2(sEmpNo VARCHAR2, sValidDate DATE) IS
      SELECT TO_CHAR(START_DATE, 'YYYY-MM-DD'),
             START_TIME,
             TO_CHAR(END_DATE, 'YYYY-MM-DD'),
             END_TIME, ORG_BY
        FROM HRA_EVCREC
       WHERE EMP_NO = sEmpNo
         AND (TO_CHAR(sValidDate, 'YYYY-MM-DD') BETWEEN
             TO_CHAR(START_DATE, 'YYYY-MM-DD') AND
             TO_CHAR(END_DATE, 'YYYY-MM-DD'))
         AND STATUS = 'Y';

  BEGIN
    OPEN cursor1;
    LOOP
      FETCH cursor1
        INTO sEMP_NO, sSTART_DATE, sEND_DATE ,sSTART_TIME, sEND_TIME, sOrganType;
      EXIT WHEN cursor1%NOTFOUND;
     /*    TEST
      itest := itest +1;

      INSERT INTO HRP.HRE_EMP_TEST  (EMP_NO,I) VALUES  (sEMP_NO,itest);
      COMMIT;
      */
      -- EndDate - StartDate +1 => 要跑的迴圈次數
      sDayCnt := TO_DATE(sEND_DATE, 'yyyy-mm-dd') -
                 TO_DATE(sSTART_DATE, 'yyyy-mm-dd') + 1;

      IF sEND_TIME = '0000' THEN

       sDayCnt := sDayCnt -1;

      END IF;

      FOR i IN 1 .. sDayCnt LOOP
        late_flag :='N';
        iRealyWorkMin := 0;
        sValidDate    := TO_DATE(sSTART_DATE, 'yyyy-mm-dd') + i - 1;
        -- 班表
        iClassKind := Ehrphrafunc_Pkg.f_getClassKind(sEMP_NO, sValidDate, sOrganType);
/*        dbms_output.put_line('iClassKind'||iClassKind||sValidDate);*/
        -- 當日班別時段數,不含 OnCall

        SELECT COUNT(*)
          INTO iClassCnt
          FROM HRP.HRA_CLASSDTL
         WHERE CLASS_CODE = iClassKind
           AND SHIFT_NO <> 4;

        FOR j IN 1 .. iClassCnt LOOP

          -- 當日上班時段出勤
          SELECT CHKIN_WKTM, CHKOUT_WKTM, START_REST, END_REST
            INTO sCHKIN_WKTM, sCHKOUT_WKTM, sSTART_REST, sEND_REST
            FROM HRP.HRA_CLASSDTL
           WHERE CLASS_CODE = iClassKind
             AND SHIFT_NO = j;
          
          --20260116 by108482 確認人員實際排班日
          /*SELECT (CASE
                   WHEN TO_DATE('2023-04-220000', 'yyyy/mm/ddHH24MI') BETWEEN
                        TO_DATE('2023-04-222200', 'yyyy/mm/ddHH24MI') AND
                        TO_DATE('2023-04-230800', 'yyyy/mm/ddHH24MI') THEN
                    1
                   ELSE
                    2
                 END)
            INTO iCheckDate
            FROM DUAL;*/

          -- 當日上班
          BEGIN
            SELECT CHKIN_CARD, CHKOUT_CARD, NIGHT_FLAG
              INTO sCHKIN_CARD, sCHKOUT_CARD, sNIGHT_FLAG
              FROM HRP.HRA_CADSIGN
             WHERE EMP_NO = sEMP_NO
               AND TO_CHAR(ATT_DATE, 'YYYY-MM-DD') =
                   TO_CHAR(sValidDate, 'yyyy-mm-dd')
               AND SHIFT_NO = j
               AND ORG_BY = sOrganType;

          EXCEPTION
            WHEN NO_DATA_FOUND THEN

              sCHKIN_CARD  := NULL;
              sCHKOUT_CARD := NULL;
              sNIGHT_FLAG  := NULL;
          END;

          -- sCHKIN_CARD,sCHKOUT_CARD,sNIGHT_FLAG 有可能是 null , 必需考慮

          -- sCHKIN_CARD 打卡時間
          -- sCHKIN_WKTM 班別時間

          IF sCHKIN_CARD IS NOT NULL AND sCHKOUT_CARD IS NOT NULL THEN

            -- 上班
            IF sCHKIN_CARD <= sCHKIN_WKTM + 2 THEN

              sCHKIN_CARD := sCHKIN_WKTM;
            
            ELSE
              --跨夜班
              IF sCHKIN_WKTM BETWEEN '0000' AND '0800' THEN

                IF sCHKIN_CARD BETWEEN '1600' AND '2400' THEN

                  sCHKIN_CARD := sCHKIN_WKTM;

                END IF;

              END IF;

            END IF;
            
       
        --20180910 108978 增加記錄遲到註記
        --20260114 108482 2026年度開始遲到改30分鐘(含)內
          IF TO_CHAR(sValidDate, 'yyyy') <= '2025' THEN
            IF (sEND_TIME IS NOT NULL AND to_number(sCHKIN_CARD) <=to_number(sCHKIN_WKTM)+15 AND to_number(sCHKIN_CARD) > to_number(sCHKIN_WKTM)+2 )THEN
              late_flag :='Y';
            END IF;
          ELSE
            IF (sEND_TIME IS NOT NULL AND to_number(sCHKIN_CARD) <=to_number(sCHKIN_WKTM)+30 AND to_number(sCHKIN_CARD) > to_number(sCHKIN_WKTM)+2 )THEN
              late_flag :='Y';
            END IF;
          END IF;
            

            -- 下班
            IF sCHKOUT_CARD >= (CASE WHEN sCHKOUT_WKTM = '0000' THEN '2400' ELSE sCHKOUT_WKTM END ) THEN

              sCHKOUT_CARD := sCHKOUT_WKTM;

            ELSE

              IF ((sCHKOUT_CARD BETWEEN '1600' AND '2400') OR (sCHKOUT_CARD = '0000')) THEN
              /*IF ((sCHKOUT_WKTM BETWEEN '1600' AND '2400') OR (sCHKOUT_WKTM = '0000')) THEN*/

                IF sCHKOUT_CARD BETWEEN '0000' AND '0800' THEN

                  sCHKOUT_CARD := sCHKOUT_WKTM;

                END IF;

              END IF;

            END IF;

            iRealyWorkMin := iRealyWorkMin + Ehrphra12_Pkg.getoffhrs(TO_CHAR(sValidDate,'yyyy-mm-dd'), 
                                                                     sCHKIN_CARD,
                                                                     (CASE WHEN (sNIGHT_FLAG = 'Y' OR sCHKOUT_WKTM ='0800' /*RN*/) THEN TO_CHAR(sValidDate + 1, 'yyyy-mm-dd') ELSE TO_CHAR(sValidDate, 'yyyy-mm-dd') END),
                                                                     /*(CASE WHEN (sNIGHT_FLAG = 'Y' AND (sCHKIN_WKTM > sCHKOUT_WKTM)) THEN TO_CHAR(sValidDate + 1, 'yyyy-mm-dd') ELSE TO_CHAR(sValidDate, 'yyyy-mm-dd') END),*/
                                                                     sCHKOUT_CARD, 
                                                                     sEMP_NO,
                                                                     sOrganType);
          ELSE
           BEGIN

            SELECT COUNT(*)
              INTO iCardSignCnt
              FROM HRP.HRA_CADSIGN
             WHERE EMP_NO = sEMP_NO
               AND TO_CHAR(ATT_DATE, 'YYYY-MM-DD') =
                   TO_CHAR(sValidDate, 'yyyy-mm-dd')
               AND SHIFT_NO = 1
               AND ORG_BY = sOrganType;

          EXCEPTION
            WHEN NO_DATA_FOUND THEN
            iCardSignCnt := 0;
          END;
          
          IF(iCardSignCnt >0)THEN
            --增加判斷打卡異常的sCHKIN_CARD或sCHKOUT_CARD是 null,工作時數為應班工時/2,在算曠職的時候已經計算，所以在請假時數不足的時候不要在計算進去，避免扣兩次。 20181106 108978
            BEGIN
            SELECT WORK_HRS * 60
              INTO iWorkMin
              FROM HRP.HRA_CLASSMST
             WHERE CLASS_CODE = iClassKind;
            EXCEPTION
            WHEN OTHERS THEN
              iWorkMin := 0;
            END;
            iRealyWorkMin := iRealyWorkMin + (iWorkMin/2);
          END IF;
          
          END IF;

        END LOOP;

        -- 借休單

        BEGIN
          SELECT NVL(SUM(OTM_HRS) * 60, 0)
            INTO sVacMin
            FROM HRA_OFFREC
           WHERE EMP_NO = sEMP_NO
             AND TO_CHAR(sValidDate, 'YYYY-MM-DD') =
                 TO_CHAR(START_DATE, 'YYYY-MM-DD')
             AND STATUS = 'Y'
             AND item_type = 'O'
             AND ORG_BY = sOrganType;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            sVacMin := 0;
        END;

        iRealyWorkMin := iRealyWorkMin + sVacMin;

        --補休單
        BEGIN
          SELECT NVL(SUM(SUP_HRS) * 60, 0)
            INTO sVacMin
            FROM HRA_SUPMST
           WHERE EMP_NO = sEMP_NO
             AND TO_CHAR(sValidDate, 'YYYY-MM-DD') =
                 TO_CHAR(START_DATE, 'YYYY-MM-DD')
             AND STATUS = 'Y'
             AND ORG_BY = sOrganType;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            sVacMin := 0;
        END;

        iRealyWorkMin := iRealyWorkMin + sVacMin;

        -- 電子假卡 時數 -- 可 "跨天" 要注意
        -- 頭尾 注意 即可!!
        BEGIN
          SELECT COUNT(*)
            INTO iCnt
            FROM HRA_EVCREC
           WHERE EMP_NO = sEMP_NO
             AND (TO_CHAR(sValidDate, 'YYYY-MM-DD') BETWEEN
                 TO_CHAR(START_DATE, 'YYYY-MM-DD') AND
                 TO_CHAR(END_DATE, 'YYYY-MM-DD')) -- sphinx  94.09.28
             AND STATUS = 'Y'
             AND ORG_BY = sOrganType;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            iCnt := 0;
        END;

        IF iCnt > 0 THEN
          OPEN cursor2(sEMP_NO, sValidDate);
          LOOP
            FETCH cursor2
              INTO vSTART_DATE, vSTART_TIME, vEND_DATE, vEND_TIME, sOrganType;
            EXIT WHEN cursor2%NOTFOUND;

            IF TO_CHAR(sValidDate, 'yyyy-mm-dd') = vSTART_DATE
             OR( TO_CHAR(sValidDate + 1, 'yyyy-mm-dd') = vEND_DATE AND vEND_TIME = '0000' ) --JB班的結算時間判斷
            THEN

              BEGIN
              SELECT CHKIN_WKTM,
                     CHKOUT_WKTM,
                     START_REST,
                     END_REST,
                     (SELECT WORK_HRS
                        FROM HRP.HRA_CLASSMST
                       WHERE CLASS_CODE = T1.CLASS_CODE) WORK_HRS
                INTO sCHKIN_WKTM,
                     sCHKOUT_WKTM,
                     sSTART_REST,
                     sEND_REST,
                     sWORK_HRS
                FROM HRP.HRA_CLASSDTL T1
               WHERE CLASS_CODE = iClassKind
                 AND SHIFT_NO = (SELECT MAX(SHIFT_NO)
                                   FROM HRP.HRA_CLASSDTL
                                  WHERE CLASS_CODE = iClassKind  AND SHIFT_NO <> '4');
              EXCEPTION
                WHEN OTHERS THEN
                NULL;
              END;
              
              --請假是同一天
              IF vSTART_DATE = vEND_DATE THEN
                vEND_TIME := vEND_TIME;
              ELSE
              --結束時間為班表時間
                vEND_TIME := sCHKOUT_WKTM;
              END IF;
              
              --JB班休假多天，最後一天檢核開始時間抓班表開始時間 20210901 by108482
              IF (TO_CHAR(sValidDate + 1, 'yyyy-mm-dd') = vEND_DATE AND vEND_TIME = '0000') AND
                 TO_CHAR(sValidDate, 'yyyy-mm-dd') <> vSTART_DATE THEN
                vSTART_TIME := sCHKIN_WKTM;
              END IF;

              --開始時間需判斷，取整點
              /*IF SUBSTR(vSTART_TIME,3,4) BETWEEN '00' AND '29' THEN
              vSTART_TIME := SUBSTR(vSTART_TIME,1,2) || '00';
              ELSIF SUBSTR(vSTART_TIME,3,4) BETWEEN '30' AND '59' THEN
              vSTART_TIME := SUBSTR(vSTART_TIME,1,2) || '30';
              END IF;*/
              --20231108 by108482 調整開始時間應往後判斷整點 EX:1333應認定為1400
              IF SUBSTR(vSTART_TIME,3,4) BETWEEN '01' AND '29' THEN
                vSTART_TIME := SUBSTR(vSTART_TIME,1,2) || '30';
              ELSIF SUBSTR(vSTART_TIME,3,4) BETWEEN '31' AND '59' THEN
                vSTART_TIME := to_number(SUBSTR(vSTART_TIME,1,2))+1 || '00';
              END IF;
              
              --結束時間需判斷，取整點(因假卡是半小時為單位,避免誤算曠職) 20210629 by108482
              /*IF SUBSTR(vEND_TIME,3,4) BETWEEN '01' AND '29' THEN
                vEND_TIME := SUBSTR(vEND_TIME,1,2) || '30';
              ELSIF SUBSTR(vEND_TIME,3,4) BETWEEN '31' AND '59' THEN
                vEND_TIME := to_number(SUBSTR(vEND_TIME,1,2))+1 || '00';
              END IF;*/
              --20240409 by108482 調整結束時間應往前判斷整點 EX:2359應認定為2330
              IF SUBSTR(vEND_TIME,3,4) BETWEEN '01' AND '29' THEN
                vEND_TIME := SUBSTR(vEND_TIME,1,2) || '00';
              ELSIF SUBSTR(vEND_TIME,3,4) BETWEEN '31' AND '59' THEN
                vEND_TIME := SUBSTR(vEND_TIME,1,2) || '30';
              END IF;
              
              IF vEND_TIME = '2400' THEN 
                vEND_TIME := '0000';
                vEND_DATE := to_char(to_date(vEND_DATE,'yyyy/mm/dd')+1, 'yyyy-mm-dd');
              END IF;
              IF LENGTH(vSTART_TIME) = 3 THEN
                vSTART_TIME := '0'||vSTART_TIME;
              END IF;
              IF LENGTH(vEND_TIME) = 3 THEN
                vEND_TIME := '0'||vEND_TIME;
              END IF;

             --JB班的工時判斷
             IF TO_CHAR(sValidDate + 1, 'yyyy-mm-dd') <= vEND_DATE AND vEND_TIME = '0000' THEN

              iRealyWorkMin := iRealyWorkMin +
                               Ehrphra12_Pkg.getoffhrs(TO_CHAR(sValidDate,
                                                               'yyyy-mm-dd'),
                                                       vSTART_TIME,
                                                       TO_CHAR(sValidDate+1,
                                                               'yyyy-mm-dd'),
                                                       vEND_TIME,
                                                       sEMP_NO,sOrganType);
             --20180430 108978 增加判斷有跨天的時候結束時間大於0000 ，如NK(1/1 2100- 1/2 0700)
             ELSIF TO_CHAR(sValidDate+1 , 'yyyy-mm-dd') <= vEND_DATE AND vEND_TIME >= '0000' THEN
              iRealyWorkMin := iRealyWorkMin +              
                               Ehrphra12_Pkg.getoffhrs(TO_CHAR(sValidDate,
                                                               'yyyy-mm-dd'),
                                                       vSTART_TIME,
                                                       TO_CHAR(sValidDate+1,
                                                               'yyyy-mm-dd'),
                                                       vEND_TIME,
                                                       sEMP_NO,sOrganType);  
             ELSE
              iRealyWorkMin := iRealyWorkMin +
                               Ehrphra12_Pkg.getoffhrs(TO_CHAR(sValidDate,
                                                               'yyyy-mm-dd'),
                                                       vSTART_TIME,
                                                       TO_CHAR(sValidDate,
                                                               'yyyy-mm-dd'),
                                                       vEND_TIME,
                                                       sEMP_NO,sOrganType);
             END IF;

              -- 請假起時 ~ 班表下班時

            ELSIF TO_CHAR(sValidDate, 'yyyy-mm-dd') = vEND_DATE THEN
              BEGIN
              SELECT CHKIN_WKTM,
                     CHKOUT_WKTM,
                     START_REST,
                     END_REST,
                     (SELECT WORK_HRS
                        FROM HRP.HRA_CLASSMST
                       WHERE CLASS_CODE = T1.CLASS_CODE) WORK_HRS
                INTO sCHKIN_WKTM,
                     sCHKOUT_WKTM,
                     sSTART_REST,
                     sEND_REST,
                     sWORK_HRS
                FROM HRP.HRA_CLASSDTL T1
               WHERE CLASS_CODE = iClassKind
                 AND SHIFT_NO = (SELECT MIN(SHIFT_NO)
                                   FROM HRP.HRA_CLASSDTL
                                  WHERE CLASS_CODE = iClassKind  AND SHIFT_NO <> '4');
              EXCEPTION
                WHEN OTHERS THEN
                NULL;
              END;

              vSTART_TIME   := sCHKIN_WKTM;
              iRealyWorkMin := iRealyWorkMin +
                               Ehrphra12_Pkg.getoffhrs(TO_CHAR(sValidDate,
                                                               'yyyy-mm-dd'),
                                                       vSTART_TIME,
                                                       TO_CHAR(sValidDate,
                                                               'yyyy-mm-dd'),
                                                       vEND_TIME,
                                                       sEMP_NO,sOrganType);

              --班表上班日 ~ 請假迄時

            ELSE
              BEGIN
              SELECT CHKIN_WKTM,
                     CHKOUT_WKTM,
                     START_REST,
                     END_REST,
                     (SELECT WORK_HRS
                        FROM HRP.HRA_CLASSMST
                       WHERE CLASS_CODE = T1.CLASS_CODE) WORK_HRS
                INTO sCHKIN_WKTM,
                     sCHKOUT_WKTM,
                     sSTART_REST,
                     sEND_REST,
                     sWORK_HRS
                FROM HRP.HRA_CLASSDTL T1
               WHERE CLASS_CODE = iClassKind
                 AND SHIFT_NO = (SELECT MIN(SHIFT_NO)
                                   FROM HRP.HRA_CLASSDTL
                                  WHERE CLASS_CODE = iClassKind  AND SHIFT_NO <> '4')
                ;
              EXCEPTION
                WHEN OTHERS THEN
                NULL;
              END;

              iRealyWorkMin := iRealyWorkMin + sWORK_HRS * 60;

            END IF;

          END LOOP;
          CLOSE cursor2;
        END IF;
    --  dbms_output.put_line('------->' || iClassKind || sEMP_NO);
        -- 應上班分鐘
        BEGIN
        SELECT WORK_HRS * 60
          INTO iWorkMin
          FROM HRP.HRA_CLASSMST
         WHERE CLASS_CODE = iClassKind;
        EXCEPTION
        WHEN OTHERS THEN
                iWorkMin := 0;
        END;
        
        --20200115 by108482 ZA班工時歸零
        IF iClassKind = 'ZA' THEN
          iWorkMin := 0;
        END IF;

        -- 應出勤時間是否小於等於 總上班時間(出勤+假單)
        IF iWorkMin > iRealyWorkMin THEN
          Insufficient_min := iWorkMin - iRealyWorkMin;
          Insufficient_time := iWorkMin - iRealyWorkMin;
          Insufficient_time_tmp := Insufficient_time - trunc(Insufficient_time/60)*60;
          Insufficient_time := trunc(Insufficient_time/60);
          --曠職時數最小單位為0.5小時 108978
          IF (Insufficient_time_tmp =0) THEN
            Insufficient_time_tmp :=0;
          ELSIF (Insufficient_time_tmp <=30) THEN
            Insufficient_time_tmp :=0.5;
          ELSE
            Insufficient_time_tmp :=1;
          END IF;
          Insufficient_time := Insufficient_time + Insufficient_time_tmp;
          IF late_flag = 'Y' THEN
            late_time := sCHKIN_CARD - sCHKIN_WKTM;
          ELSE
            late_time := 0;
          END IF;
          SELECT CH_NAME, DEPT_NO,
                 (SELECT CH_NAME FROM HRE_ORGBAS WHERE DEPT_NO = t1.DEPT_NO AND ORGAN_TYPE = t1.ORGAN_TYPE) DEPT_NAME
            INTO sEMP_NAME, sDEPT_NO, sDEPT_NAME
            FROM HRE_EMPBAS t1
           WHERE EMP_NO = sEMP_NO;
        --     AND ORGAN_TYPE = sOrganType;
        --201908 by108482 時數不足超過0.5小時且有遲到者改註記Z,避免曠職未計算到
        --IF Insufficient_time > 0.5 AND late_flag = 'Y' THEN
        IF (Insufficient_time/60) > 0.5 AND late_flag = 'Y' THEN
          late_flag := 'Z';
        END IF;
        Insufficient_min := Insufficient_min - late_time;
        IF Insufficient_min < 0 THEN
          Insufficient_min := 0;
        END IF;
        IF (TO_CHAR(sValidDate, 'YYYYMMDD') < TO_CHAR(SYSDATE, 'YYYYMMDD')) THEN
        BEGIN
          --排除100812 跨天請假且結束時間0000 之資料
          --IF (sEMP_NO = '101029' AND TO_CHAR(sValidDate, 'YYYY-MM-DD') = '2011-10-13') THEN
          --  NULL;
          --ELSE
          --排除2024-07-25颱風假資料 IF TO_CHAR(sValidDate, 'YYYY-MM-DD') IN ('2024-07-25','2024-07-26') THEN
          --排除2024-10-02,2024-10-03,2024-10-04,2024-10-31颱風假資料 IF TO_CHAR(sValidDate, 'YYYY-MM-DD') IN ('2024-10-02','2024-10-03','2024-10-04','2024-10-31') THEN
          --排除2025-07-29颱風(豪雨)假資料, 2025-08-13颱風部分資料
          IF TO_CHAR(sValidDate, 'YYYY-MM-DD') IN ('2025-07-29') THEN
            NULL;
          ELSIF TO_CHAR(sValidDate, 'YYYY-MM-DD') IN ('2025-08-13') AND sEMP_NO = '103725' THEN
            NULL;
          ELSE
          /*INSERT INTO PUR_MED
            (MED_ID, PUR_MED.INSU_CODE, PUR_MED.MED_DESC, PUR_MED.ALISE_DESC, PUR_MED.QTY_DESC, PUR_MED.CREATION_DATE, 
             PUR_MED.ORGAN_TYPE, PUR_MED.NUMBER1, PUR_MED.NUMBER2, PUR_MED.FLOAT1, PUR_MED.BRAND,
             PUR_MED.VENDOR_ID, PUR_MED.MECHANISM, PUR_MED.DOSAGE, PUR_MED.INDUCATION, PUR_MED.UNLABCL_USE, PUR_MED.INSU_DATA)
          VALUES
            (sSeq,
             sEMP_NO,
             sEMP_NAME,
             sDEPT_NO,
             sDEPT_NAME,
             sValidDate,
             sOrganType,
             Insufficient_time,
             Insufficient_min,
             late_time,
             late_flag,
             sCHKIN_CARD,
             sCHKOUT_CARD,
             sCHKIN_WKTM,
             sCHKOUT_WKTM,
             sSTART_REST,
             sEND_REST);*/
          COMMIT;
          sSeq := sSeq + 1;
          INSERT INTO HRA_9610_TEMP
            (EMP_NO, EMP_NAME, DEPT_NO, DEPT_NAME, VAC_DATE, ORGAN_TYPE, INSUFFICIENT_TIME, LATE_FLAG, 
             INSUFFICIENT_MIN, LATE_MINUTE, CHKIN_CARD, CHKOUT_CARD, CHKIN_REAL, CHKOUT_REAL, START_TIME_S, END_TIME_S)
          VALUES
            (sEMP_NO,
             sEMP_NAME,
             sDEPT_NO,
             sDEPT_NAME,
             TO_CHAR(sValidDate, 'YYYY-MM-DD'),
             sOrganType,
             Insufficient_time,
             late_flag,
             Insufficient_min,
             late_time,
             sCHKIN_CARD,
             sCHKOUT_CARD,
             sCHKIN_WKTM,
             sCHKOUT_WKTM,
             sSTART_REST,
             sEND_REST);
          END IF;
        EXCEPTION WHEN OTHERS THEN
          RtnCode := SQLCODE;
        END;
        END IF;
       
        END IF;

      END LOOP;

    END LOOP;
    CLOSE cursor1;
    RtnCode := 0;
    RETURN RtnCode;
    NULL;
    <<Continue_ForEach2>>
    NULL;

  END f_set_hra9610temp_test;
  
  FUNCTION f_set_hra9610temp_without_i(sStartDate VARCHAR2,
                                 sEndDate   VARCHAR2,sEMP_NO_I VARCHAR2 ) RETURN NUMBER IS

    StartDate     VARCHAR2(10):=sStartDate;
    EndDate VARCHAR2(10):=StartDate;
    sEMP_NO     VARCHAR2(10);
    --sEMP_NO_I     VARCHAR2(10):='108913';
    sSTART_DATE VARCHAR2(10);
    sEND_DATE   VARCHAR2(10);
    sSTART_TIME VARCHAR2(4);
    sEND_TIME   VARCHAR2(4);
    sVAC_DAYS   NUMBER;
    sVAC_HRS    NUMBER(3, 1);
    sOrganType  VARCHAR2(10);

    sEMP_NAME  VARCHAR2(200);
    sDEPT_NO   VARCHAR2(10);
    sDEPT_NAME VARCHAR2(60);

    sDayCnt    NUMBER;
    iClassCnt  NUMBER;
    iClassKind VARCHAR2(3);
    iWorkMin   NUMBER;

    sCHKIN_WKTM  VARCHAR2(4);
    sCHKOUT_WKTM VARCHAR2(4);
    sSTART_REST  VARCHAR2(4);
    sEND_REST    VARCHAR2(4);
    sWORK_HRS    VARCHAR2(4);
    sValidDate   DATE;

    iRealyWorkMin NUMBER;

    sCHKIN_CARD  VARCHAR2(4);
    sCHKOUT_CARD VARCHAR2(4);
    sNIGHT_FLAG  VARCHAR2(1);

    sVacMin NUMBER;
    iCnt    INTEGER;
    iCardsignCnt INTEGER;
    vSTART_DATE VARCHAR2(10);
    vEND_DATE   VARCHAR2(10);
    vSTART_TIME VARCHAR2(4);
    vEND_TIME   VARCHAR2(4);

    --late_flag VARCHAR2(1):='0';
    --late_time NUMBER;
    RtnCode     NUMBER;
   --itest       NUMBER :=0;
   Insufficient_time NUMBER;
   Insufficient_time_tmp NUMBER;
   Insufficient_min NUMBER;
    late_flag VARCHAR2(1):='N';
    late_time NUMBER;
    
    CURSOR cursor1 IS

      SELECT emp_no,
             TO_CHAR(start_date, 'yyyy-mm-dd') START_DATE,
             TO_CHAR(end_date, 'yyyy-mm-dd') END_DATE,START_TIME , END_TIME, ORG_BY
        FROM (SELECT emp_no, START_DATE, END_DATE,START_TIME , END_TIME, ORG_BY
                FROM hrp.HRA_EVCREC
               WHERE status = 'Y'
			   and emp_no=sEMP_NO_I -- test
                 AND emp_no NOT IN
                     (SELECT EMP_NO
                        FROM HRP.HRE_PROFILE
                       WHERE ITEM_NO IN ('EMP01', 'EMP02'))
              UNION ALL
              SELECT emp_no, START_DATE, END_DATE,START_TIME , END_TIME, ORG_BY
                FROM hrp.HRA_OFFREC
               WHERE status = 'Y'
			    and emp_no=sEMP_NO_I--test
                 AND emp_no NOT IN
                     (SELECT EMP_NO
                        FROM HRP.HRE_PROFILE
                       WHERE ITEM_NO IN ('EMP01', 'EMP02'))
                 AND item_type = 'O'
              UNION ALL
              SELECT emp_no, START_DATE, END_DATE,START_TIME , END_TIME, ORG_BY
                FROM hrp.HRA_SUPMST
               WHERE status = 'Y'
			   and emp_no=sEMP_NO_I--test
                 AND emp_no NOT IN
                     (SELECT EMP_NO
                        FROM HRP.HRE_PROFILE
                       WHERE ITEM_NO IN ('EMP01', 'EMP02')))
     WHERE TO_CHAR(start_date, 'yyyy-mm-dd') BETWEEN StartDate AND EndDate
     --WHERE TO_CHAR(start_date, 'yyyy-mm-dd') BETWEEN sStartDate AND sEndDate
     --where to_char(start_date,'yyyy-mm-dd') = '2011-10-13' --test
/*     and emp_no = '101756'*/
       ;

    CURSOR cursor2(sEmpNo VARCHAR2, sValidDate DATE) IS
      SELECT TO_CHAR(START_DATE, 'YYYY-MM-DD'),
             START_TIME,
             TO_CHAR(END_DATE, 'YYYY-MM-DD'),
             END_TIME, ORG_BY
        FROM HRA_EVCREC
       WHERE EMP_NO = sEmpNo
         AND (TO_CHAR(sValidDate, 'YYYY-MM-DD') BETWEEN
             TO_CHAR(START_DATE, 'YYYY-MM-DD') AND
             TO_CHAR(END_DATE, 'YYYY-MM-DD'))
         AND STATUS = 'Y';

  BEGIN
dbms_output.put_line('sStartDate'||sStartDate||'-'||sEndDate);    
    OPEN cursor1;
    LOOP
      FETCH cursor1
        INTO sEMP_NO, sSTART_DATE, sEND_DATE ,sSTART_TIME, sEND_TIME, sOrganType;

      EXIT WHEN cursor1%NOTFOUND;
     /*    TEST
      itest := itest +1;

      INSERT INTO HRP.HRE_EMP_TEST  (EMP_NO,I) VALUES  (sEMP_NO,itest);
      COMMIT;
      */
      -- EndDate - StartDate +1 => 要跑的迴圈次數
      sDayCnt := TO_DATE(sEND_DATE, 'yyyy-mm-dd') -
                 TO_DATE(sSTART_DATE, 'yyyy-mm-dd') + 1;

      IF sEND_TIME = '0000' THEN

       sDayCnt := sDayCnt -1;

      END IF;

      FOR i IN 1 .. sDayCnt LOOP
        late_flag := 'N';
        iRealyWorkMin := 0;
        sValidDate    := TO_DATE(sSTART_DATE, 'yyyy-mm-dd') + i - 1;

        -- 班表
        iClassKind := Ehrphrafunc_Pkg.f_getClassKind(sEMP_NO, sValidDate,sOrganType);
dbms_output.put_line('iClassKind'||iClassKind||'-'||sValidDate);
        -- 當日班別時段數,不含 OnCall

        SELECT COUNT(*)
          INTO iClassCnt
          FROM HRP.HRA_CLASSDTL
         WHERE CLASS_CODE = iClassKind
           AND SHIFT_NO <> 4;

        FOR j IN 1 .. iClassCnt LOOP

          -- 當日上班時段出勤
          SELECT CHKIN_WKTM, CHKOUT_WKTM, START_REST, END_REST
            INTO sCHKIN_WKTM, sCHKOUT_WKTM, sSTART_REST, sEND_REST
            FROM HRP.HRA_CLASSDTL
           WHERE CLASS_CODE = iClassKind
             AND SHIFT_NO = j;

          -- 當日上班

          BEGIN

            SELECT CHKIN_CARD, CHKOUT_CARD, NIGHT_FLAG
              INTO sCHKIN_CARD, sCHKOUT_CARD, sNIGHT_FLAG
              FROM HRP.HRA_CADSIGN
             WHERE EMP_NO = sEMP_NO
               AND TO_CHAR(ATT_DATE, 'YYYY-MM-DD') =
                   TO_CHAR(sValidDate, 'yyyy-mm-dd')
               AND SHIFT_NO = j
               AND ORG_BY = sOrganType;

          EXCEPTION
            WHEN NO_DATA_FOUND THEN

              sCHKIN_CARD  := NULL;
              sCHKOUT_CARD := NULL;
              sNIGHT_FLAG  := NULL;
          END;

          -- sCHKIN_CARD,sCHKOUT_CARD,sNIGHT_FLAG 有可能是 null , 必需考慮

          -- sCHKIN_CARD 打卡時間
          -- sCHKIN_WKTM 班別時間

          IF sCHKIN_CARD IS NOT NULL AND sCHKOUT_CARD IS NOT NULL THEN

            -- 上班
            IF sCHKIN_CARD <= sCHKIN_WKTM + 2 THEN

              sCHKIN_CARD := sCHKIN_WKTM;

            ELSE

              IF sCHKIN_WKTM BETWEEN '0000' AND '0800' THEN

                IF sCHKIN_CARD BETWEEN '1600' AND '2400' THEN

                  sCHKIN_CARD := sCHKIN_WKTM;

                END IF;

              END IF;

            END IF;

        --20180910 108978 增加記錄遲到註記                           
        --20260114 108482 2026年度開始遲到改30分鐘(含)內
          IF TO_CHAR(sValidDate, 'yyyy') <= '2025' THEN
            IF (sEND_TIME IS NOT NULL AND to_number(sCHKIN_CARD) <=to_number(sCHKIN_WKTM)+15 AND to_number(sCHKIN_CARD) > to_number(sCHKIN_WKTM)+2 )THEN
              late_flag :='Y';
            END IF;
          ELSE
            IF (sEND_TIME IS NOT NULL AND to_number(sCHKIN_CARD) <=to_number(sCHKIN_WKTM)+30 AND to_number(sCHKIN_CARD) > to_number(sCHKIN_WKTM)+2 )THEN
              late_flag :='Y';
            END IF;
          END IF;
      

            -- 下班
            IF sCHKOUT_CARD >= (CASE WHEN sCHKOUT_WKTM = '0000' THEN '2400' ELSE sCHKOUT_WKTM END ) THEN

              sCHKOUT_CARD := sCHKOUT_WKTM;

            ELSE

              IF sCHKOUT_CARD BETWEEN '1600' AND '2400' OR
                 sCHKOUT_CARD = '0000' THEN

                IF sCHKOUT_CARD BETWEEN '0000' AND '0800' THEN

                  sCHKOUT_CARD := sCHKOUT_WKTM;

                END IF;

              END IF;

            END IF;
            


            iRealyWorkMin := iRealyWorkMin + Ehrphra12_Pkg.getoffhrs(TO_CHAR(sValidDate,'yyyy-mm-dd'), sCHKIN_CARD,(CASE WHEN (sNIGHT_FLAG = 'Y' OR sCHKOUT_WKTM ='0800' /*RA*/) THEN TO_CHAR(sValidDate + 1, 'yyyy-mm-dd') ELSE TO_CHAR(sValidDate, 'yyyy-mm-dd') END), sCHKOUT_CARD, sEMP_NO,sOrganType);
DBMS_OUTPUT.put_line('iRealyWorkMin:'||iRealyWorkMin||'sCHKIN_CARD:'||sCHKIN_CARD||'sCHKOUT_CARD:'||sCHKOUT_CARD);
          
          ELSE
            
          BEGIN

            SELECT COUNT(*)
              INTO iCardSignCnt
              FROM HRP.HRA_CADSIGN
             WHERE EMP_NO = sEMP_NO
               AND TO_CHAR(ATT_DATE, 'YYYY-MM-DD') =
                   TO_CHAR(sValidDate, 'yyyy-mm-dd')
               AND SHIFT_NO = 1
               AND ORG_BY = sOrganType;

          EXCEPTION
            WHEN NO_DATA_FOUND THEN
            iCardSignCnt := 0;
          END;
          
            IF (iCardSignCnt>0) THEN
             --增加判斷打卡異常的sCHKIN_CARD或sCHKOUT_CARD是 null,工作時數為應班工時/2,在算曠職的時候已經計算，所以在請假時數不足的時候不要在計算進去，避免扣兩次。 20181106 108978
            BEGIN
            SELECT WORK_HRS * 60
              INTO iWorkMin
              FROM HRP.HRA_CLASSMST
             WHERE CLASS_CODE = iClassKind;
            EXCEPTION
            WHEN OTHERS THEN
              iWorkMin := 0;
            END;
            iRealyWorkMin := iRealyWorkMin + (iWorkMin/2);           
            END IF;      
          END IF;

        END LOOP;

        -- 借休單

        BEGIN
          SELECT NVL(SUM(OTM_HRS) * 60, 0)
            INTO sVacMin
            FROM HRA_OFFREC
           WHERE EMP_NO = sEMP_NO
             AND TO_CHAR(sValidDate, 'YYYY-MM-DD') =
                 TO_CHAR(START_DATE, 'YYYY-MM-DD')
             AND STATUS = 'Y'
             AND item_type = 'O'
             AND ORG_BY = sOrganType;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            sVacMin := 0;
        END;

        iRealyWorkMin := iRealyWorkMin + sVacMin;

        --補休單
        BEGIN
          SELECT NVL(SUM(SUP_HRS) * 60, 0)
            INTO sVacMin
            FROM HRA_SUPMST
           WHERE EMP_NO = sEMP_NO
             AND TO_CHAR(sValidDate, 'YYYY-MM-DD') =
                 TO_CHAR(START_DATE_TMP, 'YYYY-MM-DD')
             AND STATUS = 'Y'
             AND ORG_BY = sOrganType;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            sVacMin := 0;
        END;
DBMS_OUTPUT.put_line('補休單'||sVacMin);
        iRealyWorkMin := iRealyWorkMin + sVacMin;

        -- 電子假卡 時數 -- 可 "跨天" 要注意
        -- 頭尾 注意 即可!!
        BEGIN
          SELECT COUNT(*)
            INTO iCnt
            FROM HRA_EVCREC
           WHERE EMP_NO = sEMP_NO
             AND (TO_CHAR(sValidDate, 'YYYY-MM-DD') BETWEEN
                 TO_CHAR(START_DATE, 'YYYY-MM-DD') AND
                 TO_CHAR(END_DATE, 'YYYY-MM-DD')) -- sphinx  94.09.28
             AND STATUS = 'Y'
             AND ORG_BY = sOrganType;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            iCnt := 0;
        END;
DBMS_OUTPUT.put_line('電子假卡'||iCnt);
        IF iCnt > 0 THEN
          OPEN cursor2(sEMP_NO, sValidDate);
          LOOP
            FETCH cursor2
              INTO vSTART_DATE, vSTART_TIME, vEND_DATE, vEND_TIME, sOrganType;
            EXIT WHEN cursor2%NOTFOUND;

            IF TO_CHAR(sValidDate, 'yyyy-mm-dd') = vSTART_DATE
             OR( TO_CHAR(sValidDate + 1, 'yyyy-mm-dd') = vEND_DATE AND vEND_TIME = '0000' )
            THEN

              BEGIN
              SELECT CHKIN_WKTM,
                     CHKOUT_WKTM,
                     START_REST,
                     END_REST,
                     (SELECT WORK_HRS
                        FROM HRP.HRA_CLASSMST
                       WHERE CLASS_CODE = T1.CLASS_CODE) WORK_HRS
                INTO sCHKIN_WKTM,
                     sCHKOUT_WKTM,
                     sSTART_REST,
                     sEND_REST,
                     sWORK_HRS
                FROM HRP.HRA_CLASSDTL T1
               WHERE CLASS_CODE = iClassKind
                 AND SHIFT_NO = (SELECT MAX(SHIFT_NO)
                                   FROM HRP.HRA_CLASSDTL
                                  WHERE CLASS_CODE = iClassKind  AND SHIFT_NO <> '4');
              EXCEPTION
                WHEN OTHERS THEN
                NULL;
              END;
              
              --請假是同一天
              IF vSTART_DATE = vEND_DATE THEN
                vEND_TIME := vEND_TIME;
              ELSE
              --結束時間為班表時間
                vEND_TIME := sCHKOUT_WKTM;
              END IF;
              
              --JB班休假多天，最後一天檢核開始時間抓班表開始時間 20210901 by108482
              IF (TO_CHAR(sValidDate + 1, 'yyyy-mm-dd') = vEND_DATE AND vEND_TIME = '0000') AND
                 TO_CHAR(sValidDate, 'yyyy-mm-dd') <> vSTART_DATE THEN
                vSTART_TIME := sCHKIN_WKTM;
              END IF;

--DBMS_OUTPUT.put_line('0'||vSTART_TIME||vEND_TIME);
              --開始時間需判斷
              IF SUBSTR(vSTART_TIME,3,4) BETWEEN '00' AND '29' THEN
              vSTART_TIME := SUBSTR(vSTART_TIME,1,2) || '00';
              ELSIF SUBSTR(vSTART_TIME,3,4) BETWEEN '30' AND '59' THEN
              vSTART_TIME := SUBSTR(vSTART_TIME,1,2) || '30';
              END IF;
              
              --結束時間需判斷，取整點(因假卡是半小時為單位,避免誤算曠職) 20210629 by108482
              IF SUBSTR(vEND_TIME,3,4) BETWEEN '01' AND '29' THEN
                vEND_TIME := SUBSTR(vEND_TIME,1,2) || '30';
              ELSIF SUBSTR(vEND_TIME,3,4) BETWEEN '31' AND '59' THEN
                vEND_TIME := to_number(SUBSTR(vEND_TIME,1,2))+1 || '00';
              END IF;
              
              IF vEND_TIME = '2400' THEN 
                vEND_TIME := '0000'; 
                vEND_DATE := to_char(to_date(vEND_DATE,'yyyy/mm/dd')+1, 'yyyy-mm-dd');
              END IF;
              IF LENGTH(vEND_TIME) = 3 THEN
                vEND_TIME := '0'||vEND_TIME;
              END IF;
              
--DBMS_OUTPUT.put_line('sValidDate:'||sValidDate);
DBMS_OUTPUT.put_line('EVC：vEND_DATE:'||vEND_DATE||', vEND_TIME:'||vEND_TIME);
             IF TO_CHAR(sValidDate + 1, 'yyyy-mm-dd') <= vEND_DATE AND vEND_TIME = '0000' THEN

              iRealyWorkMin := iRealyWorkMin +
                               Ehrphra12_Pkg.getoffhrs(TO_CHAR(sValidDate,
                                                               'yyyy-mm-dd'),
                                                       vSTART_TIME,
                                                       TO_CHAR(sValidDate+1,
                                                               'yyyy-mm-dd'),
                                                       vEND_TIME,
                                                       sEMP_NO,sOrganType);
DBMS_OUTPUT.put_line('1:'||iRealyWorkMin);
             ELSIF TO_CHAR(sValidDate+1 , 'yyyy-mm-dd') <= vEND_DATE AND vEND_TIME >= '0000' THEN
              iRealyWorkMin := iRealyWorkMin +              
                               Ehrphra12_Pkg.getoffhrs(TO_CHAR(sValidDate,
                                                               'yyyy-mm-dd'),
                                                       vSTART_TIME,
                                                       TO_CHAR(sValidDate+1,
                                                               'yyyy-mm-dd'),
                                                       vEND_TIME,
                                                       sEMP_NO,sOrganType);              
             
 DBMS_OUTPUT.put_line('3:'||iRealyWorkMin);              
             ELSE
 DBMS_OUTPUT.put_line('2_1:'||iRealyWorkMin);              
              iRealyWorkMin := iRealyWorkMin +
                               Ehrphra12_Pkg.getoffhrs(TO_CHAR(sValidDate,
                                                               'yyyy-mm-dd'),
                                                       vSTART_TIME,
                                                       TO_CHAR(sValidDate,
                                                               'yyyy-mm-dd'),
                                                       vEND_TIME,
                                                       sEMP_NO,sOrganType);
DBMS_OUTPUT.put_line('2:'||iRealyWorkMin);
DBMS_OUTPUT.put_line('vSTART_TIME:'||vSTART_TIME);
DBMS_OUTPUT.put_line('vEND_TIME:'||vEND_TIME);
             END IF;

              -- 請假起時 ~ 班表下班時

            ELSIF TO_CHAR(sValidDate, 'yyyy-mm-dd') = vEND_DATE THEN
              DBMS_OUTPUT.put_line('請假起時 ~ 班表下班時');
              BEGIN
              SELECT CHKIN_WKTM,
                     CHKOUT_WKTM,
                     START_REST,
                     END_REST,
                     (SELECT WORK_HRS
                        FROM HRP.HRA_CLASSMST
                       WHERE CLASS_CODE = T1.CLASS_CODE) WORK_HRS
                INTO sCHKIN_WKTM,
                     sCHKOUT_WKTM,
                     sSTART_REST,
                     sEND_REST,
                     sWORK_HRS
                FROM HRP.HRA_CLASSDTL T1
               WHERE CLASS_CODE = iClassKind
                 AND SHIFT_NO = (SELECT MIN(SHIFT_NO)
                                   FROM HRP.HRA_CLASSDTL
                                  WHERE CLASS_CODE = iClassKind  AND SHIFT_NO <> '4')
                 ;
              EXCEPTION
                WHEN OTHERS THEN
                NULL;
              END;

              vSTART_TIME   := sCHKIN_WKTM;
              iRealyWorkMin := iRealyWorkMin +
                               Ehrphra12_Pkg.getoffhrs(TO_CHAR(sValidDate,
                                                               'yyyy-mm-dd'),
                                                       vSTART_TIME,
                                                       TO_CHAR(sValidDate,
                                                               'yyyy-mm-dd'),
                                                       vEND_TIME,
                                                       sEMP_NO,sOrganType);
--DBMS_OUTPUT.put_line(iRealyWorkMin);
              --班表上班日 ~ 請假迄時

            ELSE
              DBMS_OUTPUT.put_line('班表上班日 ~ 請假迄時');
            
              BEGIN
              SELECT CHKIN_WKTM,
                     CHKOUT_WKTM,
                     START_REST,
                     END_REST,
                     (SELECT WORK_HRS
                        FROM HRP.HRA_CLASSMST
                       WHERE CLASS_CODE = T1.CLASS_CODE) WORK_HRS
                INTO sCHKIN_WKTM,
                     sCHKOUT_WKTM,
                     sSTART_REST,
                     sEND_REST,
                     sWORK_HRS
                FROM HRP.HRA_CLASSDTL T1
               WHERE CLASS_CODE = iClassKind
                 AND SHIFT_NO = (SELECT MIN(SHIFT_NO)
                                   FROM HRP.HRA_CLASSDTL
                                  WHERE CLASS_CODE = iClassKind  AND SHIFT_NO <> '4')
                ;
              EXCEPTION
                WHEN OTHERS THEN
                NULL;
              END;

              iRealyWorkMin := iRealyWorkMin + sWORK_HRS * 60;
--DBMS_OUTPUT.put_line(iRealyWorkMin);
            END IF;

          END LOOP;
          CLOSE cursor2;
        END IF;
    --  dbms_output.put_line('------->' || iClassKind || sEMP_NO);
        -- 應上班分鐘
        BEGIN
        SELECT WORK_HRS * 60
          INTO iWorkMin
          FROM HRP.HRA_CLASSMST
         WHERE CLASS_CODE = iClassKind;
        EXCEPTION WHEN OTHERS THEN
          iWorkMin := 0;
        END;
        --20200115 by108482 ZA班工時歸零
        IF iClassKind = 'ZA' THEN
          iWorkMin := 0;
        END IF;
dbms_output.put_line('iWorkMin:'||iWorkMin||'iRealyWorkMin:'||iRealyWorkMin);

        -- 應出勤時間是否小於等於 總上班時間(出勤+假單)
--dbms_output.put_line(sEMP_NO||sOrganType||to_char(iWorkMin-iRealyWorkMin));
        IF iWorkMin > iRealyWorkMin THEN
          Insufficient_time := iWorkMin - iRealyWorkMin;
          Insufficient_min := iWorkMin - iRealyWorkMin;
          IF late_flag = 'Y' THEN
            late_time := sCHKIN_CARD - sCHKIN_WKTM;
          ELSE
            late_time := 0;
          END IF;
        /*Insufficient_time_tmp := Insufficient_time - trunc(Insufficient_time/60)*60;
        Insufficient_time := trunc(Insufficient_time/60);
        IF (Insufficient_time_tmp =0) THEN
          Insufficient_time_tmp :=0;
        ELSIF (Insufficient_time_tmp <=30) THEN
          Insufficient_time_tmp :=0.5;
        ELSE
          Insufficient_time_tmp :=1;
        END IF;
           Insufficient_time := Insufficient_time + Insufficient_time_tmp;*/
          IF (Insufficient_time/60) > 0.5 AND late_flag = 'Y' THEN
            late_flag := 'Z';
          END IF;
          Insufficient_time := Insufficient_time - late_time;
          IF Insufficient_time < 0 THEN
            Insufficient_time := 0;
          END IF;
dbms_output.put_line('Insufficient_time:'||Insufficient_time||', late_time:'||late_time);
          SELECT CH_NAME, (SELECT CH_NAME FROM HRE_ORGBAS WHERE DEPT_NO = t1.DEPT_NO AND ORGAN_TYPE = t1.ORGAN_TYPE) DEPT_NAME,
           DEPT_NO
            INTO sEMP_NAME, sDEPT_NAME, sDEPT_NO
            FROM HRE_EMPBAS t1
           WHERE EMP_NO = sEMP_NO;
--dbms_output.put_line('HRA_9610_TEMP'||Insufficient_time+Insufficient_time_tmp);
        --     AND ORGAN_TYPE = sOrganType;
/*        IF (TO_CHAR(sValidDate, 'YYYYMMDD') < TO_CHAR(SYSDATE, 'YYYYMMDD')) THEN
        BEGIN
          --排除100812 跨天請假且結束時間0000 之資料
          --IF (sEMP_NO = '101029' AND TO_CHAR(sValidDate, 'YYYY-MM-DD') = '2011-10-13') THEN
          --  NULL;
          --ELSE
          INSERT INTO HRA_9610_TEMP
            (EMP_NO, EMP_NAME, DEPT_NO, DEPT_NAME, VAC_DATE, ORGAN_TYPE)
          VALUES
            (sEMP_NO,
             sEMP_NAME,
             sDEPT_NO,
             sDEPT_NAME,
             TO_CHAR(sValidDate, 'YYYY-MM-DD'),
             sOrganType);
          --END IF;
        EXCEPTION
          WHEN OTHERS THEN
          RtnCode := 0;
        END;
        END IF;*/
        
        END IF;

      END LOOP;

    END LOOP;
    CLOSE cursor1;
    RtnCode := 0;
    RETURN RtnCode;
    NULL;
    <<Continue_ForEach2>>
    NULL;

  END f_set_hra9610temp_without_i;
  
  
/*  --多機構CALL f_set_hra9610temp_table修改完成
  PROCEDURE p_set_hra9610temp_table(sStartDate VARCHAR2,
                                    sEndDate   VARCHAR2) IS

   RtnCode NUMBER;

  BEGIN

    RtnCode := f_set_hra9610temp_table(sStartDate,sEndDate);

  END p_set_hra9610temp_table;*/


END Ehrphra3_Pkg; 
