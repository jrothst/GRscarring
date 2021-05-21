***************************************************************************************************************
* fig_familyformation.do
* JR, 4/24/2020
* based on fig_atcfx.do
*

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
	local dofile "fig_familyformation"
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
	project, uses(`scratch'/runatc_coeffs.dta)
}

use `scratch'/combinecollapse_yca2
keep if educ2==1

replace chld_pr=. if chld_pr<0.02
foreach v of varlist chld_pr married livewithprnt lives_spouse_oth {
  replace `v'=`v'*100
}
gen entrycohort=birthcohort+22
sort age entrycohort

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
	 drop if month>ym(2018,12)
	 //drop if depvar=="rw_l" & month>ym(2018,12)
	 //drop if depvar=="log_pearnval_tc_r" & month>=ym(2016,7)
	 //drop if !inlist(depvar, "empl", "rw_l", "log_pearnval_tc_r") & !inlist(model,"recession", "means")

    gen altrecession=recession*50
    gen zero=0 if model=="recession"

    twoway area altrecession month if model=="recession", color(gs13) base(0) || ///
           line chld_pr month if age==24, lstyle(p1) lpattern(shortdash) || ///
           line chld_pr month if age==26, lstyle(p2) lpattern(dash) || ///
           line chld_pr month if age==28, lstyle(p3) lpattern(longdash) || ///
           line chld_pr month if age==30, lstyle(p4) lpattern(solid) || ///
  		   , xlabel( 126 "1970" 246 "1980" 366 "1990" 486 "2000" 606 "2010" 726 "2020" )  ///
		     legend(off) ///
		     ytitle("Presence of children (%)") xtitle("Entry cohort") ///
		 	 title("Children", size(medsmall))  ///
  		     name(children, replace) nodraw
  	replace altrecession=recession*40	     
    twoway area altrecession month if model=="recession", color(gs13) base(0) || ///
           line livewithprnt month if age==24, lstyle(p1) lpattern(shortdash) || ///
           line livewithprnt month if age==26, lstyle(p2) lpattern(dash) || ///
           line livewithprnt month if age==28, lstyle(p3) lpattern(longdash) || ///
           line livewithprnt month if age==30, lstyle(p4) lpattern(solid) || ///
  		   , xlabel( 126 "1970" 246 "1980" 366 "1990" 486 "2000" 606 "2010" 726 "2020" )  ///
		     legend(off) ///
		     ytitle("Lives with parent (%)") xtitle("Entry cohort") ///
		 	 title("Live with parent", size(medsmall)) nodraw ///
  		     name(livewithprnt, replace)
  	replace altrecession=recession*80	     
    twoway area altrecession month if model=="recession", color(gs13) base(0) || ///
           line lives_spouse_oth month if age==24, lstyle(p1) lpattern(shortdash) || ///
           line lives_spouse_oth month if age==26, lstyle(p2) lpattern(dash) || ///
           line lives_spouse_oth month if age==28, lstyle(p3) lpattern(longdash) || ///
           line lives_spouse_oth month if age==30, lstyle(p4) lpattern(solid) || ///
  		   , xlabel( 126 "1970" 246 "1980" 366 "1990" 486 "2000" 606 "2010" 726 "2020" )  ///
		     legend(order(2 "Age 24" 3 "Age 26" 4 "Age 28" 5 "Age 30") ring(0) pos(6)) ///
		     ytitle("Lives with partner (%)") xtitle("Entry cohort") ///
		 	 title("Live-in partnership", size(medsmall)) nodraw ///
  		     name(lives_spouse_oth, replace)
    twoway area altrecession month if model=="recession", color(gs13) base(0) || ///
           line married month if age==24, lstyle(p1) lpattern(shortdash) || ///
           line married month if age==26, lstyle(p2) lpattern(dash) || ///
           line married month if age==28, lstyle(p3) lpattern(longdash) || ///
           line married month if age==30, lstyle(p4) lpattern(solid) || ///
  		   , xlabel( 126 "1970" 246 "1980" 366 "1990" 486 "2000" 606 "2010" 726 "2020" )  ///
		     legend(off) ///
		     ytitle("Married (%)") xtitle("Entry cohort") ///
		 	 title("Marriage", size(medsmall))  ///
  		     name(married, replace) nodraw
    graph combine married lives_spouse_oth livewithprnt children, ///
          title("Family formation, by cohort and age") ///
          saving("`output'/`dofile'.gph", replace)



if `doasproject'==1 {
  project, creates(`output'/`dofile'.gph)
}
    