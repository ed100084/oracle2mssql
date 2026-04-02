
USE MIS
GO
 IF NOT EXISTS(SELECT * FROM sys.schemas WHERE [name] = N'hrp')      
     EXEC (N'CREATE SCHEMA hrp')                                   
 GO                                                               

USE MIS
GO
IF  EXISTS (SELECT * FROM sys.objects so JOIN sys.schemas sc ON so.schema_id = sc.schema_id WHERE so.name = N'EHRPHRA3_PKG$F_HRA4010_E$IMPL'  AND sc.name=N'hrp'  AND type in (N'P',N'PC'))
 DROP PROCEDURE [hrp].[EHRPHRA3_PKG$F_HRA4010_E$IMPL]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE HRP.EHRPHRA3_PKG$F_HRA4010_E$IMPL  
   @TRNYM_IN varchar(max),
   @TRNSHIFT_IN varchar(max),
   @EMPNO_IN varchar(max),
   @STRARTDATE_IN datetime2(0),
   @ENDDATE_IN datetime2(0),
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
         @DSTRARTDATE datetime2(0) = @STRARTDATE_IN, 
         @DENDDATE datetime2(0) = @ENDDATE_IN, 
         @SORGANTYPE varchar(10) = @ORGTYPE_IN, 
         @SUPDATEBY varchar(20) = @UPDATEBY_IN, 
         @IEARLY int, 
         @ICNT int

      BEGIN TRY

         EXECUTE ssma_oracle.db_fn_check_init_package 'HRP', 'EHRPHRA3_PKG'

         /*------------------------------For義大--------------------------------*/
         BEGIN

            BEGIN TRY
               SELECT @IEARLY = count_big(*)
               FROM HRP.HRA_CARDATT_VIEW
               WHERE 
                  (HRA_CARDATT_VIEW.EMP_NO = @SEMPNO) AND 
                  (HRA_CARDATT_VIEW.ATT_DATE BETWEEN @DSTRARTDATE AND @DENDDATE) AND 
                  (HRA_CARDATT_VIEW.CHKOUT = '3') AND 
                  (HRA_CARDATT_VIEW.ORGAN_TYPE = @SORGANTYPE)
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
                  SET @IEARLY = 0
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

         IF @IEARLY > 0
            BEGIN
               IF HRP.EHRPHRA3_PKG$F_HRA4010_INS(
                  @STRNYM, 
                  @STRNSHIFT, 
                  @SEMPNO, 
                  '2021', 
                  @IEARLY, 
                  'T', 
                  @SORGANTYPE, 
                  @SUPDATEBY) <> 0
                  SET @ICNT = 1/*  早退次數INSERT失敗*/
            END

         /*------------------------------For義大--------------------------------*/
         DECLARE
            @db_null_statement int

         SET @return_value_argument = @ICNT

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
        N'MS_SSMA_SOURCE', N'HRP.EHRPHRA3_PKG.f_hra4010_E',
        N'SCHEMA', N'hrp',
        N'PROCEDURE', N'EHRPHRA3_PKG$F_HRA4010_E$IMPL'
END TRY
BEGIN CATCH
    IF (@@TRANCOUNT > 0) ROLLBACK
    PRINT ERROR_MESSAGE()
END CATCH
GO
