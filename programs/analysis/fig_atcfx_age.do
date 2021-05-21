***************************************************************************************************************
* fig_atcfx_age.do
*
* Make plot of age effects from A-T-C decomposition
* Based on fig_atcfx.do, 1/21/2020
*


***************************************************************************************************************  
clear
cap project, doinfo
//cap notaproject
if _rc==0 {
	local pdir "`r(pdir)'"						  	    // the project's main dir.
	local dofile "`r(dofile)'"						    // do-file's stub name
	local sig {bind:{hi:[`dofile'.dta. RP : `dofile'.do, `c(current_date)']}}	// a signature in notes
	local doasproject=1
}
else {
	local pdir "~/GRscarring"
	local dofile "fig_atcfx_age"
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

	*Get age effects from the basic A-T-C decomposition (model B - not extrapolated).
	use if inlist(model, "mB1b") using `scratch'/runatc_coeffs, clear
	keep if ivartype=="FV" & fvname=="exper" 
	gen age=fvval+22
	gen keep="A"
	foreach v in `depvars' {
	  replace keep="B" if depvar=="`v'"
	}
	keep if keep=="B"
	drop keep

	tempfile base
	save `base', replace

	replace b=b*100 if depvar=="empl"
	gen zero=0

	twoway line b age if depvar=="empl" & model=="mB1b", yaxis(1) lstyle(p1) || ///
           line zero age if model=="mB1b" & depvar=="empl", lpattern(dot) lcolor(black) || ///
			, legend(off) ///
			ytitle("Employment rate in % (age 32=0)") xtitle("Age") ///
		    legend(off) xlabel(22 25 30 35 40) ///
			title("Age effects on employment" "from age-time-cohort decomposition") ///
			saving("`output'/`dofile'.gph", replace)   

 if `doasproject'==1 project, creates(`output'/`dofile'.gph)
 