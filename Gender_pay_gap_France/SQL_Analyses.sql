
select * from name_geographic_information ngi2 --give geographic data on french town (mainly latitude and longitude, but also region / department codes and names )
select * from population p -- demographic information in France per town, age, sex and living mode
select * from net_salary_per_town_categories nsptc -- salaries around french town per job categories, age and sex
select * from base_etablissement_par_tranche_effectif bepte --give information on the number of firms in every french town, categorized by siz



-- 1) GEOGRAPHIC INFORMATION


-- check null values in columns which i will use
select *
from name_geographic_information n 
where (n.eu_circo,n.code_région, n.nom_région, n.nom_commune, n.code_insee) is null -- there are no null values

-- sorting by region
select distinct  code_région , eu_circo,nom_région, count(nom_commune) number_of_city
from name_geographic_information ngi 
group by code_région, nom_région , eu_circo 
order by eu_circo 

-- removing overseas regions. I will concentrate only on regions in Metropolitan France
delete from name_geographic_information where 
eu_circo  = 'Outre-Mer'

-- create view
create view v_geographic_info as
select distinct  code_région as region_code, eu_circo,nom_région, count(nom_commune) number_of_city
from name_geographic_information ngi 
group by code_région, nom_région , eu_circo 
order by eu_circo 



-- 2) POPULATION


-- check null values in columns which i will use
select *
from population p 
where (p.codgeo, p.sexe, p.nb) is null


-- number of women and men  due to cardinal and intercardinal directions (geographical location of the region)
select n.code_région, n.nom_région, 
sum(case 
	when p.sexe = 2 then p.nb
	else 0
end) women,
sum(case 
	when p.sexe = 1 then p.nb
	else 0
end) men
from population p 
join name_geographic_information n
on p.codgeo = n.code_insee 
group by n.code_région, n.nom_région 
 -- there are more women in each direction


-- create view 
create view v_population_info as
select n.code_région as region_code, n.nom_région as region_name, 
sum(case 
	when p.sexe = 2 then p.nb
	else 0
end) women,
sum(case 
	when p.sexe = 1 then p.nb
	else 0
end) men
from population p 
join name_geographic_information n
on p.codgeo = n.code_insee 
group by n.code_région, n.nom_région 






-- 3) NUMBER OF FIRMS


-- check null values in columns which i will use
select *
from base_etablissement_par_tranche_effectif b
where (b.codgeo, b.e14tst, b.e14ts0nd, b.e14ts1, b.e14ts6, b.e14ts10, b.e14ts20, 
b.e14ts50, b.e14ts100, b.e14ts200, b.e14ts500) is null

-- number of firms by region (create view)
create view v_firms as
select n.code_région as region_code, n.eu_circo , n.nom_région as region_name, 
sum(b.e14tst) number_of_firms,
sum(b.e14ts0nd) unknown_null_size_firm, -- wiecej niz polowa (od ogolnej sumy) nieznanych firm
sum(b.e14ts1) firms_1_5_employees,
sum(b.e14ts6) firms_6_9_employees,
sum(b.e14ts10) firms_10_19_employees,
sum(b.e14ts20) firms_20_49_employees,
sum(b.e14ts50) firms_50_99__employees,
sum(b.e14ts100) firms_100_199_employees,
sum(b.e14ts200) firms_200_499_employees,
sum(b.e14ts500) firms_500_employees
from base_etablissement_par_tranche_effectif b
join name_geographic_information n
on b.codgeo = n.code_insee 
group by n.code_région, n.eu_circo, n.nom_région 
order by number_of_firms desc


-- creating one table from views
create table region_info as
select g.region_code, g.eu_circo, g.nom_région as region_name, g.number_of_city, p.women, p.men, number_of_firms,  unknown_null_size_firm, firms_1_5_employees,firms_6_9_employees, firms_10_19_employees, firms_20_49_employees,
firms_50_99__employees, firms_100_199_employees, firms_200_499_employees, firms_500_employees
from v_geographic_info g
left join v_population_info p
on g.region_code = p.region_code
left join v_firms f
on p.region_code = f.region_code
order by number_of_city

-- there are no information aboun Corse region
delete from region_info where region_code = 94

select* from region_info



-- 4) SALARY

-- Basic statistict for salary:

select *
from net_salary_per_town_categories n
where (n.codgeo, n.snhm14, n.snhmc14, n.snhmp14, n.snhme14, n.snhmo14, n.snhmf14,
n.snhmfc14,  n.snhmfp14,  n.snhmfe14,  n.snhmfo14,  n.snhmh14,  n.snhmhc14,
 n.snhmhp14,  n.snhmhe14,  n.snhmho14, n.snhm1814, n.snhm2614 , n.snhm5014, 
 n.snhmf1814, n.snhmf2614, n.snhmf5014,n.snhmh1814, n.snhmh2614, n.snhmh5014) is null
 
select g.nom_région , -- by region
mode() within group (order by s.snhm14),
percentile_disc(0.5)  within group (order by s.snhm14),
avg(s.snhm14)
from name_geographic_information g
join net_salary_per_town_categories s 
on g.code_insee  = s.codgeo 
group by g.nom_région 
-- in most regions the mode is close to average

select g.eu_circo, -- due to the geographical location of the region
mode() within group (order by s.snhm14),
percentile_disc(0.5)  within group (order by s.snhm14),
avg(s.snhm14)
from name_geographic_information g
join net_salary_per_town_categories s 
on g.code_insee  = s.codgeo 
group by g.eu_circo  

--  create table: overall average (division into regions)
create table salary as
select n.code_région as region_code, n.eu_circo, n.nom_région as region_name,
min(s.snhm14) minimum,
max(s.snhm14)maximum,
round(avg((s.SNHM14))::numeric, 2) averange_salary,
round(avg((s.snhmf14))::numeric, 2) average_salary_women, 
round(avg((s.snhmh14))::numeric, 2) average_salary_men, 
round(avg((s.snhmh14))::numeric, 2) - round(avg((s.snhmf14))::numeric, 2) average_gender_pay_gap,
round(avg((s.snhmc14))::numeric, 2) average_executive,
round(avg((s.snhmfc14))::numeric, 2) average_women_executive, 
round(avg((s.snhmhc14))::numeric, 2) average_men_executive, 
round(avg((s.snhmhc14))::numeric, 2) - round(avg((s.snhmfc14))::numeric, 2) average_gender_pay_gap_executive,
round(avg((s.snhmp14))::numeric, 2) average_middle_manager,
round(avg((s.snhmfp14))::numeric, 2) average_women_middle_manager, 
round(avg((s.snhmhp14))::numeric, 2) average_men__middle_manager,
round(avg((s.snhmhp14))::numeric, 2) - round(avg((s.snhmfp14))::numeric, 2) average_gender_pay_gap_middle_manager,
round(avg((s.snhme14))::numeric, 2) average_employee,
round(avg((s.snhmfe14))::numeric, 2) average_women_empoyee, 
round(avg((s.snhmhe14))::numeric, 2) average_men_employee,
round(avg((s.snhmhe14))::numeric, 2)  - round(avg((s.snhmfe14))::numeric, 2) average_gender_pay_gap_employee,
round(avg((s.snhmo14))::numeric, 2) average_worker,
round(avg((s.snhmfo14))::numeric, 2) average_women_worker, 
round(avg((s.snhmho14))::numeric, 2) average_men_worker,
round(avg((s.snhmho14))::numeric, 2) - round(avg((s.snhmfo14))::numeric, 2) average_gender_pay_gap_worker,
round(avg((s.snhm1814))::numeric,2) average_18_26, 
round(avg((s.snhmf1814))::numeric,2) average_women18_26, 
round(avg((s.snhmh1814))::numeric,2) average_men18_25, 
round(avg((s.snhm2614))::numeric,2) average_26_50, 
round(avg((s.snhmf2614))::numeric,2) average_women26_50, 
round(avg((s.snhmh2614))::numeric,2) average_men26_50,
round(avg((s.snhm5014))::numeric, 2) average_50_plus,
round(avg((s.snhmf5014))::numeric, 2) average_women50, 
round(avg((s.snhmh5014))::numeric,2) average_men50,
round(avg((s.snhmh1814))::numeric,2) -  round(avg((s.snhmf1814))::numeric,2) gender_pay_gap_18_25, 
round(avg((s.snhmh2614))::numeric,2) - round(avg((s.snhmf2614))::numeric,2) gender_pay_gap_26_50, 
round(avg((s.snhmh5014))::numeric,2) - round(avg((s.snhmf5014))::numeric, 2)gender_pay_gap_50 
from net_salary_per_town_categories s
join name_geographic_information n
on s.codgeo = n.code_insee 
group by n.code_région, n.nom_région, n.eu_circo 
order by averange_salary desc 



-- Analysis



select s.eu_circo, s.region_name , s.averange_salary, s.average_executive, s.average_middle_manager, s.average_employee, s.average_worker 
from salary s
order by s.averange_salary desc
-- emlpoyees earn less then worker

-- gender pay gap per hour
select s.eu_circo, s.region_name , s.averange_salary, s.average_gender_pay_gap, s.average_gender_pay_gap_executive, s.average_gender_pay_gap_middle_manager, 
s.average_gender_pay_gap_employee, s.average_gender_pay_gap_worker 
from salary s
order by s.averange_salary desc

-- monthly gender pay gap: 
--the smallest gender pay gap for employee, the highest for middle manager
--the higher the salary, the higher the difference.
-- higher average in the South West
select s.eu_circo, s.region_name , s.averange_salary*168 as averange_salary , s.average_gender_pay_gap*168 as average_gender_pay_gap, 
s.average_gender_pay_gap_executive*168 as average_gender_pay_gap_executiv, s.average_gender_pay_gap_middle_manager*168 as average_gender_pay_gap_middle_manager, 
s.average_gender_pay_gap_employee*168 as average_gender_pay_gap_employee, s.average_gender_pay_gap_worker*168 as average_gender_pay_gap_worker
from salary s
order by s.averange_salary desc


select s.eu_circo, s.region_name, s.average_salary_women, s.average_salary_men, s.average_women_executive, s.average_men_executive, s.average_women_middle_manager,
s.average_women_empoyee, s.average_men_employee, s.average_women_worker, s.average_men_employee 
from salary s 
 -- for men, pay gap is more visible in different region, while for women it is practically invisible
 -- the largest pay gap between men and women for executive
-- the higher the position, the greater gender pay gap
-- pay gap in regions for executive is about 3-4 euros

select s.eu_circo, s.region_name, s.average_18_26, s.average_26_50, s.average_50_plus 
from salary s 

select s.eu_circo, s.region_name, s.average_women18_26, s.average_men18_25, s.average_women26_50, s.average_men26_50, s.average_women50, s.average_men50,
s.gender_pay_gap_18_25, s.gender_pay_gap_26_50, s.gender_pay_gap_50 
from salary s 
-- Women's wage increases less with age than men's
-- The difference in pay between women aged 18-26 and women aged over 50 is approximately EUR 3, while for men of the same age the difference is approximately EUR 6
-- The pay gap between men and women of the same age only increases with age
-- For men, the pay gap varies more by region, but for women it is virtually invisible.


