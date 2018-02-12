create or replace PROCEDURE Sp_Bond_Trx_Jur_Nextg(
P_TRX_DATE DATE,
P_TRX_SEQ_NO T_BOND_TRX.TRX_SEQ_NO%TYPE,
P_Jur_date DATE,
P_FOLDER_CD T_FOLDER.FOLDER_CD%TYPE,
P_USER_ID							T_ACCOUNT_LEDGER.USER_ID%TYPE,
P_UPD_STATUS			T_MANY_DETAIL.UPD_STATUS%TYPE,
 p_ip_address			T_MANY_HEADER.IP_ADDRESS%TYPE,
 p_cancel_reason			T_MANY_HEADER.CANCEL_REASON%TYPE,
 p_update_date			T_MANY_HEADER.UPDATE_DATE%TYPE,
 p_update_seq			T_MANY_HEADER.UPDATE_SEQ%TYPE,
 p_record_seq			T_MANY_DETAIL.RECORD_SEQ%TYPE,
 p_error_code					OUT			NUMBER,
p_error_msg					OUT			VARCHAR2)
 IS

/******************************************************************************
   NAME:       SP_BOND_TRX_JUR
   PURPOSE:

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        22/01/2014          1. Created this procedure.

   16jun15 pake Gen_Trx_Jur_Line_Nextg
   1sep14 - bond gl acct dan sl_acct hanya ada 2 macam :
                     government bond dan corporate bond (bond group_cd)
   diambil dari MST GLA TRX

   22oct 14 GET dOCNUM BOND diganti GET CONTR_NUM didlmnya ada CONTR_NUM_SEQ

   NOTES:

******************************************************************************/

CURSOR csr_trx IS
SELECT  t.trx_date, t.trx_type, t.bond_cd, t.trx_id,   t.price, t.cost, t.accrued_int,
                     t.net_amount, t.capital_gain, t.capital_tax, t.capital_tax_pcn,
					 t.accrued_int_tax, t.accrued_tax_pcn,
					 t.buy_price * t.nominal/100 AS  buy_cost, L.lawan, L.LAWAN_type, L.deb_gl_acct,
					 L.cre_gl_acct, L.sl_acct_cd,
					 t.buy_dt,   t.nominal / b.nominal * b.accrued_int AS buy_accrued_int,
					 g.gl_a AS bond_gla, g.sl_A AS bond_sla,
					 t.seller_buy_dt, t.value_dt
FROM T_BOND_TRX T,
( SELECT trx_date, buy_dt, buy_trx_seq, cost, accrued_int, nominal
FROM T_BOND_TRX
WHERE trx_date BETWEEN  (p_trx_date -10) AND  (p_trx_date + 5)
AND trx_type = 'B'
AND approved_sts <> 'C') b,
MST_LAWAN_BOND_TRX L,
 MST_BOND m,
 ( SELECT DECODE(jur_type ,'BONDGOVN', '03','BONDCORP','02') bond_type,
                      gl_a, sl_a
    FROM MST_GLA_TRX
	WHERE jur_type IN ('BONDGOVN','BONDCORP') ) g
WHERE t.trx_date =p_trx_date
AND t.trx_seq_no = p_trx_seq_no
AND  t.buy_dt = b.buy_dt
AND t.buy_trx_seq = b.buy_trx_seq
AND t.approved_sts <> 'C'
AND ( t.journal_status IS NULL OR t.doc_num IS NULL)
AND t.lawan = L.lawan(+)
AND t.bond_cd = m.bond_cd
AND m.bond_group_Cd = g.bond_type;

v_table_name VARCHAR2(50) := 'T_BOND_TRX';

CURSOR csr_many_detail IS
SELECT column_id, column_name AS field_name,
		DECODE(data_type,'VARCHAR2','S','CHAR','S','NUMBER','N','DATE','D','X') AS field_type
FROM all_tab_columns
WHERE table_name = v_table_name
AND OWNER = 'IPNEXTG';

v_many_detail  Types.many_detail_rc;


  v_tal_id NUMBER;
  v_ledger_nar  T_ACCOUNT_LEDGER.Ledger_nar%TYPE;
  v_capital_gain  T_ACCOUNT_LEDGER.curr_val%TYPE;
  v_doc_num T_ACCOUNT_LEDGER.xn_doc_num%TYPE;
  v_db_cr_flg T_ACCOUNT_LEDGER.db_cr_flg%TYPE;
  v_approved_sts T_ACCOUNT_LEDGER.approved_sts%TYPE;
  v_accrued_int T_BOND_TRX.accrued_int%TYPE;
    v_bond_gla T_ACCOUNT_LEDGER.gl_acct_Cd%TYPE;
    v_bond_sla T_ACCOUNT_LEDGER.sl_acct_Cd%TYPE;
    v_sell_accrued_int T_BOND_TRX.accrued_int%TYPE;
  v_buy_accrued_int  T_BOND_TRX.accrued_int%TYPE;
  v_selling_date  DATE;
  v_lawan MST_LAWAN_BOND_TRX.lawan%TYPE;
  v_manual 								T_ACCOUNT_LEDGER.MANUAL%TYPE;
  v_doc_ref_num 	T_ACCOUNT_LEDGER.doc_ref_num%TYPE;
v_docrefnum_flg  									  MST_SYS_PARAM.dflg1%TYPE;
v_jur_cnt											  NUMBER;
v_sum_deb											  T_BOND_TRX.net_amount%TYPE;
 v_sum_cre											  T_BOND_TRX.net_amount%TYPE;
 v_closeprice_cnt        NUMBER;
v_client_gla T_ACCOUNT_LEDGER.gl_acct_Cd%TYPE;
V_CNT NUMBER(5);
V_PEMBULATAN T_ACCOUNT_LEDGER.CURR_VAL%TYPE;
v_db_Cr_fg T_ACCOUNT_LEDGER.db_Cr_flg%TYPE;
 v_err EXCEPTION;
v_error_code NUMBER;
v_error_msg VARCHAR2(200);
v_acct_type T_Account_Ledger.acct_type%type;
V_BRANCH_CODE MST_CLIENT.BRANCH_CODE%TYPE;
BEGIN


  v_approved_sts := 'A';
   v_manual 		:= 'Y';
   v_jur_cnt	:= 0;


   SELECT dflg1 INTO v_docrefnum_flg
   FROM MST_SYS_PARAM
   WHERE param_id = 'SYSTEM'
   AND param_cd1 = 'DOC_REF';

   v_doc_ref_num := NULL;

   FOR rec IN csr_trx LOOP

   	   	   IF rec.sl_acct_cd IS NULL THEN
		   	  				 v_error_code := -2001;
							 v_error_msg := SUBSTR('GL sub acct  '||rec.lawan||' belum diinput ',1,200);
							RAISE v_err;
		   END IF;

       BEGIN
        SELECT COUNT(*) INTO v_closeprice_cnt FROM T_BOND_PRICE WHERE price_dt = p_trx_date AND bond_cd = rec.bond_cd;
      EXCEPTION
      WHEN OTHERS THEN
          v_error_code := -33;
          v_error_msg := SUBSTR('Retrieve closing price '||rec.bond_cd||' '||SQLERRM,1,200);
          RAISE v_err;
     END;

     IF v_closeprice_cnt < 1 THEN
        v_error_code := -2002;
        v_error_msg := 'Closing price for '||rec.bond_cd||' is not found!';
        RAISE v_err;
     END IF;


       v_tal_id := 0;
   	   IF rec.trx_type = 'B' THEN
--21oct	   	  		v_doc_num := Get_Docnum_Bond(P_Jur_date, 'B'  );
	   	  		v_doc_num := Get_Contr_Num(P_Jur_date, 'BUY','BOND'  );

				IF v_docrefnum_flg = 'Y' THEN
							   v_doc_ref_num := v_doc_num;
				ELSE
								v_doc_ref_num := NULL;
				END IF;

	           v_tal_id := v_tal_id + 1;
			   IF  rec.lawan_type = 'I' THEN

			   	   				  v_lawan :=rec.sl_acct_cd;
				ELSE
			   						  v_lawan := rec.lawan;
				END IF;
			   v_ledger_nar := 'Tr '||TO_CHAR(rec.trx_date,'dd/mm/yy')||' Buy '||rec.bond_cd||' from '||v_lawan||' - '||rec.trx_id;

                --1350
						BEGIN --sdh
						Gen_Trx_Jur_Line_Nextg(
					   v_doc_num,
					   v_doc_ref_num,
				 	   p_jur_date,
				 	   p_jur_date,
				 	   p_jur_date,
					   v_tal_id,
					   NULL, --v_acct_type
					   rec.bond_gla,
					   rec.bond_sla,
					   'D',
					   rec.cost,
					   v_ledger_nar,
					   'IDR',
					   'BONDTRANS',--p_budget_cd
					   NULL,--p_brch_cd
				 	   NULL, --p_folder_cd
					   'CG',--p_record_source
				   	   v_approved_sts,
					   p_user_id,
					   v_manual,
					   v_error_code,
					   v_error_msg);
						EXCEPTION
						  WHEN OTHERS THEN
						  	   		   v_error_code := -2;
										v_error_msg := SUBSTR('Gen_trx_Gljur_Line, error: '||TO_CHAR(v_error_code)||SQLERRM,1,200);
										RAISE v_err;
						  END;
						IF 		v_error_code < 0 THEN
								   v_error_code := -3;
									RAISE v_err;
						END IF;

	/*	 4NOV11       BEGIN
		        SELECT trx_date AS selling_date, accrued_int
				                  INTO v_selling_date, v_sell_accrued_int
				FROM T_BOND_TRX
				WHERE trx_date BETWEEN  p_trx_date AND  p_trx_date + 5
				AND trx_type = 'S'
				AND approved_sts = 'A'
				AND buy_dt = p_trx_date
				AND buy_trx_seq = p_trx_seq_no;
				EXCEPTION
				WHEN NO_DATA_FOUND THEN
					 			   v_selling_date := p_trx_date + 1;
								   v_sell_accrued_int := 0;
-- 					 			 v_error_code := -4;
-- 								v_error_msg := 'SELL Bond transaction not found in T_Bond_trx';
-- 								RAISE v_err;
				WHEN OTHERS THEN
				 				v_error_code := -4;
								v_error_msg := SUBSTR('Retrieve T_BOND_TRX '||SQLERRM,1,200);
								RAISE v_err;
				END;*/


				v_tal_id := v_tal_id + 1;


			   BEGIN  --sdh
						Gen_Trx_Jur_Line_Nextg(
					   v_doc_num,
					   v_doc_ref_num,
				 	   p_jur_date,
				 	   p_jur_date,
				 	   p_jur_date,
					   v_tal_id,
					   NULL, --v_acct_type
					   '1516',
					   '000000',
					   'D',
					   rec.accrued_int,
					   v_ledger_nar,
					   'IDR',
					   'BONDTRANS',--p_budget_cd
					   NULL,--p_brch_cd
				 	   NULL, --p_folder_cd
					   'CG',--p_record_source
				   	   v_approved_sts,
					   p_user_id,
					   v_manual,
					   v_error_code,
					   v_error_msg);
						EXCEPTION
						  WHEN OTHERS THEN
						  	   		   v_error_code := -5;
										v_error_msg := SUBSTR('Gen_trx_Gljur_Line '||TO_CHAR(v_error_code)||SQLERRM,1,200);
										RAISE v_err;
						  END;
						IF 		v_error_code < 0 THEN
								   v_error_code := -6;
									RAISE v_err;
						END IF;

			   IF rec.capital_tax <> 0 THEN
   	  				   v_tal_id := v_tal_id + 1;
					     IF rec.capital_tax > 0 THEN
					   	 					v_db_cr_flg := 'C';
						ELSE
											v_db_cr_flg := 'D';
						END IF;


					   BEGIN --sdh
								Gen_Trx_Jur_Line_Nextg(
							   v_doc_num,
							   v_doc_ref_num,
						 	   p_jur_date,
						 	   p_jur_date,
						 	   p_jur_date,
							   v_tal_id,
							   NULL, --v_acct_type
							   '2527',
							   '000000',
							  v_db_cr_flg,
							   rec.capital_tax,
							   v_ledger_nar,
							   'IDR',
							   'BONDTRANS',--p_budget_cd
							   NULL,--p_brch_cd
						 	   NULL, --p_folder_cd
							   'CG',--p_record_source
						   	   v_approved_sts,
							   p_user_id,
							   v_manual,
							   v_error_code,
							   v_error_msg);
								EXCEPTION
										  WHEN OTHERS THEN
										  	   		   v_error_code := -7;
														v_error_msg := SUBSTR('Gen_trx_Gljur_Line '||TO_CHAR(v_error_code)||SQLERRM,1,200);
														RAISE v_err;
										  END;
								IF 		v_error_code < 0 THEN
										   v_error_code := -8;
											RAISE v_err;
								END IF;


			   END IF;

			   IF rec.accrued_int_tax > 0 THEN

			   			   v_tal_id := v_tal_id + 1;


					   BEGIN --sdh
								Gen_Trx_Jur_Line_Nextg(
							   v_doc_num,
							   v_doc_ref_num,
						 	   p_jur_date,
						 	   p_jur_date,
						 	   p_jur_date,
							   v_tal_id,
							   NULL, --v_acct_type
							   '2527',
							   '000000',
							  'C',
							    rec.accrued_int_tax,
							   v_ledger_nar,
							   'IDR',
							   'BONDTRANS',--p_budget_cd
							   NULL,--p_brch_cd
						 	   NULL, --p_folder_cd
							   'CG',--p_record_source
						   	   v_approved_sts,
							   p_user_id,
							   v_manual,
							   v_error_code,
							   v_error_msg);
								EXCEPTION
										  WHEN OTHERS THEN
										  	   		   v_error_code := -9;
														v_error_msg := SUBSTR('Gen_trx_Gljur_Line '||TO_CHAR(v_error_code)||SQLERRM,1,200);
														RAISE v_err;
										  END;
								IF 		v_error_code < 0 THEN
										   v_error_code := -10;
											RAISE v_err;
								END IF;


			   END IF;


		        v_tal_id := v_tal_id + 1;


		   		BEGIN  --sdh
						Gen_Trx_Jur_Line_Nextg(
					   v_doc_num,
					   v_doc_num,
				 	   p_jur_date,
					   rec.value_dt,
					    rec.value_dt,
					   v_tal_id,
					   NULL, --v_acct_type
					   rec.cre_gl_acct,
					   rec.sl_acct_cd,
					  'C',
					    rec.net_amount,
					   v_ledger_nar,
					   'IDR',
					   'BONDTRANS',--p_budget_cd
					   NULL,--p_brch_cd
				 	   NULL, --p_folder_cd
					   'CG',--p_record_source
				   	   v_approved_sts,
					   p_user_id,
					   v_manual,
					   v_error_code,
					   v_error_msg);
						EXCEPTION
						  WHEN OTHERS THEN
						  	   		   v_error_code := -11;
										v_error_msg := SUBSTR('Gen_trx_Gljur_Line '||TO_CHAR(v_error_code)||SQLERRM,1,200);
										RAISE v_err;
						  END;
						IF 		v_error_code < 0 THEN
								   v_error_code := -12;
									RAISE v_err;
						END IF;


-- update DUE DATE dikomen 18jun krn sudah pake Gen_Trx_Jur_Line_nextg
--    		  	  	  		BEGIN
--    		  	  	  				  UPDATE T_ACCOUNT_LEDGER
-- 								  SET due_date = rec.value_dt,
-- 								            doc_ref_num = v_doc_num
-- 								  WHERE xn_doc_num = v_doc_num
-- 								  AND tal_id = v_tal_id;
-- 						EXCEPTION
-- 								  WHEN OTHERS THEN
-- 								  	   		   v_error_code := -13;
-- 												v_error_msg := SUBSTR('UPDATE due date on T_A_L '||TO_CHAR(v_error_code)||SQLERRM,1,200);
-- 												RAISE v_err;
-- 								  END;
		END IF;

--========================================================================================================

		IF rec.trx_type = 'S' THEN
--22oct		       v_doc_num := Get_Docnum_Bond(P_Jur_date, 'J'  );
				v_doc_num := Get_Contr_Num(P_Jur_date, 'SELL','BOND'  );

				IF v_docrefnum_flg = 'Y' THEN
							   v_doc_ref_num := v_doc_num;
				ELSE
								v_doc_ref_num := NULL;
				END IF;

	           v_tal_id := v_tal_id + 1;
			     IF  rec.lawan_type = 'I' THEN
			   	   				  v_lawan :=rec.sl_acct_cd;
				ELSE
			   					v_lawan := rec.lawan;
				END IF;
			   v_ledger_nar := 'Tr '||TO_CHAR(rec.trx_date,'dd/mm/yy')||' Sell '||rec.bond_cd||' to '||v_lawan||' - '||rec.trx_id;


				BEGIN --sdh
						Gen_Trx_Jur_Line_Nextg(
					   v_doc_num,
					   v_doc_num,
				 	   p_jur_date,
					   rec.value_dt,
					    rec.value_dt,
					   v_tal_id,
					   NULL, --v_acct_type
					   rec.Deb_gl_acct,
					   rec.sl_acct_Cd,
					   'D',
					    rec.net_amount,
					   v_ledger_nar,
					   'IDR',
					   'BONDTRANS',--p_budget_cd
					   NULL,--p_brch_cd
				 	   NULL, --p_folder_cd
					   'CG',--p_record_source
				   	   v_approved_sts,
					   p_user_id,
					   v_manual,
					   v_error_code,
					   v_error_msg);
						EXCEPTION
						  WHEN OTHERS THEN
						  	   		   v_error_code := -12;
										v_error_msg := SUBSTR('Gen_trx_Gljur_Line '||TO_CHAR(v_error_code)||SQLERRM,1,200);
										RAISE v_err;
						  END;
						IF 		v_error_code < 0 THEN
								   v_error_code := -14;
									RAISE v_err;
						END IF;

-- update DUE DATE - DI KOMEN krn sudah pake Gen_Trx_Jur_Line_nextg
--    		  	  	  		BEGIN
--    		  	  	  				  UPDATE T_ACCOUNT_LEDGER
-- 								  SET due_date = rec.value_dt
-- 								  WHERE xn_doc_num = v_doc_num
-- 								  AND tal_id = v_tal_id;
-- 						EXCEPTION
-- 								  WHEN OTHERS THEN
-- 								  	   		   v_error_code := -15;
-- 												v_error_msg := SUBSTR('UPDATE due date on T_A_L '||TO_CHAR(v_error_code)||SQLERRM,1,200);
-- 												RAISE v_err;
-- 								  END;
				 v_tal_id := v_tal_id + 1;


						BEGIN  --sdh
						Gen_Trx_Jur_Line_Nextg(
					   v_doc_num,
					   v_doc_ref_num,
				 	   p_jur_date,
				 	   p_jur_date,
				 	   p_jur_date,
					   v_tal_id,
					   NULL, --v_acct_type
					   rec.bond_gla,
					   rec.bond_sla,
					   'C',
					    rec.buy_cost,
					   v_ledger_nar,
					   'IDR',
					   'BONDTRANS',--p_budget_cd
					   NULL,--p_brch_cd
				 	   NULL, --p_folder_cd
					   'CG',--p_record_source
				   	   v_approved_sts,
					   p_user_id,
					   v_manual,
					   v_error_code,
					   v_error_msg);
						EXCEPTION
						  WHEN OTHERS THEN
						  	   		   v_error_code := -15;
										v_error_msg := SUBSTR('Gen_trx_Gljur_Line '||TO_CHAR(v_error_code)||SQLERRM,1,200);
										RAISE v_err;
						  END;
						IF 		v_error_code < 0 THEN
								   v_error_code := -16;
									RAISE v_err;
						END IF;

			   	  --v_capital_gain := rec.cost - rec.buy_cost;
				  IF rec.capital_gain <> 0 THEN

							 IF rec.capital_gain > 0 THEN
												v_db_cr_flg := 'C';
							ELSE
												v_db_cr_flg := 'D';
							END IF;

			   	  				   v_tal_id := v_tal_id + 1;
-- 								   BEGIN
-- 								 Gen_Gljur_Line(  p_jur_date,   p_folder_cd, v_tal_id,
-- 							   '6150',   '900001',   v_db_cr_flg,   ABS( rec.capital_gain - rec.capital_tax),
-- 							      v_ledger_nar,   p_user_id);
-- 								  EXCEPTION
-- 				  				  WHEN OTHERS THEN
-- 				  	   		   v_error_code := -12;
-- 								v_error_msg := SUBSTR('Gen_Gljur_Line '||SQLERRM,1,200);
-- 								RAISE v_err;
-- 				  				END;
						BEGIN --sdh
								Gen_Trx_Jur_Line_Nextg(
							   v_doc_num,
							   v_doc_ref_num,
						 	   p_jur_date,
							   p_jur_date,
							   p_jur_date,
							   v_tal_id,
							   NULL, --v_acct_type
							   '6150',
							   '900001',
							    v_db_cr_flg,
							    ABS( rec.capital_gain - rec.capital_tax),
							   v_ledger_nar,
							   'IDR',
							   'BONDTRANS',--p_budget_cd
							   NULL,--p_brch_cd
						 	   NULL, --p_folder_cd
							   'CG',--p_record_source
						   	   v_approved_sts,
							   p_user_id,
							   v_manual,
							   v_error_code,
							   v_error_msg);
								EXCEPTION
								  WHEN OTHERS THEN
								  	   		   v_error_code := -17;
												v_error_msg := SUBSTR('Gen_trx_Gljur_Line '||TO_CHAR(v_error_code)||SQLERRM,1,200);
												RAISE v_err;
								  END;
								IF 		v_error_code < 0 THEN
										   v_error_code := -18;
											RAISE v_err;
								END IF;


						IF  rec.lawan_type = 'I' THEN
								v_tal_id := v_tal_id + 1;
								v_client_gla := F_GL_ACCT_T3_JAN2016(rec.sl_acct_Cd,'D');

							BEGIN
							SELECT ACCT_TYPE INTO v_acct_type FROM MST_GL_ACCOUNT WHERE APPROVED_STAT='A' AND TRIM(GL_A)=TRIM(v_client_gla) AND SL_A=rec.sl_acct_Cd;
							EXCEPTION
							WHEN OTHERS THEN
								v_error_code :=-2009;
								v_error_msg :=SUBSTR('SELECT ACCT TYPE FROM MST_GL_ACCOUNT '||rec.sl_acct_Cd||' '||v_client_gla||SQLERRM,1,200);
								RAISE v_err;
							END;

							BEGIN
							SELECT BRANCH_CODE INTO V_BRANCH_CODE FROM MST_CLIENT WHERE APPROVED_STAT='A' AND CLIENT_CD=rec.sl_acct_Cd;
							EXCEPTION
							WHEN OTHERS THEN
								v_error_code :=-2010;
								v_error_msg :=SUBSTR('SELECT ACCT TYPE FROM MST_GL_ACCOUNT '||rec.sl_acct_Cd||SQLERRM,1,200);
								RAISE v_err;
							END;

										BEGIN--sdh
										Gen_Trx_Jur_Line_Nextg(
									   v_doc_num,
									   v_doc_ref_num,
								 	   p_jur_date,
									   rec.value_dt,
									   rec.value_dt,
									   v_tal_id,
									   TRIM(v_acct_type), --v_acct_type
									   v_client_gla,--'1424',
									   rec.sl_acct_Cd,
									   'D',
									    ABS( rec.capital_tax),
									   v_ledger_nar,
									   'IDR',
									   'BONDTRANS',--p_budget_cd
									   TRIM(V_BRANCH_CODE),--p_brch_cd
								 	   NULL, --p_folder_cd
									   'CG',--p_record_source
								   	   v_approved_sts,
									   p_user_id,
									   v_manual,
									   v_error_code,
									   v_error_msg);
										EXCEPTION
										  WHEN OTHERS THEN
										  	   		   v_error_code := -19;
														v_error_msg := SUBSTR('Gen_trx_Gljur_Line '||TO_CHAR(v_error_code)||SQLERRM,1,200);
														RAISE v_err;
										  END;
										IF 		v_error_code < 0 THEN
												   v_error_code := -20;
													RAISE v_err;
										END IF;

-- dikomen 18jun
-- 										BEGIN
--    		  	  	  				  UPDATE T_ACCOUNT_LEDGER
-- 								  SET doc_ref_num = v_doc_num
-- 								  WHERE xn_doc_num = v_doc_num
-- 								  AND tal_id = v_tal_id;
-- 						EXCEPTION
-- 								  WHEN OTHERS THEN
-- 								  	   		   v_error_code := -21;
-- 												v_error_msg := SUBSTR('UPDATE doc_ref_num on T_A_L '||TO_CHAR(v_error_code)||SQLERRM,1,200);
-- 												RAISE v_err;
-- 								  END;


			   	  				   v_tal_id := v_tal_id + 1;
										BEGIN--sdh
										Gen_Trx_Jur_Line_Nextg(
									   v_doc_num,
									   v_doc_ref_num,
								 	   p_jur_date,
								 	   p_jur_date,
								 	   p_jur_date,
									   v_tal_id,
									   NULL, --v_acct_type
									   '2527',
									   '000000',
									   'C',
									    ABS( rec.capital_tax),
									   v_ledger_nar,
									   'IDR',
									   'BONDTRANS',--p_budget_cd
									   NULL,--p_brch_cd
								 	   NULL, --p_folder_cd
									   'CG',--p_record_source
								   	   v_approved_sts,
									   p_user_id,
									   v_manual,
									   v_error_code,
									   v_error_msg);
										EXCEPTION
									  WHEN OTHERS THEN
									  	   		   v_error_code := -21;
													v_error_msg := SUBSTR('Gen_trx_Gljur_Line '||TO_CHAR(v_error_code)||SQLERRM,1,200);
													RAISE v_err;
									  END;
										IF 		v_error_code < 0 THEN
												   v_error_code := -22;
													RAISE v_err;
										END IF;
						END IF;
			   END IF;

		         v_tal_id := v_tal_id + 1;
				 IF rec.accrued_int_tax = 0 THEN
						BEGIN  --sdh
						Gen_Trx_Jur_Line_Nextg(
					   v_doc_num,
					   v_doc_ref_num,
				 	   p_jur_date,
				 	   p_jur_date,
				 	   p_jur_date,
					   v_tal_id,
					   NULL, --v_acct_type
					   '1516',
					   '000000',
					    'C',
					    rec.accrued_int,
					   v_ledger_nar,
					   'IDR',
					   'BONDTRANS',--p_budget_cd
					   NULL,--p_brch_cd
				 	   NULL, --p_folder_cd
					   'CG',--p_record_source
				   	   v_approved_sts,
					   p_user_id,
					   v_manual,
					   v_error_code,
					   v_error_msg);
						EXCEPTION
					  WHEN OTHERS THEN
					  	   		   v_error_code := -23;
									v_error_msg := SUBSTR('Gen_trx_Gljur_Line '||TO_CHAR(v_error_code)||SQLERRM,1,200);
									RAISE v_err;
					  END;
						IF 		v_error_code < 0 THEN
								   v_error_code := -24;
									RAISE v_err;
						END IF;

				ELSE
							  -- ada 1490 krn dijual ditgl yg berbeda
-- 							  BEGIN
-- 							  Gen_Gljur_Line(  p_jur_date,   p_folder_cd, v_tal_id,
-- 						   '1516',   '000000',   'C',   rec.buy_accrued_int,
-- 						      v_ledger_nar,   p_user_id);
-- 							  EXCEPTION
-- 				  			  WHEN OTHERS THEN
-- 				  	   		   v_error_code := -14;
-- 								v_error_msg := SUBSTR('Gen_Gljur_Line '||SQLERRM,1,200);
-- 								RAISE v_err;
-- 				  				END;

 --27nov kmungkinan dijual sebagian dr nominal beli, jadi buy accrued int hrs di prorate

						BEGIN --sdh
								Gen_Trx_Jur_Line_Nextg(
							   v_doc_num,
							   v_doc_ref_num,
						 	   p_jur_date,
						 	   p_jur_date,
						 	   p_jur_date,
							   v_tal_id,
							   NULL, --v_acct_type
							   '1516',
							   '000000',
							    'C',
							     rec.buy_accrued_int,
							   v_ledger_nar,
							   'IDR',
							   'BONDTRANS',--p_budget_cd
							   NULL,--p_brch_cd
						 	   NULL, --p_folder_cd
							   'CG',--p_record_source
						   	   v_approved_sts,
							   p_user_id,
							   v_manual,
							   v_error_code,
							   v_error_msg);
						EXCEPTION
					  WHEN OTHERS THEN
					  	   		   v_error_code := -25;
									v_error_msg := SUBSTR('Gen_trx_Gljur_Line '||TO_CHAR(v_error_code)||SQLERRM,1,200);
									RAISE v_err;
					  END;
						IF 		v_error_code < 0 THEN
								   v_error_code := -26;
									RAISE v_err;
						END IF;


							   v_tal_id := v_tal_id + 1;
--		8sep14					  v_accrued_int := (1 - rec.accrued_tax_pcn) / rec.accrued_tax_pcn * rec.accrued_int_tax;
                              v_accrued_int :=    rec.accrued_int - rec.buy_accrued_int - rec.accrued_int_tax;

						BEGIN --sdh
								Gen_Trx_Jur_Line_Nextg(
							   v_doc_num,
							   v_doc_ref_num,
						 	   p_jur_date,
						 	   p_jur_date,
						 	   p_jur_date,
							   v_tal_id,
							   NULL, --v_acct_type
							   '6508',
							   '000000',
							    'C',
							     v_accrued_int,
							   v_ledger_nar,
							   'IDR',
							   'BONDTRANS',--p_budget_cd
							   NULL,--p_brch_cd
						 	   NULL, --p_folder_cd
							   'CG',--p_record_source
						   	   v_approved_sts,
							   p_user_id,
							   v_manual,
							   v_error_code,
							   v_error_msg);
						EXCEPTION
						  WHEN OTHERS THEN
						  	   		   v_error_code := -27;
										v_error_msg := SUBSTR('Gen_trx_Gljur_Line '||TO_CHAR(v_error_code)||SQLERRM,1,200);
										RAISE v_err;
						  END;
						IF 		v_error_code < 0 THEN
								   v_error_code := -28;
									RAISE v_err;
						END IF;

				END IF;


		END IF;


		BEGIN
		UPDATE T_BOND_TRX
		SET DOC_NUM = V_doc_num,
		          journal_status = 'A'
		WHERE  trx_date = p_trx_date
		AND trx_seq_no = p_trx_seq_no;
		EXCEPTION
				  WHEN OTHERS THEN
				  	   		   v_error_code := -29;
								v_error_msg := SUBSTR('Upd T_BoND_TRX '||SQLERRM,1,200);
								RAISE v_err;
				  END;

		BEGIN
		SELECT SUM(DECODE(db_cr_flg,'D',curr_val,0)) sum_deb,
				           SUM(DECODE(db_cr_flg,'C',curr_val,0)) sum_cre
						   INTO v_sum_deb, v_sum_cre
		FROM T_ACCOUNT_LEDGER
		WHERE xn_doc_num =  V_doc_num;
		EXCEPTION
		  WHEN OTHERS THEN
		  	   		   v_error_code := -31;
						v_error_msg := SUBSTR('Select T_A_L '||SQLERRM,1,200);
						RAISE v_err;
		  END;

  	
            
    IF 	v_sum_deb <>  v_sum_cre THEN
        --[INDRA]19JAN2018
        BEGIN
        SELECT COUNT(1), TRIM(max(db_cr_flg)) INTO V_CNT,v_db_Cr_flg FROM T_ACCOUNT_LEDGER WHERE TRIM(GL_ACCT_CD)='6150' AND XN_DOC_NUM =V_doc_num;
        EXCEPTION
        WHEN OTHERS THEN
          v_error_code := -2001;
					v_error_msg := SUBSTR('Cek jurnal pembulatan dari T_Account_Ledger '||SQLERRM,1,200);
					RAISE v_err;
        END;
       
        
        IF V_CNT>0  AND ABS(v_sum_deb-v_sum_cre)<=1 THEN
        
          IF v_db_Cr_flg = 'D' AND   v_sum_deb >v_sum_cre THEN
              V_PEMBULATAN := -ABS(v_sum_deb-v_sum_cre);
          ELSIF  v_db_Cr_flg = 'D' AND   v_sum_deb <v_sum_cre THEN
              V_PEMBULATAN := ABS(v_sum_deb-v_sum_cre);
          ELSIF  v_db_Cr_flg = 'C' AND   v_sum_deb >v_sum_cre THEN
              V_PEMBULATAN := ABS(v_sum_deb-v_sum_cre);
          ELSIF  v_db_Cr_flg = 'C' AND   v_sum_deb <v_sum_cre THEN
              V_PEMBULATAN := -ABS(v_sum_deb-v_sum_cre);
          END IF;
          
          
          BEGIN
            UPDATE T_ACCOUNT_LEDGER SET CURR_VAL=CURR_VAL+V_PEMBULATAN WHERE 
              TRIM(GL_ACCT_CD)='6150' AND XN_DOC_NUM =V_doc_num;
          EXCEPTION
          WHEN OTHERS THEN
            v_error_code := -2005;
            v_error_msg := SUBSTR('UPDATE T_ACCOUNT_LEDGER SET CURR_VAL=CURR_VAL+v_sum_cre-v_sum_deb '||SQLERRM,1,200);
            RAISE v_err;
          END;
        
        ELSE
        --JIKA SELISIH LEBIH DARI 1
             v_error_code := -32;
            v_error_msg := 'Journal tidak balance,  '||rec.trx_type||' '||rec.bond_cd||' No. '||TO_CHAR(rec.trx_id)||' '||rec.lawan||' @ '||TO_CHAR(rec.price)||
                            ' '||v_doc_num||' deb '||v_sum_deb||' cre '||v_sum_cre;
						RAISE v_err;
        
        END IF;
      --END [INDRA]19JAN2018
      
         
		  END IF;

          v_jur_cnt := v_jur_cnt + 1;

	/*	UPDATE T_ACCOUNT_LEDGER
		SET  xn_doc_num = SUBSTR(v_doc_num,1,6)||'C'||SUBSTR(v_doc_num,8,7),
		approved_sts = 'C'
		WHERE xn_doc_num = 	    v_doc_num;*/



		--COMMIT;
    BEGIN
      UPDATE T_BOND_TRX SET upd_dt = SYSDATE, upd_by = P_USER_ID WHERE
      trx_date = p_trx_date AND trx_seq_no = p_trx_seq_no;
    EXCEPTION
      WHEN OTHERS THEN
      v_error_code := -34;
      v_error_msg := SUBSTR('Update T_BOND_TRX '||SQLERRM,1,200);
    END;

   END LOOP;

   OPEN v_many_detail FOR
    SELECT p_update_date AS update_date, p_update_seq AS update_seq, table_name, p_record_seq AS record_seq, NULL AS table_rowid, a.field_name, field_type, b.field_value, p_upd_status AS status,  b.upd_flg
      FROM(
     SELECT  SYSDATE AS  update_date, v_table_name AS table_name, column_id, column_name AS field_name,
                                    DECODE(data_type,'VARCHAR2','S','CHAR','S','NUMBER','N','DATE','D','X') AS field_type
                    FROM all_tab_columns
                    WHERE table_name = v_table_name
                    AND OWNER = 'IPNEXTG') a,
    (
          SELECT  'TRX_DATE'  AS field_name, TO_CHAR(P_TRX_DATE,'yyyy/mm/dd hh24:mi:ss')  AS field_value, 'N' upd_flg FROM dual
          UNION
          SELECT  'TRX_SEQ_NO'  AS field_name, TO_CHAR(P_TRX_SEQ_NO) AS field_value, 'N' upd_flg FROM dual
         ) b
     WHERE a.field_name = b.field_name;

    BEGIN
    Sp_T_Many_Detail_Insert(p_update_date,   p_update_seq,   P_UPD_STATUS , v_table_name, p_record_seq , NULL, v_MANY_DETAIL, v_error_code, v_error_msg);
    EXCEPTION
    WHEN OTHERS THEN
         v_error_code := -39;
          v_error_msg := SUBSTR('SP_T_MANY_DETAIL_INSERT '||v_table_name||SQLERRM,1,200);
          RAISE v_err;
    END;

      CLOSE v_many_detail;

   IF v_jur_cnt = 0 THEN
   	  			 v_error_code := -40;
				 v_error_msg := 'NO Journal generated';
				RAISE v_err;
   END IF;

   P_error_code:= 1;
	P_error_msg := '';
   EXCEPTION
     WHEN v_err THEN
	        P_error_code := v_error_code;
				P_error_msg := v_error_msg;
				ROLLBACK;

     WHEN NO_DATA_FOUND THEN
       NULL;
     WHEN OTHERS THEN
       -- Consider logging the error and then re-raise
	   ROLLBACK;

	   P_error_code := -1;
	   P_error_msg :=  SUBSTR(SQLERRM,1,200);
       RAISE;
END Sp_Bond_Trx_Jur_Nextg;