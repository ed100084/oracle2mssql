CREATE OR ALTER FUNCTION [ehrphrafunc_pkg].[f_getFlowmergeVacType]
(    @p_flowevcno NVARCHAR(MAX)
)
RETURNS NVARCHAR(MAX)
AS
BEGIN
DECLARE @Rtnvalue NVARCHAR(300);
DECLARE @boolf NVARCHAR(1);
DECLARE @RtnCode NVARCHAR(4000);
DECLARE cursor1 CURSOR FOR
    select vac_name
        from hra_vcrlmst
       where vac_type in (select vac_type
                            from hra_evcrec t1
                           where flow_merge_no = @p_flowevcno
                           group by vac_type);
    SET @RtnCode = '合併假：';
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
        SET @RtnCode = @RtnCode + '、';
      END
      SET @RtnCode = @RtnCode + @Rtnvalue;
    END
    CLOSE cursor1;
    DEALLOCATE cursor1
    RETURN @RtnCode;
END
GO
