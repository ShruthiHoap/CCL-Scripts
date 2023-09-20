/*********************************************************************************************************************************
  Report Name:
  Script Name: avh discharge orders by KP
  Source Code: cust_script:avh_kp_discharge_orders.prg
  Created By: Shruthi R 
  Requestor: Courtney Vanmannen
 
  IT PoC:
 
  Program Description:
  
 
  Path:
 
**********************************************************************************************************************************
                      GENERATED MODIFICATION CONTROL LOG
**********************************************************************************************************************************
  Mod| Date     | Programmer    |  Issue / Req#  |  Comment
  ---| -------- | ------------- | -------------  | ----------------------------------------------------------------------------- *
  000| 11/04/22 | Shruthi R       | SR-134247       | Initial release            *
**********************************************************************************************************************************/
drop program avh_kp_discharge_orders:dba go
create program avh_kp_discharge_orders:dba

prompt 
	"Output to File/Printer/MINE" = "MINE"
	, "Start Date" = "SYSDATE"
	, "End Date" = "SYSDATE" 

with OUTDEV, STARTDATE, ENDDATE

 

 
%i cust_script:avh_mail_routine.inc
 
/**************************************************************
; DVDev DECLARED SUBROUTINES
**************************************************************/
 
/**************************************************************
; DVDev DECLARED VARIABLES
**************************************************************/
record pft (
 1 cnt = i4
 1 data [*]
  ; Member Details
  
  2 encntr_id = f8
  2 PatientName=vc
	2 Patient_DOB	=dq8
	2 FIN =vc
	2 discharge_dt_tm =dq8
	2 Discharge_order =vc
	2 attending_phy =vc
	2 order_provider =vc
	2 disch_disposition = vc
	2 time_diff= f8;dq8
	2 Kp_group= vc
	2 order_prov_id = f8
	 
)
 
declare beg_dt_tm = dq8
declare end_dt_tm = dq8
declare i = i4 with noconstant(0)
declare disch_cd = f8 with constant(uar_get_code_by('meaning',17,'DISCHARGE'))
declare fin_cd = f8 with constant(uar_get_code_by('display_key',319,'FINNBR'))
declare mrn_cd = f8 with constant(uar_get_code_by('display_key',4,'MRN'))
 
/**************************************************************
; DVDev Start Coding
**************************************************************/
 
select into 'nl:'
time_diff=timestampdiff(e.disch_dt_tm,oa.action_dt_tm)
from 
encounter e
,person p
,encntr_prsnl_reltn epr
,prsnl pr
,orders o
,order_action oa
,prsnl opr
,encntr_alias ea

 
 
plan e
where ; e.encntr_id=  116878887.00
e.disch_dt_tm between cnvtdatetime($STARTDATE) and cnvtdatetime($ENDDATE)
;e.disch_dt_tm between cnvtdatetime(cnvtdate(11022022),0) and cnvtdatetime(cnvtdate(11022022),2359)
join p
where e.person_id=p.person_id
join epr
where epr.encntr_id=e.encntr_id
and epr.encntr_prsnl_r_cd=1119
and epr.active_ind=1
join pr
where pr.person_id = epr.prsnl_person_id
join o
where o.encntr_id=e.encntr_id
and o.catalog_cd=    3224545.00;	Discharge Patient
and o.active_ind=1
join oa
where oa.order_id=o.order_id
and oa.action_type_cd=2534

join opr
where opr.person_id=oa.order_provider_id
join ea
where ea.encntr_id = e.encntr_id
and ea.encntr_alias_type_cd=1077
and ea.active_ind=1
 head report
  cnt = 0
 
 head e.encntr_id
 cnt =cnt  + 1
 ; if(mod(cnt,100) = 1)
    stat = alterlist(pft->data,cnt+99)
 ; endif
 
	
	pft->data[cnt].encntr_id     = e.encntr_id
	pft->data[cnt].FIN     = ea.alias
	pft->data[cnt].discharge_dt_tm =e.disch_dt_tm ;"@SHORTDATETIME"
	pft->data[cnt].Discharge_order = "Yes"
	pft->data[cnt].order_provider =opr.name_full_formatted
	pft->data[cnt].order_prov_id =opr.person_id
	pft->data[cnt].Patient_DOB =p.birth_dt_tm
	pft->data[cnt].PatientName =p.name_full_formatted
	pft->data[cnt].time_diff =timestampdiff(e.disch_dt_tm,o.orig_order_dt_tm)
	pft->data[cnt].attending_phy =pr.name_full_formatted
	
	pft->data[cnt].disch_disposition = trim(uar_get_code_display(e.disch_disposition_cd))
	;pft->data[cnt].fin = ea.alias
	
	
	foot report
  stat = alterlist(pft->data,cnt)
 ; pft->data = cnt
 
 with nocounter
 
 
 /**************************************************************
; Member Information
**************************************************************/
 select  into 'nl:'

 from 
  (dummyt   d1  with seq = size(pft->data,5)),
prsnl pr,
prsnl_group pg,
prsnl_group_reltn pgr

plan d1
 
join pr
where pr.person_id=pft->data[d1.seq].order_prov_id
join pgr
where pgr.person_id=pr.person_id
join pg
where pg.prsnl_group_id =pgr.prsnl_group_id; pg.prsnl_group_class_cd=      11156.00
 and pg.prsnl_group_name_key like "KAISER*"
 
 detail
 if (pg.prsnl_group_name_key like "KAISER*")
     		pft->data[d1.seq].Kp_group = "Yes"
;     		else
;     		pft->data[d1.seq].Kp_group ="No"
     		endif
 
   with nocounter
  
   
   ;Display results
   select into $outdev
   Name = pft->data[d1.seq].PatientName
,   DOB = pft->data[d1.seq].Patient_DOB "mm/dd/yyyy ;;d"
,   Physician_Attending = pft->data[d1.seq].attending_phy
,   Order_provider = pft->data[d1.seq].order_provider
,   Discharge_dt_tm = pft->data[d1.seq].discharge_dt_tm "mm/dd/yyyy hh:mm;;d"
,   Discharge_disposition = pft->data[d1.seq].disch_disposition
,   FIN = pft->data[d1.seq].FIN
,   Time_bw_disch_order = pft->data[d1.seq].time_diff/3600
,   Kaiser_provider = pft->data[d1.seq].Kp_group

   
  from 
  (dummyt   d1  with seq = size(pft->data,5))
 with nocounter ,separator=" ",format
  ;WITH NOCOUNTER, SEPARATOR=" ", FORMAT, PCFORMAT('"',',',1,0), FORMAT = CRSTREAM

end
go
 
