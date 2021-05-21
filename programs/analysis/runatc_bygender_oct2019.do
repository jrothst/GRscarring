***************************************************************************************************************
* runatc_v4.do
* Runs and stores coefficients for various models to explain age-time-cohort-state variation
* in outcomes. All models are run on the "ycas" data, collapsed to the year-cohort-age-state
* level.
*
* Models:
*     // 0: Just cohort, age, and state effects -- no time effects
*     // 1: Age-time-cohort + state FEs
*     // 2: Age - cohort - UR(t)
*     // 3: A-T-C + UR(t)*Agroups (excluding one)
*     // 4: A-T-C + UR(0)*Agroups
* Each model is run once using just the cohorts born in or before 1978, and once
* using all cohorts. The latter are indexed with "b". The former models are extrapolated
* to all cohorts in a subsequent program, extrapolate.
*
* In addition, this program draws contrasts between the cohorts that turned 22 in 2005-6 and
* in 2010-11, for each of the ten models above as well as for an even simpler model that
* includes just those four cohorts and has no controls.
*
* Jesse Rothstein, Oct. 9, 2017
* Revision from runatc_v3.do, to add the binary contrast and simpler model.
* Revisions from runatc_v4.do, adds model 5
* 4/10/18, JR: Add models 6 and 7, with constraints. 
*              Switch to using ur0 in place of ur0_st
*              Explicitly limit sample for all models to birth cohorts 1954-forward
* 4/11/18, JR: Disabled production of coefficients table, as it was crashing within project
*                for some reason. It can still be created by running outside of project.
*              Removed main effects from interacted models.
* 4/16/18, JR: Adjusted march variable list. Needs to be adjusted again once march read file is fixed.
* 4/20/18, RY, Adjusted march variable list to match the new March variables.
* 4/30/18, JR: Edit to:
*              - Estimate just a few variables
*              - Estimate many fewer models
*              - Loop over the two education categories.
*  RY, 5/22/18: Added new topcoded annual earnings variable (to be used for main analysis)  
* 6/1/18, JR: Add a model E with both excess sensitivity and scarring.
*             Add inverse mills ratio control to regressions.
*             Add a "c" series of models that exclude those under 25 (21 for non-college)
* 6/14/18, JR: Modify UR*experience and UR0*experience interactions so that the last
*                 experience category is interacted with the deviation from the national
*                 unemployment rate rather than the unadjusted state unemployment rate --
*                 this ensures that the effect of the national UR/UR0 is captured by
*                 the time/cohort effects.
* 8/16/18, JR: Undo 6/14/18 change. Now the last experience category is excluded, and we 
*                 include a main effect for the deviation of the state from the national 
*                 UR/UR0. This should (a) allow the time and cohort effects to pick up the
*                 effect of the national rate and (b) allow the experience-UR/UR0 
*                 interactions to be relative to the 10+ experience group.
*              Also added "d" series of models (C,D,E only) that use the national rather
*                 than the state UR for excess sensitivity/scarring.
* 9/28/18, JR: Drop observations with missing weights from all three samples.
*              Also drop cohorts turning 18/22 in 2018, for whom UR0 is not available.
* 10/3/18, JR: Adjust model C?d to have just the national rate, not also the deviation
*                of the state rate. This aligns better with model D?d, and I think fixes
*                an oversight in earlier edits.
* 04/15/19, SR: Added  
***************************************************************************************************************

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
	local dofile "runatc_bygender"
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
	project, uses("`prepdata'/combinecollapse_yca2ss.dta")
}

cap program drop fvreg
program define fvreg
 // A program to run an OLS regression, which may include factor variables and/or
 //   factor/continuous interactions, and make a data set of the results
  syntax varlist (min=2 numeric fv) [if] [in] [aw pw fw], ///
            [outfile(string) model(string) preserve noisily quietly eststo(name) ///
             constraints(string) *]
  // Default is to list the regression output but run the rest quietly
  if "`noisily'"=="" local qui "qui"
  
  // Run the regression
  if `"`constraints'"'==`""' {
    di `"Model `model': `quietly' reg `varlist' `if' `in' [`weight'`exp'], `options'"'
    `quietly' reg `varlist' `if' `in' [`weight'`exp'], `options'
  }
  else {
    di `"Model `model': `quietly' cnsreg `varlist' `if' `in' [`weight'`exp'], constraints(`constraints') `options'"'
    `quietly' cnsreg `varlist' `if' `in' [`weight'`exp'], constraints(`constraints') `options' 
  }
  if "`preserve'"=="preserve" preserve
  
  `qui' {
  tempname ests
  estimates store `ests'
  if "`eststo'"~="" estimates store `eststo'
  
  // Make a data set of the coefficients
    //Pull off the coefficients
     local depvar "`e(depvar)'"
     tempname b variance se
     matrix `b'=e(b)
     matrix `variance'=vecdiag(e(V))
     matrix `se'=`variance'
     local nr=colsof(`se')
     forvalues i=1/`nr' {
       matrix `se'[1,`i']=sqrt(`se'[1,`i'])
     }
     matrix `b'=(`b' \ `se')'
     matrix colnames `b'=b se
    //Save the coefficients
     drop _all
     set obs `nr'
     svmat `b', names(col)   
    //Save the independent variable names
     gen ivartxt=""
     tempname oneb
     forvalues i=1/`nr' {
       matrix `oneb'=`b'[`i', 1..2]
       local ivarname : rowfullnames `oneb'
       replace ivartxt="`ivarname'" in `i'
     }
   //Parse the coefficient names
    gen ivartype=""
    replace ivartype="Interaction" if strpos(ivartxt, "#")>0          // Interactions
    replace ivartype="FV" if strpos(ivartxt, ".")>0 & ivartype==""    // Factor variable
    replace ivartype="Continuous" if ivartype==""  
    //Continuous variables are very easy to clean
     gen cvname=subinstr(ivartxt, "c.", "", .) if ivartype=="Continuous"
    //Clean interactions. Interactions are continuous-continuous, and only two-level.
     gen v1=substr(ivartxt, 1, strpos(ivartxt, "#")-1) if ivartype=="Interaction"
     gen v2=substr(ivartxt, strpos(ivartxt, "#")+1, .) if ivartype=="Interaction"
     count if ivartype=="Interaction" & ///
              (substr(v1,1,2)!="c." & substr(v1,1,3)!="co.") & ///
              (substr(v2,1,2)!="c." & substr(v2,1,3)!="co.")
     if r(N)>0 {
       di "Error: Interactions must be continuous-continuous"
       err
     }              
     //gen cvarnum=(substr(v1,1,2)=="c." | substr(v1,1,3)=="co.")
     //replace cvarnum=cvarnum+2*(substr(v2,1,2)=="c." | substr(v2,1,3)=="co.")
     //su cvarnum if ivartype=="Interaction", meanonly
     //if r(min)==0 {
     //  di "Error: Can't specify fv#fv interactions"
     //  err
     //}  
     //if r(max)==3 {
     //  di "Error: Can't specify continuous-continuous interactions."
     //  err
     //}
     // All interactions take the form of c.expgpn#c.ur, where n=0,2,4,6,8,10 and ur is one
     // of the unemployment rate variables (ur_st, ur0, dur, dur0)
     replace cvname=subinstr(subinstr(v1, "c.", "", .), "co.", "",.)  if ivartype=="Interaction"
     replace v2=subinstr(subinstr(v2, "c.", "", .), "co.", "",.)  if ivartype=="Interaction" 
     assert inlist(v2, "expgp0","expgp2","expgp4","expgp6","expgp8","expgp10") if ivartype=="Interaction"
     gen fvname="expgp" if ivartype=="Interaction"
     gen fvval=real(substr(v2,6,.)) if ivartype=="Interaction"
     drop v1 v2 
    //Clean factor variables
     gen fvtxt=ivartxt if ivartype=="FV"   
     replace fvname=substr(fvtxt, strpos(fvtxt, ".")+1, .) if fvtxt~=""
     gen fvval0=substr(fvtxt, 1, strpos(fvtxt, ".")-1) if fvtxt~=""
     gen normalized=(strpos(fvval0, "b")>0 | strpos(fvval0, "o")>0) if fvtxt~=""
     replace fvval=real(subinstr(subinstr(fvval0,"b", "", .),"o", "", .)) if fvtxt~="" 
     drop fvval0 fvtxt 
     replace ivartype="Intercept" if ivartype=="Continuous" & cvname=="_cons"

     gen depvar="`depvar'"
     order depvar ivartype cvname fvname fvval b se normalized
     if "`model"~="" {
       gen model="`model'"
       order model, first
     }  
     if "`outfile'"~="" save `outfile' 
     if "`preserve'"=="preserve" {
       restore
       estimates restore `ests'
     }
   } // End of `qui' loop
   estimates drop `ests'
end

// Program to estimate the contrast between the 2005/6 and 2010/11 cohorts
// (as measured by the age when 22). Applies only to the m#b models, where # is 0,1,2,3,4
cap program drop estdiff
program define estdiff, rclass
  matrix b=e(b)
  matrix V=e(V)
  local ncols=colsof(b)
  matrix Q=J(1,`ncols',0)
  matrix Q[1,colnumb(b,"1983.cohort")]=-0.5
  matrix Q[1,colnumb(b,"1984.cohort")]=-0.5
  matrix Q[1,colnumb(b,"1988.cohort")]=0.5
  matrix Q[1,colnumb(b,"1989.cohort")]=0.5
  matrix Qb=Q*(b')
  matrix QVQ=Q*V*(Q')
  local b_`m'_`v'=el(Qb,1,1)
  local se_`m'_`v'=sqrt(el(QVQ,1,1))
end  

// Start of data manipulation

  use `prepdata'/combinecollapse_yca2ss, clear
  cap drop _*
  keep if age<=40 
  keep if (educ2==1 & age>=22) | (educ2==0 & age>=18)
  keep if marchwgt<. | orgwgt<. | bigcpswgt<.
  // Drop the cohorts just entering the sample in 2018, for whom UR0 is missing.
  drop if year==2018 & ((educ2==0 & age==18) | (educ2==1 & age==22))
  isid cohort year fipsst educ2 sex
  gen ur0=ur0_22 if educ2==1
  replace ur0=ur0_18 if educ2==0
  gen ur0_nat=ur0_nat_22 if educ2==1
  replace ur0_nat=ur0_nat_18 if educ2==0
  // Make de-meaned state unemployment rates for the last period.
  gen dur=ur_st-ur_nat
  gen dur0=ur0-ur0_nat_22 if educ2==1
  replace dur0=ur0-ur0_nat_18 if educ2==0
    
  // Subsample that is age 30+ when GR hit
  gen estsamp=(cohort<=1978 & ur0<.)
  assert estsamp==(cohort>=1948 & cohort<=1978) if educ2==1
  assert estsamp==0 if educ2==1 & (cohort<1948 | cohort>1978)
  assert estsamp==(cohort>=1952 & cohort<=1978) if educ2==0
  assert estsamp==0 if educ2==0 & (cohort<1952 | cohort>1978)
  gen estsampb=(ur0<.)
  assert estsampb==(cohort>=1948 & cohort<=1996) if educ2==1 // NG, 8/30/2019: small change from 1995 to 1996 in order to accomodate with 2019 data
  assert estsampb==(cohort>=1952 & cohort<=1999) if (year!= 2019 & educ2==0)   // NG, 8/30/2019: adding | !=2019 in order to accomodate with 2019 data
  gen ageb=age-40
  gen exper=age-18-4*educ2
  recode exper (0/1=0) (2/3=2) (4/5=4) (6/7=6) (8/9=8) (10/max=10), gen(expgp)
  gen expgp0=(expgp==0)
  gen expgp2=(expgp==2)
  gen expgp4=(expgp==4)
  gen expgp6=(expgp==6)
  gen expgp8=(expgp==8)
  gen expgp10=(expgp==10)
  gen byte diffsamp=inlist(cohort, 1983, 1984, 1988, 1989) * (age<=27) if educ2==1
  replace diffsamp=inlist(cohort, 1987, 1988, 1992, 1993)*(age<=27) if educ2==0
  gen byte postGR=inlist(cohort, 1988, 1989) if diffsamp==1 & educ2==1
  replace postGR=inlist(cohort, 1992, 1993) if diffsamp==1 & educ2==0
  // create inverse mills ratios
  gen imr_yc=normalden(invnormal(edfr_yc))/edfr_yc 

 //Fit the age-time-cohort regressions
 foreach v of varlist `depvarscps' `depvarsmar' `depvarsorg' {
   local dvlist "`dvlist' `v'"
   foreach e in 0 1 {
     foreach s in 0 1 {
      // Assign weights to variables
       local wgt=""
       foreach w of varlist `depvarscps' {
         if "`v'"=="`w'" local wgt "bigcpswgt"
       }
       foreach w of varlist `depvarsmar' {
         if "`v'"=="`w'" local wgt "marchwgt"
       }
       foreach w of varlist `depvarsorg' {
         if "`v'"=="`w'" local wgt "orgwgt"
       }
       if "`wgt'"=="" {
         di "Variable `v' does not have an associated weight. Failing."
         err
       }
      // Models:
       // A: Just cohort, age, and state effects -- no time effects
       // B: Age-time-cohort + state FEs
       // C: A-T-C + UR(t)*Agroups
       // D: A-T-C + UR(0)*Agroups
       // E: A-T-C + UR(t)*Agroups + UR(0)*Agroups
       // b versions of each that include all cohorts
       // Zb: Just contrast between 2005/6 and 2010/11 cohorts (measured by age when 22).
       //a models: Main estimation sample, excluding recent cohorts
       //b models: Full sample
       //c models: Full sample, exclude <24.
       //d models: Main estimation sample, use national UR
       //Make estout tables .
       di "Starting models for variable `v', with weight `wgt', for education group `e'"
        tempfile mA`e'`s'a_`v' mB`e'`s'a_`v' mC`e'`s'a_`v' mD`e'`s'a_`v' mE`e'`s'a_`v' ///
                 mA`e'`s'b_`v' mB`e'`s'b_`v' mC`e'`s'b_`v' mD`e'`s'b_`v' mE`e'`s'b_`v' ///
                 mA`e'`s'c_`v' mB`e'`s'c_`v' mC`e'`s'c_`v' mD`e'`s'c_`v' mE`e'`s'c_`v' ///
                                             mC`e'`s'd_`v' mD`e'`s'd_`v' mE`e'`s'd_`v' 
       //   A: Just cohort, age, and state effects
        fvreg `v' ib10.exper ib1969.cohort ib6.fipsst imr_yc  ///
            [aw=`wgt'] if estsamp==1 & educ2==`e' & sex==`s', cluster(fipsst) ///
            model("mA`e'`s'a") outfile(`mA`e'`s'a_`v'') preserve 
        predict double mA`e'`s'a_`v'_xb, xb
        gen mA`e'`s'a_`v'_samp=e(sample)    
        eststo mod_`v'_mA`e'`s'a, noesample
       //   B: Age-time-cohort and state FEs
        fvreg `v' ib10.exper ib2007.year ib1969o1978.cohort ib6.fipsst imr_yc  ///
            [aw=`wgt'] if estsamp==1 & educ2==`e' & sex == `s', cluster(fipsst) ///
            model("mB`e'`s'a") outfile(`mB`e'`s'a_`v'') preserve 
        predict double mB`e'`s'a_`v'_xb, xb
        gen mB`e'`s'a_`v'_samp=e(sample)    
        eststo mod_`v'_mB`e'`s'a, noesample
       //   C: A-T-C + UR(t)*Agroups
        fvreg `v' ib10.exper ib2007.year ib1969o1978.cohort ib6.fipsst imr_yc  ///
            c.ur_st#c.expgp0 c.ur_st#c.expgp2 c.ur_st#c.expgp4 c.ur_st#c.expgp6 c.ur_st#c.expgp8 c.dur ///
            [aw=`wgt'] if estsamp==1 & educ2==`e' & sex == `s', cluster(fipsst) ///
            model("mC`e'`s'a") outfile(`mC`e'`s'a_`v'') preserve
        //fvreg `v' ib10.exper ib2007.year ib1969o1978.cohort ib6.fipsst imr_yc  ///
        //    c.ur_st#c.expgp0 c.ur_st#c.expgp2 c.ur_st#c.expgp4 c.ur_st#c.expgp6 c.ur_st#c.expgp8 c.dur#c.expgp10 ///
        //    [aw=`wgt'] if estsamp==1 & educ2==`e', cluster(fipsst) ///
        //    model("mC`e'a") outfile(`mC`e'a_`v'') preserve
        predict double mC`e'`s'a_`v'_xb, xb
        gen mC`e'`s'a_`v'_samp=e(sample)    
        eststo mod_`v'_mC`e'`s'a, noesample
       //   D: A-T-C + UR(0)*Agroups
        fvreg `v' ib10.exper ib2007.year ib1969o1978.cohort ib6.fipsst imr_yc  ///
            c.ur0#c.expgp0 c.ur0#c.expgp2 c.ur0#c.expgp4 c.ur0#c.expgp6 c.ur0#c.expgp8 c.dur0 ///
            [aw=`wgt'] if estsamp==1 & educ2==`e' & sex==`s', cluster(fipsst) ///
            model("mD`e'`s'a") outfile(`mD`e'`s'a_`v'') preserve
        //fvreg `v' ib10.exper ib2007.year ib1969o1978.cohort ib6.fipsst imr_yc  ///
        //    c.ur0#c.expgp0 c.ur0#c.expgp2 c.ur0#c.expgp4 c.ur0#c.expgp6 c.ur0#c.expgp8 c.dur0#c.expgp10 ///
        //    [aw=`wgt'] if estsamp==1 & educ2==`e', cluster(fipsst) ///
        //    model("mD`e'a") outfile(`mD`e'a_`v'') preserve
        predict double mD`e'`s'a_`v'_xb, xb
        gen mD`e'`s'a_`v'_samp=e(sample)    
        eststo mod_`v'_mD`e'`s'a, noesample
       //   E: A-T-C + UR(t)*Agroups + UR(0)*Agroups
        fvreg `v' ib10.exper ib2007.year ib1969o1978.cohort ib6.fipsst imr_yc ///
            c.ur_st#c.expgp0 c.ur_st#c.expgp2 c.ur_st#c.expgp4 c.ur_st#c.expgp6 c.ur_st#c.expgp8 c.dur ///
            c.ur0#c.expgp0 c.ur0#c.expgp2 c.ur0#c.expgp4 c.ur0#c.expgp6 c.ur0#c.expgp8 c.dur0 ///
            [aw=`wgt'] if estsamp==1 & educ2==`e' & sex==`s', cluster(fipsst) ///
            model("mE`e'`s'a") outfile(`mE`e'`s'a_`v'') preserve
        //fvreg `v' ib10.exper ib2007.year ib1969o1978.cohort ib6.fipsst imr_yc ///
        //    c.ur_st#c.expgp0 c.ur_st#c.expgp2 c.ur_st#c.expgp4 c.ur_st#c.expgp6 c.ur_st#c.expgp8 c.dur#c.expgp10 ///
        //    c.ur0#c.expgp0 c.ur0#c.expgp2 c.ur0#c.expgp4 c.ur0#c.expgp6 c.ur0#c.expgp8 c.dur0#c.expgp10 ///
        //    [aw=`wgt'] if estsamp==1 & educ2==`e', cluster(fipsst) ///
        //    model("mE`e'a") outfile(`mE`e'a_`v'') preserve
        predict double mE`e'`s'a_`v'_xb, xb
        gen mE`e'`s'a_`v'_samp=e(sample)    
        eststo mod_`v'_mE`e'`s'a, noesample

       
       //   Ab: Just cohort, age, and state effects, including most recent data
        fvreg `v' ib10.exper ib1969.cohort ib6.fipsst imr_yc  ///
            [aw=`wgt'] if estsampb==1 & educ2==`e' & sex == `s', cluster(fipsst) ///
            model("mA`e'`s'b") outfile(`mA`e'`s'b_`v'') preserve
        predict double mA`e'`s'b_`v'_xb, xb
        gen mA`e'`s'b_`v'_samp=e(sample)    
        estdiff
        local b_mA`e'`s'b_`v'=el(Qb,1,1)
        local se_mA`e'`s'b_`v'=sqrt(el(QVQ,1,1))
        if `e'==1 test 1988.cohort+1989.cohort=1983.cohort+1984.cohort
        else test 1992.cohort+1993.cohort=1987.cohort+1988.cohort
        local p_mA`e'`s'b_`v'=r(p)
        eststo mod_`v'_mA`e'`s'b, addscalars(diff `b_mA`e'`s'b_`v'' sediff `se_mA`e'`s'b_`v'' pdiff `p_mA`e'`s'b_`v'') noesample title(`v'_mA`e'b)
        
       //   Bb: Age-time-cohort and state FEs, including most recent data
        fvreg `v' ib10.exper ib2007.year ib1969o1978.cohort ib6.fipsst imr_yc  ///
            [aw=`wgt'] if estsampb==1  & educ2==`e' & sex==`s', cluster(fipsst) ///
            model("mB`e'`s'b") outfile(`mB`e'`s'b_`v'') preserve
        predict double mB`e'`s'b_`v'_xb, xb
        gen mB`e'`s'b_`v'_samp=e(sample)    
        estdiff
        local b_mB`e'`s'b_`v'=el(Qb,1,1)
        local se_mB`e'`s'b_`v'=sqrt(el(QVQ,1,1))
        if `e'==1 test 1988.cohort+1989.cohort=1983.cohort+1984.cohort
        else test 1992.cohort+1993.cohort=1987.cohort+1988.cohort
        local p_mB`e'`s'b_`v'=r(p)
        eststo mod_`v'_mB`e'`s'b, addscalars(diff `b_mB`e'`s'b_`v'' sediff `se_mB`e'`s'b_`v'' pdiff `p_mB`e'`s'b_`v'') noesample title(`v'_mB`e'`s'b)

       //   Cb: A-T-C + UR(t)*Agroups (excluding one), including most recent data
        fvreg `v' ib10.exper ib2007.year ib1969o1978.cohort ib6.fipsst imr_yc  ///
            c.ur_st#c.expgp0 c.ur_st#c.expgp2 c.ur_st#c.expgp4 c.ur_st#c.expgp6 c.ur_st#c.expgp8 c.dur ///
            [aw=`wgt']  if estsampb==1 & educ2==`e' & sex == `s', cluster(fipsst) ///
            model("mC`e'`s'b") outfile(`mC`e'`s'b_`v'') preserve
        //fvreg `v' ib10.exper ib2007.year ib1969o1978.cohort ib6.fipsst imr_yc  ///
        //    c.ur_st#c.expgp0 c.ur_st#c.expgp2 c.ur_st#c.expgp4 c.ur_st#c.expgp6 c.ur_st#c.expgp8 c.dur#c.expgp10 ///
        //    [aw=`wgt']  if estsampb==1 & educ2==`e', cluster(fipsst) ///
        //    model("mC`e'b") outfile(`mC`e'b_`v'') preserve
        predict double mC`e'`s'b_`v'_xb, xb
        gen mC`e'`s'b_`v'_samp=e(sample)    
        estdiff
        local b_mC`e'`s'b_`v'=el(Qb,1,1)
        local se_mC`e'`s'b_`v'=sqrt(el(QVQ,1,1))
        if `e'==1 test 1988.cohort+1989.cohort=1983.cohort+1984.cohort
        else test 1992.cohort+1993.cohort=1987.cohort+1988.cohort
        local p_mC`e'`s'b_`v'=r(p)
        eststo mod_`v'_mC`e'`s'b, addscalars(diff `b_mC`e'`s'b_`v'' sediff `se_mC`e'`s'b_`v'' pdiff `p_mC`e'`s'b_`v'') noesample title(`v'_mC`e'`s'b)

       //   Db: A-T-C + UR(0)*Agroups, including most recent data
        fvreg `v' ib10.exper ib2007.year ib1969o1978.cohort ib6.fipsst  imr_yc  ///
            c.ur0#c.expgp0 c.ur0#c.expgp2 c.ur0#c.expgp4 c.ur0#c.expgp6 c.ur0#c.expgp8 c.dur0 ///
            [aw=`wgt']  if estsampb==1 & educ2==`e' & sex == `s', cluster(fipsst) ///
            model("mD`e'`s'b") outfile(`mD`e'`s'b_`v'') preserve
        //fvreg `v' ib10.exper ib2007.year ib1969o1978.cohort ib6.fipsst  imr_yc  ///
        //    c.ur0#c.expgp0 c.ur0#c.expgp2 c.ur0#c.expgp4 c.ur0#c.expgp6 c.ur0#c.expgp8 c.dur0#c.expgp10 ///
        //    [aw=`wgt']  if estsampb==1 & educ2==`e', cluster(fipsst) ///
        //    model("mD`e'b") outfile(`mD`e'b_`v'') preserve
        predict double mD`e'`s'b_`v'_xb, xb
        gen mD`e'`s'b_`v'_samp=e(sample)    
        estdiff
        local b_mD`e'`s'b_`v'=el(Qb,1,1)
        local se_mD`e'`s'b_`v'=sqrt(el(QVQ,1,1))
        if `e'==1 test 1988.cohort+1989.cohort=1983.cohort+1984.cohort
        else test 1992.cohort+1993.cohort=1987.cohort+1988.cohort
        local p_mD`e'`s'b_`v'=r(p)
        eststo mod_`v'_mD`e'`s'b, addscalars(diff `b_mD`e'`s'b_`v'' sediff `se_mD`e'`s'b_`v'' pdiff `p_mD`e'`s'b_`v'') noesample title(`v'_mD`e'`s'b)

       //   Eb: A-T-C + UR(t)*Agroups + UR(0)*Agroups, including most recent data
        fvreg `v' ib10.exper ib2007.year ib1969o1978.cohort ib6.fipsst imr_yc  ///
            c.ur_st#c.expgp0 c.ur_st#c.expgp2 c.ur_st#c.expgp4 c.ur_st#c.expgp6 c.ur_st#c.expgp8 c.dur ///
            c.ur0#c.expgp0 c.ur0#c.expgp2 c.ur0#c.expgp4 c.ur0#c.expgp6 c.ur0#c.expgp8 c.dur0 ///
            [aw=`wgt']  if estsampb==1 & educ2==`e' & sex == `s', cluster(fipsst) ///
            model("mE`e'`s'b") outfile(`mE`e'`s'b_`v'') preserve
        //fvreg `v' ib10.exper ib2007.year ib1969o1978.cohort ib6.fipsst imr_yc  ///
        //    c.ur_st#c.expgp0 c.ur_st#c.expgp2 c.ur_st#c.expgp4 c.ur_st#c.expgp6 c.ur_st#c.expgp8 c.dur#c.expgp10 ///
        //    c.ur0#c.expgp0 c.ur0#c.expgp2 c.ur0#c.expgp4 c.ur0#c.expgp6 c.ur0#c.expgp8 c.dur0#c.expgp10 ///
        //    [aw=`wgt']  if estsampb==1 & educ2==`e', cluster(fipsst) ///
        //    model("mE`e'b") outfile(`mE`e'b_`v'') preserve
        predict double mE`e'`s'b_`v'_xb, xb
        gen mE`e'`s'b_`v'_samp=e(sample)    
        estdiff
        local b_mE`e'`s'b_`v'=el(Qb,1,1)
        local se_mE`e'`s'b_`v'=sqrt(el(QVQ,1,1))
        if `e'==1 test 1988.cohort+1989.cohort=1983.cohort+1984.cohort
        else test 1992.cohort+1993.cohort=1987.cohort+1988.cohort
        local p_mE`e'`s'b_`v'=r(p)
        eststo mod_`v'_mE`e'`s'b, addscalars(diff `b_mE`e'`s'b_`v'' sediff `se_mE`e'`s'b_`v'' pdiff `p_mE`e'`s'b_`v'') noesample title(`v'_mE`e'b)

       // Finally, a separate model that just fits simple differences across two pairs of
       // recent cohorts, those that are 22 in 2005/6 and 2010/11
       reg `v' postGR imr_yc if diffsamp==1 & educ2==`e' & sex == `s' [aw=`wgt'], cluster(fipsst)
       estimates store mod_mZ`e'`s'b_`v'
       local b_mZ`e'`s'b_`v'=_b[postGR]
       local se_mZ`e'`s'b_`v'=_se[postGR]
       test postGR
       local p_mZ`e'`s'b_`v'=r(p)
        eststo mod_`v'_mZ`e'`s'b, addscalars(diff `b_mZ`e'`s'b_`v'' sediff `se_mZ`e'`s'b_`v'' pdiff `p_mZ`e'`s'b_`v'') noesample title(`v'_mZ`e'`s'b)

       // c models: Include most recent data, but exclude anyone 24 and younger.
       //   Ac: Just cohort, age, and state effects, including most recent data
        fvreg `v' ib10.exper ib1969.cohort ib6.fipsst imr_yc  ///
            [aw=`wgt'] if estsampb==1 & educ2==`e' & age>(20+4*educ2) & sex == `s', cluster(fipsst) ///
            model("mA`e'`s'c") outfile(`mA`e'`s'c_`v'') preserve
        predict double mA`e'`s'c_`v'_xb, xb
        gen mA`e'`s'c_`v'_samp=e(sample)    
        estdiff
        local b_mA`e'`s'c_`v'=el(Qb,1,1)
        local se_mA`e'`s'c_`v'=sqrt(el(QVQ,1,1))
        if `e'==1 test 1988.cohort+1989.cohort=1983.cohort+1984.cohort
        else test 1992.cohort+1993.cohort=1987.cohort+1988.cohort
        local p_mA`e'`s'c_`v'=r(p)
        eststo mod_`v'_mA`e'`s'c, addscalars(diff `b_mA`e'`s'c_`v'' sediff `se_mA`e'`s'c_`v'' pdiff `p_mA`e'`s'c_`v'') noesample title(`v'_mA`e'`s'c)
        
       //   Bc: Age-time-cohort and state FEs, including most recent data
        fvreg `v' ib10.exper ib2007.year ib1969o1978.cohort ib6.fipsst imr_yc  ///
            [aw=`wgt'] if estsampb==1  & educ2==`e' & age>(20+4*educ2) & sex == `s', cluster(fipsst) ///
            model("mB`e'`s'c") outfile(`mB`e'`s'c_`v'') preserve
        predict double mB`e'`s'c_`v'_xb, xb
        gen mB`e'`s'c_`v'_samp=e(sample)    
        estdiff
        local b_mB`e'`s'c_`v'=el(Qb,1,1)
        local se_mB`e'`s'c_`v'=sqrt(el(QVQ,1,1))
        if `e'==1 test 1988.cohort+1989.cohort=1983.cohort+1984.cohort
        else test 1992.cohort+1993.cohort=1987.cohort+1988.cohort
        local p_mB`e'`s'c_`v'=r(p)
        eststo mod_`v'_mB`e'`s'c, addscalars(diff `b_mB`e'`s'c_`v'' sediff `se_mB`e'`s'c_`v'' pdiff `p_mB`e'`s'c_`v'') noesample title(`v'_mB`e'`s'c)

       //   Cc: A-T-C + UR(t)*Agroups (excluding one), including most recent data
        fvreg `v' ib10.exper ib2007.year ib1969o1978.cohort ib6.fipsst imr_yc  ///
            c.ur_st#c.expgp0 c.ur_st#c.expgp2 c.ur_st#c.expgp4 c.ur_st#c.expgp6 c.ur_st#c.expgp8 c.dur ///
            [aw=`wgt']  if estsampb==1 & educ2==`e' & age>(20+4*educ2) & sex == `s', cluster(fipsst) ///
            model("mC`e'`s'c") outfile(`mC`e'`s'c_`v'') preserve
        //fvreg `v' ib10.exper ib2007.year ib1969o1978.cohort ib6.fipsst imr_yc  ///
        //    c.ur_st#c.expgp0 c.ur_st#c.expgp2 c.ur_st#c.expgp4 c.ur_st#c.expgp6 c.ur_st#c.expgp8 c.dur#c.expgp10 ///
        //    [aw=`wgt']  if estsampb==1 & educ2==`e' & age>(20+4*educ2), cluster(fipsst) ///
        //    model("mC`e'`s'c") outfile(`mC`e'`s'c_`v'') preserve
        predict double mC`e'`s'c_`v'_xb, xb
        gen mC`e'`s'c_`v'_samp=e(sample)    
        estdiff
        local b_mC`e'`s'c_`v'=el(Qb,1,1)
        local se_mC`e'`s'c_`v'=sqrt(el(QVQ,1,1))
        if `e'==1 test 1988.cohort+1989.cohort=1983.cohort+1984.cohort
        else test 1992.cohort+1993.cohort=1987.cohort+1988.cohort
        local p_mC`e'`s'c_`v'=r(p)
        eststo mod_`v'_mC`e'`s'c, addscalars(diff `b_mC`e'`s'c_`v'' sediff `se_mC`e'`s'c_`v'' pdiff `p_mC`e'`s'c_`v'') noesample title(`v'_mC`e'`s'c)

       //   Dc: A-T-C + UR(0)*Agroups, including most recent data
        fvreg `v' ib10.exper ib2007.year ib1969o1978.cohort ib6.fipsst imr_yc  ///
            c.ur0#c.expgp0 c.ur0#c.expgp2 c.ur0#c.expgp4 c.ur0#c.expgp6 c.ur0#c.expgp8 c.dur0 ///
            [aw=`wgt']  if estsampb==1 & educ2==`e' & age>(20+4*educ2) & sex == `s', cluster(fipsst) ///
            model("mD`e'`s'c") outfile(`mD`e'`s'c_`v'') preserve
        //fvreg `v' ib10.exper ib2007.year ib1969o1978.cohort ib6.fipsst imr_yc  ///
        //    c.ur0#c.expgp0 c.ur0#c.expgp2 c.ur0#c.expgp4 c.ur0#c.expgp6 c.ur0#c.expgp8 c.dur0#c.expgp10 ///
        //    [aw=`wgt']  if estsampb==1 & educ2==`e' & age>(20+4*educ2), cluster(fipsst) ///
        //    model("mD`e'`s'c") outfile(`mD`e'`s'c_`v'') preserve
        predict double mD`e'`s'c_`v'_xb, xb
        gen mD`e'`s'c_`v'_samp=e(sample)    
        estdiff
        local b_mD`e'`s'c_`v'=el(Qb,1,1)
        local se_mD`e'`s'c_`v'=sqrt(el(QVQ,1,1))
        if `e'==1 test 1988.cohort+1989.cohort=1983.cohort+1984.cohort
        else test 1992.cohort+1993.cohort=1987.cohort+1988.cohort
        local p_mD`e'`s'c_`v'=r(p)
        eststo mod_`v'_mD`e'`s'c, addscalars(diff `b_mD`e'`s'c_`v'' sediff `se_mD`e'`s'c_`v'' pdiff `p_mD`e'`s'c_`v'') noesample title(`v'_mD`e'`s'c)

       //   Ec: A-T-C + UR(t)*Agroups + UR(0)*Agroups, including most recent data
        fvreg `v' ib10.exper ib2007.year ib1969o1978.cohort ib6.fipsst imr_yc  ///
            c.ur_st#c.expgp0 c.ur_st#c.expgp2 c.ur_st#c.expgp4 c.ur_st#c.expgp6 c.ur_st#c.expgp8 c.dur ///
            c.ur0#c.expgp0 c.ur0#c.expgp2 c.ur0#c.expgp4 c.ur0#c.expgp6 c.ur0#c.expgp8 c.dur0 ///
            [aw=`wgt']  if estsampb==1 & educ2==`e' & age>(20+4*educ2) & sex == `s', cluster(fipsst) ///
            model("mE`e'`s'c") outfile(`mE`e'`s'c_`v'') preserve
        //fvreg `v' ib10.exper ib2007.year ib1969o1978.cohort ib6.fipsst imr_yc  ///
        //    c.ur_st#c.expgp0 c.ur_st#c.expgp2 c.ur_st#c.expgp4 c.ur_st#c.expgp6 c.ur_st#c.expgp8 c.dur#c.expgp10 ///
        //    c.ur0#c.expgp0 c.ur0#c.expgp2 c.ur0#c.expgp4 c.ur0#c.expgp6 c.ur0#c.expgp8 c.dur0#c.expgp10 ///
        //    [aw=`wgt']  if estsampb==1 & educ2==`e' & age>(20+4*educ2), cluster(fipsst) ///
        //    model("mE`e'`s'c") outfile(`mE`e'`s'c_`v'') preserve
        predict double mE`e'`s'c_`v'_xb, xb
        gen mE`e'`s'c_`v'_samp=e(sample)    
        estdiff
        local b_mE`e'`s'c_`v'=el(Qb,1,1)
        local se_mE`e'`s'c_`v'=sqrt(el(QVQ,1,1))
        if `e'==1 test 1988.cohort+1989.cohort=1983.cohort+1984.cohort
        else test 1992.cohort+1993.cohort=1987.cohort+1988.cohort
        local p_mE`e'`s'c_`v'=r(p)
        eststo mod_`v'_mE`e'`s'c, addscalars(diff `b_mE`e'`s'c_`v'' sediff `se_mE`e'`s'c_`v'' pdiff `p_mE`e'`s'c_`v'') noesample title(`v'_mE`e'`s'c)

       // d models (just C,D,E): Use national rather than state URs.
       //   C: A-T-C + UR(t)*Agroups
        fvreg `v' ib10.exper ib2007.year ib1969o1978.cohort ib6.fipsst imr_yc  ///
            c.ur_nat#c.expgp0 c.ur_nat#c.expgp2 c.ur_nat#c.expgp4 c.ur_nat#c.expgp6 c.ur_nat#c.expgp8 ///
            [aw=`wgt'] if estsamp==1 & educ2==`e' & sex == `s', cluster(fipsst) ///
            model("mC`e'`s'd") outfile(`mC`e'`s'd_`v'') preserve
        //fvreg `v' ib10.exper ib2007.year ib1969o1978.cohort ib6.fipsst imr_yc  ///
        //    c.ur_nat#c.expgp0 c.ur_nat#c.expgp2 c.ur_nat#c.expgp4 c.ur_nat#c.expgp6 c.ur_nat#c.expgp8 ///
        //    c.dur#c.expgp0 c.dur#c.expgp2 c.dur#c.expgp4 c.dur#c.expgp6 c.dur#c.expgp8 c.dur ///
        //    [aw=`wgt'] if estsamp==1 & educ2==`e', cluster(fipsst) ///
        //    model("mC`e'`s'd") outfile(`mC`e'`s'd_`v'') preserve
        predict double mC`e'`s'd_`v'_xb, xb
        gen mC`e'`s'd_`v'_samp=e(sample)    
        eststo mod_`v'_mC`e'`s'd, noesample
       //   D: A-T-C + UR(0)*Agroups
        fvreg `v' ib10.exper ib2007.year ib1969o1978.cohort ib6.fipsst imr_yc  ///
            c.ur0_nat#c.expgp0 c.ur0_nat#c.expgp2 c.ur0_nat#c.expgp4 c.ur0_nat#c.expgp6 c.ur0_nat#c.expgp8  ///
            [aw=`wgt'] if estsamp==1 & educ2==`e' & sex == `s', cluster(fipsst) ///
            model("mD`e'`s'd") outfile(`mD`e'`s'd_`v'') preserve
        predict double mD`e'`s'd_`v'_xb, xb
        gen mD`e'`s'd_`v'_samp=e(sample)    
        eststo mod_`v'_mD`e'`s'd, noesample
       //   E: A-T-C + UR(t)*Agroups + UR(0)*Agroups
        fvreg `v' ib10.exper ib2007.year ib1969o1978.cohort ib6.fipsst imr_yc ///
            c.ur_nat#c.expgp0 c.ur_nat#c.expgp2 c.ur_nat#c.expgp4 c.ur_nat#c.expgp6 c.ur_nat#c.expgp8 ///
            c.ur0_nat#c.expgp0 c.ur0_nat#c.expgp2 c.ur0_nat#c.expgp4 c.ur0_nat#c.expgp6 c.ur0_nat#c.expgp8  ///
            [aw=`wgt'] if estsamp==1 & educ2==`e' & sex == `s', cluster(fipsst) ///
            model("mE`e'`s'd") outfile(`mE`e'`s'd_`v'') preserve
        predict double mE`e'`s'd_`v'_xb, xb
        gen mE`e'`s'd_`v'_samp=e(sample)    
        eststo mod_`v'_mE`e'`s'd, noesample

       // And spit out results into a table
       if "`append'"=="" local append "replace"
       else local append "append"
       // Old command fails for some reason under project, but not outside it. We will skip it for now.
       if `doasproject'==0 {
          estout mod_`v'_m* using `output'/runatc_bygender_fulltable.txt, `append' title("Estimates for dependent variable `v'") ///
              cells(b se) stat(N df_m r2 diff sediff pdiff) nolabel mlabels(, titles)
          // Other variants that also didnt work
          //      estout mod_`v'_m?b using `output'/runatc_fulltableb.txt, `append' title("Estimates for dependent variable `v'") ///
          //            cells(b se) stat(N df_m r2 diff sediff pdiff) nolabel mlabels(, titles)
          //    esttab mod_`v'_m?b using `output'/runatc_fulltable.txt, `append' title("Estimates for dependent variable `v'") ///
          //          se nostar nogaps plain scalars(N df_m r2 diff sediff pdiff) mtitles  
       }
       estout mod_`v'_m*b using `output'/runatc_bygender_difftable.txt, `append' title("Estimates for dependent variable `v'") ///
              cells(none) stat(N df_m r2 diff sediff pdiff) nolabel mlabels(, titles)
       estimates clear     
     }
   }
 } 
 save `prepdata'/runatc_bygender_fitted.dta, replace

  // Now loop back through the b and c models, reload them, and make a stata data set of the contrast 
  // between the 2005/6 and 2010/11 cohorts.
  // Note that these are the birth cohorts of 1983/4 and 1988/9.
   foreach v of varlist `dvlist' {
     foreach e in 0 1 {
       foreach s in 0 1 {
         foreach m in mA0b mB0b mC0b mD0b mE0b mZ0b mA0c mB0c mC0c mD0c mE0c {
           local nrows=`nrows'+1
         }
       }
     }  
   }  
    drop _all
    set obs `nrows'
    gen model=""
    gen depvar=""
    gen diff=.
    gen sediff=.
    gen pdiff=.
    local row=0
    foreach v in `dvlist' {
      foreach e in 0 1 {
        foreach s in 0 1 {
          foreach suff in b c {
            local mlist "A B C D E"
            if "`suff'"=="b" local mlist "`mlist' Z"
            foreach m of local mlist {
              local model "m`m'`e'`s'`suff'" 
              local row=`row'+1
              replace model="`model'" in `row'
              replace depvar="`v'" in `row'
              replace diff=`b_`model'_`v'' in `row'
              replace sediff=`se_`model'_`v'' in `row'
              replace pdiff=`p_`model'_`v'' in `row'
          }
        }
      }   
    }
  }
    save `prepdata'/runatc_bygender_diffs.dta, replace
/*    
use `mA0_empl', clear
append using `mB0_empl' `mC0_empl' `mD0_empl' `mA0b_empl' `mB0b_empl' `mC0b_empl' `mD0b_empl'
append using `mA1_empl' `mB1_empl' `mC1_empl' `mD1_empl' `mA1b_empl' `mB1b_empl' `mC1b_empl' `mD1b_empl'
err
*/
  // Loop back through one more time and load, append, and save the coefficient
  // data sets.    
   tempfile allmodels  
   local first=1
   foreach v in `dvlist' {
     foreach e in 0 1 {
       foreach s in 0 1 {
         use `mA`e'`s'a_`v'', clear
         append using `mB`e'`s'a_`v'' `mC`e'`s'a_`v'' `mD`e'`s'a_`v'' `mE`e'`s'a_`v'' ///
                      `mA`e'`s'b_`v'' `mB`e'`s'b_`v'' `mC`e'`s'b_`v'' `mD`e'`s'b_`v'' `mE`e'`s'b_`v'' ///
                      `mA`e'`s'c_`v'' `mB`e'`s'c_`v'' `mC`e'`s'c_`v'' `mD`e'`s'c_`v'' `mE`e'`s'c_`v'' ///
                                                      `mC`e'`s'd_`v'' `mD`e'`s'd_`v'' `mE`e'`s'd_`v''
         tempfile allm`e'`s'_`v'
         save `allm`e'`s'_`v''
         
         if `first'~=1 {
           use `allmodels', clear
           append using `allm`e'`s'_`v''
         }
         save `allmodels', replace
         local first=0 
       }
     }
   }  
   
   // Check that everything is successfully identified
    qui duplicates report model depvar ivartype cvname fvname fvval
    if r(N)~=r(unique_value) {
      di in red "Observations in coefficients dataset are not uniquely identified"
      err
    }  
   save `prepdata'/runatc_bygender_coeffs.dta, replace
 
 if `doasproject'==1 {
	project, creates(`prepdata'/runatc_bygender_fitted.dta)
	project, creates(`prepdata'/runatc_bygender_coeffs.dta)
	project, creates(`prepdata'/runatc_bygender_diffs.dta)
	//project, creates(`output'/runatc_fulltable.txt)
	project, creates(`output'/runatc_bygender_difftable.txt)
 }
 
 
