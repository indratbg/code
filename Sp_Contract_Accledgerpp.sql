create or replace 
	PROCEDURE Sp_Contract_Accledgerpp(p_contract_num    T_CONTRACTS.contr_num%TYPE,
									p_trans_type      VARCHAR2,
									p_user_id         VARCHAR2,
									p_error_code							OUT NUMBER,
									p_error_msg							OUT VARCHAR2
									)
IS
--21SEP15 jurnal PAPE
-- MAR 2015 ip next g, utk YJ n MU
-- 12may11 6504 dirubah jd 6509 100000 utk contract average price dan pasar nego

	CURSOR csr IS
    SELECT *
    FROM T_CONTRACTS tc
    WHERE tc.contr_num = p_contract_num;

	vdocnum         T_ACCOUNT_LEDGER.xn_doc_num%TYPE;
	vgl_acct_cd     T_ACCOUNT_LEDGER.gl_acct_cd%TYPE;
	vsl_acct_cd     T_ACCOUNT_LEDGER.sl_acct_cd%TYPE;
	v_tal_id	  T_ACCOUNT_LEDGER.tal_id%TYPE;
	vledger_nar	  T_ACCOUNT_LEDGER.ledger_nar%TYPE;
	vincome_commission T_ACCOUNT_LEDGER.curr_val%TYPE;
	vtrans_levy     T_ACCOUNT_LEDGER.curr_val%TYPE;
	vacct_type  T_ACCOUNT_LEDGER.acct_type%TYPE;
	v_deb_amt     T_ACCOUNT_LEDGER.curr_val%TYPE;
	v_cre_amt     T_ACCOUNT_LEDGER.curr_val%TYPE;
	v_selisih     T_ACCOUNT_LEDGER.curr_val%TYPE;
	v_coy_client_cd    MST_CLIENT.client_cd%TYPE;
	v_kode_ab    T_ACCOUNT_LEDGER.sl_acct_cd%TYPE;
	v_folder_cd			 T_ACCOUNT_LEDGER.folder_cd%TYPE;
	v_record_source T_ACCOUNT_LEDGER.record_source%TYPE := 'CG';
	v_approved_sts T_ACCOUNT_LEDGER.approved_sts%TYPE := 'A';
	v_manual		 		T_ACCOUNT_LEDGER.approved_sts%TYPE := 'Y';
	v_curr_cd		  T_ACCOUNT_LEDGER.CURR_CD%TYPE := 'IDR';
	v_budget_cd T_ACCOUNT_LEDGER.budget_cd%TYPE := 'CG';
	v_utang_dana_jaminan T_ACCOUNT_LEDGER.curr_val%TYPE;  
	v_utang_biaya_lpp         T_ACCOUNT_LEDGER.curr_val%TYPE;
	v_utang_biaya_lkp        T_ACCOUNT_LEDGER.curr_val%TYPE;
	v_utang_biaya_bei 		 T_ACCOUNT_LEDGER.curr_val%TYPE;
				
	vdb_cr_flg     CHAR(1);
	v_rtn			 VARCHAR2(20);
	v_nl			 CHAR(2);
	vapprove       CHAR(1);
	v_nrtn		 INTEGER;
	v_qty      VARCHAR2(30);

	rec     csr%ROWTYPE;

	v_err EXCEPTION;
	v_error_code							NUMBER;
	v_error_msg							VARCHAR2(200);

BEGIN
	 v_nl := CHR(10)||CHR(13);
     v_tal_id	:= 0;
	 vapprove := 'A';

	v_folder_cd := SUBSTR(p_contract_num,5,1)||SUBSTR(p_contract_num,7,7);
	
	BEGIN 
	SELECT trim(NVL(other_1,'X')) INTO v_coy_client_cd
     FROM MST_COMPANY;
	 EXCEPTION
	 WHEN NO_DATA_FOUND THEN 
   					  v_error_code := -3;
					  v_error_msg  := 'MST Company not found';
					  RAISE V_err;
	WHEN OTHERS THEN 
   					  v_error_code := -5;
					  v_error_msg  := SUBSTR('Select MST Company  '||SQLERRM,1,200);
					  RAISE V_err;		
	END;		
   
   BEGIN 
      SELECT SUBSTR(prm_desc,1,2) INTO v_kode_ab
	 FROM MST_PARAMETER
	 WHERE PRM_CD_1 = 'AB'
	 AND prm_cd_2 = '000';
    EXCEPTION
	 WHEN NO_DATA_FOUND THEN 
        v_error_code := -8;
        v_error_msg  := 'kode AB not found in MST PARAMETER';
        RAISE V_err;
	WHEN OTHERS THEN 
        v_error_code := -11;
        v_error_msg  := SUBSTR('Select MST PARAMETER for kode AB  '||SQLERRM,1,200);
        RAISE V_err;		
	END;	

    
    FOR rec IN  CSR LOOP

    
--=================================AR/AP or PORTOFOLIO 1300 ==========================
			  IF SUBSTR(rec.client_cd,1,8) = v_coy_client_cd OR SUBSTR(rec.client_type,1,1) = 'H' THEN
			  --      vgl_acct_cd := '1300';
			       vgl_acct_cd := Get_Gl_Acc_Code('PORT','_');
		     	   vgl_acct_cd := SUBSTR(vgl_acct_cd,1,4);
		
		--dikomen 13aug15 tdk dipakai lg 	       IF SUBSTR(rec.client_cd,1,8) <> v_coy_client_cd THEN -- QQ
		-- 			   vgl_acct_cd := Get_Gl_Acc_Qq(rec.client_cd,'13QQ');
		-- 		   END IF;
		
					vsl_acct_cd := rec.stk_cd;
					v_rtn := Check_Gl_Acct(trim(vgl_acct_cd)||trim(vsl_acct_cd));
					IF trim(v_rtn) = 'notfound' THEN
					   	v_nrtn := Gen_Gl_Account(trim(vgl_acct_cd),trim(vsl_acct_cd),p_user_id);
						IF v_nrtn = -1 THEN
                   v_error_code := -2;
                   v_error_msg :=  SUBSTR('insert to MST_GL_ACCOUNT : '||trim(vgl_acct_cd)||trim(vsl_acct_cd)||'  '||SQLERRM,1,200);
                   RAISE v_err;
						   --RAISE_APPLICATION_ERROR(-20100,'insert to MST_GL_ACCOUNT : '||trim(vgl_acct_cd)||trim(vsl_acct_cd)||'  '||SQLERRM);
						END IF;
					END IF;
		
			  ELSE
		
		--   dikomen 13aug15 tdk dipakai lg         IF SUBSTR(rec.client_type,1,1) <> 'K' THEN
					    vgl_acct_cd := Get_Gl_Acc_Code('CLIE',p_trans_type);
		-- 			END IF;
		-- 		dikomen 13aug15 tdk dipakai lg	IF SUBSTR(rec.client_type,1,1) = 'K' THEN -- KELEMBAGAAN
		-- 			    vgl_acct_cd := Get_Gl_Acc_Code('LEMB',p_trans_type);
		-- 			END IF;
		
					vgl_acct_cd := SUBSTR(vgl_acct_cd,1,4);
					vsl_acct_cd := rec.client_cd;
					v_rtn := Check_Gl_Acct(trim(vgl_acct_cd)||trim(vsl_acct_cd));
					IF trim(v_rtn) = 'notfound' THEN
				          v_error_code := -3;
				           v_error_msg :=  SUBSTR('Cannot find GL ACCOUNT CODE : '||trim(vgl_acct_cd)||trim(vsl_acct_cd)||SQLERRM,1,200);
				           RAISE v_err;
					 	 --RAISE_APPLICATION_ERROR(-20100,' Cannot find GL ACCOUNT CODE : '||trim(vgl_acct_cd)||trim(vsl_acct_cd));
					END IF;
			  END IF;
		
			  IF rec.contra_num IS NOT NULL OR SUBSTR(rec.contr_num,6,1) = 'I'  THEN
				 				   v_manual := 'Y';
				ELSE
								   v_manual := 'N';
				END IF;
		
		
		    	v_tal_id	:= 1;
		
				v_deb_amt := 0;
				v_cre_amt := 0;
		
			  IF p_trans_type = 'D' THEN
		
					    	 vledger_nar := 'Buy *';
					
							 IF SUBSTR(rec.client_cd,1,8) = v_coy_client_cd THEN
							     vacct_type := '';
							 ELSE
							     vacct_type := 'AR';
							 END IF;
							 v_deb_amt :=rec.amt_for_Curr;
		
			  ELSE
						     vledger_nar := 'Sell *';
					
							 IF SUBSTR(rec.client_cd,1,8) = v_coy_client_cd THEN
							     vacct_type := '';
							 ELSE
							     vacct_type := 'AP';
							 END IF;
							 v_cre_amt :=rec.amt_for_Curr;
					
			  END IF;
			  
			    
			  
			  vledger_nar := vledger_nar|| rec.stk_cd||' '||TO_CHAR(rec.qty,'fm999,999,999')||' @'||TO_CHAR(rec.price)||
			  ' '||TO_CHAR(rec.brok_perc / 100,'0.000');
		/*
			  BEGIN
				      INSERT INTO T_ACCOUNT_LEDGER (
				         XN_DOC_NUM, DOC_REF_NUM, TAL_ID, ACCT_TYPE, SL_ACCT_CD,
				         GL_ACCT_CD, CHRG_CD, CHQ_SNO,
				         CURR_CD, BRCH_CD, CURR_VAL, XN_VAL,
				         DB_CR_FLG, LEDGER_NAR, CASHIER_ID,
				         USER_ID, CRE_DT, UPD_DT,
				         DOC_DATE, DUE_DATE, NETTING_DATE,
						 NETTING_FLG,RECORD_SOURCE,
						 APPROVED_STS,MANUAL, ARAP_DUE_DATE,
						 BUDGET_CD, FOLDER_CD)
				      VALUES (
				         p_contract_num, p_contract_num, v_tal_id,vacct_type,trim(vsl_acct_cd),
				         vgl_acct_cd,NULL,NULL,
				         rec.curr_cd,rec.brch_cd,rec.amt_for_curr,rec.amt_for_curr,
				         p_trans_type,vledger_nar,NULL,
				         p_user_id,SYSDATE,NULL,
				         rec.contr_dt, rec.due_dt_for_amt, NULL,
						 '0', 'CG',
						 vapprove, v_manual,rec.due_dt_for_amt,
						 NULL,v_folder_cd);
						EXCEPTION
					       WHEN OTHERS THEN
				           		v_error_code := -4;
							   v_error_msg :=  SUBSTR('Insert contract T_ACCOUNT_LEDGER : '||p_contract_num||v_nl||SQLERRM,1,200);
							   RAISE v_err;
					       --RAISE_APPLICATION_ERROR(-20100,'insert contract T_ACCOUNT_LEDGER : '||p_contract_num||v_nl||SQLERRM);
					    END;
					*/
				BEGIN
					Gen_Trx_Jur_Line_Nextg( p_contract_num, --p_doc_num
											p_contract_num, --P_DOC_REF_NUM
											rec.contr_dt, --p_date
											rec.due_dt_for_amt, --p_due_date
											rec.due_dt_for_amt, --p_arap_due_date
											v_tal_id, --p_tal_id 
											vacct_type, --p_acct_type  
											vgl_acct_cd, --p_gl_acct_cd
											trim(vsl_acct_cd), --p_sl_acct_cd 
											vdb_cr_flg, --p_db_cr_flg 
											rec.amt_for_curr, --p_curr_val
											vledger_nar, --p_ledger_nar 
											v_curr_cd, --p_curr_cd
											v_budget_cd, --p_budget_cd  
											rec.brch_cd, 
											v_folder_cd, 
											v_record_source,
											v_approved_sts, 
											p_user_id,
											v_manual, 
											v_error_code,
											v_error_msg);
				EXCEPTION
			       WHEN OTHERS THEN
                  v_error_code :=  -20;
                  v_error_msg := SUBSTR('insert  T_ACCOUNT_LEDGER : '||p_contract_num||' - '||vgl_acct_cd||' - '||vsl_acct_cd||v_nl||SQLERRM,1,200);
                  Raise V_Err;
			    END;
				
				
				IF v_error_code < 0 THEN 
                  v_error_code :=  -30;
                  v_error_msg := SUBSTR('Gen_Trx_Jur_Line_Nextg '||v_error_msg||v_nl||SQLERRM,1,200);
                  RAISE v_err;
				END IF;
--================================KPEI / BROKER =================================================		
		
		     IF p_trans_type = 'D' THEN
		         vdb_cr_flg := 'C';
		     ELSE
		         vdb_cr_flg := 'D';
		     END IF;
		
		
--		     IF SUBSTR(p_contract_num,6,1) <> 'I' THEN
		
		 	 IF rec.mrkt_type = 'NG'    OR rec.mrkt_type = 'TS'   THEN
			 				    v_tal_id	:= 2;
	
						    IF p_trans_type = 'D' THEN
						 	      vgl_acct_cd := Get_Gl_Acc_Code('BROK','C');
						    ELSE
						    	   vgl_acct_cd := Get_Gl_Acc_Code('BROK','D');
						    END IF;
	
						    vgl_acct_cd := SUBSTR(vgl_acct_cd,1,4);
						    IF p_trans_type = 'D' THEN
							     IF rec.mrkt_type = 'TS' THEN 
								 		vsl_acct_cd :=  v_kode_ab;
								 ELSE		
						         		vsl_acct_cd := rec.sell_broker_cd;
								END IF;		
				     		    vledger_nar := 'Sell ';
				
						    ELSE
								IF rec.mrkt_type = 'TS' THEN 
								 		vsl_acct_cd :=  v_kode_ab;
								 ELSE	
						 	 	 		vsl_acct_cd := rec.buy_broker_cd;
								END IF;		
						        vledger_nar := 'Buy ';
				
					         END IF;
	
	
				    		v_rtn := Check_Gl_Acct(trim(vgl_acct_cd)||trim(vsl_acct_cd));
						    IF trim(v_rtn) = 'notfound' THEN
                      v_error_code := -5;
                      v_error_msg :=  SUBSTR('Cannot find GL ACCOUNT CODE : '||trim(vgl_acct_cd)||trim(vsl_acct_cd),1,200);
                      RAISE v_err;
								  	   --RAISE_APPLICATION_ERROR(-20100,' Cannot find GL ACCOUNT CODE : '||trim(vgl_acct_cd)||trim(vsl_acct_cd));
						    END IF;
				
	
						    vledger_nar := vledger_nar|| trim(rec.stk_cd)||' '||TO_CHAR(rec.qty,'fm999,999,999')||' @'||TO_CHAR(rec.price);
	
--			--			if rec.mrkt_type = 'NG' then
				   			 vledger_nar := vledger_nar||' (PASAR NEGO)';
--			--			else
--			--			   vledger_nar := vledger_nar||' (TUNAI)';
--			--			end if;
	
--		 	 IF rec.mrkt_type = 'NG'    OR rec.mrkt_type = 'TS'   THEN
			 ELSE
                    v_tal_id	:= 2;
							IF p_trans_type = 'D' THEN
                    vgl_acct_cd := Get_Gl_Acc_Code('KPEI','C');
                    vledger_nar := 'BUYING FROM KPEI  ';
							ELSE
                    vgl_acct_cd := Get_Gl_Acc_Code('KPEI','D');
                    vledger_nar := 'SELLING FROM KPEI  ';
							END IF;
							IF rec.contr_dt = rec.due_dt_for_amt THEN
                    vledger_nar := vledger_nar||'/TN';
							 ELSE
                    vledger_nar := vledger_nar||'due  '||TO_CHAR(rec.due_dt_for_amt,'dd/mm/yy');
							END IF;
				
              vgl_acct_cd := SUBSTR(vgl_acct_cd,1,4);
              vsl_acct_cd := 'KPEI';
              
--		 	 IF rec.mrkt_type = 'NG'    OR rec.mrkt_type = 'TS'   THEN
			 END IF;
		/*
			BEGIN
		     INSERT INTO T_ACCOUNT_LEDGER (
		         XN_DOC_NUM, TAL_ID, ACCT_TYPE, SL_ACCT_CD,
		         GL_ACCT_CD, CHRG_CD, CHQ_SNO,
		         CURR_CD,  BRCH_CD, CURR_VAL, XN_VAL,
		         DB_CR_FLG, LEDGER_NAR, CASHIER_ID,
		         USER_ID, CRE_DT, UPD_DT,
		         DOC_DATE, DUE_DATE, NETTING_DATE,
				 NETTING_FLG,RECORD_SOURCE,
				 APPROVED_STS,MANUAL, ARAP_DUE_DATE,
				 BUDGET_CD, FOLDER_CD)
		      VALUES (
		         p_contract_num, v_tal_id, NULL,trim(vsl_acct_cd),
		         vgl_acct_cd,NULL,NULL,
		         rec.curr_cd,rec.brch_cd,rec.val,rec.val,
		         vdb_cr_flg,vledger_nar,NULL,
		         p_user_id,SYSDATE,NULL,
		         rec.contr_dt, rec.kpei_due_dt, NULL,
				 '2', 'CG',
				 vapprove, v_manual,rec.kpei_due_dt,
				 NULL,v_folder_cd);
			     EXCEPTION
			     WHEN OTHERS THEN
			           v_error_code := -6;
			           v_error_msg :=  SUBSTR('Insert KPEI T_ACCOUNT_LEDGER : '||p_contract_num||v_nl||SQLERRM,1,200);
			           RAISE v_err;
			       --RAISE_APPLICATION_ERROR(-20100,'insert KPEI T_ACCOUNT_LEDGER : '||p_contract_num||v_nl||SQLERRM);
		 	END;
		*/
				BEGIN
					Gen_Trx_Jur_Line_Nextg( p_contract_num, --p_doc_num
											p_contract_num, --P_DOC_REF_NUM
											rec.contr_dt, --p_date
											rec.kpei_due_dt, --p_due_date
											rec.kpei_due_dt, --p_arap_due_date
											v_tal_id, --p_tal_id 
											null, --p_acct_type  
											vgl_acct_cd, --p_gl_acct_cd
											trim(vsl_acct_cd), --p_sl_acct_cd 
											vdb_cr_flg, --p_db_cr_flg 
											rec.val, --p_curr_val
											vledger_nar, --p_ledger_nar 
											v_curr_cd, --p_curr_cd
											null, --p_budget_cd  
											rec.brch_cd, 
											v_folder_cd, 
											'CG',
											v_approved_sts, 
											p_user_id,
											v_manual, 
											v_error_code,
											v_error_msg);
				EXCEPTION
			       WHEN OTHERS THEN
                v_error_code :=  -40;
                v_error_msg := SUBSTR('insert  T_ACCOUNT_LEDGER : '||p_contract_num||' - '||vgl_acct_cd||' - '||vsl_acct_cd||v_nl||SQLERRM,1,200);
                RAISE v_err;
			    END;
				
				
				IF v_error_code < 0 THEN 
                v_error_code :=  -45;
                v_error_msg := SUBSTR('Gen_Trx_Jur_Line_Nextg '||v_error_msg||v_nl||SQLERRM,1,200);
                RAISE v_err;
				END IF;
				
/*============= =====================COMMISSION ==============================================*/
		
		       vgl_acct_cd := Get_Gl_Acc_Code('COMM','_');
		       vsl_acct_cd := SUBSTR(vgl_acct_cd,5,6);
		       vgl_acct_cd := SUBSTR(vgl_acct_cd,1,4);
		
		      IF rec.commission <>  0  THEN
		  		      	 v_tal_id	:= 3;
		
				         vdb_cr_flg := 'C';
				/*
						 BEGIN
				         INSERT INTO T_ACCOUNT_LEDGER (
				             XN_DOC_NUM, TAL_ID, ACCT_TYPE, SL_ACCT_CD,
				             GL_ACCT_CD, CHRG_CD, CHQ_SNO,
				             CURR_CD,  BRCH_CD, CURR_VAL, XN_VAL,
				             DB_CR_FLG, LEDGER_NAR, CASHIER_ID,
				             USER_ID, CRE_DT, UPD_DT,
				             DOC_DATE, DUE_DATE, NETTING_DATE,
						 	 NETTING_FLG,RECORD_SOURCE,APPROVED_STS,MANUAL, ARAP_DUE_DATE,BUDGET_CD, FOLDER_CD)
				         VALUES (
				             p_contract_num,v_tal_id,NULL,trim(vsl_acct_cd),
				             vgl_acct_cd, NULL,NULL,
				             rec.curr_cd,rec.brch_cd,rec.commission,rec.commission,
				             vdb_cr_flg,'COMMISSION',NULL,
				             p_user_id,SYSDATE,NULL,
				             rec.contr_dt, rec.due_dt_for_amt, NULL,
						 	 '2', 'CG', vapprove, v_manual,rec.due_dt_for_amt,NULL,v_folder_cd);
						  EXCEPTION
					         WHEN OTHERS THEN
						           v_error_code := -7;
						           v_error_msg :=  SUBSTR('Insert COMMISSION T_ACCOUNT_LEDGER : '||p_contract_num||v_nl||SQLERRM,1,200);
						           RAISE v_err;
					         --RAISE_APPLICATION_ERROR(-20100,'insert COMMISSION T_ACCOUNT_LEDGER : '||p_contract_num||v_nl||SQLERRM);
					      END;
				*/
				BEGIN
					Gen_Trx_Jur_Line_Nextg( p_contract_num, --p_doc_num
											p_contract_num, --P_DOC_REF_NUM
											rec.contr_dt, --p_date
											rec.due_dt_for_amt, --p_due_date
											rec.due_dt_for_amt, --p_arap_due_date
											v_tal_id, --p_tal_id 
											null, --p_acct_type  
											vgl_acct_cd, --p_gl_acct_cd
											trim(vsl_acct_cd), --p_sl_acct_cd 
											vdb_cr_flg, --p_db_cr_flg 
											rec.commission, --p_curr_val
											'COMMISSION', --p_ledger_nar 
											v_curr_cd, --p_curr_cd
											null, --p_budget_cd  
											rec.brch_cd, 
											v_folder_cd, 
											'CG',
											v_approved_sts, 
											p_user_id,
											v_manual, 
											v_error_code,
											v_error_msg);
				EXCEPTION
			       WHEN OTHERS THEN
                v_error_code :=  -50;
                v_error_msg := SUBSTR('insert  T_ACCOUNT_LEDGER : '||p_contract_num||' - '||vgl_acct_cd||' - '||vsl_acct_cd||v_nl||SQLERRM,1,200);
                RAISE v_err;
			    END;
				
				
				IF v_error_code < 0 THEN 
                v_error_code :=  -55;
                v_error_msg := SUBSTR('Gen_Trx_Jur_Line_Nextg '||v_error_msg||v_nl||SQLERRM,1,200);
                RAISE v_err;
				END IF;
				
		      END IF;
		
		
--============================================= VAT OUT STANDARD =====================================		
		
		      IF rec.vat <> 0  THEN
				      	v_tal_id	:= 4;
				
						IF rec.contr_dt > '31mar10' THEN
				
							vgl_acct_cd := Get_Gl_Acc_Code('POSD','_');
							vledger_nar := 'VAT OUT STANDARD';
		
						ELSE
				
							BEGIN -- cek NPWP
							   SELECT COUNT(1) INTO v_nrtn
							   FROM MST_CLIENT
							   WHERE client_cd = rec.client_cd
							   AND NPWP_NO IS NOT NULL;
							   EXCEPTION
						       WHEN NO_DATA_FOUND THEN
							      v_nrtn := 0;
							END;
		
							IF v_nrtn = 0 THEN
                  vgl_acct_cd := Get_Gl_Acc_Code('PPNO','_');
                  vledger_nar := 'VAT OUT SEDERHANA';
							ELSE
                  vgl_acct_cd := Get_Gl_Acc_Code('POSD','_');
                  vledger_nar := 'VAT OUT STANDARD';
							END IF;
		
		 			END IF;
		
                vsl_acct_cd := SUBSTR(vgl_acct_cd,5,6);
                vgl_acct_cd := SUBSTR(vgl_acct_cd,1,4);
		
                vdb_cr_flg := 'C';
					/*
				    BEGIN
			         INSERT INTO T_ACCOUNT_LEDGER (
			             XN_DOC_NUM, TAL_ID, ACCT_TYPE, SL_ACCT_CD,
			             GL_ACCT_CD, CHRG_CD, CHQ_SNO,
			             CURR_CD,  BRCH_CD, CURR_VAL, XN_VAL,
			             DB_CR_FLG, LEDGER_NAR, CASHIER_ID,
			             USER_ID, CRE_DT, UPD_DT,
			             DOC_DATE, DUE_DATE, NETTING_DATE,
					 	 NETTING_FLG,RECORD_SOURCE,APPROVED_STS,MANUAL, ARAP_DUE_DATE,BUDGET_CD, FOLDER_CD)
			         VALUES (
			             p_contract_num, v_tal_id, NULL,vsl_acct_cd,
			             vgl_acct_cd,NULL,NULL,
			             rec.curr_cd,rec.brch_cd,rec.vat,rec.vat,
			             vdb_cr_flg,vledger_nar,NULL,
			             p_user_id,SYSDATE,NULL,
			             rec.contr_dt, rec.kpei_due_dt, NULL,
					 	 '2', 'CG', vapprove, v_manual,rec.kpei_due_dt,NULL,v_folder_cd);
					  EXCEPTION
				       WHEN OTHERS THEN
						         v_error_code := -8;
						         v_error_msg :=  SUBSTR('Insert VAT OUT T_ACCOUNT_LEDGER : '||p_contract_num||v_nl||SQLERRM,1,200);
						         RAISE v_err;
							       --RAISE_APPLICATION_ERROR(-20100,'insert VAT OUT T_ACCOUNT_LEDGER : '||p_contract_num||v_nl||SQLERRM);
				    END;
		*/
				BEGIN
					Gen_Trx_Jur_Line_Nextg( p_contract_num, --p_doc_num
											p_contract_num, --P_DOC_REF_NUM
											rec.contr_dt, --p_date
											rec.kpei_due_dt, --p_due_date
											rec.kpei_due_dt, --p_arap_due_date
											v_tal_id, --p_tal_id 
											null, --p_acct_type  
											vgl_acct_cd, --p_gl_acct_cd
											trim(vsl_acct_cd), --p_sl_acct_cd 
											vdb_cr_flg, --p_db_cr_flg 
											rec.vat, --p_curr_val
											vledger_nar, --p_ledger_nar 
											v_curr_cd, --p_curr_cd
											null, --p_budget_cd  
											rec.brch_cd, 
											v_folder_cd, 
											'CG',
											v_approved_sts, 
											p_user_id,
											v_manual, 
											v_error_code,
											v_error_msg);
				EXCEPTION
			       WHEN OTHERS THEN
                  v_error_code :=  -60;
                  v_error_msg := SUBSTR('insert  T_ACCOUNT_LEDGER : '||p_contract_num||' - '||vgl_acct_cd||' - '||vsl_acct_cd||v_nl||SQLERRM,1,200);
                  RAISE v_err;
			    END;
				
				
				IF v_error_code < 0 THEN 
                  v_error_code :=  -65;
                  v_error_msg := SUBSTR('Gen_Trx_Jur_Line_Nextg '||v_error_msg||v_nl||SQLERRM,1,200);
                  RAISE v_err;
				END IF;
				
		      END IF;
		
--=====================================================LEVY/ BEI FEE =================================		
/*		      vincome_commission := 0;
		      IF rec.trans_levy <> 0  THEN
				      	 v_tal_id	:= 5;
				     	 vgl_acct_cd := Get_Gl_Acc_Code('LEVY','_');
				         vsl_acct_cd := SUBSTR(vgl_acct_cd,5,6);
					     vgl_acct_cd := SUBSTR(vgl_acct_cd,1,4);
				
						IF rec.mrkt_type = 'NG' THEN
						   vincome_commission := 0.0001 * rec.val;
						   vtrans_levy := rec.trans_levy - vincome_commission;
						ELSE
						   vtrans_levy := rec.trans_levy;
						END IF;
				
				    	BEGIN
				         INSERT INTO T_ACCOUNT_LEDGER (
				             XN_DOC_NUM, TAL_ID, ACCT_TYPE, SL_ACCT_CD,
				             GL_ACCT_CD, CHRG_CD, CHQ_SNO,
				             CURR_CD, BRCH_CD, CURR_VAL, XN_VAL,
				             DB_CR_FLG, LEDGER_NAR, CASHIER_ID,
				             USER_ID, CRE_DT, UPD_DT,
				             DOC_DATE, DUE_DATE, NETTING_DATE,
						 	 NETTING_FLG,RECORD_SOURCE,APPROVED_STS,MANUAL, ARAP_DUE_DATE,BUDGET_CD, FOLDER_CD)
				         VALUES (
				             p_contract_num, v_tal_id ,NULL,trim(vsl_acct_cd),
				             vgl_acct_cd,NULL,NULL,
				             rec.curr_cd,rec.brch_cd,vtrans_levy,vtrans_levy,
				             'C','BEJ FEE/LEVY',NULL,
				             p_user_id,SYSDATE,NULL,
				             rec.contr_dt, rec.kpei_due_dt, NULL,
						 	 '2', 'CG',vapprove, v_manual,rec.kpei_due_dt,NULL,v_folder_cd);
						  EXCEPTION
					       WHEN OTHERS THEN
						         v_error_code := -9;
						         v_error_msg :=  SUBSTR('Insert LEVY T_ACCOUNT_LEDGER : '||p_contract_num||v_nl||SQLERRM,1,200);
						         RAISE v_err;
					       --RAISE_APPLICATION_ERROR(-20100,'insert LEVY T_ACCOUNT_LEDGER : '||p_contract_num||v_nl||SQLERRM);
					    END;
		
		
		      END IF;*/
		
--=============================================PPH SALE 10%====================================		
		      IF rec.pph <> 0  THEN
		
		      	 v_tal_id	:= 5;
		         vgl_acct_cd := Get_Gl_Acc_Code('PPH','_');
		         vsl_acct_cd := SUBSTR(vgl_acct_cd,5,6);
			     vgl_acct_cd := SUBSTR(vgl_acct_cd,1,4);
		/*
				 BEGIN
		         INSERT INTO T_ACCOUNT_LEDGER (
		             XN_DOC_NUM, TAL_ID, ACCT_TYPE, SL_ACCT_CD,
		             GL_ACCT_CD, CHRG_CD, CHQ_SNO,
		             CURR_CD, BRCH_CD, CURR_VAL, XN_VAL,
		             DB_CR_FLG, LEDGER_NAR, CASHIER_ID,
		             USER_ID, CRE_DT, UPD_DT,
		             DOC_DATE, DUE_DATE, NETTING_DATE,
				 	 NETTING_FLG,RECORD_SOURCE,APPROVED_STS,MANUAL, ARAP_DUE_DATE,BUDGET_CD, FOLDER_CD)
		         VALUES (
		             p_contract_num, v_tal_id , NULL,trim(vsl_acct_cd),
		             vgl_acct_cd,NULL,NULL,
		             rec.curr_cd,rec.brch_cd,rec.pph,rec.pph,
		             'C','PPH 23',NULL,
		             p_user_id,SYSDATE,NULL,
		             rec.contr_dt, rec.kpei_due_dt, NULL,
				 	 '2', 'CG', vapprove, v_manual,rec.kpei_due_dt,NULL,v_folder_cd);
				  EXCEPTION
			         WHEN OTHERS THEN
				           v_error_code := -10;
				           v_error_msg :=  SUBSTR('Insert PPH T_ACCOUNT_LEDGER : '||p_contract_num||v_nl||SQLERRM,1,200);
				           RAISE v_err;
			         --RAISE_APPLICATION_ERROR(-20100,'insert PPH T_ACCOUNT_LEDGER : '||p_contract_num||v_nl||SQLERRM);
			      END;
		*/
				BEGIN
					Gen_Trx_Jur_Line_Nextg( p_contract_num, --p_doc_num
										   p_contract_num, --P_DOC_REF_NUM
										   rec.contr_dt, --p_date
										   rec.kpei_due_dt, --p_due_date
										   rec.kpei_due_dt, --p_arap_due_date
										   v_tal_id, --p_tal_id 
										   null, --p_acct_type  
										   vgl_acct_cd, --p_gl_acct_cd
										   trim(vsl_acct_cd), --p_sl_acct_cd 
											'C', --p_db_cr_flg 
										   rec.pph, --p_curr_val
										   'PPH 23', --p_ledger_nar 
										   v_curr_cd, --p_curr_cd
										   null, --p_budget_cd  
										   rec.brch_cd, 
										   v_folder_cd, 
											'CG',
										   v_approved_sts, 
										   p_user_id,
										   v_manual, 
											v_error_code,
											v_error_msg);
				EXCEPTION
			       WHEN OTHERS THEN
                  v_error_code :=  -70;
                  v_error_msg := SUBSTR('insert  T_ACCOUNT_LEDGER : '||p_contract_num||' - '||vgl_acct_cd||' - '||vsl_acct_cd||v_nl||SQLERRM,1,200);
                  RAISE v_err;
			    END;
				
				
				IF v_error_code < 0 THEN 
                  v_error_code :=  -75;
                  v_error_msg := SUBSTR('Gen_Trx_Jur_Line_Nextg '||v_error_msg||v_nl||SQLERRM,1,200);
                  RAISE v_err;
				END IF;
		
		      END IF;
		
--======================================= UTANG DANA JAMINAN 0.01 x     (qty x price) / 100 ======================
-- BEI fee = 0,04%
--  UTANG DANA JAMINAN 0.01%  --->>> 0,01  x     (qty x price) / 100
--  sisanya 0.03%  ditambah tax 10% -> 0.033%   ==>>   0.033  x     (qty x price) / 100
-- sisa tsb diatas dibagi jadi 60% biaya bei, 30% biaya LKP, 10% biaya LPP
 
				v_utang_dana_jaminan := TRUNC(0.0001 * rec.val,2);         
				v_utang_biaya_lpp         :=  TRUNC(rec.val * 0.033 * 0.1 / 100,2);  
				v_utang_biaya_lkp         :=  TRUNC(rec.val * 0.033 * 0.3 / 100,2);  
				v_utang_biaya_bei         :=  TRUNC(rec.trans_levy - v_utang_dana_jaminan - v_utang_biaya_lkp - v_utang_biaya_lpp,2);
				
				vdb_cr_flg := 'C';
				v_tal_id	:= 6;
				
				BEGIN
					Gen_Trx_Jur_Line_Nextg( p_contract_num, --p_doc_num
										   NULL, --P_DOC_REF_NUM
										   rec.contr_dt, --p_date
										   rec.contr_dt, --p_due_date
										   NULL, --p_arap_due_date
										   v_tal_id, --p_tal_id 
										   trim(vgl_acct_cd), --p_acct_type  
										   vgl_acct_cd, --p_gl_acct_cd
										   trim(vsl_acct_cd), --p_sl_acct_cd 
											vdb_cr_flg, --p_db_cr_flg 
										   v_utang_dana_jaminan, --p_curr_val
										   'Utang dana jaminan', --p_ledger_nar 
										   v_curr_cd, --p_curr_cd
										   v_budget_cd, --p_budget_cd  
											rec.brch_cd, --brch_cd, 
										   v_folder_cd, 
											v_record_source,
										   v_approved_sts, 
										   p_user_id,
										   v_manual, 
											v_error_code,
											v_error_msg);
				EXCEPTION
					WHEN OTHERS THEN
                v_error_code :=  -80;
                v_error_msg := SUBSTR('insert  T_ACCOUNT_LEDGER : '||p_contract_num||' - '||vgl_acct_cd||' - '||vsl_acct_cd||v_nl||SQLERRM,1,200);
                RAISE v_err;
				END;
						
				IF v_error_code < 0 THEN 
                v_error_code :=  -85;
                v_error_msg := SUBSTR('Gen_Trx_Jur_Line_Nextg '||v_error_msg||v_nl||SQLERRM,1,200);
                RAISE v_err;
				END IF;
  

		
--====================================VAT IN tdk dipakai lg =========================		
/*				  IF rec.LEVY_TAX <> 0  THEN
						 -- Debit
		--		     if vdb_cr_flg = 'C' then
		--		        vdb_cr_flg := 'D';
		--		     end if;
		
					 v_tal_id	:= 8;
					 vgl_acct_cd := Get_Gl_Acc_Code('PPNI','_');
		           	 vsl_acct_cd := SUBSTR(vgl_acct_cd,5,6);
			       	 vgl_acct_cd := SUBSTR(vgl_acct_cd,1,4);
		
					 BEGIN
				     INSERT INTO T_ACCOUNT_LEDGER (
				         XN_DOC_NUM, TAL_ID, ACCT_TYPE, SL_ACCT_CD,
				         GL_ACCT_CD, CHRG_CD, CHQ_SNO,
				         CURR_CD, BRCH_CD, CURR_VAL, XN_VAL,
				         DB_CR_FLG, LEDGER_NAR, CASHIER_ID,
				         USER_ID, CRE_DT, UPD_DT,
				         DOC_DATE, DUE_DATE, NETTING_DATE,
						 NETTING_FLG,RECORD_SOURCE,APPROVED_STS,MANUAL, ARAP_DUE_DATE,BUDGET_CD, FOLDER_CD)
				      VALUES (
				         p_contract_num, v_tal_id, NULL,trim(vsl_acct_cd),
				         vgl_acct_cd,NULL,NULL,
				         rec.curr_cd,rec.brch_cd,rec.LEVY_TAX,rec.LEVY_TAX,
				         'D','VAT IN STANDARD',NULL,
				         p_user_id,SYSDATE,NULL,
				         rec.contr_dt, rec.kpei_due_dt, NULL,
						 '2', 'CG',vapprove, v_manual,rec.kpei_due_dt,NULL,v_folder_cd);
					   EXCEPTION
					       WHEN OTHERS THEN
					             v_error_code := -11;
					             v_error_msg :=  SUBSTR('Insert VAT-IN T_ACCOUNT_LEDGER : '||p_contract_num||v_nl||SQLERRM,1,200);
					             RAISE v_err;
					       --RAISE_APPLICATION_ERROR(-20100,'insert VAT-IN T_ACCOUNT_LEDGER : '||p_contract_num||v_nl||SQLERRM);
					    END;
		
		
						 -- Credit
				     vdb_cr_flg := 'C';
				     v_tal_id		:= 6;
		 			vgl_acct_cd := Get_Gl_Acc_Code('LEVY','_');
			        	vsl_acct_cd := SUBSTR(vgl_acct_cd,5,6);
				    vgl_acct_cd := SUBSTR(vgl_acct_cd,1,4);
		
					 BEGIN
				     INSERT INTO T_ACCOUNT_LEDGER (
				         XN_DOC_NUM, TAL_ID, ACCT_TYPE, SL_ACCT_CD,
				         GL_ACCT_CD, CHRG_CD, CHQ_SNO,
				         CURR_CD, BRCH_CD, CURR_VAL, XN_VAL,
				         DB_CR_FLG, LEDGER_NAR, CASHIER_ID,
				         USER_ID, CRE_DT, UPD_DT,
				         DOC_DATE, DUE_DATE, NETTING_DATE,
						 NETTING_FLG,RECORD_SOURCE,APPROVED_STS,MANUAL, ARAP_DUE_DATE,BUDGET_CD, FOLDER_CD)
				      VALUES (
				         p_contract_num, v_tal_id, NULL,trim(vsl_acct_cd),
				         vgl_acct_cd,NULL,NULL,
				         rec.curr_cd,rec.brch_cd,rec.LEVY_TAX,rec.LEVY_TAX,
				         'C','BEJ FEE/LEVY TAX', NULL,
				         p_user_id,SYSDATE,NULL,
				         rec.contr_dt, rec.kpei_due_dt, NULL,
						 '2', 'CG',vapprove, v_manual,rec.kpei_due_dt,NULL,v_folder_cd);
					  EXCEPTION
					       WHEN OTHERS THEN
					             v_error_code := -12;
					             v_error_msg :=  SUBSTR('Insert LEVY-TAX T_ACCOUNT_LEDGER : '||p_contract_num||v_nl||SQLERRM,1,200);
					             RAISE v_err;
					       --RAISE_APPLICATION_ERROR(-20100,'insert LEVY-TAX T_ACCOUNT_LEDGER : '||p_contract_num||v_nl||SQLERRM);
					    END;
		
		
				END IF;*/
		
--===========================================INCOME COMMISSION============================		
		
		        IF rec.mrkt_type = 'NG' THEN
		
				   IF vincome_commission <> 0 THEN
		
		    		  v_tal_id		:= 9;
			     	  vgl_acct_cd := Get_Gl_Acc_Code('OTHI','_');
			          vsl_acct_cd := SUBSTR(vgl_acct_cd,5,6);
				      vgl_acct_cd := SUBSTR(vgl_acct_cd,1,4);
		/*
		  			 BEGIN
				     INSERT INTO T_ACCOUNT_LEDGER (
				         XN_DOC_NUM, TAL_ID, ACCT_TYPE, SL_ACCT_CD,
				         GL_ACCT_CD, CHRG_CD, CHQ_SNO,
				         CURR_CD, BRCH_CD, CURR_VAL, XN_VAL,
				         DB_CR_FLG, LEDGER_NAR, CASHIER_ID,
				         USER_ID, CRE_DT, UPD_DT,
				         DOC_DATE, DUE_DATE, NETTING_DATE,
						 NETTING_FLG,RECORD_SOURCE,APPROVED_STS,MANUAL, ARAP_DUE_DATE,BUDGET_CD, FOLDER_CD)
				      VALUES (
				         p_contract_num, v_tal_id, NULL,trim(vsl_acct_cd),
				         vgl_acct_cd,NULL,NULL,
				         rec.curr_cd,rec.brch_cd,vincome_commission,vincome_commission,
				         'C','Income Commission', NULL,
				         p_user_id,SYSDATE,NULL,
				         rec.contr_dt, rec.kpei_due_dt, NULL,
						 '2', 'CG',vapprove, v_manual,rec.kpei_due_dt,NULL,v_folder_cd);
					  EXCEPTION
					       WHEN OTHERS THEN
					             v_error_code := -13;
					             v_error_msg :=  SUBSTR('Insert INCOME-COMM T_ACCOUNT_LEDGER : '||p_contract_num||v_nl||SQLERRM,1,200);
					             RAISE v_err;
					       --RAISE_APPLICATION_ERROR(-20100,'insert INCOME-COMM T_ACCOUNT_LEDGER : '||p_contract_num||v_nl||SQLERRM);
					    END;
		*/
				BEGIN
					Gen_Trx_Jur_Line_Nextg( p_contract_num, --p_doc_num
										   p_contract_num, --P_DOC_REF_NUM
										   rec.contr_dt, --p_date
										   rec.kpei_due_dt, --p_due_date
										   rec.kpei_due_dt, --p_arap_due_date
										   v_tal_id, --p_tal_id 
										   null, --p_acct_type  
										   vgl_acct_cd, --p_gl_acct_cd
										   Trim(Vsl_Acct_Cd), --p_sl_acct_cd 
											'C', --p_db_cr_flg 
										   vincome_commission, --p_curr_val
										   'Income Commission', --p_ledger_nar 
										   v_curr_cd, --p_curr_cd
										   null, --p_budget_cd  
										   rec.brch_cd, 
										   v_folder_cd, 
											'CG',
										   v_approved_sts, 
										   p_user_id,
										   v_manual, 
											v_error_code,
											v_error_msg);
				EXCEPTION
			       WHEN OTHERS THEN
                  v_error_code :=  -90;
                  v_error_msg := SUBSTR('insert  T_ACCOUNT_LEDGER : '||p_contract_num||' - '||vgl_acct_cd||' - '||vsl_acct_cd||v_nl||SQLERRM,1,200);
                  RAISE v_err;
			    END;
				
				
				IF v_error_code < 0 THEN 
                  v_error_code :=  -95;
                  v_error_msg := SUBSTR('Gen_Trx_Jur_Line_Nextg '||v_error_msg||v_nl||SQLERRM,1,200);
                  RAISE v_err;
				END IF;
		
				END IF;
		
			END IF;
		
--=========================================== UANG MUKA PPH23 =====================================
		
			   IF NVL(rec.pph_other_val,0) <> 0 THEN
		
		      	 v_tal_id	:= 10;
		         vgl_acct_cd := Get_Gl_Acc_Code('UP23','_');
		         vsl_acct_cd := SUBSTR(vgl_acct_cd,5,6);
			     vgl_acct_cd := SUBSTR(vgl_acct_cd,1,4);
		
				/*
				 BEGIN
		         INSERT INTO T_ACCOUNT_LEDGER (
		             XN_DOC_NUM, TAL_ID, ACCT_TYPE, SL_ACCT_CD,
		             GL_ACCT_CD, CHRG_CD, CHQ_SNO,
		             CURR_CD, BRCH_CD, CURR_VAL, XN_VAL,
		             DB_CR_FLG, LEDGER_NAR, CASHIER_ID,
		             USER_ID, CRE_DT, UPD_DT,
		             DOC_DATE, DUE_DATE, NETTING_DATE,
				 	 NETTING_FLG,RECORD_SOURCE,APPROVED_STS,MANUAL, ARAP_DUE_DATE,BUDGET_CD, FOLDER_CD)
		         VALUES (
		             p_contract_num, v_tal_id , NULL,trim(vsl_acct_cd),
		             vgl_acct_cd,NULL,NULL,
		             rec.curr_cd,rec.brch_cd,rec.pph_other_val,rec.pph_other_val,
		             'D','UM PPH 23 '||rec.client_cd||' TR '||TO_CHAR(rec.contr_dt,'dd/mm/yy'),NULL,
		             p_user_id,SYSDATE,NULL,
		             rec.contr_dt, rec.kpei_due_dt, NULL,
				 	 '2', 'CG', vapprove, v_manual,rec.kpei_due_dt,NULL,v_folder_cd);
				  EXCEPTION
			         WHEN OTHERS THEN
					           v_error_code := -14;
					           v_error_msg :=  SUBSTR('Insert WH TAX PPH T_ACCOUNT_LEDGER : '||p_contract_num||v_nl||SQLERRM,1,200);
					           RAISE v_err;
			         --RAISE_APPLICATION_ERROR(-20100,'insert WH TAX PPH T_ACCOUNT_LEDGER : '||p_contract_num||v_nl||SQLERRM);
			      END;
		*/
				BEGIN
					Gen_Trx_Jur_Line_Nextg( p_contract_num, --p_doc_num
										   p_contract_num, --P_DOC_REF_NUM
										   rec.contr_dt, --p_date
										   rec.kpei_due_dt, --p_due_date
										   rec.kpei_due_dt, --p_arap_due_date
										   v_tal_id, --p_tal_id 
										   NULL, --p_acct_type  
										   vgl_acct_cd, --p_gl_acct_cd
										   trim(vsl_acct_cd), --p_sl_acct_cd 
											'D', --p_db_cr_flg 
										   rec.pph_other_val, --p_curr_val
										   'UM PPH 23 '||rec.client_cd||' TR '||TO_CHAR(rec.contr_dt,'dd/mm/yy'), --p_ledger_nar 
										   v_curr_cd, --p_curr_cd
										   null, --p_budget_cd  
										   rec.brch_cd, 
										   v_folder_cd, 
											'CG',
										   v_approved_sts, 
										   p_user_id,
										   v_manual, 
											v_error_code,
											v_error_msg);
				EXCEPTION
			       WHEN OTHERS THEN
                  v_error_code :=  -100;
                  v_error_msg := SUBSTR('insert  T_ACCOUNT_LEDGER : '||p_contract_num||' - '||vgl_acct_cd||' - '||vsl_acct_cd||v_nl||SQLERRM,1,200);
                  RAISE v_err;
			    END;
				
				
				IF v_error_code < 0 THEN 
                  v_error_code :=  -105;
                  v_error_msg := SUBSTR('Gen_Trx_Jur_Line_Nextg '||v_error_msg||v_nl||SQLERRM,1,200);
                  RAISE v_err;
				END IF;
			   END IF;

--=======================================PEMBULATAN Contract avg price ========================		
			   IF rec.contra_num = 'APRICE' THEN
		
			   	  SELECT SUM(DECODE(db_cr_flg,'D',1,-1) * curr_val)
				         INTO v_selisih
				  FROM T_ACCOUNT_LEDGER
				  WHERE XN_DOC_NUM = p_contract_num;
		
				  IF v_selisih <> 0  THEN
		
				  	 IF v_selisih > 0 THEN
					   vdb_cr_flg := 'C';
		
					 ELSE
					   vdb_cr_flg := 'D';
					 END IF;
		-- 12may11 6504 dirubah jd 6509 100000
		/*
					 BEGIN
			         INSERT INTO T_ACCOUNT_LEDGER (
			             XN_DOC_NUM, TAL_ID, ACCT_TYPE, SL_ACCT_CD,
			             GL_ACCT_CD, CHRG_CD, CHQ_SNO,
			             CURR_CD, BRCH_CD, CURR_VAL, XN_VAL,
			             DB_CR_FLG, LEDGER_NAR, CASHIER_ID,
			             USER_ID, CRE_DT, UPD_DT,
			             DOC_DATE, DUE_DATE, NETTING_DATE,
					 	 NETTING_FLG,RECORD_SOURCE,APPROVED_STS,MANUAL, ARAP_DUE_DATE,BUDGET_CD, FOLDER_CD)
			         VALUES (
			             p_contract_num, 9 , NULL, '100000',
			             '6509',NULL,NULL,
			             rec.curr_cd,rec.brch_cd, ABS(v_selisih), ABS(v_selisih),
			             vdb_cr_flg,'PBLTN '||rec.client_cd||' '||rec.stk_cd||' TR '||TO_CHAR(rec.contr_dt,'dd/mm/yy'), NULL,
			             p_user_id,SYSDATE,NULL,
			             rec.contr_dt, rec.contr_dt, NULL,
					 	 NULL, 'CG', vapprove, v_manual,rec.contr_dt,NULL,v_folder_cd);
					  EXCEPTION
				         WHEN OTHERS THEN
		             v_error_code := -15;
		             v_error_msg :=  SUBSTR('Insert SELISIH T_ACCOUNT_LEDGER : '||p_contract_num||v_nl||SQLERRM,1,200);
		             RAISE v_err;
				         --RAISE_APPLICATION_ERROR(-20100,'insert SELISIH T_ACCOUNT_LEDGER : '||p_contract_num||v_nl||SQLERRM);
				      END;
		*/
						BEGIN
						Gen_Trx_Jur_Line_Nextg( p_contract_num, --p_doc_num
												p_contract_num, --P_DOC_REF_NUM
												rec.contr_dt, --p_date
												rec.contr_dt, --p_due_date
												rec.contr_dt, --p_arap_due_date
												'9', --p_tal_id 
												null, --p_acct_type  
												'6509', --p_gl_acct_cd
												'100000', --p_sl_acct_cd 
												vdb_cr_flg, --p_db_cr_flg 
												ABS(v_selisih), --p_curr_val
												'PBLTN '||rec.client_cd||' '||rec.stk_cd||' TR '||TO_CHAR(rec.contr_dt,'dd/mm/yy'), --p_ledger_nar 
												v_curr_cd, --p_curr_cd
												null, --p_budget_cd  
												rec.brch_cd, 
												v_folder_cd, 
												'CG',
												v_approved_sts, 
												p_user_id,
												v_manual, 
												v_error_code,
												v_error_msg);
					EXCEPTION
					   WHEN OTHERS THEN
                  v_error_code :=  -110;
                  v_error_msg := SUBSTR('insert  T_ACCOUNT_LEDGER : '||p_contract_num||' - '||vgl_acct_cd||' - '||vsl_acct_cd||v_nl||SQLERRM,1,200);
                  RAISE v_err;
					END;
					
					
					IF v_error_code < 0 THEN 
                  v_error_code :=  -115;
                  v_error_msg := SUBSTR('Gen_Trx_Jur_Line_Nextg '||v_error_msg||v_nl||SQLERRM,1,200);
                  RAISE v_err;
					END IF;
				
				  END IF;
		
			   END IF;

	  END LOOP;
-- 			CLOSE CSR;   
--     ELSE
-- 				CLOSE CSR;   
-- 		      v_error_code := -16;
-- 		       v_error_msg :=  SUBSTR('Error Proses Contract Accledger, Cannot find contract number : '||p_contract_num||' '||SQLERRM,1,200);
-- 		       RAISE v_err;
-- 		       --RAISE_APPLICATION_ERROR(-20100,'Error Proses Contract Accledger, Cannot find contract number : '||p_contract_num);
--     END IF; --  IF csr%FOUND THEN
    p_error_code := 1;
    p_error_msg := '';

EXCEPTION
	WHEN v_err THEN
       p_error_code := v_error_code;
	   p_error_msg :=  v_error_msg;
	   ROLLBACK;   
    WHEN OTHERS THEN
       ROLLBACK;
	   p_error_code := -1;
	   p_error_msg := SUBSTR(SQLERRM,1,200);
       RAISE;



END Sp_Contract_Accledgerpp;
