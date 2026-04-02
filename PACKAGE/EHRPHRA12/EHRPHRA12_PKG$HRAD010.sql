
USE MIS
GO
 IF NOT EXISTS(SELECT * FROM sys.schemas WHERE [name] = N'hrp')      
     EXEC (N'CREATE SCHEMA hrp')                                   
 GO                                                               

USE MIS
GO
IF  EXISTS (SELECT * FROM sys.objects so JOIN sys.schemas sc ON so.schema_id = sc.schema_id WHERE so.name = N'EHRPHRA12_PKG$HRAD010'  AND sc.name=N'hrp'  AND type in (N'P',N'PC'))
 DROP PROCEDURE [hrp].[EHRPHRA12_PKG$HRAD010]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE HRP.EHRPHRA12_PKG$HRAD010  
   @P_EMP_NO varchar(max),
   @P_START_DATE varchar(max),
   @P_START_TIME varchar(max),
   @P_END_DATE varchar(max),
   @P_END_TIME varchar(max),
   @P_OTM_HRS varchar(max),
   /*
   *   SSMA warning messages:
   *   O2SS0356: Conversion from NUMBER datatype can cause data loss.
   */

   @RTNCODE float(53)  OUTPUT
AS 
   BEGIN

      SET @RTNCODE = NULL

      EXECUTE ssma_oracle.db_check_init_package 'HRP', 'EHRPHRA12_PKG'

      DECLARE
         @SEMPNO varchar(20) = @P_EMP_NO, 
         @SSTART varchar(20) = ISNULL(@P_START_DATE, '') + ISNULL(@P_START_TIME, ''), 
         @SEND varchar(20) = ISNULL(@P_END_DATE, '') + ISNULL(@P_END_TIME, ''), 
         @SSTART1 varchar(20), 
         @SEND1 varchar(20), 
         @ICNT int, 
         /*
         *   SSMA warning messages:
         *   O2SS0356: Conversion from NUMBER datatype can cause data loss.
         */

         @CVAC_V float(53), 
         /*
         *   SSMA warning messages:
         *   O2SS0356: Conversion from NUMBER datatype can cause data loss.
         */

         @CVAC_SUP float(53)

      SET @RTNCODE = 0

      /*
      *   SSMA warning messages:
      *   O2SS0425: Dateadd operation may cause bad performance.
      */

      /*因 BETWEEN 會比較前後值,故 START + 1 分鐘 , END -1 分鐘 來跳過*/
      SET @SSTART1 = ssma_oracle.to_char_date(ssma_oracle.dateadd(0.000695, ssma_oracle.to_date2(@SSTART, 'YYYY-MM-DDHH24MI')), 'YYYY-MM-DDHH24MI')

      /*
      *   SSMA warning messages:
      *   O2SS0425: Dateadd operation may cause bad performance.
      */

      SET @SEND1 = ssma_oracle.to_char_date(ssma_oracle.dateadd(-0.000694, ssma_oracle.to_date2(@SEND, 'YYYY-MM-DDHH24MI')), 'YYYY-MM-DDHH24MI')

      
      /*
      *   ----------------------- 積休單 -------------------------
      *   (檢核在資料庫中除''不准''以外的積休單申請時間是否重疊)
      *   現有的補休單時間介於新積休單
      */
      BEGIN

         BEGIN TRY
            SELECT @ICNT = count_big(*)
            FROM HRP.HRA_DSUPREC
            WHERE 
               HRA_DSUPREC.EMP_NO = @SEMPNO AND 
               ((@SSTART1 BETWEEN ISNULL(ssma_oracle.to_char_date(HRA_DSUPREC.START_DATE, 'YYYY-MM-DD'), '') + ISNULL(HRA_DSUPREC.START_TIME, '') AND ISNULL(ssma_oracle.to_char_date(HRA_DSUPREC.END_DATE, 'YYYY-MM-DD'), '') + ISNULL(HRA_DSUPREC.END_TIME, '')) OR (@SEND1 BETWEEN ISNULL(ssma_oracle.to_char_date(HRA_DSUPREC.START_DATE, 'YYYY-MM-DD'), '') + ISNULL(HRA_DSUPREC.START_TIME, '') AND ISNULL(ssma_oracle.to_char_date(HRA_DSUPREC.END_DATE, 'YYYY-MM-DD'), '') + ISNULL(HRA_DSUPREC.END_TIME, ''))) AND 
               HRA_DSUPREC.STATUS <> 'N'
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
         /*新補休單介於現有的積休單時間*/
         BEGIN

            BEGIN TRY
               SELECT @ICNT = count_big(*)
               FROM HRP.HRA_DSUPREC
               WHERE 
                  HRA_DSUPREC.EMP_NO = @SEMPNO AND 
                  ((ISNULL(ssma_oracle.to_char_date(HRA_DSUPREC.START_DATE, 'YYYY-MM-DD'), '') + ISNULL(HRA_DSUPREC.START_TIME, '') BETWEEN @SSTART1 AND @SEND1) OR (ISNULL(ssma_oracle.to_char_date(HRA_DSUPREC.END_DATE, 'YYYY-MM-DD'), '') + ISNULL(HRA_DSUPREC.END_TIME, '') BETWEEN @SSTART1 AND @SEND1)) AND 
                  HRA_DSUPREC.STATUS <> 'N'
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

      IF @ICNT > 0
         BEGIN

            SET @RTNCODE = 1

            GOTO CONTINUE_FOREACH1

         END

      /*ERROR CODE 16 請特休＋補休不可超過10天*/
      BEGIN

         BEGIN TRY
            SELECT @CVAC_V = isnull(sum(isnull(HRA_DEVCREC.VAC_DAYS, 0) * 8 + isnull(HRA_DEVCREC.VAC_HRS, 0)), 0)
            FROM HRP.HRA_DEVCREC
            WHERE 
               HRA_DEVCREC.VAC_TYPE = 'V' AND 
               HRA_DEVCREC.EMP_NO = @SEMPNO AND 
               HRA_DEVCREC.STATUS = 'Y' AND 
               ssma_oracle.to_char_date(HRA_DEVCREC.START_DATE, 'YYYY-MM') = substring(@P_START_DATE, 1, 7)
         END TRY

         BEGIN CATCH
            BEGIN
               SET @CVAC_V = 0
            END
         END CATCH

      END

      BEGIN

         BEGIN TRY
            SELECT @CVAC_SUP = isnull(sum(isnull(HRA_DSUPREC.OTM_HRS, 0)), 0)
            FROM HRP.HRA_DSUPREC
            WHERE 
               HRA_DSUPREC.EMP_NO = @SEMPNO AND 
               HRA_DSUPREC.STATUS = 'Y' AND 
               ssma_oracle.to_char_date(HRA_DSUPREC.START_DATE, 'YYYY-MM') = substring(@P_START_DATE, 1, 7)
         END TRY

         BEGIN CATCH
            BEGIN
               SET @CVAC_SUP = 0
            END
         END CATCH

      END

      IF @CVAC_V + @CVAC_SUP + CAST(@P_OTM_HRS AS float(53)) > 80
         BEGIN

            SET @RTNCODE = 16

            GOTO CONTINUE_FOREACH1

         END

      DECLARE
         @db_null_statement int

      CONTINUE_FOREACH1:

      DECLARE
         @db_null_statement$2 int

   END
GO
BEGIN TRY
    EXEC sp_addextendedproperty
        N'MS_SSMA_SOURCE', N'HRP.EHRPHRA12_PKG.hraD010',
        N'SCHEMA', N'hrp',
        N'PROCEDURE', N'EHRPHRA12_PKG$HRAD010'
END TRY
BEGIN CATCH
    IF (@@TRANCOUNT > 0) ROLLBACK
    PRINT ERROR_MESSAGE()
END CATCH
GO
