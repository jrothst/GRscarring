***************************************************************************************************************
* fig_atcfx_time.do
*
* Make plot of time effects from A-T-C decomposition
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
	local dofile "fig_atcfx_time"
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

	*Get time effects from the basic A-T-C decomposition (model B - not extrapolated).
	use if inlist(model, "mB1b") using `scratch'/runatc_coeffs, clear
	keep if ivartype=="FV" & fvname=="year" 
	rename fvval year
	gen keep="A"
	foreach v in `depvars' {
	  replace keep="B" if depvar=="`v'"
	}
	keep if keep=="B"
	drop keep

	gen month=ym(year, 7)
	su month, meanonly
	format month %tm
	local fmonth=r(min)
	local lmonth=r(max)
	append using `scratch'/recessionlist
	keep if recession==. | (month>=`fmonth'-6 & month<=`lmonth'+5) | month==.
	tempfile base
	save `base', replace

	replace b=b*100 if depvar=="empl"
	gen zero=0

	twoway area recession month if recession<. & month>=186, yaxis(2) ytitle("", axis(2)) ylabel(none, axis(2)) color(gs13) || ///
	       line b month if depvar=="empl" & model=="mB1b", yaxis(1) lstyle(p1) || ///
           line zero month if model=="mB1b" & depvar=="empl", lpattern(dot) lcolor(black) || ///
			, legend(off) ///
			ytitle("Employment rate in % (2007=0)") xtitle("Year") ///
			xlabel(246 "1980" 306 "1985" 366 "1990" 426 "1995" 486 "2000" 546 "2005" 606 "2010" 666 "2015" 726 "2020")  ///
			title("Year effects on employment" "from age-time-cohort decomposition") ///
			saving("`output'/`dofile'.gph", replace)   

if `doasproject'==1 project, creates(`output'/`dofile'.gph)
 