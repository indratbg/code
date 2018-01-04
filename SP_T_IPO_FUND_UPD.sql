create or replace 
PROCEDURE SP_T_IPO_FUND_UPD(
	P_SEARCH_STK_CD		T_IPO_FUND.STK_CD%TYPE,
	P_SEARCH_CLIENT_CD		T_IPO_FUND.CLIENT_CD%TYPE,
	P_SEARCH_TAHAP		T_IPO_FUND.TAHAP%TYPE,
	P_STK_CD		T_IPO_FUND.STK_CD%TYPE,
	P_CLIENT_CD		T_IPO_FUND.CLIENT_CD%TYPE,
	P_TAHAP		T_IPO_FUND.TAHAP%TYPE,
	P_DOC_NUM		T_IPO_FUND.DOC_NUM%TYPE,
	P_CRE_DT		T_IPO_FUND.CRE_DT%TYPE,
	P_USER_ID		T_IPO_FUND.USER_ID%TYPE,
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
v_table_name 					T_MANY_DETAIL.table_name%TYPE := 'T_IPO_FUND';
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
FROM T_IPO_FUND
WHERE STK_CD = P_SEARCH_STK_CD
AND CLIENT_CD = P_SEARCH_CLIENT_CD;

v_many_detail  Types.many_detail_rc;

v_rec T_IPO_FUND%ROWTYPE;

v_cnt INTEGER;
i INTEGER;
V_FIELD_CNT NUMBER;
v_pending_cnt NUMBER;
va CHAR(1) := '@';

BEGIN
	IF P_UPD_STATUS = 'I' AND (p_search_STK_CD <> p_STK_CD OR p_search_CLIENT_CD <> p_CLIENT_CD OR P_SEARCH_TAHAP <> P_TAHAP) THEN
		IF p_search_STK_CD <> p_STK_CD THEN
			v_error_code := -2001;
			v_error_msg := 'jika INSERT, p_search_STK_CD harus sama dengan P_STK_CD';
			RAISE v_err;
		END IF;
		IF p_search_CLIENT_CD <> p_CLIENT_CD THEN
			v_error_code := -2002;
			v_error_msg := 'jika INSERT, p_search_CLIENT_CD harus sama dengan P_CLIENT_CD';
			RAISE v_err;
		END IF;
		IF P_SEARCH_TAHAP <> P_TAHAP THEN
			v_error_code := -2002;
			v_error_msg := 'jika INSERT, P_SEARCH_TAHAP harus sama dengan P_TAHAP';
			RAISE v_err;
		END IF;
	END IF;

    BEGIN
		SELECT ROWID INTO v_table_rowid
		FROM T_IPO_FUND
		WHERE STK_CD = p_search_STK_CD
		AND CLIENT_CD = p_search_CLIENT_CD
		AND TAHAP = P_SEARCH_TAHAP;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			v_table_rowid := NULL;
		WHEN OTHERS THEN
			v_error_code := -3;
			v_error_msg :=  SUBSTR('Retrieve  '|| v_table_name||' for '||p_search_STK_CD||SQLERRM,1,200);
			RAISE v_err;
	END;
	
	IF v_table_rowid IS NULL THEN
		BEGIN
			SELECT COUNT(1) INTO v_pending_cnt
			FROM (SELECT MAX(STK_CD) STK_CD, MAX(CLIENT_CD) CLIENT_CD, MAX(TAHAP) TAHAP
				  FROM (SELECT DECODE (field_name, 'STK_CD', field_value, NULL) STK_CD,
							   DECODE (field_name, 'CLIENT_CD', field_value, NULL) CLIENT_CD,
							    DECODE (field_name, 'TAHAP', field_value, NULL) TAHAP,
							   d.update_seq, record_seq, field_name
						FROM T_MANY_DETAIL D, T_MANY_HEADER H
						WHERE d.table_name = v_table_name
						AND d.update_date = h.update_date
						AND d.update_seq = h.update_seq
						AND d.field_name IN ('STK_CD','CLIENT_CD', 'TAHAP')
						AND h.APPROVED_status = 'E'
						ORDER BY d.update_seq, record_seq, field_name)
						GROUP BY update_seq, record_seq)	-- Agar SELECT MAX dapat me-retrieve composite primary key untuk setiap record
			WHERE STK_CD = p_search_STK_CD
			AND CLIENT_CD = p_search_CLIENT_CD
			AND TAHAP = P_SEARCH_TAHAP;
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
		(SELECT  'STK_CD'  AS field_name, p_STK_CD AS field_value, DECODE(trim(v_rec.STK_CD), trim(p_STK_CD),'N','Y') upd_flg FROM dual
			UNION
			SELECT  'CLIENT_CD'  AS field_name, p_CLIENT_CD AS field_value, DECODE(trim(v_rec.CLIENT_CD), trim(p_CLIENT_CD),'N','Y') upd_flg FROM dual
			UNION
			SELECT  'TAHAP'  AS field_name, p_TAHAP AS field_value, DECODE(trim(v_rec.TAHAP), trim(p_TAHAP),'N','Y') upd_flg FROM dual
			UNION
			SELECT  'DOC_NUM'  AS field_name, p_DOC_NUM AS field_value, DECODE(trim(v_rec.DOC_NUM), trim(p_DOC_NUM),'N','Y') upd_flg FROM dual
			UNION
			SELECT  'CRE_DT'  AS field_name, TO_CHAR(p_CRE_DT,'yyyy/mm/dd hh24:mi:ss')  AS field_value, DECODE(v_rec.CRE_DT, p_CRE_DT,'N','Y') upd_flg FROM dual
			WHERE P_UPD_STATUS = 'I'
			UNION
			SELECT  'USER_ID'  AS field_name, p_USER_ID AS field_value, DECODE(trim(v_rec.USER_ID), trim(p_USER_ID),'N','Y') upd_flg FROM dual
			WHERE P_UPD_STATUS = 'I'
		) b
		WHERE a.field_name = b.field_name
		AND  (P_UPD_STATUS <> 'C' OR (P_UPD_STATUS = 'C' AND a.field_name = 'STK_CD'));

		 
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
END SP_T_IPO_FUND_UPD;