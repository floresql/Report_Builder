SELECT
sm.AREANAME as ma,
COALESCE(sbb.SUB_ACCT_NO_SBB,'0') as Account_Number,
cast(job.CUST_ACCT_NO_OJB as varchar) as Customer_Number,
cast(job.ORDER_NO_OJB as varchar) as Order_Number,
job.JOB_NO_OJB as job_Number,
'' as job_reason_foa,
tslot.DESCR_C12 as time_slot,
cus.CUST_NAME_CUS as Customer_Name,
ho.ADDR1_HSE as Address1,
ho.RES_ADDR_2_HSE as Address2,
ho.RES_CITY_HSE as City,
ho.POSTAL_CDE_HSE as Zip,
PHONE_NO1_CUS as Phone_Primary,
PHONE_NO2_CUS as Phone_Alternate,
ho.RES_STATE_HSe as State,
ho.HSE_KEY_HSE as House_Key,
cus.CUST_TYP_CUS as customer_type_desc,
ho.DWELL_TYP_HSE as	dwelling_type_desc,
ho.MGMT_AREA_HSE as	mgmt_area_Desc,
ho.DROP_HUB_HSE as 	hub,
ho.BRIDGER_ADDR_HSE as 	node,
job.CREATE_DTE_OJB as	order_entered_date,
job.CREATE_TME_OJB as 	order_entered_time,
job.SCHED_DTE_OJB as schedule_date,
job.IR_TECH_OJB as	tech_id,
COALESCE(emp.SMNAM,'0000') as techName,
CASE WHEN emp.WRKTYP = 'C' THEN 1 ELSE 0 END as	tech_contractor,
CASE WHEN emp.WRKTYP = 'C' THEN SMCDXR ELSE 'INHOUSE' END as		tech_contract_firm_name,
CASE WHEN REGEXP_INSTR(job.JOB_TYP_OJB, 'XV|XQ|XT|XU|V8|FA|GU|GW|GX|GY')>0 THEN 1 ELSE 0 END as RESCUE,
CASE WHEN REGEXP_INSTR(job.JOB_TYP_OJB, 'XV|XQ|XT|XU|V8|FA|GU|GW|GX|GY')>0 AND emp.WRKTYP = 'C'  THEN 1 ELSE 0 END as Contractor_RESCUE,
CASE WHEN REGEXP_INSTR(job.JOB_TYP_OJB, 'XV|XQ|XT|XU|V8|FA|GU|GW|GX|GY')>0 AND emp.WRKTYP <> 'C' THEN 1 ELSE 0 END as INHOUSE_RESCUE,
CASE WHEN REGEXP_INSTR(job.JOB_TYP_OJB,'^WQ|Z5|Z7|U8|V8|7W|2V|2W|2X|2Z')>0 THEN 1 ELSE 0 END as Bury_Drop,
CASE WHEN REGEXP_INSTR(job.JOB_TYP_OJB,'^WQ|Z5|Z7|U8|V8|7W|2V|2W|2X|2Z')>0 AND emp.WRKTYP = 'C' THEN 1 ELSE 0 END as Contractor_Bury_Drop,
CASE WHEN REGEXP_INSTR(job.JOB_TYP_OJB,'^WQ|Z5|Z7|U8|V8|7W|2V|2W|2X|2Z')>0 AND emp.WRKTYP <> 'C' THEN 1 ELSE 0 END as INHOUSE_Bury_Drop,
CASE WHEN job.JOB_CLASS_OJB in ('C','R') THEN 1 ELSE 0 END as POS_WORK,
CASE WHEN job.JOB_CLASS_OJB in ('C','R') AND emp.WRKTYP = 'C' THEN 1 ELSE 0 END as Contrator_POS_WORK,
CASE WHEN job.JOB_CLASS_OJB in ('C','R') AND emp.WRKTYP <> 'C' THEN 1 ELSE 0 END as INHOUSE_POS_WORK,
CASE WHEN job.JOB_CLASS_OJB in ('S','T') AND REGEXP_INSTR(job.JOB_TYP_OJB, 'XV|XQ|XT|XU|V8|FA|GU|GW|GX|GY')=0 THEN 1 ELSE 0 END as TROUBLE_CALL,
CASE WHEN job.JOB_CLASS_OJB in ('S','T') AND REGEXP_INSTR(job.JOB_TYP_OJB, 'XV|XQ|XT|XU|V8|FA|GU|GW|GX|GY')=0 AND emp.WRKTYP = 'C'  THEN 1 ELSE 0 END as Contractor_TROUBLE_CALL,
CASE WHEN job.JOB_CLASS_OJB in ('S','T') AND REGEXP_INSTR(job.JOB_TYP_OJB, 'XV|XQ|XT|XU|V8|FA|GU|GW|GX|GY')=0 AND emp.WRKTYP <> 'C'  THEN 1 ELSE 0 END as INHOUSE_TROUBLE_CALL,
CASE WHEN REGEXP_INSTR(job.JOB_TYP_OJB,'^WQ|Z5|Z7|U8|V8|7W|2V|2W|2X|2Z')=0 AND job.JOB_CLASS_OJB in ('Z') THEN 1 ELSE 0 END as OTHER_SRO,
CASE WHEN REGEXP_INSTR(job.JOB_TYP_OJB,'^WQ|Z5|Z7|U8|V8|7W|2V|2W|2X|2Z')=0 AND job.JOB_CLASS_OJB in ('Z') AND emp.WRKTYP = 'C' THEN 1 ELSE 0 END as Contractor_OTHER_SRO,
CASE WHEN REGEXP_INSTR(job.JOB_TYP_OJB,'^WQ|Z5|Z7|U8|V8|7W|2V|2W|2X|2Z')=0 AND job.JOB_CLASS_OJB in ('Z') AND emp.WRKTYP <> 'C' THEN 1 ELSE 0 END as INHOUSE_OTHER_SRO,
job.TOT_SCHED_UNITS_OJB as schedule_points,
job.JOB_TYP_OJB || '-' || c32.JOB_TYP_DESCR_C32 || '-' || c32.JOB_CLASS_C32 as job_type_code,
job.SCHED_CATG_OJB as	schedule_category_code
FROM
	HSE_BASE ho
	JOIN custom.dept.NER_SITE_MAP sm ON
	(
		sm.SYS = ho.SYS_HSE
		AND sm.PRIN = ho.PRIN_HSE
		AND sm.AGENT = ho.AGNT_HSE
	)
	JOIN custom.dept.NER_WO_JOBS job ON
	(
		job.SYS_OJB = ho.SYS_HSE
		AND job.PRIN_OJB = ho.PRIN_HSE
		AND job.HSE_KEY_OJB = ho.HSE_KEY_HSE
		AND job.SCHED_DTE_OJB = to_date(current_date)
		AND job.JOB_STAT_OJB <>'X'
	)
	JOIN SBB_BASE sbb ON
	(
		sbb.SYS_SBB  = ho.SYS_HSE
		AND sbb.PRIN_SBB = ho.PRIN_HSE
		AND sbb.HSE_KEY_SBB = ho.HSE_KEY_HSE
		AND sbb.CUST_ACCT_NO_SBB = job.CUST_ACCT_NO_OJB
	)
	JOIN CUS_BASE cus ON
	(
		cus.SYS_CUS = ho.SYS_HSE
		AND cus.PRIN_CUS in (ho.PRIN_HSE,0)
		AND ho.HSE_KEY_HSE = cus.HSE_KEY_CUS
		AND cus.CUST_ACCT_NO_CUS = job.CUST_ACCT_NO_OJB
	)
	LEFT OUTER JOIN custom.dept.NER_UXIDF1 emp ON
	(
		emp.SMNROV = ho.SYS_HSE
		AND emp.SMRPNB = job.IR_TECH_OJB
		AND job.CREATE_DTE_OJB between TO_DATE(to_char(emp.WKRSD),'YYYY-MM-DD') AND COALESCE(TO_DATE(to_char(emp.WKRED),'YYYY-MM-DD'),current_date)
	)
	LEFT OUTER JOIN C12_INSTALL_TIMES_CODES tslot ON
	(
		tslot.SYS_C12 = job.SYS_OJB
		AND tslot.CDE_TBL_VAL_C12 = job.SCHED_TME01_OJB
		AND tslot.PRIN_C12 = COALESCE(0,ho.PRIN_HSE)
	)
	LEFT OUTER JOIN C32_WO_JOB_TYPES c32 ON
	(
		c32.SYS_C32 = ho.SYS_HSE
		AND c32.PRIN_C32 in (ho.PRIN_HSE,0)
		AND c32.CDE_TBL_VAL_C32 = job.JOB_TYP_OJB
	)
WHERE
	REGEXP_INSTR(JOB_TYP_OJB, 'PE|PF|PG|TM|7X|7Y')=0;


