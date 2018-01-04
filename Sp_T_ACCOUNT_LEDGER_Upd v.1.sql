create or replace 
PROCEDURE Sp_T_ACCOUNT_LEDGER_Upd(
	P_SEARCH_XN_DOC_NUM		T_ACCOUNT_LEDGER.XN_DOC_NUM%TYPE,
	P_SEARCH_TAL_ID		T_ACCOUNT_LEDGER.TAL_ID%TYPE,
	P_XN_DOC_NUM		T_ACCOUNT_LEDGER.XN_DOC_NUM%TYPE,
	P_TAL_ID		T_ACCOUNT_LEDGER.TAL_ID%TYPE,
	P_DOC_REF_NUM		T_ACCOUNT_LEDGER.DOC_REF_NUM%TYPE,
	P_ACCT_TYPE		T_ACCOUNT_LEDGER.ACCT_TYPE%TYPE,
	P_SL_ACCT_CD		T_ACCOUNT_LEDGER.SL_ACCT_CD%TYPE,
	P_GL_ACCT_CD		T_ACCOUNT_LEDGER.GL_ACCT_CD%TYPE,
	P_CHRG_CD		T_ACCOUNT_LEDGER.CHRG_CD%TYPE,
	P_CHQ_SNO		T_ACCOUNT_LEDGER.CHQ_SNO%TYPE,
	P_CURR_CD		T_ACCOUNT_LEDGER.CURR_CD%TYPE,
	P_BRCH_CD		T_ACCOUNT_LEDGER.BRCH_CD%TYPE,
	P_CURR_VAL		T_ACCOUNT_LEDGER.CURR_VAL%TYPE,
	P_XN_VAL		T_ACCOUNT_LEDGER.XN_VAL%TYPE,
	P_BUDGET_CD		T_ACCOUNT_LEDGER.BUDGET_CD%TYPE,
	P_DB_CR_FLG		T_ACCOUNT_LEDGER.DB_CR_FLG%TYPE,
	P_LEDGER_NAR		T_ACCOUNT_LEDGER.LEDGER_NAR%TYPE,
	P_CASHIER_ID		T_ACCOUNT_LEDGER.CASHIER_ID%TYPE,
	P_USER_ID		T_ACCOUNT_LEDGER.USER_ID%TYPE,
	P_CRE_DT		T_ACCOUNT_LEDGER.CRE_DT%TYPE,
	P_UPD_DT		T_ACCOUNT_LEDGER.UPD_DT%TYPE,
	P_DOC_DATE		T_ACCOUNT_LEDGER.DOC_DATE%TYPE,
	P_DUE_DATE		T_ACCOUNT_LEDGER.DUE_DATE%TYPE,
	P_NETTING_DATE		T_ACCOUNT_LEDGER.NETTING_DATE%TYPE,
	P_NETTING_FLG		T_ACCOUNT_LEDGER.NETTING_FLG%TYPE,
	P_RECORD_SOURCE		T_ACCOUNT_LEDGER.RECORD_SOURCE%TYPE,
	P_SETT_FOR_CURR		T_ACCOUNT_LEDGER.SETT_FOR_CURR%TYPE,
	P_SETT_STATUS		T_ACCOUNT_LEDGER.SETT_STATUS%TYPE,
	P_RVPV_NUMBER		T_ACCOUNT_LEDGER.RVPV_NUMBER%TYPE,
	P_FOLDER_CD		T_ACCOUNT_LEDGER.FOLDER_CD%TYPE,
	P_SETT_VAL		T_ACCOUNT_LEDGER.SETT_VAL%TYPE,
	P_ARAP_DUE_DATE		T_ACCOUNT_LEDGER.ARAP_DUE_DATE%TYPE,
	P_RVPV_GSSL		T_ACCOUNT_LEDGER.RVPV_GSSL%TYPE,
	P_UPD_STATUS					T_MANY_DETAIL.UPD_STATUS%TYPE,
	p_ip_address					T_MANY_HEADER.IP_ADDRESS%TYPE,
	p_cancel_reason					T_MANY_HEADER.CANCEL_REASON%TYPE,
	p_update_date					T_MANY_HEADER.UPDATE_DATE%TYPE,
	p_update_seq					T_MANY_HEADER.UPDATE_SEQ%TYPE,
	p_record_seq					T_MANY_DETAIL.RECORD_SEQ%TYPE,
	p_error_code					OUT			NUMBER,
	p_error_msg						OUT			VARCHAR2
) IS



	v_err EXCEPTION;
	v_error_code				NUMBER;
	v_error_msg					VARCHAR2(1000);
	v_table_name 				T_MANY_DETAIL.table_name%TYPE := 'T_ACCOUNT_LEDGER';
	v_status        		    T_MANY_DETAIL.upd_status%TYPE;
	v_table_rowid	   			T_MANY_DETAIL.table_rowid%TYPE;

CURSOR csr_MANY_DETAIL IS
SELECT      column_id, column_name AS field_name,
                       DECODE(data_type,'VARCHAR2','S','CHAR','S','NUMBER','N','DATE','D','X') AS field_type
FROM all_tab_columns
WHERE table_name =v_table_name
AND OWNER = 'IPNEXTG';

CURSOR csr_table IS
SELECT *
FROM T_ACCOUNT_LEDGER
WHERE XN_DOC_NUM = P_SEARCH_XN_DOC_NUM
 AND TAL_ID= P_SEARCH_TAL_ID;

v_MANY_DETAIL  Types.MANY_DETAIL_rc;

v_rec T_ACCOUNT_LEDGER%ROWTYPE;

v_cnt INTEGER;
 i INTEGER;
 V_FIELD_CNT NUMBER;
 v_pending_cnt NUMBER;
 va CHAR(1) := '@';
BEGIN

IF P_UPD_STATUS = 'I' AND (P_SEARCH_XN_DOC_NUM <> p_XN_DOC_NUM OR P_SEARCH_TAL_ID <> P_TAL_ID) THEN
		v_error_code := -2001; 
		v_error_msg := 'jika INSERT, P_SEARCH_XN_DOC_NUM harus sama dengan P_XN_DOC_NUM';
		RAISE v_err;
	END IF;
	

    BEGIN
		SELECT ROWID INTO v_table_rowid
		FROM T_ACCOUNT_LEDGER
		WHERE XN_DOC_NUM = p_search_XN_DOC_NUM
		AND TAL_ID = P_search_TAL_ID;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			v_table_rowid := NULL;
		WHEN OTHERS THEN
			v_error_code := -2;
			v_error_msg :=  SUBSTR('Retrieve  '|| v_table_name||' for '||P_SEARCH_XN_DOC_NUM||SQLERRM,1,200);
			RAISE v_err;
	END;
	
	IF 	P_UPD_STATUS = 'I' AND v_table_rowid IS NOT NULL THEN
		v_error_code := -2003;
		v_error_msg  := 'DUPLICATED XN_DOC_NUM AND TAL_ID';
		RAISE v_err;
	END IF;
	
	IF 	P_UPD_STATUS = 'U' AND (P_SEARCH_XN_DOC_NUM <> p_XN_DOC_NUM OR P_SEARCH_TAL_ID <> P_TAL_ID)  THEN
		BEGIN
	   	 	SELECT COUNT(1) INTO v_cnt
			FROM T_ACCOUNT_LEDGER
			WHERE XN_DOC_NUM = p_search_XN_DOC_NUM
			AND TAL_ID =P_SEARCH_TAL_ID;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				v_cnt := 0;
			WHEN OTHERS THEN
				v_error_code := -3;
				v_error_msg :=  SUBSTR('Retrieve  '|| v_table_name||' for '||p_XN_DOC_NUM||SQLERRM,1,200);
				RAISE v_err;
		END; 
				  
		IF v_cnt  > 0 THEN
			v_error_code := -2004;
			v_error_msg  := 'DUPLICATED XN_DOC_NUM AND TAL_ID';
			RAISE v_err;
		END IF;
	END IF;	

	--OPEN csr_Table;
--	FETCH csr_Table INTO v_rec;	  
			  
	IF v_table_rowid IS NULL THEN
		BEGIN
				SELECT COUNT(1) INTO v_pending_cnt
			FROM (SELECT MAX(XN_DOC_NUM) XN_DOC_NUM,MAX(TAL_ID) TAL_ID
				  FROM (SELECT DECODE (field_name, 'XN_DOC_NUM', field_value, NULL) XN_DOC_NUM,
							 DECODE (field_name, 'TAL_ID', field_value, NULL) TAL_ID,
							   d.update_seq, record_seq, field_name
						FROM T_MANY_DETAIL D, T_MANY_HEADER H
						WHERE d.table_name = v_table_name
						AND d.update_date = h.update_date
						AND d.update_seq = h.update_seq
						AND d.field_name IN ('XN_DOC_NUM','TAL_ID')
						AND h.APPROVED_status = 'E'
						ORDER BY d.update_seq, record_seq, field_name)
						GROUP BY update_seq, record_seq)	-- Agar SELECT MAX dapat me-retrieve composite primary key untuk setiap record
			WHERE XN_DOC_NUM = P_SEARCH_XN_DOC_NUM
			AND TAL_ID=P_SEARCH_TAL_ID;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				v_pending_cnt := 0;
			WHEN OTHERS THEN
				v_error_code := -4;
				v_error_msg :=  SUBSTR('Retrieve T_MANY_HEADER for '|| v_table_name||SQLERRM,1,200);
				RAISE v_err;
		END;
	ELSE
		BEGIN
			SELECT COUNT(1) INTO v_pending_cnt
			FROM T_MANY_HEADER H, T_MANY_DETAIL D
			WHERE d.table_name = v_table_name
			AND h.update_seq = d.update_seq
			AND d.table_rowid = v_table_rowid
			AND h.APPROVED_status <> 'A'
			AND h.APPROVED_status <> 'R';
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				v_pending_cnt := 0;
			WHEN OTHERS THEN
				v_error_code := -5;
				v_error_msg :=  SUBSTR('Retrieve T_MANY_HEADER for '|| v_table_name||SQLERRM,1,200);
				RAISE v_err;
			END;
	END IF;

	IF  v_pending_cnt > 0 THEN
		v_error_code := -6;
		v_error_msg := 'Masih ada yang belum di-approve';
		RAISE v_err;
	END IF;

	OPEN csr_Table;
	FETCH csr_Table INTO v_rec;

	OPEN v_MANY_DETAIL FOR
		SELECT p_update_date AS update_date, p_update_seq AS update_seq, table_name, p_record_seq AS record_seq, v_table_rowid AS table_rowid, a.field_name,  field_type, b.field_value, p_upd_status AS status,  b.upd_flg
		FROM(
			SELECT  v_table_name AS table_name, column_name AS field_name, DECODE(data_type,'VARCHAR2','S','CHAR','S','NUMBER','N','DATE','D','X') AS field_type
			FROM all_tab_columns
			WHERE table_name = v_table_name
			AND OWNER = 'IPNEXTG') a,
		( 
			SELECT  'XN_DOC_NUM'  AS field_name, p_XN_DOC_NUM AS field_value, DECODE(trim(v_rec.XN_DOC_NUM), trim(p_XN_DOC_NUM),'N','Y') upd_flg FROM dual
UNION
SELECT  'TAL_ID'  AS field_name, TO_CHAR(p_TAL_ID)  AS field_value, DECODE(v_rec.TAL_ID, p_TAL_ID,'N','Y') upd_flg FROM dual
UNION
SELECT  'DOC_REF_NUM'  AS field_name, p_DOC_REF_NUM AS field_value, DECODE(trim(v_rec.DOC_REF_NUM), trim(p_DOC_REF_NUM),'N','Y') upd_flg FROM dual
UNION
SELECT  'ACCT_TYPE'  AS field_name, p_ACCT_TYPE AS field_value, DECODE(trim(v_rec.ACCT_TYPE), trim(p_ACCT_TYPE),'N','Y') upd_flg FROM dual
UNION
SELECT  'SL_ACCT_CD'  AS field_name, p_SL_ACCT_CD AS field_value, DECODE(trim(v_rec.SL_ACCT_CD), trim(p_SL_ACCT_CD),'N','Y') upd_flg FROM dual
UNION
SELECT  'GL_ACCT_CD'  AS field_name, p_GL_ACCT_CD AS field_value, DECODE(trim(v_rec.GL_ACCT_CD), trim(p_GL_ACCT_CD),'N','Y') upd_flg FROM dual
UNION
SELECT  'CHRG_CD'  AS field_name, p_CHRG_CD AS field_value, DECODE(trim(v_rec.CHRG_CD), trim(p_CHRG_CD),'N','Y') upd_flg FROM dual
UNION
SELECT  'CHQ_SNO'  AS field_name, TO_CHAR(p_CHQ_SNO)  AS field_value, DECODE(v_rec.CHQ_SNO, p_CHQ_SNO,'N','Y') upd_flg FROM dual
UNION
SELECT  'CURR_CD'  AS field_name, p_CURR_CD AS field_value, DECODE(trim(v_rec.CURR_CD), trim(p_CURR_CD),'N','Y') upd_flg FROM dual
UNION
SELECT  'BRCH_CD'  AS field_name, p_BRCH_CD AS field_value, DECODE(trim(v_rec.BRCH_CD), trim(p_BRCH_CD),'N','Y') upd_flg FROM dual
UNION
SELECT  'CURR_VAL'  AS field_name, TO_CHAR(p_CURR_VAL)  AS field_value, DECODE(v_rec.CURR_VAL, p_CURR_VAL,'N','Y') upd_flg FROM dual
UNION
SELECT  'XN_VAL'  AS field_name, TO_CHAR(p_XN_VAL)  AS field_value, DECODE(v_rec.XN_VAL, p_XN_VAL,'N','Y') upd_flg FROM dual
UNION
SELECT  'BUDGET_CD'  AS field_name, p_BUDGET_CD AS field_value, DECODE(trim(v_rec.BUDGET_CD), trim(p_BUDGET_CD),'N','Y') upd_flg FROM dual
UNION
SELECT  'DB_CR_FLG'  AS field_name, p_DB_CR_FLG AS field_value, DECODE(trim(v_rec.DB_CR_FLG), trim(p_DB_CR_FLG),'N','Y') upd_flg FROM dual
UNION
SELECT  'LEDGER_NAR'  AS field_name, p_LEDGER_NAR AS field_value, DECODE(trim(v_rec.LEDGER_NAR), trim(p_LEDGER_NAR),'N','Y') upd_flg FROM dual
UNION
SELECT  'CASHIER_ID'  AS field_name, p_CASHIER_ID AS field_value, DECODE(trim(v_rec.CASHIER_ID), trim(p_CASHIER_ID),'N','Y') upd_flg FROM dual
UNION
SELECT  'DOC_DATE'  AS field_name, TO_CHAR(p_DOC_DATE,'yyyy/mm/dd hh24:mi:ss')  AS field_value, DECODE(v_rec.DOC_DATE, p_DOC_DATE,'N','Y') upd_flg FROM dual
UNION
SELECT  'DUE_DATE'  AS field_name, TO_CHAR(p_DUE_DATE,'yyyy/mm/dd hh24:mi:ss')  AS field_value, DECODE(v_rec.DUE_DATE, p_DUE_DATE,'N','Y') upd_flg FROM dual
UNION
SELECT  'NETTING_DATE'  AS field_name, TO_CHAR(p_NETTING_DATE,'yyyy/mm/dd hh24:mi:ss')  AS field_value, DECODE(v_rec.NETTING_DATE, p_NETTING_DATE,'N','Y') upd_flg FROM dual
UNION
SELECT  'NETTING_FLG'  AS field_name, p_NETTING_FLG AS field_value, DECODE(trim(v_rec.NETTING_FLG), trim(p_NETTING_FLG),'N','Y') upd_flg FROM dual
UNION
SELECT  'RECORD_SOURCE'  AS field_name, p_RECORD_SOURCE AS field_value, DECODE(trim(v_rec.RECORD_SOURCE), trim(p_RECORD_SOURCE),'N','Y') upd_flg FROM dual
UNION
SELECT  'SETT_FOR_CURR'  AS field_name, TO_CHAR(p_SETT_FOR_CURR)  AS field_value, DECODE(v_rec.SETT_FOR_CURR, p_SETT_FOR_CURR,'N','Y') upd_flg FROM dual
UNION
SELECT  'SETT_STATUS'  AS field_name, p_SETT_STATUS AS field_value, DECODE(trim(v_rec.SETT_STATUS), trim(p_SETT_STATUS),'N','Y') upd_flg FROM dual
UNION
SELECT  'RVPV_NUMBER'  AS field_name, p_RVPV_NUMBER AS field_value, DECODE(trim(v_rec.RVPV_NUMBER), trim(p_RVPV_NUMBER),'N','Y') upd_flg FROM dual
UNION
SELECT  'FOLDER_CD'  AS field_name, p_FOLDER_CD AS field_value, DECODE(trim(v_rec.FOLDER_CD), trim(p_FOLDER_CD),'N','Y') upd_flg FROM dual
UNION
SELECT  'SETT_VAL'  AS field_name, TO_CHAR(p_SETT_VAL)  AS field_value, DECODE(v_rec.SETT_VAL, p_SETT_VAL,'N','Y') upd_flg FROM dual
UNION
SELECT  'ARAP_DUE_DATE'  AS field_name, TO_CHAR(p_ARAP_DUE_DATE,'yyyy/mm/dd hh24:mi:ss')  AS field_value, DECODE(v_rec.ARAP_DUE_DATE, p_ARAP_DUE_DATE,'N','Y') upd_flg FROM dual
UNION
SELECT  'RVPV_GSSL'  AS field_name, p_RVPV_GSSL AS field_value, DECODE(trim(v_rec.RVPV_GSSL), trim(p_RVPV_GSSL),'N','Y') upd_flg FROM dual
UNION
			
			SELECT  'CRE_DT'  AS field_name, TO_CHAR(SYSDATE,'yyyy/mm/dd hh24:mi:ss')  AS field_value, 'Y' upd_flg FROM dual
					WHERE P_UPD_STATUS = 'I'
			UNION
			SELECT  'USER_ID'  AS field_name, p_USER_ID AS field_value, 'Y' upd_flg FROM dual
					WHERE P_UPD_STATUS = 'I'
			UNION
			SELECT  'UPD_DT'  AS field_name, TO_CHAR(SYSDATE,'yyyy/mm/dd hh24:mi:ss')  AS field_value, 'Y' upd_flg FROM dual
					WHERE P_UPD_STATUS = 'U'
		
		) b
		WHERE a.field_name = b.field_name;
		 
	IF v_table_rowid IS NOT NULL THEN
	    IF P_UPD_STATUS = 'C' THEN
		   	v_status := 'C';
		ELSE
	       	v_status := 'U';
		END IF;
	ELSE
		v_status := 'I';
	END IF;


	BEGIN
		Sp_T_Many_Detail_Insert(p_update_date,   p_update_seq,   v_status, v_table_name, p_record_seq , v_table_rowid, v_MANY_DETAIL, v_error_code, v_error_msg);
	EXCEPTION
		WHEN OTHERS THEN
			v_error_code := -7;
			v_error_msg := SUBSTR('SP_T_MANY_DETAIL_INSERT '||v_table_name||SQLERRM,1,200);
			RAISE v_err;
	END;

	CLOSE v_MANY_DETAIL;
	CLOSE csr_Table;

	IF v_error_code < 0 THEN
	    v_error_code := -8;
		v_error_msg := 'SP_T_MANY_DETAIL_INSERT '||v_table_name||' '||v_error_msg;
		RAISE v_err;
	END IF;


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

END Sp_T_ACCOUNT_LEDGER_Upd;