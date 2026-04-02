
USE MIS
GO
 IF NOT EXISTS(SELECT * FROM sys.schemas WHERE [name] = N'hrp')      
     EXEC (N'CREATE SCHEMA hrp')                                   
 GO                                                               

USE MIS
GO
IF  EXISTS (SELECT * FROM sys.objects so JOIN sys.schemas sc ON so.schema_id = sc.schema_id WHERE so.name = N'EHRPHRAFUNC_PKG$F_GETVACTIME$IMPL'  AND sc.name=N'hrp'  AND type in (N'P',N'PC'))
 DROP PROCEDURE [hrp].[EHRPHRAFUNC_PKG$F_GETVACTIME$IMPL]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE HRP.EHRPHRAFUNC_PKG$F_GETVACTIME$IMPL  
   @EMPNO_IN varchar(max),
   @STRATDATE_IN varchar(max),
   @STARTTIME_IN varchar(max),
   @ORGANTYPE_IN varchar(max),
   @ENDTIME_IN varchar(max),
   /*
   *   SSMA warning messages:
   *   O2SS0356: Conversion from NUMBER datatype can cause data loss.
   */

   @return_value_argument float(53)  OUTPUT
AS 
   BEGIN

      EXECUTE ssma_oracle.db_fn_check_init_package 'HRP', 'EHRPHRAFUNC_PKG'

      DECLARE
         @SORGANTYPE varchar(10) = @ORGANTYPE_IN, 
         @NRESULTS numeric(4), 
         @SEMPNO varchar(20) = @EMPNO_IN, 
         @SSTARTDATE datetime2(0) = ssma_oracle.to_date2(@STRATDATE_IN, 'YYYY-MM-DD'), 
         @SSTARTTIME varchar(4) = @STARTTIME_IN, 
         @SENDTIME varchar(4) = @ENDTIME_IN, 
         @ICLASSCODE varchar(3), 
         
         /*
         *     iSCH VARCHAR2(6) := 'SCH_'||substr(to_char(sStartDate,'yyyy-mm-dd'), 9, 10);
         *   iSCH_YM VARCHAR2(7) :=to_char(sStartDate,'yyyy-mm');
         *   時段一
         */
         @ICHKIN_WKTM1 varchar(4), 
         @ICHKOUT_WKTM1 varchar(4), 
         @ISTART_REST1 varchar(4), 
         @IEND_REST1 varchar(4), 
         /*時段二*/
         @ICHKIN_WKTM2 varchar(4), 
         @ICHKOUT_WKTM2 varchar(4), 
         @ISTART_REST2 varchar(4), 
         @IEND_REST2 varchar(4), 
         /*時段三*/
         @ICHKIN_WKTM3 varchar(4), 
         @ICHKOUT_WKTM3 varchar(4), 
         @ISTART_REST3 varchar(4), 
         @IEND_REST3 varchar(4), 
         @SSHIFT varchar(3)

      SET @NRESULTS = 0

      SET @ICLASSCODE = HRP.EHRPHRAFUNC_PKG$F_GETCLASSKIND(@SEMPNO, @SSTARTDATE, @SORGANTYPE)

      
      /*
      *    IF iClassCode='N/A' OR iClassCode='ZZ' then 20161219 班表新增  ZY,ZX
      *   20180214 取消ZZ限制 108978
      */
      IF @ICLASSCODE = 'N/A' OR @ICLASSCODE IN ( 'ZY', 'ZX' )
         BEGIN

            SET @NRESULTS = 0/*無排班*/

            SET @return_value_argument = @NRESULTS

            RETURN 

         END

      /*時段一*/
      BEGIN

         BEGIN TRY
            SELECT @ICHKIN_WKTM1 = HRA_CLASSDTL.CHKIN_WKTM, @ICHKOUT_WKTM1 = HRA_CLASSDTL.CHKOUT_WKTM, @ISTART_REST1 = HRA_CLASSDTL.START_REST, @IEND_REST1 = HRA_CLASSDTL.END_REST
            FROM HRP.HRA_CLASSDTL
            WHERE HRA_CLASSDTL.CLASS_CODE = @ICLASSCODE AND HRA_CLASSDTL.SHIFT_NO = '1'
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

                  SET @ICHKIN_WKTM1 = '0000'

                  SET @ICHKOUT_WKTM1 = '0000'

                  SET @ISTART_REST1 = '0000'

                  SET @IEND_REST1 = '0000'

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

      /*時段二*/
      BEGIN

         BEGIN TRY
            SELECT @ICHKIN_WKTM2 = HRA_CLASSDTL.CHKIN_WKTM, @ICHKOUT_WKTM2 = HRA_CLASSDTL.CHKOUT_WKTM, @ISTART_REST2 = HRA_CLASSDTL.START_REST, @IEND_REST2 = HRA_CLASSDTL.END_REST
            FROM HRP.HRA_CLASSDTL
            WHERE HRA_CLASSDTL.CLASS_CODE = @ICLASSCODE AND HRA_CLASSDTL.SHIFT_NO = '2'
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
               BEGIN

                  SET @ICHKIN_WKTM2 = '0000'

                  SET @ICHKOUT_WKTM2 = '0000'

                  SET @ISTART_REST2 = '0000'

                  SET @IEND_REST2 = '0000'

               END
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

      /*時段三*/
      BEGIN

         BEGIN TRY
            SELECT @ICHKIN_WKTM3 = HRA_CLASSDTL.CHKIN_WKTM, @ICHKOUT_WKTM3 = HRA_CLASSDTL.CHKOUT_WKTM, @ISTART_REST3 = HRA_CLASSDTL.START_REST, @IEND_REST3 = HRA_CLASSDTL.END_REST
            FROM HRP.HRA_CLASSDTL
            WHERE HRA_CLASSDTL.CLASS_CODE = @ICLASSCODE AND HRA_CLASSDTL.SHIFT_NO = '3'
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
               BEGIN

                  SET @ICHKIN_WKTM3 = '0000'

                  SET @ICHKOUT_WKTM3 = '0000'

                  SET @ISTART_REST3 = '0000'

                  SET @IEND_REST3 = '0000'

               END
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

      
      /*
      *       判斷 START_TIME ~ END_TIME 恆跨那幾個時段
      *       因為此程式僅能判斷當天,故時段一定是由小至大
      *   
      *       have RS and RE
      *       EE <=  RS
      *       EE > RS AND ES <=RE
      *       EE > RE AND ES < CE
      *       EE >= CE
      *       
      *       
      *       No have RS and RE
      *       EE < CE
      *       EE >= CE
      *
      *   取得該段時間所橫跨的時段
      */
      SET @SSHIFT = HRP.EHRPHRAFUNC_PKG$F_GETSHIFT(@ICLASSCODE, @SSTARTTIME, @SENDTIME)

      IF @SSHIFT IS NOT NULL AND @SSHIFT != ''
         BEGIN

            DECLARE
               @I int

            SET @I = 1

            DECLARE
               @loop$bound int

            SET @loop$bound = ssma_oracle.length_varchar(@SSHIFT)

            WHILE @I <= @loop$bound
            
               BEGIN

                  /*
                  *   SSMA warning messages:
                  *   O2SS0273: Oracle SUBSTR function and SQL Server SUBSTRING function may give different results.
                  */

                  IF substring(@SSHIFT, @I, 1) = '1'
                     IF @ISTART_REST1 = '0'
                        /*沒有休息時間*/
                        IF @SSTARTTIME >= @ICHKIN_WKTM1
                           IF @SENDTIME >= @ICHKOUT_WKTM1
                              SET @NRESULTS = HRP.EHRPHRAFUNC_PKG$F_COUNT_TIME(@SSTARTDATE, @SSTARTTIME, @SSTARTDATE, @ICHKOUT_WKTM1)
                           ELSE 
                              SET @NRESULTS = HRP.EHRPHRAFUNC_PKG$F_COUNT_TIME(@SSTARTDATE, @SSTARTTIME, @SSTARTDATE, @SENDTIME)
                        ELSE 
                           IF @SENDTIME >= @ICHKOUT_WKTM1
                              SET @NRESULTS = HRP.EHRPHRAFUNC_PKG$F_COUNT_TIME(@SSTARTDATE, @ICHKIN_WKTM1, @SSTARTDATE, @ICHKOUT_WKTM1)
                           ELSE 
                              SET @NRESULTS = HRP.EHRPHRAFUNC_PKG$F_COUNT_TIME(@SSTARTDATE, @ICHKIN_WKTM1, @SSTARTDATE, @SENDTIME)
                     ELSE 
                        /*有休息時間*/
                        IF @SSTARTTIME >= @ICHKIN_WKTM1
                           IF @SSTARTTIME < @ISTART_REST1
                              IF @SENDTIME <= @ISTART_REST1
                                 SET @NRESULTS = HRP.EHRPHRAFUNC_PKG$F_COUNT_TIME(@SSTARTDATE, @SSTARTTIME, @SSTARTDATE, @SENDTIME)
                              ELSE 
                                 IF @SENDTIME BETWEEN @ISTART_REST1 AND @IEND_REST1
                                    SET @NRESULTS = HRP.EHRPHRAFUNC_PKG$F_COUNT_TIME(@SSTARTDATE, @SSTARTTIME, @SSTARTDATE, @ISTART_REST1)
                                 ELSE 
                                    IF @SENDTIME BETWEEN @IEND_REST1 AND @ICHKOUT_WKTM1
                                       SET @NRESULTS = HRP.EHRPHRAFUNC_PKG$F_COUNT_TIME(@SSTARTDATE, @SSTARTTIME, @SSTARTDATE, @ISTART_REST1) + HRP.EHRPHRAFUNC_PKG$F_COUNT_TIME(@SSTARTDATE, @IEND_REST1, @SSTARTDATE, @SENDTIME)
                                    ELSE 
                                       SET @NRESULTS = HRP.EHRPHRAFUNC_PKG$F_COUNT_TIME(@SSTARTDATE, @SSTARTTIME, @SSTARTDATE, @ISTART_REST1) + HRP.EHRPHRAFUNC_PKG$F_COUNT_TIME(@SSTARTDATE, @IEND_REST1, @SSTARTDATE, @ICHKOUT_WKTM1)
                           ELSE 
                              IF @SSTARTTIME BETWEEN @ISTART_REST1 AND @IEND_REST1
                                 IF @SENDTIME BETWEEN @ISTART_REST1 AND @IEND_REST1
                                    SET @NRESULTS = 0
                                 ELSE 
                                    IF @SENDTIME <= @ICHKOUT_WKTM1
                                       SET @NRESULTS = HRP.EHRPHRAFUNC_PKG$F_COUNT_TIME(@SSTARTDATE, @IEND_REST1, @SSTARTDATE, @SENDTIME)
                                    ELSE 
                                       SET @NRESULTS = HRP.EHRPHRAFUNC_PKG$F_COUNT_TIME(@SSTARTDATE, @IEND_REST1, @SSTARTDATE, @ICHKOUT_WKTM1)
                              ELSE 
                                 IF @SENDTIME <= @ICHKOUT_WKTM1
                                    SET @NRESULTS = HRP.EHRPHRAFUNC_PKG$F_COUNT_TIME(@SSTARTDATE, @SSTARTTIME, @SSTARTDATE, @SENDTIME)
                                 ELSE 
                                    SET @NRESULTS = HRP.EHRPHRAFUNC_PKG$F_COUNT_TIME(@SSTARTDATE, @SSTARTTIME, @SSTARTDATE, @ICHKOUT_WKTM1)
                        /*比上班時間早 BASE ON iChkin_wktm1*/
                        ELSE 
                           IF @SENDTIME <= @ISTART_REST1
                              SET @NRESULTS = HRP.EHRPHRAFUNC_PKG$F_COUNT_TIME(@SSTARTDATE, @ICHKIN_WKTM1, @SSTARTDATE, @SENDTIME)
                           ELSE 
                              IF @SENDTIME BETWEEN @ISTART_REST1 AND @IEND_REST1
                                 SET @NRESULTS = HRP.EHRPHRAFUNC_PKG$F_COUNT_TIME(@SSTARTDATE, @ICHKIN_WKTM1, @SSTARTDATE, @ISTART_REST1)
                              ELSE 
                                 IF @SENDTIME BETWEEN @IEND_REST1 AND @ICHKOUT_WKTM1
                                    SET @NRESULTS = HRP.EHRPHRAFUNC_PKG$F_COUNT_TIME(@SSTARTDATE, @ICHKIN_WKTM1, @SSTARTDATE, @ISTART_REST1) + HRP.EHRPHRAFUNC_PKG$F_COUNT_TIME(@SSTARTDATE, @IEND_REST1, @SSTARTDATE, @SENDTIME)
                                 ELSE 
                                    SET @NRESULTS = HRP.EHRPHRAFUNC_PKG$F_COUNT_TIME(@SSTARTDATE, @ICHKIN_WKTM1, @SSTARTDATE, @ISTART_REST1) + HRP.EHRPHRAFUNC_PKG$F_COUNT_TIME(@SSTARTDATE, @IEND_REST1, @SSTARTDATE, @ICHKOUT_WKTM1)
                  ELSE 
                     /*
                     *   SSMA warning messages:
                     *   O2SS0273: Oracle SUBSTR function and SQL Server SUBSTRING function may give different results.
                     */

                     IF substring(@SSHIFT, @I, 1) = '2'
                        IF @ISTART_REST2 = '0'
                           /*沒有休息時間*/
                           IF @SSTARTTIME >= @ICHKIN_WKTM2
                              IF @SENDTIME >= @ICHKOUT_WKTM2
                                 SET @NRESULTS = HRP.EHRPHRAFUNC_PKG$F_COUNT_TIME(@SSTARTDATE, @SSTARTTIME, @SSTARTDATE, @ICHKOUT_WKTM2)
                              ELSE 
                                 SET @NRESULTS = HRP.EHRPHRAFUNC_PKG$F_COUNT_TIME(@SSTARTDATE, @SSTARTTIME, @SSTARTDATE, @SENDTIME)
                           ELSE 
                              IF @SENDTIME >= @ICHKOUT_WKTM2
                                 SET @NRESULTS = HRP.EHRPHRAFUNC_PKG$F_COUNT_TIME(@SSTARTDATE, @ICHKIN_WKTM2, @SSTARTDATE, @ICHKOUT_WKTM2)
                              ELSE 
                                 SET @NRESULTS = HRP.EHRPHRAFUNC_PKG$F_COUNT_TIME(@SSTARTDATE, @ICHKIN_WKTM2, @SSTARTDATE, @SENDTIME)
                        ELSE 
                           /*有休息時間*/
                           IF @SSTARTTIME >= @ICHKIN_WKTM2
                              IF @SSTARTTIME < @ISTART_REST2
                                 IF @SENDTIME <= @ISTART_REST2
                                    SET @NRESULTS = HRP.EHRPHRAFUNC_PKG$F_COUNT_TIME(@SSTARTDATE, @SSTARTTIME, @SSTARTDATE, @SENDTIME)
                                 ELSE 
                                    IF @SENDTIME BETWEEN @ISTART_REST2 AND @IEND_REST2
                                       SET @NRESULTS = HRP.EHRPHRAFUNC_PKG$F_COUNT_TIME(@SSTARTDATE, @SSTARTTIME, @SSTARTDATE, @ISTART_REST2)
                                    ELSE 
                                       IF @SENDTIME BETWEEN @IEND_REST2 AND @ICHKOUT_WKTM2
                                          SET @NRESULTS = HRP.EHRPHRAFUNC_PKG$F_COUNT_TIME(@SSTARTDATE, @SSTARTTIME, @SSTARTDATE, @ISTART_REST2) + HRP.EHRPHRAFUNC_PKG$F_COUNT_TIME(@SSTARTDATE, @IEND_REST2, @SSTARTDATE, @SENDTIME)
                                       ELSE 
                                          SET @NRESULTS = HRP.EHRPHRAFUNC_PKG$F_COUNT_TIME(@SSTARTDATE, @SSTARTTIME, @SSTARTDATE, @ISTART_REST2) + HRP.EHRPHRAFUNC_PKG$F_COUNT_TIME(@SSTARTDATE, @IEND_REST2, @SSTARTDATE, @ICHKOUT_WKTM2)
                              ELSE 
                                 IF @SSTARTTIME BETWEEN @ISTART_REST2 AND @IEND_REST2
                                    IF @SENDTIME BETWEEN @ISTART_REST2 AND @IEND_REST2
                                       SET @NRESULTS = 0
                                    ELSE 
                                       IF @SENDTIME <= @ICHKOUT_WKTM2
                                          SET @NRESULTS = HRP.EHRPHRAFUNC_PKG$F_COUNT_TIME(@SSTARTDATE, @IEND_REST2, @SSTARTDATE, @SENDTIME)
                                       ELSE 
                                          SET @NRESULTS = HRP.EHRPHRAFUNC_PKG$F_COUNT_TIME(@SSTARTDATE, @IEND_REST2, @SSTARTDATE, @ICHKOUT_WKTM2)
                                 ELSE 
                                    IF @SENDTIME <= @ICHKOUT_WKTM2
                                       SET @NRESULTS = HRP.EHRPHRAFUNC_PKG$F_COUNT_TIME(@SSTARTDATE, @SSTARTTIME, @SSTARTDATE, @SENDTIME)
                                    ELSE 
                                       SET @NRESULTS = HRP.EHRPHRAFUNC_PKG$F_COUNT_TIME(@SSTARTDATE, @SSTARTTIME, @SSTARTDATE, @ICHKOUT_WKTM2)
                           /*比上班時間早 BASE ON iChkin_wktm2*/
                           ELSE 
                              IF @SENDTIME <= @ISTART_REST2
                                 SET @NRESULTS = HRP.EHRPHRAFUNC_PKG$F_COUNT_TIME(@SSTARTDATE, @ICHKIN_WKTM2, @SSTARTDATE, @SENDTIME)
                              ELSE 
                                 IF @SENDTIME BETWEEN @ISTART_REST2 AND @IEND_REST2
                                    SET @NRESULTS = HRP.EHRPHRAFUNC_PKG$F_COUNT_TIME(@SSTARTDATE, @ICHKIN_WKTM2, @SSTARTDATE, @ISTART_REST2)
                                 ELSE 
                                    IF @SENDTIME BETWEEN @IEND_REST2 AND @ICHKOUT_WKTM2
                                       SET @NRESULTS = HRP.EHRPHRAFUNC_PKG$F_COUNT_TIME(@SSTARTDATE, @ICHKIN_WKTM2, @SSTARTDATE, @ISTART_REST2) + HRP.EHRPHRAFUNC_PKG$F_COUNT_TIME(@SSTARTDATE, @IEND_REST2, @SSTARTDATE, @SENDTIME)
                                    ELSE 
                                       SET @NRESULTS = HRP.EHRPHRAFUNC_PKG$F_COUNT_TIME(@SSTARTDATE, @ICHKIN_WKTM2, @SSTARTDATE, @ISTART_REST2) + HRP.EHRPHRAFUNC_PKG$F_COUNT_TIME(@SSTARTDATE, @IEND_REST2, @SSTARTDATE, @ICHKOUT_WKTM2)
                     ELSE 
                        BEGIN
                           /*
                           *   SSMA warning messages:
                           *   O2SS0273: Oracle SUBSTR function and SQL Server SUBSTRING function may give different results.
                           */

                           IF substring(@SSHIFT, @I, 1) = '3'
                              IF @ISTART_REST3 = '0'
                                 /*沒有休息時間*/
                                 IF @SSTARTTIME >= @ICHKIN_WKTM3
                                    IF @SENDTIME >= @ICHKOUT_WKTM3
                                       SET @NRESULTS = HRP.EHRPHRAFUNC_PKG$F_COUNT_TIME(@SSTARTDATE, @SSTARTTIME, @SSTARTDATE, @ICHKOUT_WKTM3)
                                    ELSE 
                                       SET @NRESULTS = HRP.EHRPHRAFUNC_PKG$F_COUNT_TIME(@SSTARTDATE, @SSTARTTIME, @SSTARTDATE, @SENDTIME)
                                 ELSE 
                                    IF @SENDTIME >= @ICHKOUT_WKTM3
                                       SET @NRESULTS = HRP.EHRPHRAFUNC_PKG$F_COUNT_TIME(@SSTARTDATE, @ICHKIN_WKTM3, @SSTARTDATE, @ICHKOUT_WKTM3)
                                    ELSE 
                                       SET @NRESULTS = HRP.EHRPHRAFUNC_PKG$F_COUNT_TIME(@SSTARTDATE, @ICHKIN_WKTM3, @SSTARTDATE, @SENDTIME)
                              ELSE 
                                 /*有休息時間*/
                                 IF @SSTARTTIME >= @ICHKIN_WKTM3
                                    IF @SSTARTTIME < @ISTART_REST3
                                       IF @SENDTIME <= @ISTART_REST3
                                          SET @NRESULTS = HRP.EHRPHRAFUNC_PKG$F_COUNT_TIME(@SSTARTDATE, @SSTARTTIME, @SSTARTDATE, @SENDTIME)
                                       ELSE 
                                          IF @SENDTIME BETWEEN @ISTART_REST3 AND @IEND_REST3
                                             SET @NRESULTS = HRP.EHRPHRAFUNC_PKG$F_COUNT_TIME(@SSTARTDATE, @SSTARTTIME, @SSTARTDATE, @ISTART_REST3)
                                          ELSE 
                                             IF @SENDTIME BETWEEN @IEND_REST3 AND @ICHKOUT_WKTM3
                                                SET @NRESULTS = HRP.EHRPHRAFUNC_PKG$F_COUNT_TIME(@SSTARTDATE, @SSTARTTIME, @SSTARTDATE, @ISTART_REST3) + HRP.EHRPHRAFUNC_PKG$F_COUNT_TIME(@SSTARTDATE, @IEND_REST3, @SSTARTDATE, @SENDTIME)
                                             ELSE 
                                                SET @NRESULTS = HRP.EHRPHRAFUNC_PKG$F_COUNT_TIME(@SSTARTDATE, @SSTARTTIME, @SSTARTDATE, @ISTART_REST3) + HRP.EHRPHRAFUNC_PKG$F_COUNT_TIME(@SSTARTDATE, @IEND_REST3, @SSTARTDATE, @ICHKOUT_WKTM3)
                                    ELSE 
                                       IF @SSTARTTIME BETWEEN @ISTART_REST3 AND @IEND_REST3
                                          IF @SENDTIME BETWEEN @ISTART_REST3 AND @IEND_REST3
                                             SET @NRESULTS = 0
                                          ELSE 
                                             IF @SENDTIME <= @ICHKOUT_WKTM3
                                                SET @NRESULTS = HRP.EHRPHRAFUNC_PKG$F_COUNT_TIME(@SSTARTDATE, @IEND_REST3, @SSTARTDATE, @SENDTIME)
                                             ELSE 
                                                SET @NRESULTS = HRP.EHRPHRAFUNC_PKG$F_COUNT_TIME(@SSTARTDATE, @IEND_REST3, @SSTARTDATE, @ICHKOUT_WKTM3)
                                       ELSE 
                                          IF @SENDTIME <= @ICHKOUT_WKTM3
                                             SET @NRESULTS = HRP.EHRPHRAFUNC_PKG$F_COUNT_TIME(@SSTARTDATE, @SSTARTTIME, @SSTARTDATE, @SENDTIME)
                                          ELSE 
                                             SET @NRESULTS = HRP.EHRPHRAFUNC_PKG$F_COUNT_TIME(@SSTARTDATE, @SSTARTTIME, @SSTARTDATE, @ICHKOUT_WKTM3)
                                 /*比上班時間早 BASE ON iChkin_wktm3*/
                                 ELSE 
                                    IF @SENDTIME <= @ISTART_REST3
                                       SET @NRESULTS = HRP.EHRPHRAFUNC_PKG$F_COUNT_TIME(@SSTARTDATE, @ICHKIN_WKTM3, @SSTARTDATE, @SENDTIME)
                                    ELSE 
                                       IF @SENDTIME BETWEEN @ISTART_REST3 AND @IEND_REST3
                                          SET @NRESULTS = HRP.EHRPHRAFUNC_PKG$F_COUNT_TIME(@SSTARTDATE, @ICHKIN_WKTM3, @SSTARTDATE, @ISTART_REST3)
                                       ELSE 
                                          IF @SENDTIME BETWEEN @IEND_REST3 AND @ICHKOUT_WKTM3
                                             SET @NRESULTS = HRP.EHRPHRAFUNC_PKG$F_COUNT_TIME(@SSTARTDATE, @ICHKIN_WKTM3, @SSTARTDATE, @ISTART_REST3) + HRP.EHRPHRAFUNC_PKG$F_COUNT_TIME(@SSTARTDATE, @IEND_REST3, @SSTARTDATE, @SENDTIME)
                                          ELSE 
                                             SET @NRESULTS = HRP.EHRPHRAFUNC_PKG$F_COUNT_TIME(@SSTARTDATE, @ICHKIN_WKTM3, @SSTARTDATE, @ISTART_REST3) + HRP.EHRPHRAFUNC_PKG$F_COUNT_TIME(@SSTARTDATE, @IEND_REST3, @SSTARTDATE, @ICHKOUT_WKTM3)
                        END

                  SET @I = @I + 1

               END

         END
      ELSE 
         SET @NRESULTS = 0

      SET @return_value_argument = @NRESULTS

      
      /*
      *   
      *           FOR I IN 1..LENGTH(sShift) LOOP
      *           sShift :=0;
      *           END LOOP;
      *
      */
      RETURN 

      DECLARE
         @db_null_statement int

   END
GO
BEGIN TRY
    EXEC sp_addextendedproperty
        N'MS_SSMA_SOURCE', N'HRP.EHRPHRAFUNC_PKG.F_GETVACTIME',
        N'SCHEMA', N'hrp',
        N'PROCEDURE', N'EHRPHRAFUNC_PKG$F_GETVACTIME$IMPL'
END TRY
BEGIN CATCH
    IF (@@TRANCOUNT > 0) ROLLBACK
    PRINT ERROR_MESSAGE()
END CATCH
GO
