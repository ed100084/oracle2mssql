CREATE OR ALTER FUNCTION [ehrphra3_pkg].[f_hra4010_E]
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
DECLARE @iEarly INT;
DECLARE @iCnt INT;
-- EXCEPTION block removed: TRY/CATCH not allowed in T-SQL scalar function

       -- EXCEPTION block removed: TRY/CATCH not allowed in T-SQL scalar function

    SELECT @iEarly = COUNT(*)
    FROM hra_cardatt_view
           WHERE (hra_cardatt_view.emp_no = @sEmpNo)
             AND (hra_cardatt_view.att_date BETWEEN @dStrartDate AND @dEndDate)
             AND (hra_cardatt_view.chkout = '3')
			 AND (hra_cardatt_view.organ_type=@sOrganType );


       IF @iEarly > 0 BEGIN
          IF [ehrphra3_pkg].[f_hra4010_ins](@sTrnYm
                                      , @sTrnShift
                                      , @sEmpNo
                                      , '2021'
                                      , @iEarly
                                      , 'T'
									  , @sOrganType
									  , @sUpdateBy ) <> 0 BEGIN
             SET @iCnt = 1;   --  早退次數INSERT失敗
          END
       END
       --------------------------------For義大--------------------------------
       RETURN @iCnt ;

END
GO
