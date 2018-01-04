create or replace PROCEDURE SP_T_PAYRECH_APPROVE_TEST2
(
   p_menu_name						T_MANY_HEADER.menu_name%TYPE,
   p_update_date					T_MANY_HEADER.update_date%TYPE,
   p_update_seq						T_MANY_HEADER.update_seq%TYPE,
   p_approved_user_id				T_MANY_HEADER.user_id%TYPE,
   p_approved_ip_address 		 	T_MANY_HEADER.ip_address%TYPE,
   p_error_code						OUT NUMBER,
   p_error_msg						OUT VARCHAR2
)
IS

	CURSOR csr_payrec IS
		SELECT DISTINCT record_seq FROM T_MANY_DETAIL 
		WHERE update_date = p_update_date
		AND update_seq = p_update_seq
		AND table_name = 'T_PAYRECD'
		AND field_name = 'RECORD_SOURCE'
		AND field_value NOT IN ('VCH','ARAP');
		
	CURSOR csr_gs1000 IS
		SELECT DISTINCT record_seq FROM T_MANY_DETAIL 
		WHERE update_date = p_update_date
		AND update_seq = p_update_seq
		AND table_name = 'T_PAYRECD'
		AND field_name = 'RECORD_SOURCE'
		AND field_value NOT IN ('VCH','ARAP')
		ORDER BY record_seq;
		
	/*CURSOR csr_payrec IS
		SELECT DISTINCT a.record_seq FROM T_MANY_DETAIL a JOIN T_MANY_DETAIL b
		ON a.update_date = b.update_date
		AND a.update_seq = b.update_seq
		AND a.table_name = b.table_name
		AND a.record_seq = b.record_seq
		WHERE update_date = p_update_date
		AND update_seq = p_update_seq
		AND a.table_name = 'T_PAYRECD'
		AND a.field_name = 'DOC_REF_NUM'
		AND b.field_name = 'PAYREC_NUM'
		AND a.field_value <> b.field_value*/
		
	CURSOR csr_payrec_upd IS -- SUBSTR(PAYREC_NUM) => Swap month and year characters in order to force the MAX function to retrieve the latest payrec_num
		SELECT SUBSTR(MAX(PAYREC_NUM),3,2)||SUBSTR(MAX(PAYREC_NUM),1,2)||SUBSTR(MAX(PAYREC_NUM),5) RVPV_NUMBER, MAX(DOC_REF_NUM) CONTR_NUM, MAX(GL_REF_NUM) GL_REF_NUM, MAX(GL_ACCT_CD) GL_ACCT_CD, MAX(SL_ACCT_CD) SL_ACCT_CD, MAX(DOC_DATE) DOC_DATE, MAX(DUE_DATE) DUE_DATE, MAX(TAL_ID) TAL_ID, MAX(DB_CR_FLG) DB_CR_FLG, MAX(REMARKS) REMARKS, MAX(RECORD_SOURCE) RECORD_SOURCE, SUM(PAYREC_AMT) PAYREC_AMT, MAX(USER_ID) USER_ID
		FROM
		(  
			SELECT SUBSTR(MAX(PAYREC_NUM),3,2)||SUBSTR(MAX(PAYREC_NUM),1,2)||SUBSTR(MAX(PAYREC_NUM),5) PAYREC_NUM, MAX(DOC_REF_NUM) DOC_REF_NUM, MAX(GL_REF_NUM) GL_REF_NUM, MAX(GL_ACCT_CD) GL_ACCT_CD, MAX(SL_ACCT_CD) SL_ACCT_CD, MAX(DOC_DATE) DOC_DATE, MAX(DUE_DATE) DUE_DATE, MAX(TAL_ID) TAL_ID, MAX(DB_CR_FLG) DB_CR_FLG, MAX(REMARKS) REMARKS, MAX(RECORD_SOURCE) RECORD_SOURCE,  DECODE(MAX(UPD_STATUS),'I',MAX(PAYREC_AMT),0 - MAX(PAYREC_AMT)) PAYREC_AMT, MAX(upd_status), MAX(USER_ID) USER_ID
			FROM 
			(
				SELECT 	DECODE (field_name, 'PAYREC_NUM', field_value, NULL) PAYREC_NUM,
						DECODE (field_name, 'DOC_REF_NUM', field_value, NULL) DOC_REF_NUM,
						DECODE (field_name, 'GL_REF_NUM', field_value, NULL) GL_REF_NUM,
						DECODE (field_name, 'GL_ACCT_CD', field_value, NULL) GL_ACCT_CD,
						DECODE (field_name, 'SL_ACCT_CD', field_value, NULL) SL_ACCT_CD,
						DECODE (field_name, 'DOC_DATE', field_value, NULL) DOC_DATE,
						DECODE (field_name, 'DUE_DATE', field_value, NULL) DUE_DATE,
						DECODE (field_name, 'TAL_ID', field_value, NULL) TAL_ID,
						DECODE (field_name, 'DB_CR_FLG', field_value, NULL) DB_CR_FLG,
						DECODE (field_name, 'REMARKS', field_value, NULL) REMARKS,
						DECODE (field_name, 'RECORD_SOURCE', field_value, NULL) RECORD_SOURCE,
						DECODE (field_name, 'PAYREC_AMT', field_value, NULL) PAYREC_AMT,
						DECODE (field_name, 'USER_ID', field_value, NULL) USER_ID,
						upd_status, update_seq, record_seq, field_name
				FROM T_MANY_DETAIL 
				WHERE update_date = p_update_date
				AND update_seq = p_update_seq
				AND table_name = 'T_PAYRECD'
				AND field_name IN ('PAYREC_NUM', 'DOC_REF_NUM', 'GL_REF_NUM', 'GL_ACCT_CD', 'SL_ACCT_CD', 'DOC_DATE', 'DUE_DATE', 'TAL_ID', 'DB_CR_FLG', 'REMARKS', 'RECORD_SOURCE', 'PAYREC_AMT','USER_ID')
			)
			GROUP BY update_seq, record_seq
			HAVING MAX(RECORD_SOURCE) NOT IN ('VCH','ARAP')
--			HAVING MAX(DOC_REF_NUM) <> MAX(PAYREC_NUM)
		)	
		GROUP BY DOC_REF_NUM, TAL_ID;
--		HAVING SUM(PAYREC_AMT) <> 0;


	CURSOR csr_payrec_upd_kpei IS
		SELECT SUBSTR(MAX(PAYREC_NUM),3,2)||SUBSTR(MAX(PAYREC_NUM),1,2)||SUBSTR(MAX(PAYREC_NUM),5) RVPV_NUMBER, MAX(DOC_REF_NUM) CONTR_NUM, MAX(GL_REF_NUM) GL_REF_NUM, MAX(GL_ACCT_CD) GL_ACCT_CD, MAX(SL_ACCT_CD) SL_ACCT_CD, MAX(DOC_DATE) DOC_DATE, MAX(DUE_DATE) DUE_DATE, MAX(TAL_ID) TAL_ID, MAX(DB_CR_FLG) DB_CR_FLG, MAX(REMARKS) REMARKS, MAX(RECORD_SOURCE) RECORD_SOURCE, SUM(PAYREC_AMT) PAYREC_AMT, MAX(USER_ID) USER_ID
		FROM
		(  
			SELECT SUBSTR(MAX(PAYREC_NUM),3,2)||SUBSTR(MAX(PAYREC_NUM),1,2)||SUBSTR(MAX(PAYREC_NUM),5) PAYREC_NUM, MAX(DOC_REF_NUM) DOC_REF_NUM, MAX(GL_REF_NUM) GL_REF_NUM, MAX(GL_ACCT_CD) GL_ACCT_CD, MAX(SL_ACCT_CD) SL_ACCT_CD, MAX(DOC_DATE) DOC_DATE, MAX(DUE_DATE) DUE_DATE, MAX(TAL_ID) TAL_ID, MAX(DB_CR_FLG) DB_CR_FLG, MAX(REMARKS) REMARKS, MAX(RECORD_SOURCE) RECORD_SOURCE,  DECODE(MAX(UPD_STATUS),'I',MAX(PAYREC_AMT),0 - MAX(PAYREC_AMT)) PAYREC_AMT, MAX(upd_status), MAX(USER_ID) USER_ID
			FROM 
			(
				SELECT 	DECODE (field_name, 'PAYREC_NUM', field_value, NULL) PAYREC_NUM,
						DECODE (field_name, 'DOC_REF_NUM', field_value, NULL) DOC_REF_NUM,
						DECODE (field_name, 'GL_REF_NUM', field_value, NULL) GL_REF_NUM,
						DECODE (field_name, 'GL_ACCT_CD', field_value, NULL) GL_ACCT_CD,
						DECODE (field_name, 'SL_ACCT_CD', field_value, NULL) SL_ACCT_CD,
						DECODE (field_name, 'DOC_DATE', field_value, NULL) DOC_DATE,
						DECODE (field_name, 'DUE_DATE', field_value, NULL) DUE_DATE,
						DECODE (field_name, 'TAL_ID', field_value, NULL) TAL_ID,
						DECODE (field_name, 'DB_CR_FLG', field_value, NULL) DB_CR_FLG,
						DECODE (field_name, 'REMARKS', field_value, NULL) REMARKS,
						DECODE (field_name, 'RECORD_SOURCE', field_value, NULL) RECORD_SOURCE,
						DECODE (field_name, 'PAYREC_AMT', field_value, NULL) PAYREC_AMT,
						DECODE (field_name, 'USER_ID', field_value, NULL) USER_ID,
						upd_status, update_seq, record_seq, field_name
				FROM T_MANY_DETAIL 
				WHERE update_date = p_update_date
				AND update_seq = p_update_seq
				AND table_name = 'T_PAYRECD'
				AND field_name IN ('PAYREC_NUM', 'DOC_REF_NUM', 'GL_REF_NUM', 'GL_ACCT_CD', 'SL_ACCT_CD', 'DOC_DATE', 'DUE_DATE', 'TAL_ID', 'DB_CR_FLG', 'REMARKS', 'RECORD_SOURCE', 'PAYREC_AMT','USER_ID')
			)
			GROUP BY update_seq, record_seq
			HAVING MAX(RECORD_SOURCE) NOT IN ('VCH','ARAP')
--			HAVING MAX(DOC_REF_NUM) <> MAX(PAYREC_NUM)
		)	
		GROUP BY GL_ACCT_CD, SL_ACCT_CD, DOC_DATE, DUE_DATE, DB_CR_FLG, REMARKS
		HAVING SUM(PAYREC_AMT) <> 0;

	CURSOR csr_log_blocking_upd IS
		SELECT record_seq FROM T_MANY_DETAIL
		WHERE update_date = p_update_date
		AND update_seq = p_update_seq
		AND table_name = 'T_ACCOUNT_LEDGER'
		AND field_name = 'CASH_WITHDRAW_AMT'
		AND field_value IS NOT NULL;
	
	v_payrec_num					T_PAYRECH.payrec_num%TYPE;
	v_cancelled_payrec_num			T_PAYRECH.payrec_num%TYPE;
	v_acct_type						T_PAYRECH.acct_type%TYPE;
	v_client_cd						T_PAYRECH.client_cd%TYPE;
	v_folder_cd						T_PAYRECH.folder_cd%TYPE;
	v_doc_date						T_PAYRECD.doc_date%TYPE;
	v_due_date						T_PAYRECD.due_date%TYPE;
	v_xn_doc_num 					T_ACCOUNT_LEDGER.xn_doc_num%TYPE;
	v_contr_num 					T_ACCOUNT_LEDGER.xn_doc_num%TYPE;
	v_sl_acct_cd  					T_ACCOUNT_LEDGER.sl_acct_cd%TYPE;
	v_amt        					T_ACCOUNT_LEDGER.curr_val%TYPE;
	v_rvpv_number   				T_ACCOUNT_LEDGER.rvpv_number%TYPE;
	v_gl_ref_num 					T_ACCOUNT_LEDGER.xn_doc_num%TYPE;
	v_gl_acct_cd 					T_ACCOUNT_LEDGER.gl_acct_cd%TYPE;
	v_tal_id     					T_ACCOUNT_LEDGER.tal_id%TYPE;
	v_record_source 				T_ACCOUNT_LEDGER.record_source%TYPE;
	v_user_id						T_ACCOUNT_LEDGER.user_id%TYPE;
	v_type							CHAR(1);
	v_cnt							NUMBER;
	v_reversal						BOOLEAN;
	v_kpei_flg 						BOOLEAN;
	v_next							BOOLEAN;
	v_approved_sts					CHAR(1);
	v_cash_withdraw_reason			T_BLOCKING_LOG.reason%TYPE;
	
	v_max_dt						DATE;
	v_min_dt						DATE;

	v_err 							EXCEPTION;
	v_error_code					NUMBER;
	v_error_msg						VARCHAR2(200);
	v_table_name 					T_MANY_DETAIL.table_name%TYPE := 'T_PAYRECH';
	v_status        		    	T_MANY_DETAIL.upd_status%TYPE;
	v_detail_status					T_MANY_DETAIL.upd_status%TYPE;
	v_table_rowid					T_MANY_DETAIL.table_rowid%TYPE;
BEGIN
	BEGIN
		SELECT STATUS INTO v_status
		FROM T_MANY_HEADER
		WHERE UPDATE_SEQ = p_update_seq
		AND UPDATE_DATE = p_update_date;
	EXCEPTION
		WHEN OTHERS THEN
			v_error_code := -2;
			v_error_msg :=  SUBSTR('Retrieve  T_MANY_HEADER for '||p_update_seq||SQLERRM,1,200);
			RAISE v_err;
	END;
	
	IF v_status IN ('U','C') THEN
		BEGIN
			SELECT field_value INTO v_cancelled_payrec_num
			FROM T_MANY_DETAIL
			WHERE update_date = p_update_date
			AND update_seq = p_update_seq
			AND table_name = v_table_name
			AND field_name = 'PAYREC_NUM'
			AND upd_status = 'C';
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				NULL;
			WHEN OTHERS THEN
				v_error_code := -3;
				v_error_msg :=  SUBSTR('Retrieve  T_MANY_DETAIL for '||p_update_seq||SQLERRM,1,200);
				RAISE v_err;
		END;
		
		IF v_cancelled_payrec_num IS NOT NULL THEN
			BEGIN
				SELECT COUNT(*) INTO v_cnt
				FROM T_ACCOUNT_LEDGER
				WHERE xn_doc_num = v_cancelled_payrec_num
				AND (sett_for_curr > 0 OR sett_val > 0);
			EXCEPTION
				WHEN OTHERS THEN
					v_error_code := -4;
					v_error_msg :=  SUBSTR('Retrieve  T_ACCOUNT_LEDGER for '||v_cancelled_payrec_num||SQLERRM,1,200);
					RAISE v_err;
			END;
			
			IF v_cnt > 0 THEN
				v_error_code := -5;
				v_error_msg := 'Approve voucher '||v_cancelled_payrec_num||' not allowed. This voucher has already been settled';
				RAISE v_err;
			END IF;
		END IF;
	END IF;
	
	BEGIN
		SELECT SUBSTR(FIELD_VALUE,6,1) INTO v_type
		FROM T_MANY_DETAIL
		WHERE UPDATE_DATE = p_update_date
		AND UPDATE_SEQ = p_update_seq
		AND TABLE_NAME = v_table_name
		AND FIELD_NAME = 'PAYREC_NUM'
		AND RECORD_SEQ = 1;
	EXCEPTION
		WHEN OTHERS THEN
			v_error_code := -6;
			v_error_msg :=  SUBSTR('Retrieve  T_MANY_DETAIL for '||p_update_seq||SQLERRM,1,200);
			RAISE v_err;
	END;
	
	BEGIN
		SELECT COUNT(*) INTO v_cnt
		FROM T_MANY_DETAIL
		WHERE UPDATE_DATE = p_update_date
		AND UPDATE_SEQ = p_update_seq
		AND TABLE_NAME = v_table_name
		AND UPD_STATUS = 'C';
	EXCEPTION
		WHEN OTHERS THEN
			v_error_code := -7;
			v_error_msg :=  SUBSTR('Retrieve  T_MANY_DETAIL for '||p_update_seq||SQLERRM,1,200);
			RAISE v_err;
	END;
	
	IF v_cnt > 0 THEN
		v_reversal := TRUE;
	ELSE
		v_reversal := FALSE;
	END IF;
	
	BEGIN
		SELECT COUNT(*) INTO v_cnt
		FROM T_MANY_DETAIL
		WHERE update_date = p_update_date
		AND update_seq = p_update_seq
		AND table_name = 'T_PAYRECH'
		AND field_name = 'ACCT_TYPE'
		AND field_value = 'KPEI'
		AND RECORD_SEQ = 1;
	EXCEPTION
		WHEN OTHERS THEN
			v_error_code := -8;
			v_error_msg :=  SUBSTR('Retrieve  T_MANY_DETAIL for '||p_update_seq||SQLERRM,1,200);
			RAISE v_err;
	END;
	
	IF v_cnt > 0 THEN
		v_kpei_flg := TRUE;
	ELSE
		v_kpei_flg := FALSE;
	END IF;
	
	BEGIN
		SELECT FIELD_VALUE INTO v_rvpv_number
		FROM T_MANY_DETAIL
		WHERE update_date = p_update_date
		AND update_seq = p_update_seq
		AND table_name = 'T_PAYRECH'
		AND field_name = 'PAYREC_NUM'
		AND RECORD_SEQ = 1;
	EXCEPTION
		WHEN OTHERS THEN
			v_error_code := -9;
			v_error_msg :=  SUBSTR('Retrieve  T_MANY_DETAIL for '||p_update_seq||SQLERRM,1,200);
			RAISE v_err;
	END;
	
	BEGIN
		SELECT NVL(field_value,'X') INTO v_acct_type
		FROM T_MANY_DETAIL
		WHERE update_date = p_update_date
		AND update_seq = p_update_seq
		AND table_name = 'T_PAYRECH'
		AND field_name = 'ACCT_TYPE'
		AND RECORD_SEQ = 1;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			v_acct_type := 'X';
			
		WHEN OTHERS THEN
			v_error_code := -10;
			v_error_msg :=  SUBSTR('Retrieve  T_MANY_DETAIL for '||p_update_seq||SQLERRM,1,200);
			RAISE v_err;
	END;
	
	IF v_acct_type NOT IN ('GSJK','GSSL') THEN
		IF v_type = 'V' THEN
			--Transaction
			IF v_status <> 'U' THEN
				-- INSERT OR CANCEL
				FOR rec IN csr_payrec LOOP			
					BEGIN
						SELECT MAX(DOC_REF_NUM), MAX(SL_ACCT_CD), MAX(PAYREC_AMT), MAX(GL_REF_NUM), MAX(GL_ACCT_CD), MAX(TAL_ID), MAX(RECORD_SOURCE), MAX(DOC_DATE), MAX(DUE_DATE), MAX(USER_ID), MAX(UPD_STATUS)
						INTO v_contr_num, v_sl_acct_cd, v_amt, v_gl_ref_num, v_gl_acct_cd, v_tal_id, v_record_source, v_doc_date, v_due_date, v_user_id, v_detail_status
						FROM
						(
							SELECT DECODE(field_name,'DOC_REF_NUM',field_value, NULL) DOC_REF_NUM,
								   DECODE(field_name,'SL_ACCT_CD',field_value, NULL) SL_ACCT_CD,
								   DECODE(field_name,'PAYREC_AMT',field_value, NULL) PAYREC_AMT,
		--						   DECODE(field_name,'PAYREC_NUM',field_value, NULL) PAYREC_NUM,
								   DECODE(field_name,'GL_REF_NUM',field_value, NULL) GL_REF_NUM,
								   DECODE(field_name,'GL_ACCT_CD',field_value, NULL) GL_ACCT_CD,
								   DECODE(field_name,'TAL_ID',field_value, NULL) TAL_ID,
								   DECODE(field_name,'RECORD_SOURCE',field_value, NULL) RECORD_SOURCE,
								   DECODE(field_name,'DOC_DATE',TO_DATE(field_value,'YYYY-MM-DD HH24:MI:SS'), NULL) DOC_DATE,
								   DECODE(field_name,'DUE_DATE',TO_DATE(field_value,'YYYY-MM-DD HH24:MI:SS'), NULL) DUE_DATE,
								   DECODE(field_name,'USER_ID',field_value, NULL) USER_ID,
								   DECODE(UPD_STATUS,'I','I','C') UPD_STATUS
							FROM  T_MANY_DETAIL
							WHERE T_MANY_DETAIL.update_date = p_update_date
							AND T_MANY_DETAIL.update_seq = p_update_seq
							AND T_MANY_DETAIL.table_name = 'T_PAYRECD'
							AND T_MANY_DETAIL.record_seq = rec.record_seq
							AND T_MANY_DETAIL.field_name IN ('DOC_REF_NUM', 'SL_ACCT_CD', 'PAYREC_AMT','GL_REF_NUM','GL_ACCT_CD','TAL_ID','RECORD_SOURCE','DOC_DATE','DUE_DATE','USER_ID')
						);
					EXCEPTION
						WHEN OTHERS THEN
							v_error_code := -11;
							v_error_msg :=  SUBSTR('Retrieve  T_MANY_DETAIL '||SQLERRM,1,200);
							RAISE v_err;
					END;
					
					IF v_record_source = 'CG' OR v_record_source = 'CDUE' THEN
						BEGIN
							UPDATE T_CONTRACTS
							SET sett_for_curr = DECODE(v_detail_status,'I',sett_for_curr - v_amt, sett_for_curr),
							sett_curr_min = DECODE(v_detail_status,'C', sett_curr_min - v_amt, sett_curr_min),
							sett_val = DECODE(v_detail_status,'I', NVL(sett_val,0) + v_amt, sett_val - v_amt),
							rvpv_number = DECODE(v_detail_status,'I',v_rvpv_number,NULL),
							upd_dt        = SYSDATE,
							upd_by      = v_user_id
							WHERE contr_num = v_contr_num;
						EXCEPTION
							WHEN OTHERS THEN
								v_error_code := -12;
								v_error_msg :=  SUBSTR('Update  T_CONTRACTS '||SQLERRM,1,200);
								RAISE v_err;
						END;

						IF SUBSTR(v_contr_num,6,1) = 'I' OR  v_record_source = 'CDUE' THEN
						-- TITIP JUAL/ BELI CONTRACT
							BEGIN
								UPDATE T_ACCOUNT_LEDGER
								SET sett_for_curr = DECODE(v_detail_status,'I',sett_for_curr - v_amt, sett_for_curr),
								sett_curr_min = DECODE(v_detail_status,'C', sett_curr_min - v_amt, sett_curr_min),
								sett_val = DECODE(v_detail_status,'I', NVL(sett_val,0) + v_amt, sett_val - v_amt),
								rvpv_number = DECODE(v_detail_status,'I',v_rvpv_number,NULL),
								upd_dt        = SYSDATE,
								upd_by       = v_user_id
								WHERE xn_doc_num = v_gl_ref_num
								AND doc_ref_num = v_contr_num
								AND TRIM(gl_acct_cd) = TRIM(v_gl_acct_cd)
								AND sl_Acct_cd = v_sl_acct_cd;
							EXCEPTION
								WHEN OTHERS THEN
									v_error_code := -13;
									v_error_msg :=  SUBSTR('Update  T_ACCOUNT_LEDGER '||SQLERRM,1,200);
									RAISE v_err;
							 END;
					
						ELSE
						-- REGULAR CONTRACT
							BEGIN
								UPDATE T_ACCOUNT_LEDGER
								SET sett_for_curr = DECODE(v_detail_status,'I',sett_for_curr - v_amt, sett_for_curr),
								sett_curr_min = DECODE(v_detail_status,'C', sett_curr_min - v_amt, sett_curr_min),
								sett_val = DECODE(v_detail_status,'I', NVL(sett_val,0) + v_amt, sett_val - v_amt),
								rvpv_number = DECODE(v_detail_status,'I',v_rvpv_number,NULL),
								upd_dt        = SYSDATE,
								upd_by       = v_user_id
								WHERE xn_doc_num = v_contr_num
								AND record_source = 'CG'
								AND TRIM(gl_acct_cd) = TRIM(v_gl_acct_cd)
								AND sl_Acct_cd = v_sl_acct_cd;
							EXCEPTION
								WHEN OTHERS THEN
									v_error_code := -14;
									v_error_msg :=  SUBSTR('Update  T_ACCOUNT_LEDGER '||SQLERRM,1,200);
									RAISE v_err;
								END;
						END IF;
					
					ELSIF v_record_source = 'KPEI'  THEN
						BEGIN
							UPDATE T_ACCOUNT_LEDGER
							SET sett_for_curr = DECODE(v_detail_status,'I',sett_for_curr - curr_val, sett_for_curr),
							sett_curr_min = DECODE(v_detail_status,'C', sett_curr_min - curr_val, sett_curr_min),
							sett_val = DECODE(v_detail_status,'I', NVL(sett_val,0) + curr_val, sett_val - curr_val),
							rvpv_number = DECODE(v_detail_status,'I',v_rvpv_number,NULL),
							upd_dt        = SYSDATE
							WHERE doc_date = v_doc_date
							AND due_date = v_due_date
							AND trim(gl_acct_cd) = trim(v_gl_acct_cd)
							AND sl_acct_cd = v_sl_acct_cd
							AND record_source = 'CG' 
							AND reversal_jur = 'N' 
							AND approved_sts = 'A';
						EXCEPTION
							WHEN OTHERS THEN
								v_error_code := -15;
								v_error_msg :=  SUBSTR('Update  T_ACCOUNT_LEDGER '||SQLERRM,1,200);
								RAISE v_err;
						END;
						
					ELSIF  v_record_source = 'NEGO' THEN
						BEGIN
							UPDATE T_ACCOUNT_LEDGER
							SET sett_for_curr = DECODE(v_detail_status,'I',sett_for_curr - v_amt, sett_for_curr),
							sett_curr_min = DECODE(v_detail_status,'C', sett_curr_min - v_amt, sett_curr_min),
							sett_val = DECODE(v_detail_status,'I', NVL(sett_val,0) + v_amt, sett_val - v_amt),
							rvpv_number = DECODE(v_detail_status,'I',v_rvpv_number,NULL),
							upd_dt        = SYSDATE
							WHERE doc_date = v_doc_date
							AND xn_doc_num = v_contr_num
							AND record_source = 'CG'
							AND trim(gl_acct_cd) = trim(v_gl_acct_cd)
							AND sl_acct_cd = v_sl_acct_cd;
						EXCEPTION
							WHEN OTHERS THEN
								v_error_code := -16;
								v_error_msg :=  SUBSTR('Update  T_ACCOUNT_LEDGER '||SQLERRM,1,200);
								RAISE v_err;
						END;
						
						BEGIN
							UPDATE T_PAYRECD
							SET sett_for_curr = DECODE(v_detail_status,'I',sett_for_curr - v_amt, sett_for_curr),
							sett_curr_min = DECODE(v_detail_status,'C', sett_curr_min - v_amt, sett_curr_min),
							sett_val = DECODE(v_detail_status,'I', NVL(sett_val,0) + v_amt, sett_val - v_amt),
							upd_dt        = SYSDATE,
							upd_by       = v_user_id
							WHERE payrec_num  = v_contr_num
							AND record_source = 'ARAP'
							AND tal_id      = v_tal_id;
						EXCEPTION
							WHEN OTHERS THEN
								v_error_code := -17;
								v_error_msg :=  SUBSTR('Update  T_PAYRECD '||SQLERRM,1,200);
								RAISE v_err;
						END;
						
					ELSIF  v_record_source = 'BOND' THEN
						BEGIN
							UPDATE T_BOND_TRX
							SET sett_for_curr = DECODE(v_detail_status,'I',sett_for_curr - v_amt, sett_for_curr),
							sett_curr_min = DECODE(v_detail_status,'C', sett_curr_min - v_amt, sett_curr_min),
							sett_val = DECODE(v_detail_status,'I', NVL(sett_val,0) + v_amt, sett_val - v_amt),
							rvpv_number = DECODE(v_detail_status,'I',v_rvpv_number,NULL),
							upd_dt        = SYSDATE
							WHERE trx_date = v_doc_date
							AND doc_num = v_contr_num;
						EXCEPTION
							WHEN OTHERS THEN
								v_error_code := -18;
								v_error_msg :=  SUBSTR('Update  T_BOND_TRX '||SQLERRM,1,200);
								RAISE v_err;
						END;
						
						/*BEGIN
							UPDATE  T_ACCOUNT_LEDGER
							SET sett_for_curr = DECODE(v_detail_status,'I',sett_for_curr - v_amt, sett_for_curr),
							sett_curr_min = DECODE(v_detail_status,'C', sett_curr_min - v_amt, sett_curr_min),
							sett_val = DECODE(v_detail_status,'I', NVL(sett_val,0) + v_amt, sett_val - v_amt),
							rvpv_number = DECODE(v_detail_status,'I',v_rvpv_number,NULL),
							upd_dt        =  SYSDATE
							WHERE  doc_date =  v_doc_date
							AND  xn_doc_num  =  v_contr_num
							AND  gl_acct_cd =  RPAD(trim(v_gl_acct_cd),12)
							AND  sl_acct_cd =  v_sl_acct_cd;
						EXCEPTION
							WHEN OTHERS THEN
								v_error_code := -15;
								v_error_msg :=  SUBSTR('Update  T_ACCOUNT_LEDGER '||SQLERRM,1,200);
								RAISE v_err;
						END;*/
							
					ELSE
			 --- for DNCN  / RD PD / RVO /PVO
						BEGIN
							UPDATE T_ACCOUNT_LEDGER
							SET sett_for_curr = DECODE(v_detail_status,'I',sett_for_curr - v_amt, sett_for_curr),
							sett_curr_min = DECODE(v_detail_status,'C', sett_curr_min - v_amt, sett_curr_min),
							sett_val = DECODE(v_detail_status,'I', NVL(sett_val,0) + v_amt, sett_val - v_amt),
							rvpv_number = DECODE(v_detail_status,'I',v_rvpv_number,NULL),
							upd_dt        = SYSDATE,
							upd_by       = v_user_id
							WHERE xn_doc_num = v_gl_ref_num
							AND TRIM(gl_Acct_cd) = TRIM(v_gl_acct_cd)
							AND sl_Acct_cd = v_sl_acct_cd
							AND tal_id = v_tal_id;
						EXCEPTION
							WHEN OTHERS THEN
								v_error_code := -19;
								v_error_msg :=  SUBSTR('Update  T_ACCOUNT_LEDGER '||SQLERRM,1,200);
								RAISE v_err;
						END;
						
						IF v_record_source = 'PDRD' THEN 					
							BEGIN
								UPDATE T_PAYRECD
								SET sett_for_curr = DECODE(v_detail_status,'I',sett_for_curr - v_amt, sett_for_curr),
								sett_curr_min = DECODE(v_detail_status,'C', sett_curr_min - v_amt, sett_curr_min),
								sett_val = DECODE(v_detail_status,'I', NVL(sett_val,0) + v_amt, sett_val - v_amt),
								upd_dt        = SYSDATE,
								upd_by       = v_user_id
								WHERE payrec_num  = v_contr_num
								AND( record_source = 'ARAP' OR record_source = 'VCH')
								AND tal_id      = v_tal_id;
							EXCEPTION
								WHEN OTHERS THEN
									v_error_code := -20;
									v_error_msg :=  SUBSTR('Update  T_PAYRECD '||SQLERRM,1,200);
									RAISE v_err;
							END;
						END IF;
					END IF;
				END LOOP;
			ELSE
				-- UPDATE
				IF v_reversal = TRUE THEN
					IF v_kpei_flg = TRUE THEN
						-- KPEI
						FOR rec IN csr_payrec_upd_kpei LOOP
							/*BEGIN
								UPDATE T_CONTRACTS
								SET sett_for_curr = DECODE(SIGN(rec.payrec_amt),1,sett_for_curr - rec.payrec_amt, sett_for_curr),
								sett_curr_min = DECODE(SIGN(rec.payrec_amt),-1, sett_curr_min + rec.payrec_amt, sett_curr_min),
								sett_val = NVL(sett_val,0) + rec.payrec_amt,
								rvpv_number = rec.rvpv_number,
								upd_dt        = SYSDATE,
								upd_by      = rec.user_id
								WHERE contr_num = rec.contr_num;
							EXCEPTION
								WHEN OTHERS THEN
									v_error_code := -14;
									v_error_msg :=  SUBSTR('Update  T_CONTRACTS '||SQLERRM,1,200);
									RAISE v_err;
							END;*/
							
							BEGIN
								UPDATE T_ACCOUNT_LEDGER
								SET sett_for_curr = DECODE(SIGN(rec.payrec_amt),1,sett_for_curr - curr_val, sett_for_curr),
								sett_curr_min = DECODE(SIGN(rec.payrec_amt),-1, sett_curr_min - curr_val, sett_curr_min),
								sett_val = DECODE(SIGN(rec.payrec_amt),1,NVL(sett_val,0) + curr_val, sett_val - curr_val),
								rvpv_number   = rec.rvpv_number,
								upd_dt        = SYSDATE
								WHERE doc_date = rec.doc_date
								AND due_date = rec.due_date
								AND trim(gl_acct_cd) = trim(rec.gl_acct_cd)
								AND sl_acct_cd = rec.sl_acct_cd
								AND record_source = 'CG' 
								AND reversal_jur = 'N' 
								AND approved_sts = 'A';
							EXCEPTION
								WHEN OTHERS THEN
									v_error_code := -31;
									v_error_msg :=  SUBSTR('Update  T_ACCOUNT_LEDGER '||SQLERRM,1,200);
									RAISE v_err;
							END;
						END LOOP;
					ELSE			
						FOR rec IN csr_payrec_upd LOOP
							IF rec.record_source = 'CG' OR rec.record_source = 'CDUE' THEN
								BEGIN
									UPDATE T_CONTRACTS
									SET sett_for_curr = DECODE(SIGN(rec.payrec_amt),1,sett_for_curr - rec.payrec_amt, sett_for_curr),
									sett_curr_min = DECODE(SIGN(rec.payrec_amt),-1, sett_curr_min + rec.payrec_amt, sett_curr_min),
									sett_val = NVL(sett_val,0) + rec.payrec_amt,
									rvpv_number = rec.rvpv_number,
									upd_dt        = SYSDATE,
									upd_by      = rec.user_id
									WHERE contr_num = rec.contr_num;
								EXCEPTION
									WHEN OTHERS THEN
										v_error_code := -32;
										v_error_msg :=  SUBSTR('Update  T_CONTRACTS '||SQLERRM,1,200);
										RAISE v_err;
								END;

								IF SUBSTR(rec.contr_num,6,1) = 'I' OR  rec.record_source = 'CDUE' THEN
								-- TITIP JUAL/ BELI CONTRACT
									BEGIN
										UPDATE T_ACCOUNT_LEDGER
										SET sett_for_curr = DECODE(SIGN(rec.payrec_amt),1,sett_for_curr - rec.payrec_amt, sett_for_curr),
										sett_curr_min = DECODE(SIGN(rec.payrec_amt),-1, sett_curr_min + rec.payrec_amt, sett_curr_min),
										sett_val = NVL(sett_val,0) + rec.payrec_amt,
										rvpv_number = rec.rvpv_number,
										upd_dt        = SYSDATE,
										upd_by       = rec.user_id
										WHERE xn_doc_num = rec.gl_ref_num
										AND doc_ref_num = rec.contr_num
										AND TRIM(gl_acct_cd) = TRIM(rec.gl_acct_cd)
										AND sl_Acct_cd = rec.sl_acct_cd;
									EXCEPTION
										WHEN OTHERS THEN
											v_error_code := -33;
											v_error_msg :=  SUBSTR('Update  T_ACCOUNT_LEDGER '||SQLERRM,1,200);
											RAISE v_err;
									 END;					

								
								
								ELSE
								-- REGULAR CONTRACT
									BEGIN
										UPDATE T_ACCOUNT_LEDGER
										SET sett_for_curr = DECODE(SIGN(rec.payrec_amt),1,sett_for_curr - rec.payrec_amt, sett_for_curr),
										sett_curr_min = DECODE(SIGN(rec.payrec_amt),-1, sett_curr_min + rec.payrec_amt, sett_curr_min),
										sett_val = NVL(sett_val,0) + rec.payrec_amt,
										rvpv_number = rec.rvpv_number,
										upd_dt        = SYSDATE,
										upd_by       = rec.user_id
										WHERE xn_doc_num = rec.contr_num
										AND record_source = 'CG'
										AND TRIM(gl_acct_cd) = TRIM(rec.gl_acct_cd)
										AND sl_Acct_cd = rec.sl_acct_cd;
									EXCEPTION
										WHEN OTHERS THEN
											v_error_code := -34;
											v_error_msg :=  SUBSTR('Update  T_ACCOUNT_LEDGER '||SQLERRM,1,200);
											RAISE v_err;
										END;
								END IF;
							
							ELSIF  rec.record_source = 'NEGO' THEN
								BEGIN
									UPDATE T_ACCOUNT_LEDGER
									SET sett_for_curr = DECODE(SIGN(rec.payrec_amt),1,sett_for_curr - rec.payrec_amt, sett_for_curr),
									sett_curr_min = DECODE(SIGN(rec.payrec_amt),-1, sett_curr_min + rec.payrec_amt, sett_curr_min),
									sett_val = NVL(sett_val,0) + rec.payrec_amt,
									rvpv_number   = rec.rvpv_number,
									upd_dt        = SYSDATE
									WHERE doc_date = rec.doc_date
									AND xn_doc_num = rec.contr_num
									AND record_source = 'CG'
									AND trim(gl_acct_cd) = trim(rec.gl_acct_cd)
									AND sl_acct_cd = rec.sl_acct_cd;
								EXCEPTION
									WHEN OTHERS THEN
										v_error_code := -35;
										v_error_msg :=  SUBSTR('Update  T_ACCOUNT_LEDGER '||SQLERRM,1,200);
										RAISE v_err;
								END;
								
								BEGIN
									UPDATE T_PAYRECD
									SET sett_for_curr = DECODE(SIGN(rec.payrec_amt),1,sett_for_curr - rec.payrec_amt, sett_for_curr),
									sett_curr_min = DECODE(SIGN(rec.payrec_amt),-1, sett_curr_min + rec.payrec_amt, sett_curr_min),
									sett_val = NVL(sett_val,0) + rec.payrec_amt,
									upd_dt        = SYSDATE,
									upd_by       = rec.user_id
									WHERE payrec_num  = rec.contr_num
									AND record_source = 'ARAP'
									AND tal_id      = rec.tal_id;
								EXCEPTION
									WHEN OTHERS THEN
										v_error_code := -36;
										v_error_msg :=  SUBSTR('Update  T_PAYRECD '||SQLERRM,1,200);
										RAISE v_err;
								END;
									
							ELSIF rec.record_source = 'BOND' THEN 
								BEGIN
									UPDATE T_BOND_TRX
									SET sett_for_curr = DECODE(SIGN(rec.payrec_amt),1,sett_for_curr - rec.payrec_amt, sett_for_curr),
									sett_curr_min = DECODE(SIGN(rec.payrec_amt),-1, sett_curr_min + rec.payrec_amt, sett_curr_min),
									sett_val = NVL(sett_val,0) + rec.payrec_amt,
									rvpv_number = rec.rvpv_number,
									upd_dt        = SYSDATE
									WHERE trx_date = rec.doc_date
									AND doc_num = rec.contr_num;
								EXCEPTION
									WHEN OTHERS THEN
										v_error_code := -37;
										v_error_msg :=  SUBSTR('Update  T_BOND_TRX '||SQLERRM,1,200);
										RAISE v_err;
								END;
								
							/*	BEGIN
									UPDATE  T_ACCOUNT_LEDGER
									SET sett_for_curr = DECODE(SIGN(rec.payrec_amt),1,sett_for_curr - rec.payrec_amt, sett_for_curr),
									sett_curr_min = DECODE(SIGN(rec.payrec_amt),-1, sett_curr_min + rec.payrec_amt, sett_curr_min),
									sett_val = NVL(sett_val,0) + rec.payrec_amt,
									rvpv_number   = rec.rvpv_number,
									upd_dt        = SYSDATE
									WHERE  doc_date =  rec.doc_date
									AND  xn_doc_num  =  rec.contr_num
									AND  gl_acct_cd =  RPAD(trim(rec.gl_acct_cd),12)
									AND  sl_acct_cd =  rec.sl_acct_cd;
								EXCEPTION
									WHEN OTHERS THEN
										v_error_code := -25;
										v_error_msg :=  SUBSTR('Update  T_ACCOUNT_LEDGER '||SQLERRM,1,200);
										RAISE v_err;
								END;*/
							
							ELSE
					 --- for DNCN  / RD PD / RVO /PVO
								BEGIN
									UPDATE T_ACCOUNT_LEDGER
									SET sett_for_curr = DECODE(SIGN(rec.payrec_amt),1,sett_for_curr - rec.payrec_amt, sett_for_curr),
									sett_curr_min = DECODE(SIGN(rec.payrec_amt),-1, sett_curr_min + rec.payrec_amt, sett_curr_min),
									sett_val = NVL(sett_val,0) + rec.payrec_amt,
									rvpv_number = rec.rvpv_number,
									upd_dt        = SYSDATE,
									upd_by       = rec.user_id
									WHERE xn_doc_num = rec.gl_ref_num
									AND TRIM(gl_Acct_cd) = TRIM(rec.gl_acct_cd)
									AND sl_Acct_cd = rec.sl_acct_cd
									AND tal_id = rec.tal_id;
								EXCEPTION
									WHEN OTHERS THEN
										v_error_code := -38;
										v_error_msg :=  SUBSTR('Update  T_ACCOUNT_LEDGER '||SQLERRM,1,200);
										RAISE v_err;
								END;
								
								IF rec.record_source = 'PDRD' THEN
									BEGIN
										UPDATE T_PAYRECD
										SET sett_for_curr = DECODE(SIGN(rec.payrec_amt),1,sett_for_curr - rec.payrec_amt, sett_for_curr),
										sett_curr_min = DECODE(SIGN(rec.payrec_amt),-1, sett_curr_min + rec.payrec_amt, sett_curr_min),
										sett_val = NVL(sett_val,0) + rec.payrec_amt,
										upd_dt        = SYSDATE,
										upd_by       = rec.user_id
										WHERE payrec_num  = rec.contr_num
										AND( record_source = 'ARAP' OR record_source = 'VCH')
										AND tal_id      = rec.tal_id;
									EXCEPTION
										WHEN OTHERS THEN
											v_error_code := -39;
											v_error_msg :=  SUBSTR('Update  T_PAYRECD '||SQLERRM,1,200);
											RAISE v_err;
									END;
								END IF;
							END IF;
						END LOOP;
					END IF;
				
				ELSE
					-- NON REVERSAL
					
					FOR rec IN csr_payrec LOOP	
						BEGIN
							SELECT MAX(DOC_REF_NUM), MAX(SL_ACCT_CD), MAX(PAYREC_AMT), MAX(GL_REF_NUM), MAX(GL_ACCT_CD), MAX(TAL_ID), MAX(RECORD_SOURCE), MAX(DOC_DATE), MAX(DUE_DATE), MAX(USER_ID), SUBSTR(MAX(UPD_STATUS),1,1)
							INTO v_contr_num, v_sl_acct_cd, v_amt, v_gl_ref_num, v_gl_acct_cd, v_tal_id, v_record_source, v_doc_date, v_due_date, v_user_id, v_detail_status
							FROM
							(
								SELECT DECODE(field_name,'DOC_REF_NUM',field_value, NULL) DOC_REF_NUM,
									   DECODE(field_name,'SL_ACCT_CD',field_value, NULL) SL_ACCT_CD,
									   DECODE(field_name,'PAYREC_AMT',field_value, NULL) PAYREC_AMT,
									   DECODE(field_name,'GL_REF_NUM',field_value, NULL) GL_REF_NUM,
									   DECODE(field_name,'GL_ACCT_CD',field_value, NULL) GL_ACCT_CD,
									   DECODE(field_name,'TAL_ID',field_value, NULL) TAL_ID,
									   DECODE(field_name,'RECORD_SOURCE',field_value, NULL) RECORD_SOURCE,
									   DECODE(field_name,'DOC_DATE',TO_DATE(field_value,'YYYY-MM-DD HH24:MI:SS'), NULL) DOC_DATE,
									   DECODE(field_name,'DUE_DATE',TO_DATE(field_value,'YYYY-MM-DD HH24:MI:SS'), NULL) DUE_DATE,
									   DECODE(field_name,'USER_ID',field_value, NULL) USER_ID,
									   UPD_STATUS
								FROM  T_MANY_DETAIL
								WHERE T_MANY_DETAIL.update_date = p_update_date
								AND T_MANY_DETAIL.update_seq = p_update_seq
								AND T_MANY_DETAIL.table_name = 'T_PAYRECD'
								AND T_MANY_DETAIL.record_seq = rec.record_seq
								AND T_MANY_DETAIL.field_name IN ('DOC_REF_NUM', 'SL_ACCT_CD', 'PAYREC_AMT','GL_REF_NUM','GL_ACCT_CD','TAL_ID','RECORD_SOURCE','DOC_DATE','DUE_DATE','USER_ID')
							);
						EXCEPTION
							WHEN OTHERS THEN
								v_error_code := -51;
								v_error_msg :=  SUBSTR('Retrieve  T_MANY_DETAIL '||SQLERRM,1,200);
								RAISE v_err;
						END;
						
						v_next := FALSE;
						
						IF v_detail_status = 'U' THEN
							BEGIN
								SELECT approved_sts INTO v_approved_sts
								FROM T_PAYRECD
								WHERE payrec_num = v_rvpv_number
								AND doc_ref_num = v_contr_num
								AND tal_id = v_tal_id;
							EXCEPTION
								WHEN OTHERS THEN
									v_error_code := -52;
									v_error_msg :=  SUBSTR('Retrieve  T_PAYRECD '||SQLERRM,1,200);
									RAISE v_err;
							END;
							
							IF v_approved_sts = 'C' THEN
								v_detail_status := 'I';
								
								BEGIN
									UPDATE T_PAYRECD
									SET approved_sts = 'A'
									WHERE payrec_num = v_rvpv_number
									AND doc_ref_num = v_contr_num
									AND tal_id = v_tal_id;
								EXCEPTION
									WHEN OTHERS THEN
										v_error_code := -53;
										v_error_msg :=  SUBSTR('UPDATE  T_PAYRECD '||SQLERRM,1,200);
										RAISE v_err;
								END;
								
							ELSE
								IF v_record_source = 'KPEI' THEN
									v_next := TRUE;
								ELSE
									BEGIN
										SELECT v_amt - payrec_amt INTO v_amt 
										FROM T_PAYRECD
										WHERE payrec_num = v_rvpv_number
										AND doc_ref_num = v_contr_num
										AND tal_id = v_tal_id;
									EXCEPTION
										WHEN OTHERS THEN
											v_error_code := -54;
											v_error_msg :=  SUBSTR('Retrieve  T_PAYRECD '||SQLERRM,1,200);
											RAISE v_err;
									END;
									
									IF v_amt > 0 THEN
										v_detail_status := 'I';
									ELSE
										v_detail_status := 'C';
										v_amt := ABS(v_amt);
									END IF;		
								END IF;
							END IF;
						END IF;
						
						IF v_next = FALSE THEN
							IF v_record_source = 'CG' OR v_record_source = 'CDUE' THEN
								BEGIN
									UPDATE T_CONTRACTS
									SET sett_for_curr = DECODE(v_detail_status,'I',sett_for_curr - v_amt, sett_for_curr),
									sett_curr_min = DECODE(v_detail_status,'C', sett_curr_min - v_amt, sett_curr_min),
									sett_val = DECODE(v_detail_status,'I', NVL(sett_val,0) + v_amt, sett_val - v_amt),
									rvpv_number = DECODE(v_detail_status,'I',v_rvpv_number,NULL),
									upd_dt        = SYSDATE,
									upd_by      = v_user_id
									WHERE contr_num = v_contr_num;
								EXCEPTION
									WHEN OTHERS THEN
										v_error_code := -55;
										v_error_msg :=  SUBSTR('Update  T_CONTRACTS '||SQLERRM,1,200);
										RAISE v_err;
								END;

								IF SUBSTR(v_contr_num,6,1) = 'I' OR  v_record_source = 'CDUE' THEN
								-- TITIP JUAL/ BELI CONTRACT
									BEGIN
										UPDATE T_ACCOUNT_LEDGER
										SET sett_for_curr = DECODE(v_detail_status,'I',sett_for_curr - v_amt, sett_for_curr),
										sett_curr_min = DECODE(v_detail_status,'C', sett_curr_min - v_amt, sett_curr_min),
										sett_val = DECODE(v_detail_status,'I', NVL(sett_val,0) + v_amt, sett_val - v_amt),
										rvpv_number = DECODE(v_detail_status,'I',v_rvpv_number,NULL),
										upd_dt        = SYSDATE,
										upd_by       = v_user_id
										WHERE xn_doc_num = v_gl_ref_num
										AND doc_ref_num = v_contr_num
										AND TRIM(gl_acct_cd) = TRIM(v_gl_acct_cd)
										AND sl_Acct_cd = v_sl_acct_cd;
									EXCEPTION
										WHEN OTHERS THEN
											v_error_code := -56;
											v_error_msg :=  SUBSTR('Update  T_ACCOUNT_LEDGER '||SQLERRM,1,200);
											RAISE v_err;
									 END;
							
								ELSE
								-- REGULAR CONTRACT
									BEGIN
										UPDATE T_ACCOUNT_LEDGER
										SET sett_for_curr = DECODE(v_detail_status,'I',sett_for_curr - v_amt, sett_for_curr),
										sett_curr_min = DECODE(v_detail_status,'C', sett_curr_min - v_amt, sett_curr_min),
										sett_val = DECODE(v_detail_status,'I', NVL(sett_val,0) + v_amt, sett_val - v_amt),
										rvpv_number = DECODE(v_detail_status,'I',v_rvpv_number,NULL),
										upd_dt        = SYSDATE,
										upd_by       = v_user_id
										WHERE xn_doc_num = v_contr_num
										AND record_source = 'CG'
										AND TRIM(gl_acct_cd) = TRIM(v_gl_acct_cd)
										AND sl_Acct_cd = v_sl_acct_cd;
									EXCEPTION
										WHEN OTHERS THEN
											v_error_code := -57;
											v_error_msg :=  SUBSTR('Update  T_ACCOUNT_LEDGER '||SQLERRM,1,200);
											RAISE v_err;
										END;
								END IF;
							
							ELSIF v_record_source = 'KPEI'  THEN
								BEGIN
									UPDATE T_ACCOUNT_LEDGER
									SET sett_for_curr = DECODE(v_detail_status,'I',sett_for_curr - curr_val, sett_for_curr),
									sett_curr_min = DECODE(v_detail_status,'C', sett_curr_min - curr_val, sett_curr_min),
									sett_val = DECODE(v_detail_status,'I', NVL(sett_val,0) + curr_val, sett_val - curr_val),
									rvpv_number = DECODE(v_detail_status,'I',v_rvpv_number,NULL),
									upd_dt        = SYSDATE
									WHERE doc_date = v_doc_date
									AND due_date = v_due_date
									AND TRIM(gl_acct_cd) = trim(v_gl_acct_cd)
									AND sl_acct_cd = v_sl_acct_cd
									AND record_source = 'CG' 
									AND reversal_jur = 'N' 
									AND approved_sts = 'A';
								EXCEPTION
									WHEN OTHERS THEN
										v_error_code := -58;
										v_error_msg :=  SUBSTR('Update  T_ACCOUNT_LEDGER '||SQLERRM,1,200);
										RAISE v_err;
								END;
								
							ELSIF  v_record_source = 'NEGO' THEN
								BEGIN
									UPDATE T_ACCOUNT_LEDGER
									SET sett_for_curr = DECODE(v_detail_status,'I',sett_for_curr - v_amt, sett_for_curr),
									sett_curr_min = DECODE(v_detail_status,'C', sett_curr_min - v_amt, sett_curr_min),
									sett_val = DECODE(v_detail_status,'I', NVL(sett_val,0) + v_amt, sett_val - v_amt),
									rvpv_number = DECODE(v_detail_status,'I',v_rvpv_number,NULL),
									upd_dt        = SYSDATE
									WHERE doc_date = v_doc_date
									AND xn_doc_num = v_contr_num
									AND record_source = 'CG'
									AND TRIM(gl_acct_cd) = trim(v_gl_acct_cd)
									AND sl_acct_cd = v_sl_acct_cd;
								EXCEPTION
									WHEN OTHERS THEN
										v_error_code := -59;
										v_error_msg :=  SUBSTR('Update  T_ACCOUNT_LEDGER '||SQLERRM,1,200);
										RAISE v_err;
								END;
								
								BEGIN
									UPDATE T_PAYRECD
									SET sett_for_curr = DECODE(v_detail_status,'I',sett_for_curr - v_amt, sett_for_curr),
									sett_curr_min = DECODE(v_detail_status,'C', sett_curr_min - v_amt, sett_curr_min),
									sett_val = DECODE(v_detail_status,'I', NVL(sett_val,0) + v_amt, sett_val - v_amt),
									upd_dt        = SYSDATE,
									upd_by       = v_user_id
									WHERE payrec_num  = v_contr_num
									AND record_source = 'ARAP'
									AND tal_id      = v_tal_id;
								EXCEPTION
									WHEN OTHERS THEN
										v_error_code := -60;
										v_error_msg :=  SUBSTR('Update  T_PAYRECD '||SQLERRM,1,200);
										RAISE v_err;
								END;
								
							ELSIF  v_record_source = 'BOND' THEN
								BEGIN
									UPDATE T_BOND_TRX
									SET sett_for_curr = DECODE(v_detail_status,'I',sett_for_curr - v_amt, sett_for_curr),
									sett_curr_min = DECODE(v_detail_status,'C', sett_curr_min - v_amt, sett_curr_min),
									sett_val = DECODE(v_detail_status,'I', NVL(sett_val,0) + v_amt, sett_val - v_amt),
									rvpv_number = DECODE(v_detail_status,'I',v_rvpv_number,NULL),
									upd_dt        = SYSDATE
									WHERE trx_date = v_doc_date
									AND doc_num = v_contr_num;
								EXCEPTION
									WHEN OTHERS THEN
										v_error_code := -61;
										v_error_msg :=  SUBSTR('Update  T_BOND_TRX '||SQLERRM,1,200);
										RAISE v_err;
								END;
									
							ELSE
					 --- for DNCN  / RD PD / RVO /PVO
								BEGIN
									UPDATE T_ACCOUNT_LEDGER
									SET sett_for_curr = DECODE(v_detail_status,'I',sett_for_curr - v_amt, sett_for_curr),
									sett_curr_min = DECODE(v_detail_status,'C', sett_curr_min - v_amt, sett_curr_min),
									sett_val = DECODE(v_detail_status,'I', NVL(sett_val,0) + v_amt, sett_val - v_amt),
									rvpv_number = DECODE(v_detail_status,'I',v_rvpv_number,NULL),
									upd_dt        = SYSDATE,
									upd_by       = v_user_id
									WHERE xn_doc_num = v_gl_ref_num
									AND TRIM(gl_Acct_cd) = TRIM(v_gl_acct_cd)
									AND sl_Acct_cd = v_sl_acct_cd
									AND tal_id = v_tal_id;
								EXCEPTION
									WHEN OTHERS THEN
										v_error_code := -62;
										v_error_msg :=  SUBSTR('Update  T_ACCOUNT_LEDGER '||SQLERRM,1,200);
										RAISE v_err;
								END;
								
								IF v_record_source = 'PDRD' THEN 					
									BEGIN
										UPDATE T_PAYRECD
										SET sett_for_curr = DECODE(v_detail_status,'I',sett_for_curr - v_amt, sett_for_curr),
										sett_curr_min = DECODE(v_detail_status,'C', sett_curr_min - v_amt, sett_curr_min),
										sett_val = DECODE(v_detail_status,'I', NVL(sett_val,0) + v_amt, sett_val - v_amt),
										upd_dt        = SYSDATE,
										upd_by       = v_user_id
										WHERE payrec_num  = v_contr_num
										AND( record_source = 'ARAP' OR record_source = 'VCH')
										AND tal_id      = v_tal_id;
									EXCEPTION
										WHEN OTHERS THEN
											v_error_code := -63;
											v_error_msg :=  SUBSTR('Update  T_PAYRECD '||SQLERRM,1,200);
											RAISE v_err;
									END;
								END IF;
							END IF;
						END IF;	
					END LOOP;
				END IF;
			END IF;
		END IF;
		
	ELSE
		-- GSJK / GSSL
		FOR rec IN csr_gs1000 LOOP			
			BEGIN
				SELECT MAX(DOC_REF_NUM), MAX(SL_ACCT_CD), MAX(PAYREC_AMT), MAX(GL_REF_NUM), MAX(GL_ACCT_CD), MAX(TAL_ID), MAX(RECORD_SOURCE), MAX(DOC_DATE), MAX(DUE_DATE), MAX(USER_ID), MAX(UPD_STATUS)
				INTO v_contr_num, v_sl_acct_cd, v_amt, v_gl_ref_num, v_gl_acct_cd, v_tal_id, v_record_source, v_doc_date, v_due_date, v_user_id, v_detail_status
				FROM
				(
					SELECT DECODE(field_name,'DOC_REF_NUM',field_value, NULL) DOC_REF_NUM,
						   DECODE(field_name,'SL_ACCT_CD',field_value, NULL) SL_ACCT_CD,
						   DECODE(field_name,'PAYREC_AMT',field_value, NULL) PAYREC_AMT,
						   DECODE(field_name,'GL_REF_NUM',field_value, NULL) GL_REF_NUM,
						   DECODE(field_name,'GL_ACCT_CD',field_value, NULL) GL_ACCT_CD,
						   DECODE(field_name,'TAL_ID',field_value, NULL) TAL_ID,
						   DECODE(field_name,'RECORD_SOURCE',field_value, NULL) RECORD_SOURCE,
						   DECODE(field_name,'DOC_DATE',TO_DATE(field_value,'YYYY-MM-DD HH24:MI:SS'), NULL) DOC_DATE,
						   DECODE(field_name,'DUE_DATE',TO_DATE(field_value,'YYYY-MM-DD HH24:MI:SS'), NULL) DUE_DATE,
						   DECODE(field_name,'USER_ID',field_value, NULL) USER_ID,
						   DECODE(UPD_STATUS,'I','I','C') UPD_STATUS
					FROM  T_MANY_DETAIL
					WHERE T_MANY_DETAIL.update_date = p_update_date
					AND T_MANY_DETAIL.update_seq = p_update_seq
					AND T_MANY_DETAIL.table_name = 'T_PAYRECD'
					AND T_MANY_DETAIL.record_seq = rec.record_seq
					AND T_MANY_DETAIL.field_name IN ('DOC_REF_NUM', 'SL_ACCT_CD', 'PAYREC_AMT','GL_REF_NUM','GL_ACCT_CD','TAL_ID','RECORD_SOURCE','DOC_DATE','DUE_DATE','USER_ID')
				);
			EXCEPTION
				WHEN OTHERS THEN
					v_error_code := -64;
					v_error_msg :=  SUBSTR('Retrieve  T_MANY_DETAIL '||SQLERRM,1,200);
					RAISE v_err;
			END;
			
			BEGIN
				SELECT COUNT(*) INTO v_cnt
				FROM MST_GLA_TRX
				WHERE jur_type = 'BROK'
				AND gl_a = TRIM(v_gl_acct_cd);
			EXCEPTION
				WHEN OTHERS THEN
					v_error_code := -65;
					v_error_msg :=  SUBSTR('Count MST_GLA_TRX '||SQLERRM,1,200);
					RAISE v_err;
			END;
			
			IF v_cnt = 0 THEN
				-- KPEI
				BEGIN
					FOR rec_in IN
					(
						SELECT xn_doc_num, tal_id
						FROM T_ACCOUNT_LEDGER
						WHERE doc_date = v_doc_date
						AND due_date = v_due_date
						AND trim(gl_acct_cd) = trim(v_gl_acct_cd)
						AND sl_acct_cd = v_sl_acct_cd
						AND brch_cd = 'SL'
						AND record_source = 'CG' 
						AND reversal_jur = 'N' 
						AND approved_sts = 'A'
					)
					LOOP
						BEGIN
							SELECT COUNT(*) INTO v_cnt
							FROM T_HEAD_BRANCH_RVPV
							WHERE xn_doc_num = rec_in.xn_doc_num
							AND tal_id = rec_in.tal_id;
						EXCEPTION
							WHEN OTHERS THEN
								v_error_code := -66;
								v_error_msg :=  SUBSTR('Count T_HEAD_BRANCH_RVPV '||SQLERRM,1,200);
								RAISE v_err;
						END;
						
						IF v_cnt = 0 THEN
							IF v_detail_status = 'I' THEN
							
								BEGIN
									INSERT INTO T_HEAD_BRANCH_RVPV
									(xn_doc_num, tal_id, head_rvpv_number, branch_rvpv_number)
									VALUES
									(rec_in.xn_doc_num, rec_in.tal_id, DECODE(v_acct_type, 'GSJK', v_rvpv_number, NULL), DECODE(v_acct_type, 'GSSL', v_rvpv_number, NULL));
								EXCEPTION
									WHEN OTHERS THEN
										v_error_code := -67;
										v_error_msg :=  SUBSTR('INSERT INTO T_HEAD_BRANCH_RVPV '||SQLERRM,1,200);
										RAISE v_err;
								END;
							
							END IF;
							
						ELSE
							IF v_detail_status = 'I' THEN
								BEGIN
									UPDATE T_HEAD_BRANCH_RVPV
									SET head_rvpv_number = DECODE(v_acct_type, 'GSJK', v_rvpv_number, head_rvpv_number),
									branch_rvpv_number = DECODE(v_acct_type, 'GSSL', v_rvpv_number, branch_rvpv_number)
									WHERE xn_doc_num = rec_in.xn_doc_num
									AND tal_id = rec_in.tal_id;
								EXCEPTION
									WHEN OTHERS THEN
										v_error_code := -68;
										v_error_msg :=  SUBSTR('UPDATE T_HEAD_BRANCH_RVPV '||SQLERRM,1,200);
										RAISE v_err;
								END;
							ELSE
								BEGIN
									UPDATE T_HEAD_BRANCH_RVPV
									SET head_rvpv_number = DECODE(v_acct_type, 'GSJK', NULL, head_rvpv_number),
									branch_rvpv_number = DECODE(v_acct_type, 'GSSL', NULL, branch_rvpv_number)
									WHERE xn_doc_num = rec_in.xn_doc_num
									AND tal_id = rec_in.tal_id;
								EXCEPTION
									WHEN OTHERS THEN
										v_error_code := -69;
										v_error_msg :=  SUBSTR('UPDATE T_HEAD_BRANCH_RVPV '||SQLERRM,1,200);
										RAISE v_err;
								END;
							END IF;
						
						END IF;
						
					END LOOP;
				EXCEPTION
					WHEN OTHERS THEN
						v_error_code := -70;
						v_error_msg :=  SUBSTR('Loop T_ACCOUNT_LEDGER '||SQLERRM,1,200);
						RAISE v_err;
				END;
				
			ELSE
				-- NEGO
				BEGIN
					SELECT xn_doc_num, tal_id
					INTO v_xn_doc_num, v_tal_id
					FROM T_ACCOUNT_LEDGER
					WHERE doc_date = v_doc_date
					AND xn_doc_num = v_contr_num
					AND record_source = 'CG'
					AND TRIM(gl_acct_cd) = trim(v_gl_acct_cd)
					AND sl_acct_cd = v_sl_acct_cd;
				EXCEPTION
					WHEN OTHERS THEN
						v_error_code := -71;
						v_error_msg :=  SUBSTR('SELECT T_ACCOUNT_LEDGER '||SQLERRM,1,200);
						RAISE v_err;
				END;
				
				BEGIN
					SELECT COUNT(*) INTO v_cnt
					FROM T_HEAD_BRANCH_RVPV
					WHERE xn_doc_num = v_xn_doc_num
					AND tal_id = v_tal_id;
				EXCEPTION
					WHEN OTHERS THEN
						v_error_code := -72;
						v_error_msg :=  SUBSTR('Count T_HEAD_BRANCH_RVPV '||SQLERRM,1,200);
						RAISE v_err;
				END;
				
				IF v_cnt = 0 THEN
					IF v_detail_status = 'I' THEN
					
						BEGIN
							INSERT INTO T_HEAD_BRANCH_RVPV
							(xn_doc_num, tal_id, head_rvpv_number, branch_rvpv_number)
							VALUES
							(v_xn_doc_num, v_tal_id, DECODE(v_acct_type, 'GSJK', v_rvpv_number, NULL), DECODE(v_acct_type, 'GSSL', v_rvpv_number, NULL));
						EXCEPTION
							WHEN OTHERS THEN
								v_error_code := -73;
								v_error_msg :=  SUBSTR('INSERT INTO T_HEAD_BRANCH_RVPV '||SQLERRM,1,200);
								RAISE v_err;
						END;
					
					END IF;
					
				ELSE
					IF v_detail_status = 'I' THEN
						BEGIN
							UPDATE T_HEAD_BRANCH_RVPV
							SET head_rvpv_number = DECODE(v_acct_type, 'GSJK', v_rvpv_number, head_rvpv_number),
							branch_rvpv_number = DECODE(v_acct_type, 'GSSL', v_rvpv_number, branch_rvpv_number)
							WHERE xn_doc_num = v_xn_doc_num
							AND tal_id = v_tal_id;
						EXCEPTION
							WHEN OTHERS THEN
								v_error_code := -74;
								v_error_msg :=  SUBSTR('UPDATE T_HEAD_BRANCH_RVPV '||SQLERRM,1,200);
								RAISE v_err;
						END;
					ELSE
						BEGIN
							UPDATE T_HEAD_BRANCH_RVPV
							SET head_rvpv_number = DECODE(v_acct_type, 'GSJK', NULL, head_rvpv_number),
							branch_rvpv_number = DECODE(v_acct_type, 'GSSL', NULL, branch_rvpv_number)
							WHERE xn_doc_num = v_xn_doc_num
							AND tal_id = v_tal_id;
						EXCEPTION
							WHEN OTHERS THEN
								v_error_code := -75;
								v_error_msg :=  SUBSTR('UPDATE T_HEAD_BRANCH_RVPV '||SQLERRM,1,200);
								RAISE v_err;
						END;
					END IF;
				
				END IF;
				
			END IF;
			
		END LOOP;
	END IF;
		
	BEGIN
		SELECT user_id INTO v_user_id
		FROM T_MANY_HEADER
		WHERE update_date = p_update_date
		AND update_seq = p_update_seq;
	EXCEPTION
		WHEN OTHERS THEN
			v_error_code := -81;
			v_error_msg :=  SUBSTR('Retrieve T_MANY_HEADER '||SQLERRM,1,200);
			RAISE v_err;
	END;
	
	IF v_reversal = TRUE THEN
		BEGIN
			SELECT field_value INTO v_xn_doc_num
			FROM T_MANY_DETAIL
			WHERE UPDATE_DATE = p_update_date
			AND UPDATE_SEQ = p_update_seq
			AND TABLE_NAME = 'T_ACCOUNT_LEDGER'
			AND FIELD_NAME = 'XN_DOC_NUM'
			AND RECORD_SEQ = 1
			AND ROWNUM = 1;
		EXCEPTION
			WHEN OTHERS THEN
				v_error_code := -82;
				v_error_msg :=  SUBSTR('Retrieve T_MANY_DETAIL '||SQLERRM,1,200);
				RAISE v_err;
		END;
		
		BEGIN
--			SELECT field_value INTO v_payrec_num
--			FROM T_MANY_DETAIL
--			WHERE UPDATE_DATE = p_update_date
--			AND UPDATE_SEQ = p_update_seq
--			AND TABLE_NAME = 'T_PAYRECH'
--			AND FIELD_NAME = 'PAYREC_NUM'
--			AND UPD_STATUS = 'C';
			
			SELECT MAX(PAYREC_NUM), MAX(ACCT_TYPE), MAX(CLIENT_CD), MAX(FOLDER_CD)
			INTO v_payrec_num, v_acct_type, v_client_cd, v_folder_cd
			FROM
			(
				SELECT DECODE(field_name,'PAYREC_NUM',field_value, NULL) PAYREC_NUM,
					   DECODE(field_name,'ACCT_TYPE',field_value, NULL) ACCT_TYPE,
					   DECODE(field_name,'CLIENT_CD',field_value, NULL) CLIENT_CD,
					   DECODE(field_name,'FOLDER_CD',field_value, NULL) FOLDER_CD
				FROM  T_MANY_DETAIL
				WHERE T_MANY_DETAIL.update_date = p_update_date
				AND T_MANY_DETAIL.update_seq = p_update_seq
				AND T_MANY_DETAIL.table_name = 'T_PAYRECH'
				AND UPD_STATUS = 'C'
				AND T_MANY_DETAIL.field_name IN ('PAYREC_NUM', 'ACCT_TYPE', 'CLIENT_CD', 'FOLDER_CD')
			);
		EXCEPTION
			WHEN OTHERS THEN
				v_error_code := -83;
				v_error_msg :=  SUBSTR('Retrieve T_MANY_DETAIL '||SQLERRM,1,200);
				RAISE v_err;
		END;
	
		BEGIN
			UPDATE T_PAYRECH
			SET reversal_jur = v_xn_doc_num
			WHERE payrec_num = v_payrec_num;
		EXCEPTION
			WHEN OTHERS THEN
				v_error_code := -84;
				v_error_msg :=  SUBSTR('Update  T_PAYRECH '||SQLERRM,1,200);
				RAISE v_err;
		END;
		
		BEGIN
			UPDATE T_ACCOUNT_LEDGER
			SET reversal_jur = v_xn_doc_num
			WHERE xn_doc_num = v_payrec_num;
		EXCEPTION
			WHEN OTHERS THEN
				v_error_code := -85;
				v_error_msg :=  SUBSTR('Update  T_ACCOUNT_LEDGER '||SQLERRM,1,200);
				RAISE v_err;
		END;
		
	--	IF v_acct_type = 'RDM' THEN 
			BEGIN
				SP_FL_CANCEL(v_payrec_num, v_user_id, v_error_code, v_error_msg);
			EXCEPTION
				WHEN OTHERS THEN
					v_error_code := -86;
					v_error_msg := SUBSTR('SP_FL_CANCEL '||SQLERRM,1,200);
					RAISE v_err;
			END;
			
			IF v_error_code < 0 THEN
				v_error_code := -87;
				v_error_msg := 'SP_FL_CANCEL '||v_error_msg;
				RAISE v_err;
			END IF;
	--	END IF;
	
		IF v_acct_type = 'KSEI' THEN
			BEGIN
				UPDATE T_FUND_KSEI
				SET approved_sts = 'C'
				WHERE doc_ref_num = v_payrec_num;
			EXCEPTION
				WHEN OTHERS THEN
					v_error_code := -88;
					v_error_msg := SUBSTR('UPDATE T_FUND_KSEI '||SQLERRM,1,200);
					RAISE v_err;
			END;
		END IF;
	
		IF SUBSTR(v_folder_cd,1,2) = 'IJ' THEN
-- 			UPDATE T_INTEREST

			BEGIN
				SELECT MAX(int_dt), MIN(int_dt)
				INTO v_max_dt, v_min_dt
				FROM T_INTEREST
				WHERE client_cd = v_client_cd
				AND xn_doc_num IS NOT NULL
				AND xn_doc_num = v_payrec_num;
			EXCEPTION
				WHEN OTHERS THEN
					v_error_code := -89;
					v_error_msg :=  SUBSTR('SELECT T_INTEREST '||SQLERRM,1,200);
					RAISE v_err;
			END;

			IF v_max_dt IS NOT NULL AND v_min_dt IS NOT NULL THEN
				IF v_status = 'C' THEN				
					BEGIN
						UPDATE T_INTEREST
						SET post_flg = 'N', xn_doc_num = NULL
						WHERE client_cd = v_client_cd
						AND int_dt BETWEEN v_min_dt AND v_max_dt
						AND xn_doc_num = v_payrec_num; 
					EXCEPTION
						WHEN OTHERS THEN
							v_error_code := -90;
							v_error_msg :=  SUBSTR('UPDATE T_INTEREST '||SQLERRM,1,200);
							RAISE v_err;
					END;
				ELSE
	--				STATUS = UPDATE
	
					BEGIN
						UPDATE T_INTEREST
						SET xn_doc_num = v_rvpv_number
						WHERE client_cd = v_client_cd
						AND int_dt BETWEEN v_min_dt AND v_max_dt
						AND xn_doc_num = v_payrec_num; 
					EXCEPTION
						WHEN OTHERS THEN
							v_error_code := -91;
							v_error_msg := SUBSTR('UPDATE T_INTEREST '||SQLERRM,1,200);
							RAISE v_err;
					END;
				END IF;
			END IF;
		END IF;
	END IF;
	
	FOR rec IN csr_log_blocking_upd LOOP
		BEGIN
			SELECT MAX(sl_acct_cd), MAX(cash_withdraw_amt), MAX(cash_withdraw_reason) INTO v_sl_acct_cd, v_amt, v_cash_withdraw_reason
			FROM
			(
				SELECT DECODE(field_name,'SL_ACCT_CD',field_value, NULL) SL_ACCT_CD,
					   DECODE(field_name,'CASH_WITHDRAW_AMT',field_value, NULL) CASH_WITHDRAW_AMT,
					   DECODE(field_name,'CASH_WITHDRAW_REASON',field_value, NULL) CASH_WITHDRAW_REASON
				FROM  T_MANY_DETAIL
				WHERE T_MANY_DETAIL.update_date = p_update_date
				AND T_MANY_DETAIL.update_seq = p_update_seq
				AND T_MANY_DETAIL.table_name = 'T_ACCOUNT_LEDGER'
				AND T_MANY_DETAIL.record_seq = rec.record_seq
				AND T_MANY_DETAIL.field_name IN ('SL_ACCT_CD', 'CASH_WITHDRAW_AMT', 'CASH_WITHDRAW_REASON')
			);
		EXCEPTION
			WHEN OTHERS THEN
				v_error_code := -101;
				v_error_msg := SUBSTR('Retrieve  T_MANY_DETAIL '||SQLERRM,1,200);
				RAISE v_err;
		END;
	
		BEGIN
			LOG_BLOCKING(TRUNC(p_update_date), v_sl_acct_cd, 'DEBIT '||v_amt, -4, v_cash_withdraw_reason, v_rvpv_number, v_user_id, v_error_code, v_error_msg);
		EXCEPTION
			WHEN OTHERS THEN
				v_error_code := -102;
				v_error_msg := SUBSTR('LOG_BLOCKING '||SQLERRM,1,200);
				RAISE v_err;
		END;
		
		IF v_error_code < 0 THEN
			v_error_code := -103;
			v_error_msg := 'LOG_BLOCKING '||v_error_msg;
			RAISE v_err;
		END IF;
	END LOOP;
	
	BEGIN
		SP_T_MANY_APPROVE(p_menu_name, p_update_date, p_update_seq, p_approved_user_id, p_approved_ip_address, v_error_code, v_error_msg); 
	EXCEPTION
		WHEN OTHERS THEN
			v_error_code := -111;
			v_error_msg := SUBSTR('SP_T_MANY_APPROVE '||SQLERRM,1,200);
			RAISE v_err;
	END;
	
	IF v_error_code < 0 THEN
		v_error_code := -112;
		v_error_msg := 'SP_T_MANY_APPROVE '||v_error_msg;
		RAISE v_err;
	END IF;
	
	IF v_status = 'U' AND v_reversal = TRUE THEN
		BEGIN
			UPDATE T_ACCOUNT_LEDGER
			SET reversal_jur = v_rvpv_number
			WHERE xn_doc_num = v_xn_doc_num;
		EXCEPTION
			WHEN OTHERS THEN
				v_error_code := -113;
				v_error_msg :=  SUBSTR('Update  T_ACCOUNT_LEDGER '||SQLERRM,1,200);
				RAISE v_err;
		END;
	END IF;
	
	IF v_status = 'I' OR (v_status = 'U' AND v_reversal = TRUE) THEN	
		BEGIN
			SP_RVPV_TRF_FL(v_rvpv_number, v_user_id, p_approved_user_id, v_error_code, v_error_msg);
		EXCEPTION
			WHEN OTHERS THEN
				v_error_code := -114;
				v_error_msg := SUBSTR('SP_RVPV_TRF_FL '||SQLERRM,1,200);
				RAISE v_err;
		END;
		
		IF v_error_code < 0 THEN
			v_error_code := -115;
			v_error_msg := 'SP_RVPV_TRF_FL '||v_error_msg;
			RAISE v_err;
		END IF;
		
		BEGIN
			SP_RVPV_FUND_KSEI(v_rvpv_number, v_user_id, p_approved_user_id, v_error_code, v_error_msg);
		EXCEPTION
			WHEN OTHERS THEN
				v_error_code := -116;
				v_error_msg := SUBSTR('SP_RVPV_FUND_KSEI '||SQLERRM,1,200);
				RAISE v_err;
		END;
		
		IF v_error_code < 0 THEN
			v_error_code := -117;
			v_error_msg := 'SP_RVPV_FUND_KSEI '||v_error_msg;
			RAISE v_err;
		END IF;
	END IF;
	
	p_error_code := 1;
	p_error_msg := '';
	
EXCEPTION
	WHEN NO_DATA_FOUND THEN
		NULL;
	WHEN v_err THEN
		p_error_code := v_error_code;
		p_error_msg :=  v_error_msg;
		ROLLBACK;	   
	WHEN OTHERS THEN
		p_error_code := -1;
		p_error_msg := SUBSTR(SQLERRM,1,200);
		ROLLBACK;
		RAISE;
END SP_T_PAYRECH_APPROVE_TEST2;