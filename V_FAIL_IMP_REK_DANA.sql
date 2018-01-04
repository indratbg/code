
  CREATE OR REPLACE FORCE VIEW "IPNEXTG"."V_FAIL_IMP_REK_DANA" ("CLIENT_CD", "NEW_BANK_CD", "NEW_BANK_ACCT", "NAME", "BANK_NAME", "NEW_ACCT_FMT", "BANK_CD", "BANK_ACCT", "BANK_ACCT_FMT", "FLG", "BALANCE") AS 
  SELECT distinct x.client_Cd, x.bank_Cd new_bank_cd, x.rek_dana new_bank_acct, x.name, x.bank_name, x.bank_acct_fmt new_acct_fmt,
     y.bank_cd, y.bank_acct_num bank_acct, y.bank_acct_fmt, 'N' flg,nvl(f_fund_bal(x.client_Cd,sysdate),0) balance
FROM( SELECT c.client_cd, 
		c.bank_cd bank_cd, 
		c.rek_dana, UPPER(trim(c.name)) name, 
		b.bank_name Bank_name, 
		F_Norek(b.acct_mask,c.rek_dana) AS bank_acct_fmt 
		FROM( SELECT client_Cd, t.bank_cd, t.rek_dana, t.name 
				FROM(  SELECT subrek001, MST_CLIENT.client_cd 
						  FROM MST_CLIENT, v_client_subrek14 
							 WHERE susp_stat = 'N' 
							 AND client_type_1 <> 'B' 
							 AND MST_CLIENT.client_cd = v_client_subrek14.client_cd 
							 AND SUBSTR(subrek001,6,4) <> '0000' 
							 AND subrek001 IS NOT NULL  ) m, 
							T_REK_DANA_KSEI t 
							WHERE t.subrek = m.subrek001 ) c,
			 ( SELECT client_cd, bank_cd, bank_acct_num		 
				 FROM MST_CLIENT_FLACCT
             where approved_stat <>'C' ) f, 
   		  mst_fund_bank b 
		WHERE c.rek_dana = f.bank_acct_num(+) 
		AND f.bank_acct_num IS NULL 
		AND c.bank_Cd= b.bank_Cd ) x,
MST_CLIENT_FLACCT y
WHERE x.client_Cd = y.client_Cd
AND y.acct_stat <> 'C'
AND y.approved_stat <>'C'
order by x.client_cd;
 
