/***********************************************************************
 *                  	MODIFICATION CONTROL LOG                       *
 ***********************************************************************
 *                                                                     *
 *MOD DATE     ENGINEER             COMMENT                            *
 *--- -------- -------------------- -----------------------------------*
 *000 xx/xx/xx  Justin Greene (HPG) INITIAL RELEASE		      		   *
 *001 02/12/19  Darrell Hall (HPG)	Modified qualifications dates	   *
 *002 12/27/19  Ron Barus (HPG)     Added ONLINE ACCESS CODE           *
 *003 01/04/22  Shruthi R           #SR-89767						   *
 *004 01/27/22  Shruthi R 			Sorting statements
 *005 06/08/22  Pavan 		         SR-113105 pull missing statements
 *006 01/31/23 Pavan                 SR-116990
 *007 02/22/23  Pavan              Corrected incorrect guarantor address
 ***********************************************************************
 
 ******************  END OF ALL MODCONTROL BLOCKS  ********************/
 
drop program avh_pft_dunning_statement_v2 go
create program avh_pft_dunning_statement_v2
 
prompt
	"Output to File/Printer/MINE" = "MINE"   ;* Enter or select the printer or file name to send this report to.
	, "Start" = "SYSDATE"
	, "End" = "SYSDATE"
 
with OUTDEV, sdt, edt
 
  call echo($sdt)
 call echo($edt)
 
/**************************************************************
; REPLACEMENT
**************************************************************/
 declare s_dt = vc
 declare e_dt = vc
 
 set s_dt = $sdt
 set e_dt = $edt
 
 ;set s_dt = "15-AUG-2019 00:00:00"
 ;set e_dt = "16-AUG-2019 00:00:00"
/**************************************************************
; DVDev DECLARED RECORD STRUCTURES
**************************************************************/
;FREE RECORD PFT
 record pft (
 1 cnt = i4
 1 data [*]
  ; Encounter Details
  2 person_id = f8
  2 encntr_id = f8
  2 pft_encntr_id = f8
  2 acct_id = f8
  2 billing_entity_id = f8
  2 statement_cycle_id = f8
  2 fin = vc
  2 name = vc
  2 prim_health_plan = vc ;003
  2 fap_date = vc ;003
  2 fap_date1 =vc  ;006
  2 fap_date3 =vc ;006
  2 service = vc
  2 service_dates = vc
  2 financial_class = f8
  2 financial_class_vc = vc
 
  ; Bill Information
  2 total_charges = f8
  2 total_charges_vc = vc
  2 insurance_payments = f8
  2 insurance_payments_vc = vc
  2 adjustments = f8
  2 adjustments_vc = vc
  2 patient_payments = f8
  2 patient_payments_vc = vc
  2 payment_due_date = vc
  2 balance_due = f8
  2 balance_due_vc = vc
  2 amount_now_due = f8
  2 amount_now_due_vc = vc
  2 online_access_code = vc
  2 statement_date = vc
  2 dunning_level_cd = f8
  2 dunning_level = vc
  2 payment_plan_ind = i2
  2 payment_plan_flg = i4
  2 statement_number = vc
  2 cycle = f8
  2 cycle_name = vc
  2 statement_cycle = f8
  2 statement_cycle_vc = vc
  2 self_pay_step = i4
  2 message = vc
  2 message2 = vc
  2 statement_message = vc
  2 statement_message2 = vc
  2 guar_person_id = f8
  2 guarantor_name = vc
  2 guarantor_address_1 = vc
  2 guarantor_address_2 = vc
  2 guarantor_address_3 = vc
)
/**************************************************************
; DVDev DECLARED VARIABLES
**************************************************************/
DECLARE ZIPCODE = VC
DECLARE TestDate = DQ8
DECLARE OutDate = DQ8
DECLARE TempMessage = VC
/**************************************************************
; Population
**************************************************************/
 select into "nl:"
 
 from  bill_rec b
     , bill_reltn br
     , pft_encntr pe
	 , pft_proration pp
     , health_plan hp
     , statement_cycle sc
     , encounter e
	 , encntr_alias ea
     , person p
 
 plan b where ( b.submit_dt_tm between cnvtdatetime(s_dt)
    	                         and cnvtdatetime(e_dt)) or
    	                         ( b.beg_effective_dt_tm between cnvtdatetime(s_dt)
    	                         and cnvtdatetime(e_dt));005
 
    	  and b.bill_class_cd = 627735.00	  ;patient statement
    	  and b.active_ind = 1
    	  and b.end_effective_dt_tm > cnvtdatetime(curdate,curtime3)
    	  and b.balance_due!=0.0 ;005
 
 join br where br.corsp_activity_id = b.corsp_activity_id
    	  and br.parent_entity_name = "PFTENCNTR"
 
 join pe where pe.pft_encntr_id = br.parent_entity_id
          ; and pe.payment_plan_status_cd != 662934.00   ;plan paid in full ;005
 
 join pp where pp.pft_encntr_id = pe.pft_encntr_id
    	   and pp.curr_amt_due > 0.00
 
 join hp where hp.health_plan_id = pp.health_plan_id
 
 join sc where sc.statement_cycle_id = pe.statement_cycle_id
           and sc.statement_cycle_cd != 2556436751.00   ;av hospital collections
 
 join e where e.encntr_id = pe.encntr_id
          and e.active_ind = 1
 
 
 
 join ea where ea.encntr_id = e.encntr_id
	       and ea.encntr_alias_type_cd = 1077.00
	       and ea.end_effective_dt_tm > sysdate
	       and ea.active_ind = 1
 
 join p where p.person_id = e.person_id
          and p.active_ind = 1
 
 
 order by sc.statement_cycle_cd ;004
 		  ,e.person_id
         ,e.encntr_id
 
 head report
  cnt = 0
 head e.person_id
  row + 0
 head e.encntr_id
  cnt += 1, stat = alterlist(pft->DATA, cnt)
 
	pft->data[cnt].person_id     = p.person_id
	pft->data[cnt].encntr_id     = pe.encntr_id
	pft->data[cnt].pft_encntr_id = pe.pft_encntr_id
	pft->data[cnt].acct_id       = pe.acct_id
	pft->data[cnt].fin           = trim(substring(1,15,pe.pft_encntr_alias),3)
	;pft->data[cnt].fin           = ea.alias
	pft->data[cnt].service       = trim(uar_get_code_display(e.med_service_cd),3)
    pft->data[cnt].online_access_code = "NONE AVAILABLE"
    pft->data[cnt].billing_entity_id = b.billing_entity_id
    pft->data[cnt].statement_cycle_id = sc.statement_cycle_id
 
	if ( p.name_middle_key != null )
 		pft->data[cnt].name = cnvtupper(concat(trim(p.name_first,3)," ",trim(p.name_middle,3)," ",trim(p.name_last,3)))
 	else
 		pft->data[cnt].name = cnvtupper(concat(trim(p.name_first,3)," ",trim(p.name_last,3)))
 	endif
 
 
 
 
	if ( format(e.disch_dt_tm,"mm/dd/yyyy;;d") = format(e.reg_dt_tm,"mm/dd/yyyy;;d") )
		pft->data[cnt].service_dates = trim(format(e.reg_dt_tm,"mm/dd/yyyy;;d"),3)
	elseif ( e.disch_dt_tm = null )
		pft->data[cnt].service_dates = trim(format(e.reg_dt_tm,"mm/dd/yyyy;;d"),3)
	else
		pft->data[cnt].service_dates = concat(trim(format(e.reg_dt_tm,"mm/dd/yyyy;;d"),3)," - "
										,trim(format(e.disch_dt_tm,"mm/dd/yyyy;;d"),3))
	endif
 
 	pft->data[cnt].financial_class    = hp.financial_class_cd
 	pft->data[cnt].financial_class_vc = uar_get_code_display(hp.financial_class_cd)
 
 if(pp.proration_type_cd=        688358.00 and pp.priority_seq=1) ;005
 pft->data[cnt].prim_health_plan    = hp.plan_name
 endif
 
	pft->data[cnt].dunning_level_cd   = pe.dunning_level_cd
	pft->data[cnt].dunning_level      = uar_get_code_display(pe.dunning_level_cd)
	pft->data[cnt].payment_plan_ind   = if( pe.payment_plan_flag = 2)  1
	                                    else 0
	                                    endif
	pft->data[cnt].statement_cycle    = sc.statement_cycle_cd
	pft->data[cnt].statement_cycle_vc = uar_get_code_display(sc.statement_cycle_cd)
	pft->data[cnt].statement_number   = build(b.bill_nbr_disp)
 
	pft->data[cnt].statement_date     = format(cnvtdatetime($sdt),"mm/dd/yyyy;;d")
 
 
 
	pft->data[cnt].total_charges      = pe.charge_balance
	pft->data[cnt].total_charges_vc   = trim(format(pe.charge_balance,"#############.##;$,"),3)
 
	pft->data[cnt].amount_now_due     = b.balance_due
	pft->data[cnt].amount_now_due_vc  = trim(format(b.balance_due,"#############.##;$,"),3)
 
	pft->data[cnt].balance_due        = pe.pat_bal_fwd
	pft->data[cnt].balance_due_vc     = trim(format(pe.pat_bal_fwd,"#############.##;$,"),3)
 
	pft->data[cnt].adjustments_vc     = "$0.00"
 
	pft->data[cnt].insurance_payments_vc = "$0.00"
 
	pft->data[cnt].patient_payments_vc   = "$0.00"
 
;******************************************
;GENERATE MESSAGES BASED ON STATEMENT CYCLE
;******************************************
 	IF ( SC.STATEMENT_CYCLE_CD = 2556436761.00 )   ;AV Hospital FPP 1
 
 		PFT->DATA[CNT].STATEMENT_MESSAGE = "Agreed payment plan amount due. Thank You."
 
 	ELSEIF ( SC.STATEMENT_CYCLE_CD in ( 2556436771.00  ;AV Hospital FPP 2
 									,2758089767.00;	AV Hospital FPP 3
 									,2758089771.00	;AV Hospital FPP 4
 									,2758089775.00 ));AV Hospital FPP 5) ;003
 
 		PFT->DATA[CNT].STATEMENT_MESSAGE = "Your payment plan is in default. Please remit payment in full today."
 
 	ELSEIF ( SC.STATEMENT_CYCLE_CD IN ( 2556436791.00     ;AV Hospital SP After Ins
 									  , 2556436899.00     ;AV Hospital Trauma CHIP
 									  , 2556436839.00     ;AV Hospital True Self Pay
									  , 2556436849.00 ))  ;AV Hospital True Self Pay 2
 
 		PFT->DATA[CNT].STATEMENT_MESSAGE = "The balance shown is your responsibility and is now due and payable. Please remit payment"
		PFT->DATA[CNT].STATEMENT_MESSAGE = CONCAT(PFT->DATA[CNT].STATEMENT_MESSAGE," in full today or contact the Business Office to")
 		PFT->DATA[CNT].STATEMENT_MESSAGE = CONCAT(PFT->DATA[CNT].STATEMENT_MESSAGE," arrange payment.")
 
 	ELSEIF ( SC.STATEMENT_CYCLE_CD IN ( 2556436801.00     ;AV Hospital Self Pay After Ins 2
 									  , 2556436909.00     ;AV Hospital Trauma CHIP 2
 									  , 2556436919.00     ;AV Hospital Trauma CHIP 3
 									  , 2556436859.00 ))  ;AV Hospital True Self Pay 3
 
 		PFT->DATA[CNT].STATEMENT_MESSAGE = "Your account is past due. The balance shown is your responsibility and is now due"
 		PFT->DATA[CNT].STATEMENT_MESSAGE = CONCAT(PFT->DATA[CNT].STATEMENT_MESSAGE," and payable. Please remit payment in full")
 		PFT->DATA[CNT].STATEMENT_MESSAGE = CONCAT(PFT->DATA[CNT].STATEMENT_MESSAGE," today or contact the Business Office to")
 		PFT->DATA[CNT].STATEMENT_MESSAGE = CONCAT(PFT->DATA[CNT].STATEMENT_MESSAGE," arrange payment.")
 
 	ELSEIF ( SC.STATEMENT_CYCLE_CD IN ( 2556436819.00     ;AV Hospital Self Pay After Ins 3
 									  , 2556436929.00     ;AV Hospital Trauma CHIP 4
 									  , 2556436939.00     ;AV Hospital Trauma CHIP 5
 									  , 2556436869.00     ;AV Hospital True Self Pay 4
 									  , 2556436879.00   ;AV Hospital True Self Pay 5
 									  ,2758089779.00	;AV Hospital Self Pay After Ins 4
 									  ,2758089783.00	;AV Hospital Self Pay After Ins 5
 										));003
 
 
 		PFT->DATA[CNT].STATEMENT_MESSAGE = "The balance on this account is seriously past due. To avoid being assigned to a credit"
 		PFT->DATA[CNT].STATEMENT_MESSAGE = CONCAT(PFT->DATA[CNT].STATEMENT_MESSAGE," reporting collection agency, please remit")
 		PFT->DATA[CNT].STATEMENT_MESSAGE = CONCAT(PFT->DATA[CNT].STATEMENT_MESSAGE," payment in full today or contact the Business")
 		PFT->DATA[CNT].STATEMENT_MESSAGE = CONCAT(PFT->DATA[CNT].STATEMENT_MESSAGE," Office to arrange payment.")
 
 	ELSEIF ( SC.STATEMENT_CYCLE_CD IN ( 2556436781.00     ;AV Hospital FPP Final Notice
 									  , 2556436829.00     ;AV Hospital Self Pay After Ins Final Not
 									  , 2556436949.00     ;AV Hospital Trauma CHIP Final Notice
 									  , 2556436889.00 ))  ;AV Hospital True Self Pay Final Notice
 
 		PFT->DATA[CNT].STATEMENT_MESSAGE = "Final Notice. Your account is being assigned to California Business Bureau, Inc., a credit reporting collection agency."
 		;"Final Notice. Your account is being assigned to a credit reporting collection agency.";003
 
 	ENDIF
 
 	IF ( SC.STATEMENT_CYCLE_CD IN ( 2556436771.00     ;AV Hospital FPP 2
 								  , 2556436819.00     ;AV Hospital Self Pay After Ins 3
 								  , 2556436929.00     ;AV Hospital Trauma CHIP 4
 								  , 2556436939.00     ;AV Hospital Trauma CHIP 5
 								  , 2556436869.00     ;AV Hospital True Self Pay 4
 								  , 2556436879.00     ;AV Hospital True Self Pay 5
 								  , 2556436781.00     ;AV Hospital FPP Final Notice
 								  , 2556436829.00     ;AV Hospital Self Pay After Ins Final Not
 								  , 2556436949.00     ;AV Hospital Trauma CHIP Final Notice
 								  , 2556436889.00 ))  ;AV Hospital True Self Pay Final Notice
 
 		TempMessage = "State and federal law require debt collectors to treat you fairly and prohibit debt collectors"
 		TempMessage = CONCAT(TempMessage," from making false statements or threats of violence, using obscene or profane language,")
 		TempMessage = CONCAT(TempMessage," and making improper communications with third parties, including your employer. Except")
 		TempMessage = CONCAT(TempMessage," under unusual circumstances, debt collectors may not contact you before 8:00 a.m. or")
 		TempMessage = CONCAT(TempMessage," after 9:00 p.m. In general, a debt collector may not give information about your debt")
 		TempMessage = CONCAT(TempMessage," to another person, other than your attorney or spouse. A debt collector may contact")
 		TempMessage = CONCAT(TempMessage," another person to confirm your location or to enforce a judgment. For more information")
 		TempMessage = CONCAT(TempMessage," about debt collection activities, you may contact the Federal Trade Commission by")
 		TempMessage = CONCAT(TempMessage," telephone at 1-877-FTCHELP (382-4357) or online at www.ftc.gov. Non-proft credit")
 		TempMessage = CONCAT(TempMessage," counseling services may be available in the area.")
 
 		PFT->DATA[CNT].STATEMENT_MESSAGE2 = TempMessage
 
 	ENDIF
 
   ;**************************************************************
   ; Dunning  - GENERATE MESSAGES BASED ON DUNNING LEVEL
   ;**************************************************************
	IF ( PE.PAYMENT_PLAN_FLAG = 2 ) ; Formal Payment Plan
 
		IF ( PE.DUNNING_LEVEL_CD IN ( 649880.00   ;Normal # 1
									, 649879.00   ;Normal # 2
									, 649878.00 ));Normal # 3
 
			PFT->DATA[CNT].SELF_PAY_STEP = 1
			PFT->DATA[CNT].MESSAGE = "Agreed Payment Plan amount due. Thank You."
 
 		ELSEIF ( PE.DUNNING_LEVEL_CD IN ( 649877.00   ;Pre - Collections # 1
										, 649884.00 ));Pre - Collections # 2
 
 			PFT->DATA[CNT].SELF_PAY_STEP = 2
 			PFT->DATA[CNT].MESSAGE = "Your payment plan is in default. Please remit payment in full today."
 
 			PFT->DATA[CNT].MESSAGE2 = "State and federal law require debt collectors to treat you fairly and prohibit"
 			PFT->DATA[CNT].MESSAGE2 = CONCAT(PFT->DATA[CNT].MESSAGE2," debt collectors from making false statements or threats")
 			PFT->DATA[CNT].MESSAGE2 = CONCAT(PFT->DATA[CNT].MESSAGE2," of violence, using obscene or profane language, and")
 			PFT->DATA[CNT].MESSAGE2 = CONCAT(PFT->DATA[CNT].MESSAGE2," making improper communications with third parties,")
 			PFT->DATA[CNT].MESSAGE2 = CONCAT(PFT->DATA[CNT].MESSAGE2," including your employer. Except under unusual")
 			PFT->DATA[CNT].MESSAGE2 = CONCAT(PFT->DATA[CNT].MESSAGE2," circumstances, debt collectors may not contact you")
 			PFT->DATA[CNT].MESSAGE2 = CONCAT(PFT->DATA[CNT].MESSAGE2," before 8:00 a.m. or after 9:00 p.m. ln general, a debt")
 			PFT->DATA[CNT].MESSAGE2 = CONCAT(PFT->DATA[CNT].MESSAGE2," collector may not give information about your debt to")
 			PFT->DATA[CNT].MESSAGE2 = CONCAT(PFT->DATA[CNT].MESSAGE2," another person, other than your attorney or spouse. A")
 			PFT->DATA[CNT].MESSAGE2 = CONCAT(PFT->DATA[CNT].MESSAGE2," debt collector may contact another person to confirm")
 			PFT->DATA[CNT].MESSAGE2 = CONCAT(PFT->DATA[CNT].MESSAGE2," your location or to enforce a judgment. For more")
 			PFT->DATA[CNT].MESSAGE2 = CONCAT(PFT->DATA[CNT].MESSAGE2," information about debt collection activities, you may")
 			PFT->DATA[CNT].MESSAGE2 = CONCAT(PFT->DATA[CNT].MESSAGE2," contact the Federal Trade Commission by telephone at")
 			PFT->DATA[CNT].MESSAGE2 = CONCAT(PFT->DATA[CNT].MESSAGE2," 1-877-FTCHELP (382-4357) or online at www.ftc.gov.")
 			PFT->DATA[CNT].MESSAGE2 = CONCAT(PFT->DATA[CNT].MESSAGE2," Non-profit credit counseling services may be available")
 			PFT->DATA[CNT].MESSAGE2 = CONCAT(PFT->DATA[CNT].MESSAGE2," in the area.")
 
 		ELSEIF ( PE.DUNNING_LEVEL_CD IN ( 649883.00   ;Collections # 1
										, 649882.00   ;Collections # 2
										, 649881.00 ));Collections # 3
 
 			PFT->DATA[CNT].SELF_PAY_STEP = 3
 			PFT->DATA[CNT].MESSAGE ="Final Notice. Your account is being assigned to California Business Bureau, Inc., a credit reporting collection agency."
 			; "Final Notice. Your account is being assigned to a credit reporting collection agency." ;003
 
 		ENDIF
 
 	ELSE; PE.PAYMENT_PLAN_FLAG != 2 (Not a Formal Payment Plan)
 
 		IF ( SC.STATEMENT_CYCLE_CD IN ( 2556436761.00   ;AV Hospital FPP 1
									  , 2556436771.00   ;AV Hospital FPP 2t
									  , 2556436781.00   ;AV Hospital FPP Final Notice
									  , 2556436791.00   ;AV Hospital SP After Ins
									  , 2556436801.00   ;AV Hospital Self Pay After Ins 2
									  , 2556436819.00   ;AV Hospital Self Pay After Ins 3
									  , 2556436829.00 ));AV Hospital Self Pay After Ins Final Not
 
 			IF ( PE.DUNNING_LEVEL_CD IN ( 649880.00   ;Normal # 1
									    , 649879.00   ;Normal # 2
									    , 649878.00 ));Normal # 3
 
			  PFT->DATA[CNT].SELF_PAY_STEP = 1
			  PFT->DATA[CNT].MESSAGE = "The balance shown is your responsibility and is now due and payable. Please remit payment"
			  PFT->DATA[CNT].MESSAGE = CONCAT(PFT->DATA[CNT].MESSAGE," in full today or contact the Business Office to arrange payment.")
 
			  PFT->DATA[CNT].MESSAGE2 = "If your family income is less than 350% of the federal poverty level, you may qualify for"
			  PFT->DATA[CNT].MESSAGE2 = CONCAT(PFT->DATA[CNT].MESSAGE2," financial assistance. Please call (661) 949-5781 for more")
			  PFT->DATA[CNT].MESSAGE2 = CONCAT(PFT->DATA[CNT].MESSAGE2," information.")
 
 			ENDIF
 
 		ELSEIF ( SC.STATEMENT_CYCLE_CD IN ( 2556436839.00   ;AV Hospital True Self Pay
										  , 2556436849.00   ;AV Hospital True Self Pay 2
										  , 2556436859.00   ;AV Hospital True Self Pay 3
										  , 2556436869.00   ;AV Hospital True Self Pay 4
										  , 2556436879.00   ;AV Hospital True Self Pay 5
										  , 2556436889.00   ;AV Hospital True Self Pay Final Notice
										  , 2556436899.00   ;AV Hospital Trauma CHIP
										  , 2556436909.00   ;AV Hospital Trauma CHIP 2
										  , 2556436919.00   ;AV Hospital Trauma CHIP 3
										  , 2556436929.00   ;AV Hospital Trauma CHIP 4
										  , 2556436939.00   ;AV Hospital Trauma CHIP 5
										  , 2556436949.00 ));AV Hospital Trauma CHIP Final Notice
 
 			IF ( PE.DUNNING_LEVEL_CD IN ( 649880.00   ;Normal # 1
									, 649879.00   ;Normal # 2
									, 649878.00 ));Normal # 3
 
				PFT->DATA[CNT].SELF_PAY_STEP = 1
				PFT->DATA[CNT].MESSAGE = "The balance shown is your responsibility and is now due and payable. Please remit payment"
				PFT->DATA[CNT].MESSAGE = CONCAT(PFT->DATA[CNT].MESSAGE," in full today or contact the Business Office to arrange payment.")
 
			ELSEIF ( PE.DUNNING_LEVEL_CD = 649877.00 ) ;Pre - Collections # 1
 
 				PFT->DATA[CNT].SELF_PAY_STEP = 2
 				PFT->DATA[CNT].MESSAGE = "The balance shown is your responsibility and is now due and payable. Please remit payment"
				PFT->DATA[CNT].MESSAGE = CONCAT(PFT->DATA[CNT].MESSAGE," in full today or contact the Business Office to arrange payment.")
 
 			ELSEIF ( PE.DUNNING_LEVEL_CD = 649884.00 ) ;Pre - Collections # 2
 
 				PFT->DATA[CNT].SELF_PAY_STEP = 3
 				PFT->DATA[CNT].MESSAGE = "The balance on this account is seriously past due. To avoid being assigned to a credit"
 				PFT->DATA[CNT].MESSAGE = CONCAT(PFT->DATA[CNT].MESSAGE," reporting collection agency, please remit payment in")
 				PFT->DATA[CNT].MESSAGE = CONCAT(PFT->DATA[CNT].MESSAGE," full today or contact the Business Office to arrange")
 				PFT->DATA[CNT].MESSAGE = CONCAT(PFT->DATA[CNT].MESSAGE," payment.")
 
				PFT->DATA[CNT].MESSAGE2 = "State and federal law require debt collectors to treat you fairly and prohibit debt"
				PFT->DATA[CNT].MESSAGE2 = CONCAT(PFT->DATA[CNT].MESSAGE2," collectors from making false statements or threats of")
				PFT->DATA[CNT].MESSAGE2 = CONCAT(PFT->DATA[CNT].MESSAGE2," violence, using obscene or profane language, and")
				PFT->DATA[CNT].MESSAGE2 = CONCAT(PFT->DATA[CNT].MESSAGE2," making improper communications with third parties,")
				PFT->DATA[CNT].MESSAGE2 = CONCAT(PFT->DATA[CNT].MESSAGE2," including your employer. Except under unusual")
				PFT->DATA[CNT].MESSAGE2 = CONCAT(PFT->DATA[CNT].MESSAGE2," circumstances, debt collectors may not contact you")
				PFT->DATA[CNT].MESSAGE2 = CONCAT(PFT->DATA[CNT].MESSAGE2," before 8:00 a.m. or after 9:00 p.m. In general, a")
				PFT->DATA[CNT].MESSAGE2 = CONCAT(PFT->DATA[CNT].MESSAGE2," debt collector may not give information about your")
				PFT->DATA[CNT].MESSAGE2 = CONCAT(PFT->DATA[CNT].MESSAGE2," debt to another person, other than your attorney or")
				PFT->DATA[CNT].MESSAGE2 = CONCAT(PFT->DATA[CNT].MESSAGE2," spouse. A debt collector may contact another person")
				PFT->DATA[CNT].MESSAGE2 = CONCAT(PFT->DATA[CNT].MESSAGE2," to confirm your location or to enforce a judgment.")
				PFT->DATA[CNT].MESSAGE2 = CONCAT(PFT->DATA[CNT].MESSAGE2," For more information about debt collection activities,")
				PFT->DATA[CNT].MESSAGE2 = CONCAT(PFT->DATA[CNT].MESSAGE2," you may contact the Federal Trade Commission by")
				PFT->DATA[CNT].MESSAGE2 = CONCAT(PFT->DATA[CNT].MESSAGE2," telephone at 1-877-FTCHELP (382-4357) or online at")
				PFT->DATA[CNT].MESSAGE2 = CONCAT(PFT->DATA[CNT].MESSAGE2," www.ftc.gov. Non-profit credit counseling services")
				PFT->DATA[CNT].MESSAGE2 = CONCAT(PFT->DATA[CNT].MESSAGE2," may be available in the area.")
 
 			ELSEIF ( PE.DUNNING_LEVEL_CD IN ( 649883.00   ;Collections # 1
											, 649882.00   ;Collections # 2
											, 649881.00 ));Collections # 3
 
 				PFT->DATA[CNT].SELF_PAY_STEP = 4
 				PFT->DATA[CNT].MESSAGE = "Final Notice. Your account is being assigned to California Business Bureau, Inc., a credit reporting collection agency."
 				;"Final Notice. Your account is being assigned to a credit reporting collection agency.";003
 
 			ENDIF
 		ENDIF ; STATEMENT CYCLE
 	ENDIF; PE.PAYMENT_PLAN_FLAG = 2
       pft->data[cnt].cycle = sc.cycle
       pft->data[cnt].cycle_name = sc.cycle_name
 
 	if(pft->data[cnt].self_pay_step = 1) ; payment due in a cycle
  	 if(sc.cycle)
       pft->data[cnt].payment_due_date = format(cnvtdatetime(cnvtdate(cnvtdatetime($sdt))+ sc.cycle,0),"mm/dd/yyyy;;d")
     else
       pft->data[cnt].payment_due_date = format(cnvtdatetime(cnvtdate(cnvtdatetime($sdt))+ 21,0),"mm/dd/yyyy;;d")
     endif
  	elseif(pe.payment_plan_flag = 2); Payment Plan
       pft->data[cnt].payment_due_date = format(cnvtdatetime(cnvtdate(cnvtdatetime($sdt))+ sc.cycle,0),"mm/dd/yyyy;;d")
    elseif(pe.payment_plan_flag != 2)
  	 if(sc.cycle)
       pft->data[cnt].payment_due_date = format(cnvtdatetime(cnvtdate(cnvtdatetime($sdt))+ sc.cycle,0),"mm/dd/yyyy;;d")
     else; Collections
       pft->data[cnt].payment_due_date = "On Receipt"
     endif
    endif
 
 
 
 with nocounter
 
 ;003 begins
 
 /**************************************************************
; Primary Health Plan
**************************************************************/
 
    select into "nl:"
    from (dummyt   d1  with seq = size(pft->data,5))
    	, encntr_plan_reltn   ep
    	, health_plan   hp
 
    plan d1
    join ep where ep.encntr_id = pft->data[d1.seq].encntr_id
    	      and ep.priority_seq =1
    	      and ep.end_effective_dt_tm > sysdate
    	      and ep.active_ind=1
 
    join hp where hp.health_plan_id = ep.health_plan_id
 
 detail
 
     		pft->data[d1.seq].prim_health_plan = hp.plan_name
 
   with nocounter
 
 
 /**************************************************************
; Financial Assistance sent date
**************************************************************/
 
 select
 into "nl:"
    from (dummyt   d1  with seq = size(pft->data,5))
 , bill_rec b
     , bill_reltn br
     , pft_encntr pe
	 , pft_proration pp
     , health_plan hp
     , statement_cycle sc
     , encounter e
	 , encntr_alias ea
     , person p
 
 plan d1
 join  e where e.encntr_id =  pft->data[d1.seq].encntr_id
   and e.active_ind = 1
 join pe where pe.encntr_id = e.encntr_id
  and pe.payment_plan_status_cd != 662934.00   ;plan paid in full
 join br where pe.pft_encntr_id = br.parent_entity_id
    	  and br.parent_entity_name = "PFTENCNTR"
 join b where br.corsp_activity_id = b.corsp_activity_id
    	  and  b.bill_class_cd = 627735.00	  ;patient statement
    	  and b.active_ind = 1
    	  and b.end_effective_dt_tm > cnvtdatetime(curdate,curtime3)
 
 join pp where pp.pft_encntr_id = pe.pft_encntr_id
    	   and pp.curr_amt_due > 0.00
 
 join hp where hp.health_plan_id = pp.health_plan_id
 
 join sc where sc.statement_cycle_id = pe.statement_cycle_id
           and sc.statement_cycle_cd != 2556436751.00   ;av hospital collections
 
 join ea where ea.encntr_id = e.encntr_id
	       and ea.encntr_alias_type_cd = 1077.00
	       and ea.end_effective_dt_tm > sysdate
	       and ea.active_ind = 1
 
 join p where p.person_id = e.person_id
          and p.active_ind = 1
 
 
 order by e.person_id
         ,e.encntr_id
         ,b.gen_dt_tm desc
;head e.encntr_id
detail
 if ( SC.STATEMENT_CYCLE_CD IN ( 2556436781.00     ;AV Hospital FPP Final Notice
 									  , 2556436829.00     ;AV Hospital Self Pay After Ins Final Not
 									  , 2556436949.00     ;AV Hospital Trauma CHIP Final Notice
 									  , 2556436889.00 ) ;AV Hospital True Self Pay Final Notice
									  or
									    PE.DUNNING_LEVEL_CD IN ( 649883.00   ;Collections # 1
										, 649882.00   ;Collections # 2
										, 649881.00 ));Collections # 3
 
    		if(b.gen_dt_tm > cnvtdatetime(cnvtdate(12312021),2359))
     		pft->data[d1.seq].fap_date=format( b.gen_dt_tm,"MM/DD/YYYY")
 
     		endif
     		endif
foot e.encntr_id
if(b.gen_dt_tm > cnvtdatetime(cnvtdate(12312021),2359))
 
 if ( SC.STATEMENT_CYCLE_CD IN ( 2556436781.00     ;AV Hospital FPP Final Notice
 									  , 2556436829.00     ;AV Hospital Self Pay After Ins Final Not
 									  , 2556436949.00     ;AV Hospital Trauma CHIP Final Notice
 									  , 2556436889.00 ) ;AV Hospital True Self Pay Final Notice
									  or
									    PE.DUNNING_LEVEL_CD IN ( 649883.00   ;Collections # 1
										, 649882.00   ;Collections # 2
										, 649881.00 ));Collections # 3
 
 
     		pft->data[d1.seq].fap_date=format( b.gen_dt_tm,"MM/DD/YYYY")
 
 
     		endif
     		endif
 
 with nocounter
 ;003 ends
 
 
 
 ;006
 
 /* Action code date*/
 select into "nl:"
  from (dummyt d1 with seq = size(pft->data,5))
       ,corsp_log_reltn clr
       ,corsp_log cl
       ,long_text lt
 
 
PLAN D1
JOIN clr WHERE clr.pft_encntr_id = PFT->DATA[D1.SEQ].PFT_ENCNTR_ID
	and clr.parent_entity_name="ENCOUNTER"
join cl
where cl.activity_id =clr.activity_id
and cl.corsp_sub_type_cd= 274485825.00
and cl.corsp_type_cd=         10984.00
 join lt
 where lt.long_text_id= cl.long_text_id
 and  lt.long_text like "*Action Code: 307*"
 order by cl.created_dt_tm desc
 
;DETAIL
head clr.pft_encntr_id
 
	pft->data[d1.seq].fap_date1=format( cl.created_dt_tm,"MM/DD/YYYY")
 
	with nocounter
 
 
 
 /* Action code date*/
 select into "nl:"
  from (dummyt d1 with seq = size(pft->data,5))
       ,corsp_log_reltn clr
       ,corsp_log cl
       ,long_text lt
 
 
PLAN D1
JOIN clr WHERE clr.pft_encntr_id = PFT->DATA[D1.SEQ].PFT_ENCNTR_ID
	and clr.parent_entity_name="ENCOUNTER"
join cl
where cl.activity_id =clr.activity_id
and cl.corsp_sub_type_cd= 274485825.00
and cl.corsp_type_cd=         10984.00
 join lt
 where lt.long_text_id= cl.long_text_id
 and  lt.long_text like "*Action Code: 308*"
 order by cl.created_dt_tm
 head report
 cnt=0
DETAIL
cnt=cnt+1
if(cnt=1)
    pft->data[d1.seq].fap_date3 =format( cl.created_dt_tm,"MM/DD/YYYY")
    else
	pft->data[d1.seq].fap_date3=concat( pft->data[d1.seq].fap_date3,if(pft->data[d1.seq].fap_date3!="")", " endif,format( cl.created_dt_tm,"MM/DD/YYYY")  )
	endif
 
 
	with nocounter
 
/**************************************************************
; Guarantor
**************************************************************/
 declare zipcode = vc
 declare ntxt = vc
 
    select into "nl:"
    from (dummyt   d1  with seq = size(pft->data,5))
    	, encntr_person_reltn   ep
    	, person   per
    	, address   a
 
    plan d1
    join ep where ep.encntr_id = pft->data[d1.seq].encntr_id
    	      and ep.person_reltn_type_cd = 1150.00   ;default guarantor
    	      and ep.end_effective_dt_tm > sysdate
    	      and ep.active_ind=1 ; 007
 
    join per where per.person_id = ep.related_person_id
 
    join a   where a.parent_entity_id = per.person_id
    	       and a.address_type_cd = 756.00   ;home
    	       and a.address_type_seq = 1
    	       and a.active_ind = 1
 
    order by ep.encntr_id
    head report
      zipcode = ntxt
 
    head ep.encntr_id
      zipcode = ntxt ; clear zipcode
    ;get guarantor id
    ;*********************
        pft->data[d1.seq].guar_person_id = per.person_id
 
 
     	if(per.name_middle_key != null)
     		pft->data[d1.seq].guarantor_name = cnvtupper(concat(trim(per.name_first,3)," "
     		                                                   ,trim(per.name_middle,3)," "
     		                                                   ,trim(per.name_last,3)))
     	else
     		pft->data[d1.seq].guarantor_name = cnvtupper(concat(trim(per.name_first,3)," "
     		                                                   ,trim(per.name_last,3)))
     	endif
 
    ;get guarantor address
    ;*********************
 
     	zipcode = 	if ( size(trim(a.zipcode_key,3))>5)
    					concat(substring(1,5,a.zipcode_key),"-",substring(6,10,a.zipcode_key))
    				else
    					trim(a.zipcode_key,3)
    				endif
 
     	if ( a.street_addr2 != null )
     		pft->data[d1.seq].guarantor_address_1 = cnvtupper(a.street_addr)
     		pft->data[d1.seq].guarantor_address_2 = cnvtupper(a.street_addr2)
     		pft->data[d1.seq].guarantor_address_3 = concat(trim(a.city,3),", ",trim(uar_get_code_display(a.state_cd),3)," ",zipcode)
     	else
     		pft->data[d1.seq].guarantor_address_1 = cnvtupper(a.street_addr)
     		pft->data[d1.seq].guarantor_address_2 = concat(trim(a.city,3),", ",trim(uar_get_code_display(a.state_cd),3)," ",zipcode)
     	endif
   with nocounter
 
/**************************************************************
; Online Billing Access Code
**************************************************************/
    select into "nl:"
     encntr_id = pft->data[d1.seq].encntr_id
    ,sort = size(build(cbs.guarantor_access_code))
    from (dummyt   d1  with seq = size(pft->data,5))
        , cons_bo_sched cbs
    plan d1
    join cbs where cbs.billing_entity_id  = pft->data[d1.seq].billing_entity_id
               and cbs.person_id          = pft->data[d1.seq].person_id
               ;and cbs.statement_cycle_id = pft->data[d1.seq].statement_cycle_id
 
    order by encntr_id, cbs.person_id, sort desc
 
    head encntr_id
      pft->data[d1.seq].online_access_code = cbs.guarantor_access_code
 
    with nocounter
/**************************************************************/
 
 
    select into "nl:"
     encntr_id = pft->data[d1.seq].encntr_id
    ,sort = size(build(cbs.guarantor_access_code))
    from (dummyt d1 with seq = size(pft->data,5))
         ,cons_bo_sched cbs
    plan d1
 
    join cbs where cbs.person_id = pft->data[d1.seq].guar_person_id
               and cbs.billing_entity_id = pft->data[d1.seq].billing_entity_id
               and cbs.guarantor_access_code > " "
               and cbs.person_id > 0.0
 
    order by  cbs.person_id, encntr_id, sort desc
 
    head cbs.person_id
     row + 0
 
    head encntr_id
 
     if(sort)
      pft->data[d1.seq].online_access_code = cbs.guarantor_access_code
     endif
 
    with nocounter
 
 
  for(xpft = 1 to size(pft->data,5))
   if(pft->data[xpft].online_access_code = "NONE AVAILABLE")
 
       call echo(build(pft->data[xpft].fin
                      ,"|ACCESS_CODE|", pft->data[xpft].online_access_code
                      ,"|PERSON_ID|",pft->data[xpft].person_id
                      ,"|GUARANTOR_PERSON_ID|",pft->data[xpft].guar_person_id
                      ,"|GUARANTOR_NAME|", pft->data[xpft].guarantor_name
                      ;,"|BILLING_ENTITY_ID|",pft->data[xpft].billing_entity_id
                      ,"|"))
 
   endif
 
 
  endfor
 
 
/**************************************************************
; Payment Plan Payment Due Date
**************************************************************/
  declare rtxt = vc
 
    select into "nl:"
     encntr_id = pft->data[d1.seq].encntr_id
    from (dummyt   d1  with seq = size(pft->data,5))
    	, pft_payment_plan   p3
        , pft_pay_plan_pe_reltn p4r
        , pft_encntr pe
 
    plan d1 where pft->data[d1.seq].payment_plan_ind = 1
              and pft->data[d1.seq].payment_due_date != "On Receipt"
 
    join p3 where p3.parent_entity_id = pft->data[d1.seq].guar_person_id
              and p3.end_effective_dt_tm > cnvtdatetime(s_dt)
              and p3.active_ind = 1
 
    join p4r where p4r.pft_payment_plan_id = p3.pft_payment_plan_id
 
    join pe  where pe.pft_encntr_id = p4r.pft_encntr_id
               and pe.encntr_id = pft->data[d1.seq].encntr_id
 
    order by pe.encntr_id, p3.beg_effective_dt_tm desc
 
    head pe.encntr_id
      rtxt = build(format(p3.begin_plan_dt_tm,"dd;;d"),"-",
                   format(cnvtlookahead("1,M"),"mmm-yyyy 00:00:00;;d"))
 
      pft->data[d1.seq].payment_due_date = format(cnvtdatetime(rtxt),"mm/dd/yyyy;;d")
      pft->data[d1.seq].amount_now_due = p3.installment_amount
      pft->data[d1.seq].amount_now_due_vc = trim(format(p3.installment_amount,"#############.##;$,"),3)
    with nocounter
 
 
 
/**************************************************************
; Totals
**************************************************************/
  select into "nl:"
  from (dummyt d1 with seq = size(pft->data,5))
       ,pft_trans_reltn p
       ,trans_log t
 
 
PLAN D1
JOIN P WHERE P.PARENT_ENTITY_ID = PFT->DATA[D1.SEQ].PFT_ENCNTR_ID
	AND P.TRANS_TYPE_CD != 10979.00   ;Charge
	AND P.ACTIVE_IND = 1
JOIN T WHERE T.ACTIVITY_ID = P.ACTIVITY_ID
 
ORDER BY
	P.PARENT_ENTITY_ID
 
DETAIL
 
	IF ( P.TRANS_TYPE_CD = 10978.00 )  ;Adjustment
		IF ( P.DR_CR_FLAG = 2 )
			PFT->DATA[D1.SEQ].ADJUSTMENTS = PFT->DATA[D1.SEQ].ADJUSTMENTS + P.AMOUNT
		ELSEIF ( P.DR_CR_FLAG = 1 )
			PFT->DATA[D1.SEQ].ADJUSTMENTS = PFT->DATA[D1.SEQ].ADJUSTMENTS + ( P.AMOUNT * -1 )
		ENDIF
	ELSEIF ( P.TRANS_TYPE_CD = 10982.00 )  ;Payment
		IF ( T.TRANS_SUB_TYPE_CD IN ( 627128.00, 627140.00, 627141.00 )) ;Commercial insurance payment, Medicaid payment, Medicare payment
			IF ( P.DR_CR_FLAG = 2 )
				PFT->DATA[D1.SEQ].INSURANCE_PAYMENTS = PFT->DATA[D1.SEQ].INSURANCE_PAYMENTS + P.AMOUNT
			ELSEIF ( P.DR_CR_FLAG = 1 )
				PFT->DATA[D1.SEQ].INSURANCE_PAYMENTS = PFT->DATA[D1.SEQ].INSURANCE_PAYMENTS + ( P.AMOUNT * -1 )
			ENDIF
		ELSEIF ( T.TRANS_SUB_TYPE_CD = 627146.00 )  ;Patient payment
			IF ( P.DR_CR_FLAG = 2 )
				PFT->DATA[D1.SEQ].PATIENT_PAYMENTS = PFT->DATA[D1.SEQ].PATIENT_PAYMENTS + P.AMOUNT
			ELSEIF ( P.DR_CR_FLAG = 1 )
				PFT->DATA[D1.SEQ].PATIENT_PAYMENTS = PFT->DATA[D1.SEQ].PATIENT_PAYMENTS + ( P.AMOUNT * -1 )
 			ENDIF
 		ENDIF
 	ENDIF
 
FOOT P.PARENT_ENTITY_ID
 
	IF ( PFT->DATA[D1.SEQ].ADJUSTMENTS > 0 )
		PFT->DATA[D1.SEQ].ADJUSTMENTS_VC = CONCAT("(",TRIM(CNVTSTRING(PFT->DATA[D1.SEQ].ADJUSTMENTS,10,2),3),")")
		PFT->DATA[D1.SEQ].ADJUSTMENTS_VC = CONCAT("(",TRIM(FORMAT(PFT->DATA[D1.SEQ].ADJUSTMENTS,"#############.##;$,"),3),")")
		;CALL ECHO(BUILD(PFT->DATA[D1.SEQ].ADJUSTMENTS_VC," ",SIZE(PFT->DATA[D1.SEQ].ADJUSTMENTS_VC,8)))
		;CALL ECHO(BUILD(PFT->DATA[D1.SEQ].ADJUSTMENTS_VC," ",FORMAT(PFT->DATA[D1.SEQ].ADJUSTMENTS,";$,")))
	ELSEIF ( PFT->DATA[D1.SEQ].ADJUSTMENTS < 0 )
		PFT->DATA[D1.SEQ].ADJUSTMENTS_VC = TRIM(CNVTSTRING(PFT->DATA[D1.SEQ].ADJUSTMENTS,10,2),3)
		PFT->DATA[D1.SEQ].ADJUSTMENTS_VC = TRIM(FORMAT(PFT->DATA[D1.SEQ].ADJUSTMENTS,"#############.##;$,"),3)
	;ELSEIF ( PFT->DATA[D1.SEQ].ADJUSTMENTS IN ( -0.00 , 0.00 ))
		;PFT->DATA[D1.SEQ].ADJUSTMENTS_VC = "$0.00"
	ELSE
		PFT->DATA[D1.SEQ].ADJUSTMENTS_VC = "$0.00"
	ENDIF
 
	IF ( PFT->DATA[D1.SEQ].ADJUSTMENTS_VC = "-$0.00" )
 		PFT->DATA[D1.SEQ].ADJUSTMENTS = 0.00
 		PFT->DATA[D1.SEQ].ADJUSTMENTS_VC = "$0.00"
 	ENDIF
 
	IF ( PFT->DATA[D1.SEQ].INSURANCE_PAYMENTS > 0 )
		PFT->DATA[D1.SEQ].INSURANCE_PAYMENTS_VC = CONCAT("(",TRIM(CNVTSTRING(PFT->DATA[D1.SEQ].INSURANCE_PAYMENTS,10,2),3),")")
		PFT->DATA[D1.SEQ].INSURANCE_PAYMENTS_VC =
			CONCAT("(",TRIM(FORMAT(PFT->DATA[D1.SEQ].INSURANCE_PAYMENTS,"#############.##;$,"),3),")")
	ELSEIF ( PFT->DATA[D1.SEQ].INSURANCE_PAYMENTS < 0 )
		PFT->DATA[D1.SEQ].INSURANCE_PAYMENTS_VC = TRIM(CNVTSTRING(PFT->DATA[D1.SEQ].INSURANCE_PAYMENTS,10,2),3)
		PFT->DATA[D1.SEQ].INSURANCE_PAYMENTS_VC = TRIM(FORMAT(PFT->DATA[D1.SEQ].INSURANCE_PAYMENTS,"#############.##;$,"),3)
	ELSE
		PFT->DATA[D1.SEQ].INSURANCE_PAYMENTS_VC = "$0.00"
	ENDIF
 
	IF ( PFT->DATA[D1.SEQ].INSURANCE_PAYMENTS_VC = "-$0.00" )
 		PFT->DATA[D1.SEQ].INSURANCE_PAYMENTS = 0.00
 		PFT->DATA[D1.SEQ].INSURANCE_PAYMENTS_VC = "$0.00"
 	ENDIF
 
	IF ( PFT->DATA[D1.SEQ].PATIENT_PAYMENTS > 0 )
		PFT->DATA[D1.SEQ].PATIENT_PAYMENTS_VC = CONCAT("(",TRIM(CNVTSTRING(PFT->DATA[D1.SEQ].PATIENT_PAYMENTS,10,2),3),")")
		PFT->DATA[D1.SEQ].PATIENT_PAYMENTS_VC = CONCAT("(",TRIM(FORMAT(PFT->DATA[D1.SEQ].PATIENT_PAYMENTS,"#############.##;$,"),3),")")
	ELSEIF ( PFT->DATA[D1.SEQ].PATIENT_PAYMENTS < 0 )
		PFT->DATA[D1.SEQ].PATIENT_PAYMENTS_VC = TRIM(CNVTSTRING(PFT->DATA[D1.SEQ].PATIENT_PAYMENTS,10,2),3)
		PFT->DATA[D1.SEQ].PATIENT_PAYMENTS_VC = TRIM(FORMAT(PFT->DATA[D1.SEQ].PATIENT_PAYMENTS,"#############.##;$,"),3)
	ELSE
		PFT->DATA[D1.SEQ].PATIENT_PAYMENTS_VC = "$0.00"
	ENDIF
 
	IF ( PFT->DATA[D1.SEQ].PATIENT_PAYMENTS_VC = "-$0.00" )
 		PFT->DATA[D1.SEQ].PATIENT_PAYMENTS = 0.00
 		PFT->DATA[D1.SEQ].PATIENT_PAYMENTS_VC = "$0.00"
 	ENDIF
 
WITH NOCOUNTER
 
call echorecord(PFT)
; select into "avh_text_file.txt"
;  encntr_id = pft->data[d1.seq].encntr_id
; ,person_id = pft->data[d1.seq].person_id
; ,fin = substring(1,12,pft->data[d1.seq].fin)
; ,name = substring(1,60,pft->data[d1.seq].name)
; ,guar = substring(1,60,pft->data[d1.seq].guarantor_name)
; ,guar_id = pft->data[d1.seq].guar_person_id
; ,self_pay = pft->data[d1.seq].self_pay_step
; ,payment_plan = pft->data[d1.seq].payment_plan_ind
; ,payment_due = substring(1,20,pft->data[d1.seq].payment_due_date)
; ,cycle = pft->data[d1.seq].cycle
;; ,cycle_name = substring(1,50,pft->data[d1.seq].cycle_name)
;
; ,statement_cycle = pft->data[d1.seq].statement_cycle
; ,statement_cycle_vc = substring(1,50,pft->data[d1.seq].statement_cycle_vc)
; ,amount_due = pft->data[d1.seq].amount_now_due
; ,p3.installment_amount
; ,p3.current_period_start_dt_tm "mm/dd/yyyy;;d"
; ,p3.due_day
; ,p3.begin_plan_dt_tm  "mm/dd/yyyy;;d"
; from (dummyt d1 with seq = size(pft->data,5))
;      ,dummyt d2
;        ,pft_payment_plan p3
;      ,dummyt d3
;        , pft_pay_plan_pe_reltn p4r
;      ,dummyt d4
;        , pft_encntr pe
; plan d1
; join d2
; join p3 where p3.parent_entity_id = outerjoin(pft->data[d1.seq].guar_person_id)
;           and p3.active_ind = outerjoin(1)
;
;
;
; join d3
;    join p4r where p4r.pft_payment_plan_id = outerjoin(p3.pft_payment_plan_id)
; join d4
;    join pe  where pe.pft_encntr_id = outerjoin(p4r.pft_encntr_id)
;               and pe.encntr_id = outerjoin(pft->data[d1.seq].encntr_id)
;
; order by person_id, encntr_id
; WITH format, outerjoin = d2, outerjoin = d3, outerjoin = d4,
;     format = stream,
;     pcformat('"',',',1),
;     nocounter
end
go
 
;EXECUTE AVH_PFT_DUNNING_STATEMENT GO
