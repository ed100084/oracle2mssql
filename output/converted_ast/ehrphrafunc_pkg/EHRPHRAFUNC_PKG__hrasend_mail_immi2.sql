CREATE OR ALTER PROCEDURE [ehrphrafunc_pkg].[hrasend_mail_immi2]
AS
DECLARE @pEvcno NVARCHAR(20);
DECLARE @pEmpno NVARCHAR(20);
DECLARE @pChname NVARCHAR(200);
DECLARE @pEmail NVARCHAR(60);
DECLARE @pStartdate NVARCHAR(20);
DECLARE @iMSG_NO NVARCHAR(20);
DECLARE @sSEQNO NVARCHAR(20);
DECLARE @__mail_msg NVARCHAR(MAX);
DECLARE cursor1 CURSOR FOR
    SELECT t1.emp_no,
             t2.ch_name,
             (CASE
               WHEN SUBSTRING(T2.EMP_NO, 1, 1) NOT IN ('S', 'P', 'R') THEN
                'ed' + T2.EMP_NO + '@edah.org.tw'
               ELSE
                'ed' + T2.EMP_NO + '@edah.org.tw'
             END) AS e_mail,
             FORMAT(T1.Start_Date, 'yyyy-mm-dd') AS Start_Date
        FROM HRA_EVCREC t1, HRE_EMPBAS t2
       WHERE t1.emp_no = t2.emp_no
         AND status IN ('Y', 'U')
         AND (t1.evc_rea = '0010' or abroad = 'Y')
         AND FORMAT(end_date, 'yyyymm') >= '200906'
         AND DATEDIFF(DAY, CAST(end_date AS DATE), CAST(GETDATE() AS DATE)) = 3
         AND evc_no NOT IN
             (SELECT t1.evc_no
                FROM HRA_EVCREC t1, HRA_IMMIDTL t2, HRA_IMMIMST t3
               WHERE t2.evc_no = t3.evc_no
                 AND (FORMAT(start_date, 'yyyymmdd') BETWEEN
                     FORMAT(t2.outdate, 'yyyymmdd') AND
                     FORMAT(t2.indate, 'yyyymmdd') OR
                     FORMAT(end_date, 'yyyymmdd') BETWEEN
                     FORMAT(t2.outdate, 'yyyymmdd') AND
                     FORMAT(t2.indate, 'yyyymmdd'))
                 AND t1.emp_no = t3.emp_no
                 AND FORMAT(end_date, 'yyyymm') >= '200906'
                 AND (evc_rea = '0010' or abroad = 'Y'))
      UNION ALL
      SELECT t1.emp_no,
             t2.ch_name,
             (CASE
               WHEN SUBSTRING(T2.EMP_NO, 1, 1) NOT IN ('S', 'P', 'R') THEN
                'ed' + T2.EMP_NO + '@edah.org.tw'
               ELSE
                'ed' + T2.EMP_NO + '@edah.org.tw'
             END) AS e_mail,
             FORMAT(T1.Start_Date, 'yyyy-mm-dd') AS Start_Date
        FROM HRA_OFFREC t1, HRE_EMPBAS t2
       WHERE t1.emp_no = t2.emp_no
         AND status IN ('Y', 'U')
         AND t1.abroad = 'Y'
         AND FORMAT(end_date, 'yyyymm') >= '200906'
         and item_type = 'O'
         AND DATEDIFF(DAY, CAST(end_date AS DATE), CAST(GETDATE() AS DATE)) = 3
         AND NOT EXISTS
             (SELECT 1
                FROM HRA_OFFREC ix1, HRA_IMMIDTL ix2, HRA_IMMIMST ix3
               WHERE ix2.evc_no = ix3.evc_no
                 AND ix1.emp_no = t1.emp_no
                 AND ix1.start_date = t1.start_date
                 AND ix1.start_time = t1.start_time
                 AND (FORMAT(ix1.start_date, 'yyyymmdd') BETWEEN
                     FORMAT(ix2.outdate, 'yyyymmdd') AND
                     FORMAT(ix2.indate, 'yyyymmdd') OR
                     FORMAT(ix1.end_date, 'yyyymmdd') BETWEEN
                     FORMAT(ix2.outdate, 'yyyymmdd') AND
                     FORMAT(ix2.indate, 'yyyymmdd'))
                 AND ix1.emp_no = ix3.emp_no
                 AND FORMAT(ix1.end_date, 'yyyymm') >= '200906'
                 AND ix1.item_type = 'O'
                 AND ix1.abroad = 'Y')
      UNION ALL
      SELECT t1.emp_no,
             t2.ch_name,
             (CASE
               WHEN SUBSTRING(T2.EMP_NO, 1, 1) NOT IN ('S', 'P', 'R') THEN
                'ed' + T2.EMP_NO + '@edah.org.tw'
               ELSE
                'ed' + T2.EMP_NO + '@edah.org.tw'
             END) AS e_mail,
             FORMAT(T1.Start_Date, 'yyyy-mm-dd') AS Start_Date
        FROM HRA_SUPMST t1, HRE_EMPBAS t2
       WHERE t1.emp_no = t2.emp_no
         AND status IN ('Y', 'U')
         AND t1.abroad = 'Y'
         AND FORMAT(end_date, 'yyyymm') >= '200906'
         AND DATEDIFF(DAY, CAST(end_date AS DATE), CAST(GETDATE() AS DATE)) = 3
         AND NOT EXISTS
             (SELECT 1
                FROM HRA_SUPMST ix1, HRA_IMMIDTL ix2, HRA_IMMIMST ix3
               WHERE ix2.evc_no = ix3.evc_no
                 AND ix1.emp_no = t1.emp_no
                 AND ix1.start_date = t1.start_date
                 AND ix1.start_time = t1.start_time
                 AND (FORMAT(ix1.start_date, 'yyyymmdd') BETWEEN
                     FORMAT(ix2.outdate, 'yyyymmdd') AND
                     FORMAT(ix2.indate, 'yyyymmdd') OR
                     FORMAT(ix1.end_date, 'yyyymmdd') BETWEEN
                     FORMAT(ix2.outdate, 'yyyymmdd') AND
                     FORMAT(ix2.indate, 'yyyymmdd'))
                 AND ix1.emp_no = ix3.emp_no
                 AND FORMAT(ix1.end_date, 'yyyymm') >= '200906'
                 AND ix1.abroad = 'Y')
      UNION ALL
      SELECT t1.emp_no,
             t2.ch_name,
             (CASE
               WHEN SUBSTRING(T2.EMP_NO, 1, 1) NOT IN ('S', 'P', 'R') THEN
                'ed' + T2.EMP_NO + '@edah.org.tw'
               ELSE
                'ed' + T2.EMP_NO + '@edah.org.tw'
             END) AS e_mail,
             FORMAT(T1.Start_Date, 'yyyy-mm-dd') AS Start_Date
        FROM HRA_DEVCREC t1, HRE_EMPBAS t2
       WHERE t1.emp_no = t2.emp_no
         AND status IN ('Y', 'U')
         AND (t1.evc_rea = '0010' or abroad = 'Y')
         AND FORMAT(end_date, 'yyyymm') >= '200906'
         AND DATEDIFF(DAY, CAST(end_date AS DATE), CAST(GETDATE() AS DATE)) = 3
         AND Dis_All <> 'Y' 
         AND evc_no NOT IN
             (SELECT t1.evc_no
                FROM HRA_DEVCREC t1, HRA_IMMIDTL t2, HRA_IMMIMST t3
               WHERE t2.evc_no = t3.evc_no
                 AND (FORMAT(start_date, 'yyyymmdd') BETWEEN
                     FORMAT(t2.outdate, 'yyyymmdd') AND
                     FORMAT(t2.indate, 'yyyymmdd') OR
                     FORMAT(end_date, 'yyyymmdd') BETWEEN
                     FORMAT(t2.outdate, 'yyyymmdd') AND
                     FORMAT(t2.indate, 'yyyymmdd'))
                 AND t1.emp_no = t3.emp_no
                 AND FORMAT(end_date, 'yyyymm') >= '200906'
                 AND (evc_rea = '0010' or abroad = 'Y'));
BEGIN
    OPEN cursor1;
    WHILE 1=1 BEGIN
      FETCH NEXT FROM cursor1 INTO @pEmpno, @pChname, @pEmail, @pStartdate;
      IF @@FETCH_STATUS <> 0 BREAK;
    
      SELECT @sSEQNO = SEQNO_NEXT
    FROM HR_SEQCTL
       WHERE SEQNO_TYPE = 'HRA';
    
      SET @iMSG_NO = 'HRA' + FORMAT(GETDATE(), 'yyMM') + CAST(@sSEQNO AS NVARCHAR);
    
      INSERT INTO PUS_MSGMST
        (MSG_NO, MSG_FROM, MSG_TO, SUBJECT, MSG_DESC, MSG_DATE)
      VALUES
        (@iMSG_NO,
         '感控',
         @pChname + '(' + @pEmpno + ')',
         '出入境管理-請假出國未填管理資料通知',
         '您有填寫假卡(請假起日' + @pStartdate +
         ')出國,但未填寫出入境管理相關資料,請至MIS 公用服務系統->公用出勤程式->出入境管理 中填寫相關資料',
         GETDATE());
      INSERT INTO PUS_MSGBAS (MSG_NO, EMP_NO) VALUES (@iMSG_NO, @pEmpno);
      IF @pEmail is not null BEGIN
        SET @__mail_msg = '您有填寫假卡(請假起日' + @pStartdate +
                       ')出國,但未填寫出入境管理相關資料,請至MIS 公用服務系統->公用出勤程式->出入境管理 中填寫相關資料';
        EXEC [ehrphrafunc_pkg].[POST_HTML_MAIL] 'system@edah.org.tw',
                       @pEmail,
                       'ed108482@edah.org.tw',
                       '1',
                       '出入境管理-請假出國未填管理資料通知',
                       @__mail_msg;
      END
    
      UPDATE HR_SEQCTL
         SET SEQNO_NEXT = case when seqno_next + 1 > 100000 then 10000 else seqno_next + 1 end
       WHERE SEQNO_TYPE = 'HRA';
    
    END
    CLOSE cursor1;
    DEALLOCATE cursor1;
    COMMIT TRAN;
    EXEC [ehrphrafunc_pkg].[DocUnsignautomsg];
END
GO
