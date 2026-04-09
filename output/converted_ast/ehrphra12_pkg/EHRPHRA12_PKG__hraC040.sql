CREATE OR ALTER PROCEDURE [ehrphra12_pkg].[hraC040]
(    @p_emp_no NVARCHAR(MAX),
    @p_uncard_date NVARCHAR(MAX),
    @p_uncard_time NVARCHAR(MAX),
    @p_uncard_poin NVARCHAR(MAX),
    @p_uncard_rea NVARCHAR(MAX),
    @OrganType_IN NVARCHAR(MAX),
    @RtnCode DECIMAL(38,10) OUTPUT
)
AS
DECLARE @sEmpNo NVARCHAR(10) = @p_emp_no;
DECLARE @sUnCardDate NVARCHAR(20) = @p_uncard_date;
DECLARE @sUnCardTime NVARCHAR(20) = @p_uncard_time;
DECLARE @sUnCardPoin NVARCHAR(10) = @p_uncard_poin;
DECLARE @sUnCardRea NVARCHAR(10) = @p_uncard_rea;
DECLARE @SOrganType NVARCHAR(10) = @OrganType_IN;
DECLARE @iClasTime_IN NVARCHAR(4);
DECLARE @iClasTime_OUT NVARCHAR(4);
DECLARE @sclassCode NVARCHAR(4);
DECLARE @sSHIFT_NO NVARCHAR(2);
DECLARE @LimitDay NVARCHAR(2);
DECLARE @iCnt INT;
DECLARE @iconti BIT;
DECLARE @iCheck INT;
DECLARE @nNum DECIMAL(38,10);
BEGIN
    SET @RtnCode = 0;
    SET @iCnt = 0;
    SET @iconti = 1;
    SET @iCheck = 0;
    IF CONVERT(DATETIME2, @sUnCardDate) > GETDATE() BEGIN
      SET @RtnCode = 2;
      SET @iconti = 0;
    END
    /*IF @sUnCardDate+@sUnCardPoin > FORMAT(GETDATE(), 'yyyy-mm-ddhh:mm') BEGIN
      SET @RtnCode = 2;
      SET @iconti = 0;
    END*/
    
    IF @sUnCardPoin = '2400' BEGIN
      SET @RtnCode = 9;
      SET @iconti = 0;
    END
    
    IF @iconti <> 0 BEGIN
      --20210113 by108482 申請不卡14天申請期限,超過五天才申請違規記點
      --20210204 by108482 每月申請最多至隔月5號(5號當天可以申請)
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
         SET @iconti = 0;
      END*/
      IF CAST(GETDATE() AS DATE) > 
         CONVERT(DATETIME2, FORMAT(DATEADD(MONTH, 1, CONVERT(DATETIME2, @sUnCardDate)), 'yyyy-MM')+'-'+@LimitDay) BEGIN
        SET @RtnCode = 3;
        SET @iconti = 0;
      END
    END
    
    IF @iconti <> 0 BEGIN
      SELECT @iCheck = COUNT(*)
    FROM HRA_UNCARD
       WHERE Emp_No = @p_emp_no
         AND Class_Date = CONVERT(DATETIME2, @p_uncard_date)
         AND Uncard_Time = @p_uncard_time;
      IF @iCheck <> 0 BEGIN
        SET @RtnCode = 4;
        SET @iconti = 0;
      END
    END

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
          IF @sUnCardPoin IS NULL BEGIN
            SET @sUnCardPoin = @iClasTime_IN;
          END
          ELSE
          BEGIN
            IF @sUnCardPoin = @iClasTime_OUT BEGIN
              SET @RtnCode = 7;
              SET @iconti = 0;
            END
          END 
          IF CONVERT(DATETIME2, @sUnCardDate+@iClasTime_IN) > GETDATE() BEGIN
            SET @RtnCode = 2;
            SET @iconti = 0;
          END
ELSE IF @sclassCode <> 'RN' AND CONVERT(DATETIME2, @sUnCardDate+@sUnCardPoin) > GETDATE() BEGIN
            SET @RtnCode = 2;
            SET @iconti = 0;
          END
ELSE IF @sclassCode = 'RN' AND @sUnCardPoin <> @iClasTime_IN AND DATEADD(DAY, -1, CONVERT(DATETIME2, @sUnCardDate+@sUnCardPoin)) > GETDATE() BEGIN
            SET @RtnCode = 2;
            SET @iconti = 0;
          END
          ELSE
          BEGIN
            --確認上班打卡時間是否早於應出勤時間超過0.5小時
            SET @nNum = DATEDIFF(MINUTE, CONVERT(DATETIME2, @sUnCardDate+@sUnCardPoin), CONVERT(DATETIME2, @sUnCardDate+@iClasTime_IN));
            IF @nNum > 0 BEGIN
              SET @nNum = FLOOR(@nNum/30) * 0.5;
              IF @nNum >= 0.5 AND @sUnCardRea IS NULL BEGIN
                SET @RtnCode = 5;
                SET @iconti = 0;
              END
              --提前超過5小時打卡無法存檔成功
              IF @nNum >= 5 BEGIN
                SET @RtnCode = 6;
                SET @iconti = 0;
              END
            END
          END
        END
ELSE IF @sSHIFT_NO = 2 BEGIN
          IF @sUnCardPoin IS NULL BEGIN
            SET @sUnCardPoin = @iClasTime_OUT;
          END
          ELSE
          BEGIN
            IF @sUnCardPoin = @iClasTime_IN BEGIN
              SET @RtnCode = 8;
              SET @iconti = 0;
            END
          END
          IF CONVERT(DATETIME2, @sUnCardDate+@iClasTime_OUT) > GETDATE() BEGIN
            SET @RtnCode = 2;
            SET @iconti = 0;
          END
ELSE IF CONVERT(DATETIME2, @sUnCardDate+@sUnCardPoin) > GETDATE() BEGIN
            SET @RtnCode = 2;
            SET @iconti = 0;
          END
          ELSE
          BEGIN
            --確認JB班是否提早下班,提早下班不用判斷時差
            IF @iClasTime_OUT = '0000' AND SUBSTRING(@sUnCardPoin,1,1) <> '0' BEGIN
              SET @nNum = 0;
            END
            ELSE
            BEGIN
              --確認下班打卡時間是否晚於應出勤時間超過0.5小時
              IF SUBSTRING(@iClasTime_OUT,1,1) = '0' AND SUBSTRING(@sUnCardPoin,1,1) = '2' BEGIN
                SET @nNum = DATEDIFF(MINUTE, DATEADD(DAY, 1, CONVERT(DATETIME2, @sUnCardDate+@iClasTime_OUT)), CONVERT(DATETIME2, @sUnCardDate+@sUnCardPoin));
              END
ELSE IF SUBSTRING(@iClasTime_OUT,1,1) = '0' AND SUBSTRING(@sUnCardPoin,1,1) <> '2' BEGIN
                SET @nNum = DATEDIFF(MINUTE, DATEADD(DAY, 1, CONVERT(DATETIME2, @sUnCardDate+@iClasTime_OUT)), DATEADD(DAY, 1, CONVERT(DATETIME2, @sUnCardDate+@sUnCardPoin)));
              END
              ELSE
              BEGIN
                SET @nNum = DATEDIFF(MINUTE, CONVERT(DATETIME2, @sUnCardDate+@iClasTime_OUT), CONVERT(DATETIME2, @sUnCardDate+@sUnCardPoin));
              END
            END
            IF @nNum > 0 BEGIN
              SET @nNum = FLOOR(@nNum/30) * 0.5;
              IF @nNum >= 0.5 AND @sUnCardRea IS NULL BEGIN
                SET @RtnCode = 5;
                SET @iconti = 0;
              END
              --延後超過5小時打卡無法存檔成功
              IF @nNum >= 5 BEGIN
                SET @RtnCode = 6;
                SET @iconti = 0;
              END
            END
          END
        END
        
      END
    END
END
GO
