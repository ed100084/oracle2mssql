
USE MIS
GO
 IF NOT EXISTS(SELECT * FROM sys.schemas WHERE [name] = N'hrp')      
     EXEC (N'CREATE SCHEMA hrp')                                   
 GO                                                               

USE MIS
GO
IF  EXISTS (SELECT * FROM sys.objects so JOIN sys.schemas sc ON so.schema_id = sc.schema_id WHERE so.name = N'EHRPHRA3_PKG$F_HRA4010_INS$IMPL'  AND sc.name=N'hrp'  AND type in (N'P',N'PC'))
 DROP PROCEDURE [hrp].[EHRPHRA3_PKG$F_HRA4010_INS$IMPL]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE HRP.EHRPHRA3_PKG$F_HRA4010_INS$IMPL  
   @TRNYM_IN varchar(max),
   @TRNSHIFT_IN varchar(max),
   @EMPNO_IN varchar(max),
   @ATTCODE_IN varchar(max),
   /*
   *   SSMA warning messages:
   *   O2SS0356: Conversion from NUMBER datatype can cause data loss.
   */

   @ATTVALUE_IN float(53),
   @ATTUNIT_IN varchar(max),
   @ORGTYPE_IN varchar(max),
   @UPDATEBY_IN varchar(max),
   /*
   *   SSMA warning messages:
   *   O2SS0356: Conversion from NUMBER datatype can cause data loss.
   */

   @return_value_argument float(53)  OUTPUT
AS 
   BEGIN

      DECLARE
         @STRNYM varchar(7) = @TRNYM_IN, 
         @STRNSHIFT varchar(2) = @TRNSHIFT_IN, 
         @SEMPNO varchar(20) = @EMPNO_IN, 
         @SATTCODE varchar(4) = @ATTCODE_IN, 
         /*
         *   SSMA warning messages:
         *   O2SS0356: Conversion from NUMBER datatype can cause data loss.
         */

         @SATTVALUE float(53) = @ATTVALUE_IN, 
         @SATTUNIT varchar(1) = @ATTUNIT_IN, 
         @SORGANTYPE varchar(10) = @ORGTYPE_IN, 
         @SUPDATEBY varchar(20) = @UPDATEBY_IN, 
         @ICNT int

      BEGIN TRY

         EXECUTE ssma_oracle.db_fn_check_init_package 'HRP', 'EHRPHRA3_PKG'

         BEGIN

            BEGIN TRY
               SELECT @ICNT = count_big(*)
               FROM HRP.HRA_ATTDTL
               WHERE 
                  HRA_ATTDTL.TRN_YM = @STRNYM AND 
                  HRA_ATTDTL.TRN_SHIFT = @STRNSHIFT AND 
                  HRA_ATTDTL.EMP_NO = @SEMPNO AND 
                  HRA_ATTDTL.ATT_CODE = @SATTCODE AND 
                  HRA_ATTDTL.ORGAN_TYPE = @SORGANTYPE
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
                  SET @ICNT = 0
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

         IF @ICNT = 0
            INSERT HRP.HRA_ATTDTL(
               TRN_YM, 
               TRN_SHIFT, 
               EMP_NO, 
               ATT_CODE, 
               ATT_VALUE, 
               ATT_UNIT, 
               CREATED_BY, 
               CREATION_DATE, 
               LAST_UPDATED_BY, 
               LAST_UPDATE_DATE, 
               ORG_BY, 
               ORGAN_TYPE)
               VALUES (
                  @STRNYM, 
                  @STRNSHIFT, 
                  @SEMPNO, 
                  @SATTCODE, 
                  @SATTVALUE, 
                  @SATTUNIT, 
                  @SUPDATEBY, 
                  sysdatetime(), 
                  @SUPDATEBY, 
                  sysdatetime(), 
                  @SORGANTYPE, 
                  @SORGANTYPE)
         ELSE 
            UPDATE HRP.HRA_ATTDTL
               SET 
                  ATT_VALUE = HRA_ATTDTL.ATT_VALUE + @SATTVALUE
            WHERE 
               HRA_ATTDTL.TRN_YM = @STRNYM AND 
               HRA_ATTDTL.TRN_SHIFT = @STRNSHIFT AND 
               HRA_ATTDTL.EMP_NO = @SEMPNO AND 
               HRA_ATTDTL.ATT_CODE = @SATTCODE AND 
               HRA_ATTDTL.ORGAN_TYPE = @SORGANTYPE

         DECLARE
            @db_null_statement int

         SET @return_value_argument = 0

         RETURN 

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

         BEGIN

            IF @@TRANCOUNT > 0
               ROLLBACK WORK 

            SET @return_value_argument = ssma_oracle.db_error_sqlcode(@exceptionidentifier$2, @errornumber$2)

            RETURN 

            DECLARE
               @db_null_statement$2 int

         END

      END CATCH

   END
GO
BEGIN TRY
    EXEC sp_addextendedproperty
        N'MS_SSMA_SOURCE', N'HRP.EHRPHRA3_PKG.f_hra4010_Ins',
        N'SCHEMA', N'hrp',
        N'PROCEDURE', N'EHRPHRA3_PKG$F_HRA4010_INS$IMPL'
END TRY
BEGIN CATCH
    IF (@@TRANCOUNT > 0) ROLLBACK
    PRINT ERROR_MESSAGE()
END CATCH
GO
