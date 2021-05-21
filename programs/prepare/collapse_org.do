********************************************************************************

* collapse_org.do
* Collapses 1987-2017 march cps data by cohort and other 
* Extracts made:
*	1) year-cohort level
*	2) year-cohort-state (current state)
*	3) year-cohort-attainment
*	4) year-cohort-attainment-state

* Edited, RY, 3/7/2018 
* modified JR 4/30/2018: Use 2, 4, and 5 education groups.
*                        Remove merge to unemployment rate (now in combinecollapse)
* modified JR 1/9/2019:  Reduce variables to keep, and generate new weight that is limited
*                        to those with non-missing earnings.

cap project, doinfo
if _rc==0 {
	 local pdir "`r(pdir)'"						  	    // the project's main dir.
	 local dofile "`r(dofile)'"						    // do-file's stub name
   local sig {bind:{hi:[`dofile'.dta. RP : `dofile'.do, `c(current_date)']}}	// a signature in notes
   local doasproject=1
}
else {
   local pdir "~/GRscarring"
   local dofile "collapse_org"
   local doasproject=0
}

set more off
local rootdir "`pdir'"
local thisdir "`pdir'"


local prepdata "`pdir'/scratch"
local rawdata "`pdir'/rawdata"


***************************************************************************************************************
*************************************
********** 0: LOAD DATA *************
*************************************

*** ORG DATA ***

if `doasproject'==1 {
  project, uses("`prepdata'/extractorg_morg.dta.gz")
}

!zcat `prepdata'/extractorg_morg.dta.gz > `prepdata'/extractorg_morg.dta
use `prepdata'/extractorg_morg.dta, clear
!rm `prepdata'/extractorg_morg.dta

*use if inlist(stfips, 1, 3, 7) & inlist(educ5,2,3) using  `prepdata'/extractorg.dta, clear


*** COHORT: ****
gen cohort=(year-age)


************************************************
*********** 1: SAMPLE RESTRICTIONS *************
************************************************

keep if age>15 & age<81


************************************************
*********** 2: MAKE SOME VARIABLES *************
************************************************

*** Variables to collapse by:

* educ5
gen educ4=.
replace educ4=1 if inlist(educ92,0,1,2,3,4,5,6,7,8)==1
replace educ4=2 if inlist(educ92,9)==1
replace educ4=3 if inlist(educ92,10,11,12)==1
replace educ4=4 if inlist(educ92,13,14,15,16)==1
  
gen educ5=educ4
replace educ5=5 if inlist(educ92,14,15,16)
drop if educ5==.
label define attain_l 1 "LTHS" 2 "HS" 3 "Some col." 4 "BA" 5 "MA+"
label values educ5 attain_l
gen byte educ2=(inlist(educ5, 4, 5)) if educ5<.

gen orgwgt_rw_l=orgwgt if rw_l<.
gen earnwt_rw_l=earnwt if rw_l<.

rename gestfips fipsst

******** Sex ******
replace sex = 0 if sex == 2
tab sex

sort year cohort fipsst educ5

tempfile all 
save `all'

*************************************
*********** 3: COLLAPSE *************
*************************************
/*Paid hourly (paidhre)
Wage (NBER def) (w_nber)
Wage (no topcode/OT adjustment) (w_no_no)
Hours used for wage calculations (hours_jr)
Wage (JR definition) (wage_jr)
Real wage (JR definition) (rw)
Real wage (CEPR method) (rw_cep)
Real wage (NBER definition) (rw_nber)
Occupation mean earnings (wage_occup) */

*local vlist "rw rw_l rw_nber rw_nber_l rwage_occup usualhoursi"
local vlist "rw_l"
local wlist "orgwgt orgwgt_rw_l earnwt earnwt_rw_l"

** 1.1: Year-cohort
collapse (mean) `vlist' sex ///
	(count) n_obs=orgwgt (rawsum) `wlist',  ///
	by(year cohort)


tempfile yc
save `yc'

** 1.2: Year-cohort-state
use `all', clear
collapse (mean) `vlist' ///
	(count) n_obs=orgwgt (rawsum) `wlist',  ///
	by(year cohort fipsst)

tempfile ycs
save `ycs'

** 1.3: Year-cohort-attainment (5 category)
use `all', clear
collapse (mean) `vlist' ///
	(count) n_obs=orgwgt (rawsum) `wlist',  ///
	by(year cohort educ5)

tempfile yca5
save `yca5'

** 1.4: Year-cohort-attainment (5 category)-state
use `all', clear
collapse (mean) `vlist' ///
	(count) n_obs=orgwgt (rawsum) `wlist',  ///
	by(year cohort fipsst educ5)
tempfile yca5s
save `yca5s'

** 1.5: Year-cohort-attainment (4 category)
use `all', clear
collapse (mean) `vlist' ///
	(count) n_obs=orgwgt (rawsum) `wlist',  ///
	by(year cohort educ4)
tempfile yca4
save `yca4'

** 1.6: Year-cohort-attainment (4 category)-state
use `all', clear
collapse (mean) `vlist' ///
	(count) n_obs=orgwgt (rawsum) `wlist',  ///
	by(year cohort fipsst educ4)
tempfile yca4s
save `yca4s'

** 1.7: Year-cohort-attainment (2 category)
use `all', clear
collapse (mean) `vlist' ///
	(count) n_obs=orgwgt (rawsum) `wlist',  ///
	by(year cohort educ2)

tempfile yca2
save `yca2'

** 1.8: Year-cohort-attainment (2 category)-state
use `all', clear
collapse (mean) `vlist' ///
	(count) n_obs=orgwgt (rawsum) `wlist',  ///
	by(year cohort fipsst educ2)
tempfile yca2s
save `yca2s'

** 1.9: Year-cohort-attainment (2 category)-sex-state
use `all', clear
collapse (mean) `vlist' ///
	(count) n_obs=orgwgt (rawsum) `wlist',  ///
	by(year cohort fipsst educ2 sex)
tempfile yca2ss
save `yca2ss'

/*
********************************************
**** 4.  MERGE POPULATION TIME SERIES *****
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
**** 5.  LABEL VARIABLES *****
********************************************
  foreach set in yc ycs yca5 yca5s yca4 yca4s yca2 yca2s yca2ss {
    use ``set''
    label var n_obs "Number of observations in cell"
    label var orgwgt "Sum of ORG weights (unweighted/raw)"	
    label var rw_l "Log of real wage (JR/CEPR definition)"
    label var orgwgt_rw_l "Sum of ORG weights (non-missing rw_l)"	
    label var earnwt "Sum of ORG earnings weights (unweighted/raw)"	
    label var earnwt_rw_l "Sum of ORG earnings weights (non-missing rw_l)"	
    /*
    label var rw "Real wage (JR/CEPR definition)"
    label var rw_nber "Real wage (NBER definition)"
    label var rw_nber_l "Log of real wage (NBER definition)"
    label var rwage_occup "Occupation mean real earnings"
    label var usualhoursi "Usual weekly hours (w imputations)"
    label var paidhre "Paid hourly"
    label var w_nber "Wage (NBER def)"
    label var w_farber "Wage (Farber def)"
    label var log_wk_ern "Log of Weekly Earnings"
    */
    /* 
    *label var in_lf "In labor force"
    *label var employed_cur "Employed (current status)"							
    *label var unemployed_cur "Unemployed (current status)"		
    *label var employed_ly "Employed (at all last year)"							
    *label var married "Married"
    *label var w_no_no "Wage (no topcode/OT adjustment)"
    *label var hours_jr "Hours used for wage calculations"
    *label var wage_jr "Wage (JR definition)"
    *label var rw_cepr "Real wage (CEPR method)"
    *label var rw_nber "Real wage (NBER definition)"
    */
    save ``set'', replace
}

drop orgwgt orgwgt_rw_l
rename earnwt orgwgt
rename earnwt_rw_l orgwgt_rw_l

*************************************
****** 6: COMPRESS AND SAVE *********
*************************************

foreach col in yc ycs yca5 yca5s yca4 yca4s yca2 yca2s yca2ss {
	use ``col'', clear
	save "`prepdata'/collapse_org_`col'.dta", replace
	*! gzip -f `prepdata'/`dofile'_`col'.dta
	*project, creates("`prepdata'/`dofile'_`col'.dta.gz")
	if `doasproject'==1 project, creates("`prepdata'/collapse_org_`col'.dta")
}


* end of do file *


