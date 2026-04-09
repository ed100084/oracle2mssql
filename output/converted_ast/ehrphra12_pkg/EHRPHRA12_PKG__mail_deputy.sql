CREATE OR ALTER PROCEDURE [ehrphra12_pkg].[mail_deputy]
(    @p_D_emp_no NVARCHAR(MAX),
    @p_start_date NVARCHAR(MAX),
    @p_end_date NVARCHAR(MAX),
    @p_P_emp_no NVARCHAR(MAX),
    @p_emp_no NVARCHAR(MAX),
    @p_OrganType_IN NVARCHAR(MAX)
)
AS
DECLARE @s_EmpName NVARCHAR(200);
DECLARE @s_PosName NVARCHAR(100);
DECLARE @s_D_EmpName NVARCHAR(200);
DECLARE @s_D_PosName NVARCHAR(100);
DECLARE @s_P_EmpName NVARCHAR(20);
DECLARE @s_D_EMail NVARCHAR(120);
DECLARE @s_P_EMail NVARCHAR(120);
DECLARE @iCnt INT;
DECLARE @Message NVARCHAR(MAX);
DECLARE @ipaddress NVARCHAR(16);
DECLARE @sOrganType NVARCHAR(10);
BEGIN
    SET @sOrganType = @p_OrganType_IN;
    SET @iCnt = 0;
   
        SELECT @ipaddress = utl_inaddr.get_host_address
    FROM dual;

        SELECT @s_EmpName = CH_NAME, @s_PosName = (SELECT CH_NAME FROM HRE_POSMST WHERE POS_NO = HRP.HRE_EMPBAS.POS_NO)
    FROM HRP.HRE_EMPBAS
         Where EMP_NO = @p_emp_no
           and organ_type = @sOrganType;

      BEGIN TRY
    SELECT @s_D_EmpName = CH_NAME, @s_D_EMail = 'ed'+Emp_No+'@edah.org.tw', @s_D_PosName = (SELECT CH_NAME FROM HRE_POSMST WHERE POS_NO = HRP.HRE_EMPBAS.POS_NO)
    FROM HRP.HRE_EMPBAS
         Where EMP_NO = @p_D_emp_no
          and disabled = 'N'
          and organ_type = @sOrganType;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() IN (1403, 100) BEGIN
        SET @iCnt = 1;
    END
END CATCH

      IF @iCnt = 0 BEGIN
      IF NOT (@s_D_EMail IS NULL  OR  @s_D_EMail = '') BEGIN
          SET @Message = @s_D_EmpName + @s_D_PosName + ' 您好 :<br><br> '  + @s_EmpName + @s_PosName + '(' +@p_emp_no +') 於 '+ @p_start_date + ' 至 ' + @p_end_date + ' 請假'
                      +' <br>謹此通知您是他(她)的指定代理人 <br><br> 感謝您的參與配合!<br><br>人事課敬啟 '+
                      FORMAT(GETDATE(), 'yyyy-MM-dd hh:mm')+'<br><br> '+@ipaddress;

         -- [ehrphrafunc_pkg].[POST_HTML_MAIL]('edhr@edah.org.tw',@s_D_EMail,'ed108978@edah.org.tw','1','請假代理人通知',@Message);
          /* TODO: hrpuser.MAILQUEUE.insertMailQueue(...) */ EXEC insertMailQueue 'edhr@edah.org.tw',@s_D_EMail,'','請假代理人通知',@Message,'','', '1';
      END
      END
END
GO
