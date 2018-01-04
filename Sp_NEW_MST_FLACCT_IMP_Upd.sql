create or replace 
PROCEDURE Sp_NEW_MST_FLACCT_IMP_Upd(
		P_SEARCH_CLIENT_CD	MST_CLIENT_FLACCT.CLIENT_CD%TYPE,
		P_SEARCH_BANK_ACCT_NUM		MST_CLIENT_FLACCT.BANK_ACCT_NUM%TYPE,
		P_CLIENT_CD		MST_CLIENT_FLACCT.CLIENT_CD%TYPE,
		P_BANK_CD		MST_CLIENT_FLACCT.BANK_CD%TYPE,
		P_BANK_ACCT_NUM		MST_CLIENT_FLACCT.BANK_ACCT_NUM%TYPE,
		P_ACCT_NAME		MST_CLIENT_FLACCT.ACCT_NAME%TYPE,
		P_ACCT_STAT		MST_CLIENT_FLACCT.ACCT_STAT%TYPE,
		P_BANK_SHORT_NAME		MST_CLIENT_FLACCT.BANK_SHORT_NAME%TYPE,
		P_BANK_ACCT_FMT		MST_CLIENT_FLACCT.BANK_ACCT_FMT%TYPE,
		P_CRE_DT		MST_CLIENT_FLACCT.CRE_DT%TYPE,
		P_USER_ID		MST_CLIENT_FLACCT.USER_ID%TYPE,
		P_UPD_DT		MST_CLIENT_FLACCT.UPD_DT%TYPE,
		P_UPD_USER_ID		MST_CLIENT_FLACCT.UPD_USER_ID%TYPE,
		P_UPD_BY		MST_CLIENT_FLACCT.UPD_BY%TYPE,
		P_FROM_DT		MST_CLIENT_FLACCT.FROM_DT%TYPE,
		P_TO_DT		MST_CLIENT_FLACCT.TO_DT%TYPE,
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
	v_table_name 				T_MANY_DETAIL.table_name%TYPE := 'MST_CLIENT_FLACCT';
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
FROM MST_CLIENT_FLACCT
WHERE CLIENT_CD = p_search_CLIENT_CD
	AND BANK_ACCT_NUM = p_search_BANK_ACCT_NUM;

v_MANY_DETAIL  Types.MANY_DETAIL_rc;

v_rec MST_CLIENT_FLACCT%ROWTYPE;

v_cnt INTEGER;
 i INTEGER;
 V_FIELD_CNT NUMBER;
 v_pending_cnt NUMBER;
 va CHAR(1) := '@';
BEGIN
/*
	IF 	P_UPD_STATUS = 'I' AND (P_SEARCH_DOC_REF_NUM <> P_DOC_REF_NUM) THEN
		v_error_code := -2001;
		IF P_SEARCH_DOC_REF_NUM <> p_DOC_REF_NUM THEN
			v_error_msg := 'jika INSERT, P_SEARCH_DOC_REF_NUM harus sama dengan P_DOC_REF_NUM';
		END IF;
		RAISE v_err;
	END IF;
	*/		
    BEGIN
   	 	SELECT ROWID INTO v_table_rowid
		FROM MST_CLIENT_FLACCT
		WHERE CLIENT_CD = p_search_CLIENT_CD
		AND BANK_ACCT_NUM = p_search_BANK_ACCT_NUM
		AND approved_stat = 'A';
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			v_table_rowid := NULL;
		WHEN OTHERS THEN
			v_error_code := -2;
			v_error_msg :=  SUBSTR('Retrieve  '|| v_table_name||' for '||P_SEARCH_CLIENT_CD||SQLERRM,1,200);
			RAISE v_err;
	END;
/*
	IF 	P_UPD_STATUS = 'I' AND v_table_rowid IS NOT NULL  THEN
		
			v_error_code := -2002;
			v_error_msg  := 'DUPLICATED DOC_REF_NUM' ;
			RAISE v_err;

	END IF;
	*/	
  /*
	IF 	P_UPD_STATUS = 'U' THEN
		IF	P_SEARCH_DOC_REF_NUM <> P_DOC_REF_NUM THEN
			BEGIN
				SELECT COUNT(1) INTO v_cnt
				FROM MST_CLIENT_FLACCT
				WHERE DOC_REF_NUM = p_DOC_REF_NUM
				
				AND approved_sts = 'A';
			EXCEPTION
				WHEN NO_DATA_FOUND THEN
					v_cnt := 0;
				WHEN OTHERS THEN
					v_error_code := -2;
					v_error_msg :=  SUBSTR('Retrieve  '|| v_table_name||' for '||P_SEARCH_DOC_REF_NUM||SQLERRM,1,200);
					RAISE v_err;
			END;
				  
			IF v_cnt  > 0 THEN
				v_error_code := -2003;
				v_error_msg  := 'DUPLICATED DOC_REF_NUM';
				RAISE v_err;
			END IF;
		END IF;
	END IF;
			
    */	  
				  
	IF v_table_rowid IS NULL THEN
		BEGIN
			SELECT COUNT(1) INTO v_pending_cnt
			FROM (SELECT MAX(CLIENT_CD) CLIENT_CD, MAX(BANK_ACCT_NUM) BANK_ACCT_NUM
				  FROM (SELECT DECODE (field_name, 'CLIENT_CD', field_value, NULL) CLIENT_CD,
								DECODE (field_name, 'BANK_ACCT_NUM', field_value, NULL) BANK_ACCT_NUM,
							   d.update_seq, record_seq, field_name
						FROM T_MANY_DETAIL D, T_MANY_HEADER H
						WHERE d.table_name = v_table_name
						AND d.update_date = h.update_date
						AND d.update_seq = h.update_seq
						AND d.field_name IN  ('CLIENT_CD','BANK_ACCT_NUM')
						AND h.APPROVED_status = 'E'
						ORDER BY d.update_seq, record_seq, field_name)
						GROUP BY update_seq, record_seq)	-- Agar SELECT MAX dapat me-retrieve composite primary key untuk setiap record
			WHERE CLIENT_CD = P_SEARCH_CLIENT_CD AND BANK_ACCT_NUM=P_SEARCH_BANK_ACCT_NUM;
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
			SELECT  'CLIENT_CD'  AS field_name, p_CLIENT_CD AS field_value, DECODE(trim(v_rec.CLIENT_CD), trim(p_CLIENT_CD),'N','Y') upd_flg FROM dual
		UNION
		SELECT  'BANK_CD'  AS field_name, p_BANK_CD AS field_value, DECODE(trim(v_rec.BANK_CD), trim(p_BANK_CD),'N','Y') upd_flg FROM dual
		UNION
		SELECT  'BANK_ACCT_NUM'  AS field_name, p_BANK_ACCT_NUM AS field_value, DECODE(trim(v_rec.BANK_ACCT_NUM), trim(p_BANK_ACCT_NUM),'N','Y') upd_flg FROM dual
		UNION
		SELECT  'ACCT_NAME'  AS field_name, p_ACCT_NAME AS field_value, DECODE(trim(v_rec.ACCT_NAME), trim(p_ACCT_NAME),'N','Y') upd_flg FROM dual
		UNION
		SELECT  'ACCT_STAT'  AS field_name, p_ACCT_STAT AS field_value, DECODE(trim(v_rec.ACCT_STAT), trim(p_ACCT_STAT),'N','Y') upd_flg FROM dual
		UNION
		SELECT  'BANK_SHORT_NAME'  AS field_name, p_BANK_SHORT_NAME AS field_value, DECODE(trim(v_rec.BANK_SHORT_NAME), trim(p_BANK_SHORT_NAME),'N','Y') upd_flg FROM dual
		UNION
		SELECT  'BANK_ACCT_FMT'  AS field_name, p_BANK_ACCT_FMT AS field_value, DECODE(trim(v_rec.BANK_ACCT_FMT), trim(p_BANK_ACCT_FMT),'N','Y') upd_flg FROM dual
		UNION
		SELECT  'UPD_USER_ID'  AS field_name, p_UPD_USER_ID AS field_value, DECODE(trim(v_rec.UPD_USER_ID), trim(p_UPD_USER_ID),'N','Y') upd_flg FROM dual
		UNION
		SELECT  'FROM_DT'  AS field_name, TO_CHAR(p_FROM_DT,'yyyy/mm/dd hh24:mi:ss')  AS field_value, DECODE(v_rec.FROM_DT, p_FROM_DT,'N','Y') upd_flg FROM dual
		UNION
		SELECT  'TO_DT'  AS field_name, TO_CHAR(p_TO_DT,'yyyy/mm/dd hh24:mi:ss')  AS field_value, DECODE(v_rec.TO_DT, p_TO_DT,'N','Y') upd_flg FROM dual
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

END Sp_NEW_MST_FLACCT_IMP_Upd;