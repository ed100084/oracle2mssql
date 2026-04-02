
USE MIS
GO
 IF NOT EXISTS(SELECT * FROM sys.schemas WHERE [name] = N'hrp')      
     EXEC (N'CREATE SCHEMA hrp')                                   
 GO                                                               

USE MIS
GO
IF  EXISTS (SELECT * FROM sys.objects so JOIN sys.schemas sc ON so.schema_id = sc.schema_id WHERE so.name = N'EHRPHRAFUNC_PKG$F_COUNTFEE$IMPL'  AND sc.name=N'hrp'  AND type in (N'P',N'PC'))
 DROP PROCEDURE [hrp].[EHRPHRAFUNC_PKG$F_COUNTFEE$IMPL]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE HRP.EHRPHRAFUNC_PKG$F_COUNTFEE$IMPL  
   /*
   *   SSMA warning messages:
   *   O2SS0356: Conversion from NUMBER datatype can cause data loss.
   */

   @OTMHRS_33 float(53),
   /*
   *   SSMA warning messages:
   *   O2SS0356: Conversion from NUMBER datatype can cause data loss.
   */

   @OTMHRS_43 float(53),
   /*
   *   SSMA warning messages:
   *   O2SS0356: Conversion from NUMBER datatype can cause data loss.
   */

   @OTMHRS_53 float(53),
   /*
   *   SSMA warning messages:
   *   O2SS0356: Conversion from NUMBER datatype can cause data loss.
   */

   @OTMHRS_83 float(53),
   /*
   *   SSMA warning messages:
   *   O2SS0356: Conversion from NUMBER datatype can cause data loss.
   */

   @SUPHRS_33 float(53),
   /*
   *   SSMA warning messages:
   *   O2SS0356: Conversion from NUMBER datatype can cause data loss.
   */

   @SUPHRS_43 float(53),
   /*
   *   SSMA warning messages:
   *   O2SS0356: Conversion from NUMBER datatype can cause data loss.
   */

   @SUPHRS_53 float(53),
   /*
   *   SSMA warning messages:
   *   O2SS0356: Conversion from NUMBER datatype can cause data loss.
   */

   @SUPHRS_83 float(53),
   @EMPNO_IN varchar(max),
   @SCHYM_IN varchar(max),
   @NOTE_FLAG varchar(max),
   /*
   *   SSMA warning messages:
   *   O2SS0356: Conversion from NUMBER datatype can cause data loss.
   */

   @return_value_argument float(53)  OUTPUT
AS 
   BEGIN

      EXECUTE ssma_oracle.db_fn_check_init_package 'HRP', 'EHRPHRAFUNC_PKG'

      DECLARE
         /*
         *   SSMA warning messages:
         *   O2SS0356: Conversion from NUMBER datatype can cause data loss.
         */

         @NSALAMT float(53), 
         /*
         *   SSMA warning messages:
         *   O2SS0356: Conversion from NUMBER datatype can cause data loss.
         */

         @NDAYFEE float(53), 
         /*
         *   SSMA warning messages:
         *   O2SS0356: Conversion from NUMBER datatype can cause data loss.
         */

         @NDAYFEE_G float(53), 
         /*
         *   SSMA warning messages:
         *   O2SS0356: Conversion from NUMBER datatype can cause data loss.
         */

         @NNIGHTAMT float(53) = 0, 
         /*
         *   SSMA warning messages:
         *   O2SS0356: Conversion from NUMBER datatype can cause data loss.
         */

         @NFEE_AMT float(53) = 0, 
         /*
         *   SSMA warning messages:
         *   O2SS0356: Conversion from NUMBER datatype can cause data loss.
         */

         @NFEE_OTM float(53) = 0, 
         /*
         *   SSMA warning messages:
         *   O2SS0356: Conversion from NUMBER datatype can cause data loss.
         */

         @NFEE_SUP float(53) = 0, 
         /*
         *   SSMA warning messages:
         *   O2SS0356: Conversion from NUMBER datatype can cause data loss.
         */

         @NFEE_AMT_OTM float(53) = 0, 
         /*
         *   SSMA warning messages:
         *   O2SS0356: Conversion from NUMBER datatype can cause data loss.
         */

         @NFEE_AMT_SUP float(53) = 0

      BEGIN

         BEGIN TRY
            SELECT @NSALAMT = isnull(A.SAL_TOT, 0), @NNIGHTAMT = isnull(B.NIGHT_AMT, 0)
            FROM 
               HRP.HRS_ACNTTOT  AS A 
                  LEFT OUTER JOIN 
                  (
                     SELECT HRA_CLASSSCH.EMP_NO, HRA_CLASSSCH.NIGHT_AMT
                     FROM HRP.HRA_CLASSSCH
                     WHERE HRA_CLASSSCH.SCH_YM = @SCHYM_IN
                  )  AS B 
                  ON A.EMP_NO = B.EMP_NO
            WHERE A.SAL_YM = @SCHYM_IN AND A.EMP_NO = @EMPNO_IN
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
               BEGIN

                  SET @NSALAMT = 0

                  SET @NFEE_AMT = 0

               END
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

      SET @NDAYFEE = (@NSALAMT + @NNIGHTAMT) / 240

      SET @NDAYFEE_G = @NSALAMT / 240

      /*-----------------計算加班費-------------------*/
      SET @NFEE_OTM = (@OTMHRS_33 * 1) + (@OTMHRS_43 * 4 / 3) + (@OTMHRS_53 * 5 / 3) + (@OTMHRS_83 * 8 / 3)

      IF @NOTE_FLAG = 'G'
         SET @NFEE_AMT_OTM = @NFEE_OTM * @NDAYFEE_G
      ELSE 
         SET @NFEE_AMT_OTM = @NFEE_OTM * @NDAYFEE

      /* 申請補休時數換算加班費*/
      SET @NFEE_SUP = (@SUPHRS_33 * 1) + (@SUPHRS_43 * 4 / 3) + (@SUPHRS_53 * 5 / 3) + (@SUPHRS_83 * 8 / 3)

      IF @NOTE_FLAG = 'G'
         SET @NFEE_AMT_SUP = @NFEE_SUP * @NDAYFEE_G
      ELSE 
         SET @NFEE_AMT_SUP = @NFEE_SUP * @NDAYFEE

      SET @NFEE_AMT = @NFEE_AMT_OTM - @NFEE_AMT_SUP/* 免稅加班費 = 申請加班倍數計算加班費 - 已補休時數倍數計算加班費*/

      SET @return_value_argument = @NFEE_AMT

      RETURN 

   END
GO
BEGIN TRY
    EXEC sp_addextendedproperty
        N'MS_SSMA_SOURCE', N'HRP.EHRPHRAFUNC_PKG.F_countfee',
        N'SCHEMA', N'hrp',
        N'PROCEDURE', N'EHRPHRAFUNC_PKG$F_COUNTFEE$IMPL'
END TRY
BEGIN CATCH
    IF (@@TRANCOUNT > 0) ROLLBACK
    PRINT ERROR_MESSAGE()
END CATCH
GO
