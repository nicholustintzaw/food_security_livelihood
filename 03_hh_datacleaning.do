/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

PROJECT:		Tat Lan Plus Baseline: Food Security & Livelihood Report

PURPOSE: 		Food Security & Livelihood Dataset Data Cleaning

AUTHOR:  		Nicholus

CREATED: 		15 Apr 2020

MODIFIED:
   

THINGS TO DO:

//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
// ***SET ROOT DIRECTORY HERE AND ONLY HERE***

// create a local to identify current user
local user = c(username)
di "`user'"

// Set root directory depending on current user
if "`user'" == "nicholustintzaw" {
	global		dir			/Users/nicholustintzaw/Documents/PERSONAL/Projects/_SCI_TatLan/01_workflow

}


// please add your PC user name and your directory for this workflow folder in global dir setting

else if "`user'" == "x" {
	global		dir			/Users/nicholustintzaw/Dropbox/SCI_FFP_Baseline/01_workflow

}


global		do			$dir/00_do
global		raw			$dir/01_raw
global		dta			$dir/02_dta
global		out			$dir/03_out

//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

// Settings for stata
pause on
clear all
clear mata
set more off
set scrollbufsize 100000

//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
*------------------------------------------------------------------------------*
***  DATA IMPORTING  ***
*------------------------------------------------------------------------------*


import excel 	using "$raw/FSL Tat-Lan Plus Baseline survey ( For Non selected Beneficiaries ) - all versions - English - 2020-03-30-03-54-31.xlsx", ///
				firstrow allstring clear

drop C R U BN CO CU CZ GC GU HN HX KO KZ LC OM QS RH SM TD TW US

gen source = 1 

tempfile non_ben
save `non_ben', replace
clear


import excel 	using "$raw/FSL Tat-Lan Plus Baseline survey ( For selected  Beneficiaries ) - all versions - English - 2020-03-30-03-54-12.xlsx", ///
				firstrow allstring clear

drop C R U BN CO CU CZ GC GU HN HX KO KZ LC OM QS RH SM TD TW US
gen source = 0
tab source, m

append using `non_ben'
lab def source 1"Non selected Beneficiaries" 0"Selected  Beneficiaries"
lab val source source
tab source, m
sort source

do "$do/_hh_var_labeling.do"

** translation field update **
readreplace using "$raw/replacement.xlsx", id(key) variable(variable) value(value) excel import(firstrow)


save "$dta/tatlan_plus_fsl_raw.dta", replace

clear

*------------------------------------------------------------------------------*
***  DATA CLEANING  ***
*------------------------------------------------------------------------------*

use "$dta/tatlan_plus_fsl_raw.dta", clear

** BASIC INFROMATION - IDENTIFICATION **
** Date & Time ** 
split starttime, p("T")

gen start_date = date(starttime1, "YMD")
format start_date %td
lab var start_date "Survey Date - System Record Date"
order start_date, after(starttime)
drop starttime1 starttime2

gen svy_date1 = date(svy_date, "YMD")
format svy_date1 %td
order svy_date1, after(svy_date)

drop svy_date 
rename svy_date1 svy_date
lab var svy_date "Survey Date - Enumerator"

count if start_date != svy_date // 21 obs did not matched the system date and enumerator fill-in date

** Geographical information **

do "$do/_hh_geo_correction.do"

// org_name 
tab org_name, m

// org_name_oth 

// state 
replace state = "Rakhine"
tab state, m

// town 
tab town, m

// vt_name 
tab vt_name, m

// vill_name
tab vill_name, m 

// geo_type
tab geo_type, m
replace geo_type = "1" if geo_type == "Host Village"
replace geo_type = "2" if geo_type == "IDP camp"
replace geo_type = "3" if geo_type == "Village"
destring geo_type, replace
lab def geo_type 1"Host Village" 2"IDP camp" 3"Village"
lab val geo_type geo_type
tab geo_type, m

forvalue x = 1/3 {
	gen geo_type_`x' = (geo_type == `x')
	replace geo_type_`x' = .m if mi(geo_type)
	tab geo_type_`x', m
	order geo_type_`x', before(enu_name)
}

lab var geo_type_1 "Host Village"
lab var geo_type_2 "IDP camp"
lab var geo_type_3 "Village"

rename geo_type_1 geo_type_host
rename geo_type_2 geo_type_camp
rename geo_type_3 geo_type_vill
 
** export to check with village name **
preserve

keep if vill_name == "Aye Chan Thar" | vill_name == "PS" | vill_name == "Sin Tet Maw" | ///
		vill_name == "Sittwe" | vill_name == "T" | vill_name == "TC" | ///
		vill_name == "Village" | vill_name == "ရြာ" | town == "Pyauk Pyin" | ///
		town == "T" | town == "ရခုိင္" | vt_name == "KDK" | vt_name == "KDk" | ///
		vt_name == "Kdk" | vt_name == "M" | vt_name == "MK" | vt_name == "NGM" | ///
        vt_name == "Pauktaw" | vt_name == "S" | vt_name == "T" | vt_name == "Sittwe" | ///
		vt_name == "Pa Nyein Chaung"
							
export excel 	start_date svy_date state town vt_name vill_name geo_type enu_name using ///
				"$out/fls_village_name.xlsx", firstrow(varlabels) replace

restore


********************************************************************************
********************************************************************************
*------------------------------------------------------------------------------*
***  HOUSEHOLD INFORMATION  ***
*------------------------------------------------------------------------------*

// resp_sex 
replace resp_sex = "1" if resp_sex == "Male" 
replace resp_sex = "0" if resp_sex == "Female"
destring resp_sex, replace
lab var resp_sex "Respondent Gender"
lab def gender 1"Male" 0"Female"
lab val resp_sex gender
tab resp_sex, m


// hhhead_relation
replace hhhead_relation = "1" if hhhead_relation == "Child"
replace hhhead_relation = "2" if hhhead_relation == "Grand-child"
replace hhhead_relation = "3" if hhhead_relation == "Head"
replace hhhead_relation = "4" if hhhead_relation == "No relation"
replace hhhead_relation = "5" if hhhead_relation == "Other relative"
replace hhhead_relation = "6" if hhhead_relation == "Parent"
replace hhhead_relation = "7" if hhhead_relation == "Sibling"
replace hhhead_relation = "8" if hhhead_relation == "Spouse"

destring hhhead_relation, replace
lab def hhhead_relation 1"Child" 2"Grand-child" 3"Head" ///
						4"No relation" 5"Other relative" 6"Parent" ///
						7"Sibling" 8"Spouse"
lab val hhhead_relation hhhead_relation
tab hhhead_relation, m


// hhmem_num_male hhmem_num_male hhmem_num_female child_school_num
local num hhmem_num_male hhmem_num_female child_school_num

foreach var in `num' {
	destring `var', replace
	replace `var' = .m if mi(`var')
	tab `var', m
}

lab def agegrp	1"0-6months" 2">6 –23mths" 3"2 - <5yrs" 4"5 - <11yrs" ///
				5"11 - <18yrs" 6"18 - <60yrs" 7"60yrs & above"

local hhage hhmem_male_age hhmem_female_age
foreach var in `hhage' {
	forvalue x = 1/7 {
		replace `var'_`x' = "1" if `var'_`x' == "0-6months"
		replace `var'_`x' = "2" if `var'_`x' == ">6 –23mths"
		replace `var'_`x' = "3" if `var'_`x' == "2 - <5yrs"
		replace `var'_`x' = "4" if `var'_`x' == "5 - <11yrs"
		replace `var'_`x' = "5" if `var'_`x' == "11 - <18yrs"
		replace `var'_`x' = "6" if `var'_`x' == "18 - <60yrs"
		replace `var'_`x' = "7" if `var'_`x' == "60yrs & above"
		
		destring `var'_`x', replace	
		lab val `var'_`x' agegrp
	}
}

lab def hhrelat	1"Head" 2"Spouse" 3"Child" 4"Parent" 5"Sibling" ///
				6"Grand-child" 7"Grandparent" 8"Other relative" 9"No relation"

local hhrelat	hhmem_male_relation hhmem_female_relation
foreach var in `hhrelat' {
	forvalue x = 1/7 {
		replace `var'_`x' = "1" if `var'_`x' == "Head"
		replace `var'_`x' = "2" if `var'_`x' == "Spouse"
		replace `var'_`x' = "3" if `var'_`x' == "Child"
		replace `var'_`x' = "4" if `var'_`x' == "Parent"
		replace `var'_`x' = "5" if `var'_`x' == "Sibling"
		replace `var'_`x' = "6" if `var'_`x' == "Grand-child"
		replace `var'_`x' = "7" if `var'_`x' == "Grandparent"
		replace `var'_`x' = "8" if `var'_`x' == "Other relative"
		replace `var'_`x' = "9" if `var'_`x' == "No relation"	
		
		destring `var'_`x', replace	
		lab val `var'_`x' hhrelat
	}
}

lab def status 1"Single" 2"Married/Living as partner" 3"Separated/ Divorced" 4"Widow or widower" 5"Not applicable"

local status hhmem_male_marital hhmem_female_marital
foreach var in `status' {
	forvalue x = 1/7 {
		replace `var'_`x' = "1" if `var'_`x' == "Single"
		replace `var'_`x' = "2" if `var'_`x' == "Married/Living as partner"
		replace `var'_`x' = "3" if `var'_`x' == "Separated/ Divorced"
		replace `var'_`x' = "4" if `var'_`x' == "Widow or widower"
		replace `var'_`x' = "5" if `var'_`x' == "Not applicable"
		
		destring `var'_`x', replace	
		lab val `var'_`x' status
	}
}


// hhmem_male
forvalue x =  1/7 {
	replace hhmem_male_age_`x' = .m if mi(hhmem_num_male) | hhmem_num_male < `x'
	replace hhmem_male_relation_`x' = .m if mi(hhmem_num_male) | hhmem_num_male < `x'
	replace hhmem_male_marital_`x' = .m if mi(hhmem_num_male) | hhmem_num_male < `x'
	 
	replace hhmem_female_age_`x' = .m if mi(hhmem_num_female) | hhmem_num_female < `x'
	replace hhmem_female_relation_`x' = .m if mi(hhmem_num_female) | hhmem_num_female < `x'
	replace hhmem_female_marital_`x' = .m if mi(hhmem_num_female) | hhmem_num_female < `x'
}


// hh_head_gender
// with assumption: all observation which HH head gender were not identified by the relationship with respondent 
// child, grand-child, no relation, other relative, parent and sibling
// assume their HH head as MALE as it is more common in Myanmar typical family

tab hhhead_relation resp_sex, m

gen hh_head_gender = (hhhead_relation != 3 | hhhead_relation != 8)
replace hh_head_gender = 0 if hhhead_relation == 8 &  resp_sex == 1
replace hh_head_gender = 1 if hhhead_relation == 8 &  resp_sex == 0
replace hh_head_gender = 0 if hhhead_relation == 3 &  resp_sex == 0
replace hh_head_gender = 1 if hhhead_relation == 3 &  resp_sex == 1
lab val hh_head_gender gender
lab var hh_head_gender "HH head gender"
order hh_head_gender, after(hhhead_relation)

forvalue x = 1/7 {
	replace hh_head_gender = 1 if hhmem_male_relation_`x' == 1
	replace hh_head_gender = 0 if hhmem_female_relation_`x' == 1
}
tab hh_head_gender, m



lab def yesno 1"yes" 0"no"

forvalue x = 0/1 {
	gen hh_head_gender_`x' = (hh_head_gender == `x')
	replace hh_head_gender_`x' = .m if mi(hh_head_gender)
	order hh_head_gender_`x', after(hh_head_gender)
	lab var hh_head_gender_`x' yesno
	tab hh_head_gender_`x', m
}
lab var hh_head_gender_1 "Men lead HH"
lab var hh_head_gender_0 "Women lead HH"
rename hh_head_gender_1 hh_head_gender_male
rename hh_head_gender_0 hh_head_gender_female



// child_school_num
// child_school_age_1 child_school_sex_1 child_school_enroll_2 child_school_grade_1 child_school_attend_2

lab def grade	1"Grade 1" 2"Grade 2" 3"Grade 3" 4"Grade 4" 5"Grade 5" ///
				6"Grade 6" 7"Grade 7" 8"Grade 8" 9"Grade 9" 10"Grade 10" 11"Grade 11"
				
local grade child_school_grade
foreach var in `grade' {
	forvalue x = 1/5 {
		replace `var'_`x' = "1" if `var'_`x' == "Grade 1"
		replace `var'_`x' = "2" if `var'_`x' == "Grade 2"
		replace `var'_`x' = "3" if `var'_`x' == "Grade 3"
		replace `var'_`x' = "4" if `var'_`x' == "Grade 4"
		replace `var'_`x' = "5" if `var'_`x' == "Grade 5"
		replace `var'_`x' = "6" if `var'_`x' == "Grade 6"
		replace `var'_`x' = "7" if `var'_`x' == "Grade 7"
		replace `var'_`x' = "8" if `var'_`x' == "Grade 8"
		replace `var'_`x' = "9" if `var'_`x' == "Grade 9"
		replace `var'_`x' = "10" if `var'_`x' == "Grade 10"
		replace `var'_`x' = "11" if `var'_`x' == "Grade 11"
		
		destring `var'_`x', replace	
		lab val `var'_`x' grade
		
		replace `var'_`x' = .m if mi(child_school_num) | child_school_num < `x'

	}
}

local childvar child_school_age child_school_sex child_school_enroll child_school_attend

foreach var in `childvar' {
	forvalue x = 1/5 {
		replace `var'_`x' = "1" if `var'_`x' == "Yes"
		replace `var'_`x' = "0" if `var'_`x' == "No"
		replace `var'_`x' = "1" if `var'_`x' == "Male"
		replace `var'_`x' = "0" if `var'_`x' == "Female"
		
		destring `var'_`x', replace	
		
		replace `var'_`x' = .m if mi(child_school_num) | child_school_num < `x'
	}
}

egen child_school_attend_num = rowtotal(child_school_attend_*)
lab var child_school_attend_num "number of schooling children"
replace child_school_attend_num = .m if hhhead_relation != 3
order child_school_attend_num, after(child_school_attend_5)
tab child_school_attend_num, m

egen hh_size 	= rowtotal(hhmem_num_male hhmem_num_female)
replace hh_size = .m if mi(hhmem_num_male) & mi(hhmem_num_female)
order hh_size, before(hh_type)
lab var hh_size "Number of HH members"
tab hh_size, m

lab var hhmem_num_male		"Number of Male HH members"
lab var hhmem_num_female 	"Number of Female HH members"


**-----------------------------------------------------**
** Affected population/location type **
**-----------------------------------------------------**
// hh_type 
replace hh_type = "1" if hh_type == "Displaced (IDPs)"
replace hh_type = "0" if hh_type == "Non Displaced"
destring hh_type, replace
lab def hh_type 1"Displaced (IDPs)" 0"Non Displaced"
lab val hh_type hh_type
tab hh_type, m

forvalue x = 0/1{
	gen hh_type_`x' = (hh_type == `x')
	replace hh_type_`x' = .m if mi(hh_type)
	order hh_type_`x', after(hh_type)
	tab hh_type_`x', m
}
lab var hh_type_1 "Displaced (IDPs) HH"
lab var hh_type_0 "Not Displaced HH"

rename hh_type_1 hh_type_nodisplace
rename hh_type_0 hh_type_idp

// hh_displace
replace hh_displace = "1" if hh_displace == "Camp"
replace hh_displace = "2" if hh_displace == "Host family"
replace hh_displace = "3" if hh_displace == "Other"
destring hh_displace, replace
lab def hh_displace 1"Camp" 2"Host family" 3"Other"
lab val hh_displace hh_displace
replace hh_displace = .m if hh_type == 0
tab hh_displace, m

forvalue x = 1/3 {
	gen hh_displace_`x' = (hh_displace == `x')
	replace hh_displace_`x' = .m if mi(hh_displace)
	order hh_displace_`x', before(hh_restriction)
	tab hh_displace_`x', m
}

lab var hh_displace_1 "Displaced to Camp"
lab var hh_displace_2 "Displaced to Host family"
lab var hh_displace_3 "Other"

rename hh_displace_1 hh_displace_camp
rename hh_displace_2 hh_displace_host
rename hh_displace_3 hh_displace_other


// hh_displace_oth 
tab hh_displace_oth, m

// hh_restriction 
replace hh_restriction = "1" if hh_restriction == "Yes"
replace hh_restriction = "0" if hh_restriction == "No"
destring hh_restriction, replace
lab val hh_restriction yesno
tab hh_restriction, m


// hh_restriction_detail 
tab hh_restriction_detail, m

replace hh_restriction_detail = "5" if hh_restriction_detail == "Caregiver not avialable (not specify detail)"
replace hh_restriction_detail = "5" if hh_restriction_detail == "Difficulties in accessing health care facilities"
replace hh_restriction_detail = "6" if hh_restriction_detail == "education (but not specify the reason)"
replace hh_restriction_detail = "6" if hh_restriction_detail == "education and health (but not specify the reason)"
replace hh_restriction_detail = "7" if hh_restriction_detail == "financial constraint"
replace hh_restriction_detail = "7" if hh_restriction_detail == "financial constraint (Education)"
replace hh_restriction_detail = "7" if hh_restriction_detail == "financial constraint (Health)"
replace hh_restriction_detail = "7" if hh_restriction_detail == "financial constraint and transportation"
replace hh_restriction_detail = "0" if hh_restriction_detail == "Flooding in raining season"
replace hh_restriction_detail = "5" if hh_restriction_detail == "Health (but not specify the reason)"
replace hh_restriction_detail = "6" if hh_restriction_detail == "Health and Education"
replace hh_restriction_detail = "5" if hh_restriction_detail == "Health Care Staff (bad interpersonal skills)"
replace hh_restriction_detail = "6" if hh_restriction_detail == "Limited School Infrastructure"
replace hh_restriction_detail = "1" if hh_restriction_detail == "Living in IDP camp"
replace hh_restriction_detail = "2" if hh_restriction_detail == "Market"
replace hh_restriction_detail = "2" if hh_restriction_detail == "Market (No Markt in village)"
replace hh_restriction_detail = "5" if hh_restriction_detail == "No (but not specify any detail information)"
replace hh_restriction_detail = "5" if hh_restriction_detail == "No Clinic"
replace hh_restriction_detail = "5" if hh_restriction_detail == "No Clinic, No Hospital"
replace hh_restriction_detail = "5" if hh_restriction_detail == "No Clinic, No School"
replace hh_restriction_detail = "6" if hh_restriction_detail == "No School in Village"
replace hh_restriction_detail = "1" if hh_restriction_detail == "not able to travel other places"
replace hh_restriction_detail = "3" if hh_restriction_detail == "Not enough rations for family"
replace hh_restriction_detail = "5" if hh_restriction_detail == "Too far from Hospital"
replace hh_restriction_detail = "0" if hh_restriction_detail == "transportation" | hh_restriction_detail == "Transportation"
replace hh_restriction_detail = "4" if hh_restriction_detail == "Yes, but not specify the detail of restriction"
destring hh_restriction_detail, replace

lab def hh_restriction_detail 	1"Travel Restriction" 2"Market" 3"Not enough rations for HH members" ///
								4"Other type of restriction (but not specify)" 5"Health Care (Health facilities)" ///
								6"Educations (Schools)" 7"Financial Constraint"
lab val hh_restriction_detail hh_restriction_detail

replace hh_restriction =  0 if hh_restriction_detail == 0
replace hh_restriction_detail = .m if hh_restriction_detail == 0

tab hh_restriction_detail, m


forvalue x = 1/7 {
	gen hh_restriction_`x' = (hh_restriction_detail == `x')
	replace hh_restriction_`x' = .m if mi(hh_restriction_detail)
	order hh_restriction_`x', before(food_freq_adult_male)
	tab hh_restriction_`x', m
}

lab var hh_restriction_1 "Travel Restriction"
lab var hh_restriction_2 "Market"
lab var hh_restriction_3 "Not enough rations for HH members"
lab var hh_restriction_4 "Other type of restriction (but not specify)"
lab var hh_restriction_5 "Health Care (Health facilities)"
lab var hh_restriction_6 "Educations (Schools)"
lab var hh_restriction_7 "Financial Constraint"


/*
preserve 
keep if !mi(hh_restriction_detail)
keep hh_restriction_detail key
export excel hh_restriction_detail key using "$out/hh_restriction_detail.xlsx", firstrow(variables) replace
restore
*/
// food_freq_adult_male food_freq_adult_female food_freq_boy food_freq_girl 
local freq food_freq_adult_male food_freq_adult_female food_freq_boy food_freq_girl 

foreach var in `freq' {
	replace `var' = "0" if `var' == "No time eat"
	replace `var' = "1" if `var' == "1 time"
	replace `var' = "2" if `var' == "2 times"
	replace `var' = "3" if `var' == "3 times"
	replace `var' = "4" if `var' == "4 times"
	replace `var' = "5" if `var' == "5 times"
	replace `var' = "6" if `var' == "over 5 times"
	replace `var' = "9999" if `var' == "99= No adult Male in the household"
	replace `var' = "9999" if `var' == "99= No adult Female in the household"
	replace `var' = "9999" if `var' == "99= No male children in the household"
	replace `var' = "9999" if `var' == "99= No female children in the household"	
	
	destring `var', replace
	replace `var' = .m if mi(`var') | `var' == 9999
	tab `var', m
}

global hhinfo	hh_size hhmem_num_male hhmem_num_female ///
				resp_sex hh_head_gender_male hh_head_gender_female ///
				hh_type_nodisplace hh_type_idp hh_displace_camp hh_displace_host hh_displace_other ///
				hh_restriction ///
				hh_restriction_1 hh_restriction_2 hh_restriction_3 hh_restriction_4 hh_restriction_5 hh_restriction_6 hh_restriction_7

**-----------------------------------------------------**
** Food Consumption Score
**-----------------------------------------------------**
// hhrice hhpotatoes hhbeans hhveg hhpumpkin hhleafyveg hhfruit hhmango hhmeat hhorgan hhbeef hhfish hheggs hhyogurt hhfat hhsweets hhcondiment
lab def foodsource	1"Own production (crops, animal)" 2"Fishing / Hunting" 3"Gathering" ///
					4"Loan" 5"Market (purchase with cash)" 6"Market (purchase on credit)" ///
					7"Beg for food" 8"Exchange labor or items for food" 9"Gift (food) from family relatives or friends" ///
					10"Food aid from civil society, NGOs, government, WFP etc." 11"Other(specify)"

					
local foods hhstaples hhrice hhpotatoes hhbeans hhveg hhpumpkin hhveg_all hhleafyveg hhfruit_all hhfruit hhmango hhmeat_all hhorgan hhbeef hhfish hheggs hhyogurt hhfat hhsweets hhcondiment

foreach var in `foods' {

	replace `var'_yn = "1" if `var'_yn == "Yes"
	replace `var'_yn = "0" if `var'_yn == "No" | `var'_yn == "NO"

	replace `var'_freq = "1" if `var'_freq == "one day"
	replace `var'_freq = "2" if `var'_freq == "two days"
	replace `var'_freq = "3" if `var'_freq == "three days"
	replace `var'_freq = "4" if `var'_freq == "four days"
	replace `var'_freq = "5" if `var'_freq == "five days"
	replace `var'_freq = "6" if `var'_freq == "six days"
	replace `var'_freq = "7" if `var'_freq == "seven days"

	replace `var'_source = "1" if `var'_source == "Own production (crops, animal)"
	replace `var'_source = "2" if `var'_source == "Fishing / Hunting"
	replace `var'_source = "3" if `var'_source == "Gathering"
	replace `var'_source = "4" if `var'_source == "Loan"
	replace `var'_source = "5" if `var'_source == "Market (purchase with cash)"
	replace `var'_source = "6" if `var'_source == "Market (purchase on credit)"
	replace `var'_source = "7" if `var'_source == "Beg for food"
	replace `var'_source = "8" if `var'_source == "Exchange labor or items for food"
	replace `var'_source = "9" if `var'_source == "Gift (food) from family relatives or friends"
	replace `var'_source = "10" if `var'_source == "Food aid from civil society, NGOs, government, WFP etc."
	replace `var'_source = "11" if `var'_source == "Other(specify)"

	destring `var'_yn `var'_freq `var'_source, replace
	
	lab val `var'_source  foodsource
	lab val `var'_yn yesno
	
	replace `var'_yn = .m if mi(`var'_yn)
	replace `var'_freq = 0 if mi(`var'_freq)
	replace `var'_source = .m if mi(`var'_source)
	tab `var'_yn, m
}


egen fcs_g1		= rowtotal(hhrice_freq hhpotatoes_freq)
replace fcs_g1	= .m if mi(hhrice_freq) & mi(hhpotatoes_freq)
tab fcs_g1, m

egen fcs_g2		= rowtotal(hhbeans_freq)
replace fcs_g2	= .m if mi(hhbeans_freq)
tab fcs_g2, m

egen fcs_g3		= rowtotal(hhleafyveg_freq hhveg_freq hhpumpkin_freq)
replace fcs_g3	= .m if mi(hhleafyveg_freq) & mi(hhveg_freq) & mi(hhpumpkin_freq)
tab fcs_g3, m

egen fcs_g4		= rowtotal(hhmango_freq hhfruit_freq)
replace fcs_g4	= .m if mi(hhmango_freq) & mi(hhfruit_freq)
tab fcs_g4, m
  
egen fcs_g5		= rowtotal(hhorgan_freq hhbeef_freq hhfish_freq hheggs_freq)
replace fcs_g5	= .m if mi(hhorgan_freq) & mi(hhbeef_freq) & mi(hhfish_freq) & mi(hheggs_freq)
tab fcs_g5, m
 
egen fcs_g6		= rowtotal(hhyogurt_freq)
replace fcs_g6	= .m if mi(hhyogurt_freq)
tab fcs_g6, m

egen fcs_g7		= rowtotal(hhfat_freq)
replace fcs_g7	= .m if mi(hhfat_freq)
tab fcs_g7, m
  
egen fcs_g8		= rowtotal(hhsweets_freq)
replace fcs_g8	= .m if mi(hhsweets_freq)
tab fcs_g8, m


forvalue x = 1/8 {
	replace fcs_g`x' = 7 if fcs_g`x' > 7 & !mi(fcs_g`x')
	tab fcs_g`x', m
}

gen fcs_g1_score = (fcs_g1 * 2) 
gen fcs_g2_score = (fcs_g2 * 3) 
gen fcs_g3_score = (fcs_g3 * 1)
gen fcs_g4_score = (fcs_g4 * 1)
gen fcs_g5_score = (fcs_g5 * 4)
gen fcs_g6_score = (fcs_g6 * 4)
gen fcs_g7_score = (fcs_g7 * 0.5)
gen fcs_g8_score = (fcs_g8 * 0.5)

egen fcs_score 		= 	rowtotal(fcs_g1_score fcs_g2_score fcs_g3_score fcs_g4_score fcs_g5_score fcs_g6_score fcs_g7_score fcs_g8_score)
replace fcs_score 	= .m if mi(fcs_g1) | mi(fcs_g2) | mi(fcs_g3) | mi(fcs_g4) | mi(fcs_g5) | mi(fcs_g6) | mi(fcs_g7) | mi(fcs_g8)
tab fcs_score, m

gen fcs_poor		= (fcs_score <= 21)
replace fcs_poor 	= .m if mi(fcs_score)
tab fcs_poor, m

gen fcs_borderline		= (fcs_score > 21 & fcs_score <= 35)
replace fcs_borderline 	= .m if mi(fcs_score)
tab fcs_borderline, m

gen fcs_acceptable		= (fcs_score > 35)
replace fcs_acceptable 	= .m if mi(fcs_score)
tab fcs_acceptable, m

** reporting variable **
lab var fcs_score		"food consumption score"
lab var fcs_acceptable	"FCS - acceptable"
lab var fcs_borderline 	"FCS - borderline"
lab var fcs_poor 		"FCS - poor"

lab var fcs_g1 "Main staples"
lab var fcs_g2 "Pulses"
lab var fcs_g3 "Vegetables"
lab var fcs_g4 "Fruit"
lab var fcs_g5 "Meat and fish"
lab var fcs_g6 "Milk"
lab var fcs_g7 "Sugar"
lab var fcs_g8 "Oil"

order	fcs_g1 fcs_g2 fcs_g3 fcs_g4 fcs_g5 fcs_g6 fcs_g7 fcs_g8 ///
		fcs_g1_score fcs_g2_score fcs_g3_score fcs_g4_score fcs_g5_score fcs_g6_score fcs_g7_score fcs_g8_score ///
		fcs_score fcs_acceptable fcs_borderline fcs_poor, before(staple_stock)


global fcs 	fcs_g1 fcs_g2 fcs_g3 fcs_g4 fcs_g5 fcs_g6 fcs_g7 fcs_g8 ///
			fcs_score fcs_acceptable fcs_borderline fcs_poor

*------------------------------------------------------------------------------*
***  HH Dietary Diversity Score ***
*------------------------------------------------------------------------------*

local foods hhstaples hhrice hhpotatoes hhbeans hhveg hhpumpkin hhveg_all hhleafyveg hhfruit_all hhfruit hhmango hhmeat_all hhorgan hhbeef hhfish hheggs hhyogurt hhfat hhsweets hhcondiment

gen hhds_g1		= (hhrice_yn == 1)
replace hhds_g1	= .m if mi(hhstaples_yn)
tab hhds_g1, m

gen hhds_g2		= (hhpotatoes_yn == 1)
replace hhds_g2	= .m if mi(hhstaples_yn)
tab hhds_g2, m

gen hhds_g3		= (hhleafyveg_yn == 1| hhveg_yn ==  1 | hhpumpkin_yn == 1)
replace hhds_g3	= .m if mi(hhveg_all_yn)
tab hhds_g3, m

gen hhds_g4		= (hhmango_yn == 1| hhfruit_yn == 1)
replace hhds_g4	= .m if mi(hhfruit_all_yn)
tab hhds_g4, m
  
gen hhds_g5		= (hhorgan_yn == 1 | hhbeef_yn == 1)
replace hhds_g5	= .m if mi(hhmeat_all_yn)
tab hhds_g5, m

gen hhds_g6		= (hheggs_yn == 1)
replace hhds_g6	= .m if mi(hhmeat_all_yn)
tab hhds_g6, m

gen hhds_g7		= (hhfish_yn == 1)
replace hhds_g7	= .m if mi(hhmeat_all_yn)
tab hhds_g7, m

gen hhds_g8		= (hhbeans_yn == 1)
replace hhds_g8	= .m if mi(hhbeans_yn)
tab hhds_g8, m

gen hhds_g9		= (hhyogurt_yn == 1)
replace hhds_g9	= .m if mi(hhyogurt_yn)
tab hhds_g9, m

gen hhds_g10		= (hhfat_yn == 1)
replace hhds_g10	= .m if mi(hhfat_yn)
tab hhds_g10, m
  
gen hhds_g11		= (hhsweets_yn == 1)
replace hhds_g11	= .m if mi(hhsweets_yn)
tab hhds_g11, m

gen hhds_g12		= (hhcondiment_yn == 1)
replace hhds_g12	= .m if mi(hhcondiment_yn)
tab hhds_g12, m

egen hhds_score 	= rowtotal(hhds_g1 hhds_g2 hhds_g3 hhds_g4 hhds_g5 hhds_g6 hhds_g7 hhds_g8 hhds_g9 hhds_g10 hhds_g11 hhds_g12)
replace hhds_score	= 	.m if 	mi(hhds_g1) | mi(hhds_g2) & mi(hhds_g3) | mi(hhds_g4) | mi(hhds_g5) | mi(hhds_g6) & ///
								mi(hhds_g7) | mi(hhds_g8) & mi(hhds_g9) | mi(hhds_g10) | mi(hhds_g11) | mi(hhds_g12)
tab hhds_score, m

sum hhds_score, d

lab var hhds_score "Averge HH Dietary Diversity Score"
lab var hhds_g1 "Grains"
lab var hhds_g2"Roots or tubers"
lab var hhds_g3"Vegetables"
lab var hhds_g4"Fruits"
lab var hhds_g5"Meat"
lab var hhds_g6"Eggs"
lab var hhds_g7"Fish"
lab var hhds_g8"Pulses and nuts"
lab var hhds_g9"Milk and Milk Products"
lab var hhds_g10"Oil and Fat"
lab var hhds_g11"Sugar and Sweets"
lab var hhds_g12"Condiments"

order hhds_g1 hhds_g2 hhds_g3 hhds_g4 hhds_g5 hhds_g6 hhds_g7 hhds_g8 hhds_g9 hhds_g10 hhds_g11 hhds_g12 hhds_score, before(staple_stock)

global hhds	hhds_g1 hhds_g2 hhds_g3 hhds_g4 hhds_g5 hhds_g6 hhds_g7 hhds_g8 hhds_g9 hhds_g10 hhds_g11 hhds_g12 hhds_score

*------------------------------------------------------------------------------*
** 4. Food Stock and Access to Markets ***
*------------------------------------------------------------------------------*

// staple_stock 
destring staple_stock, replace
lab var staple_stock "Average number of day for staple food in stock"
tab staple_stock, m

* Winsorized
winsor2 staple_stock, replace cuts(1 99)

// market_type 
tab market_type, m
replace market_type = "0"  if market_type == "No Market access"
replace market_type = "1"  if market_type == "Daily"
replace market_type = "2"  if market_type == "Periodic"
lab def market_type 0"No Market access" 1"Daily" 2"Periodic"
destring market_type, replace
lab val market_type market_type
tab market_type, m

forvalue x = 0/2 {
	gen market_type_`x' = (market_type == `x')
	replace market_type_`x' = .m if mi(market_type)
	order market_type_`x', before(market_dist)
	tab market_type_`x', m
}

lab var market_type_0 "No Market access"
lab var market_type_1 "Market access - Daily"
lab var market_type_2 "Market access - Periodic"


// market_dist  
replace market_dist = "1" if market_dist == "under 5 mimute"
replace market_dist = "2" if market_dist == "under 10 mimute"
replace market_dist = "3" if market_dist == "under 20 mimute"
replace market_dist = "4" if market_dist == "under 30 mimute"
replace market_dist = "5" if market_dist == "under 45 mimute"
replace market_dist = "6" if market_dist == "under one hour"
replace market_dist = "7" if market_dist == "under 2 hours"
destring market_dist, replace

lab def market_dist 1"under 5 mimute" 2"under 10 mimute" 3"under 20 mimute" ///
					4"under 30 mimute" 5"under 45 mimute" 6"under one hour" ///
					7"under 2 hours"
lab val market_dist market_dist
replace market_dist = .m if market_type == 0
tab market_dist, m

forvalue x = 1/7 {
	gen market_dist_`x' = (market_dist == `x')
	replace market_dist_`x' = .m if mi(`var')
	order market_dist_`x', before(market_access)
	tab market_dist_`x', m
}

lab var market_dist_1 "under 5 mimute"
lab var market_dist_2 "under 10 mimute"
lab var market_dist_3 "under 20 mimute"
lab var market_dist_4 "under 30 mimute"
lab var market_dist_5 "under 45 mimute"
lab var market_dist_6 "under one hour"
lab var market_dist_7 "under 2 hours"

// market_access 
tab market_access, m

// market_access_1 market_access_2 market_access_3 market_access_4 market_access_5 market_access_6 market_access_7 market_access_8 market_access_9 market_access_10 market_access_11 market_access_12

// market_access_ by months
destring market_access_all, replace
replace market_access_all = .m if market_type == 0
tab market_access_all, m

forvalue x = 1/12 {
	destring market_access_`x', replace
	replace market_access_`x' = .m if market_type == 0
	tab market_access_`x', m
}

lab var market_access_all "Market Always assessible"
lab var market_access_1 "January"
lab var market_access_2 "February"
lab var market_access_3 "March"
lab var market_access_4 "April"
lab var market_access_5 "May"
lab var market_access_6 "June"
lab var market_access_7 "July"
lab var market_access_8 "August"
lab var market_access_9 "September"
lab var market_access_10 "October"
lab var market_access_11 "November"
lab var market_access_12 "December"


global market 	staple_stock market_type_0 market_type_1 market_type_2 ///
				market_dist_1 market_dist_2 market_dist_3 market_dist_4 market_dist_5 market_dist_6 market_dist_7 ///
				market_access_all ///
				market_access_1 market_access_2 market_access_3 market_access_4 market_access_5 market_access_6 ///
				market_access_7 market_access_8 market_access_9 market_access_10 market_access_11 market_access_12


*------------------------------------------------------------------------------*
** 5. Food Insecurity Access Scale ** 
*------------------------------------------------------------------------------*

// hfias_q1 hfias_q1_freq hfias_q2 hfias_q2_freq hfias_q3 hfias_q3_freq hfias_q4 hfias_q4_freq hfias_q5 hfias_q5_freq hfias_q6 hfias_q6_freq hfias_q7 hfias_q7_freq hfias_q8 hfias_q8_freq hfias_q9 hfias_q9_freq

lab def hfias 0"Never" 1"Rarely" 2"Sometimes" 3"Often"

forvalue x = 1/9 {
	replace hfias_q`x' = "1" if hfias_q`x' == "Yes"
	replace hfias_q`x' = "0" if hfias_q`x' == "No"
	
	replace hfias_q`x'_freq = "1" if hfias_q`x'_freq == "Rarely (1-2times in past 4 weeks)"
	replace hfias_q`x'_freq = "2" if hfias_q`x'_freq == "Sometimes (3-10times in past 4 weeks)"
	replace hfias_q`x'_freq = "3" if hfias_q`x'_freq == "Often (more than 10times in past 4 weeks)"
	
	destring hfias_q`x' hfias_q`x'_freq, replace
	replace hfias_q`x'_freq = 0 if hfias_q`x' == 0
	
	lab val hfias_q`x' yesno
	lab val hfias_q`x'_freq hfias
	
	tab hfias_q`x', m
	tab hfias_q`x'_freq, m
}

egen hfias_score = rowtotal(hfias_q*_freq)
lab var hfias_score "Household Food Insecurity Access Scale (HFIAS)"
order hfias_score, after(hfias_q9_freq)
tab hfias_score, m

// HFIA category = 1 if [(Q1a=0 or Q1a=1) and Q2=0 and Q3=0 and Q4=0 and Q5=0 and Q6=0 and Q7=0 and Q8=0 and Q9=0]
// HFIA category = 2 if [(Q1a=2 or Q1a=3 or Q2a=1 or Q2a=2 or Q2a=3 or Q3a=1 or Q4a=1) and Q5=0 and Q6=0 and Q7=0 and Q8=0 and Q9=0]
// HFIA category = 3 if [(Q3a=2 or Q3a=3 or Q4a=2 or Q4a=3 or Q5a=1 or Q5a=2 or Q6a=1 or Q6a=2) and Q7=0 and Q8=0 and Q9=0]
// HFIA category = 4 if [Q5a=3 or Q6a=3 or Q7a=1 or Q7a=2 or Q7a=3 or Q8a=1 or Q8a=2 or Q8a=3 or Q9a=1 or Q9a=2 or Q9a=3]


gen hfias_level 	= (	hfias_q1_freq < 2 & hfias_q2_freq == 0 &  hfias_q3_freq == 0 &  hfias_q4_freq == 0 & ///
						hfias_q5_freq == 0 &  hfias_q6_freq == 0 & hfias_q7_freq == 0 & hfias_q8_freq == 0 & ///
						hfias_q9_freq == 0)


replace hfias_level	= 2 if 	(hfias_q1_freq == 2 | hfias_q1_freq == 3 | (hfias_q2_freq > 0 & hfias_q2_freq <= 3) | ///
							hfias_q3_freq == 1 | hfias_q4_freq == 1) & ///
							hfias_q5_freq == 0 &  hfias_q6_freq == 0 & hfias_q7_freq == 0 & hfias_q8_freq == 0 & ///
							hfias_q9_freq == 0

							
replace hfias_level	= 3 if 	(hfias_q3_freq == 2 | hfias_q3_freq == 3 | hfias_q4_freq == 2 | hfias_q4_freq == 3 | ///
							hfias_q5_freq == 1 | hfias_q5_freq == 2 | hfias_q6_freq == 1 | hfias_q6_freq == 2) ///
							& hfias_q7_freq == 0 & hfias_q8_freq == 0 & hfias_q9_freq == 0
							
						

replace hfias_level	= 4 if 	hfias_q5_freq == 3 | hfias_q6_freq == 3 | (hfias_q7_freq > 0 & hfias_q7_freq <=3) | ///
							(hfias_q8_freq >0 & hfias_q8_freq <= 3) | (hfias_q9_freq > 0 &  hfias_q9_freq <= 3)

lab def hfias_level 1"Food Secure" 2"Mildly Food Insecure Access" 3"Moderately Food Insecure Access" 4"Severely Food Insecure Access"
lab val hfias_level hfias_level
lab var hfias_level "Household Food Insecurity Level by (HFIAS)"
order hfias_level, after(hfias_score)
tab hfias_level, m

forvalue x = 1/4 {
	gen hfias_level_`x' = (hfias_level == `x')
	replace hfias_level_`x' = .m if mi(hfias_level)
	order hfias_level_`x', before(income_num)
	tab hfias_level_`x', m
}

lab var hfias_level_1 "Food Secure"
lab var hfias_level_2 "Mildly Food Insecure Access"
lab var hfias_level_3 "Moderately Food Insecure Access"
lab var hfias_level_4 "Severely Food Insecure Access"

global hfias hfias_score hfias_level_1 hfias_level_2 hfias_level_3 hfias_level_4

*------------------------------------------------------------------------------*
** 6. Livelihoods/Income Sources **
*------------------------------------------------------------------------------*
drop income_num 

** INCOME EARNERS **
local incomenum income_men_1518 income_men_1924 income_men_over25 income_women_1518 income_women_1924 income_women_over25 income_girl income_boy

foreach var in `incomenum' {
	replace `var' = "0" if `var' == "No one"
	destring `var', replace
	replace `var' = .m if mi(`var')
	tab `var', m
}

egen income_earntot = rowtotal(	income_men_1518 income_men_1924 income_men_over25 ///
								income_women_1518 income_women_1924 income_women_over25 ///
								income_girl income_boy)
replace income_earntot = .m if	mi(income_men_1518) & mi(income_men_1924) & mi(income_men_over25) & ///
								mi(income_women_1518) & mi(income_women_1924) & mi(income_women_over25) & ///
								mi(income_girl) & mi(income_boy)
lab var income_earntot "Total income earners are they in the household"
order income_earntot, after(income_boy)
tab income_earntot, m


** % of adolescents/youth (m/f) engaged in a decent business or Income Generation Activity by the end of the Program **
** but can't calculate for all adolescents/youth as the dataset did not included all HH members info
** WHO defines 'Adolescents' as individuals in the 10-19 years age group and 'Youth' as the 15-24 year age group. 
** While 'Young People' covers the age range 10-24 years.


egen income_youth_tot 		= rowtotal(income_men_1518 income_men_1924 income_women_1518 income_women_1924 income_girl income_boy)
replace income_youth_tot	= .m if mi(income_men_1518) & mi(income_men_1924) & mi(income_women_1518) & mi(income_women_1924) & ///
									mi(income_girl) & mi(income_boy)
tab income_youth_tot, m

egen income_female_tot		= rowtotal(income_women_1518 income_women_1924 income_women_over25 income_girl)
replace income_female_tot	= .m if mi(income_women_1518) & mi(income_women_1924) & mi(income_women_over25) & mi(income_girl)
tab income_female_tot, m

foreach var of varlist income_youth_tot income_female_tot {
	gen `var'_hh = (`var' > 0 & !mi(`var'))
	replace `var'_hh = .m if mi(`var')
	order `var'_hh, after(`var')
	tab `var'_hh, m
}
rename income_youth_tot_hh	income_youth_hh
rename income_female_tot_hh	income_female_hh

order income_youth_tot income_female_tot income_youth_hh income_female_hh, before(job_num)

lab var income_youth_tot 	"number of youth/adolescents working in HH"
lab var income_female_tot 	"number of female HH members working in HH"
lab var income_youth_hh 	"HH with youth/adolescents are working"
lab var income_female_hh	"HH with female HH members are working"


global earner 	income_earntot income_men_1518 income_men_1924 income_men_over25 income_women_1518 ///
				income_women_1924 income_women_over25 income_girl income_boy ///
				income_youth_tot income_female_tot income_youth_hh income_female_hh


** JOB **				
// job_num 
destring job_num, replace
tab job_num, m

lab def jobtype	1"Casual Labour(agriculture)" 2"Casual Labour(non-agriculture)" 3"Salaried job" ///
				4"Farming/agriculture (sale of crops)" 5"Fishing (sale of raw fish)" ///
				6"Fishing – sale of processed fish products" 7"Wood/ Bamboo cutting" ///
				8"Trade /Business" 9"Small trade/petty trade" 10"Shop owner" ///
				11"Artisan & skilled work (carpenter, mason, mechanic, driver, tailoring….)" ///
				12"Service provider (milling, taxi/bus/trishaw driver….)" 13"Remittances" ///
				14"Sale of livestock" 15"Selling non-timber forest products (orchids, hunting & selling, wild vegetables....)" ///
				16"Pensions (including government programmes such as MCCT)" 17"Sale of assistance (food rations..)" ///
				18"Cash for Work programme" 19"Others, Specify" 20"No income activity"

forvalue x = 1/4 {
	replace job_main_`x' = "1" if job_main_`x' == "Casual Labour(agriculture)"
	replace job_main_`x' = "2" if job_main_`x' == "Casual Labour(non-agriculture)"
	replace job_main_`x' = "3" if job_main_`x' == "Salaried job"
	replace job_main_`x' = "4" if job_main_`x' == "Farming / agriculture (sale of crops)"
	replace job_main_`x' = "5" if job_main_`x' == "Fishing (sale of raw fish)"
	replace job_main_`x' = "6" if job_main_`x' == "Fishing – sale of processed fish products"
	replace job_main_`x' = "7" if job_main_`x' == "Wood/ Bamboo cutting"
	replace job_main_`x' = "8" if job_main_`x' == "Trade /Business"
	replace job_main_`x' = "9" if job_main_`x' == "Small trade/petty trade"
	replace job_main_`x' = "10" if job_main_`x' == "Shop owner"
	replace job_main_`x' = "11" if job_main_`x' == "Artisan & skilled work (carpenter, mason, mechanic, driver, tailoring….)"
	replace job_main_`x' = "12" if job_main_`x' == "Service provider (milling, taxi/bus/trishaw driver….)"
	replace job_main_`x' = "13" if job_main_`x' == "Remittances"
	replace job_main_`x' = "14" if job_main_`x' == "Sale of livestock"
	replace job_main_`x' = "15" if job_main_`x' == "Selling non-timber forest products (orchids, hunting & selling, wild vegetables....)"
	replace job_main_`x' = "16" if job_main_`x' == "Pensions (including government programmes such as MCCT)"
	replace job_main_`x' = "17" if job_main_`x' == "Sale of assistance (food rations..)"
	replace job_main_`x' = "18" if job_main_`x' == "Cash for Work programme"
	replace job_main_`x' = "19" if job_main_`x' == "Others, Specify"
	replace job_main_`x' = "20" if job_main_`x' == "No income activity"

	destring job_main_`x', replace
	lab val job_main_`x' jobtype
	tab job_main_`x', m
}


forvalue x = 1/20 {
	gen  job_main_type_`x'		= (job_main_1 == `x' | job_main_2 == `x' | job_main_3 == `x' | job_main_4 == `x')
	replace job_main_type_`x'	= .m if mi(job_main_1) & mi(job_main_2) & mi(job_main_3) & mi(job_main_4)
	order job_main_type_`x', before(work_1)
	tab job_main_type_`x', m
}

lab var job_main_type_1 "Casual Labour(agriculture)"
lab var job_main_type_2 "Casual Labour(non-agriculture)"
lab var job_main_type_3 "Salaried job"
lab var job_main_type_4 "Farming/agriculture (sale of crops)"
lab var job_main_type_5 "Fishing (sale of raw fish)"
lab var job_main_type_6 "Fishing (sale of processed fish products)"
lab var job_main_type_7 "Wood/Bamboo cutting"
lab var job_main_type_8 "Trade/Business"
lab var job_main_type_9 "Small trade/petty trade"
lab var job_main_type_10 "Shop owner"
lab var job_main_type_11 "Artisan & skilled work"
lab var job_main_type_12 "Service provider"
lab var job_main_type_13 "Remittances"
lab var job_main_type_14 "Sale of livestock"
lab var job_main_type_15 "Selling non-timber forest products"
lab var job_main_type_16 "Pensions (including Gov. MCCT)"
lab var job_main_type_17 "Sale of assistance"
lab var job_main_type_18 "Cash for Work programme"
lab var job_main_type_19 "Others Job Type"
lab var job_main_type_20 "No income activity"

** FCS score for HH working in Fishing Sector **

foreach var in $fcs {
	gen `var'_fish 		= `var' if job_main_type_5 == 1 | job_main_type_6 == 1
	replace `var'_fish	= .m if job_main_type_5 != 1 & job_main_type_6 != 1
	order `var'_fish, before(staple_stock)
	tab `var'_fish, m
}


lab var fcs_score_fish			"Food consumption score - fishery HH"
lab var fcs_acceptable_fish		"FCS - acceptable - fishery HH"
lab var fcs_borderline_fish 	"FCS - borderline - fishery HH"
lab var fcs_poor_fish 			"FCS - poor - fishery HH"

lab var fcs_g1_fish	"Main staples - fishery HH"
lab var fcs_g2_fish "Pulses - fishery HH"
lab var fcs_g3_fish "Vegetables - fishery HH"
lab var fcs_g4_fish "Fruit - fishery HH"
lab var fcs_g5_fish "Meat and fish - fishery HH"
lab var fcs_g6_fish "Milk - fishery HH"
lab var fcs_g7_fish "Sugar - fishery HH"
lab var fcs_g8_fish "Oil - fishery HH"

globa fcsfish 	fcs_g1_fish fcs_g2_fish fcs_g3_fish fcs_g4_fish fcs_g5_fish fcs_g6_fish fcs_g7_fish fcs_g8_fish ///
				fcs_score_fish fcs_acceptable_fish fcs_borderline_fish fcs_poor_fish
	
			
// work_1 
// 	work_1_adult_female work_1_child work_1_adult_both work_1_male_child work_1_female_child work_1_all work_1_other

local workwho adult_male adult_female child adult_both male_child female_child all other 

foreach var in `workwho' {
	forvalue x = 1/4 {
		destring work_`x'_`var', replace
		lab val work_`x'_`var' yesno	
	}
}

// work_1_oth

// work_1_percent_income work_2_percent_income work_3_percent_income work_4_percent_income 
// not able to work as contain - irrelavance data

// income_month 
destring income_month, replace
lab var income_month "HH income in last 3 months"
tab income_month, m

* Winsorized
winsor2 income_month, replace cuts(1 99)

// income_month_average
replace income_month_average = "1" if income_month_average == "Higher than average"
replace income_month_average = "2" if income_month_average == "average"
replace income_month_average = "3" if income_month_average == "lower than average"

lab def income_month_average 1"Higher than average" 2"average" 3"lower than average"
destring income_month_average, replace
lab val income_month_average income_month_average
replace income_month_average = .m if income_month == 0
tab income_month_average, m


** LAND **

// land_access 
gen land_access_type 		= (land_access == "Yes ( Communal )")
replace land_access_type 	= 2 if land_access == "Yes ( Owned )"
replace land_access_type 	= 3 if land_access == "Yes ( Rented )"
replace land_access_type 	= .m if land_access == "No"
order land_access_type, after(land_access)
lab def land_access_type 1"Yes (Communal)" 2"Yes (Owned)" 3"Yes (Rented)"
lab val land_access_type land_access_type
lab var land_access_type "HH access land type"
tab land_access_type, m

forvalue x = 1/3 {
	gen land_access_type_`x' = (land_access_type == `x')
	replace land_access_type_`x' = .m if mi(land_access_type)
	order land_access_type_`x', before(land_measure)
	tab land_access_type_`x', m
}

lab var land_access_type_1 "Communal Land"
lab var land_access_type_2 "Owned"
lab var land_access_type_3 "Rented"

replace land_access = "1" if land_access == "Yes ( Communal )"
replace land_access = "1" if land_access == "Yes ( Owned )"
replace land_access = "1" if land_access == "Yes ( Rented )"
replace land_access = "0" if land_access == "No"
destring land_access, replace
lab val land_access yesno
tab land_access, m

// land_measure 
destring land_measure, replace
replace land_measure = .m if land_access == 0
lab var land_measure "Land measurement in Acres"
tab land_measure, m


** Last year crop **
// lastyr_crop 

local lastcrop lastyr_crop_paddy lastyr_crop_cereals lastyr_crop_flowers lastyr_crop_veg lastyr_crop_beans lastyr_crop_fruit lastyr_crop_dhani lastyr_crop_other lastyr_crop_no 

foreach var in `lastcrop' {
	destring `var', replace
	lab var `var' yesno
	replace `var' = .m if mi(lastyr_crop)
	tab `var', m
}

lab var lastyr_crop_paddy "Paddy production"
lab var lastyr_crop_cereals "Cereals production"
lab var lastyr_crop_flowers "Flowers"
lab var lastyr_crop_veg "Own vegetables production"
lab var lastyr_crop_beans "Pulses/beans production"
lab var lastyr_crop_fruit "Fruits production (mango, coconut etc.)"
lab var lastyr_crop_dhani "Dhani"
lab var lastyr_crop_other "Other"
lab var lastyr_crop_no "No crop production"


// lastyr_crop_oth

global earner 	income_earntot income_men_1518 income_men_1924 income_men_over25 income_women_1518 ///
				income_women_1924 income_women_over25 income_girl income_boy ///
				income_youth_tot income_female_tot income_youth_hh income_female_hh ///			
				job_main_type_1 job_main_type_2 job_main_type_3 job_main_type_4 job_main_type_5 job_main_type_6 job_main_type_7 ///
				job_main_type_8 job_main_type_9 job_main_type_10 job_main_type_11 job_main_type_12 job_main_type_13 job_main_type_14 ///
				job_main_type_15 job_main_type_16 job_main_type_17 job_main_type_18 job_main_type_19 job_main_type_20 ///
				income_month ///
				land_access land_access_type_1 land_access_type_2 land_access_type_3 land_measure ///
				lastyr_crop_paddy lastyr_crop_cereals lastyr_crop_flowers lastyr_crop_veg lastyr_crop_beans ///
				lastyr_crop_fruit lastyr_crop_dhani lastyr_crop_other lastyr_crop_no

**-----------------------------------------------------**
** Coping Strategy Index 
**-----------------------------------------------------**
** 6.12 During the last 30days did anyone in your household have to engage in any of the following activities
** because there was not enough food or money to buy food? 

** livelihood based index
local stress		liveindex_soldhh liveindex_senthhmem liveindex_creditfood liveindex_borrow

foreach var in `stress' {
	replace `var' = "0" if `var' == "No, because I didn’t face a shortage of food"
	replace `var' = "0" if `var' == "No, because I already sold those assets or did this activity and I cannot continue to do it"
	replace `var' = "0" if `var' == "No, because I never had the possibility to do so"
	replace `var' = "1" if `var' == "Yes"
	destring `var', replace
	
	lab val `var' yesno
	tab `var', m
}

local crisis		liveindex_reducehealth liveindex_conseed liveindex_soldassets

foreach var in `crisis' {
	replace `var' = "0" if `var' == "No, because I didn’t face a shortage of food"
	replace `var' = "0" if `var' == "No, because I already sold those assets or did this activity and I cannot continue to do it"
	replace `var' = "0" if `var' == "No, because I never had the possibility to do so"
	replace `var' = "1" if `var' == "Yes"
	destring `var', replace
	
	lab val `var' yesno
	tab `var', m
}
	
local emergency		liveindex_illegal liveindex_soldland liveindex_begged

foreach var in `emergency' {
	replace `var' = "0" if `var' == "No, because I didn’t face a shortage of food"
	replace `var' = "0" if `var' == "No, because I already sold those assets or did this activity and I cannot continue to do it"
	replace `var' = "0" if `var' == "No, because I never had the possibility to do so"
	replace `var' = "1" if `var' == "Yes"
	destring `var', replace
	
	lab val `var' yesno
	tab `var', m
}

egen lcis_emergency_score		= rowtotal(liveindex_illegal liveindex_soldland liveindex_begged)
replace lcis_emergency_score 	= .m if mi(liveindex_soldland) | mi(liveindex_illegal) | mi(liveindex_begged)
tab lcis_emergency_score, m

egen lcis_crisis_score		= rowtotal(liveindex_reducehealth liveindex_conseed liveindex_soldassets)
replace lcis_crisis_score 	= .m if mi(liveindex_soldassets) | mi(liveindex_conseed) | mi(liveindex_reducehealth)
tab lcis_crisis_score, m

egen lcis_stress_score		= rowtotal(liveindex_soldhh liveindex_senthhmem liveindex_creditfood liveindex_borrow)
replace lcis_stress_score 	= .m if mi(liveindex_soldhh) | mi(liveindex_senthhmem) | mi(liveindex_creditfood) | mi(liveindex_borrow)
tab lcis_stress_score, m

gen lcis_secure			= (lcis_stress == 0 & lcis_crisis == 0 & lcis_emergency == 0)
replace lcis_secure		= .m if mi(lcis_stress) | mi(lcis_crisis) | mi(lcis_emergency)
tab lcis_secure, m

gen lcis_stress			= (lcis_stress_score > 0 & lcis_crisis_score == 0 & lcis_emergency_score == 0)
tab lcis_stress, m

gen lcis_crisis			= (lcis_crisis_score > 0 & lcis_emergency_score == 0)
tab lcis_crisis, m

gen lcis_emergency  	= (lcis_emergency_score > 0)
tab lcis_emergency, m


** reporting variables **
lab var lcis_secure		"livelihood based CSI - secure"
lab var lcis_stress		"livelihood based CSI - stress"
lab var lcis_crisis		"livelihood based CSI - crisis"
lab var lcis_emergency 	"livelihood based CSI - emergency"

order lcis_secure lcis_stress lcis_crisis lcis_emergency, after(liveindex_soldland)

global csi	lcis_secure lcis_stress lcis_crisis lcis_emergency 


*------------------------------------------------------------------------------*
***  7. Migration ***
*------------------------------------------------------------------------------*

// migrate_temp 
destring migrate_temp, replace
lab var migrate_temp "number of HH member migrate for short-term" 
tab migrate_temp, m

// migrate_longterm
destring migrate_longterm, replace
lab var migrate_longterm "number of HH member migrate for long-term" 
tab migrate_longterm, m

gen migration_yn = ((migrate_temp > 0 & !mi(migrate_temp)) | migrate_longterm > 0 & !mi(migrate_longterm))
replace migration_yn = .m if mi(migrate_temp) & mi(migrate_longterm)
order migration_yn, before(migrate_temp)
lab var migration_yn "HH with migrant pop"
tab migration_yn, m

global migration migration_yn migrate_temp migrate_longterm


*------------------------------------------------------------------------------*
***  8. HH assets ***
*------------------------------------------------------------------------------*

// livestock 
tab livestock, m

// livestock_cattle livestock_buffalo livestock_pig livestock_chicken livestock_duck livestock_horse livestock_goat livestock_no
local livestock livestock_cattle livestock_buffalo livestock_pig livestock_chicken livestock_duck livestock_horse livestock_goat livestock_no

foreach var in `livestock' {
	destring `var', replace
	lab val `var' yesno
	replace `var' = .m if mi(livestock)
	tab `var', m
	
	if "`var'" != "livestock_no" {
		destring `var'_num, replace
		replace `var'_num = 0 if `var' == 0
		tab `var'_num, m
		
		replace `var' = 0 if `var'_num == 0
	}
}

lab var livestock_cattle "Cattle"
lab var livestock_buffalo "Buffalo"
lab var livestock_pig "Pig"
lab var livestock_chicken "Chicken"
lab var livestock_duck "Ducks"
lab var livestock_horse "Horses"
lab var livestock_goat "Goats"
lab var livestock_no "Nothing owned"

lab var livestock_cattle_num "Number of Cattle"
lab var livestock_buffalo_num "Number of Buffalo"
lab var livestock_pig_num "Number of Pig"
lab var livestock_chicken_num "Number of Chicken"
lab var livestock_duck_num "Number of Ducks"
lab var livestock_horse_num "Number of Horses"
lab var livestock_goat_num "Number of Goats"


// hh_assets 
tab hh_assets, m

// hh_assets_tiller hh_assets_ptiller hh_assets_tractor hh_assets_tlerjee hh_assets_pthresher hh_assets_bpsprayer hh_assets_storeage hh_assets_drynet hh_assets_pump hh_assets_trailer hh_assets_fishnet hh_assets_sboat hh_assets_sboat_eng hh_assets_mboat hh_assets_lboat hh_assets_generator hh_assets_bicycle hh_assets_smill hh_assets_stools hh_assets_tv hh_assets_car hh_assets_cycle hh_assets_bed hh_assets_solor hh_assets_sewing hh_assets_chainsaw hh_assets_handsaw hh_assets_bankacc hh_assets_sphone hh_assets_kphone hh_assets_radio hh_assets_dvd hh_assets_fan hh_assets_cabinet hh_assets_jewel
local hhassets hh_assets_tiller hh_assets_ptiller hh_assets_tractor hh_assets_tlerjee hh_assets_pthresher hh_assets_bpsprayer hh_assets_storeage hh_assets_drynet hh_assets_pump hh_assets_trailer hh_assets_fishnet hh_assets_sboat hh_assets_sboat_eng hh_assets_mboat hh_assets_lboat hh_assets_generator hh_assets_bicycle hh_assets_smill hh_assets_stools hh_assets_tv hh_assets_car hh_assets_cycle hh_assets_bed hh_assets_solor hh_assets_sewing hh_assets_chainsaw hh_assets_handsaw hh_assets_bankacc hh_assets_sphone hh_assets_kphone hh_assets_radio hh_assets_dvd hh_assets_fan hh_assets_cabinet hh_assets_jewel

foreach var in `hhassets' {
	destring `var', replace
	lab val `var' yesno
	replace `var' = .m if mi(hh_assets)
	tab `var', m
	
	destring `var'_num, replace
	replace `var'_num = 0 if `var' == 0
	tab `var'_num, m
	
	replace `var' = 0 if `var'_num == 0
}

replace hh_assets_sphone_num = .n if hh_assets_sphone_num == 900

lab var hh_assets_tiller "Plough/ tiller (drawn by animal)"
lab var hh_assets_ptiller "Power tiller"
lab var hh_assets_tractor "Tractor"
lab var hh_assets_tlerjee "Trawlerjee"
lab var hh_assets_pthresher "Power thresher"
lab var hh_assets_bpsprayer "Backpack sprayer"
lab var hh_assets_storeage "Improved crop storage"
lab var hh_assets_drynet "Tarpaulin or seed drying net"
lab var hh_assets_pump "Irrigation pump"
lab var hh_assets_trailer "Trailer / trawler"
lab var hh_assets_fishnet "Fish and crab nets"
lab var hh_assets_sboat "Small boat & no engine"
lab var hh_assets_sboat_eng "Small boat with small engine"
lab var hh_assets_mboat "Medium boat with engine"
lab var hh_assets_lboat "Larger boat with larger engine"
lab var hh_assets_generator "Generator"
lab var hh_assets_bicycle "Bicycle"
lab var hh_assets_smill "Rice powder machine/small mill"
lab var hh_assets_stools "Small tools (hoe, axes etc.)"
lab var hh_assets_tv "Television DVD, soundbox, sky net"
lab var hh_assets_car "Car"
lab var hh_assets_cycle "Motorcycle"
lab var hh_assets_bed "Bed (wooden or steel), table"
lab var hh_assets_solor "Solar system"
lab var hh_assets_sewing "Sewing machine"
lab var hh_assets_chainsaw "Chain saw"
lab var hh_assets_handsaw "Hand saw"
lab var hh_assets_bankacc "Bank account"
lab var hh_assets_sphone "Smartphone"
lab var hh_assets_kphone "Keypad phone"
lab var hh_assets_radio "Radio"
lab var hh_assets_dvd "DVD player"
lab var hh_assets_fan "Standing fan"
lab var hh_assets_cabinet "Food storage cabinet"
lab var hh_assets_jewel "Gold, Jewelry"


lab var hh_assets_tiller_num "Number of Plough/ tiller (drawn by animal)"
lab var hh_assets_ptiller_num "Number of Power tiller"
lab var hh_assets_tractor_num "Number of Tractor"
lab var hh_assets_tlerjee_num "Number of Trawlerjee"
lab var hh_assets_pthresher_num "Number of Power thresher"
lab var hh_assets_bpsprayer_num "Number of Backpack sprayer"
lab var hh_assets_storeage_num "Number of Improved crop storage"
lab var hh_assets_drynet_num "Number of Tarpaulin or seed drying net"
lab var hh_assets_pump_num "Number of Irrigation pump"
lab var hh_assets_trailer_num "Number of Trailer / trawler"
lab var hh_assets_fishnet_num "Number of Fish and crab nets"
lab var hh_assets_sboat_num "Number of Small boat & no engine"
lab var hh_assets_sboat_eng_num "Number of Small boat with small engine"
lab var hh_assets_mboat_num "Number of Medium boat with engine"
lab var hh_assets_lboat_num "Number of Larger boat with larger engine"
lab var hh_assets_generator_num "Number of Generator"
lab var hh_assets_bicycle_num "Number of Bicycle"
lab var hh_assets_smill_num "Number of Rice powder machine/small mill"
lab var hh_assets_stools_num "Number of Small tools (hoe, axes etc.)"
lab var hh_assets_tv_num "Number of Television DVD, soundbox, sky net"
lab var hh_assets_car_num "Number of Car"
lab var hh_assets_cycle_num "Number of Motorcycle"
lab var hh_assets_bed_num "Number of Bed (wooden or steel), table"
lab var hh_assets_solor_num "Number of Solar system"
lab var hh_assets_sewing_num "Number of Sewing machine"
lab var hh_assets_chainsaw_num "Number of Chain saw"
lab var hh_assets_handsaw_num "Number of Hand saw"
lab var hh_assets_bankacc_num "Number of Bank account"
lab var hh_assets_sphone_num "Number of Smartphone"
lab var hh_assets_kphone_num "Number of Keypad phone"
lab var hh_assets_radio_num "Number of Radio"
lab var hh_assets_dvd_num "Number of DVD player"
lab var hh_assets_fan_num "Number of Standing fan"
lab var hh_assets_cabinet_num "Number of Food storage cabinet"
lab var hh_assets_jewel_num "Number of Gold, Jewelry"


** productive assets **
local prodassets	livestock_cattle livestock_buffalo livestock_pig livestock_chicken livestock_duck livestock_horse livestock_goat ///
					hh_assets_tiller hh_assets_ptiller hh_assets_tractor hh_assets_tlerjee ///
					hh_assets_pthresher hh_assets_bpsprayer hh_assets_storeage hh_assets_drynet ///
					hh_assets_pump hh_assets_trailer hh_assets_fishnet hh_assets_sboat hh_assets_sboat_eng ///
					hh_assets_mboat hh_assets_lboat hh_assets_generator hh_assets_smill hh_assets_stools ///
					hh_assets_car hh_assets_cycle hh_assets_solor hh_assets_sewing hh_assets_chainsaw ///
					hh_assets_handsaw hh_assets_bankacc hh_assets_sphone hh_assets_kphone hh_assets_jewel 
					
egen hh_assets_prodt = rowtotal(`prodassets')
lab var hh_assets_prodt "Number of productive assets type owned by HH"
order  hh_assets_prodt, after(hh_assets_jewel_num)
tab hh_assets_prodt, m

gen hh_assets_prodt_yn = (hh_assets_prodt > 0 & !mi(hh_assets_prodt))
replace hh_assets_prodt_yn = .m if mi(hh_assets_prodt)
lab val hh_assets_prodt_yn yesno
lab var hh_assets_prodt_yn "HH own at least one of the productive assets"
order  hh_assets_prodt_yn, before(hh_assets_prodt)
tab hh_assets_prodt_yn, m

global hhassets	hh_assets_prodt_yn hh_assets_prodt ///
				livestock_cattle livestock_buffalo livestock_pig livestock_chicken livestock_duck livestock_horse ///
				livestock_goat livestock_no ///
				livestock_cattle_num livestock_buffalo_num livestock_pig_num livestock_chicken_num livestock_duck_num ///
				livestock_horse_num livestock_goat_num ///
				hh_assets_tiller hh_assets_ptiller hh_assets_tractor hh_assets_tlerjee hh_assets_pthresher hh_assets_bpsprayer ///
				hh_assets_storeage hh_assets_drynet hh_assets_pump hh_assets_trailer hh_assets_fishnet hh_assets_sboat ///
				hh_assets_sboat_eng hh_assets_mboat hh_assets_lboat hh_assets_generator hh_assets_bicycle hh_assets_smill ///
				hh_assets_stools hh_assets_tv hh_assets_car hh_assets_cycle hh_assets_bed hh_assets_solor hh_assets_sewing ///
				hh_assets_chainsaw hh_assets_handsaw hh_assets_bankacc hh_assets_sphone hh_assets_kphone hh_assets_radio ///
				hh_assets_dvd hh_assets_fan hh_assets_cabinet hh_assets_jewel ///
				hh_assets_tiller_num hh_assets_ptiller_num hh_assets_tractor_num hh_assets_tlerjee_num hh_assets_pthresher_num ///
				hh_assets_bpsprayer_num hh_assets_storeage_num hh_assets_drynet_num hh_assets_pump_num hh_assets_trailer_num ///
				hh_assets_fishnet_num hh_assets_sboat_num hh_assets_sboat_eng_num hh_assets_mboat_num hh_assets_lboat_num ///
				hh_assets_generator_num hh_assets_bicycle_num hh_assets_smill_num hh_assets_stools_num hh_assets_tv_num ///
				hh_assets_car_num hh_assets_cycle_num hh_assets_bed_num hh_assets_solor_num hh_assets_sewing_num hh_assets_chainsaw_num ///
				hh_assets_handsaw_num hh_assets_bankacc_num hh_assets_sphone_num hh_assets_kphone_num hh_assets_radio_num ///
				hh_assets_dvd_num hh_assets_fan_num hh_assets_cabinet_num hh_assets_jewel_num
				
				



** 9: HOUSEHOLD EXPENDITURES **
// (9.1 How much did your household spend on the following items? 
// For each list item, ask amount, then ask which frequency is most appropriate for that item. 
// (Note: Pre-listed frequencies in middle column are expected frequencies. 
// Ask respondents to confirm frequencies for each item.) 

// hhexp_staple hhexp_food_oth hhexp_snack hhexp_fuel hhexp_hhitems hhexp_alcohol hhexp_dwater hhexp_lottery hhexp_transport hhexp_debt hhexp_electricity hhexp_phone hhexp_cloth hhexp_business hhexp_remittance hhexp_rent hhexp_health_adult hhexp_health_child hhexp_social hhexp_edu hhexp_house hhexp_livelihood hhexp_oth
lab def expfreq 1"Daily" 2"Weekly" 3"Monthly" 4"Quarterly" 5"Twice a year" 6"Annually"

local hhexp hhexp_staple hhexp_food_oth hhexp_snack hhexp_fuel hhexp_hhitems hhexp_alcohol hhexp_dwater hhexp_lottery hhexp_transport hhexp_debt hhexp_electricity hhexp_phone hhexp_cloth hhexp_business hhexp_remittance hhexp_rent hhexp_health_adult hhexp_health_child hhexp_social hhexp_edu hhexp_house hhexp_livelihood 

foreach var in `hhexp' {
	destring `var', replace
	replace `var' = .m if mi(`var')
	
	replace `var'_freq = "1" if `var'_freq == "Daily"
	replace `var'_freq = "2" if `var'_freq == "Weekly"
	replace `var'_freq = "3" if `var'_freq == "Monthly"
	replace `var'_freq = "4" if `var'_freq == "Quarterly"
	replace `var'_freq = "5" if `var'_freq == "Twice a year"
	replace `var'_freq = "6" if `var'_freq == "Annually"
	
	destring `var'_freq, replace
	lab val `var'_freq expfreq
	tab `var'_freq, m
	
}

lab var hhexp_staple "Staple food"
lab var hhexp_food_oth "Other foods"
lab var hhexp_snack "Snacks"
lab var hhexp_fuel "Firewood/cooking fuel/charcoal"
lab var hhexp_hhitems "Household items"
lab var hhexp_alcohol "Betel nut/Cigarettes/Alcohol"
lab var hhexp_dwater "Drinking water"
lab var hhexp_lottery "Lottery/gambling"
lab var hhexp_transport "Transportation"
lab var hhexp_debt "Debt repayment"
lab var hhexp_electricity "Electricity and TV"
lab var hhexp_phone "Mobile phone and phone credit"
lab var hhexp_cloth "Clothing or beauty products"
lab var hhexp_business "Trading expenses related to your business"
lab var hhexp_remittance "Sending remittances to relatives"
lab var hhexp_rent "Rent"
lab var hhexp_health_adult "Health for adults and children > 5 years"
lab var hhexp_health_child "Health for children < 5 years"
lab var hhexp_social "Celebrations/social events/donations"
lab var hhexp_edu "Education"
lab var hhexp_house "House construction /maintenance /repair"
lab var hhexp_livelihood "Farming or fishing costs"

lab var hhexp_staple_freq "frequency of Staple food"
lab var hhexp_food_oth_freq "frequency of Other foods"
lab var hhexp_snack_freq "frequency of Snacks"
lab var hhexp_fuel_freq "frequency of Firewood/cooking fuel/charcoal"
lab var hhexp_hhitems_freq "frequency of Household items"
lab var hhexp_alcohol_freq "frequency of Betel nut/Cigarettes/Alcohol"
lab var hhexp_dwater_freq "frequency of Drinking water"
lab var hhexp_lottery_freq "frequency of Lottery/gambling"
lab var hhexp_transport_freq "frequency of Transportation"
lab var hhexp_debt_freq "frequency of Debt repayment"
lab var hhexp_electricity_freq "frequency of Electricity and TV"
lab var hhexp_phone_freq "frequency of Mobile phone and phone credit"
lab var hhexp_cloth_freq "frequency of Clothing or beauty products"
lab var hhexp_business_freq "frequency of Trading expenses related to your business"
lab var hhexp_remittance_freq "frequency of Sending remittances to relatives"
lab var hhexp_rent_freq "frequency of Rent"
lab var hhexp_health_adult_freq "frequency of Health for adults and children > 5 years"
lab var hhexp_health_child_freq "frequency of Health for children < 5 years"
lab var hhexp_social_freq "frequency of Celebrations/social events/donations"
lab var hhexp_edu_freq "frequency of Education"
lab var hhexp_house_freq "frequency of House construction /maintenance /repair"
lab var hhexp_livelihood_freq "frequency of Farming or fishing costs"

// hhexp_oth

** budget shared - expenditure **
local hhexp hhexp_staple hhexp_food_oth hhexp_snack hhexp_fuel hhexp_hhitems hhexp_alcohol hhexp_dwater hhexp_lottery hhexp_transport hhexp_debt hhexp_electricity hhexp_phone hhexp_cloth hhexp_business hhexp_remittance hhexp_rent hhexp_health_adult hhexp_health_child hhexp_social hhexp_edu hhexp_house hhexp_livelihood 

foreach var in `hhexp' {
	
	gen `var'_annual		= 0
	replace `var'_annual	= `var' if `var'_freq 						== 6
	replace `var'_annual	= round(`var' * 2, 0.1) if `var'_freq 		== 5
	replace `var'_annual	= round(`var' * 4, 0.1) if `var'_freq 		== 4
	replace `var'_annual	= round(`var' * 12, 0.1) if `var'_freq 		== 3
	replace `var'_annual	= round(`var' * 52.143, 0.1) if `var'_freq 	== 2
	replace `var'_annual	= round(`var' * 2, 365) if `var'_freq		== 1
	
	replace `var'_annual 	= .m if mi(`var') &  mi(`var'_freq)
	
	tab `var'_annual, m	
}

* Winsorized
local win99 hhexp_staple_annual hhexp_food_oth_annual hhexp_debt_annual hhexp_health_child_annual hhexp_edu_annual hhexp_house_annual hhexp_livelihood_annual
foreach var in `win99' {
	winsor2 `var', replace cuts(1 99)
}

local win95 hhexp_snack_annual hhexp_phone_annual hhexp_health_adult_annual
foreach var in `win95' {
	winsor2 `var', replace cuts(1 95)
}


// total annual expenditure //
egen hhexp_tot_annual = rowtotal(hhexp_staple_annual hhexp_food_oth_annual hhexp_snack_annual ///
						hhexp_fuel_annual hhexp_hhitems_annual hhexp_alcohol_annual hhexp_dwater_annual ///
						hhexp_lottery_annual hhexp_transport_annual hhexp_debt_annual hhexp_electricity_annual ///
						hhexp_phone_annual hhexp_cloth_annual hhexp_business_annual hhexp_remittance_annual ///
						hhexp_rent_annual hhexp_health_adult_annual hhexp_health_child_annual hhexp_social_annual ///
						hhexp_edu_annual hhexp_house_annual hhexp_livelihood_annual)
lab var hhexp_tot_annual "annual total expenditure" 
tab hhexp_tot_annual, m

//winsor2 hhexp_tot_annual, replace cuts(1 99)
	
// total food annual expenditure //
egen hhexp_food_annual = rowtotal(hhexp_staple_annual hhexp_food_oth_annual)
lab var hhexp_food_annual "annual food expenditure"
tab hhexp_food_annual, m

//winsor2 hhexp_food_annual, replace cuts(1 99)

// total beverage + snack annual expenditure //
egen hhexp_beverage_annual = rowtotal(hhexp_alcohol_annual hhexp_snack_annual)
lab var hhexp_beverage_annual "annual beverage and snacks expenditure"
tab hhexp_beverage_annual, m

//winsor2 hhexp_beverage_annual, replace cuts(1 99)

// total health annual expenditure //
egen hhexp_health_annual = rowtotal(hhexp_health_adult_annual hhexp_health_child_annual)
lab var hhexp_health_annual "annual health expenditure"
tab hhexp_health_annual, m

// total livelihood annual expenditure //
egen hhexp_allbusi_annual = rowtotal(hhexp_livelihood_annual hhexp_business_annual hhexp_rent_annual)
lab var hhexp_allbusi_annual "annual livelihood and business expenditure"
tab hhexp_allbusi_annual, m

// winsor2 hhexp_allbusi_annual, replace cuts(1 99)

// total house and household items annual expenditure //
egen hhexp_hhhouse_annual = rowtotal(hhexp_house_annual hhexp_hhitems_annual hhexp_cloth_annual)
lab var hhexp_hhhouse_annual "annual house and household items expenditure"
tab hhexp_hhhouse_annual, m

//winsor2 hhexp_hhhouse_annual, replace cuts(1 99)


// hhexp_debt_annual  
//winsor2 hhexp_debt_annual, replace cuts(1 99)

// total regular bill and payments annual expenditure //
egen hhexp_regpay_annual = rowtotal(hhexp_fuel_annual hhexp_dwater_annual hhexp_electricity_annual hhexp_phone_annual)
lab var hhexp_regpay_annual "annual regular bills and payments expenditure"
tab hhexp_regpay_annual, m

//winsor2 hhexp_regpay_annual, replace cuts(1 99)

// hhexp_transport_annual
//winsor2 hhexp_transport_annual, replace cuts(1 99)


// budget share
local budget	hhexp_food_annual hhexp_beverage_annual hhexp_health_annual hhexp_edu_annual ///
				hhexp_allbusi_annual hhexp_hhhouse_annual hhexp_regpay_annual ///
				hhexp_debt_annual hhexp_social_annual hhexp_lottery_annual ///
				hhexp_transport_annual hhexp_remittance_annual

				
foreach var in `budget' {
	gen `var'_s = round((`var'/hhexp_tot_annual) * 100, 0.1)
	replace `var'_s = .m if mi(`var')
	tab `var'_s, m

}

lab var hhexp_food_annual			"Annual expense - Foods"
lab var hhexp_beverage_annual 		"Annual expense - Beverage & Snacks"
lab var hhexp_health_annual 		"Annual expense - - Health"
lab var hhexp_edu_annual			"Annual expense - - Education"
lab var hhexp_allbusi_annual 		"Annual expense - - Livelihood & Business"
lab var hhexp_hhhouse_annual 		"Annual expense - - House & Household Items"
lab var hhexp_regpay_annual 		"Annual expense - Electric/Fuel/Water/Phone Bills"
lab var hhexp_debt_annual 			"Annual expense - - Debt"
lab var hhexp_social_annual 		"Annual expense - - Social Events & Celebration"
lab var hhexp_lottery_annual 		"Annual expense - - Lottery/Gambling"
lab var hhexp_transport_annual 		"Annual expense - - Transport"
lab var hhexp_remittance_annual		"Annual expense - - Remittance"


lab var hhexp_food_annual_s			"% of annual Budget shared - Foods"
lab var hhexp_beverage_annual_s 	"% of annual Budget shared - Beverage & Snacks"
lab var hhexp_health_annual_s 		"% of annual Budget shared - Health"
lab var hhexp_edu_annual_s 			"% of annual Budget shared - Education"
lab var hhexp_allbusi_annual_s 		"% of annual Budget shared - Livelihood & Business"
lab var hhexp_hhhouse_annual_s 		"% of annual Budget shared - House & Household Items"
lab var hhexp_regpay_annual_s 		"% of annual Budget shared - Electric/Fuel/Water/Phone Bills"
lab var hhexp_debt_annual_s 		"% of annual Budget shared - Debt"
lab var hhexp_social_annual_s 		"% of annual Budget shared - Social Events & Celebration"
lab var hhexp_lottery_annual_s 		"% of annual Budget shared - Lottery/Gambling"
lab var hhexp_transport_annual_s 	"% of annual Budget shared - Transport"
lab var hhexp_remittance_annual_s	"% of annual Budget shared - Remittance"


order *_annual *_s, before(hh_financial_cond)

// hh_financial_cond 
replace hh_financial_cond = "1" if hh_financial_cond == "We have had big financial problems - we have fallen behind with many expenditures or loan repayments"
replace hh_financial_cond = "2" if hh_financial_cond == "We have fallen behind with some expenditures or loan repayments"
replace hh_financial_cond = "3" if hh_financial_cond == "We have kept up with all expenditures and loans but it has been difficult"
replace hh_financial_cond = "4" if hh_financial_cond == "We have kept up with all expenditures and loans with no problems"
replace hh_financial_cond = "5" if hh_financial_cond == "Don’t know"
replace hh_financial_cond = "6" if hh_financial_cond == "No answer"
destring hh_financial_cond, replace
lab def hh_financial_cond 	1"We have had big financial problems - we have fallen behind with many expenditures or loan repayments" ///
							2"We have fallen behind with some expenditures or loan repayments" ///
							3"We have kept up with all expenditures and loans but it has been difficult" ///
							4"We have kept up with all expenditures and loans with no problems" 5"Don’t know" 6"No answer"
lab val hh_financial_cond hh_financial_cond
replace hh_financial_cond = .n if mi(hh_financial_cond)
tab hh_financial_cond, m

forvalue x = 1/6 {
	gen hh_financial_`x' = (hh_financial_cond == `x')
	replace hh_financial_`x' = .m if mi(hh_financial_cond)
	order hh_financial_`x', before(hh_left_money)
	tab hh_financial_`x', m
}

lab var hh_financial_1 "Big financial problems" 
lab var hh_financial_2 "Fallen behind with some expenditures" 
lab var hh_financial_3 "Kept up with all expenditures but difficult" 
lab var hh_financial_4 "No problems" 
lab var hh_financial_5 "Don’t know" 
lab var hh_financial_6 "No answer"


// hh_left_money 
replace hh_left_money = "1" if hh_left_money == "We always run out, never have money left over"
replace hh_left_money = "2" if hh_left_money == "We sometimes run out, sometimes we have money left over"
replace hh_left_money = "3" if hh_left_money == "We never run out, but we never have money left over"
replace hh_left_money = "4" if hh_left_money == "We never run out, we always have money left over"
replace hh_left_money = "5" if hh_left_money == "Don’t know"
replace hh_left_money = "6" if hh_left_money == "No answer"
destring hh_left_money, replace
lab def hh_left_money	1"We always run out, never have money left over" 2"We sometimes run out, sometimes we have money left over" ///
						3"We never run out, but we never have money left over" 4"We never run out, we always have money left over" ///
						5"Don’t know" 6"No answer"
lab val hh_left_money hh_left_money
replace hh_left_money = .n if mi(hh_left_money)
tab hh_left_money, m

forvalue x = 1/6 {
	gen hh_left_money_`x' = (hh_left_money == `x')
	replace hh_left_money_`x' = .m if mi(hh_left_money)
	order hh_left_money_`x', before(hh_cover_expend)
	tab hh_left_money_`x', m	
}

lab var hh_left_money_1 "Always run out, never left over" 
lab var hh_left_money_2 "Sometimes run out, sometimes left over" 
lab var hh_left_money_3 "Never run out, never left over" 
lab var hh_left_money_4 "Never run out, always left over"
lab var hh_left_money_5 "Don’t know" 
lab var hh_left_money_6 "No answer"


// hh_cover_expend 
replace hh_cover_expend = "1" if hh_cover_expend == "Less than three days"
replace hh_cover_expend = "2" if hh_cover_expend == "More than three days but less than one week"
replace hh_cover_expend = "3" if hh_cover_expend == "More than one week but less than one month"
replace hh_cover_expend = "4" if hh_cover_expend == "More than one month but less than three months"
replace hh_cover_expend = "5" if hh_cover_expend == "More than three months but less than six months"
replace hh_cover_expend = "6" if hh_cover_expend == "Six months or more"
replace hh_cover_expend = "7" if hh_cover_expend == "Don’t know"
replace hh_cover_expend = "8" if hh_cover_expend == "No answer"
destring hh_cover_expend, replace
lab def hh_cover_expend 1"Less than three days" 2"More than three days but less than one week" ///
						3"More than one week but less than one month" 4"More than one month but less than three months" ///
						5"More than three months but less than six months" 6"Six months or more" ///
						7"Don’t know" 8"No answer"
lab val hh_cover_expend hh_cover_expend
replace hh_cover_expend = .n if mi(hh_cover_expend)
tab hh_cover_expend, m

forvalue x = 1/8 {
	gen hh_cover_expend_`x' = (hh_cover_expend == `x')
	replace hh_cover_expend_`x' = .m if mi(hh_cover_expend)
	order hh_cover_expend_`x', before(unexpect_yn)
	tab hh_cover_expend_`x', m	
}

lab var hh_cover_expend_1 "Less than 3 days" 
lab var hh_cover_expend_2 "More than 3 days but less than 1 week"
lab var hh_cover_expend_3 "More than 1 week but less than 1 month" 
lab var hh_cover_expend_4 "More than one 1 but less than 3 months"
lab var hh_cover_expend_5 "More than 3 months but less than 6 months" 
lab var hh_cover_expend_6 "6 months or more"
lab var hh_cover_expend_7 "Don’t know" 
lab var hh_cover_expend_8 "No answer" 

// unexpect_yn 
replace unexpect_yn = "1" if unexpect_yn == "Yes"
replace unexpect_yn = "0" if unexpect_yn == "No"
destring unexpect_yn, replace
lab val unexpect_yn yesno
replace unexpect_yn = .m if mi(unexpect_yn)
tab unexpect_yn, m

// unexpect_cope 
tab unexpect_cope, m

local cope unexpect_cope_loan unexpect_cope_save unexpect_cope_assist unexpect_cope_sold unexpect_cope_dk unexpect_cope_noans 
foreach var in `cope' {
	destring `var', replace
	lab val `var' yesno
	replace `var' = .m if unexpect_yn != 1
	tab `var', m
}

lab var unexpect_cope_loan "Loan(s)"
lab var unexpect_cope_save "Savings"
lab var unexpect_cope_assist "Family/friends/neighbours’ assistance"
lab var unexpect_cope_sold "Sold assets / gold"
lab var unexpect_cope_dk "Don’t know"
lab var unexpect_cope_noans "No answer"

// unexpect_cope_scenario
replace unexpect_cope_scenario = "1" if unexpect_cope_scenario == "Yes, with my savings"
replace unexpect_cope_scenario = "2" if unexpect_cope_scenario == "Yes, will get a loan to pay for it"
replace unexpect_cope_scenario = "3" if unexpect_cope_scenario == "Yes, but I don’t know how now"
replace unexpect_cope_scenario = "4" if unexpect_cope_scenario == "No, I won’t be able to pay for it"
replace unexpect_cope_scenario = "5" if unexpect_cope_scenario == "Don’t know"
replace unexpect_cope_scenario = "6" if unexpect_cope_scenario == "No answer"
destring unexpect_cope_scenario, replace
lab def unexpect_cope_scenario	1"Yes, with my savings" 2"Yes, will get a loan to pay for it" ///
								3"Yes, but I don’t know how now" 4"No, I won’t be able to pay for it" ///
								5"Don’t know" 6"No answer"
lab val unexpect_cope_scenario unexpect_cope_scenario
replace unexpect_cope_scenario = .n if mi(unexpect_cope_scenario)
tab unexpect_cope_scenario, m

forvalue x = 1/6 {
	gen unexpect_scenario_`x' = (unexpect_cope_scenario == `x')
	replace unexpect_scenario_`x' = .m if mi(unexpect_cope_scenario)
	order unexpect_scenario_`x', before(loan_yn)
	tab unexpect_scenario_`x', m
}

lab var unexpect_scenario_1 "Yes, with my savings"
lab var unexpect_scenario_2 "Yes, will get a loan to pay for it"
lab var unexpect_scenario_3 "Yes, but I don’t know how now"
lab var unexpect_scenario_4 "No, I won’t be able to pay for it"
lab var unexpect_scenario_5 "Don’t know"
lab var unexpect_scenario_6 "No answer"


&&
// income and debth ration 
income_month



global budget 	hh_financial_1 hh_financial_2 hh_financial_3 hh_financial_4 hh_financial_5 hh_financial_6 ///
				hh_left_money_1 hh_left_money_2 hh_left_money_3 hh_left_money_4 hh_left_money_5 hh_left_money_6 ///
				hh_cover_expend_1 hh_cover_expend_2 hh_cover_expend_3 hh_cover_expend_4 hh_cover_expend_5 hh_cover_expend_6 hh_cover_expend_7 hh_cover_expend_8 ///
				unexpect_yn unexpect_cope_loan unexpect_cope_save unexpect_cope_assist unexpect_cope_sold unexpect_cope_dk unexpect_cope_noans ///
				unexpect_scenario_1 unexpect_scenario_2 unexpect_scenario_3 unexpect_scenario_4 unexpect_scenario_5 unexpect_scenario_6

global share	hhexp_tot_annual ///
				hhexp_food_annual hhexp_beverage_annual hhexp_health_annual hhexp_edu_annual ///
				hhexp_allbusi_annual hhexp_hhhouse_annual hhexp_regpay_annual ///
				hhexp_debt_annual hhexp_social_annual hhexp_lottery_annual ///
				hhexp_transport_annual hhexp_remittance_annual ///
				hhexp_food_annual_s hhexp_beverage_annual_s hhexp_health_annual_s hhexp_edu_annual_s ///
				hhexp_allbusi_annual_s hhexp_hhhouse_annual_s hhexp_regpay_annual_s hhexp_debt_annual_s ///
				hhexp_social_annual_s hhexp_lottery_annual_s hhexp_transport_annual_s hhexp_remittance_annual_s

*------------------------------------------------------------------------------*
** 10: CREDIT AND SAVINGS **
*------------------------------------------------------------------------------*

// CREDIT //

// loan_yn 
replace loan_yn = "1" if loan_yn == "Yes"
replace loan_yn = "0" if loan_yn == "No"
destring loan_yn, replace
lab val loan_yn yesno
replace loan_yn = .m if mi(loan_yn)
tab loan_yn, m

// loan_source 
tab loan_source, m

local loansource loan_source_bank loan_source_mfi loan_source_vsla loan_source_family loan_source_mlender loan_source_shop loan_source_company loan_source_religious loan_source_seller loan_source_gov loan_source_other 
foreach var in `loansource' {
	destring `var', replace
	lab val `var' yesno
	replace `var' = .m if loan_yn != 1
	tab `var', m
}

lab var loan_source_bank "Private bank"
lab var loan_source_mfi "Micro-credit provider"
lab var loan_source_vsla "Voluntary savings group (VSLA, Evergreen project…)"
lab var loan_source_family "Family or friend"
lab var loan_source_mlender "Money lender"
lab var loan_source_shop "Shop-keeper"
lab var loan_source_company "Private company (fertilizer company etc.)"
lab var loan_source_religious "Temple/monastery"
lab var loan_source_seller "Received purchased goods from producer/seller before paying"
lab var loan_source_gov "Government (MAB, Cooperative Department…)"
lab var loan_source_other "Other"

// loan_source_oth

** Priority for source **
** a lot of missing value for the priority source selecton
** in xls form these questions fields were not applied as yes in require field
// loan_main_bank loan_main_mfi loan_main_vsla loan_main_family loan_main_mlender loan_main_shop loan_main_company loan_main_religious loan_main_seller loan_main_gov loan_main_other
lab def loanmain 1"First" 2"Second" 3"Third" 4"Not applicable"

local loanmain bank mfi vsla family mlender shop company religious seller gov other

foreach var in `loanmain' {
	replace loan_main_`var' = "1" if loan_main_`var' == "First"
	replace loan_main_`var' = "2" if loan_main_`var' == "second"
	replace loan_main_`var' = "3" if loan_main_`var' == "Third"
	replace loan_main_`var' = "4" if loan_main_`var' == "Not applicable"
	destring loan_main_`var', replace
	
	lab val loan_main_`var' loanmain
	replace loan_source_`var' = 1 if loan_main_`var' < 4
	replace loan_main_`var' = .m if mi(loan_main_`var')
	tab loan_main_`var', m
}

lab var loan_main_bank "Private bank"
lab var loan_main_mfi "Micro-credit provider"
lab var loan_main_vsla "Voluntary savings group (VSLA, Evergreen project…)"
lab var loan_main_family "Family or friend"
lab var loan_main_mlender "Money lender"
lab var loan_main_shop "Shop-keeper"
lab var loan_main_company "Private company (fertilizer company etc.)"
lab var loan_main_religious "Temple/monastery"
lab var loan_main_seller "Received purchased goods from producer/seller before paying"
lab var loan_main_gov "Government (MAB, Cooperative Department…)"
lab var loan_main_other "Other"

/*
local loanmain bank mfi vsla family mlender shop company religious seller gov other
gen loan_main_1 = ""
gen loan_main_2 = ""
gen loan_main_3 = ""

foreach var in `loanmain' {
	forvalue x = 1/3 {
		replace loan_main_`x' = "`var'" if loan_main_`var' == `x'
	}
}

order loan_main_1 loan_main_2 loan_main_3, after(loan_main_other)
*/

** Priority important **
// loan_usage 
tab loan_usage, m

local loanuse loan_usage_homeimprove loan_usage_homebuy loan_usage_construct loan_usage_landbuy loan_usage_worktools loan_usage_food loan_usage_agriinouts loan_usage_medic loan_usage_assets loan_usage_weeding loan_usage_health loan_usage_funeral loan_usage_business loan_usage_loanrepay loan_usage_edu loan_usage_lottery loan_usage_other 

foreach var in `loanuse' {
	destring `var', replace
	lab val `var' yesno
	replace `var' = .m if loan_yn != 1
	tab `var', m
}

lab var loan_usage_homeimprove "Home improvement including water supply"
lab var loan_usage_homebuy "House purchase or construction"
lab var loan_usage_construct "Construction other than house"
lab var loan_usage_landbuy "Land purchase/rent"
lab var loan_usage_worktools "Purchase of working tools or equipment (including for fishing)"
lab var loan_usage_food "Food purchases"
lab var loan_usage_agriinouts "Purchase of agricultural inputs (fertilizers, seeds, pesticides, labour cost etc.)"
lab var loan_usage_medic "Purchase of animals/medicine for animals"
lab var loan_usage_assets "Purchase of other assets"
lab var loan_usage_weeding "Dowry/Wedding"
lab var loan_usage_health "Health"
lab var loan_usage_funeral "Funeral"
lab var loan_usage_business "Business investment"
lab var loan_usage_loanrepay "Repayment of loans"
lab var loan_usage_edu "School/education fees/costs"
lab var loan_usage_lottery "Lottery/gambling"
lab var loan_usage_other "Other (specify)"

// loan_usage_oth

// loan_main_homeimprove loan_main_homebuy loan_main_construct loan_main_landbuy loan_main_worktools loan_main_food loan_main_agriinouts loan_main_medic loan_main_assets loan_main_weeding loan_main_health loan_main_funeral loan_main_business loan_main_loanrepay loan_main_edu loan_main_lottery
// Same as loan main priority source
// a lot of missing were noticed

local loanusemain homeimprove homebuy construct landbuy worktools food agriinouts medic assets weeding health funeral business loanrepay edu lottery

foreach var in `loanusemain' {
	replace loan_main_`var' = "1" if loan_main_`var' == "First"
	replace loan_main_`var' = "2" if loan_main_`var' == "Second"
	replace loan_main_`var' = "3" if loan_main_`var' == "Third"
	replace loan_main_`var' = "4" if loan_main_`var' == "Not Applicable"
	destring loan_main_`var', replace
	
	lab val loan_main_`var' loanmain
	replace loan_usage_`var' = 1 if loan_main_`var' < 4
	replace loan_main_`var' = .m if mi(loan_main_`var')
	tab loan_main_`var', m
}


// hh_debt_now 
lab def hh_debt_now	1"No debt" 2"Less than Ks 25,000" 3"Ks 25,001 – Ks 50,000" 4"Ks 50,001 – Ks 75,000" ///
					5"Ks 75,001 – Ks 100,000" 6"Ks 100,001 – Ks 150,000" 7"Ks 150,001 – Ks 200,000" ///
					8"Ks 200,001 – Ks 300,000" 9"Ks 300,001 – Ks 400,000" 10"Ks 400,001 – Ks 500,000" ///
					11"Ks 500,001 – Ks 600,000" 12"Ks 600,001 – Ks 700,000" 13"Ks 700,001 – Ks 800,000" ///
					14"Ks 800,001 – Ks 900,000" 15"Ks 900,001 – Ks 1,000,000" 16"Over Ks 1,000,000" ///
					17"Do not know" 18"No answer"
replace hh_debt_now = "1" if hh_debt_now == "No debt"
replace hh_debt_now = "2" if hh_debt_now == "Less than Ks 25,000"
replace hh_debt_now = "3" if hh_debt_now == "Ks 25,001 – Ks 50,000"
replace hh_debt_now = "4" if hh_debt_now == "Ks 50,001 – Ks 75,000"
replace hh_debt_now = "5" if hh_debt_now == "Ks 75,001 – Ks 100,000"
replace hh_debt_now = "6" if hh_debt_now == "Ks 100,001 – Ks 150,000"
replace hh_debt_now = "7" if hh_debt_now == "Ks 150,001 – Ks 200,000"
replace hh_debt_now = "8" if hh_debt_now == "Ks 200,001 – Ks 300,000"
replace hh_debt_now = "9" if hh_debt_now == "Ks 300,001 – Ks 400,000"
replace hh_debt_now = "10" if hh_debt_now == "Ks 400,001 – Ks 500,000"
replace hh_debt_now = "11" if hh_debt_now == "Ks 500,001 – Ks 600,000"
replace hh_debt_now = "12" if hh_debt_now == "Ks 600,001 – Ks 700,000"
replace hh_debt_now = "13" if hh_debt_now == "Ks 700,001 – Ks 800,000"
replace hh_debt_now = "14" if hh_debt_now == "Ks 800,001 – Ks 900,000"
replace hh_debt_now = "15" if hh_debt_now == "Ks 900,001 – Ks 1,000,000"
replace hh_debt_now = "16" if hh_debt_now == "Over Ks 1,000,000"
replace hh_debt_now = "17" if hh_debt_now == "Do not know"
replace hh_debt_now = "18" if hh_debt_now == "No answer"
destring hh_debt_now, replace
replace hh_debt_now = .m if mi(hh_debt_now)
lab val hh_debt_now hh_debt_now
tab hh_debt_now, m

forvalue x = 1/18 {
	gen hh_debt_now_`x' = (hh_debt_now == `x')
	replace hh_debt_now_`x' = .m if mi(hh_debt_now)
	order hh_debt_now_`x', before(hh_debt_lastyr)
	lab val hh_debt_now_`x' yesno
	tab hh_debt_now_`x', m
}

lab var hh_debt_now_1 "No debt"
lab var hh_debt_now_2 "Less than Ks 25,000"
lab var hh_debt_now_3 "Ks 25,001 – Ks 50,000"
lab var hh_debt_now_4 "Ks 50,001 – Ks 75,000"
lab var hh_debt_now_5 "Ks 75,001 – Ks 100,000"
lab var hh_debt_now_6 "Ks 100,001 – Ks 150,000"
lab var hh_debt_now_7 "Ks 150,001 – Ks 200,000"
lab var hh_debt_now_8 "Ks 200,001 – Ks 300,000"
lab var hh_debt_now_9 "Ks 300,001 – Ks 400,000"
lab var hh_debt_now_10 "Ks 400,001 – Ks 500,000"
lab var hh_debt_now_11 "Ks 500,001 – Ks 600,000"
lab var hh_debt_now_12 "Ks 600,001 – Ks 700,000"
lab var hh_debt_now_13 "Ks 700,001 – Ks 800,000"
lab var hh_debt_now_14 "Ks 800,001 – Ks 900,000"
lab var hh_debt_now_15 "Ks 900,001 – Ks 1,000,000"
lab var hh_debt_now_16 "Over Ks 1,000,000"
lab var hh_debt_now_17 "Do not know"
lab var hh_debt_now_18 "No answer"

// hh_debt_lastyr
lab def hh_debt_lastyr 1"Increasing" 2"Staying much the same" 3"Decreasing" 4"No debt now or before" 5"Don’t know" 6"No answer"

replace hh_debt_lastyr = "1" if hh_debt_lastyr == "Increasing"
replace hh_debt_lastyr = "2" if hh_debt_lastyr == "Staying much the same"
replace hh_debt_lastyr = "3" if hh_debt_lastyr == "Decreasing"
replace hh_debt_lastyr = "4" if hh_debt_lastyr == "No debt now or before"
replace hh_debt_lastyr = "5" if hh_debt_lastyr == "Don’t know"
replace hh_debt_lastyr = "6" if hh_debt_lastyr == "No answer"
destring hh_debt_lastyr, replace
replace hh_debt_lastyr = .m if mi(hh_debt_lastyr)
lab val hh_debt_lastyr hh_debt_lastyr
tab hh_debt_lastyr, m

forvalue x = 1/6 {
	gen hh_debt_lastyr_`x' = (hh_debt_lastyr == `x')
	replace hh_debt_lastyr_`x' = .m if mi(hh_debt_lastyr)
	order hh_debt_lastyr_`x', before(hh_bankacc_num)
	lab val hh_debt_lastyr_`x' yesno
	tab hh_debt_lastyr_`x', m
}

lab var hh_debt_lastyr_1 "Increasing"
lab var hh_debt_lastyr_2 "Staying much the same"
lab var hh_debt_lastyr_3 "Decreasing"
lab var hh_debt_lastyr_4 "No debt now or before"
lab var hh_debt_lastyr_5 "Don’t know"
lab var hh_debt_lastyr_6 "No answer"


global loan	loan_yn ///
			loan_source_bank loan_source_mfi loan_source_vsla loan_source_family loan_source_mlender loan_source_shop ///
			loan_source_company loan_source_religious loan_source_seller loan_source_gov loan_source_other ///
			loan_usage_homeimprove loan_usage_homebuy loan_usage_construct loan_usage_landbuy loan_usage_worktools ///
			loan_usage_food loan_usage_agriinouts loan_usage_medic loan_usage_assets loan_usage_weeding loan_usage_health ///
			loan_usage_funeral loan_usage_business loan_usage_loanrepay loan_usage_edu loan_usage_lottery loan_usage_other ///
			hh_debt_now_1 hh_debt_now_2 hh_debt_now_3 hh_debt_now_4 hh_debt_now_5 hh_debt_now_6 hh_debt_now_7 ///
			hh_debt_now_8 hh_debt_now_9 hh_debt_now_10 hh_debt_now_11 hh_debt_now_12 hh_debt_now_13 hh_debt_now_14 ///
			hh_debt_now_15 hh_debt_now_16 hh_debt_now_17 hh_debt_now_18 ///
			hh_debt_lastyr_1 hh_debt_lastyr_2 hh_debt_lastyr_3 hh_debt_lastyr_4 hh_debt_lastyr_5 hh_debt_lastyr_6

// SAVING //
// hh_bankacc_num 
destring hh_bankacc_num, replace
replace hh_bankacc_num = .m if mi(hh_bankacc_num)
lab var hh_bankacc_num "Number of HH members with Bank account"
tab hh_bankacc_num, m

gen hh_bankacc_num_yn = (hh_bankacc_num > 0 & !mi(hh_bankacc_num))
replace hh_bankacc_num_yn = .m if mi(hh_bankacc_num)
lab var hh_bankacc_num_yn "HH members with Bank account"
lab val hh_bankacc_num_yn yesno
order hh_bankacc_num_yn, after(hh_bankacc_num)
tab hh_bankacc_num_yn, m

// hh_vsla_mem_num
destring hh_vsla_mem_num, replace
replace hh_vsla_mem_num = .m if mi(hh_vsla_mem_num)
lab var hh_vsla_mem_num "Number of HH members joined at voluntary savings group"
tab hh_vsla_mem_num, m

gen hh_vsla_mem_num_yn = (hh_vsla_mem_num > 0 & !mi(hh_vsla_mem_num))
replace hh_vsla_mem_num_yn = .m if mi(hh_vsla_mem_num)
lab var hh_vsla_mem_num_yn "HH members joined at voluntary savings group"
lab val hh_vsla_mem_num_yn yesno
order hh_vsla_mem_num_yn, after(hh_vsla_mem_num)
tab hh_vsla_mem_num_yn, m


// hh_save_yn 
replace hh_save_yn = "1" if hh_save_yn == "Yes"
replace hh_save_yn = "0" if hh_save_yn == "No"
destring hh_save_yn, replace
replace hh_save_yn = .m if mi(hh_save_yn)
lab val hh_save_yn yesno
tab hh_save_yn, m

// hh_saveplace 
tab hh_saveplace, m

// hh_saveplace_bank hh_saveplace_mfi hh_saveplace_vsla hh_saveplace_family hh_saveplace_home hh_saveplace_religious hh_saveplace_gov hh_saveplace_gold hh_saveplace_other hh_saveplace_dk hh_saveplace_noans 
local saveplce hh_saveplace_bank hh_saveplace_mfi hh_saveplace_vsla hh_saveplace_family hh_saveplace_home hh_saveplace_religious hh_saveplace_gov hh_saveplace_gold hh_saveplace_other hh_saveplace_dk hh_saveplace_noans 

foreach var in `saveplce' {
	destring `var', replace
	replace `var' = .m if hh_save_yn != 1
	lab val `var' yesno
	tab `var', m
}

lab var hh_saveplace_bank "Private bank"
lab var hh_saveplace_mfi "Micro-finance institution (MFI)"
lab var hh_saveplace_vsla "Voluntary savings group"
lab var hh_saveplace_family "Family or friend"
lab var hh_saveplace_home "At home"
lab var hh_saveplace_religious "Temple"
lab var hh_saveplace_gov "Government"
lab var hh_saveplace_gold "Bought gold"
lab var hh_saveplace_other "Other (specify)"
lab var hh_saveplace_dk "Don’t know"
lab var hh_saveplace_noans "No answer"

// hh_saveplace_oth

// hh_savemain_bank hh_savemain_mfi hh_savemain_vsla hh_savemain_family hh_savemain_home hh_savemain_religious hh_savemain_gov hh_savemain_gold hh_savemain_other

local savemain bank mfi vsla family home religious gov gold other	

foreach var in `savemain' {
	replace hh_savemain_`var' = "1" if hh_savemain_`var' == "First"
	replace hh_savemain_`var' = "2" if hh_savemain_`var' == "Second"
	replace hh_savemain_`var' = "3" if hh_savemain_`var' == "Third"
	replace hh_savemain_`var' = "4" if hh_savemain_`var' == "Not Applicable"
	destring hh_savemain_`var', replace
	
	lab val hh_savemain_`var' loanmain
	replace hh_saveplace_`var' = 1 if hh_savemain_`var' < 4
	replace hh_savemain_`var' = .m if mi(hh_savemain_`var')
	tab hh_savemain_`var', m
}

lab var hh_savemain_bank "Private bank"
lab var hh_savemain_mfi "Micro-finance institution (MFI)"
lab var hh_savemain_vsla "Voluntary savings group"
lab var hh_savemain_family "Family or friend"
lab var hh_savemain_home "At home"
lab var hh_savemain_religious "Temple"
lab var hh_savemain_gov "Government"
lab var hh_savemain_gold "Bought gold"
lab var hh_savemain_other "Other (specify)"
 
 
// hh_save_now 
lab def hh_save_now	1"No savings" 2"Less than Ks 25,000" 3"Ks 25,001 – Ks 50,000" 4"Ks 50,001 – Ks 75,000" ///
					5"Ks 75,001 – Ks 100,000" 6"Ks 100,001 – Ks 150,000" 7"Ks 150,001 – Ks 200,000" ///
					8"Ks 200,001 – Ks 300,000" 9"Ks 300,001 – Ks 400,000" 10"Ks 400,001 – Ks 500,000" ///
					11"Ks 500,001 – Ks 600,000" 12"Ks 600,001 – Ks 700,000" 13"Ks 700,001 – Ks 800,000" ///
					14"Ks 800,001 – Ks 900,000" 15"Ks 900,001 – Ks 1,000,000" 16"Over Ks 1,000,000" ///
					17"Do not know" 18"No answer"

replace hh_save_now = "1" if hh_save_now == "No savings"
replace hh_save_now = "2" if hh_save_now == "Less than Ks 25,000"
replace hh_save_now = "3" if hh_save_now == "Ks 25,001 – Ks 50,000"
replace hh_save_now = "4" if hh_save_now == "Ks 50,001 – Ks 75,000"
replace hh_save_now = "5" if hh_save_now == "Ks 75,001 – Ks 100,000"
replace hh_save_now = "6" if hh_save_now == "Ks 100,001 – Ks 150,000"
replace hh_save_now = "7" if hh_save_now == "Ks 150,001 – Ks 200,000"
replace hh_save_now = "8" if hh_save_now == "Ks 200,001 – Ks 300,000"
replace hh_save_now = "9" if hh_save_now == "Ks 300,001 – Ks 400,000"
replace hh_save_now = "10" if hh_save_now == "Ks 400,001 – Ks 500,000"
replace hh_save_now = "11" if hh_save_now == "Ks 500,001 – Ks 600,000"
replace hh_save_now = "12" if hh_save_now == "Ks 600,001 – Ks 700,000"
replace hh_save_now = "13" if hh_save_now == "Ks 700,001 – Ks 800,000"
replace hh_save_now = "14" if hh_save_now == "Ks 800,001 – Ks 900,000"
replace hh_save_now = "15" if hh_save_now == "Ks 900,001 – Ks 1,000,000"
replace hh_save_now = "16" if hh_save_now == "Over Ks 1,000,000"
replace hh_save_now = "17" if hh_save_now == "Do not know"
replace hh_save_now = "18" if hh_save_now == "No answer"

destring hh_save_now, replace
replace hh_save_now = .m if mi(hh_save_now)
lab val hh_save_now hh_save_now
tab hh_save_now, m

forvalue x = 1/18 {
	gen hh_save_now_`x' = (hh_save_now == `x')
	replace hh_save_now_`x' = .m if mi(hh_save_now)
	order hh_save_now_`x', before(hh_save_lastyr)
	lab val hh_save_now_`x' yesno
	tab hh_save_now_`x', m
}

lab var hh_save_now_1 "No savings"
lab var hh_save_now_2 "Less than Ks 25,000"
lab var hh_save_now_3 "Ks 25,001 – Ks 50,000"
lab var hh_save_now_4 "Ks 50,001 – Ks 75,000"
lab var hh_save_now_5 "Ks 75,001 – Ks 100,000"
lab var hh_save_now_6 "Ks 100,001 – Ks 150,000"
lab var hh_save_now_7 "Ks 150,001 – Ks 200,000"
lab var hh_save_now_8 "Ks 200,001 – Ks 300,000"
lab var hh_save_now_9 "Ks 300,001 – Ks 400,000"
lab var hh_save_now_10 "Ks 400,001 – Ks 500,000"
lab var hh_save_now_11 "Ks 500,001 – Ks 600,000"
lab var hh_save_now_12 "Ks 600,001 – Ks 700,000"
lab var hh_save_now_13 "Ks 700,001 – Ks 800,000"
lab var hh_save_now_14 "Ks 800,001 – Ks 900,000"
lab var hh_save_now_15 "Ks 900,001 – Ks 1,000,000"
lab var hh_save_now_16 "Over Ks 1,000,000"
lab var hh_save_now_17 "Do not know"
lab var hh_save_now_18 "No answer"


// hh_save_lastyr
lab def hh_save_lastyr 1"Increasing" 2"Staying much the same" 3"Decreasing" 4"Don’t have စုထားတာ မရွိပါ။" 5"No answer" 6"Don’t know"

replace hh_save_lastyr = "1" if hh_save_lastyr == "Increasing"
replace hh_save_lastyr = "2" if hh_save_lastyr == "Staying much the same"
replace hh_save_lastyr = "3" if hh_save_lastyr == "Decreasing"
replace hh_save_lastyr = "4" if hh_save_lastyr == "Don’t have စုထားတာ မရွိပါ။"
replace hh_save_lastyr = "5" if hh_save_lastyr == "No answer"
replace hh_save_lastyr = "6" if hh_save_lastyr == "Don’t know"


destring hh_save_lastyr, replace
replace hh_save_lastyr = .m if mi(hh_save_lastyr)
lab val hh_save_lastyr hh_save_lastyr
tab hh_save_lastyr, m

forvalue x = 1/6 {
	gen hh_save_lastyr_`x' = (hh_save_lastyr == `x')
	replace hh_save_lastyr_`x' = .m if mi(hh_save_lastyr)
	order hh_save_lastyr_`x', before(fliteracy_practices)
	lab val hh_save_lastyr_`x' yesno
	tab hh_save_lastyr_`x', m
}

lab var hh_save_lastyr_1 "Increasing"
lab var hh_save_lastyr_2 "Staying much the same"
lab var hh_save_lastyr_3 "Decreasing"
lab var hh_save_lastyr_4 "Don’t have any saving amount"
lab var hh_save_lastyr_5 "No answer"
lab var hh_save_lastyr_6 "Don’t know"


global save		hh_bankacc_num_yn hh_bankacc_num hh_vsla_mem_num_yn hh_vsla_mem_num hh_save_yn ///
				hh_saveplace_bank hh_saveplace_mfi hh_saveplace_vsla hh_saveplace_family hh_saveplace_home ///
				hh_saveplace_religious hh_saveplace_gov hh_saveplace_gold hh_saveplace_other hh_saveplace_dk hh_saveplace_noans ///
				hh_save_now_1 hh_save_now_2 hh_save_now_3 hh_save_now_4 hh_save_now_5 hh_save_now_6 hh_save_now_7 ///
				hh_save_now_8 hh_save_now_9 hh_save_now_10 hh_save_now_11 hh_save_now_12 hh_save_now_13 hh_save_now_14 ///
				hh_save_now_15 hh_save_now_16 hh_save_now_17 hh_save_now_18 ///
				hh_save_lastyr_1 hh_save_lastyr_2 hh_save_lastyr_3 hh_save_lastyr_4 hh_save_lastyr_5 hh_save_lastyr_6
				

// financial literacy practices 

// fliteracy_practices 
tab fliteracy_practices, m

// fliteracy_income fliteracy_expense fliteracy_loan fliteracy_calinterest fliteracy_borrwloan fliteracy_save fliteracy_expenseplan fliteracy_dk fliteracy_no
local flpract fliteracy_income fliteracy_expense fliteracy_loan fliteracy_calinterest fliteracy_borrwloan fliteracy_save fliteracy_expenseplan fliteracy_dk fliteracy_no

foreach var in `flpract' {
	destring `var', replace
	lab val `var' yesno
	replace `var' = .m if mi(fliteracy_practices)
	replace `var' = .n if mi(`var')
	tab `var', m
}

lab var fliteracy_income "Recorded incomes somewhere"
lab var fliteracy_expense "Recorded expenditures somewhere"
lab var fliteracy_loan "Recorded loan information somewhere"
lab var fliteracy_calinterest "Calculated interest rates for loans and kept track of when it can be paid back"
lab var fliteracy_borrwloan "Borrowed money to reimburse a loan"
lab var fliteracy_save "Recorded savings"
lab var fliteracy_expenseplan "Recorded saving objectives or expenditures plan"
lab var fliteracy_dk "Don’t know / do not want to answer"
lab var fliteracy_no "Don't Have any records"


// fliteracy_main_income fliteracy_main_expense fliteracy_main_loan fliteracy_main_calinterest fliteracy_main_borrwloan fliteracy_main_save fliteracy_main_expenseplan 
// Same as above loan and saving main places, a lot missing variable were detected
// and xls form did not applied the required field 

local flmain income expense loan calinterest borrwloan save expenseplan

foreach var in `flmain' {
	replace fliteracy_main_`var' = "1" if fliteracy_main_`var' == "First"
	replace fliteracy_main_`var' = "2" if fliteracy_main_`var' == "Second"
	replace fliteracy_main_`var' = "3" if fliteracy_main_`var' == "Third"
	replace fliteracy_main_`var' = "4" if fliteracy_main_`var' == "Not Applicable"
	destring fliteracy_main_`var', replace
	
	lab val fliteracy_main_`var' loanmain
	replace fliteracy_`var' = 1 if fliteracy_main_`var' < 4
	replace fliteracy_main_`var' = .m if mi(fliteracy_main_`var')
	tab fliteracy_main_`var', m
}

lab var fliteracy_main_income "Recorded incomes somewhere"
lab var fliteracy_main_expense "Recorded expenditures somewhere"
lab var fliteracy_main_loan "Recorded loan information somewhere"
lab var fliteracy_main_calinterest "Calculated interest rates for loans and kept track of when it can be paid back"
lab var fliteracy_main_borrwloan "Borrowed money to reimburse a loan"
lab var fliteracy_main_save "Recorded savings"
lab var fliteracy_main_expenseplan "Recorded saving objectives or expenditures plan"


// fliteracy_incharge
lab def fliteracy_incharge 1"Adult male" 2"Adult female" 3"Both adult male and female" 4"Boy" 5"Girl" 6"Boys and girls"
replace fliteracy_incharge = "1" if fliteracy_incharge == "Adult male"
replace fliteracy_incharge = "2" if fliteracy_incharge == "Adult female"
replace fliteracy_incharge = "3" if fliteracy_incharge == "Both adult male and female"
replace fliteracy_incharge = "4" if fliteracy_incharge == "Boy"
replace fliteracy_incharge = "5" if fliteracy_incharge == "Girl"
replace fliteracy_incharge = "6" if fliteracy_incharge == "Boys and girls"
destring fliteracy_incharge, replace
lab val fliteracy_incharge fliteracy_incharge
replace fliteracy_incharge = .m if fliteracy_dk == 1
tab fliteracy_incharge, m

forvalue x = 1/6 {
	gen fliteracy_incharge_`x' = (fliteracy_incharge == `x')
	replace fliteracy_incharge_`x' = .m if mi(fliteracy_incharge)
	order fliteracy_incharge_`x', before(financial_women_part)
	tab fliteracy_incharge_`x', m
}

lab var fliteracy_incharge_1 "Adult male"
lab var fliteracy_incharge_2 "Adult female"
lab var fliteracy_incharge_3 "Both adult male and female"
lab var fliteracy_incharge_4 "Boy"
lab var fliteracy_incharge_5 "Girl"
lab var fliteracy_incharge_6 "Boys and girls"


** women participation in financial related matter **
// financial_women_part 
lab def financial_women_part 1"Never" 2"Rarely or sometimes" 3"Often"
replace financial_women_part = "1" if financial_women_part == "Never"
replace financial_women_part = "2" if financial_women_part == "Rarely or sometimes"
replace financial_women_part = "3" if financial_women_part == "Often"
destring financial_women_part, replace
lab val financial_women_part financial_women_part
replace financial_women_part = .m if mi(financial_women_part)
tab financial_women_part, m

forvalue x = 1/3 {
	gen financial_women_part_`x' = (financial_women_part == `x')
	replace financial_women_part_`x' = .m if mi(financial_women_part)
	order financial_women_part_`x', before(financial_women_type)
	tab financial_women_part_`x', m
}

lab var financial_women_part_1 "Never"
lab var financial_women_part_2 "Rarely or sometimes"
lab var financial_women_part_3 "Often"

// financial_women_type 
tab financial_women_type, m

// financial_women_short financial_women_long financial_women_overall financial_women_other 
local womenpart financial_women_short financial_women_long financial_women_overall financial_women_other 
foreach var in `womenpart' {
	destring `var', replace
	lab val `var' yesno
	replace `var' = .m if financial_women_part == 1
	tab `var', m
}

lab var financial_women_short "Short-term income and expenditure"
lab var financial_women_long "Long-term investments"
lab var financial_women_overall "Overall wellbeing of the household"
lab var financial_women_other "Other decisions"

// financial_women_oth

// last year evaluation //
// wealth_lastyr_cond 
lab def wealth_lastyr_cond 1"Increasing" 2"Staying much the same" 3"Decreasing" 4"Don’t know" 5"No answer"
replace wealth_lastyr_cond = "1" if wealth_lastyr_cond == "Increasing"
replace wealth_lastyr_cond = "2" if wealth_lastyr_cond == "Staying much the same"
replace wealth_lastyr_cond = "3" if wealth_lastyr_cond == "Decreasing"
replace wealth_lastyr_cond = "4" if wealth_lastyr_cond == "Don’t know"
replace wealth_lastyr_cond = "5" if wealth_lastyr_cond == "No answer"
destring wealth_lastyr_cond, replace
lab val wealth_lastyr_cond wealth_lastyr_cond
replace wealth_lastyr_cond = .n if mi(wealth_lastyr_cond)
tab wealth_lastyr_cond, m

forvalue x =  1/5 {
	gen wealth_lastyr_cond_`x' = (wealth_lastyr_cond == `x')
	replace wealth_lastyr_cond_`x' = .m if mi(wealth_lastyr_cond)
	order wealth_lastyr_cond_`x', before(hhmem_svy)
	tab wealth_lastyr_cond_`x', m
}

lab var wealth_lastyr_cond_1 "Increasing"
lab var wealth_lastyr_cond_2 "Staying much the same"
lab var wealth_lastyr_cond_3 "Decreasing"
lab var wealth_lastyr_cond_4 "Don’t know"
lab var wealth_lastyr_cond_5 "No answer"


global flitracy	 	fliteracy_income fliteracy_expense fliteracy_loan fliteracy_calinterest fliteracy_borrwloan fliteracy_save fliteracy_expenseplan fliteracy_dk fliteracy_no ///
					fliteracy_incharge_1 fliteracy_incharge_2 fliteracy_incharge_3 fliteracy_incharge_4 fliteracy_incharge_5 fliteracy_incharge_6 ///
					financial_women_part_1 financial_women_part_2 financial_women_part_3 financial_women_short financial_women_long financial_women_overall financial_women_other ///
					wealth_lastyr_cond_1 wealth_lastyr_cond_2 wealth_lastyr_cond_3 wealth_lastyr_cond_4 wealth_lastyr_cond_5


// hhmem_svy 
tab hhmem_svy, m

// hhmem_svy_boy hhmem_svy_girl hhmem_svy_men hhmem_svy_women
local svymem hhmem_svy_boy hhmem_svy_girl hhmem_svy_men hhmem_svy_women

foreach var in `svymem' {
	destring `var', replace
	replace `var' = .m if mi(hhmem_svy)
	lab val `var' yesno
	tab `var', m
}

lab var hhmem_svy_boy "Boys ( <24 yrs )"
lab var hhmem_svy_girl "Girls ( <24 yrs )"
lab var hhmem_svy_men "Men ( >25 yrs )"
lab var hhmem_svy_women "Women ( > 25 yrs )"


// boy_incomegen girl_incomegen men_incomegen women_incomegen
// boy_incomegen_obst girl_incomegen_obst men_incomegen_obst women_incomegen_obst

local person boy girl men women
foreach var in `person' {
	replace `var'_incomegen = "0" if `var'_incomegen == "No"
	replace `var'_incomegen = "1" if `var'_incomegen == "Yes"
	destring `var'_incomegen, replace
	replace `var'_incomegen = .m if hhmem_svy_`var' != 1
	lab val `var'_incomegen yesno
	tab `var'_incomegen, m
	
	replace `var'_incomegen_obst  = "0" if `var'_incomegen_obst  == "No"
	replace `var'_incomegen_obst  = "1" if `var'_incomegen_obst  == "Yes"
	destring `var'_incomegen_obst , replace
	replace `var'_incomegen_obst  = .m if hhmem_svy_`var' != 1
	lab val `var'_incomegen_obst  yesno
	tab `var'_incomegen_obst , m
	
	destring `var'_incomegen_obst_skills, replace
	destring `var'_incomegen_obst_capital, replace
	destring `var'_incomegen_obst_network, replace
	destring `var'_incomegen_obst_confid, replace
	destring `var'_incomegen_obst_safe, replace
	destring `var'_incomegen_obst_busy, replace
	destring `var'_incomegen_obst_chores, replace
	destring `var'_incomegen_obst_parent, replace
	
	lab val `var'_incomegen_obst_skills yesno
	lab val `var'_incomegen_obst_capital yesno
	lab val `var'_incomegen_obst_network yesno
	lab val `var'_incomegen_obst_confid yesno
	lab val `var'_incomegen_obst_safe yesno
	lab val `var'_incomegen_obst_busy yesno
	lab val `var'_incomegen_obst_chores yesno
	lab val `var'_incomegen_obst_parent yesno
	
	replace `var'_incomegen_obst_skills = .m if mi(`var'_incomegen_obst_type)
	replace `var'_incomegen_obst_capital = .m if mi(`var'_incomegen_obst_type)
	replace `var'_incomegen_obst_network = .m if mi(`var'_incomegen_obst_type)
	replace `var'_incomegen_obst_confid = .m if mi(`var'_incomegen_obst_type)
	replace `var'_incomegen_obst_safe = .m if mi(`var'_incomegen_obst_type)
	replace `var'_incomegen_obst_busy = .m if mi(`var'_incomegen_obst_type)
	replace `var'_incomegen_obst_chores = .m if mi(`var'_incomegen_obst_type)
	replace `var'_incomegen_obst_parent = .m if mi(`var'_incomegen_obst_type)
	
	lab var  `var'_incomegen_obst_skills "Lack of technical skills"
	lab var  `var'_incomegen_obst_capital "Lack of financial capital to invest"
	lab var  `var'_incomegen_obst_network "Lack of networking/ does not know the people to connect with/contact"
	lab var  `var'_incomegen_obst_confid "Lack of confidence"
	lab var  `var'_incomegen_obst_safe "Security to or at work place"
	lab var  `var'_incomegen_obst_busy "Too busy with current jobs/activity"
	lab var  `var'_incomegen_obst_chores "Too busy with HH chores"
	lab var  `var'_incomegen_obst_parent "Parents/adults do not want me to do this activity"
	
	tab `var'_incomegen_obst_skills, m
	tab `var'_incomegen_obst_capital, m
	tab `var'_incomegen_obst_network, m
	tab `var'_incomegen_obst_confid, m
	tab `var'_incomegen_obst_safe, m
	tab `var'_incomegen_obst_busy, m
	tab `var'_incomegen_obst_chores, m
	tab `var'_incomegen_obst_parent, m
}


// boy_incomegen_obst_type
tab boy_incomegen_obst_type, m

// boy_incomegen_obst_skills boy_incomegen_obst_capital boy_incomegen_obst_network boy_incomegen_obst_confid boy_incomegen_obst_safe boy_incomegen_obst_busy boy_incomegen_obst_chores boy_incomegen_obst_parent

// girl_incomegen_obst_type
tab girl_incomegen_obst_type, m
 
// girl_incomegen_obst_skills girl_incomegen_obst_capital girl_incomegen_obst_network girl_incomegen_obst_confid girl_incomegen_obst_safe girl_incomegen_obst_busy girl_incomegen_obst_chores girl_incomegen_obst_parent

// men_incomegen_obst_type
tab men_incomegen_obst_type, m 
// men_incomegen_obst_skills men_incomegen_obst_capital men_incomegen_obst_network men_incomegen_obst_confid men_incomegen_obst_safe men_incomegen_obst_busy men_incomegen_obst_chores men_incomegen_obst_parent

// women_incomegen_obst_type
tab women_incomegen_obst_type, m 
// women_incomegen_obst_skills women_incomegen_obst_capital women_incomegen_obst_network women_incomegen_obst_confid women_incomegen_obst_safe women_incomegen_obst_busy women_incomegen_obst_chores women_incomegen_obst_parent


// boy_incomegen_oth 
tab boy_incomegen_oth, m

// girl_incomegen_oth
tab girl_incomegen_oth, m

// men_incomegen_oth
tab men_incomegen_oth, m

// women_incomegen_oth 
tab women_incomegen_oth, m

lab def work	1"Agricultural work" 2"Causal Labour (carpenter, trishaw cycle driver, cycle carriers)" ///
				3"Embankment (building, buying, rental)" 4"Fishery" 5"Husbandry (cow, chicken, pig etc)" ///
				6"Own business (tailor, mechanic, handicraft)" 7"Shop (betel nut)" 8"Shop (charcoal)" ///
				9"Shop (cloths)" 10"Shop (construction)" 11"Shop (general)" 12"Shop (pharmacy shop)" ///
				13"Shop (pharmacy)" 14"Shop (restaurant)" 15"Shop (rice)" 16"Shop (snack)" ///
				17"Shop (tailor)" 18"Shop (tea shop)" 19"Shop (vegetable)" 20"Staff (Public or Private)" ///
				21"To extend current business" 22"Trading (cloths, fish, boat, wood)" 23"Want back to school" ///
				24"Work at abroad"

local incomegen boy_incomegen_oth girl_incomegen_oth men_incomegen_oth women_incomegen_oth

foreach var in `incomegen' {
	replace `var'  = "1" if `var' == "Agricultural work"
	replace `var'  = "20" if `var' == "any kind of permanent work"
	replace `var'  = "2" if `var' == "carpenter"
	replace `var'  = "2" if `var' == "causal labour"
	replace `var'  = "3" if `var' == "embankment building"
	replace `var'  = "3" if `var' == "embankment buying"
	replace `var'  = "3" if `var' == "embankment hiring"
	replace `var'  = "4" if `var' == "Fishery"
	replace `var'  = "20" if `var' == "Government staff"
	replace `var'  = "6" if `var' == "handicraft (bamboo products)"
	replace `var'  = "6" if `var' == "handicraft (not specify)"
	replace `var'  = "5" if `var' == "husbandry work"
	replace `var'  = "5" if `var' == "husbendary work"
	replace `var'  = "6" if `var' == "mechanic"
	replace `var'  = "6" if `var' == "moneylander"
	replace `var'  = "6" if `var' == "moneylender"
	replace `var'  = "20" if `var' == "NGO worker"
	replace `var'  = "0" if `var' == "No"
	replace `var'  = "0" if `var' == "not decided yet"
	replace `var'  = "11" if `var' == "open a shop"
	replace `var'  = "7" if `var' == "open a shop (betel nut shop)"
	replace `var'  = "7" if `var' == "open a shop (betel nut)"
	replace `var'  = "8" if `var' == "open a shop (charcoal)"
	replace `var'  = "9" if `var' == "open a shop (cloths)"
	replace `var'  = "10" if `var' == "open a shop (construction)"
	replace `var'  = "12" if `var' == "open a shop (pharmacy shop)"
	replace `var'  = "13" if `var' == "open a shop (pharmacy)"
	replace `var'  = "14" if `var' == "open a shop (restaurant)"
	replace `var'  = "15" if `var' == "open a shop (rice)"
	replace `var'  = "16" if `var' == "open a shop (snack)"
	replace `var'  = "17" if `var' == "open a shop (tailor)"
	replace `var'  = "18" if `var' == "open a shop (tea shop)"
	replace `var'  = "19" if `var' == "open a shop (vegetable)"
	replace `var'  = "6" if `var' == "own business (not specifiy)"
	replace `var'  = "6" if `var' == "own business (not specify)"
	replace `var'  = "20" if `var' == "school teacher"
	replace `var'  = "20" if `var' == "staff (not specify)"
	replace `var'  = "6" if `var' == "tailor"
	replace `var'  = "21" if `var' == "to extend current business"
	replace `var'  = "24" if `var' == "to work in abroad"
	replace `var'  = "22" if `var' == "trader"
	replace `var'  = "22" if `var' == "trader (boat)"
	replace `var'  = "22" if `var' == "trader (cloths)"
	replace `var'  = "22" if `var' == "trader (fish)"
	replace `var'  = "22" if `var' == "trader (fish) "
	replace `var'  = "22" if `var' == "trader (wood)"
	replace `var'  = "6" if `var' == "traditional medicine practitioner"
	replace `var'  = "22" if `var' == "travelling"
	replace `var'  = "2" if `var' == "trishaw cycle driver"
	replace `var'  = "2" if `var' == "want a cycle"
	replace `var'  = "23" if `var' == "want back to school"
	replace `var'  = "24" if `var' == "want to work at abroad"
	replace `var'  = "2" if `var' == "work as cycle carrier"
	
	destring `var', replace
	lab val `var' work
	tab `var', m
}

// boy_incomegen girl_incomegen men_incomegen women_incomegen

replace boy_incomegen = 0 if boy_incomegen_oth == 0
replace boy_incomegen_oth = .m if boy_incomegen_oth == 0

replace girl_incomegen = 0 if girl_incomegen_oth == 0
replace girl_incomegen_oth = .m if girl_incomegen_oth == 0

replace men_incomegen = 0 if men_incomegen_oth == 0
replace men_incomegen_oth = .m if men_incomegen_oth == 0

replace women_incomegen = 0 if women_incomegen_oth == 0
replace women_incomegen_oth = .m if women_incomegen_oth == 0


forvalue x = 1/24 {
	gen boy_incomegen_oth_`x' = (boy_incomegen_oth == `x')
	replace boy_incomegen_oth_`x' = .m if mi(boy_incomegen_oth)
	order boy_incomegen_oth_`x', before(girl_incomegen)
	tab boy_incomegen_oth_`x', m
}

forvalue x = 1/24 {
	gen girl_incomegen_oth_`x' = (girl_incomegen_oth == `x')
	replace girl_incomegen_oth_`x' = .m if mi(girl_incomegen_oth)
	order girl_incomegen_oth_`x', before(men_incomegen)
	tab girl_incomegen_oth_`x', m
}

forvalue x = 1/24 {
	gen men_incomegen_oth_`x' = (men_incomegen_oth == `x')
	replace men_incomegen_oth_`x' = .m if mi(men_incomegen_oth)
	order men_incomegen_oth_`x', before(women_incomegen)
	tab men_incomegen_oth_`x', m
}

forvalue x = 1/24 {
	gen women_incomegen_oth_`x' = (women_incomegen_oth == `x')
	replace women_incomegen_oth_`x' = .m if mi(women_incomegen_oth)
	order women_incomegen_oth_`x', before(__version__)
	tab women_incomegen_oth_`x', m
}


local incomegen boy_incomegen_oth girl_incomegen_oth men_incomegen_oth women_incomegen_oth
foreach var in `incomegen' {
	forvalue x = 1/24 {
		lab var `var'_1 "Agricultural work"
		lab var `var'_2"Causal Labour (carpenter, trishaw cycle driver, cycle carriers)"
		lab var `var'_3"Embankment (building, buying, rental)"
		lab var `var'_4"Fishery"
		lab var `var'_5"Husbandry (cow, chicken, pig etc)"
		lab var `var'_6"Own business (tailor, mechanic, handicraft)"
		lab var `var'_7"Shop (betel nut)"
		lab var `var'_8"Shop (charcoal)"
		lab var `var'_9"Shop (cloths)"
		lab var `var'_10"Shop (construction)"
		lab var `var'_11"Shop (general)"
		lab var `var'_12"Shop (pharmacy shop)"
		lab var `var'_13"Shop (pharmacy)"
		lab var `var'_14"Shop (restaurant)"
		lab var `var'_15"Shop (rice)"
		lab var `var'_16"Shop (snack)"
		lab var `var'_17"Shop (tailor)"
		lab var `var'_18"Shop (tea shop)"
		lab var `var'_19"Shop (vegetable)"
		lab var `var'_20"Staff (Public or Private)"
		lab var `var'_21"To extend current business"
		lab var `var'_22"Trading (cloths, fish, boat, wood)"
		lab var `var'_23"Want back to school"
		lab var `var'_24"Work at abroad"
	}
}


global boysvy	hhmem_svy_boy boy_incomegen ///
				boy_incomegen_oth_1 boy_incomegen_oth_2 boy_incomegen_oth_3 boy_incomegen_oth_4 boy_incomegen_oth_5 ///
				boy_incomegen_oth_6 boy_incomegen_oth_7 boy_incomegen_oth_8 boy_incomegen_oth_9 boy_incomegen_oth_10 ///
				boy_incomegen_oth_11 boy_incomegen_oth_12 boy_incomegen_oth_13 boy_incomegen_oth_14 boy_incomegen_oth_15 ///
				boy_incomegen_oth_16 boy_incomegen_oth_17 boy_incomegen_oth_18 boy_incomegen_oth_19 boy_incomegen_oth_20 ///
				boy_incomegen_oth_21 boy_incomegen_oth_22 boy_incomegen_oth_23 boy_incomegen_oth_24 ///
				boy_incomegen_obst ///
				boy_incomegen_obst_skills boy_incomegen_obst_capital boy_incomegen_obst_network boy_incomegen_obst_confid ///
				boy_incomegen_obst_safe boy_incomegen_obst_busy boy_incomegen_obst_chores boy_incomegen_obst_parent

global girlsvy	hhmem_svy_girl girl_incomegen ///
				girl_incomegen_oth_1 girl_incomegen_oth_2 girl_incomegen_oth_3 girl_incomegen_oth_4 girl_incomegen_oth_5 ///
				girl_incomegen_oth_6 girl_incomegen_oth_7 girl_incomegen_oth_8 girl_incomegen_oth_9 girl_incomegen_oth_10 ///
				girl_incomegen_oth_11 girl_incomegen_oth_12 girl_incomegen_oth_13 girl_incomegen_oth_14 girl_incomegen_oth_15 ///
				girl_incomegen_oth_16 girl_incomegen_oth_17 girl_incomegen_oth_18 girl_incomegen_oth_19 girl_incomegen_oth_20 ///
				girl_incomegen_oth_21 girl_incomegen_oth_22 girl_incomegen_oth_23 girl_incomegen_oth_24 ///
				girl_incomegen_obst ///
				girl_incomegen_obst_skills girl_incomegen_obst_capital girl_incomegen_obst_network girl_incomegen_obst_confid ///
				girl_incomegen_obst_safe girl_incomegen_obst_busy girl_incomegen_obst_chores girl_incomegen_obst_parent

global mensvy	hhmem_svy_men men_incomegen ///
				men_incomegen_oth_1 men_incomegen_oth_2 men_incomegen_oth_3 men_incomegen_oth_4 men_incomegen_oth_5 ///
				men_incomegen_oth_6 men_incomegen_oth_7 men_incomegen_oth_8 men_incomegen_oth_9 men_incomegen_oth_10 ///
				men_incomegen_oth_11 men_incomegen_oth_12 men_incomegen_oth_13 men_incomegen_oth_14 men_incomegen_oth_15 ///
				men_incomegen_oth_16 men_incomegen_oth_17 men_incomegen_oth_18 men_incomegen_oth_19 men_incomegen_oth_20 ///
				men_incomegen_oth_21 men_incomegen_oth_22 men_incomegen_oth_23 men_incomegen_oth_24 ///
				men_incomegen_obst ///
				men_incomegen_obst_skills men_incomegen_obst_capital men_incomegen_obst_network men_incomegen_obst_confid ///
				men_incomegen_obst_safe men_incomegen_obst_busy men_incomegen_obst_chores men_incomegen_obst_parent

global womensvy	hhmem_svy_women women_incomegen ///
				women_incomegen_oth_1 women_incomegen_oth_2 women_incomegen_oth_3 women_incomegen_oth_4 women_incomegen_oth_5 ///
				women_incomegen_oth_6 women_incomegen_oth_7 women_incomegen_oth_8 women_incomegen_oth_9 women_incomegen_oth_10 ///
				women_incomegen_oth_11 women_incomegen_oth_12 women_incomegen_oth_13 women_incomegen_oth_14 women_incomegen_oth_15 ///
				women_incomegen_oth_16 women_incomegen_oth_17 women_incomegen_oth_18 women_incomegen_oth_19 women_incomegen_oth_20 ///
				women_incomegen_oth_21 women_incomegen_oth_22 women_incomegen_oth_23 women_incomegen_oth_24 ///
				women_incomegen_obst ///
				women_incomegen_obst_skills women_incomegen_obst_capital women_incomegen_obst_network women_incomegen_obst_confid ///
				women_incomegen_obst_safe women_incomegen_obst_busy women_incomegen_obst_chores women_incomegen_obst_parent

/*
preserve 
keep if !mi(boy_incomegen_oth) | !mi(girl_incomegen_oth) | !mi(men_incomegen_oth) | !mi(women_incomegen_oth)
keep key boy_incomegen_oth girl_incomegen_oth men_incomegen_oth women_incomegen_oth
export excel using "$out/hh_restriction_detail.xlsx", sheet("incomegen_oth") firstrow(variables) sheetreplace
restore
*/

*------------------------------------------------------------------------------*
***  END OF DATA CLEANING  ***
*------------------------------------------------------------------------------*

save "$dta/tatlan_plus_fsl_cleaned.dta", replace

clear

*------------------------------------------------------------------------------*
***  DATA IMPORTING  ***
*------------------------------------------------------------------------------*

use "$dta/tatlan_plus_fsl_cleaned.dta", clear

bysort vill_name source: egen final_sample = count(vill_name)
bysort vill_name source: keep if _n == 1
tempfile sample
save `sample', replace
clear


import excel 	using "$raw/Baseline_plan_NCL.xlsx", sheet("Sample_per_geounit") ///
				firstrow cellrange(A2:J29) case(lower) allstring clear

drop no 

rename villagename					vill_name 
rename camporvillage				geo_type_wt
rename totalhh						hh_tot
rename ofhhfromwealthrankinggrad	hh_level_c
rename f 							hh_level_d
rename beneficiarieshh 				hh_benef_tot		
rename nonbeneficiarieshh 			hh_non_benef_tot
rename samplebeneficiarieshh 		sample_benef
rename samplenonbeneficiarieshh		sample_non_benef

replace vill_name = "Ah Nauk Ye" if vill_name == "Ah Nauk Ywe"
replace vill_name = "Ma Nyin Kaing" if vill_name == "Ma Nyin Kaing (lower)"
replace vill_name = "Ma Nyin Kaing" if vill_name == "Ma Nyin Kaing (Upper)"
replace vill_name = "Nget Chaung" if vill_name == "Nget Chaung(1)"
replace vill_name = "Nget Chaung"  if vill_name == "Nget Chaung(2)"
replace vill_name = "Ohn Taw Gyi" if vill_name == "Ohn Taw Gyi (North)"
replace vill_name = "Ohn Taw Gyi" if vill_name == "Ohn Taw Gyi (South)"
replace vill_name = "Sin Tet Maw" if vill_name == "Sin Tet Maw (host village Muslim)"
replace vill_name = "Sin Tet Maw" if vill_name == "Sin Tet Maw (IDP)"
replace vill_name = "Thae Chaung" if vill_name == "Thae Chaung Camp"

** sampling note:
** as all the villages program intervention were survey in this baseline activity - one stage simple random sampling was applied
** weighted calculation for HH level at each village was required

// drop non-implementation villages
drop if mi(sample_benef)

destring hh_tot hh_level_c hh_level_d hh_benef_tot hh_non_benef_tot sample_benef sample_non_benef, replace

foreach var of varlist hh_tot hh_level_c hh_level_d hh_benef_tot hh_non_benef_tot sample_benef sample_non_benef {
	bysort vill_name: egen `var'_v = total(`var')
	order `var'_v, after(`var')
	drop `var'
	rename `var'_v `var'
}

bysort vill_name: keep if _n == 1

** HH number correction **
replace hh_tot = 54 if vill_name == "Ah Htet"
replace sample_non_benef = 5 if vill_name == "Ah Htet"

replace hh_tot = 108 if vill_name == "Kyar Kan"
replace sample_non_benef = 12 if vill_name == "Kyar Kan"


preserve
tempfile benef
drop hh_non_benef_tot sample_non_benef
rename sample_benef sample_benef_target

gen source = 0 
rename hh_benef_tot sampl_list

save `benef', replace
restore

drop hh_benef_tot sample_benef 
rename sample_non_benef sample_non_benef_target

gen source = 1
rename hh_non_benef_tot sampl_list

append using `benef'


merge 1:1 vill_name source using `sample', keepusing(final_sample)

drop if _merge != 3
drop _merge

** HH weight **
**Propability of selection at village Level**

gen sample_hh_pro = final_sample/sampl_list
tab sample_hh_pro

gen final_wt	=	1/sample_hh_pro
tab final_wt
sum final_wt, d


save "$dta/weight_fsl.dta", replace
export excel using "$out/fsl_sample_sruvey_figure.xlsx", firstrow(variables) replace
clear


use "$dta/tatlan_plus_fsl_cleaned.dta", clear
merge m:1 vill_name source using "$dta/weight_fsl.dta", keepusing(final_wt geo_type_wt)

rename geo_type geo_type_resp
rename geo_type_wt geo_type

keep if _merge == 3
drop _merge


replace vill_name = "1" if vill_name == "Ah Htet"
replace vill_name = "2" if vill_name == "Ah Nauk Ye"
replace vill_name = "3" if vill_name == "Baw Da Li"
replace vill_name = "4" if vill_name == "Chi Wai"
replace vill_name = "5" if vill_name == "Kyar Kan"
replace vill_name = "6" if vill_name == "Kyauk Pyin Seik"
replace vill_name = "7" if vill_name == "Kyein Ni Pyin"
replace vill_name = "8" if vill_name == "Ma De"
replace vill_name = "9" if vill_name == "Ma Nyin Kaing"
replace vill_name = "10" if vill_name == "Myin Kyan"
replace vill_name = "11" if vill_name == "Na Gar Myaung"
replace vill_name = "12" if vill_name == "Nay Pu Khan"
replace vill_name = "13" if vill_name == "Nget Chaung"
replace vill_name = "14" if vill_name == "Ohn Taw Gyi"
replace vill_name = "15" if vill_name == "Paik Seik"
replace vill_name = "16" if vill_name == "Pein Hne Chaung"
replace vill_name = "17" if vill_name == "Pone Nar Gyi"
replace vill_name = "18" if vill_name == "Sin Aing"
replace vill_name = "19" if vill_name == "Taung U Maw"
replace vill_name = "20" if vill_name == "Taw Tan"
replace vill_name = "21" if vill_name == "Thae Chaung"
replace vill_name = "22" if vill_name == "Thar Zay Kone"
destring vill_name, replace
lab def vill_name	1"Ah Htet" 2"Ah Nauk Ye" 3"Baw Da Li" 4"Chi Wai" 5"Kyar Kan" ///
					6"Kyauk Pyin Seik" 7"Kyein Ni Pyin" 8"Ma De" 9"Ma Nyin Kaing" 10"Myin Kyan" ///
					11"Na Gar Myaung" 12"Nay Pu Khan" 13"Nget Chaung" 14"Ohn Taw Gyi" 15"Paik Seik" ///
					16"Pein Hne Chaung" 17"Pone Nar Gyi" 18"Sin Aing" 19"Taung U Maw" 20"Taw Tan" ///
					21"Thae Chaung" 22"Thar Zay Kone"
lab val vill_name vill_name

forvalue x = 1/22 {
	gen vill_name_`x' = (vill_name == `x')
	replace vill_name_`x' = .m if mi(`var')
	tab vill_name_`x', m
}

lab var vill_name_1 "Ah Htet"
lab var vill_name_2 "Ah Nauk Ye"
lab var vill_name_3 "Baw Da Li"
lab var vill_name_4 "Chi Wai"
lab var vill_name_5 "Kyar Kan"
lab var vill_name_6 "Kyauk Pyin Seik"
lab var vill_name_7 "Kyein Ni Pyin"
lab var vill_name_8 "Ma De"
lab var vill_name_9 "Ma Nyin Kaing"
lab var vill_name_10 "Myin Kyan"
lab var vill_name_11 "Na Gar Myaung"
lab var vill_name_12 "Nay Pu Khan"
lab var vill_name_13 "Nget Chaung"
lab var vill_name_14 "Ohn Taw Gyi"
lab var vill_name_15 "Paik Seik"
lab var vill_name_16 "Pein Hne Chaung"
lab var vill_name_17 "Pone Nar Gyi"
lab var vill_name_18 "Sin Aing"
lab var vill_name_19 "Taung U Maw"
lab var vill_name_20 "Taw Tan"
lab var vill_name_21 "Thae Chaung"
lab var vill_name_22 "Thar Zay Kone"


replace geo_type_camp = 0 
replace geo_type_camp = 1 if vill_name_2 ==  1 | vill_name_6 == 1 | vill_name_13 == 1 | vill_name_14 == 1 | vill_name_21 == 1
replace geo_type_vill = 0
replace geo_type_vill = 1 if geo_type_camp == 0 


global geo 	geo_type_host geo_type_camp geo_type_vill ///
			vill_name_1 vill_name_2 vill_name_3 vill_name_4 vill_name_5 vill_name_6 vill_name_7 ///
			vill_name_8 vill_name_9 vill_name_10 vill_name_11 vill_name_12 vill_name_13 vill_name_14 ///
			vill_name_15 vill_name_16 vill_name_17 vill_name_18 vill_name_19 vill_name_20 vill_name_21 vill_name_22

save "$dta/tatlan_plus_fsl_cleaned_wt.dta", replace
