 
 
/*********************************************************************
*                       MODIFICATION CONTROL LOG		             *
**********************************************************************
*                                                                    *
Mod Date       Worker        Comment                                 *
--- ---------- ------------- ----------------------------------------*
001 04/01/2022 Shruthi R    Initial Development
 
**********************************************************************/
 
DROP PROGRAM avh_adhoc_requests GO
CREATE PROGRAM avh_adhoc_requests
 
prompt
	"Output to File/Printer/MINE" = "MINE"   ;* Enter or select the printer or file name to send this report to.
	, "Start Date:" = "SYSDATE"
	, "End Date:" = "SYSDATE"
 
with pOUTDEV, BEG_DT, END_DT
 
 
/***************************************************************************************
* Gather Prompt Information															   *
***************************************************************************************/
 
;Format the dates for explorermenu and ops
DECLARE START_DATE 	= DQ8
DECLARE END_DATE 	= DQ8
DECLARE EVENT_START_DATE 	= DQ8
DECLARE EVENT_END_DATE 		= DQ8
DECLARE INDEX = I4
 
 
 
;----------------------------------------------------------------
  declare s_dt = vc
  declare e_dt = vc
  declare fisc_year = i4
 
set end_dt_tm = cnvtdatetime($end_dt)
  set beg_dt_tm = cnvtdatetime($beg_dt)
 
;Get the username of the person running the rpt
DECLARE USER_NAME = VC
DECLARE USER = VC
SELECT INTO "NL:"
FROM PRSNL PR
PLAN PR
	WHERE PR.PERSON_ID = REQINFO->UPDT_ID
	AND PR.ACTIVE_IND = 1
	AND PR.END_EFFECTIVE_DT_TM > CNVTDATETIME(CURDATE,CURTIME)
DETAIL
	USER_NAME = PR.NAME_FULL_FORMATTED
	USER = PR.USERNAME
WITH COUNTER
 
DECLARE RPT_TITLE = VC
SET RPT_TITLE = CONCAT("PRIME Base Population")
 
CALL ECHO(RPT_TITLE)
 
DECLARE 18YRS	= DQ8
SET 18YRS = DATETIMEADD(CNVTDATETIME(CURDATE,CURTIME3),-6570)
 
/***************************************************************************************
* Variable and Record Definition													   *
***************************************************************************************/
 
free record pats
record pats(
 
1 patcnt = i4
1 pat[*]
	2 pid = f8
	2 nbr_encs = i4
	2 nbr_encs_v = i4
	2 person_age 		=i2
	2 admit_dt = dq8
	2 disch_dt = dq8
)WITH PROTECT
 
free record rDATA
RECORD rDATA(
	1 PERCNT = I4
	1 PER[*]
		2 PERSON_ID				= F8
		2 NAME					= C200
		2 MRN					= C30
		2 AGE					= C20
		2 SEX					= C20
		2 BIRTH_DATE			= C20
		2 NBR_ENCS				= I2
		2 nbr_encs_v = i2
		2 readmit_enc_cnt =i2
		2 VISIT_TYPES			= C200
		2 DISP					= I2
		2 QUAL_CODE             = C100
		2 PROC_CD				= C50
		2 XRay_desc	            = c200
		2 Any_image             =  c200
		2 PROC_DATE				= C20
 		2 ENCS[*]
			3 ENCNTR_ID			= F8
			3 MRN				= C30
			3 FIN				= C30
			3 LOS				= I2
			3 age_diff			=I2
			3 ADMIT_DATE		= C20
			3 ATTENDING_PHYSICIAN = c200
			3 TRANSFER_INFO = C60
			3 admit_dt_tm = dq8
			3 PREV_ADMIT_DTTM   = dq8
			3 PREV_DC_DTTM   = dq8
			3 DAYS_FR_PREV_ADM = dq8
			3 DISCH_DATE		= C20
			3 DISCH_DATEC		= DQ8
			3 DISCH_DISP		= C40
			3 ENCNTR_TYPE		= C50
			3 deceased_ind = c50
			3 ENC_LOC			= C50
			3 ENC_CNT 			= I4
			3 HPLANS			= C100
			3 PLAN_QUAL			= I2
			3 PHP_ID			= F8
			3 P_MBR_NBR			= VC
			3 PHP_NAME			= C60
			3 SEC_PLAN    = C60
			3 PHP_PLANTYPE		= C30
			3 PHP_TYPE_CD		= F8
			3 PHP_PRISEQ		= I4
			3 SHP_ID			= F8
			3 S_MBR_NBR			= VC
			3 SHP_NAME			= C60
			3 SP_PLANTYPE		= C30
			3 SHP_TYPE_CD		= F8
			3 SHP_PRISEQ		= I4
			3 DISP_VISIT_DX		= I2
			3 DISP_VISIT_CD		= I2
			3 DISP_PROC_CD		= I2
			3 CPT_HCPCS			= C100
			3 PRIN_PROC_CD		= C100
			3 PROC_PRIORITY     = I4
			3 DISCH_DX			= C100
			3 ORG_NAME 			= C40
			3 INDEX_DIAG_CODE = C50
 			3 INDEX_DIANOSIS = C255
  			3 PRIMARY_DISCH_DIAG_CODE = C40
 			3 PRIMARY_DISCH_DIAGNOSIS = C250
 			3 HOSPICE = C50
 			3 SURGERY = C50
 			3 DISCHARGE_CONDITION_CODE = C20
 			3 COMORBID_CATEGORY = C20
 			3 COMORBID_RANKING_GROUP = C200
 			3 COMORBID_RANK =C20
 			3 COMORBID_HCC = c20
 			3 DAYS_DIFF =I2
 			3 RISK_ADJUSTED_WEIGHT  = C20
 			3 OBSERVATION_STAY_WEIGHT  =C20
 			3 SURGICAL_WEIGHT = C20
 			3 DISCHARGE_CC_WEIGHT  = C20
 			3 HCC_WEIGHT = C20
			3 PROCS[*]
				4 PROCEDURE_PRI = I4
				4 PROC_NAME 	= C100
				4 SRC_VOCAB 	= C30
)WITH PROTECT
 
 
 
 
DECLARE cvEDVISITCLASS 	= F8 WITH CONSTANT(UAR_GET_CODE_BY("DISPLAY_KEY",69,"EMERGENCY"))
DECLARE cvOBSVISITCLASS 	= F8 WITH CONSTANT(UAR_GET_CODE_BY("DISPLAY_KEY",69,"OBSERVATION"))
DECLARE cvOPVISITCLASS 	= F8 WITH CONSTANT(UAR_GET_CODE_BY("DISPLAY_KEY",69,"OUTPATIENT"))
 
 
 
 
DECLARE cvSNOMEDCT 		= F8 WITH CONSTANT(UAR_GET_CODE_BY("DISPLAY_KEY",400,"SNOMEDCT"))
DECLARE cvICD9CM		= F8 WITH CONSTANT(UAR_GET_CODE_BY("DISPLAY_KEY",400,"ICD9CM"))
DECLARE cvPHARM_CAT		= F8 WITH CONSTANT(UAR_GET_CODE_BY("DISPLAY_KEY",6000,"PHARMACY"))
DECLARE cvPHARM_ACT		= F8 WITH CONSTANT(UAR_GET_CODE_BY("DISPLAY_KEY",106,"PHARMACY"))
DECLARE cvPATCARE_CAT	= F8 WITH CONSTANT(UAR_GET_CODE_BY("DISPLAY_KEY",6000,"PATIENTCARE"))
DECLARE cvPATCARE_ACT	= F8 WITH CONSTANT(UAR_GET_CODE_BY("DISPLAY_KEY",106,"PATIENTCARE"))
 
DECLARE cvFINAL			= F8 WITH CONSTANT(UAR_GET_CODE_BY("DISPLAY_KEY",17,"FINAL"))
DECLARE cvDISCH			= F8 WITH CONSTANT(UAR_GET_CODE_BY("DISPLAY_KEY",17,"DISCHARGE"))
 
 
DECLARE cvPRIMARY		= F8 WITH CONSTANT(UAR_GET_CODE_BY("DISPLAY_KEY",12034,"PRIMARY"))
DECLARE cvREPORTING		= F8 WITH CONSTANT(UAR_GET_CODE_BY("DISPLAY_KEY",12033,"REPORTING"))
DECLARE cvELECTIVE		= F8 WITH CONSTANT(UAR_GET_CODE_BY("DISPLAY_KEY",1304,"ELECTIVE"))
DECLARE cvCONTRAIND		= F8 WITH CONSTANT(UAR_GET_CODE_BY("DISPLAY_KEY",200,"CONTRAINDICATIONSTOANTICOAGULANTS"))
DECLARE cvCOMFORT		= F8 WITH CONSTANT(UAR_GET_CODE_BY("DISPLAY_KEY",200,"COMFORTMEASURESCOMFORTCARE"))
DECLARE cvCAROTID		= F8 WITH CONSTANT(UAR_GET_CODE_BY("DISPLAY_KEY",200,"CAROTIDENDARTERECTOMY"))
DECLARE cvORDERED		= F8 WITH CONSTANT(UAR_GET_CODE_BY("DISPLAY_KEY",6004,"ORDERED"))
DECLARE cvACTIVE_PR		= F8 WITH CONSTANT(UAR_GET_CODE_BY("DISPLAY_KEY",12030,"ACTIVE"))
DECLARE cvRESOLVED_PR	= F8 WITH CONSTANT(UAR_GET_CODE_BY("DISPLAY_KEY",12030,"RESOLVED"))
DECLARE cvFIN_NBR		= F8 WITH CONSTANT(UAR_GET_CODE_BY("DISPLAY_KEY",319,"FINNBR"))
DECLARE cvMRN			= F8 WITH CONSTANT(UAR_GET_CODE_BY("DISPLAY_KEY",319,"MRN"))
DECLARE cvCOMPLETE		= F8 WITH CONSTANT(UAR_GET_CODE_BY("DISPLAY_KEY",79,"COMPLETE"))
DECLARE cvNOT_DONE		= F8 WITH CONSTANT(UAR_GET_CODE_BY("DISPLAY_KEY",79,"TASKCHARTEDASNOTDONE"))
DECLARE cvDEATH_YES		= F8 WITH CONSTANT(UAR_GET_CODE_BY("DISPLAY_KEY",268,"YES"))
DECLARE cvMECH_REASON_FORM	= F8 WITH CONSTANT(UAR_GET_CODE_BY("DISPLAY_KEY",14003,"REASONNOVTEPROPHYLAXISMECHANICAL"))
DECLARE cvPHARM_REASON_FORM	= F8 WITH CONSTANT(UAR_GET_CODE_BY("DISPLAY_KEY",14003,"REASONNOVTEPROPHYLAXISPHARM"))
 
declare PHARM_CD					= f8  with constant(uar_get_code_by("DISPLAYKEY", 6000, "PHARMACY"))
declare ORDERED_cv					= f8  with constant(uar_get_code_by("DISPLAYKEY", 6004, "ORDERED"))
declare DISCONTD_cv					= f8  with constant(uar_get_code_by("DISPLAYKEY", 6004, "DISCONTINUED"))
declare COMPLETED_cv				= f8  with constant(uar_get_code_by("DISPLAYKEY", 6004, "COMPLETED"))
declare CANCELED_cv					= f8  with constant(uar_get_code_by("DISPLAYKEY", 6004, "CANCELED"))
 
declare dsORDERED_cv				= f8  with constant(uar_get_code_by("DISPLAYKEY", 14281, "ORDERED"))
declare dsDISCONTD_cv				= f8  with constant(uar_get_code_by("DISPLAYKEY", 14281, "DISCONTINUED"))
declare dsCOMPLETED_cv				= f8  with constant(uar_get_code_by("DISPLAYKEY", 14281, "COMPLETED"))
 
declare POTASSIUM_cv	= f8  with constant(uar_get_code_by("DISPLAYKEY", 72, "POTASSIUM"))
declare SERUM_CREAT_cv	= f8  with constant(uar_get_code_by("DISPLAYKEY", 72, "CREATININE"))
 
declare NUM = i4 with noconstant(0)
declare POS = i4 with noconstant(0)
 
 
 
SELECT INTO "NL:"
 
FROM ENCOUNTER E
	,PERSON P
 
PLAN E WHERE  E.DISCH_DT_TM+0 BETWEEN ; CNVTDATETIME(S_DT) AND CNVTDATETIME(E_DT)
;CNVTDATETIME(cnvtdate(01012020),0) AND CNVTDATETIME(cnvtdate(12312020),2359)
cnvtdatetime(beg_dt_tm) and cnvtdatetime(end_dt_tm)
 ; e.person_id=12561725.00
	  and e.active_ind = 1
	    and e.encntr_type_cd in ( ;309310.00; Emergency
                                309308.00; Inpatient
                                ,309312.00; Observation
                                ;19962820.00; Outpatient in a Bed
                                )
JOIN P WHERE P.PERSON_ID = E.PERSON_ID
;and DATETIMEDIFF(e.reg_dt_tm,p.birth_dt_tm) >= 18; and DATETIMEDIFF(e.reg_dt_tm,p.birth_dt_tm) <= 64
;and p.person_id=   12837219.00
 
 
ORDER BY P.PERSON_ID , e.encntr_id
;002 ends
 
head report
 cnt = 0
head p.person_id
 cnt += 1, stat = alterlist(pats->pat, cnt)
 
 pats->pat[cnt].pid = p.person_id
 
head e.encntr_id
pats->pat[cnt].admit_dt =E.reg_dt_tm
pats->pat[cnt].disch_dt = e.disch_dt_tm
;IF( DATETIMEDIFF(pats->pat[cnt].disch_dt, pats->pat[cnt-1].admit_dt) <=30)
 pats->pat[cnt].nbr_encs += 1
 ;ENDIF
with nocounter
 
 
 ;002 begins
 
 SELECT INTO "NL:"
 
reg_dt = format(e.reg_dt_tm,"mm/dd/yy;;q")
 
FROM(DUMMYT D1 WITH SEQ = SIZE(pats->pat, 5))
	,ENCOUNTER E
	,PERSON P
	,encntr_alias ea
 
 
PLAN D1
JOIN E	WHERE
 E.REG_DT_TM BETWEEN
;CNVTDATETIME(cnvtdate(01012020),0) AND CNVTDATETIME(cnvtdate(12312020),2359)
cnvtdatetime(beg_dt_tm) and cnvtdatetime(end_dt_tm)
;CNVTDATETIME(S_DT) AND CNVTDATETIME(format(datetimefind(cnvtdatetime(cnvtdate(end_date),00),"Y","E","B"),"31-mmm-yyyy hh:mm:ss;;d"))
 
          AND e.person_id =   pats->pat[d1.seq].pid
          AND E.ACTIVE_IND = 1
          and e.encntr_type_cd in (; 309310.00; Emergency
                                309308.00; Inpatient
                                ,309312.00; Observation
                             ;   ,19962820.00; Outpatient in a Bed
                                )
 
JOIN P
	WHERE P.PERSON_ID = E.PERSON_ID
 ;and DATETIMEDIFF(e.reg_dt_tm,p.birth_dt_tm) >= 18; and DATETIMEDIFF(e.reg_dt_tm,p.birth_dt_tm) <= 64
; and p.person_id=   12837219.00
join ea
where ea.encntr_id = e.encntr_id
and ea.encntr_alias_type_cd in (1077,1079)
and ea.active_ind=1
ORDER BY P.PERSON_ID,  E.ENCNTR_ID,e.reg_dt_tm ;, EPR.PRIORITY_SEQ
;002 ends
 
 
HEAD REPORT
	PCNT = 0
	ECNT = 0
 
HEAD P.PERSON_ID
 
	PCNT = PCNT + 1
	if(mod(PCNT, 10) = 1)
		STAT = ALTERLIST(rDATA->PER,PCNT + 9)
	endif
 pats->pat[Pcnt].pid = p.person_id
	rDATA->PER[PCNT].PERSON_ID		= P.PERSON_ID
	rDATA->PER[PCNT].NAME			= P.NAME_FULL_FORMATTED
	rDATA->PER[PCNT].BIRTH_DATE		= FORMAT(P.BIRTH_DT_TM,"MM/DD/YYYY;;D")
	rDATA->PER[PCNT].AGE			= TRIM(CNVTAGE(P.BIRTH_DT_TM))
    rDATA->PER[PCNT].SEX	= UAR_GET_CODE_DISPLAY(P.sex_cd)
	ECNT = 0
	HCNT = 0
 
HEAD E.ENCNTR_ID
 
	ECNT = ECNT + 1
	if(mod(ECNT, 10) = 1)
		STAT = ALTERLIST(rDATA->PER[PCNT].ENCS,ECNT+9)
 	endif
 	rDATA->PER[PCNT].nbr_encs_v  =0
 ;	rDATA->PER[PCNT].ENCS[ECNT].admit_dt_tm			= e.reg_dt_tm
 
rDATA->PER[PCNT].ENCS[ECNT].age_diff = DATETIMEDIFF(e.reg_dt_tm,p.birth_dt_tm)/365
 if (p.sex_cd =362);Female
  if (rDATA->PER[PCNT].ENCS[ECNT].age_diff  >=18 and rDATA->PER[PCNT].ENCS[ECNT].age_diff  <=44)
 	rDATA->PER[PCNT].ENCS[ECNT].RISK_ADJUSTED_WEIGHT=	"-2.7841"
  endif
  if (rDATA->PER[PCNT].ENCS[ECNT].age_diff  >44  and rDATA->PER[PCNT].ENCS[ECNT].age_diff  <=54)
 	rDATA->PER[PCNT].ENCS[ECNT].RISK_ADJUSTED_WEIGHT=	"-2.7211"
  endif
   if (rDATA->PER[PCNT].ENCS[ECNT].age_diff  >54 and rDATA->PER[PCNT].ENCS[ECNT].age_diff  <=64 )
 	rDATA->PER[PCNT].ENCS[ECNT].RISK_ADJUSTED_WEIGHT=	"-2.6547"
  endif
 endif
 
 if (p.sex_cd=363);Male
  if (rDATA->PER[PCNT].ENCS[ECNT].age_diff  >=18 and rDATA->PER[PCNT].ENCS[ECNT].age_diff  <=44)
 	rDATA->PER[PCNT].ENCS[ECNT].RISK_ADJUSTED_WEIGHT=	"-2.6788"
  endif
   if (rDATA->PER[PCNT].ENCS[ECNT].age_diff  >44  and rDATA->PER[PCNT].ENCS[ECNT].age_diff  <=54)
 	rDATA->PER[PCNT].ENCS[ECNT].RISK_ADJUSTED_WEIGHT=	"-2.6552"
  endif
   if (rDATA->PER[PCNT].ENCS[ECNT].age_diff  >54 and rDATA->PER[PCNT].ENCS[ECNT].age_diff  <=64 )
 	rDATA->PER[PCNT].ENCS[ECNT].RISK_ADJUSTED_WEIGHT=	"-2.5792"
  endif
 endif
 
 if (e.encntr_type_cd= 309312.00);	Observation)
 rDATA->PER[PCNT].ENCS[ECNT].OBSERVATION_STAY_WEIGHT=	"-0.0337"
 endif
 
	rDATA->PER[PCNT].ENCS[ECNT].ENCNTR_ID			= E.ENCNTR_ID
	rDATA->PER[PCNT].ENCS[ECNT].deceased_ind			= uar_get_code_display(p.deceased_cd)
	rDATA->PER[PCNT].ENCS[ECNT].FIN					= EA.ALIAS
	rDATA->PER[PCNT].ENCS[ECNT].ADMIT_DATE			=FORMAT(E.REG_DT_TM,"dd-mmm-yyyy hh:mm:ss;;d")
	rDATA->PER[PCNT].ENCS[ECNT].admit_dt_tm			= e.reg_dt_tm
	rDATA->PER[PCNT].ENCS[ECNT].DISCH_DATE			= FORMAT(E.DISCH_DT_TM,"dd-mmm-yyyy hh:mm:ss;;d")
	rDATA->PER[PCNT].ENCS[ECNT].DISCH_DATEC			= E.DISCH_DT_TM
	rDATA->PER[PCNT].ENCS[ECNT].DISCH_DISP			= UAR_GET_CODE_DISPLAY(E.DISCH_DISPOSITION_CD)
	rDATA->PER[PCNT].ENCS[ECNT].LOS					= DATETIMEDIFF(E.DISCH_DT_TM,E.REG_DT_TM)
	rDATA->PER[PCNT].ENCS[ECNT].DAYS_DIFF= DATETIMEDIFF(rDATA->PER[PCNT].ENCS[ECNT].admit_dt_tm,rDATA->PER[PCNT].ENCS[ECNT-1].DISCH_DATEC)
 
;	rDATA->PER[PCNT].ENCS[ECNT].FIN_CLASS			= TRIM(UAR_GET_CODE_DISPLAY(E.FINANCIAL_CLASS_CD))
	rDATA->PER[PCNT].ENCS[ECNT].ENCNTR_TYPE			= TRIM(UAR_GET_CODE_DISPLAY(E.ENCNTR_TYPE_CD))
	rDATA->PER[PCNT].ENCS[ECNT].ORG_NAME			= TRIM(UAR_GET_CODE_DISPLAY(E.loc_facility_cd))
;	rDATA->PER[PCNT].ENCS[ECNT].ENCNTR_TYPEc		= E.ENCNTR_TYPE_CD
	;rDATA->PER[PCNT].ENCS[ECNT].ENCNTR_TYPE_CLASS	= TRIM(UAR_GET_CODE_DISPLAY(E.ENCNTR_TYPE_CLASS_CD))
;	rDATA->PER[PCNT].ENCS[ECNT].ENCNTR_TYPE_CLASSc	= E.ENCNTR_TYPE_CLASS_CD
	rDATA->PER[PCNT].ENCS[ECNT].ENC_LOC				= BUILD(UAR_GET_CODE_DISPLAY(E.LOC_FACILITY_CD),"-",
															 UAR_GET_CODE_DISPLAY(E.LOC_NURSE_UNIT_CD))
;
;
	rDATA->PER[PCNT].VISIT_TYPES = CONCAT(TRIM( UAR_GET_CODE_DISPLAY(E.ENCNTR_TYPE_CD))," ",reg_dt, " - ",
															rDATA->PER[PCNT].VISIT_TYPES)
 
	;rDATA->PER[PCNT].ENCS[ECNT].DISCH_DX = BUILD(NOM.SOURCE_IDENTIFIER,"-",NOM.SOURCE_STRING) ;,"-",NOM.SOURCE_VOCABULARY_CD)
 
DETAIL
 
	if(ea.ENCNTR_ALIAS_TYPE_CD =1077)
 
			rDATA->PER[PCNT].ENCS[ECNT].FIN = EA.ALIAS
		endif
		if (ea.ENCNTR_ALIAS_TYPE_CD =1079)
			rDATA->PER[PCNT].ENCS[ECNT].MRN = EA.ALIAS
 
endif
 
FOOT P.PERSON_ID
 	;if (	rDATA->PER[PCNT].ENCS[ECNT].DAYS_DIFF<= 30)
	rDATA->PER[PCNT].NBR_ENCS =  pats->pat[d1.seq].nbr_encs
	rDATA->PER[PCNT].nbr_encs_v =  pats->pat[d1.seq].nbr_encs_v
	STAT = ALTERLIST(rDATA->PER[PCNT].ENCS,ECNT)
 ;endif
FOOT REPORT
 
 	rDATA->PERCNT = PCNT
	STAT = ALTERLIST(rDATA->PER,PCNT)
 
WITH NOCOUNTER
 
;;------------------------------------------------------------------------------------
;;--     GET HEALTH PLAN INFORMATION   ----------------------------------------------
;;------------------------------------------------------------------------------------
SELECT
  PERSON_ID = RDATA->PER[D1.SEQ].PERSON_ID
, ENCNTR_ID = RDATA->PER[D1.SEQ].ENCS[D2.SEQ].ENCNTR_ID
 
FROM
	  (DUMMYT   D1  WITH SEQ = VALUE(SIZE(RDATA->PER, 5)))
	, (DUMMYT   D2  WITH SEQ = 1)
	, ENCNTR_PLAN_RELTN epr
	, HEALTH_PLAN hp
 
PLAN D1 WHERE MAXREC(D2, SIZE(RDATA->PER[D1.SEQ].ENCS, 5))
 
JOIN D2
JOIN EPR where EPR.encntr_id = RDATA->PER[D1.SEQ].ENCS[D2.SEQ].ENCNTR_ID
           and EPR.person_id = RDATA->PER[D1.SEQ].PERSON_ID
           and EPR.ACTIVE_IND = 1
	       AND EPR.PRIORITY_SEQ IN (1,2)
	       AND EPR.END_EFFECTIVE_DT_TM > SYSDATE
 
JOIN HP WHERE HP.HEALTH_PLAN_ID = EPR.HEALTH_PLAN_ID
	      AND HP.ACTIVE_IND = 1
 
order by epr.person_id, epr.encntr_id, epr.priority_seq
 
head epr.person_id
 row + 0
;head epr.encntr_id
detail
	rDATA->PER[d1.seq].ENCS[d2.seq].P_MBR_NBR		=	EPR.MEMBER_NBR
	if (epr.priority_seq=1)
		rDATA->PER[d1.seq].ENCS[d2.seq].PHP_NAME		=	HP.PLAN_NAME
		else
 
		rDATA->PER[d1.seq].ENCS[d2.seq].SEC_PLAN		=	HP.PLAN_NAME
	endif
	rDATA->PER[d1.seq].ENCS[d2.seq].PHP_PLANTYPE	=	UAR_GET_CODE_DISPLAY(HP.PLAN_TYPE_CD)
	rDATA->PER[d1.seq].ENCS[d2.seq].PHP_TYPE_CD		=	HP.PLAN_TYPE_CD
WITH NOCOUNTER
 
 
 ;;------------------------------------------------------------------------------------
;;--     GET transfer INFORMATION   ----------------------------------------------
;;------------------------------------------------------------------------------------
SELECT
  PERSON_ID = RDATA->PER[D1.SEQ].PERSON_ID
, ENCNTR_ID = RDATA->PER[D1.SEQ].ENCS[D2.SEQ].ENCNTR_ID
 
FROM
	  (DUMMYT   D1  WITH SEQ = VALUE(SIZE(RDATA->PER, 5)))
	, (DUMMYT   D2  WITH SEQ = 1)
	, clinical_EVENT  CE
 
 
PLAN D1 WHERE MAXREC(D2, SIZE(RDATA->PER[D1.SEQ].ENCS, 5))
 
JOIN D2
JOIN CE where CE.encntr_id = RDATA->PER[D1.SEQ].ENCS[D2.SEQ].ENCNTR_ID
           and CE.person_id = RDATA->PER[D1.SEQ].PERSON_ID
           and CE.event_cd =   30690319.00
	      AND CE.valid_until_dt_tm>SYSDATE
 
 
 
head CE.person_id
 row + 0
head CE.encntr_id
	rDATA->PER[d1.seq].ENCS[d2.seq].TRANSFER_INFO		=	CE.event_title_text
 
WITH NOCOUNTER,maxrec=1
 
 
;;------------------------------------------------------------------------------------
;;--     GET ATTENDING PHYSICIAN INFORMATION   ----------------------------------------------
;;------------------------------------------------------------------------------------
SELECT
  ;PERSON_ID = RDATA->PER[D1.SEQ].PERSON_ID
 ENCNTR_ID = RDATA->PER[D1.SEQ].ENCS[D2.SEQ].ENCNTR_ID
 
FROM
	  (DUMMYT   D1  WITH SEQ = VALUE(SIZE(RDATA->PER, 5)))
	, (DUMMYT   D2  WITH SEQ = 1)
	, ENCNTR_PRSNL_RELTN epr
	, PRSNL hp
 
PLAN D1 WHERE MAXREC(D2, SIZE(RDATA->PER[D1.SEQ].ENCS, 5))
 
JOIN D2
JOIN EPR where EPR.encntr_id = RDATA->PER[D1.SEQ].ENCS[D2.SEQ].ENCNTR_ID
          ; and EPR.person_id = RDATA->PER[D1.SEQ].PERSON_ID
           and EPR.ACTIVE_IND = 1
	       AND EPR.PRIORITY_SEQ IN (1)
	       AND EPR.END_EFFECTIVE_DT_TM > SYSDATE
 
JOIN HP WHERE HP.person_id = EPR.prsnl_person_id
	      AND HP.ACTIVE_IND = 1
 
order by epr.prsnl_person_id, epr.encntr_id
 
head epr.prsnl_person_id
 row + 0
head epr.encntr_id
	rDATA->PER[d1.seq].ENCS[d2.seq].ATTENDING_PHYSICIAN		=	HP.name_full_formatted
 
WITH NOCOUNTER
 
 ;******************************************************************************
;  Check for hospice
;******************************************************************************
 /*
SELECT INTO "NL:"
	cpt = cm2.field6
	, hcpcs = cm3.field6
FROM
	(DUMMYT   D1  WITH SEQ = SIZE(RDATA->PER, 5))
	, (DUMMYT   D2  WITH SEQ = 1)
	, encounter e
	, pft_encntr pft
	, pft_charge pftc
	, charge c
	;, charge_mod cm ;cdm
	, charge_mod cm2;cpt
	, charge_mod cm3;hcpcs
 
PLAN D1 WHERE MAXREC(D2, SIZE(RDATA->PER[D1.SEQ].ENCS, 5))
 
JOIN D2
 
JOIN E where e.encntr_id = rdata->PER[d1.seq].ENCS[d2.seq].ENCNTR_ID
 
JOIN pft where pft.encntr_id = e.encntr_id
 
join pftc where pftc.pft_encntr_id = pft.pft_encntr_id
	and pftc.active_ind = 1
 
join c where c.charge_item_id = pftc.charge_item_id
	and c.active_ind = 1
 
;join cm where cm.charge_item_id = c.charge_item_id
;	and cm.field1_id = 667687.00;cdm
;	and cm.active_ind = 1
;	and cm.field2_id = 1
 
join cm2 where cm2.charge_item_id = outerjoin(c.charge_item_id)
	and cm2.field1_id = outerjoin(615214.00);cpt
	and cm2.active_ind = outerjoin(1)
	and cm2.field2_id = outerjoin(1)
 
join cm3 where cm3.charge_item_id = outerjoin(c.charge_item_id)
	and cm3.field1_id = outerjoin(615215.00);hcpcs
	and cm3.active_ind = outerjoin(1)
	and cm3.field2_id = outerjoin(1)
 
DETAIL
 	if(cm2.field1_id =615214)
 		rDATA->PER[D1.SEQ].ENCS[d2.seq].HOSPICE = BUILD("CPT: ",trim(cm2.field6),"*"
 					,rDATA->PER[D1.SEQ].ENCS[d2.seq].HOSPICE)*/
 
 	/*elseif(hcpcs in ('G9473','G9474','G9475','G9476','G9477','G9478', 'G9479',
											'Q5003','Q5004','Q5005','Q5006','Q5007','Q5008','Q5010','S9126'
											,'T2042','T2043','T2044','T2045','T2046'))*/
/*	elseif (cm3.field1_id=615215)
	rDATA->PER[D1.SEQ].ENCS[d2.seq].HOSPICE = BUILD("HCPCS: ",trim(cm3.field6),"*"
					,rDATA->PER[D1.SEQ].ENCS[d2.seq].HOSPICE)
	endif
 
WITH NOCOUNTER, TIME = 1800
 */
 
 
 SELECT INTO "NL:"
	cpt = cm2.field6
	, hcpcs = cm3.field6
	,rev =cm.field6
FROM
	(DUMMYT   D1  WITH SEQ = SIZE(RDATA->PER, 5))
	, (DUMMYT   D2  WITH SEQ = 1)
	, encounter e
	, pft_encntr pft
	, pft_charge pftc
	, charge c
	, charge_mod cm ;rev
	, charge_mod cm2;cpt
	, charge_mod cm3;hcpcs
 
PLAN D1  WHERE MAXREC(D2, SIZE(RDATA->PER[D1.SEQ].ENCS, 5))
 
JOIN D2
JOIN E where e.encntr_id = rdata->PER[d1.seq].ENCS[d2.seq].ENCNTR_ID
 
JOIN pft where pft.encntr_id = e.encntr_id
 
join pftc where pftc.pft_encntr_id = pft.pft_encntr_id
	and pftc.active_ind = 1
 
join c where c.charge_item_id = pftc.charge_item_id
	and c.active_ind = 1
 
join cm where cm.charge_item_id = c.charge_item_id
	and cm.field1_id =      615217.00;rev
	and cm.active_ind = 1
	and cm.field2_id = 1
 
join cm2 where cm2.charge_item_id = outerjoin(c.charge_item_id)
	and cm2.field1_id = outerjoin(615214.00);cpt
	and cm2.active_ind = outerjoin(1)
	and cm2.field2_id = outerjoin(1)
 
join cm3 where cm3.charge_item_id = outerjoin(c.charge_item_id)
	and cm3.field1_id = outerjoin(615215.00);hcpcs
	and cm3.active_ind = outerjoin(1)
	and cm3.field2_id = outerjoin(1)
 
DETAIL
 	if(cpt in ('99377', '99378'))
 		rDATA->PER[D1.SEQ].ENCS[d2.seq].HOSPICE= BUILD("CPT: ",trim(cpt),"*",rDATA->PER[D1.SEQ].ENCS[d2.seq].HOSPICE)
 	elseif(hcpcs in (
"G0182"
,"T2045"
))
		rDATA->PER[D1.SEQ].ENCS[d2.seq].HOSPICE = BUILD("HCPCS: ",trim(hcpcs),"*",rDATA->PER[D1.SEQ].ENCS[d2.seq].HOSPICE)
		elseif(rev in (
"0115"
,"0125"
,"0135"
,"0145"
,"0155"
,"0235"
,"0650"
,"0651"
,"0652"
,"0655"
,"0656"
,"0656"
,"0657"
,"0658"
,"0659"
))
		rDATA->PER[D1.SEQ].ENCS[d2.seq].HOSPICE = BUILD("REV: ",trim(rev),"*",rDATA->PER[D1.SEQ].ENCS[d2.seq].HOSPICE)
	endif
 
WITH NOCOUNTER, TIME = 1800
;******************************************************************************
;  Check for surgery
;******************************************************************************
 
SELECT INTO "NL:"
FROM
	(DUMMYT   D1  WITH SEQ = SIZE(RDATA->PER, 5))
	, (DUMMYT   D2  WITH SEQ = 1)
	, PROCEDURE P
 
PLAN D1 WHERE MAXREC(D2, SIZE(RDATA->PER[D1.SEQ].ENCS, 5))
 
JOIN D2
 
JOIN P where p.encntr_id = rdata->PER[d1.seq].ENCS[d2.seq].ENCNTR_ID
 	and p.active_ind = 1
 	and p.contributor_system_cd = 23648835 ; SurgiNet
DETAIL
	rDATA->PER[D1.SEQ].ENCS[d2.seq].SURGERY = 'Y'
	rDATA->PER[D1.SEQ].ENCS[d2.seq].SURGICAL_WEIGHT ="-0.1251"
 
WITH NOCOUNTER, TIME = 1800
 
 
 
;------------------------------------------------------------------------------------
;--     QUALIFYING DIAGNOSIS           ----------------------------------------------
;------------------------------------------------------------------------------------
 
SELECT INTO "NL:"
FROM
 	(DUMMYT   D1  WITH SEQ = VALUE(SIZE(RDATA->PER, 5))) ,
	(DUMMYT   D2  WITH SEQ = 1) ,
	DIAGNOSIS DX ,
	NOMENCLATURE NOM
 
PLAN D1
	WHERE MAXREC(D2, SIZE(RDATA->PER[D1.SEQ].ENCS, 5))
 
JOIN D2
 
JOIN DX
	WHERE DX.ENCNTR_ID = RDATA->PER[D1.SEQ].ENCS[D2.SEQ].ENCNTR_ID
	AND DX.ACTIVE_IND = 1
	AND DX.END_EFFECTIVE_DT_TM > SYSDATE
   AND DX.diag_type_cd IN (89,88)
  and( dx.clinical_diag_priority = 1 or dx.diag_priority=1)
JOIN NOM
	WHERE NOM.NOMENCLATURE_ID = DX.NOMENCLATURE_ID
	AND NOM.ACTIVE_IND = 1
	and nom.principle_type_cd=1252; Disease or Syndrome
 
 
ORDER BY DX.ENCNTR_ID
 
HEAD REPORT
NULL
 
DETAIL
 IF (DX.diag_type_cd=89)
	RDATA->PER[D1.SEQ].ENCS[D2.SEQ].INDEX_DIAG_CODE = trim(NOM.SOURCE_IDENTIFIER,0)
	rDATA->PER[d1.seq].ENCS[d2.seq].INDEX_DIANOSIS=trim(NOM.SOURCE_STRING,0)
 ELSE
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].PRIMARY_DISCH_DIAG_CODE= trim(NOM.SOURCE_IDENTIFIER,0)
	rDATA->PER[d1.seq].ENCS[d2.seq].PRIMARY_DISCH_DIAGNOSIS=trim(NOM.SOURCE_STRING,0)
 
 ENDIF
 if (dx.diag_type_cd=88)
 if (nom.source_identifier in (
"B20","B9735","Z21"
))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].DISCHARGE_CONDITION_CODE ="CC-1"
endif
 
if (nom.source_identifier in (
"C4000","C4001","C4002","C4010","C4011","C4012","C4020","C4021","C4022","C4030" ,"C4031","C4032","C4080","C4081","C4082","C4090" ,"C4091","C4092","C410","C411","C412","C413","C414","C419","C460" ,"C461" ,"C462" ,"C463" ,"C464" ,"C4650" ,"C4651" ,"C4652" ,"C467" ,"C469" ,"C470" ,"C4710" ,"C4711" ,"C4712" ,"C4720" ,"C4721" ,"C4722" ,"C473" ,"C474" ,"C475" ,"C476" ,"C478" ,"C479" ,"C490" ,"C4910" ,"C4911" ,"C4912" ,"C4920" ,"C4921" ,"C4922" ,"C493" ,"C494" ,"C495" ,"C496" ,"C498" ,"C499" ,"C49A0" ,"C49A1" ,"C49A2" ,"C49A3" ,"C49A4" ,"C49A5" ,"C49A9" ,"C561" ,"C562" ,"C569" ,"C5700" ,"C5701" ,"C5702" ,"C5710" ,"C5711" ,"C5712" ,"C5720" ,"C5721" ,"C5722" ,"C573" ,"C574" ,"C58" ,"C700" ,"C701" ,"C709" ,"C710" ,"C711" ,"C712" ,"C713" ,"C714" ,"C715" ,"C716" ,"C717" ,"C718" ,"C719" ,"C720" ,"C721" ,"C7220" ,"C7221" ,"C7222" ,"C7230" ,"C7231" ,"C7232" ,"C7240" ,"C7241" ,"C7242" ,"C7250" ,"C7259" ,"C729" ,"C7400" ,"C7401" ,"C7402" ,"C7410" ,"C7411" ,"C7412" ,"C7490" ,"C7491" ,"C7492" ,"C751"
 ,"C752" ,"C753" ,"C773" ,"C779" ,"C792" ,"C7981" ,"C7982" ,"C8100" ,"C8101" ,"C8102" ,"C8103" ,"C8104" ,"C8105" ,"C8106" ,"C8107" ,"C8108" ,"C8109" ,"C8110" ,"C8111" ,"C8112" ,"C8113" ,"C8114" ,"C8115" ,"C8116" ,"C8117" ,"C8118" ,"C8119" ,"C8120" ,"C8121" ,"C8122" ,"C8123" ,"C8124" ,"C8125" ,"C8126" ,"C8127" ,"C8128" ,"C8129" ,"C8130" ,"C8131" ,"C8132" ,"C8133" ,"C8134" ,"C8135" ,"C8136" ,"C8137" ,"C8138" ,"C8139" ,"C8140" ,"C8141" ,"C8142" ,"C8143" ,"C8144" ,"C8145" ,"C8146" ,"C8147" ,"C8148" ,"C8149" ,"C8170" ,"C8171" ,"C8172" ,"C8173" ,"C8174" ,"C8175" ,"C8176" ,"C8177" ,"C8178" ,"C8179" ,"C8190" ,"C8191" ,"C8192" ,"C8193" ,"C8194" ,"C8195" ,"C8196" ,"C8197" ,"C8198" ,"C8199" ,"C8200" ,"C8201" ,"C8202" ,"C8203" ,"C8204" ,"C8205" ,"C8206" ,"C8207" ,"C8208" ,"C8209" ,"C8210" ,"C8211" ,"C8212" ,"C8213" ,"C8214" ,"C8215" ,"C8216" ,"C8217" ,"C8218" ,"C8219" ,"C8220" ,"C8221" ,"C8222" ,"C8223" ,"C8224" ,"C8225" ,"C8226" ,"C8227" ,"C8228" ,"C8229" ,"C8230" ,"C8231" ,"C8232" ,"C8233"
  ,"C8234"
,"C8235" ,"C8236" ,"C8237" ,"C8238" ,"C8239" ,"C8240" ,"C8241" ,"C8242" ,"C8243" ,"C8244" ,"C8245" ,"C8246" ,"C8247" ,"C8248" ,
"C8249" ,"C8250" ,"C8251" ,"C8252" ,"C8253" ,"C8254" ,"C8255" ,"C8256" ,"C8257" ,"C8258" ,"C8259" ,"C8260" ,"C8261" ,"C8262" ,"C8263" ,"C8264" ,"C8265" ,"C8266" ,"C8267" ,"C8268" ,"C8269" ,"C8280" ,"C8281" ,"C8282" ,"C8283" ,"C8284" ,"C8285" ,"C8286" ,"C8287" ,"C8288" ,"C8289" ,"C8290" ,"C8291" ,"C8292" ,"C8293" ,"C8294" ,"C8295" ,"C8296" ,"C8297" ,"C8298" ,"C8299" ,"C8300" ,"C8301" ,"C8302" ,"C8303" ,"C8304" ,"C8305" ,"C8306" ,"C8307" ,"C8308" ,"C8309" ,"C8310" ,"C8311" ,"C8312" ,"C8313" ,"C8314" ,"C8315" ,"C8316" ,"C8317" ,"C8318" ,"C8319" ,"C8330" ,"C8331" ,"C8332" ,"C8333" ,"C8334" ,"C8335" ,"C8336" ,"C8337" ,"C8338" ,"C8339" ,"C8350" ,"C8351" ,"C8352" ,"C8353" ,"C8354" ,"C8355" ,"C8356" ,"C8357" ,"C8358" ,"C8359" ,"C8370" ,"C8371" ,"C8372" ,"C8373" ,"C8374" ,"C8375" ,"C8376" ,"C8377" ,"C8378" ,"C8379" ,"C8380" ,"C8381" ,"C8382" ,"C8383" ,"C8384" ,"C8385" ,
"C8386" ,"C8387" ,"C8388" ,"C8389" ,"C8390" ,"C8391" ,"C8392" ,"C8393" ,"C8394" ,"C8395" ,"C8396" ,"C8397" ,"C8398" ,"C8399" ,"C8400" ,"C8401" ,"C8402" ,"C8403" ,"C8404" ,"C8405" ,"C8406" ,"C8407" ,"C8408" ,"C8409" ,"C8410" ,"C8411" ,"C8412" ,"C8413" ,"C8414" ,"C8415" ,"C8416" ,"C8417" ,"C8418" ,"C8419" ,"C8440" ,"C8441" ,"C8442" ,"C8443" ,"C8444" ,"C8445" ,"C8446" ,"C8447" ,"C8448" ,"C8449" ,"C8460" ,"C8461" ,"C8462" ,"C8463" ,"C8464" ,"C8465" ,"C8466" ,"C8467" ,"C8468" ,"C8469" ,"C8470" ,"C8471" ,"C8472" ,"C8473" ,"C8474" ,"C8475" ,"C8476" ,"C8477" ,"C8478" ,"C8479" ,"C8490" ,"C8491" ,"C8492" ,"C8493" ,"C8494" ,"C8495" ,"C8496" ,"C8497" ,"C8498" ,"C8499" ,"C84A0" ,"C84A1" ,"C84A2" ,"C84A3" ,"C84A4" ,"C84A5" ,"C84A6" ,"C84A7" ,"C84A8" ,"C84A9" ,"C84Z0" ,"C84Z1" ,"C84Z2" ,"C84Z3" ,"C84Z4" ,"C84Z5" ,"C84Z6" ,"C84Z7" ,"C84Z8" ,"C84Z9" ,"C8510" ,"C8511" ,"C8512" ,"C8513" ,"C8514" ,"C8515" ,"C8516" ,"C8517" ,"C8518" ,"C8519" ,"C8520" ,"C8521" ,"C8522" ,"C8523" ,"C8524" ,"C8525" ,"C8526"
 ,"C8527" ,"C8528" ,"C8529" ,"C8580" ,"C8581" ,"C8582" ,"C8583" ,"C8584" ,"C8585" ,"C8586" ,"C8587" ,"C8588" ,"C8589" ,"C8590" ,"C8591"
 ,"C8592" ,"C8593" ,"C8594" ,"C8595" ,"C8596" ,"C8597" ,"C8598" ,"C8599" ,"C860" ,"C861" ,"C862" ,"C863" ,"C864" ,"C865" ,"C866" ,"C882" ,"C883" ,"C884" ,"C888" ,"C889" ,"C9030" ,"C9031" ,"C9032" ,"C9110" ,"C9111" ,"C9112" ,"C9130" ,"C9131" ,"C9132" ,"C9140" ,"C9141" ,"C9142" ,"C9150" ,"C9151" ,"C9152" ,"C9160" ,"C9161" ,"C9162" ,"C9190" ,"C9191" ,"C9192" ,"C91A0" ,"C91A1" ,"C91A2" ,"C91Z0" ,"C91Z1" ,"C91Z2" ,"C9510" ,"C9511" ,"C9512" ,"C9590" ,"C9591" ,"C9592" ,"C960" ,"C962" ,"C9620" ,"C9621" ,"C9622" ,"C9629" ,"C964" ,"C965" ,"C966" ,"C969" ,"C96A" ,"C96Z"
 
))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].DISCHARGE_CONDITION_CODE ="CC-10"
endif
if (nom.source_identifier in ("I6300" ,"I63011" ,"I63012" ,"I63013" ,"I63019" ,"I6302" ,"I63031" ,"I63032" ,"I63033" ,"I63039" ,"I6309" ,"I6310" ,"I63111" ,"I63112" ,"I63113" ,"I63119" ,"I6312" ,"I63131" ,"I63132" ,"I63133" ,"I63139" ,"I6319" ,"I6320" ,"I63211" ,"I63212" ,"I63213" ,"I63219" ,"I6322" ,"I63231" ,"I63232" ,"I63233" ,"I63239" ,"I6329" ,"I6330" ,"I63311" ,"I63312" ,"I63313" ,"I63319" ,"I63321" ,"I63322" ,"I63323" ,"I63329" ,"I63331" ,"I63332" ,"I63333" ,"I63339" ,"I63341" ,"I63342" ,"I63343" ,"I63349" ,"I6339" ,"I6340" ,"I63411" ,"I63412" ,"I63413" ,"I63419" ,"I63421" ,"I63422" ,"I63423" ,"I63429" ,"I63431" ,"I63432" ,"I63433" ,"I63439" ,"I63441" ,"I63442" ,"I63443" ,"I63449" ,"I6349" ,"I6350" ,"I63511" ,"I63512" ,"I63513" ,"I63519" ,"I63521" ,"I63522" ,"I63523" ,"I63529" ,"I63531" ,"I63532" ,"I63533" ,"I63539" ,"I63541" ,"I63542" ,"I63543" ,"I63549" ,"I6359" ,"I636" ,"I638" ,"I6381" ,"I6389" ,"I639" ,"I97810" ,"I97811" ,"I97820" ,"I97821"))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].DISCHARGE_CONDITION_CODE ="CC-100"
 ENDIF
 if (nom.source_identifier in ("G8100" ,"G8101" ,"G8102" ,"G8103" ,"G8104" ,"G8110" ,"G8111" ,"G8112" ,"G8113" ,"G8114" ,"G8190" ,"G8191" ,"G8192" ,"G8193" ,"G8194" ,"I69051" ,"I69052" ,"I69053" ,"I69054" ,"I69059" ,"I69151" ,"I69152" ,"I69153" ,"I69154" ,"I69159" ,"I69251" ,"I69252" ,"I69253" ,"I69254" ,"I69259" ,"I69351" ,"I69352" ,"I69353" ,"I69354" ,"I69359" ,"I69851" ,"I69852" ,"I69853" ,"I69854" ,"I69859" ,"I69951" ,"I69952" ,"I69953" ,"I69954" ,"I69959"))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].DISCHARGE_CONDITION_CODE ="CC-103"
 ENDIF
 if (nom.source_identifier in ("G830" ,"G8310" ,"G8311" ,"G8312" ,"G8313" ,"G8314" ,"G8320" ,"G8321" ,"G8322" ,"G8323" ,"G8324" ,"G8330"
 
 ,"G8331" ,"G8332" ,"G8333" ,"G8334" ,"G835" ,"G8381" ,"G8382" ,"G8383" ,"G8384" ,"G8389" ,"G839" ,"I69031" ,"I69032" ,"I69033" ,"I69034"
  ,"I69039" ,"I69041" ,"I69042" ,"I69043" ,"I69044" ,"I69049" ,"I69061" ,"I69062" ,"I69063" ,"I69064" ,"I69065" ,"I69069" ,"I69131"
  ,"I69132" ,"I69133" ,"I69134" ,"I69139" ,"I69141" ,"I69142" ,"I69143" ,"I69144" ,"I69149" ,"I69161" ,"I69162" ,"I69163" ,"I69164" ,"I69165"
  ,"I69169" ,"I69231" ,"I69232" ,"I69233" ,"I69234" ,"I69239" ,"I69241" ,"I69242" ,"I69243" ,"I69244" ,"I69249" ,"I69261" ,"I69262" ,"I69263" ,"I69264" ,"I69265" ,"I69269" ,"I69331" ,"I69332" ,"I69333" ,"I69334" ,"I69339" ,"I69341" ,"I69342" ,"I69343" ,"I69344" ,"I69349" ,"I69361" ,"I69362" ,"I69363" ,"I69364" ,"I69365" ,"I69369" ,"I69831" ,"I69832" ,"I69833" ,"I69834" ,"I69839" ,"I69841" ,"I69842" ,"I69843" ,"I69844" ,"I69849" ,"I69861" ,"I69862"
  ,"I69863" ,"I69864" ,"I69865" ,"I69869" ,"I69931" ,"I69932" ,"I69933" ,"I69934" ,"I69939" ,"I69941" ,"I69942" ,"I69943" ,"I69944" ,"I69949" ,"I69961" ,"I69962" ,"I69963" ,"I69964" ,"I69965" ,"I69969"))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].DISCHARGE_CONDITION_CODE ="CC-104"
 ENDIF
 if (nom.source_identifier in ("A480" ,"E0852" ,"E0952" ,"E1052" ,"E1152" ,"E1352" ,"I70231" ,"I70232" ,"I70233" ,"I70234" ,"I70235" ,"I70238" ,"I70239" ,"I70241" ,"I70242" ,"I70243" ,"I70244" ,"I70245" ,"I70248" ,"I70249" ,"I7025" ,"I70261" ,"I70262" ,"I70263" ,"I70268" ,"I70269" ,"I70331" ,"I70332" ,"I70333" ,"I70334" ,"I70335" ,"I70338" ,"I70339" ,"I70341" ,"I70342" ,"I70343" ,"I70344" ,"I70345" ,"I70348" ,"I70349" ,"I7035" ,"I70361" ,"I70362" ,"I70363" ,"I70368" ,"I70369" ,"I70431" ,"I70432" ,"I70433" ,"I70434" ,"I70435" ,"I70438" ,"I70439" ,"I70441" ,"I70442" ,"I70443" ,"I70444" ,"I70445" ,"I70448" ,"I70449" ,"I7045" ,"I70461" ,"I70462" ,"I70463" ,"I70468" ,"I70469" ,"I70531" ,"I70532" ,"I70533" ,"I70534" ,"I70535" ,"I70538" ,"I70539" ,"I70541" ,"I70542" ,"I70543" ,"I70544" ,"I70545" ,"I70548" ,"I70549" ,"I7055" ,"I70561" ,"I70562" ,"I70563" ,"I70568" ,"I70569" ,"I70631" ,"I70632" ,"I70633" ,"I70634" ,"I70635" ,"I70638" ,"I70639" ,"I70641" ,"I70642" ,"I70643" ,"I70644" ,"I70645" ,
"I70648" ,"I70649" ,"I7065" ,"I70661" ,"I70662" ,"I70663" ,"I70668" ,"I70669" ,"I70731" ,"I70732" ,"I70733" ,"I70734" ,"I70735" ,"I70738" ,"I70739" ,"I70741" ,"I70742" ,"I70743" ,"I70744" ,"I70745" ,"I70748" ,"I70749" ,"I7075" ,"I70761" ,"I70762" ,"I70763" ,"I70768" ,"I70769" ,"I7301" ,"I96"))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].DISCHARGE_CONDITION_CODE ="CC-106"
 ENDIF
 if (nom.source_identifier in ( "I2601" ,"I2602" ,"I2609" ,"I2690" ,"I2692" ,"I2699" ,"I2782" ,"I670" ,"I7100" ,"I7101" ,"I7102" ,"I7103" ,"I711" ,"I713" ,"I715" ,"I718" ,"I7401" ,"I7409" ,"I7410" ,"I7411" ,"I7419" ,"I742" ,"I743" ,"I744" ,"I745" ,"I748" ,"I749" ,"I75011" ,"I75012" ,"I75013" ,"I75019" ,"I75021" ,"I75022" ,"I75023" ,"I75029" ,"I7581" ,"I7589" ,"I76" ,"I7770" ,"I7771" ,"I7772" ,"I7773" ,"I7774" ,"I7775" ,"I7776" ,"I7777" ,"I7779" ,"I83001" ,"I83002" ,"I83003" ,"I83004" ,"I83005" ,"I83008" ,"I83009" ,"I83011" ,"I83012" ,"I83013" ,"I83014" ,"I83015" ,"I83018" ,"I83019" ,"I83021" ,"I83022" ,"I83023" ,"I83024" ,"I83025" ,"I83028" ,"I83029" ,"I83201" ,"I83202" ,"I83203" ,"I83204" ,"I83205" ,"I83208" ,"I83209" ,"I83211" ,"I83212" ,"I83213" ,"I83214" ,"I83215" ,"I83218" ,"I83219" ,"I83221" ,"I83222" ,"I83223" ,"I83224" ,"I83225" ,"I83228" ,"I83229" ,"I87011" ,"I87012" ,"I87013" ,"I87019" ,"I87031" ,"I87032" ,"I87033" ,"I87039" ,"I87311" ,"I87312" ,"I87313" ,"I87319" ,"I87331" ,
"I87332" ,"I87333" ,"I87339" ,"K550" ,"K55011" ,"K55012" ,"K55019" ,"K55021" ,"K55022" ,"K55029" ,"K55031" ,"K55032" ,"K55039" ,"K55041" ,"K55042" ,"K55049" ,"K55051" ,"K55052" ,"K55059" ,"K55061" ,"K55062" ,"K55069" ,"K5530" ,"K5531" ,"K5532" ,"K5533" ,"N280"))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].DISCHARGE_CONDITION_CODE ="CC-107"
 ENDIF
 if (nom.source_identifier in ("E0851" ,"E0852" ,"E0951" ,"E0952" ,"E1051" ,"E1052" ,"E1151" ,"E1152" ,"E1351" ,"E1352" ,"I700" ,"I701" ,"I70201" ,"I70202" ,"I70203" ,"I70208" ,"I70209" ,"I70211" ,"I70212" ,"I70213" ,"I70218" ,"I70219" ,"I70221" ,"I70222" ,"I70223" ,"I70228" ,"I70229" ,"I70291" ,"I70292" ,"I70293" ,"I70298" ,"I70299" ,"I70301" ,"I70302" ,"I70303" ,"I70308" ,"I70309" ,"I70311" ,"I70312" ,"I70313" ,"I70318" ,"I70319" ,"I70321" ,"I70322" ,"I70323" ,"I70328" ,"I70329" ,"I70391" ,"I70392" ,"I70393" ,"I70398" ,"I70399" ,"I70401" ,"I70402" ,"I70403" ,"I70408" ,"I70409" ,"I70411" ,"I70412" ,"I70413" ,"I70418" ,"I70419" ,"I70421" ,"I70422" ,"I70423" ,"I70428" ,"I70429" ,"I70491" ,"I70492" ,"I70493" ,"I70498" ,"I70499" ,"I70501" ,"I70502" ,"I70503" ,"I70508" ,"I70509" ,"I70511" ,"I70512" ,"I70513" ,"I70518" ,"I70519" ,"I70521" ,"I70522" ,"I70523" ,"I70528" ,"I70529" ,"I70591" ,"I70592" ,"I70593" ,"I70598" ,"I70599" ,"I70601" ,"I70602" ,"I70603" ,"I70608" ,"I70609" ,"I70611" ,
 "I70612" ,"I70613" ,"I70618" ,"I70619" ,"I70621" ,"I70622" ,"I70623" ,"I70628" ,"I70629" ,"I70691" ,"I70692" ,"I70693" ,"I70698" ,"I70699" ,"I70701" ,"I70702" ,"I70703" ,"I70708" ,"I70709" ,"I70711" ,"I70712" ,"I70713" ,"I70718" ,"I70719" ,"I70721" ,"I70722" ,"I70723" ,"I70728" ,"I70729" ,"I70791" ,"I70792" ,"I70793" ,"I70798" ,"I70799" ,"I7092" ,"I712" ,"I714" ,"I716" ,"I719" ,"I720" ,"I721" ,"I722" ,"I723" ,"I724" ,"I725" ,"I726" ,"I728" ,"I729" ,"I731" ,"I7381" ,"I7389" ,"I739" ,"I770" ,"I771" ,"I772" ,"I773" ,"I774" ,"I775" ,"I776" ,"I77810" ,"I77811" ,"I77812" ,"I77819" ,"I7789" ,"I779" ,"I780" ,"I790" ,"I791" ,"I798" ,"I8010" ,"I8011" ,"I8012" ,"I8013" ,"I80201" ,"I80202" ,"I80203" ,"I80209" ,"I80211" ,"I80212" ,"I80213" ,"I80219" ,"I80221" ,"I80222" ,"I80223" ,"I80229" ,"I80231" ,"I80232" ,"I80233" ,"I80239" ,"I80291" ,"I80292" ,"I80293" ,"I80299" ,"I820" ,"I82210" ,"I82211" ,"I82220" ,"I82221" ,"I82290" ,"I82291" ,"I823" ,"I82401" ,"I82402" ,"I82403" ,"I82409" ,"I82411"
 ,"I82412"
,"I82413" ,"I82419" ,"I82421" ,"I82422" ,"I82423" ,"I82429" ,"I82431" ,"I82432" ,"I82433" ,"I82439" ,"I82441" ,"I82442" ,"I82443" ,"I82449" ,"I82491" ,"I82492" ,"I82493" ,"I82499" ,"I824Y1" ,"I824Y2" ,"I824Y3" ,"I824Y9" ,"I824Z1" ,"I824Z2" ,"I824Z3" ,"I824Z9" ,"I82501" ,"I82502" ,"I82503" ,"I82509" ,"I82511" ,"I82512" ,"I82513" ,"I82519" ,"I82521" ,"I82522" ,"I82523" ,"I82529" ,"I82531" ,"I82532" ,"I82533" ,"I82539" ,"I82541" ,"I82542" ,"I82543" ,"I82549" ,"I82591" ,"I82592" ,"I82593" ,"I82599" ,"I825Y1" ,"I825Y2" ,"I825Y3" ,"I825Y9" ,"I825Z1" ,"I825Z2" ,"I825Z3" ,"I825Z9" ,"I82621" ,"I82622" ,"I82623" ,"I82629" ,"I82721" ,"I82722" ,"I82723" ,"I82729" ,"I82A11" ,"I82A12" ,"I82A13" ,"I82A19" ,"I82A21" ,"I82A22" ,"I82A23" ,"I82A29" ,"I82B11" ,"I82B12" ,"I82B13" ,"I82B19" ,"I82B21" ,"I82B22" ,"I82B23" ,"I82B29" ,"I82C11" ,"I82C12" ,"I82C13" ,"I82C19" ,"I82C21" ,"I82C22" ,"I82C23" ,"I82C29" ,"K551" ,"K558" ,"K559" ,"M318" ,"M319"))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].DISCHARGE_CONDITION_CODE ="CC-108"
 ENDIF
 if (nom.source_identifier in ("C01" ,"C020" ,"C021" ,"C022" ,"C023" ,"C024" ,"C028" ,"C029" ,"C030" ,"C031" ,"C039" ,"C040" ,"C041" ,"C048" ,"C049" ,"C050" ,"C051" ,"C052" ,"C058" ,"C059" ,"C060" ,"C061" ,"C062" ,"C0680" ,"C0689" ,"C069" ,"C07" ,"C080" ,"C081" ,"C089" ,"C090" ,"C091" ,"C098" ,"C099" ,"C100" ,"C101" ,"C102" ,"C103" ,"C104" ,"C108" ,"C109" ,"C110" ,"C111" ,"C112" ,"C113" ,"C118" ,"C119" ,"C12" ,"C130" ,"C131" ,"C132" ,"C138" ,"C139" ,"C140" ,"C142" ,"C148" ,"C180" ,"C181" ,"C182" ,"C183" ,"C184" ,"C185" ,"C186" ,"C187" ,"C188" ,"C189" ,"C19" ,"C20" ,"C210" ,"C211" ,"C212" ,"C218" ,"C260" ,"C261" ,"C269" ,"C300" ,"C301" ,"C310" ,"C311" ,"C312" ,"C313" ,"C318" ,"C319" ,"C320" ,"C321" ,"C322" ,"C323" ,"C328" ,"C329" ,"C37" ,"C380" ,"C381" ,"C382" ,"C383" ,"C388" ,"C390" ,"C399" ,"C510" ,"C511" ,"C512" ,"C518" ,"C519" ,"C52" ,"C530" ,"C531" ,"C538" ,"C539" ,"C577" ,"C578" ,"C579" ,"C641" ,"C642" ,"C649" ,"C651" ,"C652" ,"C659" ,"C661" ,"C662" ,"C669" ,"C670" ,"C671" ,"C672"
 ,"C673" ,"C674" ,"C675" ,"C676" ,"C677" ,"C678" ,"C679" ,"C680" ,"C681" ,"C688" ,"C689"))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].DISCHARGE_CONDITION_CODE ="CC-11"
 ENDIF
 if (nom.source_identifier in ("E840" ,"E8411" ,"E8419" ,"E848" ,"E849"))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].DISCHARGE_CONDITION_CODE ="CC-110"
 ENDIF
 if (nom.source_identifier in ("J410" ,"J411" ,"J418" ,"J42" ,"J430" ,"J431" ,"J432" ,"J438" ,"J439" ,"J440" ,"J441" ,"J449" ,"J982" ,"J983"))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].DISCHARGE_CONDITION_CODE ="CC-111"
 ENDIF
 if (nom.source_identifier in ("B4481" ,"D860" ,"D862" ,"J470" ,"J471" ,"J479" ,"J60" ,"J61" ,"J620" ,"J628" ,"J630" ,"J631" ,"J632" ,"J633" ,"J634" ,"J635" ,"J636" ,"J64" ,"J65" ,"J660" ,"J661" ,"J662" ,"J668" ,"J670" ,"J671" ,"J672" ,"J673" ,"J674" ,"J675" ,"J676" ,"J677" ,"J678" ,"J679" ,"J680" ,"J681" ,"J682" ,"J683" ,"J684" ,"J688" ,"J689" ,"J700" ,"J701" ,"J702" ,"J703" ,"J704" ,"J705" ,"J708" ,"J709" ,"J82" ,"J8401" ,"J8402" ,"J8403" ,"J8409" ,"J8410" ,"J84111" ,"J84112" ,"J84113" ,"J84114" ,"J84115" ,"J84116" ,"J84117" ,"J8417" ,"J842" ,"J8481" ,"J8482" ,"J8483" ,"J84841" ,"J84842" ,"J84843" ,"J84848" ,"J8489" ,"J849" ,"J99" ,"M3213" ,"M3301" ,"M3311" ,"M3321" ,"M3391" ,"M3481" ,"M3502" ))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].DISCHARGE_CONDITION_CODE ="CC-112"
 ENDIF
 if (nom.source_identifier in ("A481" ,"J150" ,"J151" ,"J1520" ,"J15211" ,"J15212" ,"J1529" ,"J155" ,"J156" ,"J158" ,"J690" ,"J691" ,"J698" ,"J95851"
))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].DISCHARGE_CONDITION_CODE ="CC-114"
 ENDIF
 if (nom.source_identifier in ("A0103" ,"A0222" ,"A065" ,"A202" ,"A212" ,"A221" ,"A420" ,"A430" ,"A5484" ,"B380" ,"B381" ,"B382" ,"B390" ,"B391" ,"B392" ,"B400" ,"B401" ,"B402" ,"B410" ,"B664" ,"B671" ,"J13" ,"J14" ,"J153" ,"J154" ,"J181" ,"J850" ,"J851" ,"J852" ,"J853" ,"J860" ,"J869"))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].DISCHARGE_CONDITION_CODE ="CC-115"
 ENDIF
 if (nom.source_identifier in ("C430" ,"C4310" ,"C4311" ,"C43111" ,"C43112" ,"C4312" ,"C43121" ,"C43122" ,"C4320" ,"C4321" ,"C4322" ,"C4330"
 ,"C4331" ,"C4339" ,"C434" ,"C4351" ,"C4352" ,"C4359" ,"C4360" ,"C4361" ,"C4362" ,"C4370" ,"C4371" ,"C4372" ,"C438" ,"C439" ,"C4A0" ,"C4A10" ,
 "C4A11" ,"C4A111" ,"C4A112" ,"C4A12" ,"C4A121" ,"C4A122" ,"C4A20" ,"C4A21" ,"C4A22" ,"C4A30" ,"C4A31" ,"C4A39" ,"C4A4" ,"C4A51" ,"C4A52" ,"C4A59" ,"C4A60" ,"C4A61" ,"C4A62" ,"C4A70" ,"C4A71" ,"C4A72" ,"C4A8" ,"C4A9" ,"C50011" ,"C50012" ,"C50019" ,"C50021" ,"C50022" ,"C50029" ,"C50111" ,"C50112" ,"C50119" ,"C50121" ,"C50122" ,"C50129" ,"C50211" ,"C50212" ,"C50219" ,"C50221" ,"C50222" ,"C50229" ,"C50311" ,"C50312" ,"C50319" ,"C50321" ,"C50322" ,"C50329" ,"C50411" ,"C50412" ,"C50419" ,"C50421" ,"C50422" ,"C50429" ,"C50511" ,"C50512" ,"C50519" ,"C50521" ,"C50522" ,"C50529" ,"C50611" ,"C50612" ,"C50619" ,"C50621" ,"C50622" ,"C50629" ,"C50811" ,"C50812" ,"C50819" ,"C50821" ,"C50822" ,"C50829" ,"C50911" ,"C50912" ,
 "C50919" ,"C50921" ,"C50922" ,"C50929" ,"C540" ,"C541" ,"C542" ,"C543" ,"C548" ,"C549" ,"C55" ,"C600" ,"C601" ,"C602" ,"C608" ,"C609" ,"C61" ,"C6200" ,"C6201" ,"C6202" ,"C6210" ,"C6211" ,"C6212" ,"C6290" ,"C6291" ,"C6292" ,"C6300" ,"C6301" ,"C6302" ,"C6310" ,"C6311" ,"C6312" ,"C632" ,"C637" ,"C638" ,"C639" ,"C6900" ,"C6901" ,"C6902" ,"C6910" ,"C6911" ,"C6912" ,"C6920" ,"C6921" ,"C6922" ,"C6930" ,"C6931" ,"C6932" ,"C6940" ,"C6941" ,"C6942" ,"C6950" ,"C6951" ,"C6952" ,"C6960" ,"C6961" ,"C6962" ,"C6980" ,"C6981" ,"C6982" ,"C6990" ,"C6991" ,"C6992" ,"C73" ,"C750" ,"C754" ,"C755" ,"C758" ,"C759" ,"C760" ,"C761" ,"C762" ,"C763" ,"C7640" ,"C7641" ,"C7642" ,"C7650" ,"C7651" ,"C7652" ,"C768" ,"C7A00" ,"C7A010" ,"C7A011" ,"C7A012" ,"C7A019" ,"C7A020" ,"C7A021" ,"C7A022" ,"C7A023" ,"C7A024" ,"C7A025" ,"C7A026" ,"C7A029" ,"C7A090" ,"C7A091" ,"C7A092" ,"C7A093" ,"C7A094" ,"C7A095" ,"C7A096" ,"C7A098" ,"C7A1" ,"C7A8" ,"C801" ,"C802" ,"D030" ,"D0310" ,"D0311" ,"D03111" ,"D03112" ,"D0312" ,"D03121" ,
"D03122" ,"D0320" ,"D0321" ,"D0322" ,"D0330" ,"D0339" ,"D034" ,"D0351" ,"D0352" ,"D0359" ,"D0360" ,"D0361" ,"D0362" ,"D0370" ,"D0371" ,"D0372" ,"D038" ,"D039" ,"D1802" ,"D320" ,"D321" ,"D329" ,"D330" ,"D331" ,"D332" ,"D333" ,"D334" ,"D337" ,"D339" ,"D352" ,"D353" ,"D354" ,"D420" ,"D421" ,"D429" ,"D430" ,"D431" ,"D432" ,"D433" ,"D434" ,"D438" ,"D439" ,"D443" ,"D444" ,"D445" ,"D446" ,"D447" ,"D496" ,"E340" ,"Q8500" ,"Q8501" ,"Q8502" ,"Q8503" ,"Q8509" ,"Q851" ,"Q858" ,"Q859"))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].DISCHARGE_CONDITION_CODE ="CC-12"
 ENDIF
 if (nom.source_identifier in ("E08351" ,"E083511" ,"E083512" ,"E083513" ,"E083519" ,"E083521" ,"E083522" ,"E083523" ,"E083529" ,"E083531" ,"E083532" ,"E083533" ,"E083539" ,"E083541" ,"E083542" ,"E083543" ,"E083549" ,"E083551" ,"E083552" ,"E083553" ,"E083559" ,"E08359" ,"E083591" ,"E083592" ,"E083593" ,"E083599" ,"E09351" ,"E093511" ,"E093512" ,"E093513" ,"E093519" ,"E093521" ,"E093522" ,"E093523" ,"E093529" ,"E093531" ,"E093532" ,"E093533" ,"E093539" ,"E093541" ,"E093542" ,"E093543" ,"E093549" ,"E093551" ,"E093552" ,"E093553" ,"E093559" ,"E09359" ,"E093591" ,"E093592" ,"E093593" ,"E093599" ,"E10351" ,"E103511" ,"E103512" ,"E103513" ,"E103519" ,"E103521" ,"E103522" ,"E103523" ,"E103529" ,"E103531" ,"E103532" ,"E103533" ,"E103539" ,"E103541" ,"E103542" ,"E103543" ,"E103549" ,"E103551" ,"E103552" ,"E103553" ,"E103559" ,"E10359" ,"E103591" ,"E103592" ,"E103593" ,"E103599" ,"E11351" ,"E113511" ,"E113512" ,"E113513" ,"E113519" ,"E113521" ,"E113522" ,"E113523" ,"E113529"
  ,"E113531" ,"E113532" ,"E113533" ,"E113539" ,"E113541" ,"E113542" ,"E113543" ,"E113549" ,"E113551" ,"E113552" ,"E113553" ,"E113559" ,"E11359" ,"E113591" ,"E113592" ,"E113593" ,"E113599" ,"E13351" ,"E133511" ,"E133512" ,"E133513" ,"E133519" ,"E133521" ,"E133522" ,"E133523" ,"E133529" ,"E133531" ,"E133532" ,"E133533" ,"E133539" ,"E133541" ,"E133542" ,"E133543" ,"E133549" ,"E133551" ,"E133552" ,"E133553" ,"E133559" ,"E13359" ,"E133591" ,"E133592" ,"E133593" ,"E133599" ,"H4310" ,"H4311" ,"H4312" ,"H4313"))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].DISCHARGE_CONDITION_CODE ="CC-122"
 ENDIF
 if (nom.source_identifier in ("H3532" ,"H353210" ,"H353211" ,"H353212" ,"H353213" ,"H353220" ,"H353221" ,"H353222" ,"H353223" ,"H353230" ,"H353231" ,"H353232" ,"H353233" ,"H353290" ,"H353291" ,"H353292" ,"H353293"))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].DISCHARGE_CONDITION_CODE ="CC-124"
endif
 if (nom.source_identifier in ("T81502A" ,"T81502D" ,"T81502S" ,"T81512A" ,"T81512D" ,"T81512S" ,"T81522A" ,"T81522D" ,"T81522S" ,"T81532A" ,"T81532D" ,"T81532S" ,"T81592A" ,"T81592D" ,"T81592S" ,"T8241XA" ,"T8241XD" ,"T8241XS" ,"T8242XA" ,"T8242XD" ,"T8242XS" ,"T8243XA" ,"T8243XD" ,"T8243XS" ,"T8249XA" ,"T8249XD" ,"T8249XS" ,"T85611A" ,"T85611D" ,"T85611S" ,"T85621A" ,"T85621D" ,"T85621S" ,"T85631A" ,"T85631D" ,"T85631S" ,"T85691A" ,"T85691D" ,"T85691S" ,"T8571XA" ,"T8571XD" ,"T8571XS" ,"Y622" ,"Z4901" ,"Z4902" ,"Z4931" ,"Z4932" ,"Z9115" ,"Z992"
))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].DISCHARGE_CONDITION_CODE ="CC-134"
 ENDIF
 if (nom.source_identifier in (
"N170"
,"N171"
,"N172"
,"N178"
,"N179"
))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].DISCHARGE_CONDITION_CODE ="CC-135"
endif
 if (nom.source_identifier in (
"I120"
,"I1311"
,"I132"
,"N185"
,"N186"
))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].DISCHARGE_CONDITION_CODE ="CC-136"
 ENDIF
 if (nom.source_identifier in ("N184"))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].DISCHARGE_CONDITION_CODE ="CC-137"
endif
 if (nom.source_identifier in ("N183"))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].DISCHARGE_CONDITION_CODE ="CC-138"
 ENDIF
 if (nom.source_identifier in (
"E0822"
,"E0922"
,"E1022"
,"E1122"
,"E1322"
,"I129"
,"I130"
,"I1310"
,"N181"
,"N182"
,"N189"
,"Q6111"
,"Q6119"
))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].DISCHARGE_CONDITION_CODE ="CC-139"
endif
 if (nom.source_identifier in ("N19"))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].DISCHARGE_CONDITION_CODE ="CC-140"
 ENDIF
 if (nom.source_identifier in ("A3684" ,"A985" ,"B520" ,"D8684" ,"E0821" ,"E0829" ,"E0921" ,"E0929" ,"E1021" ,"E1029" ,"E1121" ,"E1129" ,"E1321" ,"E1329" ,"M3214" ,"M3215" ,"M3504" ,"N000" ,"N001" ,"N002" ,"N003" ,"N004" ,"N005" ,"N006" ,"N007" ,"N008" ,"N009" ,"N010" ,"N011" ,"N012" ,"N013" ,"N014" ,"N015" ,"N016" ,"N017" ,"N018" ,"N019" ,"N020" ,"N021" ,"N022" ,"N023" ,"N024" ,"N025" ,"N026" ,"N027" ,"N028" ,"N029" ,"N030" ,"N031" ,"N032" ,"N033" ,"N034" ,"N035" ,"N036" ,"N037" ,"N038" ,"N039" ,"N040" ,"N041" ,"N042" ,"N043" ,"N044" ,"N045" ,"N046" ,"N047" ,"N048" ,"N049" ,"N050" ,"N051" ,"N052" ,"N053" ,"N054" ,"N055" ,"N056" ,"N057" ,"N058" ,"N059" ,"N060" ,"N061" ,"N062" ,"N063" ,"N064" ,"N065" ,"N066" ,"N067" ,"N068" ,"N069" ,"N070" ,"N071" ,"N072" ,"N073" ,"N074" ,"N075" ,"N076" ,"N077" ,"N078" ,"N079" ,"N08" ,"N140" ,"N141" ,"N142" ,"N143" ,"N144" ,"N150" ,"N158"))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].DISCHARGE_CONDITION_CODE ="CC-141"
endif
 if (nom.source_identifier in ("L89004" ,"L89014" ,"L89024" ,"L89104" ,"L89114" ,"L89124" ,"L89134" ,"L89144" ,"L89154" ,"L89204" ,"L89214" ,"L89224" ,"L89304" ,"L89314" ,"L89324" ,"L8944" ,"L89504" ,"L89514" ,"L89524" ,"L89604" ,"L89614" ,"L89624" ,"L89814" ,"L89894" ,"L8994"))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].DISCHARGE_CONDITION_CODE ="CC-157"
 ENDIF
 if (nom.source_identifier in ("L89000" ,"L89003" ,"L89010" ,"L89013" ,"L89020" ,"L89023" ,"L89100" ,"L89103" ,"L89110" ,"L89113" ,"L89120" ,"L89123" ,"L89130" ,"L89133" ,"L89140" ,"L89143" ,"L89150" ,"L89153" ,"L89200" ,"L89203" ,"L89210" ,"L89213" ,"L89220" ,"L89223" ,"L89300" ,"L89303" ,"L89310" ,"L89313" ,"L89320" ,"L89323" ,"L8943" ,"L8945" ,"L89500" ,"L89503" ,"L89510" ,"L89513" ,"L89520" ,"L89523" ,"L89600" ,"L89603" ,"L89610" ,"L89613" ,"L89620" ,"L89623" ,"L89810" ,"L89813" ,"L89890" ,"L89893" ,"L8993" ,"L8995"))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].DISCHARGE_CONDITION_CODE ="CC-158"
endif
 if (nom.source_identifier in ("L89002" ,"L89012" ,"L89022" ,"L89102" ,"L89112" ,"L89122" ,"L89132" ,"L89142" ,"L89152" ,"L89202" ,"L89212" ,"L89222" ,"L89302" ,"L89312" ,"L89322" ,"L8942" ,"L89502" ,"L89512" ,"L89522" ,"L89602" ,"L89612" ,"L89622" ,"L89812" ,"L89892" ,"L8992"))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].DISCHARGE_CONDITION_CODE ="CC-159"
 ENDIF
 if (nom.source_identifier in ("L89000" ,"L89001" ,"L89002" ,"L89003" ,"L89004" ,"L89009" ,"L89010" ,"L89011" ,"L89012" ,"L89013" ,"L89014" ,"L89019" ,"L89020" ,"L89021" ,"L89022" ,"L89023" ,"L89024" ,"L89029" ,"L89100" ,"L89101" ,"L89102" ,"L89103" ,"L89104" ,"L89109" ,"L89110" ,"L89111" ,"L89112" ,"L89113" ,"L89114" ,"L89119" ,"L89120" ,"L89121" ,"L89122" ,"L89123" ,"L89124" ,"L89129" ,"L89130" ,"L89131" ,"L89132" ,"L89133" ,"L89134" ,"L89139" ,"L89140" ,"L89141" ,"L89142" ,"L89143" ,"L89144" ,"L89149" ,"L89150" ,"L89151" ,"L89152" ,"L89153" ,"L89154" ,"L89159" ,"L89200" ,"L89201" ,"L89202" ,"L89203" ,"L89204" ,"L89209" ,"L89210" ,"L89211" ,"L89212" ,"L89213" ,"L89214" ,"L89219" ,"L89220" ,"L89221" ,"L89222" ,"L89223" ,"L89224" ,"L89229" ,"L89300" ,"L89301" ,"L89302" ,"L89303" ,"L89304" ,"L89309" ,"L89310" ,"L89311" ,"L89312" ,"L89313" ,"L89314" ,"L89319" ,"L89320" ,"L89321" ,"L89322" ,"L89323" ,"L89324" ,"L89329" ,"L8940" ,"L8941" ,"L8942" ,"L8943" ,"L8944" ,"L8945" ,"L89500"
 ,"L89501" ,"L89502" ,"L89503" ,"L89504" ,"L89509" ,"L89510" ,"L89511" ,"L89512" ,"L89513" ,"L89514" ,"L89519" ,"L89520" ,"L89521" ,"L89522" ,"L89523" ,"L89524" ,"L89529" ,"L89600" ,"L89601" ,"L89602" ,"L89603" ,"L89604" ,"L89609" ,"L89610" ,"L89611" ,"L89612" ,"L89613" ,"L89614" ,"L89619" ,"L89620" ,"L89621" ,"L89622" ,"L89623" ,"L89624" ,"L89629" ,"L89810" ,"L89811" ,"L89812" ,"L89813" ,"L89814" ,"L89819" ,"L89890" ,"L89891" ,"L89892" ,"L89893" ,"L89894" ,"L89899" ,"L8990" ,"L8991" ,"L8992" ,"L8993" ,"L8994" ,"L8995"))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].DISCHARGE_CONDITION_CODE ="CC-160"
endif
 if (nom.source_identifier in ("I70231" ,"I70232" ,"I70233" ,"I70234" ,"I70235" ,"I70238" ,"I70239" ,"I70241" ,"I70242" ,"I70243" ,"I70244" ,"I70245" ,"I70248" ,"I70249" ,"I7025" ,"I70331" ,"I70332" ,"I70333" ,"I70334" ,"I70335" ,"I70338" ,"I70339" ,"I70341" ,"I70342" ,"I70343" ,"I70344" ,"I70345" ,"I70348" ,"I70349" ,"I7035" ,"I70431" ,"I70432" ,"I70433" ,"I70434" ,"I70435" ,"I70438" ,"I70439" ,"I70441" ,"I70442" ,"I70443" ,"I70444" ,"I70445" ,"I70448" ,"I70449" ,"I7045" ,"I70531" ,"I70532" ,"I70533" ,"I70534" ,"I70535" ,"I70538" ,"I70539" ,"I70541" ,"I70542" ,"I70543" ,"I70544" ,"I70545" ,"I70548" ,"I70549" ,"I7055" ,"I70631" ,"I70632" ,"I70633" ,"I70634" ,"I70635" ,"I70638" ,"I70639" ,"I70641" ,"I70642" ,"I70643" ,"I70644" ,"I70645" ,"I70648" ,"I70649" ,"I7065" ,"I70731" ,"I70732" ,"I70733" ,"I70734" ,"I70735" ,"I70738" ,"I70739" ,"I70741" ,"I70742" ,"I70743" ,"I70744" ,"I70745" ,"I70748" ,"I70749" ,"I7075" ,"L97101" ,"L97102" ,"L97103" ,"L97104" ,"L97105" ,"L97106" ,"L97108"
  ,"L97109" ,"L97111" ,"L97112" ,"L97113" ,"L97114" ,"L97115" ,"L97116" ,"L97118" ,"L97119" ,"L97121" ,"L97122" ,"L97123" ,"L97124" ,"L97125" ,"L97126" ,"L97128" ,"L97129" ,"L97201" ,"L97202" ,"L97203" ,"L97204" ,"L97205" ,"L97206" ,"L97208" ,"L97209" ,"L97211" ,"L97212" ,"L97213" ,"L97214" ,"L97215" ,"L97216" ,"L97218" ,"L97219" ,"L97221" ,"L97222" ,"L97223" ,"L97224" ,"L97225" ,"L97226" ,"L97228" ,"L97229" ,"L97301" ,"L97302" ,"L97303" ,"L97304" ,"L97305" ,"L97306" ,"L97308" ,"L97309" ,"L97311" ,"L97312" ,"L97313" ,"L97314" ,"L97315" ,"L97316" ,"L97318" ,"L97319" ,"L97321" ,"L97322" ,"L97323" ,"L97324" ,"L97325" ,"L97326" ,"L97328" ,"L97329" ,"L97401" ,"L97402" ,"L97403" ,"L97404" ,"L97405" ,"L97406" ,"L97408" ,"L97409" ,"L97411" ,"L97412" ,"L97413" ,"L97414" ,"L97415" ,"L97416" ,"L97418" ,"L97419" ,"L97421" ,"L97422" ,"L97423" ,"L97424" ,"L97425" ,"L97426" ,"L97428" ,"L97429" ,"L97501" ,"L97502" ,"L97503" ,"L97504" ,"L97505" ,"L97506" ,"L97508" ,"L97509" ,"L97511" ,"L97512"
   ,"L97513" ,"L97514" ,
"L97515" ,"L97516" ,"L97518" ,"L97519" ,"L97521" ,"L97522" ,"L97523" ,"L97524" ,"L97525" ,"L97526" ,"L97528" ,"L97529" ,"L97801" ,"L97802" ,"L97803" ,"L97804" ,"L97805" ,"L97806" ,"L97808" ,"L97809" ,"L97811" ,"L97812" ,"L97813" ,"L97814" ,"L97815" ,"L97816" ,"L97818" ,"L97819" ,"L97821" ,"L97822" ,"L97823" ,"L97824" ,"L97825" ,"L97826" ,"L97828" ,"L97829" ,"L97901" ,"L97902" ,"L97903" ,"L97904" ,"L97905" ,"L97906" ,"L97908" ,"L97909" ,"L97911" ,"L97912" ,"L97913" ,"L97914" ,"L97915" ,"L97916" ,"L97918" ,"L97919" ,"L97921" ,"L97922" ,"L97923" ,"L97924" ,"L97925" ,"L97926" ,"L97928" ,"L97929" ,"L98411" ,"L98412" ,"L98413" ,"L98414" ,"L98415" ,"L98416" ,"L98418" ,"L98419" ,"L98421" ,"L98422" ,"L98423" ,"L98424" ,"L98425" ,"L98426" ,"L98428" ,"L98429" ,"L98491" ,"L98492" ,"L98493" ,"L98494" ,"L98495" ,"L98496" ,"L98498" ,"L98499"))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].DISCHARGE_CONDITION_CODE ="CC-161"
 ENDIF
 if (nom.source_identifier in ("L1230" ,"L1231" ,"L1235" ,"L511" ,"L512" ,"L513" ,"T3111" ,"T3121" ,"T3122" ,"T3131" ,"T3132" ,"T3133" ,"T3141" ,"T3142" ,"T3143" ,"T3144" ,"T3151" ,"T3152" ,"T3153" ,"T3154" ,"T3155" ,"T3161" ,"T3162" ,"T3163" ,"T3164" ,"T3165" ,"T3166" ,"T3171" ,"T3172" ,"T3173" ,"T3174" ,"T3175" ,"T3176" ,"T3177" ,"T3181" ,"T3182" ,"T3183" ,"T3184" ,"T3185" ,"T3186" ,"T3187" ,"T3188" ,"T3191" ,"T3192" ,"T3193" ,"T3194" ,"T3195" ,"T3196" ,"T3197" ,"T3198" ,"T3199" ,"T3211" ,"T3221" ,"T3222" ,"T3231" ,"T3232" ,"T3233" ,"T3241" ,"T3242" ,"T3243" ,"T3244" ,"T3251" ,"T3252" ,"T3253" ,"T3254" ,"T3255" ,"T3261" ,"T3262" ,"T3263" ,"T3264" ,"T3265" ,"T3266" ,"T3271" ,"T3272" ,"T3273" ,"T3274" ,"T3275" ,"T3276" ,"T3277" ,"T3281" ,"T3282" ,"T3283" ,"T3284" ,"T3285" ,"T3286" ,"T3287" ,"T3288" ,"T3291" ,"T3292" ,"T3293" ,"T3294" ,"T3295" ,"T3296" ,"T3297" ,"T3298" ,"T3299"))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].DISCHARGE_CONDITION_CODE ="CC-162"
endif
 if (nom.source_identifier in ("S061X3A" ,"S061X4A" ,"S061X5A" ,"S061X6A" ,"S062X3A" ,"S062X4A" ,"S062X5A" ,"S062X6A" ,"S06303A" ,"S06304A" ,"S06305A" ,"S06306A" ,"S06313A" ,"S06314A" ,"S06315A" ,"S06316A" ,"S06323A" ,"S06324A" ,"S06325A" ,"S06326A" ,"S06333A" ,"S06334A" ,"S06335A" ,"S06336A" ,"S06343A" ,"S06344A" ,"S06345A" ,"S06346A" ,"S06353A" ,"S06354A" ,"S06355A" ,"S06356A" ,"S06363A" ,"S06364A" ,"S06365A" ,"S06366A" ,"S06373A" ,"S06374A" ,"S06375A" ,"S06376A" ,"S06383A" ,"S06384A" ,"S06385A" ,"S06386A" ,"S064X3A" ,"S064X4A" ,"S064X5A" ,"S064X6A" ,"S065X3A" ,"S065X4A" ,"S065X5A" ,"S065X6A" ,"S066X3A" ,"S066X4A" ,"S066X5A" ,"S066X6A" ,"S06813A" ,"S06814A" ,"S06815A" ,"S06816A" ,"S06823A" ,"S06824A" ,"S06825A" ,"S06826A" ,"S06893A" ,"S06894A" ,"S06895A" ,"S06896A" ,"S069X3A" ,"S069X4A" ,"S069X5A" ,"S069X6A"))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].DISCHARGE_CONDITION_CODE ="CC-166"
 ENDIF
 if (nom.source_identifier in ("S020XXA" ,"S020XXB" ,"S020XXS" ,"S02101A" ,"S02101B" ,"S02101S" ,"S02102A" ,"S02102B" ,"S02102S" ,"S02109A" ,"S02109B" ,"S02109S" ,"S0210XA" ,"S0210XB" ,"S0210XS" ,"S02110A" ,"S02110B" ,"S02110S" ,"S02111A" ,"S02111B" ,"S02111S" ,"S02112A" ,"S02112B" ,"S02112S" ,"S02113A" ,"S02113B" ,"S02113S" ,"S02118A" ,"S02118B" ,"S02118S" ,"S02119A" ,"S02119B" ,"S02119S" ,"S0211AA" ,"S0211AB" ,"S0211AS" ,"S0211BA" ,"S0211BB" ,"S0211BS" ,"S0211CA" ,"S0211CB" ,"S0211CS" ,"S0211DA" ,"S0211DB" ,"S0211DS" ,"S0211EA" ,"S0211EB" ,"S0211ES" ,"S0211FA" ,"S0211FB" ,"S0211FS" ,"S0211GA" ,"S0211GB" ,"S0211GS" ,"S0211HA" ,"S0211HB" ,"S0211HS" ,"S0219XA" ,"S0219XB" ,"S0219XS" ,"S0230XA" ,"S0230XB" ,"S0230XS" ,"S0231XA" ,"S0231XB" ,"S0231XS" ,"S0232XA" ,"S0232XB" ,"S0232XS" ,"S023XXA" ,"S023XXB" ,"S023XXS" ,"S02400A" ,"S02400B" ,"S02400S" ,"S02401A" ,"S02401B" ,"S02401S" ,"S02402A" ,"S02402B" ,"S02402S" ,"S0240AA" ,"S0240AB" ,"S0240AS" ,"S0240BA" ,"S0240BB" ,"S0240BS" ,"S0240CA"
  ,"S0240CB" ,"S0240CS" ,"S0240DA" ,"S0240DB" ,"S0240DS" ,"S0240EA" ,"S0240EB" ,"S0240ES" ,"S0240FA" ,"S0240FB" ,"S0240FS" ,"S02411A" ,"S02411B" ,"S02411S" ,"S02412A" ,"S02412B" ,"S02412S" ,"S02413A" ,"S02413B" ,"S02413S" ,"S0242XA" ,"S0242XB" ,"S0242XS" ,"S02600A" ,"S02600B" ,"S02600S" ,"S02601A" ,"S02601B" ,"S02601S" ,"S02602A" ,"S02602B" ,"S02602S" ,"S02609A" ,"S02609B" ,"S02609S" ,"S02610A" ,"S02610B" ,"S02610S" ,"S02611A" ,"S02611B" ,"S02611S" ,"S02612A" ,"S02612B" ,"S02612S" ,"S0261XA" ,"S0261XB" ,"S0261XS" ,"S02620A" ,"S02620B" ,"S02620S" ,"S02621A" ,"S02621B" ,"S02621S" ,"S02622A" ,"S02622B" ,"S02622S" ,"S0262XA" ,"S0262XB" ,"S0262XS" ,"S02630A" ,"S02630B" ,"S02630S" ,"S02631A" ,"S02631B" ,"S02631S" ,"S02632A" ,"S02632B" ,"S02632S" ,"S0263XA" ,"S0263XB" ,"S0263XS" ,"S02640A" ,"S02640B" ,"S02640S" ,"S02641A" ,"S02641B" ,"S02641S" ,"S02642A" ,"S02642B" ,"S02642S" ,"S0264XA" ,"S0264XB" ,"S0264XS" ,"S02650A" ,"S02650B" ,"S02650S" ,"S02651A" ,"S02651B" ,"S02651S" ,"S02652A"
   ,"S02652B" ,
"S02652S" ,"S0265XA" ,"S0265XB" ,"S0265XS" ,"S0266XA" ,"S0266XB" ,"S0266XS" ,"S02670A" ,"S02670B" ,"S02670S" ,"S02671A" ,"S02671B" ,"S02671S" ,"S02672A" ,"S02672B" ,"S02672S" ,"S0267XA" ,"S0267XB" ,"S0267XS" ,"S0269XA" ,"S0269XB" ,"S0269XS" ,"S0280XA" ,"S0280XB" ,"S0280XS" ,"S0281XA" ,"S0281XB" ,"S0281XS" ,"S0282XA" ,"S0282XB" ,"S0282XS" ,"S028XXA" ,"S028XXB" ,"S028XXS" ,"S0291XA" ,"S0291XB" ,"S0291XS" ,"S0292XA" ,"S0292XB" ,"S0292XS" ,"S060X0S" ,"S060X1S" ,"S060X2S" ,"S060X3A" ,"S060X3S" ,"S060X4A" ,"S060X4S" ,"S060X5A" ,"S060X5S" ,"S060X6A" ,"S060X6S" ,"S060X9S" ,"S061X0A" ,"S061X0S" ,"S061X1A" ,"S061X1S" ,"S061X2A" ,"S061X2S" ,"S061X3S" ,"S061X4S" ,"S061X5S" ,"S061X6S" ,"S061X9A" ,"S061X9S" ,"S062X0A" ,"S062X0S" ,"S062X1A" ,"S062X1S" ,"S062X2A" ,"S062X2S" ,"S062X3S" ,"S062X4S" ,"S062X5S" ,"S062X6S" ,"S062X9A" ,"S062X9S" ,"S06300A" ,"S06300S" ,"S06301A" ,"S06301S" ,"S06302A" ,"S06302S" ,"S06303S" ,"S06304S" ,"S06305S" ,"S06306S" ,"S06309A" ,"S06309S" ,"S06310A" ,"S06310S" ,"S06311A"
,"S06311S" ,"S06312A" ,"S06312S" ,"S06313S" ,"S06314S" ,"S06315S" ,"S06316S" ,"S06319A" ,"S06319S" ,"S06320A" ,"S06320S" ,"S06321A" ,"S06321S" ,"S06322A" ,"S06322S" ,"S06323S" ,"S06324S" ,"S06325S" ,"S06326S" ,"S06329A" ,"S06329S" ,"S06330A" ,"S06330S" ,"S06331A" ,"S06331S" ,"S06332A" ,"S06332S" ,"S06333S" ,"S06334S" ,"S06335S" ,"S06336S" ,"S06339A" ,"S06339S" ,"S06340A" ,"S06340S" ,"S06341A" ,"S06341S" ,"S06342A" ,"S06342S" ,"S06343S" ,"S06344S" ,"S06345S" ,"S06346S" ,"S06349A" ,"S06349S" ,"S06350A" ,"S06350S" ,"S06351A" ,"S06351S" ,"S06352A" ,"S06352S" ,"S06353S" ,"S06354S" ,"S06355S" ,"S06356S" ,"S06359A" ,"S06359S" ,"S06360A" ,"S06360S" ,"S06361A" ,"S06361S" ,"S06362A" ,"S06362S" ,"S06363S" ,"S06364S" ,"S06365S" ,"S06366S" ,"S06369A" ,"S06369S" ,"S06370A" ,"S06370S" ,"S06371A" ,"S06371S" ,"S06372A" ,"S06372S" ,"S06373S" ,"S06374S" ,"S06375S" ,"S06376S" ,"S06379A" ,"S06379S" ,"S06380A" ,"S06380S" ,"S06381A" ,"S06381S" ,"S06382A" ,"S06382S" ,"S06383S" ,"S06384S" ,"S06385S" ,"S06386S"
 ,"S06389A" ,"S06389S" ,"S064X0A" ,"S064X0S" ,"S064X1A" ,"S064X1S" ,"S064X2A" ,"S064X2S" ,"S064X3S" ,"S064X4S" ,"S064X5S" ,"S064X6S" ,"S064X9A" ,"S064X9S" ,"S065X0A" ,"S065X0S" ,"S065X1A" ,"S065X1S" ,"S065X2A" ,"S065X2S" ,"S065X3S" ,"S065X4S" ,"S065X5S" ,"S065X6S" ,"S065X9A" ,"S065X9S" ,"S066X0A" ,"S066X0S" ,"S066X1A" ,"S066X1S" ,"S066X2A" ,"S066X2S" ,"S066X3S" ,"S066X4S" ,"S066X5S" ,"S066X6S" ,"S066X9A" ,"S066X9S" ,"S06810A" ,"S06810S" ,"S06811A" ,"S06811S" ,"S06812A" ,"S06812S" ,"S06813S" ,"S06814S" ,"S06815S" ,"S06816S" ,"S06819A" ,"S06819S" ,"S06820A" ,"S06820S" ,"S06821A" ,"S06821S" ,"S06822A" ,"S06822S" ,"S06823S" ,"S06824S" ,"S06825S" ,"S06826S" ,"S06829A" ,"S06829S" ,"S06890A" ,"S06890S" ,"S06891A" ,"S06891S" ,"S06892A" ,"S06892S" ,"S06893S" ,"S06894S" ,"S06895S" ,"S06896S" ,"S06899A" ,"S06899S" ,"S069X0A" ,"S069X0S" ,"S069X1A" ,"S069X1S" ,"S069X2A" ,"S069X2S" ,"S069X3S" ,"S069X4S" ,"S069X5S" ,"S069X6S" ,"S069X9A" ,"S069X9S"))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].DISCHARGE_CONDITION_CODE ="CC-167"
endif
 if (nom.source_identifier in ("M4850XA" ,"M4851XA" ,"M4852XA" ,"M4853XA" ,"M4854XA" ,"M4855XA" ,"M4856XA" ,"M4857XA" ,"M4858XA" ,"M8008XA" ,"M8088XA" ,"S12000A" ,"S12000B" ,"S12001A" ,"S12001B" ,"S1201XA" ,"S1201XB" ,"S1202XA" ,"S1202XB" ,"S12030A" ,"S12030B" ,"S12031A" ,"S12031B" ,"S12040A" ,"S12040B" ,"S12041A" ,"S12041B" ,"S12090A" ,"S12090B" ,"S12091A" ,"S12091B" ,"S12100A" ,"S12100B" ,"S12101A" ,"S12101B" ,"S12110A" ,"S12110B" ,"S12111A" ,"S12111B" ,"S12112A" ,"S12112B" ,"S12120A" ,"S12120B" ,"S12121A" ,"S12121B" ,"S12130A" ,"S12130B" ,"S12131A" ,"S12131B" ,"S1214XA" ,"S1214XB" ,"S12150A" ,"S12150B" ,"S12151A" ,"S12151B" ,"S12190A" ,"S12190B" ,"S12191A" ,"S12191B" ,"S12200A" ,"S12200B" ,"S12201A" ,"S12201B" ,"S12230A" ,"S12230B" ,"S12231A" ,"S12231B" ,"S1224XA" ,"S1224XB" ,"S12250A" ,"S12250B" ,"S12251A" ,"S12251B" ,"S12290A" ,"S12290B" ,"S12291A" ,"S12291B" ,"S12300A" ,"S12300B" ,"S12301A" ,"S12301B" ,"S12330A" ,"S12330B" ,"S12331A" ,"S12331B" ,"S1234XA" ,"S1234XB" ,"S12350A"
  ,"S12350B" ,"S12351A" ,"S12351B" ,"S12390A" ,"S12390B" ,"S12391A" ,"S12391B" ,"S12400A" ,"S12400B" ,"S12401A" ,"S12401B" ,"S12430A" ,"S12430B" ,"S12431A" ,"S12431B" ,"S1244XA" ,"S1244XB" ,"S12450A" ,"S12450B" ,"S12451A" ,"S12451B" ,"S12490A" ,"S12490B" ,"S12491A" ,"S12491B" ,"S12500A" ,"S12500B" ,"S12501A" ,"S12501B" ,"S12530A" ,"S12530B" ,"S12531A" ,"S12531B" ,"S1254XA" ,"S1254XB" ,"S12550A" ,"S12550B" ,"S12551A" ,"S12551B" ,"S12590A" ,"S12590B" ,"S12591A" ,"S12591B" ,"S12600A" ,"S12600B" ,"S12601A" ,"S12601B" ,"S12630A" ,"S12630B" ,"S12631A" ,"S12631B" ,"S1264XA" ,"S1264XB" ,"S12650A" ,"S12650B" ,"S12651A" ,"S12651B" ,"S12690A" ,"S12690B" ,"S12691A" ,"S12691B" ,"S128XXA" ,"S129XXA" ,"S22000A" ,"S22000B" ,"S22001A" ,"S22001B" ,"S22002A" ,"S22002B" ,"S22008A" ,"S22008B" ,"S22009A" ,"S22009B" ,"S22010A" ,"S22010B" ,"S22011A" ,"S22011B" ,"S22012A" ,"S22012B" ,"S22018A" ,"S22018B" ,"S22019A" ,"S22019B" ,"S22020A" ,"S22020B" ,"S22021A" ,"S22021B" ,"S22022A" ,"S22022B" ,"S22028A"
   ,"S22028B" ,
"S22029A" ,"S22029B" ,"S22030A" ,"S22030B" ,"S22031A" ,"S22031B" ,"S22032A" ,"S22032B" ,"S22038A" ,"S22038B" ,"S22039A" ,"S22039B" ,"S22040A" ,"S22040B" ,"S22041A" ,"S22041B" ,"S22042A" ,"S22042B" ,"S22048A" ,"S22048B" ,"S22049A" ,"S22049B" ,"S22050A" ,"S22050B" ,"S22051A" ,"S22051B" ,"S22052A" ,"S22052B" ,"S22058A" ,"S22058B" ,"S22059A" ,"S22059B" ,"S22060A" ,"S22060B" ,"S22061A" ,"S22061B" ,"S22062A" ,"S22062B" ,"S22068A" ,"S22068B" ,"S22069A" ,"S22069B" ,"S22070A" ,"S22070B" ,"S22071A" ,"S22071B" ,"S22072A" ,"S22072B" ,"S22078A" ,"S22078B" ,"S22079A" ,"S22079B" ,"S22080A" ,"S22080B" ,"S22081A" ,"S22081B" ,"S22082A" ,"S22082B" ,"S22088A" ,"S22088B" ,"S22089A" ,"S22089B" ,"S32000A" ,"S32000B" ,"S32001A" ,"S32001B" ,"S32002A" ,"S32002B" ,"S32008A" ,"S32008B" ,"S32009A" ,"S32009B" ,"S32010A" ,"S32010B" ,"S32011A" ,"S32011B" ,"S32012A" ,"S32012B" ,"S32018A" ,"S32018B" ,"S32019A" ,"S32019B" ,"S32020A" ,"S32020B" ,"S32021A" ,"S32021B" ,"S32022A" ,"S32022B" ,"S32028A" ,"S32028B" ,"S32029A"
,"S32029B" ,"S32030A" ,"S32030B" ,"S32031A" ,"S32031B" ,"S32032A" ,"S32032B" ,"S32038A" ,"S32038B" ,"S32039A" ,"S32039B" ,"S32040A" ,"S32040B" ,"S32041A" ,"S32041B" ,"S32042A" ,"S32042B" ,"S32048A" ,"S32048B" ,"S32049A" ,"S32049B" ,"S32050A" ,"S32050B" ,"S32051A" ,"S32051B" ,"S32052A" ,"S32052B" ,"S32058A" ,"S32058B" ,"S32059A" ,"S32059B" ,"S3210XA" ,"S3210XB" ,"S32110A" ,"S32110B" ,"S32111A" ,"S32111B" ,"S32112A" ,"S32112B" ,"S32119A" ,"S32119B" ,"S32120A" ,"S32120B" ,"S32121A" ,"S32121B" ,"S32122A" ,"S32122B" ,"S32129A" ,"S32129B" ,"S32130A" ,"S32130B" ,"S32131A" ,"S32131B" ,"S32132A" ,"S32132B" ,"S32139A" ,"S32139B" ,"S3214XA" ,"S3214XB" ,"S3215XA" ,"S3215XB" ,"S3216XA" ,"S3216XB" ,"S3217XA" ,"S3217XB" ,"S3219XA" ,"S3219XB" ,"S322XXA" ,"S322XXB"))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].DISCHARGE_CONDITION_CODE ="CC-169"
 ENDIF
 if (nom.source_identifier in ("E0800" ,"E0801" ,"E0810" ,"E0811" ,"E08641" ,"E0900" ,"E0901" ,"E0910" ,"E0911" ,"E09641" ,"E1010" ,"E1011" ,"E10641" ,"E1100" ,"E1101" ,"E1110" ,"E1111" ,"E11641" ,"E1300" ,"E1301" ,"E1310" ,"E1311" ,"E13641"))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].DISCHARGE_CONDITION_CODE ="CC-17"
endif
 if (nom.source_identifier in ("M80051A" ,"M80052A" ,"M80059A" ,"M80851A" ,"M80852A" ,"M80859A" ,"M84451A" ,"M84452A" ,"M84453A" ,"M84459A" ,"M84551A" ,"M84552A" ,"M84553A" ,"M84559A" ,"M84651A" ,"M84652A" ,"M84653A" ,"M84659A" ,"M84754A" ,"M84755A" ,"M84756A" ,"M84757A" ,"M84758A" ,"M84759A" ,"M9701XA" ,"M9702XA" ,"S32301A" ,"S32301B" ,"S32302A" ,"S32302B" ,"S32309A" ,"S32309B" ,"S32311A" ,"S32311B" ,"S32312A" ,"S32312B" ,"S32313A" ,"S32313B" ,"S32314A" ,"S32314B" ,"S32315A" ,"S32315B" ,"S32316A" ,"S32316B" ,"S32391A" ,"S32391B" ,"S32392A" ,"S32392B" ,"S32399A" ,"S32399B" ,"S32401A" ,"S32401B" ,"S32402A" ,"S32402B" ,"S32409A" ,"S32409B" ,"S32411A" ,"S32411B" ,"S32412A" ,"S32412B" ,"S32413A" ,"S32413B" ,"S32414A" ,"S32414B" ,"S32415A" ,"S32415B" ,"S32416A" ,"S32416B" ,"S32421A" ,"S32421B" ,"S32422A" ,"S32422B" ,"S32423A" ,"S32423B" ,"S32424A" ,"S32424B" ,"S32425A" ,"S32425B" ,"S32426A" ,"S32426B" ,"S32431A" ,"S32431B" ,"S32432A" ,"S32432B" ,"S32433A" ,"S32433B" ,"S32434A"
  ,"S32434B" ,"S32435A" ,"S32435B" ,"S32436A" ,"S32436B" ,"S32441A" ,"S32441B" ,"S32442A" ,"S32442B" ,"S32443A" ,"S32443B" ,"S32444A" ,"S32444B" ,"S32445A" ,"S32445B" ,"S32446A" ,"S32446B" ,"S32451A" ,"S32451B" ,"S32452A" ,"S32452B" ,"S32453A" ,"S32453B" ,"S32454A" ,"S32454B" ,"S32455A" ,"S32455B" ,"S32456A" ,"S32456B" ,"S32461A" ,"S32461B" ,"S32462A" ,"S32462B" ,"S32463A" ,"S32463B" ,"S32464A" ,"S32464B" ,"S32465A" ,"S32465B" ,"S32466A" ,"S32466B" ,"S32471A" ,"S32471B" ,"S32472A" ,"S32472B" ,"S32473A" ,"S32473B" ,"S32474A" ,"S32474B" ,"S32475A" ,"S32475B" ,"S32476A" ,"S32476B" ,"S32481A" ,"S32481B" ,"S32482A" ,"S32482B" ,"S32483A" ,"S32483B" ,"S32484A" ,"S32484B" ,"S32485A" ,"S32485B" ,"S32486A" ,"S32486B" ,"S32491A" ,"S32491B" ,"S32492A" ,"S32492B" ,"S32499A" ,"S32499B" ,"S32501A" ,"S32501B" ,"S32502A" ,"S32502B" ,"S32509A" ,"S32509B" ,"S32511A" ,"S32511B" ,"S32512A" ,"S32512B" ,"S32519A" ,"S32519B" ,"S32591A" ,"S32591B" ,"S32592A" ,"S32592B" ,"S32599A" ,"S32599B" ,"S32601A"
   ,"S32601B" ,"S32602A" ,
"S32602B" ,"S32609A" ,"S32609B" ,"S32611A" ,"S32611B" ,"S32612A" ,"S32612B" ,"S32613A" ,"S32613B" ,"S32614A" ,"S32614B" ,"S32615A" ,"S32615B" ,"S32616A" ,"S32616B" ,"S32691A" ,"S32691B" ,"S32692A" ,"S32692B" ,"S32699A" ,"S32699B" ,"S32810A" ,"S32810B" ,"S32811A" ,"S32811B" ,"S3282XA" ,"S3282XB" ,"S3289XA" ,"S3289XB" ,"S329XXA" ,"S329XXB" ,"S72001A" ,"S72001B" ,"S72001C" ,"S72002A" ,"S72002B" ,"S72002C" ,"S72009A" ,"S72009B" ,"S72009C" ,"S72011A" ,"S72011B" ,"S72011C" ,"S72012A" ,"S72012B" ,"S72012C" ,"S72019A" ,"S72019B" ,"S72019C" ,"S72021A" ,"S72021B" ,"S72021C" ,"S72022A" ,"S72022B" ,"S72022C" ,"S72023A" ,"S72023B" ,"S72023C" ,"S72024A" ,"S72024B" ,"S72024C" ,"S72025A" ,"S72025B" ,"S72025C" ,"S72026A" ,"S72026B" ,"S72026C" ,"S72031A" ,"S72031B" ,"S72031C" ,"S72032A" ,"S72032B" ,"S72032C" ,"S72033A" ,"S72033B" ,"S72033C" ,"S72034A" ,"S72034B" ,"S72034C" ,"S72035A" ,"S72035B" ,"S72035C" ,"S72036A" ,"S72036B" ,"S72036C" ,"S72041A" ,"S72041B" ,"S72041C" ,"S72042A" ,"S72042B" ,"S72042C"
,"S72043A" ,"S72043B" ,"S72043C" ,"S72044A" ,"S72044B" ,"S72044C" ,"S72045A" ,"S72045B" ,"S72045C" ,"S72046A" ,"S72046B" ,"S72046C" ,"S72051A" ,"S72051B" ,"S72051C" ,"S72052A" ,"S72052B" ,"S72052C" ,"S72059A" ,"S72059B" ,"S72059C" ,"S72061A" ,"S72061B" ,"S72061C" ,"S72062A" ,"S72062B" ,"S72062C" ,"S72063A" ,"S72063B" ,"S72063C" ,"S72064A" ,"S72064B" ,"S72064C" ,"S72065A" ,"S72065B" ,"S72065C" ,"S72066A" ,"S72066B" ,"S72066C" ,"S72091A" ,"S72091B" ,"S72091C" ,"S72092A" ,"S72092B" ,"S72092C" ,"S72099A" ,"S72099B" ,"S72099C" ,"S72101A" ,"S72101B" ,"S72101C" ,"S72102A" ,"S72102B" ,"S72102C" ,"S72109A" ,"S72109B" ,"S72109C" ,"S72111A" ,"S72111B" ,"S72111C" ,"S72112A" ,"S72112B" ,"S72112C" ,"S72113A" ,"S72113B" ,"S72113C" ,"S72114A" ,"S72114B" ,"S72114C" ,"S72115A" ,"S72115B" ,"S72115C" ,"S72116A" ,"S72116B" ,"S72116C" ,"S72121A" ,"S72121B" ,"S72121C" ,"S72122A" ,"S72122B" ,"S72122C" ,"S72123A" ,"S72123B" ,"S72123C" ,"S72124A" ,"S72124B" ,"S72124C" ,"S72125A" ,"S72125B" ,"S72125C" ,"S72126A"
 ,"S72126B" ,"S72126C" ,"S72131A" ,"S72131B" ,"S72131C" ,"S72132A" ,"S72132B" ,"S72132C" ,"S72133A" ,"S72133B" ,"S72133C" ,"S72134A" ,"S72134B" ,"S72134C" ,"S72135A" ,"S72135B" ,"S72135C" ,"S72136A" ,"S72136B" ,"S72136C" ,"S72141A" ,"S72141B" ,"S72141C" ,"S72142A" ,"S72142B" ,"S72142C" ,"S72143A" ,"S72143B" ,"S72143C" ,"S72144A" ,"S72144B" ,"S72144C" ,"S72145A" ,"S72145B" ,"S72145C" ,"S72146A" ,"S72146B" ,"S72146C" ,"S7221XA" ,"S7221XB" ,"S7221XC" ,"S7222XA" ,"S7222XB" ,"S7222XC" ,"S7223XA" ,"S7223XB" ,"S7223XC" ,"S7224XA" ,"S7224XB" ,"S7224XC" ,"S7225XA" ,"S7225XB" ,"S7225XC" ,"S7226XA" ,"S7226XB" ,"S7226XC" ,"S72301A" ,"S72301B" ,"S72301C" ,"S72302A" ,"S72302B" ,"S72302C" ,"S72309A" ,"S72309B" ,"S72309C" ,"S72321A" ,"S72321B" ,"S72321C" ,"S72322A" ,"S72322B" ,"S72322C" ,"S72323A" ,"S72323B" ,"S72323C" ,"S72324A" ,"S72324B" ,"S72324C" ,"S72325A" ,"S72325B" ,"S72325C" ,"S72326A" ,"S72326B" ,"S72326C" ,"S72331A" ,"S72331B" ,"S72331C" ,"S72332A" ,"S72332B" ,"S72332C" ,"S72333A"
  ,"S72333B" ,"S72333C" ,"S72334A" ,"S72334B" ,"S72334C" ,"S72335A" ,"S72335B" ,"S72335C" ,"S72336A" ,"S72336B" ,"S72336C" ,"S72341A" ,"S72341B" ,"S72341C" ,"S72342A" ,"S72342B" ,"S72342C" ,"S72343A" ,"S72343B" ,"S72343C" ,"S72344A" ,"S72344B" ,"S72344C" ,"S72345A" ,"S72345B" ,"S72345C" ,"S72346A" ,"S72346B" ,"S72346C" ,"S72351A" ,"S72351B" ,"S72351C" ,"S72352A" ,"S72352B" ,"S72352C" ,"S72353A" ,"S72353B" ,"S72353C" ,"S72354A" ,"S72354B" ,"S72354C" ,"S72355A" ,"S72355B" ,"S72355C" ,"S72356A" ,"S72356B" ,"S72356C" ,"S72361A" ,"S72361B" ,"S72361C" ,"S72362A" ,"S72362B" ,"S72362C" ,"S72363A" ,"S72363B" ,"S72363C" ,"S72364A" ,"S72364B" ,"S72364C" ,"S72365A" ,"S72365B" ,"S72365C" ,"S72366A" ,"S72366B" ,"S72366C" ,"S72391A" ,"S72391B" ,"S72391C" ,"S72392A" ,"S72392B" ,"S72392C" ,"S72399A" ,"S72399B" ,"S72399C" ,"S72401A" ,"S72401B" ,"S72401C" ,"S72402A" ,"S72402B" ,"S72402C" ,"S72409A" ,"S72409B" ,"S72409C" ,"S72411A" ,"S72411B" ,"S72411C" ,"S72412A" ,"S72412B" ,"S72412C" ,"S72413A"
   ,"S72413B" ,"S72413C" ,"S72414A" ,"S72414B" ,"S72414C" ,"S72415A" ,"S72415B" ,"S72415C" ,"S72416A" ,"S72416B" ,"S72416C" ,"S72421A" ,"S72421B" ,"S72421C" ,"S72422A" ,"S72422B" ,"S72422C" ,"S72423A" ,"S72423B" ,"S72423C" ,"S72424A" ,"S72424B" ,"S72424C" ,"S72425A" ,"S72425B" ,"S72425C" ,"S72426A" ,"S72426B" ,"S72426C" ,"S72431A" ,"S72431B" ,"S72431C" ,"S72432A" ,"S72432B" ,"S72432C" ,"S72433A" ,"S72433B" ,"S72433C" ,"S72434A" ,"S72434B" ,"S72434C" ,"S72435A" ,"S72435B" ,"S72435C" ,"S72436A" ,"S72436B" ,"S72436C" ,"S72441A" ,"S72441B" ,"S72441C" ,"S72442A" ,"S72442B" ,"S72442C" ,"S72443A" ,"S72443B" ,"S72443C" ,"S72444A" ,"S72444B" ,"S72444C" ,"S72445A" ,"S72445B" ,"S72445C" ,"S72446A" ,"S72446B" ,"S72446C" ,"S72451A" ,"S72451B" ,"S72451C" ,"S72452A" ,"S72452B" ,"S72452C" ,"S72453A" ,"S72453B" ,"S72453C" ,"S72454A" ,"S72454B" ,"S72454C" ,"S72455A" ,"S72455B" ,"S72455C" ,"S72456A" ,"S72456B" ,"S72456C" ,"S72461A" ,"S72461B" ,"S72461C" ,"S72462A" ,"S72462B" ,"S72462C" ,"S72463A"
    ,"S72463B" ,"S72463C" ,"S72464A" ,"S72464B" ,"S72464C" ,"S72465A" ,"S72465B" ,"S72465C" ,"S72466A" ,"S72466B" ,"S72466C" ,"S72471A" ,"S72472A" ,"S72479A" ,"S72491A" ,"S72491B" ,"S72491C" ,"S72492A" ,"S72492B" ,"S72492C" ,"S72499A" ,"S72499B" ,"S72499C" ,"S728X1A" ,"S728X1B" ,"S728X1C" ,"S728X2A" ,"S728X2B" ,"S728X2C" ,"S728X9A" ,"S728X9B" ,"S728X9C" ,"S7290XA" ,"S7290XB" ,"S7290XC" ,"S7291XA" ,"S7291XB" ,"S7291XC" ,"S7292XA" ,"S7292XB" ,"S7292XC" ,"S73001A" ,"S73002A" ,"S73003A" ,"S73004A" ,"S73005A" ,"S73006A" ,"S73011A" ,"S73012A" ,"S73013A" ,"S73014A" ,"S73015A" ,"S73016A" ,"S73021A" ,"S73022A" ,"S73023A" ,"S73024A" ,"S73025A" ,"S73026A" ,"S73031A" ,"S73032A" ,"S73033A" ,"S73034A" ,"S73035A" ,"S73036A" ,"S73041A" ,"S73042A" ,"S73043A" ,"S73044A" ,"S73045A" ,"S73046A" ,"S79001A" ,"S79002A" ,"S79009A" ,"S79011A" ,"S79012A" ,"S79019A" ,"S79091A" ,"S79092A" ,"S79099A" ,"S79101A" ,"S79102A" ,"S79109A" ,"S79111A" ,"S79112A" ,"S79119A" ,"S79121A" ,"S79122A" ,"S79129A" ,"S79131A"
     ,"S79132A" ,"S79139A" ,"S79141A" ,"S79142A" ,"S79149A" ,"S79191A" ,"S79192A" ,"S79199A"))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].DISCHARGE_CONDITION_CODE ="CC-170"
 ENDIF
 if (nom.source_identifier in ("S48011A" ,"S48012A" ,"S48019A" ,"S48021A" ,"S48022A" ,"S48029A" ,"S48111A" ,"S48112A" ,"S48119A" ,"S48121A" ,"S48122A" ,"S48129A" ,"S48911A" ,"S48912A" ,"S48919A" ,"S48921A" ,"S48922A" ,"S48929A" ,"S58011A" ,"S58012A" ,"S58019A" ,"S58021A" ,"S58022A" ,"S58029A" ,"S58111A" ,"S58112A" ,"S58119A" ,"S58121A" ,"S58122A" ,"S58129A" ,"S58911A" ,"S58912A" ,"S58919A" ,"S58921A" ,"S58922A" ,"S58929A" ,"S68411A" ,"S68412A" ,"S68419A" ,"S68421A" ,"S68422A" ,"S68429A" ,"S68711A" ,"S68712A" ,"S68719A" ,"S68721A" ,"S68722A" ,"S68729A" ,"S78011A" ,"S78012A" ,"S78019A" ,"S78021A" ,"S78022A" ,"S78029A" ,"S78111A" ,"S78112A" ,"S78119A" ,"S78121A" ,"S78122A" ,"S78129A" ,"S78911A" ,"S78912A" ,"S78919A" ,"S78921A" ,"S78922A" ,"S78929A" ,"S88011A" ,"S88012A" ,"S88019A" ,"S88021A" ,"S88022A" ,"S88029A" ,"S88111A" ,"S88112A" ,"S88119A" ,"S88121A" ,"S88122A" ,"S88129A" ,"S88911A" ,"S88912A" ,"S88919A" ,"S88921A" ,"S88922A" ,"S88929A" ,"S98011A" ,"S98012A" ,"S98019A" ,"S98021A"
  ,"S98022A" ,"S98029A" ,"S98111A" ,"S98112A" ,"S98119A" ,"S98121A" ,"S98122A" ,"S98129A" ,"S98131A" ,"S98132A" ,"S98139A" ,"S98141A" ,"S98142A" ,"S98149A" ,"S98211A" ,"S98212A" ,"S98219A" ,"S98221A" ,"S98222A" ,"S98229A" ,"S98311A" ,"S98312A" ,"S98319A" ,"S98321A" ,"S98322A" ,"S98329A" ,"S98911A" ,"S98912A" ,"S98919A" ,"S98921A" ,"S98922A" ,"S98929A" ,"T790XXA" ,"T791XXA" ,"T792XXA" ,"T794XXA" ,"T795XXA" ,"T796XXA" ,"T797XXA" ,"T798XXA" ,"T799XXA" ,"T79A0XA" ,"T79A11A" ,"T79A12A" ,"T79A19A" ,"T79A21A" ,"T79A22A" ,"T79A29A" ,"T79A3XA" ,"T79A9XA" ,"T870X1" ,"T870X2" ,"T870X9" ,"T871X1" ,"T871X2" ,"T871X9" ,"T872"))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].DISCHARGE_CONDITION_CODE ="CC-173"
endif
 if (nom.source_identifier in ("M96621" ,"M96622" ,"M96629" ,"M96631" ,"M96632" ,"M96639" ,"M9665" ,"M96661" ,"M96662" ,"M96669" ,"M96671" ,"M96672" ,"M96679" ,"M9669" ,"N99510" ,"N99511" ,"N99512" ,"N99518" ,"N99520" ,"N99521" ,"N99522" ,"N99523" ,"N99524" ,"N99528" ,"N99530" ,"N99531" ,"N99532" ,"N99533" ,"N99534" ,"N99538" ,"T82310A" ,"T82311A" ,"T82312A" ,"T82318A" ,"T82319A" ,"T82320A" ,"T82321A" ,"T82322A" ,"T82328A" ,"T82329A" ,"T82330A" ,"T82331A" ,"T82332A" ,"T82338A" ,"T82339A" ,"T82390A" ,"T82391A" ,"T82392A" ,"T82398A" ,"T82399A" ,"T82510A" ,"T82511A" ,"T82513A" ,"T82514A" ,"T82515A" ,"T82518A" ,"T82520A" ,"T82521A" ,"T82523A" ,"T82524A" ,"T82525A" ,"T82528A" ,"T82530A" ,"T82531A" ,"T82533A" ,"T82534A" ,"T82535A" ,"T82538A" ,"T82590A" ,"T82591A" ,"T82593A" ,"T82594A" ,"T82595A" ,"T82598A" ,"T826XXA" ,"T827XXA" ,"T82818A" ,"T82828A" ,"T82838A" ,"T82848A" ,"T82856A" ,"T82858A" ,"T82868A" ,"T82898A" ,"T83010A" ,"T83011A" ,"T83012A" ,"T83018A" ,"T83020A" ,"T83021A" ,"T83022A" ,
"T83028A" ,"T83030A" ,"T83031A" ,"T83032A" ,"T83038A" ,"T83090A" ,"T83091A" ,"T83092A" ,"T83098A" ,"T83110A" ,"T83111A" ,"T83112A" ,"T83113A" ,"T83118A" ,"T83120A" ,"T83121A" ,"T83122A" ,"T83123A" ,"T83128A" ,"T83190A" ,"T83191A" ,"T83192A" ,"T83193A" ,"T83198A" ,"T8321XA" ,"T8322XA" ,"T8323XA" ,"T8324XA" ,"T8325XA" ,"T8329XA" ,"T83410A" ,"T83411A" ,"T83418A" ,"T83420A" ,"T83421A" ,"T83428A" ,"T83490A" ,"T83491A" ,"T83498A" ,"T83510A" ,"T83511A" ,"T83512A" ,"T83518A" ,"T8351XA" ,"T83590A" ,"T83591A" ,"T83592A" ,"T83593A" ,"T83598A" ,"T8359XA" ,"T8361XA" ,"T8362XA" ,"T8369XA" ,"T836XXA" ,"T83711A" ,"T83712A" ,"T83713A" ,"T83714A" ,"T83718A" ,"T83719A" ,"T83721A" ,"T83722A" ,"T83723A" ,"T83724A" ,"T83728A" ,"T83729A" ,"T8379XA" ,"T8381XA" ,"T8382XA" ,"T8383XA" ,"T8384XA" ,"T8385XA" ,"T8386XA" ,"T8389XA" ,"T839XXA" ,"T84010A" ,"T84011A" ,"T84012A" ,"T84013A" ,"T84018A" ,"T84019A" ,"T84020A" ,"T84021A" ,"T84022A" ,"T84023A" ,"T84028A" ,"T84029A" ,"T84030A" ,"T84031A" ,"T84032A" ,"T84033A"
,"T84038A" ,"T84039A" ,"T84040A" ,"T84041A" ,"T84042A" ,"T84043A" ,"T84048A" ,"T84049A" ,"T84050A" ,"T84051A" ,"T84052A" ,"T84053A" ,"T84058A" ,"T84059A" ,"T84060A" ,"T84061A" ,"T84062A" ,"T84063A" ,"T84068A" ,"T84069A" ,"T84090A" ,"T84091A" ,"T84092A" ,"T84093A" ,"T84098A" ,"T84099A" ,"T84110A" ,"T84111A" ,"T84112A" ,"T84113A" ,"T84114A" ,"T84115A" ,"T84116A" ,"T84117A" ,"T84119A" ,"T84120A" ,"T84121A" ,"T84122A" ,"T84123A" ,"T84124A" ,"T84125A" ,"T84126A" ,"T84127A" ,"T84129A" ,"T84190A" ,"T84191A" ,"T84192A" ,"T84193A" ,"T84194A" ,"T84195A" ,"T84196A" ,"T84197A" ,"T84199A" ,"T84210A" ,"T84213A" ,"T84216A" ,"T84218A" ,"T84220A" ,"T84223A" ,"T84226A" ,"T84228A" ,"T84290A" ,"T84293A" ,"T84296A" ,"T84298A" ,"T84310A" ,"T84318A" ,"T84320A" ,"T84328A" ,"T84390A" ,"T84398A" ,"T84410A" ,"T84418A" ,"T84420A" ,"T84428A" ,"T84490A" ,"T84498A" ,"T8450XA" ,"T8451XA" ,"T8452XA" ,"T8453XA" ,"T8454XA" ,"T8459XA" ,"T8460XA" ,"T84610A" ,"T84611A" ,"T84612A" ,"T84613A" ,"T84614A" ,"T84615A" ,"T84619A"
 ,"T84620A" ,"T84621A" ,"T84622A" ,"T84623A" ,"T84624A" ,"T84625A" ,"T84629A" ,"T8463XA" ,"T8469XA" ,"T847XXA" ,"T8481XA" ,"T8482XA" ,"T8483XA" ,"T8484XA" ,"T8485XA" ,"T8486XA" ,"T8489XA" ,"T849XXA" ,"T8501XA" ,"T8502XA" ,"T8503XA" ,"T8509XA" ,"T85110A" ,"T85111A" ,"T85112A" ,"T85113A" ,"T85118A" ,"T85120A" ,"T85121A" ,"T85122A" ,"T85123A" ,"T85128A" ,"T85190A" ,"T85191A" ,"T85192A" ,"T85193A" ,"T85199A" ,"T85615A" ,"T85625A" ,"T85635A" ,"T85695A" ,"T8572XA" ,"T85730A" ,"T85731A" ,"T85732A" ,"T85733A" ,"T85734A" ,"T85735A" ,"T85738A" ,"T8579XA" ,"T85810A" ,"T85820A" ,"T85830A" ,"T85840A" ,"T85850A" ,"T85860A" ,"T85890A" ,"T86842"))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].DISCHARGE_CONDITION_CODE ="CC-176"
 ENDIF
 if (nom.source_identifier in ("E0821" ,"E0822" ,"E0829" ,"E08311" ,"E08319" ,"E08321" ,"E083211" ,"E083212" ,"E083213" ,"E083219" ,"E08329" ,"E083291" ,"E083292" ,"E083293" ,"E083299" ,"E08331" ,"E083311" ,"E083312" ,"E083313" ,"E083319" ,"E08339" ,"E083391" ,"E083392" ,"E083393" ,"E083399" ,"E08341" ,"E083411" ,"E083412" ,"E083413" ,"E083419" ,"E08349" ,"E083491" ,"E083492" ,"E083493" ,"E083499" ,"E08351" ,"E083511" ,"E083512" ,"E083513" ,"E083519" ,"E083521" ,"E083522" ,"E083523" ,"E083529" ,"E083531" ,"E083532" ,"E083533" ,"E083539" ,"E083541" ,"E083542" ,"E083543" ,"E083549" ,"E083551" ,"E083552" ,"E083553" ,"E083559" ,"E08359" ,"E083591" ,"E083592" ,"E083593" ,"E083599" ,"E0836" ,"E0837X1" ,"E0837X2" ,"E0837X3" ,"E0837X9" ,"E0839" ,"E0840" ,"E0841" ,"E0842" ,"E0843" ,"E0844" ,"E0849" ,"E0851" ,"E0852" ,"E0859" ,"E08610" ,"E08618" ,"E08620" ,"E08621" ,"E08622" ,"E08628" ,"E08630" ,"E08638" ,"E08649" ,"E0865" ,"E0869" ,"E088" ,"E0921" ,"E0922" ,"E0929" ,"E09311" ,"E09319" ,"E09321"
 ,"E093211" ,"E093212" ,"E093213" ,"E093219" ,"E09329" ,"E093291" ,"E093292" ,"E093293" ,"E093299" ,"E09331" ,"E093311" ,"E093312" ,"E093313" ,"E093319" ,"E09339" ,"E093391" ,"E093392" ,"E093393" ,"E093399" ,"E09341" ,"E093411" ,"E093412" ,"E093413" ,"E093419" ,"E09349" ,"E093491" ,"E093492" ,"E093493" ,"E093499" ,"E09351" ,"E093511" ,"E093512" ,"E093513" ,"E093519" ,"E093521" ,"E093522" ,"E093523" ,"E093529" ,"E093531" ,"E093532" ,"E093533" ,"E093539" ,"E093541" ,"E093542" ,"E093543" ,"E093549" ,"E093551" ,"E093552" ,"E093553" ,"E093559" ,"E09359" ,"E093591" ,"E093592" ,"E093593" ,"E093599" ,"E0936" ,"E0937X1" ,"E0937X2" ,"E0937X3" ,"E0937X9" ,"E0939" ,"E0940" ,"E0941" ,"E0942" ,"E0943" ,"E0944" ,"E0949" ,"E0951" ,"E0952" ,"E0959" ,"E09610" ,"E09618" ,"E09620" ,"E09621" ,"E09622" ,"E09628" ,"E09630" ,"E09638" ,"E09649" ,"E0965" ,"E0969" ,"E098" ,"E1021" ,"E1022" ,"E1029" ,"E10311" ,"E10319" ,"E10321" ,"E103211" ,"E103212" ,"E103213" ,"E103219" ,"E10329" ,"E103291" ,"E103292"
 ,"E103293" ,"E103299" ,"E10331" ,"E103311" ,"E103312" ,"E103313" ,"E103319" ,"E10339" ,"E103391" ,"E103392" ,"E103393" ,"E103399" ,"E10341" ,"E103411" ,"E103412" ,"E103413" ,"E103419" ,"E10349" ,"E103491" ,"E103492" ,"E103493" ,"E103499" ,"E10351" ,"E103511" ,"E103512" ,"E103513" ,"E103519" ,"E103521" ,"E103522" ,"E103523" ,"E103529" ,"E103531" ,"E103532" ,"E103533" ,"E103539" ,"E103541" ,"E103542" ,"E103543" ,"E103549" ,"E103551" ,"E103552" ,"E103553" ,"E103559" ,"E10359" ,"E103591" ,"E103592" ,"E103593" ,"E103599" ,"E1036" ,"E1037X1" ,"E1037X2" ,"E1037X3" ,"E1037X9" ,"E1039" ,"E1040" ,"E1041" ,"E1042" ,"E1043" ,"E1044" ,"E1049" ,"E1051" ,"E1052" ,"E1059" ,"E10610" ,"E10618" ,"E10620" ,"E10621" ,"E10622" ,"E10628" ,"E10630" ,"E10638" ,"E10649" ,"E1065" ,"E1069" ,"E108" ,"E1121" ,"E1122" ,"E1129" ,"E11311" ,"E11319" ,"E11321" ,"E113211" ,"E113212" ,"E113213" ,"E113219" ,"E11329" ,"E113291" ,"E113292" ,"E113293" ,"E113299" ,"E11331" ,"E113311" ,"E113312" ,"E113313" ,"E113319" ,"E11339"
 ,"E113391" ,"E113392" ,"E113393" ,"E113399" ,"E11341" ,"E113411" ,"E113412" ,"E113413" ,"E113419" ,"E11349" ,"E113491" ,"E113492" ,"E113493" ,"E113499" ,"E11351" ,"E113511" ,"E113512" ,"E113513" ,"E113519" ,"E113521" ,"E113522" ,"E113523" ,"E113529" ,"E113531" ,"E113532" ,"E113533" ,"E113539" ,"E113541" ,"E113542" ,"E113543" ,"E113549" ,"E113551" ,"E113552" ,"E113553" ,"E113559" ,"E11359" ,"E113591" ,"E113592" ,"E113593" ,"E113599" ,"E1136" ,"E1137X1" ,"E1137X2" ,"E1137X3" ,"E1137X9" ,"E1139" ,"E1140" ,"E1141" ,"E1142" ,"E1143" ,"E1144" ,"E1149" ,"E1151" ,"E1152" ,"E1159" ,"E11610" ,"E11618" ,"E11620" ,"E11621" ,"E11622" ,"E11628" ,"E11630" ,"E11638" ,"E11649" ,"E1165" ,"E1169" ,"E118" ,"E1321" ,"E1322" ,"E1329" ,"E13311" ,"E13319" ,"E13321" ,"E133211" ,"E133212" ,"E133213" ,"E133219" ,"E13329" ,"E133291" ,"E133292" ,"E133293" ,"E133299" ,"E13331" ,"E133311" ,"E133312" ,"E133313" ,"E133319" ,"E13339" ,"E133391" ,"E133392" ,"E133393" ,"E133399" ,"E13341" ,"E133411" ,"E133412"
  ,"E133413"
,"E133419" ,"E13349" ,"E133491" ,"E133492" ,"E133493" ,"E133499" ,"E13351" ,"E133511" ,"E133512" ,"E133513" ,"E133519" ,"E133521" ,"E133522" ,"E133523" ,"E133529" ,"E133531" ,"E133532" ,"E133533" ,"E133539" ,"E133541" ,"E133542" ,"E133543" ,"E133549" ,"E133551" ,"E133552" ,"E133553" ,"E133559" ,"E13359" ,"E133591" ,"E133592" ,"E133593" ,"E133599" ,"E1336" ,"E1337X1" ,"E1337X2" ,"E1337X3" ,"E1337X9" ,"E1339" ,"E1340" ,"E1341" ,"E1342" ,"E1343" ,"E1344" ,"E1349" ,"E1351" ,"E1352" ,"E1359" ,"E13610" ,"E13618" ,"E13620" ,"E13621" ,"E13622" ,"E13628" ,"E13630" ,"E13638" ,"E13649" ,"E1365" ,"E1369" ,"E138"))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].DISCHARGE_CONDITION_CODE ="CC-18"
endif
 if (nom.source_identifier in ("T8600" ,"T8601" ,"T8602" ,"T8603" ,"T8609" ,"T8620" ,"T8621" ,"T8622" ,"T8623" ,"T86290" ,"T86298" ,"T8630" ,"T8631" ,"T8632" ,"T8633" ,"T8639" ,"T8640" ,"T8641" ,"T8642" ,"T8643" ,"T8649" ,"T865" ,"T86810" ,"T86811" ,"T86812" ,"T86818" ,"T86819" ,"T86850" ,"T86851" ,"T86852" ,"T86858" ,"T86859" ,"Z4821" ,"Z4823" ,"Z4824" ,"Z48280" ,"Z48290" ,"Z941" ,"Z942" ,"Z943" ,"Z944" ,"Z9481" ,"Z9482" ,"Z9483" ,"Z9484" ,"Z95811" ,"Z95812"))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].DISCHARGE_CONDITION_CODE ="CC-186"
 ENDIF
 if (nom.source_identifier in ("K91850" ,"K91858" ,"K9400" ,"K9401" ,"K9402" ,"K9403" ,"K9409" ,"K9410" ,"K9411" ,"K9412" ,"K9413" ,"K9419" ,"K9420" ,"K9421" ,"K9422" ,"K9423" ,"K9429" ,"K9430" ,"K9431" ,"K9432" ,"K9433" ,"K9439" ,"Z431" ,"Z432" ,"Z433" ,"Z434" ,"Z435" ,"Z436" ,"Z438" ,"Z439" ,"Z931" ,"Z932" ,"Z933" ,"Z934" ,"Z9350" ,"Z9351" ,"Z9352" ,"Z9359" ,"Z936" ,"Z938" ,"Z939"))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].DISCHARGE_CONDITION_CODE ="CC-188"
endif
 if (nom.source_identifier in ("G546" ,"G547" ,"S48011S" ,"S48012S" ,"S48019S" ,"S48021S" ,"S48022S" ,"S48029S" ,"S48111S" ,"S48112S" ,"S48119S" ,"S48121S" ,"S48122S" ,"S48129S" ,"S48911S" ,"S48912S" ,"S48919S" ,"S48921S" ,"S48922S" ,"S48929S" ,"S58011S" ,"S58012S" ,"S58019S" ,"S58021S" ,"S58022S" ,"S58029S" ,"S58111S" ,"S58112S" ,"S58119S" ,"S58121S" ,"S58122S" ,"S58129S" ,"S58911S" ,"S58912S" ,"S58919S" ,"S58921S" ,"S58922S" ,"S58929S" ,"S68011S" ,"S68012S" ,"S68019S" ,"S68021S" ,"S68022S" ,"S68029S" ,"S68110S" ,"S68111S" ,"S68112S" ,"S68113S" ,"S68114S" ,"S68115S" ,"S68116S" ,"S68117S" ,"S68118S" ,"S68119S" ,"S68120S" ,"S68121S" ,"S68122S" ,"S68123S" ,"S68124S" ,"S68125S" ,"S68126S" ,"S68127S" ,"S68128S" ,"S68129S" ,"S68411S" ,"S68412S" ,"S68419S" ,"S68421S" ,"S68422S" ,"S68429S" ,"S68511S" ,"S68512S" ,"S68519S" ,"S68521S" ,"S68522S" ,"S68529S" ,"S68610S" ,"S68611S" ,"S68612S" ,"S68613S" ,"S68614S" ,"S68615S" ,"S68616S" ,"S68617S" ,"S68618S" ,"S68619S" ,"S68620S" ,"S68621S"
  ,"S68622S" ,"S68623S" ,"S68624S" ,"S68625S" ,"S68626S" ,"S68627S" ,"S68628S" ,"S68629S" ,"S68711S" ,"S68712S" ,"S68719S" ,"S68721S" ,"S68722S" ,"S68729S" ,"S78011D" ,"S78011S" ,"S78012D" ,"S78012S" ,"S78019D" ,"S78019S" ,"S78021D" ,"S78021S" ,"S78022D" ,"S78022S" ,"S78029D" ,"S78029S" ,"S78111D" ,"S78111S" ,"S78112D" ,"S78112S" ,"S78119D" ,"S78119S" ,"S78121D" ,"S78121S" ,"S78122D" ,"S78122S" ,"S78129D" ,"S78129S" ,"S78911D" ,"S78911S" ,"S78912D" ,"S78912S" ,"S78919D" ,"S78919S" ,"S78921D" ,"S78921S" ,"S78922D" ,"S78922S" ,"S78929D" ,"S78929S" ,"S88011D" ,"S88011S" ,"S88012D" ,"S88012S" ,"S88019D" ,"S88019S" ,"S88021D" ,"S88021S" ,"S88022D" ,"S88022S" ,"S88029D" ,"S88029S" ,"S88111D" ,"S88111S" ,"S88112D" ,"S88112S" ,"S88119D" ,"S88119S" ,"S88121D" ,"S88121S" ,"S88122D" ,"S88122S" ,"S88129D" ,"S88129S" ,"S88911D" ,"S88911S" ,"S88912D" ,"S88912S" ,"S88919D" ,"S88919S" ,"S88921D" ,"S88921S" ,"S88922D" ,"S88922S" ,"S88929D" ,"S88929S" ,"S98011D" ,"S98011S" ,"S98012D" ,"S98012S"
   ,"S98019D" ,"S98019S" ,"S98021D" ,"S98021S" ,"S98022D" ,"S98022S" ,"S98029D" ,"S98029S" ,"S98111D" ,"S98111S" ,"S98112D" ,"S98112S" ,"S98119D" ,"S98119S" ,"S98121D" ,"S98121S" ,"S98122D" ,"S98122S" ,"S98129D" ,"S98129S" ,"S98131D" ,"S98131S" ,"S98132D" ,"S98132S" ,"S98139D" ,"S98139S" ,"S98141D" ,"S98141S" ,"S98142D" ,"S98142S" ,"S98149D" ,"S98149S" ,"S98211D" ,"S98211S" ,"S98212D" ,"S98212S" ,"S98219D" ,"S98219S" ,"S98221D" ,"S98221S" ,"S98222D" ,"S98222S" ,"S98229D" ,"S98229S" ,"S98311D" ,"S98311S" ,"S98312D" ,"S98312S" ,"S98319D" ,"S98319S" ,"S98321D" ,"S98321S" ,"S98322D" ,"S98322S" ,"S98329D" ,"S98329S" ,"S98911D" ,"S98911S" ,"S98912D" ,"S98912S" ,"S98919D" ,"S98919S" ,"S98921D" ,"S98921S" ,"S98922D" ,"S98922S" ,"S98929D" ,"S98929S" ,"T8730" ,"T8731" ,"T8732" ,"T8733" ,"T8734" ,"T8740" ,"T8741" ,"T8742" ,"T8743" ,"T8744" ,"T8750" ,"T8751" ,"T8752" ,"T8753" ,"T8754" ,"T8781" ,"T8789" ,"T879" ,"Z44101" ,"Z44102" ,"Z44109" ,"Z44111" ,"Z44112" ,"Z44119" ,"Z44121" ,"Z44122"
    ,"Z44129" ,"Z89411" ,"Z89412"
 ,"Z89419" ,"Z89421" ,"Z89422" ,"Z89429" ,"Z89431" ,"Z89432" ,"Z89439" ,"Z89441" ,"Z89442" ,"Z89449" ,"Z89511" ,"Z89512" ,"Z89519" ,"Z89611" ,"Z89612" ,"Z89619"))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].DISCHARGE_CONDITION_CODE ="CC-189"
 ENDIF
 if (nom.source_identifier in (
"E089"
,"E099"
,"E109"
,"E119"
,"E139"
,"Z794"
))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].DISCHARGE_CONDITION_CODE ="CC-19"
endif
 if (nom.source_identifier in ("A021" ,"A207" ,"A227" ,"A267" ,"A327" ,"A392" ,"A393" ,"A394" ,"A400" ,"A401" ,"A403" ,"A408" ,"A409" ,"A4101" ,"A4102" ,"A411" ,"A412" ,"A413" ,"A414" ,"A4150" ,"A4151" ,"A4152" ,"A4153" ,"A4159" ,"A4181" ,"A4189" ,"A419" ,"A427" ,"A483" ,"A5486" ,"B007" ,"B377" ,"P0270" ,"P360" ,"P3610" ,"P3619" ,"P362" ,"P3630" ,"P3639" ,"P364" ,"P365" ,"P368" ,"P369" ,"R571" ,"R578" ,"R6510" ,"R6511" ,"R6520" ,"R6521" ,"T8112XA" ,"T8144XA"))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].DISCHARGE_CONDITION_CODE ="CC-2"
 ENDIF
 if (nom.source_identifier in ("E40" ,"E41" ,"E42" ,"E43" ,"E440" ,"E441" ,"E45" ,"E46" ,"E640" ,"R64"
))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].DISCHARGE_CONDITION_CODE ="CC-21"
endif
 if (nom.source_identifier in ("E6601" ,"E662" ,"Z6841" ,"Z6842" ,"Z6843" ,"Z6844" ,"Z6845"))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].DISCHARGE_CONDITION_CODE ="CC-22"
 ENDIF
 if (nom.source_identifier in ("A391" ,"C880" ,"D841" ,"D891" ,"E035" ,"E15" ,"E200" ,"E208" ,"E209" ,"E210" ,"E211" ,"E212" ,"E213" ,"E214" ,"E215" ,"E220" ,"E221" ,"E222" ,"E228" ,"E229" ,"E230" ,"E231" ,"E232" ,"E233" ,"E236" ,"E237" ,"E240" ,"E241" ,"E242" ,"E243" ,"E244" ,"E248" ,"E249" ,"E250" ,"E258" ,"E259" ,"E2601" ,"E2602" ,"E2609" ,"E261" ,"E2681" ,"E2689" ,"E269" ,"E270" ,"E271" ,"E272" ,"E273" ,"E2740" ,"E2749" ,"E275" ,"E278" ,"E279" ,"E310" ,"E311" ,"E3120" ,"E3121" ,"E3122" ,"E3123" ,"E318" ,"E319" ,"E320" ,"E321" ,"E328" ,"E329" ,"E344" ,"E700" ,"E701" ,"E7020" ,"E7021" ,"E7029" ,"E7030" ,"E70310" ,"E70311" ,"E70318" ,"E70319" ,"E70320" ,"E70321" ,"E70328" ,"E70329" ,"E70330" ,"E70331" ,"E70338" ,"E70339" ,"E7039" ,"E7040" ,"E7041" ,"E7049" ,"E705" ,"E708" ,"E709" ,"E710" ,"E71110" ,"E71111" ,"E71118" ,"E71120" ,"E71121" ,"E71128" ,"E7119" ,"E712" ,"E71310" ,"E71311" ,"E71312" ,"E71313" ,"E71314" ,"E71318" ,"E7132" ,"E7139" ,"E7140" ,"E7141" ,"E7142" ,"E7143" ,"E71440"
 ,"E71448" ,"E7150" ,"E71510" ,"E71511" ,"E71518" ,"E71520" ,"E71521" ,"E71522" ,"E71528" ,"E71529" ,"E7153" ,"E71540" ,"E71541" ,"E71542" ,"E71548" ,"E7200" ,"E7201" ,"E7202" ,"E7203" ,"E7204" ,"E7209" ,"E7210" ,"E7211" ,"E7212" ,"E7219" ,"E7220" ,"E7221" ,"E7222" ,"E7223" ,"E7229" ,"E723" ,"E724" ,"E7250" ,"E7251" ,"E7252" ,"E7253" ,"E7259" ,"E728" ,"E7281" ,"E7289" ,"E729" ,"E7400" ,"E7401" ,"E7402" ,"E7403" ,"E7404" ,"E7409" ,"E7420" ,"E7421" ,"E7429" ,"E744" ,"E748" ,"E749" ,"E7521" ,"E7522" ,"E75240" ,"E75241" ,"E75242" ,"E75243" ,"E75248" ,"E75249" ,"E753" ,"E7601" ,"E7602" ,"E7603" ,"E761" ,"E76210" ,"E76211" ,"E76219" ,"E7622" ,"E7629" ,"E763" ,"E768" ,"E769" ,"E770" ,"E771" ,"E778" ,"E779" ,"E791" ,"E792" ,"E798" ,"E799" ,"E800" ,"E801" ,"E8020" ,"E8021" ,"E8029" ,"E803" ,"E83110" ,"E850" ,"E851" ,"E852" ,"E853" ,"E854" ,"E858" ,"E8581" ,"E8582" ,"E8589" ,"E859" ,"E8801" ,"E8840" ,"E8841" ,"E8842" ,"E8849" ,"E8889" ,"E892" ,"E893" ,"E896" ,"H49811" ,"H49812" ,"H49813"
  ,"H49819" ,"N251" ,"N2581"
))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].DISCHARGE_CONDITION_CODE ="CC-23"
endif
 if (nom.source_identifier in ("I8500" ,"I8501" ,"I8510" ,"I8511" ,"K7041" ,"K7111" ,"K7201" ,"K7210" ,"K7211" ,"K7290" ,"K7291" ,"K766" ,"K767" ,"K7681"))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].DISCHARGE_CONDITION_CODE ="CC-27"
 ENDIF
 if (nom.source_identifier in ("K7030" ,"K7031" ,"K7040" ,"K7041" ,"K709" ,"K743" ,"K744" ,"K745" ,"K7460" ,"K7469"))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].DISCHARGE_CONDITION_CODE ="CC-28"
endif
 if (nom.source_identifier in ("B180" ,"B181" ,"B182" ,"B188" ,"B189" ,"K730" ,"K731" ,"K732" ,"K738" ,"K739" ,"K754"))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].DISCHARGE_CONDITION_CODE ="CC-29"
 ENDIF
 if (nom.source_identifier in ("A5485" ,"K251" ,"K252" ,"K255" ,"K256" ,"K261" ,"K262" ,"K265" ,"K266" ,"K271" ,"K272" ,"K275" ,"K276" ,"K281" ,"K282" ,"K285" ,"K286" ,"K50012" ,"K50112" ,"K50812" ,"K50912" ,"K51012" ,"K51212" ,"K51312" ,"K51412" ,"K51512" ,"K51812" ,"K51912" ,"K560" ,"K561" ,"K562" ,"K563" ,"K5641" ,"K5649" ,"K565" ,"K5650" ,"K5651" ,"K5652" ,"K5660" ,"K56600" ,"K56601" ,"K56609" ,"K5669" ,"K56690" ,"K56691" ,"K56699" ,"K567" ,"K5931" ,"K631" ,"K650" ,"K651" ,"K652" ,"K653" ,"K654" ,"K658" ,"K659" ,"K67" ,"K6812" ,"K6819"))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].DISCHARGE_CONDITION_CODE ="CC-33"
endif
 if (nom.source_identifier in (
"K860"
,"K861"
))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].DISCHARGE_CONDITION_CODE ="CC-34"
endif
 if (nom.source_identifier in ("K5000" ,"K50011" ,"K50012" ,"K50013" ,"K50014" ,"K50018" ,"K50019" ,"K5010" ,"K50111" ,"K50112" ,"K50113" ,"K50114" ,"K50118" ,"K50119" ,"K5080" ,"K50811" ,"K50812" ,"K50813" ,"K50814" ,"K50818" ,"K50819" ,"K5090" ,"K50911" ,"K50912" ,"K50913" ,"K50914" ,"K50918" ,"K50919" ,"K5100" ,"K51011" ,"K51012" ,"K51013" ,"K51014" ,"K51018" ,"K51019" ,"K5120" ,"K51211" ,"K51212" ,"K51213" ,"K51214" ,"K51218" ,"K51219" ,"K5130" ,"K51311" ,"K51312" ,"K51313" ,"K51314" ,"K51318" ,"K51319" ,"K5140" ,"K51411" ,"K51412" ,"K51413" ,"K51414" ,"K51418" ,"K51419" ,"K5150" ,"K51511" ,"K51512" ,"K51513" ,"K51514" ,"K51518" ,"K51519" ,"K5180" ,"K51811" ,"K51812" ,"K51813" ,"K51814" ,"K51818" ,"K51819" ,"K5190" ,"K51911" ,"K51912" ,"K51913" ,"K51914" ,"K51918" ,"K51919"))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].DISCHARGE_CONDITION_CODE ="CC-35"
 ENDIF
 if (nom.source_identifier in ("A0104" ,"A0105" ,"A0223" ,"A0224" ,"A3983" ,"A3984" ,"A5055" ,"A5440" ,"A5441" ,"A5442" ,"A5443" ,"A5449" ,"A666" ,"A6923" ,"B0682" ,"B2685" ,"B4282" ,"M0000" ,"M00011" ,"M00012" ,"M00019" ,"M00021" ,"M00022" ,"M00029" ,"M00031" ,"M00032" ,"M00039" ,"M00041" ,"M00042" ,"M00049" ,"M00051" ,"M00052" ,"M00059" ,"M00061" ,"M00062" ,"M00069" ,"M00071" ,"M00072" ,"M00079" ,"M0008" ,"M0009" ,"M0010" ,"M00111" ,"M00112" ,"M00119" ,"M00121" ,"M00122" ,"M00129" ,"M00131" ,"M00132" ,"M00139" ,"M00141" ,"M00142" ,"M00149" ,"M00151" ,"M00152" ,"M00159" ,"M00161" ,"M00162" ,"M00169" ,"M00171" ,"M00172" ,"M00179" ,"M0018" ,"M0019" ,"M0020" ,"M00211" ,"M00212" ,"M00219" ,"M00221" ,"M00222" ,"M00229" ,"M00231" ,"M00232" ,"M00239" ,"M00241" ,"M00242" ,"M00249" ,"M00251" ,"M00252" ,"M00259" ,"M00261" ,"M00262" ,"M00269" ,"M00271" ,"M00272" ,"M00279" ,"M0028" ,"M0029" ,"M0080" ,"M00811" ,"M00812" ,"M00819" ,"M00821" ,"M00822" ,"M00829" ,"M00831" ,"M00832" ,"M00839"
  ,"M00841" ,"M00842" ,"M00849" ,"M00851" ,"M00852" ,"M00859" ,"M00861" ,"M00862" ,"M00869" ,"M00871" ,"M00872" ,"M00879" ,"M0088" ,"M0089" ,"M009" ,"M01X0" ,"M01X11" ,"M01X12" ,"M01X19" ,"M01X21" ,"M01X22" ,"M01X29" ,"M01X31" ,"M01X32" ,"M01X39" ,"M01X41" ,"M01X42" ,"M01X49" ,"M01X51" ,"M01X52" ,"M01X59" ,"M01X61" ,"M01X62" ,"M01X69" ,"M01X71" ,"M01X72" ,"M01X79" ,"M01X8" ,"M01X9" ,"M0210" ,"M02111" ,"M02112" ,"M02119" ,"M02121" ,"M02122" ,"M02129" ,"M02131" ,"M02132" ,"M02139" ,"M02141" ,"M02142" ,"M02149" ,"M02151" ,"M02152" ,"M02159" ,"M02161" ,"M02162" ,"M02169" ,"M02171" ,"M02172" ,"M02179" ,"M0218" ,"M0219" ,"M0280" ,"M02811" ,"M02812" ,"M02819" ,"M02821" ,"M02822" ,"M02829" ,"M02831" ,"M02832" ,"M02839" ,"M02841" ,"M02842" ,"M02849" ,"M02851" ,"M02852" ,"M02859" ,"M02861" ,"M02862" ,"M02869" ,"M02871" ,"M02872" ,"M02879" ,"M0288" ,"M0289" ,"M029" ,"M4620" ,"M4621" ,"M4622" ,"M4623" ,"M4624" ,"M4625" ,"M4626" ,"M4627" ,"M4628" ,"M4630" ,"M4631" ,"M4632" ,"M4633" ,"M4634"
   ,"M4635"
 ,"M4636"
 ,"M4637" ,"M4638" ,"M4639" ,"M726" ,"M8600" ,"M86011" ,"M86012" ,"M86019"
 ,"M86021" ,"M86022" ,"M86029" ,"M86031" ,"M86032" ,"M86039" ,"M86041" ,"M86042" ,"M86049" ,"M86051" ,"M86052" ,"M86059" ,"M86061" ,"M86062" ,"M86069" ,"M86071" ,"M86072" ,"M86079" ,"M8608" ,"M8609" ,"M8610" ,"M86111" ,"M86112" ,"M86119" ,"M86121" ,"M86122" ,"M86129" ,"M86131" ,"M86132" ,"M86139" ,"M86141" ,"M86142" ,"M86149" ,"M86151" ,"M86152" ,"M86159" ,"M86161" ,"M86162" ,"M86169" ,"M86171" ,"M86172" ,"M86179" ,"M8618" ,"M8619" ,"M8620" ,"M86211" ,"M86212" ,"M86219" ,"M86221" ,"M86222" ,"M86229" ,"M86231" ,"M86232" ,"M86239" ,"M86241" ,"M86242" ,"M86249" ,"M86251" ,"M86252" ,"M86259" ,"M86261" ,"M86262" ,"M86269" ,"M86271" ,"M86272" ,"M86279" ,"M8628" ,"M8629" ,"M8630" ,"M86311" ,"M86312" ,"M86319" ,"M86321" ,"M86322" ,"M86329" ,"M86331" ,"M86332" ,"M86339" ,"M86341" ,"M86342" ,"M86349" ,"M86351" ,"M86352" ,"M86359" ,"M86361" ,"M86362" ,"M86369" ,"M86371" ,"M86372" ,"M86379" ,"M8638" ,"M8639" ,"M8640"
  ,"M86411" ,"M86412" ,"M86419" ,"M86421" ,"M86422" ,"M86429" ,"M86431" ,"M86432" ,"M86439" ,"M86441" ,"M86442" ,"M86449" ,"M86451" ,"M86452" ,"M86459" ,"M86461" ,"M86462" ,"M86469" ,"M86471" ,"M86472" ,"M86479" ,"M8648" ,"M8649" ,"M8650" ,"M86511" ,"M86512" ,"M86519" ,"M86521" ,"M86522" ,"M86529" ,"M86531" ,"M86532" ,"M86539" ,"M86541" ,"M86542" ,"M86549" ,"M86551" ,"M86552" ,"M86559" ,"M86561" ,"M86562" ,"M86569" ,"M86571" ,"M86572" ,"M86579" ,"M8658" ,"M8659" ,"M8660" ,"M86611" ,"M86612" ,"M86619" ,"M86621" ,"M86622" ,"M86629" ,"M86631" ,"M86632" ,"M86639" ,"M86641" ,"M86642" ,"M86649" ,"M86651" ,"M86652" ,"M86659" ,"M86661" ,"M86662" ,"M86669" ,"M86671" ,"M86672" ,"M86679" ,"M8668" ,"M8669" ,"M868X0" ,"M868X1" ,"M868X2" ,"M868X3" ,"M868X4" ,"M868X5" ,"M868X6" ,"M868X7" ,"M868X8" ,"M868X9" ,"M869" ,"M8700" ,"M87011" ,"M87012" ,"M87019" ,"M87021" ,"M87022" ,"M87029" ,"M87031" ,"M87032" ,"M87033" ,"M87034" ,"M87035" ,"M87036" ,"M87037" ,"M87038" ,"M87039" ,"M87041" ,"M87042" ,"M87043"
 ,"M87044" ,"M87045" ,"M87046" ,"M87050" ,"M87051" ,"M87052" ,"M87059" ,"M87061" ,"M87062" ,"M87063" ,"M87064" ,"M87065" ,"M87066" ,"M87071"
 ,"M87072" ,"M87073" ,"M87074" ,"M87075" ,"M87076" ,"M87077" ,"M87078" ,"M87079" ,"M8708" ,"M8709" ,"M8710" ,"M87111" ,"M87112" ,"M87119"
  ,"M87121" ,"M87122" ,"M87129" ,"M87131" ,"M87132" ,"M87133" ,"M87134" ,"M87135" ,"M87136" ,"M87137" ,"M87138" ,"M87139" ,"M87141" ,"M87142" ,
  "M87143" ,"M87144" ,"M87145" ,"M87146" ,"M87150" ,"M87151" ,"M87152" ,"M87159" ,"M87161" ,"M87162" ,"M87163" ,"M87164" ,"M87165" ,"M87166" ,
  "M87171" ,"M87172" ,"M87173" ,"M87174" ,"M87175" ,"M87176" ,"M87177" ,"M87178" ,"M87179" ,"M87180" ,"M87188" ,"M8719" ,"M8720" ,"M87211"
  ,"M87212" ,"M87219" ,"M87221" ,"M87222" ,"M87229" ,"M87231" ,"M87232" ,"M87233" ,"M87234" ,"M87235" ,"M87236" ,"M87237" ,"M87238" ,"M87239"
  ,"M87241" ,"M87242" ,"M87243" ,"M87244" ,"M87245" ,"M87246" ,"M87250" ,"M87251" ,"M87252" ,"M87256" ,"M87261" ,"M87262" ,"M87263" ,"M87264" ,"M87265" ,"M87266"
   ,"M87271" ,"M87272" ,"M87273" ,"M87274" ,"M87275" ,"M87276" ,"M87277" ,"M87278" ,"M87279" ,"M8728" ,"M8729" ,"M8730" ,"M87311" ,"M87312" ,
   "M87319" ,"M87321" ,"M87322" ,"M87329" ,"M87331" ,"M87332" ,"M87333" ,"M87334" ,"M87335" ,"M87336" ,"M87337" ,"M87338" ,"M87339" ,"M87341" ,"M87342" ,"M87343" ,"M87344" ,"M87345" ,"M87346" ,"M87350" ,"M87351" ,"M87352" ,"M87353" ,"M87361" ,"M87362" ,"M87363" ,"M87364" ,"M87365" ,"M87366" ,"M87371" ,"M87372" ,"M87373" ,"M87374" ,"M87375" ,"M87376" ,"M87377" ,"M87378" ,"M87379" ,"M8738" ,"M8739" ,"M8780" ,"M87811" ,"M87812" ,"M87819" ,"M87821" ,"M87822" ,"M87829" ,"M87831" ,"M87832" ,"M87833" ,"M87834" ,"M87835" ,"M87836" ,"M87837" ,"M87838" ,"M87839" ,"M87841" ,"M87842" ,"M87843" ,"M87844" ,"M87845" ,"M87849" ,"M87850" ,"M87851" ,"M87852" ,"M87859" ,"M87861" ,"M87862" ,"M87863" ,"M87864" ,"M87865" ,"M87869" ,"M87871" ,"M87872" ,"M87873" ,"M87874" ,"M87875" ,"M87876" ,"M87877" ,"M87878" ,"M87879" ,"M8788" ,"M8789" ,"M879" ,"M8960" ,"M89611"
   ,"M89612"
,"M89619" ,"M89621" ,"M89622" ,"M89629" ,"M89631" ,"M89632" ,"M89639" ,"M89641" ,"M89642" ,"M89649" ,"M89651" ,"M89652" ,"M89659" ,"M89661" ,"M89662" ,"M89669" ,"M89671" ,"M89672" ,"M89679" ,"M8968" ,"M8969" ,"M9050" ,"M90511" ,"M90512" ,"M90519" ,"M90521" ,"M90522" ,"M90529" ,"M90531" ,"M90532" ,"M90539" ,"M90541" ,"M90542" ,"M90549" ,"M90551" ,"M90552" ,"M90559" ,"M90561" ,"M90562" ,"M90569" ,"M90571" ,"M90572" ,"M90579" ,"M9058" ,"M9059"))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].DISCHARGE_CONDITION_CODE ="CC-39"
endif
 if (nom.source_identifier in ("L4050" ,"L4051" ,"L4052" ,"L4053" ,"L4054" ,"L4059" ,"M0230" ,"M02311" ,"M02312" ,"M02319" ,"M02321" ,"M02322" ,"M02329" ,"M02331" ,"M02332" ,"M02339" ,"M02341" ,"M02342" ,"M02349" ,"M02351" ,"M02352" ,"M02359" ,"M02361" ,"M02362" ,"M02369" ,"M02371" ,"M02372" ,"M02379" ,"M0238" ,"M0239" ,"M041" ,"M042" ,"M048" ,"M049" ,"M0500" ,"M05011" ,"M05012" ,"M05019" ,"M05021" ,"M05022" ,"M05029" ,"M05031" ,"M05032" ,"M05039" ,"M05041" ,"M05042" ,"M05049" ,"M05051" ,"M05052" ,"M05059" ,"M05061" ,"M05062" ,"M05069" ,"M05071" ,"M05072" ,"M05079" ,"M0509" ,"M0510" ,"M05111" ,"M05112" ,"M05119" ,"M05121" ,"M05122" ,"M05129" ,"M05131" ,"M05132" ,"M05139" ,"M05141" ,"M05142" ,"M05149" ,"M05151" ,"M05152" ,"M05159" ,"M05161" ,"M05162" ,"M05169" ,"M05171" ,"M05172" ,"M05179" ,"M0519" ,"M0520" ,"M05211" ,"M05212" ,"M05219" ,"M05221" ,"M05222" ,"M05229" ,"M05231" ,"M05232" ,"M05239" ,"M05241" ,"M05242" ,"M05249" ,"M05251" ,"M05252" ,"M05259" ,"M05261" ,"M05262" ,"M05269"
 ,"M05271" ,"M05272" ,"M05279" ,"M0529" ,"M0530" ,"M05311" ,"M05312" ,"M05319" ,"M05321" ,"M05322" ,"M05329" ,"M05331" ,"M05332" ,"M05339" ,"M05341" ,"M05342" ,"M05349" ,"M05351" ,"M05352" ,"M05359" ,"M05361" ,"M05362" ,"M05369" ,"M05371" ,"M05372" ,"M05379" ,"M0539" ,"M0540" ,"M05411" ,"M05412" ,"M05419" ,"M05421" ,"M05422" ,"M05429" ,"M05431" ,"M05432" ,"M05439" ,"M05441" ,"M05442" ,"M05449" ,"M05451" ,"M05452" ,"M05459" ,"M05461" ,"M05462" ,"M05469" ,"M05471" ,"M05472" ,"M05479" ,"M0549" ,"M0550" ,"M05511" ,"M05512" ,"M05519" ,"M05521" ,"M05522" ,"M05529" ,"M05531" ,"M05532" ,"M05539" ,"M05541" ,"M05542" ,"M05549" ,"M05551" ,"M05552" ,"M05559" ,"M05561" ,"M05562" ,"M05569" ,"M05571" ,"M05572" ,"M05579" ,"M0559" ,"M0560" ,"M05611" ,"M05612" ,"M05619" ,"M05621" ,"M05622" ,"M05629" ,"M05631" ,"M05632" ,"M05639" ,"M05641" ,"M05642" ,"M05649" ,"M05651" ,"M05652" ,"M05659" ,"M05661" ,"M05662" ,"M05669" ,"M05671" ,"M05672" ,"M05679" ,"M0569" ,"M0570" ,"M05711" ,"M05712" ,"M05719" ,"M05721"
 ,"M05722" ,"M05729" ,"M05731" ,"M05732" ,"M05739" ,"M05741" ,"M05742" ,"M05749" ,"M05751" ,"M05752" ,"M05759" ,"M05761" ,"M05762" ,"M05769" ,"M05771" ,"M05772" ,"M05779" ,"M0579" ,"M0580" ,"M05811" ,"M05812" ,"M05819" ,"M05821" ,"M05822" ,"M05829" ,"M05831" ,"M05832" ,"M05839" ,"M05841" ,"M05842" ,"M05849" ,"M05851" ,"M05852" ,"M05859" ,"M05861" ,"M05862" ,"M05869" ,"M05871" ,"M05872" ,"M05879" ,"M0589" ,"M059" ,"M0600" ,"M06011" ,"M06012" ,"M06019" ,"M06021" ,"M06022" ,"M06029" ,"M06031" ,"M06032" ,"M06039" ,"M06041" ,"M06042" ,"M06049" ,"M06051" ,"M06052" ,"M06059" ,"M06061" ,"M06062" ,"M06069" ,"M06071" ,"M06072" ,"M06079" ,"M0608" ,"M0609" ,"M061" ,"M0620" ,"M06211" ,"M06212" ,"M06219" ,"M06221" ,"M06222" ,"M06229" ,"M06231" ,"M06232" ,"M06239" ,"M06241" ,"M06242" ,"M06249" ,"M06251" ,"M06252" ,"M06259" ,"M06261" ,"M06262" ,"M06269" ,"M06271" ,"M06272" ,"M06279" ,"M0628" ,"M0629" ,"M0630" ,"M06311" ,"M06312" ,"M06319" ,"M06321" ,"M06322" ,"M06329" ,"M06331" ,"M06332" ,"M06339"
 ,"M06341" ,"M06342" ,"M06349" ,"M06351" ,"M06352" ,"M06359" ,"M06361" ,"M06362" ,"M06369" ,"M06371" ,"M06372" ,"M06379" ,"M0638" ,"M0639" ,"M064" ,"M0680" ,"M06811" ,"M06812" ,"M06819" ,"M06821" ,"M06822" ,"M06829" ,"M06831" ,"M06832" ,"M06839" ,"M06841" ,"M06842" ,"M06849" ,"M06851" ,"M06852" ,"M06859" ,"M06861" ,"M06862" ,"M06869" ,"M06871" ,"M06872" ,"M06879" ,"M0688" ,"M0689" ,"M069" ,"M0800" ,"M08011" ,"M08012" ,"M08019" ,"M08021" ,"M08022" ,"M08029" ,"M08031" ,"M08032" ,"M08039" ,"M08041" ,"M08042" ,"M08049" ,"M08051" ,"M08052" ,"M08059" ,"M08061" ,"M08062" ,"M08069" ,"M08071" ,"M08072" ,"M08079" ,"M0808" ,"M0809" ,"M081" ,"M0820" ,"M08211" ,"M08212" ,"M08219" ,"M08221" ,"M08222" ,"M08229" ,"M08231" ,"M08232" ,"M08239" ,"M08241" ,"M08242" ,"M08249" ,"M08251" ,"M08252" ,"M08259" ,"M08261" ,"M08262" ,"M08269" ,"M08271" ,"M08272" ,"M08279" ,"M0828" ,"M0829" ,"M083" ,"M0840" ,"M08411" ,"M08412" ,"M08419" ,"M08421" ,"M08422" ,"M08429" ,"M08431" ,"M08432" ,"M08439" ,"M08441" ,"M08442"
 ,"M08449" ,"M08451" ,"M08452" ,"M08459" ,"M08461" ,"M08462" ,"M08469" ,"M08471" ,"M08472" ,"M08479" ,"M0848" ,"M0880" ,"M08811" ,"M08812" ,"M08819" ,"M08821" ,"M08822" ,"M08829" ,"M08831" ,"M08832" ,"M08839" ,"M08841" ,"M08842" ,"M08849" ,"M08851" ,"M08852" ,"M08859" ,"M08861" ,"M08862" ,"M08869" ,"M08871" ,"M08872" ,"M08879" ,"M0888" ,"M0889" ,"M0890" ,"M08911" ,"M08912" ,"M08919" ,"M08921" ,"M08922" ,"M08929" ,"M08931" ,"M08932" ,"M08939" ,"M08941" ,"M08942" ,"M08949" ,"M08951" ,"M08952" ,"M08959" ,"M08961" ,"M08962" ,"M08969" ,"M08971" ,"M08972" ,"M08979" ,"M0898" ,"M0899" ,"M1200" ,"M12011" ,"M12012" ,"M12019" ,"M12021" ,"M12022" ,"M12029" ,"M12031" ,"M12032" ,"M12039" ,"M12041" ,"M12042" ,"M12049" ,"M12051" ,"M12052" ,"M12059" ,"M12061" ,"M12062" ,"M12069" ,"M12071" ,"M12072" ,"M12079" ,"M1208" ,"M1209" ,"M300" ,"M301" ,"M302" ,"M303" ,"M308" ,"M310" ,"M311" ,"M312" ,"M3130" ,"M3131" ,"M314" ,"M315" ,"M316" ,"M317" ,"M320" ,"M3210" ,"M3211" ,"M3212" ,"M3213" ,"M3214" ,"M3215"
  ,"M3219" ,
"M328" ,"M329" ,"M3300" ,"M3301" ,"M3302" ,"M3303" ,"M3309" ,"M3310" ,"M3311" ,"M3312" ,"M3313" ,"M3319" ,"M3320" ,"M3321" ,"M3322" ,"M3329" ,"M3390" ,"M3391" ,"M3392" ,"M3393" ,"M3399" ,"M340" ,"M341" ,"M342" ,"M3481" ,"M3482" ,"M3483" ,"M3489" ,"M349" ,"M3500" ,"M3501" ,"M3502" ,"M3503" ,"M3504" ,"M3509" ,"M351" ,"M352" ,"M353" ,"M355" ,"M358" ,"M359" ,"M360" ,"M368" ,"M450" ,"M451" ,"M452" ,"M453" ,"M454" ,"M455" ,"M456" ,"M457" ,"M458" ,"M459" ,"M4600" ,"M4601" ,"M4602" ,"M4603" ,"M4604" ,"M4605" ,"M4606" ,"M4607" ,"M4608" ,"M4609" ,"M461" ,"M4650" ,"M4651" ,"M4652" ,"M4653" ,"M4654" ,"M4655" ,"M4656" ,"M4657" ,"M4658" ,"M4659" ,"M4680" ,"M4681" ,"M4682" ,"M4683" ,"M4684" ,"M4685" ,"M4686" ,"M4687" ,"M4688" ,"M4689" ,"M4690" ,"M4691" ,"M4692" ,"M4693" ,"M4694" ,"M4695" ,"M4696" ,"M4697" ,"M4698" ,"M4699" ,"M488X1" ,"M488X2" ,"M488X3" ,"M488X4" ,"M488X5" ,"M488X6" ,"M488X7" ,"M488X8" ,"M488X9" ,"M4980" ,"M4981" ,"M4982" ,"M4983" ,"M4984" ,"M4985" ,"M4986" ,"M4987" ,"M4988" ,"M4989")
)
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].DISCHARGE_CONDITION_CODE ="CC-40"
 ENDIF
 if (nom.source_identifier in ("D460" ,"D461" ,"D4620" ,"D4621" ,"D4622" ,"D464" ,"D469" ,"D46A" ,"D46B" ,"D46C" ,"D46Z" ,"D474" ,"D5700" ,"D5701" ,"D5702" ,"D571" ,"D5720" ,"D57211" ,"D57212" ,"D57219" ,"D5740" ,"D57411" ,"D57412" ,"D57419" ,"D5780" ,"D57811" ,"D57812" ,"D57819" ,"D590" ,"D591" ,"D592" ,"D593" ,"D594" ,"D595" ,"D596" ,"D598" ,"D599" ,"D600" ,"D601" ,"D608" ,"D609" ,"D6101" ,"D6109" ,"D611" ,"D612" ,"D613" ,"D6182" ,"D6189" ,"D619" ,"D66" ,"D67" ,"D7581"))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].DISCHARGE_CONDITION_CODE ="CC-46"
endif
if (nom.source_identifier in ("D61810" ,"D61811" ,"D61818" ,"D700" ,"D701" ,"D702" ,"D703" ,"D704" ,"D708" ,"D709" ,"D71" ,"D720" ,"D761" ,"D762" ,"D763" ,"D800" ,"D801" ,"D802" ,"D803" ,"D804" ,"D805" ,"D806" ,"D807" ,"D808" ,"D809" ,"D810" ,"D811" ,"D812" ,"D813" ,"D814" ,"D815" ,"D816" ,"D817" ,"D8189" ,"D819" ,"D820" ,"D821" ,"D822" ,"D823" ,"D824" ,"D828" ,"D829" ,"D830" ,"D831" ,"D832" ,"D838" ,"D839" ,"D840" ,"D848" ,"D849" ,"D893" ,"D8940" ,"D8941" ,"D8942" ,"D8943" ,"D8949" ,"D89810" ,"D89811" ,"D89812" ,"D89813" ,"D8982" ,"D8989" ,"D899"))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].DISCHARGE_CONDITION_CODE ="CC-47"
endif
 if (nom.source_identifier in ("C946" ,"D45" ,"D471" ,"D473" ,"D479" ,"D47Z1" ,"D47Z2" ,"D47Z9" ,"D550" ,"D551" ,"D552" ,"D553" ,"D558" ,"D559" ,"D560" ,"D561" ,"D562" ,"D564" ,"D565" ,"D568" ,"D573" ,"D580" ,"D581" ,"D582" ,"D588" ,"D589" ,"D640" ,"D641" ,"D642" ,"D643" ,"D65" ,"D680" ,"D681" ,"D682" ,"D68311" ,"D68312" ,"D68318" ,"D6832" ,"D684" ,"D6851" ,"D6852" ,"D6859" ,"D6861" ,"D6862" ,"D6869" ,"D688" ,"D689" ,"D690" ,"D691" ,"D692" ,"D693" ,"D6941" ,"D6942" ,"D6949" ,"D696" ,"D698" ,"D699" ,"D7582"))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].DISCHARGE_CONDITION_CODE ="CC-48"
 ENDIF
 if (nom.source_identifier in ("F0151" ,"F0281" ,"F0391" ,"G910" ,"G911" ,"G912" ,"G913" ,"G914" ,"G918" ,"G919"))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].DISCHARGE_CONDITION_CODE ="CC-51"
endif
 if (nom.source_identifier in ("A8100" ,"A8101" ,"A8109" ,"A811" ,"A812" ,"A8181" ,"A8182" ,"A8183" ,"A8189" ,"A819" ,"E7500" ,"E7501" ,"E7502" ,"E7509" ,"E7510" ,"E7511" ,"E7519" ,"E7523" ,"E7525" ,"E7526" ,"E7529" ,"E754" ,"F0150" ,"F0280" ,"F0390" ,"F04" ,"G132" ,"G138" ,"G300" ,"G301" ,"G308" ,"G309" ,"G3101" ,"G3109" ,"G311" ,"G312" ,"G3181" ,"G3182" ,"G3183" ,"G3185" ,"G3189" ,"G319" ,"G937" ,"I673"))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].DISCHARGE_CONDITION_CODE ="CC-52"
 ENDIF
 if (nom.source_identifier in ("F10150" ,"F10151" ,"F10159" ,"F10231" ,"F10232" ,"F10250" ,"F10251" ,"F10259" ,"F1026" ,"F1027" ,"F10950" ,"F10951" ,"F10959" ,"F1096" ,"F1097" ,"F11150" ,"F11151" ,"F11159" ,"F11250" ,"F11251" ,"F11259" ,"F11950" ,"F11951" ,"F11959" ,"F12150" ,"F12151" ,"F12159" ,"F12250" ,"F12251" ,"F12259" ,"F12950" ,"F12951" ,"F12959" ,"F13150" ,"F13151" ,"F13159" ,"F13231" ,"F13232" ,"F13250" ,"F13251" ,"F13259" ,"F1326" ,"F1327" ,"F13931" ,"F13932" ,"F13950" ,"F13951" ,"F13959" ,"F1396" ,"F1397" ,"F14150" ,"F14151" ,"F14159" ,"F14250" ,"F14251" ,"F14259" ,"F14950" ,"F14951" ,"F14959" ,"F15150" ,"F15151" ,"F15159" ,"F15250" ,"F15251" ,"F15259" ,"F15950" ,"F15951" ,"F15959" ,"F16150" ,"F16151" ,"F16159" ,"F16250" ,"F16251" ,"F16259" ,"F16950" ,"F16951" ,"F16959" ,"F18150" ,"F18151" ,"F18159" ,"F1817" ,"F18250" ,"F18251" ,"F18259" ,"F1827" ,"F18950" ,"F18951" ,"F18959" ,"F1897" ,"F19150" ,"F19151" ,"F19159" ,"F1916" ,"F1917" ,"F19231" ,"F19232" ,"F19250" ,"F19251"
  ,"F19259" ,"F1926" ,"F1927" ,"F19931" ,"F19932" ,"F19950" ,"F19951" ,"F19959" ,"F1996" ,"F1997"))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].DISCHARGE_CONDITION_CODE ="CC-54"
endif
 if (nom.source_identifier in ("F10120" ,"F10121" ,"F10129" ,"F1014" ,"F10180" ,"F10181" ,"F10182" ,"F10188" ,"F1019" ,"F1020" ,"F1021" ,"F10220" ,"F10221" ,"F10229" ,"F10230" ,"F10239" ,"F1024" ,"F10280" ,"F10281" ,"F10282" ,"F10288" ,"F1029" ,"F10920" ,"F10921" ,"F10929" ,"F1094" ,"F10980" ,"F10981" ,"F10982" ,"F10988" ,"F1099" ,"F11120" ,"F11121" ,"F11122" ,"F11129" ,"F1114" ,"F11181" ,"F11182" ,"F11188" ,"F1119" ,"F1120" ,"F1121" ,"F11220" ,"F11221" ,"F11222" ,"F11229" ,"F1123" ,"F1124" ,"F11281" ,"F11282" ,"F11288" ,"F1129" ,"F11920" ,"F11921" ,"F11922" ,"F11929" ,"F1193" ,"F1194" ,"F11981" ,"F11982" ,"F11988" ,"F1199" ,"F12120" ,"F12121" ,"F12122" ,"F12129" ,"F12180" ,"F12188" ,"F1219" ,"F1220" ,"F1221" ,"F12220" ,"F12221" ,"F12222" ,"F12229" ,"F1223" ,"F12280" ,"F12288" ,"F1229" ,"F12920" ,"F12921" ,"F12922" ,"F12929" ,"F1293" ,"F12980" ,"F12988" ,"F1299" ,"F13120" ,"F13121" ,"F13129" ,"F1314" ,"F13180" ,"F13181" ,"F13182" ,"F13188" ,"F1319" ,"F1320" ,"F1321" ,"F13220" ,"F13221"
 ,"F13229" ,"F13230" ,"F13239" ,"F1324" ,"F13280" ,"F13281" ,"F13282" ,"F13288" ,"F1329" ,"F13920" ,"F13921" ,"F13929" ,"F13930" ,"F13939" ,"F1394" ,"F13980" ,"F13981" ,"F13982" ,"F13988" ,"F1399" ,"F14120" ,"F14121" ,"F14122" ,"F14129" ,"F1414" ,"F14180" ,"F14181" ,"F14182" ,"F14188" ,"F1419" ,"F1420" ,"F1421" ,"F14220" ,"F14221" ,"F14222" ,"F14229" ,"F1423" ,"F1424" ,"F14280" ,"F14281" ,"F14282" ,"F14288" ,"F1429" ,"F14920" ,"F14921" ,"F14922" ,"F14929" ,"F1494" ,"F14980" ,"F14981" ,"F14982" ,"F14988" ,"F1499" ,"F15120" ,"F15121" ,"F15122" ,"F15129" ,"F1514" ,"F15180" ,"F15181" ,"F15182" ,"F15188" ,"F1519" ,"F1520" ,"F1521" ,"F15220" ,"F15221" ,"F15222" ,"F15229" ,"F1523" ,"F1524" ,"F15280" ,"F15281" ,"F15282" ,"F15288" ,"F1529" ,"F15920" ,"F15921" ,"F15922" ,"F15929" ,"F1593" ,"F1594" ,"F15980" ,"F15981" ,"F15982" ,"F15988" ,"F1599" ,"F16120" ,"F16121" ,"F16122" ,"F16129" ,"F1614" ,"F16180" ,"F16183" ,"F16188" ,"F1619" ,"F1620" ,"F1621" ,"F16220" ,"F16221" ,"F16229" ,"F1624"
 ,"F16280" ,"F16283" ,"F16288" ,"F1629" ,"F16920" ,"F16921" ,"F16929" ,"F1694" ,"F16980" ,"F16983" ,"F16988" ,"F1699" ,"F18120" ,"F18121" ,"F18129" ,"F1814" ,"F18180" ,"F18188" ,"F1819" ,"F1820" ,"F1821" ,"F18220" ,"F18221" ,"F18229" ,"F1824" ,"F18280" ,"F18288" ,"F1829" ,"F18920" ,"F18921" ,"F18929" ,"F1894" ,"F18980" ,"F18988" ,"F1899" ,"F19120" ,"F19121" ,"F19122" ,"F19129" ,"F1914" ,"F19180" ,"F19181" ,"F19182" ,"F19188" ,"F1919" ,"F1920" ,"F1921" ,"F19220" ,"F19221" ,"F19222" ,"F19229" ,"F19230" ,"F19239" ,"F1924" ,"F19280" ,"F19281" ,"F19282" ,"F19288" ,"F1929" ,"F19920" ,"F19921" ,"F19922" ,"F19929" ,"F19930" ,"F19939" ,"F1994" ,"F19980" ,"F19981" ,"F19982" ,"F19988" ,"F1999" ,"T400X1A" ,"T400X4A" ,"T401X1A" ,"T401X4A" ,"T402X1A" ,"T402X4A" ,"T403X1A" ,"T403X4A" ,"T404X1A" ,"T404X4A" ,"T405X1A" ,"T405X4A" ,"T40601A" ,"T40604A" ,"T40691A" ,"T40694A" ,"T408X1A" ,"T408X4A" ,"T40901A" ,"T40904A" ,"T40991A" ,"T40994A" ,"T43601A" ,"T43604A" ,"T43611A" ,"T43614A" ,"T43621A" ,"T43624A"
,"T43631A" ,"T43634A" ,"T43641A" ,"T43644A" ,"T43691A" ,"T43694A" ,"T510X1A" ,"T510X4A"))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].DISCHARGE_CONDITION_CODE ="CC-55"
endif
 if (nom.source_identifier in ("F200" ,"F201" ,"F202" ,"F203" ,"F205" ,"F2081" ,"F2089" ,"F209" ,"F250" ,"F251" ,"F258" ,"F259"))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].DISCHARGE_CONDITION_CODE ="CC-57"
 ENDIF
 if (nom.source_identifier in ("F22" ,"F23" ,"F24" ,"F28" ,"F29" ,"F3010" ,"F3011" ,"F3012" ,"F3013" ,"F302" ,"F303" ,"F304" ,"F308" ,"F309" ,"F310" ,"F3110" ,"F3111" ,"F3112" ,"F3113" ,"F312" ,"F3130" ,"F3131" ,"F3132" ,"F314" ,"F315" ,"F3160" ,"F3161" ,"F3162" ,"F3163" ,"F3164" ,"F3170" ,"F3171" ,"F3172" ,"F3173" ,"F3174" ,"F3175" ,"F3176" ,"F3177" ,"F3178" ,"F3181" ,"F3189" ,"F319" ,"F320" ,"F321" ,"F322" ,"F323" ,"F324" ,"F325" ,"F330" ,"F331" ,"F332" ,"F333" ,"F3340" ,"F3341" ,"F3342" ,"F338" ,"F339" ,"F348" ,"F3481" ,"F3489" ,"F349" ,"F39" ,"F531" ,"T1491" ,"T360X2A" ,"T360X2S" ,"T361X2A" ,"T361X2S" ,"T362X2A" ,"T362X2S" ,"T363X2A" ,"T363X2S" ,"T364X2A" ,"T364X2S" ,"T365X2A" ,"T365X2S" ,"T366X2A" ,"T366X2S" ,"T367X2A" ,"T367X2S" ,"T368X2A" ,"T368X2S" ,"T3692XA" ,"T3692XS" ,"T370X2A" ,"T370X2S" ,"T371X2A" ,"T371X2S" ,"T372X2A" ,"T372X2S" ,"T373X2A" ,"T373X2S" ,"T374X2A" ,"T374X2S" ,"T375X2A" ,"T375X2S" ,"T378X2A" ,"T378X2S" ,"T3792XA" ,"T3792XS" ,"T380X2A" ,"T380X2S" ,"T381X2A"
 ,"T381X2S" ,"T382X2A" ,"T382X2S" ,"T383X2A" ,"T383X2S" ,"T384X2A" ,"T384X2S" ,"T385X2A" ,"T385X2S" ,"T386X2A" ,"T386X2S" ,"T387X2A" ,"T387X2S" ,"T38802A" ,"T38802S" ,"T38812A" ,"T38812S" ,"T38892A" ,"T38892S" ,"T38902A" ,"T38902S" ,"T38992A" ,"T38992S" ,"T39012A" ,"T39012S" ,"T39092A" ,"T39092S" ,"T391X2A" ,"T391X2S" ,"T392X2A" ,"T392X2S" ,"T39312A" ,"T39312S" ,"T39392A" ,"T39392S" ,"T394X2A" ,"T394X2S" ,"T398X2A" ,"T398X2S" ,"T3992XA" ,"T3992XS" ,"T400X2A" ,"T400X2S" ,"T401X2A" ,"T401X2S" ,"T402X2A" ,"T402X2S" ,"T403X2A" ,"T403X2S" ,"T404X2A" ,"T404X2S" ,"T405X2A" ,"T405X2S" ,"T40602A" ,"T40602S" ,"T40692A" ,"T40692S" ,"T407X2A" ,"T407X2S" ,"T408X2A" ,"T408X2S" ,"T40902A" ,"T40902S" ,"T40992A" ,"T40992S" ,"T410X2A" ,"T410X2S" ,"T411X2A" ,"T411X2S" ,"T41202A" ,"T41202S" ,"T41292A" ,"T41292S" ,"T413X2A" ,"T413X2S" ,"T4142XA" ,"T4142XS" ,"T415X2A" ,"T415X2S" ,"T420X2A" ,"T420X2S" ,"T421X2A" ,"T421X2S" ,"T422X2A" ,"T422X2S" ,"T423X2A" ,"T423X2S" ,"T424X2A" ,"T424X2S" ,"T425X2A"
  ,"T425X2S" ,
"T426X2A" ,"T426X2S" ,"T4272XA" ,"T4272XS" ,"T428X2A" ,"T428X2S" ,"T43012A" ,"T43012S" ,"T43022A" ,"T43022S" ,"T431X2A" ,"T431X2S" ,"T43202A" ,"T43202S" ,"T43212A" ,"T43212S" ,"T43222A" ,"T43222S" ,"T43292A" ,"T43292S" ,"T433X2A" ,"T433X2S" ,"T434X2A" ,"T434X2S" ,"T43502A" ,"T43502S" ,"T43592A" ,"T43592S" ,"T43602A" ,"T43602S" ,"T43612A" ,"T43612S" ,"T43622A" ,"T43622S" ,"T43632A" ,"T43632S" ,"T43692A" ,"T43692S" ,"T438X2A" ,"T438X2S" ,"T4392XA" ,"T4392XS" ,"T440X2A" ,"T440X2S" ,"T441X2A" ,"T441X2S" ,"T442X2A" ,"T442X2S" ,"T443X2A" ,"T443X2S" ,"T444X2A" ,"T444X2S" ,"T445X2A" ,"T445X2S" ,"T446X2A" ,"T446X2S" ,"T447X2A" ,"T447X2S" ,"T448X2A" ,"T448X2S" ,"T44902A" ,"T44902S" ,"T44992A" ,"T44992S" ,"T450X2A" ,"T450X2S" ,"T451X2A" ,"T451X2S" ,"T452X2A" ,"T452X2S" ,"T453X2A" ,"T453X2S" ,"T454X2A" ,"T454X2S" ,"T45512A" ,"T45512S" ,"T45522A" ,"T45522S" ,"T45602A" ,"T45602S" ,"T45612A" ,"T45612S" ,"T45622A" ,"T45622S" ,"T45692A" ,"T45692S" ,"T457X2A" ,"T457X2S" ,"T458X2A" ,"T458X2S" ,"T4592XA"
,"T4592XS" ,"T460X2A" ,"T460X2S" ,"T461X2A" ,"T461X2S" ,"T462X2A" ,"T462X2S" ,"T463X2A" ,"T463X2S" ,"T464X2A" ,"T464X2S" ,"T465X2A" ,"T465X2S" ,"T466X2A" ,"T466X2S" ,"T467X2A" ,"T467X2S" ,"T468X2A" ,"T468X2S" ,"T46902A" ,"T46902S" ,"T46992A" ,"T46992S" ,"T470X2A" ,"T470X2S" ,"T471X2A" ,"T471X2S" ,"T472X2A" ,"T472X2S" ,"T473X2A" ,"T473X2S" ,"T474X2A" ,"T474X2S" ,"T475X2A" ,"T475X2S" ,"T476X2A" ,"T476X2S" ,"T477X2A" ,"T477X2S" ,"T478X2A" ,"T478X2S" ,"T4792XA" ,"T4792XS" ,"T480X2A" ,"T480X2S" ,"T481X2A" ,"T481X2S" ,"T48202A" ,"T48202S" ,"T48292A" ,"T48292S" ,"T483X2A" ,"T483X2S" ,"T484X2A" ,"T484X2S" ,"T485X2A" ,"T485X2S" ,"T486X2A" ,"T486X2S" ,"T48902A" ,"T48902S" ,"T48992A" ,"T48992S" ,"T490X2A" ,"T490X2S" ,"T491X2A" ,"T491X2S" ,"T492X2A" ,"T492X2S" ,"T493X2A" ,"T493X2S" ,"T494X2A" ,"T494X2S" ,"T495X2A" ,"T495X2S" ,"T496X2A" ,"T496X2S" ,"T497X2A" ,"T497X2S" ,"T498X2A" ,"T498X2S" ,"T4992XA" ,"T4992XS" ,"T500X2A" ,"T500X2S" ,"T501X2A" ,"T501X2S" ,"T502X2A" ,"T502X2S" ,"T503X2A" ,"T503X2S"
 ,"T504X2A" ,"T504X2S" ,"T505X2A" ,"T505X2S" ,"T506X2A" ,"T506X2S" ,"T507X2A" ,"T507X2S" ,"T508X2A" ,"T508X2S" ,"T50902A" ,"T50902S" ,"T50992A" ,"T50992S" ,"T50A12A" ,"T50A12S" ,"T50A22A" ,"T50A22S" ,"T50A92A" ,"T50A92S" ,"T50B12A" ,"T50B12S" ,"T50B92A" ,"T50B92S" ,"T50Z12A" ,"T50Z12S" ,"T50Z92A" ,"T50Z92S" ,"T510X2A" ,"T510X2S" ,"T511X2A" ,"T511X2S" ,"T512X2A" ,"T512X2S" ,"T513X2A" ,"T513X2S" ,"T518X2A" ,"T518X2S" ,"T5192XA" ,"T5192XS" ,"T520X2A" ,"T520X2S" ,"T521X2A" ,"T521X2S" ,"T522X2A" ,"T522X2S" ,"T523X2A" ,"T523X2S" ,"T524X2A" ,"T524X2S" ,"T528X2A" ,"T528X2S" ,"T5292XA" ,"T5292XS" ,"T530X2A" ,"T530X2S" ,"T531X2A" ,"T531X2S" ,"T532X2A" ,"T532X2S" ,"T533X2A" ,"T533X2S" ,"T534X2A" ,"T534X2S" ,"T535X2A" ,"T535X2S" ,"T536X2A" ,"T536X2S" ,"T537X2A" ,"T537X2S" ,"T5392XA" ,"T5392XS" ,"T540X2A" ,"T540X2S" ,"T541X2A" ,"T541X2S" ,"T542X2A" ,"T542X2S" ,"T543X2A" ,"T543X2S" ,"T5492XA" ,"T5492XS" ,"T550X2A" ,"T550X2S" ,"T551X2A" ,"T551X2S" ,"T560X2A" ,"T560X2S" ,"T561X2A" ,"T561X2S"
  ,"T562X2A" ,"T562X2S" ,"T563X2A" ,"T563X2S" ,"T564X2A" ,"T564X2S" ,"T565X2A" ,"T565X2S" ,"T566X2A" ,"T566X2S" ,"T567X2A" ,"T567X2S" ,"T56812A" ,"T56812S" ,"T56892A" ,"T56892S" ,"T5692XA" ,"T5692XS" ,"T570X2A" ,"T570X2S" ,"T571X2A" ,"T571X2S" ,"T572X2A" ,"T572X2S" ,"T573X2A" ,"T573X2S" ,"T578X2A" ,"T578X2S" ,"T5792XA" ,"T5792XS" ,"T5802XA" ,"T5802XS" ,"T5812XA" ,"T5812XS" ,"T582X2A" ,"T582X2S" ,"T588X2A" ,"T588X2S" ,"T5892XA" ,"T5892XS" ,"T590X2A" ,"T590X2S" ,"T591X2A" ,"T591X2S" ,"T592X2A" ,"T592X2S" ,"T593X2A" ,"T593X2S" ,"T594X2A" ,"T594X2S" ,"T595X2A" ,"T595X2S" ,"T596X2A" ,"T596X2S" ,"T597X2A" ,"T597X2S" ,"T59812A" ,"T59812S" ,"T59892A" ,"T59892S" ,"T5992XA" ,"T5992XS" ,"T600X2A" ,"T600X2S" ,"T601X2A" ,"T601X2S" ,"T602X2A" ,"T602X2S" ,"T603X2A" ,"T603X2S" ,"T604X2A" ,"T604X2S" ,"T608X2A" ,"T608X2S" ,"T6092XA" ,"T6092XS" ,"T6102XA" ,"T6102XS" ,"T6112XA" ,"T6112XS" ,"T61772A" ,"T61772S" ,"T61782A" ,"T61782S" ,"T618X2A" ,"T618X2S" ,"T6192XA" ,"T6192XS" ,"T620X2A" ,"T620X2S"
  ,"T621X2A" ,"T621X2S" ,"T622X2A" ,"T622X2S" ,"T628X2A" ,"T628X2S" ,"T6292XA" ,"T6292XS" ,"T63002A" ,"T63002S" ,"T63012A" ,"T63012S" ,"T63022A" ,"T63022S" ,"T63032A" ,"T63032S" ,"T63042A" ,"T63042S" ,"T63062A" ,"T63062S" ,"T63072A" ,"T63072S" ,"T63082A" ,"T63082S" ,"T63092A" ,"T63092S" ,"T63112A" ,"T63112S" ,"T63122A" ,"T63122S" ,"T63192A" ,"T63192S" ,"T632X2A" ,"T632X2S" ,"T63302A" ,"T63302S" ,"T63312A" ,"T63312S" ,"T63322A" ,"T63322S" ,"T63332A" ,"T63332S" ,"T63392A" ,"T63392S" ,"T63412A" ,"T63412S" ,"T63422A" ,"T63422S" ,"T63432A" ,"T63432S" ,"T63442A" ,"T63442S" ,"T63452A" ,"T63452S" ,"T63462A" ,"T63462S" ,"T63482A" ,"T63482S" ,"T63512A" ,"T63512S" ,"T63592A" ,"T63592S" ,"T63612A" ,"T63612S" ,"T63622A" ,"T63622S" ,"T63632A" ,"T63632S" ,"T63692A" ,"T63692S" ,"T63712A" ,"T63712S" ,"T63792A" ,"T63792S" ,"T63812A" ,"T63812S" ,"T63822A" ,"T63822S" ,"T63832A" ,"T63832S" ,"T63892A" ,"T63892S" ,"T6392XA" ,"T6392XS" ,"T6402XA" ,"T6402XS" ,"T6482XA" ,"T6482XS" ,"T650X2A" ,"T650X2S"
  ,"T651X2A" ,"T651X2S" ,"T65212A" ,"T65212S" ,"T65222A" ,"T65222S" ,"T65292A" ,"T65292S" ,"T653X2A" ,"T653X2S" ,"T654X2A" ,"T654X2S" ,"T655X2A" ,"T655X2S" ,"T656X2A" ,"T656X2S" ,"T65812A" ,"T65812S" ,"T65822A" ,"T65822S" ,"T65832A" ,"T65832S" ,"T65892A" ,"T65892S" ,"T6592XA" ,"T6592XS" ,"T71112A" ,"T71112S" ,"T71122A" ,"T71122S" ,"T71132A" ,"T71132S" ,"T71152A" ,"T71152S" ,"T71162A" ,"T71162S" ,"T71192A" ,"T71192S" ,"T71222A" ,"T71222S" ,"T71232A" ,"T71232S" ,"X710XXA" ,"X710XXD" ,"X710XXS" ,"X711XXA" ,"X711XXD" ,"X711XXS" ,"X712XXA" ,"X712XXD" ,"X712XXS" ,"X713XXA" ,"X713XXD" ,"X713XXS" ,"X718XXA" ,"X718XXD" ,"X718XXS" ,"X719XXA" ,"X719XXD" ,"X719XXS" ,"X72XXXA" ,"X72XXXD" ,"X72XXXS" ,"X730XXA" ,"X730XXD" ,"X730XXS" ,"X731XXA" ,"X731XXD" ,"X731XXS" ,"X732XXA" ,"X732XXD" ,"X732XXS" ,"X738XXA" ,"X738XXD" ,"X738XXS" ,"X739XXA" ,"X739XXD" ,"X739XXS" ,"X7401XA" ,"X7401XD" ,"X7401XS" ,"X7402XA" ,"X7402XD" ,"X7402XS" ,"X7409XA" ,"X7409XD" ,"X7409XS" ,"X748XXA" ,"X748XXD" ,"X748XXS"
  ,"X749XXA" ,"X749XXD" ,"X749XXS" ,"X75XXXA" ,"X75XXXD" ,"X75XXXS" ,"X76XXXA" ,"X76XXXD" ,"X76XXXS" ,"X770XXA" ,"X770XXD" ,"X770XXS" ,"X771XXA" ,"X771XXD" ,"X771XXS" ,"X772XXA" ,"X772XXD" ,"X772XXS" ,"X773XXA" ,"X773XXD" ,"X773XXS" ,"X778XXA" ,"X778XXD" ,"X778XXS" ,"X779XXA" ,"X779XXD" ,"X779XXS" ,"X780XXA" ,"X780XXD" ,"X780XXS" ,"X781XXA" ,"X781XXD" ,"X781XXS" ,"X782XXA" ,"X782XXD" ,"X782XXS" ,"X788XXA" ,"X788XXD" ,"X788XXS" ,"X789XXA" ,"X789XXD" ,"X789XXS" ,"X79XXXA" ,"X79XXXD" ,"X79XXXS" ,"X80XXXA" ,"X80XXXD" ,"X80XXXS" ,"X810XXA" ,"X810XXD" ,"X810XXS" ,"X811XXA" ,"X811XXD" ,"X811XXS" ,"X818XXA" ,"X818XXD" ,"X818XXS" ,"X820XXA" ,"X820XXD" ,"X820XXS" ,"X821XXA" ,"X821XXD" ,"X821XXS" ,"X822XXA" ,"X822XXD" ,"X822XXS" ,"X828XXA" ,"X828XXD" ,"X828XXS" ,"X830XXA" ,"X830XXD" ,"X830XXS" ,"X831XXA" ,"X831XXD" ,"X831XXS" ,"X832XXA" ,"X832XXD" ,"X832XXS" ,"X838XXA" ,"X838XXD" ,"X838XXS"))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].DISCHARGE_CONDITION_CODE ="CC-58"
endif
 if (nom.source_identifier in ("A072" ,"A310" ,"A312" ,"B250" ,"B251" ,"B252" ,"B258" ,"B259" ,"B371" ,"B377" ,"B3781" ,"B440" ,"B441" ,"B442" ,"B447" ,"B4489" ,"B449" ,"B450" ,"B451" ,"B452" ,"B453" ,"B457" ,"B458" ,"B459" ,"B460" ,"B461" ,"B462" ,"B463" ,"B464" ,"B465" ,"B468" ,"B469" ,"B484" ,"B488" ,"B582" ,"B583" ,"B59"))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].DISCHARGE_CONDITION_CODE ="CC-6"
 ENDIF
 if (nom.source_identifier in ("G8250" ,"G8251" ,"G8252" ,"G8253" ,"G8254" ,"R532" ,"S14111A" ,"S14111D" ,"S14111S" ,"S14112A" ,"S14112D" ,"S14112S" ,"S14113A" ,"S14113D" ,"S14113S" ,"S14114A" ,"S14114D" ,"S14114S" ,"S14115A" ,"S14115D" ,"S14115S" ,"S14116A" ,"S14116D" ,"S14116S" ,"S14117A" ,"S14117D" ,"S14117S" ,"S14118A" ,"S14118D" ,"S14118S" ,"S14119A" ,"S14119D" ,"S14119S"))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].DISCHARGE_CONDITION_CODE ="CC-70"
endif
if (nom.source_identifier in ("G8220" ,"G8221" ,"G8222" ,"S24111A" ,"S24111D" ,"S24111S" ,"S24112A" ,"S24112D" ,"S24112S" ,"S24113A" ,"S24113D" ,"S24113S" ,"S24114A" ,"S24114D" ,"S24114S" ,"S24119A" ,"S24119D" ,"S24119S"))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].DISCHARGE_CONDITION_CODE ="CC-71"
endif
 if (nom.source_identifier in ("B0082" ,"B0112" ,"B0224" ,"G041" ,"G0489" ,"G0491" ,"G054" ,"G110" ,"G111" ,"G112" ,"G113" ,"G114" ,"G118" ,"G119" ,"G120" ,"G121" ,"G128" ,"G129" ,"G320" ,"G3281" ,"G373" ,"G374" ,"G834" ,"G901" ,"G950" ,"G9511" ,"G9519" ,"G9520" ,"G9529" ,"G9581" ,"G9589" ,"G959" ,"G992" ,"Q000" ,"Q001" ,"Q002" ,"Q010" ,"Q011" ,"Q012" ,"Q018" ,"Q019" ,"Q02" ,"Q030" ,"Q031" ,"Q038" ,"Q039" ,"Q040" ,"Q041" ,"Q042" ,"Q043" ,"Q044" ,"Q045" ,"Q046" ,"Q048" ,"Q049" ,"Q050" ,"Q051" ,"Q052" ,"Q053" ,"Q054" ,"Q055" ,"Q056" ,"Q057" ,"Q058" ,"Q059" ,"Q060" ,"Q061" ,"Q062" ,"Q063" ,"Q064" ,"Q068" ,"Q069" ,"Q0700" ,"Q0701" ,"Q0702" ,"Q0703" ,"Q078" ,"Q079" ,"S140XXA" ,"S140XXD" ,"S140XXS" ,"S14101A" ,"S14101D" ,"S14101S" ,"S14102A" ,"S14102D" ,"S14102S" ,"S14103A" ,"S14103D" ,"S14103S" ,"S14104A" ,"S14104D" ,"S14104S" ,"S14105A" ,"S14105D" ,"S14105S" ,"S14106A" ,"S14106D" ,"S14106S" ,"S14107A" ,"S14107D" ,"S14107S" ,"S14108A" ,"S14108D" ,"S14108S" ,"S14109A" ,"S14109D" ,"S14109S" ,
"S14121A" ,"S14121D" ,"S14121S" ,"S14122A" ,"S14122D" ,"S14122S" ,"S14123A" ,"S14123D" ,"S14123S" ,"S14124A" ,"S14124D" ,"S14124S" ,"S14125A" ,"S14125D" ,"S14125S" ,"S14126A" ,"S14126D" ,"S14126S" ,"S14127A" ,"S14127D" ,"S14127S" ,"S14128A" ,"S14128D" ,"S14128S" ,"S14129A" ,"S14129D" ,"S14129S" ,"S14131A" ,"S14131D" ,"S14131S" ,"S14132A" ,"S14132D" ,"S14132S" ,"S14133A" ,"S14133D" ,"S14133S" ,"S14134A" ,"S14134D" ,"S14134S" ,"S14135A" ,"S14135D" ,"S14135S" ,"S14136A" ,"S14136D" ,"S14136S" ,"S14137A" ,"S14137D" ,"S14137S" ,"S14138A" ,"S14138D" ,"S14138S" ,"S14139A" ,"S14139D" ,"S14139S" ,"S14141A" ,"S14141D" ,"S14141S" ,"S14142A" ,"S14142D" ,"S14142S" ,"S14143A" ,"S14143D" ,"S14143S" ,"S14144A" ,"S14144D" ,"S14144S" ,"S14145A" ,"S14145D" ,"S14145S" ,"S14146A" ,"S14146D" ,"S14146S" ,"S14147A" ,"S14147D" ,"S14147S" ,"S14148A" ,"S14148D" ,"S14148S" ,"S14149A" ,"S14149D" ,"S14149S" ,"S14151A" ,"S14151D" ,"S14151S" ,"S14152A" ,"S14152D" ,"S14152S" ,"S14153A" ,"S14153D" ,"S14153S" ,"S14154A"
,"S14154D" ,"S14154S" ,"S14155A" ,"S14155D" ,"S14155S" ,"S14156A" ,"S14156D" ,"S14156S" ,"S14157A" ,"S14157D" ,"S14157S" ,"S14158A" ,"S14158D" ,"S14158S" ,"S14159A" ,"S14159D" ,"S14159S" ,"S240XXA" ,"S240XXD" ,"S240XXS" ,"S24101A" ,"S24101D" ,"S24101S" ,"S24102A" ,"S24102D" ,"S24102S" ,"S24103A" ,"S24103D" ,"S24103S" ,"S24104A" ,"S24104D" ,"S24104S" ,"S24109A" ,"S24109D" ,"S24109S" ,"S24131A" ,"S24131D" ,"S24131S" ,"S24132A" ,"S24132D" ,"S24132S" ,"S24133A" ,"S24133D" ,"S24133S" ,"S24134A" ,"S24134D" ,"S24134S" ,"S24139A" ,"S24139D" ,"S24139S" ,"S24141A" ,"S24141D" ,"S24141S" ,"S24142A" ,"S24142D" ,"S24142S" ,"S24143A" ,"S24143D" ,"S24143S" ,"S24144A" ,"S24144D" ,"S24144S" ,"S24149A" ,"S24149D" ,"S24149S" ,"S24151A" ,"S24151D" ,"S24151S" ,"S24152A" ,"S24152D" ,"S24152S" ,"S24153A" ,"S24153D" ,"S24153S" ,"S24154A" ,"S24154D" ,"S24154S" ,"S24159A" ,"S24159D" ,"S24159S" ,"S3401XA" ,"S3401XD" ,"S3401XS" ,"S3402XA" ,"S3402XD" ,"S3402XS" ,"S34101A" ,"S34101D" ,"S34101S" ,"S34102A" ,"S34102D"
 ,"S34102S" ,"S34103A" ,"S34103D" ,"S34103S" ,"S34104A" ,"S34104D" ,"S34104S" ,"S34105A" ,"S34105D" ,"S34105S" ,"S34109A" ,"S34109D" ,"S34109S" ,"S34111A" ,"S34111D" ,"S34111S" ,"S34112A" ,"S34112D" ,"S34112S" ,"S34113A" ,"S34113D" ,"S34113S" ,"S34114A" ,"S34114D" ,"S34114S" ,"S34115A" ,"S34115D" ,"S34115S" ,"S34119A" ,"S34119D" ,"S34119S" ,"S34121A" ,"S34121D" ,"S34121S" ,"S34122A" ,"S34122D" ,"S34122S" ,"S34123A" ,"S34123D" ,"S34123S" ,"S34124A" ,"S34124D" ,"S34124S" ,"S34125A" ,"S34125D" ,"S34125S" ,"S34129A" ,"S34129D" ,"S34129S" ,"S34131A" ,"S34131D" ,"S34131S" ,"S34132A" ,"S34132D" ,"S34132S" ,"S34139A" ,"S34139D" ,"S34139S" ,"S343XXA"))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].DISCHARGE_CONDITION_CODE ="CC-72"
 ENDIF
 if (nom.source_identifier in (
 "G1220"
,"G1221"
,"G1222"
,"G1223"
,"G1224"
,"G1225"
,"G1229"
))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].DISCHARGE_CONDITION_CODE ="CC-73"
endif
 if (nom.source_identifier in (
"G800"
,"G801"
,"G802"
,"G803"
,"G804"
,"G808"
,"G809"
))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].DISCHARGE_CONDITION_CODE ="CC-74"
 ENDIF
 if (nom.source_identifier in ("D8682" ,"E0840" ,"E0842" ,"E0940" ,"E0942" ,"E1040" ,"E1042" ,"E1140" ,"E1142" ,"E1340" ,"E1342" ,"G130" ,"G131" ,"G600" ,"G601" ,"G602" ,"G603" ,"G608" ,"G609" ,"G610" ,"G611" ,"G6181" ,"G6182" ,"G6189" ,"G619" ,"G620" ,"G621" ,"G622" ,"G6281" ,"G6282" ,"G6289" ,"G629" ,"G63" ,"G64" ,"G650" ,"G651" ,"G652" ,"G7000" ,"G7001" ,"G701" ,"G702" ,"G7080" ,"G7081" ,"G7089" ,"G709" ,"G7112" ,"G7113" ,"G7114" ,"G7119" ,"G713" ,"G718" ,"G719" ,"G720" ,"G721" ,"G722" ,"G723" ,"G7241" ,"G7249" ,"G7281" ,"G7289" ,"G729" ,"G731" ,"G733" ,"G737" ,"G9001" ,"G9009" ,"G902" ,"G904" ,"G9050" ,"G90511" ,"G90512" ,"G90513" ,"G90519" ,"G90521" ,"G90522" ,"G90523" ,"G90529" ,"G9059" ,"G908" ,"G909" ,"G990" ,"M0540" ,"M05411" ,"M05412" ,"M05419" ,"M05421" ,"M05422" ,"M05429" ,"M05431" ,"M05432" ,"M05439" ,"M05441" ,"M05442" ,"M05449" ,"M05451" ,"M05452" ,"M05459" ,"M05461" ,"M05462" ,"M05469"
  ,"M05471" ,"M05472" ,"M05479" ,"M0549" ,"M0550" ,"M05511" ,"M05512" ,"M05519"
  ,"M05521" ,"M05522" ,"M05529" ,"M05531" ,"M05532" ,"M05539" ,"M05541" ,"M05542" ,"M05549" ,"M05551" ,"M05552" ,"M05559" ,"M05561" ,"M05562" ,"M05569" ,"M05571" ,"M05572" ,"M05579" ,"M0559" ,"M3302" ,"M3312" ,"M3322" ,"M3392" ,"M3482" ,"M3483" ,"M3503"))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].DISCHARGE_CONDITION_CODE ="CC-75"
endif
 if (nom.source_identifier in (
"G710"
,"G7100"
,"G7101"
,"G7102"
,"G7109"
,"G7111"
,"G712"
))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].DISCHARGE_CONDITION_CODE ="CC-76"
endif
 if (nom.source_identifier in ("G35" ,"G360" ,"G361" ,"G368" ,"G369" ,"G370" ,"G371" ,"G372" ,"G375" ,"G378" ,"G379"))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].DISCHARGE_CONDITION_CODE ="CC-77"
 ENDIF
 if (nom.source_identifier in ("G10" ,"G20" ,"G2111" ,"G2119" ,"G212" ,"G213" ,"G214" ,"G218" ,"G219" ,"G230" ,"G231" ,"G232" ,"G238" ,"G239" ,"G903"))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].DISCHARGE_CONDITION_CODE ="CC-78"
endif
 if (nom.source_identifier in ("G40001" ,"G40009" ,"G40011" ,"G40019" ,"G40101" ,"G40109" ,"G40111" ,"G40119" ,"G40201" ,"G40209" ,"G40211" ,"G40219" ,"G40301" ,"G40309" ,"G40311" ,"G40319" ,"G40401" ,"G40409" ,"G40411" ,"G40419" ,"G40501" ,"G40509" ,"G40801" ,"G40802" ,"G40803" ,"G40804" ,"G40811" ,"G40812" ,"G40813" ,"G40814" ,"G40821" ,"G40822" ,"G40823" ,"G40824" ,"G4089" ,"G40901" ,"G40909" ,"G40911" ,"G40919" ,"G40A01" ,"G40A09" ,"G40A11" ,"G40A19" ,"G40B01" ,"G40B09" ,"G40B11" ,"G40B19" ,"R5600" ,"R5601" ,"R561" ,"R569"))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].DISCHARGE_CONDITION_CODE ="CC-79"
 ENDIF
 if (nom.source_identifier in ("C770" ,"C771" ,"C772" ,"C774" ,"C775" ,"C778" ,"C7800" ,"C7801" ,"C7802" ,"C781" ,"C782" ,"C7830" ,"C7839" ,"C784" ,"C785" ,"C786" ,"C787" ,"C7880" ,"C7889" ,"C7900" ,"C7901" ,"C7902" ,"C7910" ,"C7911" ,"C7919" ,"C7931" ,"C7932" ,"C7940" ,"C7949" ,"C7951" ,"C7952" ,"C7960" ,"C7961" ,"C7962" ,"C7970" ,"C7971" ,"C7972" ,"C7989" ,"C799" ,"C7B00" ,"C7B01" ,"C7B02" ,"C7B03" ,"C7B04" ,"C7B09" ,"C7B1" ,"C7B8" ,"C800" ,"C9100" ,"C9101" ,"C9102" ,"C9200" ,"C9201" ,"C9202" ,"C9240" ,"C9241" ,"C9242" ,"C9250" ,"C9251" ,"C9252" ,"C9260" ,"C9261" ,"C9262" ,"C92A0" ,"C92A1" ,"C92A2" ,"C9300" ,"C9301" ,"C9302" ,"C9400" ,"C9401" ,"C9402" ,"C9420" ,"C9421" ,"C9422" ,"C9440" ,"C9441" ,"C9442" ,"C9500" ,"C9501" ,"C9502"))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].DISCHARGE_CONDITION_CODE ="CC-8"
endif
if (nom.source_identifier in ("G931" ,"G935" ,"G936" ,"R4020" ,"R402110" ,"R402111" ,"R402112" ,"R402113" ,"R402114" ,"R402120" ,"R402121" ,"R402122" ,"R402123" ,"R402124" ,"R402210" ,"R402211" ,"R402212" ,"R402213" ,"R402214" ,"R402220" ,"R402221" ,"R402222" ,"R402223" ,"R402224" ,"R402310" ,"R402311" ,"R402312" ,"R402313" ,"R402314" ,"R402320" ,"R402321" ,"R402322" ,"R402323" ,"R402324" ,"R402340" ,"R402341" ,"R402342" ,"R402343" ,"R402344" ,"R40243" ,"R402430" ,"R402431" ,"R402432" ,"R402433" ,"R402434" ,"R40244" ,"R402440" ,"R402441" ,"R402442" ,"R402443" ,"R402444" ,"R403"))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].DISCHARGE_CONDITION_CODE ="CC-80"
endif
 if (nom.source_identifier in (
"J9500"
,"J9501"
,"J9502"
,"J9503"
,"J9504"
,"J9509"
,"J95850"
,"J95859"
,"Z430"
,"Z930"
,"Z9911"
,"Z9912"
))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].DISCHARGE_CONDITION_CODE ="CC-82"
 ENDIF
 if (nom.source_identifier in ("R092"))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].DISCHARGE_CONDITION_CODE ="CC-83"
endif
 if (nom.source_identifier in ("I462" ,"I468" ,"I469" ,"I4901" ,"I4902" ,"J80" ,"J810" ,"J951" ,"J952" ,"J953" ,"J95821" ,"J95822" ,"J9600" ,"J9601" ,"J9602" ,"J9610" ,"J9611" ,"J9612" ,"J9620" ,"J9621" ,"J9622" ,"J9690" ,"J9691" ,"J9692" ,"R570" ,"R579" ,"T8111XA"))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].DISCHARGE_CONDITION_CODE ="CC-84"
 ENDIF
 if (nom.source_identifier in ("A3681" ,"B3324" ,"I0981" ,"I110" ,"I130" ,"I132" ,"I2601" ,"I2602" ,"I2609" ,"I270" ,"I271" ,"I272" ,"I2720" ,"I2721" ,"I2722" ,"I2723" ,"I2724" ,"I2729" ,"I2781" ,"I2783" ,"I2789" ,"I279" ,"I280" ,"I281" ,"I288" ,"I289" ,"I420" ,"I421" ,"I422" ,"I423" ,"I424" ,"I425" ,"I426" ,"I427" ,"I428" ,"I429" ,"I43" ,"I501" ,"I5020" ,"I5021" ,"I5022" ,"I5023" ,"I5030" ,"I5031" ,"I5032" ,"I5033" ,"I5040" ,"I5041" ,"I5042" ,"I5043" ,"I50810" ,"I50811" ,"I50812" ,"I50813" ,"I50814" ,"I5082" ,"I5083" ,"I5084" ,"I5089" ,"I509" ,"I514" ,"I515"))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].DISCHARGE_CONDITION_CODE ="CC-85"
endif
 if (nom.source_identifier in ("I2101" ,"I2102" ,"I2109" ,"I2111" ,"I2119" ,"I2121" ,"I2129" ,"I213" ,"I214" ,"I219" ,"I21A1" ,"I21A9" ,"I220" ,"I221" ,"I222" ,"I228" ,"I229" ,"I234" ,"I235" ,"I511" ,"I512"))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].DISCHARGE_CONDITION_CODE ="CC-86"
endif
 if (nom.source_identifier in ("I200" ,"I230" ,"I231" ,"I232" ,"I233" ,"I236" ,"I237" ,"I238" ,"I240" ,"I241" ,"I248" ,"I249" ,"I25110" ,"I25700" ,"I25710" ,"I25720" ,"I25730" ,"I25750" ,"I25760" ,"I25790"))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].DISCHARGE_CONDITION_CODE ="CC-87"
 ENDIF
 if (nom.source_identifier in ("I201" ,"I208" ,"I209" ,"I25111" ,"I25118" ,"I25119" ,"I25701" ,"I25708" ,"I25709" ,"I25711" ,"I25718" ,"I25719" ,"I25721" ,"I25728" ,"I25729" ,"I25731" ,"I25738" ,"I25739" ,"I25751" ,"I25758" ,"I25759" ,"I25761" ,"I25768" ,"I25769" ,"I25791" ,"I25798" ,"I25799"))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].DISCHARGE_CONDITION_CODE ="CC-88"
endif
 if (nom.source_identifier in ("C153" ,"C154" ,"C155" ,"C158" ,"C159" ,"C160" ,"C161" ,"C162" ,"C163" ,"C164" ,"C165" ,"C166" ,"C168" ,"C169" ,"C170" ,"C171" ,"C172" ,"C173" ,"C178" ,"C179" ,"C220" ,"C221" ,"C222" ,"C223" ,"C224" ,"C227" ,"C228" ,"C229" ,"C23" ,"C240" ,"C241" ,"C248" ,"C249" ,"C250" ,"C251" ,"C252" ,"C253" ,"C254" ,"C257" ,"C258" ,"C259" ,"C33" ,"C3400" ,"C3401" ,"C3402" ,"C3410" ,"C3411" ,"C3412" ,"C342" ,"C3430" ,"C3431" ,"C3432" ,"C3480" ,"C3481" ,"C3482" ,"C3490" ,"C3491" ,"C3492" ,"C384" ,"C450" ,"C451" ,"C452" ,"C457" ,"C459" ,"C480" ,"C481" ,"C482" ,"C488" ,"C9000" ,"C9001" ,"C9002" ,"C9010" ,"C9011" ,"C9012" ,"C9020" ,"C9021" ,"C9022" ,"C9210" ,"C9211" ,"C9212" ,"C9220" ,"C9221" ,"C9222" ,"C9230" ,"C9231" ,"C9232" ,"C9290" ,"C9291" ,"C9292" ,"C92Z0" ,"C92Z1" ,"C92Z2" ,"C9310" ,"C9311" ,"C9312" ,"C9330" ,"C9331" ,"C9332" ,"C9390" ,"C9391" ,"C9392" ,"C93Z0" ,"C93Z1" ,"C93Z2" ,"C9430" ,"C9431" ,"C9432" ,"C9480" ,"C9481" ,"C9482"))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].DISCHARGE_CONDITION_CODE ="CC-9"
 ENDIF
 if (nom.source_identifier in (
"I442","I470","I471","I472","I479","I480","I481"
,"I482"
,"I483"
,"I484"
,"I4891"
,"I4892"
,"I492"
,"I495"
))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].DISCHARGE_CONDITION_CODE ="CC-96"
endif
if (nom.source_identifier in ("I6000" ,"I6001" ,"I6002" ,"I6010" ,"I6011" ,"I6012" ,"I602" ,"I6020" ,"I6021" ,"I6022" ,"I6030" ,"I6031" ,"I6032" ,"I604" ,"I6050" ,"I6051" ,"I6052" ,"I606" ,"I607" ,"I608" ,"I609" ,"I610" ,"I611" ,"I612" ,"I613" ,"I614" ,"I615" ,"I616" ,"I618" ,"I619" ,"I6200" ,"I6201" ,"I6202" ,"I6203" ,"I621" ,"I629"))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].DISCHARGE_CONDITION_CODE ="CC-99"
endif
endif
 
if ( dx.diag_type_cd=89)
 
 if (nom.source_identifier in (
"B20","B9735","Z21"
))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_CATEGORY ="CC-1"
endif
 
if (nom.source_identifier in (
"C4000","C4001","C4002","C4010","C4011","C4012","C4020","C4021","C4022","C4030" ,"C4031","C4032","C4080","C4081","C4082","C4090" ,"C4091","C4092","C410","C411","C412","C413","C414","C419","C460" ,"C461" ,"C462" ,"C463" ,"C464" ,"C4650" ,"C4651" ,"C4652" ,"C467" ,"C469" ,"C470" ,"C4710" ,"C4711" ,"C4712" ,"C4720" ,"C4721" ,"C4722" ,"C473" ,"C474" ,"C475" ,"C476" ,"C478" ,"C479" ,"C490" ,"C4910" ,"C4911" ,"C4912" ,"C4920" ,"C4921" ,"C4922" ,"C493" ,"C494" ,"C495" ,"C496" ,"C498" ,"C499" ,"C49A0" ,"C49A1" ,"C49A2" ,"C49A3" ,"C49A4" ,"C49A5" ,"C49A9" ,"C561" ,"C562" ,"C569" ,"C5700" ,"C5701" ,"C5702" ,"C5710" ,"C5711" ,"C5712" ,"C5720" ,"C5721" ,"C5722" ,"C573" ,"C574" ,"C58" ,"C700" ,"C701" ,"C709" ,"C710" ,"C711" ,"C712" ,"C713" ,"C714" ,"C715" ,"C716" ,"C717" ,"C718" ,"C719" ,"C720" ,"C721" ,"C7220" ,"C7221" ,"C7222" ,"C7230" ,"C7231" ,"C7232" ,"C7240" ,"C7241" ,"C7242" ,"C7250" ,"C7259" ,"C729" ,"C7400" ,"C7401" ,"C7402" ,"C7410" ,"C7411" ,"C7412" ,"C7490" ,"C7491" ,"C7492" ,"C751"
 ,"C752" ,"C753" ,"C773" ,"C779" ,"C792" ,"C7981" ,"C7982" ,"C8100" ,"C8101" ,"C8102" ,"C8103" ,"C8104" ,"C8105" ,"C8106" ,"C8107" ,"C8108" ,"C8109" ,"C8110" ,"C8111" ,"C8112" ,"C8113" ,"C8114" ,"C8115" ,"C8116" ,"C8117" ,"C8118" ,"C8119" ,"C8120" ,"C8121" ,"C8122" ,"C8123" ,"C8124" ,"C8125" ,"C8126" ,"C8127" ,"C8128" ,"C8129" ,"C8130" ,"C8131" ,"C8132" ,"C8133" ,"C8134" ,"C8135" ,"C8136" ,"C8137" ,"C8138" ,"C8139" ,"C8140" ,"C8141" ,"C8142" ,"C8143" ,"C8144" ,"C8145" ,"C8146" ,"C8147" ,"C8148" ,"C8149" ,"C8170" ,"C8171" ,"C8172" ,"C8173" ,"C8174" ,"C8175" ,"C8176" ,"C8177" ,"C8178" ,"C8179" ,"C8190" ,"C8191" ,"C8192" ,"C8193" ,"C8194" ,"C8195" ,"C8196" ,"C8197" ,"C8198" ,"C8199" ,"C8200" ,"C8201" ,"C8202" ,"C8203" ,"C8204" ,"C8205" ,"C8206" ,"C8207" ,"C8208" ,"C8209" ,"C8210" ,"C8211" ,"C8212" ,"C8213" ,"C8214" ,"C8215" ,"C8216" ,"C8217" ,"C8218" ,"C8219" ,"C8220" ,"C8221" ,"C8222" ,"C8223" ,"C8224" ,"C8225" ,"C8226" ,"C8227" ,"C8228" ,"C8229" ,"C8230" ,"C8231" ,"C8232" ,"C8233"
  ,"C8234"
,"C8235" ,"C8236" ,"C8237" ,"C8238" ,"C8239" ,"C8240" ,"C8241" ,"C8242" ,"C8243" ,"C8244" ,"C8245" ,"C8246" ,"C8247" ,"C8248" ,
"C8249" ,"C8250" ,"C8251" ,"C8252" ,"C8253" ,"C8254" ,"C8255" ,"C8256" ,"C8257" ,"C8258" ,"C8259" ,"C8260" ,"C8261" ,"C8262" ,"C8263" ,"C8264" ,"C8265" ,"C8266" ,"C8267" ,"C8268" ,"C8269" ,"C8280" ,"C8281" ,"C8282" ,"C8283" ,"C8284" ,"C8285" ,"C8286" ,"C8287" ,"C8288" ,"C8289" ,"C8290" ,"C8291" ,"C8292" ,"C8293" ,"C8294" ,"C8295" ,"C8296" ,"C8297" ,"C8298" ,"C8299" ,"C8300" ,"C8301" ,"C8302" ,"C8303" ,"C8304" ,"C8305" ,"C8306" ,"C8307" ,"C8308" ,"C8309" ,"C8310" ,"C8311" ,"C8312" ,"C8313" ,"C8314" ,"C8315" ,"C8316" ,"C8317" ,"C8318" ,"C8319" ,"C8330" ,"C8331" ,"C8332" ,"C8333" ,"C8334" ,"C8335" ,"C8336" ,"C8337" ,"C8338" ,"C8339" ,"C8350" ,"C8351" ,"C8352" ,"C8353" ,"C8354" ,"C8355" ,"C8356" ,"C8357" ,"C8358" ,"C8359" ,"C8370" ,"C8371" ,"C8372" ,"C8373" ,"C8374" ,"C8375" ,"C8376" ,"C8377" ,"C8378" ,"C8379" ,"C8380" ,"C8381" ,"C8382" ,"C8383" ,"C8384" ,"C8385" ,
"C8386" ,"C8387" ,"C8388" ,"C8389" ,"C8390" ,"C8391" ,"C8392" ,"C8393" ,"C8394" ,"C8395" ,"C8396" ,"C8397" ,"C8398" ,"C8399" ,"C8400" ,"C8401" ,"C8402" ,"C8403" ,"C8404" ,"C8405" ,"C8406" ,"C8407" ,"C8408" ,"C8409" ,"C8410" ,"C8411" ,"C8412" ,"C8413" ,"C8414" ,"C8415" ,"C8416" ,"C8417" ,"C8418" ,"C8419" ,"C8440" ,"C8441" ,"C8442" ,"C8443" ,"C8444" ,"C8445" ,"C8446" ,"C8447" ,"C8448" ,"C8449" ,"C8460" ,"C8461" ,"C8462" ,"C8463" ,"C8464" ,"C8465" ,"C8466" ,"C8467" ,"C8468" ,"C8469" ,"C8470" ,"C8471" ,"C8472" ,"C8473" ,"C8474" ,"C8475" ,"C8476" ,"C8477" ,"C8478" ,"C8479" ,"C8490" ,"C8491" ,"C8492" ,"C8493" ,"C8494" ,"C8495" ,"C8496" ,"C8497" ,"C8498" ,"C8499" ,"C84A0" ,"C84A1" ,"C84A2" ,"C84A3" ,"C84A4" ,"C84A5" ,"C84A6" ,"C84A7" ,"C84A8" ,"C84A9" ,"C84Z0" ,"C84Z1" ,"C84Z2" ,"C84Z3" ,"C84Z4" ,"C84Z5" ,"C84Z6" ,"C84Z7" ,"C84Z8" ,"C84Z9" ,"C8510" ,"C8511" ,"C8512" ,"C8513" ,"C8514" ,"C8515" ,"C8516" ,"C8517" ,"C8518" ,"C8519" ,"C8520" ,"C8521" ,"C8522" ,"C8523" ,"C8524" ,"C8525" ,"C8526"
 ,"C8527" ,"C8528" ,"C8529" ,"C8580" ,"C8581" ,"C8582" ,"C8583" ,"C8584" ,"C8585" ,"C8586" ,"C8587" ,"C8588" ,"C8589" ,"C8590" ,"C8591"
 ,"C8592" ,"C8593" ,"C8594" ,"C8595" ,"C8596" ,"C8597" ,"C8598" ,"C8599" ,"C860" ,"C861" ,"C862" ,"C863" ,"C864" ,"C865" ,"C866" ,"C882" ,"C883" ,"C884" ,"C888" ,"C889" ,"C9030" ,"C9031" ,"C9032" ,"C9110" ,"C9111" ,"C9112" ,"C9130" ,"C9131" ,"C9132" ,"C9140" ,"C9141" ,"C9142" ,"C9150" ,"C9151" ,"C9152" ,"C9160" ,"C9161" ,"C9162" ,"C9190" ,"C9191" ,"C9192" ,"C91A0" ,"C91A1" ,"C91A2" ,"C91Z0" ,"C91Z1" ,"C91Z2" ,"C9510" ,"C9511" ,"C9512" ,"C9590" ,"C9591" ,"C9592" ,"C960" ,"C962" ,"C9620" ,"C9621" ,"C9622" ,"C9629" ,"C964" ,"C965" ,"C966" ,"C969" ,"C96A" ,"C96Z"
 
))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_CATEGORY ="CC-10"
endif
if (nom.source_identifier in ("I6300" ,"I63011" ,"I63012" ,"I63013" ,"I63019" ,"I6302" ,"I63031" ,"I63032" ,"I63033" ,"I63039" ,"I6309" ,"I6310" ,"I63111" ,"I63112" ,"I63113" ,"I63119" ,"I6312" ,"I63131" ,"I63132" ,"I63133" ,"I63139" ,"I6319" ,"I6320" ,"I63211" ,"I63212" ,"I63213" ,"I63219" ,"I6322" ,"I63231" ,"I63232" ,"I63233" ,"I63239" ,"I6329" ,"I6330" ,"I63311" ,"I63312" ,"I63313" ,"I63319" ,"I63321" ,"I63322" ,"I63323" ,"I63329" ,"I63331" ,"I63332" ,"I63333" ,"I63339" ,"I63341" ,"I63342" ,"I63343" ,"I63349" ,"I6339" ,"I6340" ,"I63411" ,"I63412" ,"I63413" ,"I63419" ,"I63421" ,"I63422" ,"I63423" ,"I63429" ,"I63431" ,"I63432" ,"I63433" ,"I63439" ,"I63441" ,"I63442" ,"I63443" ,"I63449" ,"I6349" ,"I6350" ,"I63511" ,"I63512" ,"I63513" ,"I63519" ,"I63521" ,"I63522" ,"I63523" ,"I63529" ,"I63531" ,"I63532" ,"I63533" ,"I63539" ,"I63541" ,"I63542" ,"I63543" ,"I63549" ,"I6359" ,"I636" ,"I638" ,"I6381" ,"I6389" ,"I639" ,"I97810" ,"I97811" ,"I97820" ,"I97821"))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_CATEGORY ="CC-100"
 ENDIF
 if (nom.source_identifier in ("G8100" ,"G8101" ,"G8102" ,"G8103" ,"G8104" ,"G8110" ,"G8111" ,"G8112" ,"G8113" ,"G8114" ,"G8190" ,"G8191" ,"G8192" ,"G8193" ,"G8194" ,"I69051" ,"I69052" ,"I69053" ,"I69054" ,"I69059" ,"I69151" ,"I69152" ,"I69153" ,"I69154" ,"I69159" ,"I69251" ,"I69252" ,"I69253" ,"I69254" ,"I69259" ,"I69351" ,"I69352" ,"I69353" ,"I69354" ,"I69359" ,"I69851" ,"I69852" ,"I69853" ,"I69854" ,"I69859" ,"I69951" ,"I69952" ,"I69953" ,"I69954" ,"I69959"))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_CATEGORY ="CC-103"
 ENDIF
 if (nom.source_identifier in ("G830" ,"G8310" ,"G8311" ,"G8312" ,"G8313" ,"G8314" ,"G8320" ,"G8321" ,"G8322" ,"G8323" ,"G8324" ,"G8330"
 
 ,"G8331" ,"G8332" ,"G8333" ,"G8334" ,"G835" ,"G8381" ,"G8382" ,"G8383" ,"G8384" ,"G8389" ,"G839" ,"I69031" ,"I69032" ,"I69033" ,"I69034"
  ,"I69039" ,"I69041" ,"I69042" ,"I69043" ,"I69044" ,"I69049" ,"I69061" ,"I69062" ,"I69063" ,"I69064" ,"I69065" ,"I69069" ,"I69131"
  ,"I69132" ,"I69133" ,"I69134" ,"I69139" ,"I69141" ,"I69142" ,"I69143" ,"I69144" ,"I69149" ,"I69161" ,"I69162" ,"I69163" ,"I69164" ,"I69165"
  ,"I69169" ,"I69231" ,"I69232" ,"I69233" ,"I69234" ,"I69239" ,"I69241" ,"I69242" ,"I69243" ,"I69244" ,"I69249" ,"I69261" ,"I69262" ,"I69263" ,"I69264" ,"I69265" ,"I69269" ,"I69331" ,"I69332" ,"I69333" ,"I69334" ,"I69339" ,"I69341" ,"I69342" ,"I69343" ,"I69344" ,"I69349" ,"I69361" ,"I69362" ,"I69363" ,"I69364" ,"I69365" ,"I69369" ,"I69831" ,"I69832" ,"I69833" ,"I69834" ,"I69839" ,"I69841" ,"I69842" ,"I69843" ,"I69844" ,"I69849" ,"I69861" ,"I69862"
  ,"I69863" ,"I69864" ,"I69865" ,"I69869" ,"I69931" ,"I69932" ,"I69933" ,"I69934" ,"I69939" ,"I69941" ,"I69942" ,"I69943" ,"I69944" ,"I69949" ,"I69961" ,"I69962" ,"I69963" ,"I69964" ,"I69965" ,"I69969"))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_CATEGORY ="CC-104"
 ENDIF
 if (nom.source_identifier in ("A480" ,"E0852" ,"E0952" ,"E1052" ,"E1152" ,"E1352" ,"I70231" ,"I70232" ,"I70233" ,"I70234" ,"I70235" ,"I70238" ,"I70239" ,"I70241" ,"I70242" ,"I70243" ,"I70244" ,"I70245" ,"I70248" ,"I70249" ,"I7025" ,"I70261" ,"I70262" ,"I70263" ,"I70268" ,"I70269" ,"I70331" ,"I70332" ,"I70333" ,"I70334" ,"I70335" ,"I70338" ,"I70339" ,"I70341" ,"I70342" ,"I70343" ,"I70344" ,"I70345" ,"I70348" ,"I70349" ,"I7035" ,"I70361" ,"I70362" ,"I70363" ,"I70368" ,"I70369" ,"I70431" ,"I70432" ,"I70433" ,"I70434" ,"I70435" ,"I70438" ,"I70439" ,"I70441" ,"I70442" ,"I70443" ,"I70444" ,"I70445" ,"I70448" ,"I70449" ,"I7045" ,"I70461" ,"I70462" ,"I70463" ,"I70468" ,"I70469" ,"I70531" ,"I70532" ,"I70533" ,"I70534" ,"I70535" ,"I70538" ,"I70539" ,"I70541" ,"I70542" ,"I70543" ,"I70544" ,"I70545" ,"I70548" ,"I70549" ,"I7055" ,"I70561" ,"I70562" ,"I70563" ,"I70568" ,"I70569" ,"I70631" ,"I70632" ,"I70633" ,"I70634" ,"I70635" ,"I70638" ,"I70639" ,"I70641" ,"I70642" ,"I70643" ,"I70644" ,"I70645" ,
"I70648" ,"I70649" ,"I7065" ,"I70661" ,"I70662" ,"I70663" ,"I70668" ,"I70669" ,"I70731" ,"I70732" ,"I70733" ,"I70734" ,"I70735" ,"I70738" ,"I70739" ,"I70741" ,"I70742" ,"I70743" ,"I70744" ,"I70745" ,"I70748" ,"I70749" ,"I7075" ,"I70761" ,"I70762" ,"I70763" ,"I70768" ,"I70769" ,"I7301" ,"I96"))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_CATEGORY ="CC-106"
 ENDIF
 if (nom.source_identifier in ( "I2601" ,"I2602" ,"I2609" ,"I2690" ,"I2692" ,"I2699" ,"I2782" ,"I670" ,"I7100" ,"I7101" ,"I7102" ,"I7103" ,"I711" ,"I713" ,"I715" ,"I718" ,"I7401" ,"I7409" ,"I7410" ,"I7411" ,"I7419" ,"I742" ,"I743" ,"I744" ,"I745" ,"I748" ,"I749" ,"I75011" ,"I75012" ,"I75013" ,"I75019" ,"I75021" ,"I75022" ,"I75023" ,"I75029" ,"I7581" ,"I7589" ,"I76" ,"I7770" ,"I7771" ,"I7772" ,"I7773" ,"I7774" ,"I7775" ,"I7776" ,"I7777" ,"I7779" ,"I83001" ,"I83002" ,"I83003" ,"I83004" ,"I83005" ,"I83008" ,"I83009" ,"I83011" ,"I83012" ,"I83013" ,"I83014" ,"I83015" ,"I83018" ,"I83019" ,"I83021" ,"I83022" ,"I83023" ,"I83024" ,"I83025" ,"I83028" ,"I83029" ,"I83201" ,"I83202" ,"I83203" ,"I83204" ,"I83205" ,"I83208" ,"I83209" ,"I83211" ,"I83212" ,"I83213" ,"I83214" ,"I83215" ,"I83218" ,"I83219" ,"I83221" ,"I83222" ,"I83223" ,"I83224" ,"I83225" ,"I83228" ,"I83229" ,"I87011" ,"I87012" ,"I87013" ,"I87019" ,"I87031" ,"I87032" ,"I87033" ,"I87039" ,"I87311" ,"I87312" ,"I87313" ,"I87319" ,"I87331" ,
"I87332" ,"I87333" ,"I87339" ,"K550" ,"K55011" ,"K55012" ,"K55019" ,"K55021" ,"K55022" ,"K55029" ,"K55031" ,"K55032" ,"K55039" ,"K55041" ,"K55042" ,"K55049" ,"K55051" ,"K55052" ,"K55059" ,"K55061" ,"K55062" ,"K55069" ,"K5530" ,"K5531" ,"K5532" ,"K5533" ,"N280"))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_CATEGORY ="CC-107"
 ENDIF
 if (nom.source_identifier in ("E0851" ,"E0852" ,"E0951" ,"E0952" ,"E1051" ,"E1052" ,"E1151" ,"E1152" ,"E1351" ,"E1352" ,"I700" ,"I701" ,"I70201" ,"I70202" ,"I70203" ,"I70208" ,"I70209" ,"I70211" ,"I70212" ,"I70213" ,"I70218" ,"I70219" ,"I70221" ,"I70222" ,"I70223" ,"I70228" ,"I70229" ,"I70291" ,"I70292" ,"I70293" ,"I70298" ,"I70299" ,"I70301" ,"I70302" ,"I70303" ,"I70308" ,"I70309" ,"I70311" ,"I70312" ,"I70313" ,"I70318" ,"I70319" ,"I70321" ,"I70322" ,"I70323" ,"I70328" ,"I70329" ,"I70391" ,"I70392" ,"I70393" ,"I70398" ,"I70399" ,"I70401" ,"I70402" ,"I70403" ,"I70408" ,"I70409" ,"I70411" ,"I70412" ,"I70413" ,"I70418" ,"I70419" ,"I70421" ,"I70422" ,"I70423" ,"I70428" ,"I70429" ,"I70491" ,"I70492" ,"I70493" ,"I70498" ,"I70499" ,"I70501" ,"I70502" ,"I70503" ,"I70508" ,"I70509" ,"I70511" ,"I70512" ,"I70513" ,"I70518" ,"I70519" ,"I70521" ,"I70522" ,"I70523" ,"I70528" ,"I70529" ,"I70591" ,"I70592" ,"I70593" ,"I70598" ,"I70599" ,"I70601" ,"I70602" ,"I70603" ,"I70608" ,"I70609" ,"I70611" ,
 "I70612" ,"I70613" ,"I70618" ,"I70619" ,"I70621" ,"I70622" ,"I70623" ,"I70628" ,"I70629" ,"I70691" ,"I70692" ,"I70693" ,"I70698" ,"I70699" ,"I70701" ,"I70702" ,"I70703" ,"I70708" ,"I70709" ,"I70711" ,"I70712" ,"I70713" ,"I70718" ,"I70719" ,"I70721" ,"I70722" ,"I70723" ,"I70728" ,"I70729" ,"I70791" ,"I70792" ,"I70793" ,"I70798" ,"I70799" ,"I7092" ,"I712" ,"I714" ,"I716" ,"I719" ,"I720" ,"I721" ,"I722" ,"I723" ,"I724" ,"I725" ,"I726" ,"I728" ,"I729" ,"I731" ,"I7381" ,"I7389" ,"I739" ,"I770" ,"I771" ,"I772" ,"I773" ,"I774" ,"I775" ,"I776" ,"I77810" ,"I77811" ,"I77812" ,"I77819" ,"I7789" ,"I779" ,"I780" ,"I790" ,"I791" ,"I798" ,"I8010" ,"I8011" ,"I8012" ,"I8013" ,"I80201" ,"I80202" ,"I80203" ,"I80209" ,"I80211" ,"I80212" ,"I80213" ,"I80219" ,"I80221" ,"I80222" ,"I80223" ,"I80229" ,"I80231" ,"I80232" ,"I80233" ,"I80239" ,"I80291" ,"I80292" ,"I80293" ,"I80299" ,"I820" ,"I82210" ,"I82211" ,"I82220" ,"I82221" ,"I82290" ,"I82291" ,"I823" ,"I82401" ,"I82402" ,"I82403" ,"I82409" ,"I82411"
 ,"I82412"
,"I82413" ,"I82419" ,"I82421" ,"I82422" ,"I82423" ,"I82429" ,"I82431" ,"I82432" ,"I82433" ,"I82439" ,"I82441" ,"I82442" ,"I82443" ,"I82449" ,"I82491" ,"I82492" ,"I82493" ,"I82499" ,"I824Y1" ,"I824Y2" ,"I824Y3" ,"I824Y9" ,"I824Z1" ,"I824Z2" ,"I824Z3" ,"I824Z9" ,"I82501" ,"I82502" ,"I82503" ,"I82509" ,"I82511" ,"I82512" ,"I82513" ,"I82519" ,"I82521" ,"I82522" ,"I82523" ,"I82529" ,"I82531" ,"I82532" ,"I82533" ,"I82539" ,"I82541" ,"I82542" ,"I82543" ,"I82549" ,"I82591" ,"I82592" ,"I82593" ,"I82599" ,"I825Y1" ,"I825Y2" ,"I825Y3" ,"I825Y9" ,"I825Z1" ,"I825Z2" ,"I825Z3" ,"I825Z9" ,"I82621" ,"I82622" ,"I82623" ,"I82629" ,"I82721" ,"I82722" ,"I82723" ,"I82729" ,"I82A11" ,"I82A12" ,"I82A13" ,"I82A19" ,"I82A21" ,"I82A22" ,"I82A23" ,"I82A29" ,"I82B11" ,"I82B12" ,"I82B13" ,"I82B19" ,"I82B21" ,"I82B22" ,"I82B23" ,"I82B29" ,"I82C11" ,"I82C12" ,"I82C13" ,"I82C19" ,"I82C21" ,"I82C22" ,"I82C23" ,"I82C29" ,"K551" ,"K558" ,"K559" ,"M318" ,"M319"))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_CATEGORY ="CC-108"
 ENDIF
 if (nom.source_identifier in ("C01" ,"C020" ,"C021" ,"C022" ,"C023" ,"C024" ,"C028" ,"C029" ,"C030" ,"C031" ,"C039" ,"C040" ,"C041" ,"C048" ,"C049" ,"C050" ,"C051" ,"C052" ,"C058" ,"C059" ,"C060" ,"C061" ,"C062" ,"C0680" ,"C0689" ,"C069" ,"C07" ,"C080" ,"C081" ,"C089" ,"C090" ,"C091" ,"C098" ,"C099" ,"C100" ,"C101" ,"C102" ,"C103" ,"C104" ,"C108" ,"C109" ,"C110" ,"C111" ,"C112" ,"C113" ,"C118" ,"C119" ,"C12" ,"C130" ,"C131" ,"C132" ,"C138" ,"C139" ,"C140" ,"C142" ,"C148" ,"C180" ,"C181" ,"C182" ,"C183" ,"C184" ,"C185" ,"C186" ,"C187" ,"C188" ,"C189" ,"C19" ,"C20" ,"C210" ,"C211" ,"C212" ,"C218" ,"C260" ,"C261" ,"C269" ,"C300" ,"C301" ,"C310" ,"C311" ,"C312" ,"C313" ,"C318" ,"C319" ,"C320" ,"C321" ,"C322" ,"C323" ,"C328" ,"C329" ,"C37" ,"C380" ,"C381" ,"C382" ,"C383" ,"C388" ,"C390" ,"C399" ,"C510" ,"C511" ,"C512" ,"C518" ,"C519" ,"C52" ,"C530" ,"C531" ,"C538" ,"C539" ,"C577" ,"C578" ,"C579" ,"C641" ,"C642" ,"C649" ,"C651" ,"C652" ,"C659" ,"C661" ,"C662" ,"C669" ,"C670" ,"C671" ,"C672"
 ,"C673" ,"C674" ,"C675" ,"C676" ,"C677" ,"C678" ,"C679" ,"C680" ,"C681" ,"C688" ,"C689"))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_CATEGORY ="CC-11"
 ENDIF
 if (nom.source_identifier in ("E840" ,"E8411" ,"E8419" ,"E848" ,"E849"))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_CATEGORY ="CC-110"
 ENDIF
 if (nom.source_identifier in ("J410" ,"J411" ,"J418" ,"J42" ,"J430" ,"J431" ,"J432" ,"J438" ,"J439" ,"J440" ,"J441" ,"J449" ,"J982" ,"J983"))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_CATEGORY ="CC-111"
 ENDIF
 if (nom.source_identifier in ("B4481" ,"D860" ,"D862" ,"J470" ,"J471" ,"J479" ,"J60" ,"J61" ,"J620" ,"J628" ,"J630" ,"J631" ,"J632" ,"J633" ,"J634" ,"J635" ,"J636" ,"J64" ,"J65" ,"J660" ,"J661" ,"J662" ,"J668" ,"J670" ,"J671" ,"J672" ,"J673" ,"J674" ,"J675" ,"J676" ,"J677" ,"J678" ,"J679" ,"J680" ,"J681" ,"J682" ,"J683" ,"J684" ,"J688" ,"J689" ,"J700" ,"J701" ,"J702" ,"J703" ,"J704" ,"J705" ,"J708" ,"J709" ,"J82" ,"J8401" ,"J8402" ,"J8403" ,"J8409" ,"J8410" ,"J84111" ,"J84112" ,"J84113" ,"J84114" ,"J84115" ,"J84116" ,"J84117" ,"J8417" ,"J842" ,"J8481" ,"J8482" ,"J8483" ,"J84841" ,"J84842" ,"J84843" ,"J84848" ,"J8489" ,"J849" ,"J99" ,"M3213" ,"M3301" ,"M3311" ,"M3321" ,"M3391" ,"M3481" ,"M3502" ))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_CATEGORY ="CC-112"
 ENDIF
 if (nom.source_identifier in ("A481" ,"J150" ,"J151" ,"J1520" ,"J15211" ,"J15212" ,"J1529" ,"J155" ,"J156" ,"J158" ,"J690" ,"J691" ,"J698" ,"J95851"
))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_CATEGORY ="CC-114"
 ENDIF
 if (nom.source_identifier in ("A0103" ,"A0222" ,"A065" ,"A202" ,"A212" ,"A221" ,"A420" ,"A430" ,"A5484" ,"B380" ,"B381" ,"B382" ,"B390" ,"B391" ,"B392" ,"B400" ,"B401" ,"B402" ,"B410" ,"B664" ,"B671" ,"J13" ,"J14" ,"J153" ,"J154" ,"J181" ,"J850" ,"J851" ,"J852" ,"J853" ,"J860" ,"J869"))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_CATEGORY ="CC-115"
 ENDIF
 if (nom.source_identifier in ("C430" ,"C4310" ,"C4311" ,"C43111" ,"C43112" ,"C4312" ,"C43121" ,"C43122" ,"C4320" ,"C4321" ,"C4322" ,"C4330"
 ,"C4331" ,"C4339" ,"C434" ,"C4351" ,"C4352" ,"C4359" ,"C4360" ,"C4361" ,"C4362" ,"C4370" ,"C4371" ,"C4372" ,"C438" ,"C439" ,"C4A0" ,"C4A10" ,
 "C4A11" ,"C4A111" ,"C4A112" ,"C4A12" ,"C4A121" ,"C4A122" ,"C4A20" ,"C4A21" ,"C4A22" ,"C4A30" ,"C4A31" ,"C4A39" ,"C4A4" ,"C4A51" ,"C4A52" ,"C4A59" ,"C4A60" ,"C4A61" ,"C4A62" ,"C4A70" ,"C4A71" ,"C4A72" ,"C4A8" ,"C4A9" ,"C50011" ,"C50012" ,"C50019" ,"C50021" ,"C50022" ,"C50029" ,"C50111" ,"C50112" ,"C50119" ,"C50121" ,"C50122" ,"C50129" ,"C50211" ,"C50212" ,"C50219" ,"C50221" ,"C50222" ,"C50229" ,"C50311" ,"C50312" ,"C50319" ,"C50321" ,"C50322" ,"C50329" ,"C50411" ,"C50412" ,"C50419" ,"C50421" ,"C50422" ,"C50429" ,"C50511" ,"C50512" ,"C50519" ,"C50521" ,"C50522" ,"C50529" ,"C50611" ,"C50612" ,"C50619" ,"C50621" ,"C50622" ,"C50629" ,"C50811" ,"C50812" ,"C50819" ,"C50821" ,"C50822" ,"C50829" ,"C50911" ,"C50912" ,
 "C50919" ,"C50921" ,"C50922" ,"C50929" ,"C540" ,"C541" ,"C542" ,"C543" ,"C548" ,"C549" ,"C55" ,"C600" ,"C601" ,"C602" ,"C608" ,"C609" ,"C61" ,"C6200" ,"C6201" ,"C6202" ,"C6210" ,"C6211" ,"C6212" ,"C6290" ,"C6291" ,"C6292" ,"C6300" ,"C6301" ,"C6302" ,"C6310" ,"C6311" ,"C6312" ,"C632" ,"C637" ,"C638" ,"C639" ,"C6900" ,"C6901" ,"C6902" ,"C6910" ,"C6911" ,"C6912" ,"C6920" ,"C6921" ,"C6922" ,"C6930" ,"C6931" ,"C6932" ,"C6940" ,"C6941" ,"C6942" ,"C6950" ,"C6951" ,"C6952" ,"C6960" ,"C6961" ,"C6962" ,"C6980" ,"C6981" ,"C6982" ,"C6990" ,"C6991" ,"C6992" ,"C73" ,"C750" ,"C754" ,"C755" ,"C758" ,"C759" ,"C760" ,"C761" ,"C762" ,"C763" ,"C7640" ,"C7641" ,"C7642" ,"C7650" ,"C7651" ,"C7652" ,"C768" ,"C7A00" ,"C7A010" ,"C7A011" ,"C7A012" ,"C7A019" ,"C7A020" ,"C7A021" ,"C7A022" ,"C7A023" ,"C7A024" ,"C7A025" ,"C7A026" ,"C7A029" ,"C7A090" ,"C7A091" ,"C7A092" ,"C7A093" ,"C7A094" ,"C7A095" ,"C7A096" ,"C7A098" ,"C7A1" ,"C7A8" ,"C801" ,"C802" ,"D030" ,"D0310" ,"D0311" ,"D03111" ,"D03112" ,"D0312" ,"D03121" ,
"D03122" ,"D0320" ,"D0321" ,"D0322" ,"D0330" ,"D0339" ,"D034" ,"D0351" ,"D0352" ,"D0359" ,"D0360" ,"D0361" ,"D0362" ,"D0370" ,"D0371" ,"D0372" ,"D038" ,"D039" ,"D1802" ,"D320" ,"D321" ,"D329" ,"D330" ,"D331" ,"D332" ,"D333" ,"D334" ,"D337" ,"D339" ,"D352" ,"D353" ,"D354" ,"D420" ,"D421" ,"D429" ,"D430" ,"D431" ,"D432" ,"D433" ,"D434" ,"D438" ,"D439" ,"D443" ,"D444" ,"D445" ,"D446" ,"D447" ,"D496" ,"E340" ,"Q8500" ,"Q8501" ,"Q8502" ,"Q8503" ,"Q8509" ,"Q851" ,"Q858" ,"Q859"))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_CATEGORY ="CC-12"
 ENDIF
 if (nom.source_identifier in ("E08351" ,"E083511" ,"E083512" ,"E083513" ,"E083519" ,"E083521" ,"E083522" ,"E083523" ,"E083529" ,"E083531" ,"E083532" ,"E083533" ,"E083539" ,"E083541" ,"E083542" ,"E083543" ,"E083549" ,"E083551" ,"E083552" ,"E083553" ,"E083559" ,"E08359" ,"E083591" ,"E083592" ,"E083593" ,"E083599" ,"E09351" ,"E093511" ,"E093512" ,"E093513" ,"E093519" ,"E093521" ,"E093522" ,"E093523" ,"E093529" ,"E093531" ,"E093532" ,"E093533" ,"E093539" ,"E093541" ,"E093542" ,"E093543" ,"E093549" ,"E093551" ,"E093552" ,"E093553" ,"E093559" ,"E09359" ,"E093591" ,"E093592" ,"E093593" ,"E093599" ,"E10351" ,"E103511" ,"E103512" ,"E103513" ,"E103519" ,"E103521" ,"E103522" ,"E103523" ,"E103529" ,"E103531" ,"E103532" ,"E103533" ,"E103539" ,"E103541" ,"E103542" ,"E103543" ,"E103549" ,"E103551" ,"E103552" ,"E103553" ,"E103559" ,"E10359" ,"E103591" ,"E103592" ,"E103593" ,"E103599" ,"E11351" ,"E113511" ,"E113512" ,"E113513" ,"E113519" ,"E113521" ,"E113522" ,"E113523" ,"E113529"
  ,"E113531" ,"E113532" ,"E113533" ,"E113539" ,"E113541" ,"E113542" ,"E113543" ,"E113549" ,"E113551" ,"E113552" ,"E113553" ,"E113559" ,"E11359" ,"E113591" ,"E113592" ,"E113593" ,"E113599" ,"E13351" ,"E133511" ,"E133512" ,"E133513" ,"E133519" ,"E133521" ,"E133522" ,"E133523" ,"E133529" ,"E133531" ,"E133532" ,"E133533" ,"E133539" ,"E133541" ,"E133542" ,"E133543" ,"E133549" ,"E133551" ,"E133552" ,"E133553" ,"E133559" ,"E13359" ,"E133591" ,"E133592" ,"E133593" ,"E133599" ,"H4310" ,"H4311" ,"H4312" ,"H4313"))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_CATEGORY ="CC-122"
 ENDIF
 if (nom.source_identifier in ("H3532" ,"H353210" ,"H353211" ,"H353212" ,"H353213" ,"H353220" ,"H353221" ,"H353222" ,"H353223" ,"H353230" ,"H353231" ,"H353232" ,"H353233" ,"H353290" ,"H353291" ,"H353292" ,"H353293"))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_CATEGORY ="CC-124"
endif
 if (nom.source_identifier in ("T81502A" ,"T81502D" ,"T81502S" ,"T81512A" ,"T81512D" ,"T81512S" ,"T81522A" ,"T81522D" ,"T81522S" ,"T81532A" ,"T81532D" ,"T81532S" ,"T81592A" ,"T81592D" ,"T81592S" ,"T8241XA" ,"T8241XD" ,"T8241XS" ,"T8242XA" ,"T8242XD" ,"T8242XS" ,"T8243XA" ,"T8243XD" ,"T8243XS" ,"T8249XA" ,"T8249XD" ,"T8249XS" ,"T85611A" ,"T85611D" ,"T85611S" ,"T85621A" ,"T85621D" ,"T85621S" ,"T85631A" ,"T85631D" ,"T85631S" ,"T85691A" ,"T85691D" ,"T85691S" ,"T8571XA" ,"T8571XD" ,"T8571XS" ,"Y622" ,"Z4901" ,"Z4902" ,"Z4931" ,"Z4932" ,"Z9115" ,"Z992"
))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_CATEGORY ="CC-134"
 ENDIF
 if (nom.source_identifier in (
"N170"
,"N171"
,"N172"
,"N178"
,"N179"
))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_CATEGORY ="CC-135"
endif
 if (nom.source_identifier in (
"I120"
,"I1311"
,"I132"
,"N185"
,"N186"
))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_CATEGORY ="CC-136"
 ENDIF
 if (nom.source_identifier in ("N184"))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_CATEGORY ="CC-137"
endif
 if (nom.source_identifier in ("N183"))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_CATEGORY ="CC-138"
 ENDIF
 if (nom.source_identifier in (
"E0822"
,"E0922"
,"E1022"
,"E1122"
,"E1322"
,"I129"
,"I130"
,"I1310"
,"N181"
,"N182"
,"N189"
,"Q6111"
,"Q6119"
))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_CATEGORY ="CC-139"
endif
 if (nom.source_identifier in ("N19"))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_CATEGORY ="CC-140"
 ENDIF
 if (nom.source_identifier in ("A3684" ,"A985" ,"B520" ,"D8684" ,"E0821" ,"E0829" ,"E0921" ,"E0929" ,"E1021" ,"E1029" ,"E1121" ,"E1129" ,"E1321" ,"E1329" ,"M3214" ,"M3215" ,"M3504" ,"N000" ,"N001" ,"N002" ,"N003" ,"N004" ,"N005" ,"N006" ,"N007" ,"N008" ,"N009" ,"N010" ,"N011" ,"N012" ,"N013" ,"N014" ,"N015" ,"N016" ,"N017" ,"N018" ,"N019" ,"N020" ,"N021" ,"N022" ,"N023" ,"N024" ,"N025" ,"N026" ,"N027" ,"N028" ,"N029" ,"N030" ,"N031" ,"N032" ,"N033" ,"N034" ,"N035" ,"N036" ,"N037" ,"N038" ,"N039" ,"N040" ,"N041" ,"N042" ,"N043" ,"N044" ,"N045" ,"N046" ,"N047" ,"N048" ,"N049" ,"N050" ,"N051" ,"N052" ,"N053" ,"N054" ,"N055" ,"N056" ,"N057" ,"N058" ,"N059" ,"N060" ,"N061" ,"N062" ,"N063" ,"N064" ,"N065" ,"N066" ,"N067" ,"N068" ,"N069" ,"N070" ,"N071" ,"N072" ,"N073" ,"N074" ,"N075" ,"N076" ,"N077" ,"N078" ,"N079" ,"N08" ,"N140" ,"N141" ,"N142" ,"N143" ,"N144" ,"N150" ,"N158"))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_CATEGORY ="CC-141"
endif
 if (nom.source_identifier in ("L89004" ,"L89014" ,"L89024" ,"L89104" ,"L89114" ,"L89124" ,"L89134" ,"L89144" ,"L89154" ,"L89204" ,"L89214" ,"L89224" ,"L89304" ,"L89314" ,"L89324" ,"L8944" ,"L89504" ,"L89514" ,"L89524" ,"L89604" ,"L89614" ,"L89624" ,"L89814" ,"L89894" ,"L8994"))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_CATEGORY ="CC-157"
 ENDIF
 if (nom.source_identifier in ("L89000" ,"L89003" ,"L89010" ,"L89013" ,"L89020" ,"L89023" ,"L89100" ,"L89103" ,"L89110" ,"L89113" ,"L89120" ,"L89123" ,"L89130" ,"L89133" ,"L89140" ,"L89143" ,"L89150" ,"L89153" ,"L89200" ,"L89203" ,"L89210" ,"L89213" ,"L89220" ,"L89223" ,"L89300" ,"L89303" ,"L89310" ,"L89313" ,"L89320" ,"L89323" ,"L8943" ,"L8945" ,"L89500" ,"L89503" ,"L89510" ,"L89513" ,"L89520" ,"L89523" ,"L89600" ,"L89603" ,"L89610" ,"L89613" ,"L89620" ,"L89623" ,"L89810" ,"L89813" ,"L89890" ,"L89893" ,"L8993" ,"L8995"))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_CATEGORY ="CC-158"
endif
 if (nom.source_identifier in ("L89002" ,"L89012" ,"L89022" ,"L89102" ,"L89112" ,"L89122" ,"L89132" ,"L89142" ,"L89152" ,"L89202" ,"L89212" ,"L89222" ,"L89302" ,"L89312" ,"L89322" ,"L8942" ,"L89502" ,"L89512" ,"L89522" ,"L89602" ,"L89612" ,"L89622" ,"L89812" ,"L89892" ,"L8992"))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_CATEGORY ="CC-159"
 ENDIF
 if (nom.source_identifier in ("L89000" ,"L89001" ,"L89002" ,"L89003" ,"L89004" ,"L89009" ,"L89010" ,"L89011" ,"L89012" ,"L89013" ,"L89014" ,"L89019" ,"L89020" ,"L89021" ,"L89022" ,"L89023" ,"L89024" ,"L89029" ,"L89100" ,"L89101" ,"L89102" ,"L89103" ,"L89104" ,"L89109" ,"L89110" ,"L89111" ,"L89112" ,"L89113" ,"L89114" ,"L89119" ,"L89120" ,"L89121" ,"L89122" ,"L89123" ,"L89124" ,"L89129" ,"L89130" ,"L89131" ,"L89132" ,"L89133" ,"L89134" ,"L89139" ,"L89140" ,"L89141" ,"L89142" ,"L89143" ,"L89144" ,"L89149" ,"L89150" ,"L89151" ,"L89152" ,"L89153" ,"L89154" ,"L89159" ,"L89200" ,"L89201" ,"L89202" ,"L89203" ,"L89204" ,"L89209" ,"L89210" ,"L89211" ,"L89212" ,"L89213" ,"L89214" ,"L89219" ,"L89220" ,"L89221" ,"L89222" ,"L89223" ,"L89224" ,"L89229" ,"L89300" ,"L89301" ,"L89302" ,"L89303" ,"L89304" ,"L89309" ,"L89310" ,"L89311" ,"L89312" ,"L89313" ,"L89314" ,"L89319" ,"L89320" ,"L89321" ,"L89322" ,"L89323" ,"L89324" ,"L89329" ,"L8940" ,"L8941" ,"L8942" ,"L8943" ,"L8944" ,"L8945" ,"L89500"
 ,"L89501" ,"L89502" ,"L89503" ,"L89504" ,"L89509" ,"L89510" ,"L89511" ,"L89512" ,"L89513" ,"L89514" ,"L89519" ,"L89520" ,"L89521" ,"L89522" ,"L89523" ,"L89524" ,"L89529" ,"L89600" ,"L89601" ,"L89602" ,"L89603" ,"L89604" ,"L89609" ,"L89610" ,"L89611" ,"L89612" ,"L89613" ,"L89614" ,"L89619" ,"L89620" ,"L89621" ,"L89622" ,"L89623" ,"L89624" ,"L89629" ,"L89810" ,"L89811" ,"L89812" ,"L89813" ,"L89814" ,"L89819" ,"L89890" ,"L89891" ,"L89892" ,"L89893" ,"L89894" ,"L89899" ,"L8990" ,"L8991" ,"L8992" ,"L8993" ,"L8994" ,"L8995"))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_CATEGORY ="CC-160"
endif
 if (nom.source_identifier in ("I70231" ,"I70232" ,"I70233" ,"I70234" ,"I70235" ,"I70238" ,"I70239" ,"I70241" ,"I70242" ,"I70243" ,"I70244" ,"I70245" ,"I70248" ,"I70249" ,"I7025" ,"I70331" ,"I70332" ,"I70333" ,"I70334" ,"I70335" ,"I70338" ,"I70339" ,"I70341" ,"I70342" ,"I70343" ,"I70344" ,"I70345" ,"I70348" ,"I70349" ,"I7035" ,"I70431" ,"I70432" ,"I70433" ,"I70434" ,"I70435" ,"I70438" ,"I70439" ,"I70441" ,"I70442" ,"I70443" ,"I70444" ,"I70445" ,"I70448" ,"I70449" ,"I7045" ,"I70531" ,"I70532" ,"I70533" ,"I70534" ,"I70535" ,"I70538" ,"I70539" ,"I70541" ,"I70542" ,"I70543" ,"I70544" ,"I70545" ,"I70548" ,"I70549" ,"I7055" ,"I70631" ,"I70632" ,"I70633" ,"I70634" ,"I70635" ,"I70638" ,"I70639" ,"I70641" ,"I70642" ,"I70643" ,"I70644" ,"I70645" ,"I70648" ,"I70649" ,"I7065" ,"I70731" ,"I70732" ,"I70733" ,"I70734" ,"I70735" ,"I70738" ,"I70739" ,"I70741" ,"I70742" ,"I70743" ,"I70744" ,"I70745" ,"I70748" ,"I70749" ,"I7075" ,"L97101" ,"L97102" ,"L97103" ,"L97104" ,"L97105" ,"L97106" ,"L97108"
  ,"L97109" ,"L97111" ,"L97112" ,"L97113" ,"L97114" ,"L97115" ,"L97116" ,"L97118" ,"L97119" ,"L97121" ,"L97122" ,"L97123" ,"L97124" ,"L97125" ,"L97126" ,"L97128" ,"L97129" ,"L97201" ,"L97202" ,"L97203" ,"L97204" ,"L97205" ,"L97206" ,"L97208" ,"L97209" ,"L97211" ,"L97212" ,"L97213" ,"L97214" ,"L97215" ,"L97216" ,"L97218" ,"L97219" ,"L97221" ,"L97222" ,"L97223" ,"L97224" ,"L97225" ,"L97226" ,"L97228" ,"L97229" ,"L97301" ,"L97302" ,"L97303" ,"L97304" ,"L97305" ,"L97306" ,"L97308" ,"L97309" ,"L97311" ,"L97312" ,"L97313" ,"L97314" ,"L97315" ,"L97316" ,"L97318" ,"L97319" ,"L97321" ,"L97322" ,"L97323" ,"L97324" ,"L97325" ,"L97326" ,"L97328" ,"L97329" ,"L97401" ,"L97402" ,"L97403" ,"L97404" ,"L97405" ,"L97406" ,"L97408" ,"L97409" ,"L97411" ,"L97412" ,"L97413" ,"L97414" ,"L97415" ,"L97416" ,"L97418" ,"L97419" ,"L97421" ,"L97422" ,"L97423" ,"L97424" ,"L97425" ,"L97426" ,"L97428" ,"L97429" ,"L97501" ,"L97502" ,"L97503" ,"L97504" ,"L97505" ,"L97506" ,"L97508" ,"L97509" ,"L97511" ,"L97512"
   ,"L97513" ,"L97514" ,
"L97515" ,"L97516" ,"L97518" ,"L97519" ,"L97521" ,"L97522" ,"L97523" ,"L97524" ,"L97525" ,"L97526" ,"L97528" ,"L97529" ,"L97801" ,"L97802" ,"L97803" ,"L97804" ,"L97805" ,"L97806" ,"L97808" ,"L97809" ,"L97811" ,"L97812" ,"L97813" ,"L97814" ,"L97815" ,"L97816" ,"L97818" ,"L97819" ,"L97821" ,"L97822" ,"L97823" ,"L97824" ,"L97825" ,"L97826" ,"L97828" ,"L97829" ,"L97901" ,"L97902" ,"L97903" ,"L97904" ,"L97905" ,"L97906" ,"L97908" ,"L97909" ,"L97911" ,"L97912" ,"L97913" ,"L97914" ,"L97915" ,"L97916" ,"L97918" ,"L97919" ,"L97921" ,"L97922" ,"L97923" ,"L97924" ,"L97925" ,"L97926" ,"L97928" ,"L97929" ,"L98411" ,"L98412" ,"L98413" ,"L98414" ,"L98415" ,"L98416" ,"L98418" ,"L98419" ,"L98421" ,"L98422" ,"L98423" ,"L98424" ,"L98425" ,"L98426" ,"L98428" ,"L98429" ,"L98491" ,"L98492" ,"L98493" ,"L98494" ,"L98495" ,"L98496" ,"L98498" ,"L98499"))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_CATEGORY ="CC-161"
 ENDIF
 if (nom.source_identifier in ("L1230" ,"L1231" ,"L1235" ,"L511" ,"L512" ,"L513" ,"T3111" ,"T3121" ,"T3122" ,"T3131" ,"T3132" ,"T3133" ,"T3141" ,"T3142" ,"T3143" ,"T3144" ,"T3151" ,"T3152" ,"T3153" ,"T3154" ,"T3155" ,"T3161" ,"T3162" ,"T3163" ,"T3164" ,"T3165" ,"T3166" ,"T3171" ,"T3172" ,"T3173" ,"T3174" ,"T3175" ,"T3176" ,"T3177" ,"T3181" ,"T3182" ,"T3183" ,"T3184" ,"T3185" ,"T3186" ,"T3187" ,"T3188" ,"T3191" ,"T3192" ,"T3193" ,"T3194" ,"T3195" ,"T3196" ,"T3197" ,"T3198" ,"T3199" ,"T3211" ,"T3221" ,"T3222" ,"T3231" ,"T3232" ,"T3233" ,"T3241" ,"T3242" ,"T3243" ,"T3244" ,"T3251" ,"T3252" ,"T3253" ,"T3254" ,"T3255" ,"T3261" ,"T3262" ,"T3263" ,"T3264" ,"T3265" ,"T3266" ,"T3271" ,"T3272" ,"T3273" ,"T3274" ,"T3275" ,"T3276" ,"T3277" ,"T3281" ,"T3282" ,"T3283" ,"T3284" ,"T3285" ,"T3286" ,"T3287" ,"T3288" ,"T3291" ,"T3292" ,"T3293" ,"T3294" ,"T3295" ,"T3296" ,"T3297" ,"T3298" ,"T3299"))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_CATEGORY ="CC-162"
endif
 if (nom.source_identifier in ("S061X3A" ,"S061X4A" ,"S061X5A" ,"S061X6A" ,"S062X3A" ,"S062X4A" ,"S062X5A" ,"S062X6A" ,"S06303A" ,"S06304A" ,"S06305A" ,"S06306A" ,"S06313A" ,"S06314A" ,"S06315A" ,"S06316A" ,"S06323A" ,"S06324A" ,"S06325A" ,"S06326A" ,"S06333A" ,"S06334A" ,"S06335A" ,"S06336A" ,"S06343A" ,"S06344A" ,"S06345A" ,"S06346A" ,"S06353A" ,"S06354A" ,"S06355A" ,"S06356A" ,"S06363A" ,"S06364A" ,"S06365A" ,"S06366A" ,"S06373A" ,"S06374A" ,"S06375A" ,"S06376A" ,"S06383A" ,"S06384A" ,"S06385A" ,"S06386A" ,"S064X3A" ,"S064X4A" ,"S064X5A" ,"S064X6A" ,"S065X3A" ,"S065X4A" ,"S065X5A" ,"S065X6A" ,"S066X3A" ,"S066X4A" ,"S066X5A" ,"S066X6A" ,"S06813A" ,"S06814A" ,"S06815A" ,"S06816A" ,"S06823A" ,"S06824A" ,"S06825A" ,"S06826A" ,"S06893A" ,"S06894A" ,"S06895A" ,"S06896A" ,"S069X3A" ,"S069X4A" ,"S069X5A" ,"S069X6A"))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_CATEGORY ="CC-166"
 ENDIF
 if (nom.source_identifier in ("S020XXA" ,"S020XXB" ,"S020XXS" ,"S02101A" ,"S02101B" ,"S02101S" ,"S02102A" ,"S02102B" ,"S02102S" ,"S02109A" ,"S02109B" ,"S02109S" ,"S0210XA" ,"S0210XB" ,"S0210XS" ,"S02110A" ,"S02110B" ,"S02110S" ,"S02111A" ,"S02111B" ,"S02111S" ,"S02112A" ,"S02112B" ,"S02112S" ,"S02113A" ,"S02113B" ,"S02113S" ,"S02118A" ,"S02118B" ,"S02118S" ,"S02119A" ,"S02119B" ,"S02119S" ,"S0211AA" ,"S0211AB" ,"S0211AS" ,"S0211BA" ,"S0211BB" ,"S0211BS" ,"S0211CA" ,"S0211CB" ,"S0211CS" ,"S0211DA" ,"S0211DB" ,"S0211DS" ,"S0211EA" ,"S0211EB" ,"S0211ES" ,"S0211FA" ,"S0211FB" ,"S0211FS" ,"S0211GA" ,"S0211GB" ,"S0211GS" ,"S0211HA" ,"S0211HB" ,"S0211HS" ,"S0219XA" ,"S0219XB" ,"S0219XS" ,"S0230XA" ,"S0230XB" ,"S0230XS" ,"S0231XA" ,"S0231XB" ,"S0231XS" ,"S0232XA" ,"S0232XB" ,"S0232XS" ,"S023XXA" ,"S023XXB" ,"S023XXS" ,"S02400A" ,"S02400B" ,"S02400S" ,"S02401A" ,"S02401B" ,"S02401S" ,"S02402A" ,"S02402B" ,"S02402S" ,"S0240AA" ,"S0240AB" ,"S0240AS" ,"S0240BA" ,"S0240BB" ,"S0240BS" ,"S0240CA"
  ,"S0240CB" ,"S0240CS" ,"S0240DA" ,"S0240DB" ,"S0240DS" ,"S0240EA" ,"S0240EB" ,"S0240ES" ,"S0240FA" ,"S0240FB" ,"S0240FS" ,"S02411A" ,"S02411B" ,"S02411S" ,"S02412A" ,"S02412B" ,"S02412S" ,"S02413A" ,"S02413B" ,"S02413S" ,"S0242XA" ,"S0242XB" ,"S0242XS" ,"S02600A" ,"S02600B" ,"S02600S" ,"S02601A" ,"S02601B" ,"S02601S" ,"S02602A" ,"S02602B" ,"S02602S" ,"S02609A" ,"S02609B" ,"S02609S" ,"S02610A" ,"S02610B" ,"S02610S" ,"S02611A" ,"S02611B" ,"S02611S" ,"S02612A" ,"S02612B" ,"S02612S" ,"S0261XA" ,"S0261XB" ,"S0261XS" ,"S02620A" ,"S02620B" ,"S02620S" ,"S02621A" ,"S02621B" ,"S02621S" ,"S02622A" ,"S02622B" ,"S02622S" ,"S0262XA" ,"S0262XB" ,"S0262XS" ,"S02630A" ,"S02630B" ,"S02630S" ,"S02631A" ,"S02631B" ,"S02631S" ,"S02632A" ,"S02632B" ,"S02632S" ,"S0263XA" ,"S0263XB" ,"S0263XS" ,"S02640A" ,"S02640B" ,"S02640S" ,"S02641A" ,"S02641B" ,"S02641S" ,"S02642A" ,"S02642B" ,"S02642S" ,"S0264XA" ,"S0264XB" ,"S0264XS" ,"S02650A" ,"S02650B" ,"S02650S" ,"S02651A" ,"S02651B" ,"S02651S" ,"S02652A"
   ,"S02652B" ,
"S02652S" ,"S0265XA" ,"S0265XB" ,"S0265XS" ,"S0266XA" ,"S0266XB" ,"S0266XS" ,"S02670A" ,"S02670B" ,"S02670S" ,"S02671A" ,"S02671B" ,"S02671S" ,"S02672A" ,"S02672B" ,"S02672S" ,"S0267XA" ,"S0267XB" ,"S0267XS" ,"S0269XA" ,"S0269XB" ,"S0269XS" ,"S0280XA" ,"S0280XB" ,"S0280XS" ,"S0281XA" ,"S0281XB" ,"S0281XS" ,"S0282XA" ,"S0282XB" ,"S0282XS" ,"S028XXA" ,"S028XXB" ,"S028XXS" ,"S0291XA" ,"S0291XB" ,"S0291XS" ,"S0292XA" ,"S0292XB" ,"S0292XS" ,"S060X0S" ,"S060X1S" ,"S060X2S" ,"S060X3A" ,"S060X3S" ,"S060X4A" ,"S060X4S" ,"S060X5A" ,"S060X5S" ,"S060X6A" ,"S060X6S" ,"S060X9S" ,"S061X0A" ,"S061X0S" ,"S061X1A" ,"S061X1S" ,"S061X2A" ,"S061X2S" ,"S061X3S" ,"S061X4S" ,"S061X5S" ,"S061X6S" ,"S061X9A" ,"S061X9S" ,"S062X0A" ,"S062X0S" ,"S062X1A" ,"S062X1S" ,"S062X2A" ,"S062X2S" ,"S062X3S" ,"S062X4S" ,"S062X5S" ,"S062X6S" ,"S062X9A" ,"S062X9S" ,"S06300A" ,"S06300S" ,"S06301A" ,"S06301S" ,"S06302A" ,"S06302S" ,"S06303S" ,"S06304S" ,"S06305S" ,"S06306S" ,"S06309A" ,"S06309S" ,"S06310A" ,"S06310S" ,"S06311A"
,"S06311S" ,"S06312A" ,"S06312S" ,"S06313S" ,"S06314S" ,"S06315S" ,"S06316S" ,"S06319A" ,"S06319S" ,"S06320A" ,"S06320S" ,"S06321A" ,"S06321S" ,"S06322A" ,"S06322S" ,"S06323S" ,"S06324S" ,"S06325S" ,"S06326S" ,"S06329A" ,"S06329S" ,"S06330A" ,"S06330S" ,"S06331A" ,"S06331S" ,"S06332A" ,"S06332S" ,"S06333S" ,"S06334S" ,"S06335S" ,"S06336S" ,"S06339A" ,"S06339S" ,"S06340A" ,"S06340S" ,"S06341A" ,"S06341S" ,"S06342A" ,"S06342S" ,"S06343S" ,"S06344S" ,"S06345S" ,"S06346S" ,"S06349A" ,"S06349S" ,"S06350A" ,"S06350S" ,"S06351A" ,"S06351S" ,"S06352A" ,"S06352S" ,"S06353S" ,"S06354S" ,"S06355S" ,"S06356S" ,"S06359A" ,"S06359S" ,"S06360A" ,"S06360S" ,"S06361A" ,"S06361S" ,"S06362A" ,"S06362S" ,"S06363S" ,"S06364S" ,"S06365S" ,"S06366S" ,"S06369A" ,"S06369S" ,"S06370A" ,"S06370S" ,"S06371A" ,"S06371S" ,"S06372A" ,"S06372S" ,"S06373S" ,"S06374S" ,"S06375S" ,"S06376S" ,"S06379A" ,"S06379S" ,"S06380A" ,"S06380S" ,"S06381A" ,"S06381S" ,"S06382A" ,"S06382S" ,"S06383S" ,"S06384S" ,"S06385S" ,"S06386S"
 ,"S06389A" ,"S06389S" ,"S064X0A" ,"S064X0S" ,"S064X1A" ,"S064X1S" ,"S064X2A" ,"S064X2S" ,"S064X3S" ,"S064X4S" ,"S064X5S" ,"S064X6S" ,"S064X9A" ,"S064X9S" ,"S065X0A" ,"S065X0S" ,"S065X1A" ,"S065X1S" ,"S065X2A" ,"S065X2S" ,"S065X3S" ,"S065X4S" ,"S065X5S" ,"S065X6S" ,"S065X9A" ,"S065X9S" ,"S066X0A" ,"S066X0S" ,"S066X1A" ,"S066X1S" ,"S066X2A" ,"S066X2S" ,"S066X3S" ,"S066X4S" ,"S066X5S" ,"S066X6S" ,"S066X9A" ,"S066X9S" ,"S06810A" ,"S06810S" ,"S06811A" ,"S06811S" ,"S06812A" ,"S06812S" ,"S06813S" ,"S06814S" ,"S06815S" ,"S06816S" ,"S06819A" ,"S06819S" ,"S06820A" ,"S06820S" ,"S06821A" ,"S06821S" ,"S06822A" ,"S06822S" ,"S06823S" ,"S06824S" ,"S06825S" ,"S06826S" ,"S06829A" ,"S06829S" ,"S06890A" ,"S06890S" ,"S06891A" ,"S06891S" ,"S06892A" ,"S06892S" ,"S06893S" ,"S06894S" ,"S06895S" ,"S06896S" ,"S06899A" ,"S06899S" ,"S069X0A" ,"S069X0S" ,"S069X1A" ,"S069X1S" ,"S069X2A" ,"S069X2S" ,"S069X3S" ,"S069X4S" ,"S069X5S" ,"S069X6S" ,"S069X9A" ,"S069X9S"))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_CATEGORY ="CC-167"
endif
 if (nom.source_identifier in ("M4850XA" ,"M4851XA" ,"M4852XA" ,"M4853XA" ,"M4854XA" ,"M4855XA" ,"M4856XA" ,"M4857XA" ,"M4858XA" ,"M8008XA" ,"M8088XA" ,"S12000A" ,"S12000B" ,"S12001A" ,"S12001B" ,"S1201XA" ,"S1201XB" ,"S1202XA" ,"S1202XB" ,"S12030A" ,"S12030B" ,"S12031A" ,"S12031B" ,"S12040A" ,"S12040B" ,"S12041A" ,"S12041B" ,"S12090A" ,"S12090B" ,"S12091A" ,"S12091B" ,"S12100A" ,"S12100B" ,"S12101A" ,"S12101B" ,"S12110A" ,"S12110B" ,"S12111A" ,"S12111B" ,"S12112A" ,"S12112B" ,"S12120A" ,"S12120B" ,"S12121A" ,"S12121B" ,"S12130A" ,"S12130B" ,"S12131A" ,"S12131B" ,"S1214XA" ,"S1214XB" ,"S12150A" ,"S12150B" ,"S12151A" ,"S12151B" ,"S12190A" ,"S12190B" ,"S12191A" ,"S12191B" ,"S12200A" ,"S12200B" ,"S12201A" ,"S12201B" ,"S12230A" ,"S12230B" ,"S12231A" ,"S12231B" ,"S1224XA" ,"S1224XB" ,"S12250A" ,"S12250B" ,"S12251A" ,"S12251B" ,"S12290A" ,"S12290B" ,"S12291A" ,"S12291B" ,"S12300A" ,"S12300B" ,"S12301A" ,"S12301B" ,"S12330A" ,"S12330B" ,"S12331A" ,"S12331B" ,"S1234XA" ,"S1234XB" ,"S12350A"
  ,"S12350B" ,"S12351A" ,"S12351B" ,"S12390A" ,"S12390B" ,"S12391A" ,"S12391B" ,"S12400A" ,"S12400B" ,"S12401A" ,"S12401B" ,"S12430A" ,"S12430B" ,"S12431A" ,"S12431B" ,"S1244XA" ,"S1244XB" ,"S12450A" ,"S12450B" ,"S12451A" ,"S12451B" ,"S12490A" ,"S12490B" ,"S12491A" ,"S12491B" ,"S12500A" ,"S12500B" ,"S12501A" ,"S12501B" ,"S12530A" ,"S12530B" ,"S12531A" ,"S12531B" ,"S1254XA" ,"S1254XB" ,"S12550A" ,"S12550B" ,"S12551A" ,"S12551B" ,"S12590A" ,"S12590B" ,"S12591A" ,"S12591B" ,"S12600A" ,"S12600B" ,"S12601A" ,"S12601B" ,"S12630A" ,"S12630B" ,"S12631A" ,"S12631B" ,"S1264XA" ,"S1264XB" ,"S12650A" ,"S12650B" ,"S12651A" ,"S12651B" ,"S12690A" ,"S12690B" ,"S12691A" ,"S12691B" ,"S128XXA" ,"S129XXA" ,"S22000A" ,"S22000B" ,"S22001A" ,"S22001B" ,"S22002A" ,"S22002B" ,"S22008A" ,"S22008B" ,"S22009A" ,"S22009B" ,"S22010A" ,"S22010B" ,"S22011A" ,"S22011B" ,"S22012A" ,"S22012B" ,"S22018A" ,"S22018B" ,"S22019A" ,"S22019B" ,"S22020A" ,"S22020B" ,"S22021A" ,"S22021B" ,"S22022A" ,"S22022B" ,"S22028A"
   ,"S22028B" ,
"S22029A" ,"S22029B" ,"S22030A" ,"S22030B" ,"S22031A" ,"S22031B" ,"S22032A" ,"S22032B" ,"S22038A" ,"S22038B" ,"S22039A" ,"S22039B" ,"S22040A" ,"S22040B" ,"S22041A" ,"S22041B" ,"S22042A" ,"S22042B" ,"S22048A" ,"S22048B" ,"S22049A" ,"S22049B" ,"S22050A" ,"S22050B" ,"S22051A" ,"S22051B" ,"S22052A" ,"S22052B" ,"S22058A" ,"S22058B" ,"S22059A" ,"S22059B" ,"S22060A" ,"S22060B" ,"S22061A" ,"S22061B" ,"S22062A" ,"S22062B" ,"S22068A" ,"S22068B" ,"S22069A" ,"S22069B" ,"S22070A" ,"S22070B" ,"S22071A" ,"S22071B" ,"S22072A" ,"S22072B" ,"S22078A" ,"S22078B" ,"S22079A" ,"S22079B" ,"S22080A" ,"S22080B" ,"S22081A" ,"S22081B" ,"S22082A" ,"S22082B" ,"S22088A" ,"S22088B" ,"S22089A" ,"S22089B" ,"S32000A" ,"S32000B" ,"S32001A" ,"S32001B" ,"S32002A" ,"S32002B" ,"S32008A" ,"S32008B" ,"S32009A" ,"S32009B" ,"S32010A" ,"S32010B" ,"S32011A" ,"S32011B" ,"S32012A" ,"S32012B" ,"S32018A" ,"S32018B" ,"S32019A" ,"S32019B" ,"S32020A" ,"S32020B" ,"S32021A" ,"S32021B" ,"S32022A" ,"S32022B" ,"S32028A" ,"S32028B" ,"S32029A"
,"S32029B" ,"S32030A" ,"S32030B" ,"S32031A" ,"S32031B" ,"S32032A" ,"S32032B" ,"S32038A" ,"S32038B" ,"S32039A" ,"S32039B" ,"S32040A" ,"S32040B" ,"S32041A" ,"S32041B" ,"S32042A" ,"S32042B" ,"S32048A" ,"S32048B" ,"S32049A" ,"S32049B" ,"S32050A" ,"S32050B" ,"S32051A" ,"S32051B" ,"S32052A" ,"S32052B" ,"S32058A" ,"S32058B" ,"S32059A" ,"S32059B" ,"S3210XA" ,"S3210XB" ,"S32110A" ,"S32110B" ,"S32111A" ,"S32111B" ,"S32112A" ,"S32112B" ,"S32119A" ,"S32119B" ,"S32120A" ,"S32120B" ,"S32121A" ,"S32121B" ,"S32122A" ,"S32122B" ,"S32129A" ,"S32129B" ,"S32130A" ,"S32130B" ,"S32131A" ,"S32131B" ,"S32132A" ,"S32132B" ,"S32139A" ,"S32139B" ,"S3214XA" ,"S3214XB" ,"S3215XA" ,"S3215XB" ,"S3216XA" ,"S3216XB" ,"S3217XA" ,"S3217XB" ,"S3219XA" ,"S3219XB" ,"S322XXA" ,"S322XXB"))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_CATEGORY ="CC-169"
 ENDIF
 if (nom.source_identifier in ("E0800" ,"E0801" ,"E0810" ,"E0811" ,"E08641" ,"E0900" ,"E0901" ,"E0910" ,"E0911" ,"E09641" ,"E1010" ,"E1011" ,"E10641" ,"E1100" ,"E1101" ,"E1110" ,"E1111" ,"E11641" ,"E1300" ,"E1301" ,"E1310" ,"E1311" ,"E13641"))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_CATEGORY ="CC-17"
endif
 if (nom.source_identifier in ("M80051A" ,"M80052A" ,"M80059A" ,"M80851A" ,"M80852A" ,"M80859A" ,"M84451A" ,"M84452A" ,"M84453A" ,"M84459A" ,"M84551A" ,"M84552A" ,"M84553A" ,"M84559A" ,"M84651A" ,"M84652A" ,"M84653A" ,"M84659A" ,"M84754A" ,"M84755A" ,"M84756A" ,"M84757A" ,"M84758A" ,"M84759A" ,"M9701XA" ,"M9702XA" ,"S32301A" ,"S32301B" ,"S32302A" ,"S32302B" ,"S32309A" ,"S32309B" ,"S32311A" ,"S32311B" ,"S32312A" ,"S32312B" ,"S32313A" ,"S32313B" ,"S32314A" ,"S32314B" ,"S32315A" ,"S32315B" ,"S32316A" ,"S32316B" ,"S32391A" ,"S32391B" ,"S32392A" ,"S32392B" ,"S32399A" ,"S32399B" ,"S32401A" ,"S32401B" ,"S32402A" ,"S32402B" ,"S32409A" ,"S32409B" ,"S32411A" ,"S32411B" ,"S32412A" ,"S32412B" ,"S32413A" ,"S32413B" ,"S32414A" ,"S32414B" ,"S32415A" ,"S32415B" ,"S32416A" ,"S32416B" ,"S32421A" ,"S32421B" ,"S32422A" ,"S32422B" ,"S32423A" ,"S32423B" ,"S32424A" ,"S32424B" ,"S32425A" ,"S32425B" ,"S32426A" ,"S32426B" ,"S32431A" ,"S32431B" ,"S32432A" ,"S32432B" ,"S32433A" ,"S32433B" ,"S32434A"
  ,"S32434B" ,"S32435A" ,"S32435B" ,"S32436A" ,"S32436B" ,"S32441A" ,"S32441B" ,"S32442A" ,"S32442B" ,"S32443A" ,"S32443B" ,"S32444A" ,"S32444B" ,"S32445A" ,"S32445B" ,"S32446A" ,"S32446B" ,"S32451A" ,"S32451B" ,"S32452A" ,"S32452B" ,"S32453A" ,"S32453B" ,"S32454A" ,"S32454B" ,"S32455A" ,"S32455B" ,"S32456A" ,"S32456B" ,"S32461A" ,"S32461B" ,"S32462A" ,"S32462B" ,"S32463A" ,"S32463B" ,"S32464A" ,"S32464B" ,"S32465A" ,"S32465B" ,"S32466A" ,"S32466B" ,"S32471A" ,"S32471B" ,"S32472A" ,"S32472B" ,"S32473A" ,"S32473B" ,"S32474A" ,"S32474B" ,"S32475A" ,"S32475B" ,"S32476A" ,"S32476B" ,"S32481A" ,"S32481B" ,"S32482A" ,"S32482B" ,"S32483A" ,"S32483B" ,"S32484A" ,"S32484B" ,"S32485A" ,"S32485B" ,"S32486A" ,"S32486B" ,"S32491A" ,"S32491B" ,"S32492A" ,"S32492B" ,"S32499A" ,"S32499B" ,"S32501A" ,"S32501B" ,"S32502A" ,"S32502B" ,"S32509A" ,"S32509B" ,"S32511A" ,"S32511B" ,"S32512A" ,"S32512B" ,"S32519A" ,"S32519B" ,"S32591A" ,"S32591B" ,"S32592A" ,"S32592B" ,"S32599A" ,"S32599B" ,"S32601A"
   ,"S32601B" ,"S32602A" ,
"S32602B" ,"S32609A" ,"S32609B" ,"S32611A" ,"S32611B" ,"S32612A" ,"S32612B" ,"S32613A" ,"S32613B" ,"S32614A" ,"S32614B" ,"S32615A" ,"S32615B" ,"S32616A" ,"S32616B" ,"S32691A" ,"S32691B" ,"S32692A" ,"S32692B" ,"S32699A" ,"S32699B" ,"S32810A" ,"S32810B" ,"S32811A" ,"S32811B" ,"S3282XA" ,"S3282XB" ,"S3289XA" ,"S3289XB" ,"S329XXA" ,"S329XXB" ,"S72001A" ,"S72001B" ,"S72001C" ,"S72002A" ,"S72002B" ,"S72002C" ,"S72009A" ,"S72009B" ,"S72009C" ,"S72011A" ,"S72011B" ,"S72011C" ,"S72012A" ,"S72012B" ,"S72012C" ,"S72019A" ,"S72019B" ,"S72019C" ,"S72021A" ,"S72021B" ,"S72021C" ,"S72022A" ,"S72022B" ,"S72022C" ,"S72023A" ,"S72023B" ,"S72023C" ,"S72024A" ,"S72024B" ,"S72024C" ,"S72025A" ,"S72025B" ,"S72025C" ,"S72026A" ,"S72026B" ,"S72026C" ,"S72031A" ,"S72031B" ,"S72031C" ,"S72032A" ,"S72032B" ,"S72032C" ,"S72033A" ,"S72033B" ,"S72033C" ,"S72034A" ,"S72034B" ,"S72034C" ,"S72035A" ,"S72035B" ,"S72035C" ,"S72036A" ,"S72036B" ,"S72036C" ,"S72041A" ,"S72041B" ,"S72041C" ,"S72042A" ,"S72042B" ,"S72042C"
,"S72043A" ,"S72043B" ,"S72043C" ,"S72044A" ,"S72044B" ,"S72044C" ,"S72045A" ,"S72045B" ,"S72045C" ,"S72046A" ,"S72046B" ,"S72046C" ,"S72051A" ,"S72051B" ,"S72051C" ,"S72052A" ,"S72052B" ,"S72052C" ,"S72059A" ,"S72059B" ,"S72059C" ,"S72061A" ,"S72061B" ,"S72061C" ,"S72062A" ,"S72062B" ,"S72062C" ,"S72063A" ,"S72063B" ,"S72063C" ,"S72064A" ,"S72064B" ,"S72064C" ,"S72065A" ,"S72065B" ,"S72065C" ,"S72066A" ,"S72066B" ,"S72066C" ,"S72091A" ,"S72091B" ,"S72091C" ,"S72092A" ,"S72092B" ,"S72092C" ,"S72099A" ,"S72099B" ,"S72099C" ,"S72101A" ,"S72101B" ,"S72101C" ,"S72102A" ,"S72102B" ,"S72102C" ,"S72109A" ,"S72109B" ,"S72109C" ,"S72111A" ,"S72111B" ,"S72111C" ,"S72112A" ,"S72112B" ,"S72112C" ,"S72113A" ,"S72113B" ,"S72113C" ,"S72114A" ,"S72114B" ,"S72114C" ,"S72115A" ,"S72115B" ,"S72115C" ,"S72116A" ,"S72116B" ,"S72116C" ,"S72121A" ,"S72121B" ,"S72121C" ,"S72122A" ,"S72122B" ,"S72122C" ,"S72123A" ,"S72123B" ,"S72123C" ,"S72124A" ,"S72124B" ,"S72124C" ,"S72125A" ,"S72125B" ,"S72125C" ,"S72126A"
 ,"S72126B" ,"S72126C" ,"S72131A" ,"S72131B" ,"S72131C" ,"S72132A" ,"S72132B" ,"S72132C" ,"S72133A" ,"S72133B" ,"S72133C" ,"S72134A" ,"S72134B" ,"S72134C" ,"S72135A" ,"S72135B" ,"S72135C" ,"S72136A" ,"S72136B" ,"S72136C" ,"S72141A" ,"S72141B" ,"S72141C" ,"S72142A" ,"S72142B" ,"S72142C" ,"S72143A" ,"S72143B" ,"S72143C" ,"S72144A" ,"S72144B" ,"S72144C" ,"S72145A" ,"S72145B" ,"S72145C" ,"S72146A" ,"S72146B" ,"S72146C" ,"S7221XA" ,"S7221XB" ,"S7221XC" ,"S7222XA" ,"S7222XB" ,"S7222XC" ,"S7223XA" ,"S7223XB" ,"S7223XC" ,"S7224XA" ,"S7224XB" ,"S7224XC" ,"S7225XA" ,"S7225XB" ,"S7225XC" ,"S7226XA" ,"S7226XB" ,"S7226XC" ,"S72301A" ,"S72301B" ,"S72301C" ,"S72302A" ,"S72302B" ,"S72302C" ,"S72309A" ,"S72309B" ,"S72309C" ,"S72321A" ,"S72321B" ,"S72321C" ,"S72322A" ,"S72322B" ,"S72322C" ,"S72323A" ,"S72323B" ,"S72323C" ,"S72324A" ,"S72324B" ,"S72324C" ,"S72325A" ,"S72325B" ,"S72325C" ,"S72326A" ,"S72326B" ,"S72326C" ,"S72331A" ,"S72331B" ,"S72331C" ,"S72332A" ,"S72332B" ,"S72332C" ,"S72333A"
  ,"S72333B" ,"S72333C" ,"S72334A" ,"S72334B" ,"S72334C" ,"S72335A" ,"S72335B" ,"S72335C" ,"S72336A" ,"S72336B" ,"S72336C" ,"S72341A" ,"S72341B" ,"S72341C" ,"S72342A" ,"S72342B" ,"S72342C" ,"S72343A" ,"S72343B" ,"S72343C" ,"S72344A" ,"S72344B" ,"S72344C" ,"S72345A" ,"S72345B" ,"S72345C" ,"S72346A" ,"S72346B" ,"S72346C" ,"S72351A" ,"S72351B" ,"S72351C" ,"S72352A" ,"S72352B" ,"S72352C" ,"S72353A" ,"S72353B" ,"S72353C" ,"S72354A" ,"S72354B" ,"S72354C" ,"S72355A" ,"S72355B" ,"S72355C" ,"S72356A" ,"S72356B" ,"S72356C" ,"S72361A" ,"S72361B" ,"S72361C" ,"S72362A" ,"S72362B" ,"S72362C" ,"S72363A" ,"S72363B" ,"S72363C" ,"S72364A" ,"S72364B" ,"S72364C" ,"S72365A" ,"S72365B" ,"S72365C" ,"S72366A" ,"S72366B" ,"S72366C" ,"S72391A" ,"S72391B" ,"S72391C" ,"S72392A" ,"S72392B" ,"S72392C" ,"S72399A" ,"S72399B" ,"S72399C" ,"S72401A" ,"S72401B" ,"S72401C" ,"S72402A" ,"S72402B" ,"S72402C" ,"S72409A" ,"S72409B" ,"S72409C" ,"S72411A" ,"S72411B" ,"S72411C" ,"S72412A" ,"S72412B" ,"S72412C" ,"S72413A"
   ,"S72413B" ,"S72413C" ,"S72414A" ,"S72414B" ,"S72414C" ,"S72415A" ,"S72415B" ,"S72415C" ,"S72416A" ,"S72416B" ,"S72416C" ,"S72421A" ,"S72421B" ,"S72421C" ,"S72422A" ,"S72422B" ,"S72422C" ,"S72423A" ,"S72423B" ,"S72423C" ,"S72424A" ,"S72424B" ,"S72424C" ,"S72425A" ,"S72425B" ,"S72425C" ,"S72426A" ,"S72426B" ,"S72426C" ,"S72431A" ,"S72431B" ,"S72431C" ,"S72432A" ,"S72432B" ,"S72432C" ,"S72433A" ,"S72433B" ,"S72433C" ,"S72434A" ,"S72434B" ,"S72434C" ,"S72435A" ,"S72435B" ,"S72435C" ,"S72436A" ,"S72436B" ,"S72436C" ,"S72441A" ,"S72441B" ,"S72441C" ,"S72442A" ,"S72442B" ,"S72442C" ,"S72443A" ,"S72443B" ,"S72443C" ,"S72444A" ,"S72444B" ,"S72444C" ,"S72445A" ,"S72445B" ,"S72445C" ,"S72446A" ,"S72446B" ,"S72446C" ,"S72451A" ,"S72451B" ,"S72451C" ,"S72452A" ,"S72452B" ,"S72452C" ,"S72453A" ,"S72453B" ,"S72453C" ,"S72454A" ,"S72454B" ,"S72454C" ,"S72455A" ,"S72455B" ,"S72455C" ,"S72456A" ,"S72456B" ,"S72456C" ,"S72461A" ,"S72461B" ,"S72461C" ,"S72462A" ,"S72462B" ,"S72462C" ,"S72463A"
    ,"S72463B" ,"S72463C" ,"S72464A" ,"S72464B" ,"S72464C" ,"S72465A" ,"S72465B" ,"S72465C" ,"S72466A" ,"S72466B" ,"S72466C" ,"S72471A" ,"S72472A" ,"S72479A" ,"S72491A" ,"S72491B" ,"S72491C" ,"S72492A" ,"S72492B" ,"S72492C" ,"S72499A" ,"S72499B" ,"S72499C" ,"S728X1A" ,"S728X1B" ,"S728X1C" ,"S728X2A" ,"S728X2B" ,"S728X2C" ,"S728X9A" ,"S728X9B" ,"S728X9C" ,"S7290XA" ,"S7290XB" ,"S7290XC" ,"S7291XA" ,"S7291XB" ,"S7291XC" ,"S7292XA" ,"S7292XB" ,"S7292XC" ,"S73001A" ,"S73002A" ,"S73003A" ,"S73004A" ,"S73005A" ,"S73006A" ,"S73011A" ,"S73012A" ,"S73013A" ,"S73014A" ,"S73015A" ,"S73016A" ,"S73021A" ,"S73022A" ,"S73023A" ,"S73024A" ,"S73025A" ,"S73026A" ,"S73031A" ,"S73032A" ,"S73033A" ,"S73034A" ,"S73035A" ,"S73036A" ,"S73041A" ,"S73042A" ,"S73043A" ,"S73044A" ,"S73045A" ,"S73046A" ,"S79001A" ,"S79002A" ,"S79009A" ,"S79011A" ,"S79012A" ,"S79019A" ,"S79091A" ,"S79092A" ,"S79099A" ,"S79101A" ,"S79102A" ,"S79109A" ,"S79111A" ,"S79112A" ,"S79119A" ,"S79121A" ,"S79122A" ,"S79129A" ,"S79131A"
     ,"S79132A" ,"S79139A" ,"S79141A" ,"S79142A" ,"S79149A" ,"S79191A" ,"S79192A" ,"S79199A"))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_CATEGORY ="CC-170"
 ENDIF
 if (nom.source_identifier in ("S48011A" ,"S48012A" ,"S48019A" ,"S48021A" ,"S48022A" ,"S48029A" ,"S48111A" ,"S48112A" ,"S48119A" ,"S48121A" ,"S48122A" ,"S48129A" ,"S48911A" ,"S48912A" ,"S48919A" ,"S48921A" ,"S48922A" ,"S48929A" ,"S58011A" ,"S58012A" ,"S58019A" ,"S58021A" ,"S58022A" ,"S58029A" ,"S58111A" ,"S58112A" ,"S58119A" ,"S58121A" ,"S58122A" ,"S58129A" ,"S58911A" ,"S58912A" ,"S58919A" ,"S58921A" ,"S58922A" ,"S58929A" ,"S68411A" ,"S68412A" ,"S68419A" ,"S68421A" ,"S68422A" ,"S68429A" ,"S68711A" ,"S68712A" ,"S68719A" ,"S68721A" ,"S68722A" ,"S68729A" ,"S78011A" ,"S78012A" ,"S78019A" ,"S78021A" ,"S78022A" ,"S78029A" ,"S78111A" ,"S78112A" ,"S78119A" ,"S78121A" ,"S78122A" ,"S78129A" ,"S78911A" ,"S78912A" ,"S78919A" ,"S78921A" ,"S78922A" ,"S78929A" ,"S88011A" ,"S88012A" ,"S88019A" ,"S88021A" ,"S88022A" ,"S88029A" ,"S88111A" ,"S88112A" ,"S88119A" ,"S88121A" ,"S88122A" ,"S88129A" ,"S88911A" ,"S88912A" ,"S88919A" ,"S88921A" ,"S88922A" ,"S88929A" ,"S98011A" ,"S98012A" ,"S98019A" ,"S98021A"
  ,"S98022A" ,"S98029A" ,"S98111A" ,"S98112A" ,"S98119A" ,"S98121A" ,"S98122A" ,"S98129A" ,"S98131A" ,"S98132A" ,"S98139A" ,"S98141A" ,"S98142A" ,"S98149A" ,"S98211A" ,"S98212A" ,"S98219A" ,"S98221A" ,"S98222A" ,"S98229A" ,"S98311A" ,"S98312A" ,"S98319A" ,"S98321A" ,"S98322A" ,"S98329A" ,"S98911A" ,"S98912A" ,"S98919A" ,"S98921A" ,"S98922A" ,"S98929A" ,"T790XXA" ,"T791XXA" ,"T792XXA" ,"T794XXA" ,"T795XXA" ,"T796XXA" ,"T797XXA" ,"T798XXA" ,"T799XXA" ,"T79A0XA" ,"T79A11A" ,"T79A12A" ,"T79A19A" ,"T79A21A" ,"T79A22A" ,"T79A29A" ,"T79A3XA" ,"T79A9XA" ,"T870X1" ,"T870X2" ,"T870X9" ,"T871X1" ,"T871X2" ,"T871X9" ,"T872"))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_CATEGORY ="CC-173"
endif
 if (nom.source_identifier in ("M96621" ,"M96622" ,"M96629" ,"M96631" ,"M96632" ,"M96639" ,"M9665" ,"M96661" ,"M96662" ,"M96669" ,"M96671" ,"M96672" ,"M96679" ,"M9669" ,"N99510" ,"N99511" ,"N99512" ,"N99518" ,"N99520" ,"N99521" ,"N99522" ,"N99523" ,"N99524" ,"N99528" ,"N99530" ,"N99531" ,"N99532" ,"N99533" ,"N99534" ,"N99538" ,"T82310A" ,"T82311A" ,"T82312A" ,"T82318A" ,"T82319A" ,"T82320A" ,"T82321A" ,"T82322A" ,"T82328A" ,"T82329A" ,"T82330A" ,"T82331A" ,"T82332A" ,"T82338A" ,"T82339A" ,"T82390A" ,"T82391A" ,"T82392A" ,"T82398A" ,"T82399A" ,"T82510A" ,"T82511A" ,"T82513A" ,"T82514A" ,"T82515A" ,"T82518A" ,"T82520A" ,"T82521A" ,"T82523A" ,"T82524A" ,"T82525A" ,"T82528A" ,"T82530A" ,"T82531A" ,"T82533A" ,"T82534A" ,"T82535A" ,"T82538A" ,"T82590A" ,"T82591A" ,"T82593A" ,"T82594A" ,"T82595A" ,"T82598A" ,"T826XXA" ,"T827XXA" ,"T82818A" ,"T82828A" ,"T82838A" ,"T82848A" ,"T82856A" ,"T82858A" ,"T82868A" ,"T82898A" ,"T83010A" ,"T83011A" ,"T83012A" ,"T83018A" ,"T83020A" ,"T83021A" ,"T83022A" ,
"T83028A" ,"T83030A" ,"T83031A" ,"T83032A" ,"T83038A" ,"T83090A" ,"T83091A" ,"T83092A" ,"T83098A" ,"T83110A" ,"T83111A" ,"T83112A" ,"T83113A" ,"T83118A" ,"T83120A" ,"T83121A" ,"T83122A" ,"T83123A" ,"T83128A" ,"T83190A" ,"T83191A" ,"T83192A" ,"T83193A" ,"T83198A" ,"T8321XA" ,"T8322XA" ,"T8323XA" ,"T8324XA" ,"T8325XA" ,"T8329XA" ,"T83410A" ,"T83411A" ,"T83418A" ,"T83420A" ,"T83421A" ,"T83428A" ,"T83490A" ,"T83491A" ,"T83498A" ,"T83510A" ,"T83511A" ,"T83512A" ,"T83518A" ,"T8351XA" ,"T83590A" ,"T83591A" ,"T83592A" ,"T83593A" ,"T83598A" ,"T8359XA" ,"T8361XA" ,"T8362XA" ,"T8369XA" ,"T836XXA" ,"T83711A" ,"T83712A" ,"T83713A" ,"T83714A" ,"T83718A" ,"T83719A" ,"T83721A" ,"T83722A" ,"T83723A" ,"T83724A" ,"T83728A" ,"T83729A" ,"T8379XA" ,"T8381XA" ,"T8382XA" ,"T8383XA" ,"T8384XA" ,"T8385XA" ,"T8386XA" ,"T8389XA" ,"T839XXA" ,"T84010A" ,"T84011A" ,"T84012A" ,"T84013A" ,"T84018A" ,"T84019A" ,"T84020A" ,"T84021A" ,"T84022A" ,"T84023A" ,"T84028A" ,"T84029A" ,"T84030A" ,"T84031A" ,"T84032A" ,"T84033A"
,"T84038A" ,"T84039A" ,"T84040A" ,"T84041A" ,"T84042A" ,"T84043A" ,"T84048A" ,"T84049A" ,"T84050A" ,"T84051A" ,"T84052A" ,"T84053A" ,"T84058A" ,"T84059A" ,"T84060A" ,"T84061A" ,"T84062A" ,"T84063A" ,"T84068A" ,"T84069A" ,"T84090A" ,"T84091A" ,"T84092A" ,"T84093A" ,"T84098A" ,"T84099A" ,"T84110A" ,"T84111A" ,"T84112A" ,"T84113A" ,"T84114A" ,"T84115A" ,"T84116A" ,"T84117A" ,"T84119A" ,"T84120A" ,"T84121A" ,"T84122A" ,"T84123A" ,"T84124A" ,"T84125A" ,"T84126A" ,"T84127A" ,"T84129A" ,"T84190A" ,"T84191A" ,"T84192A" ,"T84193A" ,"T84194A" ,"T84195A" ,"T84196A" ,"T84197A" ,"T84199A" ,"T84210A" ,"T84213A" ,"T84216A" ,"T84218A" ,"T84220A" ,"T84223A" ,"T84226A" ,"T84228A" ,"T84290A" ,"T84293A" ,"T84296A" ,"T84298A" ,"T84310A" ,"T84318A" ,"T84320A" ,"T84328A" ,"T84390A" ,"T84398A" ,"T84410A" ,"T84418A" ,"T84420A" ,"T84428A" ,"T84490A" ,"T84498A" ,"T8450XA" ,"T8451XA" ,"T8452XA" ,"T8453XA" ,"T8454XA" ,"T8459XA" ,"T8460XA" ,"T84610A" ,"T84611A" ,"T84612A" ,"T84613A" ,"T84614A" ,"T84615A" ,"T84619A"
 ,"T84620A" ,"T84621A" ,"T84622A" ,"T84623A" ,"T84624A" ,"T84625A" ,"T84629A" ,"T8463XA" ,"T8469XA" ,"T847XXA" ,"T8481XA" ,"T8482XA" ,"T8483XA" ,"T8484XA" ,"T8485XA" ,"T8486XA" ,"T8489XA" ,"T849XXA" ,"T8501XA" ,"T8502XA" ,"T8503XA" ,"T8509XA" ,"T85110A" ,"T85111A" ,"T85112A" ,"T85113A" ,"T85118A" ,"T85120A" ,"T85121A" ,"T85122A" ,"T85123A" ,"T85128A" ,"T85190A" ,"T85191A" ,"T85192A" ,"T85193A" ,"T85199A" ,"T85615A" ,"T85625A" ,"T85635A" ,"T85695A" ,"T8572XA" ,"T85730A" ,"T85731A" ,"T85732A" ,"T85733A" ,"T85734A" ,"T85735A" ,"T85738A" ,"T8579XA" ,"T85810A" ,"T85820A" ,"T85830A" ,"T85840A" ,"T85850A" ,"T85860A" ,"T85890A" ,"T86842"))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_CATEGORY ="CC-176"
 ENDIF
 if (nom.source_identifier in ("E0821" ,"E0822" ,"E0829" ,"E08311" ,"E08319" ,"E08321" ,"E083211" ,"E083212" ,"E083213" ,"E083219" ,"E08329" ,"E083291" ,"E083292" ,"E083293" ,"E083299" ,"E08331" ,"E083311" ,"E083312" ,"E083313" ,"E083319" ,"E08339" ,"E083391" ,"E083392" ,"E083393" ,"E083399" ,"E08341" ,"E083411" ,"E083412" ,"E083413" ,"E083419" ,"E08349" ,"E083491" ,"E083492" ,"E083493" ,"E083499" ,"E08351" ,"E083511" ,"E083512" ,"E083513" ,"E083519" ,"E083521" ,"E083522" ,"E083523" ,"E083529" ,"E083531" ,"E083532" ,"E083533" ,"E083539" ,"E083541" ,"E083542" ,"E083543" ,"E083549" ,"E083551" ,"E083552" ,"E083553" ,"E083559" ,"E08359" ,"E083591" ,"E083592" ,"E083593" ,"E083599" ,"E0836" ,"E0837X1" ,"E0837X2" ,"E0837X3" ,"E0837X9" ,"E0839" ,"E0840" ,"E0841" ,"E0842" ,"E0843" ,"E0844" ,"E0849" ,"E0851" ,"E0852" ,"E0859" ,"E08610" ,"E08618" ,"E08620" ,"E08621" ,"E08622" ,"E08628" ,"E08630" ,"E08638" ,"E08649" ,"E0865" ,"E0869" ,"E088" ,"E0921" ,"E0922" ,"E0929" ,"E09311" ,"E09319" ,"E09321"
 ,"E093211" ,"E093212" ,"E093213" ,"E093219" ,"E09329" ,"E093291" ,"E093292" ,"E093293" ,"E093299" ,"E09331" ,"E093311" ,"E093312" ,"E093313" ,"E093319" ,"E09339" ,"E093391" ,"E093392" ,"E093393" ,"E093399" ,"E09341" ,"E093411" ,"E093412" ,"E093413" ,"E093419" ,"E09349" ,"E093491" ,"E093492" ,"E093493" ,"E093499" ,"E09351" ,"E093511" ,"E093512" ,"E093513" ,"E093519" ,"E093521" ,"E093522" ,"E093523" ,"E093529" ,"E093531" ,"E093532" ,"E093533" ,"E093539" ,"E093541" ,"E093542" ,"E093543" ,"E093549" ,"E093551" ,"E093552" ,"E093553" ,"E093559" ,"E09359" ,"E093591" ,"E093592" ,"E093593" ,"E093599" ,"E0936" ,"E0937X1" ,"E0937X2" ,"E0937X3" ,"E0937X9" ,"E0939" ,"E0940" ,"E0941" ,"E0942" ,"E0943" ,"E0944" ,"E0949" ,"E0951" ,"E0952" ,"E0959" ,"E09610" ,"E09618" ,"E09620" ,"E09621" ,"E09622" ,"E09628" ,"E09630" ,"E09638" ,"E09649" ,"E0965" ,"E0969" ,"E098" ,"E1021" ,"E1022" ,"E1029" ,"E10311" ,"E10319" ,"E10321" ,"E103211" ,"E103212" ,"E103213" ,"E103219" ,"E10329" ,"E103291" ,"E103292"
 ,"E103293" ,"E103299" ,"E10331" ,"E103311" ,"E103312" ,"E103313" ,"E103319" ,"E10339" ,"E103391" ,"E103392" ,"E103393" ,"E103399" ,"E10341" ,"E103411" ,"E103412" ,"E103413" ,"E103419" ,"E10349" ,"E103491" ,"E103492" ,"E103493" ,"E103499" ,"E10351" ,"E103511" ,"E103512" ,"E103513" ,"E103519" ,"E103521" ,"E103522" ,"E103523" ,"E103529" ,"E103531" ,"E103532" ,"E103533" ,"E103539" ,"E103541" ,"E103542" ,"E103543" ,"E103549" ,"E103551" ,"E103552" ,"E103553" ,"E103559" ,"E10359" ,"E103591" ,"E103592" ,"E103593" ,"E103599" ,"E1036" ,"E1037X1" ,"E1037X2" ,"E1037X3" ,"E1037X9" ,"E1039" ,"E1040" ,"E1041" ,"E1042" ,"E1043" ,"E1044" ,"E1049" ,"E1051" ,"E1052" ,"E1059" ,"E10610" ,"E10618" ,"E10620" ,"E10621" ,"E10622" ,"E10628" ,"E10630" ,"E10638" ,"E10649" ,"E1065" ,"E1069" ,"E108" ,"E1121" ,"E1122" ,"E1129" ,"E11311" ,"E11319" ,"E11321" ,"E113211" ,"E113212" ,"E113213" ,"E113219" ,"E11329" ,"E113291" ,"E113292" ,"E113293" ,"E113299" ,"E11331" ,"E113311" ,"E113312" ,"E113313" ,"E113319" ,"E11339"
 ,"E113391" ,"E113392" ,"E113393" ,"E113399" ,"E11341" ,"E113411" ,"E113412" ,"E113413" ,"E113419" ,"E11349" ,"E113491" ,"E113492" ,"E113493" ,"E113499" ,"E11351" ,"E113511" ,"E113512" ,"E113513" ,"E113519" ,"E113521" ,"E113522" ,"E113523" ,"E113529" ,"E113531" ,"E113532" ,"E113533" ,"E113539" ,"E113541" ,"E113542" ,"E113543" ,"E113549" ,"E113551" ,"E113552" ,"E113553" ,"E113559" ,"E11359" ,"E113591" ,"E113592" ,"E113593" ,"E113599" ,"E1136" ,"E1137X1" ,"E1137X2" ,"E1137X3" ,"E1137X9" ,"E1139" ,"E1140" ,"E1141" ,"E1142" ,"E1143" ,"E1144" ,"E1149" ,"E1151" ,"E1152" ,"E1159" ,"E11610" ,"E11618" ,"E11620" ,"E11621" ,"E11622" ,"E11628" ,"E11630" ,"E11638" ,"E11649" ,"E1165" ,"E1169" ,"E118" ,"E1321" ,"E1322" ,"E1329" ,"E13311" ,"E13319" ,"E13321" ,"E133211" ,"E133212" ,"E133213" ,"E133219" ,"E13329" ,"E133291" ,"E133292" ,"E133293" ,"E133299" ,"E13331" ,"E133311" ,"E133312" ,"E133313" ,"E133319" ,"E13339" ,"E133391" ,"E133392" ,"E133393" ,"E133399" ,"E13341" ,"E133411" ,"E133412"
  ,"E133413"
,"E133419" ,"E13349" ,"E133491" ,"E133492" ,"E133493" ,"E133499" ,"E13351" ,"E133511" ,"E133512" ,"E133513" ,"E133519" ,"E133521" ,"E133522" ,"E133523" ,"E133529" ,"E133531" ,"E133532" ,"E133533" ,"E133539" ,"E133541" ,"E133542" ,"E133543" ,"E133549" ,"E133551" ,"E133552" ,"E133553" ,"E133559" ,"E13359" ,"E133591" ,"E133592" ,"E133593" ,"E133599" ,"E1336" ,"E1337X1" ,"E1337X2" ,"E1337X3" ,"E1337X9" ,"E1339" ,"E1340" ,"E1341" ,"E1342" ,"E1343" ,"E1344" ,"E1349" ,"E1351" ,"E1352" ,"E1359" ,"E13610" ,"E13618" ,"E13620" ,"E13621" ,"E13622" ,"E13628" ,"E13630" ,"E13638" ,"E13649" ,"E1365" ,"E1369" ,"E138"))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_CATEGORY ="CC-18"
endif
 if (nom.source_identifier in ("T8600" ,"T8601" ,"T8602" ,"T8603" ,"T8609" ,"T8620" ,"T8621" ,"T8622" ,"T8623" ,"T86290" ,"T86298" ,"T8630" ,"T8631" ,"T8632" ,"T8633" ,"T8639" ,"T8640" ,"T8641" ,"T8642" ,"T8643" ,"T8649" ,"T865" ,"T86810" ,"T86811" ,"T86812" ,"T86818" ,"T86819" ,"T86850" ,"T86851" ,"T86852" ,"T86858" ,"T86859" ,"Z4821" ,"Z4823" ,"Z4824" ,"Z48280" ,"Z48290" ,"Z941" ,"Z942" ,"Z943" ,"Z944" ,"Z9481" ,"Z9482" ,"Z9483" ,"Z9484" ,"Z95811" ,"Z95812"))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_CATEGORY ="CC-186"
 ENDIF
 if (nom.source_identifier in ("K91850" ,"K91858" ,"K9400" ,"K9401" ,"K9402" ,"K9403" ,"K9409" ,"K9410" ,"K9411" ,"K9412" ,"K9413" ,"K9419" ,"K9420" ,"K9421" ,"K9422" ,"K9423" ,"K9429" ,"K9430" ,"K9431" ,"K9432" ,"K9433" ,"K9439" ,"Z431" ,"Z432" ,"Z433" ,"Z434" ,"Z435" ,"Z436" ,"Z438" ,"Z439" ,"Z931" ,"Z932" ,"Z933" ,"Z934" ,"Z9350" ,"Z9351" ,"Z9352" ,"Z9359" ,"Z936" ,"Z938" ,"Z939"))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_CATEGORY ="CC-188"
endif
 if (nom.source_identifier in ("G546" ,"G547" ,"S48011S" ,"S48012S" ,"S48019S" ,"S48021S" ,"S48022S" ,"S48029S" ,"S48111S" ,"S48112S" ,"S48119S" ,"S48121S" ,"S48122S" ,"S48129S" ,"S48911S" ,"S48912S" ,"S48919S" ,"S48921S" ,"S48922S" ,"S48929S" ,"S58011S" ,"S58012S" ,"S58019S" ,"S58021S" ,"S58022S" ,"S58029S" ,"S58111S" ,"S58112S" ,"S58119S" ,"S58121S" ,"S58122S" ,"S58129S" ,"S58911S" ,"S58912S" ,"S58919S" ,"S58921S" ,"S58922S" ,"S58929S" ,"S68011S" ,"S68012S" ,"S68019S" ,"S68021S" ,"S68022S" ,"S68029S" ,"S68110S" ,"S68111S" ,"S68112S" ,"S68113S" ,"S68114S" ,"S68115S" ,"S68116S" ,"S68117S" ,"S68118S" ,"S68119S" ,"S68120S" ,"S68121S" ,"S68122S" ,"S68123S" ,"S68124S" ,"S68125S" ,"S68126S" ,"S68127S" ,"S68128S" ,"S68129S" ,"S68411S" ,"S68412S" ,"S68419S" ,"S68421S" ,"S68422S" ,"S68429S" ,"S68511S" ,"S68512S" ,"S68519S" ,"S68521S" ,"S68522S" ,"S68529S" ,"S68610S" ,"S68611S" ,"S68612S" ,"S68613S" ,"S68614S" ,"S68615S" ,"S68616S" ,"S68617S" ,"S68618S" ,"S68619S" ,"S68620S" ,"S68621S"
  ,"S68622S" ,"S68623S" ,"S68624S" ,"S68625S" ,"S68626S" ,"S68627S" ,"S68628S" ,"S68629S" ,"S68711S" ,"S68712S" ,"S68719S" ,"S68721S" ,"S68722S" ,"S68729S" ,"S78011D" ,"S78011S" ,"S78012D" ,"S78012S" ,"S78019D" ,"S78019S" ,"S78021D" ,"S78021S" ,"S78022D" ,"S78022S" ,"S78029D" ,"S78029S" ,"S78111D" ,"S78111S" ,"S78112D" ,"S78112S" ,"S78119D" ,"S78119S" ,"S78121D" ,"S78121S" ,"S78122D" ,"S78122S" ,"S78129D" ,"S78129S" ,"S78911D" ,"S78911S" ,"S78912D" ,"S78912S" ,"S78919D" ,"S78919S" ,"S78921D" ,"S78921S" ,"S78922D" ,"S78922S" ,"S78929D" ,"S78929S" ,"S88011D" ,"S88011S" ,"S88012D" ,"S88012S" ,"S88019D" ,"S88019S" ,"S88021D" ,"S88021S" ,"S88022D" ,"S88022S" ,"S88029D" ,"S88029S" ,"S88111D" ,"S88111S" ,"S88112D" ,"S88112S" ,"S88119D" ,"S88119S" ,"S88121D" ,"S88121S" ,"S88122D" ,"S88122S" ,"S88129D" ,"S88129S" ,"S88911D" ,"S88911S" ,"S88912D" ,"S88912S" ,"S88919D" ,"S88919S" ,"S88921D" ,"S88921S" ,"S88922D" ,"S88922S" ,"S88929D" ,"S88929S" ,"S98011D" ,"S98011S" ,"S98012D" ,"S98012S"
   ,"S98019D" ,"S98019S" ,"S98021D" ,"S98021S" ,"S98022D" ,"S98022S" ,"S98029D" ,"S98029S" ,"S98111D" ,"S98111S" ,"S98112D" ,"S98112S" ,"S98119D" ,"S98119S" ,"S98121D" ,"S98121S" ,"S98122D" ,"S98122S" ,"S98129D" ,"S98129S" ,"S98131D" ,"S98131S" ,"S98132D" ,"S98132S" ,"S98139D" ,"S98139S" ,"S98141D" ,"S98141S" ,"S98142D" ,"S98142S" ,"S98149D" ,"S98149S" ,"S98211D" ,"S98211S" ,"S98212D" ,"S98212S" ,"S98219D" ,"S98219S" ,"S98221D" ,"S98221S" ,"S98222D" ,"S98222S" ,"S98229D" ,"S98229S" ,"S98311D" ,"S98311S" ,"S98312D" ,"S98312S" ,"S98319D" ,"S98319S" ,"S98321D" ,"S98321S" ,"S98322D" ,"S98322S" ,"S98329D" ,"S98329S" ,"S98911D" ,"S98911S" ,"S98912D" ,"S98912S" ,"S98919D" ,"S98919S" ,"S98921D" ,"S98921S" ,"S98922D" ,"S98922S" ,"S98929D" ,"S98929S" ,"T8730" ,"T8731" ,"T8732" ,"T8733" ,"T8734" ,"T8740" ,"T8741" ,"T8742" ,"T8743" ,"T8744" ,"T8750" ,"T8751" ,"T8752" ,"T8753" ,"T8754" ,"T8781" ,"T8789" ,"T879" ,"Z44101" ,"Z44102" ,"Z44109" ,"Z44111" ,"Z44112" ,"Z44119" ,"Z44121" ,"Z44122"
    ,"Z44129" ,"Z89411" ,"Z89412"
 ,"Z89419" ,"Z89421" ,"Z89422" ,"Z89429" ,"Z89431" ,"Z89432" ,"Z89439" ,"Z89441" ,"Z89442" ,"Z89449" ,"Z89511" ,"Z89512" ,"Z89519" ,"Z89611" ,"Z89612" ,"Z89619"))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_CATEGORY ="CC-189"
 ENDIF
 if (nom.source_identifier in (
"E089"
,"E099"
,"E109"
,"E119"
,"E139"
,"Z794"
))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_CATEGORY ="CC-19"
endif
 if (nom.source_identifier in ("A021" ,"A207" ,"A227" ,"A267" ,"A327" ,"A392" ,"A393" ,"A394" ,"A400" ,"A401" ,"A403" ,"A408" ,"A409" ,"A4101" ,"A4102" ,"A411" ,"A412" ,"A413" ,"A414" ,"A4150" ,"A4151" ,"A4152" ,"A4153" ,"A4159" ,"A4181" ,"A4189" ,"A419" ,"A427" ,"A483" ,"A5486" ,"B007" ,"B377" ,"P0270" ,"P360" ,"P3610" ,"P3619" ,"P362" ,"P3630" ,"P3639" ,"P364" ,"P365" ,"P368" ,"P369" ,"R571" ,"R578" ,"R6510" ,"R6511" ,"R6520" ,"R6521" ,"T8112XA" ,"T8144XA"))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_CATEGORY ="CC-2"
 ENDIF
 if (nom.source_identifier in ("E40" ,"E41" ,"E42" ,"E43" ,"E440" ,"E441" ,"E45" ,"E46" ,"E640" ,"R64"
))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_CATEGORY ="CC-21"
endif
 if (nom.source_identifier in ("E6601" ,"E662" ,"Z6841" ,"Z6842" ,"Z6843" ,"Z6844" ,"Z6845"))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_CATEGORY ="CC-22"
 ENDIF
 if (nom.source_identifier in ("A391" ,"C880" ,"D841" ,"D891" ,"E035" ,"E15" ,"E200" ,"E208" ,"E209" ,"E210" ,"E211" ,"E212" ,"E213" ,"E214" ,"E215" ,"E220" ,"E221" ,"E222" ,"E228" ,"E229" ,"E230" ,"E231" ,"E232" ,"E233" ,"E236" ,"E237" ,"E240" ,"E241" ,"E242" ,"E243" ,"E244" ,"E248" ,"E249" ,"E250" ,"E258" ,"E259" ,"E2601" ,"E2602" ,"E2609" ,"E261" ,"E2681" ,"E2689" ,"E269" ,"E270" ,"E271" ,"E272" ,"E273" ,"E2740" ,"E2749" ,"E275" ,"E278" ,"E279" ,"E310" ,"E311" ,"E3120" ,"E3121" ,"E3122" ,"E3123" ,"E318" ,"E319" ,"E320" ,"E321" ,"E328" ,"E329" ,"E344" ,"E700" ,"E701" ,"E7020" ,"E7021" ,"E7029" ,"E7030" ,"E70310" ,"E70311" ,"E70318" ,"E70319" ,"E70320" ,"E70321" ,"E70328" ,"E70329" ,"E70330" ,"E70331" ,"E70338" ,"E70339" ,"E7039" ,"E7040" ,"E7041" ,"E7049" ,"E705" ,"E708" ,"E709" ,"E710" ,"E71110" ,"E71111" ,"E71118" ,"E71120" ,"E71121" ,"E71128" ,"E7119" ,"E712" ,"E71310" ,"E71311" ,"E71312" ,"E71313" ,"E71314" ,"E71318" ,"E7132" ,"E7139" ,"E7140" ,"E7141" ,"E7142" ,"E7143" ,"E71440"
 ,"E71448" ,"E7150" ,"E71510" ,"E71511" ,"E71518" ,"E71520" ,"E71521" ,"E71522" ,"E71528" ,"E71529" ,"E7153" ,"E71540" ,"E71541" ,"E71542" ,"E71548" ,"E7200" ,"E7201" ,"E7202" ,"E7203" ,"E7204" ,"E7209" ,"E7210" ,"E7211" ,"E7212" ,"E7219" ,"E7220" ,"E7221" ,"E7222" ,"E7223" ,"E7229" ,"E723" ,"E724" ,"E7250" ,"E7251" ,"E7252" ,"E7253" ,"E7259" ,"E728" ,"E7281" ,"E7289" ,"E729" ,"E7400" ,"E7401" ,"E7402" ,"E7403" ,"E7404" ,"E7409" ,"E7420" ,"E7421" ,"E7429" ,"E744" ,"E748" ,"E749" ,"E7521" ,"E7522" ,"E75240" ,"E75241" ,"E75242" ,"E75243" ,"E75248" ,"E75249" ,"E753" ,"E7601" ,"E7602" ,"E7603" ,"E761" ,"E76210" ,"E76211" ,"E76219" ,"E7622" ,"E7629" ,"E763" ,"E768" ,"E769" ,"E770" ,"E771" ,"E778" ,"E779" ,"E791" ,"E792" ,"E798" ,"E799" ,"E800" ,"E801" ,"E8020" ,"E8021" ,"E8029" ,"E803" ,"E83110" ,"E850" ,"E851" ,"E852" ,"E853" ,"E854" ,"E858" ,"E8581" ,"E8582" ,"E8589" ,"E859" ,"E8801" ,"E8840" ,"E8841" ,"E8842" ,"E8849" ,"E8889" ,"E892" ,"E893" ,"E896" ,"H49811" ,"H49812" ,"H49813"
  ,"H49819" ,"N251" ,"N2581"
))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_CATEGORY ="CC-23"
endif
 if (nom.source_identifier in ("I8500" ,"I8501" ,"I8510" ,"I8511" ,"K7041" ,"K7111" ,"K7201" ,"K7210" ,"K7211" ,"K7290" ,"K7291" ,"K766" ,"K767" ,"K7681"))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_CATEGORY ="CC-27"
 ENDIF
 if (nom.source_identifier in ("K7030" ,"K7031" ,"K7040" ,"K7041" ,"K709" ,"K743" ,"K744" ,"K745" ,"K7460" ,"K7469"))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_CATEGORY ="CC-28"
endif
 if (nom.source_identifier in ("B180" ,"B181" ,"B182" ,"B188" ,"B189" ,"K730" ,"K731" ,"K732" ,"K738" ,"K739" ,"K754"))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_CATEGORY ="CC-29"
 ENDIF
 if (nom.source_identifier in ("A5485" ,"K251" ,"K252" ,"K255" ,"K256" ,"K261" ,"K262" ,"K265" ,"K266" ,"K271" ,"K272" ,"K275" ,"K276" ,"K281" ,"K282" ,"K285" ,"K286" ,"K50012" ,"K50112" ,"K50812" ,"K50912" ,"K51012" ,"K51212" ,"K51312" ,"K51412" ,"K51512" ,"K51812" ,"K51912" ,"K560" ,"K561" ,"K562" ,"K563" ,"K5641" ,"K5649" ,"K565" ,"K5650" ,"K5651" ,"K5652" ,"K5660" ,"K56600" ,"K56601" ,"K56609" ,"K5669" ,"K56690" ,"K56691" ,"K56699" ,"K567" ,"K5931" ,"K631" ,"K650" ,"K651" ,"K652" ,"K653" ,"K654" ,"K658" ,"K659" ,"K67" ,"K6812" ,"K6819"))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_CATEGORY ="CC-33"
endif
 if (nom.source_identifier in (
"K860"
,"K861"
))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_CATEGORY ="CC-34"
endif
 if (nom.source_identifier in ("K5000" ,"K50011" ,"K50012" ,"K50013" ,"K50014" ,"K50018" ,"K50019" ,"K5010" ,"K50111" ,"K50112" ,"K50113" ,"K50114" ,"K50118" ,"K50119" ,"K5080" ,"K50811" ,"K50812" ,"K50813" ,"K50814" ,"K50818" ,"K50819" ,"K5090" ,"K50911" ,"K50912" ,"K50913" ,"K50914" ,"K50918" ,"K50919" ,"K5100" ,"K51011" ,"K51012" ,"K51013" ,"K51014" ,"K51018" ,"K51019" ,"K5120" ,"K51211" ,"K51212" ,"K51213" ,"K51214" ,"K51218" ,"K51219" ,"K5130" ,"K51311" ,"K51312" ,"K51313" ,"K51314" ,"K51318" ,"K51319" ,"K5140" ,"K51411" ,"K51412" ,"K51413" ,"K51414" ,"K51418" ,"K51419" ,"K5150" ,"K51511" ,"K51512" ,"K51513" ,"K51514" ,"K51518" ,"K51519" ,"K5180" ,"K51811" ,"K51812" ,"K51813" ,"K51814" ,"K51818" ,"K51819" ,"K5190" ,"K51911" ,"K51912" ,"K51913" ,"K51914" ,"K51918" ,"K51919"))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_CATEGORY ="CC-35"
 ENDIF
 if (nom.source_identifier in ("A0104" ,"A0105" ,"A0223" ,"A0224" ,"A3983" ,"A3984" ,"A5055" ,"A5440" ,"A5441" ,"A5442" ,"A5443" ,"A5449" ,"A666" ,"A6923" ,"B0682" ,"B2685" ,"B4282" ,"M0000" ,"M00011" ,"M00012" ,"M00019" ,"M00021" ,"M00022" ,"M00029" ,"M00031" ,"M00032" ,"M00039" ,"M00041" ,"M00042" ,"M00049" ,"M00051" ,"M00052" ,"M00059" ,"M00061" ,"M00062" ,"M00069" ,"M00071" ,"M00072" ,"M00079" ,"M0008" ,"M0009" ,"M0010" ,"M00111" ,"M00112" ,"M00119" ,"M00121" ,"M00122" ,"M00129" ,"M00131" ,"M00132" ,"M00139" ,"M00141" ,"M00142" ,"M00149" ,"M00151" ,"M00152" ,"M00159" ,"M00161" ,"M00162" ,"M00169" ,"M00171" ,"M00172" ,"M00179" ,"M0018" ,"M0019" ,"M0020" ,"M00211" ,"M00212" ,"M00219" ,"M00221" ,"M00222" ,"M00229" ,"M00231" ,"M00232" ,"M00239" ,"M00241" ,"M00242" ,"M00249" ,"M00251" ,"M00252" ,"M00259" ,"M00261" ,"M00262" ,"M00269" ,"M00271" ,"M00272" ,"M00279" ,"M0028" ,"M0029" ,"M0080" ,"M00811" ,"M00812" ,"M00819" ,"M00821" ,"M00822" ,"M00829" ,"M00831" ,"M00832" ,"M00839"
  ,"M00841" ,"M00842" ,"M00849" ,"M00851" ,"M00852" ,"M00859" ,"M00861" ,"M00862" ,"M00869" ,"M00871" ,"M00872" ,"M00879" ,"M0088" ,"M0089" ,"M009" ,"M01X0" ,"M01X11" ,"M01X12" ,"M01X19" ,"M01X21" ,"M01X22" ,"M01X29" ,"M01X31" ,"M01X32" ,"M01X39" ,"M01X41" ,"M01X42" ,"M01X49" ,"M01X51" ,"M01X52" ,"M01X59" ,"M01X61" ,"M01X62" ,"M01X69" ,"M01X71" ,"M01X72" ,"M01X79" ,"M01X8" ,"M01X9" ,"M0210" ,"M02111" ,"M02112" ,"M02119" ,"M02121" ,"M02122" ,"M02129" ,"M02131" ,"M02132" ,"M02139" ,"M02141" ,"M02142" ,"M02149" ,"M02151" ,"M02152" ,"M02159" ,"M02161" ,"M02162" ,"M02169" ,"M02171" ,"M02172" ,"M02179" ,"M0218" ,"M0219" ,"M0280" ,"M02811" ,"M02812" ,"M02819" ,"M02821" ,"M02822" ,"M02829" ,"M02831" ,"M02832" ,"M02839" ,"M02841" ,"M02842" ,"M02849" ,"M02851" ,"M02852" ,"M02859" ,"M02861" ,"M02862" ,"M02869" ,"M02871" ,"M02872" ,"M02879" ,"M0288" ,"M0289" ,"M029" ,"M4620" ,"M4621" ,"M4622" ,"M4623" ,"M4624" ,"M4625" ,"M4626" ,"M4627" ,"M4628" ,"M4630" ,"M4631" ,"M4632" ,"M4633" ,"M4634"
   ,"M4635"
 ,"M4636"
 ,"M4637" ,"M4638" ,"M4639" ,"M726" ,"M8600" ,"M86011" ,"M86012" ,"M86019"
 ,"M86021" ,"M86022" ,"M86029" ,"M86031" ,"M86032" ,"M86039" ,"M86041" ,"M86042" ,"M86049" ,"M86051" ,"M86052" ,"M86059" ,"M86061" ,"M86062" ,"M86069" ,"M86071" ,"M86072" ,"M86079" ,"M8608" ,"M8609" ,"M8610" ,"M86111" ,"M86112" ,"M86119" ,"M86121" ,"M86122" ,"M86129" ,"M86131" ,"M86132" ,"M86139" ,"M86141" ,"M86142" ,"M86149" ,"M86151" ,"M86152" ,"M86159" ,"M86161" ,"M86162" ,"M86169" ,"M86171" ,"M86172" ,"M86179" ,"M8618" ,"M8619" ,"M8620" ,"M86211" ,"M86212" ,"M86219" ,"M86221" ,"M86222" ,"M86229" ,"M86231" ,"M86232" ,"M86239" ,"M86241" ,"M86242" ,"M86249" ,"M86251" ,"M86252" ,"M86259" ,"M86261" ,"M86262" ,"M86269" ,"M86271" ,"M86272" ,"M86279" ,"M8628" ,"M8629" ,"M8630" ,"M86311" ,"M86312" ,"M86319" ,"M86321" ,"M86322" ,"M86329" ,"M86331" ,"M86332" ,"M86339" ,"M86341" ,"M86342" ,"M86349" ,"M86351" ,"M86352" ,"M86359" ,"M86361" ,"M86362" ,"M86369" ,"M86371" ,"M86372" ,"M86379" ,"M8638" ,"M8639" ,"M8640"
  ,"M86411" ,"M86412" ,"M86419" ,"M86421" ,"M86422" ,"M86429" ,"M86431" ,"M86432" ,"M86439" ,"M86441" ,"M86442" ,"M86449" ,"M86451" ,"M86452" ,"M86459" ,"M86461" ,"M86462" ,"M86469" ,"M86471" ,"M86472" ,"M86479" ,"M8648" ,"M8649" ,"M8650" ,"M86511" ,"M86512" ,"M86519" ,"M86521" ,"M86522" ,"M86529" ,"M86531" ,"M86532" ,"M86539" ,"M86541" ,"M86542" ,"M86549" ,"M86551" ,"M86552" ,"M86559" ,"M86561" ,"M86562" ,"M86569" ,"M86571" ,"M86572" ,"M86579" ,"M8658" ,"M8659" ,"M8660" ,"M86611" ,"M86612" ,"M86619" ,"M86621" ,"M86622" ,"M86629" ,"M86631" ,"M86632" ,"M86639" ,"M86641" ,"M86642" ,"M86649" ,"M86651" ,"M86652" ,"M86659" ,"M86661" ,"M86662" ,"M86669" ,"M86671" ,"M86672" ,"M86679" ,"M8668" ,"M8669" ,"M868X0" ,"M868X1" ,"M868X2" ,"M868X3" ,"M868X4" ,"M868X5" ,"M868X6" ,"M868X7" ,"M868X8" ,"M868X9" ,"M869" ,"M8700" ,"M87011" ,"M87012" ,"M87019" ,"M87021" ,"M87022" ,"M87029" ,"M87031" ,"M87032" ,"M87033" ,"M87034" ,"M87035" ,"M87036" ,"M87037" ,"M87038" ,"M87039" ,"M87041" ,"M87042" ,"M87043"
 ,"M87044" ,"M87045" ,"M87046" ,"M87050" ,"M87051" ,"M87052" ,"M87059" ,"M87061" ,"M87062" ,"M87063" ,"M87064" ,"M87065" ,"M87066" ,"M87071"
 ,"M87072" ,"M87073" ,"M87074" ,"M87075" ,"M87076" ,"M87077" ,"M87078" ,"M87079" ,"M8708" ,"M8709" ,"M8710" ,"M87111" ,"M87112" ,"M87119"
  ,"M87121" ,"M87122" ,"M87129" ,"M87131" ,"M87132" ,"M87133" ,"M87134" ,"M87135" ,"M87136" ,"M87137" ,"M87138" ,"M87139" ,"M87141" ,"M87142" ,
  "M87143" ,"M87144" ,"M87145" ,"M87146" ,"M87150" ,"M87151" ,"M87152" ,"M87159" ,"M87161" ,"M87162" ,"M87163" ,"M87164" ,"M87165" ,"M87166" ,
  "M87171" ,"M87172" ,"M87173" ,"M87174" ,"M87175" ,"M87176" ,"M87177" ,"M87178" ,"M87179" ,"M87180" ,"M87188" ,"M8719" ,"M8720" ,"M87211"
  ,"M87212" ,"M87219" ,"M87221" ,"M87222" ,"M87229" ,"M87231" ,"M87232" ,"M87233" ,"M87234" ,"M87235" ,"M87236" ,"M87237" ,"M87238" ,"M87239"
  ,"M87241" ,"M87242" ,"M87243" ,"M87244" ,"M87245" ,"M87246" ,"M87250" ,"M87251" ,"M87252" ,"M87256" ,"M87261" ,"M87262" ,"M87263" ,"M87264" ,"M87265" ,"M87266"
   ,"M87271" ,"M87272" ,"M87273" ,"M87274" ,"M87275" ,"M87276" ,"M87277" ,"M87278" ,"M87279" ,"M8728" ,"M8729" ,"M8730" ,"M87311" ,"M87312" ,
   "M87319" ,"M87321" ,"M87322" ,"M87329" ,"M87331" ,"M87332" ,"M87333" ,"M87334" ,"M87335" ,"M87336" ,"M87337" ,"M87338" ,"M87339" ,"M87341" ,"M87342" ,"M87343" ,"M87344" ,"M87345" ,"M87346" ,"M87350" ,"M87351" ,"M87352" ,"M87353" ,"M87361" ,"M87362" ,"M87363" ,"M87364" ,"M87365" ,"M87366" ,"M87371" ,"M87372" ,"M87373" ,"M87374" ,"M87375" ,"M87376" ,"M87377" ,"M87378" ,"M87379" ,"M8738" ,"M8739" ,"M8780" ,"M87811" ,"M87812" ,"M87819" ,"M87821" ,"M87822" ,"M87829" ,"M87831" ,"M87832" ,"M87833" ,"M87834" ,"M87835" ,"M87836" ,"M87837" ,"M87838" ,"M87839" ,"M87841" ,"M87842" ,"M87843" ,"M87844" ,"M87845" ,"M87849" ,"M87850" ,"M87851" ,"M87852" ,"M87859" ,"M87861" ,"M87862" ,"M87863" ,"M87864" ,"M87865" ,"M87869" ,"M87871" ,"M87872" ,"M87873" ,"M87874" ,"M87875" ,"M87876" ,"M87877" ,"M87878" ,"M87879" ,"M8788" ,"M8789" ,"M879" ,"M8960" ,"M89611"
   ,"M89612"
,"M89619" ,"M89621" ,"M89622" ,"M89629" ,"M89631" ,"M89632" ,"M89639" ,"M89641" ,"M89642" ,"M89649" ,"M89651" ,"M89652" ,"M89659" ,"M89661" ,"M89662" ,"M89669" ,"M89671" ,"M89672" ,"M89679" ,"M8968" ,"M8969" ,"M9050" ,"M90511" ,"M90512" ,"M90519" ,"M90521" ,"M90522" ,"M90529" ,"M90531" ,"M90532" ,"M90539" ,"M90541" ,"M90542" ,"M90549" ,"M90551" ,"M90552" ,"M90559" ,"M90561" ,"M90562" ,"M90569" ,"M90571" ,"M90572" ,"M90579" ,"M9058" ,"M9059"))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_CATEGORY ="CC-39"
endif
 if (nom.source_identifier in ("L4050" ,"L4051" ,"L4052" ,"L4053" ,"L4054" ,"L4059" ,"M0230" ,"M02311" ,"M02312" ,"M02319" ,"M02321" ,"M02322" ,"M02329" ,"M02331" ,"M02332" ,"M02339" ,"M02341" ,"M02342" ,"M02349" ,"M02351" ,"M02352" ,"M02359" ,"M02361" ,"M02362" ,"M02369" ,"M02371" ,"M02372" ,"M02379" ,"M0238" ,"M0239" ,"M041" ,"M042" ,"M048" ,"M049" ,"M0500" ,"M05011" ,"M05012" ,"M05019" ,"M05021" ,"M05022" ,"M05029" ,"M05031" ,"M05032" ,"M05039" ,"M05041" ,"M05042" ,"M05049" ,"M05051" ,"M05052" ,"M05059" ,"M05061" ,"M05062" ,"M05069" ,"M05071" ,"M05072" ,"M05079" ,"M0509" ,"M0510" ,"M05111" ,"M05112" ,"M05119" ,"M05121" ,"M05122" ,"M05129" ,"M05131" ,"M05132" ,"M05139" ,"M05141" ,"M05142" ,"M05149" ,"M05151" ,"M05152" ,"M05159" ,"M05161" ,"M05162" ,"M05169" ,"M05171" ,"M05172" ,"M05179" ,"M0519" ,"M0520" ,"M05211" ,"M05212" ,"M05219" ,"M05221" ,"M05222" ,"M05229" ,"M05231" ,"M05232" ,"M05239" ,"M05241" ,"M05242" ,"M05249" ,"M05251" ,"M05252" ,"M05259" ,"M05261" ,"M05262" ,"M05269"
 ,"M05271" ,"M05272" ,"M05279" ,"M0529" ,"M0530" ,"M05311" ,"M05312" ,"M05319" ,"M05321" ,"M05322" ,"M05329" ,"M05331" ,"M05332" ,"M05339" ,"M05341" ,"M05342" ,"M05349" ,"M05351" ,"M05352" ,"M05359" ,"M05361" ,"M05362" ,"M05369" ,"M05371" ,"M05372" ,"M05379" ,"M0539" ,"M0540" ,"M05411" ,"M05412" ,"M05419" ,"M05421" ,"M05422" ,"M05429" ,"M05431" ,"M05432" ,"M05439" ,"M05441" ,"M05442" ,"M05449" ,"M05451" ,"M05452" ,"M05459" ,"M05461" ,"M05462" ,"M05469" ,"M05471" ,"M05472" ,"M05479" ,"M0549" ,"M0550" ,"M05511" ,"M05512" ,"M05519" ,"M05521" ,"M05522" ,"M05529" ,"M05531" ,"M05532" ,"M05539" ,"M05541" ,"M05542" ,"M05549" ,"M05551" ,"M05552" ,"M05559" ,"M05561" ,"M05562" ,"M05569" ,"M05571" ,"M05572" ,"M05579" ,"M0559" ,"M0560" ,"M05611" ,"M05612" ,"M05619" ,"M05621" ,"M05622" ,"M05629" ,"M05631" ,"M05632" ,"M05639" ,"M05641" ,"M05642" ,"M05649" ,"M05651" ,"M05652" ,"M05659" ,"M05661" ,"M05662" ,"M05669" ,"M05671" ,"M05672" ,"M05679" ,"M0569" ,"M0570" ,"M05711" ,"M05712" ,"M05719" ,"M05721"
 ,"M05722" ,"M05729" ,"M05731" ,"M05732" ,"M05739" ,"M05741" ,"M05742" ,"M05749" ,"M05751" ,"M05752" ,"M05759" ,"M05761" ,"M05762" ,"M05769" ,"M05771" ,"M05772" ,"M05779" ,"M0579" ,"M0580" ,"M05811" ,"M05812" ,"M05819" ,"M05821" ,"M05822" ,"M05829" ,"M05831" ,"M05832" ,"M05839" ,"M05841" ,"M05842" ,"M05849" ,"M05851" ,"M05852" ,"M05859" ,"M05861" ,"M05862" ,"M05869" ,"M05871" ,"M05872" ,"M05879" ,"M0589" ,"M059" ,"M0600" ,"M06011" ,"M06012" ,"M06019" ,"M06021" ,"M06022" ,"M06029" ,"M06031" ,"M06032" ,"M06039" ,"M06041" ,"M06042" ,"M06049" ,"M06051" ,"M06052" ,"M06059" ,"M06061" ,"M06062" ,"M06069" ,"M06071" ,"M06072" ,"M06079" ,"M0608" ,"M0609" ,"M061" ,"M0620" ,"M06211" ,"M06212" ,"M06219" ,"M06221" ,"M06222" ,"M06229" ,"M06231" ,"M06232" ,"M06239" ,"M06241" ,"M06242" ,"M06249" ,"M06251" ,"M06252" ,"M06259" ,"M06261" ,"M06262" ,"M06269" ,"M06271" ,"M06272" ,"M06279" ,"M0628" ,"M0629" ,"M0630" ,"M06311" ,"M06312" ,"M06319" ,"M06321" ,"M06322" ,"M06329" ,"M06331" ,"M06332" ,"M06339"
 ,"M06341" ,"M06342" ,"M06349" ,"M06351" ,"M06352" ,"M06359" ,"M06361" ,"M06362" ,"M06369" ,"M06371" ,"M06372" ,"M06379" ,"M0638" ,"M0639" ,"M064" ,"M0680" ,"M06811" ,"M06812" ,"M06819" ,"M06821" ,"M06822" ,"M06829" ,"M06831" ,"M06832" ,"M06839" ,"M06841" ,"M06842" ,"M06849" ,"M06851" ,"M06852" ,"M06859" ,"M06861" ,"M06862" ,"M06869" ,"M06871" ,"M06872" ,"M06879" ,"M0688" ,"M0689" ,"M069" ,"M0800" ,"M08011" ,"M08012" ,"M08019" ,"M08021" ,"M08022" ,"M08029" ,"M08031" ,"M08032" ,"M08039" ,"M08041" ,"M08042" ,"M08049" ,"M08051" ,"M08052" ,"M08059" ,"M08061" ,"M08062" ,"M08069" ,"M08071" ,"M08072" ,"M08079" ,"M0808" ,"M0809" ,"M081" ,"M0820" ,"M08211" ,"M08212" ,"M08219" ,"M08221" ,"M08222" ,"M08229" ,"M08231" ,"M08232" ,"M08239" ,"M08241" ,"M08242" ,"M08249" ,"M08251" ,"M08252" ,"M08259" ,"M08261" ,"M08262" ,"M08269" ,"M08271" ,"M08272" ,"M08279" ,"M0828" ,"M0829" ,"M083" ,"M0840" ,"M08411" ,"M08412" ,"M08419" ,"M08421" ,"M08422" ,"M08429" ,"M08431" ,"M08432" ,"M08439" ,"M08441" ,"M08442"
 ,"M08449" ,"M08451" ,"M08452" ,"M08459" ,"M08461" ,"M08462" ,"M08469" ,"M08471" ,"M08472" ,"M08479" ,"M0848" ,"M0880" ,"M08811" ,"M08812" ,"M08819" ,"M08821" ,"M08822" ,"M08829" ,"M08831" ,"M08832" ,"M08839" ,"M08841" ,"M08842" ,"M08849" ,"M08851" ,"M08852" ,"M08859" ,"M08861" ,"M08862" ,"M08869" ,"M08871" ,"M08872" ,"M08879" ,"M0888" ,"M0889" ,"M0890" ,"M08911" ,"M08912" ,"M08919" ,"M08921" ,"M08922" ,"M08929" ,"M08931" ,"M08932" ,"M08939" ,"M08941" ,"M08942" ,"M08949" ,"M08951" ,"M08952" ,"M08959" ,"M08961" ,"M08962" ,"M08969" ,"M08971" ,"M08972" ,"M08979" ,"M0898" ,"M0899" ,"M1200" ,"M12011" ,"M12012" ,"M12019" ,"M12021" ,"M12022" ,"M12029" ,"M12031" ,"M12032" ,"M12039" ,"M12041" ,"M12042" ,"M12049" ,"M12051" ,"M12052" ,"M12059" ,"M12061" ,"M12062" ,"M12069" ,"M12071" ,"M12072" ,"M12079" ,"M1208" ,"M1209" ,"M300" ,"M301" ,"M302" ,"M303" ,"M308" ,"M310" ,"M311" ,"M312" ,"M3130" ,"M3131" ,"M314" ,"M315" ,"M316" ,"M317" ,"M320" ,"M3210" ,"M3211" ,"M3212" ,"M3213" ,"M3214" ,"M3215"
  ,"M3219" ,
"M328" ,"M329" ,"M3300" ,"M3301" ,"M3302" ,"M3303" ,"M3309" ,"M3310" ,"M3311" ,"M3312" ,"M3313" ,"M3319" ,"M3320" ,"M3321" ,"M3322" ,"M3329" ,"M3390" ,"M3391" ,"M3392" ,"M3393" ,"M3399" ,"M340" ,"M341" ,"M342" ,"M3481" ,"M3482" ,"M3483" ,"M3489" ,"M349" ,"M3500" ,"M3501" ,"M3502" ,"M3503" ,"M3504" ,"M3509" ,"M351" ,"M352" ,"M353" ,"M355" ,"M358" ,"M359" ,"M360" ,"M368" ,"M450" ,"M451" ,"M452" ,"M453" ,"M454" ,"M455" ,"M456" ,"M457" ,"M458" ,"M459" ,"M4600" ,"M4601" ,"M4602" ,"M4603" ,"M4604" ,"M4605" ,"M4606" ,"M4607" ,"M4608" ,"M4609" ,"M461" ,"M4650" ,"M4651" ,"M4652" ,"M4653" ,"M4654" ,"M4655" ,"M4656" ,"M4657" ,"M4658" ,"M4659" ,"M4680" ,"M4681" ,"M4682" ,"M4683" ,"M4684" ,"M4685" ,"M4686" ,"M4687" ,"M4688" ,"M4689" ,"M4690" ,"M4691" ,"M4692" ,"M4693" ,"M4694" ,"M4695" ,"M4696" ,"M4697" ,"M4698" ,"M4699" ,"M488X1" ,"M488X2" ,"M488X3" ,"M488X4" ,"M488X5" ,"M488X6" ,"M488X7" ,"M488X8" ,"M488X9" ,"M4980" ,"M4981" ,"M4982" ,"M4983" ,"M4984" ,"M4985" ,"M4986" ,"M4987" ,"M4988" ,"M4989")
)
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_CATEGORY ="CC-40"
 ENDIF
 if (nom.source_identifier in ("D460" ,"D461" ,"D4620" ,"D4621" ,"D4622" ,"D464" ,"D469" ,"D46A" ,"D46B" ,"D46C" ,"D46Z" ,"D474" ,"D5700" ,"D5701" ,"D5702" ,"D571" ,"D5720" ,"D57211" ,"D57212" ,"D57219" ,"D5740" ,"D57411" ,"D57412" ,"D57419" ,"D5780" ,"D57811" ,"D57812" ,"D57819" ,"D590" ,"D591" ,"D592" ,"D593" ,"D594" ,"D595" ,"D596" ,"D598" ,"D599" ,"D600" ,"D601" ,"D608" ,"D609" ,"D6101" ,"D6109" ,"D611" ,"D612" ,"D613" ,"D6182" ,"D6189" ,"D619" ,"D66" ,"D67" ,"D7581"))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_CATEGORY ="CC-46"
endif
if (nom.source_identifier in ("D61810" ,"D61811" ,"D61818" ,"D700" ,"D701" ,"D702" ,"D703" ,"D704" ,"D708" ,"D709" ,"D71" ,"D720" ,"D761" ,"D762" ,"D763" ,"D800" ,"D801" ,"D802" ,"D803" ,"D804" ,"D805" ,"D806" ,"D807" ,"D808" ,"D809" ,"D810" ,"D811" ,"D812" ,"D813" ,"D814" ,"D815" ,"D816" ,"D817" ,"D8189" ,"D819" ,"D820" ,"D821" ,"D822" ,"D823" ,"D824" ,"D828" ,"D829" ,"D830" ,"D831" ,"D832" ,"D838" ,"D839" ,"D840" ,"D848" ,"D849" ,"D893" ,"D8940" ,"D8941" ,"D8942" ,"D8943" ,"D8949" ,"D89810" ,"D89811" ,"D89812" ,"D89813" ,"D8982" ,"D8989" ,"D899"))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_CATEGORY ="CC-47"
endif
 if (nom.source_identifier in ("C946" ,"D45" ,"D471" ,"D473" ,"D479" ,"D47Z1" ,"D47Z2" ,"D47Z9" ,"D550" ,"D551" ,"D552" ,"D553" ,"D558" ,"D559" ,"D560" ,"D561" ,"D562" ,"D564" ,"D565" ,"D568" ,"D573" ,"D580" ,"D581" ,"D582" ,"D588" ,"D589" ,"D640" ,"D641" ,"D642" ,"D643" ,"D65" ,"D680" ,"D681" ,"D682" ,"D68311" ,"D68312" ,"D68318" ,"D6832" ,"D684" ,"D6851" ,"D6852" ,"D6859" ,"D6861" ,"D6862" ,"D6869" ,"D688" ,"D689" ,"D690" ,"D691" ,"D692" ,"D693" ,"D6941" ,"D6942" ,"D6949" ,"D696" ,"D698" ,"D699" ,"D7582"))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_CATEGORY ="CC-48"
 ENDIF
 if (nom.source_identifier in ("F0151" ,"F0281" ,"F0391" ,"G910" ,"G911" ,"G912" ,"G913" ,"G914" ,"G918" ,"G919"))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_CATEGORY ="CC-51"
endif
 if (nom.source_identifier in ("A8100" ,"A8101" ,"A8109" ,"A811" ,"A812" ,"A8181" ,"A8182" ,"A8183" ,"A8189" ,"A819" ,"E7500" ,"E7501" ,"E7502" ,"E7509" ,"E7510" ,"E7511" ,"E7519" ,"E7523" ,"E7525" ,"E7526" ,"E7529" ,"E754" ,"F0150" ,"F0280" ,"F0390" ,"F04" ,"G132" ,"G138" ,"G300" ,"G301" ,"G308" ,"G309" ,"G3101" ,"G3109" ,"G311" ,"G312" ,"G3181" ,"G3182" ,"G3183" ,"G3185" ,"G3189" ,"G319" ,"G937" ,"I673"))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_CATEGORY ="CC-52"
 ENDIF
 if (nom.source_identifier in ("F10150" ,"F10151" ,"F10159" ,"F10231" ,"F10232" ,"F10250" ,"F10251" ,"F10259" ,"F1026" ,"F1027" ,"F10950" ,"F10951" ,"F10959" ,"F1096" ,"F1097" ,"F11150" ,"F11151" ,"F11159" ,"F11250" ,"F11251" ,"F11259" ,"F11950" ,"F11951" ,"F11959" ,"F12150" ,"F12151" ,"F12159" ,"F12250" ,"F12251" ,"F12259" ,"F12950" ,"F12951" ,"F12959" ,"F13150" ,"F13151" ,"F13159" ,"F13231" ,"F13232" ,"F13250" ,"F13251" ,"F13259" ,"F1326" ,"F1327" ,"F13931" ,"F13932" ,"F13950" ,"F13951" ,"F13959" ,"F1396" ,"F1397" ,"F14150" ,"F14151" ,"F14159" ,"F14250" ,"F14251" ,"F14259" ,"F14950" ,"F14951" ,"F14959" ,"F15150" ,"F15151" ,"F15159" ,"F15250" ,"F15251" ,"F15259" ,"F15950" ,"F15951" ,"F15959" ,"F16150" ,"F16151" ,"F16159" ,"F16250" ,"F16251" ,"F16259" ,"F16950" ,"F16951" ,"F16959" ,"F18150" ,"F18151" ,"F18159" ,"F1817" ,"F18250" ,"F18251" ,"F18259" ,"F1827" ,"F18950" ,"F18951" ,"F18959" ,"F1897" ,"F19150" ,"F19151" ,"F19159" ,"F1916" ,"F1917" ,"F19231" ,"F19232" ,"F19250" ,"F19251"
  ,"F19259" ,"F1926" ,"F1927" ,"F19931" ,"F19932" ,"F19950" ,"F19951" ,"F19959" ,"F1996" ,"F1997"))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_CATEGORY ="CC-54"
endif
 if (nom.source_identifier in ("F10120" ,"F10121" ,"F10129" ,"F1014" ,"F10180" ,"F10181" ,"F10182" ,"F10188" ,"F1019" ,"F1020" ,"F1021" ,"F10220" ,"F10221" ,"F10229" ,"F10230" ,"F10239" ,"F1024" ,"F10280" ,"F10281" ,"F10282" ,"F10288" ,"F1029" ,"F10920" ,"F10921" ,"F10929" ,"F1094" ,"F10980" ,"F10981" ,"F10982" ,"F10988" ,"F1099" ,"F11120" ,"F11121" ,"F11122" ,"F11129" ,"F1114" ,"F11181" ,"F11182" ,"F11188" ,"F1119" ,"F1120" ,"F1121" ,"F11220" ,"F11221" ,"F11222" ,"F11229" ,"F1123" ,"F1124" ,"F11281" ,"F11282" ,"F11288" ,"F1129" ,"F11920" ,"F11921" ,"F11922" ,"F11929" ,"F1193" ,"F1194" ,"F11981" ,"F11982" ,"F11988" ,"F1199" ,"F12120" ,"F12121" ,"F12122" ,"F12129" ,"F12180" ,"F12188" ,"F1219" ,"F1220" ,"F1221" ,"F12220" ,"F12221" ,"F12222" ,"F12229" ,"F1223" ,"F12280" ,"F12288" ,"F1229" ,"F12920" ,"F12921" ,"F12922" ,"F12929" ,"F1293" ,"F12980" ,"F12988" ,"F1299" ,"F13120" ,"F13121" ,"F13129" ,"F1314" ,"F13180" ,"F13181" ,"F13182" ,"F13188" ,"F1319" ,"F1320" ,"F1321" ,"F13220" ,"F13221"
 ,"F13229" ,"F13230" ,"F13239" ,"F1324" ,"F13280" ,"F13281" ,"F13282" ,"F13288" ,"F1329" ,"F13920" ,"F13921" ,"F13929" ,"F13930" ,"F13939" ,"F1394" ,"F13980" ,"F13981" ,"F13982" ,"F13988" ,"F1399" ,"F14120" ,"F14121" ,"F14122" ,"F14129" ,"F1414" ,"F14180" ,"F14181" ,"F14182" ,"F14188" ,"F1419" ,"F1420" ,"F1421" ,"F14220" ,"F14221" ,"F14222" ,"F14229" ,"F1423" ,"F1424" ,"F14280" ,"F14281" ,"F14282" ,"F14288" ,"F1429" ,"F14920" ,"F14921" ,"F14922" ,"F14929" ,"F1494" ,"F14980" ,"F14981" ,"F14982" ,"F14988" ,"F1499" ,"F15120" ,"F15121" ,"F15122" ,"F15129" ,"F1514" ,"F15180" ,"F15181" ,"F15182" ,"F15188" ,"F1519" ,"F1520" ,"F1521" ,"F15220" ,"F15221" ,"F15222" ,"F15229" ,"F1523" ,"F1524" ,"F15280" ,"F15281" ,"F15282" ,"F15288" ,"F1529" ,"F15920" ,"F15921" ,"F15922" ,"F15929" ,"F1593" ,"F1594" ,"F15980" ,"F15981" ,"F15982" ,"F15988" ,"F1599" ,"F16120" ,"F16121" ,"F16122" ,"F16129" ,"F1614" ,"F16180" ,"F16183" ,"F16188" ,"F1619" ,"F1620" ,"F1621" ,"F16220" ,"F16221" ,"F16229" ,"F1624"
 ,"F16280" ,"F16283" ,"F16288" ,"F1629" ,"F16920" ,"F16921" ,"F16929" ,"F1694" ,"F16980" ,"F16983" ,"F16988" ,"F1699" ,"F18120" ,"F18121" ,"F18129" ,"F1814" ,"F18180" ,"F18188" ,"F1819" ,"F1820" ,"F1821" ,"F18220" ,"F18221" ,"F18229" ,"F1824" ,"F18280" ,"F18288" ,"F1829" ,"F18920" ,"F18921" ,"F18929" ,"F1894" ,"F18980" ,"F18988" ,"F1899" ,"F19120" ,"F19121" ,"F19122" ,"F19129" ,"F1914" ,"F19180" ,"F19181" ,"F19182" ,"F19188" ,"F1919" ,"F1920" ,"F1921" ,"F19220" ,"F19221" ,"F19222" ,"F19229" ,"F19230" ,"F19239" ,"F1924" ,"F19280" ,"F19281" ,"F19282" ,"F19288" ,"F1929" ,"F19920" ,"F19921" ,"F19922" ,"F19929" ,"F19930" ,"F19939" ,"F1994" ,"F19980" ,"F19981" ,"F19982" ,"F19988" ,"F1999" ,"T400X1A" ,"T400X4A" ,"T401X1A" ,"T401X4A" ,"T402X1A" ,"T402X4A" ,"T403X1A" ,"T403X4A" ,"T404X1A" ,"T404X4A" ,"T405X1A" ,"T405X4A" ,"T40601A" ,"T40604A" ,"T40691A" ,"T40694A" ,"T408X1A" ,"T408X4A" ,"T40901A" ,"T40904A" ,"T40991A" ,"T40994A" ,"T43601A" ,"T43604A" ,"T43611A" ,"T43614A" ,"T43621A" ,"T43624A"
,"T43631A" ,"T43634A" ,"T43641A" ,"T43644A" ,"T43691A" ,"T43694A" ,"T510X1A" ,"T510X4A"))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_CATEGORY ="CC-55"
endif
 if (nom.source_identifier in ("F200" ,"F201" ,"F202" ,"F203" ,"F205" ,"F2081" ,"F2089" ,"F209" ,"F250" ,"F251" ,"F258" ,"F259"))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_CATEGORY ="CC-57"
 ENDIF
 if (nom.source_identifier in ("F22" ,"F23" ,"F24" ,"F28" ,"F29" ,"F3010" ,"F3011" ,"F3012" ,"F3013" ,"F302" ,"F303" ,"F304" ,"F308" ,"F309" ,"F310" ,"F3110" ,"F3111" ,"F3112" ,"F3113" ,"F312" ,"F3130" ,"F3131" ,"F3132" ,"F314" ,"F315" ,"F3160" ,"F3161" ,"F3162" ,"F3163" ,"F3164" ,"F3170" ,"F3171" ,"F3172" ,"F3173" ,"F3174" ,"F3175" ,"F3176" ,"F3177" ,"F3178" ,"F3181" ,"F3189" ,"F319" ,"F320" ,"F321" ,"F322" ,"F323" ,"F324" ,"F325" ,"F330" ,"F331" ,"F332" ,"F333" ,"F3340" ,"F3341" ,"F3342" ,"F338" ,"F339" ,"F348" ,"F3481" ,"F3489" ,"F349" ,"F39" ,"F531" ,"T1491" ,"T360X2A" ,"T360X2S" ,"T361X2A" ,"T361X2S" ,"T362X2A" ,"T362X2S" ,"T363X2A" ,"T363X2S" ,"T364X2A" ,"T364X2S" ,"T365X2A" ,"T365X2S" ,"T366X2A" ,"T366X2S" ,"T367X2A" ,"T367X2S" ,"T368X2A" ,"T368X2S" ,"T3692XA" ,"T3692XS" ,"T370X2A" ,"T370X2S" ,"T371X2A" ,"T371X2S" ,"T372X2A" ,"T372X2S" ,"T373X2A" ,"T373X2S" ,"T374X2A" ,"T374X2S" ,"T375X2A" ,"T375X2S" ,"T378X2A" ,"T378X2S" ,"T3792XA" ,"T3792XS" ,"T380X2A" ,"T380X2S" ,"T381X2A"
 ,"T381X2S" ,"T382X2A" ,"T382X2S" ,"T383X2A" ,"T383X2S" ,"T384X2A" ,"T384X2S" ,"T385X2A" ,"T385X2S" ,"T386X2A" ,"T386X2S" ,"T387X2A" ,"T387X2S" ,"T38802A" ,"T38802S" ,"T38812A" ,"T38812S" ,"T38892A" ,"T38892S" ,"T38902A" ,"T38902S" ,"T38992A" ,"T38992S" ,"T39012A" ,"T39012S" ,"T39092A" ,"T39092S" ,"T391X2A" ,"T391X2S" ,"T392X2A" ,"T392X2S" ,"T39312A" ,"T39312S" ,"T39392A" ,"T39392S" ,"T394X2A" ,"T394X2S" ,"T398X2A" ,"T398X2S" ,"T3992XA" ,"T3992XS" ,"T400X2A" ,"T400X2S" ,"T401X2A" ,"T401X2S" ,"T402X2A" ,"T402X2S" ,"T403X2A" ,"T403X2S" ,"T404X2A" ,"T404X2S" ,"T405X2A" ,"T405X2S" ,"T40602A" ,"T40602S" ,"T40692A" ,"T40692S" ,"T407X2A" ,"T407X2S" ,"T408X2A" ,"T408X2S" ,"T40902A" ,"T40902S" ,"T40992A" ,"T40992S" ,"T410X2A" ,"T410X2S" ,"T411X2A" ,"T411X2S" ,"T41202A" ,"T41202S" ,"T41292A" ,"T41292S" ,"T413X2A" ,"T413X2S" ,"T4142XA" ,"T4142XS" ,"T415X2A" ,"T415X2S" ,"T420X2A" ,"T420X2S" ,"T421X2A" ,"T421X2S" ,"T422X2A" ,"T422X2S" ,"T423X2A" ,"T423X2S" ,"T424X2A" ,"T424X2S" ,"T425X2A"
  ,"T425X2S" ,
"T426X2A" ,"T426X2S" ,"T4272XA" ,"T4272XS" ,"T428X2A" ,"T428X2S" ,"T43012A" ,"T43012S" ,"T43022A" ,"T43022S" ,"T431X2A" ,"T431X2S" ,"T43202A" ,"T43202S" ,"T43212A" ,"T43212S" ,"T43222A" ,"T43222S" ,"T43292A" ,"T43292S" ,"T433X2A" ,"T433X2S" ,"T434X2A" ,"T434X2S" ,"T43502A" ,"T43502S" ,"T43592A" ,"T43592S" ,"T43602A" ,"T43602S" ,"T43612A" ,"T43612S" ,"T43622A" ,"T43622S" ,"T43632A" ,"T43632S" ,"T43692A" ,"T43692S" ,"T438X2A" ,"T438X2S" ,"T4392XA" ,"T4392XS" ,"T440X2A" ,"T440X2S" ,"T441X2A" ,"T441X2S" ,"T442X2A" ,"T442X2S" ,"T443X2A" ,"T443X2S" ,"T444X2A" ,"T444X2S" ,"T445X2A" ,"T445X2S" ,"T446X2A" ,"T446X2S" ,"T447X2A" ,"T447X2S" ,"T448X2A" ,"T448X2S" ,"T44902A" ,"T44902S" ,"T44992A" ,"T44992S" ,"T450X2A" ,"T450X2S" ,"T451X2A" ,"T451X2S" ,"T452X2A" ,"T452X2S" ,"T453X2A" ,"T453X2S" ,"T454X2A" ,"T454X2S" ,"T45512A" ,"T45512S" ,"T45522A" ,"T45522S" ,"T45602A" ,"T45602S" ,"T45612A" ,"T45612S" ,"T45622A" ,"T45622S" ,"T45692A" ,"T45692S" ,"T457X2A" ,"T457X2S" ,"T458X2A" ,"T458X2S" ,"T4592XA"
,"T4592XS" ,"T460X2A" ,"T460X2S" ,"T461X2A" ,"T461X2S" ,"T462X2A" ,"T462X2S" ,"T463X2A" ,"T463X2S" ,"T464X2A" ,"T464X2S" ,"T465X2A" ,"T465X2S" ,"T466X2A" ,"T466X2S" ,"T467X2A" ,"T467X2S" ,"T468X2A" ,"T468X2S" ,"T46902A" ,"T46902S" ,"T46992A" ,"T46992S" ,"T470X2A" ,"T470X2S" ,"T471X2A" ,"T471X2S" ,"T472X2A" ,"T472X2S" ,"T473X2A" ,"T473X2S" ,"T474X2A" ,"T474X2S" ,"T475X2A" ,"T475X2S" ,"T476X2A" ,"T476X2S" ,"T477X2A" ,"T477X2S" ,"T478X2A" ,"T478X2S" ,"T4792XA" ,"T4792XS" ,"T480X2A" ,"T480X2S" ,"T481X2A" ,"T481X2S" ,"T48202A" ,"T48202S" ,"T48292A" ,"T48292S" ,"T483X2A" ,"T483X2S" ,"T484X2A" ,"T484X2S" ,"T485X2A" ,"T485X2S" ,"T486X2A" ,"T486X2S" ,"T48902A" ,"T48902S" ,"T48992A" ,"T48992S" ,"T490X2A" ,"T490X2S" ,"T491X2A" ,"T491X2S" ,"T492X2A" ,"T492X2S" ,"T493X2A" ,"T493X2S" ,"T494X2A" ,"T494X2S" ,"T495X2A" ,"T495X2S" ,"T496X2A" ,"T496X2S" ,"T497X2A" ,"T497X2S" ,"T498X2A" ,"T498X2S" ,"T4992XA" ,"T4992XS" ,"T500X2A" ,"T500X2S" ,"T501X2A" ,"T501X2S" ,"T502X2A" ,"T502X2S" ,"T503X2A" ,"T503X2S"
 ,"T504X2A" ,"T504X2S" ,"T505X2A" ,"T505X2S" ,"T506X2A" ,"T506X2S" ,"T507X2A" ,"T507X2S" ,"T508X2A" ,"T508X2S" ,"T50902A" ,"T50902S" ,"T50992A" ,"T50992S" ,"T50A12A" ,"T50A12S" ,"T50A22A" ,"T50A22S" ,"T50A92A" ,"T50A92S" ,"T50B12A" ,"T50B12S" ,"T50B92A" ,"T50B92S" ,"T50Z12A" ,"T50Z12S" ,"T50Z92A" ,"T50Z92S" ,"T510X2A" ,"T510X2S" ,"T511X2A" ,"T511X2S" ,"T512X2A" ,"T512X2S" ,"T513X2A" ,"T513X2S" ,"T518X2A" ,"T518X2S" ,"T5192XA" ,"T5192XS" ,"T520X2A" ,"T520X2S" ,"T521X2A" ,"T521X2S" ,"T522X2A" ,"T522X2S" ,"T523X2A" ,"T523X2S" ,"T524X2A" ,"T524X2S" ,"T528X2A" ,"T528X2S" ,"T5292XA" ,"T5292XS" ,"T530X2A" ,"T530X2S" ,"T531X2A" ,"T531X2S" ,"T532X2A" ,"T532X2S" ,"T533X2A" ,"T533X2S" ,"T534X2A" ,"T534X2S" ,"T535X2A" ,"T535X2S" ,"T536X2A" ,"T536X2S" ,"T537X2A" ,"T537X2S" ,"T5392XA" ,"T5392XS" ,"T540X2A" ,"T540X2S" ,"T541X2A" ,"T541X2S" ,"T542X2A" ,"T542X2S" ,"T543X2A" ,"T543X2S" ,"T5492XA" ,"T5492XS" ,"T550X2A" ,"T550X2S" ,"T551X2A" ,"T551X2S" ,"T560X2A" ,"T560X2S" ,"T561X2A" ,"T561X2S"
  ,"T562X2A" ,"T562X2S" ,"T563X2A" ,"T563X2S" ,"T564X2A" ,"T564X2S" ,"T565X2A" ,"T565X2S" ,"T566X2A" ,"T566X2S" ,"T567X2A" ,"T567X2S" ,"T56812A" ,"T56812S" ,"T56892A" ,"T56892S" ,"T5692XA" ,"T5692XS" ,"T570X2A" ,"T570X2S" ,"T571X2A" ,"T571X2S" ,"T572X2A" ,"T572X2S" ,"T573X2A" ,"T573X2S" ,"T578X2A" ,"T578X2S" ,"T5792XA" ,"T5792XS" ,"T5802XA" ,"T5802XS" ,"T5812XA" ,"T5812XS" ,"T582X2A" ,"T582X2S" ,"T588X2A" ,"T588X2S" ,"T5892XA" ,"T5892XS" ,"T590X2A" ,"T590X2S" ,"T591X2A" ,"T591X2S" ,"T592X2A" ,"T592X2S" ,"T593X2A" ,"T593X2S" ,"T594X2A" ,"T594X2S" ,"T595X2A" ,"T595X2S" ,"T596X2A" ,"T596X2S" ,"T597X2A" ,"T597X2S" ,"T59812A" ,"T59812S" ,"T59892A" ,"T59892S" ,"T5992XA" ,"T5992XS" ,"T600X2A" ,"T600X2S" ,"T601X2A" ,"T601X2S" ,"T602X2A" ,"T602X2S" ,"T603X2A" ,"T603X2S" ,"T604X2A" ,"T604X2S" ,"T608X2A" ,"T608X2S" ,"T6092XA" ,"T6092XS" ,"T6102XA" ,"T6102XS" ,"T6112XA" ,"T6112XS" ,"T61772A" ,"T61772S" ,"T61782A" ,"T61782S" ,"T618X2A" ,"T618X2S" ,"T6192XA" ,"T6192XS" ,"T620X2A" ,"T620X2S"
  ,"T621X2A" ,"T621X2S" ,"T622X2A" ,"T622X2S" ,"T628X2A" ,"T628X2S" ,"T6292XA" ,"T6292XS" ,"T63002A" ,"T63002S" ,"T63012A" ,"T63012S" ,"T63022A" ,"T63022S" ,"T63032A" ,"T63032S" ,"T63042A" ,"T63042S" ,"T63062A" ,"T63062S" ,"T63072A" ,"T63072S" ,"T63082A" ,"T63082S" ,"T63092A" ,"T63092S" ,"T63112A" ,"T63112S" ,"T63122A" ,"T63122S" ,"T63192A" ,"T63192S" ,"T632X2A" ,"T632X2S" ,"T63302A" ,"T63302S" ,"T63312A" ,"T63312S" ,"T63322A" ,"T63322S" ,"T63332A" ,"T63332S" ,"T63392A" ,"T63392S" ,"T63412A" ,"T63412S" ,"T63422A" ,"T63422S" ,"T63432A" ,"T63432S" ,"T63442A" ,"T63442S" ,"T63452A" ,"T63452S" ,"T63462A" ,"T63462S" ,"T63482A" ,"T63482S" ,"T63512A" ,"T63512S" ,"T63592A" ,"T63592S" ,"T63612A" ,"T63612S" ,"T63622A" ,"T63622S" ,"T63632A" ,"T63632S" ,"T63692A" ,"T63692S" ,"T63712A" ,"T63712S" ,"T63792A" ,"T63792S" ,"T63812A" ,"T63812S" ,"T63822A" ,"T63822S" ,"T63832A" ,"T63832S" ,"T63892A" ,"T63892S" ,"T6392XA" ,"T6392XS" ,"T6402XA" ,"T6402XS" ,"T6482XA" ,"T6482XS" ,"T650X2A" ,"T650X2S"
  ,"T651X2A" ,"T651X2S" ,"T65212A" ,"T65212S" ,"T65222A" ,"T65222S" ,"T65292A" ,"T65292S" ,"T653X2A" ,"T653X2S" ,"T654X2A" ,"T654X2S" ,"T655X2A" ,"T655X2S" ,"T656X2A" ,"T656X2S" ,"T65812A" ,"T65812S" ,"T65822A" ,"T65822S" ,"T65832A" ,"T65832S" ,"T65892A" ,"T65892S" ,"T6592XA" ,"T6592XS" ,"T71112A" ,"T71112S" ,"T71122A" ,"T71122S" ,"T71132A" ,"T71132S" ,"T71152A" ,"T71152S" ,"T71162A" ,"T71162S" ,"T71192A" ,"T71192S" ,"T71222A" ,"T71222S" ,"T71232A" ,"T71232S" ,"X710XXA" ,"X710XXD" ,"X710XXS" ,"X711XXA" ,"X711XXD" ,"X711XXS" ,"X712XXA" ,"X712XXD" ,"X712XXS" ,"X713XXA" ,"X713XXD" ,"X713XXS" ,"X718XXA" ,"X718XXD" ,"X718XXS" ,"X719XXA" ,"X719XXD" ,"X719XXS" ,"X72XXXA" ,"X72XXXD" ,"X72XXXS" ,"X730XXA" ,"X730XXD" ,"X730XXS" ,"X731XXA" ,"X731XXD" ,"X731XXS" ,"X732XXA" ,"X732XXD" ,"X732XXS" ,"X738XXA" ,"X738XXD" ,"X738XXS" ,"X739XXA" ,"X739XXD" ,"X739XXS" ,"X7401XA" ,"X7401XD" ,"X7401XS" ,"X7402XA" ,"X7402XD" ,"X7402XS" ,"X7409XA" ,"X7409XD" ,"X7409XS" ,"X748XXA" ,"X748XXD" ,"X748XXS"
  ,"X749XXA" ,"X749XXD" ,"X749XXS" ,"X75XXXA" ,"X75XXXD" ,"X75XXXS" ,"X76XXXA" ,"X76XXXD" ,"X76XXXS" ,"X770XXA" ,"X770XXD" ,"X770XXS" ,"X771XXA" ,"X771XXD" ,"X771XXS" ,"X772XXA" ,"X772XXD" ,"X772XXS" ,"X773XXA" ,"X773XXD" ,"X773XXS" ,"X778XXA" ,"X778XXD" ,"X778XXS" ,"X779XXA" ,"X779XXD" ,"X779XXS" ,"X780XXA" ,"X780XXD" ,"X780XXS" ,"X781XXA" ,"X781XXD" ,"X781XXS" ,"X782XXA" ,"X782XXD" ,"X782XXS" ,"X788XXA" ,"X788XXD" ,"X788XXS" ,"X789XXA" ,"X789XXD" ,"X789XXS" ,"X79XXXA" ,"X79XXXD" ,"X79XXXS" ,"X80XXXA" ,"X80XXXD" ,"X80XXXS" ,"X810XXA" ,"X810XXD" ,"X810XXS" ,"X811XXA" ,"X811XXD" ,"X811XXS" ,"X818XXA" ,"X818XXD" ,"X818XXS" ,"X820XXA" ,"X820XXD" ,"X820XXS" ,"X821XXA" ,"X821XXD" ,"X821XXS" ,"X822XXA" ,"X822XXD" ,"X822XXS" ,"X828XXA" ,"X828XXD" ,"X828XXS" ,"X830XXA" ,"X830XXD" ,"X830XXS" ,"X831XXA" ,"X831XXD" ,"X831XXS" ,"X832XXA" ,"X832XXD" ,"X832XXS" ,"X838XXA" ,"X838XXD" ,"X838XXS"))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_CATEGORY ="CC-58"
endif
 if (nom.source_identifier in ("A072" ,"A310" ,"A312" ,"B250" ,"B251" ,"B252" ,"B258" ,"B259" ,"B371" ,"B377" ,"B3781" ,"B440" ,"B441" ,"B442" ,"B447" ,"B4489" ,"B449" ,"B450" ,"B451" ,"B452" ,"B453" ,"B457" ,"B458" ,"B459" ,"B460" ,"B461" ,"B462" ,"B463" ,"B464" ,"B465" ,"B468" ,"B469" ,"B484" ,"B488" ,"B582" ,"B583" ,"B59"))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_CATEGORY ="CC-6"
 ENDIF
 if (nom.source_identifier in ("G8250" ,"G8251" ,"G8252" ,"G8253" ,"G8254" ,"R532" ,"S14111A" ,"S14111D" ,"S14111S" ,"S14112A" ,"S14112D" ,"S14112S" ,"S14113A" ,"S14113D" ,"S14113S" ,"S14114A" ,"S14114D" ,"S14114S" ,"S14115A" ,"S14115D" ,"S14115S" ,"S14116A" ,"S14116D" ,"S14116S" ,"S14117A" ,"S14117D" ,"S14117S" ,"S14118A" ,"S14118D" ,"S14118S" ,"S14119A" ,"S14119D" ,"S14119S"))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_CATEGORY ="CC-70"
endif
if (nom.source_identifier in ("G8220" ,"G8221" ,"G8222" ,"S24111A" ,"S24111D" ,"S24111S" ,"S24112A" ,"S24112D" ,"S24112S" ,"S24113A" ,"S24113D" ,"S24113S" ,"S24114A" ,"S24114D" ,"S24114S" ,"S24119A" ,"S24119D" ,"S24119S"))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_CATEGORY ="CC-71"
endif
 if (nom.source_identifier in ("B0082" ,"B0112" ,"B0224" ,"G041" ,"G0489" ,"G0491" ,"G054" ,"G110" ,"G111" ,"G112" ,"G113" ,"G114" ,"G118" ,"G119" ,"G120" ,"G121" ,"G128" ,"G129" ,"G320" ,"G3281" ,"G373" ,"G374" ,"G834" ,"G901" ,"G950" ,"G9511" ,"G9519" ,"G9520" ,"G9529" ,"G9581" ,"G9589" ,"G959" ,"G992" ,"Q000" ,"Q001" ,"Q002" ,"Q010" ,"Q011" ,"Q012" ,"Q018" ,"Q019" ,"Q02" ,"Q030" ,"Q031" ,"Q038" ,"Q039" ,"Q040" ,"Q041" ,"Q042" ,"Q043" ,"Q044" ,"Q045" ,"Q046" ,"Q048" ,"Q049" ,"Q050" ,"Q051" ,"Q052" ,"Q053" ,"Q054" ,"Q055" ,"Q056" ,"Q057" ,"Q058" ,"Q059" ,"Q060" ,"Q061" ,"Q062" ,"Q063" ,"Q064" ,"Q068" ,"Q069" ,"Q0700" ,"Q0701" ,"Q0702" ,"Q0703" ,"Q078" ,"Q079" ,"S140XXA" ,"S140XXD" ,"S140XXS" ,"S14101A" ,"S14101D" ,"S14101S" ,"S14102A" ,"S14102D" ,"S14102S" ,"S14103A" ,"S14103D" ,"S14103S" ,"S14104A" ,"S14104D" ,"S14104S" ,"S14105A" ,"S14105D" ,"S14105S" ,"S14106A" ,"S14106D" ,"S14106S" ,"S14107A" ,"S14107D" ,"S14107S" ,"S14108A" ,"S14108D" ,"S14108S" ,"S14109A" ,"S14109D" ,"S14109S" ,
"S14121A" ,"S14121D" ,"S14121S" ,"S14122A" ,"S14122D" ,"S14122S" ,"S14123A" ,"S14123D" ,"S14123S" ,"S14124A" ,"S14124D" ,"S14124S" ,"S14125A" ,"S14125D" ,"S14125S" ,"S14126A" ,"S14126D" ,"S14126S" ,"S14127A" ,"S14127D" ,"S14127S" ,"S14128A" ,"S14128D" ,"S14128S" ,"S14129A" ,"S14129D" ,"S14129S" ,"S14131A" ,"S14131D" ,"S14131S" ,"S14132A" ,"S14132D" ,"S14132S" ,"S14133A" ,"S14133D" ,"S14133S" ,"S14134A" ,"S14134D" ,"S14134S" ,"S14135A" ,"S14135D" ,"S14135S" ,"S14136A" ,"S14136D" ,"S14136S" ,"S14137A" ,"S14137D" ,"S14137S" ,"S14138A" ,"S14138D" ,"S14138S" ,"S14139A" ,"S14139D" ,"S14139S" ,"S14141A" ,"S14141D" ,"S14141S" ,"S14142A" ,"S14142D" ,"S14142S" ,"S14143A" ,"S14143D" ,"S14143S" ,"S14144A" ,"S14144D" ,"S14144S" ,"S14145A" ,"S14145D" ,"S14145S" ,"S14146A" ,"S14146D" ,"S14146S" ,"S14147A" ,"S14147D" ,"S14147S" ,"S14148A" ,"S14148D" ,"S14148S" ,"S14149A" ,"S14149D" ,"S14149S" ,"S14151A" ,"S14151D" ,"S14151S" ,"S14152A" ,"S14152D" ,"S14152S" ,"S14153A" ,"S14153D" ,"S14153S" ,"S14154A"
,"S14154D" ,"S14154S" ,"S14155A" ,"S14155D" ,"S14155S" ,"S14156A" ,"S14156D" ,"S14156S" ,"S14157A" ,"S14157D" ,"S14157S" ,"S14158A" ,"S14158D" ,"S14158S" ,"S14159A" ,"S14159D" ,"S14159S" ,"S240XXA" ,"S240XXD" ,"S240XXS" ,"S24101A" ,"S24101D" ,"S24101S" ,"S24102A" ,"S24102D" ,"S24102S" ,"S24103A" ,"S24103D" ,"S24103S" ,"S24104A" ,"S24104D" ,"S24104S" ,"S24109A" ,"S24109D" ,"S24109S" ,"S24131A" ,"S24131D" ,"S24131S" ,"S24132A" ,"S24132D" ,"S24132S" ,"S24133A" ,"S24133D" ,"S24133S" ,"S24134A" ,"S24134D" ,"S24134S" ,"S24139A" ,"S24139D" ,"S24139S" ,"S24141A" ,"S24141D" ,"S24141S" ,"S24142A" ,"S24142D" ,"S24142S" ,"S24143A" ,"S24143D" ,"S24143S" ,"S24144A" ,"S24144D" ,"S24144S" ,"S24149A" ,"S24149D" ,"S24149S" ,"S24151A" ,"S24151D" ,"S24151S" ,"S24152A" ,"S24152D" ,"S24152S" ,"S24153A" ,"S24153D" ,"S24153S" ,"S24154A" ,"S24154D" ,"S24154S" ,"S24159A" ,"S24159D" ,"S24159S" ,"S3401XA" ,"S3401XD" ,"S3401XS" ,"S3402XA" ,"S3402XD" ,"S3402XS" ,"S34101A" ,"S34101D" ,"S34101S" ,"S34102A" ,"S34102D"
 ,"S34102S" ,"S34103A" ,"S34103D" ,"S34103S" ,"S34104A" ,"S34104D" ,"S34104S" ,"S34105A" ,"S34105D" ,"S34105S" ,"S34109A" ,"S34109D" ,"S34109S" ,"S34111A" ,"S34111D" ,"S34111S" ,"S34112A" ,"S34112D" ,"S34112S" ,"S34113A" ,"S34113D" ,"S34113S" ,"S34114A" ,"S34114D" ,"S34114S" ,"S34115A" ,"S34115D" ,"S34115S" ,"S34119A" ,"S34119D" ,"S34119S" ,"S34121A" ,"S34121D" ,"S34121S" ,"S34122A" ,"S34122D" ,"S34122S" ,"S34123A" ,"S34123D" ,"S34123S" ,"S34124A" ,"S34124D" ,"S34124S" ,"S34125A" ,"S34125D" ,"S34125S" ,"S34129A" ,"S34129D" ,"S34129S" ,"S34131A" ,"S34131D" ,"S34131S" ,"S34132A" ,"S34132D" ,"S34132S" ,"S34139A" ,"S34139D" ,"S34139S" ,"S343XXA"))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_CATEGORY ="CC-72"
 ENDIF
 if (nom.source_identifier in (
 "G1220"
,"G1221"
,"G1222"
,"G1223"
,"G1224"
,"G1225"
,"G1229"
))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_CATEGORY ="CC-73"
endif
 if (nom.source_identifier in (
"G800"
,"G801"
,"G802"
,"G803"
,"G804"
,"G808"
,"G809"
))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_CATEGORY ="CC-74"
 ENDIF
 if (nom.source_identifier in ("D8682" ,"E0840" ,"E0842" ,"E0940" ,"E0942" ,"E1040" ,"E1042" ,"E1140" ,"E1142" ,"E1340" ,"E1342" ,"G130" ,"G131" ,"G600" ,"G601" ,"G602" ,"G603" ,"G608" ,"G609" ,"G610" ,"G611" ,"G6181" ,"G6182" ,"G6189" ,"G619" ,"G620" ,"G621" ,"G622" ,"G6281" ,"G6282" ,"G6289" ,"G629" ,"G63" ,"G64" ,"G650" ,"G651" ,"G652" ,"G7000" ,"G7001" ,"G701" ,"G702" ,"G7080" ,"G7081" ,"G7089" ,"G709" ,"G7112" ,"G7113" ,"G7114" ,"G7119" ,"G713" ,"G718" ,"G719" ,"G720" ,"G721" ,"G722" ,"G723" ,"G7241" ,"G7249" ,"G7281" ,"G7289" ,"G729" ,"G731" ,"G733" ,"G737" ,"G9001" ,"G9009" ,"G902" ,"G904" ,"G9050" ,"G90511" ,"G90512" ,"G90513" ,"G90519" ,"G90521" ,"G90522" ,"G90523" ,"G90529" ,"G9059" ,"G908" ,"G909" ,"G990" ,"M0540" ,"M05411" ,"M05412" ,"M05419" ,"M05421" ,"M05422" ,"M05429" ,"M05431" ,"M05432" ,"M05439" ,"M05441" ,"M05442" ,"M05449" ,"M05451" ,"M05452" ,"M05459" ,"M05461" ,"M05462" ,"M05469"
  ,"M05471" ,"M05472" ,"M05479" ,"M0549" ,"M0550" ,"M05511" ,"M05512" ,"M05519"
  ,"M05521" ,"M05522" ,"M05529" ,"M05531" ,"M05532" ,"M05539" ,"M05541" ,"M05542" ,"M05549" ,"M05551" ,"M05552" ,"M05559" ,"M05561" ,"M05562" ,"M05569" ,"M05571" ,"M05572" ,"M05579" ,"M0559" ,"M3302" ,"M3312" ,"M3322" ,"M3392" ,"M3482" ,"M3483" ,"M3503"))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_CATEGORY ="CC-75"
endif
 if (nom.source_identifier in (
"G710"
,"G7100"
,"G7101"
,"G7102"
,"G7109"
,"G7111"
,"G712"
))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_CATEGORY ="CC-76"
endif
 if (nom.source_identifier in ("G35" ,"G360" ,"G361" ,"G368" ,"G369" ,"G370" ,"G371" ,"G372" ,"G375" ,"G378" ,"G379"))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_CATEGORY ="CC-77"
 ENDIF
 if (nom.source_identifier in ("G10" ,"G20" ,"G2111" ,"G2119" ,"G212" ,"G213" ,"G214" ,"G218" ,"G219" ,"G230" ,"G231" ,"G232" ,"G238" ,"G239" ,"G903"))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_CATEGORY ="CC-78"
endif
 if (nom.source_identifier in ("G40001" ,"G40009" ,"G40011" ,"G40019" ,"G40101" ,"G40109" ,"G40111" ,"G40119" ,"G40201" ,"G40209" ,"G40211" ,"G40219" ,"G40301" ,"G40309" ,"G40311" ,"G40319" ,"G40401" ,"G40409" ,"G40411" ,"G40419" ,"G40501" ,"G40509" ,"G40801" ,"G40802" ,"G40803" ,"G40804" ,"G40811" ,"G40812" ,"G40813" ,"G40814" ,"G40821" ,"G40822" ,"G40823" ,"G40824" ,"G4089" ,"G40901" ,"G40909" ,"G40911" ,"G40919" ,"G40A01" ,"G40A09" ,"G40A11" ,"G40A19" ,"G40B01" ,"G40B09" ,"G40B11" ,"G40B19" ,"R5600" ,"R5601" ,"R561" ,"R569"))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_CATEGORY ="CC-79"
 ENDIF
 if (nom.source_identifier in ("C770" ,"C771" ,"C772" ,"C774" ,"C775" ,"C778" ,"C7800" ,"C7801" ,"C7802" ,"C781" ,"C782" ,"C7830" ,"C7839" ,"C784" ,"C785" ,"C786" ,"C787" ,"C7880" ,"C7889" ,"C7900" ,"C7901" ,"C7902" ,"C7910" ,"C7911" ,"C7919" ,"C7931" ,"C7932" ,"C7940" ,"C7949" ,"C7951" ,"C7952" ,"C7960" ,"C7961" ,"C7962" ,"C7970" ,"C7971" ,"C7972" ,"C7989" ,"C799" ,"C7B00" ,"C7B01" ,"C7B02" ,"C7B03" ,"C7B04" ,"C7B09" ,"C7B1" ,"C7B8" ,"C800" ,"C9100" ,"C9101" ,"C9102" ,"C9200" ,"C9201" ,"C9202" ,"C9240" ,"C9241" ,"C9242" ,"C9250" ,"C9251" ,"C9252" ,"C9260" ,"C9261" ,"C9262" ,"C92A0" ,"C92A1" ,"C92A2" ,"C9300" ,"C9301" ,"C9302" ,"C9400" ,"C9401" ,"C9402" ,"C9420" ,"C9421" ,"C9422" ,"C9440" ,"C9441" ,"C9442" ,"C9500" ,"C9501" ,"C9502"))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_CATEGORY ="CC-8"
endif
if (nom.source_identifier in ("G931" ,"G935" ,"G936" ,"R4020" ,"R402110" ,"R402111" ,"R402112" ,"R402113" ,"R402114" ,"R402120" ,"R402121" ,"R402122" ,"R402123" ,"R402124" ,"R402210" ,"R402211" ,"R402212" ,"R402213" ,"R402214" ,"R402220" ,"R402221" ,"R402222" ,"R402223" ,"R402224" ,"R402310" ,"R402311" ,"R402312" ,"R402313" ,"R402314" ,"R402320" ,"R402321" ,"R402322" ,"R402323" ,"R402324" ,"R402340" ,"R402341" ,"R402342" ,"R402343" ,"R402344" ,"R40243" ,"R402430" ,"R402431" ,"R402432" ,"R402433" ,"R402434" ,"R40244" ,"R402440" ,"R402441" ,"R402442" ,"R402443" ,"R402444" ,"R403"))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_CATEGORY ="CC-80"
endif
 if (nom.source_identifier in (
"J9500"
,"J9501"
,"J9502"
,"J9503"
,"J9504"
,"J9509"
,"J95850"
,"J95859"
,"Z430"
,"Z930"
,"Z9911"
,"Z9912"
))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_CATEGORY ="CC-82"
 ENDIF
 if (nom.source_identifier in ("R092"))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_CATEGORY ="CC-83"
endif
 if (nom.source_identifier in ("I462" ,"I468" ,"I469" ,"I4901" ,"I4902" ,"J80" ,"J810" ,"J951" ,"J952" ,"J953" ,"J95821" ,"J95822" ,"J9600" ,"J9601" ,"J9602" ,"J9610" ,"J9611" ,"J9612" ,"J9620" ,"J9621" ,"J9622" ,"J9690" ,"J9691" ,"J9692" ,"R570" ,"R579" ,"T8111XA"))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_CATEGORY ="CC-84"
 ENDIF
 if (nom.source_identifier in ("A3681" ,"B3324" ,"I0981" ,"I110" ,"I130" ,"I132" ,"I2601" ,"I2602" ,"I2609" ,"I270" ,"I271" ,"I272" ,"I2720" ,"I2721" ,"I2722" ,"I2723" ,"I2724" ,"I2729" ,"I2781" ,"I2783" ,"I2789" ,"I279" ,"I280" ,"I281" ,"I288" ,"I289" ,"I420" ,"I421" ,"I422" ,"I423" ,"I424" ,"I425" ,"I426" ,"I427" ,"I428" ,"I429" ,"I43" ,"I501" ,"I5020" ,"I5021" ,"I5022" ,"I5023" ,"I5030" ,"I5031" ,"I5032" ,"I5033" ,"I5040" ,"I5041" ,"I5042" ,"I5043" ,"I50810" ,"I50811" ,"I50812" ,"I50813" ,"I50814" ,"I5082" ,"I5083" ,"I5084" ,"I5089" ,"I509" ,"I514" ,"I515"))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_CATEGORY ="CC-85"
endif
 if (nom.source_identifier in ("I2101" ,"I2102" ,"I2109" ,"I2111" ,"I2119" ,"I2121" ,"I2129" ,"I213" ,"I214" ,"I219" ,"I21A1" ,"I21A9" ,"I220" ,"I221" ,"I222" ,"I228" ,"I229" ,"I234" ,"I235" ,"I511" ,"I512"))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_CATEGORY ="CC-86"
endif
 if (nom.source_identifier in ("I200" ,"I230" ,"I231" ,"I232" ,"I233" ,"I236" ,"I237" ,"I238" ,"I240" ,"I241" ,"I248" ,"I249" ,"I25110" ,"I25700" ,"I25710" ,"I25720" ,"I25730" ,"I25750" ,"I25760" ,"I25790"))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_CATEGORY ="CC-87"
 ENDIF
 if (nom.source_identifier in ("I201" ,"I208" ,"I209" ,"I25111" ,"I25118" ,"I25119" ,"I25701" ,"I25708" ,"I25709" ,"I25711" ,"I25718" ,"I25719" ,"I25721" ,"I25728" ,"I25729" ,"I25731" ,"I25738" ,"I25739" ,"I25751" ,"I25758" ,"I25759" ,"I25761" ,"I25768" ,"I25769" ,"I25791" ,"I25798" ,"I25799"))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_CATEGORY ="CC-88"
endif
 if (nom.source_identifier in ("C153" ,"C154" ,"C155" ,"C158" ,"C159" ,"C160" ,"C161" ,"C162" ,"C163" ,"C164" ,"C165" ,"C166" ,"C168" ,"C169" ,"C170" ,"C171" ,"C172" ,"C173" ,"C178" ,"C179" ,"C220" ,"C221" ,"C222" ,"C223" ,"C224" ,"C227" ,"C228" ,"C229" ,"C23" ,"C240" ,"C241" ,"C248" ,"C249" ,"C250" ,"C251" ,"C252" ,"C253" ,"C254" ,"C257" ,"C258" ,"C259" ,"C33" ,"C3400" ,"C3401" ,"C3402" ,"C3410" ,"C3411" ,"C3412" ,"C342" ,"C3430" ,"C3431" ,"C3432" ,"C3480" ,"C3481" ,"C3482" ,"C3490" ,"C3491" ,"C3492" ,"C384" ,"C450" ,"C451" ,"C452" ,"C457" ,"C459" ,"C480" ,"C481" ,"C482" ,"C488" ,"C9000" ,"C9001" ,"C9002" ,"C9010" ,"C9011" ,"C9012" ,"C9020" ,"C9021" ,"C9022" ,"C9210" ,"C9211" ,"C9212" ,"C9220" ,"C9221" ,"C9222" ,"C9230" ,"C9231" ,"C9232" ,"C9290" ,"C9291" ,"C9292" ,"C92Z0" ,"C92Z1" ,"C92Z2" ,"C9310" ,"C9311" ,"C9312" ,"C9330" ,"C9331" ,"C9332" ,"C9390" ,"C9391" ,"C9392" ,"C93Z0" ,"C93Z1" ,"C93Z2" ,"C9430" ,"C9431" ,"C9432" ,"C9480" ,"C9481" ,"C9482"))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_CATEGORY ="CC-9"
 ENDIF
 if (nom.source_identifier in (
"I442","I470","I471","I472","I479","I480","I481"
,"I482"
,"I483"
,"I484"
,"I4891"
,"I4892"
,"I492"
,"I495"
))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_CATEGORY ="CC-96"
endif
if (nom.source_identifier in ("I6000" ,"I6001" ,"I6002" ,"I6010" ,"I6011" ,"I6012" ,"I602" ,"I6020" ,"I6021" ,"I6022" ,"I6030" ,"I6031" ,"I6032" ,"I604" ,"I6050" ,"I6051" ,"I6052" ,"I606" ,"I607" ,"I608" ,"I609" ,"I610" ,"I611" ,"I612" ,"I613" ,"I614" ,"I615" ,"I616" ,"I618" ,"I619" ,"I6200" ,"I6201" ,"I6202" ,"I6203" ,"I621" ,"I629"))
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_CATEGORY ="CC-99"
endif
 
endif
 
 
 
if (RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_CATEGORY="CC-8" )  RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_HCC = "HCC-8"    RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_RANK ="1"   RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_RANKING_GROUP ="Metastatic Cancer and Acute Leukemia"  endif
if (RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_CATEGORY="CC-9" )  RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_HCC = "HCC-9"       RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_RANK ="2"   RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_RANKING_GROUP ="Lung and Other Severe Cancers"  endif
if (RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_CATEGORY="CC-10" )  RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_HCC = "HCC-10"       RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_RANK ="3"   RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_RANKING_GROUP ="Lymphoma and Other Cancers"  endif
if (RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_CATEGORY="CC-11" )  RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_HCC = "HCC-11"       RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_RANK ="4"   RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_RANKING_GROUP ="Colorectal, Bladder, and Other Cancers"  endif
if (RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_CATEGORY="CC-12" )  RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_HCC = "HCC-12"       RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_RANK ="5"   RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_RANKING_GROUP ="Breast, Prostate, and Other Cancers and Tumors"  endif
if (RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_CATEGORY="CC-17" )  RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_HCC = "HCC-17"       RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_RANK ="1"   RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_RANKING_GROUP ="Diabetes with Acute Complications"  endif
if (RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_CATEGORY="CC-18" )  RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_HCC = "HCC-18"       RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_RANK ="2"   RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_RANKING_GROUP ="Diabetes with Chronic Complications"  endif
if (RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_CATEGORY="CC-19" )  RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_HCC = "HCC-19"       RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_RANK ="3"   RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_RANKING_GROUP ="Diabetes without Complication"  endif
if (RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_CATEGORY="CC-27" )  RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_HCC = "HCC-27"       RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_RANK ="1"   RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_RANKING_GROUP ="End-Stage Liver Disease"  endif
if (RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_CATEGORY="CC-28" )  RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_HCC = "HCC-28"       RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_RANK ="2"   RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_RANKING_GROUP ="Cirrhosis of Liver"  endif
if (RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_CATEGORY="CC-29" )  RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_HCC = "HCC-29"       RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_RANK ="3"   RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_RANKING_GROUP ="Chronic Hepatitis"  endif
if (RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_CATEGORY="CC-27" )  RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_HCC = "HCC-27"       RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_RANK ="1"   RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_RANKING_GROUP ="End-Stage Liver Disease"  endif
if (RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_CATEGORY="CC-80" )  RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_HCC = "HCC-80"       RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_RANK ="2"   RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_RANKING_GROUP ="Coma, Brain Compression/Anoxic Damage"  endif
if (RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_CATEGORY="CC-46" )  RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_HCC = "HCC-46"       RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_RANK ="1"   RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_RANKING_GROUP ="Severe Hematological Disorders"  endif
if (RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_CATEGORY="CC-48" )  RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_HCC = "HCC-48"       RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_RANK ="2"   RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_RANKING_GROUP ="Coagulation Defects and Other Specified Hematological Disorders"  endif
if (RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_CATEGORY="CC-54" )  RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_HCC = "HCC-54"       RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_RANK ="1"   RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_RANKING_GROUP ="Drug/Alcohol Psychosis"  endif
if (RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_CATEGORY="CC-55" )  RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_HCC = "HCC-55"       RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_RANK ="2"   RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_RANKING_GROUP ="Drug/Alcohol Dependence"  endif
if (RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_CATEGORY="CC-57" )  RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_HCC = "HCC-57"       RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_RANK ="1"   RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_RANKING_GROUP ="Schizophrenia"  endif
if (RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_CATEGORY="CC-58" )  RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_HCC = "HCC-58"       RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_RANK ="2"   RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_RANKING_GROUP ="Major Depressive, Bipolar, and Paranoid Disorders"  endif
if (RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_CATEGORY="CC-70" )  RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_HCC = "HCC-70"       RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_RANK ="1"   RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_RANKING_GROUP ="Quadriplegia"  endif
if (RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_CATEGORY="CC-71" )  RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_HCC = "HCC-71"       RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_RANK ="2"   RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_RANKING_GROUP ="Paraplegia"  endif
if (RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_CATEGORY="CC-72" )  RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_HCC = "HCC-72"       RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_RANK ="3"   RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_RANKING_GROUP ="Spinal Cord Disorders/Injuries"  endif
if (RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_CATEGORY="CC-169" )  RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_HCC = "HCC-169"       RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_RANK ="4"   RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_RANKING_GROUP ="Vertebral Fractures without Spinal Cord Injury"  endif
if (RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_CATEGORY="CC-70" )  RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_HCC = "HCC-70"       RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_RANK ="1"   RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_RANKING_GROUP ="Quadriplegia"  endif
if (RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_CATEGORY="CC-103" )  RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_HCC = "HCC-103"       RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_RANK ="2"   RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_RANKING_GROUP ="Hemiplegia/Hemiparesis"  endif
if (RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_CATEGORY="CC-70" )  RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_HCC = "HCC-70"       RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_RANK ="1"   RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_RANKING_GROUP ="Quadriplegia"  endif
if (RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_CATEGORY="CC-104" )  RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_HCC = "HCC-104"       RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_RANK ="2"   RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_RANKING_GROUP ="Monoplegia, Other Paralytic Syndromes"  endif
if (RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_CATEGORY="CC-71" )  RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_HCC = "HCC-71"       RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_RANK ="1"   RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_RANKING_GROUP ="Paraplegia"  endif
if (RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_CATEGORY="CC-104" )  RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_HCC = "HCC-104"       RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_RANK ="2"   RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_RANKING_GROUP ="Monoplegia, Other Paralytic Syndromes"  endif
if (RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_CATEGORY="CC-82" )  RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_HCC = "HCC-82"       RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_RANK ="1"   RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_RANKING_GROUP ="Respirator Dependence/Tracheostomy Status"  endif
if (RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_CATEGORY="CC-83" )  RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_HCC = "HCC-83"       RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_RANK ="2"   RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_RANKING_GROUP ="Respiratory Arrest"  endif
if (RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_CATEGORY="CC-84" )  RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_HCC = "HCC-84"       RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_RANK ="3"   RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_RANKING_GROUP ="Cardio-Respiratory Failure and Shock"  endif
if (RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_CATEGORY="CC-86" )  RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_HCC = "HCC-86"       RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_RANK ="1"   RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_RANKING_GROUP ="Acute Myocardial Infarction"  endif
if (RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_CATEGORY="CC-87" )  RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_HCC = "HCC-87"       RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_RANK ="2"   RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_RANKING_GROUP ="Unstable Angina and Other Acute Ischemic Heart Disease"  endif
if (RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_CATEGORY="CC-88" )  RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_HCC = "HCC-88"       RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_RANK ="3"   RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_RANKING_GROUP ="Angina Pectoris"  endif
if (RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_CATEGORY="CC-99" )  RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_HCC = "HCC-99"       RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_RANK ="1"   RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_RANKING_GROUP ="Cerebral Hemorrhage"  endif
if (RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_CATEGORY="CC-100" )  RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_HCC = "HCC-100"       RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_RANK ="2"   RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_RANKING_GROUP ="Ischemic or Unspecified Stroke"  endif
if (RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_CATEGORY="CC-103" )  RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_HCC = "HCC-103"       RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_RANK ="1"   RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_RANKING_GROUP ="Hemiplegia/Hemiparesis"  endif
if (RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_CATEGORY="CC-104" )  RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_HCC = "HCC-104"       RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_RANK ="2"   RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_RANKING_GROUP ="Monoplegia, Other Paralytic Syndromes"  endif
if (RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_CATEGORY="CC-106" )  RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_HCC = "HCC-106"       RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_RANK ="1"   RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_RANKING_GROUP ="Atherosclerosis of the Extremities with Ulceration or Gangrene"  endif
if (RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_CATEGORY="CC-107" )  RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_HCC = "HCC-107"       RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_RANK ="2"   RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_RANKING_GROUP ="Vascular Disease with Complications"  endif
if (RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_CATEGORY="CC-108" )  RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_HCC = "HCC-108"       RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_RANK ="3"   RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_RANKING_GROUP ="Vascular Disease"  endif
if (RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_CATEGORY="CC-106" )  RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_HCC = "HCC-106"       RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_RANK ="1"   RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_RANKING_GROUP ="Atherosclerosis of the Extremities with Ulceration or Gangrene"  endif
if (RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_CATEGORY="CC-161" )  RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_HCC = "HCC-161"       RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_RANK ="2"   RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_RANKING_GROUP ="Chronic Ulcer of Skin, Except Pressure"  endif
if (RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_CATEGORY="CC-106" )  RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_HCC = "HCC-106"       RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_RANK ="1"   RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_RANKING_GROUP ="Atherosclerosis of the Extremities with Ulceration or Gangrene"  endif
if (RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_CATEGORY="CC-189" )  RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_HCC = "HCC-189"       RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_RANK ="2"   RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_RANKING_GROUP ="Artificial Openings for Feeding or Elimination"  endif
if (RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_CATEGORY="CC-110" )  RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_HCC = "HCC-110"       RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_RANK ="1"   RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_RANKING_GROUP ="Cystic Fibrosis"  endif
if (RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_CATEGORY="CC-111" )  RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_HCC = "HCC-111"       RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_RANK ="2"   RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_RANKING_GROUP ="Chronic Obstructive Pulmonary Disease"  endif
if (RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_CATEGORY="CC-112" )  RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_HCC = "HCC-112"       RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_RANK ="3"   RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_RANKING_GROUP ="Fibrosis of Lung and Other Chronic Lung Disorders"  endif
if (RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_CATEGORY="CC-114" )  RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_HCC = "HCC-114"       RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_RANK ="1"   RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_RANKING_GROUP ="Aspiration and Specified Bacterial Pneumonias"  endif
if (RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_CATEGORY="CC-115" )  RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_HCC = "HCC-115"       RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_RANK ="2"   RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_RANKING_GROUP ="Pneumococcal Pneumonia, Empyema, Lung Abscess"  endif
if (RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_CATEGORY="CC-134" )  RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_HCC = "HCC-134"       RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_RANK ="1"   RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_RANKING_GROUP ="Dialysis Status"  endif
if (RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_CATEGORY="CC-135" )  RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_HCC = "HCC-135"       RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_RANK ="2"   RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_RANKING_GROUP ="Acute Renal Failure"  endif
if (RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_CATEGORY="CC-136" )  RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_HCC = "HCC-136"       RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_RANK ="3"   RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_RANKING_GROUP ="Chronic Kidney Disease (Stage 5)"  endif
if (RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_CATEGORY="CC-137" )  RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_HCC = "HCC-137"       RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_RANK ="4"   RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_RANKING_GROUP ="Chronic Kidney Disease, Severe (Stage 4)   "  endif
if (RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_CATEGORY="CC-157" )  RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_HCC = "HCC-157"       RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_RANK ="1"   RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_RANKING_GROUP ="Pressure Ulcer of Skin with Necrosis Through to Muscle, Tendon, or Bone"  endif
if (RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_CATEGORY="CC-158" )  RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_HCC = "HCC-158"       RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_RANK ="2"   RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_RANKING_GROUP ="Pressure Ulcer of Skin with Full Thickness Skin Loss"  endif
if (RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_CATEGORY="CC-161" )  RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_HCC = "HCC-161"       RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_RANK ="3"   RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_RANKING_GROUP ="Chronic Ulcer of Skin, Except Pressure"  endif
if (RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_CATEGORY="CC-166" )  RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_HCC = "HCC-166"       RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_RANK ="1"   RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_RANKING_GROUP ="Severe Head Injury"  endif
if (RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_CATEGORY="CC-167" )  RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_HCC = "HCC-167"       RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_RANK ="2"   RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_RANKING_GROUP ="Major Head Injury"  endif
if (RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_CATEGORY="CC-166" )  RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_HCC = "HCC-166"       RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_RANK ="1"   RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_RANKING_GROUP ="Severe Head Injury"  endif
if (RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_CATEGORY="CC-80" )  RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_HCC = "HCC-80"       RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_RANK ="2"   RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_RANKING_GROUP ="Coma, Brain Compression/Anoxic Damage"  endif
 
 
if (RDATA->PER[D1.SEQ].ENCS[D2.SEQ].DISCHARGE_CONDITION_CODE ="CC-111")
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].DISCHARGE_CC_WEIGHT ="0.0150"
endif
if (RDATA->PER[D1.SEQ].ENCS[D2.SEQ].DISCHARGE_CONDITION_CODE ="CC-57")
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].DISCHARGE_CC_WEIGHT ="0.2516"
endif
if (RDATA->PER[D1.SEQ].ENCS[D2.SEQ].DISCHARGE_CONDITION_CODE ="CC-79")
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].DISCHARGE_CC_WEIGHT ="-0.0581"
endif
if (RDATA->PER[D1.SEQ].ENCS[D2.SEQ].DISCHARGE_CONDITION_CODE ="CC-85")
RDATA->PER[D1.SEQ].ENCS[D2.SEQ].DISCHARGE_CC_WEIGHT ="0.0961"
endif
 
 
if (RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_HCC ="HCC-10" )   RDATA->PER[D1.SEQ].ENCS[D2.SEQ].HCC_WEIGHT ="0.1836"  endif
if (RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_HCC ="HCC-106" )   RDATA->PER[D1.SEQ].ENCS[D2.SEQ].HCC_WEIGHT ="0.0385"  endif
if (RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_HCC ="HCC-107" )   RDATA->PER[D1.SEQ].ENCS[D2.SEQ].HCC_WEIGHT ="0.2507"  endif
if (RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_HCC ="HCC-108" )   RDATA->PER[D1.SEQ].ENCS[D2.SEQ].HCC_WEIGHT ="0.0855"  endif
if (RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_HCC ="HCC-111" )   RDATA->PER[D1.SEQ].ENCS[D2.SEQ].HCC_WEIGHT ="0.1058"  endif
if (RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_HCC ="HCC-114" )   RDATA->PER[D1.SEQ].ENCS[D2.SEQ].HCC_WEIGHT ="0.006"  endif
if (RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_HCC ="HCC-134" )   RDATA->PER[D1.SEQ].ENCS[D2.SEQ].HCC_WEIGHT ="0.0896"  endif
if (RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_HCC ="HCC-135" )   RDATA->PER[D1.SEQ].ENCS[D2.SEQ].HCC_WEIGHT ="0.1425"  endif
if (RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_HCC ="HCC-136" )   RDATA->PER[D1.SEQ].ENCS[D2.SEQ].HCC_WEIGHT ="0.139"  endif
if (RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_HCC ="HCC-139" )   RDATA->PER[D1.SEQ].ENCS[D2.SEQ].HCC_WEIGHT ="0.1665"  endif
if (RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_HCC ="HCC-140" )   RDATA->PER[D1.SEQ].ENCS[D2.SEQ].HCC_WEIGHT ="0.0718"  endif
if (RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_HCC ="HCC-161" )   RDATA->PER[D1.SEQ].ENCS[D2.SEQ].HCC_WEIGHT ="0.0673"  endif
if (RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_HCC ="HCC-17" )   RDATA->PER[D1.SEQ].ENCS[D2.SEQ].HCC_WEIGHT ="0.0867"  endif
if (RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_HCC ="HCC-176" )   RDATA->PER[D1.SEQ].ENCS[D2.SEQ].HCC_WEIGHT ="0.1138"  endif
if (RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_HCC ="HCC-18" )   RDATA->PER[D1.SEQ].ENCS[D2.SEQ].HCC_WEIGHT ="0.0748"  endif
if (RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_HCC ="HCC-188" )   RDATA->PER[D1.SEQ].ENCS[D2.SEQ].HCC_WEIGHT ="0.1359"  endif
if (RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_HCC ="HCC-19" )   RDATA->PER[D1.SEQ].ENCS[D2.SEQ].HCC_WEIGHT ="0.0436"  endif
if (RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_HCC ="HCC-2" )   RDATA->PER[D1.SEQ].ENCS[D2.SEQ].HCC_WEIGHT ="0.0509"  endif
if (RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_HCC ="HCC-21" )   RDATA->PER[D1.SEQ].ENCS[D2.SEQ].HCC_WEIGHT ="0.1722"  endif
if (RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_HCC ="HCC-23" )   RDATA->PER[D1.SEQ].ENCS[D2.SEQ].HCC_WEIGHT ="0.09"  endif
if (RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_HCC ="HCC-27" )   RDATA->PER[D1.SEQ].ENCS[D2.SEQ].HCC_WEIGHT ="0.3186"  endif
if (RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_HCC ="HCC-28" )   RDATA->PER[D1.SEQ].ENCS[D2.SEQ].HCC_WEIGHT ="0.1458"  endif
if (RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_HCC ="HCC-29" )   RDATA->PER[D1.SEQ].ENCS[D2.SEQ].HCC_WEIGHT ="0.024"  endif
if (RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_HCC ="HCC-33" )   RDATA->PER[D1.SEQ].ENCS[D2.SEQ].HCC_WEIGHT ="0.2734"  endif
if (RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_HCC ="HCC-34" )   RDATA->PER[D1.SEQ].ENCS[D2.SEQ].HCC_WEIGHT ="0.1187"  endif
if (RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_HCC ="HCC-35" )   RDATA->PER[D1.SEQ].ENCS[D2.SEQ].HCC_WEIGHT ="0.0318"  endif
if (RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_HCC ="HCC-39" )   RDATA->PER[D1.SEQ].ENCS[D2.SEQ].HCC_WEIGHT ="0.1223"  endif
if (RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_HCC ="HCC-40" )   RDATA->PER[D1.SEQ].ENCS[D2.SEQ].HCC_WEIGHT ="0.0638"  endif
if (RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_HCC ="HCC-46" )   RDATA->PER[D1.SEQ].ENCS[D2.SEQ].HCC_WEIGHT ="0.0732"  endif
if (RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_HCC ="HCC-47" )   RDATA->PER[D1.SEQ].ENCS[D2.SEQ].HCC_WEIGHT ="0.1955"  endif
if (RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_HCC ="HCC-48" )   RDATA->PER[D1.SEQ].ENCS[D2.SEQ].HCC_WEIGHT ="0.07"  endif
if (RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_HCC ="HCC-51" )   RDATA->PER[D1.SEQ].ENCS[D2.SEQ].HCC_WEIGHT ="0.0423"  endif
if (RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_HCC ="HCC-54" )   RDATA->PER[D1.SEQ].ENCS[D2.SEQ].HCC_WEIGHT ="0.2336"  endif
if (RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_HCC ="HCC-55" )   RDATA->PER[D1.SEQ].ENCS[D2.SEQ].HCC_WEIGHT ="0.0832"  endif
if (RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_HCC ="HCC-57" )   RDATA->PER[D1.SEQ].ENCS[D2.SEQ].HCC_WEIGHT ="0.3152"  endif
if (RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_HCC ="HCC-58" )   RDATA->PER[D1.SEQ].ENCS[D2.SEQ].HCC_WEIGHT ="0.2019"  endif
if (RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_HCC ="HCC-75" )   RDATA->PER[D1.SEQ].ENCS[D2.SEQ].HCC_WEIGHT ="0.0978"  endif
if (RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_HCC ="HCC-79" )   RDATA->PER[D1.SEQ].ENCS[D2.SEQ].HCC_WEIGHT ="0.1088"  endif
if (RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_HCC ="HCC-8" )   RDATA->PER[D1.SEQ].ENCS[D2.SEQ].HCC_WEIGHT ="0.5619"  endif
if (RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_HCC ="HCC-84" )   RDATA->PER[D1.SEQ].ENCS[D2.SEQ].HCC_WEIGHT ="0.1176"  endif
if (RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_HCC ="HCC-85" )   RDATA->PER[D1.SEQ].ENCS[D2.SEQ].HCC_WEIGHT ="0.193"  endif
if (RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_HCC ="HCC-87" )   RDATA->PER[D1.SEQ].ENCS[D2.SEQ].HCC_WEIGHT ="0.1043"  endif
if (RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_HCC ="HCC-9" )   RDATA->PER[D1.SEQ].ENCS[D2.SEQ].HCC_WEIGHT ="0.2393"  endif
if (RDATA->PER[D1.SEQ].ENCS[D2.SEQ].COMORBID_HCC ="HCC-96" )   RDATA->PER[D1.SEQ].ENCS[D2.SEQ].HCC_WEIGHT ="0.1197"  endif
 
 
 
WITH NOCOUNTER
 
 /*
 SELECT INTO "nl:"
 
 
 PATIENT_NAME = RDATA->PER[D1.SEQ].NAME
 ,FIN =  RDATA->PER[D1.SEQ].ENCS[D2.SEQ].FIN
 ,PRIMARY_INSURANCE = rDATA->PER[d1.seq].ENCS[d2.seq].PHP_NAME
 ,PRIMARY_PLAN_TYPE =rDATA->PER[d1.seq].ENCS[d2.seq].PHP_PLANTYPE
 ,NUMBER_OF_ENCOUNTERS =  rDATA->PER[D1.SEQ].nbr_encs
 ,FACILITY =RDATA->PER[D1.SEQ].ENCS[D2.SEQ].ORG_NAME
 ,AGE =RDATA->PER[D1.SEQ].AGE
 ,SEX=RDATA->PER[D1.SEQ].SEX
 ,cur_adm=cnvtdatetime(rDATA->PER[d1.seq].ENCS[d2.seq].admit_dt_tm) "@SHORTDATETIME"
 ,cur_dis=cnvtdatetime(rDATA->PER[d1.seq].ENCS[d2.seq].DISCH_DATEC) "@SHORTDATETIME"
 ,prev_dis=cnvtdatetime(rDATA->PER[d1.seq].ENCS[d2.seq-1].DISCH_DATEC) "@SHORTDATETIME"
 ,prev_dis_30=cnvtdatetime(rDATA->PER[d1.seq].ENCS[d2.seq-1].DISCH_DATEC +30) "@SHORTDATETIME"
 ,daydiff=datetimediff(rDATA->PER[d1.seq].ENCS[d2.seq].admit_dt_tm,rDATA->PER[d1.seq].ENCS[d2.seq-1].DISCH_DATEC)
 ,daydiff=datetimediff(rDATA->PER[d1.seq].ENCS[d2.seq-1].DISCH_DATEC,rDATA->PER[d1.seq].ENCS[d2.seq].admit_dt_tm)
 
 ;,cnvtdate(rDATA->PER[d1.seq].ENCS[d2.seq-1].admit_dt_tm)
 ,MRN= RDATA->PER[D1.SEQ].ENCS[D2.SEQ].MRN
 ,VISIT_TYPE = RDATA->PER[D1.SEQ].ENCS[D2.SEQ].ENCNTR_TYPE
 ,ADMIT_DATE = RDATA->PER[D1.SEQ].ENCS[D2.SEQ].ADMIT_DATE
 ,DISCH_DT =  RDATA->PER[D1.SEQ].ENCS[D2.SEQ].DISCH_DATE
 ,LOS = RDATA->PER[D1.SEQ].ENCS[D2.SEQ].LOS
  ,DAYS_DIFF = if (rDATA->PER[d1.seq].ENCS[d2.seq].DAYS_DIFF <0) 0 else rDATA->PER[d1.seq].ENCS[d2.seq].DAYS_DIFF endif
,INDEX_DIAG_CODE = TRIM(rDATA->PER[d1.seq].ENCS[d2.seq].INDEX_DIAG_CODE )
 ,INDEX_DIANOSIS = TRIM( rDATA->PER[d1.seq].ENCS[d2.seq].INDEX_DIANOSIS )
 ,PRIMARY_DISCH_DIAG_CODE = TRIM(rDATA->PER[d1.seq].ENCS[d2.seq].PRIMARY_DISCH_DIAG_CODE)
 ,PRIMARY_DISCH_DIAGNOSIS = TRIM(rDATA->PER[d1.seq].ENCS[d2.seq].PRIMARY_DISCH_DIAGNOSIS )
 ,HOSPICE =rDATA->PER[d1.seq].ENCS[d2.seq].HOSPICE
 ,SURGERY = rDATA->PER[d1.seq].ENCS[d2.seq].SURGERY
 ,DISCHARGE_CONDITION_CODE = rDATA->PER[d1.seq].ENCS[d2.seq].DISCHARGE_CONDITION_CODE
 ,COMORBID_CATEGORY =rDATA->PER[d1.seq].ENCS[d2.seq].COMORBID_CATEGORY
  ,COMORBID_HCC =rDATA->PER[d1.seq].ENCS[d2.seq].COMORBID_HCC
  ,COMORBID_RANK =rDATA->PER[d1.seq].ENCS[d2.seq].COMORBID_RANK
 ,COMORBID_RANKING_GROUP = rDATA->PER[d1.seq].ENCS[d2.seq].COMORBID_RANKING_GROUP
 ,ATTENDING_PHYSICIAN =rDATA->PER[d1.seq].ENCS[d2.seq].ATTENDING_PHYSICIAN
 ,DECEASED_IND = rDATA->PER[d1.seq].ENCS[d2.seq].deceased_ind
 ,transfer_info = rDATA->PER[d1.seq].ENCS[d2.seq].TRANSFER_INFO
 ,RISK_ADJUSTED_WEIGHT  = rDATA->PER[d1.seq].ENCS[d2.seq].RISK_ADJUSTED_WEIGHT
 ,OBSERVATION_STAY_WEIGHT  = rDATA->PER[d1.seq].ENCS[d2.seq].OBSERVATION_STAY_WEIGHT
 ,	SURGICAL_WEIGHT = rDATA->PER[d1.seq].ENCS[d2.seq].SURGICAL_WEIGHT
 ,	DISCHARGE_CC_WEIGHT  = rDATA->PER[d1.seq].ENCS[d2.seq].DISCHARGE_CC_WEIGHT
 , HCC_WEIGHT = rDATA->PER[d1.seq].ENCS[d2.seq].HCC_WEIGHT
 
 
FROM
		(DUMMYT   D1  WITH SEQ = VALUE(SIZE(RDATA->PER, 5))),
		(DUMMYT   D2  WITH SEQ =  VALUE(SIZE(RDATA->PER, 5)))
 
PLAN D1
	WHERE MAXREC(D2, SIZE(RDATA->PER[D1.SEQ].ENCS, 5))
; and rDATA->PER[D1.SEQ].NBR_ENCS > 1
 
 
JOIN D2
where datetimediff(rDATA->PER[d1.seq].ENCS[d2.seq].admit_dt_tm,rDATA->PER[d1.seq].ENCS[d2.seq-1].DISCH_DATEC) < 30
and  datetimediff(rDATA->PER[d1.seq].ENCS[d2.seq].admit_dt_tm,rDATA->PER[d1.seq].ENCS[d2.seq-1].DISCH_DATEC) > 0
 
ORDER BY RDATA->PER[D1.SEQ].PERSON_ID,RDATA->PER[D1.SEQ].ENCS[D2.SEQ].ENCNTR_ID
 
WITH
     nocounter
 
 */
 
/***************************************************************************************
* Output the Results																   *
***************************************************************************************/
 
;Display the results
;CALL ECHORECORD(rDATA)
 /**************************************************************
; Output Data
**************************************************************/
 
;declare filename = vc with constant(build2('avh_ob_clin_smoke_measures_',format(sysdate,'MM_DD_YYYY;;q'),'.txt'))
	SELECT INTO $pOUTDEV
 
 
 PATIENT_NAME = RDATA->PER[D1.SEQ].NAME
 ,FIN =  RDATA->PER[D1.SEQ].ENCS[d2.seq-1].FIN
 ,PRIMARY_INSURANCE = rDATA->PER[d1.seq].ENCS[d2.seq-1].PHP_NAME
 ,SECONDARY_INSURANCE = rDATA->PER[d1.seq].ENCS[d2.seq-1].SEC_PLAN
 ,PRIMARY_PLAN_TYPE =rDATA->PER[d1.seq].ENCS[d2.seq-1].PHP_PLANTYPE
 ,NUMBER_OF_ENCOUNTERS =  rDATA->PER[D1.SEQ].nbr_encs
 ,FACILITY =RDATA->PER[D1.SEQ].ENCS[d2.seq-1].ORG_NAME
 ,AGE =RDATA->PER[D1.SEQ].AGE
 ,SEX=RDATA->PER[D1.SEQ].SEX
; ,day_d=datetimediff(rDATA->PER[d1.seq].ENCS[d2.seq].admit_dt_tm,rDATA->PER[d1.seq].ENCS[d2.seq-1].DISCH_DATEC)
 ,MRN= RDATA->PER[D1.SEQ].ENCS[d2.seq-1].MRN
 ,VISIT_TYPE = RDATA->PER[D1.SEQ].ENCS[d2.seq-1].ENCNTR_TYPE
 ,ADMIT_DATE = RDATA->PER[D1.SEQ].ENCS[d2.seq-1].ADMIT_DATE
 ,DISCH_DT =  RDATA->PER[D1.SEQ].ENCS[d2.seq-1].DISCH_DATE
 ,LOS = RDATA->PER[D1.SEQ].ENCS[d2.seq-1].LOS
  ;,DAYS_DIFF = if (rDATA->PER[d1.seq].ENCS[d2.seq-1].DAYS_DIFF <0) 0 else rDATA->PER[d1.seq].ENCS[d2.seq-1].DAYS_DIFF endif
,INDEX_DIAG_CODE = TRIM(rDATA->PER[d1.seq].ENCS[d2.seq-1].INDEX_DIAG_CODE )
 ,INDEX_DIANOSIS = TRIM( rDATA->PER[d1.seq].ENCS[d2.seq-1].INDEX_DIANOSIS )
 ,PRIMARY_DISCH_DIAG_CODE = TRIM(rDATA->PER[d1.seq].ENCS[d2.seq-1].PRIMARY_DISCH_DIAG_CODE)
 ,PRIMARY_DISCH_DIAGNOSIS = TRIM(rDATA->PER[d1.seq].ENCS[d2.seq-1].PRIMARY_DISCH_DIAGNOSIS )
 ,HOSPICE =rDATA->PER[d1.seq].ENCS[d2.seq-1].HOSPICE
 ,SURGERY = rDATA->PER[d1.seq].ENCS[d2.seq-1].SURGERY
 ,DISCHARGE_CONDITION_CODE = rDATA->PER[d1.seq].ENCS[d2.seq-1].DISCHARGE_CONDITION_CODE
 ,COMORBID_CATEGORY =rDATA->PER[d1.seq].ENCS[d2.seq-1].COMORBID_CATEGORY
  ,COMORBID_HCC =rDATA->PER[d1.seq].ENCS[d2.seq-1].COMORBID_HCC
  ,COMORBID_RANK =rDATA->PER[d1.seq].ENCS[d2.seq-1].COMORBID_RANK
 ,COMORBID_RANKING_GROUP = rDATA->PER[d1.seq].ENCS[d2.seq-1].COMORBID_RANKING_GROUP
 ,ATTENDING_PHYSICIAN =rDATA->PER[d1.seq].ENCS[d2.seq-1].ATTENDING_PHYSICIAN
 ,DECEASED_IND = rDATA->PER[d1.seq].ENCS[d2.seq-1].deceased_ind
 ,transfer_info = rDATA->PER[d1.seq].ENCS[d2.seq-1].TRANSFER_INFO
 ,RISK_ADJUSTED_WEIGHT  = rDATA->PER[d1.seq].ENCS[d2.seq-1].RISK_ADJUSTED_WEIGHT
 ,OBSERVATION_STAY_WEIGHT  = rDATA->PER[d1.seq].ENCS[d2.seq-1].OBSERVATION_STAY_WEIGHT
 ,	SURGICAL_WEIGHT = rDATA->PER[d1.seq].ENCS[d2.seq-1].SURGICAL_WEIGHT
 ,	DISCHARGE_CC_WEIGHT  = rDATA->PER[d1.seq].ENCS[d2.seq-1].DISCHARGE_CC_WEIGHT
 , HCC_WEIGHT = rDATA->PER[d1.seq].ENCS[d2.seq-1].HCC_WEIGHT
 
; ,PATIENT_NAME = RDATA->PER[D1.SEQ].NAME
 ,READMIT_FIN =  RDATA->PER[D1.SEQ].ENCS[d2.seq].FIN
; ,PRIMARY_INSURANCE = rDATA->PER[d1.seq].ENCS[d2.seq].PHP_NAME
 ;,PRIMARY_PLAN_TYPE =rDATA->PER[d1.seq].ENCS[d2.seq].PHP_PLANTYPE
; ,NUMBER_OF_ENCOUNTERS =  rDATA->PER[D1.SEQ].nbr_encs
 ,FACILITY =RDATA->PER[D1.SEQ].ENCS[d2.seq].ORG_NAME
 ;,AGE =RDATA->PER[D1.SEQ].AGE
 ;,SEX=RDATA->PER[D1.SEQ].SEX
;,day_d=datetimediff(rDATA->PER[d1.seq].ENCS[d2.seq].admit_dt_tm,rDATA->PER[d1.seq].ENCS[d2.seq-1].DISCH_DATEC)
; ,MRN= RDATA->PER[D1.SEQ].ENCS[d2.seq].MRN
 ,READMIT_VISIT_TYPE = RDATA->PER[D1.SEQ].ENCS[d2.seq].ENCNTR_TYPE
 ,READMIT_DATE = RDATA->PER[D1.SEQ].ENCS[d2.seq].ADMIT_DATE
 ,READMIT_DISCH_DT =  RDATA->PER[D1.SEQ].ENCS[d2.seq].DISCH_DATE
 ,LOS2 = RDATA->PER[D1.SEQ].ENCS[d2.seq].LOS
  ,READMIT_DAYS_DIFF = if (rDATA->PER[d1.seq].ENCS[d2.seq].DAYS_DIFF <0) 0 else rDATA->PER[d1.seq].ENCS[d2.seq].DAYS_DIFF endif
,READMIT_DIAG_CODE = TRIM(rDATA->PER[d1.seq].ENCS[d2.seq].INDEX_DIAG_CODE )
 ,READMIT_DIANOSIS = TRIM( rDATA->PER[d1.seq].ENCS[d2.seq].INDEX_DIANOSIS )
 ,READMIT_PRIMARY_DISCH_DIAG_CODE = TRIM(rDATA->PER[d1.seq].ENCS[d2.seq].PRIMARY_DISCH_DIAG_CODE)
 ,READMIT_PRIMARY_DISCH_DIAGNOSIS = TRIM(rDATA->PER[d1.seq].ENCS[d2.seq].PRIMARY_DISCH_DIAGNOSIS )
 ,READMIT_HOSPICE =rDATA->PER[d1.seq].ENCS[d2.seq].HOSPICE
 ,READMIT_SURGERY = rDATA->PER[d1.seq].ENCS[d2.seq].SURGERY
 ,READMIT_DISCHARGE_CONDITION_CODE = rDATA->PER[d1.seq].ENCS[d2.seq].DISCHARGE_CONDITION_CODE
 ,READMIT_COMORBID_CATEGORY =rDATA->PER[d1.seq].ENCS[d2.seq].COMORBID_CATEGORY
  ,READMIT_COMORBID_HCC =rDATA->PER[d1.seq].ENCS[d2.seq].COMORBID_HCC
  ,READMIT_COMORBID_RANK =rDATA->PER[d1.seq].ENCS[d2.seq].COMORBID_RANK
 ,READMIT_COMORBID_RANKING_GROUP = rDATA->PER[d1.seq].ENCS[d2.seq].COMORBID_RANKING_GROUP
 ,READMIT_ATTENDING_PHYSICIAN =rDATA->PER[d1.seq].ENCS[d2.seq].ATTENDING_PHYSICIAN
 ,READMIT_DECEASED_IND = rDATA->PER[d1.seq].ENCS[d2.seq].deceased_ind
 ,READMIT_transfer_info = rDATA->PER[d1.seq].ENCS[d2.seq].TRANSFER_INFO
 ,READMIT_RISK_ADJUSTED_WEIGHT  = rDATA->PER[d1.seq].ENCS[d2.seq].RISK_ADJUSTED_WEIGHT
 ,READMIT_OBSERVATION_STAY_WEIGHT  = rDATA->PER[d1.seq].ENCS[d2.seq].OBSERVATION_STAY_WEIGHT
 ,	READMIT_SURGICAL_WEIGHT = rDATA->PER[d1.seq].ENCS[d2.seq].SURGICAL_WEIGHT
 ,	READMIT_DISCHARGE_CC_WEIGHT  = rDATA->PER[d1.seq].ENCS[d2.seq].DISCHARGE_CC_WEIGHT
 , READMIT_HCC_WEIGHT = rDATA->PER[d1.seq].ENCS[d2.seq].HCC_WEIGHT
 
FROM
		(DUMMYT   D1  WITH SEQ = VALUE(SIZE(RDATA->PER, 5))),
		(DUMMYT   D2  WITH SEQ =  VALUE(SIZE(RDATA->PER, 5)))
 
PLAN D1
	WHERE MAXREC(D2, SIZE(RDATA->PER[D1.SEQ].ENCS, 5))
; and rDATA->PER[D1.SEQ].NBR_ENCS > 1
 
 
JOIN D2
;where datetimediff(rDATA->PER[d1.seq].ENCS[d2.seq].admit_dt_tm,rDATA->PER[d1.seq].ENCS[d2.seq-1].DISCH_DATEC) < 30
;and  datetimediff(rDATA->PER[d1.seq].ENCS[d2.seq].admit_dt_tm,rDATA->PER[d1.seq].ENCS[d2.seq-1].DISCH_DATEC) > 0
 
 
ORDER BY RDATA->PER[D1.SEQ].PERSON_ID,RDATA->PER[D1.SEQ].ENCS[D2.SEQ].ENCNTR_ID
 
WITH format,
SEPARATOR=" ",
    ; format = stream,
    ; pcformat('"',',',1),
     nocounter
 /*
 
 
 SELECT INTO $pOUTDEV
 
 
 PATIENT_NAME = RDATA->PER[D3.SEQ].NAME
 ,FIN =  RDATA->PER[D3.SEQ].ENCS[d3.seq].FIN
 ,PRIMARY_INSURANCE = rDATA->PER[d3.seq].ENCS[d4.seq].PHP_NAME
 ,SECONDARY_INSURANCE = rDATA->PER[d3.seq].ENCS[d4.seq].SEC_PLAN
 ,PRIMARY_PLAN_TYPE =rDATA->PER[d3.seq].ENCS[d4.seq].PHP_PLANTYPE
 ,NUMBER_OF_ENCOUNTERS =  rDATA->PER[D3.SEQ].nbr_encs
 ,FACILITY =RDATA->PER[D3.SEQ].ENCS[d4.seq].ORG_NAME
 ,AGE =RDATA->PER[D3.SEQ].AGE
 ,SEX=RDATA->PER[D3.SEQ].SEX
,day_d=datetimediff(rDATA->PER[d3.seq].ENCS[d4.seq].admit_dt_tm,rDATA->PER[d3.seq].ENCS[d4.seq-1].DISCH_DATEC)
 ,MRN= RDATA->PER[D3.SEQ].ENCS[d4.seq].MRN
 ,VISIT_TYPE = RDATA->PER[D3.SEQ].ENCS[d4.seq].ENCNTR_TYPE
 ,ADMIT_DATE = RDATA->PER[D3.SEQ].ENCS[d4.seq].ADMIT_DATE
 ,DISCH_DT =  RDATA->PER[D3.SEQ].ENCS[d4.seq].DISCH_DATE
 ,LOS = RDATA->PER[D3.SEQ].ENCS[d4.seq].LOS
  ,DAYS_DIFF = if (rDATA->PER[d3.seq].ENCS[d4.seq].DAYS_DIFF <0) 0 else rDATA->PER[d3.seq].ENCS[d4.seq].DAYS_DIFF endif
,INDEX_DIAG_CODE = TRIM(rDATA->PER[d3.seq].ENCS[d4.seq].INDEX_DIAG_CODE )
 ,INDEX_DIANOSIS = TRIM( rDATA->PER[d3.seq].ENCS[d4.seq].INDEX_DIANOSIS )
 ,PRIMARY_DISCH_DIAG_CODE = TRIM(rDATA->PER[d3.seq].ENCS[d4.seq].PRIMARY_DISCH_DIAG_CODE)
 ,PRIMARY_DISCH_DIAGNOSIS = TRIM(rDATA->PER[d3.seq].ENCS[d4.seq].PRIMARY_DISCH_DIAGNOSIS )
 ,HOSPICE =rDATA->PER[d3.seq].ENCS[d4.seq].HOSPICE
 ,SURGERY = rDATA->PER[d3.seq].ENCS[d4.seq].SURGERY
 ,DISCHARGE_CONDITION_CODE = rDATA->PER[d3.seq].ENCS[d4.seq].DISCHARGE_CONDITION_CODE
 ,COMORBID_CATEGORY =rDATA->PER[d3.seq].ENCS[d4.seq].COMORBID_CATEGORY
  ,COMORBID_HCC =rDATA->PER[d3.seq].ENCS[d4.seq].COMORBID_HCC
  ,COMORBID_RANK =rDATA->PER[d3.seq].ENCS[d4.seq].COMORBID_RANK
 ,COMORBID_RANKING_GROUP = rDATA->PER[d3.seq].ENCS[d4.seq].COMORBID_RANKING_GROUP
 ,ATTENDING_PHYSICIAN =rDATA->PER[d3.seq].ENCS[d4.seq].ATTENDING_PHYSICIAN
 ,DECEASED_IND = rDATA->PER[d3.seq].ENCS[d4.seq].deceased_ind
 ,transfer_info = rDATA->PER[d3.seq].ENCS[d4.seq].TRANSFER_INFO
 ,RISK_ADJUSTED_WEIGHT  = rDATA->PER[d3.seq].ENCS[d4.seq].RISK_ADJUSTED_WEIGHT
 ,OBSERVATION_STAY_WEIGHT  = rDATA->PER[d3.seq].ENCS[d4.seq].OBSERVATION_STAY_WEIGHT
 ,	SURGICAL_WEIGHT = rDATA->PER[d3.seq].ENCS[d4.seq].SURGICAL_WEIGHT
 ,	DISCHARGE_CC_WEIGHT  = rDATA->PER[d3.seq].ENCS[d4.seq].DISCHARGE_CC_WEIGHT
 , HCC_WEIGHT = rDATA->PER[d3.seq].ENCS[d4.seq].HCC_WEIGHT
 
 
FROM
		(DUMMYT   D3  WITH SEQ = VALUE(SIZE(RDATA->PER, 5))),
		(DUMMYT   D4  WITH SEQ =  1)
 
PLAN D3
	WHERE MAXREC(D4, SIZE(RDATA->PER[D3.SEQ].ENCS, 5))
; and rDATA->PER[D1.SEQ].NBR_ENCS > 1
 
 
JOIN D4
 
 
 ORDER BY RDATA->PER[D3.SEQ].PERSON_ID,RDATA->PER[D3.SEQ].ENCS[D4.SEQ].ENCNTR_ID
 
WITH format,
     format = stream,
     pcformat('"',',',1),
     nocounter*/
 
#EXIT_SCRIPT
 
;call echorecord(pats)
 
END GO
