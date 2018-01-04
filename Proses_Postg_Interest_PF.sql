create or replace 
PROCEDURE Proses_Postg_Interest_PF(p_date IN DATE,
                                                    p_bgn_client IN T_INTEREST.client_cd%TYPE,
                                                    p_end_client IN T_INTEREST.client_cd%TYPE,
													p_bgn_date   IN T_INTEREST.int_dt%TYPE,
													p_end_date   IN T_INTEREST.int_dt%TYPE,
													p_brch_cd    IN T_INTEREST.brch_cd%TYPE,
                                                    p_user_id   IN  T_INTEREST.user_id%TYPE,
													p_jv_cnt     OUT NUMBER)
IS

  -- Ambil interest yang belum diposting
  --------------------------------------
  CURSOR l_csr
  IS SELECT t.client_cd, m.old_ic_num, m.branch_code,  m.client_type_1, SUM(  t.int_amt) sum_int,
     SUM(DECODE(t.int_flg,'D',t.int_amt,0)) sum_deb, SUM(DECODE(t.int_flg,'D',0,t.int_amt)) sum_cre
     FROM T_INTEREST t, MST_CLIENT m
     WHERE t.client_cd BETWEEN p_bgn_client AND p_end_client
	   AND t.int_dt BETWEEN p_bgn_date AND p_end_date
	   AND t.brch_cd LIKE p_brch_cd
	   AND ((t.POST_FLG  = 'A') OR (t.post_flg = 'N' AND p_bgn_client <> '%'))
	   AND t.client_cd = m.client_cd
	 GROUP BY t.client_cd, m.client_type_1, m.old_ic_num, m.branch_code;

  v_rec											l_csr%ROWTYPE;

  v_dbcr_flg								T_ACCOUNT_LEDGER.db_cr_flg%TYPE;
  v_gl_acct_cd								T_ACCOUNT_LEDGER.gl_acct_cd%TYPE;
  v_sl_acct_cd								T_ACCOUNT_LEDGER.sl_acct_cd%TYPE;
  v_client_cd								T_PAYRECD.client_cd%TYPE;
  v_doc_ref_num								T_PAYRECD.doc_ref_num%TYPE;
  v_tal_id									T_ACCOUNT_LEDGER.tal_id%TYPE;
  v_sum_int									T_ACCOUNT_LEDGER.curr_val%TYPE;
  v_payrec_num 								T_ACCOUNT_LEDGER.xn_doc_num%TYPE;
  v_payrec_date									DATE;
  v_payrec_type								T_PAYRECH.payrec_type%TYPE;
  v_last_principal							T_INTEREST.int_value%TYPE;
  v_principal								T_INTEREST.int_value%TYPE;
  v_folder_cd                               T_ACCOUNT_LEDGER.FOLDER_CD%TYPE;
  v_ledger_nar                              T_ACCOUNT_LEDGER.ledger_nar%TYPE;
  v_brch_cd									T_ACCOUNT_LEDGER.brch_cd%TYPE;
  v_new     								BOOLEAN;
  v_nl										CHAR(2);
  v_cnt                                     NUMBER;


BEGIN
	v_nl := CHR(10)||CHR(13);
	v_cnt := 0;
    v_doc_ref_num := TO_CHAR(p_date,'mmyy')||'ZZ1234567';

		OPEN l_csr;
		LOOP
			FETCH l_csr INTO v_rec;
			EXIT WHEN l_csr%NOTFOUND;


			v_brch_cd := trim(v_rec.branch_code);

			IF v_rec.sum_int <> 0   THEN



			--  generate journal

			   v_tal_id 		:= 0;
			   v_ledger_nar := 'Interest '||trim(v_rec.old_ic_num)||
			   ' '||TO_CHAR(p_bgn_date,'dd')||'-'||TO_CHAR(p_end_date,'dd/mm/yy');
			   v_gl_acct_cd := '1060';

			   IF v_rec.sum_deb > 0 AND  v_rec.sum_cre = 0 THEN

	                v_dbcr_flg := 'D';
				    v_sum_int        := v_rec.sum_int;
                END IF;


			   IF v_rec.sum_deb = 0 AND  v_rec.sum_cre <> 0 THEN
				    v_dbcr_flg := 'C';
        			v_sum_int        := v_rec.sum_int * -1;

				END IF;

			   IF v_rec.sum_deb <> 0 AND  v_rec.sum_cre <> 0 THEN

				   IF v_rec.sum_int > 0 THEN

		                v_dbcr_flg := 'D';
					    v_sum_int        := v_rec.sum_int;

					ELSE
					    v_dbcr_flg := 'C';
	        			v_sum_int        := v_rec.sum_int * -1;

					END IF;


				END IF;


				v_sl_acct_cd := trim(v_rec.client_cd);
				v_client_cd	 := trim(v_rec.client_cd);

				IF v_dbcr_flg = 'D' THEN
				   v_payrec_type    := 'PD';
				   v_payrec_num		:= Get_Docnum_Rvpv(TRUNC(p_date),'PD');
				ELSE
				   v_payrec_type    := 'RD';
				   v_payrec_num		:= Get_Docnum_Rvpv(TRUNC(p_date),'RD');
				END IF;
				v_payrec_num := SUBSTR(v_payrec_num,1,6)||'A'||SUBSTR(v_payrec_num,8,7);



				 v_payrec_date := TRUNC(p_date);

				 v_folder_cd := Get_Folder_Num(TRUNC(p_date),'IJ-',v_payrec_num,p_user_id);




				 BEGIN
				 INSERT INTO INSISTPRO.T_PAYRECH (
				   PAYREC_NUM, PAYREC_TYPE, PAYREC_DATE,
				   ACCT_TYPE, SL_ACCT_CD, CURR_CD,
				   CURR_AMT, PAYREC_FRTO, REMARKS,
				   USER_ID, CRE_DT, UPD_DT,
				   APPROVED_STS, APPROVED_BY, APPROVED_DT,
				   GL_ACCT_CD, CLIENT_CD, CHECK_NUM,
				   FOLDER_CD, NUM_CHEQ)
				VALUES ( v_payrec_num, v_payrec_type, v_payrec_date,
				    NULL, trim(v_rec.client_cd), NULL,
				    v_sum_int, NULL, v_ledger_nar,
					 p_user_id, SYSDATE, NULL,
					  'A', NULL, NULL,
					   '1060', trim(v_rec.client_cd), NULL,
					   v_folder_Cd, 0);
				  EXCEPTION
				       WHEN OTHERS THEN
				       RAISE_APPLICATION_ERROR(-20100,'insert T_PAYRECH : '||v_payrec_num||v_nl||SQLERRM);
				    END;

	-- insert T_ACCOUNT_LEDGER
					v_tal_id := v_tal_id + 1;


				 BEGIN
					INSERT INTO INSISTPRO.T_ACCOUNT_LEDGER (
					   XN_DOC_NUM, TAL_ID, DOC_REF_NUM,
					   ACCT_TYPE, SL_ACCT_CD, GL_ACCT_CD,
					   CHRG_CD, CHQ_SNO, CURR_CD,
					   BRCH_CD, CURR_VAL, XN_VAL,
					   BUDGET_CD, DB_CR_FLG, LEDGER_NAR,
					   CASHIER_ID, USER_ID, CRE_DT,
					   UPD_DT, DOC_DATE, DUE_DATE,
					   NETTING_DATE, NETTING_FLG, RECORD_SOURCE,
					   SETT_FOR_CURR, SETT_STATUS, RVPV_NUMBER,
					   APPROVED_STS, APPROVED_BY, APPROVED_DT,
					   FOLDER_CD, SETT_VAL, ARAP_DUE_DATE)
					VALUES (v_payrec_num, v_tal_id, v_payrec_num,
					    'ARAP', v_sl_acct_cd, v_gl_acct_cd,
					    NULL, NULL, NULL,
					    v_brch_cd, v_sum_int, v_sum_int,
					    'INT', v_dbcr_flg, v_ledger_nar,
					    NULL, p_user_id, SYSDATE,
					    NULL, v_payrec_date, v_payrec_date,
					    v_payrec_date, v_tal_id, v_payrec_type,
					    0, NULL, NULL,
					    'A', NULL, NULL,
					    v_folder_cd, 0, v_payrec_date);
			       EXCEPTION
				       WHEN OTHERS THEN
				       RAISE_APPLICATION_ERROR(-20100,'insert to T_ACCOUNT_LEDGER : '||v_payrec_num||'-'||
					   v_gl_acct_cd||v_nl||SQLERRM);
				    END;

				 BEGIN
					INSERT INTO INSISTPRO.T_PAYRECD (
					   PAYREC_NUM, PAYREC_TYPE, PAYREC_DATE,
					   CLIENT_CD, GL_ACCT_CD, SL_ACCT_CD,
					   DB_CR_FLG, CRE_DT, UPD_DT,
					   APPROVED_STS, APPROVED_BY, APPROVED_DT,
					   PAYREC_AMT, USER_ID, DOC_REF_NUM,
					   TAL_ID, REMARKS, RECORD_SOURCE,
					   DOC_DATE, REF_FOLDER_CD, GL_REF_NUM,
					   DUE_DATE)
					VALUES ( v_payrec_num, v_payrec_type, v_payrec_date,
					    v_sl_acct_cd, v_gl_acct_cd, v_sl_acct_cd,
					    v_dbcr_flg, SYSDATE, NULL,
					    'A', NULL, NULL,
						v_sum_int, p_user_id, v_payrec_num,
						v_tal_id,v_ledger_nar,'ARAP',
						v_payrec_date,v_folder_cd,NULL,
						v_payrec_date);
			       EXCEPTION
				       WHEN OTHERS THEN
				       RAISE_APPLICATION_ERROR(-20100,'insert to T_PAYRECD : '||v_payrec_num||'-'||
					   v_gl_acct_cd||v_nl||SQLERRM);
				    END;

					v_tal_id := v_tal_id + 1;

					IF v_dbcr_flg = 'D' THEN
					   v_dbcr_flg := 'C';

					   IF trim(v_rec.branch_code) = 'JK' THEN
					   	  v_gl_acct_cd := Get_Gl_Acc_Code('JKIC');
					   ELSE
					   	  v_gl_acct_cd := Get_Gl_Acc_Code('SLIC');
					   END IF;

					ELSE
					   v_dbcr_flg := 'D';

					   IF trim(v_rec.branch_code) = 'JK' THEN
					   	  v_gl_acct_cd := Get_Gl_Acc_Code('JKID');
					   ELSE
					   	  v_gl_acct_cd := Get_Gl_Acc_Code('SLID');
					   END IF;

					END IF;


	          		v_sl_acct_cd := SUBSTR(v_gl_acct_cd,5,6);
		      		v_gl_acct_cd := SUBSTR(v_gl_acct_cd,1,4);

				 BEGIN
					INSERT INTO INSISTPRO.T_ACCOUNT_LEDGER (
					   XN_DOC_NUM, TAL_ID, DOC_REF_NUM,
					   ACCT_TYPE, SL_ACCT_CD, GL_ACCT_CD,
					   CHRG_CD, CHQ_SNO, CURR_CD,
					   BRCH_CD, CURR_VAL, XN_VAL,
					   BUDGET_CD, DB_CR_FLG, LEDGER_NAR,
					   CASHIER_ID, USER_ID, CRE_DT,
					   UPD_DT, DOC_DATE, DUE_DATE,
					   NETTING_DATE, NETTING_FLG, RECORD_SOURCE,
					   SETT_FOR_CURR, SETT_STATUS, RVPV_NUMBER,
					   APPROVED_STS, APPROVED_BY, APPROVED_DT,
					   FOLDER_CD, SETT_VAL)
					VALUES (v_payrec_num, v_tal_id, v_payrec_num,
					    NULL, v_sl_acct_cd, v_gl_acct_cd,
					    NULL, NULL, NULL,
					    v_brch_cd, v_sum_int, v_sum_int,
					    'INT', v_dbcr_flg, v_ledger_nar,
					    NULL, p_user_id, SYSDATE,
					    NULL, v_payrec_date, v_payrec_date,
					    v_payrec_date, NULL, v_payrec_type,
					    0, NULL, NULL,
					    'A', NULL, NULL,
					    v_folder_cd, 0);
   			       EXCEPTION
				       WHEN OTHERS THEN
				       RAISE_APPLICATION_ERROR(-20100,'jurnal interest to T_ACCOUNT_LEDGER : '||v_payrec_num||'-'||
					   v_gl_acct_cd||v_nl||SQLERRM);
				    END;

				 BEGIN
					INSERT INTO INSISTPRO.T_PAYRECD (
					   PAYREC_NUM, PAYREC_TYPE, PAYREC_DATE,
					   CLIENT_CD, GL_ACCT_CD, SL_ACCT_CD,
					   DB_CR_FLG, CRE_DT, UPD_DT,
					   APPROVED_STS, APPROVED_BY, APPROVED_DT,
					   PAYREC_AMT, USER_ID, DOC_REF_NUM,
					   TAL_ID, REMARKS, RECORD_SOURCE,
					   DOC_DATE, REF_FOLDER_CD, GL_REF_NUM)
					VALUES ( v_payrec_num, v_payrec_type, v_payrec_date,
					    v_client_cd, v_gl_acct_cd, v_sl_acct_cd,
					    v_dbcr_flg, SYSDATE, NULL,
					    'A', NULL, NULL,
						v_sum_int, p_user_id, v_payrec_num,
						v_tal_id, v_ledger_nar,'VCH',
					    v_payrec_date, NULL, NULL);
   			       EXCEPTION
				       WHEN OTHERS THEN
				       RAISE_APPLICATION_ERROR(-20100,'insert T_PAYRECD : '||v_payrec_num||'-'||
					   v_gl_acct_cd||v_nl||SQLERRM);
				    END;





					v_cnt := v_cnt + 1;




			END IF;
			--2.update t_interest.post_flg='Y'
			    BEGIN
				UPDATE T_INTEREST
				SET 	post_flg = 'Y',
				    xn_doc_num = v_payrec_num
				WHERE client_cd  = trim(v_rec.client_cd)
				AND int_dt BETWEEN p_bgn_date AND p_end_date
				AND post_flg <> 'Y';
		       EXCEPTION
			       WHEN OTHERS THEN
			       RAISE_APPLICATION_ERROR(-20100,'update post_flg T_INTEREST : '||v_rec.client_cd||v_nl||SQLERRM);
			    END;

	END LOOP;
	CLOSE l_csr;
	--commit;

    p_jv_cnt := v_cnt;

	EXCEPTION
     WHEN NO_DATA_FOUND THEN
       NULL;
     WHEN OTHERS THEN
       -- Consider logging the error and then re-raise
       RAISE;

END Proses_Postg_Interest_PF;
