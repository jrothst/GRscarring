* findpartners_v3.do
* JR 8/1/2017
* 
* This file identifies households in the CPS that have people of the opposite 
*	gender and are within a 10 year age range of one another. 
*	This is used in /extractcps.do to identify people living with a partner 
* As written this relies on data files in ~/data/cps/bigcps/statafmt,
*
* Edited by JR, 9/22/17: Rename a variable at the end, clean up a couple other minor issues
* Edited by JR, 10/24/17: Redo code to find why it was failing, and simplify greatly.
*   Previous problem was that code assumed sex was 1/2, when the input data set had it as 0/1.

cap project, doinfo
if _rc==0 {
  local doasproject=1
  local pdir "`r(pdir)'"						  	    // the project's main dir.
  local dofile "`r(dofile)'"						    // do-file's stub name
  local sig {bind:{hi:[RP : `dofile'.do]}}	// a signature in notes
}
else {
  local doasproject=0
  di "RUNNING OUTSIDE OF PROJECT"
  local pdir "~/GRscarring"
  local dofile "findpartners_v3"
  local sig "Not run as part of project!"
}

local cpsorig "~/data/cps/bigcps/statafmt"
local intermediate "`pdir'/scratch"
local cpsraw "~/data/cps/bigcps/raw"
local temp "`pdir'/rawdata/temp"

set more off
*set trace on
program drop _all
set type double, perm
#delimit ;

if `doasproject'==1 {;
  project, uses("`intermediate'/extractcps.dta.gz");
};
*unzip extractcps;
!zcat `intermediate'/extractcps.dta.gz > `intermediate'/extractcps.dta; 

*use if year==2013 using `intermediate'/extractcps.dta;
use `intermediate'/extractcps, clear;
sort yearmo hh_id hh_num hh_tiebreak linenum p_tiebreak;
isid yearmo hh_id hh_num hh_tiebreak linenum p_tiebreak;
*Make a temporary household and person ID to save typing;
 egen temp_hhid=group(yearmo hh_id hh_num hh_tiebreak);
 egen temp_pid=group(temp_hhid linenum p_tiebreak);
 sort temp_hhid temp_pid;
 tempfile base;
 save `base';
 
*Get list of all mens and womens ages in the household;
  gen man=(sex==1);
  gen woman=(sex==0);
  by temp_hhid: gen mannum=sum(man);
  by temp_hhid: gen womnum=sum(woman);
  gen num=mannum*man + womnum*woman;
  su num, meanonly;
  local maxnum=r(max);
  keep temp_hhid sex num age;
  reshape wide age, i(temp_hhid sex) j(num);
  gen listages="";
  foreach v of varlist age* {;
    replace listages=listages+ " " + string(`v') if `v'<.;
  };
  keep temp_hhid sex listages;
  *Convert men to women and vice versa to match to opposite sex;
   replace sex=1-sex;
  tempfile listages;
  save `listages';

*Identify opposite sex partners within 10 years;
 use `base';
 merge m:1 temp_hhid sex using `listages', keep(1 3) nogen;
 gen byte haspartner=0;
 forvalues i=1/`maxnum' {;
   gen testage=real(word(listages, `i'));
   replace haspartner=1 if testage<. & abs(age-testage)<=10;
   drop testage;
 };
 
 //Combine marital status with has partner.;
 gen byte lives_spouse_oth=haspartner;
 replace lives_spouse_oth=1 if married==1;
 //What about people who live with their parents and younger siblings? Seems best to not
 //count unmarried partners of people who live with their parents;
  replace lives_spouse_oth=0 if livewithprnt==1 & married~=1;
  
*Now save a file;
 keep yearmo hh_id hh_num hh_tiebreak linenum p_tiebreak haspartner lives_spouse_oth;
 save `intermediate'/`dofile', replace;
 ! gzip -f `intermediate'/`dofile'.dta;

if `doasproject'==1 project, creates("`intermediate'/`dofile'.dta.gz");
!rm `intermediate'/extractcps.dta;
 

