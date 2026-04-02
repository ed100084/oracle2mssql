
USE MIS
GO
 IF NOT EXISTS(SELECT * FROM sys.schemas WHERE [name] = N'hrp')      
     EXEC (N'CREATE SCHEMA hrp')                                   
 GO                                                               

USE MIS
GO
IF  EXISTS (SELECT * FROM sys.objects so JOIN sys.schemas sc ON so.schema_id = sc.schema_id WHERE so.name = N'EHRPHRA12_PKG$CHECK3MONTHOTMHRS$IMPL'  AND sc.name=N'hrp'  AND type in (N'P',N'PC'))
 DROP PROCEDURE [hrp].[EHRPHRA12_PKG$CHECK3MONTHOTMHRS$IMPL]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE HRP.EHRPHRA12_PKG$CHECK3MONTHOTMHRS$IMPL  
   @P_EMP_NO varchar(max),
   @P_START_DATE varchar(max),
   @P_OTM_HRS varchar(max),
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
         @RTNCODE numeric(4), 
         /*
         *   SSMA warning messages:
         *   O2SS0356: Conversion from NUMBER datatype can cause data loss.
         */

         @SOTMHRS float(53) = CAST(@P_OTM_HRS AS numeric(38, 10)), 
         /*
         *   SSMA warning messages:
         *   O2SS0356: Conversion from NUMBER datatype can cause data loss.
         */

         @STOTMONADD float(53)/*當月加班費總時數(含在途)*/, 
         /*
         *   SSMA warning messages:
         *   O2SS0356: Conversion from NUMBER datatype can cause data loss.
         */

         @SOTMSIGNHRS float(53)/*當月加班補休時數(含在途)*/, 
         /*
         *   SSMA warning messages:
         *   O2SS0356: Conversion from NUMBER datatype can cause data loss.
         */

         @SMONCLASSADD float(53)/* 當月班表超時*/

      SET @RTNCODE = 0

      BEGIN

         BEGIN TRY
            SELECT @STOTMONADD/* 當月積休單總時數(含在途)*/ = sum(
               CASE 
                  WHEN TT.S_CLASS = 'ZZ' OR isnull(TT.S_CLASS, 'ZZ') IS NULL THEN (TT.SONEOTT + TT.SONEOSS + TT.SONEUU)
                  WHEN TT.S_CLASS = 'ZQ' OR isnull(TT.S_CLASS, 'ZQ') IS NULL THEN (TT.SONEOTT + TT.SONEOSS + TT.SONEUU)
                  WHEN TT.S_CLASS = 'ZY' OR isnull(TT.S_CLASS, 'ZY') IS NULL THEN (TT.SONEOTT + TT.SONEOSS + TT.SONEUU)
                  ELSE TT.SOTM_HRS
               END)
            FROM 
               (
                  SELECT 
                     
                        (
                           SELECT HRA_CLASSSCH_VIEW.CLASS_CODE
                           FROM HRP.HRA_CLASSSCH_VIEW
                           WHERE HRA_CLASSSCH_VIEW.EMP_NO = HRA_OFFREC.EMP_NO AND HRA_CLASSSCH_VIEW.ATT_DATE = ssma_oracle.to_char_date(isnull(HRA_OFFREC.START_DATE_TMP, HRA_OFFREC.START_DATE), 'yyyy-mm-dd')
                        ) AS S_CLASS, 
                     HRA_OFFREC.OTM_HRS, 
                     HRA_OFFREC.SONEO, 
                     HRA_OFFREC.SONEOTT, 
                     HRA_OFFREC.SONEOSS, 
                     HRA_OFFREC.SOTM_HRS, 
                     HRA_OFFREC.SONEUU
                  FROM HRP.HRA_OFFREC
                  WHERE 
                     CONVERT(varchar(6), isnull(HRA_OFFREC.START_DATE_TMP, HRA_OFFREC.START_DATE), 112) >= CONVERT(varchar(6), dateadd(m, -2, ssma_oracle.to_date2(@P_START_DATE, 'yyyy-mm-dd')), 112) AND 
                     CONVERT(varchar(6), isnull(HRA_OFFREC.START_DATE_TMP, HRA_OFFREC.START_DATE), 112) <= CONVERT(varchar(6), ssma_oracle.to_date2(@P_START_DATE, 'yyyy-mm-dd'), 112) AND 
                     HRA_OFFREC.STATUS <> 'N' AND 
                     HRA_OFFREC.ITEM_TYPE = 'A' AND 
                     HRA_OFFREC.EMP_NO = @P_EMP_NO
               )  AS TT
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
               SET @STOTMONADD = 0
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

      IF @STOTMONADD IS NULL
         SET @STOTMONADD = 0

      BEGIN

         BEGIN TRY
            SELECT @SOTMSIGNHRS/* 3個月加班單總時數(含在途)*/ = isnull(sum(HRA_OTMSIGN.OTM_HRS), 0)
            FROM HRP.HRA_OTMSIGN
            WHERE 
               CONVERT(varchar(6), isnull(HRA_OTMSIGN.START_DATE_TMP, HRA_OTMSIGN.START_DATE), 112) >= CONVERT(varchar(6), dateadd(m, -2, ssma_oracle.to_date2(@P_START_DATE, 'yyyy-mm-dd')), 112) AND 
               CONVERT(varchar(6), isnull(HRA_OTMSIGN.START_DATE_TMP, HRA_OTMSIGN.START_DATE), 112) <= CONVERT(varchar(6), ssma_oracle.to_date2(@P_START_DATE, 'yyyy-mm-dd'), 112) AND 
               HRA_OTMSIGN.STATUS <> 'N' AND 
               HRA_OTMSIGN.OTM_FLAG = 'B' AND 
               HRA_OTMSIGN.EMP_NO = @P_EMP_NO
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
               SET @SOTMSIGNHRS = 0
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

      IF @SOTMSIGNHRS IS NULL
         SET @SOTMSIGNHRS = 0

      BEGIN

         BEGIN TRY
            SELECT @SMONCLASSADD/*當月排班超時*/ = (HRA_ATTVAC_VIEW.MON_GETADD + HRA_ATTVAC_VIEW.MON_ADDHRS + HRA_ATTVAC_VIEW.MON_SPCOTM - HRA_ATTVAC_VIEW.MON_CUTOTM + HRA_ATTVAC_VIEW.MON_DUTYHRS)
            FROM HRP.HRA_ATTVAC_VIEW
            WHERE HRA_ATTVAC_VIEW.SCH_YM = ssma_oracle.to_char_date(ssma_oracle.to_date2(@P_START_DATE, 'yyyy-mm-dd'), 'yyyy-mm') AND HRA_ATTVAC_VIEW.EMP_NO = @P_EMP_NO
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
               SET @SMONCLASSADD = 0
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

      
      /*
      *   IF   (sOtmsignHrs+sTotMonAdd+sMonClassAdd+sOtmhrs >= 138) THEN
      *   20190225 by108482 需求單IMP201901037 加班超過138小時不計算當月排班超時工時
      */
      IF (@SOTMSIGNHRS + @STOTMONADD + @SOTMHRS > 138)
         BEGIN

            PRINT 'p_emp_no' + ISNULL(@P_EMP_NO, '')

            /*dbms_output.put_line('OTM_HRS'||TO_CHAR(sOtmsignHrs+sTotMonAdd+sMonClassAdd+sOtmhrs));*/
            PRINT 'OTM_HRS' + ISNULL(CAST(@SOTMSIGNHRS + @STOTMONADD + @SOTMHRS AS varchar(max)), '')

            SET @RTNCODE = 16

            GOTO CONTINUE_FOREACH1

         END
      ELSE 
         SET @RTNCODE = 0

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
        N'MS_SSMA_SOURCE', N'HRP.EHRPHRA12_PKG.Check3MonthOtmhrs',
        N'SCHEMA', N'hrp',
        N'PROCEDURE', N'EHRPHRA12_PKG$CHECK3MONTHOTMHRS$IMPL'
END TRY
BEGIN CATCH
    IF (@@TRANCOUNT > 0) ROLLBACK
    PRINT ERROR_MESSAGE()
END CATCH
GO
