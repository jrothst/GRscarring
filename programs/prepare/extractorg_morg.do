/*******************************************************************************
 extractorg_morg.do
 RY, 3/6/2018

 Source: extractorg.do, JR, 8/10/2017, which was based on extractorg_recent.do, 
    from the replication archive for:
    Rothstein, Jesse. "The Great Recession and its Aftermath: What Role for 
    Structural Changes?" RSF: The Russell Sage Foundation Journal of the 
    Social Sciences 3(3), April 2017. p.p. 22-49. 
 Extended to incorporate earlier years.

 Description: Written to use the NBER morgyy data http://www.nber.org/morg/annual/
 As written this relies on data files in ~/data/cps/morg,
 and modified versions of CEPRs programs.
 
 modified: RY, 3/30 updated the education cleaning program based on JR code.
 modified: JR, RY, 5/18 updated the cleanwage program and added topcode flags. 
 modified: JR, 5/23/18: Substitute out the wage language, to rely on new program ceprwage.do
 modified: NG, 9/02/19: Updated the data including 2018
 
*******************************************************************************/

cap project, doinfo
if _rc==0 {
	local doasproject=1
	local pdir "`r(pdir)'"						  	    // the project's main dir.
	local dofile "`r(dofile)'"						    // do-file's stub name
	local sig {bind:{hi:[RP : `dofile'.do]}}	// a signature in notes
}
else {
  local doasproject=0
	local pdir "~/GRscarring"
	local dofile "extractorg"
	local sig "Not run as part of project!"
}

local morg "~/data/cps/morg"
local rawdata "`pdir'/rawdata"
local scratch "`pdir'/scratch"
local otherraw "`pdir'/rawdata"

if `doasproject'==1 {
project, uses("`scratch'/cpi.dta")
project, original("`rawdata'/readrawcps/cpssupplemental/gestcen_gestfips_match.dta")
project, original("`pdir'/programs/prepare/ceprwage.do")
}

clear all
set varabbrev off
set more off
set type double
#delimit ;
do /accounts/projects/jr_ra/GRscarring/programs/prepare/ceprwage.do ;       /* NG: Full Path was missing, Added*/

/***Define Global Directory***/
local startyr=1979;
*local startyr=2016;
local endyr=2019;

*local endmo=`startmo'
local overwrite=1;


****************************************************************************************
************ CODE TO CLEAN THE DIFFERENT VARIABLES. *************************************
*****************************************************************************************
 // Gender;
 cap program drop cleangender;
 program define cleangender;
   // Two arguments: The period (A-F) and the month (in %tm format). The latter is useful
   // for any small changes in coding within periods, but typically will not be needed.;
  * args period month;
   // In this case, the code is the same in all periods.;
	 gen byte female=0 if sex==1;
	 replace female=1 if sex==2;
	 lab var female "Female";
	 notes female: CPS: derived from sex;
 end;

 // Marital status;
 cap program drop cleanmaritalstatus;
 program define cleanmaritalstatus;
	gen byte married=.;
	replace married=0 if marital~=.;
	replace married=1 if 1<=marital & marital<=3;
	lab var married "Married";
	notes married: CPS: derived from prmarsta, a-maritl, marital;
 end;
 
 // Person ID;
 cap program drop cleanpersonid;
 program define cleanpersonid;
 	egen hh_id=concat(hrhhid hrhhid2);
	drop hrhhid hrhhid2;
	gen wave=1+(mis>=5);
	gen startmo=yearmo-(mis-1)-8*(mis>=5);
	egen personid=concat(gestcen hh_id hurespli startmo);
	drop startmo;
	*gen byte newmis=hrmis - 4*(wave==2);
 end;
 
 //education cleaning code, JR 3/30/18, modified by RY, 4/9/18
 cap program drop cleaneduc;
 program define cleaneduc;
 args year;
    if `year'<=1991 {;
      gen educ91=gradeat; 
      replace educ91=educ91-1 if gradecp==2 & educ91>=1; 
      gen educ92=.;
    };
    if `year'>=1992 {;
      gen byte educ92=grade92;
      gen educ91=.;
      gen gradeat=.;
      gen gradecp=.;
    };
    *Recode pre-1991 education into post-1992 categories;
     recode educ91 (0=1) (1/4=2) (5/6=3) (7/8=4) (9=5) (10=6) (11=7) (12=9) (13=10) 
           (14/15=12) (16=13) (17=14) (18=16) if year<=1991, gen(educ91_as92);
     replace educ91_as92=8 if gradeat==12 & gradecp==2 & year<=1991;
     replace educ92=educ92-30 if year>=1992;
     replace educ92=educ91_as92 if year<=1991;
     drop educ91_as92;
    *And recode post-1992 categories into pre-1991 Years;
    *This is probably better, especially at the post-9th-grade ranges;
     recode educ92 (1=0) (2=3) (3=6) (4=8) (5=9) (6=10) (7/8=11) (9=12) (10=13) (11/12=14)
                   (13=16) (14=17) (15=18) (16=20) if year>=1992, gen(educ92_as91);
     replace educ91=educ92_as91 if year>=1992;
     drop educ92_as91;
	lab var educ92 "Education level (1992+ coding - not years)";
	lab define educ92
	1  "Less than 1st grade"
	2  "1st-4th grade"
	3  "5th-6th grade"
	4  "7th-8th grade"
	5  "9th grade"
	6  "10th grade"
	7  "11th grade"
	8  "12th grade-no diploma"
	9  "HS graduate, GED"
	10 "Some college but no degree"
	11 "Associate degree-occupational/vocational"
	12 "Associate degree-academic program"
	13 "Bachelor's degree"
	14 "Master's degree"
	15 "Professional school"
	16 "Doctorate"
	;
	lab val educ92 educ92;
	label var educ91 "Education level in years (pre-1992 coding)";
 end;


 // Labor-market status (works for 1989 on);
 cap program drop cleanlfstat;
 program define cleanlfstat;
 args year;
	if `year'<=1988 {;
	gen lfstat=1 if esr==1 | esr==2;
	replace lfstat=2 if 3<=esr & esr<=4;
	replace lfstat=3 if 5<=esr & esr<=7;
	};
	else if `year'>=1989 & year<=1993 {;
	gen lfstat=1 if lfsr89==1 | lfsr89==2;
	replace lfstat=2 if 3<=lfsr89 & lfsr89<=4;
	replace lfstat=3 if 5<=lfsr89 & lfsr89<=7;
	};
	else if `year'>=1994 {;
	gen lfstat=1 if lfsr94==1 | lfsr94==2;
	replace lfstat=2 if 3<=lfsr94 & lfsr94<=4;
	replace lfstat=3 if 5<=lfsr94 & lfsr94<=7;
	};
	lab var lfstat "Labor-force status";
	lab def lfstat
	1 Employed
	2 Unemployed
	3 NILF
	;
	lab val lfstat lfstat;
	notes lfstat: CPS: derived from esr;
 end;

// Employed;
cap program drop cleanempl;
program define cleanempl;
	gen byte empl=0 if lfstat~=.;
	replace empl=1 if lfstat==1;
	lab var empl "Employed";
	notes empl: CPS: derived from pemlr;
end;

// Unemployed;
cap program drop cleanunem;
program define cleanunem;
	gen byte unem=0 if lfstat==1;
	replace unem=1 if lfstat==2;
	lab var unem "Unemployed";
	notes unem: CPS: derived from pemlr;
end;

// Not in labor force;
cap program drop cleannilf;
program define cleannilf;
	gen byte nilf=0 if lfstat~=.;
	replace nilf=1 if lfstat==3;
	lab var nilf "Not in labor force";
	notes nilf: CPS: derived from pemlr;
end;

// Self-employed (unincorporated);
cap program drop cleanselfemp;
program define cleanselfemp;
	gen byte selfemp=0 if class~=.;
	replace selfemp=1 if class==6 ;
	lab var selfemp "Self-employed";
	notes selfemp: Unincorporated self-employed only;
	notes selfemp: CPS: derived from a-clswkr, peio1cow, class;
end;

// Incorporated self-employed;
cap program drop cleanselfinc;
program define cleanselfinc;
	gen byte selfinc=0 if class~=.;
	replace selfinc=1 if class==5;
	lab var selfinc "Incorporated self-employed";
	notes selfinc: Incorporated self-employed only;
	notes selfinc: CPS: derived from a-clswkr, peio1cow;
end;


// CREATE ALLOCATION FLAG ;
cap pogram drop cleanallocationflag;
program define cleanallocationflag;
args year;
	if `year'<=1993 {;
	gen byte alloc=0;
	replace alloc=1 if I25a==1 |I25d==1;
	label var alloc "=1 if wage or hours allocated";
	replace alloc=. if wage==.;
	};
	
	*one allocation flag missing: I25d (weekly earnings)
	*In 1994-1998, allocation flags coded from 0 to 53 ;
	else if `year'>=1994 & `year'<=1998 {;
	gen byte alloc=0;
	replace alloc=1 if I25a>=10 & I25a!=.;
	replace alloc=1 if AF1>=10 & AF1!=.;
	replace alloc=1 if AF3>=10 & AF3!=. ;
	replace alloc=. if wage==.;
	label var alloc "=1 if hourly wage or hours allocated";
	};
	
	*In 1994-1999, allocation flags coded from 0 to 53 ;
	else if `year'==1999 {;
	gen byte alloc=0;
	replace alloc=1 if I25a>=10 & I25a!=.;
	replace alloc=1 if AF1>=10 & AF1!=.;
	replace alloc=1 if AF3>=10 & AF3!=. ;    
	replace alloc=1 if I25d==1;
	label var alloc "=1 if hourly wage or hours allocated";
	replace alloc=. if wage==.;
	};
end;

****************************************************************************************
************ CODE TO READ IN AND STACK THE DATA. *************************************
*****************************************************************************************
*Loop & stack data, to prepare for longitudinal links;
 forvalues y=`startyr'/`endyr' {;
 	 tempfile month`y';
 	  if `y'>=1979 & `y'<=2020  	  di "Starting year " `y' ".";
 	  else {;
 	  	 di "ERROR: YEAR " %tm `y' "OUT OF RANGE";
 	  	 error;
 	  };
      if `y'<=1993 di "WARNING: PROGRAM OUT OF DESIGN RANGE: " `y' ".";
      
    local year=`y';
    if `year'<2000 local yy=`year'-1900;
    else if `year'>=2010 local yy=`year'-2000;
    else {;
    	local yy=`year'-2000;
    	local yy "0`yy'";
    };

    local origfile "morg`yy'"; 


*Read in the data;
    if `year'<2019 {;
       if `doasproject'==1 project, original("`morg'/`origfile'.dta.gz");
      !zcat `morg'/`origfile'.dta.gz > ./tmp_`origfile'.dta;
	    use tmp_`origfile'.dta, clear;
      !rm -f tmp_`origfile'.dta; 
    };
    else {;
       if `doasproject'==1 project, uses("`scratch'/morg`year'.dta");
       use `scratch'/morg`year', clear;
    };
   rename intmonth month;
   rename minsamp mis;
   rename lineno linenum;
   rename weight orgwgt; 
    
//Now give each new HH a sort-order number, and use this to generate a tiebreaker;
    if `year'<=2003 gen hrhhid2=.;
    rename hhid hrhhid;
    rename hhnum hh_num;
    replace hh_num=hh_num[_n-1] if missing(hh_num); //RY, 2/22/18, There were a few missing observations in hh_num, which seems problematic;
    gen origorder=_n;
    gen newhh=(hrhhid~=hrhhid[_n-1] | hh_num~=hh_num[_n-1]) ;
    replace newhh=1 if _n==1;
    gen hh_sortnum=sum(newhh);
    drop newhh;
    sort hrhhid hh_num hh_sortnum linenum origorder;
    egen hh_sortnum2=group(hrhhid hh_num hh_sortnum);
    by hrhhid hh_num: gen hh_tiebreak=1+(hh_sortnum2-hh_sortnum2[1]);
    //There are still a few ties -- people listed all together in the same HH
    //with the same line number. Break these ties also./;
      sort hrhhid hh_num hh_tiebreak linenum origorder;
      by hrhhid hh_num hh_tiebreak linenum: gen p_tiebreak=_n;
      isid hrhhid hh_num hh_tiebreak linenum p_tiebreak;
      drop hh_sortnum;
      sort origorder;   
    
    //create one class of worker variable;
    if `year'>=1994 rename class94 class;
     
    //clean occupation code names  
    gen peio1ocd=.;
    if `year'<=1982 replace peio1ocd=occ70;
    else if `year'<=2001 & `year'>=1983 replace peio1ocd=occ80;
    else if `year'<=2010 & `year'>=2002 replace peio1ocd=occ00;
    else if `year'>=2011 & `year'<=2012 replace peio1ocd=occ2011;
    else if `year'>=2013                replace peio1ocd=occ2012;
    
   //merging in state labels
   if `year'<=1988 {;
     rename state gestcen;
     merge m:1 gestcen using
	     `pdir'/rawdata/readrawcps/cpssupplemental/gestcen_gestfips_match.dta, assert(3) keep(3);
     drop _merge;
   }; 
   else if `year'>=1989 {;  
     rename stfips gestfips; 
     merge m:1 gestfips using
	     `pdir'/rawdata/readrawcps/cpssupplemental/gestcen_gestfips_match.dta, assert(3) keep(3);
	 drop _merge;
   };
	
    gen yearmo=ym(year, month);
    format yearmo %tm;
    
  *Recode variables;
    cleangender `y';
    cleanmaritalstatus `y';
    cleanpersonid `y';
    cleaneduc `y';
    cleanlfstat `y';
    cleanempl `y';
    cleanunem `y';
    cleannilf `y';
    *cleanearnwke  `y';
    *cleanwnber `y';
    *cleanwage `y';
    *cleanallocationflag `y';
    ceprwage `y';
    

  keep yearmo month year age sex educ92 educ91 gestcen gestfips mis 
       hh_id linenum orgwgt earnwt hh_tiebreak p_tiebreak hh_num
       usualhours usualhoursi wage_ceprstyle wage_nberstyle useweekly_ceprstyle tc_paidbyhour tc_weekpay tc_nberstyle tc_ceprstyle
       nilf peio1ocd
       ;

/*
   keep yearmo month year age sex educ92 educ91 gestcen gestfips mis 
	hh_id linenum orgwgt hh_tiebreak p_tiebreak hh_num usualhours paidhre w_nber 
	earnwke  female married nilf peio1ocd 
	wage_ceprstyle wage_nberstyle useweekly_ceprstyle
	tc_paidbyhour tc_weekpay tc_nberstyle tc_ceprstyle
    ;
*/
    /*uhourse alloc*/ 

;
   rename wage_ceprstyle wage;
   rename wage_nberstyle wage_nber;
   rename tc_ceprstyle tc_wage;
   rename tc_nberstyle tc_nber;
   compress;
   tempfile morg`y';
   save `morg`y'';
   
 };
    
 *Stack the data;
     local start=1;
     forvalues y=`startyr'/`endyr' {;
     if `start'==1 {;
     	 use `morg`y'';
     	 local start=0;
     };
     else {;
    	 di "Appending year " `y' ".";
     	 append using `morg`y'';
     };
   };
     
   
****************************************************************************************
************ CODE TO CONVERT NOMINAL TO REAL. *************************************
*****************************************************************************************

*Real wages;
 sort yearmo;
 *drop _merge;
 merge m:1 yearmo using `scratch'/cpi, keepusing(yearmo monthly);
 assert _merge>1 if yearmo<=ym(2015,11);
 *drop _merge;
 rename monthly cpi;
 su cpi if yearmo==ym(2009,1), meanonly;
 local basecpi=r(mean);
 su cpi if yearmo==ym(2001,1), meanonly;
 local cpijan01=r(mean);
 drop if _merge==2;
 drop _merge;
 gen rw=wage/(cpi/`basecpi'); 
 gen rw_nber=wage_nber/(cpi/`basecpi'); 
 drop cpi; 
 
*Trim at 1/200 Jan2001 dollars;
 local cpitrim=`cpijan01';
 foreach v of varlist rw rw_nber {;
  replace `v'=. if `v'<(`basecpi'/`cpitrim') | `v'>(200*`basecpi'/`cpitrim');
 };
 gen rw_l=ln(rw);
 gen rw_nber_l=ln(rw_nber);


label var rw "Wage (09$), adapted CPER method, trimmed at 1/200 (01$)";
label var rw_l "Log of real wage, adapted CPER method";

sort year month gestcen hh_id linenum mis;
cap drop __0*;

*Create occupation dependent variables;
  *Occupation period (based on changes to the census occupation coding: bls.gov/cps/spcoccind.htm);
    gen period=.;
    replace period=1990 if year<=1991;
    replace period=1992 if year>=1992 & year<=2002;
    replace period=2003 if year>=2003 & year<=2010;
    replace period=2011 if year==2011;
    replace period=2012 if year>=2013;
    if year==2012 {;
	replace period=2011 if month<=4;
	replace period=2012 if month>=5;
};
  
  *Occupation mean earnings;
  sort period peio1ocd;
  by period peio1ocd: egen rwage_occup=mean(rw_nber) if peio1ocd>=1 ;
  
  
  keep yearmo month year age sex educ92 educ91 gestfips mis hh_id gestcen linenum orgwgt earnwt hh_tiebreak p_tiebreak hh_num
       usualhours usualhoursi wage wage_nber useweekly_ceprstyle tc_paidbyhour tc_weekpay tc_nber tc_wage
       nilf rwage_occup rw rw_l rw_nber rw_nber_l
       ;
	
	
compress;
save `scratch'/extractorg_morg.dta, replace;
! gzip -f `scratch'/extractorg_morg.dta;
if `doasproject'==1 project, creates("`scratch'/extractorg_morg.dta.gz");

