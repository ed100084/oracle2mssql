CREATE OR ALTER FUNCTION [ehrphra12_pkg].[check_deputy]
(    @p_emp_no NVARCHAR(MAX),
    @p_start_date NVARCHAR(MAX),
    @p_start_time NVARCHAR(MAX),
    @p_end_date NVARCHAR(MAX),
    @p_end_time NVARCHAR(MAX)
)
RETURNS DECIMAL(38,10)
AS
BEGIN
DECLARE @sEmpNo NVARCHAR(20) = @p_emp_no;
DECLARE @sStartDate NVARCHAR(10) = @p_start_date;
DECLARE @sStartTime NVARCHAR(7) = @p_start_time;
DECLARE @sEndDate NVARCHAR(10) = @p_end_date;
DECLARE @sEndTime NVARCHAR(7) = @p_end_time;
DECLARE @iCnt INT;
DECLARE @RtnCode DECIMAL(38,10);
    SET @RtnCode = 0;

      -- 有無此人
      IF @sEmpNo <> 'MIS' BEGIN  -- TEST用

        -- EXCEPTION block removed: TRY/CATCH not allowed in T-SQL scalar function

    SELECT @iCnt = COUNT(*)
    FROM HRP.HRE_EMPBAS
         Where EMP_NO = @sEmpNo
          and disabled = 'N';


      IF @iCnt = 0 BEGIN
      SET @RtnCode = 1;
      GOTO Continue_ForEach1;
      END

       END
       /*
      -- 假單
      BEGIN
          SELECT @iCnt = count(*)
    FROM hra_evcrec
           WHERE ((FORMAT(start_date, 'yyyy-MM-dd') + start_time between
                 @sStartDate + @sStartTime and @sEndDate + @sEndTime)
              OR (FORMAT(end_date, 'yyyy-MM-dd') + end_time between
                 @sStartDate + @sStartTime and @sEndDate + @sEndTime))
             AND EMP_NO = @sEmpNo AND STATUS NOT IN ('N','D');
       EXCEPTION
       WHEN OTHERS THEN
            SET @iCnt = 0;
       END

       IF @iCnt > 0 BEGIN
        SET @RtnCode = 2;
        GOTO Continue_ForEach1;
       END

       -- 新假卡介於db 日期
       IF @iCnt = 0 BEGIN
          BEGIN
             SELECT @iCnt = count(*)
    FROM hra_evcrec
              WHERE ((@sStartDate + @sStartTime between FORMAT(start_date, 'yyyy-MM-dd') + start_time
                                                   and FORMAT(end_date, 'yyyy-MM-dd') + end_time)
                 OR  (@sEndDate   + @sEndTime   between FORMAT(start_date, 'yyyy-MM-dd') + start_time
                                                   and FORMAT(end_date, 'yyyy-MM-dd') + end_time))
                AND EMP_NO = @sEmpNo AND STATUS NOT IN ('N','D');
          EXCEPTION
          WHEN OTHERS THEN
               SET @iCnt = 0;
          END
       END

       IF @iCnt > 0 BEGIN
        SET @RtnCode = 2;
        GOTO Continue_ForEach1;
       END

      -- 借休

      -- 補休

       */
       Continue_ForEach1:
       return @RtnCode;
END
GO
