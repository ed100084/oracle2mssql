
USE MIS
GO
 IF NOT EXISTS(SELECT * FROM sys.schemas WHERE [name] = N'hrp')      
     EXEC (N'CREATE SCHEMA hrp')                                   
 GO                                                               

USE MIS
GO
IF  EXISTS (SELECT * FROM sys.objects so JOIN sys.schemas sc ON so.schema_id = sc.schema_id WHERE so.name = N'EHRPHRA12_PKG$HRAC020'  AND sc.name=N'hrp'  AND type in (N'P',N'PC'))
 DROP PROCEDURE [hrp].[EHRPHRA12_PKG$HRAC020]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE HRP.EHRPHRA12_PKG$HRAC020  
   @P_SUP_NO varchar(max),
   @P_OTM_DATE varchar(max),
   @P_SUP_HRS varchar(max),
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
         @SEMP_NO varchar(20), 
         @SSTART_DATE datetime2(0), 
         /*
         *   SSMA warning messages:
         *   O2SS0356: Conversion from NUMBER datatype can cause data loss.
         */

         @NSUPHRS float(53), 
         /*
         *   SSMA warning messages:
         *   O2SS0356: Conversion from NUMBER datatype can cause data loss.
         */

         @NOTM_HRS float(53), 
         /*
         *   SSMA warning messages:
         *   O2SS0356: Conversion from NUMBER datatype can cause data loss.
         */

         @NCNT_HRS float(53)

      
      /*
      *       sStart_time  hra_supmst.start_time%TYPE ;
      *       sEnd_date    hra_supmst.end_date%TYPE ;
      *       sEnd_time    hra_supmst.end_time%TYPE ;
      *       nCnt   NUMBER;
      */
      SET @RTNCODE = 0

      /*----------------------計算請補休時數------------------------*/
      BEGIN

         BEGIN TRY
            SELECT @SEMP_NO = HRA_SUPMST.EMP_NO, @SSTART_DATE = HRA_SUPMST.START_DATE, /*               , sStart_time                 , sEnd_date                 , sEnd_time*/@NSUPHRS = /*               , start_time                 , end_date                 , end_time*/HRA_SUPMST.SUP_HRS
            FROM HRP.HRA_SUPMST
            WHERE HRA_SUPMST.SUP_NO = @P_SUP_NO
         END TRY

         /*             AND status = 'U' ;*/
         BEGIN CATCH
            BEGIN

               SET @SEMP_NO = NULL

               SET @SSTART_DATE = NULL

               SET @NSUPHRS = 0/*            sStart_time   := null;              sEnd_date     := null;              sEnd_time     := null;              RtnCode       := 7 ;    -- 無請補休              GOTO Continue_ForEach1 ;*/

            END
         END CATCH

      END

      IF ssma_oracle.to_char_date(@SSTART_DATE, 'yyyy-mm-dd') < @P_OTM_DATE OR @SSTART_DATE IS NULL
         BEGIN

            SET @RTNCODE = 7/* 補休日期 < 加班日期*/

            GOTO CONTINUE_FOREACH1

         END

      IF @NSUPHRS = 0
         BEGIN

            SET @RTNCODE = 8/* 無補休時數*/

            GOTO CONTINUE_FOREACH1

         END

      
      /*
      *        IF NOT (sEnd_date IS NULL OR sEnd_time IS NULL) THEN
      *          nSupHrs := ehrphra2_pkg.f_hra3010c(ls_start_date => sStart_date
      *                                        , ls_start_time => sStart_time
      *                                       , ls_end_date   => sEnd_date
      *                                        , ls_end_time   => sEnd_time);
      *       END IF;
      *       IF MOD(nSupHrs, 60) = 0 OR MOD(nSupHrs, 60) = 30 THEN
      *          nSupHrs := nSupHrs / 60 ;
      *       ELSIF MOD(nSupHrs, 60) > 30 THEN
      *         nSupHrs := TRUNC(nSupHrs / 60) + 1 ;
      *       ELSIF MOD(nSupHrs, 60) < 30 THEN
      *          nSupHrs := TRUNC(nSupHrs / 60) + 0.5 ;
      *       END IF ;
      *   ----------------------計算請補休時數------------------------
      *   -----------------補休時數及補休日是否到期-------------------
      */
      BEGIN

         BEGIN TRY
            SELECT @NOTM_HRS = isnull(sum(HRA_OTMSIGN.OTM_HRS), 0)
            FROM HRP.HRA_OTMSIGN
            WHERE 
               HRA_OTMSIGN.STATUS = 'Y' AND 
               HRA_OTMSIGN.ONCALL = 'N' AND 
               (HRA_OTMSIGN.TRN_YM IS NULL OR HRA_OTMSIGN.TRN_YM = '') AND 
               HRA_OTMSIGN.EMP_NO = @SEMP_NO AND 
               ssma_oracle.to_char_date(HRA_OTMSIGN.START_DATE, 'yyyy-mm-dd') = @P_OTM_DATE
         END TRY

         BEGIN CATCH
            BEGIN
               SET @NOTM_HRS = 0
            END
         END CATCH

      END

      IF @NOTM_HRS = 0
         BEGIN

            SET @RTNCODE = 2/* 該日無超時時數可請補休*/

            GOTO CONTINUE_FOREACH1

         END

      IF (ssma_oracle.to_char_date(dateadd(m, 1, @SSTART_DATE), 'yyyy-mm-dd') < @P_OTM_DATE)
         BEGIN

            SET @RTNCODE = 3/* 已逾期，不可補休*/

            GOTO CONTINUE_FOREACH1

         END

      BEGIN

         BEGIN TRY
            SELECT @NCNT_HRS = isnull(sum(HRA_SUPDTL.SUP_HRS), 0)
            FROM HRP.HRA_SUPDTL
            WHERE HRA_SUPDTL.SUP_NO IN 
               (
                  SELECT HRA_SUPMST.SUP_NO
                  FROM HRP.HRA_SUPMST
                  WHERE HRA_SUPMST.EMP_NO = @SEMP_NO AND HRA_SUPMST.STATUS = 'Y'
               ) AND ssma_oracle.to_char_date(HRA_SUPDTL.OTM_DATE, 'yyyy-mm-dd') = @P_OTM_DATE
         END TRY

         /*             and status in ('Y', 'U')*/
         BEGIN CATCH
            BEGIN
               SET @NCNT_HRS = 0
            END
         END CATCH

      END

      IF @NOTM_HRS - (@NCNT_HRS + CAST(@P_SUP_HRS AS float(53))) < 0
         BEGIN

            SET @RTNCODE = 4/* 該日超時時數不足此請補休時數*/

            GOTO CONTINUE_FOREACH1

         END

      BEGIN

         BEGIN TRY
            SELECT @NCNT_HRS = isnull(sum(HRA_SUPDTL.SUP_HRS), 0)
            FROM HRP.HRA_SUPDTL
            WHERE HRA_SUPDTL.SUP_NO = @P_SUP_NO
         END TRY

         /*             AND status = 'U' ;*/
         BEGIN CATCH
            BEGIN
               SET @NCNT_HRS = 0
            END
         END CATCH

      END

      
      /*
      *    IF (nCnt_hrs + p_sup_hrs) < nSupHrs THEN --<==ERROR !!若是兩筆以上的補休會有問題!
      *        RtnCode  := 5 ;   -- 超時時數dtl < 請補休時數mst (警告訊息)  此張申請單
      *     ELSIF (nCnt_hrs + p_sup_hrs) > nSupHrs  THEN
      */
      IF (@NCNT_HRS + CAST(@P_SUP_HRS AS float(53))) > @NSUPHRS
         SET @RTNCODE = 6/* 超時時數dtl > 請補休時數mst (警告訊息)  此張申請單*/

      /*----------------補休時數及補休日是否到期-------------------*/
      DECLARE
         @db_null_statement int

      CONTINUE_FOREACH1:

      DECLARE
         @db_null_statement$2 int

   END
GO
BEGIN TRY
    EXEC sp_addextendedproperty
        N'MS_SSMA_SOURCE', N'HRP.EHRPHRA12_PKG.hraC020',
        N'SCHEMA', N'hrp',
        N'PROCEDURE', N'EHRPHRA12_PKG$HRAC020'
END TRY
BEGIN CATCH
    IF (@@TRANCOUNT > 0) ROLLBACK
    PRINT ERROR_MESSAGE()
END CATCH
GO
