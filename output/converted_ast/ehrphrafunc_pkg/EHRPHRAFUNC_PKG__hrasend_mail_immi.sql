CREATE OR ALTER PROCEDURE [ehrphrafunc_pkg].[hrasend_mail_immi]
(    @EmpNo_IN NVARCHAR(MAX),
    @RtnCode DECIMAL(38,10) OUTPUT
)
AS
DECLARE @sEmpName NVARCHAR(200);
DECLARE @sEEMail NVARCHAR(120);
DECLARE @sMessage NVARCHAR(255);
DECLARE @sDeptName NVARCHAR(60);
DECLARE @sPosName NVARCHAR(60);
DECLARE @sTitle NVARCHAR(50);
DECLARE @sOrgan NVARCHAR(120);
DECLARE cursor2 CURSOR FOR
    SELECT CODE_NAME
        FROM HR_CODEDTL
       WHERE CODE_TYPE = 'HRA99'
         AND CODE_NO like 'A%'
         AND DISABLED = 'N';
BEGIN
    BEGIN TRY
    SELECT @sEmpName = hre_empbas.ch_name, @sDeptName = hre_orgbas.ch_name, @sPosName = hre_posmst.ch_name, @sOrgan = (select ban_nm
                from pus_orgsys
               where organ_type =
                     hrp.f_flow_organ(hre_empbas.emp_no,
                                      hre_empbas.organ_type))
    FROM hre_empbas, hre_orgbas, hre_posmst
       WHERE hre_empbas.dept_no = hre_orgbas.dept_no
         and hre_empbas.pos_no = hre_posmst.pos_no
         and hre_empbas.emp_no = @EmpNo_IN;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() IN (1403, 100) BEGIN
        SET @sEmpName = NULL;
        SET @sDeptName = NULL;
    END
END CATCH
  
    SET @sTitle = '出入境管理-輸入症狀通知';
    SET @SMessage = 'MIS出入境管理,' + @sOrgan + ' ' + @EmpNo_IN + '(' + @sEmpName + ')' +
                '輸入相關症狀資料,請進入MIS出入境管理相關報表查詢';
    --抓通知人員的資訊
    OPEN cursor2;
    WHILE 1=1 BEGIN
      FETCH NEXT FROM cursor2 INTO @sEEMail;
      IF @@FETCH_STATUS <> 0 BREAK;
      EXEC [ehrphrafunc_pkg].[POST_HTML_MAIL] 'system@edah.org.tw',
                     @sEEMail,
                     'ed108482@edah.org.tw',
                     '1',
                     @sTitle,
                     @sMessage;
    END
    CLOSE cursor2;
    DEALLOCATE cursor2
    SET @RtnCode = 0;
END
GO
