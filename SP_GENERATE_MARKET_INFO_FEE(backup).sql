create or replace 
PROCEDURE SP_GENERATE_MARKET_INFO_FEE(p_end_date date,
							P_JOURNAL_DATE DATE,
							P_TOTAL_FEE T_OLT_LOGIN.INFO_FEE%TYPE,
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
 v_ledger_nar  T_ACCOUNT_LEDGER.Ledger_nar%TYPE;
 v_tal_id NUMBER;
 v_tot_fee  NUMBER;
  v_fee_gla  T_ACCOUNT_LEDGER.GL_ACCT_CD%TYPE;
   v_fee_sla T_ACCOUNT_LEDGER.SL_ACCT_CD%TYPE;
  v_doc_num T_ACCOUNT_LEDGER.xn_doc_num%TYPE;
v_err EXCEPTION;
v_error_code							NUMBER;
v_error_msg							VARCHAR2(200);	
v_sign char(1);
v_doc_ref varchar2(25);
v_acct_type mst_gl_account.acct_type%type;
v_db_cr_flg char(1);
record_Seq number;
CURSOR csr_jurnal is
SELECT 
TO_CHAR((SELECT to_date(FIELD_VALUE,'yyyy-mm-dd hh24:mi:ss') FROM T_MANY_DETAIL DA 
        WHERE DA.UPDATE_SEQ = p_update_seq
		AND DA.UPDATE_DATE = p_update_date
		AND	DA.TABLE_NAME = 'T_OLT_LOGIN' 
        AND DA.FIELD_NAME = 'PERIOD_END_DATE'
        AND DA.RECORD_SEQ = DD.RECORD_SEQ),'YYYY-MM-DD') PERIOD_END_DATE, 
(SELECT FIELD_VALUE FROM T_MANY_DETAIL DA 
        WHERE DA.UPDATE_SEQ = p_update_seq
        AND DA.UPDATE_DATE = p_update_date
        AND DA.TABLE_NAME = 'T_OLT_LOGIN' 
        AND DA.FIELD_NAME = 'CLIENT_CD'
        AND DA.RECORD_SEQ = DD.RECORD_SEQ) CLIENT_CD, 
(SELECT FIELD_VALUE FROM T_MANY_DETAIL DA 
        WHERE DA.UPDATE_SEQ = p_update_seq
        AND DA.UPDATE_DATE = p_update_date
        AND DA.TABLE_NAME = 'T_OLT_LOGIN' 
        AND DA.FIELD_NAME = 'FEE_FLG'
        AND DA.RECORD_SEQ = DD.RECORD_SEQ) FEE_FLG,
DECODE(M.SUSP_STAT,'C',0,(SELECT FIELD_VALUE FROM T_MANY_DETAIL DA 
        WHERE DA.UPDATE_SEQ =  p_update_seq
	    AND DA.UPDATE_DATE = p_update_date
        AND DA.TABLE_NAME = 'T_OLT_LOGIN' 
        AND DA.FIELD_NAME = 'INFO_FEE'
        AND DA.RECORD_SEQ = DD.RECORD_SEQ)) INFO_FEE,
M.CLIENT_NAME, M.BRANCH_CODE,
'N' FLG, DECODE(M.SUSP_STAT,'C','CLOSED','')KETERANGAN,
DECODE(trim(m.client_type_3),'M',v_margin_gla ,v_reg_gla) arap_gla

FROM MST_CLIENT M, T_MANY_DETAIL DD, T_MANY_HEADER HH WHERE DD.UPDATE_SEQ = P_UPDATE_SEQ AND DD.UPDATE_DATE = P_UPDATE_DATE
AND DD.UPDATE_SEQ = HH.UPDATE_SEQ AND DD.UPDATE_DATE = HH.UPDATE_DATE AND DD.TABLE_NAME = 'T_OLT_LOGIN'    
           AND 
	(SELECT FIELD_VALUE FROM T_MANY_DETAIL DA 
        WHERE DA.UPDATE_SEQ = p_update_seq
		AND DA.UPDATE_DATE = p_update_date
		AND DA.TABLE_NAME = 'T_OLT_LOGIN' 
        AND DA.FIELD_NAME = 'CLIENT_CD'
        AND DA.RECORD_SEQ = DD.RECORD_SEQ) = M.CLIENT_CD and 
    (SELECT FIELD_VALUE FROM T_MANY_DETAIL DA 
        WHERE DA.UPDATE_SEQ =  p_update_seq
        AND DA.UPDATE_DATE = p_update_date
        AND DA.TABLE_NAME = 'T_OLT_LOGIN' 
        AND DA.FIELD_NAME = 'INFO_FEE'
        AND DA.RECORD_SEQ = DD.RECORD_SEQ)>0
        AND dd.field_name='PERIOD_END_DATE';
		
BEGIN



  -- v_tal_id := 0;
   v_tot_fee := 0;
   v_ledger_nar := upper('Market Info Fee '||TO_CHAR(p_end_date,'monyyyy'));

    BEGIN
   SELECT dstr1, dstr2  INTO v_Reg_gla, v_margin_gla
			   FROM MST_SYS_PARAM
			   WHERE param_id = 'SP_OLT_FEE_JUR'
			   AND param_cd1 = 'GL_ACCT'
			   AND param_cd2 = 'CLIENT';
EXCEPTION
   WHEN OTHERS THEN
				     v_error_code := -5;
					 v_error_msg :=  SUBSTR('mst_sys_param '|| SQLERRM,1,200);
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
				     v_error_code := -10;
					 v_error_msg :=  SUBSTR('mst_sys_param '|| SQLERRM,1,200);
					 RAISE v_err;
	END;
   
   begin
   select dflg1 into v_sign from mst_sys_param where
   param_id='SYSTEM' and param_cd1='DOC_REF';
   EXCEPTION
   WHEN OTHERS THEN
				     v_error_code := -15;
					 v_error_msg :=  SUBSTR('mst_sys_param '||SQLERRM,1,200);
					 RAISE v_err;
	END;
   record_Seq:=1;
   for jur in csr_jurnal loop
  
	v_tot_fee := v_tot_fee +   jur.info_fee;
   --buat kepala jurnal
   if record_Seq = 1 then
    v_doc_num := Get_Docnum_GL(P_JOURNAL_DATE,'GL');
begin
	Sp_T_JVCHH_Upd(	v_doc_num,
					 v_doc_num,
					'GL',
					P_JOURNAL_DATE,
					NULL,
					NULL,
					'IDR',
					P_TOTAL_FEE,
					v_ledger_nar,
					P_USER_ID,
					SYSDATE,
					NULL,
					P_FOLDER_CD,
					'N',
					--'A',
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
	   			v_error_code := -20;
				v_error_msg :=  SUBSTR('Sp_T_JVCHH_Upd '||SQLERRM,1,200);
				RAISE v_err;
	   END;
	  
    IF v_error_code<0 THEN
    	v_error_code := -25;
				v_error_msg :=  SUBSTR('Sp_T_JVCHH_Upd '||v_error_msg||' '||SQLERRM,1,200);
				RAISE v_err;
    END IF;
 
		end if;
	--end kepala jurnal

--buat jurnal untuk debit
if v_sign ='Y' THEN
v_doc_ref :=v_doc_num;
END IF;

 begin
SELECT acct_type into v_acct_type FROM MST_CLIENT c,mst_gl_account m WHERE client_cd = sl_a and sl_a=JUR.CLIENT_CD and trim(gl_a)= trim(JUR.ARAP_GLA);
 EXCEPTION
   WHEN OTHERS THEN
				     v_error_code := -30;
					 v_error_msg :=  SUBSTR('mst_sys_param '||SQLERRM,1,200);
					 RAISE v_err;
	END;
	
for i in 1..2 loop
  -- v_tal_id := i;
	if i=1 then
	v_db_cr_flg :='D';
	else
	v_db_cr_flg :='C';
	end if;
begin
Sp_T_ACCOUNT_LEDGER_Upd(v_doc_num,
						record_Seq,
						v_doc_num,
						record_Seq,
						v_doc_ref,
						v_acct_type,
						JUR.CLIENT_CD,
						JUR.ARAP_GLA,
						NULL,
						NULL,
						'IDR',
						NULL,
						JUR.INFO_FEE,
						JUR.INFO_FEE,
						'GL',
						v_db_cr_flg,
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
						P_FOLDER_CD,
						NULL,
						NULL,
						NULL,
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
						record_Seq,
						v_error_code,
						v_error_msg); 
	 EXCEPTION
 	    WHEN OTHERS THEN
	   			v_error_code := -35;
				v_error_msg :=  SUBSTR('Sp_T_ACCOUNT_LEDGER_Upd '||SQLERRM,1,200);
				RAISE v_err;
	   END;
	
    IF v_error_code<0 THEN
    	v_error_code := -40;
				v_error_msg :=  SUBSTR('Sp_T_ACCOUNT_LEDGER_Upd '||v_error_msg||' '||SQLERRM,1,200);
				RAISE v_err;
    END IF;
      record_Seq := record_Seq+1;
   end loop;
   
end loop;

		
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
       -- Consider logging the error and then re-raise
	    ROLLBACK;
		p_error_code := -1;
		p_error_msg := SUBSTR(SQLERRM,1,200);
		RAISE;		
							
END SP_GENERATE_MARKET_INFO_FEE;