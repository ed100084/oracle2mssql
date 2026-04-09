CREATE OR ALTER FUNCTION [ehrphrafunc_pkg].[f_cutsuphrs]
(    @EmpNo_IN NVARCHAR(MAX),
    @ClassCode_IN NVARCHAR(MAX),
    @AttDate_IN DATETIME2(0)
)
RETURNS DECIMAL(38,10)
AS
BEGIN
DECLARE @sEmpNo NVARCHAR(20) = @EmpNo_IN;
DECLARE @sClassCode NVARCHAR(10) = @ClassCode_IN;
DECLARE @dAttDate DATETIME2(0) = @AttDate_IN;
DECLARE @iHoliHrs INT;
DECLARE @dStartDate DATETIME2(0);
DECLARE @dEndDate DATETIME2(0);
DECLARE @sVacType NVARCHAR(1);
DECLARE @sEvcNo NVARCHAR(20);
    -- 94.10.14 sphinx  edah 未有排班補休
    /*   BEGIN
        SELECT @iHoliHrs = SUM(HOLI_HRS)
    FROM HRA_HOLIDAY
         WHERE HOLI_DATE = @dAttDate AND HOLI_TYPE = 'E';
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          SET @iHoliHrs = 0;
      END
    
      IF @iHoliHrs IS NULL BEGIN
        SET @iHoliHrs = 0;
      END
    
      IF @iHoliHrs = 0 BEGIN
        RETURN(0);
      END
    
      IF @sClassCode LIKE '8%' OR @sClassCode IN ('1000', '9000') OR
         @sClassCode IS NULL BEGIN
        IF @sClassCode LIKE '8%' BEGIN
          BEGIN
            SELECT @sEvcNo = MAX(EVC_NO)
    FROM HRA_EVCREC
             WHERE EMP_NO = @sEmpNo AND @dAttDate BETWEEN START_DATE AND
                   END_DATE AND STATUS = 'Y';
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              RETURN(0);
          END
    
          BEGIN
            SELECT @dStartDate = START_DATE, @dEndDate = END_DATE, @sVacType = VAC_TYPE
    FROM HRA_EVCREC
             WHERE EVC_NO = @sEvcNo;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              RETURN(0);
          END
        END
    
        IF (@sVacType IN ('I', 'P', 'W', 'Z') AND @sClassCode LIKE '8%') OR
           @sClassCode IN ('1000', '9000') OR @sClassCode IS NULL BEGIN
          IF @sVacType IN ('P', 'W') AND @iHoliHrs <= 8 BEGIN
            RETURN(0);
          END
          ELSE
          BEGIN
            RETURN @iHoliHrs;
          END
        END
        ELSE
        BEGIN
          RETURN(0);
        END
      END
      ELSE
      BEGIN
        RETURN(0);
      END
    */
    --RETURN(@iHoliHrs);
    RETURN(0);
END
GO
