/*********************************************************************************************************************************
  Report Name:
  Script Name: avh_birth_log_book_extract
  Source Code: cust_script:avh_birth_log_book_extract.prg
  Created By:Shruthi R
  Requestor: Betty Price
 
 
  Program Description:
 
  Set up the report to send on the first of every month to Yvonne Reifenstahl and Devon Cons.
 
Mother's Name
EGA
Baby MRN
Baby's Date of Birth
Neonate Outcome
Baby's Sex
Birth Weight
 
  Path:
 
**********************************************************************************************************************************
                      GENERATED MODIFICATION CONTROL LOG
**********************************************************************************************************************************
  Mod| Date     | Programmer    |  Issue / Req#  |  Comment
  ---| -------- | ------------- | -------------  | ----------------------------------------------------------------------------- *
  000| 09/15/22 | sraamaavh       | CHN-1193      | Initial release                                                               *
**********************************************************************************************************************************/
DROP PROGRAM avh_birth_log_book_extract :dba GO
CREATE PROGRAM avh_birth_log_book_extract :dba
 prompt 
	"Output to File/Printer/MINE" = "MINE"   ;* Enter or select the printer or file name to send this report to.
	, "Start Date" = "CURDATE"
	, "End Date" = "CURDATE"
	, "Organization" = 0
	, "OPS Job" = "NO" 

with OUTDEV, sdate, edate, Org, OPS
 
%i cust_script:avh_mail_routine.inc
 IF (NOT (validate (reply ,0 ) ) )
  RECORD reply (
    1 status_data
      2 status = c1
      2 subeventstatus [1 ]
        3 operationname = c25
        3 operationstatus = c1
        3 targetobjectname = c25
        3 targetobjectvalue = vc
  )
 ENDIF
 DECLARE sdate = vc WITH noconstant (" " )
 DECLARE edate = vc WITH noconstant (" " )
 DECLARE stime = vc WITH noconstant (" " )
 DECLARE etime = vc WITH noconstant (" " )
 DECLARE e_date_range = vc WITH protect ,noconstant
 DECLARE e_org = vc WITH protect ,noconstant
 DECLARE e_print = vc WITH protect ,noconstant
 IF (( $2 IN ("*CURDATE*" ) ) )
  DECLARE _dq8 = dq8 WITH noconstant ,private
  DECLARE _parse = vc WITH constant (concat ("set _dq8 = cnvtdatetime(" , $2 ,", 0) go" ) ) ,private
  CALL parser (_parse )
  DECLARE sdatetime = vc WITH protect ,constant (format (_dq8 ,"DD-MMM-YYYY;;D" ) )
 ELSE
  DECLARE sdatetime = vc WITH protect ,constant ( $2 )
 ENDIF
 IF (( $3 IN ("*CURDATE*" ) ) )
  DECLARE _dq8 = dq8 WITH noconstant ,private
  DECLARE _parse2 = vc WITH constant (concat ("set _dq8 = cnvtdatetime(" , $3 ,", 235959) go" ) ) ,
  private
  CALL parser (_parse2 )
  DECLARE edatetime = vc WITH protect ,constant (format (_dq8 ,"DD-MMM-YYYY HH:MM;;Q" ) )
  DECLARE ledatetime = vc WITH protect ,constant (format (_dq8 ,"DD-MMM-YYYY;;D" ) )
 ELSE
  DECLARE edatetime = vc WITH protect ,constant (concat (trim ( $3 ) ," 23:59:59" ) )
  DECLARE ledatetime = vc WITH protect ,constant ( $3 )
 ENDIF
 DECLARE e_idx = i4 WITH protect ,noconstant (0 )
 DECLARE lac_temp_date = dq8
 DECLARE epis_temp_date = dq8
 DECLARE all_orgs_flag = i4
 DECLARE fetch_records_based_dt_tm = dq8
 DECLARE auth = f8 WITH public ,constant (uar_get_code_by_cki ("CKI.CODEVALUE!2628" ) )
 DECLARE modified = f8 WITH public ,constant (uar_get_code_by_cki ("CKI.CODEVALUE!2636" ) )
 DECLARE altered = f8 WITH public ,constant (uar_get_code_by_cki ("CKI.CODEVALUE!16901" ) )
 DECLARE lactive = f8 WITH public ,noconstant (uar_get_code_by_cki ("CKI.CODEVALUE!12609392" ) )
 DECLARE linactive = f8 WITH public ,noconstant (uar_get_code_by_cki ("CKI.CODEVALUE!12609393" ) )
 DECLARE linerror = f8 WITH public ,noconstant (uar_get_code_by_cki ("CKI.CODEVALUE!12609394" ) )
 DECLARE pactive = f8 WITH public ,constant (uar_get_code_by_cki ("CKI.CODEVALUE!3465" ) )
 DECLARE mrn_cd = f8 WITH protect ,constant (uar_get_code_by ("MEANING" ,319 ,"MRN" ) )
 DECLARE pmrn_cd = f8 WITH public ,constant (uar_get_code_by_cki ("CKI.CODEVALUE!2623" ) )
 DECLARE cki_newborn_enc = f8 WITH public ,constant (uar_get_code_by_cki ("CKI.CODEVALUE!723871538"
   ) )
 DECLARE cki_mother = f8 WITH public ,constant (uar_get_code_by_cki ("CKI.CODEVALUE!3233" ) )
 DECLARE vloc = vc WITH public ,noconstant (" " )
 DECLARE event_found_ind = i4 WITH public ,noconstant (0 )
 DECLARE cs_t_inc = f8 WITH public ,constant (uar_get_code_by_cki ("CKI.CODEVALUE!12610764" ) )
 DECLARE cs_low_vertl = f8 WITH public ,constant (uar_get_code_by_cki ("CKI.CODEVALUE!12610762" ) )
 DECLARE cs_low_tran = f8 WITH public ,constant (uar_get_code_by_cki ("CKI.CODEVALUE!12610747" ) )
 DECLARE cs_j_inc = f8 WITH public ,constant (uar_get_code_by_cki ("CKI.CODEVALUE!4100275822" ) )
 DECLARE cs = f8 WITH public ,constant (uar_get_code_by_cki ("CKI.CODEVALUE!12610746" ) )
 DECLARE cs_class = f8 WITH public ,constant (uar_get_code_by_cki ("CKI.CODEVALUE!12610763" ) )
 DECLARE cs_vac_assist = f8 WITH public ,constant (uar_get_code_by_cki ("CKI.CODEVALUE!4100275825" )
  )
 DECLARE cs_unknown = f8 WITH public ,constant (uar_get_code_by_cki ("CKI.CODEVALUE!4100275827" ) )
 DECLARE cs_other = f8 WITH public ,constant (uar_get_code_by_cki ("CKI.CODEVALUE!4100275826" ) )
 DECLARE cs_frcp_vac = f8 WITH public ,constant (uar_get_code_by_cki ("CKI.CODEVALUE!4100275823" ) )
 DECLARE cs_frcp = f8 WITH public ,constant (uar_get_code_by_cki ("CKI.CODEVALUE!4100275824" ) )
 DECLARE tob_use_per_day = f8 WITH public ,constant (uar_get_code_by_cki ("CKI.EC!7014" ) )
 DECLARE tob_last_use = f8 WITH public ,constant (uar_get_code_by_cki ("CKI.EC!6984" ) )
 DECLARE obgyn_cd = f8 WITH public ,constant (uar_get_code_by_cki ("CKI.CODEVALUE!4591" ) )
 DECLARE assistant_physician_1_cki = vc WITH public ,constant ("CKI.EC!14996" )
 DECLARE assistant_physician_2_cki = vc WITH public ,constant ("CKI.EC!14833" )
 DECLARE delivery_rn_1_cki = vc WITH public ,constant ("CKI.EC!14834" )
 DECLARE delivery_rn_2_cki = vc WITH public ,constant ("CKI.EC!14835" )
 DECLARE rom_to_delivery_hours_calc = vc WITH public ,constant (
  "CERNER!7DB3D314-2095-485D-98B9-7E14FA4A1E5F" )
 DECLARE rom_dt_tm = vc WITH public ,constant ("CERNER!17A18CD6-CA24-4AC2-B80B-27B61A62D253" )
 DECLARE rom_type = vc WITH public ,constant ("CERNER!09694B26-1FE7-47DF-AD29-9B673968D64E" )
 DECLARE augmentation_methods = vc WITH public ,constant (
  "CERNER!6B69F0FC-5514-40A1-BBE4-EF20AAF35BE0" )
 DECLARE date_time_of_birth = vc WITH public ,constant ("CERNER!ASYr9AEYvUr1YoPTCqIGfQ" )
 DECLARE delivery_type = vc WITH public ,constant ("CERNER!0B07155E-2E5C-461F-ADE6-CB5768257107" )
 DECLARE neonate_outcome = vc WITH public ,constant ("CERNER!ASYr9AEYvUr1YoRACqIGfQ" )
 DECLARE placenta_delivery_date_time = vc WITH public ,constant (
  "CERNER!DBCD00BD-E56D-4987-BDE4-FA7D0BA9449C" )
 DECLARE gender = vc WITH public ,constant ("CERNER!ASYr9AEYvUr1YoQ0CqIGfQ" )
 DECLARE birth_weight = vc WITH public ,constant ("CERNER!ASYr9AEYvUr1YoRMCqIGfQ" )
 DECLARE apgar_score_1_minute = vc WITH public ,constant (
  "CERNER!B6EDB709-4DB0-4718-B897-E198850FEA3E" )
 DECLARE apgar_score_10_minute = vc WITH public ,constant (
  "CERNER!9900D029-8186-45D9-B9C6-49594E976ED2" )
 DECLARE apgar_score_15_minute = vc WITH public ,constant (
  "CERNER!B48BBCD8-68FE-40A2-9438-F158CD0CAF7F" )
 DECLARE apgar_score_20_minute = vc WITH public ,constant (
  "CERNER!98807D2C-601B-4B4C-A685-68ACE052748C" )
 DECLARE apgar_score_5_minute = vc WITH public ,constant (
  "CERNER!A1EEDCA0-DD0B-4A6B-9381-E7492D5409B1" )
 DECLARE fhr_monitoring_method = vc WITH public ,constant (
  "CERNER!5F5D6B1C-C75E-48A7-A1A5-672942D2AD06" )
 DECLARE neonate_complications = vc WITH public ,constant (
  "CERNER!07B2090C-7AE6-4E14-A702-C20EE3E7D4FD" )
 DECLARE risk_factors = vc WITH public ,constant ("CERNER!28CD17AC-F1BD-4AE3-A9F6-1282F19618AB" )
 DECLARE amniotic_fluid_color_description = vc WITH public ,constant (
  "CERNER!2271786D-245C-448C-BD01-9D6AE23FA313" )
 DECLARE delivery_physician = vc WITH public ,constant (
  "CERNER!148D82CA-6CCA-437C-818A-FC0BDE22EF2F" )
 DECLARE assistant_physician_2 = vc WITH public ,constant (
  "CERNER!F585EADF-7F01-46CD-8D43-1C7B01C17592" )
 DECLARE assistant_physician_1 = vc WITH public ,constant (
  "CERNER!F585EADF-7F01-46CD-8D43-1C7B01C17592" )
 DECLARE attending_physician = vc WITH public ,constant (
  "CERNER!B5FCA4F5-DCAC-4CF8-A3E2-941C08D8B725" )
 DECLARE pediatrician = vc WITH public ,constant ("CERNER!ABEA0D57-6F36-4252-9338-C33C70C69978" )
 DECLARE delivery_rn_2 = vc WITH public ,constant ("CERNER!7DC28206-7A88-4CC1-B53E-1C5C33DF9B9D" )
 DECLARE delivery_rn_1 = vc WITH public ,constant ("CERNER!7DC28206-7A88-4CC1-B53E-1C5C33DF9B9D" )
 DECLARE resuscitation_rn_1 = vc WITH public ,constant (
  "CERNER!D216FB18-2E6A-4341-A200-D22811FDEC58" )
 DECLARE transfer_to_from = vc WITH public ,constant ("CERNER!05AADF41-79E7-4B96-A18F-5FC059CC280E"
  )
 DECLARE cord_blood_banking = vc WITH public ,constant (
  "CERNER!D3E1CBEF-1595-4431-8F8F-8E1B05D71AE6" )
 DECLARE labor_onset_dt_tm = vc WITH public ,constant ("CERNER!148690D8-2679-435F-AEE3-D5F7E601E4E0"
  )
 DECLARE 2nd_stage_onset_dt_tm = vc WITH public ,constant (
  "CERNER!1DA608D8-5D02-4BE1-BE5C-76D179E37BBF" )
 DECLARE 3nd_stage_onset_dt_tm = vc WITH public ,constant (
  "CERNER!0EBA50DA-7FF6-4FB5-B70F-BEBC66378469" )
 DECLARE cord_blood_ph_drawn = vc WITH public ,constant (
  "CERNER!00B16C8B-7AB3-4E46-A569-CA61275B4416" )
 DECLARE id_band_num = vc WITH public ,constant ("CERNER!5826042F-7D11-4365-8F0A-63862BABB4AC" )
 DECLARE indications_for_induction = vc WITH public ,constant (
  "CERNER!DCFA6EC4-8DB5-4EDB-B519-DC1E2BF3BBB4" )
 DECLARE risk_factors_antepartum_current_preg = vc WITH public ,constant (
  "CERNER!534FEBB4-232A-4824-9A5E-2DF5FC22A3E6" )
 DECLARE anesthesiologist_attending_delivery = vc WITH public ,constant (
  "CERNER!676B955C-EB41-4E5D-A847-08914BAD33AE" )
 DECLARE anesthetist = vc WITH public ,constant ("CERNER!239377AD-E73F-4863-B341-D791662E4E2D" )
 DECLARE induction_methods = vc WITH public ,constant ("CERNER!4D713327-956D-46E5-893B-8DAFA44336FE"
  )
 DECLARE labial_laceration = vc WITH public ,constant ("CERNER!8CC89133-CAE8-4D22-AF0E-CE133E62B105"
  )
 DECLARE perineum_vaginal_laceration = vc WITH public ,constant (
  "CERNER!1F964DAE-0971-46AA-B38C-B7710C1159D0" )
 DECLARE perineum_superficial_abrasion_laceration = vc WITH public ,constant (
  "CERNER!6E9C03CA-CC3D-4D8E-BF6C-8B42A007083A" )
 DECLARE perineum_periurethral_laceration = vc WITH public ,constant (
  "CERNER!F7BB6E59-D0EE-466B-AAAA-1524FDF7FBDC" )
 DECLARE perineum_perineal_laceration = vc WITH public ,constant (
  "CERNER!6DEBAC89-5A20-4074-9698-EAD6A4E4ED0D" )
 DECLARE perineum_cervical_laceration = vc WITH public ,constant (
  "CERNER!12448C7B-1C76-4D14-8F4A-2370708B1040" )
 DECLARE perineum_intact = vc WITH public ,constant ("CERNER!D344529E-FBC5-4E8D-99E1-C6195274F252" )
 DECLARE episiotomy_other_information = vc WITH public ,constant (
  "CERNER!919A00D1-41C2-4717-99E5-1D7147DF69A8" )
 DECLARE episiotomy_performed = vc WITH public ,constant (
  "CERNER!155683DF-B118-4C15-B603-B750F3A6515F" )
 DECLARE episiotomy_mediolateral = vc WITH public ,constant (
  "CERNER!D4413143-8122-45C7-BFB6-21608DAF7A1B" )
 DECLARE episiotomy_midline = vc WITH public ,constant (
  "CERNER!1DD6481D-40C0-471C-8516-F8EE19469897" )
 DECLARE episiotomy_degree = vc WITH public ,constant ("CERNER!93130FE6-0444-4DE2-90C4-DE2CD6A00493"
  )
 DECLARE gravida = vc WITH public ,constant ("CERNER!AEO/PQD7LLZ5Xf6zn4waeg" )
 DECLARE para_full_term = vc WITH public ,constant ("CERNER!AVdLiAEMseBG5YDhCqIGfQ" )
 DECLARE para_premature = vc WITH public ,constant ("CERNER!AVdLiAEMseBG5YDtCqIGfQ" )
 DECLARE aborh = vc WITH public ,constant ("CERNER!AeXiwwEJc7Lb7IGDCqk/Mw" )
 DECLARE reason_for_csection = vc WITH public ,constant (
  "CERNER!7963B3E1-0F6C-40A0-AA21-4D57220CF9AE" )
 DECLARE anesthesia_type_ob = vc WITH public ,constant ("CERNER!ASYr9AEYvUr1YoPECqIGfQ" )
 DECLARE uterine_contraction_monitoring_method = vc WITH public ,constant (
  "CERNER!CE2B6444-EF47-4242-974B-E3568B4EDA6A" )
 DECLARE pediatrician_selected = vc WITH public ,constant (
  "CERNER!D6247C7E-22A4-465F-8C16-98832D8A3968" )
 DECLARE maternal_delivery_complications = vc WITH public ,constant (
  "CERNER!2D13D00F-BFD4-44DA-BFC3-73392A695B93" )
 DECLARE infant_feeding = vc WITH public ,constant ("CERNER!67FD02F4-5BA3-4EF2-9E3D-16CEB449F5EC" )
 DECLARE presenting_part = vc WITH public ,constant ("CERNER!5E8EA222-CDC3-4297-B9CA-06165BB8FB69" )
 DECLARE transferred_to = vc WITH public ,constant ("CERNER!73F036A3-D3EB-46F8-8A58-47EA59F2DE1A" )
 DECLARE estimated_blood_loss = vc WITH public ,constant (
  "CERNER!756174DA-A629-49DD-BDC9-29AA32BF9D0F" )
 DECLARE g_cd = f8 WITH public ,constant (uar_get_code_by_cki ("CKI.CODEVALUE!6123" ) )
 DECLARE kg_cd = f8 WITH public ,constant (uar_get_code_by_cki ("CKI.CODEVALUE!2751" ) )
 DECLARE lb_cd = f8 WITH public ,constant (uar_get_code_by_cki ("CKI.CODEVALUE!2746" ) )
 DECLARE sscript_name = vc WITH protect ,constant ("PCM_BIRTH_LOG_BOOK_EXTRACT" )
 DECLARE errmsg = c132 WITH protect ,noconstant (fillstring (132 ," " ) )
 DECLARE error_check = i2 WITH protect ,noconstant (error (errmsg ,1 ) )
 DECLARE shx_code_set = i4 WITH protect ,constant (14003 )
 DECLARE e_int = i4 WITH public ,noconstant (0 )
 DECLARE org_int = i4 WITH public ,noconstant (0 )
 DECLARE actual_size = i4 WITH public
 DECLARE expand_size = i4 WITH public ,constant (200 )
 DECLARE expand_total = i4 WITH public
 DECLARE expand_start = i4 WITH public
 DECLARE expand_stop = i4 WITH public
 DECLARE expand_num = i4 WITH public
 DECLARE shx_exists = i4 WITH public ,noconstant (0 )
 DECLARE get_pregnancy_model_data (null ) = null
 DECLARE get_event_codes (null ) = null
 DECLARE get_ce_model_data (null ) = null
 DECLARE get_header (null ) = null
 DECLARE get_mother_mrn (null ) = null
 DECLARE load_birth_log_rec (null ) = null
 DECLARE get_mother_mrn (null ) = null
 DECLARE get_mother_demographic (null ) = null
 DECLARE get_mother_diagnosis (null ) = null
 DECLARE get_location_history (null ) = null
 DECLARE get_patient_ega (null ) = null
 DECLARE get_baby_mrn (null ) = null
 DECLARE get_tobacco_shx (null ) = null
 DECLARE get_tobacco_ce (null ) = null
 FREE RECORD birth_log
 RECORD birth_log (
   1 tot_mother_del = i4
   1 tot_baby_del = i4
   1 tot_vag = i4
   1 tot_csect = i4
   1 tot_unspec_del = i4
   1 start_date = vc
   1 end_date = vc
   1 organization = c30
   1 location = f8
   1 print_user = vc
   1 rec [* ]
     2 extract_out = vc
     2 extract_out1 = vc
     2 extract_out2 = vc
     2 extract_out3 = vc
     2 encntr_id = f8
     2 print_ind = i4
     2 baby_1_dt_tm = dq8
     2 amniotic_desc = vc
     2 person_id = f8
     2 mother_name = vc
     2 mother_age = vc
     2 mother_reg_dt = vc
     2 mother_reg_tm = vc
     2 mother_disch_dt_tm = vc
     2 mother_mrn = vc
     2 ega = vc
     2 g = vc
     2 p_full_term = vc
     2 p_pre_term = vc
     2 aborh = vc
     2 anesth_type = vc
     2 uc_mon = vc
     2 mother_to = vc
     2 induct_ind = vc
     2 mat_compl = vc
     2 labial_lac = vc
     2 episiotomy = vc
     2 laceration = vc
     2 pregnancy_id = f8
     2 active_preg_ind = i4
     2 prev_csec_ind = i4
     2 race = vc
     2 ethnicity =c100;SR150201
     2 tobacco_use = vc
     2 tobacco_amt = vc
     2 tobacco_dt_tm = dq8
     2 feeding_method = vc
     2 location = vc
     2 diagnosis = vc
     2 est_blood_loss = vc
     2 pediatrician = vc
     2 labor_room = vc
     2 postpart_room = vc
     2 mother_to_dq = dq8
     2 mother_obgyn = vc
     2 presenting_part = vc
     2 neo_prov = vc
     2 labor_onset_dt_tm = vc
     2 preg_risk_factors = vc
     2 baby [* ]
       3 person_id = f8
       3 id = vc
       3 brth_dt_tm = vc
       3 brth_dt_tm_dq = dq8
       3 event_id = f8
       3 sex = vc
       3 birth_wt = vc
       3 rom_del = vc
       3 rom_dt_tm = vc
       3 ind_meth = vc
       3 aug_meth = vc
       3 del_type = vc
       3 cs_ind = vc
       3 neo_outcome = vc
       3 placenta_dt_tm = vc
       3 apgar_1min = vc
       3 apgar_5min = vc
       3 apgar_10min = vc
       3 apgar_15min = vc
       3 apgar_20min = vc
       3 fhr_mon = vc
       3 del_prov = vc
       3 del_cnm = vc
       3 scrub_tech = vc
       3 other_del_clin = vc
       3 neo_prov = vc
       3 resus_md = vc
       3 resus_prov = vc
       3 trans_to = vc
       3 birth_compl = vc
       3 risk_factors = vc
       3 asst_phys_1 = vc
       3 asst_phys_2 = vc
       3 attn_phys = vc
       3 del_rn_1 = vc
       3 del_rn_2 = vc
       3 resus_rn_1 = vc
       3 baby_to = vc
       3 placenta_desc = vc
       3 neo_compl = vc
       3 cord_blood_banking = vc
       3 labor_onset_dt_tm = vc
       3 labor_onset_dt_tm_dq = dq8
       3 2nd_stage_onset_dt_tm = vc
       3 3nd_stage_onset_dt_tm = vc
       3 cord_blood_ph = vc
       3 baby_mrn = vc
       3 rom_type = vc
       3 mat_compl = vc
       3 pediatrician = vc
       3 newborn_feeding = vc
       3 anesthetist = vc
       3 anesthesiologist = vc
 )
 FREE RECORD preg_data_model
 RECORD preg_data_model (
   1 num_valid_deliv = i4
   1 mother [* ]
     2 person_id = f8
     2 pregnancy_id = f8
     2 preg_start_dt_tm = dq8
     2 preg_end_dt_tm = dq8
     2 mat_compl = vc
     2 prev_csec_ind = i4
     2 date_range_ind = i4
     2 cs_ind = i4
     2 baby_1_dt_tm = dq8
     2 confirmed_dt_tm = dq8
     2 historical_ind = i4
     2 g = vc
     2 p_full_term = vc
     2 p_pre_term = vc
     2 delivery [* ]
       3 pregnancy_child_id = f8
       3 ega = vc
       3 person_id = f8
       3 gender = vc
       3 birth_dt_tm = dq8
       3 del_type = vc
       3 weight = vc
       3 anes_type = vc
       3 fetal_comp = vc
       3 neo_outcome = vc
       3 location = vc
 )
 FREE RECORD event_codes
 RECORD event_codes (
   1 rec [* ]
     2 event_cd = f8
 )
 FREE RECORD ce_data_model
 RECORD ce_data_model (
   1 mother [* ]
     2 person_id = f8
     2 encntr_id = f8
     2 loc_fac_cd = f8
     2 location = vc
     2 g = vc
     2 p_full_term = vc
     2 p_pre_term = vc
     2 aborh = vc
     2 mother_to = vc
     2 mother_to_dq = dq8
     2 anesth_type = vc
     2 feeding_method = vc
     2 est_blood_loss_uom = vc
     2 est_blood_loss = vc
     2 uc_mon = vc
     2 amniotic_desc = vc
     2 pediatrician = vc
     2 induct_ind = vc
     2 epis_degree = vc
     2 epis_midline = vc
     2 epis_medio = vc
     2 epis_performed = vc
     2 epis_oth_info = vc
     2 perin_intact = vc
     2 perin_cerv_lac = vc
     2 perin_perineal_lac = vc
     2 perin_periureth_lac = vc
     2 perin_sup_abr_lac = vc
     2 perin_vag_lac = vc
     2 labial_lac = vc
     2 episiotomy = vc
     2 laceration = vc
     2 baby_1_dt_tm = dq8
     2 prev_cs_ind = i2
     2 presenting_part = vc
     2 neo_prov = vc
     2 labor_onset_dt_tm = vc
     2 ega = vc
     2 organization_id = f8
     2 preg_risk_factors = vc
     2 preg_start_dt_tm = dq8
     2 preg_end_dt_tm = dq8
     2 delivery [* ]
       3 brth_dt_tm = vc
       3 brth_dt_tm_pm = vc
       3 brth_dt_tm_dq = dq8
       3 sex = vc
       3 birth_wt = vc
       3 rom_del = vc
       3 rom_dt_tm = vc
       3 ind_meth = vc
       3 aug_meth = vc
       3 del_type = vc
       3 cs_ind = vc
       3 neo_outcome = vc
       3 placenta_dt_tm = vc
       3 apgar_1min = vc
       3 apgar_5min = vc
       3 apgar_10min = vc
       3 apgar_15min = vc
       3 apgar_20min = vc
       3 fhr_mon = vc
       3 del_prov = vc
       3 baby_to = vc
       3 risk_factors = vc
       3 neo_prov = vc
       3 neo_compl = vc
       3 cord_blood_banking = vc
       3 labor_onset_dt_tm = vc
       3 2nd_stage_onset_dt_tm = vc
       3 3nd_stage_onset_dt_tm = vc
       3 attn_phys = vc
       3 cord_blood_ph = vc
       3 resus_rn_1 = vc
       3 asst_phys_1 = vc
       3 asst_phys_2 = vc
       3 del_rn_2 = vc
       3 del_rn_1 = vc
       3 id = vc
       3 rom_type = vc
       3 mat_compl = vc
       3 pediatrician = vc
       3 ega = vc
       3 anesthetist = vc
       3 anesthesiologist = vc
       3 g = vc
       3 p_full_term = vc
       3 p_pre_term = vc
       3 aborh = vc
       3 mother_to = vc
       3 mother_to_dq = dq8
       3 anesth_type = vc
       3 est_blood_loss = vc
       3 uc_mon = vc
       3 amniotic_desc = vc
       3 neo_prov = vc
       3 presenting_part = vc
       3 labor_onset_dt_tm = vc
       3 laceration = vc
       3 episiotomy = vc
       3 induct_ind = vc
 )
 FREE RECORD temp_delivery_model
 RECORD temp_delivery_model (
   1 delivery [* ]
     2 brth_dt_tm = vc
     2 brth_dt_tm_pm = vc
     2 brth_dt_tm_dq = dq8
     2 sex = vc
     2 birth_wt = vc
     2 rom_del = vc
     2 rom_dt_tm = vc
     2 ind_meth = vc
     2 aug_meth = vc
     2 del_type = vc
     2 cs_ind = vc
     2 neo_outcome = vc
     2 placenta_dt_tm = vc
     2 apgar_1min = vc
     2 apgar_5min = vc
     2 apgar_10min = vc
     2 apgar_15min = vc
     2 apgar_20min = vc
     2 fhr_mon = vc
     2 del_prov = vc
     2 baby_to = vc
     2 risk_factors = vc
     2 neo_prov = vc
     2 neo_compl = vc
     2 cord_blood_banking = vc
     2 labor_onset_dt_tm = vc
     2 2nd_stage_onset_dt_tm = vc
     2 3nd_stage_onset_dt_tm = vc
     2 attn_phys = vc
     2 cord_blood_ph = vc
     2 resus_rn_1 = vc
     2 asst_phys_1 = vc
     2 asst_phys_2 = vc
     2 del_rn_2 = vc
     2 del_rn_1 = vc
     2 id = vc
     2 rom_type = vc
     2 mat_compl = vc
     2 pediatrician = vc
     2 ega = vc
     2 anesthetist = vc
     2 anesthesiologist = vc
     2 g = vc
     2 p_full_term = vc
     2 p_pre_term = vc
     2 aborh = vc
     2 mother_to = vc
     2 mother_to_dq = dq8
     2 anesth_type = vc
     2 est_blood_loss = vc
     2 uc_mon = vc
     2 amniotic_desc = vc
     2 neo_prov = vc
     2 presenting_part = vc
     2 labor_onset_dt_tm = vc
     2 laceration = vc
     2 episiotomy = vc
     2 induct_ind = vc
 )
 FREE RECORD org
 RECORD org (
   1 rec [* ]
     2 code_value = f8
     2 display = vc
     2 description = vc
     2 organization_id = f8
   1 display = vc
   1 count = i4
 )
 FREE SET header
 RECORD header (
   1 name = vc
   1 years = vc
   1 admit_dt_tm = vc
   1 disch_dt_tm = vc
   1 mrn_id = vc
   1 age = vc
   1 ega = vc
   1 g = vc
   1 p_full = vc
   1 p_term = vc
   1 aborh = vc
   1 rom = vc
   1 rom_dt_tm = vc
   1 induction_ind = vc
   1 induction_method = vc
   1 aug_method = vc
   1 birth_dt_tm = vc
   1 del_type = vc
   1 cs_indications = vc
   1 anes_type = vc
   1 neo_outcome = vc
   1 epis = vc
   1 laceration = vc
   1 placenta_dt_tm = vc
   1 sex = vc
   1 weight = vc
   1 apgar_1 = vc
   1 apgar_5 = vc
   1 apgar_10 = vc
   1 apgar_15 = vc
   1 apgar_20 = vc
   1 fhr_mon = vc
   1 uc_mon = vc
   1 maternal_compl = vc
   1 neonate_comp = vc
   1 risk_factors = vc
   1 amniotic_desc = vc
   1 del_prov = vc
   1 del_rn_1 = vc
   1 del_rn_2 = vc
   1 neo_prov = vc
   1 resus_rn_1 = vc
   1 asst_phys_1 = vc
   1 asst_phys_2 = vc
   1 attn_phys = vc
   1 ped = vc
   1 baby_to = vc
   1 mother_to = vc
   1 race = vc
   1 ethnicity =c100 ;SR150201
   1 tobac_use = vc
   1 tobac_amt = vc
   1 feed_method = vc
   1 location = vc
   1 diagnosis = vc
   1 ebl = vc
   1 cbb = vc
   1 present_part = vc
   1 lab_onset_dt_tm = vc
   1 2nd_onset_dt_tm = vc
   1 3rd_onset_dt_tm = vc
   1 no_deliv = vc
   1 report_title = vc
   1 date_range = vc
   1 printed_by = vc
   1 org = vc
   1 cord_blood_ph = vc
   1 baby_mrn = vc
   1 rom_type = vc
   1 labor_room = vc
   1 postpart_room = vc
   1 previous_cs = vc
   1 preg_risk_factors = vc
   1 anesthetist = vc
   1 anesthesiologist = vc
 )
 FREE RECORD ega_request
 RECORD ega_request (
   1 patient_list [* ]
     2 patient_id = f8
     2 encntr_id = f8
   1 pregnancy_list [* ]
     2 pregnancy_id = f8
   1 multiple_egas = i2
   1 provider_list [* ]
     2 patient_id = f8
     2 encntr_id = f8
     2 provider_patient_reltn_cd = f8
   1 provider_id = f8
   1 position_cd = f8
   1 cal_ega_multiple_gest = i2
 )
 FREE RECORD ex_out
 RECORD ex_out (
   1 rec [* ]
     2 name = vc
     2 admit_dt_tm = vc
     2 disch_dt_tm = vc
     2 mrn_id = vc
     2 age = vc
     2 ega = vc
     2 g = vc
     2 p_full = vc
     2 p_term = vc
     2 aborh = vc
     2 rom = vc
     2 rom_type = vc
     2 rom_dt_tm = vc
     2 induction_ind = vc
     2 induction_method = vc
     2 aug_method = vc
     2 birth_dt_tm = vc
     2 del_type = vc
     2 cs_indications = vc
     2 anes_type = vc
     2 neo_outcome = vc
     2 epis = vc
     2 laceration = vc
     2 placenta_dt_tm = vc
     2 sex = vc
     2 weight = vc
     2 apgar_1 = vc
     2 apgar_5 = vc
     2 apgar_10 = vc
     2 apgar_15 = vc
     2 apgar_20 = vc
     2 fhr_mon = vc
     2 uc_mon = vc
     2 maternal_compl = vc
     2 neonate_comp = vc
     2 risk_factors = vc
     2 amniotic_desc = vc
     2 del_prov = vc
     2 asst_phys_1 = vc
     2 asst_phys_2 = vc
     2 attn_phys = vc
     2 ped = vc
     2 del_rn_1 = vc
     2 del_rn_2 = vc
     2 neo_prov = vc
     2 resus_rn_1 = vc
     2 baby_to = vc
     2 mother_to = vc
     2 race = vc
     2 ethnicity =c100 ;SR150201
     2 tobac_use = vc
     2 tobac_amt = vc
     2 feed_method = vc
     2 location = vc
     2 diagnosis = vc
     2 ebl = vc
     2 cbb = vc
     2 present_part = vc
     2 lab_onset_dt_tm = vc
     2 2nd_onset_dt_tm = vc
     2 3rd_onset_dt_tm = vc
     2 cord_blood_ph = vc
     2 baby_mrn = vc
     2 labor_room = vc
     2 postpart_room = vc
     2 previous_cs = vc
     2 preg_risk_factors = vc
     2 anesthetist = vc
     2 anesthesiologist = vc
 )
 IF ((validate (i18nuar_def ,999 ) = 999 ) )
  CALL echo ("Declaring i18nuar_def" )
  DECLARE i18nuar_def = i2 WITH persist
  SET i18nuar_def = 1
  DECLARE uar_i18nlocalizationinit ((p1 = i4 ) ,(p2 = vc ) ,(p3 = vc ) ,(p4 = f8 ) ) = i4 WITH
  persist
  DECLARE uar_i18ngetmessage ((p1 = i4 ) ,(p2 = vc ) ,(p3 = vc ) ) = vc WITH persist
  DECLARE uar_i18nbuildmessage () = vc WITH persist
  DECLARE uar_i18ngethijridate ((imonth = i2 (val ) ) ,(iday = i2 (val ) ) ,(iyear = i2 (val ) ) ,(
   sdateformattype = vc (ref ) ) ) = c50 WITH image_axp = "shri18nuar" ,image_aix =
  "libi18n_locale.a(libi18n_locale.o)" ,uar = "uar_i18nGetHijriDate" ,persist
  DECLARE uar_i18nbuildfullformatname ((sfirst = vc (ref ) ) ,(slast = vc (ref ) ) ,(smiddle = vc (
    ref ) ) ,(sdegree = vc (ref ) ) ,(stitle = vc (ref ) ) ,(sprefix = vc (ref ) ) ,(ssuffix = vc (
    ref ) ) ,(sinitials = vc (ref ) ) ,(soriginal = vc (ref ) ) ) = c250 WITH image_axp =
  "shri18nuar" ,image_aix = "libi18n_locale.a(libi18n_locale.o)" ,uar = "i18nBuildFullFormatName" ,
  persist
  DECLARE uar_i18ngetarabictime ((ctime = vc (ref ) ) ) = c20 WITH image_axp = "shri18nuar" ,
  image_aix = "libi18n_locale.a(libi18n_locale.o)" ,uar = "i18n_GetArabicTime" ,persist
 ENDIF
 SET i18nhandle = 0
 SET h = uar_i18nlocalizationinit (i18nhandle ,curprog ,"" ,curcclrev )
 SET header->name = uar_i18ngetmessage (i18nhandle ,"header1" ,"Name(Mother)" )
 SET header->admit_dt_tm = uar_i18ngetmessage (i18nhandle ,"header2" ,"Admit_Date/Time" )
 SET header->disch_dt_tm = uar_i18ngetmessage (i18nhandle ,"header2_3" ,"Discharge_Date/Time" )
 SET header->mrn_id = uar_i18ngetmessage (i18nhandle ,"header3" ,"MRN/ID_Number" )
 SET header->age = uar_i18ngetmessage (i18nhandle ,"header4" ,"Age" )
SET header->ega = uar_i18ngetmessage (i18nhandle ,"header5" ,"EGA" )
 SET header->g = uar_i18ngetmessage (i18nhandle ,"header6" ,"G" )
 SET header->p_full = uar_i18ngetmessage (i18nhandle ,"header7" ,"Para_Full_Term" )
 SET header->p_term = uar_i18ngetmessage (i18nhandle ,"header8" ,"Para_Pre_Term" )
 SET header->aborh = uar_i18ngetmessage (i18nhandle ,"header9" ,"ABORh" )
 SET header->rom = uar_i18ngetmessage (i18nhandle ,"header10" ,"ROM_to_Delivery_(Hr)" )
 SET header->induction_ind = uar_i18ngetmessage (i18nhandle ,"header11" ,"Induction_Indications" )
 SET header->induction_method = uar_i18ngetmessage (i18nhandle ,"header12" ,"Induction_Method" )
 SET header->aug_method = uar_i18ngetmessage (i18nhandle ,"header13" ,"Augmentation_Method" )
 SET header->birth_dt_tm = uar_i18ngetmessage (i18nhandle ,"header14" ,"Birth_Date/Time" )
 SET header->del_type = uar_i18ngetmessage (i18nhandle ,"header15" ,"Delivery_Type" )
 SET header->cs_indications = uar_i18ngetmessage (i18nhandle ,"header16" ,"C/S_Indications" )
 SET header->anes_type = uar_i18ngetmessage (i18nhandle ,"header17" ,"Anesthesia_Type" )
 SET header->neo_outcome = uar_i18ngetmessage (i18nhandle ,"header18" ,"Neonate_Outcome" )
 SET header->epis = uar_i18ngetmessage (i18nhandle ,"header19" ,"Episiotomy" )
 SET header->laceration = uar_i18ngetmessage (i18nhandle ,"header20" ,"Laceration" )
 SET header->placenta_dt_tm = uar_i18ngetmessage (i18nhandle ,"header21" ,"Placenta_Delivery_dt/tm"
  )
 SET header->sex = uar_i18ngetmessage (i18nhandle ,"header22" ,"Sex_of_Baby" )
 SET header->weight = uar_i18ngetmessage (i18nhandle ,"header23" ,"Birth_Weight_(g)" )
 SET header->apgar_1 = uar_i18ngetmessage (i18nhandle ,"header24" ,"Apgar_1_Min" )
 SET header->apgar_5 = uar_i18ngetmessage (i18nhandle ,"header25" ,"Apgar_5_Min" )
 SET header->apgar_10 = uar_i18ngetmessage (i18nhandle ,"header26" ,"Apgar_10_Min" )
 SET header->apgar_15 = uar_i18ngetmessage (i18nhandle ,"header27" ,"Apgar_15_Min" )
 SET header->apgar_20 = uar_i18ngetmessage (i18nhandle ,"header28" ,"Apgar_20_Min" )
 SET header->fhr_mon = uar_i18ngetmessage (i18nhandle ,"header29" ,"FHR_Mon" )
 SET header->uc_mon = uar_i18ngetmessage (i18nhandle ,"header30" ,"UC_Mon" )
 SET header->maternal_compl = uar_i18ngetmessage (i18nhandle ,"header31" ,"Maternal_Complications" )
 SET header->neonate_comp = uar_i18ngetmessage (i18nhandle ,"header32" ,"Neonate_Complications" )
 SET header->risk_factors = uar_i18ngetmessage (i18nhandle ,"header33" ,"Risk_Factors" )
 SET header->amniotic_desc = uar_i18ngetmessage (i18nhandle ,"header34" ,"Amniotic_Fluid_Desc" )
 SET header->del_prov = uar_i18ngetmessage (i18nhandle ,"header35" ,"Delivery_Provider" )
 SET header->del_rn_1 = uar_i18ngetmessage (i18nhandle ,"header36" ,"Delivery_RN_#1" )
 SET header->neo_prov = uar_i18ngetmessage (i18nhandle ,"header37" ,"Neonatal_Provider" )
 SET header->resus_rn_1 = uar_i18ngetmessage (i18nhandle ,"header38" ,"Resus_RN_#1" )
 SET header->baby_to = uar_i18ngetmessage (i18nhandle ,"header39" ,"Baby_To" )
 SET header->mother_to = uar_i18ngetmessage (i18nhandle ,"header40" ,"Mother_To" )
 SET header->race = uar_i18ngetmessage (i18nhandle ,"header41" ,"Race" )
 SET header->ethnicity = uar_i18ngetmessage (i18nhandle ,"header41" ,"Ethnicity" ) ;SR150201
 SET header->tobac_use = uar_i18ngetmessage (i18nhandle ,"header42" ,"Tobacco_Use" )
 SET header->tobac_amt = uar_i18ngetmessage (i18nhandle ,"header43" ,"Tobacco_Amt" )
 SET header->feed_method = uar_i18ngetmessage (i18nhandle ,"header44" ,"Feeding_Type_Newborn" )
 SET header->location = uar_i18ngetmessage (i18nhandle ,"header45" ,"Location" )
 SET header->diagnosis = uar_i18ngetmessage (i18nhandle ,"header46" ,"Diagnosis" )
 SET header->ebl = uar_i18ngetmessage (i18nhandle ,"header47" ,"EBL" )
 SET header->cbb = uar_i18ngetmessage (i18nhandle ,"header48" ,"Cord_Blood_Banking" )
 SET header->present_part = uar_i18ngetmessage (i18nhandle ,"header49" ,"Presenting_Part" )
 SET header->lab_onset_dt_tm = uar_i18ngetmessage (i18nhandle ,"header50" ,"Labor_Onset_dt/tm" )
 SET header->2nd_onset_dt_tm = uar_i18ngetmessage (i18nhandle ,"header51" ,"2nd_Stage_Onset_dt/tm" )
 SET header->3rd_onset_dt_tm = uar_i18ngetmessage (i18nhandle ,"header52" ,"3rd_Stage_Onset_dt/tm" )
 SET header->no_deliv = uar_i18ngetmessage (i18nhandle ,"error" ,
  "No deliveries found for specified parameters" )
 SET header->report_title = uar_i18ngetmessage (i18nhandle ,"header53" ,"EXTRACTABLE BIRTH LOG BOOK"
  )
 SET header->date_range = uar_i18ngetmessage (i18nhandle ,"header54" ,"Date Range:" )
 SET header->printed_by = uar_i18ngetmessage (i18nhandle ,"header55" ,"Printed By:" )
 SET header->org = uar_i18ngetmessage (i18nhandle ,"header56" ,"Organization(s):" )
 SET header->cord_blood_ph = uar_i18ngetmessage (i18nhandle ,"header57" ,"Cord_Blood_pH_Drawn" )
 SET header->attn_phys = uar_i18ngetmessage (i18nhandle ,"header58" ,"Attending_Physician" )
 SET header->rom_dt_tm = uar_i18ngetmessage (i18nhandle ,"header59" ,"ROM_dt/tm" )
 SET header->asst_phys_1 = uar_i18ngetmessage (i18nhandle ,"header60" ,"Assisting_Physician_#1" )
 SET header->asst_phys_2 = uar_i18ngetmessage (i18nhandle ,"header61" ,"Assisting_Physician_#2" )
 SET header->del_rn_2 = uar_i18ngetmessage (i18nhandle ,"header62" ,"Delivery_RN_#2" )
 SET header->ped = uar_i18ngetmessage (i18nhandle ,"header63" ,"Pediatrician" )
 SET header->baby_mrn = uar_i18ngetmessage (i18nhandle ,"header64" ,"Baby_MRN" )
 SET header->labor_room = uar_i18ngetmessage (i18nhandle ,"header65" ,"Labor_Room" )
 SET header->postpart_room = uar_i18ngetmessage (i18nhandle ,"header66" ,"Postpartum_Room" )
 SET header->previous_cs = uar_i18ngetmessage (i18nhandle ,"header67" ,"Previous_C/S_Indicator" )
 SET header->years = uar_i18ngetmessage (i18nhandle ,"header68" ,"Years" )
 SET header->rom_type = uar_i18ngetmessage (i18nhandle ,"header69" ,"ROM_Type" )
 SET header->preg_risk_factors = uar_i18ngetmessage (i18nhandle ,"header70" ,
  "Risk_Factors_Current_Pregnancy" )
 SET header->anesthesiologist = uar_i18ngetmessage (i18nhandle ,"header71" ,"Anesthesiologist" )
 SET header->anesthetist = uar_i18ngetmessage (i18nhandle ,"header72" ,"Anesthetist" )
 DECLARE loadpregnancyorganizationsecuritylist () = null
 IF ((validate (preg_org_sec_ind ) = 0 ) )
  DECLARE preg_org_sec_ind = i4 WITH noconstant (0 )
  SELECT INTO "nl:"
   FROM (dm_info d1 ),
    (dm_info d2 )
   WHERE (d1.info_domain = "SECURITY" )
   AND (d1.info_name = "SEC_ORG_RELTN" )
   AND (d1.info_number = 1 )
   AND (d2.info_domain = "SECURITY" )
   AND (d2.info_name = "SEC_PREG_ORG_RELTN" )
   AND (d2.info_number = 1 )
   DETAIL
    preg_org_sec_ind = 1
   WITH nocounter
  ;end select
  CALL echo (build ("preg_org_sec_ind=" ,preg_org_sec_ind ) )
  IF ((preg_org_sec_ind = 1 ) )
   FREE RECORD preg_sec_orgs
   RECORD preg_sec_orgs (
     1 qual [* ]
       2 org_id = f8
       2 confid_level = i4
   )
   CALL loadpregnancyorganizationsecuritylist (null )
  ENDIF
 ENDIF
 SUBROUTINE  loadpregnancyorganizationsecuritylist (null )
  DECLARE org_cnt = i2 WITH noconstant (0 )
  DECLARE stat = i2 WITH protect ,noconstant (0 )
  IF ((validate (sac_org ) = 1 ) )
   FREE RECORD sac_org
  ENDIF
  RECORD sac_org (
    1 organizations [* ]
      2 organization_id = f8
      2 confid_cd = f8
      2 confid_level = i4
  )
  EXECUTE secrtl
  DECLARE orgcnt = i4 WITH protected ,noconstant (0 )
  DECLARE secstat = i2
  DECLARE logontype = i4 WITH protect ,noconstant (- (1 ) )
  DECLARE confid_cd = f8 WITH protected ,noconstant (0.0 )
  DECLARE role_profile_org_id = f8 WITH protected ,noconstant (0.0 )
  CALL uar_secgetclientlogontype (logontype )
  CALL echo (build ("logontype:" ,logontype ) )
  IF ((logontype = 0 ) )
   SELECT DISTINCT INTO "nl:"
    FROM (prsnl_org_reltn por ),
     (organization o ),
     (prsnl p )
    PLAN (p
     WHERE (p.person_id = reqinfo->updt_id ) )
     JOIN (por
     WHERE (por.person_id = p.person_id )
     AND (por.active_ind = 1 )
     AND (por.beg_effective_dt_tm <= cnvtdatetime (curdate ,curtime3 ) )
     AND (por.end_effective_dt_tm > cnvtdatetime (curdate ,curtime3 ) ) )
     JOIN (o
     WHERE (por.organization_id = o.organization_id ) )
    DETAIL
     orgcnt = (orgcnt + 1 ) ,
     IF ((mod (orgcnt ,10 ) = 1 ) ) secstat = alterlist (sac_org->organizations ,(orgcnt + 9 ) )
     ENDIF
     ,sac_org->organizations[orgcnt ].organization_id = por.organization_id ,
     sac_org->organizations[orgcnt ].confid_cd = por.confid_level_cd ,
     confid_cd = uar_get_collation_seq (por.confid_level_cd ) ,
     sac_org->organizations[orgcnt ].confid_level =
     IF ((confid_cd > 0 ) ) confid_cd
     ELSE 0
     ENDIF
    WITH nocounter
   ;end select
   SET secstat = alterlist (sac_org->organizations ,orgcnt )
  ENDIF
  IF ((logontype = 1 ) )
   CALL echo ("entered into NHS logon" )
   DECLARE hprop = i4 WITH protect ,noconstant (0 )
   DECLARE tmpstat = i2
   DECLARE spropname = vc
   DECLARE sroleprofile = vc
   SET hprop = uar_srvcreateproperty ()
   SET tmpstat = uar_secgetclientattributesext (5 ,hprop )
   SET spropname = uar_srvfirstproperty (hprop )
   SET sroleprofile = uar_srvgetpropertyptr (hprop ,nullterm (spropname ) )
   CALL echo (sroleprofile )
   DECLARE nhstrustchild_org_org_reltn_cd = f8
   SET nhstrustchild_org_org_reltn_cd = uar_get_code_by ("MEANING" ,369 ,"NHSTRUSTCHLD" )
   SELECT INTO "nl:"
    FROM (prsnl_org_reltn_type prt ),
     (prsnl_org_reltn por ),
     (organization o )
    PLAN (prt
     WHERE (prt.role_profile = sroleprofile )
     AND (prt.active_ind = 1 )
     AND (prt.beg_effective_dt_tm <= cnvtdatetime (curdate ,curtime3 ) )
     AND (prt.end_effective_dt_tm > cnvtdatetime (curdate ,curtime3 ) ) )
     JOIN (o
     WHERE (o.organization_id = prt.organization_id ) )
     JOIN (por
     WHERE (outerjoin (prt.organization_id ) = por.organization_id )
     AND (por.person_id = outerjoin (prt.prsnl_id ) )
     AND (por.active_ind = outerjoin (1 ) )
     AND (por.beg_effective_dt_tm <= outerjoin (cnvtdatetime (curdate ,curtime3 ) ) )
     AND (por.end_effective_dt_tm > outerjoin (cnvtdatetime (curdate ,curtime3 ) ) ) )
    ORDER BY por.prsnl_org_reltn_id
    DETAIL
     orgcnt = 1 ,
     stat = alterlist (sac_org->organizations ,1 ) ,
     sac_org->organizations[1 ].organization_id = prt.organization_id ,
     role_profile_org_id = sac_org->organizations[orgcnt ].organization_id ,
     sac_org->organizations[1 ].confid_cd = por.confid_level_cd ,
     confid_cd = uar_get_collation_seq (por.confid_level_cd ) ,
     sac_org->organizations[1 ].confid_level =
     IF ((confid_cd > 0 ) ) confid_cd
     ELSE 0
     ENDIF
    WITH maxrec = 1
   ;end select
   SELECT INTO "nl:"
    FROM (prsnl_org_reltn por )
    PLAN (por
     WHERE (por.person_id = reqinfo->updt_id )
     AND (por.active_ind = 1 )
     AND (por.beg_effective_dt_tm <= cnvtdatetime (curdate ,curtime3 ) )
     AND (por.end_effective_dt_tm > cnvtdatetime (curdate ,curtime3 ) ) )
    HEAD REPORT
     IF ((orgcnt > 0 ) ) stat = alterlist (sac_org->organizations ,10 )
     ENDIF
    DETAIL
     IF ((role_profile_org_id != por.organization_id ) ) orgcnt = (orgcnt + 1 ) ,
      IF ((mod (orgcnt ,10 ) = 1 ) ) stat = alterlist (sac_org->organizations ,(orgcnt + 9 ) )
      ENDIF
      ,sac_org->organizations[orgcnt ].organization_id = por.organization_id ,sac_org->organizations[
      orgcnt ].confid_cd = por.confid_level_cd ,confid_cd = uar_get_collation_seq (por
       .confid_level_cd ) ,sac_org->organizations[orgcnt ].confid_level =
      IF ((confid_cd > 0 ) ) confid_cd
      ELSE 0
      ENDIF
     ENDIF
    FOOT REPORT
     stat = alterlist (sac_org->organizations ,orgcnt )
    WITH nocounter
   ;end select
   CALL uar_srvdestroyhandle (hprop )
  ENDIF
  SET org_cnt = size (sac_org->organizations ,5 )
  CALL echo (build ("org_cnt: " ,org_cnt ) )
  SET stat = alterlist (preg_sec_orgs->qual ,(org_cnt + 1 ) )
  FOR (count = 1 TO org_cnt )
   SET preg_sec_orgs->qual[count ].org_id = sac_org->organizations[count ].organization_id
   SET preg_sec_orgs->qual[count ].confid_level = sac_org->organizations[count ].confid_level
  ENDFOR
  SET preg_sec_orgs->qual[(org_cnt + 1 ) ].org_id = 0.00
  SET preg_sec_orgs->qual[(org_cnt + 1 ) ].confid_level = 0
 END ;Subroutine
 IF ((validate (debug_ind ,0 ) = 1 ) )
  IF (preg_org_sec_ind )
   CALL echorecord (preg_sec_orgs )
  ENDIF
 ENDIF
 CALL get_header (null )
 CALL get_event_codes (null )
 CALL get_pregnancy_model_data (null )
 IF ((validate (debug_ind ,0 ) = 1 ) )
  CALL echorecord (preg_data_model )
 ENDIF
 CALL get_clinical_model_data (null )
 IF ((validate (debug_ind ,0 ) = 1 ) )
  CALL echorecord (preg_data_model )
 ENDIF
 FOR (v_m = 1 TO size (preg_data_model->mother ,5 ) )
  FOR (a_m = 1 TO size (preg_data_model->mother ,5 ) )
   IF ((preg_data_model->mother[v_m ].person_id = preg_data_model->mother[a_m ].person_id ) )
    IF ((preg_data_model->mother[v_m ].delivery[1 ].birth_dt_tm > preg_data_model->mother[a_m ].
    delivery[1 ].birth_dt_tm ) )
     IF ((preg_data_model->mother[a_m ].cs_ind = 1 ) )
      SET preg_data_model->mother[v_m ].prev_csec_ind = 1
     ENDIF
    ELSEIF ((preg_data_model->mother[v_m ].delivery[1 ].birth_dt_tm = null ) )
     IF ((preg_data_model->mother[a_m ].cs_ind = 1 ) )
      SET preg_data_model->mother[v_m ].prev_csec_ind = 1
     ENDIF
    ENDIF
   ENDIF
  ENDFOR
 ENDFOR
 IF ((size (event_codes->rec ,5 ) < 1 ) )
  GO TO exit_script
 ENDIF
 IF ((validate (debug_ind ,0 ) = 1 ) )
  CALL echorecord (preg_data_model )
  CALL echorecord (event_codes )
 ENDIF
 IF ((all_orgs_flag = 1 ) )
  CALL get_ce_model_data (null )
 ELSE
  CALL get_ce_model_data_by_org (null )
 ENDIF
 CALL get_ce_data (null )
 IF ((validate (debug_ind ,0 ) = 1 ) )
  CALL echorecord (ce_data_model )
 ENDIF
 CALL load_birth_log_rec (null )
 CALL get_mother_mrn (null )
 CALL get_mother_demographic (null )
 CALL get_mother_diagnosis (null )
 CALL get_location_history (null )
 CALL get_patient_ega (null )
 CALL get_baby_mrn (null )
 SET shx_exists = checkdic ("SHX_ACTIVITY" ,"T" ,0 )
 CALL get_tobacco_ce (null )
 IF ((shx_exists > 0 ) )
  CALL get_tobacco_shx (null )
 ENDIF
 FOR (crec = 1 TO size (birth_log->rec ,5 ) )
 call echo("PM-entered 1st data")
  SET birth_log->rec[crec ].mother_name =
  ;uar_i18ngetmessage (i18nhandle ,"header1" ,birth_log->rec[crec ].mother_name )
   replace (birth_log->rec[crec ].mother_name ,"," ,";" ,0 )
  SET birth_log->rec[crec ].mother_age = replace (birth_log->rec[crec ].mother_age ,"," ,";" ,0 )
  SET birth_log->rec[crec ].mother_reg_dt = replace (birth_log->rec[crec ].mother_reg_dt ,"," ,";" ,
   0 )
  SET birth_log->rec[crec ].mother_disch_dt_tm = replace (birth_log->rec[crec ].mother_disch_dt_tm ,
   "," ,";" ,0 )
  SET birth_log->rec[crec ].mother_mrn = replace (birth_log->rec[crec ].mother_mrn ,"," ,";" ,0 )
  SET birth_log->rec[crec ].ega = 
  ;uar_i18ngetmessage (i18nhandle ,"header1" ,birth_log->rec[crec ].ega )
  replace (birth_log->rec[crec ].ega ,"," ,";" ,0 )
 
  SET birth_log->rec[crec ].g = replace (birth_log->rec[crec ].g ,"," ,";" ,0 )
  SET birth_log->rec[crec ].p_full_term = replace (birth_log->rec[crec ].p_full_term ,"," ,";" ,0 )
  SET birth_log->rec[crec ].p_pre_term = replace (birth_log->rec[crec ].p_pre_term ,"," ,";" ,0 )
  SET birth_log->rec[crec ].aborh = replace (birth_log->rec[crec ].aborh ,"," ,";" ,0 )
  SET birth_log->rec[crec ].anesth_type = replace (birth_log->rec[crec ].anesth_type ,"," ,";" ,0 )
  SET birth_log->rec[crec ].uc_mon = replace (birth_log->rec[crec ].uc_mon ,"," ,";" ,0 )
  SET birth_log->rec[crec ].mother_to = replace (birth_log->rec[crec ].mother_to ,"," ,";" ,0 )
  SET birth_log->rec[crec ].induct_ind = replace (birth_log->rec[crec ].induct_ind ,"," ,";" ,0 )
  SET birth_log->rec[crec ].episiotomy = replace (birth_log->rec[crec ].episiotomy ,"," ,";" ,0 )
  SET birth_log->rec[crec ].laceration = replace (birth_log->rec[crec ].laceration ,"," ,";" ,0 )
  SET birth_log->rec[crec ].race = replace (birth_log->rec[crec ].race ,"," ,";" ,0 )
  SET birth_log->rec[crec ].ethnicity = replace (birth_log->rec[crec ].ethnicity ,"," ,";" ,0 )
  SET birth_log->rec[crec ].tobacco_use = replace (birth_log->rec[crec ].tobacco_use ,"," ,";" ,0 )
  SET birth_log->rec[crec ].tobacco_amt = replace (birth_log->rec[crec ].tobacco_amt ,"," ,";" ,0 )
  SET birth_log->rec[crec ].feeding_method = replace (birth_log->rec[crec ].feeding_method ,"," ,";"
   ,0 )
  SET birth_log->rec[crec ].location = replace (birth_log->rec[crec ].location ,"," ,";" ,0 )
  SET birth_log->rec[crec ].diagnosis = replace (birth_log->rec[crec ].diagnosis ,"," ,";" ,0 )
  SET birth_log->rec[crec ].est_blood_loss = replace (birth_log->rec[crec ].est_blood_loss ,"," ,";"
   ,0 )
  SET birth_log->rec[crec ].amniotic_desc = replace (birth_log->rec[crec ].amniotic_desc ,"," ,";" ,
   0 )
  SET birth_log->rec[crec ].neo_prov = replace (birth_log->rec[crec ].neo_prov ,"," ,";" ,0 )
  SET birth_log->rec[crec ].presenting_part = replace (birth_log->rec[crec ].presenting_part ,"," ,
   ";" ,0 )
  SET birth_log->rec[crec ].labor_onset_dt_tm = replace (birth_log->rec[crec ].labor_onset_dt_tm ,
   "," ,";" ,0 )
  SET birth_log->rec[crec ].preg_risk_factors = replace (birth_log->rec[crec ].preg_risk_factors ,
   "," ,";" ,0 )
  FOR (cbaby = 1 TO size (birth_log->rec[crec ].baby ,5 ) )
   SET birth_log->rec[crec ].baby[cbaby ].id = replace (birth_log->rec[crec ].baby[cbaby ].id ,"," ,
    ";" ,0 )
   IF ((size (birth_log->rec[crec ].baby[cbaby ].id ) > 0 ) )
    SET birth_log->rec[crec ].mother_mrn = concat (birth_log->rec[crec ].mother_mrn ,"/" ,birth_log->
     rec[crec ].baby[cbaby ].id )
   ENDIF
   SET birth_log->rec[crec ].baby[cbaby ].mat_compl = replace (birth_log->rec[crec ].baby[cbaby ].
    mat_compl ,"," ,";" ,0 )
   SET birth_log->rec[crec ].baby[cbaby ].rom_del = replace (birth_log->rec[crec ].baby[cbaby ].
    rom_del ,"," ,";" ,0 )
   SET birth_log->rec[crec ].baby[cbaby ].rom_type = replace (birth_log->rec[crec ].baby[cbaby ].
    rom_type ,"," ,";" ,0 )
   SET birth_log->rec[crec ].baby[cbaby ].rom_dt_tm = replace (birth_log->rec[crec ].baby[cbaby ].
    rom_dt_tm ,"," ,";" ,0 )
   SET birth_log->rec[crec ].baby[cbaby ].brth_dt_tm = 
   ;uar_i18ngetmessage (i18nhandle ,"header1" ,birth_log->rec[crec ].baby[cbaby ].brth_dt_tm )
   replace (birth_log->rec[crec ].baby[cbaby ].brth_dt_tm ,"," ,";" ,0 )
   SET birth_log->rec[crec ].baby[cbaby ].del_type = replace (birth_log->rec[crec ].baby[cbaby ].
    del_type ,"," ,";" ,0 )
   SET birth_log->rec[crec ].baby[cbaby ].neo_outcome = 
   ; uar_i18ngetmessage (i18nhandle ,"header1" ,birth_log->rec[crec ].baby[cbaby ].neo_outcome  )
   replace (birth_log->rec[crec ].baby[cbaby ].neo_outcome ,"," ,";" ,0 )
   SET birth_log->rec[crec ].baby[cbaby ].sex = 
   ;uar_i18ngetmessage (i18nhandle ,"header1" ,birth_log->rec[crec ].baby[cbaby ].sex  )
   replace (birth_log->rec[crec ].baby[cbaby ].sex ,",",";" ,0 )
   SET birth_log->rec[crec ].baby[cbaby ].birth_wt =
   ; uar_i18ngetmessage (i18nhandle ,"header1" ,birth_log->rec[crec ].baby[cbaby ]. birth_wt  )
    replace (birth_log->rec[crec ].baby[cbaby ]. birth_wt ,"," ,";" ,0 )
   SET birth_log->rec[crec ].baby[cbaby ].apgar_1min = replace (birth_log->rec[crec ].baby[cbaby ].
    apgar_1min ,"," ,";" ,0 )
   SET birth_log->rec[crec ].baby[cbaby ].apgar_5min = replace (birth_log->rec[crec ].baby[cbaby ].
    apgar_5min ,"," ,";" ,0 )
   SET birth_log->rec[crec ].baby[cbaby ].apgar_10min = replace (birth_log->rec[crec ].baby[cbaby ].
    apgar_10min ,"," ,";" ,0 )
   SET birth_log->rec[crec ].baby[cbaby ].apgar_15min = replace (birth_log->rec[crec ].baby[cbaby ].
    apgar_15min ,"," ,";" ,0 )
   SET birth_log->rec[crec ].baby[cbaby ].apgar_20min = replace (birth_log->rec[crec ].baby[cbaby ].
    apgar_20min ,"," ,";" ,0 )
   SET birth_log->rec[crec ].baby[cbaby ].fhr_mon = replace (birth_log->rec[crec ].baby[cbaby ].
    fhr_mon ,"," ,";" ,0 )
   SET birth_log->rec[crec ].baby[cbaby ].ind_meth = replace (birth_log->rec[crec ].baby[cbaby ].
    ind_meth ,"," ,";" ,0 )
   SET birth_log->rec[crec ].baby[cbaby ].aug_meth = replace (birth_log->rec[crec ].baby[cbaby ].
    aug_meth ,"," ,";" ,0 )
   SET birth_log->rec[crec ].baby[cbaby ].cs_ind = replace (birth_log->rec[crec ].baby[cbaby ].cs_ind
     ,"," ,";" ,0 )
   SET birth_log->rec[crec ].baby[cbaby ].del_prov = replace (birth_log->rec[crec ].baby[cbaby ].
    del_prov ,"," ,";" ,0 )
   SET birth_log->rec[crec ].baby[cbaby ].asst_phys_1 = replace (birth_log->rec[crec ].baby[cbaby ].
    asst_phys_1 ,"," ,";" ,0 )
   SET birth_log->rec[crec ].baby[cbaby ].asst_phys_2 = replace (birth_log->rec[crec ].baby[cbaby ].
    asst_phys_2 ,"," ,";" ,0 )
   SET birth_log->rec[crec ].baby[cbaby ].del_rn_1 = replace (birth_log->rec[crec ].baby[cbaby ].
    del_rn_1 ,"," ,";" ,0 )
   SET birth_log->rec[crec ].baby[cbaby ].del_rn_2 = replace (birth_log->rec[crec ].baby[cbaby ].
    del_rn_2 ,"," ,";" ,0 )
   SET birth_log->rec[crec ].baby[cbaby ].pediatrician = replace (birth_log->rec[crec ].baby[cbaby ].
    pediatrician ,"," ,";" ,0 )
   SET birth_log->rec[crec ].baby[cbaby ].baby_to = replace (birth_log->rec[crec ].baby[cbaby ].
    baby_to ,"," ,";" ,0 )
   SET birth_log->rec[crec ].baby[cbaby ].placenta_dt_tm = replace (birth_log->rec[crec ].baby[cbaby
    ].placenta_dt_tm ,"," ,";" ,0 )
   SET birth_log->rec[crec ].baby[cbaby ].neo_compl = replace (birth_log->rec[crec ].baby[cbaby ].
    neo_compl ,"," ,";" ,0 )
   SET birth_log->rec[crec ].baby[cbaby ].risk_factors = replace (birth_log->rec[crec ].baby[cbaby ].
    risk_factors ,"," ,";" ,0 )
   SET birth_log->rec[crec ].baby[cbaby ].resus_rn_1 = replace (birth_log->rec[crec ].baby[cbaby ].
    resus_rn_1 ,"," ,";" ,0 )
   SET birth_log->rec[crec ].baby[cbaby ].cord_blood_banking = replace (birth_log->rec[crec ].baby[
    cbaby ].cord_blood_banking ,"," ,";" ,0 )
   SET birth_log->rec[crec ].baby[cbaby ].2nd_stage_onset_dt_tm = replace (birth_log->rec[crec ].
    baby[cbaby ].2nd_stage_onset_dt_tm ,"," ,";" ,0 )
   SET birth_log->rec[crec ].baby[cbaby ].3nd_stage_onset_dt_tm = replace (birth_log->rec[crec ].
    baby[cbaby ].3nd_stage_onset_dt_tm ,"," ,";" ,0 )
   SET birth_log->rec[crec ].baby[cbaby ].rom_dt_tm = replace (birth_log->rec[crec ].baby[cbaby ].
    rom_dt_tm ,"," ,";" ,0 )
   SET birth_log->rec[crec ].baby[cbaby ].asst_phys_1 = replace (birth_log->rec[crec ].baby[cbaby ].
    asst_phys_1 ,"," ,";" ,0 )
   SET birth_log->rec[crec ].baby[cbaby ].asst_phys_2 = replace (birth_log->rec[crec ].baby[cbaby ].
    asst_phys_2 ,"," ,";" ,0 )
   SET birth_log->rec[crec ].baby[cbaby ].attn_phys = replace (birth_log->rec[crec ].baby[cbaby ].
    attn_phys ,"," ,";" ,0 )
   SET birth_log->rec[crec ].baby[cbaby ].baby_mrn =
   ; uar_i18ngetmessage (i18nhandle ,"header1" ,birth_log->rec[crec ].baby[cbaby ]. baby_mrn )
    replace (birth_log->rec[crec ].baby[cbaby ]. baby_mrn ,"," ,";" ,0 )
   SET birth_log->rec[crec ].baby[cbaby ].cord_blood_ph = replace (birth_log->rec[crec ].baby[cbaby ]
    .cord_blood_ph ,"," ,";" ,0 )
   SET birth_log->rec[crec ].baby[cbaby ].anesthesiologist = replace (birth_log->rec[crec ].baby[
    cbaby ].anesthesiologist ,"," ,";" ,0 )
   SET birth_log->rec[crec ].baby[cbaby ].anesthetist = replace (birth_log->rec[crec ].baby[cbaby ].
    anesthetist ,"," ,";" ,0 )
  ENDFOR
 ENDFOR
 SELECT INTO  $OUTDEV
  sort1 = cnvtdatetime (birth_log->rec[d1.seq ].baby[1 ].brth_dt_tm_dq ) ,
  sort2 = birth_log->rec[d1.seq ].encntr_id ,
  sort3 = cnvtdatetime (birth_log->rec[d1.seq ].baby[d2.seq ].brth_dt_tm_dq )
  FROM (dummyt d1 WITH seq = size (birth_log->rec ,5 ) ),
   (dummyt d2 WITH seq = 1 )
  PLAN (d1
   WHERE maxrec (d2 ,size (birth_log->rec[d1.seq ].baby ,5 ) ) )
   JOIN (d2 )
  ORDER BY sort1 DESC ,
   sort2
  HEAD REPORT
   xo_cnt = 1 ,
   stat = alterlist (ex_out->rec ,xo_cnt ) ,
   ex_out->rec[xo_cnt ].name = header->name ,
   ex_out->rec[xo_cnt ].admit_dt_tm = header->admit_dt_tm ,
   ex_out->rec[xo_cnt ].disch_dt_tm = header->disch_dt_tm ,
   ex_out->rec[xo_cnt ].mrn_id = header->mrn_id ,
   ex_out->rec[xo_cnt ].age = header->age ,
   ex_out->rec[xo_cnt ].ega = header->ega ,
   ex_out->rec[xo_cnt ].g = header->g ,
   ex_out->rec[xo_cnt ].p_full = header->p_full ,
   ex_out->rec[xo_cnt ].p_term = header->p_term ,
   ex_out->rec[xo_cnt ].aborh = header->aborh ,
   ex_out->rec[xo_cnt ].rom = header->rom ,
   ex_out->rec[xo_cnt ].rom_type = header->rom_type ,
   ex_out->rec[xo_cnt ].rom_dt_tm = header->rom_dt_tm ,
   ex_out->rec[xo_cnt ].induction_ind = header->induction_ind ,
   ex_out->rec[xo_cnt ].induction_method = header->induction_method ,
   ex_out->rec[xo_cnt ].aug_method = header->aug_method ,
   ex_out->rec[xo_cnt ].birth_dt_tm = header->birth_dt_tm ,
   ex_out->rec[xo_cnt ].del_type = header->del_type ,
   ex_out->rec[xo_cnt ].cs_indications = header->cs_indications ,
   ex_out->rec[xo_cnt ].anes_type = header->anes_type ,
   ex_out->rec[xo_cnt ].neo_outcome = header->neo_outcome ,
   ex_out->rec[xo_cnt ].epis = header->epis ,
   ex_out->rec[xo_cnt ].laceration = header->laceration ,
   ex_out->rec[xo_cnt ].placenta_dt_tm = header->placenta_dt_tm ,
   ex_out->rec[xo_cnt ].sex = header->sex ,
   ex_out->rec[xo_cnt ].weight = header->weight ,
   ex_out->rec[xo_cnt ].apgar_1 = header->apgar_1 ,
   ex_out->rec[xo_cnt ].apgar_5 = header->apgar_5 ,
   ex_out->rec[xo_cnt ].apgar_10 = header->apgar_10 ,
   ex_out->rec[xo_cnt ].apgar_15 = header->apgar_15 ,
   ex_out->rec[xo_cnt ].apgar_20 = header->apgar_20 ,
   ex_out->rec[xo_cnt ].fhr_mon = header->fhr_mon ,
   ex_out->rec[xo_cnt ].uc_mon = header->uc_mon ,
   ex_out->rec[xo_cnt ].maternal_compl = header->maternal_compl ,
   ex_out->rec[xo_cnt ].neonate_comp = header->neonate_comp ,
   ex_out->rec[xo_cnt ].risk_factors = header->risk_factors ,
   ex_out->rec[xo_cnt ].amniotic_desc = header->amniotic_desc ,
   ex_out->rec[xo_cnt ].del_prov = header->del_prov ,
   ex_out->rec[xo_cnt ].asst_phys_1 = header->asst_phys_1 ,
   ex_out->rec[xo_cnt ].asst_phys_2 = header->asst_phys_2 ,
   ex_out->rec[xo_cnt ].attn_phys = header->attn_phys ,
   ex_out->rec[xo_cnt ].ped = header->ped ,
   ex_out->rec[xo_cnt ].del_rn_1 = header->del_rn_1 ,
   ex_out->rec[xo_cnt ].del_rn_2 = header->del_rn_2 ,
   ex_out->rec[xo_cnt ].neo_prov = header->neo_prov ,
   ex_out->rec[xo_cnt ].resus_rn_1 = header->resus_rn_1 ,
   ex_out->rec[xo_cnt ].baby_to = header->baby_to ,
   ex_out->rec[xo_cnt ].mother_to = header->mother_to ,
   ex_out->rec[xo_cnt ].race = header->race ,
    ex_out->rec[xo_cnt ].ethnicity = header->ethnicity ,
   
   ex_out->rec[xo_cnt ].tobac_use = header->tobac_use ,
   ex_out->rec[xo_cnt ].tobac_amt = header->tobac_amt ,
   ex_out->rec[xo_cnt ].feed_method = header->feed_method ,
   ex_out->rec[xo_cnt ].location = header->location ,
   ex_out->rec[xo_cnt ].diagnosis = header->diagnosis ,
   ex_out->rec[xo_cnt ].ebl = header->ebl ,
   ex_out->rec[xo_cnt ].cbb = header->cbb ,
   ex_out->rec[xo_cnt ].present_part = header->present_part ,
   ex_out->rec[xo_cnt ].lab_onset_dt_tm = header->lab_onset_dt_tm ,
   ex_out->rec[xo_cnt ].2nd_onset_dt_tm = header->2nd_onset_dt_tm ,
   ex_out->rec[xo_cnt ].3rd_onset_dt_tm = header->3rd_onset_dt_tm ,
   ex_out->rec[xo_cnt ].cord_blood_ph = header->cord_blood_ph ,
   ex_out->rec[xo_cnt ].baby_mrn = header->baby_mrn ,
   ex_out->rec[xo_cnt ].labor_room = header->labor_room ,
   ex_out->rec[xo_cnt ].postpart_room = header->postpart_room ,
   ex_out->rec[xo_cnt ].previous_cs = header->previous_cs ,
   ex_out->rec[xo_cnt ].preg_risk_factors = header->preg_risk_factors ,
   ex_out->rec[xo_cnt ].anesthesiologist = header->anesthesiologist ,
   ex_out->rec[xo_cnt ].anesthetist = header->anesthetist
  DETAIL
   xo_cnt = (xo_cnt + 1 ) ,
   IF ((xo_cnt > size (ex_out->rec ,5 ) ) ) stat = alterlist (ex_out->rec ,(xo_cnt + 99 ) )
   ENDIF
   ,ex_out->rec[xo_cnt ].name = birth_log->rec[d1.seq ].mother_name ,
   ex_out->rec[xo_cnt ].admit_dt_tm = birth_log->rec[d1.seq ].mother_reg_dt ,
   ex_out->rec[xo_cnt ].disch_dt_tm = birth_log->rec[d1.seq ].mother_disch_dt_tm ,
   ex_out->rec[xo_cnt ].mrn_id = birth_log->rec[d1.seq ].mother_mrn ,
   ex_out->rec[xo_cnt ].age = birth_log->rec[d1.seq ].mother_age ,
   ex_out->rec[xo_cnt ].ega = birth_log->rec[d1.seq ].ega ,
   ex_out->rec[xo_cnt ].g = birth_log->rec[d1.seq ].g ,
   ex_out->rec[xo_cnt ].p_full = birth_log->rec[d1.seq ].p_full_term ,
   ex_out->rec[xo_cnt ].p_term = birth_log->rec[d1.seq ].p_pre_term ,
   ex_out->rec[xo_cnt ].aborh = birth_log->rec[d1.seq ].aborh ,
   ex_out->rec[xo_cnt ].rom = birth_log->rec[d1.seq ].baby[d2.seq ].rom_del ,
   ex_out->rec[xo_cnt ].rom_type = birth_log->rec[d1.seq ].baby[d2.seq ].rom_type ,
   ex_out->rec[xo_cnt ].rom_dt_tm = birth_log->rec[d1.seq ].baby[d2.seq ].rom_dt_tm ,
   ex_out->rec[xo_cnt ].induction_ind = birth_log->rec[d1.seq ].induct_ind ,
   ex_out->rec[xo_cnt ].induction_method = birth_log->rec[d1.seq ].baby[d2.seq ].ind_meth ,
   ex_out->rec[xo_cnt ].aug_method = birth_log->rec[d1.seq ].baby[d2.seq ].aug_meth ,
   ex_out->rec[xo_cnt ].birth_dt_tm = birth_log->rec[d1.seq ].baby[d2.seq ].brth_dt_tm ,
   ex_out->rec[xo_cnt ].del_type = birth_log->rec[d1.seq ].baby[d2.seq ].del_type ,
   ex_out->rec[xo_cnt ].cs_indications = birth_log->rec[d1.seq ].baby[d2.seq ].cs_ind ,
   ex_out->rec[xo_cnt ].anes_type = birth_log->rec[d1.seq ].anesth_type ,
   ex_out->rec[xo_cnt ].neo_outcome = birth_log->rec[d1.seq ].baby[d2.seq ].neo_outcome ,
   ex_out->rec[xo_cnt ].epis = birth_log->rec[d1.seq ].episiotomy ,
   ex_out->rec[xo_cnt ].laceration = birth_log->rec[d1.seq ].laceration ,
   ex_out->rec[xo_cnt ].placenta_dt_tm = birth_log->rec[d1.seq ].baby[d2.seq ].placenta_dt_tm ,
   ex_out->rec[xo_cnt ].sex = birth_log->rec[d1.seq ].baby[d2.seq ].sex ,
   ex_out->rec[xo_cnt ].weight = birth_log->rec[d1.seq ].baby[d2.seq ].birth_wt ,
   ex_out->rec[xo_cnt ].apgar_1 = birth_log->rec[d1.seq ].baby[d2.seq ].apgar_1min ,
   ex_out->rec[xo_cnt ].apgar_5 = birth_log->rec[d1.seq ].baby[d2.seq ].apgar_5min ,
   ex_out->rec[xo_cnt ].apgar_10 = birth_log->rec[d1.seq ].baby[d2.seq ].apgar_10min ,
   ex_out->rec[xo_cnt ].apgar_15 = birth_log->rec[d1.seq ].baby[d2.seq ].apgar_15min ,
   ex_out->rec[xo_cnt ].apgar_20 = birth_log->rec[d1.seq ].baby[d2.seq ].apgar_20min ,
   ex_out->rec[xo_cnt ].fhr_mon = birth_log->rec[d1.seq ].baby[d2.seq ].fhr_mon ,
   ex_out->rec[xo_cnt ].uc_mon = birth_log->rec[d1.seq ].uc_mon ,
   ex_out->rec[xo_cnt ].maternal_compl = birth_log->rec[d1.seq ].baby[d2.seq ].mat_compl ,
   ex_out->rec[xo_cnt ].neonate_comp = birth_log->rec[d1.seq ].baby[d2.seq ].neo_compl ,
   ex_out->rec[xo_cnt ].risk_factors = birth_log->rec[d1.seq ].baby[d2.seq ].risk_factors ,
   ex_out->rec[xo_cnt ].amniotic_desc = birth_log->rec[d1.seq ].amniotic_desc ,
   ex_out->rec[xo_cnt ].del_prov = birth_log->rec[d1.seq ].baby[d2.seq ].del_prov ,
   ex_out->rec[xo_cnt ].asst_phys_1 = birth_log->rec[d1.seq ].baby[d2.seq ].asst_phys_1 ,
   ex_out->rec[xo_cnt ].asst_phys_2 = birth_log->rec[d1.seq ].baby[d2.seq ].asst_phys_2 ,
   ex_out->rec[xo_cnt ].attn_phys = birth_log->rec[d1.seq ].baby[d2.seq ].attn_phys ,
   ex_out->rec[xo_cnt ].ped = birth_log->rec[d1.seq ].baby[d2.seq ].pediatrician ,
   ex_out->rec[xo_cnt ].del_rn_1 = birth_log->rec[d1.seq ].baby[d2.seq ].del_rn_1 ,
   ex_out->rec[xo_cnt ].del_rn_2 = birth_log->rec[d1.seq ].baby[d2.seq ].del_rn_2 ,
   ex_out->rec[xo_cnt ].neo_prov = birth_log->rec[d1.seq ].neo_prov ,
   ex_out->rec[xo_cnt ].resus_rn_1 = birth_log->rec[d1.seq ].baby[d2.seq ].resus_rn_1 ,
   ex_out->rec[xo_cnt ].baby_to = birth_log->rec[d1.seq ].baby[d2.seq ].baby_to ,
   ex_out->rec[xo_cnt ].mother_to = birth_log->rec[d1.seq ].mother_to ,
   ex_out->rec[xo_cnt ].race = birth_log->rec[d1.seq ].race ,
   ex_out->rec[xo_cnt ].ethnicity = birth_log->rec[d1.seq ].ethnicity ,
   ex_out->rec[xo_cnt ].tobac_use = birth_log->rec[d1.seq ].tobacco_use ,
   ex_out->rec[xo_cnt ].tobac_amt = birth_log->rec[d1.seq ].tobacco_amt ,
   ex_out->rec[xo_cnt ].feed_method = birth_log->rec[d1.seq ].baby[d2.seq ].newborn_feeding ,
   ex_out->rec[xo_cnt ].location = birth_log->rec[d1.seq ].location ,
   ex_out->rec[xo_cnt ].diagnosis = birth_log->rec[d1.seq ].diagnosis ,
   ex_out->rec[xo_cnt ].ebl = birth_log->rec[d1.seq ].est_blood_loss ,
   ex_out->rec[xo_cnt ].cbb = birth_log->rec[d1.seq ].baby[d2.seq ].cord_blood_banking ,
   ex_out->rec[xo_cnt ].present_part = birth_log->rec[d1.seq ].presenting_part ,
   ex_out->rec[xo_cnt ].lab_onset_dt_tm = birth_log->rec[d1.seq ].labor_onset_dt_tm ,
   ex_out->rec[xo_cnt ].2nd_onset_dt_tm = birth_log->rec[d1.seq ].baby[d2.seq ].2nd_stage_onset_dt_tm
    ,
   ex_out->rec[xo_cnt ].3rd_onset_dt_tm = birth_log->rec[d1.seq ].baby[d2.seq ].3nd_stage_onset_dt_tm
    ,
   ex_out->rec[xo_cnt ].cord_blood_ph = birth_log->rec[d1.seq ].baby[d2.seq ].cord_blood_ph ,
   ex_out->rec[xo_cnt ].baby_mrn = birth_log->rec[d1.seq ].baby[d2.seq ].baby_mrn ,
   ex_out->rec[xo_cnt ].labor_room = birth_log->rec[d1.seq ].labor_room ,
   ex_out->rec[xo_cnt ].postpart_room = birth_log->rec[d1.seq ].postpart_room ,
   ex_out->rec[xo_cnt ].previous_cs = cnvtstring (birth_log->rec[d1.seq ].prev_csec_ind ) ,
   ex_out->rec[xo_cnt ].preg_risk_factors = birth_log->rec[d1.seq ].preg_risk_factors ,
   ex_out->rec[xo_cnt ].anesthesiologist = birth_log->rec[d1.seq ].baby[d2.seq ].anesthesiologist ,
   ex_out->rec[xo_cnt ].anesthetist = birth_log->rec[d1.seq ].baby[d2.seq ].anesthetist
  FOOT REPORT
   stat = alterlist (ex_out->rec ,xo_cnt )
  WITH nocounter
 ;end select
 CALL echorecord (ex_out )
 
 
 
  /******************************************************************
; Data - Patient Race Values where multiple values were recorded
*******************************************************************/
/* select into "nl:"
  encntr_id =  ex_out->rec[d1.seq].encntr_id
 from (dummyt d1 WITH seq = size ( ex_out->rec ,5 ) )
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
 
 */
 
 
 
 ;declare filename = vc with constant(build2('avh_baby_friendly_report_',format(sysdate,'MM_DD_YYYY;;q'),'.csv'))
 free record reply
  record reply
  (
%i cclsource:status_block.inc
  )
 if($OPS = 'YES')
 SELECT INTO   $OUTDEV;; ;value(filename) ;
/* substring(1,30, trim(ex_out->rec[d1.seq ].name))  ,
;  substring (1 ,300 ,ex_out->rec[d1.seq ].admit_dt_tm ) ,
;  substring (1 ,300 ,ex_out->rec[d1.seq ].disch_dt_tm ) ,
;  substring (1 ,300 ,ex_out->rec[d1.seq ].mrn_id ) ,
;  substring (1 ,300 ,ex_out->rec[d1.seq ].age ) ,
 substring(1,30,trim(ex_out->rec[d1.seq ].ega))  ,
;  substring (1 ,300 ,ex_out->rec[d1.seq ].g ) ,
;  substring (1 ,300 ,ex_out->rec[d1.seq ].p_full ) ,
;  substring (1 ,300 ,ex_out->rec[d1.seq ].p_term ) ,
;  substring (1 ,300 ,ex_out->rec[d1.seq ].aborh ) ,
;  substring (1 ,300 ,ex_out->rec[d1.seq ].rom ) ,
;  substring (1 ,300 ,ex_out->rec[d1.seq ].rom_type ) ,
;  substring (1 ,300 ,ex_out->rec[d1.seq ].rom_dt_tm ) ,
;  substring (1 ,300 ,ex_out->rec[d1.seq ].induction_ind ) ,
;  substring (1 ,300 ,ex_out->rec[d1.seq ].induction_method ) ,
;  substring (1 ,300 ,ex_out->rec[d1.seq ].aug_method ) ,
substring(1,30, trim(ex_out->rec[d1.seq ].birth_dt_tm )) ,
;  substring (1 ,300 ,ex_out->rec[d1.seq ].del_type ) ,
;  substring (1 ,300 ,ex_out->rec[d1.seq ].cs_indications ) ,
;  substring (1 ,300 ,ex_out->rec[d1.seq ].anes_type ) ,
substring(1,30, trim(ex_out->rec[d1.seq ].neo_outcome )) ,
;  substring (1 ,300 ,ex_out->rec[d1.seq ].epis ) ,
;  substring (1 ,300 ,ex_out->rec[d1.seq ].laceration ) ,
;  substring (1 ,300 ,ex_out->rec[d1.seq ].placenta_dt_tm ) ,
 substring(1,30,trim(ex_out->rec[d1.seq ].sex )) ,
 substring(1,30,trim(ex_out->rec[d1.seq ].weight) ) ,
;  substring (1 ,300 ,ex_out->rec[d1.seq ].apgar_1 ) ,
;  substring (1 ,300 ,ex_out->rec[d1.seq ].apgar_5 ) ,
;  substring (1 ,300 ,ex_out->rec[d1.seq ].apgar_10 ) ,
;  substring (1 ,300 ,ex_out->rec[d1.seq ].apgar_15 ) ,
;  substring (1 ,300 ,ex_out->rec[d1.seq ].apgar_20 ) ,
;  substring (1 ,300 ,ex_out->rec[d1.seq ].fhr_mon ) ,
;  substring (1 ,300 ,ex_out->rec[d1.seq ].uc_mon ) ,
;  substring (1 ,300 ,ex_out->rec[d1.seq ].maternal_compl ) ,
;  substring (1 ,300 ,ex_out->rec[d1.seq ].neonate_comp ) ,
;  substring (1 ,300 ,ex_out->rec[d1.seq ].risk_factors ) ,
;  substring (1 ,300 ,ex_out->rec[d1.seq ].amniotic_desc ) ,
;  substring (1 ,300 ,ex_out->rec[d1.seq ].del_prov ) ,
;  substring (1 ,300 ,ex_out->rec[d1.seq ].asst_phys_1 ) ,
;  substring (1 ,300 ,ex_out->rec[d1.seq ].asst_phys_2 ) ,
;  substring (1 ,300 ,ex_out->rec[d1.seq ].attn_phys ) ,
;  substring (1 ,300 ,ex_out->rec[d1.seq ].ped ) ,
;  substring (1 ,300 ,ex_out->rec[d1.seq ].del_rn_1 ) ,
;  substring (1 ,300 ,ex_out->rec[d1.seq ].del_rn_2 ) ,
;  substring (1 ,300 ,ex_out->rec[d1.seq ].neo_prov ) ,
;  substring (1 ,300 ,ex_out->rec[d1.seq ].resus_rn_1 ) ,
;  substring (1 ,300 ,ex_out->rec[d1.seq ].baby_to ) ,
;  substring (1 ,300 ,ex_out->rec[d1.seq ].mother_to ) ,
;  substring (1 ,300 ,ex_out->rec[d1.seq ].race ) ,
;  substring (1 ,300 ,ex_out->rec[d1.seq ].tobac_use ) ,
;  substring (1 ,300 ,ex_out->rec[d1.seq ].tobac_amt ) ,
;  substring (1 ,300 ,ex_out->rec[d1.seq ].feed_method ) ,
;  substring (1 ,300 ,ex_out->rec[d1.seq ].location ) ,
;  substring (1 ,300 ,ex_out->rec[d1.seq ].diagnosis ) ,
;  substring (1 ,300 ,ex_out->rec[d1.seq ].ebl ) ,
;  substring (1 ,300 ,ex_out->rec[d1.seq ].cbb ) ,
;  substring (1 ,300 ,ex_out->rec[d1.seq ].present_part ) ,
;  substring (1 ,300 ,ex_out->rec[d1.seq ].lab_onset_dt_tm ) ,
;  substring (1 ,300 ,ex_out->rec[d1.seq ].2nd_onset_dt_tm ) ,
;  substring (1 ,300 ,ex_out->rec[d1.seq ].3rd_onset_dt_tm ) ,
;  substring (1 ,300 ,ex_out->rec[d1.seq ].cord_blood_ph ) ,
substrinG(1,30, trim(ex_out->rec[d1.seq ].baby_mrn ))
;  substring (1 ,300 ,ex_out->rec[d1.seq ].labor_room ) ,
;  substring (1 ,300 ,ex_out->rec[d1.seq ].postpart_room ) ,
;  substring (1 ,300 ,ex_out->rec[d1.seq ].previous_cs ) ,
;  substring (1 ,300 ,ex_out->rec[d1.seq ].preg_risk_factors ) ,
;  substring (1 ,300 ,ex_out->rec[d1.seq ].anesthesiologist ) ,
;  substring (1 ,300 ,ex_out->rec[d1.seq ].anesthetist )*/
substring(1,150,(ex_out->rec[d1.seq ].name ))  ,

substring(1,50,(ex_out->rec[d1.seq ].ega )) ,
substring(1,50,(ex_out->rec[d1.seq ].birth_dt_tm )) ,
substring(1,50,(ex_out->rec[d1.seq ].neo_outcome )),
substring(1,50,(ex_out->rec[d1.seq ].sex ))  ,
substring(1,50,(ex_out->rec[d1.seq ].weight))   ,
substring(1,50,(ex_out->rec[d1.seq ].baby_mrn )) ,
substring(1,50,(ex_out->rec[d1.seq ].race )),;SR150201
substring(1,50,(ex_out->rec[d1.seq ].ethnicity ));SR150201

  FROM (dummyt d1 WITH seq = size (ex_out->rec ,5 ) )
 
 ; WITH noheading,nocounter ,format ,separator ="	"
 
	WITH noheading,NOCOUNTER, SEPARATOR=" ", FORMAT, PCFORMAT('"',',',1,0), FORMAT = CRSTREAM
 else
 select into $OUTDEV
 substring(1,150,(ex_out->rec[d1.seq ].name ))  ,

substring(1,50,(ex_out->rec[d1.seq ].ega )) ,
substring(1,50,(ex_out->rec[d1.seq ].birth_dt_tm )) ,
substring(1,50,(ex_out->rec[d1.seq ].neo_outcome )),
substring(1,50,(ex_out->rec[d1.seq ].sex ))  ,
substring(1,50,(ex_out->rec[d1.seq ].weight))   ,
substring(1,50,(ex_out->rec[d1.seq ].baby_mrn )) ,
substring(1,50,(ex_out->rec[d1.seq ].race )),;SR150201
substring(1,50,(ex_out->rec[d1.seq ].ethnicity ));SR150201

  FROM (dummyt d1 WITH seq = size (ex_out->rec ,5 ) )
  
	WITH NOCOUNTER,NOHEADING, SEPARATOR=" ", FORMAT
 endif
 /* declare email_address = vc with constant("shruthi.rama@avmc.org")
    declare email_subject = vc with constant(build2('ENCRYPT - AVH Baby Friendly Results ',format(sysdate,'MM/DD/YYYY;;q')))
    declare email_body = vc with constant('See attached file')
    call sendMail(email_address,email_subject,email_body,filename)
    call dcl(build2('rm $CCLUSERDIR/',filename),size(filename)+15,0) ;remove file from source directory once sent
 
 
  set reply->status_data->status = "S"
 */
 ;end select
 GO TO exit_script
 SUBROUTINE  get_baby_mrn (null )
  SELECT INTO "nl:"
   c_mrn = trim (ea.alias )
   FROM (encntr_encntr_reltn eer ),
    (encntr_alias ea ),
    (encounter e ),
    (person p ),
    (dummyt d1 WITH seq = size (birth_log->rec ,5 ) )
   PLAN (d1 )
    JOIN (eer
    WHERE (eer.encntr_id = birth_log->rec[d1.seq ].encntr_id )
    AND (eer.encntr_reltn_type_cd = cki_newborn_enc ) )
    JOIN (ea
    WHERE (ea.encntr_id = eer.related_encntr_id )
    AND (ea.encntr_alias_type_cd = mrn_cd ) )
    JOIN (e
    WHERE (e.encntr_id = ea.encntr_id ) )
    JOIN (p
    WHERE (p.person_id = e.person_id ) )
   ORDER BY d1.seq ,
    p.birth_dt_tm
   HEAD REPORT
    mrn_cnt = 0
   HEAD d1.seq
    mrn_cnt = 0
   HEAD p.birth_dt_tm
    mrn_cnt = (mrn_cnt + 1 ) ,
    IF ((mrn_cnt <= size (birth_log->rec[d1.seq ].baby ,5 ) ) ) birth_log->rec[d1.seq ].baby[mrn_cnt
     ].baby_mrn = c_mrn ,birth_log->rec[d1.seq ].baby[mrn_cnt ].person_id = p.person_id
    ENDIF
   WITH nocounter
  ;end select
  SELECT INTO "nl:"
   c_mrn = trim (pa.alias )
   FROM (person_person_reltn ppr ),
    (person_alias pa ),
    (person p ),
    (dummyt d1 WITH seq = size (birth_log->rec ,5 ) )
   PLAN (d1 )
    JOIN (ppr
    WHERE (ppr.related_person_id = birth_log->rec[d1.seq ].person_id )
    AND (ppr.person_reltn_cd = cki_mother ) )
    JOIN (pa
    WHERE (pa.person_id = ppr.person_id )
    AND (pa.person_alias_type_cd = pmrn_cd ) )
    JOIN (p
    WHERE (p.person_id = pa.person_id )
    AND (p.birth_dt_tm BETWEEN datetimeadd (cnvtdatetime (birth_log->rec[d1.seq ].baby_1_dt_tm ) ,- (
     7 ) ) AND datetimeadd (cnvtdatetime (birth_log->rec[d1.seq ].baby_1_dt_tm ) ,7 ) ) )
   ORDER BY d1.seq ,
    p.birth_dt_tm
   HEAD REPORT
    mrn_cnt = 0
   HEAD d1.seq
    mrn_cnt = 0
   HEAD p.birth_dt_tm
    mrn_cnt = (mrn_cnt + 1 ) ,
    IF ((mrn_cnt <= size (birth_log->rec[d1.seq ].baby ,5 ) ) )
     IF ((size (trim (birth_log->rec[d1.seq ].baby[mrn_cnt ].baby_mrn ) ) = 0 ) ) birth_log->rec[d1
      .seq ].baby[mrn_cnt ].baby_mrn = c_mrn ,birth_log->rec[d1.seq ].baby[mrn_cnt ].person_id = p
      .person_id
     ENDIF
    ENDIF
   WITH nocounter
  ;end select
  SELECT INTO "nl:"
   FROM (clinical_event ce ),
    (code_value cv ),
    (dummyt d1 WITH seq = size (birth_log->rec ,5 ) ),
    (dummyt d2 WITH seq = 1 )
   PLAN (d1
    WHERE maxrec (d2 ,size (birth_log->rec[d1.seq ].baby ,5 ) ) )
    JOIN (d2 )
    JOIN (ce
    WHERE (ce.person_id = birth_log->rec[d1.seq ].baby[d2.seq ].person_id )
    AND (ce.valid_until_dt_tm > cnvtdatetime (curdate ,curtime3 ) )
    AND (ce.result_status_cd IN (auth ,
    modified ,
    altered ) ) )
    JOIN (cv
    WHERE (cv.code_value = ce.event_cd )
    AND (cv.concept_cki = infant_feeding ) )
   ORDER BY d1.seq ,
    d2.seq ,
    ce.event_end_dt_tm
   DETAIL
    birth_log->rec[d1.seq ].baby[d2.seq ].newborn_feeding = ce.result_val
   WITH nocounter
  ;end select
 END ;Subroutine
 SUBROUTINE  get_tobacco_shx (null )
  DECLARE hx_tob_use_parser = vc WITH protect ,noconstant ("" )
  DECLARE hx_tob_amt_parser = vc WITH protect ,noconstant ("" )
  DECLARE hx_tob_parser = vc WITH protect ,noconstant ("" )
  DECLARE shx_active = f8 WITH protect ,constant (uar_get_code_by_cki ("CKI.CODEVALUE!12883709" ) )
  DECLARE tobacco_use = vc WITH protect ,constant ("CERNER!AE8dDQEX5dTW5YCPCqIGfA" )
  DECLARE tobacco_amount_per_day = vc WITH protect ,constant ("CERNER!AE8dDQEX5dTW5YClCqIGfA" )
  DECLARE tobacco_cd = f8 WITH protect ,constant (uar_get_code_by_cki ("CKI.CODEVALUE!12878798" ) )
  SELECT INTO "nl:"
   ecode = trim (cnvtstring (cv.code_value ) )
   FROM (code_value cv )
   WHERE (cv.concept_cki IN (tobacco_use ,
   tobacco_amount_per_day ) )
   AND (cv.code_set = shx_code_set )
   ORDER BY cv.concept_cki ,
    cv.code_set
   HEAD REPORT
    hx_tob_use_cnt = 0 ,
    hx_tob_amt_cnt = 0 ,
    hx_tob_cnt = 0
   DETAIL
    hx_tob_cnt = (hx_tob_cnt + 1 ) ,
    IF ((hx_tob_cnt = 1 ) ) hx_tob_parser = concat ("sr.task_assay_cd in (" ,ecode )
    ELSE hx_tob_parser = concat (hx_tob_parser ,"," ,ecode )
    ENDIF
    ,
    IF ((cv.concept_cki = tobacco_use ) ) hx_tob_use_cnt = (hx_tob_use_cnt + 1 ) ,
     IF ((hx_tob_use_cnt = 1 ) ) hx_tob_use_parser = concat ("sr.task_assay_cd in (" ,ecode )
     ELSEIF ((hx_tob_use_cnt > 1 ) ) hx_tob_use_parser = concat (hx_tob_use_parser ,"," ,ecode )
     ENDIF
    ELSEIF ((cv.concept_cki = tobacco_amount_per_day ) ) hx_tob_amt_cnt = (hx_tob_amt_cnt + 1 ) ,
     IF ((hx_tob_amt_cnt = 1 ) ) hx_tob_amt_parser = concat ("sr.task_assay_cd in (" ,ecode )
     ELSEIF ((hx_tob_amt_cnt > 1 ) ) hx_tob_amt_parser = concat (hx_tob_amt_parser ,"," ,ecode )
     ENDIF
    ENDIF
   FOOT REPORT
    IF ((hx_tob_use_cnt > 0 ) ) hx_tob_use_parser = concat (hx_tob_use_parser ,")" )
    ENDIF
    ,
    IF ((hx_tob_amt_cnt > 0 ) ) hx_tob_amt_parser = concat (hx_tob_amt_parser ,")" )
    ENDIF
    ,
    IF ((hx_tob_cnt > 0 ) ) hx_tob_parser = concat (hx_tob_parser ,")" )
    ENDIF
   WITH nocounter
  ;end select
  SET error_check = error (errmsg ,0 )
  IF ((error_check != 0 ) )
   CALL errorhandler ("F" ,"Create tobacco use parser" ,errmsg )
  ENDIF
  IF ((hx_tob_use_parser != null )
  AND (hx_tob_amt_parser != null )
  AND (hx_tob_parser != null ) )
   SELECT INTO "nl:"
    dta = trim (uar_get_code_description (sr.task_assay_cd ) ) ,
    sr.task_assay_cd ,
    date = format (sa.perform_dt_tm ,"@SHORTDATETIME" ) ,
    num_response = trim (sr.response_val ) ,
    num_uom = trim (uar_get_code_display (sr.response_unit_cd ) ) ,
    alpha_response =
    IF ((sar.nomenclature_id > 0 ) )
     IF ((trim (n.mnemonic ) > " " ) ) trim (n.mnemonic )
     ELSEIF ((trim (n.source_string ) > " " ) ) trim (n.source_string )
     ENDIF
    ELSEIF ((trim (sar.other_text ) > " " ) ) trim (sar.other_text )
    ENDIF
    FROM (shx_activity sa ),
     (shx_category_ref scr ),
     (shx_response sr ),
     (shx_alpha_response sar ),
     (nomenclature n ),
     (dummyt d1 WITH seq = size (birth_log->rec ,5 ) )
    PLAN (d1 )
     JOIN (sa
     WHERE (sa.person_id = birth_log->rec[d1.seq ].person_id )
     AND (sa.beg_effective_dt_tm > datetimeadd (cnvtdatetime (birth_log->rec[d1.seq ].baby[1 ].
       brth_dt_tm_dq ) ,- (365 ) ) )
     AND (sa.end_effective_dt_tm > cnvtdatetime (curdate ,curtime3 ) )
     AND (sa.perform_dt_tm <= cnvtdatetime (birth_log->rec[d1.seq ].baby[1 ].brth_dt_tm_dq ) )
     AND (sa.active_ind = 1 )
     AND (sa.status_cd = shx_active ) )
     JOIN (scr
     WHERE (scr.shx_category_ref_id = sa.shx_category_ref_id )
     AND (scr.category_cd = tobacco_cd ) )
     JOIN (sr
     WHERE (sr.shx_activity_id = sa.shx_activity_id )
     AND parser (hx_tob_parser ) )
     JOIN (sar
     WHERE (sar.shx_response_id = outerjoin (sr.shx_response_id ) ) )
     JOIN (n
     WHERE (n.nomenclature_id = outerjoin (sar.nomenclature_id ) ) )
    ORDER BY d1.seq ,
     sa.perform_dt_tm DESC
    HEAD REPORT
     report_cnt = 0
    HEAD d1.seq
     report_cnt = 0
    HEAD sa.perform_dt_tm
     report_cnt = (report_cnt + 1 )
    DETAIL
     IF ((report_cnt = 1 ) )
      IF (parser (hx_tob_use_parser ) ) birth_log->rec[d1.seq ].tobacco_use = alpha_response
      ELSEIF (parser (hx_tob_amt_parser ) ) birth_log->rec[d1.seq ].tobacco_amt = num_response
      ENDIF
     ENDIF
    FOOT  sa.perform_dt_tm
     IF ((report_cnt = 1 ) ) birth_log->rec[d1.seq ].tobacco_dt_tm = sa.perform_dt_tm
     ENDIF
    WITH nocounter
   ;end select
   SET error_check = error (errmsg ,0 )
   IF ((error_check != 0 ) )
    CALL errorhandler ("F" ,"Tobacco use from shx data model" ,errmsg )
   ENDIF
  ENDIF
 END ;Subroutine
 SUBROUTINE  get_tobacco_ce (null )
  DECLARE tr_idx = i4 WITH noconstant (0 )
  FREE RECORD tob_rsk
  RECORD tob_rsk (
    1 rec [* ]
      2 code_value = f8
  )
  IF ((tob_use_per_day > 0 ) )
   SET stat = alterlist (tob_rsk->rec ,1 )
   SET tob_rsk->rec[1 ].code_value = tob_use_per_day
  ENDIF
  IF ((tob_last_use > 0 ) )
   SET stat = alterlist (tob_rsk->rec ,(size (tob_rsk->rec ,5 ) + 1 ) )
   SET tob_rsk->rec[size (tob_rsk->rec ,5 ) ].code_value = tob_last_use
  ENDIF
  SELECT INTO "nl:"
   FROM (code_value cv )
   PLAN (cv
    WHERE (cv.code_set = 72 )
    AND (cv.concept_cki = risk_factors_antepartum_current_preg )
    AND (cv.code_value != 0 ) )
   HEAD REPORT
    tr_cnt = size (tob_rsk->rec ,5 )
   DETAIL
    tr_cnt = (tr_cnt + 1 ) ,
    stat = alterlist (tob_rsk->rec ,tr_cnt ) ,
    tob_rsk->rec[tr_cnt ].code_value = cv.code_value
   WITH nocounter
  ;end select
  SELECT INTO "nl:"
   rv = trim (ce.result_val )
   FROM (clinical_event ce ),
    (dummyt d1 WITH seq = size (birth_log->rec ,5 ) )
   PLAN (d1 )
    JOIN (ce
    WHERE (ce.person_id = birth_log->rec[d1.seq ].person_id )
    AND expand (tr_idx ,1 ,size (tob_rsk->rec ,5 ) ,ce.event_cd ,tob_rsk->rec[tr_idx ].code_value )
    AND (ce.event_end_dt_tm > datetimeadd (cnvtdatetime (birth_log->rec[d1.seq ].baby[1 ].
      brth_dt_tm_dq ) ,- (365 ) ) )
    AND (ce.event_end_dt_tm <= cnvtdatetime (birth_log->rec[d1.seq ].baby[1 ].brth_dt_tm_dq ) )
    AND (ce.valid_until_dt_tm > cnvtdatetime (curdate ,curtime3 ) ) )
   ORDER BY d1.seq ,
    ce.event_end_dt_tm DESC
   HEAD REPORT
    report_cnt = 0
   HEAD d1.seq
    report_cnt = 0
   HEAD ce.event_end_dt_tm
    report_cnt = (report_cnt + 1 ) ,
    IF (NOT ((ce.event_cd IN (tob_use_per_day ,
    tob_last_use ) ) ) ) birth_log->rec[d1.seq ].preg_risk_factors = rv
    ENDIF
   DETAIL
    IF ((report_cnt = 1 ) )
     IF ((ce.event_end_dt_tm > cnvtdatetime (birth_log->rec[d1.seq ].tobacco_dt_tm ) ) )
      IF ((ce.event_cd = tob_last_use ) ) birth_log->rec[d1.seq ].tobacco_use = rv
      ELSEIF ((ce.event_cd = tob_use_per_day ) ) birth_log->rec[d1.seq ].tobacco_amt = rv
      ENDIF
     ENDIF
    ENDIF
   FOOT  ce.event_end_dt_tm
    IF ((report_cnt = 1 ) )
     IF ((ce.event_end_dt_tm > cnvtdatetime (birth_log->rec[d1.seq ].tobacco_dt_tm ) ) ) birth_log->
      rec[d1.seq ].tobacco_dt_tm = ce.event_end_dt_tm
     ENDIF
    ENDIF
   WITH nocounter
  ;end select
  SET error_check = error (errmsg ,0 )
  IF ((error_check != 0 ) )
   CALL errorhandler ("F" ,"Tobacco use from Social History control" ,errmsg )
  ENDIF
 END ;Subroutine
 SUBROUTINE  get_patient_ega (null )
 call echo("PM-entered get patient ega")
  FOR (i = 1 TO size (birth_log->rec ,5 ) )
   SET stat = alterlist (ega_request->patient_list ,i )
   SET ega_request->patient_list[i ].patient_id = birth_log->rec[i ].person_id
  ENDFOR
  EXECUTE dcp_get_final_ega WITH replace ("REQUEST" ,ega_request ) ,
  replace ("REPLY" ,ega_reply )
  IF ((ega_reply->status_data.status = "F" ) )
   SET reply->status_data.status = "F"
   SET reply->subeventstatus[1 ].operationname = "Execute"
   SET reply->subeventstatus[1 ].operationstatus = "F"
   SET reply->subeventstatus[1 ].targetobjectname = "dcp_get_final_ega"
   SET reply->subeventstatus[1 ].targetobjectvalue = "fail status returned from dcp_get_final_ega"
  ENDIF
  SET modify = nopredeclare
  FOR (dcp = 1 TO size (ega_reply->gestation_info ,5 ) )
 
   FOR (be = 1 TO size (birth_log->rec ,5 ) )
    IF ((ega_reply->gestation_info[dcp ].person_id = birth_log->rec[be ].person_id ) )
     IF ((birth_log->rec[be ].ega = " " ) )
     
      IF ((ega_reply->gestation_info[dcp ].delivered_ind > 0 ) )
       IF ((ega_reply->gestation_info[dcp ].gest_age_at_delivery <= 0 ) )
        SET birth_log->rec[be ].ega = "0 days"
       ELSEIF ((ega_reply->gestation_info[dcp ].gest_age_at_delivery < 7 ) )
        SET birth_log->rec[be ].ega = build (ega_reply->gestation_info[dcp ].gest_age_at_delivery ,
         " days" )
       ELSEIF ((ega_reply->gestation_info[dcp ].gest_age_at_delivery = 7 ) )
        SET birth_log->rec[be ].ega = "1 week"
       ELSEIF ((mod (ega_reply->gestation_info[dcp ].gest_age_at_delivery ,7 ) = 0 ) )
        SET birth_log->rec[be ].ega = build ((ega_reply->gestation_info[dcp ].gest_age_at_delivery /
         7 ) ," weeks" )
       ELSE
        SET birth_log->rec[be ].ega =
         concat (trim (cnvtstring ((ega_reply->gestation_info[dcp ].
           gest_age_at_delivery / 7 ) ) ) ," " ,trim (cnvtstring (mod (ega_reply->gestation_info[dcp
            ].gest_age_at_delivery ,7 ) ) ) ,"/7 weeks" )
       ENDIF
      ELSE
       IF ((ega_reply->gestation_info[dcp ].current_gest_age <= 0 ) )
        SET birth_log->rec[be ].ega = "0 days"
       ELSEIF ((ega_reply->gestation_info[dcp ].current_gest_age < 7 ) )
        SET birth_log->rec[be ].ega = build (ega_reply->gestation_info[dcp ].current_gest_age ,
         " days" )
       ELSEIF ((ega_reply->gestation_info[dcp ].current_gest_age = 7 ) )
        SET birth_log->rec[be ].ega = "1 week"
       ELSEIF ((mod (ega_reply->gestation_info[dcp ].current_gest_age ,7 ) = 0 ) )
        SET birth_log->rec[be ].ega = build ((ega_reply->gestation_info[dcp ].current_gest_age / 7 )
         ," weeks" )
       ELSE
        SET birth_log->rec[be ].ega = concat (trim (cnvtstring ((ega_reply->gestation_info[dcp ].
           current_gest_age / 7 ) ) ) ," " ,trim (cnvtstring (mod (ega_reply->gestation_info[dcp ].
            current_gest_age ,7 ) ) ) ,"/7 weeks" )
       ENDIF
      ENDIF
     ENDIF
    ENDIF
   ENDFOR
  ENDFOR
  
   
 
  
  FREE RECORD ega_request
  FREE RECORD ega_reply
 END ;Subroutine
 SUBROUTINE  get_mother_diagnosis (null )
  SET actual_size = size (birth_log->rec ,5 )
  SET expand_total = (actual_size + (expand_size - mod (actual_size ,expand_size ) ) )
  SET expand_start = 1
  SET expand_stop = 200
  SET expand_num = 0
  SET stat = alterlist (birth_log->rec ,expand_total )
  FOR (idx = (actual_size + 1 ) TO expand_total )
   SET birth_log->rec[idx ].encntr_id = birth_log->rec[actual_size ].encntr_id
  ENDFOR
  SELECT INTO "nl:"
   diag =
   IF ((size (trim (d.diagnosis_display ) ) > 1 ) ) trim (d.diagnosis_display )
   ELSEIF ((size (trim (d.diag_ftdesc ) ) > 1 ) ) trim (d.diag_ftdesc )
   ELSE trim (n.source_string )
   ENDIF
   FROM (diagnosis d ),
    (nomenclature n ),
    (dummyt d1 WITH seq = value ((expand_total / expand_size ) ) )
   PLAN (d1
    WHERE assign (expand_start ,evaluate (d1.seq ,1 ,1 ,(expand_start + expand_size ) ) )
    AND assign (expand_stop ,(expand_start + (expand_size - 1 ) ) ) )
    JOIN (d
    WHERE expand (expand_num ,expand_start ,expand_stop ,d.encntr_id ,birth_log->rec[expand_num ].
     encntr_id )
    AND (d.active_ind = 1 ) )
    JOIN (n
    WHERE (n.nomenclature_id = d.nomenclature_id ) )
   DETAIL
    pos = locateval (expand_num ,1 ,actual_size ,d.encntr_id ,birth_log->rec[expand_num ].encntr_id
     ) ,
    IF ((birth_log->rec[pos ].diagnosis > " " ) ) birth_log->rec[pos ].diagnosis = concat (birth_log
      ->rec[pos ].diagnosis ,"; " ,trim (diag ) )
    ELSE birth_log->rec[pos ].diagnosis = trim (diag )
    ENDIF
   WITH nocounter
  ;end select
  SET stat = alterlist (birth_log->rec ,actual_size )
  SET error_check = error (errmsg ,0 )
  IF ((error_check != 0 ) )
   CALL errorhandler ("F" ,"Mother diagnosis" ,errmsg )
  ENDIF
  IF ((curqual = 0 ) )
   SET stat = alterlist (birth_log->rec ,actual_size )
  ENDIF
 END ;Subroutine
 SUBROUTINE  get_location_history (null )
  FREE RECORD encntr_loc_hist
  RECORD encntr_loc_hist (
    1 rec [* ]
      2 encntr_id = f8
      2 loc_hist [* ]
        3 beg_effective_dt_tm = dq8
        3 end_effective_dt_tm = dq8
        3 loc_room_cd = f8
        3 loc_room = vc
  )
  SET actual_size = size (birth_log->rec ,5 )
  SET expand_total = (actual_size + (expand_size - mod (actual_size ,expand_size ) ) )
  SET expand_start = 1
  SET expand_stop = 200
  SET expand_num = 0
  SET stat = alterlist (birth_log->rec ,expand_total )
  FOR (idx = (actual_size + 1 ) TO expand_total )
   SET birth_log->rec[idx ].encntr_id = birth_log->rec[actual_size ].encntr_id
  ENDFOR
  SELECT INTO "nl:"
   room = uar_get_code_display (eh.loc_room_cd )
   FROM (encntr_loc_hist eh ),
    (dummyt d WITH seq = value ((expand_total / expand_size ) ) )
   PLAN (d
    WHERE assign (expand_start ,evaluate (d.seq ,1 ,1 ,(expand_start + expand_size ) ) )
    AND assign (expand_stop ,(expand_start + (expand_size - 1 ) ) ) )
    JOIN (eh
    WHERE expand (expand_num ,expand_start ,expand_stop ,eh.encntr_id ,birth_log->rec[expand_num ].
     encntr_id )
    AND (eh.active_ind = 1 ) )
   ORDER BY eh.encntr_id ,
    eh.beg_effective_dt_tm
   HEAD REPORT
    stat = alterlist (birth_log->rec ,actual_size ) ,
    d_cnt = 0 ,
    loc_cnt = 0
   HEAD eh.encntr_id
    d_cnt = (d_cnt + 1 ) ,
    IF ((d_cnt > size (encntr_loc_hist->rec ,5 ) ) ) stat = alterlist (encntr_loc_hist->rec ,(d_cnt
      + 9 ) )
    ENDIF
    ,encntr_loc_hist->rec[d_cnt ].encntr_id = eh.encntr_id ,loc_cnt = 0
   DETAIL
    loc_cnt = (loc_cnt + 1 ) ,
    stat = alterlist (encntr_loc_hist->rec[d_cnt ].loc_hist ,loc_cnt ) ,
    encntr_loc_hist->rec[d_cnt ].loc_hist[loc_cnt ].beg_effective_dt_tm = eh.beg_effective_dt_tm ,
    encntr_loc_hist->rec[d_cnt ].loc_hist[loc_cnt ].end_effective_dt_tm = eh.end_effective_dt_tm ,
    encntr_loc_hist->rec[d_cnt ].loc_hist[loc_cnt ].loc_room_cd = eh.loc_room_cd ,
    encntr_loc_hist->rec[d_cnt ].loc_hist[loc_cnt ].loc_room = room
   FOOT REPORT
    stat = alterlist (encntr_loc_hist->rec ,d_cnt )
   WITH nocounter
  ;end select
  SET error_check = error (errmsg ,0 )
  IF ((error_check != 0 ) )
   CALL errorhandler ("F" ,"Mother Location History" ,errmsg )
  ENDIF
  IF ((curqual = 0 ) )
   SET stat = alterlist (birth_log->rec ,actual_size )
  ELSE
   FOR (bl_cnt = 1 TO size (birth_log->rec ,5 ) )
    FOR (elh_cnt = 1 TO size (encntr_loc_hist->rec ,5 ) )
     IF ((birth_log->rec[bl_cnt ].encntr_id = encntr_loc_hist->rec[elh_cnt ].encntr_id ) )
      FOR (loc_cnt = 1 TO size (encntr_loc_hist->rec[elh_cnt ].loc_hist ,5 ) )
       IF ((birth_log->rec[bl_cnt ].baby[1 ].brth_dt_tm_dq BETWEEN encntr_loc_hist->rec[elh_cnt ].
       loc_hist[loc_cnt ].beg_effective_dt_tm AND encntr_loc_hist->rec[elh_cnt ].loc_hist[loc_cnt ].
       end_effective_dt_tm ) )
        SET birth_log->rec[bl_cnt ].labor_room = encntr_loc_hist->rec[elh_cnt ].loc_hist[loc_cnt ].
        loc_room
        SET birth_log->rec[bl_cnt ].postpart_room = encntr_loc_hist->rec[elh_cnt ].loc_hist[loc_cnt ]
        .loc_room
       ENDIF
       IF ((birth_log->rec[bl_cnt ].mother_to_dq BETWEEN encntr_loc_hist->rec[elh_cnt ].loc_hist[
       loc_cnt ].beg_effective_dt_tm AND encntr_loc_hist->rec[elh_cnt ].loc_hist[loc_cnt ].
       end_effective_dt_tm ) )
        SET birth_log->rec[bl_cnt ].postpart_room = encntr_loc_hist->rec[elh_cnt ].loc_hist[loc_cnt ]
        .loc_room
       ENDIF
      ENDFOR
     ENDIF
    ENDFOR
   ENDFOR
  ENDIF
 END ;Subroutine
 SUBROUTINE  get_mother_demographic (null )
  SELECT INTO "nl:"
   m_name = trim (p.name_full_formatted ) ,
   m_race = uar_get_code_display (p.race_cd ) ,
   m_ethnicity =uar_get_code_display(p.ethnic_grp_cd),;SR
   obgyn_name = trim (pr.name_full_formatted )
   FROM (encounter e ),
    (person p ),
    (person_prsnl_reltn ppr ),
    (prsnl pr ),
    (dummyt d WITH seq = size (birth_log->rec ,5 ) )
   PLAN (d )
    JOIN (e
    WHERE (e.encntr_id = birth_log->rec[d.seq ].encntr_id ) )
    JOIN (p
    WHERE (p.person_id = e.person_id ) )
    JOIN (ppr
    WHERE (ppr.person_id = outerjoin (p.person_id ) )
    AND (ppr.active_ind = outerjoin (1 ) )
    AND (ppr.person_prsnl_r_cd = outerjoin (obgyn_cd ) ) )
    JOIN (pr
    WHERE (pr.person_id = outerjoin (ppr.person_prsnl_reltn_id ) ) )
   DETAIL
    IF ((size (birth_log->rec[d.seq ].baby ,5 ) > 0 ) ) birth_log->rec[d.seq ].mother_name = m_name ,
     birth_log->rec[d.seq ].mother_age =
     IF ((findstring ("Years" ,cnvtage (p.birth_dt_tm ,birth_log->rec[d.seq ].baby[1 ].brth_dt_tm_dq
       ,0 ) ) > 0 ) ) replace (cnvtage (p.birth_dt_tm ,birth_log->rec[d.seq ].baby[1 ].brth_dt_tm_dq
        ,0 ) ," Years" ,"" )
     ENDIF
     ,birth_log->rec[d.seq ].race = m_race ,birth_log->rec[d.seq ].ethnicity = m_ethnicity,birth_log->rec[d.seq ].mother_obgyn = obgyn_name
    ENDIF
   WITH nocounter
   /******************************************************************
; Data - Patient Race Values where multiple values were recorded
*******************************************************************/

 select into "nl:"
  encntr_id = birth_log->rec[d1.seq].encntr_id
 from (dummyt d1 WITH seq = size (birth_log->rec ,5 ) )
      ,person_code_value_r pr
 
 plan d1
 where birth_log->rec[d1.seq].race="Multiple"
 join pr where pr.person_id = birth_log->rec[d1.seq].person_id
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
  birth_log->rec[d1.seq].race = rtxt
 
 with nocounter
 
 
  ;end select
  SET error_check = error (errmsg ,0 )
  IF ((error_check != 0 ) )
   CALL errorhandler ("F" ,"Mother Demographics" ,errmsg )
  ENDIF
 END ;Subroutine
 SUBROUTINE  load_birth_log_rec (null )
 call echo("PM-entered load_birth_log")
  FOR (ce_m = 1 TO size (ce_data_model->mother ,5 ) )
  
  call echo("PM-entered load_birth_log FOR")
   IF ((size (ce_data_model->mother[ce_m ].delivery ,5 ) > 0 ) )
    call echo("PM-entered load_birth_log 1st if")
    SET ce_data_model->mother[ce_m ].baby_1_dt_tm = ce_data_model->mother[ce_m ].delivery[1 ].
    brth_dt_tm_dq
   ENDIF
   FOR (p_m = 1 TO size (preg_data_model->mother ,5 ) )
   call echo("PM-entered load_birth_log 2nd FOR")
   
    IF ((ce_data_model->mother[ce_m ].person_id = preg_data_model->mother[p_m ].person_id ) )
     IF ((size (ce_data_model->mother[ce_m ].delivery ,5 ) > 0 )
     AND (size (preg_data_model->mother[p_m ].delivery ,5 ) > 0 ) )
      IF ((ce_data_model->mother[ce_m ].delivery[1 ].brth_dt_tm_dq = preg_data_model->mother[p_m ].
      baby_1_dt_tm ) )
       SET ce_data_model->mother[ce_m ].prev_cs_ind = preg_data_model->mother[p_m ].prev_csec_ind
       FOR (ce_b = 1 TO size (ce_data_model->mother[ce_m ].delivery ,5 ) )
        IF ((size (preg_data_model->mother[p_m ].delivery ,5 ) >= ce_b ) )
         IF ((preg_data_model->mother[p_m ].delivery[ce_b ].gender > "" ) )
          SET ce_data_model->mother[ce_m ].delivery[ce_b ].sex = preg_data_model->mother[p_m ].
          delivery[ce_b ].gender
         ENDIF
         IF ((preg_data_model->mother[p_m ].delivery[ce_b ].weight > "" ) )
         call echo ("PM-entered load birth rec if weight")
          SET ce_data_model->mother[ce_m ].delivery[ce_b ].birth_wt = preg_data_model->mother[p_m ].
          delivery[ce_b ].weight
         ENDIF
         IF ((preg_data_model->mother[p_m ].delivery[ce_b ].neo_outcome > "" ) )
          SET ce_data_model->mother[ce_m ].delivery[ce_b ].neo_outcome = preg_data_model->mother[p_m
          ].delivery[ce_b ].neo_outcome
         ENDIF
          call echo ("PM-entered load birth rec before if ega")
         IF ((preg_data_model->mother[p_m ].delivery[ce_b ].ega > "" ) )
         call echo ("PM-entered load birth rec if ega")
          SET ce_data_model->mother[ce_m ].delivery[ce_b ].ega = preg_data_model->mother[p_m ].
          delivery[ce_b ].ega
         ENDIF
        ENDIF
       ENDFOR
      ENDIF
     ENDIF
    ENDIF
   ENDFOR
  ENDFOR
  SELECT INTO "nl:"
   sort1 = build (ce_data_model->mother[d1.seq ].baby_1_dt_tm ,ce_data_model->mother[d1.seq ].
    encntr_id ) ,
   format_dt = format (ce_data_model->mother[d1.seq ].delivery[d2.seq ].brth_dt_tm_dq ,
    "@SHORTDATETIME" )
   FROM (dummyt d1 WITH seq = size (ce_data_model->mother ,5 ) ),
    (dummyt d2 WITH seq = 1 )
   PLAN (d1
    WHERE maxrec (d2 ,size (ce_data_model->mother[d1.seq ].delivery ,5 ) ) )
    JOIN (d2 )
   ORDER BY sort1
   HEAD REPORT
    cnt = 0
   HEAD sort1
    numberofbabies = 0 ,cnt = (cnt + 1 ) ,
    IF ((cnt > size (birth_log->rec ,5 ) ) ) stat = alterlist (birth_log->rec ,(cnt + 99 ) )
    ENDIF
    ,birth_log->rec[cnt ].prev_csec_ind = ce_data_model->mother[d1.seq ].prev_cs_ind ,birth_log->rec[
    cnt ].encntr_id = ce_data_model->mother[d1.seq ].encntr_id ,birth_log->rec[cnt ].person_id =
    ce_data_model->mother[d1.seq ].person_id ,birth_log->rec[cnt ].location = ce_data_model->mother[
    d1.seq ].location ,birth_log->rec[cnt ].baby_1_dt_tm = ce_data_model->mother[d1.seq ].
    baby_1_dt_tm
   DETAIL
    IF ((trim (format_dt ,3 ) != "" ) ) numberofbabies = (numberofbabies + 1 ) ,stat = alterlist (
      birth_log->rec[cnt ].baby ,numberofbabies ) ,birth_log->rec[cnt ].presenting_part =
     ce_data_model->mother[d1.seq ].delivery[1 ].presenting_part ,birth_log->rec[cnt ].
     labor_onset_dt_tm = ce_data_model->mother[d1.seq ].delivery[1 ].labor_onset_dt_tm ,birth_log->
     rec[cnt ].aborh = ce_data_model->mother[d1.seq ].delivery[1 ].aborh ,birth_log->rec[cnt ].
     est_blood_loss = ce_data_model->mother[d1.seq ].delivery[1 ].est_blood_loss ,birth_log->rec[cnt
     ].uc_mon = ce_data_model->mother[d1.seq ].delivery[1 ].uc_mon ,birth_log->rec[cnt ].
     amniotic_desc = ce_data_model->mother[d1.seq ].delivery[1 ].amniotic_desc ,birth_log->rec[cnt ].
     neo_prov = ce_data_model->mother[d1.seq ].delivery[1 ].neo_prov ,birth_log->rec[cnt ].episiotomy
      = ce_data_model->mother[d1.seq ].delivery[1 ].episiotomy ,birth_log->rec[cnt ].laceration =
     ce_data_model->mother[d1.seq ].delivery[1 ].laceration ,birth_log->rec[cnt ].g = ce_data_model->
     mother[d1.seq ].delivery[1 ].g ,birth_log->rec[cnt ].p_full_term = ce_data_model->mother[d1.seq
     ].delivery[1 ].p_full_term ,birth_log->rec[cnt ].p_pre_term = ce_data_model->mother[d1.seq ].
     delivery[1 ].p_pre_term ,birth_log->rec[cnt ].mother_to = ce_data_model->mother[d1.seq ].
     delivery[1 ].mother_to ,birth_log->rec[cnt ].mother_to_dq = ce_data_model->mother[d1.seq ].
     delivery[1 ].mother_to_dq ,birth_log->rec[cnt ].anesth_type = ce_data_model->mother[d1.seq ].
     delivery[1 ].anesth_type ,birth_log->rec[cnt ].induct_ind = ce_data_model->mother[d1.seq ].
     delivery[1 ].induct_ind ,birth_log->rec[cnt ].baby[numberofbabies ].sex = ce_data_model->mother[
     d1.seq ].delivery[d2.seq ].sex ,birth_log->rec[cnt ].baby[numberofbabies ].brth_dt_tm =
     format_dt ,birth_log->rec[cnt ].baby[numberofbabies ].brth_dt_tm_dq = ce_data_model->mother[d1
     .seq ].delivery[d2.seq ].brth_dt_tm_dq ,birth_log->rec[cnt ].baby[numberofbabies ].birth_wt =
     ce_data_model->mother[d1.seq ].delivery[d2.seq ].birth_wt ,birth_log->rec[cnt ].baby[
     numberofbabies ].neo_outcome = ce_data_model->mother[d1.seq ].delivery[d2.seq ].neo_outcome ,
     birth_log->rec[cnt ].ega = ce_data_model->mother[d1.seq ].delivery[1 ].ega ,birth_log->rec[cnt ]
     .baby[numberofbabies ].id = ce_data_model->mother[d1.seq ].delivery[d2.seq ].id ,birth_log->rec[
     cnt ].baby[numberofbabies ].rom_del = ce_data_model->mother[d1.seq ].delivery[d2.seq ].rom_del ,
     birth_log->rec[cnt ].baby[numberofbabies ].rom_type = ce_data_model->mother[d1.seq ].delivery[d2
     .seq ].rom_type ,birth_log->rec[cnt ].baby[numberofbabies ].rom_dt_tm = ce_data_model->mother[d1
     .seq ].delivery[d2.seq ].rom_dt_tm ,birth_log->rec[cnt ].baby[numberofbabies ].ind_meth =
     ce_data_model->mother[d1.seq ].delivery[d2.seq ].ind_meth ,birth_log->rec[cnt ].baby[
     numberofbabies ].aug_meth = ce_data_model->mother[d1.seq ].delivery[d2.seq ].aug_meth ,birth_log
     ->rec[cnt ].baby[numberofbabies ].del_type = ce_data_model->mother[d1.seq ].delivery[d2.seq ].
     del_type ,birth_log->rec[cnt ].baby[numberofbabies ].cs_ind = ce_data_model->mother[d1.seq ].
     delivery[d2.seq ].cs_ind ,birth_log->rec[cnt ].baby[numberofbabies ].neo_outcome = ce_data_model
     ->mother[d1.seq ].delivery[d2.seq ].neo_outcome ,birth_log->rec[cnt ].baby[numberofbabies ].
     placenta_dt_tm = ce_data_model->mother[d1.seq ].delivery[d2.seq ].placenta_dt_tm ,birth_log->
     rec[cnt ].baby[numberofbabies ].apgar_1min = ce_data_model->mother[d1.seq ].delivery[d2.seq ].
     apgar_1min ,birth_log->rec[cnt ].baby[numberofbabies ].apgar_5min = ce_data_model->mother[d1
     .seq ].delivery[d2.seq ].apgar_5min ,birth_log->rec[cnt ].baby[numberofbabies ].apgar_10min =
     ce_data_model->mother[d1.seq ].delivery[d2.seq ].apgar_10min ,birth_log->rec[cnt ].baby[
     numberofbabies ].apgar_15min = ce_data_model->mother[d1.seq ].delivery[d2.seq ].apgar_15min ,
     birth_log->rec[cnt ].baby[numberofbabies ].apgar_20min = ce_data_model->mother[d1.seq ].
     delivery[d2.seq ].apgar_20min ,birth_log->rec[cnt ].baby[numberofbabies ].fhr_mon =
     ce_data_model->mother[d1.seq ].delivery[d2.seq ].fhr_mon ,birth_log->rec[cnt ].baby[
     numberofbabies ].del_prov = ce_data_model->mother[d1.seq ].delivery[d2.seq ].del_prov ,birth_log
     ->rec[cnt ].baby[numberofbabies ].baby_to = ce_data_model->mother[d1.seq ].delivery[d2.seq ].
     baby_to ,birth_log->rec[cnt ].baby[numberofbabies ].risk_factors = ce_data_model->mother[d1.seq
     ].delivery[d2.seq ].risk_factors ,birth_log->rec[cnt ].baby[numberofbabies ].pediatrician =
     ce_data_model->mother[d1.seq ].delivery[d2.seq ].pediatrician ,birth_log->rec[cnt ].baby[
     numberofbabies ].neo_compl = ce_data_model->mother[d1.seq ].delivery[d2.seq ].neo_compl ,
     birth_log->rec[cnt ].baby[numberofbabies ].cord_blood_banking = ce_data_model->mother[d1.seq ].
     delivery[d2.seq ].cord_blood_banking ,birth_log->rec[cnt ].baby[numberofbabies ].
     2nd_stage_onset_dt_tm = ce_data_model->mother[d1.seq ].delivery[d2.seq ].2nd_stage_onset_dt_tm ,
     birth_log->rec[cnt ].baby[numberofbabies ].3nd_stage_onset_dt_tm = ce_data_model->mother[d1.seq
     ].delivery[d2.seq ].3nd_stage_onset_dt_tm ,birth_log->rec[cnt ].baby[numberofbabies ].attn_phys
     = ce_data_model->mother[d1.seq ].delivery[d2.seq ].attn_phys ,birth_log->rec[cnt ].baby[
     numberofbabies ].cord_blood_ph = ce_data_model->mother[d1.seq ].delivery[d2.seq ].cord_blood_ph
    ,birth_log->rec[cnt ].baby[numberofbabies ].resus_rn_1 = ce_data_model->mother[d1.seq ].delivery[
     d2.seq ].resus_rn_1 ,birth_log->rec[cnt ].baby[numberofbabies ].asst_phys_1 = ce_data_model->
     mother[d1.seq ].delivery[d2.seq ].asst_phys_1 ,birth_log->rec[cnt ].baby[numberofbabies ].
     asst_phys_2 = ce_data_model->mother[d1.seq ].delivery[d2.seq ].asst_phys_2 ,birth_log->rec[cnt ]
     .baby[numberofbabies ].del_rn_2 = ce_data_model->mother[d1.seq ].delivery[d2.seq ].del_rn_2 ,
     birth_log->rec[cnt ].baby[numberofbabies ].del_rn_1 = ce_data_model->mother[d1.seq ].delivery[d2
     .seq ].del_rn_1 ,birth_log->rec[cnt ].baby[numberofbabies ].mat_compl = ce_data_model->mother[d1
     .seq ].delivery[d2.seq ].mat_compl ,birth_log->rec[cnt ].baby[numberofbabies ].anesthesiologist
     = ce_data_model->mother[d1.seq ].delivery[d2.seq ].anesthesiologist ,birth_log->rec[cnt ].baby[
     numberofbabies ].anesthetist = ce_data_model->mother[d1.seq ].delivery[d2.seq ].anesthetist
    ENDIF
   FOOT REPORT
    stat = alterlist (birth_log->rec ,cnt )
   WITH nocounter
  ;end select
 END ;Subroutine
 SUBROUTINE  get_ce_model_data (null )
  SELECT
   IF ((preg_org_sec_ind = 1 ) )
    FROM (clinical_event ce ),
     (ce_date_result dt ),
     (encounter e ),
     (encntr_loc_hist el ),
     (dummyt d WITH seq = size (preg_data_model->mother ,5 ) )
    PLAN (d
     WHERE (preg_data_model->mother[d.seq ].date_range_ind = 1 ) )
     JOIN (ce
     WHERE (ce.person_id =   preg_data_model->mother[d.seq ].person_id )
     AND expand (e_int ,1 ,size (event_codes->rec ,5 ) ,ce.event_cd ,event_codes->rec[e_int ].
      event_cd )
     AND (cnvtint (format (ce.event_end_dt_tm ,"YYYYMMDD;;D" ) ) BETWEEN cnvtint (format (
       preg_data_model->mother[d.seq ].preg_start_dt_tm ,"YYYYMMDD;;D" ) ) AND cnvtint (format (
       preg_data_model->mother[d.seq ].preg_end_dt_tm ,"YYYYMMDD;;D" ) ) )
     AND (ce.valid_until_dt_tm > cnvtdatetime (curdate ,curtime3 ) )
     AND ((ce.result_status_cd + 0 ) IN (auth ,
     modified ,
     altered ) ) )
     JOIN (dt
     WHERE (dt.event_id = ce.event_id )
     AND ((dt.result_dt_tm + 0 ) >= cnvtdatetime (sdatetime ) )
     AND ((dt.result_dt_tm + 0 ) <= cnvtdatetime (edatetime ) ) )
     JOIN (e
     WHERE (e.encntr_id = ce.encntr_id )
     AND ((e.encntr_id + 0 ) != 0 )
     AND expand (e_idx ,1 ,size (preg_sec_orgs->qual ,5 ) ,e.organization_id ,preg_sec_orgs->qual[
      e_idx ].org_id ) )
     JOIN (el
     WHERE (e.encntr_id = el.encntr_id ) )
   ELSE
    FROM (clinical_event ce ),
     (ce_date_result dt ),
     (encounter e ),
     (encntr_loc_hist el ),
     (dummyt d WITH seq = size (preg_data_model->mother ,5 ) )
    PLAN (d
     WHERE (preg_data_model->mother[d.seq ].date_range_ind = 1 ) )
     JOIN (ce
     WHERE (ce.person_id =      preg_data_model->mother[d.seq ].person_id )
     AND expand (e_int ,1 ,size (event_codes->rec ,5 ) ,ce.event_cd ,event_codes->rec[e_int ].
      event_cd )
     AND (cnvtint (format (ce.event_end_dt_tm ,"YYYYMMDD;;D" ) ) BETWEEN cnvtint (format (
       preg_data_model->mother[d.seq ].preg_start_dt_tm ,"YYYYMMDD;;D" ) ) AND cnvtint (format (
       preg_data_model->mother[d.seq ].preg_end_dt_tm ,"YYYYMMDD;;D" ) ) )
     AND (ce.valid_until_dt_tm > cnvtdatetime (curdate ,curtime3 ) )
     AND ((ce.result_status_cd + 0 ) IN (auth ,
     modified ,
     altered ) ) )
     JOIN (dt
     WHERE (dt.event_id = ce.event_id )
     AND ((dt.result_dt_tm + 0 ) >= cnvtdatetime (sdatetime ) )
     AND ((dt.result_dt_tm + 0 ) <= cnvtdatetime (edatetime ) ) )
     JOIN (e
     WHERE (e.encntr_id = ce.encntr_id )
     AND ((e.encntr_id + 0 ) != 0 ) )
     JOIN (el
     WHERE (e.encntr_id = el.encntr_id ) )
   ENDIF
   ORDER BY ce.encntr_id
   HEAD REPORT
    pec = 0
   HEAD ce.encntr_id
    pec = (pec + 1 ) ,
    IF ((pec > size (ce_data_model->mother ,5 ) ) ) stat = alterlist (ce_data_model->mother ,(pec +
      99 ) )
    ENDIF
    ,ce_data_model->mother[pec ].person_id = ce.person_id ,ce_data_model->mother[pec ].encntr_id = ce
    .encntr_id ,ce_data_model->mother[pec ].organization_id = el.organization_id ,ce_data_model->
    mother[pec ].preg_start_dt_tm = preg_data_model->mother[d.seq ].preg_start_dt_tm ,ce_data_model->
    mother[pec ].preg_end_dt_tm = preg_data_model->mother[d.seq ].preg_end_dt_tm
   FOOT REPORT
    stat = alterlist (ce_data_model->mother ,pec )
   WITH nocounter
  ;end select
  SET error_check = error (errmsg ,0 )
  IF ((error_check != 0 ) )
   CALL errorhandler ("F" ,"clinical event data model search" ,errmsg )
  ENDIF
  IF ((curqual = 0 ) )
   GO TO exit_script
  ENDIF
 END ;Subroutine
 SUBROUTINE  get_ce_model_data_by_org (null )
  SELECT
   IF ((preg_org_sec_ind = 1 ) )
    FROM (clinical_event ce ),
     (ce_date_result dt ),
     (encounter e ),
     (encntr_loc_hist el ),
     (dummyt d WITH seq = size (preg_data_model->mother ,5 ) )
    PLAN (d
     WHERE (preg_data_model->mother[d.seq ].date_range_ind = 1 ) )
     JOIN (ce
     WHERE (ce.person_id = preg_data_model->mother[d.seq ].person_id )
     AND expand (e_int ,1 ,size (event_codes->rec ,5 ) ,ce.event_cd ,event_codes->rec[e_int ].
      event_cd )
     AND (cnvtint (format (ce.event_end_dt_tm ,"YYYYMMDD;;D" ) ) BETWEEN cnvtint (format (
       preg_data_model->mother[d.seq ].preg_start_dt_tm ,"YYYYMMDD;;D" ) ) AND cnvtint (format (
       preg_data_model->mother[d.seq ].preg_end_dt_tm ,"YYYYMMDD;;D" ) ) )
     AND (ce.valid_until_dt_tm > cnvtdatetime (curdate ,curtime3 ) )
     AND ((ce.result_status_cd + 0 ) IN (auth ,
     modified ,
     altered ) ) )
     JOIN (dt
     WHERE (dt.event_id = ce.event_id )
     AND ((dt.result_dt_tm + 0 ) >= cnvtdatetime (sdatetime ) )
     AND ((dt.result_dt_tm + 0 ) <= cnvtdatetime (edatetime ) ) )
     JOIN (e
     WHERE (e.encntr_id = ce.encntr_id )
     AND ((e.encntr_id + 0 ) != 0 ) )
     JOIN (el
     WHERE (e.encntr_id = el.encntr_id )
     AND expand (e_idx ,1 ,size (org->rec ,5 ) ,el.organization_id ,org->rec[e_idx ].organization_id
      )
     AND expand (e_idx ,1 ,size (preg_sec_orgs->qual ,5 ) ,el.organization_id ,preg_sec_orgs->qual[
      e_idx ].org_id )
     AND (dt.result_dt_tm BETWEEN el.beg_effective_dt_tm AND el.end_effective_dt_tm ) )
   ELSE
    FROM (clinical_event ce ),
     (ce_date_result dt ),
     (encounter e ),
     (encntr_loc_hist el ),
     (dummyt d WITH seq = size (preg_data_model->mother ,5 ) )
    PLAN (d
     WHERE (preg_data_model->mother[d.seq ].date_range_ind = 1 ) )
     JOIN (ce
     WHERE (ce.person_id = preg_data_model->mother[d.seq ].person_id )
     AND expand (e_int ,1 ,size (event_codes->rec ,5 ) ,ce.event_cd ,event_codes->rec[e_int ].
      event_cd )
     AND (cnvtint (format (ce.event_end_dt_tm ,"YYYYMMDD;;D" ) ) BETWEEN cnvtint (format (
       preg_data_model->mother[d.seq ].preg_start_dt_tm ,"YYYYMMDD;;D" ) ) AND cnvtint (format (
       preg_data_model->mother[d.seq ].preg_end_dt_tm ,"YYYYMMDD;;D" ) ) )
     AND (ce.valid_until_dt_tm > cnvtdatetime (curdate ,curtime3 ) )
     AND ((ce.result_status_cd + 0 ) IN (auth ,
     modified ,
     altered ) ) )
     JOIN (dt
     WHERE (dt.event_id = ce.event_id )
     AND ((dt.result_dt_tm + 0 ) >= cnvtdatetime (sdatetime ) )
     AND ((dt.result_dt_tm + 0 ) <= cnvtdatetime (edatetime ) ) )
     JOIN (e
     WHERE (e.encntr_id = ce.encntr_id )
     AND ((e.encntr_id + 0 ) != 0 ) )
     JOIN (el
     WHERE (e.encntr_id = el.encntr_id )
     AND expand (e_idx ,1 ,size (org->rec ,5 ) ,el.organization_id ,org->rec[e_idx ].organization_id
      )
     AND (dt.result_dt_tm BETWEEN el.beg_effective_dt_tm AND el.end_effective_dt_tm ) )
   ENDIF
   ORDER BY ce.encntr_id
   HEAD REPORT
    pec = 0
   HEAD ce.encntr_id
    pec = (pec + 1 ) ,
    IF ((pec > size (ce_data_model->mother ,5 ) ) ) stat = alterlist (ce_data_model->mother ,(pec +
      99 ) )
    ENDIF
    ,ce_data_model->mother[pec ].person_id = ce.person_id ,ce_data_model->mother[pec ].encntr_id = ce
    .encntr_id ,ce_data_model->mother[pec ].organization_id = el.organization_id ,ce_data_model->
    mother[pec ].preg_start_dt_tm = preg_data_model->mother[d.seq ].preg_start_dt_tm ,ce_data_model->
    mother[pec ].preg_end_dt_tm = preg_data_model->mother[d.seq ].preg_end_dt_tm
   FOOT REPORT
    stat = alterlist (ce_data_model->mother ,pec )
   WITH nocounter
  ;end select
  SET error_check = error (errmsg ,0 )
  IF ((error_check != 0 ) )
   CALL errorhandler ("F" ,"clinical event data model search" ,errmsg )
  ENDIF
  IF ((curqual = 0 ) )
   GO TO exit_script
  ENDIF
 END ;Subroutine
 SUBROUTINE  get_ce_data (null )
  FREE RECORD event_codes
  RECORD event_codes (
    1 rec [* ]
      2 event_cd = f8
  )
  SELECT INTO "nl:"
   FROM (code_value cv )
   PLAN (cv
    WHERE (cv.concept_cki IN (id_band_num ,
    date_time_of_birth ,
    gender ,
    birth_weight ,
    rom_to_delivery_hours_calc ,
    rom_type ,
    rom_dt_tm ,
    induction_methods ,
    augmentation_methods ,
    delivery_type ,
    reason_for_csection ,
    neonate_outcome ,
    placenta_delivery_date_time ,
    apgar_score_1_minute ,
    apgar_score_5_minute ,
    apgar_score_10_minute ,
    apgar_score_15_minute ,
    apgar_score_20_minute ,
    fhr_monitoring_method ,
    delivery_physician ,
    transferred_to ,
    risk_factors ,
    pediatrician ,
    neonate_complications ,
    cord_blood_banking ,
    2nd_stage_onset_dt_tm ,
    3nd_stage_onset_dt_tm ,
    attending_physician ,
    cord_blood_ph_drawn ,
    resuscitation_rn_1 ,
    maternal_delivery_complications ,
    anesthesiologist_attending_delivery ,
    anesthetist ,
    assistant_physician_1 ,
    delivery_rn_1 ,
    gravida ,
    para_full_term ,
    para_premature ,
    aborh ,
    transfer_to_from ,
    anesthesia_type_ob ,
    estimated_blood_loss ,
    uterine_contraction_monitoring_method ,
    amniotic_fluid_color_description ,
    pediatrician_selected ,
    presenting_part ,
    labor_onset_dt_tm ,
    episiotomy_degree ,
    episiotomy_midline ,
    episiotomy_mediolateral ,
    episiotomy_performed ,
    episiotomy_other_information ,
    perineum_intact ,
    perineum_cervical_laceration ,
    perineum_perineal_laceration ,
    perineum_periurethral_laceration ,
    perineum_superficial_abrasion_laceration ,
    perineum_vaginal_laceration ,
    labial_laceration ,
    indications_for_induction ) )
    AND (cv.code_set = 72 ) )
   HEAD REPORT
    iccki_cnt = 0
   DETAIL
    iccki_cnt = (iccki_cnt + 1 ) ,
    IF ((iccki_cnt > size (event_codes->rec ,5 ) ) ) stat = alterlist (event_codes->rec ,(iccki_cnt
      + 99 ) )
    ENDIF
    ,event_codes->rec[iccki_cnt ].event_cd = cv.code_value
   FOOT REPORT
    stat = alterlist (event_codes->rec ,iccki_cnt )
   WITH nocounter
  ;end select
  SELECT INTO "nl:"
   result_val =
   IF ((uar_get_code_meaning (ce.event_class_cd ) = "TXT" ) ) trim (replace (replace (ce.result_val ,
       char (10 ) ," ; " ) ,char (13 ) ,"" ) )
   ELSE trim (ce.result_val )
   ENDIF
   ,result_dt_tm = format (dt.result_dt_tm ,"@SHORTDATETIME" ) ,
   end_dt_tm = format (ce.event_end_dt_tm ,"@SHORTDATETIME" ) ,
   result_val_uom = concat (trim (ce.result_val ) ," " ,trim (uar_get_code_display (ce
      .result_units_cd ) ) ) ,
   wt =
   IF ((cv.concept_cki = birth_weight ) )
    IF ((ce.result_units_cd = g_cd ) ) ce.result_val
    ELSEIF ((ce.result_units_cd = kg_cd ) ) cnvtstring ((cnvtreal (ce.result_val ) * 1000 ) )
    ELSEIF ((ce.result_units_cd = lb_cd ) ) cnvtstring ((cnvtreal (ce.result_val ) * 453.59237 ) )
    ENDIF
   ENDIF
   ,result_val_uom = concat (trim (ce.result_val ) ," " ,trim (uar_get_code_display (ce
      .result_units_cd ) ) ) ,
   epis_ind =
   IF ((cv.concept_cki IN (episiotomy_degree ,
   episiotomy_midline ,
   episiotomy_mediolateral ,
   episiotomy_performed ,
   episiotomy_other_information ) ) ) 1
   ELSE 0
   ENDIF
   ,lac_ind =
   IF ((cv.concept_cki IN (perineum_intact ,
   perineum_cervical_laceration ,
   perineum_perineal_laceration ,
   perineum_periurethral_laceration ,
   perineum_superficial_abrasion_laceration ,
   perineum_vaginal_laceration ,
   labial_laceration ) ) ) 1
   ELSE 0
   ENDIF
   FROM (clinical_event ce ),
    (ce_dynamic_label ced ),
    (code_value cv ),
    (ce_date_result dt ),
    (dummyt d1 WITH seq = size (ce_data_model->mother ,5 ) )
   PLAN (d1 )
    JOIN (ce
    WHERE (ce.person_id = ce_data_model->mother[d1.seq ].person_id )
    AND (ce.result_status_cd IN (auth ,
    modified ,
    altered ) )
    AND ((ce.valid_until_dt_tm + 0 ) > cnvtdatetime (curdate ,curtime3 ) )
    AND expand (e_int ,1 ,size (event_codes->rec ,5 ) ,(ce.event_cd + 0 ) ,event_codes->rec[e_int ].
     event_cd ) )
    JOIN (ced
    WHERE (ced.ce_dynamic_label_id = ce.ce_dynamic_label_id )
    AND ((ced.valid_until_dt_tm + 0 ) IN (cnvtdatetime ("31-DEC-2100" ) ,
    null ) ) )
    JOIN (cv
    WHERE (cv.code_set = 72 )
    AND (cv.code_value = ce.event_cd ) )
    JOIN (dt
    WHERE (dt.event_id = outerjoin (ce.event_id ) )
    AND (dt.valid_until_dt_tm > outerjoin (cnvtdatetime (curdate ,curtime3 ) ) ) )
   ORDER BY d1.seq ,
    ced.label_name ,
    cv.concept_cki ,
    ce.event_end_dt_tm DESC ,
    ce.clinical_event_id
   HEAD REPORT
    bc = 0 ,
    lac_temp_date = null ,
    epis_temp_date = null ,
    ind_temp_date = null ,
    event_end_date_in_days = 0 ,
    preg_start_date_in_days = 0 ,
    preg_end_date_in_days = 0 ,
    fetch_records_based_dt_tm = null
   HEAD d1.seq
    bc = 0 ,lac_temp_date = null ,epis_temp_date = null ,ind_temp_date = null ,
    preg_start_date_in_days = cnvtint (format (ce_data_model->mother[d1.seq ].preg_start_dt_tm ,
      "YYYYMMDD;;D" ) ) ,preg_end_date_in_days = cnvtint (format (ce_data_model->mother[d1.seq ].
      preg_end_dt_tm ,"YYYYMMDD;;D" ) ) ,
    IF ((cnvtdatetime (edatetime ) > cnvtdatetime (ce_data_model->mother[d1.seq ].preg_end_dt_tm ) )
    ) fetch_records_based_dt_tm = cnvtdatetime (edatetime )
    ELSE fetch_records_based_dt_tm = cnvtdatetime (ce_data_model->mother[d1.seq ].preg_end_dt_tm )
    ENDIF
   HEAD ced.label_name
    IF ((ced.create_dt_tm >= cnvtdatetime (ce_data_model->mother[d1.seq ].preg_start_dt_tm ) )
    AND (ced.create_dt_tm <= cnvtdatetime (fetch_records_based_dt_tm ) ) )
     IF ((ced.ce_dynamic_label_id > 0 ) ) bc = (bc + 1 ) ,stat = alterlist (ce_data_model->mother[d1
       .seq ].delivery ,bc )
     ENDIF
    ENDIF
   HEAD cv.concept_cki
    event_end_date_in_days = cnvtint (format (ce.event_end_dt_tm ,"YYYYMMDD;;D" ) ) ,
    IF ((bc = 0 ) ) stat = alterlist (ce_data_model->mother[d1.seq ].delivery ,1 )
    ENDIF
    ,
    CASE (cv.concept_cki )
     OF gravida :
      ce_data_model->mother[d1.seq ].delivery[bc ].g = result_val
     OF para_full_term :
      ce_data_model->mother[d1.seq ].delivery[bc ].p_full_term = result_val
     OF para_premature :
      ce_data_model->mother[d1.seq ].delivery[bc ].p_pre_term = result_val
    ENDCASE
    ,
    IF ((dt.result_dt_tm >= ce_data_model->mother[d1.seq ].preg_start_dt_tm )
    AND (dt.result_dt_tm <= fetch_records_based_dt_tm ) )
     CASE (cv.concept_cki )
      OF date_time_of_birth :
       ce_data_model->mother[d1.seq ].delivery[bc ].brth_dt_tm = result_dt_tm ,
       ce_data_model->mother[d1.seq ].delivery[bc ].brth_dt_tm_dq = dt.result_dt_tm
      OF rom_dt_tm :
       ce_data_model->mother[d1.seq ].delivery[bc ].rom_dt_tm = result_dt_tm
      OF placenta_delivery_date_time :
       ce_data_model->mother[d1.seq ].delivery[bc ].placenta_dt_tm = result_dt_tm
      OF 2nd_stage_onset_dt_tm :
       ce_data_model->mother[d1.seq ].delivery[bc ].2nd_stage_onset_dt_tm = result_dt_tm
      OF 3nd_stage_onset_dt_tm :
       ce_data_model->mother[d1.seq ].delivery[bc ].3nd_stage_onset_dt_tm = result_dt_tm
      OF labor_onset_dt_tm :
       ce_data_model->mother[d1.seq ].delivery[bc ].labor_onset_dt_tm = result_dt_tm
     ENDCASE
    ENDIF
    ,
    IF ((ce.event_end_dt_tm >= ce_data_model->mother[d1.seq ].preg_start_dt_tm )
    AND (ce.event_end_dt_tm <= fetch_records_based_dt_tm ) )
     CASE (cv.concept_cki )
      OF id_band_num :
       ce_data_model->mother[d1.seq ].delivery[bc ].id = result_val
      OF gender :
       ce_data_model->mother[d1.seq ].delivery[bc ].sex = result_val
      OF birth_weight :
       ce_data_model->mother[d1.seq ].delivery[bc ].birth_wt = wt
      OF rom_to_delivery_hours_calc :
       ce_data_model->mother[d1.seq ].delivery[bc ].rom_del = result_val
      OF rom_type :
       ce_data_model->mother[d1.seq ].delivery[bc ].rom_type = result_val
      OF induction_methods :
       ce_data_model->mother[d1.seq ].delivery[bc ].ind_meth = result_val
      OF augmentation_methods :
       ce_data_model->mother[d1.seq ].delivery[bc ].aug_meth = result_val
      OF delivery_type :
       ce_data_model->mother[d1.seq ].delivery[bc ].del_type = result_val
      OF reason_for_csection :
       ce_data_model->mother[d1.seq ].delivery[bc ].cs_ind = result_val
      OF neonate_outcome :
       ce_data_model->mother[d1.seq ].delivery[bc ].neo_outcome = result_val
      OF apgar_score_1_minute :
       ce_data_model->mother[d1.seq ].delivery[bc ].apgar_1min = result_val
      OF apgar_score_5_minute :
       ce_data_model->mother[d1.seq ].delivery[bc ].apgar_5min = result_val
      OF apgar_score_10_minute :
       ce_data_model->mother[d1.seq ].delivery[bc ].apgar_10min = result_val
      OF apgar_score_15_minute :
       ce_data_model->mother[d1.seq ].delivery[bc ].apgar_15min = result_val
      OF apgar_score_20_minute :
       ce_data_model->mother[d1.seq ].delivery[bc ].apgar_20min = result_val
      OF fhr_monitoring_method :
       ce_data_model->mother[d1.seq ].delivery[bc ].fhr_mon = result_val
      OF delivery_physician :
       ce_data_model->mother[d1.seq ].delivery[bc ].del_prov = result_val
      OF transferred_to :
       ce_data_model->mother[d1.seq ].delivery[bc ].baby_to = result_val
      OF risk_factors :
       ce_data_model->mother[d1.seq ].delivery[bc ].risk_factors = result_val
      OF pediatrician :
       ce_data_model->mother[d1.seq ].delivery[bc ].pediatrician = result_val
      OF neonate_complications :
       ce_data_model->mother[d1.seq ].delivery[bc ].neo_compl = result_val
      OF cord_blood_banking :
       ce_data_model->mother[d1.seq ].delivery[bc ].cord_blood_banking = result_val
      OF attending_physician :
       ce_data_model->mother[d1.seq ].delivery[bc ].attn_phys = result_val
      OF cord_blood_ph_drawn :
       ce_data_model->mother[d1.seq ].delivery[bc ].cord_blood_ph = result_val
      OF resuscitation_rn_1 :
       ce_data_model->mother[d1.seq ].delivery[bc ].resus_rn_1 = result_val
      OF maternal_delivery_complications :
       ce_data_model->mother[d1.seq ].delivery[bc ].mat_compl = result_val
      OF anesthesiologist_attending_delivery :
       ce_data_model->mother[d1.seq ].delivery[bc ].anesthesiologist = result_val
      OF anesthetist :
       ce_data_model->mother[d1.seq ].delivery[bc ].anesthetist = result_val
      OF aborh :
       ce_data_model->mother[d1.seq ].delivery[bc ].aborh = result_val
      OF transfer_to_from :
       ce_data_model->mother[d1.seq ].delivery[bc ].mother_to = result_val ,
       ce_data_model->mother[d1.seq ].delivery[bc ].mother_to_dq = ce.event_end_dt_tm
      OF anesthesia_type_ob :
       ce_data_model->mother[d1.seq ].delivery[bc ].anesth_type = result_val
      OF estimated_blood_loss :
       ce_data_model->mother[d1.seq ].delivery[bc ].est_blood_loss = result_val_uom
      OF uterine_contraction_monitoring_method :
       ce_data_model->mother[d1.seq ].delivery[bc ].uc_mon = result_val
      OF amniotic_fluid_color_description :
       ce_data_model->mother[d1.seq ].delivery[bc ].amniotic_desc = result_val
      OF pediatrician_selected :
       ce_data_model->mother[d1.seq ].delivery[bc ].neo_prov = result_val
      OF presenting_part :
       ce_data_model->mother[d1.seq ].delivery[bc ].presenting_part = result_val
     ENDCASE
    ENDIF
   HEAD cv.cki
    IF ((cv.cki IN (assistant_physician_1_cki ,
    assistant_physician_2_cki ,
    delivery_rn_2_cki ,
    delivery_rn_1_cki ) ) )
     IF ((bc = 0 ) ) stat = alterlist (ce_data_model->mother[d1.seq ].delivery ,1 )
     ENDIF
    ENDIF
    ,
    IF ((ce.event_end_dt_tm >= ce_data_model->mother[d1.seq ].preg_start_dt_tm )
    AND (ce.event_end_dt_tm <= fetch_records_based_dt_tm ) )
     CASE (cv.cki )
      OF assistant_physician_1_cki :
       ce_data_model->mother[d1.seq ].delivery[bc ].asst_phys_1 = result_val
      OF assistant_physician_2_cki :
       ce_data_model->mother[d1.seq ].delivery[bc ].asst_phys_2 = result_val
      OF delivery_rn_2_cki :
       ce_data_model->mother[d1.seq ].delivery[bc ].del_rn_2 = result_val
      OF delivery_rn_1_cki :
       ce_data_model->mother[d1.seq ].delivery[bc ].del_rn_1 = result_val
     ENDCASE
    ENDIF
   HEAD ce.clinical_event_id
    IF ((ce.event_end_dt_tm >= ce_data_model->mother[d1.seq ].preg_start_dt_tm )
    AND (ce.event_end_dt_tm <= fetch_records_based_dt_tm ) )
     IF ((lac_ind = 1 ) )
      IF ((ce.event_end_dt_tm > lac_temp_date ) ) ce_data_model->mother[d1.seq ].delivery[bc ].
       laceration = result_val ,lac_temp_date = ce.event_end_dt_tm
      ELSEIF ((ce.event_end_dt_tm = lac_temp_date ) ) ce_data_model->mother[d1.seq ].delivery[bc ].
       laceration = concat (ce_data_model->mother[d1.seq ].delivery[bc ].laceration ," " ,result_val
        )
      ENDIF
     ENDIF
     ,
     IF ((epis_ind = 1 ) )
      IF ((ce.event_end_dt_tm > epis_temp_date ) ) ce_data_model->mother[d1.seq ].delivery[bc ].
       episiotomy = result_val ,epis_temp_date = ce.event_end_dt_tm
      ELSEIF ((ce.event_end_dt_tm = epis_temp_date ) ) ce_data_model->mother[d1.seq ].delivery[bc ].
       episiotomy = concat (ce_data_model->mother[d1.seq ].delivery[bc ].episiotomy ," " ,result_val
        )
      ENDIF
     ENDIF
     ,
     IF ((cv.concept_cki = indications_for_induction ) )
      IF ((ce.event_end_dt_tm > ind_temp_date ) ) ce_data_model->mother[d1.seq ].delivery[bc ].
       induct_ind = result_val ,ind_temp_date = ce.event_end_dt_tm
      ELSEIF ((ce.event_end_dt_tm = ind_temp_date ) ) ce_data_model->mother[d1.seq ].delivery[bc ].
       induct_ind = concat (ce_data_model->mother[d1.seq ].delivery[bc ].induct_ind ," " ,result_val
        )
      ENDIF
     ENDIF
    ENDIF
   WITH nocounter
  ;end select
  SET error_check = error (errmsg ,0 )
  IF ((error_check != 0 ) )
   CALL errorhandler ("F" ,"clinical event data model search" ,errmsg )
  ENDIF
  SELECT INTO "nl:"
   FROM (organization o ),
    (dummyt d WITH seq = size (ce_data_model->mother ,5 ) )
   PLAN (d )
    JOIN (o
    WHERE (o.organization_id = ce_data_model->mother[d.seq ].organization_id ) )
   DETAIL
    ce_data_model->mother[d.seq ].location = o.org_name
   WITH nocounter
  ;end select
 END ;Subroutine
 SUBROUTINE  get_event_codes (null )
  SELECT INTO "nl:"
   FROM (code_value cv )
   PLAN (cv
    WHERE (cv.code_set = 72 )
    AND (cv.concept_cki = date_time_of_birth ) )
   ORDER BY cv.code_value
   HEAD REPORT
    event_cd_cnt = 0
   HEAD cv.code_value
    event_cd_cnt = (event_cd_cnt + 1 ) ,stat = alterlist (event_codes->rec ,event_cd_cnt ) ,
    event_codes->rec[event_cd_cnt ].event_cd = cv.code_value
   WITH nocounter
  ;end select
  SET error_check = error (errmsg ,0 )
  IF ((error_check != 0 ) )
   CALL errorhandler ("F" ,"Load event codes" ,errmsg )
  ENDIF
 END ;Subroutine
 SUBROUTINE  get_pregnancy_model_data (null )
  SELECT
   sex = uar_get_code_display (pc.gender_cd ) ,
   wt =
   IF ((pc.weight_unit_cd = g_cd ) ) cnvtstring (pc.weight_amt )
   ELSEIF ((pc.weight_unit_cd = kg_cd ) ) cnvtstring ((pc.weight_amt * 1000 ) )
   ELSEIF ((pc.weight_unit_cd = lb_cd ) ) cnvtstring ((pc.weight_amt * 453.59237 ) )
   ENDIF
   ,neo_out = uar_get_code_display (pc.neonate_outcome_cd ) ,
   del_meth = uar_get_code_display (pc.delivery_method_cd ) ,
   v_dt_ind =
   IF ((pc.delivery_dt_tm = null ) ) 1
   ELSEIF ((pc.delivery_dt_tm < cnvtdatetime (sdatetime ) ) ) 0
   ELSEIF ((pc.delivery_dt_tm > cnvtdatetime (edatetime ) ) ) 0
   ELSEIF ((pi.historical_ind = 0 ) ) 1
   ENDIF
   FROM (pregnancy_instance pi ),
    (pregnancy_child pc ),
    (problem pr )
   PLAN (pi
    WHERE (pi.active_ind = 1 )
    AND (pi.pregnancy_id != 0 ))
   ; and pi.person_id in (   13487981.00));PM )
    JOIN (pc
    WHERE (pc.pregnancy_id = pi.pregnancy_id )
    AND (pc.active_ind = 1 )
   AND (pc.delivery_dt_tm BETWEEN cnvtdatetime (sdatetime ) AND cnvtdatetime (edatetime ) ) )
    JOIN (pr
    WHERE (pr.problem_id = pi.problem_id )
    AND (pr.active_ind = 1 ) )
   ORDER BY pi.pregnancy_id ,
    pc.delivery_dt_tm
   HEAD REPORT
    i_preg_cnt = 0 ,
    i_baby_cnt = 0
   HEAD pi.pregnancy_id
    i_preg_cnt = (i_preg_cnt + 1 ) ,
    IF ((i_preg_cnt > size (preg_data_model->mother ,5 ) ) ) stat = alterlist (preg_data_model->
      mother ,(i_preg_cnt + 99 ) )
    ENDIF
    ,preg_data_model->mother[i_preg_cnt ].person_id = pi.person_id ,preg_data_model->mother[
    i_preg_cnt ].pregnancy_id = pi.pregnancy_id ,preg_data_model->mother[i_preg_cnt ].
    preg_start_dt_tm = pr.onset_dt_tm ,preg_data_model->mother[i_preg_cnt ].preg_end_dt_tm = pi
    .preg_end_dt_tm ,preg_data_model->mother[i_preg_cnt ].baby_1_dt_tm = pc.delivery_dt_tm ,
    preg_data_model->mother[i_preg_cnt ].confirmed_dt_tm = pi.confirmed_dt_tm ,
    IF ((v_dt_ind = 1 ) ) preg_data_model->mother[i_preg_cnt ].date_range_ind = 1 ,vd = 1
    ENDIF
    ,i_baby_cnt = 0
   HEAD pc.pregnancy_child_id
    i_baby_cnt = (i_baby_cnt + 1 ) ,stat = alterlist (preg_data_model->mother[i_preg_cnt ].delivery ,
     i_baby_cnt ) ,preg_data_model->mother[i_preg_cnt ].delivery[i_baby_cnt ].pregnancy_child_id = pc
    .pregnancy_child_id ,preg_data_model->mother[i_preg_cnt ].delivery[i_baby_cnt ].gender = sex ,
    preg_data_model->mother[i_preg_cnt ].delivery[i_baby_cnt ].birth_dt_tm = pc.delivery_dt_tm ,
    preg_data_model->mother[i_preg_cnt ].delivery[i_baby_cnt ].del_type = del_meth ,preg_data_model->
    mother[i_preg_cnt ].delivery[i_baby_cnt ].weight = wt ,preg_data_model->mother[i_preg_cnt ].
    delivery[i_baby_cnt ].neo_outcome = neo_out ,
    IF ((pc.gestation_age <= 0 ) ) preg_data_model->mother[i_preg_cnt ].delivery[i_baby_cnt ].ega =
     "0 days"
    ELSEIF ((pc.gestation_age < 7 ) ) preg_data_model->mother[i_preg_cnt ].delivery[i_baby_cnt ].ega
     = build (pc.gestation_age ," days" )
    ELSEIF ((pc.gestation_age = 7 ) ) preg_data_model->mother[i_preg_cnt ].delivery[i_baby_cnt ].ega
     = "1 week"
    ELSEIF ((mod (pc.gestation_age ,7 ) = 0 ) ) preg_data_model->mother[i_preg_cnt ].delivery[
     i_baby_cnt ].ega = build ((pc.gestation_age / 7 ) ," weeks" )
    ELSE preg_data_model->mother[i_preg_cnt ].delivery[i_baby_cnt ].ega = concat (trim (cnvtstring ((
        pc.gestation_age / 7 ) ) ) ," " ,trim (cnvtstring (mod (pc.gestation_age ,7 ) ) ) ,
      "/7 weeks" )
    ENDIF
    ,
    IF ((pc.delivery_method_cd IN (cs_t_inc ,
    cs_low_vertl ,
    cs_low_tran ,
    cs_j_inc ,
    cs ,
    cs_class ,
    cs_vac_assist ,
    cs_unknown ,
    cs_other ,
    cs_frcp_vac ,
    cs_frcp ) ) ) preg_data_model->mother[i_preg_cnt ].cs_ind = 1
    ENDIF
   FOOT  pi.pregnancy_id
    IF ((size (preg_data_model->mother[i_preg_cnt ].delivery ,5 ) = 0 ) ) stat = alterlist (
      preg_data_model->mother[i_preg_cnt ].delivery ,1 )
    ENDIF
   FOOT REPORT
    stat = alterlist (preg_data_model->mother ,i_preg_cnt )
   WITH nocounter
  ;end select
  SET error_check = error (errmsg ,0 )
  IF ((error_check != 0 ) )
   CALL errorhandler ("F" ,"Pregnancy data model search" ,errmsg )
  ENDIF
 END ;Subroutine
 SUBROUTINE  get_clinical_model_data (null )
  SELECT INTO "nl:"
   FROM (pregnancy_instance pi ),
    (problem pr ),
    (clinical_event ce ),
    (ce_date_result cdt ),
    (dummyt d1 WITH seq = size (preg_data_model->mother ,5 ) )
   PLAN (pi
    WHERE (pi.preg_end_dt_tm = cnvtdatetime ("31-DEC-2100" ) )
    AND (pi.active_ind = 1 ) )
    JOIN (pr
    WHERE (pr.problem_id = pi.problem_id )
    AND (pr.active_ind = 1 ) )
    JOIN (ce
    WHERE (ce.person_id = pi.person_id )
    AND expand (e_int ,1 ,size (event_codes->rec ,5 ) ,ce.event_cd ,event_codes->rec[e_int ].event_cd
      )
    AND (ce.valid_until_dt_tm > cnvtdatetime (curdate ,curtime3 ) )
    AND (ce.result_status_cd IN (auth ,
    modified ,
    altered ) ) )
    JOIN (cdt
    WHERE (cdt.event_id = ce.event_id ) ;PM
    AND (cdt.result_dt_tm BETWEEN cnvtdatetime (sdatetime ) AND cnvtdatetime (edatetime ) ) )
    JOIN (d1
    WHERE (ce.person_id != preg_data_model->mother[d1.seq ].person_id ) )
   HEAD REPORT
    i_preg_cnt = size (preg_data_model->mother ,5 )
   HEAD ce.person_id
    i_preg_cnt = (i_preg_cnt + 1 ) ,
    IF ((i_preg_cnt > size (preg_data_model->mother ,5 ) ) ) stat = alterlist (preg_data_model->
      mother ,(i_preg_cnt + 99 ) )
    ENDIF
    ,preg_data_model->mother[i_preg_cnt ].person_id = ce.person_id ,preg_data_model->mother[
    i_preg_cnt ].preg_start_dt_tm = pr.onset_dt_tm ,preg_data_model->mother[i_preg_cnt ].
    preg_end_dt_tm = pi.preg_end_dt_tm ,preg_data_model->mother[i_preg_cnt ].pregnancy_id = pi
    .pregnancy_id ,preg_data_model->mother[i_preg_cnt ].confirmed_dt_tm = pi.confirmed_dt_tm ,
    preg_data_model->mother[i_preg_cnt ].date_range_ind = 1
   FOOT  ce.person_id
    IF ((size (preg_data_model->mother[i_preg_cnt ].delivery ,5 ) = 0 ) ) stat = alterlist (
      preg_data_model->mother[i_preg_cnt ].delivery ,1 )
    ENDIF
   FOOT REPORT
    stat = alterlist (preg_data_model->mother ,i_preg_cnt )
   WITH nocounter
  ;end select
 END ;Subroutine
 SUBROUTINE  get_header (null )
  SELECT INTO "nl:"
   FROM (prsnl p )
   WHERE (p.person_id = reqinfo->updt_id )
   DETAIL
    birth_log->print_user = concat (trim (p.name_first ) ," " ,trim (p.name_last ) )
   WITH nocounter
  ;end select
  SELECT
   IF (( $4 != 0 ) )
    FROM (organization o )
    PLAN (o
     WHERE (o.organization_id IN ( $4 ) )
     AND (o.organization_id != 0 ) )
    HEAD REPORT
     cnt = 0
    DETAIL
     cnt = (cnt + 1 ) ,
     stat = alterlist (org->rec ,cnt ) ,
     org->rec[cnt ].organization_id = o.organization_id ,
     org->rec[cnt ].display = o.org_name ,
     IF ((cnt > 1 ) ) org->display = concat (org->display ,"; " ,trim (o.org_name ) )
     ELSE org->display = trim (o.org_name )
     ENDIF
    FOOT REPORT
     org->count = cnt
    WITH nocounter
   ELSE
   ENDIF
   INTO "nl:"
  ;end select
  IF ((size (org->rec ,5 ) = 0 ) )
   SET all_orgs_flag = 1
   SET org->display = "All Organizations"
  ENDIF
  SET e_date_range = concat (header->date_range ," " ,sdatetime ," - " ,ledatetime )
  SET e_org = concat (header->org ," " ,org->display )
  SET e_print = concat (header->printed_by ," " ,birth_log->print_user ," " ,format (cnvtdatetime (
     curdate ,curtime3 ) ,"@SHORTDATETIME" ) )
 END ;Subroutine
 SUBROUTINE  get_mother_mrn (null )
  SET actual_size = size (birth_log->rec ,5 )
  SET expand_total = (actual_size + (expand_size - mod (actual_size ,expand_size ) ) )
  SET expand_start = 1
  SET expand_stop = 200
  SET expand_num = 0
  SET stat = alterlist (birth_log->rec ,expand_total )
  FOR (idx = (actual_size + 1 ) TO expand_total )
   SET birth_log->rec[idx ].encntr_id = birth_log->rec[actual_size ].encntr_id
  ENDFOR
  SELECT INTO "nl:"
   m_mrn = trim (ea.alias ) ,
   rdt = format (e.reg_dt_tm ,"@SHORTDATETIME" ) ,
   ddt = format (e.disch_dt_tm ,"@SHORTDATETIME" )
   FROM (encounter e ),
    (encntr_alias ea ),
    (dummyt d WITH seq = value ((expand_total / expand_size ) ) )
   PLAN (d
    WHERE assign (expand_start ,evaluate (d.seq ,1 ,1 ,(expand_start + expand_size ) ) )
    AND assign (expand_stop ,(expand_start + (expand_size - 1 ) ) ) )
    JOIN (e
    WHERE expand (expand_num ,expand_start ,expand_stop ,e.encntr_id ,birth_log->rec[expand_num ].
     encntr_id ) )
    JOIN (ea
    WHERE (ea.encntr_id = e.encntr_id )
    AND ((ea.encntr_alias_type_cd + 0 ) = mrn_cd )
    AND (ea.active_ind = 1 ) )
   DETAIL
    pos = locateval (expand_num ,1 ,actual_size ,e.encntr_id ,birth_log->rec[expand_num ].encntr_id
     ) ,
    birth_log->rec[pos ].mother_mrn = m_mrn ,
    birth_log->rec[pos ].mother_reg_dt = rdt ,
    birth_log->rec[pos ].mother_disch_dt_tm = ddt
   WITH nocounter
  ;end select
  SET stat = alterlist (birth_log->rec ,actual_size )
  SET error_check = error (errmsg ,0 )
  IF ((error_check != 0 ) )
   CALL errorhandler ("F" ,"Mother MRN" ,errmsg )
  ENDIF
  IF ((curqual = 0 ) )
   SET stat = alterlist (birth_log->rec ,actual_size )
  ENDIF
 END ;Subroutine
 SUBROUTINE  errorhandler (operationstatus ,targetobjectname ,targetobjectvalue )
  DECLARE error_cnt = i2 WITH private ,noconstant (0 )
  SET error_cnt = size (reply->status_data.subeventstatus ,5 )
  IF ((((error_cnt > 1 ) ) OR ((error_cnt = 1 )
  AND (reply->status_data.subeventstatus[error_cnt ].operationstatus != "" ) )) )
   SET error_cnt = (error_cnt + 1 )
   SET stat = alter (reply->status_data.subeventstatus ,error_cnt )
  ENDIF
  SET reply->status_data.status = "F"
  SET reply->status_data.subeventstatus[error_cnt ].operationname = sscript_name
  SET reply->status_data.subeventstatus[error_cnt ].operationstatus = operationstatus
  SET reply->status_data.subeventstatus[error_cnt ].targetobjectname = targetobjectname
  SET reply->status_data.subeventstatus[error_cnt ].targetobjectvalue = targetobjectvalue
 END ;Subroutine
 
 
 
#exit_script
 FREE RECORD ce_data_model
 FREE RECORD preg_data_model
 FREE RECORD birth_log
 FREE RECORD event_codes
 FREE RECORD org
 FREE RECORD header
 SET script_version = "009 06/05/2015 nk031295"
END GO
 
