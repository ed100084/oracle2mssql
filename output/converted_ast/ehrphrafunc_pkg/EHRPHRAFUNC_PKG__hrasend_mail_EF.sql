CREATE OR ALTER PROCEDURE [ehrphrafunc_pkg].[hrasend_mail_EF]
AS
DECLARE @pempno NVARCHAR(100);
DECLARE @pchname NVARCHAR(200);
DECLARE @pdeptname NVARCHAR(100);
DECLARE @pposname NVARCHAR(100);
DECLARE @pvacname NVARCHAR(100);
DECLARE @pstatusname NVARCHAR(100);
DECLARE @psd NVARCHAR(100);
DECLARE @pst NVARCHAR(104);
DECLARE @ped NVARCHAR(100);
DECLARE @pet NVARCHAR(40);
DECLARE @pevcrea NVARCHAR(100);
DECLARE @pvacdays SMALLINT;
DECLARE @pvachrs DECIMAL(4,1);
DECLARE @prm NVARCHAR(300);
DECLARE @sTitle NVARCHAR(100);
DECLARE @sEEMail NVARCHAR(120);
DECLARE @sMessage NVARCHAR(MAX);
DECLARE @sTitleR NVARCHAR(100);
DECLARE @sMessageR NVARCHAR(MAX);
DECLARE @n_total_1 SMALLINT;
DECLARE @n_tota3_1 SMALLINT;
DECLARE @n_rang SMALLINT;
DECLARE @n_start SMALLINT;
DECLARE @n_end SMALLINT;
DECLARE curtotal_1 CURSOR FOR
    SELECT count(*)
        FROM (SELECT ORG_BY,
                     EMP_NO,
                     DEPT_NO,
                     VAC_TYPE,
                     VAC_RUL,
                     STATUS,
                     FORMAT(START_DATE, 'yyyy-mm-dd') SD,
                     START_TIME ST,
                     FORMAT(END_DATE, 'yyyy-mm-dd') ED,
                     END_TIME ET,
                     EVC_REA,
                     VAC_DAYS,
                     VAC_HRS,
                     REMARK
                FROM HRA_EVCREC
               WHERE STATUS IN ('Y', 'U')
                 AND START_DATE <= CAST(GETDATE() AS DATE)
                 AND END_DATE >= CAST(GETDATE() AS DATE)
              UNION ALL
              SELECT ORG_BY,
                     EMP_NO,
                     DEPT_NO,
                     'O1' VAC_TYPE,
                     'O1' VAC_RUL,
                     STATUS,
                     FORMAT(START_DATE, 'yyyy-mm-dd') SD,
                     START_TIME ST,
                     FORMAT(END_DATE, 'yyyy-mm-dd') ED,
                     END_TIME ET,
                     OTM_REA EVC_REA,
                     0 VAC_DAYS,
                     OTM_HRS VAC_HRS,
                     REMARK
                FROM HRA_OFFREC
               WHERE ITEM_TYPE = 'O'
                 AND STATUS IN ('Y', 'U')
                 AND START_DATE <= CAST(GETDATE() AS DATE)
                 AND END_DATE >= CAST(GETDATE() AS DATE)
              UNION ALL
              SELECT ORG_BY,
                     EMP_NO,
                     DEPT_NO,
                     'B0' VAC_TYPE,
                     'B0' VAC_RUL,
                     STATUS,
                     FORMAT(START_DATE, 'yyyy-mm-dd') SD,
                     START_TIME ST,
                     FORMAT(END_DATE, 'yyyy-mm-dd') ED,
                     END_TIME ET,
                     SUP_REA EVC_REA,
                     0 VAC_DAYS,
                     SUP_HRS VAC_HRS,
                     REMARK
                FROM HRA_SUPMST
               WHERE STATUS IN ('Y', 'U')
                 AND START_DATE <= CAST(GETDATE() AS DATE)
                 AND END_DATE >= CAST(GETDATE() AS DATE)) TA,
             HRE_EMPBAS TB
       WHERE TA.EMP_NO = TB.EMP_NO
         AND TB.ORGAN_TYPE = 'EF'
       ORDER BY TA.DEPT_NO, TA.EMP_NO;
DECLARE cursor1 CURSOR FOR
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
                             FORMAT(START_DATE, 'yyyy-mm-dd') SD,
                             START_TIME ST,
                             FORMAT(END_DATE, 'yyyy-mm-dd') ED,
                             END_TIME ET,
                             EVC_REA,
                             VAC_DAYS,
                             VAC_HRS,
                             REMARK
                        FROM HRA_EVCREC
                       WHERE STATUS IN ('Y', 'U')
                         AND START_DATE <= CAST(GETDATE() AS DATE)
                         AND END_DATE >= CAST(GETDATE() AS DATE)
                      UNION ALL
                      SELECT ORG_BY,
                             EMP_NO,
                             DEPT_NO,
                             'O1' VAC_TYPE,
                             'O1' VAC_RUL,
                             STATUS,
                             FORMAT(START_DATE, 'yyyy-mm-dd') SD,
                             START_TIME ST,
                             FORMAT(END_DATE, 'yyyy-mm-dd') ED,
                             END_TIME ET,
                             OTM_REA EVC_REA,
                             0 VAC_DAYS,
                             OTM_HRS VAC_HRS,
                             REMARK
                        FROM HRA_OFFREC
                       WHERE ITEM_TYPE = 'O'
                         AND STATUS IN ('Y', 'U')
                         AND START_DATE <= CAST(GETDATE() AS DATE)
                         AND END_DATE >= CAST(GETDATE() AS DATE)
                      UNION ALL
                      SELECT ORG_BY,
                             EMP_NO,
                             DEPT_NO,
                             'B0' VAC_TYPE,
                             'B0' VAC_RUL,
                             STATUS,
                             FORMAT(START_DATE, 'yyyy-mm-dd') SD,
                             START_TIME ST,
                             FORMAT(END_DATE, 'yyyy-mm-dd') ED,
                             END_TIME ET,
                             SUP_REA EVC_REA,
                             0 VAC_DAYS,
                             SUP_HRS VAC_HRS,
                             REMARK
                        FROM HRA_SUPMST
                       WHERE STATUS IN ('Y', 'U')
                         AND START_DATE <= CAST(GETDATE() AS DATE)
                         AND END_DATE >= CAST(GETDATE() AS DATE)) TA,
                     HRE_EMPBAS TB
               WHERE TA.EMP_NO = TB.EMP_NO
                 AND TB.ORGAN_TYPE = 'EF'
               -- ORDER BY removed: not allowed in T-SQL subquery without TOP/FOR XML
               ) AS _dt1
       WHERE NUM1 > @n_start
         AND NUM1 <= @n_end;
DECLARE cursor2 CURSOR FOR
    SELECT CODE_NAME
        FROM HR_CODEDTL
       WHERE CODE_TYPE = 'HRA99'
         AND CODE_NO LIKE 'D%'
         AND DISABLED = 'N';
DECLARE cursor3 CURSOR FOR
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
                             FORMAT(START_DATE, 'yyyy-mm-dd') SD,
                             START_TIME ST,
                             FORMAT(END_DATE, 'yyyy-mm-dd') ED,
                             END_TIME ET,
                             EVC_REA,
                             VAC_DAYS,
                             VAC_HRS,
                             REMARK
                        FROM HRA_DEVCREC
                       WHERE STATUS IN ('Y', 'U')
                         AND START_DATE <= CAST(GETDATE() AS DATE)
                         AND END_DATE >= CAST(GETDATE() AS DATE)
                         AND DIS_ALL <> 'Y') TA,
                     HRE_EMPBAS TB
               WHERE TA.EMP_NO = TB.EMP_NO
                 AND TB.ORGAN_TYPE = 'EF') AS _dt2
       WHERE num1 >= @n_start
         AND num1 <= @n_end;
DECLARE curtota3_1 CURSOR FOR
    SELECT COUNT(*)
        FROM (SELECT ORG_BY,
                     EMP_NO,
                     DEPT_NO,
                     VAC_TYPE,
                     VAC_RUL,
                     STATUS,
                     FORMAT(START_DATE, 'yyyy-mm-dd') SD,
                     START_TIME ST,
                     FORMAT(END_DATE, 'yyyy-mm-dd') ED,
                     END_TIME ET,
                     EVC_REA,
                     VAC_DAYS,
                     VAC_HRS,
                     REMARK
                FROM HRA_DEVCREC
               WHERE STATUS IN ('Y', 'U')
                 AND START_DATE <= CAST(GETDATE() AS DATE)
                 AND END_DATE >= CAST(GETDATE() AS DATE)
                 AND DIS_ALL <> 'Y') TA,
             HRE_EMPBAS TB
       WHERE TA.EMP_NO = TB.EMP_NO
         AND TB.ORGAN_TYPE = 'EF'
       ORDER BY TA.DEPT_NO, TB.POS_NO DESC, TA.EMP_NO;
BEGIN
    SET @sMessage = '';
    SET @sMessageR = '';
  
    open curtotal_1;
    WHILE 1=1 BEGIN
      FETCH NEXT FROM curtotal_1 INTO @n_total_1;
      IF @@FETCH_STATUS <> 0 BREAK;
    
      SET @n_rang = CEILING(@n_total_1 / 12);
      DECLARE @i INT = (1);
WHILE @i <= @n_rang BEGIN
        IF @i = 1 BEGIN
          IF @n_total_1 <= 12 BEGIN
            SET @n_start = 1;
            SET @n_end = @n_total_1;
          END
          ELSE
          BEGIN
            SET @n_start = 1;
            SET @n_end = 12;
          END
        END
        ELSE
        BEGIN
          SET @n_start = @n_end + 1;
          SET @n_end = @n_end + 12;
        END
      
        SET @sMessage = NULL;
      
        OPEN cursor1;
        SET @pempno = '';
        WHILE 1=1 BEGIN
          FETCH NEXT FROM cursor1 INTO @pempno, @pchname, @pdeptname, @pposname, @pvacname, @pstatusname, @psd, @pst, @ped, @pet, @pevcrea, @pvacdays, @pvachrs, @prm;
          IF @@FETCH_STATUS <> 0 BREAK;
        
          IF @sMessage IS NULL BEGIN
            SET @sMessage = '<table border="1" width="100%">' +
                        '<tr><th>工號</th><th>姓名</th><th>部門名稱</th><th>職稱</th><th>假別</th>' +
                        '<th>狀態</th><th>開始日期</th><th>開始時間</th><th>結束日期</th><th>結束時間</th>' +
                        '<th>天數</th><th>時數</th><th>請假理由</th><th>其他原因</th></tr>';
          END
          IF @pempno IS NOT NULL BEGIN
            SET @sMessage = @sMessage + '<tr><td>' + @pempno + '</td><td>' +
                        @pchname + '</td><td>' + @pdeptname + '</td>' +
                        '<td>' + @pposname + '</td><td>' + @pvacname +
                        '</td><td>' + @pstatusname + '</td>' + '<td>' + @psd +
                        '</td><td>' + @pst + '</td><td>' + @ped +
                        '</td><td>' + @pet + '</td>' + '<td>' + @pvacdays +
                        '</td><td>' + @pvachrs + '</td><td>' + @pevcrea +
                        '</td><td>' + @prm + '</td></tr>';
          END
          ELSE
          BEGIN
            SET @sMessage = @sMessage + '<tr><td colspan="14">無人員請假</td></tr>';
          END
        
        END
        CLOSE cursor1;
    DEALLOCATE cursor1
      
        SET @sTitle = '今日（非醫師）請假通知_大昌醫院(' + FORMAT(GETDATE(), 'yyyy-mm-dd') + ')';
      
        IF @sMessage IS NULL BEGIN
          SET @sMessage = '<table border="1" width="100%">' +
                      '<tr><th>工號</th><th>姓名</th><th>部門名稱</th><th>職稱</th><th>假別</th>' +
                      '<th>狀態</th><th>開始日期</th><th>開始時間</th><th>結束日期</th><th>結束時間</th>' +
                      '<th>天數</th><th>時數</th><th>請假理由</th><th>其他原因</th></tr>' +
                      '<tr><td colspan="14">無人員請假</td></tr>';
        END
      
        IF (@sMessage IS NOT NULL) BEGIN
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
      END
    
    END
    CLOSE curtotal_1;
    DEALLOCATE curtotal_1
  
    open curtota3_1;
    WHILE 1=1 BEGIN
      FETCH NEXT FROM curtota3_1 INTO @n_tota3_1;
      IF @@FETCH_STATUS <> 0 BREAK;
    
      SET @n_rang = CEILING(@n_tota3_1 / 10);
-- DECLARE @i INT = (1);  -- deduplicated
WHILE @i <= @n_rang BEGIN
        IF @i = 1 BEGIN
          IF @n_tota3_1 <= 10 BEGIN
            SET @n_start = 1;
            SET @n_end = @n_tota3_1;
          END
          ELSE
          BEGIN
            SET @n_start = 1;
            SET @n_end = 10;
          END
        END
        ELSE
        BEGIN
          SET @n_start = @n_end + 1;
          SET @n_end = @n_end + 10;
        END
      
        OPEN cursor3;
      
        SET @pempno = '';
        WHILE 1=1 BEGIN
          FETCH NEXT FROM cursor3 INTO @pempno, @pchname, @pdeptname, @pposname, @pvacname, @pstatusname, @psd, @pst, @ped, @pet, @pevcrea, @pvacdays, @pvachrs, @prm;
          IF @@FETCH_STATUS <> 0 BREAK;
        
          IF @sMessageR IS NULL BEGIN
            SET @sMessageR = '<table border="1" width="100%">' +
                         '<tr><th>工號</th><th>姓名</th><th>部門名稱</th><th>職稱</th><th>假別</th>' +
                         '<th>狀態</th><th>開始日期</th><th>開始時間</th><th>結束日期</th><th>結束時間</th>' +
                         '<th>天數</th><th>時數</th><th>請假理由</th><th>其他原因</th></tr>';
          END
          IF @pempno IS NOT NULL BEGIN
            SET @sMessageR = @sMessageR + '<tr><td>' + @pempno + '</td><td>' +
                         @pchname + '</td><td>' + @pdeptname + '</td>' +
                         '<td>' + @pposname + '</td><td>' + @pvacname +
                         '</td><td>' + @pstatusname + '</td>' + '<td>' + @psd +
                         '</td><td>' + @pst + '</td><td>' + @ped +
                         '</td><td>' + @pet + '</td>' + '<td>' +
                         @pvacdays + '</td><td>' + @pvachrs + '</td><td>' +
                         @pevcrea + '</td><td>' + @prm + '</td></tr>';
          END
          ELSE
          BEGIN
            SET @sMessageR = @sMessageR +
                         '<tr><td colspan="14">無醫師請假</td></tr>';
          END
        
        END
        CLOSE cursor3;
    DEALLOCATE cursor3
      
        SET @sTitleR = '今日醫師請假通知_大昌醫院(' + FORMAT(GETDATE(), 'yyyy-mm-dd') + ')';
      
        IF @sMessageR IS NULL BEGIN
          SET @sMessageR = '<table border="1" width="100%">' +
                       '<tr><th>工號</th><th>姓名</th><th>部門名稱</th><th>職稱</th><th>假別</th>' +
                       '<th>狀態</th><th>開始日期</th><th>開始時間</th><th>結束日期</th><th>結束時間</th>' +
                       '<th>天數</th><th>時數</th><th>請假理由</th><th>其他原因</th></tr>' +
                       '<tr><td colspan="14">無醫師請假</td></tr>';
        END
      
        IF (@sMessageR IS NOT NULL) BEGIN
          SET @sMessageR = @sMessageR + '</table>';
          OPEN cursor2;
          WHILE 1=1 BEGIN
            FETCH NEXT FROM cursor2 INTO @sEEMail;
            IF @@FETCH_STATUS <> 0 BREAK;
          
            EXEC [ehrphrafunc_pkg].[POST_HTML_MAIL] 'system@edah.org.tw',
                                           @sEEMail,
                                           '',
                                           '1',
                                           @sTitleR,
                                           @sMessageR;
          
          END
          CLOSE cursor2;
    DEALLOCATE cursor2
        END
        SET @sMessageR = '';
      END
    END
    CLOSE curtota3_1;
    DEALLOCATE curtota3_1
END
GO
