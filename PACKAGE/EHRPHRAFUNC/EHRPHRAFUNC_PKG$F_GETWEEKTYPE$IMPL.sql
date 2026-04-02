
USE MIS
GO
 IF NOT EXISTS(SELECT * FROM sys.schemas WHERE [name] = N'hrp')      
     EXEC (N'CREATE SCHEMA hrp')                                   
 GO                                                               

USE MIS
GO
IF  EXISTS (SELECT * FROM sys.objects so JOIN sys.schemas sc ON so.schema_id = sc.schema_id WHERE so.name = N'EHRPHRAFUNC_PKG$F_GETWEEKTYPE$IMPL'  AND sc.name=N'hrp'  AND type in (N'P',N'PC'))
 DROP PROCEDURE [hrp].[EHRPHRAFUNC_PKG$F_GETWEEKTYPE$IMPL]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE HRP.EHRPHRAFUNC_PKG$F_GETWEEKTYPE$IMPL  
   @ATTDATE_IN datetime2(0),
   @return_value_argument varchar(max)  OUTPUT
AS 
   BEGIN

      EXECUTE ssma_oracle.db_fn_check_init_package 'HRP', 'EHRPHRAFUNC_PKG'

      DECLARE
         @DATTDATE datetime2(0) = @ATTDATE_IN, 
         @SRTNTYPE varchar(1), 
         @SDAY varchar(1), 
         @ICNT int

      BEGIN

         BEGIN TRY
            SELECT @ICNT = count_big(*)
            FROM HRP.HRA_HOLIDAY
            WHERE HRA_HOLIDAY.HOLI_DATE = @DATTDATE AND HRA_HOLIDAY.HOLI_TYPE = 'A'
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
         SET @SRTNTYPE = 'H'
      ELSE 
         BEGIN

            SET @SDAY = ssma_oracle.to_char_date(@DATTDATE, 'D')

            IF @SDAY = '7'
               SET @SRTNTYPE = 'W'
            ELSE 
               IF @SDAY = '1'
                  SET @SRTNTYPE = 'H'
               ELSE 
                  SET @SRTNTYPE = 'N'

         END

      SET @return_value_argument = @SRTNTYPE

      RETURN 

   END
GO
BEGIN TRY
    EXEC sp_addextendedproperty
        N'MS_SSMA_SOURCE', N'HRP.EHRPHRAFUNC_PKG.F_GETWEEKTYPE',
        N'SCHEMA', N'hrp',
        N'PROCEDURE', N'EHRPHRAFUNC_PKG$F_GETWEEKTYPE$IMPL'
END TRY
BEGIN CATCH
    IF (@@TRANCOUNT > 0) ROLLBACK
    PRINT ERROR_MESSAGE()
END CATCH
GO
