
USE MIS
GO
 IF NOT EXISTS(SELECT * FROM sys.schemas WHERE [name] = N'hrp')      
     EXEC (N'CREATE SCHEMA hrp')                                   
 GO                                                               

USE MIS
GO
IF  EXISTS (SELECT * FROM sys.objects so JOIN sys.schemas sc ON so.schema_id = sc.schema_id WHERE so.name = N'EHRPHRAFUNC_PKG$F_GETCONDITION$IMPL'  AND sc.name=N'hrp'  AND type in (N'P',N'PC'))
 DROP PROCEDURE [hrp].[EHRPHRAFUNC_PKG$F_GETCONDITION$IMPL]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE HRP.EHRPHRAFUNC_PKG$F_GETCONDITION$IMPL  
   @SCHYM_IN varchar(max),
   @EMPNO_IN varchar(max),
   @return_value_argument varchar(max)  OUTPUT
AS 
   BEGIN

      EXECUTE ssma_oracle.db_fn_check_init_package 'HRP', 'EHRPHRAFUNC_PKG'

      DECLARE
         @SSCHYM varchar(10) = @SCHYM_IN, 
         @SEMPNO varchar(10) = @EMPNO_IN, 
         @SRESULTS varchar(1), 
         @ICNT int = 0, 
         @IDAYS int = 0

      SET @IDAYS = CAST(CONVERT(varchar(2), ssma_oracle.last_day(ssma_oracle.to_date2(ISNULL(@SSCHYM, '') + '-01', 'YYYY-MM-DD')), 106) AS numeric(38, 10))

      IF @IDAYS = 28
         BEGIN

            BEGIN TRY
               SELECT @ICNT = count_big(*)
               FROM HRP.HRA_CLASSSCH
               WHERE 
                  HRA_CLASSSCH.SCH_YM = @SSCHYM AND 
                  HRA_CLASSSCH.EMP_NO = @SEMPNO AND 
                  (
                  HRA_CLASSSCH.SCH_01 IS NULL OR 
                  HRA_CLASSSCH.SCH_01 = '' OR 
                  HRA_CLASSSCH.SCH_02 IS NULL OR 
                  HRA_CLASSSCH.SCH_02 = '' OR 
                  HRA_CLASSSCH.SCH_03 IS NULL OR 
                  HRA_CLASSSCH.SCH_03 = '' OR 
                  HRA_CLASSSCH.SCH_04 IS NULL OR 
                  HRA_CLASSSCH.SCH_04 = '' OR 
                  HRA_CLASSSCH.SCH_05 IS NULL OR 
                  HRA_CLASSSCH.SCH_05 = '' OR 
                  HRA_CLASSSCH.SCH_06 IS NULL OR 
                  HRA_CLASSSCH.SCH_06 = '' OR 
                  HRA_CLASSSCH.SCH_07 IS NULL OR 
                  HRA_CLASSSCH.SCH_07 = '' OR 
                  HRA_CLASSSCH.SCH_08 IS NULL OR 
                  HRA_CLASSSCH.SCH_08 = '' OR 
                  HRA_CLASSSCH.SCH_09 IS NULL OR 
                  HRA_CLASSSCH.SCH_09 = '' OR 
                  HRA_CLASSSCH.SCH_10 IS NULL OR 
                  HRA_CLASSSCH.SCH_10 = '' OR 
                  HRA_CLASSSCH.SCH_11 IS NULL OR 
                  HRA_CLASSSCH.SCH_11 = '' OR 
                  HRA_CLASSSCH.SCH_12 IS NULL OR 
                  HRA_CLASSSCH.SCH_12 = '' OR 
                  HRA_CLASSSCH.SCH_13 IS NULL OR 
                  HRA_CLASSSCH.SCH_13 = '' OR 
                  HRA_CLASSSCH.SCH_14 IS NULL OR 
                  HRA_CLASSSCH.SCH_14 = '' OR 
                  HRA_CLASSSCH.SCH_15 IS NULL OR 
                  HRA_CLASSSCH.SCH_15 = '' OR 
                  HRA_CLASSSCH.SCH_16 IS NULL OR 
                  HRA_CLASSSCH.SCH_16 = '' OR 
                  HRA_CLASSSCH.SCH_17 IS NULL OR 
                  HRA_CLASSSCH.SCH_17 = '' OR 
                  HRA_CLASSSCH.SCH_18 IS NULL OR 
                  HRA_CLASSSCH.SCH_18 = '' OR 
                  HRA_CLASSSCH.SCH_19 IS NULL OR 
                  HRA_CLASSSCH.SCH_19 = '' OR 
                  HRA_CLASSSCH.SCH_20 IS NULL OR 
                  HRA_CLASSSCH.SCH_20 = '' OR 
                  HRA_CLASSSCH.SCH_21 IS NULL OR 
                  HRA_CLASSSCH.SCH_21 = '' OR 
                  HRA_CLASSSCH.SCH_22 IS NULL OR 
                  HRA_CLASSSCH.SCH_22 = '' OR 
                  HRA_CLASSSCH.SCH_23 IS NULL OR 
                  HRA_CLASSSCH.SCH_23 = '' OR 
                  HRA_CLASSSCH.SCH_24 IS NULL OR 
                  HRA_CLASSSCH.SCH_24 = '' OR 
                  HRA_CLASSSCH.SCH_25 IS NULL OR 
                  HRA_CLASSSCH.SCH_25 = '' OR 
                  HRA_CLASSSCH.SCH_26 IS NULL OR 
                  HRA_CLASSSCH.SCH_26 = '' OR 
                  HRA_CLASSSCH.SCH_27 IS NULL OR 
                  HRA_CLASSSCH.SCH_27 = '' OR 
                  HRA_CLASSSCH.SCH_28 IS NULL OR 
                  HRA_CLASSSCH.SCH_28 = '')
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
      ELSE 
         IF @IDAYS = 29
            BEGIN

               BEGIN TRY
                  SELECT @ICNT = count_big(*)
                  FROM HRP.HRA_CLASSSCH
                  WHERE 
                     HRA_CLASSSCH.SCH_YM = @SSCHYM AND 
                     HRA_CLASSSCH.EMP_NO = @SEMPNO AND 
                     (
                     HRA_CLASSSCH.SCH_01 IS NULL OR 
                     HRA_CLASSSCH.SCH_01 = '' OR 
                     HRA_CLASSSCH.SCH_02 IS NULL OR 
                     HRA_CLASSSCH.SCH_02 = '' OR 
                     HRA_CLASSSCH.SCH_03 IS NULL OR 
                     HRA_CLASSSCH.SCH_03 = '' OR 
                     HRA_CLASSSCH.SCH_04 IS NULL OR 
                     HRA_CLASSSCH.SCH_04 = '' OR 
                     HRA_CLASSSCH.SCH_05 IS NULL OR 
                     HRA_CLASSSCH.SCH_05 = '' OR 
                     HRA_CLASSSCH.SCH_06 IS NULL OR 
                     HRA_CLASSSCH.SCH_06 = '' OR 
                     HRA_CLASSSCH.SCH_07 IS NULL OR 
                     HRA_CLASSSCH.SCH_07 = '' OR 
                     HRA_CLASSSCH.SCH_08 IS NULL OR 
                     HRA_CLASSSCH.SCH_08 = '' OR 
                     HRA_CLASSSCH.SCH_09 IS NULL OR 
                     HRA_CLASSSCH.SCH_09 = '' OR 
                     HRA_CLASSSCH.SCH_10 IS NULL OR 
                     HRA_CLASSSCH.SCH_10 = '' OR 
                     HRA_CLASSSCH.SCH_11 IS NULL OR 
                     HRA_CLASSSCH.SCH_11 = '' OR 
                     HRA_CLASSSCH.SCH_12 IS NULL OR 
                     HRA_CLASSSCH.SCH_12 = '' OR 
                     HRA_CLASSSCH.SCH_13 IS NULL OR 
                     HRA_CLASSSCH.SCH_13 = '' OR 
                     HRA_CLASSSCH.SCH_14 IS NULL OR 
                     HRA_CLASSSCH.SCH_14 = '' OR 
                     HRA_CLASSSCH.SCH_15 IS NULL OR 
                     HRA_CLASSSCH.SCH_15 = '' OR 
                     HRA_CLASSSCH.SCH_16 IS NULL OR 
                     HRA_CLASSSCH.SCH_16 = '' OR 
                     HRA_CLASSSCH.SCH_17 IS NULL OR 
                     HRA_CLASSSCH.SCH_17 = '' OR 
                     HRA_CLASSSCH.SCH_18 IS NULL OR 
                     HRA_CLASSSCH.SCH_18 = '' OR 
                     HRA_CLASSSCH.SCH_19 IS NULL OR 
                     HRA_CLASSSCH.SCH_19 = '' OR 
                     HRA_CLASSSCH.SCH_20 IS NULL OR 
                     HRA_CLASSSCH.SCH_20 = '' OR 
                     HRA_CLASSSCH.SCH_21 IS NULL OR 
                     HRA_CLASSSCH.SCH_21 = '' OR 
                     HRA_CLASSSCH.SCH_22 IS NULL OR 
                     HRA_CLASSSCH.SCH_22 = '' OR 
                     HRA_CLASSSCH.SCH_23 IS NULL OR 
                     HRA_CLASSSCH.SCH_23 = '' OR 
                     HRA_CLASSSCH.SCH_24 IS NULL OR 
                     HRA_CLASSSCH.SCH_24 = '' OR 
                     HRA_CLASSSCH.SCH_25 IS NULL OR 
                     HRA_CLASSSCH.SCH_25 = '' OR 
                     HRA_CLASSSCH.SCH_26 IS NULL OR 
                     HRA_CLASSSCH.SCH_26 = '' OR 
                     HRA_CLASSSCH.SCH_27 IS NULL OR 
                     HRA_CLASSSCH.SCH_27 = '' OR 
                     HRA_CLASSSCH.SCH_28 IS NULL OR 
                     HRA_CLASSSCH.SCH_28 = '' OR 
                     HRA_CLASSSCH.SCH_29 IS NULL OR 
                     HRA_CLASSSCH.SCH_29 = '')
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
                     SET @ICNT = 0
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
         ELSE 
            IF @IDAYS = 30
               BEGIN

                  BEGIN TRY
                     SELECT @ICNT = count_big(*)
                     FROM HRP.HRA_CLASSSCH
                     WHERE 
                        HRA_CLASSSCH.SCH_YM = @SSCHYM AND 
                        HRA_CLASSSCH.EMP_NO = @SEMPNO AND 
                        (
                        HRA_CLASSSCH.SCH_01 IS NULL OR 
                        HRA_CLASSSCH.SCH_01 = '' OR 
                        HRA_CLASSSCH.SCH_02 IS NULL OR 
                        HRA_CLASSSCH.SCH_02 = '' OR 
                        HRA_CLASSSCH.SCH_03 IS NULL OR 
                        HRA_CLASSSCH.SCH_03 = '' OR 
                        HRA_CLASSSCH.SCH_04 IS NULL OR 
                        HRA_CLASSSCH.SCH_04 = '' OR 
                        HRA_CLASSSCH.SCH_05 IS NULL OR 
                        HRA_CLASSSCH.SCH_05 = '' OR 
                        HRA_CLASSSCH.SCH_06 IS NULL OR 
                        HRA_CLASSSCH.SCH_06 = '' OR 
                        HRA_CLASSSCH.SCH_07 IS NULL OR 
                        HRA_CLASSSCH.SCH_07 = '' OR 
                        HRA_CLASSSCH.SCH_08 IS NULL OR 
                        HRA_CLASSSCH.SCH_08 = '' OR 
                        HRA_CLASSSCH.SCH_09 IS NULL OR 
                        HRA_CLASSSCH.SCH_09 = '' OR 
                        HRA_CLASSSCH.SCH_10 IS NULL OR 
                        HRA_CLASSSCH.SCH_10 = '' OR 
                        HRA_CLASSSCH.SCH_11 IS NULL OR 
                        HRA_CLASSSCH.SCH_11 = '' OR 
                        HRA_CLASSSCH.SCH_12 IS NULL OR 
                        HRA_CLASSSCH.SCH_12 = '' OR 
                        HRA_CLASSSCH.SCH_13 IS NULL OR 
                        HRA_CLASSSCH.SCH_13 = '' OR 
                        HRA_CLASSSCH.SCH_14 IS NULL OR 
                        HRA_CLASSSCH.SCH_14 = '' OR 
                        HRA_CLASSSCH.SCH_15 IS NULL OR 
                        HRA_CLASSSCH.SCH_15 = '' OR 
                        HRA_CLASSSCH.SCH_16 IS NULL OR 
                        HRA_CLASSSCH.SCH_16 = '' OR 
                        HRA_CLASSSCH.SCH_17 IS NULL OR 
                        HRA_CLASSSCH.SCH_17 = '' OR 
                        HRA_CLASSSCH.SCH_18 IS NULL OR 
                        HRA_CLASSSCH.SCH_18 = '' OR 
                        HRA_CLASSSCH.SCH_19 IS NULL OR 
                        HRA_CLASSSCH.SCH_19 = '' OR 
                        HRA_CLASSSCH.SCH_20 IS NULL OR 
                        HRA_CLASSSCH.SCH_20 = '' OR 
                        HRA_CLASSSCH.SCH_21 IS NULL OR 
                        HRA_CLASSSCH.SCH_21 = '' OR 
                        HRA_CLASSSCH.SCH_22 IS NULL OR 
                        HRA_CLASSSCH.SCH_22 = '' OR 
                        HRA_CLASSSCH.SCH_23 IS NULL OR 
                        HRA_CLASSSCH.SCH_23 = '' OR 
                        HRA_CLASSSCH.SCH_24 IS NULL OR 
                        HRA_CLASSSCH.SCH_24 = '' OR 
                        HRA_CLASSSCH.SCH_25 IS NULL OR 
                        HRA_CLASSSCH.SCH_25 = '' OR 
                        HRA_CLASSSCH.SCH_26 IS NULL OR 
                        HRA_CLASSSCH.SCH_26 = '' OR 
                        HRA_CLASSSCH.SCH_27 IS NULL OR 
                        HRA_CLASSSCH.SCH_27 = '' OR 
                        HRA_CLASSSCH.SCH_28 IS NULL OR 
                        HRA_CLASSSCH.SCH_28 = '' OR 
                        HRA_CLASSSCH.SCH_29 IS NULL OR 
                        HRA_CLASSSCH.SCH_29 = '' OR 
                        HRA_CLASSSCH.SCH_30 IS NULL OR 
                        HRA_CLASSSCH.SCH_30 = '')
                  END TRY

                  BEGIN CATCH

                     DECLARE
                        @errornumber$3 int

                     SET @errornumber$3 = ERROR_NUMBER()

                     DECLARE
                        @errormessage$3 nvarchar(4000)

                     SET @errormessage$3 = ERROR_MESSAGE()

                     DECLARE
                        @exceptionidentifier$3 nvarchar(4000)

                     SELECT @exceptionidentifier$3 = ssma_oracle.db_error_get_oracle_exception_id(@errormessage$3, @errornumber$3)

                     IF (@exceptionidentifier$3 LIKE N'ORA-00100%')
                        SET @ICNT = 0
                     ELSE 
                        BEGIN
                           IF (@exceptionidentifier$3 IS NOT NULL)
                              BEGIN
                                 IF @errornumber$3 = 59998
                                    RAISERROR(59998, 16, 1, @exceptionidentifier$3)
                                 ELSE 
                                    RAISERROR(59999, 16, 1, @exceptionidentifier$3)
                              END
                           ELSE 
                              BEGIN
                                 EXECUTE ssma_oracle.ssma_rethrowerror
                              END
                        END

                  END CATCH

               END
            ELSE 
               BEGIN

                  BEGIN TRY
                     SELECT @ICNT = count_big(*)
                     FROM HRP.HRA_CLASSSCH
                     WHERE 
                        HRA_CLASSSCH.SCH_YM = @SSCHYM AND 
                        HRA_CLASSSCH.EMP_NO = @SEMPNO AND 
                        (
                        HRA_CLASSSCH.SCH_01 IS NULL OR 
                        HRA_CLASSSCH.SCH_01 = '' OR 
                        HRA_CLASSSCH.SCH_02 IS NULL OR 
                        HRA_CLASSSCH.SCH_02 = '' OR 
                        HRA_CLASSSCH.SCH_03 IS NULL OR 
                        HRA_CLASSSCH.SCH_03 = '' OR 
                        HRA_CLASSSCH.SCH_04 IS NULL OR 
                        HRA_CLASSSCH.SCH_04 = '' OR 
                        HRA_CLASSSCH.SCH_05 IS NULL OR 
                        HRA_CLASSSCH.SCH_05 = '' OR 
                        HRA_CLASSSCH.SCH_06 IS NULL OR 
                        HRA_CLASSSCH.SCH_06 = '' OR 
                        HRA_CLASSSCH.SCH_07 IS NULL OR 
                        HRA_CLASSSCH.SCH_07 = '' OR 
                        HRA_CLASSSCH.SCH_08 IS NULL OR 
                        HRA_CLASSSCH.SCH_08 = '' OR 
                        HRA_CLASSSCH.SCH_09 IS NULL OR 
                        HRA_CLASSSCH.SCH_09 = '' OR 
                        HRA_CLASSSCH.SCH_10 IS NULL OR 
                        HRA_CLASSSCH.SCH_10 = '' OR 
                        HRA_CLASSSCH.SCH_11 IS NULL OR 
                        HRA_CLASSSCH.SCH_11 = '' OR 
                        HRA_CLASSSCH.SCH_12 IS NULL OR 
                        HRA_CLASSSCH.SCH_12 = '' OR 
                        HRA_CLASSSCH.SCH_13 IS NULL OR 
                        HRA_CLASSSCH.SCH_13 = '' OR 
                        HRA_CLASSSCH.SCH_14 IS NULL OR 
                        HRA_CLASSSCH.SCH_14 = '' OR 
                        HRA_CLASSSCH.SCH_15 IS NULL OR 
                        HRA_CLASSSCH.SCH_15 = '' OR 
                        HRA_CLASSSCH.SCH_16 IS NULL OR 
                        HRA_CLASSSCH.SCH_16 = '' OR 
                        HRA_CLASSSCH.SCH_17 IS NULL OR 
                        HRA_CLASSSCH.SCH_17 = '' OR 
                        HRA_CLASSSCH.SCH_18 IS NULL OR 
                        HRA_CLASSSCH.SCH_18 = '' OR 
                        HRA_CLASSSCH.SCH_19 IS NULL OR 
                        HRA_CLASSSCH.SCH_19 = '' OR 
                        HRA_CLASSSCH.SCH_20 IS NULL OR 
                        HRA_CLASSSCH.SCH_20 = '' OR 
                        HRA_CLASSSCH.SCH_21 IS NULL OR 
                        HRA_CLASSSCH.SCH_21 = '' OR 
                        HRA_CLASSSCH.SCH_22 IS NULL OR 
                        HRA_CLASSSCH.SCH_22 = '' OR 
                        HRA_CLASSSCH.SCH_23 IS NULL OR 
                        HRA_CLASSSCH.SCH_23 = '' OR 
                        HRA_CLASSSCH.SCH_24 IS NULL OR 
                        HRA_CLASSSCH.SCH_24 = '' OR 
                        HRA_CLASSSCH.SCH_25 IS NULL OR 
                        HRA_CLASSSCH.SCH_25 = '' OR 
                        HRA_CLASSSCH.SCH_26 IS NULL OR 
                        HRA_CLASSSCH.SCH_26 = '' OR 
                        HRA_CLASSSCH.SCH_27 IS NULL OR 
                        HRA_CLASSSCH.SCH_27 = '' OR 
                        HRA_CLASSSCH.SCH_28 IS NULL OR 
                        HRA_CLASSSCH.SCH_28 = '' OR 
                        HRA_CLASSSCH.SCH_29 IS NULL OR 
                        HRA_CLASSSCH.SCH_29 = '' OR 
                        HRA_CLASSSCH.SCH_30 IS NULL OR 
                        HRA_CLASSSCH.SCH_30 = '' OR 
                        HRA_CLASSSCH.SCH_28 IS NULL OR 
                        HRA_CLASSSCH.SCH_28 = '')
                  END TRY

                  BEGIN CATCH

                     DECLARE
                        @errornumber$4 int

                     SET @errornumber$4 = ERROR_NUMBER()

                     DECLARE
                        @errormessage$4 nvarchar(4000)

                     SET @errormessage$4 = ERROR_MESSAGE()

                     DECLARE
                        @exceptionidentifier$4 nvarchar(4000)

                     SELECT @exceptionidentifier$4 = ssma_oracle.db_error_get_oracle_exception_id(@errormessage$4, @errornumber$4)

                     IF (@exceptionidentifier$4 LIKE N'ORA-00100%')
                        SET @ICNT = 0
                     ELSE 
                        BEGIN
                           IF (@exceptionidentifier$4 IS NOT NULL)
                              BEGIN
                                 IF @errornumber$4 = 59998
                                    RAISERROR(59998, 16, 1, @exceptionidentifier$4)
                                 ELSE 
                                    RAISERROR(59999, 16, 1, @exceptionidentifier$4)
                              END
                           ELSE 
                              BEGIN
                                 EXECUTE ssma_oracle.ssma_rethrowerror
                              END
                        END

                  END CATCH

               END

      IF @ICNT = 0
         SET @SRESULTS = 'A'
      ELSE 
         SET @SRESULTS = 'B'

      SET @return_value_argument = @SRESULTS

      RETURN 

   END
GO
BEGIN TRY
    EXEC sp_addextendedproperty
        N'MS_SSMA_SOURCE', N'HRP.EHRPHRAFUNC_PKG.F_GETCONDITION',
        N'SCHEMA', N'hrp',
        N'PROCEDURE', N'EHRPHRAFUNC_PKG$F_GETCONDITION$IMPL'
END TRY
BEGIN CATCH
    IF (@@TRANCOUNT > 0) ROLLBACK
    PRINT ERROR_MESSAGE()
END CATCH
GO
