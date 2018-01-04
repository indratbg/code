create or replace PROCEDURE SP_T_STK_MOVEMENT_APPROVE
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
--[INDRA] 23NOV2017 SUPAYA JIKA UPDATE/CANCEL JURNAL OTC, CANCEL DULU JURNAL GL
--[IN] 03 may 2017 update t_contracts jika jurnal yang dicancel adalah jurnal settle trx, tanda jurnal settle trx s_d_type='V' pada t_stk_movement

	v_client_cd						T_STK_MOVEMENT.client_cd%TYPE;
	v_stk_cd						T_STK_MOVEMENT.stk_cd%TYPE;
	v_gl_acct_cd					T_STK_MOVEMENT.gl_acct_cd%TYPE;
	v_db_cr_flg						T_STK_MOVEMENT.db_cr_flg%TYPE;
	v_qty							T_STK_MOVEMENT.total_share_qty%TYPE;
	v_total_share_qty 				T_STK_MOVEMENT.total_share_qty%TYPE;
	v_withdrawn_share_qty			T_STK_MOVEMENT.withdrawn_share_qty%TYPE;
	v_jur_type						T_STK_MOVEMENT.jur_type%TYPE;
	v_doc_num						T_STK_MOVEMENT.doc_num%TYPE;
	v_doc_dt						T_STK_MOVEMENT.doc_dt%TYPE;
	v_ref_doc_num					T_STK_MOVEMENT.ref_doc_num%TYPE;
	v_prev_doc_num					T_STK_MOVEMENT.prev_doc_num%TYPE;
	v_user_id						T_STK_MOVEMENT.user_id%TYPE;
	v_cre_dt						T_STK_MOVEMENT.cre_dt%TYPE;
	v_movement_type					VARCHAR2(20);
	v_repo_ref						VARCHAR2(20);
	
	v_new_doc_num					T_STK_MOVEMENT.doc_num%TYPE;
	v_doc_num2						T_STK_MOVEMENT.doc_num%TYPE;
	v_client_cd2					T_STK_MOVEMENT.client_cd%TYPE;
	
	v_ratio							NUMBER;
	v_ratio_reason					VARCHAR2(200);
	
	v_cnt							NUMBER:=0;
	v_reversal_flg					NUMBER;
	
	CURSOR csr_stk_mov IS
		SELECT DISTINCT record_seq FROM T_MANY_DETAIL
		WHERE UPDATE_DATE = p_update_date
		AND UPDATE_SEQ = p_update_seq;

	v_sql							VARCHAR2(32767);
	v_err 							EXCEPTION;
	v_error_code					NUMBER;
	v_error_msg						VARCHAR2(200);
	v_table_name 					T_MANY_DETAIL.table_name%TYPE := 'T_STK_MOVEMENT';
	v_status        		    	T_MANY_DETAIL.upd_status%TYPE;
	v_table_rowid					T_MANY_DETAIL.table_rowid%TYPE;
  V_S_D_TYPE T_STK_MOVEMENT.S_D_TYPE%TYPE;
  V_SETT_VAL T_CONTRACTS.SETT_VAL%TYPE;
  V_STK_FLG VARCHAR2(1):='Y';
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
	
	BEGIN
		SELECT 
			CASE SUBSTR(FIELD_VALUE,5,3)
				WHEN 'REV' THEN 1
				ELSE
					0 
			END
		INTO v_reversal_flg
		FROM T_MANY_DETAIL
		WHERE UPDATE_SEQ = p_update_seq
		AND UPDATE_DATE = p_update_date
		AND RECORD_SEQ = 1
		AND FIELD_NAME = 'DOC_NUM';
	EXCEPTION
		WHEN OTHERS THEN
			v_error_code := -3;
			v_error_msg :=  SUBSTR('Retrieve  T_MANY_DETAIL for '||p_update_seq||SQLERRM,1,200);
			RAISE v_err;
	END;
	
	IF v_status <> 'U' OR v_reversal_flg = 1 THEN
		FOR rec IN csr_stk_mov LOOP
			BEGIN
				SELECT MAX(CLIENT_CD), MAX(STK_CD), MAX(GL_ACCT_CD), MAX(DB_CR_FLG), MAX(DOC_NUM), MAX(REF_DOC_NUM), MAX(PREV_DOC_NUM), MAX(TOTAL_SHARE_QTY), MAX(WITHDRAWN_SHARE_QTY), MAX(JUR_TYPE), MAX(REPO_REF), MAX(RATIO), MAX(RATIO_REASON), MAX(USER_ID), TO_DATE(MAX(CRE_DT),'YYYY-MM-DD HH24:MI:SS')
				INTO v_client_cd, v_stk_cd, v_gl_acct_cd, v_db_cr_flg, v_doc_num, v_ref_doc_num, v_prev_doc_num, v_total_share_qty, v_withdrawn_share_qty, v_jur_type, v_repo_ref, v_ratio, v_ratio_reason, v_user_id, v_cre_dt
				FROM
				(
					SELECT DECODE(field_name,'CLIENT_CD',field_value, NULL) CLIENT_CD,
						   DECODE(field_name,'STK_CD',field_value, NULL) STK_CD,
						   DECODE(field_name,'GL_ACCT_CD',field_value, NULL) GL_ACCT_CD,
						   DECODE(field_name,'DB_CR_FLG',field_value, NULL) DB_CR_FLG,
						   DECODE(field_name,'DOC_NUM',field_value, NULL) DOC_NUM,
						   DECODE(field_name,'REF_DOC_NUM',field_value, NULL) REF_DOC_NUM,
						   DECODE(field_name,'PREV_DOC_NUM',field_value, NULL) PREV_DOC_NUM,
						   DECODE(field_name,'TOTAL_SHARE_QTY',field_value, NULL) TOTAL_SHARE_QTY,
						   DECODE(field_name,'WITHDRAWN_SHARE_QTY',field_value, NULL) WITHDRAWN_SHARE_QTY,
						   DECODE(field_name,'JUR_TYPE',field_value, NULL) JUR_TYPE,
						   DECODE(field_name,'REPO_REF',field_value, NULL) REPO_REF,
						   DECODE(field_name,'RATIO',field_value, NULL) RATIO,
						   DECODE(field_name,'RATIO_REASON',field_value, NULL) RATIO_REASON,
						   DECODE(field_name,'USER_ID',field_value, NULL) USER_ID,
						   DECODE(field_name,'CRE_DT',field_value, NULL) CRE_DT
					FROM  T_MANY_DETAIL
					WHERE T_MANY_DETAIL.update_date = p_update_date
					AND T_MANY_DETAIL.update_seq = p_update_seq
					AND T_MANY_DETAIL.table_name = v_table_name
					AND T_MANY_DETAIL.record_seq = rec.record_seq
					AND T_MANY_DETAIL.field_name IN ('CLIENT_CD', 'STK_CD', 'GL_ACCT_CD', 'DB_CR_FLG','DOC_NUM','REF_DOC_NUM','PREV_DOC_NUM','TOTAL_SHARE_QTY','WITHDRAWN_SHARE_QTY','JUR_TYPE','REPO_REF','RATIO','RATIO_REASON','USER_ID','CRE_DT')
				);
			EXCEPTION
				WHEN OTHERS THEN
					v_error_code := -4;
					v_error_msg :=  SUBSTR('Retrieve  T_MANY_DETAIL '||SQLERRM,1,200);
					RAISE v_err;
			END;
			
			IF SUBSTR(v_doc_num,5,3) = 'REV' THEN 	-- REVERSE JOURNAL
				CASE SUBSTR(v_prev_doc_num,5,3)
					WHEN 'RSN' THEN
						v_movement_type := 'RECEIVE';
					WHEN 'WSN' THEN
						v_movement_type := 'WITHDRAW';
					WHEN 'JVA' THEN
	--					IF v_jur_type NOT IN ('RECV','WHDR') THEN-- Exclude SETTLE
							CASE 
								WHEN v_ref_doc_num IN ('UNSETTLED','REPO CLIENT') THEN
									v_movement_type := 'REPO';
								ELSE
									v_movement_type := 'RETURN REPO';
							END CASE;
	--					ELSE
	--						IF v_jur_type = 'RECV' THEN
	--							v_movement_type := 'RECEIVE';
	--						ELSE
	--							v_movement_type := 'WITHDRAW';
	--						END IF;
	--					END IF;
					ELSE
						v_movement_type := 'RECEIVE';
				END CASE;
			ELSE
				CASE SUBSTR(v_doc_num,5,3)
					WHEN 'RSN' THEN
						v_movement_type := 'RECEIVE';
					WHEN 'WSN' THEN
						v_movement_type := 'WITHDRAW';
					WHEN 'JVA' THEN
	--					IF v_jur_type NOT IN ('RECV','WHDR') THEN-- Exclude SETTLE
							CASE 
								WHEN v_ref_doc_num IN ('UNSETTLED','REPO CLIENT') THEN
									v_movement_type := 'REPO';
								ELSE
									v_movement_type := 'RETURN REPO';
							END CASE;
	--					ELSE
	--						IF v_jur_type = 'RECV' THEN
	--							v_movement_type := 'RECEIVE';
	--						ELSE
	--							v_movement_type := 'WITHDRAW';
	--						END IF;
	--					END IF;
					ELSE
						v_movement_type := 'RECEIVE';
				END CASE;
			END IF;
			
			IF v_movement_type = 'WITHDRAW' THEN
				v_qty := v_withdrawn_share_qty;
			ELSE
				v_qty := v_total_share_qty;
			END IF;
			
			BEGIN
				SP_UPD_T_STKHAND(v_client_cd, v_stk_cd, v_gl_acct_cd, v_db_cr_flg, v_qty, v_jur_type, v_user_id, v_error_code, v_error_msg);
			EXCEPTION
				WHEN OTHERS THEN
					v_error_code := -5;
					v_error_msg := SUBSTR('SP_UPD_T_STKHAND '||v_table_name||SQLERRM,1,200);
					RAISE v_err;
			END;
			
			IF v_error_code < 0 THEN
				v_error_code := -6;
				v_error_msg := 'SP_UPD_T_STKHAND '||v_error_msg;
				RAISE v_err;
			END IF;
				
			/*IF v_db_cr_flg = 'D' THEN
				CASE 
					WHEN v_gl_acct_cd = '09' THEN
						BEGIN
							UPDATE T_STKHAND
							SET ON_BAE = ON_BAE + v_qty
							WHERE CLIENT_CD = v_client_cd
							AND STK_CD = v_stk_cd;
						EXCEPTION
							WHEN OTHERS THEN
								v_error_code := -5;
								v_error_msg := SUBSTR('UPDATE T_STKHAND '||SQLERRM,1,200);
								RAISE v_err;
						END;
					WHEN v_gl_acct_cd = '12' THEN
						IF v_movement_type NOT IN ('REPO','RETURN REPO') THEN
							BEGIN
								UPDATE T_STKHAND
								SET BAL_QTY = BAL_QTY + v_qty
								WHERE CLIENT_CD = v_client_cd
								AND STK_CD = v_stk_cd;
							EXCEPTION
								WHEN OTHERS THEN
									v_error_code := -6;
									v_error_msg := SUBSTR('UPDATE T_STKHAND '||SQLERRM,1,200);
									RAISE v_err;
							END;
						END IF;
					WHEN v_gl_acct_cd = '33' THEN
						BEGIN
							UPDATE T_STKHAND
							SET ON_CUSTODY = ON_CUSTODY - v_qty
							WHERE CLIENT_CD = v_client_cd
							AND STK_CD = v_stk_cd;
						EXCEPTION
							WHEN OTHERS THEN
								v_error_code := -7;
								v_error_msg := SUBSTR('UPDATE T_STKHAND '||SQLERRM,1,200);
								RAISE v_err;
						END;
					WHEN v_gl_acct_cd IN ('35','36') THEN
						BEGIN
							UPDATE T_STKHAND
							SET ON_HAND = ON_HAND - v_qty
							WHERE CLIENT_CD = v_client_cd
							AND STK_CD = v_stk_cd;
						EXCEPTION
							WHEN OTHERS THEN
								v_error_code := -7;
								v_error_msg := SUBSTR('UPDATE T_STKHAND '||SQLERRM,1,200);
								RAISE v_err;
						END;
				END CASE;
			ELSE
				CASE 
					WHEN v_gl_acct_cd = '09' THEN
						BEGIN
							UPDATE T_STKHAND
							SET ON_BAE = ON_BAE - v_qty
							WHERE CLIENT_CD = v_client_cd
							AND STK_CD = v_stk_cd;
						EXCEPTION
							WHEN OTHERS THEN
								v_error_code := -8;
								v_error_msg := SUBSTR('UPDATE T_STKHAND '||SQLERRM,1,200);
								RAISE v_err;
						END;
					WHEN v_gl_acct_cd = '12' THEN
						IF v_movement_type NOT IN ('REPO','RETURN REPO') THEN
							BEGIN
								UPDATE T_STKHAND
								SET BAL_QTY = BAL_QTY - v_qty
								WHERE CLIENT_CD = v_client_cd
								AND STK_CD = v_stk_cd;
							EXCEPTION
								WHEN OTHERS THEN
									v_error_code := -9;
									v_error_msg := SUBSTR('UPDATE T_STKHAND '||SQLERRM,1,200);
									RAISE v_err;
							END;
						END IF;
					WHEN v_gl_acct_cd = '33' THEN
						BEGIN
							UPDATE T_STKHAND
							SET ON_CUSTODY = ON_CUSTODY + v_qty
							WHERE CLIENT_CD = v_client_cd
							AND STK_CD = v_stk_cd;
						EXCEPTION
							WHEN OTHERS THEN
								v_error_code := -7;
								v_error_msg := SUBSTR('UPDATE T_STKHAND '||SQLERRM,1,200);
								RAISE v_err;
						END;
					WHEN v_gl_acct_cd IN ('35','36') THEN
						BEGIN
							UPDATE T_STKHAND
							SET ON_HAND = ON_HAND + v_qty
							WHERE CLIENT_CD = v_client_cd
							AND STK_CD = v_stk_cd;
						EXCEPTION
							WHEN OTHERS THEN
								v_error_code := -10;
								v_error_msg := SUBSTR('UPDATE T_STKHAND '||SQLERRM,1,200);
								RAISE v_err;
						END;
				END CASE;
			END IF;
			
			BEGIN
				UPDATE T_STKHAND
				SET UPD_BY = v_user_id, UPD_DT = v_cre_dt
				WHERE CLIENT_CD = v_client_cd
				AND STK_CD = v_stk_cd;
			EXCEPTION
				WHEN OTHERS THEN
					v_error_code := -7;
					v_error_msg := SUBSTR('UPDATE T_STKHAND '||SQLERRM,1,200);
					RAISE v_err;
			END;*/
			
		
		
			/*IF v_db_cr_flg = 'D' THEN
				CASE 
					WHEN v_gl_acct_cd = '09' THEN
						BEGIN
							INSERT INTO T_STKHAND (CLIENT_CD, STK_CD, L_F, ON_BAE, CRE_DT, CRE_BY)
							VALUES(v_client_cd, v_stk_cd, 'L', v_qty, v_cre_dt, v_user_id);
						EXCEPTION
							WHEN OTHERS THEN
								v_error_code := -11;
								v_error_msg := SUBSTR('INSERT TO T_STKHAND '||SQLERRM,1,200);
								RAISE v_err;
						END;
					WHEN v_gl_acct_cd = '12' THEN
						IF v_movement_type NOT IN ('REPO','RETURN REPO') THEN
							BEGIN
								INSERT INTO T_STKHAND (CLIENT_CD, STK_CD, L_F, BAL_QTY, CRE_DT, CRE_BY)
								VALUES(v_client_cd, v_stk_cd, 'L', v_qty, v_cre_dt, v_user_id);
							EXCEPTION
								WHEN OTHERS THEN
									v_error_code := -12;
									v_error_msg := SUBSTR('INSERT TO T_STKHAND '||SQLERRM,1,200);
									RAISE v_err;
							END;
						END IF;
				END CASE;
			ELSE
				CASE 
					WHEN v_gl_acct_cd IN ('35','36') THEN
						BEGIN
							INSERT INTO T_STKHAND (CLIENT_CD, STK_CD, L_F, ON_HAND, CRE_DT, CRE_BY)
							VALUES(v_client_cd, v_stk_cd, 'L', v_qty, v_cre_dt, v_user_id);
						EXCEPTION
							WHEN OTHERS THEN
								v_error_code := -13;
								v_error_msg := SUBSTR('INSERT TO T_STKHAND '||SQLERRM,1,200);
								RAISE v_err;
						END;
					WHEN v_gl_acct_cd = '33' THEN
						BEGIN
							INSERT INTO T_STKHAND (CLIENT_CD, STK_CD, L_F, ON_CUSTODY, CRE_DT, CRE_BY)
							VALUES(v_client_cd, v_stk_cd, 'L', v_qty, v_cre_dt, v_user_id);
						EXCEPTION
							WHEN OTHERS THEN
								v_error_code := -14;
								v_error_msg := SUBSTR('INSERT TO T_STKHAND '||SQLERRM,1,200);
								RAISE v_err;
						END;
				END CASE;
			END IF;*/
		
			IF (rec.record_seq = 1 OR rec.record_seq = 3) AND (v_movement_type = 'RETURN REPO' OR v_jur_type IN ('TOFFBUYDU1','TOFFSELLDU','BORROWRTN','LENDRTN','LENDPERTN')) THEN
					BEGIN
						UPDATE T_STK_MOVEMENT
						SET REF_DOC_NUM = DECODE(SUBSTR(v_doc_num,5,3),'REV','UNSETTLED','SETTLED')
						WHERE DOC_NUM = v_ref_doc_num;
					EXCEPTION
						WHEN OTHERS THEN
							v_error_code := -7;
							v_error_msg := SUBSTR('UPDATE '||v_table_name||' '||SQLERRM,1,200);
							RAISE v_err;
					END;
			END IF;
			
			IF rec.record_seq = 1 AND SUBSTR(v_doc_num,5,3) = 'REV' THEN
				BEGIN
					UPDATE T_STK_MOVEMENT
					SET DOC_STAT = '9'
					WHERE doc_num = v_prev_doc_num;
				EXCEPTION
					WHEN OTHERS THEN
						v_error_code := -8;
						v_error_msg := SUBSTR('UPDATE '||v_table_name||' '||SQLERRM,1,200);
						RAISE v_err;
				END;
				
				/*IF v_movement_type = 'RETURN REPO' THEN
					BEGIN
						UPDATE T_STK_MOVEMENT
						SET REF_DOC_NUM = 'REPO CLIENT'
						WHERE DOC_NUM = v_ref_doc_num;
					EXCEPTION
						WHEN OTHERS THEN
							v_error_code := -14;
							v_error_msg := SUBSTR('UPDATE '||v_table_name||' '||SQLERRM,1,200);
							RAISE v_err;
					END;
				END IF;*/
			END IF;
			
			IF rec.record_seq = 1 OR rec.record_seq = 3 THEN
				IF v_movement_type = 'REPO' THEN
					IF SUBSTR(v_doc_num,5,3) <> 'REV' THEN
						BEGIN
							INSERT INTO T_REPO_STK(REPO_NUM, DOC_NUM, MVMT_TYPE, USER_ID, CRE_DT, APPROVED_STAT) VALUES(v_repo_ref, v_doc_num, 'REPO', v_user_id, v_cre_dt, 'A');
						EXCEPTION
							WHEN OTHERS THEN
								v_error_code := -9;
								v_error_msg := SUBSTR('INSERT INTO T_REPO_STK '||SQLERRM,1,200);
								RAISE v_err;
						END;
					ELSE
						BEGIN
							UPDATE T_REPO_STK SET APPROVED_STAT = 'C'
							WHERE doc_num = v_prev_doc_num;
						EXCEPTION
							WHEN OTHERS THEN
								v_error_code := -10;
								v_error_msg := SUBSTR('UPDATE T_REPO_STK '||SQLERRM,1,200);
								RAISE v_err;
						END;
					END IF;
					
				ELSIF v_movement_type = 'RETURN REPO' THEN
					IF SUBSTR(v_doc_num,5,3) <> 'REV' THEN
						BEGIN
							INSERT INTO T_REPO_STK(REPO_NUM, DOC_NUM, MVMT_TYPE, USER_ID, CRE_DT, APPROVED_STAT)  VALUES(v_repo_ref, v_doc_num, 'RETURN', v_user_id, v_cre_dt, 'A');
						EXCEPTION
							WHEN OTHERS THEN
								v_error_code := -11;
								v_error_msg := SUBSTR('INSERT INTO T_REPO_STK '||SQLERRM,1,200);
								RAISE v_err;
						END;
					ELSE
						BEGIN
							UPDATE T_REPO_STK SET APPROVED_STAT = 'C'
							WHERE doc_num = v_prev_doc_num;
						EXCEPTION
							WHEN OTHERS THEN
								v_error_code := -12;
								v_error_msg := SUBSTR('UPDATE T_REPO_STK '||SQLERRM,1,200);
								RAISE v_err;
						END;
					END IF;
					
				ELSIF v_movement_type = 'WITHDRAW' THEN
					IF v_ratio IS NOT NULL THEN
						BEGIN
							LOG_BLOCKING(TRUNC(v_cre_dt), v_client_cd, 'Withdraw '||v_stk_cd||' '||v_qty, v_ratio, v_ratio_reason, v_doc_num, v_user_id, v_error_code, v_error_msg);
						EXCEPTION
							WHEN OTHERS THEN
								v_error_code := -13;
								v_error_msg := SUBSTR('LOG_BLOCKING '||SQLERRM,1,200);
								RAISE v_err;
						END;
						
						IF v_error_code < 0 THEN
							v_error_code := -14;
							v_error_msg := 'LOG_BLOCKING '||v_error_msg;
							RAISE v_err;
						END IF;
					END IF;
				END IF;	
				
			END IF;
		END LOOP;
	END IF;
	
	BEGIN
		SP_T_MANY_APPROVE(p_menu_name, p_update_date, p_update_seq, p_approved_user_id, p_approved_ip_address, v_error_code, v_error_msg); 
	EXCEPTION
		WHEN OTHERS THEN
			v_error_code := -15;
			v_error_msg := SUBSTR('SP_T_MANY_APPROVE '||SQLERRM,1,200);
			RAISE v_err;
	END;	
	
	IF v_error_code < 0 THEN
		v_error_code := -16;
		v_error_msg := 'SP_T_MANY_APPROVE '||v_error_msg;
		RAISE v_err;
	END IF;
        
	IF v_status = 'I' THEN
		BEGIN
			SELECT MAX(record_seq) INTO v_cnt
			FROM T_MANY_DETAIL
			WHERE update_date = p_update_date
			AND update_seq = p_update_seq;
		EXCEPTION
			WHEN OTHERS THEN
				v_error_code := -21;
				v_error_msg := SUBSTR('COUNT T_MANY_DETAIL '||SQLERRM,1,200);
				RAISE v_err;
		END;
		
		IF v_cnt = 4 THEN
			BEGIN
				SELECT COUNT(*) INTO v_cnt
				FROM T_MANY_DETAIL
				WHERE update_date = p_update_date
				AND update_seq = p_update_seq
				AND field_name = 'S_D_TYPE'
				AND field_value <> 'C';
			EXCEPTION
				WHEN OTHERS THEN
					v_error_code := -22;
					v_error_msg := SUBSTR('COUNT T_MANY_DETAIL '||SQLERRM,1,200);
					RAISE v_err;
			END;
			
			IF v_cnt = 0 THEN -- MOVEMENT TYPE = MOVE
				BEGIN
					SELECT COUNT(*) INTO v_cnt
					FROM T_MANY_DETAIL
					WHERE update_date = p_update_date
					AND update_seq = p_update_seq
					AND field_name = 'JUR_TYPE'
					AND field_value = 'WHDR';
				EXCEPTION
					WHEN OTHERS THEN
						v_error_code := -23;
						v_error_msg := SUBSTR('COUNT T_MANY_DETAIL '||SQLERRM,1,200);
						RAISE v_err;
				END;
				
				IF v_cnt > 0 THEN -- SCRIPLESS
					BEGIN
						SELECT MAX(DOC_NUM), MAX(TO_DATE(DOC_DT,'yyyy/mm/dd hh24:mi:ss')), MAX(CLIENT_CD), MAX(STK_CD), MAX(WITHDRAWN_SHARE_QTY)
						INTO v_doc_num, v_doc_dt, v_client_cd, v_stk_cd, v_withdrawn_share_qty
						FROM
						(
							SELECT DECODE(field_name,'DOC_NUM',field_value, NULL) DOC_NUM,
									DECODE(field_name,'DOC_DT',field_value, NULL) DOC_DT,
									DECODE(field_name,'CLIENT_CD',field_value, NULL) CLIENT_CD,
									DECODE(field_name,'STK_CD',field_value, NULL) STK_CD,
									DECODE(field_name,'WITHDRAWN_SHARE_QTY',field_value, NULL) WITHDRAWN_SHARE_QTY
							FROM  T_MANY_DETAIL
							WHERE T_MANY_DETAIL.update_date = p_update_date
							AND T_MANY_DETAIL.update_seq = p_update_seq
							AND T_MANY_DETAIL.table_name = v_table_name
							AND T_MANY_DETAIL.record_seq = 
							(
								SELECT MIN(record_seq) 
								FROM T_MANY_DETAIL
								WHERE update_date = p_update_date
								AND update_seq = p_update_seq
								AND field_name = 'JUR_TYPE'
								AND field_value = 'WHDR'
							)
							AND T_MANY_DETAIL.field_name IN ('DOC_NUM','DOC_DT','CLIENT_CD', 'STK_CD', 'WITHDRAWN_SHARE_QTY')
						);
					EXCEPTION
						WHEN OTHERS THEN
							v_error_code := -24;
							v_error_msg :=  SUBSTR('Retrieve  T_MANY_DETAIL '||SQLERRM,1,200);
							RAISE v_err;
					END;
					
					BEGIN
						SELECT MAX(DOC_NUM), MAX(CLIENT_CD)
						INTO v_doc_num2, v_client_cd2
						FROM
						(
							SELECT DECODE(field_name,'DOC_NUM',field_value, NULL) DOC_NUM,
									DECODE(field_name,'CLIENT_CD',field_value, NULL) CLIENT_CD
							FROM  T_MANY_DETAIL
							WHERE T_MANY_DETAIL.update_date = p_update_date
							AND T_MANY_DETAIL.update_seq = p_update_seq
							AND T_MANY_DETAIL.table_name = v_table_name
							AND record_seq =
							(
								SELECT MIN(record_seq) 
								FROM T_MANY_DETAIL
								WHERE update_date = p_update_date
								AND update_seq = p_update_seq
								AND field_name = 'JUR_TYPE'
								AND field_value = 'RECV'
							)
							AND T_MANY_DETAIL.field_name IN ('DOC_NUM','CLIENT_CD')
						);
					EXCEPTION
						WHEN OTHERS THEN
							v_error_code := -25;
							v_error_msg :=  SUBSTR('Retrieve  T_MANY_DETAIL '||SQLERRM,1,200);
							RAISE v_err;
					END;
					
					BEGIN
						SP_STK_OTC_UPD(v_doc_num, v_doc_dt, v_client_cd, v_stk_cd, v_withdrawn_share_qty, NULL, 0, 'SECTRS', v_client_cd2,'OWNE', 'N', v_user_id, v_error_code, v_error_msg);
					EXCEPTION
						WHEN OTHERS THEN
							v_error_code := -26;
							v_error_msg := SUBSTR('SP_STK_OTC_UPD '||SQLERRM,1,200);
							RAISE v_err;
					END;
					
					IF v_error_code < 0 THEN
						v_error_code := -27;
						v_error_msg := 'SP_STK_OTC_UPD '||v_error_msg;
						RAISE v_err;
					END IF;
				/*	
					BEGIN
						UPDATE T_STK_OTC 
						SET recv_doc_num = v_doc_num2,
						approved_stat = 'A'
						WHERE doc_num = v_doc_num
						AND settle_date = v_doc_dt;
					EXCEPTION
						WHEN OTHERS THEN
							v_error_code := -20;
							v_error_msg :=  SUBSTR('UPDATE T_STK_OTC '||SQLERRM,1,200);
							RAISE v_err;
					END;
				*/
				END IF;
			END IF;
		
		ELSE
			BEGIN
				SELECT field_value INTO v_jur_type
				FROM T_MANY_DETAIL
				WHERE update_date = p_update_date
				AND update_seq = p_update_seq
				AND record_seq = 1
				AND field_name = 'JUR_TYPE';
			EXCEPTION
				WHEN OTHERS THEN
					v_error_code := -31;
					v_error_msg := SUBSTR('COUNT T_MANY_DETAIL '||SQLERRM,1,200);
					RAISE v_err;
			END;
			
			IF v_jur_type = 'EXERW' THEN
				BEGIN
					SELECT MAX(DOC_NUM), MAX(TO_DATE(DOC_DT,'yyyy/mm/dd hh24:mi:ss')), MAX(CLIENT_CD), MAX(STK_CD), MAX(WITHDRAWN_SHARE_QTY)
					INTO v_doc_num, v_doc_dt, v_client_cd, v_stk_cd, v_withdrawn_share_qty
					FROM
					(
						SELECT DECODE(field_name,'DOC_NUM',field_value, NULL) DOC_NUM,
								DECODE(field_name,'DOC_DT',field_value, NULL) DOC_DT,
								DECODE(field_name,'CLIENT_CD',field_value, NULL) CLIENT_CD,
								DECODE(field_name,'STK_CD',field_value, NULL) STK_CD,
								DECODE(field_name,'WITHDRAWN_SHARE_QTY',field_value, NULL) WITHDRAWN_SHARE_QTY
						FROM  T_MANY_DETAIL
						WHERE T_MANY_DETAIL.update_date = p_update_date
						AND T_MANY_DETAIL.update_seq = p_update_seq
						AND T_MANY_DETAIL.table_name = v_table_name
						AND T_MANY_DETAIL.record_seq = 1
						AND T_MANY_DETAIL.field_name IN ('DOC_NUM','DOC_DT','CLIENT_CD', 'STK_CD', 'WITHDRAWN_SHARE_QTY')
					);
				EXCEPTION
					WHEN OTHERS THEN
						v_error_code := -32;
						v_error_msg :=  SUBSTR('Retrieve  T_MANY_DETAIL '||SQLERRM,1,200);
						RAISE v_err;
				END;
			
				BEGIN
					INSERT INTO T_STK_OTC 
					(
						SETTLE_DATE, CLIENT_CD, BELI_JUAL,
						STK_CD, QTY, CUSTODIAN_CD, INSTRUCTION_TYPE, DOC_NUM,
						AMOUNT, CRE_DT, USER_ID, TO_CLIENT, XML_FLG
					)
					VALUES 
					( 
						v_doc_dt, v_client_Cd, 'W',
						v_stk_Cd, v_withdrawn_share_qty, NULL, 'EXERCS', v_doc_num,
						0, SYSDATE, v_user_id, NULL, 'N'
					);
				EXCEPTION
					WHEN OTHERS THEN
						v_error_code := -33;
						v_error_msg := SUBSTR('INSERT T_STK_OTC '||SQLERRM,1,200);
						RAISE v_err;
				END;
			
			ELSIF v_jur_type = 'EXERR' THEN
				
				BEGIN
					SELECT MAX(DOC_NUM), MAX(DOC_NUM2)
					INTO v_doc_num, v_doc_num2
					FROM
					(
						SELECT DECODE(field_name,'DOC_NUM',field_value, NULL) DOC_NUM,
								DECODE(field_name,'REPO_REF',field_value, NULL) DOC_NUM2
						FROM  T_MANY_DETAIL
						WHERE T_MANY_DETAIL.update_date = p_update_date
						AND T_MANY_DETAIL.update_seq = p_update_seq
						AND T_MANY_DETAIL.table_name = v_table_name
						AND T_MANY_DETAIL.record_seq = 1
						AND T_MANY_DETAIL.field_name IN ('DOC_NUM','REPO_REF')
					);
				EXCEPTION
					WHEN OTHERS THEN
						v_error_code := -34;
						v_error_msg :=  SUBSTR('Retrieve  T_MANY_DETAIL '||SQLERRM,1,200);
						RAISE v_err;
				END;
				
				BEGIN
					UPDATE T_STK_MOVEMENT
					SET ref_doc_num = v_doc_num
					WHERE doc_num = v_doc_num2;
				EXCEPTION
					WHEN OTHERS THEN
						v_error_code := -35;
						v_error_msg :=  SUBSTR('UPDATE T_STK_MOVEMENT '||SQLERRM,1,200);
						RAISE v_err;
				END;
				
			END IF;
		END IF;
		
	ELSIF v_reversal_flg = 1 THEN 
		BEGIN
			SELECT MAX(JUR_TYPE), MAX(PREV_DOC_NUM), MAX(DOC_DT),MAX(S_D_TYPE)S_D_TYPE
			INTO v_jur_type, v_prev_doc_num, v_doc_dt, V_S_D_TYPE
			FROM
			(
				SELECT DECODE(field_name,'JUR_TYPE',field_value, NULL) JUR_TYPE,
						DECODE(field_name,'PREV_DOC_NUM',field_value, NULL) PREV_DOC_NUM,
						DECODE(field_name,'DOC_DT',field_value, NULL) DOC_DT,
            DECODE(field_name,'S_D_TYPE',field_value, NULL) S_D_TYPE--03MAY2017
				FROM  T_MANY_DETAIL
				WHERE T_MANY_DETAIL.update_date = p_update_date
				AND T_MANY_DETAIL.update_seq = p_update_seq
				AND T_MANY_DETAIL.table_name = v_table_name
				AND record_seq = 1
				AND T_MANY_DETAIL.field_name IN ('JUR_TYPE','PREV_DOC_NUM','DOC_DT','S_D_TYPE')
			);
		EXCEPTION
			WHEN OTHERS THEN
				v_error_code := -41;
				v_error_msg :=  SUBSTR('RETRIEVE T_MANY_DETAIL '||SQLERRM,1,200);
				RAISE v_err;
		END;
		
	--	23NOV2017[INDRA] SUPAYA JIKA UPDATE/CANCEL JURNAL OTC, CANCEL DULU JURNAL GL
		IF V_STATUS IN('U','C') THEN

			BEGIN
				SELECT COUNT(1) INTO V_CNT FROM T_DAILY_OTC_JUR WHERE DOC_NUM=v_prev_doc_num AND XN_DOC_NUM IS NOT NULL;
			EXCEPTION	
				WHEN OTHERS THEN
					v_error_code := -42;
					v_error_msg :=  SUBSTR('SELECT JURNAL OTC FROM T_DAILY_OTC_JUR '||SQLERRM,1,200);
				RAISE v_err;
			END;

			IF V_CNT>0 THEN
				v_error_code := -43;
				v_error_msg :=  'Sudah dibuat jurnal GL OTC, cancel terlebih dahulu jurnal GL OTC sebelum approve';
				RAISE v_err;
			END IF;

		END IF;
	-- END 23NOV2017

    --03MAY2017
      IF V_STATUS='C' AND V_S_D_TYPE = 'V' AND SUBSTR(v_ref_doc_num,6,1) <> 'O' THEN
          
          BEGIN
            SELECT SETT_VAL INTO V_SETT_VAL FROM T_CONTRACTS WHERE CONTR_NUM=v_ref_doc_num;
          EXCEPTION
          WHEN NO_DATA_FOUND THEN
          V_SETT_VAL :=0;
          V_STK_FLG :='N';
          WHEN OTHERS THEN
              v_error_code := -501;
              v_error_msg :=  SUBSTR('CHECK SETT VAL T_CONTRCTS '||v_ref_doc_num||' '||SQLERRM,1,200);
              RAISE v_err;
           END;
           
            IF V_SETT_VAL>0 THEN
              v_error_code := -502;
              v_error_msg :=  'Jurnal Stock Movement sudah proses T3, silahkan finance cancel voucher settle transaksi yang bersangkutan ';
              RAISE v_err;
            ELSE
              IF V_STK_FLG<>'N' THEN
                    BEGIN
                      UPDATE T_CONTRACTS SET SETT_QTY = NVL(SETT_QTY,0)- (v_total_share_qty+v_withdrawn_share_qty)
                      where contr_num=v_ref_doc_num;
                    EXCEPTION
                    WHEN OTHERS THEN
                      v_error_code := -503;
                      v_error_msg :=  SUBSTR('UPDATE T_CONTRACTS, SETT_QTY '||v_ref_doc_num||' '||SQLERRM,1,200);
                      RAISE v_err;
                   END;
              END IF;
            END IF;
      END IF;--end 03may2017
    
    
		IF v_jur_type IN ('WHDR','RECV','EXERW') THEN
			IF v_status = 'C' THEN
				IF v_jur_type IN ('WHDR','EXERW') THEN
					BEGIN
						DELETE FROM T_STK_OTC
						WHERE doc_num = v_prev_doc_num;
					EXCEPTION
						WHEN OTHERS THEN
							v_error_code := -42;
							v_error_msg :=  SUBSTR('DELETE T_STK_OTC '||SQLERRM,1,200);
							RAISE v_err;
					END;
					
				ELSIF v_jur_type = 'RECV' THEN
					BEGIN
						DELETE FROM T_STK_OTC
						WHERE doc_num = REPLACE(v_prev_doc_num,'RSN','WSN');
					EXCEPTION
						WHEN OTHERS THEN
							v_error_code := -43;
							v_error_msg :=  SUBSTR('DELETE T_STK_OTC '||SQLERRM,1,200);
							RAISE v_err;
					END;
				END IF;
				
			ELSE -- UPDATE
				IF v_jur_type IN ('WHDR','RECV') THEN
					BEGIN
						SELECT COUNT(*) INTO v_cnt
						FROM T_STK_OTC
						WHERE doc_num = DECODE(v_jur_type, 'WHDR', v_prev_doc_num, REPLACE(v_prev_doc_num,'RSN','WSN'));
					EXCEPTION
						WHEN OTHERS THEN
							v_error_code := -44;
							v_error_msg :=  SUBSTR('SELECT T_STK_OTC '||SQLERRM,1,200);
							RAISE v_err;
					END;
					
					IF v_cnt > 0 THEN
						BEGIN
							SELECT new_doc_num INTO v_new_doc_num
							FROM T_STK_OTC
							WHERE doc_num = DECODE(v_jur_type, 'WHDR', v_prev_doc_num, REPLACE(v_prev_doc_num,'RSN','WSN'));
						EXCEPTION
							WHEN OTHERS THEN
								v_error_code := -45;
								v_error_msg :=  SUBSTR('SELECT T_STK_OTC '||SQLERRM,1,200);
								RAISE v_err;
						END;
						
						IF v_new_doc_num IS NULL THEN
							BEGIN
								SELECT field_value INTO v_doc_num
								FROM T_MANY_DETAIL
								WHERE update_date = p_update_date
								AND update_seq = p_update_seq
								AND table_name = v_table_name
								AND record_seq = 3
								AND field_name = 'DOC_NUM';
							EXCEPTION
								WHEN OTHERS THEN
									v_error_code := -46;
									v_error_msg :=  SUBSTR('SELECT T_MANY_DETAIL '||SQLERRM,1,200);
									RAISE v_err;
							END;
						
							BEGIN
								UPDATE T_STK_OTC
								SET new_doc_num = REPLACE(v_doc_num,'RSN','WSN')
								WHERE doc_num = DECODE(v_jur_type, 'WHDR', v_prev_doc_num, REPLACE(v_prev_doc_num,'RSN','WSN'));
							EXCEPTION
								WHEN OTHERS THEN
									v_error_code := -47;
									v_error_msg :=  SUBSTR('UPDATE T_STK_OTC '||SQLERRM,1,200);
									RAISE v_err;
							END;
							
						ELSE
							BEGIN
								DELETE FROM T_STK_OTC
								WHERE doc_num = DECODE(v_jur_type, 'WHDR', v_prev_doc_num, REPLACE(v_prev_doc_num,'RSN','WSN'));
							EXCEPTION
								WHEN OTHERS THEN
									v_error_code := -48;
									v_error_msg :=  SUBSTR('DELETE T_STK_OTC '||SQLERRM,1,200);
									RAISE v_err;
							END;
							
							BEGIN
								SELECT a.doc_dt, a.client_cd, a.stk_cd, a.withdrawn_share_qty, b.client_cd
								INTO v_doc_dt, v_client_cd, v_stk_cd, v_withdrawn_share_qty, v_client_cd2
								FROM T_STK_MOVEMENT a, T_STK_MOVEMENT b
								WHERE a.doc_num = v_new_doc_num
								AND a.db_cr_flg = 'D'
								AND b.doc_num = REPLACE(v_new_doc_num,'WSN','RSN')
								AND b.db_cr_flg = 'D';
							EXCEPTION
								WHEN OTHERS THEN
									v_error_code := -49;
									v_error_msg :=  SUBSTR('SELECT T_STK_MOVEMENT '||SQLERRM,1,200);
									RAISE v_err;
							END;
							
							-- INSERT NEW T_STK_OTC
							BEGIN
								SP_STK_OTC_UPD(v_new_doc_num, v_doc_dt, v_client_cd, v_stk_cd, v_withdrawn_share_qty, NULL, 0, 'SECTRS', v_client_cd2,'OWNE', 'N', v_user_id, v_error_code, v_error_msg);
							EXCEPTION
								WHEN OTHERS THEN
									v_error_code := -50;
									v_error_msg := SUBSTR('SP_STK_OTC_UPD '||SQLERRM,1,200);
									RAISE v_err;
							END;
						END IF;
					END IF;
				
				ELSE -- EXERW
					BEGIN
						SELECT field_value INTO v_doc_num
						FROM T_MANY_DETAIL
						WHERE update_date = p_update_date
						AND update_seq = p_update_seq
						AND table_name = v_table_name
						AND record_seq = 3
						AND field_name = 'DOC_NUM';
					EXCEPTION
						WHEN OTHERS THEN
							v_error_code := -51;
							v_error_msg :=  SUBSTR('SELECT T_MANY_DETAIL '||SQLERRM,1,200);
							RAISE v_err;
					END;
					
					BEGIN
						UPDATE T_STK_OTC
						SET doc_num = v_doc_num
						WHERE doc_num = v_prev_doc_num;
					EXCEPTION
						WHEN OTHERS THEN
							v_error_code := -52;
							v_error_msg :=  SUBSTR('UPDATE T_STK_OTC '||SQLERRM,1,200);
							RAISE v_err;
					END;
				END IF;
			END IF;
		
		ELSIF v_jur_type = 'EXERR' THEN
		
			IF v_status = 'C' THEN
				BEGIN
					UPDATE T_STK_MOVEMENT
					SET ref_doc_num = NULL
					WHERE ref_doc_num = v_prev_doc_num
					AND jur_type = 'EXERW';
				EXCEPTION
					WHEN OTHERS THEN
						v_error_code := -53;
						v_error_msg :=  SUBSTR('UPDATE T_STK_MOVEMENT '||SQLERRM,1,200);
						RAISE v_err;
				END;
				
			ELSE
				BEGIN
					SELECT field_value INTO v_doc_num
					FROM T_MANY_DETAIL
					WHERE update_date = p_update_date
					AND update_seq = p_update_seq
					AND table_name = v_table_name
					AND record_seq = 3
					AND field_name = 'DOC_NUM';
				EXCEPTION
					WHEN OTHERS THEN
						v_error_code := -54;
						v_error_msg :=  SUBSTR('SELECT T_MANY_DETAIL '||SQLERRM,1,200);
						RAISE v_err;
				END;
				
				BEGIN
					UPDATE T_STK_MOVEMENT
					SET ref_doc_num = v_doc_num
					WHERE ref_doc_num = v_prev_doc_num
					AND jur_type = 'EXERW';
				EXCEPTION
					WHEN OTHERS THEN
						v_error_code := -55;
						v_error_msg :=  SUBSTR('UPDATE T_STK_MOVEMENT '||SQLERRM,1,200);
						RAISE v_err;
				END;
			END IF;
			
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
END SP_T_STK_MOVEMENT_APPROVE;