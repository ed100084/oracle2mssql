CREATE OR ALTER FUNCTION [ehrphra3_pkg].[f_hra4010_J]
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
DECLARE @RtnCode DECIMAL(38,10);
DECLARE @nFee DECIMAL(38,10);
DECLARE @nFeeCount DECIMAL(38,10);
DECLARE @cur_getotmsign NVARCHAR(MAX) /*cur_otmsign%ROWTYPE*/;
DECLARE cur_otmsign CURSOR FOR
    SELECT A.EMP_NO, SUM(A.OTM_FEE) AS OTM_FEE, SUM(A.ONCALL_FEE) AS ONCALL_FEE
      FROM (SELECT EMP_NO,
                   FORMAT(START_DATE, 'yyyy-mm'),
                   CEILING(ISNULL(SUM(OTM_FEE), 0)) OTM_FEE,
                   CEILING(ISNULL(SUM(ONCALL_FEE), 0)) ONCALL_FEE
              FROM HRA_OTMSIGN
             WHERE HRA_OTMSIGN.STATUS = 'Y'
               AND OTM_NO LIKE 'OTM%'
               AND HRA_OTMSIGN.EMP_NO = @sEmpNo
               AND HRA_OTMSIGN.TRN_YM = @sTrnYm
               AND HRA_OTMSIGN.ORG_BY = @sOrganType
             GROUP BY EMP_NO, FORMAT(START_DATE, 'yyyy-mm')) A
    GROUP BY A.EMP_NO;
-- EXCEPTION block removed: TRY/CATCH not allowed in T-SQL scalar function

       OPEN cur_otmsign ;
       WHILE 1=1 BEGIN
          FETCH NEXT FROM cur_otmsign INTO @cur_getotmsign;
          IF @@FETCH_STATUS <> 0 BREAK;

          --------------------------加班時數--------------------------
          SET @RtnCode = 0;


          IF @cur_getotmsign>0 BEGIN
             IF [ehrphra3_pkg].[f_hra4010_ins](@sTrnYm
                                     , @sTrnShift
                                     , @sEmpNo
                                     , '3041'
                                     , @cur_getotmsign
                                     , 'N'
									                   , @sOrganType
                                     , @sUpdateBy ) <> 0 BEGIN

                SET @RtnCode = 1;   -- 加班時數INSERT失敗
                GOTO Continue_ForEach2 ;
             END
          END

          -- 免稅
          IF @cur_getotmsign = 0  BEGIN
             GOTO Continue_ForEach1 ;
          END

          IF [ehrphra3_pkg].[f_hra4010_ins](@sTrnYm
                                     , @sTrnShift
                                     , @sEmpNo
                                     , '3031'
                                     , @cur_getotmsign
                                     , 'N'
									                   , @sOrganType
                                     , @sUpdateBy ) <> 0 BEGIN
             SET @RtnCode = 1;   -- 加班時數INSERT失敗
             GOTO Continue_ForEach2 ;
          END

          Continue_ForEach1:
          --------------------------加班時數--------------------------

          --------------------------交通費--------------------------
           Continue_ForEach2:
          --------------------------交通費--------------------------

       END
       CLOSE cur_otmsign;
    DEALLOCATE cur_otmsign
       RETURN @RtnCode;
RETURN NULL; -- T-SQL: ensure all paths return
END
GO
