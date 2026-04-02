
  CREATE OR REPLACE PACKAGE "HRP"."EHRPHRA12_PKG" is

   /*PROCEDURE hraC010(p_otm_no          VARCHAR2
                    , p_emp_no          VARCHAR2
                    , p_start_date      VARCHAR2
                    , p_start_time      VARCHAR2
                    , p_end_date        VARCHAR2
                    , p_end_time        VARCHAR2
                    , RtnCode       OUT NUMBER) ;*/
  --加班補休稽核                  
  PROCEDURE hraC010a(p_otm_no          VARCHAR2
                        , p_emp_no          VARCHAR2
                        , p_start_date      VARCHAR2
                        , p_start_time      VARCHAR2
                        , p_end_date        VARCHAR2
                        , p_end_time        VARCHAR2
                        , p_start_date_tmp   VARCHAR2
                        , p_on_call          VARCHAR2
                        , p_status          VARCHAR2
                        , OrganType_IN        VARCHAR2
                        , p_otm_hrs          VARCHAR2
                        , RtnCode       OUT NUMBER) ;
  --加班補休稽核(進階作業用,檢核加班總時數)
  PROCEDURE hraC010a_add(p_otm_no         VARCHAR2,
                         p_emp_no         VARCHAR2,
                         p_start_date     VARCHAR2,
                         p_start_date_tmp VARCHAR2,
                         p_otm_hrs        VARCHAR2,
                         OrganType_IN     VARCHAR2,
                         RtnCode          OUT NUMBER);
                                       
   -- 醫師加班稽核
   PROCEDURE hraD010( p_emp_no           VARCHAR2
                    , p_start_date       VARCHAR2
                    , p_start_time       VARCHAR2
                    , p_end_date         VARCHAR2
                    , p_end_time         VARCHAR2
                    , P_otm_hrs          VARCHAR2
                    , RtnCode       OUT NUMBER) ;

    -- 補休稽核
    PROCEDURE hraC020(p_sup_no          VARCHAR2
                    , p_otm_date        VARCHAR2
                    , p_sup_hrs         VARCHAR2
                    , RtnCode       OUT NUMBER) ;

    -- 補休稽核-申請稽核
   PROCEDURE hraC020a( p_otm_date        VARCHAR2,
                        p_sup_date        VARCHAR2,
                        RtnCode       OUT NUMBER) ;


  -- 加班換加班費稽核
  PROCEDURE hraC030(p_item_type       VARCHAR2
                    , p_emp_no          VARCHAR2
                    , p_start_date      VARCHAR2
                    , p_start_time      VARCHAR2
                    , p_end_date        VARCHAR2
                    , p_end_time        VARCHAR2
                    , p_on_call         VARCHAR2
                    , p_posted_startdate VARCHAR2
                    , p_posted_starttime VARCHAR2
                    , p_posted_status    VARCHAR2
                    , p_start_date_tmp   VARCHAR2
                    , p_otm_hrs          VARCHAR2
                    ,OrganType_IN      VARCHAR2
                    , RtnCode       OUT NUMBER) ;
  -- 加班換加班費稽核(進階作業用,檢核加班總時數)
  PROCEDURE hraC030_add(p_emp_no         VARCHAR2,
                        p_start_date     VARCHAR2,
                        p_start_date_tmp VARCHAR2,
                        p_otm_hrs        VARCHAR2,
                        OrganType_IN     VARCHAR2,
                        RtnCode          OUT NUMBER);

  PROCEDURE hraC040_old(p_emp_no      VARCHAR2,
                    p_uncard_date VARCHAR2,
                    p_uncard_time VARCHAR2,
                    OrganType_IN  VARCHAR2,
                    RtnCode       OUT NUMBER) ;
  
  PROCEDURE hraC040(p_emp_no      VARCHAR2,
                    p_uncard_date VARCHAR2,
                    p_uncard_time VARCHAR2,
                    p_uncard_poin VARCHAR2,
                    p_uncard_rea  VARCHAR2,
                    OrganType_IN  VARCHAR2,
                    RtnCode       OUT NUMBER);
  
  PROCEDURE hraC041(p_emp_no      VARCHAR2,
                    p_uncard_date VARCHAR2,
                    p_uncard_time VARCHAR2,
                    p_check_poin  VARCHAR2,
                    p_night_flag  VARCHAR2,
                    OrganType_IN  VARCHAR2,
                    RtnCode       OUT NUMBER);
                
  PROCEDURE hraC050(EmpNo_In     VARCHAR2,
                    StartDate_In VARCHAR2,
                    Merge_In     VARCHAR2,
                    User_In      VARCHAR2,
                    RtnCode      OUT NUMBER);
  
  PROCEDURE hraC060(EmpNo_In     VARCHAR2,
                    StartDate_In VARCHAR2,
                    Merge_In     VARCHAR2,
                    User_In      VARCHAR2,
                    RtnCode      OUT NUMBER);
                    
  PROCEDURE hraC061(EmpNo_In     VARCHAR2,
                    StartDate_In VARCHAR2,
                    User_In      VARCHAR2,
                    RtnCode      OUT NUMBER);

   PROCEDURE hraD030( p_item_type       VARCHAR2
                    , p_emp_no          VARCHAR2
                    , p_start_date      VARCHAR2
                    , p_start_time      VARCHAR2
                    , p_end_date        VARCHAR2
                    , p_end_time        VARCHAR2
                    , P_otm_hrs         VARCHAR2
                    , OrganType_IN      VARCHAR2
                    , RtnCode       OUT NUMBER) ;

-- 判別 Oncall
    FUNCTION checkOncall( p_emp_no           VARCHAR2
                        , p_start_date       VARCHAR2
                        , p_start_time       VARCHAR2
                        , p_end_date         VARCHAR2
                        , p_start_date_tmp   VARCHAR2
                        ,OrganType_IN VARCHAR2 ) RETURN NUMBER;
-- 判別 Class
    FUNCTION checkClass(  p_emp_no           VARCHAR2
                        , p_start_date       VARCHAR2
                        , p_start_time       VARCHAR2
                        , p_end_date         VARCHAR2
                        , p_end_time         VARCHAR2
                         ,OrganType_IN VARCHAR2 ) RETURN NUMBER;
-- 取得加班時數
 FUNCTION getOtmhrs(  p_start_date       VARCHAR2
                    , p_start_time       VARCHAR2
                    , p_end_date         VARCHAR2
                    , p_end_time         VARCHAR2
                    , p_emp_no            VARCHAR2
                    , OrganType_IN VARCHAR2) RETURN NUMBER;

 FUNCTION getOtmhrs_T(  p_start_date       VARCHAR2
                    , p_start_date_tmp     VARCHAR2
                    , p_start_time       VARCHAR2
                    , p_end_date         VARCHAR2
                    , p_end_time         VARCHAR2
                    , p_emp_no            VARCHAR2
                    , OrganType_IN VARCHAR2) RETURN NUMBER;

-- 取得借休時數
 FUNCTION getOffhrs(  p_start_date       VARCHAR2
                    , p_start_time       VARCHAR2
                    , p_end_date         VARCHAR2
                    , p_end_time         VARCHAR2
                    , p_emp_no           VARCHAR2
                    , OrganType_IN VARCHAR2) RETURN NUMBER;
                    
 FUNCTION getOffhrs_T(  p_start_date       VARCHAR2
                      , p_start_date_tmp     VARCHAR2
                      , p_start_time       VARCHAR2
                      , p_end_date         VARCHAR2
                      , p_end_time         VARCHAR2
                      , p_emp_no           VARCHAR2
                      , OrganType_IN VARCHAR2) RETURN NUMBER;
                    
 --假卡時數計算用(休息時間不計算時數)
 FUNCTION getOffhrs_Evc(  p_start_date       VARCHAR2
                        , p_start_time       VARCHAR2
                        , p_end_date         VARCHAR2
                        , p_end_time         VARCHAR2
                        , p_emp_no           VARCHAR2
                        , OrganType_IN VARCHAR2) RETURN NUMBER;

    -- 調班(失敗)-批次處理 fneg add 2005-10-17
  --  PROCEDURE hraChgClass ;
  /*
PROCEDURE mail_deputy2( p_emp_no       VARCHAR2,
                       p_start_date   VARCHAR2,
                       p_deputy       VARCHAR2);
  */
--不能即時修改擬複製後作廢
PROCEDURE mail_deputy(    p_D_emp_no     VARCHAR2,
                          p_start_date   VARCHAR2,
                          p_end_date     VARCHAR2,
                          p_P_emp_no     VARCHAR2,
                          p_emp_no       VARCHAR2,
                          p_OrganType_IN VARCHAR2
                        );
--假卡代理人通知 2010-05-04 weichun

/* 擬作廢刪除
PROCEDURE mail_deputy2( p_D_emp_no     VARCHAR2,
                        p_start_date   VARCHAR2,
                        p_End_date     VARCHAR2,
                        p_P_emp_no     VARCHAR2,
                        p_emp_no       VARCHAR2,
                        p_OrganType_IN VARCHAR2
                        );
  */
FUNCTION  check_deputy(   p_emp_no           VARCHAR2
                        , p_start_date       VARCHAR2
                        , p_start_time       VARCHAR2
                        , p_end_date         VARCHAR2
                        , p_end_time         VARCHAR2) RETURN NUMBER;
-- 取得醫師補休時數
 FUNCTION getCountDocSUPhrs(  p_start_date       VARCHAR2
                            , p_start_time       VARCHAR2
                            , p_end_date         VARCHAR2
                            , p_end_time         VARCHAR2) RETURN NUMBER;
FUNCTION getCountDocSUPhrs_fun(  p_start_date       VARCHAR2
                            , p_start_time       VARCHAR2
                            , p_end_date         VARCHAR2
                            , p_end_time         VARCHAR2) RETURN NUMBER;
--積借休uni key重複備份
PROCEDURE offrec_uni_backup(p_emp_no           VARCHAR2
                              , p_start_date       VARCHAR2
                              , p_start_time       VARCHAR2
                              , p_status           VARCHAR2
                              , p_item_type        VARCHAR2
                              , RtnCode            OUT NUMBER);
--積借休異常通報與建立
PROCEDURE offrec_ovrtrans(UpdateBy_IN      VARCHAR2
                          , organtype_IN   VARCHAR2
                          , RtnCode        OUT NUMBER);
/*
--取得積借休時數
FUNCTION getOffData(EmpNo_IN VARCHAR2
                  , CloseDate_IN VARCHAR2) RETURN VARCHAR2;

--積借休時數年度結算:移動至EHRPHRA2_PKG
PROCEDURE makeOffYsmData(LastUpdateBy_IN VARCHAR2
                         , RtnCode       OUT NUMBER);
*/

-- 取得3個月加班和積休時數
 FUNCTION Check3MonthOtmhrs(  p_emp_no     VARCHAR2
                             ,p_start_date VARCHAR2
                             ,p_otm_hrs    VARCHAR2
                             ,OrganType_IN VARCHAR2) RETURN NUMBER;

--用補休退回同步更新明細狀態
PROCEDURE UpdateSupdtl(SUPNO_IN VARCHAR2,
                       EMPNO_IN VARCHAR2);

--用補休刪除同步刪除代理設定
PROCEDURE Delete_DeputySup(EmpNo_IN     VARCHAR2,
                           StartDate_IN VARCHAR2,
                           EndDate_IN   VARCHAR2);

--用補休退回或准同步更新代理設定是否失效
PROCEDURE Update_DeputySup(EmpNo_IN     VARCHAR2,
                           StartDate_IN VARCHAR2,
                           EndDate_IN   VARCHAR2,
                           Status_IN    VARCHAR2,
                           Update_IN    VARCHAR2);
END EHRPHRA12_PKG;

CREATE OR REPLACE PACKAGE BODY "HRP"."EHRPHRA12_PKG" is

/*------------------------------------------
-- SQL_NAME : hraC010.sql
-- 加班稽核
------------------------------------------*/

/*PROCEDURE hraC010(p_otm_no          VARCHAR2
                , p_emp_no          VARCHAR2
                , p_start_date      VARCHAR2
                , p_start_time      VARCHAR2
                , p_end_date        VARCHAR2
                , p_end_time        VARCHAR2
                , RtnCode       OUT NUMBER) IS

    nCnt NUMBER ;
    sStart   VARCHAR2(14)   := replace(p_start_date, '/', '-') || p_start_time;
    sEnd     VARCHAR2(14)   := replace(p_end_date, '/', '-') || p_end_time ;

    BEGIN
       RtnCode := 0 ;

       ---------------------------------一般簽到---------------------------------
       BEGIN
      --   SELECT count(*)
      --      INTO nCnt
      --      FROM hra_cadsign_view
       --    WHERE emp_no = p_emp_no
        --     and (
        --          (sEnd BETWEEN to_char(att_date, 'yyyy-mm-dd') || nvl(chkin1_card, '')
        --                    AND to_char(att_date, 'yyyy-mm-dd') || nvl(chkout1_card, '')
        --     and sEnd > to_char(att_date, 'yyyy-mm-dd') || nvl(chkin1_wktm, ''))

      --       or (sEnd BETWEEN to_char(att_date, 'yyyy-mm-dd') || nvl(chkin2_card, '')
        --                  AND to_char(att_date, 'yyyy-mm-dd') || nvl(chkout2_card, '')
       --     and sEnd > to_char(att_date, 'yyyy-mm-dd') || nvl(chkin2_wktm, ''))

        --     or (sEnd BETWEEN to_char(att_date, 'yyyy-mm-dd') || nvl(chkin3_card, '')
        --                  AND to_char(att_date, 'yyyy-mm-dd') || nvl(chkout3_card, '')
         --    and sEnd > to_char(att_date, 'yyyy-mm-dd') || nvl(chkin3_wktm, ''))
         --        );

      SELECT count(*)
            INTO nCnt
            FROM hra_cadsign
           WHERE emp_no = p_emp_no
                and(sEnd BETWEEN to_char(att_date, 'yyyy-mm-dd') || case when nvl(chkin_card, '') = '0000' then '2400' else nvl(chkin_card, '')end
                                         AND CASE WHEN night_flag = 'Y'
                                            then (to_char(att_date+1, 'yyyy-mm-dd') || nvl(chkout_card, ''))
                                            else to_char(att_date, 'yyyy-mm-dd') || nvl(chkout_card, '')
                                            end)
             and sStart >= to_char(att_date, 'yyyy-mm-dd') || case when nvl(chkin_card, '') = '0000' then '2400' else nvl(chkin_card, '')end;

       EXCEPTION
       WHEN no_data_found THEN
            nCnt := 0 ;
       END ;

       IF nCnt > 0 THEN
          GOTO Continue_ForEach2 ;
       END IF;
       ---------------------------------一般簽到---------------------------------

       ---------------------------------加班簽到---------------------------------
       BEGIN
          SELECT count(*)
            INTO nCnt
            FROM hra_otmsign
           WHERE emp_no = p_emp_no
             AND substr(otm_no, 1, 3) = 'OTS'
                AND ((sStart between to_char(start_date, 'YYYY-MM-DD') || start_time
                                 and to_char(end_date, 'YYYY-MM-DD') || end_time)
                AND  (sEnd   between to_char(start_date, 'YYYY-MM-DD') || start_time
                --  By szuhao 2005-11-29  OR  (sEnd   between to_char(start_date, 'YYYY-MM-DD') || start_time
                                 and to_char(end_date, 'YYYY-MM-DD') || end_time))  ;

       EXCEPTION
       WHEN no_data_found THEN
            nCnt := 0 ;
       END ;

       IF nCnt = 0 THEN
          RtnCode := 5 ;     -- 無簽到時間
          GOTO Continue_ForEach1 ;
       END IF;
       ---------------------------------加班簽到---------------------------------

       NULL ;
       <<Continue_ForEach2>>
       NULL ;


       -----------------------------加班期間重覆-----------------------------
       sStart := p_start_date || p_start_time ;
       sEnd   := p_end_date || p_end_time ;

       -- 已有加班 2005-03-01 2000 ~ 2005-03-01 2200
       -- new      2005-03-01 2100 ~ 2005-03-01 2130
       BEGIN
          SELECT count(*)
            INTO nCnt
            FROM hra_otmsign
           WHERE status = 'Y'
             AND emp_no = p_emp_no
             AND to_char(start_date, 'yyyy-mm-dd') || start_time <= sStart
             AND to_char(end_date, 'yyyy-mm-dd') || end_time >= sEnd
             AND otm_no <> p_otm_no;
       EXCEPTION
       WHEN OTHERS THEN
            nCnt := 0;
       END ;

       IF nCnt > 0 THEN
          RtnCode := 1 ;  -- 加班期間重覆
       ELSE

          -- 已有加班 2005-03-01 2000 ~ 2005-03-01 2200
          -- new      2005-03-01 1900 ~ 2005-03-01 2230
          BEGIN
             SELECT count(*)
               INTO nCnt
               FROM hra_otmsign
              WHERE status = 'Y'
                AND emp_no = p_emp_no
                AND to_char(start_date, 'yyyy-mm-dd') || start_time >= sStart
                AND to_char(end_date, 'yyyy-mm-dd') || end_time <= sEnd
                AND otm_no <> p_otm_no;
          EXCEPTION
          WHEN OTHERS THEN
               nCnt := 0 ;
          END;

          IF nCnt > 0 THEN
             RtnCode := 2 ;  -- 加班期間含已申請加班期間
          ELSE
             -- 已有加班 2005-03-01 2000 ~ 2005-03-01 2200
             -- new      2005-03-01 1900 ~ 2005-03-01 2130
             BEGIN
                SELECT count(*)
                  INTO nCnt
                  FROM hra_otmsign
                 WHERE status = 'Y'
                   AND emp_no = p_emp_no
                   AND to_char(start_date, 'yyyy-mm-dd') || start_time > sStart
                   AND (to_char(end_date, 'yyyy-mm-dd') || end_time > sEnd
                   AND  to_char(start_date, 'yyyy-mm-dd') || start_time < sEnd)
                   AND otm_no <> p_otm_no;
             EXCEPTION
             WHEN OTHERS THEN
                  nCnt := 0 ;
             END;

             IF nCnt > 0 THEN
                RtnCode := 3 ;  -- 加班期間_訖 重覆
             ELSE
                -- 已有加班 2005-03-01 2000 ~ 2005-03-01 2200
                -- new      2005-03-01 2100 ~ 2005-03-01 2330
                BEGIN
                   SELECT count(*)
                     INTO nCnt
                     FROM hra_otmsign
                    WHERE status = 'Y'
                      AND emp_no = p_emp_no
                      AND (to_char(start_date, 'yyyy-mm-dd') || start_time < sStart
                      AND  to_char(end_date, 'yyyy-mm-dd') || end_time > sStart )
                      AND to_char(end_date, 'yyyy-mm-dd') || end_time < sEnd
                      AND otm_no <> p_otm_no;
                EXCEPTION
                WHEN OTHERS THEN
                     nCnt := 0 ;
                END;

                IF nCnt > 0 THEN
                   RtnCode := 4 ;  -- 加班期間_起 重覆
                END IF;

             END IF;
          END IF;
       END IF;
      -----------------------------加班期間重覆-----------------------------
       NULL ;
       <<Continue_ForEach1>>
       NULL ;

   END hraC010;*/

   
/*------------------------------------------
-- SQL_NAME : hraC010.sql
-- 加班換補休稽核
------------------------------------------*/
  PROCEDURE hraC010a(p_otm_no         VARCHAR2
                     , p_emp_no         VARCHAR2
                     , p_start_date     VARCHAR2
                     , p_start_time     VARCHAR2
                     , p_end_date       VARCHAR2
                     , p_end_time       VARCHAR2
                     , p_start_date_tmp VARCHAR2
                     , p_on_call        VARCHAR2
                     , p_status         VARCHAR2
                     , OrganType_IN     VARCHAR2
                     , p_otm_hrs        VARCHAR2
                     , RtnCode          OUT NUMBER) IS

   nCnt NUMBER ;
   SOrganType VARCHAR2(10) := OrganType_IN;
   sStart      VARCHAR2(20) := p_start_date || p_start_time;
   sEnd        VARCHAR2(20) := p_end_date || p_end_time ;
   sOtmhrs     NUMBER  := TO_NUMBER(p_otm_hrs);
   sCLASS_CODE VARCHAR2(3);
   i_end_date  VARCHAR2(10);
   iCnt        NUMBER;
   iCnt2       INTEGER ;
   sClassKind  VARCHAR2(3);
   sLastClassKind VARCHAR2(3);
   sWorkHrs    NUMBER;  -- 當日班表時數
   sTotAddHrs  NUMBER; --當日在途積休單申請時數
   iCheckCard  VARCHAR2(1); --註記是否為加班打卡,預設N(非加班打卡) 20181219 by108482
   iposlevel   VARCHAR2(1); --確認職等，7職等(含)以上人員不能自行申請加班 20190306 by108482
   LimitDay    VARCHAR2(2);
   

	sTotMonAdd  NUMBER; --當月積休單總時數(含在途)
	sOtmsignHrs  NUMBER;  --當日加班單時數
	sMonClassAdd  NUMBER; -- 當月班表超時  


   --因 BETWEEN 會比較前後值,故 START + 1 分鐘 , END -1 分鐘 來跳過
   sStart1     VARCHAR2(20) := TO_CHAR(TO_DATE(sStart,'YYYY-MM-DDHH24MI')+0.000695,'YYYY-MM-DDHH24MI');
   sEnd1       VARCHAR2(20) := TO_CHAR(TO_DATE(sEnd,'YYYY-MM-DDHH24MI')-0.000694,'YYYY-MM-DDHH24MI');

   iRestStart      VARCHAR2(4);
   iRestEnd        VARCHAR2(4);
   iChkinWktm     VARCHAR2(4);
   iChkoutWktm    VARCHAR2(4);
   sNextCLASS_CODE VARCHAR2(3);
    pchkinrea  VARCHAR2(2);
    pchkoutrea VARCHAR2(2);
    pwkintm    VARCHAR2(20);
    pwkouttm   VARCHAR2(20);

    BEGIN
       RtnCode := 0 ;
       sWorkHrs:=0;
       sTotAddHrs:=0;
   	   sTotMonAdd:=0;
       sOtmsignHrs:=0;
	     sMonClassAdd:=0;
       iCheckCard := 'N';
       
 
       --現有的加班單時間介於新加班單
       BEGIN
          SELECT COUNT(*)
            INTO nCnt
            FROM hra_otmsign
           WHERE emp_no = p_emp_no
             AND ORG_BY = SOrganType
             AND otm_no LIKE 'OTM%'
             AND ((sStart1  BETWEEN to_char(start_date, 'YYYY-MM-DD') || start_time AND to_char(end_date, 'YYYY-MM-DD') || end_time)
              OR  (sEnd1    BETWEEN to_char(start_date, 'YYYY-MM-DD') || start_time AND to_char(end_date, 'YYYY-MM-DD') || end_time ))
             AND status <> 'N'
             AND OTM_NO <> p_otm_no;

       EXCEPTION WHEN no_data_found THEN
            nCnt := 0 ;
       END;

       IF nCnt = 0 THEN

       --新加班單介於現有的加班單時間
       BEGIN
          SELECT COUNT(*)
            INTO nCnt
            FROM hra_otmsign
           WHERE emp_no = p_emp_no
             AND ORG_BY = SOrganType
             AND otm_no like 'OTM%'
             AND ((to_char(start_date, 'YYYY-MM-DD') || start_time BETWEEN sStart1 AND sEnd1)
              OR  (to_char(end_date, 'YYYY-MM-DD')   || end_time   BETWEEN sStart1 AND sEnd1))
             AND status <> 'N'
             AND OTM_NO <> p_otm_no;

       EXCEPTION WHEN no_data_found THEN
            nCnt := 0 ;
       END;
       END IF;


       IF nCnt > 0 THEN
         IF p_start_date_tmp <> 'N/A' THEN
           sCLASS_CODE := ehrphrafunc_pkg.f_getClassKind(p_emp_no,to_date(p_start_date_tmp,'yyyy-mm-dd'),SOrganType);
         ELSE
           sCLASS_CODE := ehrphrafunc_pkg.f_getClassKind(p_emp_no,to_date(p_start_date,'yyyy-mm-dd'),SOrganType);
         END IF;

       BEGIN
         SELECT START_REST, END_REST
           INTO iRestStart, iRestEnd
           FROM HRP.HRA_CLASSDTL
          WHERE CLASS_CODE = sCLASS_CODE
            AND SHIFT_NO = '1';
       EXCEPTION
         WHEN no_data_found THEN
       iRestStart := '0';
       iRestEnd :='0';
       END;

       IF p_start_time BETWEEN  iRestStart AND  iRestEnd
       AND p_end_time BETWEEN iRestStart AND  iRestEnd THEN

       --20180801 108978 這段有問題,要嚴格一點不能申請！
       --nCnt := nCnt -1;
       nCnt := nCnt;
       ELSIF iRestStart ='0' 
             AND iRestEnd ='0' 
            -- AND sCLASS_CODE='ZZ' 20161219 新增班別 ZX,ZY
            --20180725 108978 增加ZQ
             AND sCLASS_CODE IN ('ZZ','ZX','ZY','ZQ') 
             THEN
       --20180516 108978 這段有問題，同時段不能申請才對！
       nCnt := nCnt;

       END IF;


       IF nCnt > 0 THEN
       RtnCode := 1 ;
       GOTO Continue_ForEach1 ;
       END IF;

       END IF;
       
       BEGIN
       SELECT pos_level
         INTO iposlevel
         FROM HRE_POSMST
        WHERE pos_no = (SELECT pos_no FROM hre_empbas WHERE emp_no = p_emp_no);
       EXCEPTION WHEN no_data_found THEN
            iposlevel := NULL;
       END;
       --108482 20190306 7職等(含)以上人員不能自行申請加班
       
       IF iposlevel IS NULL THEN
         RtnCode := 99 ;
         GOTO Continue_ForEach1 ;
       ELSIF iposlevel >= 7 THEN
         RtnCode := 17 ;
         GOTO Continue_ForEach1 ;
       END IF;

        ------------------------- 加班簽到 -------------------------
       BEGIN

          SELECT count(*)
            INTO nCnt
            FROM hra_otmsign
           WHERE emp_no = p_emp_no
             AND ORG_BY = SOrganType
             AND ((sStart between to_char(start_date, 'YYYY-MM-DD') || start_time
                              and to_char(end_date, 'YYYY-MM-DD') || end_time)
             AND  (sEnd   between to_char(start_date, 'YYYY-MM-DD') || start_time
                              and to_char(end_date, 'YYYY-MM-DD') || end_time))
             AND substr(otm_no, 1, 3) = 'OTS';

       EXCEPTION
       WHEN no_data_found THEN
            nCnt := 0 ;
       END ;

       IF nCnt = 0 THEN
         RtnCode := 2 ;     -- 無簽到時間
       ELSE 
         iCheckCard := 'Y'; --nCnt<>0,有加班簽到 20181219 by108482
       END IF;

       ------------------------- 加班簽到 -------------------------


       ------------------------- 一般簽到 -------------------------
       IF RtnCode = 2 THEN
       -------------Check OnCall-----------
       RtnCode := 0;
       
       IF p_start_date_tmp <> 'N/A' THEN
         sCLASS_CODE := ehrphrafunc_pkg.f_getClassKind(p_emp_no,to_date(p_start_date_tmp,'yyyy-mm-dd'),SOrganType);
         BEGIN
           SELECT CHKIN_WKTM, CHKOUT_WKTM
             INTO iChkinWktm, iChkoutWktm
             FROM HRA_CLASSDTL
            WHERE CLASS_CODE = sCLASS_CODE
              AND SHIFT_NO = '1';
         EXCEPTION WHEN no_data_found THEN
           iChkinWktm := 0;
           iChkoutWktm := 0;
         END ;
         BEGIN
           SELECT COUNT(*)
             INTO nCnt
             FROM HRA_CADSIGN
            WHERE EMP_NO = P_EMP_NO
              AND TO_CHAR(ATT_DATE, 'yyyy-mm-dd') = P_START_DATE_TMP
              AND SSTART >=
                  (CASE WHEN ICHKINWKTM < ICHKOUTWKTM AND CHKIN_CARD > CHKOUT_CARD THEN
                   TO_CHAR(ATT_DATE - 1, 'yyyy-mm-dd') || CHKIN_CARD ELSE
                   TO_CHAR(ATT_DATE, 'yyyy-mm-dd') || CHKIN_CARD END)
              AND (SEND BETWEEN
                  (CASE WHEN ICHKINWKTM < ICHKOUTWKTM AND CHKIN_CARD > CHKOUT_CARD THEN
                   TO_CHAR(ATT_DATE - 1, 'yyyy-mm-dd') || CHKIN_CARD ELSE
                   TO_CHAR(ATT_DATE, 'yyyy-mm-dd') || CHKIN_CARD END) AND
                  (CASE WHEN ICHKINWKTM > ICHKOUTWKTM AND CHKIN_CARD > CHKOUT_CARD THEN
                   --20201202增CHKIN_CARD > CHKOUT_CARD條件 by108482 嚴謹檢核
                   TO_CHAR(ATT_DATE + 1, 'yyyy-mm-dd') || CHKOUT_CARD ELSE
                   TO_CHAR(ATT_DATE, 'yyyy-mm-dd') || CHKOUT_CARD END));
         EXCEPTION WHEN no_data_found THEN
           nCnt := 0 ;
         END ;
         --若查無記錄且申請起始時間>結束時間再次檢核
         --IF nCnt = 0 AND p_start_time > p_end_time THEN
         --20250718 by108482區分RN班和其他跨夜班打卡檢核
         IF nCnt = 0 THEN --by108482 20211215 不卡時間條件
           SELECT COUNT(*)
             INTO nCnt
             FROM hra_cadsign
            WHERE emp_no = p_emp_no
              AND to_char(att_date, 'yyyy-mm-dd') = p_start_date_tmp
              AND CHKIN_CARD > CHKOUT_CARD --20221123增 by108482 嚴謹檢核
              AND sStart >= (CASE CLASS_CODE WHEN 'RN' THEN TO_CHAR(ATT_DATE - 1, 'yyyy-mm-dd') || CHKIN_CARD
                             ELSE TO_CHAR(ATT_DATE, 'yyyy-mm-dd') || CHKIN_CARD END)
              AND sEnd <= (CASE CLASS_CODE WHEN 'RN' THEN TO_CHAR(ATT_DATE, 'yyyy-mm-dd') || CHKIN_CARD
                           ELSE TO_CHAR(ATT_DATE + 1, 'yyyy-mm-dd') || CHKOUT_CARD END);
         END IF;
       ELSE
       --108978 20180913 RN班申請加班，和ZZ/ZX/ZY+RN申請加班
       sCLASS_CODE := ehrphrafunc_pkg.f_getClassKind(p_emp_no,to_date(p_start_date,'yyyy-mm-dd'),SOrganType);
       sNextCLASS_CODE := ehrphrafunc_pkg.f_getClassKind(p_emp_no,to_date(p_start_date,'yyyy-mm-dd')+1,SOrganType);
       --108482 20190125 RN班提前或延後加班，start_time都不會是0000，若start_time為0000則需跑else的SQL
       IF ((sCLASS_CODE ='RN' OR sNextCLASS_CODE='RN') AND p_start_time<>'0000') THEN
        BEGIN
        SELECT count(*)
                INTO nCnt
                FROM hra_cadsign
               WHERE emp_no = p_emp_no
                 AND (sEnd BETWEEN to_char(att_date-1, 'yyyy-mm-dd') || chkin_card  AND  (to_char(att_date, 'yyyy-mm-dd') || chkout_card))                                           
                 AND (sStart >= to_char(att_date-1, 'yyyy-mm-dd') || chkin_card );
        EXCEPTION
           WHEN no_data_found THEN
                nCnt := 0 ;
        END ;
        
       ELSE
       
        BEGIN
        SELECT count(*)
                INTO nCnt
                FROM hra_cadsign
               WHERE emp_no = p_emp_no
                 AND ORG_BY = SOrganType
                 AND (sEnd BETWEEN to_char(att_date, 'yyyy-mm-dd') || chkin_card  AND  case when Night_Flag='Y' then (to_char(att_date+1, 'yyyy-mm-dd') || chkout_card)
                                                else to_char(att_date, 'yyyy-mm-dd') || chkout_card
                                                end)
                 AND (sStart >= to_char(att_date, 'yyyy-mm-dd') || chkin_card );


        EXCEPTION
        WHEN no_data_found THEN
            nCnt := 0 ;
        END ;
       END IF;
       END IF;
       IF nCnt = 0 THEN
          RtnCode := 2 ;     -- 無簽到時間
          GOTO Continue_ForEach1 ;
       END IF;
       END IF;
       
       --檢核是否有因公才能申請 20181116 108978
       --非加班打卡才檢核一般打卡因公因私 20181219 by108482
         IF (sStart > '2011-09-010000') AND iCheckCard = 'N' THEN
         IF p_start_date_tmp <> 'N/A' THEN
           BEGIN
             SELECT NVL(CHKIN_REA, 10),
                    NVL(CHKOUT_REA, 20),
                    TO_CHAR(ATT_DATE, 'yyyy-mm-dd') ||
                    (SELECT CHKIN_WKTM
                       FROM HRA_CLASSDTL
                      WHERE CLASS_CODE = HRA_CADSIGN.CLASS_CODE
                        AND SHIFT_NO = HRA_CADSIGN.SHIFT_NO),
                    (CASE
                      WHEN (SELECT CHKOUT_WKTM
                              FROM HRA_CLASSDTL
                             WHERE CLASS_CODE = HRA_CADSIGN.CLASS_CODE
                               AND SHIFT_NO = HRA_CADSIGN.SHIFT_NO) <
                           (SELECT CHKIN_WKTM
                              FROM HRA_CLASSDTL
                             WHERE CLASS_CODE = HRA_CADSIGN.CLASS_CODE
                               AND SHIFT_NO = HRA_CADSIGN.SHIFT_NO) THEN
                       TO_CHAR(ATT_DATE + 1, 'yyyy-mm-dd') ||
                       (SELECT CHKOUT_WKTM
                          FROM HRA_CLASSDTL
                         WHERE CLASS_CODE = HRA_CADSIGN.CLASS_CODE
                           AND SHIFT_NO = HRA_CADSIGN.SHIFT_NO)
                      ELSE
                       TO_CHAR(ATT_DATE, 'yyyy-mm-dd') ||
                       (SELECT CHKOUT_WKTM
                          FROM HRA_CLASSDTL
                         WHERE CLASS_CODE = HRA_CADSIGN.CLASS_CODE
                           AND SHIFT_NO = HRA_CADSIGN.SHIFT_NO)
                    END)
               INTO pchkinrea, pchkoutrea, pwkintm, pwkouttm
               FROM HRA_CADSIGN
              WHERE EMP_NO = P_EMP_NO
                AND TO_CHAR(ATT_DATE, 'yyyy-mm-dd') = p_start_date_tmp
                AND SSTART >=
                  (CASE WHEN ICHKINWKTM < ICHKOUTWKTM AND CHKIN_CARD > CHKOUT_CARD THEN
                   TO_CHAR(ATT_DATE - 1, 'yyyy-mm-dd') || CHKIN_CARD ELSE
                   TO_CHAR(ATT_DATE, 'yyyy-mm-dd') || CHKIN_CARD END)
                AND (SEND BETWEEN
                  (CASE WHEN ICHKINWKTM < ICHKOUTWKTM AND CHKIN_CARD > CHKOUT_CARD THEN
                   TO_CHAR(ATT_DATE - 1, 'yyyy-mm-dd') || CHKIN_CARD ELSE
                   TO_CHAR(ATT_DATE, 'yyyy-mm-dd') || CHKIN_CARD END) AND
                  (CASE WHEN ICHKINWKTM > ICHKOUTWKTM THEN
                   TO_CHAR(ATT_DATE + 1, 'yyyy-mm-dd') || CHKOUT_CARD ELSE
                   TO_CHAR(ATT_DATE, 'yyyy-mm-dd') || CHKOUT_CARD END));
           EXCEPTION WHEN no_data_found THEN
             pchkinrea := '15';
             pchkoutrea := '25';
             pwkouttm := sStart;
             pwkintm := sEnd;
           END ;
         ELSE
           BEGIN
           --108482 20190125 RN班提前或延後加班，start_time都不會是0000，若start_time為0000則需跑else的SQL
             IF ((sCLASS_CODE ='RN' OR sNextCLASS_CODE='RN') AND p_start_time<>'0000') THEN
               SELECT NVL(CHKIN_REA, 10),
                     NVL(CHKOUT_REA, 20),
                     TO_CHAR(ATT_DATE, 'yyyy-mm-dd') ||
                     (SELECT CHKIN_WKTM
                        FROM HRA_CLASSDTL
                       WHERE CLASS_CODE = HRA_CADSIGN.CLASS_CODE
                         AND SHIFT_NO = HRA_CADSIGN.SHIFT_NO),
                     TO_CHAR(ATT_DATE, 'yyyy-mm-dd') ||
                     (SELECT CHKOUT_WKTM
                        FROM HRA_CLASSDTL
                       WHERE CLASS_CODE = HRA_CADSIGN.CLASS_CODE
                         AND SHIFT_NO = HRA_CADSIGN.SHIFT_NO)
                INTO pchkinrea, pchkoutrea, pwkintm, pwkouttm
                FROM HRA_CADSIGN
               WHERE EMP_NO = P_EMP_NO
                 AND (SEND BETWEEN CASE WHEN CHKIN_CARD BETWEEN '0000' AND '0800' THEN
                      TO_CHAR(ATT_DATE, 'yyyy-mm-dd') ELSE
                      TO_CHAR(ATT_DATE - 1, 'yyyy-mm-dd') END || CHKIN_CARD AND
                     (TO_CHAR(ATT_DATE, 'yyyy-mm-dd') || CHKOUT_CARD))
                 AND (SSTART >= TO_CHAR(ATT_DATE - 1, 'yyyy-mm-dd') || CHKIN_CARD);
             ELSE 
              SELECT nvl(chkin_rea,10),nvl(chkout_rea,20),
                     to_char(att_date, 'yyyy-mm-dd') || (select chkin_wktm from hra_classdtl where class_code = hra_cadsign.class_code and shift_no = hra_cadsign.shift_no),
                     case when Night_Flag='Y' OR CLASS_CODE ='JB' then to_char(att_date+1, 'yyyy-mm-dd')
                                                else to_char(att_date, 'yyyy-mm-dd')
                                                end ||
                     (select chkout_wktm from hra_classdtl where class_code = hra_cadsign.class_code and shift_no = hra_cadsign.shift_no)
                INTO pchkinrea,pchkoutrea,pwkintm,pwkouttm
                FROM hra_cadsign
               WHERE emp_no = p_emp_no
                 AND (sEnd BETWEEN to_char(att_date, 'yyyy-mm-dd') || chkin_card  AND  case when Night_Flag='Y' then (to_char(att_date+1, 'yyyy-mm-dd') || chkout_card)
                                                else to_char(att_date, 'yyyy-mm-dd') || chkout_card
                                                end)
                 AND (sStart >= to_char(att_date, 'yyyy-mm-dd') || chkin_card );
             END IF;
           EXCEPTION
           WHEN no_data_found THEN
             pchkinrea := '15';
             pchkoutrea := '25';
             pwkouttm := sStart;
             pwkintm := sEnd;
           END ;
           END IF;

            --延後加班狀況
           IF (sStart >= pwkouttm AND pchkoutrea < '25') THEN
              RtnCode := 13 ;     -- 非因公務加班不可申請加班換補休
              GOTO Continue_ForEach1 ;
           END IF;
           --提前加班狀況
           IF (sEnd <= pwkintm AND pchkinrea < '15') THEN
              RtnCode := 13 ;     -- 非因公務加班不可申請加班換補休
              GOTO Continue_ForEach1 ;
           END IF;
         END IF;

       ------加班不可申請積休-------
       --20180612 108978 IMP201806109 同日加班申請方式只能同一種申請方式」規則
       BEGIN
         IF p_start_date_tmp <> 'N/A' THEN
           SELECT count(EMP_NO)
             INTO nCnt
             FROM HRP.HRA_OFFREC
            WHERE emp_no = p_emp_no
              AND ORG_BY = SOrganType
              AND ITEM_TYPE = 'A'
              AND STATUS NOT IN ('N') --排除不准
              AND (p_start_date_tmp = TO_CHAR(START_DATE_TMP,'YYYY-MM-DD') OR
                   (p_end_date = TO_CHAR(END_DATE,'YYYY-MM-DD') AND p_start_date = to_char(start_date,'yyyy-mm-dd')));
         ELSE
           SELECT count(EMP_NO)
             INTO nCnt
             FROM HRP.HRA_OFFREC
            WHERE emp_no = p_emp_no
              AND ORG_BY = SOrganType
              AND ITEM_TYPE = 'A'
              AND STATUS NOT IN ('N') --排除不准
              AND p_end_date = TO_CHAR(END_DATE,'YYYY-MM-DD');
         END IF;
       EXCEPTION
       WHEN no_data_found THEN
            nCnt := 0 ;
       END ;

       IF nCnt > 0 THEN
          RtnCode := 10 ;
          GOTO Continue_ForEach1 ;
       END IF;


       -----------------------------
       --20210113 by108482 申請不卡14天申請期限,超過五天才申請違規記點
       --20210204 by108482 每月申請最多至隔月5號(5號當天可以申請)
       --20241007 by108482 每月申請最多至隔月幾號抓參數HRA89的設定
       BEGIN
         SELECT CODE_NAME
           INTO LimitDay
           FROM HR_CODEDTL
          WHERE CODE_TYPE = 'HRA89'
            AND CODE_NO = 'DAY';
       EXCEPTION WHEN OTHERS THEN
         LimitDay := '5';
       END;
       IF trunc(SYSDATE) > 
          to_date(to_char(ADD_MONTHS(TO_DATE(p_start_date, 'yyyy/mm/dd'), 1),'YYYY-MM')||'-'||LimitDay,'yyyy/mm/dd') THEN
         RtnCode := 3;     
         GOTO Continue_ForEach1 ;
       END IF;

       --check 積休開放日
        IF p_end_time ='0000' then
        i_end_date := p_start_date;
        else i_end_date := p_end_date;
        end if;


--查是否為上班時間內申請 108978 20190109
       IF iCnt = 0 THEN
       --須修正機構別
         IF p_start_date_tmp <> 'N/A' THEN
           RtnCode := checkclass(p_emp_no, p_start_date_tmp, p_start_time, p_end_date, p_end_time, SOrganType);
         ELSE
           RtnCode := checkclass(p_emp_no, p_start_date, p_start_time, p_end_date, p_end_time, SOrganType);
         END IF;
       --20180913 108978 修正RtnCode IS NULL的問題
        IF (RtnCode IS NULL ) THEN 
          RtnCode := 8 ;
        END IF;
       END IF;
       --END IF;


       -- OnCall 判斷
       IF  RtnCode = 0 AND p_on_call ='Y' THEN
         RtnCode := checkOncall(p_emp_no, p_start_date, p_start_time, p_end_date, p_start_date_tmp,SOrganType);

         BEGIN
         SELECT count(*)
                INTO iCnt2
                FROM GESD_DORMMST
               WHERE emp_no = p_emp_no
                 AND USE_FLAG = 'Y';

          EXCEPTION
           WHEN no_data_found THEN
                iCnt2 := 0 ;
           END ;

           IF iCnt2 > 0 THEN
              RtnCode := 4 ;     -- 住宿不可申請OnCall
              GOTO Continue_ForEach1 ;
           END IF;

           BEGIN

           SELECT (CASE WHEN CHKIN_WKTM < CHKOUT_WKTM THEN ( CASE WHEN p_start_time between CHKIN_WKTM AND CHKOUT_WKTM  THEN 1 ELSE 0 END )

	                      ELSE ( CASE WHEN  (p_start_time between CHKIN_WKTM AND '2400') OR (p_start_time between '0000' AND CHKOUT_WKTM )  THEN 1 ELSE 0 END )END
                   ) AS COUNT
           INTO iCnt2
           FROM HRP.HRA_CLASSDTL
           WHERE SHIFT_NO='4'
             AND CLASS_CODE= sClassKind;

            EXCEPTION
             WHEN no_data_found THEN
                  iCnt2 := 0 ;
            END ;
            
            IF iCnt2 = 0 THEN
              BEGIN
                SELECT COUNT(*) 
                  INTO iCnt2
                  FROM hr_codedtl
                 WHERE code_type = 'HRA79'
                   AND code_no = (SELECT dept_no
                                    FROM hre_empbas
                                   WHERE emp_no = p_emp_no);
              EXCEPTION WHEN no_data_found THEN
                iCnt2 := 0 ;
              END;
            END IF;

             IF iCnt2 = 0 THEN
                RtnCode := 5 ;     -- 申請OnCall之積休日班別須為on call班
                GOTO Continue_ForEach1 ;
             END IF;
            BEGIN
            IF p_start_date_tmp <> 'N/A' THEN

            SELECT COUNT(*)
            INTO iCnt2
            FROM  HRA_CADSIGN
            Where HRA_CADSIGN.EMP_NO = p_emp_no
              AND TO_CHAR(HRA_CADSIGN.ATT_DATE,'YYYY-MM-DD') = p_start_date_tmp;

            ELSE
            SELECT COUNT(*)
            INTO iCnt2
            FROM  HRA_CADSIGN
            Where HRA_CADSIGN.EMP_NO = p_emp_no
              AND TO_CHAR(HRA_CADSIGN.ATT_DATE,'YYYY-MM-DD') = p_start_date;

            END IF;
            EXCEPTION
            WHEN no_data_found THEN
            iCnt2 := 0 ;
            END ;

            IF iCnt2 >0 THEN

            BEGIN

            --ON CALL VALIDATE
            -- IF p_start_date_tmp <> 'N/A' AND p_start_date_tmp <> p_start_date 代表 為跨夜申請
            -- 故 ATT_DATE 要加 1 , 並以 p_end_date 為基準

            IF p_start_date_tmp <> 'N/A' AND p_start_date_tmp <> p_start_date THEN

            SELECT (case when (  TO_DATE(  TO_CHAR(MAX(HRA_OTMSIGN.START_DATE),'YYYY-MM-DD')||MAX(HRA_OTMSIGN.START_TIME) ,'YYYY-MM-DD HH24MI') - TO_DATE(  TO_CHAR(MAX(HRA_CADSIGN.ATT_DATE),'YYYY-MM-DD')||MAX(HRA_CADSIGN.CHKOUT_CARD) ,'YYYY-MM-DD HH24MI'))*60*24 > 30 then 0 else 1 end )
            INTO iCnt2
            FROM HRA_OTMSIGN , HRA_CADSIGN
            Where HRA_CADSIGN.EMP_NO = HRA_OTMSIGN.EMP_NO
              AND TO_CHAR(ATT_DATE+1,'YYYY-MM-DD') = TO_CHAR(START_DATE,'YYYY-MM-DD')
              AND HRA_OTMSIGN.EMP_NO = p_emp_no
              AND TO_CHAR(HRA_OTMSIGN.START_DATE,'YYYY-MM-DD') = p_end_date;

            ELSE

            SELECT (case when (  NVL(TO_DATE(  TO_CHAR(MAX(HRA_OTMSIGN.START_DATE),'YYYY-MM-DD')||MAX(HRA_OTMSIGN.START_TIME) ,'YYYY-MM-DD HH24MI') - TO_DATE(  TO_CHAR(MAX(HRA_CADSIGN.ATT_DATE),'YYYY-MM-DD')||MAX(HRA_CADSIGN.CHKOUT_CARD) ,'YYYY-MM-DD HH24MI'),0))*60*24 > 30 then 0 else 1 end )
            INTO iCnt2
            FROM HRA_OTMSIGN , HRA_CADSIGN
            Where HRA_CADSIGN.EMP_NO = HRA_OTMSIGN.EMP_NO
              AND TO_CHAR(ATT_DATE,'YYYY-MM-DD') = TO_CHAR(START_DATE,'YYYY-MM-DD')
              AND HRA_OTMSIGN.EMP_NO = p_emp_no
              AND TO_CHAR(HRA_OTMSIGN.START_DATE,'YYYY-MM-DD') = p_start_date;

            END IF;
            EXCEPTION
            WHEN no_data_found THEN
            iCnt2 := 0 ;
            END ;

            IF iCnt2 = 0 THEN
                RtnCode := 0 ;
                GOTO Continue_ForEach1 ;
                ELSE
                 RtnCode := 6 ;     -- 申請OnCall失敗
                GOTO Continue_ForEach1 ;
            END IF;
           END IF;
          END IF;

--20180508比照加班換加班費的邏輯判斷判別是否為上班時間 108978

      IF iCnt = 0 THEN
        IF p_start_date_tmp <> 'N/A' THEN
          sClassKind := ehrphrafunc_pkg.f_getClassKind(p_emp_no,to_date(p_start_date_tmp,'YYYY-MM-DD'),SOrganType);
          sLastClassKind := ehrphrafunc_pkg.f_getClassKind(p_emp_no,to_date(p_start_date_tmp,'YYYY-MM-DD')-1,SOrganType);
        ELSE
          sClassKind := ehrphrafunc_pkg.f_getClassKind(p_emp_no,to_date(p_start_date,'YYYY-MM-DD'),SOrganType);
          sLastClassKind := ehrphrafunc_pkg.f_getClassKind(p_emp_no,to_date(p_start_date,'YYYY-MM-DD')-1,SOrganType);
        END IF;
      BEGIN
       SELECT COUNT(*)
         INTO iCnt
         FROM HRP.HRA_CLASSDTL
        Where CHKIN_WKTM  > CASE WHEN CHKOUT_WKTM ='0000' THEN '2400' ELSE CHKOUT_WKTM END
          AND SHIFT_NO <> '4'
          AND CLASS_CODE = sLastClassKind;

      EXCEPTION
      WHEN no_data_found THEN
      iCnt :=0;
      END ;

      IF sClassKind ='N/A' THEN
        RtnCode :=7;
        GOTO Continue_ForEach1 ;
      --sClassKind='ZZ'  20161219 新增班別 ZX,ZY
      --20180725 108978 增加ZQ
      ELSIF p_start_date_tmp <> 'N/A' AND sClassKind IN ('ZZ','ZX','ZY','ZQ') THEN
        GOTO Continue_ForEach3 ;
      ELSIF sClassKind IN ('ZZ','ZX','ZY','ZQ') AND iCnt=0 THEN
        GOTO Continue_ForEach3 ;
      ELSE
                  RtnCode :=  ehrphrafunc_pkg.checkClassTime(p_emp_no,p_start_date,p_start_time,p_end_date,p_end_time,sClassKind,sLastClassKind);

                  IF RtnCode = 1 THEN
                    RtnCode := 8; --上班時間不可申請加班!!存檔失敗!
                    GOTO Continue_ForEach1 ;
                  ELSIF (RtnCode IS NULL ) THEN 
                    RtnCode := 8 ;
                    GOTO Continue_ForEach1 ;
                  ELSIF RtnCode = 7 THEN --您尚未排班!!存檔失敗!
                    GOTO Continue_ForEach1 ;
                  ELSIF RtnCode = 8 THEN 
                    GOTO Continue_ForEach1 ;
                  END IF;
                  
      END IF; 

      END IF;      
      NULL;
      <<Continue_ForEach3>>
      NULL;
      
       BEGIN -- 當日班表應出勤時數
  	     IF p_start_date_tmp <> 'N/A' THEN
           SELECT WORK_HRS
    		     INTO sWorkHrs
    		     FROM HRA_CLASSMST
            WHERE CLASS_CODE= Ehrphrafunc_Pkg.f_getClassKind(p_emp_no,TO_DATE(p_start_date_tmp,'YYYY-MM-DD'),SOrganType);
         ELSE
           SELECT WORK_HRS
    		     INTO sWorkHrs
    		     FROM HRA_CLASSMST
            WHERE CLASS_CODE= Ehrphrafunc_Pkg.f_getClassKind(p_emp_no,TO_DATE(p_start_date,'YYYY-MM-DD'),SOrganType);
         END IF;
    	 EXCEPTION WHEN NO_DATA_FOUND THEN
         sWorkHrs := 0 ;
  	   END;
  
  	   BEGIN
         IF p_start_date_tmp <> 'N/A' THEN
          SELECT SUM(OTM_HRS)
    		    INTO  sTotAddHrs  -- 當日加班單時數
    		    FROM HRA_OTMSIGN
              WHERE TO_CHAR(nvl(Start_Date_Tmp,start_date),'yyyy-mm-dd') = p_start_date_tmp
              AND status<>'N'
              AND otm_flag = 'B'
              AND emp_no=p_emp_no
              AND OTM_NO <> p_otm_no;
         ELSE
  	      SELECT SUM(OTM_HRS)
    		    INTO  sTotAddHrs  -- 當日加班單時數
    		    FROM HRA_OTMSIGN
              WHERE TO_CHAR(nvl(Start_Date_Tmp,start_date),'yyyy-mm-dd')=  p_start_date
              AND status<>'N'
              AND otm_flag = 'B'
              AND emp_no=p_emp_no
              AND OTM_NO <> p_otm_no;
         END IF;
    	 EXCEPTION WHEN NO_DATA_FOUND THEN
         sTotAddHrs := 0 ;
  	   END;

      BEGIN
        --20180725 108978 增加ZQ
  	      SELECT  NVL(sum(decode(s_class , 'ZZ',(soneott+soneoss+soneuu),'ZQ',(soneott+soneoss+soneuu),'ZY',(soneott+soneoss+soneuu),sotm_Hrs)),0)
  		      INTO  sTotMonAdd  -- 當月積休單總時數(含在途)
    		   FROM  (
          SELECT (select class_code
                    from hra_classsch_view
                   where emp_no = HRA_OFFREC.Emp_No
                     and att_date = to_char(NVL(Start_Date_Tmp,start_date), 'yyyy-mm-dd')) as s_class,                
                 otm_hrs,
                 soneo,
                 soneott,
                 soneoss,
                 sotm_hrs,
                 soneuu
            FROM HRA_OFFREC
            --20250219 用應出勤日年月確認加班時數
            WHERE TO_CHAR(NVL(Start_Date_Tmp,start_date),'yyyy-mm')=  SUBSTR(p_start_date_tmp ,1,7)
             AND status <> 'N'
             AND item_type = 'A'
             AND emp_no=p_emp_no) tt;
  		EXCEPTION
           WHEN NO_DATA_FOUND THEN
             sTotMonAdd := 0 ;
  	   END;  
  
  	   IF sTotAddHrs IS NULL THEN
  	     sTotAddHrs := 0 ;
  	   END IF;

	   BEGIN
	      SELECT (mon_getadd + mon_addhrs   + mon_spcotm -  mon_cutotm + mon_dutyhrs )
		      INTO  sMonClassAdd --當月排班超時
          FROM hra_attvac_view
         --20250219 用應出勤日年月確認加班時數
         WHERE  hra_attvac_view.sch_ym = SUBSTR(p_start_date_tmp ,1,7)
		  AND hra_attvac_view.emp_no = p_emp_no ;
	   EXCEPTION
         WHEN NO_DATA_FOUND THEN
           sMonClassAdd := 0 ;
	   END;

  	   
        BEGIN
    	      SELECT NVL(SUM(OTM_HRS),0)
    		    INTO  sOtmsignHrs  -- 當月加班單總時數(含在途)
    		  FROM HRA_OTMSIGN
              --20250219 用應出勤日年月確認加班時數
              WHERE TO_CHAR(NVL(Start_Date_Tmp,start_date),'yyyy-mm')=  SUBSTR(p_start_date_tmp ,1,7)
              AND status<>'N'
              AND otm_flag = 'B'
              AND emp_no=p_emp_no;
    		EXCEPTION
             WHEN NO_DATA_FOUND THEN
               sOtmsignHrs := 0 ;
    	   END;
--0301開始加班每月不能超過54HR 108978
       --20190301 by108482 因改四週排班，排除班表超時工時
       IF ((sOtmhrs+sWorkHrs+sTotAddHrs)> 12 OR (sTotMonAdd+sOtmsignHrs+/*sMonClassAdd+*/sOtmhrs>54)) THEN
	        RtnCode := 15 ;
       GOTO Continue_ForEach1 ;
       END IF;
       
       IF (RtnCode = 0 )  THEN 
       --20250219 用應出勤日年月確認加班時數
       RtnCode := Check3MonthOtmhrs(p_emp_no,p_start_date_tmp, p_otm_hrs,SOrganType);
       END IF;
       
       NULL ;
       <<Continue_ForEach1>>
       NULL ;

  END hraC010a;
   
  PROCEDURE hraC010a_add(p_otm_no         VARCHAR2,
                         p_emp_no         VARCHAR2,
                         p_start_date     VARCHAR2,
                         p_start_date_tmp VARCHAR2,
                         p_otm_hrs        VARCHAR2,
                         OrganType_IN     VARCHAR2,
                         RtnCode          OUT NUMBER) IS
  
  sOtmhrs     NUMBER := TO_NUMBER(p_otm_hrs);
  sClassCode  VARCHAR2(3); --當日班別
  sWorkHrs    NUMBER; --當日班別時數
  sTotAddHrs  NUMBER; --當日在途加班補休申請時數
  sTotMonAdd  NUMBER; --當月加班費總時數(含在途)
	sOtmsignHrs NUMBER; --當月加班補休總時數(含在途)
  
  BEGIN
    RtnCode     := 0;
    sWorkHrs    := 0;
    sTotAddHrs  := 0;
    sTotMonAdd  := 0;
    sOtmsignHrs := 0;
    
    sClassCode := Ehrphrafunc_Pkg.f_getClassKind(p_emp_no,TO_DATE(NVL(p_start_date_tmp, p_start_date),'YYYY-MM-DD'),OrganType_IN);
    BEGIN --當日班別時數
      SELECT WORK_HRS
		    INTO sWorkHrs
		    FROM HRA_CLASSMST
       WHERE CLASS_CODE = sClassCode;
		EXCEPTION WHEN NO_DATA_FOUND THEN
      sWorkHrs := 0 ;
	  END;
    
    BEGIN --當日在途加班補休申請時數
      SELECT SUM(OTM_HRS)
    	  INTO sTotAddHrs
    		FROM HRA_OTMSIGN
       WHERE TO_CHAR(nvl(Start_Date_Tmp,start_date),'yyyy-mm-dd') = NVL(p_start_date_tmp,p_start_date)
         AND status <> 'N'
         AND otm_flag = 'B'
         AND emp_no = p_emp_no
         AND OTM_NO <> p_otm_no;
    EXCEPTION WHEN NO_DATA_FOUND THEN
      sTotAddHrs := 0 ;
  	END;
    
    IF sOtmhrs IS NULL THEN sOtmhrs := 0; END IF;
    IF sWorkHrs IS NULL THEN sWorkHrs := 0; END IF;
    IF sTotAddHrs IS NULL THEN sTotAddHrs := 0; END IF;
    
    IF (sOtmhrs + sWorkHrs + sTotAddHrs)> 12 THEN
      RtnCode := 1;
      GOTO Continue_ForEach1;
    END IF;
    
    BEGIN
  	  SELECT NVL(SUM(decode(s_class , 'ZZ',(soneott+soneoss+soneuu),
                                      'ZQ',(soneott+soneoss+soneuu),
                                      'ZY',(soneott+soneoss+soneuu),
                                      sotm_Hrs)),0)
  		  INTO sTotMonAdd  -- 當月加班費總時數(含在途)
    	  FROM (SELECT (SELECT class_code
                        FROM hra_classsch_view
                       WHERE emp_no = HRA_OFFREC.Emp_No
                         AND att_date = to_char(start_date, 'yyyy-mm-dd')) as s_class,                
                     otm_hrs,
                     soneo,
                     soneott,
                     soneoss,
                     sotm_hrs,
                     soneuu
                FROM HRA_OFFREC
               WHERE TO_CHAR(NVL(Start_Date_Tmp,start_date),'yyyy-mm') = 
                     SUBSTR(NVL(p_start_date_tmp, p_start_date), 1, 7)
                 AND status <> 'N'
                 AND item_type = 'A'
                 AND emp_no = p_emp_no) tt;
    EXCEPTION WHEN NO_DATA_FOUND THEN
      sTotMonAdd := 0 ;
  	END;
    
    BEGIN
    	SELECT NVL(SUM(OTM_HRS),0)
    	  INTO sOtmsignHrs  -- 當月加班補休總時數(含在途)
    	  FROM HRA_OTMSIGN
       WHERE TO_CHAR(NVL(Start_Date_Tmp,start_date),'yyyy-mm') = 
             SUBSTR(NVL(p_start_date_tmp, p_start_date), 1, 7)
         AND status <> 'N'
         AND otm_flag = 'B'
         AND emp_no = p_emp_no;
    EXCEPTION WHEN NO_DATA_FOUND THEN
      sOtmsignHrs := 0 ;
    END;
    
    IF sTotMonAdd IS NULL THEN sTotMonAdd := 0; END IF;
    IF sOtmsignHrs IS NULL THEN sOtmsignHrs := 0; END IF;
    IF (sOtmhrs + sTotMonAdd + sOtmsignHrs) > 54 THEN
      RtnCode := 2;
      GOTO Continue_ForEach1;
    END IF;
    
    RtnCode := Check3MonthOtmhrs(p_emp_no, NVL(p_start_date_tmp,p_start_date), p_otm_hrs, OrganType_IN);
    IF RtnCode = 16 THEN
      RtnCode := 3;
      GOTO Continue_ForEach1;
    END IF;
    
    NULL;
    <<Continue_ForEach1>>
    NULL;
  END hraC010a_add;

/*------------------------------------------
-- 醫師補休稽核
------------------------------------------*/

PROCEDURE hraD010(p_emp_no           VARCHAR2
                , p_start_date       VARCHAR2
                , p_start_time       VARCHAR2
                , p_end_date         VARCHAR2
                , p_end_time         VARCHAR2
                , P_otm_hrs          VARCHAR2
                , RtnCode       OUT NUMBER) IS

    sEmpNo      hra_offrec.emp_no%TYPE      := p_emp_no;
    sStart      VARCHAR2(20) := p_start_date || p_start_time;
    sEnd        VARCHAR2(20) := p_end_date || p_end_time ;
    sStart1     VARCHAR2(20) ;
    sEnd1       VARCHAR2(20) ;
    iCnt        INTEGER ;
    cVac_V      NUMBER;
    cVac_SUP    NUMBER;

    BEGIN


       RtnCode := 0 ;

       --因 BETWEEN 會比較前後值,故 START + 1 分鐘 , END -1 分鐘 來跳過
       sStart1 := TO_CHAR(TO_DATE(sStart,'YYYY-MM-DDHH24MI')+0.000695,'YYYY-MM-DDHH24MI');
       sEnd1  := TO_CHAR(TO_DATE(sEnd,'YYYY-MM-DDHH24MI')-0.000694,'YYYY-MM-DDHH24MI');


       ------------------------- 積休單 -------------------------
       --(檢核在資料庫中除''不准''以外的積休單申請時間是否重疊)

       --現有的補休單時間介於新積休單
         BEGIN
          SELECT COUNT(*)
            INTO iCnt
            FROM hra_DSUPREC
           WHERE  emp_no    = sEmpNo
             AND ((sStart1  between to_char(start_date, 'YYYY-MM-DD') || start_time and to_char(end_date, 'YYYY-MM-DD') || end_time)
              OR  ( sEnd1    between to_char(start_date, 'YYYY-MM-DD') || start_time and to_char(end_date, 'YYYY-MM-DD') || end_time ))
             AND status <> 'N' ;

         EXCEPTION
         WHEN no_data_found THEN
            iCnt := 0 ;
       END;

       IF iCnt = 0 THEN

       --新補休單介於現有的積休單時間
       BEGIN
          SELECT COUNT(*)
            INTO iCnt
            FROM hra_DSUPREC
           WHERE emp_no    = sEmpNo
             AND ((to_char(start_date, 'YYYY-MM-DD') || start_time between sStart1 and sEnd1)
              OR  (to_char(end_date, 'YYYY-MM-DD')   || end_time   between sStart1 and sEnd1))
             AND status <> 'N' ;

         EXCEPTION
         WHEN no_data_found THEN
            iCnt := 0 ;
       END;
       END IF;

       IF iCnt > 0 THEN
       RtnCode := 1 ;
       GOTO Continue_ForEach1 ;
       END IF;

      --ERROR CODE 16 請特休＋補休不可超過10天

         BEGIN
            SELECT nvl(SUM( nvl(VAC_DAYS,0) *8 + nvl(VAC_HRS,0)),0)
              INTO cVac_V
              FROM HRP.HRA_DEVCREC
             WHERE VAC_TYPE = 'V'
               AND EMP_NO = sEmpNo
               AND STATUS = 'Y'
               AND TO_CHAR(START_DATE,'YYYY-MM') = substr(p_start_date, 1, 7) ;
         EXCEPTION
         WHEN OTHERS THEN
              cVac_V := 0;
         END;

         BEGIN
            SELECT nvl(SUM( nvl(OTM_HRS,0)),0)
              INTO cVac_SUP
              FROM HRP.HRA_DSUPREC
             WHERE EMP_NO = sEmpNo
               AND STATUS = 'Y'
               AND TO_CHAR(START_DATE,'YYYY-MM') = substr(p_start_date, 1, 7) ;
         EXCEPTION
         WHEN OTHERS THEN
              cVac_SUP := 0;
         END;

          IF cVac_V + cVac_SUP + P_otm_hrs > 80 THEN
          RtnCode := 16;
          GOTO Continue_ForEach1;
          END IF;





       NULL;
       <<Continue_ForEach1>>
       NULL;

    END hraD010;
/*------------------------------------------
-- SQL_NAME : hraC020.sql
-- 補休稽核
------------------------------------------*/

PROCEDURE hraC020(p_sup_no          VARCHAR2
                , p_otm_date        VARCHAR2
                , p_sup_hrs         VARCHAR2
                , RtnCode       OUT NUMBER) IS


    sEmp_no      hra_supmst.emp_no%TYPE;
    sStart_date  hra_supmst.start_date%TYPE ;
    nSupHrs         NUMBER;

    nOtm_hrs     hra_otmsign.otm_hrs%TYPE;
    nCnt_hrs     NUMBER;

--    sStart_time  hra_supmst.start_time%TYPE ;
--    sEnd_date    hra_supmst.end_date%TYPE ;
--    sEnd_time    hra_supmst.end_time%TYPE ;
--    nCnt   NUMBER;


    BEGIN
       RtnCode  := 0 ;

       ------------------------計算請補休時數------------------------
       BEGIN
          SELECT emp_no
               , start_date
--               , start_time
--               , end_date
--               , end_time
               , sup_hrs
            INTO sEmp_no
               , sStart_date
--               , sStart_time
--               , sEnd_date
--               , sEnd_time
               , nSupHrs
            FROM hra_supmst
           WHERE sup_no = p_sup_no ;
--             AND status = 'U' ;
       EXCEPTION
       WHEN OTHERS THEN
            sEmp_no       := NULL;
            sStart_date   := null;
            nSupHrs       := 0 ;
--            sStart_time   := null;
--            sEnd_date     := null;
--            sEnd_time     := null;
--            RtnCode       := 7 ;    -- 無請補休
--            GOTO Continue_ForEach1 ;
       END;

       IF to_char(sStart_date, 'yyyy-mm-dd') < p_otm_date or sStart_date is null THEN
          RtnCode  := 7 ;   -- 補休日期 < 加班日期
          GOTO Continue_ForEach1 ;
       END IF;

       IF nSupHrs = 0 THEN
          RtnCode  := 8 ;   -- 無補休時數
          GOTO Continue_ForEach1 ;
       END IF;


  --     IF NOT (sEnd_date IS NULL OR sEnd_time IS NULL) THEN

   --       nSupHrs := ehrphra2_pkg.f_hra3010c(ls_start_date => sStart_date
   --                                     , ls_start_time => sStart_time
    --                                    , ls_end_date   => sEnd_date
   --                                     , ls_end_time   => sEnd_time);
   --    END IF;


   --    IF MOD(nSupHrs, 60) = 0 OR MOD(nSupHrs, 60) = 30 THEN
   --       nSupHrs := nSupHrs / 60 ;
   --    ELSIF MOD(nSupHrs, 60) > 30 THEN
    --      nSupHrs := TRUNC(nSupHrs / 60) + 1 ;
   --    ELSIF MOD(nSupHrs, 60) < 30 THEN
   --       nSupHrs := TRUNC(nSupHrs / 60) + 0.5 ;
   --    END IF ;

       ------------------------計算請補休時數------------------------

       -------------------補休時數及補休日是否到期-------------------
       BEGIN
          SELECT NVL(SUM(otm_hrs), 0)
            INTO nOtm_hrs
            FROM hra_otmsign
           WHERE status = 'Y'
             AND oncall = 'N'
             AND trn_ym IS NULL
             AND emp_no = sEmp_no
             AND to_char(start_date, 'yyyy-mm-dd') = p_otm_date ;
       EXCEPTION
       WHEN OTHERS THEN
            nOtm_hrs  := 0 ;
       END ;

       IF nOtm_hrs = 0 THEN
          RtnCode  := 2 ;   -- 該日無超時時數可請補休
          GOTO Continue_ForEach1 ;
       END IF ;

       IF (to_char(add_months(sStart_date, 1), 'yyyy-mm-dd') < p_otm_date) THEN
           RtnCode  := 3 ;   -- 已逾期，不可補休
           GOTO Continue_ForEach1 ;
       END IF;

       BEGIN
          SELECT nvl(sum(sup_hrs), 0)
            INTO nCnt_hrs
            FROM hra_supdtl
           WHERE sup_no in (select sup_no from hra_supmst where emp_no = sEmp_no
                               AND status = 'Y')
             AND to_char(otm_date, 'yyyy-mm-dd') = p_otm_date ;
--             and status in ('Y', 'U')
       EXCEPTION
       WHEN OTHERS THEN
            nCnt_hrs := 0 ;
       END ;

       IF nOtm_hrs - (nCnt_hrs + p_sup_hrs) < 0 THEN
           RtnCode  := 4 ;   -- 該日超時時數不足此請補休時數
          GOTO Continue_ForEach1 ;
       END IF ;

       BEGIN
          SELECT nvl(sum(sup_hrs), 0)
            INTO nCnt_hrs
            FROM hra_supdtl
           WHERE sup_no = p_sup_no ;
--             AND status = 'U' ;
       EXCEPTION
       WHEN OTHERS THEN
            nCnt_hrs := 0 ;
       END ;

      -- IF (nCnt_hrs + p_sup_hrs) < nSupHrs THEN --<==ERROR !!若是兩筆以上的補休會有問題!
     --     RtnCode  := 5 ;   -- 超時時數dtl < 請補休時數mst (警告訊息)  此張申請單
     --  ELSIF (nCnt_hrs + p_sup_hrs) > nSupHrs  THEN
       IF (nCnt_hrs + p_sup_hrs) > nSupHrs  THEN
          RtnCode  := 6 ;   -- 超時時數dtl > 請補休時數mst (警告訊息)  此張申請單
       END IF;

       ------------------補休時數及補休日是否到期-------------------

       NULL ;
       <<Continue_ForEach1>>
       NULL ;

    END hraC020 ;


/*------------------------------------------
-- SQL_NAME : hraC030.sql
-- 積假稽核
------------------------------------------*/
/*
PROCEDURE hraC030(p_item_type       VARCHAR2
                , p_emp_no          VARCHAR2
                , p_start_date      VARCHAR2
                , p_start_time      VARCHAR2
                , p_end_date        VARCHAR2
                , p_end_time        VARCHAR2
--                , p_upd_type        VARCHAR2
                , RtnCode       OUT NUMBER) IS

    sItemType   hra_offrec.item_type%TYPE   := p_item_type;
    sEmpNo      hra_offrec.emp_no%TYPE      := p_emp_no;
    sStart      VARCHAR2(20) := p_start_date || p_start_time;
    sEnd        VARCHAR2(20) := p_end_date || p_end_time ;
    sSDate1      VARCHAR2(20) ;
    sEDate1     VARCHAR2(20) ;
    sStart1     VARCHAR2(20) ;
    sEnd1       VARCHAR2(20) ;
    sStart2      DATE ;
    sEnd2        DATE ;
  --  sUpdType    VARCHAR2(1) := 'I' ;  -- := p_upd_type ;
    iCnt        INTEGER ;
    sNightFlag VARCHAR2(1) ;



    BEGIN

       RtnCode := 0 ;
       sStart2 := TO_DATE(sStart,'YYYY-MM-DDHH24MI');
       sEnd2 := TO_DATE(sEnd,'YYYY-MM-DDHH24MI');

       sEnd1  := TO_CHAR(sEnd2-0.000694,'YYYY-MM-DDHH24MI');
       sStart1 := TO_CHAR(sStart2+0.000695,'YYYY-MM-DDHH24MI');

        ------------------------- 補休單 -------------------------
       --(檢核在資料庫中除''不准''以外的補休單申請時間是否重疊)

       --現有的補休單時間介於新補休單
       BEGIN
          SELECT COUNT(*)
            INTO iCnt
            FROM hra_offrec
           WHERE item_type = sItemType
             AND emp_no    = sEmpNo
             AND ((sStart1  between to_char(start_date, 'YYYY-MM-DD') || start_time and to_char(start_date, 'YYYY-MM-DD') || end_time)
              OR  ( sEnd1    between to_char(start_date, 'YYYY-MM-DD') || start_time and to_char(start_date, 'YYYY-MM-DD') || end_time ))
             AND status <> 'N' ;

         EXCEPTION
         WHEN no_data_found THEN
            iCnt := 0 ;
       END;

       IF iCnt = 0 THEN

       --新補休單介於現有的補休單時間
       BEGIN
          SELECT COUNT(*)
            INTO iCnt
            FROM hra_offrec
           WHERE item_type = sItemType
             AND emp_no    = sEmpNo
             AND ((to_char(start_date, 'YYYY-MM-DD') || start_time between sStart1 and sEnd1)
              OR  (to_char(end_date, 'YYYY-MM-DD')   || end_time   between sStart1 and sEnd1))
             AND status <> 'N' ;

         EXCEPTION
         WHEN no_data_found THEN
            iCnt := 0 ;
       END;
       END IF;

       IF iCnt > 0 THEN
          RtnCode := 1 ;
          GOTO Continue_ForEach1 ;
       END IF;


       ------------------------- 加班簽到 -------------------------
       IF sItemType = 'A' THEN
       BEGIN
          SELECT count(*)
            INTO iCnt
            FROM hra_otmsign
           WHERE emp_no = sEmpNo
             AND ((sStart between to_char(start_date, 'YYYY-MM-DD') || start_time
                              and to_char(end_date, 'YYYY-MM-DD') || end_time)
              AND  (sEnd   between to_char(start_date, 'YYYY-MM-DD') || start_time
                              and to_char(end_date, 'YYYY-MM-DD') || end_time))
             AND substr(otm_no, 1, 3) = 'OTS';

       EXCEPTION
       WHEN no_data_found THEN
            iCnt := 0 ;
       END ;

       IF iCnt = 0 THEN
          RtnCode := 2 ;     -- 無加班簽到
       END IF;
       ------------------------- 加班簽到 -------------------------


       ------------------------- 一般簽到 -------------------------
       IF RtnCode = 2 THEN
       RtnCode :=0;
       BEGIN

    SELECT count(*)
            INTO iCnt
            FROM hra_cadsign
           WHERE emp_no = p_emp_no
                  --因為忘打卡單UPDATE班表的時間為 0000 故將 0000 改為 2400
          --       and(sEnd BETWEEN to_char(att_date, 'yyyy-mm-dd') || case when nvl(chkin_card, '') = '0000' then '2400' else nvl(chkin_card, '')end
			 		--		                           AND CASE WHEN case when nvl(chkin_card, '') = '0000' then '2400' else nvl(chkin_card, '')end > nvl(chkout_card, '') or Night_Flag='Y'
          --                                  then (to_char(att_date+1, 'yyyy-mm-dd') || nvl(chkout_card, ''))
          --                                  else to_char(att_date, 'yyyy-mm-dd') || nvl(chkout_card, '')
          --                                  end)
          --  and sStart >= to_char(att_date, 'yyyy-mm-dd') || case when nvl(chkin_card, '') = '0000' then '2400' else nvl(chkin_card, '')end;

                 and(sEnd BETWEEN to_char(att_date, 'yyyy-mm-dd') || chkin_card  AND  case when Night_Flag='Y' then (to_char(att_date+1, 'yyyy-mm-dd') || chkout_card)
                                            else to_char(att_date, 'yyyy-mm-dd') || chkout_card
                                            end)
             and (sStart >= to_char(att_date, 'yyyy-mm-dd') || chkin_card );
--             and to_char(att_date, 'yyyy-mm-dd') = p_start_date;



       EXCEPTION
       WHEN no_data_found THEN
            iCnt := 0 ;
       END ;

       IF iCnt = 0 THEN
          RtnCode := 2 ;     -- 無簽到時間
       END IF;
       END IF;

        ------------------------- 一般簽到 (大夜加班判斷)-------------------------
       IF RtnCode = 2 THEN
       RtnCode :=0;
       BEGIN

       SELECT NIGHT_FLAG
         INTO sNightFlag
         FROM hra_cadsign
        WHERE emp_no = p_emp_no
          and att_date = to_date(p_start_date, 'yyyy-mm-dd')-1;

      IF sNightFlag = 'Y' THEN

      sSDate1 := to_char(to_date(p_start_date,'YYYY-MM-DD')-1,'yyyy-mm-dd')|| p_start_time;
      sEDate1 := to_char(to_date(p_end_date,'YYYY-MM-DD')-1,'yyyy-mm-dd')|| p_end_time;

         SELECT count(*)
            INTO iCnt
            FROM hra_cadsign
           WHERE emp_no = p_emp_no
             and(sEDate1 < to_char(att_date, 'yyyy-mm-dd') || chkout_card )
             and (sSDate1 < to_char(att_date, 'yyyy-mm-dd') || chkout_card );

      ELSE
       iCnt := 0 ;
      END IF;

       EXCEPTION
       WHEN no_data_found THEN
            iCnt := 0 ;
       END ;

       IF iCnt = 0 THEN
          RtnCode := 2 ;     -- 無簽到時間
       END IF;
       END IF;



      IF RtnCode <> 0 THEN
         GOTO Continue_ForEach1 ;
       END IF;

       END IF;





     --  RtnCode := 0;

       NULL;
       <<Continue_ForEach1>>
       NULL;


    END hraC030;
*/

  PROCEDURE hraC020a( p_otm_date        VARCHAR2,
                        p_sup_date        VARCHAR2,
                        RtnCode       OUT NUMBER) IS



    basedate DATE:=add_months( TO_DATE(substr(p_sup_date,1,7)||'-01','YYYY-MM-DD'),-1);

    BEGIN

    RtnCode  := 0 ;

    IF p_otm_date > p_sup_date THEN
    RtnCode  := 1 ;
    GOTO Continue_ForEach1 ;
    END IF;

    if p_otm_date not between to_char(basedate,'yyyy-mm-dd')and p_otm_date  then
    RtnCode  := 2;
    GOTO Continue_ForEach1 ;
    end if;

    NULL;
    <<Continue_ForEach1>>
    NULL;


    END hraC020a;

/*------------------------------------------
-- 積借休稽核
-- 多機構驗證中
------------------------------------------*/
PROCEDURE hraC030(p_item_type        VARCHAR2
                    , p_emp_no           VARCHAR2
                    , p_start_date       VARCHAR2
                    , p_start_time       VARCHAR2
                    , p_end_date         VARCHAR2
                    , p_end_time         VARCHAR2
                    , p_on_call          VARCHAR2
                    , p_posted_startdate VARCHAR2
                    , p_posted_starttime VARCHAR2
                    , p_posted_status    VARCHAR2
                    , p_start_date_tmp   VARCHAR2
                    , p_otm_hrs          VARCHAR2
                    , OrganType_IN       VARCHAR2
                    , RtnCode            OUT NUMBER) IS

    sItemType   hra_offrec.item_type%TYPE := p_item_type;
    sEmpNo      hra_offrec.emp_no%TYPE    := p_emp_no;
    sStart      VARCHAR2(20) := p_start_date || p_start_time;
    sEnd        VARCHAR2(20) := p_end_date || p_end_time ;
    sOnCall     VARCHAR2(1)  := p_on_call;
    sOffrest    NUMBER;
    SOrganType  VARCHAR2(10) := OrganType_IN;
    --20113-03-22 modify by weihun VACHAR2(3) -> NUMBER(5,1)
    sOtmhrs     NUMBER  := TO_NUMBER(p_otm_hrs);
    sClassKind  VARCHAR2(3);
    sLastClassKind VARCHAR2(3);
    sNextClassKind VARCHAR2(3);
    iCnt        INTEGER ;
    iCnt2       INTEGER ;
    i_end_date  VARCHAR2(10);
    iCheckCard  VARCHAR2(1); --註記是否為加班打卡,預設N(非加班打卡) 20181219 by108482
    iposlevel   VARCHAR2(1); --確認職等，7職等(含)以上人員不能自行申請加班 20190306 by108482
    iChkinWktm  VARCHAR2(4);
    iChkoutWktm VARCHAR2(4);
    LimitDay    VARCHAR2(2);

    --上限加舊結算
    sOldSumary    NUMBER;

    pchkinrea  VARCHAR2(2);
    pchkoutrea VARCHAR2(2);
    pwkintm    VARCHAR2(20);
    pwkouttm   VARCHAR2(20);
    sWorkHrs     NUMBER; -- 當日班表時數
	  sTotAddHrs   NUMBER; --當日在途積休單申請時數
	  sTotMonAdd   NUMBER; --當月積休單總時數(含在途)
	  sOtmsignHrs  NUMBER; --當日加班單時數
  	sMonClassAdd NUMBER; -- 當月班表超時

    BEGIN
      sOldSumary := 0;
      RtnCode := 0 ;

      sWorkHrs:=0;
	    sTotAddHrs:=0;
	    sTotMonAdd:=0;
      sOtmsignHrs:=0;
	    sMonClassAdd:=0;
      iCheckCard := 'N';

       --IF SYSDATE  > TO_DATE(p_start_date,'YYYY-MM-DD')+7 THEN 20151110 修改 14天 可申請
      /*IF SYSDATE  > TO_DATE(p_start_date,'YYYY-MM-DD')+14 THEN
        RtnCode := 11 ;
        GOTO Continue_ForEach1 ;
      END IF;*/
      --20210113 by108482 申請不卡14天申請期限,超過五天才申請違規記點
      --20210204 by108482 每月申請最多至隔月5號(5號當天可以申請)
      --20241007 by108482 每月申請最多至隔月幾號抓參數HRA89的設定
      BEGIN
        SELECT CODE_NAME
          INTO LimitDay
          FROM HR_CODEDTL
         WHERE CODE_TYPE = 'HRA89'
           AND CODE_NO = 'DAY';
      EXCEPTION WHEN OTHERS THEN
        LimitDay := '5';
      END;
      /*IF trunc(SYSDATE) > trunc(ADD_MONTHS(TO_DATE(p_start_date, 'yyyy/mm/dd'), 1), 'mm') +9 THEN
        RtnCode := 11 ;
        GOTO Continue_ForEach1 ;
      END IF;*/
      IF trunc(SYSDATE) > 
         to_date(to_char(ADD_MONTHS(TO_DATE(p_start_date, 'yyyy/mm/dd'), 1),'YYYY-MM')||'-'||LimitDay, 'yyyy/mm/dd') THEN
        RtnCode := 11 ;
        GOTO Continue_ForEach1 ;
      END IF;

      --IF 借休該日班表時數為0時,不可存檔
      IF sItemType ='O' THEN
        sClassKind := ehrphrafunc_pkg.f_getClassKind(p_emp_no,to_date(p_start_date,'YYYY-MM-DD'),SOrganType);
      BEGIN
       SELECT COUNT(*)
         INTO iCnt
         FROM HRP.HRA_CLASSMST
        WHERE CLASS_CODE = sClassKind
          AND WORK_HRS = 0;
      END;

      IF iCnt > 0 THEN
        RtnCode := 12 ;
        GOTO Continue_ForEach1 ;
      END IF;
      END IF;

      IF sItemType ='O' AND p_start_date_tmp <> p_start_date  THEN
        sStart := TO_CHAR(TO_DATE(p_start_date,'YYYY-MM-DD')+1,'YYYY-MM-DD') ||p_start_time ;
      END IF;

      ------------------------- 積休單 -------------------------
      --(檢核在資料庫中除''不准''以外的積休單申請時間是否重疊)
      IF sItemType = 'A' THEN
       
      BEGIN
        SELECT pos_level
          INTO iposlevel
          FROM HRE_POSMST
         WHERE pos_no = (SELECT pos_no FROM hre_empbas WHERE emp_no = sEmpNo);
      EXCEPTION WHEN no_data_found THEN
        iposlevel := NULL;
      END;
      --108482 20190306 7職等(含)以上人員不能自行申請加班
      IF iposlevel IS NULL THEN
        RtnCode := 99 ;
        GOTO Continue_ForEach1 ;
      ELSIF iposlevel >= 7 THEN
        RtnCode := 17 ;
        GOTO Continue_ForEach1 ;
      END IF;

      BEGIN
        SELECT COUNT(ROWID)
          INTO iCnt
          FROM hra_offrec
         WHERE emp_no = sEmpNo
           AND item_type = sItemType
           AND (((sStart >=  to_char(start_date, 'YYYY-MM-DD') || start_time AND sStart < to_char(end_date, 'YYYY-MM-DD')||end_time)
                OR (sEnd > to_char(start_date, 'YYYY-MM-DD') || start_time AND sEnd <= to_char(end_date, 'YYYY-MM-DD')||end_time ))
      		      OR (to_char(start_date, 'YYYY-MM-DD') || start_time >= sStart AND to_char(end_date, 'YYYY-MM-DD') ||end_time < sStart)
                OR (to_char(start_date, 'YYYY-MM-DD') || start_time > sEnd AND to_char(end_date, 'YYYY-MM-DD') ||end_time <= sEnd)
			          OR (to_char(start_date, 'YYYY-MM-DD') || start_time >= sStart AND to_char(end_date, 'YYYY-MM-DD')||end_time <= sEnd))
                --20200410 by108482 檢核更精確
                --OR (to_char(start_date, 'YYYY-MM-DD') || start_time = sStart AND to_char(end_date, 'YYYY-MM-DD')||end_time = sEnd))
           AND status in ('U','1','2','Y') AND ORG_BY = SOrganType;
      EXCEPTION WHEN no_data_found THEN
        iCnt := 0 ;
      END;

      IF iCnt > 0 THEN
        RtnCode := 1 ;
      END IF;
      
      --判斷是否為更改原資料
      IF iCnt > 0 AND p_posted_startdate<>'N/A' AND  p_posted_starttime<>'N/A' AND p_posted_status<>'N/A' THEN

        BEGIN
          SELECT COUNT(*)
            INTO iCnt
            FROM hra_offrec
           WHERE emp_no    = sEmpNo
             AND item_type = sItemType
             AND start_date = to_date(p_posted_startdate,'yyyy-mm-dd')
             AND start_time = p_posted_starttime
             AND status = p_posted_status
             AND org_by = SOrganType;
        EXCEPTION WHEN no_data_found THEN
          iCnt := 0 ;
        END;

        IF iCnt >= 1 THEN
          RtnCode := 0 ;
        END IF;
      END IF;
      
      ELSE --sItemType = 'O'
        BEGIN
          SELECT COUNT(ROWID)
            INTO iCnt
            FROM hra_offrec
           WHERE emp_no = sEmpNo
             AND item_type = sItemType
             AND (start_date = start_date_tmp AND
		             (
                 (((sStart >=  to_char(start_date, 'YYYY-MM-DD') ||start_time and sStart <  to_char(end_date, 'YYYY-MM-DD')||end_time)
                 OR (sEnd  >  to_char(start_date, 'YYYY-MM-DD') ||start_time and sEnd <=  to_char(end_date, 'YYYY-MM-DD')||end_time ))
      		       OR (to_char(start_date, 'YYYY-MM-DD') ||start_time >= sStart And  to_char(end_date, 'YYYY-MM-DD') ||end_time < sStart)
                 OR (to_char(start_date, 'YYYY-MM-DD') ||start_time > sEnd And  to_char(end_date, 'YYYY-MM-DD') ||end_time <= sEnd)
			           OR (to_char(start_date, 'YYYY-MM-DD') ||start_time = sStart And  to_char(end_date, 'YYYY-MM-DD')||end_time = sEnd))
			           ) OR
			           (start_date <> start_date_tmp AND
		              (((sStart >=  to_char(start_date_tmp, 'YYYY-MM-DD') ||start_time and sStart <  to_char(end_date, 'YYYY-MM-DD')||end_time)
                  OR (sEnd  >  to_char(start_date_tmp, 'YYYY-MM-DD') ||start_time and sEnd <=  to_char(end_date, 'YYYY-MM-DD')||end_time ))
      		        OR (to_char(start_date_tmp, 'YYYY-MM-DD') ||start_time >= sStart And  to_char(end_date, 'YYYY-MM-DD') ||end_time < sStart)
                  OR (to_char(start_date_tmp, 'YYYY-MM-DD') ||start_time > sEnd And  to_char(end_date, 'YYYY-MM-DD') ||end_time <= sEnd)
			            OR (to_char(start_date_tmp, 'YYYY-MM-DD') ||start_time = sStart And  to_char(end_date, 'YYYY-MM-DD')||end_time = sEnd))
			           ))
             AND status in ('U','1','2','Y')
             AND ORG_BY = sOrganType;
        EXCEPTION WHEN no_data_found THEN
          iCnt := 0 ;
        END;

        IF iCnt > 0 THEN
          RtnCode := 1 ;
        END IF;
        
        --判斷是否為更改原資料
        IF iCnt > 0 AND p_posted_startdate<>'N/A' AND  p_posted_starttime<>'N/A' AND p_posted_status<>'N/A' THEN

          BEGIN
            SELECT COUNT(*)
              INTO iCnt
              FROM hra_offrec
             WHERE emp_no    = sEmpNo
               AND item_type = sItemType
               AND start_date_tmp = to_date(p_posted_startdate,'yyyy-mm-dd')
               AND start_time = p_posted_starttime
               AND status = p_posted_status
               AND org_by = SOrganType;

          EXCEPTION WHEN no_data_found THEN
            iCnt := 0 ;
          END;

          IF iCnt >= 1 THEN
            RtnCode := 0 ;
          END IF;
        END IF;

      END IF;

      IF RtnCode = 1 then
        GOTO Continue_ForEach1 ;
      END IF;
      
      ---借休不可申請 OnCall---
      IF sItemType = 'O' AND sOnCall ='Y' THEN
        RtnCode := 7 ;
        GOTO Continue_ForEach1 ;
      END IF;

      ---借休不可申請 超過 24 小時 (工讀生,兼職不必)---
      IF sItemType = 'O' AND  p_emp_no NOT LIKE 'P%' AND p_emp_no NOT LIKE 'S%' THEN
        BEGIN
          SELECT (mon_getadd + mon_addhrs + mon_otmhrs - mon_offhrs + mon_spcotm - mon_cutotm + mon_dutyhrs) +
                 (SELECT NVL(SUM(ATT_VALUE),0) FROM HRA_ATTDTL1 Where EMP_NO = sEmpNo AND ATT_CODE = '204' AND DISABLED = 'N' AND TRN_YM < TO_CHAR(SYSDATE,'YYYY-MM'))
            INTO sOffrest
            FROM hra_attvac_view
	         WHERE (hra_attvac_view.emp_no = sEmpNo)
             AND (hra_attvac_view.sch_ym = TO_CHAR(SYSDATE,'YYYY-MM'));
        EXCEPTION WHEN no_data_found THEN
          iCnt := 0 ;
        END;
        
        sOffrest := sOffrest;

        -- 需包含此次申請的時數 by szuhao 2007.7.16
        --2010-11-24 modify by weichun 因要加上結算後再計算上限 for 需求 2011-05-19關閉
        --select nvl(case when (select hrs_alloffym from hrs_ym where rownum = 1) = '2010-09' then
        -- (select clos_hrs from hra_offclos where clos_ym = '2010-9' and emp_no = sEmpNo) else 0 end,0)
        --  into sOldSumary
        --  from dual;
       
        -- IF  (sOffrest - sOtmhrs) + sOldSumary < -24 THEN
        --2010-02-01 修改調成績核時數由24改為超過9999時不可借休(即不稽核)
        --IF  (sOffrest - sOtmhrs) + sOldSumary < -9999 THEN
        --2014-04-28 修改為無稽休不能借休
        IF  (sOffrest - sOtmhrs) + sOldSumary < 0 THEN 
          RtnCode := 9 ;
          GOTO Continue_ForEach1 ;
        END IF;
      END IF;

      --判斷是否為借休 或 OnCall
      --IF   p_item_type ='O' OR ( p_item_type ='A' AND p_on_call='Y') THEN
      --20190312 by108482 加班費需KEY應出勤日,20190823 by108482 sStart依照人員填入的時間
      --IF p_item_type ='O' OR ( p_item_type ='A' AND p_start_date_tmp <> 'N/A') THEN
      IF p_item_type ='O' OR ( p_item_type ='A' AND p_on_call='Y') THEN
        --sStart := p_start_date_tmp || p_start_time;
        sStart := p_start_date || p_start_time;
      END IF;
      
      RtnCode := 0 ;

      ------------------------- 積休單 -------------------------
      IF sItemType = 'A' THEN
        ---積休不可申請加班----多機構沒差一並判斷
        --20180612 108978 IMP201806109 同日加班申請方式只能同一種申請方式」規則
        BEGIN
          IF p_start_date_tmp <> 'N/A' THEN
            SELECT COUNT(ROWID)
              INTO iCnt
              FROM HRP.HRA_OTMSIGN
             WHERE emp_no = sEmpNo
               AND otm_no LIKE 'OTM%'
               AND STATUS NOT IN ('N') --排除不准
               AND (p_start_date_tmp = to_char(Start_Date_Tmp,'yyyy-mm-dd') OR 
                    (p_end_date = to_char(end_date,'yyyy-mm-dd') AND p_start_date = to_char(start_date,'yyyy-mm-dd')));
          ELSE
            SELECT COUNT(ROWID)
              INTO iCnt
              FROM HRP.HRA_OTMSIGN
             WHERE emp_no = sEmpNo
               AND otm_no LIKE 'OTM%'
               AND STATUS NOT IN ('N') --排除不准
               AND p_end_date = to_char(end_date,'yyyy-mm-dd');
               --AND (p_start_date || p_start_time) BETWEEN (to_char(start_date,'yyyy-mm-dd')|| start_time) AND  (to_char(END_date,'yyyy-mm-dd')||end_time);
          END IF;
        EXCEPTION WHEN no_data_found THEN
          iCnt := 0 ;
        END;

        IF iCnt > 0 THEN
          RtnCode := 10 ;
          GOTO Continue_ForEach1 ;
        END IF;
 
        ---積休申請不可請產假-多機構沒差一並判斷
        BEGIN
          SELECT COUNT(ROWID)
            INTO iCnt
            FROM HRP.HRA_EVCREC
           WHERE emp_no = sEmpNo
             AND (p_start_date || p_start_time) BETWEEN (to_char(start_date,'yyyy-mm-dd')|| start_time) AND (to_char(END_date,'yyyy-mm-dd')||end_time)
             AND STATUS IN ('U','Y')
             AND VAC_TYPE = 'I';
        
        EXCEPTION WHEN no_data_found THEN
          iCnt := 0 ;
        END;

        IF iCnt > 0 THEN
          RtnCode := 14 ;
          GOTO Continue_ForEach1 ;
        END IF;

        --103.09 by sphinx 當日應出勤班時數+當日加班單時數 +該筆積休單時數不可大於12小時
	      BEGIN -- 當日班表應出勤時數
          IF p_start_date_tmp <> 'N/A' THEN
            SELECT WORK_HRS
		          INTO sWorkHrs
		          FROM HRA_CLASSMST
             WHERE CLASS_CODE= Ehrphrafunc_Pkg.f_getClassKind(p_emp_no,TO_DATE(p_start_date_tmp,'YYYY-MM-DD'),SOrganType);
          ELSE
	          SELECT WORK_HRS
		          INTO sWorkHrs
		          FROM HRA_CLASSMST
             WHERE CLASS_CODE= Ehrphrafunc_Pkg.f_getClassKind(p_emp_no,TO_DATE(p_start_date,'YYYY-MM-DD'),SOrganType);
          END IF;
		    EXCEPTION WHEN NO_DATA_FOUND THEN
          sWorkHrs := 0 ;
	      END;

	      --當日積休單時數
        BEGIN
          IF p_start_date_tmp <> 'N/A' THEN
          SELECT SUM(SOTM_HRS)
		        INTO sTotAddHrs
		        FROM HRA_OFFREC
           WHERE TO_CHAR(NVL(Start_Date_Tmp,Start_Date),'yyyy-mm-dd') = p_start_date_tmp
             AND status<>'N'
             AND item_type='A'
             AND emp_no=p_emp_no;
          ELSE
	        SELECT SUM(SOTM_HRS)
		        INTO sTotAddHrs
		        FROM HRA_OFFREC
           WHERE TO_CHAR(NVL(Start_Date_Tmp,start_date),'yyyy-mm-dd') = p_start_date
             AND status<>'N'
             AND item_type='A'
             AND emp_no=p_emp_no;
          END IF;
		    EXCEPTION WHEN NO_DATA_FOUND THEN
          sTotAddHrs := 0 ;
	      END;

	      IF sTotAddHrs IS NULL THEN
	        sTotAddHrs := 0 ;
	      END IF;
     
        -- 20170427 調整 一例一休 休息日:<4 列入4 ,>4 <8 列入8,>8  列入12.  國定假日:>8之後列入
        --20180725 108978 增加ZQ
        BEGIN
  	      SELECT NVL(sum(decode(s_class , 'ZZ',(soneott+soneoss+soneuu),'ZQ',(soneott+soneoss+soneuu),'ZY',(soneott+soneoss+soneuu),sotm_Hrs)),0)
  		      INTO sTotMonAdd  -- 當月積休單總時數(含在途)
    		    FROM (SELECT (SELECT class_code
                            FROM hra_classsch_view
                           WHERE emp_no = HRA_OFFREC.Emp_No
                             AND att_date = to_char(NVL(Start_Date_Tmp,start_date), 'yyyy-mm-dd')) as s_class,                
                         otm_hrs,
                         soneo,
                         soneott,
                         soneoss,
                         sotm_hrs,
                         soneuu
                    FROM HRA_OFFREC
                   --20250219 用應出勤日年月確認加班時數
                   --WHERE TO_CHAR(NVL(Start_Date_Tmp,start_date),'yyyy-mm') = SUBSTR(p_start_date, 1, 7)
                   WHERE TO_CHAR(NVL(Start_Date_Tmp,start_date),'yyyy-mm') = SUBSTR(p_start_date_tmp, 1, 7)
                     AND status <> 'N'
                     AND item_type = 'A'
                     AND emp_no=p_emp_no) tt;
  		  EXCEPTION WHEN NO_DATA_FOUND THEN
          sTotMonAdd := 0 ;
  	    END;  
           
  	    /* 
        BEGIN
    	    SELECT SUM(SOTM_HRS)
    		   INTO  sTotMonAdd  -- 當月積休單總時數(含在途)
    		   FROM HRA_OFFREC
          WHERE TO_CHAR(start_date,'yyyy-mm')=  SUBSTR(p_start_date ,1,7)
            AND status<>'N'
            AND item_type='A'
            AND emp_no=p_emp_no;
    		EXCEPTION WHEN NO_DATA_FOUND THEN
          sTotMonAdd := 0 ;
    	  END;
        */

        BEGIN
    	    SELECT NVL(SUM(OTM_HRS),0)
    		    INTO sOtmsignHrs  -- 當月加班單總時數(含在途)
    		    FROM HRA_OTMSIGN
           --20250219 用應出勤日年月確認加班時數
           --WHERE TO_CHAR(NVL(Start_Date_Tmp,start_date),'yyyy-mm')=  SUBSTR(p_start_date ,1,7)
           WHERE TO_CHAR(NVL(Start_Date_Tmp,start_date),'yyyy-mm')=  SUBSTR(p_start_date_tmp ,1,7)
             AND status<>'N'
             AND otm_flag = 'B'
             AND emp_no=p_emp_no;
    		EXCEPTION WHEN NO_DATA_FOUND THEN
          sOtmsignHrs := 0 ;
    	  END;

	      BEGIN
	        SELECT (mon_getadd + mon_addhrs   + mon_spcotm -  mon_cutotm + mon_dutyhrs )
		        INTO sMonClassAdd --當月排班超時
            FROM hra_attvac_view
           --WHERE hra_attvac_view.sch_ym = SUBSTR(p_start_date ,1,7)
           WHERE hra_attvac_view.sch_ym = SUBSTR(p_start_date_tmp ,1,7)
		         AND hra_attvac_view.emp_no = p_emp_no ;
	      EXCEPTION WHEN NO_DATA_FOUND THEN
          sMonClassAdd := 0 ;
	      END;
     
        --0301開始加班每月不能超過54HR 108978
        IF SYSDATE  >= TO_DATE('20180315','YYYY-MM-DD') THEN
          --IF  ((sOtmhrs+sWorkHrs+sTotAddHrs)> 12) OR (sOtmsignHrs+sTotMonAdd+sMonClassAdd+sOtmhrs>54) THEN
          --20190301 by108482 因改四週排班，排除班表超時工時
          IF ((sOtmhrs+sWorkHrs+sTotAddHrs)> 12) OR (sOtmsignHrs+sTotMonAdd+/*sMonClassAdd+*/sOtmhrs>54) THEN
	          RtnCode := 15 ;
            GOTO Continue_ForEach1 ;
          END IF;
        ELSE
          IF ((sOtmhrs+sWorkHrs+sTotAddHrs)> 12) OR (sTotMonAdd+sMonClassAdd+sOtmhrs>46) THEN
	          RtnCode := 15 ;
            GOTO Continue_ForEach1 ;
          END IF;
        END IF;

        IF (RtnCode = 0 ) THEN 
          --20250219 用應出勤日年月確認加班時數
          --RtnCode := Check3MonthOtmhrs(p_emp_no,p_start_date, p_otm_hrs,SOrganType);
          RtnCode := Check3MonthOtmhrs(p_emp_no,p_start_date_tmp, p_otm_hrs,SOrganType);
          IF (RtnCode = 16 ) THEN
            RtnCode := 16 ;
            GOTO Continue_ForEach1 ;
          END IF; 
        END IF;

        ---判別是否為上班時間積休
        --check 積休開放日

        IF p_end_time ='0000' THEN
          i_end_date := p_start_date;
        ELSE
          i_end_date := p_end_date;
        END IF;

        BEGIN
          SELECT COUNT(ROWID)
            INTO iCnt
            FROM HRP.HR_CODEDTL
           WHERE CODE_TYPE = 'HRA53'
             AND CODE_NAME = p_start_date
             AND CODE_NAME = i_end_date;
        EXCEPTION WHEN no_data_found THEN
            iCnt := 0 ;
        END;

        IF iCnt = 0 THEN
          IF p_start_date_tmp <> 'N/A' THEN
            sClassKind := ehrphrafunc_pkg.f_getClassKind(p_emp_no,to_date(p_start_date_tmp,'YYYY-MM-DD'),SOrganType);
            sLastClassKind := ehrphrafunc_pkg.f_getClassKind(p_emp_no,to_date(p_start_date_tmp,'YYYY-MM-DD')-1,SOrganType);
          ELSE
            sClassKind := ehrphrafunc_pkg.f_getClassKind(p_emp_no,to_date(p_start_date,'YYYY-MM-DD'),SOrganType);
            sLastClassKind := ehrphrafunc_pkg.f_getClassKind(p_emp_no,to_date(p_start_date,'YYYY-MM-DD')-1,SOrganType);
            sNextClassKind := ehrphrafunc_pkg.f_getClassKind(p_emp_no,to_date(p_start_date,'YYYY-MM-DD')+1,SOrganType);
            
            --RN提前上班 20181205 108978
            IF ( p_start_time >='2000' AND p_end_time = '0000' ) THEN
              IF (sNextClassKind = ehrphrafunc_pkg.f_getClassKind(p_emp_no,to_date(p_end_date,'YYYY-MM-DD'),SOrganType)) THEN
                sClassKind := ehrphrafunc_pkg.f_getClassKind(p_emp_no,to_date(p_end_date,'YYYY-MM-DD'),SOrganType);  
              END IF;
            END IF;
          END IF;

          BEGIN
            SELECT COUNT(ROWID)
              INTO iCnt
              FROM HRP.HRA_CLASSDTL
             WHERE CHKIN_WKTM > CASE WHEN CHKOUT_WKTM ='0000' THEN '2400' ELSE CHKOUT_WKTM END
               AND SHIFT_NO <> '4'
               AND CLASS_CODE = sLastClassKind;
          EXCEPTION WHEN no_data_found THEN
            iCnt :=0;
          END;
      
          IF sClassKind ='N/A' THEN
            RtnCode :=8;
            GOTO Continue_ForEach1 ;
          --sClassKind='ZZ'  20161219 新增班別 ZX,ZY
          --20180725 108978 增加ZQ
          ELSIF p_start_date_tmp <> 'N/A' AND sClassKind IN ('ZZ','ZX','ZY','ZQ') THEN
            GOTO Continue_ForEach2 ;
          ELSIF sClassKind IN ('ZZ','ZX','ZY','ZQ') AND iCnt=0 THEN
            GOTO Continue_ForEach2 ;
          ELSE
          --RtnCode :=  ehrphrafunc_pkg.checkClassTime2(p_emp_no,p_start_date,p_start_time,p_end_date,p_end_time,sClassKind,sLastClassKind);
          --by108482 20190109 因checkClassTime2判斷有問題，改用checkclass
          --RtnCode := checkclass(p_emp_no, p_start_date, p_start_time, p_end_date, p_end_time,SOrganType);
          --by108482 20190110 因checkclass判斷有問題，改用checkClassTime
            RtnCode := ehrphrafunc_pkg.checkClassTime(p_emp_no,p_start_date,p_start_time,p_end_date,p_end_time,sClassKind,sLastClassKind);

            IF RtnCode = 1 THEN
              RtnCode := 3; --申請時間不符合班表!!存檔失敗!
              GOTO Continue_ForEach1 ;
            ELSIF (RtnCode IS NULL ) THEN 
              RtnCode := 3 ;
              GOTO Continue_ForEach1 ;
            ELSIF RtnCode = 7 THEN
              RtnCode := 8 ; --您尚未排班!!存檔失敗!
              GOTO Continue_ForEach1 ;
            ELSIF RtnCode = 8 THEN 
              RtnCode := 3 ;
              GOTO Continue_ForEach1 ;
            END IF;
          END IF;
        END IF;
        NULL;
        <<Continue_ForEach2>>
        NULL;

        ------------------------- 加班簽到 -------------------------
        BEGIN
          SELECT COUNT(*)
            INTO iCnt
            FROM hra_otmsign
           WHERE emp_no = sEmpNo
             AND ((sStart BETWEEN to_char(start_date, 'YYYY-MM-DD') || start_time
                              AND to_char(end_date, 'YYYY-MM-DD') || end_time)
             AND  (sEnd   BETWEEN to_char(start_date, 'YYYY-MM-DD') || start_time
                              AND to_char(end_date, 'YYYY-MM-DD') || end_time))
             AND substr(otm_no, 1, 3) = 'OTS';
        EXCEPTION WHEN no_data_found THEN
          iCnt := 0 ;
        END;

        IF iCnt = 0 THEN
          RtnCode := 2 ;     -- 無簽到時間
        ELSE 
          iCheckCard := 'Y'; --iCnt<>0,有加班簽到 20181219 by108482
        END IF;

        ------------------------- 加班簽到 -------------------------

        ------------------------- 一般簽到 -------------------------
        IF RtnCode = 2 THEN
        -------------Check OnCall-----------
          RtnCode := 0;
        IF p_start_date_tmp <> 'N/A' THEN
          sClassKind := ehrphrafunc_pkg.f_getClassKind(p_emp_no,to_date(p_start_date_tmp,'yyyy-mm-dd'),SOrganType);
          BEGIN
            SELECT CHKIN_WKTM, CHKOUT_WKTM
              INTO iChkinWktm, iChkoutWktm
              FROM HRA_CLASSDTL
             WHERE CLASS_CODE = sClassKind
               AND SHIFT_NO = '1';
          EXCEPTION WHEN no_data_found THEN
            iChkinWktm := 0;
            iChkoutWktm := 0;
          END;
          BEGIN
            SELECT COUNT(*)
              INTO iCnt
              FROM hra_cadsign
             WHERE emp_no = p_emp_no
               AND to_char(att_date, 'yyyy-mm-dd') = p_start_date_tmp
               AND sStart >= 
                   (CASE WHEN ICHKINWKTM < ICHKOUTWKTM AND CHKIN_CARD > CHKOUT_CARD THEN
                    TO_CHAR(ATT_DATE - 1, 'yyyy-mm-dd') || CHKIN_CARD ELSE
                    TO_CHAR(ATT_DATE, 'yyyy-mm-dd') || CHKIN_CARD END)
               AND (sEnd BETWEEN
                   (CASE WHEN ICHKINWKTM < ICHKOUTWKTM AND CHKIN_CARD > CHKOUT_CARD THEN
                    TO_CHAR(ATT_DATE - 1, 'yyyy-mm-dd') || CHKIN_CARD ELSE
                    TO_CHAR(ATT_DATE, 'yyyy-mm-dd') || CHKIN_CARD END) AND
                   (CASE WHEN ICHKINWKTM > ICHKOUTWKTM THEN
                    TO_CHAR(ATT_DATE + 1, 'yyyy-mm-dd') || CHKOUT_CARD ELSE
                    TO_CHAR(ATT_DATE, 'yyyy-mm-dd') || CHKOUT_CARD END)) ;
            --20191014 by108482 原寫法僅檢核當天是否有打卡記錄，未檢核申請的時間起迄是否符合打卡的時間
            /*SELECT COUNT(*)
              INTO iCnt
              FROM hra_cadsign
             WHERE emp_no = p_emp_no
               AND to_char(att_date, 'yyyy-mm-dd') = p_start_date_tmp;*/
          EXCEPTION WHEN no_data_found THEN
            iCnt := 0 ;
          END;
          --若查無記錄再次檢核
          --IF iCnt = 0 AND p_start_time > p_end_time THEN by108482 20210820 不卡時間條件
          --20250718 by108482區分RN班和其他跨夜班打卡檢核
          IF iCnt = 0 THEN
            SELECT COUNT(*)
              INTO iCnt
              FROM hra_cadsign
             WHERE emp_no = p_emp_no
               AND to_char(att_date, 'yyyy-mm-dd') = p_start_date_tmp
               AND CHKIN_CARD > CHKOUT_CARD --20230922增 by108482 嚴謹檢核
               AND sStart >= (CASE CLASS_CODE WHEN 'RN' THEN TO_CHAR(ATT_DATE - 1, 'yyyy-mm-dd') || CHKIN_CARD
                              ELSE TO_CHAR(ATT_DATE, 'yyyy-mm-dd') || CHKIN_CARD END)
               AND sEnd <= (CASE CLASS_CODE WHEN 'RN' THEN TO_CHAR(ATT_DATE, 'yyyy-mm-dd') || CHKOUT_CARD
                            ELSE TO_CHAR(ATT_DATE + 1, 'yyyy-mm-dd') || CHKOUT_CARD END);
          END IF;
        ELSE
        --108154 20181207 RN班申請加班費
          sClassKind := ehrphrafunc_pkg.f_getClassKind(p_emp_no,to_date(p_start_date,'yyyy-mm-dd'),SOrganType);
          sNextClassKind := ehrphrafunc_pkg.f_getClassKind(p_emp_no,to_date(p_start_date,'yyyy-mm-dd')+1,SOrganType);
        --108482 20190121 RN班提前或延後加班，start_time都不會是0000，若start_time為0000則需跑else的SQL
          IF ((sClassKind ='RN' OR sNextClassKind='RN') AND p_start_time <> '0000') THEN
            BEGIN
              SELECT COUNT(*)
                INTO iCnt
                FROM hra_cadsign
               WHERE emp_no = p_emp_no
                 AND (sEnd BETWEEN to_char(att_date-1, 'yyyy-mm-dd') || chkin_card AND (to_char(att_date, 'yyyy-mm-dd') || chkout_card))                                           
                 AND (sStart >= to_char(att_date-1, 'yyyy-mm-dd') || chkin_card );
            EXCEPTION WHEN no_data_found THEN
              iCnt := 0 ;
            END;
          ELSE
            BEGIN
              SELECT COUNT(*)
                INTO iCnt
                FROM hra_cadsign
               WHERE emp_no = p_emp_no
                 AND (sEnd BETWEEN to_char(att_date, 'yyyy-mm-dd') || chkin_card  AND CASE WHEN Night_Flag='Y' THEN (to_char(att_date+1, 'yyyy-mm-dd') || chkout_card)
                                                ELSE to_char(att_date, 'yyyy-mm-dd') || chkout_card
                                                END)
                 AND (sStart >= to_char(att_date, 'yyyy-mm-dd') || chkin_card );
            EXCEPTION WHEN no_data_found THEN
              iCnt := 0 ;
            END;
          END IF;
        END IF;
          IF iCnt = 0 THEN
            RtnCode := 2 ;     -- 無簽到時間
            GOTO Continue_ForEach1 ;
          END IF;
        END IF;

        --非加班打卡才檢核一般打卡因公因私 20181219 by108482
        --IF (sStart > '2011-09-010000') THEN
        IF (sStart > '2011-09-010000') AND iCheckCard = 'N' THEN
        IF p_start_date_tmp <> 'N/A' THEN
          BEGIN
            SELECT NVL(CHKIN_REA, 10),
                   NVL(CHKOUT_REA, 20),
                   TO_CHAR(ATT_DATE, 'yyyy-mm-dd') ||
                   (SELECT CHKIN_WKTM
                      FROM HRA_CLASSDTL
                     WHERE CLASS_CODE = HRA_CADSIGN.CLASS_CODE
                       AND SHIFT_NO = HRA_CADSIGN.SHIFT_NO),
                   /*TO_CHAR(ATT_DATE, 'yyyy-mm-dd') ||
                   (SELECT CHKOUT_WKTM
                      FROM HRA_CLASSDTL
                     WHERE CLASS_CODE = HRA_CADSIGN.CLASS_CODE
                       AND SHIFT_NO = HRA_CADSIGN.SHIFT_NO)*/
                   --108482 20190506 跨夜班需調整日期
                   (CASE
                     WHEN (SELECT CHKOUT_WKTM
                             FROM HRA_CLASSDTL
                            WHERE CLASS_CODE = HRA_CADSIGN.CLASS_CODE
                              AND SHIFT_NO = HRA_CADSIGN.SHIFT_NO) <
                          (SELECT CHKIN_WKTM
                             FROM HRA_CLASSDTL
                            WHERE CLASS_CODE = HRA_CADSIGN.CLASS_CODE
                              AND SHIFT_NO = HRA_CADSIGN.SHIFT_NO) THEN
                      TO_CHAR(ATT_DATE + 1, 'yyyy-mm-dd') ||
                      (SELECT CHKOUT_WKTM
                         FROM HRA_CLASSDTL
                        WHERE CLASS_CODE = HRA_CADSIGN.CLASS_CODE
                          AND SHIFT_NO = HRA_CADSIGN.SHIFT_NO)
                     ELSE
                      TO_CHAR(ATT_DATE, 'yyyy-mm-dd') ||
                      (SELECT CHKOUT_WKTM
                         FROM HRA_CLASSDTL
                        WHERE CLASS_CODE = HRA_CADSIGN.CLASS_CODE
                          AND SHIFT_NO = HRA_CADSIGN.SHIFT_NO)
                   END)
              INTO PCHKINREA, PCHKOUTREA, PWKINTM, PWKOUTTM
              FROM HRA_CADSIGN
             WHERE EMP_NO = P_EMP_NO
               AND to_char(att_date, 'yyyy-mm-dd') = p_start_date_tmp
               AND sStart >= 
                   (CASE WHEN ICHKINWKTM < ICHKOUTWKTM AND CHKIN_CARD > CHKOUT_CARD THEN
                    TO_CHAR(ATT_DATE - 1, 'yyyy-mm-dd') || CHKIN_CARD ELSE
                    TO_CHAR(ATT_DATE, 'yyyy-mm-dd') || CHKIN_CARD END)
               AND (sEnd BETWEEN
                   (CASE WHEN ICHKINWKTM < ICHKOUTWKTM AND CHKIN_CARD > CHKOUT_CARD THEN
                    TO_CHAR(ATT_DATE - 1, 'yyyy-mm-dd') || CHKIN_CARD ELSE
                    TO_CHAR(ATT_DATE, 'yyyy-mm-dd') || CHKIN_CARD END) AND
                   (CASE WHEN ICHKINWKTM > ICHKOUTWKTM THEN
                    TO_CHAR(ATT_DATE + 1, 'yyyy-mm-dd') || CHKOUT_CARD ELSE
                    TO_CHAR(ATT_DATE, 'yyyy-mm-dd') || CHKOUT_CARD END)) ;
          EXCEPTION WHEN no_data_found THEN
            pchkinrea := '15';
            pchkoutrea := '25';
            pwkouttm := sStart;
            pwkintm := sEnd;
          END ;
        ELSE
          BEGIN
            --108482 20190125 與檢核是否有打卡記錄的判斷統一
            --IF (sClassKind = 'RN') THEN
            IF ((sClassKind ='RN' OR sNextClassKind='RN') AND p_start_time <> '0000') THEN
              SELECT NVL(CHKIN_REA, 10),
                     NVL(CHKOUT_REA, 20),
                     TO_CHAR(ATT_DATE, 'yyyy-mm-dd') ||
                     (SELECT CHKIN_WKTM
                        FROM HRA_CLASSDTL
                       WHERE CLASS_CODE = HRA_CADSIGN.CLASS_CODE
                         AND SHIFT_NO = HRA_CADSIGN.SHIFT_NO),
                     TO_CHAR(ATT_DATE, 'yyyy-mm-dd') ||
                     (SELECT CHKOUT_WKTM
                        FROM HRA_CLASSDTL
                       WHERE CLASS_CODE = HRA_CADSIGN.CLASS_CODE
                         AND SHIFT_NO = HRA_CADSIGN.SHIFT_NO)
                INTO PCHKINREA, PCHKOUTREA, PWKINTM, PWKOUTTM
                FROM HRA_CADSIGN
               WHERE EMP_NO = P_EMP_NO
                 AND (SEND BETWEEN TO_CHAR(ATT_DATE - 1, 'yyyy-mm-dd') || CHKIN_CARD AND
                     (TO_CHAR(ATT_DATE, 'yyyy-mm-dd') || CHKOUT_CARD))
                 AND (SSTART >= TO_CHAR(ATT_DATE - 1, 'yyyy-mm-dd') || CHKIN_CARD);
            ELSE
              SELECT nvl(chkin_rea,10),nvl(chkout_rea,20),
                     to_char(att_date, 'yyyy-mm-dd') || (select chkin_wktm from hra_classdtl where class_code = hra_cadsign.class_code and shift_no = hra_cadsign.shift_no),
                     case when Night_Flag='Y' OR CLASS_CODE ='JB' then to_char(att_date+1, 'yyyy-mm-dd')
                                                else to_char(att_date, 'yyyy-mm-dd')
                                                end ||
                     (select chkout_wktm from hra_classdtl where class_code = hra_cadsign.class_code and shift_no = hra_cadsign.shift_no)
                INTO pchkinrea,pchkoutrea,pwkintm,pwkouttm
                FROM hra_cadsign
               WHERE emp_no = p_emp_no
                 AND (sEnd BETWEEN to_char(att_date, 'yyyy-mm-dd') || chkin_card  AND  case when Night_Flag='Y' then (to_char(att_date+1, 'yyyy-mm-dd') || chkout_card)
                                                else to_char(att_date, 'yyyy-mm-dd') || chkout_card
                                                end)
                 AND (sStart >= to_char(att_date, 'yyyy-mm-dd') || chkin_card );
            END IF;
          EXCEPTION WHEN no_data_found THEN
            pchkinrea := '15';
            pchkoutrea := '25';
            pwkouttm := sStart;
            pwkintm := sEnd;
          END ;
        END IF;
          --延後加班狀況
          IF (sStart >= pwkouttm AND pchkoutrea < '25') THEN
            RtnCode := 13 ;     -- 非因公務加班不可申請積休
            GOTO Continue_ForEach1 ;
          END IF;
          --提前加班狀況
          IF (sEnd <= pwkintm AND pchkinrea < '15') THEN
            RtnCode := 13 ;     -- 非因公務加班不可申請積休
            GOTO Continue_ForEach1 ;
          END IF;
        END IF;
        

        -------------Check OnCall-----------
        IF  RtnCode = 0 AND sOnCall ='Y' THEN
          RtnCode := checkOncall(p_emp_no, p_start_date, p_start_time, p_end_date, p_start_date_tmp,SOrganType);

          BEGIN
            SELECT COUNT(*)
              INTO iCnt2
              FROM GESD_DORMMST
             WHERE emp_no = p_emp_no
               AND USE_FLAG = 'Y';
          EXCEPTION WHEN no_data_found THEN
            iCnt2 := 0 ;
          END;

          IF iCnt2 > 0 THEN
            RtnCode := 4 ;     -- 住宿不可申請OnCall
            GOTO Continue_ForEach1 ;
          END IF;

          -- IF p_start_date_tmp <> 'N/A' AND p_start_date_tmp <> p_start_date 代表 為跨夜申請
          -- 故 ClassKin 要以 p_start_date_tmp 為基準

          IF p_start_date_tmp <> 'N/A' AND p_start_date_tmp <> p_start_date THEN
            sClassKind := ehrphrafunc_pkg.f_getClassKind(p_emp_no,to_date(p_start_date_tmp,'YYYY-MM-DD'),SOrganType);
          ELSE
            sClassKind := ehrphrafunc_pkg.f_getClassKind(p_emp_no,to_date(p_start_date,'YYYY-MM-DD'),SOrganType);
          END IF;
          BEGIN
dbms_output.put_line(sClassKind);
            IF sClassKind ='N/A' THEN
              RtnCode := 8;     -- 申請OnCall之積休日班別須為on call班
              GOTO Continue_ForEach1 ;
            END IF;

            SELECT (CASE WHEN CHKIN_WKTM < CHKOUT_WKTM THEN ( CASE WHEN p_start_time between CHKIN_WKTM AND CHKOUT_WKTM  THEN 1 ELSE 0 END )
	                      ELSE ( CASE WHEN  (p_start_time between CHKIN_WKTM AND '2400') OR (p_start_time between '0000' AND CHKOUT_WKTM )  THEN 1 ELSE 0 END )END
                   ) AS COUNT
              INTO iCnt2
              FROM HRP.HRA_CLASSDTL
             WHERE SHIFT_NO='4'
               AND CLASS_CODE= sClassKind;
          EXCEPTION WHEN no_data_found THEN
            iCnt2 := 0 ;
          END ;
          
          IF iCnt2 = 0 THEN
            BEGIN
              SELECT COUNT(*) 
                INTO iCnt2
                FROM hr_codedtl
               WHERE code_type = 'HRA79'
                 AND code_no = (SELECT dept_no
                                  FROM hre_empbas
                                 WHERE emp_no = sEmpNo);
            EXCEPTION WHEN no_data_found THEN
              iCnt2 := 0 ;
            END;
          END IF;

          IF iCnt2 = 0 THEN
            RtnCode := 5 ;     -- 申請OnCall之積休日班別須為on call班
            GOTO Continue_ForEach1 ;
          END IF;

          ---如果有上班打卡就驗證
          -- IF p_start_date_tmp <> 'N/A' AND p_start_date_tmp <> p_start_date 代表 為跨夜申請
          -- 以 p_end_date 為基準
          BEGIN
            IF p_start_date_tmp <> 'N/A' AND p_start_date_tmp <> p_start_date THEN
              SELECT COUNT(*)
                INTO iCnt2
                FROM HRA_CADSIGN
               WHERE HRA_CADSIGN.EMP_NO = p_emp_no
                 AND TO_CHAR(HRA_CADSIGN.ATT_DATE,'YYYY-MM-DD') = p_start_date_tmp;
            ELSE
              SELECT COUNT(*)
                INTO iCnt2
                FROM HRA_CADSIGN
               WHERE HRA_CADSIGN.EMP_NO = p_emp_no
                 AND TO_CHAR(HRA_CADSIGN.ATT_DATE,'YYYY-MM-DD') = p_start_date;
            END IF;
          EXCEPTION WHEN no_data_found THEN
            iCnt2 := 0 ;
          END ;

          IF iCnt2 >0 THEN
            BEGIN
            --ON CALL VALIDATE
            -- IF p_start_date_tmp <> 'N/A' AND p_start_date_tmp <> p_start_date 代表 為跨夜申請
            -- 故 ATT_DATE 要加 1 , 並以 p_end_date 為基準
            IF p_start_date_tmp <> 'N/A' AND p_start_date_tmp <> p_start_date THEN
              SELECT (case when (  TO_DATE(  TO_CHAR(MAX(HRA_OTMSIGN.START_DATE),'YYYY-MM-DD')||MAX(HRA_OTMSIGN.START_TIME) ,'YYYY-MM-DD HH24MI') - TO_DATE(  TO_CHAR(MAX(HRA_CADSIGN.ATT_DATE),'YYYY-MM-DD')||MAX(HRA_CADSIGN.CHKOUT_CARD) ,'YYYY-MM-DD HH24MI'))*60*24 > 30 then 0 else 1 end )
                INTO iCnt2
                FROM HRA_OTMSIGN , HRA_CADSIGN
               WHERE HRA_CADSIGN.EMP_NO = HRA_OTMSIGN.EMP_NO
                 AND TO_CHAR(ATT_DATE+1,'YYYY-MM-DD') = TO_CHAR(START_DATE,'YYYY-MM-DD')
                 AND HRA_OTMSIGN.EMP_NO = p_emp_no
                 AND TO_CHAR(HRA_OTMSIGN.START_DATE,'YYYY-MM-DD') = p_end_date;
            ELSE
              SELECT (case when (  NVL(TO_DATE(  TO_CHAR(MAX(HRA_OTMSIGN.START_DATE),'YYYY-MM-DD')||MAX(HRA_OTMSIGN.START_TIME) ,'YYYY-MM-DD HH24MI') - TO_DATE(  TO_CHAR(MAX(HRA_CADSIGN.ATT_DATE),'YYYY-MM-DD')||MAX(HRA_CADSIGN.CHKOUT_CARD) ,'YYYY-MM-DD HH24MI'),0))*60*24 > 30 then 0 else 1 end )
                INTO iCnt2
                FROM HRA_OTMSIGN , HRA_CADSIGN
               WHERE HRA_CADSIGN.EMP_NO = HRA_OTMSIGN.EMP_NO
                 AND TO_CHAR(ATT_DATE,'YYYY-MM-DD') = TO_CHAR(START_DATE,'YYYY-MM-DD')
                 AND HRA_OTMSIGN.EMP_NO = p_emp_no
                 AND TO_CHAR(HRA_OTMSIGN.START_DATE,'YYYY-MM-DD') = p_start_date;
            END IF;
            EXCEPTION WHEN no_data_found THEN
              iCnt2 := 0 ;
            END;

            IF iCnt2 = 0 THEN
              RtnCode := 0 ;
              GOTO Continue_ForEach1 ;
            ELSE
              RtnCode := 6 ;     -- 申請OnCall失敗
              GOTO Continue_ForEach1 ;
            END IF;
          END IF;
        END IF;
      END IF;
      
      ------------------------- 補休單 -------------------------

      NULL;
      <<Continue_ForEach1>>
      NULL;

  END hraC030;
  
  PROCEDURE hraC030_add(p_emp_no         VARCHAR2,
                        p_start_date     VARCHAR2,
                        p_start_date_tmp VARCHAR2,
                        p_otm_hrs        VARCHAR2,
                        OrganType_IN     VARCHAR2,
                        RtnCode          OUT NUMBER) IS
  
  sClassCode   VARCHAR2(3); --當日班別
  sWorkHrs     NUMBER; --當日班別時數
	sTotAddHrs   NUMBER; --當日在途加班費申請時數
	sTotMonAdd   NUMBER; --當月加班費總時數(含在途)
	sOtmsignHrs  NUMBER; --當月加班補休總時數(含在途)
  sOtmhrs      NUMBER := TO_NUMBER(p_otm_hrs);
  
  BEGIN
    RtnCode     := 0;
    sWorkHrs    := 0;
    sTotAddHrs  := 0;
    sTotMonAdd  := 0;
    sOtmsignHrs := 0;
    
    sClassCode := Ehrphrafunc_Pkg.f_getClassKind(p_emp_no,TO_DATE(NVL(p_start_date_tmp, p_start_date),'YYYY-MM-DD'),OrganType_IN);
    
    BEGIN --當日班別時數
      SELECT WORK_HRS
		    INTO sWorkHrs
		    FROM HRA_CLASSMST
       WHERE CLASS_CODE = sClassCode;
		EXCEPTION WHEN NO_DATA_FOUND THEN
      sWorkHrs := 0 ;
	  END;
    
    BEGIN --當日在途加班費申請時數
      SELECT SUM(SOTM_HRS)
		    INTO sTotAddHrs
		    FROM HRA_OFFREC
       WHERE TO_CHAR(NVL(Start_Date_Tmp,Start_Date),'yyyy-mm-dd') = NVL(p_start_date_tmp, p_start_date)
         AND status <> 'N'
         AND item_type = 'A'
         AND emp_no = p_emp_no;
		EXCEPTION WHEN NO_DATA_FOUND THEN
      sTotAddHrs := 0 ;
	  END;
    
    IF sOtmhrs IS NULL THEN sOtmhrs := 0; END IF;
    IF sWorkHrs IS NULL THEN sWorkHrs := 0; END IF;
    IF sTotAddHrs IS NULL THEN sTotAddHrs := 0; END IF;
    
    IF (sOtmhrs + sWorkHrs + sTotAddHrs)> 12 THEN
      RtnCode := 1;
      GOTO Continue_ForEach1;
    END IF;
  
    BEGIN
  	  SELECT NVL(sum(decode(s_class , 'ZZ',(soneott+soneoss+soneuu),
                                      'ZQ',(soneott+soneoss+soneuu),
                                      'ZY',(soneott+soneoss+soneuu),
                                      sotm_Hrs)),0)
  		  INTO sTotMonAdd  -- 當月加班費總時數(含在途)
    	  FROM (SELECT (SELECT class_code
                        FROM hra_classsch_view
                       WHERE emp_no = HRA_OFFREC.Emp_No
                         AND att_date = to_char(start_date, 'yyyy-mm-dd')) as s_class,                
                     otm_hrs,
                     soneo,
                     soneott,
                     soneoss,
                     sotm_hrs,
                     soneuu
                FROM HRA_OFFREC
               WHERE TO_CHAR(NVL(Start_Date_Tmp,start_date),'yyyy-mm') = 
                     SUBSTR(NVL(p_start_date_tmp, p_start_date), 1, 7)
                 AND status <> 'N'
                 AND item_type = 'A'
                 AND emp_no = p_emp_no) tt;
    EXCEPTION WHEN NO_DATA_FOUND THEN
      sTotMonAdd := 0 ;
  	END;
    
    BEGIN
    	SELECT NVL(SUM(OTM_HRS),0)
    	  INTO sOtmsignHrs  -- 當月加班補休總時數(含在途)
    	  FROM HRA_OTMSIGN
       WHERE TO_CHAR(NVL(Start_Date_Tmp,start_date),'yyyy-mm') = 
             SUBSTR(NVL(p_start_date_tmp, p_start_date), 1, 7)
         AND status <> 'N'
         AND otm_flag = 'B'
         AND emp_no = p_emp_no;
    EXCEPTION WHEN NO_DATA_FOUND THEN
      sOtmsignHrs := 0 ;
    END;
    
    IF sTotMonAdd IS NULL THEN sTotMonAdd := 0; END IF;
    IF sOtmsignHrs IS NULL THEN sOtmsignHrs := 0; END IF;
    IF (sOtmhrs + sTotMonAdd + sOtmsignHrs) > 54 THEN
      RtnCode := 2;
      GOTO Continue_ForEach1;
    END IF;
    
    RtnCode := Check3MonthOtmhrs(p_emp_no, NVL(p_start_date_tmp,p_start_date), p_otm_hrs, OrganType_IN);
    IF RtnCode = 16 THEN
      RtnCode := 3;
      GOTO Continue_ForEach1;
    END IF;
    
    NULL;
    <<Continue_ForEach1>>
    NULL;
  END hraC030_add;

/*
*  忘打卡 檢核 
*  非加班
*/
  PROCEDURE hraC040_old(p_emp_no      VARCHAR2,
                    p_uncard_date VARCHAR2,
                    p_uncard_time VARCHAR2,
                    OrganType_IN  VARCHAR2,
                    RtnCode       OUT NUMBER) IS

    sEmpNo        VARCHAR2(10)   := p_emp_no;
    sUnCardDate   VARCHAR2(20) := p_uncard_date;
    sUnCardTime   VARCHAR2(20) := p_uncard_time;
    SOrganType VARCHAR2(10) := OrganType_IN;
    iClasTime_IN     VARCHAR2(4);
    iClasTime_OUT    VARCHAR2(4);
    sclassCode       VARCHAR2(4);
    sSHIFT_NO        VARCHAR2(2);

    iCnt        INTEGER;
    iconti      BOOLEAN;
    iCheck      INTEGER;

  BEGIN
    RtnCode := 0 ;
    iCnt := 0;
    iconti := true;
    iCheck := 0;
    IF TO_DATE(sUnCardDate,'YYYY-MM-DD') > SYSDATE THEN
      RtnCode := 2 ;
      iconti := false;
    END IF;

    --2014-02-13 忘打卡鎖七日 by weichun 3/3 open
    --2014-04-29 要求關閉七日限制
  /*  if (iconti) THEN
      IF TRUNC(SYSDATE) >= TO_DATE(sUnCardDate,'YYYY-MM-DD')+7 THEN
         RtnCode := 3 ;
         iconti := false;
      END IF;
    END IF;  */
    
    --2016-11-24 忘打卡鎖14日 by ed102674
     IF (iconti) THEN
      /*IF TRUNC(SYSDATE) >= TO_DATE(sUnCardDate,'YYYY-MM-DD')+14 THEN
         RtnCode := 3 ;
         iconti := false;
      END IF;*/
      --20210113 by108482 申請不卡14天申請期限,超過五天才申請違規記點
      --20210204 by108482 每月申請最多至隔月5號(5號當天可以申請)
      IF trunc(SYSDATE) > trunc(ADD_MONTHS(TO_DATE(sUnCardDate, 'yyyy/mm/dd'), 1), 'mm') +4 THEN
      --IF SYSDATE > trunc(ADD_MONTHS(TO_DATE(sUnCardDate, 'yyyy/mm/dd'), 1), 'mm') + 2 + 13.5 / 24 THEN --20211202 因考核結算,11月份申請期限至12/3 13:30止
      --IF trunc(SYSDATE) > trunc(ADD_MONTHS(TO_DATE(sUnCardDate, 'yyyy/mm/dd'), 1), 'mm') +7 THEN --20220406 因4月份國定連假,延長3月份出勤申請期限至8號
         RtnCode := 3 ;
         iconti := false;
      END IF;
    END IF;
    
    /*IF (iconti) THEN
      SELECT COUNT(*)
        INTO iCheck
        FROM hra_uncard
       WHERE to_char(hra_uncard.class_date,'yyyy-mm-dd') = sUnCardDate
         AND hra_uncard.uncard_time = sUnCardTime;
      IF iCheck <> 0 THEN
        RtnCode := 4;
        iconti := FALSE;
      END IF;
    END IF;*/

    IF (iconti) THEN

    sclassCode := ehrphrafunc_pkg.f_getClassKind (sEmpNo , to_date(sUnCardDate,'yyyy-mm-dd'),SOrganType);

    IF sUnCardTime = 'A1' OR sUnCardTime = 'A2' THEN
    sSHIFT_NO :=1;
    ELSIF sUnCardTime = 'B1' OR sUnCardTime = 'B2' THEN
    sSHIFT_NO :=2;
    ELSIF sUnCardTime = 'C1' OR sUnCardTime = 'C2' THEN
    sSHIFT_NO :=3;
    END IF;

    BEGIN
     SELECT CHKIN_WKTM, CHKOUT_WKTM
      INTO iClasTime_IN , iClasTime_OUT
      FROM HRP.HRA_CLASSDTL
     WHERE CLASS_CODE = sclassCode
       AND SHIFT_NO = sSHIFT_NO ;

    EXCEPTION WHEN no_data_found THEN
      iCnt := 1 ;
    END ;

     IF iCnt = 0 THEN
     sSHIFT_NO := SUBSTR(sUnCardTime,2,1);

     IF sSHIFT_NO = 1 THEN

        IF TO_DATE(sUnCardDate||iClasTime_IN,'YYYY-MM-DDHH24MI') > SYSDATE THEN
        RtnCode := 2 ;
        --iconti := false;
        END IF;

     ELSIF sSHIFT_NO = 2 THEN

        IF TO_DATE(sUnCardDate||iClasTime_OUT,'YYYY-MM-DDHH24MI') > SYSDATE THEN
        RtnCode := 2 ;
        --iconti := false;
        END IF;

     END IF;


    END IF;

    END IF;

  END hraC040_old;
  
/*
*  忘打卡 檢核 
*  非加班
*/
  PROCEDURE hraC040(p_emp_no      VARCHAR2,
                    p_uncard_date VARCHAR2,
                    p_uncard_time VARCHAR2,
                    p_uncard_poin VARCHAR2,
                    p_uncard_rea  VARCHAR2,
                    OrganType_IN  VARCHAR2,
                    RtnCode       OUT NUMBER) IS

    sEmpNo        VARCHAR2(10) := p_emp_no;
    sUnCardDate   VARCHAR2(20) := p_uncard_date;
    sUnCardTime   VARCHAR2(20) := p_uncard_time;
    sUnCardPoin   VARCHAR2(10) := p_uncard_poin;
    sUnCardRea    VARCHAR2(10) := p_uncard_rea;
    SOrganType    VARCHAR2(10) := OrganType_IN;
    iClasTime_IN  VARCHAR2(4);
    iClasTime_OUT VARCHAR2(4);
    sclassCode    VARCHAR2(4);
    sSHIFT_NO     VARCHAR2(2);
    LimitDay      VARCHAR2(2);

    iCnt   INTEGER;
    iconti BOOLEAN;
    iCheck INTEGER;
    nNum   NUMBER;
    nNumMin NUMBER;
    nNumHrs NUMBER;

  BEGIN
    RtnCode := 0;
    iCnt := 0;
    iconti := TRUE;
    iCheck := 0;
    IF TO_DATE(sUnCardDate,'YYYY-MM-DD') > SYSDATE THEN
      RtnCode := 2;
      iconti := FALSE;
    END IF;
    --搭配應出勤時段檢查在取班別之後處理
    
    IF sUnCardPoin = '2400' THEN
      RtnCode := 9;
      iconti := FALSE;
    END IF;
    
    IF (iconti) THEN
      --20210113 by108482 申請不卡14天申請期限,超過五天才申請違規記點
      --20210204 by108482 每月申請最多至隔月5號(5號當天可以申請)
      --20241007 by108482 每月申請最多至隔月幾號抓參數HRA89的設定
      BEGIN
        SELECT CODE_NAME
          INTO LimitDay
          FROM HR_CODEDTL
         WHERE CODE_TYPE = 'HRA89'
           AND CODE_NO = 'DAY';
      EXCEPTION WHEN OTHERS THEN
        LimitDay := '5';
      END;
      /*IF trunc(SYSDATE) > trunc(ADD_MONTHS(TO_DATE(sUnCardDate, 'yyyy/mm/dd'), 1), 'mm') +9 THEN
         RtnCode := 3;
         iconti := FALSE;
      END IF;*/
      IF trunc(SYSDATE) > 
         to_date(to_char(ADD_MONTHS(TO_DATE(sUnCardDate, 'yyyy/mm/dd'), 1),'YYYY-MM')||'-'||LimitDay, 'yyyy/mm/dd') THEN
        RtnCode := 3;
        iconti := FALSE;
      END IF;
    END IF;
    
    IF (iconti) THEN
      SELECT COUNT(*) 
        INTO iCheck
        FROM HRA_UNCARD
       WHERE Emp_No = p_emp_no
         AND Class_Date = to_date(p_uncard_date,'yyyy/mm/dd')
         AND Uncard_Time = p_uncard_time;
      IF iCheck <> 0 THEN
        RtnCode := 4;
        iconti := FALSE;
      END IF;
    END IF;

    IF (iconti) THEN

      sclassCode := ehrphrafunc_pkg.f_getClassKind (sEmpNo , to_date(sUnCardDate,'yyyy-mm-dd'),SOrganType);

      IF sUnCardTime = 'A1' OR sUnCardTime = 'A2' THEN
        sSHIFT_NO := 1;
      ELSIF sUnCardTime = 'B1' OR sUnCardTime = 'B2' THEN
        sSHIFT_NO := 2;
      ELSIF sUnCardTime = 'C1' OR sUnCardTime = 'C2' THEN
        sSHIFT_NO := 3;
      END IF;

      BEGIN
       SELECT CHKIN_WKTM, CHKOUT_WKTM
        INTO iClasTime_IN , iClasTime_OUT
        FROM HRP.HRA_CLASSDTL
       WHERE CLASS_CODE = sclassCode
         AND SHIFT_NO = sSHIFT_NO ;

      EXCEPTION WHEN no_data_found THEN
        iCnt := 1;
      END ;
      
      --20250728 by108482 確認系統日時間是否已過應班時間
      IF iCnt = 0 THEN
        IF iClasTime_OUT < iClasTime_IN THEN --應下班小於應上班(下班日期為應班日隔天)
          IF sUnCardTime IN ('A1','B1','C1') THEN --上班未打卡
            IF TO_DATE(sUnCardDate||iClasTime_IN, 'yyyy/mm/ddHH24MI') > SYSDATE THEN
              RtnCode := 2;
              iconti := FALSE;
            END IF;
          ELSE --下班未打卡(下班日期為應班日隔天)
            IF TO_DATE(sUnCardDate||iClasTime_OUT, 'yyyy/mm/ddHH24MI')+1 > SYSDATE THEN
              RtnCode := 2;
              iconti := FALSE;
            END IF;
          END IF;
        ELSE --上下班日期皆為應班日當天
          IF sUnCardTime IN ('A1','B1','C1') THEN --上班未打卡
            IF TO_DATE(sUnCardDate||iClasTime_IN, 'yyyy/mm/ddHH24MI') > SYSDATE THEN
              RtnCode := 2;
              iconti := FALSE;
            END IF;
          ELSE
            IF TO_DATE(sUnCardDate||iClasTime_OUT, 'yyyy/mm/ddHH24MI') > SYSDATE THEN
              RtnCode := 2;
              iconti := FALSE;
            END IF;
          END IF;
        END IF;
      END IF;

      IF iCnt = 0 THEN
        sSHIFT_NO := SUBSTR(sUnCardTime,2,1);

        IF sSHIFT_NO = 1 THEN
          IF sUnCardPoin IS NULL THEN
            sUnCardPoin := iClasTime_IN;
          ELSE
            IF sUnCardPoin = iClasTime_OUT THEN
              RtnCode := 7;
              iconti := FALSE;
            END IF;
          END IF; 
          IF TO_DATE(sUnCardDate||iClasTime_IN,'YYYY-MM-DDHH24MI') > SYSDATE THEN
            RtnCode := 2;
            iconti := FALSE;
          ELSIF sclassCode <> 'RN' AND TO_DATE(sUnCardDate||sUnCardPoin,'YYYY-MM-DDHH24MI') > SYSDATE THEN
            RtnCode := 2;
            iconti := FALSE;
          ELSIF sclassCode = 'RN' AND sUnCardPoin <> iClasTime_IN AND TO_DATE(sUnCardDate||sUnCardPoin,'YYYY-MM-DDHH24MI')-1 > SYSDATE THEN
            RtnCode := 2;
            iconti := FALSE;
          ELSE
            --確認上班打卡時間是否早於應出勤時間超過0.5小時
            --20250704 by108482 確認上班打卡時間是否早於應出勤時間1分鐘
            nNum := TO_DATE(sUnCardDate||iClasTime_IN,'YYYY-MM-DDHH24MI') - TO_DATE(sUnCardDate||sUnCardPoin,'YYYY-MM-DDHH24MI');
            IF nNum > 0 THEN
              nNumHrs := FLOOR((nNum*24*60)/30) * 0.5;
              nNumMin := ROUND(nNum*24*60);
              --IF nNumHrs >= 0.5 AND sUnCardRea IS NULL THEN
              IF nNumMin >= 1 AND sUnCardRea IS NULL THEN
                RtnCode := 5;
                iconti := FALSE;
              END IF;
              --提前超過5小時打卡無法存檔成功
              IF nNumHrs >= 5 THEN
                RtnCode := 6;
                iconti := FALSE;
              END IF;
            END IF;
          END IF;
        ELSIF sSHIFT_NO = 2 THEN
          IF sUnCardPoin IS NULL THEN
            sUnCardPoin := iClasTime_OUT;
          ELSE
            IF sUnCardPoin = iClasTime_IN THEN
              RtnCode := 8;
              iconti := FALSE;
            END IF;
          END IF;
          IF TO_DATE(sUnCardDate||iClasTime_OUT,'YYYY-MM-DDHH24MI') > SYSDATE THEN
            RtnCode := 2;
            iconti := FALSE;
          ELSIF TO_DATE(sUnCardDate||sUnCardPoin,'YYYY-MM-DDHH24MI') > SYSDATE THEN
            RtnCode := 2;
            iconti := FALSE;
          ELSE
            --確認JB班是否提早下班,提早下班不用判斷時差
            IF iClasTime_OUT = '0000' AND substr(sUnCardPoin,1,1) <> '0' THEN
              nNum := 0;
            ELSE
              --確認下班打卡時間是否晚於應出勤時間超過0.5小時
              --20250704 by108482 確認下班打卡時間是否晚於應出勤時間1分鐘
              IF substr(iClasTime_OUT,1,1) = '0' AND substr(sUnCardPoin,1,1) = '2' THEN
                nNum := TO_DATE(sUnCardDate||sUnCardPoin,'YYYY-MM-DDHH24MI') - (TO_DATE(sUnCardDate||iClasTime_OUT,'YYYY-MM-DDHH24MI')+1);
              ELSIF substr(iClasTime_OUT,1,1) = '0' AND substr(sUnCardPoin,1,1) <> '2' THEN
                nNum := (TO_DATE(sUnCardDate||sUnCardPoin,'YYYY-MM-DDHH24MI')+1) - (TO_DATE(sUnCardDate||iClasTime_OUT,'YYYY-MM-DDHH24MI')+1);
              ELSE
                nNum := TO_DATE(sUnCardDate||sUnCardPoin,'YYYY-MM-DDHH24MI') - TO_DATE(sUnCardDate||iClasTime_OUT,'YYYY-MM-DDHH24MI');
              END IF;
            END IF;
            IF nNum > 0 THEN
              nNumHrs := FLOOR((nNum*24*60)/30) * 0.5;
              nNumMin := ROUND(nNum*24*60);
              --IF nNumHrs >= 0.5 AND sUnCardRea IS NULL THEN
              IF nNumMin >= 1 AND sUnCardRea IS NULL THEN
                RtnCode := 5;
                iconti := FALSE;
              END IF;
              --延後超過5小時打卡無法存檔成功
              IF nNumHrs >= 5 THEN
                RtnCode := 6;
                iconti := FALSE;
              END IF;
            END IF;
          END IF;
        END IF;
        
      END IF;
    END IF;

  END hraC040;

/*
*  忘打卡 檢核 
*  加班
*/
  PROCEDURE hraC041(p_emp_no      VARCHAR2,
                    p_uncard_date VARCHAR2,
                    p_uncard_time VARCHAR2,
                    p_check_poin  VARCHAR2,
                    p_night_flag  VARCHAR2,
                    OrganType_IN  VARCHAR2,
                    RtnCode       OUT NUMBER) IS
                    
    sEmpNo      VARCHAR2(10) := p_emp_no;
    sUnCardDate VARCHAR2(20) := p_uncard_date;
    sUnCardTime VARCHAR2(4)  := p_uncard_time;
    sCheckPoin  VARCHAR2(10) := p_check_poin;
    sNightFlag  VARCHAR2(1)  := p_night_flag;
    SOrganType  VARCHAR2(10) := OrganType_IN;
    sUnCardType VARCHAR2(1)  := substr(p_uncard_time,2,1);
    dSignDateT  DATE := TO_DATE(p_uncard_date||p_check_poin, 'YYYY-MM-DDHH24:MI');
    
    sClassCode  VARCHAR2(4);
    dSchDate    DATE;
    iCnt        NUMBER;
    iCnt2       NUMBER;
    dStartDate  DATE;
    LimitDay    VARCHAR2(2);
    
  BEGIN
    RtnCode := 0 ;
    IF TO_DATE(sUnCardDate,'YYYY-MM-DD') > SYSDATE THEN
      RtnCode := 2 ;
      GOTO Continue_ForEach;
    END IF;
    
    IF TO_DATE(sUnCardDate||sCheckPoin,'YYYY-MM-DDHH24MI') > SYSDATE THEN
      RtnCode := 2 ;
      GOTO Continue_ForEach;
    END IF;
    
    --每月申請最多至隔月5號(5號當天可以申請)
    --20241007 by108482 每月申請最多至隔月幾號抓參數HRA89的設定
    BEGIN
      SELECT CODE_NAME
        INTO LimitDay
        FROM HR_CODEDTL
       WHERE CODE_TYPE = 'HRA89'
         AND CODE_NO = 'DAY';
    EXCEPTION WHEN OTHERS THEN
      LimitDay := '5';
    END;
    /*IF trunc(SYSDATE) > trunc(ADD_MONTHS(TO_DATE(sUnCardDate, 'yyyy/mm/dd'), 1), 'mm') +9 THEN
      RtnCode := 3 ;
      GOTO Continue_ForEach;
    END IF;*/
    IF trunc(SYSDATE) > 
       to_date(to_char(ADD_MONTHS(TO_DATE(sUnCardDate, 'yyyy/mm/dd'), 1),'YYYY-MM')||'-'||LimitDay, 'yyyy/mm/dd') THEN
      RtnCode := 3 ;
      GOTO Continue_ForEach;
    END IF;
    
    IF sUnCardType = '1' AND sNightFlag = 'Y' THEN
    --加班上班卡且隔夜註記,代表應出勤日為打卡時間的隔天
      dSchDate := to_date(sUnCardDate,'yyyy-mm-dd')+1;
    ELSIF sUnCardType = '2' AND sNightFlag = 'Y' THEN
    --加班下班卡且隔夜註記,代表應出勤日為打卡時間的前一天
      dSchDate := to_date(sUnCardDate,'yyyy-mm-dd')-1;
    ELSE
      dSchDate := to_date(sUnCardDate,'yyyy-mm-dd');
    END IF;
    sClassCode := ehrphrafunc_pkg.f_getClassKind(sEmpNo, dSchDate, SOrganType);
    IF sClassCode = 'ZX' THEN
    --ZX不能出勤加班,應先調班
      RtnCode := 4 ;
      GOTO Continue_ForEach;
    ELSIF sClassCode = 'ZQ' AND substr(sEmpNo,1,1) IN ('S','P') THEN
    --SP人員ZQ不能出勤加班,應先調班
      RtnCode := 5 ;
      GOTO Continue_ForEach;
    /*ELSIF sClassCode NOT IN ('ZZ','ZY','ZQ') THEN
      RtnCode := ;
      GOTO Continue_ForEach;*/
    END IF;
    
    SELECT COUNT(*)
      INTO iCnt
      FROM HRA_OTMSIGN
     WHERE EMP_NO = sEmpNo
       AND ORG_BY = sOrganType
       AND (TO_CHAR(START_DATE, 'YYYY-MM-DD') = TO_CHAR(dSchDate, 'YYYY-MM-DD') OR 
            TO_CHAR(START_DATE, 'YYYY-MM-DD') = TO_CHAR(dSchDate-1, 'YYYY-MM-DD'))
       AND END_DATE IS NULL
       AND OTM_NO LIKE 'OTS%';
    
    SELECT COUNT(*)
      INTO iCnt2
      FROM HRA_OTMSIGN
     WHERE EMP_NO = sEmpNo
       AND ORG_BY = sOrganType
       AND TO_CHAR(START_DATE, 'YYYY-MM-DD') = TO_CHAR(dSchDate, 'YYYY-MM-DD')
       AND END_DATE IS NOT NULL
       AND OTM_NO LIKE 'OTS%'
       AND FLOOR(((TO_DATE(sUnCardDate || sCheckPoin, 'YYYY-MM-DDHH24:MI') -
                 TO_DATE(TO_CHAR(START_DATE, 'yyyy-mm-dd') || START_TIME, 'YYYY-MM-DDHH24:MI')) * 24 * 60) / 30) * 0.5 > 0;
         
    IF sUnCardType = '2' THEN
      IF iCnt = 0 THEN
        IF iCnt2 = 0 THEN 
        --補加班下班但無上班記錄,應先補加班上班記錄
          RtnCode := 6 ;
          GOTO Continue_ForEach;
        ELSIF iCnt2 <> 1 THEN
          RtnCode := 6 ;
          GOTO Continue_ForEach;
        END IF;
      ELSIF iCnt > 1 THEN
      --補加班下班但多筆上班記錄,先請人資確認加班打卡資料,整理後再重新申請
        RtnCode := 7 ;
        GOTO Continue_ForEach;
      ELSE
        SELECT TO_DATE(TO_CHAR(START_DATE,'yyyy-mm-dd')||START_TIME, 'YYYY-MM-DDHH24:MI')
          INTO dStartDate
          FROM HRA_OTMSIGN
         WHERE EMP_NO = sEmpNo
           AND ORG_BY = sOrganType
           AND (TO_CHAR(START_DATE, 'YYYY-MM-DD') = TO_CHAR(dSchDate, 'YYYY-MM-DD') OR 
                TO_CHAR(START_DATE, 'YYYY-MM-DD') = TO_CHAR(dSchDate-1, 'YYYY-MM-DD'))
           AND END_DATE IS NULL
           AND OTM_NO LIKE 'OTS%';
        IF dSignDateT <= dStartDate THEN
          --下班卡的時間小於上班卡時間,請人員確認填寫的資料
          RtnCode := 8 ;
          GOTO Continue_ForEach;
        END IF;
      END IF;
    ELSIF sUnCardType = '1' THEN
      IF iCnt = 1 THEN
      --新增加班上班但尚有加班打卡資料不完整,應先補加班下班記錄
        RtnCode := 9 ;
        GOTO Continue_ForEach;
      ELSIF iCnt > 1 THEN
      --補加班下班但多筆上班記錄,先請人資確認加班打卡資料,整理後再重新申請
        RtnCode := 7 ;
        GOTO Continue_ForEach;
      END IF;
    END IF;
    
    /*SELECT COUNT(*)
      INTO 
      FROM HRA_OTMSIGN
     WHERE EMP_NO = SEMPNO
       AND ORG_BY = SORGANTYPE
       AND (TO_CHAR(START_DATE, 'YYYY-MM-DD') = TO_CHAR(DSCHDATE, 'YYYY-MM-DD') OR
            TO_CHAR(START_DATE, 'YYYY-MM-DD') = TO_CHAR(DSCHDATE - 1, 'YYYY-MM-DD'))
       AND END_DATE IS NOT NULL
       AND OTM_NO LIKE 'OTS%'
       AND 30 > (TO_DATE(TO_CHAR(END_DATE, 'YYYY-MM-DD') || END_TIME, 'YYYY-MM-DDHH24MI') -
                 TO_DATE(TO_CHAR(START_DATE, 'YYYY-MM-DD') || START_TIME, 'YYYY-MM-DDHH24MI')) * 1440;
    
    IF sUnCardType = '1' THEN
      IF iCnt2 > 1 THEN
        --加班完整記錄且相差小於30分鐘的資料有多筆,作業會無法判斷要更新哪一筆加班卡紀錄,請人員與人資聯繫
        RtnCode := 10 ;
        GOTO Continue_ForEach;
      END IF;
    END IF;*/
    
    NULL;
    <<Continue_ForEach>>
    NULL;
    
  END hraC041;
  
  --20200109 by108482 刪除加班換補休時調整Merge值
  PROCEDURE hraC050(EmpNo_In     VARCHAR2,
                    StartDate_In VARCHAR2,
                    Merge_In     VARCHAR2,
                    User_In      VARCHAR2,
                    RtnCode      OUT NUMBER) AS
  iCnt NUMBER;
  
  BEGIN
    SELECT COUNT(*)
      INTO iCnt
      FROM HRA_OTMSIGN
     WHERE EMP_NO = EmpNo_In
       AND TO_CHAR(START_DATE_TMP, 'yyyy-mm-dd') = StartDate_In;
    
    IF iCnt - Merge_In <> 0 THEN
      UPDATE HRA_OTMSIGN
         SET MERGE = MERGE - 1,
             LAST_UPDATE_DATE = SYSDATE,
             LAST_UPDATED_BY = User_In
       WHERE EMP_NO = EmpNo_In
         AND TO_CHAR(START_DATE_TMP, 'yyyy-mm-dd') = StartDate_In 
         AND MERGE > Merge_In;
    END IF;
    COMMIT;
    RtnCode := iCnt;
    
  EXCEPTION WHEN OTHERS THEN
    ROLLBACK WORK;
    RtnCode := SQLCODE;
  END hraC050;
  
  --20200121 by108482 刪除加班換加班費時調整Merge值
  PROCEDURE hraC060(EmpNo_In     VARCHAR2,
                    StartDate_In VARCHAR2,
                    Merge_In     VARCHAR2,
                    User_In      VARCHAR2,
                    RtnCode      OUT NUMBER) AS
  iCnt NUMBER; 
  BEGIN
    SELECT COUNT(*)
      INTO iCnt
      FROM HRA_OFFREC
     WHERE EMP_NO = EmpNo_In
       AND TO_CHAR(START_DATE_TMP, 'yyyy-mm-dd') = StartDate_In;
    
    IF iCnt - Merge_In <> 0 THEN
      UPDATE HRA_OFFREC
         SET MERGE = MERGE - 1,
             LAST_UPDATE_DATE = SYSDATE,
             LAST_UPDATED_BY = User_In
       WHERE EMP_NO = EmpNo_In
         AND TO_CHAR(START_DATE_TMP, 'yyyy-mm-dd') = StartDate_In 
         AND MERGE > Merge_In;
    END IF;
    COMMIT;
    RtnCode := iCnt;

  EXCEPTION WHEN OTHERS THEN
    ROLLBACK WORK;
    RtnCode := SQLCODE;
  END hraC060;
  
  --20200121 by108482 刪除加班換加班費時調整加成分配及加成時數
  PROCEDURE hraC061(EmpNo_In     VARCHAR2,
                    StartDate_In VARCHAR2,
                    User_In      VARCHAR2,
                    RtnCode      OUT NUMBER) AS
  
  iCnt       NUMBER;
  iMerge     VARCHAR2(1);
  iClassCode VARCHAR2(4);
  iSotmHrs   NUMBER;
  iSumHrs    NUMBER;
  iWorkHrs   NUMBER;
  iTotalHrs  NUMBER;
  
  sSONEO   NUMBER;
  sSONEOTT NUMBER;
  sSONEOSS NUMBER;
  sSONEUU  NUMBER;
  
  BEGIN
    RtnCode := 0;
    
    SELECT COUNT(*)
      INTO iCnt
      FROM HRA_OFFREC
     WHERE EMP_NO = EmpNo_In
       AND TO_CHAR(START_DATE_TMP, 'yyyy-mm-dd') = StartDate_In;
    
  IF iCnt > 0 THEN
    SELECT MAX(MERGE)
      INTO iMerge
      FROM HRA_OFFREC
     WHERE EMP_NO = EmpNo_In
       AND TO_CHAR(START_DATE_TMP, 'yyyy-mm-dd') = StartDate_In;

    iSumHrs  := 0;
    FOR I IN 0..TO_NUMBER(iMerge) LOOP
      sSONEO   := 0;
      sSONEOTT := 0;
      sSONEOSS := 0;
      sSONEUU  := 0;
      SELECT CLASS_CODE, SOTM_HRS
        INTO iClassCode, iSotmHrs
        FROM HRA_OFFREC
       WHERE EMP_NO = EmpNo_In
         AND TO_CHAR(START_DATE_TMP, 'yyyy-mm-dd') = StartDate_In
         AND MERGE = TO_CHAR(I);
         
      IF iClassCode = 'ZZ' THEN
        IF iSumHrs+iSotmHrs <= 2 THEN 
          sSONEOTT := iSotmHrs;
        ELSIF iSumHrs+iSotmHrs > 2 AND iSumHrs+iSotmHrs <= 8 THEN
          IF iSumHrs < 2 THEN --前面加班時數尚未滿2小時，則4/3時數還有配額
            sSONEOTT := 2 - iSumHrs;
            sSONEOSS := iSotmHrs - (2 - iSumHrs);
          ELSE --前面加班時數滿2小時，則4/3時數無配額
            sSONEOSS := iSotmHrs;
          END IF;
        ELSIF iSumHrs+iSotmHrs > 8 AND iSumHrs+iSotmHrs <= 12 THEN
          IF iSumHrs < 2 THEN --前面加班時數尚未滿2小時，則4/3時數還有配額
            sSONEOTT := 2 - iSumHrs;
            sSONEOSS := 6;
            sSONEUU := iSotmHrs - 6 - (2 - iSumHrs);
          ELSE --前面加班時數滿2小時，則4/3時數無配額
            IF iSumHrs - 2 < 6 THEN --5/3時數還有配額
              sSONEOSS := 6 - (iSumHrs - 2);
              sSONEUU := iSotmHrs - (6 - (iSumHrs - 2));
            ELSE --5/3時數無配額
              sSONEUU := iSotmHrs;
            END IF;
          END IF;
        END IF;
      ELSIF iClassCode = 'ZY' THEN
        IF substr(EmpNo_In,1,1) IN ('S','P') THEN
          IF iSumHrs = 0 THEN
            IF iSotmHrs <= 8 THEN
              sSONEO := iSotmHrs;
            ELSE
              sSONEO := 8;
              IF iSotmHrs - 8 <= 2 THEN
                sSONEOTT := iSotmHrs - 8;
              ELSE
                sSONEOTT := 2;
                sSONEOSS := iSotmHrs - 10;
              END IF;
            END IF;
          ELSE
            IF iSotmHrs+iSumHrs <= 8 THEN
              sSONEO := iSotmHrs;
            ELSE
              IF iSumHrs > 8 THEN
                IF iSumHrs - 8 < 2 THEN --1:4/3還有配額
                  sSONEOTT := 2 - (iSumHrs - 8);
                  sSONEOSS := iSotmHrs - (2 - (iSumHrs - 8));
                ELSE
                  sSONEOSS := iSotmHrs;
                END IF;
              ELSE --之前申請時數還未超過(或等於)8小時 iSumHrs <= 8，1:1可能還有配額
                sSONEO := 8-iSumHrs;
                IF iSotmHrs - (8-iSumHrs) <= 2 THEN
                  sSONEOTT := iSotmHrs - (8-iSumHrs);
                ELSE
                  sSONEOTT := 2;
                  sSONEOSS := iSotmHrs - (8-iSumHrs) - 2;
                END IF;
              END IF;
            END IF;
          END IF;
        ELSE
          IF iSumHrs = 0 THEN
            IF iSotmHrs <= 8 THEN
              sSONEO := 8;
            ELSE
              sSONEO := 8;
              IF iSotmHrs - 8 <= 2 THEN
                sSONEOTT := iSotmHrs - 8;
              ELSE
                sSONEOTT := 2;
                sSONEOSS := iSotmHrs - 10;
              END IF;
            END IF;
          ELSE
            IF iSotmHrs+iSumHrs <= 8 THEN
              sSONEO := 0;
            ELSE
              IF iSumHrs <= 8 THEN
                IF iSotmHrs - (8-iSumHrs) <= 2 THEN
                  sSONEOTT := iSotmHrs - (8-iSumHrs);
                ELSE
                  sSONEOTT := 2;
                  sSONEOSS := iSotmHrs - (8-iSumHrs) - 2;
                END IF;
              ELSE
                IF iSumHrs - 8 < 2 THEN
                  sSONEOTT := 2 - (iSumHrs - 8);
                  sSONEOSS := iSotmHrs - (2 - (iSumHrs - 8));
                ELSE
                  sSONEOSS := iSotmHrs;
                END IF;
              END IF;
            END IF;
          END IF;
        END IF;
      ELSIF substr(EmpNo_In,1,1) IN ('S','P') THEN --時薪人員需確認出勤班的時數
        SELECT WORK_HRS 
          INTO iWorkHrs
          FROM HRA_CLASSMST
         WHERE CLASS_CODE = iClassCode;
        IF iWorkHrs > 8 THEN iWorkHrs := 8; END IF;
        IF iSumHrs = 0 THEN
          IF iWorkHrs + iSotmHrs <= 8 THEN
            sSONEO := iSotmHrs;
          ELSE
            sSONEO := 8-iWorkHrs;
            IF iSotmHrs - (8 - iWorkHrs) <=2 THEN
              sSONEOTT := iSotmHrs - (8 - iWorkHrs);
            ELSE
              sSONEOTT := 2;
              sSONEOSS := iSotmHrs - (8 - iWorkHrs) -2;
            END IF;
          END IF;
        ELSE
          IF iSotmHrs+iSumHrs+iWorkHrs <= 8 THEN
            sSONEO := iSotmHrs;
          ELSE
            IF iSotmHrs+iWorkHrs < 8 THEN --代表1:1尚有配額
              sSONEO := 8-(iSumHrs+iWorkHrs);
              IF iSotmHrs - (8-(iSumHrs+iWorkHrs)) <=2 THEN
                sSONEOTT := iSotmHrs - (8-(iSumHrs+iWorkHrs));
              ELSE
                sSONEOTT := 2;
                sSONEOSS := iSotmHrs - (8-(iSumHrs+iWorkHrs)) -2;
              END IF;
            ELSIF iSumHrs+iWorkHrs = 8 THEN
              IF iSotmHrs <=2 THEN
                sSONEOTT := iSotmHrs;
              ELSE
                sSONEOTT := 2;
                sSONEOSS := iSotmHrs-2;
              END IF;
            ELSE
              IF iSumHrs+iWorkHrs-8 <2 THEN --代表1:4/3尚有配額
                IF iSotmHrs <= 2-(iSumHrs+iWorkHrs-8) THEN
                  sSONEOTT := iSotmHrs;
                ELSE
                  sSONEOTT := 2-(iSumHrs+iWorkHrs-8);
                  sSONEOSS := iSotmHrs - (2-(iSumHrs+iWorkHrs-8));
                END IF;
              ELSE
                sSONEOSS := iSotmHrs;
              END IF;
            END IF;
          END IF;
        END IF;
      ELSE
        IF iSumHrs+iSotmHrs <= 2 THEN
          sSONEOTT := iSotmHrs;
        ELSIF iSumHrs+iSotmHrs > 2 AND iSumHrs+iSotmHrs <= 12 THEN
          IF iSumHrs < 2 THEN --前面加班時數尚未滿2小時，則4/3時數還有配額
            sSONEOTT := 2 - iSumHrs;
            sSONEOSS := iSotmHrs - (2 - iSumHrs);
          ELSE --前面加班時數滿2小時，則4/3時數無配額
            sSONEOSS := iSotmHrs;
          END IF;
        END IF;
      END IF;
      iSumHrs := iSumHrs+iSotmHrs;
      iTotalHrs := CEIL(((sSONEO*1)+(sSONEOTT*4/3)+(sSONEOSS*5/3)+(sSONEUU*8/3))*1000)/1000;
      UPDATE HRA_OFFREC
         SET OTM_HRS = iTotalHrs,
             SONEO   = sSONEO,
             SONEOTT = sSONEOTT,
             SONEOSS = sSONEOSS,
             SONEUU  = sSONEUU,
             LAST_UPDATED_BY = User_In,
             LAST_UPDATE_DATE = SYSDATE
       WHERE EMP_NO = EmpNo_In
         AND TO_CHAR(START_DATE_TMP, 'yyyy-mm-dd') = StartDate_In
         AND MERGE = TO_CHAR(I);
    END LOOP;
    COMMIT;
  END IF;
    RtnCode := iCnt;
    
  EXCEPTION WHEN OTHERS THEN
    ROLLBACK WORK;
    RtnCode := SQLCODE;
  END hraC061;

/*------------------------------------------
-- 醫師積借修稽核
-- 須修正機構別
------------------------------------------*/

PROCEDURE hraD030(p_item_type        VARCHAR2
                , p_emp_no           VARCHAR2
                , p_start_date       VARCHAR2
                , p_start_time       VARCHAR2
                , p_end_date         VARCHAR2
                , p_end_time         VARCHAR2
                , P_otm_hrs          VARCHAR2
                , OrganType_IN      VARCHAR2
                , RtnCode       OUT NUMBER) IS

    sItemType   hra_offrec.item_type%TYPE   := p_item_type;
    sEmpNo      hra_offrec.emp_no%TYPE      := p_emp_no;
    sStart      VARCHAR2(20) := p_start_date || p_start_time;
    sEnd        VARCHAR2(20) := p_end_date || p_end_time ;
    sStart1     VARCHAR2(20) ;
    sEnd1       VARCHAR2(20) ;
    sOffrest    NUMBER(4,1);
    iLeave      VARCHAR2(10);
    maxHrs      NUMBER(5,1);
    Test1      NUMBER(5,1);
    Test2      NUMBER(5,1);
    Test3      NUMBER(5,1);
    maxHrs_Tmp  NUMBER(5,1);
    iCnt        INTEGER ;
    iComedate   VARCHAR2(10) ;


    BEGIN


       RtnCode := 0 ;

       --因 BETWEEN 會比較前後值,故 START + 1 分鐘 , END -1 分鐘 來跳過
       sStart1 := TO_CHAR(TO_DATE(sStart,'YYYY-MM-DDHH24MI')+0.000695,'YYYY-MM-DDHH24MI');
       sEnd1  := TO_CHAR(TO_DATE(sEnd,'YYYY-MM-DDHH24MI')-0.000694,'YYYY-MM-DDHH24MI');


       ------------------------- 積休單 -------------------------
       --(檢核在資料庫中除''不准''以外的積休單申請時間是否重疊)

       --現有的補休單時間介於新積休單
              BEGIN
          SELECT COUNT(*)
            INTO iCnt
            FROM hra_Doffrec
           WHERE item_type = sItemType
             AND emp_no    = sEmpNo
             AND ((sStart1  between to_char(start_date, 'YYYY-MM-DD') || start_time and to_char(end_date, 'YYYY-MM-DD') || end_time)
              OR  ( sEnd1    between to_char(start_date, 'YYYY-MM-DD') || start_time and to_char(end_date, 'YYYY-MM-DD') || end_time ))
             AND status <> 'N' ;

         EXCEPTION
         WHEN no_data_found THEN
            iCnt := 0 ;
       END;

       IF iCnt = 0 THEN

       --新補休單介於現有的積休單時間
       BEGIN
          SELECT COUNT(*)
            INTO iCnt
            FROM hra_Doffrec
           WHERE item_type = sItemType
             AND emp_no    = sEmpNo
             AND ((to_char(start_date, 'YYYY-MM-DD') || start_time between sStart1 and sEnd1)
              OR  (to_char(end_date, 'YYYY-MM-DD')   || end_time   between sStart1 and sEnd1))
             AND status <> 'N' ;

         EXCEPTION
         WHEN no_data_found THEN
            iCnt := 0 ;
       END;
       END IF;

       IF iCnt > 0 THEN
       RtnCode := 1 ;
       GOTO Continue_ForEach1 ;
       END IF;


       IF sItemType = 'A' THEN
      BEGIN

       SELECT SUM(otm_hrs)
         INTO sOffrest
         FROM hra_doffrec
	      WHERE (emp_no = sEmpNo)
          AND status = 'Y'
          AND disabled ='N'
          AND item_type = 'A'
          AND TO_CHAR(START_DATE,'YYYY')=TO_CHAR(SYSDATE,'YYYY');

         EXCEPTION
         WHEN no_data_found THEN
            sOffrest := 0 ;
       END;


       BEGIN
       SELECT TO_CHAR(COME_DATE,'YYYY-MM-DD') , TO_CHAR(LEAVE_DATE,'YYYY-MM-DD')
         INTO iComedate , iLeave
         FROM HRA_DYEARVAC
	      WHERE (emp_no = sEmpNo)
          AND  VAC_YEAR = TO_CHAR(SYSDATE,'YYYY');

         EXCEPTION
         WHEN no_data_found THEN
            maxHrs := 0 ;
       END;

       IF iLeave IS NULL THEN

       IF ceil(MONTHS_BETWEEN(to_date(p_start_date,'yyyy-mm-dd'),to_date(iComedate,'yyyy-mm-dd'))) >= 12 THEN

        maxHrs := 128; --1

       ELSE

        maxHrs_Tmp := 128 /12 * ceil((MONTHS_BETWEEN(to_date(to_char(sysdate,'yyyy')||'-12-31','yyyy-mm-dd'),to_date(iComedate,'yyyy-mm-dd'))));

          --未滿半日以半日算,滿半日以一日算
         IF maxHrs_Tmp = FLOOR(maxHrs_Tmp) THEN
           maxHrs := maxHrs_Tmp;
           ELSIF maxHrs_Tmp = FLOOR(maxHrs_Tmp)+0.5 THEN
           maxHrs := FLOOR(maxHrs_Tmp)+0.5;
           ELSIF maxHrs_Tmp > FLOOR(maxHrs_Tmp)+0.5 THEN
           maxHrs := FLOOR(maxHrs_Tmp) +1;
         ELSE
           maxHrs := FLOOR(maxHrs_Tmp) +0.5; --2
         END IF;

       END IF;

       ELSE

       IF ceil(MONTHS_BETWEEN(to_date(p_start_date,'yyyy-mm-dd'),to_date(iComedate,'yyyy-mm-dd'))) >= 12 THEN

        maxHrs_Tmp := 128 /12 * to_number(SUBSTR(iLeave, 6, 2));

       ELSE

        maxHrs_Tmp := 128 /12 * ceil((MONTHS_BETWEEN(to_date(iLeave,'yyyy-mm-dd'),to_date(iComedate,'yyyy-mm-dd'))));

       END IF;

          --未滿半日以半日算,滿半日以一日算
         IF maxHrs_Tmp = FLOOR(maxHrs_Tmp) THEN
         maxHrs := maxHrs_Tmp;
         ELSIF maxHrs_Tmp = FLOOR(maxHrs_Tmp)+0.5 THEN
         maxHrs := FLOOR(maxHrs_Tmp)+0.5;
         ELSIF maxHrs_Tmp > FLOOR(maxHrs_Tmp)+0.5 THEN
         maxHrs := FLOOR(maxHrs_Tmp) +1;
         ELSE
         maxHrs := FLOOR(maxHrs_Tmp) +0.5;
         END IF;

       END IF;


       IF  P_otm_hrs + sOffrest > maxHrs THEN
       RtnCode := 2 ;
       GOTO Continue_ForEach1 ;
       END IF;

       END IF;



       NULL;
       <<Continue_ForEach1>>
       NULL;

    END hraD030;

FUNCTION checkOncall(
                  p_emp_no           VARCHAR2
                , p_start_date       VARCHAR2
                , p_start_time       VARCHAR2
                , p_end_date         VARCHAR2
                , p_start_date_tmp   VARCHAR2
                , OrganType_IN       VARCHAR2) RETURN NUMBER IS



    sClassKind  VARCHAR2(3);
    iCnt2       INTEGER ;
    RtnCode     NUMBER(1);
    SOrganType VARCHAR2(10) := OrganType_IN;
    BEGIN

      RtnCode := 0;

         BEGIN
         SELECT count(*)
                INTO iCnt2
                FROM GESD_DORMMST
               WHERE emp_no = p_emp_no
                 AND USE_FLAG = 'Y';

          EXCEPTION
           WHEN no_data_found THEN
                iCnt2 := 0 ;
           END ;

           IF iCnt2 > 0 THEN
              RtnCode := 4 ;     -- 住宿不可申請OnCall
              GOTO Continue_ForEach1 ;
           END IF;

           -- IF p_start_date_tmp <> 'N/A' AND p_start_date_tmp <> p_start_date 代表 為跨夜申請
           -- 故 ClassKin 要以 p_start_date_tmp 為基準

           IF p_start_date_tmp <> 'N/A' AND p_start_date_tmp <> p_start_date THEN
           sClassKind := ehrphrafunc_pkg.f_getClassKind(p_emp_no,to_date(p_start_date_tmp,'YYYY-MM-DD'),SOrganType);
           ELSE
           sClassKind := ehrphrafunc_pkg.f_getClassKind(p_emp_no,to_date(p_start_date,'YYYY-MM-DD'),SOrganType);
           END IF;
           BEGIN

           SELECT (CASE WHEN CHKIN_WKTM < CHKOUT_WKTM THEN ( CASE WHEN p_start_time between CHKIN_WKTM AND CHKOUT_WKTM  THEN 1 ELSE 0 END )

	                      ELSE ( CASE WHEN  (p_start_time between CHKIN_WKTM AND '2400') OR (p_start_time between '0000' AND CHKOUT_WKTM )  THEN 1 ELSE 0 END )END
                   ) AS COUNT
           INTO iCnt2
           FROM HRP.HRA_CLASSDTL
           WHERE SHIFT_NO='4'
             AND CLASS_CODE= sClassKind;

           EXCEPTION
             WHEN no_data_found THEN
                  iCnt2 := 0 ;
           END ;
           
           IF iCnt2 = 0 THEN
            BEGIN
               SELECT COUNT(*) 
                 INTO iCnt2
                 FROM hr_codedtl
                WHERE code_type = 'HRA79'
                  AND code_no = (SELECT dept_no
                                   FROM hre_empbas
                                  WHERE emp_no = p_emp_no)
                  AND disabled='N';
             EXCEPTION WHEN no_data_found THEN
               iCnt2 := 0 ;
             END;
           END IF;

             IF iCnt2 = 0 THEN
                RtnCode := 5 ;     -- 申請OnCall之積休日班別須為on call班
                GOTO Continue_ForEach1 ;
             END IF;

            ---如果有上班打卡就驗證
            -- IF p_start_date_tmp <> 'N/A' AND p_start_date_tmp <> p_start_date 代表 為跨夜申請
            -- 以 p_end_date 為基準
            BEGIN
            IF p_start_date_tmp <> 'N/A' AND p_start_date_tmp <> p_start_date THEN

            SELECT COUNT(*)
            INTO iCnt2
            FROM  HRA_CADSIGN
            Where HRA_CADSIGN.EMP_NO = p_emp_no
              AND TO_CHAR(HRA_CADSIGN.ATT_DATE,'YYYY-MM-DD') = p_start_date_tmp;

            ELSE
            SELECT COUNT(*)
            INTO iCnt2
            FROM  HRA_CADSIGN
            Where HRA_CADSIGN.EMP_NO = p_emp_no
              AND TO_CHAR(HRA_CADSIGN.ATT_DATE,'YYYY-MM-DD') = p_start_date;

            END IF;
            EXCEPTION
            WHEN no_data_found THEN
            iCnt2 := 0 ;
            END ;

            IF iCnt2 >0 THEN

            BEGIN

            -- IF p_start_date_tmp <> 'N/A' AND p_start_date_tmp <> p_start_date 代表 為跨夜申請
            -- 故 ATT_DATE 要加 1 , 並以 p_end_date 為基準

            IF p_start_date_tmp <> 'N/A' AND p_start_date_tmp <> p_start_date THEN

            SELECT (case when (  TO_DATE(  TO_CHAR(MAX(HRA_OTMSIGN.START_DATE),'YYYY-MM-DD')||MAX(HRA_OTMSIGN.START_TIME) ,'YYYY-MM-DD HH24MI') - TO_DATE(  TO_CHAR(MAX(HRA_CADSIGN.ATT_DATE),'YYYY-MM-DD')||MAX(HRA_CADSIGN.CHKOUT_CARD) ,'YYYY-MM-DD HH24MI'))*60*24 > 30 then 0 else 1 end )
            INTO iCnt2
            FROM HRA_OTMSIGN , HRA_CADSIGN
            Where HRA_CADSIGN.EMP_NO = HRA_OTMSIGN.EMP_NO
              AND TO_CHAR(ATT_DATE+1,'YYYY-MM-DD') = TO_CHAR(START_DATE,'YYYY-MM-DD')
              AND HRA_OTMSIGN.EMP_NO = p_emp_no
              AND TO_CHAR(HRA_OTMSIGN.START_DATE,'YYYY-MM-DD') = p_end_date;

            ELSE

            SELECT (case when (  NVL(TO_DATE(  TO_CHAR(MAX(HRA_OTMSIGN.START_DATE),'YYYY-MM-DD')||MAX(HRA_OTMSIGN.START_TIME) ,'YYYY-MM-DD HH24MI') - TO_DATE(  TO_CHAR(MAX(HRA_CADSIGN.ATT_DATE),'YYYY-MM-DD')||MAX(HRA_CADSIGN.CHKOUT_CARD) ,'YYYY-MM-DD HH24MI'),0))*60*24 > 30 then 0 else 1 end )
            INTO iCnt2
            FROM HRA_OTMSIGN , HRA_CADSIGN
            Where HRA_CADSIGN.EMP_NO = HRA_OTMSIGN.EMP_NO
              AND TO_CHAR(ATT_DATE,'YYYY-MM-DD') = TO_CHAR(START_DATE,'YYYY-MM-DD')
              AND HRA_OTMSIGN.EMP_NO = p_emp_no
              AND TO_CHAR(HRA_OTMSIGN.START_DATE,'YYYY-MM-DD') = p_start_date;

            END IF;
            EXCEPTION
            WHEN no_data_found THEN
            iCnt2 := 0 ;
            END ;

            IF iCnt2 = 0 THEN
                RtnCode := 0 ;
                GOTO Continue_ForEach1 ;
            ELSE
                 RtnCode := 6 ;     -- 申請OnCall失敗
                GOTO Continue_ForEach1 ;
            END IF;

            END IF;


      IF RtnCode <> 0 THEN
         GOTO Continue_ForEach1 ;
      END IF;


      ------------------------- 補休單 -------------------------


       NULL;
       <<Continue_ForEach1>>
       NULL;

    return RtnCode;

    END checkOncall;


-- 判別是否為上班時間 (加班用)

FUNCTION checkClass(  p_emp_no           VARCHAR2
                    , p_start_date       VARCHAR2
                    , p_start_time       VARCHAR2
                    , p_end_date         VARCHAR2
                    , p_end_time         VARCHAR2
                    , OrganType_IN       VARCHAR2) RETURN NUMBER IS



    sClassKind  VARCHAR2(3);
    iCnt       INTEGER ;
    RtnCode     NUMBER(1);
    SOrganType VARCHAR2(10) := OrganType_IN;
    iSrest_1    VARCHAR2(4);
    iSrest_2    VARCHAR2(4);
    iSrest_3    VARCHAR2(4);
    iErest_1    VARCHAR2(4);
    iErest_2    VARCHAR2(4);
    iErest_3    VARCHAR2(4);



    BEGIN

       sClassKind := ehrphrafunc_pkg.f_getClassKind (p_emp_no , to_date(p_start_date,'yyyy-mm-dd'),SOrganType);

       IF sClassKind ='N/A' THEN
        RtnCode :=7;
        GOTO Continue_ForEach1 ;
       --ELSIF sClassKind IN ('ZZ') THEN 20161219 新增班別 ZX,ZY
       --20180725 108978 增加ZQ
       ELSIF sClassKind IN ('ZZ','ZX','ZY','ZQ') THEN
        GOTO Continue_ForEach2 ;
       ELSE

           BEGIN

            SELECT  COUNT(*)
              INTO  iCnt
              FROM HRP.HRA_CLASSDTL
             Where CLASS_CODE = sClassKind
               AND ( (p_start_time >= CHKIN_WKTM AND p_start_time <  CHKOUT_WKTM)
                OR (p_end_time > CHKIN_WKTM AND p_end_time < CHKOUT_WKTM)
                OR (CHKIN_WKTM > p_start_time AND CHKIN_WKTM < p_end_time)
                )
               AND SHIFT_NO <> '4';

           EXCEPTION
             WHEN no_data_found THEN
              GOTO Continue_ForEach2 ;
           END ;

       IF  iCnt > 0 THEN

       BEGIN

       SELECT  (NVL((SELECT  START_REST FROM HRP.HRA_CLASSDTL Where CLASS_CODE = sClassKind AND SHIFT_NO='1'),'0') ) AS START_REST1 ,
 	             (NVL((SELECT  END_REST FROM HRP.HRA_CLASSDTL Where CLASS_CODE = sClassKind AND SHIFT_NO='1'),'0') )  AS END_REST1 ,
          	   (NVL((SELECT  START_REST FROM HRP.HRA_CLASSDTL Where CLASS_CODE = sClassKind AND SHIFT_NO='2'),'0') )AS START_REST2,
          		 (NVL((SELECT  END_REST FROM HRP.HRA_CLASSDTL Where CLASS_CODE = sClassKind AND SHIFT_NO='2'),'0') )AS END_REST2,
          		 (NVL((SELECT  START_REST FROM HRP.HRA_CLASSDTL Where CLASS_CODE = sClassKind AND SHIFT_NO='3'),'0') )AS START_REST3,
          		 (NVL((SELECT  END_REST FROM HRP.HRA_CLASSDTL Where CLASS_CODE = sClassKind AND SHIFT_NO='3'),'0') )AS END_REST3
         INTO iSrest_1, iErest_1, iSrest_2 ,iErest_2 ,iSrest_3 ,  iErest_3
         FROM DUAL;

       EXCEPTION
             WHEN no_data_found THEN
             RtnCode :=7;
             GOTO Continue_ForEach2 ;
       END ;

         IF (p_start_time  BETWEEN iSrest_1 AND iErest_1
        AND p_end_time BETWEEN iSrest_1 AND iErest_1)

         OR (p_start_time BETWEEN iSrest_2 AND iErest_2
        AND p_end_time BETWEEN iSrest_2 AND iErest_2)

         OR (p_start_time BETWEEN iSrest_3 AND iErest_3
        AND p_end_time BETWEEN iSrest_3 AND iErest_3)



        THEN
        GOTO Continue_ForEach2 ;
        END IF;

       RtnCode:=8;
       GOTO Continue_ForEach1 ;
       END IF;


       END IF;

       NULL;
       <<Continue_ForEach2>>
       NULL;

       IF p_start_date <> p_end_date THEN

       --sClassKind := ehrphrafunc_pkg.f_getClassKind (p_emp_no , to_date(p_end_date,'yyyy-mm-dd'),SOrganType);
       --20180809 108978 若用end_date會導致抓到後一天的班別，導致出現判斷是否?上班時間出錯
       sClassKind := ehrphrafunc_pkg.f_getClassKind (p_emp_no , to_date(p_start_date,'yyyy-mm-dd'),SOrganType);
       --IF sClassKind IN ('ZZ') THEN 20161219 新增班別 ZX,ZY
       --20180725 108978 增加ZQ
       IF sClassKind IN ('ZZ','ZX','ZY','ZQ') THEN
        RtnCode:=0;
        GOTO Continue_ForEach1 ;
       ELSIF sClassKind ='N/A' THEN
        RtnCode:=7;
        GOTO Continue_ForEach1 ;
       ELSE

       BEGIN

            SELECT  COUNT(*)
              INTO  iCnt
              FROM HRP.HRA_CLASSDTL
             Where CLASS_CODE = sClassKind
               AND ( (p_start_time >= CHKIN_WKTM AND p_start_time <  CHKOUT_WKTM)
                OR (p_end_time > CHKIN_WKTM AND p_end_time < CHKOUT_WKTM)
                OR (CHKIN_WKTM > p_start_time AND CHKIN_WKTM < p_end_time)
                );

       EXCEPTION
         WHEN no_data_found THEN
          GOTO Continue_ForEach1 ;
       END ;

       IF  iCnt > 0 THEN
         IF (p_start_time  BETWEEN iSrest_1 AND iErest_1
        AND p_end_time BETWEEN iSrest_1 AND iErest_1)

         OR (p_start_time BETWEEN iSrest_2 AND iErest_2
        AND p_end_time BETWEEN iSrest_2 AND iErest_2)

         OR (p_start_time BETWEEN iSrest_3 AND iErest_3
        AND p_end_time BETWEEN iSrest_3 AND iErest_3)

        THEN
        GOTO Continue_ForEach1 ;
        END IF;
       RtnCode:=8;
       END IF;

       END IF;

       ELSE
       RtnCode:=0;
       END IF;




       NULL;
       <<Continue_ForEach1>>
       NULL;

    return RtnCode;

    END checkClass;

 -- 取得加班時數
 --20210106 不可用getOtmhrs_T取代
 FUNCTION getOtmhrs(  p_start_date      VARCHAR2
                    , p_start_time       VARCHAR2
                    , p_end_date         VARCHAR2
                    , p_end_time         VARCHAR2
                    , p_emp_no           VARCHAR2
                    , OrganType_IN VARCHAR2
                     ) RETURN NUMBER IS


    RtnCode       NUMBER(4);
    iSMin         NUMBER(4);
    iEMin         NUMBER(4);
    iSrest        NUMBER(4);
    iErest        NUMBER(4);
    sClassKind    VARCHAR2(3);
    iRestStartTime   VARCHAR2(4);
    iEndRestTime     VARCHAR2(4);
    SOrganType VARCHAR2(10) := OrganType_IN;

    BEGIN
    RtnCode :=0;
    iSMin := substr(p_start_time,1,2)*60 + substr(p_start_time,3,4);
    iEMin := substr(p_end_time,1,2)*60 + substr(p_end_time,3,4);

    sClassKind := ehrphrafunc_pkg.f_getClassKind (p_emp_no , to_date(p_start_date,'yyyy-mm-dd'),SOrganType);


    BEGIN

      SELECT START_REST, END_REST
        INTO  iRestStartTime ,iEndRestTime
        FROM HRP.HRA_CLASSDTL Tbl
       Where CLASS_CODE = sClassKind
         AND SHIFT_NO IN ('1');  -- 僅取時段1的休息時間

      EXCEPTION
        WHEN NO_DATA_FOUND THEN
        iRestStartTime  := '1200';
        iEndRestTime   :='1300';
        iSrest := 12 * 60;
        iErest := 13 * 60;
      END ;


    IF  iRestStartTime <>'0' AND iRestStartTime<>'0' THEN
    iSrest := substr(iRestStartTime,1,2)*60 + substr(iRestStartTime,3,4);
    iErest := substr(iEndRestTime,1,2)*60 + substr(iEndRestTime,3,4);
    ELSE
      --扣 中午午休 BY SZUHAO AT 2007-06-06
      iRestStartTime := '1200';
      iEndRestTime   := '1300';
      iSrest := 12 * 60;
      iErest := 13 * 60;
    /*  REMARK BY SZUHAO AT 2007-06-06
    iSrest :='0';
    iErest :='0';
    */
    END IF;



    --當日
    IF p_start_date = p_end_date THEN
    -- 介於 1200~1330 之間
    IF (p_start_time BETWEEN iRestStartTime AND iEndRestTime) AND (p_end_time BETWEEN iRestStartTime AND iEndRestTime) THEN

    RtnCode := iEMin -iSMin;

    ELSIF (p_start_time BETWEEN iRestStartTime AND iEndRestTime) THEN  -- 起始時間介於 iRestStartTime~iEndRestTime

    RtnCode := iEMin -  iErest ;

    ELSIF (p_end_time BETWEEN iRestStartTime AND iEndRestTime) THEN    -- 結束時間介於 iRestStartTime~iEndRestTime

    RtnCode :=iSrest - iSMin ;

    ELSIF (iRestStartTime BETWEEN p_start_time AND p_end_time) THEN  -- Stime 及 Etiem 介於 iRestStartTime~iEndRestTime

    RtnCode :=iSrest - iSMin +  iEMin -  iErest ;

    ELSE
    RtnCode := iEMin -iSMin;
    END IF;

    ELSE

    --跨天

    IF p_start_time BETWEEN iEndRestTime AND '2400' THEN
    RtnCode := 1440 - iSMin;
    ELSIF p_start_time BETWEEN iRestStartTime AND iEndRestTime THEN
    RtnCode := 1440 - iErest;
    ELSE
    RtnCode := 1440 - iSMin - (iErest - iSrest) ;
    END IF;

    IF p_end_time BETWEEN '0000' AND iRestStartTime THEN
    RtnCode := RtnCode + iEMin;
    ELSIF p_end_time BETWEEN iRestStartTime AND iEndRestTime THEN
    RtnCode := RtnCode + iSrest;
    ELSE
    RtnCode :=  RtnCode + iSrest +  iEMin - iErest;
    END IF;

    END IF;

    return RtnCode;

    END getOtmhrs;
 
--不可取代getOtmhrs
    FUNCTION getOtmhrs_T(  p_start_date      VARCHAR2
                    , p_start_date_tmp     VARCHAR2
                    , p_start_time       VARCHAR2
                    , p_end_date         VARCHAR2
                    , p_end_time         VARCHAR2
                    , p_emp_no           VARCHAR2
                    , OrganType_IN VARCHAR2
                     ) RETURN NUMBER IS


    RtnCode       NUMBER(4);
    iSMin         NUMBER(4);
    iEMin         NUMBER(4);
    iSrest        NUMBER(4);
    iErest        NUMBER(4);
    sClassKind    VARCHAR2(3);
    iRestStartTime   VARCHAR2(4);
    iEndRestTime     VARCHAR2(4);
    SOrganType VARCHAR2(10) := OrganType_IN;

    BEGIN
    RtnCode :=0;
    iSMin := substr(p_start_time,1,2)*60 + substr(p_start_time,3,4);
    iEMin := substr(p_end_time,1,2)*60 + substr(p_end_time,3,4);

    --sClassKind := ehrphrafunc_pkg.f_getClassKind (p_emp_no , to_date(p_start_date,'yyyy-mm-dd'),SOrganType);
    sClassKind := ehrphrafunc_pkg.f_getClassKind (p_emp_no , to_date(p_start_date_tmp,'yyyy-mm-dd'),SOrganType);

    BEGIN

      SELECT START_REST, END_REST
        INTO  iRestStartTime ,iEndRestTime
        FROM HRP.HRA_CLASSDTL Tbl
       Where CLASS_CODE = sClassKind
         AND SHIFT_NO IN ('1');  -- 僅取時段1的休息時間

      EXCEPTION
        WHEN NO_DATA_FOUND THEN
        iRestStartTime  := '1200';
        iEndRestTime   :='1300';
        iSrest := 12 * 60;
        iErest := 13 * 60;
      END ;


    IF  iRestStartTime <>'0' AND iRestStartTime<>'0' THEN
    iSrest := substr(iRestStartTime,1,2)*60 + substr(iRestStartTime,3,4);
    iErest := substr(iEndRestTime,1,2)*60 + substr(iEndRestTime,3,4);
    ELSE
      --扣 中午午休 BY SZUHAO AT 2007-06-06
      /*iRestStartTime := '1200';
      iEndRestTime   := '1300';
      iSrest := 12 * 60;
      iErest := 13 * 60;*/
    /*  REMARK BY SZUHAO AT 2007-06-06
    iSrest :='0';
    iErest :='0';
    */
      iSrest := 0;
      iErest := 0;
    END IF;



    --當日
    IF p_start_date = p_end_date THEN
    -- 介於 1200~1330 之間
    IF (p_start_time BETWEEN iRestStartTime AND iEndRestTime) AND (p_end_time BETWEEN iRestStartTime AND iEndRestTime) THEN

    RtnCode := iEMin -iSMin;

    ELSIF (p_start_time BETWEEN iRestStartTime AND iEndRestTime) THEN  -- 起始時間介於 iRestStartTime~iEndRestTime

    RtnCode := iEMin -  iErest ;

    ELSIF (p_end_time BETWEEN iRestStartTime AND iEndRestTime) THEN    -- 結束時間介於 iRestStartTime~iEndRestTime

    RtnCode :=iSrest - iSMin ;

    ELSIF (iRestStartTime BETWEEN p_start_time AND p_end_time) THEN  -- Stime 及 Etiem 介於 iRestStartTime~iEndRestTime

    RtnCode :=iSrest - iSMin +  iEMin -  iErest ;

    ELSE
    RtnCode := iEMin -iSMin;
    END IF;

    ELSE

    --跨天

    IF p_start_time BETWEEN iEndRestTime AND '2400' THEN
    RtnCode := 1440 - iSMin;
    ELSIF p_start_time BETWEEN iRestStartTime AND iEndRestTime THEN
    RtnCode := 1440 - iErest;
    ELSE
    RtnCode := 1440 - iSMin - (iErest - iSrest) ;
    END IF;

    IF p_end_time BETWEEN '0000' AND iRestStartTime THEN
    RtnCode := RtnCode + iEMin;
    ELSIF p_end_time BETWEEN iRestStartTime AND iEndRestTime THEN
    RtnCode := RtnCode + iSrest;
    ELSE
    RtnCode :=  RtnCode + iSrest +  iEMin - iErest;
    END IF;

    END IF;

    return RtnCode;

    END getOtmhrs_T;

 --20210106 不可用getOffhrs_T取代,假卡計算會用(無應出勤日)
    FUNCTION getOffhrs(  p_start_date       VARCHAR2
                       , p_start_time       VARCHAR2
                       , p_end_date         VARCHAR2
                       , p_end_time         VARCHAR2
                       , p_emp_no           VARCHAR2
                       , OrganType_IN VARCHAR2
                       ) RETURN NUMBER IS


    RtnCode          NUMBER(4);
    sEmpNo           VARCHAR2(10) := p_emp_no;
    sTotal           NUMBER(4);
    sStartDate       VARCHAR2(10) := p_start_date;
    sStartTime       VARCHAR2(4)  := p_start_time;
    sEndDate         VARCHAR2(10) := p_end_date;
    sEndTime         VARCHAR2(4)  := p_end_time;
    sclassCode       VARCHAR2(3);
    SOrganType VARCHAR2(10) := OrganType_IN;
    iSMin            NUMBER(4);
    iEMin            NUMBER(4);
    iSrest           NUMBER(4);
    iErest           NUMBER(4);
    sClassKind       VARCHAR2(3);
    iRestStartTime   VARCHAR2(4);
    iEndRestTime     VARCHAR2(4);
    ichkin           VARCHAR2(4);
    ichkout          VARCHAR2(4);

     CURSOR cursor1 (arg_class_code VARCHAR2) IS
  --    SELECT CHKIN_WKTM,CHKOUT_WKTM,START_REST, END_REST
       SELECT START_REST, END_REST
        FROM HRP.HRA_CLASSDTL
       Where CLASS_CODE = arg_class_code
       ORDER BY START_REST;



    BEGIN
    RtnCode :=0;

     IF TO_DATE(sStartDate ||sStartTime,'YYYY-MM-DDHH24MI') > TO_DATE(sEndDate ||sEndTime,'YYYY-MM-DDHH24MI') THEN
      RtnCode := 0;
      GOTO Continue_ForEach2;
     END IF;

    sclassCode := ehrphrafunc_pkg.f_getClassKind (sEmpNo , to_date(sStartDate,'yyyy-mm-dd') ,SOrganType);
    sTotal := ehrphrafunc_pkg.f_count_time(to_date(sStartDate,'yyyy-mm-dd'),sStartTime,to_date(sEndDate,'yyyy-mm-dd'),sEndTime);

    --無排班
    IF sclassCode = 'N/A' THEN
    GOTO Continue_ForEach2 ;
    END IF;


    OPEN cursor1(sclassCode);
    LOOP
      FETCH cursor1
--        INTO ichkin, ichkout ,iRestStartTime ,iEndRestTime  ;
        INTO iRestStartTime ,iEndRestTime  ;
      EXIT WHEN cursor1%NOTFOUND;

     IF  iRestStartTime = '0' OR iEndRestTime ='0' THEN

     RtnCode := sTotal -0 ;

     ELSIF sStartTime between iRestStartTime and iEndRestTime AND  sEndTime NOT between iRestStartTime and iEndRestTime then

     RtnCode := sTotal - ehrphrafunc_pkg.f_count_time(to_date(sStartDate,'yyyy-mm-dd'),sStartTime,to_date(sEndDate,'yyyy-mm-dd'),iEndRestTime);
	 --RtnCode := sTotal - ehrphrafunc_pkg.f_count_time(to_date(sStartDate,'yyyy-mm-dd'),sStartTime,to_date('2008-05-21','yyyy-mm-dd'),iEndRestTime);

     ELSIF sEndTime between iRestStartTime and iEndRestTime and sStartTime not between iRestStartTime and iEndRestTime then

     RtnCode := sTotal - ehrphrafunc_pkg.f_count_time(to_date(sStartDate,'yyyy-mm-dd'),iRestStartTime,to_date(sEndDate,'yyyy-mm-dd'),sEndTime);

     ELSIF sStartTime < iRestStartTime and sEndTime > iEndRestTime then

     RtnCode := sTotal - ehrphrafunc_pkg.f_count_time(to_date(sStartDate,'yyyy-mm-dd'),iRestStartTime,to_date(sEndDate,'yyyy-mm-dd'),iEndRestTime);

     ELSIF sStartTime between iRestStartTime and iEndRestTime AND  sEndTime between iRestStartTime and iEndRestTime THEN

     RtnCode := sTotal ;

     ELSE
     RtnCode := sTotal -0 ;

     END IF;


      NULL;
      <<Continue_ForEach1>>
      NULL;

    END LOOP;
    CLOSE cursor1;
    NULL;


       NULL;
      <<Continue_ForEach2>>
      NULL;
    return RtnCode;

    END getOffhrs;
    
--不可取代getOffhrs
    FUNCTION getOffhrs_T(  p_start_date       VARCHAR2
                       , p_start_date_tmp     VARCHAR2
                       , p_start_time       VARCHAR2
                       , p_end_date         VARCHAR2
                       , p_end_time         VARCHAR2
                       , p_emp_no           VARCHAR2
                       , OrganType_IN VARCHAR2
                       ) RETURN NUMBER IS


    RtnCode          NUMBER(4);
    sEmpNo           VARCHAR2(10) := p_emp_no;
    sTotal           NUMBER(4);
    sStartDate       VARCHAR2(10) := p_start_date;
    sStartTime       VARCHAR2(4)  := p_start_time;
    sEndDate         VARCHAR2(10) := p_end_date;
    sEndTime         VARCHAR2(4)  := p_end_time;
    sclassCode       VARCHAR2(3);
    SOrganType VARCHAR2(10) := OrganType_IN;
    --iSMin            NUMBER(4);
    --iEMin            NUMBER(4);
    --iSrest           NUMBER(4);
    --iErest           NUMBER(4);
    --sClassKind       VARCHAR2(3);
    iRestStartTime   VARCHAR2(4);
    iEndRestTime     VARCHAR2(4);
    --ichkin           VARCHAR2(4);
    --ichkout          VARCHAR2(4);

     CURSOR cursor1 (arg_class_code VARCHAR2) IS
  --    SELECT CHKIN_WKTM,CHKOUT_WKTM,START_REST, END_REST
       SELECT START_REST, END_REST
        FROM HRP.HRA_CLASSDTL
       Where CLASS_CODE = arg_class_code
       ORDER BY START_REST;



    BEGIN
    RtnCode :=0;

     IF TO_DATE(sStartDate ||sStartTime,'YYYY-MM-DDHH24MI') > TO_DATE(sEndDate ||sEndTime,'YYYY-MM-DDHH24MI') THEN
      RtnCode := 0;
      GOTO Continue_ForEach2;
     END IF;

    --sclassCode := ehrphrafunc_pkg.f_getClassKind (sEmpNo , to_date(sStartDate,'yyyy-mm-dd') ,SOrganType);
    sclassCode := ehrphrafunc_pkg.f_getClassKind (sEmpNo , to_date(p_start_date_tmp,'yyyy-mm-dd') ,SOrganType);
    sTotal := ehrphrafunc_pkg.f_count_time(to_date(sStartDate,'yyyy-mm-dd'),sStartTime,to_date(sEndDate,'yyyy-mm-dd'),sEndTime);

    --無排班
    IF sclassCode = 'N/A' THEN
    GOTO Continue_ForEach2 ;
    END IF;


    OPEN cursor1(sclassCode);
    LOOP
      FETCH cursor1
--        INTO ichkin, ichkout ,iRestStartTime ,iEndRestTime  ;
        INTO iRestStartTime ,iEndRestTime  ;
      EXIT WHEN cursor1%NOTFOUND;

     IF  iRestStartTime = '0' OR iEndRestTime ='0' THEN

     RtnCode := sTotal -0 ;

     ELSIF sStartTime between iRestStartTime and iEndRestTime AND  sEndTime NOT between iRestStartTime and iEndRestTime then

     RtnCode := sTotal - ehrphrafunc_pkg.f_count_time(to_date(sStartDate,'yyyy-mm-dd'),sStartTime,to_date(sEndDate,'yyyy-mm-dd'),iEndRestTime);
	 --RtnCode := sTotal - ehrphrafunc_pkg.f_count_time(to_date(sStartDate,'yyyy-mm-dd'),sStartTime,to_date('2008-05-21','yyyy-mm-dd'),iEndRestTime);

     ELSIF sEndTime between iRestStartTime and iEndRestTime and sStartTime not between iRestStartTime and iEndRestTime then

     RtnCode := sTotal - ehrphrafunc_pkg.f_count_time(to_date(sStartDate,'yyyy-mm-dd'),iRestStartTime,to_date(sEndDate,'yyyy-mm-dd'),sEndTime);

     ELSIF sStartTime < iRestStartTime and sEndTime > iEndRestTime then

     RtnCode := sTotal - ehrphrafunc_pkg.f_count_time(to_date(sStartDate,'yyyy-mm-dd'),iRestStartTime,to_date(sEndDate,'yyyy-mm-dd'),iEndRestTime);

     ELSIF sStartTime between iRestStartTime and iEndRestTime AND  sEndTime between iRestStartTime and iEndRestTime THEN

     RtnCode := sTotal ;

     ELSE
     RtnCode := sTotal -0 ;

     END IF;


      NULL;
      <<Continue_ForEach1>>
      NULL;

    END LOOP;
    CLOSE cursor1;
    NULL;


       NULL;
      <<Continue_ForEach2>>
      NULL;
    return RtnCode;

    END getOffhrs_T;
    
    FUNCTION getOffhrs_Evc(  p_start_date       VARCHAR2
                           , p_start_time       VARCHAR2
                           , p_end_date         VARCHAR2
                           , p_end_time         VARCHAR2
                           , p_emp_no           VARCHAR2
                           , OrganType_IN VARCHAR2
                           ) RETURN NUMBER IS


    RtnCode          NUMBER(4);
    sEmpNo           VARCHAR2(10) := p_emp_no;
    sTotal           NUMBER(4);
    sStartDate       VARCHAR2(10) := p_start_date;
    sStartTime       VARCHAR2(4)  := p_start_time;
    sEndDate         VARCHAR2(10) := p_end_date;
    sEndTime         VARCHAR2(4)  := p_end_time;
    sclassCode       VARCHAR2(3);
    SOrganType VARCHAR2(10) := OrganType_IN;
    iSMin            NUMBER(4);
    iEMin            NUMBER(4);
    iSrest           NUMBER(4);
    iErest           NUMBER(4);
    sClassKind       VARCHAR2(3);
    iRestStartTime   VARCHAR2(4);
    iEndRestTime     VARCHAR2(4);
    ichkin           VARCHAR2(4);
    ichkout          VARCHAR2(4);

     CURSOR cursor1 (arg_class_code VARCHAR2) IS
  --    SELECT CHKIN_WKTM,CHKOUT_WKTM,START_REST, END_REST
       SELECT START_REST, END_REST
        FROM HRP.HRA_CLASSDTL
       Where CLASS_CODE = arg_class_code
       ORDER BY START_REST;



    BEGIN
    RtnCode :=0;

     IF TO_DATE(sStartDate ||sStartTime,'YYYY-MM-DDHH24MI') > TO_DATE(sEndDate ||sEndTime,'YYYY-MM-DDHH24MI') THEN
      RtnCode := 0;
      GOTO Continue_ForEach2;
     END IF;

    sclassCode := ehrphrafunc_pkg.f_getClassKind (sEmpNo , to_date(sStartDate,'yyyy-mm-dd') ,SOrganType);
    sTotal := ehrphrafunc_pkg.f_count_time(to_date(sStartDate,'yyyy-mm-dd'),sStartTime,to_date(sEndDate,'yyyy-mm-dd'),sEndTime);

    --無排班
    IF sclassCode = 'N/A' THEN
    GOTO Continue_ForEach2 ;
    END IF;


    OPEN cursor1(sclassCode);
    LOOP
      FETCH cursor1
--        INTO ichkin, ichkout ,iRestStartTime ,iEndRestTime  ;
        INTO iRestStartTime ,iEndRestTime  ;
      EXIT WHEN cursor1%NOTFOUND;

     IF  iRestStartTime = '0' OR iEndRestTime ='0' THEN

     RtnCode := sTotal -0 ;

     ELSIF sStartTime between iRestStartTime and iEndRestTime AND  sEndTime NOT between iRestStartTime and iEndRestTime then

     RtnCode := sTotal - ehrphrafunc_pkg.f_count_time(to_date(sStartDate,'yyyy-mm-dd'),sStartTime,to_date(sEndDate,'yyyy-mm-dd'),iEndRestTime);
	 --RtnCode := sTotal - ehrphrafunc_pkg.f_count_time(to_date(sStartDate,'yyyy-mm-dd'),sStartTime,to_date('2008-05-21','yyyy-mm-dd'),iEndRestTime);

     ELSIF sEndTime between iRestStartTime and iEndRestTime and sStartTime not between iRestStartTime and iEndRestTime then

     RtnCode := sTotal - ehrphrafunc_pkg.f_count_time(to_date(sStartDate,'yyyy-mm-dd'),iRestStartTime,to_date(sEndDate,'yyyy-mm-dd'),sEndTime);

     ELSIF sStartTime < iRestStartTime and sEndTime > iEndRestTime then

     RtnCode := sTotal - ehrphrafunc_pkg.f_count_time(to_date(sStartDate,'yyyy-mm-dd'),iRestStartTime,to_date(sEndDate,'yyyy-mm-dd'),iEndRestTime);

     ELSIF sStartTime between iRestStartTime and iEndRestTime AND  sEndTime between iRestStartTime and iEndRestTime THEN

     RtnCode := 0 ;

     ELSE
     RtnCode := sTotal -0 ;

     END IF;


      NULL;
      <<Continue_ForEach1>>
      NULL;

    END LOOP;
    CLOSE cursor1;
    NULL;


       NULL;
      <<Continue_ForEach2>>
      NULL;
    return RtnCode;

    END getOffhrs_Evc;

  --MAIL不CARE多機構
  PROCEDURE mail_deputy(  p_D_emp_no     VARCHAR2,      --代理人
                          p_start_date   VARCHAR2,
                          p_end_date     VARCHAR2,
                          p_P_emp_no     VARCHAR2,      --審核者
                          p_emp_no       VARCHAR2,      --申請者
                          p_OrganType_IN VARCHAR2) IS
    s_EmpName   VARCHAR2(200);
    s_PosName   VARCHAR2(100);
    s_D_EmpName VARCHAR2(200);
    s_D_PosName VARCHAR2(100);
    s_P_EmpName VARCHAR2(20);
    s_D_EMail   VARCHAR2(120);
    s_P_EMail   VARCHAR2(120);
    iCnt         INTEGER;
    Message  VARCHAR2(24000);
    ipaddress    VARCHAR2(16);
    sOrganType   VARCHAR2(10);
  BEGIN
    sOrganType := p_OrganType_IN;
    iCnt := 0;
   
        SELECT utl_inaddr.get_host_address
          INTO ipaddress
          FROM dual;

        SELECT CH_NAME,(SELECT CH_NAME FROM HRE_POSMST WHERE POS_NO = HRP.HRE_EMPBAS.POS_NO) POSNAME
          INTO s_EmpName, s_PosName
          FROM HRP.HRE_EMPBAS
         Where EMP_NO = p_emp_no;
           --and organ_type = sOrganType;

      BEGIN
        SELECT CH_NAME,
               --(CASE WHEN substr(Emp_No,1,1) IN ('P', 'R', 'S') THEN Emp_No||'@edah.org.tw' ELSE 'ed'||Emp_No||'@edah.org.tw' END) EMail,
               'ed'||Emp_No||'@edah.org.tw' AS EMail,
               (SELECT CH_NAME FROM HRE_POSMST WHERE POS_NO = HRP.HRE_EMPBAS.POS_NO) POSNAME
          INTO s_D_EmpName , s_D_EMail, s_D_PosName
          FROM HRP.HRE_EMPBAS
         Where EMP_NO = p_D_emp_no
          and disabled = 'N';
          --and organ_type = sOrganType;

      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          iCnt := 1;
      END;

    IF iCnt = 0 THEN
      IF s_D_EMail IS NULL  OR  s_D_EMail = '' THEN
        null;
      ELSE
          Message := s_D_EmpName || s_D_PosName || ' 您好 :<br><br> '  || s_EmpName || s_PosName || '(' ||p_emp_no ||') 於 '|| p_start_date || ' 至 ' || p_end_date || ' 請假'
                      ||' <br>謹此通知您是他(她)的指定代理人 <br><br> 感謝您的參與配合!<br><br>人事課敬啟 '||
                      to_char(sysdate, 'YYYY-MM-DD HH24:MI')||'<br><br> '||ipaddress;

         -- ehrphrafunc_pkg.POST_HTML_MAIL('edhr@edah.org.tw',s_D_EMail,'ed108978@edah.org.tw','1','請假代理人通知',Message);
          hrpuser.MAILQUEUE.insertMailQueue('edhr@edah.org.tw',s_D_EMail,'','請假代理人通知',Message,'','', '1');
      END IF;
    END IF;
  END mail_deputy;
  
 

  /*   擬作廢刪除
  PROCEDURE mail_deputy2(  p_D_emp_no     VARCHAR2,
                          p_start_date   VARCHAR2,
                          p_end_date     VARCHAR2,
                          p_P_emp_no     VARCHAR2,
                          p_emp_no       VARCHAR2,
                          p_OrganType_IN VARCHAR2) IS
    s_EmpName   VARCHAR2(20);
    s_PosName   VARCHAR2(20);
    s_D_EmpName VARCHAR2(20);
    s_D_PosName VARCHAR2(20);
    s_P_EmpName VARCHAR2(20);
    s_D_EMail   VARCHAR2(120);
    s_P_EMail   VARCHAR2(120);
    iCnt         INTEGER;
    Message  VARCHAR2(4000);
    ipaddress    VARCHAR2(16);
    sOrganType   VARCHAR2(10);
  BEGIN
    sOrganType := p_OrganType_IN;
    iCnt := 0;
        SELECT utl_inaddr.get_host_address
          INTO ipaddress
          FROM dual;

        SELECT CH_NAME,(SELECT CH_NAME FROM HRE_POSMST WHERE POS_NO = HRP.HRE_EMPBAS.POS_NO) POSNAME
          INTO s_EmpName, s_PosName
          FROM HRP.HRE_EMPBAS
         Where EMP_NO = p_emp_no
           and organ_type = sOrganType;

      BEGIN
        SELECT CH_NAME,E_MAIL,(SELECT CH_NAME FROM HRE_POSMST WHERE POS_NO = HRP.HRE_EMPBAS.POS_NO) POSNAME
          INTO s_D_EmpName , s_D_EMail, s_D_PosName
          FROM HRP.HRE_EMPBAS
         Where EMP_NO = p_D_emp_no
          and disabled = 'N'
          and organ_type = sOrganType;

      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          iCnt := 1;
      END;

      IF iCnt = 0 THEN
      IF s_D_EMail IS NULL  AND  s_D_EMail = '' THEN
        null;
      else
          Message := s_D_EmpName || s_D_PosName || ' 您好 :<br><br> '  || s_EmpName || s_PosName || '(' ||p_emp_no ||') 於 '|| p_start_date || ' 至 ' || p_end_date || ' 請假'
                      ||' <br>謹此通知您是他(她)的指定代理人 <br><br> 感謝您的參與配合!<br><br>人事課敬啟 '||
                      to_char(sysdate, 'YYYY-MM-DD HH24:MI')||'<br><br> '||ipaddress;
          --EAST_PKG.POST_HTML_MAIL('edhr@edah.org.tw',
          --                       s_D_EMail,
          --                        '請假代理人通知',
          --                         Message);
          ehrphrafunc_pkg.POST_HTML_MAIL('edhr@edah.org.tw',s_D_EMail,'','1','請假代理人通知',Message);
      END IF;
      END IF;
  END mail_deputy2;
    */

/*------------------------------------------
-- SQL_NAME : check_deputy
-- 檢核請假代理人
-- RETURN 1 = 無此人 , 2 = 已請假
-- by szuhao
------------------------------------------*/


FUNCTION       check_deputy(  p_emp_no           VARCHAR2
                            , p_start_date       VARCHAR2
                            , p_start_time       VARCHAR2
                            , p_end_date         VARCHAR2
                            , p_end_time         VARCHAR2
                            ) RETURN NUMBER IS

    sEmpNo      VARCHAR2(20) := p_emp_no;
    sStartDate  VARCHAR2(10) := p_start_date;
    sStartTime  VARCHAR2(7)  := p_start_time;
    sEndDate    VARCHAR2(10) := p_end_date;
    sEndTime    VARCHAR2(7)  := p_end_time;
    iCnt        INTEGER ;
    RtnCode     NUMBER;

    BEGIN
    RtnCode :=0;

      -- 有無此人
      IF sEmpNo <> 'MIS' THEN  -- TEST用

        BEGIN
        SELECT COUNT(*)
          INTO iCnt
          FROM HRP.HRE_EMPBAS
         Where EMP_NO = sEmpNo
          and disabled = 'N';

      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          iCnt := 0;
      END;

      IF iCnt = 0 THEN
      RtnCode :=1;
      GOTO Continue_ForEach1;
      END IF;

       END IF;
       /*
      -- 假單
      BEGIN
          SELECT count(*)
            INTO iCnt
            FROM hra_evcrec
           WHERE ((to_char(start_date, 'YYYY-MM-DD') || start_time between
                 sStartDate || sStartTime and sEndDate || sEndTime)
              OR (to_char(end_date, 'YYYY-MM-DD') || end_time between
                 sStartDate || sStartTime and sEndDate || sEndTime))
             AND EMP_NO = sEmpNo AND STATUS NOT IN ('N','D');
       EXCEPTION
       WHEN OTHERS THEN
            iCnt := 0;
       END;

       IF iCnt > 0 THEN
        RtnCode := 2;
        GOTO Continue_ForEach1;
       END IF;

       -- 新假卡介於db 日期
       IF iCnt = 0 THEN
          BEGIN
             SELECT count(*)
               INTO iCnt
               FROM hra_evcrec
              WHERE ((sStartDate || sStartTime between to_char(start_date, 'YYYY-MM-DD') || start_time
                                                   and to_char(end_date, 'YYYY-MM-DD') || end_time)
                 OR  (sEndDate   || sEndTime   between to_char(start_date, 'YYYY-MM-DD') || start_time
                                                   and to_char(end_date, 'YYYY-MM-DD') || end_time))
                AND EMP_NO = sEmpNo AND STATUS NOT IN ('N','D');
          EXCEPTION
          WHEN OTHERS THEN
               iCnt := 0;
          END;
       END IF;

       IF iCnt > 0 THEN
        RtnCode := 2;
        GOTO Continue_ForEach1;
       END IF;

      -- 借休

      -- 補休

       */
       NULL;
       <<Continue_ForEach1>>
       NULL;

       return RtnCode;
    END check_deputy;

    FUNCTION getCountDocSUPhrs(  p_start_date       VARCHAR2
                               , p_start_time       VARCHAR2
                               , p_end_date         VARCHAR2
                               , p_end_time         VARCHAR2) RETURN NUMBER IS


    sTotal           NUMBER(5,1);
    sStartDate       VARCHAR2(10) := p_start_date;
    sStartTime       VARCHAR2(4)  := p_start_time;
    sEndDate         VARCHAR2(10) := p_end_date;
    sEndTime         VARCHAR2(10) := p_end_time;


    sClassKind       VARCHAR2(3);
    iRestStartTime   VARCHAR2(4);
    iEndRestTime     VARCHAR2(4);
    CntMin           NUMBER(5);
    CntHrs           NUMBER(5,1);
    nCnt             INTEGER;
    iSTime           VARCHAR2(4);
    iETime           VARCHAR2(4);
    iDate            VARCHAR2(10);



    BEGIN

      CntHrs :=0;
      CntMin :=0;
    --同一天
    IF sEndDate =  sStartDate THEN

    CntMin := getCountDocSUPhrs_fun( sStartDate, sStartTime, sEndDate, sEndTime);
    --跨天
    ELSIF TO_DATE(sEndDate,'YYYY-MM-DD') = TO_DATE(sStartDate,'YYYY-MM-DD') +1 THEN

    CntMin := getCountDocSUPhrs_fun( sStartDate, sStartTime, sStartDate, '1700');
    CntMin :=  CntMin + getCountDocSUPhrs_fun( sEndDate, '0800', sEndDate, sEndTime);

    --跨兩天以上
    ELSE

    CntMin := getCountDocSUPhrs_fun( sStartDate, sStartTime, sStartDate, '1700');
    CntMin :=  CntMin + getCountDocSUPhrs_fun( sEndDate, '0800', sEndDate, sEndTime);


    nCnt := to_date(sEndDate,'yyyy-mm-dd') - to_date(sStartDate,'yyyy-mm-dd') -1;

    FOR i IN 1..nCnt LOOP
    iDate := to_char(to_date(sStartDate,'yyyy-mm-dd')+i,'yyyy-mm-dd');
    CntMin :=  CntMin + getCountDocSUPhrs_fun( iDate , '0800', iDate, '1700');


    END LOOP;


    END IF;




       NULL;
      <<Continue_ForEach1>>
      NULL;

    CntHrs := CEIL(CntMin / 30) * 0.5;



    return CntHrs;

    END getCountDocSUPhrs;

    FUNCTION getCountDocSUPhrs_fun(  p_start_date       VARCHAR2
                                   , p_start_time       VARCHAR2
                                   , p_end_date         VARCHAR2
                                   , p_end_time         VARCHAR2) RETURN NUMBER IS

    sStartDate       VARCHAR2(10) := p_start_date;
    sStartTime       VARCHAR2(4)  := p_start_time;
    sEndDate         VARCHAR2(10) := p_end_date;
    sEndTime         VARCHAR2(10) := p_end_time;


    CntMin           NUMBER(5);
    nCnt             INTEGER;
    iSTime           VARCHAR2(4);
    iETime           VARCHAR2(4);



    BEGIN

      CntMin :=0;


    --是否為假日
    BEGIN
     SELECT  COUNT(*)
     INTO nCnt
     FROM HRP.HRA_HOLIDAY
    Where to_char(holi_date,'yyyy-mm-dd')= sStartDate
      and STOP_WORK = 'Y'
      and HOLI_WEEK <> 'SAT';
    EXCEPTION
       WHEN OTHERS THEN
            nCnt := 0;
    END;

    IF nCnt > 0 THEN
    GOTO Continue_ForEach1;
    END IF;

    --是否為週六

    BEGIN
     SELECT  COUNT(*)
     INTO nCnt
     FROM HRP.HRA_HOLIDAY
    Where to_char(holi_date,'yyyy-mm-dd')= sStartDate
      and HOLI_WEEK = 'SAT';
    EXCEPTION
       WHEN OTHERS THEN
            nCnt := 0;
    END;

     --計算時數

    IF sStartTime BETWEEN '0800' AND '1700' THEN
    iSTime := sStartTime;
    ELSIF sStartTime < '0800' THEN
    iSTime := '0800';
    ELSE
    iSTime := '0800';
    END IF;

    IF sEndTime BETWEEN '0800' AND '1700' THEN
    iETime := sEndTime;
    ELSIF sEndTime > '1700' THEN
    iETime := '1700';
    ELSE
    iETime := '0800';
    END IF;

    IF nCnt > 0 AND  iETime > '1200' THEN --星期六上半天
    iETime := '1200';
    END IF;

    IF iETime BETWEEN '1200' AND '1300' THEN
    CntMin := ehrphrafunc_pkg.f_count_time(to_date(sStartDate,'yyyy-mm-dd'),iSTime,to_date(sStartDate,'yyyy-mm-dd'),'1200');
    ELSIF iETime BETWEEN '1300' AND '1700'  AND sStartTime <= '1200' THEN
    CntMin := ehrphrafunc_pkg.f_count_time(to_date(sStartDate,'yyyy-mm-dd'),iSTime,to_date(sStartDate,'yyyy-mm-dd'),iETime);
    CntMin := CntMin - 60;
    ELSIF iETime BETWEEN '1300' AND '1700'  AND sStartTime >= '1300' THEN
    CntMin := ehrphrafunc_pkg.f_count_time(to_date(sStartDate,'yyyy-mm-dd'),iSTime,to_date(sStartDate,'yyyy-mm-dd'),iETime);
    ELSIF iETime BETWEEN '0800' AND '1200' THEN
    CntMin := ehrphrafunc_pkg.f_count_time(to_date(sStartDate,'yyyy-mm-dd'),iSTime,to_date(sStartDate,'yyyy-mm-dd'),iETime);
    END IF;

    NULL;
    <<Continue_ForEach1>>
    NULL;

    return CntMin;

    END getCountDocSUPhrs_fun;

PROCEDURE offrec_uni_backup(p_emp_no           VARCHAR2
                          , p_start_date       VARCHAR2
                          , p_start_time       VARCHAR2
                          , p_status           VARCHAR2
                          , p_item_type        VARCHAR2
                          , RtnCode           OUT NUMBER) AS
    iCnt         NUMBER(1);
BEGIN
  RtnCode := 0;
  SELECT COUNT(EMP_NO)
    INTO iCnt
    FROM HRA_OFFREC
    WHERE EMP_NO = p_emp_no AND
          start_date = to_date(p_start_date,'yyyy-mm-dd') AND
          start_time = p_start_time AND
          status = p_status AND
          item_type = p_item_type;
  if (iCnt <> 0) THEN
    INSERT INTO HRA_OFFREC_UNI
    (EMP_NO, SEQ, DEPT_NO, START_DATE,
   START_TIME, END_DATE, END_TIME,
   OTM_HRS, ORG_FEE, REG_FEE,
   OTM_REA, REMARK, STATUS,
   PERMIT_ID, PERMIT_DATE, CREATED_BY,
   CREATION_DATE, LAST_UPDATED_BY, LAST_UPDATE_DATE,
   ITEM_TYPE, TRN_YM, ONCALL,
   TRAFFIC_FEE, CHECK_FLAG, CHECK_POIN,
   START_DATE_TMP, CREATION_COMP, LAST_UPDATED_COMP,
   DISABLED, DEPUTY, HARM_MEAL_EXPENSE,
   FOLLOW_DEPT_NO, CHIEF_TRANS, ABROAD)
   (SELECT EMP_NO,
   NVL((SELECT MAX(SEQ)+1 FROM HRA_OFFREC_UNI WHERE EMP_NO = p_emp_no AND
          start_date = to_date(p_start_date,'yyyy-mm-dd') AND
          start_time = p_start_time AND status = p_status AND item_type = p_item_type),1),
    DEPT_NO, START_DATE,
   START_TIME, END_DATE, END_TIME,
   OTM_HRS, ORG_FEE, REG_FEE,
   OTM_REA, REMARK, STATUS,
   PERMIT_ID, PERMIT_DATE, CREATED_BY,
   CREATION_DATE, LAST_UPDATED_BY, LAST_UPDATE_DATE,
   ITEM_TYPE, TRN_YM, ONCALL,
   TRAFFIC_FEE, CHECK_FLAG, CHECK_POIN,
   START_DATE_TMP, CREATION_COMP, LAST_UPDATED_COMP,
   DISABLED, DEPUTY, HARM_MEAL_EXPENSE,
   FOLLOW_DEPT_NO, CHIEF_TRANS, ABROAD FROM HRA_OFFREC
   WHERE EMP_NO = p_emp_no AND
          start_date = to_date(p_start_date,'yyyy-mm-dd') AND
          start_time = p_start_time AND status = p_status AND item_type = p_item_type);

  DELETE FROM HRA_OFFREC WHERE EMP_NO = p_emp_no AND
          start_date = to_date(p_start_date,'yyyy-mm-dd') AND
          start_time = p_start_time AND status = p_status AND item_type = p_item_type;

  COMMIT;
  END IF;

end offrec_uni_backup;

PROCEDURE offrec_ovrtrans(UpdateBy_IN      VARCHAR2
                          , organtype_IN   VARCHAR2
                          , RtnCode        OUT NUMBER) AS
    iCnt         NUMBER(1);
    ichecked     VARCHAR2(1);
    dTrnym       VARCHAR2(7);
    dSignman     VARCHAR2(20);
    dEmail       VARCHAR2(120);
    dDeptno      VARCHAR2(20);
    dDeptname    VARCHAR2(60);
    dOvrtype     VARCHAR2(60);
      -- 主管迴圈變換變數
    dSignmanTmp   VARCHAR2(20);
    dEmailTmp     VARCHAR2(120);
      --主管訊息
    sMessageL    VARCHAR2(20000);
      --人事課訊息
    pMessageL    VARCHAR2(20000);
    sEMail       VARCHAR2(120);
    --INSERT迴圈參數
    qHrsym       VARCHAR2(7);
    qSignman     VARCHAR2(20);
    qPermit_id   VARCHAR2(20);
    qDeptno      VARCHAR2(20);
    qStatus      VARCHAR2(1);
    qOvrtyp      VARCHAR2(1);
    qOvravg      NUMBER(7,2);
    qOvrths      NUMBER(7,2);
    qOvryel      NUMBER(7,2);
    qOvrred      NUMBER(7,2);
    qPremon      NUMBER(7,2);
    qNowmon      NUMBER(7,2);

    sOrganType   VARCHAR2(10);

    CURSOR cursor1 IS
    	select trn_tm,signman,email,dept_no,deptname,sta from
   (
select  trn_tm,signman,(select 'ed'||hre_empbas.emp_no||'@edah.org.tw' from hre_empbas where organ_type = sOrganType and emp_no = t1.signman) email,
    	dept_no,(select ch_name from hre_orgbas where organ_type = sOrganType and dept_no = t1.dept_no) deptname,
case ovr_type when 'A' then '紅燈警示' when 'B' then '黃燈警示' when 'C' then '連續兩個月超過閾值' else '' end sta
 from hra_offovrres t1  where org_by = sOrganType and  trn_tm = (select hrs_ym from hrs_ym where rownum = 1) and need_reply = 'Y'
UNION ALL
select  trn_tm,(select user_signman from hre_Empbas where organ_type = sOrganType and emp_no = t2.signman),
        (select 'ed'||hre_empbas.emp_no||'@edah.org.tw' from hre_empbas where organ_type = sOrganType and emp_no = (select user_signman from hre_empbas where organ_type = sOrganType and emp_no = t2.signman)) email,
    	dept_no,(select ch_name from hre_orgbas where organ_type = sOrganType and dept_no = t2.dept_no) deptname,
        case ovr_type when  'A' then '紅燈警示需覆核' when 'B' then '黃燈警示需覆核' else '連續兩個月超過閾值需覆核' end
 from hra_offovrres t2
  where org_by = sOrganType and trn_tm = (select hrs_ym from hrs_ym where rownum = 1) and ovr_type in ('A','B','C') and need_reply = 'Y'
    and (select user_signman from hre_Empbas where organ_type = sOrganType and emp_no = t2.signman) not in (select code_name from hr_codedtl where code_type = 'HRA32' and to_number(code_no) < 100)
 )
  order by signman;

    CURSOR cursor2 IS
    --SELECT hre_empbas.e_mail
    SELECT 'ed'||hre_empbas.emp_no||'@edah.org.tw' AS e_mail
      FROM hr_codedtl, hre_empbas
     WHERE hre_empbas.organ_type = sOrganType and  (hr_codedtl.code_name = hre_empbas.emp_no) and
           ((hr_codedtl.code_type = 'HRA99') AND
           (hr_codedtl.code_no like 'C%'));

    CURSOR cursor3 IS
    with tb as (
		 select dept_no,signman from (
		   select dept_no,signman,cnt,Rank() over (Partition BY dept_no order by cnt desc,rownum) rnk from(
		     select dept_no,signman,count(dept_no) cnt from(
		     select dept_no,(select user_signman from hre_empbas where organ_type = sOrganType and emp_no = t2.emp_no) signman
		       from hre_empbas t2 where organ_type = sOrganType and disabled ='N' and (emp_flag='01' or dept_no = 'Z050')  and (job_lev <> 'R' or job_lev is null)
		     )
		      group by dept_no,signman
		   )
		 ) where rnk = 1
		 )
       select (select hrs_ym from hrs_ym where rownum = 1),
	      (select signman from tb where dept_no = hra_offovr.dept_no and rownum = 1),
        (select user_signman from hre_empbas where organ_type = sOrganType  and emp_no = (select signman from tb where dept_no = hra_offovr.dept_no and rownum = 1)),
		     DEPT_NO,'U',STR_YM,OVR_AVG,
         OVR_THS, OVR_YEL, OVR_RED,
         (select sum(mon_getadd + mon_addhrs+
           nvl((select sum(sotm_hrs) from hra_offrec where org_by = sOrganType and to_char(start_date, 'YYYY-MM') = t1.sch_ym and item_type ='A'
           and status = 'Y' and disabled='N' and otm_rea <> '1007' and dept_no = t1.dept_no and emp_no = t1.emp_no
		   ),0)-
           nvl((select sum(sotm_hrs) from hra_offrec where org_by = sOrganType and to_char(start_date, 'YYYY-MM') = t1.sch_ym and item_type ='O'
           and status = 'Y' and disabled='N' and  otm_rea <> '1013' and dept_no = t1.dept_no and emp_no = t1.emp_no
		   ),0)
					  ) attvalue from hra_attvac_view t1
	                  where t1.sch_ym = (select  to_char(to_date(hrs_ym || '-01','yyyy-mm-dd')-1,'yyyy-mm')  from hrs_ym)
					  and dept_no = hra_offovr.DEPT_NO) PREMON,
          (select sum(mon_getadd + mon_addhrs+
           nvl((select sum(sotm_hrs) from hra_offrec where org_by = sOrganType and  to_char(start_date, 'YYYY-MM') = t1.sch_ym and item_type ='A'
           and status = 'Y' and disabled='N' and otm_rea <> '1007' and dept_no = t1.dept_no and emp_no = t1.emp_no
		   ),0)-
           nvl((select sum(sotm_hrs) from hra_offrec where org_by = sOrganType and to_char(start_date, 'YYYY-MM') = t1.sch_ym and item_type ='O'
           and status = 'Y' and disabled='N' and  otm_rea <> '1013' and dept_no = t1.dept_no and emp_no = t1.emp_no
		   ),0)
					  ) attvalue from hra_attvac_view t1
	                  where organ_type = sOrganType and t1.sch_ym = (select hrs_ym from hrs_ym)
					  and dept_no = hra_offovr.DEPT_NO and emp_no not in (select code_name from hr_codedtl where code_type= 'HRA32' and code_no like '2%')) NOWMON
         from hra_offovr where organ_type = sOrganType and ovr_type = 'B' and create_res ='Y' and str_ym <> 'Z' ;

BEGIN
  RtnCode := 0;
  sOrganType := organtype_IN;

  select create_res
    into ichecked
    from hra_offovr
   where ovr_type = 'A'
     AND organ_type = sOrganType;

  IF (ichecked = 'Y') THEN

    OPEN cursor3;
      LOOP
     FETCH cursor3
      INTO qHrsym ,qSignman, qPermit_id ,qDeptno ,qStatus , qOvrtyp, qOvravg, qOvrths,qOvryel, qOvrred, qPremon, qNowmon;
      EXIT WHEN cursor3%NOTFOUND;

    insert into hra_offovrres (TRN_TM, SIGNMAN, PERMIT_ID, Permit_Status , DEPT_NO,
   STATUS, OVR_TYPE, OVR_AVG,
   OVR_THS, OVR_YEL, OVR_RED,
   NEED_REPLY,Keep_Premon,Keep_Thismon,
   CREATED_BY, CREATION_DATE,
   LAST_UPDATED_BY, LAST_UPDATE_DATE,org_By) VALUES
    (qHrsym ,qSignman, qPermit_id ,'N',qDeptno ,qStatus, qOvrtyp, qOvravg, qOvrths,qOvryel,
     qOvrred,
     'Y',qPremon,qNowmon,
     UpdateBy_IN,SYSDATE,UpdateBy_IN,SYSDATE,sOrganType);
    END LOOP;
    CLOSE cursor3;
    --修改控制不需要維護或替代資料
    update hra_offovrres
       set NEED_REPLY ='N'
     where TRN_TM = (select hrs_ym from hrs_ym where rownum = 1)
       and signman in (select code_name from hr_codedtl where code_type = 'HRA32' and to_number(code_no) < 100)
       and org_By = sOrganType  ;

    update hra_offovrres
       set signman = (select REMARK from hr_codedtl where code_type = 'HRA32' and to_number(code_no) between 100 and 199 and code_name = signman)
     where TRN_TM = (select hrs_ym from hrs_ym where rownum = 1)
       and signman in (select code_name from hr_codedtl where code_type = 'HRA32' and to_number(code_no) between 100 and 199)
       and org_By = sOrganType;

    update hra_offovrres set permit_id = null where  permit_id = '100003'
        and TRN_TM = (select hrs_ym from hrs_ym where rownum = 1)
        and org_By = sOrganType;
    --新增不需要回覆的資料供報表抓取
    insert into hra_offovrres(TRN_TM,org_by, SIGNMAN,Permit_Id , permit_status, DEPT_NO,
   STATUS, OVR_TYPE, OVR_AVG,
   OVR_THS, OVR_YEL, OVR_RED,
   NEED_REPLY,Keep_Premon,Keep_Thismon,
   CREATED_BY, CREATION_DATE,
   LAST_UPDATED_BY, LAST_UPDATE_DATE)
   (
   select (select hrs_ym from hrs_ym where rownum = 1),sOrganType,
	      'MIS' ,'MIS', 'Y' ,
		    DEPT_NO,'R',STR_YM,OVR_AVG,
         OVR_THS, OVR_YEL, OVR_RED,'N',
         (select sum(mon_getadd + mon_addhrs+
           nvl((select sum(sotm_hrs) from hra_offrec where org_by = sOrganType and to_char(start_date, 'YYYY-MM') = t1.sch_ym and item_type ='A'
           and status = 'Y' and disabled='N' and otm_rea <> '1007' and dept_no = t1.dept_no and emp_no = t1.emp_no
		   ),0)-
           nvl((select sum(sotm_hrs) from hra_offrec where org_by = sOrganType and to_char(start_date, 'YYYY-MM') = t1.sch_ym and item_type ='O'
           and status = 'Y' and disabled='N' and  otm_rea <> '1013' and dept_no = t1.dept_no and emp_no = t1.emp_no
		   ),0)
					  ) attvalue from hra_attvac_view t1
	                  where organ_type = sOrganType and t1.sch_ym = (select  to_char(to_date(hrs_ym || '-01','yyyy-mm-dd')-1,'yyyy-mm')  from hrs_ym)
					  and dept_no = hra_offovr.DEPT_NO) PREMON,
          (select sum(mon_getadd + mon_addhrs+
           nvl((select sum(sotm_hrs) from hra_offrec where org_by = sOrganType and to_char(start_date, 'YYYY-MM') = t1.sch_ym and item_type ='A'
           and status = 'Y' and disabled='N' and otm_rea <> '1007' and dept_no = t1.dept_no and emp_no = t1.emp_no
		   ),0)-
           nvl((select sum(sotm_hrs) from hra_offrec where org_by = sOrganType and to_char(start_date, 'YYYY-MM') = t1.sch_ym and item_type ='O'
           and status = 'Y' and disabled='N' and  otm_rea <> '1013' and dept_no = t1.dept_no and emp_no = t1.emp_no
		   ),0)
					  ) attvalue from hra_attvac_view t1
	                  where organ_type = sOrganType and t1.sch_ym = (select hrs_ym from hrs_ym)
					  and dept_no = hra_offovr.DEPT_NO) NOWMON
              ,UpdateBy_IN,SYSDATE,UpdateBy_IN,SYSDATE
         from hra_offovr where org_by = sOrganType and ovr_type = 'B' and DEPT_NO NOT IN (SELECT DEPT_NO FROM hra_offovrres WHERE org_by = sOrganType and TRN_TM = (select hrs_ym from hrs_ym where rownum = 1))
   );

    UPDATE hra_offovr set create_res = 'N' where create_res ='Y' and organ_type = sOrganType;


    COMMIT;

    OPEN cursor1;
      LOOP
     FETCH cursor1
      INTO dTrnym,dSignman ,dEmail ,dDeptno, dDeptname, dOvrtype;
      EXIT WHEN cursor1%NOTFOUND;


      IF (TRIM(dSignmanTmp) IS NULL OR dSignmanTmp <> dSignman) THEN
        IF TRIM(sMessageL) IS NOT NULL THEN
         --主管mail發送
         sMessageL := sMessageL ||'</table>' ;
         if (dEmailTmp <> 'ed100003@edah.org.tw') then --暫時移除特助
         null;
         ehrphrafunc_pkg.POST_HTML_MAIL('system@edah.org.tw',dEmailTmp,'ed101961@edah.org.tw','2','出勤管理-積借休異常通知', sMessageL);
         end if;
       END IF;
        sMessageL := '以下部門為' || dTrnym || '積借休異常，' ||
                     '若需回覆請主管們至MIS,出勤管理系統-出勤作業-積借休異常維護維護說明原因，謝謝！'||
                     '<table><tr><td>部門</td><td>部門名稱</td><td>異常情況</td><td>主管</td></tr>'||
                     '<tr><td>'||dDeptno||'</td><td>'||dDeptname||'</td><td>' || dOvrtype || '</td><td>' || dSignman || '</td></tr>';
      ELSE
        sMessageL := sMessageL || '<tr><td>'||dDeptno||'</td><td>'||dDeptname||'</td><td>' || dOvrtype || '</td><td>' || dSignman || '</td></tr>';
      END IF;
       -- 暫存上次的主管工號和MAIL
      dSignmanTmp := dSignman;
      dEmailTmp := dEmail;

      --組合管理者MAIL
      IF TRIM(pMessageL) IS NOT NULL THEN
         pMessageL := pMessageL || '<tr><td>'||dDeptno||'</td><td>'||dDeptname||'</td><td>' || dOvrtype || '</td><td>' || dSignman || '</td></tr>';
      ELSE
        pMessageL := '以下部門為' || dTrnym || '積借休異常，' ||
                     '<table><tr><td>部門</td><td>部門名稱</td><td>異常情況</td><td>主管</td></tr>'||
                     '<tr><td>'||dDeptno||'</td><td>'||dDeptname||'</td><td>' || dOvrtype || '</td><td>' || dSignman || '</td></tr>';
      END IF;
    END LOOP;
    CLOSE cursor1;
    --最後一位主管的MAIL發送
    IF TRIM(sMessageL) IS NOT NULL THEN
      sMessageL := sMessageL ||'</table>' ;
      if (dEmailTmp <> 'ed100003@edah.org.tw') then -- 暫時移除特助
      null;
      ehrphrafunc_pkg.POST_HTML_MAIL('system@edah.org.tw',dEmailTmp,'ed101961@edah.org.tw','2','出勤管理-積借休異常通知', sMessageL);
      end if;
    END IF;
    --管理者MAIL發送
    IF TRIM(pMessageL) IS NOT NULL THEN
      pMessageL := pMessageL ||'</table>' ;
      OPEN cursor2;
        LOOP
       FETCH cursor2
        INTO sEMail;
        EXIT WHEN cursor2%NOTFOUND;
          null;
          ehrphrafunc_pkg.POST_HTML_MAIL('system@edah.org.tw', sEMail,'ed101961@edah.org.tw','2','出勤管理-積借休異常通知', pMessageL);
       END LOOP;
       CLOSE cursor2;
    END IF;


  END IF;


end offrec_ovrtrans;

/*
FUNCTION getOffData(EmpNo_IN VARCHAR2, CloseDate_IN VARCHAR2) RETURN VARCHAR2 IS
    pYm          VARCHAR2(7);
    pClsHrs      NUMBER(5,1);
    pAppHrs      NUMBER(5,1);
    pSumClsHrs   NUMBER(5,1);
    pSumAppHrs   NUMBER(5,1);

    pOffAddHrs   NUMBER(5,1);
    pOffSubHrs   NUMBER(5,1);
    pOffSumHrs   NUMBER(5,1);

    pOffAppHrs   NUMBER(5,1);
    pOffClsHrs   NUMBER(5,1);
    --特簽結算
    pSumclos     NUMBER(5,1);
    sMessage VARCHAR2(200) := '';
    --
    pSumoneone   NUMBER(5,1);
    pSumonethreethree NUMBER(5,1);
    pSumonesixseven   NUMBER(5,1);
    pSumonetwo        NUMBER(5,1);
    --結算至前月班表與申請積借休資料
    CURSOR cursor1 IS
   select t1.sch_ym SCHYM,to_char(t1.mon_addhrs) MONADDHRS,
          to_char(nvl(nvl(t3.att_value,t2.att_value),0)-t1.mon_addhrs) APPVALUE
     from hra_offrec_cal t1,
          (select trn_ym,emp_no,att_code,att_value from hra_attdtl1
            where att_code = '204' and emp_no = EmpNo_IN and
                  trn_ym >= (select HRS_ALLOFFYM from hrs_ym where rownum = 1)) t2,
          (select trn_ym,emp_no,att_code,att_value from hra_attdtl1
            where att_code = '2040' and emp_no = EmpNo_IN and
                  trn_ym >= (select HRS_ALLOFFYM from hrs_ym where rownum = 1)) t3
     where t1.sch_ym = t2.trn_ym (+)
       and t1.sch_ym = t3.trn_ym (+)
       and t1.emp_no = EmpNo_IN
       and t1.sch_ym < substr(CloseDate_IN,1,7)
       and t1.sch_ym >= (select HRS_ALLOFFYM from hrs_ym where rownum = 1)
     order by t1.sch_ym;

   --回推之分類1:1,1:1.33,1:1:1.67
   pRevTotHrs  NUMBER(5,1);
   pRevHrs     NUMBER(5,1);
   pRevTmpHrs  NUMBER(5,1);
    CURSOR cursor2 IS
    select otm_hrs
      from hra_offrec where emp_no = EmpNo_IN
       and start_date >= to_date((select HRS_ALLOFFYM || '01' from hrs_ym where rownum = 1),'yyyy-mm-dd')
       and start_date < trunc(to_date(CloseDate_IN,'yyyy-mm-dd') + 1)
       and item_type ='A' and status = 'Y' and disabled='N'
       and  not (permit_id = 'edhr' and otm_rea = '1007')
  order by start_date desc;
  BEGIN
    pSumClsHrs := 0;
    pSumAppHrs := 0;

    pSumoneone := 0;
    pSumonethreethree := 0;
    pSumonesixseven := 0;
    pSumonetwo := 0;

    OPEN cursor1;
    LOOP
      FETCH cursor1
        INTO pYm, pClsHrs, pAppHrs;
      EXIT WHEN cursor1%NOTFOUND;
         pSumClsHrs := pSumClsHrs + pClsHrs;
         pSumAppHrs := pSumAppHrs + pAppHrs;
    END LOOP;
    CLOSE cursor1;

    --單月額外積休
    select nvl(sum(otm_hrs),0)
      into pOffAddHrs
      from hra_offrec where emp_no = EmpNo_IN
       and start_date >= to_date(substr(CloseDate_IN,1,7) || '01','yyyy-mm-dd')
       and start_date < trunc(to_date(CloseDate_IN,'yyyy-mm-dd') + 1)
       and item_type ='A' and status = 'Y' and disabled='N'
       and  not (permit_id = 'edhr' and otm_rea = '1007');

    --單月額外借休
   select nvl(sum(otm_hrs),0)
     into pOffSubHrs
     from hra_offrec where emp_no = EmpNo_IN
      and start_date >= to_date(substr(CloseDate_IN,1,7) || '01','yyyy-mm-dd')
      and start_date < trunc(to_date(CloseDate_IN,'yyyy-mm-dd') + 1)
      and item_type ='O' and status = 'Y' and disabled='N'
      and  otm_rea <> '1013';

      pOffSumHrs := pOffAddHrs - pOffSubHrs;

    --特簽結算資料
    select nvl(sum(clos_hrs),0)
      into pSumclos
      from hra_offclos
     where emp_no = EmpNo_IN
       and clos_ym > (select HRS_ALLOFFYM from hrs_ym where rownum = 1)
       and length(clos_ym) = 7;

    --申請=結算+單月(單月積休-單月借休),班表=結算-特簽
     pOffAppHrs := pSumAppHrs + pOffSumHrs;
     pOffClsHrs := pSumClsHrs - pSumclos;

     --總結小於等於0
     IF (pOffAppHrs + pOffClsHrs <= 0) THEN
       pSumoneone := pOffAppHrs + pOffClsHrs;
     --總結大於0
     ELSE
       --班表小於等於0
       IF (pOffClsHrs <= 0) THEN
         --總結推算exit
         pRevTotHrs := pOffAppHrs + pOffClsHrs;
         OPEN cursor2;
         LOOP
         FETCH cursor2
          INTO pRevHrs;
      EXIT WHEN cursor2%NOTFOUND;
      pRevTmpHrs := pRevHrs;
      IF (pRevTotHrs <= pRevTmpHrs) THEN
        pRevTmpHrs := pRevTotHrs;
      END IF;
      pRevTotHrs := pRevTotHrs - pRevTmpHrs;

      IF (pRevTmpHrs > 4) THEN
        pSumonetwo := pSumonetwo + (pRevTmpHrs - 4);
        pRevTmpHrs := 4;
      END IF;

      IF (pRevTmpHrs > 2) THEN
        pSumonesixseven := pSumonesixseven + (pRevTmpHrs - 2);
        pRevTmpHrs := 2;
      END IF;

      IF (pRevTmpHrs > 0) THEN
        pSumonethreethree := pSumonethreethree + pRevTmpHrs;
        pRevTmpHrs := 0;
      END IF;

      IF (pRevTotHrs <= 0) THEN
        EXIT;
      END IF;

    END LOOP;
    CLOSE cursor2;
       --班表大於0
       ELSE
         --總結小於等於班表
         IF (pOffAppHrs + pOffClsHrs <= pOffClsHrs) THEN
           pSumoneone := pOffAppHrs + pOffClsHrs;
         --總結大於班表
         ELSE
           pSumoneone := pOffClsHrs;
           --申請推算
           pRevTotHrs := pOffAppHrs;
           OPEN cursor2;
           LOOP
           FETCH cursor2
            INTO pRevHrs;
           EXIT WHEN cursor2%NOTFOUND;
           pRevTmpHrs := pRevHrs;
           IF (pRevTotHrs <= pRevTmpHrs) THEN
             pRevTmpHrs := pRevTotHrs;
           END IF;
           pRevTotHrs := pRevTotHrs - pRevTmpHrs;

           IF (pRevTmpHrs > 4) THEN
             pSumonetwo := pSumonetwo + (pRevTmpHrs - 4);
             pRevTmpHrs := 4;
           END IF;

           IF (pRevTmpHrs > 2) THEN
             pSumonesixseven := pSumonesixseven + (pRevTmpHrs - 2);
             pRevTmpHrs := 2;
           END IF;

           IF (pRevTmpHrs > 0) THEN
             pSumonethreethree := pSumonethreethree + pRevTmpHrs;
             pRevTmpHrs := 0;
           END IF;

           IF (pRevTotHrs <= 0) THEN
             EXIT;
           END IF;
           END LOOP;
           CLOSE cursor2;

         END IF;
       END IF;
     END IF;

    sMessage := '一比一時數:' || to_char(pSumoneone) || ',一比一點三三時數:' || to_char(pSumonethreethree) ||
                ',一比一點六七時數:' || to_char(pSumonesixseven) || ',一比二時數:' || to_char(pSumonetwo);
    RETURN sMessage;
  END getOffData;

PROCEDURE makeOffYsmData(LastUpdateBy_IN VARCHAR2,
                         RtnCode       OUT NUMBER) IS
    pStartdate   Date;
    pEnddate    Date;

    pEmpNo       VARCHAR2(20);
    pAppHrs   NUMBER(10,4);
    pClsHrs   NUMBER(10,4);


    --結算至前月班表與申請積借休資料
    CURSOR cursor1 IS
   select emp_no,apphrs,clshrs
     from hra_offrec_ysm t1
     where t1.sch_ym = to_char(pEnddate,'yyyy-mm')
     order by t1.sch_ym;

   --回推
   pOtmhrs     NUMBER(5,1);
   sEmpNo      VARCHAR2(20);
   sStartdate  DATE;
   sStartTime  VARCHAR2(4);
   sStatus     VARCHAR2(1);
   sItemType   VARCHAR2(1);
   sOtmhrs     NUMBER(5,1);

    CURSOR cursor2 IS
    select EMP_NO,START_DATE,START_TIME,STATUS,ITEM_TYPE,OTM_HRS
      from hra_offrec where emp_no = pEmpNo
       and start_date >= pStartdate
       and start_date <= pEnddate
       and item_type ='A' and status = 'Y' and disabled='N'
       and  not (permit_id = 'edhr' and otm_rea = '1007')
  order by start_date desc;
  BEGIN
    RtnCode := 0;

    Select to_date((select HRS_ALLOFFYM from hrs_ym where rownum = 1) || '01','yyyy-mm-dd')
      into pStartdate
      from dual;

    Select last_day(to_date((select max(sch_ym) from hra_offrec_cal) || '01','yyyy-mm-dd'))
      into pEnddate
      from dual;


    INSERT INTO HRA_OFFREC_YSM (SCH_YM, EMP_NO,
      DEPT_NO,
      SCH_DATE, APPHRS, CLSHRS, SPEHRS,
      DUTI_APP, DUTI_CLS, UNDU_APP, UNDU_CLS,
      CREATED_BY, CREATION_DATE, LAST_UPDATED_BY, LAST_UPDATE_DATE)
      (SELECT to_char(pEnddate,'yyyy-mm'),EMP_NO,
              (SELECT DEPT_NO FROM HRE_EMPBAS WHERE EMP_NO = t2.EMP_NO),
              SYSDATE,NVL(ADDS,0)-NVL(MINUSS,0),NVL(CLSHRS,0),NVL(SPEHRS,0),
              0,0,0,0,
              LastUpdateBy_IN,SYSDATE,LastUpdateBy_IN,SYSDATE
         FROM (select emp_no,sum(mon_addhrs-mon_specal) clshrs,
                  (select tot_hrs from hra_offclos where emp_no = t1.emp_no and clos_ym ='2010-9') spehrs,
                  (select nvl(sum(otm_hrs),0)
                     from hra_offrec where emp_no = t1.emp_no
                      and start_date >= pStartdate
                      and start_date <= pEnddate
                      and item_type ='A' and status = 'Y' and disabled='N'
                      and  not (permit_id = 'edhr' and otm_rea = '1007')
	           ) adds,
                   (select nvl(sum(otm_hrs),0)
                      from hra_offrec where emp_no = t1.emp_no
                       and start_date >= pStartdate
                       and start_date <= pEnddate
                       and item_type ='O' and status = 'Y' and disabled='N'
                       and  otm_rea <> '1013'
	            ) minuss
                from hra_offrec_cal t1
               where t1.sch_ym >= to_char(pStartdate,'yyyy-mm')
	         and disabled ='N'
            group by emp_no)  t2
      );

    OPEN cursor1;
    LOOP
      FETCH cursor1
        INTO pEmpNo,pAppHrs, pClsHrs;
      EXIT WHEN cursor1%NOTFOUND;
     --總結小於等於0
      IF (pAppHrs+pClsHrs <= 0) THEN
        update hra_offrec
           set rem_hrs = 0,
               REM_DATE = SYSDATE
         where emp_no = pEmpNo
           and start_date >= pStartdate
           and start_date <= pEnddate
           and item_type ='A' and status = 'Y' and disabled='N'
           and  not (permit_id = 'edhr' and otm_rea = '1007');
      ELSE
      --總結大於0

       --班表大於0
       IF (pClsHrs > 0) THEN
         --總結小於等於班表
         IF (pAppHrs + pClsHrs <= pClsHrs) THEN
           update hra_offrec
              set rem_hrs = 0,
                  REM_DATE = SYSDATE
            where emp_no = pEmpNo
              and start_date >= pStartdate
              and start_date <= pEnddate
              and item_type ='A' and status = 'Y' and disabled='N'
              and  not (permit_id = 'edhr' and otm_rea = '1007');
         ELSE
         --總結大於班表,需用申請推算回壓剩餘時數
           pOtmhrs := pAppHrs;
             OPEN cursor2;
             LOOP
             FETCH cursor2
               INTO sEmpNo,sStartdate,sStartTime,sStatus,sItemType,sOtmhrs;
             EXIT WHEN cursor2%NOTFOUND;
               IF (pOtmhrs >= sOtmhrs) THEN
                 UPDATE hra_offrec
                    SET rem_hrs = sOtmhrs,
                        REM_DATE = SYSDATE
                  where emp_no = sEmpNo
                    and start_date = sStartdate
                    and start_time = sStartTime
                    and status = sStatus
                    and item_type = sItemType;
               ELSE
                 IF (pOtmhrs > 0) THEN
                 UPDATE hra_offrec
                    SET rem_hrs = pOtmhrs,
                        REM_DATE = SYSDATE
                  where emp_no = sEmpNo
                    and start_date = sStartdate
                    and start_time = sStartTime
                    and status = sStatus
                    and item_type = sItemType;
                 ELSE
                   pOtmhrs := 0;
                 UPDATE hra_offrec
                    SET rem_hrs = 0,
                        REM_DATE = SYSDATE
                  where emp_no = sEmpNo
                    and start_date = sStartdate
                    and start_time = sStartTime
                    and status = sStatus
                    and item_type = sItemType;
                  END IF;
               END IF;
               pOtmhrs := pOtmhrs - sOtmhrs;

             END LOOP;
             CLOSE cursor2;

         END IF;

       ELSE
       --班表小於等於0,需用總結推算回壓剩餘時數
       pOtmhrs := pAppHrs+pClsHrs;
             OPEN cursor2;
             LOOP
             FETCH cursor2
               INTO sEmpNo,sStartdate,sStartTime,sStatus,sItemType,sOtmhrs;
             EXIT WHEN cursor2%NOTFOUND;
               IF (pOtmhrs >= sOtmhrs) THEN
                 UPDATE hra_offrec
                    SET rem_hrs = sOtmhrs,
                        REM_DATE = SYSDATE
                  where emp_no = sEmpNo
                    and start_date = sStartdate
                    and start_time = sStartTime
                    and status = sStatus
                    and item_type = sItemType;
               ELSE
                 IF (pOtmhrs > 0) THEN
                 UPDATE hra_offrec
                    SET rem_hrs = pOtmhrs,
                        REM_DATE = SYSDATE
                  where emp_no = sEmpNo
                    and start_date = sStartdate
                    and start_time = sStartTime
                    and status = sStatus
                    and item_type = sItemType;
                 ELSE
                   pOtmhrs := 0;
                 UPDATE hra_offrec
                    SET rem_hrs = 0,
                        REM_DATE = SYSDATE
                  where emp_no = sEmpNo
                    and start_date = sStartdate
                    and start_time = sStartTime
                    and status = sStatus
                    and item_type = sItemType;
                  END IF;
               END IF;
               pOtmhrs := pOtmhrs - sOtmhrs;

             END LOOP;
             CLOSE cursor2;
       END IF;
      END IF;


    END LOOP;
    CLOSE cursor1;
    commit;

  END makeOffYsmData;
  */
  /*
  *取得3個月加班和積休時數 20180222 108978
  */
   FUNCTION Check3MonthOtmhrs(p_emp_no     VARCHAR2,
                              p_start_date VARCHAR2,
                              p_otm_hrs    VARCHAR2,
                              OrganType_IN VARCHAR2 ) RETURN NUMBER IS

    RtnCode      NUMBER(4);
    sOtmhrs      NUMBER := TO_NUMBER(p_otm_hrs);    
    sTotMonAdd   NUMBER; --當月加班費總時數(含在途)
	  sOtmsignHrs  NUMBER;  --當月加班補休時數(含在途)
	  sMonClassAdd NUMBER; -- 當月班表超時

    BEGIN
    RtnCode :=0;
    
    BEGIN
  	  SELECT  SUM(decode(s_class , 'ZZ',(soneott+soneoss+soneuu),'ZQ',(soneott+soneoss+soneuu),'ZY',(soneott+soneoss+soneuu),sotm_Hrs))
  		  INTO  sTotMonAdd  -- 當月積休單總時數(含在途)
    	  FROM  (
          SELECT (select class_code
                    from hra_classsch_view
                   where emp_no = HRA_OFFREC.Emp_No
                     and att_date = to_char(NVL(Start_Date_Tmp,start_date), 'yyyy-mm-dd')) as s_class,                
                 otm_hrs,
                 soneo,
                 soneott,
                 soneoss,
                 sotm_hrs,
                 soneuu
            FROM HRA_OFFREC
           WHERE TO_CHAR(NVL(Start_Date_Tmp,start_date),'yyyymm') >= TO_CHAR( add_months( to_date(p_start_date,'yyyy-mm-dd'), -2),'yyyymm') 
             AND TO_CHAR(NVL(Start_Date_Tmp,start_date),'yyyymm') <= TO_CHAR(to_date(p_start_date,'yyyy-mm-dd'),'yyyymm') 
             AND status <> 'N'
             AND item_type = 'A'
             AND emp_no = p_emp_no) tt;
  	EXCEPTION WHEN NO_DATA_FOUND THEN
      sTotMonAdd := 0 ;
  	END;
    
    IF sTotMonAdd IS NULL THEN
      sTotMonAdd := 0;
    END IF;

    BEGIN
    	SELECT NVL(SUM(OTM_HRS),0)
    	  INTO sOtmsignHrs  -- 3個月加班單總時數(含在途)
    		FROM HRA_OTMSIGN
       WHERE TO_CHAR(NVL(Start_Date_Tmp,start_date),'yyyymm') >= TO_CHAR( add_months( to_date(p_start_date,'yyyy-mm-dd'), -2),'yyyymm')
         AND TO_CHAR(NVL(Start_Date_Tmp,start_date),'yyyymm') <= TO_CHAR(to_date(p_start_date,'yyyy-mm-dd'),'yyyymm') 
         AND status <> 'N'
         AND otm_flag = 'B'
         AND emp_no = p_emp_no;
    EXCEPTION WHEN NO_DATA_FOUND THEN
      sOtmsignHrs := 0 ;
    END;
    
    IF sOtmsignHrs IS NULL THEN
      sOtmsignHrs := 0;
    END IF;

	  BEGIN
	    SELECT (mon_getadd + mon_addhrs   + mon_spcotm -  mon_cutotm + mon_dutyhrs )
		    INTO  sMonClassAdd --當月排班超時
        FROM hra_attvac_view
       WHERE hra_attvac_view.sch_ym = TO_CHAR(to_date(p_start_date,'yyyy-mm-dd'),'yyyy-mm') 
		     AND hra_attvac_view.emp_no = p_emp_no ;
	  EXCEPTION WHEN NO_DATA_FOUND THEN
      sMonClassAdd := 0 ;
	  END;

      --IF   (sOtmsignHrs+sTotMonAdd+sMonClassAdd+sOtmhrs >= 138) THEN
      --20190225 by108482 需求單IMP201901037 加班超過138小時不計算當月排班超時工時
      IF   (sOtmsignHrs+sTotMonAdd+sOtmhrs > 138) THEN
        dbms_output.put_line('p_emp_no'||p_emp_no);
        --dbms_output.put_line('OTM_HRS'||TO_CHAR(sOtmsignHrs+sTotMonAdd+sMonClassAdd+sOtmhrs));
        dbms_output.put_line('OTM_HRS'||TO_CHAR(sOtmsignHrs+sTotMonAdd+sOtmhrs));
	        RtnCode := 16 ;
       GOTO Continue_ForEach1 ;
      ELSE
        RtnCode := 0 ;
      END IF;

      NULL;
      <<Continue_ForEach1>>
      NULL;

    RETURN RtnCode;

  END Check3MonthOtmhrs;
    
  PROCEDURE UpdateSupdtl(SUPNO_IN VARCHAR2,
                         EMPNO_IN VARCHAR2) AS
    ccunt NUMBER;
  BEGIN
    ccunt := 0;
  
    BEGIN
      SELECT COUNT(*)
        INTO ccunt
        FROM hra_supdtl
       WHERE status = 'Y'
         AND sup_no = SUPNO_IN;
    EXCEPTION WHEN no_data_found THEN
      ccunt := 0;
    END;
    
    IF ccunt <> 0 THEN
      UPDATE hra_supdtl
         SET status = 'N',
             last_updated_by = EMPNO_IN,
             last_update_date = SYSDATE
       WHERE sup_no = SUPNO_IN;
    END IF;
    COMMIT;
  EXCEPTION WHEN OTHERS THEN
    ROLLBACK WORK;
    Ehrphrafunc_Pkg.Post_Html_Mail('system@edah.org.tw','ed108482@edah.org.tw','','1','補休退回調整明細作業(異常)',
                                   '執行EHRPHRA12_PKG.PROCEDURE UpdateSupdtl，但SQLCODE='||SQLCODE);
  END UpdateSupdtl;
  
  PROCEDURE Delete_DeputySup(EmpNo_IN     VARCHAR2,
                             StartDate_IN VARCHAR2,
                             EndDate_IN   VARCHAR2) AS
    CNT NUMBER; --確認是否有代理資料
  BEGIN
    CNT := 0;
    BEGIN
    SELECT COUNT(*)
      INTO CNT
      FROM HRE_DEPUTY
     WHERE EMP_NO = EmpNo_IN
       AND TO_CHAR(EFFECT_DATE, 'yyyy-mm-dd') = StartDate_IN
       AND TO_CHAR(EXPIRE_DATE, 'yyyy-mm-dd') = EndDate_IN;
    EXCEPTION WHEN OTHERS THEN
      CNT := 0;
    END;
    IF CNT <> 0 THEN
      DELETE FROM HRE_DEPUTY
       WHERE EMP_NO = EmpNo_IN
         AND TO_CHAR(EFFECT_DATE, 'yyyy-mm-dd') = StartDate_IN
         AND TO_CHAR(EXPIRE_DATE, 'yyyy-mm-dd') = EndDate_IN;
      COMMIT;
    END IF;
  END Delete_DeputySup;
  
  PROCEDURE Update_DeputySup(EmpNo_IN     VARCHAR2,
                             StartDate_IN VARCHAR2,
                             EndDate_IN   VARCHAR2,
                             Status_IN    VARCHAR2,
                             Update_IN    VARCHAR2) AS
    CNT NUMBER;
  BEGIN
    CNT := 0;
    BEGIN
    SELECT COUNT(*)
      INTO CNT
      FROM HRE_DEPUTY
     WHERE EMP_NO = EmpNo_IN
       AND TO_CHAR(EFFECT_DATE, 'yyyy-mm-dd') = StartDate_IN
       AND TO_CHAR(EXPIRE_DATE, 'yyyy-mm-dd') = EndDate_IN;
    EXCEPTION WHEN OTHERS THEN
      CNT := 0;
    END;
    
    IF CNT <> 0 AND Status_IN IN ('D','N') THEN
      UPDATE HRE_DEPUTY
         SET DISABLED         = 'Y',
             LAST_UPDATED_BY  = Update_IN,
             LAST_UPDATE_DATE = SYSDATE
       WHERE EMP_NO = EmpNo_IN
         AND TO_CHAR(EFFECT_DATE, 'yyyy-mm-dd') = StartDate_IN
         AND TO_CHAR(EXPIRE_DATE, 'yyyy-mm-dd') = EndDate_IN;
    ELSIF CNT <> 0 AND Status_IN IN ('Y') THEN
      UPDATE HRE_DEPUTY
         SET DISABLED         = 'N',
             LAST_UPDATED_BY  = Update_IN,
             LAST_UPDATE_DATE = SYSDATE
       WHERE EMP_NO = EmpNo_IN
         AND TO_CHAR(EFFECT_DATE, 'yyyy-mm-dd') = StartDate_IN
         AND TO_CHAR(EXPIRE_DATE, 'yyyy-mm-dd') = EndDate_IN;
    END IF;
    COMMIT;
  END Update_DeputySup;
  
END EHRPHRA12_PKG; 
