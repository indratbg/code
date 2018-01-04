create or replace PROCEDURE Sp_T_TENDER_OFFER_SELL_UPD(
	P_SEARCH_CA_TYPE		T_TENDER_OFFER_SELL.CA_TYPE%TYPE,
P_SEARCH_STK_CD		T_TENDER_OFFER_SELL.STK_CD%TYPE,
P_SEARCH_TRX_DT		T_TENDER_OFFER_SELL.TRX_DT%TYPE,
P_SEARCH_CLIENT_CD		T_TENDER_OFFER_SELL.CLIENT_CD%TYPE,
P_CA_TYPE		T_TENDER_OFFER_SELL.CA_TYPE%TYPE,
P_STK_CD		T_TENDER_OFFER_SELL.STK_CD%TYPE,
P_TRX_DT		T_TENDER_OFFER_SELL.TRX_DT%TYPE,
P_CLIENT_CD		T_TENDER_OFFER_SELL.CLIENT_CD%TYPE,
P_QTY		T_TENDER_OFFER_SELL.QTY%TYPE,
P_PRICE		T_TENDER_OFFER_SELL.PRICE%TYPE,
P_GROSS_AMT		T_TENDER_OFFER_SELL.GROSS_AMT%TYPE,
P_FEE_PCN		T_TENDER_OFFER_SELL.FEE_PCN%TYPE,
P_FEE_AMT		T_TENDER_OFFER_SELL.FEE_AMT%TYPE,
P_NET_AMT		T_TENDER_OFFER_SELL.NET_AMT%TYPE,
P_CRE_DT		T_TENDER_OFFER_SELL.CRE_DT%TYPE,
P_USER_ID		T_TENDER_OFFER_SELL.USER_ID%TYPE,
P_UPD_DT		T_TENDER_OFFER_SELL.UPD_DT%TYPE,
P_UPD_BY		T_TENDER_OFFER_SELL.UPD_BY%TYPE,
P_RVPV_NUMBER		T_TENDER_OFFER_SELL.RVPV_NUMBER%TYPE,
P_PAYMENT_DT 		T_TENDER_OFFER_SELL.PAYMENT_DT%TYPE,
P_ROUNDING T_TENDER_OFFER_SELL.ROUNDING%TYPE,
P_ROUND_POINT T_TENDER_OFFER_SELL.ROUND_POINT%TYPE,
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
v_table_name 					T_MANY_DETAIL.table_name%TYPE := 'T_TENDER_OFFER_SELL';
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
FROM T_TENDER_OFFER_SELL
WHERE CA_TYPE = p_search_CA_TYPE
AND STK_CD = p_search_STK_CD
AND TRX_DT = P_SEARCH_TRX_DT
AND CLIENT_CD=P_SEARCH_CLIENT_CD;

v_many_detail  Types.many_detail_rc;

v_rec T_TENDER_OFFER_SELL%ROWTYPE;

v_cnt INTEGER;
i INTEGER;
V_FIELD_CNT NUMBER;
v_pending_cnt NUMBER;
va CHAR(1) := '@';

BEGIN
	IF P_UPD_STATUS = 'I' AND (p_search_CA_TYPE <> p_CA_TYPE OR p_search_STK_CD <> p_STK_CD OR P_SEARCH_TRX_DT <> P_TRX_DT OR P_SEARCH_CLIENT_CD <> P_CLIENT_CD) THEN
		IF p_search_CA_TYPE <> p_CA_TYPE THEN
			v_error_code := -2001;
			v_error_msg := 'jika INSERT, p_search_CA_TYPE harus sama dengan P_CA_TYPE';
			RAISE v_err;
		END IF;
		IF p_search_STK_CD <> p_STK_CD THEN
			v_error_code := -2002;
			v_error_msg := 'jika INSERT, p_search_STK_CD harus sama dengan P_STK_CD';
			RAISE v_err;
		END IF;
		IF P_SEARCH_TRX_DT <> P_TRX_DT THEN
			v_error_code := -2003;
			v_error_msg := 'jika INSERT, P_SEARCH_TRX_DT harus sama dengan P_TRX_DT';
			RAISE v_err;
		END IF;
		IF P_SEARCH_CLIENT_CD <> P_CLIENT_CD THEN
			v_error_code := -2003;
			v_error_msg := 'jika INSERT, P_SEARCH_CLIENT_CD harus sama dengan P_CLIENT_CD';
			RAISE v_err;
		END IF;
	END IF;

	BEGIN
		SELECT ROWID INTO v_table_rowid
		FROM T_TENDER_OFFER_SELL
		WHERE CA_TYPE = p_search_CA_TYPE
		AND STK_CD = p_search_STK_CD
		AND TRX_DT = P_SEARCH_TRX_DT
		AND CLIENT_CD=P_SEARCH_CLIENT_CD;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			v_table_rowid := NULL;
		WHEN OTHERS THEN
			v_error_code := -3;
			v_error_msg :=  SUBSTR('Retrieve  '|| v_table_name||' for '||P_SEARCH_STK_CD||SQLERRM,1,200);
			RAISE v_err;
	END;
	
	IF v_table_rowid IS NULL THEN
		BEGIN
			SELECT COUNT(1) INTO v_pending_cnt
			FROM 
			(
				SELECT MAX(CA_TYPE) CA_TYPE, MAX(STK_CD) STK_CD,MAX(TRX_DT) TRX_DT,MAX(CLIENT_CD) CLIENT_CD
				FROM 
				(
					SELECT DECODE (field_name, 'CA_TYPE', field_value, NULL) CA_TYPE,
							DECODE (field_name, 'STK_CD', field_value, NULL) STK_CD,
							DECODE (field_name, 'TRX_DT', field_value, NULL) TRX_DT,
							DECODE (field_name, 'CLIENT_CD', field_value, NULL) CLIENT_CD,
							d.update_seq, record_seq, field_name
					FROM T_MANY_DETAIL D, T_MANY_HEADER H
					WHERE d.table_name = v_table_name
					AND d.update_date = h.update_date
					AND d.update_seq = h.update_seq
					AND d.field_name IN ('CA_TYPE','STK_CD','TRX_DT','CLIENT_CD')
					AND h.APPROVED_status = 'E'
					ORDER BY d.update_seq, record_seq, field_name
				)
				GROUP BY update_seq, record_seq
			)	-- Agar SELECT MAX dapat me-retrieve composite primary key untuk setiap record
			WHERE CA_TYPE = p_search_CA_TYPE
			AND STK_CD = p_search_STK_CD
			AND TRX_DT = P_SEARCH_TRX_DT
			AND CLIENT_CD=P_SEARCH_CLIENT_CD;
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
		v_error_msg := 'Masih ada yang belum di-approve TAL '||p_search_CA_TYPE;
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
			SELECT  'CA_TYPE'  AS field_name, p_CA_TYPE AS field_value, DECODE(trim(v_rec.CA_TYPE), trim(p_CA_TYPE),'N','Y') upd_flg FROM dual
			UNION
			SELECT  'STK_CD'  AS field_name, p_STK_CD AS field_value, DECODE(trim(v_rec.STK_CD), trim(p_STK_CD),'N','Y') upd_flg FROM dual
			UNION
			SELECT  'TRX_DT'  AS field_name, TO_CHAR(p_TRX_DT,'yyyy/mm/dd hh24:mi:ss')  AS field_value, DECODE(v_rec.TRX_DT, p_TRX_DT,'N','Y') upd_flg FROM dual
			UNION
			SELECT  'CLIENT_CD'  AS field_name, p_CLIENT_CD AS field_value, DECODE(trim(v_rec.CLIENT_CD), trim(p_CLIENT_CD),'N','Y') upd_flg FROM dual
			UNION
			SELECT  'QTY'  AS field_name, TO_CHAR(p_QTY)  AS field_value, DECODE(v_rec.QTY, p_QTY,'N','Y') upd_flg FROM dual
			UNION
			SELECT  'PRICE'  AS field_name, TO_CHAR(p_PRICE)  AS field_value, DECODE(v_rec.PRICE, p_PRICE,'N','Y') upd_flg FROM dual
			UNION
			SELECT  'GROSS_AMT'  AS field_name, TO_CHAR(p_GROSS_AMT)  AS field_value, DECODE(v_rec.GROSS_AMT, p_GROSS_AMT,'N','Y') upd_flg FROM dual
			UNION
			SELECT  'FEE_PCN'  AS field_name, TO_CHAR(p_FEE_PCN)  AS field_value, DECODE(v_rec.FEE_PCN, p_FEE_PCN,'N','Y') upd_flg FROM dual
			UNION
			SELECT  'FEE_AMT'  AS field_name, TO_CHAR(p_FEE_AMT)  AS field_value, DECODE(v_rec.FEE_AMT, p_FEE_AMT,'N','Y') upd_flg FROM dual
			UNION
			SELECT  'NET_AMT'  AS field_name, TO_CHAR(p_NET_AMT)  AS field_value, DECODE(v_rec.NET_AMT, p_NET_AMT,'N','Y') upd_flg FROM dual
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
			UNION
			SELECT  'RVPV_NUMBER'  AS field_name, p_RVPV_NUMBER AS field_value, DECODE(trim(v_rec.RVPV_NUMBER), trim(p_RVPV_NUMBER),'N','Y') upd_flg FROM dual			
      UNION
			SELECT  'PAYMENT_DT'  AS field_name, TO_CHAR(P_PAYMENT_DT,'yyyy/mm/dd hh24:mi:ss') AS field_value, DECODE(trim(v_rec.PAYMENT_DT), trim(P_PAYMENT_DT),'N','Y') upd_flg FROM dual			
			UNION
			SELECT  'ROUNDING'  AS field_name, P_ROUNDING AS field_value, DECODE(trim(v_rec.ROUNDING), trim(P_ROUNDING),'N','Y') upd_flg FROM dual			
			UNION 
			SELECT  'ROUND_POINT'  AS field_name, TO_CHAR(P_ROUND_POINT)  AS field_value, DECODE(v_rec.ROUND_POINT, P_ROUND_POINT,'N','Y') upd_flg FROM dual
		) b
		WHERE a.field_name = b.field_name
		AND  (P_UPD_STATUS <> 'C' OR (P_UPD_STATUS = 'C' AND a.field_name = 'CA_TYPE'));

		 
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
END Sp_T_TENDER_OFFER_SELL_UPD;