/****************************************************************************
Program: collapse_march_v3.do
Author: Rachel Young
Date: 4/17/2018

Description: Program creates the variables listed below from the March CPS
- Annual earnings (pearnval)
- Annual personal income (ptotval)
- Number of weeks worked
- An indicator for positive weeks worked.
- Versions of annual earnings and income that 
	(a) set zeros/negatives to missing, 
	(b) are adjusted for inflation, and 
	(c) are logged.
	
Source: This program combines the previous prepare_march.do (9/21/2017) and collapse_march.do (3/21/18)

modified RY 4/25/2018, Revised the collapse so that it has two education groups 
modified JR 4/30/2018: Use 2, 4, and 5 education groups.
                       Remove merge to unemployment rate (now in combinecollapse)
modified RY 5/22/2018: Added new topcoded annual earnings variable (to be used for main analysis)
modified NR 9/29/2018: Added new weight (marsupwt_retro) when merging `set'_retro
to contemporary `set' dataset
modified JR 1/9/2019:  Reduce variables to keep, and generate new weight that is limited
                       to those with non-missing earnings.
****************************************************************************/

cap project, doinfo
if _rc==0 {
   local pdir "`r(pdir)'"						     // the project's main dir.
   local dofile "`r(dofile)'"						     // do-file's stub name
   local sig {bind:{hi:[`dofile'.dta. RP : `dofile'.do, `c(current_date)']}} // a signature in notes
   local doasproject=1
}
else {
    local pdir "~/GRscarring"
    local dofile "collapse_march"
    local doasproject=0
}

set more off
local rootdir "`pdir'"
local thisdir "`pdir'"

local prepdata "`pdir'/scratch"
local rawdata "`pdir'/rawdata"
local output "`pdir'/results"


if `doasproject'==1 {
  project, uses(`prepdata'/clean_compile_march.dta.gz)
}


*************************************
** 0 LOAD STACKED MARCH CPS DATA **    
*************************************  

*if `doasproject'==1 project, uses(`prepdata'/clean_compile_march_v1.dta.gz)

! zcat `prepdata'/clean_compile_march.dta.gz > `prepdata'/clean_compile_march.dta
use `prepdata'/clean_compile_march.dta, clear
! rm `prepdata'/clean_compile_march.dta


************************************************
*********** 1 SAMPLE RESTRICTIONS *************
************************************************

keep if age>15 & age<81

*******************************************
******** 2 CREATE COLLAPSE VARIABLES ******
*******************************************

***** Cohort ****
gen cohort=(year-age)

****** Married *****
gen married=(a_maritl<4)

***** State (fipsst) *****
 decode state, gen(state_name)
 drop if state==. /* only 4 observations */
 * Merge to population
 merge m:1 state_name year using `prepdata'/statepop, assert(2 3) keep(3) keepusing(fipsst)

***** Education (educ5) ****
*  HS completion
*  Some college
*  BA+
*  Yrs educ
tab a_hga, m
gen ed_yrs=a_hga if year<=1991
replace ed_yrs=0 if a_hga==31
replace ed_yrs=4 if a_hga==32
replace ed_yrs=6 if a_hga==33
replace ed_yrs=8 if a_hga==34
replace ed_yrs=a_hga-26 if inrange(a_hga, 35,38)
replace ed_yrs=12 if a_hga==39
replace ed_yrs=13 if a_hga==40
replace ed_yrs=14 if a_hga==41
replace ed_yrs=14 if a_hga==42
replace ed_yrs=16 if a_hga==43
replace ed_yrs=18 if a_hga==44
replace ed_yrs=19 if a_hga==45
replace ed_yrs=19 if a_hga==46

gen educ5=1 
replace educ5=2 if ed_hs==1
replace educ5=3 if ed_scol==1
replace educ5=4 if ed_ba==1
replace educ5=5 if ed_grad==1
label define attain_l 1 "LTHS" 2 "HS" 3 "Some col." 4 "BA" 5 "MA+"
label values educ5 attain_l

*gen byte ed_scol_less=(educ5==1 | educ5==2 | educ5==3) if educ5<.
*gen byte ed_ba_more=(educ5==4 | educ5==5) if educ5<.
gen byte educ2=(inlist(educ5, 4, 5)) if educ5<.
recode educ5 (1=1) (2=2) (3=3) (4 5=4), gen(educ4)

******** Sex ******
gen sex = 2
replace sex = 1 if a_sex == 1
replace sex = 0 if a_sex == 2
tab sex

***********************************************
******** 3 CREATE VARIABLES FOR ANALYSIS ******
***********************************************

***** Annual Earnings ******

* Annual earnings (ann_ern)
gen earn = pearnval

* Inflation adjusted annual earnings (ann_ern_r)
gen earn_r = pearnval_r

* Setting 0's and negatives to missing (pearnval and pearnval_r)
 gen posearn=(pearnval>0)
 gen earn_pos=pearnval
 replace earn_pos=. if posearn==0
 
 gen posearn_r=(pearnval_r>0)
 gen earn_r_pos=pearnval_r
 replace earn_r_pos=. if posearn_r==0
 
  //Another deals with topcoding -- censor at double the 90th percentile. (The 99th percentile 
 //  ranges from 2* to 5* the 90th percentile over time, with some of that variation apparently
 //  due to topcoding not reality.
 // TC dumm variable is tcernval
 levelsof year
 gen earn_r_pos_tc=earn_r
 foreach y of numlist `r(levels)' {
   di "Real personal earnings distribution, `y'"
   qui su earn_r_pos if earn_r_pos>0 & year==`y' [aw=marsupwt], d
   local p90=r(p90)
   local p99=r(p99)
   di "Ratio of 99th percentile to 90th percentile in `y' is " `p99'/`p90'
   replace earn_r_pos_tc=2*`p90' if year==`y' & earn_r_pos>2*`p90' & earn_r_pos<.
 }
 
* Annual earnings logged (log_ann_ern_r)
 gen log_earn_pos=ln(earn_pos)
 gen log_earn_r_pos=ln(earn_r_pos)
 gen log_earn_r_pos_tc=ln(earn_r_pos_tc)
 gen log_pearnval_tc_r=ln(pearnval_tc_r)
 
local ernvars "log_pearnval_tc_r pearnval_tc_r earn earn_r earn_pos earn_r_pos earn_r_pos_tc log_earn_pos log_earn_r_pos log_earn_r_pos_tc tcernval posearn"

***** Annual Income *******

* Annual Income (ann_inc)
 gen inc=ptotval

* Inflation adjusted annual income (ann_inc_r)
 gen inc_r=ptotval_r						

* Setting 0's and negatives to missing (ann_inc_pos ann_inc_pos)
 gen posinc=(ptotval>0)
 gen inc_pos=inc
 replace inc_pos=. if posinc==0 
 
 gen posinc_r=(ptotval_r>0)
 gen inc_r_pos=inc_r
 replace inc_r_pos=. if posinc_r==0
 
* Top coding
//Similar to the earnings variable, the 99th percentile ranges from 2* to ~5* the 90th percentile. 
//  topcoded obervations are identified with the tcwsval variable
levelsof year
gen inc_r_pos_tc=inc_r_pos
 foreach y of numlist `r(levels)' {
   di "Real personal earnings distribution, `y'"
   qui su inc_r_pos if inc_r_pos>0 & year==`y' [aw=marsupwt], d
   local p90=r(p90)
   local p99=r(p99)
   di "Ratio of 99th percentile to 90th percentile in `y' is " `p99'/`p90'
   replace inc_r_pos_tc=2*`p90' if year==`y' & inc_r_pos>2*`p90' & inc_r_pos<.
 }


* Annual income logged
gen log_inc_pos = ln(inc_pos)
gen log_inc_r_pos = ln(inc_r_pos)
gen log_inc_r_pos_tc = ln(inc_r_pos_tc)

local incvars "inc inc_r inc_pos inc_r_pos inc_r_pos_tc log_inc_pos log_inc_r_pos log_inc_r_pos_tc tcwsval posinc"

****** Weeks worked ******

*Number of weeks worked (wkswork)

*Indicator for positive weeks worked (wkswork_pos)
gen wkswork_pos=(wkswork>0)

local workvars "wkswork wkswork_pos"

gen marsupwt_log_pearnval_tc_r=marsupwt if log_pearnval_tc_r<.
local collapsevars "log_pearnval_tc_r"
local weightvars "marsupwt marsupwt_log_pearnval_tc_r"

*******************
****** SAVE *******
*******************
sort year cohort fipsst educ5
tempfile all 
save `all'


*************************************
*********** 4 COLLAPSE *************
************************************

** 1.1: Year-cohort
collapse (mean) sex married ed_hs ed_scol ed_ba ed_grad ed_yrs `ernvars' `incvars' `workvars' ///
         (count) n_obs=marsupwt (rawsum) `weightvars' [aw=marsupwt], by(year cohort)
tempfile yc
save `yc'

** 1.2: Year-cohort-state
use `all', clear
collapse (mean) married ed_hs ed_scol ed_ba ed_grad ed_yrs `ernvars' `incvars' `workvars' ///
         (count) n_obs=marsupwt (rawsum) `weightvars' [aw=marsupwt], by(year cohort fipsst)
tempfile ycs
save `ycs'

** 1.3: Year-cohort-attainment (5 category)
use `all', clear
collapse (mean) married `ernvars' `incvars' `workvars' ///
         (count) n_obs=marsupwt (rawsum) `weightvars' [aw=marsupwt], by(year cohort educ5)
tempfile yca5
save `yca5'

** 1.4: Year-cohort-attainment (5 category)-state
use `all', clear
collapse (mean) married `ernvars' `incvars' `workvars' ///
         (count) n_obs=marsupwt (rawsum) `weightvars' [aw=marsupwt], by(year cohort fipsst educ5)
tempfile yca5s
save `yca5s'

** 1.5: Year-cohort-attainment (4 category)
use `all', clear
collapse (mean) married `ernvars' `incvars' `workvars' ///
         (count) n_obs=marsupwt (rawsum) `weightvars' [aw=marsupwt], by(year cohort educ4)
tempfile yca4
save `yca4'

** 1.6: Year-cohort-attainment (4 category)-state
use `all', clear
collapse (mean) married `ernvars' `incvars' `workvars' ///
         (count) n_obs=marsupwt (rawsum) `weightvars' [aw=marsupwt], by(year cohort fipsst educ4)
tempfile yca4s
save `yca4s'

** 1.7: Year-cohort-attainment (2 category)
use `all', clear
collapse (mean) married `ernvars' `incvars' `workvars' ///
         (count) n_obs=marsupwt (rawsum) `weightvars' [aw=marsupwt], by(year cohort educ2)
tempfile yca2
save `yca2'

** 1.8: Year-cohort-attainment (2 category)-state
use `all', clear
collapse (mean) married `ernvars' `incvars' `workvars' ///
         (count) n_obs=marsupwt (rawsum) `weightvars' [aw=marsupwt], by(year cohort fipsst educ2)
tempfile yca2s
save `yca2s'

** 1.9: Year-cohort-attainment (2 category)-sex-state
use `all', clear
collapse (mean) married `ernvars' `incvars' `workvars' ///
         (count) n_obs=marsupwt (rawsum) `weightvars' [aw=marsupwt], by(year cohort fipsst educ2 sex)
tempfile yca2ss
save `yca2ss'

/*
********************************************
**** 5  MERGE POPULATION TIME SERIES *****
********************************************
 // Make national version of population dataset
  use `prepdata'/statepop
  collapse (sum) pop, by(year)
  tempfile natlpop
  save `natlpop'
 // Make annual versions of unemployment rates
  use `prepdata'/unrate_national
  isid yearmo
  sort yearmo
  gen year=yofd(dofm(yearmo))
  bys year (yearmo): keep if _n==_N
  keep year ur_nat_annual ur_nat_3yr_avg
  tempfile natlur
  save `natlur'
  use `prepdata'/unrate_state
  isid fipsst yearmo
  sort fipsst yearmo
  gen year=yofd(dofm(yearmo))
  bys fipsst year (yearmo): keep if _n==_N
  keep fipsst year ur_st_annual ur_st_3yr_avg
  tempfile stateur
  save `stateur'
  exit
  
 // Merge to population
  foreach set in yc yca {
    use ``set''
    merge m:1 year using `natlpop', assert(2 3) keep(3) nogen
    save ``set'', replace
  }
  foreach set in ycs ycas {
    use ``set''
    merge m:1 fipsst year using `prepdata'/statepop, assert(2 3) keep(3) nogen
    save ``set'', replace
  }

 // Merge to national unemployment rate
  foreach set in yc ycs yca ycas {
    use ``set''
    merge m:1 year using `natlur', assert(2 3) keep(3) nogen
    label var ur_nat_annual "Unemployment rate (national)"
    rename ur_nat_annual ur_nat
    // Now merge on the unemployment rate at age 22
    rename year origyear
    gen year=cohort + 22
    merge m:1 year using `natlur', keep(1 3) nogen
    label var ur_nat_annual "UR (natl) at age 22"
    rename ur_nat_annual ur0_nat
    drop year
    rename origyear year
    save ``set'', replace
  }
 // Merge to state unemployment rate
  foreach set in ycs ycas {
    use ``set''
    merge m:1 fipsst year using `stateur', assert(2 3) keep(3) nogen
    label var ur_st_annual "Unemployment rate (state)"
    rename ur_st_annual ur_st
    // Now merge on the unemployment rate at age 22
      rename year origyear
      gen year=cohort + 22
      merge m:1 fipsst year using `stateur', keep(1 3) nogen
      label var ur_st_annual "UR (state) at age 22"
      rename ur_st_annual ur0_st
      drop year
      rename origyear year
    save ``set'', replace
  }
*/

********************************************
**** 6  LABEL VARIABLES *****
********************************************
  foreach set in yc ycs yca5 yca5s yca4 yca4s yca2 yca2s yca2ss {
    use ``set''
    label var n_obs "Number of observations in cell"
    label var marsupwt "Sum of weights (unweighted/raw)"							
    label var married "Married"
    cap label var ed_hs "Educ: HS grad"
    cap label var ed_scol "Educ: Some coll"
    cap label var ed_ba "Educ: Bach degree"
    cap label var ed_grad "Educ: >Bach degree"*/
    cap label var ed_yrs "Educ: years"
	
    label var log_pearnval_tc_r "ln(Annual earnings), for analysis"
    label var marsupwt_log_pearnval_tc_r "Sum of weights (log_pearnval_tc_r<.)"							

    
    label var pearnval_tc_r "Annual earnings, for analysis"
    label var earn "Annual earnings"
    label var earn_r "Annual earnings (2015$)"
    label var earn_pos "Annual earnings | ern>0"
    label var earn_r_pos "Annual earnings | ern>0 (2015$)"
    label var earn_r_pos_tc "Top coded, annual earnings | ern>0,  (2015$)"
    label var log_earn_pos "Ln(annual earnings | ern>0)"
    label var log_earn_r_pos "Ln(annual earnings | ern>0) (2015$)"
    label var log_earn_r_pos_tc "Ln(Top coded annual earnings | ern>0) (2015$)"
    label var inc "Annual income "
    label var inc_r "Annual income (2015$)"
    label var inc_pos "Annual income | inc>0"	
    label var inc_r_pos "Annual income | inc>0 (2015$)"
    label var inc_r_pos_tc "Top coded, annual income | inc>0,  (2015$)"
    label var log_inc_pos "Ln(annual income) | inc>0"
    label var log_inc_r_pos "Ln(annual income) | inc>0, (2015$)"
    label var log_inc_r_pos_tc "Ln(Top coded annual income) | inc>0, (2015$)"
 	
    label var wkswork "Weeks worked"
    label var wkswork_pos "Weeks worked | weeks>0"
    

    save ``set'', replace
  }

*****************************************************
**** 7  ADJUST YEAR FOR RETROSPECTIVE VARIABLES *****
*****************************************************
foreach set in yc ycs yca5 yca5s yca4 yca4s yca2 yca2s yca2ss {
  if "`set'"=="yc" local id "cohort"
  if "`set'"=="ycs" local id "cohort fipsst"
  if "`set'"=="yca5" local id "cohort educ5"
  if "`set'"=="yca5s" local id "cohort educ5 fipsst"
  if "`set'"=="yca4" local id "cohort educ4"
  if "`set'"=="yca4s" local id "cohort educ4 fipsst"
  if "`set'"=="yca2" local id "cohort educ2"
  if "`set'"=="yca2s" local id "cohort educ2 fipsst"
  if "`set'"=="yca2ss" local id "cohort sex educ2 fipsst"
  
  use ``set'', clear
  tempfile `set'_contemp `set'_retro
  //keep year `id' employed_ly ann_* log_* wkswork* hrswk_ly* 
  //keep year `id' `collapsevars' `weightvars'
  //rename marsupwt marsupwt_retro
  isid year `id'
  sort `id' year
  replace year=year-1
  /* 
  save `set'_retro, replace
  use ``set'', clear
  //drop employed_ly ann_* log_* wkswork* hrswk_ly* 
  drop `incvars' `ernvars' 
  merge 1:1 year `id' using `set'_retro, nogen 

  //replace marsupwt with marsupwt_retro
  //if marsupwt == .
  replace marsupwt = marsupwt_retro if missing(marsupwt)
   */
  save ``set'', replace
}
   
*************************************
****** 8 COMPRESS AND SAVE *********
*************************************
foreach col in yc ycs yca5 yca5s yca4 yca4s yca2 yca2s yca2ss {
  use ``col'', clear
  save "`prepdata'/`dofile'_`col'.dta", replace
  *! gzip -f `prepdata'/`dofile'_`col'.dta
  *project, creates("`prepdata'/`dofile'_`col'.dta.gz")
  if `doasproject'==1 project, creates("`prepdata'/`dofile'_`col'.dta")
}


* end of do file *
