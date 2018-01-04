create or replace 
PROCEDURE SP_T_OLT_LOGIN_UPD(
	P_SEARCH_PERIOD_END_DATE		T_OLT_LOGIN.PERIOD_END_DATE%TYPE,
	P_SEARCH_OLT_USER_ID		T_OLT_LOGIN.OLT_USER_ID%TYPE,
	P_SEARCH_CLIENT_CD		T_OLT_LOGIN.CLIENT_CD%TYPE,
	P_PERIOD_END_DATE		T_OLT_LOGIN.PERIOD_END_DATE%TYPE,
	P_OLT_USER_ID		T_OLT_LOGIN.OLT_USER_ID%TYPE,
	P_ACCESSFLAG		T_OLT_LOGIN.ACCESSFLAG%TYPE,
	P_CLIENT_TYPE		T_OLT_LOGIN.CLIENT_TYPE%TYPE,
	P_USER_STAT		T_OLT_LOGIN.USER_STAT%TYPE,
	P_CLIENT_CD		T_OLT_LOGIN.CLIENT_CD%TYPE,
	P_FEE_FLG		T_OLT_LOGIN.FEE_FLG%TYPE,
	P_INFO_FEE		T_OLT_LOGIN.INFO_FEE%TYPE,
	P_CRE_DT		T_OLT_LOGIN.CRE_DT%TYPE,
	P_USER_ID		T_OLT_LOGIN.USER_ID%TYPE,
	P_UPD_DT		T_OLT_LOGIN.UPD_DT%TYPE,
	P_UPD_BY		T_OLT_LOGIN.UPD_BY%TYPE,
	P_UPD_STATUS					T_MANY_DETAIL.UPD_STATUS%TYPE,
	p_ip_address					T_MANY_HEADER.IP_ADDRESS%TYPE,
	p_cancel_reason					T_MANY_HEADER.CANCEL_REASON%TYPE,
	p_update_date					T_MANY_HEADER.UPDATE_DATE%TYPE,
	p_update_seq					T_MANY_HEADER.UPDATE_SEQ%TYPE,
	p_record_seq					T_MANY_DETAIL.RECORD_SEQ%TYPE,
	p_error_code					OUT			NUMBER,
	p_error_msg						OUT			VARCHAR2
) IS



 v_reg_gla T_ACCOUNT_LEDGER.GL_ACCT_CD%TYPE;
 v_margin_gla T_ACCOUNT_LEDGER.GL_ACCT_CD%TYPE;
 v_ledger_nar  T_ACCOUNT_LEDGER.Ledger_nar%TYPE;
 v_tal_id NUMBER;
 v_tot_fee  NUMBER;
  v_fee_gla  T_ACCOUNT_LEDGER.GL_ACCT_CD%TYPE;
   v_fee_sla T_ACCOUNT_LEDGER.SL_ACCT_CD%TYPE;
  v_doc_num T_ACCOUNT_LEDGER.xn_doc_num%TYPE;
	v_err EXCEPTION;
	v_error_code				NUMBER;
	v_error_msg					VARCHAR2(1000);
	v_table_name 				T_MANY_DETAIL.table_name%TYPE := 'T_OLT_LOGIN';
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
FROM T_OLT_LOGIN
WHERE PERIOD_END_DATE = P_SEARCH_PERIOD_END_DATE
AND OLT_USER_ID = P_SEARCH_OLT_USER_ID
AND CLIENT_CD = P_SEARCH_CLIENT_CD;

v_MANY_DETAIL  Types.MANY_DETAIL_rc;

v_rec T_OLT_LOGIN%ROWTYPE;

v_cnt INTEGER;
 i INTEGER;
 V_FIELD_CNT NUMBER;
 v_pending_cnt NUMBER;
 va CHAR(1) := '@';
BEGIN

IF P_UPD_STATUS = 'I' AND (P_SEARCH_PERIOD_END_DATE <> P_PERIOD_END_DATE OR P_SEARCH_OLT_USER_ID <> P_OLT_USER_ID OR P_SEARCH_CLIENT_CD <> P_CLIENT_CD ) THEN
		IF P_SEARCH_PERIOD_END_DATE <> P_PERIOD_END_DATE THEN
			v_error_code := -2001;
			v_error_msg := 'jika INSERT, P_SEARCH_PERIOD_END_DATE harus sama dengan P_PERIOD_END_DATE';
			RAISE v_err;
		END IF;
		IF P_SEARCH_OLT_USER_ID <> P_OLT_USER_ID THEN
			v_error_code := -2002;
			v_error_msg := 'jika INSERT, P_SEARCH_OLT_USER_ID harus sama dengan P_OLT_USER_ID ';
			RAISE v_err;
		END IF;
		IF P_SEARCH_CLIENT_CD <> P_CLIENT_CD THEN
			v_error_code := -2003;
			v_error_msg := 'jika INSERT, P_SEARCH_CLIENT_CD harus sama dengan CLIENT_CD ';
			RAISE v_err;
		END IF;
	END IF;
	

    BEGIN
		SELECT ROWID INTO v_table_rowid
		FROM T_OLT_LOGIN
		WHERE  PERIOD_END_DATE = P_SEARCH_PERIOD_END_DATE
				AND OLT_USER_ID = P_SEARCH_OLT_USER_ID
				AND CLIENT_CD = P_SEARCH_CLIENT_CD;
		
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			v_table_rowid := NULL;
		WHEN OTHERS THEN
			v_error_code := -2;
			v_error_msg :=  SUBSTR('Retrieve  '|| v_table_name||' for '||P_SEARCH_PERIOD_END_DATE||SQLERRM,1,200);
			RAISE v_err;
	END;
	
	IF 	P_UPD_STATUS = 'I' AND v_table_rowid IS NOT NULL THEN
		v_error_code := -2003;
		v_error_msg  := 'DUPLICATED PERIOD_END_DATE';
		RAISE v_err;
	END IF;
	


	--OPEN csr_Table;
--	FETCH csr_Table INTO v_rec;	  
			  
	
	IF v_table_rowid IS NULL THEN
		BEGIN
			SELECT COUNT(1) INTO v_pending_cnt
			FROM (SELECT MAX(PERIOD_END_DATE) PERIOD_END_DATE, MAX(OLT_USER_ID) OLT_USER_ID, MAX(CLIENT_CD) CLIENT_CD
				  FROM (SELECT DECODE (field_name, 'PERIOD_END_DATE', field_value, NULL) PERIOD_END_DATE,
							   DECODE (field_name, 'OLT_USER_ID', field_value, NULL) OLT_USER_ID,
							   DECODE (field_name, 'CLIENT_CD', field_value, NULL) CLIENT_CD,
							   d.update_seq, record_seq, field_name
						FROM T_MANY_DETAIL D, T_MANY_HEADER H
						WHERE d.table_name = v_table_name
						AND d.update_date = h.update_date
						AND d.update_seq = h.update_seq
						AND (d.field_name = 'PERIOD_END_DATE' OR d.field_name = 'OLT_USER_ID' OR d.field_name = 'CLIENT_CD')
						AND h.APPROVED_status = 'E'
						ORDER BY d.update_seq, record_seq, field_name)
						GROUP BY update_seq, record_seq)	-- Agar SELECT MAX dapat me-retrieve composite primary key untuk setiap record
			WHERE PERIOD_END_DATE = P_SEARCH_PERIOD_END_DATE
			AND OLT_USER_ID = P_SEARCH_OLT_USER_ID
				AND CLIENT_CD = P_SEARCH_CLIENT_CD;
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
			AND OWNER = 'IPNEXTG'
--			 UNION
--		SELECT v_table_name, 'JOURNAL_DATE', 'D' FROM dual
--		UNION
--		SELECT v_table_name, 'FOLDER_CD', 'S' FROM dual
--    	UNION
--		SELECT v_table_name, 'FLG', 'S' FROM dual
    --	UNION
	--	SELECT v_table_name, 'TOTAL_FEE', 'N' FROM dual
			
			) a,
		( 

		
			SELECT  'PERIOD_END_DATE'  AS field_name, TO_CHAR(p_PERIOD_END_DATE,'yyyy/mm/dd hh24:mi:ss')  AS field_value, DECODE(v_rec.PERIOD_END_DATE, p_PERIOD_END_DATE,'N','Y') upd_flg FROM dual
			UNION
			SELECT  'OLT_USER_ID'  AS field_name, p_OLT_USER_ID AS field_value, DECODE(trim(v_rec.OLT_USER_ID), trim(p_OLT_USER_ID),'N','Y') upd_flg FROM dual
			UNION
			SELECT  'ACCESSFLAG'  AS field_name, p_ACCESSFLAG AS field_value, DECODE(trim(v_rec.ACCESSFLAG), trim(p_ACCESSFLAG),'N','Y') upd_flg FROM dual
			UNION
			SELECT  'CLIENT_TYPE'  AS field_name, p_CLIENT_TYPE AS field_value, DECODE(trim(v_rec.CLIENT_TYPE), trim(p_CLIENT_TYPE),'N','Y') upd_flg FROM dual
			UNION
			SELECT  'USER_STAT'  AS field_name, p_USER_STAT AS field_value, DECODE(trim(v_rec.USER_STAT), trim(p_USER_STAT),'N','Y') upd_flg FROM dual
			UNION
			SELECT  'CLIENT_CD'  AS field_name, p_CLIENT_CD AS field_value, DECODE(trim(v_rec.CLIENT_CD), trim(p_CLIENT_CD),'N','Y') upd_flg FROM dual
			UNION
			SELECT  'FEE_FLG'  AS field_name, p_FEE_FLG AS field_value, DECODE(trim(v_rec.FEE_FLG), trim(p_FEE_FLG),'N','Y') upd_flg FROM dual
			UNION
			SELECT  'INFO_FEE'  AS field_name, TO_CHAR(p_INFO_FEE)  AS field_value, DECODE(v_rec.INFO_FEE, p_INFO_FEE,'N','Y') upd_flg FROM dual
			UNION
			SELECT  'CRE_DT'  AS field_name, TO_CHAR(p_CRE_DT,'yyyy/mm/dd hh24:mi:ss')  AS field_value, DECODE(v_rec.CRE_DT, p_CRE_DT,'N','Y') upd_flg FROM dual
			WHERE P_UPD_STATUS = 'I'
			UNION
			SELECT  'USER_ID'  AS field_name, p_USER_ID AS field_value, DECODE(trim(v_rec.USER_ID), trim(p_USER_ID),'N','Y') upd_flg FROM dual
			WHERE P_UPD_STATUS = 'I'
			UNION
			SELECT  'UPD_DT'  AS field_name, TO_CHAR(p_UPD_DT,'yyyy/mm/dd hh24:mi:ss')  AS field_value, DECODE(v_rec.UPD_DT, p_UPD_DT,'N','Y') upd_flg FROM dual
			WHERE P_UPD_STATUS = 'U'
			UNION
			SELECT  'UPD_BY'  AS field_name, p_UPD_BY AS field_value, DECODE(trim(v_rec.UPD_BY), trim(p_UPD_BY),'N','Y') upd_flg FROM dual
			WHERE P_UPD_STATUS = 'U'
		) b
	WHERE a.field_name = b.field_name
		AND  (P_UPD_STATUS <> 'C' OR (P_UPD_STATUS = 'C' AND a.field_name = 'CLIENT_CD'));
		 
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
		v_error_msg := 'SP_T_MANY_DETAIL_INSERT'||v_table_name||' '||v_error_msg;
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

END SP_T_OLT_LOGIN_UPD;