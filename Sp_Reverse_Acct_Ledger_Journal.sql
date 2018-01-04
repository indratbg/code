create or replace 
PROCEDURE Sp_Reverse_Acct_Ledger_Journal(
P_DATE 	  		  T_FUND_MOVEMENT.doc_date%TYPE,
P_JVCH_NUM    T_FUND_MOVEMENT.doc_num%TYPE,
P_USER_ID     T_FUND_MOVEMENT.user_id%TYPE,
p_update_date t_many_detail.update_date%type,
p_update_seq t_many_detail.update_seq%type,
p_ip_address t_many_header.ip_address%type,
p_error_code OUT NUMBER,
p_error_msg			OUT				VARCHAR2)
 IS

/******************************************************************************
   NAME:       Sp_Reverse_Acct_Ledger_Journal
   PURPOSE:

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        08/10/2014          1. Created this procedure.

   NOTES:


******************************************************************************/

	cursor csr_data(a_xn_doc_num t_account_ledger.xn_doc_num%type) is
	 SELECT * FROM T_ACCOUNT_LEDGER
	 where xn_doc_num=a_xn_doc_num
	 order by tal_id;

v_record_seq t_many_detail.record_seq%type;
v_db_cr_flg t_account_ledger.db_cr_flg%type;
 v_err EXCEPTION;
v_error_code							NUMBER;
v_error_msg							VARCHAR2(200);

v_reversal_doc_num  T_FUND_MOVEMENT.doc_num%TYPE;
BEGIN

   v_reversal_doc_num := Get_Docnum_Jvch(p_DATE,'GL');

FOR REC IN CSR_DATA(p_jvch_num) LOOP

   BEGIN
   INSERT INTO IPNEXTG.T_account_LEDGER (  
   XN_DOC_NUM,TAL_ID,DOC_REF_NUM,
	ACCT_TYPE,SL_ACCT_CD,GL_ACCT_CD,
	CHRG_CD,CHQ_SNO,CURR_CD,
	BRCH_CD,CURR_VAL,XN_VAL,
	BUDGET_CD,DB_CR_FLG,LEDGER_NAR,
	CASHIER_ID,USER_ID,CRE_DT,
	UPD_DT,DOC_DATE,DUE_DATE,
	NETTING_DATE,NETTING_FLG,RECORD_SOURCE,
	SETT_FOR_CURR,SETT_STATUS,RVPV_NUMBER,
	APPROVED_STS,APPROVED_BY,APPROVED_DT,
	FOLDER_CD,SETT_VAL,ARAP_DUE_DATE,
	RVPV_GSSL,UPD_BY)
					values(  v_reversal_doc_num, rec.tal_id, rec.doc_ref_num,
							rec.acct_type, rec.sl_acct_cd, rec.gl_acct_cd,
							rec.chrg_cd, rec.chq_sno,rec.curr_cd,
							rec.brch_cd, rec.curr_val, rec.xn_val,
							rec.budget_cd, DECODE(rec.db_cr_flg,'C','D','C') ,rec.ledger_nar,
							rec.cashier_id, p_user_id, sysdate,
							null, rec.doc_date, rec.due_date,
							rec.netting_date, rec.netting_flg, rec.record_source,
							rec.sett_for_curr, rec. sett_status, rec.rvpv_number,
							rec.approved_sts, p_user_id, sysdate, 
							rec.folder_cd, rec.sett_val, rec.arap_due_date,
							rec.rvpv_gssl,null);
   
   
   EXCEPTION
   WHEN OTHERS THEN
				     v_error_code := -2;
					 v_error_msg :=  SUBSTR('insert reversal T ACCOUNT LEDGER '|| p_jvch_num||SQLERRM,1,200);
					 RAISE v_err;
	END;
	
	begin
	select count(1) into v_record_seq from t_account_ledger where xn_doc_num= p_jvch_num;
	EXCEPTION
   WHEN OTHERS THEN
				     v_error_code := -2;
					 v_error_msg :=  SUBSTR('t account ledger'||SQLERRM,1,200);
					 RAISE v_err;
	END;
	
	if v_record_seq = 0 then
		v_record_seq :=1;
		else
		v_record_seq :=v_record_seq+1;
	end if;
	
	if rec.db_cr_flg= 'C' then
	v_db_cr_flg :='D';
	else
	v_db_cr_flg :='C';
	end if;
	
	begin
	Sp_T_ACCOUNT_LEDGER_Upd(
						v_reversal_doc_num,
						rec.tal_id,
						v_reversal_doc_num,
						 rec.tal_id,
						rec.doc_ref_num,
						rec.acct_type,
						rec.sl_acct_cd,
						rec.gl_acct_cd,
						rec.chrg_cd,
						rec.chq_sno,
						rec.curr_cd,
						rec.brch_cd,
						rec.curr_val,
						 rec.xn_val,
						rec.budget_cd,
						 v_db_cr_flg,
						rec.ledger_nar,
						rec.cashier_id,
						rec.doc_date,
						rec.due_date,
						rec.netting_date,
						 rec.netting_flg,
						 rec.record_source,
						rec.sett_for_curr,
						rec. sett_status,
						rec.rvpv_number,
						rec.folder_cd,
						rec.sett_val,
						rec.arap_due_date,
						rec.rvpv_gssl,
						 p_user_id,
						sysdate,
						null,
						null,						
						'I',
						p_ip_address,
						null,
						p_update_date,
						p_update_seq,
						v_record_seq,
						v_error_code,
						v_error_msg);
	EXCEPTION
   WHEN OTHERS THEN
				     v_error_code := -2;
					 v_error_msg :=  SUBSTR('Sp_T_ACCOUNT_LEDGER_Upd'||SQLERRM,1,200);
					 RAISE v_err;
	END;
	
	
		
	
END LOOP;   
	
	BEGIN
   UPDATE T_jvchh
    SET REVERSAL_JUR = v_reversal_doc_num
	WHERE jvch_num = P_jvch_num;
   EXCEPTION
   WHEN OTHERS THEN
				     v_error_code := -3;
					 v_error_msg :=  SUBSTR('update t jvchh '||P_jvch_num||SQLERRM,1,200);
					 RAISE v_err;
	END;



   EXCEPTION
     WHEN NO_DATA_FOUND THEN
       NULL;
     WHEN OTHERS THEN
			ROLLBACK;
			p_error_code := -1;
			p_error_msg := SUBSTR(SQLERRM,1,200);
			RAISE;
      
END Sp_Reverse_Acct_Ledger_Journal;