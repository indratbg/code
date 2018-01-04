
  CREATE OR REPLACE FORCE VIEW "IPNEXTG"."V_IMPORT_MUTASI_RDI" ("TANGGALTIMESTAMP", "CURRENCY", "INSTRUCTIONFROM", "RDN", "BRANCH_CODE", "CLIENT_CD", "CLIENT_NAME", "BEGINNINGBALANCE", "TRANSACTIONVALUE", "CLOSINGBALANCE", "BANKREFERENCE", "JURNAL", "CNT", "TANGGALEFEKTIF", "BANKID", "TRANSACTIONTYPE", "TYPETEXT", "FROMBANK", "REMARK", "DEFAULT_REMARK") AS 
  select a.TANGGALTimestamp, a.currency, a.InstructionFrom, a.RDN, c.branch_code, c.client_cd, c.client_name,					
						a.BEGINNINGBALANCE, a.TRANSACTIONVALUE, a.CLOSINGBALANCE ,				
					 a.BANKREFERENCE, 'N' Jurnal, b.cnt ,					
					a.tanggalefektif, a.bankid, a.transactiontype,					
					 decode(a.transactiontype,'NTAX','Tax','NINT','Interest','NKOR','Koreksi','Setoran') TYPETEXT ,					
					decode(a.transactiontype,'NTAX','BCA','NINT','BCA',decode(a.InstructionFrom,'0000000000','XXX','BCA')) frombank,					
					a.remark, 'N' default_remark					
					from( select nvl(bank_ref_num,'X') bank_ref_num, BANK_ACCT_NUM, doc_Date, sl_acct_Cd,					
					                                get_doc_date(1,doc_date) doc_date_min1					
						    from T_fund_movement a , mst_client_flacct b				
							where	
							approved_sts <> 'C'			
							and a.client_Cd = b.client_Cd) d,			
					 		T_bank_mutation a, 			
							( select BANK_ACCT_NUM, max(client_cd) as client_cd, count(1) as cnt			
								from 	mst_client_flacct	
								where acct_stat <> 'C' 		
							group by BANK_ACCT_NUM) b, 			
							( select client_cd, client_name, 			
					decode(trim(rem_cd),'LOT','LO',decode(trim(mst_client.olt),'N',trim(branch_code),'LO')) branch_finan,					
							 branch_code			
							from mst_client ) c			
					where					
					a.InstructionFrom not in (select replace(replace(bank_acct_cd,'-',''),'.','') from MST_BANK_ACCT)					
					and ( (a.TYPEMUTASI = 'C' and a.transactiontype in ('NTRF','NKOR') )					
					       or (a.transactiontype in ('NINT','NTAX') ))					
					and b.client_cd = c.client_cd					
					and a.BANKREFERENCE = d.bank_ref_num(+)					
					and  d.bank_ref_num is null					
					and a.rdn = b.BANK_ACCT_NUM					
					and a.rdn = d.BANK_ACCT_NUM(+)					
					and d.BANK_ACCT_NUM is null					
					AND a.TanggalEfektif BETWEEN d.doc_date_min1(+) AND d.doc_date(+)					
					and d.doc_date is null					
					and a.transactiontype = d.sl_acct_cd(+)					
					and d.sl_acct_cd is null 									
					order by c.branch_code, c.client_cd,  a.TANGGALTimestamp;
 
