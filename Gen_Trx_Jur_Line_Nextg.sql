Create Or Replace 
PROCEDURE Gen_Trx_Jur_Line_Nextg(
	   p_doc_num T_ACCOUNT_LEDGER.xn_doc_num%TYPE,
       P_DOC_REF_NUM T_ACCOUNT_LEDGER.doc_ref_num%TYPE,
 	   p_date T_ACCOUNT_LEDGER.doc_date%TYPE,
       p_due_date T_ACCOUNT_LEDGER.due_date%TYPE,
	   p_arap_due_date T_ACCOUNT_LEDGER.arap_due_date%TYPE,
	   p_tal_id T_ACCOUNT_LEDGER.tal_id%TYPE,
	   p_acct_type  T_ACCOUNT_LEDGER.acct_type%TYPE,
	   p_gl_acct_cd T_ACCOUNT_LEDGER.gl_acct_cd%TYPE,
	   p_sl_acct_cd T_ACCOUNT_LEDGER.sl_acct_cd%TYPE,
	   p_db_cr_flg T_ACCOUNT_LEDGER.db_cr_flg%TYPE,
	   p_curr_val T_ACCOUNT_LEDGER.curr_val%TYPE,
	   p_ledger_nar T_ACCOUNT_LEDGER.ledger_nar%TYPE,
	   p_curr_cd  T_ACCOUNT_LEDGER.curr_cd%TYPE,
	   p_budget_cd  T_ACCOUNT_LEDGER.budget_cd%TYPE,
	   p_brch_cd  T_ACCOUNT_LEDGER.brch_cd%TYPE,
 	   p_folder_cd T_ACCOUNT_LEDGER.folder_cd%TYPE,
	   p_record_source T_ACCOUNT_LEDGER.record_source%TYPE,
   	   p_approved_sts T_ACCOUNT_LEDGER.approved_sts%TYPE,
	   p_user_id T_ACCOUNT_LEDGER.user_id%TYPE,
	   p_manual	T_ACCOUNT_LEDGER.MANUAL%TYPE,
	    p_error_code					OUT			NUMBER,
p_error_msg					OUT			VARCHAR2

 ) IS
tmpVar NUMBER;
/******************************************************************************
   NAME:       GEN_TRX_GL_JUR
   PURPOSE:    generate TRX  jurnal from PROCESS_ CONTRACT _ACCT_LEDGER



******************************************************************************/

v_err EXCEPTION;
v_error_code NUMBER;
v_error_msg VARCHAR2(200);
BEGIN




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
			   FOLDER_CD, SETT_VAL, MANUAL,
			   ARAP_DUE_DATE)
			VALUES ( p_doc_num, p_tal_id, P_DOC_REF_NUM,
			    p_acct_type, p_sl_acct_cd, p_gl_acct_cd,
			    NULL, NULL, p_curr_cd,
			    p_brch_cd, p_curr_val, p_curr_val,
				p_BUDGET_CD, p_db_cr_flg, p_ledger_nar,
			    NULL, p_user_id, SYSDATE,
			    NULL, p_date, p_due_date,
			    p_date, '1', p_record_source,
			    0, NULL, NULL,
			    p_approved_sts, p_user_id, sysdate,
			    p_folder_cd, 0, p_manual,
				p_arap_due_date);

		EXCEPTION
		  WHEN OTHERS THEN
				  	   		   v_error_code := -2;
								v_error_msg := SUBSTR('insert T_A_L  '||p_doc_num||SQLERRM,1,200);
								RAISE v_err;
				  END;

   P_error_code:= 1;
	P_error_msg := '';
   EXCEPTION
     WHEN v_err THEN
	        P_error_code := v_error_code;
				P_error_msg := v_error_msg;
				ROLLBACK;
     WHEN NO_DATA_FOUND THEN
        P_error_code := -1;
				P_error_msg := 'GEN_TRX_JUR_LINE Data not found';
				ROLLBACK;
     WHEN OTHERS THEN
       -- Consider logging the error and then re-raise
	   ROLLBACK;

	   P_error_code := -1;
	   P_error_msg :=  SUBSTR(SQLERRM,1,200);
       Raise;
END Gen_Trx_Jur_Line_Nextg;