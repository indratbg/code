SELECT branch_code, rem_cd, rem_name, client_type_3, 										
client_cd, client_name, stk_cd, onh, 										
cash_dividen as gross, tax_pcn,										
ROUND(tax_pcn * gross,2) tax,										
ROUND(cash_dividen -  round(tax_pcn * gross,2),2) deviden,										
client_type_2, 'Y' flg, client_type_1, NVL(recov_charge_flg,'N') recov_charge_flg										
from(										
SELECT m.branch_code, m.rem_cd, s.rem_name, m.client_type_3, 										
b.client_cd, m.client_name, b.stk_cd, b.onh, decode(:n_pengali,0,0,(b.onh * :n_pengali / :n_pembagi)) div_stk,										
(b.onh * :n_rate + decode(:n_pengali,0,0,trunc(b.onh * :n_pengali / :n_pembagi,0)) * :n_price ) gross, p.tax_pcn,										
b.onh * :n_rate as cash_dividen,										
m.client_type_2,  m.client_type_1, NVL(m.recov_charge_flg,'N') recov_charge_flg  										
FROM(   SELECT client_cd, stk_cd, SUM(beg_onh + mvmt)  onh										
			FROM(  SELECT client_cd, stk_cd, qty as beg_onh, 0 mvmt 							
						FROM T_SECU_BAL 				
					 WHERE bal_dt = :d_bgn_dt					
						AND stk_cd = :s_stk_cd 				
						AND gl_acct_cd in ('35','36') 				
						UNION ALL	  			
				  SELECT client_Cd, stk_cd, 0 beg_onh,  						
						 DECODE(SUBSTR(doc_num,5,3),'JVS',1,'JVB',1,'RSN',1,'WSN',1,0)				
						 * DECODE(db_cr_flg,'D',-1,1) * (total_share_qty + withdrawn_share_qty) mvmt 				
					FROM T_STK_MOVEMENT 					
					  WHERE doc_dt BETWEEN  :d_bgn_dt AND :d_end_dt					
						AND SUBSTR(DOC_NUM,5,3) IN ('RSN','WSN','JVB','JVS')				
						 AND gl_acct_cd IS NOT NULL 				
						 AND gl_acct_cd in ('35','36') 				
						 AND doc_stat = '2' 				
						AND stk_cd = :s_stk_cd ) 				
			GROUP BY client_cd, stk_cd							
			HAVING SUM(beg_onh + mvmt) > 0) b, 							
	(   SELECT client_cd,  TO_NUMBER(tax_rate) / 100 tax_pcn 									
			FROM(   SELECT m.client_cd,   							
								DECODE(a.rate_over25persen,NULL, DECODE(m.rate_no,2,r.rate_2,1,r.rate_1,0), a.rate_over25persen)  tax_rate		
						 FROM( SELECT client_cd, biz_type, npwp_no,				
										 DECODE(SUBSTR(NVL(agreement_no,'123451234123'),6,7),'0000001','H',client_type_1) AS client_type_1,
										  client_type_2,
										  DECODE(npwp_no,NULL,2,1)    
										  * DECODE(biz_type,'PF',0,'FD',0,1)  rate_no
									FROM MST_CLIENT	
									WHERE  client_type_1 <> 'B') m, 	
									( SELECT client_cd, rate_1 AS rate_over25persen	
									  FROM MST_TAX_RATE	
										WHERE :d_end_dt BETWEEN BEGIN_DT AND end_dt
										AND tax_type = 'DIVTAX'
										AND client_cd IS NOT NULL
										AND stk_cd IS NOT NULL
										AND stk_cd = :s_stk_cd ) a,
									( SELECT *	
									  FROM MST_TAX_RATE	
										WHERE :d_end_dt BETWEEN BEGIN_DT AND end_dt
										AND tax_type = 'DIVTAX'
										AND client_cd IS  NULL
										AND stk_cd IS  NULL ) r
							WHERE  m.client_type_2 LIKE r.client_type_2			
							AND m.client_type_1 LIKE r.client_type_1			
							AND m.client_cd = a.client_cd (+))) p,			
		MST_CLIENT m, MST_SALES s 								
		WHERE  b.client_cd = p.client_cd (+) 								
		AND b.client_cd = m.client_cd								
		AND m.branch_code BETWEEN :s_bgn_branch AND :s_end_branch								
		--AND m.rem_cd BETWEEN :s_bgn_rem AND :s_end_rem								
		AND m.client_cd BETWEEN :s_bgn_client AND :s_end_client								
		AND m.rem_cd = s.rem_cd								
		AND b.onh > 0)								
