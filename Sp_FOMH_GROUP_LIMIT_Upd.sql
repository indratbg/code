create or replace PROCEDURE Sp_FOMH_GROUP_LIMIT_Upd(
	P_SEARCH_GROUP_CD		FOMH_GROUP_LIMIT.GROUP_CD%TYPE,
	P_SEARCH_USERID		FOMH_GROUP_LIMIT.USERID%TYPE,
	P_GROUP_CD		FOMH_GROUP_LIMIT.GROUP_CD%TYPE,
	P_GROUP_NAME		FOMH_GROUP_LIMIT.GROUP_NAME%TYPE,
	P_USERID		FOMH_GROUP_LIMIT.USERID%TYPE,
	P_CRE_BY		FOMH_GROUP_LIMIT.CRE_BY%TYPE,
	P_CRE_DT		FOMH_GROUP_LIMIT.CRE_DT%TYPE,
	P_UPD_BY		FOMH_GROUP_LIMIT.UPD_BY%TYPE,
	P_UPD_DT		FOMH_GROUP_LIMIT.UPD_DT%TYPE,
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
v_table_name 					T_MANY_DETAIL.table_name%TYPE := 'FOMH_GROUP_LIMIT';
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
FROM FOMH_GROUP_LIMIT
WHERE GROUP_CD = p_search_GROUP_CD
AND USERID = p_search_USERID;

v_many_detail  Types.many_detail_rc;

v_rec FOMH_GROUP_LIMIT%ROWTYPE;

v_cnt INTEGER;
i INTEGER;
V_FIELD_CNT NUMBER;
v_pending_cnt NUMBER;
va CHAR(1) := '@';

BEGIN
	IF P_UPD_STATUS = 'I' AND (p_search_GROUP_CD <> p_GROUP_CD OR p_search_USERID <> p_USERID) THEN
		IF p_search_GROUP_CD <> p_GROUP_CD THEN
			v_error_code := -2001;
			v_error_msg := 'jika INSERT, p_search_GROUP_CD harus sama dengan P_GROUP_CD';
			RAISE v_err;
		END IF;
		IF p_search_USERID <> p_USERID THEN
			v_error_code := -2002;
			v_error_msg := 'jika INSERT, p_search_USERID harus sama dengan P_USERID';
			RAISE v_err;
		END IF;
	END IF;

	BEGIN
		SELECT ROWID INTO v_table_rowid
		FROM FOMH_GROUP_LIMIT
		WHERE GROUP_CD = p_search_GROUP_CD
		AND USERID = p_search_USERID;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			v_table_rowid := NULL;
		WHEN OTHERS THEN
			v_error_code := -3;
			v_error_msg :=  SUBSTR('Retrieve  '|| v_table_name||' for '||p_search_GROUP_CD||SQLERRM,1,200);
			RAISE v_err;
	END;
	
	IF v_table_rowid IS NULL THEN
		BEGIN
			SELECT COUNT(1) INTO v_pending_cnt
			FROM 
			(
				SELECT MAX(GROUP_CD) GROUP_CD, MAX(USERID) USERID
				FROM 
				(
					SELECT DECODE (field_name, 'GROUP_CD', field_value, NULL) GROUP_CD,
							DECODE (field_name, 'USERID', field_value, NULL) USERID,
							d.update_seq, record_seq, field_name
					FROM T_MANY_DETAIL D, T_MANY_HEADER H
					WHERE d.table_name = v_table_name
					AND d.update_date = h.update_date
					AND d.update_seq = h.update_seq
					AND (d.field_name = 'GROUP_CD' OR d.field_name = 'USERID')
					AND h.APPROVED_status = 'E'
					ORDER BY d.update_seq, record_seq, field_name
				)
				GROUP BY update_seq, record_seq
			)	-- Agar SELECT MAX dapat me-retrieve composite primary key untuk setiap record
			WHERE GROUP_CD = p_search_GROUP_CD
			AND USERID = p_search_USERID;
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
		v_error_msg := 'Masih ada yang belum di-approve  '||p_search_GROUP_CD;
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
			--AND OWNER = 'IPNEXTG_FO'
		) a,
		( 
			SELECT  'GROUP_CD'  AS field_name, p_GROUP_CD AS field_value, DECODE(trim(v_rec.GROUP_CD), trim(p_GROUP_CD),'N','Y') upd_flg FROM dual
			UNION
			SELECT  'GROUP_NAME'  AS field_name, p_GROUP_NAME AS field_value, DECODE(trim(v_rec.GROUP_NAME), trim(p_GROUP_NAME),'N','Y') upd_flg FROM dual
			UNION
			SELECT  'USERID'  AS field_name, p_USERID AS field_value, DECODE(trim(v_rec.USERID), trim(p_USERID),'N','Y') upd_flg FROM dual
			WHERE P_UPD_STATUS = 'I'
			UNION
			SELECT  'CRE_BY'  AS field_name, p_CRE_BY AS field_value, DECODE(trim(v_rec.CRE_BY), trim(p_CRE_BY),'N','Y') upd_flg FROM dual
			WHERE P_UPD_STATUS = 'I'
			UNION
			SELECT  'CRE_DT'  AS field_name, TO_CHAR(p_CRE_DT,'yyyy/mm/dd hh24:mi:ss')  AS field_value, DECODE(v_rec.CRE_DT, p_CRE_DT,'N','Y') upd_flg FROM dual
			WHERE P_UPD_STATUS = 'I'
			UNION
			SELECT  'UPD_BY'  AS field_name, p_UPD_BY AS field_value, DECODE(trim(v_rec.UPD_BY), trim(p_UPD_BY),'N','Y') upd_flg FROM dual
			WHERE P_UPD_STATUS = 'U'
			UNION
			SELECT  'UPD_DT'  AS field_name, TO_CHAR(p_UPD_DT,'yyyy/mm/dd hh24:mi:ss')  AS field_value, DECODE(v_rec.UPD_DT, p_UPD_DT,'N','Y') upd_flg FROM dual
			WHERE P_UPD_STATUS = 'U'
		) b
		WHERE a.field_name = b.field_name
		AND  (P_UPD_STATUS <> 'C' OR (P_UPD_STATUS = 'C' AND a.field_name = 'GROUP_CD'));

		 
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
END Sp_FOMH_GROUP_LIMIT_Upd;