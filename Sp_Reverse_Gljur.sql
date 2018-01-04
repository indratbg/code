create or replace 
PROCEDURE Sp_Reverse_Gljur(
P_doc_num 		  T_ACCOUNT_LEDGER.xn_doc_num%TYPE,
P_user_id              T_ACCOUNT_LEDGER.user_id%TYPE,
p_error_code					OUT			NUMBER,
p_error_msg					OUT			VARCHAR2)
IS
tmpVar NUMBER;
/******************************************************************************
   NAME:       SP_REVERSE_GLJUR
   PURPOSE:    

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        03/12/2014          1. Created this procedure.

   NOTES:

  

******************************************************************************/
v_doc_num 						T_ACCOUNT_LEDGER.xn_doc_num%TYPE;
 v_doc_date						DATE;
v_folder_Cd						T_ACCOUNT_LEDGER.folder_Cd%TYPE;
 v_hamt 							 T_JVCHH.curr_amt%TYPE;
 v_hremarks                      T_JVCHH.remarks%TYPE;
 
v_err EXCEPTION;
v_error_code							NUMBER;
v_error_msg							VARCHAR2(200);
BEGIN
   tmpVar := 0;
   -- sementara tgl reversal jur SAMA dg tgl jur yg direverse
   -- nantinya = sysdate
   BEGIN
	   SELECT doc_date INTO v_doc_date
	   FROM T_ACCOUNT_LEDGER
	   WHERE xn_doc_num = p_doc_num
	   AND ROWNUM = 1;
   EXCEPTION
   WHEN OTHERS THEN
		v_error_code := -10;
		v_error_msg :=SUBSTR('SELECT v_doc_date FROM T_ACCOUNT_LEDGER: '||SQLERRM,1,200);
   RAISE V_ERR;
   END;
   
   -- nomor reversal jur dari GET DOCNUM GL didlmnya pakai SEQ
     v_doc_num := Get_Docnum_Gl(v_doc_date,'GL');
	 
	-- update field REVERSAL_JUR di 'kepala' jurnal
	-- update approved_sts = C tidak di sp ini . . 
	  
     IF SUBSTR(p_doc_num,5,2) = 'GL' THEN
        BEGIN
			SELECT jvch_date, curr_amt, remarks
			INTO v_doc_date, v_hamt, v_hremarks
			FROM T_JVCHH
			WHERE jvch_num = p_doc_num;
		 EXCEPTION
		WHEN OTHERS THEN
			v_error_code := -20;
			v_error_msg :=SUBSTR('SELECT jvch_date, curr_amt, remarks FROM T_JVCHH: '||SQLERRM,1,200);
		RAISE V_ERR;
		END;
   
		BEGIN
		UPDATE T_JVCHH
		SET REVERSAL_JUR = v_doc_num
		WHERE  jvch_num = p_doc_num;
		EXCEPTION
		WHEN OTHERS THEN
			v_error_code := -30;
			v_error_msg :=SUBSTR('UPDATE T_JVCHH FIELD REVERSAL_JUR'||SQLERRM,1,200);
		RAISE V_ERR;
		END;
		
    END IF;
	
	/* tidak dipakai, di upd via t many
       IF SUBSTR(p_doc_num,5,2) = 'RD' OR SUBSTR(p_doc_num,5,2) = 'PD' OR
	       SUBSTR(p_doc_num,5,2) = 'RV'  OR SUBSTR(p_doc_num,5,2) = 'PV' THEN
        
		SELECT payrec_date, curr_amt, remarks
		INTO v_doc_date, v_hamt, v_hremarks
		FROM T_PAYRECH
		WHERE payrec_num = p_doc_num;
		
		UPDATE T_PAYRECH
		SET REVERSAL_JUR = v_doc_num
		WHERE  payrec_num = p_doc_num;
    END IF;
	*/
 
    IF SUBSTR(p_doc_num,5,2) IN ( 'BR','JR','BI','JI')  THEN
	   BEGIN
			SELECT   contr_dt, amt_for_curr, client_cd||' '||SUBSTR(contr_num,5,1)||' '||stk_cd||' @'||TO_CHAR(price) AS remarks
			INTO  v_doc_date, v_hamt, v_hremarks
			FROM T_CONTRACTS
			WHERE contr_num = p_doc_num;
		EXCEPTION
		WHEN OTHERS THEN
			v_error_code := -40;
			v_error_msg :=SUBSTR('SELECT T_CONTRACTS '||SQLERRM,1,200);
		RAISE V_ERR;
		END;
		
		BEGIN
			UPDATE T_CONTRACTS
			SET REVERSAL_JUR = v_doc_num
			WHERE  contr_num = p_doc_num;
		EXCEPTION
		WHEN OTHERS THEN
			v_error_code := -50;
			v_error_msg :=SUBSTR('UPDATE T_CONTRACTS FIELD REVERSAL_JUR'||SQLERRM,1,200);
		RAISE V_ERR;
		END;
		
	END IF;
   
   
   IF SUBSTR(p_doc_num,5,2) IN ( 'BO','JO')  THEN
		BEGIN
			SELECT    trx_date, net_amount, DECODE(trx_type,'B','BUY ','SELL ')||bond_cd||' @'||TO_CHAR(price) AS remarks
			INTO  v_doc_date, v_hamt, v_hremarks
			FROM T_BOND_TRX
			WHERE doc_num = p_doc_num;
		EXCEPTION
		WHEN OTHERS THEN
			v_error_code := -60;
			v_error_msg :=SUBSTR('SELECT T_BOND_TRX'||SQLERRM,1,200);
		RAISE V_ERR;
		END;
		
		BEGIN
		UPDATE T_BOND_TRX
		SET REVERSAL_DOC_NUM = v_doc_num
		WHERE  doc_num = p_doc_num;
		EXCEPTION
		WHEN OTHERS THEN
			v_error_code := -70;
			v_error_msg :=SUBSTR('UPDATE T_BOND_TRX FIELD REVERSAL_DOC_NUM'||SQLERRM,1,200);
		RAISE V_ERR;
		END;
		
	END IF;
	
	  IF SUBSTR(p_doc_num,5,2) IN ( 'DN','CN') THEN
        BEGIN
			SELECT dncn_date, curr_val, ledger_nar
			INTO v_doc_date, v_hamt, v_hremarks
			FROM T_DNCNH
			WHERE dncn_num = p_doc_num;
			EXCEPTION
		WHEN OTHERS THEN
			v_error_code := -80;
			v_error_msg :=SUBSTR('SELECT T_DNCNH'||SQLERRM,1,200);
		RAISE V_ERR;
		END;
		
		BEGIN
			UPDATE T_DNCNH
			SET REVERSAL_JUR = v_doc_num
			WHERE  dncn_num = p_doc_num;
		EXCEPTION
		WHEN OTHERS THEN
			v_error_code := -90;
			v_error_msg :=SUBSTR('UPDATE T_DNCNH FIELD REVERSAL_JUR'||SQLERRM,1,200);
		RAISE V_ERR;
		END;	
    END IF;
	
	-- upd field REVERSAL_JUR di T_A_L yg direverse
	BEGIN
		UPDATE T_ACCOUNT_LEDGER
		SET REVERSAL_JUR = v_doc_num
		WHERE xn_doc_num = p_doc_num;
	EXCEPTION
	WHEN OTHERS THEN
		v_error_code := -100;
		v_error_msg :=SUBSTR('UPDATE T_ACCOUNT_LEDGER FIELD REVERSAL_JUR'||SQLERRM,1,200);
	RAISE V_ERR;
	END;	
		
  v_folder_cd := Get_Folder_Num(v_doc_date,'RJ-',v_doc_num,p_user_id);
	-- create kepala jurnal reversal, JVCH_TYPE = 'RE'
	BEGIN
		   INSERT INTO IPNEXTG.T_JVCHH (
		   JVCH_NUM, JVCH_TYPE, JVCH_DATE, 
		   GL_ACCT_CD, SL_ACCT_CD, CURR_CD, 
		   CURR_AMT, REMARKS, USER_ID, 
		   CRE_DT, UPD_DT, APPROVED_STS, 
		   APPROVED_BY, APPROVED_DT, FOLDER_CD, 
		   REVERSAL_JUR) 
		VALUES (  v_doc_num, 'RE', v_doc_date,
		   NULL ,NULL, 'IDR',
			v_hamt, v_hremarks, p_user_id,
			SYSDATE, NULL, 'A',
			NULL, NULL, v_folder_cd,NULL );
	EXCEPTION
	WHEN OTHERS THEN
		v_error_code := -110;
		v_error_msg :=SUBSTR('INSERT INTO T_JVCHH'||SQLERRM,1,200);
	RAISE V_ERR;
	END;	
	
	-- create jurnal reversal 
	--               RECORD sOURCE = RE
	--               SETT_VAL = CURR_VAL spy tidak menimbulkan outstanding AR/AP
	--               debit/credit DB_CR_FLG dibalik
	
		BEGIN
			INSERT INTO IPNEXTG.T_ACCOUNT_LEDGER (
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
		   FOLDER_CD, SETT_VAL, ARAP_DUE_DATE, 
		   RVPV_GSSL, REVERSAL_JUR, MANUAL) 
			SELECT v_DOC_NUM, TAL_ID, DOC_REF_NUM, 
		   ACCT_TYPE, SL_ACCT_CD, GL_ACCT_CD, 
		   CHRG_CD, CHQ_SNO, CURR_CD, 
		   BRCH_CD, CURR_VAL, XN_VAL, 
		   BUDGET_CD, DECODE(DB_CR_FLG,'D','C','D') db_cr_flg, LEDGER_NAR, 
		   CASHIER_ID, P_USER_ID, SYSDATE, 
		   NULL, DOC_DATE, DUE_DATE, 
		   NETTING_DATE, NETTING_FLG, 'RE', 
		   SETT_FOR_CURR, SETT_STATUS, RVPV_NUMBER, 
		   'A' , NULL, NULL, 
		   v_FOLDER_CD, CURR_VAL, ARAP_DUE_DATE, 
		   RVPV_GSSL, 'N', 'Y'
		FROM IPNEXTG.T_ACCOUNT_LEDGER
		WHERE xn_doc_num = p_doc_num;
	EXCEPTION
	WHEN OTHERS THEN
		v_error_code := -110;
		v_error_msg :=SUBSTR('INSERT INTO T_ACCOUNT_LEDGER'||SQLERRM,1,200);
	RAISE V_ERR;
	END;	



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
	      ROLLBACK;
	   p_error_code := -1;
	   p_error_msg := SUBSTR(SQLERRM,1,200);
       RAISE;

END Sp_Reverse_Gljur;