* Show robustness to using quadratic in education fraction rather than IMR
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
	local dofile "fig_imr"
	local doasproject=0
}

set more off
local rootdir "`pdir'"
local thisdir "`pdir'"

local scratch "`pdir'/scratch"
local rawdata "`pdir'/rawdata"
local results "`pdir'/results"

if `doasproject'==1 {
	project, uses(`scratch'/runatc_coeffs.dta)
}

local depvars "empl rw_l log_pearnval_tc_r"
local wages "rw_l log_pearnval_tc_r"

set scheme s1color


use `scratch'/runatc_coeffs, clear

keep if inlist(model, "mC1b", "mD1b", "mE1b", "mC1d", "mD1d", "mE1d") & ivartype=="Interaction"
keep if depvar=="empl"

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

gen agecatA=agecat-0.15
gen agecatB=agecat-0.05
gen agecatC=agecat+0.05
gen agecatD=agecat+0.15

twoway rcap cil ciu agecatA if model=="mD1b" & cvname=="ur0", lstyle(p1) mstyle(p1) ||  ///
          scatter b agecatA if model=="mD1b" & cvname=="ur0", lstyle(p1) mstyle(p1) || ///
       rcap cil ciu agecatB if model=="mD1d" & cvname=="ur0", lstyle(p2) mstyle(p2) ||  ///
          scatter b agecatB if model=="mD1d" & cvname=="ur0", lstyle(p2) mstyle(p2) || ///
       rcap cil ciu agecatC if model=="mE1b" & cvname=="ur0", lstyle(p3) mstyle(p3) ||  ///
          scatter b agecatC if model=="mE1b" & cvname=="ur0", lstyle(p3) mstyle(p3) || ///
       rcap cil ciu agecatD if model=="mE1d" & cvname=="ur0", lstyle(p4) mstyle(p4) ||  ///
          scatter b agecatD if model=="mE1d" & cvname=="ur0", lstyle(p4) mstyle(p4) || ///
       , legend(order(2 4 6 8) label(2 "Base, IMR") label(4 "Base, quadratic") ///
                label(6 "Expanded, IMR") label(8 "Expanded, quadratic") colfirst) ///
         title("Sensitivity of scarring effects to selection control") ///
         xlabel(0 "0-1" 2 "2-3" 4 "4-5" 6 "6-7" 8 "8-9" 10 "10+") ///
         yline(0, lcolor(gray)) ///
         xtitle("Age") ytitle("Effect of entry UR") ///
         saving("`results'/`dofile'_scarring.gph", replace)

twoway rcap cil ciu agecatA if model=="mC1b" & cvname=="ur_st", lstyle(p1) mstyle(p1) || ///
          scatter b agecatA if model=="mC1b" & cvname=="ur_st", lstyle(p1) mstyle(p1) || ///
       rcap cil ciu agecatB if model=="mC1d" & cvname=="ur_st", lstyle(p2) mstyle(p2) || ///
          scatter b agecatB if model=="mC1d" & cvname=="ur_st", lstyle(p2) mstyle(p2) || ///
       rcap cil ciu agecatC if model=="mE1b" & cvname=="ur_st", lstyle(p3) mstyle(p3) ||  ///
          scatter b agecatC if model=="mE1b" & cvname=="ur_st", lstyle(p3) mstyle(p3) || ///
       rcap cil ciu agecatD if model=="mE1d" & cvname=="ur_st", lstyle(p4) mstyle(p4) ||  ///
          scatter b agecatD if model=="mE1d" & cvname=="ur_st", lstyle(p4) mstyle(p4) || ///
       , legend(order(2 4 6 8) label(2 "Base, IMR") label(4 "Base, quadratic") ///
                label(6 "Expanded, IMR") label(8 "Expanded, quadratic") colfirst) ///
         title("Sensitivity of sensitivity effects to selection control") ///
         xlabel(0 "0-1" 2 "2-3" 4 "4-5" 6 "6-7" 8 "8-9" 10 "10+") ///
         yline(0, lcolor(gray)) ///
         xtitle("Age") ytitle("Effect of contemp. UR") ///
         saving("`results'/`dofile'_sensitivity.gph", replace)
         



local depvars "empl"
use `scratch'/runatc_coeffs, clear
gen keep=.
foreach v of local depvars {
  replace keep=1 if depvar=="`v'"
}
keep if keep==1
drop keep
keep if ivartype=="FV" & fvname=="entrycohort"
replace b = b*100 if depvar=="empl"
rename fvval entrycohort
gen educ=real(substr(model,3,1))
tempfile coeffs
save `coeffs'
	gen month=ym(entrycohort, 7)

	*Drop observations from before the 1978 birthcohort
*	drop if month<ym(1978,7)
	drop if month<ym(1970,1)
	
	*Drop observations from the last cohort, for which we have only a single observation
	 *For now (4/16/2020), this is 2019 for bigcps outcomes, 2019 for MORG, and 2017 for March
	 *Note that code is for specific dependent variables -- all others are set to missing
	 *for safety
	 drop if depvar=="empl" & month>ym(2018,12)
	 drop if depvar=="rw_l" & month>ym(2018,12)
	 drop if depvar=="log_pearnval_tc_r" & month>=ym(2016,7)
	 drop if !inlist(depvar, "empl", "rw_l", "log_pearnval_tc_r") & !inlist(model,"recession", "means")

    gen zero=0 
  
// Baseline cohort graphs -- show the importance of A-T-C decomposition
    twoway line b month if model=="mB1b" & depvar=="empl", lstyle(p1) lpattern(solid)  yaxis(1) || ///
           line b month if model=="mC1b" & depvar=="empl", lstyle(p2) lpattern(solid)  yaxis(1) || ///
           line b month if model=="mD1b" & depvar=="empl", lstyle(p3) lpattern(solid)  yaxis(1) || ///
           line b month if model=="mE1b" & depvar=="empl", lstyle(p4) lpattern(solid)  yaxis(1) || ///
           line zero month if model=="mB1b" & depvar=="empl", lpattern(dot) lcolor(black) || ///
  		   , xlabel( 126 "1970" 246 "1980" 366 "1990" 486 "2000" 606 "2010" 726 "2020" )  ///
		     legend(order(2 "Baseline" 3 "Excess sensitivity" 4 "Scarring" 5 "Excess sensitivity and scarring") cols(1) ring(0) pos(7)) ///
		     ytitle("Employment rate (%, 1984=0)") xtitle("Entry cohort") ///
		 	 title("IMR control", size(medsmall)) ///
  		     name(imr, replace) nodraw
    twoway line b month if model=="mB1d" & depvar=="empl", lstyle(p1) lpattern(solid)  yaxis(1) || ///
           line b month if model=="mC1d" & depvar=="empl", lstyle(p2) lpattern(solid)  yaxis(1) || ///
           line b month if model=="mD1d" & depvar=="empl", lstyle(p3) lpattern(solid)  yaxis(1) || ///
           line b month if model=="mE1d" & depvar=="empl", lstyle(p4) lpattern(solid)  yaxis(1) || ///
           line zero month if model=="mB1b" & depvar=="empl", lpattern(dot) lcolor(black) || ///
  		   , xlabel( 126 "1970" 246 "1980" 366 "1990" 486 "2000" 606 "2010" 726 "2020" )  ///
		     legend(order(2 "Baseline" 3 "Excess sensitivity" 4 "Scarring" 5 "Excess sensitivity and scarring") cols(1) ring(0) pos(7)) ///
		     ytitle("Employment rate (%, 1984=0)") xtitle("Entry cohort") ///
		 	 title("Quadratic selection control", size(medsmall)) ///
  		     name(quad, replace) nodraw
  	graph combine imr quad, title("ATC decompositions - alternate controls") ///
  	      saving("`results'/`dofile'_cohortfx.gph", replace)


if `doasproject'==1 {
  project, creates("`results'/`dofile'_scarring.gph")
  project, creates("`results'/`dofile'_sensitivity.gph")
  project, creates("`results'/`dofile'_cohortfx.gph")
}
