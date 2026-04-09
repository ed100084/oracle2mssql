CREATE OR ALTER FUNCTION [ehrphrafunc_pkg].[f_getClassKind]
(    @empno_IN NVARCHAR(MAX),
    @Date_IN DATETIME2(0),
    @OrganType_IN NVARCHAR(MAX)
)
RETURNS NVARCHAR(MAX)
AS
BEGIN
DECLARE @SOrganType NVARCHAR(10);
DECLARE @iClassCode NVARCHAR(3);
    SET @SOrganType = @OrganType_IN;
    -- EXCEPTION block removed: TRY/CATCH not allowed in T-SQL scalar function

    SELECT @iClassCode = CASE WHEN SUBSTRING(FORMAT(@Date_IN, 'yyyy-mm-dd'), 9, 10) = '01' THEN sch_01 WHEN SUBSTRING(FORMAT(@Date_IN, 'yyyy-mm-dd'), 9, 10) = '02' THEN sch_02 WHEN SUBSTRING(FORMAT(@Date_IN, 'yyyy-mm-dd'), 9, 10) = '03' THEN sch_03 WHEN SUBSTRING(FORMAT(@Date_IN, 'yyyy-mm-dd'), 9, 10) = '04' THEN sch_04 WHEN SUBSTRING(FORMAT(@Date_IN, 'yyyy-mm-dd'), 9, 10) = '05' THEN sch_05 WHEN SUBSTRING(FORMAT(@Date_IN, 'yyyy-mm-dd'), 9, 10) = '06' THEN sch_06 WHEN SUBSTRING(FORMAT(@Date_IN, 'yyyy-mm-dd'), 9, 10) = '07' THEN sch_07 WHEN SUBSTRING(FORMAT(@Date_IN, 'yyyy-mm-dd'), 9, 10) = '08' THEN sch_08 WHEN SUBSTRING(FORMAT(@Date_IN, 'yyyy-mm-dd'), 9, 10) = '09' THEN sch_09 WHEN SUBSTRING(FORMAT(@Date_IN, 'yyyy-mm-dd'), 9, 10) = '10' THEN sch_10 WHEN SUBSTRING(FORMAT(@Date_IN, 'yyyy-mm-dd'), 9, 10) = '11' THEN sch_11 WHEN SUBSTRING(FORMAT(@Date_IN, 'yyyy-mm-dd'), 9, 10) = '12' THEN sch_12 WHEN SUBSTRING(FORMAT(@Date_IN, 'yyyy-mm-dd'), 9, 10) = '13' THEN sch_13 WHEN SUBSTRING(FORMAT(@Date_IN, 'yyyy-mm-dd'), 9, 10) = '14' THEN sch_14 WHEN SUBSTRING(FORMAT(@Date_IN, 'yyyy-mm-dd'), 9, 10) = '15' THEN sch_15 WHEN SUBSTRING(FORMAT(@Date_IN, 'yyyy-mm-dd'), 9, 10) = '16' THEN sch_16 WHEN SUBSTRING(FORMAT(@Date_IN, 'yyyy-mm-dd'), 9, 10) = '17' THEN sch_17 WHEN SUBSTRING(FORMAT(@Date_IN, 'yyyy-mm-dd'), 9, 10) = '18' THEN sch_18 WHEN SUBSTRING(FORMAT(@Date_IN, 'yyyy-mm-dd'), 9, 10) = '19' THEN sch_19 WHEN SUBSTRING(FORMAT(@Date_IN, 'yyyy-mm-dd'), 9, 10) = '20' THEN sch_20 WHEN SUBSTRING(FORMAT(@Date_IN, 'yyyy-mm-dd'), 9, 10) = '21' THEN sch_21 WHEN SUBSTRING(FORMAT(@Date_IN, 'yyyy-mm-dd'), 9, 10) = '22' THEN sch_22 WHEN SUBSTRING(FORMAT(@Date_IN, 'yyyy-mm-dd'), 9, 10) = '23' THEN sch_23 WHEN SUBSTRING(FORMAT(@Date_IN, 'yyyy-mm-dd'), 9, 10) = '24' THEN sch_24 WHEN SUBSTRING(FORMAT(@Date_IN, 'yyyy-mm-dd'), 9, 10) = '25' THEN sch_25 WHEN SUBSTRING(FORMAT(@Date_IN, 'yyyy-mm-dd'), 9, 10) = '26' THEN sch_26 WHEN SUBSTRING(FORMAT(@Date_IN, 'yyyy-mm-dd'), 9, 10) = '27' THEN sch_27 WHEN SUBSTRING(FORMAT(@Date_IN, 'yyyy-mm-dd'), 9, 10) = '28' THEN sch_28 WHEN SUBSTRING(FORMAT(@Date_IN, 'yyyy-mm-dd'), 9, 10) = '29' THEN sch_29 WHEN SUBSTRING(FORMAT(@Date_IN, 'yyyy-mm-dd'), 9, 10) = '30' THEN sch_30 WHEN SUBSTRING(FORMAT(@Date_IN, 'yyyy-mm-dd'), 9, 10) = '31' THEN sch_31 END
    FROM hra_classsch
       Where EMP_NO = @empno_IN
         AND SCH_YM = FORMAT(@Date_IN, 'yyyy-mm')
         AND ORG_BY = @SOrganType;
    return @iClassCode;
END
GO
