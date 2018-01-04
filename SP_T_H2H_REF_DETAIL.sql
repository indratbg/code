create or replace PROCEDURE SP_T_H2H_REF_DETAIL(
	P_SEARCH_TRF_ID		T_H2H_REF_DETAIL.TRF_ID%TYPE,
	P_SEARCH_TRX_REF		T_H2H_REF_DETAIL.TRX_REF%TYPE,
	P_ROW_ID		T_H2H_REF_DETAIL.ROW_ID%TYPE,
	P_TRX_REF		T_H2H_REF_DETAIL.TRX_REF%TYPE,
	P_TRF_ID		T_H2H_REF_DETAIL.TRF_ID%TYPE,
	P_ACCT_NAME		T_H2H_REF_DETAIL.ACCT_NAME%TYPE,
	P_RDI_ACCT		T_H2H_REF_DETAIL.RDI_ACCT%TYPE,
	P_CLIENT_BANK_ACCT		T_H2H_REF_DETAIL.CLIENT_BANK_ACCT%TYPE,
	P_BANK_NAME		T_H2H_REF_DETAIL.BANK_NAME%TYPE,
	P_TRF_AMT		T_H2H_REF_DETAIL.TRF_AMT%TYPE,
	P_STATUS		T_H2H_REF_DETAIL.STATUS%TYPE,
	P_DESCRIPTION		T_H2H_REF_DETAIL.DESCRIPTION%TYPE,
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
v_table_name 					T_MANY_DETAIL.table_name%TYPE := 'T_H2H_REF_DETAIL';
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
FROM T_H2H_REF_DETAIL
WHERE TRF_ID = P_SEARCH_TRF_ID
AND TRX_REF = P_SEARCH_TRX_REF;

v_many_detail  Types.many_detail_rc;

v_rec T_H2H_REF_DETAIL%ROWTYPE;

v_cnt INTEGER;
i INTEGER;
V_FIELD_CNT NUMBER;
v_pending_cnt NUMBER;
va CHAR(1) := '@';

BEGIN
	IF P_UPD_STATUS = 'I' AND (p_search_TRF_ID <> p_TRF_ID OR p_search_TRX_REF <> p_TRX_REF) THEN
		IF p_search_TRF_ID <> p_TRF_ID THEN
			v_error_code := -2001;
			v_error_msg := 'jika INSERT, p_search_TRF_ID harus sama dengan P_TRF_ID';
			RAISE v_err;
		END IF;
		IF p_search_TRX_REF <> p_TRX_REF THEN
			v_error_code := -2002;
			v_error_msg := 'jika INSERT, p_search_TRX_REF harus sama dengan P_TRX_REF';
			RAISE v_err;
		END IF;
	END IF;

	BEGIN
		SELECT ROWID INTO v_table_rowid
		FROM T_H2H_REF_DETAIL
		WHERE TRF_ID = p_search_TRF_ID;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			v_table_rowid := NULL;
		WHEN OTHERS THEN
			v_error_code := -3;
			v_error_msg :=  SUBSTR('Retrieve  '|| v_table_name||' for '||p_search_TRF_ID||SQLERRM,1,200);
			RAISE v_err;
	END;
	
	IF v_table_rowid IS NULL THEN
		BEGIN
			SELECT COUNT(1) INTO v_pending_cnt
			FROM 
			(
				SELECT MAX(TRF_ID) TRF_ID, MAX(TRX_REF) TRX_REF
				FROM 
				(
					SELECT DECODE (field_name, 'TRF_ID', field_value, NULL) TRF_ID,
							DECODE (field_name, 'TRX_REF', field_value, NULL) TRX_REF,
							d.update_seq, record_seq, field_name
					FROM T_MANY_DETAIL D, T_MANY_HEADER H
					WHERE d.table_name = v_table_name
					AND d.update_date = h.update_date
					AND d.update_seq = h.update_seq
					AND (d.field_name = 'TRF_ID' OR d.field_name = 'TRX_REF')
					AND h.APPROVED_status = 'E'
					ORDER BY d.update_seq, record_seq, field_name
				)
				GROUP BY update_seq, record_seq
			)	-- Agar SELECT MAX dapat me-retrieve composite primary key untuk setiap record
			WHERE TRF_ID = p_search_TRF_ID
			AND TRX_REF = p_search_TRX_REF;
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
      AND h.update_date = d.update_date
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
		v_error_msg := 'Masih ada yang belum di-approve TAL '||p_search_TRF_ID;
		RAISE v_err;
	END IF;
	
	OPEN csr_Table;
	FETCH csr_Table INTO v_rec;

	OPEN v_Many_detail FOR
		SELECT p_update_date AS update_date, p_update_seq AS update_seq, table_name, p_record_seq AS record_seq, v_table_rowid AS table_rowid, a.field_name,  field_type, b.field_value, p_upd_status AS status,  b.upd_flg
		FROM
		(
			SELECT  v_table_name AS table_name, column_name AS field_name, DECODE(data_type,'VARCHAR2','S','CHAR','S','NUMBER','N','DATE','D','X') AS field_type
			FROM all_tab_columns
			WHERE table_name =v_table_name
			AND OWNER = 'IPNEXTG'
		) a,
		( 
			SELECT  'ROW_ID'  AS field_name, TO_CHAR(p_ROW_ID)  AS field_value, DECODE(v_rec.ROW_ID, p_ROW_ID,'N','Y') upd_flg FROM dual
			UNION
			SELECT  'TRX_REF'  AS field_name, p_TRX_REF AS field_value, DECODE(trim(v_rec.TRX_REF), trim(p_TRX_REF),'N','Y') upd_flg FROM dual
			UNION
			SELECT  'TRF_ID'  AS field_name, p_TRF_ID AS field_value, DECODE(trim(v_rec.TRF_ID), trim(p_TRF_ID),'N','Y') upd_flg FROM dual
			UNION
			SELECT  'ACCT_NAME'  AS field_name, p_ACCT_NAME AS field_value, DECODE(trim(v_rec.ACCT_NAME), trim(p_ACCT_NAME),'N','Y') upd_flg FROM dual
			UNION
			SELECT  'RDI_ACCT'  AS field_name, p_RDI_ACCT AS field_value, DECODE(trim(v_rec.RDI_ACCT), trim(p_RDI_ACCT),'N','Y') upd_flg FROM dual
			UNION
			SELECT  'CLIENT_BANK_ACCT'  AS field_name, p_CLIENT_BANK_ACCT AS field_value, DECODE(trim(v_rec.CLIENT_BANK_ACCT), trim(p_CLIENT_BANK_ACCT),'N','Y') upd_flg FROM dual
			UNION
			SELECT  'BANK_NAME'  AS field_name, p_BANK_NAME AS field_value, DECODE(trim(v_rec.BANK_NAME), trim(p_BANK_NAME),'N','Y') upd_flg FROM dual
			UNION
			SELECT  'TRF_AMT'  AS field_name, TO_CHAR(p_TRF_AMT)  AS field_value, DECODE(v_rec.TRF_AMT, p_TRF_AMT,'N','Y') upd_flg FROM dual
			UNION
			SELECT  'STATUS'  AS field_name, p_STATUS AS field_value, DECODE(trim(v_rec.STATUS), trim(p_STATUS),'N','Y') upd_flg FROM dual
			UNION
			SELECT  'DESCRIPTION'  AS field_name, p_DESCRIPTION AS field_value, DECODE(trim(v_rec.DESCRIPTION), trim(p_DESCRIPTION),'N','Y') upd_flg FROM dual
		) b
		WHERE a.field_name = b.field_name
		AND  (P_UPD_STATUS <> 'C' OR (P_UPD_STATUS = 'C' AND a.field_name = 'TRF_ID'));

		 
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
END SP_T_H2H_REF_DETAIL;