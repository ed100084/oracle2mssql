
USE MIS
GO
 IF NOT EXISTS(SELECT * FROM sys.schemas WHERE [name] = N'hrp')      
     EXEC (N'CREATE SCHEMA hrp')                                   
 GO                                                               

USE MIS
GO
IF  EXISTS (SELECT * FROM sys.objects so JOIN sys.schemas sc ON so.schema_id = sc.schema_id WHERE so.name = N'EHRPHRA12_PKG$HRAC030_ADD'  AND sc.name=N'hrp'  AND type in (N'P',N'PC'))
 DROP PROCEDURE [hrp].[EHRPHRA12_PKG$HRAC030_ADD]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE HRP.EHRPHRA12_PKG$HRAC030_ADD  
   @P_EMP_NO varchar(max),
   @P_START_DATE varchar(max),
   @P_START_DATE_TMP varchar(max),
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
         @SCLASSCODE varchar(3)/*當日班別*/, 
         /*
         *   SSMA warning messages:
         *   O2SS0356: Conversion from NUMBER datatype can cause data loss.
         */

         @SWORKHRS float(53)/*當日班別時數*/, 
         /*
         *   SSMA warning messages:
         *   O2SS0356: Conversion from NUMBER datatype can cause data loss.
         */

         @STOTADDHRS float(53)/*當日在途加班費申請時數*/, 
         /*
         *   SSMA warning messages:
         *   O2SS0356: Conversion from NUMBER datatype can cause data loss.
         */

         @STOTMONADD float(53)/*當月加班費總時數(含在途)*/, 
         /*
         *   SSMA warning messages:
         *   O2SS0356: Conversion from NUMBER datatype can cause data loss.
         */

         @SOTMSIGNHRS float(53)/*當月加班補休總時數(含在途)*/, 
         /*
         *   SSMA warning messages:
         *   O2SS0356: Conversion from NUMBER datatype can cause data loss.
         */

         @SOTMHRS float(53) = CAST(@P_OTM_HRS AS numeric(38, 10))

      SET @RTNCODE = 0

      SET @SWORKHRS = 0

      SET @STOTADDHRS = 0

      SET @STOTMONADD = 0

      SET @SOTMSIGNHRS = 0

      SET @SCLASSCODE = HRP.EHRPHRAFUNC_PKG$F_GETCLASSKIND(@P_EMP_NO, ssma_oracle.to_date2(isnull(@P_START_DATE_TMP, @P_START_DATE), 'YYYY-MM-DD'), @ORGANTYPE_IN)

      BEGIN

         BEGIN TRY
            /*當日班別時數*/
            SELECT @SWORKHRS = HRA_CLASSMST.WORK_HRS
            FROM HRP.HRA_CLASSMST
            WHERE HRA_CLASSMST.CLASS_CODE = @SCLASSCODE
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
               SET @SWORKHRS = 0
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

      BEGIN

         BEGIN TRY
            /*當日在途加班費申請時數*/
            SELECT @STOTADDHRS = sum(HRA_OFFREC.SOTM_HRS)
            FROM HRP.HRA_OFFREC
            WHERE 
               ssma_oracle.to_char_date(isnull(HRA_OFFREC.START_DATE_TMP, HRA_OFFREC.START_DATE), 'yyyy-mm-dd') = isnull(@P_START_DATE_TMP, @P_START_DATE) AND 
               HRA_OFFREC.STATUS <> 'N' AND 
               HRA_OFFREC.ITEM_TYPE = 'A' AND 
               HRA_OFFREC.EMP_NO = @P_EMP_NO
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
               SET @STOTADDHRS = 0
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

      IF @SOTMHRS IS NULL
         SET @SOTMHRS = 0

      IF @SWORKHRS IS NULL
         SET @SWORKHRS = 0

      IF @STOTADDHRS IS NULL
         SET @STOTADDHRS = 0

      IF (@SOTMHRS + @SWORKHRS + @STOTADDHRS) > 12
         BEGIN

            SET @RTNCODE = 1

            GOTO CONTINUE_FOREACH1

         END

      BEGIN

         BEGIN TRY
            SELECT @STOTMONADD/* 當月加班費總時數(含在途)*/ = isnull(sum(
               CASE 
                  WHEN TT.S_CLASS = 'ZZ' OR isnull(TT.S_CLASS, 'ZZ') IS NULL THEN (TT.SONEOTT + TT.SONEOSS + TT.SONEUU)
                  WHEN TT.S_CLASS = 'ZQ' OR isnull(TT.S_CLASS, 'ZQ') IS NULL THEN (TT.SONEOTT + TT.SONEOSS + TT.SONEUU)
                  WHEN TT.S_CLASS = 'ZY' OR isnull(TT.S_CLASS, 'ZY') IS NULL THEN (TT.SONEOTT + TT.SONEOSS + TT.SONEUU)
                  ELSE TT.SOTM_HRS
               END), 0)
            FROM 
               (
                  SELECT 
                     
                        (
                           SELECT HRA_CLASSSCH_VIEW.CLASS_CODE
                           FROM HRP.HRA_CLASSSCH_VIEW
                           WHERE HRA_CLASSSCH_VIEW.EMP_NO = HRA_OFFREC.EMP_NO AND HRA_CLASSSCH_VIEW.ATT_DATE = ssma_oracle.to_char_date(HRA_OFFREC.START_DATE, 'yyyy-mm-dd')
                        ) AS S_CLASS, 
                     HRA_OFFREC.OTM_HRS, 
                     HRA_OFFREC.SONEO, 
                     HRA_OFFREC.SONEOTT, 
                     HRA_OFFREC.SONEOSS, 
                     HRA_OFFREC.SOTM_HRS, 
                     HRA_OFFREC.SONEUU
                  FROM HRP.HRA_OFFREC
                  WHERE 
                     ssma_oracle.to_char_date(isnull(HRA_OFFREC.START_DATE_TMP, HRA_OFFREC.START_DATE), 'yyyy-mm') = substring(isnull(@P_START_DATE_TMP, @P_START_DATE), 1, 7) AND 
                     HRA_OFFREC.STATUS <> 'N' AND 
                     HRA_OFFREC.ITEM_TYPE = 'A' AND 
                     HRA_OFFREC.EMP_NO = @P_EMP_NO
               )  AS TT
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
               SET @STOTMONADD = 0
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
            SELECT @SOTMSIGNHRS/* 當月加班補休總時數(含在途)*/ = isnull(sum(HRA_OTMSIGN.OTM_HRS), 0)
            FROM HRP.HRA_OTMSIGN
            WHERE 
               ssma_oracle.to_char_date(isnull(HRA_OTMSIGN.START_DATE_TMP, HRA_OTMSIGN.START_DATE), 'yyyy-mm') = substring(isnull(@P_START_DATE_TMP, @P_START_DATE), 1, 7) AND 
               HRA_OTMSIGN.STATUS <> 'N' AND 
               HRA_OTMSIGN.OTM_FLAG = 'B' AND 
               HRA_OTMSIGN.EMP_NO = @P_EMP_NO
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
               SET @SOTMSIGNHRS = 0
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

      IF @STOTMONADD IS NULL
         SET @STOTMONADD = 0

      IF @SOTMSIGNHRS IS NULL
         SET @SOTMSIGNHRS = 0

      IF (@SOTMHRS + @STOTMONADD + @SOTMSIGNHRS) > 54
         BEGIN

            SET @RTNCODE = 2

            GOTO CONTINUE_FOREACH1

         END

      SET @RTNCODE = HRP.EHRPHRA12_PKG$CHECK3MONTHOTMHRS(@P_EMP_NO, isnull(@P_START_DATE_TMP, @P_START_DATE), @P_OTM_HRS, @ORGANTYPE_IN)

      IF @RTNCODE = 16
         BEGIN

            SET @RTNCODE = 3

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
        N'MS_SSMA_SOURCE', N'HRP.EHRPHRA12_PKG.hraC030_add',
        N'SCHEMA', N'hrp',
        N'PROCEDURE', N'EHRPHRA12_PKG$HRAC030_ADD'
END TRY
BEGIN CATCH
    IF (@@TRANCOUNT > 0) ROLLBACK
    PRINT ERROR_MESSAGE()
END CATCH
GO
