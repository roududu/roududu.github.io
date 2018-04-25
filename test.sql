select
		tb1.city,
		tb1.build_year,
		tb1.plan_amount_lj,
		tb1.actual_amount_lj,
		round(tb1.actual_amount_lj/tb1.plan_amount_lj,4) as lj_rate,
		tb2.plan_amt_m0,
		tb2.repay_amt_m0,
		round(tb2.repay_amt_m0/tb2.plan_amt_m0,4) as m0_rate,
		tb2.plan_amt_m1,
		tb2.repay_amt_m1,
		round(tb2.repay_amt_m1/tb2.plan_amt_m1,4) as m1_rate,
		tb4.valid_app,
		tb4.td_rej,
		round(tb4.td_rej/tb4.valid_app,4) as td_rej_rate
from(
		select		 
				z11.city as city,
				z11.build_year as build_year,
				sum(z11.benjin2)+sum(z11.lixi2) as plan_amount_lj,
				sum(z11.benjin3)+sum(z11.lixi3)  as actual_amount_lj
		from(
			select
				date_format(b0.wo_build_time, '%Y') as build_year,
				a1.app_id, 
				case when dc.group_name like "%旧%" then replace(dc.group_name,"（旧）","") else dc.group_name end as city,
				b21.benjin2,	 
				b22.lixi2,	 
				b31.benjin3,	 
				b32.lixi3	 
			from
				loan_db.t_ind_application a1	 
			left join (
						select	
							app_id,	
							sum(plan_amt) as benjin2
						from	loan_db.t_ind_repayment
						where	sub_code = 101 and plan_date < curdate()
						group by	app_id
						) b21 on a1.app_id = b21.app_id
			left join (
						select	
							app_id,	
							sum(plan_amt) as lixi2
						from	loan_db.t_ind_repayment
						where	sub_code = 102 and plan_date < curdate()
						group by	app_id
						) b22 on a1.app_id = b22.app_id
			left join (
						select		
							app_id,	
							sum(repay_amt) as benjin3
						from	loan_db.t_ind_repayment
						where	sub_code = 101 and plan_date < curdate() and repay_date < curdate()
						group by	app_id
						) b31 on a1.app_id = b31.app_id
			left join (
						select		
							app_id,	
							sum(repay_amt) as lixi3
						from	loan_db.t_ind_repayment
						where	sub_code = 102	and plan_date < curdate() and repay_date < curdate()
						group by	app_id
						) b32 on a1.app_id = b32.app_id
			left join fk_report.st_tanchangde_assist_table_city_m0_m1_repayment_rate b0 on b0.id = a1.order_id
			left join jf_cn.user_group dc on b0.org_code = dc.group_code
		union all
			select
			date_format(b0.wo_build_time, '%Y') as build_year,
			a1.app_id,
			case when dc.group_name like "%旧%" then replace(dc.group_name,"（旧）","") else dc.group_name end as city,	 
			b31.benjin3  as benjin2,
			b32.lixi3  as lixi2,
			b31.benjin3,
			b32.lixi3
			from
				loan_db.t_ind_application_settle a1			 
			left join (
						select
							app_id,
							sum(plan_amt) as benjin2
						from	loan_db.t_ind_repayment_his
						where sub_code = 101 and plan_date < curdate()
						group by app_id
						) b21 on a1.app_id = b21.app_id
			left join (
						select
							app_id,
							sum(plan_amt) as lixi2
						from	loan_db.t_ind_repayment_his
						where	sub_code = 102 and plan_date < curdate()
						group by app_id
						) b22 on a1.app_id = b22.app_id
			left join (
						select
							app_id,
							sum(repay_amt) as benjin3
						from loan_db.t_ind_repayment_his
						where	sub_code = 101 and plan_date < curdate() and repay_date < curdate()
						group by	app_id
						) b31 on a1.app_id = b31.app_id
			left join (
						select
							app_id,
							sum(repay_amt) as lixi3
						from loan_db.t_ind_repayment_his
						where	sub_code = 102 and plan_date < curdate() and repay_date < curdate()
						group by	app_id
						) b32 on a1.app_id = b32.app_id
			left join fk_report.st_tanchangde_assist_table_city_m0_m1_repayment_rate b0 on b0.id = a1.order_id
			left join jf_cn.user_group dc on b0.org_code = dc.group_code
			) z11
		group by z11.city,z11.build_year
	) tb1

left join(
		
		select 
				z21.city as city,		
				z21.build_year,
				sum(z21.plan_amt)+ sum(z21.plan_lx) as plan_amt_m0,
				sum(z21.repay_amt)+ sum(z21.repay_lx) as repay_amt_m0,
				sum(case when z21.overdue_series = 'm1' then z21.plan_amt else 0 end)+sum(case when z21.overdue_series = 'm1' then z21.plan_lx else 0 end) as plan_amt_m1,
				sum(case when z21.overdue_series = 'm1' then z21.repay_amt else 0 end)+sum(case when z21.overdue_series = 'm1' then z21.repay_lx else 0 end) as repay_amt_m1
		from(
				select 
						a01.app_id,			
						date_format(b0.wo_build_time, '%Y') as build_year,
						case when dc.group_name like "%旧%" then replace(dc.group_name,"（旧）","") else dc.group_name end as city,	 
						a01.repay_stage,		 
						a01.plan_date,		 
						a01.plan_amt,		 
						a11.plan_amt as plan_lx,		 
						a02.repay_amt,	 
						a12.repay_amt as repay_lx,	 
						a12.repay_date,		 
						(case 	when ifnull(a12.repay_date,curdate()) between a01.plan_date and date_add(a01.plan_date,interval 1 month) then 'm1'
								else null 
								end) as overdue_series 
				from (
							select 		
									app_id,
									repay_stage,
									plan_amt,
									plan_date 
							from loan_db.t_ind_repayment 
							where sub_code=101 and plan_date<curdate()
							group by app_id,repay_stage
							) a01
				left join (
							select   		 
									app_id,
									repay_stage,
									repay_amt,
									repay_date 
							from loan_db.t_ind_repayment 
							where sub_code=101 and repay_date<curdate() 
							group by app_id,repay_stage
							) a02 on (a02.app_id=a01.app_id and a02.repay_stage=a01.repay_stage)
				left join (
							select 		 
									app_id,
									repay_stage,
									plan_amt,
									plan_date 
							from loan_db.t_ind_repayment 
							where sub_code=102 and plan_date<curdate()
							group by app_id,repay_stage
							) a11 on (a11.app_id=a01.app_id and a11.repay_stage=a01.repay_stage)
				left join (
							select 	  	 
									app_id,
									repay_stage,
									repay_amt,
									repay_date 
							from loan_db.t_ind_repayment 
							where sub_code=102 and repay_date<curdate()
							group by app_id,repay_stage
							) a12 on (a12.app_id=a01.app_id and a12.repay_stage=a01.repay_stage)
				left join loan_db.t_ind_application a3 on a01.app_id=a3.app_id		 
				left join fk_report.st_tanchangde_assist_table_city_m0_m1_repayment_rate b0 on b0.id=a3.order_id				 
				left join jf_cn.user_group dc on b0.org_code=dc.group_code		 
				where  a12.repay_date is null or a12.repay_date >a01.plan_date
				order by a01.app_id,a01.repay_stage
		) z21
		group by z21.city,z21.build_year
	)tb2 on tb1.city = tb2.city and tb1.build_year =tb2.build_year

left join(
			select		
				z41.city,
				z41.build_year,
				ifnull(sum(z41.app),0) as valid_app,
				ifnull(sum(z41.td_rej),0) as td_rej
			from(
				select distinct 
						a.id,		 
						date_format(a.wo_build_time, '%Y') as build_year,
						case when c.group_name like "%旧%" then replace(c.group_name,"（旧）","") else c.group_name end as city,	 
						if(a.app_state in (20,21,30,31,32,35,36,50,80,81,37),1,0) as app,	
						if(b.name in ('拒绝') and d.ret_code in ('RJ27','RJ000003'), 1, 0) as td_rej	 
				from fk_report.st_tanchangde_assist_table_city_m0_m1_repayment_rate a
				left join jf_cn.jj_code b on a.app_state=b.code and groupid='148' 	 
				left join jf_cn.user_group c on a.org_code=c.group_code	 
				left join (	select * from jf_cn.fk_log_auto_checking where id in (select max(id) from jf_cn.fk_log_auto_checking group by app_id)) d on a.id=d.app_id 
				where a.wo_build_time>'2016-04-01'	 
				) z41
			group by z41.city,z41.build_year 
		)tb4 on tb1.city = tb4.city and  tb1.build_year =tb4.build_year
WHERE tb1.city IS NOT NULL
;
