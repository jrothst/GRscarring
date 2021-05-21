**********************************************************************
* Run IV versions of the scarring models, using double-weighted
* measures of the entry unemployment weight a la Heisz-von Wachter
*
*Edits
** NR 03/17/2019: Comment out line that sets ur0 = 0 if  cohort<1954
* 01/20/2020: NG:  Updated to match with the new cohort and birthcohort variables 
* 5/2/20, JR: Updated and repaired
*********************************************************************

clear
cap project, doinfo
if _rc==0 {
	local pdir "`r(pdir)'"						  	    // the project's main dir.
	local dofile "`r(dofile)'"						    // do-file's stub name
	local sig {bind:{hi:[`dofile'.dta. RP : `dofile'.do, `c(current_date)']}}   // a signature in notes
	local doasproject=1
}
else {
	local pdir "~/GRscarring"
	local dofile "ivrunatc"
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
	project, uses("`prepdata'/double_weight.dta")
}

use "`prepdata'/double_weight", replace
rename cohort entrycohort
tempfile weight
save `weight', replace

// Start of data manipulation

use `prepdata'/combinecollapse_yca2s, clear
cap drop _*
keep if age<=40 
keep if (educ2==1 & age>=22) 
keep if marchwgt<. | orgwgt<. | bigcpswgt<.
// Drop 2019 data, which is not yet complete
//  drop if year==2019
// Drop the cohorts just entering the sample in 2018, for whom UR0 is missing.
// edit, 9/2/19: Dont need this now that we have UR for 2018
isid birthcohort year fipsst educ2
gen ur0=ur0_22 if educ2==1
replace ur0=ur0_18 if educ2==0
gen ur0_nat=ur0_nat_22 if educ2==1
replace ur0_nat=ur0_nat_18 if educ2==0

// Edit 12/26/19:  Update to match the new cohort definition
// gen ur0=ur0_22 
// gen ur0_nat=ur0_nat_22

*replace ur0_22=. if cohort<1954
*replace ur0   =. if cohort<1954

// Make de-meaned state unemployment rates for the last period.
gen dur    = ur_st-ur_nat
gen dur0=ur0-ur0_nat_22 if educ2==1
replace dur0=ur0-ur0_nat_18 if educ2==0
// Edit 12/26/19:  Update to match the new cohort definition
*gen dur0   = ur0-ur0_nat_22
  
  gen estsamp=(birthcohort<=1978 & ur0<.) if educ2==1
  replace estsamp=(birthcohort<=1982 & ur0<.) if educ2==0
  assert estsamp==(birthcohort>=1948 & birthcohort<=1978) if educ2==1 
  assert estsamp==0 if educ2==1 & (birthcohort<1948 | birthcohort>1978)
  assert estsamp==(birthcohort>=1952 & birthcohort<=1982) if educ2==0
  assert estsamp==0 if educ2==0 & (birthcohort<1952 | birthcohort>1982)
  gen estsampb=(ur0<.)
  assert estsampb==(birthcohort>=1948 & birthcohort<=1997) if educ2==1 
  assert estsampb==(birthcohort>=1952 & birthcohort<=2001) if educ2==0 
  gen ageb=age-40
  gen exper=age-18-4*educ2
  recode exper (0/1=0) (2/3=2) (4/5=4) (6/7=6) (8/9=8) (10/max=10), gen(expgp)
  gen expgp0=(expgp==0)
  gen expgp2=(expgp==2)
  gen expgp4=(expgp==4)
  gen expgp6=(expgp==6)
  gen expgp8=(expgp==8)
  gen expgp10=(expgp==10)
  gen byte diffsamp=inlist(birthcohort, 1983, 1984, 1988, 1989) * (age<=27) if educ2==1
  replace diffsamp=inlist(birthcohort, 1987, 1988, 1992, 1993)*(age<=27) if educ2==0
  gen byte postGR=inlist(birthcohort, 1988, 1989) if diffsamp==1 & educ2==1
  replace postGR=inlist(birthcohort, 1992, 1993) if diffsamp==1 & educ2==0
  // create inverse mills ratios
  gen imr_yc=normalden(invnormal(edfr_yc))/edfr_yc if educ2==1
  replace imr_yc=normalden(invnormal(1-edfr_yc))/(1-edfr_yc) if educ2==0
  
  gen imr_ycs=normalden(invnormal(edfr_ycs))/edfr_ycs if educ2==1
  replace imr_ycs=normalden(invnormal(1-edfr_ycs))/(1-edfr_ycs) if educ2==0
  gen edfr2_ycs=edfr_ycs^2

 
 // NG 01/20/2020: Edited, new name for the cohort variable (entrycohort) and new variable for the birth year (birthcohort)
* For clarity we define birthcohort and entrycohort and we redefine the cohort definition
label var birthcohort "Year of Birth"
gen entrycohort=. 
replace entrycohort=birthcohort+22 if educ2==1
replace entrycohort=birthcohort+18 if educ2==0
label var entrycohort "Year of entry on the labor market, depending on level of education"

// Merge on double_weight UR22 
merge 1:1 entrycohort age fipsst educ2 using `weight', keep(1 3) 

// NG, Edit 12/26/12: Update to match new cohort definition 
* drop if cohort<1948
drop if entrycohort<1970
*drop if entrycohort<1970 & educ2==1 | entrycohort<1970 & educ2==0
assert _merge==3
drop _merge
gen dur_dw = UR22_dw-ur0_nat_22

/* 
//OLS, model D, estsamp
    reg empl ib10.exper ib2007.year ib1991o2000.entrycohort ib6.fipsst imr_yc  ///
        c.ur0#c.expgp0 c.ur0#c.expgp2 c.ur0#c.expgp4 c.ur0#c.expgp6 c.ur0#c.expgp8 c.dur0 ///
        [aw=bigcpswgt] if estsamp==1, cluster(fipsst) 
        eststo sub
    *fvreg `v' ib10.exper ib2007.year ib1991o2000.entrycohort ib6.fipsst imr_yc  ///
    *     c.ur0#c.expgp0 c.ur0#c.expgp2 c.ur0#c.expgp4 c.ur0#c.expgp6 c.ur0#c.expgp8 c.dur0 ///
    *     [aw=`wgt'] if estsamp==1 & educ2==`e', cluster(fipsst) ///
    *     model("mD`e'a") outfile(`mD`e'a_`v'') preserve
 //IV, model D, estsamp
    ivregress 2sls empl ib10.exper ib2007.year ib1991o2000.entrycohort ib6.fipsst imr_yc  c.dur0 ///
        (c.ur0#c.expgp0     c.ur0#c.expgp2     c.ur0#c.expgp4     c.ur0#c.expgp6     c.ur0#c.expgp8 = ///
         c.UR22_dw#c.expgp0 c.UR22_dw#c.expgp2 c.UR22_dw#c.expgp4 c.UR22_dw#c.expgp6 c.UR22_dw#c.expgp8) ///
        [aw=bigcpswgt] if estsamp==1, cluster(fipsst) 
        eststo sub_2sls
*/

 //OLS, model D, estsampb
    reg empl ib10.exper ib2007.year ib1984o2000.entrycohort ib6.fipsst imr_ycs  ///
        c.ur0#c.expgp0 c.ur0#c.expgp2 c.ur0#c.expgp4 c.ur0#c.expgp6 c.ur0#c.expgp8 c.dur0 ///
        [aw=bigcpswgt] if estsampb==1, cluster(fipsst) 
        eststo mD_ols
    forvalues c = 0(2)8 {
      local bD_ols_`c'=_b[c.ur0#c.expgp`c']
      local seD_ols_`c'=_se[c.ur0#c.expgp`c']
    }
    matrix results_Dols=(0, `bD_ols_0', `seD_ols_0' \ ///
                         2, `bD_ols_2', `seD_ols_2' \ ///
                         4, `bD_ols_4', `seD_ols_4' \ ///
                         6, `bD_ols_6', `seD_ols_6' \ ///
                         8, `bD_ols_8', `seD_ols_8' \ 10, 0, 0)
    matrix colnames results_Dols=period beta_Dols se_Dols

 //IV, model D, estsampb
    ivregress 2sls empl ib10.exper ib2007.year ib1984o2000.entrycohort ib6.fipsst imr_ycs  c.dur0 ///
        (c.ur0#c.expgp0     c.ur0#c.expgp2     c.ur0#c.expgp4     c.ur0#c.expgp6     c.ur0#c.expgp8 = ///
         c.UR22_dw#c.expgp0 c.UR22_dw#c.expgp2 c.UR22_dw#c.expgp4 c.UR22_dw#c.expgp6 c.UR22_dw#c.expgp8) ///
        [aw=bigcpswgt] if estsampb==1, cluster(fipsst) 
        eststo mD_2sls
    forvalues c = 0(2)8 {
      local bD_2sls_`c'=_b[c.ur0#c.expgp`c']
      local seD_2sls_`c'=_se[c.ur0#c.expgp`c']
    }
    matrix results_D2sls=(0, `bD_2sls_0', `seD_2sls_0' \ ///
                          2, `bD_2sls_2', `seD_2sls_2' \ ///
                          4, `bD_2sls_4', `seD_2sls_4' \ ///
                          6, `bD_2sls_6', `seD_2sls_6' \ ///
                          8, `bD_2sls_8', `seD_2sls_8' \ 10, 0, 0)
    matrix colnames results_D2sls=period2 beta_D2sls se_D2sls

 //OLS, model E, estsampb
    reg empl ib10.exper ib2007.year ib1984o2000.entrycohort ib6.fipsst imr_ycs  ///
          c.ur_st#c.expgp0 c.ur_st#c.expgp2 c.ur_st#c.expgp4 c.ur_st#c.expgp6 c.ur_st#c.expgp8 c.dur ///
          c.ur0#c.expgp0 c.ur0#c.expgp2 c.ur0#c.expgp4 c.ur0#c.expgp6 c.ur0#c.expgp8 c.dur0 ///
        [aw=bigcpswgt] if estsampb==1, cluster(fipsst) 
        eststo mE_ols
    forvalues c = 0(2)8 {
      local bE_ols_`c'=_b[c.ur0#c.expgp`c']
      local seE_ols_`c'=_se[c.ur0#c.expgp`c']
    }
    matrix results_Eols=(0, `bE_ols_0', `seE_ols_0' \ ///
                         2, `bE_ols_2', `seE_ols_2' \ ///
                         4, `bE_ols_4', `seE_ols_4' \ ///
                         6, `bE_ols_6', `seE_ols_6' \ ///
                         8, `bE_ols_8', `seE_ols_8' \ 10, 0, 0)
    matrix colnames results_Eols=period3 beta_Eols se_Eols
 //IV, model E, estsampb
    ivregress 2sls empl ib10.exper ib2007.year ib1984o2000.entrycohort ib6.fipsst imr_ycs  c.dur0 ///
          c.ur_st#c.expgp0 c.ur_st#c.expgp2 c.ur_st#c.expgp4 c.ur_st#c.expgp6 c.ur_st#c.expgp8 c.dur ///
        (c.ur0#c.expgp0     c.ur0#c.expgp2     c.ur0#c.expgp4     c.ur0#c.expgp6     c.ur0#c.expgp8 = ///
         c.UR22_dw#c.expgp0 c.UR22_dw#c.expgp2 c.UR22_dw#c.expgp4 c.UR22_dw#c.expgp6 c.UR22_dw#c.expgp8) ///
        [aw=bigcpswgt] if estsampb==1, cluster(fipsst) 
        eststo mE_2sls
    forvalues c = 0(2)8 {
      local bE_2sls_`c'=_b[c.ur0#c.expgp`c']
      local seE_2sls_`c'=_se[c.ur0#c.expgp`c']
    }
    matrix results_E2sls=(0, `bE_2sls_0', `seE_2sls_0' \ ///
                          2, `bE_2sls_2', `seE_2sls_2' \ ///
                          4, `bE_2sls_4', `seE_2sls_4' \ ///
                          6, `bE_2sls_6', `seE_2sls_6' \ ///
                          8, `bE_2sls_8', `seE_2sls_8' \ 10, 0, 0)
    matrix colnames results_E2sls=period4 beta_E2sls se_E2sls

esttab mD_ols mD_2sls mE_ols mE_2sls ///
using `output'/`dofile'.txt, replace b se nostar drop(*.exper *.year *.entrycohort *.fipsst)

drop _all
matrix results=results_Dols, results_D2sls, results_Eols, results_E2sls
svmat results, names(col)
foreach model in Dols D2sls Eols E2sls {
  replace beta_`model'=beta_`model'*100
  replace se_`model'=se_`model'*100
  gen cil_`model'=beta_`model'-2*se_`model'
  gen cih_`model'=beta_`model'+2*se_`model'
}    
save "`output'/`dofile'.dta", replace
gen periodA=period-0.1
gen periodB=period+0.1

twoway rcap cil_Dols  cih_Dols  periodA || ///
       scatter beta_Dols  periodA, msymbol(X) lstyle(p1) mstyle(p1) || ///
       rcap cil_D2sls cih_D2sls periodB, lstyle(p2) mstyle(p2) || ///
       scatter beta_D2sls periodB, msymbol(Th) mstyle(p2) || ///
       , legend(order(2 4) label(2 "OLS") label(4 "IV") cols(1) ring(0) pos(5)) ///
         title("A. Base scarring model") ///
         xlabel(0 "22-23" 2 "24-25" 4 "26-27" 6 "28-29" 8 "30-31" 10 "32+") ///
         yline(0, lcolor(gray)) xtitle("Age") ytitle("Effect of entry UR") ///
         name(panelA, replace) nodraw
twoway rcap cil_Eols  cih_Eols  periodA || ///
       scatter beta_Eols  periodA, msymbol(X) lstyle(p1) mstyle(p1) || ///
       rcap cil_E2sls cih_E2sls periodB, lstyle(p2) mstyle(p2) || ///
       scatter beta_E2sls periodB, msymbol(Th) mstyle(p2) || ///
       , legend(off) ///
         title("B. With excess sensitivity controls") ///
         xlabel(0 "22-23" 2 "24-25" 4 "26-27" 6 "28-29" 8 "30-31" 10 "32+") ///
         yline(0, lcolor(gray)) xtitle("Age") ytitle("Effect of entry UR") ///
         name(panelB, replace) nodraw
graph combine panelA panelB, ycommon saving("`output'/`dofile'.gph", replace)
         
if `doasproject' == 1 {
  project, creates("`output'/`dofile'.txt")
  project, creates("`output'/`dofile'.gph")
  project, creates("`output'/`dofile'.dta")
}


