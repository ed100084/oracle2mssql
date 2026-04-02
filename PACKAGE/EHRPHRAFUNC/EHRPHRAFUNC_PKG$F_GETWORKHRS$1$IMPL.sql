
USE MIS
GO
 IF NOT EXISTS(SELECT * FROM sys.schemas WHERE [name] = N'hrp')      
     EXEC (N'CREATE SCHEMA hrp')                                   
 GO                                                               

USE MIS
GO
IF  EXISTS (SELECT * FROM sys.objects so JOIN sys.schemas sc ON so.schema_id = sc.schema_id WHERE so.name = N'EHRPHRAFUNC_PKG$F_GETWORKHRS$1$IMPL'  AND sc.name=N'hrp'  AND type in (N'P',N'PC'))
 DROP PROCEDURE [hrp].[EHRPHRAFUNC_PKG$F_GETWORKHRS$1$IMPL]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE HRP.EHRPHRAFUNC_PKG$F_GETWORKHRS$1$IMPL  
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

         @NCARDHRS float(53) = 0, 
         /*
         *   SSMA warning messages:
         *   O2SS0356: Conversion from NUMBER datatype can cause data loss.
         */

         @NNOCARDHRS float(53) = 0

      SET @SATTDATE = ssma_oracle.to_char_date(@DATTDATE, 'YYYY-MM-DD')

      BEGIN

         BEGIN TRY
            SELECT @NCARDHRS = sum(HRA_CLASSMST.WORK_HRS / 8)
            FROM HRP.HRA_CADSIGN_VIEW, HRP.HRA_CLASSMST
            WHERE (HRA_CADSIGN_VIEW.CLASS_CODE = HRA_CLASSMST.CLASS_CODE) AND (
               HRA_CADSIGN_VIEW.DEPT_NO = @SDEPTNO AND 
               ssma_oracle.to_char_date(HRA_CADSIGN_VIEW.ATT_DATE, 'YYYY-MM-DD') = @SATTDATE AND 
               HRA_CLASSMST.SCH_KIND = @SSCHKIND)
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
               SET @NCARDHRS = 0
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

      IF @NCARDHRS IS NULL
         SET @NCARDHRS = 0

      BEGIN

         BEGIN TRY
            SELECT @NNOCARDHRS = sum(HRA_CLASSMST.WORK_HRS / 8)
            FROM HRP.HRA_CLASSSCH_VIEW, HRP.HRE_PROFILE, HRP.HRA_CLASSMST
            WHERE 
               (HRA_CLASSSCH_VIEW.EMP_NO = HRE_PROFILE.EMP_NO) AND 
               (HRA_CLASSSCH_VIEW.CLASS_CODE = HRA_CLASSMST.CLASS_CODE) AND 
               (
               (HRA_CLASSSCH_VIEW.DEPT_NO = @SDEPTNO) AND 
               (HRE_PROFILE.ITEM_TYPE = 'Z') AND 
               (HRE_PROFILE.ITEM_NO = 'EMP01') AND 
               (HRA_CLASSMST.SCH_KIND = @SSCHKIND) AND 
               (/*    (to_char(hra_classsch_view.att_date, 'YYYY-MM-DD') = sAttDate));*/HRA_CLASSSCH_VIEW.ATT_DATE = @SATTDATE))
         END TRY

         BEGIN CATCH

            DECLARE
               @errornumber$2 int

            SET @errornumber$2 = ERROR_NUMBER()

            DECLARE
               @errormessage$2 nvarchar(4000)

            SET @errormessage$2 = ERROR_MESSAGE()

            DECLARE
               @exceptionidentifier$2 nvarchar(4000)

            SELECT @exceptionidentifier$2 = ssma_oracle.db_error_get_oracle_exception_id(@errormessage$2, @errornumber$2)

            IF (@exceptionidentifier$2 LIKE N'ORA-00100%')
               SET @NNOCARDHRS = 0
            ELSE 
               BEGIN
                  IF (@exceptionidentifier$2 IS NOT NULL)
                     BEGIN
                        IF @errornumber$2 = 59998
                           RAISERROR(59998, 16, 1, @exceptionidentifier$2)
                        ELSE 
                           RAISERROR(59999, 16, 1, @exceptionidentifier$2)
                     END
                  ELSE 
                     BEGIN
                        EXECUTE ssma_oracle.ssma_rethrowerror
                     END
               END

         END CATCH

      END

      IF @NNOCARDHRS IS NULL
         SET @NNOCARDHRS = 0

      SET @return_value_argument = (@NCARDHRS + @NNOCARDHRS)

      RETURN 

   END
GO
BEGIN TRY
    EXEC sp_addextendedproperty
        N'MS_SSMA_SOURCE', N'HRP.EHRPHRAFUNC_PKG.F_GETWORKHRS',
        N'SCHEMA', N'hrp',
        N'PROCEDURE', N'EHRPHRAFUNC_PKG$F_GETWORKHRS$1$IMPL'
END TRY
BEGIN CATCH
    IF (@@TRANCOUNT > 0) ROLLBACK
    PRINT ERROR_MESSAGE()
END CATCH
GO
