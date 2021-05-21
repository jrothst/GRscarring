* Figure 1 -Employment and unemployment. Published UR, and prime-age non-employment rate 

*Modification history:
* 4/14/2020: Exclude 2020
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
	local dofile "fig_ur"
	local doasproject=0
}

set more off
local rootdir "`pdir'"
local thisdir "`pdir'"

local scratch "`pdir'/scratch"
local rawdata "`pdir'/rawdata"
local output "`pdir'/results"

if `doasproject'==1 {
	project, uses("`scratch'/unrate_national.dta")
	project, uses("`scratch'/extractcps.dta.gz")
}

set scheme s1color

** Create Prime Age  Non Employment 
!zcat `scratch'/extractcps.dta.gz > `scratch'/extractcps.dta 
use`scratch'/extractcps.dta
use age empl yearmo wgt_composite using `scratch'/extractcps.dta
gen prime=1 if age>24 & age<55
keep if prime==1
collapse (mean) empl [aw=wgt_composite], by(yearmo)
gen nonemploy_r = (1 - empl)


*Simple seasonal adjustment
gen year=year(dofm(yearmo))
gen mon=month(dofm(yearmo))
foreach v of varlist  nonemploy_r {
  areg `v' i.year, a(mon)
  local int=_b[_cons]
  predict monfx, d
  gen `v'_sa=`v'-monfx
  drop monfx
}

* 7 months Smoothing 	     
tsset yearmo
foreach v of varlist nonemploy_r_sa {
  gen     `v'_m7=100*((4*`v' + 3*L.`v' + 2*L2.`v' + 1*L3.`v'+ 3*F.`v'+ 2*F2.`v' + 1*F3.`v')/16)
  replace `v'_m7=100*((4*`v' + 3*L.`v' + 2*L2.`v' + 1*L3.`v')/10) if F.`v'==.
  replace `v'_m7=100*((4*`v' + 3*F.`v' + 2*F2.`v' + 1*F3.`v')/10) if L.`v'==.
}

tempfile nonempl
save `nonempl'

** Merge to first dataset 
merge 1:1 yearmo using `scratch'/unrate_national, nogen

keep if yearmo>=ym(1981, 7)
gen recession=(yearmo>=ym(1981,7) & yearmo<=ym(1982,11)) | (yearmo>=ym(1990,7) & yearmo<=ym(1991,3)) | ///
              (yearmo>=ym(2001,3) & yearmo<=ym(2001,11)) | (yearmo>=ym(2007,12) & yearmo<=ym(2009,6))

keep if yearmo>=ym(1989,1)
keep if yearmo<=ym(2019,12)

gen nonemploy_r_copy=nonemploy_r_sa_m7-18
gen altrecession=recession*8

** Figure 1 - Figure 1. Employment and unemployment. Published UR, and prime-age non-employment rate 
twoway area altrecession yearmo, yaxis(1) color(gs13)  || ///
 line  nonemploy_r_copy yearmo, yaxis(1) ytitle("Non-employment rate (seasonally adjusted)", height(4) axis(1)) ylabel(0 "18" 2 "20" 4 "22" 6 "24" 8 "26", axis(1))  || ///
 line  ur_nat_s yearmo, lpattern(dash) yaxis(2) ytitle("Unemployment rate (seasonally adjusted)", axis(2)) ylabel(0 (2) 10, axis(2)) || ///
, xlabel(366 "1990" 426 "1995" 486 "2000" 546 "2005" 606 "2010" 666 "2015" 726 "2020") ///
 xtitle("")  legend(order(2 "Non-employment (l. axis)" 3 "Unemployment rate (r. axis)") size(small)) title(" Unemployment and prime-age non-employment", size(medsmall))  ///
  saving("`output'/fig_ur.gph", replace)
  
save `scratch'/fig_ur.dta, replace
! rm `scratch'/extractcps.dta

  
 if `doasproject'==1 {
	project, creates(`output'/fig_ur.gph)
	project, creates(`scratch'/fig_ur.dta)
} 
