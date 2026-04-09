CREATE OR ALTER PROCEDURE [ehrphra12_pkg].[hraD010]
(    @p_emp_no NVARCHAR(MAX),
    @p_start_date NVARCHAR(MAX),
    @p_start_time NVARCHAR(MAX),
    @p_end_date NVARCHAR(MAX),
    @p_end_time NVARCHAR(MAX),
    @P_otm_hrs NVARCHAR(MAX),
    @RtnCode DECIMAL(38,10) OUTPUT
)
AS
DECLARE @sEmpNo NVARCHAR(MAX) /*hra_offrec.emp_no%TYPE*/ = @p_emp_no;
DECLARE @sStart NVARCHAR(20) = @p_start_date + @p_start_time;
DECLARE @sEnd NVARCHAR(20) = @p_end_date + @p_end_time;
DECLARE @sStart1 NVARCHAR(20);
DECLARE @sEnd1 NVARCHAR(20);
DECLARE @iCnt INT;
DECLARE @cVac_V DECIMAL(5,1);
DECLARE @cVac_SUP DECIMAL(5,1);
BEGIN
       SET @RtnCode = 0;

       --因 BETWEEN 會比較前後值,故 START + 1 分鐘 , END -1 分鐘 來跳過
       SET @sStart1 = FORMAT(DATEADD(MINUTE, 1, CONVERT(DATETIME2, @sStart)), 'yyyy-MM-ddhhmm');
       SET @sEnd1 = FORMAT(DATEADD(MINUTE, -1, CONVERT(DATETIME2, @sEnd)), 'yyyy-MM-ddhhmm');


       ------------------------- 積休單 -------------------------
       --(檢核在資料庫中除''不准''以外的積休單申請時間是否重疊)

       --現有的補休單時間介於新積休單
         BEGIN TRY
    SELECT @iCnt = COUNT(*)
    FROM hra_DSUPREC
           WHERE  emp_no    = @sEmpNo
             AND ((@sStart1  between FORMAT(start_date, 'yyyy-MM-dd') + start_time and FORMAT(end_date, 'yyyy-MM-dd') + end_time)
              OR  ( @sEnd1    between FORMAT(start_date, 'yyyy-MM-dd') + start_time and FORMAT(end_date, 'yyyy-MM-dd') + end_time ))
             AND status <> 'N' ;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() IN (1403, 100) BEGIN
        SET @iCnt = 0;
    END
END CATCH

       IF @iCnt = 0 BEGIN

       --新補休單介於現有的積休單時間
       BEGIN TRY
    SELECT @iCnt = COUNT(*)
    FROM hra_DSUPREC
           WHERE emp_no    = @sEmpNo
             AND ((FORMAT(start_date, 'yyyy-MM-dd') + start_time between @sStart1 and @sEnd1)
              OR  (FORMAT(end_date, 'yyyy-MM-dd')   + end_time   between @sStart1 and @sEnd1))
             AND status <> 'N' ;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() IN (1403, 100) BEGIN
        SET @iCnt = 0;
    END
END CATCH
       END

       IF @iCnt > 0 BEGIN
       SET @RtnCode = 1;
       GOTO Continue_ForEach1 ;
       END

      --ERROR CODE 16 請特休＋補休不可超過10天

         BEGIN TRY
    SELECT @cVac_V = ISNULL(SUM( ISNULL(VAC_DAYS,0) *8 + ISNULL(VAC_HRS,0)),0)
    FROM HRP.HRA_DEVCREC
             WHERE VAC_TYPE = 'V'
               AND EMP_NO = @sEmpNo
               AND STATUS = 'Y'
               AND FORMAT(START_DATE, 'yyyy-MM') = SUBSTRING(@p_start_date, 1, 7) ;
END TRY
BEGIN CATCH
    -- WHEN OTHERS
    SET @cVac_V = 0;
END CATCH

         BEGIN TRY
    SELECT @cVac_SUP = ISNULL(SUM( ISNULL(OTM_HRS,0)),0)
    FROM HRP.HRA_DSUPREC
             WHERE EMP_NO = @sEmpNo
               AND STATUS = 'Y'
               AND FORMAT(START_DATE, 'yyyy-MM') = SUBSTRING(@p_start_date, 1, 7) ;
END TRY
BEGIN CATCH
    -- WHEN OTHERS
    SET @cVac_SUP = 0;
END CATCH

          IF @cVac_V + @cVac_SUP + @P_otm_hrs > 80 BEGIN
          SET @RtnCode = 16;
          GOTO Continue_ForEach1;
          END
       Continue_ForEach1:
END
GO
