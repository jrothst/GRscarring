***************************************************************************************************************
* recessionlist.do
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
	local dofile "recessionlist"
	local doasproject=0
}

set more off
local rootdir "`pdir'"
local thisdir "`pdir'"

local scratch "`pdir'/scratch"

  // Make a monthly data set with recessions
  drop _all
  local fmonth=ym(1945,1)
  local lmonth=ym(2017,12)
  local nobs=(`lmonth'-`fmonth')+1
  set obs `nobs'
  gen month=`fmonth'-1+_n
  gen recession=0
  replace recession=1 if month>=ym(2007,12) & month<=ym(2009, 6)
  replace recession=1 if month>=ym(2001, 3) & month<=ym(2001,11)
  replace recession=1 if month>=ym(1990, 7) & month<=ym(1991, 3)
  replace recession=1 if month>=ym(1981, 7) & month<=ym(1982,11)
  replace recession=1 if month>=ym(1980, 1) & month<=ym(1980, 7)
  replace recession=1 if month>=ym(1973,11) & month<=ym(1975, 3)
  replace recession=1 if month>=ym(1969,12) & month<=ym(1970,11)
  replace recession=1 if month>=ym(1960, 4) & month<=ym(1961, 2)
  replace recession=1 if month>=ym(1957, 8) & month<=ym(1958, 4)
  replace recession=1 if month>=ym(1953, 7) & month<=ym(1954, 5)
  replace recession=1 if month>=ym(1948,11) & month<=ym(1949,10)
  replace recession=1 if month>=ym(1945, 2) & month<=ym(1945,10)
  save `scratch'/recessionlist.dta, replace
  
if `doasproject'==1 {
	project, creates(`scratch'/recessionlist.dta)
}
  
