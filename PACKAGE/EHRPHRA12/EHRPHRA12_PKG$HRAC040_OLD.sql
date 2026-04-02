
USE MIS
GO
 IF NOT EXISTS(SELECT * FROM sys.schemas WHERE [name] = N'hrp')      
     EXEC (N'CREATE SCHEMA hrp')                                   
 GO                                                               

USE MIS
GO
IF  EXISTS (SELECT * FROM sys.objects so JOIN sys.schemas sc ON so.schema_id = sc.schema_id WHERE so.name = N'EHRPHRA12_PKG$HRAC040_OLD'  AND sc.name=N'hrp'  AND type in (N'P',N'PC'))
 DROP PROCEDURE [hrp].[EHRPHRA12_PKG$HRAC040_OLD]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE HRP.EHRPHRA12_PKG$HRAC040_OLD  
   @P_EMP_NO varchar(max),
   @P_UNCARD_DATE varchar(max),
   @P_UNCARD_TIME varchar(max),
   @ORGANTYPE_IN varchar(max),
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
         @SEMPNO varchar(10) = @P_EMP_NO, 
         @SUNCARDDATE varchar(20) = @P_UNCARD_DATE, 
         @SUNCARDTIME varchar(20) = @P_UNCARD_TIME, 
         @SORGANTYPE varchar(10) = @ORGANTYPE_IN, 
         @ICLASTIME_IN varchar(4), 
         @ICLASTIME_OUT varchar(4), 
         @SCLASSCODE varchar(4), 
         @SSHIFT_NO varchar(2), 
         @ICNT int, 
         @ICONTI bit, 
         @ICHECK int

      SET @RTNCODE = 0

      SET @ICNT = 0

      SET @ICONTI = 1

      SET @ICHECK = 0

      IF ssma_oracle.to_date2(@SUNCARDDATE, 'YYYY-MM-DD') > sysdatetime()
         BEGIN

            SET @RTNCODE = 2

            SET @ICONTI = 0

         END

      
      /*
      *   2014-02-13 忘打卡鎖七日 by weichun 3/3 open
      *   2014-04-29 要求關閉七日限制
      *     if (iconti) THEN
      *         IF TRUNC(SYSDATE) >= TO_DATE(sUnCardDate,'YYYY-MM-DD')+7 THEN
      *            RtnCode := 3 ;
      *            iconti := false;
      *         END IF;
      *       END IF;
      *   2016-11-24 忘打卡鎖14日 by ed102674
      */
      IF (@ICONTI != 0)
         BEGIN
            
            /*
            *   IF TRUNC(SYSDATE) >= TO_DATE(sUnCardDate,'YYYY-MM-DD')+14 THEN
            *            RtnCode := 3 ;
            *            iconti := false;
            *         END IF;
            *   20210113 by108482 申請不卡14天申請期限,超過五天才申請違規記點
            *   20210204 by108482 每月申請最多至隔月5號(5號當天可以申請)
            */
            IF ssma_oracle.trunc_date(sysdatetime()) > ssma_oracle.trunc_date2(dateadd(m, 1, CONVERT(datetime2, @SUNCARDDATE, 111)), 'mm') + 4
               BEGIN

                  
                  /*
                  *   IF SYSDATE > trunc(ADD_MONTHS(TO_DATE(sUnCardDate, 'yyyy/mm/dd'), 1), 'mm') + 2 + 13.5 / 24 THEN --20211202 因考核結算,11月份申請期限至12/3 13:30止
                  *   IF trunc(SYSDATE) > trunc(ADD_MONTHS(TO_DATE(sUnCardDate, 'yyyy/mm/dd'), 1), 'mm') +7 THEN --20220406 因4月份國定連假,延長3月份出勤申請期限至8號
                  */
                  SET @RTNCODE = 3

                  SET @ICONTI = 0

               END
         END

      
      /*
      *   IF (iconti) THEN
      *         SELECT COUNT(*)
      *           INTO iCheck
      *           FROM hra_uncard
      *          WHERE to_char(hra_uncard.class_date,'yyyy-mm-dd') = sUnCardDate
      *            AND hra_uncard.uncard_time = sUnCardTime;
      *         IF iCheck <> 0 THEN
      *           RtnCode := 4;
      *           iconti := FALSE;
      *         END IF;
      *       END IF;
      */
      IF (@ICONTI != 0)
         BEGIN

            SET @SCLASSCODE = HRP.EHRPHRAFUNC_PKG$F_GETCLASSKIND(@SEMPNO, ssma_oracle.to_date2(@SUNCARDDATE, 'yyyy-mm-dd'), @SORGANTYPE)

            IF @SUNCARDTIME = 'A1' OR @SUNCARDTIME = 'A2'
               SET @SSHIFT_NO = 1
            ELSE 
               IF @SUNCARDTIME = 'B1' OR @SUNCARDTIME = 'B2'
                  SET @SSHIFT_NO = 2
               ELSE 
                  BEGIN
                     IF @SUNCARDTIME = 'C1' OR @SUNCARDTIME = 'C2'
                        SET @SSHIFT_NO = 3
                  END

            BEGIN

               BEGIN TRY
                  SELECT @ICLASTIME_IN = HRA_CLASSDTL.CHKIN_WKTM, @ICLASTIME_OUT = HRA_CLASSDTL.CHKOUT_WKTM
                  FROM HRP.HRA_CLASSDTL
                  WHERE HRA_CLASSDTL.CLASS_CODE = @SCLASSCODE AND HRA_CLASSDTL.SHIFT_NO = @SSHIFT_NO
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
                     SET @ICNT = 1
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

            IF @ICNT = 0
               BEGIN

                  SET @SSHIFT_NO = substring(@SUNCARDTIME, 2, 1)

                  IF @SSHIFT_NO = 1
                     BEGIN
                        IF ssma_oracle.to_date2(ISNULL(@SUNCARDDATE, '') + ISNULL(@ICLASTIME_IN, ''), 'YYYY-MM-DDHH24MI') > sysdatetime()
                           SET @RTNCODE = 2/*iconti := false;*/
                     END
                  ELSE 
                     BEGIN
                        IF @SSHIFT_NO = 2
                           BEGIN
                              IF ssma_oracle.to_date2(ISNULL(@SUNCARDDATE, '') + ISNULL(@ICLASTIME_OUT, ''), 'YYYY-MM-DDHH24MI') > sysdatetime()
                                 SET @RTNCODE = 2/*iconti := false;*/
                           END
                     END

               END

         END

   END
GO
BEGIN TRY
    EXEC sp_addextendedproperty
        N'MS_SSMA_SOURCE', N'HRP.EHRPHRA12_PKG.hraC040_old',
        N'SCHEMA', N'hrp',
        N'PROCEDURE', N'EHRPHRA12_PKG$HRAC040_OLD'
END TRY
BEGIN CATCH
    IF (@@TRANCOUNT > 0) ROLLBACK
    PRINT ERROR_MESSAGE()
END CATCH
GO
