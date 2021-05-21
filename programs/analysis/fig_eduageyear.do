***************************************************************************************************************
* fig_eduageyear.do
* outcome is share of people in the cohort who are college grads, in each year and at each age.
*
* Edit: 
* 4/10/18, JR: Reorganized to use same code for BA as for some college
* 4/16/18, JR: Minor edits to fix recession shading issue.
* 01/20/2020: NG:  Update to match with the new cohort and birthcohort variables 
*************************************************************************************************************** 

clear
cap project, doinfo
*cap err
if _rc==0 {
	local pdir "`r(pdir)'"						  	    // the project's main dir.
	local dofile "`r(dofile)'"						    // do-file's stub name
	local sig {bind:{hi:[`dofile'.dta. RP : `dofile'.do, `c(current_date)']}}	// a signature in notes
	local doasproject=1
}
else {
	local pdir "~/GRscarring"
	local dofile "fig_eduageyear"
	local doasproject=0
}

set more off
local rootdir "`pdir'"
local thisdir "`pdir'" 

local scratch "`pdir'/scratch"
local rawdata "`pdir'/rawdata"
local output "`pdir'/results"

if `doasproject'==1 {
	project, uses("`scratch'/combinecollapse_yc.dta")
}

set scheme s1color
/*
**************************************************************************
use `scratch'/combinecollapse_yc, clear

keep if age>=22 & age<=40 
isid birthcohort year 
*drop if year>=2018

*Group ages
recode age (22/23=22) (24/25=24) (26/27=26) (28/29=28) (30/max=30), gen(agegp)
label define agegp_l 22 "Age 22-23" 24 "Age 24-25" 26 "Age 26-27" 28 "Age 28-29"
label values agegp agegp_l  
*share that graduated from college
gen collegegrad=ed_ba + ed_grad
replace collegegrad=0 if collegegrad==.
gen collegesome=ed_scol + ed_ba + ed_grad
replace collegesome=0 if collegesome==.

drop if year<1979

  

collapse (mean) collegegrad collegesome ur_nat ur0_nat_22 ur0_nat_18 (rawsum) bigcpswgt bigcps_yc ///
        [aw=bigcpswgt], by(agegp year)

*gen cohort=year-agegp
keep if agegp<30
replace collegegrad=collegegrad*100
replace collegesome=collegesome*100

gen age2223_ba=collegegrad if agegp==22
gen age2425_ba=collegegrad if agegp==24
gen age2627_ba=collegegrad if agegp==26
gen age2829_ba=collegegrad if agegp==28
gen age2223_scol=collegesome if agegp==22
gen age2425_scol=collegesome if agegp==24
gen age2627_scol=collegesome if agegp==26
gen age2829_scol=collegesome if agegp==28

label var age2223_ba "Age 22-23"
label var age2425_ba "Age 24-25"
label var age2627_ba "Age 26-27"
label var age2829_ba "Age 28-29"
label var age2223_scol "Age 22-23"
label var age2425_scol "Age 24-25"
label var age2627_scol "Age 26-27"
label var age2829_scol "Age 28-29"


// Convert to monthly data to add recession shading
gen month=ym(year, 7)
tempfile base
save `base'
su month, meanonly
local fmonth=r(min)
local lmonth=r(max)
levelsof agegp
local agegps "`r(levels)'"
local ng=wordcount("`agegps'")
use `scratch'/recessionlist, clear
keep if month>=`fmonth'-6 & month<=`lmonth'+5
isid month
expand `ng'
sort month
gen agegp=.
forvalues g=1/`ng' {
  local w=word("`agegps'", `g')
  by month: replace agegp=`w' if _n==`g'
  }
merge 1:1 agegp month using `base'   
format month %tm
label values agegp agegp_l                  

//Figure percent graduated from college
twoway area recession month if agegp==22, yaxis(2) ytitle("", axis(2)) ylabel(none, axis(2)) color(gs13) fcolor(gs13) || ///
line age2223_ba age2425_ba age2627_ba age2829_ba month, yaxis(1) || ///
scatter collegegrad month if agegp==22 + (year-2009), mstyle(p1) yaxis(1) || ///
,  xlabel(246 "1980" 306 "1985" 366 "1990" 426 "1995" 486 "2000" 546 "2005" 606 "2010" 666 "2015" )  ///
   legend(order(2 3 4 5 6 "Cohort aged 22-23 in 2009")) ///
   ytitle("Percent Graduated from College") xtitle("Year") saving("`output'/`dofile'_college.gph", replace)

twoway area recession month if agegp==22, yaxis(2) ytitle("", axis(2)) ylabel(none, axis(2)) color(gs13) fcolor(gs13) || ///
line age2223_ba age2425_ba age2627_ba age2829_ba month, yaxis(1) || ///
scatter collegegrad month if agegp==22 + (year-2009), mstyle(p1) yaxis(1) || ///
,  xlabel(246 "1980" 306 "1985" 366 "1990" 426 "1995" 486 "2000" 546 "2005" 606 "2010" 666 "2015" )  ///
   legend(order(2 3 4 5 6 "Cohort aged 22-23 in 2009")) ///
   ytitle("Percent Graduated from College") xtitle("Year") saving("`output'/`dofile'_college.gph", replace)
   
twoway area recession month if agegp==22, yaxis(2) ytitle("", axis(2)) ylabel(none, axis(2)) color(gs13) fcolor(gs13) || ///
line age2223_scol age2425_scol age2627_scol age2829_scol month, yaxis(1) || ///
scatter collegesome month if agegp==22 + (year-2009), mstyle(p1) yaxis(1) || ///
,  xlabel(246 "1980" 306 "1985" 366 "1990" 426 "1995" 486 "2000" 546 "2005" 606 "2010" 666 "2015" )  ///
   legend(order(2 3 4 5 6 "Cohort aged 22-23 in 2009")) ///
   ytitle("Percent with some college or more") xtitle("Year") saving("`output'/`dofile'_somecollege.gph", replace)
*/   


use `scratch'/combinecollapse_yc, clear


keep if age>=22 & age<=40 
isid birthcohort year 
*drop if year>=2018

gen year22=birthcohort+22
*Group adjacent cohorts
gen year22_even=floor(year22/2)*2
keep if year22==year22_even   

gen collegegrad=ed_ba + ed_grad
gen collegesome=ed_scol + ed_ba + ed_grad
replace collegesome=0 if collegesome==.
collapse (mean) collegegrad collegesome (min) age [aw=bigcpswgt], by(year22_even year)
replace collegegrad=collegegrad*100 
replace collegesome=collegesome*100 

forvalues y=1980(2)2016 {
  gen ba_cohort`y'=collegegrad if year22_even==`y'
  gen sc_cohort`y'=collegesome if year22_even==`y'
}
/*   
*title("Share college graduates, by year and age (22-30)") 
twoway line  ba_cohort* year if age<=30, lstyle(p1 p2 p3 p4 p1 p2 p3 p4 p1 p2 p3 p4 p1 p2 p3 p4 p1 p2 p3) ///
                                         lpattern(solid solid solid solid dash dash dash dash ///
                                                  solid solid solid solid dash dash dash dash solid solid solid) || ///
scatter ba_cohort* year if age==30, mstyle(p1 p2 p3 p4 p1 p2 p3 p4 p1 p2 p3 p4 p1 p2 p3 p4 p1 p2 p3) || ///
scatter ba_cohort* year if age==24, mstyle(p1 p2 p3 p4 p1 p2 p3 p4 p1 p2 p3 p4 p1 p2 p3 p4 p1 p2 p3) ///
                                    msymbol(th th th th th th th th th th th th th th th th th th th) || ///
  , legend(order(1 "1980/1988/1996/2004/2012" 2 "1982/1990/1998/2006/2014" ///
                 3 "1984/1992/2000/2008/2016" 4 "1986/1994/2002/2010" 39 "Age 24" 20 "Age 30")) ///
    xtitle("Year") ytitle("Percent with BA") ///
    saving("`output'/`dofile'_college_alt.gph", replace)
*/

twoway line  ba_cohort* year if age<=30, lstyle(p1 p2 p3 p4 p1 p2 p3 p4 p1 p2 p3 p4 p1 p2 p3 p4 p1 p2 p3) ///
                                         lcolor(gray gray gray gray gray gray gray gray gray gray gray gray gray gray gray gray gray gray gray) ///
                                         lpattern(shortdash shortdash shortdash shortdash shortdash shortdash shortdash shortdash shortdash shortdash shortdash shortdash shortdash shortdash shortdash shortdash shortdash shortdash shortdash )|| ///
scatter collegegrad year if age==30 & year22_even>=1980, mstyle(p1 ) lstyle(p1) ///
        msize(small) connect(l) || ///
scatter collegegrad year if age==24 & year22_even>=1980, mstyle(p2) lstyle(p2) ///
        msize(small) msymbol(Th)  connect(l)  || ///
scatter collegegrad year if age==22 & year22_even>=1980, mstyle(p3) lstyle(p3) ///
         msymbol(X) connect(l) || ///
  , legend(order(22 "Age 22"  21 "Age 24" 20 "Age 30") cols(3)) ///
    xtitle("Year") ytitle("Percent with BA") ///
    saving("`output'/`dofile'_college.gph", replace)

twoway line  sc_cohort* year if age<=30, lstyle(p1 p2 p3 p4 p1 p2 p3 p4 p1 p2 p3 p4 p1 p2 p3 p4 p1 p2 p3) ///
                                         lcolor(gray gray gray gray gray gray gray gray gray gray gray gray gray gray gray gray gray gray gray) ///
                                         lpattern(shortdash shortdash shortdash shortdash shortdash shortdash shortdash shortdash shortdash shortdash shortdash shortdash shortdash shortdash shortdash shortdash shortdash shortdash shortdash )|| ///
scatter collegesome year if age==30 & year22_even>=1980, mstyle(p1 ) lstyle(p1) ///
        msize(small) connect(l) || ///
scatter collegesome year if age==24 & year22_even>=1980, mstyle(p2) lstyle(p2) ///
        msize(small) msymbol(Th)  connect(l)  || ///
scatter collegesome year if age==22 & year22_even>=1980, mstyle(p3) lstyle(p3) ///
         msymbol(X) connect(l) || ///
  , legend(order(22 "Age 22"  21 "Age 24" 20 "Age 30") cols(3)) ///
    xtitle("Year") ytitle("Percent with some college") ///
    saving("`output'/`dofile'_somecollege.gph", replace)


if `doasproject'==1 {
	project, creates(`output'/`dofile'_college.gph)
	project, creates(`output'/`dofile'_somecollege.gph)
	project, creates(`output'/`dofile'_college_alt.gph)
}
 



