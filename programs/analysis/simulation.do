

// Program to simulate the effect of a transitory increase in the unemployment rate,
// through various channels

set more off
eststo clear
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
	local dofile "simulation"
	local doasproject=0
}

set more off
local rootdir "`pdir'"
local thisdir "`pdir'"

local scratch "`pdir'/scratch"
local rawdata "`pdir'/rawdata"
local output "`pdir'/results"

if `doasproject'==1 {
	project, uses(`scratch'/runatc_coeffs.dta)
	project, uses(`output'/cohfxregs_cyclecoeffs.dta)
}
  
// Set up panel
 drop _all
 set obs 50
 gen cohort=_n
 sort cohort
 expand 19
 sort cohort
 by cohort: gen age=21+_n
 su age, meanonly
 assert r(max)==40 & r(min)==22 
 gen year = cohort + age - 22
 
 su cohort if year==21
 assert r(N)==19
 tempfile basepanel
 save `basepanel'
 
 cap program drop simshock
 program define simshock
   syntax, panel(string) coefficientdata(string) cyclicalitydata(string) model(string) depvar(string)
   // Read in coefficient estimates - theta and phi
   use "`coefficientdata'", clear
   keep if model=="`model'" & depvar=="`depvar'"
   sort ivartype cvname fvval
   count if ivartype=="Interaction" & cvname=="ur_st"
   if r(N)>0 {
     mkmat fvval b if ivartype=="Interaction" & cvname=="ur_st", matrix(theta)
   }
   else matrix theta=(0, 0 \ 2, 0 \ 4, 0 \ 6, 0 \ 8, 0)
   count if ivartype=="Interaction" & cvname=="ur0"
   if r(N)>0 {
     mkmat fvval b if ivartype=="Interaction" & cvname=="ur0", matrix(phi)
   }
   else matrix phi=(0, 0 \ 2, 0 \ 4, 0 \ 6, 0 \ 8, 0)
   
   matrix list theta
   matrix list phi
   forvalues i=0/4 {
     local phi`i'=el(phi,`i',2)*100
     local theta`i'=el(theta,`i', 2)*100
     di "Phi`i' is `phi`i''. Theta`i' is `theta`i''"
   }
   // Read in cyclicality coefficients
   use "`cyclicalitydata'", clear
   keep if model=="`model'" & depvar=="`depvar'"
   keep if samp=="preGR" & controls=="trend"
   su beta, meanonly
   assert r(N)==1
   local cyclic_time=r(mean)
   su delta, meanonly
   assert r(N)
   local cyclic_cohort=r(mean)

   // Model effects of a shock in year 21
   use `panel', clear
   local shockyear=21
   gen cohorteffects=0
   gen timeeffects=0
   gen scarring=0
   gen sensitivity=0
   replace cohorteffects = cohorteffects+(`cyclic_cohort') if cohort==`shockyear'
   replace timeeffects=timeeffects+(`cyclic_time') if year==`shockyear'
   replace scarring=scarring+`phi0' if cohort==`shockyear' & inlist(age, 22, 23)
   replace scarring=scarring+`phi1' if cohort==`shockyear' & inlist(age, 24, 25)
   replace scarring=scarring+`phi2' if cohort==`shockyear' & inlist(age, 26, 27)
   replace scarring=scarring+`phi3' if cohort==`shockyear' & inlist(age, 28, 29)
   replace scarring=scarring+`phi4' if cohort==`shockyear' & inlist(age, 30, 31)
   replace sensitivity=sensitivity+`theta0' if year==`shockyear' & inlist(age, 22, 23)
   replace sensitivity=sensitivity+`theta1' if year==`shockyear' & inlist(age, 24, 25)
   replace sensitivity=sensitivity+`theta2' if year==`shockyear' & inlist(age, 26, 27)
   replace sensitivity=sensitivity+`theta3' if year==`shockyear' & inlist(age, 28, 29)
   replace sensitivity=sensitivity+`theta4' if year==`shockyear' & inlist(age, 30, 31)

   // Now illustrate results
   collapse (sum) cohorteffects timeeffects scarring sensitivity, by(year)
   collapse (sum) cohorteffects timeeffects scarring sensitivity
   gen model="`model'"
   gen depvar="`depvar'"
 end 

 foreach depvar in empl rw_l {
   foreach mod in B C D E {
     tempfile mod`mod'_`depvar'
     simshock, panel("`basepanel'") coefficientdata("~/GRscarring/scratch/runatc_coeffs.dta") ///
               cyclicalitydata("~/GRscarring/results/cohfxregs_cyclecoeffs.dta") ///
               model("m`mod'1b") depvar("`depvar'")
     save `mod`mod'_`depvar''             
   }              
 }
 use `modB_empl'
 append using `modC_empl' `modD_empl' `modE_empl' `modB_rw_l' `modC_rw_l' `modD_rw_l' `modE_rw_l'
 outsheet using `output'/`dofile'.csv, replace comma
 
if `doasproject'==1 {
	project, creates(`output'/`dofile'.csv)
}
            