create or replace PROCEDURE SP_T_H2H_REF_HEADER(
	P_SEARCH_TRF_ID		T_H2H_REF_HEADER.TRF_ID%TYPE,
	P_TRF_ID		T_H2H_REF_HEADER.TRF_ID%TYPE,
P_FILE_NAME		T_H2H_REF_HEADER.FILE_NAME%TYPE,
P_TRX_TYPE		T_H2H_REF_HEADER.TRX_TYPE%TYPE,
P_KBB_TYPE1		T_H2H_REF_HEADER.KBB_TYPE1%TYPE,
P_KBB_TYPE2		T_H2H_REF_HEADER.KBB_TYPE2%TYPE,
P_BRANCH_GROUP		T_H2H_REF_HEADER.BRANCH_GROUP%TYPE,
P_TRF_DATE		T_H2H_REF_HEADER.TRF_DATE%TYPE,
P_SAVE_DATE		T_H2H_REF_HEADER.SAVE_DATE%TYPE,
P_UPLOAD_DATE		T_H2H_REF_HEADER.UPLOAD_DATE%TYPE,
P_RESPONSE_DATE		T_H2H_REF_HEADER.RESPONSE_DATE%TYPE,
P_TOTAL_RECORD		T_H2H_REF_HEADER.TOTAL_RECORD%TYPE,
P_SUCCESS_CNT		T_H2H_REF_HEADER.SUCCESS_CNT%TYPE,
P_FAIL_CNT		T_H2H_REF_HEADER.FAIL_CNT%TYPE,
P_DESCRIPTION		T_H2H_REF_HEADER.DESCRIPTION%TYPE,
P_CURR_CD VARCHAR2,
P_REMARK1 VARCHAR2,
P_REMARK2 VARCHAR2,
P_RECEIVER_EMAIL_ADDRESS varchar2,
P_RECEIVER_BANK_CD VARCHAR2,
P_RECEIVER_CUST_TYPE VARCHAR2,
P_RECEIVER_CUST_RESIDENCE VARCHAR2,
P_TRANSFER_TYPE VARCHAR2,
P_RECEIVER_BANK_BRANCH_NAME VARCHAR2,
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
v_table_name 					T_MANY_DETAIL.table_name%TYPE := 'T_H2H_REF_HEADER';
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
FROM T_H2H_REF_HEADER
WHERE TRF_ID = P_SEARCH_TRF_ID;

v_many_detail  Types.many_detail_rc;

v_rec T_H2H_REF_HEADER%ROWTYPE;

v_cnt INTEGER;
i INTEGER;
V_FIELD_CNT NUMBER;
v_pending_cnt NUMBER;
va CHAR(1) := '@';

BEGIN
	IF P_UPD_STATUS = 'I' AND p_search_TRF_ID <> p_TRF_ID  THEN
			v_error_code := -2001;
			v_error_msg := 'jika INSERT, p_search_TRF_ID harus sama dengan P_TRF_ID';
			RAISE v_err;
	END IF;

	BEGIN
		SELECT ROWID INTO v_table_rowid
		FROM T_H2H_REF_HEADER
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
				SELECT COUNT(1)  INTO v_pending_cnt FROM T_MANY_DETAIL D, T_MANY_HEADER H WHERE
				D.UPDATE_sEQ=H.UPDATE_sEQ
				AND D.TABLE_NAME=v_table_name
				AND D.FIELD_NAME = 'TRF_ID'
				AND H.APPROVED_status ='E'
				AND field_value = P_SEARCH_TRF_ID;

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
      UNION 
      SELECT v_table_name,'CURR_CD' AS field_name, 'S' FROM DUAL
      UNION
      SELECT v_table_name,'REMARK1' AS field_name, 'S' FROM DUAL
      UNION
      SELECT v_table_name,'REMARK2' AS field_name, 'S' FROM DUAL
      UNION
      SELECT v_table_name,'RECEIVER_EMAIL_ADDRESS' AS field_name, 'S' FROM DUAL
      UNION
      SELECT v_table_name,'RECEIVER_BANK_CD' AS field_name, 'S' FROM DUAL
      UNION
      SELECT v_table_name,'RECEIVER_CUST_TYPE' AS field_name, 'S' FROM DUAL
      UNION
      SELECT v_table_name,'RECEIVER_CUST_RESIDENCE' AS field_name, 'S' FROM DUAL
       UNION
      SELECT v_table_name,'TRANSFER_TYPE' AS field_name, 'S' FROM DUAL
      UNION
      SELECT v_table_name,'RECEIVER_BANK_BRANCH_NAME' AS field_name, 'S' FROM DUAL
		) a,
		( 
			SELECT  'TRF_ID'  AS field_name, p_TRF_ID AS field_value, DECODE(trim(v_rec.TRF_ID), trim(p_TRF_ID),'N','Y') upd_flg FROM dual
			UNION
			SELECT  'FILE_NAME'  AS field_name, p_FILE_NAME AS field_value, DECODE(trim(v_rec.FILE_NAME), trim(p_FILE_NAME),'N','Y') upd_flg FROM dual
			UNION
			SELECT  'TRX_TYPE'  AS field_name, p_TRX_TYPE AS field_value, DECODE(trim(v_rec.TRX_TYPE), trim(p_TRX_TYPE),'N','Y') upd_flg FROM dual
			UNION
			SELECT  'KBB_TYPE1'  AS field_name, TO_CHAR(p_KBB_TYPE1)  AS field_value, DECODE(v_rec.KBB_TYPE1, p_KBB_TYPE1,'N','Y') upd_flg FROM dual
			UNION
			SELECT  'KBB_TYPE2'  AS field_name, p_KBB_TYPE2 AS field_value, DECODE(trim(v_rec.KBB_TYPE2), trim(p_KBB_TYPE2),'N','Y') upd_flg FROM dual
			UNION
			SELECT  'BRANCH_GROUP'  AS field_name, p_BRANCH_GROUP AS field_value, DECODE(trim(v_rec.BRANCH_GROUP), trim(p_BRANCH_GROUP),'N','Y') upd_flg FROM dual
			UNION
			SELECT  'TRF_DATE'  AS field_name, TO_CHAR(p_TRF_DATE,'yyyy/mm/dd hh24:mi:ss')  AS field_value, DECODE(v_rec.TRF_DATE, p_TRF_DATE,'N','Y') upd_flg FROM dual
			UNION
			SELECT  'SAVE_DATE'  AS field_name, TO_CHAR(p_SAVE_DATE,'yyyy/mm/dd hh24:mi:ss')  AS field_value, DECODE(v_rec.SAVE_DATE, p_SAVE_DATE,'N','Y') upd_flg FROM dual
			UNION
			SELECT  'UPLOAD_DATE'  AS field_name, TO_CHAR(p_UPLOAD_DATE,'yyyy/mm/dd hh24:mi:ss')  AS field_value, DECODE(v_rec.UPLOAD_DATE, p_UPLOAD_DATE,'N','Y') upd_flg FROM dual
			UNION
			SELECT  'RESPONSE_DATE'  AS field_name, TO_CHAR(p_RESPONSE_DATE,'yyyy/mm/dd hh24:mi:ss')  AS field_value, DECODE(v_rec.RESPONSE_DATE, p_RESPONSE_DATE,'N','Y') upd_flg FROM dual
			UNION
			SELECT  'TOTAL_RECORD'  AS field_name, TO_CHAR(p_TOTAL_RECORD)  AS field_value, DECODE(v_rec.TOTAL_RECORD, p_TOTAL_RECORD,'N','Y') upd_flg FROM dual
			UNION
			SELECT  'SUCCESS_CNT'  AS field_name, TO_CHAR(p_SUCCESS_CNT)  AS field_value, DECODE(v_rec.SUCCESS_CNT, p_SUCCESS_CNT,'N','Y') upd_flg FROM dual
			UNION
			SELECT  'FAIL_CNT'  AS field_name, TO_CHAR(p_FAIL_CNT)  AS field_value, DECODE(v_rec.FAIL_CNT, p_FAIL_CNT,'N','Y') upd_flg FROM dual
			UNION
			SELECT  'DESCRIPTION'  AS field_name, p_DESCRIPTION AS field_value, DECODE(trim(v_rec.DESCRIPTION), trim(p_DESCRIPTION),'N','Y') upd_flg FROM dual
      UNION
			SELECT  'CURR_CD'  AS field_name, P_CURR_CD AS field_value, 'X' upd_flg FROM dual
      UNION
			SELECT  'REMARK1'  AS field_name, P_REMARK1 AS field_value, 'X' upd_flg FROM dual
      UNION
      SELECT  'REMARK2'  AS field_name, P_REMARK2 AS field_value, 'X' upd_flg FROM dual
      UNION
      SELECT  'RECEIVER_EMAIL_ADDRESS'  AS field_name, P_RECEIVER_EMAIL_ADDRESS AS field_value, 'X' upd_flg FROM dual
      UNION
      SELECT  'RECEIVER_BANK_CD'  AS field_name, P_RECEIVER_BANK_CD AS field_value, 'X' upd_flg FROM dual
       UNION
      SELECT  'RECEIVER_CUST_TYPE'  AS field_name, P_RECEIVER_CUST_TYPE AS field_value, 'X' upd_flg FROM dual
       UNION
      SELECT  'RECEIVER_CUST_RESIDENCE'  AS field_name, P_RECEIVER_CUST_RESIDENCE AS field_value, 'X' upd_flg FROM dual
       UNION
      SELECT  'TRANSFER_TYPE'  AS field_name, P_TRANSFER_TYPE AS field_value, 'X' upd_flg FROM dual
      UNION
      SELECT  'RECEIVER_BANK_BRANCH_NAME'  AS field_name, P_RECEIVER_BANK_BRANCH_NAME AS field_value, 'X' upd_flg FROM dual
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
END SP_T_H2H_REF_HEADER;