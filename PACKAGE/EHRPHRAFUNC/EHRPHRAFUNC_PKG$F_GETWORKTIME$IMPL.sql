
USE MIS
GO
 IF NOT EXISTS(SELECT * FROM sys.schemas WHERE [name] = N'hrp')      
     EXEC (N'CREATE SCHEMA hrp')                                   
 GO                                                               

USE MIS
GO
IF  EXISTS (SELECT * FROM sys.objects so JOIN sys.schemas sc ON so.schema_id = sc.schema_id WHERE so.name = N'EHRPHRAFUNC_PKG$F_GETWORKTIME$IMPL'  AND sc.name=N'hrp'  AND type in (N'P',N'PC'))
 DROP PROCEDURE [hrp].[EHRPHRAFUNC_PKG$F_GETWORKTIME$IMPL]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE HRP.EHRPHRAFUNC_PKG$F_GETWORKTIME$IMPL  
   @SCHYM_IN varchar(max),
   /*
   *   SSMA warning messages:
   *   O2SS0356: Conversion from NUMBER datatype can cause data loss.
   */

   @return_value_argument float(53)  OUTPUT
AS 
   BEGIN

      EXECUTE ssma_oracle.db_fn_check_init_package 'HRP', 'EHRPHRAFUNC_PKG'

      DECLARE
         @SSCHYM varchar(7) = @SCHYM_IN, 
         @IDAYS int, 
         @DSTARTDATE datetime2(0), 
         @DENDDATE datetime2(0), 
         @IHOLIHRS int, 
         @ITOTALHRS int

      SET @DSTARTDATE = ssma_oracle.to_date2(ISNULL(@SSCHYM, '') + '-01', 'YYYY-MM-DD')

      SET @DENDDATE = ssma_oracle.last_day(@DSTARTDATE)

      SET @IDAYS = CAST(CONVERT(varchar(2), @DENDDATE, 106) AS numeric(38, 10))

      SET @ITOTALHRS = @IDAYS * 8

      BEGIN

         BEGIN TRY
            SELECT @IHOLIHRS = sum(HRA_HOLIDAY.HOLI_HRS)
            FROM HRP.HRA_HOLIDAY
            WHERE ssma_oracle.to_char_date(HRA_HOLIDAY.HOLI_DATE, 'YYYY-MM') = @SSCHYM
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
               SET @IHOLIHRS = 0
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

      IF @IHOLIHRS IS NULL
         SET @IHOLIHRS = 0

      SET @return_value_argument = (@ITOTALHRS - @IHOLIHRS)

      RETURN 

   END
GO
BEGIN TRY
    EXEC sp_addextendedproperty
        N'MS_SSMA_SOURCE', N'HRP.EHRPHRAFUNC_PKG.F_GETWORKTIME',
        N'SCHEMA', N'hrp',
        N'PROCEDURE', N'EHRPHRAFUNC_PKG$F_GETWORKTIME$IMPL'
END TRY
BEGIN CATCH
    IF (@@TRANCOUNT > 0) ROLLBACK
    PRINT ERROR_MESSAGE()
END CATCH
GO
