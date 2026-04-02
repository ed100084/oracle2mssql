
USE MIS
GO
 IF NOT EXISTS(SELECT * FROM sys.schemas WHERE [name] = N'hrp')      
     EXEC (N'CREATE SCHEMA hrp')                                   
 GO                                                               

USE MIS
GO
IF  EXISTS (SELECT * FROM sys.objects so JOIN sys.schemas sc ON so.schema_id = sc.schema_id WHERE so.name = N'EHRPHRAFUNC_PKG$F_GETHOLIDAY$IMPL'  AND sc.name=N'hrp'  AND type in (N'P',N'PC'))
 DROP PROCEDURE [hrp].[EHRPHRAFUNC_PKG$F_GETHOLIDAY$IMPL]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE HRP.EHRPHRAFUNC_PKG$F_GETHOLIDAY$IMPL  
   @P_DAY varchar(max),
   @return_value_argument varchar(max)  OUTPUT
AS 
   BEGIN

      EXECUTE ssma_oracle.db_fn_check_init_package 'HRP', 'EHRPHRAFUNC_PKG'

      DECLARE
         @RTNCODE varchar(1), 
         @SDAY varchar(10) = @P_DAY, 
         @IHOLI_TYPE varchar(10), 
         @IHOLI_WEEK varchar(10)

      BEGIN

         BEGIN TRY

            SELECT @IHOLI_TYPE = HRA_HOLIDAY.HOLI_TYPE, @IHOLI_WEEK = HRA_HOLIDAY.HOLI_WEEK
            FROM HRP.HRA_HOLIDAY
            WHERE ssma_oracle.to_char_date(HRA_HOLIDAY.HOLI_DATE, 'YYYY-MM-DD') = @SDAY

            /*IF iHOLI_TYPE = 'D' THEN  --  IF 週休 20161227 區分例假日，休息日*/
            IF @IHOLI_TYPE IN ( 'D', 'X' )
               BEGIN

                  /*  IF 週休*/
                  IF @IHOLI_WEEK = 'SAT'
                     /* IF 週六*/
                     SET @RTNCODE = 'D'

                  IF @IHOLI_WEEK = 'SUN'
                     /* IF 週日*/
                     SET @RTNCODE = 'C'

               END
            ELSE 
               BEGIN
                  IF @IHOLI_TYPE = 'A'
                     /* IF 國定假日*/
                     SET @RTNCODE = 'B'
               END

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
               SET @RTNCODE = 'A'
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

      SET @return_value_argument = @RTNCODE

      RETURN 

   END
GO
BEGIN TRY
    EXEC sp_addextendedproperty
        N'MS_SSMA_SOURCE', N'HRP.EHRPHRAFUNC_PKG.F_GETHOLIDAY',
        N'SCHEMA', N'hrp',
        N'PROCEDURE', N'EHRPHRAFUNC_PKG$F_GETHOLIDAY$IMPL'
END TRY
BEGIN CATCH
    IF (@@TRANCOUNT > 0) ROLLBACK
    PRINT ERROR_MESSAGE()
END CATCH
GO
