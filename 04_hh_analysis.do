/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

PROJECT:		Tat Lan Plus Baseline: Nutrition Report

PURPOSE: 		Food Security & Livelihood Dataset Data Analysis

AUTHOR:  		Nicholus

CREATED: 		24 Apr 2020

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

**----------------------------------------------------------------------------**
** Import Dataset
**----------------------------------------------------------------------------**

use "$dta/tatlan_plus_fsl_cleaned_wt.dta", clear

rename hh_head_gender hh_head_sex

**----------------------------------------------------------------------------**
**----------------------------------------------------------------------------**
** GEO INFORMATION **

global geo 	geo_type_host geo_type_camp geo_type_vill ///
			vill_name_1 vill_name_2 vill_name_3 vill_name_4 vill_name_5 vill_name_6 vill_name_7 ///
			vill_name_8 vill_name_9 vill_name_10 vill_name_11 vill_name_12 vill_name_13 vill_name_14 ///
			vill_name_15 vill_name_16 vill_name_17 vill_name_18 vill_name_19 vill_name_20 vill_name_21 vill_name_22
		

//// sample type: benef vs non benef
forvalue x = 0/1 {
	preserve 
	
	keep if source == `x'
	
	if _N > 0 {
	
	keep final_wt $geo    
	gen var_name = ""
		label var var_name "   "

	foreach var in num mean sd lb ub count {
		gen `var' = 0
		label var `var' "`var'"
	}
		
	local i = 1
	foreach var of global geo {
			
		local label : variable label `var'
		replace var_name = "`label'" in `i'
		
		count if !mi(`var') 
		if `r(N)' > 0 {
			quietly mean `var' [pw = final_wt]
			local N		= e(N)

			mat A 		= r(table)
			mat li A 	
			local mean 	= (A[1,1])
			local lb 	= (A[5,1])
			local ub 	= (A[6,1])
			
			quietly mean `var' [pw = final_wt]
			estat sd
			mat sd = r(sd)

			global mean 	= round(`mean', 0.001)
			replace mean 	= $mean in `i'
			
			global sd		= (sd[1,1]) // round(`r(se)', 0.001)
			replace sd		= $sd in `i'
			
			//global lb		= round(`lb', 0.001)
			replace lb		= `lb' in `i'
			
			//global ub		= round(`ub', 0.001)
			replace ub		= `ub' in `i'
			
			global count = `N'
			replace count = $count in `i'
			
			count if `var' == 1
			
			global num		= `r(N)'
			replace num		= $num in `i'
		}
		
		local i = `i' + 1
		
	}

	//drop if mi(var_name) //      //get rid of extra raws, if the variable is empty still keep it
	drop if count == 0     //get rid of extra raws - if the variable is empty value, drop
	global export_table var_name num mean sd lb ub count

	export excel $export_table using "$out/_fsl_hh/01_sumstat_fsl_geo_hh.xls",  sheet("geo_`x'") firstrow(varlabels) sheetreplace 	
	
	}
	restore
}


**----------------------------------------------------------------------------**
**----------------------------------------------------------------------------**
** HH INFORMATION **
global hhinfo	hh_size hhmem_num_male hhmem_num_female ///
				resp_sex hh_head_gender_male hh_head_gender_female ///
				hh_type_nodisplace hh_type_idp hh_displace_camp hh_displace_host hh_displace_other ///
				hh_restriction ///
				hh_restriction_1 hh_restriction_2 hh_restriction_3 hh_restriction_4 hh_restriction_5 hh_restriction_6 hh_restriction_7


// sample type: benef vs non benef
forvalue x = 0/1 {
	preserve 
	
	keep if source == `x'
	
	if _N > 0 {
	
	keep final_wt $hhinfo    
	gen var_name = ""
		label var var_name "   "

	foreach var in num mean sd lb ub count {
		gen `var' = 0
		label var `var' "`var'"
	}
		
	local i = 1
	foreach var of global hhinfo {
			
		local label : variable label `var'
		replace var_name = "`label'" in `i'
		
		quietly mean `var' [pw = final_wt]
		local N		= e(N)

		mat A 		= r(table)
		mat li A 	
		local mean 	= (A[1,1])
		local lb 	= (A[5,1])
		local ub 	= (A[6,1])
		
		quietly mean `var' [pw = final_wt]
		estat sd
		mat sd = r(sd)

		global mean 	= round(`mean', 0.001)
		replace mean 	= $mean in `i'
		
		global sd		= (sd[1,1]) // round(`r(se)', 0.001)
		replace sd		= $sd in `i'
		
		//global lb		= round(`lb', 0.001)
		replace lb		= `lb' in `i'
		
		//global ub		= round(`ub', 0.001)
		replace ub		= `ub' in `i'
		
		global count = `N'
		replace count = $count in `i'
		
		count if `var' == 1
		
		global num		= `r(N)'
		replace num		= $num in `i'
		
		local i = `i' + 1
		
	}

	//drop if mi(var_name) //      //get rid of extra raws, if the variable is empty still keep it
	drop if count == 0     //get rid of extra raws - if the variable is empty value, drop
	global export_table var_name num mean sd lb ub count

	export excel $export_table using "$out/_fsl_hh/01_sumstat_fsl_geo_hh.xls",  sheet("hhmem_`x'") firstrow(varlabels) sheetreplace 	
	
	}
	restore
}


**----------------------------------------------------------------------------**
**----------------------------------------------------------------------------**
** FOOD CONSUMPTION SCORE **
global fcs 	fcs_g1 fcs_g2 fcs_g3 fcs_g4 fcs_g5 fcs_g6 fcs_g7 fcs_g8 ///
			fcs_score fcs_acceptable fcs_borderline fcs_poor ///
			fcs_g1_fish fcs_g2_fish fcs_g3_fish fcs_g4_fish fcs_g5_fish fcs_g6_fish fcs_g7_fish fcs_g8_fish ///
			fcs_score_fish fcs_acceptable_fish fcs_borderline_fish fcs_poor_fish


// sample type: benef vs non benef
forvalue x = 0/1 {
	preserve 
	
	keep if source == `x'
	
	if _N > 0 {
	
	keep final_wt $fcs     
	gen var_name = ""
		label var var_name "   "

	foreach var in num mean sd lb ub count {
		gen `var' = 0
		label var `var' "`var'"
	}
		
	local i = 1
	foreach var of global fcs {
			
		local label : variable label `var'
		replace var_name = "`label'" in `i'
		
		quietly mean `var' [pw = final_wt]
		local N		= e(N)

		mat A 		= r(table)
		mat li A 	
		local mean 	= (A[1,1])
		local lb 	= (A[5,1])
		local ub 	= (A[6,1])
		
		quietly mean `var' [pw = final_wt]
		estat sd
		mat sd = r(sd)

		global mean 	= round(`mean', 0.001)
		replace mean 	= $mean in `i'
		
		global sd		= (sd[1,1]) // round(`r(se)', 0.001)
		replace sd		= $sd in `i'
		
		//global lb		= round(`lb', 0.001)
		replace lb		= `lb' in `i'
		
		//global ub		= round(`ub', 0.001)
		replace ub		= `ub' in `i'
		
		global count = `N'
		replace count = $count in `i'
		
		count if `var' == 1
		
		global num		= `r(N)'
		replace num		= $num in `i'
		
		local i = `i' + 1
				
	}

	//drop if mi(var_name) //      //get rid of extra raws, if the variable is empty still keep it
	drop if count == 0     //get rid of extra raws - if the variable is empty value, drop
	global export_table var_name num mean sd lb ub count

	export excel $export_table using "$out/_fsl_hh/02_sumstat_fsl_fcs.xls",  sheet("fcs_`x'") firstrow(varlabels) sheetreplace 	
	
	}
	restore
}


// sample type: benef vs non benef
// hh head gender
global fcs 	fcs_g1 fcs_g2 fcs_g3 fcs_g4 fcs_g5 fcs_g6 fcs_g7 fcs_g8 ///
			fcs_score fcs_acceptable fcs_borderline fcs_poor 		
			
forvalue y = 0/1 {

	forvalue x = 0/1 {
		preserve 
		
		keep if source == `y'
		
		if _N > 0 {
			
			keep if hh_head_sex == `x'
			
			if _N > 0 {
			
				keep final_wt $fcs     
				gen var_name = ""
					label var var_name "   "

				foreach var in num mean sd lb ub count {
					gen `var' = 0
					label var `var' "`var'"
				}
					
				local i = 1
				foreach var of global fcs {
						
					local label : variable label `var'
					replace var_name = "`label'" in `i'
					
					quietly mean `var' [pw = final_wt]
					local N		= e(N)

					mat A 		= r(table)
					mat li A 	
					local mean 	= (A[1,1])
					local lb 	= (A[5,1])
					local ub 	= (A[6,1])
					
					quietly mean `var' [pw = final_wt]
					estat sd
					mat sd = r(sd)

					global mean 	= round(`mean', 0.001)
					replace mean 	= $mean in `i'
					
					global sd		= (sd[1,1]) // round(`r(se)', 0.001)
					replace sd		= $sd in `i'
					
					//global lb		= round(`lb', 0.001)
					replace lb		= `lb' in `i'
					
					//global ub		= round(`ub', 0.001)
					replace ub		= `ub' in `i'
					
					global count = `N'
					replace count = $count in `i'
					
					count if `var' == 1
					
					global num		= `r(N)'
					replace num		= $num in `i'
					
					local i = `i' + 1
					
				}

				//drop if count == 0     //get rid of extra raws - if the variable is empty value, drop
				drop if mi(var_name) //      //get rid of extra raws
				global export_table var_name num mean sd lb ub count

				export excel $export_table using "$out/_fsl_hh/02_sumstat_fsl_fcs.xls",  sheet("fcs_`y'_`x'") firstrow(varlabels) sheetreplace 
			
				}
			}
	restore
	}
}


global fcs	fcs_g1_fish fcs_g2_fish fcs_g3_fish fcs_g4_fish fcs_g5_fish fcs_g6_fish fcs_g7_fish fcs_g8_fish ///
			fcs_score_fish fcs_acceptable_fish fcs_borderline_fish fcs_poor_fish		
				
forvalue y = 0/1 {

	forvalue x = 0/1 {
		preserve 
		
		keep if source == `y'
		
		if _N > 0 {
			
			keep if hh_head_sex == `x'
			
			if _N > 0 {
			
				keep final_wt $fcs     
				gen var_name = ""
					label var var_name "   "

				foreach var in num mean sd lb ub count {
					gen `var' = 0
					label var `var' "`var'"
				}
					
				local i = 1
				foreach var of global fcs {
						
					local label : variable label `var'
					replace var_name = "`label'" in `i'
					
					quietly mean `var' [pw = final_wt]
					local N		= e(N)

					mat A 		= r(table)
					mat li A 	
					local mean 	= (A[1,1])
					local lb 	= (A[5,1])
					local ub 	= (A[6,1])
					
					quietly mean `var' [pw = final_wt]
					estat sd
					mat sd = r(sd)

					global mean 	= round(`mean', 0.001)
					replace mean 	= $mean in `i'
					
					global sd		= (sd[1,1]) // round(`r(se)', 0.001)
					replace sd		= $sd in `i'
					
					//global lb		= round(`lb', 0.001)
					replace lb		= `lb' in `i'
					
					//global ub		= round(`ub', 0.001)
					replace ub		= `ub' in `i'
					
					global count = `N'
					replace count = $count in `i'
					
					count if `var' == 1
					
					global num		= `r(N)'
					replace num		= $num in `i'
					
					local i = `i' + 1
					
				}

				drop if count == 0     //get rid of extra raws - if the variable is empty value, drop
				// drop if mi(var_name) //      //get rid of extra raws
				global export_table var_name num mean sd lb ub count

				export excel $export_table using "$out/_fsl_hh/02_sumstat_fsl_fcs.xls",  sheet("fcs1_`y'_`x'") firstrow(varlabels) sheetreplace 
			
				}
			}
	restore
	}
}

			
**----------------------------------------------------------------------------**
**----------------------------------------------------------------------------**
** HH DIETARY DIVERSITY **

global hhds	hhds_g1 hhds_g2 hhds_g3 hhds_g4 hhds_g5 hhds_g6 hhds_g7 hhds_g8 hhds_g9 hhds_g10 hhds_g11 hhds_g12 ///
			hhds_score

	
// sample type: benef vs non benef
forvalue x = 0/1 {
	preserve 
	
	keep if source == `x'
	
	if _N > 0 {
	
	keep final_wt $hhds     
	gen var_name = ""
		label var var_name "   "

	foreach var in num mean sd lb ub count {
		gen `var' = 0
		label var `var' "`var'"
	}
		
	local i = 1
	foreach var of global hhds {
			
		local label : variable label `var'
		replace var_name = "`label'" in `i'
		
		quietly mean `var' [pw = final_wt]
		local N		= e(N)

		mat A 		= r(table)
		mat li A 	
		local mean 	= (A[1,1])
		local lb 	= (A[5,1])
		local ub 	= (A[6,1])
		
		quietly mean `var' [pw = final_wt]
		estat sd
		mat sd = r(sd)

		global mean 	= round(`mean', 0.001)
		replace mean 	= $mean in `i'
		
		global sd		= (sd[1,1]) // round(`r(se)', 0.001)
		replace sd		= $sd in `i'
		
		//global lb		= round(`lb', 0.001)
		replace lb		= `lb' in `i'
		
		//global ub		= round(`ub', 0.001)
		replace ub		= `ub' in `i'
		
		global count = `N'
		replace count = $count in `i'
		
		count if `var' == 1
		
		global num		= `r(N)'
		replace num		= $num in `i'
		
		local i = `i' + 1
		
	}

	//drop if mi(var_name) //      //get rid of extra raws, if the variable is empty still keep it
	drop if count == 0     //get rid of extra raws - if the variable is empty value, drop
	global export_table var_name num mean sd lb ub count

	export excel $export_table using "$out/_fsl_hh/03_sumstat_fsl_hhds.xls",  sheet("hhds_`x'") firstrow(varlabels) sheetreplace 	
	
	}
	restore
}


// sample type: benef vs non benef
// hh head gender
global hhds	hhds_g1 hhds_g2 hhds_g3 hhds_g4 hhds_g5 hhds_g6 hhds_g7 hhds_g8 hhds_g9 hhds_g10 hhds_g11 hhds_g12 ///
			hhds_score

				
forvalue y = 0/1 {

	forvalue x = 0/1 {
		preserve 
		
		keep if source == `y'
		
		if _N > 0 {
			
			keep if hh_head_sex == `x'
			
			if _N > 0 {
			
				keep final_wt $hhds     
				gen var_name = ""
					label var var_name "   "

				foreach var in num mean sd lb ub count {
					gen `var' = 0
					label var `var' "`var'"
				}
					
				local i = 1
				foreach var of global hhds {
						
					local label : variable label `var'
					replace var_name = "`label'" in `i'
					
					quietly mean `var' [pw = final_wt]
					local N		= e(N)

					mat A 		= r(table)
					mat li A 	
					local mean 	= (A[1,1])
					local lb 	= (A[5,1])
					local ub 	= (A[6,1])
					
					quietly mean `var' [pw = final_wt]
					estat sd
					mat sd = r(sd)

					global mean 	= round(`mean', 0.001)
					replace mean 	= $mean in `i'
					
					global sd		= (sd[1,1]) // round(`r(se)', 0.001)
					replace sd		= $sd in `i'
					
					//global lb		= round(`lb', 0.001)
					replace lb		= `lb' in `i'
					
					//global ub		= round(`ub', 0.001)
					replace ub		= `ub' in `i'
					
					global count = `N'
					replace count = $count in `i'
					
					count if `var' == 1
					
					global num		= `r(N)'
					replace num		= $num in `i'
					
					local i = `i' + 1
					
				}

				//drop if count == 0     //get rid of extra raws - if the variable is empty value, drop
				drop if mi(var_name) //      //get rid of extra raws
				global export_table var_name num mean sd lb ub count

				export excel $export_table using "$out/_fsl_hh/03_sumstat_fsl_hhds.xls",  sheet("hhds_`y'_`x'") firstrow(varlabels) sheetreplace 
			
				}
			}
	restore
	}
}


**----------------------------------------------------------------------------**
**----------------------------------------------------------------------------**
** FOOD STOCK AND ACCESS TO MARKETS **

global market 	staple_stock market_type_0 market_type_1 market_type_2 ///
				market_dist_1 market_dist_2 market_dist_3 market_dist_4 market_dist_5 market_dist_6 market_dist_7 ///
				market_access_all ///
				market_access_1 market_access_2 market_access_3 market_access_4 market_access_5 market_access_6 ///
				market_access_7 market_access_8 market_access_9 market_access_10 market_access_11 market_access_12


// sample type: benef vs non benef
forvalue x = 0/1 {
	preserve 
	
	keep if source == `x'
	
	if _N > 0 {
	
	keep final_wt $market     
	gen var_name = ""
		label var var_name "   "

	foreach var in num mean sd lb ub count {
		gen `var' = 0
		label var `var' "`var'"
	}
		
	local i = 1
	foreach var of global market {
			
		local label : variable label `var'
		replace var_name = "`label'" in `i'
		
		quietly mean `var' [pw = final_wt]
		local N		= e(N)

		mat A 		= r(table)
		mat li A 	
		local mean 	= (A[1,1])
		local lb 	= (A[5,1])
		local ub 	= (A[6,1])
		
		quietly mean `var' [pw = final_wt]
		estat sd
		mat sd = r(sd)

		global mean 	= round(`mean', 0.001)
		replace mean 	= $mean in `i'
		
		global sd		= (sd[1,1]) // round(`r(se)', 0.001)
		replace sd		= $sd in `i'
		
		//global lb		= round(`lb', 0.001)
		replace lb		= `lb' in `i'
		
		//global ub		= round(`ub', 0.001)
		replace ub		= `ub' in `i'
		
		global count = `N'
		replace count = $count in `i'
		
		count if `var' == 1
		
		global num		= `r(N)'
		replace num		= $num in `i'
		
		local i = `i' + 1
		
	}

	drop if mi(var_name) //      //get rid of extra raws, if the variable is empty still keep it
	// drop if count == 0     //get rid of extra raws - if the variable is empty value, drop
	global export_table var_name num mean sd lb ub count

	export excel $export_table using "$out/_fsl_hh/04_sumstat_fsl_market_hfias.xls",  sheet("market_`x'") firstrow(varlabels) sheetreplace 	
	
	}
	restore
}


// sample type: benef vs non benef
// hh head gender
	
forvalue y = 0/1 {

	forvalue x = 0/1 {
		preserve 
		
		keep if source == `y'
		
		if _N > 0 {
			
			keep if hh_head_sex == `x'
			
			if _N > 0 {
			
				keep final_wt $market     
				gen var_name = ""
					label var var_name "   "

				foreach var in num mean sd lb ub count {
					gen `var' = 0
					label var `var' "`var'"
				}
					
				local i = 1
				foreach var of global market {
						
					local label : variable label `var'
					replace var_name = "`label'" in `i'
					
					quietly mean `var' [pw = final_wt]
					local N		= e(N)

					mat A 		= r(table)
					mat li A 	
					local mean 	= (A[1,1])
					local lb 	= (A[5,1])
					local ub 	= (A[6,1])
					
					quietly mean `var' [pw = final_wt]
					estat sd
					mat sd = r(sd)

					global mean 	= round(`mean', 0.001)
					replace mean 	= $mean in `i'
					
					global sd		= (sd[1,1]) // round(`r(se)', 0.001)
					replace sd		= $sd in `i'
					
					//global lb		= round(`lb', 0.001)
					replace lb		= `lb' in `i'
					
					//global ub		= round(`ub', 0.001)
					replace ub		= `ub' in `i'
					
					global count = `N'
					replace count = $count in `i'
					
					count if `var' == 1
					
					global num		= `r(N)'
					replace num		= $num in `i'
					
					local i = `i' + 1
					
				}

				//drop if count == 0     //get rid of extra raws - if the variable is empty value, drop
				drop if mi(var_name) //      //get rid of extra raws
				global export_table var_name num mean sd lb ub count

				export excel $export_table using "$out/_fsl_hh/04_sumstat_fsl_market_hfias.xls",  sheet("merket_`y'_`x'") firstrow(varlabels) sheetreplace 
			
				}
			}
	restore
	}
}

**----------------------------------------------------------------------------**
**----------------------------------------------------------------------------**
** FOOD INSECURITY ACCESS SCALE **

global hfias hfias_score hfias_level_1 hfias_level_2 hfias_level_3 hfias_level_4

// sample type: benef vs non benef

forvalue x = 0/1 {
	preserve 
	
	keep if source == `x'
	
	if _N > 0 {
	
	keep final_wt $hfias     
	gen var_name = ""
		label var var_name "   "

	foreach var in num mean sd lb ub count {
		gen `var' = 0
		label var `var' "`var'"
	}
		
	local i = 1
	foreach var of global hfias {
			
		local label : variable label `var'
		replace var_name = "`label'" in `i'
		
		quietly mean `var' [pw = final_wt]
		local N		= e(N)

		mat A 		= r(table)
		mat li A 	
		local mean 	= (A[1,1])
		local lb 	= (A[5,1])
		local ub 	= (A[6,1])
		
		quietly mean `var' [pw = final_wt]
		estat sd
		mat sd = r(sd)

		global mean 	= round(`mean', 0.001)
		replace mean 	= $mean in `i'
		
		global sd		= (sd[1,1]) // round(`r(se)', 0.001)
		replace sd		= $sd in `i'
		
		//global lb		= round(`lb', 0.001)
		replace lb		= `lb' in `i'
		
		//global ub		= round(`ub', 0.001)
		replace ub		= `ub' in `i'
		
		global count = `N'
		replace count = $count in `i'
		
		count if `var' == 1
		
		global num		= `r(N)'
		replace num		= $num in `i'
		
		local i = `i' + 1
		
	}

	//drop if mi(var_name) //      //get rid of extra raws, if the variable is empty still keep it
	drop if count == 0     //get rid of extra raws - if the variable is empty value, drop
	global export_table var_name num mean sd lb ub count

	export excel $export_table using "$out/_fsl_hh/04_sumstat_fsl_market_hfias.xls",  sheet("hfias_`x'") firstrow(varlabels) sheetreplace 	
	
	}
	restore
}


// sample type: benef vs non benef
// hh head gender

forvalue y = 0/1 {

	forvalue x = 0/1 {
		preserve 
		
		keep if source == `y'
		
		if _N > 0 {
			
			keep if hh_head_sex == `x'
			
			if _N > 0 {
			
				keep final_wt $hfias     
				gen var_name = ""
					label var var_name "   "

				foreach var in num mean sd lb ub count {
					gen `var' = 0
					label var `var' "`var'"
				}
					
				local i = 1
				foreach var of global hfias {
						
					local label : variable label `var'
					replace var_name = "`label'" in `i'
					
					quietly mean `var' [pw = final_wt]
					local N		= e(N)

					mat A 		= r(table)
					mat li A 	
					local mean 	= (A[1,1])
					local lb 	= (A[5,1])
					local ub 	= (A[6,1])
					
					quietly mean `var' [pw = final_wt]
					estat sd
					mat sd = r(sd)

					global mean 	= round(`mean', 0.001)
					replace mean 	= $mean in `i'
					
					global sd		= (sd[1,1]) // round(`r(se)', 0.001)
					replace sd		= $sd in `i'
					
					//global lb		= round(`lb', 0.001)
					replace lb		= `lb' in `i'
					
					//global ub		= round(`ub', 0.001)
					replace ub		= `ub' in `i'
					
					global count = `N'
					replace count = $count in `i'
					
					count if `var' == 1
					
					global num		= `r(N)'
					replace num		= $num in `i'
					
					local i = `i' + 1
					
				}

				//drop if count == 0     //get rid of extra raws - if the variable is empty value, drop
				drop if mi(var_name) //      //get rid of extra raws
				global export_table var_name num mean sd lb ub count

				export excel $export_table using "$out/_fsl_hh/04_sumstat_fsl_market_hfias.xls",  sheet("hfias_`y'_`x'") firstrow(varlabels) sheetreplace 
			
				}
			}
	restore
	}
}

**----------------------------------------------------------------------------**
**----------------------------------------------------------------------------**
** LIVELIHOODS AND INCOME SOURCE **

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


// sample type: benef vs non benef
forvalue x = 0/1 {
	preserve 
	
	keep if source == `x'
	
	if _N > 0 {
	
	keep final_wt $earner     
	gen var_name = ""
		label var var_name "   "

	foreach var in num mean sd lb ub count {
		gen `var' = 0
		label var `var' "`var'"
	}
		
	local i = 1
	foreach var of global earner {
			
		local label : variable label `var'
		replace var_name = "`label'" in `i'
		
		quietly mean `var' [pw = final_wt]
		local N		= e(N)

		mat A 		= r(table)
		mat li A 	
		local mean 	= (A[1,1])
		local lb 	= (A[5,1])
		local ub 	= (A[6,1])
		
		quietly mean `var' [pw = final_wt]
		estat sd
		mat sd = r(sd)

		global mean 	= round(`mean', 0.001)
		replace mean 	= $mean in `i'
		
		global sd		= (sd[1,1]) // round(`r(se)', 0.001)
		replace sd		= $sd in `i'
		
		//global lb		= round(`lb', 0.001)
		replace lb		= `lb' in `i'
		
		//global ub		= round(`ub', 0.001)
		replace ub		= `ub' in `i'
		
		global count = `N'
		replace count = $count in `i'
		
		count if `var' == 1
		
		global num		= `r(N)'
		replace num		= $num in `i'
		
		local i = `i' + 1
		
	}

	//drop if mi(var_name) //      //get rid of extra raws, if the variable is empty still keep it
	drop if count == 0     //get rid of extra raws - if the variable is empty value, drop
	global export_table var_name num mean sd lb ub count

	export excel $export_table using "$out/_fsl_hh/05_sumstat_fsl_job_income.xls",  sheet("job_income_`x'") firstrow(varlabels) sheetreplace 	
	
	}
	restore
}


// sample type: benef vs non benef
// hh head gender

forvalue y = 0/1 {

	forvalue x = 0/1 {
		preserve 
		
		keep if source == `y'
		
		if _N > 0 {
			
			keep if hh_head_sex == `x'
			
			if _N > 0 {
			
				keep final_wt $earner     
				gen var_name = ""
					label var var_name "   "

				foreach var in num mean sd lb ub count {
					gen `var' = 0
					label var `var' "`var'"
				}
					
				local i = 1
				foreach var of global earner {
						
					local label : variable label `var'
					replace var_name = "`label'" in `i'
					
					quietly mean `var' [pw = final_wt]
					local N		= e(N)

					mat A 		= r(table)
					mat li A 	
					local mean 	= (A[1,1])
					local lb 	= (A[5,1])
					local ub 	= (A[6,1])
					
					quietly mean `var' [pw = final_wt]
					estat sd
					mat sd = r(sd)

					global mean 	= round(`mean', 0.001)
					replace mean 	= $mean in `i'
					
					global sd		= (sd[1,1]) // round(`r(se)', 0.001)
					replace sd		= $sd in `i'
					
					//global lb		= round(`lb', 0.001)
					replace lb		= `lb' in `i'
					
					//global ub		= round(`ub', 0.001)
					replace ub		= `ub' in `i'
					
					global count = `N'
					replace count = $count in `i'
					
					count if `var' == 1
					
					global num		= `r(N)'
					replace num		= $num in `i'
					
					local i = `i' + 1
					
				}

				//drop if count == 0     //get rid of extra raws - if the variable is empty value, drop
				drop if mi(var_name) //      //get rid of extra raws
				global export_table var_name num mean sd lb ub count

				export excel $export_table using "$out/_fsl_hh/05_sumstat_fsl_job_income.xls",  sheet("job_income_`y'_`x'") firstrow(varlabels) sheetreplace 
			
				}
			}
	restore
	}
}


**----------------------------------------------------------------------------**
**----------------------------------------------------------------------------**
** COPING STRATEGY INDEX - LCSI **

global csi	lcis_secure lcis_stress lcis_crisis lcis_emergency ///
			migration_yn migrate_temp migrate_longterm



// sample type: benef vs non benef
forvalue x = 0/1 {
	preserve 
	
	keep if source == `x'
	
	if _N > 0 {
	
	keep final_wt $csi     
	gen var_name = ""
		label var var_name "   "

	foreach var in num mean sd lb ub count {
		gen `var' = 0
		label var `var' "`var'"
	}
		
	local i = 1
	foreach var of global csi {
			
		local label : variable label `var'
		replace var_name = "`label'" in `i'
		
		quietly mean `var' [pw = final_wt]
		local N		= e(N)

		mat A 		= r(table)
		mat li A 	
		local mean 	= (A[1,1])
		local lb 	= (A[5,1])
		local ub 	= (A[6,1])
		
		quietly mean `var' [pw = final_wt]
		estat sd
		mat sd = r(sd)

		global mean 	= round(`mean', 0.001)
		replace mean 	= $mean in `i'
		
		global sd		= (sd[1,1]) // round(`r(se)', 0.001)
		replace sd		= $sd in `i'
		
		//global lb		= round(`lb', 0.001)
		replace lb		= `lb' in `i'
		
		//global ub		= round(`ub', 0.001)
		replace ub		= `ub' in `i'
		
		global count = `N'
		replace count = $count in `i'
		
		count if `var' == 1
		
		global num		= `r(N)'
		replace num		= $num in `i'
		
		local i = `i' + 1
		
	}

	//drop if mi(var_name) //      //get rid of extra raws, if the variable is empty still keep it
	drop if count == 0     //get rid of extra raws - if the variable is empty value, drop
	global export_table var_name num mean sd lb ub count

	export excel $export_table using "$out/_fsl_hh/06_sumstat_fsl_lcsi_migt.xls",  sheet("lcsi_migt_`x'") firstrow(varlabels) sheetreplace 	
	
	}
	restore
}


// sample type: benef vs non benef
// hh head gender

forvalue y = 0/1 {

	forvalue x = 0/1 {
		preserve 
		
		keep if source == `y'
		
		if _N > 0 {
			
			keep if hh_head_sex == `x'
			
			if _N > 0 {
			
				keep final_wt $csi     
				gen var_name = ""
					label var var_name "   "

				foreach var in num mean sd lb ub count {
					gen `var' = 0
					label var `var' "`var'"
				}
					
				local i = 1
				foreach var of global csi {
						
					local label : variable label `var'
					replace var_name = "`label'" in `i'
					
					quietly mean `var' [pw = final_wt]
					local N		= e(N)

					mat A 		= r(table)
					mat li A 	
					local mean 	= (A[1,1])
					local lb 	= (A[5,1])
					local ub 	= (A[6,1])
					
					quietly mean `var' [pw = final_wt]
					estat sd
					mat sd = r(sd)

					global mean 	= round(`mean', 0.001)
					replace mean 	= $mean in `i'
					
					global sd		= (sd[1,1]) // round(`r(se)', 0.001)
					replace sd		= $sd in `i'
					
					//global lb		= round(`lb', 0.001)
					replace lb		= `lb' in `i'
					
					//global ub		= round(`ub', 0.001)
					replace ub		= `ub' in `i'
					
					global count = `N'
					replace count = $count in `i'
					
					count if `var' == 1
					
					global num		= `r(N)'
					replace num		= $num in `i'
					
					local i = `i' + 1
					
				}

				//drop if count == 0     //get rid of extra raws - if the variable is empty value, drop
				drop if mi(var_name) //      //get rid of extra raws
				global export_table var_name num mean sd lb ub count

				export excel $export_table using "$out/_fsl_hh/06_sumstat_fsl_lcsi_migt.xls",  sheet("lcsi_migt_`y'_`x'") firstrow(varlabels) sheetreplace 
			
				}
			}
	restore
	}
}


**----------------------------------------------------------------------------**
**----------------------------------------------------------------------------**
** HH ASSETS **
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
				

// sample type: benef vs non benef
forvalue x = 0/1 {
	preserve 
	
	keep if source == `x'
	
	if _N > 0 {
	
	keep final_wt $hhassets     
	gen var_name = ""
		label var var_name "   "

	foreach var in num mean sd lb ub count {
		gen `var' = 0
		label var `var' "`var'"
	}
		
	local i = 1
	foreach var of global hhassets {
			
		local label : variable label `var'
		replace var_name = "`label'" in `i'
		
		quietly mean `var' [pw = final_wt]
		local N		= e(N)

		mat A 		= r(table)
		mat li A 	
		local mean 	= (A[1,1])
		local lb 	= (A[5,1])
		local ub 	= (A[6,1])
		
		quietly mean `var' [pw = final_wt]
		estat sd
		mat sd = r(sd)

		global mean 	= round(`mean', 0.001)
		replace mean 	= $mean in `i'
		
		global sd		= (sd[1,1]) // round(`r(se)', 0.001)
		replace sd		= $sd in `i'
		
		//global lb		= round(`lb', 0.001)
		replace lb		= `lb' in `i'
		
		//global ub		= round(`ub', 0.001)
		replace ub		= `ub' in `i'
		
		global count = `N'
		replace count = $count in `i'
		
		count if `var' == 1
		
		global num		= `r(N)'
		replace num		= $num in `i'
		
		local i = `i' + 1
		
	}

	//drop if mi(var_name) //      //get rid of extra raws, if the variable is empty still keep it
	drop if count == 0     //get rid of extra raws - if the variable is empty value, drop
	global export_table var_name num mean sd lb ub count

	export excel $export_table using "$out/_fsl_hh/07_sumstat_fsl_hhassets.xls",  sheet("hhassets_`x'") firstrow(varlabels) sheetreplace 	
	
	}
	restore
}


// sample type: benef vs non benef
// hh head gender
		
forvalue y = 0/1 {

	forvalue x = 0/1 {
		preserve 
		
		keep if source == `y'
		
		if _N > 0 {
			
			keep if hh_head_sex == `x'
			
			if _N > 0 {
			
				keep final_wt $hhassets     
				gen var_name = ""
					label var var_name "   "

				foreach var in num mean sd lb ub count {
					gen `var' = 0
					label var `var' "`var'"
				}
					
				local i = 1
				foreach var of global hhassets {
						
					local label : variable label `var'
					replace var_name = "`label'" in `i'
					
					quietly mean `var' [pw = final_wt]
					local N		= e(N)

					mat A 		= r(table)
					mat li A 	
					local mean 	= (A[1,1])
					local lb 	= (A[5,1])
					local ub 	= (A[6,1])
					
					quietly mean `var' [pw = final_wt]
					estat sd
					mat sd = r(sd)

					global mean 	= round(`mean', 0.001)
					replace mean 	= $mean in `i'
					
					global sd		= (sd[1,1]) // round(`r(se)', 0.001)
					replace sd		= $sd in `i'
					
					//global lb		= round(`lb', 0.001)
					replace lb		= `lb' in `i'
					
					//global ub		= round(`ub', 0.001)
					replace ub		= `ub' in `i'
					
					global count = `N'
					replace count = $count in `i'
					
					count if `var' == 1
					
					global num		= `r(N)'
					replace num		= $num in `i'
					
					local i = `i' + 1
					
				}

				//drop if count == 0     //get rid of extra raws - if the variable is empty value, drop
				drop if mi(var_name) //      //get rid of extra raws
				global export_table var_name num mean sd lb ub count

				export excel $export_table using "$out/_fsl_hh/07_sumstat_fsl_hhassets.xls",  sheet("hhassets_`y'_`x'") firstrow(varlabels) sheetreplace 
			
				}
			}
	restore
	}
}

**----------------------------------------------------------------------------**
**----------------------------------------------------------------------------**
** HOUSEHOLD EXPENDITURES **
global budget 	hh_financial_1 hh_financial_2 hh_financial_3 hh_financial_4 hh_financial_5 hh_financial_6 ///
				hh_left_money_1 hh_left_money_2 hh_left_money_3 hh_left_money_4 hh_left_money_5 hh_left_money_6 ///
				hh_cover_expend_1 hh_cover_expend_2 hh_cover_expend_3 hh_cover_expend_4 hh_cover_expend_5 hh_cover_expend_6 hh_cover_expend_7 hh_cover_expend_8 ///
				unexpect_yn unexpect_cope_loan unexpect_cope_save unexpect_cope_assist unexpect_cope_sold unexpect_cope_dk unexpect_cope_noans ///
				unexpect_scenario_1 unexpect_scenario_2 unexpect_scenario_3 unexpect_scenario_4 unexpect_scenario_5 unexpect_scenario_6 ///
				hhexp_food_annual_s hhexp_beverage_annual_s hhexp_health_annual_s hhexp_edu_annual_s ///
				hhexp_allbusi_annual_s hhexp_hhhouse_annual_s hhexp_regpay_annual_s hhexp_debt_annual_s ///
				hhexp_social_annual_s hhexp_lottery_annual_s hhexp_transport_annual_s hhexp_remittance_annual_s

// sample type: benef vs non benef
forvalue x = 0/1 {
	preserve 
	
	keep if source == `x'
	
	if _N > 0 {
	
	keep final_wt $budget     
	gen var_name = ""
		label var var_name "   "

	foreach var in num mean sd lb ub count {
		gen `var' = 0
		label var `var' "`var'"
	}
		
	local i = 1
	foreach var of global budget {
			
		local label : variable label `var'
		replace var_name = "`label'" in `i'
		
		quietly mean `var' [pw = final_wt]
		local N		= e(N)

		mat A 		= r(table)
		mat li A 	
		local mean 	= (A[1,1])
		local lb 	= (A[5,1])
		local ub 	= (A[6,1])
		
		quietly mean `var' [pw = final_wt]
		estat sd
		mat sd = r(sd)

		global mean 	= round(`mean', 0.001)
		replace mean 	= $mean in `i'
		
		global sd		= (sd[1,1]) // round(`r(se)', 0.001)
		replace sd		= $sd in `i'
		
		//global lb		= round(`lb', 0.001)
		replace lb		= `lb' in `i'
		
		//global ub		= round(`ub', 0.001)
		replace ub		= `ub' in `i'
		
		global count = `N'
		replace count = $count in `i'
		
		count if `var' == 1
		
		global num		= `r(N)'
		replace num		= $num in `i'
		
		local i = `i' + 1
		
	}

	//drop if mi(var_name) //      //get rid of extra raws, if the variable is empty still keep it
	drop if count == 0     //get rid of extra raws - if the variable is empty value, drop
	global export_table var_name num mean sd lb ub count

	export excel $export_table using "$out/_fsl_hh/08_sumstat_fsl_hhexpense.xls",  sheet("hhexpense_`x'") firstrow(varlabels) sheetreplace 	
	
	}
	restore
}


// sample type: benef vs non benef
// hh head gender				
		
forvalue y = 0/1 {

	forvalue x = 0/1 {
		preserve 
		
		keep if source == `y'
		
		if _N > 0 {
			
			keep if hh_head_sex == `x'
			
			if _N > 0 {
			
				keep final_wt $budget     
				gen var_name = ""
					label var var_name "   "

				foreach var in num mean sd lb ub count {
					gen `var' = 0
					label var `var' "`var'"
				}
					
				local i = 1
				foreach var of global budget {
						
					local label : variable label `var'
					replace var_name = "`label'" in `i'
					
					count if !mi(`var')
					if `r(N)' > 0 {
					
						quietly mean `var' [pw = final_wt]
						local N		= e(N)

						mat A 		= r(table)
						mat li A 	
						local mean 	= (A[1,1])
						local lb 	= (A[5,1])
						local ub 	= (A[6,1])
						
						quietly mean `var' [pw = final_wt]
						estat sd
						mat sd = r(sd)

						global mean 	= round(`mean', 0.001)
						replace mean 	= $mean in `i'
						
						global sd		= (sd[1,1]) // round(`r(se)', 0.001)
						replace sd		= $sd in `i'
						
						//global lb		= round(`lb', 0.001)
						replace lb		= `lb' in `i'
						
						//global ub		= round(`ub', 0.001)
						replace ub		= `ub' in `i'
						
						global count = `N'
						replace count = $count in `i'
						
						count if `var' == 1
						
						global num		= `r(N)'
						replace num		= $num in `i'
					
					}
					
					local i = `i' + 1
					
				}

				//drop if count == 0     //get rid of extra raws - if the variable is empty value, drop
				drop if mi(var_name) //      //get rid of extra raws
				global export_table var_name num mean sd lb ub count

				export excel $export_table using "$out/_fsl_hh/08_sumstat_fsl_hhexpense.xls",  sheet("hhexpense_`y'_`x'") firstrow(varlabels) sheetreplace 
			
				}
			}
	restore
	}
}


global share	hhexp_tot_annual ///
				hhexp_food_annual hhexp_beverage_annual hhexp_health_annual hhexp_edu_annual ///
				hhexp_allbusi_annual hhexp_hhhouse_annual hhexp_regpay_annual ///
				hhexp_debt_annual hhexp_social_annual hhexp_lottery_annual ///
				hhexp_transport_annual hhexp_remittance_annual 
			

// sample type: benef vs non benef
forvalue x = 0/1 {
	preserve 
	
	keep if source == `x'
	
	if _N > 0 {
	
	keep final_wt $share     
	gen var_name = ""
		label var var_name "   "

	foreach var in mean median q_first q_third count {
		gen `var' = 0
		label var `var' "`var'"
	}
		
	local i = 1
	foreach var of global share {
			
		local label : variable label `var'
		replace var_name = "`label'" in `i'
		
		quietly sum `var' [aw = final_wt],d
		
		local N			= `r(N)'
		local mean		= `r(mean)'
		local median	= `r(p50)'
		local q_first	= `r(p25)'
		local q_third	= `r(p75)'
				
		global mean 	= round(`mean', 0.001)
		replace mean 	= $mean in `i'
		
		global median	= round(`median', 0.001)
		replace median	= $median in `i'
		
		global q_first	= round(`q_first', 0.001)
		replace q_first	= `q_first' in `i'
		
		global q_third	= round(`q_third', 0.001)
		replace q_third	= `q_third' in `i'
		
		global count = `N'
		replace count = $count in `i'
		
		local i = `i' + 1
		
	}

	//drop if mi(var_name) //      //get rid of extra raws, if the variable is empty still keep it
	drop if count == 0     //get rid of extra raws - if the variable is empty value, drop
	global export_table var_name mean median q_first q_third count

	export excel $export_table using "$out/_fsl_hh/08_sumstat_fsl_hhexpense.xls",  sheet("share_`x'") firstrow(varlabels) sheetreplace 	
	
	}
	restore
}


// sample type: benef vs non benef
// hh head gender	
		
forvalue y = 0/1 {

	forvalue x = 0/1 {
		preserve 
		
		keep if source == `y'
		
		if _N > 0 {
			
			keep if hh_head_sex == `x'
			
			if _N > 0 {
			
				keep final_wt $share     
				gen var_name = ""
					label var var_name "   "

				foreach var in mean median q_first q_third count {
					gen `var' = 0
					label var `var' "`var'"
				}
					
				local i = 1
				foreach var of global share {
						
					local label : variable label `var'
					replace var_name = "`label'" in `i'
					
					count if !mi(`var')
					if `r(N)' > 0 {
					
						quietly sum `var' [aw = final_wt],d
						
						local N			= `r(N)'
						local mean		= `r(mean)'
						local median	= `r(p50)'
						local q_first	= `r(p25)'
						local q_third	= `r(p75)'
						
						quietly mean `var' [pw = final_wt]
						estat sd
						mat sd = r(sd)

						
						global mean 	= round(`mean', 0.001)
						replace mean 	= $mean in `i'
						
						global median	= round(`median', 0.001)
						replace median	= $median in `i'
						
						global q_first	= round(`q_first', 0.001)
						replace q_first	= `q_first' in `i'
						
						global q_third	= round(`q_third', 0.001)
						replace q_third	= `q_third' in `i'
						
						global count = `N'
						replace count = $count in `i'
					
					}
					
					local i = `i' + 1
					
				}

				//drop if count == 0     //get rid of extra raws - if the variable is empty value, drop
				drop if mi(var_name) //      //get rid of extra raws
				global export_table var_name mean median q_first q_third count

				export excel $export_table using "$out/_fsl_hh/08_sumstat_fsl_hhexpense.xls",  sheet("share_`y'_`x'") firstrow(varlabels) sheetreplace 
			
				}
			}
	restore
	}
}

**----------------------------------------------------------------------------**
**----------------------------------------------------------------------------**
** CREDIT AND SAVINGS **
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
			

// sample type: benef vs non benef
forvalue x = 0/1 {
	preserve 
	
	keep if source == `x'
	
	if _N > 0 {
	
	keep final_wt $loan     
	gen var_name = ""
		label var var_name "   "

	foreach var in num mean sd lb ub count {
		gen `var' = 0
		label var `var' "`var'"
	}
		
	local i = 1
	foreach var of global loan {
			
		local label : variable label `var'
		replace var_name = "`label'" in `i'
		
		quietly mean `var' [pw = final_wt]
		local N		= e(N)

		mat A 		= r(table)
		mat li A 	
		local mean 	= (A[1,1])
		local lb 	= (A[5,1])
		local ub 	= (A[6,1])
		
		quietly mean `var' [pw = final_wt]
		estat sd
		mat sd = r(sd)

		global mean 	= round(`mean', 0.001)
		replace mean 	= $mean in `i'
		
		global sd		= (sd[1,1]) // round(`r(se)', 0.001)
		replace sd		= $sd in `i'
		
		//global lb		= round(`lb', 0.001)
		replace lb		= `lb' in `i'
		
		//global ub		= round(`ub', 0.001)
		replace ub		= `ub' in `i'
		
		global count = `N'
		replace count = $count in `i'
		
		count if `var' == 1
		
		global num		= `r(N)'
		replace num		= $num in `i'
		
		local i = `i' + 1
		
	}

	//drop if mi(var_name) //      //get rid of extra raws, if the variable is empty still keep it
	drop if count == 0     //get rid of extra raws - if the variable is empty value, drop
	global export_table var_name num mean sd lb ub count

	export excel $export_table using "$out/_fsl_hh/09_sumstat_fsl_creditsave.xls",  sheet("loan_`x'") firstrow(varlabels) sheetreplace 	
	
	}
	restore
}


// sample type: benef vs non benef
// hh head gender
				
forvalue y = 0/1 {

	forvalue x = 0/1 {
		preserve 
		
		keep if source == `y'
		
		if _N > 0 {
			
			keep if hh_head_sex == `x'
			
			if _N > 0 {
			
				keep final_wt $loan     
				gen var_name = ""
					label var var_name "   "

				foreach var in num mean sd lb ub count {
					gen `var' = 0
					label var `var' "`var'"
				}
					
				local i = 1
				foreach var of global loan {
						
					local label : variable label `var'
					replace var_name = "`label'" in `i'
					
					count if !mi(`var')
					if `r(N)' > 0 {
					
						quietly mean `var' [pw = final_wt]
						local N		= e(N)

						mat A 		= r(table)
						mat li A 	
						local mean 	= (A[1,1])
						local lb 	= (A[5,1])
						local ub 	= (A[6,1])
						
						quietly mean `var' [pw = final_wt]
						estat sd
						mat sd = r(sd)

						global mean 	= round(`mean', 0.001)
						replace mean 	= $mean in `i'
						
						global sd		= (sd[1,1]) // round(`r(se)', 0.001)
						replace sd		= $sd in `i'
						
						//global lb		= round(`lb', 0.001)
						replace lb		= `lb' in `i'
						
						//global ub		= round(`ub', 0.001)
						replace ub		= `ub' in `i'
						
						global count = `N'
						replace count = $count in `i'
						
						count if `var' == 1
						
						global num		= `r(N)'
						replace num		= $num in `i'
					
					}
					
					local i = `i' + 1
					
				}

				//drop if count == 0     //get rid of extra raws - if the variable is empty value, drop
				drop if mi(var_name) //      //get rid of extra raws
				global export_table var_name num mean sd lb ub count

				export excel $export_table using "$out/_fsl_hh/09_sumstat_fsl_creditsave.xls",  sheet("loan_`y'_`x'") firstrow(varlabels) sheetreplace 
			
				}
			}
	restore
	}
}


global save		hh_bankacc_num_yn hh_bankacc_num hh_vsla_mem_num_yn hh_vsla_mem_num hh_save_yn ///
				hh_saveplace_bank hh_saveplace_mfi hh_saveplace_vsla hh_saveplace_family hh_saveplace_home ///
				hh_saveplace_religious hh_saveplace_gov hh_saveplace_gold hh_saveplace_other hh_saveplace_dk hh_saveplace_noans ///
				hh_save_now_1 hh_save_now_2 hh_save_now_3 hh_save_now_4 hh_save_now_5 hh_save_now_6 hh_save_now_7 ///
				hh_save_now_8 hh_save_now_9 hh_save_now_10 hh_save_now_11 hh_save_now_12 hh_save_now_13 hh_save_now_14 ///
				hh_save_now_15 hh_save_now_16 hh_save_now_17 hh_save_now_18 ///
				hh_save_lastyr_1 hh_save_lastyr_2 hh_save_lastyr_3 hh_save_lastyr_4 hh_save_lastyr_5 hh_save_lastyr_6
	
// sample type: benef vs non benef
forvalue x = 0/1 {
	preserve 
	
	keep if source == `x'
	
	if _N > 0 {
	
	keep final_wt $save     
	gen var_name = ""
		label var var_name "   "

	foreach var in num mean sd lb ub count {
		gen `var' = 0
		label var `var' "`var'"
	}
		
	local i = 1
	foreach var of global save {
			
		local label : variable label `var'
		replace var_name = "`label'" in `i'
		
		quietly mean `var' [pw = final_wt]
		local N		= e(N)

		mat A 		= r(table)
		mat li A 	
		local mean 	= (A[1,1])
		local lb 	= (A[5,1])
		local ub 	= (A[6,1])
		
		quietly mean `var' [pw = final_wt]
		estat sd
		mat sd = r(sd)

		global mean 	= round(`mean', 0.001)
		replace mean 	= $mean in `i'
		
		global sd		= (sd[1,1]) // round(`r(se)', 0.001)
		replace sd		= $sd in `i'
		
		//global lb		= round(`lb', 0.001)
		replace lb		= `lb' in `i'
		
		//global ub		= round(`ub', 0.001)
		replace ub		= `ub' in `i'
		
		global count = `N'
		replace count = $count in `i'
		
		count if `var' == 1
		
		global num		= `r(N)'
		replace num		= $num in `i'
		
		local i = `i' + 1
		
	}

	//drop if mi(var_name) //      //get rid of extra raws, if the variable is empty still keep it
	drop if count == 0     //get rid of extra raws - if the variable is empty value, drop
	global export_table var_name num mean sd lb ub count

	export excel $export_table using "$out/_fsl_hh/09_sumstat_fsl_creditsave.xls",  sheet("save_`x'") firstrow(varlabels) sheetreplace 	
	
	}
	restore
}


// sample type: benef vs non benef
// hh head gender
				
forvalue y = 0/1 {

	forvalue x = 0/1 {
		preserve 
		
		keep if source == `y'
		
		if _N > 0 {
			
			keep if hh_head_sex == `x'
			
			if _N > 0 {
			
				keep final_wt $save     
				gen var_name = ""
					label var var_name "   "

				foreach var in num mean sd lb ub count {
					gen `var' = 0
					label var `var' "`var'"
				}
					
				local i = 1
				foreach var of global save {
						
					local label : variable label `var'
					replace var_name = "`label'" in `i'
					
					count if !mi(`var')
					if `r(N)' > 0 {
					
						quietly mean `var' [pw = final_wt]
						local N		= e(N)

						mat A 		= r(table)
						mat li A 	
						local mean 	= (A[1,1])
						local lb 	= (A[5,1])
						local ub 	= (A[6,1])
						
						quietly mean `var' [pw = final_wt]
						estat sd
						mat sd = r(sd)

						global mean 	= round(`mean', 0.001)
						replace mean 	= $mean in `i'
						
						global sd		= (sd[1,1]) // round(`r(se)', 0.001)
						replace sd		= $sd in `i'
						
						//global lb		= round(`lb', 0.001)
						replace lb		= `lb' in `i'
						
						//global ub		= round(`ub', 0.001)
						replace ub		= `ub' in `i'
						
						global count = `N'
						replace count = $count in `i'
						
						count if `var' == 1
						
						global num		= `r(N)'
						replace num		= $num in `i'
					
					}
					
					local i = `i' + 1
					
				}

				//drop if count == 0     //get rid of extra raws - if the variable is empty value, drop
				drop if mi(var_name) //      //get rid of extra raws
				global export_table var_name num mean sd lb ub count

				export excel $export_table using "$out/_fsl_hh/09_sumstat_fsl_creditsave.xls",  sheet("save_`y'_`x'") firstrow(varlabels) sheetreplace 
			
				}
			}
	restore
	}
}

global flitracy	 	fliteracy_income fliteracy_expense fliteracy_loan fliteracy_calinterest fliteracy_borrwloan fliteracy_save fliteracy_expenseplan fliteracy_dk fliteracy_no ///
					fliteracy_incharge_1 fliteracy_incharge_2 fliteracy_incharge_3 fliteracy_incharge_4 fliteracy_incharge_5 fliteracy_incharge_6 ///
					financial_women_part_1 financial_women_part_2 financial_women_part_3 financial_women_short financial_women_long financial_women_overall financial_women_other ///
					wealth_lastyr_cond_1 wealth_lastyr_cond_2 wealth_lastyr_cond_3 wealth_lastyr_cond_4 wealth_lastyr_cond_5


// sample type: benef vs non benef
forvalue x = 0/1 {
	preserve 
	
	keep if source == `x'
	
	if _N > 0 {
	
	keep final_wt $flitracy     
	gen var_name = ""
		label var var_name "   "

	foreach var in num mean sd lb ub count {
		gen `var' = 0
		label var `var' "`var'"
	}
		
	local i = 1
	foreach var of global flitracy {
			
		local label : variable label `var'
		replace var_name = "`label'" in `i'
		
		count if !mi(`var')
		if `r(N)' > 0 {
		
			quietly mean `var' [pw = final_wt]
			local N		= e(N)

			mat A 		= r(table)
			mat li A 	
			local mean 	= (A[1,1])
			local lb 	= (A[5,1])
			local ub 	= (A[6,1])
			
			quietly mean `var' [pw = final_wt]
			estat sd
			mat sd = r(sd)

			global mean 	= round(`mean', 0.001)
			replace mean 	= $mean in `i'
			
			global sd		= (sd[1,1]) // round(`r(se)', 0.001)
			replace sd		= $sd in `i'
			
			//global lb		= round(`lb', 0.001)
			replace lb		= `lb' in `i'
			
			//global ub		= round(`ub', 0.001)
			replace ub		= `ub' in `i'
			
			global count = `N'
			replace count = $count in `i'
			
			count if `var' == 1
			
			global num		= `r(N)'
			replace num		= $num in `i'
		
		}

		
		local i = `i' + 1
		
	}

	//drop if mi(var_name) //      //get rid of extra raws, if the variable is empty still keep it
	drop if count == 0     //get rid of extra raws - if the variable is empty value, drop
	global export_table var_name num mean sd lb ub count

	export excel $export_table using "$out/_fsl_hh/09_sumstat_fsl_creditsave.xls",  sheet("flitracy_`x'") firstrow(varlabels) sheetreplace 	
	
	}
	restore
}


// sample type: benef vs non benef
// hh head gender
				
forvalue y = 0/1 {

	forvalue x = 0/1 {
		preserve 
		
		keep if source == `y'
		
		if _N > 0 {
			
			keep if hh_head_sex == `x'
			
			if _N > 0 {
			
				keep final_wt $flitracy     
				gen var_name = ""
					label var var_name "   "

				foreach var in num mean sd lb ub count {
					gen `var' = 0
					label var `var' "`var'"
				}
					
				local i = 1
				foreach var of global flitracy {
						
					local label : variable label `var'
					replace var_name = "`label'" in `i'
					
					count if !mi(`var')
					if `r(N)' > 0 {
					
						quietly mean `var' [pw = final_wt]
						local N		= e(N)

						mat A 		= r(table)
						mat li A 	
						local mean 	= (A[1,1])
						local lb 	= (A[5,1])
						local ub 	= (A[6,1])
						
						quietly mean `var' [pw = final_wt]
						estat sd
						mat sd = r(sd)

						global mean 	= round(`mean', 0.001)
						replace mean 	= $mean in `i'
						
						global sd		= (sd[1,1]) // round(`r(se)', 0.001)
						replace sd		= $sd in `i'
						
						//global lb		= round(`lb', 0.001)
						replace lb		= `lb' in `i'
						
						//global ub		= round(`ub', 0.001)
						replace ub		= `ub' in `i'
						
						global count = `N'
						replace count = $count in `i'
						
						count if `var' == 1
						
						global num		= `r(N)'
						replace num		= $num in `i'
					
					}
					
					local i = `i' + 1
					
				}

				//drop if count == 0     //get rid of extra raws - if the variable is empty value, drop
				drop if mi(var_name) //      //get rid of extra raws
				global export_table var_name num mean sd lb ub count

				export excel $export_table using "$out/_fsl_hh/09_sumstat_fsl_creditsave.xls",  sheet("flitracy_`y'_`x'") firstrow(varlabels) sheetreplace 
			
				}
			}
	restore
	}
}


**----------------------------------------------------------------------------**
**----------------------------------------------------------------------------**
** ANTHROPOMETRIC **

global boysvy	hhmem_svy_boy boy_incomegen ///
				boy_incomegen_oth_1 boy_incomegen_oth_2 boy_incomegen_oth_3 boy_incomegen_oth_4 boy_incomegen_oth_5 ///
				boy_incomegen_oth_6 boy_incomegen_oth_7 boy_incomegen_oth_8 boy_incomegen_oth_9 boy_incomegen_oth_10 ///
				boy_incomegen_oth_11 boy_incomegen_oth_12 boy_incomegen_oth_13 boy_incomegen_oth_14 boy_incomegen_oth_15 ///
				boy_incomegen_oth_16 boy_incomegen_oth_17 boy_incomegen_oth_18 boy_incomegen_oth_19 boy_incomegen_oth_20 ///
				boy_incomegen_oth_21 boy_incomegen_oth_22 boy_incomegen_oth_23 boy_incomegen_oth_24 ///
				boy_incomegen_obst ///
				boy_incomegen_obst_skills boy_incomegen_obst_capital boy_incomegen_obst_network boy_incomegen_obst_confid ///
				boy_incomegen_obst_safe boy_incomegen_obst_busy boy_incomegen_obst_chores boy_incomegen_obst_parent

					
// sample type: benef vs non benef
forvalue x = 0/1 {
	preserve 
	
	keep if source == `x'
	
	if _N > 0 {
	
	keep final_wt $boysvy     
	gen var_name = ""
		label var var_name "   "

	foreach var in num mean sd lb ub count {
		gen `var' = 0
		label var `var' "`var'"
	}
		
	local i = 1
	foreach var of global boysvy {
			
		local label : variable label `var'
		replace var_name = "`label'" in `i'
		
		count if !mi(`var')
		if `r(N)' > 0 {
		
			quietly mean `var' [pw = final_wt]
			local N		= e(N)

			mat A 		= r(table)
			mat li A 	
			local mean 	= (A[1,1])
			local lb 	= (A[5,1])
			local ub 	= (A[6,1])
			
			quietly mean `var' [pw = final_wt]
			estat sd
			mat sd = r(sd)

			global mean 	= round(`mean', 0.001)
			replace mean 	= $mean in `i'
			
			global sd		= (sd[1,1]) // round(`r(se)', 0.001)
			replace sd		= $sd in `i'
			
			//global lb		= round(`lb', 0.001)
			replace lb		= `lb' in `i'
			
			//global ub		= round(`ub', 0.001)
			replace ub		= `ub' in `i'
			
			global count = `N'
			replace count = $count in `i'
			
			count if `var' == 1
			
			global num		= `r(N)'
			replace num		= $num in `i'
		
		}
		
		local i = `i' + 1
		
	}

	drop if mi(var_name) //      //get rid of extra raws, if the variable is empty still keep it
	//drop if count == 0     //get rid of extra raws - if the variable is empty value, drop
	global export_table var_name num mean sd lb ub count

	export excel $export_table using "$out/_fsl_hh/10_sumstat_fsl_jobobst.xls",  sheet("boysvy_`x'") firstrow(varlabels) sheetreplace 	
	
	}
	restore
}


// sample type: benef vs non benef
// hh head gender
				
forvalue y = 0/1 {

	forvalue x = 0/1 {
		preserve 
		
		keep if source == `y'
		
		if _N > 0 {
			
			keep if hh_head_sex == `x'
			
			if _N > 0 {
			
				keep final_wt $boysvy     
				gen var_name = ""
					label var var_name "   "

				foreach var in num mean sd lb ub count {
					gen `var' = 0
					label var `var' "`var'"
				}
					
				local i = 1
				foreach var of global boysvy {
						
					local label : variable label `var'
					replace var_name = "`label'" in `i'
					
					count if !mi(`var')
					if `r(N)' > 0 {
					
						quietly mean `var' [pw = final_wt]
						local N		= e(N)

						mat A 		= r(table)
						mat li A 	
						local mean 	= (A[1,1])
						local lb 	= (A[5,1])
						local ub 	= (A[6,1])
						
						quietly mean `var' [pw = final_wt]
						estat sd
						mat sd = r(sd)

						global mean 	= round(`mean', 0.001)
						replace mean 	= $mean in `i'
						
						global sd		= (sd[1,1]) // round(`r(se)', 0.001)
						replace sd		= $sd in `i'
						
						//global lb		= round(`lb', 0.001)
						replace lb		= `lb' in `i'
						
						//global ub		= round(`ub', 0.001)
						replace ub		= `ub' in `i'
						
						global count = `N'
						replace count = $count in `i'
						
						count if `var' == 1
						
						global num		= `r(N)'
						replace num		= $num in `i'
					
					}
					
					local i = `i' + 1
					
				}

				//drop if count == 0     //get rid of extra raws - if the variable is empty value, drop
				drop if mi(var_name) //      //get rid of extra raws
				global export_table var_name num mean sd lb ub count

				export excel $export_table using "$out/_fsl_hh/10_sumstat_fsl_jobobst.xls",  sheet("boysvy_`y'_`x'") firstrow(varlabels) sheetreplace 
			
				}
			}
	restore
	}
}



global girlsvy	hhmem_svy_girl girl_incomegen ///
				girl_incomegen_oth_1 girl_incomegen_oth_2 girl_incomegen_oth_3 girl_incomegen_oth_4 girl_incomegen_oth_5 ///
				girl_incomegen_oth_6 girl_incomegen_oth_7 girl_incomegen_oth_8 girl_incomegen_oth_9 girl_incomegen_oth_10 ///
				girl_incomegen_oth_11 girl_incomegen_oth_12 girl_incomegen_oth_13 girl_incomegen_oth_14 girl_incomegen_oth_15 ///
				girl_incomegen_oth_16 girl_incomegen_oth_17 girl_incomegen_oth_18 girl_incomegen_oth_19 girl_incomegen_oth_20 ///
				girl_incomegen_oth_21 girl_incomegen_oth_22 girl_incomegen_oth_23 girl_incomegen_oth_24 ///
				girl_incomegen_obst ///
				girl_incomegen_obst_skills girl_incomegen_obst_capital girl_incomegen_obst_network girl_incomegen_obst_confid ///
				girl_incomegen_obst_safe girl_incomegen_obst_busy girl_incomegen_obst_chores girl_incomegen_obst_parent

// sample type: benef vs non benef
forvalue x = 0/1 {
	preserve 
	
	keep if source == `x'
	
	if _N > 0 {
	
	keep final_wt $girlsvy     
	gen var_name = ""
		label var var_name "   "

	foreach var in num mean sd lb ub count {
		gen `var' = 0
		label var `var' "`var'"
	}
		
	local i = 1
	foreach var of global girlsvy {
			
		local label : variable label `var'
		replace var_name = "`label'" in `i'
		
		count if !mi(`var')
		if `r(N)' > 0 {
		
			quietly mean `var' [pw = final_wt]
			local N		= e(N)

			mat A 		= r(table)
			mat li A 	
			local mean 	= (A[1,1])
			local lb 	= (A[5,1])
			local ub 	= (A[6,1])
			
			quietly mean `var' [pw = final_wt]
			estat sd
			mat sd = r(sd)

			global mean 	= round(`mean', 0.001)
			replace mean 	= $mean in `i'
			
			global sd		= (sd[1,1]) // round(`r(se)', 0.001)
			replace sd		= $sd in `i'
			
			//global lb		= round(`lb', 0.001)
			replace lb		= `lb' in `i'
			
			//global ub		= round(`ub', 0.001)
			replace ub		= `ub' in `i'
			
			global count = `N'
			replace count = $count in `i'
			
			count if `var' == 1
			
			global num		= `r(N)'
			replace num		= $num in `i'
		
		}
		
		local i = `i' + 1
		
	}

	drop if mi(var_name) //      //get rid of extra raws, if the variable is empty still keep it
	//drop if count == 0     //get rid of extra raws - if the variable is empty value, drop
	global export_table var_name num mean sd lb ub count

	export excel $export_table using "$out/_fsl_hh/10_sumstat_fsl_jobobst.xls",  sheet("girlsvy_`x'") firstrow(varlabels) sheetreplace 	
	
	}
	restore
}


// sample type: benef vs non benef
// hh head gender
				
forvalue y = 0/1 {

	forvalue x = 0/1 {
		preserve 
		
		keep if source == `y'
		
		if _N > 0 {
			
			keep if hh_head_sex == `x'
			
			if _N > 0 {
			
				keep final_wt $girlsvy     
				gen var_name = ""
					label var var_name "   "

				foreach var in num mean sd lb ub count {
					gen `var' = 0
					label var `var' "`var'"
				}
					
				local i = 1
				foreach var of global girlsvy {
						
					local label : variable label `var'
					replace var_name = "`label'" in `i'
					
					count if !mi(`var')
					if `r(N)' > 0 {
					
						quietly mean `var' [pw = final_wt]
						local N		= e(N)

						mat A 		= r(table)
						mat li A 	
						local mean 	= (A[1,1])
						local lb 	= (A[5,1])
						local ub 	= (A[6,1])
						
						quietly mean `var' [pw = final_wt]
						estat sd
						mat sd = r(sd)

						global mean 	= round(`mean', 0.001)
						replace mean 	= $mean in `i'
						
						global sd		= (sd[1,1]) // round(`r(se)', 0.001)
						replace sd		= $sd in `i'
						
						//global lb		= round(`lb', 0.001)
						replace lb		= `lb' in `i'
						
						//global ub		= round(`ub', 0.001)
						replace ub		= `ub' in `i'
						
						global count = `N'
						replace count = $count in `i'
						
						count if `var' == 1
						
						global num		= `r(N)'
						replace num		= $num in `i'
					
					}
					
					local i = `i' + 1
					
				}

				//drop if count == 0     //get rid of extra raws - if the variable is empty value, drop
				drop if mi(var_name) //      //get rid of extra raws
				global export_table var_name num mean sd lb ub count

				export excel $export_table using "$out/_fsl_hh/10_sumstat_fsl_jobobst.xls",  sheet("girlsvy_`y'_`x'") firstrow(varlabels) sheetreplace 
			
				}
			}
	restore
	}
}


global mensvy	hhmem_svy_men men_incomegen ///
				men_incomegen_oth_1 men_incomegen_oth_2 men_incomegen_oth_3 men_incomegen_oth_4 men_incomegen_oth_5 ///
				men_incomegen_oth_6 men_incomegen_oth_7 men_incomegen_oth_8 men_incomegen_oth_9 men_incomegen_oth_10 ///
				men_incomegen_oth_11 men_incomegen_oth_12 men_incomegen_oth_13 men_incomegen_oth_14 men_incomegen_oth_15 ///
				men_incomegen_oth_16 men_incomegen_oth_17 men_incomegen_oth_18 men_incomegen_oth_19 men_incomegen_oth_20 ///
				men_incomegen_oth_21 men_incomegen_oth_22 men_incomegen_oth_23 men_incomegen_oth_24 ///
				men_incomegen_obst ///
				men_incomegen_obst_skills men_incomegen_obst_capital men_incomegen_obst_network men_incomegen_obst_confid ///
				men_incomegen_obst_safe men_incomegen_obst_busy men_incomegen_obst_chores men_incomegen_obst_parent

					
// sample type: benef vs non benef
forvalue x = 0/1 {
	preserve 
	
	keep if source == `x'
	
	if _N > 0 {
	
	keep final_wt $mensvy     
	gen var_name = ""
		label var var_name "   "

	foreach var in num mean sd lb ub count {
		gen `var' = 0
		label var `var' "`var'"
	}
		
	local i = 1
	foreach var of global mensvy {
			
		local label : variable label `var'
		replace var_name = "`label'" in `i'
		
		count if !mi(`var')
		if `r(N)' > 0 {
		
			quietly mean `var' [pw = final_wt]
			local N		= e(N)

			mat A 		= r(table)
			mat li A 	
			local mean 	= (A[1,1])
			local lb 	= (A[5,1])
			local ub 	= (A[6,1])
			
			quietly mean `var' [pw = final_wt]
			estat sd
			mat sd = r(sd)

			global mean 	= round(`mean', 0.001)
			replace mean 	= $mean in `i'
			
			global sd		= (sd[1,1]) // round(`r(se)', 0.001)
			replace sd		= $sd in `i'
			
			//global lb		= round(`lb', 0.001)
			replace lb		= `lb' in `i'
			
			//global ub		= round(`ub', 0.001)
			replace ub		= `ub' in `i'
			
			global count = `N'
			replace count = $count in `i'
			
			count if `var' == 1
			
			global num		= `r(N)'
			replace num		= $num in `i'
		
		}
		
		local i = `i' + 1
		
	}

	drop if mi(var_name) //      //get rid of extra raws, if the variable is empty still keep it
	//drop if count == 0     //get rid of extra raws - if the variable is empty value, drop
	global export_table var_name num mean sd lb ub count

	export excel $export_table using "$out/_fsl_hh/10_sumstat_fsl_jobobst.xls",  sheet("mensvy_`x'") firstrow(varlabels) sheetreplace 	
	
	}
	restore
}


// sample type: benef vs non benef
// hh head gender
				
forvalue y = 0/1 {

	forvalue x = 0/1 {
		preserve 
		
		keep if source == `y'
		
		if _N > 0 {
			
			keep if hh_head_sex == `x'
			
			if _N > 0 {
			
				keep final_wt $mensvy     
				gen var_name = ""
					label var var_name "   "

				foreach var in num mean sd lb ub count {
					gen `var' = 0
					label var `var' "`var'"
				}
					
				local i = 1
				foreach var of global mensvy {
						
					local label : variable label `var'
					replace var_name = "`label'" in `i'
					
					count if !mi(`var')
					if `r(N)' > 0 {
					
						quietly mean `var' [pw = final_wt]
						local N		= e(N)

						mat A 		= r(table)
						mat li A 	
						local mean 	= (A[1,1])
						local lb 	= (A[5,1])
						local ub 	= (A[6,1])
						
						quietly mean `var' [pw = final_wt]
						estat sd
						mat sd = r(sd)

						global mean 	= round(`mean', 0.001)
						replace mean 	= $mean in `i'
						
						global sd		= (sd[1,1]) // round(`r(se)', 0.001)
						replace sd		= $sd in `i'
						
						//global lb		= round(`lb', 0.001)
						replace lb		= `lb' in `i'
						
						//global ub		= round(`ub', 0.001)
						replace ub		= `ub' in `i'
						
						global count = `N'
						replace count = $count in `i'
						
						count if `var' == 1
						
						global num		= `r(N)'
						replace num		= $num in `i'
					
					}
					
					local i = `i' + 1
					
				}

				//drop if count == 0     //get rid of extra raws - if the variable is empty value, drop
				drop if mi(var_name) //      //get rid of extra raws
				global export_table var_name num mean sd lb ub count

				export excel $export_table using "$out/_fsl_hh/10_sumstat_fsl_jobobst.xls",  sheet("mensvy_`y'_`x'") firstrow(varlabels) sheetreplace 
			
				}
			}
	restore
	}
}



global womensvy	hhmem_svy_women women_incomegen ///
				women_incomegen_oth_1 women_incomegen_oth_2 women_incomegen_oth_3 women_incomegen_oth_4 women_incomegen_oth_5 ///
				women_incomegen_oth_6 women_incomegen_oth_7 women_incomegen_oth_8 women_incomegen_oth_9 women_incomegen_oth_10 ///
				women_incomegen_oth_11 women_incomegen_oth_12 women_incomegen_oth_13 women_incomegen_oth_14 women_incomegen_oth_15 ///
				women_incomegen_oth_16 women_incomegen_oth_17 women_incomegen_oth_18 women_incomegen_oth_19 women_incomegen_oth_20 ///
				women_incomegen_oth_21 women_incomegen_oth_22 women_incomegen_oth_23 women_incomegen_oth_24 ///
				women_incomegen_obst ///
				women_incomegen_obst_skills women_incomegen_obst_capital women_incomegen_obst_network women_incomegen_obst_confid ///
				women_incomegen_obst_safe women_incomegen_obst_busy women_incomegen_obst_chores women_incomegen_obst_parent

					
// sample type: benef vs non benef
forvalue x = 0/1 {
	preserve 
	
	keep if source == `x'
	
	if _N > 0 {
	
	keep final_wt $womensvy     
	gen var_name = ""
		label var var_name "   "

	foreach var in num mean sd lb ub count {
		gen `var' = 0
		label var `var' "`var'"
	}
		
	local i = 1
	foreach var of global womensvy {
			
		local label : variable label `var'
		replace var_name = "`label'" in `i'
		
		count if !mi(`var')
		if `r(N)' > 0 {
		
			quietly mean `var' [pw = final_wt]
			local N		= e(N)

			mat A 		= r(table)
			mat li A 	
			local mean 	= (A[1,1])
			local lb 	= (A[5,1])
			local ub 	= (A[6,1])
			
			quietly mean `var' [pw = final_wt]
			estat sd
			mat sd = r(sd)

			global mean 	= round(`mean', 0.001)
			replace mean 	= $mean in `i'
			
			global sd		= (sd[1,1]) // round(`r(se)', 0.001)
			replace sd		= $sd in `i'
			
			//global lb		= round(`lb', 0.001)
			replace lb		= `lb' in `i'
			
			//global ub		= round(`ub', 0.001)
			replace ub		= `ub' in `i'
			
			global count = `N'
			replace count = $count in `i'
			
			count if `var' == 1
			
			global num		= `r(N)'
			replace num		= $num in `i'
		
		}
		
		local i = `i' + 1
		
	}

	drop if mi(var_name) //      //get rid of extra raws, if the variable is empty still keep it
	//drop if count == 0     //get rid of extra raws - if the variable is empty value, drop
	global export_table var_name num mean sd lb ub count

	export excel $export_table using "$out/_fsl_hh/10_sumstat_fsl_jobobst.xls",  sheet("womensvy_`x'") firstrow(varlabels) sheetreplace 	
	
	}
	restore
}


// sample type: benef vs non benef
// hh head gender
				
forvalue y = 0/1 {

	forvalue x = 0/1 {
		preserve 
		
		keep if source == `y'
		
		if _N > 0 {
			
			keep if hh_head_sex == `x'
			
			if _N > 0 {
			
				keep final_wt $womensvy     
				gen var_name = ""
					label var var_name "   "

				foreach var in num mean sd lb ub count {
					gen `var' = 0
					label var `var' "`var'"
				}
					
				local i = 1
				foreach var of global womensvy {
						
					local label : variable label `var'
					replace var_name = "`label'" in `i'
					
					count if !mi(`var')
					if `r(N)' > 0 {
					
						quietly mean `var' [pw = final_wt]
						local N		= e(N)

						mat A 		= r(table)
						mat li A 	
						local mean 	= (A[1,1])
						local lb 	= (A[5,1])
						local ub 	= (A[6,1])
						
						quietly mean `var' [pw = final_wt]
						estat sd
						mat sd = r(sd)

						global mean 	= round(`mean', 0.001)
						replace mean 	= $mean in `i'
						
						global sd		= (sd[1,1]) // round(`r(se)', 0.001)
						replace sd		= $sd in `i'
						
						//global lb		= round(`lb', 0.001)
						replace lb		= `lb' in `i'
						
						//global ub		= round(`ub', 0.001)
						replace ub		= `ub' in `i'
						
						global count = `N'
						replace count = $count in `i'
						
						count if `var' == 1
						
						global num		= `r(N)'
						replace num		= $num in `i'
					
					}
					
					local i = `i' + 1
					
				}

				//drop if count == 0     //get rid of extra raws - if the variable is empty value, drop
				drop if mi(var_name) //      //get rid of extra raws
				global export_table var_name num mean sd lb ub count

				export excel $export_table using "$out/_fsl_hh/10_sumstat_fsl_jobobst.xls",  sheet("womensvy_`y'_`x'") firstrow(varlabels) sheetreplace 
			
				}
			}
	restore
	}
}

