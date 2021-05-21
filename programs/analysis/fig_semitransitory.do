*
* Plots UR*age and UR0*age coefficients from models run by runatc.do.
*
* Based on fig_URfx.do, 5/18/18
* Edits:
* 5/22/18, RY: Added new topcoded annual earnings variable (to be used for main analysis)  
* 8/16/18, JR: Adjusted to accommodate normalization of effects for 10+ experience.
* 9/29/18, NR: Sort by model depvar cvname fvval instead of by model depvar fvval
* 1/21/19, NR: Adjusted yaxis (-0.8 to +0.2) and removed "yr" from xaxis labels
* 9/17/19, NG: Added and updated figures 
* 02/19/2020: NG:  Updated to keep only new figures used in the paper. 
* 				   See  GRscarring/archive/archive_20200216_161201/programs/analysis/old for a older and longer version of this program 
* 4/1/20, JR:  Rewritten completely

clear

cap project, doinfo
//cap notaproject
if _rc==0 {
	local pdir "`r(pdir)'"						  	    // the project's main dir.
	local dofile "`r(dofile)'"						    // do-file's stub name
	local sig {bind:{hi:[`dofile'.dta. RP : `dofile'.do, `c(current_date)']}}   // a signature in notes
	local doasproject=1
}
else {
	local pdir "~/GRscarring"
	local dofile "fig_semitransitory"
	local doasproject=0
}

set more off
local rootdir "`pdir'"
local thisdir "`pdir'"

local scratch "`pdir'/scratch"
local rawdata "`pdir'/rawdata"
local output "`pdir'/results"

if `doasproject'==1 {
	project, uses(`scratch'/extrapolate_coeffs.dta)
}

local depvars "empl rw_l log_pearnval_tc_r"
local wages "rw_l log_pearnval_tc_r"

set scheme s1color

use `scratch'/extrapolate_coeffs.dta, clear

keep if inlist(substr(model, 1, 2),"mC","mD","mE","mF") & ivartype=="Interaction"

** As of 10/24/17, when the regressions are run the unemployment rate (independent variable)
** is in percentage points, while binary dependent variables such as unemployment are in
** percent.
*Rescale for those outcomes where the dependent variable was measured in % but should be in p.p.
// if depvar=="labfor" | depvar=="empl" | depvar=="unem" | depvar=="livewithprnt" | ///
//    depvar=="married" | depvar=="lives_spouse_oth" | depvar=="chld_pr" {
// 	replace b=b*100 
// 	replace se=se*100
// }

isid model depvar cvname fvval
sort model depvar cvname fvval
by model depvar cvname: assert fvval==8 if _n==_N
expand 2 if fvval==8, gen(new)
replace fvval=10 if new==1
drop new
replace b=0 if fvval==10
replace se=0 if fvval==10


replace b=b*100 if inlist(depvar,"labfor", "empl", "unem", "livewithprnt", "married", "lives_spouse_oth", "chld_pr")
replace se=se*100 if inlist(depvar,"labfor", "empl", "unem", "livewithprnt", "married", "lives_spouse_oth", "chld_pr")

label def scarringpath 0 "0-1 year" 2 "2-3 years" 4 "4-5 years" 6 "6-7 years" 8 "8-9 years" 10 "10+ years"
label values fvval scarringpath

gen cil=b-2*se
gen ciu=b+2*se

*individual dependent variable graphs - excess sensitivity


rename fvval expcat
gen agecat=expcat
label define agecat_l 0 "22-23" 2 "24-25" 4 "26-27" 6 "28-29" 8 "30-31" 10 "32+"
label values agecat agecat_l

gen expcatA=expcat-0.1
gen expcatB=expcat+0.1
gen agecatA=agecat-0.1
gen agecatB=agecat+0.1

// One basic graph output
cap program drop makescarplot
program define makescarplot
  syntax, depvar(string) e(real) plotver(real) effecttype(string) ///
          xvar(string) modelseries(string) ///
          [name(string) saving(string) gphtitle(string) shift yscal(string) legpos(string)]
  
  if "`xvar'"=="agecat" {
    local xtitle "Age"
    local xlabels=`"0 "22-23" 2 "24-25" 4 "26-27" 6 "28-29" 8 "30-31" 10 "32+""'
  }
  else if "`xvar'"=="expcat" {
    local xtitle "Potential experience (years)"
    local xlabels=`"0 "0-1" 2 "2-3" 4 "4-5" 6 "6-7" 8 "8-9" 10 "10+""'
  }  
  else {
    di "Need to specify x variable"
    error
  }
  if "`shift'"=="shift" {
    local xvarA `xvar'A
    local xvarB `xvar'B
  }
  else {
    local xvarA `xvar'
    local xvarB `xvar'
  }
  if `"`gphtitle'"'==`""' {
    if "`depvar'"=="empl" {
      local gphtitle "A. Employment"
    }
    if "`depvar'"=="rw_l" {
      local gphtitle "B. Log wages"
    }
  }
    if "`depvar'"=="empl" {
      if "`yscal'"=="" local yscal "yscale(range(-1.1 0.4)) ylabel(-0.8 (0.4) 0.4)"
    }
    if "`depvar'"=="rw_l" {
      if "`yscal'"=="" local yscal "yscale(range(-0.023 0.01)) ylabel(-0.02 (0.01) 0.01)"
    }
    
  
  if `plotver'==1 { // Base plots for main paper -- models C and D, with alternative series
    if "`effecttype'" == "sensitivity" {
      local ytitle "Effect of contemporaneous UR"
      local altlegend "Controlling for scarring effects"
      local basemodel "mC`e'`modelseries'"
      local altcv "ur_st"
    }
    if "`effecttype'" == "scarring" {
      local ytitle "Effect of entry UR"
      local altlegend "Controlling for excess sensitivity effects"
      local basemodel "mD`e'`modelseries'"
      local altcv "ur0"
    }

    if "`legpos'"=="none" local legtext "legend(off)"
    else local legtext `"legend(order(2 4) label(2 "Base Model") label(4 "Model with scarring &" "sensitivity effects") rowgap(1) cols(1) ring(0) pos(`legpos'))"'
  	if `"`saving'"'~=`""' local savtext `"saving(`saving', replace)"'
  	if `"`name'"'~=`""' local nametext `"name(`name', replace)"'
  
      twoway rcap cil ciu `xvarA' if model=="`basemodel'" & depvar=="`depvar'"|| ///
             scatter b `xvarA' if model=="`basemodel'" & depvar=="`depvar'",  msymbol(X)  lstyle(p1) mstyle(p1) || ///
             rcap cil ciu `xvarB' if model=="mE`e'`modelseries'" & depvar=="`depvar'" & cvname=="`altcv'", mstyle(p2) lstyle(p2) || ///
             scatter b `xvarB' if model=="mE`e'`modelseries'" & depvar=="`depvar'" & cvname=="`altcv'", msymbol(Th) mstyle(p2)  ||, ///
               `legtext' ///
               title("`gphtitle'", pos(12)) ///
               xlabel(`xlabels') ///
               yline(0, lcolor(gray)) `yscal' ///
               xtitle(`xtitle') ytitle(`ytitle') ///
               `savtext' `nametext'
  }
  if `plotver'==2 { // Scarring model that includes both state and national unemployment rates
    if "`legpos'"=="none" local legtext "legend(off)"
    else local legtext `"legend(order(2 "State UR" 4 "National UR") cols(1) ring(0) pos(`legpos'))"'
    twoway rcap cil ciu `xvarA' if model=="mF1`modelseries'" & depvar=="`depvar'" & cvname=="ur0" || ///
           scatter b `xvarA' if model=="mF1`modelseries'" & depvar=="`depvar'" & cvname=="ur0", ///
                   msymbol(X) lstyle(p1) mstyle(p1) || ///
           rcap cil ciu `xvarB' if model=="mF1`modelseries'" & depvar=="`depvar'" & cvname=="ur0_nat", ///
                   mstyle(p2) lstyle(p2) || ///
           scatter b `xvarB' if model=="mF1`modelseries'" & depvar=="`depvar'" & cvname=="ur0_nat", ///
                   lstyle(p2) mstyle(p2) ||, ///
           `legpos' ///
               title("`gphtitle'", pos(12)) ///
               xlabel(`xlabels') ///
               yline(0) ylabel(`yscal') ///
               xtitle(`xtitle') ytitle(`ytitle') ///
               `savtext' `nametext'
  }       
end


 // Models:
     // A: No time:Just cohort, age, and state effects -- no time effects
     // B: Basic: Age-time-cohort + state FEs
     // C: Excess sensitivity: A-T-C + UR(t)*Agroups
     // D: Scarring: A-T-C + UR(0)*Agroups
     // E: Scarring. + excess sensitivity: A-T-C + UR(t)*Agroups + UR(0)*Agroups
    // F : Same as D but with interactions between age and both the state and national unemployment rates
     // b versions of each that include all cohorts
     // Zb: Just contrast between 2005/6 and 2010/11 cohorts (measured by age when 22).
     //a models: Main estimation sample, excluding recent cohorts
     //b models: Full sample
     //c models: Full sample, exclude <24.
     //d models: Main estimation sample, use national UR


 


// Base graphs for paper
  makescarplot, depvar(empl) e(1) plotver(1) effecttype(sensitivity) xvar(agecat) shift /// 
                modelseries(b) saving("`output'/`dofile'_sensitivity_empl.gph") legpos(none) ///
                name(sensitivity_empl) gphtitle("B. Employment - excess sensitivity")
  makescarplot, depvar(empl) e(1) plotver(1) effecttype(scarring) xvar(agecat) shift /// 
                modelseries(b) saving("`output'/`dofile'_scarring_empl.gph") legpos(none) ///
                name(scarring_empl) gphtitle("A. Employment - scarring")
  makescarplot, depvar(rw_l) e(1) plotver(1) effecttype(sensitivity) xvar(agecat) shift /// 
                modelseries(b) saving("`output'/`dofile'_sensitivity_rw_l.gph") legpos(none) ///
                name(sensitivity_rw_l) gphtitle("D. Log wages - excess sensitivity")
  makescarplot, depvar(rw_l) e(1) plotver(1) effecttype(scarring) xvar(agecat) shift /// 
                modelseries(b) saving("`output'/`dofile'_scarring_rw_l.gph") legpos(4) ///
                name(scarring_rw_l) gphtitle("C. Log wages - scarring")

graph combine scarring_empl sensitivity_empl scarring_rw_l sensitivity_rw_l

graph combine scarring_empl sensitivity_empl, saving(`output'/`dofile'_empl.gph, replace)
graph combine scarring_rw_l sensitivity_rw_l, saving(`output'/`dofile'_rw_l.gph, replace)


// Using just those from earlier cohorts
  makescarplot, depvar(empl) e(1) plotver(1) effecttype(sensitivity) xvar(agecat) shift /// 
                modelseries(a) legpos(4)  ///
                name(sensitivity_empl_older) gphtitle("B. Employment - excess sensitivity")
  makescarplot, depvar(empl) e(1) plotver(1) effecttype(scarring) xvar(agecat) shift /// 
                modelseries(a) legpos(none) ///
                name(scarring_empl_older) gphtitle("A. Employment- scarring")
  makescarplot, depvar(rw_l) e(1) plotver(1) effecttype(sensitivity) xvar(agecat) shift /// 
                modelseries(a) legpos(4)  ///
                name(sensitivity_rw_l_older) gphtitle("D. Log wages - excess sensitivity")
  makescarplot, depvar(rw_l) e(1) plotver(1) effecttype(scarring) xvar(agecat) shift /// 
                modelseries(a) legpos(none) ///
                name(scarring_rw_l_older) gphtitle("C. Log wages - scarring")
graph combine scarring_empl_older sensitivity_empl_older, saving(`output'/`dofile'_empl_older.gph, replace)
graph combine scarring_rw_l_older sensitivity_rw_l_older, saving(`output'/`dofile'_rw_l_older.gph, replace)

 
// Models that include both state and national URs
//foreach d in empl rw_l {
//  makescarplot, depvar(`d') e(1) plotver(2) effecttype(scarring) xvar(agecat) shift /// 
//                modelseries(b) saving("`output'/extras/`dofile'_scarring_`d'_natlUR.gph")
//}

foreach d in empl rw_l {
  if `doasproject'==1 {
    project, creates(`output'/`dofile'_sensitivity_`d'.gph)
    project, creates(`output'/`dofile'_scarring_`d'.gph)
    project, creates(`output'/`dofile'_`d'.gph)
    project, creates(`output'/extras/`dofile'_sensitivity_`d'_older.gph)
    project, creates(`output'/extras/`dofile'_scarring_`d'_older.gph)
    //project, creates(`output'/extras/`dofile'_scarring_`d'_natlUR.gph)
  }
}

*/