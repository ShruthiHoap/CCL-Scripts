drop program anterxreq01:dba go
create program anterxreq01:dba
 
/*~BB~************************************************************************
  *                                                                      *
  *  Copyright Notice:  (c) 1983 Laboratory Information Systems &        *
  *                              Technology, Inc.                        *
  *       Revision      (c) 1984-2003 Cerner Corporation                 *
  *                                                                      *
  *  Cerner (R) Proprietary Rights Notice:  All rights reserved.         *
  *  This material contains the valuable properties and trade secrets of *
  *  Cerner Corporation of Kansas City, Missouri, United States of       *
  *  America (Cerner), embodying substantial creative efforts and        *
  *  confidential information, ideas and expressions, no part of which   *
  *  may be reproduced or transmitted in any form or by any means, or    *
  *  retained in any storage or retrieval system without the express     *
  *  written permission of Cerner.                                       *
  *                                                                      *
  *  Cerner is a registered mark of Cerner Corporation.                  *
  *                                                                      *
  ~BE~***********************************************************************/
/*****************************************************************************
 
        Source file name:       RXREQGEN03.PRG
        Object name:            RXREQGEN03
        Task #:                 NA
        Request #:              NA
 
        Product:                EasyScript (Rx printing)
        Product Team:           PowerChart Office
        HNA Version:            500
        CCL Version:            4.0
 
        Program purpose:        Print/Fax Rx requisitions
 
        Special Notes:          Generic script based off of TMMC_FL_PCORXRECGEN,
                                written by Steven Farmer.
 
******************************************************************************/
;~DB~************************************************************************
;    *                      GENERATED MODIFICATION CONTROL LOG              *
;    ************************************************************************
;    *                                                                      *
;    *Mod Date     Engineer Comment                                         *
;    *--- -------- -------- ----------------------------------------------- *
;     000 02/11/03 JF8275   Initial Release                                 *
;     001 05/21/03 SF3151   Correct Drug Sorting                            *
;     002 06/09/03 SF3151   Validate Don't Print detail is valued           *
;     003 06/10/03 SF3151   1) Print COMPLETE orders                        *
;                           2) Print STREET_ADDR2 for patient               *
;                           3) Remove Re-print indicator                    *
;     004 06/17/03 SF3151   Throw error if can't find CSA_SCHEDULE          *
;     005 06/23/03 SF3151   Correct Phone Format                            *
;     006 07/02/03 SF3151   Correct Multum table check                      *
;     007 12/10/03 BP9613   Replacing Dispense Duration to Dispense when    *
;							necessary.          *
;     008 12/29/03 JF8275   Fix defects CAPEP00113087 and CAPEP00112906     *
;     009 01/09/04 JF8275   Added fix for volume dose                       *
;     010 01/14/04 JF8275   Group Misc. Meds individually by csa_group      *
;     011 04/02/04 BP9613   Ordering on the correct parameter               *
;     012 04/08/04 BP9613   Printing all meds on seperate pages             *
;     013 07/09/04 IT010631 Refill and Mid-level enahncement changes        *
;     014 07/16/04 PC3603   Fix refill/renew issues                         *
;     015 08/25/04 PC3603   Subtract one from additional refill field because
;                           it was incremented when it was refilled         *
;     016 01/07/05 BP9613   Front end printing enhancement change:          *
;                           Ordering the print jobs for one printer call    *
;                           while still grouping the fax jobs the same      *
;     017 04/04/05 SF3151   Access Righs                                    *
;     018 04/08/05 SF3151   Traverse prsnl_orgs org list correctly          *
;     019 04/11/05 SF3151   Handle getting prsnl_org org list correctly     *
;     020 10/14/05 KS012546 Printing does not occur on the complete action for orders     *
;                           		that are not one times.                         *
;     021 02/02/06 KS012546 Requisitions no longer print "PRN" on SIG line  *
;                           after PRN instructions removed.			        *
;	  022 02/13/06 MJ6234   Selecting from frequency schedule is done using *
;							dummyt table instead of expand function.		*
;     023 02/22/07 AC013650 Time stamps added to determine if an order with *
;                           a complete action should be printed             *
;	  024 05/24/07 RD012555 Changed naming convention of fax output to      *
;							ensure uniqueness.								*
;	  025 05/24/07 RD012555 Prescriptions without a frequency will not print*
;							twice when taking a complete action.			*
;	  026 08/07/07 RD012555 Add ellipsis to mnemonics that are truncated.   *
;     027 05/06/08 SA016585 Changed the ORDER and HEAD section of select for*
;                          	DEA number to print the DEA number of the       *
;                          	prescribing physician when supervising physician*
;                           is present.										*
;	  028 07/18/08 WC014474 Stop printing if order status is med student.   *
;	  029 07/23/08 WC014474 Print NPI number								*
;     030 08/07/08 MK012585 Fix to print both DEA and NPI aliases correctly *
;     031 10/30/08 SJ016555 For Orders containing both strength and volume
;                           dose the requisitions will print both strength
;                           and volume doses for Primary, Brand and C type
;                           mnemonics
;     032 12/22/08 SW015124 Added drug form detail.                         *
;     033 01/20/09 CG011817 Changes for stacked suspend on new order.        *
;     034 08/20/09 AD010624 Replaced comparisons using > " " with size() > 0*
;                           Trim both sides of order details                *
;	  035 08/09/09 SH018059 Remove Start Dt Tm, replace with "Date Written" *
;	  036 08/25/09 JT018805 Replace time based logic around auto-complete   *
;							and auto-suspend								*
;     037 10/12/09 DP014848	For Orders containing both strength and volume  *
;                           dose the requisitions will print only strength  *
;                           dose for Primary, Brand and C type mnemonics    *
;     038 08/19/10 MK012585	Include order_id in the name of the report      *
;                           to ensure uniqueness                            *
;     039 01/12/12 KK023353	Changes for Electronic Prescription of      *
;                           Controlled Substances (EPCS)                    *
;     040 02/06/12 PC3603   Stop printing e-sig for controlled substances   *
;     041 06/27/12 PC3603   Sort the order_detail correctly so the routing  *
;                           pharmacy name is printed correctly              *
;     042 08/15/12 BB024239 Medication is displayed and printed both		*
;                           numerically and alphabetically					*
;     043 04/04/13 PB027274 Fixed incorrect conversion of DOB from UTC to   *
;                           local by adding birth timezone                  *
;     044 10/01/13 ST020427 Date/time format converted to support           *
;                           globalization format.                           *
;     045 12/08/16 VS043502 CR 1-11377339641				    			*
;	 		    			Rx Requisite print refills 			    		*
;			    			incorrectly if total refills does		    	*
;			    			not equal the remaining refills.		    	*
;    *046 03/05/17 HV030682 Replacing tab with spaces in order comments	    *
;     047 06/25/17 SR051119 pulling at most 2 diagnosis description from	*
;							diagnosis table instead of nomenclature with 	*
;							their ICD10 code. And increased    				*
;                           the space alloted to display diagnosis.added 	*
;							MRN, FIN, Height, Weight, Refill line, 			*
;							signature line, units measurements line,		*
;						    wrapped order mnemonic filed, added special 	*
;							testing.     								    *
;																			*
;~DE~************************************************************************
;~END~ ******************  END OF ALL MODCONTROL BLOCKS  ********************
 
/****************************************************************************
*       Request record                                                      *
*****************************************************************************/
;*** requisitions should always have the request defined (not commented out)
;*** order of the request fields matter.
record request
(
  1 person_id         = f8
  1 print_prsnl_id    = f8
  1 order_qual[*]
    2 order_id        = f8
    2 encntr_id       = f8
    2 conversation_id = f8
  1 printer_name      = c50
)
 
;call echorecord(request)
 
/****************************************************************************
*       Reply record                                                        *
*****************************************************************************/
free record reply
record reply
(
%i cclsource:status_block.inc
)
 
/****************************************************************************
*       Include files                                                       *
*****************************************************************************/
;%i cclsource:cps_header_declares.inc
 
if (validate(FALSE,-1) = -1)
   set FALSE         = 0
endif
if (validate(TRUE,-1) = -1)
   set TRUE          = 1
endif
set GEN_NBR_ERROR = 3      ;*** error generating a sequence number
set INSERT_ERROR  = 4      ;*** error inserting item
set UPDATE_ERROR  = 5      ;*** error updating item
set DELETE_ERROR  = 6      ;*** error deleteing item
set SELECT_ERROR  = 7      ;*** error selecting item
set LOCK_ERROR    = 8
set INPUT_ERROR   = 9      ;*** error in request data
set EXE_ERROR     = 10     ;*** error in execution of embedded program
set failed        = FALSE  ;*** holds failure status of script
set table_name    = fillstring (50, " ")
set sErrMsg       = fillstring(132, " ")
set iErrCode      = error(sErrMsg,1)
set iErrCode      = 0
 
/*******************************************************************************
;Variables for RTF tags
**************************************************************/
SET  RHEAD   = concat ("{\rtf1\ansi\deff0{\fonttbl{\f0\fswiss Arial;}}" ,
   " {\colortbl;\red0\green0\blue0;\red255\green255\" ,"blue255;}\deftab1134" )
SET  REOL    = "\par "
SET  REOP    = "\pard "
SET  RTAB    = "\tab "
SET  WR      = " \plain\f0\fs18\cb2"
SET  WB      = "\plain\f0\fs18\cb2\b"
SET  HI      = "\pard\fi-2340\li2340 "
SET  RTFEOF  = "}"
 
 
/****************************************************************************
*       Declare variables                                                   *
*****************************************************************************/
declare new_rx_text    = c22 with public, constant("Prescription Details:") ;013
declare refill_rx_text = c22 with public, constant("Prescription Details:") ;013
declare reprint_text   = c24 with public, constant("RE-PRINT Prescription(s)")
declare is_a_reprint   = i2 with public, noconstant(FALSE)
declare v500_ind       = i2 with public, noconstant(FALSE)
declare use_pco        = i2 with public, noconstant(FALSE)
declare mltm_loaded    = i2 with public, noconstant(FALSE)
declare non_blank_nbr  = i2 with public, noconstant(TRUE) ;008
declare found_npi	   = i2 with public, noconstant(FALSE);029
declare found_npi_sup  = i2 with public, noconstant(FALSE);029
 
declare count		   = i4 with public, noconstant(0)	;047
declare FIN_cd		   = f8  with protect, constant(uar_get_code_by_cki("CKI.CODEVALUE!2930"))	;047
declare WEIGHT_CD 		   = f8  with protect, constant(UAR_GET_CODE_BY ("DISPLAYKEY" ,72 ,"WEIGHTMEASURED" ))	;047
declare HEIGHT_CD          = f8  with protect, constant(UAR_GET_CODE_BY ("DISPLAYKEY" ,72 ,"HEIGHTLENGTHMEASURED" ))	;047
declare cell_phone_cd  = f8 with constant(uar_get_code_by("DISPLAYKEY",43,"MOBILE"))	;047
 
declare username  = vc with public, noconstant(" ")
declare file_name = vc with public, noconstant(" ")
 
declare 43_BUSINESS_PHONE = f8  with protect, constant(uar_get_code_by_cki("CKI.CODEVALUE!9598"))
declare 43_FAX_PHONE = f8  with protect, constant(uar_get_code_by_cki("CKI.CODEVALUE!9529"))
 
declare 212_BUSINESS_ADD = f8  with protect, constant(uar_get_code_by_cki("CKI.CODEVALUE!8009"))
 
declare 400_ICD10		 = f8 with protect, constant(uar_get_code_by_cki("CKI.CODEVALUE!4101498946"))
 
declare work_add_cd         = f8 with public, noconstant(0.0)
declare home_add_cd         = f8 with public, noconstant(0.0)
declare work_phone_cd       = f8 with public, noconstant(0.0)
declare home_phone_cd       = f8 with public, noconstant(0.0)
declare order_cd            = f8 with public, noconstant(0.0)
declare complete_cd         = f8 with public, noconstant(0.0)
declare modify_cd           = f8 with public, noconstant(0.0)
declare suspend_cd          = f8 with public, noconstant(0.0);033
declare studactivate_cd     = f8 with public, noconstant(0.0)
declare activate_cd			= f8 with public, noconstant(0.0) ;MOD 036
declare docdea_cd           = f8 with public, noconstant(0.0)
declare licensenbr_cd       = f8 with public, noconstant(0.0)
declare canceled_allergy_cd = f8 with public, noconstant(0.0)
declare emrn_cd             = f8 with public, noconstant(0.0)
 
declare pmrn_cd             = f8 with public, noconstant(0.0)
declare ord_comment_cd      = f8 with public, noconstant(0.0)
declare prsnl_type_cd       = f8 with public,noconstant(0.0)
declare medstudent_hold_cd	= f8 with public, noconstant(0.0);028
declare docnpi_cd		    = f8 with public, noconstant(0.0);029
declare eprsnl_ind          = i2 with public,noconstant(FALSE)
declare code_set    = i4  with public, noconstant(0)
declare cdf_meaning = c12 with public, noconstant(fillstring(12," "))
declare csa_group_cnt       = i4 with public, noconstant(0)   ;010
declare temp_csa_group      = vc with public, noconstant(" ") ;010
declare pos                 = i4 with protect, noconstant(0)  ;020
declare j                   = i4 with protect, noconstant(0)  ;020
 
;*** MOD 017 BEG
declare bPersonOrgSecurityOn = i2 with public,noconstant(FALSE)
declare dminfo_ok = i2 with private,noconstant(FALSE)
declare algy_bit_pos = i2 with public,noconstant(0)
declare algy_access_priv = f8 with public,noconstant(0.0)
declare access_granted = i2 with public,noconstant(FALSE)
declare user_id = f8 with public,noconstant(0.0)
declare eidx = i4 with public,noconstant(0)
declare fidx = i4 with public,noconstant(0)
declare adr_exist = i2 with public,noconstant(FALSE)
;*** MOD 017 END
 
declare mnemonic_size = i4 with protect, noconstant(0)	;026
declare mnem_length = i4 with protect, noconstant(0)	;026
 
declare primary_mnemonic_type_cd = f8 with protect, noconstant(0.0)
declare brand_mnemonic_type_cd   = f8 with protect, noconstant(0.0)
declare c_mnemonic_type_cd       = f8 with protect, noconstant(0.0)
 
;032 Start
declare generic_top_type_cd = f8 with protect, noconstant(0.0)
declare trade_top_type_cd = f8 with protect, noconstant(0.0)
declare generic_prod_type_cd = f8 with protect, noconstant(0.0)
declare trade_prod_type_cd = f8 with protect, noconstant(0.0)
;032 End
declare erx_idx = i4 with protect, noconstant(0)
declare msg_audit_code = f8 with protect, noconstant(0.0)
 
;042 Start
declare number_spellout     = vc with protect, noconstant("")
declare dispense_number     = c255 with protect, noconstant("")
;042 End
 
 ;Setting up structure to hold numbers for spell out
 
record numbers
(
    1 ones[10]
      2 value  = vc
    1 teens[10]
      2 value  = vc
    1 tens[9]
      2 value  = vc
    1 hundred  = c7
    1 thousand = c8
 
)
/*******************************************************************************
;Record Structure
*******************************************************************************/
record reply_rtf
(
               1 text = vc
               1 format = i4
)
 
 
;initializing the ones
set numbers->ones[1].value   = "zero"
set numbers->ones[2].value   = "one"
set numbers->ones[3].value   = "two"
set numbers->ones[4].value   = "three"
set numbers->ones[5].value   = "four"
set numbers->ones[6].value   = "five"
set numbers->ones[7].value   = "six"
set numbers->ones[8].value   = "seven"
set numbers->ones[9].value   = "eight"
set numbers->ones[10].value  = "nine"
 
;initializing the teens
set numbers->teens[1].value  = "ten"
set numbers->teens[2].value  = "eleven"
set numbers->teens[3].value  = "twelve"
set numbers->teens[4].value  = "thirteen"
set numbers->teens[5].value  = "fourteen"
set numbers->teens[6].value  = "fifteen"
set numbers->teens[7].value  = "sixteen"
set numbers->teens[8].value  = "seventeen"
set numbers->teens[9].value  = "eightteen"
set numbers->teens[10].value = "nineteen"
 
;initializing the tens
set numbers->tens[1].value   = "ten"
set numbers->tens[2].value   = "twenty"
set numbers->tens[3].value   = "thirty"
set numbers->tens[4].value   = "forty"
set numbers->tens[5].value   = "fifty"
set numbers->tens[6].value   = "sixty"
set numbers->tens[7].value   = "seventy"
set numbers->tens[8].value   = "eighty"
set numbers->tens[9].value   = "ninety"
 
;initializing hundred
set numbers->hundred = "hundred"
 
;initializing thousand
set numbers->thousand = "thousand"
 
/****************************************************************************
*       Initialize variables                                                *
*****************************************************************************/
set code_set = 212
set cdf_meaning = "HOME"
set stat = uar_get_meaning_by_codeset(code_set,cdf_meaning,1,home_add_cd)
 
if (home_add_cd < 1)
    set failed = SELECT_ERROR
    set table_name = "CODE_VALUE"
    set sErrMsg = concat("Unable to find the Code Value for ",
                         trim(cdf_meaning),
                         " in Code Set ",
                         trim(cnvtstring(code_set)))
    go to EXIT_SCRIPT
endif
 
set code_set = 212
set cdf_meaning = "BUSINESS"
set stat = uar_get_meaning_by_codeset(code_set,cdf_meaning,1,work_add_cd)
if (work_add_cd < 1)
    set failed = SELECT_ERROR
    set table_name = "CODE_VALUE"
    set sErrMsg = concat("Unable to find the Code Value for ",
                         trim(cdf_meaning),
                         " in Code Set ",
                         trim(cnvtstring(code_set)))
    go to EXIT_SCRIPT
endif
 
set code_set = 43
set cdf_meaning = "HOME"
set stat = uar_get_meaning_by_codeset(code_set,cdf_meaning,1,home_phone_cd)
if (home_phone_cd < 1)
    set failed = SELECT_ERROR
    set table_name = "CODE_VALUE"
    set sErrMsg = concat("Unable to find the Code Value for ",
                         trim(cdf_meaning),
                         " in Code Set ",
                         trim(cnvtstring(code_set)))
    go to EXIT_SCRIPT
endif
 
set code_set = 43
set cdf_meaning = "BUSINESS"
set stat = uar_get_meaning_by_codeset(code_set,cdf_meaning,1,work_phone_cd)
if (work_phone_cd < 1)
    set failed = SELECT_ERROR
    set table_name = "CODE_VALUE"
    set sErrMsg = concat("Unable to find the Code Value for ",
                         trim(cdf_meaning),
                         " in Code Set ",
                         trim(cnvtstring(code_set)))
    go to EXIT_SCRIPT
endif
 
set code_set = 6003
set cdf_meaning = "ORDER"
set stat = uar_get_meaning_by_codeset(code_set,cdf_meaning,1,order_cd)
if (order_cd < 1)
    set failed = SELECT_ERROR
    set table_name = "CODE_VALUE"
    set sErrMsg = concat("Unable to find the Code Value for ",
                         trim(cdf_meaning),
                         " in Code Set ",
                         trim(cnvtstring(code_set)))
    go to EXIT_SCRIPT
endif
 
set code_set = 6003
set cdf_meaning = "COMPLETE"
set stat = uar_get_meaning_by_codeset(code_set,cdf_meaning,1,complete_cd)
if (complete_cd < 1)
    set failed = SELECT_ERROR
    set table_name = "CODE_VALUE"
    set sErrMsg = concat("Unable to find the Code Value for ",
                         trim(cdf_meaning),
                         " in Code Set ",
                         trim(cnvtstring(code_set)))
    go to EXIT_SCRIPT
endif
 
set code_set = 6003
set cdf_meaning = "MODIFY"
set stat = uar_get_meaning_by_codeset(code_set,cdf_meaning,1,modify_cd)
if (modify_cd < 1)
    set failed = SELECT_ERROR
    set table_name = "CODE_VALUE"
    set sErrMsg = concat("Unable to find the Code Value for ",
                         trim(cdf_meaning),
                         " in Code Set ",
                         trim(cnvtstring(code_set)))
    go to EXIT_SCRIPT
endif
 
set code_set = 6003
set cdf_meaning = "STUDACTIVATE"
set stat = uar_get_meaning_by_codeset(code_set,cdf_meaning,1,studactivate_cd)
if (studactivate_cd < 1)
    set failed = SELECT_ERROR
    set table_name = "CODE_VALUE"
    set sErrMsg = concat("Unable to find the Code Value for ",
                         trim(cdf_meaning),
                         " in Code Set ",
                         trim(cnvtstring(code_set)))
    go to EXIT_SCRIPT
endif
 
;Begin Mod 033
set code_set = 6003
set cdf_meaning = "SUSPEND"
set stat = uar_get_meaning_by_codeset(code_set,cdf_meaning,1,suspend_cd)
if (suspend_cd < 1)
    set failed = SELECT_ERROR
    set table_name = "CODE_VALUE"
    set sErrMsg = concat("Unable to find the Code Value for ",
                         trim(cdf_meaning),
                         " in Code Set ",
                         trim(cnvtstring(code_set)))
    go to EXIT_SCRIPT
endif
;End Mod 033
 
;BEGIN MOD 036
set code_set = 6003
set cdf_meaning = "ACTIVATE"
set stat = uar_get_meaning_by_codeset(code_set,cdf_meaning,1,activate_cd)
if (activate_cd < 1)
    set failed = SELECT_ERROR
    set table_name = "CODE_VALUE"
    set sErrMsg = concat("Unable to find the Code Value for ",
                         trim(cdf_meaning),
                         " in Code Set ",
                         trim(cnvtstring(code_set)))
    go to EXIT_SCRIPT
endif
;END MOD 036
 
set code_set = 12025
set cdf_meaning = "CANCELED"
set stat = uar_get_meaning_by_codeset(code_set,cdf_meaning,1,canceled_allergy_cd)
if (canceled_allergy_cd < 1)
    set failed = SELECT_ERROR
    set table_name = "CODE_VALUE"
    set sErrMsg = concat("Unable to find the Code Value for ",
                         trim(cdf_meaning),
                         " in Code Set ",
                         trim(cnvtstring(code_set)))
    go to EXIT_SCRIPT
endif
 
set code_set = 320
set cdf_meaning = "LICENSENBR"
set stat = uar_get_meaning_by_codeset(code_set,cdf_meaning,1,licensenbr_cd)
if (licensenbr_cd < 1)
    set failed = SELECT_ERROR
    set table_name = "CODE_VALUE"
    set sErrMsg = concat("Unable to find the Code Value for ",
                         trim(cdf_meaning),
                         " in Code Set ",
                         trim(cnvtstring(code_set)))
    go to EXIT_SCRIPT
endif
 
set code_set = 320
set cdf_meaning = "DOCDEA"
set stat = uar_get_meaning_by_codeset(code_set,cdf_meaning,1,docdea_cd)
if (docdea_cd < 1)
    set failed = SELECT_ERROR
    set table_name = "CODE_VALUE"
    set sErrMsg = concat("Unable to find the Code Value for ",
                         trim(cdf_meaning),
                         " in Code Set ",
                         trim(cnvtstring(code_set)))
    go to EXIT_SCRIPT
endif
 
/*** start 028 ***/
set code_set = 6004
set cdf_meaning = "MEDSTUDENT"
set stat = uar_get_meaning_by_codeset(code_set,cdf_meaning,1,medstudent_hold_cd)
if (medstudent_hold_cd < 1)
    set failed = SELECT_ERROR
    set table_name = "CODE_VALUE"
    set sErrMsg = concat("Unable to find the Code Value for ",
                         trim(cdf_meaning),
                         " in Code Set ",
                         trim(cnvtstring(code_set)))
    go to EXIT_SCRIPT
endif
/*** end 028 ***/
 
/*** start 029 ***/
set code_set = 320
set cdf_meaning = "NPI"
set stat = uar_get_meaning_by_codeset(code_set,cdf_meaning,1,docnpi_cd)
if (docnpi_cd < 1)
    set failed = SELECT_ERROR
    set table_name = "CODE_VALUE"
    set sErrMsg = concat("Unable to find the Code Value for ",
                         trim(cdf_meaning),
                         " in Code Set ",
                         trim(cnvtstring(code_set)))
    go to EXIT_SCRIPT
endif
/*** end 029 ***/
 
set code_set = 319
set cdf_meaning = "MRN"
set stat = uar_get_meaning_by_codeset(code_set,cdf_meaning,1,emrn_cd)
if (emrn_cd < 1)
    set failed = SELECT_ERROR
    set table_name = "CODE_VALUE"
    set sErrMsg = concat("Unable to find the Code Value for ",
                         trim(cdf_meaning),
                         " in Code Set ",
                         trim(cnvtstring(code_set)))
    go to EXIT_SCRIPT
endif
 
set code_set = 4
set cdf_meaning = "MRN"
set stat = uar_get_meaning_by_codeset(code_set,cdf_meaning,1,pmrn_cd)
if (pmrn_cd < 1)
    set failed = SELECT_ERROR
    set table_name = "CODE_VALUE"
    set sErrMsg = concat("Unable to find the Code Value for ",
                         trim(cdf_meaning),
                         " in Code Set ",
                         trim(cnvtstring(code_set)))
    go to EXIT_SCRIPT
endif
 
set code_set = 14
set cdf_meaning = "ORD COMMENT"
set stat = uar_get_meaning_by_codeset(code_set,cdf_meaning,1,ord_comment_cd)
if (ord_comment_cd < 1)
    set failed = SELECT_ERROR
    set table_name = "CODE_VALUE"
    set sErrMsg = concat("Failed to find the code_value for ",
                         trim(cdf_meaning),
                         " in code_set ",
                         trim(cnvtstring(code_set)))
    go to EXIT_SCRIPT
endif
 
set code_set = 213
set cdf_meaning = "PRSNL"
set stat = uar_get_meaning_by_codeset(code_set,cdf_meaning,1,prsnl_type_cd)
if (prsnl_type_cd < 1)
   set failed = SELECT_ERROR
   set table_name = "CODE_VALUE"
   set sErrMsg = concat("Failed to find the code_value for ",
                        trim(cdf_meaning),
                        " in code_set ",
                        trim(cnvtstring(code_set)))
   go to EXIT_SCRIPT
endif
 
;031
set code_set = 6011
set cdf_meaning = "PRIMARY"
set stat = uar_get_meaning_by_codeset(code_set, cdf_meaning, 1, primary_mnemonic_type_cd)
if (primary_mnemonic_type_cd < 1)
   set failed = SELECT_ERROR
   set table_name = "CODE_VALUE"
   set sErrMsg = concat("Failed to find the code_value for ",
                        trim(cdf_meaning),
                        " in code_set ",
                        trim(cnvtstring(code_set)))
   go to EXIT_SCRIPT
endif
 
set cdf_meaning = "BRANDNAME"
set stat = uar_get_meaning_by_codeset(code_set, cdf_meaning, 1, brand_mnemonic_type_cd)
if (brand_mnemonic_type_cd < 1)
   set failed = SELECT_ERROR
   set table_name = "CODE_VALUE"
   set sErrMsg = concat("Failed to find the code_value for ",
                        trim(cdf_meaning),
                        " in code_set ",
                        trim(cnvtstring(code_set)))
   go to EXIT_SCRIPT
endif
 
set cdf_meaning = "DISPDRUG"
set stat = uar_get_meaning_by_codeset(code_set, cdf_meaning, 1, c_mnemonic_type_cd)
 
if (c_mnemonic_type_cd < 1)
   set failed = SELECT_ERROR
   set table_name = "CODE_VALUE"
   set sErrMsg = concat("Failed to find the code_value for ",
                        trim(cdf_meaning),
                        " in code_set ",
                        trim(cnvtstring(code_set)))
   go to EXIT_SCRIPT
endif
 
;032 Start
set cdf_meaning = "GENERICTOP"
set stat = uar_get_meaning_by_codeset(code_set, cdf_meaning, 1, generic_top_type_cd)
if (generic_top_type_cd < 1)
   set failed = SELECT_ERROR
   set table_name = "CODE_VALUE"
   set sErrMsg = concat("Failed to find the code_value for ",
                        trim(cdf_meaning),
                        " in code_set ",
                        trim(cnvtstring(code_set)))
   go to EXIT_SCRIPT
endif
 
set cdf_meaning = "TRADETOP"
set stat = uar_get_meaning_by_codeset(code_set, cdf_meaning, 1, trade_top_type_cd)
if (trade_top_type_cd < 1)
   set failed = SELECT_ERROR
   set table_name = "CODE_VALUE"
   set sErrMsg = concat("Failed to find the code_value for ",
                        trim(cdf_meaning),
                        " in code_set ",
                        trim(cnvtstring(code_set)))
   go to EXIT_SCRIPT
endif
 
set cdf_meaning = "GENERICPROD"
set stat = uar_get_meaning_by_codeset(code_set, cdf_meaning, 1, generic_prod_type_cd)
if (generic_prod_type_cd < 1)
   set failed = SELECT_ERROR
   set table_name = "CODE_VALUE"
   set sErrMsg = concat("Failed to find the code_value for ",
                        trim(cdf_meaning),
                        " in code_set ",
                        trim(cnvtstring(code_set)))
   go to EXIT_SCRIPT
endif
 
set cdf_meaning = "TRADEPROD"
set stat = uar_get_meaning_by_codeset(code_set, cdf_meaning, 1, trade_prod_type_cd)
if (trade_prod_type_cd < 1)
   set failed = SELECT_ERROR
   set table_name = "CODE_VALUE"
   set sErrMsg = concat("Failed to find the code_value for ",
                        trim(cdf_meaning),
                        " in code_set ",
                        trim(cnvtstring(code_set)))
   go to EXIT_SCRIPT
endif
;032 End
 
; determine if this is a reprint
if (request->print_prsnl_id > 0)
    set is_a_reprint = TRUE
endif
 
; find printer
if (is_a_reprint = FALSE)
    select into "nl:"
    from
        prsnl p
    plan p where
        p.person_id = reqinfo->updt_id
    head report
        username = trim(substring(1,12,p.username))
    with nocounter
endif
 
if (not(size(username,1) > 0))     ;034
   set username = "faxreq"
endif
 
call echo ("***")
call echo (build("*** username :",username))
call echo ("***")
 
/****************************************************************************
*       load patient demographics                                           *
*****************************************************************************/
free record demo_info
record demo_info
(
  1 pat_id         = f8
  1 pat_name       = vc
  1 pat_sex        = vc
  1 pat_bday       = vc
  1 pat_age        = vc
  1 pat_addr       = vc
  1 pat_city       = vc
  1 pat_hphone     = vc
  1 pat_wphone     = vc
  1 pat_cphone	   = vc	;047
  1 allergy_line   = vc
)
 
;*** get name and address information
set iErrCode = error(sErrMsg,1)
set iErrCode = 0
 
select into "nl:"
from
    person p,
    address a
plan p where
    p.person_id = request->person_id
join a where
    a.parent_entity_id = outerjoin(p.person_id) and
    a.parent_entity_name = outerjoin("PERSON") and
    a.address_type_cd = outerjoin(home_add_cd) and
    (a.active_ind = outerjoin(1) and
     a.beg_effective_dt_tm <= outerjoin(cnvtdatetime(curdate,curtime3)) and
     a.end_effective_dt_tm > outerjoin(cnvtdatetime(curdate,curtime3)))
order
 
    a.address_id
 
head report
    demo_info->pat_id   = p.person_id
    demo_info->pat_name = trim(p.name_full_formatted)
    demo_info->pat_sex  = trim(uar_get_code_display(p.sex_cd))
    demo_info->pat_bday = trim(format(cnvtdatetimeutc(datetimezone(p.birth_dt_tm,p.birth_tz),1),"@SHORTDATE4YR"))
    demo_info->pat_age  = cnvtage(p.birth_dt_tm)
    found_address = FALSE
 
head a.address_id
 
    if (a.address_id > 0 and found_address = FALSE)
        found_address = TRUE
        demo_info->pat_addr = trim(substring(1,33,a.street_addr))
        if (size(trim(a.street_addr2,3),1) > 0)     ;034
            demo_info->pat_addr = trim(substring(1,33,trim(concat(trim(demo_info->pat_addr),", ",trim(a.street_addr2)))))
        endif
 
        demo_info->pat_city = trim(a.city)
 
        if (a.state_cd > 0)
            demo_info->pat_city = concat(trim(demo_info->pat_city),", ",trim(uar_get_code_display(a.state_cd)))
        elseif (size(a.state,1) > 0)     ;034
            demo_info->pat_city = concat(trim(demo_info->pat_city),", ",trim(a.state))
        endif
 
        if (size(a.zipcode,1) > 0)     ;034
            demo_info->pat_city = concat(trim(demo_info->pat_city)," ",trim(a.zipcode))
        endif
 
        demo_info->pat_city = trim(substring(1,33,demo_info->pat_city))
    endif
with nocounter
 
set iErrCode = error(sErrMsg,1)
if (iErrCode > 0)
    set failed = SELECT_ERROR
    set table_name = "NAME_ADDRESS"
    go to EXIT_SCRIPT
endif
 
;*** get patient phone numbers
set iErrCode = error(sErrMsg,1)
set iErrCode = 0
 
select into "nl:"
from
    phone p
plan p where
    p.parent_entity_id = request->person_id and
    p.parent_entity_name = "PERSON" and
    p.phone_type_cd in (home_phone_cd,work_phone_cd,cell_phone_cd) and	;047
    (p.active_ind = 1 and
     p.beg_effective_dt_tm <= cnvtdatetime(curdate,curtime3) and
     p.end_effective_dt_tm > cnvtdatetime(curdate,curtime3))
order
    p.beg_effective_dt_tm desc
 
head report
    found_home = FALSE
    found_work = FALSE
 
detail
    if (found_home = FALSE and p.phone_type_cd = home_phone_cd)
        found_home = TRUE
        demo_info->pat_hphone = trim(cnvtphone(p.phone_num,p.phone_format_cd,2))
    endif
 
    if (found_work = FALSE and p.phone_type_cd = work_phone_cd)
        found_work = TRUE
        demo_info->pat_wphone = trim(cnvtphone(p.phone_num,p.phone_format_cd,2))
   endif
 
   if ( p.phone_type_cd = cell_phone_cd)	;047
          demo_info->pat_cphone = trim(cnvtphone(p.phone_num,p.phone_format_cd,2))	;047
   endif	;047
with nocounter
 
set iErrCode = error(sErrMsg,1)
if (iErrCode > 0)
    set failed = SELECT_ERROR
    set table_name = "PATIENT_PHONE"
    go to EXIT_SCRIPT
endif
 
;*** get allergy info
;*** MOD 017 BEG
;*** Is Person/Org Security On ================================================
 
;*** Check to see if ADR table exist.  If it exist then Person/Org Security
;*** may be on
 
set iErrCode = error(sErrMsg,1)
set iErrCode = 0
 
select into "nl:"
from
    dba_tables d
plan d where
    d.table_name = "ACTIVITY_DATA_RELTN" and
    d.owner = "V500"
detail
    adr_exist = TRUE
with nocounter
set iErrCode = error(sErrMsg,1)
if (iErrCode > 0)
    set failed = SELECT_ERROR
    set table_name = "DBA_TABLES"
    go to EXIT_SCRIPT
endif
 
if (adr_exist = TRUE)
;*** determine if Person/Org Security is on
   set dminfo_ok = validate( ccldminfo->mode, 0 )
   if(dminfo_ok = 1)
      if (ccldminfo->sec_org_reltn = 1 and ccldminfo->person_org_sec = 1)
         set bPersonOrgSecurityOn = TRUE
      endif
   else
      set iErrCode = error(sErrMsg,1)
      set iErrCode = 0
      select into "nl:"
      from dm_info di
      plan di
         where di.info_domain = "SECURITY"
         and di.info_name in ("SEC_ORG_RELTN", "PERSON_ORG_SEC")
         and di.info_number = 1
      head report
         encntr_org_sec_on = 0
         person_org_sec_on = 0
      detail
         if (di.info_name = "SEC_ORG_RELTN" and di.info_number = 1)
            encntr_org_sec_on = 1
         elseif (di.info_name = "PERSON_ORG_SEC")
            person_org_sec_on = 1
         endif
      foot report
         if (person_org_sec_on = 1 and encntr_org_sec_on = 1)
            bPersonOrgSecurityOn = TRUE
         endif
      with nocounter
      set iErrCode = error(sErrMsg,1)
      if (iErrCode > 0)
         set failed = SELECT_ERROR
         set table_name = "DM_INFO"
         go to EXIT_SCRIPT
      endif
   endif
endif
 
if (bPersonOrgSecurityOn = TRUE)
;*** If Person/Org Security is on check to see if the User has an "Override" Person/Prsnl
;*** relationship to the patient.  If and "Override" relationship exist then act as if
;*** Person/Org Security is off
 
   set iErrCode = error(sErrMsg,1)
   set iErrCode = 0
   select into "nl:"
   from orders o
      ,order_action oa
   plan o
      where o.order_id = request->order_qual[1].order_id
   join oa
      where oa.order_id = o.order_id
      and oa.action_sequence = o.last_action_sequence
   detail
      user_id = oa.order_provider_id
   with nocounter
   set iErrCode = error(sErrMsg,1)
   if (iErrCode > 0)
      set failed = SELECT_ERROR
      set table_name = "GET_USER_ID"
      go to EXIT_SCRIPT
   endif
 
   if (user_id < 1)
      set bPersonOrgSecurityOn = FALSE
   else
      set iErrCode = error(sErrMsg,1)
      set iErrCode = 0
      select into "nl:"
      from person_prsnl_reltn ppr
         ,code_value_extension cve
      plan ppr
         where ppr.prsnl_person_id = user_id
         and ppr.active_ind = 1
         and ppr.person_id+0 = request->person_id
         and ppr.beg_effective_dt_tm <= cnvtdatetime(curdate, curtime3)
         and ppr.end_effective_dt_tm > cnvtdatetime(curdate, curtime3)
      join cve
         where cve.code_value = ppr.person_prsnl_r_cd
         and cve.code_set = 331
         and (cve.field_value = "1" or cve.field_value = "2")
         and cve.field_name = "Override"
      head report
         bPersonOrgSecurityOn = FALSE
      with nocounter
      set iErrCode = error(sErrMsg,1)
      if (iErrCode > 0)
         set failed = SELECT_ERROR
         set table_name = "PRSNL_OVERRIDE"
         go to EXIT_SCRIPT
      endif
   endif
endif
if (bPersonOrgSecurityOn = TRUE)
;*** If Person/Org Security is on determine the Allergy Access Priv Code Value
;*** to be used later to determine the bit position of the access priv of the
;*** Org Set the user belongs to.
 
   set algy_access_priv = uar_get_code_by("DISPLAYKEY",413574,"ALLERGIES")
   if (algy_access_priv < 1)
      set failed = SELECT_ERROR
      set table_name = "CODE_VALUE"
      set sErrMsg = "Failed to find Code Value for Display Key ALLERGIES in Code Set 413574"
      go to EXIT_SCRIPT
   endif
endif
 
;*** Load Prsnl Orgs ==========================================================
if (bPersonOrgSecurityOn = TRUE)
 
;*** Person/Org Security is on, load the organizations and org sets the user belongs to
 
   call echo ("***")
   call echo ("***   Load Prsnl Orgs")
   call echo ("***")
 
   declare network_var = f8 with Constant(uar_get_code_by("MEANING",28881,"NETWORK")),protect
 
   free record prsnl_orgs
   record prsnl_orgs
   (
      1  org_knt = i4
      1  org[*]
         2  organization_id = f8
      1  org_set_knt = i4
      1  org_set[*]
         2  org_set_id = f8
         2  access_privs = i4
         2  org_list_knt = i4
         2  org_list[*]
            3  organization_id = f8
   )
 
   set iErrCode = error(sErrMsg,1)
   set iErrCode = 0
   select into "nl:"
   from prsnl_org_reltn por
   plan por
      where por.person_id = user_id
      and por.beg_effective_dt_tm <= cnvtdatetime(curdate,curtime3)
      and por.end_effective_dt_tm >= cnvtdatetime(curdate,curtime3)
      and por.active_ind = TRUE
   head report
      knt = 0
      stat = alterlist(prsnl_orgs->org,10)
   head por.organization_id
      knt = knt + 1
      if (mod(knt,10) = 1 and knt != 1)
         stat = alterlist(prsnl_orgs->org,knt + 9)
      endif
      prsnl_orgs->org[knt].organization_id = por.organization_id
   foot report
      prsnl_orgs->org_knt = knt
      stat = alterlist(prsnl_orgs->org,knt)
   with nocounter
   set iErrCode = error(sErrMsg,1)
   if (iErrCode > 0)
      set failed = SELECT_ERROR
      set table_name = "PRSNL_ORG_RELTN"
      go to EXIT_SCRIPT
   endif
 
   if (network_var < 1)
      set failed = SELECT_ERROR
      set table_name = "CODE_VALUE"
      set sErrMsg = "Failed to find Code Value for CDF_MEANING NETWORK from Code Set 28881"
      go to EXIT_SCRIPT
   endif
 
   ;*** MOD 019 :: Use ORG_SET_TYPE_R to determine if Network Org
   set iErrCode = error(sErrMsg,1)
   set iErrCode = 0
   select into "nl:"
   from org_set_prsnl_r ospr
      ,org_set_type_r ostr
      ,org_set os
      ,org_set_org_r osor
   plan ospr
      where ospr.prsnl_id = reqinfo->updt_id
      and ospr.beg_effective_dt_tm <= cnvtdatetime(curdate,curtime3)
      and ospr.end_effective_dt_tm >= cnvtdatetime(curdate,curtime3)
      and ospr.active_ind = TRUE
   join ostr
      where ostr.org_set_id = ospr.org_set_id
      and ostr.org_set_type_cd = network_var
      and ostr.active_ind = 1
      and ostr.beg_effective_dt_tm <= cnvtdatetime(curdate,curtime3)
      and ostr.end_effective_dt_tm >= cnvtdatetime(curdate,curtime3)
   join os
      where os.org_set_id = ospr.org_set_id
   join osor
      where osor.org_set_id = os.org_set_id
      and osor.beg_effective_dt_tm <= cnvtdatetime(curdate,curtime3)
      and osor.end_effective_dt_tm >= cnvtdatetime(curdate,curtime3)
      and osor.active_ind = TRUE
   head report
      knt = 0
      stat = alterlist(prsnl_orgs->org_set,10)
   head ospr.org_set_id
      knt = knt + 1
      if (mod(knt,10) = 1 and knt != 1)
         stat = alterlist(prsnl_orgs->org_set,knt + 9)
      endif
      prsnl_orgs->org_set[knt].org_set_id = ospr.org_set_id
      prsnl_orgs->org_set[knt].access_privs = os.org_set_attr_bit
      oknt = 0
      stat = alterlist(prsnl_orgs->org_set[knt].org_list,10)
   detail
      oknt = oknt + 1
      if (mod(oknt,10) = 1 and oknt != 1)
         stat = alterlist(prsnl_orgs->org_set[knt].org_list,oknt + 9)
      endif
      prsnl_orgs->org_set[knt].org_list[oknt].organization_id = osor.organization_id
   foot ospr.org_set_id
      prsnl_orgs->org_set[knt].org_list_knt = oknt
      stat = alterlist(prsnl_orgs->org_set[knt].org_list,oknt)
   foot report
      prsnl_orgs->org_set_knt = knt
      stat = alterlist(prsnl_orgs->org_set,knt)
   with nocounter
   set iErrCode = error(sErrMsg,1)
   if (iErrCode > 0)
      set failed = SELECT_ERROR
      set table_name = "PRSNL_ORG_RELTN"
      go to EXIT_SCRIPT
   endif
endif
;==============================================================================
 
if (bPersonOrgSecurityOn = TRUE)
 
;*** Person Org Security is on, load all allergies that will be later filter based
;*** on viewablity
 
call echo ("***")
call echo ("***   bPersonOrgSecurityOn = TRUE")
call echo ("***")
 
   free record temp_alg
   record temp_alg
   (
      1  qual_knt = i4
      1  qual[*]
         2  allergy_id = f8
         2  subst_name = vc
         2  organization_id = f8
         2  viewable_ind = i2
         2  adr_knt = i4
         2  adr[*]
            3  reltn_entity_name = vc
            3  reltn_entity_id = f8
   )
 
   set iErrCode = error(sErrMsg,1)
   set iErrCode = 0
   select into "nl:"
   from
      allergy a
      ,nomenclature n
   plan a
      where a.person_id = request->person_id
      and a.reaction_status_cd != canceled_allergy_cd
      and (a.beg_effective_dt_tm <= cnvtdatetime(curdate,curtime3)
            and a.end_effective_dt_tm > cnvtdatetime(curdate,curtime3))
   join n
      where n.nomenclature_id = a.substance_nom_id
   head report
      knt = 0
      stat = alterlist(temp_alg->qual,10)
   detail
   	  ;call echo("inside allergy")
      knt = knt + 1
      if (mod(knt,10) = 1 and knt != 1)
         stat = alterlist(temp_alg->qual,knt + 9)
      endif
      temp_alg->qual[knt].allergy_id = a.allergy_id
      temp_alg->qual[knt].organization_id = a.organization_id
      if (n.nomenclature_id < 1)
         temp_alg->qual[knt].subst_name = a.substance_ftdesc
      else
         temp_alg->qual[knt].subst_name = n.source_string
      endif
      if (a.organization_id = 0.0)  ;*** if the allergy is associated to org_id 0.0 then everybody can see it.
         temp_alg->qual[knt].viewable_ind = 1
      endif
   foot report
      temp_alg->qual_knt = knt
      stat = alterlist(temp_alg->qual,knt)
   with nocounter
   set iErrCode = error(sErrMsg,1)
   if (iErrCode > 0)
      set failed = SELECT_ERROR
      set table_name = "ALLERGY"
      go to EXIT_SCRIPT
   endif
 
   ;call echorecord(temp_alg)
 
   if (temp_alg->qual_knt > 0)
 
      ;*** Allergies have been found, we need to load the ADR data for the allergies
 
      set iErrCode = error(sErrMsg,1)
      set iErrCode = 0
      select into "nl:"
      from activity_data_reltn adr
      plan adr
         where expand(eidx,1,temp_alg->qual_knt,adr.activity_entity_id,temp_alg->qual[eidx].allergy_id)
         and adr.activity_entity_name = "ALLERGY"
      head adr.activity_entity_id
         fidx = 0
         fidx = locateval(fidx,1,temp_alg->qual_knt,adr.activity_entity_id,temp_alg->qual[eidx].allergy_id)
         if (fidx > 0)
            stat = alterlist(temp_alg->qual[fidx].adr,10)
         endif
         knt = 0
      detail
         if (fidx > 0)
            knt = knt + 1
            if (mod(knt,10) = 1 and knt != 1)
               stat = alterlist(temp_alg->qual[fidx].adr,knt + 9)
            endif
            temp_alg->qual[fidx].adr[knt].reltn_entity_name = adr.reltn_entity_name
            temp_alg->qual[fidx].adr[knt].reltn_entity_id = adr.reltn_entity_id
         endif
      foot adr.activity_entity_id
         temp_alg->qual[fidx].adr_knt = knt
         stat = alterlist(temp_alg->qual[fidx].adr,knt)
      with nocounter
      set iErrCode = error(sErrMsg,1)
      if (iErrCode > 0)
         set failed = SELECT_ERROR
         set table_name = "ACTIVITY_DATA_RELTN"
         go to EXIT_SCRIPT
      endif
 
      set viewable_knt = 0
      for (vidx = 1 to temp_alg->qual_knt)
 
         ;*** Cycle through the allergy list and determine what's viewable
         set continue = TRUE
         set oknt = 1
         while (continue = TRUE and oknt <= prsnl_orgs->org_knt and temp_alg->qual[vidx].viewable_ind < 1)
            ;*** Check to see if "direct" organization between allergy and prsnl exist
            if (temp_alg->qual[vidx].organization_id = prsnl_orgs->org[oknt].organization_id)
               set temp_alg->qual[vidx].viewable_ind = 1
               set continue = FALSE
            endif
            set oknt = oknt + 1
         endwhile
         if (temp_alg->qual[vidx].viewable_ind < 1)
            set osknt = 1
            set continue = TRUE
            while (continue = TRUE and osknt <= prsnl_orgs->org_set_knt)
               ;*** Check to see if the allergy organization is in the Org Set org list of the user
               set oknt = 1
               set access_granted = FALSE
               set access_granted = btest(prsnl_orgs->org_set[osknt].access_priv,algy_bit_pos)
               while (continue = TRUE and oknt <= prsnl_orgs->org_set[osknt].org_list_knt and access_granted = TRUE)
                  if (temp_alg->qual[vidx].organization_id = prsnl_orgs->org_set[osknt].org_list[oknt].organization_id)
                     set temp_alg->qual[vidx].viewable_ind = 1
                     set continue = FALSE
                  endif
                  set oknt = oknt + 1
               endwhile
               set osknt = osknt + 1
            endwhile
         endif
         if (temp_alg->qual[vidx].adr_knt > 0 and temp_alg->qual[vidx].viewable_ind < 1)
            for (ridx = 1 to temp_alg->qual[vidx].adr_knt)
               ;*** detemine if ADR orgs are related to user orgs
 
               set continue = TRUE
               set oknt = 1
               while (continue = TRUE and oknt <= prsnl_orgs->org_knt and temp_alg->qual[vidx].viewable_ind < 1)
                  ;*** Check to see if "direct" organization between adr and prsnl exist
                  if (temp_alg->qual[vidx].adr[ridx].reltn_entity_name = "ORGANIZATION" and
                      temp_alg->qual[vidx].adr[ridx].reltn_entity_id = prsnl_orgs->org[oknt].organization_id)
                     set temp_alg->qual[vidx].viewable_ind = 1
                     set continue = FALSE
                  endif
                  set oknt = oknt + 1
               endwhile
               if (temp_alg->qual[vidx].viewable_ind < 1)
                  set osknt = 1
                  set continue = TRUE
                  while (continue = TRUE and osknt <= prsnl_orgs->org_set_knt)
                     ;*** Check to see if "in-direct" organization between adr and prsnl org set org exist
                     set oknt = 1
                     set access_granted = FALSE
                     set access_granted = btest(prsnl_orgs->org_set[osknt].access_priv,algy_bit_pos)
                     while (continue = TRUE and oknt <= prsnl_orgs->org_set[osknt].org_list_knt and access_granted = TRUE)
                        if (temp_alg->qual[vidx].adr[ridx].reltn_entity_name = "ORGANIZATION" and
                            temp_alg->qual[vidx].adr[ridx].reltn_entity_id =
                            prsnl_orgs->org_set[osknt].org_list[oknt].organization_id)
                           set temp_alg->qual[vidx].viewable_ind = 2
                           set continue = FALSE
                        endif
                        set oknt = oknt + 1
                     endwhile
                     set osknt = osknt + 1
                  endwhile
               endif
            endfor
         endif
 
         if (temp_alg->qual[vidx].viewable_ind > 0)
            set viewable_knt = viewable_knt + 1
            if (viewable_knt = 1)
               set demo_info->allergy_line = trim(temp_alg->qual[vidx].subst_name)
            else
               set demo_info->allergy_line = concat(trim(demo_info->allergy_line),", ",trim(temp_alg->qual[vidx].subst_name))
            endif
         endif
      endfor
   endif
else  ;*** MOD 017 END
 
   call echo ("***")
   call echo ("***   bPersonOrgSecurityOn = FALSE")
   call echo ("***")
 
 
   set iErrCode = error(sErrMsg,1)
   set iErrCode = 0
 
   select into "nl:"
   from
    allergy a,
    nomenclature n
plan a where
    a.person_id = request->person_id and
    a.reaction_status_cd != canceled_allergy_cd and
    (a.beg_effective_dt_tm <= cnvtdatetime(curdate,curtime3) and
     a.end_effective_dt_tm > cnvtdatetime(curdate,curtime3))
join n where
    n.nomenclature_id = a.substance_nom_id
 
head report
    knt = 0
detail
    knt = knt + 1
 
    if (knt = 1)
        if (n.nomenclature_id > 0)
            demo_info->allergy_line = trim(n.source_string)
        else
            demo_info->allergy_line = trim(a.substance_ftdesc)
        endif
    else
        if (n.nomenclature_id > 0)
            demo_info->allergy_line = concat(trim(demo_info->allergy_line),", ",
                trim(n.source_string))
        else
            demo_info->allergy_line = concat(trim(demo_info->allergy_line),", ",
                trim(a.substance_ftdesc))
        endif
    endif
with nocounter
 
   set iErrCode = error(sErrMsg,1)
   if (iErrCode > 0)
      set failed = SELECT_ERROR
      set table_name = "ALLERGY"
      go to EXIT_SCRIPT
   endif
 
endif
 
 
if (textlen(trim(demo_info->allergy_line, 3)) > 0)
	set demo_info->allergy_line = trim(demo_info->allergy_line, 3)
else
	set demo_info->allergy_line = "No Allergies Have Been Recorded."
endif
 
 
/****************************************************************************
*       Load Order and Encounter Information                                *
*****************************************************************************/
free record temp_req
record temp_req
(
  1 qual_knt              = i4
  1 qual[*]
    2 order_id            = f8
    2 encntr_id           = f8
    2 encntr_type_cd	= f8
    2 pat_loc_name   = vc
	2 pat_loc_add    = vc
	2 pat_loc_bus_phone  = vc
	2 pat_loc_fax_phone  = vc
	2 ord_diag_idc		  = vc
	2 ord_diag_desc		 = vc
    2 d_nbr               = vc
    2 csa_schedule        = c1
    2 csa_group           = vc  ;*** C = 0 | A = 1,2 | B = 3,4,5
    2 mrn                 = vc
    2 fin 				  = vc ;047
    2 height 			  = vc ;047
	2 weight 			  = vc ;047
	2 height_w_units      = vc ;047
	2 weight_w_units      = vc ;047
    2 found_emrn          = i2
    2 hp_pri_found        = i2
    2 hp_pri_name         = vc
    2 hp_pri_polgrp       = vc
    2 hp_sec_found        = i2
    2 hp_sec_name         = vc
    2 hp_sec_polgrp       = vc
    2 oe_format_id        = f8
    2 phys_id             = f8
    2 phys_name           = vc
    2 phys_fname          = vc
    2 phys_mname          = vc
    2 phys_lname          = vc
    2 phys_title          = vc
    2 phys_bname          = vc
    2 found_phys_addr_ind = i2
    2 phys_addr_id        = f8
    2 phys_addr1          = vc
    2 phys_addr2          = vc
    2 phys_addr3          = vc
    2 phys_addr4          = vc
    2 phys_city           = vc
    2 phys_dea            = vc
    2 phys_npi			  = vc ;029
    2 sup_phys_npi		  = vc ;029
    2 phys_lnbr           = vc
    2 phys_phone          = vc
    2 phys_fax			  = vc
    2 eprsnl_ind          = i2
    2 eprsnl_id           = f8
    2 eprsnl_name         = vc
    2 eprsnl_fname        = vc
    2 eprsnl_mname        = vc
    2 eprsnl_lname        = vc
    2 eprsnl_title        = vc
    2 eprsnl_bname        = vc
    2 order_dt            = dq8
    2 output_dest_cd      = f8
    2 free_text_nbr       = vc
    2 print_loc           = vc
    2 no_print            = i2
    2 print_dea           = i2
    2 daw                 = i2
    2 start_date          = dq8
    2 req_start_date      = dq8
    2 perform_loc         = vc
    2 order_mnemonic      = vc
    2 order_as_mnemonic   = vc
    2 free_txt_ord        = vc
    2 med_name            = vc
 
    2 med_disp			  = vc
 
    2 strength_dose       = vc
    2 strength_dose_unit  = vc
    2 volume_dose         = vc
    2 volume_dose_unit    = vc
    2 freetext_dose       = vc
    2 rx_route            = vc
    2 frequency           = vc
    2 duration            = vc
    2 duration_unit       = vc
    2 sig_line            = vc
 
    2 dispense_qty        = vc
    2 dispense_qty_unit   = vc
    2 dispense_line       = vc
 
    2 dispense_duration   = vc			;*** MOD 007
    2 dispense_duration_unit = vc		;*** MOD 007
    2 dispense_duration_line = vc		;*** MOD 007
 
    2 req_refill_date     = dq8
    2 nbr_refills_txt     = vc
    2 nbr_refills         = f8
    2 total_refills       = f8
    2 add_refills_txt     = vc          ;008
    2 add_refills         = f8          ;008
    2 refill_ind          = i2
    2 refill_line         = vc
 
    2 special_inst        = vc
    2 special_inst_rtf	  = vc
 
    2 prn_ind             = i2
    2 prn_inst            = vc
 
    2 indications         = vc
 
    2 get_comment_ind     = i2
    2 comments            = vc
 
    2 sup_phys_bname      = vc           ;013
    2 sup_phys_dea        = vc           ;013
    2 sup_phys_id         = f8           ;013
    2 action_type_cd	  = f8           ;020
    2 frequency_cd        = f8           ;020
    2 action_dt_tm        = dq8          ;023
    2 orig_order_dt_tm    = dq8          ;023
    2 mnemonic_type_cd    = f8           ;031
    2 drug_form           = vc           ;032
    2 second_attempt_note = vc           ; complete message for second attempt printing of EPCS
 
    2 routing_pharmacy_name = vc        ; Name of Pharmacy to which EPCS routing failed
	2 routing_dt_tm			= dq8
	2 prim_dx_icd_code			= vc
	2 prim_dx_description		= vc
 
)
 
;*** get order data
set eprsnl_ind = FALSE
set iErrCode = error(sErrMsg,1)
set iErrCode = 0
select into "nl:"
    encntr_id = request->order_qual[d.seq]->encntr_id,
    oa.order_provider_id,
    o.order_id,
    cki_len = textlen(o.cki)
from
    (dummyt d with seq = value(size(request->order_qual,5))),
    orders o,
    order_action oa,
    prsnl p
plan d where
    d.seq > 0
join o where
    o.order_id = request->order_qual[d.seq]->order_id and
    o.encntr_id = request->order_qual[d.seq]->encntr_id and
    o.order_status_cd != medstudent_hold_cd ;028
join oa where
    oa.order_id = o.order_id and
    oa.action_sequence = o.last_action_sequence and
    (((oa.action_type_cd = order_cd or
       oa.action_type_cd = modify_cd or
       oa.action_type_cd = studactivate_cd or ;033
       oa.action_type_cd = activate_cd or												;MOD 036
       ((oa.action_type_cd = complete_cd or oa.action_type_cd = suspend_cd)				;MOD 036
        and oa.order_conversation_id =													;MOD 036
        	(select oap.order_conversation_id											;MOD 036
        	 from order_action oap														;MOD 036
        	 where oap.order_id = o.order_id and										;MOD 036
        	 	   oap.action_sequence = o.last_action_sequence-1						;MOD 036
        	 	   and oap.action_type_cd in (order_cd, studactivate_cd, activate_cd))	;MOD 036
       )) and
      (o.orig_ord_as_flag = 1)) or
     (is_a_reprint = TRUE))
join p where
    p.person_id = oa.order_provider_id
order
    o.order_id  ;MOD 011
 
head report
    knt = 0
    stat = alterlist(temp_req->qual,10)
    mnemonic_size = size(o.hna_order_mnemonic,3) - 1	;026
 
head o.order_id
    knt = knt + 1
    if (mod(knt,10) = 1 and knt != 1)
        stat = alterlist(temp_req->qual, knt + 9)
    endif
 
    temp_req->qual[knt]->order_id          = o.order_id
    temp_req->qual[knt]->encntr_id         = o.encntr_id
    temp_req->qual[knt]->oe_format_id      = o.oe_format_id
    temp_req->qual[knt]->phys_id           = oa.order_provider_id
    temp_req->qual[knt]->sup_phys_id       = oa.supervising_provider_id ;012
    temp_req->qual[knt]->eprsnl_id         = oa.action_personnel_id
    if (oa.order_provider_id != oa.action_personnel_id)
      temp_req->qual[knt]->eprsnl_ind = TRUE
      eprsnl_ind = TRUE
    endif
    temp_req->qual[knt]->phys_name         = trim(p.name_full_formatted)
    temp_req->qual[knt]->order_dt          = cnvtdatetime(cnvtdate(oa.action_dt_tm),0)
    temp_req->qual[knt]->print_loc         = request->printer_name
 
	;BEGIN 027
	mnem_length = size(trim(o.hna_order_mnemonic),1)
    if (mnem_length >= mnemonic_size
    	and SUBSTRING(mnem_length - 3, mnem_length, o.hna_order_mnemonic) != "...")
    	temp_req->qual[knt]->order_mnemonic = concat(trim(o.hna_order_mnemonic), "...")
    else
    	temp_req->qual[knt]->order_mnemonic = o.hna_order_mnemonic
    endif
 
 	mnem_length = size(trim(o.ordered_as_mnemonic),1)
    if (mnem_length >= mnemonic_size
    	and SUBSTRING(mnem_length - 3, mnem_length, o.hna_order_mnemonic) != "...")
    	temp_req->qual[knt]->order_as_mnemonic = concat(trim(o.ordered_as_mnemonic), "...")
    else
    	temp_req->qual[knt]->order_as_mnemonic = o.ordered_as_mnemonic
    endif
	;END 027
 
    temp_req->qual[knt]->action_type_cd    = oa.action_type_cd     ;020
    temp_req->qual[knt]->action_dt_tm      = oa.action_dt_tm       ;023
    temp_req->qual[knt]->orig_order_dt_tm  = o.orig_order_dt_tm    ;023
    if (band(o.comment_type_mask,1) = 1)
        temp_req->qual[knt]->get_comment_ind = TRUE
    endif
 
    d_pos = findstring("!d",o.cki)
    if (d_pos > 0)
        temp_req->qual[knt]->d_nbr = trim(substring(d_pos + 1, cki_len, o.cki))
    endif
 
foot report
    temp_req->qual_knt = knt
    stat = alterlist(temp_req->qual,knt)
with nocounter
 
set iErrCode = error(sErrMsg,1)
if (iErrCode > 0)
    set failed = SELECT_ERROR
    set table_name = "ORDER_INFO"
    go to EXIT_SCRIPT
endif
 
;*** get patient encounter location information
;set eprsnl_ind = FALSE
set iErrCode = error(sErrMsg,1)
set iErrCode = 0
 
select into "nl:"
	from (dummyt d with seq = value(temp_req->qual_knt)),
    encounter e,
    address a,
    phone p,
    phone p2,
    code_value cv
plan d where
    d.seq > 0
 
join e where
    e.encntr_id = temp_req->qual[d.seq]->encntr_id
 
join a where
    a.parent_entity_id = outerjoin(e.loc_facility_cd)
    and a.parent_entity_name = outerjoin("LOCATION")
    and a.active_ind 			= outerjoin(1)
    and a.beg_effective_dt_tm 	<= outerjoin(cnvtdatetime(curdate, curtime3))
    and a.end_effective_dt_tm 	> outerjoin(cnvtdatetime(curdate, curtime3))
    and a.address_type_cd = outerjoin(212_BUSINESS_ADD)
 
join p where
    p.parent_entity_id = outerjoin(e.loc_facility_cd)
    and p.parent_entity_name = outerjoin("LOCATION")
    and p.active_ind 			= outerjoin(1)
    and p.beg_effective_dt_tm 	<= outerjoin(cnvtdatetime(curdate, curtime3))
    and p.end_effective_dt_tm 	> outerjoin(cnvtdatetime(curdate, curtime3))
    and p.phone_type_cd = outerjoin(43_BUSINESS_PHONE)
 
 
join p2 where
    p2.parent_entity_id = outerjoin(e.loc_facility_cd)
    and p2.parent_entity_name = outerjoin("LOCATION")
    and p2.active_ind 			= outerjoin(1)
    and p2.beg_effective_dt_tm 	<= outerjoin(cnvtdatetime(curdate, curtime3))
    and p2.end_effective_dt_tm 	> outerjoin(cnvtdatetime(curdate, curtime3))
    and p2.phone_type_cd = outerjoin(43_FAX_PHONE)
 
join cv
	where cv.code_value = e.loc_facility_cd
 
head report
	null
 
detail
 
   	if (e.encntr_id = temp_req->qual[d.seq].encntr_id)
   		temp_req->qual[d.seq].encntr_type_cd = e.encntr_type_cd
   		temp_req->qual[d.seq].pat_loc_name = trim(cv.description,3)
   		temp_req->qual[d.seq].pat_loc_bus_phone = cnvtphone(p.phone_num, p.phone_format_cd,0)
   		temp_req->qual[d.seq].pat_loc_fax_phone = cnvtphone(p2.phone_num, p2.phone_format_cd,0)
   		if(textlen(trim(a.street_addr, 3)) > 0)
   			temp_req->qual[d.seq].pat_loc_add = trim(a.street_addr,3)
   		endif
   		if(textlen(trim(a.street_addr2 ,3)) > 0)
   			temp_req->qual[d.seq].pat_loc_add = build2(temp_req->qual[d.seq].pat_loc_add," ", trim(a.street_addr2,3))
   		endif
   		if(textlen(trim(a.street_addr3 ,3)) > 0)
   			temp_req->qual[d.seq].pat_loc_add = build2(temp_req->qual[d.seq].pat_loc_add," ", trim(a.street_addr3,3))
   		endif
   		if(textlen(trim(a.street_addr4 ,3)) > 0)
   			temp_req->qual[d.seq].pat_loc_add = build2(temp_req->qual[d.seq].pat_loc_add," ", trim(a.street_addr4,3))
   		endif
   		if(a.city_cd > 0)
   			temp_req->qual[d.seq].pat_loc_add = build2(temp_req->qual[d.seq].pat_loc_add," "
   												, trim(uar_get_code_display(a.city_cd) ,3))
   		elseif(textlen(trim(a.city ,3)) > 0)
   			temp_req->qual[d.seq].pat_loc_add = build2(temp_req->qual[d.seq].pat_loc_add," "
   												, trim(a.city ,3))
   		endif
   		if(a.state_cd > 0)
   			temp_req->qual[d.seq].pat_loc_add = build2(temp_req->qual[d.seq].pat_loc_add,", "
   												, trim(uar_get_code_display(a.state_cd) ,3))
   		elseif(textlen(trim(a.state ,3)) > 0)
   			temp_req->qual[d.seq].pat_loc_add = build2(temp_req->qual[d.seq].pat_loc_add,", "
   												, trim(a.state ,3))
   		endif
   		if(textlen(trim(a.zipcode, 3)) > 0)
   			temp_req->qual[d.seq].pat_loc_add = build2(temp_req->qual[d.seq].pat_loc_add," "
   												, trim(a.zipcode,3))
   		endif
   	endif
 
 
foot report
    null
with nocounter
 
set iErrCode = error(sErrMsg,1)
if (iErrCode > 0)
    set failed = SELECT_ERROR
    set table_name = "ORDER_INFO"
    go to EXIT_SCRIPT
endif
 
if (temp_req->qual_knt < 1)
    call echo ("***")
    call echo ("***   No items found to print")
    call echo ("***")
    go to EXIT_SCRIPT
endif
 
;*** get order primary diagnosis information when there is a priority saved
;set eprsnl_ind = FALSE
set iErrCode = error(sErrMsg,1)
set iErrCode = 0
 
select into "nl:"
	from (dummyt d with seq = value(temp_req->qual_knt)),
	orders o
	,nomen_entity_reltn ner
	,diagnosis dg
	,nomenclature n
 
plan d
	where d.seq > 0
 
join o
	where o.order_id = temp_req->qual[d.seq]->order_id
 
join ner
	where ner.parent_entity_id = outerjoin(o.order_id)
    and ner.parent_entity_name = outerjoin("ORDERS")
    and ner.active_ind 			= outerjoin(1)
    and ner.beg_effective_dt_tm 	<= outerjoin(cnvtdatetime(curdate, curtime3))
    and ner.end_effective_dt_tm 	> outerjoin(cnvtdatetime(curdate, curtime3))
    and ner.child_entity_name = outerjoin("DIAGNOSIS")
 
join dg
	where dg.diagnosis_id = ner.child_entity_id
 
join n
	where n.nomenclature_id = outerjoin(dg.nomenclature_id)
	and n.source_vocabulary_cd = 400_ICD10
 
order by o.order_id
 
head report
	null
 
 
 
detail
 
;047 BEGIN
if (o.order_id = temp_req->qual[d.seq].order_id)
	if(ner.priority in(1,2))
		if(textlen(trim(n.source_string ,3)) > 0)
		count=count+1
			if(textlen(trim(temp_req->qual[d.seq].prim_dx_icd_code))>0)
			temp_req->qual[d.seq].prim_dx_icd_code = build2(trim(dg.diagnosis_display,3),"(","ICD10 CODE: ",trim(n.source_identifier ,3),")")
			temp_req->qual[d.seq].prim_dx_description =
			build2(temp_req->qual[d.seq].prim_dx_description,", ",temp_req->qual[d.seq].prim_dx_icd_code)
			else
			temp_req->qual[d.seq].prim_dx_icd_code = build2(trim(dg.diagnosis_display,3),"(","ICD10 CODE: ",trim(n.source_identifier ,3),")")
				temp_req->qual[d.seq].prim_dx_description =temp_req->qual[d.seq].prim_dx_icd_code
			endif
		endif
	endif
endif
 
;047 END
foot report
    null
 
with nocounter
 
set iErrCode = error(sErrMsg,1)
if (iErrCode > 0)
    set failed = SELECT_ERROR
    set table_name = "ORDER_INFO"
    go to EXIT_SCRIPT
endif
 
if (temp_req->qual_knt < 1)
    call echo ("***")
    call echo ("***   No items found to print")
    call echo ("***")
    go to EXIT_SCRIPT
endif
 
;*** get order primary diagnosis information when there is NOT a priority saved
;set eprsnl_ind = FALSE
set iErrCode = error(sErrMsg,1)
set iErrCode = 0
 
 
select into "nl:"
	from (dummyt d with seq = value(temp_req->qual_knt)),
	orders o
	,nomen_entity_reltn ner
	,nomenclature n
 
plan d
	where d.seq > 0
 
join o
	where o.order_id = temp_req->qual[d.seq]->order_id
 
join ner
	where ner.parent_entity_id = outerjoin(o.order_id)
    and ner.priority = outerjoin(1)
    and ner.parent_entity_name = outerjoin("ORDERS")
    and ner.active_ind 			= outerjoin(1)
    and ner.beg_effective_dt_tm 	<= outerjoin(cnvtdatetime(curdate, curtime3))
    and ner.end_effective_dt_tm 	> outerjoin(cnvtdatetime(curdate, curtime3))
    and ner.child_entity_name = outerjoin("NOMENCLATURE")
    and ner.priority = outerjoin(0)
 
join n
	where n.nomenclature_id = outerjoin(ner.nomenclature_id)
	and n.source_vocabulary_cd = 400_ICD10
 
order by ner.beg_effective_dt_tm
 
head report
	null
 
head ner.beg_effective_dt_tm
	null
 
detail
 
   	if (o.order_id = temp_req->qual[d.seq].order_id)
   		if(textlen(trim(n.source_string ,3)) > 0 AND textlen(trim(temp_req->qual[d.seq].prim_dx_description, 3)) > 0)
   			temp_req->qual[d.seq].prim_dx_icd_code = trim(n.source_identifier ,3)
   			temp_req->qual[d.seq].prim_dx_description = trim(n.source_string ,3)
   		endif
   	endif
 
foot ner.beg_effective_dt_tm
	null
 
foot report
    null
with nocounter
 
set iErrCode = error(sErrMsg,1)
if (iErrCode > 0)
    set failed = SELECT_ERROR
    set table_name = "ORDER_INFO"
    go to EXIT_SCRIPT
endif
 
if (temp_req->qual_knt < 1)
    call echo ("***")
    call echo ("***   No items found to print")
    call echo ("***")
    go to EXIT_SCRIPT
endif
;*** get title
call echo("***")
call echo("***   Get Phys Title")
call echo("***")
 
set iErrCode = error(sErrMsg,1)
set iErrCode = 0
select into "nl:"
from (dummyt d with seq = value(temp_req->qual_knt))
   ,person_name p
plan d
   where d.seq > 0
join p
   where (p.person_id = temp_req->qual[d.seq].phys_id or
          p.person_id = temp_req->qual[d.seq].sup_phys_id) ;013
   and p.person_id > 0                                     ;013
   and p.name_type_cd = prsnl_type_cd
   and p.active_ind = TRUE
   and p.beg_effective_dt_tm <= cnvtdatetime(curdate,curtime3)
   and p.end_effective_dt_tm > cnvtdatetime(curdate,curtime3)
detail
    if (p.person_id = temp_req->qual[d.seq].phys_id)
	    temp_req->qual[d.seq]->phys_fname = trim(p.name_first)
	    temp_req->qual[d.seq]->phys_mname = trim(p.name_middle)
	    temp_req->qual[d.seq]->phys_lname = trim(p.name_last)
	    temp_req->qual[d.seq]->phys_title = trim(p.name_title)
	    if (size(p.name_first,1) > 0)     ;034
	        temp_req->qual[d.seq]->phys_bname = trim(p.name_first)
	        if (size(p.name_middle,1) > 0)     ;034
	            temp_req->qual[d.seq]->phys_bname = concat(trim(temp_req->qual[d.seq]->phys_bname)," ",trim(p.name_middle))
	            if (size(p.name_last,1) > 0)     ;034
	                temp_req->qual[d.seq]->phys_bname = concat(trim(temp_req->qual[d.seq]->phys_bname)," ",trim(p.name_last))
	            endif
	        elseif (size(p.name_last,1) > 0)     ;034
	            temp_req->qual[d.seq]->phys_bname = concat(trim(temp_req->qual[d.seq]->phys_bname)," ",trim(p.name_last))
	        endif
	    elseif (size(p.name_middle,1) > 0)     ;034
	        temp_req->qual[d.seq]->phys_bname = trim(p.name_middle)
	        if (size(p.name_last,1) > 0)     ;034
	            temp_req->qual[d.seq]->phys_bname = concat(trim(temp_req->qual[d.seq]->phys_bname)," ",trim(p.name_last))
	        endif
	    elseif (size(p.name_last,1) > 0)     ;034
	        temp_req->qual[d.seq]->phys_bname = concat(trim(temp_req->qual[d.seq]->phys_bname)," ",trim(p.name_last))
	    else
	        temp_req->qual[d.seq]->phys_bname = temp_req->qual[d.seq]->phys_name
	    endif
	    if (size(trim(temp_req->qual[d.seq]->phys_bname, 3),1) > 0 and size(trim(p.name_title,3),1) > 0)     ;034
	        temp_req->qual[d.seq]->phys_bname = concat(trim(temp_req->qual[d.seq]->phys_bname),", ",trim(p.name_title))
	    endif
    ;Mod 013 Start- Added the if/else to write the supervising physician name
	else
	    if (size(p.name_first,1) > 0)     ;034
	        temp_req->qual[d.seq]->sup_phys_bname = trim(p.name_first)
	        if (size(p.name_middle,1) > 0)     ;034
	            temp_req->qual[d.seq]->sup_phys_bname = concat(trim(temp_req->qual[d.seq]->sup_phys_bname)," ",trim(p.name_middle))
	            if (size(p.name_last,1) > 0)     ;034
	                temp_req->qual[d.seq]->sup_phys_bname = concat(trim(temp_req->qual[d.seq]->sup_phys_bname)," ",trim(p.name_last))
	            endif
	        elseif (size(p.name_last,1) > 0)     ;034
	            temp_req->qual[d.seq]->sup_phys_bname = concat(trim(temp_req->qual[d.seq]->sup_phys_bname)," ",trim(p.name_last))
	        endif
	    elseif (size(p.name_middle,1) > 0)     ;034
	        temp_req->qual[d.seq]->sup_phys_bname = trim(p.name_middle)
	        if (size(p.name_last,1) > 0)     ;034
	            temp_req->qual[d.seq]->sup_phys_bname = concat(trim(temp_req->qual[d.seq]->sup_phys_bname)," ",trim(p.name_last))
	        endif
	    elseif (size(p.name_last,1) > 0)     ;034
	        temp_req->qual[d.seq]->sup_phys_bname = concat(trim(temp_req->qual[d.seq]->sup_phys_bname)," ",trim(p.name_last))
	    else
	        temp_req->qual[d.seq]->sup_phys_bname = temp_req->qual[d.seq]->phys_name
	    endif
	    if (size(trim(temp_req->qual[d.seq]->sup_phys_bname,3),1) > 0 and size(trim(p.name_title,3),1) > 0)     ;034
	        temp_req->qual[d.seq]->sup_phys_bname = concat(trim(temp_req->qual[d.seq]->sup_phys_bname),", ",trim(p.name_title))
	    endif
	endif
    ;Mod 013 End
with nocounter
set iErrCode = error(sErrMsg,1)
if (iErrCode > 0)
    set failed = SELECT_ERROR
    set table_name = "PERSON_NAME"
    go to EXIT_SCRIPT
endif
 
if (eprsnl_ind = TRUE)
call echo("***")
call echo("***   Get Eprsnl Title")
call echo("***")
   set iErrCode = error(sErrMsg,1)
   set iErrCode = 0
   select into "nl:"
   from (dummyt d with seq = value(temp_req->qual_knt))
      ,person_name p
   plan d
      where d.seq > 0
      and temp_req->qual[d.seq].eprsnl_ind = TRUE
   join p
      where p.person_id = temp_req->qual[d.seq].eprsnl_id
      and p.name_type_cd = prsnl_type_cd
      and p.active_ind = TRUE
      and p.beg_effective_dt_tm <= cnvtdatetime(curdate,curtime3)
      and p.end_effective_dt_tm > cnvtdatetime(curdate,curtime3)
   detail
      temp_req->qual[d.seq]->eprsnl_name = trim(p.name_full)
      temp_req->qual[d.seq]->eprsnl_fname = trim(p.name_first)
      temp_req->qual[d.seq]->eprsnl_mname = trim(p.name_middle)
      temp_req->qual[d.seq]->eprsnl_lname = trim(p.name_last)
      temp_req->qual[d.seq]->eprsnl_title = trim(p.name_title)
      if (size(p.name_first,1) > 0)     ;034
         temp_req->qual[d.seq]->eprsnl_bname = trim(p.name_first)
         if (size(p.name_middle,1) > 0)     ;034
               temp_req->qual[d.seq]->eprsnl_bname = concat(trim(temp_req->qual[d.seq]->eprsnl_bname)," ",trim(p.name_middle))
               if (size(p.name_last,1) > 0)     ;034
                  temp_req->qual[d.seq]->eprsnl_bname = concat(trim(temp_req->qual[d.seq]->eprsnl_bname)," ",trim(p.name_last))
               endif
         elseif (size(p.name_last,1) > 0)     ;034
               temp_req->qual[d.seq]->eprsnl_bname = concat(trim(temp_req->qual[d.seq]->eprsnl_bname)," ",trim(p.name_last))
         endif
      elseif (size(p.name_middle,1) > 0)     ;034
         temp_req->qual[d.seq]->eprsnl_bname = trim(p.name_middle)
         if (size(p.name_last,1) > 0)     ;034
               temp_req->qual[d.seq]->eprsnl_bname = concat(trim(temp_req->qual[d.seq]->eprsnl_bname)," ",trim(p.name_last))
         endif
      elseif (size(p.name_last,1) > 0)     ;034
         temp_req->qual[d.seq]->eprsnl_bname = concat(trim(temp_req->qual[d.seq]->eprsnl_bname)," ",trim(p.name_last))
      else
         temp_req->qual[d.seq]->eprsnl_bname = temp_req->qual[d.seq]->eprsnl_name
      endif
      if (size(trim(temp_req->qual[d.seq]->eprsnl_bname,3),1) > 0 and size(trim(p.name_title, 3),1) > 0)     ;034
         temp_req->qual[d.seq]->eprsnl_bname = concat(trim(temp_req->qual[d.seq]->eprsnl_bname),", ",trim(p.name_title))
      endif
   with nocounter
   set iErrCode = error(sErrMsg,1)
   if (iErrCode > 0)
      set failed = SELECT_ERROR
      set table_name = "EPRSNL_NAME"
      go to EXIT_SCRIPT
   endif
endif
 
;*** find multum table
set iErrCode = error(sErrMsg,1)
set iErrCode = 0
 
select into "nl:"
from
    dba_tables d
plan d where
    d.table_name = "MLTM_NDC_MAIN_DRUG_CODE" and
    d.owner = "V500"
detail
    use_pco = TRUE
with nocounter
 
set iErrCode = error(sErrMsg,1)
if (iErrCode > 0)
    set failed = SELECT_ERROR
    set table_name = "DBA_TABLES"
    go to EXIT_SCRIPT
endif
 
if (use_pco = FALSE)
    set iErrCode = error(sErrMsg,1)
    set iErrCode = 0
 
    select into "nl:"
    from
	dba_tables d
    plan d where
	d.table_name = "NDC_MAIN_MULTUM_DRUG_CODE" and
	d.owner = "V500"
    detail
	v500_ind = TRUE
    with nocounter
    set iErrCode = error(sErrMsg,1)
    if (iErrCode > 0)
	set failed = SELECT_ERROR
	set table_name = "DBA_TABLES"
	go to EXIT_SCRIPT
    endif
endif
 
set iErrCode = error(sErrMsg,1)
set iErrCode = 0
 
set non_blank_nbr = TRUE                                                    ;008
set mltm_loaded   = FALSE                                                   ;008
 
if (use_pco = TRUE)
    select into "nl:"
    from
        (dummyt d with seq = value(temp_req->qual_knt)),
        mltm_ndc_main_drug_code n
    plan d where
        d.seq > 0 ;and
        ;size(temp_req->qual[d.seq]->d_nbr,1) > 0     ;034          ;008
    join n where
        n.drug_identifier = temp_req->qual[d.seq]->d_nbr
    order
        d.seq,
        n.csa_schedule
 
    head d.seq
        if (size(temp_req->qual[d.seq]->d_nbr,1) > 0)     ;034      ;008
            mltm_loaded = TRUE                                              ;008
            non_blank_nbr = FALSE                                           ;008
        endif                                                               ;008
        temp_req->qual[d.seq]->csa_schedule = n.csa_schedule
        if (n.csa_schedule = "0")
            temp_req->qual[d.seq]->csa_group = "C"
        elseif (n.csa_schedule = "1" or n.csa_schedule = "2")
            temp_req->qual[d.seq]->csa_group = "A"
        elseif (n.csa_schedule = "3" or n.csa_schedule = "4" or n.csa_schedule = "5")
            temp_req->qual[d.seq]->csa_group = "B"
        elseif (temp_req->qual[d.seq]->d_nbr <= " ")                        ;010
            temp_req->qual[d.seq]->csa_schedule = "0"                       ;010
            csa_group_cnt = csa_group_cnt + 1                               ;010
            temp_req->qual[d.seq]->csa_group = concat("D",                  ;010
                trim(cnvtstring(csa_group_cnt)))                            ;010
        else
            temp_req->qual[d.seq]->csa_group = "C"
        endif
    with outerjoin = d, nocounter                                           ;010
 
    set iErrCode = error(sErrMsg,1)
    if ((iErrCode > 0 or mltm_loaded = FALSE) and non_blank_nbr = FALSE)    ;008
        set failed = SELECT_ERROR
        set table_name = "MLTM_CSA_SCHEDULE"
        if (mltm_loaded = FALSE)
            set sErrMsg = "Table is Empty"
        endif
        go to EXIT_SCRIPT
    endif
elseif (v500_ind = TRUE)
    select into "nl:"
    from
        (dummyt d with seq = value(temp_req->qual_knt)),
        ndc_main_multum_drug_code n
    plan d where
        d.seq > 0 ;and
        ;size(temp_req->qual[d.seq]->d_nbr,1) > 0     ;034          ;008
    join n where
        n.drug_identifier = temp_req->qual[d.seq]->d_nbr
    order
        d.seq,
        n.csa_schedule
    head d.seq
        if (size(temp_req->qual[d.seq]->d_nbr,1) > 0)     ;034      ;008
            mltm_loaded = TRUE                                              ;008
            non_blank_nbr = FALSE                                           ;008
        endif                                                               ;008
        temp_req->qual[d.seq]->csa_schedule = n.csa_schedule
        if (n.csa_schedule = "0")
            temp_req->qual[d.seq]->csa_group = "C"
        elseif (n.csa_schedule = "1" or n.csa_schedule = "2")
            temp_req->qual[d.seq]->csa_group = "A"
        elseif (n.csa_schedule = "3" or n.csa_schedule = "4" or n.csa_schedule = "5")
            temp_req->qual[d.seq]->csa_group = "B"
        elseif (temp_req->qual[d.seq]->d_nbr <= " ")                        ;010
            temp_req->qual[d.seq]->csa_schedule = "0"                       ;010
            csa_group_cnt = csa_group_cnt + 1                               ;010
            temp_req->qual[d.seq]->csa_group = concat("D",                  ;010
                trim(cnvtstring(csa_group_cnt)))                            ;010
        else
            temp_req->qual[d.seq]->csa_group = "C"
        endif
    with outerjoin = d, nocounter                                           ;010
 
    set iErrCode = error(sErrMsg,1)
    if ((iErrCode > 0 or mltm_loaded = FALSE) and non_blank_nbr = FALSE)    ;008
        set failed = SELECT_ERROR
        set table_name = "CSA_SCHEDULE"
        if (mltm_loaded = FALSE)
            set sErrMsg = "Table is Empty"
        endif
        go to EXIT_SCRIPT
    endif
else
    select into "nl:"
    from
        (dummyt d with seq = value(temp_req->qual_knt)),
        v500_ref.ndc_main_multum_drug_code n
    plan d where
        d.seq > 0 ;and
        ;size(temp_req->qual[d.seq]->d_nbr,1) > 0     ;034          ;008
    join n where
        n.drug_id = temp_req->qual[d.seq]->d_nbr
    order
        d.seq,
        n.csa_schedule
    head d.seq
        if (size(temp_req->qual[d.seq]->d_nbr,1) > 0)     ;034      ;008
            mltm_loaded = TRUE                                              ;008
            non_blank_nbr = FALSE                                           ;008
        endif                                                               ;008
        temp_req->qual[d.seq]->csa_schedule = n.csa_schedule
        if (n.csa_schedule = "0")
            temp_req->qual[d.seq]->csa_group = "C"
        elseif (n.csa_schedule = "1" or n.csa_schedule = "2")
            temp_req->qual[d.seq]->csa_group = "A"
        elseif (n.csa_schedule = "3" or n.csa_schedule = "4" or n.csa_schedule = "5")
            temp_req->qual[d.seq]->csa_group = "B"
        elseif (temp_req->qual[d.seq]->d_nbr <= " ")                        ;010
            temp_req->qual[d.seq]->csa_schedule = "0"                       ;010
            csa_group_cnt = csa_group_cnt + 1                               ;010
            temp_req->qual[d.seq]->csa_group = concat("D",                  ;010
                trim(cnvtstring(csa_group_cnt)))                            ;010
        else
            temp_req->qual[d.seq]->csa_group = "C"
        endif
    with outerjoin = d, nocounter                                           ;010
 
    set iErrCode = error(sErrMsg,1)
    if ((iErrCode > 0 or mltm_loaded = FALSE) and non_blank_nbr = FALSE)    ;008
        set failed = SELECT_ERROR
        set table_name = "V500_CSA_SCHEDULE"
        if (mltm_loaded = FALSE)
            set sErrMsg = "Table is Empty"
        endif
        go to EXIT_SCRIPT
    endif
endif
 
;*** get order detail
set iErrCode = error(sErrMsg,1)
set iErrCode = 0
 
select into "nl:"
from
    order_detail od,
    oe_format_fields oef,
    (dummyt d1 with seq = value(temp_req->qual_knt))
plan d1 where
    d1.seq > 0
join od where
    od.order_id = temp_req->qual[d1.seq]->order_id
join oef where
    oef.oe_format_id = temp_req->qual[d1.seq]->oe_format_id and
    oef.oe_field_id = od.oe_field_id
order
    od.order_id,
    oef.group_seq,
    oef.field_seq,
    od.oe_field_id,
    od.action_sequence desc
 
head od.oe_field_id
    act_seq = od.action_sequence
    odflag = TRUE
 
head od.action_sequence
    if (act_seq != od.action_sequence)
        odflag = FALSE
    endif
 
detail
    if (odflag = TRUE)
        if (od.oe_field_meaning_id = 2107)
            temp_req->qual[d1.seq]->print_dea = od.oe_field_value
 
        elseif (od.oe_field_meaning_id = 2056)
            temp_req->qual[d1.seq]->strength_dose = trim(od.oe_field_display_value,3)     ;034
 
        elseif (od.oe_field_meaning_id = 2057)
            temp_req->qual[d1.seq]->strength_dose_unit = trim(od.oe_field_display_value,3)     ;034
 
        elseif (od.oe_field_meaning_id = 2058)
            temp_req->qual[d1.seq]->volume_dose = trim(od.oe_field_display_value,3)     ;034
 
        elseif (od.oe_field_meaning_id = 2059)
            temp_req->qual[d1.seq]->volume_dose_unit = trim(od.oe_field_display_value,3)     ;034
 
        elseif (od.oe_field_meaning_id = 2063)
            temp_req->qual[d1.seq]->freetext_dose = trim(od.oe_field_display_value,3)     ;034
 
        elseif (od.oe_field_meaning_id = 2050)
            temp_req->qual[d1.seq]->rx_route = trim(od.oe_field_display_value,3)     ;034
 
        elseif (od.oe_field_meaning_id = 2011)
            temp_req->qual[d1.seq]->frequency = trim(od.oe_field_display_value,3)     ;034
            temp_req->qual[d1.seq]->frequency_cd = od.oe_field_value	;020
 
        elseif (od.oe_field_meaning_id = 2061)
            temp_req->qual[d1.seq]->duration = trim(od.oe_field_display_value,3)     ;034
 
        elseif (od.oe_field_meaning_id = 2062)
            temp_req->qual[d1.seq]->duration_unit = trim(od.oe_field_display_value,3)     ;034
 
        elseif (od.oe_field_meaning_id = 2015)
            temp_req->qual[d1.seq]->dispense_qty = trim(od.oe_field_display_value,3)     ;034
 
        elseif (od.oe_field_meaning_id = 2102)
            temp_req->qual[d1.seq]->dispense_qty_unit = trim(od.oe_field_display_value,3)     ;034
 
        ;BEGIN MOD 007
        elseif ((od.oe_field_meaning_id = 2290) and (od.oe_field_value > 0))
            temp_req->qual[d1.seq]->dispense_duration = trim(od.oe_field_display_value,3)     ;034
 
        elseif (od.oe_field_meaning_id = 2291)
            temp_req->qual[d1.seq]->dispense_duration_unit = trim(od.oe_field_display_value,3)     ;034
        ;END MOD 007
 
        elseif (od.oe_field_meaning_id = 67)
            temp_req->qual[d1.seq]->nbr_refills_txt = trim(od.oe_field_display_value,3)     ;034
            temp_req->qual[d1.seq]->nbr_refills     = od.oe_field_value
 
        elseif (od.oe_field_meaning_id = 2101)
            temp_req->qual[d1.seq]->prn_inst = trim(od.oe_field_display_value,3)     ;034
            temp_req->qual[d1.seq]->prn_ind = 1
 
        elseif (od.oe_field_id = 12663)
            temp_req->qual[d1.seq]->special_inst =trim(od.oe_field_display_value,3)
            call echo(build("sr:",od.oe_field_display_value))    ;034
 
 
        elseif (od.oe_field_meaning_id = 15)
            temp_req->qual[d1.seq]->indications = trim(od.oe_field_display_value,3)     ;034
 
        elseif (od.oe_field_meaning_id = 2017)
            temp_req->qual[d1.seq]->daw = od.oe_field_value
 
        elseif (od.oe_field_meaning_id = 18)
            temp_req->qual[d1.seq]->perform_loc = trim(od.oe_field_display_value,3)     ;034
 
        elseif (od.oe_field_meaning_id = 2108)
            temp_req->qual[d1.seq]->phys_addr_id = od.oe_field_value
 
        elseif (od.oe_field_meaning_id = 1)
            temp_req->qual[d1.seq]->free_txt_ord = trim(od.oe_field_display_value,3)     ;034
 
        elseif (od.oe_field_meaning_id = 1560)
            temp_req->qual[d1.seq]->req_refill_date = od.oe_field_dt_tm_value
 
        elseif (od.oe_field_meaning_id = 51)
            temp_req->qual[d1.seq]->req_start_date = od.oe_field_dt_tm_value
 
        elseif (od.oe_field_meaning_id = 1558)
            temp_req->qual[d1.seq]->total_refills = od.oe_field_value
 
        elseif (od.oe_field_meaning_id = 1557 and od.oe_field_value > 0)              ;008
 
            temp_req->qual[d1.seq]->add_refills_txt = trim(cnvtstring(od.oe_field_value-1),3) ;015     ;034
 
            temp_req->qual[d1.seq]->add_refills = od.oe_field_value - 1               ;015
            temp_req->qual[d1.seq]->refill_ind = TRUE
 
        elseif (od.oe_field_meaning_id = 2105 and od.oe_field_value > 0 and not(is_a_reprint)) ;*** MOD 002
            temp_req->qual[d1.seq]->no_print = TRUE
 
        elseif (od.oe_field_meaning_id = 138 and
                is_a_reprint = FALSE and
                temp_req->qual[d1.seq]->csa_group != "A")  ;*** ORDEROUTPUTDEST
            temp_req->qual[d1.seq]->output_dest_cd = od.oe_field_value
 
        elseif (od.oe_field_meaning_id = 139 and
                is_a_reprint = FALSE and
                temp_req->qual[d1.seq]->csa_group != "A")  ;*** FREETEXTORDERFAXNUMBER
            temp_req->qual[d1.seq]->free_text_nbr = trim(od.oe_field_display_value,3)     ;034
 
        ;032 Start Drug Form detail
        elseif (od.oe_field_meaning_id = 2014)
            temp_req->qual[d1.seq]->drug_form = trim(od.oe_field_display_value,3)     ;034
        ;032 end
 
        endif
    endif
 
with nocounter
 
set iErrCode = error(sErrMsg,1)
if (iErrCode > 0)
    set failed = SELECT_ERROR
    set table_name = "ORDER_DETAIL"
    go to EXIT_SCRIPT
endif
 
;*** get order comments
set iErrCode = error(sErrMsg,1)
set iErrCode = 0
 
select into "nl:"
from
    (dummyt d with seq = value(temp_req->qual_knt)),
    order_comment oc,
    long_text lt
plan d where
    d.seq > 0 and
    temp_req->qual[d.seq]->get_comment_ind = TRUE
join oc where
    oc.order_id = temp_req->qual[d.seq]->order_id and
    oc.comment_type_cd = ord_comment_cd
join lt where
    lt.long_text_id = oc.long_text_id
order
    oc.order_id,
    oc.action_sequence desc
 
head oc.order_id
    found_comment = FALSE
 
detail
    if (found_comment = FALSE)
        found_comment = TRUE
        temp_req->qual[d.seq]->comments = lt.long_text
        temp_req->qual[d.seq]->comments = replace(temp_req->qual[d.seq]->comments,char(9),"    ",0)
    endif
with nocounter
 
set iErrCode = error(sErrMsg,1)
if (iErrCode > 0)
    set failed = SELECT_ERROR
    set table_name = "ORDER_DETAIL"
    go to EXIT_SCRIPT
endif
 
;*** find mrn by encntr_id
set iErrCode = error(sErrMsg,1)
set iErrCode = 0
 
select into "nl:"
    d.seq,
    ea.beg_effective_dt_tm
from
    (dummyt d with seq = value(temp_req->qual_knt)),
    encntr_alias ea
plan d where
    d.seq > 0 and
    temp_req->qual[d.seq]->encntr_id > 0
join ea where
    ea.encntr_id = temp_req->qual[d.seq]->encntr_id and
    ea.encntr_alias_type_cd = emrn_cd and
    (ea.active_ind = TRUE and
     ea.beg_effective_dt_tm <= cnvtdatetime(curdate,curtime3) and
     ea.end_effective_dt_tm > cnvtdatetime(curdate,curtime3))
order
    ;ea.beg_effective_dt_tm desc
    d.seq  ;MOD 008
 
head d.seq
    temp_req->qual[d.seq]->found_emrn = TRUE
    if (ea.alias_pool_cd > 0)
        temp_req->qual[d.seq]->mrn = trim(cnvtalias(ea.alias,ea.alias_pool_cd))
    else
        temp_req->qual[d.seq]->mrn = trim(ea.alias)
    endif
with nocounter
 
set iErrCode = error(sErrMsg,1)
if (iErrCode > 0)
    set failed = SELECT_ERROR
    set table_name = "LOAD_EMRN"
    go to EXIT_SCRIPT
endif
 
 
 
;047 BEGIN FIN
set iErrCode = error(sErrMsg,1)
set iErrCode = 0
 
select into "nl:"
    d.seq,
    ea.beg_effective_dt_tm
from
    (dummyt d with seq = value(temp_req->qual_knt)),
    encntr_alias ea
plan d where
    d.seq > 0 and
    temp_req->qual[d.seq]->encntr_id > 0
join ea where
    ea.encntr_id = temp_req->qual[d.seq]->encntr_id and
    ea.encntr_alias_type_cd = FIN_cd and
    (ea.active_ind = TRUE and
     ea.beg_effective_dt_tm <= cnvtdatetime(curdate,curtime3) and
     ea.end_effective_dt_tm > cnvtdatetime(curdate,curtime3))
order
 
    d.seq
 
head d.seq
 
    if (ea.alias_pool_cd > 0)
        temp_req->qual[d.seq]->fin = trim(cnvtalias(ea.alias,ea.alias_pool_cd))
    else
        temp_req->qual[d.seq]->fin = trim(ea.alias)
    endif
with nocounter
 
set iErrCode = error(sErrMsg,1)
if (iErrCode > 0)
    set failed = SELECT_ERROR
    set table_name = "LOAD_FIN"
    go to EXIT_SCRIPT
endif
;047 END FIN
 
 
 
;*** get mrn by person_id
set iErrCode = error(sErrMsg,1)
set iErrCode = 0
call echo(build("*** pmrn_cd :",pmrn_cd))
 
select into "nl:"
    d.seq,
    pa.beg_effective_dt_tm
from
    (dummyt d with seq = value(temp_req->qual_knt)),
    person_alias pa
plan d where
    d.seq > 0 and
    temp_req->qual[d.seq]->found_emrn = FALSE
join pa where
    pa.person_id = request->person_id and
    pa.person_alias_type_cd = pmrn_cd and
    (pa.active_ind = TRUE and
     pa.beg_effective_dt_tm <= cnvtdatetime(curdate,curtime3) and
     pa.end_effective_dt_tm > cnvtdatetime(curdate,curtime3))
order
    ;pa.beg_effective_dt_tm desc
    d.seq   ;MOD 011
 
head d.seq
    temp_req->qual[d.seq]->found_emrn = TRUE
 
    if (pa.alias_pool_cd > 0)
        temp_req->qual[d.seq]->mrn = trim(cnvtalias(pa.alias,pa.alias_pool_cd))
    else
        temp_req->qual[d.seq]->mrn = trim(pa.alias)
    endif
with nocounter
 
set iErrCode = error(sErrMsg,1)
if (iErrCode > 0)
    set failed = SELECT_ERROR
    set table_name = "LOAD_PMRN"
    go to EXIT_SCRIPT
endif
 
 
 
;047 BEGIN HEIGHT
select into "nl:"
from (dummyt d with seq = value(temp_req->qual_knt)),
	clinical_event ce
 
plan d
 where d.seq > 0
	 and  temp_req->qual[d.seq]->encntr_id > 0
join ce where
	ce.encntr_id = temp_req->qual[d.seq]->encntr_id
	and ce.event_cd = height_cd
 
detail
	temp_req->qual[d.seq]->height=ce.result_val
temp_req->qual[d.seq]->height_w_units = concat(trim(temp_req->qual[d.seq]->height)," ",uar_get_code_display(ce.result_units_cd))
 
with nocounter
;047 END HEIGHT
 
 
 
;047 BEGIN WEIGHT
select into "nl:"
from (dummyt d with seq = value(temp_req->qual_knt)),
	clinical_event ce
 
plan d
 where d.seq > 0
	 and  temp_req->qual[d.seq]->encntr_id > 0
join ce where
	ce.encntr_id = temp_req->qual[d.seq]->encntr_id
	and ce.event_cd = weight_cd
 
detail
	temp_req->qual[d.seq]->weight=ce.result_val
temp_req->qual[d.seq]->weight_w_units = concat(trim(temp_req->qual[d.seq]->weight)," ",uar_get_code_display(ce.result_units_cd))
 
with nocounter
;047 END WEIGHT
 
 
 
;*** find physician address by addr_id
set iErrCode = error(sErrMsg,1)
set iErrCode = 0
 
select into "nl:"
    d.seq
from
    (dummyt d with seq = value(temp_req->qual_knt)),
    address a
plan d where
    d.seq > 0 and
    temp_req->qual[d.seq]->no_print = FALSE and
    temp_req->qual[d.seq]->phys_addr_id > 0
join a where
    a.address_id = temp_req->qual[d.seq]->phys_addr_id
order
    d.seq   ;MOD 011
 
head d.seq
    temp_req->qual[d.seq]->found_phys_addr_ind = TRUE
    temp_req->qual[d.seq]->phys_addr1 = trim(a.street_addr)
 
    if (size(a.street_addr2,1) > 0)     ;034
        temp_req->qual[d.seq]->phys_addr2 = trim(a.street_addr2)
    endif
 
    if (size(a.street_addr3,1) > 0)     ;034
        temp_req->qual[d.seq]->phys_addr3 = trim(a.street_addr3)
    endif
 
    if (size(a.street_addr4,1) > 0)     ;034
        temp_req->qual[d.seq]->phys_addr4 = trim(a.street_addr4)
    endif
 
    if (size(a.city,1) > 0)     ;034
        temp_req->qual[d.seq]->phys_city = trim(a.city)
    endif
 
    if (size(a.state,1) > 0 or a.state_cd > 0)     ;034
        if (size(temp_req->qual[d.seq]->phys_city,1) > 0)     ;034
            if (a.state_cd > 0)
                temp_req->qual[d.seq]->phys_city = concat(trim(temp_req->qual[d.seq]->
                    phys_city),", ",trim(uar_get_code_display(a.state_cd)))
            else
                temp_req->qual[d.seq]->phys_city = concat(trim(temp_req->qual[d.seq]->
                    phys_city),", ",trim(a.state))
            endif
        else
            if (a.state_cd > 0)
                temp_req->qual[d.seq]->phys_city = trim(uar_get_code_display(a.state_cd))
            else
                temp_req->qual[d.seq]->phys_city = trim(a.state)
            endif
        endif
    endif
 
    if (size(a.zipcode,1) > 0)     ;034
        if (size(temp_req->qual[d.seq]->phys_city,1) > 0)     ;034
            temp_req->qual[d.seq]->phys_city = concat(trim(temp_req->qual[d.seq]->phys_city),
                " ",trim(a.zipcode))
        else
            temp_req->qual[d.seq]->phys_city = trim(a.zipcode)
        endif
    endif
with nocounter
 
set iErrCode = error(sErrMsg,1)
if (iErrCode > 0)
    set failed = SELECT_ERROR
    set table_name = "PHYS_ADDR1"
    go to EXIT_SCRIPT
endif
 
;*** find dea number
;*** find npi number ;029
set iErrCode = error(sErrMsg,1)
set iErrCode = 0
 
select into "nl:"
    d.seq,
    pa.prsnl_alias_type_cd,
    pa.beg_effective_dt_tm
from
    (dummyt d with seq = value(temp_req->qual_knt)),
    prsnl_alias pa
plan d where
    d.seq > 0 and
    temp_req->qual[d.seq]->no_print = FALSE and
    temp_req->qual[d.seq]->phys_id > 0
join pa where
    pa.person_id > 0 and                                    ;013
    pa.person_id in (temp_req->qual[d.seq]->phys_id,temp_req->qual[d.seq]->sup_phys_id) and
    pa.prsnl_alias_type_cd in (docdea_cd,docnpi_cd) and		;029
    (pa.active_ind = TRUE and
     pa.beg_effective_dt_tm <= cnvtdatetime(curdate,curtime3) and
     pa.end_effective_dt_tm > cnvtdatetime(curdate,curtime3))
order
    d.seq,
    pa.prsnl_alias_type_cd,
    pa.person_id,
    pa.beg_effective_dt_tm desc
 
;head report           ***MOD 013
;    found_dea = FALSE ***MOD 013
 
head d.seq
    found_dea = FALSE
    found_dea_sup = FALSE ;013
 
head pa.prsnl_alias_type_cd ;030
    found_npi = FALSE		;029
    found_npi_sup = FALSE 	;029
 
head pa.person_id
    if (found_dea = FALSE and pa.prsnl_alias_type_cd = docdea_cd and pa.person_id=temp_req->qual[d.seq]->phys_id)   ;013
        found_dea = TRUE
 
        if (pa.alias_pool_cd > 0)
            temp_req->qual[d.seq]->phys_dea = trim(cnvtalias(pa.alias,pa.alias_pool_cd))
        else
            temp_req->qual[d.seq]->phys_dea = trim(pa.alias)
        endif
    endif
 
    ;MOD 013 Start - Added in order to get the dea for the supervising physician
 
    if (found_dea_sup = FALSE and pa.prsnl_alias_type_cd = docdea_cd and pa.person_id=temp_req->qual[d.seq]->sup_phys_id)
        found_dea_sup = TRUE
 
        if (pa.alias_pool_cd > 0)
            temp_req->qual[d.seq]->sup_phys_dea = trim(cnvtalias(pa.alias,pa.alias_pool_cd))
        else
            temp_req->qual[d.seq]->sup_phys_dea = trim(pa.alias)
        endif
    endif
    ;MOD 013 Stop
 
 	/*** start 029 ***/
    if (found_npi = FALSE and pa.prsnl_alias_type_cd = docnpi_cd and pa.person_id=temp_req->qual[d.seq]->phys_id)
        found_npi = TRUE
		if (pa.alias_pool_cd > 0)
			temp_req->qual[d.seq]->phys_npi = trim(cnvtalias(pa.alias,pa.alias_pool_cd))
		else
			temp_req->qual[d.seq]->phys_npi = trim(pa.alias)
		endif
	endif
 
	if (found_npi_sup = FALSE and pa.prsnl_alias_type_cd = docnpi_cd and pa.person_id=temp_req->qual[d.seq]->sup_phys_id)
        found_npi_sup = TRUE
		if (pa.alias_pool_cd > 0)
			temp_req->qual[d.seq]->sup_phys_npi = trim(cnvtalias(pa.alias,pa.alias_pool_cd))
		else
			temp_req->qual[d.seq]->sup_phys_npi = trim(pa.alias)
		endif
	endif
 	/*** end 029 ***/
 
with nocounter
 
set iErrCode = error(sErrMsg,1)
if (iErrCode > 0)
    set failed = SELECT_ERROR
    set table_name = "PHYS_DEA"
    go to EXIT_SCRIPT
endif
 
;*** find physician address by phys_id
set iErrCode = error(sErrMsg,1)
set iErrCode = 0
 
select into "nl:"
    d.seq,
    a.beg_effective_dt_tm
from
    (dummyt d with seq = value(temp_req->qual_knt)),
    address a
plan d where
    d.seq > 0 and
    temp_req->qual[d.seq]->no_print = FALSE and
    temp_req->qual[d.seq]->found_phys_addr_ind = FALSE and
    temp_req->qual[d.seq]->phys_id > 0
join a where
    a.parent_entity_id = temp_req->qual[d.seq]->phys_id and
    a.parent_entity_name in ("PERSON","PRSNL") and
    a.address_type_cd = work_add_cd and
    (a.active_ind = 1 and
     a.beg_effective_dt_tm <= cnvtdatetime(curdate,curtime3) and
     a.end_effective_dt_tm > cnvtdatetime(curdate,curtime3))
order
    d.seq,
    a.beg_effective_dt_tm desc
 
head d.seq
    if (temp_req->qual[d.seq]->found_phys_addr_ind = FALSE)
 
        temp_req->qual[d.seq]->phys_addr_id        = a.address_id
        temp_req->qual[d.seq]->found_phys_addr_ind = TRUE
        temp_req->qual[d.seq]->phys_addr1          = trim(a.street_addr)
 
        if (size(a.street_addr2,1) > 0)     ;034
            temp_req->qual[d.seq]->phys_addr2 = trim(a.street_addr2)
        endif
 
        if (size(a.street_addr3,1) > 0)     ;034
            temp_req->qual[d.seq]->phys_addr3 = trim(a.street_addr3)
        endif
 
        if (size(a.street_addr4,1) > 0)     ;034
            temp_req->qual[d.seq]->phys_addr4 = trim(a.street_addr4)
        endif
 
        if (size(a.city,1) > 0)     ;034
            temp_req->qual[d.seq]->phys_city = trim(a.city)
        endif
 
        if (size(a.state,1) > 0 or a.state_cd > 0)     ;034
            if (size(temp_req->qual[d.seq]->phys_city,1) > 0)     ;034
                if (a.state_cd > 0)
                temp_req->qual[d.seq]->phys_city = concat(trim(temp_req->qual[d.seq]->
                    phys_city),", ",trim(uar_get_code_display(a.state_cd)))
                else
                    temp_req->qual[d.seq]->phys_city = concat(trim(temp_req->qual[d.seq]->
                        phys_city),", ",trim(a.state))
                endif
            else
                if (a.state_cd > 0)
                    temp_req->qual[d.seq]->phys_city = trim(uar_get_code_display(a.state_cd))
                else
                    temp_req->qual[d.seq]->phys_city = trim(a.state)
                endif
            endif
        endif
 
        if (size(a.zipcode,1) > 0)     ;034
            if (size(temp_req->qual[d.seq]->phys_city,1) > 0)     ;034
 
                temp_req->qual[d.seq]->phys_city = concat(trim(temp_req->qual[d.seq]->
                    phys_city)," ",trim(a.zipcode))
            else
                temp_req->qual[d.seq]->phys_city = trim(a.zipcode)
            endif
        endif
    endif
with nocounter
 
set iErrCode = error(sErrMsg,1)
if (iErrCode > 0)
    set failed = SELECT_ERROR
    set table_name = "PHYS_ADDR2"
    go to EXIT_SCRIPT
endif
 
;*** Find doctor phone number
select into "nl:"
from
    (dummyt d with seq = value(temp_req->qual_knt)),
    phone p
    ,phone p2
plan d where
    d.seq > 0
join p where
    p.parent_entity_id = temp_req->qual[d.seq]->phys_id and
    p.parent_entity_name in ("PERSON","PRSNL") and
    p.phone_type_cd = work_phone_cd and
    (p.active_ind = 1 and
     p.beg_effective_dt_tm <= cnvtdatetime(curdate,curtime3) and
     p.end_effective_dt_tm > cnvtdatetime(curdate,curtime3))
join p2 where
    p2.parent_entity_id = temp_req->qual[d.seq]->phys_id and
    p2.parent_entity_name in ("PERSON","PRSNL") and
    p2.phone_type_cd = 43_FAX_PHONE and
    (p2.active_ind = 1 and
     p2.beg_effective_dt_tm <= cnvtdatetime(curdate,curtime3) and
     p2.end_effective_dt_tm > cnvtdatetime(curdate,curtime3))
order
    d.seq,
    p.beg_effective_dt_tm desc
 
head d.seq
  temp_req->qual[d.seq]->phys_phone = trim(cnvtphone(p.phone_num,p.phone_format_cd,2))
  temp_req->qual[d.seq]->phys_fax = trim(cnvtphone(p2.phone_num, p2.phone_format_cd, 2))
with nocounter
 
;*** find health plans by encntr
set iErrCode = error(sErrMsg,1)
set iErrCode = 0
 
select into "nl:"
    d.seq,
    epr.beg_effective_dt_tm
from
    (dummyt d with seq = value(temp_req->qual_knt)),
    encntr_plan_reltn epr,
    health_plan hp,
    organization o
plan d where
    d.seq > 0 and
    temp_req->qual[d.seq]->encntr_id > 0
join epr where
    epr.encntr_id = temp_req->qual[d.seq]->encntr_id and
    epr.priority_seq in (1,2,99) and
    (epr.active_ind = TRUE and
     epr.beg_effective_dt_tm <= cnvtdatetime(curdate,curtime3) and
     epr.end_effective_dt_tm > cnvtdatetime(curdate,curtime3))
join hp where
    hp.health_plan_id = epr.health_plan_id and
    hp.active_ind = TRUE
join o where
    o.organization_id= epr.organization_id
order
    d.seq,
    epr.beg_effective_dt_tm desc
 
head report
    hp_99_name   = fillstring(100," ")
    hp_99_polgrp = fillstring(200," ")
 
head d.seq
    found_pri_hp = FALSE
    found_sec_hp = FALSE
    found_99_hp  = FALSE
 
detail
 
    if (epr.priority_seq = 1 and found_pri_hp = FALSE)
        temp_req->qual[d.seq]->hp_pri_found  = TRUE
        temp_req->qual[d.seq]->hp_pri_name   = trim(o.org_name)
        temp_req->qual[d.seq]->hp_pri_polgrp = concat(trim(epr.member_nbr),"/",
            trim(hp.group_nbr))
        found_pri_hp = TRUE
    endif
 
    if (epr.priority_seq = 2 and found_sec_hp = FALSE)
        temp_req->qual[d.seq]->hp_sec_found  = TRUE
        temp_req->qual[d.seq]->hp_sec_name   = trim(o.org_name)
        temp_req->qual[d.seq]->hp_sec_polgrp = concat(trim(epr.member_nbr),"/",
            trim(hp.group_nbr))
        found_sec_hp = TRUE
    endif
 
    if (epr.priority_seq = 99 and found_99_hp = FALSE)
        hp_99_name   = trim(o.org_name)
        hp_99_polgrp = concat(trim(epr.member_nbr),"/",trim(hp.group_nbr))
        found_99_hp  = TRUE
    endif
 
foot d.seq
    if (found_pri_hp = FALSE and found_99_hp = TRUE)
        temp_req->qual[d.seq]->hp_pri_found  = TRUE
        temp_req->qual[d.seq]->hp_pri_name   = trim(hp_99_name)
        temp_req->qual[d.seq]->hp_pri_polgrp = trim(hp_99_polgrp)
        found_pri_hp = TRUE
    endif
with nocounter
 
set iErrCode = error(sErrMsg,1)
if (iErrCode > 0)
    set failed = SELECT_ERROR
    set table_name = "ENCNTR_HEALTH"
    go to EXIT_SCRIPT
endif
 
;*** find health plans by person
set iErrCode = error(sErrMsg,1)
set iErrCode = 0
 
select into "nl:"
    d.seq,
    ppr.beg_effective_dt_tm
from
    (dummyt d with seq = value(temp_req->qual_knt)),
    person_plan_reltn ppr,
    health_plan hp,
    organization o
plan d where
    d.seq > 0 and
    (temp_req->qual[d.seq]->hp_pri_found = FALSE or
     temp_req->qual[d.seq]->hp_sec_found = FALSE)
join ppr where
    ppr.person_id = request->person_id and
    ppr.priority_seq in (1,2,99) and
    (ppr.active_ind = TRUE and
     ppr.beg_effective_dt_tm <= cnvtdatetime(curdate,curtime3) and
     ppr.end_effective_dt_tm > cnvtdatetime(curdate,curtime3))
join hp where
    hp.health_plan_id = ppr.health_plan_id and
    hp.active_ind = TRUE
join o where
    o.organization_id= ppr.organization_id
order
    d.seq,
    ppr.beg_effective_dt_tm desc
 
head report
    hp_99_name = fillstring(100," ")
    hp_99_polgrp = fillstring(200," ")
 
head d.seq
    found_pri_hp = FALSE
    found_sec_hp = FALSE
    found_99_hp = FALSE
 
detail
    if (ppr.priority_seq = 1 and found_pri_hp = FALSE and
        temp_req->qual[d.seq]->hp_pri_found = FALSE)
 
        temp_req->qual[d.seq]->hp_pri_found  = TRUE
        temp_req->qual[d.seq]->hp_pri_name   = trim(o.org_name)
        temp_req->qual[d.seq]->hp_pri_polgrp = concat(trim(ppr.member_nbr),"/",
            trim(hp.group_nbr))
        found_pri_hp = TRUE
    endif
 
    if (ppr.priority_seq = 2 and found_sec_hp = FALSE and
       temp_req->qual[d.seq]->hp_sec_found = FALSE)
 
        temp_req->qual[d.seq]->hp_sec_found  = TRUE
        temp_req->qual[d.seq]->hp_sec_name   = trim(o.org_name)
        temp_req->qual[d.seq]->hp_sec_polgrp = concat(trim(ppr.member_nbr),"/",
            trim(hp.group_nbr))
        found_sec_hp = TRUE
    endif
 
    if (ppr.priority_seq = 99 and found_99_hp = FALSE and
        temp_req->qual[d.seq]->hp_pri_found = FALSE)
 
        hp_99_name   = trim(o.org_name)
        hp_99_polgrp = concat(trim(ppr.member_nbr),"/",trim(hp.group_nbr))
        found_99_hp  = TRUE
   endif
 
foot d.seq
    if (found_pri_hp = FALSE and found_99_hp = TRUE)
        temp_req->qual[d.seq]->hp_pri_found  = TRUE
        temp_req->qual[d.seq]->hp_pri_name   = trim(hp_99_name)
        temp_req->qual[d.seq]->hp_pri_polgrp = trim(hp_99_polgrp)
        found_pri_hp = TRUE
   endif
with nocounter
 
set iErrCode = error(sErrMsg,1)
if (iErrCode > 0)
    set failed = SELECT_ERROR
    set table_name = "PERSON_HEALTH"
    go to EXIT_SCRIPT
endif
 
; EPCS - check if messaging_audit table has an entry for the order_ids in temp_req
; if so, then the orders were electronically routed, then check if each of the temp_req->qual[*] is a controlled substance
; if the order is a controlled substance (CS), check if electronic routing was successful or failed
; if the electronic routing was successful for the CS include a label stating "copy - not for dispensing"
; in the printed requisition
; if the electronic routing had failed for the CS, include a label in the printed requisition, stating that the electronic
; routing had failed, and also mention the pharmacy name to which routing had failed
; These labels are repated individually for each of the controlled substances in the requisition, since there could be a mix
; of orders whose electronic routing failed or successful
 
declare FIELD_MEANING_ROUTING_PHARMACY_NAME = i4 with constant(1565)
; define constants mapped to electornic routing success code values in code set 3401
declare MSG_AUDIT_STATUS_CD_COMPLETE   = f8 with constant(uar_get_code_by("MEANING",3401,"COMPLETE"))
declare MSG_AUDIT_STATUS_CD_DELIVERED  = f8 with constant(uar_get_code_by("MEANING",3401,"DELIVERED"))
declare MSG_AUDIT_STATUS_CD_INPROGRESS = f8 with constant(uar_get_code_by("MEANING",3401,"IN PROGRESS"))
 
select into "nl:"
       m_status_cd =  m.status_cd,
       m.order_id,
	   od_pharmacy_name = od.OE_FIELD_DISPLAY_VALUE,
	   m.audit_dt_tm
from  messaging_audit   m, order_detail od
where expand(erx_idx,1,size(temp_req->qual, 5),m.order_id,temp_req->qual[erx_idx].order_id) and
      ((m.publish_ind = 1) and (od.OE_FIELD_MEANING_ID=FIELD_MEANING_ROUTING_PHARMACY_NAME) and
       (m.order_id = od.order_id ))
order m.order_id, m.audit_dt_tm desc, od.action_sequence
 
head m.order_id
     locate_idx = 0
head m.audit_dt_tm
     newIndex = locateval(locate_idx, 1, size(temp_req->qual,5), m.order_id, temp_req->qual[locate_idx].order_id)
     call echo(build("s1:",uar_get_code_display(m.status_cd)))
     ; if csa_schedule is "0" it is not a controlled substance
     if ((temp_req->qual[newIndex]->csa_schedule <= "0") or (temp_req->qual[newIndex]->csa_schedule <= ""))
             temp_req->qual[newIndex]->second_attempt_note = "" ; EPCS specific labeling : None
     else ; for controlled substances attempted EPCS
          if (m_status_cd in (MSG_AUDIT_STATUS_CD_COMPLETE, MSG_AUDIT_STATUS_CD_DELIVERED, MSG_AUDIT_STATUS_CD_INPROGRESS))
              ; EPCS specific labeling : Copy, not for dispensing
              temp_req->qual[newIndex]->second_attempt_note =
                         "***COPY - NOT FOR DISPENSING.FOR INFORMATIONAL PURPOSES ONLY. ***"
          else
              temp_req->qual[newIndex]->second_attempt_note =
                       "THE PRESCRIPTION WAS ORIGINALLY TRANSMITTED ELECTRONICALLY TO PHARMACY AND FAILED."
               temp_req->qual[newIndex]->routing_pharmacy_name = trim(od_pharmacy_name)
               temp_req->qual[newIndex]->routing_dt_tm = od.updt_dt_tm
          endif
      endif
with nocounter
;031
select into "nl:"
from  (dummyt d with seq = size(temp_req->qual, 5)),
      order_catalog_synonym ocs,
      orders o
 
plan  d
where d.seq > 0
 
join o
where o.order_id = temp_req->qual[d.seq]->order_id
 
join ocs
where ocs.synonym_id = o.synonym_id
 
detail
temp_req->qual[d.seq]->mnemonic_type_cd = ocs.mnemonic_type_cd
with nocounter
 
;*** parse details
for (a = 1 to temp_req->qual_knt)
 
    if (temp_req->qual[a]->no_print = FALSE)
 
        if (size(temp_req->qual[a]->free_txt_ord,1) > 0)     ;034
            set temp_req->qual[a]->med_name = trim(temp_req->qual[a]->free_txt_ord)
        else
            set temp_req->qual[a]->med_name = trim(temp_req->qual[a]->order_as_mnemonic)
        endif
 
        ;MOD 013 Start - Should look like a new prescription when having additional refill.
 
        if (size(temp_req->qual[a]->add_refills_txt,1) > 0 and temp_req->qual[a]->add_refills > 0)     ;034
            set temp_req->qual[a]->refill_line = trim(temp_req->qual[a]->add_refills_txt)
 
        ;MOD 013 End
 
        else
            ;008
            if (size(temp_req->qual[a]->nbr_refills_txt,1) > 0 and temp_req->qual[a]->nbr_refills > 0)     ;034
                    set temp_req->qual[a]->refill_line = trim(temp_req->qual[a]->nbr_refills_txt)
            endif
 
		endif	;Mod 014 PC3603
 
		 if (size(temp_req->qual[a]->refill_line,1) > 0)     ;034
                set temp_req->qual[a]->refill_line = build2("<",trim(temp_req->qual[a]->refill_line, 3),">")
 
            endif
 
        set temp_req->qual[a]->med_name = trim(temp_req->qual[a]->med_name, 3)
 
        set temp_req->qual[a]->start_date = cnvtdatetime(cnvtdate(temp_req->qual[a]->
                req_start_date),0)
 
        if (size(temp_req->qual[a]->strength_dose,1) > 0 and size(temp_req->qual[a]->volume_dose,1) > 0)     ;034
 
          ; For Orders containing both strength and volume doses the requisitions will only
          ; print strength dose for Primary, Brand and C type mnemonics   037
 
           if (temp_req->qual[a]->mnemonic_type_cd = value(primary_mnemonic_type_cd) or
               temp_req->qual[a]->mnemonic_type_cd = value(brand_mnemonic_type_cd) or
               temp_req->qual[a]->mnemonic_type_cd = value(c_mnemonic_type_cd))
 
            	set temp_req->qual[a]->sig_line = trim(temp_req->qual[a]->strength_dose)
 
            	if (size(temp_req->qual[a]->strength_dose_unit,1) > 0)     ;034
                	set temp_req->qual[a]->sig_line = concat(trim(temp_req->qual[a]->sig_line),
                    	" ",trim(temp_req->qual[a]->strength_dose_unit))
            	endif
 
          else   ;031
 
            	set temp_req->qual[a]->sig_line = trim(temp_req->qual[a]->volume_dose)
 
            	if (size(temp_req->qual[a]->volume_dose_unit,1) > 0)     ;034
               	 set temp_req->qual[a]->sig_line = concat(trim(temp_req->qual[a]->sig_line),
                    	" ",trim(temp_req->qual[a]->volume_dose_unit))
            	endif
 
           endif  ;031
 
            ;032 Start Drug From
            if (size(temp_req->qual[a]->drug_form,1) > 0 and not     ;034
                   (temp_req->qual[a]->mnemonic_type_cd = value(generic_top_type_cd)
                    or temp_req->qual[a]->mnemonic_type_cd = value(trade_top_type_cd)
                    or temp_req->qual[a]->mnemonic_type_cd = value(generic_prod_type_cd)
                    or temp_req->qual[a]->mnemonic_type_cd = value(trade_prod_type_cd)))
            	set temp_req->qual[a]->sig_line = concat(trim(temp_req->qual[a]->sig_line),
                    " ",trim(temp_req->qual[a]->drug_form))
            endif
            ;032 End
 
            if (size(temp_req->qual[a]->rx_route,1) > 0)     ;034
                set temp_req->qual[a]->sig_line = concat(trim(temp_req->qual[a]->sig_line),
                    " ",trim(temp_req->qual[a]->rx_route))
            endif
 
            if (size(temp_req->qual[a]->frequency,1) > 0)     ;034
                set temp_req->qual[a]->sig_line = concat(trim(temp_req->qual[a]->sig_line),
                    " ",trim(temp_req->qual[a]->frequency))
            endif
 
            if (size(temp_req->qual[a]->duration,1) > 0)     ;034
                set temp_req->qual[a]->sig_line = concat(trim(temp_req->qual[a]->sig_line),
                    " for ",trim(temp_req->qual[a]->duration))
            endif
 
            if (size(temp_req->qual[a]->duration_unit,1) > 0)     ;034
                set temp_req->qual[a]->sig_line = concat(trim(temp_req->qual[a]->sig_line),
                    " ",trim(temp_req->qual[a]->duration_unit))
            endif
 
        elseif (size(temp_req->qual[a]->strength_dose,1) > 0)     ;034
 
            set temp_req->qual[a]->sig_line = trim(temp_req->qual[a]->strength_dose)
            if (size(temp_req->qual[a]->strength_dose_unit,1) > 0)     ;034
                set temp_req->qual[a]->sig_line = concat(trim(temp_req->qual[a]->sig_line),
                    " ",trim(temp_req->qual[a]->strength_dose_unit))
            endif
 
            ;032 Drug Form
            if (size(temp_req->qual[a]->drug_form,1) > 0 and not     ;034
                   (temp_req->qual[a]->mnemonic_type_cd = value(generic_top_type_cd)
                    or temp_req->qual[a]->mnemonic_type_cd = value(trade_top_type_cd)
                    or temp_req->qual[a]->mnemonic_type_cd = value(generic_prod_type_cd)
                    or temp_req->qual[a]->mnemonic_type_cd = value(trade_prod_type_cd)))
            	set temp_req->qual[a]->sig_line = concat(trim(temp_req->qual[a]->sig_line),
                    " ",trim(temp_req->qual[a]->drug_form))
            endif
            ;032 End
 
            if (size(temp_req->qual[a]->rx_route,1) > 0)     ;034
                set temp_req->qual[a]->sig_line = concat(trim(temp_req->qual[a]->sig_line),
                    " ",trim(temp_req->qual[a]->rx_route))
            endif
 
            if (size(temp_req->qual[a]->frequency,1) > 0)     ;034
                set temp_req->qual[a]->sig_line = concat(trim(temp_req->qual[a]->sig_line),
                    " ",trim(temp_req->qual[a]->frequency))
            endif
 
            if (size(temp_req->qual[a]->duration,1) > 0)     ;034
                set temp_req->qual[a]->sig_line = concat(trim(temp_req->qual[a]->sig_line),
                    " for ",trim(temp_req->qual[a]->duration))
            endif
 
            if (size(temp_req->qual[a]->duration_unit,1) > 0)     ;034
                set temp_req->qual[a]->sig_line = concat(trim(temp_req->qual[a]->sig_line),
                    " ",trim(temp_req->qual[a]->duration_unit))
            endif
 
        elseif (size(temp_req->qual[a]->volume_dose,1) > 0)     ;034
 
            set temp_req->qual[a]->sig_line = trim(temp_req->qual[a]->volume_dose)
            if (size(temp_req->qual[a]->volume_dose_unit,1) > 0)
                set temp_req->qual[a]->sig_line = concat(trim(temp_req->qual[a]->sig_line),
                    " ",trim(temp_req->qual[a]->volume_dose_unit))
            endif
 
            ;032 Drug Form
            if (size(temp_req->qual[a]->drug_form,1) > 0 and not     ;034
                   (temp_req->qual[a]->mnemonic_type_cd = value(generic_top_type_cd)
                    or temp_req->qual[a]->mnemonic_type_cd = value(trade_top_type_cd)
                    or temp_req->qual[a]->mnemonic_type_cd = value(generic_prod_type_cd)
                    or temp_req->qual[a]->mnemonic_type_cd = value(trade_prod_type_cd)))
            	set temp_req->qual[a]->sig_line = concat(trim(temp_req->qual[a]->sig_line),
                    " ",trim(temp_req->qual[a]->drug_form))
            endif
            ;032 End
 
            if (size(temp_req->qual[a]->rx_route,1) > 0)     ;034
                set temp_req->qual[a]->sig_line = concat(trim(temp_req->qual[a]->sig_line),
                    " ",trim(temp_req->qual[a]->rx_route))
            endif
 
            if (size(temp_req->qual[a]->frequency,1) > 0)     ;034
                set temp_req->qual[a]->sig_line = concat(trim(temp_req->qual[a]->sig_line),
                    " ",trim(temp_req->qual[a]->frequency))
            endif
 
            if (size(temp_req->qual[a]->duration,1) > 0)     ;034
                set temp_req->qual[a]->sig_line = concat(trim(temp_req->qual[a]->sig_line),
                    " for ",trim(temp_req->qual[a]->duration))
            endif
 
            if (size(temp_req->qual[a]->duration_unit,1) > 0)     ;034
                set temp_req->qual[a]->sig_line = concat(trim(temp_req->qual[a]->sig_line),
                    " ",trim(temp_req->qual[a]->duration_unit))
            endif
        else
            set temp_req->qual[a]->sig_line = trim(temp_req->qual[a]->freetext_dose)
 
            ;032 Drug Form
            if (size(temp_req->qual[a]->drug_form,1) > 0 and not     ;034
                   (temp_req->qual[a]->mnemonic_type_cd = value(generic_top_type_cd)
                    or temp_req->qual[a]->mnemonic_type_cd = value(trade_top_type_cd)
                    or temp_req->qual[a]->mnemonic_type_cd = value(generic_prod_type_cd)
                    or temp_req->qual[a]->mnemonic_type_cd = value(trade_prod_type_cd)))
            	set temp_req->qual[a]->sig_line = concat(trim(temp_req->qual[a]->sig_line),
                    " ",trim(temp_req->qual[a]->drug_form))
            endif
            ;032 End
 
            if (size(temp_req->qual[a]->rx_route,1) > 0)     ;034
                set temp_req->qual[a]->sig_line = concat(trim(temp_req->qual[a]->sig_line),
                    " ",trim(temp_req->qual[a]->rx_route))
            endif
 
            if (size(temp_req->qual[a]->frequency,1) > 0)     ;034
                set temp_req->qual[a]->sig_line = concat(trim(temp_req->qual[a]->sig_line),
                    " ",trim(temp_req->qual[a]->frequency))
            endif
 
            if (size(temp_req->qual[a]->duration,1) > 0)     ;034
                set temp_req->qual[a]->sig_line = concat(trim(temp_req->qual[a]->sig_line),
                    " for ",trim(temp_req->qual[a]->duration))
            endif
 
            if (size(temp_req->qual[a]->duration_unit,1) > 0)     ;034
                set temp_req->qual[a]->sig_line = concat(trim(temp_req->qual[a]->sig_line),
                    " ",trim(temp_req->qual[a]->duration_unit))
            endif
        endif
 
        if (temp_req->qual[a]->prn_ind = TRUE and size(temp_req->qual[a]->prn_inst,1) > 0)	; MOD 021     ;034
            set temp_req->qual[a]->sig_line = concat(trim(temp_req->qual[a]->sig_line)," PRN ",trim(temp_req->qual[a]->prn_inst))
        endif
 
        if (size(temp_req->qual[a]->sig_line,1) > 0)     ;034
      		set temp_req->qual[a]->sig_line = trim(temp_req->qual[a]->sig_line, 3)
 
        endif
 
        if (size(temp_req->qual[a]->dispense_qty,1) > 0)     ;034
 
            set dispense_number = temp_req->qual[a]->dispense_qty ;042
            set number_spellout = get_number_spellout(temp_req->qual[a]->dispense_qty) ;042
            if (size(temp_req->qual[a]->dispense_qty_unit,1) > 0)     ;034
               	set temp_req->qual[a]->dispense_line = trim(concat(temp_req->qual[a]->dispense_qty,
               	                                       " ",trim(temp_req->qual[a]->dispense_qty_unit)))
            else ;042
                set temp_req->qual[a]->dispense_line = trim(temp_req->qual[a]->dispense_qty)
            endif ;042
 
            if (number_spellout > "") ;042
                set temp_req->qual[a]->dispense_line = trim(concat(temp_req->qual[a]->
                    dispense_line," (",number_spellout,")")) ;042
            endif
 
        elseif (size(temp_req->qual[a]->dispense_qty_unit,1) > 0)     ;034
            set temp_req->qual[a]->dispense_line = trim(temp_req->qual[a]->dispense_qty_unit)
        endif
 
 	;BEGIN MOD 007
        if (size(temp_req->qual[a]->dispense_duration,1) > 0)     ;034
 
            set dispense_number = temp_req->qual[a]->dispense_duration ;042
            set number_spellout = get_number_spellout(temp_req->qual[a]->dispense_duration) ;042
            if (size(temp_req->qual[a]->dispense_duration_unit,1) > 0)     ;034
                set temp_req->qual[a]->dispense_duration_line = trim(concat(temp_req->qual[a]->dispense_duration,
                                                            " ",trim(temp_req->qual[a]->dispense_duration_unit)))
            else ;042
                set temp_req->qual[a]->dispense_duration_line = trim(temp_req->qual[a]->dispense_duration)
            endif ;042
 
            if (number_spellout > "") ;042
                set temp_req->qual[a]->dispense_duration_line = trim(concat(temp_req->qual[a]->
                    dispense_duration_line," (",number_spellout,")")) ;042
            endif
 
        elseif (size(temp_req->qual[a]->dispense_duration_unit,1) > 0)     ;034
            set temp_req->qual[a]->dispense_duration_line = trim(temp_req->qual[a]->dispense_duration_unit)
 
        endif
 
	if (size(temp_req->qual[a]->dispense_duration_line,1) > 0)     ;034
		set temp_req->qual[a]->dispense_duration_line = concat(temp_req->qual[a]->dispense_duration_line," supply")
		set temp_req->qual[a]->dispense_line = " "
	endif
	;END MOD 007
 
 
 
        if (size(temp_req->qual[a]->dispense_line,1) > 0)     ;034
        	set temp_req->qual[a]->dispense_line = build2("<", trim(temp_req->qual[a]->dispense_line, 3), ">")
 
        endif
 
 
 
	    ;BEGIN MOD 007
        if (size(temp_req->qual[a]->dispense_duration_line,1) > 0)     ;034
        	set temp_req->qual[a]->dispense_duration_line = build2("<", trim(temp_req->qual[a]->dispense_duration_line, 3), ">")
 
        endif
        ;END MOD 007
 
 
 
       if (size(temp_req->qual[a]->special_inst,1) > 0)     ;034
            set temp_req->qual[a]->special_inst = trim(temp_req->qual[a]->special_inst)
 
        endif
 
 
       if (size(temp_req->qual[a]->indications,1) > 0)     ;034
            set temp_req->qual[a]->indications = trim(temp_req->qual[a]->indications)
 
        endif
 
        if (size(temp_req->qual[a]->comments,1) > 0)     ;034
            set temp_req->qual[a]->comments = trim(temp_req->qual[a]->comments)
 
        endif
        ;EPCS labels - split the long text in second_attempt_note, into multiple lines of 60 chars
        ;by passing it to dcp_parse_text, which stores each of the lines in pt->lns and updates
        ; pt->line_cnt with the number of lines
        if (size(trim(temp_req->qual[a]->second_attempt_note),1) > 0)
            set temp_req->qual[a]->second_attempt_note = trim(temp_req->qual[a]->second_attempt_note)
 
        endif
    endif
endfor
 
/****************************************************************************
*       build print record                                                  *
*****************************************************************************/
free record tprint_req
record tprint_req
(
  1 job_knt = i4
  1 job[*]
    2 refill_ind     = i2
    2 phys_name      = vc
    2 phys_bname     = vc
    2 phys_fname     = vc
    2 phys_mname     = vc
    2 phys_lname     = vc
    2 pat_loc_name   = vc
	2 pat_loc_add    = vc
	2 pat_loc_bus_phone  = vc
	2 pat_loc_fax_phone  = vc
    2 eprsnl_id      = f8
    2 eprsnl_ind     = i2
    2 eprsnl_name    = vc
    2 eprsnl_bname   = vc
    2 eprsnl_fname   = vc
    2 eprsnl_mname   = vc
    2 eprsnl_lname   = vc
    2 phys_addr1     = vc
    2 phys_addr2     = vc
    2 phys_addr3     = vc
    2 phys_addr4     = vc
    2 phys_city      = vc
    2 phys_dea       = vc
    2 phys_npi		 = vc ;029
    2 sup_phys_npi   = vc ;029
    2 phys_lnbr      = vc
    2 phys_phone     = vc
    2 phys_fax		 = vc
    2 csa_group      = vc
    2 phys_ord_dt    = vc
    2 output_dest_cd = f8
    2 free_text_nbr  = vc
    2 print_loc      = vc
    2 daw            = i2
    2 mrn            = vc
    2 fin 			 = vc ;047
    2 height 			  = vc ;047
	2 weight 			  = vc ;047
	2 height_w_units      = vc ;047
	2 weight_w_units      = vc ;047
    2 hp_found       = i2
    2 hp_pri_name    = vc
    2 hp_pri_polgrp  = vc
    2 hp_sec_name    = vc
    2 hp_sec_polgrp  = vc
    2 req_knt        = i4
    2 req[*]
      3 order_id     = f8
      3 print_dea    = i2
      3 csa_sched    = c1
      3 start_dt     = vc
      3 req_start_dt = vc
      3 orig_dt_tm   = vc
      3 action_dt    = vc ;035
      3 med_disp	 = vc
	  3 sig_disp	 = vc
      3 dispense_disp           = vc
      3 dispense_duration_disp  = vc
      3 refill_disp             = vc
      3 special_disp            = vc
      3 special_inst_rtf		= vc
      3 prn_disp                = vc
      3 indic_disp	            = vc
      3 comment_disp            = vc
	  3 sec_att_disp            = vc
      3 erx_pharmacy_name       = vc
      3 erx_routing_dt_tm       = vc
      3 prim_dx_icd_code		= vc
	  3 prim_dx_description		= vc
    2 sup_phys_bname = vc   ;013
    2 sup_phys_dea   = vc   ;013
    2 sup_phys_id    = f8   ;013
    2 encntr_type_cd = f8
)
 
set iErrCode = error(sErrMsg,1)
set iErrCode = 0
 
select into "nl:"
    encntr_id = temp_req->qual[d.seq]->encntr_id,
    print_loc = temp_req->qual[d.seq]->print_loc,
    order_dt = format(cnvtdatetime(temp_req->qual[d.seq]->order_dt),'MM/DD/YYYY HH:MM;;Q'),
    print_dea = temp_req->qual[d.seq]->print_dea,
    csa_schedule = temp_req->qual[d.seq]->csa_schedule,
    csa_group = temp_req->qual[d.seq]->csa_group,
    daw = temp_req->qual[d.seq]->daw,
    output_dest_cd = temp_req->qual[d.seq]->output_dest_cd,
    free_text_nbr = temp_req->qual[d.seq]->free_text_nbr,
    fax_seq = build(temp_req->qual[d.seq]->output_dest_cd,temp_req->qual[d.seq]->free_text_nbr),
    phys_id = temp_req->qual[d.seq]->phys_id,
    phys_addr_id = temp_req->qual[d.seq]->phys_addr_id,
    phys_seq = build(temp_req->qual[d.seq]->phys_id,temp_req->qual[d.seq]->phys_addr_id),
    refill_ind = temp_req->qual[d.seq]->refill_ind,
    o_seq_1 = build(temp_req->qual[d.seq]->refill_ind,temp_req->qual[d.seq]->encntr_id),
    d.seq
from
    (dummyt d with seq = value(temp_req->qual_knt))
plan d where
    d.seq > 0 and
    temp_req->qual[d.seq]->no_print = FALSE
order
;**    refill_ind,
;**    encntr_id,
    o_seq_1,
    order_dt,
    daw,
    csa_group,
    csa_schedule,
    print_loc,
    fax_seq,
    phys_seq,
    print_dea,
    d.seq
 
head report
 
    jknt = 0
    rknt = 0
    stat = alterlist(tprint_req->job,10)
 
 
    temp_o_seq_1        = fillstring(255," ")
    temp_order_dt       = fillstring(12," ")
    temp_print_loc      = fillstring(255," ")
    temp_output_dest_cd = 0.0
    temp_free_text_nbr  = fillstring(255," ")
    temp_phys_id        = 0.0
    temp_phys_addr_id   = 0.0
    temp_daw            = 0
    temp_csa_group      = ""
    temp_csa_schedule   = fillstring(1," ")
 
detail
 
 
        if (jknt > 0)
            tprint_req->job[jknt]->req_knt = rknt
            stat = alterlist(tprint_req->job[jknt]->req,rknt)
        endif
 
        jknt = jknt + 1
        if (mod(jknt,10) = 1 and jknt != 1)
            stat = alterlist(tprint_req->job,jknt + 9)
        endif
 
        tprint_req->job[jknt]->csa_group         = csa_group
        tprint_req->job[jknt]->refill_ind        = temp_req->qual[d.seq]->refill_ind
        tprint_req->job[jknt]->phys_name         = temp_req->qual[d.seq]->phys_name
        tprint_req->job[jknt]->phys_bname        = temp_req->qual[d.seq]->phys_bname
        tprint_req->job[jknt]->phys_fname        = temp_req->qual[d.seq]->phys_fname
        tprint_req->job[jknt]->phys_mname        = temp_req->qual[d.seq]->phys_mname
        tprint_req->job[jknt]->phys_lname        = temp_req->qual[d.seq]->phys_lname
        tprint_req->job[jknt]->eprsnl_ind        = temp_req->qual[d.seq]->eprsnl_ind
        tprint_req->job[jknt]->eprsnl_bname      = temp_req->qual[d.seq]->eprsnl_bname
        tprint_req->job[jknt]->eprsnl_id         = temp_req->qual[d.seq]->eprsnl_id             ;023
        tprint_req->job[jknt]->phys_addr1        = temp_req->qual[d.seq]->phys_addr1
        tprint_req->job[jknt]->phys_addr2        = temp_req->qual[d.seq]->phys_addr2
        tprint_req->job[jknt]->phys_addr3        = temp_req->qual[d.seq]->phys_addr3
        tprint_req->job[jknt]->phys_addr4        = temp_req->qual[d.seq]->phys_addr4
        tprint_req->job[jknt]->phys_city         = temp_req->qual[d.seq]->phys_city
        tprint_req->job[jknt]->phys_dea          = temp_req->qual[d.seq]->phys_dea
        tprint_req->job[jknt]->phys_npi          = temp_req->qual[d.seq]->phys_npi ;029
        tprint_req->job[jknt]->sup_phys_npi      = temp_req->qual[d.seq]->sup_phys_npi ;029
        tprint_req->job[jknt]->phys_lnbr         = temp_req->qual[d.seq]->phys_lnbr
        tprint_req->job[jknt]->phys_phone        = temp_req->qual[d.seq]->phys_phone
        tprint_req->job[jknt]->phys_fax          = temp_req->qual[d.seq]->phys_fax
        tprint_req->job[jknt]->phys_ord_dt       = order_dt
        tprint_req->job[jknt]->sup_phys_bname    = temp_req->qual[d.seq]->sup_phys_bname ;013
        tprint_req->job[jknt]->sup_phys_dea      = temp_req->qual[d.seq]->sup_phys_dea    ;013
        tprint_req->job[jknt]->pat_loc_add       = temp_req->qual[d.seq]->pat_loc_add
        tprint_req->job[jknt]->pat_loc_name      = temp_req->qual[d.seq]->pat_loc_name
        tprint_req->job[jknt]->pat_loc_bus_phone = temp_req->qual[d.seq]->pat_loc_bus_phone
        tprint_req->job[jknt]->pat_loc_fax_phone = temp_req->qual[d.seq]->pat_loc_fax_phone
        tprint_req->job[jknt]->encntr_type_cd    = temp_req->qual[d.seq]->encntr_type_cd
 
        if (tprint_req->job[jknt]->csa_group = "A")
            tprint_req->job[jknt]->output_dest_cd = -1
            tprint_req->job[jknt]->free_text_nbr = "1"
        else
            tprint_req->job[jknt]->output_dest_cd = temp_req->qual[d.seq]->output_dest_cd
            tprint_req->job[jknt]->free_text_nbr = trim(temp_req->qual[d.seq]->free_text_nbr)
        endif
 
        tprint_req->job[jknt]->print_loc     	= trim(temp_req->qual[d.seq]->print_loc)
        tprint_req->job[jknt]->daw           	= temp_req->qual[d.seq]->daw
        tprint_req->job[jknt]->mrn           	= temp_req->qual[d.seq]->mrn	;047
        tprint_req->job[jknt]->fin           	= temp_req->qual[d.seq]->fin	;047
        tprint_req->job[jknt]->height		 	= temp_req->qual[d.seq]->height	;047
        tprint_req->job[jknt]->height_w_units	= temp_req->qual[d.seq]->height_w_units	;047
        tprint_req->job[jknt]->weight		 	= temp_req->qual[d.seq]->weight	;047
        tprint_req->job[jknt]->weight_w_units	= temp_req->qual[d.seq]->weight_w_units	;047
call echo("***")
call echo(build("***   hp_pri_found :",temp_req->qual[d.seq]->hp_pri_found))
call echo(build("***   hp_sec_found :",temp_req->qual[d.seq]->hp_sec_found))
call echo("***")
        if (temp_req->qual[d.seq]->hp_pri_found = TRUE or temp_req->qual[d.seq]->hp_sec_found = TRUE)
            tprint_req->job[jknt]->hp_found = TRUE
        endif
        tprint_req->job[jknt]->hp_pri_name   = temp_req->qual[d.seq]->hp_pri_name
        tprint_req->job[jknt]->hp_pri_polgrp = temp_req->qual[d.seq]->hp_pri_polgrp
        tprint_req->job[jknt]->hp_sec_name   = temp_req->qual[d.seq]->hp_sec_name
        tprint_req->job[jknt]->hp_sec_polgrp = temp_req->qual[d.seq]->hp_sec_polgrp
 
;**     temp_refill_ind     = refill_ind
;**        temp_encntr_id      = encntr_id
        temp_o_seq_1        = o_seq_1
        temp_order_dt       = order_dt
        temp_print_loc      = print_loc
        temp_output_dest_cd = output_dest_cd
        temp_free_text_nbr  = free_text_nbr
        temp_phys_id        = phys_id
        temp_phys_addr_id   = phys_addr_id
        temp_daw            = daw
        temp_csa_group      = csa_group
        temp_csa_schedule   = csa_schedule
 
        rknt = 0
        stat = alterlist(tprint_req->job[jknt]->req,10)
;    endif
 
    if (jknt > 0)
        rknt = rknt + 1
        if (mod(rknt,10) = 1 and rknt != 1)
            stat = alterlist(tprint_req->job[jknt]->req,rknt + 9)
        endif
 
        tprint_req->job[jknt]->req[rknt]->order_id = temp_req->qual[d.seq]->order_id
        tprint_req->job[jknt]->req[rknt]->print_dea   = temp_req->qual[d.seq]->print_dea
        tprint_req->job[jknt]->req[rknt]->csa_sched = csa_schedule
        tprint_req->job[jknt]->req[rknt]->start_dt = trim(format(cnvtdatetime(temp_req->
            qual[d.seq]->start_date),'MM/DD/YYYY HH:MM;;Q'))
        tprint_req->job[jknt]->req[rknt]->action_dt = trim(format(cnvtdatetime(temp_req->
            qual[d.seq]->action_dt_tm),'MM/DD/YYYY HH:MM;;Q'))
        tprint_req->job[jknt]->req[rknt]->req_start_dt = trim(format(cnvtdatetime(temp_req->
            qual[d.seq]->req_start_date),'MM/DD/YYYY HH:MM;;Q'))
        tprint_req->job[jknt]->req[rknt]->orig_dt_tm = trim(format(cnvtdatetime(temp_req->
            qual[d.seq]->orig_order_dt_tm),'MM/DD/YYYY HH:MM;;Q'))
 
        tprint_req->job[jknt]->req[rknt]->med_disp = trim(temp_req->qual[d.seq]->med_name, 3)
        tprint_req->job[jknt]->req[rknt]->prim_dx_description = trim(temp_req->qual[d.seq].prim_dx_description, 3)
        tprint_req->job[jknt]->req[rknt]->prim_dx_icd_code = trim(temp_req->qual[d.seq].prim_dx_icd_code, 3)
 
 
		tprint_req->job[jknt]->req[rknt]->sec_att_disp = trim(temp_req->qual[d.seq]->second_attempt_note, 3)
 
        ; EPCS - copy the routing pharmacy name, this will be empty text unless routing had failed
        ; in which case the pharmacy where routing failed has to be printed as a label too
        tprint_req->job[jknt]->req[rknt]->erx_pharmacy_name = temp_req->qual[d.seq]->routing_pharmacy_name
        tprint_req->job[jknt]->req[rknt]->erx_routing_dt_tm =
        	concat(trim(format(cnvtdatetime(temp_req->qual[d.seq]->routing_dt_tm), "@SHORTDATE4YR")),
        	 " ", trim(format(cnvtdatetime(temp_req->qual[d.seq]->routing_dt_tm), "@TIMENOSECONDS")))
        tprint_req->job[jknt]->req[rknt]->sig_disp = trim(temp_req->qual[d.seq]->sig_line, 3)
 
 
	if (textlen(temp_req->qual[d.seq]->dispense_line) > 0)	;*** MOD 007
	    tprint_req->job[jknt]->req[rknt]->dispense_disp = trim(temp_req->qual[d.seq]->dispense_line, 3)
 
	;BEGIN MOD 007
	else
	    tprint_req->job[jknt]->req[rknt]->dispense_duration_disp = trim(temp_req->qual[d.seq]->dispense_duration, 3)
 
	endif
	;END MOD 007
 
        tprint_req->job[jknt]->req[rknt]->refill_disp = temp_req->qual[d.seq]->refill_line
        tprint_req->job[jknt]->req[rknt]->special_disp = trim(temp_req->qual[d.seq]->special_inst, 3)
        call echo(build("sr_print",tprint_req->job[jknt]->req[rknt]->special_disp))
 
        tprint_req->job[jknt]->req[rknt]->prn_disp = temp_req->qual[d.seq]->prn_inst
        tprint_req->job[jknt]->req[rknt]->indic_disp = temp_req->qual[d.seq]->indications
        tprint_req->job[jknt]->req[rknt]->comment_disp = temp_req->qual[d.seq]->comments
 
    endif
 
foot report
    tprint_req->job_knt = jknt
    stat = alterlist(tprint_req->job,jknt)
 
    tprint_req->job[jknt]->req_knt = rknt
    stat = alterlist(tprint_req->job[jknt]->req,rknt)
with nocounter
 
set iErrCode = error(sErrMsg,1)
if (iErrCode > 0)
    set failed = SELECT_ERROR
    set table_name = "BUILD_TPRINT"
    go to EXIT_SCRIPT
endif
 call echorecord(temp_req)
free record temp_req
 
 
if (tprint_req->job_knt = 0)			;020
	call echo("No print job found!",1)	;020
	go to EXIT_SCRIPT                       ;020
endif                                           ;020
 
 
/****************************************************************************
*       Print Requisition                                                   *
*****************************************************************************/
if (size(request->printer_name,1) > 0)     ;034     ;*** MOD 015
	execute anterxreq01_lyt:dba value(request->printer_name)
endif
 
/****************************************************************************
*       Fax Requisition                                                     *
*****************************************************************************/
;*** MOD 015 Keeping the the same grouping for fax jobs
for (i = 1 to tprint_req->job_knt)
   if (tprint_req->job[i]->output_dest_cd > 0)
 
   set toad = 1
   set file_name = concat("cer_print:",trim(cnvtlower(username)),"_",		;023
       trim(cnvtstring(tprint_req->job[i]->req[1]->order_id)),"_",          ;038
       trim(cnvtstring(curtime3,7,0,r)),"_",trim(cnvtstring(i)),".dat")
 
 
   set tprint_req->job[i]->print_loc = trim(file_name)
   execute chvarxreq03_lyt:dba value(tprint_req->job[i]->print_loc)
 
 
;***
;***  RxFax Macros
;***
;***  Special Notes: Based off of original print macros include file
;***                 written by Steven Farmer
;***
;***  000   02/14/03 JF8275   Initial Release
;***  001   12/03/03 BP9613   Adding dispense_duration for EasyScript Supply
;***							calculation.
;***  002   01/15/04 JF8275   Shortened line for DEA #
;***  003   07/09/04 IT010631 Refill and Mid-level Enhancement
;***  004   02/22/07 AC013605 Added a meaningful report title
 
      free record prequest
      record prequest
      (
        1 output_dest_cd   = f8
        1 file_name        = vc
        1 copies           = i4
        1 output_handle_id = f8  ; this field should never be passed in!
        1 number_of_pages  = i4
        1 transmit_dt_tm   = dq8
        1 priority_value   = i4
        1 report_title     = vc
        1 server           = vc
        1 country_code     = c3
        1 area_code        = c10
        1 exchange         = c10
        1 suffix           = c50
      )
 
      set prequest->output_dest_cd  = tprint_req->job[i]->output_dest_cd
      set prequest->file_name       = tprint_req->job[i]->print_loc
      set prequest->number_of_pages = 1
      set prequest->report_title = concat("RX","|",trim(cnvtstring(tprint_req->job[i]->req[1]->order_id)),"|",
      								trim(demo_info->pat_name),"|","0","|"," ","|"," ","|",trim(cnvtstring(demo_info->pat_id)),
      								"|",trim(cnvtstring(tprint_req->job[i]->eprsnl_id)),"|"," ","|","0")
 
      if (size(tprint_req->job[i]->free_text_nbr,1) > 0 and     ;034
          tprint_req->job[i]->free_text_nbr != "0")
          set prequest->suffix = tprint_req->job[i]->free_text_nbr
      endif
 
      free record preply
      record preply
      (
        1 sts = i4
        1 status_data
          2 status = c1
          2 subeventstatus[1]
            3 OperationName = c15
            3 OperationStatus = c1
            3 TargetOjbectName = c15
            3 TargetObjectValue = c100
      )
 
      call echo ("***")
      call echo ("***   Executing SYS_OUTPUTDEST_PRINT")
      call echo ("***")
      execute sys_outputdest_print with replace("REQUEST",prequest),replace("REPLY",preply)
      call echo ("***")
      call echo ("***   Finished executing SYS_OUTPUTDEST_PRINT")
      call echo ("***")
      call echorecord(preply)
  endif
endfor
 
 
 
 ;MOD 042 Begin - Subroutine which is used to spell out numbers
/****************************************************************************
*       SUBROUTINES                                                         *
*****************************************************************************/
DECLARE get_number_spellout(x=vc(REF)) = vc
SUBROUTINE get_number_spellout(x)
 
	declare language_log = vc with private, noconstant("")
	set language_log = trim(cnvtupper(logical("CCL_LANG")),3)
 
	call echo("Lang *************************************")
	call echo(build("Lang:",language_log))
    call echo("******************************************")
 
    if (size(language_log) >= 2)
		if (substring(1,2,language_log) != "EN")
			return ("")
		endif
    endif
 
	declare index = i2 with private, noconstant(1)
 
	declare new_num = vc with private, noconstant("")
	set new_num = replace(x,",","")
 
	call echo("Comma Removal ****************************")
	call echo(build("new_num:",new_num))
    call echo("******************************************")
 
	declare int_x = i4 with private, constant(cnvtint(new_num))
    declare real_x = f8 with private, constant(cnvtreal(new_num))
	declare whole = vc with protect, noconstant("")
	declare below = vc with protect, noconstant("")
    declare over  = vc with protect, noconstant("")
    declare decimal_x = f8 with private, constant(round(real_x - cnvtreal(int_x),3))
 
    call echo("******************************************")
    call echo(build("decimal_x:",decimal_x))
	call echo(build("int_x:",int_x))
	call echo(build("real_x:",real_x))
    call echo("******************************************")
    if (decimal_x = 0)
    	call echo("in if")
		if (int_x < 0)
	    	return ("")
		endif
		if (int_x < 10)
			set index = (int_x + 1)
			return (trim(numbers->ones[index].value))
    	endif
    	if (int_x < 20)
        	set index = (int_x - 9)
        	return (trim(numbers->teens[index].value))
    	endif
    	if (int_x < 100)
 
        	set index = cnvtint(int_x / 10)
        	if (mod(int_x,10) = 0)
        	    return (trim(numbers->tens[index].value))
        	else
            	return (trim(concat(numbers->tens[index].value,"-", numbers->ones[mod(int_x,10)+1].value)))
        	endif
    	endif
    	if (int_x < 1000)
     	   	set index = cnvtint(int_x / 100 + 1)
        	if (mod(int_x,100) = 0)
            	return (trim(concat(numbers->ones[index].value," ",numbers->hundred)))
         	else
            	set below = get_number_spellout(cnvtstring(mod(int_x,100)))
              	return (trim(concat(numbers->ones[index].value," ",numbers->hundred," ",below)))
         	endif
    	endif
    	if (int_x < 1000000)
        	if (mod(int_x,1000) = 0)
            	set over = get_number_spellout(cnvtstring(int_x / 1000))
            	return (trim(concat(over," ",numbers->thousand)))
         	else
              	set over = get_number_spellout(cnvtstring(int_x / 1000))
              	set below = get_number_spellout(cnvtstring(mod(int_x,1000)))
              	return (trim(concat(over," ",numbers->thousand," ",below)))
 
	     	endif
		else
			return ("")
		endif
	else
		call echo("in else")
		set whole = get_number_spellout(cnvtstring(int_x))
		if (decimal_x = 0.25)
		    return (trim(concat(whole," and one quarter")))
		elseif (decimal_x = 0.5)
		    return (trim(concat(whole," and one half")))
		elseif (decimal_x = 0.75)
		    return (trim(concat(whole," and three quarters")))
		elseif (decimal_x = 0.1)
		    return (trim(concat(whole," and one tenth")))
		elseif (decimal_x = 0.2)
		    return (trim(concat(whole," and one fifth")))
		elseif (decimal_x = 0.3)
		    return (trim(concat(whole," and three tenths")))
		elseif (decimal_x = 0.4)
		    return (trim(concat(whole," and two fifths")))
		elseif (decimal_x = 0.6)
		    return (trim(concat(whole," and three fifths")))
		elseif (decimal_x = 0.7)
		    return (trim(concat(whole," and seven tenths")))
		elseif (decimal_x = 0.8)
		    return (trim(concat(whole," and four fifths")))
		elseif (decimal_x = 0.9)
		    return (trim(concat(whole," and nine tenths")))
		else
			return (trim(concat(whole," and ",build(decimal_x))))
		endif
	endif
END
;MOD 42 END
 
 
/****************************************************************************
*       EXIT_SCRIPT                                                         *
*****************************************************************************/
#EXIT_SCRIPT
 
if (failed != FALSE)
    set reply->status_data->status = "F"
    set reply->status_data->subeventstatus[1]->OperationStatus = "F"
    set reply->status_data->subeventstatus[1]->TargetObjectValue = sErrMsg
 
    if (failed = SELECT_ERROR)
        set reply->status_data->subeventstatus[1]->OperationName = "SELECT"
        set reply->status_data->subeventstatus[1]->TargetObjectName = table_name
    elseif (failed = INSERT_ERROR)
        set reply->status_data->subeventstatus[1]->OperationName = "INSERT"
        set reply->status_data->subeventstatus[1]->TargetObjectName = table_name
    elseif (failed = INPUT_ERROR)
        set reply->status_data->subeventstatus[1]->OperationName = "VALIDATION"
        set reply->status_data->subeventstatus[1]->TargetObjectName = table_name
    else
        set reply->status_data->subeventstatus[1]->OperationName = "UNKNOWN"
        set reply->status_data->subeventstatus[1]->TargetObjectName = table_name
    endif
else
    set reply->status_data->status = "S"
endif
 
call echorecord(reply)
 
 
set script_version = "047 08/08/18 SR051119 Changed mod"
set rx_version = "04"
end go
