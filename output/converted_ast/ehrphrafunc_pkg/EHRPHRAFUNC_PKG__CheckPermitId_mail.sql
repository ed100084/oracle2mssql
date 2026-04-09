CREATE OR ALTER PROCEDURE [ehrphrafunc_pkg].[CheckPermitId_mail]
AS
DECLARE @pempno NVARCHAR(20);
DECLARE @pdate NVARCHAR(20);
DECLARE @ppermitid NVARCHAR(20);
DECLARE @sTitle NVARCHAR(100);
DECLARE @sEEMail NVARCHAR(120);
DECLARE @sMessage NVARCHAR(MAX);
DECLARE cursor1 CURSOR FOR
    SELECT EMP_NO,
             FORMAT(START_DATE, 'yyyy-mm-dd') AS START_DATE,
             PERMIT_ID
        FROM HRA_OFFREC
       WHERE PERMIT_ID = '100005'
         AND STATUS NOT IN ('Y', 'N')
         AND EMP_NO <> '100102'
      UNION
      SELECT EMP_NO,
             FORMAT(START_DATE, 'yyyy-mm-dd') AS START_DATE,
             PERMIT_ID
        FROM HRA_OTMSIGN
       WHERE PERMIT_ID = '100005'
         AND STATUS NOT IN ('Y', 'N')
         AND OTM_FLAG = 'B'
         AND EMP_NO <> '100102';
DECLARE cursor2 CURSOR FOR
    SELECT 'ed108154@edah.org.tw'
        FROM dual 
      UNION ALL
      SELECT 'ed108482@edah.org.tw'
        FROM dual 
      UNION ALL
      SELECT 'ed100037@edah.org.tw'
        FROM dual;
BEGIN
    SET @sMessage = '';
    SET @sEEMail = '';
    SET @sTitle = '確認加班單審核者';
  
    OPEN cursor1;
    WHILE 1=1 BEGIN
      FETCH NEXT FROM cursor1 INTO @pempno, @pdate, @ppermitid;
      IF @@FETCH_STATUS <> 0 BREAK;
      IF @sMessage IS NULL BEGIN
        SET @sMessage = '<table border="1"><tr><td>工號</td><td>日期</td><td>審核者</td></tr>' +
                    '<tr><td>' + @pempno + '</td><td>' + @pdate +
                    '</td><td>' + @ppermitid + '</td></tr>';
      END
      ELSE
      BEGIN
        SET @sMessage = @sMessage + '<tr><td>' + @pempno + '</td><td>' +
                    @pdate + '</td><td>' + @ppermitid + '</td></tr>';
      END
    END
    CLOSE cursor1;
    DEALLOCATE cursor1
  
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
END
GO
