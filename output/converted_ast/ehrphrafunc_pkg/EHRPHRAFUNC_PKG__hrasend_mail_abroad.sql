CREATE OR ALTER PROCEDURE [ehrphrafunc_pkg].[hrasend_mail_abroad]
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
DECLARE @sTitle2 NVARCHAR(100);
DECLARE @sEEMail NVARCHAR(120);
DECLARE @sMessage NVARCHAR(MAX);
DECLARE @sMessage2 NVARCHAR(MAX);
DECLARE @sMessageDoc NVARCHAR(MAX);
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
             CASE WHEN tb.organ_type = 'ED' THEN '義大' WHEN tb.organ_type = 'EC' THEN '癌醫' WHEN tb.organ_type = 'EF' THEN '大昌' WHEN tb.organ_type = 'EG' THEN '護理之家' WHEN tb.organ_type = 'EK' THEN '產後護理' WHEN tb.organ_type = 'EH' THEN '居護所' WHEN tb.organ_type = 'EL' THEN '貝思諾' WHEN tb.organ_type = 'EN' THEN '幼兒園' END ORGANTYPE,
             
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
BEGIN
BEGIN TRY
    SET @sMessage = '<table border="1" width="100%">';
  
    SET @sMessage = @sMessage + '<tr><td colspan="17" ><BR>' +
                '==========(一般人員出國假單)==========' + '<BR><BR></tr></tr>';
    SET @sMessage = @sMessage +
                '<TR><TD>機構</td><TD>工號</td><TD>姓名</td><TD>部門名稱</td><TD>職稱</td><TD>職等</td><TD>假別</td>';
  
    SET @sMessage = @sMessage +
                '<TD>狀態</td><TD>開始日期</td><TD>開始時間</td><TD>結束日期</td><TD>結束時間</td>';
    SET @sMessage = @sMessage +
                '<TD>天數</td><TD>時數</td><TD>請假理由</td><TD>其他原因</td><TD>出國</td>';
  
    OPEN cursor1;
    WHILE 1=1 BEGIN
      FETCH NEXT FROM cursor1 INTO @pempno, @pchname, @pdeptname, @pposname, @pvacname, @pstatusname, @psd, @pst, @ped, @pet, @pevcrea, @pvacdays, @pvachrs, @prm, @pevcday, @plastvacday, @pevc_u, @pevc_s, @pevc_f, @pabroad, @porgantype, @pposlevel;
      IF @@FETCH_STATUS <> 0 BREAK;
      SET @nconti = 0;
      --check 電子假卡vs補休 
      --仍有盲點
      SELECT @nconti = COUNT(*)
    FROM (SELECT MIN(start_date) starDate
                FROM (SELECT t1.emp_no, start_date, end_date
                        FROM HRA_EVCREC t1
                       WHERE status IN ('Y', 'U')
                         AND abroad = 'Y'
                         AND ((FORMAT(START_DATE, 'yyyy-mm-dd') BETWEEN
                             FORMAT(GETDATE(), 'yyyy-mm-dd') AND
                             FORMAT(DATEADD(DAY, 7, GETDATE()), 'yyyy-mm-dd')) OR
                             (FORMAT(END_DATE, 'yyyy-mm-dd') BETWEEN
                             FORMAT(GETDATE(), 'yyyy-mm-dd') AND
                             FORMAT(DATEADD(DAY, 7, GETDATE()), 'yyyy-mm-dd')) OR
                             (FORMAT(START_DATE, 'yyyy-mm-dd') <=
                             FORMAT(GETDATE(), 'yyyy-mm-dd') AND
                             FORMAT(END_DATE, 'yyyy-mm-dd') >=
                             FORMAT(GETDATE(), 'yyyy-mm-dd')))
                      UNION ALL
                      SELECT t1.emp_no, start_date, end_date
                        FROM HRA_SUPMST t1
                       WHERE status IN ('Y', 'U')
                         AND ((FORMAT(start_date, 'yyyy-mm-dd') BETWEEN
                             FORMAT(GETDATE(), 'yyyy-mm-dd') AND
                             FORMAT(DATEADD(DAY, 7, GETDATE()), 'yyyy-mm-dd')) OR
                             (FORMAT(END_date, 'yyyy-mm-dd') BETWEEN
                             FORMAT(GETDATE(), 'yyyy-mm-dd') AND
                             FORMAT(DATEADD(DAY, 7, GETDATE()), 'yyyy-mm-dd')) OR
                             (FORMAT(start_date, 'yyyy-mm-dd') <=
                             FORMAT(GETDATE(), 'yyyy-mm-dd') AND
                             FORMAT(end_date, 'yyyy-mm-dd') >=
                             FORMAT(DATEADD(DAY, 7, GETDATE()), 'yyyy-mm-dd')))
                         AND abroad IN ('Y')) AS _dt4
               WHERE emp_no = @pempno) AS _dt5
       WHERE FORMAT(starDate, 'yyyy-mm-dd') <=
             FORMAT(GETDATE(), 'yyyy-mm-dd');
    
      IF @psd <= FORMAT(GETDATE(), 'yyyy-mm-dd') OR @nconti <> 0 BEGIN
        SET @pabroad = @pabroad + '-已出';
      END
      ELSE
      BEGIN
        SET @pabroad = @pabroad + '-未出';
      END
    
      --2023-4-11 拆2封 by108154
      IF (LEN(@sMessage) < 19000) BEGIN
      
        SET @sMessage = @sMessage + '<TR><TD>' + @porgantype + '</td><TD>' +
                    @pempno + '</td><TD>' + @pchname + '</td><TD>' +
                    @pdeptname + '</td>';
        SET @sMessage = @sMessage + '<TD>' + @pposname + '</td><TD>' +
                    @pposlevel + '</td><TD>' + @pvacname + '</td><TD>' +
                    @pstatusname + '</td>';
        SET @sMessage = @sMessage + '<TD>' + @psd + '</td><TD>' + @pst +
                    '</td><TD>' + @ped + '</td>';
        SET @sMessage = @sMessage + '<TD>' + @pet + '</td><TD>' + @pvacdays +
                    '</td><TD>' + @pvachrs + '</td>';
        SET @sMessage = @sMessage + '<TD>' + @pevcrea + '</td><TD>' + @prm +
                    '</td><TD>' + @pabroad + '</td></tr>';
      
      END
      ELSE
      BEGIN
      
        IF @sMessage2 is null BEGIN
          SET @sMessage2 = '<table border="1" width="100%">';
          SET @sMessage2 = @sMessage2 + '<tr><td colspan="17" ><BR>' +
                       '==========(一般人員出國假單)==========' +
                       '<BR><BR></tr></tr>';
          SET @sMessage2 = @sMessage2 +
                       '<TR><TD>機構</td><TD>工號</td><TD>姓名</td><TD>部門名稱</td><TD>職稱</td><TD>職等</td><TD>假別</td>';
        
          SET @sMessage2 = @sMessage2 +
                       '<TD>狀態</td><TD>開始日期</td><TD>開始時間</td><TD>結束日期</td><TD>結束時間</td>';
          SET @sMessage2 = @sMessage2 +
                       '<TD>天數</td><TD>時數</td><TD>請假理由</td><TD>其他原因</td><TD>出國</td>';
          SET @sMessage2 = @sMessage2 + '<TR><TD>' + @porgantype + '</td><TD>' +
                       @pempno + '</td><TD>' + @pchname + '</td><TD>' +
                       @pdeptname + '</td>';
          SET @sMessage2 = @sMessage2 + '<TD>' + @pposname + '</td><TD>' +
                       @pposlevel + '</td><TD>' + @pvacname + '</td><TD>' +
                       @pstatusname + '</td>';
          SET @sMessage2 = @sMessage2 + '<TD>' + @psd + '</td><TD>' + @pst +
                       '</td><TD>' + @ped + '</td>';
          SET @sMessage2 = @sMessage2 + '<TD>' + @pet + '</td><TD>' +
                       @pvacdays + '</td><TD>' + @pvachrs + '</td>';
          SET @sMessage2 = @sMessage2 + '<TD>' + @pevcrea + '</td><TD>' + @prm +
                       '</td><TD>' + @pabroad + '</td></tr>';
        END
        ELSE
        BEGIN
          SET @sMessage2 = @sMessage2 + '<TR><TD>' + @porgantype + '</td><TD>' +
                       @pempno + '</td><TD>' + @pchname + '</td><TD>' +
                       @pdeptname + '</td>';
          SET @sMessage2 = @sMessage2 + '<TD>' + @pposname + '</td><TD>' +
                       @pposlevel + '</td><TD>' + @pvacname + '</td><TD>' +
                       @pstatusname + '</td>';
          SET @sMessage2 = @sMessage2 + '<TD>' + @psd + '</td><TD>' + @pst +
                       '</td><TD>' + @ped + '</td>';
          SET @sMessage2 = @sMessage2 + '<TD>' + @pet + '</td><TD>' +
                       @pvacdays + '</td><TD>' + @pvachrs + '</td>';
          SET @sMessage2 = @sMessage2 + '<TD>' + @pevcrea + '</td><TD>' + @prm +
                       '</td><TD>' + @pabroad + '</td></tr>';
        END
      
      END
    END
    CLOSE cursor1;
    DEALLOCATE cursor1
  
    SET @sTitle = '未來一週請假出國人員名單(一般人員)(' + FORMAT(GETDATE(), 'yyyy-mm-dd') + ')';
    SET @sTitle2 = '未來一週請假出國人員名單(一般人員)(第2封/共2封)(' +
               FORMAT(GETDATE(), 'yyyy-mm-dd') + ')';
  
    IF @sMessage is null BEGIN
    
      SET @sMessageMail = '截至上午07:10，無未來一週請假出國假卡。';
    
      OPEN cursor2;
      WHILE 1=1 BEGIN
        FETCH NEXT FROM cursor2 INTO @sEEMail;
        IF @@FETCH_STATUS <> 0 BREAK;
        EXEC [ehrphrafunc_pkg].[POST_HTML_MAIL] 'system@edah.org.tw',
                       @sEEMail,
                       '',
                       '1',
                       @sTitle,
                       @sMessageMail;
      END
      CLOSE cursor2;
    DEALLOCATE cursor2
    END
    ELSE
    BEGIN
      --無醫師有一般(一封)
      IF @sMessage2 is null BEGIN
      
        SET @sMessage = @sMessage + '</table>';
        SET @sMessageMail = @sMessage;
        OPEN cursor2;
        WHILE 1=1 BEGIN
          FETCH NEXT FROM cursor2 INTO @sEEMail;
          IF @@FETCH_STATUS <> 0 BREAK;
          EXEC [ehrphrafunc_pkg].[POST_HTML_MAIL] 'system@edah.org.tw',
                         @sEEMail,
                         '',
                         '1',
                         @sTitle,
                         @sMessage;
        END
        CLOSE cursor2;
    DEALLOCATE cursor2
      
      END
      ELSE
      BEGIN
        SET @sTitle = '未來一週請假出國人員名單(一般人員)(第1封/共2封)(' +
                  FORMAT(GETDATE(), 'yyyy-mm-dd') + ')';
      
        SET @sMessage = @sMessage + '</table>';
        SET @sMessageMail = @sMessage;
        OPEN cursor2;
        WHILE 1=1 BEGIN
          FETCH NEXT FROM cursor2 INTO @sEEMail;
          IF @@FETCH_STATUS <> 0 BREAK;
          EXEC [ehrphrafunc_pkg].[POST_HTML_MAIL] 'system@edah.org.tw',
                         @sEEMail,
                         '',
                         '1',
                         @sTitle,
                         @sMessageMail;
        END
        CLOSE cursor2;
    DEALLOCATE cursor2
      
        SET @sMessage2 = @sMessage2 + '</table>';
        OPEN cursor2;
        WHILE 1=1 BEGIN
          FETCH NEXT FROM cursor2 INTO @sEEMail;
          IF @@FETCH_STATUS <> 0 BREAK;
          EXEC [ehrphrafunc_pkg].[POST_HTML_MAIL] 'system@edah.org.tw',
                         @sEEMail,
                         '',
                         '1',
                         @sTitle2,
                         @sMessage2;
        END
        CLOSE cursor2;
    DEALLOCATE cursor2
      
      END
    END
END TRY
BEGIN CATCH
    -- WHEN OTHERS
    SET @ErrorCode = ERROR_NUMBER();
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
         '未來一週請假出國人員名單通知執行異常(一般人員)',
         @ErrorMessage,
         'MIS',
         GETDATE(),
         'MIS',
         GETDATE());
      COMMIT TRAN;
END CATCH
END
GO
