CREATE OR ALTER FUNCTION [ehrphra3_pkg].[f_hra4010_H]
(    @TrnYm_IN NVARCHAR(MAX),
    @TrnShift_IN NVARCHAR(MAX),
    @EmpNo_IN NVARCHAR(MAX),
    @Orgtype_IN NVARCHAR(MAX),
    @UpdateBy_IN NVARCHAR(MAX)
)
RETURNS DECIMAL(38,10)
AS
BEGIN
DECLARE @sTrnYm NVARCHAR(7) = @TRNYM_IN;
DECLARE @sTrnShift NVARCHAR(2) = @TRNSHIFT_IN;
DECLARE @sEmpNo NVARCHAR(20) = @EMPNO_IN;
DECLARE @sOrganType NVARCHAR(10) = @ORGTYPE_IN;
DECLARE @sUpdateBy NVARCHAR(20) = @UPDATEBY_IN;
DECLARE @nOffTime DECIMAL(38,10);
DECLARE @nTrafficfee DECIMAL(38,10);
DECLARE @RtnCode DECIMAL(38,10);
-- EXCEPTION block removed: TRY/CATCH not allowed in T-SQL scalar function

       -- EXCEPTION block removed: TRY/CATCH not allowed in T-SQL scalar function

    SELECT @nOffTime = SUM(A. otm_hrs), @nTrafficfee = SUM(traffic_fee)
    FROM (
          SELECT ISNULL(SUM(CASE WHEN item_type = 'A' THEN otm_hrs ELSE otm_hrs * -1 END), 0) otm_hrs
               , ISNULL(SUM((SELECT ISNULL(code_value, 0) FROM HR_CODEDTL
                          WHERE code_type = 'HRA40'
                            AND code_no = traffic_fee)), 0) traffic_fee
            FROM HRA_OFFREC
           WHERE EMP_NO = @sEmpNo
             AND trn_ym = @sTrnYm
		   --AND FORMAT(START_DATE, 'yyyy-MM-dd') BETWEEN '2025-03-01' AND '2025-03-30' -- 提前結算
             AND STATUS = 'Y'
			 AND ORG_BY = @sOrganType 
       UNION ALL
        SELECT ISNULL(SUM( otm_hrs), 0) otm_hrs
               , ISNULL(SUM((SELECT ISNULL(code_value, 0) FROM HR_CODEDTL
                          WHERE code_type = 'HRA40'
                            AND code_no = traffic_fee)), 0) traffic_fee
            FROM HRA_OTMSIGN
           WHERE EMP_NO = @sEmpNo
             AND trn_ym1 = @sTrnYm
             AND OTM_NO LIKE ('OTM%')
       --AND FORMAT(START_DATE, 'yyyy-MM-dd') BETWEEN '2025-03-01' AND '2025-03-30' -- 提前結算
             AND STATUS = 'Y'
       AND ORG_BY = @sOrganType 
       ) A ;


       --------------------------ONCALL交通費--------------------------
       IF @nTrafficfee = 0 BEGIN
          GOTO Continue_ForEach2 ;
       END

       IF [ehrphra3_pkg].[f_hra4010_ins](@sTrnYm
                                   , @sTrnShift
                                   , @sEmpNo
                                   , '3051'
                                   , @nTrafficfee
                                   , 'N'
								   , @sOrganType
                                   , @sUpdateBy ) <> 0 BEGIN
          SET @RtnCode = 2;   -- 交通費INSERT失敗
          GOTO Continue_ForEach2 ;
       END
       Continue_ForEach2:
       --------------------------交通費--------------------------
    RETURN @RtnCode;

END
GO
