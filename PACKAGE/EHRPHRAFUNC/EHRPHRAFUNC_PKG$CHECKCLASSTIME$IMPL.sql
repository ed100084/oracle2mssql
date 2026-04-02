
USE MIS
GO
 IF NOT EXISTS(SELECT * FROM sys.schemas WHERE [name] = N'hrp')      
     EXEC (N'CREATE SCHEMA hrp')                                   
 GO                                                               

USE MIS
GO
IF  EXISTS (SELECT * FROM sys.objects so JOIN sys.schemas sc ON so.schema_id = sc.schema_id WHERE so.name = N'EHRPHRAFUNC_PKG$CHECKCLASSTIME$IMPL'  AND sc.name=N'hrp'  AND type in (N'P',N'PC'))
 DROP PROCEDURE [hrp].[EHRPHRAFUNC_PKG$CHECKCLASSTIME$IMPL]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE HRP.EHRPHRAFUNC_PKG$CHECKCLASSTIME$IMPL  
   @P_EMP_NO varchar(max),
   @P_START_DATE varchar(max),
   @P_START_TIME varchar(max),
   @P_END_DATE varchar(max),
   @P_END_TIME varchar(max),
   @P_CLASS_CODE varchar(max),
   @P_LAST_CLASS_CODE varchar(max),
   /*
   *   SSMA warning messages:
   *   O2SS0356: Conversion from NUMBER datatype can cause data loss.
   */

   @return_value_argument float(53)  OUTPUT
AS 
   BEGIN

      EXECUTE ssma_oracle.db_fn_check_init_package 'HRP', 'EHRPHRAFUNC_PKG'

      DECLARE
         @SCLASSCODE varchar(3), 
         @SLASTCLASSKIND varchar(3), 
         @ICNT int, 
         @RTNCODE numeric(1), 
         @ICHKIN_WKTM varchar(4), 
         @ICHKOUT_WKTM varchar(4), 
         @ISTART_REST varchar(4), 
         @IEND_REST varchar(4), 
         @ISTARTTIME datetime2(0), 
         @IENDTIME datetime2(0)

      SET @RTNCODE = 0

      DECLARE
          CURSOR1 CURSOR LOCAL FOR 
            SELECT HRA_CLASSDTL.CHKIN_WKTM, HRA_CLASSDTL.CHKOUT_WKTM, HRA_CLASSDTL.START_REST, HRA_CLASSDTL.END_REST
            FROM HRP.HRA_CLASSDTL
            WHERE HRA_CLASSDTL.CLASS_CODE = @P_CLASS_CODE AND HRA_CLASSDTL.SHIFT_NO <> '4'

      OPEN CURSOR1

      WHILE 1 = 1
      
         BEGIN

            FETCH CURSOR1
                INTO @ICHKIN_WKTM, @ICHKOUT_WKTM, @ISTART_REST, @IEND_REST

            /*
            *   SSMA warning messages:
            *   O2SS0113: The value of @@FETCH_STATUS might be changed by previous FETCH operations on other cursors, if the cursors are used simultaneously.
            */

            IF @@FETCH_STATUS <> 0
               BREAK

            /*是否為跨夜班*/
            BEGIN

               BEGIN TRY

                  /* 
                  *   SSMA error messages:
                  *   O2SS0404: ROWID column can not be converted in this context because the referenced table has no triggers and ROWID column will not be generated.

                  SELECT @ICNT = count_big(ROWID)
                  FROM HRP.HRA_CLASSDTL
                  WHERE 
                     HRA_CLASSDTL.CHKIN_WKTM > 
                     CASE 
                        WHEN HRA_CLASSDTL.CHKOUT_WKTM = '0000' THEN '2400'
                        ELSE HRA_CLASSDTL.CHKOUT_WKTM
                     END AND 
                     HRA_CLASSDTL.SHIFT_NO <> '4' AND 
                     HRA_CLASSDTL.CLASS_CODE = @P_CLASS_CODE
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

            IF @ICNT > 0
               /*如果為跨夜班,下班日期+1*/
               SET @IENDTIME = DATEADD(D, 1, ssma_oracle.to_date2(ISNULL(@P_START_DATE, '') + ISNULL(@ICHKOUT_WKTM, ''), 'yyyy-mm-ddHH24MI'))
            ELSE 
               SET @IENDTIME = ssma_oracle.to_date2(ISNULL(@P_START_DATE, '') + ISNULL(@ICHKOUT_WKTM, ''), 'yyyy-mm-ddHH24MI')

            /*ini*/
            SET @ICNT = 0

            /*是否為0000上班*/
            BEGIN

               BEGIN TRY

                  /* 
                  *   SSMA error messages:
                  *   O2SS0404: ROWID column can not be converted in this context because the referenced table has no triggers and ROWID column will not be generated.

                  SELECT @ICNT = count_big(ROWID)
                  FROM HRP.HRA_CLASSDTL
                  WHERE 
                     HRA_CLASSDTL.CHKIN_WKTM = '0000' AND 
                     HRA_CLASSDTL.CHKIN_FLAG = 'Y' AND 
                     HRA_CLASSDTL.CLASS_CODE = @P_CLASS_CODE
                  */



                  DECLARE
                     @db_null_statement$2 int

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

            
            /*
            *   IF  iCnt > 0 THEN
            *         iSTARTTIME := TO_DATE( p_start_date ||  iCHKIN_WKTM ,'yyyy-mm-ddHH24MI')+1;
            *         iENDTIME := TO_DATE( p_start_date ||  iCHKOUT_WKTM ,'yyyy-mm-ddHH24MI')+1;
            *         ELSE
            *         iSTARTTIME := TO_DATE( p_start_date ||  iCHKIN_WKTM ,'yyyy-mm-ddHH24MI');
            *         END IF;
            *   20190110 調整同checkClassTime2的處理 by108482
            */
            IF @ICNT > 0
               SET @ISTARTTIME = DATEADD(D, 1, ssma_oracle.to_date2(ISNULL(@P_START_DATE, '') + ISNULL(@ICHKIN_WKTM, ''), 'yyyy-mm-ddHH24MI'))
            ELSE 
               BEGIN

                  SET @ISTARTTIME = ssma_oracle.to_date2(ISNULL(@P_START_DATE, '') + ISNULL(@ICHKIN_WKTM, ''), 'yyyy-mm-ddHH24MI')

                  SET @IENDTIME = ssma_oracle.to_date2(ISNULL(@P_START_DATE, '') + ISNULL(@ICHKOUT_WKTM, ''), 'yyyy-mm-ddHH24MI')

               END

            /*
            *   SSMA warning messages:
            *   O2SS0425: Dateadd operation may cause bad performance.
            *   O2SS0425: Dateadd operation may cause bad performance.
            *   O2SS0425: Dateadd operation may cause bad performance.
            */

            /*比較上班時間*/
            IF ((ssma_oracle.dateadd(0.0001, ssma_oracle.to_date2(ISNULL(@P_START_DATE, '') + ISNULL(@P_START_TIME, ''), 'yyyy-mm-ddHH24MI')) BETWEEN @ISTARTTIME AND @IENDTIME) OR (ssma_oracle.dateadd(-0.0001, ssma_oracle.to_date2(ISNULL(@P_END_DATE, '') + ISNULL(@P_END_TIME, ''), 'yyyy-mm-ddHH24MI')) BETWEEN @ISTARTTIME AND @IENDTIME)) OR (ssma_oracle.dateadd(0.0001, @ISTARTTIME) BETWEEN ssma_oracle.to_date2(ISNULL(@P_START_DATE, '') + ISNULL(@P_START_TIME, ''), 'yyyy-mm-ddHH24MI') AND ssma_oracle.to_date2(ISNULL(@P_END_DATE, '') + ISNULL(@P_END_TIME, ''), 'yyyy-mm-ddHH24MI'))
               SET @RTNCODE = 1

            /*比較休息時間*/
            IF @RTNCODE > 0
               BEGIN
                  IF @ISTART_REST <> '0' AND @IEND_REST <> '0'
                     BEGIN
                        IF (@P_START_TIME BETWEEN @ISTART_REST AND @IEND_REST AND @P_END_TIME BETWEEN @ISTART_REST AND @IEND_REST)
                           SET @RTNCODE = 0
                     END
               END

         END

      CLOSE CURSOR1

      DEALLOCATE CURSOR1

      DECLARE
         @db_null_statement$3 int

      SET @return_value_argument = @RTNCODE

      RETURN 

   END
GO
BEGIN TRY
    EXEC sp_addextendedproperty
        N'MS_SSMA_SOURCE', N'HRP.EHRPHRAFUNC_PKG.CHECKCLASSTIME',
        N'SCHEMA', N'hrp',
        N'PROCEDURE', N'EHRPHRAFUNC_PKG$CHECKCLASSTIME$IMPL'
END TRY
BEGIN CATCH
    IF (@@TRANCOUNT > 0) ROLLBACK
    PRINT ERROR_MESSAGE()
END CATCH
GO
