
USE MIS
GO
 IF NOT EXISTS(SELECT * FROM sys.schemas WHERE [name] = N'hrp')      
     EXEC (N'CREATE SCHEMA hrp')                                   
 GO                                                               

USE MIS
GO
IF  EXISTS (SELECT * FROM sys.objects so JOIN sys.schemas sc ON so.schema_id = sc.schema_id WHERE so.name = N'EHRPHRAFUNC_PKG$F_GETDOCGIVEVAC$IMPL'  AND sc.name=N'hrp'  AND type in (N'P',N'PC'))
 DROP PROCEDURE [hrp].[EHRPHRAFUNC_PKG$F_GETDOCGIVEVAC$IMPL]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE HRP.EHRPHRAFUNC_PKG$F_GETDOCGIVEVAC$IMPL  
   @EMPNO_IN varchar(max),
   @VACYEAR_IN varchar(max),
   @VACTYPE_IN varchar(max),
   @VACRULE_IN varchar(max),
   /*
   *   SSMA warning messages:
   *   O2SS0356: Conversion from NUMBER datatype can cause data loss.
   */

   @return_value_argument float(53)  OUTPUT
AS 
   BEGIN

      EXECUTE ssma_oracle.db_fn_check_init_package 'HRP', 'EHRPHRAFUNC_PKG'

      DECLARE
         @SEMPNO varchar(20) = @EMPNO_IN, 
         @SVACYEAR varchar(4) = @VACYEAR_IN, 
         @SVACTYPE varchar(1) = @VACTYPE_IN, 
         @SVACRULE varchar(10) = @VACRULE_IN, 
         /*
         *   SSMA warning messages:
         *   O2SS0356: Conversion from NUMBER datatype can cause data loss.
         */

         @NVACHRS float(53), 
         /*
         *   SSMA warning messages:
         *   O2SS0356: Conversion from NUMBER datatype can cause data loss.
         */

         @NVACQTY float(53), 
         @DCOMEDATE datetime2(0), 
         @SVACYM varchar(7)

      BEGIN

         BEGIN TRY
            SELECT @DCOMEDATE = HRE_EMPBAS.COME_DATE
            FROM HRP.HRE_EMPBAS
            WHERE HRE_EMPBAS.EMP_NO = @SEMPNO
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
               SET @DCOMEDATE = NULL
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

      IF @DCOMEDATE IS NULL
         BEGIN

            SET @return_value_argument = 0

            RETURN 

         END

      BEGIN

         BEGIN TRY
            SELECT @NVACQTY = HRA_VCRLDTL.VAC_QTY
            FROM HRP.HRA_VCRLDTL
            WHERE HRA_VCRLDTL.VAC_TYPE = @SVACTYPE AND HRA_VCRLDTL.VAC_RUL = @SVACRULE
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
               SET @NVACQTY = 0
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

      IF @NVACQTY IS NULL
         SET @NVACQTY = 0

      SET @SVACYM = ISNULL(@SVACYEAR, '') + '-' + ISNULL(@SVACRULE, '')

      IF @SVACTYPE = 'K'
         IF ssma_oracle.to_char_date(@DCOMEDATE, 'YYYY-MM') > @SVACYM
            SET @NVACHRS = 0
         ELSE 
            SET @NVACHRS = @NVACQTY * 8

      IF @SVACTYPE = 'L'
         IF CONVERT(varchar(4), @DCOMEDATE, 102) > @SVACYEAR
            SET @NVACHRS = 0
         ELSE 
            SET @NVACHRS = @NVACQTY * 8

      SET @return_value_argument = @NVACHRS

      RETURN 

   END
GO
BEGIN TRY
    EXEC sp_addextendedproperty
        N'MS_SSMA_SOURCE', N'HRP.EHRPHRAFUNC_PKG.F_GETDOCGIVEVAC',
        N'SCHEMA', N'hrp',
        N'PROCEDURE', N'EHRPHRAFUNC_PKG$F_GETDOCGIVEVAC$IMPL'
END TRY
BEGIN CATCH
    IF (@@TRANCOUNT > 0) ROLLBACK
    PRINT ERROR_MESSAGE()
END CATCH
GO
