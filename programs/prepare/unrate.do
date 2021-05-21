**************************************************************************
* unrate.do
* Makes time series of national unemployment rate and panel of state UR.
*
*Updated:
* JR, 4/30/18: Update input data, and cut things off at end of 2017
* NR, 9/10/18: Update input data, data extends through July 2018
* NR, 4/02/19: Update input data, extend data through 2018 - drop if 2019
* NG, 08/22/19: Update input data, extend data through July 2019
* JR, 4/14/2020, with data through 3/2020			

**************************************************************************

cap project, doinfo
if _rc==0 {
   local pdir "`r(pdir)'"						      // the project's main dir.
   local dofile "`r(dofile)'"						      // do-file's stub name
   local sig {bind:{hi:[`dofile'.dta. RP : `dofile'.do, `c(current_date)']}}  // a signature in notes
   local doasproject=1
}
else {
   local pdir "~/GRscarring"
   local dofile "unrate"
   local doasproject=0
}

set more off
local rootdir "`pdir'"
local thisdir "`pdir'"

local prepdata "`pdir'/scratch"
local rawdata "`pdir'/rawdata"
local output "`pdir'/results"

***************************************************************************************************************
***************************************************************************************************************
*** 0.1 LOAD NATIONAL UNEMPLOYMENT DATA ***
*******************************************

* National - monthly
* Downloaded from https://data.bls.gov/cgi-bin/srgate
* From BLS website -- series LNS14000000 :
* All years, original data value, CSV
* From BLS website -- series LNU04000000 :
* All years, original data value, CSV, include annual averages
* Most recent download 8/25/2019
if `doasproject'==1 project, original(`rawdata'/lns14000000.csv)
import delimited using "`rawdata'/lns14000000.csv" , clear varnames(1)
rename (jan-dec) ur#, addnumber
foreach v of varlist ur* {
  destring `v', replace
}
reshape long ur, i(year) j(month)
gen yearmo=ym(year, month)
keep yearmo ur
drop if ur==.
rename ur ur_nat_s
tempfile ur_s
save `ur_s'


if `doasproject'==1 project, original(`rawdata'/lnu04000000.csv)
import delimited using "`rawdata'/lnu04000000.csv" , clear varnames(1)
rename (jan-dec) ur#, addnumber
foreach v of varlist ur* annual {
  destring `v', replace
}
reshape long ur, i(year) j(month)
gen yearmo=ym(year, month)
keep yearmo ur annual
drop if ur==. & annual==.
rename ur ur_nat_u
rename annual ur_nat_annual
tempfile ur_u
save `ur_u'
merge 1:1 yearmo using `ur_s', nogen
tempfile ur_u_s
save `ur_u_s'

**** LOAD IN NATIONAL EMPLOYMENT-POPULATION RATIO (EPR) *****
* Downloaded from https://data.bls.gov/cgi-bin/srgate
* Most recent download 25/08/2019
* Series Id:	LNS12300000				
* Seasonally Adjusted					
* Series title:	(Seas) Employment-Population Ratio				
* Labor force status:	Employment-population ratio				
* Type of data:	Percent or rate				
* Age:	16 years and over				
* Years:1948 to 2019
*

if `doasproject'==1 project, original(`rawdata'/lns12300000.csv)
import delimited using "`rawdata'/lns12300000.csv" , clear varnames(1)
*drop if year==2018
rename (jan-dec) epr#, addnumber
foreach v of varlist epr* {
  destring `v', replace
}
reshape long epr, i(year) j(month)
gen yearmo=ym(year, month)
keep yearmo epr
drop if epr==.
rename epr epr_nat_s
tempfile epr_s
save `epr_s'
merge 1:1 yearmo using `ur_u_s', nogen
format yearmo %tm

* Employment to Population Ration
* current and 2007 peak
di epr_nat_s[_N]
sum epr_nat_s if yofd(dofm(yearmo)) == 2007

* New generate 3 year rolling average for unemployment rate - 10/26/2017
gen year=yofd(dofm(yearmo))
gen ur_nat_3yr_avg = ((ur_nat_annual + ur_nat_annual[_n+12] + ur_nat_annual[_n+24])/3) if year<=2014
drop year
label var ur_nat_3yr_avg "3 year average unemployment rate"

save `prepdata'/`dofile'_national.dta, replace
if `doasproject'==1 project, creates(`prepdata'/`dofile'_national.dta)


*** LOAD STATE UNEMPLOYMENT DATA ***

**Downloaded from https://download.bls.gov/pub/time.series/la/
**Most recent download 4/14/20
**Footnote codes:
**footnote_code	footnote_text
**A	Area boundaries do not reflect official OMB definitions.	
**B	Reflects revised population controls, model reestimation, and new seasonal adjustment.	
**C	Corrected.	
**D	Reflects revised population controls and model reestimation.	
**N	Not available.	
**P	Preliminary.	
**R	Data were subject to revision on April 21, 2017.	
**S	Reflects new population controls and revised seasonal adjustment.	
**T	Reflects new population controls.
*****

if `doasproject'==1 project, original(`rawdata'/la.data.3.AllStatesS.txt)
import delimited `rawdata'/la.data.3.AllStatesS.txt, clear
*drop if year==2019
gen fipsst=real(substr(series_id, 6,2))
keep if fipsst<=56
gen measure=real(substr(series_id, 20,1))
keep if measure==3
drop series_id measure
gen mo=real(substr(period,2,.))
gen yearmo=ym(year, mo)
format yearmo %tm
drop year mo period
rename value ur_st_s
rename footnote_codes fn_ur_st_s
tempfile ur_state_s
save `ur_state_s'

if `doasproject'==1 project, original(`rawdata'/la.data.2.AllStatesU.txt)
import delimited `rawdata'/la.data.2.AllStatesU.txt, clear
*drop if year==2019
gen fipsst=real(substr(series_id, 6,2))
keep if fipsst<=56
gen measure=real(substr(series_id, 20,1))
keep if measure==3
drop series_id measure
gsort fipsst year -period
by fipsst year: assert period[1]=="M13" | year==2020
by fipsst year: gen ur_st_annual=value[1] if period[1]=="M13"
drop if period=="M13"
gen mo=real(substr(period,2,.))
gen yearmo=ym(year, mo)
format yearmo %tm
drop year mo period
rename value ur_st_u
rename footnote_codes fn_ur_st_u
merge 1:1 fipsst yearmo using `ur_state_s', assert(3) nogen

* New generate 3 year rolling average for unemployment rate - 10/26/2017
gen year=yofd(dofm(yearmo))
sort fipsst year
gen ur_st_3yr_avg = ((ur_st_annual + ur_st_annual[_n+12] + ur_st_annual[_n+24])/3) if year<=2014
drop year
label var ur_st_3yr_avg "3 year average unemployment rate (state)"

save `prepdata'/`dofile'_state.dta, replace
if `doasproject'==1 project, creates(`prepdata'/`dofile'_state.dta)


