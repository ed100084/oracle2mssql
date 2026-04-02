
USE MIS
GO
 IF NOT EXISTS(SELECT * FROM sys.schemas WHERE [name] = N'hrp')      
     EXEC (N'CREATE SCHEMA hrp')                                   
 GO                                                               

USE MIS
GO
IF  EXISTS (SELECT * FROM sys.objects so JOIN sys.schemas sc ON so.schema_id = sc.schema_id WHERE so.name = N'EHRPHRA12_PKG$CHECK_DEPUTY$IMPL'  AND sc.name=N'hrp'  AND type in (N'P',N'PC'))
 DROP PROCEDURE [hrp].[EHRPHRA12_PKG$CHECK_DEPUTY$IMPL]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE HRP.EHRPHRA12_PKG$CHECK_DEPUTY$IMPL  
   @P_EMP_NO varchar(max),
   @P_START_DATE varchar(max),
   @P_START_TIME varchar(max),
   @P_END_DATE varchar(max),
   @P_END_TIME varchar(max),
   /*
   *   SSMA warning messages:
   *   O2SS0356: Conversion from NUMBER datatype can cause data loss.
   */

   @return_value_argument float(53)  OUTPUT
AS 
   BEGIN

      EXECUTE ssma_oracle.db_fn_check_init_package 'HRP', 'EHRPHRA12_PKG'

      DECLARE
         @SEMPNO varchar(20) = @P_EMP_NO, 
         @SSTARTDATE varchar(10) = @P_START_DATE, 
         @SSTARTTIME varchar(7) = @P_START_TIME, 
         @SENDDATE varchar(10) = @P_END_DATE, 
         @SENDTIME varchar(7) = @P_END_TIME, 
         @ICNT int, 
         /*
         *   SSMA warning messages:
         *   O2SS0356: Conversion from NUMBER datatype can cause data loss.
         */

         @RTNCODE float(53)

      SET @RTNCODE = 0

      /* 有無此人*/
      IF @SEMPNO <> 'MIS'
         BEGIN

            /* TEST用*/
            BEGIN

               BEGIN TRY
                  SELECT @ICNT = count_big(*)
                  FROM HRP.HRE_EMPBAS
                  WHERE HRE_EMPBAS.EMP_NO = @SEMPNO AND HRE_EMPBAS.DISABLED = 'N'
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
               BEGIN

                  SET @RTNCODE = 1

                  GOTO CONTINUE_FOREACH1

               END

         END

      
      /*
      *   
      *         -- 假單
      *         BEGIN
      *             SELECT count(*)
      *               INTO iCnt
      *               FROM hra_evcrec
      *              WHERE ((to_char(start_date, 'YYYY-MM-DD') || start_time between
      *                    sStartDate || sStartTime and sEndDate || sEndTime)
      *                 OR (to_char(end_date, 'YYYY-MM-DD') || end_time between
      *                    sStartDate || sStartTime and sEndDate || sEndTime))
      *                AND EMP_NO = sEmpNo AND STATUS NOT IN ('N','D');
      *          EXCEPTION
      *          WHEN OTHERS THEN
      *               iCnt := 0;
      *          END;
      *   
      *          IF iCnt > 0 THEN
      *           RtnCode := 2;
      *           GOTO Continue_ForEach1;
      *          END IF;
      *   
      *          -- 新假卡介於db 日期
      *          IF iCnt = 0 THEN
      *             BEGIN
      *                SELECT count(*)
      *                  INTO iCnt
      *                  FROM hra_evcrec
      *                 WHERE ((sStartDate || sStartTime between to_char(start_date, 'YYYY-MM-DD') || start_time
      *                                                      and to_char(end_date, 'YYYY-MM-DD') || end_time)
      *                    OR  (sEndDate   || sEndTime   between to_char(start_date, 'YYYY-MM-DD') || start_time
      *                                                      and to_char(end_date, 'YYYY-MM-DD') || end_time))
      *                   AND EMP_NO = sEmpNo AND STATUS NOT IN ('N','D');
      *             EXCEPTION
      *             WHEN OTHERS THEN
      *                  iCnt := 0;
      *             END;
      *          END IF;
      *   
      *          IF iCnt > 0 THEN
      *           RtnCode := 2;
      *           GOTO Continue_ForEach1;
      *          END IF;
      *   
      *         -- 借休
      *   
      *         -- 補休
      *   
      *
      */
      DECLARE
         @db_null_statement int

      CONTINUE_FOREACH1:

      DECLARE
         @db_null_statement$2 int

      SET @return_value_argument = @RTNCODE

      RETURN 

   END
GO
BEGIN TRY
    EXEC sp_addextendedproperty
        N'MS_SSMA_SOURCE', N'HRP.EHRPHRA12_PKG.check_deputy',
        N'SCHEMA', N'hrp',
        N'PROCEDURE', N'EHRPHRA12_PKG$CHECK_DEPUTY$IMPL'
END TRY
BEGIN CATCH
    IF (@@TRANCOUNT > 0) ROLLBACK
    PRINT ERROR_MESSAGE()
END CATCH
GO
