
USE MIS
GO
 IF NOT EXISTS(SELECT * FROM sys.schemas WHERE [name] = N'hrp')      
     EXEC (N'CREATE SCHEMA hrp')                                   
 GO                                                               

USE MIS
GO
IF  EXISTS (SELECT * FROM sys.objects so JOIN sys.schemas sc ON so.schema_id = sc.schema_id WHERE so.name = N'EHRPHRA12_PKG$HRAD030'  AND sc.name=N'hrp'  AND type in (N'P',N'PC'))
 DROP PROCEDURE [hrp].[EHRPHRA12_PKG$HRAD030]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE HRP.EHRPHRA12_PKG$HRAD030  
   @P_ITEM_TYPE varchar(max),
   @P_EMP_NO varchar(max),
   @P_START_DATE varchar(max),
   @P_START_TIME varchar(max),
   @P_END_DATE varchar(max),
   @P_END_TIME varchar(max),
   @P_OTM_HRS varchar(max),
   @ORGANTYPE_IN varchar(max),
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
         @SITEMTYPE varchar(1) = @P_ITEM_TYPE, 
         @SEMPNO varchar(20) = @P_EMP_NO, 
         @SSTART varchar(20) = ISNULL(@P_START_DATE, '') + ISNULL(@P_START_TIME, ''), 
         @SEND varchar(20) = ISNULL(@P_END_DATE, '') + ISNULL(@P_END_TIME, ''), 
         @SSTART1 varchar(20), 
         @SEND1 varchar(20), 
         @SOFFREST numeric(4, 1), 
         @ILEAVE varchar(10), 
         @MAXHRS numeric(5, 1), 
         @TEST1 numeric(5, 1), 
         @TEST2 numeric(5, 1), 
         @TEST3 numeric(5, 1), 
         @MAXHRS_TMP numeric(5, 1), 
         @ICNT int, 
         @ICOMEDATE varchar(10)

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
            FROM HRP.HRA_DOFFREC
            WHERE 
               HRA_DOFFREC.ITEM_TYPE = @SITEMTYPE AND 
               HRA_DOFFREC.EMP_NO = @SEMPNO AND 
               ((@SSTART1 BETWEEN ISNULL(ssma_oracle.to_char_date(HRA_DOFFREC.START_DATE, 'YYYY-MM-DD'), '') + ISNULL(HRA_DOFFREC.START_TIME, '') AND ISNULL(ssma_oracle.to_char_date(HRA_DOFFREC.END_DATE, 'YYYY-MM-DD'), '') + ISNULL(HRA_DOFFREC.END_TIME, '')) OR (@SEND1 BETWEEN ISNULL(ssma_oracle.to_char_date(HRA_DOFFREC.START_DATE, 'YYYY-MM-DD'), '') + ISNULL(HRA_DOFFREC.START_TIME, '') AND ISNULL(ssma_oracle.to_char_date(HRA_DOFFREC.END_DATE, 'YYYY-MM-DD'), '') + ISNULL(HRA_DOFFREC.END_TIME, ''))) AND 
               HRA_DOFFREC.STATUS <> 'N'
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
               FROM HRP.HRA_DOFFREC
               WHERE 
                  HRA_DOFFREC.ITEM_TYPE = @SITEMTYPE AND 
                  HRA_DOFFREC.EMP_NO = @SEMPNO AND 
                  ((ISNULL(ssma_oracle.to_char_date(HRA_DOFFREC.START_DATE, 'YYYY-MM-DD'), '') + ISNULL(HRA_DOFFREC.START_TIME, '') BETWEEN @SSTART1 AND @SEND1) OR (ISNULL(ssma_oracle.to_char_date(HRA_DOFFREC.END_DATE, 'YYYY-MM-DD'), '') + ISNULL(HRA_DOFFREC.END_TIME, '') BETWEEN @SSTART1 AND @SEND1)) AND 
                  HRA_DOFFREC.STATUS <> 'N'
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

      IF @SITEMTYPE = 'A'
         BEGIN

            BEGIN

               BEGIN TRY
                  SELECT @SOFFREST = sum(HRA_DOFFREC.OTM_HRS)
                  FROM HRP.HRA_DOFFREC
                  WHERE 
                     (HRA_DOFFREC.EMP_NO = @SEMPNO) AND 
                     HRA_DOFFREC.STATUS = 'Y' AND 
                     HRA_DOFFREC.DISABLED = 'N' AND 
                     HRA_DOFFREC.ITEM_TYPE = 'A' AND 
                     CONVERT(varchar(4), HRA_DOFFREC.START_DATE, 102) = CONVERT(varchar(4), sysdatetime(), 102)
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
                     SET @SOFFREST = 0
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

            BEGIN

               BEGIN TRY
                  SELECT @ICOMEDATE = ssma_oracle.to_char_date(HRA_DYEARVAC.COME_DATE, 'YYYY-MM-DD'), @ILEAVE = ssma_oracle.to_char_date(HRA_DYEARVAC.LEAVE_DATE, 'YYYY-MM-DD')
                  FROM HRP.HRA_DYEARVAC
                  WHERE (HRA_DYEARVAC.EMP_NO = @SEMPNO) AND HRA_DYEARVAC.VAC_YEAR = CONVERT(varchar(4), sysdatetime(), 102)
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
                     SET @MAXHRS = 0
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

            IF @ILEAVE IS NULL OR @ILEAVE = ''
               IF ceiling(ssma_oracle.months_between(ssma_oracle.to_date2(@P_START_DATE, 'yyyy-mm-dd'), ssma_oracle.to_date2(@ICOMEDATE, 'yyyy-mm-dd'))) >= 12
                  SET @MAXHRS = 128/*1*/
               ELSE 
                  BEGIN

                     SET @MAXHRS_TMP = CAST(128 AS float(53)) / 12 * ceiling(ssma_oracle.months_between(ssma_oracle.to_date2(ISNULL(CONVERT(varchar(4), sysdatetime(), 102), '') + '-12-31', 'yyyy-mm-dd'), ssma_oracle.to_date2(@ICOMEDATE, 'yyyy-mm-dd')))

                     /*未滿半日以半日算,滿半日以一日算*/
                     IF @MAXHRS_TMP = floor(@MAXHRS_TMP)
                        SET @MAXHRS = @MAXHRS_TMP
                     ELSE 
                        IF @MAXHRS_TMP = floor(@MAXHRS_TMP) + 0.5
                           SET @MAXHRS = floor(@MAXHRS_TMP) + 0.5
                        ELSE 
                           IF @MAXHRS_TMP > floor(@MAXHRS_TMP) + 0.5
                              SET @MAXHRS = floor(@MAXHRS_TMP) + 1
                           ELSE 
                              SET @MAXHRS = floor(@MAXHRS_TMP) + 0.5/*2*/

                  END
            ELSE 
               BEGIN

                  IF ceiling(ssma_oracle.months_between(ssma_oracle.to_date2(@P_START_DATE, 'yyyy-mm-dd'), ssma_oracle.to_date2(@ICOMEDATE, 'yyyy-mm-dd'))) >= 12
                     SET @MAXHRS_TMP = CAST(128 AS float(53)) / 12 * CAST(substring(@ILEAVE, 6, 2) AS numeric(38, 10))
                  ELSE 
                     SET @MAXHRS_TMP = CAST(128 AS float(53)) / 12 * ceiling(ssma_oracle.months_between(ssma_oracle.to_date2(@ILEAVE, 'yyyy-mm-dd'), ssma_oracle.to_date2(@ICOMEDATE, 'yyyy-mm-dd')))

                  /*未滿半日以半日算,滿半日以一日算*/
                  IF @MAXHRS_TMP = floor(@MAXHRS_TMP)
                     SET @MAXHRS = @MAXHRS_TMP
                  ELSE 
                     IF @MAXHRS_TMP = floor(@MAXHRS_TMP) + 0.5
                        SET @MAXHRS = floor(@MAXHRS_TMP) + 0.5
                     ELSE 
                        IF @MAXHRS_TMP > floor(@MAXHRS_TMP) + 0.5
                           SET @MAXHRS = floor(@MAXHRS_TMP) + 1
                        ELSE 
                           SET @MAXHRS = floor(@MAXHRS_TMP) + 0.5

               END

            IF CAST(@P_OTM_HRS AS float(53)) + @SOFFREST > @MAXHRS
               BEGIN

                  SET @RTNCODE = 2

                  GOTO CONTINUE_FOREACH1

               END

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
        N'MS_SSMA_SOURCE', N'HRP.EHRPHRA12_PKG.hraD030',
        N'SCHEMA', N'hrp',
        N'PROCEDURE', N'EHRPHRA12_PKG$HRAD030'
END TRY
BEGIN CATCH
    IF (@@TRANCOUNT > 0) ROLLBACK
    PRINT ERROR_MESSAGE()
END CATCH
GO
