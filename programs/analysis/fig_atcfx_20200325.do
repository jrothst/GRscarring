***************************************************************************************************************
* fig_atcfx.do
* JR, 9/20/2017
*
* Edits:
* JR, 4/10/18:  Limit cohort graphs to 1976 cohorts and forward.
* JR, 4/11/18:  Rewrite code to avoid repeating code.
*               Added adjustment to m3 cohort effects to incorporate UR0 main effects.
* 4/16/18, JR:  Adjusted code to loop over dependent variables, defined at top, to avoid
*               repeating code.
* 4/25/18, RY:  Revised the march variable names
* 5/3/18,  RY:  Revised to use the new model naming convention  
* 5/16/18, JR:  Revised to standardize names, fix model choices, fix adjustment for base conditions.
* 5/22/18, RY:  Added new topcoded annual earnings variable (to be used for main analysis)  
* 6/14/18, JR:  Revised to no longer adjust the year/cohort effects in models with UR interactions,
*               as the newly revised model specifications make this unnecessary.
* 12/14/18,SR:  Distinguish cohort effects by pattern and color in cohort B figure.
* 1/17/19, SR:  Add figures that show sample B models B C D E (base model, excess sensitive, scarring, and 
*               excess sensitivity + scarring)  
* 1/21/19, SR:  Add figures that show sample B models B C D for cohort c (full sample, exclude <24).  
* 3/7/19,  SR:  Revised to only multiply coefficient by 100 if depvar == "empl"  
* 9/2/19,  JR:  Better code to drop last observation in each cohort series, for which there is
*               only a single observation. Last year is coded by hand; needs to be updated
*               if more data are added.
*9/16/19,  NG:  Add new figures on employment and wages based on the basic model. Specifications are as following;
*		         basic model, without time effects, only age>25, with series extrapolating data on pre-recession cohorts
*12/9/19,  JR:  Adjusted code (lines 227-236) to accommodate cohorts measured as years of entry rather than
*                birth years. Also added code to facilitate debugging -- allows running only part of
*                the program at a time (in non-project mode)
* 01/03/20,  NG: Cosmetic changes about the figures. Fixed issues with figures 8, 9, 4, 5 and loops that were not running properly
* 01/20/2020: NG:  Updated to match with the new cohort and birthcohort variables 
* 02/19/2020: NG:  Updated to keep only new figures used in the paper. 
* 				   See  GRscarring/archive/archive_20200216_161201/programs/analysis/old for a older and longer version of this program 


***************************************************************************************************************  
clear
cap project, doinfo
if _rc==0 {
	local pdir "`r(pdir)'"						  	    // the project's main dir.
	local dofile "`r(dofile)'"						    // do-file's stub name
	local sig {bind:{hi:[`dofile'.dta. RP : `dofile'.do, `c(current_date)']}}	// a signature in notes
	local doasproject=1
}
else {
	local pdir "~/GRscarring"
	local dofile "fig_atcfx"
	local doasproject=0
}

set more off
local rootdir "`pdir'"
local thisdir "`pdir'"

local scratch "`pdir'/scratch"
local rawdata "`pdir'/rawdata"
local output "`pdir'/results"

set scheme s1color

if `doasproject'==1 {
	project, uses(`scratch'/recessionlist.dta)
	project, uses(`scratch'/extrapolate_coeffs.dta)
}

local depvars "empl rw_l log_pearnval_tc_r"
local depvars empl rw_l

local edtxt0 "<BA"
local edtxt1 "BA+"
local ytitle_empl "Employment rate in %"
local title_empl "Employment rate, 22-40"
local titleB_empl "Year effects on employment, 22-40"
local titleD_empl "Cohort effects on employment, 22-40"
local legend_empl "Employment rate"
local ytitle_rw_l "Log real hourly wage"
local title_rw_l "Log real wage, 22-40"
local titleB_rw_l "Year effects on log wages, 22-40"
local titleD_rw_l "Cohort effects on log wages, 22-40"
local legend_rw_l "Log real hourly wage"
local ytitle_log_pearnval_tc_r "Log real annual earnings"
local title_log_pearnval_tc_r "Log real annual earnings, 22-40"
local titleB_log_pearnval_tc_r "Year effects on log earnings, 22-40"
local titleD_log_pearnval_tc_r "Cohort effects on log earnings, 22-40"
local legend_log_pearnval_tc_r "Log real annual earnings"

local depvars "empl rw_l log_pearnval_tc_r "

*** Cohort effects 
	*Get cohort effects from models A,B,C
	use `scratch'/extrapolate_coeffs, clear
	gen keep="A"
	foreach v in `depvars' {
	  replace keep="B" if depvar=="`v'"
	}
	keep if keep=="B"
	drop keep
	keep if ivartype=="FV" & fvname=="entrycohort" 
	
gen birthcohort=fvval
label var birthcohort "Year of Birth"
gen educ=real(substr(model,3,1))
gen entrycohort=. 
replace entrycohort=birthcohort+22 if educ==1
replace entrycohort=birthcohort+18 if educ==0
label var entrycohort "Year of entry on the labor market, depending on level of education"

	replace b = b*100 if depvar == "empl"
	gen month=ym(birthcohort, 7)

	tempfile base
	save `base'
	su month, meanonly
	local fmonth=r(min)
	local lmonth=r(max)
	levelsof fvval
	local fvval "`r(levels)'"
	local ng=wordcount("`fvval'")
	use `scratch'/recessionlist, clear
	keep if month>=`fmonth'-6 & month<=`lmonth'+5
	isid month
	expand `ng'
	sort month
	gen fvval=.
	 forvalues g=1/`ng' {
	   local w=word("`fvval'", `g')
	   by month: replace fvval=`w' if _n==`g'
	   }
	 tempfile recessionlist
	 save `recessionlist'
	 use `base', clear
	 merge m:1 fvval month using `recessionlist'
	 format month %tm
	 label values fvval fvval_l   
 
	sort  month  recession

	*Drop observations from before the 1978 birthcohort
	*drop if month<186
	drop if month<ym(1978,7)
	
	*Drop observations from the last cohort, for which we have only a single observation
	 *For now (9/2/19), this is 2018 for bigcps outcomes, 2017 for MORG, and 2016 for March
	 *Note that code is for specific dependent variables -- all others are set to missing
	 *for safety
	 * NG (12/26/19) Edit -- 2019 for bigcps outcomes
	 foreach v in `depvars' {
	   if "`v'"=="empl" drop if depvar=="`v'" & month>=ym(2019,7)
	   else if "`v'"=="log_pearnval_tc_r" drop if depvar=="`v'" & month>=ym(2016,7)
	   else if "`v'"=="rw_l" drop if  month>=ym(2017,7)
	   else drop if depvar=="`v'"
	}

	local edyr0 "18"
	local edyr1 "22"

	************************************************************************
	** Statistics for use in body of paper **

	** Base Model Change in Coefficients 
	su b if model=="mB1a" & depvar=="empl" & entrycohort==2006
	local coeff_base_2006 = r(mean)

	su b if model=="mB1a" & depvar=="empl" & entrycohort==2010
	local coeff_base_2010 = r(mean)

	** Scarring Model Change in Coefficients 
	su b if model=="mD1a" & depvar=="empl" & entrycohort==2006
	local coeff_scar_2006 = r(mean)

	su b if model=="mD1a" & depvar=="empl" & entrycohort==2010
	local coeff_scar_2010 = r(mean)

	** Change in cohort effect between 
	** mean(2010-11) cohort and
	** mean(2005-06) cohort
	su b if model=="mB1a" & depvar=="empl" & (entrycohort==2010 | entrycohort==2011) 
	local cohorteff_empl_post = r(mean)
	su b if model=="mB1a" & depvar=="empl" & (entrycohort==2005 | entrycohort==2006) 
	local cohorteff_empl_pre = r(mean)
	di `cohorteff_empl_post' - `cohorteff_empl_pre'

	su b if model=="mB1a" & depvar=="log_pearnval_tc_r" & (entrycohort==2010 | entrycohort==2011) 
	local cohorteff_earn_post = r(mean)
	su b if model=="mB1a" & depvar=="log_pearnval_tc_r" & (entrycohort==2005 | entrycohort==2006) 
	local cohorteff_earn_pre = r(mean)
	di `cohorteff_earn_post' - `cohorteff_earn_pre'
	************************************************************************
	* mB: Basic
	*mC: Excess sensitivity
	* mD: Scarring
	* mE: Scarring + Excess sensitivity
	* _a => extrapolated / older cohorts
	*_b => full sample

local ytitle_empl_updated "Relative employment rate in %"
local ytitle_rw_l_updated "Log real hourly wage(1991=0)"
local ytitle_log_pearnval_tc_r "Log real annual earnings (1991=0)"
	
	**  Figure 4 - Basic Model Cohort Effects Only  + without time controls + just age 25+ extrapolates from pre-recession cohorts
		  twoway area recession month if recession<., yaxis(2) ytitle("", axis(2)) ylabel(none, axis(2)) color(gs13) || ///
		  line b month if model=="mB1b" & depvar=="empl", lpattern(solid) color(red) ||  line b month if model=="mA1b" & depvar=="empl", lpattern(dash) color(cranberry) || ///
		  line b month if model=="mB1c" & depvar=="empl", lpattern(solid) color(midblue) ||  line b month if model=="mB1a" & depvar=="empl", lpattern(dash) color(navy) || , ///
		  xlabel(/* 6 "1960" 66 "1965" 126 "1970" */ 186 "1975" 246 "1980" 306 "1985" 366 "1990" 426 "1995" 486 "2000" 546 "2005" 606 "2010" 666 "2015" )  ///
		  legend(order(2 "Baseline" 3 "No year controls" 4 "Age 25+" 5 "Pre-recession fit") cols(1) ring(0) pos(6)) ///
		  ytitle("`ytitle_`d'_updated'") xtitle("Year when turned `edyr`e''") ///
			  xline(2007) title("Cohort effects on employment of college graduates", size(medsmall)) ///
		  saving("`output'/`dofile'_cohortB_ed1_empl_basic_updated.gph", replace)
		  
	**  Figure 5 - Basic Model Cohort Effects Only  + without time controls + just age 25+ extrapolates from pre-recession cohorts
		  twoway area recession month if recession<., yaxis(2) ytitle("", axis(2)) ylabel(none, axis(2)) color(gs13) || ///
		  line b month if model=="mB1b" & depvar=="rw_l", lpattern(solid) color(red) ||  line b month if model=="mA1b" & depvar=="rw_l", lpattern(dash) color(cranberry) || ///
		  line b month if model=="mB1c" & depvar=="rw_l", lpattern(solid) color(midblue) ||  line b month if model=="mB1a" & depvar=="rw_l", lpattern(dash) color(navy) || , ///
		  xlabel(/* 6 "1960" 66 "1965" 126 "1970" */ 186 "1975" 246 "1980" 306 "1985" 366 "1990" 426 "1995" 486 "2000" 546 "2005" 606 "2010" 666 "2015" )  ///
		  legend(order(2 "Baseline" 3 "No year controls" 4 "Age 25+" 5 "Pre-recession fit") cols(1) ring(0) pos(6)) ///
		  ytitle("`ytitle_`d'_updated'") xtitle("Year when turned `edyr`e''") ///
			  xline(2007) title("Cohort effects on log wages of college graduates", size(medsmall)) ///
		  saving("`output'/`dofile'_cohortB_ed1_rw_l_basic_updated.gph", replace)
		  
		  
	** Figure 8  - Scarring & Sensitivity Cohort Effects, all sample
		  twoway area recession month if recession<., yaxis(2) ytitle("", axis(2)) ylabel(none, axis(2)) color(gs13) || ///
		  line b month if model=="mB1b" & depvar=="empl", lpattern(solid) color(red) ||  line b month if model=="mC1b" & depvar=="empl", lpattern(dash) color(cranberry) || ///
		  line b month if model=="mD1b" & depvar=="empl", lpattern(solid) color(midblue) ||  line b month if model=="mE1b" & depvar=="empl", lpattern(dash) color(navy) || , ///
		  xlabel(/* 6 "1960" 66 "1965" 126 "1970" */ 186 "1975" 246 "1980" 306 "1985" 366 "1990" 426 "1995" 486 "2000" 546 "2005" 606 "2010" 666 "2015" )  ///
		  legend(order(2 "Basic model" 3 "Excess sensitivity" ///
				 4 "Scarring" 5 "Excess sensitivity and scarring") cols(1) ring(0) pos(6)) ///
		  ytitle("`ytitle_`d'' (1991=2000=0)") xtitle("Year when turned `edyr`e''") ///
			  xline(2007) title("Cohort effects on employment of college graduates", size(medsmall))  ///
		  saving("`output'/`dofile'_cohortB_ed1_empl_sensitivity_and_scarring.gph", replace)
		  
		  ** Figure 9 - Scarring & Sensitivity Cohort Effects, all sample
		  twoway area recession month if recession<., yaxis(2) ytitle("", axis(2)) ylabel(none, axis(2)) color(gs13) || ///
		  line b month if model=="mB1b" & depvar=="rw_l", lpattern(solid) color(red) ||  line b month if model=="mC1b" & depvar=="rw_l", lpattern(dash) color(cranberry) || ///
		  line b month if model=="mD1b" & depvar=="rw_l", lpattern(solid) color(midblue) ||  line b month if model=="mE1b" & depvar=="rw_l", lpattern(dash) color(navy) || , ///
		  xlabel(/* 6 "1960" 66 "1965" 126 "1970" */ 186 "1975" 246 "1980" 306 "1985" 366 "1990" 426 "1995" 486 "2000" 546 "2005" 606 "2010" 666 "2015" )  ///
		  legend(order(2 "Basic model" 3 "Excess sensitivity" ///
				 4 "Scarring" 5 "Excess sensitivity and scarring") cols(1) ring(0) pos(6)) ///
		  ytitle("`ytitle_`d'' (1991=2000=0)") xtitle("Year when turned `edyr`e''") ///
			  xline(2007) title("Cohort effects on log wages of college graduates", size(medsmall))  ///
		  saving("`output'/`dofile'_cohortB_ed1_rw_l_sensitivity_and_scarring.gph", replace)

if `doasproject'==1 {
  foreach d in `depvars ' {
    foreach e in 0 1 {
      project, creates(`output'/`dofile'_cohortB_ed`e'_`d'_basic_updated.gph)
      project, creates(`output'/`dofile'_cohortB_ed`e'_`d'_sensitivity_and_scarring.gph)
    }
  }
}
