CREATE OR ALTER FUNCTION [ehrphra12_pkg].[checkOncall]
(    @p_emp_no NVARCHAR(MAX),
    @p_start_date NVARCHAR(MAX),
    @p_start_time NVARCHAR(MAX),
    @p_end_date NVARCHAR(MAX),
    @p_start_date_tmp NVARCHAR(MAX),
    @OrganType_IN NVARCHAR(MAX)
)
RETURNS DECIMAL(38,10)
AS
BEGIN
DECLARE @sClassKind NVARCHAR(3);
DECLARE @iCnt2 INT;
DECLARE @RtnCode SMALLINT;
DECLARE @SOrganType NVARCHAR(10) = @OrganType_IN;
      SET @RtnCode = 0;

         -- EXCEPTION block removed: TRY/CATCH not allowed in T-SQL scalar function

    SELECT @iCnt2 = count(*)
    FROM GESD_DORMMST
               WHERE emp_no = @p_emp_no
                 AND USE_FLAG = 'Y';


           IF @iCnt2 > 0 BEGIN
              SET @RtnCode = 4;     -- 住宿不可申請OnCall
              GOTO Continue_ForEach1 ;
           END

           -- IF @p_start_date_tmp <> 'N/A' AND @p_start_date_tmp <> @p_start_date 代表 為跨夜申請
           -- 故 ClassKin 要以 @p_start_date_tmp 為基準

           IF @p_start_date_tmp <> 'N/A' AND @p_start_date_tmp <> @p_start_date BEGIN
           SET @sClassKind = [ehrphrafunc_pkg].[f_getClassKind](@p_emp_no,CONVERT(DATETIME2, @p_start_date_tmp),@SOrganType);
           END
           ELSE
           BEGIN
           SET @sClassKind = [ehrphrafunc_pkg].[f_getClassKind](@p_emp_no,CONVERT(DATETIME2, @p_start_date),@SOrganType);
           END
           -- EXCEPTION block removed: TRY/CATCH not allowed in T-SQL scalar function

    SELECT @iCnt2 = (CASE WHEN CHKIN_WKTM < CHKOUT_WKTM THEN ( CASE WHEN @p_start_time between CHKIN_WKTM AND CHKOUT_WKTM  THEN 1 ELSE 0 END )

	                      ELSE ( CASE WHEN  (@p_start_time between CHKIN_WKTM AND '2400') OR (@p_start_time between '0000' AND CHKOUT_WKTM )  THEN 1 ELSE 0 END )END
                   )
    FROM HRP.HRA_CLASSDTL
           WHERE SHIFT_NO='4'
             AND CLASS_CODE= @sClassKind;

           
           IF @iCnt2 = 0 BEGIN
            -- EXCEPTION block removed: TRY/CATCH not allowed in T-SQL scalar function

    SELECT @iCnt2 = COUNT(*)
    FROM hr_codedtl
                WHERE code_type = 'HRA79'
                  AND code_no = (SELECT dept_no
                                   FROM hre_empbas
                                  WHERE emp_no = @p_emp_no)
                  AND disabled='N';

           END

             IF @iCnt2 = 0 BEGIN
                SET @RtnCode = 5;     -- 申請OnCall之積休日班別須為on call班
                GOTO Continue_ForEach1 ;
             END

            ---如果有上班打卡就驗證
            -- IF @p_start_date_tmp <> 'N/A' AND @p_start_date_tmp <> @p_start_date 代表 為跨夜申請
            -- 以 @p_end_date 為基準
            -- EXCEPTION block removed: TRY/CATCH not allowed in T-SQL scalar function

    IF @p_start_date_tmp <> 'N/A' AND @p_start_date_tmp <> @p_start_date BEGIN

            SELECT @iCnt2 = COUNT(*)
    FROM  HRA_CADSIGN
            Where HRA_CADSIGN.EMP_NO = @p_emp_no
              AND FORMAT(HRA_CADSIGN.ATT_DATE, 'yyyy-MM-dd') = @p_start_date_tmp;

            END
            ELSE
            BEGIN
            SELECT @iCnt2 = COUNT(*)
    FROM  HRA_CADSIGN
            Where HRA_CADSIGN.EMP_NO = @p_emp_no
              AND FORMAT(HRA_CADSIGN.ATT_DATE, 'yyyy-MM-dd') = @p_start_date;

            END


            IF @iCnt2 >0 BEGIN

            -- EXCEPTION block removed: TRY/CATCH not allowed in T-SQL scalar function

    -- IF @p_start_date_tmp <> 'N/A' AND @p_start_date_tmp <> @p_start_date 代表 為跨夜申請
            -- 故 ATT_DATE 要加 1 , 並以 @p_end_date 為基準

            IF @p_start_date_tmp <> 'N/A' AND @p_start_date_tmp <> @p_start_date BEGIN

            SELECT @iCnt2 = (case when (  CONVERT(DATETIME2, FORMAT(MAX(HRA_OTMSIGN.START_DATE), 'yyyy-MM-dd')+MAX(HRA_OTMSIGN.START_TIME)) - CONVERT(DATETIME2, FORMAT(MAX(HRA_CADSIGN.ATT_DATE), 'yyyy-MM-dd')+MAX(HRA_CADSIGN.CHKOUT_CARD)))*60*24 > 30 then 0 else 1 end )
    FROM HRA_OTMSIGN , HRA_CADSIGN
            Where HRA_CADSIGN.EMP_NO = HRA_OTMSIGN.EMP_NO
              AND FORMAT(ATT_DATE+1, 'yyyy-MM-dd') = FORMAT(START_DATE, 'yyyy-MM-dd')
              AND HRA_OTMSIGN.EMP_NO = @p_emp_no
              AND FORMAT(HRA_OTMSIGN.START_DATE, 'yyyy-MM-dd') = @p_end_date;

            END
            ELSE
            BEGIN

            SELECT @iCnt2 = (case when (  ISNULL(CONVERT(DATETIME2, FORMAT(MAX(HRA_OTMSIGN.START_DATE), 'yyyy-MM-dd')+MAX(HRA_OTMSIGN.START_TIME)) - CONVERT(DATETIME2, FORMAT(MAX(HRA_CADSIGN.ATT_DATE), 'yyyy-MM-dd')+MAX(HRA_CADSIGN.CHKOUT_CARD)),0))*60*24 > 30 then 0 else 1 end )
    FROM HRA_OTMSIGN , HRA_CADSIGN
            Where HRA_CADSIGN.EMP_NO = HRA_OTMSIGN.EMP_NO
              AND FORMAT(ATT_DATE, 'yyyy-MM-dd') = FORMAT(START_DATE, 'yyyy-MM-dd')
              AND HRA_OTMSIGN.EMP_NO = @p_emp_no
              AND FORMAT(HRA_OTMSIGN.START_DATE, 'yyyy-MM-dd') = @p_start_date;

            END


            IF @iCnt2 = 0 BEGIN
                SET @RtnCode = 0;
                GOTO Continue_ForEach1 ;
            END
            ELSE
            BEGIN
                 SET @RtnCode = 6;     -- 申請OnCall失敗
                GOTO Continue_ForEach1 ;
            END

            END


      IF @RtnCode <> 0 BEGIN
         GOTO Continue_ForEach1 ;
      END


      ------------------------- 補休單 -------------------------
       Continue_ForEach1:
    return @RtnCode;
END
GO
