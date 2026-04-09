CREATE OR ALTER PROCEDURE [ehrphra12_pkg].[hraC061]
(    @EmpNo_In NVARCHAR(MAX),
    @StartDate_In NVARCHAR(MAX),
    @User_In NVARCHAR(MAX),
    @RtnCode DECIMAL(38,10) OUTPUT
)
AS
DECLARE @iCnt DECIMAL(38,10);
DECLARE @iMerge NVARCHAR(1);
DECLARE @iClassCode NVARCHAR(4);
DECLARE @iSotmHrs DECIMAL(38,10);
DECLARE @iSumHrs DECIMAL(38,10);
DECLARE @iWorkHrs DECIMAL(38,10);
DECLARE @iTotalHrs DECIMAL(7,3);
DECLARE @sSONEO DECIMAL(38,10);
DECLARE @sSONEOTT DECIMAL(38,10);
DECLARE @sSONEOSS DECIMAL(38,10);
DECLARE @sSONEUU DECIMAL(38,10);
BEGIN
BEGIN TRY
    SET @RtnCode = 0;
    
    SELECT @iCnt = COUNT(*)
    FROM HRA_OFFREC
     WHERE EMP_NO = @EmpNo_In
       AND FORMAT(START_DATE_TMP, 'yyyy-mm-dd') = @StartDate_In;
    
  IF @iCnt > 0 BEGIN
    SELECT @iMerge = MAX([MERGE])
    FROM HRA_OFFREC
     WHERE EMP_NO = @EmpNo_In
       AND FORMAT(START_DATE_TMP, 'yyyy-mm-dd') = @StartDate_In;

    SET @iSumHrs = 0;
    DECLARE @I INT = (0);
WHILE @I <= CAST(@iMerge AS DECIMAL(38,10)) BEGIN
      SET @sSONEO = 0;
      SET @sSONEOTT = 0;
      SET @sSONEOSS = 0;
      SET @sSONEUU = 0;
      SELECT @iClassCode = CLASS_CODE, @iSotmHrs = SOTM_HRS
    FROM HRA_OFFREC
       WHERE EMP_NO = @EmpNo_In
         AND FORMAT(START_DATE_TMP, 'yyyy-mm-dd') = @StartDate_In
         AND [MERGE] = CAST(I AS NVARCHAR);
         
      IF @iClassCode = 'ZZ' BEGIN
        IF @iSumHrs+@iSotmHrs <= 2 BEGIN 
          SET @sSONEOTT = @iSotmHrs;
        END
ELSE IF @iSumHrs+@iSotmHrs > 2 AND @iSumHrs+@iSotmHrs <= 8 BEGIN
          IF @iSumHrs < 2 BEGIN --前面加班時數尚未滿2小時，則4/3時數還有配額
            SET @sSONEOTT = 2 - @iSumHrs;
            SET @sSONEOSS = @iSotmHrs - (2 - @iSumHrs);
          END
          ELSE
          BEGIN --前面加班時數滿2小時，則4/3時數無配額
            SET @sSONEOSS = @iSotmHrs;
          END
        END
ELSE IF @iSumHrs+@iSotmHrs > 8 AND @iSumHrs+@iSotmHrs <= 12 BEGIN
          IF @iSumHrs < 2 BEGIN --前面加班時數尚未滿2小時，則4/3時數還有配額
            SET @sSONEOTT = 2 - @iSumHrs;
            SET @sSONEOSS = 6;
            SET @sSONEUU = @iSotmHrs - 6 - (2 - @iSumHrs);
          END
          ELSE
          BEGIN --前面加班時數滿2小時，則4/3時數無配額
            IF @iSumHrs - 2 < 6 BEGIN --5/3時數還有配額
              SET @sSONEOSS = 6 - (@iSumHrs - 2);
              SET @sSONEUU = @iSotmHrs - (6 - (@iSumHrs - 2));
            END
            ELSE
            BEGIN --5/3時數無配額
              SET @sSONEUU = @iSotmHrs;
            END
          END
        END
      END
ELSE IF @iClassCode = 'ZY' BEGIN
        IF SUBSTRING(@EmpNo_In,1,1) IN ('S','P') BEGIN
          IF @iSumHrs = 0 BEGIN
            IF @iSotmHrs <= 8 BEGIN
              SET @sSONEO = @iSotmHrs;
            END
            ELSE
            BEGIN
              SET @sSONEO = 8;
              IF @iSotmHrs - 8 <= 2 BEGIN
                SET @sSONEOTT = @iSotmHrs - 8;
              END
              ELSE
              BEGIN
                SET @sSONEOTT = 2;
                SET @sSONEOSS = @iSotmHrs - 10;
              END
            END
          END
          ELSE
          BEGIN
            IF @iSotmHrs+@iSumHrs <= 8 BEGIN
              SET @sSONEO = @iSotmHrs;
            END
            ELSE
            BEGIN
              IF @iSumHrs > 8 BEGIN
                IF @iSumHrs - 8 < 2 BEGIN --1:4/3還有配額
                  SET @sSONEOTT = 2 - (@iSumHrs - 8);
                  SET @sSONEOSS = @iSotmHrs - (2 - (@iSumHrs - 8));
                END
                ELSE
                BEGIN
                  SET @sSONEOSS = @iSotmHrs;
                END
              END
              ELSE
              BEGIN --之前申請時數還未超過(或等於)8小時 @iSumHrs <= 8，1:1可能還有配額
                SET @sSONEO = 8-@iSumHrs;
                IF @iSotmHrs - (8-@iSumHrs) <= 2 BEGIN
                  SET @sSONEOTT = @iSotmHrs - (8-@iSumHrs);
                END
                ELSE
                BEGIN
                  SET @sSONEOTT = 2;
                  SET @sSONEOSS = @iSotmHrs - (8-@iSumHrs) - 2;
                END
              END
            END
          END
        END
        ELSE
        BEGIN
          IF @iSumHrs = 0 BEGIN
            IF @iSotmHrs <= 8 BEGIN
              SET @sSONEO = 8;
            END
            ELSE
            BEGIN
              SET @sSONEO = 8;
              IF @iSotmHrs - 8 <= 2 BEGIN
                SET @sSONEOTT = @iSotmHrs - 8;
              END
              ELSE
              BEGIN
                SET @sSONEOTT = 2;
                SET @sSONEOSS = @iSotmHrs - 10;
              END
            END
          END
          ELSE
          BEGIN
            IF @iSotmHrs+@iSumHrs <= 8 BEGIN
              SET @sSONEO = 0;
            END
            ELSE
            BEGIN
              IF @iSumHrs <= 8 BEGIN
                IF @iSotmHrs - (8-@iSumHrs) <= 2 BEGIN
                  SET @sSONEOTT = @iSotmHrs - (8-@iSumHrs);
                END
                ELSE
                BEGIN
                  SET @sSONEOTT = 2;
                  SET @sSONEOSS = @iSotmHrs - (8-@iSumHrs) - 2;
                END
              END
              ELSE
              BEGIN
                IF @iSumHrs - 8 < 2 BEGIN
                  SET @sSONEOTT = 2 - (@iSumHrs - 8);
                  SET @sSONEOSS = @iSotmHrs - (2 - (@iSumHrs - 8));
                END
                ELSE
                BEGIN
                  SET @sSONEOSS = @iSotmHrs;
                END
              END
            END
          END
        END
      END
ELSE IF SUBSTRING(@EmpNo_In,1,1) IN ('S','P') BEGIN --時薪人員需確認出勤班的時數
        SELECT @iWorkHrs = WORK_HRS
    FROM HRA_CLASSMST
         WHERE CLASS_CODE = @iClassCode;
        IF @iWorkHrs > 8 BEGIN SET @iWorkHrs = 8; END
        IF @iSumHrs = 0 BEGIN
          IF @iWorkHrs + @iSotmHrs <= 8 BEGIN
            SET @sSONEO = @iSotmHrs;
          END
          ELSE
          BEGIN
            SET @sSONEO = 8-@iWorkHrs;
            IF @iSotmHrs - (8 - @iWorkHrs) <=2 BEGIN
              SET @sSONEOTT = @iSotmHrs - (8 - @iWorkHrs);
            END
            ELSE
            BEGIN
              SET @sSONEOTT = 2;
              SET @sSONEOSS = @iSotmHrs - (8 - @iWorkHrs) -2;
            END
          END
        END
        ELSE
        BEGIN
          IF @iSotmHrs+@iSumHrs+@iWorkHrs <= 8 BEGIN
            SET @sSONEO = @iSotmHrs;
          END
          ELSE
          BEGIN
            IF @iSotmHrs+@iWorkHrs < 8 BEGIN --代表1:1尚有配額
              SET @sSONEO = 8-(@iSumHrs+@iWorkHrs);
              IF @iSotmHrs - (8-(@iSumHrs+@iWorkHrs)) <=2 BEGIN
                SET @sSONEOTT = @iSotmHrs - (8-(@iSumHrs+@iWorkHrs));
              END
              ELSE
              BEGIN
                SET @sSONEOTT = 2;
                SET @sSONEOSS = @iSotmHrs - (8-(@iSumHrs+@iWorkHrs)) -2;
              END
            END
ELSE IF @iSumHrs+@iWorkHrs = 8 BEGIN
              IF @iSotmHrs <=2 BEGIN
                SET @sSONEOTT = @iSotmHrs;
              END
              ELSE
              BEGIN
                SET @sSONEOTT = 2;
                SET @sSONEOSS = @iSotmHrs-2;
              END
            END
            ELSE
            BEGIN
              IF @iSumHrs+@iWorkHrs-8 <2 BEGIN --代表1:4/3尚有配額
                IF @iSotmHrs <= 2-(@iSumHrs+@iWorkHrs-8) BEGIN
                  SET @sSONEOTT = @iSotmHrs;
                END
                ELSE
                BEGIN
                  SET @sSONEOTT = 2-(@iSumHrs+@iWorkHrs-8);
                  SET @sSONEOSS = @iSotmHrs - (2-(@iSumHrs+@iWorkHrs-8));
                END
              END
              ELSE
              BEGIN
                SET @sSONEOSS = @iSotmHrs;
              END
            END
          END
        END
      END
      ELSE
      BEGIN
        IF @iSumHrs+@iSotmHrs <= 2 BEGIN
          SET @sSONEOTT = @iSotmHrs;
        END
ELSE IF @iSumHrs+@iSotmHrs > 2 AND @iSumHrs+@iSotmHrs <= 12 BEGIN
          IF @iSumHrs < 2 BEGIN --前面加班時數尚未滿2小時，則4/3時數還有配額
            SET @sSONEOTT = 2 - @iSumHrs;
            SET @sSONEOSS = @iSotmHrs - (2 - @iSumHrs);
          END
          ELSE
          BEGIN --前面加班時數滿2小時，則4/3時數無配額
            SET @sSONEOSS = @iSotmHrs;
          END
        END
      END
      SET @iSumHrs = @iSumHrs+@iSotmHrs;
      SET @iTotalHrs = CEILING(((@sSONEO*1)+(@sSONEOTT*4/3)+(@sSONEOSS*5/3)+(@sSONEUU*8/3))*1000)/1000;
      UPDATE HRA_OFFREC
         SET OTM_HRS = @iTotalHrs,
             SONEO   = @sSONEO,
             SONEOTT = @sSONEOTT,
             SONEOSS = @sSONEOSS,
             SONEUU  = @sSONEUU,
             LAST_UPDATED_BY = @User_In,
             LAST_UPDATE_DATE = GETDATE()
       WHERE EMP_NO = @EmpNo_In
         AND FORMAT(START_DATE_TMP, 'yyyy-mm-dd') = @StartDate_In
         AND [MERGE] = CAST(I AS NVARCHAR);
    END
    COMMIT TRAN;
  END
    SET @RtnCode = @iCnt;
END TRY
BEGIN CATCH
    -- WHEN OTHERS
    ROLLBACK TRAN;
    SET @RtnCode = ERROR_NUMBER();
END CATCH
END
GO
