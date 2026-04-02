
USE MIS
GO
 IF NOT EXISTS(SELECT * FROM sys.schemas WHERE [name] = N'hrp')      
     EXEC (N'CREATE SCHEMA hrp')                                   
 GO                                                               

USE MIS
GO
IF  EXISTS (SELECT * FROM sys.objects so JOIN sys.schemas sc ON so.schema_id = sc.schema_id WHERE so.name = N'EHRPHRA12_PKG$HRAC041'  AND sc.name=N'hrp'  AND type in (N'P',N'PC'))
 DROP PROCEDURE [hrp].[EHRPHRA12_PKG$HRAC041]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE HRP.EHRPHRA12_PKG$HRAC041  
   @P_EMP_NO varchar(max),
   @P_UNCARD_DATE varchar(max),
   @P_UNCARD_TIME varchar(max),
   @P_CHECK_POIN varchar(max),
   @P_NIGHT_FLAG varchar(max),
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
         @SUNCARDTIME varchar(4) = @P_UNCARD_TIME, 
         @SCHECKPOIN varchar(10) = @P_CHECK_POIN, 
         @SNIGHTFLAG varchar(1) = @P_NIGHT_FLAG, 
         @SORGANTYPE varchar(10) = @ORGANTYPE_IN, 
         @SUNCARDTYPE varchar(1) = substring(@P_UNCARD_TIME, 2, 1), 
         @DSIGNDATET datetime2(0) = ssma_oracle.to_date2(ISNULL(@P_UNCARD_DATE, '') + ISNULL(@P_CHECK_POIN, ''), 'YYYY-MM-DDHH24:MI'), 
         @SCLASSCODE varchar(4), 
         @DSCHDATE datetime2(0), 
         /*
         *   SSMA warning messages:
         *   O2SS0356: Conversion from NUMBER datatype can cause data loss.
         */

         @ICNT float(53), 
         /*
         *   SSMA warning messages:
         *   O2SS0356: Conversion from NUMBER datatype can cause data loss.
         */

         @ICNT2 float(53), 
         @DSTARTDATE datetime2(0), 
         @LIMITDAY varchar(2)

      SET @RTNCODE = 0

      IF ssma_oracle.to_date2(@SUNCARDDATE, 'YYYY-MM-DD') > sysdatetime()
         BEGIN

            SET @RTNCODE = 2

            GOTO CONTINUE_FOREACH

         END

      IF ssma_oracle.to_date2(ISNULL(@SUNCARDDATE, '') + ISNULL(@SCHECKPOIN, ''), 'YYYY-MM-DDHH24MI') > sysdatetime()
         BEGIN

            SET @RTNCODE = 2

            GOTO CONTINUE_FOREACH

         END

      
      /*
      *   每月申請最多至隔月5號(5號當天可以申請)
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
      *         RtnCode := 3 ;
      *         GOTO Continue_ForEach;
      *       END IF;
      */
      IF ssma_oracle.trunc_date(sysdatetime()) > CONVERT(datetime2, ISNULL(ssma_oracle.to_char_date(dateadd(m, 1, CONVERT(datetime2, @SUNCARDDATE, 111)), 'YYYY-MM'), '') + '-' + ISNULL(@LIMITDAY, ''), 111)
         BEGIN

            SET @RTNCODE = 3

            GOTO CONTINUE_FOREACH

         END

      IF @SUNCARDTYPE = '1' AND @SNIGHTFLAG = 'Y'
         /*加班上班卡且隔夜註記,代表應出勤日為打卡時間的隔天*/
         SET @DSCHDATE = DATEADD(D, 1, ssma_oracle.to_date2(@SUNCARDDATE, 'yyyy-mm-dd'))
      ELSE 
         IF @SUNCARDTYPE = '2' AND @SNIGHTFLAG = 'Y'
            /*加班下班卡且隔夜註記,代表應出勤日為打卡時間的前一天*/
            SET @DSCHDATE = DATEADD(D, -1, ssma_oracle.to_date2(@SUNCARDDATE, 'yyyy-mm-dd'))
         ELSE 
            SET @DSCHDATE = ssma_oracle.to_date2(@SUNCARDDATE, 'yyyy-mm-dd')

      SET @SCLASSCODE = HRP.EHRPHRAFUNC_PKG$F_GETCLASSKIND(@SEMPNO, @DSCHDATE, @SORGANTYPE)

      IF @SCLASSCODE = 'ZX'
         BEGIN

            /*ZX不能出勤加班,應先調班*/
            SET @RTNCODE = 4

            GOTO CONTINUE_FOREACH

         END
      ELSE 
         BEGIN
            IF @SCLASSCODE = 'ZQ' AND substring(@SEMPNO, 1, 1) IN ( 'S', 'P' )
               BEGIN

                  /*SP人員ZQ不能出勤加班,應先調班*/
                  SET @RTNCODE = 5

                  GOTO CONTINUE_FOREACH
                  /*
                  *   ELSIF sClassCode NOT IN ('ZZ','ZY','ZQ') THEN
                  *         RtnCode := ;
                  *         GOTO Continue_ForEach;
                  */

               END
         END

      SELECT @ICNT = count_big(*)
      FROM HRP.HRA_OTMSIGN
      WHERE 
         HRA_OTMSIGN.EMP_NO = @SEMPNO AND 
         HRA_OTMSIGN.ORG_BY = @SORGANTYPE AND 
         (ssma_oracle.to_char_date(HRA_OTMSIGN.START_DATE, 'YYYY-MM-DD') = ssma_oracle.to_char_date(@DSCHDATE, 'YYYY-MM-DD') OR ssma_oracle.to_char_date(HRA_OTMSIGN.START_DATE, 'YYYY-MM-DD') = ssma_oracle.to_char_date(DATEADD(D, -1, @DSCHDATE), 'YYYY-MM-DD')) AND 
         HRA_OTMSIGN.END_DATE IS NULL AND 
         HRA_OTMSIGN.OTM_NO LIKE 'OTS%'

      SELECT @ICNT2 = count_big(*)
      FROM HRP.HRA_OTMSIGN
      WHERE 
         HRA_OTMSIGN.EMP_NO = @SEMPNO AND 
         HRA_OTMSIGN.ORG_BY = @SORGANTYPE AND 
         ssma_oracle.to_char_date(HRA_OTMSIGN.START_DATE, 'YYYY-MM-DD') = ssma_oracle.to_char_date(@DSCHDATE, 'YYYY-MM-DD') AND 
         HRA_OTMSIGN.END_DATE IS NOT NULL AND 
         HRA_OTMSIGN.OTM_NO LIKE 'OTS%' AND 
         floor((ssma_oracle.datediff(ssma_oracle.to_date2(ISNULL(@SUNCARDDATE, '') + ISNULL(@SCHECKPOIN, ''), 'YYYY-MM-DDHH24:MI'), ssma_oracle.to_date2(ISNULL(ssma_oracle.to_char_date(HRA_OTMSIGN.START_DATE, 'yyyy-mm-dd'), '') + ISNULL(HRA_OTMSIGN.START_TIME, ''), 'YYYY-MM-DDHH24:MI')) * 24 * 60) / 30) * 0.5 > 0

      IF @SUNCARDTYPE = '2'
         IF @ICNT = 0
            IF @ICNT2 = 0
               BEGIN

                  /*補加班下班但無上班記錄,應先補加班上班記錄*/
                  SET @RTNCODE = 6

                  GOTO CONTINUE_FOREACH

               END
            ELSE 
               BEGIN
                  IF @ICNT2 <> 1
                     BEGIN

                        SET @RTNCODE = 6

                        GOTO CONTINUE_FOREACH

                     END
               END
         ELSE 
            IF @ICNT > 1
               BEGIN

                  /*補加班下班但多筆上班記錄,先請人資確認加班打卡資料,整理後再重新申請*/
                  SET @RTNCODE = 7

                  GOTO CONTINUE_FOREACH

               END
            ELSE 
               BEGIN

                  SELECT @DSTARTDATE = ssma_oracle.to_date2(ISNULL(ssma_oracle.to_char_date(HRA_OTMSIGN.START_DATE, 'yyyy-mm-dd'), '') + ISNULL(HRA_OTMSIGN.START_TIME, ''), 'YYYY-MM-DDHH24:MI')
                  FROM HRP.HRA_OTMSIGN
                  WHERE 
                     HRA_OTMSIGN.EMP_NO = @SEMPNO AND 
                     HRA_OTMSIGN.ORG_BY = @SORGANTYPE AND 
                     (ssma_oracle.to_char_date(HRA_OTMSIGN.START_DATE, 'YYYY-MM-DD') = ssma_oracle.to_char_date(@DSCHDATE, 'YYYY-MM-DD') OR ssma_oracle.to_char_date(HRA_OTMSIGN.START_DATE, 'YYYY-MM-DD') = ssma_oracle.to_char_date(DATEADD(D, -1, @DSCHDATE), 'YYYY-MM-DD')) AND 
                     HRA_OTMSIGN.END_DATE IS NULL AND 
                     HRA_OTMSIGN.OTM_NO LIKE 'OTS%'

                  IF @DSIGNDATET <= @DSTARTDATE
                     BEGIN

                        /*下班卡的時間小於上班卡時間,請人員確認填寫的資料*/
                        SET @RTNCODE = 8

                        GOTO CONTINUE_FOREACH

                     END

               END
      ELSE 
         BEGIN
            IF @SUNCARDTYPE = '1'
               IF @ICNT = 1
                  BEGIN

                     /*新增加班上班但尚有加班打卡資料不完整,應先補加班下班記錄*/
                     SET @RTNCODE = 9

                     GOTO CONTINUE_FOREACH

                  END
               ELSE 
                  BEGIN
                     IF @ICNT > 1
                        BEGIN

                           /*補加班下班但多筆上班記錄,先請人資確認加班打卡資料,整理後再重新申請*/
                           SET @RTNCODE = 7

                           GOTO CONTINUE_FOREACH

                        END
                  END
         END

      
      /*
      *   SELECT COUNT(*)
      *         INTO 
      *         FROM HRA_OTMSIGN
      *        WHERE EMP_NO = SEMPNO
      *          AND ORG_BY = SORGANTYPE
      *          AND (TO_CHAR(START_DATE, 'YYYY-MM-DD') = TO_CHAR(DSCHDATE, 'YYYY-MM-DD') OR
      *               TO_CHAR(START_DATE, 'YYYY-MM-DD') = TO_CHAR(DSCHDATE - 1, 'YYYY-MM-DD'))
      *          AND END_DATE IS NOT NULL
      *          AND OTM_NO LIKE 'OTS%'
      *          AND 30 > (TO_DATE(TO_CHAR(END_DATE, 'YYYY-MM-DD') || END_TIME, 'YYYY-MM-DDHH24MI') -
      *                    TO_DATE(TO_CHAR(START_DATE, 'YYYY-MM-DD') || START_TIME, 'YYYY-MM-DDHH24MI')) * 1440;
      *       
      *       IF sUnCardType = '1' THEN
      *         IF iCnt2 > 1 THEN
      *           --加班完整記錄且相差小於30分鐘的資料有多筆,作業會無法判斷要更新哪一筆加班卡紀錄,請人員與人資聯繫
      *           RtnCode := 10 ;
      *           GOTO Continue_ForEach;
      *         END IF;
      *       END IF;
      */
      DECLARE
         @db_null_statement int

      CONTINUE_FOREACH:

      DECLARE
         @db_null_statement$2 int

   END
GO
BEGIN TRY
    EXEC sp_addextendedproperty
        N'MS_SSMA_SOURCE', N'HRP.EHRPHRA12_PKG.hraC041',
        N'SCHEMA', N'hrp',
        N'PROCEDURE', N'EHRPHRA12_PKG$HRAC041'
END TRY
BEGIN CATCH
    IF (@@TRANCOUNT > 0) ROLLBACK
    PRINT ERROR_MESSAGE()
END CATCH
GO
