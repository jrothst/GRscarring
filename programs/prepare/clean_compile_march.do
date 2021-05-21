********************************************************************************

* clean_compile_march.do
* Cleans and compiles 1979-2015 march cps data 
* (For the most part) keeping person level records here

*modified: RY, 4/2/2018, edited to extend back to 1981. 
*	Note: there are significant differences between the 1980 and 1981 march supplements. 
*		prior to 1981 the march supplement is missing several variables, including
*		everything after column 338 (the earnings variables, 
*		parent present, spouse present.). Therefore we are only extending the 
*		March CPS back to 1979.
* 5/21/18, JR: Add topcoded total annual earnings, at 98th percentile.
* 9/20/18, NR: edited to extend back to 1979 
*	 
********************************************************************************

cap project, doinfo
if _rc==0 {
	 local pdir "`r(pdir)'"						  	    // the project's main dir.
	 local dofile "`r(dofile)'"						    // do-file's stub name
   local sig {bind:{hi:[`dofile'.dta. RP : `dofile'.do, `c(current_date)']}}	// a signature in notes
      local doasproject=1

}
else {
	local pdir "~/GRscarring"
	local dofile "clean_compile_march"
   local doasproject=0
}

set more off
local rootdir "`pdir'"
local thisdir "`pdir'"
set varabbrev off	// for long projects, it's best not to abbreviate

global nberdata "`pdir'/rawdata/rawfromNBER"
global nbercode "`pdir'/programs/fromNBER"

local prepdata "`pdir'/scratch"
local ipumsdata "`pdir'/rawdata/IPUMS"
local data "`pdir'/rawdata"

if `doasproject'==1 {
	project, original("`ipumsdata'/cps_ind_xwalk.dta")
	project, original("`ipumsdata'/cps_occ_xwalk.dta")
	project, uses("`prepdata'/cpi.dta")
}

***************************************************************************************************************
* Create some local varlists:

local ernvarsA "ern_yn ern_srce ern_otr ern_val wageotr wsal_yn wsal_val ws_val seotr semp_yn semp_val se_val frmotr frse_yn frse_val frm_val"
local increcodes "pearnval ptotval pothval ptot_r"
local incvarsA "uc_yn subuc strkuc uc_val"
local incvarsB "wc_yn wc_type wc_val"
local incvarsC "ss_yn ss_val "    
local incvarsD "ssi_yn ssi_val"
local incvarsE "paw_yn paw_typ paw_mon paw_val"
local incvarsF "vet_yn vet_typ? vet_qva vet_val"
local incvarsG "sur_yn sur_sc? sur_val? srvs_val"
local incvarsH "dis_hp dis_cs dis_yn dis_sc? dis_val? dsab_val"
local incvarsI "ret_yn ret_sc? ret_val? rtm_val"
local incvarsJ 		 "int_yn int_val div_yn div_non div_val rnt_yn rnt_val"
local incvarsJ2015 "int_yn int_val div_yn div_val rnt_yn rnt_val"
local incvarsK "ed_yn oed_typ? ed_val"
local incvarsL 		 "csp_yn csp_val alm_yn alm_val fin_yn fin_val oi_off oi_yn oi_val"
local incvarsL2015 "csp_yn csp_val fin_yn fin_val oi_off oi_yn oi_val"
local hivarsA "mcare mcaid champ hi_yn hiown"
local hivarsB "hiemp hipaid emcontrb hi dephi"
local hivarsC "paid hiout priv prityp depriv pout out oth otyp_? othstper"
local hivarsD "othstyp? hea ihsflg ahiper ahityp? pchip cov_gh cov_hi ch_mc ch_hi"

local occ_ind_vars a_ind industry a_occ a_mjocc a_dtocc a_mjind a_dtind poccu2 occup weind wemind wemocg
local occ_ind_vars_late industry peioind peioocc mjocc a_dtocc a_mjind a_dtind poccu2 occup weind wemind wemocg
local occ_ind_vars_later industry peioind peioocc a_mjocc a_dtocc a_mjind a_dtind poccu2 occup weind wemind wemocg


* Variables not in early (1989-?) March CPS files
local laterlist resnss1 resnss2 resnssi1 resnssi2 ssikidyn p_mvcare p_mvcaid hityp hilin? pilin? care caid mon


***************************************************************************************************************

* Loop over years and keep relevant variables *
forvalues yr=79/80 {
	if `doasproject'==1 project, uses(`prepdata'/cpsmar`yr'.dta.gz)
	! zcat `prepdata'/cpsmar`yr'.dta.gz > `prepdata'/cpsmar`yr'.dta
	use `prepdata'/cpsmar`yr'.dta
	! rm `prepdata'/cpsmar`yr'.dta
	gen year=19`yr'
	
	*cleaning up the race variables
	label values race race
	label define race ///
			1	"White" ///
			2	"Black" ///
			3	"Other"
	rename race a_race
	gen prdtrace=.
	label values ethnicit ethnicit 
	label define ethnicit ///
			10	"Mexican American" ///
			11	"Chicano" ///
			12	"Mexican" ///
			13	"Mexicano" ///
			14	"Puerto Rican" ///
			15	"Cuban" ///
			16	"Central or South American" ///
			17	"Other Spanish" ///
			30	"Another Group Not Listed" ///
			39	"Don't Know" ///
			40	"Not Available"
	gen pehspnon=.
	replace pehspnon=ethnicit
	
	label values highgrad highgrad
	label define highgrad ///
		0	"Children under 15" ///
		1	"None" ///
		2	"Elementary one" ///
		3	"Elementary two" ///
		4	"Elementary three" ///
		5	"Elementary four" ///
		6	"Elementary five" ///
		7	"Elementary six" ///
		8	"Elementary seven" ///
		9	"Elementary eight" ///
		10	"High School one" ///
		11	"High School two" ///
		12	"High School three" ///
		13	"High School four" ///
		14	"College one" ///
		15	"College two" ///
		16	"College three" ///
		17	"College four" ///
		18	"College five" ///
		19	"College six or more" 
	
	label values empst empst
	label define empst  ///
		0	"NIU" ///
		1	"Full time" ///
		2	"Part time" ///
		3	"Unemployed experienced" ///
		4	"Unemployed not experienced" ///
		5 	"Armed forces" ///
		6	"Not in labor force" 
	
	label values bfullpar bfullpar
	label define bfullpar  ///
		0	"NIU" ///
		1	"Employed full time" ///
		2	"Part time for economic reasons" ///
		3	"unemployed full time" ///
		4	"employed part time" ///
		5	"unemployed part time"
		
	*renaming the education variable
	rename highgrad a_hga
	*renaming the state variable
	gen state=mststate
	gen state_fips=.
	
	*renaming variables that are the same
	ren marstat a_maritl
	ren sex a_sex
	ren a_hrs1 a_uslhrs
	ren weind a_dtind
	ren poccu2 a_dtocc
	ren famrel a_famrel
	ren Tenure h_tenure
	ren marsuppw marsupwt
	ren inern tcernval
	ren intot tcwsval

	*generating variables that are not quite the same across years but we are equating here
	gen pearnval = incearn
	gen ptotval  = pinctot
	gen ljcw     = a_clswkr
	gen lkweeks  = I43WK	
	gen nwlkwk   = I43WK
	
	*generating variablest that are missing from this earlier period
	gen a_occ    = .
	gen a_mjocc  = .	
	gen a_ind    = .
	gen a_mjind  = . 
	gen a_werntf = .
	
	tempfile mar19`yr'
 	save `mar19`yr''
}

forvalues yr=81/87 {
	if `doasproject'==1 project, uses(`prepdata'/cpsmar`yr'.dta.gz)
	! zcat `prepdata'/cpsmar`yr'.dta.gz > `prepdata'/cpsmar`yr'.dta
	use `prepdata'/cpsmar`yr'.dta
	! rm `prepdata'/cpsmar`yr'.dta
	gen year=19`yr'
	
	*cleaning up the race variables
	label values race race
	label define race ///
			1	"White" ///
			2	"Black" ///
			3	"Other"
	rename race a_race
	gen prdtrace=.
	label values ethnicit ethnicit 
	label define ethnicit ///
			10	"Mexican American" ///
			11	"Chicano" ///
			12	"Mexican" ///
			13	"Mexicano" ///
			14	"Puerto Rican" ///
			15	"Cuban" ///
			16	"Central or South American" ///
			17	"Other Spanish" ///
			30	"Another Group Not Listed" ///
			39	"Don't Know" ///
			40	"Not Available"
	gen pehspnon=.
	replace pehspnon=ethnicit
	
	label values highgrad highgrad
	label define highgrad ///
		0	"Children under 15" ///
		1	"None" ///
		2	"Elementary one" ///
		3	"Elementary two" ///
		4	"Elementary three" ///
		5	"Elementary four" ///
		6	"Elementary five" ///
		7	"Elementary six" ///
		8	"Elementary seven" ///
		9	"Elementary eight" ///
		10	"High School one" ///
		11	"High School two" ///
		12	"High School three" ///
		13	"High School four" ///
		14	"College one" ///
		15	"College two" ///
		16	"College three" ///
		17	"College four" ///
		18	"College five" ///
		19	"College six or more" 
	
	label values empst empst
	label define empst  ///
		0	"NIU" ///
		1	"Full time" ///
		2	"Part time" ///
		3	"Unemployed experienced" ///
		4	"Unemployed not experienced" ///
		5 	"Armed forces" ///
		6	"Not in labor force" 
	
	label values bfullpar bfullpar
	label define bfullpar  ///
		0	"NIU" ///
		1	"Employed full time" ///
		2	"Part time for economic reasons" ///
		3	"unemployed full time" ///
		4	"employed part time" ///
		5	"unemployed part time"
		
	*renaming the education variable
	rename highgrad a_hga
	*renaming the state variable
	gen state=mststate
	gen state_fips=.
	
	*renaming variables that are the same
	ren marstat a_maritl
	ren sex a_sex
	ren spouse a_spouse
	ren earnhrtc a_herntf
	ren earnhour a_hrspay
	ren a_hrs1 a_uslhrs
	ren weind a_dtind
	ren poccu2 a_dtocc
	ren famrel a_famrel
	ren shlftpt a_ftpt
	ren Tenure h_tenure
	ren marsuppw marsupwt
	ren flpinern tcernval
	ren flpintot tcwsval
	
	*generating variables that are not quite the same across years but we are equating here
	gen wkswork=I34WK
	gen hrswk=I38 //we are equating number of hours worked to hours usually worked 
	gen pearnval=incearn
	gen ptotval=pinctot
	gen ljcw=a_clswkr
	gen nwlook=I43N
	gen lkweeks=I43WK	
	gen nwlkwk=I43WK
	
	*generating variablest that are missing from this earlier period
	gen weclw=.
	gen a_occ=.
	gen a_mjocc=.	
	gen a_ind=.
	gen a_mjind=. 
	gen a_werntf=.
	
	tempfile mar19`yr'
 	save `mar19`yr''
}

forvalues yr=88/99 {
	if `doasproject'==1 project, uses(`prepdata'/cpsmar`yr'.dta.gz)
	! zcat `prepdata'/cpsmar`yr'.dta.gz > `prepdata'/cpsmar`yr'.dta
	use `prepdata'/cpsmar`yr'.dta
	! rm `prepdata'/cpsmar`yr'.dta
	gen year=19`yr'
	** PROBLEMATIC VARS **	
	foreach stvar in hg_st60 gestcen {
		cap confirm var `stvar'
		if !_rc ren `stvar' state
	}
	local addlist ""
	foreach var of local laterlist {
		cap confirm var `var'
		if !_rc local addlist "`addlist' `var'"  
	}
	cap confirm var a_lineno
	if !_rc ren a_lineno pulineno
	cap confirm var h_idnum1
	if !_rc egen hhid=concat(h_idnum1 h_idnum2)
	else gen hhid=h_idnum
	
	* 1995 variable conventions change: 
	if `yr'==95 {
		ren prmarsta a_maritl
		ren perace a_race
		ren peage a_age
		ren pespouse a_spouse
		ren peeduca a_hga
		ren pesex a_sex
		ren pthr a_herntf
		ren ptwk a_werntf
		ren prernhly a_hrspay
		ren prunedur a_wkslk
		ren pehrusl1 a_uslhrs
		ren pei01icd a_ind
		ren prmjind1 a_mjind 
		ren prdtind1 a_dtind
		ren pei01ocd a_occ
		ren prmjocc1 a_mjocc 
		ren prdtocc1 a_dtocc
		ren prfamrel a_famrel
		ren peschft a_ftpt
	} 
	local addlist2 ""
	foreach var in a_race prdtrace pehspnon eit_cred pruntype fl_665 prwkstat agi a_whenlj pelklwo a_wantjb prwntjob  ///
								 a_mjind prmjind1 a_nlflj penlfjh a_wkstat prwkstat h_hhtype hrintsta prerelg {
		cap confirm var `var'
		if !_rc local addlist2 "`addlist2' `var'"  
	}

	* Keep relevant vars:
	keep state hhid pulineno a_spouse a_age age1 a_hga a_maritl a_sex p_stat a_famrel famrel hhdrel h_seq ///
			 paw_typ a_herntf a_werntf pearnval a_hrspay mcaid mcare  a_wkslk workyn a_ftpt ///
			 a_uslhrs hrswk a_lfsr a_rcow a_untype h_tenure ///
			 subuc a_clswkr clwk weclw ljcw ///
			 lknone nwlook nwlkwk lkweeks wtemp ///
			 strkuc a_fnlwgt marsupwt wkswork wewkrs year `occ_ind_vars' ///
 			 `ernvarsA' `increcodes' `incvarsA' `incvarsB' `incvarsC' `incvarsD' `incvarsE' `incvarsF' ///
 			 `incvarsG' `incvarsH' `incvarsI' `incvarsJ' `incvarsK' `incvarsL' `hivarsA' `addlist' `addlist2'
 			 
 	tempfile mar19`yr'
 	save `mar19`yr''
}


forvalues yr=0/12 {
	if `yr'<10 local yr "0`yr'"
	if `doasproject'==1 project, uses(`prepdata'/cpsmar`yr'.dta.gz)
	! zcat `prepdata'/cpsmar`yr'.dta.gz > `prepdata'/cpsmar`yr'.dta
	use `prepdata'/cpsmar`yr'.dta
	! rm `prepdata'/cpsmar`yr'.dta
	gen year=20`yr'
	** PROBLEMATIC VARS **	
	foreach stvar in hg_st60 gestcen {
		cap confirm var `stvar'
		if !_rc ren `stvar' state
	}
	local addlist ""
	foreach var of local laterlist {
		cap confirm var `var'
		if !_rc local addlist "`addlist' `var'"  
	}
	
	cap confirm var a_lineno
	if !_rc ren a_lineno pulineno
	cap confirm var h_idnum1
	if !_rc egen hhid=concat(h_idnum1 h_idnum2)
	else gen hhid=h_idnum
	local addlist2 ""
	foreach var in a_race prdtrace pehspnon eit_cred pruntype fl_665 a_wkstat prwkstat agi prerelg {
		cap confirm var `var'
		if !_rc local addlist2 "`addlist2' `var'"  
	}

	* Keep relevant vars:
	if `yr'<03 {
		keep state hhid pulineno a_spouse a_age age1 a_hga a_maritl a_sex p_stat a_famrel famrel hhdrel h_seq ///
				 paw_typ a_herntf a_werntf pearnval a_hrspay mcaid mcare  a_wkslk workyn a_ftpt ///
				 a_uslhrs hrswk a_lfsr a_untype h_tenure ///
				 subuc a_clswkr clwk weclw ljcw ///
				 lknone nwlook nwlkwk lkweeks wtemp ///
				 strkuc a_fnlwgt marsupwt wkswork wewkrs year `occ_ind_vars' ///
 				 `ernvarsA' `increcodes' `incvarsA' `incvarsB' `incvarsC' `incvarsD' `incvarsE' `incvarsF' ///
 				 `incvarsG' `incvarsH' `incvarsI' `incvarsJ' `incvarsK' `incvarsL' `hivarsA' `addlist' `addlist2'
 	 }
 	 else if `yr'>=03 & `yr'<11 {
		keep state hhid pulineno a_spouse a_age age1 a_hga a_maritl a_sex p_stat a_famrel famrel hhdrel h_seq ///
				 paw_typ a_herntf a_werntf pearnval a_hrspay mcaid mcare  a_wkslk workyn a_ftpt ///
				 a_uslhrs hrswk a_lfsr a_untype h_tenure ///
				 subuc a_clswkr clwk weclw ljcw ///
				 lknone nwlook nwlkwk lkweeks wtemp ///
				 strkuc a_fnlwgt marsupwt wkswork wewkrs year `occ_ind_vars_late' a_famrel famrel hhdrel ///
 				 `ernvarsA' `increcodes' `incvarsA' `incvarsB' `incvarsC' `incvarsD' `incvarsE' `incvarsF' ///
 				 `incvarsG' `incvarsH' `incvarsI' `incvarsJ' `incvarsK' `incvarsL' `hivarsA' `addlist' `addlist2'
 	 }
 	 else {
 	 		keep state hhid pulineno a_spouse a_age age1 a_hga a_maritl a_sex p_stat a_famrel famrel hhdrel h_seq ///
			 paw_typ a_herntf a_werntf pearnval a_hrspay mcaid mcare  a_wkslk workyn a_ftpt ///
			 a_uslhrs hrswk a_lfsr a_untype h_tenure ///
			 subuc a_clswkr clwk weclw ljcw ///
			 lknone nwlook nwlkwk lkweeks wtemp ///
			 strkuc a_fnlwgt marsupwt wkswork wewkrs year `occ_ind_vars_later' ///
 			 `ernvarsA' `increcodes' `incvarsA' `incvarsB' `incvarsC' `incvarsD' `incvarsE' `incvarsF' ///
 			 `incvarsG' `incvarsH' `incvarsI' `incvarsJ' `incvarsK' `incvarsL' `hivarsA' `addlist' `addlist2'
 	 }

 	tempfile mar20`yr'
 	save `mar20`yr''
}		

forvalues yr=2013/2018 {
	if `yr'==2014 {
		if `doasproject'==1 project, uses(`prepdata'/cpsmar`yr't.dta.gz)
		! zcat `prepdata'/cpsmar`yr't.dta.gz > `prepdata'/cpsmar`yr'.dta
	}
	else {
		if `doasproject'==1 project, uses(`prepdata'/cpsmar`yr'.dta.gz)
		! zcat `prepdata'/cpsmar`yr'.dta.gz > `prepdata'/cpsmar`yr'.dta
	}
	use `prepdata'/cpsmar`yr'.dta
	! rm `prepdata'/cpsmar`yr'.dta
	gen year=`yr'
	** PROBLEMATIC VARS **	
	/*
	foreach stvar in hg_st60 gestcen {
		cap confirm var `stvar'
		if !_rc ren `stvar' state
	}
	*/
	ren gestfips state_fips
	
	local addlist ""
	foreach var of local laterlist {
		cap confirm var `var'
		if !_rc local addlist "`addlist' `var'"  
	}
	
	cap confirm var a_lineno
	if !_rc ren a_lineno pulineno
	cap confirm var h_idnum1
	if !_rc egen hhid=concat(h_idnum1 h_idnum2)
	else gen hhid=h_idnum
	
	local addlist2 ""
	foreach var in a_race prdtrace pehspnon eit_cred pruntype fl_665 a_wkstat prwkstat agi prerelg {
		cap confirm var `var'
		if !_rc local addlist2 "`addlist2' `var'"  
	}
	
	* Keep relevant vars:
	if `yr'<2015 {
		keep state_fips hhid pulineno a_spouse a_age age1 a_hga a_maritl a_sex p_stat a_famrel famrel hhdrel h_seq ///
			 paw_typ a_herntf a_werntf pearnval a_hrspay mcaid mcare a_wkslk workyn a_ftpt ///
			 a_uslhrs hrswk a_lfsr a_untype h_tenure ///
			 subuc a_clswkr clwk weclw ljcw ///
			 lknone nwlook nwlkwk lkweeks wtemp ///
			 strkuc a_fnlwgt marsupwt wkswork wewkrs year `occ_ind_vars_later' ///
 			 `ernvarsA' `increcodes' `incvarsA' `incvarsB' `incvarsC' `incvarsD' `incvarsE' `incvarsF' ///
 			 `incvarsG' `incvarsH' `incvarsI' `incvarsJ' `incvarsK' `incvarsL' `hivarsA' `addlist' `addlist2'
 	
 	}
 	else if inlist(`yr',2015,2016,2017,2018) {
		keep state_fips hhid pulineno a_spouse a_age age1 a_hga a_maritl a_sex pehspnon p_stat a_famrel famrel hhdrel h_seq ///
			 paw_typ a_herntf a_werntf pearnval a_hrspay mcaid mcare a_wkslk workyn a_ftpt ///
			 a_uslhrs hrswk a_lfsr a_untype h_tenure ///
			 subuc a_clswkr clwk weclw ljcw ///
			 lknone nwlook nwlkwk lkweeks wtemp ///
			 strkuc a_fnlwgt marsupwt wkswork wewkrs year `occ_ind_vars_later' ///
 			 `ernvarsA' `increcodes' `incvarsA' `incvarsB' `incvarsC' `incvarsD' `incvarsE' `incvarsF' ///
 			 `incvarsG' `incvarsH' `incvarsI' `incvarsJ2015' `incvarsK' `incvarsL2015' `hivarsA' `addlist'  `addlist2'		
 	}
 			 
 	tempfile mar`yr'
 	save `mar`yr''		 
}	

***************************************************************************************************************

** APPEND FILES TOGETHER **

use `mar1979'
forvalues y=1979/2018 {
	qui append using `mar`y''
}


***************************************************************************************************************

**********************
** DO SOME CLEANING **
**********************

*** Consistent coding of variables that change over time (most problems in 1995): *** 

** Race variables - coding changes 2002-2003      

gen byte r_white=(a_race==1) if year<2003
gen byte r_black=(a_race==2) if year<2003
gen byte r_asian=(a_race==3) if year<2003
gen byte r_amind=(a_race==4) if year<2003
gen byte r_other=(a_race==5) if year<2003

replace r_black=(inlist(prdtrace, 2, 6, 10, 11, 12, 15, 16, 19)) if year>=2003
replace r_asian=(inlist(prdtrace, 4, 5, 8, 11, 13, 14, 16, 17, 18, 19)) if year>=2003
replace r_amind=(inlist(prdtrace, 3, 7, 10, 13, 15, 17, 19)) if year>=2003
replace r_white=(inlist(prdtrace, 1, 6, 7, 8, 9, 15, 16, 17, 18, 19)) if year>=2003  
replace r_other=(inlist(prdtrace, 20, 21, 22, 23, 24, 25, 26)) if year>=2003

gen byte r_hispan=(pehspnon==1) if year>=2003
replace r_hispan=1 if pehspnon>=10 | pehspnon<=17 
gen byte r_hispan_miss=(r_hispan==.)
replace r_hispan=0 if r_hispan==.

drop prdtrace a_race pehspnon ethnicit

** Education vars - coding changes from 1991-1992

gen byte ed_lths=(a_hga>0 & a_hga<12) if a_hga<. & year<=1991
gen byte ed_hs=(a_hga==12) if a_hga<. & year<=1991
gen byte ed_scol=inlist(a_hga, 13,14,15) if a_hga<. & year<=1991
gen byte ed_ba=(a_hga==16) if a_hga<. & year<=1991
gen byte ed_grad=(a_hga>16) if a_hga<. & year<=1991 

replace ed_lths=inlist(a_hga, 31, 32, 33, 34, 35, 36, 37, 38) if a_hga<. & year>1991
replace ed_hs=inlist(a_hga, 39) if a_hga<. & year>1991
replace ed_scol=inlist(a_hga, 40, 41, 42) if a_hga<. & year>1991
replace ed_ba=inlist(a_hga, 43) if a_hga<. & year>1991
replace ed_grad=inlist(a_hga, 44, 45, 46) if a_hga<. & year>1991
*drop a_hga

** Self employment and SE income 
* SEMP-YN - any own business (all yrs) - recode (not sure if that's what we want...)
* SEMP-VAL - total earnings, own business SE (all yrs)


** Not that important for now, but here are some vars w/ coding changes: 
* prwkstat a_wkstat 
* a_whenlj pelklwo 
* a_wantjb prwntjob 
* a_nlflj penlfjh 
* a_mjind prmjind1 
* h_hhtype hrintsta

* RACE: (a_race until 2002, prdtrace afterwards)

* a_race prdtrace pehspnon

* Fix 2013-2015 state codes (using FIPS - convert to 1960 census codes since all other data in that format)

replace state=11 if state_fips==23 & inlist(year, 2013, 2014, 2015, 2016, 2017, 2018)
replace state=12 if state_fips==33 & inlist(year, 2013, 2014, 2015, 2016, 2017, 2018)
replace state=13 if state_fips==50 & inlist(year, 2013, 2014, 2015, 2016, 2017, 2018)
replace state=14 if state_fips==25 & inlist(year, 2013, 2014, 2015, 2016, 2017, 2018)
replace state=15 if state_fips==44 & inlist(year, 2013, 2014, 2015, 2016, 2017, 2018)
replace state=16 if state_fips==9  & inlist(year, 2013, 2014, 2015, 2016, 2017, 2018)
replace state=21 if state_fips==36 & inlist(year, 2013, 2014, 2015, 2016, 2017, 2018)
replace state=22 if state_fips==34 & inlist(year, 2013, 2014, 2015, 2016, 2017, 2018)
replace state=23 if state_fips==42 & inlist(year, 2013, 2014, 2015, 2016, 2017, 2018)
replace state=31 if state_fips==39 & inlist(year, 2013, 2014, 2015, 2016, 2017, 2018)
replace state=32 if state_fips==18 & inlist(year, 2013, 2014, 2015, 2016, 2017, 2018)
replace state=33 if state_fips==17 & inlist(year, 2013, 2014, 2015, 2016, 2017, 2018)
replace state=34 if state_fips==26 & inlist(year, 2013, 2014, 2015, 2016, 2017, 2018)
replace state=35 if state_fips==55 & inlist(year, 2013, 2014, 2015, 2016, 2017, 2018)
replace state=41 if state_fips==27 & inlist(year, 2013, 2014, 2015, 2016, 2017, 2018)
replace state=42 if state_fips==19 & inlist(year, 2013, 2014, 2015, 2016, 2017, 2018)
replace state=43 if state_fips==29 & inlist(year, 2013, 2014, 2015, 2016, 2017, 2018)
replace state=44 if state_fips==38 & inlist(year, 2013, 2014, 2015, 2016, 2017, 2018)
replace state=45 if state_fips==46 & inlist(year, 2013, 2014, 2015, 2016, 2017, 2018)
replace state=46 if state_fips==31 & inlist(year, 2013, 2014, 2015, 2016, 2017, 2018)
replace state=47 if state_fips==20 & inlist(year, 2013, 2014, 2015, 2016, 2017, 2018)
replace state=51 if state_fips==10 & inlist(year, 2013, 2014, 2015, 2016, 2017, 2018)
replace state=52 if state_fips==24 & inlist(year, 2013, 2014, 2015, 2016, 2017, 2018)
replace state=53 if state_fips==11 & inlist(year, 2013, 2014, 2015, 2016, 2017, 2018)
replace state=54 if state_fips==51 & inlist(year, 2013, 2014, 2015, 2016, 2017, 2018)
replace state=55 if state_fips==54 & inlist(year, 2013, 2014, 2015, 2016, 2017, 2018)
replace state=56 if state_fips==37 & inlist(year, 2013, 2014, 2015, 2016, 2017, 2018)
replace state=57 if state_fips==45 & inlist(year, 2013, 2014, 2015, 2016, 2017, 2018)
replace state=58 if state_fips==13 & inlist(year, 2013, 2014, 2015, 2016, 2017, 2018)
replace state=59 if state_fips==12 & inlist(year, 2013, 2014, 2015, 2016, 2017, 2018)
replace state=61 if state_fips==21 & inlist(year, 2013, 2014, 2015, 2016, 2017, 2018)
replace state=62 if state_fips==47 & inlist(year, 2013, 2014, 2015, 2016, 2017, 2018)
replace state=63 if state_fips==1  & inlist(year, 2013, 2014, 2015, 2016, 2017, 2018)
replace state=64 if state_fips==28 & inlist(year, 2013, 2014, 2015, 2016, 2017, 2018)
replace state=71 if state_fips==5  & inlist(year, 2013, 2014, 2015, 2016, 2017, 2018)
replace state=72 if state_fips==22 & inlist(year, 2013, 2014, 2015, 2016, 2017, 2018)
replace state=73 if state_fips==40 & inlist(year, 2013, 2014, 2015, 2016, 2017, 2018)
replace state=74 if state_fips==48 & inlist(year, 2013, 2014, 2015, 2016, 2017, 2018)
replace state=81 if state_fips==30 & inlist(year, 2013, 2014, 2015, 2016, 2017, 2018)
replace state=82 if state_fips==16 & inlist(year, 2013, 2014, 2015, 2016, 2017, 2018)
replace state=83 if state_fips==56 & inlist(year, 2013, 2014, 2015, 2016, 2017, 2018)
replace state=84 if state_fips==8  & inlist(year, 2013, 2014, 2015, 2016, 2017, 2018)
replace state=85 if state_fips==35 & inlist(year, 2013, 2014, 2015, 2016, 2017, 2018)
replace state=86 if state_fips==4  & inlist(year, 2013, 2014, 2015, 2016, 2017, 2018)
replace state=87 if state_fips==49 & inlist(year, 2013, 2014, 2015, 2016, 2017, 2018)
replace state=88 if state_fips==32 & inlist(year, 2013, 2014, 2015, 2016, 2017, 2018)
replace state=91 if state_fips==53 & inlist(year, 2013, 2014, 2015, 2016, 2017, 2018)
replace state=92 if state_fips==41 & inlist(year, 2013, 2014, 2015, 2016, 2017, 2018)
replace state=93 if state_fips==6  & inlist(year, 2013, 2014, 2015, 2016, 2017, 2018)
replace state=94 if state_fips==2  & inlist(year, 2013, 2014, 2015, 2016, 2017, 2018)
replace state=95 if state_fips==15 & inlist(year, 2013, 2014, 2015, 2016, 2017, 2018)

drop state_fips

#delimit ;
label values state state;
label define state
	11	"Maine"
	12	"New Hampshire"
	13	"Vermont"
	14	"Massachusetts"
	15	"Rhode Island"
	16	"Connecticut"
	21	"New York"
	22	"New Jersey"
	23	"Pennsylvania"
	31	"Ohio"
	32	"Indiana"
	33	"Illinois"
	34	"Michigan"
	35	"Wisconsin"
	41	"Minnesota"
	42	"Iowa"
	43          "Missouri"                      
	44          "North Dakota"                  
	45          "South Dakota"                  
	46          "Nebraska"                      
	47          "Kansas"                        
	51          "Delaware"                      
	52          "Maryland"                      
	53          "District of Columbia"          
	54          "Virginia"                      
	55          "West Virginia"                 
	56          "North Carolina"                
	57          "South Carolina"                
	58          "Georgia"                       
	59          "Florida"                       
	61          "Kentucky"                      
	62          "Tennessee"                     
	63          "Alabama"                       
	64          "Mississippi"                   
	71          "Arkansas"                      
	72          "Louisiana"                     
	73          "Oklahoma"                      
	74          "Texas"                         
	81          "Montana"                       
	82          "Idaho"                         
	83          "Wyoming"                       
	84          "Colorado"                      
	85          "New Mexico"                    
	86          "Arizona"                       
	87          "Utah"                          
	88          "Nevada"                        
	91          "Washington"                    
	92          "Oregon"                        
	93          "California"                    
	94          "Alaska"                        
	95          "Hawaii"
	98	    "Overseas"                        
;
#delimit cr

* Industry and occupation codes: (for now, do "last year" questions, although also "last week" ones) *
replace industry=ind if year>1987 
replace occup=occ if year>1987 

***** AGE COHORTS *****

* Birth year:
gen byear=year-age

* 4-year birth cohorts (1977-80, 81-84, 85-88, 89-92)
gen byear_grp="77-80" if byear>=1977 & byear<=1980
replace byear_grp="81-84" if byear>=1981 & byear<=1984
replace byear_grp="85-88" if byear>=1985 & byear<=1988
replace byear_grp="89-92" if byear>=1989 & byear<=1992


**** EDUCATION ****

gen educ=.
replace educ=1 if ed_lths==1
replace educ=2 if ed_hs==1
replace educ=3 if ed_scol==1
replace educ=4 if ed_ba==1
replace educ=5 if ed_grad==1

merge m:1 year ind using "`ipumsdata'/cps_ind_xwalk.dta" 
tab _merge /* only 9 ppl didn't match - not sure why, small so not going to worry */
drop _merge
merge m:1 year occ using "`ipumsdata'/cps_occ_xwalk.dta" 
tab _merge /* again, looks good, w/ 138/4.7 million that don't match */
drop _merge

tempfile all
save `all'

** Convert income vars to real income (2015$)
 use"`prepdata'/cpi.dta", clear
 keep if month==3
 keep if inrange(year,1979,2018)
 keep year monthly
 rename monthly cpi
 label var cpi "CPI (Annual avg)"
 su cpi if year==2015, meanonly
 local cpi2015=r(mean)
 merge 1:m year using `all', assert(3)
 drop _merge
 foreach v of varlist incearn ern_val ws_val wsal_val se_val semp_val frm_val frse_val ///
	uc_val wc_val ss_val ssi_val paw_val vet_val sur_val1 ///
 	sur_val2 srvs_val dis_val1 dis_val2 dsab_val ret_val1 ///
 	ret_val2 rtm_val int_val div_val rnt_val ed_val csp_val ///
 	alm_val fin_val oi_val ptotval pearnval pothval p_mvcare ///
 	p_mvcaid eit_cred agi {
		   gen `v'_r=`v'*`cpi2015'/cpi
		   local label : var label `v'
		   label var `v'_r "`label' (2015$)"
}
*Make a top-coded total earnings that is censored at the 98th percentile by year
 gen pearnval_tc_r=pearnval_r
 levelsof year, local(yrlist)
 foreach y of local yrlist {
   _pctile pearnval_r [aw=marsupwt] if year==`y', percentiles(98)
   replace pearnval_tc_r=r(r1) if year==`y' & pearnval_r>r(r1) & pearnval_r<.
 }
 
* A few more small things
replace age=a_age if year>1987
drop a_age
ren age1 age_bins


/********* CODE MAJOR OCCUPATION CATEGORIES ******

* Labels from IPUMS (also correspond to major categories in Census 2010 Occ Codes Xwalk)

qui gen occ_major=""
label var occ_major "2010 Census Occupation: Major"
qui replace occ_major="Management in Business, Science, and Arts" 	if occ2010>=10 & occ2010<=430
qui replace occ_major="Business Operations Specialists" 		if occ2010>=500 & occ2010<=730
qui replace occ_major="Financial Specialists" 				if occ2010>=800 & occ2010<=950
qui replace occ_major="Computer and Mathematical" 			if occ2010>=1000 & occ2010<=1240
qui replace occ_major="Architecture and Engineering" 			if occ2010>=1300 & occ2010<=1540
qui replace occ_major="Technicians"					if occ2010>=1550 & occ2010<=1560  
qui replace occ_major="Life, Physical, and Social Science:" 		if occ2010>=1600 & occ2010<=1980 
qui replace occ_major="Community and Social Services" 			if occ2010>=2000 & occ2010<=2060  
qui replace occ_major="Legal"						if occ2010>=2100 & occ2010<=2150  
qui replace occ_major="Education, Training, and Library" 		if occ2010>=2200 & occ2010<=2550  
qui replace occ_major="Arts, Design, Entertainment, Sports, and Media" 	if occ2010>=2600 & occ2010<=2920  
qui replace occ_major="Healthcare Practitioners and Technicians" 	if occ2010>=3000 & occ2010<=3540  
qui replace occ_major="Healthcare Support" 				if occ2010>=3600 & occ2010<=3650 
qui replace occ_major="Protective Service"				if occ2010>=3700 & occ2010<=3950  
qui replace occ_major="Food Preparation and Serving"			if occ2010>=4000 & occ2010<=4150  
qui replace occ_major="Building and Grounds Cleaning and Maintenance"	if occ2010>=4200 & occ2010<=4250  
qui replace occ_major="Personal Care and Service" 			if occ2010>=4300 & occ2010<=4650 
qui replace occ_major="Sales and Related" 				if occ2010>=4700 & occ2010<=4965 
qui replace occ_major="Office and Administrative Support" 		if occ2010>=5000 & occ2010<=5940  
qui replace occ_major="Farming, Fisheries, and Forestry" 		if occ2010>=6005 & occ2010<=6130  
qui replace occ_major="Construction" 					if occ2010>=6200 & occ2010<=6765  
qui replace occ_major="Extraction" 					if occ2010>=6800 & occ2010<=6940  
qui replace occ_major="Installation, Maintenance, and Repair" 		if occ2010>=7000 & occ2010<=7630  
qui replace occ_major="Production" 					if occ2010>=7700 & occ2010<=8965  
qui replace occ_major="Transportation and Material Moving" 		if occ2010>=9000 & occ2010<=9750  
qui replace occ_major="Military" 					if occ2010>=9800 & occ2010<=9830
qui replace occ_major="No Occupation" 					if occ2010==9920 
*/

** SAVE FILE **

compress
save `prepdata'/`dofile'.dta, replace
! gzip -f `prepdata'/`dofile'.dta

if `doasproject'==1 project, creates(`prepdata'/`dofile'.dta.gz)


* end of do file *

