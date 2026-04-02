
USE MIS
GO
 IF NOT EXISTS(SELECT * FROM sys.schemas WHERE [name] = N'hrp')      
     EXEC (N'CREATE SCHEMA hrp')                                   
 GO                                                               

USE MIS
GO
IF  EXISTS (SELECT * FROM sys.objects so JOIN sys.schemas sc ON so.schema_id = sc.schema_id WHERE so.name = N'EHRPHRA12_PKG$GETCOUNTDOCSUPHRS_FUN$IMPL'  AND sc.name=N'hrp'  AND type in (N'P',N'PC'))
 DROP PROCEDURE [hrp].[EHRPHRA12_PKG$GETCOUNTDOCSUPHRS_FUN$IMPL]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE HRP.EHRPHRA12_PKG$GETCOUNTDOCSUPHRS_FUN$IMPL  
   @P_START_DATE varchar(max),
   @P_START_TIME varchar(max),
   @P_END_DATE varchar(max),
   @P_END_TIME varchar(max),
   /*
   *   SSMA warning messages:
   *   O2SS0356: Conversion from NUMBER datatype can cause data loss.
   */

   @return_value_argument float(53)  OUTPUT
AS 
   BEGIN

      EXECUTE ssma_oracle.db_fn_check_init_package 'HRP', 'EHRPHRA12_PKG'

      DECLARE
         @SSTARTDATE varchar(10) = @P_START_DATE, 
         @SSTARTTIME varchar(4) = @P_START_TIME, 
         @SENDDATE varchar(10) = @P_END_DATE, 
         @SENDTIME varchar(10) = @P_END_TIME, 
         @CNTMIN numeric(5), 
         @NCNT int, 
         @ISTIME varchar(4), 
         @IETIME varchar(4)

      SET @CNTMIN = 0

      /*是否為假日*/
      BEGIN

         BEGIN TRY
            SELECT @NCNT = count_big(*)
            FROM HRP.HRA_HOLIDAY
            WHERE 
               ssma_oracle.to_char_date(HRA_HOLIDAY.HOLI_DATE, 'yyyy-mm-dd') = @SSTARTDATE AND 
               HRA_HOLIDAY.STOP_WORK = 'Y' AND 
               HRA_HOLIDAY.HOLI_WEEK <> 'SAT'
         END TRY

         BEGIN CATCH
            BEGIN
               SET @NCNT = 0
            END
         END CATCH

      END

      IF @NCNT > 0
         GOTO CONTINUE_FOREACH1

      /*是否為週六*/
      BEGIN

         BEGIN TRY
            SELECT @NCNT = count_big(*)
            FROM HRP.HRA_HOLIDAY
            WHERE ssma_oracle.to_char_date(HRA_HOLIDAY.HOLI_DATE, 'yyyy-mm-dd') = @SSTARTDATE AND HRA_HOLIDAY.HOLI_WEEK = 'SAT'
         END TRY

         BEGIN CATCH
            BEGIN
               SET @NCNT = 0
            END
         END CATCH

      END

      /*計算時數*/
      IF @SSTARTTIME BETWEEN '0800' AND '1700'
         SET @ISTIME = @SSTARTTIME
      ELSE 
         IF @SSTARTTIME < '0800'
            SET @ISTIME = '0800'
         ELSE 
            SET @ISTIME = '0800'

      IF @SENDTIME BETWEEN '0800' AND '1700'
         SET @IETIME = @SENDTIME
      ELSE 
         IF @SENDTIME > '1700'
            SET @IETIME = '1700'
         ELSE 
            SET @IETIME = '0800'

      IF @NCNT > 0 AND @IETIME > '1200'
         /*星期六上半天*/
         SET @IETIME = '1200'

      IF @IETIME BETWEEN '1200' AND '1300'
         SET @CNTMIN = HRP.EHRPHRAFUNC_PKG$F_COUNT_TIME(ssma_oracle.to_date2(@SSTARTDATE, 'yyyy-mm-dd'), @ISTIME, ssma_oracle.to_date2(@SSTARTDATE, 'yyyy-mm-dd'), '1200')
      ELSE 
         IF @IETIME BETWEEN '1300' AND '1700' AND @SSTARTTIME <= '1200'
            BEGIN

               SET @CNTMIN = HRP.EHRPHRAFUNC_PKG$F_COUNT_TIME(ssma_oracle.to_date2(@SSTARTDATE, 'yyyy-mm-dd'), @ISTIME, ssma_oracle.to_date2(@SSTARTDATE, 'yyyy-mm-dd'), @IETIME)

               SET @CNTMIN = @CNTMIN - 60

            END
         ELSE 
            IF @IETIME BETWEEN '1300' AND '1700' AND @SSTARTTIME >= '1300'
               SET @CNTMIN = HRP.EHRPHRAFUNC_PKG$F_COUNT_TIME(ssma_oracle.to_date2(@SSTARTDATE, 'yyyy-mm-dd'), @ISTIME, ssma_oracle.to_date2(@SSTARTDATE, 'yyyy-mm-dd'), @IETIME)
            ELSE 
               BEGIN
                  IF @IETIME BETWEEN '0800' AND '1200'
                     SET @CNTMIN = HRP.EHRPHRAFUNC_PKG$F_COUNT_TIME(ssma_oracle.to_date2(@SSTARTDATE, 'yyyy-mm-dd'), @ISTIME, ssma_oracle.to_date2(@SSTARTDATE, 'yyyy-mm-dd'), @IETIME)
               END

      DECLARE
         @db_null_statement int

      CONTINUE_FOREACH1:

      DECLARE
         @db_null_statement$2 int

      SET @return_value_argument = @CNTMIN

      RETURN 

   END
GO
BEGIN TRY
    EXEC sp_addextendedproperty
        N'MS_SSMA_SOURCE', N'HRP.EHRPHRA12_PKG.getCountDocSUPhrs_fun',
        N'SCHEMA', N'hrp',
        N'PROCEDURE', N'EHRPHRA12_PKG$GETCOUNTDOCSUPHRS_FUN$IMPL'
END TRY
BEGIN CATCH
    IF (@@TRANCOUNT > 0) ROLLBACK
    PRINT ERROR_MESSAGE()
END CATCH
GO
