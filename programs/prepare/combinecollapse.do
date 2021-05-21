********************************************************************************

* combinecollapse.do
* Combines the collapsed bigcps, march, and org files, and merges on the unemployment rates
*
* Edit history:
*  JR, 4/10/18: Moved merge to unemployment rate here, from collapse_bigcps and collapse_march
*               Create a new "ur0" that uses state-level URs since 1976 and national URs previously.
*  JR, 4/16/18: Edited March variable list to match stripped-down version. Need to change this back later.
*  RY, 4/30/18: Edited to add on unemployment rate at age 18.    
*  JR, 4/30/18: Cleaned up program to loop rather than repeating. 
*  RY, 5/22/18: Added new topcoded annual earnings variable (to be used for main analysis)        
*  JR, 1/9/18:  Minor adjustments to use weights for those with non-missing earnings/wages.
*  NG, 8/28/2019: Minor adjustments to use 2019 data
*  JR, 4/24/2020: Fix education fraction calculation -- previously wildly wrong

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
	local dofile "combinecollapse"
	local doasproject=0
}

set more off
local rootdir "`pdir'"
local thisdir "`pdir'"
local scratch "`pdir'/scratch"

if `doasproject'==1 {
	project, uses("`scratch'/statepop.dta")
	project, uses("`scratch'/unrate_national.dta")
	project, uses("`scratch'/unrate_state.dta")
	project, uses("`scratch'/collapse_bigcps_yc.dta")
	project, uses("`scratch'/collapse_march_yc.dta")
	project, uses("`scratch'/collapse_org_yc.dta")
	project, uses("`scratch'/collapse_bigcps_yca5.dta")
	project, uses("`scratch'/collapse_march_yca5.dta")
	project, uses("`scratch'/collapse_org_yca5.dta")
	project, uses("`scratch'/collapse_bigcps_yca5s.dta")
	project, uses("`scratch'/collapse_march_yca5s.dta")
	project, uses("`scratch'/collapse_org_yca5s.dta")
	project, uses("`scratch'/collapse_bigcps_yca4.dta")
	project, uses("`scratch'/collapse_march_yca4.dta")
	project, uses("`scratch'/collapse_org_yca4.dta")
	project, uses("`scratch'/collapse_bigcps_yca4s.dta")
	project, uses("`scratch'/collapse_march_yca4s.dta")
	project, uses("`scratch'/collapse_org_yca4s.dta")
	project, uses("`scratch'/collapse_bigcps_yca2.dta")
	project, uses("`scratch'/collapse_march_yca2.dta")
	project, uses("`scratch'/collapse_org_yca2.dta")
	project, uses("`scratch'/collapse_bigcps_yca2s.dta")
	project, uses("`scratch'/collapse_march_yca2s.dta")
	project, uses("`scratch'/collapse_org_yca2s.dta")
}


local dvlist_cps "labfor empl unem married hourslw hourslw_pos uhours livewithprnt chld_pr educ_occup lives_spouse_oth"

*local dvlist_march "week_unemployed week_out_lf week_unempl_pos week_out_lf_pos unemployed_ever out_lf_lastyr"
*local dvlist_march "`dvlist_march' employed_ly ann_inc ann_ern ann_inc_pos ann_ern_pos log_ann_ern log_ann_inc"
*local dvlist_march "`dvlist_march' wkswork wkswork_pos hrswk_ly hrswk_ly_pos"
local dvlist_march "log_pearnval_tc_r pearnval_tc_r earn_r_pos earn_r_pos_tc log_earn_r_pos log_earn_r_pos_tc inc_r_pos inc_r_pos_tc log_inc_r_pos log_inc_r_pos_tc wkswork wkswork_pos tcwsval tcernval posinc posearn"
*local dvlist_march "pearnval_r pearnval_r_tc lpearnval_r lpearnval_r_tc posearn"
*local dvlist_org "paidhre rw rw_l rw_cepr rw_nber hours_jr wage_occup log_wk_ern"
*local dvlist_org "paidhre rw rw_l rw_nber wage_occup uhourse log_wk_ern"
local dvlist_org "rw rw_l rw_nber rw_nber_l rwage_occup usualhoursi"

*Prepare population and unemployment rates to merge on, at year-cohort and year-state-cohort levels
 // Make national version of population dataset
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
  // Have UR 1947-2017, pop only 1970-2017
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
  merge 1:1 fipsst year using `scratch'/statepop, nogen
  sort fipsst year
  bysort fipsst: replace state_name = state_name[1] if missing(state_name)
 merge m:1 year using `popur_n', keepusing(year ur_nat_annual ur_nat_3yr_avg) assert(2 3) keep(3) nogen

  tempfile popur_s
  save `popur_s'
 
 foreach set in yc yca5 yca5s yca4 yca4s yca2 yca2s yca2ss {
   if inlist("`set'", "yca5", "yca5s") local edvar educ5
   if inlist("`set'", "yca4", "yca4s") local edvar educ4
   if inlist("`set'", "yca2", "yca2s", "yca2ss") local edvar educ2
  
   if "`set'"=="yc" local ids "cohort year"
   if inlist("`set'", "yca5", "yca4", "yca2") local ids "cohort year `edvar'"
   if inlist("`set'", "yca5s", "yca4s", "yca2s") local ids "cohort year fipsst `edvar'"
   if inlist("`set'", "yca2ss") local ids "cohort year fipsst `edvar' sex"
   tempfile bigcps_`set' march_`set' org_`set'

   use `scratch'/collapse_bigcps_`set', clear
   rename wgt_composite bigcpswgt
   rename n_obs bigcps_`set'
   gen fromcps=1
   save `bigcps_`set''
   use `scratch'/collapse_march_`set', clear
   rename marsupwt marchwgt
   rename marsupwt_log_pearnval_tc_r marchwgt_log_pearnval_tc_r
   drop married 
   cap drop ed_*
   gen frommarch=1
   save `march_`set''
   use `scratch'/collapse_org_`set', clear
   gen fromorg=1
   save `org_`set''
   use `bigcps_`set''
   merge 1:1 `ids' using `march_`set'', nogen /*update*/
   merge 1:1 `ids' using `org_`set'', nogen 

   gen age=year-cohort
   // Compute education shares
    if inlist("`set'", "yca5", "yca4", "yca2", "yca5s", "yca4s", "yca2s", "yca2ss") {
      sort cohort year `edvar' 
      tempvar totsize edsize
      by cohort year: egen double `totsize'=total(bigcpswgt)
      by cohort year `edvar': egen double `edsize'=total(bigcpswgt)
      gen edfr_yc=`edsize'/`totsize'
      drop `totsize' `edsize'
    }
    if inlist("`set'", "yca5s", "yca4s", "yca2s", "yca2ss") {
      sort cohort year fipsst `edvar'
      tempvar totsize_st edsize_st
      by cohort year fipsst: egen double `totsize_st'=total(bigcpswgt)
      by cohort year fipsst `edvar': egen double `edsize_st'=total(bigcpswgt)
      gen edfr_ycs=`edsize_st'/`totsize_st'
      drop `totsize_st' `edsize_st'
    }

   // Merge on population and UR
   cap drop ur* 
   cap drop pop
   if inlist("`set'", "yc", "yca5", "yca4", "yca2") { 
    // merge on national UR
     merge m:1 year using `popur_n', assert(2 3) keep(3) nogen 
     rename ur_nat_annual ur_nat
     // And merge on age-22 UR 
      rename year origyr
      gen year=cohort+22
      merge m:1 year using `popur_n', keepusing(year ur_nat_annual) assert(1 3) nogen
      rename ur_nat_annual ur0_nat_22
      label var ur0_nat_22 "UR (natl) at age 22"
      drop year 
     // And merge on age-18 UR  
      gen year=cohort+18
      merge m:1 year using `popur_n', keepusing(year ur_nat_annual) assert(1 3) nogen
      rename ur_nat_annual ur0_nat_18
      label var ur0_nat_18 "UR (natl) at age 18"
      drop year 
     rename origyr year
   //Missing ur0_nat for 1899-1924 and 1996-2001 birth cohorts 
   // RY, 4/30/18, labels made above
   }
   else { 
     // merge on state and national UR
     // Merge on population and UR
      merge m:1 fipsst year using `popur_s', assert(2 3) keep(3) nogen
      rename ur_nat_annual ur_nat
      rename ur_st_annual ur_st
     // And merge on age-22 UR
      rename year origyr
      gen year=cohort+22
      merge m:1 fipsst year using `popur_s', keepusing(year ur_nat_annual ur_st_annual) assert(1 3) nogen
      rename ur_nat_annual ur0_nat_22  
      label var ur0_nat_22 "UR (natl) at age 22"
      rename ur_st_annual ur0_st_22
      label var ur0_st_22 "UR (state) at age 22"  
      drop year
     // And merge on age-18 UR  
      gen year=cohort+18
      merge m:1 fipsst year using `popur_s', keepusing(year ur_nat_annual ur_st_annual) assert(1 3) nogen
      rename ur_nat_annual ur0_nat_18
      label var ur0_nat_18 "UR (natl) at age 18"
      rename ur_st_annual ur0_st_18
      label var ur0_st_18 "UR (state) at age 18"  
     //Missing UR from pre 1969, post 2017.
     drop year
     rename origyr year
     // Make a consolidated age-22 UR that uses national rate before 1976 and state rate before
     // This makes it possible to include earlier cohorts in the analyses that control for the age-22 UR.
      gen ur0_22=ur0_st_22
      assert ur0_22==. if cohort<1954
      replace ur0_22=ur0_nat_22 if cohort<1954
      label var ur0_22 "Age-22 UR (nat pre-1976, state 1976-)"
     //Make a consolidated age-18 UR that uses national rate before 1972 and state rate before
      gen ur0_18=ur0_st_18
      assert ur0_18==. if cohort<1958
      replace ur0_18=ur0_nat_18 if cohort<1958
      label var ur0_18 "Age-18 UR (nat pre-1972, state 1972-)"
   }
  rename cohort birthcohort
  save `scratch'/combinecollapse_`set', replace

 }   

 
if `doasproject'==1 {
  project, creates(`scratch'/combinecollapse_yc.dta)
  project, creates(`scratch'/combinecollapse_yca5.dta)
  project, creates(`scratch'/combinecollapse_yca5s.dta)
  project, creates(`scratch'/combinecollapse_yca4.dta)
  project, creates(`scratch'/combinecollapse_yca4s.dta)
  project, creates(`scratch'/combinecollapse_yca2.dta)
  project, creates(`scratch'/combinecollapse_yca2s.dta)
  project, creates(`scratch'/combinecollapse_yca2ss.dta)
}
