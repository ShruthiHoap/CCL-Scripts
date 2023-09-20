/*********************************************************************
*                       MODIFICATION CONTROL LOG		             *
**********************************************************************
*                                                                    *
Mod Date       Worker        Comment                                 *
--- ---------- ------------- ----------------------------------------*
000 5/25/2021  L. Garrison   Initial Development
 
**********************************************************************/
DROP PROGRAM avh_qip_cms135 GO
CREATE PROGRAM avh_qip_cms135
 
prompt
	"Output to File/Printer/MINE" = "MINE"   ;* Enter or select the printer or file name to send this report to.
	, "Discharge Start Date:" = ""
	, "Discharge End Date:" = ""
	, "Rolling Year" = 0
 
with pOUTDEV, pSTART_DATE, pEND_DATE, ryear
 
 
/***************************************************************************************
* Gather Prompt Information															   *
***************************************************************************************/
 
;Format the dates for explorermenu and ops
DECLARE START_DATE 	= DQ8
DECLARE END_DATE 	= DQ8
DECLARE EVENT_START_DATE 	= DQ8
DECLARE EVENT_END_DATE 		= DQ8
DECLARE INDEX = I4
 
IF (ISNUMERIC($pSTART_DATE) > 0) ;input was in curdate/curtime format
	SET START_DATE = CNVTDATETIME($pSTART_DATE,0)
ELSE ;input was in MM/DD/YYYY string format
	SET START_DATE = CNVTDATETIME(CNVTDATE2($pSTART_DATE,"MM/DD/YYYY"),0)
ENDIF
 
IF (ISNUMERIC($pEND_DATE) > 0) ;input was in curdate/curtime format
	SET END_DATE = CNVTDATETIME($pEND_DATE,2359)
ELSE ;input was in MM/DD/YYYY string format
	SET END_DATE = CNVTDATETIME(CNVTDATE2($pEND_DATE,"MM/DD/YYYY"),2359)
ENDIF
 
 
;Check the max date range
IF (ABS(DATETIMEDIFF(CNVTDATETIME(START_DATE),CNVTDATETIME(END_DATE),1)) > 370)
	SELECT INTO $pOUTDEV
	FROM DUMMYT D
	PLAN D
	DETAIL
		COL 0, ROW 1,
		"Date range greater than thirty-one days not allowed."
	WITH FORMAT
 
	GO TO EXIT_SCRIPT
ENDIF
 
;----------------------------------------------------------------
declare s_dt = vc
declare e_dt = vc
declare fisc_year = i4
 
/***********************************************************************************************
; Determine current fiscal/rolling year
************************************************************************************************/
 if($ryear = 0); not rolling year report
 
  if(month(cnvtdatetime(start_date)) between 1 and 6) ;last half of fiscal year, use prior year start
    set fisc_year = year(cnvtdatetime(start_date)) - 1
    set s_dt = concat("01-JUL-", format(fisc_year,"####")," 00:00:00")
    set e_dt = format(cnvtdatetime(end_date),"dd-mmm-yyyy hh:mm:ss;;d")
  else  ;first half of fiscal year, use current year start
    set fisc_year = year(cnvtdatetime(start_date))
    set s_dt = concat("01-JUL-", format(fisc_year,"####")," 00:00:00")
    set e_dt = format(cnvtdatetime(end_date),"dd-mmm-yyyy hh:mm:ss;;d")
  endif
 
 elseif($ryear = 1); Rolling Year Report (last 12 Months)
    set s_dt = format(cnvtlookbehind("12,M",cnvtdatetime(start_date)),"dd-mmm-yyyy hh:mm:ss;;d")
    set e_dt = format(cnvtdatetime(end_date),"dd-mmm-yyyy hh:mm:ss;;d")
 
 elseif($ryear = 2); Calendar Year Report (Current Calendar Year)
    set s_dt = format(datetimefind(cnvtdatetime(start_date),"Y","B","B"),"dd-mmm-yyyy hh:mm:ss;;d")
    set e_dt = format(cnvtdatetime(end_date),"dd-mmm-yyyy hh:mm:ss;;d")
 
 endif
;----------------------------------------------------------------
 
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
 
/***************************************************************************************
* Variable and Record Definition													   *
***************************************************************************************/
 
free record pats
record pats(
 
1 patcnt = i4
1 pat[*]
	2 pid = f8
	2 encntr_cnt = i4
)WITH PROTECT
 
free record rDATA
RECORD rDATA(
	1 PERCNT = I4
	1 PER[*]
		2 PERSON_ID				= F8
		2 NAME					= C200
		2 MRN					= C30
		2 AGE					= C20
		2 BIRTH_DATE			= C20
		2 NBR_ENCS				= I2
		2 VISIT_TYPES			= C200
		2 DISP					= I2
 		2 ENCS[*]
			3 ENCNTR_ID			= F8
			3 FIN				= C30
			3 LOS				= I4
			3 ADMIT_DATE		= C20
			3 DISCH_DATE		= C20
			3 DISCH_DISP		= C40
			3 ENCNTR_TYPE		= C50
			3 ENC_LOC			= C50
			3 ENC_CNT 			= I4
			3 HPLANS			= C100
			3 PLAN_QUAL			= I2
			3 PHP_ID			= F8
			3 P_MBR_NBR			= VC
			3 PHP_NAME			= C60
			3 PHP_PLANTYPE		= C30
			3 PHP_TYPE_CD		= F8
			3 PHP_PRISEQ		= I4
			3 SHP_ID			= F8
			3 S_MBR_NBR			= VC
			3 SHP_NAME			= C60
			3 SP_PLANTYPE		= C30
			3 SHP_TYPE_CD		= F8
			3 SHP_PRISEQ		= I4
			3 ORG_NAME 			= c40
			3 HF_DX				= c100
			3 ENC_HPLNS[*]
				4 HP_ID			= F8
				4 HP_NAME		= C30
				4 HP_PLANTYPE	= C30
				4 HP_PRISEQ		= I4
)WITH PROTECT
 
 
DECLARE cvFIN_NBR		= F8 WITH CONSTANT(UAR_GET_CODE_BY("DISPLAY_KEY",319,"FINNBR"))
DECLARE cvMRN			= F8 WITH CONSTANT(UAR_GET_CODE_BY("DISPLAY_KEY",4,"MRN"))
 
declare NUM = i4 with noconstant(0)
declare POS = i4 with noconstant(0)
 
;**********************************************************************************************************
; Pull Patients Discharged in range entered
;**********************************************************************************************************
SELECT INTO "NL:"
 
FROM ENCOUNTER E
	,PERSON P
 
PLAN E WHERE E.DISCH_DT_TM+0 BETWEEN CNVTDATETIME(S_DT) AND CNVTDATETIME(E_DT)
	and E.ACTIVE_IND = 1
	and E.END_EFFECTIVE_DT_TM > SYSDATE
  	and e.encntr_type_cd in ( 309310.00; Emergency
                             ,309308.00; Inpatient
                             ,309312.00; Observation
                             ,19962820.00; Outpatient in a Bed
                             ,309309.00); Outpatient
JOIN P WHERE P.PERSON_ID = E.PERSON_ID
 
ORDER BY P.PERSON_ID
 
HEAD REPORT
	PCNT = 0
 
HEAD P.PERSON_ID
 
	PCNT = PCNT + 1
 	if(mod(pcnt, 10) = 1)
		STAT = ALTERLIST(pats->pat,PCNT+9)
	endif
	pats->pat[PCNT].pid		= P.PERSON_ID
 
HEAD E.encntr_id
 
    pats->pat[PCNT].encntr_cnt += 1
 
FOOT REPORT
 	pats->patcnt = PCNT
	STAT = ALTERLIST(pats->pat,PCNT)
 
WITH NOCOUNTER
 
/***************************************************************************************
* Get Encounter Info for Patients															   *
***************************************************************************************/
SELECT INTO "NL:"
 
 reg_dt = format(e.reg_dt_tm,"mm/dd/yy;;q")
 
FROM
	 (DUMMYT   D3  WITH SEQ = value(size(pats->pat,5)))
	,ENCOUNTER E
	,PERSON P
	,PERSON_ALIAS PA
	,ENCNTR_ALIAS EA
	,ENCNTR_PLAN_RELTN EPR
	,HEALTH_PLAN HP
 
PLAN D3
join E WHERE e.person_id = pats->pat[d3.seq].pid
		and e.encntr_type_cd in ( 309310.00; Emergency
                                 ,309308.00; Inpatient
                                 ,309312.00; Observation
                                 ,19962820.00; Outpatient in a Bed
                                 ,309309.00); Outpatient
		and E.DISCH_DT_TM+0 BETWEEN CNVTDATETIME(START_DATE) AND CNVTDATETIME(END_DATE)
		and E.ACTIVE_IND = 1
	and E.END_EFFECTIVE_DT_TM > SYSDATE
JOIN P WHERE P.PERSON_ID = E.PERSON_ID
JOIN EA	WHERE EA.ENCNTR_ID = E.ENCNTR_ID
	and EA.ENCNTR_ALIAS_TYPE_CD = cvFIN_NBR
	and EA.ACTIVE_IND = 1
	and EA.END_EFFECTIVE_DT_TM > SYSDATE
JOIN PA	WHERE PA.PERSON_ID = P.PERSON_ID
	and PA.PERSON_ALIAS_TYPE_CD = cvMRN
	and PA.ACTIVE_IND = 1
	and PA.END_EFFECTIVE_DT_TM > SYSDATE
JOIN EPR WHERE EPR.ENCNTR_ID = E.ENCNTR_ID
	AND EPR.PERSON_ID = E.PERSON_ID
JOIN HP	WHERE HP.HEALTH_PLAN_ID = EPR.HEALTH_PLAN_ID
 
ORDER BY P.PERSON_ID, E.REG_DT_TM, E.ENCNTR_ID, EPR.PRIORITY_SEQ
 
HEAD REPORT
	PCNT = 0
	ECNT = 0
 
HEAD P.PERSON_ID
 
	PCNT = PCNT + 1
	if(mod(PCNT, 10) = 1)
		STAT = ALTERLIST(rDATA->PER,PCNT + 9)
	endif
 
	rDATA->PER[PCNT].PERSON_ID		= P.PERSON_ID
	rDATA->PER[PCNT].MRN			= PA.ALIAS
	rDATA->PER[PCNT].NAME			= P.NAME_FULL_FORMATTED
	rDATA->PER[PCNT].BIRTH_DATE		= FORMAT(P.BIRTH_DT_TM,"MM/DD/YYYY;;D")
	rDATA->PER[PCNT].AGE			= TRIM(CNVTAGE(P.BIRTH_DT_TM, e.disch_dt_tm, 0))
 
	ECNT = 0
	HCNT = 0
 
HEAD E.ENCNTR_ID
 
	ECNT = ECNT + 1
	if(mod(ECNT, 10) = 1)
		STAT = ALTERLIST(rDATA->PER[PCNT].ENCS,ECNT+9)
 	endif
 
	rDATA->PER[PCNT].ENCS[ECNT].ENCNTR_ID			= E.ENCNTR_ID
	rDATA->PER[PCNT].ENCS[ECNT].FIN					= EA.ALIAS
	rDATA->PER[PCNT].ENCS[ECNT].ADMIT_DATE			= FORMAT(E.REG_DT_TM,"MM/DD/YY HH:MM;;D")
	rDATA->PER[PCNT].ENCS[ECNT].DISCH_DATE			= FORMAT(E.DISCH_DT_TM,"MM/DD/YY HH:MM;;D")
	rDATA->PER[PCNT].ENCS[ECNT].DISCH_DISP			= UAR_GET_CODE_DISPLAY(E.DISCH_DISPOSITION_CD)
	rDATA->PER[PCNT].ENCS[ECNT].ENCNTR_TYPE			= TRIM(UAR_GET_CODE_DISPLAY(E.ENCNTR_TYPE_CD))
	rDATA->PER[PCNT].ENCS[ECNT].ORG_NAME			= TRIM(UAR_GET_CODE_DISPLAY(E.loc_facility_cd))
	rDATA->PER[PCNT].VISIT_TYPES = CONCAT(TRIM( UAR_GET_CODE_DISPLAY(E.ENCNTR_TYPE_CD))," ",reg_dt, " - ",
															rDATA->PER[PCNT].VISIT_TYPES)
	HCNT = 0
 
DETAIL
 
	CASE(EPR.PRIORITY_SEQ)
 
		OF 1:		rDATA->PER[PCNT].ENCS[ECNT].PHP_ID			=	HP.HEALTH_PLAN_ID
					rDATA->PER[PCNT].ENCS[ECNT].P_MBR_NBR		=	EPR.MEMBER_NBR
					rDATA->PER[PCNT].ENCS[ECNT].PHP_NAME		=	HP.PLAN_NAME
					rDATA->PER[PCNT].ENCS[ECNT].PHP_PLANTYPE	=	UAR_GET_CODE_DISPLAY(HP.PLAN_TYPE_CD)
					rDATA->PER[PCNT].ENCS[ECNT].PHP_TYPE_CD		=	HP.PLAN_TYPE_CD
					rDATA->PER[PCNT].ENCS[ECNT].PHP_PRISEQ		=	EPR.PRIORITY_SEQ
 					HCNT = HCNT + 1
					rDATA->PER[PCNT].ENCS[ECNT].HPLANS =
					BUILD( HP.PLAN_NAME,
					"(",EPR.MEMBER_NBR ,")"," - ",rDATA->PER[PCNT].ENCS[ECNT].HPLANS)
 
		OF 2:		rDATA->PER[PCNT].ENCS[ECNT].SHP_ID			=	HP.HEALTH_PLAN_ID
					rDATA->PER[PCNT].ENCS[ECNT].S_MBR_NBR		=	EPR.MEMBER_NBR
					rDATA->PER[PCNT].ENCS[ECNT].SHP_NAME		=	HP.PLAN_NAME
					rDATA->PER[PCNT].ENCS[ECNT].SP_PLANTYPE 	=	UAR_GET_CODE_DISPLAY(HP.PLAN_TYPE_CD)
					rDATA->PER[PCNT].ENCS[ECNT].SHP_TYPE_CD		=	HP.PLAN_TYPE_CD
					rDATA->PER[PCNT].ENCS[ECNT].SHP_PRISEQ		=	EPR.PRIORITY_SEQ
 					HCNT = HCNT + 1
					rDATA->PER[PCNT].ENCS[ECNT].HPLANS = ;BUILD( HP.PLAN_NAME," - ",rDATA->PER[PCNT].ENCS[ECNT].HPLANS)
					BUILD( HP.PLAN_NAME,
					"(",EPR.MEMBER_NBR ,")"," - ",rDATA->PER[PCNT].ENCS[ECNT].HPLANS)
	ENDCASE
 
FOOT P.PERSON_ID
 
 
	rDATA->PER[PCNT].NBR_ENCS = pats->pat[d3.seq].encntr_cnt
	STAT = ALTERLIST(rDATA->PER[PCNT].ENCS,ECNT)
 
FOOT REPORT
 
 	rDATA->PERCNT = PCNT
	STAT = ALTERLIST(rDATA->PER,PCNT)
 
WITH NOCOUNTER, TIME = 1800
 
;***********************************************************************
;  Heart Failure DX
;***********************************************************************/
SELECT INTO "NL:"
 
FROM
	(DUMMYT   D1  WITH SEQ = SIZE(RDATA->PER, 5))
	, (DUMMYT   D2  WITH SEQ = 1)
	, DIAGNOSIS   DX
	, NOMENCLATURE   NOM
 
PLAN D1 WHERE MAXREC(D2, SIZE(RDATA->PER[D1.SEQ].ENCS, 5))
JOIN D2
 
JOIN DX WHERE DX.encntr_id = rDATA->PER[d1.seq].ENCS[d2.seq].ENCNTR_ID
	and DX.ACTIVE_IND = 1
	and DX.END_EFFECTIVE_DT_TM > SYSDATE
	and DX.DIAG_TYPE_CD = 88 ; Discharge
 
JOIN NOM WHERE NOM.NOMENCLATURE_ID = DX.NOMENCLATURE_ID
	and NOM.ACTIVE_IND = 1
	and NOM.END_EFFECTIVE_DT_TM > SYSDATE
 	and NOM.source_identifier in ('I11.0', 'I13.0', 'I13.2', 'I50.1', 'I50.20', 'I50.21', 'I50.22', 'I50.23',
 						'I50.30', 'I50.31', 'I50.32', 'I50.33', 'I50.40', 'I50.41', 'I50.42', 'I50.43', 'I50.814',
 						'I50.82', 'I50.83', 'I50.84', 'I50.89', 'I50.9')
ORDER BY
	DX.ENCNTR_ID
	, DX.DIAGNOSIS_ID
 
DETAIL
 
	rDATA->PER[d1.seq].ENCS[d2.seq].HF_DX  = BUILD(NOM.SOURCE_IDENTIFIER,"*"
		,rDATA->PER[d1.seq].ENCS[d2.seq].HF_DX)
 
WITH NOCOUNTER, TIME = 1800
 
 
/***************************************************************************************
* Output the Results																   *
***************************************************************************************/
 
SELECT INTO $pOUTDEV
		;PID = RDATA->PER[D1.SEQ].PERSON_ID
		 MRN = RDATA->PER[D1.SEQ].MRN
     	,FIN = RDATA->PER[D1.SEQ].ENCS[D2.SEQ].FIN
     	;,ENCTR = RDATA->PER[D1.SEQ].ENCS[D2.SEQ].ENCNTR_ID
		,NAME = RDATA->PER[D1.SEQ].NAME
		,AGE = RDATA->PER[D1.SEQ].AGE
        ,LOCATION = RDATA->PER[D1.SEQ].ENCS[D2.SEQ].ORG_NAME
        ,PATIENT_TYPE = RDATA->PER[D1.SEQ].ENCS[D2.SEQ].ENCNTR_TYPE
        ,PRI_PLAN_NAME = RDATA->PER[D1.SEQ].ENCS[D2.SEQ].PHP_NAME
		,PRI_PLAN_TYPE = RDATA->PER[D1.SEQ].ENCS[D2.SEQ].PHP_PLANTYPE
        ,SEC_PLAN_NAME = RDATA->PER[D1.SEQ].ENCS[D2.SEQ].SHP_NAME
		,SEC_PLAN_TYPE = RDATA->PER[D1.SEQ].ENCS[D2.SEQ].SP_PLANTYPE
		,DISH_DATE = RDATA->PER[D1.SEQ].ENCS[D2.SEQ].DISCH_DATE
		,DISCH_DISPOSITION = RDATA->PER[D1.SEQ].ENCS[D2.SEQ].DISCH_DISP
		,HEART_FAILURE_DX = rDATA->PER[d1.seq].ENCS[d2.seq].HF_DX
 
FROM (DUMMYT   D1  WITH SEQ = VALUE(SIZE(RDATA->PER, 5))),
		(DUMMYT   D2  WITH SEQ = 1)
 
PLAN D1	WHERE MAXREC(D2, SIZE(RDATA->PER[D1.SEQ].ENCS, 5))
 
JOIN D2 WHERE rDATA->PER[d1.seq].ENCS[d2.seq].HF_DX > ' '
 
ORDER BY NAME
 
WITH format, format = stream, nocounter, pcformat('"',',',1)
;WITH NOCOUNTER, SEPARATOR=" ", FORMAT,time=360
 
#EXIT_SCRIPT
 
 
END GO
 
