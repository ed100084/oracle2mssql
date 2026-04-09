CREATE OR ALTER PROCEDURE [ehrphra12_pkg].[hraD030]
(    @p_item_type NVARCHAR(MAX),
    @p_emp_no NVARCHAR(MAX),
    @p_start_date NVARCHAR(MAX),
    @p_start_time NVARCHAR(MAX),
    @p_end_date NVARCHAR(MAX),
    @p_end_time NVARCHAR(MAX),
    @P_otm_hrs NVARCHAR(MAX),
    @OrganType_IN NVARCHAR(MAX),
    @RtnCode DECIMAL(38,10) OUTPUT
)
AS
DECLARE @sItemType NVARCHAR(MAX) /*hra_offrec.item_type%TYPE*/ = @p_item_type;
DECLARE @sEmpNo NVARCHAR(MAX) /*hra_offrec.emp_no%TYPE*/ = @p_emp_no;
DECLARE @sStart NVARCHAR(20) = @p_start_date + @p_start_time;
DECLARE @sEnd NVARCHAR(20) = @p_end_date + @p_end_time;
DECLARE @sStart1 NVARCHAR(20);
DECLARE @sEnd1 NVARCHAR(20);
DECLARE @sOffrest DECIMAL(4,1);
DECLARE @iLeave NVARCHAR(10);
DECLARE @maxHrs DECIMAL(5,1);
DECLARE @Test1 DECIMAL(5,1);
DECLARE @Test2 DECIMAL(5,1);
DECLARE @Test3 DECIMAL(5,1);
DECLARE @maxHrs_Tmp DECIMAL(5,1);
DECLARE @iCnt INT;
DECLARE @iComedate NVARCHAR(10);
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
    FROM hra_Doffrec
           WHERE item_type = @sItemType
             AND emp_no    = @sEmpNo
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
    FROM hra_Doffrec
           WHERE item_type = @sItemType
             AND emp_no    = @sEmpNo
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


       IF @sItemType = 'A' BEGIN
      BEGIN TRY
    SELECT @sOffrest = SUM(otm_hrs)
    FROM hra_doffrec
	      WHERE (emp_no = @sEmpNo)
          AND status = 'Y'
          AND disabled ='N'
          AND item_type = 'A'
          AND FORMAT(START_DATE, 'yyyy')=FORMAT(GETDATE(), 'yyyy');
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() IN (1403, 100) BEGIN
        SET @sOffrest = 0;
    END
END CATCH


       BEGIN TRY
    SELECT @iComedate = FORMAT(COME_DATE, 'yyyy-MM-dd'), @iLeave = FORMAT(LEAVE_DATE, 'yyyy-MM-dd')
    FROM HRA_DYEARVAC
	      WHERE (emp_no = @sEmpNo)
          AND  VAC_YEAR = FORMAT(GETDATE(), 'yyyy');
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() IN (1403, 100) BEGIN
        SET @maxHrs = 0;
    END
END CATCH

       IF @iLeave IS NULL BEGIN

       IF CEILING(DATEDIFF(MONTH, CONVERT(DATETIME2, @iComedate), CONVERT(DATETIME2, @p_start_date))) >= 12 BEGIN

        SET @maxHrs = 128; --1

       END
       ELSE
       BEGIN

        SET @maxHrs_Tmp = 128 /12 * CEILING((DATEDIFF(MONTH, CONVERT(DATETIME2, @iComedate), CONVERT(DATETIME2, FORMAT(GETDATE(), 'yyyy')+'-12-31'))));

          --未滿半日以半日算,滿半日以一日算
         IF @maxHrs_Tmp = FLOOR(@maxHrs_Tmp) BEGIN
           SET @maxHrs = @maxHrs_Tmp;
           END
ELSE IF @maxHrs_Tmp = FLOOR(@maxHrs_Tmp)+0.5 BEGIN
           SET @maxHrs = FLOOR(@maxHrs_Tmp)+0.5;
           END
ELSE IF @maxHrs_Tmp > FLOOR(@maxHrs_Tmp)+0.5 BEGIN
           SET @maxHrs = FLOOR(@maxHrs_Tmp) +1;
         END
         ELSE
         BEGIN
           SET @maxHrs = FLOOR(@maxHrs_Tmp) +0.5; --2
         END

       END

       END
       ELSE
       BEGIN

       IF CEILING(DATEDIFF(MONTH, CONVERT(DATETIME2, @iComedate), CONVERT(DATETIME2, @p_start_date))) >= 12 BEGIN

        SET @maxHrs_Tmp = 128 /12 * CAST(SUBSTRING(@iLeave, 6, 2) AS DECIMAL(38,10));

       END
       ELSE
       BEGIN

        SET @maxHrs_Tmp = 128 /12 * CEILING((DATEDIFF(MONTH, CONVERT(DATETIME2, @iComedate), CONVERT(DATETIME2, @iLeave))));

       END

          --未滿半日以半日算,滿半日以一日算
         IF @maxHrs_Tmp = FLOOR(@maxHrs_Tmp) BEGIN
         SET @maxHrs = @maxHrs_Tmp;
         END
ELSE IF @maxHrs_Tmp = FLOOR(@maxHrs_Tmp)+0.5 BEGIN
         SET @maxHrs = FLOOR(@maxHrs_Tmp)+0.5;
         END
ELSE IF @maxHrs_Tmp > FLOOR(@maxHrs_Tmp)+0.5 BEGIN
         SET @maxHrs = FLOOR(@maxHrs_Tmp) +1;
         END
         ELSE
         BEGIN
         SET @maxHrs = FLOOR(@maxHrs_Tmp) +0.5;
         END

       END


       IF  @P_otm_hrs + @sOffrest > @maxHrs BEGIN
       SET @RtnCode = 2;
       GOTO Continue_ForEach1 ;
       END

       END
       Continue_ForEach1:
END
GO
