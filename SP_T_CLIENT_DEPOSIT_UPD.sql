create or replace 
PROCEDURE SP_T_CLIENT_DEPOSIT_UPD(P_SEARCH_TRX_DATE		T_CLIENT_DEPOSIT.TRX_DATE%TYPE,
								P_SEARCH_CLIENT_CD		T_CLIENT_DEPOSIT.CLIENT_CD%TYPE,
								P_SEARCH_DOC_NUM		T_CLIENT_DEPOSIT.DOC_NUM%TYPE,
								P_TRX_DATE		T_CLIENT_DEPOSIT.TRX_DATE%TYPE,
								P_CLIENT_CD		T_CLIENT_DEPOSIT.CLIENT_CD%TYPE,
								P_DEBIT		T_CLIENT_DEPOSIT.DEBIT%TYPE,
								P_CREDIT		T_CLIENT_DEPOSIT.CREDIT%TYPE,
								P_DOC_NUM		T_CLIENT_DEPOSIT.DOC_NUM%TYPE,
								P_CRE_DT		T_CLIENT_DEPOSIT.CRE_DT%TYPE,
								P_USER_ID		T_CLIENT_DEPOSIT.USER_ID%TYPE,
								P_UPD_DT		T_CLIENT_DEPOSIT.UPD_DT%TYPE,
								P_UPD_BY		T_CLIENT_DEPOSIT.UPD_BY%TYPE,
								P_REVERSAL_JUR		T_CLIENT_DEPOSIT.REVERSAL_JUR%TYPE,
								P_NO_PERJANJIAN		T_CLIENT_DEPOSIT.NO_PERJANJIAN%TYPE,
								P_DOC_TYPE		T_CLIENT_DEPOSIT.DOC_TYPE%TYPE,
								P_TAL_ID		T_CLIENT_DEPOSIT.TAL_ID%TYPE,
								P_FOLDER_CD		T_CLIENT_DEPOSIT.FOLDER_CD%TYPE,
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
v_table_name 					T_MANY_DETAIL.table_name%TYPE := 'T_CLIENT_DEPOSIT';
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
FROM T_CLIENT_DEPOSIT
WHERE TRX_DATE = P_SEARCH_TRX_DATE
AND CLIENT_CD = P_SEARCH_CLIENT_CD
AND DOC_NUM = P_SEARCH_DOC_NUM;

v_many_detail  Types.many_detail_rc;

v_rec T_CLIENT_DEPOSIT%ROWTYPE;

v_cnt INTEGER;
i INTEGER;
V_FIELD_CNT NUMBER;
v_pending_cnt NUMBER;
va CHAR(1) := '@';

BEGIN
	IF P_UPD_STATUS = 'I' AND (P_SEARCH_TRX_DATE <> P_TRX_DATE OR P_SEARCH_CLIENT_CD <> P_CLIENT_CD OR P_SEARCH_DOC_NUM <> P_DOC_NUM) THEN
		IF P_SEARCH_TRX_DATE <> P_TRX_DATE THEN
			v_error_code := -2001;
			v_error_msg := 'jika INSERT, P_SEARCH_TRX_DATE harus sama dengan P_TRX_DATE';
			RAISE v_err;
		END IF;
		IF  P_SEARCH_CLIENT_CD <> P_CLIENT_CD THEN
			v_error_code := -2002;
			v_error_msg := 'jika INSERT, P_SEARCH_CLIENT_CD harus sama dengan P_CLIENT_CD';
			RAISE v_err;
		END IF;
		IF P_SEARCH_DOC_NUM <> P_DOC_NUM THEN
			v_error_code := -2003;
			v_error_msg := 'jika INSERT, P_SEARCH_DOC_NUM harus sama dengan P_DOC_NUM';
			RAISE v_err;
		END IF;
	END IF;

    BEGIN
		SELECT ROWID INTO v_table_rowid
		FROM T_CLIENT_DEPOSIT
		WHERE TRX_DATE = P_SEARCH_TRX_DATE
		AND CLIENT_CD = P_SEARCH_CLIENT_CD
		AND DOC_NUM = P_SEARCH_DOC_NUM;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			v_table_rowid := NULL;
		WHEN OTHERS THEN
			v_error_code := -3;
			v_error_msg :=  SUBSTR('Retrieve  '|| v_table_name||' for '||P_SEARCH_CLIENT_CD||SQLERRM,1,200);
			RAISE v_err;
	END;
	
	IF v_table_rowid IS NULL THEN
		BEGIN
			SELECT COUNT(1) INTO v_pending_cnt
			FROM (SELECT MAX(TRX_DATE) TRX_DATE, MAX(CLIENT_CD) CLIENT_CD, MAX(DOC_NUM) DOC_NUM
				  FROM (SELECT DECODE (field_name, 'TRX_DATE', field_value, NULL) TRX_DATE,
							   DECODE (field_name, 'CLIENT_CD', field_value, NULL) CLIENT_CD,
							   DECODE (field_name, 'DOC_NUM', field_value, NULL) DOC_NUM,
							   d.update_seq, record_seq, field_name
						FROM T_MANY_DETAIL D, T_MANY_HEADER H
						WHERE d.table_name = v_table_name
						AND d.update_date = h.update_date
						AND d.update_seq = h.update_seq
						AND (d.field_name IN ('TRX_DATE','CLIENT_CD','DOC_NUM'))
						AND h.APPROVED_status = 'E'
						ORDER BY d.update_seq, record_seq, field_name)
						GROUP BY update_seq, record_seq)	-- Agar SELECT MAX dapat me-retrieve composite primary key untuk setiap record
			WHERE TRX_DATE = P_SEARCH_TRX_DATE
		AND CLIENT_CD = P_SEARCH_CLIENT_CD
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

	OPEN v_Many_detail FOR
		SELECT p_update_date AS update_date, p_update_seq AS update_seq, table_name, p_record_seq AS record_seq, v_table_rowid AS table_rowid, a.field_name,  field_type, b.field_value, p_upd_status AS status,  b.upd_flg
		FROM(
		 SELECT  v_table_name AS table_name, column_name AS field_name,
					DECODE(data_type,'VARCHAR2','S','CHAR','S','NUMBER','N','DATE','D','X') AS field_type
			FROM all_tab_columns
			WHERE table_name =v_table_name
			AND OWNER = 'IPNEXTG'
		) a,
		( SELECT  'TRX_DATE'  AS field_name, TO_CHAR(p_TRX_DATE,'yyyy/mm/dd hh24:mi:ss')  AS field_value, DECODE(v_rec.TRX_DATE, p_TRX_DATE,'N','Y') upd_flg FROM dual
			UNION
			SELECT  'CLIENT_CD'  AS field_name, p_CLIENT_CD AS field_value, DECODE(trim(v_rec.CLIENT_CD), trim(p_CLIENT_CD),'N','Y') upd_flg FROM dual
			UNION
			SELECT  'DEBIT'  AS field_name, TO_CHAR(p_DEBIT)  AS field_value, DECODE(v_rec.DEBIT, p_DEBIT,'N','Y') upd_flg FROM dual
			UNION
			SELECT  'CREDIT'  AS field_name, TO_CHAR(p_CREDIT)  AS field_value, DECODE(v_rec.CREDIT, p_CREDIT,'N','Y') upd_flg FROM dual
			UNION
			SELECT  'DOC_NUM'  AS field_name, p_DOC_NUM AS field_value, DECODE(trim(v_rec.DOC_NUM), trim(p_DOC_NUM),'N','Y') upd_flg FROM dual
      UNION
			SELECT  'REVERSAL_JUR'  AS field_name, p_REVERSAL_JUR AS field_value, DECODE(trim(v_rec.REVERSAL_JUR), trim(p_REVERSAL_JUR),'N','Y') upd_flg FROM dual
			UNION
			SELECT  'NO_PERJANJIAN'  AS field_name, p_NO_PERJANJIAN AS field_value, DECODE(trim(v_rec.NO_PERJANJIAN), trim(p_NO_PERJANJIAN),'N','Y') upd_flg FROM dual
			UNION
			SELECT  'DOC_TYPE'  AS field_name, p_DOC_TYPE AS field_value, DECODE(trim(v_rec.DOC_TYPE), trim(p_DOC_TYPE),'N','Y') upd_flg FROM dual
			UNION
			SELECT  'TAL_ID'  AS field_name, TO_CHAR(p_TAL_ID)  AS field_value, DECODE(v_rec.TAL_ID, p_TAL_ID,'N','Y') upd_flg FROM dual
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
			UNION
			SELECT  'UPD_BY'  AS field_name, p_UPD_BY AS field_value, DECODE(trim(v_rec.UPD_BY), trim(p_UPD_BY),'N','Y') upd_flg FROM dual
			WHERE P_UPD_STATUS = 'U'
		) b
		WHERE a.field_name = b.field_name
		AND  (P_UPD_STATUS <> 'C' OR (P_UPD_STATUS = 'C' AND a.field_name = 'TRX_DATE'));

		 
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
END SP_T_CLIENT_DEPOSIT_UPD;