CREATE DATABASE IF NOT EXISTS CLASES_BD;
USE CLASES_BD;
CREATE USER usuario_tp_bd IDENTIFIED WITH mysql_native_password BY '123456.';
GRANT ALL PRIVILEGES ON *.* TO usuario_tp_bd;

# EJERCICIO 1
# Inciso a
select 
case when age < 20 then '1_<20'
when age >= 20 and age < 35 then '2_20-35'
when age >= 35 and age < 50 then '3_35-50'
when age >= 50 and age < 65 then '4_50-65'
when age >= 65 and age < 70 then '5_65-70'
when age >= 70 then '6_>70' end as age_cat,
sum(housing) as sum_housing_loan,
sum(loan) as sum_personal_loan,
count(ID) as count_id from bank_datos
group by age_cat
order by age_cat;

# Inciso b
select id_default, 
		avg(balance) as avg_balance, 
        min(balance) as min_balance, 
        max(balance) as max_balance 
from bank_datos
where housing = '1' or loan = '1'
group by id_default;

# Inciso c
select bj.job, 
		avg(bd.balance) as avg_balance, 
        sum(bd.loan) as sum_personal_loan,
		sum(bd.housing) as sum_housing_loan,
		sum(case when bd.id_default = 0 then 1 else 0 end) as count_not_def,
		sum(case when bd.id_default = 1 then 1 else 0 end) as count_def
from bank_datos bd

left join bank_job bj
on bd.id_job = bj.id_job

group by bj.job
order by bj.job;

	#Inciso d
	select * from (
	(select bc.contact, bd.month, avg(duration) as avg_duration, sum(campaign) as sum_campaign 
	from bank_datos bd

	left join bank_contact bc
	on bd.id_contact = bc.id_contact

	group by bc.contact, bd.month
	order by bc.contact, bd.month)

	union

	(select bc.contact, 'total' month, avg(duration) as avg_duration, sum(campaign) as sum_campaign 
	from bank_datos bd

	left join bank_contact bc
	on bd.id_contact = bc.id_contact

	group by bc.contact
	order by bc.contact)) tab
	order by tab.contact, tab.month;

#Inciso e
select age_cat,
(sum(case when id_previos_outcome = 1 then 1 else 0 end)/count(id_previos_outcome))*100 as porc_failure,
(sum(case when id_previos_outcome = 2 then 1 else 0 end)/count(id_previos_outcome))*100 as porc_success,
(sum(case when id_previos_outcome = 3 then 1 else 0 end)/count(id_previos_outcome))*100 as porc_othe,
(sum(case when id_previos_outcome = 4 then 1 else 0 end)/count(id_previos_outcome))*100 as porc_unknown
from (
select 
case when age < 20 then '1_<20'
when age >= 20 and age < 35 then '2_20-35'
when age >= 35 and age < 50 then '3_35-50'
when age >= 50 and age < 65 then '4_50-65'
when age >= 65 and age < 70 then '5_65-70'
when age >= 70 then '6_>70' end as age_cat,
bp.poutcome,
bd.id_previos_outcome

from bank_datos bd

left join bank_poutcome bp
on bd.id_previos_outcome = bp.id_poutcome) t1

group by age_cat
order by porc_success desc;

#Inciso f
select age_cat,
		deposit_no/freq_success as prop_no,
		deposit_yes/freq_success as prop_yes 
from(
	select tab2.age_cat, deposit.deposit_no, deposit.deposit_yes, deposit.freq_success from
		(select age_cat,
		(sum(case when id_previos_outcome = 1 then 1 else 0 end)/count(id_previos_outcome))*100 as porc_failure,
		(sum(case when id_previos_outcome = 2 then 1 else 0 end)/count(id_previos_outcome))*100 as porc_success,
		(sum(case when id_previos_outcome = 3 then 1 else 0 end)/count(id_previos_outcome))*100 as porc_other,
		(sum(case when id_previos_outcome = 4 then 1 else 0 end)/count(id_previos_outcome))*100 as porc_unknown
		from (
			select 
			case when age < 20 then '1_<20'
			when age >= 20 and age < 35 then '2_20-35'
			when age >= 35 and age < 50 then '3_35-50'
			when age >= 50 and age < 65 then '4_50-65'
			when age >= 65 and age < 70 then '5_65-70'
			when age >= 70 then '6_>70' end as age_cat,
			bp.poutcome,
			bd.id_previos_outcome

			from bank_datos bd

			left join bank_poutcome bp
			on bd.id_previos_outcome = bp.id_poutcome) t1

		group by age_cat
		order by porc_success desc
		limit 3) tab2

	left join 
	(
		select age_cat,
		sum(case when term_deposit = 0 then 1 else 0 end) as deposit_no,
		sum(case when term_deposit = 1 then 1 else 0 end) as deposit_yes,
		sum(case when id_previos_outcome = 2 then 1 else 0 end) as freq_success
		from(
			select 
			case when age < 20 then '1_<20'
			when age >= 20 and age < 35 then '2_20-35'
			when age >= 35 and age < 50 then '3_35-50'
			when age >= 50 and age < 65 then '4_50-65'
			when age >= 65 and age < 70 then '5_65-70'
			when age >= 70 then '6_>70' end as age_cat,
			byn.yn,
			bd.term_deposit,
			bd.id_previos_outcome

			from bank_datos bd

			left join bank_yn byn
			on bd.term_deposit = byn.id_yn

			left join bank_poutcome bp
			on bd.id_previos_outcome = bp.id_poutcome) tab3

		where id_previos_outcome = 2

		group by age_cat) deposit

	on tab2.age_cat = deposit.age_cat) tab4;

# EJERCICIO 2
#Consulta 1. Proporcion de los créditos que fueron hipotecarios y personales y proporción de defaults y no defaults según nivel educativo.
select be.education, 
	round((sum(bd.housing)/(sum(bd.housing)+sum(bd.loan))),2) as prop_housing_loan, 
	round((sum(bd.loan)/(sum(bd.housing)+sum(bd.loan))),2) as prop_loan,
	round((sum(case when bd.id_default = 0 then 1 else 0 end)/count(bd.id_default)),2) as count_not_def,
	round((sum(case when bd.id_default = 1 then 1 else 0 end)/count(bd.id_default)),2) as count_def
from bank_datos bd

left join bank_education be
on bd.id_education = be.id_education

where bd.housing = 1 or bd.loan = 1
group by be.education;

#Consulta 2. Promedio de días entre la campaña anterior y la actual (para personas ya contactadas), cantidad de contactos previos 
# y actuales y proporción de terminos a depositos suscriptoss según profesión.
select bj.job, 
	avg(bd.pdays) as avg_pdays, 
	sum(previous) as sum_previous, 
	sum(campaign) as sum_camp,
	round((sum(case when bd.term_deposit = 1 then 1 else 0 end)/count(bd.term_deposit)),2) as prop_term_deposit
from bank_datos bd

left join bank_job bj
on bd.id_job = bj.id_job

where pdays != -1
group by bj.job
order by avg_pdays;

