
USE MIS
GO
 IF NOT EXISTS(SELECT * FROM sys.schemas WHERE [name] = N'hrp')      
     EXEC (N'CREATE SCHEMA hrp')                                   
 GO                                                               

USE MIS
GO
IF  EXISTS (SELECT * FROM sys.objects so JOIN sys.schemas sc ON so.schema_id = sc.schema_id WHERE so.name = N'EHRPHRA12_PKG$HRAC020A'  AND sc.name=N'hrp'  AND type in (N'P',N'PC'))
 DROP PROCEDURE [hrp].[EHRPHRA12_PKG$HRAC020A]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE HRP.EHRPHRA12_PKG$HRAC020A  
   @P_OTM_DATE varchar(max),
   @P_SUP_DATE varchar(max),
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
         @BASEDATE datetime2(0) = dateadd(m, -1, ssma_oracle.to_date2(ISNULL(substring(@P_SUP_DATE, 1, 7), '') + '-01', 'YYYY-MM-DD'))

      SET @RTNCODE = 0

      IF @P_OTM_DATE > @P_SUP_DATE
         BEGIN

            SET @RTNCODE = 1

            GOTO CONTINUE_FOREACH1

         END

      IF @P_OTM_DATE NOT BETWEEN ssma_oracle.to_char_date(@BASEDATE, 'yyyy-mm-dd') AND @P_OTM_DATE
         BEGIN

            SET @RTNCODE = 2

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
        N'MS_SSMA_SOURCE', N'HRP.EHRPHRA12_PKG.hraC020a',
        N'SCHEMA', N'hrp',
        N'PROCEDURE', N'EHRPHRA12_PKG$HRAC020A'
END TRY
BEGIN CATCH
    IF (@@TRANCOUNT > 0) ROLLBACK
    PRINT ERROR_MESSAGE()
END CATCH
GO
