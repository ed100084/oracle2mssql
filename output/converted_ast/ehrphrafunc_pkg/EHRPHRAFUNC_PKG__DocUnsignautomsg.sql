CREATE OR ALTER PROCEDURE [ehrphrafunc_pkg].[DocUnsignautomsg]
AS
DECLARE @pMsg NVARCHAR(300);
DECLARE @pEmpno NVARCHAR(20);
DECLARE @pChname NVARCHAR(200);
DECLARE @pCreationdate NVARCHAR(10);
DECLARE @pStatus NVARCHAR(20);
DECLARE @pCnt DECIMAL(38,10);
DECLARE @sSEQNO DECIMAL(38,10);
DECLARE @iMSG_NO NVARCHAR(20);
DECLARE cursor1 CURSOR FOR
    select emp_no,
             (select ch_name from hre_empbas where emp_no = t1.emp_no) chname,
             FORMAT(CAST(creation_date AS DATE), 'yyyy-mm-dd'),
             case
               when CAST(creation_date AS DATE) = CAST(DATEADD(DAY, -3, GETDATE()) AS DATE) then
                '代理人'
               else
                '代理人或主管'
             end msgfor,
             count(emp_no) cnt
        from hra_devcrec t1
       where deputy_all = 'N'
         and dis_all = 'N'
         and CAST(creation_date AS DATE) = CAST(DATEADD(DAY, -3, GETDATE()) AS DATE)
          or ((status = 'U' or deputy_all = 'N') and dis_all = 'N' and
             CAST(creation_date AS DATE) = CAST(DATEADD(DAY, -7, GETDATE()) AS DATE))
       group by emp_no, CAST(creation_date AS DATE);
BEGIN
    SET @pMsg = '';
  
    OPEN cursor1;
    WHILE 1=1 BEGIN
      FETCH NEXT FROM cursor1 INTO @pEmpno, @pChname, @pCreationdate, @pStatus, @pCnt;
      IF @@FETCH_STATUS <> 0 BREAK;
    
      SELECT @sSEQNO = SEQNO_NEXT
    FROM HR_SEQCTL
       WHERE SEQNO_TYPE = 'HRA';
    
      SET @iMSG_NO = 'HRA' + FORMAT(GETDATE(), 'yyMM') + CAST(@sSEQNO AS NVARCHAR);
    
      SET @pMsg = '人力資源室提醒您於' + @pCreationdate + '申請之' + CAST(@pCnt AS NVARCHAR) +
              '筆假卡,尚未通過' + @pStatus + '簽核';
    
      INSERT INTO PUS_MSGMST
        (MSG_NO, MSG_FROM, MSG_TO, SUBJECT, MSG_DESC, MSG_DATE)
      VALUES
        (@iMSG_NO,
         '人力資源室',
         @pEmpno + '(' + @pChname + ')',
         '假卡未簽通知',
         @pMsg,
         GETDATE());
    
      INSERT INTO PUS_MSGBAS (MSG_NO, EMP_NO) VALUES (@iMSG_NO, @pEmpno);
    
      UPDATE HR_SEQCTL
         SET SEQNO_NEXT = case when seqno_next + 1 > 100000 then 10000 else seqno_next + 1 end
       WHERE SEQNO_TYPE = 'HRA';
    
    END
    CLOSE cursor1;
    DEALLOCATE cursor1
  
    COMMIT TRAN;
END
GO
