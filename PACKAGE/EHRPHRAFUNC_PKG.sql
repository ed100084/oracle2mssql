
  CREATE OR REPLACE PACKAGE "HRP"."EHRPHRAFUNC_PKG" IS

  -- Author  : EDWIN
  -- Created : 2004/10/18 上午 09:19:12
  -- Purpose : 出勤函數

  -- Public function and procedure declarations
  FUNCTION F_GETCLASSNAME(CLASSCODE_IN VARCHAR2) RETURN VARCHAR2;

  FUNCTION F_CUTADDHRS(EMPNO_IN     VARCHAR2,
                       CLASSCODE_IN VARCHAR2,
                       ATTDATE_IN   DATE) RETURN NUMBER;

  FUNCTION F_CUTSUPHRS(EMPNO_IN     VARCHAR2,
                       CLASSCODE_IN VARCHAR2,
                       ATTDATE_IN   DATE) RETURN NUMBER;

  FUNCTION F_GETWORKTIME(SCHYM_IN VARCHAR2) RETURN NUMBER;

  FUNCTION F_GETSUPOUT(SCHYM_IN VARCHAR2, EMPNO_IN VARCHAR2) RETURN NUMBER;

  FUNCTION F_GETCONDITION(SCHYM_IN VARCHAR2, EMPNO_IN VARCHAR2)
    RETURN VARCHAR2;

  FUNCTION F_GETDOCGIVEVAC(EMPNO_IN   VARCHAR2,
                           VACYEAR_IN VARCHAR2,
                           VACTYPE_IN VARCHAR2,
                           VACRULE_IN VARCHAR2) RETURN NUMBER;

  FUNCTION F_GETWORKHRS(DEPTNO_IN  VARCHAR2,
                        ATTDATE_IN DATE,
                        SCHKIND_IN VARCHAR2) RETURN NUMBER;

  FUNCTION F_GETCLASSHRS(DEPTNO_IN  VARCHAR2,
                         ATTDATE_IN DATE,
                         SCHKIND_IN VARCHAR2) RETURN NUMBER;

  FUNCTION F_GETOFFAMT(EMPNO_IN     VARCHAR2,
                       DEPTNO_IN    VARCHAR2,
                       ATTDATE_IN   DATE,
                       STARTTIME_IN VARCHAR2,
                       OTMHRS_IN    NUMBER) RETURN NUMBER;

  FUNCTION F_GETWORKHRS(SCHYM_IN VARCHAR2, EMPNO_IN VARCHAR2) RETURN NUMBER;

  --取得當天星期一至五(工作日),六(週末),日及國定假日為(休假日)
  FUNCTION F_GETWEEKTYPE(ATTDATE_IN DATE) RETURN VARCHAR2;

  --取得特休可開始休假日
  FUNCTION F_GETYEARENDAY(COMEDAY VARCHAR2, VACYEAR VARCHAR2) RETURN VARCHAR2;

  --取得年資年
  FUNCTION F_GETSENIORITY_YEAR(COMEDAY VARCHAR2, VACYEAR VARCHAR2)
    RETURN VARCHAR2;

  --取得年資月
  FUNCTION F_GETSENIORITY_MONTH(COMEDAY VARCHAR2, VACYEAR VARCHAR2)
    RETURN VARCHAR2;
  --取得留職停薪(月)
  FUNCTION F_GETLEAVEBETWEENBACK_MONTH(EMPNO    VARCHAR2,
                                       LEAVEDAY VARCHAR2,
                                       BACKDAY  VARCHAR2) RETURN VARCHAR2;

  FUNCTION F_COUNT_TIME(LS_START_DATE DATE,
                        LS_START_TIME VARCHAR2,
                        LS_END_DATE   DATE,
                        LS_END_TIME   VARCHAR2) RETURN NUMBER;
  --取得某一天所上的班
  FUNCTION F_GETCLASSKIND(EMPNO_IN     VARCHAR2,
                          DATE_IN      DATE,
                          ORGANTYPE_IN VARCHAR2) RETURN VARCHAR2;
  -- 取得某一段時間所橫跨的時段
  FUNCTION F_GETSHIFT(CLASSCODE VARCHAR2,
                      STARTIME  VARCHAR2,
                      ENDTIME   VARCHAR2) RETURN VARCHAR2;
  -- 計算請假時數
  -- ps.僅能計算當日
  FUNCTION F_GETVACTIME(EMPNO_IN     VARCHAR2,
                        STRATDATE_IN VARCHAR2,
                        STARTTIME_IN VARCHAR2,
                        ORGANTYPE_IN VARCHAR2,
                        ENDTIME_IN   VARCHAR2) RETURN NUMBER;

  --取得假日別  週六 D , 週日 C ,國定假日 B, 一般日 A
  FUNCTION F_GETNOTEFLAG(STARTDATE VARCHAR2) RETURN VARCHAR2;

  --取得到職是否滿6個月
  FUNCTION F_CHECKCOMEDATEBEFFER6MONTHS(EMP_NO VARCHAR2) RETURN VARCHAR2;

  --BI028報表用
  FUNCTION F_GETHRATIME(EMPNO_IN VARCHAR2,
                        DATE_IN  VARCHAR2,
                        FLAG_IN  VARCHAR2,
                        TYPE_IN  VARCHAR2,
                        NUM_IN   NUMBER) RETURN VARCHAR2;

  --體溫未填寫查看請假紀錄用
  FUNCTION F_GETEVCTIME(EMPNO_IN VARCHAR2, DATE_IN VARCHAR2) RETURN VARCHAR2;

  --判別是否為上班時間(需修改如下個FUNCTION)
  FUNCTION CHECKCLASSTIME(P_EMP_NO          VARCHAR2,
                          P_START_DATE      VARCHAR2,
                          P_START_TIME      VARCHAR2,
                          P_END_DATE        VARCHAR2,
                          P_END_TIME        VARCHAR2,
                          P_CLASS_CODE      VARCHAR2,
                          P_LAST_CLASS_CODE VARCHAR2) RETURN NUMBER;
  --判別是否為上班時間(嘗試修改考慮前日班表問題)
  FUNCTION CHECKCLASSTIME2(P_EMP_NO          VARCHAR2,
                           P_START_DATE      VARCHAR2,
                           P_START_TIME      VARCHAR2,
                           P_END_DATE        VARCHAR2,
                           P_END_TIME        VARCHAR2,
                           P_CLASS_CODE      VARCHAR2,
                           P_LAST_CLASS_CODE VARCHAR2) RETURN NUMBER;
  --傳回是假日註記別
  FUNCTION F_GETHOLIDAY(P_DAY VARCHAR2) RETURN VARCHAR2;
  --判斷兩時間是否連續
  FUNCTION F_TIME_CONTINUOUS(P_EMP_NO     VARCHAR2,
                             P_START_DATE VARCHAR2,
                             P_START_TIME VARCHAR2,
                             P_END_DATE   VARCHAR2,
                             P_END_TIME   VARCHAR2,
                             ORGANTYPE_IN VARCHAR2) RETURN NUMBER;
  --判斷兩時間是否連續（免排班人員）                         
  FUNCTION F_TIME_CONTINUOUS4NOSCH(P_EMP_NO     VARCHAR2,
                                   P_START_DATE VARCHAR2,
                                   P_START_TIME VARCHAR2,
                                   P_END_DATE   VARCHAR2,
                                   P_END_TIME   VARCHAR2,
                                   ORGANTYPE_IN VARCHAR2) RETURN NUMBER;

  --取得連續審核假別連續資訊
  FUNCTION F_GETFLOWMERGEVACTYPE(P_FLOWEVCNO VARCHAR2) RETURN VARCHAR2;

  --連續假取時間
  FUNCTION F_GETFLOWMERGEVACDATA(FLOWEVCNO_IN VARCHAR2, TYPE_IN VARCHAR2)
    RETURN VARCHAR2;

  --取得簽核意見
  FUNCTION F_GETEVCFLOWREMARK(P_EVC_NO VARCHAR2) RETURN VARCHAR2;

  --取得審核者串
  FUNCTION F_USERSIGNMAN(EMPNO_IN VARCHAR2) RETURN VARCHAR2;

  --取免排班打卡的時間及理由
  FUNCTION F_FREESIGNDATA(EMPNO_IN VARCHAR2,
                          DATE_IN  DATE,
                          TYPE_IN  VARCHAR2) RETURN VARCHAR2;

  --確認免排班是否有申請休假,回傳預帶的打卡時間
  FUNCTION F_FREESIGNTIME(EMPNO_IN  VARCHAR2,
                          DATE_IN   DATE,
                          TYPE_IN   VARCHAR2,
                          CHECKTIME VARCHAR2,
                          CLASS_IN  VARCHAR2) RETURN VARCHAR2;
  
  --編外助理打卡作業取出勤記錄用
  FUNCTION F_HRACADSIGNTIME(EMPNO_IN VARCHAR2,
                            DATE_IN  VARCHAR2,
                            TYPE_IN  VARCHAR2) RETURN VARCHAR2;

  --email 功能
  --暫時無用 改hrasend_mail2 JOB
  PROCEDURE HRASEND_MAIL(EMPNO_IN    VARCHAR2,
                         PROCTYPE_IN VARCHAR2,
                         PROCMSG_IN  VARCHAR2,
                         EXUSERID_IN VARCHAR2,
                         RTNCODE     OUT NUMBER);
  --改JOB
  PROCEDURE HRASEND_MAIL2;

  --2020-02-20 108154add sysdate+7 出國假單(一般人員)
  PROCEDURE HRASEND_MAIL_ABROAD;

  --2023-03-23 108154add sysdate+7 出國假單(醫師)
  PROCEDURE HRASEND_MAIL_ABROADDOC;

  --出入境管理-症狀輸入通知
  PROCEDURE HRASEND_MAIL_IMMI(EMPNO_IN VARCHAR2, RTNCODE OUT NUMBER);
  --出入境管理-自動掃描假卡判斷未填通知
  PROCEDURE HRASEND_MAIL_IMMI2;

  --醫師假卡未簽核完成通知
  PROCEDURE DOCUNSIGNAUTOMSG;

  --大昌人員請假通知 20170522 by108482
  PROCEDURE HRASEND_MAIL_EF;

  --確認審核者是否異常 by108482
  PROCEDURE CHECKPERMITID_MAIL;

  --資訊人員隔離通知 20220606 by108482
  PROCEDURE HRASEND_MAIL_IT;

  --檢核信件是否正常發送 20220715 by108482
  PROCEDURE CHECKMORNING_MAIL;

  --寄信
  --mailtype : 1 : 只寄給收件者
  --           2 : 寄給收件者與附件收件者,但不顯示附件收件者 DEBUG好用
  --           3 : 寄給收件者與附件收件者,且顯示附件收件者
  PROCEDURE POST_HTML_MAIL(SENDER       IN VARCHAR2,
                           RECIPIENT    IN VARCHAR2,
                           CC_RECIPIENT IN VARCHAR2,
                           MAILTYPE     IN VARCHAR2,
                           SUBJECT      IN VARCHAR2,
                           MESSAGE      IN VARCHAR2);

  --20211025 測試新exchange server
  PROCEDURE POST_HTML_MAIL2(SENDER       IN VARCHAR2,
                            RECIPIENT    IN VARCHAR2,
                            CC_RECIPIENT IN VARCHAR2,
                            MAILTYPE     IN VARCHAR2,
                            SUBJECT      IN VARCHAR2,
                            MESSAGE      IN VARCHAR2);

  --寄信:直接測試UTF8 -> ROW -> SEND ,沒試用過ipad,沒用BASE64,純粹試解長MAIL
  --mailtype : 1 : 只寄給收件者
  --           2 : 寄給收件者與附件收件者,但不顯示附件收件者 DEBUG好用
  --           3 : 寄給收件者與附件收件者,且顯示附件收件者
  PROCEDURE POST_ORIGIN_HTML_MAIL(SENDER       IN VARCHAR2,
                                  RECIPIENT    IN VARCHAR2,
                                  CC_RECIPIENT IN VARCHAR2,
                                  MAILTYPE     IN VARCHAR2,
                                  SUBJECT      IN VARCHAR2,
                                  MESSAGE      IN VARCHAR2);

  PROCEDURE DELETE_MIS_MSG(MSGNO IN VARCHAR2);

  PROCEDURE POST_MIS_MSG(MSGNO     IN VARCHAR2,
                         SENDER    IN VARCHAR2,
                         RECIPIENT IN VARCHAR2,
                         SUBJECT   IN VARCHAR2,
                         MESSAGE   IN VARCHAR2,
                         MSGDATE   IN VARCHAR2);

  --20231218 by108482 同時發送訊息及信件通知
  PROCEDURE POST_MISMSG_MAIL(MSGNO     IN VARCHAR2,
                             SENDER    IN VARCHAR2,
                             RECIPIENT IN VARCHAR2,
                             SUBJECT   IN VARCHAR2,
                             MESSAGE   IN VARCHAR2,
                             MSGDATE   IN VARCHAR2);
                             
  --計算加班費
  FUNCTION F_countfee(OTMHRS_33 NUMBER,
                          OTMHRS_43 NUMBER,
                          OTMHRS_53 NUMBER,
                          OTMHRS_83 NUMBER,
                          SUPHRS_33 NUMBER,
                          SUPHRS_43 NUMBER,
                          SUPHRS_53 NUMBER,
                          SUPHRS_83 NUMBER,
                          EMPNO_IN  VARCHAR2,
                          SCHYM_IN  VARCHAR2,
                          note_flag VARCHAR2) RETURN NUMBER;

  --確認打卡是否需原因
  FUNCTION f_Check_Cadsign(EmpNo_IN     VARCHAR2,
                           ShiftNo_IN   VARCHAR2,
                           ClassCode_IN VARCHAR2,
                           CheckIn_IN   VARCHAR2,
					                 CardTime_IN  VARCHAR2) RETURN NUMBER;
                             
END EHRPHRAFUNC_PKG;

CREATE OR REPLACE PACKAGE BODY "HRP"."EHRPHRAFUNC_PKG" is

  -- Function and procedure implementations
  -- 取得班別描述
  FUNCTION f_getclassname(ClassCode_IN VARCHAR2) RETURN VARCHAR2 is
    sClassCode VARCHAR2(10) := ClassCode_IN;
    sClassName VARCHAR2(60);
  BEGIN
    BEGIN
      SELECT CLASS_NAME
        INTO sClassName
        FROM HRA_CLASSMST
       WHERE CLASS_CODE = sClassCode;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        sClassName := NULL;
    END;
    RETURN(sClassName);
  END f_getclassname;
  --取得當月積假時數
  FUNCTION f_cutaddhrs(EmpNo_IN     VARCHAR2,
                       ClassCode_IN VARCHAR2,
                       AttDate_IN   DATE) RETURN NUMBER IS
    sEmpNo     VARCHAR2(20) := EmpNo_IN;
    sClassCode VARCHAR2(10) := ClassCode_IN;
    dAttDate   DATE := AttDate_IN;
  
    iHoliHrs   INTEGER;
    dStartDate DATE;
    dEndDate   DATE;
    sVacType   VARCHAR2(1);
    iDay       INTEGER;
    sEvcNo     VARCHAR2(20);
  
  BEGIN
    --  sphinx  94.10.19  義大無此規則
    /*   BEGIN
        SELECT SUM(HOLI_HRS)
          INTO iHoliHrs
          FROM HRA_HOLIDAY
         WHERE HOLI_DATE = dAttDate AND HOLI_TYPE IN ('A', 'D');
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          iHoliHrs := 0;
      END;
    
      IF iHoliHrs IS NULL THEN
        iHoliHrs := 0;
      END IF;
    
      IF iHoliHrs = 0 THEN
        RETURN(0);
      END IF;
    
       IF sClassCode LIKE '8%' OR sClassCode IN ('1000', '9000') OR
         sClassCode IS NULL THEN
        IF sClassCode LIKE '8%' THEN
          BEGIN
            SELECT MAX(EVC_NO)
              INTO sEvcNo
              FROM HRA_EVCREC
             WHERE EMP_NO = sEmpNo AND dAttDate BETWEEN START_DATE AND
                   END_DATE AND STATUS = 'Y';
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              RETURN(0);
          END;
          BEGIN
            SELECT START_DATE, END_DATE, VAC_TYPE
              INTO dStartDate, dEndDate, sVacType
              FROM HRA_EVCREC
             WHERE EVC_NO = sEvcNo;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              RETURN(0);
          END;
        END IF;
    
    
        IF (sVacType IN ('I', 'P', 'W', 'Z') AND sClassCode LIKE '8%') OR
           sClassCode IN ('1000', '9000') OR sClassCode IS NULL THEN
          iDay := dEndDate - dStartDate + 1;
          IF sVacType = 'P' AND iDay < 15 THEN
            RETURN(0);
          ELSE
            RETURN iHoliHrs;
          END IF;
        ELSE
          RETURN(0);
        END IF;
      ELSE
        RETURN(0);
      END IF;
    */
    -- RETURN(iHoliHrs);
    RETURN(0);
  END f_cutaddhrs;

  -- 取得當月補休時數
  FUNCTION f_cutsuphrs(EmpNo_IN     VARCHAR2,
                       ClassCode_IN VARCHAR2,
                       AttDate_IN   DATE) RETURN NUMBER IS
    sEmpNo     VARCHAR2(20) := EmpNo_IN;
    sClassCode VARCHAR2(10) := ClassCode_IN;
    dAttDate   DATE := AttDate_IN;
  
    iHoliHrs   INTEGER;
    dStartDate DATE;
    dEndDate   DATE;
    sVacType   VARCHAR2(1);
    sEvcNo     VARCHAR2(20);
  
  BEGIN
    -- 94.10.14 sphinx  edah 未有排班補休
    /*   BEGIN
        SELECT SUM(HOLI_HRS)
          INTO iHoliHrs
          FROM HRA_HOLIDAY
         WHERE HOLI_DATE = dAttDate AND HOLI_TYPE = 'E';
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          iHoliHrs := 0;
      END;
    
      IF iHoliHrs IS NULL THEN
        iHoliHrs := 0;
      END IF;
    
      IF iHoliHrs = 0 THEN
        RETURN(0);
      END IF;
    
      IF sClassCode LIKE '8%' OR sClassCode IN ('1000', '9000') OR
         sClassCode IS NULL THEN
        IF sClassCode LIKE '8%' THEN
          BEGIN
            SELECT MAX(EVC_NO)
              INTO sEvcNo
              FROM HRA_EVCREC
             WHERE EMP_NO = sEmpNo AND dAttDate BETWEEN START_DATE AND
                   END_DATE AND STATUS = 'Y';
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              RETURN(0);
          END;
    
          BEGIN
            SELECT START_DATE, END_DATE, VAC_TYPE
              INTO dStartDate, dEndDate, sVacType
              FROM HRA_EVCREC
             WHERE EVC_NO = sEvcNo;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              RETURN(0);
          END;
        END IF;
    
        IF (sVacType IN ('I', 'P', 'W', 'Z') AND sClassCode LIKE '8%') OR
           sClassCode IN ('1000', '9000') OR sClassCode IS NULL THEN
          IF sVacType IN ('P', 'W') AND iHoliHrs <= 8 THEN
            RETURN(0);
          ELSE
            RETURN iHoliHrs;
          END IF;
        ELSE
          RETURN(0);
        END IF;
      ELSE
        RETURN(0);
      END IF;
    */
    --RETURN(iHoliHrs);
    RETURN(0);
  END f_cutsuphrs;
  --取得當月應班工時
  FUNCTION f_getworktime(SchYm_IN VARCHAR2) RETURN NUMBER IS
  
    sSchYm     VARCHAR2(7) := SchYm_IN;
    iDays      INTEGER;
    dStartDate DATE;
    dEndDate   DATE;
    iHoliHrs   INTEGER;
    iTotalHrs  INTEGER;
  
  BEGIN
    dStartDate := TO_DATE(sSchYm || '-01', 'YYYY-MM-DD');
    dEndDate   := Last_day(dStartDate);
    iDays      := TO_NUMBER(TO_CHAR(dEndDate, 'DD'));
  
    iTotalHrs := iDays * 8;
  
    BEGIN
      SELECT SUM(HOLI_HRS)
        INTO iHoliHrs
        FROM HRA_HOLIDAY
       WHERE TO_CHAR(HOLI_DATE, 'YYYY-MM') = sSchYm;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        iHoliHrs := 0;
    END;
  
    IF iHoliHrs IS NULL THEN
      iHoliHrs := 0;
    END IF;
  
    RETURN(iTotalHrs - iHoliHrs);
  END f_getworktime;

  --取得當月補休到期
  FUNCTION f_getsupout(SchYm_IN VARCHAR2, EmpNo_IN VARCHAR2) RETURN NUMBER IS
  
    sSchYm    VARCHAR2(7) := SchYm_IN;
    sEmpNo    VARCHAR2(20) := EmpNo_IN;
    nAttValue NUMBER;
    nSupHrs   NUMBER;
    nDiffHrs  NUMBER;
  
  BEGIN
  
    BEGIN
      SELECT SUM(ATT_VALUE)
        INTO nAttValue
        FROM HRA_ATTDTL1
       WHERE TRN_YM < sSchYm
         AND EMP_NO = sEmpNo
         AND ATT_CODE = '108';
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        nAttValue := 0;
    END;
  
    IF nAttValue IS NULL THEN
      nAttValue := 0;
    END IF;
  
    BEGIN
      SELECT SUM(SUP_HRS)
        INTO nSupHrs
        FROM Hra_Classsch_View
       WHERE SCH_YM = sSchYm
         AND EMP_NO = sEmpNo;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        nSupHrs := 0;
    END;
  
    IF nSupHrs IS NULL THEN
      nSupHrs := 0;
    END IF;
  
    nDiffHrs := ROUND(nAttValue + nSupHrs);
  
    IF nDiffHrs > 0 THEN
      RETURN(nDiffHrs);
    ELSE
      RETURN(0);
    END IF;
  
  END f_getsupout;

  -- Function and procedure implementations
  -- 取得班別描述
  FUNCTION f_getcondition(SchYm_IN VARCHAR2, EmpNo_IN VARCHAR2)
    RETURN VARCHAR2 is
    sSchYm   VARCHAR2(10) := SchYm_IN;
    sEmpNo   VARCHAR2(10) := EmpNo_IN;
    sResults VARCHAR2(1);
    iCnt     INTEGER := 0;
    iDays    INTEGER := 0;
  BEGIN
    iDays := TO_NUMBER(TO_CHAR(Last_day(to_date(sSchYm || '-01',
                                                'YYYY-MM-DD')),
                               'DD'));
  
    IF iDays = 28 THEN
      BEGIN
        SELECT COUNT(*)
          INTO iCnt
          FROM hra_classsch
         WHERE hra_classsch.sch_ym = sSchYm
           AND hra_classsch.emp_no = sEmpNo
           AND (hra_classsch.sch_01 is null or hra_classsch.sch_02 is null or
               hra_classsch.sch_03 is null or hra_classsch.sch_04 is null or
               hra_classsch.sch_05 is null or hra_classsch.sch_06 is null or
               hra_classsch.sch_07 is null or hra_classsch.sch_08 is null or
               hra_classsch.sch_09 is null or hra_classsch.sch_10 is null or
               hra_classsch.sch_11 is null or hra_classsch.sch_12 is null or
               hra_classsch.sch_13 is null or hra_classsch.sch_14 is null or
               hra_classsch.sch_15 is null or hra_classsch.sch_16 is null or
               hra_classsch.sch_17 is null or hra_classsch.sch_18 is null or
               hra_classsch.sch_19 is null or hra_classsch.sch_20 is null or
               hra_classsch.sch_21 is null or hra_classsch.sch_22 is null or
               hra_classsch.sch_23 is null or hra_classsch.sch_24 is null or
               hra_classsch.sch_25 is null or hra_classsch.sch_26 is null or
               hra_classsch.sch_27 is null or hra_classsch.sch_28 is null);
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          iCnt := 0;
      END;
    ELSIF iDays = 29 THEN
      BEGIN
        SELECT COUNT(*)
          INTO iCnt
          FROM hra_classsch
         WHERE hra_classsch.sch_ym = sSchYm
           AND hra_classsch.emp_no = sEmpNo
           AND (hra_classsch.sch_01 is null or hra_classsch.sch_02 is null or
               hra_classsch.sch_03 is null or hra_classsch.sch_04 is null or
               hra_classsch.sch_05 is null or hra_classsch.sch_06 is null or
               hra_classsch.sch_07 is null or hra_classsch.sch_08 is null or
               hra_classsch.sch_09 is null or hra_classsch.sch_10 is null or
               hra_classsch.sch_11 is null or hra_classsch.sch_12 is null or
               hra_classsch.sch_13 is null or hra_classsch.sch_14 is null or
               hra_classsch.sch_15 is null or hra_classsch.sch_16 is null or
               hra_classsch.sch_17 is null or hra_classsch.sch_18 is null or
               hra_classsch.sch_19 is null or hra_classsch.sch_20 is null or
               hra_classsch.sch_21 is null or hra_classsch.sch_22 is null or
               hra_classsch.sch_23 is null or hra_classsch.sch_24 is null or
               hra_classsch.sch_25 is null or hra_classsch.sch_26 is null or
               hra_classsch.sch_27 is null or hra_classsch.sch_28 is null or
               hra_classsch.sch_29 is null);
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          iCnt := 0;
      END;
    ELSIF iDays = 30 THEN
      BEGIN
        SELECT COUNT(*)
          INTO iCnt
          FROM hra_classsch
         WHERE hra_classsch.sch_ym = sSchYm
           AND hra_classsch.emp_no = sEmpNo
           AND (hra_classsch.sch_01 is null or hra_classsch.sch_02 is null or
               hra_classsch.sch_03 is null or hra_classsch.sch_04 is null or
               hra_classsch.sch_05 is null or hra_classsch.sch_06 is null or
               hra_classsch.sch_07 is null or hra_classsch.sch_08 is null or
               hra_classsch.sch_09 is null or hra_classsch.sch_10 is null or
               hra_classsch.sch_11 is null or hra_classsch.sch_12 is null or
               hra_classsch.sch_13 is null or hra_classsch.sch_14 is null or
               hra_classsch.sch_15 is null or hra_classsch.sch_16 is null or
               hra_classsch.sch_17 is null or hra_classsch.sch_18 is null or
               hra_classsch.sch_19 is null or hra_classsch.sch_20 is null or
               hra_classsch.sch_21 is null or hra_classsch.sch_22 is null or
               hra_classsch.sch_23 is null or hra_classsch.sch_24 is null or
               hra_classsch.sch_25 is null or hra_classsch.sch_26 is null or
               hra_classsch.sch_27 is null or hra_classsch.sch_28 is null or
               hra_classsch.sch_29 is null or hra_classsch.sch_30 is null);
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          iCnt := 0;
      END;
    ELSE
      BEGIN
        SELECT COUNT(*)
          INTO iCnt
          FROM hra_classsch
         WHERE hra_classsch.sch_ym = sSchYm
           AND hra_classsch.emp_no = sEmpNo
           AND (hra_classsch.sch_01 is null or hra_classsch.sch_02 is null or
               hra_classsch.sch_03 is null or hra_classsch.sch_04 is null or
               hra_classsch.sch_05 is null or hra_classsch.sch_06 is null or
               hra_classsch.sch_07 is null or hra_classsch.sch_08 is null or
               hra_classsch.sch_09 is null or hra_classsch.sch_10 is null or
               hra_classsch.sch_11 is null or hra_classsch.sch_12 is null or
               hra_classsch.sch_13 is null or hra_classsch.sch_14 is null or
               hra_classsch.sch_15 is null or hra_classsch.sch_16 is null or
               hra_classsch.sch_17 is null or hra_classsch.sch_18 is null or
               hra_classsch.sch_19 is null or hra_classsch.sch_20 is null or
               hra_classsch.sch_21 is null or hra_classsch.sch_22 is null or
               hra_classsch.sch_23 is null or hra_classsch.sch_24 is null or
               hra_classsch.sch_25 is null or hra_classsch.sch_26 is null or
               hra_classsch.sch_27 is null or hra_classsch.sch_28 is null or
               hra_classsch.sch_29 is null or hra_classsch.sch_30 is null or
               hra_classsch.sch_28 is null);
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          iCnt := 0;
      END;
    END IF;
  
    IF iCnt = 0 THEN
      sResults := 'A';
    ELSE
      sResults := 'B';
    END IF;
  
    RETURN(sResults);
  END f_getcondition;

  --取得當月補休到期
  FUNCTION f_getdocgivevac(EmpNo_IN   VARCHAR2,
                           VacYear_IN VARCHAR2,
                           VacType_IN VARCHAR2,
                           VacRule_IN VARCHAR2) RETURN NUMBER IS
  
    sEmpNo    VARCHAR2(20) := EmpNo_IN;
    sVacYear  VARCHAR2(4) := VacYear_IN;
    sVacType  VARCHAR2(1) := VacType_IN;
    sVacRule  VARCHAR2(10) := VacRule_IN;
    nVacHrs   NUMBER;
    nVacQty   NUMBER;
    dComeDate DATE;
    sVacYM    VARCHAR2(7);
  
  BEGIN
  
    BEGIN
      SELECT COME_DATE
        INTO dComeDate
        FROM HRE_EMPBAS
       WHERE EMP_NO = sEmpNo;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        dComeDate := NULL;
    END;
  
    IF dComeDate IS NULL THEN
      RETURN(0);
    END IF;
  
    BEGIN
      SELECT VAC_QTY
        INTO nVacQty
        FROM HRA_VCRLDTL
       WHERE VAC_TYPE = sVacType
         AND VAC_RUL = sVacRule;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        nVacQty := 0;
    END;
  
    IF nVacQty IS NULL THEN
      nVacQty := 0;
    END IF;
  
    sVacYM := sVacYear || '-' || sVacRule;
  
    IF sVacType = 'K' THEN
      IF TO_CHAR(dComeDate, 'YYYY-MM') > sVacYM THEN
        nVacHrs := 0;
      ELSE
        nVacHrs := nVacQty * 8;
      END IF;
    END IF;
  
    IF sVacType = 'L' THEN
      IF TO_CHAR(dComeDate, 'YYYY') > sVacYear THEN
        nVacHrs := 0;
      ELSE
        nVacHrs := nVacQty * 8;
      END IF;
    END IF;
  
    RETURN(nVacHrs);
  
  END f_getdocgivevac;

  -- 出勤人力
  FUNCTION f_getworkhrs(DeptNo_IN  VARCHAR2,
                        AttDate_IN DATE,
                        SchKind_IN VARCHAR2) RETURN NUMBER IS
  
    sDeptNo  VARCHAR2(10) := DeptNo_IN;
    dAttDate DATE := AttDate_IN;
    sSchKind VARCHAR2(1) := SchKind_IN;
  
    sAttDate   VARCHAR2(10);
    nCardHrs   NUMBER := 0;
    nNoCardHrs NUMBER := 0;
  
  BEGIN
    sAttDate := TO_CHAR(dAttDate, 'YYYY-MM-DD');
  
    BEGIN
      SELECT sum(hra_classmst.work_hrs / 8)
        INTO nCardHrs
        FROM hra_cadsign_view, hra_classmst
       WHERE (hra_cadsign_view.class_code = hra_classmst.class_code)
         and (hra_cadsign_view.dept_no = sDeptNo AND
             TO_CHAR(hra_cadsign_view.att_date, 'YYYY-MM-DD') = sAttDate AND
             hra_classmst.sch_kind = sSchKind);
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        nCardHrs := 0;
    END;
  
    IF nCardHrs IS NULL THEN
      nCardHrs := 0;
    END IF;
  
    BEGIN
      SELECT sum(hra_classmst.work_hrs / 8) as noatt_hrs
        INTO nNoCardHrs
        FROM hra_classsch_view, hre_profile, hra_classmst
       WHERE (hra_classsch_view.emp_no = hre_profile.emp_no)
         and (hra_classsch_view.class_code = hra_classmst.class_code)
         and ((hra_classsch_view.dept_no = sDeptNo) AND
             (hre_profile.item_type = 'Z') AND
             (hre_profile.item_no = 'EMP01') AND
             (hra_classmst.sch_kind = sSchKind) AND
             --    (to_char(hra_classsch_view.att_date, 'YYYY-MM-DD') = sAttDate));
             (hra_classsch_view.att_date = sAttDate));
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        nNoCardHrs := 0;
    END;
  
    IF nNoCardHrs IS NULL THEN
      nNoCardHrs := 0;
    END IF;
  
    RETURN(nCardHrs + nNoCardHrs);
  END f_getworkhrs;

  FUNCTION f_getclasshrs(DeptNo_IN  VARCHAR2,
                         AttDate_IN DATE,
                         SchKind_IN VARCHAR2) RETURN NUMBER IS
  
    sDeptNo  VARCHAR2(10) := DeptNo_IN;
    dAttDate DATE := AttDate_IN;
    sSchKind VARCHAR2(1) := SchKind_IN;
  
    sAttDate VARCHAR2(10);
    nSchHrs  NUMBER := 0;
  
  BEGIN
    sAttDate := TO_CHAR(dAttDate, 'YYYY-MM-DD');
  
    BEGIN
      SELECT sum(hra_classmst.work_hrs / 8)
        INTO nSchHrs
        FROM hra_classsch_view, hra_classmst
       WHERE (hra_classsch_view.class_code = hra_classmst.class_code)
         and (hra_classsch_view.dept_no = sDeptNo AND
             hra_classmst.sch_kind = sSchKind)
         AND
            --TO_CHAR(hra_classsch_view.att_date, 'YYYY-MM-DD') = sAttDate;
             hra_classsch_view.att_date = sAttDate;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        nSchHrs := 0;
    END;
  
    IF nSchHrs IS NULL THEN
      nSchHrs := 0;
    END IF;
  
    RETURN(nSchHrs);
  END f_getclasshrs;

  FUNCTION f_getoffamt(EmpNo_IN     VARCHAR2,
                       DeptNo_IN    VARCHAR2,
                       AttDate_IN   DATE,
                       StartTime_IN VARCHAR2,
                       OtmHrs_IN    NUMBER) RETURN NUMBER IS
  
    sEmpNo     VARCHAR2(20) := EmpNo_IN;
    sDeptNo    VARCHAR2(10) := DeptNo_IN;
    dAttDate   DATE := AttDate_IN;
    sStartTime VARCHAR2(4) := StartTime_IN;
    nOtmHrs    NUMBER := OtmHrs_IN;
  
    sAttDate  VARCHAR2(10);
    sDontCard VARCHAR2(1);
    iCnt      INTEGER;
    nDutyFee  NUMBER;
  
  BEGIN
    sAttDate := TO_CHAR(dAttDate, 'YYYY-MM-DD');
  
    BEGIN
      SELECT COUNT(*)
        INTO iCnt
        FROM HRE_PROFILE
       WHERE EMP_NO = sEmpNo
         AND ITEM_TYPE = 'Z'
         AND ITEM_NO = 'EMP01';
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        iCnt := 0;
    END;
  
    IF iCnt = 0 THEN
      sDontCard := 'N';
    ELSE
      sDontCard := 'Y';
    END IF;
  
    IF sDontCard = 'Y' THEN
      BEGIN
        SELECT sum(hra_classmst.duty_fee)
          INTO nDutyFee
          FROM hra_classsch_view, hra_classmst
         WHERE (hra_classsch_view.class_code = hra_classmst.class_code)
           and (hra_classsch_view.emp_no = sEmpNo)
         GROUP BY hra_classsch_view.att_date
        HAVING hra_classsch_view.att_date = sAttDate;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          nDutyFee := 0;
      END;
    ELSE
      BEGIN
        SELECT SUM(hra_classmst.duty_fee)
          INTO nDutyFee
          FROM hra_classmst, hra_cadsign_view
         WHERE hra_classmst.class_code = hra_cadsign_view.class_code
           AND hra_cadsign_view.emp_no = sEmpNo
           AND TO_CHAR(hra_cadsign_view.att_date, 'YYYY-MM-DD') = sAttDate;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          nDutyFee := 0;
      END;
    END IF;
  
    IF nDutyFee IS NULL THEN
      nDutyFee := 0;
    END IF;
  
    IF nDutyFee = 0 THEN
      RETURN(0);
    END IF;
  
    IF sDeptNo = '1323' AND nDutyFee = 150 THEN
      IF sStartTime >= '1900' THEN
        RETURN(0);
      ELSE
        RETURN(150);
      END IF;
    END IF;
  
    IF nOtmHrs > 4 THEN
      RETURN(nDutyFee);
    END IF;
  
    IF nDutyFee = 800 THEN
      RETURN(0);
    END IF;
  
    RETURN(TRUNC(nDutyFee * nOtmHrs / 8));
  
  END f_getoffamt;

  -- 月工時
  FUNCTION f_getworkhrs(SchYm_IN VARCHAR2, EmpNo_IN VARCHAR2) RETURN NUMBER IS
  
    sSchYm     VARCHAR2(7) := SchYm_IN;
    sEmpNo     VARCHAR2(20) := EmpNo_IN;
    iDays      INTEGER;
    dStartDate DATE;
    dEndDate   DATE;
    nHoliHrs   NUMBER;
    nTotalHrs  NUMBER;
  
  BEGIN
    dStartDate := TO_DATE(sSchYm || '-01', 'YYYY-MM-DD');
    dEndDate   := Last_day(dStartDate);
    iDays      := TO_NUMBER(TO_CHAR(dEndDate, 'DD'));
  
    nTotalHrs := iDays * 8;
  
    BEGIN
      SELECT sum(add_hrs + sup_hrs + vac_hrs + otm_hrs - off_hrs +
                 cutotm_hrs + cutsup_hrs)
        INTO nHoliHrs
        FROM hra_classsch_view
       WHERE sch_ym = sSchYm
         AND emp_no = sEmpNo;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        nHoliHrs := 0;
    END;
  
    IF nHoliHrs IS NULL THEN
      nHoliHrs := 0;
    END IF;
  
    RETURN(nTotalHrs + nHoliHrs);
  END f_getworkhrs;

  --取得當天星期一至五(工作日),六(週末),日及國定假日為(休假日)
  FUNCTION f_getweektype(Attdate_IN DATE) RETURN VARCHAR2 IS
  
    dAttdate DATE := Attdate_IN;
    sRtnType VARCHAR(1);
  
    sDay VARCHAR(1);
    iCnt INTEGER;
  
  BEGIN
  
    BEGIN
      SELECT COUNT(*)
        INTO iCnt
        FROM HRA_HOLIDAY
       WHERE HOLI_DATE = dAttdate
         AND HOLI_TYPE = 'A';
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        iCnt := 0;
    END;
  
    IF iCnt > 0 THEN
      sRtnType := 'H';
    ELSE
      sDay := TO_CHAR(dAttdate, 'D');
      IF sDay = '7' THEN
        sRtnType := 'W';
      ELSIF sDay = '1' THEN
        sRtnType := 'H';
      ELSE
        sRtnType := 'N';
      END IF;
    END IF;
  
    RETURN(sRtnType);
  END f_getweektype;

  --------------------------------------------------
  --取得特休可開始休假日 by szuhao 2005-11.10
  --------------------------------------------------

  FUNCTION f_getyearenday(comeday VARCHAR2, vacyear VARCHAR2) RETURN VARCHAR2 IS
  
    dcomeday VARCHAR2(10) := comeday;
    dvacyear VARCHAR2(4) := vacyear;
    sRtnType VARCHAR(10);
  
  BEGIN
  
    IF (to_number(SUBSTR(dcomeday, 1, 4), 9999) + 1 <
       to_number(dvacyear, 9999)) THEN
      sRtnType := dvacyear || '-01-01';
    ELSE
      sRtnType := to_char(to_date(dcomeday, 'yyyy-mm-dd') + 365,
                          'yyyy-mm-dd');
    END IF;
  
    RETURN(sRtnType);
  
  END f_getyearenday;
  --------------------------------------------------
  --取得年資年 by szuhao 2005-11.10
  --------------------------------------------------

  FUNCTION f_getseniority_year(comeday VARCHAR2, vacyear VARCHAR2)
    RETURN VARCHAR2 IS
  
    dcomeday VARCHAR2(10) := comeday;
    dvacyear VARCHAR2(4) := vacyear;
    sRtnType NUMBER(10);
  
  BEGIN
    sRtnType := to_number(dvacyear, 9999) -
                to_number(SUBSTR(dcomeday, 1, 4), 9999) - 1;
  
    IF ((12 - to_number(SUBSTR(dcomeday, 6, 2), 99) + 1) >= 12) THEN
      sRtnType := sRtnType + 1;
    END IF;
  
    IF (sRtnType < 0) THEN
      sRtnType := 0;
    END IF;
  
    RETURN(TO_CHAR(sRtnType, 999));
  
  END f_getseniority_year;

  --------------------------------------------------
  --取得年資月 by szuhao 2005-11.10
  --------------------------------------------------

  FUNCTION f_getseniority_month(comeday VARCHAR2, vacyear VARCHAR2)
    RETURN VARCHAR2 IS
  
    dcomeday VARCHAR2(10) := comeday;
    dvacyear VARCHAR2(4) := vacyear;
  
    sRtnType VARCHAR2(2);
  
  BEGIN
  
    sRtnType := 12 - to_number(SUBSTR(dcomeday, 6, 2), 99) + 1;
  
    IF (to_number(dvacyear, 9999) - to_number(SUBSTR(dcomeday, 1, 4), 9999) - 1 < 0 OR
       sRtnType >= 12) THEN
      sRtnType := 0;
    END IF;
  
    RETURN(sRtnType);
  
  END f_getseniority_month;

  --------------------------------------------------
  --取得留職停薪(月) by szuhao 2006-12.14
  --------------------------------------------------

  FUNCTION f_getLeaveBetweenBack_month(empno    VARCHAR2,
                                       leaveday VARCHAR2,
                                       backday  VARCHAR2) RETURN VARCHAR2 IS
  
    dLeave VARCHAR2(10) := leaveday;
    dBack  VARCHAR2(4) := backday;
    dEmpNo VARCHAR2(10) := empno;
  
    sRtnType VARCHAR2(2);
  
  BEGIN
  
    sRtnType := 12;
  
    RETURN(sRtnType);
  
  END f_getLeaveBetweenBack_month;

  /*------------------------------------------
  -- SQL_NAME : f_count_time
  -- 計算兩日期,時間之相差 RETURN 分鐘
  ------------------------------------------*/
  function f_count_time(ls_start_date DATE,
                        ls_start_time varchar2,
                        ls_end_date   DATE,
                        ls_end_time   varchar2) return number is
  
    li_rtn_time number; --結果
    /*
    li_days       number;      --相差天數
    li_start_time number;      --起始時間  單位:分
    li_end_time   number;      --結束時間  單位:分
    li_time       number;      --相差時間  單位:分
    */
    sStartDate varchar2(10);
    sEndDate   varchar2(10);
  
  begin
  
    sStartDate := to_char(ls_start_date, 'yyyy-mm-dd');
    sEndDate   := to_char(ls_end_date, 'yyyy-mm-dd');
  
    li_rtn_time := round(to_number(to_date(sEndDate || ls_end_time,
                                           'yyyy-mm-ddHH24MI') -
                                   (to_date(sStartDate || ls_start_time,
                                            'yyyy-mm-ddHH24MI'))) * 1440);
  
    ---- by szuhao 2008-01-17 fix------
    /* by szuhao 2008-01-17 fix
    --西元日期相減
    li_days := ls_end_date - ls_start_date;
    
    -- 轉換為分
    li_start_time := substr(ls_start_time,1, 2) * 60 + substr(ls_start_time,3, 2) ;
    li_end_time := substr(ls_end_time,1, 2) * 60 + substr(ls_end_time,3, 2) ;
    
    IF li_days = 0 THEN  --同一天
       li_time := li_end_time - li_start_time ;
       IF li_time < 0 THEN
          li_time := li_time + 1440;
       END IF;
    ELSE
       li_time := 1440 - li_start_time + li_end_time + 1440 * (li_days - 1) ;
    END IF ;
    
    -- li_rtn_time := ls_h || ls_m ;
    li_rtn_time := li_time ;
    */
    -----------------
    return li_rtn_time;
  end f_count_time;
  ----------------------------------------------------------------
  -- SQL_NAME : f_getClassKind
  -- 取得某一天所上的班
  -- PS.僅限當日
  -- BY SZUHAO 2006.01.02
  ----------------------------------------------------------------
  FUNCTION f_getClassKind(empno_IN     VARCHAR2,
                          Date_IN      date,
                          OrganType_IN VARCHAR2) RETURN VARCHAR2 IS
    SOrganType VARCHAR2(10);
    iClassCode VARCHAR2(3);
  BEGIN
    SOrganType := OrganType_IN;
    BEGIN
      SELECT DECODE(substr(to_char(Date_IN, 'yyyy-mm-dd'), 9, 10),
                    
                    '01',
                    sch_01,
                    '02',
                    sch_02,
                    '03',
                    sch_03,
                    '04',
                    sch_04,
                    '05',
                    sch_05,
                    
                    '06',
                    sch_06,
                    '07',
                    sch_07,
                    '08',
                    sch_08,
                    '09',
                    sch_09,
                    '10',
                    sch_10,
                    
                    '11',
                    sch_11,
                    '12',
                    sch_12,
                    '13',
                    sch_13,
                    '14',
                    sch_14,
                    '15',
                    sch_15,
                    
                    '16',
                    sch_16,
                    '17',
                    sch_17,
                    '18',
                    sch_18,
                    '19',
                    sch_19,
                    '20',
                    sch_20,
                    
                    '21',
                    sch_21,
                    '22',
                    sch_22,
                    '23',
                    sch_23,
                    '24',
                    sch_24,
                    '25',
                    sch_25,
                    
                    '26',
                    sch_26,
                    '27',
                    sch_27,
                    '28',
                    sch_28,
                    '29',
                    sch_29,
                    '30',
                    sch_30,
                    
                    '31',
                    sch_31)
      
        INTO iClassCode
        FROM hra_classsch
       Where EMP_NO = empno_IN
         AND SCH_YM = to_char(Date_IN, 'yyyy-mm')
         AND ORG_BY = SOrganType;
    
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        iClassCode := 'N/A'; --無排班
        IF iClassCode = '' THEN
          iClassCode := 'N/A';
        END IF;
        RETURN iClassCode;
    END;
    NULL;
    return iClassCode;
  END f_getClassKind;
  ----------------------------------------------------------------
  -- SQL_NAME : f_getShift
  -- 取得某一段時間所橫跨的時段
  -- PS.僅限當日
  -- BY SZUHAO 2006.01.02
  ----------------------------------------------------------------
  FUNCTION f_getShift(ClassCode VARCHAR2,
                      Startime  VARCHAR2,
                      Endtime   VARCHAR2) RETURN VARCHAR2 IS
  
    rShift VARCHAR2(3);
    iShift VARCHAR2(1);
  
    CURSOR cursor1 IS
      SELECT SHIFT_NO
        FROM HRP.HRA_CLASSDTL
       Where CLASS_CODE = ClassCode
         AND (Startime > chkin_wktm OR Endtime > chkin_wktm)
            
         AND SHIFT_NO < 4
       ORDER BY SHIFT_NO ASC;
  
    CURSOR cursor2 IS
      SELECT SHIFT_NO
        FROM HRP.HRA_CLASSDTL
       Where CLASS_CODE = ClassCode
         AND (Startime > chkin_wktm OR Endtime < chkin_wktm)
         AND SHIFT_NO < 4
       ORDER BY SHIFT_NO ASC;
  
  BEGIN
  
    IF Startime < Endtime THEN
    
      OPEN cursor1;
      LOOP
        FETCH cursor1
          INTO iShift;
      
        EXIT WHEN cursor1%NOTFOUND;
      
        rShift := rShift || iShift;
      
        NULL;
        <<Continue_ForEach1>>
        NULL;
      
      END LOOP;
      CLOSE cursor1;
    
    ELSE
      OPEN cursor2;
      LOOP
        FETCH cursor2
          INTO iShift;
      
        EXIT WHEN cursor2%NOTFOUND;
      
        rShift := rShift || iShift;
      
        NULL;
        <<Continue_ForEach1>>
        NULL;
      
      END LOOP;
      CLOSE cursor2;
    END IF;
    NULL;
    return rShift;
  END f_getShift;

  /*------------------------------------------
  -- SQL_NAME : f_getworktime
  -- 計算請假時數
  -- ps. 目前僅能計算當日
  -- RETURN 分鐘 , 0 表是無排班
  ------------------------------------------*/

  FUNCTION f_getvactime(EmpNo_IN     VARCHAR2,
                        StratDate_IN VARCHAR2,
                        StartTime_IN VARCHAR2,
                        OrganType_IN VARCHAR2,
                        EndTime_IN   VARCHAR2) RETURN NUMBER IS
    SOrganType VARCHAR2(10) := OrganType_IN;
    nResults   NUMBER(4);
    sEmpNo     VARCHAR2(20) := EmpNo_IN;
    sStartDate DATE := TO_DATE(StratDate_IN, 'YYYY-MM-DD');
    sStartTime VARCHAR2(4) := StartTime_IN;
    sEndTime   VARCHAR2(4) := EndTime_IN;
    iClassCode VARCHAR2(3);
    --  iSCH VARCHAR2(6) := 'SCH_'||substr(to_char(sStartDate,'yyyy-mm-dd'), 9, 10);
    --iSCH_YM VARCHAR2(7) :=to_char(sStartDate,'yyyy-mm');
    --時段一
    iChkin_wktm1  VARCHAR2(4);
    iChkout_wktm1 VARCHAR2(4);
    iStart_rest1  VARCHAR2(4);
    iEnd_rest1    VARCHAR2(4);
    --時段二
    iChkin_wktm2  VARCHAR2(4);
    iChkout_wktm2 VARCHAR2(4);
    iStart_rest2  VARCHAR2(4);
    iEnd_rest2    VARCHAR2(4);
    --時段三
    iChkin_wktm3  VARCHAR2(4);
    iChkout_wktm3 VARCHAR2(4);
    iStart_rest3  VARCHAR2(4);
    iEnd_rest3    VARCHAR2(4);
  
    sShift VARCHAR2(3);
  
  BEGIN
    nResults := 0;
  
    iClassCode := ehrphrafunc_pkg.f_getClassKind(sEmpNo,
                                                 sStartDate,
                                                 SOrganType);
    -- IF iClassCode='N/A' OR iClassCode='ZZ' then 20161219 班表新增  ZY,ZX
    --20180214 取消ZZ限制 108978
    IF iClassCode = 'N/A' OR iClassCode IN ('ZY', 'ZX') THEN
      nResults := 0; --無排班
      RETURN nResults;
    END IF;
  
    --時段一
    BEGIN
      SELECT CHKIN_WKTM, CHKOUT_WKTM, START_REST, END_REST
        INTO iChkin_wktm1, iChkout_wktm1, iStart_rest1, iEnd_rest1
        FROM hra_classdtl
       WHERE CLASS_CODE = iClassCode
         AND SHIFT_NO = '1';
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        iChkin_wktm1  := '0000';
        iChkout_wktm1 := '0000';
        iStart_rest1  := '0000';
        iEnd_rest1    := '0000';
    END;
  
    --時段二
    BEGIN
      SELECT CHKIN_WKTM, CHKOUT_WKTM, START_REST, END_REST
        INTO iChkin_wktm2, iChkout_wktm2, iStart_rest2, iEnd_rest2
        FROM hra_classdtl
       WHERE CLASS_CODE = iClassCode
         AND SHIFT_NO = '2';
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        iChkin_wktm2  := '0000';
        iChkout_wktm2 := '0000';
        iStart_rest2  := '0000';
        iEnd_rest2    := '0000';
    END;
  
    --時段三
    BEGIN
      SELECT CHKIN_WKTM, CHKOUT_WKTM, START_REST, END_REST
        INTO iChkin_wktm3, iChkout_wktm3, iStart_rest3, iEnd_rest3
        FROM hra_classdtl
       WHERE CLASS_CODE = iClassCode
         AND SHIFT_NO = '3';
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        iChkin_wktm3  := '0000';
        iChkout_wktm3 := '0000';
        iStart_rest3  := '0000';
        iEnd_rest3    := '0000';
    END;
  
    --    判斷 START_TIME ~ END_TIME 恆跨那幾個時段
    --    因為此程式僅能判斷當天,故時段一定是由小至大
    /*
    have RS and RE
    EE <=  RS
    EE > RS AND ES <=RE
    EE > RE AND ES < CE
    EE >= CE
    
    
    No have RS and RE
    EE < CE
    EE >= CE
    */
  
    --取得該段時間所橫跨的時段
    sShift := ehrphrafunc_pkg.f_getShift(iClassCode, sStartTime, sEndTime);
  
    IF sShift IS NOT NULL THEN
      FOR I IN 1 .. LENGTH(sShift) LOOP
      
        IF SUBSTR(sShift, I, 1) = '1' THEN
        
          IF iStart_rest1 = '0' THEN
            --沒有休息時間
          
            IF sStartTime >= iChkin_wktm1 THEN
            
              IF sEndTime >= iChkout_wktm1 THEN
                nResults := ehrphrafunc_pkg.f_count_time(sStartDate,
                                                         sStartTime,
                                                         sStartDate,
                                                         iChkout_wktm1);
              ELSE
                nResults := ehrphrafunc_pkg.f_count_time(sStartDate,
                                                         sStartTime,
                                                         sStartDate,
                                                         sEndTime);
              END IF;
            
            ELSE
            
              IF sEndTime >= iChkout_wktm1 THEN
                nResults := ehrphrafunc_pkg.f_count_time(sStartDate,
                                                         iChkin_wktm1,
                                                         sStartDate,
                                                         iChkout_wktm1);
              ELSE
                nResults := ehrphrafunc_pkg.f_count_time(sStartDate,
                                                         iChkin_wktm1,
                                                         sStartDate,
                                                         sEndTime);
              END IF;
            
            END IF;
          
          ELSE
            --有休息時間
          
            IF sStartTime >= iChkin_wktm1 THEN
            
              IF sStartTime < iStart_rest1 THEN
              
                IF sEndTime <= iStart_rest1 THEN
                
                  nResults := ehrphrafunc_pkg.f_count_time(sStartDate,
                                                           sStartTime,
                                                           sStartDate,
                                                           sEndTime);
                
                ELSIF sEndTime BETWEEN iStart_rest1 AND iEnd_rest1 THEN
                
                  nResults := ehrphrafunc_pkg.f_count_time(sStartDate,
                                                           sStartTime,
                                                           sStartDate,
                                                           iStart_rest1);
                
                ELSIF sEndTime BETWEEN iEnd_rest1 AND iChkout_wktm1 THEN
                
                  nResults := ehrphrafunc_pkg.f_count_time(sStartDate,
                                                           sStartTime,
                                                           sStartDate,
                                                           iStart_rest1) +
                              ehrphrafunc_pkg.f_count_time(sStartDate,
                                                           iEnd_rest1,
                                                           sStartDate,
                                                           sEndTime);
                
                ELSE
                
                  nResults := ehrphrafunc_pkg.f_count_time(sStartDate,
                                                           sStartTime,
                                                           sStartDate,
                                                           iStart_rest1) +
                              ehrphrafunc_pkg.f_count_time(sStartDate,
                                                           iEnd_rest1,
                                                           sStartDate,
                                                           iChkout_wktm1);
                
                END IF;
              
              ELSIF sStartTime BETWEEN iStart_rest1 AND iEnd_rest1 THEN
              
                IF sEndTime BETWEEN iStart_rest1 AND iEnd_rest1 THEN
                
                  nResults := 0;
                
                ELSIF sEndTime <= iChkout_wktm1 THEN
                
                  nResults := ehrphrafunc_pkg.f_count_time(sStartDate,
                                                           iEnd_rest1,
                                                           sStartDate,
                                                           sEndTime);
                
                ELSE
                
                  nResults := ehrphrafunc_pkg.f_count_time(sStartDate,
                                                           iEnd_rest1,
                                                           sStartDate,
                                                           iChkout_wktm1);
                
                END IF;
              
              ELSE
              
                IF sEndTime <= iChkout_wktm1 THEN
                
                  nResults := ehrphrafunc_pkg.f_count_time(sStartDate,
                                                           sStartTime,
                                                           sStartDate,
                                                           sEndTime);
                
                ELSE
                
                  nResults := ehrphrafunc_pkg.f_count_time(sStartDate,
                                                           sStartTime,
                                                           sStartDate,
                                                           iChkout_wktm1);
                
                END IF;
              
              END IF;
            
              --比上班時間早 BASE ON iChkin_wktm1
            ELSE
            
              IF sEndTime <= iStart_rest1 THEN
              
                nResults := ehrphrafunc_pkg.f_count_time(sStartDate,
                                                         iChkin_wktm1,
                                                         sStartDate,
                                                         sEndTime);
              
              ELSIF sEndTime BETWEEN iStart_rest1 AND iEnd_rest1 THEN
              
                nResults := ehrphrafunc_pkg.f_count_time(sStartDate,
                                                         iChkin_wktm1,
                                                         sStartDate,
                                                         iStart_rest1);
              
              ELSIF sEndTime BETWEEN iEnd_rest1 AND iChkout_wktm1 THEN
              
                nResults := ehrphrafunc_pkg.f_count_time(sStartDate,
                                                         iChkin_wktm1,
                                                         sStartDate,
                                                         iStart_rest1) +
                            ehrphrafunc_pkg.f_count_time(sStartDate,
                                                         iEnd_rest1,
                                                         sStartDate,
                                                         sEndTime);
              ELSE
              
                nResults := ehrphrafunc_pkg.f_count_time(sStartDate,
                                                         iChkin_wktm1,
                                                         sStartDate,
                                                         iStart_rest1) +
                            ehrphrafunc_pkg.f_count_time(sStartDate,
                                                         iEnd_rest1,
                                                         sStartDate,
                                                         iChkout_wktm1);
              END IF;
            
            END IF;
          
          END IF;
        
        ELSIF SUBSTR(sShift, I, 1) = '2' THEN
          IF iStart_rest2 = '0' THEN
            --沒有休息時間
          
            IF sStartTime >= iChkin_wktm2 THEN
            
              IF sEndTime >= iChkout_wktm2 THEN
                nResults := ehrphrafunc_pkg.f_count_time(sStartDate,
                                                         sStartTime,
                                                         sStartDate,
                                                         iChkout_wktm2);
              ELSE
                nResults := ehrphrafunc_pkg.f_count_time(sStartDate,
                                                         sStartTime,
                                                         sStartDate,
                                                         sEndTime);
              END IF;
            
            ELSE
            
              IF sEndTime >= iChkout_wktm2 THEN
                nResults := ehrphrafunc_pkg.f_count_time(sStartDate,
                                                         iChkin_wktm2,
                                                         sStartDate,
                                                         iChkout_wktm2);
              ELSE
                nResults := ehrphrafunc_pkg.f_count_time(sStartDate,
                                                         iChkin_wktm2,
                                                         sStartDate,
                                                         sEndTime);
              END IF;
            
            END IF;
          
          ELSE
            --有休息時間
          
            IF sStartTime >= iChkin_wktm2 THEN
            
              IF sStartTime < iStart_rest2 THEN
              
                IF sEndTime <= iStart_rest2 THEN
                
                  nResults := ehrphrafunc_pkg.f_count_time(sStartDate,
                                                           sStartTime,
                                                           sStartDate,
                                                           sEndTime);
                
                ELSIF sEndTime BETWEEN iStart_rest2 AND iEnd_rest2 THEN
                
                  nResults := ehrphrafunc_pkg.f_count_time(sStartDate,
                                                           sStartTime,
                                                           sStartDate,
                                                           iStart_rest2);
                
                ELSIF sEndTime BETWEEN iEnd_rest2 AND iChkout_wktm2 THEN
                
                  nResults := ehrphrafunc_pkg.f_count_time(sStartDate,
                                                           sStartTime,
                                                           sStartDate,
                                                           iStart_rest2) +
                              ehrphrafunc_pkg.f_count_time(sStartDate,
                                                           iEnd_rest2,
                                                           sStartDate,
                                                           sEndTime);
                
                ELSE
                
                  nResults := ehrphrafunc_pkg.f_count_time(sStartDate,
                                                           sStartTime,
                                                           sStartDate,
                                                           iStart_rest2) +
                              ehrphrafunc_pkg.f_count_time(sStartDate,
                                                           iEnd_rest2,
                                                           sStartDate,
                                                           iChkout_wktm2);
                
                END IF;
              
              ELSIF sStartTime BETWEEN iStart_rest2 AND iEnd_rest2 THEN
              
                IF sEndTime BETWEEN iStart_rest2 AND iEnd_rest2 THEN
                
                  nResults := 0;
                
                ELSIF sEndTime <= iChkout_wktm2 THEN
                
                  nResults := ehrphrafunc_pkg.f_count_time(sStartDate,
                                                           iEnd_rest2,
                                                           sStartDate,
                                                           sEndTime);
                
                ELSE
                
                  nResults := ehrphrafunc_pkg.f_count_time(sStartDate,
                                                           iEnd_rest2,
                                                           sStartDate,
                                                           iChkout_wktm2);
                
                END IF;
              
              ELSE
              
                IF sEndTime <= iChkout_wktm2 THEN
                
                  nResults := ehrphrafunc_pkg.f_count_time(sStartDate,
                                                           sStartTime,
                                                           sStartDate,
                                                           sEndTime);
                
                ELSE
                
                  nResults := ehrphrafunc_pkg.f_count_time(sStartDate,
                                                           sStartTime,
                                                           sStartDate,
                                                           iChkout_wktm2);
                
                END IF;
              
              END IF;
            
              --比上班時間早 BASE ON iChkin_wktm2
            ELSE
            
              IF sEndTime <= iStart_rest2 THEN
              
                nResults := ehrphrafunc_pkg.f_count_time(sStartDate,
                                                         iChkin_wktm2,
                                                         sStartDate,
                                                         sEndTime);
              
              ELSIF sEndTime BETWEEN iStart_rest2 AND iEnd_rest2 THEN
              
                nResults := ehrphrafunc_pkg.f_count_time(sStartDate,
                                                         iChkin_wktm2,
                                                         sStartDate,
                                                         iStart_rest2);
              
              ELSIF sEndTime BETWEEN iEnd_rest2 AND iChkout_wktm2 THEN
              
                nResults := ehrphrafunc_pkg.f_count_time(sStartDate,
                                                         iChkin_wktm2,
                                                         sStartDate,
                                                         iStart_rest2) +
                            ehrphrafunc_pkg.f_count_time(sStartDate,
                                                         iEnd_rest2,
                                                         sStartDate,
                                                         sEndTime);
              ELSE
              
                nResults := ehrphrafunc_pkg.f_count_time(sStartDate,
                                                         iChkin_wktm2,
                                                         sStartDate,
                                                         iStart_rest2) +
                            ehrphrafunc_pkg.f_count_time(sStartDate,
                                                         iEnd_rest2,
                                                         sStartDate,
                                                         iChkout_wktm2);
              END IF;
            
            END IF;
          
          END IF;
        
        ELSIF SUBSTR(sShift, I, 1) = '3' THEN
        
          IF iStart_rest3 = '0' THEN
            --沒有休息時間
          
            IF sStartTime >= iChkin_wktm3 THEN
            
              IF sEndTime >= iChkout_wktm3 THEN
                nResults := ehrphrafunc_pkg.f_count_time(sStartDate,
                                                         sStartTime,
                                                         sStartDate,
                                                         iChkout_wktm3);
              ELSE
                nResults := ehrphrafunc_pkg.f_count_time(sStartDate,
                                                         sStartTime,
                                                         sStartDate,
                                                         sEndTime);
              END IF;
            
            ELSE
            
              IF sEndTime >= iChkout_wktm3 THEN
                nResults := ehrphrafunc_pkg.f_count_time(sStartDate,
                                                         iChkin_wktm3,
                                                         sStartDate,
                                                         iChkout_wktm3);
              ELSE
                nResults := ehrphrafunc_pkg.f_count_time(sStartDate,
                                                         iChkin_wktm3,
                                                         sStartDate,
                                                         sEndTime);
              END IF;
            
            END IF;
          
          ELSE
            --有休息時間
          
            IF sStartTime >= iChkin_wktm3 THEN
            
              IF sStartTime < iStart_rest3 THEN
              
                IF sEndTime <= iStart_rest3 THEN
                
                  nResults := ehrphrafunc_pkg.f_count_time(sStartDate,
                                                           sStartTime,
                                                           sStartDate,
                                                           sEndTime);
                
                ELSIF sEndTime BETWEEN iStart_rest3 AND iEnd_rest3 THEN
                
                  nResults := ehrphrafunc_pkg.f_count_time(sStartDate,
                                                           sStartTime,
                                                           sStartDate,
                                                           iStart_rest3);
                
                ELSIF sEndTime BETWEEN iEnd_rest3 AND iChkout_wktm3 THEN
                
                  nResults := ehrphrafunc_pkg.f_count_time(sStartDate,
                                                           sStartTime,
                                                           sStartDate,
                                                           iStart_rest3) +
                              ehrphrafunc_pkg.f_count_time(sStartDate,
                                                           iEnd_rest3,
                                                           sStartDate,
                                                           sEndTime);
                
                ELSE
                
                  nResults := ehrphrafunc_pkg.f_count_time(sStartDate,
                                                           sStartTime,
                                                           sStartDate,
                                                           iStart_rest3) +
                              ehrphrafunc_pkg.f_count_time(sStartDate,
                                                           iEnd_rest3,
                                                           sStartDate,
                                                           iChkout_wktm3);
                
                END IF;
              
              ELSIF sStartTime BETWEEN iStart_rest3 AND iEnd_rest3 THEN
              
                IF sEndTime BETWEEN iStart_rest3 AND iEnd_rest3 THEN
                
                  nResults := 0;
                
                ELSIF sEndTime <= iChkout_wktm3 THEN
                
                  nResults := ehrphrafunc_pkg.f_count_time(sStartDate,
                                                           iEnd_rest3,
                                                           sStartDate,
                                                           sEndTime);
                
                ELSE
                
                  nResults := ehrphrafunc_pkg.f_count_time(sStartDate,
                                                           iEnd_rest3,
                                                           sStartDate,
                                                           iChkout_wktm3);
                
                END IF;
              
              ELSE
              
                IF sEndTime <= iChkout_wktm3 THEN
                
                  nResults := ehrphrafunc_pkg.f_count_time(sStartDate,
                                                           sStartTime,
                                                           sStartDate,
                                                           sEndTime);
                
                ELSE
                
                  nResults := ehrphrafunc_pkg.f_count_time(sStartDate,
                                                           sStartTime,
                                                           sStartDate,
                                                           iChkout_wktm3);
                
                END IF;
              
              END IF;
            
              --比上班時間早 BASE ON iChkin_wktm3
            ELSE
            
              IF sEndTime <= iStart_rest3 THEN
              
                nResults := ehrphrafunc_pkg.f_count_time(sStartDate,
                                                         iChkin_wktm3,
                                                         sStartDate,
                                                         sEndTime);
              
              ELSIF sEndTime BETWEEN iStart_rest3 AND iEnd_rest3 THEN
              
                nResults := ehrphrafunc_pkg.f_count_time(sStartDate,
                                                         iChkin_wktm3,
                                                         sStartDate,
                                                         iStart_rest3);
              
              ELSIF sEndTime BETWEEN iEnd_rest3 AND iChkout_wktm3 THEN
              
                nResults := ehrphrafunc_pkg.f_count_time(sStartDate,
                                                         iChkin_wktm3,
                                                         sStartDate,
                                                         iStart_rest3) +
                            ehrphrafunc_pkg.f_count_time(sStartDate,
                                                         iEnd_rest3,
                                                         sStartDate,
                                                         sEndTime);
              ELSE
              
                nResults := ehrphrafunc_pkg.f_count_time(sStartDate,
                                                         iChkin_wktm3,
                                                         sStartDate,
                                                         iStart_rest3) +
                            ehrphrafunc_pkg.f_count_time(sStartDate,
                                                         iEnd_rest3,
                                                         sStartDate,
                                                         iChkout_wktm3);
              END IF;
            
            END IF;
          
          END IF;
        END IF;
      END LOOP;
    ELSE
      nResults := 0;
    END IF;
    /*
        FOR I IN 1..LENGTH(sShift) LOOP
        sShift :=0;
        END LOOP;
    */
  
    RETURN nResults;
    NULL;
  END f_getvactime;

  --取得假日別  週六 D , 週日 C ,國定假日 B, 一般日 A
  FUNCTION f_getNoteFlag(startdate VARCHAR2) RETURN VARCHAR2 IS
  
    rNoteFlag VARCHAR2(1);
  
    iHOLI_TYPE VARCHAR2(3);
    iHOLI_WEEK VARCHAR2(3);
  
  BEGIN
  
    BEGIN
      SELECT HOLI_TYPE, HOLI_WEEK
        INTO iHOLI_TYPE, iHOLI_WEEK
        FROM HRP.HRA_HOLIDAY
       WHERE TO_CHAR(HOLI_DATE, 'YYYY-MM-DD') = startdate;
    
    EXCEPTION
      WHEN no_data_found THEN
        rNoteFlag := 'A';
    END;
  
    -- IF iHOLI_TYPE = 'D' THEN 20161227 新增例假日，休息日
    IF iHOLI_TYPE IN ('D', 'X') THEN
      IF iHOLI_WEEK = 'SAT' THEN
        rNoteFlag := 'D';
      ELSE
        rNoteFlag := 'C';
      END IF;
    ELSIF iHOLI_TYPE = 'A' THEN
      rNoteFlag := 'B';
    END IF;
  
    return rNoteFlag;
  
  END f_getNoteFlag;

  FUNCTION f_GetHraTime(empno_in VARCHAR2,
                        date_in  VARCHAR2,
                        flag_in  VARCHAR2,
                        type_in  VARCHAR2,
                        num_in   NUMBER) RETURN VARCHAR2 IS
  
    Putout1 VARCHAR2(50);
    Putout2 VARCHAR2(50);
    Putout3 VARCHAR2(50);
    Putout  VARCHAR2(50);
    Ptmp    VARCHAR2(50);
    Ptmp2   VARCHAR2(50);
    Phrs    VARCHAR2(50);
    Phrs2   VARCHAR2(50);
    Pcount  NUMBER;
    Prun    NUMBER;
  
    CURSOR CUR_OTM_A_S IS
      SELECT START_TIME
        FROM HRA_OTMSIGN
       WHERE EMP_NO = empno_in
         AND TO_CHAR(START_DATE, 'yyyy-mm-dd') = date_in
         AND OTM_FLAG = flag_in;
  
    CURSOR CUR_OTM_A_E IS
      SELECT END_TIME
        FROM HRA_OTMSIGN
       WHERE EMP_NO = empno_in
         AND TO_CHAR(END_DATE, 'yyyy-mm-dd') = date_in
         AND OTM_FLAG = flag_in;
  
    CURSOR CUR_ADD IS
      SELECT START_TIME || '-' || END_TIME,
             (CASE
               WHEN OTM_HRS < 1 THEN
                '0' || OTM_HRS
               ELSE
                to_char(OTM_HRS)
             END),
             (CASE
               WHEN OTM_HRS < 1 THEN
                '0' || OTM_HRS
               ELSE
                to_char(OTM_HRS)
             END),
             '補休' || DECODE(STATUS, 'Y', 'Y', 'U')
        FROM HRA_OTMSIGN
       WHERE EMP_NO = EMPNO_IN
         AND TO_CHAR(NVL(START_DATE_TMP, START_DATE), 'yyyy-mm-dd') =
             DATE_IN
         AND STATUS <> 'N'
         AND OTM_FLAG = 'B'
      UNION ALL
      SELECT START_TIME || '-' || END_TIME,
             (CASE
               WHEN OTM_HRS < 1 THEN
                '0' || OTM_HRS
               ELSE
                to_char(OTM_HRS)
             END),
             (CASE
               WHEN SOTM_HRS < 1 THEN
                '0' || SOTM_HRS
               ELSE
                to_char(SOTM_HRS)
             END),
             '加班費' || DECODE(STATUS, 'Y', 'Y', 'U')
        FROM HRA_OFFREC
       WHERE EMP_NO = EMPNO_IN
         AND TO_CHAR(NVL(START_DATE_TMP, START_DATE), 'yyyy-mm-dd') =
             DATE_IN
         AND STATUS <> 'N'
         AND ITEM_TYPE = 'A'
       ORDER BY 1;
  
    CURSOR CUR_VAC IS
      SELECT (CASE
               WHEN START_DATE = END_DATE THEN
                TO_CHAR(START_DATE, 'yyyy-mm-dd') || ' ' || START_TIME || '~' ||
                END_TIME
               ELSE
                TO_CHAR(START_DATE, 'yyyy-mm-dd') || ' ' || START_TIME || '~' ||
                TO_CHAR(END_DATE, 'yyyy-mm-dd') || ' ' || END_TIME
             END),
             VAC_TYPE ||
             (SELECT VAC_NAME
                FROM HRA_VCRLMST
               WHERE VAC_TYPE = HRA_EVCREC.VAC_TYPE) ||
             DECODE(STATUS, 'Y', 'Y', 'U'),
             TO_CHAR(VAC_DAYS * 8 + VAC_HRS)
        FROM HRA_EVCREC
       WHERE EMP_NO = EMPNO_IN
            /*AND TO_CHAR(START_DATE, 'yyyy-mm-dd') = DATE_IN*/
         AND DATE_IN BETWEEN TO_CHAR(START_DATE, 'yyyy-mm-dd') AND
             TO_CHAR(END_DATE, 'yyyy-mm-dd')
         AND STATUS NOT IN ('N', 'D')
      UNION ALL
      SELECT (CASE
               WHEN START_DATE = END_DATE THEN
                TO_CHAR(START_DATE, 'yyyy-mm-dd') || ' ' || START_TIME || '~' ||
                END_TIME
               ELSE
                TO_CHAR(START_DATE, 'yyyy-mm-dd') || ' ' || START_TIME || '~' ||
                TO_CHAR(END_DATE, 'yyyy-mm-dd') || ' ' || END_TIME
             END),
             '用補休' || DECODE(STATUS, 'Y', 'Y', 'U'),
             TO_CHAR(SUP_HRS)
             /*(CASE
               WHEN SUP_HRS < 1 THEN
                '0' || SUP_HRS
               ELSE
                TO_CHAR(SUP_HRS)
             END)*/
        FROM HRA_SUPMST
       WHERE EMP_NO = EMPNO_IN
         AND TO_CHAR(START_DATE_TMP, 'yyyy-mm-dd') = DATE_IN
         AND STATUS <> 'N'
      UNION ALL
      SELECT (CASE
               WHEN START_DATE = END_DATE THEN
                TO_CHAR(START_DATE, 'yyyy-mm-dd') || ' ' || START_TIME || '~' ||
                END_TIME
               ELSE
                TO_CHAR(START_DATE, 'yyyy-mm-dd') || ' ' || START_TIME || '~' ||
                TO_CHAR(END_DATE, 'yyyy-mm-dd') || ' ' || END_TIME
             END),
             '外出單' || DECODE(STATUS, 'Y', 'Y', 'U'),
             TO_CHAR(OUT_DAYS * 8 + OUT_HRS)
        FROM HRA_OUTREC
       WHERE EMP_NO = EMPNO_IN
         AND TO_CHAR(START_DATE, 'yyyy-mm-dd') = DATE_IN
         AND STATUS <> 'N'
         AND PERMIT_HR <> 'Y'
      UNION ALL
      SELECT TO_CHAR(LT_STARTDATE, 'yyyy-mm-dd') || '~' || TO_CHAR(LT_ENDDATE, 'yyyy-mm-dd'),
             '彈性留停' || DECODE(STATUS, 'C01', 'Y', 'F01', 'N', 'U') ||' (天數)',
             TO_CHAR(LT_DAY)
        FROM HRE_UNPAID
       WHERE EMP_NO = EMPNO_IN
         AND DATE_IN BETWEEN TO_CHAR(LT_STARTDATE, 'yyyy-mm-dd') AND
             TO_CHAR(LT_ENDDATE, 'yyyy-mm-dd')
         AND STATUS <> 'F01'
       ORDER BY 1;
  
  BEGIN
    Ptmp    := '';
    Ptmp2   := '';
    Putout1 := '';
    Putout2 := '';
    Putout3 := '';
    Putout  := '';
    Pcount  := 0;
    Prun    := 0;
  
    IF flag_in = 'A' THEN
      IF type_in = 'IN' THEN
        SELECT COUNT(emp_no)
          INTO Pcount
          FROM HRA_OTMSIGN
         WHERE EMP_NO = empno_in
           AND TO_CHAR(START_DATE, 'yyyy-mm-dd') = date_in
           AND OTM_FLAG = flag_in;
        OPEN CUR_OTM_A_S;
        LOOP
          FETCH CUR_OTM_A_S
            INTO Ptmp;
          EXIT WHEN CUR_OTM_A_S%NOTFOUND;
          Prun := Prun + 1;
          IF num_in <= Pcount AND num_in <= Prun THEN
            IF Prun = num_in AND num_in = 1 THEN
              Putout1 := Ptmp;
            ELSIF Prun = num_in AND num_in = 2 THEN
              Putout2 := Ptmp;
            ELSIF Prun = num_in AND num_in = 3 THEN
              Putout3 := Ptmp;
              IF Pcount > 3 THEN
                Putout3 := Putout3 || '有' || Pcount || '筆';
              END IF;
            END IF;
          END IF;
        END LOOP;
        CLOSE CUR_OTM_A_S;
      ELSE
        SELECT COUNT(emp_no)
          INTO Pcount
          FROM HRA_OTMSIGN
         WHERE EMP_NO = empno_in
           AND TO_CHAR(END_DATE, 'yyyy-mm-dd') = date_in
           AND OTM_FLAG = flag_in;
        OPEN CUR_OTM_A_E;
        LOOP
          FETCH CUR_OTM_A_E
            INTO Ptmp2;
          EXIT WHEN CUR_OTM_A_E%NOTFOUND;
          Prun := Prun + 1;
          IF num_in <= Pcount AND num_in <= Prun THEN
            IF Prun = num_in AND num_in = 1 THEN
              Putout1 := Ptmp2;
            ELSIF Prun = num_in AND num_in = 2 THEN
              Putout2 := Ptmp2;
            ELSIF Prun = num_in AND num_in = 3 THEN
              Putout3 := Ptmp2;
              IF Pcount > 3 THEN
                Putout3 := Putout3 || '有' || Pcount || '筆';
              END IF;
            END IF;
          END IF;
        END LOOP;
        CLOSE CUR_OTM_A_E;
      END IF;
    
      /*SELECT COUNT(emp_no)
        INTO Pcount
        FROM HRA_OTMSIGN
       WHERE EMP_NO = empno_in
         AND TO_CHAR(START_DATE, 'yyyy-mm-dd') = date_in
         AND OTM_FLAG = flag_in;
      
      OPEN CUR_OTM_A;
      LOOP
      FETCH CUR_OTM_A
      INTO Ptmp, Ptmp2;
      EXIT WHEN CUR_OTM_A%NOTFOUND;
        Prun := Prun+1;
        IF num_in <= Pcount AND num_in <= Prun THEN
          IF Prun = num_in AND num_in = 1 THEN
            IF type_in = 'IN' THEN Putout1 := Ptmp;
            ELSE Putout1 := Ptmp2;
            END IF;
          ELSIF Prun = num_in AND num_in = 2 THEN
            IF type_in = 'IN' THEN Putout2 := Ptmp;
            ELSE Putout2 := Ptmp2;
            END IF;
          ELSIF Prun = num_in AND num_in = 3 THEN
            IF type_in = 'IN' THEN Putout3 := Ptmp;
            ELSE Putout3 := Ptmp2;
            END IF;
            IF Pcount > 3 THEN
              Putout3 := Putout3||'有'||Pcount||'筆';
            END IF;
          END IF;
        END IF;
      END LOOP;
      CLOSE CUR_OTM_A;*/
    
    ELSIF flag_in = 'ADD' THEN
      SELECT COUNT(*)
        INTO Pcount
        FROM (SELECT EMP_NO
                FROM HRA_OTMSIGN
               WHERE EMP_NO = EMPNO_IN
                 AND TO_CHAR(NVL(START_DATE_TMP, START_DATE), 'yyyy-mm-dd') =
                     DATE_IN
                 AND STATUS <> 'N'
                 AND OTM_FLAG = 'B'
              UNION ALL
              SELECT EMP_NO
                FROM HRA_OFFREC
               WHERE EMP_NO = EMPNO_IN
                 AND TO_CHAR(NVL(START_DATE_TMP, START_DATE), 'yyyy-mm-dd') =
                     DATE_IN
                 AND STATUS <> 'N'
                 AND ITEM_TYPE = 'A');
      IF type_in = 'CON' THEN
        Putout := Pcount;
      ELSE
        OPEN CUR_ADD;
        LOOP
          FETCH CUR_ADD
            INTO Ptmp, Phrs, Phrs2, Ptmp2;
          EXIT WHEN CUR_ADD%NOTFOUND;
          Prun := Prun + 1;
          IF num_in <= Pcount AND num_in <= Prun THEN
            IF Prun = num_in AND num_in = 1 THEN
              IF type_in = 'T' THEN
                Putout1 := Ptmp; --時間
              ELSIF type_in = 'H' THEN
                Putout1 := Phrs; --加班(成)時數
              ELSIF type_in = 'N' THEN
                Putout1 := Ptmp2; --類別(補休 or 加班費)
              ELSE
                Putout1 := Phrs2; --原時數(補休原時數為0)
              END IF;
            ELSIF Prun = num_in AND num_in = 2 THEN
              IF type_in = 'T' THEN
                Putout2 := Ptmp;
              ELSIF type_in = 'H' THEN
                Putout2 := Phrs; --加班(成)時數
              ELSIF type_in = 'N' THEN
                Putout2 := Ptmp2; --類別(補休 or 加班費)
              ELSE
                Putout2 := Phrs2; --原時數(補休原時數為0)
              END IF;
            ELSIF Prun = num_in AND num_in = 3 THEN
              IF type_in = 'T' THEN
                Putout3 := Ptmp;
                IF Pcount > 3 THEN
                  Putout3 := Putout3 || '有' || Pcount || '筆';
                END IF;
              ELSIF type_in = 'H' THEN
                Putout3 := Phrs; --加班(成)時數
              ELSIF type_in = 'N' THEN
                Putout3 := Ptmp2; --類別(補休 or 加班費)
              ELSE
                Putout3 := Phrs2; --原時數(補休原時數為0)
              END IF;
            END IF;
          END IF;
        END LOOP;
        CLOSE CUR_ADD;
      END IF;
    ELSIF flag_in = 'VAC' THEN
      SELECT COUNT(*)
        INTO Pcount
        FROM (SELECT EMP_NO
                FROM HRA_EVCREC
               WHERE EMP_NO = EMPNO_IN
                 AND DATE_IN BETWEEN TO_CHAR(START_DATE, 'yyyy-mm-dd') AND
                     TO_CHAR(END_DATE, 'yyyy-mm-dd')
                 AND STATUS NOT IN ('N', 'D')
              UNION ALL
              SELECT EMP_NO
                FROM HRA_SUPMST
               WHERE EMP_NO = EMPNO_IN
                 AND TO_CHAR(START_DATE_TMP, 'yyyy-mm-dd') = DATE_IN
                 AND STATUS <> 'N'
              UNION ALL
              SELECT EMP_NO
                FROM HRA_OUTREC
               WHERE EMP_NO = EMPNO_IN
                 AND TO_CHAR(START_DATE, 'yyyy-mm-dd') = DATE_IN
                 AND STATUS <> 'N'
                 AND PERMIT_HR <> 'Y'
              UNION ALL
              SELECT EMP_NO
                FROM HRE_UNPAID
               WHERE EMP_NO = EMPNO_IN
                 AND DATE_IN BETWEEN TO_CHAR(LT_STARTDATE, 'yyyy-mm-dd') AND
                     TO_CHAR(LT_ENDDATE, 'yyyy-mm-dd')
                 AND STATUS <> 'F01');
    
      OPEN CUR_VAC;
      LOOP
        FETCH CUR_VAC
          INTO Ptmp, Ptmp2, Phrs;
        EXIT WHEN CUR_VAC%NOTFOUND;
        Prun := Prun + 1;
        IF num_in <= Pcount AND num_in <= Prun THEN
          IF Prun = num_in AND num_in = 1 THEN
            IF type_in = 'T' THEN
              Putout1 := Ptmp;
            ELSIF type_in = 'N' THEN
              Putout1 := Ptmp2; --類別(假卡 or 用補休)
            ELSE
              Putout1 := Phrs; --時數
            END IF;
          ELSIF Prun = num_in AND num_in = 2 THEN
            IF type_in = 'T' THEN
              Putout2 := Ptmp;
            ELSIF type_in = 'N' THEN
              Putout2 := Ptmp2; --類別(假卡 or 用補休)
            ELSE
              Putout2 := Phrs; --時數
            END IF;
          ELSIF Prun = num_in AND num_in = 3 THEN
            IF type_in = 'T' THEN
              Putout3 := Ptmp;
              IF Pcount > 3 THEN
                Putout3 := Putout3 || '有' || Pcount || '筆';
              END IF;
            ELSIF type_in = 'N' THEN
              Putout3 := Ptmp2; --類別(假卡 or 用補休)
            ELSE
              Putout3 := Phrs; --時數
            END IF;
          END IF;
        END IF;
      END LOOP;
      CLOSE CUR_VAC;
    ELSE
      Putout := '無可取值代碼';
    END IF;
  
    IF Putout1 IS NOT NULL THEN
      Putout := Putout1;
    ELSIF Putout2 IS NOT NULL THEN
      Putout := Putout2;
    ELSIF Putout3 IS NOT NULL THEN
      Putout := Putout3;
    END IF;
  
    RETURN Putout;
  END f_GetHraTime;

  FUNCTION f_GetEvcTime(empno_in VARCHAR2, date_in VARCHAR2) RETURN VARCHAR2 IS
  
    Putout VARCHAR2(500);
    Ptmp   VARCHAR2(100);
    Pcount NUMBER;
    Dcount NUMBER;
  
    CURSOR CUR_VAC IS
      SELECT (SELECT VAC_NAME
                FROM HRA_VCRLMST
               WHERE VAC_TYPE = HRA_EVCREC.VAC_TYPE) || ',' || (CASE
               WHEN START_DATE = END_DATE THEN
                TO_CHAR(START_DATE, 'yyyy-mm-dd') || ' ' || START_TIME || '~' ||
                END_TIME
               ELSE
                TO_CHAR(START_DATE, 'yyyy-mm-dd') || ' ' || START_TIME || '~' ||
                TO_CHAR(END_DATE, 'yyyy-mm-dd') || ' ' || END_TIME
             END) || ',' || VAC_DAYS || '天' || VAC_HRS || '小時'
        FROM HRA_EVCREC
       WHERE EMP_NO = EMPNO_IN
         AND DATE_IN BETWEEN TO_CHAR(START_DATE, 'yyyy-mm-dd') AND
             TO_CHAR(END_DATE, 'yyyy-mm-dd')
         AND STATUS NOT IN ('N', 'D')
      UNION ALL
      SELECT '用補休,' || (CASE
               WHEN START_DATE = END_DATE THEN
                TO_CHAR(START_DATE, 'yyyy-mm-dd') || ' ' || START_TIME || '~' ||
                END_TIME
               ELSE
                TO_CHAR(START_DATE, 'yyyy-mm-dd') || ' ' || START_TIME || '~' ||
                TO_CHAR(END_DATE, 'yyyy-mm-dd') || ' ' || END_TIME
             END) || ',' || (CASE
               WHEN SUP_HRS < 1 THEN
                '0' || SUP_HRS
               ELSE
                TO_CHAR(SUP_HRS)
             END) || '小時'
        FROM HRA_SUPMST
       WHERE EMP_NO = EMPNO_IN
         AND TO_CHAR(START_DATE_TMP, 'yyyy-mm-dd') = DATE_IN
         AND STATUS <> 'N';
  
    CURSOR CUR_DOCVAC IS
      SELECT (SELECT VAC_NAME
                FROM HRA_DVCRLMST
               WHERE VAC_TYPE = HRA_DEVCREC.VAC_TYPE) || ',' || (CASE
               WHEN START_DATE = END_DATE THEN
                TO_CHAR(START_DATE, 'yyyy-mm-dd') || ' ' || START_TIME || '~' ||
                END_TIME
               ELSE
                TO_CHAR(START_DATE, 'yyyy-mm-dd') || ' ' || START_TIME || '~' ||
                TO_CHAR(END_DATE, 'yyyy-mm-dd') || ' ' || END_TIME
             END) || ',' || VAC_DAYS || '天' || VAC_HRS || '小時'
        FROM HRA_DEVCREC
       WHERE EMP_NO = EMPNO_IN
         AND DATE_IN BETWEEN TO_CHAR(START_DATE, 'yyyy-mm-dd') AND
             TO_CHAR(END_DATE, 'yyyy-mm-dd')
         AND STATUS NOT IN ('N')
         AND DIS_AGENT NOT IN ('Y');
  
  BEGIN
    Ptmp   := '';
    Putout := '';
    Pcount := 0;
    Dcount := 0;
  
    SELECT COUNT(*)
      INTO Pcount
      FROM (SELECT EMP_NO
              FROM HRA_EVCREC
             WHERE EMP_NO = EMPNO_IN
               AND DATE_IN BETWEEN TO_CHAR(START_DATE, 'yyyy-mm-dd') AND
                   TO_CHAR(END_DATE, 'yyyy-mm-dd')
               AND STATUS NOT IN ('N', 'D')
            UNION ALL
            SELECT EMP_NO
              FROM HRA_SUPMST
             WHERE EMP_NO = EMPNO_IN
               AND TO_CHAR(START_DATE_TMP, 'yyyy-mm-dd') = DATE_IN
               AND STATUS <> 'N');
  
    SELECT COUNT(*)
      INTO Dcount
      FROM HRA_DEVCREC
     WHERE EMP_NO = EMPNO_IN
       AND DATE_IN BETWEEN TO_CHAR(START_DATE, 'yyyy-mm-dd') AND
           TO_CHAR(END_DATE, 'yyyy-mm-dd')
       AND STATUS NOT IN ('N')
       AND DIS_AGENT NOT IN ('Y');
  
    IF Pcount > 0 THEN
      OPEN CUR_VAC;
      LOOP
        FETCH CUR_VAC
          INTO Ptmp;
        EXIT WHEN CUR_VAC%NOTFOUND;
        IF Putout IS NULL THEN
          Putout := Ptmp;
        ELSE
          Putout := Putout || ';' || Ptmp;
        END IF;
      END LOOP;
      CLOSE CUR_VAC;
    ELSIF Dcount > 0 THEN
      OPEN CUR_DOCVAC;
      LOOP
        FETCH CUR_DOCVAC
          INTO Ptmp;
        EXIT WHEN CUR_DOCVAC%NOTFOUND;
        IF Putout IS NULL THEN
          Putout := Ptmp;
        ELSE
          Putout := Putout || ';' || Ptmp;
        END IF;
      END LOOP;
      CLOSE CUR_DOCVAC;
    END IF;
  
    RETURN Putout;
  END f_GetEvcTime;

  FUNCTION f_checkComeDateBeffer6Months(emp_no VARCHAR2) RETURN VARCHAR2 IS
    iemp_no    VARCHAR2(10) := emp_no;
    iCOME_DATE DATE;
    rEffect    VARCHAR2(5) := 'Null';
  BEGIN
  
    BEGIN
      SELECT COME_DATE
        INTO iCOME_DATE
        FROM HRE_EMPBAS
       WHERE EMP_NO = iemp_no;
    
    EXCEPTION
      WHEN no_data_found THEN
        return rEffect;
    END;
  
    IF add_months(iCOME_DATE, 6) < SYSDATE THEN
      rEffect := 'True';
    Else
    
      rEffect := 'False';
    
    END IF;
  
    return rEffect;
  
  END f_checkComeDateBeffer6Months;

  /*------------------------------------------
   判別是否為上班時間  RETURN 1 : 是 , 0 :否
  -------------------------------------------*/

  FUNCTION checkClassTime(p_emp_no          VARCHAR2,
                          p_start_date      VARCHAR2,
                          p_start_time      VARCHAR2,
                          p_end_date        VARCHAR2,
                          p_end_time        VARCHAR2,
                          p_class_code      VARCHAR2,
                          p_Last_Class_code VARCHAR2) RETURN NUMBER IS
  
    sClassCode     VARCHAR2(3);
    sLastClassKind VARCHAR2(3);
    iCnt           INTEGER;
    RtnCode        NUMBER(1);
  
    iCHKIN_WKTM  VARCHAR2(4);
    iCHKOUT_WKTM VARCHAR2(4);
    iSTART_REST  VARCHAR2(4);
    iEND_REST    VARCHAR2(4);
    iSTARTTIME   DATE;
    iENDTIME     DATE;
  
    CURSOR cursor1 IS
      SELECT CHKIN_WKTM, CHKOUT_WKTM, START_REST, END_REST
        FROM HRP.HRA_CLASSDTL
       Where CLASS_CODE = p_class_code
         AND SHIFT_NO <> '4';
  
  BEGIN
  
    RtnCode := 0;
  
    OPEN cursor1;
    LOOP
      FETCH cursor1
        INTO iCHKIN_WKTM, iCHKOUT_WKTM, iSTART_REST, iEND_REST;
      EXIT WHEN cursor1%NOTFOUND;
    
      --是否為跨夜班
      BEGIN
        SELECT COUNT(ROWID)
          INTO iCnt
          FROM HRP.HRA_CLASSDTL
         WHERE CHKIN_WKTM > CASE WHEN CHKOUT_WKTM = '0000' THEN '2400' ELSE CHKOUT_WKTM END AND SHIFT_NO <> '4' AND CLASS_CODE = p_class_code;
      
      EXCEPTION
        WHEN no_data_found THEN
          iCnt := 0;
      END;
    
      IF iCnt > 0 THEN
        --如果為跨夜班,下班日期+1
        iENDTIME := TO_DATE(p_start_date || iCHKOUT_WKTM,
                            'yyyy-mm-ddHH24MI') + 1;
      ELSE
        iENDTIME := TO_DATE(p_start_date || iCHKOUT_WKTM,
                            'yyyy-mm-ddHH24MI');
      END IF;
    
      --ini
      iCnt := 0;
      --是否為0000上班
      BEGIN
        SELECT COUNT(ROWID)
          INTO iCnt
          FROM HRP.HRA_CLASSDTL
         WHERE CHKIN_WKTM = '0000'
           AND CHKIN_FLAG = 'Y'
           AND CLASS_CODE = p_class_code;
      
      EXCEPTION
        WHEN no_data_found THEN
          iCnt := 0;
      END;
    
      /*IF  iCnt > 0 THEN
      iSTARTTIME := TO_DATE( p_start_date ||  iCHKIN_WKTM ,'yyyy-mm-ddHH24MI')+1;
      iENDTIME := TO_DATE( p_start_date ||  iCHKOUT_WKTM ,'yyyy-mm-ddHH24MI')+1;
      ELSE
      iSTARTTIME := TO_DATE( p_start_date ||  iCHKIN_WKTM ,'yyyy-mm-ddHH24MI');
      END IF;*/
      --20190110 調整同checkClassTime2的處理 by108482
      IF iCnt > 0 THEN
        iSTARTTIME := TO_DATE(p_start_date || iCHKIN_WKTM,
                              'yyyy-mm-ddHH24MI') + 1;
      ELSE
        iSTARTTIME := TO_DATE(p_start_date || iCHKIN_WKTM,
                              'yyyy-mm-ddHH24MI');
        iENDTIME   := TO_DATE(p_start_date || iCHKOUT_WKTM,
                              'yyyy-mm-ddHH24MI');
      END IF;
    
      --比較上班時間
      IF ((TO_DATE(p_start_date || p_start_time, 'yyyy-mm-ddHH24MI') +
         0.0001 BETWEEN iSTARTTIME AND iENDTIME) OR
         (TO_DATE(p_end_date || p_end_time, 'yyyy-mm-ddHH24MI') - 0.0001 BETWEEN
         iSTARTTIME AND iENDTIME)) OR
         (iSTARTTIME + 0.0001 BETWEEN
         TO_DATE(p_start_date || p_start_time, 'yyyy-mm-ddHH24MI') AND
         TO_DATE(p_end_date || p_end_time, 'yyyy-mm-ddHH24MI'))
      
       THEN
        RtnCode := 1;
      END IF;
    
      --比較休息時間
      IF RtnCode > 0 THEN
        IF iSTART_REST <> '0' AND iEND_REST <> '0' THEN
          IF (p_start_time BETWEEN iSTART_REST AND iEND_REST AND
             p_end_time BETWEEN iSTART_REST AND iEND_REST) THEN
            RtnCode := 0;
          END IF;
        END IF;
      END IF;
    
    END LOOP;
    CLOSE cursor1;
    NULL;
  
    RETURN RtnCode;
  
  END checkClassTime;

  /*------------------------------------------
   判別是否為上班時間  RETURN 1 : 是 , 0 :否
   modify all function by weichun
  -------------------------------------------*/

  FUNCTION checkClassTime2(p_emp_no          VARCHAR2,
                           p_start_date      VARCHAR2,
                           p_start_time      VARCHAR2,
                           p_end_date        VARCHAR2,
                           p_end_time        VARCHAR2,
                           p_class_code      VARCHAR2,
                           p_Last_Class_code VARCHAR2) RETURN NUMBER IS
  
    sClassCode     VARCHAR2(3);
    sLastClassKind VARCHAR2(3);
    iCnt           INTEGER;
    RtnCode        NUMBER(1);
    iCHKIN_WKTM    VARCHAR2(4);
    iCHKOUT_WKTM   VARCHAR2(4);
    iSTART_REST    VARCHAR2(4);
    iEND_REST      VARCHAR2(4);
    iSTARTTIME     DATE;
    iENDTIME       DATE;
  
    CURSOR cursor1 IS
      SELECT CHKIN_WKTM, CHKOUT_WKTM, START_REST, END_REST
        FROM HRP.HRA_CLASSDTL
       Where CLASS_CODE = p_class_code
         AND SHIFT_NO <> '4';
  
    CURSOR cursor2 IS
      SELECT CHKIN_WKTM, CHKOUT_WKTM, START_REST, END_REST
        FROM HRP.HRA_CLASSDTL
       Where CLASS_CODE = p_Last_Class_code
         AND SHIFT_NO <> '4';
  
  BEGIN
    --ini
    RtnCode := 0;
  
    OPEN cursor1;
    LOOP
      FETCH cursor1
        INTO iCHKIN_WKTM, iCHKOUT_WKTM, iSTART_REST, iEND_REST;
      EXIT WHEN cursor1%NOTFOUND;
    
      --是否為跨夜班
      BEGIN
        SELECT COUNT(ROWID)
          INTO iCnt
          FROM HRP.HRA_CLASSDTL
         Where CHKIN_WKTM > CASE WHEN CHKOUT_WKTM = '0000' THEN '2400' ELSE CHKOUT_WKTM END AND SHIFT_NO <> '4' AND CLASS_CODE = p_class_code;
      EXCEPTION
        WHEN no_data_found THEN
          iCnt := 0;
      END;
    
      IF iCnt > 0 THEN
        --如果為跨夜班,下班日期+1
        iENDTIME := TO_DATE(p_start_date || iCHKOUT_WKTM,
                            'yyyy-mm-ddHH24MI') + 1;
      ELSE
        iENDTIME := TO_DATE(p_start_date || iCHKOUT_WKTM,
                            'yyyy-mm-ddHH24MI');
      END IF;
    
      --ini
      iCnt := 0;
      --是否為0000上班
      BEGIN
        SELECT COUNT(ROWID)
          INTO iCnt
          FROM HRP.HRA_CLASSDTL
         Where CHKIN_WKTM = '0000'
           AND CHKIN_FLAG = 'Y'
           AND CLASS_CODE = p_class_code;
      
      EXCEPTION
        WHEN no_data_found THEN
          iCnt := 0;
      END;
      IF iCnt > 0 THEN
        iSTARTTIME := TO_DATE(p_start_date || iCHKIN_WKTM,
                              'yyyy-mm-ddHH24MI') + 1;
      ELSE
        iSTARTTIME := TO_DATE(p_start_date || iCHKIN_WKTM,
                              'yyyy-mm-ddHH24MI');
        iENDTIME   := TO_DATE(p_start_date || iCHKOUT_WKTM,
                              'yyyy-mm-ddHH24MI');
      END IF;
    
      --比較上班時間
      IF ((TO_DATE(p_start_date || p_start_time, 'yyyy-mm-ddHH24MI') +
         0.0001 BETWEEN iSTARTTIME AND iENDTIME) OR
         (TO_DATE(p_end_date || p_end_time, 'yyyy-mm-ddHH24MI') - 0.0001 BETWEEN
         iSTARTTIME AND iENDTIME)) OR
         (iSTARTTIME + 0.0001 BETWEEN
         TO_DATE(p_start_date || p_start_time, 'yyyy-mm-ddHH24MI') AND
         TO_DATE(p_end_date || p_end_time, 'yyyy-mm-ddHH24MI')) THEN
        RtnCode := 1;
      END IF;
    
      --比較休息時間
      IF RtnCode > 0 THEN
        IF iSTART_REST <> '0' AND iEND_REST <> '0' THEN
          IF (p_start_time BETWEEN iSTART_REST AND iEND_REST AND
             p_end_time BETWEEN iSTART_REST AND iEND_REST) THEN
            RtnCode := 0;
          END IF;
        END IF;
      END IF;
    END LOOP;
    CLOSE cursor1;
  
    --前日班
    OPEN cursor2;
    LOOP
      FETCH cursor2
        INTO iCHKIN_WKTM, iCHKOUT_WKTM, iSTART_REST, iEND_REST;
      EXIT WHEN cursor2%NOTFOUND;
    
      --是否為跨夜班
      BEGIN
        SELECT COUNT(ROWID)
          INTO iCnt
          FROM HRP.HRA_CLASSDTL
         Where CHKIN_WKTM > CASE WHEN CHKOUT_WKTM = '0000' THEN '2400' ELSE CHKOUT_WKTM END AND SHIFT_NO <> '4' AND CLASS_CODE = p_Last_Class_code;
      EXCEPTION
        WHEN no_data_found THEN
          iCnt := 0;
      END;
    
      IF iCnt > 0 THEN
        --如果為跨夜班,前日下班日期-1
        iENDTIME := TO_DATE(p_start_date || iCHKOUT_WKTM,
                            'yyyy-mm-ddHH24MI');
      ELSE
        iENDTIME := TO_DATE(p_start_date || iCHKOUT_WKTM,
                            'yyyy-mm-ddHH24MI') - 1;
      END IF;
    
      --ini
      iCnt := 0;
      --是否為0000上班(前日0000班別特殊處理)
      BEGIN
        SELECT COUNT(ROWID)
          INTO iCnt
          FROM HRP.HRA_CLASSDTL
         Where CHKIN_WKTM = '0000'
           AND CHKIN_FLAG = 'Y'
           AND CLASS_CODE = p_Last_Class_code;
      
      EXCEPTION
        WHEN no_data_found THEN
          iCnt := 0;
      END;
      IF iCnt > 0 THEN
        iSTARTTIME := TO_DATE(p_start_date || iCHKIN_WKTM,
                              'yyyy-mm-ddHH24MI');
        iENDTIME   := TO_DATE(p_start_date || iCHKOUT_WKTM,
                              'yyyy-mm-ddHH24MI');
      ELSE
        iSTARTTIME := TO_DATE(p_start_date || iCHKIN_WKTM,
                              'yyyy-mm-ddHH24MI') - 1;
      END IF;
    
      --比較上班時間
      IF ((TO_DATE(p_start_date || p_start_time, 'yyyy-mm-ddHH24MI') +
         0.0001 BETWEEN iSTARTTIME AND iENDTIME) OR
         (TO_DATE(p_end_date || p_end_time, 'yyyy-mm-ddHH24MI') - 0.0001 BETWEEN
         iSTARTTIME AND iENDTIME)) OR
         (iSTARTTIME + 0.0001 BETWEEN
         TO_DATE(p_start_date || p_start_time, 'yyyy-mm-ddHH24MI') AND
         TO_DATE(p_end_date || p_end_time, 'yyyy-mm-ddHH24MI')) THEN
        RtnCode := 1;
      END IF;
    
      --比較休息時間
      IF RtnCode > 0 THEN
        IF iSTART_REST <> '0' AND iEND_REST <> '0' THEN
          IF (p_start_time BETWEEN iSTART_REST AND iEND_REST AND
             p_end_time BETWEEN iSTART_REST AND iEND_REST) THEN
            RtnCode := 0;
          END IF;
        END IF;
      END IF;
    END LOOP;
    CLOSE cursor2;
  
    return RtnCode;
  END checkClassTime2;
  ----------------------------------------------------------------
  -- SQL_NAME : f_getHoliday
  -- 取得某日的假日註記
  -- return A =>一般上班 , B =>國定假日 , C=>週日 , D=>週六 ,E=>值班
  ----------------------------------------------------------------
  FUNCTION f_getHoliday(p_day VARCHAR2) RETURN VARCHAR2 IS
  
    RtnCode    VARCHAR2(1);
    sDay       VARCHAR2(10) := p_day;
    iHOLI_TYPE VARCHAR2(10);
    iHOLI_WEEK VARCHAR2(10);
  
  BEGIN
    BEGIN
      SELECT HOLI_TYPE, HOLI_WEEK
        INTO iHOLI_TYPE, iHOLI_WEEK
        FROM HRP.HRA_HOLIDAY
       WHERE TO_CHAR(HOLI_DATE, 'YYYY-MM-DD') = sDay;
    
      --IF iHOLI_TYPE = 'D' THEN  --  IF 週休 20161227 區分例假日，休息日
      IF iHOLI_TYPE IN ('D', 'X') THEN
        --  IF 週休
      
        IF iHOLI_WEEK = 'SAT' THEN
          -- IF 週六
        
          RtnCode := 'D';
        END IF;
      
        IF iHOLI_WEEK = 'SUN' THEN
          -- IF 週日
        
          RtnCode := 'C';
        END IF;
      
      ELSIF iHOLI_TYPE = 'A' THEN
        -- IF 國定假日
        RtnCode := 'B';
      END IF;
    
    EXCEPTION
      WHEN no_data_found THEN
        RtnCode := 'A';
    END;
  
    return RtnCode;
  
  END f_getHoliday;

  /*------------------------------------------
  -- SQL_NAME : f_time_continuous
  -- 判別 兩時間是否連續
  -- RETURN 0 : 不連續
            1 : 連續
  ------------------------------------------*/

  FUNCTION f_time_continuous(p_emp_no     VARCHAR2,
                             p_start_date VARCHAR2,
                             p_start_time VARCHAR2,
                             p_end_date   VARCHAR2,
                             P_end_time   VARCHAR2,
                             OrganType_IN VARCHAR2) return NUMBER IS
  
    sEmpNO     VARCHAR2(10) := p_emp_no;
    sStartDate VARCHAR2(10) := p_start_date;
    sEndDate   VARCHAR2(10) := p_end_date;
    sStartTime VARCHAR2(10) := p_start_time;
    sEndTime   VARCHAR2(10) := P_end_time;
    SOrganType VARCHAR2(10) := OrganType_IN;
    iSCH       VARCHAR2(4);
    iSCH1      VARCHAR2(4);
    iSCH2      VARCHAR2(4);
  
    sClassTime1 VARCHAR2(4);
    sClassTime2 VARCHAR2(4);
    nDay        NUMBER;
  
    RtnCode NUMBER;
    nCnt    NUMBER;
  
  BEGIN
  
    nDay    := to_date(p_end_date, 'yyyy-mm-dd') -
               to_date(p_start_date, 'yyyy-mm-dd');
    RtnCode := 0;
  
    IF nDay = 0 THEN
      --同一天 視為連續請假
    
      iSCH1 := ehrphrafunc_pkg.f_getClassKind(sEmpNO,
                                              to_date(sStartDate,
                                                      'yyyy-mm-dd'),
                                              SOrganType);
      iSCH2 := ehrphrafunc_pkg.f_getClassKind(sEmpNO,
                                              to_date(sEndDate, 'yyyy-mm-dd'),
                                              SOrganType);
    
      SELECT MAX(CHKOUT_WKTM)
        INTO sClassTime1
        FROM HRP.HRA_CLASSDTL
       Where CLASS_CODE = iSCH1;
    
      SELECT MIN(CHKIN_WKTM)
        INTO sClassTime2
        FROM HRP.HRA_CLASSDTL
       Where CLASS_CODE = iSCH2;
    
      IF sStartTime >= sClassTime1 AND sEndTime <= sClassTime2 THEN
        RtnCode := 1;
      END IF;
    
    ELSIF nDay = 1 THEN
      -- 間隔一天
      iSCH1 := ehrphrafunc_pkg.f_getClassKind(sEmpNO,
                                              to_date(sStartDate,
                                                      'yyyy-mm-dd'),
                                              SOrganType);
      iSCH2 := ehrphrafunc_pkg.f_getClassKind(sEmpNO,
                                              to_date(sEndDate, 'yyyy-mm-dd'),
                                              SOrganType);
    
      --IF iSCH1 = 'ZZ' OR iSCH2 = 'ZZ' THEN 20161219班別新增 ZX,ZY
      --20180725 108978 增加ZQ
      IF iSCH1 IN ('ZZ', 'ZX', 'ZX', 'ZQ') OR
         iSCH2 IN ('ZZ', 'ZY', 'ZX', 'ZQ') THEN
        RtnCode := 1;
      ELSE
        SELECT MAX(CHKOUT_WKTM)
          INTO sClassTime1
          FROM HRP.HRA_CLASSDTL
         Where CLASS_CODE = iSCH1;
      
        SELECT MIN(CHKIN_WKTM)
          INTO sClassTime2
          FROM HRP.HRA_CLASSDTL
         Where CLASS_CODE = iSCH2;
      
        IF sStartTime >= sClassTime1 AND sEndTime <= sClassTime2 THEN
          RtnCode := 1;
        END IF;
      END IF;
    ELSE
      -- 間隔二天以上,需判斷班表有無 ZZ 班
      nCnt := 0;
      FOR i IN 1 .. nDay LOOP
      
        iSCH := ehrphrafunc_pkg.f_getClassKind(sEmpNO,
                                               to_date(p_start_date,
                                                       'yyyy-mm-dd') + i,
                                               SOrganType);
      
        --IF iSCH = 'ZZ' THEN 20161219 班別新增 ZX,ZY
        --20180725 108978 增加ZQ
        IF iSCH in ('ZZ', 'ZX', 'ZY', 'ZQ') THEN
          nCnt := nCnt + 1;
        END IF;
      
      END LOOP;
    
      IF nCnt = nDay - 1 THEN
      
        iSCH1 := ehrphrafunc_pkg.f_getClassKind(sEmpNO,
                                                to_date(sStartDate,
                                                        'yyyy-mm-dd'),
                                                SOrganType);
        iSCH2 := ehrphrafunc_pkg.f_getClassKind(sEmpNO,
                                                to_date(sEndDate,
                                                        'yyyy-mm-dd'),
                                                SOrganType);
      
        SELECT MAX(CHKOUT_WKTM)
          INTO sClassTime1
          FROM HRP.HRA_CLASSDTL
         Where CLASS_CODE = iSCH1;
      
        SELECT MIN(CHKIN_WKTM)
          INTO sClassTime2
          FROM HRP.HRA_CLASSDTL
         Where CLASS_CODE = iSCH2;
      
        IF sStartTime >= sClassTime1 AND sEndTime <= sClassTime2 THEN
          RtnCode := 1;
        END IF;
      
      END IF;
    END IF;
  
    NULL;
    <<Continue_ForEach1>>
    NULL;
  
    RETURN RtnCode;
  
  end f_time_continuous;

  /*------------------------------------------
  -- SQL_NAME : f_time_continuous4nosch
  -- 判別 兩時間是否連續
  -- RETURN 0 : 不連續
            1 : 連續
  ------------------------------------------*/

  FUNCTION f_time_continuous4nosch(p_emp_no     VARCHAR2,
                                   p_start_date VARCHAR2,
                                   p_start_time VARCHAR2,
                                   p_end_date   VARCHAR2,
                                   P_end_time   VARCHAR2,
                                   OrganType_IN VARCHAR2) return NUMBER IS
  
    sEmpNO     VARCHAR2(10) := p_emp_no;
    sStartDate VARCHAR2(10) := p_start_date;
    sEndDate   VARCHAR2(10) := p_end_date;
    sStartTime VARCHAR2(10) := p_start_time;
    sEndTime   VARCHAR2(10) := P_end_time;
    SOrganType VARCHAR2(10) := OrganType_IN;
    iSCH       VARCHAR2(4);
    iSCH1      VARCHAR2(4);
    iSCH2      VARCHAR2(4);
  
    sClassTime1 VARCHAR2(4);
    sClassTime2 VARCHAR2(4);
    nDay        NUMBER;
  
    RtnCode NUMBER;
    nCnt    NUMBER;
    v_lower NUMBER := 1;
    v_upper NUMBER;
  
    CheckEndCnt  NUMBER;
    CheckEndTime VARCHAR2(10);
  
  BEGIN
  
    SELECT COUNT(*)
      INTO CheckEndCnt
      FROM HR_CODEDTL
     WHERE CODE_TYPE = 'HRA78'
       AND CODE_NO = (SELECT dept_no FROM hre_empbas WHERE emp_no = sEmpNO);
    --20210507 108482 部門在參數裡的下班時間為1700
    IF CheckEndCnt = 0 THEN
      CheckEndTime := '1730';
    ELSE
      CheckEndTime := '1700';
    END IF;
  
    --20181210 108978 修正開始時間大於結束時間日期會判斷?負數的bug      
    IF (to_date(p_start_date, 'yyyy-mm-dd') >
       to_date(p_end_date, 'yyyy-mm-dd')) THEN
      sStartDate := p_end_date;
      sEndDate   := p_start_date;
      nDay       := to_date(p_start_date, 'yyyy-mm-dd') -
                    to_date(p_end_date, 'yyyy-mm-dd');
    ELSE
      nDay := to_date(p_end_date, 'yyyy-mm-dd') -
              to_date(p_start_date, 'yyyy-mm-dd');
    END IF;
  
    v_upper := nDay;
    RtnCode := 0;
  
    IF nDay = 0 THEN
      --同一天 視為連續請假
    
      /*    iSCH1   := ehrphrafunc_pkg.f_getClassKind (sEmpNO , to_date(sStartDate,'yyyy-mm-dd'),SOrganType);
      iSCH2   := ehrphrafunc_pkg.f_getClassKind (sEmpNO , to_date(sEndDate,'yyyy-mm-dd'),SOrganType);
      
      SELECT MAX(CHKOUT_WKTM)
        INTO sClassTime1
        FROM HRP.HRA_CLASSDTL
       Where CLASS_CODE = iSCH1;
      
      SELECT MIN(CHKIN_WKTM)
        INTO sClassTime2
        FROM HRP.HRA_CLASSDTL
       Where CLASS_CODE = iSCH2;*/
    
      --IF sStartTime >= '1730' AND sEndTime <= '0800' THEN
      IF sStartTime >= CheckEndTime AND sEndTime <= '0800' THEN
        RtnCode := 1;
      ELSIF sStartTime = '1200' AND (sEndTime BETWEEN '1200' AND '1330') THEN
        RtnCode := 1;
      ELSIF sStartTime = sEndTime THEN
        RtnCode := 1;
      END IF;
    
    ELSIF nDay = 1 THEN
      -- 間隔一天
      /*    iSCH1   := ehrphrafunc_pkg.f_getClassKind (sEmpNO , to_date(sStartDate,'yyyy-mm-dd'),SOrganType);
      iSCH2   := ehrphrafunc_pkg.f_getClassKind (sEmpNO , to_date(sEndDate,'yyyy-mm-dd'),SOrganType);*/
    
      --IF iSCH1 = 'ZZ' OR iSCH2 = 'ZZ' THEN 20161219班別新增 ZX,ZY
      /*     IF iSCH1 IN('ZZ','ZX','ZY') OR iSCH2 IN ('ZZ','ZY','ZX') THEN
       RtnCode := 1;
       ELSE
      SELECT MAX(CHKOUT_WKTM)
        INTO sClassTime1
        FROM HRP.HRA_CLASSDTL
       Where CLASS_CODE = iSCH1;
      
      SELECT MIN(CHKIN_WKTM)
        INTO sClassTime2
        FROM HRP.HRA_CLASSDTL
       Where CLASS_CODE = iSCH2;*/
    
      --IF sStartTime >= '1730' AND sEndTime <= '0800' THEN
      IF sStartTime >= CheckEndTime AND sEndTime <= '0800' THEN
        RtnCode := 1;
      END IF;
    
    ELSE
      --間隔1天以上判斷是否有假日 20181210 108978
      FOR i IN v_lower .. v_upper - 1 LOOP
        SELECT COUNT(*)
          INTO nCnt
          FROM hra_holiday
         WHERE holi_yy =
               TO_CHAR(to_date(sStartDate, 'yyyy-mm-dd') + i, 'YYYY')
           AND holi_date = to_date(sStartDate, 'yyyy-mm-dd') + i;
      
        IF (nCnt = 0) THEN
          RtnCode := nCnt;
          GOTO Continue_ForEach1;
        END IF;
      
        RtnCode := nCnt;
        IF sStartTime >= CheckEndTime AND sEndTime <= '0800' THEN
          RtnCode := 1;
        ELSE
          RtnCode := 0;
        END IF;
      END LOOP;
    
    END IF;
  
    NULL;
    <<Continue_ForEach1>>
    NULL;
  
    RETURN RtnCode;
  
  end f_time_continuous4nosch;

  FUNCTION f_getFlowmergeVacType(p_flowevcno VARCHAR2) RETURN VARCHAR2 IS
    Rtnvalue VARCHAR2(300);
    boolf    VARCHAR2(1);
    RtnCode  VARCHAR2(4000);
    CURSOR cursor1 IS
      select vac_name
        from hra_vcrlmst
       where vac_type in (select vac_type
                            from hra_evcrec t1
                           where flow_merge_no = p_flowevcno
                           group by vac_type);
  BEGIN
    RtnCode := '合併假：';
    boolf   := '0';
    OPEN cursor1;
    LOOP
      FETCH cursor1
        INTO Rtnvalue;
      EXIT WHEN cursor1%NOTFOUND;
      if (boolf = '0') then
        boolf := '1';
      else
        RtnCode := RtnCode || '、';
      end if;
      RtnCode := RtnCode || Rtnvalue;
    END LOOP;
    CLOSE cursor1;
    RETURN RtnCode;
  END f_getFlowmergeVacType;
  
  FUNCTION f_getFlowmergeVacData(flowevcno_in VARCHAR2, type_in VARCHAR2) RETURN VARCHAR2 IS
  startdate DATE;
  enddate DATE;
  starttime VARCHAR2(4);
  endtime VARCHAR2(4);
  BEGIN
    SELECT MIN(start_date), MAX(end_date)
      INTO startdate, enddate
      FROM hra_evcrec
     WHERE flow_merge_no = flowevcno_in;
    
    SELECT start_time
      INTO starttime
      FROM hra_evcrec
     WHERE flow_merge_no = flowevcno_in
       AND start_date = startdate
       AND rownum = 1
       ORDER BY start_time;
       
    SELECT end_time
      INTO endtime
      FROM hra_evcrec
     WHERE flow_merge_no = flowevcno_in
       AND end_date = enddate
       AND rownum = 1
       ORDER BY end_time DESC;
    IF type_in = 's' THEN
      RETURN starttime;
    ELSIF type_in = 'e' THEN
      RETURN endtime;
    ELSE
      RETURN '';
    END IF;
  END f_getFlowmergeVacData;

  FUNCTION f_getevcflowremark(p_evc_no VARCHAR2) RETURN VARCHAR2 IS
    Rtnvalue VARCHAR2(800);
    boolf    VARCHAR2(1);
    RtnCode  VARCHAR2(4000);
    CURSOR cursor1 IS
      SELECT (select ch_name
                from hre_empbas
               where emp_no = HraEvcFlow.PERMIT_ID
                 AND ORGAN_TYPE =
                     (SELECT ORG_BY FROM HRA_EVCREC WHERE EVC_NO = p_evc_no)) || '(' ||
             (select ch_name
                from hre_posmst
               where pos_no = (select pos_no
                                 from hre_empbas
                                where emp_no = HraEvcFlow.PERMIT_ID
                                  and ORGAN_TYPE =
                                      (SELECT ORG_BY
                                         FROM HRA_EVCREC
                                        WHERE EVC_NO = p_evc_no))) ||
             ')(分機:' || (select ext_tel
                           from hre_adrbook
                          where emp_no = HraEvcFlow.PERMIT_ID) || '):' ||
             CASE HraEvcflow.STATUS
               WHEN 'U' THEN
                '請示'
               WHEN 'D' THEN
                '取消'
               WHEN 'N' THEN
                '不准'
               WHEN 'Y' THEN
                '准'
               ELSE
                ''
             END || 'abdc簽核意見:' || nvl(HraEvcflow.PERMIT_REMARK, '(無)') || ', ' ||
             to_char(LAST_UPDATE_DATE, 'yyyy-mm-dd')
        FROM HRA_EVCFLOW HraEvcflow
       WHERE HraEvcflow.EVC_NO = p_evc_no;
  BEGIN
    RtnCode := '';
    boolf   := '0';
    OPEN cursor1;
    LOOP
      FETCH cursor1
        INTO Rtnvalue;
      EXIT WHEN cursor1%NOTFOUND;
      if (boolf = '0') then
        boolf := '1';
      else
        RtnCode := RtnCode || 'cadb';
      end if;
      RtnCode := RtnCode || Rtnvalue;
    END LOOP;
    CLOSE cursor1;
    RETURN RtnCode;
  END f_getevcflowremark;

  FUNCTION f_userSignman(EmpNo_IN VARCHAR2) RETURN VARCHAR2 IS
    vEmpno     VARCHAR2(20) := EmpNo_IN;
    vSignMan   VARCHAR2(20);
    vDeptChief VARCHAR2(2);
    vOut       VARCHAR2(50);
  BEGIN
    vOut := NULL;
    LOOP
      SELECT USER_SIGNMAN, DEPT_CHIEF
        INTO vSignMan, vDeptChief
        FROM HRE_EMPBAS
       WHERE EMP_NO = vEmpno;
      
      IF vOut IS NULL THEN
        vOut := vEmpno;
      END IF;
      
      IF vDeptChief <> 'Y' THEN
        IF vOut IS NULL THEN
          vOut := vEmpno || ',' || vSignMan;
        ELSE
          vOut := vOut || ',' || vSignMan;
        END IF;
        vEmpno := vSignMan;
      END IF;
      EXIT WHEN vDeptChief = 'Y';
    END LOOP;
  
    RETURN vOut;
  END f_userSignman;
  
  FUNCTION f_FreesignData(EmpNo_IN VARCHAR2, Date_IN DATE, Type_IN VARCHAR2) RETURN VARCHAR2 IS 
  --Type_IN: in取上班卡時間, out取下班卡時間, inrea取上班卡理由前兩碼, outrea取下班卡理由前兩碼,
  --Type_IN: inreano取上班卡理由後兩碼, outreano取下班卡理由後兩碼, inreadesc取上班卡理由文字, outreadesc取下班卡理由文字
    min_signdate DATE;
    max_signdate DATE;
    output VARCHAR2(60);
    inrea      VARCHAR2(4);
    inreano    VARCHAR2(4);
    inreadesc  VARCHAR2(60);
    outrea     VARCHAR2(4);
    outreano   VARCHAR2(4);
    outreadesc VARCHAR2(60);
  BEGIN
    SELECT MIN(SIGN_DATE)
      INTO min_signdate
      FROM HRA_FREESIGN
     WHERE EMP_NO = EmpNo_IN
       AND trunc(SIGN_DATE) = Date_IN
       AND SIGNIN = 'IN'
       AND SERVER_IP <> 'mis';
    
    SELECT MAX(SIGN_DATE)
      INTO max_signdate
      FROM HRA_FREESIGN
     WHERE EMP_NO = EmpNo_IN
       AND trunc(SIGN_DATE) = Date_IN
       AND SIGNIN = 'OUT'
       AND SERVER_IP <> 'mis';
    
    IF min_signdate IS NOT NULL THEN
      SELECT substr(REANO,1,2), substr(REANO,3,2), 
             (SELECT CODE_NAME FROM HR_CODEBAS WHERE CODE_TYPE = 'HRA34' AND CODE_NO || CODE_DTL = REANO)
        INTO inrea, inreano, inreadesc
        FROM HRA_FREESIGN
       WHERE EMP_NO = EmpNo_IN
         AND SIGN_DATE = min_signdate
         AND SIGNIN = 'IN'
         AND SERVER_IP <> 'mis';
    END IF;
       
    IF max_signdate IS NOT NULL THEN
      SELECT substr(REANO,1,2), substr(REANO,3,2), 
             (SELECT CODE_NAME FROM HR_CODEBAS WHERE CODE_TYPE = 'HRA34' AND CODE_NO || CODE_DTL = REANO)
        INTO outrea, outreano, outreadesc
        FROM HRA_FREESIGN
       WHERE EMP_NO = EmpNo_IN
         AND SIGN_DATE = max_signdate
         AND SIGNIN = 'OUT'
         AND SERVER_IP <> 'mis';
    END IF;
    
    IF Type_IN = 'in' THEN
      IF min_signdate IS NOT NULL THEN
        output := to_char(min_signdate, 'HH24MI');
      ELSE
        output := NULL;
      END IF;
    ELSIF Type_IN = 'out' THEN
      IF max_signdate IS NOT NULL THEN
        output := to_char(max_signdate, 'HH24MI');
      ELSE
        output := NULL;
      END IF;
    ELSIF Type_IN = 'inrea' THEN
      output := inrea;
    ELSIF Type_IN = 'outrea' THEN
      output := outrea;
    ELSIF Type_IN = 'inreano' THEN
      output := inreano;
    ELSIF Type_IN = 'outreano' THEN
      output := outreano;
    ELSIF Type_IN = 'inreadesc' THEN
      output := inreadesc;
    ELSIF Type_IN = 'outreadesc' THEN
      output := outreadesc;
    END IF;
    
    RETURN output;
  END f_FreesignData;
  
  FUNCTION f_FreesignTime(EmpNo_IN VARCHAR2, Date_IN DATE, Type_IN VARCHAR2, 
                          CheckTime VARCHAR2, Class_IN VARCHAR2) RETURN VARCHAR2 IS 
    suphrs NUMBER;
    evchrs NUMBER;
    output VARCHAR2(70);
    supstart VARCHAR2(4);
    supend   VARCHAR2(4);
    evcstart VARCHAR2(4);
    evcend   VARCHAR2(4);
    
    CURSOR cur_evcdata IS
    SELECT DISTINCT CASE WHEN A.VAC_TYPE IN ('E','P','S','U') 
           THEN NVL(SUBSTR(M.VAC_NAME, 1, INSTR(M.VAC_NAME, '(', 1, 1) - 1), M.VAC_NAME)||'('||D.RUL_NAME||')'
           ELSE NVL(SUBSTR(M.VAC_NAME, 1, INSTR(M.VAC_NAME, '(', 1, 1) - 1), M.VAC_NAME) END AS VACNAME
      FROM HRA_EVCREC A, HRA_VCRLMST M, HRA_VCRLDTL D
     WHERE EMP_NO = EmpNo_IN
       AND Date_IN BETWEEN START_DATE AND END_DATE
       AND STATUS NOT IN ('N','D')
       AND A.VAC_TYPE = M.VAC_TYPE
       AND A.VAC_RUL = D.VAC_RUL;
    rec_evcdata cur_evcdata%ROWTYPE;
    vactype VARCHAR2(100);
  BEGIN
    output := NULL;
    vactype := NULL;
    
    IF Class_IN LIKE 'Z%' THEN
      BEGIN
      SELECT HOLI_NAME
        INTO output
        FROM HRA_HOLIDAY
       WHERE HOLI_DATE = Date_IN;
      EXCEPTION WHEN OTHERS THEN
        output := NULL;
      END;
      IF output IS NOT NULL THEN
        GOTO Continue_ForEach1;
      END IF;
    END IF;
    
    SELECT NVL(SUM(SUP_HRS),0)
      INTO suphrs
      FROM HRA_SUPMST
     WHERE EMP_NO = EmpNo_IN
       AND START_DATE = Date_IN
       AND STATUS <> 'N';
       
    SELECT NVL(SUM(VAC_DAYS*8+VAC_HRS),0)
      INTO evchrs
      FROM HRA_EVCREC
     WHERE EMP_NO = EmpNo_IN
       AND START_DATE = Date_IN
       AND STATUS NOT IN ('N','D');
    
    IF suphrs <> 0 THEN
      SELECT START_TIME, END_TIME
        INTO supstart, supend
        FROM HRA_SUPMST
       WHERE EMP_NO = EmpNo_IN
         AND START_DATE = Date_IN
         AND STATUS <> 'N';
    END IF;
    
    IF evchrs <> 0 THEN
      SELECT MIN(START_TIME), MAX(END_TIME)
        INTO evcstart, evcend
        FROM HRA_EVCREC
       WHERE EMP_NO = EmpNo_IN
         AND START_DATE = Date_IN
         AND STATUS <> 'N';
      OPEN cur_evcdata;
      LOOP
      FETCH cur_evcdata
      INTO rec_evcdata;
      EXIT WHEN cur_evcdata%NOTFOUND;
        IF vactype IS NULL THEN
          vactype := rec_evcdata.vacname;
        ELSE
          vactype := vactype||','||rec_evcdata.vacname;
        END IF;
      END LOOP;
      CLOSE cur_evcdata;
    ELSE
      SELECT NVL(SUM(VAC_DAYS*8+VAC_HRS),0)
        INTO evchrs
        FROM HRA_EVCREC
       WHERE EMP_NO = EmpNo_IN
         AND END_DATE = Date_IN
         AND STATUS NOT IN ('N','D');
      IF evchrs <> 0 THEN
        SELECT MIN(START_TIME), MAX(END_TIME)
          INTO evcstart, evcend
          FROM HRA_EVCREC
         WHERE EMP_NO = EmpNo_IN
           AND END_DATE = Date_IN
           AND STATUS <> 'N';
        OPEN cur_evcdata;
        LOOP
        FETCH cur_evcdata
        INTO rec_evcdata;
        EXIT WHEN cur_evcdata%NOTFOUND;
          IF vactype IS NULL THEN
            vactype := rec_evcdata.vacname;
          ELSE
            vactype := vactype||','||rec_evcdata.vacname;
          END IF;
        END LOOP;
        CLOSE cur_evcdata;
      ELSE
        SELECT NVL(SUM(VAC_DAYS*8+VAC_HRS),0)
          INTO evchrs
          FROM HRA_EVCREC
         WHERE EMP_NO = EmpNo_IN
           AND START_DATE < Date_IN
           AND END_DATE > Date_IN
           AND STATUS NOT IN ('N','D');
        IF evchrs <> 0 THEN
          SELECT MIN(START_TIME), MAX(END_TIME)
            INTO evcstart, evcend
            FROM HRA_EVCREC
           WHERE EMP_NO = EmpNo_IN
             AND START_DATE < Date_IN
             AND END_DATE > Date_IN
             AND STATUS <> 'N';
          OPEN cur_evcdata;
          LOOP
          FETCH cur_evcdata
          INTO rec_evcdata;
          EXIT WHEN cur_evcdata%NOTFOUND;
            IF vactype IS NULL THEN
              vactype := rec_evcdata.vacname;
            ELSE
              vactype := vactype||','||rec_evcdata.vacname;
            END IF;
          END LOOP;
          CLOSE cur_evcdata;
        END IF;
      END IF;
    END IF;
    
    IF suphrs <> 0 AND evchrs = 0 THEN
      IF suphrs >= 8 THEN
        output := 'NO';
        IF Type_IN IN ('inreadesc', 'outreadesc') THEN
          output := '補休假';
        END IF;
      ELSE
        IF Type_IN IN ('in', 'inreadesc') THEN
          IF supstart = CheckTime THEN --從上班時間開始休
            output := supend;
            IF Class_IN = 'DK' AND supend BETWEEN '1200' AND '1330' THEN
              output := '1330';
            ELSIF Class_IN = 'BE' AND supend BETWEEN '1200' AND '1300' THEN
              output := '1300';
            END IF;
            IF Type_IN IN ('inreadesc') THEN
              output := '補休假';
            END IF;
          ELSE
            output := CheckTime;
          END IF;
        ELSIF Type_IN IN ('out', 'outreadesc') THEN 
          IF supend = CheckTime THEN --休到下班時間
            output := supstart;
            IF Class_IN = 'DK' AND supstart BETWEEN '1200' AND '1330' THEN
              output := '1200';
            ELSIF Class_IN = 'BE' AND supstart BETWEEN '1200' AND '1300' THEN
              output := '1200';
            END IF;
            IF Type_IN IN ('outreadesc') THEN
              output := '補休假';
            END IF;
          ELSE
            output := CheckTime;
          END IF;
        END IF;
      END IF;
    ELSIF suphrs = 0 AND evchrs <> 0 THEN
      IF evchrs < 8 THEN --確定只請一天內
        IF Type_IN IN ('in', 'inreadesc') THEN
          IF evcstart = CheckTime THEN --從上班時間開始休
            output := evcend;
            IF Class_IN = 'DK' AND evcend BETWEEN '1200' AND '1330' THEN
              output := '1330';
            ELSIF Class_IN = 'BE' AND evcend BETWEEN '1200' AND '1300' THEN
              output := '1300';
            END IF;
            IF Type_IN IN ('inreadesc') THEN
              output := vactype;
            END IF;
          ELSE
            output := CheckTime;
          END IF;
        ELSIF Type_IN IN ('out', 'outreadesc') THEN 
          IF evcend = CheckTime THEN --休到下班時間
            output := evcstart;
            IF Class_IN = 'DK' AND evcstart BETWEEN '1200' AND '1330' THEN
              output := '1200';
            ELSIF Class_IN = 'BE' AND evcstart BETWEEN '1200' AND '1300' THEN
              output := '1200';
            END IF;
            IF Type_IN IN ('outreadesc') THEN
              output := vactype;
            END IF;
          ELSE
            output := CheckTime;
          END IF;
        END IF;
      ELSE --請一天(含)以上，該天不需打卡
        output := 'NO';
        IF Type_IN IN ('inreadesc', 'outreadesc') THEN
          output := vactype;
        END IF;
      END IF;
    ELSIF suphrs <> 0 AND evchrs <> 0 THEN
      IF suphrs + evchrs < 8 THEN --確定只請一天內
        IF supstart > evcstart THEN --補休時間早於假卡時間
          NULL;
        END IF;
      ELSE --請一天(含)以上，該天不需打卡
        output := 'NO';
        IF Type_IN IN ('inreadesc', 'outreadesc') THEN
          output := vactype;
        END IF;
      END IF;
    ELSIF suphrs = 0 AND evchrs = 0 THEN
      output := CheckTime;
    END IF;
    
    IF output IS NULL THEN
      output := CheckTime;
    END IF;
    
    NULL;
    <<Continue_ForEach1>>
    NULL;
    
    RETURN output;
  END f_FreesignTime;
  
  FUNCTION f_HraCadsignTime(EmpNo_IN VARCHAR2,
                            Date_IN  VARCHAR2,
                            Type_IN  VARCHAR2) RETURN VARCHAR2 IS
  ClassCode   VARCHAR2(3);
  CntCad      NUMBER := 0;
  CntOut      NUMBER := 0;
  CntEvc1     NUMBER := 0;
  CntEvc2     NUMBER := 0;
  CntEvc3     NUMBER := 0;
  CntEvc4     NUMBER := 0;
  CntSup      NUMBER := 0;
  CntUncard1  NUMBER := 0;
  CntUncard2  NUMBER := 0;
  StartDate   VARCHAR2(10);
  StartTime   VARCHAR2(4);
  StartUncard VARCHAR2(1);
  EndDate     VARCHAR2(10);
  EndTime     VARCHAR2(4);
  EndUncard   VARCHAR2(1);
  ChkinWktm   VARCHAR2(4);
  ChkoutWktm  VARCHAR2(4);
  ChkinDate   VARCHAR2(10);
  ChkinCard   VARCHAR2(4);
  ChkinUncard VARCHAR2(1);
  ChkoutDate  VARCHAR2(10);
  ChkoutCard  VARCHAR2(4);
  ChkoutUncard VARCHAR2(1);
  OutStartDate VARCHAR2(10);
  OutStartTime VARCHAR2(4);
  OutEndDate   VARCHAR2(10);
  OutEndTime   VARCHAR2(4);
  EvcStartDate VARCHAR2(10);
  EvcStartTime VARCHAR2(4);
  EvcEndDate   VARCHAR2(10);
  EvcEndTime   VARCHAR2(4);
  VacMessage   VARCHAR2(200);
  OutStatus    VARCHAR2(100);
  EvcStatus    VARCHAR2(100);
  VacStatus    VARCHAR2(200);
  BEGIN
    SELECT EHRPHRAFUNC_PKG.F_GETCLASSKIND(EmpNo_IN,
                                          TO_DATE(Date_IN, 'yyyy/mm/dd'),
                                          NVL((SELECT ORGAN_TYPE
                                                 FROM HRE_EMPBAS_MON
                                                WHERE YYMM = substr(Date_IN,1,7)
                                                  AND EMP_NO = EmpNo_IN),
                                              (SELECT ORGAN_TYPE
                                                 FROM HRE_EMPBAS
                                                WHERE EMP_NO = EmpNo_IN))) AS 
      INTO ClassCode
      FROM dual;
    
    IF ClassCode LIKE 'Z%' THEN
      StartTime := '0000';
      StartUncard := 'N';
      EndTime := '0000';
      EndUncard := 'N';
    ELSIF ClassCode <> 'N/A' THEN
      SELECT CHKIN_WKTM, CHKOUT_WKTM
        INTO ChkinWktm, ChkoutWktm
        FROM HRA_CLASSDTL
       WHERE CLASS_CODE = ClassCode
         AND SHIFT_NO = '1';
      SELECT COUNT(*)
        INTO CntCad
        FROM HRA_CADSIGN
       WHERE EMP_NO = EmpNo_IN
         AND ATT_DATE = TO_DATE(Date_IN, 'yyyy/mm/dd');
      SELECT COUNT(*)
        INTO CntUncard1
        FROM HRA_UNCARD
       WHERE EMP_NO = EmpNo_IN
         AND CLASS_DATE = TO_DATE(Date_IN, 'yyyy/mm/dd')
         AND STATUS NOT IN ('N')
         AND UNCARD_TIME = 'A1';
      SELECT COUNT(*)
        INTO CntUncard2
        FROM HRA_UNCARD
       WHERE EMP_NO = EmpNo_IN
         AND CLASS_DATE = TO_DATE(Date_IN, 'yyyy/mm/dd')
         AND STATUS NOT IN ('N')
         AND UNCARD_TIME = 'A2';
      SELECT COUNT(*)
        INTO CntOut
        FROM HRA_OUTREC
       WHERE EMP_NO = EmpNo_IN
         AND START_DATE = TO_DATE(Date_IN, 'yyyy/mm/dd')
         AND STATUS NOT IN ('N')
         AND PERMIT_HR = 'N';
      SELECT COUNT(*)
        INTO CntEvc1
        FROM HRA_EVCREC
       WHERE EMP_NO = EmpNo_IN
         AND VAC_TYPE IN ('B','P')
         AND START_DATE = TO_DATE(Date_IN, 'yyyy/mm/dd')
         AND STATUS NOT IN ('N','D');
      IF CntEvc1 = 0 THEN
        SELECT COUNT(*)
          INTO CntEvc2 --出勤日等於假卡結束日期
          FROM HRA_EVCREC
         WHERE EMP_NO = EmpNo_IN
           AND VAC_TYPE IN ('B','P')
           AND END_DATE = TO_DATE(Date_IN, 'yyyy/mm/dd')
           AND STATUS NOT IN ('N','D');
      ELSE
        CntEvc2 := 0;
      END IF;
      IF CntEvc1 = 0 AND CntEvc2 = 0 THEN
        SELECT COUNT(*)
          INTO CntEvc3 --出勤日介於假卡起訖期間
          FROM HRA_EVCREC
         WHERE EMP_NO = EmpNo_IN
           AND VAC_TYPE IN ('B','P')
           AND TO_DATE(Date_IN, 'yyyy/mm/dd') > START_DATE
           AND TO_DATE(Date_IN, 'yyyy/mm/dd') < END_DATE
           AND STATUS NOT IN ('N','D');
      ELSE
        CntEvc3 := 0;
      END IF;
      IF CntEvc1 = 0 AND CntEvc2 = 0 AND CntEvc3 = 0 THEN
        SELECT COUNT(*)
          INTO CntEvc4 --確認是否有非公假或因公外出的休假
          FROM HRA_EVCREC
         WHERE EMP_NO = EmpNo_IN
           AND VAC_TYPE NOT IN ('B','P')
           AND TO_DATE(Date_IN, 'yyyy/mm/dd') BETWEEN START_DATE AND END_DATE
           AND STATUS NOT IN ('N','D');
        SELECT COUNT(*)
          INTO CntSup --確認是否有用補休
          FROM HRA_SUPMST
         WHERE EMP_NO = EmpNo_IN
           AND START_DATE = TO_DATE(Date_IN, 'yyyy/mm/dd')
           AND STATUS NOT IN ('N','D');
      ELSE
        CntEvc4 := 0;
        CntSup :=0;
      END IF;
      IF CntCad <> 0 THEN
        SELECT NVL(CHKIN_CARD, ChkinWktm), (CASE WHEN CHKIN_CARD IS NULL THEN 'Y' ELSE 'N' END),
               NVL(CHKOUT_CARD, ChkoutWktm), (CASE WHEN CHKOUT_CARD IS NULL THEN 'Y' ELSE 'N' END),
               (CASE WHEN NIGHT_FLAG = 'Y' AND ChkinWktm < ChkoutWktm AND
                     NVL(CHKIN_CARD, ChkinWktm) > NVL(CHKOUT_CARD, ChkoutWktm) THEN TO_CHAR(ATT_DATE - 1, 'yyyy-mm-dd')
                ELSE TO_CHAR(ATT_DATE, 'yyyy-mm-dd') END),
               (CASE WHEN NIGHT_FLAG = 'Y' AND ChkinWktm > ChkoutWktm AND
                     NVL(CHKIN_CARD, ChkinWktm) > NVL(CHKOUT_CARD, ChkoutWktm) THEN TO_CHAR(ATT_DATE + 1, 'yyyy-mm-dd')
                     WHEN ChkinWktm > ChkoutWktm AND CHKOUT_CARD IS NULL THEN TO_CHAR(ATT_DATE + 1, 'yyyy-mm-dd')
                ELSE TO_CHAR(ATT_DATE, 'yyyy-mm-dd') END)
          INTO ChkinCard, ChkinUncard, ChkoutCard, ChkoutUncard, ChkinDate, ChkoutDate
          FROM HRA_CADSIGN
         WHERE EMP_NO = EmpNo_IN
           AND ATT_DATE = TO_DATE(Date_IN, 'yyyy/mm/dd');
      END IF;
      IF CntOut = 1 THEN --有外出(尚未轉假卡)
        SELECT START_TIME, NVL(END_TIME, ChkoutWktm),
               TO_CHAR(START_DATE,'yyyy-mm-dd'), TO_CHAR(NVL(END_DATE, START_DATE),'yyyy-mm-dd'),
               '外出('||(CASE STATUS WHEN 'U' THEN '請示' WHEN 'N' THEN '退回' ELSE '准' END)||')'
          INTO OutStartTime, OutEndTime, OutStartDate, OutEndDate, OutStatus
          FROM HRA_OUTREC
         WHERE EMP_NO = EmpNo_IN
           AND START_DATE = TO_DATE(Date_IN, 'yyyy/mm/dd')
           AND STATUS NOT IN ('N')
           AND PERMIT_HR = 'N';
      ELSIF CntOut > 1 THEN
        SELECT MIN(START_TIME), (CASE WHEN MAX(END_CHOOSE) = 'Y' THEN ChkoutWktm ELSE MAX(END_TIME) END),
               TO_CHAR(MIN(START_DATE),'yyyy-mm-dd'), TO_CHAR((CASE WHEN MAX(END_CHOOSE) = 'Y' THEN MAX(START_DATE) ELSE MAX(END_DATE) END),'yyyy-mm-dd'),
               '外出('||(CASE STATUS WHEN 'U' THEN '請示' WHEN 'N' THEN '退回' ELSE '准' END)||')'
          INTO OutStartTime, OutEndTime, OutStartDate, OutEndDate, OutStatus
          FROM HRA_OUTREC
         WHERE EMP_NO = EmpNo_IN
           AND START_DATE = TO_DATE(Date_IN, 'yyyy/mm/dd')
           AND STATUS NOT IN ('N')
           AND PERMIT_HR = 'N';
      END IF;
      IF CntEvc1 = 1 THEN
        SELECT START_TIME, (CASE WHEN START_DATE = END_DATE THEN END_TIME ELSE ChkoutWktm END),
               TO_CHAR(START_DATE,'yyyy-mm-dd'), 
               TO_CHAR((CASE WHEN START_DATE = END_DATE THEN END_DATE ELSE (CASE WHEN ChkoutWktm < ChkinWktm THEN START_DATE+1 ELSE START_DATE END) END),'yyyy-mm-dd'),
               (CASE VAC_TYPE WHEN 'P' THEN '公假' ELSE '外出' END)||'('||(CASE STATUS WHEN 'U' THEN '請示' WHEN 'D' THEN '取消' WHEN 'N' THEN '退回' ELSE '准' END)||')'
          INTO EvcStartTime, EvcEndTime, EvcStartDate, EvcEndDate, EvcStatus
          FROM HRA_EVCREC
         WHERE EMP_NO = EmpNo_IN
           AND VAC_TYPE IN ('B','P')
           AND START_DATE = TO_DATE(Date_IN, 'yyyy/mm/dd')
           AND STATUS NOT IN ('N','D');
      ELSIF CntEvc1 > 1 THEN
        SELECT MIN(START_TIME), (CASE WHEN MIN(START_DATE) = MAX(END_DATE) THEN MAX(END_TIME) ELSE ChkoutWktm END),
               TO_CHAR(MIN(START_DATE),'yyyy-mm-dd'), 
               TO_CHAR((CASE WHEN MIN(START_DATE) = MAX(END_DATE) THEN MAX(END_DATE) ELSE (CASE WHEN ChkoutWktm < ChkinWktm THEN MIN(START_DATE)+1 ELSE MIN(START_DATE) END) END),'yyyy-mm-dd'),
               (CASE VAC_TYPE WHEN 'P' THEN '公假' ELSE '外出' END)||'('||(CASE STATUS WHEN 'U' THEN '請示' WHEN 'D' THEN '取消' WHEN 'N' THEN '退回' ELSE '准' END)||')'
          INTO EvcStartTime, EvcEndTime, EvcStartDate, EvcEndDate, EvcStatus
          FROM HRA_EVCREC
         WHERE EMP_NO = EmpNo_IN
           AND VAC_TYPE IN ('B','P')
           AND START_DATE = TO_DATE(Date_IN, 'yyyy/mm/dd')
           AND STATUS NOT IN ('N','D');
      END IF;
      IF CntEvc2 = 1 THEN
        SELECT ChkinWktm, END_TIME,
               TO_CHAR((CASE WHEN ChkinWktm > END_TIME THEN END_DATE-1 ELSE END_DATE END),'yyyy-mm-dd'),
               TO_CHAR(END_DATE,'yyyy-mm-dd'),
               (CASE VAC_TYPE WHEN 'P' THEN '公假' ELSE '外出' END)||'('||(CASE STATUS WHEN 'U' THEN '請示' WHEN 'D' THEN '取消' WHEN 'N' THEN '退回' ELSE '准' END)||')'
          INTO EvcStartTime, EvcEndTime, EvcStartDate, EvcEndDate, EvcStatus
          FROM HRA_EVCREC
         WHERE EMP_NO = EmpNo_IN
           AND VAC_TYPE IN ('B','P')
           AND END_DATE = TO_DATE(Date_IN, 'yyyy/mm/dd')
           AND STATUS NOT IN ('N','D');
      ELSIF CntEvc2 > 1 THEN
        SELECT ChkinWktm, MAX(END_TIME),
               TO_CHAR((CASE WHEN ChkinWktm > END_TIME THEN MAX(END_DATE)-1 ELSE MAX(END_DATE) END),'yyyy-mm-dd'),
               TO_CHAR(MAX(END_DATE),'yyyy-mm-dd'),
               (CASE VAC_TYPE WHEN 'P' THEN '公假' ELSE '外出' END)||'('||(CASE STATUS WHEN 'U' THEN '請示' WHEN 'D' THEN '取消' WHEN 'N' THEN '退回' ELSE '准' END)||')'
          INTO EvcStartTime, EvcEndTime, EvcStartDate, EvcEndDate, EvcStatus
          FROM HRA_EVCREC
         WHERE EMP_NO = EmpNo_IN
           AND VAC_TYPE IN ('B','P')
           AND END_DATE = TO_DATE(Date_IN, 'yyyy/mm/dd')
           AND STATUS NOT IN ('N','D');
      END IF;
      IF CntEvc3 <> 0 THEN
        SELECT ChkinWktm, ChkoutWktm,
               Date_IN, TO_CHAR((CASE WHEN ChkinWktm > ChkoutWktm THEN TO_DATE(Date_IN, 'yyyy/mm/dd')+1 ELSE TO_DATE(Date_IN, 'yyyy/mm/dd') END),'yyyy-mm-dd'),
               (CASE VAC_TYPE WHEN 'P' THEN '公假' ELSE '外出' END)||'('||(CASE STATUS WHEN 'U' THEN '請示' WHEN 'D' THEN '取消' WHEN 'N' THEN '退回' ELSE '准' END)||')'
          INTO EvcStartTime, EvcEndTime, EvcStartDate, EvcEndDate, EvcStatus
          FROM HRA_EVCREC
         WHERE EMP_NO = EmpNo_IN
           AND VAC_TYPE IN ('B','P')
           AND TO_DATE(Date_IN, 'yyyy/mm/dd') > START_DATE
           AND TO_DATE(Date_IN, 'yyyy/mm/dd') < END_DATE
           AND STATUS NOT IN ('N','D');
      END IF;
    END IF;
    IF CntCad <> 0 THEN --有打卡
      IF CntOut = 0 AND CntEvc1 = 0 AND CntEvc2 = 0 AND CntEvc3 = 0 THEN --無公假/外出
        StartDate := ChkinDate;
        StartTime := ChkinCard;
        StartUncard := ChkinUncard;
        EndDate := ChkoutDate;
        EndTime := ChkoutCard;
        EndUncard := ChkoutUncard;
      ELSIF CntOut <> 0 AND CntEvc1 = 0 AND CntEvc2 = 0 AND CntEvc3 = 0 THEN --僅外出
        IF ChkinCard < OutStartTime THEN
          StartTime := ChkinCard;
          StartDate := ChkinDate;
        ELSE
          StartTime := OutStartTime;
          StartDate := OutStartDate;
        END IF;
        IF ChkoutCard < OutEndTime THEN
          EndTime := OutEndTime;
          EndDate := OutEndDate;
        ELSE
          EndTime := ChkoutCard;
          EndDate := ChkoutDate;
        END IF;
        StartUncard := ChkinUncard;
        EndUncard := ChkoutUncard;
        VacMessage := '(公假/外出'||OutStartTime||'~'||OutEndTime||')';
      ELSIF CntOut = 0 AND (CntEvc1 <> 0 OR CntEvc2 <> 0 OR CntEvc3 <> 0) THEN --僅休假
        IF ChkinCard < EvcStartTime THEN
          StartTime := ChkinCard;
          StartDate := ChkinDate;
        ELSE
          StartTime := EvcStartTime;
          StartDate := EvcStartDate;
        END IF;
        IF ChkoutCard < EvcEndTime THEN
          EndTime := EvcEndTime;
          EndDate := EvcEndDate;
        ELSE
          EndTime := ChkoutCard;
          EndDate := ChkoutDate;
        END IF;
        StartUncard := ChkinUncard;
        EndUncard := ChkoutUncard;
        VacMessage := '(公假/外出'||EvcStartTime||'~'||EvcEndTime||')';
      ELSIF CntOut <> 0 AND (CntEvc1 <> 0 OR CntEvc2 <> 0 OR CntEvc3 <> 0) THEN --有外出也有休假
        IF ChkinCard < EvcStartTime AND EvcStartTime < OutStartTime THEN
          StartTime := ChkinCard;
          StartDate := ChkinDate;
        ELSIF ChkinCard > EvcStartTime AND EvcStartTime > OutStartTime THEN
          StartTime := OutStartTime;
          StartDate := OutStartDate;
        ELSE
          StartTime := EvcStartTime;
          StartDate := EvcStartDate;
        END IF;
        IF ChkoutCard < EvcEndTime AND OutEndTime < EvcEndTime THEN
          EndTime := EvcEndTime;
          EndDate := EvcEndDate;
        ELSIF ChkoutCard > EvcEndTime AND ChkoutCard > OutEndTime THEN
          EndTime := ChkoutCard;
          EndDate := ChkoutDate;
        ELSE
          EndTime := OutEndTime;
          EndDate := OutEndDate;
        END IF;
        StartUncard := ChkinUncard;
        EndUncard := ChkoutUncard;
        VacMessage := '(公假/外出'||(CASE WHEN EvcStartTime < OutStartTime THEN EvcStartTime ELSE OutStartTime END)||'~'||
                      (CASE WHEN EvcEndTime > OutEndTime THEN EvcEndTime ELSE OutEndTime END)||')';
      END IF;
    ELSE --無打卡
      IF CntOut <> 0 AND CntEvc1 = 0 AND CntEvc2 = 0 AND CntEvc3 = 0 THEN --僅外出
        StartTime := OutStartTime;
        StartDate := OutStartDate;
        EndTime := OutEndTime;
        EndDate := OutEndDate;
        StartUncard := 'N';
        EndUncard := 'N';
        VacMessage := '(公假/外出'||OutStartTime||'~'||OutEndTime||')';
      ELSIF CntOut = 0 AND (CntEvc1 <> 0 OR CntEvc2 <> 0 OR CntEvc3 <> 0) THEN --僅休假
        StartTime := EvcStartTime;
        StartDate := EvcStartDate;
        EndTime := EvcEndTime;
        EndDate := EvcEndDate;
        StartUncard := 'N';
        EndUncard := 'N';
        VacMessage := '(公假/外出'||EvcStartTime||'~'||EvcEndTime||')';
      ELSIF CntOut <> 0 AND (CntEvc1 <> 0 OR CntEvc2 <> 0 OR CntEvc3 <> 0) THEN --有外出也有休假
        IF EvcStartTime < OutStartTime THEN
          StartTime := EvcStartTime;
          StartDate := EvcStartDate;
        ELSE
          StartTime := OutStartTime;
          StartDate := OutStartDate;
        END IF;
        IF EvcEndTime < OutEndTime THEN
          EndTime := OutEndTime;
          EndDate := OutEndDate;
        ELSE
          EndTime := EvcEndTime;
          EndDate := EvcEndDate;
        END IF;
        StartUncard := 'N';
        EndUncard := 'N';
        VacMessage := '(公假/外出'||(CASE WHEN EvcStartTime < OutStartTime THEN EvcStartTime ELSE OutStartTime END)||'~'||
                      (CASE WHEN EvcEndTime > OutEndTime THEN EvcEndTime ELSE OutEndTime END)||')';
      END IF;
    END IF;
    
    IF CntUncard1 <> 0 THEN
      SELECT '忘簽到'||'('||(CASE STATUS WHEN 'U' THEN '請示' WHEN 'N' THEN '取消' ELSE '准' END)||')'
        INTO VacStatus
        FROM HRA_UNCARD
       WHERE EMP_NO = EmpNo_IN
         AND CLASS_DATE = TO_DATE(Date_IN, 'yyyy/mm/dd')
         AND STATUS NOT IN ('N')
         AND UNCARD_TIME = 'A1';
    END IF;
    IF CntUncard2 <> 0 THEN
      IF VacStatus IS NOT NULL THEN 
        SELECT VacStatus || '忘簽退'||'('||(CASE STATUS WHEN 'U' THEN '請示' WHEN 'N' THEN '取消' ELSE '准' END)||')'
          INTO VacStatus
          FROM HRA_UNCARD
         WHERE EMP_NO = EmpNo_IN
           AND CLASS_DATE = TO_DATE(Date_IN, 'yyyy/mm/dd')
           AND STATUS NOT IN ('N')
           AND UNCARD_TIME = 'A2';
      ELSE
        SELECT '忘簽退'||'('||(CASE STATUS WHEN 'U' THEN '請示' WHEN 'N' THEN '取消' ELSE '准' END)||')'
          INTO VacStatus
          FROM HRA_UNCARD
         WHERE EMP_NO = EmpNo_IN
           AND CLASS_DATE = TO_DATE(Date_IN, 'yyyy/mm/dd')
           AND STATUS NOT IN ('N')
           AND UNCARD_TIME = 'A2';
      END IF;
    END IF;
    
    IF ClassCode NOT LIKE 'Z%' AND 
       CntCad = 0 AND CntOut = 0 AND CntEvc1 = 0 AND CntEvc2 = 0 AND CntEvc3 = 0 AND (CntEvc4 <> 0 OR CntSup <> 0) THEN
    --無打卡也無公假及因公外出但有休假,人員於編外可打卡
      StartTime := '0000';
      StartDate := Date_IN;
      StartUncard := 'N';
      EndTime := '0000';
      EndDate := Date_IN;
      EndUncard := 'N';
      VacMessage := '(院內休假)';
    ELSIF ClassCode NOT LIKE 'Z%' AND
          CntCad = 0 AND CntOut = 0 AND CntEvc1 = 0 AND CntEvc2 = 0 AND CntEvc3 = 0 AND CntEvc4 = 0 AND CntSup = 0 THEN
    --無打卡無休假,人員於編外可打卡但註記未打卡
      StartTime := '0000';
      StartDate := Date_IN;
      StartUncard := 'Y';
      EndTime := '0000';
      EndDate := Date_IN;
      EndUncard := 'Y';
    END IF;
    
    IF ClassCode <> 'N/A' THEN
      IF Type_IN = 'class' THEN
        RETURN ClassCode;
      ELSIF Type_IN = 'st' THEN
        RETURN StartTime;
      ELSIF Type_IN = 'sd' THEN
        RETURN StartDate;
      ELSIF Type_IN = 'su' THEN
        RETURN StartUncard;
      ELSIF Type_IN = 'et' THEN
        RETURN EndTime;
      ELSIF Type_IN = 'ed' THEN
        RETURN EndDate;
      ELSIF Type_IN = 'eu' THEN
        RETURN EndUncard;
      ELSIF Type_IN = 'vm' THEN
        IF VacMessage IS NULL THEN
          IF StartUncard = 'Y' AND EndUncard = 'Y' THEN
            VacMessage := '(院內正職未打卡)';
          ELSIF StartUncard = 'Y' AND EndUncard = 'N' THEN
            VacMessage := '(院內正職上班未打卡)';
          ELSIF StartUncard = 'N' AND EndUncard = 'Y' THEN
            VacMessage := '(院內正職下班未打卡)';
          END IF;
        ELSE
          IF StartUncard = 'Y' AND EndUncard = 'Y' THEN
            VacMessage := VacMessage||'(院內正職未打卡)';
          ELSIF StartUncard = 'Y' AND EndUncard = 'N' THEN
            VacMessage := VacMessage||'(院內正職上班未打卡)';
          ELSIF StartUncard = 'N' AND EndUncard = 'Y' THEN
            VacMessage := VacMessage||'(院內正職下班未打卡)';
          END IF;
        END IF;
        RETURN VacMessage;
      ELSIF Type_IN = 'vs' THEN
        IF OutStatus IS NOT NULL AND EvcStatus IS NOT NULL THEN
          IF VacStatus IS NOT NULL THEN
            VacStatus := VacStatus||','||OutStatus||','||EvcStatus;
          ELSE
            VacStatus := OutStatus||','||EvcStatus;
          END IF;
        ELSIF OutStatus IS NOT NULL AND EvcStatus IS NULL THEN
          IF VacStatus IS NOT NULL THEN
            VacStatus := VacStatus||','||OutStatus;
          ELSE
            VacStatus := OutStatus;
          END IF;
        ELSIF OutStatus IS NULL AND EvcStatus IS NOT NULL THEN
          IF VacStatus IS NOT NULL THEN
            VacStatus := VacStatus||','||EvcStatus;
          ELSE
            VacStatus := EvcStatus;
          END IF;
        ELSIF OutStatus IS NULL AND EvcStatus IS NULL THEN
          IF StartUncard = 'Y' AND EndUncard = 'Y' THEN
            VacStatus := '未打卡無休假';
          END IF;
        END IF;
        IF VacStatus IS NULL THEN
          IF StartUncard = 'Y' AND EndUncard = 'Y' THEN
            VacStatus := '未打卡(未申請)';
          ELSIF StartUncard = 'Y' AND EndUncard = 'N' THEN
            VacStatus := '忘簽到(未申請)';
          ELSIF StartUncard = 'N' AND EndUncard = 'Y' THEN
            VacStatus := '忘簽退(未申請)';
          END IF;
        END IF;
        RETURN VacStatus;
      END IF;
    ELSE
      IF Type_IN = 'class' THEN
        RETURN ClassCode;
      ELSE
        RETURN '';
      END IF;
    END IF;
  END F_HraCadsignTime;

  /*   mail 功能
  
  ProcType_IN -->
  被通知人(ㄧ級主管假卡劉協理審核完成) WHEN '1'
  暫時無用 改hrasend_mail2 JOB
  */
  PROCEDURE hrasend_mail(EmpNo_IN    VARCHAR2,
                         ProcType_IN Varchar2,
                         ProcMsg_IN  VARCHAR2,
                         ExUserID_IN VARCHAR2,
                         RtnCode     OUT NUMBER) AS
    sEmpName  VARCHAR2(200);
    sEEMail   VARCHAR2(120);
    sMessage  VARCHAR2(255);
    sDeptName VARCHAR2(60);
    sPosName  VARCHAR2(60);
    sComeDate Date;
    sTitle    VARCHAR2(50);
  
    pMsgno VARCHAR2(20);
  BEGIN
    BEGIN
      POST_HTML_MAIL('system@edah.org.tw',
                     'ed101961@edah.org.tw',
                     'ed101961@edah.org.tw',
                     '2',
                     'ㄧ級主管假卡劉協理審核test',
                     'ㄧ級主管假卡劉協理審核test');
      --抓該名員工的資訊
      SELECT --hre_empbas.e_mail,
       hre_empbas.ch_name,
       hre_orgbas.ch_name,
       hre_posmst.ch_name,
       hre_empbas.come_date
        INTO sEmpName, sDeptName, sPosName, sComeDate
        FROM hre_empbas, hre_orgbas, hre_posmst
       WHERE hre_empbas.dept_no = hre_orgbas.dept_no
         and hre_empbas.pos_no = hre_posmst.pos_no
         and hre_empbas.emp_no = EmpNo_IN;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        --sEMail    := NULL;
        sEmpName  := NULL;
        sDeptName := NULL;
    END;
    --抓通知人員的資訊
    BEGIN
      --抓該名員工簽核者或人事課人員的資訊
      SELECT hre_empbas.e_mail
        INTO sEEMail
        FROM hre_empbas, hre_orgbas
       WHERE (hre_empbas.dept_no = hre_orgbas.dept_no)
         and (hre_empbas.emp_no = ExUserID_IN);
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        sEEMail   := NULL;
        sEmpName  := NULL;
        sDeptName := NULL;
    END;
    if (ProcType_IN = '1') then
      sEEmail := 'ed100003@edah.org.tw';
    end if;
    sMessage := CASE ProcType_IN
    --被通知人(ㄧ級主管假卡劉協理審核完成) WHEN '1'
     WHEN '1' THEN '僅通知您一級主管請假審核已完成-' || sDeptName || ':' || EmpNo_IN || '(' || sEmpName || ')申請' || ProcMsg_IN || '審核完成' END;
    sTitle   := CASE ProcType_IN WHEN '1' THEN '出勤通知-一級主管請假審核完成通知' END;
  
    IF TRIM(sEEMail) IS NOT NULL THEN
      POST_HTML_MAIL('system@edah.org.tw',
                     sEEMail,
                     'ed101961@edah.org.tw',
                     '2',
                     sTitle,
                     sMessage);
    END IF;
    RtnCode := 0;
  END hrasend_mail;

  PROCEDURE hrasend_mail2 AS
    pempno      VARCHAR2(20);
    pchname     VARCHAR2(200);
    pdeptname   VARCHAR2(60);
    pposname    VARCHAR2(60);
    pvacname    VARCHAR2(40);
    pstatusname VARCHAR2(10);
    psd         VARCHAR2(10);
    pst         VARCHAR2(4);
    ped         VARCHAR2(10);
    pet         VARCHAR2(4);
    pevcrea     VARCHAR2(100);
    pvacdays    NUMBER(3);
    pvachrs     NUMBER(4, 1);
    prm         VARCHAR2(300);
    pevcday     VARCHAR2(100);
    plastvacday VARCHAR2(100); --20190130 108978 增加遞延天數顯示
    pevc_u      VARCHAR2(100);
    pevc_f      VARCHAR2(100);
    pevc_s      VARCHAR2(100);
    pabroad     VARCHAR2(2); --20200214 108154 增加出國註記
    pevc_p      VARCHAR2(100); --20220317 108482 增加年度公假
    psup_hr     VARCHAR2(100); --20220317 108482 增加年度補休
  
    sTitle   VARCHAR2(100);
    sEEMail  VARCHAR2(120);
    sMessage VARCHAR2(32000);
  
    ErrorCode    NUMBER; --20220715 108482 記錄異常代碼
    ErrorMessage VARCHAR2(500); --20220715 108482 記錄異常訊息
  
    CURSOR cursor1 IS
      SELECT ta.emp_no,
             tb.ch_name,
             (SELECT ch_name
                FROM HRE_ORGBAS
               WHERE dept_no = ta.dept_no
                 and organ_type = ta.org_by) deptname,
             (SELECT ch_name FROM HRE_POSMST WHERE pos_no = tb.pos_no) posname,
             CASE ta.vac_type
               WHEN 'O1' THEN
                '借休'
               WHEN 'B0' THEN
                '補休'
               ELSE
                (SELECT vac_name
                   FROM HRA_VCRLMST
                  WHERE vac_type = ta.vac_type)
             END vacname,
             CASE ta.status
               WHEN 'Y' THEN
                '准'
               WHEN 'U' THEN
                CASE
               WHEN
                (SELECT COUNT(*) FROM hra_evcflow WHERE evc_no = ta.evc_no) = 0 THEN
                '申請'
               WHEN
                (SELECT COUNT(*) FROM hra_evcflow WHERE evc_no = ta.evc_no) = 1 THEN
                '初審'
               ELSE
                '覆審'
             END ELSE '' END statusname,
             ta.sd,
             ta.st,
             ta.ed,
             ta.et,
             CASE vac_type
               WHEN 'B0' THEN
                (SELECT code_name
                   FROM HR_CODEDTL
                  WHERE code_type = 'HRA22'
                    AND code_no = ta.evc_rea)
               WHEN '01' THEN
                (SELECT code_name
                   FROM HR_CODEDTL
                  WHERE code_type = 'HRA51'
                    AND code_no = ta.evc_rea)
               ELSE
                (SELECT code_name
                   FROM HR_CODEDTL
                  WHERE code_type = 'HRA08'
                    AND code_no = ta.evc_rea)
             END evcrea,
             vac_days,
             vac_hrs,
             ta.remark,
             tc.vac_day,
             tc.last_vac_day,
             (SELECT NVL(FLOOR(SUM(VAC_DAYS * 8 + VAC_HRS) / 8), '0') || '天' ||
                     NVL(MOD(SUM(VAC_DAYS * 8 + VAC_HRS), 8), '0') || '時'
                FROM HRP.HRA_EVCREC
               WHERE VAC_TYPE = 'V'
                 AND EMP_NO = ta.EMP_NO
                 AND ORG_BY = ta.ORG_BY
                 AND STATUS IN ('Y', 'U')
                 AND TO_CHAR(START_DATE, 'YYYY') = TO_CHAR(SYSDATE, 'yyyy')
                 AND TRANS_FLAG = 'N') V_U_DAY,
             (SELECT NVL(FLOOR(SUM(VAC_DAYS * 8 + VAC_HRS) / 8), '0') || '天' ||
                     NVL(MOD(SUM(VAC_DAYS * 8 + VAC_HRS), 8), '0') || '時'
                FROM HRP.HRA_EVCREC
               WHERE VAC_TYPE = 'S'
                 AND EMP_NO = ta.EMP_NO
                 AND ORG_BY = ta.ORG_BY
                 AND STATUS IN ('Y', 'U')
                 AND TO_CHAR(START_DATE, 'YYYY') = TO_CHAR(SYSDATE, 'yyyy')
                 AND TRANS_FLAG = 'N') S_U_DAY,
             (SELECT NVL(FLOOR(SUM(VAC_DAYS * 8 + VAC_HRS) / 8), '0') || '天' ||
                     NVL(MOD(SUM(VAC_DAYS * 8 + VAC_HRS), 8), '0') || '時'
                FROM HRP.HRA_EVCREC
               WHERE VAC_TYPE = 'F'
                 AND EMP_NO = ta.EMP_NO
                 AND ORG_BY = ta.ORG_BY
                 AND STATUS IN ('Y', 'U')
                 AND TO_CHAR(START_DATE, 'YYYY') = TO_CHAR(SYSDATE, 'yyyy')
                 AND TRANS_FLAG = 'N') F_U_DAY,
             abroad,
             (SELECT NVL(FLOOR(SUM(VAC_DAYS * 8 + VAC_HRS) / 8), '0') || '天' ||
                     NVL(MOD(SUM(VAC_DAYS * 8 + VAC_HRS), 8), '0') || '時'
                FROM HRP.HRA_EVCREC
               WHERE VAC_TYPE = 'P'
                 AND EMP_NO = ta.EMP_NO
                 AND ORG_BY = ta.ORG_BY
                 AND STATUS IN ('Y', 'U')
                 AND TO_CHAR(START_DATE, 'YYYY') = TO_CHAR(SYSDATE, 'yyyy')
                 AND TRANS_FLAG = 'N') P_U_DAY,
             (SELECT NVL(FLOOR(SUM(SUP_HRS) / 8), '0') || '天' ||
                     NVL(MOD(SUM(SUP_HRS), 8), '0') || '時'
                FROM HRP.HRA_SUPMST
               WHERE EMP_NO = ta.EMP_NO
                 AND ORG_BY = ta.ORG_BY
                 AND STATUS IN ('Y', 'U')
                 AND TO_CHAR(START_DATE, 'YYYY') = TO_CHAR(SYSDATE, 'yyyy')) SUP_U_HR
      
        FROM (SELECT evc_no,
                     org_by,
                     emp_no,
                     dept_no,
                     vac_type,
                     vac_rul,
                     status,
                     sd,
                     st,
                     ed,
                     et,
                     evc_rea,
                     vac_days,
                     vac_hrs,
                     remark,
                     abroad
                FROM (SELECT t1.evc_no,
                             t1.org_by,
                             t1.emp_no,
                             t1.dept_no,
                             vac_type,
                             vac_rul,
                             status,
                             TO_CHAR(start_date, 'yyyy-mm-dd') sd,
                             start_time st,
                             TO_CHAR(end_date, 'yyyy-mm-dd') ed,
                             end_time et,
                             evc_rea,
                             vac_days,
                             vac_hrs,
                             remark,
                             abroad
                        FROM HRA_EVCREC t1
                       WHERE status IN ('Y', 'U'))
               WHERE sd <= TO_CHAR(SYSDATE, 'yyyy-mm-dd')
                 AND ed >= TO_CHAR(SYSDATE, 'yyyy-mm-dd')
                 AND EMP_NO IN
                    -- (SELECT code_no FROM HR_CODEDTL WHERE code_type = 'HRA67')
                     (SELECT emp_no
                        FROM HRE_EMPBAS
                       WHERE POS_NO IN (SELECT POS_NO
                                          FROM HRE_POSMST
                                         WHERE POS_LEVEL >= 7 /*BETWEEN 7 AND 11*/
                                        )
                         AND DISABLED = 'N'
                         AND EMP_FLAG = '01'
                         AND NVL(JOB_LEV, 'Z') <> 'R'
                         AND emp_no <> '100003' --排除執副(需求單)
                      )
              UNION ALL
              SELECT '',
                     org_by,
                     emp_no,
                     dept_no,
                     vac_type,
                     vac_rul,
                     status,
                     sd,
                     st,
                     ed,
                     et,
                     evc_rea,
                     vac_days,
                     vac_hrs,
                     remark,
                     abroad
                FROM (SELECT org_by,
                             emp_no,
                             dept_no,
                             'O1' vac_type,
                             'O1' vac_rul,
                             status,
                             TO_CHAR(start_date, 'yyyy-mm-dd') sd,
                             start_time st,
                             TO_CHAR(end_date, 'yyyy-mm-dd') ed,
                             end_time et,
                             OTM_REA evc_rea,
                             0 vac_days,
                             otm_hrs vac_hrs,
                             remark,
                             abroad
                        FROM HRA_OFFREC t1
                       WHERE item_type = 'O'
                         AND status IN ('Y', 'U'))
               WHERE sd <= TO_CHAR(SYSDATE, 'yyyy-mm-dd')
                 AND ed >= TO_CHAR(SYSDATE, 'yyyy-mm-dd')
                 AND EMP_NO IN
                    --    (SELECT code_no FROM HR_CODEDTL WHERE code_type = 'HRA67')
                     (SELECT emp_no
                        FROM HRE_EMPBAS
                       WHERE POS_NO IN (SELECT POS_NO
                                          FROM HRE_POSMST
                                         WHERE POS_LEVEL >= 7 /*BETWEEN 7 AND 11*/
                                        )
                         AND DISABLED = 'N'
                         AND EMP_FLAG = '01'
                         AND NVL(JOB_LEV, 'Z') <> 'R'
                         AND emp_no <> '100003' --排除執副(需求單)
                      )
              UNION ALL
              SELECT '',
                     org_by,
                     emp_no,
                     dept_no,
                     vac_type,
                     vac_rul,
                     status,
                     sd,
                     st,
                     ed,
                     et,
                     evc_rea,
                     vac_days,
                     vac_hrs,
                     remark,
                     abroad
                FROM (SELECT org_by,
                             emp_no,
                             dept_no,
                             'B0' vac_type,
                             'B0' vac_rul,
                             status,
                             TO_CHAR(start_date, 'yyyy-mm-dd') sd,
                             start_time st,
                             TO_CHAR(end_date, 'yyyy-mm-dd') ed,
                             end_time et,
                             sup_rea evc_rea,
                             0 vac_days,
                             SUP_HRS vac_hrs,
                             remark,
                             abroad
                        FROM HRA_SUPMST t1
                       WHERE status IN ('Y', 'U'))
               WHERE sd <= TO_CHAR(SYSDATE, 'yyyy-mm-dd')
                 AND ed >= TO_CHAR(SYSDATE, 'yyyy-mm-dd')
                 AND EMP_NO IN
                    --(SELECT code_no FROM HR_CODEDTL WHERE code_type = 'HRA67')
                     (SELECT emp_no
                        FROM HRE_EMPBAS
                       WHERE POS_NO IN (SELECT POS_NO
                                          FROM HRE_POSMST
                                         WHERE POS_LEVEL >= 7 /*BETWEEN 7 AND 11*/
                                        )
                         AND DISABLED = 'N'
                         AND EMP_FLAG = '01'
                         AND NVL(JOB_LEV, 'Z') <> 'R'
                         AND emp_no <> '100003' --排除執副(需求單)
                      )
              
              ) ta
        LEFT OUTER JOIN HRA_YEARVAC TC ON TA.EMP_NO = TC.EMP_NO
                                      AND TC.VAC_YEAR =
                                          TO_CHAR(SYSDATE, 'yyyy'),
       HRE_EMPBAS tb
       WHERE ta.emp_no = tb.emp_no
         and ta.org_by = tb.organ_type
      --  AND ta.emp_no ='108154' --test
      --AND ta.emp_no = tc.emp_no
      --AND tc.vac_year = TO_CHAR(SYSDATE, 'yyyy')
       ORDER BY ta.emp_no, ta.sd, ta.st;
  
    CURSOR cursor2 IS
      SELECT CODE_NAME
        FROM HR_CODEDTL
       WHERE CODE_TYPE = 'HRA62'
         AND DISABLED = 'N';
    -- SELECT 'ed108154@edah.org.tw' FROM dual;
  BEGIN
    sMessage := '';
  
    OPEN cursor1;
    LOOP
      FETCH cursor1
        INTO pempno, pchname, pdeptname, pposname, pvacname, pstatusname, psd, pst, ped, pet, pevcrea, pvacdays, pvachrs, prm, pevcday, plastvacday, pevc_u, pevc_s, pevc_f, pabroad, pevc_p, psup_hr;
      EXIT WHEN cursor1%NOTFOUND;
    
      IF sMessage is null THEN
        sMessage := '<table border="1" width="100%"><TR><TD>工號</td><TD>姓名</td><TD>部門名稱</td><TD>職稱</td><TD>假別</td>';
        sMessage := sMessage ||
                    '<TD>狀態</td><TD>開始日期</td><TD>開始時間</td><TD>結束日期</td><TD>結束時間</td>';
        sMessage := sMessage ||
                    '<TD>天數</td><TD>時數</td><TD>請假理由</td><TD>其他原因</td><TD>出國</td><TD>可休特休</td><TD>已請特休</td><TD>事假</td><TD>病假</td></tr>';
        --'<TD>天數</td><TD>時數</td><TD>請假理由</td><TD>其他原因</td><TD>出國</td><TD>可休特休</td><TD>已休特休</td><TD>事假</td><TD>病假</td><TD>公假</td><TD>補休</td></tr>';
        sMessage := sMessage || '<TR><TD>' || pempno || '</td><TD>' ||
                    pchname || '</td><TD>' || pdeptname || '</td>';
        sMessage := sMessage || '<TD>' || pposname || '</td><TD>' ||
                    pvacname || '</td><TD>' || pstatusname || '</td>';
        sMessage := sMessage || '<TD>' || psd || '</td><TD>' || pst ||
                    '</td><TD>' || ped || '</td>';
        sMessage := sMessage || '<TD>' || pet || '</td><TD>' || pvacdays ||
                    '</td><TD>' || pvachrs || '</td>';
        sMessage := sMessage || '<TD>' || pevcrea || '</td><TD>' || prm ||
                    '</td><TD>' || pabroad || '</td><TD>' || pevcday ||
                    '<font color="red">(含遞延' || plastvacday ||
                    '天)</font></td><TD>' || pevc_u || '</td><TD>' || pevc_f ||
                    '</td><TD>' || pevc_s || '</td></tr>';
        --'</td><TD>' || pevc_s || '</td><td>'|| pevc_p || '</td><td>'|| psup_hr ||'</td></tr>';
      ELSE
        sMessage := sMessage || '<TR><TD>' || pempno || '</td><TD>' ||
                    pchname || '</td><TD>' || pdeptname || '</td>';
        sMessage := sMessage || '<TD>' || pposname || '</td><TD>' ||
                    pvacname || '</td><TD>' || pstatusname || '</td>';
        sMessage := sMessage || '<TD>' || psd || '</td><TD>' || pst ||
                    '</td><TD>' || ped || '</td>';
        sMessage := sMessage || '<TD>' || pet || '</td><TD>' || pvacdays ||
                    '</td><TD>' || pvachrs || '</td>';
        sMessage := sMessage || '<TD>' || pevcrea || '</td><TD>' || prm ||
                    '</td><TD>' || pabroad || '</td><TD>' || pevcday ||
                    '<font color="red">(含遞延' || plastvacday ||
                    '天)</font></td><TD>' || pevc_u || '</td><TD>' || pevc_f ||
                    '</td><TD>' || pevc_s || '</td></tr>';
        --'</td><TD>' || pevc_s || '</td><td>'|| pevc_p || '</td><td>'|| psup_hr ||'</td></tr>';
      END IF;
    
    END LOOP;
    CLOSE cursor1;
  
    sTitle := '今日一級主管請假彙總表(' || TO_CHAR(SYSDATE, 'yyyy-mm-dd') || ')';
  
    IF (sMessage is not null) THEN
      sMessage := sMessage || '</table>';
      OPEN cursor2;
      LOOP
        FETCH cursor2
          INTO sEEMail;
        EXIT WHEN cursor2%NOTFOUND;
        POST_HTML_MAIL('system@edah.org.tw',
                       sEEMail,
                       '',
                       '1',
                       sTitle,
                       sMessage);
      
      END LOOP;
      CLOSE cursor2;
    ELSE
    
      sMessage := '截至上午07:00，無今日(' || TO_CHAR(SYSDATE, 'yyyy-mm-dd') || ')';
      sMessage := sMessage || '一級主管電子假卡、補休申請單。';
      OPEN cursor2;
      LOOP
        FETCH cursor2
          INTO sEEMail;
        EXIT WHEN cursor2%NOTFOUND;
        POST_HTML_MAIL('system@edah.org.tw',
                       sEEMail,
                       '',
                       '1',
                       sTitle,
                       sMessage);
      
      END LOOP;
      CLOSE cursor2;
    
    END IF;
  
  EXCEPTION
    WHEN OTHERS THEN
      ErrorCode    := SQLCODE;
      ErrorMessage := SQLERRM;
      INSERT INTO HRA_UNNORMAL_LOG
        (LOG_SEQ,
         PROG_NAME,
         SYS_DATE,
         LOG_CODE,
         LOG_MSG,
         LOG_INFO,
         CREATED_BY,
         CREATION_DATE,
         LAST_UPDATED_BY,
         LAST_UPDATE_DATE)
      VALUES
        (TO_CHAR(SYSDATE, 'MMDDHH24MISS'),
         '一級主管請假彙總',
         SYSDATE,
         ErrorCode,
         '今日一級主管請假彙總表通知執行異常',
         ErrorMessage,
         'MIS',
         SYSDATE,
         'MIS',
         SYSDATE);
      COMMIT;
    
  END hrasend_mail2;

  PROCEDURE hrasend_mail_abroad AS
    pempno      VARCHAR2(20);
    pchname     VARCHAR2(200);
    pdeptname   VARCHAR2(60);
    pposname    VARCHAR2(60);
    pvacname    VARCHAR2(60);
    pstatusname VARCHAR2(10);
    psd         VARCHAR2(10);
    pst         VARCHAR2(4);
    ped         VARCHAR2(10);
    pet         VARCHAR2(4);
    pevcrea     VARCHAR2(200);
    pvacdays    NUMBER(3);
    pvachrs     NUMBER(4, 1);
    prm         VARCHAR2(300);
    pevcday     VARCHAR2(100);
    plastvacday VARCHAR2(100); --20190130 108978 增加遞延天數顯示
    pevc_u      VARCHAR2(100);
    pevc_f      VARCHAR2(100);
    pevc_s      VARCHAR2(100);
    pabroad     VARCHAR2(10); --20200214 108154 增加出國註記
    porgantype  VARCHAR2(100);
    pposlevel   NUMBER(3);
  
    sTitle       VARCHAR2(100);
    sTitle2      VARCHAR2(100);
    sEEMail      VARCHAR2(120);
    sMessage     VARCHAR2(32767);
    sMessage2    VARCHAR2(32767); --一般人員第二封
    sMessageDoc  VARCHAR2(32767);
    sMessageMail VARCHAR2(32767);
    nconti       NUMBER(1);
    pCONTIEVCNO  VARCHAR2(20);
    psd2         VARCHAR2(10);
    nconti2      NUMBER(1);
  
    ErrorCode    NUMBER; --20220715 108482 記錄異常代碼
    ErrorMessage VARCHAR2(500); --20220715 108482 記錄異常訊息
  
    CURSOR cursor1 IS --一般人員
      SELECT ta.emp_no,
             tb.ch_name,
             (SELECT ch_name
                FROM HRE_ORGBAS
               WHERE dept_no = ta.dept_no
                 and organ_type = ta.org_by) deptname,
             (SELECT ch_name FROM HRE_POSMST WHERE pos_no = tb.pos_no) posname,
             CASE ta.vac_type
               WHEN 'O1' THEN
                '借休'
               WHEN 'B0' THEN
                '補休'
               WHEN 'B1' THEN
                '補休'
               ELSE
                (SELECT vac_name
                   FROM HRA_VCRLMST
                  WHERE vac_type = ta.vac_type)
             END vacname,
             CASE ta.status
               WHEN 'Y' THEN
                '准'
               WHEN 'U' THEN
                '申請'
               ELSE
                ''
             END statusname,
             ta.sd,
             ta.st,
             ta.ed,
             ta.et,
             CASE vac_type
               WHEN 'B0' THEN
                (SELECT code_name
                   FROM HR_CODEDTL
                  WHERE code_type = 'HRA22'
                    AND code_no = ta.evc_rea)
               WHEN '01' THEN
                (SELECT code_name
                   FROM HR_CODEDTL
                  WHERE code_type = 'HRA51'
                    AND code_no = ta.evc_rea)
               ELSE
                (SELECT code_name
                   FROM HR_CODEDTL
                  WHERE code_type = 'HRA08'
                    AND code_no = ta.evc_rea)
             END evcrea,
             vac_days,
             vac_hrs,
             ta.remark,
             tc.vac_day,
             tc.last_vac_day,
             (SELECT NVL(FLOOR(SUM(VAC_DAYS * 8 + VAC_HRS) / 8), '0') || '天' ||
                     NVL(MOD(SUM(VAC_DAYS * 8 + VAC_HRS), 8), '0') || '時'
                FROM HRP.HRA_EVCREC
               WHERE VAC_TYPE = 'V'
                 AND EMP_NO = ta.EMP_NO
                 AND ORG_BY = ta.ORG_BY
                 AND STATUS IN ('Y', 'U')
                 AND TO_CHAR(START_DATE, 'YYYY') = TO_CHAR(SYSDATE, 'yyyy')
                 AND TRANS_FLAG = 'N') V_U_DAY,
             
             (SELECT NVL(FLOOR(SUM(VAC_DAYS * 8 + VAC_HRS) / 8), '0') || '天' ||
                     NVL(MOD(SUM(VAC_DAYS * 8 + VAC_HRS), 8), '0') || '時'
                FROM HRP.HRA_EVCREC
               WHERE VAC_TYPE = 'S'
                 AND EMP_NO = ta.EMP_NO
                 AND ORG_BY = ta.ORG_BY
                 AND STATUS IN ('Y', 'U')
                 AND TO_CHAR(START_DATE, 'YYYY') = TO_CHAR(SYSDATE, 'yyyy')
                 AND TRANS_FLAG = 'N') S_U_DAY,
             
             (SELECT NVL(FLOOR(SUM(VAC_DAYS * 8 + VAC_HRS) / 8), '0') || '天' ||
                     NVL(MOD(SUM(VAC_DAYS * 8 + VAC_HRS), 8), '0') || '時'
                FROM HRP.HRA_EVCREC
               WHERE VAC_TYPE = 'F'
                 AND EMP_NO = ta.EMP_NO
                 AND ORG_BY = ta.ORG_BY
                 AND STATUS IN ('Y', 'U')
                 AND TO_CHAR(START_DATE, 'YYYY') = TO_CHAR(SYSDATE, 'yyyy')
                 AND TRANS_FLAG = 'N') F_U_DAY,
             abroad,
             DECODE(tb.organ_type,
                    'ED',
                    '義大',
                    'EC',
                    '癌醫',
                    'EF',
                    '大昌',
                    'EG',
                    '護理之家',
                    'EK',
                    '產後護理',
                    'EH',
                    '居護所',
                    'EL',
                    '貝思諾',
                    'EN',
                    '幼兒園') ORGANTYPE,
             
             (SELECT pos_level FROM HRE_POSMST WHERE pos_no = tb.pos_no) poslevel
      
        FROM (SELECT org_by,
                     emp_no,
                     dept_no,
                     vac_type,
                     vac_rul,
                     status,
                     sd,
                     st,
                     ed,
                     et,
                     evc_rea,
                     vac_days,
                     vac_hrs,
                     remark,
                     abroad
                FROM (SELECT t1.org_by,
                             t1.emp_no,
                             t1.dept_no,
                             vac_type,
                             vac_rul,
                             status,
                             TO_CHAR(start_date, 'yyyy-mm-dd') sd,
                             start_time st,
                             TO_CHAR(end_date, 'yyyy-mm-dd') ed,
                             end_time et,
                             evc_rea,
                             vac_days,
                             vac_hrs,
                             remark,
                             abroad
                        FROM HRA_EVCREC t1
                       WHERE status IN ('Y', 'U'))
               WHERE ((sd BETWEEN TO_CHAR(SYSDATE, 'yyyy-mm-dd') AND
                     TO_CHAR(SYSDATE + 7, 'yyyy-mm-dd')) OR
                     (ed BETWEEN TO_CHAR(SYSDATE, 'yyyy-mm-dd') AND
                     TO_CHAR(SYSDATE + 7, 'yyyy-mm-dd')) OR
                     (sd <= TO_CHAR(SYSDATE, 'yyyy-mm-dd') AND
                     ed >= TO_CHAR(SYSDATE + 7, 'yyyy-mm-dd')))
                 AND abroad IN ('Y')
              UNION ALL
              SELECT org_by,
                     emp_no,
                     dept_no,
                     vac_type,
                     vac_rul,
                     status,
                     sd,
                     st,
                     ed,
                     et,
                     evc_rea,
                     vac_days,
                     vac_hrs,
                     remark,
                     abroad
                FROM (SELECT org_by,
                             emp_no,
                             dept_no,
                             'O1' vac_type,
                             'O1' vac_rul,
                             status,
                             TO_CHAR(start_date, 'yyyy-mm-dd') sd,
                             start_time st,
                             TO_CHAR(end_date, 'yyyy-mm-dd') ed,
                             end_time et,
                             OTM_REA evc_rea,
                             0 vac_days,
                             otm_hrs vac_hrs,
                             remark,
                             abroad
                        FROM HRA_OFFREC t1
                       WHERE item_type = 'O'
                         AND status IN ('Y', 'U'))
               WHERE ((sd BETWEEN TO_CHAR(SYSDATE, 'yyyy-mm-dd') AND
                     TO_CHAR(SYSDATE + 7, 'yyyy-mm-dd')) OR
                     (ed BETWEEN TO_CHAR(SYSDATE, 'yyyy-mm-dd') AND
                     TO_CHAR(SYSDATE + 7, 'yyyy-mm-dd')) OR
                     (sd <= TO_CHAR(SYSDATE, 'yyyy-mm-dd') AND
                     ed >= TO_CHAR(SYSDATE + 7, 'yyyy-mm-dd')))
                 AND abroad IN ('Y')
              UNION ALL
              SELECT org_by,
                     emp_no,
                     dept_no,
                     vac_type,
                     vac_rul,
                     status,
                     sd,
                     st,
                     ed,
                     et,
                     evc_rea,
                     vac_days,
                     vac_hrs,
                     remark,
                     abroad
                FROM (SELECT org_by,
                             emp_no,
                             dept_no,
                             'B0' vac_type,
                             'B0' vac_rul,
                             status,
                             TO_CHAR(start_date, 'yyyy-mm-dd') sd,
                             start_time st,
                             TO_CHAR(end_date, 'yyyy-mm-dd') ed,
                             end_time et,
                             sup_rea evc_rea,
                             0 vac_days,
                             SUP_HRS vac_hrs,
                             remark,
                             abroad
                        FROM HRA_SUPMST t1
                       WHERE status IN ('Y', 'U'))
               WHERE ((sd BETWEEN TO_CHAR(SYSDATE, 'yyyy-mm-dd') AND
                     TO_CHAR(SYSDATE + 7, 'yyyy-mm-dd')) OR
                     (ed BETWEEN TO_CHAR(SYSDATE, 'yyyy-mm-dd') AND
                     TO_CHAR(SYSDATE + 7, 'yyyy-mm-dd')) OR
                     (sd <= TO_CHAR(SYSDATE, 'yyyy-mm-dd') AND
                     ed >= TO_CHAR(SYSDATE + 7, 'yyyy-mm-dd')))
                 AND abroad IN ('Y')) ta,
             HRE_EMPBAS tb,
             hra_yearvac tc
       WHERE ta.emp_no = tb.emp_no
         and ta.org_by = tb.organ_type
         AND ta.emp_no = tc.emp_no
         AND tc.vac_year = TO_CHAR(SYSDATE, 'yyyy')
       ORDER BY ta.sd,
                (SELECT pos_level FROM HRE_POSMST WHERE pos_no = tb.pos_no) DESC,
                ta.emp_no;
  
    CURSOR cursor2 IS --收件人
    /*SELECT CODE_NAME
                                              FROM HR_CODEDTL
                                             WHERE CODE_TYPE = 'HRA62'
                                               AND DISABLED = 'N';*/
      SELECT 'ed108154@edah.org.tw'
        FROM dual --李采柔
      UNION ALL
      SELECT 'ed108482@edah.org.tw'
        FROM dual --葉鈴雅
      UNION ALL
      SELECT 'ed100037@edah.org.tw'
        FROM dual --鄭淑宏
      UNION ALL
      SELECT 'ed100054@edah.org.tw'
        FROM dual --蔡易庭
      UNION ALL
      SELECT 'ed100005@edah.org.tw'
        FROM dual --洪行政長
      UNION ALL
      SELECT 'ed105094@edah.org.tw' --許菀齡副行政長
        FROM dual;
  
  BEGIN
    sMessage := '<table border="1" width="100%">';
  
    sMessage := sMessage || '<tr><td colspan="17" ><BR>' ||
                '==========(一般人員出國假單)==========' || '<BR><BR></tr></tr>';
    sMessage := sMessage ||
                '<TR><TD>機構</td><TD>工號</td><TD>姓名</td><TD>部門名稱</td><TD>職稱</td><TD>職等</td><TD>假別</td>';
  
    sMessage := sMessage ||
                '<TD>狀態</td><TD>開始日期</td><TD>開始時間</td><TD>結束日期</td><TD>結束時間</td>';
    sMessage := sMessage ||
                '<TD>天數</td><TD>時數</td><TD>請假理由</td><TD>其他原因</td><TD>出國</td>';
  
    OPEN cursor1;
    LOOP
      FETCH cursor1
        INTO pempno, pchname, pdeptname, pposname, pvacname, pstatusname, psd, pst, ped, pet, pevcrea, pvacdays, pvachrs, prm, pevcday, plastvacday, pevc_u, pevc_s, pevc_f, pabroad, porgantype, pposlevel;
      EXIT WHEN cursor1%NOTFOUND;
      nconti := 0;
      --check 電子假卡vs補休 
      --仍有盲點
      SELECT COUNT(*)
        INTO nconti
        FROM (SELECT MIN(start_date) starDate
                FROM (SELECT t1.emp_no, start_date, end_date
                        FROM HRA_EVCREC t1
                       WHERE status IN ('Y', 'U')
                         AND abroad = 'Y'
                         AND ((TO_CHAR(START_DATE, 'yyyy-mm-dd') BETWEEN
                             TO_CHAR(SYSDATE, 'yyyy-mm-dd') AND
                             TO_CHAR(SYSDATE + 7, 'yyyy-mm-dd')) OR
                             (TO_CHAR(END_DATE, 'yyyy-mm-dd') BETWEEN
                             TO_CHAR(SYSDATE, 'yyyy-mm-dd') AND
                             TO_CHAR(SYSDATE + 7, 'yyyy-mm-dd')) OR
                             (TO_CHAR(START_DATE, 'yyyy-mm-dd') <=
                             TO_CHAR(SYSDATE, 'yyyy-mm-dd') AND
                             TO_CHAR(END_DATE, 'yyyy-mm-dd') >=
                             TO_CHAR(SYSDATE, 'yyyy-mm-dd')))
                      UNION ALL
                      SELECT t1.emp_no, start_date, end_date
                        FROM HRA_SUPMST t1
                       WHERE status IN ('Y', 'U')
                         AND ((TO_CHAR(start_date, 'yyyy-mm-dd') BETWEEN
                             TO_CHAR(SYSDATE, 'yyyy-mm-dd') AND
                             TO_CHAR(SYSDATE + 7, 'yyyy-mm-dd')) OR
                             (TO_CHAR(END_date, 'yyyy-mm-dd') BETWEEN
                             TO_CHAR(SYSDATE, 'yyyy-mm-dd') AND
                             TO_CHAR(SYSDATE + 7, 'yyyy-mm-dd')) OR
                             (TO_CHAR(start_date, 'yyyy-mm-dd') <=
                             TO_CHAR(SYSDATE, 'yyyy-mm-dd') AND
                             TO_CHAR(end_date, 'yyyy-mm-dd') >=
                             TO_CHAR(SYSDATE + 7, 'yyyy-mm-dd')))
                         AND abroad IN ('Y'))
               WHERE emp_no = pempno)
       WHERE TO_CHAR(starDate, 'yyyy-mm-dd') <=
             TO_CHAR(sysdate, 'yyyy-mm-dd');
    
      IF psd <= TO_CHAR(sysdate, 'yyyy-mm-dd') OR nconti <> 0 THEN
        pabroad := pabroad || '-已出';
      ELSE
        pabroad := pabroad || '-未出';
      END IF;
    
      --2023-4-11 拆2封 by108154
      IF (LENGTH(sMessage) < 19000) THEN
      
        sMessage := sMessage || '<TR><TD>' || porgantype || '</td><TD>' ||
                    pempno || '</td><TD>' || pchname || '</td><TD>' ||
                    pdeptname || '</td>';
        sMessage := sMessage || '<TD>' || pposname || '</td><TD>' ||
                    pposlevel || '</td><TD>' || pvacname || '</td><TD>' ||
                    pstatusname || '</td>';
        sMessage := sMessage || '<TD>' || psd || '</td><TD>' || pst ||
                    '</td><TD>' || ped || '</td>';
        sMessage := sMessage || '<TD>' || pet || '</td><TD>' || pvacdays ||
                    '</td><TD>' || pvachrs || '</td>';
        sMessage := sMessage || '<TD>' || pevcrea || '</td><TD>' || prm ||
                    '</td><TD>' || pabroad || '</td></tr>';
      
      ELSE
      
        IF sMessage2 is null THEN
          sMessage2 := '<table border="1" width="100%">';
          sMessage2 := sMessage2 || '<tr><td colspan="17" ><BR>' ||
                       '==========(一般人員出國假單)==========' ||
                       '<BR><BR></tr></tr>';
          sMessage2 := sMessage2 ||
                       '<TR><TD>機構</td><TD>工號</td><TD>姓名</td><TD>部門名稱</td><TD>職稱</td><TD>職等</td><TD>假別</td>';
        
          sMessage2 := sMessage2 ||
                       '<TD>狀態</td><TD>開始日期</td><TD>開始時間</td><TD>結束日期</td><TD>結束時間</td>';
          sMessage2 := sMessage2 ||
                       '<TD>天數</td><TD>時數</td><TD>請假理由</td><TD>其他原因</td><TD>出國</td>';
          sMessage2 := sMessage2 || '<TR><TD>' || porgantype || '</td><TD>' ||
                       pempno || '</td><TD>' || pchname || '</td><TD>' ||
                       pdeptname || '</td>';
          sMessage2 := sMessage2 || '<TD>' || pposname || '</td><TD>' ||
                       pposlevel || '</td><TD>' || pvacname || '</td><TD>' ||
                       pstatusname || '</td>';
          sMessage2 := sMessage2 || '<TD>' || psd || '</td><TD>' || pst ||
                       '</td><TD>' || ped || '</td>';
          sMessage2 := sMessage2 || '<TD>' || pet || '</td><TD>' ||
                       pvacdays || '</td><TD>' || pvachrs || '</td>';
          sMessage2 := sMessage2 || '<TD>' || pevcrea || '</td><TD>' || prm ||
                       '</td><TD>' || pabroad || '</td></tr>';
        ELSE
          sMessage2 := sMessage2 || '<TR><TD>' || porgantype || '</td><TD>' ||
                       pempno || '</td><TD>' || pchname || '</td><TD>' ||
                       pdeptname || '</td>';
          sMessage2 := sMessage2 || '<TD>' || pposname || '</td><TD>' ||
                       pposlevel || '</td><TD>' || pvacname || '</td><TD>' ||
                       pstatusname || '</td>';
          sMessage2 := sMessage2 || '<TD>' || psd || '</td><TD>' || pst ||
                       '</td><TD>' || ped || '</td>';
          sMessage2 := sMessage2 || '<TD>' || pet || '</td><TD>' ||
                       pvacdays || '</td><TD>' || pvachrs || '</td>';
          sMessage2 := sMessage2 || '<TD>' || pevcrea || '</td><TD>' || prm ||
                       '</td><TD>' || pabroad || '</td></tr>';
        END IF;
      
      END IF;
    END LOOP;
    CLOSE cursor1;
  
    sTitle  := '未來一週請假出國人員名單(一般人員)(' || TO_CHAR(SYSDATE, 'yyyy-mm-dd') || ')';
    sTitle2 := '未來一週請假出國人員名單(一般人員)(第2封/共2封)(' ||
               TO_CHAR(SYSDATE, 'yyyy-mm-dd') || ')';
  
    IF sMessage is null THEN
    
      sMessageMail := '截至上午07:10，無未來一週請假出國假卡。';
    
      OPEN cursor2;
      LOOP
        FETCH cursor2
          INTO sEEMail;
        EXIT WHEN cursor2%NOTFOUND;
        POST_HTML_MAIL('system@edah.org.tw',
                       sEEMail,
                       '',
                       '1',
                       sTitle,
                       sMessageMail);
      END LOOP;
      CLOSE cursor2;
    ELSE
      --無醫師有一般(一封)
      IF sMessage2 is null THEN
      
        sMessage     := sMessage || '</table>';
        sMessageMail := sMessage;
        OPEN cursor2;
        LOOP
          FETCH cursor2
            INTO sEEMail;
          EXIT WHEN cursor2%NOTFOUND;
          POST_HTML_MAIL('system@edah.org.tw',
                         sEEMail,
                         '',
                         '1',
                         sTitle,
                         sMessage);
        END LOOP;
        CLOSE cursor2;
      
      ELSE
        sTitle := '未來一週請假出國人員名單(一般人員)(第1封/共2封)(' ||
                  TO_CHAR(SYSDATE, 'yyyy-mm-dd') || ')';
      
        sMessage     := sMessage || '</table>';
        sMessageMail := sMessage;
        OPEN cursor2;
        LOOP
          FETCH cursor2
            INTO sEEMail;
          EXIT WHEN cursor2%NOTFOUND;
          POST_HTML_MAIL('system@edah.org.tw',
                         sEEMail,
                         '',
                         '1',
                         sTitle,
                         sMessageMail);
        END LOOP;
        CLOSE cursor2;
      
        sMessage2 := sMessage2 || '</table>';
        OPEN cursor2;
        LOOP
          FETCH cursor2
            INTO sEEMail;
          EXIT WHEN cursor2%NOTFOUND;
          POST_HTML_MAIL('system@edah.org.tw',
                         sEEMail,
                         '',
                         '1',
                         sTitle2,
                         sMessage2);
        END LOOP;
        CLOSE cursor2;
      
      END IF;
    END IF;
  
  EXCEPTION
    WHEN OTHERS THEN
      ErrorCode    := SQLCODE;
      ErrorMessage := SQLERRM;
      INSERT INTO HRA_UNNORMAL_LOG
        (LOG_SEQ,
         PROG_NAME,
         SYS_DATE,
         LOG_CODE,
         LOG_MSG,
         LOG_INFO,
         CREATED_BY,
         CREATION_DATE,
         LAST_UPDATED_BY,
         LAST_UPDATE_DATE)
      VALUES
        (TO_CHAR(SYSDATE, 'MMDDHH24MISS'),
         '請假出國人員通知',
         SYSDATE,
         ErrorCode,
         '未來一週請假出國人員名單通知執行異常(一般人員)',
         ErrorMessage,
         'MIS',
         SYSDATE,
         'MIS',
         SYSDATE);
      COMMIT;
    
  END hrasend_mail_abroad;

  PROCEDURE hrasend_mail_abroadDoc AS
    pempno      VARCHAR2(20);
    pchname     VARCHAR2(200);
    pdeptname   VARCHAR2(60);
    pposname    VARCHAR2(60);
    pvacname    VARCHAR2(60);
    pstatusname VARCHAR2(10);
    psd         VARCHAR2(10);
    pst         VARCHAR2(4);
    ped         VARCHAR2(10);
    pet         VARCHAR2(4);
    pevcrea     VARCHAR2(200);
    pvacdays    NUMBER(3);
    pvachrs     NUMBER(4, 1);
    prm         VARCHAR2(300);
    pevcday     VARCHAR2(100);
    plastvacday VARCHAR2(100); --20190130 108978 增加遞延天數顯示
    pevc_u      VARCHAR2(100);
    pevc_f      VARCHAR2(100);
    pevc_s      VARCHAR2(100);
    pabroad     VARCHAR2(10); --20200214 108154 增加出國註記
    porgantype  VARCHAR2(100);
    pposlevel   NUMBER(3);
  
    sTitle       VARCHAR2(100);
    sEEMail      VARCHAR2(120);
    sMessage     VARCHAR2(32767);
    sMessageDoc  VARCHAR2(32767);
    sMessageDoc2 VARCHAR2(32767);
    sMessageMail VARCHAR2(32767);
    nconti       NUMBER(1);
    pCONTIEVCNO  VARCHAR2(20);
    psd2         VARCHAR2(10);
    nconti2      NUMBER(1);
  
    ErrorCode    NUMBER; --20220715 108482 記錄異常代碼
    ErrorMessage VARCHAR2(500); --20220715 108482 記錄異常訊息
  
    CURSOR cursor1 IS --一般人員
      SELECT ta.emp_no,
             tb.ch_name,
             (SELECT ch_name
                FROM HRE_ORGBAS
               WHERE dept_no = ta.dept_no
                 and organ_type = ta.org_by) deptname,
             (SELECT ch_name FROM HRE_POSMST WHERE pos_no = tb.pos_no) posname,
             CASE ta.vac_type
               WHEN 'O1' THEN
                '借休'
               WHEN 'B0' THEN
                '補休'
               WHEN 'B1' THEN
                '補休'
               ELSE
                (SELECT vac_name
                   FROM HRA_VCRLMST
                  WHERE vac_type = ta.vac_type)
             END vacname,
             CASE ta.status
               WHEN 'Y' THEN
                '准'
               WHEN 'U' THEN
                '申請'
               ELSE
                ''
             END statusname,
             ta.sd,
             ta.st,
             ta.ed,
             ta.et,
             CASE vac_type
               WHEN 'B0' THEN
                (SELECT code_name
                   FROM HR_CODEDTL
                  WHERE code_type = 'HRA22'
                    AND code_no = ta.evc_rea)
               WHEN '01' THEN
                (SELECT code_name
                   FROM HR_CODEDTL
                  WHERE code_type = 'HRA51'
                    AND code_no = ta.evc_rea)
               ELSE
                (SELECT code_name
                   FROM HR_CODEDTL
                  WHERE code_type = 'HRA08'
                    AND code_no = ta.evc_rea)
             END evcrea,
             vac_days,
             vac_hrs,
             ta.remark,
             tc.vac_day,
             tc.last_vac_day,
             (SELECT NVL(FLOOR(SUM(VAC_DAYS * 8 + VAC_HRS) / 8), '0') || '天' ||
                     NVL(MOD(SUM(VAC_DAYS * 8 + VAC_HRS), 8), '0') || '時'
                FROM HRP.HRA_EVCREC
               WHERE VAC_TYPE = 'V'
                 AND EMP_NO = ta.EMP_NO
                 AND ORG_BY = ta.ORG_BY
                 AND STATUS IN ('Y', 'U')
                 AND TO_CHAR(START_DATE, 'YYYY') = TO_CHAR(SYSDATE, 'yyyy')
                 AND TRANS_FLAG = 'N') V_U_DAY,
             
             (SELECT NVL(FLOOR(SUM(VAC_DAYS * 8 + VAC_HRS) / 8), '0') || '天' ||
                     NVL(MOD(SUM(VAC_DAYS * 8 + VAC_HRS), 8), '0') || '時'
                FROM HRP.HRA_EVCREC
               WHERE VAC_TYPE = 'S'
                 AND EMP_NO = ta.EMP_NO
                 AND ORG_BY = ta.ORG_BY
                 AND STATUS IN ('Y', 'U')
                 AND TO_CHAR(START_DATE, 'YYYY') = TO_CHAR(SYSDATE, 'yyyy')
                 AND TRANS_FLAG = 'N') S_U_DAY,
             
             (SELECT NVL(FLOOR(SUM(VAC_DAYS * 8 + VAC_HRS) / 8), '0') || '天' ||
                     NVL(MOD(SUM(VAC_DAYS * 8 + VAC_HRS), 8), '0') || '時'
                FROM HRP.HRA_EVCREC
               WHERE VAC_TYPE = 'F'
                 AND EMP_NO = ta.EMP_NO
                 AND ORG_BY = ta.ORG_BY
                 AND STATUS IN ('Y', 'U')
                 AND TO_CHAR(START_DATE, 'YYYY') = TO_CHAR(SYSDATE, 'yyyy')
                 AND TRANS_FLAG = 'N') F_U_DAY,
             abroad,
             DECODE(tb.organ_type,
                    'ED',
                    '義大',
                    'EC',
                    '癌醫',
                    'EF',
                    '大昌',
                    'EG',
                    '護理之家',
                    'EK',
                    '產後護理',
                    'EH',
                    '居護所',
                    'EL',
                    '貝思諾') ORGANTYPE,
             
             (SELECT pos_level FROM HRE_POSMST WHERE pos_no = tb.pos_no) poslevel
      
        FROM (SELECT org_by,
                     emp_no,
                     dept_no,
                     vac_type,
                     vac_rul,
                     status,
                     sd,
                     st,
                     ed,
                     et,
                     evc_rea,
                     vac_days,
                     vac_hrs,
                     remark,
                     abroad
                FROM (SELECT t1.org_by,
                             t1.emp_no,
                             t1.dept_no,
                             vac_type,
                             vac_rul,
                             status,
                             TO_CHAR(start_date, 'yyyy-mm-dd') sd,
                             start_time st,
                             TO_CHAR(end_date, 'yyyy-mm-dd') ed,
                             end_time et,
                             evc_rea,
                             vac_days,
                             vac_hrs,
                             remark,
                             abroad
                        FROM HRA_EVCREC t1
                       WHERE status IN ('Y', 'U'))
               WHERE ((sd BETWEEN TO_CHAR(SYSDATE, 'yyyy-mm-dd') AND
                     TO_CHAR(SYSDATE + 7, 'yyyy-mm-dd')) OR
                     (ed BETWEEN TO_CHAR(SYSDATE, 'yyyy-mm-dd') AND
                     TO_CHAR(SYSDATE + 7, 'yyyy-mm-dd')) OR
                     (sd <= TO_CHAR(SYSDATE, 'yyyy-mm-dd') AND
                     ed >= TO_CHAR(SYSDATE + 7, 'yyyy-mm-dd')))
                 AND abroad IN ('Y')
              UNION ALL
              SELECT org_by,
                     emp_no,
                     dept_no,
                     vac_type,
                     vac_rul,
                     status,
                     sd,
                     st,
                     ed,
                     et,
                     evc_rea,
                     vac_days,
                     vac_hrs,
                     remark,
                     abroad
                FROM (SELECT org_by,
                             emp_no,
                             dept_no,
                             'O1' vac_type,
                             'O1' vac_rul,
                             status,
                             TO_CHAR(start_date, 'yyyy-mm-dd') sd,
                             start_time st,
                             TO_CHAR(end_date, 'yyyy-mm-dd') ed,
                             end_time et,
                             OTM_REA evc_rea,
                             0 vac_days,
                             otm_hrs vac_hrs,
                             remark,
                             abroad
                        FROM HRA_OFFREC t1
                       WHERE item_type = 'O'
                         AND status IN ('Y', 'U'))
               WHERE ((sd BETWEEN TO_CHAR(SYSDATE, 'yyyy-mm-dd') AND
                     TO_CHAR(SYSDATE + 7, 'yyyy-mm-dd')) OR
                     (ed BETWEEN TO_CHAR(SYSDATE, 'yyyy-mm-dd') AND
                     TO_CHAR(SYSDATE + 7, 'yyyy-mm-dd')) OR
                     (sd <= TO_CHAR(SYSDATE, 'yyyy-mm-dd') AND
                     ed >= TO_CHAR(SYSDATE + 7, 'yyyy-mm-dd')))
                 AND abroad IN ('Y')
              UNION ALL
              SELECT org_by,
                     emp_no,
                     dept_no,
                     vac_type,
                     vac_rul,
                     status,
                     sd,
                     st,
                     ed,
                     et,
                     evc_rea,
                     vac_days,
                     vac_hrs,
                     remark,
                     abroad
                FROM (SELECT org_by,
                             emp_no,
                             dept_no,
                             'B0' vac_type,
                             'B0' vac_rul,
                             status,
                             TO_CHAR(start_date, 'yyyy-mm-dd') sd,
                             start_time st,
                             TO_CHAR(end_date, 'yyyy-mm-dd') ed,
                             end_time et,
                             sup_rea evc_rea,
                             0 vac_days,
                             SUP_HRS vac_hrs,
                             remark,
                             abroad
                        FROM HRA_SUPMST t1
                       WHERE status IN ('Y', 'U'))
               WHERE ((sd BETWEEN TO_CHAR(SYSDATE, 'yyyy-mm-dd') AND
                     TO_CHAR(SYSDATE + 7, 'yyyy-mm-dd')) OR
                     (ed BETWEEN TO_CHAR(SYSDATE, 'yyyy-mm-dd') AND
                     TO_CHAR(SYSDATE + 7, 'yyyy-mm-dd')) OR
                     (sd <= TO_CHAR(SYSDATE, 'yyyy-mm-dd') AND
                     ed >= TO_CHAR(SYSDATE + 7, 'yyyy-mm-dd')))
                 AND abroad IN ('Y')) ta,
             HRE_EMPBAS tb,
             hra_yearvac tc
       WHERE ta.emp_no = tb.emp_no
         and ta.org_by = tb.organ_type
         AND ta.emp_no = tc.emp_no
         AND tc.vac_year = TO_CHAR(SYSDATE, 'yyyy')
       ORDER BY ta.sd,
                (SELECT pos_level FROM HRE_POSMST WHERE pos_no = tb.pos_no) DESC,
                ta.emp_no;
  
    CURSOR cursor2 IS --收件人
    /*SELECT CODE_NAME
                                              FROM HR_CODEDTL
                                             WHERE CODE_TYPE = 'HRA62'
                                               AND DISABLED = 'N';*/
      SELECT 'ed108154@edah.org.tw'
        FROM dual --李采柔
      UNION ALL
      SELECT 'ed108482@edah.org.tw'
        FROM dual --葉鈴雅
      UNION ALL
      SELECT 'ed100037@edah.org.tw'
        FROM dual --鄭淑宏
      UNION ALL
      SELECT 'ed100054@edah.org.tw'
        FROM dual --蔡易庭
      UNION ALL
      SELECT 'ed100005@edah.org.tw'
        FROM dual --洪行政長
      UNION ALL
      SELECT 'ed105094@edah.org.tw' --許菀齡副行政長
        FROM dual;
  
    CURSOR CURSOR3 IS --醫師
      SELECT A.EMP_NO,
             B.CH_NAME,
             C.CH_NAME DEPT_NAME,
             E.CH_NAME POS_NAME,
             D.VAC_NAME,
             CASE A.status
               WHEN 'Y' THEN
                '准'
               WHEN 'U' THEN
                '申請'
               ELSE
                ''
             END statusname, --statusName
             TO_CHAR(A.START_DATE, 'YYYY-MM-DD'),
             A.START_TIME,
             TO_CHAR(A.END_DATE, 'YYYY-MM-DD'),
             A.END_TIME,
             F.Rul_Name, --pevcrea
             A.VAC_DAYS,
             A.VAC_HRS,
             A.REMARK,
             '', --pevcday
             '', --plastvacday
             '', --pevc_u
             '', --pevc_s
             '', --pevc_f
             A.Abroad,
             DECODE(B.ORGAN_TYPE, 'ED', '義大', 'EC', '癌醫', 'EF', '大昌') ORGANTYPE,
             E.Pos_Level,
             CONTI_EVCNO
        FROM HRA_DEVCREC  A,
             HRE_EMPBAS   B,
             HRE_ORGBAS   C,
             HRA_DVCRLMST D,
             HRE_POSMST   E,
             HRA_DVCRLDTL F
       WHERE A.STATUS <> 'N'
         AND ((TO_CHAR(A.START_DATE, 'YYYY-MM-DD') BETWEEN
             TO_CHAR(SYSDATE, 'YYYY-MM-DD') AND
             TO_CHAR(SYSDATE + 7, 'YYYY-MM-DD')) OR
             (TO_CHAR(A.END_DATE, 'YYYY-MM-DD') BETWEEN
             TO_CHAR(SYSDATE, 'YYYY-MM-DD') AND
             TO_CHAR(SYSDATE + 7, 'YYYY-MM-DD')) OR
             (TO_CHAR(A.START_DATE, 'YYYY-MM-DD') <=
             TO_CHAR(SYSDATE, 'YYYY-MM-DD') AND
             TO_CHAR(A.END_DATE, 'YYYY-MM-DD') >=
             TO_CHAR(SYSDATE + 7, 'YYYY-MM-DD')))
         AND A.EMP_NO = B.EMP_NO
         AND B.DEPT_NO = C.DEPT_NO
         AND A.VAC_TYPE = D.VAC_TYPE
         AND D.VAC_TYPE = F.VAC_TYPE
         AND A.VAC_RUL = F.VAC_RUL
         AND B.POS_NO = E.POS_NO
         AND A.ABROAD = 'Y'
         AND A.DIS_ALL = 'N'
         AND ((A.DIS_SD IS NULL) OR ((TO_CHAR(A.DIS_SD, 'YYYY-MM-DD') >
             TO_CHAR(SYSDATE, 'YYYY-MM-DD')) OR
             (TO_CHAR(A.DIS_ED, 'YYYY-MM-DD') <
             TO_CHAR(SYSDATE, 'YYYY-MM-DD'))))
       ORDER BY A.Start_Date, E.Pos_Level DESC, A.EMP_NO;
  
  BEGIN
    sMessage    := '';
    sMessageDoc := '';
    sMessageDoc2 := '';
  
    OPEN cursor3;
    LOOP
      FETCH cursor3
        INTO pempno, pchname, pdeptname, pposname, pvacname, pstatusname, psd, pst, ped, pet, pevcrea, pvacdays, pvachrs, prm, pevcday, plastvacday, pevc_u, pevc_s, pevc_f, pabroad, porgantype, pposlevel, pCONTIEVCNO;
      EXIT WHEN cursor3%NOTFOUND;
      nconti  := 0;
      nconti2 := 0;
      --check 跨月出國假單
      SELECT count(*)
        INTO nconti
        FROM hra_devcrec
       WHERE emp_no = pempno
         AND start_date > sysdate
         AND abroad = 'Y'
         AND TO_CHAR(start_date, 'yyyy-mm-dd') = psd
         AND CONTI_EVCNO IN (SELECT evc_no
                               FROM hra_devcrec
                              WHERE evc_no = pCONTIEVCNO
                                AND dis_all = 'N');
    
      --20221018 by108482 check 連續假卡是否已經出國
      IF pCONTIEVCNO IS NOT NULL THEN
      
        BEGIN
          SELECT TO_CHAR(start_date, 'yyyy-mm-dd')
            INTO psd2
            FROM hra_devcrec
           WHERE evc_no = pCONTIEVCNO
             AND dis_all = 'N';
        EXCEPTION
          WHEN OTHERS THEN
            psd2 := '';
        END;
      
        IF psd > psd2 THEN
          IF psd2 <= TO_CHAR(SYSDATE, 'yyyy-mm-dd') THEN
            nconti2 := 1;
          ELSE
            nconti2 := 0;
          END IF;
        ELSE
          IF psd <= TO_CHAR(SYSDATE, 'yyyy-mm-dd') THEN
            nconti2 := 1;
          ELSE
            nconti2 := 0;
          END IF;
        END IF;
      END IF;
    
      IF psd <= TO_CHAR(sysdate, 'yyyy-mm-dd') OR
         (nconti <> 0 AND nconti2 <> 0) THEN
        pabroad := pabroad || '-已出';
      ELSE
        pabroad := pabroad || '-未出';
      END IF;
    
      IF sMessageDoc is null THEN
        sMessageDoc := '<table border="1" width="100%">';
        sMessageDoc := sMessageDoc || '<tr><td colspan="17" ><BR>' ||
                       '==========(醫師出國假單)==========' ||
                       '<BR><BR></tr></tr>';
        sMessageDoc := sMessageDoc ||
                       '<TR><TD>機構</td><TD>工號</td><TD>姓名</td><TD>部門名稱</td><TD>職稱</td><TD>職等</td><TD>假別</td>';
      
        sMessageDoc := sMessageDoc ||
                       '<TD>狀態</td><TD>開始日期</td><TD>開始時間</td><TD>結束日期</td><TD>結束時間</td>';
        sMessageDoc := sMessageDoc ||
                       '<TD>天數</td><TD>時數</td><TD>請假理由</td><TD>其他原因</td><TD>出國</td>';
        sMessageDoc := sMessageDoc || '<TR><TD>' || porgantype ||
                       '</td><TD>' || pempno || '</td><TD>' || pchname ||
                       '</td><TD>' || pdeptname || '</td>';
        sMessageDoc := sMessageDoc || '<TD>' || pposname || '</td><TD>' ||
                       pposlevel || '</td><TD>' || pvacname || '</td><TD>' ||
                       pstatusname || '</td>';
        sMessageDoc := sMessageDoc || '<TD>' || psd || '</td><TD>' || pst ||
                       '</td><TD>' || ped || '</td>';
        sMessageDoc := sMessageDoc || '<TD>' || pet || '</td><TD>' ||
                       pvacdays || '</td><TD>' || pvachrs || '</td>';
        sMessageDoc := sMessageDoc || '<TD>' || pevcrea || '</td><TD>' || prm ||
                       '</td><TD>' || pabroad || '</td></tr>';
      ELSIF LENGTH(sMessageDoc) < 19000 THEN 
        sMessageDoc := sMessageDoc || '<TR><TD>' || porgantype ||
                       '</td><TD>' || pempno || '</td><TD>' || pchname ||
                       '</td><TD>' || pdeptname || '</td>';
        sMessageDoc := sMessageDoc || '<TD>' || pposname || '</td><TD>' ||
                       pposlevel || '</td><TD>' || pvacname || '</td><TD>' ||
                       pstatusname || '</td>';
        sMessageDoc := sMessageDoc || '<TD>' || psd || '</td><TD>' || pst ||
                       '</td><TD>' || ped || '</td>';
        sMessageDoc := sMessageDoc || '<TD>' || pet || '</td><TD>' ||
                       pvacdays || '</td><TD>' || pvachrs || '</td>';
        sMessageDoc := sMessageDoc || '<TD>' || pevcrea || '</td><TD>' || prm ||
                       '</td><TD>' || pabroad || '</td></tr>';
      ELSIF LENGTH(sMessageDoc) > 19000 THEN 
        IF sMessageDoc2 IS NULL THEN
          sMessageDoc2 := '<table border="1" width="100%">';
          sMessageDoc2 := sMessageDoc2 || '<tr><td colspan="17" ><BR>' ||
                          '==========(醫師出國假單,接續前一封)==========' ||
                          '<BR><BR></tr></tr>';
          sMessageDoc2 := sMessageDoc2 ||
                          '<TR><TD>機構</td><TD>工號</td><TD>姓名</td><TD>部門名稱</td><TD>職稱</td><TD>職等</td><TD>假別</td>';
          sMessageDoc2 := sMessageDoc2 ||
                          '<TD>狀態</td><TD>開始日期</td><TD>開始時間</td><TD>結束日期</td><TD>結束時間</td>';
          sMessageDoc2 := sMessageDoc2 ||
                          '<TD>天數</td><TD>時數</td><TD>請假理由</td><TD>其他原因</td><TD>出國</td>';
          sMessageDoc2 := sMessageDoc2 || '<TR><TD>' || porgantype ||
                          '</td><TD>' || pempno || '</td><TD>' || pchname ||
                          '</td><TD>' || pdeptname || '</td>';
          sMessageDoc2 := sMessageDoc2 || '<TD>' || pposname || '</td><TD>' ||
                          pposlevel || '</td><TD>' || pvacname || '</td><TD>' ||
                          pstatusname || '</td>';
          sMessageDoc2 := sMessageDoc2 || '<TD>' || psd || '</td><TD>' || pst ||
                          '</td><TD>' || ped || '</td>';
          sMessageDoc2 := sMessageDoc2 || '<TD>' || pet || '</td><TD>' ||
                          pvacdays || '</td><TD>' || pvachrs || '</td>';
          sMessageDoc2 := sMessageDoc2 || '<TD>' || pevcrea || '</td><TD>' || prm ||
                          '</td><TD>' || pabroad || '</td></tr>';
        ELSE
          sMessageDoc2 := sMessageDoc2 || '<TR><TD>' || porgantype ||
                          '</td><TD>' || pempno || '</td><TD>' || pchname ||
                          '</td><TD>' || pdeptname || '</td>';
          sMessageDoc2 := sMessageDoc2 || '<TD>' || pposname || '</td><TD>' ||
                          pposlevel || '</td><TD>' || pvacname || '</td><TD>' ||
                          pstatusname || '</td>';
          sMessageDoc2 := sMessageDoc2 || '<TD>' || psd || '</td><TD>' || pst ||
                          '</td><TD>' || ped || '</td>';
          sMessageDoc2 := sMessageDoc2 || '<TD>' || pet || '</td><TD>' ||
                          pvacdays || '</td><TD>' || pvachrs || '</td>';
          sMessageDoc2 := sMessageDoc2 || '<TD>' || pevcrea || '</td><TD>' || prm ||
                          '</td><TD>' || pabroad || '</td></tr>';
        END IF;
      END IF;
    
    END LOOP;
    --sMessageDoc := sMessageDoc|| '</table>';
    CLOSE cursor3;
  
    sTitle := '未來一週請假出國人員名單(醫師)(' || TO_CHAR(SYSDATE, 'yyyy-mm-dd') || ')';
  
    IF sMessageDoc is null THEN
      IF sMessage is null THEN
        --無醫師無一般
        sMessageMail := '截至上午07:10，無未來一週請假出國假卡。';
      ELSE
        --無醫師有一般
        sMessage     := sMessage || '</table>';
        sMessageMail := sMessage;
      END IF;
    ELSE
      sMessageDoc := sMessageDoc || '</table>';
      IF sMessage is null THEN
        --有醫師無一般
        sMessageMail := sMessageDoc;
      ELSE
        --有醫師有一般
        sMessage     := sMessage || '</table>';
        sMessageMail := sMessageDoc || '<br><br>' || sMessage;
      END IF;
    END IF;
    
    IF sMessageDoc2 IS NOT NULL THEN
      sMessageDoc2 := sMessageDoc2 || '</table>';
    END IF;
    
    OPEN cursor2;
    LOOP
      FETCH cursor2
        INTO sEEMail;
      EXIT WHEN cursor2%NOTFOUND;
      IF sMessageDoc2 IS NOT NULL THEN
        POST_HTML_MAIL('system@edah.org.tw', sEEMail, '', '1', sTitle||'_1', sMessageMail);
        POST_HTML_MAIL('system@edah.org.tw', sEEMail, '', '1', sTitle||'_2', sMessageDoc2);
      ELSE
        POST_HTML_MAIL('system@edah.org.tw', sEEMail, '', '1', sTitle, sMessageMail);
      END IF;
    END LOOP;
    CLOSE cursor2;
  
  EXCEPTION
    WHEN OTHERS THEN
      ErrorCode    := pempno;
      ErrorMessage := SQLERRM;
      INSERT INTO HRA_UNNORMAL_LOG
        (LOG_SEQ,
         PROG_NAME,
         SYS_DATE,
         LOG_CODE,
         LOG_MSG,
         LOG_INFO,
         CREATED_BY,
         CREATION_DATE,
         LAST_UPDATED_BY,
         LAST_UPDATE_DATE)
      VALUES
        (TO_CHAR(SYSDATE, 'MMDDHH24MISS'),
         '請假出國人員通知',
         SYSDATE,
         ErrorCode,
         '未來一週請假出國人員名單通知執行異常(醫師)',
         ErrorMessage,
         'MIS',
         SYSDATE,
         'MIS',
         SYSDATE);
      COMMIT;
    
  END hrasend_mail_abroadDoc;

  PROCEDURE hrasend_mail_immi(EmpNo_IN VARCHAR2, RtnCode OUT NUMBER) AS
    CURSOR cursor2 IS
      SELECT CODE_NAME
        FROM HR_CODEDTL
       WHERE CODE_TYPE = 'HRA99'
         AND CODE_NO like 'A%'
         AND DISABLED = 'N';
    sEmpName  VARCHAR2(200);
    sEEMail   VARCHAR2(120);
    sMessage  VARCHAR2(255);
    sDeptName VARCHAR2(60);
    sPosName  VARCHAR2(60);
    sTitle    VARCHAR2(50);
    sOrgan    VARCHAR2(120);
  
  BEGIN
    BEGIN
      SELECT hre_empbas.ch_name,
             hre_orgbas.ch_name,
             hre_posmst.ch_name,
             (select ban_nm
                from pus_orgsys
               where organ_type =
                     hrp.f_flow_organ(hre_empbas.emp_no,
                                      hre_empbas.organ_type))
        INTO sEmpName, sDeptName, sPosName, sOrgan
        FROM hre_empbas, hre_orgbas, hre_posmst
       WHERE hre_empbas.dept_no = hre_orgbas.dept_no
         and hre_empbas.pos_no = hre_posmst.pos_no
         and hre_empbas.emp_no = EmpNo_IN;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        sEmpName  := NULL;
        sDeptName := NULL;
    END;
  
    sTitle   := '出入境管理-輸入症狀通知';
    SMessage := 'MIS出入境管理,' || sOrgan || ' ' || EmpNo_IN || '(' || sEmpName || ')' ||
                '輸入相關症狀資料,請進入MIS出入境管理相關報表查詢';
    --抓通知人員的資訊
    OPEN cursor2;
    LOOP
      FETCH cursor2
        INTO sEEMail;
      EXIT WHEN cursor2%NOTFOUND;
      POST_HTML_MAIL('system@edah.org.tw',
                     sEEMail,
                     'ed108482@edah.org.tw',
                     '1',
                     sTitle,
                     sMessage);
    END LOOP;
    CLOSE cursor2;
    RtnCode := 0;
  END hrasend_mail_immi;

  PROCEDURE hrasend_mail_immi2 AS
    pEvcno     varchar2(20 Byte);
    pEmpno     varchar2(20 Byte);
    pChname    varchar2(200 Byte);
    pEmail     varchar2(60 Byte);
    pStartdate VARCHAR2(20);
  
    iMSG_NO VARCHAR2(20);
    sSEQNO  VARCHAR2(20);
  
    CURSOR cursor1 IS
      SELECT t1.emp_no,
             t2.ch_name,
             (CASE
               WHEN SUBSTR(T2.EMP_NO, 1, 1) NOT IN ('S', 'P', 'R') THEN
                'ed' || T2.EMP_NO || '@edah.org.tw'
               ELSE
                'ed' || T2.EMP_NO || '@edah.org.tw'
             END) AS e_mail,
             to_char(T1.Start_Date, 'yyyy-mm-dd') AS Start_Date
        FROM HRA_EVCREC t1, HRE_EMPBAS t2
       WHERE t1.emp_no = t2.emp_no
         AND status IN ('Y', 'U')
         AND (t1.evc_rea = '0010' or abroad = 'Y')
         AND TO_CHAR(end_date, 'yyyymm') >= '200906'
         AND TRUNC(SYSDATE) - TRUNC(end_date) = 3
         AND evc_no NOT IN
             (SELECT t1.evc_no
                FROM HRA_EVCREC t1, HRA_IMMIDTL t2, HRA_IMMIMST t3
               WHERE t2.evc_no = t3.evc_no
                 AND (TO_CHAR(start_date, 'yyyymmdd') BETWEEN
                     TO_CHAR(t2.outdate, 'yyyymmdd') AND
                     TO_CHAR(t2.indate, 'yyyymmdd') OR
                     TO_CHAR(end_date, 'yyyymmdd') BETWEEN
                     TO_CHAR(t2.outdate, 'yyyymmdd') AND
                     TO_CHAR(t2.indate, 'yyyymmdd'))
                 AND t1.emp_no = t3.emp_no
                 AND TO_CHAR(end_date, 'yyyymm') >= '200906'
                 AND (evc_rea = '0010' or abroad = 'Y'))
      UNION ALL
      SELECT t1.emp_no,
             t2.ch_name,
             (CASE
               WHEN SUBSTR(T2.EMP_NO, 1, 1) NOT IN ('S', 'P', 'R') THEN
                'ed' || T2.EMP_NO || '@edah.org.tw'
               ELSE
                'ed' || T2.EMP_NO || '@edah.org.tw'
             END) AS e_mail,
             to_char(T1.Start_Date, 'yyyy-mm-dd') AS Start_Date
        FROM HRA_OFFREC t1, HRE_EMPBAS t2
       WHERE t1.emp_no = t2.emp_no
         AND status IN ('Y', 'U')
         AND t1.abroad = 'Y'
         AND TO_CHAR(end_date, 'yyyymm') >= '200906'
         and item_type = 'O'
         AND TRUNC(SYSDATE) - TRUNC(end_date) = 3
         AND (t1.emp_no, t1.start_date, t1.start_time) NOT IN
             (SELECT t1.emp_no, t1.start_date, t1.start_time
                FROM HRA_OFFREC t1, HRA_IMMIDTL t2, HRA_IMMIMST t3
               WHERE t2.evc_no = t3.evc_no
                 AND (TO_CHAR(start_date, 'yyyymmdd') BETWEEN
                     TO_CHAR(t2.outdate, 'yyyymmdd') AND
                     TO_CHAR(t2.indate, 'yyyymmdd') OR
                     TO_CHAR(end_date, 'yyyymmdd') BETWEEN
                     TO_CHAR(t2.outdate, 'yyyymmdd') AND
                     TO_CHAR(t2.indate, 'yyyymmdd'))
                 AND t1.emp_no = t3.emp_no
                 AND TO_CHAR(end_date, 'yyyymm') >= '200906'
                 and item_type = 'O'
                 and abroad = 'Y')
      UNION ALL
      SELECT t1.emp_no,
             t2.ch_name,
             (CASE
               WHEN SUBSTR(T2.EMP_NO, 1, 1) NOT IN ('S', 'P', 'R') THEN
                'ed' || T2.EMP_NO || '@edah.org.tw'
               ELSE
                'ed' || T2.EMP_NO || '@edah.org.tw'
             END) AS e_mail,
             to_char(T1.Start_Date, 'yyyy-mm-dd') AS Start_Date
        FROM HRA_SUPMST t1, HRE_EMPBAS t2
       WHERE t1.emp_no = t2.emp_no
         AND status IN ('Y', 'U')
         AND t1.abroad = 'Y'
         AND TO_CHAR(end_date, 'yyyymm') >= '200906'
         AND TRUNC(SYSDATE) - TRUNC(end_date) = 3
         AND (t1.emp_no, t1.start_date, t1.start_time) NOT IN
             (SELECT t1.emp_no, t1.start_date, t1.start_time
                FROM HRA_SUPMST t1, HRA_IMMIDTL t2, HRA_IMMIMST t3
               WHERE t2.evc_no = t3.evc_no
                 AND (TO_CHAR(start_date, 'yyyymmdd') BETWEEN
                     TO_CHAR(t2.outdate, 'yyyymmdd') AND
                     TO_CHAR(t2.indate, 'yyyymmdd') OR
                     TO_CHAR(end_date, 'yyyymmdd') BETWEEN
                     TO_CHAR(t2.outdate, 'yyyymmdd') AND
                     TO_CHAR(t2.indate, 'yyyymmdd'))
                 AND t1.emp_no = t3.emp_no
                 AND TO_CHAR(end_date, 'yyyymm') >= '200906'
                 AND abroad = 'Y')
      UNION ALL
      SELECT t1.emp_no,
             t2.ch_name,
             (CASE
               WHEN SUBSTR(T2.EMP_NO, 1, 1) NOT IN ('S', 'P', 'R') THEN
                'ed' || T2.EMP_NO || '@edah.org.tw'
               ELSE
                'ed' || T2.EMP_NO || '@edah.org.tw'
             END) AS e_mail,
             to_char(T1.Start_Date, 'yyyy-mm-dd') AS Start_Date
        FROM HRA_DEVCREC t1, HRE_EMPBAS t2
       WHERE t1.emp_no = t2.emp_no
         AND status IN ('Y', 'U')
         AND (t1.evc_rea = '0010' or abroad = 'Y')
         AND TO_CHAR(end_date, 'yyyymm') >= '200906'
         AND TRUNC(SYSDATE) - TRUNC(end_date) = 3
         AND Dis_All <> 'Y' --20200604 108482 醫師假卡全部銷假不列入
         AND evc_no NOT IN
             (SELECT t1.evc_no
                FROM HRA_DEVCREC t1, HRA_IMMIDTL t2, HRA_IMMIMST t3
               WHERE t2.evc_no = t3.evc_no
                 AND (TO_CHAR(start_date, 'yyyymmdd') BETWEEN
                     TO_CHAR(t2.outdate, 'yyyymmdd') AND
                     TO_CHAR(t2.indate, 'yyyymmdd') OR
                     TO_CHAR(end_date, 'yyyymmdd') BETWEEN
                     TO_CHAR(t2.outdate, 'yyyymmdd') AND
                     TO_CHAR(t2.indate, 'yyyymmdd'))
                 AND t1.emp_no = t3.emp_no
                 AND TO_CHAR(end_date, 'yyyymm') >= '200906'
                 AND (evc_rea = '0010' or abroad = 'Y'));
  BEGIN
    OPEN cursor1;
    LOOP
      FETCH cursor1
        INTO pEmpno, pChname, pEmail, pStartdate;
      EXIT WHEN cursor1%NOTFOUND;
    
      SELECT SEQNO_NEXT
        INTO sSEQNO
        FROM HR_SEQCTL
       WHERE SEQNO_TYPE = 'HRA';
    
      iMSG_NO := 'HRA' || TO_CHAR(SYSDATE, 'YYMM') || TO_CHAR(sSEQNO);
    
      INSERT INTO PUS_MSGMST
        (MSG_NO, MSG_FROM, MSG_TO, SUBJECT, MSG_DESC, MSG_DATE)
      VALUES
        (iMSG_NO,
         '感控',
         pChname || '(' || pEmpno || ')',
         '出入境管理-請假出國未填管理資料通知',
         '您有填寫假卡(請假起日' || pStartdate ||
         ')出國,但未填寫出入境管理相關資料,請至MIS 公用服務系統->公用出勤程式->出入境管理 中填寫相關資料',
         SYSDATE);
      INSERT INTO PUS_MSGBAS (MSG_NO, EMP_NO) VALUES (iMSG_NO, pEmpno);
      IF pEmail is not null THEN
        POST_HTML_MAIL('system@edah.org.tw',
                       pEmail,
                       'ed108482@edah.org.tw',
                       '1',
                       '出入境管理-請假出國未填管理資料通知',
                       '您有填寫假卡(請假起日' || pStartdate ||
                       ')出國,但未填寫出入境管理相關資料,請至MIS 公用服務系統->公用出勤程式->出入境管理 中填寫相關資料');
      END IF;
    
      UPDATE HR_SEQCTL
         SET SEQNO_NEXT = case when seqno_next + 1 > 100000 then 10000 else seqno_next + 1 end
       WHERE SEQNO_TYPE = 'HRA';
    
    END LOOP;
    commit;
    DocUnsignautomsg;
  END hrasend_mail_immi2;

  --醫師假卡未簽核完成通知
  PROCEDURE DocUnsignautomsg AS
    pMsg          VARCHAR2(10000);
    pEmpno        VARCHAR2(20);
    pChname       VARCHAR2(200);
    pCreationdate VARCHAR2(10);
    pStatus       VARCHAR2(20);
    pCnt          NUMBER;
    pOrgby        VARCHAR2(10);
    sSEQNO        NUMBER;
    iMSG_NO       VARCHAR2(20);
    pVacno        VARCHAR2(20);
    pVacname      VARCHAR2(40);
    pVacdate      VARCHAR2(40);
  
    CURSOR cursor1 IS
      select emp_no,
             (select ch_name from hre_empbas where emp_no = t1.emp_no) chname,
             to_char(trunc(creation_date), 'yyyy-mm-dd'),
             case
               when trunc(creation_date) = trunc(sysdate - 3) then
                '代理人'
               else
                '代理人或主管'
             end msgfor,
             count(emp_no) cnt,
             T1.ORG_BY
        from hra_devcrec t1
       where deputy_all = 'N'
         and dis_all = 'N'
         and trunc(creation_date) = trunc(sysdate - 3)
          or ((status = 'U' or deputy_all = 'N') and dis_all = 'N' and
             trunc(creation_date) = trunc(sysdate - 7))
       group by emp_no, trunc(creation_date), T1.ORG_BY;
       
    CURSOR cursor1Details IS
      SELECT EVC_NO,
             (SELECT VAC_NAME FROM HRA_DVCRLMST WHERE VAC_TYPE = T1.VAC_TYPE) AS VAC_NAME,
             TO_CHAR(START_DATE, 'yyyy-mm-dd') || ' ' || START_TIME || ' ~ ' ||
             TO_CHAR(END_DATE, 'yyyy-mm-dd') || ' ' || END_TIME AS VAC_DATE
        FROM HRA_DEVCREC T1
       WHERE ((DEPUTY_ALL = 'N' AND DIS_ALL = 'N' AND
             TRUNC(CREATION_DATE) = TRUNC(SYSDATE - 3)) OR
             ((STATUS = 'U' OR DEPUTY_ALL = 'N') AND DIS_ALL = 'N' AND
             TRUNC(CREATION_DATE) = TRUNC(SYSDATE - 7)))
         AND T1.EMP_NO = pEmpno
         AND TO_CHAR(T1.CREATION_DATE, 'yyyy-mm-dd') = pCreationdate;
  
  BEGIN
    pMsg := '';
  
    OPEN cursor1;
    LOOP
      FETCH cursor1
        INTO pEmpno, pChname, pCreationdate, pStatus, pCnt, pOrgby;
      EXIT WHEN cursor1%NOTFOUND;
    
      SELECT SEQNO_NEXT
        INTO sSEQNO
        FROM HR_SEQCTL
       WHERE SEQNO_TYPE = 'HRA';
    
      iMSG_NO := 'HRA' || TO_CHAR(SYSDATE, 'YYMM') || TO_CHAR(sSEQNO);
    
      pMsg := '提醒您於' || pCreationdate || '申請之' || to_char(pCnt) || '筆假卡，尚未通過' || 
              pStatus || '簽核：<br><br><table border="1"><tr><th>假卡單號</th><th>假別</th><th>請假起訖</th></tr>';
      OPEN cursor1Details;
      LOOP
      FETCH cursor1Details
      INTO pVacno, pVacname, pVacdate;
      EXIT WHEN cursor1Details%NOTFOUND;
        pMsg := pMsg||'<tr><td>'||pVacno||'</td><td>'||pVacname||'</td><td>'||pVacdate||'</td></tr>';
      END LOOP;
      CLOSE cursor1Details;
      
      pMsg := pMsg||'</table>';

      INSERT INTO PUS_MSGMST
        (MSG_NO, MSG_FROM, MSG_TO, SUBJECT, MSG_DESC, MSG_DATE, ORGAN_TYPE, ORG_BY)
      VALUES
        (iMSG_NO,
         '人力資源室',
         pEmpno || '(' || pChname || ')',
         '假卡未簽通知',
         pMsg,
         SYSDATE, pOrgby, pOrgby);
    
      INSERT INTO PUS_MSGBAS (MSG_NO, EMP_NO, ORGAN_TYPE, ORG_BY) VALUES (iMSG_NO, pEmpno, pOrgby, pOrgby);
          
      UPDATE HR_SEQCTL
         SET SEQNO_NEXT = case when seqno_next + 1 > 100000 then 10000 else seqno_next + 1 end
       WHERE SEQNO_TYPE = 'HRA';
    END LOOP;
    CLOSE cursor1;
  
    commit;
  
  END DocUnsignautomsg;

  PROCEDURE hrasend_mail_EF AS
  
    pempno      VARCHAR2(100);
    pchname     VARCHAR2(200);
    pdeptname   VARCHAR2(100);
    pposname    VARCHAR2(100);
    pvacname    VARCHAR2(100);
    pstatusname VARCHAR2(100);
    psd         VARCHAR2(100);
    pst         VARCHAR2(104);
    ped         VARCHAR2(100);
    pet         VARCHAR2(40);
    pevcrea     VARCHAR2(100);
    pvacdays    NUMBER(3);
    pvachrs     NUMBER(4, 1);
    prm         VARCHAR2(300);
  
    sTitle   VARCHAR2(100);
    sEEMail  VARCHAR2(120);
    sMessage CLOB;
  
    sTitleR   VARCHAR2(100);
    sMessageR VARCHAR2(10000);
    n_total_1 NUMBER(3);
    n_tota3_1 NUMBER(3);
    n_rang    NUMBER(3);
    n_start   NUMBER(3);
    n_end     NUMBER(3);
  
    CURSOR curtotal_1 is
      SELECT count(*)
        FROM (SELECT ORG_BY,
                     EMP_NO,
                     DEPT_NO,
                     VAC_TYPE,
                     VAC_RUL,
                     STATUS,
                     TO_CHAR(START_DATE, 'yyyy-mm-dd') SD,
                     START_TIME ST,
                     TO_CHAR(END_DATE, 'yyyy-mm-dd') ED,
                     END_TIME ET,
                     EVC_REA,
                     VAC_DAYS,
                     VAC_HRS,
                     REMARK
                FROM HRA_EVCREC
               WHERE STATUS IN ('Y', 'U')
                 AND START_DATE <= TRUNC(SYSDATE)
                 AND END_DATE >= TRUNC(SYSDATE)
              UNION ALL
              SELECT ORG_BY,
                     EMP_NO,
                     DEPT_NO,
                     'O1' VAC_TYPE,
                     'O1' VAC_RUL,
                     STATUS,
                     TO_CHAR(START_DATE, 'yyyy-mm-dd') SD,
                     START_TIME ST,
                     TO_CHAR(END_DATE, 'yyyy-mm-dd') ED,
                     END_TIME ET,
                     OTM_REA EVC_REA,
                     0 VAC_DAYS,
                     OTM_HRS VAC_HRS,
                     REMARK
                FROM HRA_OFFREC
               WHERE ITEM_TYPE = 'O'
                 AND STATUS IN ('Y', 'U')
                 AND START_DATE <= TRUNC(SYSDATE)
                 AND END_DATE >= TRUNC(SYSDATE)
              UNION ALL
              SELECT ORG_BY,
                     EMP_NO,
                     DEPT_NO,
                     'B0' VAC_TYPE,
                     'B0' VAC_RUL,
                     STATUS,
                     TO_CHAR(START_DATE, 'yyyy-mm-dd') SD,
                     START_TIME ST,
                     TO_CHAR(END_DATE, 'yyyy-mm-dd') ED,
                     END_TIME ET,
                     SUP_REA EVC_REA,
                     0 VAC_DAYS,
                     SUP_HRS VAC_HRS,
                     REMARK
                FROM HRA_SUPMST
               WHERE STATUS IN ('Y', 'U')
                 AND START_DATE <= TRUNC(SYSDATE)
                 AND END_DATE >= TRUNC(SYSDATE)) TA,
             HRE_EMPBAS TB
       WHERE TA.EMP_NO = TB.EMP_NO
         AND TB.ORGAN_TYPE = 'EF'
       ORDER BY TA.DEPT_NO, TA.EMP_NO;
  
    CURSOR cursor1(n_start in varchar2, n_end in varchar2) IS
      select EMP_NO,
             CH_NAME,
             DEPTNAME,
             POSNAME,
             VACNAME,
             STATUSNAME,
             ST,
             SD,
             ED,
             ET,
             EVCREA,
             VAC_DAYS,
             VAC_HRS,
             REMARK
        from (SELECT (ROW_NUMBER() OVER(ORDER BY TA.DEPT_NO, TA.EMP_NO)) num1,
                     TA.EMP_NO,
                     TB.CH_NAME,
                     (SELECT CH_NAME
                        FROM HRE_ORGBAS
                       WHERE DEPT_NO = TA.DEPT_NO) DEPTNAME,
                     (SELECT CH_NAME FROM HRE_POSMST WHERE POS_NO = TB.POS_NO) POSNAME,
                     CASE TA.VAC_TYPE
                       WHEN 'O1' THEN
                        '借休'
                       WHEN 'B0' THEN
                        '補休'
                       ELSE
                        (SELECT VAC_NAME
                           FROM HRA_VCRLMST
                          WHERE VAC_TYPE = TA.VAC_TYPE)
                     END VACNAME,
                     CASE TA.STATUS
                       WHEN 'Y' THEN
                        '准'
                       WHEN 'U' THEN
                        '申請'
                       ELSE
                        ''
                     END STATUSNAME,
                     TA.SD,
                     TA.ST,
                     TA.ED,
                     TA.ET,
                     CASE VAC_TYPE
                       WHEN 'B0' THEN
                        (SELECT CODE_NAME
                           FROM HR_CODEDTL
                          WHERE CODE_TYPE = 'HRA22'
                            AND CODE_NO = TA.EVC_REA)
                       WHEN 'O1' THEN
                        (SELECT CODE_NAME
                           FROM HR_CODEDTL
                          WHERE CODE_TYPE = 'HRA51'
                            AND CODE_NO = TA.EVC_REA)
                       ELSE
                        (SELECT CODE_NAME
                           FROM HR_CODEDTL
                          WHERE CODE_TYPE = 'HRA08'
                            AND CODE_NO = TA.EVC_REA)
                     END EVCREA,
                     VAC_DAYS,
                     VAC_HRS,
                     TA.REMARK
                FROM (SELECT ORG_BY,
                             EMP_NO,
                             DEPT_NO,
                             VAC_TYPE,
                             VAC_RUL,
                             STATUS,
                             TO_CHAR(START_DATE, 'yyyy-mm-dd') SD,
                             START_TIME ST,
                             TO_CHAR(END_DATE, 'yyyy-mm-dd') ED,
                             END_TIME ET,
                             EVC_REA,
                             VAC_DAYS,
                             VAC_HRS,
                             REMARK
                        FROM HRA_EVCREC
                       WHERE STATUS IN ('Y', 'U')
                         AND START_DATE <= TRUNC(SYSDATE)
                         AND END_DATE >= TRUNC(SYSDATE)
                      UNION ALL
                      SELECT ORG_BY,
                             EMP_NO,
                             DEPT_NO,
                             'O1' VAC_TYPE,
                             'O1' VAC_RUL,
                             STATUS,
                             TO_CHAR(START_DATE, 'yyyy-mm-dd') SD,
                             START_TIME ST,
                             TO_CHAR(END_DATE, 'yyyy-mm-dd') ED,
                             END_TIME ET,
                             OTM_REA EVC_REA,
                             0 VAC_DAYS,
                             OTM_HRS VAC_HRS,
                             REMARK
                        FROM HRA_OFFREC
                       WHERE ITEM_TYPE = 'O'
                         AND STATUS IN ('Y', 'U')
                         AND START_DATE <= TRUNC(SYSDATE)
                         AND END_DATE >= TRUNC(SYSDATE)
                      UNION ALL
                      SELECT ORG_BY,
                             EMP_NO,
                             DEPT_NO,
                             'B0' VAC_TYPE,
                             'B0' VAC_RUL,
                             STATUS,
                             TO_CHAR(START_DATE, 'yyyy-mm-dd') SD,
                             START_TIME ST,
                             TO_CHAR(END_DATE, 'yyyy-mm-dd') ED,
                             END_TIME ET,
                             SUP_REA EVC_REA,
                             0 VAC_DAYS,
                             SUP_HRS VAC_HRS,
                             REMARK
                        FROM HRA_SUPMST
                       WHERE STATUS IN ('Y', 'U')
                         AND START_DATE <= TRUNC(SYSDATE)
                         AND END_DATE >= TRUNC(SYSDATE)) TA,
                     HRE_EMPBAS TB
               WHERE TA.EMP_NO = TB.EMP_NO
                 AND TB.ORGAN_TYPE = 'EF'
               ORDER BY TA.DEPT_NO, TA.EMP_NO)
       WHERE NUM1 > n_start
         AND NUM1 <= n_end;
  
    CURSOR cursor2 IS
      SELECT CODE_NAME
        FROM HR_CODEDTL
       WHERE CODE_TYPE = 'HRA99'
         AND CODE_NO LIKE 'D%'
         AND DISABLED = 'N';
  
    CURSOR cursor3(n_start in varchar2, n_end in varchar2) IS
      SELECT EMP_NO,
             CH_NAME,
             DEPTNAME,
             POSNAME,
             VACNAME,
             STATUSNAME,
             SD,
             ST,
             ED,
             ET,
             EVCREA,
             VAC_DAYS,
             VAC_HRS,
             REMARK
        FROM (SELECT (ROW_NUMBER()
                      OVER(ORDER BY TA.DEPT_NO, TB.POS_NO DESC, TA.EMP_NO)) num1,
                     TA.EMP_NO,
                     TB.CH_NAME,
                     (SELECT CH_NAME
                        FROM HRE_ORGBAS
                       WHERE DEPT_NO = TA.DEPT_NO) DEPTNAME,
                     (SELECT CH_NAME FROM HRE_POSMST WHERE POS_NO = TB.POS_NO) POSNAME,
                     (SELECT VAC_NAME
                        FROM HRA_DVCRLMST
                       WHERE VAC_TYPE = TA.VAC_TYPE) VACNAME,
                     CASE TA.STATUS
                       WHEN 'Y' THEN
                        '准'
                       WHEN 'U' THEN
                        '申請'
                       ELSE
                        ''
                     END STATUSNAME,
                     TA.SD,
                     TA.ST,
                     TA.ED,
                     TA.ET,
                     (SELECT CODE_NAME
                        FROM HR_CODEDTL
                       WHERE CODE_TYPE = 'HRA08'
                         AND CODE_NO = TA.EVC_REA) EVCREA,
                     VAC_DAYS,
                     VAC_HRS,
                     TA.REMARK
                FROM (SELECT ORG_BY,
                             EMP_NO,
                             DEPT_NO,
                             VAC_TYPE,
                             VAC_RUL,
                             STATUS,
                             TO_CHAR(START_DATE, 'yyyy-mm-dd') SD,
                             START_TIME ST,
                             TO_CHAR(END_DATE, 'yyyy-mm-dd') ED,
                             END_TIME ET,
                             EVC_REA,
                             VAC_DAYS,
                             VAC_HRS,
                             REMARK
                        FROM HRA_DEVCREC
                       WHERE STATUS IN ('Y', 'U')
                         AND START_DATE <= TRUNC(SYSDATE)
                         AND END_DATE >= TRUNC(SYSDATE)
                         AND DIS_ALL <> 'Y') TA,
                     HRE_EMPBAS TB
               WHERE TA.EMP_NO = TB.EMP_NO
                 AND TB.ORGAN_TYPE = 'EF')
       WHERE num1 >= n_start
         AND num1 <= n_end;
  
    CURSOR curtota3_1 IS
      SELECT COUNT(*)
        FROM (SELECT ORG_BY,
                     EMP_NO,
                     DEPT_NO,
                     VAC_TYPE,
                     VAC_RUL,
                     STATUS,
                     TO_CHAR(START_DATE, 'yyyy-mm-dd') SD,
                     START_TIME ST,
                     TO_CHAR(END_DATE, 'yyyy-mm-dd') ED,
                     END_TIME ET,
                     EVC_REA,
                     VAC_DAYS,
                     VAC_HRS,
                     REMARK
                FROM HRA_DEVCREC
               WHERE STATUS IN ('Y', 'U')
                 AND START_DATE <= TRUNC(SYSDATE)
                 AND END_DATE >= TRUNC(SYSDATE)
                 AND DIS_ALL <> 'Y') TA,
             HRE_EMPBAS TB
       WHERE TA.EMP_NO = TB.EMP_NO
         AND TB.ORGAN_TYPE = 'EF'
       ORDER BY TA.DEPT_NO, TB.POS_NO DESC, TA.EMP_NO;
  
  BEGIN
    sMessage  := '';
    sMessageR := '';
  
    open curtotal_1;
    loop
      fetch curtotal_1
        into n_total_1;
      EXIT when curtotal_1%NOTFOUND;
    
      n_rang := CEIL(n_total_1 / 12);
      for i in 1 .. n_rang loop
        if i = 1 then
          IF n_total_1 <= 12 THEN
            n_start := 1;
            n_end   := n_total_1;
          ELSE
            n_start := 1;
            n_end   := 12;
          END IF;
        else
          n_start := n_end + 1;
          n_end   := n_end + 12;
        end if;
      
        sMessage := NULL;
      
        OPEN cursor1(n_start, n_end);
        pempno := '';
        LOOP
          FETCH cursor1
            INTO pempno, pchname, pdeptname, pposname, pvacname, pstatusname, psd, pst, ped, pet, pevcrea, pvacdays, pvachrs, prm;
          EXIT WHEN cursor1%NOTFOUND;
        
          IF sMessage IS NULL THEN
            sMessage := '<table border="1" width="100%">' ||
                        '<tr><th>工號</th><th>姓名</th><th>部門名稱</th><th>職稱</th><th>假別</th>' ||
                        '<th>狀態</th><th>開始日期</th><th>開始時間</th><th>結束日期</th><th>結束時間</th>' ||
                        '<th>天數</th><th>時數</th><th>請假理由</th><th>其他原因</th></tr>';
          END IF;
          IF pempno IS NOT NULL THEN
            sMessage := sMessage || '<tr><td>' || pempno || '</td><td>' ||
                        pchname || '</td><td>' || pdeptname || '</td>' ||
                        '<td>' || pposname || '</td><td>' || pvacname ||
                        '</td><td>' || pstatusname || '</td>' || '<td>' || psd ||
                        '</td><td>' || pst || '</td><td>' || ped ||
                        '</td><td>' || pet || '</td>' || '<td>' || pvacdays ||
                        '</td><td>' || pvachrs || '</td><td>' || pevcrea ||
                        '</td><td>' || prm || '</td></tr>';
          ELSE
            sMessage := sMessage || '<tr><td colspan="14">無人員請假</td></tr>';
          END IF;
        
        END LOOP;
        CLOSE cursor1;
      
        sTitle := '今日（非醫師）請假通知_大昌醫院(' || TO_CHAR(SYSDATE, 'yyyy-mm-dd') || ')';
      
        IF sMessage IS NULL THEN
          sMessage := '<table border="1" width="100%">' ||
                      '<tr><th>工號</th><th>姓名</th><th>部門名稱</th><th>職稱</th><th>假別</th>' ||
                      '<th>狀態</th><th>開始日期</th><th>開始時間</th><th>結束日期</th><th>結束時間</th>' ||
                      '<th>天數</th><th>時數</th><th>請假理由</th><th>其他原因</th></tr>' ||
                      '<tr><td colspan="14">無人員請假</td></tr>';
        END IF;
      
        IF (sMessage IS NOT NULL) THEN
          sMessage := sMessage || '</table>';
          OPEN cursor2;
          LOOP
            FETCH cursor2
              INTO sEEMail;
            EXIT WHEN cursor2%NOTFOUND;
          
            Ehrphrafunc_Pkg.POST_HTML_MAIL('system@edah.org.tw',
                                           sEEMail,
                                           '',
                                           '1',
                                           sTitle,
                                           sMessage);
          
          END LOOP;
          CLOSE cursor2;
        END IF;
      end loop;
    
    END LOOP;
    CLOSE curtotal_1;
  
    open curtota3_1;
    loop
      fetch curtota3_1
        into n_tota3_1;
      EXIT when curtota3_1%NOTFOUND;
    
      n_rang := CEIL(n_tota3_1 / 10);
      for i in 1 .. n_rang loop
        if i = 1 then
          IF n_tota3_1 <= 10 THEN
            n_start := 1;
            n_end   := n_tota3_1;
          ELSE
            n_start := 1;
            n_end   := 10;
          END IF;
        else
          n_start := n_end + 1;
          n_end   := n_end + 10;
        end if;
      
        OPEN cursor3(n_start, n_end);
      
        pempno := '';
        LOOP
          FETCH cursor3
            INTO pempno, pchname, pdeptname, pposname, pvacname, pstatusname, psd, pst, ped, pet, pevcrea, pvacdays, pvachrs, prm;
          EXIT WHEN cursor3%NOTFOUND;
        
          IF sMessageR IS NULL THEN
            sMessageR := '<table border="1" width="100%">' ||
                         '<tr><th>工號</th><th>姓名</th><th>部門名稱</th><th>職稱</th><th>假別</th>' ||
                         '<th>狀態</th><th>開始日期</th><th>開始時間</th><th>結束日期</th><th>結束時間</th>' ||
                         '<th>天數</th><th>時數</th><th>請假理由</th><th>其他原因</th></tr>';
          END IF;
          IF pempno IS NOT NULL THEN
            sMessageR := sMessageR || '<tr><td>' || pempno || '</td><td>' ||
                         pchname || '</td><td>' || pdeptname || '</td>' ||
                         '<td>' || pposname || '</td><td>' || pvacname ||
                         '</td><td>' || pstatusname || '</td>' || '<td>' || psd ||
                         '</td><td>' || pst || '</td><td>' || ped ||
                         '</td><td>' || pet || '</td>' || '<td>' ||
                         pvacdays || '</td><td>' || pvachrs || '</td><td>' ||
                         pevcrea || '</td><td>' || prm || '</td></tr>';
          ELSE
            sMessageR := sMessageR ||
                         '<tr><td colspan="14">無醫師請假</td></tr>';
          END IF;
        
        END LOOP;
        CLOSE cursor3;
      
        sTitleR := '今日醫師請假通知_大昌醫院(' || TO_CHAR(SYSDATE, 'yyyy-mm-dd') || ')';
      
        IF sMessageR IS NULL THEN
          sMessageR := '<table border="1" width="100%">' ||
                       '<tr><th>工號</th><th>姓名</th><th>部門名稱</th><th>職稱</th><th>假別</th>' ||
                       '<th>狀態</th><th>開始日期</th><th>開始時間</th><th>結束日期</th><th>結束時間</th>' ||
                       '<th>天數</th><th>時數</th><th>請假理由</th><th>其他原因</th></tr>' ||
                       '<tr><td colspan="14">無醫師請假</td></tr>';
        END IF;
      
        IF (sMessageR IS NOT NULL) THEN
          sMessageR := sMessageR || '</table>';
          OPEN cursor2;
          LOOP
            FETCH cursor2
              INTO sEEMail;
            EXIT WHEN cursor2%NOTFOUND;
          
            Ehrphrafunc_Pkg.POST_HTML_MAIL('system@edah.org.tw',
                                           sEEMail,
                                           '',
                                           '1',
                                           sTitleR,
                                           sMessageR);
          
          END LOOP;
          CLOSE cursor2;
        END IF;
        sMessageR := '';
      END LOOP;
    END LOOP;
    CLOSE curtota3_1;
  
  END hrasend_mail_EF;

  PROCEDURE CheckPermitId_mail AS
    pempno    VARCHAR2(20);
    pdate     VARCHAR2(20);
    ppermitid VARCHAR2(20);
  
    sTitle   VARCHAR2(100);
    sEEMail  VARCHAR2(120);
    sMessage VARCHAR2(32767);
  
    CURSOR cursor1 IS
      SELECT EMP_NO,
             TO_CHAR(START_DATE, 'yyyy-mm-dd') AS START_DATE,
             PERMIT_ID
        FROM HRA_OFFREC
       WHERE PERMIT_ID = '100005'
         AND STATUS NOT IN ('Y', 'N')
         AND EMP_NO <> '100102'
      UNION
      SELECT EMP_NO,
             TO_CHAR(START_DATE, 'yyyy-mm-dd') AS START_DATE,
             PERMIT_ID
        FROM HRA_OTMSIGN
       WHERE PERMIT_ID = '100005'
         AND STATUS NOT IN ('Y', 'N')
         AND OTM_FLAG = 'B'
         AND EMP_NO <> '100102';
  
    CURSOR cursor2 IS --收件人
      SELECT 'ed108154@edah.org.tw'
        FROM dual --李采柔
      UNION ALL
      SELECT 'ed108482@edah.org.tw'
        FROM dual --葉鈴雅
      UNION ALL
      SELECT 'ed100037@edah.org.tw'
        FROM dual --鄭淑宏
      ;
  
  BEGIN
    sMessage := '';
    sEEMail  := '';
    sTitle   := '確認加班單審核者';
  
    OPEN cursor1;
    LOOP
      FETCH cursor1
        INTO pempno, pdate, ppermitid;
      EXIT WHEN cursor1%NOTFOUND;
      IF sMessage IS NULL THEN
        sMessage := '<table border="1"><tr><td>工號</td><td>日期</td><td>審核者</td></tr>' ||
                    '<tr><td>' || pempno || '</td><td>' || pdate ||
                    '</td><td>' || ppermitid || '</td></tr>';
      ELSE
        sMessage := sMessage || '<tr><td>' || pempno || '</td><td>' ||
                    pdate || '</td><td>' || ppermitid || '</td></tr>';
      END IF;
    END LOOP;
    CLOSE cursor1;
  
    IF (sMessage is not null) THEN
      sMessage := sMessage || '</table>';
      OPEN cursor2;
      LOOP
        FETCH cursor2
          INTO sEEMail;
        EXIT WHEN cursor2%NOTFOUND;
        ehrphrafunc_pkg.POST_HTML_MAIL('system@edah.org.tw',
                                       sEEMail,
                                       '',
                                       '1',
                                       sTitle,
                                       sMessage);
      END LOOP;
      CLOSE cursor2;
    END IF;
  END CheckPermitId_mail;

  PROCEDURE hrasend_mail_IT AS
    pempno      VARCHAR2(20);
    pchname     VARCHAR2(200);
    pdeptname   VARCHAR2(60);
    pposname    VARCHAR2(60);
    pvacname    VARCHAR2(40);
    pstatusname VARCHAR2(10);
    psd         VARCHAR2(10);
    pst         VARCHAR2(4);
    ped         VARCHAR2(10);
    pet         VARCHAR2(4);
    pevcrea     VARCHAR2(100);
    pvacdays    NUMBER(3);
    pvachrs     NUMBER(4, 1);
    prm         VARCHAR2(300);
    prm2        VARCHAR2(50);
  
    sTitle    VARCHAR2(100);
    sEEMail   VARCHAR2(120);
    sMessage  VARCHAR2(20000);
    sMessage2 VARCHAR2(20000);
    sMessage3 VARCHAR2(500);
  
    iCntTime   NUMBER; --共多少居隔人次(一人隔離過幾次算幾次)
    iCntNow    NUMBER; --正在居隔中人數
    iCntCovid  NUMBER; --本人確診人數
    iCntPerson NUMBER; --共多少人居隔過
    iCntAll    NUMBER; --資訊部總人數
    iPercent   NUMBER; --居隔率(iCntPerson/iCntAll)*100 百分比四捨五入至整數
    iPercentC  NUMBER; --確診率(iCntCovid/iCntAll)*100 百分比四捨五入至整數
  
    CURSOR cursor1 IS
      SELECT TA.EMP_NO,
             TB.CH_NAME,
             (SELECT CH_NAME
                FROM HRE_ORGBAS
               WHERE DEPT_NO = TA.DEPT_NO
                 AND ORGAN_TYPE = TA.ORG_BY) DEPTNAME,
             (SELECT CH_NAME FROM HRE_POSMST WHERE POS_NO = TB.POS_NO) POSNAME,
             CASE TA.VAC_TYPE
               WHEN 'B0' THEN
                '補休'
               ELSE
                (SELECT VAC_NAME
                   FROM HRA_VCRLMST
                  WHERE VAC_TYPE = TA.VAC_TYPE)
             END VACNAME,
             CASE TA.STATUS
               WHEN 'Y' THEN
                '准'
               WHEN 'U' THEN
                CASE
               WHEN
                (SELECT COUNT(*) FROM HRA_EVCFLOW WHERE EVC_NO = TA.EVC_NO) = 0 THEN
                '申請'
               WHEN
                (SELECT COUNT(*) FROM HRA_EVCFLOW WHERE EVC_NO = TA.EVC_NO) = 1 THEN
                '初審'
               ELSE
                '覆審'
             END ELSE '' END STATUSNAME,
             TA.SD,
             TA.ST,
             TA.ED,
             TA.ET,
             CASE VAC_TYPE
               WHEN 'B0' THEN
                (SELECT CODE_NAME
                   FROM HR_CODEDTL
                  WHERE CODE_TYPE = 'HRA22'
                    AND CODE_NO = TA.EVC_REA)
               ELSE
                (SELECT CODE_NAME
                   FROM HR_CODEDTL
                  WHERE CODE_TYPE = 'HRA08'
                    AND CODE_NO = TA.EVC_REA)
             END EVCREA,
             VAC_DAYS,
             VAC_HRS,
             TA.REMARK,
             (SELECT PUS_CODEBAS.CODE_NAME
                FROM PUS_CODEBAS
               WHERE CODE_TYPE = 'IT01'
                 AND CODE_NO = TA.EMP_NO
                 AND TO_DATE(CODE_DTL, 'yyyy/mm/dd') >= TRUNC(SYSDATE)) AS REMARK2
        FROM (SELECT EVC_NO,
                     ORG_BY,
                     EMP_NO,
                     DEPT_NO,
                     VAC_TYPE,
                     VAC_RUL,
                     STATUS,
                     SD,
                     ST,
                     ED,
                     ET,
                     EVC_REA,
                     VAC_DAYS,
                     VAC_HRS,
                     REMARK,
                     ABROAD
                FROM (SELECT T1.EVC_NO,
                             T1.ORG_BY,
                             T1.EMP_NO,
                             T1.DEPT_NO,
                             VAC_TYPE,
                             VAC_RUL,
                             STATUS,
                             TO_CHAR(START_DATE, 'yyyy-mm-dd') SD,
                             START_TIME ST,
                             TO_CHAR(END_DATE, 'yyyy-mm-dd') ED,
                             END_TIME ET,
                             EVC_REA,
                             VAC_DAYS,
                             VAC_HRS,
                             REMARK,
                             ABROAD
                        FROM HRA_EVCREC T1
                       WHERE STATUS IN ('Y', 'U'))
               WHERE SD <= TO_CHAR(SYSDATE, 'yyyy-mm-dd')
                 AND ED >= TO_CHAR(SYSDATE, 'yyyy-mm-dd')
                 AND EMP_NO IN (SELECT CODE_NO
                                  FROM PUS_CODEBAS
                                 WHERE CODE_TYPE = 'IT01'
                                   AND TO_DATE(CODE_DTL, 'yyyy/mm/dd') >=
                                       TRUNC(SYSDATE))
              UNION ALL
              SELECT '',
                     ORG_BY,
                     EMP_NO,
                     DEPT_NO,
                     VAC_TYPE,
                     VAC_RUL,
                     STATUS,
                     SD,
                     ST,
                     ED,
                     ET,
                     EVC_REA,
                     VAC_DAYS,
                     VAC_HRS,
                     REMARK,
                     ABROAD
                FROM (SELECT ORG_BY,
                             EMP_NO,
                             DEPT_NO,
                             'B0' VAC_TYPE,
                             'B0' VAC_RUL,
                             STATUS,
                             TO_CHAR(START_DATE, 'yyyy-mm-dd') SD,
                             START_TIME ST,
                             TO_CHAR(END_DATE, 'yyyy-mm-dd') ED,
                             END_TIME ET,
                             SUP_REA EVC_REA,
                             0 VAC_DAYS,
                             SUP_HRS VAC_HRS,
                             REMARK,
                             ABROAD
                        FROM HRA_SUPMST T1
                       WHERE STATUS IN ('Y', 'U'))
               WHERE SD <= TO_CHAR(SYSDATE, 'yyyy-mm-dd')
                 AND ED >= TO_CHAR(SYSDATE, 'yyyy-mm-dd')
                 AND EMP_NO IN (SELECT CODE_NO
                                  FROM PUS_CODEBAS
                                 WHERE CODE_TYPE = 'IT01'
                                   AND TO_DATE(CODE_DTL, 'yyyy/mm/dd') >=
                                       TRUNC(SYSDATE))) TA,
             HRE_EMPBAS TB
       WHERE TA.EMP_NO = TB.EMP_NO
       ORDER BY TA.SD, TA.ED, TA.ST, TA.ET;
  
    CURSOR cursor3 IS
      SELECT A.CODE_NO,
             B.CH_NAME,
             (SELECT CH_NAME FROM HRE_ORGBAS WHERE DEPT_NO = B.DEPT_NO) DEPTNAME,
             (SELECT CH_NAME FROM HRE_POSMST WHERE POS_NO = B.POS_NO) POSNAME,
             '人員尚未申請假卡或補休' AS REMARK,
             A.CODE_NAME AS REMARK2
        FROM PUS_CODEBAS A, HRE_EMPBAS B
       WHERE A.CODE_NO = B.EMP_NO
         AND A.CODE_TYPE = 'IT01'
         AND 0 = (SELECT COUNT(*)
                    FROM HRA_EVCREC
                   WHERE START_DATE <= TRUNC(SYSDATE)
                     AND END_DATE >= TRUNC(SYSDATE)
                     AND EMP_NO = A.CODE_NO
                     AND TO_CHAR(SYSDATE, 'yyyy-mm-dd') <= A.CODE_DTL)
         AND 0 = (SELECT COUNT(*)
                    FROM HRA_SUPMST
                   WHERE START_DATE <= TRUNC(SYSDATE)
                     AND END_DATE >= TRUNC(SYSDATE)
                     AND EMP_NO = A.CODE_NO
                     AND TO_CHAR(SYSDATE, 'yyyy-mm-dd') <= A.CODE_DTL)
         AND TO_CHAR(SYSDATE, 'yyyy-mm-dd') <= A.CODE_DTL
       ORDER BY A.CODE_NAME;
  
    CURSOR cursor4 IS
      SELECT A.CODE_NO,
             B.CH_NAME,
             (SELECT CH_NAME FROM HRE_ORGBAS WHERE DEPT_NO = B.DEPT_NO) DEPTNAME,
             (SELECT CH_NAME FROM HRE_POSMST WHERE POS_NO = B.POS_NO) POSNAME,
             A.CODE_NAME
        FROM PUS_CODEBAS A, HRE_EMPBAS B
       WHERE A.CODE_NO = B.EMP_NO
         AND A.CODE_TYPE = 'IT01'
         AND TO_CHAR(SYSDATE, 'yyyy-mm-dd') > A.CODE_DTL
         AND B.DISABLED = 'N'
       ORDER BY A.CODE_DTL DESC;
  
    CURSOR cursor2 IS
      SELECT 'ed100009@edah.org.tw'
        FROM DUAL
      UNION ALL
      SELECT 'ed100014@edah.org.tw'
        FROM DUAL
      UNION ALL
      SELECT 'ed100037@edah.org.tw'
        FROM DUAL
      UNION ALL
      SELECT 'ed104857@edah.org.tw'
        FROM DUAL
      UNION ALL
      SELECT 'ed100084@edah.org.tw'
        FROM DUAL
      UNION ALL
      SELECT 'ed100052@edah.org.tw'
        FROM DUAL
      UNION ALL
      SELECT 'ed107403@edah.org.tw'
        FROM DUAL
      UNION ALL
      SELECT 'ed108024@edah.org.tw'
        FROM DUAL
      UNION ALL
      SELECT 'ed108154@edah.org.tw'
        FROM DUAL
      UNION ALL
      SELECT 'ed108482@edah.org.tw' FROM DUAL;
  
  BEGIN
    sMessage := '';
    OPEN cursor1;
    LOOP
      FETCH cursor1
        INTO pempno, pchname, pdeptname, pposname, pvacname, pstatusname, psd, pst, ped, pet, pevcrea, pvacdays, pvachrs, prm, prm2;
      EXIT WHEN cursor1%NOTFOUND;
    
      IF sMessage is null THEN
        sMessage := '<table border="1" width="100%"><TR><TD>工號</td><TD>姓名</td><TD>部門名稱</td><TD>職稱</td><TD>假別</td>';
        sMessage := sMessage ||
                    '<TD>狀態</td><TD>開始日期</td><TD>開始時間</td><TD>結束日期</td><TD>結束時間</td>';
        sMessage := sMessage ||
                    '<TD>天數</td><TD>時數</td><TD>請假理由</td><TD>其他原因</td><TD>備註</td></tr>';
        sMessage := sMessage || '<TR><TD>' || pempno || '</td><TD>' ||
                    pchname || '</td><TD>' || pdeptname || '</td>';
        sMessage := sMessage || '<TD>' || pposname || '</td><TD>' ||
                    pvacname || '</td><TD>' || pstatusname || '</td>';
        sMessage := sMessage || '<TD>' || psd || '</td><TD>' || pst ||
                    '</td><TD>' || ped || '</td>';
        sMessage := sMessage || '<TD>' || pet || '</td><TD>' || pvacdays ||
                    '</td><TD>' || pvachrs || '</td>';
        sMessage := sMessage || '<TD>' || pevcrea || '</td><TD>' || prm ||
                    '</td><TD>' || prm2 || '</td></tr>';
      ELSE
        sMessage := sMessage || '<TR><TD>' || pempno || '</td><TD>' ||
                    pchname || '</td><TD>' || pdeptname || '</td>';
        sMessage := sMessage || '<TD>' || pposname || '</td><TD>' ||
                    pvacname || '</td><TD>' || pstatusname || '</td>';
        sMessage := sMessage || '<TD>' || psd || '</td><TD>' || pst ||
                    '</td><TD>' || ped || '</td>';
        sMessage := sMessage || '<TD>' || pet || '</td><TD>' || pvacdays ||
                    '</td><TD>' || pvachrs || '</td>';
        sMessage := sMessage || '<TD>' || pevcrea || '</td><TD>' || prm ||
                    '</td><TD>' || prm2 || '</td></tr>';
      END IF;
    END LOOP;
    CLOSE cursor1;
  
    OPEN cursor3;
    LOOP
      FETCH cursor3
        INTO pempno, pchname, pdeptname, pposname, prm, prm2;
      EXIT WHEN cursor3%NOTFOUND;
      IF sMessage IS NULL THEN
        sMessage := '<table border="1" width="100%"><TR><TD>工號</td><TD>姓名</td><TD>部門名稱</td><TD>職稱</td><TD>假別</td>';
        sMessage := sMessage ||
                    '<TD>狀態</td><TD>開始日期</td><TD>開始時間</td><TD>結束日期</td><TD>結束時間</td>';
        sMessage := sMessage ||
                    '<TD>天數</td><TD>時數</td><TD>請假理由</td><TD>其他原因</td><TD>備註</td></tr>';
        sMessage := sMessage || '<TR><TD>' || pempno || '</td><TD>' ||
                    pchname || '</td><TD>' || pdeptname || '</td>';
        sMessage := sMessage || '<TD>' || pposname ||
                    '</td><TD colspan="10">' || prm || '</td><TD>' || prm2 ||
                    '</td></tr>';
      ELSE
        sMessage := sMessage || '<TR><TD>' || pempno || '</td><TD>' ||
                    pchname || '</td><TD>' || pdeptname || '</td>';
        sMessage := sMessage || '<TD>' || pposname ||
                    '</td><TD colspan="10">' || prm || '</td><TD>' || prm2 ||
                    '</td></tr>';
      END IF;
    END LOOP;
    CLOSE cursor3;
  
    OPEN cursor4;
    LOOP
      FETCH cursor4
        INTO pempno, pchname, pdeptname, pposname, prm;
      EXIT WHEN cursor4%NOTFOUND;
      IF sMessage2 IS NULL THEN
        sMessage2 := '<table border="1" width="50%"><TR><TD>工號</td><TD>姓名</td><TD>部門名稱</td><TD>職稱</td><TD>備註</td></tr>' ||
                     '<TR><TD>' || pempno || '</td><TD>' || pchname ||
                     '</td><TD>' || pdeptname || '</td><TD>' || pposname ||
                     '</td><TD>' || prm || '</td></tr>';
      ELSE
        sMessage2 := sMessage2 || '<TR><TD>' || pempno || '</td><TD>' ||
                     pchname || '</td><TD>' || pdeptname || '</td><TD>' ||
                     pposname || '</td><TD>' || prm || '</td></tr>';
      END IF;
    END LOOP;
    CLOSE cursor4;
  
    sTitle := '今日資訊部COVID-19人員請假彙總表(' || TO_CHAR(SYSDATE, 'yyyy-mm-dd') || ')';
  
    BEGIN
      SELECT COUNT(*)
        INTO iCntTime
        FROM PUS_CODEBAS
       WHERE CODE_TYPE = 'IT01'
         AND CODE_NO IN
             (SELECT EMP_NO FROM HRE_EMPBAS WHERE DISABLED = 'N');
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        iCntTime := 0;
    END;
    BEGIN
      SELECT COUNT(*)
        INTO iCntNow
        FROM PUS_CODEBAS
       WHERE CODE_TYPE = 'IT01'
         AND CODE_NO IN
             (SELECT EMP_NO FROM HRE_EMPBAS WHERE DISABLED = 'N')
         AND TO_DATE(CODE_DTL, 'yyyy/mm/dd') >= TRUNC(SYSDATE);
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        iCntNow := 0;
    END;
    BEGIN
      SELECT COUNT(*)
        INTO iCntCovid
        FROM (SELECT DISTINCT (CODE_NO)
                FROM PUS_CODEBAS
               WHERE CODE_TYPE = 'IT01'
                 AND CODE_NO IN
                     (SELECT EMP_NO FROM HRE_EMPBAS WHERE DISABLED = 'N')
                 AND CODE_VALUE = 1);
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        iCntCovid := 0;
    END;
    BEGIN
      SELECT COUNT(*)
        INTO iCntPerson
        FROM PUS_CODEDTL
       WHERE CODE_TYPE = 'IT01'
         AND CODE_NO IN
             (SELECT EMP_NO FROM HRE_EMPBAS WHERE DISABLED = 'N');
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        iCntPerson := 0;
    END;
    BEGIN
      SELECT COUNT(*)
        INTO iCntAll
        FROM HRE_EMPBAS
       WHERE DEPT_NO IN
             ('5500', '5510', '5511', '5512', '5513', '5520', '5521', '5522',
              '5530', '5531', '5532', 'CA5000', 'CA5100', 'CA5110', 'CA5120',
              'CA5200', 'CA5210', 'CA5220', 'CA5300', 'CA5310', 'CA5320',
              'CA5330', 'DA5000', 'DA5010')
         AND DISABLED = 'N';
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        iCntAll := 0;
    END;
  
    iPercent  := ROUND((iCntPerson / iCntAll) * 100);
    iPercentC := ROUND((iCntCovid / iCntAll) * 100);
  
    sMessage3 := '資訊部今日隔離中人數共' || iCntNow || '人，累計共' || iCntCovid ||
                 '人確診，確診率：' || iPercentC || '%。<br>' || '累計居家隔離共' ||
                 iCntPerson || '人(' || iCntTime || '人次)，居隔率：' || iPercent || '%。';
    /*sMessage3 := '資訊部目前居家隔離總計'||iCntTime||'人次，共'||iCntPerson||
    '人隔離(含隔離中'||iCntNow||'人)，居隔率：'||iPercent||'%；'||
    iCntCovid||'人確診，確診率：'||iPercentC||'%。';*/
  
    IF (sMessage IS NOT NULL) THEN
      sMessage := sMessage3 || '<br><br>今日隔離人員：<br>' || sMessage ||
                  '</table>';
      IF (sMessage2 IS NOT NULL) THEN
        sMessage := sMessage || '<br><br>已解除隔離人員：<br>' || sMessage2 ||
                    '</table>';
      END IF;
      OPEN cursor2;
      LOOP
        FETCH cursor2
          INTO sEEMail;
        EXIT WHEN cursor2%NOTFOUND;
        POST_HTML_MAIL('system@edah.org.tw',
                       sEEMail,
                       '',
                       '1',
                       sTitle,
                       sMessage);
      
      END LOOP;
      CLOSE cursor2;
    ELSE
      sMessage := sMessage3 || '<br><br>截至上午07:00，今日(' ||
                  TO_CHAR(SYSDATE, 'yyyy-mm-dd') || ')';
      sMessage := sMessage || '資訊部無COVID-19居隔中人員通報。';
      IF (sMessage2 IS NOT NULL) THEN
        sMessage := sMessage || '<br><br>已解除隔離人員：<br>' || sMessage2 ||
                    '</table>';
      END IF;
      OPEN cursor2;
      LOOP
        FETCH cursor2
          INTO sEEMail;
        EXIT WHEN cursor2%NOTFOUND;
        POST_HTML_MAIL('system@edah.org.tw',
                       sEEMail,
                       '',
                       '1',
                       sTitle,
                       sMessage);
      
      END LOOP;
      CLOSE cursor2;
    END IF;
  
  END hrasend_mail_IT;

  PROCEDURE CheckMorning_mail AS
    iCnt NUMBER;
  
  BEGIN
    BEGIN
      SELECT COUNT(*)
        INTO iCnt
        FROM HRA_UNNORMAL_LOG
       WHERE TRUNC(SYS_DATE) = TRUNC(SYSDATE);
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        iCnt := 0;
    END;
    --20220715僅確認收件者有行政長的一級主管假卡、醫師假卡、出國假卡三項通知
    IF iCnt <> 0 THEN
      POST_HTML_MAIL('system@edah.org.tw', 'ed108482@edah.org.tw', '', '1',
                     '上午7點信件發送異常',
                     '請確認HRA_UNNORMAL_LOG記錄的異常訊息<br>' ||
                     'SELECT * FROM HRA_UNNORMAL_LOG WHERE TRUNC(SYS_DATE) = TRUNC(SYSDATE);');
      POST_HTML_MAIL('system@edah.org.tw', 'ed108154@edah.org.tw', '', '1',
                     '上午7點信件發送異常',
                     '請確認HRA_UNNORMAL_LOG記錄的異常訊息<br>' ||
                     'SELECT * FROM HRA_UNNORMAL_LOG WHERE TRUNC(SYS_DATE) = TRUNC(SYSDATE);');
      POST_HTML_MAIL('system@edah.org.tw', 'ed100037@edah.org.tw', '', '1',
                     '上午7點信件發送異常',
                     '請確認HRA_UNNORMAL_LOG記錄的異常訊息<br>' ||
                     'SELECT * FROM HRA_UNNORMAL_LOG WHERE TRUNC(SYS_DATE) = TRUNC(SYSDATE);');
    END IF;
  
    ehrphra7_pkg.hra9000;
  END CheckMorning_mail;

  --寄信
  --mailtype : 1 : 只寄給收件者
  --           2 : 寄給收件者與附件收件者,但不顯示附件收件者 DEBUG好用
  --           3 : 寄給收件者與附件收件者,且顯示附件收件者
  PROCEDURE POST_HTML_MAIL(sender       IN VARCHAR2,
                           recipient    IN VARCHAR2,
                           cc_recipient IN VARCHAR2,
                           mailtype     IN VARCHAR2,
                           subject      IN VARCHAR2,
                           message      IN VARCHAR2) IS
    --mailhost VARCHAR2(30) := '10.6.3.12';
    mailhost     VARCHAR2(30) := 'smtp.edah.org.tw';
    mail_conn    utl_smtp.connection;
    crlf         VARCHAR2(2) := CHR(13) || CHR(10);
    errnum       NUMBER;
    mesg         VARCHAR2(32767);
    ErrorMessage VARCHAR2(500); --20220715 108482 記錄異常訊息
  BEGIN
    mail_conn := utl_smtp.open_connection(mailhost, 25);
    utl_smtp.helo(mail_conn, mailhost);
    utl_smtp.mail(mail_conn, sender);
    utl_smtp.rcpt(mail_conn, recipient);
    IF (mailtype = 2 or mailtype = 3) THEN
      utl_smtp.rcpt(mail_conn, cc_recipient);
    END IF;
  
    mesg := message;
    UTL_SMTP.OPEN_DATA(mail_conn);
    --主旨
    UTL_smtp.write_raw_data(mail_conn,
                            utl_raw.cast_to_raw('Subject: ' || subject ||
                                                utl_tcp.crlf));
    --編碼
    UTL_SMTP.WRITE_DATA(mail_conn,
                        'Content-Type: text/html;charset=UTF-8' ||
                        UTL_TCP.CRLF);
    UTL_SMTP.WRITE_DATA(mail_conn,
                        'Content-Transfer-Encoding: base64' || UTL_TCP.CRLF);
  
    --寄件人
    UTL_SMTP.WRITE_DATA(mail_conn, 'From: ' || sender || UTL_TCP.CRLF);
    --收件人
    UTL_SMTP.WRITE_DATA(mail_conn, 'To: ' || recipient || UTL_TCP.CRLF);
    IF (mailtype = 3) THEN
      UTL_SMTP.WRITE_DATA(mail_conn,
                          'Cc: ' || cc_recipient || UTL_TCP.CRLF);
    END IF;
  
    UTL_SMTP.WRITE_DATA(mail_conn, UTL_TCP.CRLF);
    UTL_SMTP.WRITE_DATA(mail_conn,
                        UTL_RAW.CAST_TO_VARCHAR2(UTL_ENCODE.BASE64_ENCODE(UTL_RAW.CAST_TO_RAW(message))));
  
    UTL_SMTP.CLOSE_DATA(mail_conn);
    UTL_SMTP.quit(mail_conn);
  EXCEPTION
    WHEN OTHERS THEN
      NULL;
      errnum       := SQLCODE;
      ErrorMessage := SQLERRM;
      INSERT INTO HRA_UNNORMAL_LOG
        (LOG_SEQ,
         PROG_NAME,
         SYS_DATE,
         LOG_CODE,
         LOG_MSG,
         LOG_INFO,
         CREATED_BY,
         CREATION_DATE,
         LAST_UPDATED_BY,
         LAST_UPDATE_DATE)
      VALUES
        (TO_CHAR(SYSDATE, 'MMDDHH24MISS'),
         substr(subject, 1, 10),
         SYSDATE,
         errnum,
         'ehrphrafunc_pkg.POST_HTML_MAIL寄送異常',
         recipient||','||ErrorMessage,
         'MIS',
         SYSDATE,
         'MIS',
         SYSDATE);
      COMMIT;
    
  END POST_HTML_MAIL;

  PROCEDURE POST_HTML_MAIL2(sender       IN VARCHAR2,
                            recipient    IN VARCHAR2,
                            cc_recipient IN VARCHAR2,
                            mailtype     IN VARCHAR2,
                            subject      IN VARCHAR2,
                            message      IN VARCHAR2) IS
    --mailhost VARCHAR2(30) := '10.6.3.12';
    mailhost  VARCHAR2(30) := 'ntexcas01.edah.org.tw';
    mail_conn utl_smtp.connection;
    crlf      VARCHAR2(2) := CHR(13) || CHR(10);
    errnum    NUMBER;
    mesg      VARCHAR2(30000);
  BEGIN
    mail_conn := utl_smtp.open_connection(mailhost, 25);
    utl_smtp.helo(mail_conn, mailhost);
    utl_smtp.mail(mail_conn, sender);
    utl_smtp.rcpt(mail_conn, recipient);
    IF (mailtype = 2 or mailtype = 3) THEN
      utl_smtp.rcpt(mail_conn, cc_recipient);
    END IF;
  
    mesg := message;
    UTL_SMTP.OPEN_DATA(mail_conn);
    --主旨
    UTL_smtp.write_raw_data(mail_conn,
                            utl_raw.cast_to_raw('Subject: ' || subject ||
                                                utl_tcp.crlf));
    --編碼
    UTL_SMTP.WRITE_DATA(mail_conn,
                        'Content-Type: text/html;charset=UTF-8' ||
                        UTL_TCP.CRLF);
    UTL_SMTP.WRITE_DATA(mail_conn,
                        'Content-Transfer-Encoding: base64' || UTL_TCP.CRLF);
  
    --寄件人
    UTL_SMTP.WRITE_DATA(mail_conn, 'From: ' || sender || UTL_TCP.CRLF);
    --收件人
    UTL_SMTP.WRITE_DATA(mail_conn, 'To: ' || recipient || UTL_TCP.CRLF);
    IF (mailtype = 3) THEN
      UTL_SMTP.WRITE_DATA(mail_conn,
                          'Cc: ' || cc_recipient || UTL_TCP.CRLF);
    END IF;
  
    UTL_SMTP.WRITE_DATA(mail_conn, UTL_TCP.CRLF);
    UTL_SMTP.WRITE_DATA(mail_conn,
                        UTL_RAW.CAST_TO_VARCHAR2(UTL_ENCODE.BASE64_ENCODE(UTL_RAW.CAST_TO_RAW(mesg))));
  
    UTL_SMTP.CLOSE_DATA(mail_conn);
    UTL_SMTP.quit(mail_conn);
  EXCEPTION
    WHEN OTHERS THEN
      NULL;
      errnum := SQLCODE;
  END POST_HTML_MAIL2;

  --寄信:直接測試UTF8 -> ROW -> SEND ,沒試用過ipad,沒用BASE64,純粹試解長MAIL
  --mailtype : 1 : 只寄給收件者
  --           2 : 寄給收件者與附件收件者,但不顯示附件收件者 DEBUG好用
  --           3 : 寄給收件者與附件收件者,且顯示附件收件者
  PROCEDURE POST_ORIGIN_HTML_MAIL(sender       IN VARCHAR2,
                                  recipient    IN VARCHAR2,
                                  cc_recipient IN VARCHAR2,
                                  mailtype     IN VARCHAR2,
                                  subject      IN VARCHAR2,
                                  message      IN VARCHAR2) IS
    --mailhost VARCHAR2(30) := '10.6.3.12';
    mailhost  VARCHAR2(30) := 'smtp.edah.org.tw';
    mail_conn utl_smtp.connection;
    crlf      VARCHAR2(2) := CHR(13) || CHR(10);
    errnum    NUMBER;
    mesg      VARCHAR2(30000);
  BEGIN
    mail_conn := utl_smtp.open_connection(mailhost, 25);
    utl_smtp.helo(mail_conn, mailhost);
    utl_smtp.mail(mail_conn, sender);
    utl_smtp.rcpt(mail_conn, recipient);
    IF (mailtype = 2 or mailtype = 3) THEN
      utl_smtp.rcpt(mail_conn, cc_recipient);
    END IF;
    mesg := '';
  
    --mesg := message;
    UTL_SMTP.OPEN_DATA(mail_conn);
    --主旨
    UTL_smtp.write_raw_data(mail_conn,
                            utl_raw.cast_to_raw('Subject: ' || subject ||
                                                utl_tcp.crlf));
    --編碼
    UTL_SMTP.WRITE_DATA(mail_conn,
                        'Content-Type: text/html;charset=UTF-8' ||
                        UTL_TCP.CRLF);
  
    --寄件人
    UTL_SMTP.WRITE_DATA(mail_conn, 'From: ' || sender || UTL_TCP.CRLF);
    --收件人
    UTL_SMTP.WRITE_DATA(mail_conn, 'To: ' || recipient || UTL_TCP.CRLF);
    IF (mailtype = 3) THEN
      UTL_SMTP.WRITE_DATA(mail_conn,
                          'Cc: ' || cc_recipient || UTL_TCP.CRLF);
    END IF;
  
    UTL_SMTP.WRITE_DATA(mail_conn, UTL_TCP.CRLF);
    utl_smtp.write_raw_data(mail_conn,
                            UTL_RAW.CAST_TO_RAW(mesg || message || chr(13) ||
                                                chr(10)));
  
    UTL_SMTP.CLOSE_DATA(mail_conn);
    UTL_SMTP.quit(mail_conn);
  EXCEPTION
    WHEN OTHERS THEN
      NULL;
      errnum := SQLCODE;
  END POST_ORIGIN_HTML_MAIL;

  PROCEDURE DELETE_MIS_MSG(msgno IN VARCHAR2) IS
  BEGIN
    DELETE FROM PUS_MSGBAS WHERE MSG_NO = msgno;
    DELETE FROM PUS_MSGMST WHERE MSG_NO = msgno;
    commit;
  END DELETE_MIS_MSG;

  PROCEDURE POST_MIS_MSG(msgno     IN VARCHAR2,
                         sender    IN VARCHAR2,
                         recipient IN VARCHAR2,
                         subject   IN VARCHAR2,
                         message   IN VARCHAR2,
                         msgdate   IN VARCHAR2) IS
  organtype VARCHAR2(10);
  BEGIN
    BEGIN
    SELECT ORGAN_TYPE
      INTO organtype
      FROM HRE_EMPBAS
     WHERE EMP_NO = recipient;
    EXCEPTION WHEN OTHERS THEN
      organtype := 'ED';
    END;
    INSERT INTO PUS_MSGMST
      (MSG_NO, MSG_FROM, MSG_TO, SUBJECT, MSG_DESC, MSG_DATE, ORG_BY, ORGAN_TYPE)
    VALUES
      (msgno,
       sender,
       recipient,
       subject,
       message,
       to_date(msgdate, 'yyyy-mm-dd'),
       organtype, organtype);
    INSERT INTO PUS_MSGBAS (MSG_NO, EMP_NO, ORG_BY, ORGAN_TYPE) VALUES (msgno, recipient, organtype, organtype);
    COMMIT;
  END POST_MIS_MSG;
  
  PROCEDURE POST_MISMSG_MAIL(msgno IN VARCHAR2,
                             sender IN VARCHAR2,
                             recipient IN VARCHAR2,
                             subject IN VARCHAR2,
                             message IN VARCHAR2,
                             msgdate IN VARCHAR2) IS
  CURSOR cursor1 IS
    SELECT E.CH_NAME||P.CH_NAME AS EMPPOS, E.ORGAN_TYPE
      FROM HRE_EMPBAS E, HRE_POSMST P 
     WHERE E.POS_NO = P.POS_NO
       AND E.EMP_NO = recipient;
  rec_emp cursor1%ROWTYPE;
  Realmessage VARCHAR2(30000);
  Email VARCHAR2(120);
  BEGIN
    OPEN cursor1;
    LOOP
    FETCH cursor1
    INTO rec_emp;
    EXIT WHEN cursor1%NOTFOUND;
      Realmessage := rec_emp.emppos||' 您好：<br><br>'||message;
      INSERT INTO PUS_MSGMST
        (MSG_NO, MSG_FROM, MSG_TO, SUBJECT, MSG_DESC, MSG_DATE, ORG_BY, ORGAN_TYPE)
      VALUES
        (msgno,
         sender,
         recipient,
         subject,
         Realmessage,
         to_date(msgdate, 'yyyy-mm-dd'),
         rec_emp.organ_type, rec_emp.organ_type);
      INSERT INTO PUS_MSGBAS (MSG_NO, EMP_NO, ORG_BY, ORGAN_TYPE) VALUES (msgno, recipient, rec_emp.organ_type, rec_emp.organ_type);
    END LOOP;
    COMMIT;
    CLOSE cursor1;
    
    /*IF substr(recipient,1,1) <> '1' THEN
      Email := recipient || '@edah.org.tw';
    ELSE
      Email := 'ed' || recipient || '@edah.org.tw';
    END IF;*/
    Email := 'ed' || recipient || '@edah.org.tw';
    
    IF recipient LIKE 'IBM%' THEN
      Email := 'ed108482@edah.org.tw';
    END IF;
    
    hrpuser.MAILQUEUE.insertMailQueue('system@edah.org.tw',Email,'',subject,Realmessage,'','','1');
  END POST_MISMSG_MAIL;
  
  FUNCTION F_countfee(OTMHRS_33 NUMBER,
                      OTMHRS_43 NUMBER,
                      OTMHRS_53 NUMBER,
                      OTMHRS_83 NUMBER,
                      SUPHRS_33 NUMBER,
                      SUPHRS_43 NUMBER,
                      SUPHRS_53 NUMBER,
                      SUPHRS_83 NUMBER,
                      EMPNO_IN  VARCHAR2,
                      SCHYM_IN  VARCHAR2,
                      note_flag VARCHAR2) RETURN NUMBER IS
    nSalAmt   NUMBER; 
    nDayFee   NUMBER;
    nDayFee_G NUMBER;
    nNightAmt NUMBER := 0 ;
    nFee_amt  NUMBER := 0 ;
    nFee_otm  NUMBER := 0 ;
    nFee_sup  NUMBER := 0 ;
    nFee_amt_otm NUMBER := 0 ;
    nFee_amt_sup NUMBER := 0 ;
  
  BEGIN
    BEGIN
      SELECT nvl(a.sal_tot,0) ,nvl(b.night_amt,0)
        INTO nSalAmt , nNightAmt
        FROM HRS_ACNTTOT a, (select emp_no, night_amt from hra_classsch where sch_ym= SCHYM_IN ) b
       WHERE a.sal_ym = SCHYM_IN 
         AND a.emp_no = b.emp_no(+)
         AND a.emp_no = EMPNO_IN ;
    EXCEPTION WHEN NO_DATA_FOUND THEN
      nSalAmt := 0;
      nFee_amt := 0;
    END;
    nDayFee := (nSalAmt+nNightAmt) / 240;  
    nDayFee_G := nSalAmt / 240;
    
    -------------------計算加班費-------------------
    
          nFee_otm := (OTMHRS_33 * 1) + (OTMHRS_43 * 4/3) + 
                      (OTMHRS_53 * 5/3) + (OTMHRS_83 * 8/3) ;
          
          IF note_flag = 'G' THEN
            nFee_amt_otm := nFee_otm * nDayFee_G;
          ELSE  
            nFee_amt_otm := nFee_otm * nDayFee;
          END IF;
            
          -- 申請補休時數換算加班費
          
          nFee_sup := (SUPHRS_33 * 1) + (SUPHRS_43 * 4/3) + 
                      (SUPHRS_53 * 5/3) + (SUPHRS_83 * 8/3) ;
            
          IF note_flag = 'G' THEN
            nFee_amt_sup := nFee_sup * nDayFee_G;
          ELSE
            nFee_amt_sup := nFee_sup * nDayFee;
          END IF;
            
          nFee_amt := nFee_amt_otm - nFee_amt_sup ; -- 免稅加班費 = 申請加班倍數計算加班費 - 已補休時數倍數計算加班費
    RETURN nFee_amt;
  END F_countfee;
  
  FUNCTION f_Check_Cadsign(EmpNo_IN     VARCHAR2,
                           ShiftNo_IN   VARCHAR2,
                           ClassCode_IN VARCHAR2,
                           CheckIn_IN   VARCHAR2,
					                 CardTime_IN  VARCHAR2) RETURN NUMBER IS
    sCheckIn VARCHAR2(1) := CheckIn_IN;
    recheck_in  NUMBER;
    recheck_out NUMBER;
    recheck_tm  NUMBER;
    OutPut      NUMBER;
  BEGIN
    
    BEGIN
    SELECT substr(chkin_wktm,1,2)*60+substr(chkin_wktm,3,2),
           substr(chkout_wktm,1,2)*60+substr(chkout_wktm,3,2),
           substr(CardTime_IN,1,2)*60+substr(CardTime_IN,3,2)
      INTO recheck_in, recheck_out, recheck_tm
      FROM hra_classdtl
     WHERE CLASS_CODE = ClassCode_IN
       AND SHIFT_NO = ShiftNo_IN;
    EXCEPTION WHEN NO_DATA_FOUND THEN
      recheck_in := -1;
      recheck_out := -1;
      recheck_tm := -1;
    END;
    
    IF recheck_in >= 0 AND recheck_out >= 0 AND recheck_tm >= 0 THEN
      IF sCheckIn = 'Y' THEN --簽入
        IF recheck_in < 480 AND recheck_tm >= 960 THEN --上班時間0800前,且打卡大於1600(跨夜提早上班)
          IF (1440-recheck_tm) + recheck_in >= 1 THEN
            OutPut := 1;
            GOTO Continue_ForEach1;
          ELSIF (1440-recheck_tm) + recheck_in < 1 THEN
            OutPut := 0;
          END IF;
        ELSE 
          IF recheck_in - recheck_tm >= 1 THEN
            OutPut := 1;
            GOTO Continue_ForEach1;
          ELSIF recheck_in - recheck_tm < 1 THEN
            OutPut := 0;
          END IF;
        END IF;
      ELSE --簽出
        IF recheck_out > 960 AND recheck_tm <= 420 THEN --下班時間1600後,且打卡小於0700(跨夜延後下班)
          IF recheck_tm + (1440-recheck_out) >= 1 THEN
            OutPut := 1;
            GOTO Continue_ForEach1;
          ELSIF recheck_tm + (1440-recheck_out) < 1 THEN
            OutPut := 0;
          END IF;
        ELSIF recheck_out <= 480 AND recheck_tm >= 840 THEN --下班時間0800前,且打卡大於1400
          NULL; --是提早下班不是延後下班的狀況,非異常
        ELSE
          IF recheck_tm - recheck_out >= 1 THEN
            OutPut := 1;
            GOTO Continue_ForEach1;
          ELSIF recheck_tm - recheck_out < 1 THEN
            OutPut := 0;
          END IF;
        END IF;
      END IF;
    END IF;
    
    NULL;
    <<Continue_ForEach1>>
    NULL;
    
    RETURN OutPut;
  END f_Check_Cadsign;

end ehrphrafunc_pkg;
