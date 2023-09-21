drop program avh_racial_demog_rpt go
create program avh_racial_demog_rpt
 
prompt
	"Output to File/Printer/MINE" = "MINE"    ;* Enter or select the printer or file name to send this report to.
	, "Admit Period Start Date" = "SYSDATE"
	, "Admit Period End Date" = "SYSDATE"
 
with OUTDEV, sdt, edt
 
 
 
/**************************************************************
; Record Structure
**************************************************************/
  record pr(
   1 e[*]
    2 person_id  = f8
    2 encntr_id  = f8
    2 mrn        = vc
    2 pt_name    = vc
    2 fin        = vc
    2 type       = vc
    2 dos        = vc
    2 race       = vc
    2 person_race = vc
  )
 
/**************************************************************
; Declared Variables
**************************************************************/
  declare rtxt = vc
  declare ntxt = vc
 
/**************************************************************
; Data - Patients for reported period
**************************************************************/
  select into "nl:"
  from encounter e
      ,person p
      ,encntr_alias eaf
      ,encntr_alias eam
 
  plan e where e.reg_dt_tm between cnvtdatetime($sdt)
                               and cnvtdatetime($edt)
           and e.active_ind = 1
           and e.encntr_type_cd in (     309310.0;	Emergency
                                    ,    309308.0;	Inpatient
                                    ,    309312.0;	Observation
                                    ,  19962820.0;	Outpatient in a Bed
                                    )
 
 
  join p where p.person_id = e.person_id
           and p.active_ind = 1
           and p.race_cd =    23274729.00 ; MULTIPLE
 
  join eaf where eaf.encntr_id = e.encntr_id
             and eaf.encntr_alias_type_cd = 1077.0
             and eaf.active_ind = 1
 
  join eam where eam.encntr_id = e.encntr_id
             and eam.encntr_alias_type_cd = 1079.0
             and eam.active_ind = 1
 
  order by e.encntr_id
 
  head report
   ecnt = 0
 
  head e.encntr_id
   ecnt = ecnt + 1, stat = alterlist(pr->e, ecnt)
   pr->e[ecnt].encntr_id = e.encntr_id
   pr->e[ecnt].person_id = e.person_id
   pr->e[ecnt].pt_name   = p.name_full_formatted
   pr->e[ecnt].fin       = eaf.alias
   pr->e[ecnt].mrn       = eam.alias
   pr->e[ecnt].dos       = build(format(e.reg_dt_tm,"mm/dd/yyyy;;d"), "-", format(e.disch_dt_tm,"mm/dd/yyyy;;d"))
   pr->e[ecnt].type      = uar_get_code_display(e.encntr_type_cd)
   pr->e[ecnt].person_race = uar_get_code_display(p.race_cd)
  with nocounter
 
/******************************************************************
; Data - Patient Race Values where multiple values were recorded
*******************************************************************/
 select into "nl:"
  encntr_id = pr->e[d1.seq].encntr_id
 from (dummyt d1 with seq = size(pr->e,5))
      ,person_code_value_r pr
 
 plan d1
 join pr where pr.person_id = pr->e[d1.seq].person_id
           and pr.code_set = 282.0 ; race code set
           and pr.code_value > 0.0
           and pr.active_ind = 1
 
 order by encntr_id, pr.code_value
 
 head encntr_id
  rtxt = ntxt ; null result
 
 detail
 
  if(rtxt > " ")
    rtxt = concat(rtxt,", ",uar_get_code_display(pr.code_value))
  else
    rtxt = uar_get_code_display(pr.code_value)
  endif
 
 foot encntr_id
  pr->e[d1.seq].race = rtxt
 
 with nocounter
 
 
/**************************************************************
; Output
**************************************************************/
 
 
  select into $outdev
   MRN          = substring(1, 15,pr->e[d1.seq].mrn)
  ,PATIENT_NAME = substring(1,100,pr->e[d1.seq].pt_name)
  ,FIN          = substring(1, 15,pr->e[d1.seq].fin)
  ,TYPE         = substring(1, 30,pr->e[d1.seq].type)
  ,DOS          = substring(1, 30,pr->e[d1.seq].dos)
  ,PERSON_RACE  = substring(1, 30,pr->e[d1.seq].person_race)
  ,PATIENT_RACE = substring(1,150,pr->e[d1.seq].race)
 
  from (dummyt d1 with seq = size(pr->e,5))
 
  plan d1
 
  order by type, dos
  with format, separator = " "
/**************************************************************
; DVDev DEFINED SUBROUTINES
**************************************************************/
 
end
go
 
