drop program avh_ed_arr_mode_driver go
create program avh_ed_arr_mode_driver
 
prompt
	"Output to File/Printer/MINE" = "MINE"   ;* Enter or select the printer or file name to send this report to.
	, "Start Date" = "SYSDATE"
	, "End Date" = "SYSDATE"
 
with OUTDEV, STARTDATE, ENDDATE
 
/**************************************************************
; DVDev DECLARED VARIABLES
**************************************************************/
record ed_pts(
	1 ed_pt_list[*]
		2 encntrid = f8
		2 ed_admit_dt = dq8
		2 ed_fin = c25
		2 ed_checkin = dq8
		2 ed_amb_start = dq8
		2 ed_amb_end = dq8
		2 ed_amb_mins = i4
		2 ed_amb_bed = c10
		2 ed_amb_payor = c100
		2 arrival_mode =c100
		2 es_level =c100
)
 
declare cnt = i4 with Protect
declare dtl_cnt = i4 with Protect
set cnt = 0
set dtl_cnt = 0
/**************************************************************
; DVDev Start Coding
**************************************************************/
SELECT INTO "NL:"
	TC.CHECKIN_DT_TM
	, t.encntr_id
	, ea.alias
	, TL_LOC_ROOM_DISP = UAR_GET_CODE_DISPLAY(TL.LOC_ROOM_CD)
	, TL_LOC_NURSE_UNIT_DISP = UAR_GET_CODE_DISPLAY(TL.LOC_NURSE_UNIT_CD)
 
FROM
	TRACKING_CHECKIN   TC
	, TRACKING_ITEM   T
	, TRACKING_LOCATOR   TL
	, encntr_alias   ea
	, encounter   e
 
WHERE tc.checkin_dt_tm between cnvtdatetime($STARTDATE) and cnvtdatetime($ENDDATE)
		and
		 tc.tracking_group_cd =     2554887529.00  ; AVH ED tracking group
		;and t.encntr_id=  119812555.00
and TC.TRACKING_ID = T.TRACKING_ID
and ea.encntr_id = t.encntr_id
	and ea.alias_pool_cd = 38741899.00 ;FIN
and e.encntr_id = t.encntr_id
	and ((e.loc_nurse_unit_cd != 2554885293.00 and e.encntr_status_cd = 854) ; still in ED on active encounter
			 or (e.encntr_status_cd = 856)) ; discharged encounter
   ; and e.admit_mode_cd!=   36824319.00	;Private Auto

and TL.TRACKING_ID = t.tracking_id
 
ORDER BY
	t.encntr_id
	, tc.checkin_dt_tm
	, TL.TRACKING_LOCATOR_ID
 
HEAD t.encntr_id
	cnt = cnt + 1
	if(mod(cnt,10)=1)
		stat = alterlist(ed_pts->ed_pt_list, cnt+9)
	endif
	ed_pts->ed_pt_list[cnt].ed_admit_dt = tc.checkin_dt_tm
	ed_pts->ed_pt_list[cnt].ed_fin = ea.alias
	ed_pts->ed_pt_list[cnt].encntrid = t.encntr_id
	ed_pts->ed_pt_list[cnt].ed_checkin = tc.checkin_dt_tm
	dtl_cnt = 0
DETAIL
	dtl_cnt = dtl_cnt + 1
	if(dtl_cnt = 2)      ; transfer to AMB bed should occur on 2nd row
		if(substring(1,3,TL_LOC_ROOM_DISP) = 'AMB' and TL_LOC_NURSE_UNIT_DISP != 'ED Hold'
			and cnvtint(substring(4,2,TL_LOC_ROOM_DISP)) between 5 and 25)
			ed_pts->ed_pt_list[cnt].ed_amb_start = tl.arrive_dt_tm
			ed_pts->ed_pt_list[cnt].ed_amb_end = tl.depart_dt_tm
			ed_pts->ed_pt_list[cnt].ed_amb_mins = datetimediff(tl.depart_dt_tm,
				ed_pts->ed_pt_list[cnt].ed_checkin,4)
			ed_pts->ed_pt_list[cnt].ed_amb_bed = tl_loc_room_disp
		endif
	endif
	if(dtl_cnt > 2)    ; pt may be transfered from one AMB bed to another so capture that time
		if(substring(1,3,TL_LOC_ROOM_DISP) = 'AMB' and TL_LOC_NURSE_UNIT_DISP != 'ED Hold'
			and cnvtint(substring(4,2,TL_LOC_ROOM_DISP)) between 5 and 25)
			ed_pts->ed_pt_list[cnt].ed_amb_end = tl.depart_dt_tm
			ed_pts->ed_pt_list[cnt].ed_amb_mins = datetimediff(tl.depart_dt_tm,
				ed_pts->ed_pt_list[cnt].ed_checkin,4)
			ed_pts->ed_pt_list[cnt].ed_amb_bed = tl_loc_room_disp
		endif
	endif
  if (e.admit_mode_cd!=   36824319.00)
  ed_pts->ed_pt_list[cnt].arrival_mode = uar_get_code_display(e.admit_mode_cd)
  endif
FOOT REPORT
	stat = alterlist(ed_pts->ed_pt_list, cnt)
 
WITH NOCOUNTER, SEPARATOR=" ", FORMAT
 /*
     3330051.00	         72		ESI Level 1
    3330054.00	         72		ESI Level 2
    3330057.00	         72		ESI Level 3

 */
 
 /**************************************************************
; Get ESI Level Information
**************************************************************/
for(x = 1 to cnt)
	SELECT INTO "NL:"
	FROM CLINICAL_EVENT CE
	WHERE ce.encntr_id = ed_pts->ed_pt_list[x].encntrid
				and ce.event_cd  =    3346954.00
				/*in (
				 3330051.00	  ;       72		ESI Level 1
,    3330054.00	   ;      72		ESI Level 2
,    3330057.00	  ;       72		ESI Level 3
				)*/
			and ce.view_level=1
			and ce.valid_until_dt_tm>sysdate
			and ce.result_status_cd in (25,34,35)
			;and ce.event_tag="Yes"
	DETAIL
		ed_pts->ed_pt_list[x].es_level = ce.result_val  ;uar_get_code_display(ce.event_cd)
	WITH NOCOUNTER, SEPARATOR=" ", FORMAT
endfor
 
 
 
/**************************************************************
; Get Payor Information
**************************************************************/
for(x = 1 to cnt)
	SELECT INTO "NL:"
	FROM ENCNTR_PLAN_RELTN   EP
		, HEALTH_PLAN   H
	WHERE ep.encntr_id = ed_pts->ed_pt_list[x].encntrid
				and EP.ACTIVE_IND = 1
				and EP.PRIORITY_SEQ = 1
			and H.HEALTH_PLAN_ID = EP.HEALTH_PLAN_ID
				and h.active_ind = 1
	DETAIL
		ed_pts->ed_pt_list[x].ed_amb_payor = h.plan_name
 
	WITH NOCOUNTER, SEPARATOR=" ", FORMAT
endfor
 
/**************************************************************
; Output results
**************************************************************/
SELECT INTO $OUTDEV
	FIN = ED_PTS->ed_pt_list[D1.SEQ].ed_fin
	, CHECKIN = ED_PTS->ed_pt_list[D1.SEQ].ed_checkin "mm/dd/yy hh:mm;;q"
	, AMB_END = ED_PTS->ed_pt_list[D1.SEQ].ed_amb_end "mm/dd/yy hh:mm;;q"
	, AMB_MINS = ED_PTS->ed_pt_list[D1.SEQ].ed_amb_mins
	, AMB_BED = ED_PTS->ed_pt_list[D1.SEQ].ed_amb_bed
	, PAYOR = ED_PTS->ed_pt_list[D1.SEQ].ed_amb_payor
	,ARRIVAL_MODE = ED_PTS->ed_pt_list[D1.SEQ].arrival_mode
	,ESI_LEVEL = ED_PTS->ed_pt_list[D1.SEQ].es_level
	;, ED_PT_LIST_ENCNTRID = ED_PTS->ed_pt_list[D1.SEQ].encntrid
 
FROM
	(DUMMYT   D1  WITH SEQ = VALUE(SIZE(ED_PTS->ed_pt_list, 5)))
 
PLAN D1 WHERE ED_PTS->ed_pt_list[D1.SEQ].ed_amb_bed > " "
; and ED_PTS->ed_pt_list[D1.SEQ].arrival_mode <= " "
ORDER BY
	CHECKIN

 
WITH NOCOUNTER, SEPARATOR=" ", FORMAT
 
end
go
 
