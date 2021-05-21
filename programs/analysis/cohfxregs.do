

*Regressions of cohort effects from various models on the unemployment rate at entry

* Edits:
* RY, 5/22/18: Added new topcoded annual earnings variable  
* NR, 1/20/19: Append cohort effects for each variable for cohorts 2002, 2006
*              and 2010
* JR, 5/3/19:  Report the regression in the log, and adjust the calculation and reporting
*              of the 2002-6-10 cohort effects. 
* NG, 9/27/19; Added New tables and figures for revision
* NG: 1/3/2020:  Updated to match with the new cohort and birthcohort variables 
* NG, 1/5/20; Fixed issue with the tables and the recession area
* JR, 1/16/20: Fixed loop issue to generate predicted values from regressions
* NG:  02/19/2020:  Updated to keep only new figures used in the paper. 
* 				   See  GRscarring/archive/archive_20200216_161201/programs/analysis/old for a older and longer version of this program 
* JR: 4/12/2020: Entirely rewritten



set more off
eststo clear
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
	local dofile "cohfxregs"
	local doasproject=0
}

set more off
local rootdir "`pdir'"
local thisdir "`pdir'"

local scratch "`pdir'/scratch"
local rawdata "`pdir'/rawdata"
local output "`pdir'/results"

if `doasproject'==1 {
	project, uses(`scratch'/extrapolate_coeffs.dta)
	project, uses(`scratch'/unrate_national.dta)
}

**Prepare data - cohoft effects
use `scratch'/extrapolate_coeffs, clear

*We keep only the cohort models
keep if ivartype=="FV" & fvname=="entrycohort"

* Since extrapolate is defined by the entrycohort date, we redefine a birthcohort variable based on the level of education
gen educ=real(substr(model,3,1))
gen birthcohort=.
replace birthcohort=fvval-22 if educ==1
replace birthcohort=fvval-18 if educ==0

* We use entrycohort to match with the actual unemployment rate 
gen entrycohort= fvval
gen yearmo=ym(entrycohort,7)
merge m:1 yearmo using `scratch'/unrate_national, keepusing(ur_nat_annual) keep(1 3) nogen
rename ur_nat_annual ur0

replace b=b*100 if inlist(depvar,"labfor", "empl", "unem", "livewithprnt", "married", "lives_spouse_oth", "chld_pr")
replace se=se*100 if inlist(depvar,"labfor", "empl", "unem", "livewithprnt", "married", "lives_spouse_oth", "chld_pr")

// Different UR0 after the year 2004
gen post2005=0
replace post2005=1 if fvval>2004   
gen ur0_post2005= ur0 * post2005
gen postc=(fvval-2004)*post2005
gen post1978=0
replace post1978=1 if fvval>1977
gen postc1978=(fvval-1977)*post1978

* We create a quadratic term
gen year2=(birthcohort-1980)^2  

levelsof depvar, local(dvars)
levelsof model, local(mods)
local dvars "empl rw_l"

gen ur0_save=ur0
su ur0, meanonly
local avgur0=r(mean)
egen dvarmod=group(depvar model)

tempfile cohfx
save `cohfx'

**Prepare data - time effects
use `scratch'/extrapolate_coeffs, clear

*We keep only the cohort models
keep if ivartype=="FV" & fvname=="year"

* Since extrapolate is defined by the entrycohort date, we redefine a birthcohort variable based on the level of education
gen educ=real(substr(model,3,1))

* We use entrycohort to match with the actual unemployment rate 
gen year= fvval
gen yearmo=ym(year,7)
merge m:1 yearmo using `scratch'/unrate_national, keepusing(ur_nat_annual) keep(1 3) nogen
rename ur_nat_annual ur

replace b=b*100 if inlist(depvar,"labfor", "empl", "unem", "livewithprnt", "married", "lives_spouse_oth", "chld_pr")
replace se=se*100 if inlist(depvar,"labfor", "empl", "unem", "livewithprnt", "married", "lives_spouse_oth", "chld_pr")

// Different UR after the year 2004
gen post2005=0
replace post2005=1 if fvval>2004   
gen ur0_post2005= ur * post2005
gen postt=(fvval-2004)*post2005
gen post1978=0
replace post1978=1 if fvval>1977
gen postt1978=(fvval-1977)*post1978

* We create a quadratic term
gen year2=(year-1980)^2  

levelsof depvar, local(dvars)
levelsof model, local(mods)
local dvars "empl rw_l"

gen ur_save=ur
su ur, meanonly
local avgur=r(mean)
egen dvarmod=group(depvar model)

tempfile timefx
save `timefx'


****Run cyclicality regressions - cohort effeccts
// Four loops:
//  1) Outcomes, 
//  2) Cohort effect models -- age-adjusted, basic A-T-C decomposition, scarring, sensitivity, both
//  3) Samples: Full sample, pre-GR
//  4) Three regression models: no controls, time trend, time trend*post-2005 indicator.
use `cohfx', clear
estimates clear
xtset dvarmod entrycohort
tempvar pred
local nmodels=0
foreach depvar in empl rw_l {
  foreach cohfx in A B D C E {
    foreach samp in full preGR {
      if "`samp'"=="full" local select 
      else if "`samp'"=="preGR" local select "& entrycohort<2005"

      foreach controls in none trend break break78 2break {
         if "`controls'"=="none" local X ""
         if "`controls'"=="trend" local X "entrycohort"
         if "`controls'"=="break" local X "entrycohort post2005 postc"
         if "`controls'"=="break78" local X "entrycohort post1978 postc1978"
         if "`controls'"=="2break" local X "entrycohort post2005 postc post1978 postc1978"
         if "`controls'"=="none" local spec "0"
         if "`controls'"=="trend" local spec "1"
         if "`controls'"=="break" local spec "2"
         if "`controls'"=="break78" local spec "3"
         if "`controls'"=="2break" local spec "4"
         di
         di
         di "Depvar: `depvar'. Cohort effects type: `cohfx'. Sample: `samp'. Controls: `controls'"
         if "`samp'"=="preGR" & inlist("`controls'","break","2break") di "Skipping model"
         else {
           newey b ur0 `X' if depvar=="`depvar'" & model=="m`cohfx'1b" `select', lag(2)
           eststo `depvar'_`cohfx'_`samp'_`controls'_cohort, title("`cohfx'_`spec'_`samp'")
           local b_`depvar'_`cohfx'_`samp'_`controls'_cohort=_b[ur0]
          
           predict `pred' , xb
           cap confirm var fitted_`samp'_`spec'
           if _rc==0 {
             replace fitted_`samp'_`spec'=`pred' if depvar=="`depvar'" & model=="m`cohfx'1b"
             replace resid_`samp'_`spec'=b-fitted_`samp'_`spec' if depvar=="`depvar'" & model=="m`cohfx'1b"
           }
           else {
             gen fitted_`samp'_`spec'=`pred' if depvar=="`depvar'" & model=="m`cohfx'1b"
             gen resid_`samp'_`spec'=b-fitted_`samp'_`spec' if depvar=="`depvar'" & model=="m`cohfx'1b"
           }
           drop `pred'
         }
         local nmodels=`nmodels'+1
      } // end of controls loop
    } // end of samp loop
  } // end of cohfx loop 
} // End of depvar loop
keep entrycohort b model depvar ur0 fitted_* resid_*
tempfile cohfx2
save `cohfx2'

***Make a dataset of the coefficients
drop _all
set obs `nmodels'
local modelnum=1
gen depvar=""
gen cohfx=""
gen samp=""
gen controls=""
gen model=""
gen delta=.
foreach depvar in empl rw_l {
  foreach cohfx in A B D C E {
    foreach samp in full preGR {
      foreach controls in none trend break break78 2break {
        replace depvar="`depvar'" in `modelnum'
        replace cohfx="`cohfx'" in `modelnum'
        replace samp="`samp'" in `modelnum'
        replace controls="`controls'" in `modelnum'
        replace model="m`cohfx'1b" in `modelnum'
        if "`b_`depvar'_`cohfx'_`samp'_`controls'_cohort'"!="" ///
          replace delta=`b_`depvar'_`cohfx'_`samp'_`controls'_cohort' in `modelnum'
        local modelnum=`modelnum'+1
      }
    }
  }
}
tempfile deltas
save `deltas'

****Run cyclicality regressions - time effeccts
// Four loops:
//  1) Outcomes, 
//  2) Cohort effect models -- age-adjusted, basic A-T-C decomposition, scarring, sensitivity, both
//  3) Samples: Full sample, pre-GR
//  4) Three regression models: no controls, time trend, time trend*post-2005 indicator.
use `timefx', clear
tsset dvarmod year
tempvar pred
local nmodels=0
foreach depvar in empl rw_l {
  foreach timefx in B D C E {
    foreach samp in full preGR {
      if "`samp'"=="full" local select 
      else if "`samp'"=="preGR" local select "& year<2005"

      foreach controls in none trend break {
         if "`controls'"=="none" local X ""
         if "`controls'"=="trend" local X "year"
         if "`controls'"=="break" local X "year post2005 postt"
         //if "`controls'"=="break78" local X "year post1978 postt1978"
         //if "`controls'"=="break2" local X "year post2005 postt post1978 postt1978"
         if "`controls'"=="none" local spec "0"
         if "`controls'"=="trend" local spec "1"
         if "`controls'"=="break" local spec "2"
         //if "`controls'"=="break78" local spec "3"
         //if "`controls'"=="2break" local spec "4"
         di
         di
         di "Depvar: `depvar'. Time effects type: `timefx'. Sample: `samp'. Controls: `controls'"
         if "`samp'"=="preGR" & inlist("`controls'","break","2break") di "Skipping model"
         else {
           newey b ur `X' if depvar=="`depvar'" & model=="m`timefx'1b" `select', lag(2)
           eststo `depvar'_`timefx'_`samp'_`controls'_time, title("`timefx'_`spec'_`samp'")
           local b_`depvar'_`timefx'_`samp'_`controls'_time=_b[ur]
          
           predict `pred' , xb
           cap confirm var fitted_`samp'_`spec'
           if _rc==0 {
             replace fitted_`samp'_`spec'=`pred' if depvar=="`depvar'" & model=="m`timefx'1b"
             replace resid_`samp'_`spec'=b-fitted_`samp'_`spec' if depvar=="`depvar'" & model=="m`timefx'1b"
           }
           else {
             gen fitted_`samp'_`spec'=`pred' if depvar=="`depvar'" & model=="m`timefx'1b"
             gen resid_`samp'_`spec'=b-fitted_`samp'_`spec' if depvar=="`depvar'" & model=="m`timefx'1b"
           }
           drop `pred'
         }
         local nmodels=`nmodels'+1
      } // end of controls loop
    } // end of samp loop
  } // end of timefx loop 
} // End of depvar loop
keep year b model depvar ur fitted_* resid_*
append using `cohfx2'
save `cohfx2', replace

***Make a dataset of the coefficients
drop _all
set obs `nmodels'
local modelnum=1
gen depvar=""
gen timefx=""
gen samp=""
gen controls=""
gen model=""
gen beta=.
foreach depvar in empl rw_l {
  foreach timefx in B D C E {
    foreach samp in full preGR {
      foreach controls in none trend break {
        replace depvar="`depvar'" in `modelnum'
        replace timefx="`timefx'" in `modelnum'
        replace samp="`samp'" in `modelnum'
        replace model="m`timefx'1b" in `modelnum'
        replace controls="`controls'" in `modelnum'
        if "`b_`depvar'_`timefx'_`samp'_`controls'_time'"!="" ///
          replace beta=`b_`depvar'_`timefx'_`samp'_`controls'_time' in `modelnum'
        local modelnum=`modelnum'+1
      }
    }
  }
}
append using `deltas'
save `output'/`dofile'_cyclecoeffs.dta, replace

// Now make the tables
use `cohfx2', clear
esttab empl_*_cohort using `output'/`dofile'.txt, replace b se nostar noparen nogaps mtitles ///
    title("Models for cohort effects on dependent variable empl") 
esttab empl_*_time using `output'/`dofile'.txt, append b se nostar noparen nogaps mtitles ///
    title("Models for year effects on dependent variable empl") 

esttab rw_l_*_cohort using `output'/`dofile'.txt, append b se nostar noparen nogaps mtitles ///
    title("Models for cohort effects on dependent variable rw_l") 
esttab rw_l_*_time using `output'/`dofile'.txt, append b se nostar noparen nogaps mtitles ///
    title("Models for year effects on dependent variable rw_l") 

esttab empl_*_cohort using `output'/`dofile'.csv, replace b se nostar noparen nogaps mtitles ///
    title("Models for cohort effects on dependent variable empl") 
esttab empl_*_time using `output'/`dofile'.csv, append b se nostar noparen nogaps mtitles ///
    title("Models for year effects on dependent variable empl") 

esttab rw_l_*_cohort using `output'/`dofile'.csv, append b se nostar noparen nogaps mtitles ///
    title("Models for cohort effects on dependent variable rw_l") 
esttab rw_l_*_time using `output'/`dofile'.csv, append b se nostar noparen nogaps mtitles ///
    title("Models for year effects on dependent variable rw_l") 


save `scratch'/`dofile'.dta, replace


//And make graphs
// Now convert to monthly data for recession shading

    keep if entrycohort<.
	gen month=ym(entrycohort, 7)

	tempfile base
	save `base'
	su month, meanonly
	local fmonth=r(min)
	local lmonth=r(max)

	use `scratch'/recessionlist, clear
	keep if month>=`fmonth'-6 & month<=`lmonth'+5
	gen model="recession"
	append using `base'

	*Drop observations from before the 1978 birthcohort
	*drop if month<ym(1978,7)
	drop if month<ym(1970,1)
	
	*Drop observations from the last cohort, for which we have only a single observation
	 *For now (4/13/2020), this is 2019 for bigcps outcomes, 2019 for MORG, and 2017 for March
	 *Note that code is for specific dependent variables -- all others are set to missing
	 *for safety
	 drop if depvar=="empl" & month>ym(2018,12)
	 drop if depvar=="rw_l" & month>ym(2018,12)
	 drop if depvar=="log_pearnval_tc_r" & month>=ym(2016,7)
	 drop if !inlist(depvar, "empl", "rw_l", "log_pearnval_tc_r") & !inlist(model,"recession", "means")

    gen altrecession=recession
    gen zero=0 if model=="recession"
  
// Baseline cohort graphs -- show the importance of A-T-C decomposition
    replace altrecession=-6+8.5*recession
    foreach m in B C D E {
      if "`m'"=="B" local paneltitle "Basic decomposition"
      if "`m'"=="C" local paneltitle "Controlling for excess sensitivity"
      if "`m'"=="D" local paneltitle "Controlling for scarring"
      if "`m'"=="E" local paneltitle "Controlling for scarring & excess sensitivity"
      if "`m'"=="E" local legendopt `"legend(order(2 "Estimated cohort effects" 3 "Predicted cohort effects") cols(1) ring(0) pos(7))"'
      else local legendopt "legend(off)"
      twoway area altrecession month if model=="recession", color(gs13) base(-6) || ///
             line b month if model=="m`m'1b" & depvar=="empl", lstyle(p1) lpattern(solid)  yaxis(1) || ///
             line fitted_preGR_1 month if model=="m`m'1b" & depvar=="empl", lstyle(p2) lpattern(dash) yaxis(1) || ///
             line zero month if model=="recession", lpattern(dot) lcolor(black) || ///
  		     , xlabel( 126 "1970" 246 "1980" 366 "1990" 486 "2000" 606 "2010" 726 "2020" )  ///
		       `legendopt' ///
		       ytitle("Employment (%, 1991=2000=0)") xtitle("Entry cohort") ///
		 	   title("`paneltitle'", size(medsmall)) ///
		 	   name(model`m', replace) nodraw
    }
    local m="B"
    local legendopt `"legend(order(2 "Estimated cohort effects" 3 "Predicted cohort effects") cols(1) ring(0) pos(7))"'
      twoway area altrecession month if model=="recession", color(gs13) base(-6) || ///
             line b month if model=="m`m'1b" & depvar=="empl", lstyle(p2) lpattern(solid)  yaxis(1) || ///
             line fitted_preGR_1 month if model=="m`m'1b" & depvar=="empl", lstyle(p3) lpattern(dash) yaxis(1) || ///
             line zero month if model=="recession", lpattern(dot) lcolor(black) || ///
  		     , xlabel( 126 "1970" 246 "1980" 366 "1990" 486 "2000" 606 "2010" 726 "2020" )  ///
		       `legendopt' ///
		       ytitle("Employment (%, 1991=2000=0)") xtitle("Entry cohort") ///
		 	   title("A. Basic employment decomposition", size(medsmall)) ///
		 	   name(panelA, replace) nodraw
    local m="E"
    local legendopt "legend(off)"
      twoway area altrecession month if model=="recession", color(gs13) base(-6) || ///
             line b month if model=="m`m'1b" & depvar=="empl", lstyle(p2) lpattern(solid)  yaxis(1) || ///
             line fitted_preGR_1 month if model=="m`m'1b" & depvar=="empl", lstyle(p3) lpattern(dash) yaxis(1) || ///
             line zero month if model=="recession", lpattern(dot) lcolor(black) || ///
  		     , xlabel( 126 "1970" 246 "1980" 366 "1990" 486 "2000" 606 "2010" 726 "2020" )  ///
		       `legendopt' ///
		       ytitle("Employment (%, 1991=2000=0)") xtitle("Entry cohort") ///
		 	   title("B. Employment, controlling for early career effects", size(medsmall)) ///
		 	   name(panelB, replace) nodraw

    graph combine modelB modelE, title("Predicted cohort effects on employment" "based on pre-2005 patterns") ///
          saving("`output'/`dofile'_2panel_empl.gph", replace)		 	 
    graph combine modelB modelD modelC modelE, title("Predicted cohort effects on employment" "based on pre-2005 patterns") ///
          saving("`output'/`dofile'_4panel_empl.gph", replace)		
          	 
    replace altrecession=-0.1 + 0.2*recession
    foreach m in B C D E {
      if "`m'"=="B" local paneltitle "Basic decomposition"
      if "`m'"=="C" local paneltitle "Controlling for excess sensitivity"
      if "`m'"=="D" local paneltitle "Controlling for scarring"
      if "`m'"=="E" local paneltitle "Controlling for scarring & excess sensitivity"
      if "`m'"=="E" local legendopt `"legend(order(2 "Estimated cohort effects" 3 "Predicted cohort effects") cols(1) ring(0) pos(11))"'
      else local legendopt "legend(off)"
      twoway area altrecession month if model=="recession", color(gs13) base(-0.1) || ///
             line b month if model=="m`m'1b" & depvar=="rw_l", lstyle(p3) lpattern(solid)  yaxis(1) || ///
             line fitted_preGR_3 month if model=="m`m'1b" & depvar=="rw_l", lstyle(p1) lpattern(dash) yaxis(1) || ///
             line zero month if model=="recession", lpattern(dot) lcolor(black) || ///
  		     , xlabel( 126 "1970" 246 "1980" 366 "1990" 486 "2000" 606 "2010" 726 "2020" )  ///
		       `legendopt' ///
  		       ylabel(-0.1 (0.05) 0.1) ///
		       ytitle("Log wage (1991=2000=0)") xtitle("Entry cohort") ///
		 	   title("`paneltitle'", size(medsmall)) ///
		 	   name(model`m', replace) nodraw
    }
    local m="B"
    local legendopt "legend(off)"
    replace altrecession=-0.1 + 0.15*recession
      twoway area altrecession month if model=="recession", color(gs13) base(-0.1) || ///
             line b month if model=="m`m'1b" & depvar=="rw_l", lstyle(p2) lpattern(solid)  yaxis(1) || ///
             line fitted_preGR_3 month if model=="m`m'1b" & depvar=="rw_l", lstyle(p3) lpattern(dash) yaxis(1) || ///
             line zero month if model=="recession", lpattern(dot) lcolor(black) || ///
  		     , xlabel( 126 "1970" 246 "1980" 366 "1990" 486 "2000" 606 "2010" 726 "2020" )  ///
		       `legendopt' ///
  		       ylabel(-0.1 (0.05) 0.05) ///
		       ytitle("Log wage (1991=2000=0)") xtitle("Entry cohort") ///
		 	   title("C. Basic log wage decomposition", size(medsmall)) ///
		 	   name(panelC, replace) nodraw
    local m="E"
    local legendopt "legend(off)"
      twoway area altrecession month if model=="recession", color(gs13) base(-0.1) || ///
             line b month if model=="m`m'1b" & depvar=="rw_l", lstyle(p2) lpattern(solid)  yaxis(1) || ///
             line fitted_preGR_3 month if model=="m`m'1b" & depvar=="rw_l", lstyle(p3) lpattern(dash) yaxis(1) || ///
             line zero month if model=="recession", lpattern(dot) lcolor(black) || ///
  		     , xlabel( 126 "1970" 246 "1980" 366 "1990" 486 "2000" 606 "2010" 726 "2020" )  ///
		       `legendopt' ///
  		       ylabel(-0.1 (0.05) 0.05) ///
		       ytitle("Log wage (1991=2000=0)") xtitle("Entry cohort") ///
		 	   title("D. Log wages, controlling for early career effects", size(medsmall)) ///
		 	   name(panelD, replace) nodraw
		 	   
    graph combine modelB modelE, title("Predicted cohort effects on log wages" "based on pre-2005 patterns") ///
          saving("`output'/`dofile'_2panel_rw_l.gph", replace)		 	 
    graph combine modelB modelD modelC modelE, title("Predicted cohort effects on log wages" "based on pre-2005 patterns") ///
          saving("`output'/`dofile'_4panel_rw_l.gph", replace)		 	 
  		     

    graph combine panelA panelB panelC panelD, title("Predicted cohort effects on employment and wages" "based on pre-2005 patterns") ///
          saving("`output'/`dofile'_4panel.gph", replace)

if `doasproject'==1 {
	project, creates(`scratch'/`dofile'.dta)
	project, creates(`output'/`dofile'.txt)
	project, creates(`output'/`dofile'.csv)
	project, creates(`output'/`dofile'_cyclecoeffs.dta)
	project, creates(`output'/`dofile'_2panel_empl.gph)
	project, creates(`output'/`dofile'_4panel_empl.gph)
	project, creates(`output'/`dofile'_2panel_rw_l.gph)
	project, creates(`output'/`dofile'_4panel_rw_l.gph)
	project, creates(`output'/`dofile'_4panel.gph)
}
