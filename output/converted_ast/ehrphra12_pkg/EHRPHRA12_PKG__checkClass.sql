CREATE OR ALTER FUNCTION [ehrphra12_pkg].[checkClass]
(    @p_emp_no NVARCHAR(MAX),
    @p_start_date NVARCHAR(MAX),
    @p_start_time NVARCHAR(MAX),
    @p_end_date NVARCHAR(MAX),
    @p_end_time NVARCHAR(MAX),
    @OrganType_IN NVARCHAR(MAX)
)
RETURNS DECIMAL(38,10)
AS
BEGIN
DECLARE @sClassKind NVARCHAR(3);
DECLARE @iCnt INT;
DECLARE @RtnCode SMALLINT;
DECLARE @SOrganType NVARCHAR(10) = @OrganType_IN;
DECLARE @iSrest_1 NVARCHAR(4);
DECLARE @iSrest_2 NVARCHAR(4);
DECLARE @iSrest_3 NVARCHAR(4);
DECLARE @iErest_1 NVARCHAR(4);
DECLARE @iErest_2 NVARCHAR(4);
DECLARE @iErest_3 NVARCHAR(4);
       SET @sClassKind = [ehrphrafunc_pkg].[f_getClassKind] (@p_emp_no , CONVERT(DATETIME2, @p_start_date),@SOrganType);

       IF @sClassKind ='N/A' BEGIN
        SET @RtnCode = 7;
        GOTO Continue_ForEach1 ;
       --ELSIF @sClassKind IN ('ZZ') THEN 20161219 新增班別 ZX,ZY
       --20180725 108978 增加ZQ
       END
ELSE IF @sClassKind IN ('ZZ','ZX','ZY','ZQ') BEGIN
        GOTO Continue_ForEach2 ;
       END
       ELSE
       BEGIN

           -- EXCEPTION block removed: TRY/CATCH not allowed in T-SQL scalar function

    SELECT  @iCnt = COUNT(*)
    FROM HRP.HRA_CLASSDTL
             Where CLASS_CODE = @sClassKind
               AND ( (@p_start_time >= CHKIN_WKTM AND @p_start_time <  CHKOUT_WKTM)
                OR (@p_end_time > CHKIN_WKTM AND @p_end_time < CHKOUT_WKTM)
                OR (CHKIN_WKTM > @p_start_time AND CHKIN_WKTM < @p_end_time)
                )
               AND SHIFT_NO <> '4';


       IF  @iCnt > 0 BEGIN

       -- EXCEPTION block removed: TRY/CATCH not allowed in T-SQL scalar function

    SELECT  @iSrest_1 = (ISNULL((SELECT  START_REST FROM HRP.HRA_CLASSDTL Where CLASS_CODE = @sClassKind AND SHIFT_NO='1'),'0') ), @iErest_1 = (ISNULL((SELECT  END_REST FROM HRP.HRA_CLASSDTL Where CLASS_CODE = @sClassKind AND SHIFT_NO='1'),'0') ), @iSrest_2 = (ISNULL((SELECT  START_REST FROM HRP.HRA_CLASSDTL Where CLASS_CODE = @sClassKind AND SHIFT_NO='2'),'0') ), @iErest_2 = (ISNULL((SELECT  END_REST FROM HRP.HRA_CLASSDTL Where CLASS_CODE = @sClassKind AND SHIFT_NO='2'),'0') ), @iSrest_3 = (ISNULL((SELECT  START_REST FROM HRP.HRA_CLASSDTL Where CLASS_CODE = @sClassKind AND SHIFT_NO='3'),'0') ), @iErest_3 = (ISNULL((SELECT  END_REST FROM HRP.HRA_CLASSDTL Where CLASS_CODE = @sClassKind AND SHIFT_NO='3'),'0') )
    FROM DUAL;


         IF (@p_start_time  BETWEEN @iSrest_1 AND @iErest_1
        AND @p_end_time BETWEEN @iSrest_1 AND @iErest_1)

         OR (@p_start_time BETWEEN @iSrest_2 AND @iErest_2
        AND @p_end_time BETWEEN @iSrest_2 AND @iErest_2)

         OR (@p_start_time BETWEEN @iSrest_3 AND @iErest_3
        AND @p_end_time BETWEEN @iSrest_3 AND @iErest_3)



        BEGIN
        GOTO Continue_ForEach2 ;
        END

       SET @RtnCode = 8;
       GOTO Continue_ForEach1 ;
       END


       END
       Continue_ForEach2:
       IF @p_start_date <> @p_end_date BEGIN

       --SET @sClassKind = [ehrphrafunc_pkg].[f_getClassKind] (@p_emp_no , CONVERT(DATETIME2, @p_end_date),@SOrganType);
       --20180809 108978 若用end_date會導致抓到後一天的班別，導致出現判斷是否?上班時間出錯
       SET @sClassKind = [ehrphrafunc_pkg].[f_getClassKind] (@p_emp_no , CONVERT(DATETIME2, @p_start_date),@SOrganType);
       --IF @sClassKind IN ('ZZ') THEN 20161219 新增班別 ZX,ZY
       --20180725 108978 增加ZQ
       IF @sClassKind IN ('ZZ','ZX','ZY','ZQ') BEGIN
        SET @RtnCode = 0;
        GOTO Continue_ForEach1 ;
       END
ELSE IF @sClassKind ='N/A' BEGIN
        SET @RtnCode = 7;
        GOTO Continue_ForEach1 ;
       END
       ELSE
       BEGIN

       -- EXCEPTION block removed: TRY/CATCH not allowed in T-SQL scalar function

    SELECT  @iCnt = COUNT(*)
    FROM HRP.HRA_CLASSDTL
             Where CLASS_CODE = @sClassKind
               AND ( (@p_start_time >= CHKIN_WKTM AND @p_start_time <  CHKOUT_WKTM)
                OR (@p_end_time > CHKIN_WKTM AND @p_end_time < CHKOUT_WKTM)
                OR (CHKIN_WKTM > @p_start_time AND CHKIN_WKTM < @p_end_time)
                );


       IF  @iCnt > 0 BEGIN
         IF (@p_start_time  BETWEEN @iSrest_1 AND @iErest_1
        AND @p_end_time BETWEEN @iSrest_1 AND @iErest_1)

         OR (@p_start_time BETWEEN @iSrest_2 AND @iErest_2
        AND @p_end_time BETWEEN @iSrest_2 AND @iErest_2)

         OR (@p_start_time BETWEEN @iSrest_3 AND @iErest_3
        AND @p_end_time BETWEEN @iSrest_3 AND @iErest_3)

        BEGIN
        GOTO Continue_ForEach1 ;
        END
       SET @RtnCode = 8;
       END

       END

       END
       ELSE
       BEGIN
       SET @RtnCode = 0;
       END
       Continue_ForEach1:
    return @RtnCode;
END
GO
