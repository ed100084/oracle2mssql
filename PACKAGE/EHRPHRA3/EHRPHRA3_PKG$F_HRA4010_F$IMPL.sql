
USE MIS
GO
 IF NOT EXISTS(SELECT * FROM sys.schemas WHERE [name] = N'hrp')      
     EXEC (N'CREATE SCHEMA hrp')                                   
 GO                                                               

USE MIS
GO
IF  EXISTS (SELECT * FROM sys.objects so JOIN sys.schemas sc ON so.schema_id = sc.schema_id WHERE so.name = N'EHRPHRA3_PKG$F_HRA4010_F$IMPL'  AND sc.name=N'hrp'  AND type in (N'P',N'PC'))
 DROP PROCEDURE [hrp].[EHRPHRA3_PKG$F_HRA4010_F$IMPL]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE HRP.EHRPHRA3_PKG$F_HRA4010_F$IMPL  
   @TRNYM_IN varchar(max),
   @TRNSHIFT_IN varchar(max),
   @EMPNO_IN varchar(max),
   @ORGTYPE_IN varchar(max),
   @UPDATEBY_IN varchar(max),
   /*
   *   SSMA warning messages:
   *   O2SS0356: Conversion from NUMBER datatype can cause data loss.
   */

   @return_value_argument float(53)  OUTPUT
AS 
   BEGIN

      DECLARE
         @STRNYM varchar(7) = @TRNYM_IN, 
         @STRNSHIFT varchar(2) = @TRNSHIFT_IN, 
         @SEMPNO varchar(20) = @EMPNO_IN, 
         @SORGANTYPE varchar(10) = @ORGTYPE_IN, 
         @SUPDATEBY varchar(20) = @UPDATEBY_IN, 
         /*
         *   SSMA warning messages:
         *   O2SS0356: Conversion from NUMBER datatype can cause data loss.
         */

         @NOVERTIME float(53), 
         @ICNT int, 
         /*
         *   SSMA warning messages:
         *   O2SS0356: Conversion from NUMBER datatype can cause data loss.
         */

         @NMONADDHRS float(53), 
         @ICNT_1 int, 
         @SDEPTNO varchar(10)

      BEGIN TRY

         EXECUTE ssma_oracle.db_fn_check_init_package 'HRP', 'EHRPHRA3_PKG'

         BEGIN

            BEGIN TRY
               /*20180731 108978 修改積休時數不計排班時數不平，nMonAddhrs 給0*/
               SELECT /*mon_otmhrs,0,dept_no*/@NOVERTIME = HRA_ATTVAC_VIEW.MON_OTMHRS - HRA_ATTVAC_VIEW.MON_OTMHRS_N, @NMONADDHRS = 0, @SDEPTNO = HRA_ATTVAC_VIEW.DEPT_NO/*提前結算要解開，然後下一行要註釋，記得修改HRA_ATTVAC_VIEW mon_otmhrs_n的日期區間 20190122 108978*/
               FROM HRP.HRA_ATTVAC_VIEW
               WHERE 
                  (HRA_ATTVAC_VIEW.SCH_YM = @STRNYM) AND 
                  (HRA_ATTVAC_VIEW.EMP_NO = @SEMPNO) AND 
                  (HRA_ATTVAC_VIEW.ORGAN_TYPE = @SORGANTYPE)
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

                     SET @NOVERTIME = 0

                     SET @NMONADDHRS = 0

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

         IF @NOVERTIME IS NULL
            BEGIN

               SET @NOVERTIME = 0

               SET @NMONADDHRS = 0

            END

         IF HRP.EHRPHRA3_PKG$F_HRA4010_INS(
            @STRNYM, 
            @STRNSHIFT, 
            @SEMPNO, 
            '2040', 
            @NOVERTIME, 
            'H', 
            @SORGANTYPE, 
            @SUPDATEBY) <> 0
            SET @ICNT = 1/*  積假時數INSERT失敗*/

         /* 99.09.28  SPHINX 班表超時時數*/
         BEGIN

            BEGIN TRY
               SELECT @ICNT_1 = count_big(*)
               FROM HRP.HRA_OFFREC_CAL
               WHERE 
                  HRA_OFFREC_CAL.SCH_YM = @STRNYM AND 
                  HRA_OFFREC_CAL.EMP_NO = @SEMPNO AND 
                  HRA_OFFREC_CAL.ORGAN_TYPE = @SORGANTYPE
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
                  SET @ICNT_1 = 0
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

         IF @ICNT_1 = 0
            INSERT HRP.HRA_OFFREC_CAL(
               SCH_YM, 
               EMP_NO, 
               MON_ADDHRS, 
               MON_SPECAL, 
               DISABLED, 
               CREATED_BY, 
               CREATION_DATE, 
               LAST_UPDATED_BY, 
               LAST_UPDATE_DATE, 
               DEPT_NO, 
               ORG_BY, 
               ORGAN_TYPE)
               VALUES (
                  @STRNYM, 
                  @SEMPNO, 
                  @NMONADDHRS, 
                  0, 
                  'N', 
                  @SUPDATEBY, 
                  sysdatetime(), 
                  @SUPDATEBY, 
                  sysdatetime(), 
                  @SDEPTNO, 
                  @SORGANTYPE, 
                  @SORGANTYPE)
         ELSE 
            UPDATE HRP.HRA_OFFREC_CAL
               SET 
                  MON_ADDHRS = @NMONADDHRS, 
                  LAST_UPDATED_BY = @SUPDATEBY, 
                  LAST_UPDATE_DATE = sysdatetime()
            WHERE 
               HRA_OFFREC_CAL.SCH_YM = @STRNYM AND 
               HRA_OFFREC_CAL.EMP_NO = @SEMPNO AND 
               HRA_OFFREC_CAL.ORGAN_TYPE = @SORGANTYPE

         DECLARE
            @db_null_statement int

         SET @return_value_argument = @ICNT

         RETURN 

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

         BEGIN

            IF @@TRANCOUNT > 0
               ROLLBACK WORK 

            SET @return_value_argument = ssma_oracle.db_error_sqlcode(@exceptionidentifier$3, @errornumber$3)

            RETURN 

            DECLARE
               @db_null_statement$2 int

         END

      END CATCH

   END
GO
BEGIN TRY
    EXEC sp_addextendedproperty
        N'MS_SSMA_SOURCE', N'HRP.EHRPHRA3_PKG.f_hra4010_F',
        N'SCHEMA', N'hrp',
        N'PROCEDURE', N'EHRPHRA3_PKG$F_HRA4010_F$IMPL'
END TRY
BEGIN CATCH
    IF (@@TRANCOUNT > 0) ROLLBACK
    PRINT ERROR_MESSAGE()
END CATCH
GO
