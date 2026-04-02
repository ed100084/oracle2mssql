
USE MIS
GO
 IF NOT EXISTS(SELECT * FROM sys.schemas WHERE [name] = N'hrp')      
     EXEC (N'CREATE SCHEMA hrp')                                   
 GO                                                               

USE MIS
GO
IF  EXISTS (SELECT * FROM sys.objects so JOIN sys.schemas sc ON so.schema_id = sc.schema_id WHERE so.name = N'EHRPHRA12_PKG$CHECKCLASS$IMPL'  AND sc.name=N'hrp'  AND type in (N'P',N'PC'))
 DROP PROCEDURE [hrp].[EHRPHRA12_PKG$CHECKCLASS$IMPL]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE HRP.EHRPHRA12_PKG$CHECKCLASS$IMPL  
   @P_EMP_NO varchar(max),
   @P_START_DATE varchar(max),
   @P_START_TIME varchar(max),
   @P_END_DATE varchar(max),
   @P_END_TIME varchar(max),
   @ORGANTYPE_IN varchar(max),
   /*
   *   SSMA warning messages:
   *   O2SS0356: Conversion from NUMBER datatype can cause data loss.
   */

   @return_value_argument float(53)  OUTPUT
AS 
   BEGIN

      EXECUTE ssma_oracle.db_fn_check_init_package 'HRP', 'EHRPHRA12_PKG'

      DECLARE
         @SCLASSKIND varchar(3), 
         @ICNT int, 
         @RTNCODE numeric(1), 
         @SORGANTYPE varchar(10) = @ORGANTYPE_IN, 
         @ISREST_1 varchar(4), 
         @ISREST_2 varchar(4), 
         @ISREST_3 varchar(4), 
         @IEREST_1 varchar(4), 
         @IEREST_2 varchar(4), 
         @IEREST_3 varchar(4)

      SET @SCLASSKIND = HRP.EHRPHRAFUNC_PKG$F_GETCLASSKIND(@P_EMP_NO, ssma_oracle.to_date2(@P_START_DATE, 'yyyy-mm-dd'), @SORGANTYPE)

      IF @SCLASSKIND = 'N/A'
         BEGIN

            SET @RTNCODE = 7

            GOTO CONTINUE_FOREACH1

         END
      ELSE 
         IF @SCLASSKIND IN ( 'ZZ', 'ZX', 'ZY', 'ZQ' )
            GOTO CONTINUE_FOREACH2
         ELSE 
            BEGIN

               BEGIN

                  BEGIN TRY
                     SELECT @ICNT = count_big(*)
                     FROM HRP.HRA_CLASSDTL
                     WHERE 
                        HRA_CLASSDTL.CLASS_CODE = @SCLASSKIND AND 
                        ((@P_START_TIME >= HRA_CLASSDTL.CHKIN_WKTM AND @P_START_TIME < HRA_CLASSDTL.CHKOUT_WKTM) OR (@P_END_TIME > HRA_CLASSDTL.CHKIN_WKTM AND @P_END_TIME < HRA_CLASSDTL.CHKOUT_WKTM) OR (HRA_CLASSDTL.CHKIN_WKTM > @P_START_TIME AND HRA_CLASSDTL.CHKIN_WKTM < @P_END_TIME)) AND 
                        HRA_CLASSDTL.SHIFT_NO <> '4'
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
                        GOTO CONTINUE_FOREACH2
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

               IF @ICNT > 0
                  BEGIN

                     BEGIN

                        BEGIN TRY
                           SELECT 
                              @ISREST_1 = isnull(
                                 (
                                    SELECT HRA_CLASSDTL.START_REST
                                    FROM HRP.HRA_CLASSDTL
                                    WHERE HRA_CLASSDTL.CLASS_CODE = @SCLASSKIND AND HRA_CLASSDTL.SHIFT_NO = '1'
                                 ), '0'), 
                              @IEREST_1 = isnull(
                                 (
                                    SELECT HRA_CLASSDTL$2.END_REST
                                    FROM HRP.HRA_CLASSDTL  AS HRA_CLASSDTL$2
                                    WHERE HRA_CLASSDTL$2.CLASS_CODE = @SCLASSKIND AND HRA_CLASSDTL$2.SHIFT_NO = '1'
                                 ), '0'), 
                              @ISREST_2 = isnull(
                                 (
                                    SELECT HRA_CLASSDTL$3.START_REST
                                    FROM HRP.HRA_CLASSDTL  AS HRA_CLASSDTL$3
                                    WHERE HRA_CLASSDTL$3.CLASS_CODE = @SCLASSKIND AND HRA_CLASSDTL$3.SHIFT_NO = '2'
                                 ), '0'), 
                              @IEREST_2 = isnull(
                                 (
                                    SELECT HRA_CLASSDTL$4.END_REST
                                    FROM HRP.HRA_CLASSDTL  AS HRA_CLASSDTL$4
                                    WHERE HRA_CLASSDTL$4.CLASS_CODE = @SCLASSKIND AND HRA_CLASSDTL$4.SHIFT_NO = '2'
                                 ), '0'), 
                              @ISREST_3 = isnull(
                                 (
                                    SELECT HRA_CLASSDTL$5.START_REST
                                    FROM HRP.HRA_CLASSDTL  AS HRA_CLASSDTL$5
                                    WHERE HRA_CLASSDTL$5.CLASS_CODE = @SCLASSKIND AND HRA_CLASSDTL$5.SHIFT_NO = '3'
                                 ), '0'), 
                              @IEREST_3 = isnull(
                                 (
                                    SELECT HRA_CLASSDTL$6.END_REST
                                    FROM HRP.HRA_CLASSDTL  AS HRA_CLASSDTL$6
                                    WHERE HRA_CLASSDTL$6.CLASS_CODE = @SCLASSKIND AND HRA_CLASSDTL$6.SHIFT_NO = '3'
                                 ), '0')
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
                              BEGIN

                                 SET @RTNCODE = 7

                                 GOTO CONTINUE_FOREACH2

                              END
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

                     IF (@P_START_TIME BETWEEN @ISREST_1 AND @IEREST_1 AND @P_END_TIME BETWEEN @ISREST_1 AND @IEREST_1) OR (@P_START_TIME BETWEEN @ISREST_2 AND @IEREST_2 AND @P_END_TIME BETWEEN @ISREST_2 AND @IEREST_2) OR (@P_START_TIME BETWEEN @ISREST_3 AND @IEREST_3 AND @P_END_TIME BETWEEN @ISREST_3 AND @IEREST_3)
                        GOTO CONTINUE_FOREACH2

                     SET @RTNCODE = 8

                     GOTO CONTINUE_FOREACH1

                  END

            END

      DECLARE
         @db_null_statement int

      CONTINUE_FOREACH2:

      DECLARE
         @db_null_statement$2 int

      IF @P_START_DATE <> @P_END_DATE
         BEGIN

            
            /*
            *   sClassKind := ehrphrafunc_pkg.f_getClassKind (p_emp_no , to_date(p_end_date,'yyyy-mm-dd'),SOrganType);
            *   20180809 108978 若用end_date會導致抓到後一天的班別，導致出現判斷是否?上班時間出錯
            */
            SET @SCLASSKIND = HRP.EHRPHRAFUNC_PKG$F_GETCLASSKIND(@P_EMP_NO, ssma_oracle.to_date2(@P_START_DATE, 'yyyy-mm-dd'), @SORGANTYPE)

            
            /*
            *   IF sClassKind IN ('ZZ') THEN 20161219 新增班別 ZX,ZY
            *   20180725 108978 增加ZQ
            */
            IF @SCLASSKIND IN ( 'ZZ', 'ZX', 'ZY', 'ZQ' )
               BEGIN

                  SET @RTNCODE = 0

                  GOTO CONTINUE_FOREACH1

               END
            ELSE 
               IF @SCLASSKIND = 'N/A'
                  BEGIN

                     SET @RTNCODE = 7

                     GOTO CONTINUE_FOREACH1

                  END
               ELSE 
                  BEGIN

                     BEGIN

                        BEGIN TRY
                           SELECT @ICNT = count_big(*)
                           FROM HRP.HRA_CLASSDTL
                           WHERE HRA_CLASSDTL.CLASS_CODE = @SCLASSKIND AND ((@P_START_TIME >= HRA_CLASSDTL.CHKIN_WKTM AND @P_START_TIME < HRA_CLASSDTL.CHKOUT_WKTM) OR (@P_END_TIME > HRA_CLASSDTL.CHKIN_WKTM AND @P_END_TIME < HRA_CLASSDTL.CHKOUT_WKTM) OR (HRA_CLASSDTL.CHKIN_WKTM > @P_START_TIME AND HRA_CLASSDTL.CHKIN_WKTM < @P_END_TIME))
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
                              GOTO CONTINUE_FOREACH1
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

                     IF @ICNT > 0
                        BEGIN

                           IF (@P_START_TIME BETWEEN @ISREST_1 AND @IEREST_1 AND @P_END_TIME BETWEEN @ISREST_1 AND @IEREST_1) OR (@P_START_TIME BETWEEN @ISREST_2 AND @IEREST_2 AND @P_END_TIME BETWEEN @ISREST_2 AND @IEREST_2) OR (@P_START_TIME BETWEEN @ISREST_3 AND @IEREST_3 AND @P_END_TIME BETWEEN @ISREST_3 AND @IEREST_3)
                              GOTO CONTINUE_FOREACH1

                           SET @RTNCODE = 8

                        END

                  END

         END
      ELSE 
         SET @RTNCODE = 0

      DECLARE
         @db_null_statement$3 int

      CONTINUE_FOREACH1:

      DECLARE
         @db_null_statement$4 int

      SET @return_value_argument = @RTNCODE

      RETURN 

   END
GO
BEGIN TRY
    EXEC sp_addextendedproperty
        N'MS_SSMA_SOURCE', N'HRP.EHRPHRA12_PKG.checkClass',
        N'SCHEMA', N'hrp',
        N'PROCEDURE', N'EHRPHRA12_PKG$CHECKCLASS$IMPL'
END TRY
BEGIN CATCH
    IF (@@TRANCOUNT > 0) ROLLBACK
    PRINT ERROR_MESSAGE()
END CATCH
GO
