CREATE OR ALTER FUNCTION [ehrphrafunc_pkg].[f_count_time]
(    @ls_start_date DATETIME2(0),
    @ls_start_time NVARCHAR(MAX),
    @ls_end_date DATETIME2(0),
    @ls_end_time NVARCHAR(MAX)
)
RETURNS DECIMAL(38,10)
AS
BEGIN
DECLARE @li_rtn_time DECIMAL(38,10);
DECLARE @sStartDate NVARCHAR(10);
DECLARE @sEndDate NVARCHAR(10);
  
    SET @sStartDate = FORMAT(@ls_start_date, 'yyyy-mm-dd');
    SET @sEndDate = FORMAT(@ls_end_date, 'yyyy-mm-dd');
  
    SET @li_rtn_time = ROUND(CAST(DATEDIFF(MINUTE,
                                   CONVERT(DATETIME2, @sStartDate + @ls_start_time),
                                   CONVERT(DATETIME2, @sEndDate + @ls_end_time)) AS DECIMAL(38,10)), 0);
  
    ---- by szuhao 2008-01-17 fix------
    /* by szuhao 2008-01-17 fix
    --西元日期相減
    SET @li_days = @ls_end_date - @ls_start_date;
    
    -- 轉換為分
    SET @li_start_time = SUBSTRING(@ls_start_time,1, 2) * 60 + SUBSTRING(@ls_start_time,3, 2);
    SET @li_end_time = SUBSTRING(@ls_end_time,1, 2) * 60 + SUBSTRING(@ls_end_time,3, 2);
    
    IF li_days = 0 BEGIN  --同一天
       SET @li_time = li_end_time - li_start_time;
       IF li_time < 0 BEGIN
          SET @li_time = li_time + 1440;
       END
    END
    ELSE
    BEGIN
       SET @li_time = 1440 - li_start_time + li_end_time + 1440 * (li_days - 1);
    END
    
    -- SET @li_rtn_time = ls_h + ls_m;
    SET @li_rtn_time = li_time;
    */
    -----------------
    return @li_rtn_time;
END
GO
