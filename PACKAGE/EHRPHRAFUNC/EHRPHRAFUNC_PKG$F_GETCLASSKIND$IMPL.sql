
USE MIS
GO
 IF NOT EXISTS(SELECT * FROM sys.schemas WHERE [name] = N'hrp')      
     EXEC (N'CREATE SCHEMA hrp')                                   
 GO                                                               

USE MIS
GO
IF  EXISTS (SELECT * FROM sys.objects so JOIN sys.schemas sc ON so.schema_id = sc.schema_id WHERE so.name = N'EHRPHRAFUNC_PKG$F_GETCLASSKIND$IMPL'  AND sc.name=N'hrp'  AND type in (N'P',N'PC'))
 DROP PROCEDURE [hrp].[EHRPHRAFUNC_PKG$F_GETCLASSKIND$IMPL]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE HRP.EHRPHRAFUNC_PKG$F_GETCLASSKIND$IMPL  
   @EMPNO_IN varchar(max),
   @DATE_IN datetime2(0),
   @ORGANTYPE_IN varchar(max),
   @return_value_argument varchar(max)  OUTPUT
AS 
   BEGIN

      EXECUTE ssma_oracle.db_fn_check_init_package 'HRP', 'EHRPHRAFUNC_PKG'

      DECLARE
         @SORGANTYPE varchar(10), 
         @ICLASSCODE varchar(3)

      SET @SORGANTYPE = @ORGANTYPE_IN

      BEGIN

         BEGIN TRY
            SELECT @ICLASSCODE = 
               CASE 
                  WHEN substring(ssma_oracle.to_char_date(@DATE_IN, 'yyyy-mm-dd'), 9, 10) = '01' OR isnull(substring(ssma_oracle.to_char_date(@DATE_IN, 'yyyy-mm-dd'), 9, 10), '01') IS NULL THEN HRA_CLASSSCH.SCH_01
                  WHEN substring(ssma_oracle.to_char_date(@DATE_IN, 'yyyy-mm-dd'), 9, 10) = '02' OR isnull(substring(ssma_oracle.to_char_date(@DATE_IN, 'yyyy-mm-dd'), 9, 10), '02') IS NULL THEN HRA_CLASSSCH.SCH_02
                  WHEN substring(ssma_oracle.to_char_date(@DATE_IN, 'yyyy-mm-dd'), 9, 10) = '03' OR isnull(substring(ssma_oracle.to_char_date(@DATE_IN, 'yyyy-mm-dd'), 9, 10), '03') IS NULL THEN HRA_CLASSSCH.SCH_03
                  WHEN substring(ssma_oracle.to_char_date(@DATE_IN, 'yyyy-mm-dd'), 9, 10) = '04' OR isnull(substring(ssma_oracle.to_char_date(@DATE_IN, 'yyyy-mm-dd'), 9, 10), '04') IS NULL THEN HRA_CLASSSCH.SCH_04
                  WHEN substring(ssma_oracle.to_char_date(@DATE_IN, 'yyyy-mm-dd'), 9, 10) = '05' OR isnull(substring(ssma_oracle.to_char_date(@DATE_IN, 'yyyy-mm-dd'), 9, 10), '05') IS NULL THEN HRA_CLASSSCH.SCH_05
                  WHEN substring(ssma_oracle.to_char_date(@DATE_IN, 'yyyy-mm-dd'), 9, 10) = '06' OR isnull(substring(ssma_oracle.to_char_date(@DATE_IN, 'yyyy-mm-dd'), 9, 10), '06') IS NULL THEN HRA_CLASSSCH.SCH_06
                  WHEN substring(ssma_oracle.to_char_date(@DATE_IN, 'yyyy-mm-dd'), 9, 10) = '07' OR isnull(substring(ssma_oracle.to_char_date(@DATE_IN, 'yyyy-mm-dd'), 9, 10), '07') IS NULL THEN HRA_CLASSSCH.SCH_07
                  WHEN substring(ssma_oracle.to_char_date(@DATE_IN, 'yyyy-mm-dd'), 9, 10) = '08' OR isnull(substring(ssma_oracle.to_char_date(@DATE_IN, 'yyyy-mm-dd'), 9, 10), '08') IS NULL THEN HRA_CLASSSCH.SCH_08
                  WHEN substring(ssma_oracle.to_char_date(@DATE_IN, 'yyyy-mm-dd'), 9, 10) = '09' OR isnull(substring(ssma_oracle.to_char_date(@DATE_IN, 'yyyy-mm-dd'), 9, 10), '09') IS NULL THEN HRA_CLASSSCH.SCH_09
                  WHEN substring(ssma_oracle.to_char_date(@DATE_IN, 'yyyy-mm-dd'), 9, 10) = '10' OR isnull(substring(ssma_oracle.to_char_date(@DATE_IN, 'yyyy-mm-dd'), 9, 10), '10') IS NULL THEN HRA_CLASSSCH.SCH_10
                  WHEN substring(ssma_oracle.to_char_date(@DATE_IN, 'yyyy-mm-dd'), 9, 10) = '11' OR isnull(substring(ssma_oracle.to_char_date(@DATE_IN, 'yyyy-mm-dd'), 9, 10), '11') IS NULL THEN HRA_CLASSSCH.SCH_11
                  WHEN substring(ssma_oracle.to_char_date(@DATE_IN, 'yyyy-mm-dd'), 9, 10) = '12' OR isnull(substring(ssma_oracle.to_char_date(@DATE_IN, 'yyyy-mm-dd'), 9, 10), '12') IS NULL THEN HRA_CLASSSCH.SCH_12
                  WHEN substring(ssma_oracle.to_char_date(@DATE_IN, 'yyyy-mm-dd'), 9, 10) = '13' OR isnull(substring(ssma_oracle.to_char_date(@DATE_IN, 'yyyy-mm-dd'), 9, 10), '13') IS NULL THEN HRA_CLASSSCH.SCH_13
                  WHEN substring(ssma_oracle.to_char_date(@DATE_IN, 'yyyy-mm-dd'), 9, 10) = '14' OR isnull(substring(ssma_oracle.to_char_date(@DATE_IN, 'yyyy-mm-dd'), 9, 10), '14') IS NULL THEN HRA_CLASSSCH.SCH_14
                  WHEN substring(ssma_oracle.to_char_date(@DATE_IN, 'yyyy-mm-dd'), 9, 10) = '15' OR isnull(substring(ssma_oracle.to_char_date(@DATE_IN, 'yyyy-mm-dd'), 9, 10), '15') IS NULL THEN HRA_CLASSSCH.SCH_15
                  WHEN substring(ssma_oracle.to_char_date(@DATE_IN, 'yyyy-mm-dd'), 9, 10) = '16' OR isnull(substring(ssma_oracle.to_char_date(@DATE_IN, 'yyyy-mm-dd'), 9, 10), '16') IS NULL THEN HRA_CLASSSCH.SCH_16
                  WHEN substring(ssma_oracle.to_char_date(@DATE_IN, 'yyyy-mm-dd'), 9, 10) = '17' OR isnull(substring(ssma_oracle.to_char_date(@DATE_IN, 'yyyy-mm-dd'), 9, 10), '17') IS NULL THEN HRA_CLASSSCH.SCH_17
                  WHEN substring(ssma_oracle.to_char_date(@DATE_IN, 'yyyy-mm-dd'), 9, 10) = '18' OR isnull(substring(ssma_oracle.to_char_date(@DATE_IN, 'yyyy-mm-dd'), 9, 10), '18') IS NULL THEN HRA_CLASSSCH.SCH_18
                  WHEN substring(ssma_oracle.to_char_date(@DATE_IN, 'yyyy-mm-dd'), 9, 10) = '19' OR isnull(substring(ssma_oracle.to_char_date(@DATE_IN, 'yyyy-mm-dd'), 9, 10), '19') IS NULL THEN HRA_CLASSSCH.SCH_19
                  WHEN substring(ssma_oracle.to_char_date(@DATE_IN, 'yyyy-mm-dd'), 9, 10) = '20' OR isnull(substring(ssma_oracle.to_char_date(@DATE_IN, 'yyyy-mm-dd'), 9, 10), '20') IS NULL THEN HRA_CLASSSCH.SCH_20
                  WHEN substring(ssma_oracle.to_char_date(@DATE_IN, 'yyyy-mm-dd'), 9, 10) = '21' OR isnull(substring(ssma_oracle.to_char_date(@DATE_IN, 'yyyy-mm-dd'), 9, 10), '21') IS NULL THEN HRA_CLASSSCH.SCH_21
                  WHEN substring(ssma_oracle.to_char_date(@DATE_IN, 'yyyy-mm-dd'), 9, 10) = '22' OR isnull(substring(ssma_oracle.to_char_date(@DATE_IN, 'yyyy-mm-dd'), 9, 10), '22') IS NULL THEN HRA_CLASSSCH.SCH_22
                  WHEN substring(ssma_oracle.to_char_date(@DATE_IN, 'yyyy-mm-dd'), 9, 10) = '23' OR isnull(substring(ssma_oracle.to_char_date(@DATE_IN, 'yyyy-mm-dd'), 9, 10), '23') IS NULL THEN HRA_CLASSSCH.SCH_23
                  WHEN substring(ssma_oracle.to_char_date(@DATE_IN, 'yyyy-mm-dd'), 9, 10) = '24' OR isnull(substring(ssma_oracle.to_char_date(@DATE_IN, 'yyyy-mm-dd'), 9, 10), '24') IS NULL THEN HRA_CLASSSCH.SCH_24
                  WHEN substring(ssma_oracle.to_char_date(@DATE_IN, 'yyyy-mm-dd'), 9, 10) = '25' OR isnull(substring(ssma_oracle.to_char_date(@DATE_IN, 'yyyy-mm-dd'), 9, 10), '25') IS NULL THEN HRA_CLASSSCH.SCH_25
                  WHEN substring(ssma_oracle.to_char_date(@DATE_IN, 'yyyy-mm-dd'), 9, 10) = '26' OR isnull(substring(ssma_oracle.to_char_date(@DATE_IN, 'yyyy-mm-dd'), 9, 10), '26') IS NULL THEN HRA_CLASSSCH.SCH_26
                  WHEN substring(ssma_oracle.to_char_date(@DATE_IN, 'yyyy-mm-dd'), 9, 10) = '27' OR isnull(substring(ssma_oracle.to_char_date(@DATE_IN, 'yyyy-mm-dd'), 9, 10), '27') IS NULL THEN HRA_CLASSSCH.SCH_27
                  WHEN substring(ssma_oracle.to_char_date(@DATE_IN, 'yyyy-mm-dd'), 9, 10) = '28' OR isnull(substring(ssma_oracle.to_char_date(@DATE_IN, 'yyyy-mm-dd'), 9, 10), '28') IS NULL THEN HRA_CLASSSCH.SCH_28
                  WHEN substring(ssma_oracle.to_char_date(@DATE_IN, 'yyyy-mm-dd'), 9, 10) = '29' OR isnull(substring(ssma_oracle.to_char_date(@DATE_IN, 'yyyy-mm-dd'), 9, 10), '29') IS NULL THEN HRA_CLASSSCH.SCH_29
                  WHEN substring(ssma_oracle.to_char_date(@DATE_IN, 'yyyy-mm-dd'), 9, 10) = '30' OR isnull(substring(ssma_oracle.to_char_date(@DATE_IN, 'yyyy-mm-dd'), 9, 10), '30') IS NULL THEN HRA_CLASSSCH.SCH_30
                  WHEN substring(ssma_oracle.to_char_date(@DATE_IN, 'yyyy-mm-dd'), 9, 10) = '31' OR isnull(substring(ssma_oracle.to_char_date(@DATE_IN, 'yyyy-mm-dd'), 9, 10), '31') IS NULL THEN HRA_CLASSSCH.SCH_31
               END
            FROM HRP.HRA_CLASSSCH
            WHERE 
               HRA_CLASSSCH.EMP_NO = @EMPNO_IN AND 
               HRA_CLASSSCH.SCH_YM = ssma_oracle.to_char_date(@DATE_IN, 'yyyy-mm') AND 
               HRA_CLASSSCH.ORG_BY = @SORGANTYPE
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
               BEGIN

                  SET @ICLASSCODE = 'N/A'/*無排班*/

                  IF @ICLASSCODE = NULL
                     SET @ICLASSCODE = 'N/A'

                  SET @return_value_argument = @ICLASSCODE

                  RETURN 

               END
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

      DECLARE
         @db_null_statement int

      SET @return_value_argument = @ICLASSCODE

      RETURN 

   END
GO
BEGIN TRY
    EXEC sp_addextendedproperty
        N'MS_SSMA_SOURCE', N'HRP.EHRPHRAFUNC_PKG.F_GETCLASSKIND',
        N'SCHEMA', N'hrp',
        N'PROCEDURE', N'EHRPHRAFUNC_PKG$F_GETCLASSKIND$IMPL'
END TRY
BEGIN CATCH
    IF (@@TRANCOUNT > 0) ROLLBACK
    PRINT ERROR_MESSAGE()
END CATCH
GO
