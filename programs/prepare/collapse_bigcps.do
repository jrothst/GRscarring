********************************************************************************

* collapse_bigcps.do
* Collapses 1989-2015 big cps data by cohort and other 
* Extracts made:
*	1) year-cohort level
*	2) year-cohort-state (current state)
*	3) year-cohort-attainment
*	4) year-cohort-attainment-state
*
* Edited by JR, 8/4/17: Modify to get age-22 UE rate, even for cohorts not seen at 22
*                       As part of this, rearrange program flow.
*  JR, 9/22/17: Eliminate "cpsnewvariables.do" -- merge extractcps and findpartners here.
*  JR, 4/10/18: Comment out merge to UR and pop -- do this in combinecollapse instead.
*  RY, 4/25/18: Revised the collapse so that it has two education groups 
*  JR, 4/30/18: Add a 2- and 4-category education collapses

cap project, doinfo
if _rc==0 {
	 local pdir "`r(pdir)'"						  	    // the project's main dir.
	 local dofile "`r(dofile)'"						    // do-file's stub name
   local sig {bind:{hi:[`dofile'.dta. RP : `dofile'.do, `c(current_date)']}}	// a signature in notes
   local doasproject=1
}
else {
	local pdir "~/GRscarring"
	local dofile "collapse_bigcps"
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

*** CPS DATA ***

if `doasproject'==1 {
  project, uses("`prepdata'/extractcps.dta.gz")
  project, uses("`prepdata'/findpartners_v3.dta.gz")
}

 *unzip extractcps and findpartners;
  !zcat `prepdata'/extractcps.dta.gz > `prepdata'/extractcps.dta 
  !zcat `prepdata'/findpartners_v3.dta.gz > `prepdata'/findpartners_v3.dta 

  use `prepdata'/extractcps.dta
  *Merge in lives-with-partner
  qui merge m:1 hh_id yearmo linenum hh_num hh_tiebreak p_tiebreak using `prepdata'/findpartners_v3, gen(mrg2partner)
  tab mrg2partner, m
  tab year mrg2partner, m
  drop if mrg2partner==2
  drop mrg2partner

  !rm `prepdata'/extractcps.dta
  !rm `prepdata'/findpartners_v3.dta



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

*  Weekly hours, w/ zeros
replace hourslw=0 if hourslw==. & pemlr~=-1
*  Weekly hours, w/o zeros 
gen hourslw_pos=hourslw if hourslw>0 & hourslw<.

gen byte ed_hs=(educ5==2) if educ5<.
gen byte ed_scol=(educ5==3) if educ5<.
gen byte ed_ba=(educ5==4) if educ5<.
gen byte ed_grad=(educ5==5) if educ5<.


*gen byte ed_scol_less=(educ5==1 | educ5==2 | educ5==3) if educ5<.
*gen byte ed_ba_more=(educ5==4 | educ5==5) if educ5<.
gen byte educ2=(inlist(educ5, 4, 5)) if educ5<.
*recode educ5 (1=1) (2=2) (3=3) (4 5=4), gen(educ4)

*  Mean education of occupation, conditional on employment (use pre-recession base period)
*bys occ1_2003: egen occ_mn_ed_yrs_tmp=mean(ed_yrs) if inrange(year, 1998, 2007)
*bys occ1_2003: egen occ_mn_ed_yrs=mode(occ_mn_ed_yrs_tmp)

*  Mean earnings of occupation, conditional on employment (use pre-recession base period)
*bys occ: egen occ_mn_tot_ern_r_tmp=mean(tot_ern_r) if inrange(year, 1998, 2007)
*bys occ: egen occ_mn_tot_ern_r=mode(occ_mn_tot_ern_r_tmp)

rename stfips fipsst
sort year cohort fipsst educ5
tempfile all 
save `all'



*************************************
*********** 3: COLLAPSE *************
*************************************
local mainvars "labfor empl unem married howner hourslw hourslw_pos uhours livewithprnt chld_pr educ_occup lives_spouse_oth"
** 1.1: Year-cohort
collapse (mean) `mainvars' sex educ_yr ed_hs ed_scol ed_ba ed_grad ///
		 (count) n_obs=wgt_composite (rawsum) wgt_composite [aw=wgt_composite], ///
		 by(year cohort)
tempfile yc
save `yc'

** 1.2: Year-cohort-state
use `all', clear
collapse (mean) `mainvars' educ_yr ed_hs ed_scol ed_ba ed_grad ///
		 (count) n_obs=wgt_composite (rawsum) wgt_composite [aw=wgt_composite], ///
		 by(year cohort fipsst)
tempfile ycs
save `ycs'

** 1.3: Year-cohort-attainment (5 category)
use `all', clear
collapse (mean) `mainvars' educ_yr ///
		 (count) n_obs=wgt_composite (rawsum) wgt_composite [aw=wgt_composite], ///
		 by(year cohort educ5)
tempfile yca5
save `yca5'

** 1.4: Year-cohort-attainment (5 category)-state
use `all', clear
collapse (mean) `mainvars' educ_yr ///
		 (count) n_obs=wgt_composite (rawsum) wgt_composite [aw=wgt_composite], ///
		 by(year cohort fipsst educ5)
tempfile yca5s
save `yca5s'

** 1.5: Year-cohort-attainment (2 category)
use `all', clear
collapse (mean) `mainvars' educ_yr ed_hs ed_scol ed_ba ed_grad ///
		 (count) n_obs=wgt_composite (rawsum) wgt_composite [aw=wgt_composite], ///
		 by(year cohort educ2)
tempfile yca2
save `yca2'

** 1.6: Year-cohort-attainment (2 category)-state
use `all', clear
collapse (mean) `mainvars' educ_yr ed_hs ed_scol ed_ba ed_grad ///
		 (count) n_obs=wgt_composite (rawsum) wgt_composite [aw=wgt_composite], ///
		 by(year cohort fipsst educ2)
tempfile yca2s
save `yca2s'

** 1.7: Year-cohort-attainment (2 category)-sex-state
use `all', clear
collapse (mean) `mainvars' educ_yr ed_grad ///
		 (count) n_obs=wgt_composite (rawsum) wgt_composite [aw=wgt_composite], ///
		 by(year cohort fipsst educ2 sex)
tempfile yca2ss 
save `yca2ss'

** 1.8: Year-cohort-attainment (4 category)
use `all', clear
collapse (mean) `mainvars' educ_yr ed_grad ///
		 (count) n_obs=wgt_composite (rawsum) wgt_composite [aw=wgt_composite], ///
		 by(year cohort educ4)
tempfile yca4
save `yca4'

** 1.9: Year-cohort-attainment (4 category)-state
use `all', clear
collapse (mean) `mainvars' educ_yr ed_grad ///
		 (count) n_obs=wgt_composite (rawsum) wgt_composite [aw=wgt_composite], ///
		 by(year cohort fipsst educ4)
tempfile yca4s
save `yca4s'


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
    // Make a consolidated age-22 UR that uses national rate before 1976 and state rate before
    // This makes it possible to include earlier cohorts in the analyses that control for the age-22 UR.
      gen ur0=ur0_st
      assert ur0==. if cohort<1954
      replace ur0=ur_nat if cohort<1954
      label var ur0 "Age-22 UR (nat pre-1976, state 1976-)"
    save ``set'', replace
  }
*/  
********************************************
**** 5.  LABEL VARIABLES *****
********************************************
  foreach set in yc ycs yca5 yca5s yca2 yca2s yca2ss yca4 yca4s {
    use ``set''
    label var n_obs "Number of observations in cell"
    label var wgt_composite "Sum of basic CPS weights (unweighted/raw)"	
    label var labfor "In labor force (current status)"
    label var empl "Employed (current status)"							
    label var unem "Unemployed (current status)"		
    label var married "Married"
    label var hourslw "Hours worked last week"
    label var hourslw_pos "Hours worked last week | hours>0"
    cap  label var ed_hs "Educ: HS grad"
    cap  label var ed_scol "Educ: Some coll"
    cap  label var ed_ba "Educ: Bach degree"
    cap  label var ed_grad "Educ: >Bach degree"*/
    cap  label var ed_scol_less "Educ: Some coll or <Some coll"
    cap  label var ed_ba_more "Educ: Bach degree or >BA"
    cap  label var ed_yrs "Educ: years"
    save ``set'', replace
  }


*************************************
****** 6: COMPRESS AND SAVE *********
*************************************


foreach col in yc ycs yca5 yca5s yca2 yca2s yca2ss yca4 yca4s {
	use ``col'', clear
	save "`prepdata'/`dofile'_`col'.dta", replace
	*! gzip -f `prepdata'/`dofile'_`col'.dta
	*project, creates("`prepdata'/`dofile'_`col'.dta.gz")
	if `doasproject'==1 project, creates("`prepdata'/`dofile'_`col'.dta")
}


* end of do file *
