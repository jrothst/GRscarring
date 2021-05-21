*************************************************************************************************************** 
* NG: 9/18/2019
* summarystats.do
* Creates Stats Des
*
* NG Edit: 01/20/2020, Update to match with the new name of cohort, entrycohort
* JR, 4/24/2020: Rewrite to work with microdata


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
	local dofile "summarystats"
	local doasproject=0
}

set more off
local rootdir "`pdir'"
local thisdir "`pdir'"

local prepdata "`pdir'/scratch"
local scratch "`pdir'/scratch"
local rawdata "`pdir'/rawdata"
local output "`pdir'/results"

// Prep the big CPS data

if `doasproject'==1 {
	project, uses("`scratch'/statepop.dta")
	project, uses("`scratch'/unrate_national.dta")
	project, uses("`scratch'/unrate_state.dta")
  project, uses("`prepdata'/extractcps.dta.gz")
  project, uses("`prepdata'/extractorg_morg.dta.gz")
  project, uses("`prepdata'/combinecollapse_yca2s.dta")
}


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
  
 
 //unzip extractcps and findpartners;
  !zcat `prepdata'/extractcps.dta.gz > `prepdata'/extractcps.dta 
  use `prepdata'/extractcps.dta
  !rm `prepdata'/extractcps.dta

*** COHORT: ****
gen birthcohort=(year-age)

rename wgt_composite bigcpswgt
rename stfips fipsst

************************************************
*********** 1: SAMPLE RESTRICTIONS *************
************************************************
keep if age>=22 & age<=40
keep if birthcohort>=1948
  // Drop last year data, which is not yet complete
  drop if year>2019

************************************************
*********** 2: MAKE SOME VARIABLES *************
************************************************
*  Weekly hours, w/ zeros
replace hourslw=0 if hourslw==. & pemlr~=-1
*  Weekly hours, w/o zeros 
gen hourslw_pos=hourslw if hourslw>0 & hourslw<.
gen byte ed_hs=(educ5==2) if educ5<.
gen byte ed_scol=(educ5==3) if educ5<.
gen byte ed_ba=(educ5==4) if educ5<.
gen byte ed_grad=(educ5==5) if educ5<.

gen byte educ2=(inlist(educ5, 4, 5)) if educ5<.
keep if educ2==1

  keep if bigcpswgt<.
  gen entrycohort=birthcohort+22 if educ2==1
  replace entrycohort=birthcohort+18 if educ2==0
  label var birthcohort "Year of Birth"
  label var entrycohort "Year of entry on the labor market, depending on level of education"
      merge m:1 fipsst year using `popur_s', assert(2 3) keep(3) nogen
      rename ur_nat_annual ur_nat
      rename ur_st_annual ur_st
     // And merge on age-22 UR
      rename year origyr
      gen year=entrycohort
      merge m:1 fipsst year using `popur_s', keepusing(year ur_nat_annual ur_st_annual) keep(1 3) nogen
      rename ur_nat_annual ur0_nat_22  
      label var ur0_nat_22 "UR (natl) at age 22"
      rename ur_st_annual ur0_st_22
      label var ur0_st_22 "UR (state) at age 22"  
      drop year
      rename origyr year
     // Make a consolidated age-22 UR that uses national rate before 1976 and state rate before
     // This makes it possible to include earlier cohorts in the analyses that control for the age-22 UR.
      gen ur0_22=ur0_st_22
      assert ur0_22==. if birthcohort<1954
      replace ur0_22=ur0_nat_22 if birthcohort<1954
      label var ur0_22 "Age-22 UR (nat pre-1976, state 1976-)"


  gen ur0=ur0_22 if educ2==1
  gen ur0_nat=ur0_nat_22 if educ2==1
    
  // Subsample that is age 30+ when GR hit for educated, 26 otherwise 
  gen estsamp=(birthcohort<=1978 & ur0<.) if educ2==1
  replace estsamp=(birthcohort<=1982 & ur0<.) if educ2==0
  assert estsamp==(birthcohort>=1948 & birthcohort<=1978) if educ2==1 
  assert estsamp==0 if educ2==1 & (birthcohort<1948 | birthcohort>1978)
  assert estsamp==(birthcohort>=1952 & birthcohort<=1982) if educ2==0
  assert estsamp==0 if educ2==0 & (birthcohort<1952 | birthcohort>1982)
  gen estsampb=(ur0<.)
  assert estsampb==(birthcohort>=1948 & birthcohort<=1997) if educ2==1 
  assert estsampb==(birthcohort>=1952 & birthcohort<=2001) if educ2==0 
  // create inverse mills ratios
  // Need to merge on education fraction
  merge m:1 year birthcohort educ2 fipsst using `prepdata'/combinecollapse_yca2s, keepusing(edfr_yc edfr_ycs)
  assert _merge==3 if educ2==1 & birthcohort>=1948 & age>=22 & age<=40 & year>=1979
  drop if _merge==2
  gen imr_yc=normalden(invnormal(edfr_yc))/edfr_yc if educ2==1
  replace imr_yc=normalden(invnormal(1-edfr_yc))/(1-edfr_yc) if educ2==0
  
  gen imr_ycs=normalden(invnormal(edfr_ycs))/edfr_ycs if educ2==1
  replace imr_ycs=normalden(invnormal(1-edfr_ycs))/(1-edfr_ycs) if educ2==0



// Summary Statistics Table 
local bigcpsvars "ed_grad empl birthcohort age entrycohort uhours ur_st ur0 edfr_yc imr_yc edfr_ycs imr_ycs"
estpost tabstat `bigcpsvars' [aw=bigcpswgt], stat(mean sd min p10 p50 p90 max) col(stat)
eststo bigcps


// Now prepare ORG file
!zcat `prepdata'/extractorg_morg.dta.gz > `prepdata'/extractorg_morg.dta
use `prepdata'/extractorg_morg.dta, clear
!rm `prepdata'/extractorg_morg.dta
*** COHORT: ****
gen birthcohort=(year-age)
************************************************
*********** 1: SAMPLE RESTRICTIONS *************
************************************************
keep if age>=22 & age<=40
keep if age>=22 & age<=40
keep if birthcohort>=1948
  // Drop last year data, which is not yet complete
  drop if year>2019

rename gestfips fipsst

************************************************
*********** 2: MAKE SOME VARIABLES *************
************************************************
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
keep if educ2==1

gen orgwgt_rw_l=orgwgt if rw_l<.
gen earnwt_rw_l=earnwt if rw_l<.


******** Sex ******
replace sex = 0 if sex == 2
tab sex

local orgvars "rw_l"
estpost tabstat `orgvars' [aw=orgwgt], stat(mean sd min p10 p50 p90 max) col(stat)
eststo org


esttab bigcps using `output'/summarystats_statdes.txt, title("Summary Statistics")   replace ///
cells("mean(label(Mean)fmt(%9.3f)) sd(label(Std.Dev.)fmt(%9.3f)) min(label(Min)fmt(%9.2f)) max(label(Max)fmt(%9.2f)) p10(label(p10)fmt(%9.2f)) p50(label(p50)fmt(%9.2f)) p90(label(p90)fmt(%9.2f))")

esttab org using `output'/summarystats_statdes.txt, title("Summary Statistics")   append ///
cells("mean(label(Mean)fmt(%9.3f)) sd(label(Std.Dev.)fmt(%9.3f)) min(label(Min)fmt(%9.2f)) max(label(Max)fmt(%9.2f)) p10(label(p10)fmt(%9.2f)) p50(label(p50)fmt(%9.2f)) p90(label(p90)fmt(%9.2f))")


*create Table1b with full data
*estpost tabstat $list2, stat(mean sd min max) col(stat) 
*esttab . using `output'/summarystats_statdes.txt, title("Summary Statistics")   replace ///
*cells("mean(label(Mean)fmt(%9.3f)) sd(label(Std.Dev.)fmt(%9.3f)) min(label(Min)fmt(%9.2f)) max(label(Max)fmt(%9.2f))")

save `prepdata'/summarystats_statdes.dta, replace
  
if `doasproject'==1 {
      project, creates(`output'/summarystats_statdes.txt)
      project, creates(`prepdata'/summarystats_statdes.dta)
}
