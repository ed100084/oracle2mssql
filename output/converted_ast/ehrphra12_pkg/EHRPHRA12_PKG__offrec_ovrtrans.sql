CREATE OR ALTER PROCEDURE [ehrphra12_pkg].[offrec_ovrtrans]
(    @UpdateBy_IN NVARCHAR(MAX),
    @organtype_IN NVARCHAR(MAX),
    @RtnCode DECIMAL(38,10) OUTPUT
)
AS
DECLARE @iCnt SMALLINT;
DECLARE @ichecked NVARCHAR(1);
DECLARE @dTrnym NVARCHAR(7);
DECLARE @dSignman NVARCHAR(20);
DECLARE @dEmail NVARCHAR(120);
DECLARE @dDeptno NVARCHAR(20);
DECLARE @dDeptname NVARCHAR(60);
DECLARE @dOvrtype NVARCHAR(60);
DECLARE @dSignmanTmp NVARCHAR(20);
DECLARE @dEmailTmp NVARCHAR(120);
DECLARE @sMessageL NVARCHAR(MAX);
DECLARE @pMessageL NVARCHAR(MAX);
DECLARE @sEMail NVARCHAR(120);
DECLARE @qHrsym NVARCHAR(7);
DECLARE @qSignman NVARCHAR(20);
DECLARE @qPermit_id NVARCHAR(20);
DECLARE @qDeptno NVARCHAR(20);
DECLARE @qStatus NVARCHAR(1);
DECLARE @qOvrtyp NVARCHAR(1);
DECLARE @qOvravg DECIMAL(7,2);
DECLARE @qOvrths DECIMAL(7,2);
DECLARE @qOvryel DECIMAL(7,2);
DECLARE @qOvrred DECIMAL(7,2);
DECLARE @qPremon DECIMAL(7,2);
DECLARE @qNowmon DECIMAL(7,2);
DECLARE @sOrganType NVARCHAR(10);
DECLARE cursor1 CURSOR FOR
    select trn_tm,signman,email,dept_no,deptname,sta from
   (
select  trn_tm,signman,(select 'ed'+hre_empbas.emp_no+'@edah.org.tw' from hre_empbas where organ_type = @sOrganType and emp_no = t1.signman) email,
    	dept_no,(select ch_name from hre_orgbas where organ_type = @sOrganType and dept_no = t1.dept_no) deptname,
case ovr_type when 'A' then '紅燈警示' when 'B' then '黃燈警示' when 'C' then '連續兩個月超過閾值' else '' end sta
 from hra_offovrres t1  where org_by = @sOrganType and  trn_tm = (select hrs_ym from hrs_ym where 1=1 /* TODO: converted ROWNUM=1 → use TOP 1 */) and need_reply = 'Y'
UNION ALL
select  trn_tm,(select user_signman from hre_Empbas where organ_type = @sOrganType and emp_no = t2.signman),
        (select 'ed'+hre_empbas.emp_no+'@edah.org.tw' from hre_empbas where organ_type = @sOrganType and emp_no = (select user_signman from hre_empbas where organ_type = @sOrganType and emp_no = t2.signman)) email,
    	dept_no,(select ch_name from hre_orgbas where organ_type = @sOrganType and dept_no = t2.dept_no) deptname,
        case ovr_type when  'A' then '紅燈警示需覆核' when 'B' then '黃燈警示需覆核' else '連續兩個月超過閾值需覆核' end
 from hra_offovrres t2
  where org_by = @sOrganType and trn_tm = (select hrs_ym from hrs_ym where 1=1 /* TODO: converted ROWNUM=1 → use TOP 1 */) and ovr_type in ('A','B','C') and need_reply = 'Y'
    and (select user_signman from hre_Empbas where organ_type = @sOrganType and emp_no = t2.signman) not in (select code_name from hr_codedtl where code_type = 'HRA32' and CAST(code_no AS DECIMAL(38,10)) < 100)
 ) AS _dt1
  order by signman;
DECLARE cursor2 CURSOR FOR
    SELECT 'ed'+hre_empbas.emp_no+'@edah.org.tw' AS e_mail
      FROM hr_codedtl, hre_empbas
     WHERE hre_empbas.organ_type = @sOrganType and  (hr_codedtl.code_name = hre_empbas.emp_no) and
           ((hr_codedtl.code_type = 'HRA99') AND
           (hr_codedtl.code_no like 'C%'));
DECLARE cursor3 CURSOR FOR
    with tb as (
		 select dept_no,signman from (
		   select dept_no,signman,cnt,Rank() over (Partition BY dept_no order by cnt desc) rnk from(
		     select dept_no,signman,count(dept_no) cnt from(
		     select dept_no,(select user_signman from hre_empbas where organ_type = @sOrganType and emp_no = t2.emp_no) signman
		       from hre_empbas t2 where organ_type = @sOrganType and disabled ='N' and (emp_flag='01' or dept_no = 'Z050')  and (job_lev <> 'R' or job_lev is null)
		     ) AS _dt2
		      group by dept_no,signman
		   ) AS _dt3
		 ) AS _dt4 where rnk = 1
		 )
       select (select hrs_ym from hrs_ym where 1=1 /* TODO: converted ROWNUM=1 → use TOP 1 */),
	      (select signman from tb where dept_no = hra_offovr.dept_no and 1=1 /* TODO: converted ROWNUM=1 → use TOP 1 */),
        (select user_signman from hre_empbas where organ_type = @sOrganType  and emp_no = (select signman from tb where dept_no = hra_offovr.dept_no and 1=1 /* TODO: converted ROWNUM=1 → use TOP 1 */)),
		     DEPT_NO,'U',STR_YM,OVR_AVG,
         OVR_THS, OVR_YEL, OVR_RED,
         (select sum(mon_getadd + mon_addhrs+
           ISNULL((select sum(sotm_hrs) from hra_offrec where org_by = @sOrganType and FORMAT(start_date, 'yyyy-MM') = t1.sch_ym and item_type ='A'
           and status = 'Y' and disabled='N' and otm_rea <> '1007' and dept_no = t1.dept_no and emp_no = t1.emp_no
		   ),0)-
           ISNULL((select sum(sotm_hrs) from hra_offrec where org_by = @sOrganType and FORMAT(start_date, 'yyyy-MM') = t1.sch_ym and item_type ='O'
           and status = 'Y' and disabled='N' and  otm_rea <> '1013' and dept_no = t1.dept_no and emp_no = t1.emp_no
		   ),0)
					  ) attvalue from hra_attvac_view t1
	                  where t1.sch_ym = (select  FORMAT(DATEADD(DAY, -1, CONVERT(DATETIME2, hrs_ym + '-01')), 'yyyy-mm')  from hrs_ym)
					  and dept_no = hra_offovr.DEPT_NO) PREMON,
          (select sum(mon_getadd + mon_addhrs+
           ISNULL((select sum(sotm_hrs) from hra_offrec where org_by = @sOrganType and  FORMAT(start_date, 'yyyy-MM') = t1.sch_ym and item_type ='A'
           and status = 'Y' and disabled='N' and otm_rea <> '1007' and dept_no = t1.dept_no and emp_no = t1.emp_no
		   ),0)-
           ISNULL((select sum(sotm_hrs) from hra_offrec where org_by = @sOrganType and FORMAT(start_date, 'yyyy-MM') = t1.sch_ym and item_type ='O'
           and status = 'Y' and disabled='N' and  otm_rea <> '1013' and dept_no = t1.dept_no and emp_no = t1.emp_no
		   ),0)
					  ) attvalue from hra_attvac_view t1
	                  where organ_type = @sOrganType and t1.sch_ym = (select hrs_ym from hrs_ym)
					  and dept_no = hra_offovr.DEPT_NO and emp_no not in (select code_name from hr_codedtl where code_type= 'HRA32' and code_no like '2%')) NOWMON
         from hra_offovr where organ_type = @sOrganType and ovr_type = 'B' and create_res ='Y' and str_ym <> 'Z';
BEGIN
  SET @RtnCode = 0;
  SET @sOrganType = @organtype_IN;

  select @ichecked = create_res
    FROM hra_offovr
   where ovr_type = 'A'
     AND organ_type = @sOrganType;

  IF (@ichecked = 'Y') BEGIN

    OPEN cursor3;
      WHILE 1=1 BEGIN
     FETCH NEXT FROM cursor3 INTO @qHrsym ,@qSignman, @qPermit_id ,@qDeptno ,@qStatus , @qOvrtyp, @qOvravg, @qOvrths,@qOvryel, @qOvrred, @qPremon, @qNowmon;
      IF @@FETCH_STATUS <> 0 BREAK;

    insert into hra_offovrres (TRN_TM, SIGNMAN, PERMIT_ID, Permit_Status , DEPT_NO,
   STATUS, OVR_TYPE, OVR_AVG,
   OVR_THS, OVR_YEL, OVR_RED,
   NEED_REPLY,Keep_Premon,Keep_Thismon,
   CREATED_BY, CREATION_DATE,
   LAST_UPDATED_BY, LAST_UPDATE_DATE,org_By) VALUES
    (@qHrsym ,@qSignman, @qPermit_id ,'N',@qDeptno ,@qStatus, @qOvrtyp, @qOvravg, @qOvrths,@qOvryel,
     @qOvrred,
     'Y',@qPremon,@qNowmon,
     @UpdateBy_IN,GETDATE(),@UpdateBy_IN,GETDATE(),@sOrganType);
    END
    CLOSE cursor3;
    DEALLOCATE cursor3
    --修改控制不需要維護或替代資料
    update hra_offovrres
       set NEED_REPLY ='N'
     where TRN_TM = (select hrs_ym from hrs_ym where 1=1 /* TODO: converted ROWNUM=1 → use TOP 1 */)
       and signman in (select code_name from hr_codedtl where code_type = 'HRA32' and CAST(code_no AS DECIMAL(38,10)) < 100)
       and org_By = @sOrganType  ;

    update hra_offovrres
       set signman = (select REMARK from hr_codedtl where code_type = 'HRA32' and CAST(code_no AS DECIMAL(38,10)) between 100 and 199 and code_name = signman)
     where TRN_TM = (select hrs_ym from hrs_ym where 1=1 /* TODO: converted ROWNUM=1 → use TOP 1 */)
       and signman in (select code_name from hr_codedtl where code_type = 'HRA32' and CAST(code_no AS DECIMAL(38,10)) between 100 and 199)
       and org_By = @sOrganType;

    update hra_offovrres set permit_id = null where  permit_id = '100003'
        and TRN_TM = (select hrs_ym from hrs_ym where 1=1 /* TODO: converted ROWNUM=1 → use TOP 1 */)
        and org_By = @sOrganType;
    --新增不需要回覆的資料供報表抓取
    insert into hra_offovrres(TRN_TM,org_by, SIGNMAN,Permit_Id , permit_status, DEPT_NO,
   STATUS, OVR_TYPE, OVR_AVG,
   OVR_THS, OVR_YEL, OVR_RED,
   NEED_REPLY,Keep_Premon,Keep_Thismon,
   CREATED_BY, CREATION_DATE,
   LAST_UPDATED_BY, LAST_UPDATE_DATE)
   (
   select (select hrs_ym from hrs_ym where 1=1 /* TODO: converted ROWNUM=1 → use TOP 1 */),@sOrganType,
	      'MIS' ,'MIS', 'Y' ,
		    DEPT_NO,'R',STR_YM,OVR_AVG,
         OVR_THS, OVR_YEL, OVR_RED,'N',
         (select sum(mon_getadd + mon_addhrs+
           ISNULL((select sum(sotm_hrs) from hra_offrec where org_by = @sOrganType and FORMAT(start_date, 'yyyy-MM') = t1.sch_ym and item_type ='A'
           and status = 'Y' and disabled='N' and otm_rea <> '1007' and dept_no = t1.dept_no and emp_no = t1.emp_no
		   ),0)-
           ISNULL((select sum(sotm_hrs) from hra_offrec where org_by = @sOrganType and FORMAT(start_date, 'yyyy-MM') = t1.sch_ym and item_type ='O'
           and status = 'Y' and disabled='N' and  otm_rea <> '1013' and dept_no = t1.dept_no and emp_no = t1.emp_no
		   ),0)
					  ) attvalue from hra_attvac_view t1
	                  where organ_type = @sOrganType and t1.sch_ym = (select  FORMAT(DATEADD(DAY, -1, CONVERT(DATETIME2, hrs_ym + '-01')), 'yyyy-mm')  from hrs_ym)
					  and dept_no = hra_offovr.DEPT_NO) PREMON,
          (select sum(mon_getadd + mon_addhrs+
           ISNULL((select sum(sotm_hrs) from hra_offrec where org_by = @sOrganType and FORMAT(start_date, 'yyyy-MM') = t1.sch_ym and item_type ='A'
           and status = 'Y' and disabled='N' and otm_rea <> '1007' and dept_no = t1.dept_no and emp_no = t1.emp_no
		   ),0)-
           ISNULL((select sum(sotm_hrs) from hra_offrec where org_by = @sOrganType and FORMAT(start_date, 'yyyy-MM') = t1.sch_ym and item_type ='O'
           and status = 'Y' and disabled='N' and  otm_rea <> '1013' and dept_no = t1.dept_no and emp_no = t1.emp_no
		   ),0)
					  ) attvalue from hra_attvac_view t1
	                  where organ_type = @sOrganType and t1.sch_ym = (select hrs_ym from hrs_ym)
					  and dept_no = hra_offovr.DEPT_NO) NOWMON
              ,@UpdateBy_IN,GETDATE(),@UpdateBy_IN,GETDATE()
         from hra_offovr where org_by = @sOrganType and ovr_type = 'B' and DEPT_NO NOT IN (SELECT DEPT_NO FROM hra_offovrres WHERE org_by = @sOrganType and TRN_TM = (select hrs_ym from hrs_ym where 1=1 /* TODO: converted ROWNUM=1 → use TOP 1 */))
   );

    UPDATE hra_offovr set create_res = 'N' where create_res ='Y' and organ_type = @sOrganType;


    COMMIT TRAN;

    OPEN cursor1;
      WHILE 1=1 BEGIN
     FETCH NEXT FROM cursor1 INTO @dTrnym,@dSignman ,@dEmail ,@dDeptno, @dDeptname, @dOvrtype;
      IF @@FETCH_STATUS <> 0 BREAK;


      IF (LTRIM(RTRIM(@dSignmanTmp)) IS NULL OR @dSignmanTmp <> @dSignman) BEGIN
        IF LTRIM(RTRIM(@sMessageL)) IS NOT NULL BEGIN
         --主管mail發送
         SET @sMessageL = @sMessageL +'</table>';
         if (@dEmailTmp <> 'ed100003@edah.org.tw') BEGIN --暫時移除特助
         EXEC [ehrphrafunc_pkg].[POST_HTML_MAIL] 'system@edah.org.tw',@dEmailTmp,'ed101961@edah.org.tw','2','出勤管理-積借休異常通知', @sMessageL;
         END
       END
        SET @sMessageL = '以下部門為' + @dTrnym + '積借休異常，' +
                     '若需回覆請主管們至MIS,出勤管理系統-出勤作業-積借休異常維護維護說明原因，謝謝！'+
                     '<table><tr><td>部門</td><td>部門名稱</td><td>異常情況</td><td>主管</td></tr>'+
                     '<tr><td>'+@dDeptno+'</td><td>'+@dDeptname+'</td><td>' + @dOvrtype + '</td><td>' + @dSignman + '</td></tr>';
      END
      ELSE
      BEGIN
        SET @sMessageL = @sMessageL + '<tr><td>'+@dDeptno+'</td><td>'+@dDeptname+'</td><td>' + @dOvrtype + '</td><td>' + @dSignman + '</td></tr>';
      END
       -- 暫存上次的主管工號和MAIL
      SET @dSignmanTmp = @dSignman;
      SET @dEmailTmp = @dEmail;

      --組合管理者MAIL
      IF LTRIM(RTRIM(@pMessageL)) IS NOT NULL BEGIN
         SET @pMessageL = @pMessageL + '<tr><td>'+@dDeptno+'</td><td>'+@dDeptname+'</td><td>' + @dOvrtype + '</td><td>' + @dSignman + '</td></tr>';
      END
      ELSE
      BEGIN
        SET @pMessageL = '以下部門為' + @dTrnym + '積借休異常，' +
                     '<table><tr><td>部門</td><td>部門名稱</td><td>異常情況</td><td>主管</td></tr>'+
                     '<tr><td>'+@dDeptno+'</td><td>'+@dDeptname+'</td><td>' + @dOvrtype + '</td><td>' + @dSignman + '</td></tr>';
      END
    END
    CLOSE cursor1;
    DEALLOCATE cursor1
    --最後一位主管的MAIL發送
    IF LTRIM(RTRIM(@sMessageL)) IS NOT NULL BEGIN
      SET @sMessageL = @sMessageL +'</table>';
      if (@dEmailTmp <> 'ed100003@edah.org.tw') BEGIN -- 暫時移除特助
      EXEC [ehrphrafunc_pkg].[POST_HTML_MAIL] 'system@edah.org.tw',@dEmailTmp,'ed101961@edah.org.tw','2','出勤管理-積借休異常通知', @sMessageL;
      END
    END
    --管理者MAIL發送
    IF LTRIM(RTRIM(@pMessageL)) IS NOT NULL BEGIN
      SET @pMessageL = @pMessageL +'</table>';
      OPEN cursor2;
        WHILE 1=1 BEGIN
       FETCH NEXT FROM cursor2 INTO @sEMail;
        IF @@FETCH_STATUS <> 0 BREAK;
          EXEC [ehrphrafunc_pkg].[POST_HTML_MAIL] 'system@edah.org.tw', @sEMail,'ed101961@edah.org.tw','2','出勤管理-積借休異常通知', @pMessageL;
       END
       CLOSE cursor2;
    DEALLOCATE cursor2
    END


  END
END
GO
