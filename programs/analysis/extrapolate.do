// Program to extrapolate regressions estimated on a subset of the data to what they
// imply for other parts. Specifically, I fit various forms of age-time-cohort regressions
// in "runatc.do" that use only data from the 1954-1978 birth cohorts. Using the age and 
// time coefficients (and other auxiliary coefficients, such as unemployment rate*age
// interactions) from these regressions, what are the implied cohort effects for later cohorts?

// Jesse Rothstein
// 9/11/2017

// Modified 9/13/17, JR: Add code for new model m0.
//  4/16/18, JR: Adjusted march variable list. Needs to be adjusted again once march read file is fixed.
//  4/30/18, JR: Edited to conform to new runatc.
//  5/22/18, RY: Added new topcoded annual earnings variable (to be used for main analysis)  
//  6/1/18, JR:  Adjusted to handle new "c" models from runatc.
//  8/16/18, JR: Adjusted to handle new "d" models from runatc.
//  9/11/19, NG: Adjusted to handle the new cohort definition (lines 209 & 219)
// NG 01/20/2020: Edit, new name for the cohort variable (entrycohort) and new variable for the birth year (birthcohort)

// NOTES:
//  Need to adjust threshold for zero mean residuals once the variables have been 
//  normalized to a reasonable scale.


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
	local dofile "extrapolate"
	local doasproject=0
}

set more off
local rootdir "`pdir'"
local thisdir "`pdir'"

local prepdata "`pdir'/scratch"
local rawdata "`pdir'/rawdata"
local output "`pdir'/scratch"

/* 
local depvarscps "empl unem labfor married hourslw hourslw_pos uhours livewithprnt chld_pr educ_occup lives_spouse_oth"
//local depvarsmar "employed_ly ann_inc ann_ern ann_inc_pos ann_ern_pos log_ann_ern log_ann_inc wkswork wkswork_pos hrswk_ly hrswk_ly_pos"
//local depvarsmar "pearnval_r pearnval_r_tc lpearnval_r lpearnval_r_tc posearn"
local depvarsmar "earn_r_pos earn_r_pos_tc log_earn_r_pos log_earn_r_pos_tc inc_r_pos inc_r_pos_tc log_inc_r_pos log_inc_r_pos_tc wkswork wkswork_pos"
local depvarsorg "paidhre w_nber w_no_no uhourse wage_jr rw rw_l rw_nber wage_occup log_wk_ern"
*/
local depvarscps "empl"
local depvarsmar "log_pearnval_tc_r"
local depvarsorg "rw_l"

local modellist "A B C D E F"
local educlist "0 1"
local sufflist "a b c"

if `doasproject'==1 {
	project, uses("`prepdata'/runatc_fitted.dta")
	project, uses("`prepdata'/runatc_coeffs.dta")
}

use `prepdata'/runatc_fitted, clear // These data are year-entrycohort-state

// Get a list of variables, by looking at all of the form mA0_*_xb
foreach v of varlist mA0a_*_xb {
  local l=strlen("`v'")
  local vstub=substr("`v'", 6, `l'-8)
  di "`v' turns to `vstub'"
  local dvlist "`dvlist' `vstub'"
}
 
// Check which weight to use 
foreach v of local dvlist {
   // Assign weights to variables
    foreach w of local depvarscps {
      if "`v'"=="`w'" local w_`v'="bigcpswgt"
    }
    foreach w of local depvarsmar {
      if "`v'"=="`w'" local w_`v'="marchwgt"
    }
    foreach w of local depvarsorg {
      if "`v'"=="`w'" local w_`v'="orgwgt"
    }
  if "`w_`v''"=="" {
    local w_`v'="UNDEFINED"
    di "Variable `v' has undefined weight -- error."
    err
  }  
  di "For variable `v', weight is `w_`v''"
} 
keep bigcpswgt marchwgt orgwgt entrycohort estsamp educ2 m*xb m*samp `dvlist' 

// Make residuals
foreach v of local dvlist {
  foreach m of local modellist {
    foreach e of local educlist {
      foreach sufflet of local sufflist { // Note that the "b" models use all data so this is just a check.k
        if "`sufflet'"~="d" | inlist("`m'","C","D","E") {
          gen double m`m'`e'`sufflet'_`v'_resid=`v'-m`m'`e'`sufflet'_`v'_xb if educ2==`e'
          if "`w_`v''"=="bigcpswgt" {
            rename m`m'`e'`sufflet'_`v'_resid cps_m`m'`e'`sufflet'_`v'_resid
            rename m`m'`e'`sufflet'_`v'_samp cps_m`m'`e'`sufflet'_`v'_samp
          }
          if "`w_`v''"=="marchwgt" {
            rename m`m'`e'`sufflet'_`v'_resid mar_m`m'`e'`sufflet'_`v'_resid
            rename m`m'`e'`sufflet'_`v'_samp mar_m`m'`e'`sufflet'_`v'_samp
          }
          else if "`w_`v''"=="orgwgt" {
            rename m`m'`e'`sufflet'_`v'_resid org_m`m'`e'`sufflet'_`v'_resid
            rename m`m'`e'`sufflet'_`v'_samp org_m`m'`e'`sufflet'_`v'_samp
          }
        }
      }
    }
  }
}  
tempfile tocollapse extrapcps extrapmar extraporg
save `tocollapse'

//Make cohort-level means
collapse (mean) cps_m*_*_resid (max) cps_m*_*_samp [aw=bigcpswgt], by(entrycohort)
gen keep=0
foreach m of local modellist {
  foreach e of local educlist {
    foreach s of local sufflist {
      if "`s'"~="d" | inlist("`m'","C","D","E") {
        foreach v of local depvarscps {
          assert inlist(cps_m`m'`e'`s'_`v'_samp, 0, 1)
          cap assert abs(cps_m`m'`e'`s'_`v'_resid)<1e-9 if cps_m`m'`e'`s'_`v'_samp==1
          if _rc~=0 & "`s'"!="c" {
            di "Error: Got non-zero residuals in sample for variable `v'"
            di "Model `m', educ `e', suffix `s'"
            error
          }
          qui replace cps_m`m'`e'`s'_`v'_resid=. if cps_m`m'`e'`s'_`v'_samp==1
          qui replace keep=1 if cps_m`m'`e'`s'_`v'_samp==0 
        }
      }
    }
  }
}
keep if keep==1
drop keep
drop *_samp
rename cps_m*_resid m*
save `extrapcps'

use `tocollapse', clear
collapse (mean) mar_m*_*_resid (max) mar_m*_*_samp [aw=marchwgt], by(entrycohort)
gen keep=0
foreach m of local modellist {
  foreach e of local educlist {
    foreach s of local sufflist {
      if "`s'"~="d" | inlist("`m'","C","D","E") {
        foreach v of local depvarsmar {
          assert inlist(mar_m`m'`e'`s'_`v'_samp, 0, 1)
          cap assert abs(mar_m`m'`e'`s'_`v'_resid)<1e-9 if mar_m`m'`e'`s'_`v'_samp==1
          if _rc~=0 & "`s'"~="c" {
            di "Error: Got non-zero residuals in sample for variable `v', with m/e/s=`m'/`e'/`s'"
            error
          }
          qui replace mar_m`m'`e'`s'_`v'_resid=. if mar_m`m'`e'`s'_`v'_samp==1
          qui replace keep=1 if mar_m`m'`e'`s'_`v'_samp==0 
        }
      }
    }
  }
}
keep if keep==1
drop keep
drop *_samp
rename mar_m*_resid m*
save `extrapmar'

use `tocollapse', clear
collapse (mean) org_m*_*_resid (max) org_m*_*_samp [aw=orgwgt], by(entrycohort )
gen keep=0
foreach m of local modellist {
  foreach e of local educlist {
    foreach s of local sufflist {
      if "`s'"~="d" | inlist("`m'","C","D","E") {
        foreach v of local depvarsorg {
          assert inlist(org_m`m'`e'`s'_`v'_samp, 0, 1)
          cap assert abs(org_m`m'`e'`s'_`v'_resid)<1e-9 if org_m`m'`e'`s'_`v'_samp==1
          if _rc~=0 & "`s'"~="c" {
            di "Error: Got non-zero residuals in sample for variable `v', with m/e/s=`m'/`e'/`s'"
            error
          }
          qui replace org_m`m'`e'`s'_`v'_resid=. if org_m`m'`e'`s'_`v'_samp==1
          qui replace keep=1 if org_m`m'`e'`s'_`v'_samp==0 
        }
      }
    }
  }
}
   
keep if keep==1
drop keep
drop *_samp
rename org_m*_resid m*
save `extraporg'

use `extrapcps'
merge 1:1 entrycohort using `extrapmar', nogen
merge 1:1 entrycohort using `extraporg', nogen

// NG,  9/19: update to adapt to the newt cohort definition
* Non-college was originally the 1952 birth cohort. Add 18 -> 1970
foreach v of varlist m?0b* { // check that these "extra" cohort effects are zero.
  cap assert abs(`v')<1e-9  if `v'<. & entrycohort>=1970 /*& year!=2019*/
  if _rc~=0 {
    di "Error: Got non-zero residuals for variable `v'"
    error
  }
}   

// NG,  9/19: update to adapt to the newt cohort definition
//  College was originally the 1948 birth cohort. Add 22 -> 1970
foreach v of varlist m?1b* { // check that these "extra" cohort effects are zero.
  cap assert abs(`v')<1e-9  if `v'<. & entrycohort>=1970 /*& year!=2019 & cohort<=1995 */
  if _rc~=0 {
    di "Error: Got non-zero residuals for variable `v'"
    error
  }
}   
tempfile extrap
save `extrap'

//Clean up these data to augment runatc_coeffs
 local first=1
 tempfile extrapcoeffs
 foreach v in `dvlist' {
   foreach m of local modellist { // Note that the "b" models use all data so no need to bother.
     foreach e of local educlist {
       use entrycohort m`m'`e'a_`v' using `extrap', clear
       keep if m`m'`e'a_`v'<.
       gen model="m`m'`e'a"
       gen depvar="`v'"
       gen ivartype="FV"
       gen fvname="entrycohort"
       rename m`m'`e'a_`v' b
       rename entrycohort fvval
       gen ivartxt=string(fvval)+"e.`v'"
       gen extrapolate=1
       tempfile coeffs_`m'`e'_`v'
       save `coeffs_`m'`e'_`v''
     
       if `first'==1 save `extrapcoeffs'
       else {
         append using `extrapcoeffs'
         save `extrapcoeffs', replace
       }
       local first=0
     }
   }
 }
use `prepdata'/runatc_coeffs
gen extrapolate=0
replace model=model+"a" if length(model)==3
append using `extrapcoeffs'
duplicates report model depvar ivartype cvname fvname fvval
assert r(N)==r(unique_value)
save `output'/extrapolate_coeffs, replace

// Now lets go back to the fitted data and fix those as well.
use `prepdata'/runatc_fitted
*rename m??_* m??a_*
tempfile runatc
save `runatc'

use `extrap'
drop m??b_*
rename m* m*_cohfx
merge 1:m entrycohort using `runatc'
assert estsamp==1 if _merge==2
drop _merge
foreach v in `dvlist' {
  foreach m of local modellist {
    foreach e of local educlist {
      gen m`m'`e'a_`v'_xb_extrap=m`m'`e'a_`v'_xb
      replace m`m'`e'a_`v'_xb_extrap=m`m'`e'a_`v'_xb_extrap+m`m'`e'a_`v'_cohfx if m`m'`e'a_`v'_cohfx<.
      drop m`m'`e'a_`v'_cohfx
    }
  }  
}     
isid entrycohort year fipsst age educ2
save `output'/extrapolate_fitted, replace


if `doasproject'==1 {
	project, creates(`output'/extrapolate_coeffs.dta)
	project, creates(`output'/extrapolate_fitted.dta)
}




