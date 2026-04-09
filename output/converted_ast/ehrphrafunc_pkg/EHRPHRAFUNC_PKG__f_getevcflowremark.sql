CREATE OR ALTER FUNCTION [ehrphrafunc_pkg].[f_getevcflowremark]
(    @p_evc_no NVARCHAR(MAX)
)
RETURNS NVARCHAR(MAX)
AS
BEGIN
DECLARE @Rtnvalue NVARCHAR(800);
DECLARE @boolf NVARCHAR(1);
DECLARE @RtnCode NVARCHAR(4000);
DECLARE cursor1 CURSOR FOR
    SELECT (select ch_name
                from hre_empbas
               where emp_no = HraEvcFlow.PERMIT_ID
                 AND ORGAN_TYPE =
                     (SELECT ORG_BY FROM HRA_EVCREC WHERE EVC_NO = @p_evc_no)) + '(' +
             (select ch_name
                from hre_posmst
               where pos_no = (select pos_no
                                 from hre_empbas
                                where emp_no = HraEvcFlow.PERMIT_ID
                                  and ORGAN_TYPE =
                                      (SELECT ORG_BY
                                         FROM HRA_EVCREC
                                        WHERE EVC_NO = @p_evc_no))) +
             ')(分機:' + (select ext_tel
                           from hre_adrbook
                          where emp_no = HraEvcFlow.PERMIT_ID) + '):' +
             CASE HraEvcflow.STATUS
               WHEN 'U' THEN
                '請示'
               WHEN 'D' THEN
                '取消'
               WHEN 'N' THEN
                '不准'
               WHEN 'Y' THEN
                '准'
               ELSE
                ''
             END + 'abdc簽核意見:' + ISNULL(HraEvcflow.PERMIT_REMARK, '(無)') + ', ' +
             FORMAT(LAST_UPDATE_DATE, 'yyyy-mm-dd')
        FROM HRA_EVCFLOW HraEvcflow
       WHERE HraEvcflow.EVC_NO = @p_evc_no;
    SET @RtnCode = '';
    SET @boolf = '0';
    OPEN cursor1;
    WHILE 1=1 BEGIN
      FETCH NEXT FROM cursor1 INTO @Rtnvalue;
      IF @@FETCH_STATUS <> 0 BREAK;
      if (@boolf = '0') BEGIN
        SET @boolf = '1';
      END
      ELSE
      BEGIN
        SET @RtnCode = @RtnCode + 'cadb';
      END
      SET @RtnCode = @RtnCode + @Rtnvalue;
    END
    CLOSE cursor1;
    DEALLOCATE cursor1
    RETURN @RtnCode;
END
GO
