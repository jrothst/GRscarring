***************************************************************************************************************
* runatc_balanced.do
* Runs and stores coefficients for various models to explain age-time-cohort-state variation
* in outcomes, separately by gender.

* Based on runatc_bygender.do, 6/2020

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
	local dofile "runatc_balanced"
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
  matrix Q[1,colnumb(b,"1983.entrycohort")]=-0.5
  matrix Q[1,colnumb(b,"1984.entrycohort")]=-0.5
  matrix Q[1,colnumb(b,"1988.entrycohort")]=0.5
  matrix Q[1,colnumb(b,"1989.entrycohort")]=0.5
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
  // Drop last year data, which is not yet complete
  drop if year>2019
  // Drop the cohorts just entering the sample in 2018, for whom UR0 is missing.
  // edit, 9/2/19: Dont need this now that we have UR for 2018
*drop if year==2018 & ((educ2==0 & age==18) | (educ2==1 & age==22))
  isid birthcohort year fipsst educ2 sex
  gen entrycohort=birthcohort+22 if educ2==1
  replace entrycohort=birthcohort+18 if educ2==0
  label var birthcohort "Year of Birth"
  label var entrycohort "Year of entry on the labor market, depending on level of education"
  gen ur0=ur0_22 if educ2==1
  replace ur0=ur0_18 if educ2==0
  gen ur0_nat=ur0_nat_22 if educ2==1
  replace ur0_nat=ur0_nat_18 if educ2==0
  // Make de-meaned state unemployment rates.
  gen dur=ur_st-ur_nat
  gen dur0=ur0-ur0_nat
    
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

  // Subset the sample to balanced panel
  keep if age<=27
  keep if entrycohort<=2014
  count if year==2019 & entrycohort==2014 & age==27
  assert r(N)>0

 //Fit the age-time-cohort regressions
 foreach v of varlist `depvarscps' `depvarsmar' `depvarsorg' {
   local dvlist "`dvlist' `v'"
   foreach e in 0 1 {
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
     //.   SKIP   F : Same as D but with interactions between age and both the state and national unemployment rates
     // b versions of each that include all cohorts
     //.   SKIP   Zb: Just contrast between 2005/6 and 2010/11 entrycohort (measured by age when 22).
     //.   SKIP  a models: Main estimation sample, excluding recent entrycohort
     //b models: Full sample
     //c models: Full sample, exclude <24.
     //.   SKIP  d models: Main estimation sample, use national UR
     //Make estout tables .
     di "Starting models for variable `v', with weight `wgt', for education group `e'"
      tempfile mA`e'`s'b_`v' mB`e'`s'b_`v' mC`e'`s'b_`v' mD`e'`s'b_`v' mE`e'`s'b_`v' mF`e'`s'b_`v' ///
               mA`e'`s'c_`v' mB`e'`s'c_`v' mC`e'`s'c_`v' mD`e'`s'c_`v' mE`e'`s'c_`v' mF`e'`s'c_`v' 
     
     //   Bb: Age-time-cohort and state FEs, including most recent data
      fvreg `v' ib10.exper ib2007.year ib1984o2000.entrycohort ib6.fipsst imr_ycs  ///
          [aw=`wgt'] if estsampb==1  & educ2==`e', cluster(fipsst) ///
          model("mB`e'b") outfile(`mB`e'b_`v'') preserve
      predict double mB`e'b_`v'_xb, xb
      gen mB`e'b_`v'_samp=e(sample)    
      eststo mod_`v'_mB`e'b, noesample title(`v'_mB`e'b)

     //   Eb: A-T-C + UR(t)*Agroups + UR(0)*Agroups, including most recent data
      fvreg `v' ib10.exper ib2007.year ib1984o2000.entrycohort ib6.fipsst imr_ycs  ///
          c.ur_st#c.expgp0 c.ur_st#c.expgp2 c.ur_st#c.expgp4 c.ur_st#c.expgp6 c.ur_st#c.expgp8 c.dur ///
          c.ur0#c.expgp0 c.ur0#c.expgp2 c.ur0#c.expgp4 c.ur0#c.expgp6 c.ur0#c.expgp8 c.dur0 ///
          [aw=`wgt'] if estsampb==1  & educ2==`e', cluster(fipsst) ///
          model("mE`e'b") outfile(`mE`e'b_`v'') preserve

   }
 } 
 save `prepdata'/`dofile'_fitted.dta, replace

  // Loop back through one more time and load, append, and save the coefficient
  // data sets.    
   tempfile allmodels  
   local first=1
   foreach v in `dvlist' {
     foreach e in 0 1 {
       use `mB`e'b_`v'', clear
       tempfile allm`e'_`v'
       save `allm`e'_`v''
       
       if `first'==1 {
         use `mB`e'b_`v'', clear
         append using `mE`e'b_`v''
       }
       if `first'~=1 {
         use `allmodels', clear
         append using `mB`e'b_`v''
         append using `mE`e'b_`v''
       }
       save `allmodels', replace
       local first=0 
       }
     }
  
   
   // Check that everything is successfully identified
    qui duplicates report model depvar ivartype cvname fvname fvval
    if r(N)~=r(unique_value) {
      di in red "Observations in coefficients dataset are not uniquely identified"
      err
    }  
   save `prepdata'/`dofile'_coeffs.dta, replace
 
 if `doasproject'==1 {
	project, creates(`prepdata'/`dofile'_fitted.dta)
	project, creates(`prepdata'/`dofile'_coeffs.dta)
 }
 
 