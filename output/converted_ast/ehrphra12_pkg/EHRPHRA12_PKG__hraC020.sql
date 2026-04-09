CREATE OR ALTER PROCEDURE [ehrphra12_pkg].[hraC020]
(    @p_sup_no NVARCHAR(MAX),
    @p_otm_date NVARCHAR(MAX),
    @p_sup_hrs NVARCHAR(MAX),
    @RtnCode DECIMAL(38,10) OUTPUT
)
AS
DECLARE @sEmp_no NVARCHAR(MAX) /*hra_supmst.emp_no%TYPE*/;
DECLARE @sStart_date NVARCHAR(MAX) /*hra_supmst.start_date%TYPE*/;
DECLARE @nSupHrs DECIMAL(38,10);
DECLARE @nOtm_hrs NVARCHAR(MAX) /*hra_otmsign.otm_hrs%TYPE*/;
DECLARE @nCnt_hrs DECIMAL(38,10);
BEGIN
       SET @RtnCode = 0;

       ------------------------計算請補休時數------------------------
       BEGIN TRY
    SELECT @sEmp_no = emp_no, @sStart_date = start_date, @nSupHrs = sup_hrs
    FROM hra_supmst
           WHERE sup_no = @p_sup_no ;
--             AND status = 'U' ;
END TRY
BEGIN CATCH
    -- WHEN OTHERS
    SET @sEmp_no = NULL;
            SET @sStart_date = null;
            SET @nSupHrs = 0;
--            SET @sStart_time = null;
--            SET @sEnd_date = null;
--            SET @sEnd_time = null;
--            SET @RtnCode = 7;    -- 無請補休
--            GOTO Continue_ForEach1 ;
END CATCH

       IF @sStart_date < @p_otm_date or @sStart_date is null BEGIN
          SET @RtnCode = 7;   -- 補休日期 < 加班日期
          GOTO Continue_ForEach1 ;
       END

       IF @nSupHrs = 0 BEGIN
          SET @RtnCode = 8;   -- 無補休時數
          GOTO Continue_ForEach1 ;
       END


  --     IF NOT (sEnd_date IS NULL OR sEnd_time IS NULL) THEN

   --       SET @nSupHrs = ehrphra2_pkg.f_hra3010c(@sStart_date
   --                                     , sStart_time
    --                                    , sEnd_date
   --                                     , sEnd_time);
   --    END IF;


   --    IF (@nSupHrs % 60) = 0 OR (@nSupHrs % 60) = 30 THEN
   --       SET @nSupHrs = @nSupHrs / 60;
   --    ELSIF (@nSupHrs % 60) > 30 THEN
    --      SET @nSupHrs = DATEADD(DAY, 1, CAST(@nSupHrs / 60 AS DATE));
   --    ELSIF (@nSupHrs % 60) < 30 THEN
   --       SET @nSupHrs = CAST(@nSupHrs / 60 AS DATE) + 0.5;
   --    END IF ;

       ------------------------計算請補休時數------------------------

       -------------------補休時數及補休日是否到期-------------------
       BEGIN TRY
    SELECT @nOtm_hrs = ISNULL(SUM(otm_hrs), 0)
    FROM hra_otmsign
           WHERE status = 'Y'
             AND oncall = 'N'
             AND trn_ym IS NULL
             AND emp_no = @sEmp_no
             AND FORMAT(start_date, 'yyyy-mm-dd') = @p_otm_date ;
END TRY
BEGIN CATCH
    -- WHEN OTHERS
    SET @nOtm_hrs = 0;
END CATCH

       IF @nOtm_hrs = 0 BEGIN
          SET @RtnCode = 2;   -- 該日無超時時數可請補休
          GOTO Continue_ForEach1 ;
       END

       IF (FORMAT(DATEADD(MONTH, 1, @sStart_date), 'yyyy-mm-dd') < @p_otm_date) BEGIN
           SET @RtnCode = 3;   -- 已逾期，不可補休
           GOTO Continue_ForEach1 ;
       END

       BEGIN TRY
    SELECT @nCnt_hrs = ISNULL(sum(sup_hrs), 0)
    FROM hra_supdtl
           WHERE sup_no in (select sup_no from hra_supmst where emp_no = @sEmp_no
                               AND status = 'Y')
             AND FORMAT(otm_date, 'yyyy-mm-dd') = @p_otm_date ;
--             and status in ('Y', 'U')
END TRY
BEGIN CATCH
    -- WHEN OTHERS
    SET @nCnt_hrs = 0;
END CATCH

       IF @nOtm_hrs - (@nCnt_hrs + @p_sup_hrs) < 0 BEGIN
           SET @RtnCode = 4;   -- 該日超時時數不足此請補休時數
          GOTO Continue_ForEach1 ;
       END

       BEGIN TRY
    SELECT @nCnt_hrs = ISNULL(sum(sup_hrs), 0)
    FROM hra_supdtl
           WHERE sup_no = @p_sup_no ;
--             AND status = 'U' ;
END TRY
BEGIN CATCH
    -- WHEN OTHERS
    SET @nCnt_hrs = 0;
END CATCH

      -- IF (@nCnt_hrs + @p_sup_hrs) < @nSupHrs THEN --<==ERROR !!若是兩筆以上的補休會有問題!
     --     SET @RtnCode = 5;   -- 超時時數dtl < 請補休時數mst (警告訊息)  此張申請單
     --  ELSIF (@nCnt_hrs + @p_sup_hrs) > @nSupHrs  THEN
       IF (@nCnt_hrs + @p_sup_hrs) > @nSupHrs  BEGIN
          SET @RtnCode = 6;   -- 超時時數dtl > 請補休時數mst (警告訊息)  此張申請單
       END

       ------------------補休時數及補休日是否到期-------------------
       Continue_ForEach1:
END
GO
