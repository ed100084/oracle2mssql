CREATE OR ALTER FUNCTION [ehrphrafunc_pkg].[f_getclasshrs]
(    @DeptNo_IN NVARCHAR(MAX),
    @AttDate_IN DATETIME2(0),
    @SchKind_IN NVARCHAR(MAX)
)
RETURNS DECIMAL(38,10)
AS
BEGIN
DECLARE @sDeptNo NVARCHAR(10) = @DeptNo_IN;
DECLARE @dAttDate DATETIME2(0) = @AttDate_IN;
DECLARE @sSchKind NVARCHAR(1) = @SchKind_IN;
DECLARE @sAttDate NVARCHAR(10);
DECLARE @nSchHrs DECIMAL(38,10) = 0;
    SET @sAttDate = FORMAT(@dAttDate, 'yyyy-MM-dd');
  
    -- EXCEPTION block removed: TRY/CATCH not allowed in T-SQL scalar function

    SELECT @nSchHrs = sum(hra_classmst.work_hrs / 8)
    FROM hra_classsch_view, hra_classmst
       WHERE (hra_classsch_view.class_code = hra_classmst.class_code)
         and (hra_classsch_view.dept_no = @sDeptNo AND
             hra_classmst.sch_kind = @sSchKind)
         AND
            --FORMAT(hra_classsch_view.att_date, 'yyyy-MM-dd') = @sAttDate;
             hra_classsch_view.att_date = @sAttDate;

  
    IF @nSchHrs IS NULL BEGIN
      SET @nSchHrs = 0;
    END
  
    RETURN(@nSchHrs);
END
GO
