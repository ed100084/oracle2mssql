CREATE OR ALTER FUNCTION [ehrphrafunc_pkg].[f_getcondition]
(    @SchYm_IN NVARCHAR(MAX),
    @EmpNo_IN NVARCHAR(MAX)
)
RETURNS NVARCHAR(MAX)
AS
BEGIN
DECLARE @sSchYm NVARCHAR(10) = @SchYm_IN;
DECLARE @sEmpNo NVARCHAR(10) = @EmpNo_IN;
DECLARE @sResults NVARCHAR(1);
DECLARE @iCnt INT = 0;
DECLARE @iDays INT = 0;
    SET @iDays = CAST(FORMAT(EOMONTH(CONVERT(DATETIME2, @sSchYm + '-01')), 'dd') AS DECIMAL(38,10));
  
    IF @iDays = 28 BEGIN
      -- EXCEPTION block removed: TRY/CATCH not allowed in T-SQL scalar function

    SELECT @iCnt = COUNT(*)
    FROM hra_classsch
         WHERE hra_classsch.sch_ym = @sSchYm
           AND hra_classsch.emp_no = @sEmpNo
           AND (hra_classsch.sch_01 is null or hra_classsch.sch_02 is null or
               hra_classsch.sch_03 is null or hra_classsch.sch_04 is null or
               hra_classsch.sch_05 is null or hra_classsch.sch_06 is null or
               hra_classsch.sch_07 is null or hra_classsch.sch_08 is null or
               hra_classsch.sch_09 is null or hra_classsch.sch_10 is null or
               hra_classsch.sch_11 is null or hra_classsch.sch_12 is null or
               hra_classsch.sch_13 is null or hra_classsch.sch_14 is null or
               hra_classsch.sch_15 is null or hra_classsch.sch_16 is null or
               hra_classsch.sch_17 is null or hra_classsch.sch_18 is null or
               hra_classsch.sch_19 is null or hra_classsch.sch_20 is null or
               hra_classsch.sch_21 is null or hra_classsch.sch_22 is null or
               hra_classsch.sch_23 is null or hra_classsch.sch_24 is null or
               hra_classsch.sch_25 is null or hra_classsch.sch_26 is null or
               hra_classsch.sch_27 is null or hra_classsch.sch_28 is null);

    END
ELSE IF @iDays = 29 BEGIN
      -- EXCEPTION block removed: TRY/CATCH not allowed in T-SQL scalar function

    SELECT @iCnt = COUNT(*)
    FROM hra_classsch
         WHERE hra_classsch.sch_ym = @sSchYm
           AND hra_classsch.emp_no = @sEmpNo
           AND (hra_classsch.sch_01 is null or hra_classsch.sch_02 is null or
               hra_classsch.sch_03 is null or hra_classsch.sch_04 is null or
               hra_classsch.sch_05 is null or hra_classsch.sch_06 is null or
               hra_classsch.sch_07 is null or hra_classsch.sch_08 is null or
               hra_classsch.sch_09 is null or hra_classsch.sch_10 is null or
               hra_classsch.sch_11 is null or hra_classsch.sch_12 is null or
               hra_classsch.sch_13 is null or hra_classsch.sch_14 is null or
               hra_classsch.sch_15 is null or hra_classsch.sch_16 is null or
               hra_classsch.sch_17 is null or hra_classsch.sch_18 is null or
               hra_classsch.sch_19 is null or hra_classsch.sch_20 is null or
               hra_classsch.sch_21 is null or hra_classsch.sch_22 is null or
               hra_classsch.sch_23 is null or hra_classsch.sch_24 is null or
               hra_classsch.sch_25 is null or hra_classsch.sch_26 is null or
               hra_classsch.sch_27 is null or hra_classsch.sch_28 is null or
               hra_classsch.sch_29 is null);

    END
ELSE IF @iDays = 30 BEGIN
      -- EXCEPTION block removed: TRY/CATCH not allowed in T-SQL scalar function

    SELECT @iCnt = COUNT(*)
    FROM hra_classsch
         WHERE hra_classsch.sch_ym = @sSchYm
           AND hra_classsch.emp_no = @sEmpNo
           AND (hra_classsch.sch_01 is null or hra_classsch.sch_02 is null or
               hra_classsch.sch_03 is null or hra_classsch.sch_04 is null or
               hra_classsch.sch_05 is null or hra_classsch.sch_06 is null or
               hra_classsch.sch_07 is null or hra_classsch.sch_08 is null or
               hra_classsch.sch_09 is null or hra_classsch.sch_10 is null or
               hra_classsch.sch_11 is null or hra_classsch.sch_12 is null or
               hra_classsch.sch_13 is null or hra_classsch.sch_14 is null or
               hra_classsch.sch_15 is null or hra_classsch.sch_16 is null or
               hra_classsch.sch_17 is null or hra_classsch.sch_18 is null or
               hra_classsch.sch_19 is null or hra_classsch.sch_20 is null or
               hra_classsch.sch_21 is null or hra_classsch.sch_22 is null or
               hra_classsch.sch_23 is null or hra_classsch.sch_24 is null or
               hra_classsch.sch_25 is null or hra_classsch.sch_26 is null or
               hra_classsch.sch_27 is null or hra_classsch.sch_28 is null or
               hra_classsch.sch_29 is null or hra_classsch.sch_30 is null);

    END
    ELSE
    BEGIN
      -- EXCEPTION block removed: TRY/CATCH not allowed in T-SQL scalar function

    SELECT @iCnt = COUNT(*)
    FROM hra_classsch
         WHERE hra_classsch.sch_ym = @sSchYm
           AND hra_classsch.emp_no = @sEmpNo
           AND (hra_classsch.sch_01 is null or hra_classsch.sch_02 is null or
               hra_classsch.sch_03 is null or hra_classsch.sch_04 is null or
               hra_classsch.sch_05 is null or hra_classsch.sch_06 is null or
               hra_classsch.sch_07 is null or hra_classsch.sch_08 is null or
               hra_classsch.sch_09 is null or hra_classsch.sch_10 is null or
               hra_classsch.sch_11 is null or hra_classsch.sch_12 is null or
               hra_classsch.sch_13 is null or hra_classsch.sch_14 is null or
               hra_classsch.sch_15 is null or hra_classsch.sch_16 is null or
               hra_classsch.sch_17 is null or hra_classsch.sch_18 is null or
               hra_classsch.sch_19 is null or hra_classsch.sch_20 is null or
               hra_classsch.sch_21 is null or hra_classsch.sch_22 is null or
               hra_classsch.sch_23 is null or hra_classsch.sch_24 is null or
               hra_classsch.sch_25 is null or hra_classsch.sch_26 is null or
               hra_classsch.sch_27 is null or hra_classsch.sch_28 is null or
               hra_classsch.sch_29 is null or hra_classsch.sch_30 is null or
               hra_classsch.sch_28 is null);

    END
  
    IF @iCnt = 0 BEGIN
      SET @sResults = 'A';
    END
    ELSE
    BEGIN
      SET @sResults = 'B';
    END
  
    RETURN(@sResults);
END
GO
