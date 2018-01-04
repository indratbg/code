create or replace 
PROCEDURE Sp_T_FUND_LEDGER_UPD(
	P_SEARCH_DOC_NUM	T_FUND_LEDGER.DOC_NUM%TYPE,
	P_SEARCH_SEQNO		T_FUND_LEDGER.SEQNO%TYPE,
	P_DOC_NUM		T_FUND_LEDGER.DOC_NUM%TYPE,
	P_SEQNO		T_FUND_LEDGER.SEQNO%TYPE,
	P_TRX_TYPE		T_FUND_LEDGER.TRX_TYPE%TYPE,
	P_DOC_DATE		T_FUND_LEDGER.DOC_DATE%TYPE,
	P_ACCT_CD		T_FUND_LEDGER.ACCT_CD%TYPE,
	P_CLIENT_CD		T_FUND_LEDGER.CLIENT_CD%TYPE,
	P_DEBIT		T_FUND_LEDGER.DEBIT%TYPE,
	P_CREDIT		T_FUND_LEDGER.CREDIT%TYPE,
	P_CRE_DT		T_FUND_LEDGER.CRE_DT%TYPE,
	P_USER_ID		T_FUND_LEDGER.USER_ID%TYPE,
	P_CANCEL_DT		T_FUND_LEDGER.CANCEL_DT%TYPE,
	P_CANCEL_BY		T_FUND_LEDGER.CANCEL_BY%TYPE,
	P_UPD_DT		T_FUND_LEDGER.UPD_DT%TYPE,
	P_UPD_BY		T_FUND_LEDGER.UPD_BY%TYPE,
  P_MANUAL T_FUND_LEDGER.MANUAL%TYPE,
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
	v_table_name 				T_MANY_DETAIL.table_name%TYPE := 'T_FUND_LEDGER';
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
FROM T_FUND_LEDGER
WHERE DOC_NUM = P_SEARCH_DOC_NUM
	AND SEQNO=P_SEARCH_SEQNO;

v_MANY_DETAIL  Types.MANY_DETAIL_rc;

v_rec T_FUND_LEDGER%ROWTYPE;

v_cnt INTEGER;
 i INTEGER;
 V_FIELD_CNT NUMBER;
 v_pending_cnt NUMBER;
 va CHAR(1) := '@';
BEGIN
	IF P_UPD_STATUS = 'I' AND (p_search_DOC_NUM <> p_DOC_NUM OR p_search_SEQNO <> p_SEQNO) THEN
		IF p_search_DOC_NUM <> p_DOC_NUM THEN
			v_error_code := -2001;
			v_error_msg := 'jika INSERT, p_search_DOC_NUM harus sama dengan P_DOC_NUM';
			RAISE v_err;
		END IF;
		IF p_search_SEQNO <> p_SEQNO THEN
			v_error_code := -2002;
			v_error_msg := 'jika INSERT, p_search_SEQNO harus sama dengan P_SEQNO';
			RAISE v_err;
		END IF;
	END IF;
		
    BEGIN
   	 	SELECT ROWID INTO v_table_rowid
		FROM T_FUND_LEDGER
		WHERE DOC_NUM= P_SEARCH_DOC_NUM
			and seqno=p_search_seqno;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			v_table_rowid := NULL;
		WHEN OTHERS THEN
			v_error_code := -2;
			v_error_msg :=  SUBSTR('Retrieve  '|| v_table_name||' for '||P_SEARCH_DOC_NUM||SQLERRM,1,200);
			RAISE v_err;
	END;

				  
	IF v_table_rowid IS NULL THEN
		BEGIN
			SELECT COUNT(1) INTO v_pending_cnt
			FROM (SELECT MAX(DOC_NUM) DOC_NUM, MAX(SEQNO) SEQNO
				  FROM (SELECT DECODE (field_name, 'DOC_NUM', field_value, NULL) DOC_NUM,
							  DECODE (field_name, 'SEQNO', field_value, NULL) SEQNO,
							   d.update_seq, record_seq, field_name
						FROM T_MANY_DETAIL D, T_MANY_HEADER H
						WHERE d.table_name = v_table_name
						AND d.update_date = h.update_date
						AND d.update_seq = h.update_seq
						AND (d.field_name = 'DOC_NUM' OR d.field_name = 'SEQNO')
						AND h.APPROVED_status = 'E'
						ORDER BY d.update_seq, record_seq, field_name)
						GROUP BY update_seq, record_seq)	-- Agar SELECT MAX dapat me-retrieve composite primary key untuk setiap record
			WHERE DOC_NUM = P_SEARCH_DOC_NUM
					AND SEQNO=P_SEARCH_SEQNO;
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
			SELECT  'DOC_NUM'  AS field_name, p_DOC_NUM AS field_value, DECODE(trim(v_rec.DOC_NUM), trim(p_DOC_NUM),'N','Y') upd_flg FROM dual
			UNION
			SELECT  'SEQNO'  AS field_name, TO_CHAR(p_SEQNO)  AS field_value, DECODE(v_rec.SEQNO, p_SEQNO,'N','Y') upd_flg FROM dual
			UNION
			SELECT  'TRX_TYPE'  AS field_name, p_TRX_TYPE AS field_value, DECODE(trim(v_rec.TRX_TYPE), trim(p_TRX_TYPE),'N','Y') upd_flg FROM dual
			UNION
			SELECT  'DOC_DATE'  AS field_name, TO_CHAR(p_DOC_DATE,'yyyy/mm/dd hh24:mi:ss')  AS field_value, DECODE(v_rec.DOC_DATE, p_DOC_DATE,'N','Y') upd_flg FROM dual
			UNION
			SELECT  'ACCT_CD'  AS field_name, p_ACCT_CD AS field_value, DECODE(trim(v_rec.ACCT_CD), trim(p_ACCT_CD),'N','Y') upd_flg FROM dual
			UNION
			SELECT  'CLIENT_CD'  AS field_name, p_CLIENT_CD AS field_value, DECODE(trim(v_rec.CLIENT_CD), trim(p_CLIENT_CD),'N','Y') upd_flg FROM dual
			UNION
			SELECT  'DEBIT'  AS field_name, TO_CHAR(p_DEBIT)  AS field_value, DECODE(v_rec.DEBIT, p_DEBIT,'N','Y') upd_flg FROM dual
			UNION
			SELECT  'CREDIT'  AS field_name, TO_CHAR(p_CREDIT)  AS field_value, DECODE(v_rec.CREDIT, p_CREDIT,'N','Y') upd_flg FROM dual
			UNION
			SELECT  'CANCEL_DT'  AS field_name, TO_CHAR(p_CANCEL_DT,'yyyy/mm/dd hh24:mi:ss')  AS field_value, DECODE(v_rec.CANCEL_DT, p_CANCEL_DT,'N','Y') upd_flg FROM dual
			UNION
			SELECT  'CANCEL_BY'  AS field_name, p_CANCEL_BY AS field_value, DECODE(trim(v_rec.CANCEL_BY), trim(p_CANCEL_BY),'N','Y') upd_flg FROM dual
			UNION
      SELECT  'MANUAL'  AS field_name, p_MANUAL AS field_value, DECODE(trim(v_rec.MANUAL), trim(p_MANUAL),'N','Y') upd_flg FROM dual
      UNION
			SELECT  'CRE_DT'  AS field_name, TO_CHAR(SYSDATE,'yyyy/mm/dd hh24:mi:ss')  AS field_value, 'Y' upd_flg FROM dual
					WHERE P_UPD_STATUS = 'I'
			UNION
			SELECT  'USER_ID'  AS field_name, p_USER_ID AS field_value, 'Y' upd_flg FROM dual
					WHERE P_UPD_STATUS = 'I'
			UNION
			SELECT  'UPD_DT'  AS field_name, TO_CHAR(SYSDATE,'yyyy/mm/dd hh24:mi:ss')  AS field_value, 'Y' upd_flg FROM dual
					WHERE P_UPD_STATUS = 'U'
			UNION
			SELECT  'UPD_BY'  AS field_name, p_USER_ID AS field_value, 'Y' upd_flg FROM dual
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
		v_error_msg := 'SP_T_MANY_DETAIL_INSERT '||v_table_name||' '||v_error_msg;
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

END  Sp_T_FUND_LEDGER_UPD;