CREATE OR ALTER PROCEDURE [ehrphrafunc_pkg].[POST_MISMSG_MAIL]
(    @msgno NVARCHAR(MAX),
    @sender NVARCHAR(MAX),
    @recipient NVARCHAR(MAX),
    @subject NVARCHAR(MAX),
    @message NVARCHAR(MAX),
    @msgdate NVARCHAR(MAX)
)
AS
DECLARE @rec_emp NVARCHAR(MAX) /*cursor1%ROWTYPE*/;
DECLARE @Realmessage NVARCHAR(MAX);
DECLARE @Email NVARCHAR(120);
DECLARE cursor1 CURSOR FOR
    SELECT E.CH_NAME+P.CH_NAME AS EMPPOS, E.ORGAN_TYPE
      FROM HRE_EMPBAS E, HRE_POSMST P 
     WHERE E.POS_NO = P.POS_NO
       AND E.EMP_NO = @recipient;
BEGIN
    OPEN cursor1;
    WHILE 1=1 BEGIN
    FETCH NEXT FROM cursor1 INTO @rec_emp;
    IF @@FETCH_STATUS <> 0 BREAK;
      SET @Realmessage = @rec_emp+' 您好：<br><br>'+@message;
      INSERT INTO PUS_MSGMST
        (MSG_NO, MSG_FROM, MSG_TO, subject, MSG_DESC, MSG_DATE, ORG_BY, ORGAN_TYPE)
      VALUES
        (@msgno,
         @sender,
         @recipient,
         @subject,
         @Realmessage,
         CONVERT(DATETIME2, @msgdate),
         @rec_emp, @rec_emp);
      INSERT INTO PUS_MSGBAS (MSG_NO, EMP_NO, ORG_BY, ORGAN_TYPE) VALUES (@msgno, @recipient, @rec_emp, @rec_emp);
    END
    COMMIT TRAN;
    CLOSE cursor1;
    DEALLOCATE cursor1
    
    /*IF SUBSTRING(@recipient,1,1) <> '1' BEGIN
      SET @Email = @recipient + '@edah.org.tw';
    END
    ELSE
    BEGIN
      SET @Email = 'ed' + @recipient + '@edah.org.tw';
    END*/
    SET @Email = 'ed' + @recipient + '@edah.org.tw';
    
    IF @recipient LIKE 'IBM%' BEGIN
      SET @Email = 'ed108482@edah.org.tw';
    END
    
    /* TODO: hrpuser.MAILQUEUE.insertMailQueue(...) */ EXEC insertMailQueue 'system@edah.org.tw',@Email,'',@subject,@Realmessage,'','','1';
END
GO
