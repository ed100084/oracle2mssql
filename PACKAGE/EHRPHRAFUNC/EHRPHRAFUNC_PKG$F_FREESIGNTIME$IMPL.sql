
USE MIS
GO
 IF NOT EXISTS(SELECT * FROM sys.schemas WHERE [name] = N'hrp')      
     EXEC (N'CREATE SCHEMA hrp')                                   
 GO                                                               

USE MIS
GO
IF  EXISTS (SELECT * FROM sys.objects so JOIN sys.schemas sc ON so.schema_id = sc.schema_id WHERE so.name = N'EHRPHRAFUNC_PKG$F_FREESIGNTIME$IMPL'  AND sc.name=N'hrp'  AND type in (N'P',N'PC'))
 DROP PROCEDURE [hrp].[EHRPHRAFUNC_PKG$F_FREESIGNTIME$IMPL]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE HRP.EHRPHRAFUNC_PKG$F_FREESIGNTIME$IMPL  
   @EMPNO_IN varchar(max),
   @DATE_IN datetime2(0),
   @TYPE_IN varchar(max),
   @CHECKTIME varchar(max),
   @CLASS_IN varchar(max),
   @return_value_argument varchar(max)  OUTPUT
AS 
   BEGIN

      EXECUTE ssma_oracle.db_fn_check_init_package 'HRP', 'EHRPHRAFUNC_PKG'

      DECLARE
         /*
         *   SSMA warning messages:
         *   O2SS0356: Conversion from NUMBER datatype can cause data loss.
         */

         @SUPHRS float(53), 
         /*
         *   SSMA warning messages:
         *   O2SS0356: Conversion from NUMBER datatype can cause data loss.
         */

         @EVCHRS float(53), 
         @OUTPUT varchar(70), 
         @SUPSTART varchar(4), 
         @SUPEND varchar(4), 
         @EVCSTART varchar(4), 
         @EVCEND varchar(4)

      DECLARE
         @REC_EVCDATA$VACNAME varchar(max), 
         @VACTYPE varchar(100)

      SET @OUTPUT = NULL

      SET @VACTYPE = NULL

      IF @CLASS_IN LIKE 'Z%'
         BEGIN

            BEGIN

               BEGIN TRY
                  SELECT @OUTPUT = HRA_HOLIDAY.HOLI_NAME
                  FROM HRP.HRA_HOLIDAY
                  WHERE HRA_HOLIDAY.HOLI_DATE = @DATE_IN
               END TRY

               BEGIN CATCH
                  BEGIN
                     SET @OUTPUT = NULL
                  END
               END CATCH

            END

            IF @OUTPUT IS NOT NULL AND @OUTPUT != ''
               GOTO CONTINUE_FOREACH1

         END

      SELECT @SUPHRS = isnull(sum(HRA_SUPMST.SUP_HRS), 0)
      FROM HRP.HRA_SUPMST
      WHERE 
         HRA_SUPMST.EMP_NO = @EMPNO_IN AND 
         HRA_SUPMST.START_DATE = @DATE_IN AND 
         HRA_SUPMST.STATUS <> 'N'

      SELECT @EVCHRS = isnull(sum(HRA_EVCREC.VAC_DAYS * 8 + HRA_EVCREC.VAC_HRS), 0)
      FROM HRP.HRA_EVCREC
      WHERE 
         HRA_EVCREC.EMP_NO = @EMPNO_IN AND 
         HRA_EVCREC.START_DATE = @DATE_IN AND 
         HRA_EVCREC.STATUS NOT IN ( 'N', 'D' )

      IF @SUPHRS <> 0
         SELECT @SUPSTART = HRA_SUPMST.START_TIME, @SUPEND = HRA_SUPMST.END_TIME
         FROM HRP.HRA_SUPMST
         WHERE 
            HRA_SUPMST.EMP_NO = @EMPNO_IN AND 
            HRA_SUPMST.START_DATE = @DATE_IN AND 
            HRA_SUPMST.STATUS <> 'N'

      IF @EVCHRS <> 0
         BEGIN

            SELECT @EVCSTART = min(HRA_EVCREC.START_TIME), @EVCEND = max(HRA_EVCREC.END_TIME)
            FROM HRP.HRA_EVCREC
            WHERE 
               HRA_EVCREC.EMP_NO = @EMPNO_IN AND 
               HRA_EVCREC.START_DATE = @DATE_IN AND 
               HRA_EVCREC.STATUS <> 'N'

            DECLARE
                CUR_EVCDATA CURSOR LOCAL FOR 
                  /*
                  *   SSMA warning messages:
                  *   O2SS0273: Oracle SUBSTR function and SQL Server SUBSTRING function may give different results.
                  *   O2SS0273: Oracle SUBSTR function and SQL Server SUBSTRING function may give different results.
                  */

                  SELECT DISTINCT 
                     CASE 
                        WHEN A.VAC_TYPE IN ( 'E', 'P', 'S', 'U' ) THEN ISNULL(isnull(substring(M.VAC_NAME, 1, ssma_oracle.instr4_varchar(M.VAC_NAME, '(', 1, 1) - 1), M.VAC_NAME), '') + '(' + ISNULL(D.RUL_NAME, '') + ')'
                        ELSE isnull(substring(M.VAC_NAME, 1, ssma_oracle.instr4_varchar(M.VAC_NAME, '(', 1, 1) - 1), M.VAC_NAME)
                     END AS VACNAME
                  FROM HRP.HRA_EVCREC  AS A, HRP.HRA_VCRLMST  AS M, HRP.HRA_VCRLDTL  AS D
                  WHERE 
                     A.EMP_NO = @EMPNO_IN AND 
                     @DATE_IN BETWEEN A.START_DATE AND A.END_DATE AND 
                     A.STATUS NOT IN ( 'N', 'D' ) AND 
                     A.VAC_TYPE = M.VAC_TYPE AND 
                     A.VAC_RUL = D.VAC_RUL

            OPEN CUR_EVCDATA

            WHILE 1 = 1
            
               BEGIN

                  FETCH CUR_EVCDATA
                      INTO @REC_EVCDATA$VACNAME

                  /*
                  *   SSMA warning messages:
                  *   O2SS0113: The value of @@FETCH_STATUS might be changed by previous FETCH operations on other cursors, if the cursors are used simultaneously.
                  */

                  IF @@FETCH_STATUS <> 0
                     BREAK

                  IF @VACTYPE IS NULL OR @VACTYPE = ''
                     SET @VACTYPE = @REC_EVCDATA$VACNAME
                  ELSE 
                     SET @VACTYPE = ISNULL(@VACTYPE, '') + ',' + ISNULL(@REC_EVCDATA$VACNAME, '')

               END

            CLOSE CUR_EVCDATA

            DEALLOCATE CUR_EVCDATA

         END
      ELSE 
         BEGIN

            SELECT @EVCHRS = isnull(sum(HRA_EVCREC.VAC_DAYS * 8 + HRA_EVCREC.VAC_HRS), 0)
            FROM HRP.HRA_EVCREC
            WHERE 
               HRA_EVCREC.EMP_NO = @EMPNO_IN AND 
               HRA_EVCREC.END_DATE = @DATE_IN AND 
               HRA_EVCREC.STATUS NOT IN ( 'N', 'D' )

            IF @EVCHRS <> 0
               BEGIN

                  SELECT @EVCSTART = min(HRA_EVCREC.START_TIME), @EVCEND = max(HRA_EVCREC.END_TIME)
                  FROM HRP.HRA_EVCREC
                  WHERE 
                     HRA_EVCREC.EMP_NO = @EMPNO_IN AND 
                     HRA_EVCREC.END_DATE = @DATE_IN AND 
                     HRA_EVCREC.STATUS <> 'N'

                  DECLARE
                      CUR_EVCDATA CURSOR LOCAL FOR 
                        /*
                        *   SSMA warning messages:
                        *   O2SS0273: Oracle SUBSTR function and SQL Server SUBSTRING function may give different results.
                        *   O2SS0273: Oracle SUBSTR function and SQL Server SUBSTRING function may give different results.
                        */

                        SELECT DISTINCT 
                           CASE 
                              WHEN A.VAC_TYPE IN ( 'E', 'P', 'S', 'U' ) THEN ISNULL(isnull(substring(M.VAC_NAME, 1, ssma_oracle.instr4_varchar(M.VAC_NAME, '(', 1, 1) - 1), M.VAC_NAME), '') + '(' + ISNULL(D.RUL_NAME, '') + ')'
                              ELSE isnull(substring(M.VAC_NAME, 1, ssma_oracle.instr4_varchar(M.VAC_NAME, '(', 1, 1) - 1), M.VAC_NAME)
                           END AS VACNAME
                        FROM HRP.HRA_EVCREC  AS A, HRP.HRA_VCRLMST  AS M, HRP.HRA_VCRLDTL  AS D
                        WHERE 
                           A.EMP_NO = @EMPNO_IN AND 
                           @DATE_IN BETWEEN A.START_DATE AND A.END_DATE AND 
                           A.STATUS NOT IN ( 'N', 'D' ) AND 
                           A.VAC_TYPE = M.VAC_TYPE AND 
                           A.VAC_RUL = D.VAC_RUL

                  OPEN CUR_EVCDATA

                  WHILE 1 = 1
                  
                     BEGIN

                        FETCH CUR_EVCDATA
                            INTO @REC_EVCDATA$VACNAME

                        /*
                        *   SSMA warning messages:
                        *   O2SS0113: The value of @@FETCH_STATUS might be changed by previous FETCH operations on other cursors, if the cursors are used simultaneously.
                        */

                        IF @@FETCH_STATUS <> 0
                           BREAK

                        IF @VACTYPE IS NULL OR @VACTYPE = ''
                           SET @VACTYPE = @REC_EVCDATA$VACNAME
                        ELSE 
                           SET @VACTYPE = ISNULL(@VACTYPE, '') + ',' + ISNULL(@REC_EVCDATA$VACNAME, '')

                     END

                  CLOSE CUR_EVCDATA

                  DEALLOCATE CUR_EVCDATA

               END
            ELSE 
               BEGIN

                  SELECT @EVCHRS = isnull(sum(HRA_EVCREC.VAC_DAYS * 8 + HRA_EVCREC.VAC_HRS), 0)
                  FROM HRP.HRA_EVCREC
                  WHERE 
                     HRA_EVCREC.EMP_NO = @EMPNO_IN AND 
                     HRA_EVCREC.START_DATE < @DATE_IN AND 
                     HRA_EVCREC.END_DATE > @DATE_IN AND 
                     HRA_EVCREC.STATUS NOT IN ( 'N', 'D' )

                  IF @EVCHRS <> 0
                     BEGIN

                        SELECT @EVCSTART = min(HRA_EVCREC.START_TIME), @EVCEND = max(HRA_EVCREC.END_TIME)
                        FROM HRP.HRA_EVCREC
                        WHERE 
                           HRA_EVCREC.EMP_NO = @EMPNO_IN AND 
                           HRA_EVCREC.START_DATE < @DATE_IN AND 
                           HRA_EVCREC.END_DATE > @DATE_IN AND 
                           HRA_EVCREC.STATUS <> 'N'

                        DECLARE
                            CUR_EVCDATA CURSOR LOCAL FOR 
                              /*
                              *   SSMA warning messages:
                              *   O2SS0273: Oracle SUBSTR function and SQL Server SUBSTRING function may give different results.
                              *   O2SS0273: Oracle SUBSTR function and SQL Server SUBSTRING function may give different results.
                              */

                              SELECT DISTINCT 
                                 CASE 
                                    WHEN A.VAC_TYPE IN ( 'E', 'P', 'S', 'U' ) THEN ISNULL(isnull(substring(M.VAC_NAME, 1, ssma_oracle.instr4_varchar(M.VAC_NAME, '(', 1, 1) - 1), M.VAC_NAME), '') + '(' + ISNULL(D.RUL_NAME, '') + ')'
                                    ELSE isnull(substring(M.VAC_NAME, 1, ssma_oracle.instr4_varchar(M.VAC_NAME, '(', 1, 1) - 1), M.VAC_NAME)
                                 END AS VACNAME
                              FROM HRP.HRA_EVCREC  AS A, HRP.HRA_VCRLMST  AS M, HRP.HRA_VCRLDTL  AS D
                              WHERE 
                                 A.EMP_NO = @EMPNO_IN AND 
                                 @DATE_IN BETWEEN A.START_DATE AND A.END_DATE AND 
                                 A.STATUS NOT IN ( 'N', 'D' ) AND 
                                 A.VAC_TYPE = M.VAC_TYPE AND 
                                 A.VAC_RUL = D.VAC_RUL

                        OPEN CUR_EVCDATA

                        WHILE 1 = 1
                        
                           BEGIN

                              FETCH CUR_EVCDATA
                                  INTO @REC_EVCDATA$VACNAME

                              /*
                              *   SSMA warning messages:
                              *   O2SS0113: The value of @@FETCH_STATUS might be changed by previous FETCH operations on other cursors, if the cursors are used simultaneously.
                              */

                              IF @@FETCH_STATUS <> 0
                                 BREAK

                              IF @VACTYPE IS NULL OR @VACTYPE = ''
                                 SET @VACTYPE = @REC_EVCDATA$VACNAME
                              ELSE 
                                 SET @VACTYPE = ISNULL(@VACTYPE, '') + ',' + ISNULL(@REC_EVCDATA$VACNAME, '')

                           END

                        CLOSE CUR_EVCDATA

                        DEALLOCATE CUR_EVCDATA

                     END

               END

         END

      IF @SUPHRS <> 0 AND @EVCHRS = 0
         IF @SUPHRS >= 8
            BEGIN

               SET @OUTPUT = 'NO'

               IF @TYPE_IN IN ( 'inreadesc', 'outreadesc' )
                  SET @OUTPUT = '補休假'

            END
         ELSE 
            IF @TYPE_IN IN ( 'in', 'inreadesc' )
               IF @SUPSTART = @CHECKTIME
                  BEGIN

                     /*從上班時間開始休*/
                     SET @OUTPUT = @SUPEND

                     IF @CLASS_IN = 'DK' AND @SUPEND BETWEEN '1200' AND '1330'
                        SET @OUTPUT = '1330'
                     ELSE 
                        BEGIN
                           IF @CLASS_IN = 'BE' AND @SUPEND BETWEEN '1200' AND '1300'
                              SET @OUTPUT = '1300'
                        END

                     IF @TYPE_IN IN (  'inreadesc' )
                        SET @OUTPUT = '補休假'

                  END
               ELSE 
                  SET @OUTPUT = @CHECKTIME
            ELSE 
               BEGIN
                  IF @TYPE_IN IN ( 'out', 'outreadesc' )
                     IF @SUPEND = @CHECKTIME
                        BEGIN

                           /*休到下班時間*/
                           SET @OUTPUT = @SUPSTART

                           IF @CLASS_IN = 'DK' AND @SUPSTART BETWEEN '1200' AND '1330'
                              SET @OUTPUT = '1200'
                           ELSE 
                              BEGIN
                                 IF @CLASS_IN = 'BE' AND @SUPSTART BETWEEN '1200' AND '1300'
                                    SET @OUTPUT = '1200'
                              END

                           IF @TYPE_IN IN (  'outreadesc' )
                              SET @OUTPUT = '補休假'

                        END
                     ELSE 
                        SET @OUTPUT = @CHECKTIME
               END
      ELSE 
         IF @SUPHRS = 0 AND @EVCHRS <> 0
            IF @EVCHRS < 8
               /*確定只請一天內*/
               IF @TYPE_IN IN ( 'in', 'inreadesc' )
                  IF @EVCSTART = @CHECKTIME
                     BEGIN

                        /*從上班時間開始休*/
                        SET @OUTPUT = @EVCEND

                        IF @CLASS_IN = 'DK' AND @EVCEND BETWEEN '1200' AND '1330'
                           SET @OUTPUT = '1330'
                        ELSE 
                           BEGIN
                              IF @CLASS_IN = 'BE' AND @EVCEND BETWEEN '1200' AND '1300'
                                 SET @OUTPUT = '1300'
                           END

                        IF @TYPE_IN IN (  'inreadesc' )
                           SET @OUTPUT = @VACTYPE

                     END
                  ELSE 
                     SET @OUTPUT = @CHECKTIME
               ELSE 
                  BEGIN
                     IF @TYPE_IN IN ( 'out', 'outreadesc' )
                        IF @EVCEND = @CHECKTIME
                           BEGIN

                              /*休到下班時間*/
                              SET @OUTPUT = @EVCSTART

                              IF @CLASS_IN = 'DK' AND @EVCSTART BETWEEN '1200' AND '1330'
                                 SET @OUTPUT = '1200'
                              ELSE 
                                 BEGIN
                                    IF @CLASS_IN = 'BE' AND @EVCSTART BETWEEN '1200' AND '1300'
                                       SET @OUTPUT = '1200'
                                 END

                              IF @TYPE_IN IN (  'outreadesc' )
                                 SET @OUTPUT = @VACTYPE

                           END
                        ELSE 
                           SET @OUTPUT = @CHECKTIME
                  END
            ELSE 
               BEGIN

                  /*請一天(含)以上，該天不需打卡*/
                  SET @OUTPUT = 'NO'

                  IF @TYPE_IN IN ( 'inreadesc', 'outreadesc' )
                     SET @OUTPUT = @VACTYPE

               END
         ELSE 
            IF @SUPHRS <> 0 AND @EVCHRS <> 0
               IF @SUPHRS + @EVCHRS < 8
                  BEGIN
                     /*確定只請一天內*/
                     IF @SUPSTART > @EVCSTART
                        /*補休時間早於假卡時間*/
                        DECLARE
                           @db_null_statement int
                  END
               ELSE 
                  BEGIN

                     /*請一天(含)以上，該天不需打卡*/
                     SET @OUTPUT = 'NO'

                     IF @TYPE_IN IN ( 'inreadesc', 'outreadesc' )
                        SET @OUTPUT = @VACTYPE

                  END
            ELSE 
               BEGIN
                  IF @SUPHRS = 0 AND @EVCHRS = 0
                     SET @OUTPUT = @CHECKTIME
               END

      IF @OUTPUT IS NULL OR @OUTPUT = ''
         SET @OUTPUT = @CHECKTIME

      DECLARE
         @db_null_statement$2 int

      CONTINUE_FOREACH1:

      DECLARE
         @db_null_statement$3 int

      SET @return_value_argument = @OUTPUT

      RETURN 

   END
GO
BEGIN TRY
    EXEC sp_addextendedproperty
        N'MS_SSMA_SOURCE', N'HRP.EHRPHRAFUNC_PKG.F_FREESIGNTIME',
        N'SCHEMA', N'hrp',
        N'PROCEDURE', N'EHRPHRAFUNC_PKG$F_FREESIGNTIME$IMPL'
END TRY
BEGIN CATCH
    IF (@@TRANCOUNT > 0) ROLLBACK
    PRINT ERROR_MESSAGE()
END CATCH
GO
