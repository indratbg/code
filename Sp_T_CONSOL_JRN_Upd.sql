create or replace 
PROCEDURE Sp_T_CONSOL_JRN_Upd(
	P_SEARCH_DOC_DATE		T_CONSOL_JRN.DOC_DATE%TYPE,
	P_SEARCH_XN_DOC_NUM		T_CONSOL_JRN.XN_DOC_NUM%TYPE,
	P_SEARCH_TAL_ID		T_CONSOL_JRN.TAL_ID%TYPE,
	P_XN_DOC_NUM		T_CONSOL_JRN.XN_DOC_NUM%TYPE,
	P_TAL_ID		T_CONSOL_JRN.TAL_ID%TYPE,
	P_ENTITY		T_CONSOL_JRN.ENTITY%TYPE,
	P_SL_ACCT_CD		T_CONSOL_JRN.SL_ACCT_CD%TYPE,
	P_GL_ACCT_CD		T_CONSOL_JRN.GL_ACCT_CD%TYPE,
	P_CURR_VAL		T_CONSOL_JRN.CURR_VAL%TYPE,
	P_DB_CR_FLG		T_CONSOL_JRN.DB_CR_FLG%TYPE,
	P_LEDGER_NAR		T_CONSOL_JRN.LEDGER_NAR%TYPE,
	P_USER_ID		T_CONSOL_JRN.USER_ID%TYPE,
	P_CRE_DT		T_CONSOL_JRN.CRE_DT%TYPE,
	P_UPD_DT		T_CONSOL_JRN.UPD_DT%TYPE,
	P_DOC_DATE		T_CONSOL_JRN.DOC_DATE%TYPE,
	P_FOLDER_CD		T_CONSOL_JRN.FOLDER_CD%TYPE,
	P_UPD_STATUS					T_MANY_DETAIL.UPD_STATUS%TYPE,
	p_ip_address					T_MANY_HEADER.IP_ADDRESS%TYPE,
	p_cancel_reason					T_MANY_HEADER.CANCEL_REASON%TYPE,
	p_update_date					T_MANY_HEADER.UPDATE_DATE%TYPE,
	p_update_seq					T_MANY_HEADER.UPDATE_SEQ%TYPE,
	p_record_seq					T_MANY_DETAIL.RECORD_SEQ%TYPE,
	p_error_code					OUT			NUMBER,
	p_error_msg						OUT			VARCHAR2
) IS

v_doc_type 						CHAR(3);

v_err EXCEPTION;
v_error_code					NUMBER;
v_error_msg						VARCHAR2(200);
v_table_name 					T_MANY_DETAIL.table_name%TYPE := 'T_CONSOL_JRN';
v_status            			T_MANY_DETAIL.upd_status%TYPE;
v_table_rowid					T_MANY_DETAIL.table_rowid%TYPE;

CURSOR csr_many_detail IS
SELECT  column_id, column_name AS field_name,
                       DECODE(data_type,'VARCHAR2','S','CHAR','S','NUMBER','N','DATE','D','X') AS field_type
FROM all_tab_columns
WHERE table_name =v_table_name
AND OWNER = 'IPNEXTG';

CURSOR csr_table IS
SELECT *
FROM T_CONSOL_JRN
WHERE DOC_DATE= P_SEARCH_DOC_DATE
AND XN_DOC_NUM = P_SEARCH_XN_DOC_NUM
AND TAL_ID = P_SEARCH_TAL_ID;

v_many_detail  Types.many_detail_rc;

v_rec T_CONSOL_JRN%ROWTYPE;

v_cnt INTEGER;
i INTEGER;
V_FIELD_CNT NUMBER;
v_pending_cnt NUMBER;
va CHAR(1) := '@';

BEGIN
	IF P_UPD_STATUS = 'I' AND (P_SEARCH_DOC_DATE <> P_DOC_DATE OR p_search_XN_DOC_NUM <> p_XN_DOC_NUM OR p_search_TAL_ID <> p_TAL_ID) THEN
		IF P_SEARCH_DOC_DATE <> P_DOC_DATE THEN
			v_error_code := -2002;
			v_error_msg := 'jika INSERT, p_search_DOC_DATE harus sama dengan P_DOC_DATE';
			RAISE v_err;
		END IF;
		IF p_search_XN_DOC_NUM <> p_XN_DOC_NUM THEN
			v_error_code := -2001;
			v_error_msg := 'jika INSERT, p_search_XN_DOC_NUM harus sama dengan P_XN_DOC_NUM';
			RAISE v_err;
		END IF;
		IF p_search_TAL_ID <> p_TAL_ID THEN
			v_error_code := -2002;
			v_error_msg := 'jika INSERT, p_search_TAL_ID harus sama dengan P_TAL_ID';
			RAISE v_err;
		END IF;
	END IF;

    BEGIN
		SELECT ROWID INTO v_table_rowid
		FROM T_CONSOL_JRN
		WHERE DOC_DATE= P_SEARCH_DOC_DATE
			AND XN_DOC_NUM = P_SEARCH_XN_DOC_NUM
			AND TAL_ID = P_SEARCH_TAL_ID;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			v_table_rowid := NULL;
		WHEN OTHERS THEN
			v_error_code := -3;
			v_error_msg :=  SUBSTR('Retrieve  '|| v_table_name||' for '||p_search_XN_DOC_NUM||SQLERRM,1,200);
			RAISE v_err;
	END;
	
	IF v_table_rowid IS NULL THEN
		BEGIN
			SELECT COUNT(1) INTO v_pending_cnt
			FROM (SELECT MAX(DOC_DATE) DOC_DATE , MAX(XN_DOC_NUM) XN_DOC_NUM, MAX(TAL_ID) TAL_ID
				  FROM (SELECT DECODE (field_name, 'DOC_DATE', field_value, NULL) DOC_DATE,
								DECODE (field_name, 'XN_DOC_NUM', field_value, NULL) XN_DOC_NUM,
							   DECODE (field_name, 'TAL_ID', field_value, NULL) TAL_ID,
							   d.update_seq, record_seq, field_name
						FROM T_MANY_DETAIL D, T_MANY_HEADER H
						WHERE d.table_name = v_table_name
						AND d.update_date = h.update_date
						AND d.update_seq = h.update_seq
						AND (d.field_name = 'DOC_DATE' OR d.field_name = 'XN_DOC_NUM' OR d.field_name ='TAL_ID')
						AND h.APPROVED_status = 'E'
						ORDER BY d.update_seq, record_seq, field_name)
						GROUP BY update_seq, record_seq)	-- Agar SELECT MAX dapat me-retrieve composite primary key untuk setiap record
			WHERE DOC_DATE= P_SEARCH_DOC_DATE
			AND XN_DOC_NUM = P_SEARCH_XN_DOC_NUM
			AND TAL_ID = P_SEARCH_TAL_ID;
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

	OPEN v_Many_detail FOR
		SELECT p_update_date AS update_date, p_update_seq AS update_seq, table_name, p_record_seq AS record_seq, v_table_rowid AS table_rowid, a.field_name,  field_type, b.field_value, p_upd_status AS status,  b.upd_flg
		FROM(
		 SELECT  v_table_name AS table_name, column_name AS field_name,
		                       					DECODE(data_type,'VARCHAR2','S','CHAR','S','NUMBER','N','DATE','D','X') AS field_type
										FROM all_tab_columns
										WHERE table_name =v_table_name
										AND OWNER = 'IPNEXTG'
		) a,
		(SELECT  'XN_DOC_NUM'  AS field_name, p_XN_DOC_NUM AS field_value, DECODE(trim(v_rec.XN_DOC_NUM), trim(p_XN_DOC_NUM),'N','Y') upd_flg FROM dual
			UNION
			SELECT  'TAL_ID'  AS field_name, TO_CHAR(p_TAL_ID)  AS field_value, DECODE(v_rec.TAL_ID, p_TAL_ID,'N','Y') upd_flg FROM dual
			UNION
			SELECT  'ENTITY'  AS field_name, p_ENTITY AS field_value, DECODE(trim(v_rec.ENTITY), trim(p_ENTITY),'N','Y') upd_flg FROM dual
			UNION
			SELECT  'SL_ACCT_CD'  AS field_name, p_SL_ACCT_CD AS field_value, DECODE(trim(v_rec.SL_ACCT_CD), trim(p_SL_ACCT_CD),'N','Y') upd_flg FROM dual
			UNION
			SELECT  'GL_ACCT_CD'  AS field_name, p_GL_ACCT_CD AS field_value, DECODE(trim(v_rec.GL_ACCT_CD), trim(p_GL_ACCT_CD),'N','Y') upd_flg FROM dual
			UNION
			SELECT  'CURR_VAL'  AS field_name, TO_CHAR(p_CURR_VAL)  AS field_value, DECODE(v_rec.CURR_VAL, p_CURR_VAL,'N','Y') upd_flg FROM dual
			UNION
			SELECT  'DB_CR_FLG'  AS field_name, p_DB_CR_FLG AS field_value, DECODE(trim(v_rec.DB_CR_FLG), trim(p_DB_CR_FLG),'N','Y') upd_flg FROM dual
			UNION
			SELECT  'LEDGER_NAR'  AS field_name, p_LEDGER_NAR AS field_value, DECODE(trim(v_rec.LEDGER_NAR), trim(p_LEDGER_NAR),'N','Y') upd_flg FROM dual
			UNION
			SELECT  'USER_ID'  AS field_name, p_USER_ID AS field_value, DECODE(trim(v_rec.USER_ID), trim(p_USER_ID),'N','Y') upd_flg FROM dual
			UNION
			SELECT  'CRE_DT'  AS field_name, TO_CHAR(p_CRE_DT,'yyyy/mm/dd hh24:mi:ss')  AS field_value, DECODE(v_rec.CRE_DT, p_CRE_DT,'N','Y') upd_flg FROM dual
			UNION
			SELECT  'UPD_DT'  AS field_name, TO_CHAR(p_UPD_DT,'yyyy/mm/dd hh24:mi:ss')  AS field_value, DECODE(v_rec.UPD_DT, p_UPD_DT,'N','Y') upd_flg FROM dual
			UNION
			SELECT  'DOC_DATE'  AS field_name, TO_CHAR(p_DOC_DATE,'yyyy/mm/dd hh24:mi:ss')  AS field_value, DECODE(v_rec.DOC_DATE, p_DOC_DATE,'N','Y') upd_flg FROM dual
			UNION
			SELECT  'FOLDER_CD'  AS field_name, p_FOLDER_CD AS field_value, DECODE(trim(v_rec.FOLDER_CD), trim(p_FOLDER_CD),'N','Y') upd_flg FROM dual
			UNION
			SELECT  'CRE_DT'  AS field_name, TO_CHAR(p_CRE_DT,'yyyy/mm/dd hh24:mi:ss')  AS field_value, DECODE(v_rec.CRE_DT, p_CRE_DT,'N','Y') upd_flg FROM dual
			WHERE P_UPD_STATUS = 'I'
			UNION
			SELECT  'USER_ID'  AS field_name, p_USER_ID AS field_value, DECODE(trim(v_rec.USER_ID), trim(p_USER_ID),'N','Y') upd_flg FROM dual
			WHERE P_UPD_STATUS = 'I'
			UNION
			SELECT  'UPD_DT'  AS field_name, TO_CHAR(p_UPD_DT,'yyyy/mm/dd hh24:mi:ss')  AS field_value, DECODE(v_rec.UPD_DT, p_UPD_DT,'N','Y') upd_flg FROM dual
			WHERE P_UPD_STATUS = 'U'
		) b
		WHERE a.field_name = b.field_name;
	--	AND  (P_UPD_STATUS <> 'C' OR (P_UPD_STATUS = 'C' AND a.field_name = 'XN_DOC_NUM'));

		 
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

	CLOSE v_Many_detail;
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
		ROLLBACK;
		p_error_code := v_error_code;
		p_error_msg := v_error_msg;
	WHEN OTHERS THEN
   -- Consider logging the error and then re-raise
		ROLLBACK;
		p_error_code := -1;
		p_error_msg := SUBSTR(SQLERRM(SQLCODE),1,200);
		RAISE;
END Sp_T_CONSOL_JRN_Upd;