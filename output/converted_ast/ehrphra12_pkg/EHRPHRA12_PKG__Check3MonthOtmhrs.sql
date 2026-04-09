CREATE OR ALTER FUNCTION [ehrphra12_pkg].[Check3MonthOtmhrs]
(    @p_emp_no NVARCHAR(MAX),
    @p_start_date NVARCHAR(MAX),
    @p_otm_hrs NVARCHAR(MAX),
    @OrganType_IN NVARCHAR(MAX)
)
RETURNS DECIMAL(38,10)
AS
BEGIN
DECLARE @RtnCode SMALLINT;
DECLARE @sOtmhrs DECIMAL(5,1) = CAST(@p_otm_hrs AS DECIMAL(38,10));
DECLARE @sTotMonAdd DECIMAL(5,1);
DECLARE @sOtmsignHrs DECIMAL(5,1);
DECLARE @sMonClassAdd DECIMAL(5,1);
    SET @RtnCode = 0;
    
    -- EXCEPTION block removed: TRY/CATCH not allowed in T-SQL scalar function

    SELECT  @sTotMonAdd = SUM(CASE WHEN s_class = 'ZZ' THEN (soneott+soneoss+soneuu) WHEN s_class = 'ZQ' THEN (soneott+soneoss+soneuu) WHEN s_class = 'ZY' THEN (soneott+soneoss+soneuu) ELSE sotm_Hrs END)
    FROM  (
          SELECT (select class_code
                    from hra_classsch_view
                   where emp_no = HRA_OFFREC.Emp_No
                     and att_date = FORMAT(ISNULL(Start_Date_Tmp,start_date), 'yyyy-mm-dd')) as s_class,                
                 otm_hrs,
                 soneo,
                 soneott,
                 soneoss,
                 sotm_hrs,
                 soneuu
            FROM HRA_OFFREC
           WHERE FORMAT(ISNULL(Start_Date_Tmp,start_date), 'yyyymm') >= FORMAT(DATEADD(MONTH, -2, CONVERT(DATETIME2, @p_start_date)), 'yyyymm') 
             AND FORMAT(ISNULL(Start_Date_Tmp,start_date), 'yyyymm') <= FORMAT(CONVERT(DATETIME2, @p_start_date), 'yyyymm') 
             AND status <> 'N'
             AND item_type = 'A'
             AND emp_no = @p_emp_no) tt;

    
    IF @sTotMonAdd IS NULL BEGIN
      SET @sTotMonAdd = 0;
    END

    -- EXCEPTION block removed: TRY/CATCH not allowed in T-SQL scalar function

    SELECT @sOtmsignHrs = ISNULL(SUM(OTM_HRS),0)
    FROM HRA_OTMSIGN
       WHERE FORMAT(ISNULL(Start_Date_Tmp,start_date), 'yyyymm') >= FORMAT(DATEADD(MONTH, -2, CONVERT(DATETIME2, @p_start_date)), 'yyyymm')
         AND FORMAT(ISNULL(Start_Date_Tmp,start_date), 'yyyymm') <= FORMAT(CONVERT(DATETIME2, @p_start_date), 'yyyymm') 
         AND status <> 'N'
         AND otm_flag = 'B'
         AND emp_no = @p_emp_no;

    
    IF @sOtmsignHrs IS NULL BEGIN
      SET @sOtmsignHrs = 0;
    END

	  -- EXCEPTION block removed: TRY/CATCH not allowed in T-SQL scalar function

    SELECT @sMonClassAdd = (mon_getadd + mon_addhrs   + mon_spcotm -  mon_cutotm + mon_dutyhrs )
    FROM hra_attvac_view
       WHERE hra_attvac_view.sch_ym = FORMAT(CONVERT(DATETIME2, @p_start_date), 'yyyy-mm') 
		     AND hra_attvac_view.emp_no = @p_emp_no ;


      --IF   (@sOtmsignHrs+@sTotMonAdd+@sMonClassAdd+@sOtmhrs >= 138) THEN
      --20190225 by108482 需求單IMP201901037 加班超過138小時不計算當月排班超時工時
      IF   (@sOtmsignHrs+@sTotMonAdd+@sOtmhrs > 138) BEGIN
        -- PRINT removed: not allowed in T-SQL scalar function
        --PRINT 'OTM_HRS'+CAST(@sOtmsignHrs+@sTotMonAdd+@sMonClassAdd+@sOtmhrs AS NVARCHAR);
        -- PRINT removed: not allowed in T-SQL scalar function
	        SET @RtnCode = 16;
       GOTO Continue_ForEach1 ;
      END
      ELSE
      BEGIN
        SET @RtnCode = 0;
      END
      Continue_ForEach1:
    RETURN @RtnCode;
END
GO
