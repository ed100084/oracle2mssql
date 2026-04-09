CREATE OR ALTER FUNCTION [ehrphrafunc_pkg].[f_HraCadsignTime]
(    @EmpNo_IN NVARCHAR(MAX),
    @Date_IN NVARCHAR(MAX),
    @Type_IN NVARCHAR(MAX)
)
RETURNS NVARCHAR(MAX)
AS
BEGIN
DECLARE @ClassCode NVARCHAR(3);
DECLARE @CntCad DECIMAL(38,10) = 0;
DECLARE @CntOut DECIMAL(38,10) = 0;
DECLARE @CntEvc1 DECIMAL(38,10) = 0;
DECLARE @CntEvc2 DECIMAL(38,10) = 0;
DECLARE @CntEvc3 DECIMAL(38,10) = 0;
DECLARE @CntEvc4 DECIMAL(38,10) = 0;
DECLARE @CntSup DECIMAL(38,10) = 0;
DECLARE @CntUncard1 DECIMAL(38,10) = 0;
DECLARE @CntUncard2 DECIMAL(38,10) = 0;
DECLARE @StratTime NVARCHAR(4);
DECLARE @StartUncard NVARCHAR(1);
DECLARE @EndTime NVARCHAR(4);
DECLARE @EndUncard NVARCHAR(1);
DECLARE @ChkinWktm NVARCHAR(4);
DECLARE @ChkoutWktm NVARCHAR(4);
DECLARE @ChkinCard NVARCHAR(4);
DECLARE @ChkinUncard NVARCHAR(1);
DECLARE @ChkoutCard NVARCHAR(4);
DECLARE @ChkoutUncard NVARCHAR(1);
DECLARE @OutStartTime NVARCHAR(4);
DECLARE @OutEndTime NVARCHAR(4);
DECLARE @EvcStartTime NVARCHAR(4);
DECLARE @EvcEndTime NVARCHAR(4);
DECLARE @VacMessage NVARCHAR(200);
DECLARE @OutStatus NVARCHAR(100);
DECLARE @EvcStatus NVARCHAR(100);
DECLARE @VacStatus NVARCHAR(200);
    SET @ClassCode = [ehrphrafunc_pkg].[F_GETCLASSKIND](@EmpNo_IN,
                                          CONVERT(DATETIME2, @Date_IN),
                                          ISNULL((SELECT ORGAN_TYPE
                                                 FROM HRE_EMPBAS_MON
                                                WHERE YYMM = SUBSTRING(@Date_IN,1,7)
                                                  AND EMP_NO = @EmpNo_IN),
                                              (SELECT ORGAN_TYPE
                                                 FROM HRE_EMPBAS
                                                WHERE EMP_NO = @EmpNo_IN)));
    
    IF @ClassCode LIKE 'Z%' BEGIN
      SET @StratTime = '0000';
      SET @StartUncard = 'N';
      SET @EndTime = '0000';
      SET @EndUncard = 'N';
    END
ELSE IF @ClassCode <> 'N/A' BEGIN
      SELECT @ChkinWktm = CHKIN_WKTM, @ChkoutWktm = CHKOUT_WKTM
    FROM HRA_CLASSDTL
       WHERE CLASS_CODE = @ClassCode
         AND SHIFT_NO = '1';
      SELECT @CntCad = COUNT(*)
    FROM HRA_CADSIGN
       WHERE EMP_NO = @EmpNo_IN
         AND ATT_DATE = CONVERT(DATETIME2, @Date_IN);
      SELECT @CntUncard1 = COUNT(*)
    FROM HRA_UNCARD
       WHERE EMP_NO = @EmpNo_IN
         AND CLASS_DATE = CONVERT(DATETIME2, @Date_IN)
         AND STATUS NOT IN ('N')
         AND UNCARD_TIME = 'A1';
      SELECT @CntUncard2 = COUNT(*)
    FROM HRA_UNCARD
       WHERE EMP_NO = @EmpNo_IN
         AND CLASS_DATE = CONVERT(DATETIME2, @Date_IN)
         AND STATUS NOT IN ('N')
         AND UNCARD_TIME = 'A2';
      SELECT @CntOut = COUNT(*)
    FROM HRA_OUTREC
       WHERE EMP_NO = @EmpNo_IN
         AND START_DATE = CONVERT(DATETIME2, @Date_IN)
         AND STATUS NOT IN ('N')
         AND PERMIT_HR = 'N';
      SELECT @CntEvc1 = COUNT(*)
    FROM HRA_EVCREC
       WHERE EMP_NO = @EmpNo_IN
         AND VAC_TYPE IN ('B','P')
         AND START_DATE = CONVERT(DATETIME2, @Date_IN)
         AND STATUS NOT IN ('N','D');
      IF @CntEvc1 = 0 BEGIN
        SELECT @CntEvc2 = COUNT(*)
    FROM HRA_EVCREC
         WHERE EMP_NO = @EmpNo_IN
           AND VAC_TYPE IN ('B','P')
           AND END_DATE = CONVERT(DATETIME2, @Date_IN)
           AND STATUS NOT IN ('N','D');
      END
      ELSE
      BEGIN
        SET @CntEvc2 = 0;
      END
      IF @CntEvc1 = 0 AND @CntEvc2 = 0 BEGIN
        SELECT @CntEvc3 = COUNT(*)
    FROM HRA_EVCREC
         WHERE EMP_NO = @EmpNo_IN
           AND VAC_TYPE IN ('B','P')
           AND CONVERT(DATETIME2, @Date_IN) > START_DATE
           AND CONVERT(DATETIME2, @Date_IN) < END_DATE
           AND STATUS NOT IN ('N','D');
      END
      ELSE
      BEGIN
        SET @CntEvc3 = 0;
      END
      IF @CntEvc1 = 0 AND @CntEvc2 = 0 AND @CntEvc3 = 0 BEGIN
        SELECT @CntEvc4 = COUNT(*)
    FROM HRA_EVCREC
         WHERE EMP_NO = @EmpNo_IN
           AND VAC_TYPE NOT IN ('B','P')
           AND CONVERT(DATETIME2, @Date_IN) BETWEEN START_DATE AND END_DATE
           AND STATUS NOT IN ('N','D');
        SELECT @CntSup = COUNT(*)
    FROM HRA_SUPMST
         WHERE EMP_NO = @EmpNo_IN
           AND START_DATE = CONVERT(DATETIME2, @Date_IN)
           AND STATUS NOT IN ('N','D');
      END
      ELSE
      BEGIN
        SET @CntEvc4 = 0;
        SET @CntSup = 0;
      END
      IF @CntCad <> 0 BEGIN
        SELECT @ChkinCard = ISNULL(CHKIN_CARD, @ChkinWktm), @ChkinUncard = (CASE WHEN CHKIN_CARD IS NULL THEN 'Y' ELSE 'N' END), @ChkoutCard = ISNULL(CHKOUT_CARD, @ChkoutWktm), @ChkoutUncard = (CASE WHEN CHKOUT_CARD IS NULL THEN 'Y' ELSE 'N' END)
    FROM HRA_CADSIGN
         WHERE EMP_NO = @EmpNo_IN
           AND ATT_DATE = CONVERT(DATETIME2, @Date_IN);
      END
      IF @CntOut = 1 BEGIN --有外出(尚未轉假卡)
        SELECT @OutStartTime = START_TIME, @OutEndTime = ISNULL(END_TIME, @ChkoutWktm), @OutStatus = '外出('+(CASE STATUS WHEN 'U' THEN '請示' WHEN 'N' THEN '退回' ELSE '准' END)+')'
    FROM HRA_OUTREC
         WHERE EMP_NO = @EmpNo_IN
           AND START_DATE = CONVERT(DATETIME2, @Date_IN)
           AND STATUS NOT IN ('N')
           AND PERMIT_HR = 'N';
      END
ELSE IF @CntOut > 1 BEGIN
        SELECT @OutStartTime = MIN(START_TIME), @OutEndTime = (CASE WHEN MAX(END_CHOOSE) = 'Y' THEN @ChkoutWktm ELSE MAX(END_TIME) END), @OutStatus = '外出('+(CASE STATUS WHEN 'U' THEN '請示' WHEN 'N' THEN '退回' ELSE '准' END)+')'
    FROM HRA_OUTREC
         WHERE EMP_NO = @EmpNo_IN
           AND START_DATE = CONVERT(DATETIME2, @Date_IN)
           AND STATUS NOT IN ('N')
           AND PERMIT_HR = 'N';
      END
      IF @CntEvc1 = 1 BEGIN
        SELECT @EvcStartTime = START_TIME, @EvcEndTime = (CASE WHEN START_DATE = END_DATE THEN END_TIME ELSE @ChkoutWktm END), @EvcStatus = (CASE VAC_TYPE WHEN 'P' THEN '公假' ELSE '外出' END)+'('+(CASE STATUS WHEN 'U' THEN '請示' WHEN 'D' THEN '取消' WHEN 'N' THEN '退回' ELSE '准' END)+')'
    FROM HRA_EVCREC
         WHERE EMP_NO = @EmpNo_IN
           AND VAC_TYPE IN ('B','P')
           AND START_DATE = CONVERT(DATETIME2, @Date_IN)
           AND STATUS NOT IN ('N','D');
      END
ELSE IF @CntEvc1 > 1 BEGIN
        SELECT @EvcStartTime = MIN(START_TIME), @EvcEndTime = (CASE WHEN MIN(START_DATE) = MAX(END_DATE) THEN MAX(END_TIME) ELSE @ChkoutWktm END), @EvcStatus = (CASE VAC_TYPE WHEN 'P' THEN '公假' ELSE '外出' END)+'('+(CASE STATUS WHEN 'U' THEN '請示' WHEN 'D' THEN '取消' WHEN 'N' THEN '退回' ELSE '准' END)+')'
    FROM HRA_EVCREC
         WHERE EMP_NO = @EmpNo_IN
           AND VAC_TYPE IN ('B','P')
           AND START_DATE = CONVERT(DATETIME2, @Date_IN)
           AND STATUS NOT IN ('N','D');
      END
      IF @CntEvc2 = 1 BEGIN
        SELECT @EvcStartTime = @ChkinWktm, @EvcEndTime = END_TIME, @EvcStatus = (CASE VAC_TYPE WHEN 'P' THEN '公假' ELSE '外出' END)+'('+(CASE STATUS WHEN 'U' THEN '請示' WHEN 'D' THEN '取消' WHEN 'N' THEN '退回' ELSE '准' END)+')'
    FROM HRA_EVCREC
         WHERE EMP_NO = @EmpNo_IN
           AND VAC_TYPE IN ('B','P')
           AND END_DATE = CONVERT(DATETIME2, @Date_IN)
           AND STATUS NOT IN ('N','D');
      END
ELSE IF @CntEvc2 > 1 BEGIN
        SELECT @EvcStartTime = @ChkinWktm, @EvcEndTime = MAX(END_TIME), @EvcStatus = (CASE VAC_TYPE WHEN 'P' THEN '公假' ELSE '外出' END)+'('+(CASE STATUS WHEN 'U' THEN '請示' WHEN 'D' THEN '取消' WHEN 'N' THEN '退回' ELSE '准' END)+')'
    FROM HRA_EVCREC
         WHERE EMP_NO = @EmpNo_IN
           AND VAC_TYPE IN ('B','P')
           AND END_DATE = CONVERT(DATETIME2, @Date_IN)
           AND STATUS NOT IN ('N','D');
      END
      IF @CntEvc3 <> 0 BEGIN
        SELECT @EvcStartTime = @ChkinWktm, @EvcEndTime = @ChkoutWktm, @EvcStatus = (CASE VAC_TYPE WHEN 'P' THEN '公假' ELSE '外出' END)+'('+(CASE STATUS WHEN 'U' THEN '請示' WHEN 'D' THEN '取消' WHEN 'N' THEN '退回' ELSE '准' END)+')'
    FROM HRA_EVCREC
         WHERE EMP_NO = @EmpNo_IN
           AND VAC_TYPE IN ('B','P')
           AND CONVERT(DATETIME2, @Date_IN) > START_DATE
           AND CONVERT(DATETIME2, @Date_IN) < END_DATE
           AND STATUS NOT IN ('N','D');
      END
    END
    IF @CntCad <> 0 BEGIN --有打卡
      IF @CntOut = 0 AND @CntEvc1 = 0 AND @CntEvc2 = 0 AND @CntEvc3 = 0 BEGIN --無公假/外出
        SET @StratTime = @ChkinCard;
        SET @StartUncard = @ChkinUncard;
        SET @EndTime = @ChkoutCard;
        SET @EndUncard = @ChkoutUncard;
      END
ELSE IF @CntOut <> 0 AND @CntEvc1 = 0 AND @CntEvc2 = 0 AND @CntEvc3 = 0 BEGIN --僅外出
        IF @ChkinCard < @OutStartTime BEGIN
          SET @StratTime = @ChkinCard;
        END
        ELSE
        BEGIN
          SET @StratTime = @OutStartTime;
        END
        IF @ChkoutCard < @OutEndTime BEGIN
          SET @EndTime = @OutEndTime;
        END
        ELSE
        BEGIN
          SET @EndTime = @ChkoutCard;
        END
        SET @StartUncard = @ChkinUncard;
        SET @EndUncard = @ChkoutUncard;
        SET @VacMessage = '(公假/外出'+@OutStartTime+'~'+@OutEndTime+')';
      END
ELSE IF @CntOut = 0 AND (@CntEvc1 <> 0 OR @CntEvc2 <> 0 OR @CntEvc3 <> 0) BEGIN --僅休假
        IF @ChkinCard < @EvcStartTime BEGIN
          SET @StratTime = @ChkinCard;
        END
        ELSE
        BEGIN
          SET @StratTime = @EvcStartTime;
        END
        IF @ChkoutCard < @EvcEndTime BEGIN
          SET @EndTime = @EvcEndTime;
        END
        ELSE
        BEGIN
          SET @EndTime = @ChkoutCard;
        END
        SET @StartUncard = @ChkinUncard;
        SET @EndUncard = @ChkoutUncard;
        SET @VacMessage = '(公假/外出'+@EvcStartTime+'~'+@EvcEndTime+')';
      END
ELSE IF @CntOut <> 0 AND (@CntEvc1 <> 0 OR @CntEvc2 <> 0 OR @CntEvc3 <> 0) BEGIN --有外出也有休假
        IF @ChkinCard < @EvcStartTime AND @EvcStartTime < @OutStartTime BEGIN
          SET @StratTime = @ChkinCard;
        END
ELSE IF @ChkinCard > @EvcStartTime AND @EvcStartTime > @OutStartTime BEGIN
          SET @StratTime = @OutStartTime;
        END
        ELSE
        BEGIN
          SET @StratTime = @EvcStartTime;
        END
        IF @ChkoutCard < @EvcEndTime AND @OutEndTime < @EvcEndTime BEGIN
          SET @EndTime = @EvcEndTime;
        END
ELSE IF @ChkoutCard > @EvcEndTime AND @ChkoutCard > @OutEndTime BEGIN
          SET @EndTime = @ChkoutCard;
        END
        ELSE
        BEGIN
          SET @EndTime = @OutEndTime;
        END
        SET @StartUncard = @ChkinUncard;
        SET @EndUncard = @ChkoutUncard;
        SET @VacMessage = '(公假/外出'+(CASE WHEN @EvcStartTime < @OutStartTime THEN @EvcStartTime ELSE @OutStartTime END)+'~'+
                      (CASE WHEN @EvcEndTime > @OutEndTime THEN @EvcEndTime ELSE @OutEndTime END)+')';
      END
    END
    ELSE
    BEGIN --無打卡
      IF @CntOut <> 0 AND @CntEvc1 = 0 AND @CntEvc2 = 0 AND @CntEvc3 = 0 BEGIN --僅外出
        SET @StratTime = @OutStartTime;
        SET @EndTime = @OutEndTime;
        SET @StartUncard = 'N';
        SET @EndUncard = 'N';
        SET @VacMessage = '(公假/外出'+@OutStartTime+'~'+@OutEndTime+')';
      END
ELSE IF @CntOut = 0 AND (@CntEvc1 <> 0 OR @CntEvc2 <> 0 OR @CntEvc3 <> 0) BEGIN --僅休假
        SET @StratTime = @EvcStartTime;
        SET @EndTime = @EvcEndTime;
        SET @StartUncard = 'N';
        SET @EndUncard = 'N';
        SET @VacMessage = '(公假/外出'+@EvcStartTime+'~'+@EvcEndTime+')';
      END
ELSE IF @CntOut <> 0 AND (@CntEvc1 <> 0 OR @CntEvc2 <> 0 OR @CntEvc3 <> 0) BEGIN --有外出也有休假
        IF @EvcStartTime < @OutStartTime BEGIN
          SET @StratTime = @EvcStartTime;
        END
        ELSE
        BEGIN
          SET @StratTime = @OutStartTime;
        END
        IF @EvcEndTime < @OutEndTime BEGIN
          SET @EndTime = @OutEndTime;
        END
        ELSE
        BEGIN
          SET @EndTime = @EvcEndTime;
        END
        SET @StartUncard = 'N';
        SET @EndUncard = 'N';
        SET @VacMessage = '(公假/外出'+(CASE WHEN @EvcStartTime < @OutStartTime THEN @EvcStartTime ELSE @OutStartTime END)+'~'+
                      (CASE WHEN @EvcEndTime > @OutEndTime THEN @EvcEndTime ELSE @OutEndTime END)+')';
      END
    END
    
    IF @CntUncard1 <> 0 BEGIN
      SELECT @VacStatus = '忘簽到'+'('+(CASE STATUS WHEN 'U' THEN '請示' WHEN 'N' THEN '取消' ELSE '准' END)+')'
    FROM HRA_UNCARD
       WHERE EMP_NO = @EmpNo_IN
         AND CLASS_DATE = CONVERT(DATETIME2, @Date_IN)
         AND STATUS NOT IN ('N')
         AND UNCARD_TIME = 'A1';
    END
    IF @CntUncard2 <> 0 BEGIN
      IF @VacStatus IS NOT NULL BEGIN 
        SELECT @VacStatus = @VacStatus + '忘簽退'+'('+(CASE STATUS WHEN 'U' THEN '請示' WHEN 'N' THEN '取消' ELSE '准' END)+')'
    FROM HRA_UNCARD
         WHERE EMP_NO = @EmpNo_IN
           AND CLASS_DATE = CONVERT(DATETIME2, @Date_IN)
           AND STATUS NOT IN ('N')
           AND UNCARD_TIME = 'A2';
      END
      ELSE
      BEGIN
        SELECT @VacStatus = '忘簽退'+'('+(CASE STATUS WHEN 'U' THEN '請示' WHEN 'N' THEN '取消' ELSE '准' END)+')'
    FROM HRA_UNCARD
         WHERE EMP_NO = @EmpNo_IN
           AND CLASS_DATE = CONVERT(DATETIME2, @Date_IN)
           AND STATUS NOT IN ('N')
           AND UNCARD_TIME = 'A2';
      END
    END
    
    IF @ClassCode NOT LIKE 'Z%' AND 
       @CntCad = 0 AND @CntOut = 0 AND @CntEvc1 = 0 AND @CntEvc2 = 0 AND @CntEvc3 = 0 AND (@CntEvc4 <> 0 OR @CntSup <> 0) BEGIN
    --無打卡也無公假及因公外出但有休假,人員於編外可打卡
      SET @StratTime = '0000';
      SET @StartUncard = 'N';
      SET @EndTime = '0000';
      SET @EndUncard = 'N';
      SET @VacMessage = '(院內休假)';
    END
ELSE IF @ClassCode NOT LIKE 'Z%' AND
          @CntCad = 0 AND @CntOut = 0 AND @CntEvc1 = 0 AND @CntEvc2 = 0 AND @CntEvc3 = 0 AND @CntEvc4 = 0 AND @CntSup = 0 BEGIN
    --無打卡無休假,人員於編外可打卡但註記未打卡
      SET @StratTime = '0000';
      SET @StartUncard = 'Y';
      SET @EndTime = '0000';
      SET @EndUncard = 'Y';
    END
    
    IF @ClassCode <> 'N/A' BEGIN
      IF @Type_IN = 'class' BEGIN
        RETURN @ClassCode;
      END
ELSE IF @Type_IN = 'st' BEGIN
        RETURN @StratTime;
      END
ELSE IF @Type_IN = 'su' BEGIN
        RETURN @StartUncard;
      END
ELSE IF @Type_IN = 'et' BEGIN
        RETURN @EndTime;
      END
ELSE IF @Type_IN = 'eu' BEGIN
        RETURN @EndUncard;
      END
ELSE IF @Type_IN = 'vm' BEGIN
        IF @VacMessage IS NULL BEGIN
          IF @StartUncard = 'Y' AND @EndUncard = 'Y' BEGIN
            SET @VacMessage = '(院內正職未打卡)';
          END
ELSE IF @StartUncard = 'Y' AND @EndUncard = 'N' BEGIN
            SET @VacMessage = '(院內正職上班未打卡)';
          END
ELSE IF @StartUncard = 'N' AND @EndUncard = 'Y' BEGIN
            SET @VacMessage = '(院內正職下班未打卡)';
          END
        END
        ELSE
        BEGIN
          IF @StartUncard = 'Y' AND @EndUncard = 'Y' BEGIN
            SET @VacMessage = @VacMessage+'(院內正職未打卡)';
          END
ELSE IF @StartUncard = 'Y' AND @EndUncard = 'N' BEGIN
            SET @VacMessage = @VacMessage+'(院內正職上班未打卡)';
          END
ELSE IF @StartUncard = 'N' AND @EndUncard = 'Y' BEGIN
            SET @VacMessage = @VacMessage+'(院內正職下班未打卡)';
          END
        END
        RETURN @VacMessage;
      END
ELSE IF @Type_IN = 'vs' BEGIN
        IF @OutStatus IS NOT NULL AND @EvcStatus IS NOT NULL BEGIN
          IF @VacStatus IS NOT NULL BEGIN
            SET @VacStatus = @VacStatus+','+@OutStatus+','+@EvcStatus;
          END
          ELSE
          BEGIN
            SET @VacStatus = @OutStatus+','+@EvcStatus;
          END
        END
ELSE IF @OutStatus IS NOT NULL AND @EvcStatus IS NULL BEGIN
          IF @VacStatus IS NOT NULL BEGIN
            SET @VacStatus = @VacStatus+','+@OutStatus;
          END
          ELSE
          BEGIN
            SET @VacStatus = @OutStatus;
          END
        END
ELSE IF @OutStatus IS NULL AND @EvcStatus IS NOT NULL BEGIN
          IF @VacStatus IS NOT NULL BEGIN
            SET @VacStatus = @VacStatus+','+@EvcStatus;
          END
          ELSE
          BEGIN
            SET @VacStatus = @EvcStatus;
          END
        END
ELSE IF @OutStatus IS NULL AND @EvcStatus IS NULL BEGIN
          IF @StartUncard = 'Y' AND @EndUncard = 'Y' BEGIN
            SET @VacStatus = '未打卡無休假';
          END
        END
        IF @VacStatus IS NULL BEGIN
          IF @StartUncard = 'Y' AND @EndUncard = 'Y' BEGIN
            SET @VacStatus = '未打卡(未申請)';
          END
ELSE IF @StartUncard = 'Y' AND @EndUncard = 'N' BEGIN
            SET @VacStatus = '忘簽到(未申請)';
          END
ELSE IF @StartUncard = 'N' AND @EndUncard = 'Y' BEGIN
            SET @VacStatus = '忘簽退(未申請)';
          END
        END
        RETURN @VacStatus;
      END
    END
    ELSE
    BEGIN
      IF @Type_IN = 'class' BEGIN
        RETURN @ClassCode;
      END
      ELSE
      BEGIN
        RETURN '';
      END
    END
    RETURN NULL; -- safety fallback for error 455
END
GO
