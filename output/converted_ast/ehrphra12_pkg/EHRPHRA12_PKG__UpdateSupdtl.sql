CREATE OR ALTER PROCEDURE [ehrphra12_pkg].[UpdateSupdtl]
(    @SUPNO_IN NVARCHAR(MAX),
    @EMPNO_IN NVARCHAR(MAX)
)
AS
DECLARE @ccunt DECIMAL(38,10);
BEGIN
BEGIN TRY
    SET @ccunt = 0;
  
    BEGIN TRY
    SELECT @ccunt = COUNT(*)
    FROM hra_supdtl
       WHERE status = 'Y'
         AND sup_no = @SUPNO_IN;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() IN (1403, 100) BEGIN
        SET @ccunt = 0;
    END
END CATCH
    
    IF @ccunt <> 0 BEGIN
      UPDATE hra_supdtl
         SET status = 'N',
             last_updated_by = @EMPNO_IN,
             last_update_date = GETDATE()
       WHERE sup_no = @SUPNO_IN;
    END
    COMMIT TRAN;
END TRY
BEGIN CATCH
    -- WHEN OTHERS
    ROLLBACK TRAN;
    DECLARE @__exec_arg NVARCHAR(MAX);
    SET @__exec_arg = '執行[ehrphra12_pkg].[PROCEDURE] UpdateSupdtl，但SQLCODE='+CAST(ERROR_NUMBER() AS NVARCHAR);
    EXEC [ehrphrafunc_pkg].[Post_Html_Mail] 'system@edah.org.tw','ed108482@edah.org.tw','','1','補休不准調整明細作業(異常)',
                                   @__exec_arg;
END CATCH
END
GO
