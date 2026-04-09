CREATE OR ALTER PROCEDURE [ehrphra12_pkg].[hraC040_old]
(    @p_emp_no NVARCHAR(MAX),
    @p_uncard_date NVARCHAR(MAX),
    @p_uncard_time NVARCHAR(MAX),
    @OrganType_IN NVARCHAR(MAX),
    @RtnCode DECIMAL(38,10) OUTPUT
)
AS
DECLARE @sEmpNo NVARCHAR(10) = @p_emp_no;
DECLARE @sUnCardDate NVARCHAR(20) = @p_uncard_date;
DECLARE @sUnCardTime NVARCHAR(20) = @p_uncard_time;
DECLARE @SOrganType NVARCHAR(10) = @OrganType_IN;
DECLARE @iClasTime_IN NVARCHAR(4);
DECLARE @iClasTime_OUT NVARCHAR(4);
DECLARE @sclassCode NVARCHAR(4);
DECLARE @sSHIFT_NO NVARCHAR(2);
DECLARE @iCnt INT;
DECLARE @iconti BIT;
DECLARE @iCheck INT;
BEGIN
    SET @RtnCode = 0;
    SET @iCnt = 0;
    SET @iconti = 1;
    SET @iCheck = 0;
    IF CONVERT(DATETIME2, @sUnCardDate) > GETDATE() BEGIN
      SET @RtnCode = 2;
      SET @iconti = 0;
    END

    --2014-02-13 忘打卡鎖七日 by weichun 3/3 open
    --2014-04-29 要求關閉七日限制
  /*  IF @iconti <> 0 BEGIN
      IF CAST(GETDATE() AS DATE) >= DATEADD(DAY, 7, CONVERT(DATETIME2, @sUnCardDate)) BEGIN
         SET @RtnCode = 3;
         SET @iconti = 0;
      END
    END  */
    
    --2016-11-24 忘打卡鎖14日 by ed102674
     IF @iconti <> 0 BEGIN
      /*IF CAST(GETDATE() AS DATE) >= DATEADD(DAY, 14, CONVERT(DATETIME2, @sUnCardDate)) BEGIN
         SET @RtnCode = 3;
         SET @iconti = 0;
      END*/
      --20210113 by108482 申請不卡14天申請期限,超過五天才申請違規記點
      --20210204 by108482 每月申請最多至隔月5號(5號當天可以申請)
      IF CAST(GETDATE() AS DATE) > DATEADD(DAY, 4, CAST(DATEADD(MONTH, 1, CONVERT(DATETIME2, @sUnCardDate)) AS DATE)) BEGIN
      --IF GETDATE() > CAST(DATEADD(MONTH, 1, CONVERT(DATETIME2, @sUnCardDate)) AS DATE) + 2 + 13.5 / 24 THEN --20211202 因考核結算,11月份申請期限至12/3 13:30止
      --IF CAST(GETDATE() AS DATE) > CAST(DATEADD(MONTH, 1, CONVERT(DATETIME2, @sUnCardDate)) AS DATE) +7 THEN --20220406 因4月份國定連假,延長3月份出勤申請期限至8號
         SET @RtnCode = 3;
         SET @iconti = 0;
      END
    END
    
    /*IF @iconti <> 0 BEGIN
      SELECT @iCheck = COUNT(*)
    FROM hra_uncard
       WHERE FORMAT(hra_uncard.class_date, 'yyyy-mm-dd') = @sUnCardDate
         AND hra_uncard.uncard_time = @sUnCardTime;
      IF @iCheck <> 0 BEGIN
        SET @RtnCode = 4;
        SET @iconti = 0;
      END
    END*/

    IF @iconti <> 0 BEGIN

    SET @sclassCode = [ehrphrafunc_pkg].[f_getClassKind] (@sEmpNo , CONVERT(DATETIME2, @sUnCardDate),@SOrganType);

    IF @sUnCardTime = 'A1' OR @sUnCardTime = 'A2' BEGIN
    SET @sSHIFT_NO = 1;
    END
ELSE IF @sUnCardTime = 'B1' OR @sUnCardTime = 'B2' BEGIN
    SET @sSHIFT_NO = 2;
    END
ELSE IF @sUnCardTime = 'C1' OR @sUnCardTime = 'C2' BEGIN
    SET @sSHIFT_NO = 3;
    END

    BEGIN TRY
    SELECT @iClasTime_IN = CHKIN_WKTM, @iClasTime_OUT = CHKOUT_WKTM
    FROM HRP.HRA_CLASSDTL
     WHERE CLASS_CODE = @sclassCode
       AND SHIFT_NO = @sSHIFT_NO ;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() IN (1403, 100) BEGIN
        SET @iCnt = 1;
    END
END CATCH

     IF @iCnt = 0 BEGIN
     SET @sSHIFT_NO = SUBSTRING(@sUnCardTime,2,1);

     IF @sSHIFT_NO = 1 BEGIN

        IF CONVERT(DATETIME2, @sUnCardDate+@iClasTime_IN) > GETDATE() BEGIN
        SET @RtnCode = 2;
        --SET @iconti = 0;
        END

     END
ELSE IF @sSHIFT_NO = 2 BEGIN

        IF CONVERT(DATETIME2, @sUnCardDate+@iClasTime_OUT) > GETDATE() BEGIN
        SET @RtnCode = 2;
        --SET @iconti = 0;
        END

     END


    END

    END
END
GO
