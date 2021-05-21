// ceprwage.do
//
// Create hourly wages and topcode indicators for the CPS ORG data, as
// distributed by NBER.
//
// Code adapted by Jesse Rothstein, May 23, 2018
//
// Source was CEPR code for the CPS ORG (esp. cepr_org_wages), version 2.4,Mar 22, 2019.
// Copyright 2018 CEPR and John Schmitt, GNU GPL version 2
//
// Written to be called as "ceprwage <year>" when the NBER MORG file has been loaded.

cap program drop origvars
program define origvars
  syntax varlist
  foreach v of varlist `varlist' {
    rename `v' orig_`v'
  }
end
  
cap program drop ceprwage
program define ceprwage
  args year


/* Paid by the hour indicator variable */
gen paidbyhour=paidhre
replace paidbyhour=0 if paidhre==2
origvars paidhre 
lab var paidbyhour "Paid by hour"
notes paidbyhour: Indicates BLS records respondent's earnings by hour
notes paidbyhour: Not a consistent indicator of "hourly worker" status
notes paidbyhour: CPS: derived from a-hrlywk, peernhry

/* Hourly earnings if "paid by hour" (paidhre==1)  - excludes OTC*/
gen wage_paidbyhour=.
replace wage_paidbyhour=earnhre/100 if paidbyhour==1 /* convert from pennies to dollars */
origvars earnhre 
lab var wage_paidbyhour "Hourly wage (if hourly worker)"
notes wage_paidbyhour: Dollars per hour
notes wage_paidbyhour: For hourly workers only
notes wage_paidbyhour: Excludes overtime, tips, commissions
notes wage_paidbyhour: Top-code 1979-84: 99.00
notes wage_paidbyhour: Top-code 1985-98: set so that hours worked times earnhre /*
*/ < weekly earnings top-code
notes wage_paidbyhour: Top-code 1998-: set so that hours worked times earnhre /*
*/ < 1,998, which is less than the weekly earnings top-code of 2,884 /*
*/ [BLS documentation; check]
notes wage_paidbyhour: Top-code 1985-: NBER states that top-code not applied /* 
*/ to all observations
notes wage_paidbyhour: Bottom-code: 1979-88: 0.50; 1994: 0.10; 1995: 0.20
notes wage_paidbyhour: set to missing if prernhly<0 to get rid of neg values
notes wage_paidbyhour: CPS: a-herntp, prernhly, pternhly

/*
	/* Hourly earnings allocated */

if 1979<=`year' & `year'<=1988 {
gen byte blsimph=0 if I25c~=.
replace blsimph=1 if I25c==1
}
if 1989<=`year' & `year'<=1993 {
gen byte blsimph=0 if I25c~=.
replace blsimph=1 if (1<=I25c & I25c<=8)
}
if 1994==`year' {
gen byte blsimph=. /* prhernal missing in cps basic 1994 */
}
if 1995==`year' {
  gen byte blsimph=. /* prhernal missing Jan-Aug 1995 */
  replace blsimph=0 if (9<=month & month<=12) & prhernal==0
  replace blsimph=1 if (9<=month & month<=12) & prhernal==1
}
if 1996<=`year' & `year'<=2019 {
gen byte blsimph=0 if prhernal==0
replace blsimph=1 if prhernal==1
}

lab var blsimph "BLS allocated hourly earnings"
notes blsimph: Indicates BLS allocated usual hourly earnings
notes blsimph: CPS: I25c, prhernal
notes blsimph: BLS provides no allocation info Jan 94-Aug 95
notes blsimph: According to Hirsch & Schumacher (2004), allocation flags/*
	      */ unreliable 1989-1993
notes blsimph: For 1989-1993, underlying data don't use complete range

	/* Weekly earnings allocated */

if 1979<=`year' & `year'<=1988 {
gen byte blsimpw=0 if I25d~=.
replace blsimpw=1 if I25d==1
}
if 1989<=`year' & `year'<=1993 {
gen byte blsimpw=0 if I25d~=.
replace blsimpw=1 if (1<=I25d & I25d<=8)
}
if 1994==`year' {
gen byte blsimpw=. /* prwernal missing in cps basic 1994 */
}
if 1995==`year' {
    gen byte blsimpw=.  /* prwernal missing Jan-Aug 1995 */
    replace blsimpw=0 if (9<=month & month<=12) & prwernal==0
    replace blsimpw=1 if (9<=month & month<=12) & prwernal==1
}
if 1996<=`year' & `year'<=2019 {
gen byte blsimpw=0 if prwernal==0
replace blsimpw=1 if prwernal==1
}

lab var blsimpw "BLS allocated weekly earnings"
notes blsimpw: Indicates BLS allocated usual weekly earnings
notes blsimpw: CPS: I25d, prwernal
notes blsimpw: BLS provides no allocation info Jan 94-Aug 95
notes blsimpw: According to Hirsch & Schumacher (2004), allocation flags/*
	      */ unreliable 1989-1993

/* Paid by the hour indicator variable */

if 1979<=`year' & `year'<=1993 {
replace paidhre=0 if paidhre==2
}
if 1994<=`year' & `year'<=2019 {
gen paidhre=0 if peernhry==2
replace paidhre=1 if peernhry==1
}
lab var paidhre "Paid by hour"
notes paidhre: Indicates BLS records respondent's earnings by hour
notes paidhre: Not a consistent indicator of "hourly worker" status
notes paidhre: CPS: derived from a-hrlywk, peernhry

/* Hourly earnings if "paid by hour" (paidhre==1) */

gen wage1=.

if 1979<=`year' & `year'<=1993 {
replace wage1=earnhre/100 if paidhre==1 /* convert from pennies to dollars */
}
if 1994<=`year' & `year'<=2019 {
replace wage1=prernhly/100 if paidhre==1 /* convert from pennies to dollars */
replace wage1=. if prernhly<0
}
lab var wage1 "Hourly wage (if hourly worker)"
notes wage1: Dollars per hour
notes wage1: For hourly workers only
notes wage1: Excludes overtime, tips, commissions
notes wage1: Top-code 1979-84: 99.00
notes wage1: Top-code 1985-98: set so that hours worked times earnhre /*
*/ < weekly earnings top-code
notes wage1: Top-code 1998-: set so that hours worked times earnhre /*
*/ < 1,998, which is less than the weekly earnings top-code of 2,884 /*
*/ [BLS documentation; check]
notes wage1: Top-code 1985-: NBER states that top-code not applied /* 
*/ to all observations
notes wage1: Bottom-code: 1979-88: 0.50; 1994: 0.10; 1995: 0.20
notes wage1: set to missing if prernhly<0 to get rid of neg values
notes wage1: CPS: a-herntp, prernhly, pternhly

 Usual weekly earnings including overtime, tips, commissions 
   nonhourly workers (paidhre==0) and hourly workers (paidhre==1)
   
    The NBER extract contains three usual weekly earnings variables, 
which we include here for 1979-1993.

The first two are uearnwk ("unedited," available 1979-1993) and uearnwke 
("edited," available 1979-1988 only). For *hourly* workers, these variables
give the usual weekly earnings *including* overtime, tips, and commissions. 
Between 1989 and 1993, when uearnwke is not available, few observations on 
hourly workers show uearnwk greater than the product of earnhre (usual 
hourly pay) times uhourse (usual weekly hours), suggesting that the CPS may 
not have reliably captured the overtime, tips, and commissions received by 
hourly workers between 1989 and 1993. 

For hourly workers in 1979-1988, the CEPR extract uses uearnwke for usual 
weekly earnings including overtime, tips, and commissions. For hourly workers
1989-1993, the CEPR extract uses uearnwk, which does appear to capture well
overtime, tips, and commissions.

The third variable is earnwke ("edited," available 1979-1993). For hourly
workers, this variable contains the product of earnhre (usual hourly pay) 
times uhourse (usual weekly hours); so, by definition, it excludes overtime,
tips, and commissions for hourly workers. For nonhourly workers, earnwke 
does include overtime, tips, and commissions.

*/

gen weekpay=.
	
if 1979<=`year' & `year'<=1988 {
// replace uearnwk=. if uearnwk<0
  replace weekpay=earnwke if paidbyhour==0
  replace weekpay=uearnwke if paidbyhour==1
  replace weekpay=. if earnwke<0
  origvars earnwke uearnwke uearnwk
}
if 1989<=`year' & `year'<=1993 {
// replace uearnwk=. if uearnwk<0
  gen byte uearnwke=.
  replace weekpay=earnwke if paidbyhour==0
  replace weekpay=uearnwk if paidbyhour==1 & uearnwk>=0 /* note shift from uearnwke to uearnwk */
  origvars earnwke uearnwke uearnwk
}
if 1994<=`year' & `year'<=2019 {
// gen byte uearnwk=.
// gen uearnwke=.
// gen earnwke=.
  replace weekpay=earnwke /* convert from pennies to dollars */
  replace weekpay=. if earnwke<0
  origvars earnwke
}
lab var weekpay "Weekly pay"
notes weekpay: Dollars per week
notes weekpay: For nonhourly and hourly workers
notes weekpay: Includes overtime, tips, commissions
notes weekpay: Top-code: 1979-88: 999; 1989-97: 1923; 1998-: 2884
notes weekpay: CPS 1979-88: earnwke for non-hourly, uearnwke for hourly
notes weekpay: CPS 1989-93: earnwke for non-hourly, uearnwk for hourly
notes weekpay: CPS 1994-: prernwa


/* Impute hours for missing hours (which includes "hours vary" on the NBER files*/
gen usualhours = uhourse if uhourse>0 & uhourse<.
 *use actual hours last week if usual hours is missing and actual hours is consistent with FT/PT info
  gen usualhoursi=usualhours
  if `year'>=1979 & `year'<=1988 {
    gen isft=(uhourse>=35) if uhourse<.
    // uhours35 doesnt exist 1989-1993, and is very often missing before that
    replace isft=(uhours35==1) if isft==. & uhours35<.
    replace isft=(inlist(ftpt79,1,3)) if isft==. & inlist(ftpt79,1,2,3,4,5)
    origvars uhourse uhours35 ftpt79
  }
  if `year'>=1989 & `year'<=1993 {
    gen isft=(uhourse>=35) if uhourse<.
    // uhours35 doesnt exist 1989-1993, and is very often missing before that
    replace isft=(inlist(ftpt89,2,3,6)) if isft==. & inlist(ftpt89,2,3,4,5,6,7)
    origvars uhourse ftpt89
  }
  if `year'>=1994 & `year'<=2019 {
    gen isft=(uhourse>=35) if uhourse<.
    replace isft=(inlist(ftpt94,2,3,11)) if isft==. & ftpt94>1 & ftpt94<.
    origvars uhourse ftpt94
  }
  gen useactual=(isft==1 & hourslw>=35) | (isft==0 & hourslw<35)
  replace usualhoursi=hourslw if usualhours==. & useactual==1
  origvars hourslw
  replace isft=1 if isft==.
  *Assign mean hours by gender and part time status if necessary
   sort sex isft
   by sex isft: egen meanhrs=mean(usualhours)
   replace usualhoursi=meanhrs if usualhoursi==.
   drop meanhrs
lab var usualhours "Usual hours, main job"
notes usualhours: Edited
notes usualhours: CPS: a-uslhrs, peernhro
lab var usualhoursi "Usual hours, main job, (with imputations)"
notes usualhoursi: CPS: a-uslhrs, peernhro
notes usualhoursi: Use actual hours to impute if consistent with FT/PT info
notes usualhoursi: Use mean by gender/FT if actual hours arent usable.
drop isft useactual

/* Usual hourly earnings including overtime, tips, commissions 
   nonhourly workers (paidhre==0)
*/
gen wage_nonhourly=.
replace wage_nonhourly=weekpay/usualhoursi if weekpay>0 & usualhoursi>0
lab var wage_nonhourly "Hourly wage "
notes wage_nonhourly: Dollars per hour
notes wage_nonhourly: Computed for hourly and non-hourly workers
notes wage_nonhourly: Includes overtime, tips, commissions
notes wage_nonhourly: Usual weekly earnings / usual weekly hours
notes wage_nonhourly: 1979-1993: weekpay/uhourse; 1994-present: weekpay/pehrusl1
notes wage_nonhourly: CPS top code weekly earnings in 1979-1988: 999
notes wage_nonhourly: CPS top code weekly earnings in 1989-1997: 1923
notes wage_nonhourly: CPS top code weekly earnings in 1998-: 2884



/* OTC receipt and amount, used only after 1994 -- not in NBER files 
gen byte otcrec=.
if 1994<=`year' & `year'<=2017 {
  replace otcrec=0 if paidbyhour==1 & peernuot==2
  replace otcrec=1 if paidbyhour==1 & peernuot==1
  origvars peernuot
}
lab var otcrec "Usually receive overtime, tips, commissions"
notes otcrec: Hourly workers only
notes otcrec: Only 1994-present
notes otcrec: CPS: Derived from peernuot
* Weekly earnings from overtime, tips, commissions 1994- 
gen byte otcamt=.
if 1994<=`year' & `year'<=2017 {
  replace otcamt=peern/100 if otcrec==1 & otcamt<0
}
format otcamt %5.0f // format to no decimal places 
lab var otcamt "Weekly earnings overtime, tips, commissions"
notes otcamt: Hourly workers only
notes otcamt: Only 1994-present
notes otcamt: CPS: derived from peern

* Hourly earnings, including OTC, if paid by hour  
gen wage_paidbyhour_withotc=weekpay/usualhours if paidbyhour==1 & weekpay<. & usualhours<. 
replace wage_paidbyhour_withotc=wage_paidbyhour if ///
        (wage_paidbyhour_withotc<wage_paidbyhour & wage_paidbyhour~=.) & paidbyhour==1 & wage_paidbyhour<.
replace wage_paidbyhour_withotc=wage_paidbyhour if paidbyhour==1 & wage_paidbyhour_withotc==.
  // prevents wage including overtime, tips, and commissions
  // from being less than wage excluding overtime, tips, and
  // commissions
if 1994<=`year' & `year'<=2017 {
  // About one-fourth of hourly workers report wages at 
  // other periodicities (weekly, monthly, etc.); these workers are not asked
  // provide peernhro, which we use to calculate minimum wage for the
  // rest of hourly workers. For the subset of hourly workers without a 
  // valid peernhro, we estimate hourly earnings including overtime, tips, 
  // and commissions by dividing weekly earnings (prernwa) by usual hours worked 
  // (pehrusl1) 
  // For hourly workers with information on peernhro, we use that
  // information to calculate wages with overtime, tips, and commissions. 
  replace wage_paidbyhour_withotc=wage_paidbyhour+(otcamt/usualhours) if paidbyhour==1 & ///
          otcrec==1 & (0<otcamt & otcamt<.) & (0<usualhours & usualhours<=99) 
}
// JR edit: Dont use OTC calculation if it is more than 5*straight pay
replace wage_paidbyhour_withotc=wage_paidbyhour if wage_paidbyhour_withotc<. & ///
        wage_paidbyhour_withotc>5*wage_paidbyhour
*/


/* Topcoding */
//Hourly wages are always top-coded at 99.
 gen tc_paidbyhour=(wage_paidbyhour>=99) if wage_paidbyhour<.
 replace wage_paidbyhour=99 if tc_paidbyhour==1
// After 1985, hourly wages are topcoded so wages*hours< weekly pay topcode 
  // Codebooks sometimes say limit is 100K/year (2K/week), but no spikes in the data.
  // Note lots of observations above topcode, and weekly earnings still have a spike
  // at 1923 in 1998.
if `year'>=1979 & `year'<=1988 local weektc 999
if `year'>=1989 & `year'<=1997 local weektc 1923
if `year'>=1998 & `year'<=2019 local weektc 2884
if `year'>=1985 & `year'<=2019 {
  replace tc_paidbyhour=2 if (wage_paidbyhour*usualhoursi>=`weektc') & ///
                             wage_paidbyhour<. & usualhoursi<. 
  replace wage_paidbyhour=`weektc'/usualhoursi if tc_paidbyhour==2
}
gen tc_weekpay=(weekpay>=`weektc') if weekpay<.
replace weekpay=`weektc' if tc_weekpay==1
replace wage_nonhourly=`weektc'/usualhoursi if paidbyhour==0 & tc_weekpay==1 & usualhoursi>0

// JR: If this is above $100/hour and hours are low, or if it is above $200/hour,
// assume hours are wrong and set to missing
  replace wage_nonhourly=. if wage_nonhourly>200 | ///
            (wage_nonhourly>100 & usualhoursi<30)
  replace tc_weekpay=. if wage_nonhourly==.
  
                                
/* NBER-style wage variable usual hourly earnings
   INcluding overtime, tips, commissions for nonhourly workers
   EXcluding overtime, tips, commissions for hourly workers
*/
gen wage_nberstyle=wage_paidbyhour if paidbyhour==1
replace wage_nberstyle=wage_nonhourly if paidbyhour==0
lab var wage_nberstyle "Hourly wage"
notes wage_nberstyle: Dollars per hour
notes wage_nberstyle: For hourly and nonhourly workers
notes wage_nberstyle: Approximates NBER's recommended wage variable
notes wage_nberstyle: Includes overtime, tips, commissions for nonhourly
notes wage_nberstyle: Excludes overtime, tips, commissions for hourly
notes wage_nberstyle: No adjustments for top-coding
notes wage_nberstyle: No trimming of outliers
notes wage_nberstyle: Excludes nonhourly workers whose usual hours vary
gen tc_nberstyle=tc_paidbyhour if paidbyhour==1
replace tc_nberstyle=tc_weekpay if paidbyhour==0

/* CEPR-style wage variable (wage4):
   Uses wage_paidbyhour_withotc for hourly workers, and wage_nonhourly for others
   Note that with NBER files, this doesnt use actual information on OT pay. */
*Alternative version of OTC computation that is possible in the NBER files.
*Use weekly earnings for all workers, unless this is less than hourly wage or hours missing
 gen useweekly_ceprstyle=1 if wage_nonhourly<. & usualhours<.
 replace useweekly_ceprstyle=0 if paidbyhour==1 & (wage_nonhourly==. | usualhours==.) & ///
                                  wage_paidbyhour<.
 replace useweekly_ceprstyle=0 if paidbyhour==1 & wage_nonhourly<wage_paidbyhour & ///
                                  wage_paidbyhour<.
 replace useweekly_ceprstyle=1 if wage_nonhourly<. & wage_paidbyhour==.
*Note that the vast majority of observations use the weekly pay, so arent
*necessarily subject to the $99 limit.
  // prevents wage including overtime, tips, and commissions
  // from being less than wage excluding overtime, tips, and
  // commissions

gen wage_ceprstyle=wage_paidbyhour if useweekly_ceprstyle==0
replace wage_ceprstyle=wage_nonhourly if useweekly_ceprstyle==1
lab var wage_ceprstyle "Hourly wage"
notes wage_ceprstyle: Dollars per hour
notes wage_ceprstyle: For hourly and nonhourly workers
notes wage_ceprstyle: Includes overtime, tips, commissions for nonhourly and hourly
notes wage_ceprstyle: Covers only hourly workers who report hourly rate of pay
notes wage_ceprstyle: No adjustments for top-coding
notes wage_ceprstyle: No trimming of outliers
notes wage_ceprstyle: Excludes nonhourly workers whose usual hours vary
notes wage_ceprstyle: Uses weekly earnings for hourly workers, to get OTC.
notes wage_ceprstyle: In 1994-2016, CPLS collects OTC, but NBER files dont have it.

gen tc_ceprstyle=tc_paidbyhour if useweekly_ceprstyle==0
replace tc_ceprstyle=2*tc_weekpay if useweekly_ceprstyle==1
label def tc_l 0 "Not topcoded" 1 "TC based on hourly rate" 2 "TC based on weekly earnings"
label values tc_ceprstyle tc_cepr_l
label values tc_nberstyle tc_cepr_l

// I have not been careful to restrict wage information to wage and salary workers, though
// there are sometimes values for the self employed
foreach v of varlist wage_* tc_* useweekly_ceprstyle weekpay paidbyhour {
  if `year'>=1979 & `year'<=1988 {
    replace `v'=. if !inlist(classer,1,2)
  }
  if `year'>=1989 & `year'<=1993 {
    replace `v'=. if !inlist(classer2,1,2,3,4)
  }
  if `year'>=1994 & `year'<=2019 {
    replace `v'=. if !inlist(class,4,5,1,2,3)
  }
}
end
   
