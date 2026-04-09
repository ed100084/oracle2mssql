CREATE OR ALTER FUNCTION [ehrphra3_pkg].[f_hra4010_B]
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
DECLARE @iChkIn1Cnt INT = 0;
DECLARE @iChkOut1Cnt INT = 0;
DECLARE @iChkIn2Cnt INT = 0;
DECLARE @iChkOut2Cnt INT = 0;
DECLARE @iChkIn3Cnt INT = 0;
DECLARE @iChkOut3Cnt INT = 0;
DECLARE @nTotalUnCard INT = 0;
DECLARE @iChkCardCnt INT = 0;
DECLARE @iCnt INT = 0;
-- EXCEPTION block removed: TRY/CATCH not allowed in T-SQL scalar function

    ------------------------- new 寫法  -------------------------
	-- 忘打卡未處理
     SELECT @nTotalUnCard = SUM(uncard)
    FROM (SELECT SUM(CASE WHEN chkin1 = '1' THEN 1 ELSE 0 END + CASE WHEN chkout1 = '1' THEN 1 ELSE 0 END + CASE WHEN chkin2 = '1' THEN 1 ELSE 0 END
                 +     CASE WHEN chkout2 = '1' THEN 1 ELSE 0 END + CASE WHEN chkin3 = '1' THEN 1 ELSE 0 END + CASE WHEN chkout3 = '1' THEN 1 ELSE 0 END
          			 +     0) uncard
              FROM HRA_CARDABNORMAL_VIEW
             WHERE EMP_NO =@sEmpNo
			   AND ORGAN_TYPE= @sOrganType
			   AND (ATT_DATE BETWEEN @dStrartDate AND @dEndDate)
			   AND (chkin1 = '1' OR chkin2 = '1' OR chkin3 = '1' OR chkout1 = '1' OR chkout2 = '1' OR chkout3 = '1')
			   ) AS _dt1 ;


   IF @nTotalUnCard>0 BEGIN

    IF [ehrphra3_pkg].[f_hra4010_ins](@sTrnYm
                                , @sTrnShift
                                , @sEmpNo
                                , '2010'
								, @nTotalUnCard
                                , 'T'
   								, @sOrganType
								, @sUpdateBy ) <> 0 BEGIN
       SET @iCnt = 1;   --  未打卡次數INSERT失敗
    END
   END

   --- 忘打卡單
   SET @nTotalUnCard = 0;

   SELECT @nTotalUnCard = SUM(uncard)
    FROM (SELECT COUNT(*) uncard
            FROM HRA_UNCARD
            WHERE emp_no =@sEmpNo
			AND otm_rea LIKE '1%'
			AND (CLASS_DATE BETWEEN @dStrartDate AND @dEndDate)
            AND status = 'Y'
			AND ORG_BY= @sOrganType  ) AS _dt2 ;

    IF @nTotalUnCard = 0 BEGIN
      GOTO Continue_ForEach1;
    END

	  IF [ehrphra3_pkg].[f_hra4010_ins](@sTrnYm
                                , @sTrnShift
                                , @sEmpNo
                                , '2050'
                                , @nTotalUnCard
                                , 'T'
								, @sOrganType
                                , @sUpdateBy ) <> 0 BEGIN
         SET @iCnt = 1;   --  未打卡次數INSERT失敗
      END
    Continue_ForEach1:
    RETURN @iCnt;
    ------------------------- new 寫法  -------------------------
RETURN NULL; -- T-SQL: ensure all paths return
END
GO
