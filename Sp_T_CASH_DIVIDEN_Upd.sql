create or replace 
PROCEDURE Sp_T_CASH_DIVIDEN_Upd(
	P_SEARCH_CA_TYPE		T_CASH_DIVIDEN.CA_TYPE%TYPE,
	P_SEARCH_STK_CD		T_CASH_DIVIDEN.STK_CD%TYPE,
	P_SEARCH_DISTRIB_DT 	T_CASH_DIVIDEN.DISTRIB_DT%TYPE,
	P_SEARCH_CLIENT_CD		T_CASH_DIVIDEN.CLIENT_CD%TYPE,
	P_CA_TYPE		T_CASH_DIVIDEN.CA_TYPE%TYPE,
	P_STK_CD		T_CASH_DIVIDEN.STK_CD%TYPE,
	P_DISTRIB_DT		T_CASH_DIVIDEN.DISTRIB_DT%TYPE,
	P_CLIENT_CD		T_CASH_DIVIDEN.CLIENT_CD%TYPE,
	P_QTY		T_CASH_DIVIDEN.QTY%TYPE,
	P_RATE		T_CASH_DIVIDEN.RATE%TYPE,
	P_GROSS_AMT		T_CASH_DIVIDEN.GROSS_AMT%TYPE,
	P_TAX_PCN		T_CASH_DIVIDEN.TAX_PCN%TYPE,
	P_TAX_AMT		T_CASH_DIVIDEN.TAX_AMT%TYPE,
	P_DIV_AMT		T_CASH_DIVIDEN.DIV_AMT%TYPE,
	P_CRE_DT		T_CASH_DIVIDEN.CRE_DT%TYPE,
	P_USER_ID		T_CASH_DIVIDEN.USER_ID%TYPE,
	P_UPD_DT		T_CASH_DIVIDEN.UPD_DT%TYPE,
	P_UPD_BY		T_CASH_DIVIDEN.UPD_BY%TYPE,
	P_APPROVED_DT		T_CASH_DIVIDEN.APPROVED_DT%TYPE,
	P_APPROVED_BY		T_CASH_DIVIDEN.APPROVED_BY%TYPE,
	P_APPROVED_STAT		T_CASH_DIVIDEN.APPROVED_STAT%TYPE,
	P_RVPV_NUMBER		T_CASH_DIVIDEN.RVPV_NUMBER%TYPE,
	P_CUM_DATE		T_CASH_DIVIDEN.CUM_DATE%TYPE,
	P_CUM_QTY		T_CASH_DIVIDEN.CUM_QTY%TYPE,
	P_ONH		T_CASH_DIVIDEN.ONH%TYPE,
	P_SELISIH_QTY		T_CASH_DIVIDEN.SELISIH_QTY%TYPE,
	P_CUMDT_DIV_AMT		T_CASH_DIVIDEN.CUMDT_DIV_AMT%TYPE,
	P_RVPV_KOREKSI		T_CASH_DIVIDEN.RVPV_KOREKSI%TYPE,
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
v_table_name 					T_MANY_DETAIL.table_name%TYPE := 'T_CASH_DIVIDEN';
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
FROM T_CASH_DIVIDEN
WHERE CA_TYPE = p_search_CA_TYPE
AND STK_CD = p_search_STK_CD
AND DISTRIB_DT= P_SEARCH_DISTRIB_DT
AND CLIENT_CD = P_CLIENT_CD;

v_many_detail  Types.many_detail_rc;

v_rec T_CASH_DIVIDEN%ROWTYPE;

v_cnt INTEGER;
i INTEGER;
V_FIELD_CNT NUMBER;
v_pending_cnt NUMBER;
va CHAR(1) := '@';

BEGIN
	IF P_UPD_STATUS = 'I' AND (P_SEARCH_CA_TYPE<> P_CA_TYPE OR P_SEARCH_STK_CD <> P_STK_CD OR P_SEARCH_DISTRIB_DT <> P_DISTRIB_DT OR P_SEARCH_CLIENT_CD <> P_CLIENT_CD) THEN
		IF P_SEARCH_CA_TYPE<> P_CA_TYPE THEN
			v_error_code := -2001;
			v_error_msg := 'jika INSERT, P_SEARCH_CA_TYPE harus sama dengan P_CA_TYPE';
			RAISE v_err;
		END IF;
		IF P_SEARCH_STK_CD <> P_STK_CD THEN
			v_error_code := -2002;
			v_error_msg := 'jika INSERT, P_SEARCH_STK_CD harus sama dengan P_STK_CD';
			RAISE v_err;
		END IF;
		IF P_SEARCH_DISTRIB_DT <> P_DISTRIB_DT  THEN
			v_error_code := -2003;
			v_error_msg := 'jika INSERT,  P_SEARCH_DISTRIB_DT harus sama dengan  P_DISTRIB_DT';
			RAISE v_err;
		END IF;
		IF P_SEARCH_CLIENT_CD <> P_CLIENT_CD THEN
			v_error_code := -2004;
			v_error_msg := 'jika INSERT,  P_SEARCH_CLIENT_CD  harus sama dengan P_CLIENT_CD ';
			RAISE v_err;
		END IF;
	END IF;

    BEGIN
		SELECT ROWID INTO v_table_rowid FROM T_CASH_DIVIDEN
		WHERE CA_TYPE = p_search_CA_TYPE
			AND STK_CD = p_search_STK_CD
			AND DISTRIB_DT= P_SEARCH_DISTRIB_DT
			AND CLIENT_CD = P_CLIENT_CD;
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
			FROM (SELECT MAX(CA_TYPE) CA_TYPE, MAX(STK_CD) STK_CD, MAX(DISTRIB_DT) DISTRIB_DT, MAX(CLIENT_CD) CLIENT_CD
				  FROM (SELECT DECODE (field_name, 'CA_TYPE', field_value, NULL) CA_TYPE,
							   DECODE (field_name, 'STK_CD', field_value, NULL) STK_CD,
							   DECODE (field_name, 'DISTRIB_DT', field_value, NULL) DISTRIB_DT,
							   DECODE (field_name, 'CLIENT_CD', field_value, NULL) CLIENT_CD,
							   d.update_seq, record_seq, field_name
						FROM T_MANY_DETAIL D, T_MANY_HEADER H
						WHERE d.table_name = v_table_name
						AND d.update_date = h.update_date
						AND d.update_seq = h.update_seq
						AND (d.field_name = 'CA_TYPE' OR d.field_name = 'STK_CD' OR d.field_name = 'DISTRIB_DT' OR d.field_name = 'CLIENT_cD')
						AND h.APPROVED_status = 'E'
						ORDER BY d.update_seq, record_seq, field_name)
						GROUP BY update_seq, record_seq)	-- Agar SELECT MAX dapat me-retrieve composite primary key untuk setiap record
			WHERE CA_TYPE = p_search_CA_TYPE
			AND STK_CD = p_search_STK_CD
			AND DISTRIB_DT= P_SEARCH_DISTRIB_DT
			AND CLIENT_CD = P_CLIENT_CD;
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
		UNION
		SELECT v_table_name, 'REPO_REF', 'S' FROM dual
		) a,
		( SELECT  'CA_TYPE'  AS field_name, p_CA_TYPE AS field_value, DECODE(trim(v_rec.CA_TYPE), trim(p_CA_TYPE),'N','Y') upd_flg FROM dual
			UNION
			SELECT  'STK_CD'  AS field_name, p_STK_CD AS field_value, DECODE(trim(v_rec.STK_CD), trim(p_STK_CD),'N','Y') upd_flg FROM dual
			UNION
			SELECT  'DISTRIB_DT'  AS field_name, TO_CHAR(p_DISTRIB_DT,'yyyy/mm/dd hh24:mi:ss')  AS field_value, DECODE(v_rec.DISTRIB_DT, p_DISTRIB_DT,'N','Y') upd_flg FROM dual
			UNION
			SELECT  'CLIENT_CD'  AS field_name, p_CLIENT_CD AS field_value, DECODE(trim(v_rec.CLIENT_CD), trim(p_CLIENT_CD),'N','Y') upd_flg FROM dual
			UNION
			SELECT  'QTY'  AS field_name, TO_CHAR(p_QTY)  AS field_value, DECODE(v_rec.QTY, p_QTY,'N','Y') upd_flg FROM dual
			UNION
			SELECT  'RATE'  AS field_name, TO_CHAR(p_RATE)  AS field_value, DECODE(v_rec.RATE, p_RATE,'N','Y') upd_flg FROM dual
			UNION
			SELECT  'GROSS_AMT'  AS field_name, TO_CHAR(p_GROSS_AMT)  AS field_value, DECODE(v_rec.GROSS_AMT, p_GROSS_AMT,'N','Y') upd_flg FROM dual
			UNION
			SELECT  'TAX_PCN'  AS field_name, TO_CHAR(p_TAX_PCN)  AS field_value, DECODE(v_rec.TAX_PCN, p_TAX_PCN,'N','Y') upd_flg FROM dual
			UNION
			SELECT  'TAX_AMT'  AS field_name, TO_CHAR(p_TAX_AMT)  AS field_value, DECODE(v_rec.TAX_AMT, p_TAX_AMT,'N','Y') upd_flg FROM dual
			UNION
			SELECT  'DIV_AMT'  AS field_name, TO_CHAR(p_DIV_AMT)  AS field_value, DECODE(v_rec.DIV_AMT, p_DIV_AMT,'N','Y') upd_flg FROM dual
			UNION
			SELECT  'RVPV_NUMBER'  AS field_name, p_RVPV_NUMBER AS field_value, DECODE(trim(v_rec.RVPV_NUMBER), trim(p_RVPV_NUMBER),'N','Y') upd_flg FROM dual
			UNION
			SELECT  'CUM_DATE'  AS field_name, TO_CHAR(p_CUM_DATE,'yyyy/mm/dd hh24:mi:ss')  AS field_value, DECODE(v_rec.CUM_DATE, p_CUM_DATE,'N','Y') upd_flg FROM dual
			UNION
			SELECT  'CUM_QTY'  AS field_name, TO_CHAR(p_CUM_QTY)  AS field_value, DECODE(v_rec.CUM_QTY, p_CUM_QTY,'N','Y') upd_flg FROM dual
			UNION
			SELECT  'ONH'  AS field_name, TO_CHAR(p_ONH)  AS field_value, DECODE(v_rec.ONH, p_ONH,'N','Y') upd_flg FROM dual
			UNION
			SELECT  'SELISIH_QTY'  AS field_name, TO_CHAR(p_SELISIH_QTY)  AS field_value, DECODE(v_rec.SELISIH_QTY, p_SELISIH_QTY,'N','Y') upd_flg FROM dual
			UNION
			SELECT  'CUMDT_DIV_AMT'  AS field_name, TO_CHAR(p_CUMDT_DIV_AMT)  AS field_value, DECODE(v_rec.CUMDT_DIV_AMT, p_CUMDT_DIV_AMT,'N','Y') upd_flg FROM dual
			UNION
			SELECT  'RVPV_KOREKSI'  AS field_name, p_RVPV_KOREKSI AS field_value, DECODE(trim(v_rec.RVPV_KOREKSI), trim(p_RVPV_KOREKSI),'N','Y') upd_flg FROM dual
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
		AND  (P_UPD_STATUS <> 'C' OR (P_UPD_STATUS = 'C' AND a.field_name = 'XN_DOC_NUM'));

		 
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
END Sp_T_CASH_DIVIDEN_Upd;