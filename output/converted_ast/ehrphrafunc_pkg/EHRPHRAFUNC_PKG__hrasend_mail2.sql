CREATE OR ALTER PROCEDURE [ehrphrafunc_pkg].[hrasend_mail2]
AS
DECLARE @pempno NVARCHAR(20);
DECLARE @pchname NVARCHAR(200);
DECLARE @pdeptname NVARCHAR(60);
DECLARE @pposname NVARCHAR(60);
DECLARE @pvacname NVARCHAR(40);
DECLARE @pstatusname NVARCHAR(10);
DECLARE @psd NVARCHAR(10);
DECLARE @pst NVARCHAR(4);
DECLARE @ped NVARCHAR(10);
DECLARE @pet NVARCHAR(4);
DECLARE @pevcrea NVARCHAR(100);
DECLARE @pvacdays SMALLINT;
DECLARE @pvachrs DECIMAL(4,1);
DECLARE @prm NVARCHAR(300);
DECLARE @pevcday NVARCHAR(100);
DECLARE @plastvacday NVARCHAR(100);
DECLARE @pevc_u NVARCHAR(100);
DECLARE @pevc_f NVARCHAR(100);
DECLARE @pevc_s NVARCHAR(100);
DECLARE @pabroad NVARCHAR(2);
DECLARE @pevc_p NVARCHAR(100);
DECLARE @psup_hr NVARCHAR(100);
DECLARE @sTitle NVARCHAR(100);
DECLARE @sEEMail NVARCHAR(120);
DECLARE @sMessage NVARCHAR(MAX);
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
             (SELECT ISNULL(FLOOR(SUM(VAC_DAYS * 8 + VAC_HRS) / 8), '0') + '天' +
                     ISNULL((SUM(VAC_DAYS * 8 + VAC_HRS) % 8), '0') + '時'
                FROM HRP.HRA_EVCREC
               WHERE VAC_TYPE = 'P'
                 AND EMP_NO = ta.EMP_NO
                 AND ORG_BY = ta.ORG_BY
                 AND STATUS IN ('Y', 'U')
                 AND FORMAT(START_DATE, 'yyyy') = FORMAT(GETDATE(), 'yyyy')
                 AND TRANS_FLAG = 'N') P_U_DAY,
             (SELECT ISNULL(FLOOR(SUM(SUP_HRS) / 8), '0') + '天' +
                     ISNULL((SUM(SUP_HRS) % 8), '0') + '時'
                FROM HRP.HRA_SUPMST
               WHERE EMP_NO = ta.EMP_NO
                 AND ORG_BY = ta.ORG_BY
                 AND STATUS IN ('Y', 'U')
                 AND FORMAT(START_DATE, 'yyyy') = FORMAT(GETDATE(), 'yyyy')) SUP_U_HR
      
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
               WHERE sd <= FORMAT(GETDATE(), 'yyyy-mm-dd')
                 AND ed >= FORMAT(GETDATE(), 'yyyy-mm-dd')
                 AND EMP_NO IN
                    
                     (SELECT emp_no
                        FROM HRE_EMPBAS
                       WHERE POS_NO IN (SELECT POS_NO
                                          FROM HRE_POSMST
                                         WHERE POS_LEVEL >= 7 
                                        )
                         AND DISABLED = 'N'
                         AND EMP_FLAG = '01'
                         AND ISNULL(JOB_LEV, 'Z') <> 'R'
                         AND emp_no <> '100003' 
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
               WHERE sd <= FORMAT(GETDATE(), 'yyyy-mm-dd')
                 AND ed >= FORMAT(GETDATE(), 'yyyy-mm-dd')
                 AND EMP_NO IN
                    
                     (SELECT emp_no
                        FROM HRE_EMPBAS
                       WHERE POS_NO IN (SELECT POS_NO
                                          FROM HRE_POSMST
                                         WHERE POS_LEVEL >= 7 
                                        )
                         AND DISABLED = 'N'
                         AND EMP_FLAG = '01'
                         AND ISNULL(JOB_LEV, 'Z') <> 'R'
                         AND emp_no <> '100003' 
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
               WHERE sd <= FORMAT(GETDATE(), 'yyyy-mm-dd')
                 AND ed >= FORMAT(GETDATE(), 'yyyy-mm-dd')
                 AND EMP_NO IN
                    
                     (SELECT emp_no
                        FROM HRE_EMPBAS
                       WHERE POS_NO IN (SELECT POS_NO
                                          FROM HRE_POSMST
                                         WHERE POS_LEVEL >= 7 
                                        )
                         AND DISABLED = 'N'
                         AND EMP_FLAG = '01'
                         AND ISNULL(JOB_LEV, 'Z') <> 'R'
                         AND emp_no <> '100003' 
                      )
              
              ) ta
        LEFT OUTER JOIN HRA_YEARVAC TC ON TA.EMP_NO = TC.EMP_NO
                                      AND TC.VAC_YEAR =
                                          FORMAT(GETDATE(), 'yyyy'),
       HRE_EMPBAS tb
       WHERE ta.emp_no = tb.emp_no
         and ta.org_by = tb.organ_type
      
      
      
       ORDER BY ta.emp_no;
DECLARE cursor2 CURSOR FOR
    SELECT CODE_NAME
        FROM HR_CODEDTL
       WHERE CODE_TYPE = 'HRA62'
         AND DISABLED = 'N';
BEGIN
BEGIN TRY
    SET @sMessage = '';
  
    OPEN cursor1;
    WHILE 1=1 BEGIN
      FETCH NEXT FROM cursor1 INTO @pempno, @pchname, @pdeptname, @pposname, @pvacname, @pstatusname, @psd, @pst, @ped, @pet, @pevcrea, @pvacdays, @pvachrs, @prm, @pevcday, @plastvacday, @pevc_u, @pevc_s, @pevc_f, @pabroad, @pevc_p, @psup_hr;
      IF @@FETCH_STATUS <> 0 BREAK;
    
      IF @sMessage is null BEGIN
        SET @sMessage = '<table border="1" width="100%"><TR><TD>工號</td><TD>姓名</td><TD>部門名稱</td><TD>職稱</td><TD>假別</td>';
        SET @sMessage = @sMessage +
                    '<TD>狀態</td><TD>開始日期</td><TD>開始時間</td><TD>結束日期</td><TD>結束時間</td>';
        SET @sMessage = @sMessage +
                    '<TD>天數</td><TD>時數</td><TD>請假理由</td><TD>其他原因</td><TD>出國</td><TD>可休特休</td><TD>已休特休</td><TD>事假</td><TD>病假</td></tr>';
        --'<TD>天數</td><TD>時數</td><TD>請假理由</td><TD>其他原因</td><TD>出國</td><TD>可休特休</td><TD>已休特休</td><TD>事假</td><TD>病假</td><TD>公假</td><TD>補休</td></tr>';
        SET @sMessage = @sMessage + '<TR><TD>' + @pempno + '</td><TD>' +
                    @pchname + '</td><TD>' + @pdeptname + '</td>';
        SET @sMessage = @sMessage + '<TD>' + @pposname + '</td><TD>' +
                    @pvacname + '</td><TD>' + @pstatusname + '</td>';
        SET @sMessage = @sMessage + '<TD>' + @psd + '</td><TD>' + @pst +
                    '</td><TD>' + @ped + '</td>';
        SET @sMessage = @sMessage + '<TD>' + @pet + '</td><TD>' + @pvacdays +
                    '</td><TD>' + @pvachrs + '</td>';
        SET @sMessage = @sMessage + '<TD>' + @pevcrea + '</td><TD>' + @prm +
                    '</td><TD>' + @pabroad + '</td><TD>' + @pevcday +
                    '<font color="red">(含遞延' + @plastvacday +
                    '天)</font></td><TD>' + @pevc_u + '</td><TD>' + @pevc_f +
                    '</td><TD>' + @pevc_s + '</td></tr>';
        --'</td><TD>' + @pevc_s + '</td><td>'+ @pevc_p + '</td><td>'+ @psup_hr +'</td></tr>';
      END
      ELSE
      BEGIN
        SET @sMessage = @sMessage + '<TR><TD>' + @pempno + '</td><TD>' +
                    @pchname + '</td><TD>' + @pdeptname + '</td>';
        SET @sMessage = @sMessage + '<TD>' + @pposname + '</td><TD>' +
                    @pvacname + '</td><TD>' + @pstatusname + '</td>';
        SET @sMessage = @sMessage + '<TD>' + @psd + '</td><TD>' + @pst +
                    '</td><TD>' + @ped + '</td>';
        SET @sMessage = @sMessage + '<TD>' + @pet + '</td><TD>' + @pvacdays +
                    '</td><TD>' + @pvachrs + '</td>';
        SET @sMessage = @sMessage + '<TD>' + @pevcrea + '</td><TD>' + @prm +
                    '</td><TD>' + @pabroad + '</td><TD>' + @pevcday +
                    '<font color="red">(含遞延' + @plastvacday +
                    '天)</font></td><TD>' + @pevc_u + '</td><TD>' + @pevc_f +
                    '</td><TD>' + @pevc_s + '</td></tr>';
        --'</td><TD>' + @pevc_s + '</td><td>'+ @pevc_p + '</td><td>'+ @psup_hr +'</td></tr>';
      END
    
    END
    CLOSE cursor1;
    DEALLOCATE cursor1
  
    SET @sTitle = '今日一級主管請假彙總表(' + FORMAT(GETDATE(), 'yyyy-mm-dd') + ')';
  
    IF (@sMessage is not null) BEGIN
      SET @sMessage = @sMessage + '</table>';
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
    
      SET @sMessage = '截至上午07:00，無今日(' + FORMAT(GETDATE(), 'yyyy-mm-dd') + ')';
      SET @sMessage = @sMessage + '一級主管電子假卡、補休申請單。';
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
         '一級主管請假彙總',
         GETDATE(),
         @ErrorCode,
         '今日一級主管請假彙總表通知執行異常',
         @ErrorMessage,
         'MIS',
         GETDATE(),
         'MIS',
         GETDATE());
      COMMIT TRAN;
END CATCH
END
GO
