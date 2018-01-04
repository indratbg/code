
  CREATE OR REPLACE FORCE VIEW "IPNEXTG"."V_GENERATE_REPO_INT_JUR" ("REPO_NUM", "REPO_TYPE", "REPO_REF", "CLIENT_CD", "REPO_DATE", "DUE_DATE", "REPO_VAL", "INTEREST_RATE", "DAYS", "INT_AMT", "INT_AFT_TAX", "INT_TAX_AMT", "JUR_FLG", "FOLDER_CD") AS 
  SELECT repo_num, repo_type, repo_ref, 
client_cd,  repo_date, due_date,
repo_val, interest_rate, days,
int_amt, 
round( int_amt / (100 - interest_tax) * 100,0) int_aft_tax,
 round( int_amt / (100 - interest_tax)  * 100,0) - int_amt   AS int_tax_amt,
'Y' jur_flg,
''  folder_cd
FROM(  SELECT a.repo_num, a.repo_type,  a.repo_ref, a.client_cd, 
				a.repo_date, a.due_date,
                a.interest_tax, a.repo_val,a.interest_rate,
				  NVL( B.days,to_date('08/01/2015','dd/mm/yyyy') - a.repo_date) days, 
				  DECODE(to_date('08/01/2015','dd/mm/yyyy'),a.due_date, a.return_val - a.repo_val- NVL(b.accum_int,0),
				 ROUND(NVL(b.days,to_date('08/01/2015','dd/mm/yyyy') - a.repo_date) * a.repo_val * a.interest_rate /100 / 360, 0) ) AS int_amt 
		FROM( SELECT h.repo_num, h.repo_type, d.repo_ref,
				d.repo_date, d.due_date, d.repo_val,  d.return_val, h.client_cd, 
				d.interest_rate,d.interest_tax
				FROM T_REPO h, T_REPO_HIST d
				WHERE h.sett_val > 0
				AND h.sett_val < h.return_val
				AND d.interest_rate > 0
				AND h.repo_num = d.REPO_NUM 
				AND h.extent_dt = d.repo_date  ) a,
( SELECT h.repo_num AS repo_num, 
         SUM(DECODE(t.db_Cr_flg,'D',1,-1) * DECODE( t.doc_date,h.extent_dt,0,t.curr_val))  AS accum_int,
		decode(to_date('08/01/2015','dd/mm/yyyy'),to_date('02/01/2015','dd/mm/yyyy'),to_date('08/01/2015','dd/mm/yyyy') - to_date('01/01/2015','dd/mm/yyyy'), to_date('08/01/2015','dd/mm/yyyy') - NVL(MAX(t.doc_date) , H.extent_dt)) DAYS
	FROM T_REPO h, T_REPO_VCH d, 
		 		T_ACCOUNT_LEDGER t, v_gl_acct_type v 
			WHERE h.sett_val > 0
			AND h.sett_val < h.return_val
			AND h.repo_num = d.REPO_NUM 
			AND  to_date('08/01/2015','dd/mm/yyyy') BETWEEN  h.extent_dt + 1 AND h.due_date 
			AND t.doc_date BETWEEN h.extent_dt AND to_date('08/01/2015','dd/mm/yyyy')
			AND t.approved_sts <> 'C'
			AND t.budget_cd = 'INTREPO'
                                                       and v.acct_type = 'REPO'
			AND t.gl_acct_cd = v.gl_a
			AND t.sl_acct_cd = h.client_cd
			AND t.xn_doc_num = d.doc_num
			GROUP BY  h.repo_num, H.extent_dt) b
WHERE a.repo_num = b.repo_num(+))
where days > 0;
 
