
USE MIS
GO
 IF NOT EXISTS(SELECT * FROM sys.schemas WHERE [name] = N'hrp')      
     EXEC (N'CREATE SCHEMA hrp')                                   
 GO                                                               

USE MIS
GO
IF  EXISTS (SELECT * FROM sys.objects so JOIN sys.schemas sc ON so.schema_id = sc.schema_id WHERE so.name = N'EHRPHRA3_PKG$F_HRA4010_A$IMPL'  AND sc.name=N'hrp'  AND type in (N'P',N'PC'))
 DROP PROCEDURE [hrp].[EHRPHRA3_PKG$F_HRA4010_A$IMPL]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE HRP.EHRPHRA3_PKG$F_HRA4010_A$IMPL  
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
         @SVACTYPE varchar(10), 
         @SATTCODE varchar(10), 
         /*
         *   SSMA warning messages:
         *   O2SS0356: Conversion from NUMBER datatype can cause data loss.
         */

         @NVACDAYS float(53), 
         /*
         *   SSMA warning messages:
         *   O2SS0356: Conversion from NUMBER datatype can cause data loss.
         */

         @NVACHRS float(53), 
         /*
         *   SSMA warning messages:
         *   O2SS0356: Conversion from NUMBER datatype can cause data loss.
         */

         @NHOLIHRS float(53), 
         /*
         *   SSMA warning messages:
         *   O2SS0356: Conversion from NUMBER datatype can cause data loss.
         */

         @NEVCTOTALHRS float(53), 
         /*
         *   SSMA warning messages:
         *   O2SS0356: Conversion from NUMBER datatype can cause data loss.
         */

         @NOFFVACDAYS float(53), 
         /*
         *   SSMA warning messages:
         *   O2SS0356: Conversion from NUMBER datatype can cause data loss.
         */

         @NOFFVACHRS float(53), 
         /*
         *   SSMA warning messages:
         *   O2SS0356: Conversion from NUMBER datatype can cause data loss.
         */

         @NOFFTOTALHRS float(53), 
         /*
         *   SSMA warning messages:
         *   O2SS0356: Conversion from NUMBER datatype can cause data loss.
         */

         @NTOTALHRS float(53), 
         @ICNT int = 0, 
         @SSALCODE varchar(10), 
         @IVALUE int = 0

      BEGIN TRY

         EXECUTE ssma_oracle.db_fn_check_init_package 'HRP', 'EHRPHRA3_PKG'

         DECLARE
             CURSOR1 CURSOR LOCAL FOR 
               SELECT HRA_VCRLMST.VAC_TYPE
               FROM HRP.HRA_VCRLMST

         OPEN CURSOR1

         WHILE 1 = 1
         
            BEGIN

               FETCH CURSOR1
                   INTO @SVACTYPE

               /*
               *   SSMA warning messages:
               *   O2SS0113: The value of @@FETCH_STATUS might be changed by previous FETCH operations on other cursors, if the cursors are used simultaneously.
               */

               IF @@FETCH_STATUS <> 0
                  BREAK

               DECLARE
                  @db_null_statement int

               /* 電子請假時數*/
               BEGIN

                  BEGIN TRY
                     SELECT @NVACDAYS = sum(HRA_EVCREC.VAC_DAYS), @NVACHRS = sum(HRA_EVCREC.VAC_HRS), @NHOLIHRS = sum(HRA_EVCREC.HOLI_HRS)
                     FROM HRP.HRA_EVCREC
                     WHERE 
                        HRA_EVCREC.EMP_NO = @SEMPNO AND 
                        HRA_EVCREC.VAC_TYPE = @SVACTYPE AND 
                        ssma_oracle.to_char_date(HRA_EVCREC.START_DATE, 'YYYY-MM') = @STRNYM AND 
                        HRA_EVCREC.STATUS = 'Y' AND 
                        ssma_oracle.to_char_date(HRA_EVCREC.START_DATE, 'yyyy-mm-dd') BETWEEN '2026-03-01' AND '2026-03-30'/* 提前結算*/ AND 
                        HRA_EVCREC.ORG_BY = @SORGANTYPE
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

                           SET @NVACDAYS = 0

                           SET @NVACHRS = 0

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

               IF @NVACDAYS IS NULL
                  SET @NVACDAYS = 0

               IF @NVACHRS IS NULL
                  SET @NVACHRS = 0

               SET @NEVCTOTALHRS = @NVACDAYS * 8 + @NVACHRS

               
               /*
               *   100.07.27 產假,流產假 扣除假日時數
               *   2020.02 與人資確認 ,須扣薪的產假不用排除非出勤日
               */
               IF (@SVACTYPE = 'J') AND (@NEVCTOTALHRS > 0)
                  SET @NEVCTOTALHRS = @NVACDAYS * 8 + @NVACHRS - @NHOLIHRS

               SET @NTOTALHRS = @NEVCTOTALHRS

               IF @NTOTALHRS = 0
                  GOTO CONTINUE_FOREACH1

               BEGIN

                  BEGIN TRY
                     SELECT @SATTCODE = HRA_ATTRUL.ATT_CODE
                     FROM HRP.HRA_ATTRUL
                     WHERE HRA_ATTRUL.ORG_CODE = @SVACTYPE AND HRA_ATTRUL.ATT_KIND = '2'/* att_kind = 2  請假*/
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
                        SET @SATTCODE = NULL
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

               IF @SATTCODE IS NULL OR @SATTCODE = ''
                  GOTO CONTINUE_FOREACH1

               IF HRP.EHRPHRA3_PKG$F_HRA4010_INS(
                  @STRNYM, 
                  @STRNSHIFT, 
                  @SEMPNO, 
                  @SATTCODE, 
                  @NTOTALHRS, 
                  'H', 
                  @SORGANTYPE, 
                  @SUPDATEBY) <> 0
                  SET @ICNT = 1/*  請假時數INSERT失敗*/

               DECLARE
                  @db_null_statement$2 int

               CONTINUE_FOREACH1:

               DECLARE
                  @db_null_statement$3 int

            END

         CLOSE CURSOR1

         DEALLOCATE CURSOR1

         DECLARE
            @db_null_statement$4 int

         
         /*
         *   --------------------- 404全勤 405不休假 -----------------------
         *    94.11.07 SPHINX  薪資結構有此津貼才寫入
         */
         BEGIN

            BEGIN TRY
               SELECT @IVALUE = count_big(*)
               FROM HRP.HRS_ACNTDTL
               WHERE 
                  HRS_ACNTDTL.EMP_NO = @SEMPNO AND 
                  HRS_ACNTDTL.DISABLED = 'N' AND 
                  HRS_ACNTDTL.SAL_CODE IN ( 'AA0G', 'AA0F' ) AND 
                  HRS_ACNTDTL.SAL_AMT > 0 AND 
                  HRS_ACNTDTL.ORGAN_TYPE = @SORGANTYPE
            END TRY

            BEGIN CATCH
               BEGIN
                  SET @IVALUE = 0
               END
            END CATCH

         END

         IF @IVALUE > 0
            BEGIN

               IF HRP.EHRPHRA3_PKG$F_HRA4010_INS(
                  @STRNYM, 
                  @STRNSHIFT, 
                  @SEMPNO, 
                  '4040', 
                  1, 
                  'T', 
                  @SORGANTYPE, 
                  @SUPDATEBY) <> 0
                  BEGIN

                     SET @ICNT = 1/*  請假時數INSERT失敗*/

                     GOTO CONTINUE_FOREACH2

                  END

               IF HRP.EHRPHRA3_PKG$F_HRA4010_INS(
                  @STRNYM, 
                  @STRNSHIFT, 
                  @SEMPNO, 
                  '4050', 
                  1, 
                  'T', 
                  @SORGANTYPE, 
                  @SUPDATEBY) <> 0
                  SET @ICNT = 1/*  請假時數INSERT失敗*/

            END
         /* END iValue =0*/

         DECLARE
            @db_null_statement$5 int

         CONTINUE_FOREACH2:

         DECLARE
            @db_null_statement$6 int

         SET @return_value_argument = @ICNT

         /*--------------------- 404全勤 405不休假 -----------------------*/
         RETURN 

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

         BEGIN

            IF @@TRANCOUNT > 0
               ROLLBACK WORK 

            SET @return_value_argument = ssma_oracle.db_error_sqlcode(@exceptionidentifier$3, @errornumber$3)

            RETURN 

            DECLARE
               @db_null_statement$7 int

         END

      END CATCH

   END
GO
BEGIN TRY
    EXEC sp_addextendedproperty
        N'MS_SSMA_SOURCE', N'HRP.EHRPHRA3_PKG.f_hra4010_A',
        N'SCHEMA', N'hrp',
        N'PROCEDURE', N'EHRPHRA3_PKG$F_HRA4010_A$IMPL'
END TRY
BEGIN CATCH
    IF (@@TRANCOUNT > 0) ROLLBACK
    PRINT ERROR_MESSAGE()
END CATCH
GO
