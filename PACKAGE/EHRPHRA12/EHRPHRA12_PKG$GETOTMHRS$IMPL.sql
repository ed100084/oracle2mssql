
USE MIS
GO
 IF NOT EXISTS(SELECT * FROM sys.schemas WHERE [name] = N'hrp')      
     EXEC (N'CREATE SCHEMA hrp')                                   
 GO                                                               

USE MIS
GO
IF  EXISTS (SELECT * FROM sys.objects so JOIN sys.schemas sc ON so.schema_id = sc.schema_id WHERE so.name = N'EHRPHRA12_PKG$GETOTMHRS$IMPL'  AND sc.name=N'hrp'  AND type in (N'P',N'PC'))
 DROP PROCEDURE [hrp].[EHRPHRA12_PKG$GETOTMHRS$IMPL]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE HRP.EHRPHRA12_PKG$GETOTMHRS$IMPL  
   @P_START_DATE varchar(max),
   @P_START_TIME varchar(max),
   @P_END_DATE varchar(max),
   @P_END_TIME varchar(max),
   @P_EMP_NO varchar(max),
   @ORGANTYPE_IN varchar(max),
   /*
   *   SSMA warning messages:
   *   O2SS0356: Conversion from NUMBER datatype can cause data loss.
   */

   @return_value_argument float(53)  OUTPUT
AS 
   BEGIN

      EXECUTE ssma_oracle.db_fn_check_init_package 'HRP', 'EHRPHRA12_PKG'

      DECLARE
         @RTNCODE numeric(4), 
         @ISMIN numeric(4), 
         @IEMIN numeric(4), 
         @ISREST numeric(4), 
         @IEREST numeric(4), 
         @SCLASSKIND varchar(3), 
         @IRESTSTARTTIME varchar(4), 
         @IENDRESTTIME varchar(4), 
         @SORGANTYPE varchar(10) = @ORGANTYPE_IN

      SET @RTNCODE = 0

      SET @ISMIN = substring(@P_START_TIME, 1, 2) * 60 + CAST(substring(@P_START_TIME, 3, 4) AS float(53))

      SET @IEMIN = substring(@P_END_TIME, 1, 2) * 60 + CAST(substring(@P_END_TIME, 3, 4) AS float(53))

      SET @SCLASSKIND = HRP.EHRPHRAFUNC_PKG$F_GETCLASSKIND(@P_EMP_NO, ssma_oracle.to_date2(@P_START_DATE, 'yyyy-mm-dd'), @SORGANTYPE)

      BEGIN

         BEGIN TRY
            SELECT @IRESTSTARTTIME = TBL.START_REST, @IENDRESTTIME = TBL.END_REST
            FROM HRP.HRA_CLASSDTL  AS TBL
            WHERE TBL.CLASS_CODE = @SCLASSKIND AND TBL.SHIFT_NO IN (  '1'/* 僅取時段1的休息時間*/ )
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

                  SET @IRESTSTARTTIME = '1200'

                  SET @IENDRESTTIME = '1300'

                  SET @ISREST = 12 * 60

                  SET @IEREST = 13 * 60

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

      IF @IRESTSTARTTIME <> '0' AND @IRESTSTARTTIME <> '0'
         BEGIN

            SET @ISREST = substring(@IRESTSTARTTIME, 1, 2) * 60 + CAST(substring(@IRESTSTARTTIME, 3, 4) AS float(53))

            SET @IEREST = substring(@IENDRESTTIME, 1, 2) * 60 + CAST(substring(@IENDRESTTIME, 3, 4) AS float(53))

         END
      ELSE 
         BEGIN

            /*扣 中午午休 BY SZUHAO AT 2007-06-06*/
            SET @IRESTSTARTTIME = '1200'

            SET @IENDRESTTIME = '1300'

            SET @ISREST = 12 * 60

            SET @IEREST = 13 * 60
            /*
            *     REMARK BY SZUHAO AT 2007-06-06
            *       iSrest :='0';
            *       iErest :='0';
            *
            */

         END

      /*當日*/
      IF @P_START_DATE = @P_END_DATE
         /* 介於 1200~1330 之間*/
         IF (@P_START_TIME BETWEEN @IRESTSTARTTIME AND @IENDRESTTIME) AND (@P_END_TIME BETWEEN @IRESTSTARTTIME AND @IENDRESTTIME)
            SET @RTNCODE = @IEMIN - @ISMIN
         ELSE 
            IF (@P_START_TIME BETWEEN @IRESTSTARTTIME AND @IENDRESTTIME)
               /* 起始時間介於 iRestStartTime~iEndRestTime*/
               SET @RTNCODE = @IEMIN - @IEREST
            ELSE 
               IF (@P_END_TIME BETWEEN @IRESTSTARTTIME AND @IENDRESTTIME)
                  /* 結束時間介於 iRestStartTime~iEndRestTime*/
                  SET @RTNCODE = @ISREST - @ISMIN
               ELSE 
                  IF (@IRESTSTARTTIME BETWEEN @P_START_TIME AND @P_END_TIME)
                     /* Stime 及 Etiem 介於 iRestStartTime~iEndRestTime*/
                     SET @RTNCODE = @ISREST - @ISMIN + @IEMIN - @IEREST
                  ELSE 
                     SET @RTNCODE = @IEMIN - @ISMIN
      ELSE 
         BEGIN

            /*跨天*/
            IF @P_START_TIME BETWEEN @IENDRESTTIME AND '2400'
               SET @RTNCODE = 1440 - @ISMIN
            ELSE 
               IF @P_START_TIME BETWEEN @IRESTSTARTTIME AND @IENDRESTTIME
                  SET @RTNCODE = 1440 - @IEREST
               ELSE 
                  SET @RTNCODE = 1440 - @ISMIN - (@IEREST - @ISREST)

            IF @P_END_TIME BETWEEN '0000' AND @IRESTSTARTTIME
               SET @RTNCODE = @RTNCODE + @IEMIN
            ELSE 
               IF @P_END_TIME BETWEEN @IRESTSTARTTIME AND @IENDRESTTIME
                  SET @RTNCODE = @RTNCODE + @ISREST
               ELSE 
                  SET @RTNCODE = @RTNCODE + @ISREST + @IEMIN - @IEREST

         END

      SET @return_value_argument = @RTNCODE

      RETURN 

   END
GO
BEGIN TRY
    EXEC sp_addextendedproperty
        N'MS_SSMA_SOURCE', N'HRP.EHRPHRA12_PKG.getOtmhrs',
        N'SCHEMA', N'hrp',
        N'PROCEDURE', N'EHRPHRA12_PKG$GETOTMHRS$IMPL'
END TRY
BEGIN CATCH
    IF (@@TRANCOUNT > 0) ROLLBACK
    PRINT ERROR_MESSAGE()
END CATCH
GO
