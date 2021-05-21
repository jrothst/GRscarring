***************************************************************************************************************

* statepop.do
* Makes panel of state population
*
* Source data:
*  1) http://www.nber.org/data/census-intercensal-county-population.html 
*     (through 2009)
*  2) https://www2.census.gov/programs-surveys/popest/tables/2010-2019/state/totals/nst-est2017-01.xlsx
*      (2010-2019)
*  (Old: 3) Linear extrapolation to end of series)
*
*Updates:
* JR, 4/30/18: Add 2017 data -- no need to extrapolate.
* NR, 9/12/18: Fixed code so that DC population data correctly populates
* JR, 4/14/20: Update through 2019 data
      
cap project, doinfo
if _rc==0 {
   local pdir "`r(pdir)'"						  	// the project's main dir.
   local dofile "`r(dofile)'"						        // do-file's stub name
   local sig {bind:{hi:[`dofile'.dta. RP : `dofile'.do, `c(current_date)']}}	// a signature in notes
   local doasproject=1
}
else {
   local pdir "~/GRscarring"
   local dofile "statepop"
   local doasproject=0
}

set more off
local rootdir "`pdir'"
local thisdir "`pdir'"

local prepdata "`pdir'/scratch"
local rawdata "`pdir'/rawdata"
local output "`pdir'/results"

********************************************
********************************************
** 0.2 LOAD STATE/COUNTY POPULATION DATA ***
********************************************

* 1970-2014 (following code from cleanstatebudget.do, by Audrey Tiew, from LRS 2016 project):

******************************************************************************
* Filling in state population counts based on NBER data                      *
* http://www.nber.org/data/census-intercensal-county-population.html         *
******************************************************************************

* Population counts based on counties
if `doasproject'==1 project, original("`rawdata'/county_population.dta")
use "`rawdata'/county_population.dta", clear

* Using only intercensenal estimates (and the same version of each)
drop pop19904 pop20104 base20104

* Fix DC:
sort state_fips county_fips
bysort state_fips: gen id = _n
forvalues year=1970/2009 {
	bysort state_fips: replace pop`year' = pop`year'[1] if state_fips==11
}

* Drop id
drop id

* Drop state averages (don't have for every year but do for counties)
drop if state_name==county_name & areaname==state_name

* Trimming strings
foreach var of varlist fips state_name county_name fipsst {
	replace `var'=trim(`var')
}


*Code below confirms that each of the 2 observations for the same county has population for different years
*bysort fips: gen count=_n
*tab count
*drop state_fips county_fips areaname state_name county_name fipsst fipsco region division base20104
*reshape long pop, i(fips count) j(year)
*reshape wide pop, i(fips year) j(count)
*count if pop1!=. & pop2!=.

collapse (sum) pop* (firstnm) state_name, by(fipsst)

*checking ratios between years
gen max_ratio_yr = pop1971/pop1970
forvalues yr=1972/2014 {
	local yrbf=`yr'-1
	replace max_ratio_yr = pop`yr'/pop`yrbf' if pop`yr'/pop`yrbf'>max_ratio_yr
}

sum max_ratio_yr
*the largest year to year change is about 10%
drop max_ratio_yr

reshape long pop, i(fipsst state_name) j(year)

sort year fipsst
replace state_name=strupper(state_name)
rename state_name state

tempfile state_pop
save `state_pop'



*Replace 2010-2018 data with the most recent
*Downloaded from https://www.census.gov/data/datasets/time-series/demo/popest/2010s-state-total.html
*on 4/2/2019
* Update: From https://www2.census.gov/programs-surveys/popest/tables/2010-2019/state/totals/nst-est2019-01.xlsx
*on 4/14/2020, then saved as csv.
if `doasproject'==1 project, original("`rawdata'/nst-est2018-01.csv")

import delimited using "`rawdata'/nst-est2018-01.csv", clear varnames(4)
drop census estimatesbase
forvalues i=4/12 {
	local j=`i'+2006
	ren v`i' pop`j' 
}
ren v1 state_name
replace state_name=subinstr(state_name,".","",1)
tab state_name
drop if state_name=="Midwest"
drop if state_name=="Northeast"
drop if state_name=="United States"
drop if state_name=="South"
drop if state_name=="West"
drop if state_name=="Puerto Rico"

destring pop*, replace ignore(",")

*Extrapolate to 2017.
*NOTE: THIS NEEDS TO BE CHANGED WHEN WE GET MORE CURRENT DATA
*gen pop2017=(pop2016/pop2015)*pop2016
*gen pop2018=(pop2017/pop2016)*pop2017

reshape long pop, i(state_name) j(year)

keep if inlist(year, 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017, 2018, 2019)
tab state_name if pop==.
drop if pop==.
*destring pop, replace ignore(",")
tempfile state_pop_2010s
save `state_pop_2010s'

use `state_pop'
drop if year>=2010
append using `state_pop_2010s'


replace state=strupper(state_name) if state==""
sort state fipsst
by state: replace fipsst=fipsst[_N] if fipsst==""
assert fipsst!=""
drop state_name
destring fipsst, replace
ren state state_name
replace state_name=strproper(state_name)
replace state_name="District of Columbia" if state_name=="District Of Columbia"
isid state_name year

save `prepdata'/`dofile'.dta, replace
if `doasproject'==1 project, creates(`prepdata'/`dofile'.dta)

***************************************************************************************************************
***************************************************************************************************************
