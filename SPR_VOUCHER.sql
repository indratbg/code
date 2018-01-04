create or replace PROCEDURE SPR_VOUCHER(
  vp_doc_num 			DOCNUM_ARRAY,
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
        SP_RPT_REMOVE_RAND('R_VOUCHER',vl_random_value,vo_errcd,vo_errmsg);
    EXCEPTION
        WHEN OTHERS THEN
            vo_errcd := -2;
            vo_errmsg := SQLERRM(SQLCODE);
            RAISE vl_err;
    END;
	
	BEGIN
        SP_RPT_REMOVE_RAND('R_CHEQ',vl_random_value,vo_errcd,vo_errmsg);
    EXCEPTION
        WHEN OTHERS THEN
            vo_errcd := -3;
            vo_errmsg := SQLERRM(SQLCODE);
            RAISE vl_err;
    END;
	
	FOR i IN 1..vp_doc_num.count LOOP
		IF vp_approved_status <> 'E' THEN
			BEGIN
				SELECT client_cd INTO v_client_cd
				FROM IPNEXTG.T_PAYRECH
				WHERE payrec_num = vp_doc_num(i);
			EXCEPTION
				WHEN OTHERS THEN
					vo_errcd := -4;
					vo_errmsg := SQLERRM(SQLCODE);
					RAISE vl_err;
			END;
		
			BEGIN
				INSERT INTO R_VOUCHER
				(
					/*SELECT h.payrec_num, h.payrec_date, TRIM(d.gl_acct_cd), d.sl_acct_cd, h.client_cd, d.db_cr_flg, d.payrec_amt, h.folder_cd, d.doc_ref_num, d.tal_id, d.record_source, d.remarks, vl_random_value, vp_user_id, vp_generate_date
					FROM IPNEXTG.T_PAYRECH h JOIN IPNEXTG.T_PAYRECD d
					ON h.payrec_num = d.payrec_num
					WHERE h.payrec_num = vp_doc_num(i)*/
					
					SELECT h.payrec_num, h.payrec_date, h.client_cd, TRIM(h.gl_acct_cd), h.sl_acct_cd, h.curr_amt, TRIM(d.gl_acct_cd), d.sl_acct_cd, d.db_cr_flg, d.doc_ref_num, d.doc_date, DECODE(SUBSTR(h.payrec_num,5,1),'R', DECODE(d.db_cr_flg,'C',d.payrec_amt, -1 * d.payrec_amt), DECODE(d.db_cr_flg,'D',d.payrec_amt, -1 * d.payrec_amt)) PAYREC_AMT, d.remarks, d.tal_id,	
					--DECODE(d.record_source,'GL','M','VCH',' ',SUBSTR(d.doc_ref_num,5,1))||' '||d.ref_folder_cd ref_folder_cd, 
					CASE 
						WHEN d.record_source IN ('VCH','ARAP') THEN '  '||d.ref_folder_cd
						WHEN d.record_source = 'GL' THEN 'M '||SUBSTR(d.doc_ref_num,5)
						ELSE 'I '||SUBSTR(d.doc_ref_num,5)			
					END ref_folder_cd,
					DECODE(d.db_cr_flg,'D','P','R') RP_code,		
					DECODE(d.record_source,'BOND',l.lawan_name,m.client_name), h.remarks, d.record_source, g.acct_name,	h.folder_cd, h.num_cheq, f.bank_acct_fmt, h.user_id, vl_random_value, vp_user_id, vp_generate_date	
					FROM IPNEXTG.T_PAYRECH h 
					JOIN IPNEXTG.T_PAYRECD d ON h.payrec_num = d.payrec_num
					LEFT JOIN IPNEXTG.MST_CLIENT m ON h.client_cd = m.client_cd
					LEFT JOIN IPNEXTG.MST_LAWAN_BOND_TRX l ON h.client_cd = l.lawan
					LEFT JOIN IPNEXTG.MST_GL_ACCOUNT g ON RPAD(TRIM(h.gl_acct_cd), 12) = g.gl_a AND TRIM(h.sl_acct_cd) = g.sl_a
					LEFT JOIN IPNEXTG.MST_CLIENT_FLACCT f ON h.client_cd = f.client_cd AND f.acct_stat IN ('A','I')	
					WHERE h.payrec_num = vp_doc_num(i)														
				);
			EXCEPTION
				WHEN OTHERS THEN
					vo_errcd := -5;
					vo_errmsg := SQLERRM(SQLCODE);
					RAISE vl_err;
			END;

			BEGIN
				INSERT INTO R_CHEQ
				(
					SELECT bg_cq_flg, chq_num, chq_dt, chq_amt, 
					NVL(b.acct_NAME,c.payee_name)||' / '||TRIM(c.PAYEE_ACCT_NUM)||' / '||TRIM(NVL(b.bank_short_name,c.bank_name))||' '||TRIM(NVL(b.BANK_BRCH_NAME,'')) payee_bank, vp_doc_num(i), vl_random_value, vp_user_id, vp_generate_date		
					FROM( 
						SELECT T_CHEQ.*, p.BANK_NAME		
						FROM IPNEXTG.T_CHEQ,		
						( 
							SELECT BANK_CD, BANK_NAME	
							FROM IPNEXTG.MST_IP_BANK
							WHERE APPROVED_STAT='A'
						) p 	
						WHERE rvpv_number = vp_doc_num(i)
						AND payee_bank_cd = p.BANK_CD(+)
					) c,
					( 
						SELECT 'Payee ' AS payee_type, bank_acct_num, bank_short_name, acct_name, bank_brch_name
						FROM IPNEXTG.V_CLIENT_BANK 	
						WHERE client_cd = v_client_cd
						UNION	
						SELECT 'Rek Dana ' AS payee_type, c.bank_acct_fmt, bank_short_name, c.acct_name, '' 		
						FROM IPNEXTG.MST_CLIENT_FLACCT c		
						WHERE c.client_cd = v_client_cd
						AND c.acct_stat IN ('A','I')
					) b	
					WHERE  c.PAYEE_ACCT_NUM = b.bank_acct_num(+)	
				);
			EXCEPTION
				WHEN OTHERS THEN
					vo_errcd := -6;
					vo_errmsg := SQLERRM(SQLCODE);
					RAISE vl_err;
			END;
		ELSE
			BEGIN
				SELECT h.update_seq, h.update_date INTO v_update_seq, v_update_date
				FROM IPNEXTG.T_MANY_HEADER h JOIN IPNEXTG.T_MANY_DETAIL d
				ON h.update_date = d.update_date
				AND h.update_seq = d.update_seq
				WHERE d.table_name = 'T_PAYRECH'
				AND h.approved_status = 'E'
				AND d.field_name = 'PAYREC_NUM'
				AND d.field_value = vp_doc_num(i)
				AND d.upd_status = 'I';
			EXCEPTION
				WHEN NO_DATA_FOUND THEN
					vo_errcd := -7;
					vo_errmsg := 'Voucher '||vp_doc_num(i)||' has already been approved/rejected, please retrieve the list of vouchers again';
					RAISE vl_err;
				WHEN OTHERS THEN 
					vo_errcd := -8;
					vo_errmsg := SQLERRM(SQLCODE);
					RAISE vl_err;
			END;
		
			BEGIN
				SELECT field_value INTO v_client_cd
				FROM IPNEXTG.T_MANY_DETAIL 
				WHERE update_date = v_update_date
				AND update_seq = v_update_seq
				AND table_name = 'T_PAYRECH'
				AND field_name = 'CLIENT_CD'
				AND upd_status = 'I';
			EXCEPTION
				WHEN OTHERS THEN
					vo_errcd := -9;
					vo_errmsg := SQLERRM(SQLCODE);
					RAISE vl_err;
			END;
			
			BEGIN
				INSERT INTO R_VOUCHER
				(
					SELECT h.payrec_num, h.payrec_date, h.client_cd, TRIM(h.gl_acct_cd), h.sl_acct_cd, h.curr_amt, TRIM(d.gl_acct_cd), d.sl_acct_cd, d.db_cr_flg, d.doc_ref_num, d.doc_date, DECODE(SUBSTR(h.payrec_num,5,1),'R', DECODE(d.db_cr_flg,'C',d.payrec_amt, -1 * d.payrec_amt), DECODE(d.db_cr_flg,'D',d.payrec_amt, -1 * d.payrec_amt)) PAYREC_AMT, d.remarks, d.tal_id,	
					--DECODE(d.record_source,'GL','M','VCH',' ',SUBSTR(d.doc_ref_num,5,1))||' '||d.ref_folder_cd ref_folder_cd, 
					CASE 
						WHEN d.record_source IN ('VCH','ARAP') THEN '  '||d.ref_folder_cd
						WHEN d.record_source = 'GL' THEN 'M '||SUBSTR(d.doc_ref_num,5)
						ELSE 'I '||SUBSTR(d.doc_ref_num,5)	
					END ref_folder_cd,
					DECODE(d.db_cr_flg,'D','P','R') RP_code,		
					DECODE(d.record_source,'BOND',l.lawan_name,m.client_name), h.remarks, d.record_source, g.acct_name,	h.folder_cd, h.num_cheq, f.bank_acct_fmt, h.user_id, vl_random_value, vp_user_id, vp_generate_date	
					FROM 
					(
						SELECT MAX(PAYREC_NUM) PAYREC_NUM, MAX(PAYREC_DATE) PAYREC_DATE, MAX(CLIENT_CD) CLIENT_CD, MAX(GL_ACCT_CD) GL_ACCT_CD, MAX(SL_ACCT_CD) SL_ACCT_CD, MAX(CURR_AMT) CURR_AMT, MAX(REMARKS) REMARKS, MAX(FOLDER_CD) FOLDER_CD, MAX(NUM_CHEQ) NUM_CHEQ, MAX(USER_ID) USER_ID
						FROM 
						(
							SELECT 	DECODE (field_name, 'PAYREC_NUM', field_value, NULL) PAYREC_NUM,
									DECODE (field_name, 'PAYREC_DATE', field_value, NULL) PAYREC_DATE,
									DECODE (field_name, 'CLIENT_CD', field_value, NULL) CLIENT_CD,
									DECODE (field_name, 'GL_ACCT_CD', field_value, NULL) GL_ACCT_CD,
									DECODE (field_name, 'SL_ACCT_CD', field_value, NULL) SL_ACCT_CD,
									DECODE (field_name, 'CURR_AMT', field_value, NULL) CURR_AMT,
									DECODE (field_name, 'REMARKS', field_value, NULL) REMARKS,
									DECODE (field_name, 'FOLDER_CD', field_value, NULL) FOLDER_CD,
									DECODE (field_name, 'NUM_CHEQ', field_value, NULL) NUM_CHEQ,
									DECODE (field_name, 'USER_ID', field_value, NULL) USER_ID,
									record_seq
							FROM IPNEXTG.T_MANY_DETAIL 
							WHERE update_date = v_update_date
							AND update_seq = v_update_seq
							AND table_name = 'T_PAYRECH'
							AND upd_status = 'I'
							AND field_name IN ('PAYREC_NUM','PAYREC_DATE','CLIENT_CD','GL_ACCT_CD','SL_ACCT_CD','CURR_AMT','REMARKS','FOLDER_CD','NUM_CHEQ','USER_ID')
						)
						GROUP BY record_seq
					) h 
					JOIN 
					(
						SELECT MAX(PAYREC_NUM) PAYREC_NUM, MAX(GL_ACCT_CD) GL_ACCT_CD, MAX(SL_ACCT_CD) SL_ACCT_CD, MAX(DB_CR_FLG) DB_CR_FLG, MAX(DOC_REF_NUM) DOC_REF_NUM, MAX(DOC_DATE) DOC_DATE, MAX(PAYREC_AMT) PAYREC_AMT, MAX(REMARKS) REMARKS, MAX(TAL_ID) TAL_ID, MAX(RECORD_SOURCE) RECORD_SOURCE, MAX(REF_FOLDER_CD) REF_FOLDER_CD
						FROM 
						(
							SELECT 	DECODE (field_name, 'PAYREC_NUM', field_value, NULL) PAYREC_NUM,
									DECODE (field_name, 'GL_ACCT_CD', field_value, NULL) GL_ACCT_CD,
									DECODE (field_name, 'SL_ACCT_CD', field_value, NULL) SL_ACCT_CD,
									DECODE (field_name, 'DB_CR_FLG', field_value, NULL) DB_CR_FLG,
									DECODE (field_name, 'DOC_REF_NUM', field_value, NULL) DOC_REF_NUM,
									DECODE (field_name, 'DOC_DATE', field_value, NULL) DOC_DATE,
									DECODE (field_name, 'PAYREC_AMT', field_value, NULL) PAYREC_AMT,
									DECODE (field_name, 'REMARKS', field_value, NULL) REMARKS,
									DECODE (field_name, 'TAL_ID', field_value, NULL) TAL_ID,
									DECODE (field_name, 'RECORD_SOURCE', field_value, NULL) RECORD_SOURCE,
									DECODE (field_name, 'REF_FOLDER_CD', field_value, NULL) REF_FOLDER_CD,
									record_seq
							FROM IPNEXTG.T_MANY_DETAIL 
							WHERE update_date = v_update_date
							AND update_seq = v_update_seq
							AND table_name = 'T_PAYRECD'
							AND upd_status = 'I'
							AND field_name IN ('PAYREC_NUM','GL_ACCT_CD','SL_ACCT_CD','DB_CR_FLG','DOC_REF_NUM','DOC_DATE','PAYREC_AMT','REMARKS', 'TAL_ID','RECORD_SOURCE','REF_FOLDER_CD')
						)
						GROUP BY record_seq
					) d 
					ON h.payrec_num = d.payrec_num
					LEFT JOIN IPNEXTG.MST_CLIENT m ON h.client_cd = m.client_cd
					LEFT JOIN IPNEXTG.MST_LAWAN_BOND_TRX l ON h.client_cd = l.lawan
					LEFT JOIN IPNEXTG.MST_GL_ACCOUNT g ON RPAD(TRIM(h.gl_acct_cd), 12) = g.gl_a AND TRIM(h.sl_acct_cd) = g.sl_a
					LEFT JOIN IPNEXTG.MST_CLIENT_FLACCT f ON h.client_cd = f.client_cd AND f.acct_stat IN ('A','I')	
					WHERE h.payrec_num = vp_doc_num(i)														
				);
			EXCEPTION
				WHEN OTHERS THEN
					vo_errcd := -10;
					vo_errmsg := SQLERRM(SQLCODE);
					RAISE vl_err;
			END;
			
			BEGIN
				INSERT INTO R_CHEQ
				(
					SELECT bg_cq_flg, chq_num, chq_dt, chq_amt, 
					NVL(b.acct_NAME,c.payee_name)||' / '||TRIM(c.PAYEE_ACCT_NUM)||' / '||TRIM(NVL(b.bank_short_name,c.bank_name))||' '||TRIM(NVL(b.BANK_BRCH_NAME,'')) payee_bank, vp_doc_num(i), vl_random_value, vp_user_id, vp_generate_date		
					FROM
					( 
						SELECT T_CHEQ.*, p.BANK_NAME		
						FROM 
						(
							SELECT MAX(RVPV_NUMBER) RVPV_NUMBER, MAX(BG_CQ_FLG) BG_CQ_FLG, MAX(CHQ_NUM) CHQ_NUM, MAX(CHQ_DT) CHQ_DT, MAX(CHQ_AMT) CHQ_AMT, MAX(PAYEE_NAME) PAYEE_NAME, MAX(PAYEE_ACCT_NUM) PAYEE_ACCT_NUM, MAX(PAYEE_BANK_CD) PAYEE_BANK_CD
							FROM 
							(
								SELECT 	DECODE (field_name, 'RVPV_NUMBER', field_value, NULL) RVPV_NUMBER,
										DECODE (field_name, 'BG_CQ_FLG', field_value, NULL) BG_CQ_FLG,
										DECODE (field_name, 'CHQ_NUM', field_value, NULL) CHQ_NUM,
										DECODE (field_name, 'CHQ_DT', field_value, NULL) CHQ_DT,
										DECODE (field_name, 'CHQ_AMT', field_value, NULL) CHQ_AMT,
										DECODE (field_name, 'PAYEE_NAME', field_value, NULL) PAYEE_NAME,
										DECODE (field_name, 'PAYEE_ACCT_NUM', field_value, NULL) PAYEE_ACCT_NUM,
										DECODE (field_name, 'PAYEE_BANK_CD', field_value, NULL) PAYEE_BANK_CD,
										record_seq
								FROM IPNEXTG.T_MANY_DETAIL 
								WHERE update_date = v_update_date
								AND update_seq = v_update_seq
								AND table_name = 'T_CHEQ'
								AND upd_status <> 'C'
								AND field_name IN ('RVPV_NUMBER','BG_CQ_FLG','CHQ_NUM','CHQ_DT','CHQ_AMT','PAYEE_NAME','PAYEE_ACCT_NUM','PAYEE_BANK_CD')
							)
							GROUP BY record_seq
						) T_CHEQ,		
						( 
							SELECT BANK_CD, BANK_NAME	
							FROM IPNEXTG.MST_IP_BANK
							WHERE APPROVED_STAT='A'
						) p 	
						WHERE rvpv_number = vp_doc_num(i)
						AND payee_bank_cd = p.BANK_CD(+)
					) c,
					( 
						SELECT 'Payee ' AS payee_type, bank_acct_num, bank_short_name, acct_name, bank_brch_name
						FROM IPNEXTG.V_CLIENT_BANK 	
						WHERE client_cd = v_client_cd
						UNION	
						SELECT 'Rek Dana ' AS payee_type, c.bank_acct_fmt, bank_short_name, c.acct_name, '' 		
						FROM IPNEXTG.MST_CLIENT_FLACCT c		
						WHERE c.client_cd = v_client_cd
						AND c.acct_stat IN ('A','I')
					) b	
					WHERE  c.PAYEE_ACCT_NUM = b.bank_acct_num(+)	
				);
			EXCEPTION
				WHEN OTHERS THEN
					vo_errcd := -11;
					vo_errmsg := SQLERRM(SQLCODE);
					RAISE vl_err;
			END;
		END IF;
	END LOOP;

    vo_random_value := vl_random_value;
    vo_errcd := 1;
    vo_errmsg := '';
	
  COMMIT;
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
END SPR_VOUCHER;