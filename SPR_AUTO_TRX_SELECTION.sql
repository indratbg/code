create or replace PROCEDURE SPR_AUTO_TRX_SELECTION(P_FUND_BANK_CD VARCHAR2,
									P_BRANCH_GRP VARCHAR2,
									P_End_Date Date,
                  vp_doc_num 			DOCNUM_ARRAY,
									P_User_Id Varchar2,
									P_GENERATE_DATE 	DATE,
									P_RANDOM_VALUE	OUT NUMBER,
								   P_ERROR_MSG OUT VARCHAR2,
								   P_ERROR_CD OUT NUMBER) IS


V_ERROR_MSG VARCHAR2(200);
V_ERROR_CD NUMBER(10);
v_random_value	NUMBER(10);
V_ERR EXCEPTION;

 BEGIN
 
   v_random_value := abs(dbms_random.random);

    BEGIN
        SP_RPT_REMOVE_RAND('R_AUTO_TRX_SELECTION',V_RANDOM_VALUE,V_ERROR_MSG,V_ERROR_CD);
    EXCEPTION
        WHEN OTHERS THEN
             V_ERROR_CD := -10;
             V_ERROR_MSG := SUBSTR('SP_RPT_REMOVE_RAND '||V_ERROR_MSG||SQLERRM(SQLCODE),1,200);
            RAISE V_err;
    END;
	
	IF V_ERROR_CD<0 THEN
			V_ERROR_CD := -20;
             V_ERROR_MSG := SUBSTR('SP_RPT_REMOVE_RAND'||V_ERROR_MSG,1,200);
            RAISE V_ERR;
	END IF;
 
 	FOR i IN 1..vp_doc_num.count LOOP
 
	BEGIN 
		INSERT INTO R_AUTO_TRX_SELECTION(BRANCH_CODE,CLIENT_CD, BRCH, RDI_ACCT_NAME,BANK_ACCT_FMT,
										PAYREC_DATE, CURR_AMT, REMARKS,FOLDER_CD, PAYEE_NAME,
										Payee_Acct_Num, Payee_Bank_Cd, Bank_Name, Bank_Branch,
										Trf_Fee, Name_Length, Print_Flg, User_Id, Rand_Value,
										Generate_Date)
		  Select decode(M.brch,M.branch_code,M.branch_code,M.brch)  branch_code, 
      p.client_cd,brch, m.acct_name as rdi_acct_name, m.bank_acct_fmt,			
		  payrec_date,curr_amt, remarks, folder_cd, payee_name, 			
		  payee_acct_num, payee_bank_cd, nvl(v.bank_name,nvl(b.BANK_SHORT_NAME,'-')) as bank_name, nvl(bank_brch_name, '-') bank_branch,		
			trf_fee, decode(payee_bank_cd,'BCA',0,length(payee_name)) as name_length, 1 print_flg, P_USER_ID, V_RANDOM_VALUE,
			P_GENERATE_DATE
	from(  select client_cd, REM_CD,  acct_name, 				
				  bank_acct_fmt,	
				 brch,branch_code	
			from( select mst_client.client_cd, REM_CD,  substr(mst_client_flacct.acct_name,1,35) as acct_name, 		
					mst_client_flacct.bank_acct_fmt,
					decode(trim(mst_client.rem_cd), 'LOT','LOT',
                       decode(trim(mst_client.olt),'N',trim(branch_code),'LOT')) as brch,					
				 trim(branch_code) as branch_code	
				 from mst_client_flacct, mst_client	
				 where mst_client_flacct.client_cd = mst_client.client_cd	
				 and mst_client_flacct.acct_stat <> 'C'	
				 aND mst_client_flacct.bank_cd = P_FUND_BANK_CD)	
			where instr(P_BRANCH_GRP,substr(brch,1,2)) > 0		
			) M,		
		( select payrec_date,payrec_num AS DOC_NUM, T_PAYRECH.client_cd,			
			  curr_amt, deduct_fee as trf_fee,		
 			  remarks, folder_cd,  		
			  q.payee_name, 		
			  q.payee_acct_num, q.payee_bank_cd	   	
		 FROM T_PAYRECH, t_cheq q			
		  WHERE PAYREC_DATE = P_END_DATE			
		and acct_type = 'RDM'			
		and payrec_type in ('PV', 'PD')			
		 and T_PAYRECH.approved_sts <> 'C'			
 		and T_PAYRECH.payrec_num = q.rvpv_number 			
		union all			
		select doc_date,doc_num, client_cd,			
		       trx_amt, fee,			
			   remarks, folder_cd,		
			   acct_name,		
			   to_acct, to_bank		
		from t_fund_movement			
		WHERE Doc_DATE = P_END_DATE			
		and source = 'INPUT'			
		and trx_type = 'W'			
		and to_client = 'LUAR'			
		and approved_sts <> 'C'
    
        UNION ALL
				
				SELECT TO_DATE(MAX(payrec_date),'YYYY/MM/DD HH24:MI:SS'), MAX(payrec_num), MAX(client_cd),
						TO_NUMBER(MAX(curr_amt)), TO_NUMBER(MAX(deduct_fee)),
						MAX(remarks), MAX(folder_cd),
						MAX(payee_name),
						MAX(payee_acct_num), MAX(payee_bank_cd)	
				FROM
				(
					SELECT DECODE (field_name, 'PAYREC_DATE', field_value, NULL) payrec_date,
							DECODE (field_name, 'PAYREC_NUM', field_value, NULL) payrec_num,
							DECODE (field_name, 'CLIENT_CD', field_value, NULL) client_cd,
							DECODE (field_name, 'CURR_AMT', field_value, NULL) curr_amt,
							DECODE (field_name, 'DEDUCT_FEE',field_value, NULL) deduct_fee,
							DECODE (field_name, 'REMARKS',field_value, NULL) remarks,
							DECODE (field_name, 'FOLDER_CD', field_value, NULL) folder_cd,
							DECODE (field_name, 'PAYEE_NAME',field_value, NULL) payee_name,
							DECODE (field_name, 'PAYEE_ACCT_NUM',field_value, NULL) payee_acct_num,
							DECODE (field_name, 'PAYEE_BANK_CD', field_value, NULL) payee_bank_cd,
							DECODE (field_name, 'ACCT_TYPE', field_value, NULL) acct_type,
							DECODE (field_name, 'PAYREC_TYPE', field_value, NULL) payrec_type,
					a.update_seq, a.record_seq
					FROM T_MANY_DETAIL a JOIN T_MANY_HEADER b
					ON a.update_date = b.update_date
					AND a.update_seq = b.update_seq
					WHERE b.approved_status = 'E'
					AND a.table_name IN ('T_PAYRECH','T_CHEQ')
					AND a.upd_status = 'I'
				)
				GROUP BY update_seq, record_seq
				HAVING TO_DATE(MAX(payrec_date),'YYYY/MM/DD HH24:MI:SS') = P_END_DATE
				AND MAX(acct_type) = 'RDM'
				AND MAX(payrec_type) IN ('PV','PD')
		) p,			
		  v_client_bank v,			
		 ( select BANK_CD, BANK_SHORT_NAME			
			from MST_IP_BANK		
			WHERE APPROVED_STAT='A' ) b		
		where p.client_cd = m.client_cd			
		and p.client_cd = v.client_cd(+)			
		and p.payee_acct_num = v.bank_acct_num(+)			
		And P.Payee_Bank_Cd = B.BANK_CD(+)
    AND P.DOC_NUM = vp_doc_num(I);			
								
	 EXCEPTION
			WHEN OTHERS THEN
				 V_ERROR_CD := -30;
				 V_ERROR_MSG := SUBSTR('INSERT R_AUTO_TRX_SELECTION '||V_ERROR_MSG||SQLERRM(SQLCODE),1,200);
				RAISE V_err;
		End;
	END LOOP;
P_RANDOM_VALUE :=V_RANDOM_VALUE;	
P_ERROR_CD := 1 ;
P_ERROR_MSG := '';

 EXCEPTION
  WHEN V_ERR THEN
        ROLLBACK;
        P_ERROR_MSG := V_ERROR_MSG;
		P_ERROR_CD := V_ERROR_CD;
  WHEN OTHERS THEN
   P_ERROR_CD := -1 ;
   P_ERROR_MSG := SUBSTR(SQLERRM(SQLCODE),1,200);
   Raise;
END SPR_AUTO_TRX_SELECTION;