
USE MIS
GO
 IF NOT EXISTS(SELECT * FROM sys.schemas WHERE [name] = N'hrp')      
     EXEC (N'CREATE SCHEMA hrp')                                   
 GO                                                               

USE MIS
GO
IF  EXISTS (SELECT * FROM sys.objects so JOIN sys.schemas sc ON so.schema_id = sc.schema_id WHERE so.name = N'EHRPHRA12_PKG$HRAC061'  AND sc.name=N'hrp'  AND type in (N'P',N'PC'))
 DROP PROCEDURE [hrp].[EHRPHRA12_PKG$HRAC061]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE HRP.EHRPHRA12_PKG$HRAC061  
   @EMPNO_IN varchar(max),
   @STARTDATE_IN varchar(max),
   @USER_IN varchar(max),
   /*
   *   SSMA warning messages:
   *   O2SS0356: Conversion from NUMBER datatype can cause data loss.
   */

   @RTNCODE float(53)  OUTPUT
AS 
   BEGIN

      DECLARE
         /*
         *   SSMA warning messages:
         *   O2SS0356: Conversion from NUMBER datatype can cause data loss.
         */

         @ICNT float(53), 
         @IMERGE varchar(1), 
         @ICLASSCODE varchar(4), 
         /*
         *   SSMA warning messages:
         *   O2SS0356: Conversion from NUMBER datatype can cause data loss.
         */

         @ISOTMHRS float(53), 
         /*
         *   SSMA warning messages:
         *   O2SS0356: Conversion from NUMBER datatype can cause data loss.
         */

         @ISUMHRS float(53), 
         /*
         *   SSMA warning messages:
         *   O2SS0356: Conversion from NUMBER datatype can cause data loss.
         */

         @IWORKHRS float(53), 
         /*
         *   SSMA warning messages:
         *   O2SS0356: Conversion from NUMBER datatype can cause data loss.
         */

         @ITOTALHRS float(53), 
         /*
         *   SSMA warning messages:
         *   O2SS0356: Conversion from NUMBER datatype can cause data loss.
         */

         @SSONEO float(53), 
         /*
         *   SSMA warning messages:
         *   O2SS0356: Conversion from NUMBER datatype can cause data loss.
         */

         @SSONEOTT float(53), 
         /*
         *   SSMA warning messages:
         *   O2SS0356: Conversion from NUMBER datatype can cause data loss.
         */

         @SSONEOSS float(53), 
         /*
         *   SSMA warning messages:
         *   O2SS0356: Conversion from NUMBER datatype can cause data loss.
         */

         @SSONEUU float(53)

      BEGIN TRY

         SET @RTNCODE = NULL

         EXECUTE ssma_oracle.db_check_init_package 'HRP', 'EHRPHRA12_PKG'

         SET @RTNCODE = 0

         SELECT @ICNT = count_big(*)
         FROM HRP.HRA_OFFREC
         WHERE HRA_OFFREC.EMP_NO = @EMPNO_IN AND ssma_oracle.to_char_date(HRA_OFFREC.START_DATE_TMP, 'yyyy-mm-dd') = @STARTDATE_IN

         IF @ICNT > 0
            BEGIN

               SELECT @IMERGE = max(HRA_OFFREC.MERGE)
               FROM HRP.HRA_OFFREC
               WHERE HRA_OFFREC.EMP_NO = @EMPNO_IN AND ssma_oracle.to_char_date(HRA_OFFREC.START_DATE_TMP, 'yyyy-mm-dd') = @STARTDATE_IN

               SET @ISUMHRS = 0

               BEGIN

                  DECLARE
                     @I int

                  SET @I = 0

                  DECLARE
                     @loop$bound int

                  SET @loop$bound = CAST(@IMERGE AS numeric(38, 10))

                  WHILE @I <= @loop$bound
                  
                     BEGIN

                        SET @SSONEO = 0

                        SET @SSONEOTT = 0

                        SET @SSONEOSS = 0

                        SET @SSONEUU = 0

                        SELECT @ICLASSCODE = HRA_OFFREC.CLASS_CODE, @ISOTMHRS = HRA_OFFREC.SOTM_HRS
                        FROM HRP.HRA_OFFREC
                        WHERE 
                           HRA_OFFREC.EMP_NO = @EMPNO_IN AND 
                           ssma_oracle.to_char_date(HRA_OFFREC.START_DATE_TMP, 'yyyy-mm-dd') = @STARTDATE_IN AND 
                           HRA_OFFREC.MERGE = CAST(@I AS varchar(max))

                        IF @ICLASSCODE = 'ZZ'
                           IF @ISUMHRS + @ISOTMHRS <= 2
                              SET @SSONEOTT = @ISOTMHRS
                           ELSE 
                              IF @ISUMHRS + @ISOTMHRS > 2 AND @ISUMHRS + @ISOTMHRS <= 8
                                 IF @ISUMHRS < 2
                                    BEGIN

                                       /*前面加班時數尚未滿2小時，則4/3時數還有配額*/
                                       SET @SSONEOTT = 2 - @ISUMHRS

                                       SET @SSONEOSS = @ISOTMHRS - (2 - @ISUMHRS)

                                    END
                                 ELSE 
                                    /*前面加班時數滿2小時，則4/3時數無配額*/
                                    SET @SSONEOSS = @ISOTMHRS
                              ELSE 
                                 BEGIN
                                    IF @ISUMHRS + @ISOTMHRS > 8 AND @ISUMHRS + @ISOTMHRS <= 12
                                       IF @ISUMHRS < 2
                                          BEGIN

                                             /*前面加班時數尚未滿2小時，則4/3時數還有配額*/
                                             SET @SSONEOTT = 2 - @ISUMHRS

                                             SET @SSONEOSS = 6

                                             SET @SSONEUU = @ISOTMHRS - 6 - (2 - @ISUMHRS)

                                          END
                                       ELSE 
                                          /*前面加班時數滿2小時，則4/3時數無配額*/
                                          IF @ISUMHRS - 2 < 6
                                             BEGIN

                                                /*5/3時數還有配額*/
                                                SET @SSONEOSS = 6 - (@ISUMHRS - 2)

                                                SET @SSONEUU = @ISOTMHRS - (6 - (@ISUMHRS - 2))

                                             END
                                          ELSE 
                                             /*5/3時數無配額*/
                                             SET @SSONEUU = @ISOTMHRS
                                 END
                        ELSE 
                           IF @ICLASSCODE = 'ZY'
                              IF substring(@EMPNO_IN, 1, 1) IN ( 'S', 'P' )
                                 IF @ISUMHRS = 0
                                    IF @ISOTMHRS <= 8
                                       SET @SSONEO = @ISOTMHRS
                                    ELSE 
                                       BEGIN

                                          SET @SSONEO = 8

                                          IF @ISOTMHRS - 8 <= 2
                                             SET @SSONEOTT = @ISOTMHRS - 8
                                          ELSE 
                                             BEGIN

                                                SET @SSONEOTT = 2

                                                SET @SSONEOSS = @ISOTMHRS - 10

                                             END

                                       END
                                 ELSE 
                                    IF @ISOTMHRS + @ISUMHRS <= 8
                                       SET @SSONEO = @ISOTMHRS
                                    ELSE 
                                       IF @ISUMHRS > 8
                                          IF @ISUMHRS - 8 < 2
                                             BEGIN

                                                /*1:4/3還有配額*/
                                                SET @SSONEOTT = 2 - (@ISUMHRS - 8)

                                                SET @SSONEOSS = @ISOTMHRS - (2 - (@ISUMHRS - 8))

                                             END
                                          ELSE 
                                             SET @SSONEOSS = @ISOTMHRS
                                       ELSE 
                                          BEGIN

                                             /*之前申請時數還未超過(或等於)8小時 iSumHrs <= 8，1:1可能還有配額*/
                                             SET @SSONEO = 8 - @ISUMHRS

                                             IF @ISOTMHRS - (8 - @ISUMHRS) <= 2
                                                SET @SSONEOTT = @ISOTMHRS - (8 - @ISUMHRS)
                                             ELSE 
                                                BEGIN

                                                   SET @SSONEOTT = 2

                                                   SET @SSONEOSS = @ISOTMHRS - (8 - @ISUMHRS) - 2

                                                END

                                          END
                              ELSE 
                                 IF @ISUMHRS = 0
                                    IF @ISOTMHRS <= 8
                                       SET @SSONEO = 8
                                    ELSE 
                                       BEGIN

                                          SET @SSONEO = 8

                                          IF @ISOTMHRS - 8 <= 2
                                             SET @SSONEOTT = @ISOTMHRS - 8
                                          ELSE 
                                             BEGIN

                                                SET @SSONEOTT = 2

                                                SET @SSONEOSS = @ISOTMHRS - 10

                                             END

                                       END
                                 ELSE 
                                    IF @ISOTMHRS + @ISUMHRS <= 8
                                       SET @SSONEO = 0
                                    ELSE 
                                       IF @ISUMHRS <= 8
                                          IF @ISOTMHRS - (8 - @ISUMHRS) <= 2
                                             SET @SSONEOTT = @ISOTMHRS - (8 - @ISUMHRS)
                                          ELSE 
                                             BEGIN

                                                SET @SSONEOTT = 2

                                                SET @SSONEOSS = @ISOTMHRS - (8 - @ISUMHRS) - 2

                                             END
                                       ELSE 
                                          IF @ISUMHRS - 8 < 2
                                             BEGIN

                                                SET @SSONEOTT = 2 - (@ISUMHRS - 8)

                                                SET @SSONEOSS = @ISOTMHRS - (2 - (@ISUMHRS - 8))

                                             END
                                          ELSE 
                                             SET @SSONEOSS = @ISOTMHRS
                           ELSE 
                              IF substring(@EMPNO_IN, 1, 1) IN ( 'S', 'P' )
                                 BEGIN

                                    /*時薪人員需確認出勤班的時數*/
                                    SELECT @IWORKHRS = HRA_CLASSMST.WORK_HRS
                                    FROM HRP.HRA_CLASSMST
                                    WHERE HRA_CLASSMST.CLASS_CODE = @ICLASSCODE

                                    IF @IWORKHRS > 8
                                       SET @IWORKHRS = 8

                                    IF @ISUMHRS = 0
                                       IF @IWORKHRS + @ISOTMHRS <= 8
                                          SET @SSONEO = @ISOTMHRS
                                       ELSE 
                                          BEGIN

                                             SET @SSONEO = 8 - @IWORKHRS

                                             IF @ISOTMHRS - (8 - @IWORKHRS) <= 2
                                                SET @SSONEOTT = @ISOTMHRS - (8 - @IWORKHRS)
                                             ELSE 
                                                BEGIN

                                                   SET @SSONEOTT = 2

                                                   SET @SSONEOSS = @ISOTMHRS - (8 - @IWORKHRS) - 2

                                                END

                                          END
                                    ELSE 
                                       IF @ISOTMHRS + @ISUMHRS + @IWORKHRS <= 8
                                          SET @SSONEO = @ISOTMHRS
                                       ELSE 
                                          IF @ISOTMHRS + @IWORKHRS < 8
                                             BEGIN

                                                /*代表1:1尚有配額*/
                                                SET @SSONEO = 8 - (@ISUMHRS + @IWORKHRS)

                                                IF @ISOTMHRS - (8 - (@ISUMHRS + @IWORKHRS)) <= 2
                                                   SET @SSONEOTT = @ISOTMHRS - (8 - (@ISUMHRS + @IWORKHRS))
                                                ELSE 
                                                   BEGIN

                                                      SET @SSONEOTT = 2

                                                      SET @SSONEOSS = @ISOTMHRS - (8 - (@ISUMHRS + @IWORKHRS)) - 2

                                                   END

                                             END
                                          ELSE 
                                             IF @ISUMHRS + @IWORKHRS = 8
                                                IF @ISOTMHRS <= 2
                                                   SET @SSONEOTT = @ISOTMHRS
                                                ELSE 
                                                   BEGIN

                                                      SET @SSONEOTT = 2

                                                      SET @SSONEOSS = @ISOTMHRS - 2

                                                   END
                                             ELSE 
                                                IF @ISUMHRS + @IWORKHRS - 8 < 2
                                                   /*代表1:4/3尚有配額*/
                                                   IF @ISOTMHRS <= 2 - (@ISUMHRS + @IWORKHRS - 8)
                                                      SET @SSONEOTT = @ISOTMHRS
                                                   ELSE 
                                                      BEGIN

                                                         SET @SSONEOTT = 2 - (@ISUMHRS + @IWORKHRS - 8)

                                                         SET @SSONEOSS = @ISOTMHRS - (2 - (@ISUMHRS + @IWORKHRS - 8))

                                                      END
                                                ELSE 
                                                   SET @SSONEOSS = @ISOTMHRS

                                 END
                              ELSE 
                                 IF @ISUMHRS + @ISOTMHRS <= 2
                                    SET @SSONEOTT = @ISOTMHRS
                                 ELSE 
                                    BEGIN
                                       IF @ISUMHRS + @ISOTMHRS > 2 AND @ISUMHRS + @ISOTMHRS <= 12
                                          IF @ISUMHRS < 2
                                             BEGIN

                                                /*前面加班時數尚未滿2小時，則4/3時數還有配額*/
                                                SET @SSONEOTT = 2 - @ISUMHRS

                                                SET @SSONEOSS = @ISOTMHRS - (2 - @ISUMHRS)

                                             END
                                          ELSE 
                                             /*前面加班時數滿2小時，則4/3時數無配額*/
                                             SET @SSONEOSS = @ISOTMHRS
                                    END

                        SET @ISUMHRS = @ISUMHRS + @ISOTMHRS

                        SET @ITOTALHRS = ceiling(((@SSONEO * 1) + (@SSONEOTT * 4 / 3) + (@SSONEOSS * 5 / 3) + (@SSONEUU * 8 / 3)) * 1000) / 1000

                        UPDATE HRP.HRA_OFFREC
                           SET 
                              OTM_HRS = @ITOTALHRS, 
                              SONEO = @SSONEO, 
                              SONEOTT = @SSONEOTT, 
                              SONEOSS = @SSONEOSS, 
                              SONEUU = @SSONEUU, 
                              LAST_UPDATED_BY = @USER_IN, 
                              LAST_UPDATE_DATE = sysdatetime()
                        WHERE 
                           HRA_OFFREC.EMP_NO = @EMPNO_IN AND 
                           ssma_oracle.to_char_date(HRA_OFFREC.START_DATE_TMP, 'yyyy-mm-dd') = @STARTDATE_IN AND 
                           HRA_OFFREC.MERGE = CAST(@I AS varchar(max))

                        SET @I = @I + 1

                     END

               END

               IF @@TRANCOUNT > 0
                  COMMIT TRANSACTION 

            END

         SET @RTNCODE = @ICNT

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

         BEGIN

            IF @@TRANCOUNT > 0
               ROLLBACK WORK 

            SET @RTNCODE = ssma_oracle.db_error_sqlcode(@exceptionidentifier, @errornumber)

         END

      END CATCH

   END
GO
BEGIN TRY
    EXEC sp_addextendedproperty
        N'MS_SSMA_SOURCE', N'HRP.EHRPHRA12_PKG.hraC061',
        N'SCHEMA', N'hrp',
        N'PROCEDURE', N'EHRPHRA12_PKG$HRAC061'
END TRY
BEGIN CATCH
    IF (@@TRANCOUNT > 0) ROLLBACK
    PRINT ERROR_MESSAGE()
END CATCH
GO
