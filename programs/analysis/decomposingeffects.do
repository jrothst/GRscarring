

* Program to make a csv with base model estimates for use in decomposing the effect of a 
* transitory increase in the unemployment rate

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
	local dofile "decomposingeffects"
	local doasproject=0
}
 
 
local rootdir "`pdir'"
local thisdir "`pdir'"

local scratch "`pdir'/scratch"
local rawdata "`pdir'/rawdata"
local output "`pdir'/results"


use `scratch'/extrapolate_coeffs, clear

keep if inlist(model, "mB1b", "mC1b", "mD1b", "mE1b")
keep if inlist(depvar, "empl", "rw_l")
keep if ivartype=="Interaction"

gen phi_ur0=b if cvname=="ur0"
gen theta_ur=b if cvname=="ur_st"
sort depvar model cvname fvval
list depvar model cvname fvval phi_ur0 theta_ur se

err



gen depmod=depvar+"_"+model

egen groupi=group(ivartype cvname fvname fvval), missing
keep ivartype cvname fvname fvval  b groupi depmod
reshape wide b, i(groupi) j(depmod) string

err

keep if inlist(cvname, "dur", "dur0")

gen b_ur=b if cvname=="dur"
gen b_ur0=b if cvname=="dur0"

list
err
drop groupi
gen grouping=1 if 