
USE MIS
GO
 IF NOT EXISTS(SELECT * FROM sys.schemas WHERE [name] = N'hrp')      
     EXEC (N'CREATE SCHEMA hrp')                                   
 GO                                                               

USE MIS
GO
IF  EXISTS (SELECT * FROM sys.objects so JOIN sys.schemas sc ON so.schema_id = sc.schema_id WHERE so.name = N'EHRPHRA3_PKG$HRA4010'  AND sc.name=N'hrp'  AND type in (N'P',N'PC'))
 DROP PROCEDURE [hrp].[EHRPHRA3_PKG$HRA4010]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE HRP.EHRPHRA3_PKG$HRA4010  
   @TRNYM_IN varchar(max),
   @TRNSHIFT_IN varchar(max),
   @UPDATEBY_IN varchar(max),
   @ORGTYPE_IN varchar(max),
   /*
   *   SSMA warning messages:
   *   O2SS0356: Conversion from NUMBER datatype can cause data loss.
   */

   @RTNCODE float(53)  OUTPUT
AS 
   BEGIN

      DECLARE
         @STRNYM varchar(7) = @TRNYM_IN, 
         @STRNSHIFT varchar(2) = @TRNSHIFT_IN, 
         @SORGANTYPE varchar(10) = @ORGTYPE_IN, 
         @SUPDATEBY varchar(20) = @UPDATEBY_IN, 
         @SSTARTDAY varchar(2), 
         @SENDDAY varchar(2), 
         @DSTRARTDATE datetime2(0), 
         @DENDDATE datetime2(0), 
         @SEMPNO varchar(20), 
         @SDEPTNO varchar(10), 
         @ICNT int, 
         /*
         *   SSMA warning messages:
         *   O2SS0356: Conversion from NUMBER datatype can cause data loss.
         */

         @NSALARY float(53), 
         @SDAY varchar(2), 
         @I int

      BEGIN TRY

         SET @RTNCODE = NULL

         EXECUTE ssma_oracle.db_check_init_package 'HRP', 'EHRPHRA3_PKG'

         SET @RTNCODE = 0

         /*紀錄此時段是否開始執行*/
         INSERT HRP.HRA_ATTDTL_AUDIT(
            TRN_YM, 
            TASK, 
            SHIFT_NO, 
            CREATED_BY, 
            CREATION_DATE, 
            LAST_UPDATED_BY, 
            LAST_UPDATE_DATE, 
            ORG_BY, 
            ORGAN_TYPE)
            VALUES (
               @STRNYM, 
               'hra4010', 
               @STRNSHIFT, 
               @SUPDATEBY, 
               sysdatetime(), 
               @SUPDATEBY, 
               sysdatetime(), 
               @SORGANTYPE, 
               @SORGANTYPE)

         IF @@TRANCOUNT > 0
            COMMIT TRANSACTION 

         /*清檔*/
         DELETE HRP.HRA_ATTDTL
         WHERE 
            HRA_ATTDTL.TRN_YM = @STRNYM AND 
            HRA_ATTDTL.TRN_SHIFT = @STRNSHIFT AND 
            HRA_ATTDTL.ORGAN_TYPE = @SORGANTYPE

         IF @@TRANCOUNT > 0
            COMMIT TRANSACTION 

         BEGIN

            DECLARE
               /* 
               *   SSMA error messages:
               *   O2SS0005: The source datatype 'SP1' was not recognized.
               */

               @SAVEPOINT varchar(8000)

            BEGIN TRY
               SELECT @SSTARTDAY = HRA_TRNSHIFT.START_DAY, @SENDDAY = HRA_TRNSHIFT.END_DAY
               FROM HRP.HRA_TRNSHIFT
               WHERE HRA_TRNSHIFT.TRN_SHIFT = @STRNSHIFT
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

                     SET @SSTARTDAY = NULL

                     SET @SENDDAY = NULL

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

         
         /*
         *    SPHINX 95.06.12 提前結算取最後日期要註記掉
         *   IF sTrnShift = 'A3' THEN
         *            sEndDay := TO_CHAR(LAST_DAY(TO_DATE(sTrnYm || '-01', 'YYYY-MM-DD')), 'DD');
         *          END IF;
         */
         IF 
            @SSTARTDAY IS NULL OR 
            @SSTARTDAY = '' OR 
            @SENDDAY IS NULL OR 
            @SENDDAY = ''
            BEGIN

               SET @RTNCODE = 2

               GOTO CONTINUE_FOREACH1

            END

         /* 結轉日期*/
         SET @DSTRARTDATE = ssma_oracle.to_date2(ISNULL(@STRNYM, '') + '-' + ISNULL(@SSTARTDAY, ''), 'YYYY-MM-DD')

         SET @DENDDATE = ssma_oracle.to_date2(ISNULL(@STRNYM, '') + '-' + ISNULL(@SENDDAY, ''), 'YYYY-MM-DD')

         DECLARE
             CURSOR1 CURSOR LOCAL FOR 
               SELECT HRA_CLASSSCH.EMP_NO
               FROM HRP.HRA_CLASSSCH
               WHERE HRA_CLASSSCH.SCH_YM = @STRNYM AND HRA_CLASSSCH.ORG_BY = @SORGANTYPE/*103.01.13 機構*/

         OPEN CURSOR1

         WHILE 1 = 1
         
            BEGIN

               FETCH CURSOR1
                   INTO @SEMPNO

               /*
               *   SSMA warning messages:
               *   O2SS0113: The value of @@FETCH_STATUS might be changed by previous FETCH operations on other cursors, if the cursors are used simultaneously.
               */

               IF @@FETCH_STATUS <> 0
                  BREAK

               /*未打卡次數統計*/
               IF HRP.EHRPHRA3_PKG$F_HRA4010_B(
                  @STRNYM, 
                  @STRNSHIFT, 
                  @SEMPNO, 
                  @DSTRARTDATE, 
                  @DENDDATE, 
                  @SORGANTYPE, 
                  @SUPDATEBY) <> 0
                  BEGIN

                     SET @RTNCODE = 0

                     GOTO CONTINUE_FOREACH1

                  END

               
               /*
               *    曠職次數統計
               *   IF f_hra4010_C(sTrnYm, sTrnShift, sEmpNo
               *                          , dStrartDate, dEndDate, sOrganType , sUpdateBy) <> 0 THEN
               *    2026.01 曠職次數統計
               */
               IF HRP.EHRPHRA3_PKG$F_HRA4010_C_MIN(
                  @STRNYM, 
                  @STRNSHIFT, 
                  @SEMPNO, 
                  @DSTRARTDATE, 
                  @DENDDATE, 
                  @SORGANTYPE, 
                  @SUPDATEBY) <> 0
                  BEGIN

                     SET @RTNCODE = 4

                     GOTO CONTINUE_FOREACH1

                  END

               /* 遲到分數統計(for 義大 以次數計)*/
               IF HRP.EHRPHRA3_PKG$F_HRA4010_D(
                  @STRNYM, 
                  @STRNSHIFT, 
                  @SEMPNO, 
                  @DSTRARTDATE, 
                  @DENDDATE, 
                  @SORGANTYPE, 
                  @SUPDATEBY) <> 0
                  BEGIN

                     SET @RTNCODE = 0

                     GOTO CONTINUE_FOREACH1

                  END

               /* 早退分數統計(for 義大 以次數計)*/
               IF HRP.EHRPHRA3_PKG$F_HRA4010_E(
                  @STRNYM, 
                  @STRNSHIFT, 
                  @SEMPNO, 
                  @DSTRARTDATE, 
                  @DENDDATE, 
                  @SORGANTYPE, 
                  @SUPDATEBY) <> 0
                  BEGIN

                     SET @RTNCODE = 6

                     GOTO CONTINUE_FOREACH1

                  END

               IF @STRNSHIFT IN (  'A3' )
                  BEGIN

                     /*請假統計結轉*/
                     IF HRP.EHRPHRA3_PKG$F_HRA4010_A(
                        @STRNYM, 
                        @STRNSHIFT, 
                        @SEMPNO, 
                        @SORGANTYPE, 
                        @SUPDATEBY) <> 0
                        BEGIN

                           SET @RTNCODE = 0

                           GOTO CONTINUE_FOREACH1

                        END

                     /*超時積假時數統計*/
                     IF HRP.EHRPHRA3_PKG$F_HRA4010_F(
                        @STRNYM, 
                        @STRNSHIFT, 
                        @SEMPNO, 
                        @SORGANTYPE, 
                        @SUPDATEBY) <> 0
                        BEGIN

                           SET @RTNCODE = 0

                           GOTO CONTINUE_FOREACH1

                        END

                     
                     /*
                     *   批OFF時數統計(積借休時數統計)
                     *    ONCALL交通費待人事公告後再由細統計算 94.12.26 SPHINX
                     */
                     IF HRP.EHRPHRA3_PKG$F_HRA4010_H(
                        @STRNYM, 
                        @STRNSHIFT, 
                        @SEMPNO, 
                        @SORGANTYPE, 
                        @SUPDATEBY) <> 0
                        BEGIN

                           SET @RTNCODE = 10

                           GOTO CONTINUE_FOREACH1

                        END

                     /* 加班時數統計*/
                     IF HRP.EHRPHRA3_PKG$F_HRA4010_J(
                        @STRNYM, 
                        @STRNSHIFT, 
                        @SEMPNO, 
                        @SORGANTYPE, 
                        @SUPDATEBY) <> 0
                        BEGIN

                           SET @RTNCODE = 12

                           GOTO CONTINUE_FOREACH1

                        END

                  END

               DECLARE
                   CURSOR2 CURSOR LOCAL FOR 
                     SELECT DISTINCT HRA_ATTDTL.EMP_NO, HRE_EMPBAS.DEPT_NO
                     FROM HRP.HRA_ATTDTL, HRP.HRE_EMPBAS
                     WHERE 
                        (HRA_ATTDTL.EMP_NO = HRE_EMPBAS.EMP_NO) AND 
                        ((HRA_ATTDTL.TRN_YM = @STRNYM) AND (HRA_ATTDTL.TRN_SHIFT = @STRNSHIFT)) AND 
                        (HRA_ATTDTL.ORGAN_TYPE = @SORGANTYPE) AND 
                        (HRA_ATTDTL.ORGAN_TYPE = HRE_EMPBAS.ORGAN_TYPE)

               /*出勤統計主檔*/
               OPEN CURSOR2

               WHILE 1 = 1
               
                  BEGIN

                     FETCH CURSOR2
                         INTO @SEMPNO, @SDEPTNO

                     /*
                     *   SSMA warning messages:
                     *   O2SS0113: The value of @@FETCH_STATUS might be changed by previous FETCH operations on other cursors, if the cursors are used simultaneously.
                     */

                     IF @@FETCH_STATUS <> 0
                        BREAK

                     BEGIN

                        BEGIN TRY
                           SELECT @NSALARY = isnull(sum(HRS_ACNTDTL.SAL_AMT), 0)
                           FROM HRP.HRS_ACNTMST, HRP.HRS_ACNTDTL
                           WHERE 
                              HRS_ACNTMST.EMP_NO = HRS_ACNTDTL.EMP_NO AND 
                              HRS_ACNTMST.EMP_ID = HRS_ACNTDTL.EMP_ID AND 
                              HRS_ACNTMST.EMP_NO = @SEMPNO AND 
                              HRS_ACNTMST.MAIN_FLAG = 'Y' AND 
                              HRS_ACNTMST.DISABLED = 'N' AND 
                              HRS_ACNTMST.ORGAN_TYPE = @SORGANTYPE
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
                              SET @NSALARY = 0
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

                     BEGIN

                        BEGIN TRY
                           SELECT @ICNT = count_big(*)
                           FROM HRP.HRA_ATTMST
                           WHERE 
                              HRA_ATTMST.TRN_YM = @STRNYM AND 
                              HRA_ATTMST.EMP_NO = @SEMPNO AND 
                              HRA_ATTMST.ORGAN_TYPE = @SORGANTYPE
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

                     IF @ICNT = 0
                        INSERT HRP.HRA_ATTMST(
                           TRN_YM, 
                           EMP_NO, 
                           DEPT_NO, 
                           SALARY, 
                           DISABLED, 
                           CREATED_BY, 
                           CREATION_DATE, 
                           LAST_UPDATED_BY, 
                           LAST_UPDATE_DATE, 
                           ORG_BY, 
                           ORGAN_TYPE)
                           VALUES (
                              @STRNYM, 
                              @SEMPNO, 
                              @SDEPTNO, 
                              @NSALARY, 
                              'N', 
                              @SUPDATEBY, 
                              sysdatetime(), 
                              @SUPDATEBY, 
                              sysdatetime(), 
                              @SORGANTYPE, 
                              @SORGANTYPE)
                     ELSE 
                        UPDATE HRP.HRA_ATTMST
                           SET 
                              DEPT_NO = @SDEPTNO
                        WHERE 
                           HRA_ATTMST.TRN_YM = @STRNYM AND 
                           HRA_ATTMST.EMP_NO = @SEMPNO AND 
                           HRA_ATTMST.ORGAN_TYPE = @SORGANTYPE

                     DECLARE
                        @db_null_statement int

                  END

               CLOSE CURSOR2

               DEALLOCATE CURSOR2

               DECLARE
                  @db_null_statement$2 int

            END

         CLOSE CURSOR1

         DEALLOCATE CURSOR1

         IF @@TRANCOUNT > 0
            COMMIT TRANSACTION 

         DECLARE
            @db_null_statement$3 int

         SET @RTNCODE = 0

         DECLARE
            @db_null_statement$4 int

         CONTINUE_FOREACH1:

         DECLARE
            @db_null_statement$5 int

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

         BEGIN

            IF @@TRANCOUNT > 0
               ROLLBACK WORK 

            SET @RTNCODE = ssma_oracle.db_error_sqlcode(@exceptionidentifier$4, @errornumber$4)

         END

      END CATCH

   END
GO
BEGIN TRY
    EXEC sp_addextendedproperty
        N'MS_SSMA_SOURCE', N'HRP.EHRPHRA3_PKG.hra4010',
        N'SCHEMA', N'hrp',
        N'PROCEDURE', N'EHRPHRA3_PKG$HRA4010'
END TRY
BEGIN CATCH
    IF (@@TRANCOUNT > 0) ROLLBACK
    PRINT ERROR_MESSAGE()
END CATCH
GO
