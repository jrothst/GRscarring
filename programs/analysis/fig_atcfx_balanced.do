***************************************************************************************************************
* fig_atcfx_balanced.do
* JR, 6/29/2020, based on fig_atcfxbygender.do
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
	local dofile "fig_atcfx_balanced"
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
	project, uses(`scratch'/runatc_balanced_coeffs.dta)
    project, uses(`scratch'/extrapolate_coeffs.dta)
}

local depvars "empl rw_l log_pearnval_tc_r"

use `scratch'/extrapolate_coeffs, clear
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
keep if inlist(model, "mB0b", "mB1b", "mE0b", "mE1b")
gen variant=0
tempfile basecoeffs
save `basecoeffs'


use `scratch'/runatc_balanced_coeffs, clear
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
gen variant=1
tempfile coeffs
save `coeffs'

append using `basecoeffs'

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
   replace altrecession=-5+9*recession
   twoway area altrecession month if model=="recession", color(gs13) base(-5) || ///
          line b month if model=="mB1b" & depvar=="empl" & variant==0, lstyle(p1) lpattern(dash) || ///
          line b month if model=="mB1b" & depvar=="empl" & variant==1 & entrycohort>=1978, lstyle(p2) || ///
          line zero month if model=="recession", lpattern(dot) lcolor(black) || ///
  		   , xlabel( 126 "1970" 246 "1980" 366 "1990" 486 "2000" 606 "2010" 726 "2020" )  ///
  		     ylabel(-4 (2) 4) ///
		     legend(order(2 "Base specification" 3 "Balanced cohort-age") cols(1) ring(0) pos(7)) ///
		     ytitle("Employment rate (%, 1991=0)") xtitle("Entry cohort") ///
		 	 title("Employment rates", size(medsmall)) ///
		 	 name(empl, replace)
   replace altrecession=-0.1 + 0.15*recession
   twoway area altrecession month if model=="recession", color(gs13) base(-0.1) || ///
          line b month if model=="mB1b" & depvar=="rw_l" & variant==0, lstyle(p1) lpattern(dash) || ///
          line b month if model=="mB1b" & depvar=="rw_l" & variant==1 & entrycohort>=1978, lstyle(p2) || ///
          line zero month if model=="recession", lpattern(dot) lcolor(black) || ///
  		   , xlabel( 126 "1970" 246 "1980" 366 "1990" 486 "2000" 606 "2010" 726 "2020" )  ///
		     legend(off) ///
		     ytitle("Log real hourly wage (1984=2000=0)") xtitle("Entry cohort") ///
		 	 title("Log wages", size(medsmall)) ///
		 	 name(rw_l, replace)
   graph combine empl rw_l, title("Cohort effects on employment and wages:" "Balanced cohort-age panel estimates") ///
          saving("`output'/`dofile'.gph", replace)

// scarring-adjusted ATC decomposition
   replace altrecession=-5+9*recession
   twoway area altrecession month if model=="recession", color(gs13) base(-5) || ///
          line b month if model=="mE1b" & depvar=="empl" & variant==0, lstyle(p1) lpattern(dash) || ///
          line b month if model=="mE1b" & depvar=="empl" & variant==1 & entrycohort>=1978, lstyle(p2) || ///
          line zero month if model=="recession", lpattern(dot) lcolor(black) || ///
  		   , xlabel( 126 "1970" 246 "1980" 366 "1990" 486 "2000" 606 "2010" 726 "2020" )  ///
  		     ylabel(-4 (2) 4) ///
		     legend(order(2 "Base specification" 3 "Balanced cohort-age") cols(1) ring(0) pos(7)) ///
		     ytitle("Employment rate (%, 1991=0)") xtitle("Entry cohort") ///
		 	 title("Employment rates", size(medsmall)) ///
		 	 name(empl, replace)
   replace altrecession=-0.1 + 0.15*recession
   twoway area altrecession month if model=="recession", color(gs13) base(-0.1) || ///
          line b month if model=="mE1b" & depvar=="rw_l" & variant==0, lstyle(p1) lpattern(dash) || ///
          line b month if model=="mE1b" & depvar=="rw_l" & variant==1 & entrycohort>=1978, lstyle(p2) || ///
          line zero month if model=="recession", lpattern(dot) lcolor(black) || ///
  		   , xlabel( 126 "1970" 246 "1980" 366 "1990" 486 "2000" 606 "2010" 726 "2020" )  ///
		     legend(off) ///
		     ytitle("Log real hourly wage (1984=2000=0)") xtitle("Entry cohort") ///
		 	 title("Log wages", size(medsmall)) ///
		 	 name(rw_l, replace)
   graph combine empl rw_l, title("Cohort effects on employment and wages:" "Balanced cohort-age panel estimates") ///
          saving("`output'/`dofile'_B.gph", replace)

if `doasproject'==1 {
  project, creates(`output'/`dofile'.gph)
  project, creates(`output'/`dofile'_B.gph)
}
    