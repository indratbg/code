create or replace 
PROCEDURE Sp_T_JVCHH_Upd(
	P_SEARCH_JVCH_NUM		T_JVCHH.JVCH_NUM%TYPE,
	P_JVCH_NUM		T_JVCHH.JVCH_NUM%TYPE,
	P_JVCH_TYPE		T_JVCHH.JVCH_TYPE%TYPE,
	P_JVCH_DATE		T_JVCHH.JVCH_DATE%TYPE,
	P_GL_ACCT_CD		T_JVCHH.GL_ACCT_CD%TYPE,
	P_SL_ACCT_CD		T_JVCHH.SL_ACCT_CD%TYPE,
	P_CURR_CD		T_JVCHH.CURR_CD%TYPE,
	P_CURR_AMT		T_JVCHH.CURR_AMT%TYPE,
	P_REMARKS		T_JVCHH.REMARKS%TYPE,
	P_USER_ID		T_JVCHH.USER_ID%TYPE,
	P_CRE_DT		T_JVCHH.CRE_DT%TYPE,
	P_UPD_DT		T_JVCHH.UPD_DT%TYPE,
	P_FOLDER_CD		T_JVCHH.FOLDER_CD%TYPE,
	P_REVERSAL_JUR		T_JVCHH.REVERSAL_JUR%TYPE,
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
	v_table_name 				T_MANY_DETAIL.table_name%TYPE := 'T_JVCHH';
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
FROM T_JVCHH
WHERE JVCH_NUM = P_SEARCH_JVCH_NUM;

v_MANY_DETAIL  Types.MANY_DETAIL_rc;

v_rec T_JVCHH%ROWTYPE;

v_cnt INTEGER;
 i INTEGER;
 V_FIELD_CNT NUMBER;
 v_pending_cnt NUMBER;
 va CHAR(1) := '@';
BEGIN

IF P_UPD_STATUS = 'I' AND P_SEARCH_JVCH_NUM <> p_JVCH_NUM THEN
		v_error_code := -2001; 
		v_error_msg := 'jika INSERT, P_SEARCH_JVCH_NUM harus sama dengan  p_JVCH_NUM';
		RAISE v_err;
	END IF;
	

    BEGIN
		SELECT ROWID INTO v_table_rowid
		FROM T_JVCHH
		WHERE JVCH_NUM = p_search_JVCH_NUM;
		
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			v_table_rowid := NULL;
		WHEN OTHERS THEN
			v_error_code := -2;
			v_error_msg :=  SUBSTR('Retrieve  '|| v_table_name||' for '||p_search_JVCH_NUM||SQLERRM,1,200);
			RAISE v_err;
	END;
	
	IF 	P_UPD_STATUS = 'I' AND v_table_rowid IS NOT NULL THEN
		v_error_code := -2003;
		v_error_msg  := 'DUPLICATED JVCH_NUM';
		RAISE v_err;
	END IF;
	
	IF 	P_UPD_STATUS = 'U' AND  P_SEARCH_JVCH_NUM <> p_JVCH_NUM THEN
		BEGIN
	   	 	SELECT COUNT(1) INTO v_cnt
			FROM T_JVCHH
			WHERE JVCH_NUM = p_search_JVCH_NUM;
			
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				v_cnt := 0;
			WHEN OTHERS THEN
				v_error_code := -3;
				v_error_msg :=  SUBSTR('Retrieve  '|| v_table_name||' for '||p_JVCH_NUM||SQLERRM,1,200);
				RAISE v_err;
		END; 
				  
		IF v_cnt  > 0 THEN
			v_error_code := -2004;
			v_error_msg  := 'DUPLICATED JVCH_NUM';
			RAISE v_err;
		END IF;
	END IF;	

	--OPEN csr_Table;
--	FETCH csr_Table INTO v_rec;	  
			  
	IF v_table_rowid IS NULL THEN
		BEGIN
					SELECT COUNT(1) INTO v_pending_cnt
			FROM T_MANY_DETAIL D, T_MANY_HEADER H
			WHERE d.table_name = v_table_name
			AND d.update_date = h.update_date
			AND d.update_seq = h.update_seq
			AND d.field_name = 'JVCH_NUM'
			AND d.field_value = p_search_JVCH_NUM
			AND h.APPROVED_status = 'E';
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
			SELECT  'JVCH_NUM'  AS field_name, p_JVCH_NUM AS field_value, DECODE(trim(v_rec.JVCH_NUM), trim(p_JVCH_NUM),'N','Y') upd_flg FROM dual
			UNION
			SELECT  'JVCH_TYPE'  AS field_name, p_JVCH_TYPE AS field_value, DECODE(trim(v_rec.JVCH_TYPE), trim(p_JVCH_TYPE),'N','Y') upd_flg FROM dual
			UNION
			SELECT  'JVCH_DATE'  AS field_name, TO_CHAR(p_JVCH_DATE,'yyyy/mm/dd hh24:mi:ss')  AS field_value, DECODE(v_rec.JVCH_DATE, p_JVCH_DATE,'N','Y') upd_flg FROM dual
			UNION
			SELECT  'GL_ACCT_CD'  AS field_name, p_GL_ACCT_CD AS field_value, DECODE(trim(v_rec.GL_ACCT_CD), trim(p_GL_ACCT_CD),'N','Y') upd_flg FROM dual
			UNION
			SELECT  'SL_ACCT_CD'  AS field_name, p_SL_ACCT_CD AS field_value, DECODE(trim(v_rec.SL_ACCT_CD), trim(p_SL_ACCT_CD),'N','Y') upd_flg FROM dual
			UNION
			SELECT  'CURR_CD'  AS field_name, p_CURR_CD AS field_value, DECODE(trim(v_rec.CURR_CD), trim(p_CURR_CD),'N','Y') upd_flg FROM dual
			UNION
			SELECT  'CURR_AMT'  AS field_name, TO_CHAR(p_CURR_AMT)  AS field_value, DECODE(v_rec.CURR_AMT, p_CURR_AMT,'N','Y') upd_flg FROM dual
			UNION
			SELECT  'REMARKS'  AS field_name, p_REMARKS AS field_value, DECODE(trim(v_rec.REMARKS), trim(p_REMARKS),'N','Y') upd_flg FROM dual
			UNION
			SELECT  'FOLDER_CD'  AS field_name, p_FOLDER_CD AS field_value, DECODE(trim(v_rec.FOLDER_CD), trim(p_FOLDER_CD),'N','Y') upd_flg FROM dual
			UNION
			SELECT  'REVERSAL_JUR'  AS field_name, p_REVERSAL_JUR AS field_value, DECODE(trim(v_rec.REVERSAL_JUR), trim(p_REVERSAL_JUR),'N','Y') upd_flg FROM dual
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

END Sp_T_JVCHH_Upd;