***************************************************************************************************************
* fig_atcfxbygender.do
* JR, 4/24/2020, based on fig_atcfx.do
*
* Edits:

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
	local dofile "fig_atcfxbygender"
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
	project, uses(`scratch'/runatc_bygender_coeffs.dta)
}

local depvars "empl rw_l log_pearnval_tc_r"

use `scratch'/runatc_bygender_coeffs, clear
gen keep=.
foreach v of local depvars {
  replace keep=1 if depvar=="`v'"
}
keep if keep==1
drop keep
keep if ivartype=="FV" & fvname=="entrycohort"
replace b = b*100 if depvar=="empl"
rename fvval entrycohort
gen educ=real(substr(model,3,1))
tempfile coeffs
save `coeffs'

// Now convert to monthly data for recession shading

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
*	drop if month<ym(1978,7)
	drop if month<ym(1970,1)
	
	*Drop observations from the last cohort, for which we have only a single observation
	 *For now (4/16/2020), this is 2019 for bigcps outcomes, 2019 for MORG, and 2017 for March
	 *Note that code is for specific dependent variables -- all others are set to missing
	 *for safety
	 drop if depvar=="empl" & month>ym(2018,12)
	 drop if depvar=="rw_l" & month>ym(2018,12)
	 drop if depvar=="log_pearnval_tc_r" & month>=ym(2016,7)
	 drop if !inlist(depvar, "empl", "rw_l", "log_pearnval_tc_r") & !inlist(model,"recession", "means")

    gen altrecession=recession
    gen zero=0 

// baseline ATC decomposition
   replace altrecession=-8+12*recession
   twoway area altrecession month if model=="recession", color(gs13) base(-8) || ///
          line b month if model=="mB10b" & depvar=="empl", lstyle(p1) || ///
          line b month if model=="mB11b" & depvar=="empl", lstyle(p2) || ///
          line zero month if model=="recession", lpattern(dot) lcolor(black) || ///
  		   , xlabel( 126 "1970" 246 "1980" 366 "1990" 486 "2000" 606 "2010" 726 "2020" )  ///
  		     ylabel(-8 (4) 4) ///
		     legend(order(2 "Female" 3 "Male") cols(1) ring(0) pos(7)) ///
		     ytitle("Employment rate (%, 1984=2000=0)") xtitle("Entry cohort") ///
		 	 title("Cohort effects on employment rates, college graduates, by gender", size(medsmall)) ///
  		     saving("`output'/`dofile'_cohortA_empl.gph", replace)

   replace altrecession=-0.11 + 0.21*recession
   twoway area altrecession month if model=="recession", color(gs13) base(-0.11) || ///
          line b month if model=="mB10b" & depvar=="rw_l", lstyle(p1) || ///
          line b month if model=="mB11b" & depvar=="rw_l", lstyle(p2) || ///
          line zero month if model=="recession", lpattern(dot) lcolor(black) || ///
  		   , xlabel( 126 "1970" 246 "1980" 366 "1990" 486 "2000" 606 "2010" 726 "2020" )  ///
		     legend(order(2 "Female" 3 "Male") cols(1) ring(0) pos(5)) ///
		     ytitle("Log real hourly wage (1984=2000=0)") xtitle("Entry cohort") ///
		 	 title("Cohort effects on log real wages, college graduates, by gender", size(medsmall)) ///
  		     saving("`output'/`dofile'_cohortA_rw_l.gph", replace)

// Effects of scarring and excess sensitivity by gender
   replace altrecession=-8+12*recession
   twoway area altrecession month if model=="recession", color(gs13) base(-8) || ///
          line b month if model=="mB10b" & depvar=="empl", lstyle(p1) || ///
          line b month if model=="mE10b" & depvar=="empl", lstyle(p2) lpattern(dash)  || ///
           line zero month if model=="mE10b" & depvar=="empl", lpattern(dot) lcolor(black) || ///
  		   , xlabel( 126 "1970" 246 "1980" 366 "1990" 486 "2000" 606 "2010" 726 "2020" )  ///
  		     ylabel(-8 (2) 2) ///
		     legend(off) ///
		     ytitle("Employment rate (%, 1984=2000=0)") xtitle("Entry cohort") nodraw ///
		 	 title("A. Female employment", size(medsmall)) name(scarring_fem, replace) 
   twoway area altrecession month if model=="recession", color(gs13) base(-8) || ///
          line b month if model=="mB11b" & depvar=="empl", lstyle(p1) || ///
          line b month if model=="mE11b" & depvar=="empl", lstyle(p2) lpattern(dash)  || ///
           line zero month if model=="mE11b" & depvar=="empl", lpattern(dot) lcolor(black) || ///
  		   , xlabel( 126 "1970" 246 "1980" 366 "1990" 486 "2000" 606 "2010" 726 "2020" )  ///
  		     ylabel(-8 (2) 2) ///
		     legend(order(2 "Baseline" 3 "Scarring & excess sensitivity") cols(1) ring(0) pos(7)) ///
		     ytitle("Employment rate (%, 1984=2000=0)") xtitle("Entry cohort") ///
		 	 title("B. Male employment", size(medsmall)) name(scarring_men, replace) nodraw
   graph combine scarring_fem scarring_men, ///
  		     saving("`output'/`dofile'_cohortB_empl.gph", replace)

   replace altrecession=-0.15 + 0.25*recession
   twoway area altrecession month if model=="recession", color(gs13) base(-0.15) || ///
          line b month if model=="mB10b" & depvar=="rw_l", lstyle(p1) || ///
          line b month if model=="mE10b" & depvar=="rw_l", lstyle(p2) lpattern(dash)  || ///
           line zero month if model=="mE10b" & depvar=="rw_l", lpattern(dot) lcolor(black) || ///
  		   , xlabel( 126 "1970" 246 "1980" 366 "1990" 486 "2000" 606 "2010" 726 "2020" )  ///
		     legend(order(2 "Baseline" 3 "Scarring & excess sensitivity") cols(1) ring(0) pos(11)) ///
		     ytitle("Log real hourly wage (%, 1984=2000=0)") xtitle("Entry cohort") nodraw ///
		 	 title("C. Female log wages", size(medsmall)) name(scarring_fem, replace) 
   twoway area altrecession month if model=="recession", color(gs13) base(-0.15) || ///
          line b month if model=="mB11b" & depvar=="rw_l", lstyle(p1) || ///
          line b month if model=="mE11b" & depvar=="rw_l", lstyle(p2) lpattern(dash) || ///
           line zero month if model=="mE11b" & depvar=="rw_l", lpattern(dot) lcolor(black) || ///
  		   , xlabel( 126 "1970" 246 "1980" 366 "1990" 486 "2000" 606 "2010" 726 "2020" )  ///
		     legend(off) ///
		     ytitle("Log real hourly wage (%, 1984=2000=0)") xtitle("Entry cohort") ///
		 	 title("D. Male log wages", size(medsmall)) name(scarring_men, replace) nodraw
   graph combine scarring_fem scarring_men, ///
  		     saving("`output'/`dofile'_cohortB_rw_l.gph", replace)
                 


if `doasproject'==1 {
  project, creates(`output'/`dofile'_cohortA_empl.gph)
  project, creates(`output'/`dofile'_cohortA_rw_l.gph)
  project, creates(`output'/`dofile'_cohortB_empl.gph)
  project, creates(`output'/`dofile'_cohortB_rw_l.gph)
}
    