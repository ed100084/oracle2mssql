CREATE OR ALTER PROCEDURE [ehrphra12_pkg].[hraC060]
(    @EmpNo_In NVARCHAR(MAX),
    @StartDate_In NVARCHAR(MAX),
    @Merge_In NVARCHAR(MAX),
    @User_In NVARCHAR(MAX),
    @RtnCode DECIMAL(38,10) OUTPUT
)
AS
DECLARE @iCnt DECIMAL(38,10);
BEGIN
BEGIN TRY
    SELECT @iCnt = COUNT(*)
    FROM HRA_OFFREC
     WHERE EMP_NO = @EmpNo_In
       AND FORMAT(START_DATE_TMP, 'yyyy-mm-dd') = @StartDate_In;
    
    IF @iCnt - @Merge_In <> 0 BEGIN
      UPDATE HRA_OFFREC
         SET [MERGE] = [MERGE] - 1,
             LAST_UPDATE_DATE = GETDATE(),
             LAST_UPDATED_BY = @User_In
       WHERE EMP_NO = @EmpNo_In
         AND FORMAT(START_DATE_TMP, 'yyyy-mm-dd') = @StartDate_In 
         AND [MERGE] > @Merge_In;
    END
    COMMIT TRAN;
    SET @RtnCode = @iCnt;
END TRY
BEGIN CATCH
    -- WHEN OTHERS
    ROLLBACK TRAN;
    SET @RtnCode = ERROR_NUMBER();
END CATCH
END
GO
