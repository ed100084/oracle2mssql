CREATE OR ALTER FUNCTION [ehrphra12_pkg].[getOffData]
(    @EmpNo_IN NVARCHAR(MAX),
    @CloseDate_IN NVARCHAR(MAX)
)
RETURNS NVARCHAR(MAX)
AS
BEGIN
DECLARE @pYm NVARCHAR(7);
DECLARE @pClsHrs DECIMAL(5,1);
DECLARE @pAppHrs DECIMAL(5,1);
DECLARE @pSumClsHrs DECIMAL(5,1);
DECLARE @pSumAppHrs DECIMAL(5,1);
DECLARE @pOffAddHrs DECIMAL(5,1);
DECLARE @pOffSubHrs DECIMAL(5,1);
DECLARE @pOffSumHrs DECIMAL(5,1);
DECLARE @pOffAppHrs DECIMAL(5,1);
DECLARE @pOffClsHrs DECIMAL(5,1);
DECLARE @pSumclos DECIMAL(5,1);
DECLARE @sMessage NVARCHAR(200) = '';
DECLARE @pSumoneone DECIMAL(5,1);
DECLARE @pSumonethreethree DECIMAL(5,1);
DECLARE @pSumonesixseven DECIMAL(5,1);
DECLARE @pSumonetwo DECIMAL(5,1);
DECLARE @pRevTotHrs DECIMAL(5,1);
DECLARE @pRevHrs DECIMAL(5,1);
DECLARE @pRevTmpHrs DECIMAL(5,1);
DECLARE cursor1 CURSOR FOR
    select t1.sch_ym SCHYM,CAST(t1.mon_addhrs AS NVARCHAR) MONADDHRS,
          CAST(ISNULL(ISNULL(t3.att_value,t2.att_value),0)-t1.mon_addhrs AS NVARCHAR) APPVALUE
     from hra_offrec_cal t1,
          (select trn_ym,emp_no,att_code,att_value from hra_attdtl1
            where att_code = '204' and emp_no = @EmpNo_IN and
                  trn_ym >= (select HRS_ALLOFFYM from hrs_ym where 1=1 /* TODO: converted ROWNUM=1 → use TOP 1 */)) t2,
          (select trn_ym,emp_no,att_code,att_value from hra_attdtl1
            where att_code = '2040' and emp_no = @EmpNo_IN and
                  trn_ym >= (select HRS_ALLOFFYM from hrs_ym where 1=1 /* TODO: converted ROWNUM=1 → use TOP 1 */)) t3
     where t1.sch_ym = t2.trn_ym
       and t1.sch_ym = t3.trn_ym
       and t1.emp_no = @EmpNo_IN
       and t1.sch_ym < SUBSTRING(@CloseDate_IN,1,7)
       and t1.sch_ym >= (select HRS_ALLOFFYM from hrs_ym where 1=1 /* TODO: converted ROWNUM=1 → use TOP 1 */)
     order by t1.sch_ym;
DECLARE cursor2 CURSOR FOR
    select otm_hrs
      from hra_offrec where emp_no = @EmpNo_IN
       and start_date >= CONVERT(DATETIME2, (select HRS_ALLOFFYM + '01' from hrs_ym where 1=1 /* TODO: converted ROWNUM=1 → use TOP 1 */))
       and start_date < CAST(DATEADD(DAY, 1, CONVERT(DATETIME2, @CloseDate_IN)) AS DATE)
       and item_type ='A' and status = 'Y' and disabled='N'
       and  not (permit_id = 'edhr' and otm_rea = '1007')
  order by start_date desc;
    SET @pSumClsHrs = 0;
    SET @pSumAppHrs = 0;

    SET @pSumoneone = 0;
    SET @pSumonethreethree = 0;
    SET @pSumonesixseven = 0;
    SET @pSumonetwo = 0;

    OPEN cursor1;
    WHILE 1=1 BEGIN
      FETCH NEXT FROM cursor1 INTO @pYm, @pClsHrs, @pAppHrs;
      IF @@FETCH_STATUS <> 0 BREAK;
         SET @pSumClsHrs = @pSumClsHrs + @pClsHrs;
         SET @pSumAppHrs = @pSumAppHrs + @pAppHrs;
    END
    CLOSE cursor1;
    DEALLOCATE cursor1

    --單月額外積休
    select @pOffAddHrs = ISNULL(sum(otm_hrs),0)
    FROM hra_offrec where emp_no = @EmpNo_IN
       and start_date >= CONVERT(DATETIME2, SUBSTRING(@CloseDate_IN,1,7) + '01')
       and start_date < CAST(DATEADD(DAY, 1, CONVERT(DATETIME2, @CloseDate_IN)) AS DATE)
       and item_type ='A' and status = 'Y' and disabled='N'
       and  not (permit_id = 'edhr' and otm_rea = '1007');

    --單月額外借休
   select @pOffSubHrs = ISNULL(sum(otm_hrs),0)
    FROM hra_offrec where emp_no = @EmpNo_IN
      and start_date >= CONVERT(DATETIME2, SUBSTRING(@CloseDate_IN,1,7) + '01')
      and start_date < CAST(DATEADD(DAY, 1, CONVERT(DATETIME2, @CloseDate_IN)) AS DATE)
      and item_type ='O' and status = 'Y' and disabled='N'
      and  otm_rea <> '1013';

      SET @pOffSumHrs = @pOffAddHrs - @pOffSubHrs;

    --特簽結算資料
    select @pSumclos = ISNULL(sum(clos_hrs),0)
    FROM hra_offclos
     where emp_no = @EmpNo_IN
       and clos_ym > (select HRS_ALLOFFYM from hrs_ym where 1=1 /* TODO: converted ROWNUM=1 → use TOP 1 */)
       and LEN(clos_ym) = 7;

    --申請=結算+單月(單月積休-單月借休),班表=結算-特簽
     SET @pOffAppHrs = @pSumAppHrs + @pOffSumHrs;
     SET @pOffClsHrs = @pSumClsHrs - @pSumclos;

     --總結小於等於0
     IF (@pOffAppHrs + @pOffClsHrs <= 0) BEGIN
       SET @pSumoneone = @pOffAppHrs + @pOffClsHrs;
     --總結大於0
     END
     ELSE
     BEGIN
       --班表小於等於0
       IF (@pOffClsHrs <= 0) BEGIN
         --總結推算exit
         SET @pRevTotHrs = @pOffAppHrs + @pOffClsHrs;
         OPEN cursor2;
         WHILE 1=1 BEGIN
         FETCH NEXT FROM cursor2 INTO @pRevHrs;
      IF @@FETCH_STATUS <> 0 BREAK;
      SET @pRevTmpHrs = @pRevHrs;
      IF (@pRevTotHrs <= @pRevTmpHrs) BEGIN
        SET @pRevTmpHrs = @pRevTotHrs;
      END
      SET @pRevTotHrs = @pRevTotHrs - @pRevTmpHrs;

      IF (@pRevTmpHrs > 4) BEGIN
        SET @pSumonetwo = @pSumonetwo + (@pRevTmpHrs - 4);
        SET @pRevTmpHrs = 4;
      END

      IF (@pRevTmpHrs > 2) BEGIN
        SET @pSumonesixseven = @pSumonesixseven + (@pRevTmpHrs - 2);
        SET @pRevTmpHrs = 2;
      END

      IF (@pRevTmpHrs > 0) BEGIN
        SET @pSumonethreethree = @pSumonethreethree + @pRevTmpHrs;
        SET @pRevTmpHrs = 0;
      END

      IF (@pRevTotHrs <= 0) BEGIN
        BREAK;
      END

    END
    CLOSE cursor2;
    DEALLOCATE cursor2
       --班表大於0
       END
       ELSE
       BEGIN
         --總結小於等於班表
         IF (@pOffAppHrs + @pOffClsHrs <= @pOffClsHrs) BEGIN
           SET @pSumoneone = @pOffAppHrs + @pOffClsHrs;
         --總結大於班表
         END
         ELSE
         BEGIN
           SET @pSumoneone = @pOffClsHrs;
           --申請推算
           SET @pRevTotHrs = @pOffAppHrs;
           OPEN cursor2;
           WHILE 1=1 BEGIN
           FETCH NEXT FROM cursor2 INTO @pRevHrs;
           IF @@FETCH_STATUS <> 0 BREAK;
           SET @pRevTmpHrs = @pRevHrs;
           IF (@pRevTotHrs <= @pRevTmpHrs) BEGIN
             SET @pRevTmpHrs = @pRevTotHrs;
           END
           SET @pRevTotHrs = @pRevTotHrs - @pRevTmpHrs;

           IF (@pRevTmpHrs > 4) BEGIN
             SET @pSumonetwo = @pSumonetwo + (@pRevTmpHrs - 4);
             SET @pRevTmpHrs = 4;
           END

           IF (@pRevTmpHrs > 2) BEGIN
             SET @pSumonesixseven = @pSumonesixseven + (@pRevTmpHrs - 2);
             SET @pRevTmpHrs = 2;
           END

           IF (@pRevTmpHrs > 0) BEGIN
             SET @pSumonethreethree = @pSumonethreethree + @pRevTmpHrs;
             SET @pRevTmpHrs = 0;
           END

           IF (@pRevTotHrs <= 0) BEGIN
             BREAK;
           END
           END
           CLOSE cursor2;
    DEALLOCATE cursor2

         END
       END
     END

    SET @sMessage = '一比一時數:' + CAST(@pSumoneone AS NVARCHAR) + ',一比一點三三時數:' + CAST(@pSumonethreethree AS NVARCHAR) +
                ',一比一點六七時數:' + CAST(@pSumonesixseven AS NVARCHAR) + ',一比二時數:' + CAST(@pSumonetwo AS NVARCHAR);
    RETURN @sMessage;
END
GO
