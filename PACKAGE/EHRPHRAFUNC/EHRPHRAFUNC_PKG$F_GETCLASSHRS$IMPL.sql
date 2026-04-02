
USE MIS
GO
 IF NOT EXISTS(SELECT * FROM sys.schemas WHERE [name] = N'hrp')      
     EXEC (N'CREATE SCHEMA hrp')                                   
 GO                                                               

USE MIS
GO
IF  EXISTS (SELECT * FROM sys.objects so JOIN sys.schemas sc ON so.schema_id = sc.schema_id WHERE so.name = N'EHRPHRAFUNC_PKG$F_GETCLASSHRS$IMPL'  AND sc.name=N'hrp'  AND type in (N'P',N'PC'))
 DROP PROCEDURE [hrp].[EHRPHRAFUNC_PKG$F_GETCLASSHRS$IMPL]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE HRP.EHRPHRAFUNC_PKG$F_GETCLASSHRS$IMPL  
   @DEPTNO_IN varchar(max),
   @ATTDATE_IN datetime2(0),
   @SCHKIND_IN varchar(max),
   /*
   *   SSMA warning messages:
   *   O2SS0356: Conversion from NUMBER datatype can cause data loss.
   */

   @return_value_argument float(53)  OUTPUT
AS 
   BEGIN

      EXECUTE ssma_oracle.db_fn_check_init_package 'HRP', 'EHRPHRAFUNC_PKG'

      DECLARE
         @SDEPTNO varchar(10) = @DEPTNO_IN, 
         @DATTDATE datetime2(0) = @ATTDATE_IN, 
         @SSCHKIND varchar(1) = @SCHKIND_IN, 
         @SATTDATE varchar(10), 
         /*
         *   SSMA warning messages:
         *   O2SS0356: Conversion from NUMBER datatype can cause data loss.
         */

         @NSCHHRS float(53) = 0

      SET @SATTDATE = ssma_oracle.to_char_date(@DATTDATE, 'YYYY-MM-DD')

      BEGIN

         BEGIN TRY
            SELECT @NSCHHRS = sum(HRA_CLASSMST.WORK_HRS / 8)
            FROM HRP.HRA_CLASSSCH_VIEW, HRP.HRA_CLASSMST
            WHERE 
               (HRA_CLASSSCH_VIEW.CLASS_CODE = HRA_CLASSMST.CLASS_CODE) AND 
               (HRA_CLASSSCH_VIEW.DEPT_NO = @SDEPTNO AND HRA_CLASSMST.SCH_KIND = @SSCHKIND) AND 
               /*TO_CHAR(hra_classsch_view.att_date, 'YYYY-MM-DD') = sAttDate;*/HRA_CLASSSCH_VIEW.ATT_DATE = @SATTDATE
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
               SET @NSCHHRS = 0
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

      IF @NSCHHRS IS NULL
         SET @NSCHHRS = 0

      SET @return_value_argument = @NSCHHRS

      RETURN 

   END
GO
BEGIN TRY
    EXEC sp_addextendedproperty
        N'MS_SSMA_SOURCE', N'HRP.EHRPHRAFUNC_PKG.F_GETCLASSHRS',
        N'SCHEMA', N'hrp',
        N'PROCEDURE', N'EHRPHRAFUNC_PKG$F_GETCLASSHRS$IMPL'
END TRY
BEGIN CATCH
    IF (@@TRANCOUNT > 0) ROLLBACK
    PRINT ERROR_MESSAGE()
END CATCH
GO
