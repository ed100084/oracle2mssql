CREATE OR ALTER FUNCTION [ehrphrafunc_pkg].[f_FreesignData]
(    @EmpNo_IN NVARCHAR(MAX),
    @Date_IN DATETIME2(0),
    @Type_IN NVARCHAR(MAX)
)
RETURNS NVARCHAR(MAX)
AS
BEGIN
DECLARE @min_signdate DATETIME2(0);
DECLARE @max_signdate DATETIME2(0);
DECLARE @output NVARCHAR(60);
DECLARE @inrea NVARCHAR(4);
DECLARE @inreano NVARCHAR(4);
DECLARE @inreadesc NVARCHAR(60);
DECLARE @outrea NVARCHAR(4);
DECLARE @outreano NVARCHAR(4);
DECLARE @outreadesc NVARCHAR(60);
    SELECT @min_signdate = MIN(SIGN_DATE)
    FROM HRA_FREESIGN
     WHERE EMP_NO = @EmpNo_IN
       AND CAST(SIGN_DATE AS DATE) = @Date_IN
       AND SIGNIN = 'IN'
       AND SERVER_IP <> 'mis';
    
    SELECT @max_signdate = MAX(SIGN_DATE)
    FROM HRA_FREESIGN
     WHERE EMP_NO = @EmpNo_IN
       AND CAST(SIGN_DATE AS DATE) = @Date_IN
       AND SIGNIN = 'OUT'
       AND SERVER_IP <> 'mis';
    
    IF @min_signdate IS NOT NULL BEGIN
      SELECT @inrea = SUBSTRING(REANO,1,2), @inreano = SUBSTRING(REANO,3,2), @inreadesc = (SELECT CODE_NAME FROM HR_CODEBAS WHERE CODE_TYPE = 'HRA34' AND CODE_NO + CODE_DTL = REANO)
    FROM HRA_FREESIGN
       WHERE EMP_NO = @EmpNo_IN
         AND SIGN_DATE = @min_signdate
         AND SIGNIN = 'IN'
         AND SERVER_IP <> 'mis';
    END
       
    IF @max_signdate IS NOT NULL BEGIN
      SELECT @outrea = SUBSTRING(REANO,1,2), @outreano = SUBSTRING(REANO,3,2), @outreadesc = (SELECT CODE_NAME FROM HR_CODEBAS WHERE CODE_TYPE = 'HRA34' AND CODE_NO + CODE_DTL = REANO)
    FROM HRA_FREESIGN
       WHERE EMP_NO = @EmpNo_IN
         AND SIGN_DATE = @max_signdate
         AND SIGNIN = 'OUT'
         AND SERVER_IP <> 'mis';
    END
    
    IF @Type_IN = 'in' BEGIN
      IF @min_signdate IS NOT NULL BEGIN
        SET @output = FORMAT(@min_signdate, 'hhmm');
      END
      ELSE
      BEGIN
        SET @output = NULL;
      END
    END
ELSE IF @Type_IN = 'out' BEGIN
      IF @max_signdate IS NOT NULL BEGIN
        SET @output = FORMAT(@max_signdate, 'hhmm');
      END
      ELSE
      BEGIN
        SET @output = NULL;
      END
    END
ELSE IF @Type_IN = '@inrea' BEGIN
      SET @output = @inrea;
    END
ELSE IF @Type_IN = '@outrea' BEGIN
      SET @output = @outrea;
    END
ELSE IF @Type_IN = '@inreano' BEGIN
      SET @output = @inreano;
    END
ELSE IF @Type_IN = '@outreano' BEGIN
      SET @output = @outreano;
    END
ELSE IF @Type_IN = '@inreadesc' BEGIN
      SET @output = @inreadesc;
    END
ELSE IF @Type_IN = '@outreadesc' BEGIN
      SET @output = @outreadesc;
    END
    
    RETURN @output;
END
GO
