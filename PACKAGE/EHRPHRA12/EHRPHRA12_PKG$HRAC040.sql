
USE MIS
GO
 IF NOT EXISTS(SELECT * FROM sys.schemas WHERE [name] = N'hrp')      
     EXEC (N'CREATE SCHEMA hrp')                                   
 GO                                                               

USE MIS
GO
IF  EXISTS (SELECT * FROM sys.objects so JOIN sys.schemas sc ON so.schema_id = sc.schema_id WHERE so.name = N'EHRPHRA12_PKG$HRAC040'  AND sc.name=N'hrp'  AND type in (N'P',N'PC'))
 DROP PROCEDURE [hrp].[EHRPHRA12_PKG$HRAC040]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE HRP.EHRPHRA12_PKG$HRAC040  
   @P_EMP_NO varchar(max),
   @P_UNCARD_DATE varchar(max),
   @P_UNCARD_TIME varchar(max),
   @P_UNCARD_POIN varchar(max),
   @P_UNCARD_REA varchar(max),
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
         @SUNCARDPOIN varchar(10) = @P_UNCARD_POIN, 
         @SUNCARDREA varchar(10) = @P_UNCARD_REA, 
         @SORGANTYPE varchar(10) = @ORGANTYPE_IN, 
         @ICLASTIME_IN varchar(4), 
         @ICLASTIME_OUT varchar(4), 
         @SCLASSCODE varchar(4), 
         @SSHIFT_NO varchar(2), 
         @LIMITDAY varchar(2), 
         @ICNT int, 
         @ICONTI bit, 
         @ICHECK int, 
         /*
         *   SSMA warning messages:
         *   O2SS0356: Conversion from NUMBER datatype can cause data loss.
         */

         @NNUM float(53), 
         /*
         *   SSMA warning messages:
         *   O2SS0356: Conversion from NUMBER datatype can cause data loss.
         */

         @NNUMMIN float(53), 
         /*
         *   SSMA warning messages:
         *   O2SS0356: Conversion from NUMBER datatype can cause data loss.
         */

         @NNUMHRS float(53)

      SET @RTNCODE = 0

      SET @ICNT = 0

      SET @ICONTI = 1

      SET @ICHECK = 0

      IF ssma_oracle.to_date2(@SUNCARDDATE, 'YYYY-MM-DD') > sysdatetime()
         BEGIN

            SET @RTNCODE = 2

            SET @ICONTI = 0

         END

      /*搭配應出勤時段檢查在取班別之後處理*/
      IF @SUNCARDPOIN = '2400'
         BEGIN

            SET @RTNCODE = 9

            SET @ICONTI = 0

         END

      IF (@ICONTI != 0)
         BEGIN

            
            /*
            *   20210113 by108482 申請不卡14天申請期限,超過五天才申請違規記點
            *   20210204 by108482 每月申請最多至隔月5號(5號當天可以申請)
            *   20241007 by108482 每月申請最多至隔月幾號抓參數HRA89的設定
            */
            BEGIN

               BEGIN TRY
                  SELECT @LIMITDAY = HR_CODEDTL.CODE_NAME
                  FROM HRP.HR_CODEDTL
                  WHERE HR_CODEDTL.CODE_TYPE = 'HRA89' AND HR_CODEDTL.CODE_NO = 'DAY'
               END TRY

               BEGIN CATCH
                  BEGIN
                     SET @LIMITDAY = '5'
                  END
               END CATCH

            END

            
            /*
            *   IF trunc(SYSDATE) > trunc(ADD_MONTHS(TO_DATE(sUnCardDate, 'yyyy/mm/dd'), 1), 'mm') +9 THEN
            *            RtnCode := 3;
            *            iconti := FALSE;
            *         END IF;
            */
            IF ssma_oracle.trunc_date(sysdatetime()) > CONVERT(datetime2, ISNULL(ssma_oracle.to_char_date(dateadd(m, 1, CONVERT(datetime2, @SUNCARDDATE, 111)), 'YYYY-MM'), '') + '-' + ISNULL(@LIMITDAY, ''), 111)
               BEGIN

                  SET @RTNCODE = 3

                  SET @ICONTI = 0

               END

         END

      IF (@ICONTI != 0)
         BEGIN

            SELECT @ICHECK = count_big(*)
            FROM HRP.HRA_UNCARD
            WHERE 
               HRA_UNCARD.EMP_NO = @P_EMP_NO AND 
               HRA_UNCARD.CLASS_DATE = CONVERT(datetime2, @P_UNCARD_DATE, 111) AND 
               HRA_UNCARD.UNCARD_TIME = @P_UNCARD_TIME

            IF @ICHECK <> 0
               BEGIN

                  SET @RTNCODE = 4

                  SET @ICONTI = 0

               END

         END

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

            /*20250728 by108482 確認系統日時間是否已過應班時間*/
            IF @ICNT = 0
               IF @ICLASTIME_OUT < @ICLASTIME_IN
                  /*應下班小於應上班(下班日期為應班日隔天)*/
                  IF @SUNCARDTIME IN ( 'A1', 'B1', 'C1' )
                     BEGIN
                        /*上班未打卡*/
                        IF ssma_oracle.to_date2(ISNULL(@SUNCARDDATE, '') + ISNULL(@ICLASTIME_IN, ''), 'yyyy/mm/ddHH24MI') > sysdatetime()
                           BEGIN

                              SET @RTNCODE = 2

                              SET @ICONTI = 0

                           END
                     END
                  ELSE 
                     BEGIN
                        /*下班未打卡(下班日期為應班日隔天)*/
                        IF DATEADD(D, 1, ssma_oracle.to_date2(ISNULL(@SUNCARDDATE, '') + ISNULL(@ICLASTIME_OUT, ''), 'yyyy/mm/ddHH24MI')) > sysdatetime()
                           BEGIN

                              SET @RTNCODE = 2

                              SET @ICONTI = 0

                           END
                     END
               ELSE 
                  /*上下班日期皆為應班日當天*/
                  IF @SUNCARDTIME IN ( 'A1', 'B1', 'C1' )
                     BEGIN
                        /*上班未打卡*/
                        IF ssma_oracle.to_date2(ISNULL(@SUNCARDDATE, '') + ISNULL(@ICLASTIME_IN, ''), 'yyyy/mm/ddHH24MI') > sysdatetime()
                           BEGIN

                              SET @RTNCODE = 2

                              SET @ICONTI = 0

                           END
                     END
                  ELSE 
                     BEGIN
                        IF ssma_oracle.to_date2(ISNULL(@SUNCARDDATE, '') + ISNULL(@ICLASTIME_OUT, ''), 'yyyy/mm/ddHH24MI') > sysdatetime()
                           BEGIN

                              SET @RTNCODE = 2

                              SET @ICONTI = 0

                           END
                     END

            IF @ICNT = 0
               BEGIN

                  SET @SSHIFT_NO = substring(@SUNCARDTIME, 2, 1)

                  IF @SSHIFT_NO = 1
                     BEGIN

                        IF @SUNCARDPOIN IS NULL OR @SUNCARDPOIN = ''
                           SET @SUNCARDPOIN = @ICLASTIME_IN
                        ELSE 
                           BEGIN
                              IF @SUNCARDPOIN = @ICLASTIME_OUT
                                 BEGIN

                                    SET @RTNCODE = 7

                                    SET @ICONTI = 0

                                 END
                           END

                        IF ssma_oracle.to_date2(ISNULL(@SUNCARDDATE, '') + ISNULL(@ICLASTIME_IN, ''), 'YYYY-MM-DDHH24MI') > sysdatetime()
                           BEGIN

                              SET @RTNCODE = 2

                              SET @ICONTI = 0

                           END
                        ELSE 
                           IF @SCLASSCODE <> 'RN' AND ssma_oracle.to_date2(ISNULL(@SUNCARDDATE, '') + ISNULL(@SUNCARDPOIN, ''), 'YYYY-MM-DDHH24MI') > sysdatetime()
                              BEGIN

                                 SET @RTNCODE = 2

                                 SET @ICONTI = 0

                              END
                           ELSE 
                              IF 
                                 @SCLASSCODE = 'RN' AND 
                                 @SUNCARDPOIN <> @ICLASTIME_IN AND 
                                 DATEADD(D, -1, ssma_oracle.to_date2(ISNULL(@SUNCARDDATE, '') + ISNULL(@SUNCARDPOIN, ''), 'YYYY-MM-DDHH24MI')) > sysdatetime()
                                 BEGIN

                                    SET @RTNCODE = 2

                                    SET @ICONTI = 0

                                 END
                              ELSE 
                                 BEGIN

                                    
                                    /*
                                    *   確認上班打卡時間是否早於應出勤時間超過0.5小時
                                    *   20250704 by108482 確認上班打卡時間是否早於應出勤時間1分鐘
                                    */
                                    SET @NNUM = ssma_oracle.datediff(ssma_oracle.to_date2(ISNULL(@SUNCARDDATE, '') + ISNULL(@ICLASTIME_IN, ''), 'YYYY-MM-DDHH24MI'), ssma_oracle.to_date2(ISNULL(@SUNCARDDATE, '') + ISNULL(@SUNCARDPOIN, ''), 'YYYY-MM-DDHH24MI'))

                                    IF @NNUM > 0
                                       BEGIN

                                          SET @NNUMHRS = floor((@NNUM * 24 * 60) / 30) * 0.5

                                          SET @NNUMMIN = ssma_oracle.round_numeric_0(@NNUM * 24 * 60)

                                          /*IF nNumHrs >= 0.5 AND sUnCardRea IS NULL THEN*/
                                          IF @NNUMMIN >= 1 AND (@SUNCARDREA IS NULL OR @SUNCARDREA = '')
                                             BEGIN

                                                SET @RTNCODE = 5

                                                SET @ICONTI = 0

                                             END

                                          /*提前超過5小時打卡無法存檔成功*/
                                          IF @NNUMHRS >= 5
                                             BEGIN

                                                SET @RTNCODE = 6

                                                SET @ICONTI = 0

                                             END

                                       END

                                 END

                     END
                  ELSE 
                     BEGIN
                        IF @SSHIFT_NO = 2
                           BEGIN

                              IF @SUNCARDPOIN IS NULL OR @SUNCARDPOIN = ''
                                 SET @SUNCARDPOIN = @ICLASTIME_OUT
                              ELSE 
                                 BEGIN
                                    IF @SUNCARDPOIN = @ICLASTIME_IN
                                       BEGIN

                                          SET @RTNCODE = 8

                                          SET @ICONTI = 0

                                       END
                                 END

                              IF ssma_oracle.to_date2(ISNULL(@SUNCARDDATE, '') + ISNULL(@ICLASTIME_OUT, ''), 'YYYY-MM-DDHH24MI') > sysdatetime()
                                 BEGIN

                                    SET @RTNCODE = 2

                                    SET @ICONTI = 0

                                 END
                              ELSE 
                                 IF ssma_oracle.to_date2(ISNULL(@SUNCARDDATE, '') + ISNULL(@SUNCARDPOIN, ''), 'YYYY-MM-DDHH24MI') > sysdatetime()
                                    BEGIN

                                       SET @RTNCODE = 2

                                       SET @ICONTI = 0

                                    END
                                 ELSE 
                                    BEGIN

                                       /*確認JB班是否提早下班,提早下班不用判斷時差*/
                                       IF @ICLASTIME_OUT = '0000' AND substring(@SUNCARDPOIN, 1, 1) <> '0'
                                          SET @NNUM = 0
                                       ELSE 
                                          
                                          /*
                                          *   確認下班打卡時間是否晚於應出勤時間超過0.5小時
                                          *   20250704 by108482 確認下班打卡時間是否晚於應出勤時間1分鐘
                                          */
                                          IF substring(@ICLASTIME_OUT, 1, 1) = '0' AND substring(@SUNCARDPOIN, 1, 1) = '2'
                                             SET @NNUM = ssma_oracle.datediff(ssma_oracle.to_date2(ISNULL(@SUNCARDDATE, '') + ISNULL(@SUNCARDPOIN, ''), 'YYYY-MM-DDHH24MI'), DATEADD(D, 1, ssma_oracle.to_date2(ISNULL(@SUNCARDDATE, '') + ISNULL(@ICLASTIME_OUT, ''), 'YYYY-MM-DDHH24MI')))
                                          ELSE 
                                             IF substring(@ICLASTIME_OUT, 1, 1) = '0' AND substring(@SUNCARDPOIN, 1, 1) <> '2'
                                                SET @NNUM = ssma_oracle.datediff(DATEADD(D, 1, ssma_oracle.to_date2(ISNULL(@SUNCARDDATE, '') + ISNULL(@SUNCARDPOIN, ''), 'YYYY-MM-DDHH24MI')), DATEADD(D, 1, ssma_oracle.to_date2(ISNULL(@SUNCARDDATE, '') + ISNULL(@ICLASTIME_OUT, ''), 'YYYY-MM-DDHH24MI')))
                                             ELSE 
                                                SET @NNUM = ssma_oracle.datediff(ssma_oracle.to_date2(ISNULL(@SUNCARDDATE, '') + ISNULL(@SUNCARDPOIN, ''), 'YYYY-MM-DDHH24MI'), ssma_oracle.to_date2(ISNULL(@SUNCARDDATE, '') + ISNULL(@ICLASTIME_OUT, ''), 'YYYY-MM-DDHH24MI'))

                                       IF @NNUM > 0
                                          BEGIN

                                             SET @NNUMHRS = floor((@NNUM * 24 * 60) / 30) * 0.5

                                             SET @NNUMMIN = ssma_oracle.round_numeric_0(@NNUM * 24 * 60)

                                             /*IF nNumHrs >= 0.5 AND sUnCardRea IS NULL THEN*/
                                             IF @NNUMMIN >= 1 AND (@SUNCARDREA IS NULL OR @SUNCARDREA = '')
                                                BEGIN

                                                   SET @RTNCODE = 5

                                                   SET @ICONTI = 0

                                                END

                                             /*延後超過5小時打卡無法存檔成功*/
                                             IF @NNUMHRS >= 5
                                                BEGIN

                                                   SET @RTNCODE = 6

                                                   SET @ICONTI = 0

                                                END

                                          END

                                    END

                           END
                     END

               END

         END

   END
GO
BEGIN TRY
    EXEC sp_addextendedproperty
        N'MS_SSMA_SOURCE', N'HRP.EHRPHRA12_PKG.hraC040',
        N'SCHEMA', N'hrp',
        N'PROCEDURE', N'EHRPHRA12_PKG$HRAC040'
END TRY
BEGIN CATCH
    IF (@@TRANCOUNT > 0) ROLLBACK
    PRINT ERROR_MESSAGE()
END CATCH
GO
