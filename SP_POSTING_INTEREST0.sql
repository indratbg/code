create or replace 
PROCEDURE SP_POSTING_INTEREST(p_date IN DATE,
                              p_bgn_client IN T_INTEREST.client_cd%TYPE,
                              p_end_client IN T_INTEREST.client_cd%TYPE,
                              p_bgn_date   IN T_INTEREST.int_dt%TYPE,
                              p_end_date   IN T_INTEREST.int_dt%TYPE,
                              p_user_id   IN  T_INTEREST.user_id%TYPE,
                              P_IP_ADDRESS T_MANY_HEADER.IP_ADDRESS%TYPE,
                              P_ERROR_CD OUT NUMBER,
                              P_ERROR_MSG OUT VARCHAR2)
IS

-- 17mar11 acct 6504 diganti 6509 per cabang

  -- Ambil interest yang belum diposting
  --------------------------------------
  CURSOR l_csr(a_bgn_client T_INTEREST.client_cd%TYPE,
               a_end_client T_INTEREST.client_cd%TYPE)
  IS SELECT t.client_cd, NVL(m.amt_int_flg,'Y') amt_int_flg, m.client_type_1, m.client_type_2,
     m.client_type_3, m.branch_code,
     NVL(m.RECOV_CHARGE_FLG,'N') RECOV_CHARGE_FLG, 
     NVL(m.tax_on_interest,'N') tax_on_interest, t.sum_int
     FROM( SELECT client_cd, SUM( int_amt) sum_int
	       FROM T_INTEREST
		   WHERE POST_FLG  = 'N'
		   AND client_cd BETWEEN a_bgn_client AND a_end_client
		   AND int_dt BETWEEN p_bgn_date AND p_end_date
		   GROUP BY client_cd) t,
		 ( SELECT client_cd, amt_int_flg, client_type_1, client_type_2, 
		          client_type_3, branch_code,
                  tax_on_interest, NVL(RECOV_CHARGE_FLG,'N') RECOV_CHARGE_FLG 
		   FROM MST_CLIENT
		   WHERE ((client_type_3 = 'D'  AND p_bgn_client = 'D') OR
           		  (client_type_3 <> 'D' AND p_bgn_client = '%' ) OR
         		  (p_bgn_client <> 'D' AND p_bgn_client <> '%' )) ) m
--			and	  branch_code = 'MD') m
     WHERE  t.client_cd = m.client_cd;

  v_rec											l_csr%ROWTYPE;

  v_dbcr_flg								T_ACCOUNT_LEDGER.db_cr_flg%TYPE;
  v_gl_acct_cd							T_ACCOUNT_LEDGER.gl_acct_cd%TYPE;
  v_acct_6509							MST_GL_ACCOUNT.gl_a%TYPE;
  v_sl_acct_cd							T_ACCOUNT_LEDGER.sl_acct_cd%TYPE;
  v_tal_id									T_ACCOUNT_LEDGER.tal_id%TYPE;
  v_sum_int									T_ACCOUNT_LEDGER.curr_val%TYPE;
  v_pph23									T_ACCOUNT_LEDGER.curr_val%TYPE;
  v_bunga_pinjaman							T_ACCOUNT_LEDGER.curr_val%TYPE;
  --v_dncn_num 								T_ACCOUNT_LEDGER.xn_doc_num%TYPE;
  --v_dncn_dt									DATE;
  v_last_principal							T_INTEREST.int_value%TYPE;
  v_principal								T_INTEREST.int_value%TYPE;
  v_folder_cd                               T_ACCOUNT_LEDGER.FOLDER_CD%TYPE;
  v_ledger_nar                              T_ACCOUNT_LEDGER.ledger_nar%TYPE;
  v_client_cd								T_INTEREST.client_cd%TYPE;
  v_bgn_client								T_INTEREST.client_cd%TYPE;
  v_end_client								T_INTEREST.client_cd%TYPE;
  v_new     								BOOLEAN;
  v_nl										CHAR(2);
  v_cnt                                     NUMBER;
	
V_ERR EXCEPTION;
V_ERROR_CD NUMBER;
V_ERROR_MSG VARCHAR2(200);
V_MENU_NAME T_MANY_HEADER.MENU_NAME%TYPE :='POSTING INTEREST';
V_UPDATE_DATE T_MANY_HEADER.UPDATE_DATE%TYPE;
V_UPDATE_SEQ T_MANY_HEADER.UPDATE_SEQ%TYPE;
v_flg char(1):='N';

--VOUCHER
V_PAYREC_NUM T_PAYRECH.PAYREC_NUM%TYPE;
V_PAYREC_TYPE T_PAYRECH.PAYREC_TYPE%TYPE;
V_PAYREC_DATE T_PAYRECH.PAYREC_DATE%TYPE;


BEGIN

	v_nl := CHR(10)||CHR(13);
	v_cnt := 0;

	IF p_bgn_client = '%' OR p_bgn_client = 'D' THEN

	   v_bgn_client := '%';
	   v_end_client := '_';
	ELSE
		v_bgn_client := p_bgn_client;
		v_end_client := p_end_client;
	END IF;

	-- 17mar11
	v_acct_6509 := Get_Gl_Acc_Code('INTR','_');
	v_acct_6509 := SUBSTR(v_acct_6509,1,4);
	-- 17mar11
	
		OPEN l_csr(v_bgn_client, v_end_client);
		LOOP
			FETCH l_csr INTO v_rec;
			EXIT WHEN l_csr%NOTFOUND;
			IF v_rec.sum_int <> 0  AND NVL(v_rec.amt_int_flg,'Y') = 'Y' THEN

			--  generate PAYRECH

			   v_tal_id 		:= 0;
			   v_client_cd  := trim(v_rec.client_cd);

				   IF v_rec.sum_int > 0 THEN

		                v_dbcr_flg := 'D';
						
					--	v_gl_acct_cd := '1424'; mulai may 2010
					--    v_gl_acct_cd := '1422'; 
					-- mulai 27feb2013 
					    if v_rec.client_type_3 = 'M' then
						   v_gl_acct_cd := '1422';
						else
						   v_gl_acct_cd := '1424'; 
						end if;   
					-- mulai 27feb2013 end 	
   

					    v_sum_int        := v_rec.sum_int;
					    v_ledger_nar := 'TERLAMBAT BYR DR '||trim(v_rec.client_cd);
          		V_PAYREC_TYPE := 'PD';
					ELSE
					    v_dbcr_flg := 'C';
					
						IF v_rec.RECOV_CHARGE_FLG = 'Y' THEN
						   v_gl_acct_cd := '2490';
						ELSE
						   v_gl_acct_cd := '1422';
						END IF;

	        			v_sum_int        := v_rec.sum_int * -1;
					    v_ledger_nar := 'TERLAMBAT BYR KE '||trim(v_rec.client_cd);
						 --v_dncn_num		:= Get_Docnum_Dcnote(TRUNC(p_date),'CN');
						 V_PAYREC_TYPE := 'RD';
					END IF;



				IF v_rec.client_type_3 = 'D' THEN

					v_ledger_nar := 'BUNGA '||v_client_cd||' '||TO_CHAR(p_end_date,'mm/yyyy');

				END IF;


				v_gl_acct_cd := SUBSTR(v_gl_acct_cd,1,4);

				v_sl_acct_cd := trim(v_rec.client_cd);


    			-- v_dncn_num		:= Get_Docnum_Dcnote(TRUNC(p_date),'DN');

				 --v_dncn_num      := SUBSTR(v_dncn_num, 1,6)||'A'||SUBSTR(v_dncn_num, 8,7);

				 V_PAYREC_DATE := TRUNC(p_date);

				 v_folder_cd := F_GET_FOLDER_NUM(p_date,'IJ-');
        
  
					
						--EXECUTE SP HEADER
						 BEGIN
						Sp_T_Many_Header_Insert(V_MENU_NAME,
												 'I',
												 P_USER_ID,
												 P_IP_ADDRESS,
												 NULL,
												 V_UPDATE_DATE,
												 V_UPDATE_SEQ,
												 V_ERROR_CD,
												 V_ERROR_MSG);
						EXCEPTION
							  WHEN OTHERS THEN
								 V_ERROR_CD := -11;
								 V_ERROR_MSG := SUBSTR('SP_T_MANY_HEADER_INSERT '|| SQLERRM(SQLCODE),1,200);
								RAISE V_ERR;
							END;
				BEGIN	
				 SP_T_PAYRECH_UPD (	V_PAYREC_NUM,--P_SEARCH_PAYREC_NUM,
									V_PAYREC_NUM,--P_PAYREC_NUM,
									V_PAYREC_TYPE,--P_PAYREC_TYPE,
									V_PAYREC_DATE,--P_PAYREC_DATE,
									NULL,--P_ACCT_TYPE,
									trim(v_rec.client_cd),--P_SL_ACCT_CD,
									'IDR',--P_CURR_CD,
									v_sum_int,--P_CURR_AMT,
									NULL,--P_PAYREC_FRTO,
									v_ledger_nar,--P_REMARKS,
									V_GL_ACCT_CD,--P_GL_ACCT_CD,
									v_rec.client_cd,--P_CLIENT_CD,
									NULL,--P_CHECK_NUM,
									v_folder_cd,--P_FOLDER_CD,
									0,--P_NUM_CHEQ,
									NULL,--P_CLIENT_BANK_ACCT,
									NULL,--P_CLIENT_BANK_NAME,
									'N',--P_REVERSAL_JUR,
									P_USER_ID,
									SYSDATE,--P_CRE_DT,
									NULL,--P_UPD_BY,
									NULL,--P_UPD_DT,
									'I',--P_UPD_STATUS,
									p_ip_address,
									NULL,--p_cancel_reason,
									V_UPDATE_DATE,--p_update_date,
									V_UPDATE_SEQ,--p_update_seq,
									1,--p_record_seq,
									V_ERROR_CD,--p_error_code,
									V_ERROR_MSG--p_error_msg
									);
			EXCEPTION
		  WHEN OTHERS THEN
			 V_ERROR_CD := -20;
			 V_ERROR_MSG := SUBSTR('SP_T_MANY_HEADER_INSERT '|| SQLERRM(SQLCODE),1,200);
			RAISE V_ERR;
			END;					
								
			IF v_error_cd<0 then
				v_error_cd := -30;
				v_error_msg :=substr('CALL SP_T_PAYRECH_UPD : '||v_error_msg,1,200);
				raise v_err;
			end if;	


			BEGIN
			Sp_T_Many_Approve(V_MENU_NAME,--p_menu_name,
                         V_UPDATE_DATE,--p_update_date,
                         V_UPDATE_SEQ,--p_update_seq,
                         P_USER_ID,--p_approved_user_id,
                         P_IP_ADDRESS,--p_approved_ip_address,
                         v_error_cd,
                         v_error_msg);
			EXCEPTION
			  WHEN OTHERS THEN
				v_error_cd := -40;
				v_error_msg :=substr('Sp_T_Many_Approve : '||v_nl||SQLERRM(SQLCODE),1,200);
				raise v_err;
			END;
			IF v_error_cd<0 then
				v_error_cd := -50;
				v_error_msg :=substr('Sp_T_Many_Approve : '||v_error_msg,1,200);
				raise v_err;
			end if;
		
			--INSERT INTO T FOLDER
	     BEGIN
         INSERT INTO T_FOLDER (
         FLD_MON, FOLDER_CD, DOC_DATE,
         DOC_NUM, USER_ID, CRE_DT,
         UPD_DT,
         APPROVED_DT,
         APPROVED_BY,
         APPROVED_STAT)
         VALUES(TO_CHAR(v_payrec_date,'mmyy'),
                 v_folder_cd,
                 v_payrec_date,
             V_PAYREC_NUM,
             p_user_id,
             SYSDATE, NULL,
             SYSDATE,
             P_USER_ID,
             'A');
        EXCEPTION
        WHEN OTHERS THEN
            V_ERROR_CD := -60;
             V_ERROR_MSG := SUBSTR('Error insert T_FOLDER : '||v_folder_cd||' '||SQLERRM,1,200);
            RAISE V_ERR;
        END;
				

			-- insert T_ACCOUNT_LEDGER
					v_tal_id := v_tal_id + 1;
					
				 BEGIN
			     INSERT INTO T_ACCOUNT_LEDGER (
			         XN_DOC_NUM, TAL_ID, ACCT_TYPE, SL_ACCT_CD,
			         GL_ACCT_CD, CHRG_CD, CHQ_SNO,
			         CURR_CD, CURR_VAL, XN_VAL,
			         DB_CR_FLG, LEDGER_NAR, CASHIER_ID,
			         USER_ID, CRE_DT, UPD_DT,
			         DOC_DATE, DUE_DATE, NETTING_DATE,
					 NETTING_FLG,RECORD_SOURCE,DOC_REF_NUM,
					 APPROVED_STS,  APPROVED_BY, APPROVED_DT,
					 SETT_FOR_CURR, RVPV_NUMBER, FOLDER_CD,MANUAL)
			      VALUES (
			         V_PAYREC_NUM, v_tal_id, NULL,v_sl_acct_cd,
			         v_gl_acct_cd,NULL,NULL,
			         'IDR',v_sum_int, v_sum_int,
			         v_dbcr_flg,v_ledger_nar,NULL,
			         p_user_id,SYSDATE,NULL,
			         v_payrec_date, v_payrec_date,  NULL,
					 '0', 'INT',NULL,
					 'A',p_user_id,SYSDATE,
					 NULL,NULL, v_folder_cd,'N');
			       EXCEPTION
				       WHEN OTHERS THEN
					    V_ERROR_CD := -70;
						V_ERROR_MSG :=SUBSTR('insert to T_ACCOUNT_LEDGER : '||V_PAYREC_NUM||'-'|| v_gl_acct_cd||v_nl||SQLERRM,1,200);
						RAISE V_ERR;
				    END;
		--INSERT T_PAYRECD			
				 BEGIN
					INSERT INTO T_PAYRECD (
					   PAYREC_NUM, PAYREC_TYPE, PAYREC_DATE,
					   CLIENT_CD, GL_ACCT_CD, SL_ACCT_CD,
					   DB_CR_FLG, CRE_DT, UPD_DT,
					   APPROVED_STS, APPROVED_BY, APPROVED_DT,
					   PAYREC_AMT, USER_ID, DOC_REF_NUM,
					   TAL_ID, REMARKS, RECORD_SOURCE,
					   DOC_DATE, REF_FOLDER_CD, GL_REF_NUM,
					   DUE_DATE)
					VALUES ( v_payrec_num, v_payrec_type, V_PAYREC_DATE,
					    v_sl_acct_cd, v_gl_acct_cd, v_sl_acct_cd,
					    v_dbcr_flg, SYSDATE, NULL,
					    'A', p_user_id, SYSDATE,
						v_sum_int, p_user_id, v_payrec_num,
						v_tal_id,v_ledger_nar,'ARAP',
						v_payrec_date,v_folder_cd,NULL,
						v_payrec_date);
			       EXCEPTION
				       WHEN OTHERS THEN
                V_ERROR_CD := -80;
                V_ERROR_MSG :=SUBSTR('insert to T_PAYRECD : '||v_payrec_num||'-'|| v_gl_acct_cd||v_nl||SQLERRM,1,200);
                RAISE V_ERR;
				    END;		
					

					IF v_Rec.tax_on_interest = 'N' OR ( v_rec.sum_int > 0 AND v_rec.client_type_2 = 'F') THEN

						v_tal_id := v_tal_id + 1;

						IF v_dbcr_flg = 'D' THEN
						   v_dbcr_flg := 'C';
						ELSE
						   v_dbcr_flg := 'D';
						END IF;
-- 		17mar11				v_gl_acct_cd := Get_Gl_Acc_Code('OTHI','_');
-- 		          		v_sl_acct_cd := SUBSTR(v_gl_acct_cd,5,6);
--		      		v_gl_acct_cd := SUBSTR(v_gl_acct_cd,1,4);

-- 17mar11 account by branch
                        v_gl_acct_cd := v_acct_6509;						
                        v_sl_acct_cd := Get_Gl_Acct_Branch(v_gl_acct_cd, v_rec.branch_code);
                        
					 BEGIN
				     INSERT INTO T_ACCOUNT_LEDGER (
				         XN_DOC_NUM, TAL_ID, ACCT_TYPE, SL_ACCT_CD,
				         GL_ACCT_CD, CHRG_CD, CHQ_SNO,
				         CURR_CD, CURR_VAL, XN_VAL,
				         DB_CR_FLG, LEDGER_NAR, CASHIER_ID,
				         USER_ID, CRE_DT, UPD_DT,
				         DOC_DATE, DUE_DATE, NETTING_DATE,
						 NETTING_FLG,RECORD_SOURCE,DOC_REF_NUM,
	 					 APPROVED_STS,  APPROVED_BY, APPROVED_DT,
						 SETT_FOR_CURR, RVPV_NUMBER, FOLDER_CD,MANUAL)
				      VALUES (
				         V_PAYREC_NUM, v_tal_id, NULL,v_sl_acct_cd,
				         v_gl_acct_cd,NULL,NULL,
				         'IDR',v_sum_int, v_sum_int,
				         v_dbcr_flg,v_ledger_nar,NULL,
				         p_user_id,SYSDATE,NULL,
				         V_PAYREC_DATE, V_PAYREC_DATE,  NULL,
						 '0', 'INT',NULL,
						 'A',p_user_id,SYSDATE,
						 NULL,NULL, v_folder_cd,'N');
	   			       EXCEPTION
					       WHEN OTHERS THEN
							V_ERROR_CD := -90;
							V_ERROR_MSG :=SUBSTR('insert PAYRECH to T_ACCOUNT_LEDGER : '||V_PAYREC_NUM||'-'|| v_gl_acct_cd||v_nl||SQLERRM,1,200);
							RAISE V_ERR;
					    END;

							
					ELSE

						v_tal_id := v_tal_id + 1;


						-- 2526 - local - 15%
						--2529 - asing - 20%
						v_ledger_nar := 'PPH 23 BUNGA '||v_client_cd||' '||TO_CHAR(p_end_date,'mm/yy');

						IF v_rec.client_type_2 = 'L' THEN
						   v_pph23  := ROUND(v_sum_int  / 85 * 15, 0);

	   					   IF v_dbcr_flg = 'C' THEN
						   	  v_gl_acct_cd := Get_Gl_Acc_Code('P23L','_');
						   ELSE
						   	  v_gl_acct_cd := Get_Gl_Acc_Code('UP23','_');
							  v_ledger_nar := 'UM '||v_ledger_nar;
						   END IF;
						ELSE
						   v_pph23 := ROUND(v_sum_int  / 80 * 20, 0);
						   v_gl_acct_cd := Get_Gl_Acc_Code('P23F','_');

						END IF;

						v_bunga_pinjaman :=  v_sum_int + v_pph23;
		          		v_sl_acct_cd := SUBSTR(v_gl_acct_cd,5,6);
			      		v_gl_acct_cd := SUBSTR(v_gl_acct_cd,1,4);

						 BEGIN
					     INSERT INTO T_ACCOUNT_LEDGER (
					         XN_DOC_NUM, TAL_ID, ACCT_TYPE, SL_ACCT_CD,
					         GL_ACCT_CD, CHRG_CD, CHQ_SNO,
					         CURR_CD, CURR_VAL, XN_VAL,
					         DB_CR_FLG, LEDGER_NAR, CASHIER_ID,
					         USER_ID, CRE_DT, UPD_DT,
					         DOC_DATE, DUE_DATE, NETTING_DATE,
							 NETTING_FLG,RECORD_SOURCE,DOC_REF_NUM,
		 					 APPROVED_STS,  APPROVED_BY, APPROVED_DT,
							 SETT_FOR_CURR, RVPV_NUMBER, FOLDER_CD,MANUAL)
					      VALUES (
					         V_PAYREC_NUM, v_tal_id, NULL,v_sl_acct_cd,
					         v_gl_acct_cd,NULL,NULL,
					         'IDR',v_pph23, v_pph23,
					         v_dbcr_flg,v_ledger_nar,NULL,
					         p_user_id,SYSDATE,NULL,
					         V_PAYREC_DATE, V_PAYREC_DATE,  NULL,
							 '0', 'INT',NULL,
							 'A',p_user_id,SYSDATE,
							 NULL,NULL, v_folder_cd,'N');
		   			       EXCEPTION
						       WHEN OTHERS THEN
								V_ERROR_CD := -100;
								V_ERROR_MSG :=SUBSTR('insert PAYRECH to T_ACCOUNT_LEDGER : '||V_PAYREC_NUM||'-'||v_gl_acct_cd||v_nl||SQLERRM,1,200);
								RAISE V_ERR;
						    END;

			

						v_tal_id := v_tal_id + 1;


						IF v_dbcr_flg = 'D' THEN
						   v_dbcr_flg := 'C';
						ELSE
						   v_dbcr_flg := 'D';
						END IF;

						v_gl_acct_cd := Get_Gl_Acc_Code('BPIN','_');


		          		v_sl_acct_cd := SUBSTR(v_gl_acct_cd,5,6);
			      		v_gl_acct_cd := SUBSTR(v_gl_acct_cd,1,4);
						v_ledger_nar := 'BUNGA '||v_client_cd||' '||TO_CHAR(p_end_date,'mm/yy');

						 BEGIN
					     INSERT INTO T_ACCOUNT_LEDGER (
					         XN_DOC_NUM, TAL_ID, ACCT_TYPE, SL_ACCT_CD,
					         GL_ACCT_CD, CHRG_CD, CHQ_SNO,
					         CURR_CD, CURR_VAL, XN_VAL,
					         DB_CR_FLG, LEDGER_NAR, CASHIER_ID,
					         USER_ID, CRE_DT, UPD_DT,
					         DOC_DATE, DUE_DATE, NETTING_DATE,
							 NETTING_FLG,RECORD_SOURCE,DOC_REF_NUM,
		 					 APPROVED_STS,  APPROVED_BY, APPROVED_DT,
							 SETT_FOR_CURR, RVPV_NUMBER, FOLDER_CD,MANUAL)
					      VALUES (
					         V_PAYREC_NUM, v_tal_id, NULL,v_sl_acct_cd,
					         v_gl_acct_cd,NULL,NULL,
					         'IDR',v_bunga_pinjaman, v_bunga_pinjaman,
					         v_dbcr_flg,v_ledger_nar,NULL,
					         p_user_id,SYSDATE,NULL,
					         V_PAYREC_DATE, V_PAYREC_DATE,  NULL,
							 '0', 'INT',NULL,
							 'A',p_user_id,SYSDATE,
							 NULL,NULL, v_folder_cd,'N');
		   			       EXCEPTION
						       WHEN OTHERS THEN
							   	V_ERROR_CD := -110;
								V_ERROR_MSG :=SUBSTR('insert dncn to T_ACCOUNT_LEDGER : '||V_PAYREC_NUM||'-'|| v_gl_acct_cd||v_nl||SQLERRM,1,200);
								RAISE V_ERR;
						    END;
					END IF;

					v_cnt := v_cnt + 1;




			END IF;
			--2.update t_interest.post_flg='Y'
			    BEGIN
				UPDATE T_INTEREST
				SET 	post_flg = 'Y',
				    xn_doc_num = V_PAYREC_NUM,
            upd_by=p_user_id,
            approved_by =p_user_id,
            approved_dt=sysdate
				WHERE client_cd  = trim(v_rec.client_cd)
				AND int_dt BETWEEN p_bgn_date AND p_end_date
				AND post_flg = 'N';
		       EXCEPTION
			       WHEN OTHERS THEN
				   	V_ERROR_CD := -120;
            V_ERROR_MSG :=SUBSTR('update post_flg T_INTEREST : '||v_rec.client_cd||v_nl||SQLERRM,1,200);
            RAISE V_ERR;
			    END;
	V_PAYREC_NUM:=NULL;
  v_flg:='Y';
	END LOOP;
	CLOSE l_csr;
	--commit;
  
  if v_flg ='N' then
            V_ERROR_CD := -130;
            V_ERROR_MSG :='No data found to posting';
            RAISE V_ERR;
  end if;

    --p_jv_cnt := v_cnt;
	P_ERROR_CD := 1;
	p_error_msg := '';

EXCEPTION
    WHEN NO_DATA_FOUND THEN
		NULL;
	WHEN v_err THEN
		P_ERROR_CD := V_ERROR_CD;
		P_ERROR_MSG :=  V_ERROR_MSG;
		ROLLBACK;
    WHEN OTHERS THEN
       -- Consider logging the error and then re-raise
	    ROLLBACK;
		P_ERROR_CD := -1;
		P_ERROR_MSG := SUBSTR(SQLERRM,1,200);
		RAISE;		

END SP_POSTING_INTEREST;