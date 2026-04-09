CREATE OR ALTER PROCEDURE [ehrphra12_pkg].[hraC030_add]
(    @p_emp_no NVARCHAR(MAX),
    @p_start_date NVARCHAR(MAX),
    @p_start_date_tmp NVARCHAR(MAX),
    @p_otm_hrs NVARCHAR(MAX),
    @OrganType_IN NVARCHAR(MAX),
    @RtnCode DECIMAL(38,10) OUTPUT
)
AS
DECLARE @sClassCode NVARCHAR(3);
DECLARE @sWorkHrs DECIMAL(5,1);
DECLARE @sTotAddHrs DECIMAL(5,1);
DECLARE @sTotMonAdd DECIMAL(5,1);
DECLARE @sOtmsignHrs DECIMAL(5,1);
DECLARE @sOtmhrs DECIMAL(5,1) = CAST(@p_otm_hrs AS DECIMAL(38,10));
BEGIN
    SET @RtnCode = 0;
    SET @sWorkHrs = 0;
    SET @sTotAddHrs = 0;
    SET @sTotMonAdd = 0;
    SET @sOtmsignHrs = 0;
    
    SET @sClassCode = [ehrphrafunc_pkg].[f_getClassKind](@p_emp_no,CONVERT(DATETIME2, ISNULL(@p_start_date_tmp, @p_start_date)),@OrganType_IN);
    
    BEGIN TRY
    --當日班別時數
      SELECT @sWorkHrs = WORK_HRS
    FROM HRA_CLASSMST
       WHERE CLASS_CODE = @sClassCode;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() IN (1403, 100) BEGIN
        SET @sWorkHrs = 0;
    END
END CATCH
    
    BEGIN TRY
    --當日在途加班費申請時數
      SELECT @sTotAddHrs = SUM(SOTM_HRS)
    FROM HRA_OFFREC
       WHERE FORMAT(ISNULL(Start_Date_Tmp,Start_Date), 'yyyy-mm-dd') = ISNULL(@p_start_date_tmp, @p_start_date)
         AND status <> 'N'
         AND item_type = 'A'
         AND emp_no = @p_emp_no;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() IN (1403, 100) BEGIN
        SET @sTotAddHrs = 0;
    END
END CATCH
    
    IF @sOtmhrs IS NULL BEGIN SET @sOtmhrs = 0; END
    IF @sWorkHrs IS NULL BEGIN SET @sWorkHrs = 0; END
    IF @sTotAddHrs IS NULL BEGIN SET @sTotAddHrs = 0; END
    
    IF (@sOtmhrs + @sWorkHrs + @sTotAddHrs)> 12 BEGIN
      SET @RtnCode = 1;
      GOTO Continue_ForEach1;
    END
  
    BEGIN TRY
    SELECT @sTotMonAdd = ISNULL(sum(CASE WHEN s_class = 'ZZ' THEN (soneott+soneoss+soneuu) WHEN s_class = 'ZQ' THEN (soneott+soneoss+soneuu) WHEN s_class = 'ZY' THEN (soneott+soneoss+soneuu) ELSE sotm_Hrs END),0)
    FROM (SELECT (SELECT class_code
                        FROM hra_classsch_view
                       WHERE emp_no = HRA_OFFREC.Emp_No
                         AND att_date = FORMAT(start_date, 'yyyy-mm-dd')) as s_class,                
                     otm_hrs,
                     soneo,
                     soneott,
                     soneoss,
                     sotm_hrs,
                     soneuu
                FROM HRA_OFFREC
               WHERE FORMAT(ISNULL(Start_Date_Tmp,start_date), 'yyyy-mm') = 
                     SUBSTRING(ISNULL(@p_start_date_tmp, @p_start_date), 1, 7)
                 AND status <> 'N'
                 AND item_type = 'A'
                 AND emp_no = @p_emp_no) tt;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() IN (1403, 100) BEGIN
        SET @sTotMonAdd = 0;
    END
END CATCH
    
    BEGIN TRY
    SELECT @sOtmsignHrs = ISNULL(SUM(OTM_HRS),0)
    FROM HRA_OTMSIGN
       WHERE FORMAT(ISNULL(Start_Date_Tmp,start_date), 'yyyy-mm') = 
             SUBSTRING(ISNULL(@p_start_date_tmp, @p_start_date), 1, 7)
         AND status <> 'N'
         AND otm_flag = 'B'
         AND emp_no = @p_emp_no;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() IN (1403, 100) BEGIN
        SET @sOtmsignHrs = 0;
    END
END CATCH
    
    IF @sTotMonAdd IS NULL BEGIN SET @sTotMonAdd = 0; END
    IF @sOtmsignHrs IS NULL BEGIN SET @sOtmsignHrs = 0; END
    IF (@sOtmhrs + @sTotMonAdd + @sOtmsignHrs) > 54 BEGIN
      SET @RtnCode = 2;
      GOTO Continue_ForEach1;
    END
    
    SET @RtnCode = [ehrphra12_pkg].[Check3MonthOtmhrs](@p_emp_no, ISNULL(@p_start_date_tmp,@p_start_date), @p_otm_hrs, @OrganType_IN);
    IF @RtnCode = 16 BEGIN
      SET @RtnCode = 3;
      GOTO Continue_ForEach1;
    END
    Continue_ForEach1:
END
GO
