CREATE OR ALTER FUNCTION [ehrphra3_pkg].[f_hra4010_A]
(    @TrnYm_IN NVARCHAR(MAX),
    @TrnShift_IN NVARCHAR(MAX),
    @EmpNo_IN NVARCHAR(MAX),
    @Orgtype_IN NVARCHAR(MAX),
    @UpdateBy_IN NVARCHAR(MAX)
)
RETURNS DECIMAL(38,10)
AS
BEGIN
DECLARE @sTrnYm NVARCHAR(7) = @TRNYM_IN;
DECLARE @sTrnShift NVARCHAR(2) = @TRNSHIFT_IN;
DECLARE @sEmpNo NVARCHAR(20) = @EMPNO_IN;
DECLARE @sOrganType NVARCHAR(10) = @ORGTYPE_IN;
DECLARE @sUpdateBy NVARCHAR(20) = @UPDATEBY_IN;
DECLARE @sVacType NVARCHAR(10);
DECLARE @sAttCode NVARCHAR(10);
DECLARE @nVacDays DECIMAL(38,10);
DECLARE @nVacHrs DECIMAL(38,10);
DECLARE @nHoliHrs DECIMAL(38,10);
DECLARE @nEvcTotalHrs DECIMAL(38,10);
DECLARE @nOffVacDays DECIMAL(38,10);
DECLARE @nOffVacHrs DECIMAL(38,10);
DECLARE @nOffTotalHrs DECIMAL(38,10);
DECLARE @nTotalHrs DECIMAL(38,10);
DECLARE @iCnt INT = 0;
DECLARE @sSalCode VARCHAR(10);
DECLARE @iValue INT = 0;
DECLARE cursor1 CURSOR FOR
    SELECT VAC_TYPE FROM HRA_VCRLMST;
-- EXCEPTION block removed: TRY/CATCH not allowed in T-SQL scalar function

       OPEN cursor1;
       WHILE 1=1 BEGIN
          FETCH NEXT FROM cursor1 INTO @sVacType;
          IF @@FETCH_STATUS <> 0 BREAK;
          -- 電子請假時數
          -- EXCEPTION block removed: TRY/CATCH not allowed in T-SQL scalar function

    SELECT @nVacDays = SUM(VAC_DAYS), @nVacHrs = SUM(VAC_HRS), @nHoliHrs = SUM(HOLI_HRS)
    FROM HRA_EVCREC
              WHERE EMP_NO = @sEmpNo
			  AND VAC_TYPE = @sVacType
			  AND FORMAT(START_DATE, 'yyyy-MM') = @sTrnYm
			  AND STATUS = 'Y'
        --AND FORMAT(start_date, 'yyyy-mm-dd') BETWEEN '2025-03-01' AND '2025-03-30'  -- 提前結算
			  AND ORG_BY = @sOrganType;


          IF @nVacDays IS NULL BEGIN
             SET @nVacDays = 0;
          END

          IF @nVacHrs IS NULL BEGIN
             SET @nVacHrs = 0;
          END

          SET @nEvcTotalHrs = @nVacDays * 8 + @nVacHrs;

		  --100.07.27 產假,流產假 扣除假日時數
      --2020.02 與人資確認 ,須扣薪的產假不用排除非出勤日
		  IF (@sVacType='J') AND (@nEvcTotalHrs>0) BEGIN
             SET @nEvcTotalHrs = @nVacDays * 8 + @nVacHrs - @nHoliHrs;
		  END

           SET @nTotalHrs = @nEvcTotalHrs;

          IF @nTotalHrs = 0 BEGIN
             GOTO Continue_ForEach1;
          END

          -- EXCEPTION block removed: TRY/CATCH not allowed in T-SQL scalar function

    SELECT @sAttCode = ATT_CODE
    FROM HRA_ATTRUL
              WHERE ORG_CODE = @sVacType AND ATT_KIND = '2';    -- att_kind = 2  請假


          IF @sAttCode IS NULL BEGIN
             GOTO Continue_ForEach1;
          END

          IF [ehrphra3_pkg].[f_hra4010_ins](@sTrnYm
                                      , @sTrnShift
                                      , @sEmpNo
                                      , @sAttCode
                                      , @nTotalHrs
                                      , 'H'
									  , @sOrganType
									  , @sUpdateBy ) <> 0 BEGIN
             SET @iCnt = 1;   --  請假時數INSERT失敗
          END
          Continue_ForEach1:
       END
       CLOSE cursor1;
    DEALLOCATE cursor1
       ----------------------- 404全勤 405不休假 -----------------------
	   -- 94.11.07 SPHINX  薪資結構有此津貼才寫入
     SET @iValue = 0;

	   IF @iValue>0 BEGIN

	     IF [ehrphra3_pkg].[f_hra4010_ins](@sTrnYm
                                   , @sTrnShift
                                   , @sEmpNo
                                   , '4040'
                                   , 1
                                   , 'T'
								   , @sOrganType
                                   , @sUpdateBy ) <> 0 BEGIN
           SET @iCnt = 1;   --  請假時數INSERT失敗
           GOTO Continue_ForEach2 ;
         END


         IF [ehrphra3_pkg].[f_hra4010_ins](@sTrnYm
                                   , @sTrnShift
                                   , @sEmpNo
                                   , '4050'
                                   , 1
                                   , 'T'
								   , @sOrganType
                                   , @sUpdateBy ) <> 0 BEGIN
           SET @iCnt = 1;   --  請假時數INSERT失敗
         END
        END-- END @iValue =0
       Continue_ForEach2:
    ----------------------- 404全勤 405不休假 -----------------------

       RETURN @iCnt;

END
GO
