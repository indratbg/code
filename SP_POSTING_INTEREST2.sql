create or replace 
PROCEDURE Sp_Posting_Interest(p_date IN DATE,
                              p_bgn_client IN T_INTEREST.client_cd%TYPE,
                              p_end_client IN T_INTEREST.client_cd%TYPE,
                              p_bgn_date   IN T_INTEREST.int_dt%TYPE,
                              p_end_date   IN T_INTEREST.int_dt%TYPE,
                          	  p_brch_cd IN MST_CLIENT.branch_code%TYPE,
                              p_user_id   IN  T_INTEREST.user_id%TYPE,
                              P_IP_ADDRESS T_MANY_HEADER.IP_ADDRESS%TYPE,
                              P_ERROR_CD OUT NUMBER,
                              P_ERROR_MSG OUT VARCHAR2)
IS

-- 17mar11 acct 6504 diganti 6509 per cabang

  -- Ambil interest yang belum diposting
  --------------------------------------
  CURSOR l_csr(a_bgn_client T_INTEREST.client_cd%TYPE, a_end_client T_INTEREST.client_cd%TYPE)
  IS SELECT t.client_cd, NVL(m.amt_int_flg,'Y') amt_int_flg, m.client_type_1, m.client_type_2,
     m.client_type_3, m.branch_code, NVL(m.RECOV_CHARGE_FLG,'N') RECOV_CHARGE_FLG, 
     NVL(m.tax_on_interest,'N') tax_on_interest, t.sum_int,T.SUM_DEB,T.SUM_CRE,m.old_ic_num
     From( Select Client_Cd, Sum( Int_Amt) Sum_Int,
	      SUM(DECODE(int_flg,'D',int_amt,0)) sum_deb, SUM(DECODE(int_flg,'D',0,int_amt)) sum_cre
           FROM T_INTEREST
           WHERE POST_FLG  = 'N'
           AND client_cd BETWEEN a_bgn_client AND a_end_client
           AND int_dt BETWEEN p_bgn_date AND p_end_date
           GROUP BY client_cd) t,
		 ( Select Client_Cd, Amt_Int_Flg, Client_Type_1, Client_Type_2, 
		          Client_Type_3, Branch_Code, Tax_On_Interest, 
              NVL(RECOV_CHARGE_FLG,'N') RECOV_CHARGE_FLG,old_ic_num
		   FROM MST_CLIENT
		   WHERE ((client_type_3 = 'D'  AND p_bgn_client = 'D') OR
           		(client_type_3 <> 'D' AND p_bgn_client = '%' ) OR
         		  (p_bgn_client <> 'D' AND p_bgn_client <> '%' )) 
					AND	 branch_code LIKE '%'||p_brch_cd||'%'	  
				  ) m
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
v_flg CHAR(1):='N';

--VOUCHER
V_PAYREC_NUM T_PAYRECH.PAYREC_NUM%TYPE;
V_PAYREC_TYPE T_PAYRECH.PAYREC_TYPE%TYPE;
V_PAYREC_DATE T_PAYRECH.PAYREC_DATE%TYPE;
V_DOC_REF CHAR(1);
V_DOC_REF_NUM T_ACCOUNT_LEDGER.XN_DOC_NUM%TYPE;
V_ACCT_TYPE MST_GL_ACCOUNT.ACCT_TYPE%TYPE;
V_ACCT_MARGIN T_ACCOUNT_LEDGER.GL_ACCT_CD%TYPE;
V_ACCT_REGULAR T_ACCOUNT_LEDGER.GL_ACCT_CD%TYPE;
V_GL_A_RECOV_Y T_ACCOUNT_LEDGER.GL_ACCT_CD%TYPE;
V_Gl_A_Recov_N T_Account_Ledger.Gl_Acct_Cd%Type;
V_Kode_Ab Mst_Parameter.Prm_Desc%Type;
V_UANG_MUKA VARCHAR2(1);
V_CEK_FOLDER VARCHAR2(1);
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
	
	
	BEGIN
		SELECT DFLG1 INTO V_DOC_REF FROM MST_SYS_PARAM WHERE param_id = 'SYSTEM' AND param_cd1 = 'DOC_REF';
	EXCEPTION
		WHEN OTHERS THEN
			V_ERROR_CD := -4;
			V_ERROR_MSG := SUBSTR('SELECT DOC_REF FROM MST_SYS_PARAM '|| SQLERRM(SQLCODE),1,200);
			RAISE V_ERR;
	END;
	/*
		--GET GL_ACCT_CD
		BEGIN
			SELECT DSTR1,DSTR2 INTO V_ACCT_MARGIN, V_ACCT_REGULAR
				FROM MST_SYS_PARAM WHERE PARAM_ID='POSTING INTEREST' AND PARAM_CD1='GL_ACCT' AND PARAM_CD2='CL_TYPE3'; 
		EXCEPTION
		WHEN OTHERS THEN
			 V_ERROR_CD := -5;
			 V_ERROR_MSG := SUBSTR('SELECT GL_ACCT_CD FROM MST_SYS_PARAM '|| SQLERRM(SQLCODE),1,200);
		RAISE V_ERR;
		END;
*/
	Begin
		Select Prm_Desc into V_Kode_Ab From Mst_Parameter Where Prm_Cd_1 = 'AB' And Prm_Cd_2='000' And Approved_Stat='A';
	EXCEPTION
		WHEN OTHERS THEN
			V_Error_Cd := -5;
			V_ERROR_MSG := SUBSTR('SELECT KODE AB FROM Mst_Parameter '|| SQLERRM(SQLCODE),1,200);
			Raise V_Err;
	END;
    
	BEGIN
		Select DFLG1 INTO V_UANG_MUKA From Mst_Sys_Param Where Param_Id='POSTING INTEREST' AND PARAM_CD1='PPH23';
	EXCEPTION
		WHEN OTHERS THEN
			V_Error_Cd := -6;
			V_ERROR_MSG := SUBSTR('SELECT V_PPH23 FROM Mst_Sys_Param '|| SQLERRM(SQLCODE),1,200);
			Raise V_Err;
	END;	
	
	BEGIN
		Select DFLG1 INTO V_CEK_FOLDER From Mst_Sys_Param Where  Param_Id='SYSTEM' And Param_Cd1='VCH_REF';
	EXCEPTION
		WHEN OTHERS THEN
			V_Error_Cd := -7;
			V_ERROR_MSG := SUBSTR('SELECT USING FILE NO. FROM Mst_Sys_Param '|| SQLERRM(SQLCODE),1,200);
			Raise V_Err;
	END;	
	
	OPEN l_csr(v_bgn_client, v_end_client);
	LOOP
		FETCH l_csr INTO v_rec;
		EXIT WHEN l_csr%NOTFOUND;
		
		IF (v_rec.sum_int <> 0  AND NVL(v_rec.amt_int_flg,'Y') = 'Y') OR (v_rec.sum_int <> 0  AND V_Kode_Ab <> 'YJ001' ) THEN

			--  generate PAYRECH
			v_tal_id 		:= 0;
			v_client_cd  := trim(v_rec.client_cd);
			
				-- mulai 27feb2013 end 	
				/*
				If V_Rec.Client_Type_3 = 'M' Then
  					V_Gl_Acct_Cd := V_Acct_Margin;--'1422';
				ELSE
							v_gl_acct_cd := V_ACCT_REGULAR;--'1424'; 
				END IF;   
			   */
			   
			   
			IF v_rec.sum_int > 0 THEN
		              
					--	v_gl_acct_cd := '1424'; mulai may 2010
					--    v_gl_acct_cd := '1422'; 
					-- mulai 27feb2013 
				v_dbcr_flg := 'D';
				v_sum_int        := v_rec.sum_int;
				V_Payrec_Type := 'PD';
				V_Gl_Acct_Cd := F_GL_ACCT_T3_SEP2015(v_rec.client_cd,v_dbcr_flg);
				If V_Kode_Ab ='YJ001' Then
					V_Ledger_Nar := 'TERLAMBAT BYR DR '||Trim(V_Rec.Client_Cd);
				END IF;
              
			Else
				v_dbcr_flg := 'C';		
				V_Sum_Int        := V_Rec.Sum_Int * -1;
				V_PAYREC_TYPE := 'RD';
				V_Gl_Acct_Cd := F_GL_ACCT_T3_SEP2015(v_rec.client_cd,v_dbcr_flg);
				If V_Kode_Ab ='YJ001' Then
					v_ledger_nar := 'TERLAMBAT BYR KE '||trim(v_rec.client_cd);
				END IF;
			END IF;



			If V_Rec.Client_Type_3 = 'D' Then
				If V_Kode_Ab ='YJ001' Then
					V_Ledger_Nar := 'BUNGA '||V_Client_Cd||' '||To_Char(P_End_Date,'mm/yyyy');
				END IF;
			END IF;

			v_gl_acct_cd := SUBSTR(v_gl_acct_cd,1,4);
			v_sl_acct_cd := trim(v_rec.client_cd);
			V_PAYREC_DATE := TRUNC(p_date);
			v_folder_cd := F_Get_Folder_Num(p_date,'IJ-');
				
			--untuk broker selain YJ
			If V_Kode_Ab <> 'YJ001' Then
				v_ledger_nar := 'Interest '||trim(v_rec.old_ic_num)||' '||TO_CHAR(p_bgn_date,'dd')||'-'||TO_CHAR(p_end_date,'dd/mm/yy');
				v_gl_acct_cd := F_GL_ACCT_T3_SEP2015(v_rec.client_cd,v_dbcr_flg); --'1060'; -- NANTINYA DIUPDATE UNTUK PF
			end if;

								
		BEGIN
			SELECT ACCT_TYPE INTO V_ACCT_TYPE FROM MST_GL_ACCOUNT WHERE SL_A=v_sl_acct_cd AND TRIM(GL_A)= TRIM(v_gl_acct_cd);
		EXCEPTION
			WHEN OTHERS THEN
				V_ERROR_CD := -8;
				V_ERROR_MSG := SUBSTR('Error SELECT  ACCT_TYPE FROM MST_GL_ACCOUNT : '||SQLERRM,1,200);
				RAISE V_ERR;
		END;	
		
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
				
		--CALL Sp_T_Payrech_Upd
		BEGIN	
			Sp_T_Payrech_Upd (V_PAYREC_NUM,--P_SEARCH_PAYREC_NUM,
								V_PAYREC_NUM,--P_PAYREC_NUM,
								V_PAYREC_TYPE,--P_PAYREC_TYPE,
								V_PAYREC_DATE,--P_PAYREC_DATE,
								V_ACCT_TYPE,--P_ACCT_TYPE,
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
								
		IF v_error_cd<0 THEN
			v_error_cd := -30;
			v_error_msg :=SUBSTR('CALL SP_T_PAYRECH_UPD : '||v_error_msg,1,200);
			RAISE v_err;
		END IF;	

		--CALL Sp_T_Many_Approve
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
				v_error_msg :=SUBSTR('Sp_T_Many_Approve : '||v_nl||SQLERRM(SQLCODE),1,200);
				RAISE v_err;
		END;
			
		IF v_error_cd<0 THEN
			v_error_cd := -50;
			v_error_msg :=SUBSTR('Sp_T_Many_Approve : '||v_error_msg,1,200);
			RAISE v_err;
		END IF;
		
		
		IF V_CEK_FOLDER='Y' THEN	
		--INSERT INTO T FOLDER
			BEGIN
				INSERT INTO T_FOLDER ( FLD_MON, FOLDER_CD, DOC_DATE, DOC_NUM, USER_ID, 
										CRE_DT,	 UPD_DT, APPROVED_DT, APPROVED_BY, APPROVED_STAT)
				 VALUES(TO_CHAR(v_payrec_date,'mmyy'), v_folder_cd,v_payrec_date, V_PAYREC_NUM, p_user_id,
						SYSDATE, NULL, SYSDATE, P_USER_ID,'A');
			EXCEPTION
				WHEN OTHERS THEN
					V_Error_Cd := -60;
					V_ERROR_MSG := SUBSTR('Error insert T_FOLDER : '||V_PAYREC_NUM||' '||v_folder_cd||' '||SQLERRM,1,200);
					RAISE V_ERR;
			END;
				
		END IF;
		
		-- insert T_ACCOUNT_LEDGER
		v_tal_id := v_tal_id + 1;
		IF V_DOC_REF ='Y' THEN
			V_DOC_REF_NUM := V_PAYREC_NUM;
		END IF;
	
					
		BEGIN
			Gen_Trx_Jur_Line_Nextg( V_PAYREC_NUM, --p_doc_num
									V_Doc_Ref_Num, --P_DOC_REF_NUM
									v_payrec_date, --p_date
									v_payrec_date, --p_due_date
									v_payrec_date, --p_arap_due_date
									v_tal_id, --p_tal_id 
									V_ACCT_TYPE, --p_acct_type  
									V_Gl_Acct_Cd, --p_gl_acct_cd
									trim(v_sl_acct_cd), --p_sl_acct_cd 
									v_dbcr_flg, --p_db_cr_flg 
									V_Sum_Int, --p_curr_val
									V_Ledger_Nar, --p_ledger_nar 
									'IDR', --p_curr_cd
									'INT', --p_budget_cd  
									V_Rec.Branch_Code, --p_brch_cd
									v_folder_cd, --p_folder_cd ,
									V_PAYREC_TYPE, --p_record_source
									'A', --p_approved_sts 
									p_user_id,
									'N', --p_manual
									V_Error_Cd,
									V_ERROR_MSG);
		EXCEPTION
			WHEN OTHERS THEN
				V_ERROR_CD := -70;
				V_ERROR_MSG := SUBSTR('insert T_ACCOUNT_LEDGER : '||V_PAYREC_NUM||v_nl||SQLERRM,1,200);
				RAISE v_err;
		END;
			
		IF V_ERROR_CD < 0 THEN 
			V_ERROR_CD := -75;
			V_ERROR_MSG := SUBSTR(V_ERROR_MSG||v_nl||SQLERRM,1,200);
			RAISE v_err;
		END IF;
			
		--INSERT T_PAYRECD			
		BEGIN
			INSERT INTO T_PAYRECD (
					   PAYREC_NUM, PAYREC_TYPE, PAYREC_DATE,
					   CLIENT_CD, GL_ACCT_CD, SL_ACCT_CD,
					   DB_CR_FLG, CRE_DT, UPD_DT,
					   APPROVED_STS, APPROVED_BY, APPROVED_DT,
					   PAYREC_AMT, USER_ID, DOC_REF_NUM,
					   TAL_ID, REMARKS, RECORD_SOURCE,
					   Doc_Date, Ref_Folder_Cd, Gl_Ref_Num,
					   DUE_DATE,BRCH_CD)
					VALUES ( v_payrec_num, v_payrec_type, V_PAYREC_DATE,
					    v_rec.client_cd, v_gl_acct_cd, v_sl_acct_cd,
					    v_dbcr_flg, SYSDATE, NULL,
					    'A', p_user_id, SYSDATE,
						v_sum_int, p_user_id, v_payrec_num,
						v_tal_id,v_ledger_nar,V_PAYREC_TYPE,
						V_Payrec_Date,V_Folder_Cd,v_payrec_num,
						v_payrec_date,V_Rec.Branch_Code);
		EXCEPTION
			WHEN OTHERS THEN
				V_ERROR_CD := -80;
				V_ERROR_MSG :=SUBSTR('insert to T_PAYRECD : '||v_payrec_num||'-'|| v_gl_acct_cd||v_nl||SQLERRM,1,200);
				RAISE V_ERR;
		END;		
					

		IF v_Rec.tax_on_interest = 'N' OR ( v_rec.sum_int > 0 AND v_rec.client_type_2 = 'F') OR V_Kode_Ab <> 'YJ001' THEN
				
			v_tal_id := v_tal_id + 1;

					
-- 		17mar11				v_gl_acct_cd := Get_Gl_Acc_Code('OTHI','_');
-- 		          		v_sl_acct_cd := SUBSTR(v_gl_acct_cd,5,6);
--		      		v_gl_acct_cd := SUBSTR(v_gl_acct_cd,1,4);

-- 17mar11 account by branch
			v_gl_acct_cd := v_acct_6509;						
			v_sl_acct_cd := Get_Gl_Acct_Branch(v_gl_acct_cd, v_rec.branch_code);
			v_acct_type := NULL;	
			IF V_DOC_REF ='Y' THEN
				V_DOC_REF_NUM := V_PAYREC_NUM;
			END IF;
						
			IF v_dbcr_flg = 'D' THEN
				v_dbcr_flg := 'C';
				IF V_Kode_Ab <> 'YJ001' THEN
					If Trim(V_Rec.Branch_Code) = 'JK' Then
						v_gl_acct_cd := Get_Gl_Acc_Code('JKIC','_');
					ELSE
						v_gl_acct_cd := Get_Gl_Acc_Code('SLIC','_');
					END IF;
					v_sl_acct_cd := SUBSTR(v_gl_acct_cd,5,6);
					v_gl_acct_cd := SUBSTR(v_gl_acct_cd,1,4);
				END IF;
						   
			ELSE
				v_dbcr_flg := 'D';
				IF V_Kode_Ab <>'YJ001' THEN
					IF trim(v_rec.branch_code) = 'JK' THEN
						v_gl_acct_cd := Get_Gl_Acc_Code('JKID','_');
					ELSE
						v_gl_acct_cd := Get_Gl_Acc_Code('SLID','_');
					END IF;
					v_sl_acct_cd := SUBSTR(v_gl_acct_cd,5,6);
					v_gl_acct_cd := SUBSTR(v_gl_acct_cd,1,4);
				END IF;
			END IF;
			
					
		BEGIN
			Gen_Trx_Jur_Line_Nextg(V_PAYREC_NUM, --p_doc_num
								   V_Doc_Ref_Num, --P_DOC_REF_NUM
								   v_payrec_date, --p_date
								   v_payrec_date, --p_due_date
								   v_payrec_date, --p_arap_due_date
								   v_tal_id, --p_tal_id 
								   V_Acct_Type, --p_acct_type  
								   v_gl_acct_cd, --p_gl_acct_cd
								   Trim(V_Sl_Acct_Cd), --p_sl_acct_cd 
								   V_Dbcr_Flg, --p_db_cr_flg 
								   v_sum_int, --p_curr_val
								   V_Ledger_Nar, --p_ledger_nar 
								   'IDR', --p_curr_cd
								   'INT', --p_budget_cd  
								   V_Rec.Branch_Code, --p_brch_cd
								   V_Folder_Cd, --p_folder_cd ,
								   V_Payrec_Type, --p_record_source
								   'A', --p_approved_sts 
								   P_User_Id,
								  'N', --p_manual
								   V_Error_Cd,
								   V_ERROR_MSG);
		EXCEPTION
			WHEN OTHERS THEN
				V_ERROR_CD := -90;
				V_ERROR_MSG := SUBSTR('insert T_ACCOUNT_LEDGER : '||V_PAYREC_NUM||v_nl||SQLERRM,1,200);
				RAISE v_err;
		END;
			
		IF V_ERROR_CD < 0 THEN 
			V_ERROR_CD := -95;
			V_ERROR_MSG := SUBSTR(V_ERROR_MSG||v_nl||SQLERRM,1,200);
			RAISE v_err;
		END IF;
						
						
		--INSERT T_PAYRECD			
		BEGIN
			INSERT INTO T_PAYRECD (
					   PAYREC_NUM, PAYREC_TYPE, PAYREC_DATE,
					   CLIENT_CD, GL_ACCT_CD, SL_ACCT_CD,
					   DB_CR_FLG, CRE_DT, UPD_DT,
					   APPROVED_STS, APPROVED_BY, APPROVED_DT,
					   PAYREC_AMT, USER_ID, DOC_REF_NUM,
					   TAL_ID, REMARKS, RECORD_SOURCE,
					   Doc_Date, Ref_Folder_Cd, Gl_Ref_Num,
					   DUE_DATE,BRCH_CD)
					VALUES ( v_payrec_num, v_payrec_type, V_PAYREC_DATE,
					    v_rec.client_cd, v_gl_acct_cd, v_sl_acct_cd,
					    v_dbcr_flg, SYSDATE, NULL,
					    'A', p_user_id, SYSDATE,
						v_sum_int, p_user_id, v_payrec_num,
						v_tal_id,v_ledger_nar,V_PAYREC_TYPE,
						V_Payrec_Date,V_Folder_Cd,v_payrec_num,
						v_payrec_date,V_Rec.Branch_Code);
		EXCEPTION
			WHEN OTHERS THEN
				V_ERROR_CD := -100;
				V_ERROR_MSG :=SUBSTR('insert to T_PAYRECD : '||v_payrec_num||'-'|| v_gl_acct_cd||v_nl||SQLERRM,1,200);
				RAISE V_ERR;
		END;		
						
							
		ELSE

			IF V_UANG_MUKA='Y' THEN
						
				v_tal_id := v_tal_id + 1;

									-- 2526 - local - 15%
									--2529 - asing - 20%
				If V_Kode_Ab ='YJ001' Then 
					v_ledger_nar := 'PPH 23 BUNGA '||v_client_cd||' '||TO_CHAR(p_end_date,'mm/yy');
				Else
					v_ledger_nar := 'PPH 23 BUNGA '||v_client_cd||' '||TO_CHAR(p_end_date,'mm/yy');--SEMENTARA UNTUK PF
				END IF;
						
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
				V_Gl_Acct_Cd := Substr(V_Gl_Acct_Cd,1,4);
				v_acct_type := NULL;	
				
		BEGIN
			Gen_Trx_Jur_Line_Nextg(V_PAYREC_NUM, --p_doc_num
								   V_DOC_REF_NUM, --P_DOC_REF_NUM
								   v_payrec_date, --p_date
								   v_payrec_date, --p_due_date
								   v_payrec_date, --p_arap_due_date
								   v_tal_id, --p_tal_id 
								   V_ACCT_TYPE, --p_acct_type  
								   v_gl_acct_cd, --p_gl_acct_cd
								   trim(v_sl_acct_cd), --p_sl_acct_cd 
								   v_dbcr_flg, --p_db_cr_flg 
								   v_pph23, --p_curr_val
								   v_ledger_nar, --p_ledger_nar 
								   'IDR', --p_curr_cd
								   'INT', --p_budget_cd  
								   v_rec.branch_code, --p_brch_cd
								   v_folder_cd, --p_folder_cd ,
								   V_PAYREC_TYPE, --p_record_source
								   'A', --p_approved_sts 
								   p_user_id,
								   'N', --p_manual
								   V_Error_Cd,
								   V_ERROR_MSG);
		Exception
			WHEN OTHERS THEN
				V_ERROR_CD := -110;
				V_ERROR_MSG := SUBSTR('insert T_ACCOUNT_LEDGER : '||V_PAYREC_NUM||v_nl||SQLERRM,1,200);
				RAISE v_err;
		END;
						
		IF V_ERROR_CD < 0 THEN 
			V_ERROR_CD := -120;
			V_ERROR_MSG := SUBSTR(V_ERROR_MSG||v_nl||SQLERRM,1,200);
			Raise V_Err;
		END IF;
						
								
		--INSERT T_PAYRECD			
		BEGIN
			INSERT INTO T_PAYRECD (
								   PAYREC_NUM, PAYREC_TYPE, PAYREC_DATE,
								   CLIENT_CD, GL_ACCT_CD, SL_ACCT_CD,
								   DB_CR_FLG, CRE_DT, UPD_DT,
								   APPROVED_STS, APPROVED_BY, APPROVED_DT,
								   PAYREC_AMT, USER_ID, DOC_REF_NUM,
								   TAL_ID, REMARKS, RECORD_SOURCE,
								   Doc_Date, Ref_Folder_Cd, Gl_Ref_Num,
								   DUE_DATE,BRCH_CD)
								VALUES ( v_payrec_num, v_payrec_type, V_PAYREC_DATE,
									v_rec.client_cd, v_gl_acct_cd, v_sl_acct_cd,
									v_dbcr_flg, SYSDATE, NULL,
									'A', p_user_id, SYSDATE,
									v_pph23, p_user_id, v_payrec_num,
									v_tal_id,v_ledger_nar,V_PAYREC_TYPE,
									V_Payrec_Date,V_Folder_Cd,v_payrec_num,
									v_payrec_date,V_Rec.Branch_Code);
		EXCEPTION
			WHEN OTHERS THEN
				V_ERROR_CD := -125;
				V_ERROR_MSG :=SUBSTR('insert to T_PAYRECD : '||v_payrec_num||'-'|| v_gl_acct_cd||v_nl||SQLERRM,1,200);
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
				V_Gl_Acct_Cd := Substr(V_Gl_Acct_Cd,1,4);
				v_acct_type := NULL;	
				If V_Kode_Ab ='YJ001' Then
					V_Ledger_Nar := 'BUNGA '||V_Client_Cd||' '||To_Char(P_End_Date,'mm/yy');
				Else
					V_Ledger_Nar := 'BUNGA '||V_Client_Cd||' '||To_Char(P_End_Date,'mm/yy');
				END IF;
							
		BEGIN
			Gen_Trx_Jur_Line_Nextg(V_PAYREC_NUM, --p_doc_num
								   V_DOC_REF_NUM, --P_DOC_REF_NUM
								   V_Payrec_Date, --p_date
								   v_payrec_date, --p_due_date
								   v_payrec_date, --p_arap_due_date
								   v_tal_id, --p_tal_id 
								   V_ACCT_TYPE, --p_acct_type  
								   V_Gl_Acct_Cd, --p_gl_acct_cd
								   trim(v_sl_acct_cd), --p_sl_acct_cd 
								   V_Dbcr_Flg, --p_db_cr_flg 
								   v_bunga_pinjaman, --p_curr_val
								   V_Ledger_Nar, --p_ledger_nar 
								   'IDR', --p_curr_cd
								   'INT', --p_budget_cd  
								   V_Rec.Branch_Code, --p_brch_cd
								   V_Folder_Cd, --p_folder_cd ,
								   V_PAYREC_TYPE, --p_record_source
								   'A', --p_approved_sts 
								   P_User_Id,
								   'N', --p_manual
								   V_Error_Cd,
								   V_ERROR_MSG);
		EXCEPTION
			WHEN OTHERS THEN
				V_ERROR_CD := -130;
				V_ERROR_MSG := SUBSTR('insert T_ACCOUNT_LEDGER : '||V_PAYREC_NUM||v_nl||SQLERRM,1,200);
				RAISE v_err;
		END;
						
		IF V_ERROR_CD < 0 THEN 
			V_ERROR_CD := -140;
			V_ERROR_MSG := SUBSTR(V_ERROR_MSG||v_nl||SQLERRM,1,200);
			RAISE v_err;
		END IF;	
							
				
		--INSERT T_PAYRECD			
		BEGIN
			INSERT INTO T_PAYRECD (
								   PAYREC_NUM, PAYREC_TYPE, PAYREC_DATE,
								   CLIENT_CD, GL_ACCT_CD, SL_ACCT_CD,
								   DB_CR_FLG, CRE_DT, UPD_DT,
								   APPROVED_STS, APPROVED_BY, APPROVED_DT,
								   PAYREC_AMT, USER_ID, DOC_REF_NUM,
								   TAL_ID, REMARKS, RECORD_SOURCE,
								   Doc_Date, Ref_Folder_Cd, Gl_Ref_Num,
								   DUE_DATE,BRCH_CD)
								VALUES ( v_payrec_num, v_payrec_type, V_PAYREC_DATE,
									v_rec.client_cd, v_gl_acct_cd, v_sl_acct_cd,
									v_dbcr_flg, SYSDATE, NULL,
									'A', p_user_id, SYSDATE,
									v_bunga_pinjaman, p_user_id, v_payrec_num,
									v_tal_id,v_ledger_nar,V_PAYREC_TYPE,
									V_Payrec_Date,V_Folder_Cd,v_payrec_num,
									v_payrec_date,V_Rec.Branch_Code);
		EXCEPTION
			WHEN OTHERS THEN
				V_ERROR_CD := -145;
				V_ERROR_MSG :=SUBSTR('insert to T_PAYRECD : '||v_payrec_num||'-'|| v_gl_acct_cd||v_nl||SQLERRM,1,200);
				RAISE V_ERR;
		END;		
				   
			END IF;--END PPH23 FOR YJ 
		END IF;	--	IF v_Rec.tax_on_interest = 'N' OR ( v_rec.sum_int > 0 AND v_rec.client_type_2 = 'F')		
			
		v_cnt := v_cnt + 1;


		END IF;--IF v_rec.sum_int <> 0  AND NVL(v_rec.amt_int_flg,'Y') = 'Y' 
			
		--2.update t_interest.post_flg='Y'
		BEGIN
			UPDATE T_INTEREST
					SET post_flg = 'Y',
						xn_doc_num = V_PAYREC_NUM,
						upd_by=p_user_id,
						approved_by =p_user_id,
						approved_dt=SYSDATE
					WHERE client_cd  = trim(v_rec.client_cd)
					AND int_dt BETWEEN p_bgn_date AND p_end_date
					AND post_flg = 'N';
		Exception
			WHEN OTHERS THEN
				V_ERROR_CD := -150;
				V_ERROR_MSG :=SUBSTR('update post_flg T_INTEREST : '||v_rec.client_cd||v_nl||SQLERRM,1,200);
				RAISE V_ERR;
		END;
				
	V_PAYREC_NUM:=NULL;
	v_flg:='Y';
	END LOOP;
	CLOSE l_csr;
	--commit;
		  
	IF V_FLG ='N' THEN
		V_ERROR_CD := -160;
		V_ERROR_MSG :='NO DATA FOUND TO POSTING';
		RAISE V_ERR;
	END IF;

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
END Sp_Posting_Interest;
