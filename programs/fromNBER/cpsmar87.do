********************************************************************************
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
	local dofile "cpsmar87"
	local sig "Not run as part of project!"
}

set more off
local rootdir "`pdir'"
local thisdir "`pdir'"

global nberdata "~/data/cps/march/rawdata"
global nbercode "`pdir'/programs/fromNBER"

local prepdata "`pdir'/scratch"


***************************************************************************************************************
if `doasproject'==1 {
project, original(${nberdata}/`dofile'.zip)
project, relies_on(${nbercode}/`dofile'.dct)
}
* Unzip data *

! zcat ${nberdata}/`dofile'.zip > ${nberdata}/`dofile'.dat 

*Based on code by Jean Roth Mon Oct 7 16:04:25 EDT 2002

* Read in data *
quietly infile using "${nbercode}/`dofile'.dct", using("${nberdata}/`dofile'.dat") clear

replace     h_seq =     h_seq[_n-1]  if  hrecord>1
replace     hhpos =     hhpos[_n-1]  if  hrecord>1
replace  h_numper =  h_numper[_n-1]  if  hrecord>1
replace   hnumfam =   hnumfam[_n-1]  if  hrecord>1
replace    h_type =    h_type[_n-1]  if  hrecord>1
replace  ppindind =  ppindind[_n-1]  if  hrecord>1
replace   h_hhnum =   h_hhnum[_n-1]  if  hrecord>1
replace     h_mis =     h_mis[_n-1]  if  hrecord>1
replace   h_idnum =   h_idnum[_n-1]  if  hrecord>1
replace  h_typebc =  h_typebc[_n-1]  if  hrecord>1
replace    bniwgt =    bniwgt[_n-1]  if  hrecord>1
replace     numhu =     numhu[_n-1]  if  hrecord>1
replace   pmsrank =   pmsrank[_n-1]  if  hrecord>1
replace    region =    region[_n-1]  if  hrecord>1
replace  division =  division[_n-1]  if  hrecord>1
replace  mststate =  mststate[_n-1]  if  hrecord>1
replace  mststran =  mststran[_n-1]  if  hrecord>1
replace    mprank =    mprank[_n-1]  if  hrecord>1
replace  smsafips =  smsafips[_n-1]  if  hrecord>1
replace    hmsa_r =    hmsa_r[_n-1]  if  hrecord>1
replace   cccsmsa =   cccsmsa[_n-1]  if  hrecord>1
replace  smsasizr =  smsasizr[_n-1]  if  hrecord>1
replace   msarank =   msarank[_n-1]  if  hrecord>1
replace     hmssz =     hmssz[_n-1]  if  hrecord>1
replace  landusag =  landusag[_n-1]  if  hrecord>1
replace    aitem9 =    aitem9[_n-1]  if  hrecord>1
replace     Item4 =     Item4[_n-1]  if  hrecord>1
replace    Tenure =    Tenure[_n-1]  if  hrecord>1
replace    public =    public[_n-1]  if  hrecord>1
replace  lowerren =  lowerren[_n-1]  if  hrecord>1
replace   tenallo =   tenallo[_n-1]  if  hrecord>1
replace    cccode =    cccode[_n-1]  if  hrecord>1
replace  hhstatus =  hhstatus[_n-1]  if  hrecord>1
replace   hhund18 =   hhund18[_n-1]  if  hrecord>1
replace  hhinctot =  hhinctot[_n-1]  if  hrecord>1
replace  hhrecrel =  hhrecrel[_n-1]  if  hrecord>1
replace  hhnumnrl =  hhnumnrl[_n-1]  if  hrecord>1
replace  hhnumcpl =  hhnumcpl[_n-1]  if  hrecord>1
replace  hhtop5pc =  hhtop5pc[_n-1]  if  hrecord>1
replace  hhpctcut =  hhpctcut[_n-1]  if  hrecord>1
replace  hhincmre =  hhincmre[_n-1]  if  hrecord>1
replace  hmemb518 =  hmemb518[_n-1]  if  hrecord>1
replace   hhotlun =   hhotlun[_n-1]  if  hrecord>1
replace    hnumfs =    hnumfs[_n-1]  if  hrecord>1
replace  hhsupwgt =  hhsupwgt[_n-1]  if  hrecord>1
replace    fh_seq =    fh_seq[_n-1]  if  prectyp==3
replace     ffpos =     ffpos[_n-1]  if  prectyp==3
replace     fkind =     fkind[_n-1]  if  prectyp==3
replace     ftype =     ftype[_n-1]  if  prectyp==3
replace  fpersons =  fpersons[_n-1]  if  prectyp==3
replace  fhouhind =  fhouhind[_n-1]  if  prectyp==3
replace  fspousin =  fspousin[_n-1]  if  prectyp==3
replace  flastind =  flastind[_n-1]  if  prectyp==3
replace  fspanhea =  fspanhea[_n-1]  if  prectyp==3
replace    fincws =    fincws[_n-1]  if  prectyp==3
replace    fincse =    fincse[_n-1]  if  prectyp==3
replace    fincfr =    fincfr[_n-1]  if  prectyp==3
replace   finctot =   finctot[_n-1]  if  prectyp==3
replace  fincearn =  fincearn[_n-1]  if  prectyp==3
replace   fincoth =   fincoth[_n-1]  if  prectyp==3
replace  flfincws =  flfincws[_n-1]  if  prectyp==3
replace  flpincse =  flpincse[_n-1]  if  prectyp==3
replace  flfincfr =  flfincfr[_n-1]  if  prectyp==3
replace  flfincus =  flfincus[_n-1]  if  prectyp==3
replace  flfincsp =  flfincsp[_n-1]  if  prectyp==3
replace  frecode1 =  frecode1[_n-1]  if  prectyp==3
replace  frecod98 =  frecod98[_n-1]  if  prectyp==3
replace  frecode5 =  frecode5[_n-1]  if  prectyp==3
replace  frecode6 =  frecode6[_n-1]  if  prectyp==3
replace  frecode7 =  frecode7[_n-1]  if  prectyp==3
replace     frec8 =     frec8[_n-1]  if  prectyp==3
replace     frec9 =     frec9[_n-1]  if  prectyp==3
replace    fincm2 =    fincm2[_n-1]  if  prectyp==3
replace    fsinc2 =    fsinc2[_n-1]  if  prectyp==3
replace   fsupwgt =   fsupwgt[_n-1]  if  prectyp==3
replace  fhusbinx =  fhusbinx[_n-1]  if  prectyp==3
replace  ffrectyp =  ffrectyp[_n-1]  if  prectyp==3


replace hrecord = 1
keep if prectyp==3



*Everything below this point are value labels

#delimit ;
;

label values hrecord  hrecord;
label define hrecord 
	1           "Household record"              
;

label values h_type h_type;
label define h_type
	1	"Interview Household, with Householder"
	2	"Group quarters (collective hh)"
	3	"Non-interview type A"
	4	"noninterview type B/C"
;

label values ppindind ppindpind;
label define ppindind
	00	"NIU (Not in universe)"
;

label values h_hhnum h_hhnum;
label define h_hhnum
	1	"Household 1"
	2	"Household 2"
	3	"Household 3"
	4	"Household 4"
	5	"Household 5"
	6	"Household 6"
	7	"Household 7"
	8	"Household 8"
;

label values itm14rc itm14rc;
label define itm14rc
	0	"NIU"
	1	"White"
	2	"Black"
	3	"Other"
;

label values region region;
label define region
	1	"Northeast"
	2	"Midwest"
	3	"South"
	4	"West"
;

label values division division;
label define division
	1	"New England"
	2	"Middle Atlantic"
	3	"East North Central"
	4	"West North Central"
	5	"South Atlantic"
	6	"East South Central"
	7	"West South Central"
	8	"Mountain"
	9	"Pacific"
;

label values mststate mststate;
label define mststate
	11	"Maine"
	12	"New Hampshire"
	13	"Vermont"
	14	"Massachusetts"
	15	"Rhode Island"
	16	"Connecticut"
	21	"New York"
	22	"New Jersey"
	23	"Pennsylvania"
	31	"Ohio"
	32	"Indiana"
	33	"Illinois"
	34	"Michigan"
	35	"Wisconsin"
	41	"Minnesota"
	42	"Iowa"
	43          "Missouri"                      
	44          "North Dakota"                  
	45          "South Dakota"                  
	46          "Nebraska"                      
	47          "Kansas"                        
	51          "Delaware"                      
	52          "Maryland"                      
	53          "District of Columbia"          
	54          "Virginia"                      
	55          "West Virginia"                 
	56          "North Carolina"                
	57          "South Carolina"                
	58          "Georgia"                       
	59          "Florida"                       
	61          "Kentucky"                      
	62          "Tennessee"                     
	63          "Alabama"                       
	64          "Mississippi"                   
	71          "Arkansas"                      
	72          "Louisiana"                     
	73          "Oklahoma"                      
	74          "Texas"                         
	81          "Montana"                       
	82          "Idaho"                         
	83          "Wyoming"                       
	84          "Colorado"                      
	85          "New Mexico"                    
	86          "Arizona"                       
	87          "Utah"                          
	88          "Nevada"                        
	91          "Washington"                    
	92          "Oregon"                        
	93          "California"                    
	94          "Alaska"                        
	95          "Hawaii"                        
;

label values mststran mststran;
label define mststran
	1	"MSA/PMSA"
	2	"Non MSA/PMSA"
	3	"Not identifiable"
;

label values smsasizr smsasizr;
label define smsasizr
	0	"NIU"
	1	"3,000,000 or more"
	2	"1,000,000 - 2,999,999"
	3	"500,000 - 999,999"
	4	"250,000 - 499,999"
	5	"100,000 - 249,999"
;

label values hmssz hmssz;
label define hmssz
	1           "Not a MSA/CMSA or not identifiable"
	2           "100,000 - 249,999"             
	3           "250,000 - 499,999"             
	4           "500,000 - 999,999"             
	5           "1 million - 2,499,999"         
	6           "2.5 million - 4,999,999"       
	7           "5 million - 9,999,999"         
	8           "10 million or more"            
;

label values landusag landusag;
label define landusag
	1	"Nonfarm"
	2	"Farm"
;

label values aitem9 aitem9;
label define aitem9
	0	"Not allocated"
	1	"allocated"
;

label values hhstatus hhstatus;
label define hhstatus
	0	"NIU (Group Quarters)"
	1	"Family"
	2	"Nonfamily Householder living alone"
	3	"Nonfamily householder living with nonrelatives"
;

label values hhund18 hhund18;
label define hhund18
	00	"None"
;

label values hhinctot hhinctot;
label define hhinctot
	0	"No income"
;

label values hhrecrel hhrecrel;
label define hhrecrel
	0	"NIU"
	1	"All members related to householder"
	2	"No members related to householder"
	3	"Some members related to householder"
;

label values hhnumnrl hhnumnrl;
label define hhnumnrl
	0	"NIU or None"
	1	"1 person"
	2	"2 persons"
	3	"3 persons"
	4	"4 or more persons"
;

label values hhtop5pc hhtop5pc;
label define hhtop5pc
	0	"NIU"
	1	"Not in top 5 pct"
	2	"In top 5 pct"
;

label values hhpctcut hhpctcut;
label define hhpctcut
	0	"NIU"
	1	"Lowest 5 percent"
	2	"Second 5 percent"
	3	"Third 5 percent"
	4	"Fourth 5 percent"
	5	"Fifth 5 percent"
	6	"Sixth 5 percent"
	7	"Seventh 5 percent"
	8	"Eighth 5 percent"
	9	"Ninth 5 percent"
	10	"Tenth 5 percent"
	11 	"Eleventh 5 percent"
	12 	"Twelfth 5 percent"
	13	"Thirteenth 5 percent"
	14 	"Fourteenth 5 percent"
	15	"Fifteenth 5 percent"
	16 	"Sixteenth 5 percent"
	17	"Seventeenth 5 percent"
	18	"Eighteenth 5 percent"
	19	"Nineteenth 5 percent"
	20	"Top 5 percent"
;

label values hhincmre hhincmre;
label define hhincmre
	1       "None"    
	2	"Loss"
	3	"Under $2,500"                  
	4           "$2,500 to $4,999"              
	5           "$5,000 to $7,499"              
	6           "$7,500 to $9,999"              
	7           "$10,000 to $12,499"            
	8           "$12,500 to $14,999"            
	9           "$15,000 to $17,499"            
	10          "$17,500 to $19,999"            
	11          "$20,000 to $22,499"            
	12          "$22,500 to $24,999"            
	13          "$25,000 to $27,499"            
	14          "$27,500 to $29,999"            
	15          "$30,000 to $32,499"            
	16          "$32,500 to $34,999"            
	17          "$35,000 to $37,499"            
	18          "$37,500 to $39,999"            
	19          "$40,000 to $44,999"            
	20          "$45,000 to $49,999"            
	21          "$50,000 to $59,999"            
	22          "$60,000 to $74,999"  
	23	    "$75,000 and over"
;


label values pincom pincom;
label define pincom
	1       "None"    
	2	"Loss"	
	3	"$1 to $999"
	4	"$1,000 to $1,999"
	5	"$2,000 to $2,499"
	6	"$2,500	to $2,999"
	7	"$3,000 to $3,499"
	8	"$3,500 to $3,999"
	9	"$4,000 to $4,999"
	10	"$5,000 to $5,999"
	11	"$6,000 to $6,999"
	12	"$7,000 to $7,499"
	13	"$7,500 to $7,999"
	14	"$8,000 to $8,499"
	15	"$8,500 to $8,999"
	16	"$9,000 to $9,999"
	17	"$10,000 to $12,499"
	18	"$12,500 to $14,999"
	19	"$15,000 to $17,499"
	20	"$17,500 to $19,999"
	21	"$20,000 to $24,999"
	22	"$25,000 to $29,999"
	23	"$30,000 to $34,000"
	24	"$35,000 to $39,999"
	25	"$40,000 to $49,999"
	26	"$50,000 to $59,999"
	27	"$60,000 to $74,999"
	28	"$75,000 and over"
;

label values psinc1 psinc1;
label define psinc1
	0	"NIU"
	1	"Wage or salary only"
	2	"Nonfarm only"
	3	"Farm only"
	4	"Nonfarm and farm"
	5	"Wage or salary and nonfarm self-employment income only"
	6	"Wage or salary and farm self-employment income only"
	7	"Wage or salary, nonfarm and farm only"
	8	"Wage or salary and property inc only"
	9	"Wage or salary and other income"
	10	"Nonfarm inc, property inc only"
	11	"Nonfarm se income and other income"
	12	"Farm inc, property inc only"
	13 	"Farm se income and other income"
	14	"Wage/salary, nonfarm, property income"
	15	"Wage/salary, nonfarm, other income"
	16	"Wage/salary, farm, property income"
	17	"Wage/salary, farm se other income"
	18	"Other combinations"
	19	"Social security"
	20	"Public assistance income only"
	21	"Pension income only"
	22	"Pension and property income only"
	23	"Social security and public assistance"
	24	"Social security and property income"
	25	"Social security and pension income on"
	26	"Social security, pensions, property"
	27	"All other combinations"
	28	"No income"
;
	
label values rgenmob rgenmob;
label define rgenmob
	1	"nonmover"
	2	"Different house same county"
	3	"Different county, same state, same SMSA"
	4	"Different county, same state, different SMSA"
	5	"Diff county, dif state, contiguous"
	6	"Diff county, dif state, noncontiguous"
	7	"Movers from abroad"
	8	"Not in migration sample"
	9	"Moved within same state, diff. cnty."
;

label values prectyp prectyp;
label define prectyp
	3	"Person record"
;

label values parent parent;
label define parent
	0	"Yes, parent"
	1	"No parent"
;

label values spouse spouse;
label define spouse
	0	"Yes, spouse"
	1	"No spouse"
;	

label values migstate migstate;
label define migstate
	11	"Maine"
	12	"New Hampshire"
	13	"Vermont"
	14	"Massachusetts"
	15	"Rhode Island"
	16	"Connecticut"
	21	"New York"
	22	"New Jersey"
	23	"Pennsylvania"
	31	"Ohio"
	32	"Indiana"
	33	"Illinois"
	34	"Michigan"
	35	"Wisconsin"
	41	"Minnesota"
	42	"Iowa"
	43          "Missouri"                      
	44          "North Dakota"                  
	45          "South Dakota"                  
	46          "Nebraska"                      
	47          "Kansas"                        
	51          "Delaware"                      
	52          "Maryland"                      
	53          "District of Columbia"          
	54          "Virginia"                      
	55          "West Virginia"                 
	56          "North Carolina"                
	57          "South Carolina"                
	58          "Georgia"                       
	59          "Florida"                       
	61          "Kentucky"                      
	62          "Tennessee"                     
	63          "Alabama"                       
	64          "Mississippi"                   
	71          "Arkansas"                      
	72          "Louisiana"                     
	73          "Oklahoma"                      
	74          "Texas"                         
	81          "Montana"                       
	82          "Idaho"                         
	83          "Wyoming"                       
	84          "Colorado"                      
	85          "New Mexico"                    
	86          "Arizona"                       
	87          "Utah"                          
	88          "Nevada"                        
	91          "Washington"                    
	92          "Oregon"                        
	93          "California"                    
	94          "Alaska"                        
	95          "Hawaii"
	98	    "Overseas"                        
;

label values paidhour paidhour;
label define paidhour
	0	"NIU"
	1	"Yes"
	2	"No"
;

label values ahrswok ahrswok;
label define ahrswok
	0	"Not allocated"
	1	"Allocated"
;


label values umember umember;
label define umember
	0	"Not coded"
	1	"Yes"
	2	"No"
;

label values earnhrtc earnhrtc;
label define earnhrtc
	0	"NIU"
	1	"Top coded"
;

label values intckag intckag;
label define intckag
	0	"NIU"
	1	"16-24 years of age"
	2	"All others"
;

label values attend attend;
label define attend
	0	"NIU"
	1	"Yes"
	2	"No"
;

label values hscolge hscolge;
label define hscolge
	0	"NIU"
	1	"High School"
	2	"College or University"
;	

label values shlftpt shlftpt;
label define shlftpt
	0	"NIU"
	1	"Full-time"
	2	"Part-time"
;		

label values I35 I35;
label define I35
	0	"NIU"
	1	"Yes"
	2	"No"
;

label values I37 I37;
label define I37
	0	"NIU"
	1	"Ill or disabled"
	2	"Taking care of home/family"
	3	"Going to school"
	4	"Could not find work"
	5	"(Code not used beginning 1984)"
	6	"Retired"
	7	"Other"
;

label values I45 I45;
label define I45
	0	"NIU"
	1	"Ill or disabled"
	2	"Taking care of home/family"
	3	"Going to school"
	5	"Retired"
	6	"No work available"
	7	"Other"
;

label values I49 I49;
label define I49
	0	"NIU"
	1	"Could only find part time"
	2	"Wanted or could only work part time"
	3	"Slack work or material shortage"
	4	"Other"
;

label values a_clswkr a_clswkr;
label define a_clswkr
	0	"NIU"
	1	"Private"
	2	"Federal Gov't"
	3	"State Gov't"
	4	"Local Gov't"
	5	"SE - Incorportated"
	6	"Self-employed or farm"
	7	"Without pay"
;
	
#delimit cr
compress
save `prepdata'/`dofile'.dta, replace
! gzip -f `prepdata'/`dofile'.dta
! rm ${nberdata}/`dofile'.dat

if `doasproject'==1 {
project, creates(`prepdata'/`dofile'.dta.gz)
}
