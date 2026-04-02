
USE MIS
GO
 IF NOT EXISTS(SELECT * FROM sys.schemas WHERE [name] = N'hrp')      
     EXEC (N'CREATE SCHEMA hrp')                                   
 GO                                                               

USE MIS
GO
IF  EXISTS (SELECT * FROM sys.objects so JOIN sys.schemas sc ON so.schema_id = sc.schema_id WHERE so.name = N'EHRPHRA12_PKG$CHECKONCALL$IMPL'  AND sc.name=N'hrp'  AND type in (N'P',N'PC'))
 DROP PROCEDURE [hrp].[EHRPHRA12_PKG$CHECKONCALL$IMPL]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE HRP.EHRPHRA12_PKG$CHECKONCALL$IMPL  
   @P_EMP_NO varchar(max),
   @P_START_DATE varchar(max),
   @P_START_TIME varchar(max),
   @P_END_DATE varchar(max),
   @P_START_DATE_TMP varchar(max),
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
         @ICNT2 int, 
         @RTNCODE numeric(1), 
         @SORGANTYPE varchar(10) = @ORGANTYPE_IN

      SET @RTNCODE = 0

      BEGIN

         BEGIN TRY
            SELECT @ICNT2 = count_big(*)
            FROM HRP.GESD_DORMMST
            WHERE GESD_DORMMST.EMP_NO = @P_EMP_NO AND GESD_DORMMST.USE_FLAG = 'Y'
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
               SET @ICNT2 = 0
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

      IF @ICNT2 > 0
         BEGIN

            SET @RTNCODE = 4/* 住宿不可申請OnCall*/

            GOTO CONTINUE_FOREACH1

         END

      
      /*
      *    IF p_start_date_tmp <> 'N/A' AND p_start_date_tmp <> p_start_date 代表 為跨夜申請
      *    故 ClassKin 要以 p_start_date_tmp 為基準
      */
      IF @P_START_DATE_TMP <> 'N/A' AND @P_START_DATE_TMP <> @P_START_DATE
         SET @SCLASSKIND = HRP.EHRPHRAFUNC_PKG$F_GETCLASSKIND(@P_EMP_NO, ssma_oracle.to_date2(@P_START_DATE_TMP, 'YYYY-MM-DD'), @SORGANTYPE)
      ELSE 
         SET @SCLASSKIND = HRP.EHRPHRAFUNC_PKG$F_GETCLASSKIND(@P_EMP_NO, ssma_oracle.to_date2(@P_START_DATE, 'YYYY-MM-DD'), @SORGANTYPE)

      BEGIN

         BEGIN TRY
            SELECT @ICNT2 = 
               CASE 
                  WHEN HRA_CLASSDTL.CHKIN_WKTM < HRA_CLASSDTL.CHKOUT_WKTM THEN 
                     CASE 
                        WHEN @P_START_TIME BETWEEN HRA_CLASSDTL.CHKIN_WKTM AND HRA_CLASSDTL.CHKOUT_WKTM THEN 1
                        ELSE 0
                     END
                  ELSE 
                     CASE 
                        WHEN (@P_START_TIME BETWEEN HRA_CLASSDTL.CHKIN_WKTM AND '2400') OR (@P_START_TIME BETWEEN '0000' AND HRA_CLASSDTL.CHKOUT_WKTM) THEN 1
                        ELSE 0
                     END
               END
            FROM HRP.HRA_CLASSDTL
            WHERE HRA_CLASSDTL.SHIFT_NO = '4' AND HRA_CLASSDTL.CLASS_CODE = @SCLASSKIND
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
               SET @ICNT2 = 0
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

      IF @ICNT2 = 0
         BEGIN

            BEGIN TRY
               SELECT @ICNT2 = count_big(*)
               FROM HRP.HR_CODEDTL
               WHERE 
                  HR_CODEDTL.CODE_TYPE = 'HRA79' AND 
                  HR_CODEDTL.CODE_NO = 
                  (
                     SELECT HRE_EMPBAS.DEPT_NO
                     FROM HRP.HRE_EMPBAS
                     WHERE HRE_EMPBAS.EMP_NO = @P_EMP_NO
                  ) AND 
                  HR_CODEDTL.DISABLED = 'N'
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
                  SET @ICNT2 = 0
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

      IF @ICNT2 = 0
         BEGIN

            SET @RTNCODE = 5/* 申請OnCall之積休日班別須為on call班*/

            GOTO CONTINUE_FOREACH1

         END

      
      /*
      *   -如果有上班打卡就驗證
      *    IF p_start_date_tmp <> 'N/A' AND p_start_date_tmp <> p_start_date 代表 為跨夜申請
      *    以 p_end_date 為基準
      */
      BEGIN

         BEGIN TRY
            IF @P_START_DATE_TMP <> 'N/A' AND @P_START_DATE_TMP <> @P_START_DATE
               SELECT @ICNT2 = count_big(*)
               FROM HRP.HRA_CADSIGN
               WHERE HRA_CADSIGN.EMP_NO = @P_EMP_NO AND ssma_oracle.to_char_date(HRA_CADSIGN.ATT_DATE, 'YYYY-MM-DD') = @P_START_DATE_TMP
            ELSE 
               SELECT @ICNT2 = count_big(*)
               FROM HRP.HRA_CADSIGN
               WHERE HRA_CADSIGN.EMP_NO = @P_EMP_NO AND ssma_oracle.to_char_date(HRA_CADSIGN.ATT_DATE, 'YYYY-MM-DD') = @P_START_DATE
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

            IF (@exceptionidentifier$4 LIKE N'ORA-00100%')
               SET @ICNT2 = 0
            ELSE 
               BEGIN
                  IF (@exceptionidentifier$4 IS NOT NULL)
                     BEGIN
                        IF @errornumber$4 = 59998
                           RAISERROR(59998, 16, 1, @exceptionidentifier$4)
                        ELSE 
                           RAISERROR(59999, 16, 1, @exceptionidentifier$4)
                     END
                  ELSE 
                     BEGIN
                        EXECUTE ssma_oracle.ssma_rethrowerror
                     END
               END

         END CATCH

      END

      IF @ICNT2 > 0
         BEGIN

            BEGIN

               BEGIN TRY
                  
                  /*
                  *    IF p_start_date_tmp <> 'N/A' AND p_start_date_tmp <> p_start_date 代表 為跨夜申請
                  *    故 ATT_DATE 要加 1 , 並以 p_end_date 為基準
                  */
                  IF @P_START_DATE_TMP <> 'N/A' AND @P_START_DATE_TMP <> @P_START_DATE
                     SELECT @ICNT2 = 
                        CASE 
                           WHEN ssma_oracle.datediff(ssma_oracle.to_date2(ISNULL(ssma_oracle.to_char_date(max(HRA_OTMSIGN.START_DATE), 'YYYY-MM-DD'), '') + ISNULL(max(HRA_OTMSIGN.START_TIME), ''), 'YYYY-MM-DD HH24MI'), ssma_oracle.to_date2(ISNULL(ssma_oracle.to_char_date(max(HRA_CADSIGN.ATT_DATE), 'YYYY-MM-DD'), '') + ISNULL(max(HRA_CADSIGN.CHKOUT_CARD), ''), 'YYYY-MM-DD HH24MI')) * 60 * 24 > 30 THEN 0
                           ELSE 1
                        END
                     FROM HRP.HRA_OTMSIGN, HRP.HRA_CADSIGN
                     WHERE 
                        HRA_CADSIGN.EMP_NO = HRA_OTMSIGN.EMP_NO AND 
                        ssma_oracle.to_char_date(DATEADD(D, 1, HRA_CADSIGN.ATT_DATE), 'YYYY-MM-DD') = ssma_oracle.to_char_date(HRA_OTMSIGN.START_DATE, 'YYYY-MM-DD') AND 
                        HRA_OTMSIGN.EMP_NO = @P_EMP_NO AND 
                        ssma_oracle.to_char_date(HRA_OTMSIGN.START_DATE, 'YYYY-MM-DD') = @P_END_DATE
                  ELSE 
                     SELECT @ICNT2 = 
                        CASE 
                           WHEN isnull(ssma_oracle.datediff(ssma_oracle.to_date2(ISNULL(ssma_oracle.to_char_date(max(HRA_OTMSIGN.START_DATE), 'YYYY-MM-DD'), '') + ISNULL(max(HRA_OTMSIGN.START_TIME), ''), 'YYYY-MM-DD HH24MI'), ssma_oracle.to_date2(ISNULL(ssma_oracle.to_char_date(max(HRA_CADSIGN.ATT_DATE), 'YYYY-MM-DD'), '') + ISNULL(max(HRA_CADSIGN.CHKOUT_CARD), ''), 'YYYY-MM-DD HH24MI')), 0) * 60 * 24 > 30 THEN 0
                           ELSE 1
                        END
                     FROM HRP.HRA_OTMSIGN, HRP.HRA_CADSIGN
                     WHERE 
                        HRA_CADSIGN.EMP_NO = HRA_OTMSIGN.EMP_NO AND 
                        ssma_oracle.to_char_date(HRA_CADSIGN.ATT_DATE, 'YYYY-MM-DD') = ssma_oracle.to_char_date(HRA_OTMSIGN.START_DATE, 'YYYY-MM-DD') AND 
                        HRA_OTMSIGN.EMP_NO = @P_EMP_NO AND 
                        ssma_oracle.to_char_date(HRA_OTMSIGN.START_DATE, 'YYYY-MM-DD') = @P_START_DATE
               END TRY

               BEGIN CATCH

                  DECLARE
                     @errornumber$5 int

                  SET @errornumber$5 = ERROR_NUMBER()

                  DECLARE
                     @errormessage$5 nvarchar(4000)

                  SET @errormessage$5 = ERROR_MESSAGE()

                  DECLARE
                     @exceptionidentifier$5 nvarchar(4000)

                  SELECT @exceptionidentifier$5 = ssma_oracle.db_error_get_oracle_exception_id(@errormessage$5, @errornumber$5)

                  IF (@exceptionidentifier$5 LIKE N'ORA-00100%')
                     SET @ICNT2 = 0
                  ELSE 
                     BEGIN
                        IF (@exceptionidentifier$5 IS NOT NULL)
                           BEGIN
                              IF @errornumber$5 = 59998
                                 RAISERROR(59998, 16, 1, @exceptionidentifier$5)
                              ELSE 
                                 RAISERROR(59999, 16, 1, @exceptionidentifier$5)
                           END
                        ELSE 
                           BEGIN
                              EXECUTE ssma_oracle.ssma_rethrowerror
                           END
                     END

               END CATCH

            END

            IF @ICNT2 = 0
               BEGIN

                  SET @RTNCODE = 0

                  GOTO CONTINUE_FOREACH1

               END
            ELSE 
               BEGIN

                  SET @RTNCODE = 6/* 申請OnCall失敗*/

                  GOTO CONTINUE_FOREACH1

               END

         END

      IF @RTNCODE <> 0
         GOTO CONTINUE_FOREACH1

      /*----------------------- 補休單 -------------------------*/
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
        N'MS_SSMA_SOURCE', N'HRP.EHRPHRA12_PKG.checkOncall',
        N'SCHEMA', N'hrp',
        N'PROCEDURE', N'EHRPHRA12_PKG$CHECKONCALL$IMPL'
END TRY
BEGIN CATCH
    IF (@@TRANCOUNT > 0) ROLLBACK
    PRINT ERROR_MESSAGE()
END CATCH
GO
