CREATE OR ALTER PROCEDURE [ehrphrafunc_pkg].[hrasend_mail_IT]
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
DECLARE @prm2 NVARCHAR(50);
DECLARE @sTitle NVARCHAR(100);
DECLARE @sEEMail NVARCHAR(120);
DECLARE @sMessage NVARCHAR(MAX);
DECLARE @sMessage2 NVARCHAR(MAX);
DECLARE @sMessage3 NVARCHAR(500);
DECLARE @iCntTime DECIMAL(38,10);
DECLARE @iCntNow DECIMAL(38,10);
DECLARE @iCntCovid DECIMAL(38,10);
DECLARE @iCntPerson DECIMAL(38,10);
DECLARE @iCntAll DECIMAL(38,10);
DECLARE @iPercent DECIMAL(38,10);
DECLARE @iPercentC DECIMAL(38,10);
DECLARE cursor1 CURSOR FOR
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
                 AND CONVERT(DATETIME2, CODE_DTL) >= CAST(GETDATE() AS DATE)) AS REMARK2
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
                             FORMAT(START_DATE, 'yyyy-mm-dd') SD,
                             START_TIME ST,
                             FORMAT(END_DATE, 'yyyy-mm-dd') ED,
                             END_TIME ET,
                             EVC_REA,
                             VAC_DAYS,
                             VAC_HRS,
                             REMARK,
                             ABROAD
                        FROM HRA_EVCREC T1
                       WHERE STATUS IN ('Y', 'U')) AS _dt1
               WHERE SD <= FORMAT(GETDATE(), 'yyyy-mm-dd')
                 AND ED >= FORMAT(GETDATE(), 'yyyy-mm-dd')
                 AND EMP_NO IN (SELECT CODE_NO
                                  FROM PUS_CODEBAS
                                 WHERE CODE_TYPE = 'IT01'
                                   AND CONVERT(DATETIME2, CODE_DTL) >=
                                       CAST(GETDATE() AS DATE))
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
                             FORMAT(START_DATE, 'yyyy-mm-dd') SD,
                             START_TIME ST,
                             FORMAT(END_DATE, 'yyyy-mm-dd') ED,
                             END_TIME ET,
                             SUP_REA EVC_REA,
                             0 VAC_DAYS,
                             SUP_HRS VAC_HRS,
                             REMARK,
                             ABROAD
                        FROM HRA_SUPMST T1
                       WHERE STATUS IN ('Y', 'U')) AS _dt2
               WHERE SD <= FORMAT(GETDATE(), 'yyyy-mm-dd')
                 AND ED >= FORMAT(GETDATE(), 'yyyy-mm-dd')
                 AND EMP_NO IN (SELECT CODE_NO
                                  FROM PUS_CODEBAS
                                 WHERE CODE_TYPE = 'IT01'
                                   AND CONVERT(DATETIME2, CODE_DTL) >=
                                       CAST(GETDATE() AS DATE))) TA,
             HRE_EMPBAS TB
       WHERE TA.EMP_NO = TB.EMP_NO
       ORDER BY TA.SD, TA.ED, TA.ST, TA.ET;
DECLARE cursor3 CURSOR FOR
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
                   WHERE START_DATE <= CAST(GETDATE() AS DATE)
                     AND END_DATE >= CAST(GETDATE() AS DATE)
                     AND EMP_NO = A.CODE_NO
                     AND FORMAT(GETDATE(), 'yyyy-mm-dd') <= A.CODE_DTL)
         AND 0 = (SELECT COUNT(*)
                    FROM HRA_SUPMST
                   WHERE START_DATE <= CAST(GETDATE() AS DATE)
                     AND END_DATE >= CAST(GETDATE() AS DATE)
                     AND EMP_NO = A.CODE_NO
                     AND FORMAT(GETDATE(), 'yyyy-mm-dd') <= A.CODE_DTL)
         AND FORMAT(GETDATE(), 'yyyy-mm-dd') <= A.CODE_DTL
       ORDER BY A.CODE_NAME;
DECLARE cursor4 CURSOR FOR
    SELECT A.CODE_NO,
             B.CH_NAME,
             (SELECT CH_NAME FROM HRE_ORGBAS WHERE DEPT_NO = B.DEPT_NO) DEPTNAME,
             (SELECT CH_NAME FROM HRE_POSMST WHERE POS_NO = B.POS_NO) POSNAME,
             A.CODE_NAME
        FROM PUS_CODEBAS A, HRE_EMPBAS B
       WHERE A.CODE_NO = B.EMP_NO
         AND A.CODE_TYPE = 'IT01'
         AND FORMAT(GETDATE(), 'yyyy-mm-dd') > A.CODE_DTL
         AND B.DISABLED = 'N'
       ORDER BY A.CODE_DTL DESC;
DECLARE cursor2 CURSOR FOR
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
    SET @sMessage = '';
    OPEN cursor1;
    WHILE 1=1 BEGIN
      FETCH NEXT FROM cursor1 INTO @pempno, @pchname, @pdeptname, @pposname, @pvacname, @pstatusname, @psd, @pst, @ped, @pet, @pevcrea, @pvacdays, @pvachrs, @prm, @prm2;
      IF @@FETCH_STATUS <> 0 BREAK;
    
      IF @sMessage is null BEGIN
        SET @sMessage = '<table border="1" width="100%"><TR><TD>工號</td><TD>姓名</td><TD>部門名稱</td><TD>職稱</td><TD>假別</td>';
        SET @sMessage = @sMessage +
                    '<TD>狀態</td><TD>開始日期</td><TD>開始時間</td><TD>結束日期</td><TD>結束時間</td>';
        SET @sMessage = @sMessage +
                    '<TD>天數</td><TD>時數</td><TD>請假理由</td><TD>其他原因</td><TD>備註</td></tr>';
        SET @sMessage = @sMessage + '<TR><TD>' + @pempno + '</td><TD>' +
                    @pchname + '</td><TD>' + @pdeptname + '</td>';
        SET @sMessage = @sMessage + '<TD>' + @pposname + '</td><TD>' +
                    @pvacname + '</td><TD>' + @pstatusname + '</td>';
        SET @sMessage = @sMessage + '<TD>' + @psd + '</td><TD>' + @pst +
                    '</td><TD>' + @ped + '</td>';
        SET @sMessage = @sMessage + '<TD>' + @pet + '</td><TD>' + @pvacdays +
                    '</td><TD>' + @pvachrs + '</td>';
        SET @sMessage = @sMessage + '<TD>' + @pevcrea + '</td><TD>' + @prm +
                    '</td><TD>' + @prm2 + '</td></tr>';
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
                    '</td><TD>' + @prm2 + '</td></tr>';
      END
    END
    CLOSE cursor1;
    DEALLOCATE cursor1
  
    OPEN cursor3;
    WHILE 1=1 BEGIN
      FETCH NEXT FROM cursor3 INTO @pempno, @pchname, @pdeptname, @pposname, @prm, @prm2;
      IF @@FETCH_STATUS <> 0 BREAK;
      IF @sMessage IS NULL BEGIN
        SET @sMessage = '<table border="1" width="100%"><TR><TD>工號</td><TD>姓名</td><TD>部門名稱</td><TD>職稱</td><TD>假別</td>';
        SET @sMessage = @sMessage +
                    '<TD>狀態</td><TD>開始日期</td><TD>開始時間</td><TD>結束日期</td><TD>結束時間</td>';
        SET @sMessage = @sMessage +
                    '<TD>天數</td><TD>時數</td><TD>請假理由</td><TD>其他原因</td><TD>備註</td></tr>';
        SET @sMessage = @sMessage + '<TR><TD>' + @pempno + '</td><TD>' +
                    @pchname + '</td><TD>' + @pdeptname + '</td>';
        SET @sMessage = @sMessage + '<TD>' + @pposname +
                    '</td><TD colspan="10">' + @prm + '</td><TD>' + @prm2 +
                    '</td></tr>';
      END
      ELSE
      BEGIN
        SET @sMessage = @sMessage + '<TR><TD>' + @pempno + '</td><TD>' +
                    @pchname + '</td><TD>' + @pdeptname + '</td>';
        SET @sMessage = @sMessage + '<TD>' + @pposname +
                    '</td><TD colspan="10">' + @prm + '</td><TD>' + @prm2 +
                    '</td></tr>';
      END
    END
    CLOSE cursor3;
    DEALLOCATE cursor3
  
    OPEN cursor4;
    WHILE 1=1 BEGIN
      FETCH NEXT FROM cursor4 INTO @pempno, @pchname, @pdeptname, @pposname, @prm;
      IF @@FETCH_STATUS <> 0 BREAK;
      IF @sMessage2 IS NULL BEGIN
        SET @sMessage2 = '<table border="1" width="50%"><TR><TD>工號</td><TD>姓名</td><TD>部門名稱</td><TD>職稱</td><TD>備註</td></tr>' +
                     '<TR><TD>' + @pempno + '</td><TD>' + @pchname +
                     '</td><TD>' + @pdeptname + '</td><TD>' + @pposname +
                     '</td><TD>' + @prm + '</td></tr>';
      END
      ELSE
      BEGIN
        SET @sMessage2 = @sMessage2 + '<TR><TD>' + @pempno + '</td><TD>' +
                     @pchname + '</td><TD>' + @pdeptname + '</td><TD>' +
                     @pposname + '</td><TD>' + @prm + '</td></tr>';
      END
    END
    CLOSE cursor4;
    DEALLOCATE cursor4
  
    SET @sTitle = '今日資訊部COVID-19人員請假彙總表(' + FORMAT(GETDATE(), 'yyyy-mm-dd') + ')';
  
    BEGIN TRY
    SELECT @iCntTime = COUNT(*)
    FROM PUS_CODEBAS
       WHERE CODE_TYPE = 'IT01'
         AND CODE_NO IN
             (SELECT EMP_NO FROM HRE_EMPBAS WHERE DISABLED = 'N');
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() IN (1403, 100) BEGIN
        SET @iCntTime = 0;
    END
END CATCH
    BEGIN TRY
    SELECT @iCntNow = COUNT(*)
    FROM PUS_CODEBAS
       WHERE CODE_TYPE = 'IT01'
         AND CODE_NO IN
             (SELECT EMP_NO FROM HRE_EMPBAS WHERE DISABLED = 'N')
         AND CONVERT(DATETIME2, CODE_DTL) >= CAST(GETDATE() AS DATE);
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() IN (1403, 100) BEGIN
        SET @iCntNow = 0;
    END
END CATCH
    BEGIN TRY
    SELECT @iCntCovid = COUNT(*)
    FROM (SELECT DISTINCT (CODE_NO)
                FROM PUS_CODEBAS
               WHERE CODE_TYPE = 'IT01'
                 AND CODE_NO IN
                     (SELECT EMP_NO FROM HRE_EMPBAS WHERE DISABLED = 'N')
                 AND CODE_VALUE = 1) AS _dt3;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() IN (1403, 100) BEGIN
        SET @iCntCovid = 0;
    END
END CATCH
    BEGIN TRY
    SELECT @iCntPerson = COUNT(*)
    FROM PUS_CODEDTL
       WHERE CODE_TYPE = 'IT01'
         AND CODE_NO IN
             (SELECT EMP_NO FROM HRE_EMPBAS WHERE DISABLED = 'N');
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() IN (1403, 100) BEGIN
        SET @iCntPerson = 0;
    END
END CATCH
    BEGIN TRY
    SELECT @iCntAll = COUNT(*)
    FROM HRE_EMPBAS
       WHERE DEPT_NO IN
             ('5500', '5510', '5511', '5512', '5513', '5520', '5521', '5522',
              '5530', '5531', '5532', 'CA5000', 'CA5100', 'CA5110', 'CA5120',
              'CA5200', 'CA5210', 'CA5220', 'CA5300', 'CA5310', 'CA5320',
              'CA5330', 'DA5000')
         AND DISABLED = 'N';
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() IN (1403, 100) BEGIN
        SET @iCntAll = 0;
    END
END CATCH
  
    SET @iPercent = ROUND((@iCntPerson / @iCntAll) * 100, 0);
    SET @iPercentC = ROUND((@iCntCovid / @iCntAll) * 100, 0);
  
    SET @sMessage3 = '資訊部今日隔離中人數共' + @iCntNow + '人，累計共' + @iCntCovid +
                 '人確診，確診率：' + @iPercentC + '%。<br>' + '累計居家隔離共' +
                 @iCntPerson + '人(' + @iCntTime + '人次)，居隔率：' + @iPercent + '%。';
    /*SET @sMessage3 = '資訊部目前居家隔離總計'+@iCntTime+'人次，共'+@iCntPerson+
    '人隔離(含隔離中'+@iCntNow+'人)，居隔率：'+@iPercent+'%；'+
    @iCntCovid+'人確診，確診率：'+@iPercentC+'%。';*/
  
    IF (@sMessage IS NOT NULL) BEGIN
      SET @sMessage = @sMessage3 + '<br><br>今日隔離人員：<br>' + @sMessage +
                  '</table>';
      IF (@sMessage2 IS NOT NULL) BEGIN
        SET @sMessage = @sMessage + '<br><br>已解除隔離人員：<br>' + @sMessage2 +
                    '</table>';
      END
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
      SET @sMessage = @sMessage3 + '<br><br>截至上午07:00，今日(' +
                  FORMAT(GETDATE(), 'yyyy-mm-dd') + ')';
      SET @sMessage = @sMessage + '資訊部無COVID-19居隔中人員通報。';
      IF (@sMessage2 IS NOT NULL) BEGIN
        SET @sMessage = @sMessage + '<br><br>已解除隔離人員：<br>' + @sMessage2 +
                    '</table>';
      END
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
GO
