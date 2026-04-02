
USE MIS
GO
 IF NOT EXISTS(SELECT * FROM sys.schemas WHERE [name] = N'hrp')      
     EXEC (N'CREATE SCHEMA hrp')                                   
 GO                                                               

USE MIS
GO
IF  EXISTS (SELECT * FROM sys.objects so JOIN sys.schemas sc ON so.schema_id = sc.schema_id WHERE so.name = N'EHRPHRAFUNC_PKG$F_CHECK_CADSIGN$IMPL'  AND sc.name=N'hrp'  AND type in (N'P',N'PC'))
 DROP PROCEDURE [hrp].[EHRPHRAFUNC_PKG$F_CHECK_CADSIGN$IMPL]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE HRP.EHRPHRAFUNC_PKG$F_CHECK_CADSIGN$IMPL  
   @EMPNO_IN varchar(max),
   @SHIFTNO_IN varchar(max),
   @CLASSCODE_IN varchar(max),
   @CHECKIN_IN varchar(max),
   @CARDTIME_IN varchar(max),
   /*
   *   SSMA warning messages:
   *   O2SS0356: Conversion from NUMBER datatype can cause data loss.
   */

   @return_value_argument float(53)  OUTPUT
AS 
   BEGIN

      EXECUTE ssma_oracle.db_fn_check_init_package 'HRP', 'EHRPHRAFUNC_PKG'

      DECLARE
         @SCHECKIN varchar(1) = @CHECKIN_IN, 
         /*
         *   SSMA warning messages:
         *   O2SS0356: Conversion from NUMBER datatype can cause data loss.
         */

         @RECHECK_IN float(53), 
         /*
         *   SSMA warning messages:
         *   O2SS0356: Conversion from NUMBER datatype can cause data loss.
         */

         @RECHECK_OUT float(53), 
         /*
         *   SSMA warning messages:
         *   O2SS0356: Conversion from NUMBER datatype can cause data loss.
         */

         @RECHECK_TM float(53), 
         /*
         *   SSMA warning messages:
         *   O2SS0356: Conversion from NUMBER datatype can cause data loss.
         */

         @OUTPUT float(53)

      BEGIN

         BEGIN TRY
            SELECT @RECHECK_IN = substring(HRA_CLASSDTL.CHKIN_WKTM, 1, 2) * 60 + CAST(substring(HRA_CLASSDTL.CHKIN_WKTM, 3, 2) AS float(53)), @RECHECK_OUT = substring(HRA_CLASSDTL.CHKOUT_WKTM, 1, 2) * 60 + CAST(substring(HRA_CLASSDTL.CHKOUT_WKTM, 3, 2) AS float(53)), @RECHECK_TM = substring(@CARDTIME_IN, 1, 2) * 60 + CAST(substring(@CARDTIME_IN, 3, 2) AS float(53))
            FROM HRP.HRA_CLASSDTL
            WHERE HRA_CLASSDTL.CLASS_CODE = @CLASSCODE_IN AND HRA_CLASSDTL.SHIFT_NO = @SHIFTNO_IN
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

                  SET @RECHECK_IN = -1

                  SET @RECHECK_OUT = -1

                  SET @RECHECK_TM = -1

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

      IF 
         @RECHECK_IN >= 0 AND 
         @RECHECK_OUT >= 0 AND 
         @RECHECK_TM >= 0
         IF @SCHECKIN = 'Y'
            /*簽入*/
            IF @RECHECK_IN < 480 AND @RECHECK_TM >= 960
               /*上班時間0800前,且打卡大於1600(跨夜提早上班)*/
               IF (1440 - @RECHECK_TM) + @RECHECK_IN >= 1
                  BEGIN

                     SET @OUTPUT = 1

                     GOTO CONTINUE_FOREACH1

                  END
               ELSE 
                  BEGIN
                     IF (1440 - @RECHECK_TM) + @RECHECK_IN < 1
                        SET @OUTPUT = 0
                  END
            ELSE 
               IF @RECHECK_IN - @RECHECK_TM >= 1
                  BEGIN

                     SET @OUTPUT = 1

                     GOTO CONTINUE_FOREACH1

                  END
               ELSE 
                  BEGIN
                     IF @RECHECK_IN - @RECHECK_TM < 1
                        SET @OUTPUT = 0
                  END
         ELSE 
            /*簽出*/
            IF @RECHECK_OUT > 960 AND @RECHECK_TM <= 420
               /*下班時間1600後,且打卡小於0700(跨夜延後下班)*/
               IF @RECHECK_TM + (1440 - @RECHECK_OUT) >= 1
                  BEGIN

                     SET @OUTPUT = 1

                     GOTO CONTINUE_FOREACH1

                  END
               ELSE 
                  BEGIN
                     IF @RECHECK_TM + (1440 - @RECHECK_OUT) < 1
                        SET @OUTPUT = 0
                  END
            ELSE 
               IF @RECHECK_OUT <= 480 AND @RECHECK_TM >= 840
                  /*下班時間0800前,且打卡大於1400*/
                  DECLARE
                     @db_null_statement int/*是提早下班不是延後下班的狀況,非異常*/
               ELSE 
                  IF @RECHECK_TM - @RECHECK_OUT >= 1
                     BEGIN

                        SET @OUTPUT = 1

                        GOTO CONTINUE_FOREACH1

                     END
                  ELSE 
                     BEGIN
                        IF @RECHECK_TM - @RECHECK_OUT < 1
                           SET @OUTPUT = 0
                     END

      DECLARE
         @db_null_statement$2 int

      CONTINUE_FOREACH1:

      DECLARE
         @db_null_statement$3 int

      SET @return_value_argument = @OUTPUT

      RETURN 

   END
GO
BEGIN TRY
    EXEC sp_addextendedproperty
        N'MS_SSMA_SOURCE', N'HRP.EHRPHRAFUNC_PKG.f_Check_Cadsign',
        N'SCHEMA', N'hrp',
        N'PROCEDURE', N'EHRPHRAFUNC_PKG$F_CHECK_CADSIGN$IMPL'
END TRY
BEGIN CATCH
    IF (@@TRANCOUNT > 0) ROLLBACK
    PRINT ERROR_MESSAGE()
END CATCH
GO
