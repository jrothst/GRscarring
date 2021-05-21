clear
cap project, doinfo
//cap notaproject
if _rc==0 {
	local pdir "`r(pdir)'"						  	    // the project's main dir.
	local dofile "`r(dofile)'"						    // do-file's stub name
	local sig {bind:{hi:[`dofile'.dta. RP : `dofile'.do, `c(current_date)']}}	// a signature in notes
	local doasproject=1
}
else {
	local pdir "~/GRscarring"
	local dofile "miscstats"
	local doasproject=0
}

set more off
local rootdir "`pdir'"
local thisdir "`pdir'"

local scratch "`pdir'/scratch"
local rawdata "`pdir'/rawdata"
local output "`pdir'/results"

set scheme s1color

if `doasproject'==1 {
	project, uses(`scratch'/extrapolate_coeffs.dta)
	project, uses(`scratch'/runatc_coeffs.dta)
	project, uses(`scratch'/cohfxregs.dta)
	project, uses(`scratch'/fig_ur.dta)
	project, uses(`scratch'/fig_ur_age.dta)
	project, uses(`scratch'/extractcps.dta.gz)
	project, uses(`scratch'/extractorg_morg.dta.gz)
}

// The cohort that entered the labor market in 2010 has had an employment rate that, 
// averaged over its experience to date, is ## percentage points lower than what would
// have been expected based on prior cohorts’ age profiles and the state of the economy.
use `scratch'/extrapolate_coeffs
keep if depvar=="empl"
keep if ivartype=="FV" & fvname=="entrycohort" & model=="mB1b"
gen educ=real(substr(model,3,1))
keep if educ==1
replace b = b*100 if depvar=="empl"
rename fvval entrycohort
reg b entrycohort if entrycohort<2005
predict fvvalhat, xb
gen resid=b-fvvalhat
list entrycohort b fvvalhat resid


// The most recent cohorts have employment rates three to four percentage points lower 
// than what one would have anticipated based on the pre-2005 trend. 
use `scratch'/cohfxregs, clear
keep if depvar=="empl" & entrycohort<.
list entrycohort b  ur0 fitted_preGR_1 resid_preGR_1 if model=="mB1b"


// The headline unemployment rate rose by 5.6 percentage points between mid-2007 and late 
// 2009, while the prime-age (25-54) non-employment rate rose by over 5 percentage points 
// (Figure 2). 
use `scratch'/fig_ur, clear
list yearmo year mon ur_nat_s nonemploy_r nonemploy_r_sa_m7 if year>=2007 & year<=2009
su  ur_nat_s  if year>=2007 & year<=2009
di r(max)-r(min)
su  nonemploy_r  if year>=2007 & year<=2009
di r(max)-r(min)

// Unemployment began to recover in mid 2010 and declined roughly linearly, at a rate of 
// about 0.9 percentage points per year, thereafter.
list yearmo year mon ur_nat_s nonemploy_r nonemploy_r_sa_m7 if year>=2010 
reg ur_nat_s yearmo if yearmo>=ym(2010,7) & yearmo<=ym(2015,12)
di _b[yearmo]*12

// The unemployment rate was below 6% from the third quarter of 2014 and below its
// pre-recession level from late 2017. 
list yearmo year mon ur_nat_s nonemploy_r nonemploy_r_sa_m7 if year>=2010 & ur_nat_s<=6 & ur_nat_s>5 
list yearmo year mon ur_nat_s nonemploy_r nonemploy_r_sa_m7 if year>=2010 & ur_nat_s<=4.1
su ur_nat_s if yearmo>=ym(2014,12)
su ur_nat_s if yearmo>=ym(2017,12)

// Only half the decline in prime-age employment had been erased by the end of 2015; the
// employment rate did not recover its level prior to the recession until late 2019. 
su nonemploy_r if year>=2007 & year<=2010
list yearmo year mon ur_nat_s nonemploy_r nonemploy_r_sa_m7 if inlist(year, 2015, 2016)
list yearmo year mon ur_nat_s nonemploy_r nonemploy_r_sa_m7 if year>=2010 & nonemploy_r<0.207

  
// Young people fared particularly poorly. 
!zcat `scratch'/extractcps.dta.gz > `scratch'/extractcps.dta 
use year empl unem age wgt_composite yearmo if year>=2005 & age>=22 & age<=65 using `scratch'/extractcps.dta
collapse (mean) empl unem (rawsum) wgt_composite [aw=wgt_composite], by(yearmo age)
tempfile agemeans agegp0 agegp1 agegp2 agegp3 agegp4 agegp5 agegp6
save `agemeans'
gen agegp=0 if age>=22 & age<=40
replace agegp=5 if age>40 & age<=55
collapse (mean) empl unem [aw=wgt_composite], by(yearmo agegp)
save `agegp0'
use `agemeans'
gen agegp=1 if age>=22 & age<=30
replace agegp=2 if age>=31 & age<=40
collapse (mean) empl unem [aw=wgt_composite], by(yearmo agegp)
save `agegp1'
use `agemeans'
gen agegp=3 if age>=22 & age<=25
replace agegp=4 if age>=26 & age<=30
collapse (mean) empl unem [aw=wgt_composite], by(yearmo agegp)
save `agegp3'
use `agemeans'
gen agegp=6 if age>=25 & age<=54
keep if agegp<.
collapse (mean) empl unem [aw=wgt_composite], by(yearmo agegp)
save `agegp6'
use `agegp0'
append using `agegp1'
append using `agegp3'
append using `agegp6'
label def agegp_l 0 "22-40" 1 "22-30" 2 "31-40" 3 "22-25" 4 "26-30" 5 "40-55" 6 "25-54"
label values agegp agegp_l
save `scratch'/miscstats_agegpempl, replace
!rm `scratch'/extractcps.dta 

//Over the same period, the employment rate among 26-30-year-olds fell by more than 7 percentage points.  
use  `scratch'/miscstats_agegpempl, clear
list if yearmo>=ym(2007,1) & yearmo<=ym(2009,12) & agegp==4
su  empl if yearmo>=ym(2007,1) & yearmo<=ym(2009,12) & agegp==4
di r(max)-r(min)

//Employment of young workers was particularly slow to recover: by the end of 2014, 
//the 25-30-year-old employment rate remained 3.8 percentage points below its pre-recession 
//peak (as compared with 2.6 percentage points for all prime-age workers)
su empl if agegp==4 & yearmo>=ym(2003,1) & yearmo<=ym(2007,12)
local young_pre=r(max)
su empl if agegp==6 & yearmo>=ym(2003,1) & yearmo<=ym(2007,12)
local prime_pre=r(max)
su empl if agegp==4 & yearmo==ym(2014,7)
local young_post=r(mean)
su empl if agegp==6 & yearmo==ym(2014,7)
local prime_post=r(mean)
di "Change for 25-30 is " `young_post'-`young_pre'
di "Change for 25-54 is " `prime_post'-`prime_pre'
 
 
// Average real hourly wages did not fall during the recession, due to changes in the 
// composition of workers (Daly, Hobijn, and Wiles 2012). But they began to fall after 
// the recession ended, with a larger decline for younger workers, then recovered in 
// the later part of the recovery. 
!zcat `scratch'/extractorg_morg.dta.gz > `scratch'/extractorg_morg.dta 
use year yearmo rw_l age earnwt if year>=2005 & age>=22 & age<=65 using `scratch'/extractorg_morg.dta
collapse (mean) rw_l (rawsum) earnwt [aw=earnwt], by(yearmo age)
tempfile agemeans agegp0 agegp1 agegp2 agegp3 agegp4 agegp5 agegp6
save `agemeans'
gen agegp=0 if age>=22 & age<=40
replace agegp=5 if age>40 & age<=55
keep if agegp<.
collapse (mean) rw_l [aw=earnwt], by(yearmo agegp)
save `agegp0'
use `agemeans'
gen agegp=1 if age>=22 & age<=30
replace agegp=2 if age>=31 & age<=40
keep if agegp<.
collapse (mean) rw_l [aw=earnwt], by(yearmo agegp)
save `agegp1'
use `agemeans'
gen agegp=3 if age>=22 & age<=25
replace agegp=4 if age>=26 & age<=30
keep if agegp<.
collapse (mean) rw_l [aw=earnwt], by(yearmo agegp)
save `agegp3'
use `agemeans'
gen agegp=6 if age>=25 & age<=54
keep if agegp<.
collapse (mean) rw_l [aw=earnwt], by(yearmo agegp)
save `agegp6'
use `agegp0'
append using `agegp1'
append using `agegp3'
append using `agegp6'
label def agegp_l 0 "22-40" 1 "22-30" 2 "31-40" 3 "22-25" 4 "26-30" 5 "40-55" 6 "25-54"
label values agegp agegp_l
save `scratch'/miscstats_agegprw_l, replace
!rm `scratch'/extractorg_morg.dta 

use `scratch'/miscstats_agegprw_l, clear
gen year=year(dofm(yearmo))
drop if agegp==.
collapse (mean) rw_l, by(agegp year)
reshape wide rw_l, i(year) j(agegp)
list if year>=2006
su rw_l6 if inlist(year, 2009, 2013,2014)
di "Decline in wages for prime-age workers is " r(max)-r(min)
su rw_l1 if inlist(year, 2009, 2013,2014)
di "Decline in wages for 22-30 workers is " r(max)-r(min)

 
// Figure 3 shows non-employment and unemployment for college graduates aged 22-40. The 
// unemployment rate rose by 150% between early 2007 and late 2009, while the non-employment 
// rate rose from 14% in January 2007 to 18% in December 2012
use `scratch'/fig_ur_age, clear
list yearmo unem_sa_m7 empl_sa_m7 if yearmo>=ym(2007,1) & agegp==0 & yearmo<=ym(2011,12)
su unem_sa_m7 if yearmo>=ym(2007,1) & agegp==0 & yearmo<=ym(2009,12)
di "Increase in unem rate was " r(max)/r(min)
list yearmo empl_sa_m7 if agegp==0 & inlist(yearmo, ym(2007,1), ym(2014,12))
//Employment recovered somewhat more quickly for young graduates than for the prime-age 
// labor force as a whole, but nevertheless did not achieve its level on the eve of the 
//recession until mid 2018
list yearmo empl_sa_m7 if agegp==0 & yearmo>=ym(2014,12) & yearmo<=ym(2018,12)

//Figure 4 shows the graduate employment series separately for younger and older graduates. 
//The decline in employment was about #twice# as large for the youngest graduates as for 
//older graduates, and was much more persistent. On the eve of the recession young 
//graduates had similar employment rates to older graduates, as they did at the previous
//business cycle peak, but have been persistently lower since the recession’s onset. 
//Even in the most recent data, younger graduates’ employment rates are about three 
//percentage points lower than those of older graduates.
su empl_sa_m7 if yearmo>=ym(2007,1) & yearmo<=ym(2014,12) & agegp==1
di "Decline in emp for younger graduates is " r(max)-r(min)
su empl_sa_m7 if yearmo>=ym(2007,1) & yearmo<=ym(2014,12) & agegp==2
di "Decline in emp for older graduates is " r(max)-r(min)
collapse (mean) empl, by(year agegp)
reshape wide empl, i(year) j(agegp)
list if year>=2007


//Age-adjusted employment rates fell gradually across cohorts entering from 1975 through 
//around 2004, with the total decline amounting to around 2.5 percentage points. There was 
//then an additional 1.8 percentage point decline between the 2004 and 2010 entrants, 
//with stability thereafter.
use `scratch'/extrapolate_coeffs.dta, clear
keep if depvar=="empl"
keep if ivartype=="FV" & fvname=="entrycohort"
drop if fvval==2019
reg b fvval if fvval>=1979 & fvval<=2004 & model=="mA1b"
predict bhat1
list fvval b bhat1 if model=="mA1b"

//It also shows a clear trend break in the 2000-2004 period.  A model with a linear trend 
//and single trend break fits best when the break is in 2003, but breaks placed in any 
//year from 2000 to 2006 all fit nearly as well.
forvalues y=1995/2015 {
  gen break=max(0,fvval-`y')
  qui reg b fvval break if fvval>=1970 & model=="mB1b"
  local fit=e(r2)
  di "Break at `y': R2=`fit'"
  drop break
}
//Across the 18 cohorts since the 2000 entrants, cohort effects have fallen nearly five 
//percentage points (relative to the 1984-2000 trend), with no sign that the downward 
//trend stabilized after the Great Recession.
list fvval b if model=="mB1b"


//Cohorts that enter the labor market when the state’s unemployment rate is elevated by 
//1% have employment probabilities that are reduced by 0.7 percentage points at ages 22 
//and 23, 0.5 percentage points at 24 and 25, and about 0.2 percentage points at 26 and 
//27, after which the effect fades away. 
use `scratch'/runatc_coeffs, clear
list if ivartype=="Interaction" & model=="mD1b" & depvar=="empl"
list if cvname=="dur0" & model=="mD1b" & depvar=="empl"
//A 1 percentage point higher unemployment rate in the year of entry reduces wages by 
//about 1.1% at age 22-23, 1% at 24-25, 0.4% at 26-29, and 0.1% (not significant) at 30-31.
list if ivartype=="Interaction" & model=="mD1b" & depvar=="rw_l"
list if cvname=="dur0" & model=="mD1b" & depvar=="rw_l"
//Perhaps the most notable aspect of Figure 9 is that the sharp decline in cohort 
//employment rates for the most recent cohorts is largely robust to the choice of 
//controls....Across all four specifications, employment rates for the 2016 entrants 
//are more than #5 percentage points below the 1990s trend.
list if ivartype=="FV" & depvar=="empl" & fvname=="entrycohort" & ///
        inlist(model, "mB1b", "mC1b", "mD1b", "mE1b") & fvval==2017
//In the baseline decomposition we see a sharp drop in wages, about 2 percent, for the 
//2009 entrants, with smaller reductions in 2007 and 2008. 
list if ivartype=="FV" & depvar=="rw_l" & fvname=="entrycohort" & ///
        inlist(model, "mB1b") & fvval>=2005 & fvval<=2017
//The 2011 and subsequent cohorts have wages about 2% higher, on average, than earlier
// cohorts, after adjusting for normal early career scarring effects.        
list if ivartype=="FV" & depvar=="rw_l" & fvname=="entrycohort" & ///
        inlist(model, "mB1b", "mC1b", "mD1b", "mE1b") & fvval>=2011 & fvval<=2017


use `scratch'/cohfxregs, clear
list model entrycohort b fitted_preGR_1 resid_preGR_1 if depvar=="empl" & model=="mB1b" ///
          & entrycohort>=2007 & entrycohort<.
list model entrycohort b fitted_preGR_1 resid_preGR_1 if depvar=="empl" & model=="mE1b" ///
          & entrycohort>=2007 & entrycohort<.

if `doasproject'==1 {
  project, creates(`scratch'/`dofile'_agegprw_l.dta)
  project, creates(`scratch'/`dofile'_agegpempl.dta)
}