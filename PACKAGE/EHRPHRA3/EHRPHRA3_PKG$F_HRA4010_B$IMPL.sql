
USE MIS
GO
 IF NOT EXISTS(SELECT * FROM sys.schemas WHERE [name] = N'hrp')      
     EXEC (N'CREATE SCHEMA hrp')                                   
 GO                                                               

USE MIS
GO
IF  EXISTS (SELECT * FROM sys.objects so JOIN sys.schemas sc ON so.schema_id = sc.schema_id WHERE so.name = N'EHRPHRA3_PKG$F_HRA4010_B$IMPL'  AND sc.name=N'hrp'  AND type in (N'P',N'PC'))
 DROP PROCEDURE [hrp].[EHRPHRA3_PKG$F_HRA4010_B$IMPL]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE HRP.EHRPHRA3_PKG$F_HRA4010_B$IMPL  
   @TRNYM_IN varchar(max),
   @TRNSHIFT_IN varchar(max),
   @EMPNO_IN varchar(max),
   @STRARTDATE_IN datetime2(0),
   @ENDDATE_IN datetime2(0),
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
         @DSTRARTDATE datetime2(0) = @STRARTDATE_IN, 
         @DENDDATE datetime2(0) = @ENDDATE_IN, 
         @SORGANTYPE varchar(10) = @ORGTYPE_IN, 
         @SUPDATEBY varchar(20) = @UPDATEBY_IN, 
         @ICHKIN1CNT int = 0, 
         @ICHKOUT1CNT int = 0, 
         @ICHKIN2CNT int = 0, 
         @ICHKOUT2CNT int = 0, 
         @ICHKIN3CNT int = 0, 
         @ICHKOUT3CNT int = 0, 
         @NTOTALUNCARD int = 0, 
         @ICHKCARDCNT int = 0, 
         @ICNT int = 0

      BEGIN TRY

         EXECUTE ssma_oracle.db_fn_check_init_package 'HRP', 'EHRPHRA3_PKG'

         
         /*
         *   ----------------------- new 寫法  -------------------------
         *    忘打卡未處理
         */
         SELECT @NTOTALUNCARD = sum(fci.UNCARD)
         FROM 
            (
               SELECT sum(
                  
                     CASE 
                        WHEN HRA_CARDABNORMAL_VIEW.CHKIN1 = '1' OR isnull(HRA_CARDABNORMAL_VIEW.CHKIN1, '1') IS NULL THEN 1
                        ELSE 0
                     END
                   + 
                  
                     CASE 
                        WHEN HRA_CARDABNORMAL_VIEW.CHKOUT1 = '1' OR isnull(HRA_CARDABNORMAL_VIEW.CHKOUT1, '1') IS NULL THEN 1
                        ELSE 0
                     END
                   + 
                  
                     CASE 
                        WHEN HRA_CARDABNORMAL_VIEW.CHKIN2 = '1' OR isnull(HRA_CARDABNORMAL_VIEW.CHKIN2, '1') IS NULL THEN 1
                        ELSE 0
                     END
                   + 
                  
                     CASE 
                        WHEN HRA_CARDABNORMAL_VIEW.CHKOUT2 = '1' OR isnull(HRA_CARDABNORMAL_VIEW.CHKOUT2, '1') IS NULL THEN 1
                        ELSE 0
                     END
                   + 
                  
                     CASE 
                        WHEN HRA_CARDABNORMAL_VIEW.CHKIN3 = '1' OR isnull(HRA_CARDABNORMAL_VIEW.CHKIN3, '1') IS NULL THEN 1
                        ELSE 0
                     END
                   + 
                  
                     CASE 
                        WHEN HRA_CARDABNORMAL_VIEW.CHKOUT3 = '1' OR isnull(HRA_CARDABNORMAL_VIEW.CHKOUT3, '1') IS NULL THEN 1
                        ELSE 0
                     END
                   + 
                  0) AS UNCARD
               FROM HRP.HRA_CARDABNORMAL_VIEW
               WHERE 
                  HRA_CARDABNORMAL_VIEW.EMP_NO = @SEMPNO AND 
                  HRA_CARDABNORMAL_VIEW.ORGAN_TYPE = @SORGANTYPE AND 
                  (HRA_CARDABNORMAL_VIEW.ATT_DATE BETWEEN @DSTRARTDATE AND @DENDDATE) AND 
                  (
                  HRA_CARDABNORMAL_VIEW.CHKIN1 = '1' OR 
                  HRA_CARDABNORMAL_VIEW.CHKIN2 = '1' OR 
                  HRA_CARDABNORMAL_VIEW.CHKIN3 = '1' OR 
                  HRA_CARDABNORMAL_VIEW.CHKOUT1 = '1' OR 
                  HRA_CARDABNORMAL_VIEW.CHKOUT2 = '1' OR 
                  HRA_CARDABNORMAL_VIEW.CHKOUT3 = '1')
            )  AS fci

         IF @NTOTALUNCARD > 0
            BEGIN
               IF HRP.EHRPHRA3_PKG$F_HRA4010_INS(
                  @STRNYM, 
                  @STRNSHIFT, 
                  @SEMPNO, 
                  '2010', 
                  @NTOTALUNCARD, 
                  'T', 
                  @SORGANTYPE, 
                  @SUPDATEBY) <> 0
                  SET @ICNT = 1/*  未打卡次數INSERT失敗*/
            END

         /*- 忘打卡單*/
         SET @NTOTALUNCARD = 0

         SELECT @NTOTALUNCARD = sum(fci.UNCARD)
         FROM 
            (
               SELECT count_big(*) AS UNCARD
               FROM HRP.HRA_UNCARD
               WHERE 
                  HRA_UNCARD.EMP_NO = @SEMPNO AND 
                  HRA_UNCARD.OTM_REA LIKE '1%' AND 
                  (HRA_UNCARD.CLASS_DATE BETWEEN @DSTRARTDATE AND @DENDDATE) AND 
                  HRA_UNCARD.STATUS = 'Y' AND 
                  HRA_UNCARD.ORG_BY = @SORGANTYPE
            )  AS fci

         IF @NTOTALUNCARD = 0
            GOTO CONTINUE_FOREACH1

         IF HRP.EHRPHRA3_PKG$F_HRA4010_INS(
            @STRNYM, 
            @STRNSHIFT, 
            @SEMPNO, 
            '2050', 
            @NTOTALUNCARD, 
            'T', 
            @SORGANTYPE, 
            @SUPDATEBY) <> 0
            SET @ICNT = 1/*  未打卡次數INSERT失敗*/

         DECLARE
            @db_null_statement int

         CONTINUE_FOREACH1:

         SET @return_value_argument = @ICNT

         RETURN 

         DECLARE
            @db_null_statement$2 int

      END TRY

      /*----------------------- new 寫法  -------------------------*/
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

         BEGIN

            IF @@TRANCOUNT > 0
               ROLLBACK WORK 

            SET @return_value_argument = ssma_oracle.db_error_sqlcode(@exceptionidentifier, @errornumber)

            RETURN 

            DECLARE
               @db_null_statement$3 int

         END

      END CATCH

   END
GO
BEGIN TRY
    EXEC sp_addextendedproperty
        N'MS_SSMA_SOURCE', N'HRP.EHRPHRA3_PKG.f_hra4010_B',
        N'SCHEMA', N'hrp',
        N'PROCEDURE', N'EHRPHRA3_PKG$F_HRA4010_B$IMPL'
END TRY
BEGIN CATCH
    IF (@@TRANCOUNT > 0) ROLLBACK
    PRINT ERROR_MESSAGE()
END CATCH
GO
