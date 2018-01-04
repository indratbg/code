SELECT DISTINCT a.TANGGALTimestamp, a.currency, a.InstructionFrom, a.RDN, c.branch_code, c.client_cd, c.client_name, 
						a.BEGINNINGBALANCE, a.TRANSACTIONVALUE, a.CLOSINGBALANCE , 
					 a.BANKREFERENCE, 'N' Jurnal, b.cnt , 
					a.tanggalefektif, a.bankid, a.transactiontype, 
						 f.descrip TYPETEXT , 
					DECODE(a.InstructionFrom,'0000000000','XXX',f.ip_bank_cd) frombank, 
					a.remark, 'N' default_remark,a.typemutasi 
					FROM( SELECT NVL(bank_ref_num,'X') bank_ref_num, BANK_ACCT_NUM, doc_Date, 
					        sl_acct_cd, 
					                                get_doc_date(1,doc_date) doc_date_min1 
						    FROM T_FUND_MOVEMENT a , MST_CLIENT_FLACCT b 
							WHERE doc_date BETWEEN :from_dt AND :to_dt 
							AND approved_sts <> 'C' 
							AND a.client_Cd = b.client_Cd) d, 
							T_BANK_MUTATION  a, 
							( SELECT BANK_ACCT_NUM, MAX(client_cd) AS client_cd, COUNT(1) AS cnt 
								FROM 	MST_CLIENT_FLACCT 
								WHERE acct_stat <> 'C' 
							GROUP BY BANK_ACCT_NUM) b, 
							( SELECT client_cd, client_name, 
					DECODE(trim(rem_cd),'LOT','LO',DECODE(trim(MST_CLIENT.olt),'N',trim(branch_code),'LO')) branch_finan, 
							 branch_code 
							FROM MST_CLIENT ) c, 
							( 
							SELECT t.rdi_trx_type, t.descrip, t.grp, f.ip_bank_cd, t.db_cr_flg 
							   FROM mst_rdi_trx_type t, MST_FUND_BANK f 
							   WHERE t.fund_bank_cd = f.bank_cd 
							   AND t.grp =:p_type) f 
					WHERE a.TanggalEfektif BETWEEN :from_dt AND :to_dt 
					AND a.InstructionFrom NOT IN (SELECT REPLACE(REPLACE(bank_acct_cd,'-',''),'.','') 
					                                                               FROM MST_BANK_ACCT 
    																			    WHERE  bank_acct_cd <> 'X') 
					AND a.transactiontype LIKE f.rdi_trx_type 
					AND a.typemutasi = f.db_Cr_flg 
					AND b.client_cd = c.client_cd 
					AND a.BANKREFERENCE = d.bank_ref_num(+) 
					AND  d.bank_ref_num IS NULL 
					AND a.rdn = b.BANK_ACCT_NUM 
					AND a.rdn = d.BANK_ACCT_NUM(+) 
					AND d.BANK_ACCT_NUM IS NULL 
					AND a.TanggalEfektif BETWEEN d.doc_date_min1(+) AND d.doc_date(+) 
					AND d.doc_date IS NULL 
					AND a.transactiontype = d.sl_acct_cd(+) 
					AND d.sl_acct_cd IS NULL 
					AND a.transactiontype <> '@IP@' 
					AND (:branch = 'All' 
					     OR  INSTR(:branch,trim(branch_finan)) > 0)
