
USE MIS
GO
 IF NOT EXISTS(SELECT * FROM sys.schemas WHERE [name] = N'hrp')      
     EXEC (N'CREATE SCHEMA hrp')                                   
 GO                                                               

USE MIS
GO
IF  EXISTS (SELECT * FROM sys.objects so JOIN sys.schemas sc ON so.schema_id = sc.schema_id WHERE so.name = N'EHRPHRAFUNC_PKG$F_GETWORKHRS$2$IMPL'  AND sc.name=N'hrp'  AND type in (N'P',N'PC'))
 DROP PROCEDURE [hrp].[EHRPHRAFUNC_PKG$F_GETWORKHRS$2$IMPL]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE HRP.EHRPHRAFUNC_PKG$F_GETWORKHRS$2$IMPL  
   @SCHYM_IN varchar(max),
   @EMPNO_IN varchar(max),
   /*
   *   SSMA warning messages:
   *   O2SS0356: Conversion from NUMBER datatype can cause data loss.
   */

   @return_value_argument float(53)  OUTPUT
AS 
   BEGIN

      EXECUTE ssma_oracle.db_fn_check_init_package 'HRP', 'EHRPHRAFUNC_PKG'

      DECLARE
         @SSCHYM varchar(7) = @SCHYM_IN, 
         @SEMPNO varchar(20) = @EMPNO_IN, 
         @IDAYS int, 
         @DSTARTDATE datetime2(0), 
         @DENDDATE datetime2(0), 
         /*
         *   SSMA warning messages:
         *   O2SS0356: Conversion from NUMBER datatype can cause data loss.
         */

         @NHOLIHRS float(53), 
         /*
         *   SSMA warning messages:
         *   O2SS0356: Conversion from NUMBER datatype can cause data loss.
         */

         @NTOTALHRS float(53)

      SET @DSTARTDATE = ssma_oracle.to_date2(ISNULL(@SSCHYM, '') + '-01', 'YYYY-MM-DD')

      SET @DENDDATE = ssma_oracle.last_day(@DSTARTDATE)

      SET @IDAYS = CAST(CONVERT(varchar(2), @DENDDATE, 106) AS numeric(38, 10))

      SET @NTOTALHRS = @IDAYS * 8

      BEGIN

         BEGIN TRY
            SELECT @NHOLIHRS = sum(
               HRA_CLASSSCH_VIEW.ADD_HRS
                + 
               HRA_CLASSSCH_VIEW.SUP_HRS
                + 
               HRA_CLASSSCH_VIEW.VAC_HRS
                + 
               HRA_CLASSSCH_VIEW.OTM_HRS
                - 
               HRA_CLASSSCH_VIEW.OFF_HRS
                + 
               HRA_CLASSSCH_VIEW.CUTOTM_HRS
                + 
               HRA_CLASSSCH_VIEW.CUTSUP_HRS)
            FROM HRP.HRA_CLASSSCH_VIEW
            WHERE HRA_CLASSSCH_VIEW.SCH_YM = @SSCHYM AND HRA_CLASSSCH_VIEW.EMP_NO = @SEMPNO
         END TRY

         BEGIN CATCH

            DECLARE
               @errornumber int

            SET @errornumber = ERROR_NUMBER()

            DECLARE
               @errormessage nvarchar(4000)

            SET @errormessage = ERROR_MESSAGE()

            DECLARE
               @exceptionidentifier nvarchar(4000)

            SELECT @exceptionidentifier = ssma_oracle.db_error_get_oracle_exception_id(@errormessage, @errornumber)

            IF (@exceptionidentifier LIKE N'ORA-00100%')
               SET @NHOLIHRS = 0
            ELSE 
               BEGIN
                  IF (@exceptionidentifier IS NOT NULL)
                     BEGIN
                        IF @errornumber = 59998
                           RAISERROR(59998, 16, 1, @exceptionidentifier)
                        ELSE 
                           RAISERROR(59999, 16, 1, @exceptionidentifier)
                     END
                  ELSE 
                     BEGIN
                        EXECUTE ssma_oracle.ssma_rethrowerror
                     END
               END

         END CATCH

      END

      IF @NHOLIHRS IS NULL
         SET @NHOLIHRS = 0

      SET @return_value_argument = (@NTOTALHRS + @NHOLIHRS)

      RETURN 

   END
GO
BEGIN TRY
    EXEC sp_addextendedproperty
        N'MS_SSMA_SOURCE', N'HRP.EHRPHRAFUNC_PKG.F_GETWORKHRS',
        N'SCHEMA', N'hrp',
        N'PROCEDURE', N'EHRPHRAFUNC_PKG$F_GETWORKHRS$2$IMPL'
END TRY
BEGIN CATCH
    IF (@@TRANCOUNT > 0) ROLLBACK
    PRINT ERROR_MESSAGE()
END CATCH
GO
