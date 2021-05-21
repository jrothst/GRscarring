*Program to compute simple, unadjusted cohort mean outcomes
*
* Jesse Rothstein, 4/2/2020

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
	local dofile "simplecohortmeans"
	local doasproject=0
}

set more off
eststo clear
estimates clear
local rootdir "`pdir'"
local thisdir "`pdir'"

local prepdata "`pdir'/scratch"
local rawdata "`pdir'/rawdata"
local output "`pdir'/results"

/*
local depvarscps "empl unem labfor married hourslw hourslw_pos uhours livewithprnt chld_pr educ_occup lives_spouse_oth" 
local depvarsmar "earn_r_pos earn_r_pos_tc log_earn_r_pos log_earn_r_pos_tc inc_r_pos inc_r_pos_tc log_inc_r_pos log_inc_r_pos_tc wkswork wkswork_pos"
local depvarsorg "paidhre rw rw_l rw_nber uhourse wage_occup log_wk_ern"
*/
local depvarscps "empl"
local depvarsmar "log_pearnval_tc_r"
local depvarsorg "rw_l"

if `doasproject'==1 {
	project, uses("`prepdata'/combinecollapse_yca2s.dta")
}


  use `prepdata'/combinecollapse_yca2s, clear
  cap drop _*
  keep if age<=40 
  keep if (educ2==1 & age>=22) | (educ2==0 & age>=18)
  keep if marchwgt<. | orgwgt<. | bigcpswgt<.
  // Drop 2019 data, which is not yet complete
  drop if year==2019
  // Drop the cohorts just entering the sample in 2018, for whom UR0 is missing.
  // edit, 9/2/19: Dont need this now that we have UR for 2018
*drop if year==2018 & ((educ2==0 & age==18) | (educ2==1 & age==22))

// NG 01/20/2020: Edit, new name for the cohort variable 
* For clarity we define birthcohort and entrycohort and we redefine the cohort definition
*gen birthcohort=cohort
*label var birthcohort "Year of Birth"
gen entrycohort=. 
replace entrycohort=birthcohort+22 if educ2==1
replace entrycohort=birthcohort+18 if educ2==0
label var entrycohort "Year of entry on the labor market, depending on level of education"
cap drop cohort 

tempfile base 
save `base'

local depvarscps "empl"
local depvarsmar "log_pearnval_tc_r"
local depvarsorg "rw_l"

tempfile bigcps march org
collapse (mean) `depvarscps' [aw=bigcpswgt], by(entrycohort birthcohort educ2)
save `bigcps'
use `base'
collapse (mean) `depvarsmar' [aw=marchwgt], by(entrycohort educ2)
save `march'
use `base'
collapse (mean) `depvarsorg' [aw=orgwgt], by(entrycohort educ2)
save `org'
use `bigcps', clear
merge 1:1 entrycohort educ2 using `march', nogen
merge 1:1 entrycohort educ2 using `org', nogen

save `prepdata'/`dofile'.dta, replace
 if `doasproject'==1 {
	project, creates(`prepdata'/`dofile'.dta)
 }
 
