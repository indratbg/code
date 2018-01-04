create or replace PROCEDURE SPR_VOUCHER_RDI(
  vp_doc_num 			DOCNUM_ARRAY,
  vp_update_date		DATE_ARRAY,
  vp_update_seq			NUMBER_ARRAY,
  vp_approved_status	CHAR,
  vp_user_id			VARCHAR2,
  vp_generate_date 		DATE,
  vo_random_value		OUT NUMBER,
  vo_errcd	 			OUT NUMBER,
  vo_errmsg	 			OUT VARCHAR2
) IS
  v_client_cd		VARCHAR2(12);
  v_update_seq		IPNEXTG.T_MANY_HEADER.update_seq%TYPE;
  v_update_date		IPNEXTG.T_MANY_HEADER.update_date%TYPE;

  vl_random_value	NUMBER(10);
  vl_err			EXCEPTION;
BEGIN
    vl_random_value := abs(dbms_random.random);

   BEGIN
        SP_RPT_REMOVE_RAND('R_FUND_MOVEMENT',vl_random_value,vo_errcd,vo_errmsg);
    EXCEPTION
        WHEN OTHERS THEN
            vo_errcd := -2;
            vo_errmsg := SQLERRM(SQLCODE);
            RAISE vl_err;
    END;
	
	IF vp_approved_status <> 'E' THEN
		FOR i IN 1..vp_doc_num.count LOOP
		
			BEGIN
				INSERT INTO R_FUND_MOVEMENT
				(	
					SELECT t.doc_num,
							t.trx_type, 
							t.doc_date,
							t.client_cd, 
							m.client_name,
							t.remarks,
							t.trx_amt,
							f.bank_acct_fmt as rdn,
							t.from_acct,
							t.to_acct,
							b.bank_name,
							t.acct_name, 
							vl_random_value, 
							vp_user_id, 
							vp_generate_date	
					FROM IPNEXTG.T_FUND_MOVEMENT t 
					JOIN IPNEXTG.MST_CLIENT m ON t.client_cd = m.client_cd
					JOIN IPNEXTG.MST_CLIENT_FLACCT f ON t.client_cd = f.client_cd
					LEFT JOIN 
					(
						SELECT BANK_CD, BANK_NAME
						FROM MST_IP_BANK
						WHERE APPROVED_STAT='A' 
					) b ON NVL(DECODE(trx_type,'W',t.to_bank,t.from_bank),'X') = b.bank_cd	
					WHERE t.doc_num = vp_doc_num(i)
					AND f.acct_stat <> 'C'
				);
			EXCEPTION
				WHEN OTHERS THEN
					vo_errcd := -5;
					vo_errmsg := SQLERRM(SQLCODE);
					RAISE vl_err;
			END;
		
		END LOOP;
		
	ELSE
		FOR i IN 1..vp_update_date.count LOOP
			
			BEGIN
				INSERT INTO R_FUND_MOVEMENT
				(
					SELECT i doc_num,
							t.trx_type, 
							t.doc_date,
							t.client_cd, 
							m.client_name,
							t.remarks,
							t.trx_amt,
							f.bank_acct_fmt as rdn,
							t.from_acct,
							t.to_acct,
							b.bank_name,
							t.acct_name, 
							vl_random_value, 
							vp_user_id, 
							vp_generate_date	
					FROM 
					(
						SELECT MAX(DOC_NUM) DOC_NUM, MAX(TRX_TYPE) TRX_TYPE, TO_DATE(MAX(DOC_DATE),'YYYY-MM-DD HH24:MI:SS') DOC_DATE, MAX(CLIENT_CD) CLIENT_CD,
						MAX(REMARKS) REMARKS, MAX(TRX_AMT) TRX_AMT, MAX(FROM_ACCT) FROM_ACCT, MAX(TO_ACCT) TO_ACCT, MAX(ACCT_NAME) ACCT_NAME, MAX(FROM_BANK) FROM_BANK, MAX(TO_BANK) TO_BANK
						FROM 
						(
							SELECT 	DECODE (field_name, 'DOC_NUM', field_value, NULL) DOC_NUM,
									DECODE (field_name, 'TRX_TYPE', field_value, NULL) TRX_TYPE,
									DECODE (field_name, 'DOC_DATE', field_value, NULL) DOC_DATE,
									DECODE (field_name, 'CLIENT_CD', field_value, NULL) CLIENT_CD,
									DECODE (field_name, 'REMARKS', field_value, NULL) REMARKS,
									DECODE (field_name, 'TRX_AMT', field_value, NULL) TRX_AMT,
									DECODE (field_name, 'FROM_ACCT', field_value, NULL) FROM_ACCT,
									DECODE (field_name, 'TO_ACCT', field_value, NULL) TO_ACCT,
									DECODE (field_name, 'ACCT_NAME', field_value, NULL) ACCT_NAME,
									DECODE (field_name, 'FROM_BANK', field_value, NULL) FROM_BANK,
									DECODE (field_name, 'TO_BANK', field_value, NULL) TO_BANK,
									record_seq
							FROM IPNEXTG.T_MANY_DETAIL 
							WHERE update_date = vp_update_date(i)
							AND update_seq = vp_update_seq(i)
							AND table_name = 'T_FUND_MOVEMENT'
							AND upd_status = 'I'
							AND field_name IN ('DOC_NUM','TRX_TYPE','DOC_DATE','CLIENT_CD','REMARKS','TRX_AMT','FROM_ACCT','TO_ACCT','ACCT_NAME','FROM_BANK','TO_BANK')
						)
						GROUP BY record_seq
					) t 
					JOIN IPNEXTG.MST_CLIENT m ON t.client_cd = m.client_cd
					JOIN IPNEXTG.MST_CLIENT_FLACCT f ON t.client_cd = f.client_cd
					LEFT JOIN 
					(
						SELECT BANK_CD, BANK_NAME
						FROM MST_IP_BANK
						WHERE APPROVED_STAT='A' 
					) b ON NVL(DECODE(trx_type,'W',t.to_bank,t.from_bank),'X') = b.bank_cd		
					AND f.acct_stat <> 'C'
				);
			EXCEPTION
				WHEN OTHERS THEN
					vo_errcd := -10;
					vo_errmsg := SQLERRM(SQLCODE);
					RAISE vl_err;
			END;
			
		END LOOP;
	END IF;

    vo_random_value := vl_random_value;
    vo_errcd := 1;
    vo_errmsg := '';

EXCEPTION
    WHEN vl_err THEN
        ROLLBACK;
        vo_random_value := 0;
        vo_errmsg := SUBSTR(vo_errmsg,1,200);
    WHEN OTHERS THEN
        ROLLBACK;
        vo_random_value := 0;
        vo_errcd := -1;
        vo_errmsg := SUBSTR(SQLERRM(SQLCODE),1,200);
END SPR_VOUCHER_RDI;