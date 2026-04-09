CREATE OR ALTER PROCEDURE [ehrphrafunc_pkg].[hrasend_mail]
(    @EmpNo_IN NVARCHAR(MAX),
    @ProcType_IN NVARCHAR(MAX),
    @ProcMsg_IN NVARCHAR(MAX),
    @ExUserID_IN NVARCHAR(MAX),
    @RtnCode DECIMAL(38,10) OUTPUT
)
AS
DECLARE @sEmpName NVARCHAR(200);
DECLARE @sEEMail NVARCHAR(120);
DECLARE @sMessage NVARCHAR(255);
DECLARE @sDeptName NVARCHAR(60);
DECLARE @sPosName NVARCHAR(60);
DECLARE @sComeDate DATETIME2(0);
DECLARE @sTitle NVARCHAR(50);
DECLARE @pMsgno NVARCHAR(20);
BEGIN
    BEGIN TRY
    EXEC [ehrphrafunc_pkg].[POST_HTML_MAIL] 'system@edah.org.tw',
                     'ed101961@edah.org.tw',
                     'ed101961@edah.org.tw',
                     '2',
                     'ㄧ級主管假卡劉協理審核test',
                     'ㄧ級主管假卡劉協理審核test';
      --抓該名員工的資訊
      SELECT
       @sEmpName = hre_empbas.ch_name, @sDeptName = hre_orgbas.ch_name, @sPosName = hre_posmst.ch_name, @sComeDate = hre_empbas.come_date
    FROM hre_empbas, hre_orgbas, hre_posmst
       WHERE hre_empbas.dept_no = hre_orgbas.dept_no
         and hre_empbas.pos_no = hre_posmst.pos_no
         and hre_empbas.emp_no = @EmpNo_IN;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() IN (1403, 100) BEGIN
        --SET @sEMail = NULL;
        SET @sEmpName = NULL;
        SET @sDeptName = NULL;
    END
END CATCH
    --抓通知人員的資訊
    BEGIN TRY
    --抓該名員工簽核者或人事課人員的資訊
      SELECT @sEEMail = hre_empbas.e_mail
    FROM hre_empbas, hre_orgbas
       WHERE (hre_empbas.dept_no = hre_orgbas.dept_no)
         and (hre_empbas.emp_no = @ExUserID_IN);
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() IN (1403, 100) BEGIN
        SET @sEEMail = NULL;
        SET @sEmpName = NULL;
        SET @sDeptName = NULL;
    END
END CATCH
    if (@ProcType_IN = '1') BEGIN
      SET @sEEmail = 'ed100003@edah.org.tw';
    END
    SET @sMessage = CASE @ProcType_IN
    --被通知人(ㄧ級主管假卡劉協理審核完成) WHEN '1'
     WHEN '1' THEN '僅通知您一級主管請假審核已完成-' + @sDeptName + ':' + @EmpNo_IN + '(' + @sEmpName + ')申請' + @ProcMsg_IN + '審核完成' END
    SET @sTitle = CASE @ProcType_IN WHEN '1' THEN '出勤通知-一級主管請假審核完成通知' END
  
    IF LTRIM(RTRIM(@sEEMail)) IS NOT NULL BEGIN
      EXEC [ehrphrafunc_pkg].[POST_HTML_MAIL] 'system@edah.org.tw',
                     @sEEMail,
                     'ed101961@edah.org.tw',
                     '2',
                     @sTitle,
                     @sMessage;
    END
    SET @RtnCode = 0;
END
GO
