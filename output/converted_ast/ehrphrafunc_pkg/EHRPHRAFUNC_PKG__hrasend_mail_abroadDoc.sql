CREATE OR ALTER PROCEDURE [ehrphrafunc_pkg].[hrasend_mail_abroadDoc]
AS
DECLARE @pempno NVARCHAR(20);
DECLARE @pchname NVARCHAR(200);
DECLARE @pdeptname NVARCHAR(60);
DECLARE @pposname NVARCHAR(60);
DECLARE @pvacname NVARCHAR(60);
DECLARE @pstatusname NVARCHAR(10);
DECLARE @psd NVARCHAR(10);
DECLARE @pst NVARCHAR(4);
DECLARE @ped NVARCHAR(10);
DECLARE @pet NVARCHAR(4);
DECLARE @pevcrea NVARCHAR(200);
DECLARE @pvacdays SMALLINT;
DECLARE @pvachrs DECIMAL(4,1);
DECLARE @prm NVARCHAR(300);
DECLARE @pevcday NVARCHAR(100);
DECLARE @plastvacday NVARCHAR(100);
DECLARE @pevc_u NVARCHAR(100);
DECLARE @pevc_f NVARCHAR(100);
DECLARE @pevc_s NVARCHAR(100);
DECLARE @pabroad NVARCHAR(10);
DECLARE @porgantype NVARCHAR(100);
DECLARE @pposlevel SMALLINT;
DECLARE @sTitle NVARCHAR(100);
DECLARE @sEEMail NVARCHAR(120);
DECLARE @__exec_title1 NVARCHAR(MAX);
DECLARE @__exec_title2 NVARCHAR(MAX);
DECLARE @sMessage NVARCHAR(MAX);
DECLARE @sMessageDoc NVARCHAR(MAX);
DECLARE @sMessageDoc2 NVARCHAR(MAX);
DECLARE @sMessageMail NVARCHAR(MAX);
DECLARE @nconti SMALLINT;
DECLARE @pCONTIEVCNO NVARCHAR(20);
DECLARE @psd2 NVARCHAR(10);
DECLARE @nconti2 SMALLINT;
DECLARE @ErrorCode DECIMAL(38,10);
DECLARE @ErrorMessage NVARCHAR(500);
DECLARE cursor1 CURSOR FOR
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
             (SELECT ISNULL(FLOOR(SUM(VAC_DAYS * 8 + VAC_HRS) / 8), '0') + '天' +
                     ISNULL((SUM(VAC_DAYS * 8 + VAC_HRS) % 8), '0') + '時'
                FROM HRP.HRA_EVCREC
               WHERE VAC_TYPE = 'V'
                 AND EMP_NO = ta.EMP_NO
                 AND ORG_BY = ta.ORG_BY
                 AND STATUS IN ('Y', 'U')
                 AND FORMAT(START_DATE, 'yyyy') = FORMAT(GETDATE(), 'yyyy')
                 AND TRANS_FLAG = 'N') V_U_DAY,
             
             (SELECT ISNULL(FLOOR(SUM(VAC_DAYS * 8 + VAC_HRS) / 8), '0') + '天' +
                     ISNULL((SUM(VAC_DAYS * 8 + VAC_HRS) % 8), '0') + '時'
                FROM HRP.HRA_EVCREC
               WHERE VAC_TYPE = 'S'
                 AND EMP_NO = ta.EMP_NO
                 AND ORG_BY = ta.ORG_BY
                 AND STATUS IN ('Y', 'U')
                 AND FORMAT(START_DATE, 'yyyy') = FORMAT(GETDATE(), 'yyyy')
                 AND TRANS_FLAG = 'N') S_U_DAY,
             
             (SELECT ISNULL(FLOOR(SUM(VAC_DAYS * 8 + VAC_HRS) / 8), '0') + '天' +
                     ISNULL((SUM(VAC_DAYS * 8 + VAC_HRS) % 8), '0') + '時'
                FROM HRP.HRA_EVCREC
               WHERE VAC_TYPE = 'F'
                 AND EMP_NO = ta.EMP_NO
                 AND ORG_BY = ta.ORG_BY
                 AND STATUS IN ('Y', 'U')
                 AND FORMAT(START_DATE, 'yyyy') = FORMAT(GETDATE(), 'yyyy')
                 AND TRANS_FLAG = 'N') F_U_DAY,
             abroad,
             CASE WHEN tb.organ_type = 'ED' THEN '義大' WHEN tb.organ_type = 'EC' THEN '癌醫' WHEN tb.organ_type = 'EF' THEN '大昌' WHEN tb.organ_type = 'EG' THEN '護理之家' WHEN tb.organ_type = 'EK' THEN '產後護理' WHEN tb.organ_type = 'EH' THEN '居護所' WHEN tb.organ_type = 'EL' THEN '貝思諾' END ORGANTYPE,
             
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
                             FORMAT(start_date, 'yyyy-mm-dd') sd,
                             start_time st,
                             FORMAT(end_date, 'yyyy-mm-dd') ed,
                             end_time et,
                             evc_rea,
                             vac_days,
                             vac_hrs,
                             remark,
                             abroad
                        FROM HRA_EVCREC t1
                       WHERE status IN ('Y', 'U')) AS _dt1
               WHERE ((sd BETWEEN FORMAT(GETDATE(), 'yyyy-mm-dd') AND
                     FORMAT(DATEADD(DAY, 7, GETDATE()), 'yyyy-mm-dd')) OR
                     (ed BETWEEN FORMAT(GETDATE(), 'yyyy-mm-dd') AND
                     FORMAT(DATEADD(DAY, 7, GETDATE()), 'yyyy-mm-dd')) OR
                     (sd <= FORMAT(GETDATE(), 'yyyy-mm-dd') AND
                     ed >= FORMAT(DATEADD(DAY, 7, GETDATE()), 'yyyy-mm-dd')))
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
                             FORMAT(start_date, 'yyyy-mm-dd') sd,
                             start_time st,
                             FORMAT(end_date, 'yyyy-mm-dd') ed,
                             end_time et,
                             OTM_REA evc_rea,
                             0 vac_days,
                             otm_hrs vac_hrs,
                             remark,
                             abroad
                        FROM HRA_OFFREC t1
                       WHERE item_type = 'O'
                         AND status IN ('Y', 'U')) AS _dt2
               WHERE ((sd BETWEEN FORMAT(GETDATE(), 'yyyy-mm-dd') AND
                     FORMAT(DATEADD(DAY, 7, GETDATE()), 'yyyy-mm-dd')) OR
                     (ed BETWEEN FORMAT(GETDATE(), 'yyyy-mm-dd') AND
                     FORMAT(DATEADD(DAY, 7, GETDATE()), 'yyyy-mm-dd')) OR
                     (sd <= FORMAT(GETDATE(), 'yyyy-mm-dd') AND
                     ed >= FORMAT(DATEADD(DAY, 7, GETDATE()), 'yyyy-mm-dd')))
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
                             FORMAT(start_date, 'yyyy-mm-dd') sd,
                             start_time st,
                             FORMAT(end_date, 'yyyy-mm-dd') ed,
                             end_time et,
                             sup_rea evc_rea,
                             0 vac_days,
                             SUP_HRS vac_hrs,
                             remark,
                             abroad
                        FROM HRA_SUPMST t1
                       WHERE status IN ('Y', 'U')) AS _dt3
               WHERE ((sd BETWEEN FORMAT(GETDATE(), 'yyyy-mm-dd') AND
                     FORMAT(DATEADD(DAY, 7, GETDATE()), 'yyyy-mm-dd')) OR
                     (ed BETWEEN FORMAT(GETDATE(), 'yyyy-mm-dd') AND
                     FORMAT(DATEADD(DAY, 7, GETDATE()), 'yyyy-mm-dd')) OR
                     (sd <= FORMAT(GETDATE(), 'yyyy-mm-dd') AND
                     ed >= FORMAT(DATEADD(DAY, 7, GETDATE()), 'yyyy-mm-dd')))
                 AND abroad IN ('Y')) ta,
             HRE_EMPBAS tb,
             hra_yearvac tc
       WHERE ta.emp_no = tb.emp_no
         and ta.org_by = tb.organ_type
         AND ta.emp_no = tc.emp_no
         AND tc.vac_year = FORMAT(GETDATE(), 'yyyy')
       ORDER BY ta.sd,
                (SELECT pos_level FROM HRE_POSMST WHERE pos_no = tb.pos_no) DESC,
                ta.emp_no;
DECLARE cursor2 CURSOR FOR
    SELECT 'ed108154@edah.org.tw'
        FROM dual 
      UNION ALL
      SELECT 'ed108482@edah.org.tw'
        FROM dual 
      UNION ALL
      SELECT 'ed100037@edah.org.tw'
        FROM dual 
      UNION ALL
      SELECT 'ed100054@edah.org.tw'
        FROM dual 
      UNION ALL
      SELECT 'ed100005@edah.org.tw'
        FROM dual 
      UNION ALL
      SELECT 'ed105094@edah.org.tw' 
        FROM dual;
DECLARE CURSOR3 CURSOR FOR
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
             END statusname, 
             FORMAT(A.START_DATE, 'yyyy-MM-dd'),
             A.START_TIME,
             FORMAT(A.END_DATE, 'yyyy-MM-dd'),
             A.END_TIME,
             F.Rul_Name, 
             A.VAC_DAYS,
             A.VAC_HRS,
             A.REMARK,
             '', 
             '', 
             '', 
             '', 
             '', 
             A.Abroad,
             CASE WHEN B.ORGAN_TYPE = 'ED' THEN '義大' WHEN B.ORGAN_TYPE = 'EC' THEN '癌醫' WHEN B.ORGAN_TYPE = 'EF' THEN '大昌' END ORGANTYPE,
             E.Pos_Level,
             CONTI_EVCNO
        FROM HRA_DEVCREC  A,
             HRE_EMPBAS   B,
             HRE_ORGBAS   C,
             HRA_DVCRLMST D,
             HRE_POSMST   E,
             HRA_DVCRLDTL F
       WHERE A.STATUS <> 'N'
         AND ((FORMAT(A.START_DATE, 'yyyy-MM-dd') BETWEEN
             FORMAT(GETDATE(), 'yyyy-MM-dd') AND
             FORMAT(DATEADD(DAY, 7, GETDATE()), 'yyyy-MM-dd')) OR
             (FORMAT(A.END_DATE, 'yyyy-MM-dd') BETWEEN
             FORMAT(GETDATE(), 'yyyy-MM-dd') AND
             FORMAT(DATEADD(DAY, 7, GETDATE()), 'yyyy-MM-dd')) OR
             (FORMAT(A.START_DATE, 'yyyy-MM-dd') <=
             FORMAT(GETDATE(), 'yyyy-MM-dd') AND
             FORMAT(A.END_DATE, 'yyyy-MM-dd') >=
             FORMAT(DATEADD(DAY, 7, GETDATE()), 'yyyy-MM-dd')))
         AND A.EMP_NO = B.EMP_NO
         AND B.DEPT_NO = C.DEPT_NO
         AND A.VAC_TYPE = D.VAC_TYPE
         AND D.VAC_TYPE = F.VAC_TYPE
         AND A.VAC_RUL = F.VAC_RUL
         AND B.POS_NO = E.POS_NO
         AND A.ABROAD = 'Y'
         AND A.DIS_ALL = 'N'
         AND ((A.DIS_SD IS NULL) OR ((FORMAT(A.DIS_SD, 'yyyy-MM-dd') >
             FORMAT(GETDATE(), 'yyyy-MM-dd')) OR
             (FORMAT(A.DIS_ED, 'yyyy-MM-dd') <
             FORMAT(GETDATE(), 'yyyy-MM-dd'))))
       ORDER BY A.Start_Date, E.Pos_Level DESC, A.EMP_NO;
BEGIN
BEGIN TRY
    SET @sMessage = '';
    SET @sMessageDoc = '';
    SET @sMessageDoc2 = '';
  
    OPEN cursor3;
    WHILE 1=1 BEGIN
      FETCH NEXT FROM cursor3 INTO @pempno, @pchname, @pdeptname, @pposname, @pvacname, @pstatusname, @psd, @pst, @ped, @pet, @pevcrea, @pvacdays, @pvachrs, @prm, @pevcday, @plastvacday, @pevc_u, @pevc_s, @pevc_f, @pabroad, @porgantype, @pposlevel, @pCONTIEVCNO;
      IF @@FETCH_STATUS <> 0 BREAK;
      SET @nconti = 0;
      SET @nconti2 = 0;
      --check 跨月出國假單
      SELECT @nconti = count(*)
    FROM hra_devcrec
       WHERE emp_no = @pempno
         AND start_date > GETDATE()
         AND abroad = 'Y'
         AND FORMAT(start_date, 'yyyy-mm-dd') = @psd
         AND CONTI_EVCNO IN (SELECT evc_no
                               FROM hra_devcrec
                              WHERE evc_no = @pCONTIEVCNO
                                AND dis_all = 'N');
    
      --20221018 by108482 check 連續假卡是否已經出國
      IF @pCONTIEVCNO IS NOT NULL BEGIN
      
        BEGIN TRY
    SELECT @psd2 = FORMAT(start_date, 'yyyy-mm-dd')
    FROM hra_devcrec
           WHERE evc_no = @pCONTIEVCNO
             AND dis_all = 'N';
END TRY
BEGIN CATCH
    -- WHEN OTHERS
    SET @psd2 = '';
END CATCH
      
        IF @psd > @psd2 BEGIN
          IF @psd2 <= FORMAT(GETDATE(), 'yyyy-mm-dd') BEGIN
            SET @nconti2 = 1;
          END
          ELSE
          BEGIN
            SET @nconti2 = 0;
          END
        END
        ELSE
        BEGIN
          IF @psd <= FORMAT(GETDATE(), 'yyyy-mm-dd') BEGIN
            SET @nconti2 = 1;
          END
          ELSE
          BEGIN
            SET @nconti2 = 0;
          END
        END
      END
    
      IF @psd <= FORMAT(GETDATE(), 'yyyy-mm-dd') OR
         (@nconti <> 0 AND @nconti2 <> 0) BEGIN
        SET @pabroad = @pabroad + '-已出';
      END
      ELSE
      BEGIN
        SET @pabroad = @pabroad + '-未出';
      END
    
      IF @sMessageDoc is null BEGIN
        SET @sMessageDoc = '<table border="1" width="100%">';
        SET @sMessageDoc = @sMessageDoc + '<tr><td colspan="17" ><BR>' +
                       '==========(醫師出國假單)==========' +
                       '<BR><BR></tr></tr>';
        SET @sMessageDoc = @sMessageDoc +
                       '<TR><TD>機構</td><TD>工號</td><TD>姓名</td><TD>部門名稱</td><TD>職稱</td><TD>職等</td><TD>假別</td>';
      
        SET @sMessageDoc = @sMessageDoc +
                       '<TD>狀態</td><TD>開始日期</td><TD>開始時間</td><TD>結束日期</td><TD>結束時間</td>';
        SET @sMessageDoc = @sMessageDoc +
                       '<TD>天數</td><TD>時數</td><TD>請假理由</td><TD>其他原因</td><TD>出國</td>';
        SET @sMessageDoc = @sMessageDoc + '<TR><TD>' + @porgantype +
                       '</td><TD>' + @pempno + '</td><TD>' + @pchname +
                       '</td><TD>' + @pdeptname + '</td>';
        SET @sMessageDoc = @sMessageDoc + '<TD>' + @pposname + '</td><TD>' +
                       @pposlevel + '</td><TD>' + @pvacname + '</td><TD>' +
                       @pstatusname + '</td>';
        SET @sMessageDoc = @sMessageDoc + '<TD>' + @psd + '</td><TD>' + @pst +
                       '</td><TD>' + @ped + '</td>';
        SET @sMessageDoc = @sMessageDoc + '<TD>' + @pet + '</td><TD>' +
                       @pvacdays + '</td><TD>' + @pvachrs + '</td>';
        SET @sMessageDoc = @sMessageDoc + '<TD>' + @pevcrea + '</td><TD>' + @prm +
                       '</td><TD>' + @pabroad + '</td></tr>';
      END
ELSE IF LEN(@sMessageDoc) < 19000 BEGIN 
        SET @sMessageDoc = @sMessageDoc + '<TR><TD>' + @porgantype +
                       '</td><TD>' + @pempno + '</td><TD>' + @pchname +
                       '</td><TD>' + @pdeptname + '</td>';
        SET @sMessageDoc = @sMessageDoc + '<TD>' + @pposname + '</td><TD>' +
                       @pposlevel + '</td><TD>' + @pvacname + '</td><TD>' +
                       @pstatusname + '</td>';
        SET @sMessageDoc = @sMessageDoc + '<TD>' + @psd + '</td><TD>' + @pst +
                       '</td><TD>' + @ped + '</td>';
        SET @sMessageDoc = @sMessageDoc + '<TD>' + @pet + '</td><TD>' +
                       @pvacdays + '</td><TD>' + @pvachrs + '</td>';
        SET @sMessageDoc = @sMessageDoc + '<TD>' + @pevcrea + '</td><TD>' + @prm +
                       '</td><TD>' + @pabroad + '</td></tr>';
      END
ELSE IF LEN(@sMessageDoc) > 19000 BEGIN 
        IF @sMessageDoc2 IS NULL BEGIN
          SET @sMessageDoc2 = '<table border="1" width="100%">';
          SET @sMessageDoc2 = @sMessageDoc2 + '<tr><td colspan="17" ><BR>' +
                          '==========(醫師出國假單,接續前一封)==========' +
                          '<BR><BR></tr></tr>';
          SET @sMessageDoc2 = @sMessageDoc2 +
                          '<TR><TD>機構</td><TD>工號</td><TD>姓名</td><TD>部門名稱</td><TD>職稱</td><TD>職等</td><TD>假別</td>';
          SET @sMessageDoc2 = @sMessageDoc2 +
                          '<TD>狀態</td><TD>開始日期</td><TD>開始時間</td><TD>結束日期</td><TD>結束時間</td>';
          SET @sMessageDoc2 = @sMessageDoc2 +
                          '<TD>天數</td><TD>時數</td><TD>請假理由</td><TD>其他原因</td><TD>出國</td>';
          SET @sMessageDoc2 = @sMessageDoc2 + '<TR><TD>' + @porgantype +
                          '</td><TD>' + @pempno + '</td><TD>' + @pchname +
                          '</td><TD>' + @pdeptname + '</td>';
          SET @sMessageDoc2 = @sMessageDoc2 + '<TD>' + @pposname + '</td><TD>' +
                          @pposlevel + '</td><TD>' + @pvacname + '</td><TD>' +
                          @pstatusname + '</td>';
          SET @sMessageDoc2 = @sMessageDoc2 + '<TD>' + @psd + '</td><TD>' + @pst +
                          '</td><TD>' + @ped + '</td>';
          SET @sMessageDoc2 = @sMessageDoc2 + '<TD>' + @pet + '</td><TD>' +
                          @pvacdays + '</td><TD>' + @pvachrs + '</td>';
          SET @sMessageDoc2 = @sMessageDoc2 + '<TD>' + @pevcrea + '</td><TD>' + @prm +
                          '</td><TD>' + @pabroad + '</td></tr>';
        END
        ELSE
        BEGIN
          SET @sMessageDoc2 = @sMessageDoc2 + '<TR><TD>' + @porgantype +
                          '</td><TD>' + @pempno + '</td><TD>' + @pchname +
                          '</td><TD>' + @pdeptname + '</td>';
          SET @sMessageDoc2 = @sMessageDoc2 + '<TD>' + @pposname + '</td><TD>' +
                          @pposlevel + '</td><TD>' + @pvacname + '</td><TD>' +
                          @pstatusname + '</td>';
          SET @sMessageDoc2 = @sMessageDoc2 + '<TD>' + @psd + '</td><TD>' + @pst +
                          '</td><TD>' + @ped + '</td>';
          SET @sMessageDoc2 = @sMessageDoc2 + '<TD>' + @pet + '</td><TD>' +
                          @pvacdays + '</td><TD>' + @pvachrs + '</td>';
          SET @sMessageDoc2 = @sMessageDoc2 + '<TD>' + @pevcrea + '</td><TD>' + @prm +
                          '</td><TD>' + @pabroad + '</td></tr>';
        END
      END
    
    END
    --SET @sMessageDoc = @sMessageDoc+ '</table>';
    CLOSE cursor3;
    DEALLOCATE cursor3
  
    SET @sTitle = '未來一週請假出國人員名單(醫師)(' + FORMAT(GETDATE(), 'yyyy-mm-dd') + ')';
  
    IF @sMessageDoc is null BEGIN
      IF @sMessage is null BEGIN
        --無醫師無一般
        SET @sMessageMail = '截至上午07:10，無未來一週請假出國假卡。';
      END
      ELSE
      BEGIN
        --無醫師有一般
        SET @sMessage = @sMessage + '</table>';
        SET @sMessageMail = @sMessage;
      END
    END
    ELSE
    BEGIN
      SET @sMessageDoc = @sMessageDoc + '</table>';
      IF @sMessage is null BEGIN
        --有醫師無一般
        SET @sMessageMail = @sMessageDoc;
      END
      ELSE
      BEGIN
        --有醫師有一般
        SET @sMessage = @sMessage + '</table>';
        SET @sMessageMail = @sMessageDoc + '<br><br>' + @sMessage;
      END
    END
    
    IF @sMessageDoc2 IS NOT NULL BEGIN
      SET @sMessageDoc2 = @sMessageDoc2 + '</table>';
    END
    
    OPEN cursor2;
    WHILE 1=1 BEGIN
      FETCH NEXT FROM cursor2 INTO @sEEMail;
      IF @@FETCH_STATUS <> 0 BREAK;
      IF @sMessageDoc2 IS NOT NULL BEGIN
        SET @__exec_title1 = @sTitle + '_1';
        SET @__exec_title2 = @sTitle + '_2';
        EXEC [ehrphrafunc_pkg].[POST_HTML_MAIL] 'system@edah.org.tw', @sEEMail, '', '1', @__exec_title1, @sMessageMail;
        EXEC [ehrphrafunc_pkg].[POST_HTML_MAIL] 'system@edah.org.tw', @sEEMail, '', '1', @__exec_title2, @sMessageDoc2;
      END
      ELSE
      BEGIN
        EXEC [ehrphrafunc_pkg].[POST_HTML_MAIL] 'system@edah.org.tw', @sEEMail, '', '1', @sTitle, @sMessageMail;
      END
    END
    CLOSE cursor2;
    DEALLOCATE cursor2
END TRY
BEGIN CATCH
    -- WHEN OTHERS
    SET @ErrorCode = @pempno;
      SET @ErrorMessage = ERROR_MESSAGE();
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
        (FORMAT(GETDATE(), 'MMddhhmmss'),
         '請假出國人員通知',
         GETDATE(),
         @ErrorCode,
         '未來一週請假出國人員名單通知執行異常(醫師)',
         @ErrorMessage,
         'MIS',
         GETDATE(),
         'MIS',
         GETDATE());
      COMMIT TRAN;
END CATCH
END
GO
