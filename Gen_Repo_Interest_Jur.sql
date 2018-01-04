create or replace 
PROCEDURE Gen_Repo_Interest_Jur(p_date DATE,
	   	  		  										 	  													p_client_cd T_REPO.client_cd%TYPE,
																												p_repo_num 	T_REPO.repo_num%TYPE,
																												p_repo_type 	T_REPO.repo_type%TYPE,
																												p_repo_date		T_REPO.repo_date%TYPE,
																												p_repo_val		T_REPO.repo_val%TYPE,
																												p_interest_rate T_REPO_HIST.interest_rate%TYPE,
																												p_int_amt T_ACCOUNT_LEDGER.curr_val%TYPE,
																												p_int_aft_tax T_ACCOUNT_LEDGER.curr_val%TYPE,
																												p_int_tax T_ACCOUNT_LEDGER.curr_val%TYPE,
																												p_folder_cd T_ACCOUNT_LEDGER.folder_cd%TYPE,
																												p_user_id T_ACCOUNT_LEDGER.user_id%TYPE			) IS
tmpVar NUMBER;
/******************************************************************************
   NAME:       GEN_REPO_INTEREST_JUR
   PURPOSE:    jurnal harian interest dari repo saham / reverse repo saham

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        27/05/2011          1. Created this procedure.


******************************************************************************/

  

v_doc_num T_ACCOUNT_LEDGER.xn_doc_num%TYPE;
v_gl_acct_cd T_ACCOUNT_LEDGER.gl_acct_cd%TYPE;
v_sl_acct_cd T_ACCOUNT_LEDGER.sl_acct_cd%TYPE;
v_ledger_nar T_ACCOUNT_LEDGER.ledger_nar%TYPE;
v_desc T_ACCOUNT_LEDGER.ledger_nar%TYPE;
 v_tal_id T_ACCOUNT_LEDGER.tal_id %TYPE;
 v_arap_tal_id T_ACCOUNT_LEDGER.tal_id %TYPE;
v_curr_val  T_ACCOUNT_LEDGER.curr_val%TYPE;
v_db_cr_flg T_ACCOUNT_LEDGER.db_cr_flg%TYPE;
v_status T_ACCOUNT_LEDGER.approved_sts%TYPE;

BEGIN
   tmpVar := 0;
--v_status := 'C';
 v_status := 'A';

   	   v_doc_num := Get_Docnum_Jvch(p_date,'GL');
     v_doc_num := SUBSTR(v_doc_num,1,6)||v_status||SUBSTR(v_doc_num,8,7);
	 
      v_curr_val := TRUNC(p_repo_val / 1000000000, 1);
      v_desc := p_client_cd||' '||TO_CHAR(p_repo_date,'dd/mm/yy')||' '||TO_CHAR(v_curr_val)||' M '||TO_CHAR(p_interest_rate)||'%';
   FOR v_tal_id IN  1..3  LOOP

   	   v_curr_val := 0;
	   
   	   IF v_tal_id = 1 THEN
		   	  IF p_repo_type = 'REVERSE' THEN
			  	       v_gl_acct_cd := '1415';
					   v_sl_acct_cd := p_client_cd;
					   v_db_cr_flg := 'D';
					   v_curr_val := p_int_amt;
					     v_ledger_nar := 'B.Repo '||v_desc;
						 v_arap_tal_id := v_tal_id;
			   ELSE
			   	       v_gl_acct_cd := '5300';
					   v_sl_acct_cd := '100094';
					   v_db_cr_flg := 'D';
					   v_curr_val := p_int_aft_tax;
					     v_ledger_nar := 'B.Repo '||v_desc;
			   END IF;
		ELSIF  v_tal_id = 2 AND p_int_tax > 0 THEN
		      
		   	  IF p_repo_type = 'REVERSE' THEN
			  	       v_gl_acct_cd := '1524';
					   v_sl_acct_cd := '000000';
					   v_db_cr_flg := 'D';
					   v_curr_val := p_int_tax;
					     v_ledger_nar := 'um23 '||v_desc;
			   ELSE
			   	       v_gl_acct_cd := '2526';
					   v_sl_acct_cd := '000000';
					   v_db_cr_flg := 'C';
					   v_curr_val := p_int_tax;
					     v_ledger_nar := 'um23 '||v_desc;
			   END IF;
		
		ELSIF  v_tal_id = 3 THEN
		   	  IF p_repo_type = 'REVERSE' THEN
			  -- dirubah 15Jun 12 , dulunya 5300 
			   	       v_gl_acct_cd := '6510';
					   v_sl_acct_cd := '000000';
					   v_db_cr_flg := 'C';
					   v_curr_val := p_int_aft_tax;
					     v_ledger_nar := 'P.RevRepo '||v_desc;
			   ELSE
			  	       v_gl_acct_cd := '2415';
					   v_sl_acct_cd := p_client_cd;
					   v_db_cr_flg := 'C';
					   v_curr_val := p_int_amt;
					     v_ledger_nar := 'B.Repo '||v_desc;
						 v_arap_tal_id := v_tal_id;
			   END IF;
	   END IF;
		
		IF  v_curr_val >  0 THEN
		
				BEGIN				   
			   INSERT INTO T_ACCOUNT_LEDGER (
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
			VALUES ( v_doc_num, v_tal_id, NULL,
			    NULL,  v_sl_acct_cd,   v_gl_acct_cd,
			   NULL , NULL, NULL,
			    NULL,  v_curr_val, v_curr_val ,
			    'INTREPO',  v_db_cr_flg, v_ledger_nar,
			    NULL, p_user_id, SYSDATE,
			    NULL, p_date, p_date,
			    NULL, NULL, 'GL',
			    0, NULL, NULL,
			    v_status, NULL, SYSDATE,
			    p_folder_cd,0 );
		     EXCEPTION
				 	WHEN OTHERS THEN
			  		RAISE_APPLICATION_ERROR(-20100,'insert on T_A_L '||p_client_cd||' '||v_gl_acct_cd||' '||SQLERRM);
				  END;

   		  END IF;
		  
   END LOOP;
   
   
   BEGIN		
   INSERT INTO T_JVCHH (
   JVCH_NUM, JVCH_TYPE, JVCH_DATE, 
   GL_ACCT_CD, SL_ACCT_CD, CURR_CD, 
   CURR_AMT, REMARKS, USER_ID, 
   CRE_DT, UPD_DT, APPROVED_STS, 
   APPROVED_BY, APPROVED_DT, FOLDER_CD) 
VALUES ( v_doc_num, 'GL', p_date,
    NULL, NULL, NULL,
    p_int_amt, v_desc , p_user_id,
    SYSDATE,NULL , v_status,
    NULL,NULL ,p_folder_cd );
	EXCEPTION
		 	WHEN OTHERS THEN
	  		RAISE_APPLICATION_ERROR(-20100,'insert on T_JVCHH '||p_client_cd||SQLERRM);
		  END;
	
	BEGIN
	INSERT INTO T_FOLDER (
   FLD_MON, FOLDER_CD, DOC_DATE, 
   DOC_NUM, USER_ID, CRE_DT) 
VALUES ( TO_CHAR(p_date,'mmyy'), p_folder_cd, p_date,
    v_doc_num, p_user_id, SYSDATE );
	EXCEPTION
		 	WHEN OTHERS THEN
	  		RAISE_APPLICATION_ERROR(-20100,'insert on T_FOLDER '||p_folder_cd||SQLERRM);
		  END;
	
BEGIN	
INSERT INTO T_REPO_VCH (
   REPO_NUM, DOC_NUM, DOC_REF_NUM, 
   TAL_ID, AMT, DOC_DT, 
   USER_ID, CRE_DT) 
VALUES ( p_repo_num, v_doc_num, v_doc_num,
    v_arap_tal_id, p_int_amt, p_date,
    p_user_id,SYSDATE );	
	EXCEPTION
		 	WHEN OTHERS THEN
	  		RAISE_APPLICATION_ERROR(-20100,'insert T_REPO_VCH '||p_repo_num||SQLERRM);
		  END;
		  
	BEGIN		  
		UPDATE T_REPO
		SET sett_val = sett_val + p_int_amt
		WHERE repo_num = p_repo_num;  
	EXCEPTION
		 	WHEN OTHERS THEN
	  		RAISE_APPLICATION_ERROR(-20100,'insert T_REPO_VCH '||p_repo_num||SQLERRM);
		  END;
		  	  
		  
   EXCEPTION
     WHEN NO_DATA_FOUND THEN
       NULL;
     WHEN OTHERS THEN
       -- Consider logging the error and then re-raise
       RAISE;
END Gen_Repo_Interest_Jur;