CREATE OR ALTER FUNCTION [ehrphrafunc_pkg].[f_getvactime]
(    @EmpNo_IN NVARCHAR(MAX),
    @StratDate_IN NVARCHAR(MAX),
    @StartTime_IN NVARCHAR(MAX),
    @OrganType_IN NVARCHAR(MAX),
    @EndTime_IN NVARCHAR(MAX)
)
RETURNS DECIMAL(38,10)
AS
BEGIN
DECLARE @SOrganType NVARCHAR(10) = @OrganType_IN;
DECLARE @nResults SMALLINT;
DECLARE @sEmpNo NVARCHAR(20) = @EmpNo_IN;
DECLARE @sStartDate DATETIME2(0) = CONVERT(DATETIME2, @StratDate_IN);
DECLARE @sStartTime NVARCHAR(4) = @StartTime_IN;
DECLARE @sEndTime NVARCHAR(4) = @EndTime_IN;
DECLARE @iClassCode NVARCHAR(3);
DECLARE @iChkin_wktm1 NVARCHAR(4);
DECLARE @iChkout_wktm1 NVARCHAR(4);
DECLARE @iStart_rest1 NVARCHAR(4);
DECLARE @iEnd_rest1 NVARCHAR(4);
DECLARE @iChkin_wktm2 NVARCHAR(4);
DECLARE @iChkout_wktm2 NVARCHAR(4);
DECLARE @iStart_rest2 NVARCHAR(4);
DECLARE @iEnd_rest2 NVARCHAR(4);
DECLARE @iChkin_wktm3 NVARCHAR(4);
DECLARE @iChkout_wktm3 NVARCHAR(4);
DECLARE @iStart_rest3 NVARCHAR(4);
DECLARE @iEnd_rest3 NVARCHAR(4);
DECLARE @sShift NVARCHAR(3);
    SET @nResults = 0;
  
    SET @iClassCode = [ehrphrafunc_pkg].[f_getClassKind](@sEmpNo,
                                                 @sStartDate,
                                                 @SOrganType);
    -- IF @iClassCode='N/A' OR @iClassCode='ZZ' then 20161219 班表新增  ZY,ZX
    --20180214 取消ZZ限制 108978
    IF @iClassCode = 'N/A' OR @iClassCode IN ('ZY', 'ZX') BEGIN
      SET @nResults = 0; --無排班
      RETURN @nResults;
    END
  
    --時段一
    -- EXCEPTION block removed: TRY/CATCH not allowed in T-SQL scalar function

    SELECT @iChkin_wktm1 = CHKIN_WKTM, @iChkout_wktm1 = CHKOUT_WKTM, @iStart_rest1 = START_REST, @iEnd_rest1 = END_REST
    FROM hra_classdtl
       WHERE CLASS_CODE = @iClassCode
         AND SHIFT_NO = '1';

  
    --時段二
    -- EXCEPTION block removed: TRY/CATCH not allowed in T-SQL scalar function

    SELECT @iChkin_wktm2 = CHKIN_WKTM, @iChkout_wktm2 = CHKOUT_WKTM, @iStart_rest2 = START_REST, @iEnd_rest2 = END_REST
    FROM hra_classdtl
       WHERE CLASS_CODE = @iClassCode
         AND SHIFT_NO = '2';

  
    --時段三
    -- EXCEPTION block removed: TRY/CATCH not allowed in T-SQL scalar function

    SELECT @iChkin_wktm3 = CHKIN_WKTM, @iChkout_wktm3 = CHKOUT_WKTM, @iStart_rest3 = START_REST, @iEnd_rest3 = END_REST
    FROM hra_classdtl
       WHERE CLASS_CODE = @iClassCode
         AND SHIFT_NO = '3';

  
    --    判斷 START_TIME ~ END_TIME 恆跨那幾個時段
    --    因為此程式僅能判斷當天,故時段一定是由小至大
    /*
    have RS and RE
    EE <=  RS
    EE > RS AND ES <=RE
    EE > RE AND ES < CE
    EE >= CE
    
    
    No have RS and RE
    EE < CE
    EE >= CE
    */
  
    --取得該段時間所橫跨的時段
    SET @sShift = [ehrphrafunc_pkg].[f_getShift](@iClassCode, @sStartTime, @sEndTime);
  
    IF @sShift IS NOT NULL BEGIN
      DECLARE @I INT = (1);
WHILE @I <= LEN(@sShift) BEGIN
      
        IF SUBSTRING(@sShift, @I, 1) = '1' BEGIN
        
          IF @iStart_rest1 = '0' BEGIN
            --沒有休息時間
          
            IF @sStartTime >= @iChkin_wktm1 BEGIN
            
              IF @sEndTime >= @iChkout_wktm1 BEGIN
                SET @nResults = [ehrphrafunc_pkg].[f_count_time](@sStartDate,
                                                         @sStartTime,
                                                         @sStartDate,
                                                         @iChkout_wktm1);
              END
              ELSE
              BEGIN
                SET @nResults = [ehrphrafunc_pkg].[f_count_time](@sStartDate,
                                                         @sStartTime,
                                                         @sStartDate,
                                                         @sEndTime);
              END
            
            END
            ELSE
            BEGIN
            
              IF @sEndTime >= @iChkout_wktm1 BEGIN
                SET @nResults = [ehrphrafunc_pkg].[f_count_time](@sStartDate,
                                                         @iChkin_wktm1,
                                                         @sStartDate,
                                                         @iChkout_wktm1);
              END
              ELSE
              BEGIN
                SET @nResults = [ehrphrafunc_pkg].[f_count_time](@sStartDate,
                                                         @iChkin_wktm1,
                                                         @sStartDate,
                                                         @sEndTime);
              END
            
            END
          
          END
          ELSE
          BEGIN
            --有休息時間
          
            IF @sStartTime >= @iChkin_wktm1 BEGIN
            
              IF @sStartTime < @iStart_rest1 BEGIN
              
                IF @sEndTime <= @iStart_rest1 BEGIN
                
                  SET @nResults = [ehrphrafunc_pkg].[f_count_time](@sStartDate,
                                                           @sStartTime,
                                                           @sStartDate,
                                                           @sEndTime);
                
                END
ELSE IF @sEndTime BETWEEN @iStart_rest1 AND @iEnd_rest1 BEGIN
                
                  SET @nResults = [ehrphrafunc_pkg].[f_count_time](@sStartDate,
                                                           @sStartTime,
                                                           @sStartDate,
                                                           @iStart_rest1);
                
                END
ELSE IF @sEndTime BETWEEN @iEnd_rest1 AND @iChkout_wktm1 BEGIN
                
                  SET @nResults = [ehrphrafunc_pkg].[f_count_time](@sStartDate,
                                                           @sStartTime,
                                                           @sStartDate,
                                                           @iStart_rest1) + [ehrphrafunc_pkg].[f_count_time](@sStartDate, @iEnd_rest1, @sStartDate, @sEndTime)
                
                END
                ELSE
                BEGIN
                
                  SET @nResults = [ehrphrafunc_pkg].[f_count_time](@sStartDate,
                                                           @sStartTime,
                                                           @sStartDate,
                                                           @iStart_rest1) + [ehrphrafunc_pkg].[f_count_time](@sStartDate, @iEnd_rest1, @sStartDate, @iChkout_wktm1)
                
                END
              
              END
ELSE IF @sStartTime BETWEEN @iStart_rest1 AND @iEnd_rest1 BEGIN
              
                IF @sEndTime BETWEEN @iStart_rest1 AND @iEnd_rest1 BEGIN
                
                  SET @nResults = 0;
                
                END
ELSE IF @sEndTime <= @iChkout_wktm1 BEGIN
                
                  SET @nResults = [ehrphrafunc_pkg].[f_count_time](@sStartDate,
                                                           @iEnd_rest1,
                                                           @sStartDate,
                                                           @sEndTime);
                
                END
                ELSE
                BEGIN
                
                  SET @nResults = [ehrphrafunc_pkg].[f_count_time](@sStartDate,
                                                           @iEnd_rest1,
                                                           @sStartDate,
                                                           @iChkout_wktm1);
                
                END
              
              END
              ELSE
              BEGIN
              
                IF @sEndTime <= @iChkout_wktm1 BEGIN
                
                  SET @nResults = [ehrphrafunc_pkg].[f_count_time](@sStartDate,
                                                           @sStartTime,
                                                           @sStartDate,
                                                           @sEndTime);
                
                END
                ELSE
                BEGIN
                
                  SET @nResults = [ehrphrafunc_pkg].[f_count_time](@sStartDate,
                                                           @sStartTime,
                                                           @sStartDate,
                                                           @iChkout_wktm1);
                
                END
              
              END
            
              --比上班時間早 BASE ON @iChkin_wktm1
            END
            ELSE
            BEGIN
            
              IF @sEndTime <= @iStart_rest1 BEGIN
              
                SET @nResults = [ehrphrafunc_pkg].[f_count_time](@sStartDate,
                                                         @iChkin_wktm1,
                                                         @sStartDate,
                                                         @sEndTime);
              
              END
ELSE IF @sEndTime BETWEEN @iStart_rest1 AND @iEnd_rest1 BEGIN
              
                SET @nResults = [ehrphrafunc_pkg].[f_count_time](@sStartDate,
                                                         @iChkin_wktm1,
                                                         @sStartDate,
                                                         @iStart_rest1);
              
              END
ELSE IF @sEndTime BETWEEN @iEnd_rest1 AND @iChkout_wktm1 BEGIN
              
                SET @nResults = [ehrphrafunc_pkg].[f_count_time](@sStartDate,
                                                         @iChkin_wktm1,
                                                         @sStartDate,
                                                         @iStart_rest1) + [ehrphrafunc_pkg].[f_count_time](@sStartDate, @iEnd_rest1, @sStartDate, @sEndTime)
              END
              ELSE
              BEGIN
              
                SET @nResults = [ehrphrafunc_pkg].[f_count_time](@sStartDate,
                                                         @iChkin_wktm1,
                                                         @sStartDate,
                                                         @iStart_rest1) + [ehrphrafunc_pkg].[f_count_time](@sStartDate, @iEnd_rest1, @sStartDate, @iChkout_wktm1)
              END
            
            END
          
          END
        
        END
ELSE IF SUBSTRING(@sShift, @I, 1) = '2' BEGIN
          IF @iStart_rest2 = '0' BEGIN
            --沒有休息時間
          
            IF @sStartTime >= @iChkin_wktm2 BEGIN
            
              IF @sEndTime >= @iChkout_wktm2 BEGIN
                SET @nResults = [ehrphrafunc_pkg].[f_count_time](@sStartDate,
                                                         @sStartTime,
                                                         @sStartDate,
                                                         @iChkout_wktm2);
              END
              ELSE
              BEGIN
                SET @nResults = [ehrphrafunc_pkg].[f_count_time](@sStartDate,
                                                         @sStartTime,
                                                         @sStartDate,
                                                         @sEndTime);
              END
            
            END
            ELSE
            BEGIN
            
              IF @sEndTime >= @iChkout_wktm2 BEGIN
                SET @nResults = [ehrphrafunc_pkg].[f_count_time](@sStartDate,
                                                         @iChkin_wktm2,
                                                         @sStartDate,
                                                         @iChkout_wktm2);
              END
              ELSE
              BEGIN
                SET @nResults = [ehrphrafunc_pkg].[f_count_time](@sStartDate,
                                                         @iChkin_wktm2,
                                                         @sStartDate,
                                                         @sEndTime);
              END
            
            END
          
          END
          ELSE
          BEGIN
            --有休息時間
          
            IF @sStartTime >= @iChkin_wktm2 BEGIN
            
              IF @sStartTime < @iStart_rest2 BEGIN
              
                IF @sEndTime <= @iStart_rest2 BEGIN
                
                  SET @nResults = [ehrphrafunc_pkg].[f_count_time](@sStartDate,
                                                           @sStartTime,
                                                           @sStartDate,
                                                           @sEndTime);
                
                END
ELSE IF @sEndTime BETWEEN @iStart_rest2 AND @iEnd_rest2 BEGIN
                
                  SET @nResults = [ehrphrafunc_pkg].[f_count_time](@sStartDate,
                                                           @sStartTime,
                                                           @sStartDate,
                                                           @iStart_rest2);
                
                END
ELSE IF @sEndTime BETWEEN @iEnd_rest2 AND @iChkout_wktm2 BEGIN
                
                  SET @nResults = [ehrphrafunc_pkg].[f_count_time](@sStartDate,
                                                           @sStartTime,
                                                           @sStartDate,
                                                           @iStart_rest2) + [ehrphrafunc_pkg].[f_count_time](@sStartDate, @iEnd_rest2, @sStartDate, @sEndTime)
                
                END
                ELSE
                BEGIN
                
                  SET @nResults = [ehrphrafunc_pkg].[f_count_time](@sStartDate,
                                                           @sStartTime,
                                                           @sStartDate,
                                                           @iStart_rest2) + [ehrphrafunc_pkg].[f_count_time](@sStartDate, @iEnd_rest2, @sStartDate, @iChkout_wktm2)
                
                END
              
              END
ELSE IF @sStartTime BETWEEN @iStart_rest2 AND @iEnd_rest2 BEGIN
              
                IF @sEndTime BETWEEN @iStart_rest2 AND @iEnd_rest2 BEGIN
                
                  SET @nResults = 0;
                
                END
ELSE IF @sEndTime <= @iChkout_wktm2 BEGIN
                
                  SET @nResults = [ehrphrafunc_pkg].[f_count_time](@sStartDate,
                                                           @iEnd_rest2,
                                                           @sStartDate,
                                                           @sEndTime);
                
                END
                ELSE
                BEGIN
                
                  SET @nResults = [ehrphrafunc_pkg].[f_count_time](@sStartDate,
                                                           @iEnd_rest2,
                                                           @sStartDate,
                                                           @iChkout_wktm2);
                
                END
              
              END
              ELSE
              BEGIN
              
                IF @sEndTime <= @iChkout_wktm2 BEGIN
                
                  SET @nResults = [ehrphrafunc_pkg].[f_count_time](@sStartDate,
                                                           @sStartTime,
                                                           @sStartDate,
                                                           @sEndTime);
                
                END
                ELSE
                BEGIN
                
                  SET @nResults = [ehrphrafunc_pkg].[f_count_time](@sStartDate,
                                                           @sStartTime,
                                                           @sStartDate,
                                                           @iChkout_wktm2);
                
                END
              
              END
            
              --比上班時間早 BASE ON @iChkin_wktm2
            END
            ELSE
            BEGIN
            
              IF @sEndTime <= @iStart_rest2 BEGIN
              
                SET @nResults = [ehrphrafunc_pkg].[f_count_time](@sStartDate,
                                                         @iChkin_wktm2,
                                                         @sStartDate,
                                                         @sEndTime);
              
              END
ELSE IF @sEndTime BETWEEN @iStart_rest2 AND @iEnd_rest2 BEGIN
              
                SET @nResults = [ehrphrafunc_pkg].[f_count_time](@sStartDate,
                                                         @iChkin_wktm2,
                                                         @sStartDate,
                                                         @iStart_rest2);
              
              END
ELSE IF @sEndTime BETWEEN @iEnd_rest2 AND @iChkout_wktm2 BEGIN
              
                SET @nResults = [ehrphrafunc_pkg].[f_count_time](@sStartDate,
                                                         @iChkin_wktm2,
                                                         @sStartDate,
                                                         @iStart_rest2) + [ehrphrafunc_pkg].[f_count_time](@sStartDate, @iEnd_rest2, @sStartDate, @sEndTime)
              END
              ELSE
              BEGIN
              
                SET @nResults = [ehrphrafunc_pkg].[f_count_time](@sStartDate,
                                                         @iChkin_wktm2,
                                                         @sStartDate,
                                                         @iStart_rest2) + [ehrphrafunc_pkg].[f_count_time](@sStartDate, @iEnd_rest2, @sStartDate, @iChkout_wktm2)
              END
            
            END
          
          END
        
        END
ELSE IF SUBSTRING(@sShift, @I, 1) = '3' BEGIN
        
          IF @iStart_rest3 = '0' BEGIN
            --沒有休息時間
          
            IF @sStartTime >= @iChkin_wktm3 BEGIN
            
              IF @sEndTime >= @iChkout_wktm3 BEGIN
                SET @nResults = [ehrphrafunc_pkg].[f_count_time](@sStartDate,
                                                         @sStartTime,
                                                         @sStartDate,
                                                         @iChkout_wktm3);
              END
              ELSE
              BEGIN
                SET @nResults = [ehrphrafunc_pkg].[f_count_time](@sStartDate,
                                                         @sStartTime,
                                                         @sStartDate,
                                                         @sEndTime);
              END
            
            END
            ELSE
            BEGIN
            
              IF @sEndTime >= @iChkout_wktm3 BEGIN
                SET @nResults = [ehrphrafunc_pkg].[f_count_time](@sStartDate,
                                                         @iChkin_wktm3,
                                                         @sStartDate,
                                                         @iChkout_wktm3);
              END
              ELSE
              BEGIN
                SET @nResults = [ehrphrafunc_pkg].[f_count_time](@sStartDate,
                                                         @iChkin_wktm3,
                                                         @sStartDate,
                                                         @sEndTime);
              END
            
            END
          
          END
          ELSE
          BEGIN
            --有休息時間
          
            IF @sStartTime >= @iChkin_wktm3 BEGIN
            
              IF @sStartTime < @iStart_rest3 BEGIN
              
                IF @sEndTime <= @iStart_rest3 BEGIN
                
                  SET @nResults = [ehrphrafunc_pkg].[f_count_time](@sStartDate,
                                                           @sStartTime,
                                                           @sStartDate,
                                                           @sEndTime);
                
                END
ELSE IF @sEndTime BETWEEN @iStart_rest3 AND @iEnd_rest3 BEGIN
                
                  SET @nResults = [ehrphrafunc_pkg].[f_count_time](@sStartDate,
                                                           @sStartTime,
                                                           @sStartDate,
                                                           @iStart_rest3);
                
                END
ELSE IF @sEndTime BETWEEN @iEnd_rest3 AND @iChkout_wktm3 BEGIN
                
                  SET @nResults = [ehrphrafunc_pkg].[f_count_time](@sStartDate,
                                                           @sStartTime,
                                                           @sStartDate,
                                                           @iStart_rest3) + [ehrphrafunc_pkg].[f_count_time](@sStartDate, @iEnd_rest3, @sStartDate, @sEndTime)
                
                END
                ELSE
                BEGIN
                
                  SET @nResults = [ehrphrafunc_pkg].[f_count_time](@sStartDate,
                                                           @sStartTime,
                                                           @sStartDate,
                                                           @iStart_rest3) + [ehrphrafunc_pkg].[f_count_time](@sStartDate, @iEnd_rest3, @sStartDate, @iChkout_wktm3)
                
                END
              
              END
ELSE IF @sStartTime BETWEEN @iStart_rest3 AND @iEnd_rest3 BEGIN
              
                IF @sEndTime BETWEEN @iStart_rest3 AND @iEnd_rest3 BEGIN
                
                  SET @nResults = 0;
                
                END
ELSE IF @sEndTime <= @iChkout_wktm3 BEGIN
                
                  SET @nResults = [ehrphrafunc_pkg].[f_count_time](@sStartDate,
                                                           @iEnd_rest3,
                                                           @sStartDate,
                                                           @sEndTime);
                
                END
                ELSE
                BEGIN
                
                  SET @nResults = [ehrphrafunc_pkg].[f_count_time](@sStartDate,
                                                           @iEnd_rest3,
                                                           @sStartDate,
                                                           @iChkout_wktm3);
                
                END
              
              END
              ELSE
              BEGIN
              
                IF @sEndTime <= @iChkout_wktm3 BEGIN
                
                  SET @nResults = [ehrphrafunc_pkg].[f_count_time](@sStartDate,
                                                           @sStartTime,
                                                           @sStartDate,
                                                           @sEndTime);
                
                END
                ELSE
                BEGIN
                
                  SET @nResults = [ehrphrafunc_pkg].[f_count_time](@sStartDate,
                                                           @sStartTime,
                                                           @sStartDate,
                                                           @iChkout_wktm3);
                
                END
              
              END
            
              --比上班時間早 BASE ON @iChkin_wktm3
            END
            ELSE
            BEGIN
            
              IF @sEndTime <= @iStart_rest3 BEGIN
              
                SET @nResults = [ehrphrafunc_pkg].[f_count_time](@sStartDate,
                                                         @iChkin_wktm3,
                                                         @sStartDate,
                                                         @sEndTime);
              
              END
ELSE IF @sEndTime BETWEEN @iStart_rest3 AND @iEnd_rest3 BEGIN
              
                SET @nResults = [ehrphrafunc_pkg].[f_count_time](@sStartDate,
                                                         @iChkin_wktm3,
                                                         @sStartDate,
                                                         @iStart_rest3);
              
              END
ELSE IF @sEndTime BETWEEN @iEnd_rest3 AND @iChkout_wktm3 BEGIN
              
                SET @nResults = [ehrphrafunc_pkg].[f_count_time](@sStartDate,
                                                         @iChkin_wktm3,
                                                         @sStartDate,
                                                         @iStart_rest3) + [ehrphrafunc_pkg].[f_count_time](@sStartDate, @iEnd_rest3, @sStartDate, @sEndTime)
              END
              ELSE
              BEGIN
              
                SET @nResults = [ehrphrafunc_pkg].[f_count_time](@sStartDate,
                                                         @iChkin_wktm3,
                                                         @sStartDate,
                                                         @iStart_rest3) + [ehrphrafunc_pkg].[f_count_time](@sStartDate, @iEnd_rest3, @sStartDate, @iChkout_wktm3)
              END
            
            END
          
          END
        END
      END
    END
    ELSE
    BEGIN
      SET @nResults = 0;
    END
    /*
-- DECLARE @I INT = (1);  -- deduplicated
WHILE @I <= LEN(@sShift) BEGIN
        SET @sShift = 0;
        END
    */
  
    RETURN @nResults;
END
GO
