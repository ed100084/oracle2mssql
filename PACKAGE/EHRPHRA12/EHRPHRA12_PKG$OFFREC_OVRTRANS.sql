
USE MIS
GO
 IF NOT EXISTS(SELECT * FROM sys.schemas WHERE [name] = N'hrp')      
     EXEC (N'CREATE SCHEMA hrp')                                   
 GO                                                               

USE MIS
GO
IF  EXISTS (SELECT * FROM sys.objects so JOIN sys.schemas sc ON so.schema_id = sc.schema_id WHERE so.name = N'EHRPHRA12_PKG$OFFREC_OVRTRANS'  AND sc.name=N'hrp'  AND type in (N'P',N'PC'))
 DROP PROCEDURE [hrp].[EHRPHRA12_PKG$OFFREC_OVRTRANS]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE HRP.EHRPHRA12_PKG$OFFREC_OVRTRANS  
   @UPDATEBY_IN varchar(max),
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
         @ICNT numeric(1), 
         @ICHECKED varchar(1), 
         @DTRNYM varchar(7), 
         @DSIGNMAN varchar(20), 
         @DEMAIL varchar(120), 
         @DDEPTNO varchar(20), 
         @DDEPTNAME varchar(60), 
         @DOVRTYPE varchar(60), 
         /* 主管迴圈變換變數*/
         @DSIGNMANTMP varchar(20), 
         @DEMAILTMP varchar(120), 
         /*主管訊息*/
         @SMESSAGEL varchar(max), 
         /*人事課訊息*/
         @PMESSAGEL varchar(max), 
         @SEMAIL varchar(120), 
         /*INSERT迴圈參數*/
         @QHRSYM varchar(7), 
         @QSIGNMAN varchar(20), 
         @QPERMIT_ID varchar(20), 
         @QDEPTNO varchar(20), 
         @QSTATUS varchar(1), 
         @QOVRTYP varchar(1), 
         @QOVRAVG numeric(7, 2), 
         @QOVRTHS numeric(7, 2), 
         @QOVRYEL numeric(7, 2), 
         @QOVRRED numeric(7, 2), 
         @QPREMON numeric(7, 2), 
         @QNOWMON numeric(7, 2), 
         @SORGANTYPE varchar(10)

      SET @RTNCODE = 0

      SET @SORGANTYPE = @ORGANTYPE_IN

      SELECT @ICHECKED = HRA_OFFOVR.CREATE_RES
      FROM HRP.HRA_OFFOVR
      WHERE HRA_OFFOVR.OVR_TYPE = 'A' AND HRA_OFFOVR.ORGAN_TYPE = @SORGANTYPE

      IF (@ICHECKED = 'Y')
         BEGIN

            /* 
            *   SSMA error messages:
            *   O2SS0241: Aggregate functions with parameter expressions that contain aggregates or subqueries cannot be converted.
            *   O2SS0241: Aggregate functions with parameter expressions that contain aggregates or subqueries cannot be converted.

            DECLARE
                CURSOR3 CURSOR LOCAL FOR 
                  WITH 
                     TB AS 
                     (
                        /* 
                        *   SSMA error messages:
                        *   O2SS0573: ORDER BY clause is not supported in subquery factoring clause: 
                        *   
                        *   ORDER BY cnt DESC, rownum

                        SELECT fci.DEPT_NO, fci.SIGNMAN
                        FROM 
                           (
                              SELECT SSMAROWNUM.DEPT_NO, SSMAROWNUM.SIGNMAN, SSMAROWNUM.CNT, rank() OVER(PARTITION BY SSMAROWNUM.DEPT_NO
                                 ORDER BY SSMAROWNUM.CNT DESC, SSMAROWNUM.ROWNUM) AS RNK
                              FROM 
                                 (
                                    SELECT DEPT_NO, SIGNMAN, CNT, ROW_NUMBER() OVER(
                                       ORDER BY SSMAPSEUDOCOLUMN) AS ROWNUM
                                    FROM 
                                       (
                                          SELECT fci$2.DEPT_NO, fci$2.SIGNMAN, fci$2.CNT, 0 AS SSMAPSEUDOCOLUMN
                                          FROM 
                                             (
                                                SELECT fci$3.DEPT_NO, fci$3.SIGNMAN, count_big(fci$3.DEPT_NO) AS CNT
                                                FROM 
                                                   (
                                                      SELECT T2.DEPT_NO, 
                                                         (
                                                            SELECT HRE_EMPBAS.USER_SIGNMAN
                                                            FROM HRP.HRE_EMPBAS
                                                            WHERE HRE_EMPBAS.ORGAN_TYPE = @SORGANTYPE AND HRE_EMPBAS.EMP_NO = T2.EMP_NO
                                                         ) AS SIGNMAN
                                                      FROM HRP.HRE_EMPBAS  AS T2
                                                      WHERE 
                                                         T2.ORGAN_TYPE = @SORGANTYPE AND 
                                                         T2.DISABLED = 'N' AND 
                                                         (T2.EMP_FLAG = '01' OR T2.DEPT_NO = 'Z050') AND 
                                                         (T2.JOB_LEV <> 'R' OR T2.JOB_LEV IS NULL OR T2.JOB_LEV = '')
                                                   )  AS fci$3
                                                GROUP BY fci$3.DEPT_NO, fci$3.SIGNMAN
                                             )  AS fci$2
                                       )  AS SSMAPSEUDO
                                 )  AS SSMAROWNUM
                           )  AS fci
                        WHERE fci.RNK = 1
                        */


                     )
                  SELECT 
                     
                        (
                           SELECT TOP (1) HRS_YM.HRS_YM
                           FROM HRP.HRS_YM
                        ), 
                     
                        (
                           SELECT SSMAROWNUM.SIGNMAN
                           FROM 
                              (
                                 SELECT SIGNMAN, DEPT_NO, ROW_NUMBER() OVER(
                                    ORDER BY SSMAPSEUDOCOLUMN) AS ROWNUM
                                 FROM 
                                    (
                                       SELECT TB.SIGNMAN, TB.DEPT_NO, 0 AS SSMAPSEUDOCOLUMN
                                       FROM TB
                                       WHERE TB.DEPT_NO = HRA_OFFOVR.DEPT_NO AND 1 = 1
                                    )  AS SSMAPSEUDO
                              )  AS SSMAROWNUM
                           WHERE SSMAROWNUM.DEPT_NO = HRA_OFFOVR.DEPT_NO AND SSMAROWNUM.ROWNUM = 1
                        ), 
                     
                        (
                           SELECT HRE_EMPBAS.USER_SIGNMAN
                           FROM HRP.HRE_EMPBAS
                           WHERE HRE_EMPBAS.ORGAN_TYPE = @SORGANTYPE AND HRE_EMPBAS.EMP_NO = 
                              (
                                 SELECT SSMAROWNUM$2.SIGNMAN
                                 FROM 
                                    (
                                       SELECT SIGNMAN, DEPT_NO, ROW_NUMBER() OVER(
                                          ORDER BY SSMAPSEUDOCOLUMN) AS ROWNUM
                                       FROM 
                                          (
                                             SELECT TB$2.SIGNMAN, TB$2.DEPT_NO, 0 AS SSMAPSEUDOCOLUMN
                                             FROM TB  AS TB$2
                                             WHERE TB$2.DEPT_NO = HRA_OFFOVR.DEPT_NO AND 1 = 1
                                          )  AS SSMAPSEUDO$2
                                    )  AS SSMAROWNUM$2
                                 WHERE SSMAROWNUM$2.DEPT_NO = HRA_OFFOVR.DEPT_NO AND SSMAROWNUM$2.ROWNUM = 1
                              )
                        ), 
                     HRA_OFFOVR.DEPT_NO, 
                     'U', 
                     HRA_OFFOVR.STR_YM, 
                     HRA_OFFOVR.OVR_AVG, 
                     HRA_OFFOVR.OVR_THS, 
                     HRA_OFFOVR.OVR_YEL, 
                     HRA_OFFOVR.OVR_RED, 
                     
                        (
                           SELECT sum(T1.MON_GETADD + T1.MON_ADDHRS + isnull(
                              (
                                 SELECT sum(HRA_OFFREC.SOTM_HRS)
                                 FROM HRP.HRA_OFFREC
                                 WHERE 
                                    HRA_OFFREC.ORG_BY = @SORGANTYPE AND 
                                    ssma_oracle.to_char_date(HRA_OFFREC.START_DATE, 'YYYY-MM') = T1.SCH_YM AND 
                                    HRA_OFFREC.ITEM_TYPE = 'A' AND 
                                    HRA_OFFREC.STATUS = 'Y' AND 
                                    HRA_OFFREC.DISABLED = 'N' AND 
                                    HRA_OFFREC.OTM_REA <> '1007' AND 
                                    HRA_OFFREC.DEPT_NO = T1.DEPT_NO AND 
                                    HRA_OFFREC.EMP_NO = T1.EMP_NO
                              ), 0) - isnull(
                              (
                                 SELECT sum(HRA_OFFREC$2.SOTM_HRS)
                                 FROM HRP.HRA_OFFREC  AS HRA_OFFREC$2
                                 WHERE 
                                    HRA_OFFREC$2.ORG_BY = @SORGANTYPE AND 
                                    ssma_oracle.to_char_date(HRA_OFFREC$2.START_DATE, 'YYYY-MM') = T1.SCH_YM AND 
                                    HRA_OFFREC$2.ITEM_TYPE = 'O' AND 
                                    HRA_OFFREC$2.STATUS = 'Y' AND 
                                    HRA_OFFREC$2.DISABLED = 'N' AND 
                                    HRA_OFFREC$2.OTM_REA <> '1013' AND 
                                    HRA_OFFREC$2.DEPT_NO = T1.DEPT_NO AND 
                                    HRA_OFFREC$2.EMP_NO = T1.EMP_NO
                              ), 0)) AS ATTVALUE
                           FROM HRP.HRA_ATTVAC_VIEW  AS T1
                           WHERE T1.SCH_YM = 
                              (
                                 SELECT ssma_oracle.to_char_date(DATEADD(D, -1, ssma_oracle.to_date2(ISNULL(HRS_YM$2.HRS_YM, '') + '-01', 'yyyy-mm-dd')), 'yyyy-mm')
                                 FROM HRP.HRS_YM  AS HRS_YM$2
                              ) AND T1.DEPT_NO = HRA_OFFOVR.DEPT_NO
                        ) AS PREMON, 
                     
                        (
                           /* 
                           *   SSMA error messages:
                           *   O2SS0241: Aggregate functions with parameter expressions that contain aggregates or subqueries cannot be converted.
                           *   O2SS0241: Aggregate functions with parameter expressions that contain aggregates or subqueries cannot be converted.

                           SELECT sum(T1$2.MON_GETADD + T1$2.MON_ADDHRS + isnull(
                              (
                                 SELECT sum(HRA_OFFREC$3.SOTM_HRS)
                                 FROM HRP.HRA_OFFREC  AS HRA_OFFREC$3
                                 WHERE 
                                    HRA_OFFREC$3.ORG_BY = @SORGANTYPE AND 
                                    ssma_oracle.to_char_date(HRA_OFFREC$3.START_DATE, 'YYYY-MM') = T1$2.SCH_YM AND 
                                    HRA_OFFREC$3.ITEM_TYPE = 'A' AND 
                                    HRA_OFFREC$3.STATUS = 'Y' AND 
                                    HRA_OFFREC$3.DISABLED = 'N' AND 
                                    HRA_OFFREC$3.OTM_REA <> '1007' AND 
                                    HRA_OFFREC$3.DEPT_NO = T1$2.DEPT_NO AND 
                                    HRA_OFFREC$3.EMP_NO = T1$2.EMP_NO
                              ), 0) - isnull(
                              (
                                 SELECT sum(HRA_OFFREC$4.SOTM_HRS)
                                 FROM HRP.HRA_OFFREC  AS HRA_OFFREC$4
                                 WHERE 
                                    HRA_OFFREC$4.ORG_BY = @SORGANTYPE AND 
                                    ssma_oracle.to_char_date(HRA_OFFREC$4.START_DATE, 'YYYY-MM') = T1$2.SCH_YM AND 
                                    HRA_OFFREC$4.ITEM_TYPE = 'O' AND 
                                    HRA_OFFREC$4.STATUS = 'Y' AND 
                                    HRA_OFFREC$4.DISABLED = 'N' AND 
                                    HRA_OFFREC$4.OTM_REA <> '1013' AND 
                                    HRA_OFFREC$4.DEPT_NO = T1$2.DEPT_NO AND 
                                    HRA_OFFREC$4.EMP_NO = T1$2.EMP_NO
                              ), 0)) AS ATTVALUE
                           FROM HRP.HRA_ATTVAC_VIEW  AS T1$2
                           WHERE 
                              T1$2.ORGAN_TYPE = @SORGANTYPE AND 
                              T1$2.SCH_YM = 
                              (
                                 SELECT HRS_YM$3.HRS_YM
                                 FROM HRP.HRS_YM  AS HRS_YM$3
                              ) AND 
                              T1$2.DEPT_NO = HRA_OFFOVR.DEPT_NO AND 
                              T1$2.EMP_NO NOT IN 
                              (
                                 SELECT HR_CODEDTL.CODE_NAME
                                 FROM HRP.HR_CODEDTL
                                 WHERE HR_CODEDTL.CODE_TYPE = 'HRA32' AND HR_CODEDTL.CODE_NO LIKE '2%'
                              )
                           */


                        ) AS NOWMON
                  FROM HRP.HRA_OFFOVR
                  WHERE 
                     HRA_OFFOVR.ORGAN_TYPE = @SORGANTYPE AND 
                     HRA_OFFOVR.OVR_TYPE = 'B' AND 
                     HRA_OFFOVR.CREATE_RES = 'Y' AND 
                     HRA_OFFOVR.STR_YM <> 'Z'
            */



            OPEN CURSOR3

            WHILE 1 = 1
            
               BEGIN

                  FETCH CURSOR3
                      INTO 
                        @QHRSYM, 
                        @QSIGNMAN, 
                        @QPERMIT_ID, 
                        @QDEPTNO, 
                        @QSTATUS, 
                        @QOVRTYP, 
                        @QOVRAVG, 
                        @QOVRTHS, 
                        @QOVRYEL, 
                        @QOVRRED, 
                        @QPREMON, 
                        @QNOWMON

                  /*
                  *   SSMA warning messages:
                  *   O2SS0113: The value of @@FETCH_STATUS might be changed by previous FETCH operations on other cursors, if the cursors are used simultaneously.
                  */

                  IF @@FETCH_STATUS <> 0
                     BREAK

                  INSERT HRP.HRA_OFFOVRRES(
                     TRN_TM, 
                     SIGNMAN, 
                     PERMIT_ID, 
                     PERMIT_STATUS, 
                     DEPT_NO, 
                     STATUS, 
                     OVR_TYPE, 
                     OVR_AVG, 
                     OVR_THS, 
                     OVR_YEL, 
                     OVR_RED, 
                     NEED_REPLY, 
                     KEEP_PREMON, 
                     KEEP_THISMON, 
                     CREATED_BY, 
                     CREATION_DATE, 
                     LAST_UPDATED_BY, 
                     LAST_UPDATE_DATE, 
                     ORG_BY)
                     VALUES (
                        @QHRSYM, 
                        @QSIGNMAN, 
                        @QPERMIT_ID, 
                        'N', 
                        @QDEPTNO, 
                        @QSTATUS, 
                        @QOVRTYP, 
                        @QOVRAVG, 
                        @QOVRTHS, 
                        @QOVRYEL, 
                        @QOVRRED, 
                        'Y', 
                        @QPREMON, 
                        @QNOWMON, 
                        @UPDATEBY_IN, 
                        sysdatetime(), 
                        @UPDATEBY_IN, 
                        sysdatetime(), 
                        @SORGANTYPE)

               END

            CLOSE CURSOR3

            DEALLOCATE CURSOR3

            /*修改控制不需要維護或替代資料*/
            UPDATE HRP.HRA_OFFOVRRES
               SET 
                  NEED_REPLY = 'N'
            WHERE 
               HRA_OFFOVRRES.TRN_TM = 
               (
                  SELECT TOP (1) HRS_YM.HRS_YM
                  FROM HRP.HRS_YM
               ) AND 
               HRA_OFFOVRRES.SIGNMAN IN 
               (
                  SELECT HR_CODEDTL.CODE_NAME
                  FROM HRP.HR_CODEDTL
                  WHERE HR_CODEDTL.CODE_TYPE = 'HRA32' AND CAST(HR_CODEDTL.CODE_NO AS numeric(38, 10)) < 100
               ) AND 
               HRA_OFFOVRRES.ORG_BY = @SORGANTYPE

            UPDATE HRP.HRA_OFFOVRRES
               SET 
                  SIGNMAN = 
                     (
                        SELECT HR_CODEDTL.REMARK
                        FROM HRP.HR_CODEDTL
                        WHERE 
                           HR_CODEDTL.CODE_TYPE = 'HRA32' AND 
                           CAST(HR_CODEDTL.CODE_NO AS numeric(38, 10)) BETWEEN 100 AND 199 AND 
                           HR_CODEDTL.CODE_NAME = HRA_OFFOVRRES.SIGNMAN
                     )
            WHERE 
               HRA_OFFOVRRES.TRN_TM = 
               (
                  SELECT TOP (1) HRS_YM.HRS_YM
                  FROM HRP.HRS_YM
               ) AND 
               HRA_OFFOVRRES.SIGNMAN IN 
               (
                  SELECT HR_CODEDTL$2.CODE_NAME
                  FROM HRP.HR_CODEDTL  AS HR_CODEDTL$2
                  WHERE HR_CODEDTL$2.CODE_TYPE = 'HRA32' AND CAST(HR_CODEDTL$2.CODE_NO AS numeric(38, 10)) BETWEEN 100 AND 199
               ) AND 
               HRA_OFFOVRRES.ORG_BY = @SORGANTYPE

            UPDATE HRP.HRA_OFFOVRRES
               SET 
                  PERMIT_ID = NULL
            WHERE 
               HRA_OFFOVRRES.PERMIT_ID = '100003' AND 
               HRA_OFFOVRRES.TRN_TM = 
               (
                  SELECT TOP (1) HRS_YM.HRS_YM
                  FROM HRP.HRS_YM
               ) AND 
               HRA_OFFOVRRES.ORG_BY = @SORGANTYPE

            /* 
            *   SSMA error messages:
            *   O2SS0241: Aggregate functions with parameter expressions that contain aggregates or subqueries cannot be converted.
            *   O2SS0241: Aggregate functions with parameter expressions that contain aggregates or subqueries cannot be converted.

            /*新增不需要回覆的資料供報表抓取*/
            INSERT HRP.HRA_OFFOVRRES(
               TRN_TM, 
               ORG_BY, 
               SIGNMAN, 
               PERMIT_ID, 
               PERMIT_STATUS, 
               DEPT_NO, 
               STATUS, 
               OVR_TYPE, 
               OVR_AVG, 
               OVR_THS, 
               OVR_YEL, 
               OVR_RED, 
               NEED_REPLY, 
               KEEP_PREMON, 
               KEEP_THISMON, 
               CREATED_BY, 
               CREATION_DATE, 
               LAST_UPDATED_BY, 
               LAST_UPDATE_DATE)
                (
                  SELECT 
                     
                        (
                           SELECT TOP (1) HRS_YM.HRS_YM
                           FROM HRP.HRS_YM
                        ), 
                     @SORGANTYPE, 
                     'MIS', 
                     'MIS', 
                     'Y', 
                     HRA_OFFOVR.DEPT_NO, 
                     'R', 
                     HRA_OFFOVR.STR_YM, 
                     HRA_OFFOVR.OVR_AVG, 
                     HRA_OFFOVR.OVR_THS, 
                     HRA_OFFOVR.OVR_YEL, 
                     HRA_OFFOVR.OVR_RED, 
                     'N', 
                     
                        (
                           SELECT sum(T1.MON_GETADD + T1.MON_ADDHRS + isnull(
                              (
                                 SELECT sum(HRA_OFFREC.SOTM_HRS)
                                 FROM HRP.HRA_OFFREC
                                 WHERE 
                                    HRA_OFFREC.ORG_BY = @SORGANTYPE AND 
                                    ssma_oracle.to_char_date(HRA_OFFREC.START_DATE, 'YYYY-MM') = T1.SCH_YM AND 
                                    HRA_OFFREC.ITEM_TYPE = 'A' AND 
                                    HRA_OFFREC.STATUS = 'Y' AND 
                                    HRA_OFFREC.DISABLED = 'N' AND 
                                    HRA_OFFREC.OTM_REA <> '1007' AND 
                                    HRA_OFFREC.DEPT_NO = T1.DEPT_NO AND 
                                    HRA_OFFREC.EMP_NO = T1.EMP_NO
                              ), 0) - isnull(
                              (
                                 SELECT sum(HRA_OFFREC$2.SOTM_HRS)
                                 FROM HRP.HRA_OFFREC  AS HRA_OFFREC$2
                                 WHERE 
                                    HRA_OFFREC$2.ORG_BY = @SORGANTYPE AND 
                                    ssma_oracle.to_char_date(HRA_OFFREC$2.START_DATE, 'YYYY-MM') = T1.SCH_YM AND 
                                    HRA_OFFREC$2.ITEM_TYPE = 'O' AND 
                                    HRA_OFFREC$2.STATUS = 'Y' AND 
                                    HRA_OFFREC$2.DISABLED = 'N' AND 
                                    HRA_OFFREC$2.OTM_REA <> '1013' AND 
                                    HRA_OFFREC$2.DEPT_NO = T1.DEPT_NO AND 
                                    HRA_OFFREC$2.EMP_NO = T1.EMP_NO
                              ), 0)) AS ATTVALUE
                           FROM HRP.HRA_ATTVAC_VIEW  AS T1
                           WHERE 
                              T1.ORGAN_TYPE = @SORGANTYPE AND 
                              T1.SCH_YM = 
                              (
                                 SELECT ssma_oracle.to_char_date(DATEADD(D, -1, ssma_oracle.to_date2(ISNULL(HRS_YM$3.HRS_YM, '') + '-01', 'yyyy-mm-dd')), 'yyyy-mm')
                                 FROM HRP.HRS_YM  AS HRS_YM$3
                              ) AND 
                              T1.DEPT_NO = HRA_OFFOVR.DEPT_NO
                        ) AS PREMON, 
                     
                        (
                           /* 
                           *   SSMA error messages:
                           *   O2SS0241: Aggregate functions with parameter expressions that contain aggregates or subqueries cannot be converted.
                           *   O2SS0241: Aggregate functions with parameter expressions that contain aggregates or subqueries cannot be converted.

                           SELECT sum(T1$2.MON_GETADD + T1$2.MON_ADDHRS + isnull(
                              (
                                 SELECT sum(HRA_OFFREC$3.SOTM_HRS)
                                 FROM HRP.HRA_OFFREC  AS HRA_OFFREC$3
                                 WHERE 
                                    HRA_OFFREC$3.ORG_BY = @SORGANTYPE AND 
                                    ssma_oracle.to_char_date(HRA_OFFREC$3.START_DATE, 'YYYY-MM') = T1$2.SCH_YM AND 
                                    HRA_OFFREC$3.ITEM_TYPE = 'A' AND 
                                    HRA_OFFREC$3.STATUS = 'Y' AND 
                                    HRA_OFFREC$3.DISABLED = 'N' AND 
                                    HRA_OFFREC$3.OTM_REA <> '1007' AND 
                                    HRA_OFFREC$3.DEPT_NO = T1$2.DEPT_NO AND 
                                    HRA_OFFREC$3.EMP_NO = T1$2.EMP_NO
                              ), 0) - isnull(
                              (
                                 SELECT sum(HRA_OFFREC$4.SOTM_HRS)
                                 FROM HRP.HRA_OFFREC  AS HRA_OFFREC$4
                                 WHERE 
                                    HRA_OFFREC$4.ORG_BY = @SORGANTYPE AND 
                                    ssma_oracle.to_char_date(HRA_OFFREC$4.START_DATE, 'YYYY-MM') = T1$2.SCH_YM AND 
                                    HRA_OFFREC$4.ITEM_TYPE = 'O' AND 
                                    HRA_OFFREC$4.STATUS = 'Y' AND 
                                    HRA_OFFREC$4.DISABLED = 'N' AND 
                                    HRA_OFFREC$4.OTM_REA <> '1013' AND 
                                    HRA_OFFREC$4.DEPT_NO = T1$2.DEPT_NO AND 
                                    HRA_OFFREC$4.EMP_NO = T1$2.EMP_NO
                              ), 0)) AS ATTVALUE
                           FROM HRP.HRA_ATTVAC_VIEW  AS T1$2
                           WHERE 
                              T1$2.ORGAN_TYPE = @SORGANTYPE AND 
                              T1$2.SCH_YM = 
                              (
                                 SELECT HRS_YM$4.HRS_YM
                                 FROM HRP.HRS_YM  AS HRS_YM$4
                              ) AND 
                              T1$2.DEPT_NO = HRA_OFFOVR.DEPT_NO
                           */


                        ) AS NOWMON, 
                     @UPDATEBY_IN, 
                     sysdatetime(), 
                     @UPDATEBY_IN, 
                     sysdatetime()
                  FROM HRP.HRA_OFFOVR
                  WHERE 
                     HRA_OFFOVR.ORG_BY = @SORGANTYPE AND 
                     HRA_OFFOVR.OVR_TYPE = 'B' AND 
                     HRA_OFFOVR.DEPT_NO NOT IN 
                     (
                        SELECT HRA_OFFOVRRES.DEPT_NO
                        FROM HRP.HRA_OFFOVRRES
                        WHERE HRA_OFFOVRRES.ORG_BY = @SORGANTYPE AND HRA_OFFOVRRES.TRN_TM = 
                           (
                              SELECT TOP (1) HRS_YM$2.HRS_YM
                              FROM HRP.HRS_YM  AS HRS_YM$2
                           )
                     )
                )
            */



            UPDATE HRP.HRA_OFFOVR
               SET 
                  CREATE_RES = 'N'
            WHERE HRA_OFFOVR.CREATE_RES = 'Y' AND HRA_OFFOVR.ORGAN_TYPE = @SORGANTYPE

            IF @@TRANCOUNT > 0
               COMMIT TRANSACTION 

            DECLARE
                CURSOR1 CURSOR LOCAL FOR 
                  SELECT 
                     fci.TRN_TM, 
                     fci.SIGNMAN, 
                     fci.EMAIL, 
                     fci.DEPT_NO, 
                     fci.DEPTNAME, 
                     fci.STA
                  FROM 
                     (
                        SELECT 
                           T1.TRN_TM, 
                           T1.SIGNMAN, 
                           
                              (
                                 SELECT 'ed' + ISNULL(HRE_EMPBAS.EMP_NO, '') + '@edah.org.tw' AS expr
                                 FROM HRP.HRE_EMPBAS
                                 WHERE HRE_EMPBAS.ORGAN_TYPE = @SORGANTYPE AND HRE_EMPBAS.EMP_NO = T1.SIGNMAN
                              ) AS EMAIL, 
                           T1.DEPT_NO, 
                           
                              (
                                 SELECT HRE_ORGBAS.CH_NAME
                                 FROM HRP.HRE_ORGBAS
                                 WHERE HRE_ORGBAS.ORGAN_TYPE = @SORGANTYPE AND HRE_ORGBAS.DEPT_NO = T1.DEPT_NO
                              ) AS DEPTNAME, 
                           CASE T1.OVR_TYPE
                              WHEN 'A' THEN '紅燈警示'
                              WHEN 'B' THEN '黃燈警示'
                              WHEN 'C' THEN '連續兩個月超過閾值'
                              ELSE NULL
                           END AS STA
                        FROM HRP.HRA_OFFOVRRES  AS T1
                        WHERE 
                           T1.ORG_BY = @SORGANTYPE AND 
                           T1.TRN_TM = 
                           (
                              SELECT TOP (1) HRS_YM.HRS_YM
                              FROM HRP.HRS_YM
                           ) AND 
                           T1.NEED_REPLY = 'Y'
                         UNION ALL
                        SELECT 
                           T2.TRN_TM, 
                           
                              (
                                 SELECT HRE_EMPBAS$2.USER_SIGNMAN
                                 FROM HRP.HRE_EMPBAS  AS HRE_EMPBAS$2
                                 WHERE HRE_EMPBAS$2.ORGAN_TYPE = @SORGANTYPE AND HRE_EMPBAS$2.EMP_NO = T2.SIGNMAN
                              ), 
                           
                              (
                                 SELECT 'ed' + ISNULL(HRE_EMPBAS$3.EMP_NO, '') + '@edah.org.tw' AS expr
                                 FROM HRP.HRE_EMPBAS  AS HRE_EMPBAS$3
                                 WHERE HRE_EMPBAS$3.ORGAN_TYPE = @SORGANTYPE AND HRE_EMPBAS$3.EMP_NO = 
                                    (
                                       SELECT HRE_EMPBAS$5.USER_SIGNMAN
                                       FROM HRP.HRE_EMPBAS  AS HRE_EMPBAS$5
                                       WHERE HRE_EMPBAS$5.ORGAN_TYPE = @SORGANTYPE AND HRE_EMPBAS$5.EMP_NO = T2.SIGNMAN
                                    )
                              ) AS EMAIL, 
                           T2.DEPT_NO, 
                           
                              (
                                 SELECT HRE_ORGBAS$2.CH_NAME
                                 FROM HRP.HRE_ORGBAS  AS HRE_ORGBAS$2
                                 WHERE HRE_ORGBAS$2.ORGAN_TYPE = @SORGANTYPE AND HRE_ORGBAS$2.DEPT_NO = T2.DEPT_NO
                              ) AS DEPTNAME, 
                           CASE T2.OVR_TYPE
                              WHEN 'A' THEN '紅燈警示需覆核'
                              WHEN 'B' THEN '黃燈警示需覆核'
                              ELSE '連續兩個月超過閾值需覆核'
                           END
                        FROM HRP.HRA_OFFOVRRES  AS T2
                        WHERE 
                           T2.ORG_BY = @SORGANTYPE AND 
                           T2.TRN_TM = 
                           (
                              SELECT TOP (1) HRS_YM$2.HRS_YM
                              FROM HRP.HRS_YM  AS HRS_YM$2
                           ) AND 
                           T2.OVR_TYPE IN ( 'A', 'B', 'C' ) AND 
                           T2.NEED_REPLY = 'Y' AND 
                           
                           (
                              SELECT HRE_EMPBAS$4.USER_SIGNMAN
                              FROM HRP.HRE_EMPBAS  AS HRE_EMPBAS$4
                              WHERE HRE_EMPBAS$4.ORGAN_TYPE = @SORGANTYPE AND HRE_EMPBAS$4.EMP_NO = T2.SIGNMAN
                           ) NOT IN 
                           (
                              SELECT HR_CODEDTL.CODE_NAME
                              FROM HRP.HR_CODEDTL
                              WHERE HR_CODEDTL.CODE_TYPE = 'HRA32' AND CAST(HR_CODEDTL.CODE_NO AS numeric(38, 10)) < 100
                           )
                     )  AS fci
                  ORDER BY fci.SIGNMAN

            OPEN CURSOR1

            WHILE 1 = 1
            
               BEGIN

                  FETCH CURSOR1
                      INTO 
                        @DTRNYM, 
                        @DSIGNMAN, 
                        @DEMAIL, 
                        @DDEPTNO, 
                        @DDEPTNAME, 
                        @DOVRTYPE

                  /*
                  *   SSMA warning messages:
                  *   O2SS0113: The value of @@FETCH_STATUS might be changed by previous FETCH operations on other cursors, if the cursors are used simultaneously.
                  */

                  IF @@FETCH_STATUS <> 0
                     BREAK

                  IF (ssma_oracle.trim2_varchar(3, @DSIGNMANTMP) IS NULL OR ssma_oracle.trim2_varchar(3, @DSIGNMANTMP) = '' OR @DSIGNMANTMP <> @DSIGNMAN)
                     BEGIN

                        IF ssma_oracle.trim2_varchar(3, @SMESSAGEL) IS NOT NULL AND ssma_oracle.trim2_varchar(3, @SMESSAGEL) != ''
                           BEGIN

                              /*主管mail發送*/
                              SET @SMESSAGEL = ISNULL(@SMESSAGEL, '') + '</table>'

                              IF (@DEMAILTMP <> 'ed100003@edah.org.tw')
                                 BEGIN

                                    /*暫時移除特助*/
                                    DECLARE
                                       @db_null_statement int

                                    EXECUTE HRP.EHRPHRAFUNC_PKG$POST_HTML_MAIL 
                                       @SENDER = 'system@edah.org.tw', 
                                       @RECIPIENT = @DEMAILTMP, 
                                       @CC_RECIPIENT = 'ed101961@edah.org.tw', 
                                       @MAILTYPE = '2', 
                                       @SUBJECT = '出勤管理-積借休異常通知', 
                                       @MESSAGE = @SMESSAGEL

                                 END

                           END

                        SET @SMESSAGEL = 
                           '以下部門為'
                            + 
                           ISNULL(@DTRNYM, '')
                            + 
                           '積借休異常，'
                            + 
                           '若需回覆請主管們至MIS,出勤管理系統-出勤作業-積借休異常維護維護說明原因，謝謝！'
                            + 
                           '<table><tr><td>部門</td><td>部門名稱</td><td>異常情況</td><td>主管</td></tr>'
                            + 
                           '<tr><td>'
                            + 
                           ISNULL(@DDEPTNO, '')
                            + 
                           '</td><td>'
                            + 
                           ISNULL(@DDEPTNAME, '')
                            + 
                           '</td><td>'
                            + 
                           ISNULL(@DOVRTYPE, '')
                            + 
                           '</td><td>'
                            + 
                           ISNULL(@DSIGNMAN, '')
                            + 
                           '</td></tr>'

                     END
                  ELSE 
                     SET @SMESSAGEL = 
                        ISNULL(@SMESSAGEL, '')
                         + 
                        '<tr><td>'
                         + 
                        ISNULL(@DDEPTNO, '')
                         + 
                        '</td><td>'
                         + 
                        ISNULL(@DDEPTNAME, '')
                         + 
                        '</td><td>'
                         + 
                        ISNULL(@DOVRTYPE, '')
                         + 
                        '</td><td>'
                         + 
                        ISNULL(@DSIGNMAN, '')
                         + 
                        '</td></tr>'

                  /* 暫存上次的主管工號和MAIL*/
                  SET @DSIGNMANTMP = @DSIGNMAN

                  SET @DEMAILTMP = @DEMAIL

                  /*組合管理者MAIL*/
                  IF ssma_oracle.trim2_varchar(3, @PMESSAGEL) IS NOT NULL AND ssma_oracle.trim2_varchar(3, @PMESSAGEL) != ''
                     SET @PMESSAGEL = 
                        ISNULL(@PMESSAGEL, '')
                         + 
                        '<tr><td>'
                         + 
                        ISNULL(@DDEPTNO, '')
                         + 
                        '</td><td>'
                         + 
                        ISNULL(@DDEPTNAME, '')
                         + 
                        '</td><td>'
                         + 
                        ISNULL(@DOVRTYPE, '')
                         + 
                        '</td><td>'
                         + 
                        ISNULL(@DSIGNMAN, '')
                         + 
                        '</td></tr>'
                  ELSE 
                     SET @PMESSAGEL = 
                        '以下部門為'
                         + 
                        ISNULL(@DTRNYM, '')
                         + 
                        '積借休異常，'
                         + 
                        '<table><tr><td>部門</td><td>部門名稱</td><td>異常情況</td><td>主管</td></tr>'
                         + 
                        '<tr><td>'
                         + 
                        ISNULL(@DDEPTNO, '')
                         + 
                        '</td><td>'
                         + 
                        ISNULL(@DDEPTNAME, '')
                         + 
                        '</td><td>'
                         + 
                        ISNULL(@DOVRTYPE, '')
                         + 
                        '</td><td>'
                         + 
                        ISNULL(@DSIGNMAN, '')
                         + 
                        '</td></tr>'

               END

            CLOSE CURSOR1

            DEALLOCATE CURSOR1

            /*最後一位主管的MAIL發送*/
            IF ssma_oracle.trim2_varchar(3, @SMESSAGEL) IS NOT NULL AND ssma_oracle.trim2_varchar(3, @SMESSAGEL) != ''
               BEGIN

                  SET @SMESSAGEL = ISNULL(@SMESSAGEL, '') + '</table>'

                  IF (@DEMAILTMP <> 'ed100003@edah.org.tw')
                     BEGIN

                        /* 暫時移除特助*/
                        DECLARE
                           @db_null_statement$2 int

                        EXECUTE HRP.EHRPHRAFUNC_PKG$POST_HTML_MAIL 
                           @SENDER = 'system@edah.org.tw', 
                           @RECIPIENT = @DEMAILTMP, 
                           @CC_RECIPIENT = 'ed101961@edah.org.tw', 
                           @MAILTYPE = '2', 
                           @SUBJECT = '出勤管理-積借休異常通知', 
                           @MESSAGE = @SMESSAGEL

                     END

               END

            /*管理者MAIL發送*/
            IF ssma_oracle.trim2_varchar(3, @PMESSAGEL) IS NOT NULL AND ssma_oracle.trim2_varchar(3, @PMESSAGEL) != ''
               BEGIN

                  SET @PMESSAGEL = ISNULL(@PMESSAGEL, '') + '</table>'

                  DECLARE
                      CURSOR2 CURSOR LOCAL FOR 
                        /*SELECT hre_empbas.e_mail*/
                        SELECT 'ed' + ISNULL(HRE_EMPBAS.EMP_NO, '') + '@edah.org.tw' AS E_MAIL
                        FROM HRP.HR_CODEDTL, HRP.HRE_EMPBAS
                        WHERE 
                           HRE_EMPBAS.ORGAN_TYPE = @SORGANTYPE AND 
                           (HR_CODEDTL.CODE_NAME = HRE_EMPBAS.EMP_NO) AND 
                           ((HR_CODEDTL.CODE_TYPE = 'HRA99') AND (HR_CODEDTL.CODE_NO LIKE 'C%'))

                  OPEN CURSOR2

                  WHILE 1 = 1
                  
                     BEGIN

                        FETCH CURSOR2
                            INTO @SEMAIL

                        /*
                        *   SSMA warning messages:
                        *   O2SS0113: The value of @@FETCH_STATUS might be changed by previous FETCH operations on other cursors, if the cursors are used simultaneously.
                        */

                        IF @@FETCH_STATUS <> 0
                           BREAK

                        DECLARE
                           @db_null_statement$3 int

                        EXECUTE HRP.EHRPHRAFUNC_PKG$POST_HTML_MAIL 
                           @SENDER = 'system@edah.org.tw', 
                           @RECIPIENT = @SEMAIL, 
                           @CC_RECIPIENT = 'ed101961@edah.org.tw', 
                           @MAILTYPE = '2', 
                           @SUBJECT = '出勤管理-積借休異常通知', 
                           @MESSAGE = @PMESSAGEL

                     END

                  CLOSE CURSOR2

                  DEALLOCATE CURSOR2

               END

         END

   END
GO
BEGIN TRY
    EXEC sp_addextendedproperty
        N'MS_SSMA_SOURCE', N'HRP.EHRPHRA12_PKG.offrec_ovrtrans',
        N'SCHEMA', N'hrp',
        N'PROCEDURE', N'EHRPHRA12_PKG$OFFREC_OVRTRANS'
END TRY
BEGIN CATCH
    IF (@@TRANCOUNT > 0) ROLLBACK
    PRINT ERROR_MESSAGE()
END CATCH
GO
