create or replace PROCEDURE SP_GENERATE_MARKET_INFO_FEE(p_end_date date,
							P_JOURNAL_DATE DATE,
							--P_TOTAL_FEE T_OLT_LOGIN.INFO_FEE%TYPE,
							P_USER_ID T_JVCHH.USER_ID%TYPE,
							P_FOLDER_CD T_JVCHH.FOLDER_CD%TYPE,
							P_IP_ADDRESS T_MANY_HEADER.IP_ADDRESS%TYPE,
							P_UPDATE_DATE T_MANY_HEADER.UPDATE_DATE%TYPE,
							P_UPDATE_SEQ T_MANY_HEADER.UPDATE_SEQ%TYPE,
							P_ERROR_CODE	OUT NUMBER,
							P_ERROR_MSG	OUT VARCHAR2
							) is


 v_reg_gla T_ACCOUNT_LEDGER.GL_ACCT_CD%TYPE;
 v_margin_gla T_ACCOUNT_LEDGER.GL_ACCT_CD%TYPE;


CURSOR csr_fee( a_margin_gla  T_ACCOUNT_LEDGER.GL_ACCT_CD%TYPE,a_reg_gla  T_ACCOUNT_LEDGER.GL_ACCT_CD%TYPE) IS
  SELECT t.client_cd, info_fee,DECODE(trim(m.client_type_3),'M',a_margin_gla ,a_reg_gla) arap_gla
FROM T_OLT_LOGIN t, MST_CLIENT m
WHERE period_end_date = p_end_date
AND info_fee > 0
AND t.client_Cd = m.client_cd
AND m.susp_stat = 'N'
and NOT  exists 
  ( select field_value CLIENT_CD from t_many_detail
  where UPDATE_SEQ = P_UPDATE_SEQ AND UPDATE_DATE>=P_UPDATE_DATE
  and table_name='T_OLT_LOGIN' AND FIELD_NAME='CLIENT_CD' AND FIELD_VALUE=T.client_cd ) 
;   

--FROM C_OLT_LOGIN_JAN14

 v_ledger_nar  T_ACCOUNT_LEDGER.Ledger_nar%TYPE;
 v_tal_id NUMBER;
 v_tot_fee  NUMBER;
  v_fee_gla  T_ACCOUNT_LEDGER.GL_ACCT_CD%TYPE;
   v_fee_sla T_ACCOUNT_LEDGER.SL_ACCT_CD%TYPE;
  v_doc_num T_ACCOUNT_LEDGER.xn_doc_num%TYPE;

v_err EXCEPTION;
v_error_code NUMBER;
v_error_msg VARCHAR2(200);
v_sign varchar2(1);
V_FLD_MON VARCHAR2(10);
v_doc_ref T_JVCHH.JVCH_NUM%TYPE;
v_acct_type T_ACCOUNT_LEDGER.ACCT_TYPE%TYPE;
v_flg char(1):='N';
V_FOLDER CHAR(1);
V_FOLDER_CD T_FOLDER.FOLDER_CD%type;
BEGIN

   v_tot_fee := 0;
   v_ledger_nar := 'Market Info Fee '||TO_CHAR(p_end_date,'monyyyy');
	begin
	   SELECT dstr1, dstr2  INTO v_Reg_gla, v_margin_gla
	   FROM MST_SYS_PARAM
	   WHERE param_id = 'SP_OLT_FEE_JUR'
	   AND param_cd1 = 'GL_ACCT'
	   AND param_cd2 = 'CLIENT';
	EXCEPTION
   WHEN OTHERS THEN
				     v_error_code := -10;
					 v_error_msg :=  SUBSTR('mst_sys_param '||SQLERRM,1,200);
					 RAISE v_err;
	END;
	
	begin
	   SELECT dstr1, dstr2  INTO v_fee_gla, v_fee_sla
	   FROM MST_SYS_PARAM
	   WHERE param_id = 'SP_OLT_FEE_JUR'
	   AND param_cd1 = 'GL_ACCT'
	   AND param_cd2 = 'FEE';
	EXCEPTION
   WHEN OTHERS THEN
				     v_error_code := -15;
					 v_error_msg :=  SUBSTR('mst_sys_param '||SQLERRM,1,200);
					 RAISE v_err;
	END;
	
   begin
   select dflg1 into v_sign from mst_sys_param where
   param_id='SYSTEM' and param_cd1='DOC_REF';
   EXCEPTION
   WHEN OTHERS THEN
				     v_error_code := -20;
					 v_error_msg :=  SUBSTR('mst_sys_param '||SQLERRM,1,200);
					 RAISE v_err;
	END;
  
  begin
  SELECT DFLG1 INTO V_FOLDER FROM MST_SYS_PARAM WHERE PARAM_ID='SYSTEM' AND PARAM_CD1='VCH_REF';
   EXCEPTION
   WHEN OTHERS THEN
		 v_error_code := -21;
		 v_error_msg :=  SUBSTR('CEK PENGGUNAAN FOLDER CD PADA MST_SYS_PARAM '||SQLERRM,1,200);
		 RAISE v_err;
	END;
  
  IF V_FOLDER='Y' THEN
  V_FOLDER_CD :=P_FOLDER_CD;
  else
  V_FOLDER_CD :='';
  END IF;
  
	v_tal_id :=1;
	v_doc_num := Get_Docnum_GL(P_JOURNAL_DATE,'GL');
   FOR rec IN csr_fee(v_margin_gla,v_Reg_gla ) LOOP
		
		v_tot_fee :=v_tot_fee + REC.INFO_FEE;
		
		IF V_TAL_ID = 1 THEN
		begin
	Sp_T_JVCHH_Upd(	v_doc_num,
					 v_doc_num,
					'GL',
					P_JOURNAL_DATE,
					NULL,
					NULL,
					'IDR',
					v_tot_fee,
					v_ledger_nar,
					P_USER_ID,
					SYSDATE,
					NULL,
					V_FOLDER_CD,
					'N',
					'I',
					p_ip_address,
					NULL,
					p_update_date,
					p_update_seq,
					'1',
					v_error_code,
					v_error_msg);
  EXCEPTION
 	    WHEN OTHERS THEN
	   			v_error_code := -25;
				v_error_msg :=  SUBSTR('Sp_T_JVCHH_Upd '||SQLERRM,1,200);
				RAISE v_err;
	   END;
	  
    IF v_error_code<0 THEN
    	v_error_code := -30;
				v_error_msg :=  SUBSTR('Sp_T_JVCHH_Upd '||v_error_msg||' '||SQLERRM,1,200);
				RAISE v_err;
    END IF;
		
    IF V_FOLDER ='Y' THEN
		V_FLD_MON := TO_CHAR(P_JOURNAL_DATE,'MMYY');
		
		BEGIN
		 SP_T_FOLDER_UPD (v_doc_num,
						V_FLD_MON,
						V_FOLDER_CD,
						P_JOURNAL_DATE,
						v_doc_num,
						P_USER_ID,
						SYSDATE,
						NULL,--P_UPD_BY,
						NULL,--P_UPD_DT,
						'I',--P_UPD_STATUS,
						p_ip_address,
						NULL,
						p_update_date,
						p_update_seq,
						V_TAL_ID,
						v_error_code,
						v_error_msg	);
 EXCEPTION
 	    WHEN OTHERS THEN
	   			v_error_code := -35;
				v_error_msg :=  SUBSTR('SP_T_FOLDER_UPD '||SQLERRM,1,200);
				RAISE v_err;
	   END;
	  
    IF v_error_code<0 THEN
    	v_error_code := -40;
				v_error_msg :=  SUBSTR('SP_T_FOLDER_UPD '||v_error_msg||' '||SQLERRM,1,200);
				RAISE v_err;
    END IF;
	END IF;	
		
		END IF;

--BUAT JURNAL UNTUK DEBIT
if v_sign ='Y' THEN
v_doc_ref :=v_doc_num;
END IF;

 begin
SELECT acct_type into v_acct_type FROM MST_CLIENT c,mst_gl_account m WHERE client_cd = sl_a 
      and sl_a=REC.CLIENT_CD and trim(gl_a)= trim(REC.ARAP_GLA) ;
 EXCEPTION
   WHEN OTHERS THEN
				     v_error_code := -45;
					 v_error_msg :=  SUBSTR('mst_sys_param  '||REC.CLIENT_CD||trim(REC.ARAP_GLA)||SQLERRM,1,200);
					 RAISE v_err;
	END;
	
   begin
Sp_T_ACCOUNT_LEDGER_Upd(v_doc_num,
						V_TAL_ID,
						v_doc_num,
						V_TAL_ID,
						v_doc_ref,
						v_acct_type,
						REC.CLIENT_CD,
						REC.ARAP_GLA,
						NULL,
						NULL,
						'IDR',
						NULL,
						REC.INFO_FEE,
						REC.INFO_FEE,
						'OLTFEE',
						'D',--v_db_cr_flg,
						v_ledger_nar,
						NULL,
						P_JOURNAL_DATE,
						P_JOURNAL_DATE,
						NULL,
						NULL,
						'GL',
						NULL,
						NULL,
						NULL,
						V_FOLDER_CD,
						NULL,
						NULL,
						Null,
            Null,
            null,
						P_USER_ID,
						SYSDATE,
						NULL,
						NULL,
						'N',
						'Y',
						'I',
						p_ip_address,
						NULL,
						p_update_date,
						p_update_seq,
						V_TAL_ID,
						v_error_code,
						v_error_msg); 
	 EXCEPTION
 	    WHEN OTHERS THEN
	   			v_error_code := -50;
				v_error_msg :=  SUBSTR('Sp_T_ACCOUNT_LEDGER_Upd '||SQLERRM,1,200);
				RAISE v_err;
	   END;
	
    IF v_error_code<0 THEN
    	v_error_code := -55;
				v_error_msg :=  SUBSTR('Sp_T_ACCOUNT_LEDGER_Upd '||v_error_msg||' '||SQLERRM,1,200);
				RAISE v_err;
    END IF;
	V_TAL_ID :=V_TAL_ID+1;
v_flg :='Y';
   END LOOP;
   
   if v_flg ='Y' then
   
   if v_sign ='Y' THEN
v_doc_ref :=v_doc_num;
END IF;
   --BUAT JURNAL CREDIT 1 UNTUK BALANCE
   begin
Sp_T_ACCOUNT_LEDGER_Upd(v_doc_num,
						V_TAL_ID,
						v_doc_num,
						V_TAL_ID,
						v_doc_ref,
						v_acct_type,
						v_fee_sla,
						v_fee_gla,
						NULL,
						NULL,
						'IDR',
						NULL,
						v_tot_fee,
						v_tot_fee,
						'OLTFEE',
						'C',--v_db_cr_flg,
						v_ledger_nar,
						NULL,
						P_JOURNAL_DATE,
						P_JOURNAL_DATE,
						NULL,
						NULL,
						'GL',
						NULL,
						NULL,
						NULL,
						V_FOLDER_CD,
						NULL,
						NULL,
						Null,
            Null,--P_CASH_WITHDRAW_AMT
            null,
						P_USER_ID,
						SYSDATE,
						NULL,
						NULL,
						'N',
						'Y',
						'I',
						p_ip_address,
						NULL,
						p_update_date,
						p_update_seq,
						V_TAL_ID,
						v_error_code,
						v_error_msg); 
	 EXCEPTION
 	    WHEN OTHERS THEN
	   			v_error_code := -60;
				v_error_msg :=  SUBSTR('Sp_T_ACCOUNT_LEDGER_Upd '||SQLERRM,1,200);
				RAISE v_err;
	   END;
	
    IF v_error_code<0 THEN
    	v_error_code := -65;
				v_error_msg :=  SUBSTR('Sp_T_ACCOUNT_LEDGER_Upd '||v_error_msg||' '||SQLERRM,1,200);
				RAISE v_err;
    END IF;
   
   
		BEGIN
		UPDATE T_MANY_DETAIL SET FIELD_VALUE=v_tot_fee WHERE UPDATE_SEQ=P_UPDATE_SEQ AND UPDATE_DATE= P_UPDATE_DATE AND TABLE_NAME='T_JVCHH' AND FIELD_NAME='CURR_AMT';
		EXCEPTION
		WHEN OTHERS THEN
		 				v_error_code := -70;
						v_error_msg := SUBSTR('upd curr amount in T_JVCHH '||SQLERRM,1,200);
						RAISE v_err;
		END;
   end if;
   

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
END SP_GENERATE_MARKET_INFO_FEE;