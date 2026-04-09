CREATE OR ALTER PROCEDURE [ehrphra12_pkg].[offrec_uni_backup]
(    @p_emp_no NVARCHAR(MAX),
    @p_start_date NVARCHAR(MAX),
    @p_start_time NVARCHAR(MAX),
    @p_status NVARCHAR(MAX),
    @p_item_type NVARCHAR(MAX),
    @RtnCode DECIMAL(38,10) OUTPUT
)
AS
DECLARE @iCnt SMALLINT;
BEGIN
  SET @RtnCode = 0;
  SELECT @iCnt = COUNT(EMP_NO)
    FROM HRA_OFFREC
    WHERE EMP_NO = @p_emp_no AND
          start_date = CONVERT(DATETIME2, @p_start_date) AND
          start_time = @p_start_time AND
          status = @p_status AND
          item_type = @p_item_type;
  if (@iCnt <> 0) BEGIN
    INSERT INTO HRA_OFFREC_UNI
    (EMP_NO, SEQ, DEPT_NO, START_DATE,
   START_TIME, END_DATE, END_TIME,
   OTM_HRS, ORG_FEE, REG_FEE,
   OTM_REA, REMARK, STATUS,
   PERMIT_ID, PERMIT_DATE, CREATED_BY,
   CREATION_DATE, LAST_UPDATED_BY, LAST_UPDATE_DATE,
   ITEM_TYPE, TRN_YM, ONCALL,
   TRAFFIC_FEE, CHECK_FLAG, CHECK_POIN,
   START_DATE_TMP, CREATION_COMP, LAST_UPDATED_COMP,
   DISABLED, DEPUTY, HARM_MEAL_EXPENSE,
   FOLLOW_DEPT_NO, CHIEF_TRANS, ABROAD)
   (SELECT EMP_NO,
   ISNULL((SELECT MAX(SEQ)+1 FROM HRA_OFFREC_UNI WHERE EMP_NO = @p_emp_no AND
          start_date = CONVERT(DATETIME2, @p_start_date) AND
          start_time = @p_start_time AND status = @p_status AND item_type = @p_item_type),1),
    DEPT_NO, START_DATE,
   START_TIME, END_DATE, END_TIME,
   OTM_HRS, ORG_FEE, REG_FEE,
   OTM_REA, REMARK, STATUS,
   PERMIT_ID, PERMIT_DATE, CREATED_BY,
   CREATION_DATE, LAST_UPDATED_BY, LAST_UPDATE_DATE,
   ITEM_TYPE, TRN_YM, ONCALL,
   TRAFFIC_FEE, CHECK_FLAG, CHECK_POIN,
   START_DATE_TMP, CREATION_COMP, LAST_UPDATED_COMP,
   DISABLED, DEPUTY, HARM_MEAL_EXPENSE,
   FOLLOW_DEPT_NO, CHIEF_TRANS, ABROAD FROM HRA_OFFREC
   WHERE EMP_NO = @p_emp_no AND
          start_date = CONVERT(DATETIME2, @p_start_date) AND
          start_time = @p_start_time AND status = @p_status AND item_type = @p_item_type);

  DELETE FROM HRA_OFFREC WHERE EMP_NO = @p_emp_no AND
          start_date = CONVERT(DATETIME2, @p_start_date) AND
          start_time = @p_start_time AND status = @p_status AND item_type = @p_item_type;

  COMMIT TRAN;
  END
END
GO
