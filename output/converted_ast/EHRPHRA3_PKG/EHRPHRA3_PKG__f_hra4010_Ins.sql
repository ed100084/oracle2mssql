CREATE OR ALTER FUNCTION [ehrphra3_pkg].[f_hra4010_Ins]
(    @TrnYm_IN NVARCHAR(MAX),
    @TrnShift_IN NVARCHAR(MAX),
    @EmpNo_IN NVARCHAR(MAX),
    @AttCode_IN NVARCHAR(MAX),
    @AttValue_IN DECIMAL(38,10),
    @AttUnit_IN NVARCHAR(MAX),
    @Orgtype_IN NVARCHAR(MAX),
    @UpdateBy_IN NVARCHAR(MAX)
)
RETURNS DECIMAL(38,10)
AS
BEGIN
DECLARE @sTrnYm NVARCHAR(7) = @TRNYM_IN;
DECLARE @sTrnShift NVARCHAR(2) = @TRNSHIFT_IN;
DECLARE @sEmpNo NVARCHAR(20) = @EMPNO_IN;
DECLARE @sAttCode NVARCHAR(4) = @ATTCODE_IN;
DECLARE @sAttValue DECIMAL(38,10) = @ATTVALUE_IN;
DECLARE @sAttUnit NVARCHAR(1) = @ATTUNIT_IN;
DECLARE @sOrganType NVARCHAR(10) = @ORGTYPE_IN;
DECLARE @sUpdateBy NVARCHAR(20) = @UPDATEBY_IN;
DECLARE @iCnt INT;
-- EXCEPTION block removed: TRY/CATCH not allowed in T-SQL scalar function

       -- EXCEPTION block removed: TRY/CATCH not allowed in T-SQL scalar function

    SELECT @iCnt = COUNT(*)
    FROM HRA_ATTDTL
           WHERE TRN_YM = @sTrnYm
		   AND TRN_SHIFT = @sTrnShift
		   AND EMP_NO = @sEmpNo
           AND ATT_CODE = @sAttCode
		   AND ORGAN_TYPE = @sOrganType ;


       IF @iCnt = 0 BEGIN
          INSERT INTO HRA_ATTDTL(TRN_YM
                               , TRN_SHIFT
                               , EMP_NO
                               , ATT_CODE
                               , ATT_VALUE
                               , ATT_UNIT
                               , CREATED_BY
                               , CREATION_DATE
                               , LAST_UPDATED_BY
                               , LAST_UPDATE_DATE
							   , ORG_BY
							   , ORGAN_TYPE )
                          VALUES(@sTrnYm
                               , @sTrnShift
                               , @sEmpNo
                               , @sAttCode
                               , @sAttValue
                               , @sAttUnit
                               , @sUpdateBy
                               , GETDATE()
                               , @sUpdateBy
                               , GETDATE()
							   , @sOrganType
							   , @sOrganType );

       END
       ELSE
       BEGIN
          UPDATE HRA_ATTDTL
             SET ATT_VALUE = ATT_VALUE + @sAttValue
           WHERE TRN_YM = @sTrnYm AND TRN_SHIFT = @sTrnShift AND EMP_NO = @sEmpNo
             AND ATT_CODE = @sAttCode AND ORGAN_TYPE= @sOrganType ;
       END
       RETURN 0;

END
GO
