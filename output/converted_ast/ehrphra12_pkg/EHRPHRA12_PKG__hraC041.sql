CREATE OR ALTER PROCEDURE [ehrphra12_pkg].[hraC041]
(    @p_emp_no NVARCHAR(MAX),
    @p_uncard_date NVARCHAR(MAX),
    @p_uncard_time NVARCHAR(MAX),
    @p_check_poin NVARCHAR(MAX),
    @p_night_flag NVARCHAR(MAX),
    @OrganType_IN NVARCHAR(MAX),
    @RtnCode DECIMAL(38,10) OUTPUT
)
AS
DECLARE @sEmpNo NVARCHAR(10) = @p_emp_no;
DECLARE @sUnCardDate NVARCHAR(20) = @p_uncard_date;
DECLARE @sUnCardTime NVARCHAR(4) = @p_uncard_time;
DECLARE @sCheckPoin NVARCHAR(10) = @p_check_poin;
DECLARE @sNightFlag NVARCHAR(1) = @p_night_flag;
DECLARE @SOrganType NVARCHAR(10) = @OrganType_IN;
DECLARE @sUnCardType NVARCHAR(1) = SUBSTRING(@p_uncard_time,2,1);
DECLARE @dSignDateT DATETIME2(0) = CONVERT(DATETIME2, @p_uncard_date+@p_check_poin);
DECLARE @sClassCode NVARCHAR(4);
DECLARE @dSchDate DATETIME2(0);
DECLARE @iCnt DECIMAL(38,10);
DECLARE @iCnt2 DECIMAL(38,10);
DECLARE @dStartDate DATETIME2(0);
DECLARE @LimitDay NVARCHAR(2);
BEGIN
    SET @RtnCode = 0;
    IF CONVERT(DATETIME2, @sUnCardDate) > GETDATE() BEGIN
      SET @RtnCode = 2;
      GOTO Continue_ForEach;
    END
    
    IF CONVERT(DATETIME2, @sUnCardDate+@sCheckPoin) > GETDATE() BEGIN
      SET @RtnCode = 2;
      GOTO Continue_ForEach;
    END
    
    --每月申請最多至隔月5號(5號當天可以申請)
    --20241007 by108482 每月申請最多至隔月幾號抓參數HRA89的設定
    BEGIN TRY
    SELECT @LimitDay = CODE_NAME
    FROM HR_CODEDTL
       WHERE CODE_TYPE = 'HRA89'
         AND CODE_NO = 'DAY';
END TRY
BEGIN CATCH
    -- WHEN OTHERS
    SET @LimitDay = '5';
END CATCH
    /*IF CAST(GETDATE() AS DATE) > CAST(DATEADD(MONTH, 1, CONVERT(DATETIME2, @sUnCardDate)) AS DATE) +9 BEGIN
      SET @RtnCode = 3;
      GOTO Continue_ForEach;
    END*/
    IF CAST(GETDATE() AS DATE) > 
       CONVERT(DATETIME2, FORMAT(DATEADD(MONTH, 1, CONVERT(DATETIME2, @sUnCardDate)), 'yyyy-MM')+'-'+@LimitDay) BEGIN
      SET @RtnCode = 3;
      GOTO Continue_ForEach;
    END
    
    IF @sUnCardType = '1' AND @sNightFlag = 'Y' BEGIN
    --加班上班卡且隔夜註記,代表應出勤日為打卡時間的隔天
      SET @dSchDate = DATEADD(DAY, 1, CONVERT(DATETIME2, @sUnCardDate));
    END
ELSE IF @sUnCardType = '2' AND @sNightFlag = 'Y' BEGIN
    --加班下班卡且隔夜註記,代表應出勤日為打卡時間的前一天
      SET @dSchDate = DATEADD(DAY, -1, CONVERT(DATETIME2, @sUnCardDate));
    END
    ELSE
    BEGIN
      SET @dSchDate = CONVERT(DATETIME2, @sUnCardDate);
    END
    SET @sClassCode = [ehrphrafunc_pkg].[f_getClassKind](@sEmpNo, @dSchDate, @SOrganType);
    IF @sClassCode = 'ZX' BEGIN
    --ZX不能出勤加班,應先調班
      SET @RtnCode = 4;
      GOTO Continue_ForEach;
    END
ELSE IF @sClassCode = 'ZQ' AND SUBSTRING(@sEmpNo,1,1) IN ('S','P') BEGIN
    --SP人員ZQ不能出勤加班,應先調班
      SET @RtnCode = 5;
      GOTO Continue_ForEach;
    /*END
ELSE IF @sClassCode NOT IN ('ZZ','ZY','ZQ') BEGIN
      SET @RtnCode = ;
      GOTO Continue_ForEach;*/
    END
    
    SELECT @iCnt = COUNT(*)
    FROM HRA_OTMSIGN
     WHERE EMP_NO = @sEmpNo
       AND ORG_BY = @SOrganType
       AND (FORMAT(START_DATE, 'yyyy-MM-dd') = FORMAT(@dSchDate, 'yyyy-MM-dd') OR 
            FORMAT(START_DATE, 'yyyy-MM-dd') = FORMAT(@dSchDate-1, 'yyyy-MM-dd'))
       AND END_DATE IS NULL
       AND OTM_NO LIKE 'OTS%';
    
    SELECT @iCnt2 = COUNT(*)
    FROM HRA_OTMSIGN
     WHERE EMP_NO = @sEmpNo
       AND ORG_BY = @SOrganType
       AND FORMAT(START_DATE, 'yyyy-MM-dd') = FORMAT(@dSchDate, 'yyyy-MM-dd')
       AND END_DATE IS NOT NULL
       AND OTM_NO LIKE 'OTS%'
       AND FLOOR(((CONVERT(DATETIME2, @sUnCardDate + @sCheckPoin) -
                 CONVERT(DATETIME2, FORMAT(START_DATE, 'yyyy-mm-dd') + START_TIME)) * 24 * 60) / 30) * 0.5 > 0;
         
    IF @sUnCardType = '2' BEGIN
      IF @iCnt = 0 BEGIN
        IF @iCnt2 = 0 BEGIN 
        --補加班下班但無上班記錄,應先補加班上班記錄
          SET @RtnCode = 6;
          GOTO Continue_ForEach;
        END
ELSE IF @iCnt2 <> 1 BEGIN
          SET @RtnCode = 6;
          GOTO Continue_ForEach;
        END
      END
ELSE IF @iCnt > 1 BEGIN
      --補加班下班但多筆上班記錄,先請人資確認加班打卡資料,整理後再重新申請
        SET @RtnCode = 7;
        GOTO Continue_ForEach;
      END
      ELSE
      BEGIN
        SELECT @dStartDate = CONVERT(DATETIME2, FORMAT(START_DATE, 'yyyy-mm-dd')+START_TIME)
    FROM HRA_OTMSIGN
         WHERE EMP_NO = @sEmpNo
           AND ORG_BY = @SOrganType
           AND (FORMAT(START_DATE, 'yyyy-MM-dd') = FORMAT(@dSchDate, 'yyyy-MM-dd') OR 
                FORMAT(START_DATE, 'yyyy-MM-dd') = FORMAT(@dSchDate-1, 'yyyy-MM-dd'))
           AND END_DATE IS NULL
           AND OTM_NO LIKE 'OTS%';
        IF @dSignDateT <= @dStartDate BEGIN
          --下班卡的時間小於上班卡時間,請人員確認填寫的資料
          SET @RtnCode = 8;
          GOTO Continue_ForEach;
        END
      END
    END
ELSE IF @sUnCardType = '1' BEGIN
      IF @iCnt = 1 BEGIN
      --新增加班上班但尚有加班打卡資料不完整,應先補加班下班記錄
        SET @RtnCode = 9;
        GOTO Continue_ForEach;
      END
ELSE IF @iCnt > 1 BEGIN
      --補加班下班但多筆上班記錄,先請人資確認加班打卡資料,整理後再重新申請
        SET @RtnCode = 7;
        GOTO Continue_ForEach;
      END
    END
    
    /*SELECT COUNT(*)
      INTO 
      FROM HRA_OTMSIGN
     WHERE EMP_NO = @sEmpNo
       AND ORG_BY = @SOrganType
       AND (FORMAT(START_DATE, 'yyyy-MM-dd') = FORMAT(@dSchDate, 'yyyy-MM-dd') OR
            FORMAT(START_DATE, 'yyyy-MM-dd') = FORMAT(@dSchDate - 1, 'yyyy-MM-dd'))
       AND END_DATE IS NOT NULL
       AND OTM_NO LIKE 'OTS%'
       AND 30 > (CONVERT(DATETIME2, FORMAT(END_DATE, 'yyyy-MM-dd') + END_TIME) -
                 CONVERT(DATETIME2, FORMAT(START_DATE, 'yyyy-MM-dd') + START_TIME)) * 1440;
    
    IF @sUnCardType = '1' BEGIN
      IF @iCnt2 > 1 BEGIN
        --加班完整記錄且相差小於30分鐘的資料有多筆,作業會無法判斷要更新哪一筆加班卡紀錄,請人員與人資聯繫
        SET @RtnCode = 10;
        GOTO Continue_ForEach;
      END
    END*/
    Continue_ForEach:
END
GO
