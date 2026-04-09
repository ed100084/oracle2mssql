CREATE OR ALTER FUNCTION [ehrphra3_pkg].[f_hra4010_D]
(    @TrnYm_IN NVARCHAR(MAX),
    @TrnShift_IN NVARCHAR(MAX),
    @EmpNo_IN NVARCHAR(MAX),
    @StrartDate_IN DATETIME2(0),
    @EndDate_IN DATETIME2(0),
    @Orgtype_IN NVARCHAR(MAX),
    @UpdateBy_IN NVARCHAR(MAX)
)
RETURNS DECIMAL(38,10)
AS
BEGIN
DECLARE @sTrnYm NVARCHAR(7) = @TRNYM_IN;
DECLARE @sTrnShift NVARCHAR(2) = @TRNSHIFT_IN;
DECLARE @sEmpNo NVARCHAR(20) = @EMPNO_IN;
DECLARE @dStrartDate DATETIME2(0) = @STRARTDATE_IN;
DECLARE @dEndDate DATETIME2(0) = @ENDDATE_IN;
DECLARE @sOrganType NVARCHAR(10) = @ORGTYPE_IN;
DECLARE @sUpdateBy NVARCHAR(20) = @UPDATEBY_IN;
DECLARE @iLate INT;
DECLARE @iCnt INT;
DECLARE @iLate_DAILYTRAN INT = 0;
-- EXCEPTION block removed: TRY/CATCH not allowed in T-SQL scalar function

       -- EXCEPTION block removed: TRY/CATCH not allowed in T-SQL scalar function

    SELECT @iLate = COUNT(*)
    FROM hra_cardatt_view
           WHERE (hra_cardatt_view.emp_no = @sEmpNo)
             AND (hra_cardatt_view.att_date BETWEEN @dStrartDate AND @dEndDate)
             AND (hra_cardatt_view.chkin = '2');

       
--20180914 108978 加入請假時數不足列入遲到的人       
       -- EXCEPTION block removed: TRY/CATCH not allowed in T-SQL scalar function

    SELECT @iLate_DAILYTRAN = COUNT(*)
    FROM HRA_DAILYTRAN
           WHERE HRA_DAILYTRAN.EMP_NO = @sEmpNo
             AND HRA_DAILYTRAN.LATE_FLAG = 'Y'
             AND (HRA_DAILYTRAN.VAC_DATE BETWEEN @dStrartDate AND @dEndDate);
 
             
       SET @iLate = @iLate+@iLate_DAILYTRAN;
       
       IF @iLate > 0 BEGIN
          IF [ehrphra3_pkg].[f_hra4010_ins](@sTrnYm
                                      , @sTrnShift
                                      , @sEmpNo
									                    , '2060'
                                      , @iLate
                                      , 'T'
									                    , @sOrganType
                                      , @sUpdateBy ) <> 0 BEGIN
             SET @iCnt = 1;   --  遲到次數INSERT失敗
          END
       END
       --------------------------------For義大--------------------------------
       RETURN @iCnt;

END
GO
