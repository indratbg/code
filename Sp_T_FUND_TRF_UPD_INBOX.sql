create or replace 
PROCEDURE Sp_T_FUND_TRF_UPD_INBOX(
					P_SEARCH_TRF_DATE  T_FUND_TRF.TRF_DATE%TYPE,
					P_SEARCH_TRF_ID T_FUND_TRF.TRF_ID%TYPE,
					P_SEARCH_DOC_NUM T_FUND_TRF.DOC_NUM%TYPE,
					P_TRF_DATE		T_FUND_TRF.TRF_DATE%TYPE,
					P_TRF_ID		T_FUND_TRF.TRF_ID%TYPE,
					P_DOC_NUM		T_FUND_TRF.DOC_NUM%TYPE,
					P_FUND_BANK_CD		T_FUND_TRF.FUND_BANK_CD%TYPE,
					P_CLIENT_CD		T_FUND_TRF.CLIENT_CD%TYPE,
					P_TRF_TYPE		T_FUND_TRF.TRF_TYPE%TYPE,
					P_TRF_FLG		T_FUND_TRF.TRF_FLG%TYPE,
					P_TRF_TIMESTAMP		T_FUND_TRF.TRF_TIMESTAMP%TYPE,
					P_TRF_AMT		T_FUND_TRF.TRF_AMT%TYPE,
					P_CRE_DT		T_FUND_TRF.CRE_DT%TYPE,
					P_UPD_DT		T_FUND_TRF.UPD_DT%TYPE,
					P_USER_ID		T_FUND_TRF.USER_ID%TYPE,
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
	v_table_name 				T_MANY_DETAIL.table_name%TYPE := 'T_FUND_TRF';
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
FROM T_FUND_TRF
WHERE TRF_DATE = P_SEARCH_TRF_DATE
AND TRF_ID= P_SEARCH_TRF_ID
AND DOC_NUM = P_SEARCH_DOC_NUM;

v_MANY_DETAIL  Types.MANY_DETAIL_rc;

v_rec T_FUND_TRF%ROWTYPE;

v_cnt INTEGER;
 i INTEGER;
 V_FIELD_CNT NUMBER;
 v_pending_cnt NUMBER;
 va CHAR(1) := '@';
BEGIN

IF P_UPD_STATUS = 'I' AND (P_SEARCH_TRF_DATE <> P_TRF_DATE  OR P_SEARCH_TRF_ID <> P_TRF_ID OR P_SEARCH_DOC_NUM <> P_DOC_NUM ) THEN
		IF P_SEARCH_TRF_DATE <> P_TRF_DATE THEN
			v_error_code := -2001; 
			v_error_msg := 'jika INSERT, P_SEARCH_TRF_DATE harus sama dengan  P_TRF_DATE';
			RAISE v_err;
		END IF;
		IF P_SEARCH_TRF_ID <> P_TRF_ID  THEN
			v_error_code := -2002; 
			v_error_msg := 'jika INSERT, P_SEARCH_TRF_ID Hharus sama dengan P_TRF_ID';
			RAISE v_err;
		END IF;
			IF P_SEARCH_DOC_NUM <> P_DOC_NUM THEN
			v_error_code := -2003; 
			v_error_msg := 'jika INSERT, P_SEARCH_DOC_NUM harusa sama dengan P_DOC_NUM  ';
			RAISE v_err;
		END IF;
	END IF;
	

	BEGIN
		SELECT ROWID INTO v_table_rowid
		FROM T_FUND_TRF
		WHERE TRF_DATE = P_SEARCH_TRF_DATE
		AND TRF_ID= P_SEARCH_TRF_ID
		AND DOC_NUM = P_SEARCH_DOC_NUM;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			v_table_rowid := NULL;
		WHEN OTHERS THEN
			v_error_code := -3;
			v_error_msg :=  SUBSTR('Retrieve  '|| v_table_name||' for '||P_SEARCH_DOC_NUM||SQLERRM,1,200);
			RAISE v_err;
	END;
	
	IF v_table_rowid IS NULL THEN
		BEGIN
			SELECT COUNT(1) INTO v_pending_cnt
			FROM 
			(
				SELECT MAX(TRF_DATE) TRF_DATE, MAX(TRF_ID) TRF_ID, MAX(DOC_NUM) DOC_NUM
				FROM 
				(
					SELECT DECODE (field_name, 'TRF_DATE', field_value, NULL) TRF_DATE,
							DECODE (field_name, 'TRF_ID', field_value, NULL) TRF_ID,
							DECODE (field_name, 'DOC_NUM', field_value, NULL) DOC_NUM,
							d.update_seq, record_seq, field_name
					FROM T_MANY_DETAIL D, T_MANY_HEADER H
					WHERE d.table_name = v_table_name
					AND d.update_date = h.update_date
					AND d.update_seq = h.update_seq
					AND (d.field_name = 'TRF_DATE' OR d.field_name = 'TRF_ID' OR d.field_name = 'DOC_NUM')
					AND h.APPROVED_status = 'E'
					ORDER BY d.update_seq, record_seq, field_name
				)
				GROUP BY update_seq, record_seq
			)	-- Agar SELECT MAX dapat me-retrieve composite primary key untuk setiap record
				WHERE TRF_DATE = P_SEARCH_TRF_DATE
				AND TRF_ID= P_SEARCH_TRF_ID
				AND DOC_NUM = P_SEARCH_DOC_NUM;
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
			SELECT  'TRF_DATE'  AS field_name, TO_CHAR(p_TRF_DATE,'yyyy/mm/dd hh24:mi:ss')  AS field_value, DECODE(v_rec.TRF_DATE, p_TRF_DATE,'N','Y') upd_flg FROM dual
			UNION
			SELECT  'TRF_ID'  AS field_name, p_TRF_ID AS field_value, DECODE(trim(v_rec.TRF_ID), trim(p_TRF_ID),'N','Y') upd_flg FROM dual
			UNION
			SELECT  'DOC_NUM'  AS field_name, p_DOC_NUM AS field_value, DECODE(trim(v_rec.DOC_NUM), trim(p_DOC_NUM),'N','Y') upd_flg FROM dual
			UNION
			SELECT  'FUND_BANK_CD'  AS field_name, p_FUND_BANK_CD AS field_value, DECODE(trim(v_rec.FUND_BANK_CD), trim(p_FUND_BANK_CD),'N','Y') upd_flg FROM dual
			UNION
			SELECT  'CLIENT_CD'  AS field_name, p_CLIENT_CD AS field_value, DECODE(trim(v_rec.CLIENT_CD), trim(p_CLIENT_CD),'N','Y') upd_flg FROM dual
			UNION
			SELECT  'TRF_TYPE'  AS field_name, p_TRF_TYPE AS field_value, DECODE(trim(v_rec.TRF_TYPE), trim(p_TRF_TYPE),'N','Y') upd_flg FROM dual
			UNION
			SELECT  'TRF_FLG'  AS field_name, p_TRF_FLG AS field_value, DECODE(trim(v_rec.TRF_FLG), trim(p_TRF_FLG),'N','Y') upd_flg FROM dual
			UNION
			SELECT  'TRF_TIMESTAMP'  AS field_name, TO_CHAR(p_TRF_TIMESTAMP,'yyyy/mm/dd hh24:mi:ss')  AS field_value, DECODE(v_rec.TRF_TIMESTAMP, p_TRF_TIMESTAMP,'N','Y') upd_flg FROM dual
			UNION
			SELECT  'TRF_AMT'  AS field_name, TO_CHAR(p_TRF_AMT)  AS field_value, DECODE(v_rec.TRF_AMT, p_TRF_AMT,'N','Y') upd_flg FROM dual
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

END Sp_T_FUND_TRF_UPD_INBOX;