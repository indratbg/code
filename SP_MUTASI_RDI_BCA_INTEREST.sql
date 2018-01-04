create or replace 
PROCEDURE SP_MUTASI_RDI_BCA_INTEREST(--	P_UPDATE_DATE DATE,
											--		P_UPDATE_SEQ NUMBER,
													P_USER_ID VARCHAR2,
													P_IP_ADDRESS VARCHAR2,
													P_MENU_NAME varchar2,
													 P_FROM_DT DATE,
													 P_TO_DT DATE,
													 P_FROM_DT_FUND DATE,
													 P_TO_DT_FUND DATE,
												--	 P_TYPE VARCHAR2,
													 P_BRANCH VARCHAR2,
													 P_BANK_RDI VARCHAR2,
                           p_client_fail out varchar2,
													 P_ERROR_CD OUT NUMBER,
													 P_ERROR_MSG out VARCHAR2
													)
													IS


CURSOR CSR_DATA IS
SELECT X.* FROM (
			SELECT  a.tanggalefektif,  a.TANGGALTimestamp, a.currency, a.InstructionFrom, a.RDN, c.branch_code, c.client_cd, c.client_name,a.namanasabah, 
					a.BEGINNINGBALANCE, a.TRANSACTIONVALUE, a.CLOSINGBALANCE , a.BANKREFERENCE, 'N' Jurnal, b.cnt , 
					a.bankid, a.transactiontype , 	a.remark,a.typemutasi ,b.acct_stat,
			--	 DECODE(a.transactiontype,'NINT',f.ip_bank_cd,'NTAX',f.ip_bank_cd,DECODE(a.InstructionFrom,'0000000000','XXX',f.ip_bank_cd)) frombank 
      P_BANK_RDI frombank
					FROM(SELECT NVL(bank_ref_num,'X') bank_ref_num, fund_bank_acct AS BANK_ACCT_NUM, doc_Date,    sl_acct_cd 
						 FROM T_FUND_MOVEMENT a 
						WHERE doc_date BETWEEN P_FROM_DT_FUND AND  P_TO_DT_FUND
						AND source = 'MUTASI'
						AND approved_sts <> 'C'
						) d, 
					     ( SELECT  a.*  FROM T_BANK_MUTATION a --,
					          --(SELECT REPLACE(REPLACE(bank_acct_cd,'-',''),'.','')  pe_bank_acct
					           --FROM MST_BANK_ACCT WHERE  bank_acct_cd <> 'X') b
					        WHERE a.TanggalEfektif BETWEEN P_FROM_DT AND P_TO_DT
							and a.transactiontype in('NTAX','NINT')
					        --AND a.InstructionFrom = pe_bank_acct(+) AND pe_bank_acct IS NULL
							) a, 
					   (SELECT BANK_ACCT_NUM, MAX(client_cd) AS client_cd, COUNT(1) AS cnt,acct_stat 
						FROM 	MST_CLIENT_FLACCT 
						--WHERE acct_stat <> 'C'
						GROUP BY BANK_ACCT_NUM,acct_stat
						) b, 
					    ( SELECT client_cd, client_name, 
						  DECODE(trim(rem_cd),'LOT','LO',DECODE(trim(MST_CLIENT.olt),'N',trim(branch_code),'LO')) branch_finan, branch_code 
						FROM MST_CLIENT ) c
--					   (SELECT t.rdi_trx_type, t.descrip, t.grp, f.ip_bank_cd, t.db_cr_flg 
--						FROM MST_RDI_TRX_TYPE t, MST_FUND_BANK f 
--						WHERE t.fund_bank_cd = f.bank_cd 
--						AND t.grp = P_TYPE) f 
					WHERE  a.transactiontype in('NINT','NTAX')-- LIKE f.rdi_trx_type 
					--AND a.typemutasi = f.db_Cr_flg 
					AND b.client_cd = c.client_cd 
					AND a.BANKREFERENCE = d.bank_ref_num(+) 
					AND  d.bank_ref_num IS NULL 
					AND a.rdn = b.BANK_ACCT_NUM 
					AND a.rdn = d.BANK_ACCT_NUM(+) 
					AND d.BANK_ACCT_NUM IS NULL 
					
					AND d.doc_date IS NULL 
					AND a.transactiontype = d.sl_acct_cd(+) 
					AND d.sl_acct_cd IS NULL 
					--AND (P_BRANCH = 'All' 
					  --   OR  INSTR(P_BRANCH,trim(branch_finan)) > 0)
               )X
					   where bankid  = P_BANK_RDI  
					 ORDER BY client_cd,tanggaltimestamp DESC ;


V_ERR EXCEPTION;
V_ERROR_CODE NUMBER;
V_ERROR_MSG VARCHAR2(200);
v_record_seq number;
V_MENU_NAME t_many_header.menu_name%type:='UPLOAD RDN MUTATION';
v_update_date t_many_header.update_date%type;
v_update_seq t_many_header.update_seq%type;
v_client_fail varchar(200);
v_client varchar(200):='';
v_num_fail number:=0;
v_remarks varchar2(50);
BEGIN


		--EXECUTE SP HEADER
         BEGIN
        Sp_T_Many_Header_Insert(V_MENU_NAME,
								 'I',
								 P_USER_ID,
								 P_IP_ADDRESS,
								 NULL,
								 V_UPDATE_DATE,
								 V_UPDATE_SEQ,
								 v_error_code,
								 v_error_msg);
        EXCEPTION
              WHEN OTHERS THEN
                 v_error_code := -2;
                 v_error_msg := SUBSTR('SP_T_MANY_HEADER_INSERT '|| SQLERRM(SQLCODE),1,200);
                RAISE V_ERR;
            END;
            
	v_record_seq := 1;
	FOR REC IN CSR_DATA LOOP

IF REC.ACCT_STAT <> 'C' THEN

if rec.transactiontype ='NINT' then
v_remarks :='Bunga BCA' ;
else
v_remarks := 'Tax';
end if;
	BEGIN
	 Sp_MUTASI_RDI_UPD(	rec.client_cd,
						rec.branch_code,
						rec.frombank,
						--NULL,--KODEAB
					--	NULL,--NAMAAB
						rec.rdn,
						--null,--sid
					--	null,--null
						rec.client_name,
						rec.tanggalefektif,
						rec.TANGGALTimestamp,
						rec.instructionfrom,
					--	null,--counterpartaccount
						trim(rec.typemutasi),
						rec.transactiontype,
					--	rec.currency,
				--		rec.BEGINNINGBALANCE,
						rec.TRANSACTIONVALUE,
					--	rec.CLOSINGBALANCE,
						rec.REMARK,
						rec.BANKREFERENCE,
						rec.bankid,
					--	null,--IMPORTSEQ,
					--	null,--IMPORTDATE,
						p_USER_ID,
						'I',--UPD_STATUS,
						p_ip_address,
						null,--cancel_reason,
						v_update_date,
						v_update_seq,
						v_record_seq,
						V_error_code,
						V_error_msg);
	EXCEPTION
		WHEN OTHERS THEN
			v_error_code := -5;
			v_error_msg := SUBSTR('Sp_MUTASI_RDI_UPD '||SQLERRM,1,200);
			RAISE v_err;
	END;
		IF v_error_code < 0 THEN
	    v_error_code := -10;
		v_error_msg := 'Sp_MUTASI_RDI_UPD '||v_error_code||' '||v_error_msg;
		RAISE v_err;
	END IF;
  
	
	BEGIN
	  SP_FL_BCA_INTEREST_APPROVE (rec.tanggalefektif,
								  rec.client_cd,
								  rec.transactiontype,
								   p_menu_name,
								   v_update_date,
								   v_update_seq,
								   p_user_id,
								   p_ip_address,
								   v_error_code,
								   v_error_msg);
	EXCEPTION
		WHEN OTHERS THEN
			v_error_code := -15;
			v_error_msg := SUBSTR('SP_FL_BCA_INTEREST_APPROVE '||SQLERRM,1,200);
			RAISE v_err;
	END;
	IF v_error_code < 0 THEN
	    v_error_code := -20;
		v_error_msg := 'SP_FL_BCA_INTEREST_APPROVE '||v_error_code||' '||v_error_msg;
		RAISE v_err;
	END IF;
  ELSE
    v_client := rec.client_cd ||' , '|| v_client; 
    	v_num_fail :=v_num_fail+1;
		v_client_fail := 'Terdapat '||v_num_fail || ' client yang tidak dijurnal '||v_client;

    
	END IF;
	
	v_record_seq := v_record_seq + 1;
	END LOOP;

P_ERROR_CD := 1;
p_error_msg := '';
p_client_fail := v_client_fail;   
		   
   EXCEPTION
     WHEN NO_DATA_FOUND THEN
       NULL;
	 WHEN v_err THEN
           P_ERROR_CD := v_error_code;
		   p_error_msg :=  v_error_msg;
	      ROLLBACK;
	   
     WHEN OTHERS THEN
       ROLLBACK;
	   P_ERROR_CD := -1;
	   p_error_msg := SUBSTR(SQLERRM,1,200);
       RAISE;
END SP_MUTASI_RDI_BCA_INTEREST;