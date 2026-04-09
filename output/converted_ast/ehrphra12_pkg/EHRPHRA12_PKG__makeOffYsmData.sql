CREATE OR ALTER PROCEDURE [ehrphra12_pkg].[makeOffYsmData]
(    @LastUpdateBy_IN NVARCHAR(MAX),
    @RtnCode DECIMAL(38,10) OUTPUT
)
AS
DECLARE @pStartdate DATETIME2(0);
DECLARE @pEnddate DATETIME2(0);
DECLARE @pEmpNo NVARCHAR(20);
DECLARE @pAppHrs DECIMAL(10,4);
DECLARE @pClsHrs DECIMAL(10,4);
DECLARE @pOtmhrs DECIMAL(5,1);
DECLARE @sEmpNo NVARCHAR(20);
DECLARE @sStartdate DATETIME2(0);
DECLARE @sStartTime NVARCHAR(4);
DECLARE @sStatus NVARCHAR(1);
DECLARE @sItemType NVARCHAR(1);
DECLARE @sOtmhrs DECIMAL(5,1);
DECLARE cursor1 CURSOR FOR
    select emp_no,apphrs,clshrs
     from hra_offrec_ysm t1
     where t1.sch_ym = FORMAT(@pEnddate, 'yyyy-mm')
     order by t1.sch_ym;
DECLARE cursor2 CURSOR FOR
    select EMP_NO,START_DATE,START_TIME,STATUS,ITEM_TYPE,OTM_HRS
      from hra_offrec where emp_no = @pEmpNo
       and start_date >= @pStartdate
       and start_date <= @pEnddate
       and item_type ='A' and status = 'Y' and disabled='N'
       and  not (permit_id = 'edhr' and otm_rea = '1007')
  order by start_date desc;
BEGIN
    SET @RtnCode = 0;

    Select @pStartdate = CONVERT(DATETIME2, (select HRS_ALLOFFYM from hrs_ym where 1=1 /* TODO: converted ROWNUM=1 → use TOP 1 */) + '01')
    FROM dual;

    Select @pEnddate = EOMONTH(CONVERT(DATETIME2, (select max(sch_ym) from hra_offrec_cal) + '01'))
    FROM dual;


    INSERT INTO HRA_OFFREC_YSM (SCH_YM, EMP_NO,
      DEPT_NO,
      SCH_DATE, APPHRS, CLSHRS, SPEHRS,
      DUTI_APP, DUTI_CLS, UNDU_APP, UNDU_CLS,
      CREATED_BY, CREATION_DATE, LAST_UPDATED_BY, LAST_UPDATE_DATE)
      (SELECT FORMAT(@pEnddate, 'yyyy-mm'),EMP_NO,
              (SELECT DEPT_NO FROM HRE_EMPBAS WHERE EMP_NO = t2.EMP_NO),
              GETDATE(),ISNULL(ADDS,0)-ISNULL(MINUSS,0),ISNULL(CLSHRS,0),ISNULL(SPEHRS,0),
              0,0,0,0,
              @LastUpdateBy_IN,GETDATE(),@LastUpdateBy_IN,GETDATE()
         FROM (select emp_no,sum(mon_addhrs-mon_specal) clshrs,
                  (select tot_hrs from hra_offclos where emp_no = t1.emp_no and clos_ym ='2010-9') spehrs,
                  (select ISNULL(sum(otm_hrs),0)
                     from hra_offrec where emp_no = t1.emp_no
                      and start_date >= @pStartdate
                      and start_date <= @pEnddate
                      and item_type ='A' and status = 'Y' and disabled='N'
                      and  not (permit_id = 'edhr' and otm_rea = '1007')
	           ) adds,
                   (select ISNULL(sum(otm_hrs),0)
                      from hra_offrec where emp_no = t1.emp_no
                       and start_date >= @pStartdate
                       and start_date <= @pEnddate
                       and item_type ='O' and status = 'Y' and disabled='N'
                       and  otm_rea <> '1013'
	            ) minuss
                from hra_offrec_cal t1
               where t1.sch_ym >= FORMAT(@pStartdate, 'yyyy-mm')
	         and disabled ='N'
            group by emp_no)  t2
      );

    OPEN cursor1;
    WHILE 1=1 BEGIN
      FETCH NEXT FROM cursor1 INTO @pEmpNo,@pAppHrs, @pClsHrs;
      IF @@FETCH_STATUS <> 0 BREAK;
     --總結小於等於0
      IF (@pAppHrs+@pClsHrs <= 0) BEGIN
        update hra_offrec
           set rem_hrs = 0,
               REM_DATE = GETDATE()
         where emp_no = @pEmpNo
           and start_date >= @pStartdate
           and start_date <= @pEnddate
           and item_type ='A' and status = 'Y' and disabled='N'
           and  not (permit_id = 'edhr' and otm_rea = '1007');
      END
      ELSE
      BEGIN
      --總結大於0

       --班表大於0
       IF (@pClsHrs > 0) BEGIN
         --總結小於等於班表
         IF (@pAppHrs + @pClsHrs <= @pClsHrs) BEGIN
           update hra_offrec
              set rem_hrs = 0,
                  REM_DATE = GETDATE()
            where emp_no = @pEmpNo
              and start_date >= @pStartdate
              and start_date <= @pEnddate
              and item_type ='A' and status = 'Y' and disabled='N'
              and  not (permit_id = 'edhr' and otm_rea = '1007');
         END
         ELSE
         BEGIN
         --總結大於班表,需用申請推算回壓剩餘時數
           SET @pOtmhrs = @pAppHrs;
             OPEN cursor2;
             WHILE 1=1 BEGIN
             FETCH NEXT FROM cursor2 INTO @sEmpNo,@sStartdate,@sStartTime,@sStatus,@sItemType,@sOtmhrs;
             IF @@FETCH_STATUS <> 0 BREAK;
               IF (@pOtmhrs >= @sOtmhrs) BEGIN
                 UPDATE hra_offrec
                    SET rem_hrs = @sOtmhrs,
                        REM_DATE = GETDATE()
                  where emp_no = @sEmpNo
                    and start_date = @sStartdate
                    and start_time = @sStartTime
                    and status = @sStatus
                    and item_type = @sItemType;
               END
               ELSE
               BEGIN
                 IF (@pOtmhrs > 0) BEGIN
                 UPDATE hra_offrec
                    SET rem_hrs = @pOtmhrs,
                        REM_DATE = GETDATE()
                  where emp_no = @sEmpNo
                    and start_date = @sStartdate
                    and start_time = @sStartTime
                    and status = @sStatus
                    and item_type = @sItemType;
                 END
                 ELSE
                 BEGIN
                   SET @pOtmhrs = 0;
                 UPDATE hra_offrec
                    SET rem_hrs = 0,
                        REM_DATE = GETDATE()
                  where emp_no = @sEmpNo
                    and start_date = @sStartdate
                    and start_time = @sStartTime
                    and status = @sStatus
                    and item_type = @sItemType;
                  END
               END
               SET @pOtmhrs = @pOtmhrs - @sOtmhrs;

             END
             CLOSE cursor2;
    DEALLOCATE cursor2

         END

       END
       ELSE
       BEGIN
       --班表小於等於0,需用總結推算回壓剩餘時數
       SET @pOtmhrs = @pAppHrs+@pClsHrs;
             OPEN cursor2;
             WHILE 1=1 BEGIN
             FETCH NEXT FROM cursor2 INTO @sEmpNo,@sStartdate,@sStartTime,@sStatus,@sItemType,@sOtmhrs;
             IF @@FETCH_STATUS <> 0 BREAK;
               IF (@pOtmhrs >= @sOtmhrs) BEGIN
                 UPDATE hra_offrec
                    SET rem_hrs = @sOtmhrs,
                        REM_DATE = GETDATE()
                  where emp_no = @sEmpNo
                    and start_date = @sStartdate
                    and start_time = @sStartTime
                    and status = @sStatus
                    and item_type = @sItemType;
               END
               ELSE
               BEGIN
                 IF (@pOtmhrs > 0) BEGIN
                 UPDATE hra_offrec
                    SET rem_hrs = @pOtmhrs,
                        REM_DATE = GETDATE()
                  where emp_no = @sEmpNo
                    and start_date = @sStartdate
                    and start_time = @sStartTime
                    and status = @sStatus
                    and item_type = @sItemType;
                 END
                 ELSE
                 BEGIN
                   SET @pOtmhrs = 0;
                 UPDATE hra_offrec
                    SET rem_hrs = 0,
                        REM_DATE = GETDATE()
                  where emp_no = @sEmpNo
                    and start_date = @sStartdate
                    and start_time = @sStartTime
                    and status = @sStatus
                    and item_type = @sItemType;
                  END
               END
               SET @pOtmhrs = @pOtmhrs - @sOtmhrs;

             END
             CLOSE cursor2;
    DEALLOCATE cursor2
       END
      END


    END
    CLOSE cursor1;
    DEALLOCATE cursor1
    COMMIT TRAN;
END
GO
