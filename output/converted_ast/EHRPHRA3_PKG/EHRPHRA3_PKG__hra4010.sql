CREATE OR ALTER PROCEDURE [ehrphra3_pkg].[hra4010]
(    @TrnYm_IN NVARCHAR(MAX),
    @TrnShift_IN NVARCHAR(MAX),
    @UpdateBy_IN NVARCHAR(MAX),
    @Orgtype_IN NVARCHAR(MAX),
    @RtnCode DECIMAL(38,10) OUTPUT
)
AS
DECLARE @sTrnYm NVARCHAR(7) = @TRNYM_IN;
DECLARE @sTrnShift NVARCHAR(2) = @TRNSHIFT_IN;
DECLARE @sOrganType NVARCHAR(10) = @ORGTYPE_IN;
DECLARE @sUpdateBy NVARCHAR(20) = @UPDATEBY_IN;
DECLARE @sStartDay NVARCHAR(2);
DECLARE @sEndDay NVARCHAR(2);
DECLARE @dStrartDate DATETIME2(0);
DECLARE @dEndDate DATETIME2(0);
DECLARE @sEmpNo NVARCHAR(20);
DECLARE @sDeptNo NVARCHAR(10);
DECLARE @iCnt INT;
DECLARE @nSalary DECIMAL(38,10);
DECLARE @sDay NVARCHAR(2);
DECLARE @i INT;
DECLARE cursor1 CURSOR FOR
    SELECT EMP_NO FROM HRA_CLASSSCH
     WHERE SCH_YM = @sTrnYm
	     AND ORG_BY= @sOrganType;
DECLARE cursor2 CURSOR FOR
    SELECT DISTINCT HRA_ATTDTL.emp_no, HRE_EMPBAS.dept_no
      FROM HRA_ATTDTL, HRE_EMPBAS
     WHERE (HRA_ATTDTL.emp_no = HRE_EMPBAS.emp_no)
       AND ((HRA_ATTDTL.trn_ym = @sTrnYm)
       AND (HRA_ATTDTL.trn_shift = @sTrnShift))
	     AND (HRA_ATTDTL.ORGAN_TYPE= @sOrganType)
	     AND (HRA_ATTDTL.ORGAN_TYPE=HRE_EMPBAS.ORGAN_TYPE);
BEGIN
BEGIN TRY
       SET @RtnCode = 0;
       
       --紀錄此時段是否開始執行
       INSERT INTO HRA_ATTDTL_AUDIT
       (TRN_YM, TASK, SHIFT_NO, CREATED_BY, CREATION_DATE, LAST_UPDATED_BY, LAST_UPDATE_DATE, ORG_BY, ORGAN_TYPE)
       VALUES
       (@sTrnYm, 'hra4010', @sTrnShift, @sUpdateBy, GETDATE(), @sUpdateBy, GETDATE(), @sOrganType, @sOrganType);
       COMMIT TRAN;

       --清檔
       DELETE FROM HRA_ATTDTL
        WHERE TRN_YM = @sTrnYm AND TRN_SHIFT = @sTrnShift
		      AND ORGAN_TYPE= @sOrganType;
       COMMIT TRAN;
       SAVE TRAN SP1;

       BEGIN TRY
    SELECT @sStartDay = START_DAY, @sEndDay = END_DAY
    FROM HRA_TRNSHIFT
           WHERE TRN_SHIFT = @sTrnShift;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() IN (1403, 100) BEGIN
        SET @sStartDay = NULL;
            SET @sEndDay = NULL;
    END
END CATCH


	  -- SPHINX 95.06.12 提前結算取最後日期要註記掉
     
       IF @sTrnShift = 'A3' BEGIN
         SET @sEndDay = FORMAT(EOMONTH(CONVERT(DATETIME2, @sTrnYm + '-01')), 'dd');
       END
      
  
      
       IF @sStartDay IS NULL OR @sEndDay IS NULL BEGIN
          SET @RtnCode = 2;
          GOTO Continue_ForEach1;
       END

       -- 結轉日期
       SET @dStrartDate = CONVERT(DATETIME2, @sTrnYm + '-' + @sStartDay);
       SET @dEndDate = CONVERT(DATETIME2, @sTrnYm + '-' + @sEndDay);

       OPEN cursor1;
       WHILE 1=1 BEGIN
          FETCH NEXT FROM cursor1 INTO @sEmpNo;
          IF @@FETCH_STATUS <> 0 BREAK;

          --未打卡次數統計
          IF [ehrphra3_pkg].[f_hra4010_B](@sTrnYm, @sTrnShift, @sEmpNo
                       , @dStrartDate, @dEndDate,@sOrganType, @sUpdateBy) <> 0 BEGIN
             SET @RtnCode = 0;
             GOTO Continue_ForEach1;
          END

          -- 曠職次數統計
          /*IF f_hra4010_C(@sTrnYm, @sTrnShift, @sEmpNo
                       , @dStrartDate, @dEndDate, @sOrganType , @sUpdateBy) <> 0 BEGIN*/
          -- 2026.01 曠職次數統計
          IF [ehrphra3_pkg].[f_hra4010_C_MIN](@sTrnYm, @sTrnShift, @sEmpNo
                           , @dStrartDate, @dEndDate, @sOrganType , @sUpdateBy) <> 0 BEGIN
             SET @RtnCode = 4;
             GOTO Continue_ForEach1;
          END


          -- 遲到分數統計(for 義大 以次數計)
          IF [ehrphra3_pkg].[f_hra4010_D](@sTrnYm, @sTrnShift, @sEmpNo
                       , @dStrartDate, @dEndDate, @sOrganType ,@sUpdateBy) <> 0 BEGIN
             SET @RtnCode = 0;
             GOTO Continue_ForEach1;
          END

          -- 早退分數統計(for 義大 以次數計)
          IF [ehrphra3_pkg].[f_hra4010_E](@sTrnYm, @sTrnShift, @sEmpNo
                       , @dStrartDate, @dEndDate, @sOrganType ,@sUpdateBy) <> 0 BEGIN
             SET @RtnCode = 6;
             GOTO Continue_ForEach1;
          END

          IF @sTrnShift IN ('A3') BEGIN
             --請假統計結轉
             IF [ehrphra3_pkg].[f_hra4010_A](@sTrnYm, @sTrnShift, @sEmpNo, @sOrganType ,@sUpdateBy) <> 0 BEGIN
                 SET @RtnCode = 0;
                GOTO Continue_ForEach1;
             END

             --超時積假時數統計
             IF [ehrphra3_pkg].[f_hra4010_F](@sTrnYm, @sTrnShift, @sEmpNo, @sOrganType , @sUpdateBy) <> 0 BEGIN
                SET @RtnCode = 0;
                GOTO Continue_ForEach1;
             END

             --批OFF時數統計(積借休時數統計)
			 -- ONCALL交通費待人事公告後再由細統計算 94.12.26 SPHINX
             IF [ehrphra3_pkg].[f_hra4010_H](@sTrnYm, @sTrnShift, @sEmpNo, @sOrganType ,@sUpdateBy) <> 0 BEGIN
                SET @RtnCode = 10;
                GOTO Continue_ForEach1;
             END

             -- 加班時數統計
             IF [ehrphra3_pkg].[f_hra4010_J](@sTrnYm, @sTrnShift, @sEmpNo, @sOrganType ,@sUpdateBy) <> 0 BEGIN
                SET @RtnCode = 12;
                GOTO Continue_ForEach1;
             END
          END
       END
       CLOSE cursor1;
    DEALLOCATE cursor1


       COMMIT TRAN;
       SET @RtnCode = 0;
       Continue_ForEach1:
END TRY
BEGIN CATCH
    -- WHEN OTHERS
    ROLLBACK TRAN;
         SET @RtnCode = ERROR_NUMBER();
END CATCH
END
GO
