/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

PROJECT:		Tat Lan Plus Baseline: Nutrition Report

PURPOSE: 		Food Security & Livelihood Dataset Data Analysis, in-depth

AUTHOR:  		Nicholus

CREATED: 		26 Apr 2020

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

replace geo_type = "0" if geo_type == "Camp"
replace geo_type = "1" if geo_type == "Village"

destring geo_type, replace
lab def geo_typenew 0"Camp" 1"Village"
lab val geo_type geo_typenew
tab geo_type, m

svyset, clear
svyset [pw = final_wt]


**----------------------------------------------------------------------------**
**----------------------------------------------------------------------------**

** HH INFORMATION **

local hhinfo	hh_head_gender_male hh_head_gender_female ///
				hh_type_nodisplace hh_type_idp hh_displace_camp hh_displace_host hh_displace_other ///
				hh_restriction ///
				hh_restriction_1 hh_restriction_2 hh_restriction_3 hh_restriction_4 hh_restriction_5 hh_restriction_6 hh_restriction_7
foreach var in `hhinfo' {
	svy: tab `var' source, col
}


local hhinfo hh_size hhmem_num_male hhmem_num_female

foreach var in `hhinfo' {
	svy: mean `var' , over(source)
	test [`var']_subpop_1 = [`var']_subpop_2
}


**----------------------------------------------------------------------------**
**----------------------------------------------------------------------------**
** FOOD CONSUMPTION SCORE **
local fcs 	 fcs_acceptable fcs_borderline fcs_poor 
foreach var in `fcs' {
	svy: tab `var' source, col
}


local fcs fcs_score fcs_g1 fcs_g2 fcs_g3 fcs_g4 fcs_g5 fcs_g6 fcs_g7 fcs_g8
foreach var in `fcs' {
	svy: mean `var' , over(source)
	test [`var']_subpop_1 = [`var']_subpop_2
}


local fcs 	 fcs_acceptable_fish fcs_borderline_fish fcs_poor_fish	
foreach var in `fcs' {
	svy: tab `var' source, col
}

svy: reg fcs_acceptable_fish source 
svy: reg hhexp_tot_annual source
svy: reg hhexp_tot_annual income_month



local fcs fcs_score_fish fcs_g1_fish fcs_g2_fish fcs_g3_fish fcs_g4_fish fcs_g5_fish fcs_g6_fish fcs_g7_fish fcs_g8_fish
foreach var in `fcs' {
	svy: mean `var' , over(source)
	test [`var']_subpop_1 = [`var']_subpop_2
}

					
**----------------------------------------------------------------------------**
**----------------------------------------------------------------------------**
** HH DIETARY DIVERSITY **
local hhds	hhds_g1 hhds_g2 hhds_g3 hhds_g4 hhds_g5 hhds_g6 hhds_g7 hhds_g8 hhds_g9 hhds_g10 hhds_g11 hhds_g12
foreach var in `hhds' {
	svy: tab `var' source, col
}


local hhds hhds_score
foreach var in `hhds' {
	svy: mean `var' , over(source)
	test [`var']_subpop_1 = [`var']_subpop_2
}

**----------------------------------------------------------------------------**
**----------------------------------------------------------------------------**
** FOOD INSECURITY ACCESS SCALE **

local hfias hfias_level_1 hfias_level_2 hfias_level_3 hfias_level_4
foreach var in `hfias' {
	svy: tab `var' source, col
}


local hfias hfias_score
foreach var in `hfias' {
	svy: mean `var' , over(source)
	test [`var']_subpop_1 = [`var']_subpop_2
}

sum hfias_score [aw = final_wt] if source ==  1, d
sum hfias_score [aw = final_wt] if source ==  0, d

svy: tab hfias_score if source ==  1

**----------------------------------------------------------------------------**
**----------------------------------------------------------------------------**
** FOOD STOCK AND ACCESS TO MARKETS **
				
local market staple_stock
foreach var in `market' {
	svy: mean `var' , over(source)
	test [`var']_subpop_1 = [`var']_subpop_2
}


local market 	market_type_0 market_type_1 market_type_2 ///
				market_dist_1 market_dist_2 market_dist_3 market_dist_4 market_dist_5 market_dist_6 market_dist_7 ///
				market_access_all
				
foreach var in `market' {
	svy: tab `var' source, col
}

**----------------------------------------------------------------------------**
**----------------------------------------------------------------------------**
** LIVELIHOODS AND INCOME SOURCE **

local earner income_month land_measure
foreach var in `earner' {
	svy: mean `var' , over(source)
	test [`var']_subpop_1 = [`var']_subpop_2
}

local earner 	income_earntot income_men_1518 income_men_1924 income_men_over25 income_women_1518 ///
				income_women_1924 income_women_over25 income_girl income_boy ///
				income_youth_tot income_female_tot 
				
foreach var in `earner' {
	svy: mean `var' , over(source)
	test [`var']_subpop_1 = [`var']_subpop_2
}

				
local earner 	income_youth_hh income_female_hh 		
foreach var in `earner' {
	svy: tab `var' source, col
}


local earner	job_main_type_1 job_main_type_2 job_main_type_3 job_main_type_4 job_main_type_5 job_main_type_6 job_main_type_7 ///
				job_main_type_8 job_main_type_9 job_main_type_10 job_main_type_11 job_main_type_12 job_main_type_13 job_main_type_14 ///
				job_main_type_15 job_main_type_16 job_main_type_17 job_main_type_18 job_main_type_19 job_main_type_20 

foreach var in `earner' {
	svy: tab `var' source
}



local earner	land_access land_access_type_1 land_access_type_2 land_access_type_3  ///
				lastyr_crop_paddy lastyr_crop_cereals lastyr_crop_flowers lastyr_crop_veg lastyr_crop_beans ///
				lastyr_crop_fruit lastyr_crop_dhani lastyr_crop_other lastyr_crop_no

foreach var in `earner' {
	svy: tab `var' source, col
}

**----------------------------------------------------------------------------**
**----------------------------------------------------------------------------**
** COPING STRATEGY INDEX - LCSI **

local csi	lcis_secure lcis_stress lcis_crisis lcis_emergency 

foreach var in `csi' {
	svy: tab `var' source, col
}


local migration migration_yn 
foreach var in `migration' {
	svy: tab `var' source, col
}

local migration migrate_temp migrate_longterm
foreach var in `migration' {
	svy: mean `var' , over(source)
	test [`var']_subpop_1 = [`var']_subpop_2
}




**----------------------------------------------------------------------------**
**----------------------------------------------------------------------------**
** HH ASSETS **
		
local hhassets	hh_assets_prodt_yn  
foreach var in `hhassets' {
	svy: tab `var' source, col
}

local hhassets hh_assets_prodt
foreach var in `hhassets' {
	svy: mean `var' , over(source)
	test [`var']_subpop_1 = [`var']_subpop_2
}


local hhassets	livestock_cattle livestock_buffalo livestock_pig livestock_chicken livestock_duck livestock_horse ///
				livestock_goat livestock_no

foreach var in `hhassets' {
	svy: tab `var' source
}


local hhassets	hh_assets_tiller hh_assets_ptiller hh_assets_tractor hh_assets_tlerjee hh_assets_pthresher hh_assets_bpsprayer ///
				hh_assets_storeage hh_assets_drynet hh_assets_pump hh_assets_trailer hh_assets_fishnet hh_assets_sboat ///
				hh_assets_sboat_eng hh_assets_mboat hh_assets_lboat hh_assets_generator hh_assets_bicycle hh_assets_smill ///
				hh_assets_stools hh_assets_tv hh_assets_car hh_assets_cycle hh_assets_bed hh_assets_solor hh_assets_sewing ///
				hh_assets_chainsaw hh_assets_handsaw hh_assets_bankacc hh_assets_sphone hh_assets_kphone hh_assets_radio ///
				hh_assets_dvd hh_assets_fan hh_assets_cabinet hh_assets_jewel 

foreach var in `hhassets' {
	svy: tab `var' source
}




**----------------------------------------------------------------------------**
**----------------------------------------------------------------------------**
** HOUSEHOLD EXPENDITURES **
				
local share		hhexp_food_annual_s hhexp_beverage_annual_s hhexp_health_annual_s hhexp_edu_annual_s ///
				hhexp_allbusi_annual_s hhexp_hhhouse_annual_s hhexp_regpay_annual_s hhexp_debt_annual_s ///
				hhexp_social_annual_s hhexp_lottery_annual_s hhexp_transport_annual_s hhexp_remittance_annual_s
				
foreach var in `share' {
	svy: mean `var' , over(source)
	test [`var']_subpop_1 = [`var']_subpop_2
}


local share 	hhexp_tot_annual ///
				hhexp_food_annual hhexp_beverage_annual hhexp_health_annual hhexp_edu_annual ///
				hhexp_allbusi_annual hhexp_hhhouse_annual hhexp_regpay_annual ///
				hhexp_debt_annual hhexp_social_annual hhexp_lottery_annual ///
				hhexp_transport_annual hhexp_remittance_annual 

foreach var in `share' {
	svy: mean `var' , over(source)
	test [`var']_subpop_1 = [`var']_subpop_2
}


local budget 	hh_financial_1 hh_financial_2 hh_financial_3 hh_financial_4 hh_financial_5 hh_financial_6 ///
				hh_left_money_1 hh_left_money_2 hh_left_money_3 hh_left_money_4 hh_left_money_5 hh_left_money_6 ///
				hh_cover_expend_1 hh_cover_expend_2 hh_cover_expend_3 hh_cover_expend_4 hh_cover_expend_5 hh_cover_expend_6 hh_cover_expend_7 hh_cover_expend_8 ///
				unexpect_yn unexpect_cope_loan unexpect_cope_save unexpect_cope_assist unexpect_cope_sold unexpect_cope_dk unexpect_cope_noans ///
				unexpect_scenario_1 unexpect_scenario_2 unexpect_scenario_3 unexpect_scenario_4 unexpect_scenario_5 unexpect_scenario_6 ///
				
				
foreach var in `budget' {
	svy: mean `var' , over(source)
	test [`var']_subpop_1 = [`var']_subpop_2
}

**----------------------------------------------------------------------------**
**----------------------------------------------------------------------------**
** CREDIT AND SAVINGS **
local loan	loan_yn ///
			loan_source_bank loan_source_mfi loan_source_vsla loan_source_family loan_source_mlender loan_source_shop ///
			loan_source_company loan_source_religious loan_source_seller loan_source_gov loan_source_other ///
			loan_usage_homeimprove loan_usage_homebuy loan_usage_construct loan_usage_landbuy loan_usage_worktools ///
			loan_usage_food loan_usage_agriinouts loan_usage_medic loan_usage_assets loan_usage_weeding loan_usage_health ///
			loan_usage_funeral loan_usage_business loan_usage_loanrepay loan_usage_edu loan_usage_lottery loan_usage_other ///
			hh_debt_now_1 hh_debt_now_2 hh_debt_now_3 hh_debt_now_4 hh_debt_now_5 hh_debt_now_6 hh_debt_now_7 ///
			hh_debt_now_8 hh_debt_now_9 hh_debt_now_10 hh_debt_now_11 hh_debt_now_12 hh_debt_now_13 hh_debt_now_14 ///
			hh_debt_now_15 hh_debt_now_16 hh_debt_now_17 hh_debt_now_18 ///
			hh_debt_lastyr_1 hh_debt_lastyr_2 hh_debt_lastyr_3 hh_debt_lastyr_4 hh_debt_lastyr_5 hh_debt_lastyr_6
			

foreach var in `loan' {
	svy: tab `var' source
}


local save		hh_bankacc_num_yn hh_vsla_mem_num hh_save_yn ///
				hh_saveplace_bank hh_saveplace_mfi hh_saveplace_vsla hh_saveplace_family hh_saveplace_home ///
				hh_saveplace_religious hh_saveplace_gov hh_saveplace_gold hh_saveplace_other hh_saveplace_dk hh_saveplace_noans ///
				hh_save_now_1 hh_save_now_2 hh_save_now_3 hh_save_now_4 hh_save_now_5 hh_save_now_6 hh_save_now_7 ///
				hh_save_now_8 hh_save_now_9 hh_save_now_10 hh_save_now_11 hh_save_now_12 hh_save_now_13 hh_save_now_14 ///
				hh_save_now_15 hh_save_now_16 hh_save_now_17 hh_save_now_18 ///
				hh_save_lastyr_1 hh_save_lastyr_2 hh_save_lastyr_3 hh_save_lastyr_4 hh_save_lastyr_5 hh_save_lastyr_6
	
foreach var in `save' {
	svy: tab `var' source
}

local save		hh_bankacc_num hh_vsla_mem_num  
foreach var in `save' {
	svy: mean `var' , over(source)
	test [`var']_subpop_1 = [`var']_subpop_2
}


local flitracy	 	fliteracy_income fliteracy_expense fliteracy_loan fliteracy_calinterest fliteracy_borrwloan fliteracy_save fliteracy_expenseplan fliteracy_dk fliteracy_no ///
					fliteracy_incharge_1 fliteracy_incharge_2 fliteracy_incharge_3 fliteracy_incharge_4 fliteracy_incharge_5 fliteracy_incharge_6 ///
					financial_women_part_1 financial_women_part_2 financial_women_part_3 financial_women_short financial_women_long financial_women_overall financial_women_other ///
					wealth_lastyr_cond_1 wealth_lastyr_cond_2 wealth_lastyr_cond_3 wealth_lastyr_cond_4 wealth_lastyr_cond_5

foreach var in `flitracy' {
	count if `var' == 1
	if `r(N)'  > 0 {
	svy: tab `var' source
	}
}


**----------------------------------------------------------------------------**
**----------------------------------------------------------------------------**
** DESIRED IGA **

local boysvy	hhmem_svy_boy boy_incomegen ///
				boy_incomegen_oth_1 boy_incomegen_oth_2 boy_incomegen_oth_3 boy_incomegen_oth_4 boy_incomegen_oth_5 ///
				boy_incomegen_oth_6 boy_incomegen_oth_7 boy_incomegen_oth_8 boy_incomegen_oth_9 boy_incomegen_oth_10 ///
				boy_incomegen_oth_11 boy_incomegen_oth_12 boy_incomegen_oth_13 boy_incomegen_oth_14 boy_incomegen_oth_15 ///
				boy_incomegen_oth_16 boy_incomegen_oth_17 boy_incomegen_oth_18 boy_incomegen_oth_19 boy_incomegen_oth_20 ///
				boy_incomegen_oth_21 boy_incomegen_oth_22 boy_incomegen_oth_23 boy_incomegen_oth_24 ///
				boy_incomegen_obst ///
				boy_incomegen_obst_skills boy_incomegen_obst_capital boy_incomegen_obst_network boy_incomegen_obst_confid ///
				boy_incomegen_obst_safe boy_incomegen_obst_busy boy_incomegen_obst_chores boy_incomegen_obst_parent

foreach var in `boysvy' {
	count if `var' == 1
	if `r(N)'  > 0 {
	svy: tab `var' source
	}
}


local girlsvy	hhmem_svy_girl girl_incomegen ///
				girl_incomegen_oth_1 girl_incomegen_oth_2 girl_incomegen_oth_3 girl_incomegen_oth_4 girl_incomegen_oth_5 ///
				girl_incomegen_oth_6 girl_incomegen_oth_7 girl_incomegen_oth_8 girl_incomegen_oth_9 girl_incomegen_oth_10 ///
				girl_incomegen_oth_11 girl_incomegen_oth_12 girl_incomegen_oth_13 girl_incomegen_oth_14 girl_incomegen_oth_15 ///
				girl_incomegen_oth_16 girl_incomegen_oth_17 girl_incomegen_oth_18 girl_incomegen_oth_19 girl_incomegen_oth_20 ///
				girl_incomegen_oth_21 girl_incomegen_oth_22 girl_incomegen_oth_23 girl_incomegen_oth_24 ///
				girl_incomegen_obst ///
				girl_incomegen_obst_skills girl_incomegen_obst_capital girl_incomegen_obst_network girl_incomegen_obst_confid ///
				girl_incomegen_obst_safe girl_incomegen_obst_busy girl_incomegen_obst_chores girl_incomegen_obst_parent

foreach var in `girlsvy' {
	count if `var' == 1
	if `r(N)'  > 0 {
	svy: tab `var' source
	}
}


local mensvy	hhmem_svy_men men_incomegen ///
				men_incomegen_oth_1 men_incomegen_oth_2 men_incomegen_oth_3 men_incomegen_oth_4 men_incomegen_oth_5 ///
				men_incomegen_oth_6 men_incomegen_oth_7 men_incomegen_oth_8 men_incomegen_oth_9 men_incomegen_oth_10 ///
				men_incomegen_oth_11 men_incomegen_oth_12 men_incomegen_oth_13 men_incomegen_oth_14 men_incomegen_oth_15 ///
				men_incomegen_oth_16 men_incomegen_oth_17 men_incomegen_oth_18 men_incomegen_oth_19 men_incomegen_oth_20 ///
				men_incomegen_oth_21 men_incomegen_oth_22 men_incomegen_oth_23 men_incomegen_oth_24 ///
				men_incomegen_obst ///
				men_incomegen_obst_skills men_incomegen_obst_capital men_incomegen_obst_network men_incomegen_obst_confid ///
				men_incomegen_obst_safe men_incomegen_obst_busy men_incomegen_obst_chores men_incomegen_obst_parent

foreach var in `mensvy' {
	count if `var' == 1
	if `r(N)'  > 0 {
	svy: tab `var' source
	}
}


local womensvy	hhmem_svy_women women_incomegen ///
				women_incomegen_oth_1 women_incomegen_oth_2 women_incomegen_oth_3 women_incomegen_oth_4 women_incomegen_oth_5 ///
				women_incomegen_oth_6 women_incomegen_oth_7 women_incomegen_oth_8 women_incomegen_oth_9 women_incomegen_oth_10 ///
				women_incomegen_oth_11 women_incomegen_oth_12 women_incomegen_oth_13 women_incomegen_oth_14 women_incomegen_oth_15 ///
				women_incomegen_oth_16 women_incomegen_oth_17 women_incomegen_oth_18 women_incomegen_oth_19 women_incomegen_oth_20 ///
				women_incomegen_oth_21 women_incomegen_oth_22 women_incomegen_oth_23 women_incomegen_oth_24 ///
				women_incomegen_obst ///
				women_incomegen_obst_skills women_incomegen_obst_capital women_incomegen_obst_network women_incomegen_obst_confid ///
				women_incomegen_obst_safe women_incomegen_obst_busy women_incomegen_obst_chores women_incomegen_obst_parent

foreach var in `womensvy' {
	count if `var' == 1
	if `r(N)'  > 0 {
	svy: tab `var' source
	}
}
