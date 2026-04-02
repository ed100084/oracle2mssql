
USE MIS
GO
 IF NOT EXISTS(SELECT * FROM sys.schemas WHERE [name] = N'hrp')      
     EXEC (N'CREATE SCHEMA hrp')                                   
 GO                                                               

USE MIS
GO
IF  EXISTS (SELECT * FROM sys.objects so JOIN sys.schemas sc ON so.schema_id = sc.schema_id WHERE so.name = N'EHRPHRAFUNC_PKG$F_GETOFFAMT$IMPL'  AND sc.name=N'hrp'  AND type in (N'P',N'PC'))
 DROP PROCEDURE [hrp].[EHRPHRAFUNC_PKG$F_GETOFFAMT$IMPL]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE HRP.EHRPHRAFUNC_PKG$F_GETOFFAMT$IMPL  
   @EMPNO_IN varchar(max),
   @DEPTNO_IN varchar(max),
   @ATTDATE_IN datetime2(0),
   @STARTTIME_IN varchar(max),
   /*
   *   SSMA warning messages:
   *   O2SS0356: Conversion from NUMBER datatype can cause data loss.
   */

   @OTMHRS_IN float(53),
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
         @SDEPTNO varchar(10) = @DEPTNO_IN, 
         @DATTDATE datetime2(0) = @ATTDATE_IN, 
         @SSTARTTIME varchar(4) = @STARTTIME_IN, 
         /*
         *   SSMA warning messages:
         *   O2SS0356: Conversion from NUMBER datatype can cause data loss.
         */

         @NOTMHRS float(53) = @OTMHRS_IN, 
         @SATTDATE varchar(10), 
         @SDONTCARD varchar(1), 
         @ICNT int, 
         /*
         *   SSMA warning messages:
         *   O2SS0356: Conversion from NUMBER datatype can cause data loss.
         */

         @NDUTYFEE float(53)

      SET @SATTDATE = ssma_oracle.to_char_date(@DATTDATE, 'YYYY-MM-DD')

      BEGIN

         BEGIN TRY
            SELECT @ICNT = count_big(*)
            FROM HRP.HRE_PROFILE
            WHERE 
               HRE_PROFILE.EMP_NO = @SEMPNO AND 
               HRE_PROFILE.ITEM_TYPE = 'Z' AND 
               HRE_PROFILE.ITEM_NO = 'EMP01'
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
         SET @SDONTCARD = 'N'
      ELSE 
         SET @SDONTCARD = 'Y'

      IF @SDONTCARD = 'Y'
         BEGIN

            BEGIN TRY
               SELECT @NDUTYFEE = sum(HRA_CLASSMST.DUTY_FEE)
               FROM HRP.HRA_CLASSSCH_VIEW, HRP.HRA_CLASSMST
               WHERE (HRA_CLASSSCH_VIEW.CLASS_CODE = HRA_CLASSMST.CLASS_CODE) AND (HRA_CLASSSCH_VIEW.EMP_NO = @SEMPNO)
               GROUP BY HRA_CLASSSCH_VIEW.ATT_DATE
               HAVING HRA_CLASSSCH_VIEW.ATT_DATE = @SATTDATE
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
                  SET @NDUTYFEE = 0
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
         BEGIN

            BEGIN TRY
               SELECT @NDUTYFEE = sum(HRA_CLASSMST.DUTY_FEE)
               FROM HRP.HRA_CLASSMST, HRP.HRA_CADSIGN_VIEW
               WHERE 
                  HRA_CLASSMST.CLASS_CODE = HRA_CADSIGN_VIEW.CLASS_CODE AND 
                  HRA_CADSIGN_VIEW.EMP_NO = @SEMPNO AND 
                  ssma_oracle.to_char_date(HRA_CADSIGN_VIEW.ATT_DATE, 'YYYY-MM-DD') = @SATTDATE
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
                  SET @NDUTYFEE = 0
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

      IF @NDUTYFEE IS NULL
         SET @NDUTYFEE = 0

      IF @NDUTYFEE = 0
         BEGIN

            SET @return_value_argument = 0

            RETURN 

         END

      IF @SDEPTNO = '1323' AND @NDUTYFEE = 150
         IF @SSTARTTIME >= '1900'
            BEGIN

               SET @return_value_argument = 0

               RETURN 

            END
         ELSE 
            BEGIN

               SET @return_value_argument = 150

               RETURN 

            END

      IF @NOTMHRS > 4
         BEGIN

            SET @return_value_argument = @NDUTYFEE

            RETURN 

         END

      IF @NDUTYFEE = 800
         BEGIN

            SET @return_value_argument = 0

            RETURN 

         END

      SET @return_value_argument = ssma_oracle.trunc(@NDUTYFEE * @NOTMHRS / 8, DEFAULT)

      RETURN 

   END
GO
BEGIN TRY
    EXEC sp_addextendedproperty
        N'MS_SSMA_SOURCE', N'HRP.EHRPHRAFUNC_PKG.F_GETOFFAMT',
        N'SCHEMA', N'hrp',
        N'PROCEDURE', N'EHRPHRAFUNC_PKG$F_GETOFFAMT$IMPL'
END TRY
BEGIN CATCH
    IF (@@TRANCOUNT > 0) ROLLBACK
    PRINT ERROR_MESSAGE()
END CATCH
GO
