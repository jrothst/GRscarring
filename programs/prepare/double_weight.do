****************************************************************************************
** Steps:
** 1) Compute the number of people born in b living in s at age a.
** 2) Compute the average age-22 UR that people born in b from cohort c are exposed to,
**    using the long-run migration shares from (1).
** 3) Compute the average of (2) for everyone from cohort c living in state s at age a,
****************************************************************************************
clear
cap project, doinfo
if _rc==0 {
  local pdir "`r(pdir)'"
  local dofile "`r(dofile)'"
  local sig {bind:{hi:[`dofile'.dta. RP : `dofile'.do, `c(current_date)']}}
  local doasproject=1
}
else {
  local pdir "~/GRscarring"
  local dofile "double_weight"
  local doasproject=0
}

set more off 
local prepare "`pdir'/programs/prepare"
local rawdata "`pdir'/rawdata"
local scratch "`pdir'/scratch"

if `doasproject' == 1 {
  project, uses("`scratch'/ipums_doubleweight.dta.gz")
  project, uses("`scratch'/statepop.dta")
  project, uses("`scratch'/unrate_national.dta")
  project, uses("`scratch'/unrate_state.dta")
}

** Read in Seasonally Adjusted Unemployment, 1976-2018
*import delimited "`rawdata'/la.data.3.AllStatesS.txt"
*gen fipsst=real(substr(series_id, 6,2))
*keep if fipsst<=56
*gen measure=real(substr(series_id, 20,1))
*keep if measure==3
*collapse (mean) value, by(fipsst year)
*rename value ur
*tempfile ur_state_s
*save `ur_state_s'
use `scratch'/statepop
collapse (sum) pop, by(year)
tempfile natlpop
save `natlpop'
// Make annual versions of unemployment rates
use `scratch'/unrate_national
isid yearmo
sort yearmo
gen year=yofd(dofm(yearmo))
bys year (yearmo): keep if _n==_N
keep year ur_nat_annual ur_nat_3yr_avg
label var ur_nat_annual "Unemployment rate (national)"
tempfile natlur
save `natlur'
merge 1:1 year using `natlpop', nogen assert(1 3)
tempfile popur_n
save `popur_n'
// Have UR 1947-2018, pop only 1970-2018
// Make state version of unemployment rate  
use `scratch'/unrate_state
isid fipsst yearmo
sort fipsst yearmo
gen year=yofd(dofm(yearmo))
bys fipsst year (yearmo): keep if _n==_N
keep fipsst year ur_st_annual ur_st_3yr_avg
label var ur_st_annual "Unemployment rate (state)"
tempfile stateur
save `stateur'
merge 1:1 fipsst year using `scratch'/statepop
merge m:1 year using `popur_n', keepusing(year ur_nat_annual ur_nat_3yr_avg) assert(2 3) keep(3) nogen
keep ur_st_annual ur_nat_annual year fipsst
tempfile popur_s
save `popur_s'


** Read in IPUMS data
*Years: 1980-2017 (decennial 1980, 90, 2000, then ACS since)
*       Note 1980 sample is 1/3 the size of 1990, and 2001-4 are much smaller than later.
*Ages: 3-97
** Drop if not born in US
** Drop if not college grad 
   ** Sasha: Unsure if this should be 81 or 101
   ** JR: Definitely 101. We want BA or more.
** Drop if under 22 or over 40
!zcat `scratch'/ipums_doubleweight.dta.gz > `scratch'/ipums_doubleweight.dta
use if bpl<=56 & age>=22 & age<=40 & educd>=101 & educd<. using "`scratch'/ipums_doubleweight.dta", clear
rename statefip fipsst
*Adjust weights to account for the fact that 1980 is standing in for 1980-85, 1990 for 1986-1995,
*and 2000 for 1996-2000
gen perwt_adj=perwt if year>2000
replace perwt_adj=perwt*10 if inlist(year, 1990, 2000)
replace perwt_adj=perwt*5 if year==1980

**Step 1: Compute the number of people born in b living in s at age a.
collapse (count) n_obs = perwt (rawsum) N_bsa=perwt, by(age fipsst bpl)  
tempfile migcounts
save `migcounts'
**Step 2: Compute the average age-22 UR that we expect people born in state b in cohort
*         c to be exposed to, given the long-run migration shares from (1).
use `migcounts', clear
keep if age==22
keep fipsst bpl N_bsa
joinby fipsst using `popur_s'
*joinby fipsst using `ur_state_s'
replace ur_st_annual = ur_nat_annual if missing(ur_st_annual)
isid fipsst bpl year
rename year year22
collapse (mean) UR22_bc=ur_st_annual [aw=N_bsa], by(bpl year22)
gen cohort=year22-22
keep bpl cohort UR22_bc
tempfile bpl_ur22
save `bpl_ur22'
 
**Step 3: Compute the average of (2) for everyone from cohort c living in state s at age a,
**       again using the long-run migration shares from (1).
use `bpl_ur22', clear
joinby bpl using `migcounts'
collapse (mean) UR22_dw=UR22_bc [aw=N_bsa], by(fipsst cohort age)
gen year=cohort+age
tempfile dw_ur22
save `dw_ur22'
 
**Check that this predicts the endogenous version 
use `popur_s'
* use `ur_state_s'
gen cohort=year-22
rename ur_st_annual ur22
merge 1:m fipsst cohort using `dw_ur22'
 
forvalues a=22/40 {
  di "First stage for age `a'"
  areg ur22 UR22_dw i.year if age==`a', a(fipsst)
}
reg ur22 UR22_dw i.year i.age i.cohort, cluster(fipsst)

** Create education variable
gen educ2 = 1

keep fipsst cohort age UR22_dw educ2

// Edit 12/26/12: Change the cohort definition 
replace cohort=cohort+22 if educ2==1
replace cohort=cohort+18 if educ2==0

save `scratch'/`dofile'.dta, replace

!rm `scratch'/ipums_doubleweight.dta

if `doasproject' == 1 {
  project, creates(`scratch'/`dofile'.dta)
}

