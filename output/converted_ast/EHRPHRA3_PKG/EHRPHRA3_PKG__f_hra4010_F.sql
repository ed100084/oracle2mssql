CREATE OR ALTER FUNCTION [ehrphra3_pkg].[f_hra4010_F]
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
DECLARE @nOverTime DECIMAL(38,10);
DECLARE @iCnt INT;
DECLARE @nMonAddhrs DECIMAL(38,10);
DECLARE @iCnt_1 INT;
DECLARE @sDeptNo NVARCHAR(10);
-- EXCEPTION block removed: TRY/CATCH not allowed in T-SQL scalar function

    -- EXCEPTION block removed: TRY/CATCH not allowed in T-SQL scalar function

    --20180731 108978 修改積休時數不計排班時數不平，@nMonAddhrs 給0
      SELECT 

        @nOverTime = mon_otmhrs, @nMonAddhrs = 0, @sDeptNo = dept_no
    FROM hra_attvac_view
       WHERE (hra_attvac_view.sch_ym = @sTrnYm) AND
	         (hra_attvac_view.emp_no = @sEmpNo) AND
			  (hra_attvac_view.ORGAN_TYPE= @sOrganType ) ;


    IF @nOverTime IS NULL BEGIN
      SET @nOverTime = 0;
	  SET @nMonAddhrs = 0;
    END

    IF [ehrphra3_pkg].[f_hra4010_ins](@sTrnYm
                                , @sTrnShift
                                , @sEmpNo
                                , '2040'
                                , @nOverTime
                                , 'H'
								, @sOrganType
                                , @sUpdateBy ) <> 0 BEGIN
         SET @iCnt = 1;   --  積假時數INSERT失敗
    END


-- 99.09.28  SPHINX 班表超時時數
    -- EXCEPTION block removed: TRY/CATCH not allowed in T-SQL scalar function

    SELECT @iCnt_1 = COUNT(*)
    FROM HRA_OFFREC_CAL
       WHERE SCH_YM= @sTrnYm
	   AND EMP_NO = @sEmpNo
	   AND ORGAN_TYPE= @sOrganType ;


    IF @iCnt_1 = 0 BEGIN

      INSERT INTO HRA_OFFREC_CAL
        (SCH_YM,
         EMP_NO,
         MON_ADDHRS,
         MON_SPECAL,
         DISABLED,
         CREATED_BY,
         CREATION_DATE,
         LAST_UPDATED_BY,
         LAST_UPDATE_DATE,
		 DEPT_NO,
		 ORG_BY,
		 ORGAN_TYPE )
      VALUES
        (@sTrnYm,
         @sEmpNo,
         @nMonAddhrs,
         0,
         'N',
         @sUpdateBy,
         GETDATE(),
         @sUpdateBy,
         GETDATE(),
		 @sDeptNo,
		 @sOrganType,
		 @sOrganType );

    END
    ELSE
    BEGIN
      UPDATE HRA_OFFREC_CAL
         SET MON_ADDHRS= @nMonAddhrs,LAST_UPDATED_BY=@sUpdateBy,LAST_UPDATE_DATE=GETDATE()
       WHERE SCH_YM = @sTrnYm  AND EMP_NO = @sEmpNo AND ORGAN_TYPE= @sOrganType ;

    END
    RETURN @iCnt;

END
GO
