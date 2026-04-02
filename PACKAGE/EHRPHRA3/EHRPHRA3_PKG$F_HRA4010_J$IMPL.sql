
USE MIS
GO
 IF NOT EXISTS(SELECT * FROM sys.schemas WHERE [name] = N'hrp')      
     EXEC (N'CREATE SCHEMA hrp')                                   
 GO                                                               

USE MIS
GO
IF  EXISTS (SELECT * FROM sys.objects so JOIN sys.schemas sc ON so.schema_id = sc.schema_id WHERE so.name = N'EHRPHRA3_PKG$F_HRA4010_J$IMPL'  AND sc.name=N'hrp'  AND type in (N'P',N'PC'))
 DROP PROCEDURE [hrp].[EHRPHRA3_PKG$F_HRA4010_J$IMPL]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE HRP.EHRPHRA3_PKG$F_HRA4010_J$IMPL  
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

         @RTNCODE float(53), 
         /*
         *   SSMA warning messages:
         *   O2SS0356: Conversion from NUMBER datatype can cause data loss.
         */

         @NFEE float(53), 
         /*
         *   SSMA warning messages:
         *   O2SS0356: Conversion from NUMBER datatype can cause data loss.
         */

         @NFEECOUNT float(53)

      BEGIN TRY

         EXECUTE ssma_oracle.db_fn_check_init_package 'HRP', 'EHRPHRA3_PKG'

         DECLARE
            @CUR_GETOTMSIGN$EMP_NO varchar(max), 
            /*
            *   SSMA warning messages:
            *   O2SS0356: Conversion from NUMBER datatype can cause data loss.
            */

            @CUR_GETOTMSIGN$OTM_FEE float(53), 
            /*
            *   SSMA warning messages:
            *   O2SS0356: Conversion from NUMBER datatype can cause data loss.
            */

            @CUR_GETOTMSIGN$ONCALL_FEE float(53)

         DECLARE
             CUR_OTMSIGN CURSOR LOCAL FOR 
               /*20231212 by108482 先每月彙總後再加總*/
               SELECT A.EMP_NO, sum(A.OTM_FEE) AS OTM_FEE, sum(A.ONCALL_FEE) AS ONCALL_FEE
               FROM 
                  (
                     SELECT HRA_OTMSIGN.EMP_NO, ssma_oracle.to_char_date(HRA_OTMSIGN.START_DATE, 'yyyy-mm') AS expr, ceiling(isnull(sum(HRA_OTMSIGN.OTM_FEE), 0)) AS OTM_FEE, ceiling(isnull(sum(HRA_OTMSIGN.ONCALL_FEE), 0)) AS ONCALL_FEE
                     FROM HRP.HRA_OTMSIGN
                     WHERE 
                        HRA_OTMSIGN.STATUS = 'Y' AND 
                        HRA_OTMSIGN.OTM_NO LIKE 'OTM%' AND 
                        HRA_OTMSIGN.EMP_NO = @SEMPNO AND 
                        HRA_OTMSIGN.TRN_YM = @STRNYM AND 
                        HRA_OTMSIGN.ORG_BY = @SORGANTYPE
                     GROUP BY HRA_OTMSIGN.EMP_NO, ssma_oracle.to_char_date(HRA_OTMSIGN.START_DATE, 'yyyy-mm')
                  )  AS A
               GROUP BY A.EMP_NO

         OPEN CUR_OTMSIGN

         WHILE 1 = 1
         
            BEGIN

               FETCH CUR_OTMSIGN
                   INTO @CUR_GETOTMSIGN$EMP_NO, @CUR_GETOTMSIGN$OTM_FEE, @CUR_GETOTMSIGN$ONCALL_FEE

               /*
               *   SSMA warning messages:
               *   O2SS0113: The value of @@FETCH_STATUS might be changed by previous FETCH operations on other cursors, if the cursors are used simultaneously.
               */

               IF @@FETCH_STATUS <> 0
                  BREAK

               /*------------------------加班時數--------------------------*/
               SET @RTNCODE = 0

               IF @CUR_GETOTMSIGN$ONCALL_FEE > 0
                  BEGIN
                     IF HRP.EHRPHRA3_PKG$F_HRA4010_INS(
                        @STRNYM, 
                        @STRNSHIFT, 
                        @SEMPNO, 
                        '3041', 
                        @CUR_GETOTMSIGN$ONCALL_FEE, 
                        'N', 
                        @SORGANTYPE, 
                        @SUPDATEBY) <> 0
                        BEGIN

                           SET @RTNCODE = 1/* 加班時數INSERT失敗*/

                           GOTO CONTINUE_FOREACH2

                        END
                  END

               /* 免稅*/
               IF @CUR_GETOTMSIGN$OTM_FEE = 0
                  GOTO CONTINUE_FOREACH1

               IF HRP.EHRPHRA3_PKG$F_HRA4010_INS(
                  @STRNYM, 
                  @STRNSHIFT, 
                  @SEMPNO, 
                  '3031', 
                  @CUR_GETOTMSIGN$OTM_FEE, 
                  'N', 
                  @SORGANTYPE, 
                  @SUPDATEBY) <> 0
                  BEGIN

                     SET @RTNCODE = 1/* 加班時數INSERT失敗*/

                     GOTO CONTINUE_FOREACH2

                  END

               CONTINUE_FOREACH1:

               DECLARE
                  @db_null_statement int

               
               /*
               *   ------------------------加班時數--------------------------
               *   ------------------------交通費--------------------------
               */
               DECLARE
                  @db_null_statement$2 int

               CONTINUE_FOREACH2:

               DECLARE
                  @db_null_statement$3 int/*------------------------交通費--------------------------*/

            END

         CLOSE CUR_OTMSIGN

         DEALLOCATE CUR_OTMSIGN

         DECLARE
            @db_null_statement$4 int

         SET @return_value_argument = @RTNCODE

         RETURN 

         DECLARE
            @db_null_statement$5 int

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

         BEGIN

            IF @@TRANCOUNT > 0
               ROLLBACK WORK 

            SET @RTNCODE = ssma_oracle.db_error_sqlcode(@exceptionidentifier, @errornumber)

            SET @return_value_argument = @RTNCODE

            RETURN 

            DECLARE
               @db_null_statement$6 int

         END

      END CATCH

   END
GO
BEGIN TRY
    EXEC sp_addextendedproperty
        N'MS_SSMA_SOURCE', N'HRP.EHRPHRA3_PKG.f_hra4010_J',
        N'SCHEMA', N'hrp',
        N'PROCEDURE', N'EHRPHRA3_PKG$F_HRA4010_J$IMPL'
END TRY
BEGIN CATCH
    IF (@@TRANCOUNT > 0) ROLLBACK
    PRINT ERROR_MESSAGE()
END CATCH
GO
