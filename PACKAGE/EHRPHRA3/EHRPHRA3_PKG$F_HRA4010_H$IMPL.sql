
USE MIS
GO
 IF NOT EXISTS(SELECT * FROM sys.schemas WHERE [name] = N'hrp')      
     EXEC (N'CREATE SCHEMA hrp')                                   
 GO                                                               

USE MIS
GO
IF  EXISTS (SELECT * FROM sys.objects so JOIN sys.schemas sc ON so.schema_id = sc.schema_id WHERE so.name = N'EHRPHRA3_PKG$F_HRA4010_H$IMPL'  AND sc.name=N'hrp'  AND type in (N'P',N'PC'))
 DROP PROCEDURE [hrp].[EHRPHRA3_PKG$F_HRA4010_H$IMPL]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE HRP.EHRPHRA3_PKG$F_HRA4010_H$IMPL  
   @TRNYM_IN varchar(max),
   @TRNSHIFT_IN varchar(max),
   @EMPNO_IN varchar(max),
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
         @SORGANTYPE varchar(10) = @ORGTYPE_IN, 
         @SUPDATEBY varchar(20) = @UPDATEBY_IN, 
         /*
         *   SSMA warning messages:
         *   O2SS0356: Conversion from NUMBER datatype can cause data loss.
         */

         @NOFFTIME float(53), 
         /*
         *   SSMA warning messages:
         *   O2SS0356: Conversion from NUMBER datatype can cause data loss.
         */

         @NTRAFFICFEE float(53), 
         /*
         *   SSMA warning messages:
         *   O2SS0356: Conversion from NUMBER datatype can cause data loss.
         */

         @RTNCODE float(53)

      BEGIN TRY

         EXECUTE ssma_oracle.db_fn_check_init_package 'HRP', 'EHRPHRA3_PKG'

         /*    iCnt        INTEGER;*/
         BEGIN

            BEGIN TRY

               /* 
               *   SSMA error messages:
               *   O2SS0241: Aggregate functions with parameter expressions that contain aggregates or subqueries cannot be converted.

               SELECT @NOFFTIME = sum(A.OTM_HRS), @NTRAFFICFEE = sum(A.TRAFFIC_FEE)
               FROM 
                  (
                     SELECT isnull(sum(
                        CASE 
                           WHEN HRA_OFFREC.ITEM_TYPE = 'A' OR isnull(HRA_OFFREC.ITEM_TYPE, 'A') IS NULL THEN HRA_OFFREC.OTM_HRS
                           ELSE HRA_OFFREC.OTM_HRS * -1
                        END), 0) AS OTM_HRS, isnull(sum(
                        (
                           SELECT isnull(HR_CODEDTL.CODE_VALUE, 0)
                           FROM HRP.HR_CODEDTL
                           WHERE HR_CODEDTL.CODE_TYPE = 'HRA40' AND HR_CODEDTL.CODE_NO = HRA_OFFREC.TRAFFIC_FEE
                        )), 0) AS TRAFFIC_FEE
                     FROM HRP.HRA_OFFREC
                     WHERE 
                        HRA_OFFREC.EMP_NO = @SEMPNO AND 
                        HRA_OFFREC.TRN_YM = @STRNYM AND 
                        ssma_oracle.to_char_date(HRA_OFFREC.START_DATE, 'YYYY-MM-DD') BETWEEN '2026-03-01' AND '2026-03-30'/* 提前結算*/ AND 
                        HRA_OFFREC.STATUS = 'Y' AND 
                        HRA_OFFREC.ORG_BY = @SORGANTYPE
                      UNION ALL
                     /* 
                     *   SSMA error messages:
                     *   O2SS0241: Aggregate functions with parameter expressions that contain aggregates or subqueries cannot be converted.

                     SELECT isnull(sum(HRA_OTMSIGN.OTM_HRS), 0) AS OTM_HRS, isnull(sum(
                        (
                           SELECT isnull(HR_CODEDTL$2.CODE_VALUE, 0)
                           FROM HRP.HR_CODEDTL  AS HR_CODEDTL$2
                           WHERE HR_CODEDTL$2.CODE_TYPE = 'HRA40' AND HR_CODEDTL$2.CODE_NO = HRA_OTMSIGN.TRAFFIC_FEE
                        )), 0) AS TRAFFIC_FEE
                     FROM HRP.HRA_OTMSIGN
                     WHERE 
                        HRA_OTMSIGN.EMP_NO = @SEMPNO AND 
                        HRA_OTMSIGN.TRN_YM1 = @STRNYM AND 
                        HRA_OTMSIGN.OTM_NO LIKE ('OTM%') AND 
                        ssma_oracle.to_char_date(HRA_OTMSIGN.START_DATE, 'YYYY-MM-DD') BETWEEN '2026-03-01' AND '2026-03-30'/* 提前結算*/ AND 
                        HRA_OTMSIGN.STATUS = 'Y' AND 
                        HRA_OTMSIGN.ORG_BY = @SORGANTYPE
                     */


                  )  AS A
               */



               DECLARE
                  @db_null_statement int

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

                     SET @NOFFTIME = 0

                     SET @NTRAFFICFEE = 0

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

         /*------------------------ONCALL交通費--------------------------*/
         IF @NTRAFFICFEE = 0
            GOTO CONTINUE_FOREACH2

         IF HRP.EHRPHRA3_PKG$F_HRA4010_INS(
            @STRNYM, 
            @STRNSHIFT, 
            @SEMPNO, 
            '3051', 
            @NTRAFFICFEE, 
            'N', 
            @SORGANTYPE, 
            @SUPDATEBY) <> 0
            BEGIN

               SET @RTNCODE = 2/* 交通費INSERT失敗*/

               GOTO CONTINUE_FOREACH2

            END

         DECLARE
            @db_null_statement$2 int

         CONTINUE_FOREACH2:

         DECLARE
            @db_null_statement$3 int

         /*------------------------交通費--------------------------*/
         DECLARE
            @db_null_statement$4 int

         SET @return_value_argument = @RTNCODE

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
               @db_null_statement$5 int

         END

      END CATCH

   END
GO
BEGIN TRY
    EXEC sp_addextendedproperty
        N'MS_SSMA_SOURCE', N'HRP.EHRPHRA3_PKG.f_hra4010_H',
        N'SCHEMA', N'hrp',
        N'PROCEDURE', N'EHRPHRA3_PKG$F_HRA4010_H$IMPL'
END TRY
BEGIN CATCH
    IF (@@TRANCOUNT > 0) ROLLBACK
    PRINT ERROR_MESSAGE()
END CATCH
GO
