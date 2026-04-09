CREATE OR ALTER FUNCTION [ehrphrafunc_pkg].[f_getoffamt]
(    @EmpNo_IN NVARCHAR(MAX),
    @DeptNo_IN NVARCHAR(MAX),
    @AttDate_IN DATETIME2(0),
    @StartTime_IN NVARCHAR(MAX),
    @OtmHrs_IN DECIMAL(38,10)
)
RETURNS DECIMAL(38,10)
AS
BEGIN
DECLARE @sEmpNo NVARCHAR(20) = @EmpNo_IN;
DECLARE @sDeptNo NVARCHAR(10) = @DeptNo_IN;
DECLARE @dAttDate DATETIME2(0) = @AttDate_IN;
DECLARE @sStartTime NVARCHAR(4) = @StartTime_IN;
DECLARE @nOtmHrs DECIMAL(38,10) = @OtmHrs_IN;
DECLARE @sAttDate NVARCHAR(10);
DECLARE @sDontCard NVARCHAR(1);
DECLARE @iCnt INT;
DECLARE @nDutyFee DECIMAL(38,10);
    SET @sAttDate = FORMAT(@dAttDate, 'yyyy-MM-dd');
  
    -- EXCEPTION block removed: TRY/CATCH not allowed in T-SQL scalar function

    SELECT @iCnt = COUNT(*)
    FROM HRE_PROFILE
       WHERE EMP_NO = @sEmpNo
         AND ITEM_TYPE = 'Z'
         AND ITEM_NO = 'EMP01';

  
    IF @iCnt = 0 BEGIN
      SET @sDontCard = 'N';
    END
    ELSE
    BEGIN
      SET @sDontCard = 'Y';
    END
  
    IF @sDontCard = 'Y' BEGIN
      -- EXCEPTION block removed: TRY/CATCH not allowed in T-SQL scalar function

    SELECT @nDutyFee = sum(hra_classmst.duty_fee)
    FROM hra_classsch_view, hra_classmst
         WHERE (hra_classsch_view.class_code = hra_classmst.class_code)
           and (hra_classsch_view.emp_no = @sEmpNo)
         GROUP BY hra_classsch_view.att_date
        HAVING hra_classsch_view.att_date = @sAttDate;

    END
    ELSE
    BEGIN
      -- EXCEPTION block removed: TRY/CATCH not allowed in T-SQL scalar function

    SELECT @nDutyFee = SUM(hra_classmst.duty_fee)
    FROM hra_classmst, hra_cadsign_view
         WHERE hra_classmst.class_code = hra_cadsign_view.class_code
           AND hra_cadsign_view.emp_no = @sEmpNo
           AND FORMAT(hra_cadsign_view.att_date, 'yyyy-MM-dd') = @sAttDate;

    END
  
    IF @nDutyFee IS NULL BEGIN
      SET @nDutyFee = 0;
    END
  
    IF @nDutyFee = 0 BEGIN
      RETURN(0);
    END
  
    IF @sDeptNo = '1323' AND @nDutyFee = 150 BEGIN
      IF @sStartTime >= '1900' BEGIN
        RETURN(0);
      END
      ELSE
      BEGIN
        RETURN(150);
      END
    END
  
    IF @nOtmHrs > 4 BEGIN
      RETURN(@nDutyFee);
    END
  
    IF @nDutyFee = 800 BEGIN
      RETURN(0);
    END
  
    RETURN(@nDutyFee * @nOtmHrs / 8);
END
GO
