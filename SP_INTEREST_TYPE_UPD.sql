create or replace 
PROCEDURE "SP_INTEREST_TYPE_UPD" (
	P_SEARCH_CLIENT_CD		MST_CLIENT.CLIENT_CD%TYPE,
	P_AMT_INT_FLG			MST_CLIENT.AMT_INT_FLG%TYPE,
	P_INT_ACCUMULATED		MST_CLIENT.INT_ACCUMULATED%TYPE,
	P_TAX_ON_INTEREST		MST_CLIENT.TAX_ON_INTEREST%TYPE,
	P_CRE_DT				MST_CLIENT.CRE_DT%TYPE,
	P_UPD_DT				MST_CLIENT.UPD_DT%TYPE,
	P_USER_ID				MST_CLIENT.USER_ID%TYPE,
	P_UPD_BY				MST_CLIENT.UPD_BY%TYPE,
	P_UPD_STATUS			T_MANY_DETAIL.UPD_STATUS%TYPE,
	p_ip_address			T_MANY_HEADER.IP_ADDRESS%TYPE,
	p_update_date			T_MANY_HEADER.UPDATE_DATE%TYPE,
	p_update_seq			T_MANY_HEADER.UPDATE_SEQ%TYPE,
	p_record_seq			T_MANY_DETAIL.RECORD_SEQ%TYPE,
	p_error_code			OUT			NUMBER,
	p_error_msg				OUT			VARCHAR2
) IS

	v_err EXCEPTION;
	v_error_code				NUMBER;
	v_error_msg					VARCHAR2(1000);
	v_table_name 				T_MANY_DETAIL.table_name%TYPE := 'MST_CLIENT';
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
FROM MST_CLIENT
WHERE CLIENT_CD = p_search_CLIENT_CD;

v_MANY_DETAIL  Types.MANY_DETAIL_rc;

v_rec MST_CLIENT%ROWTYPE;

v_cnt INTEGER;
 i INTEGER;
 V_FIELD_CNT NUMBER;
 v_pending_cnt NUMBER;
 va CHAR(1) := '@';
BEGIN
	 BEGIN
		SELECT ROWID INTO v_table_rowid
		FROM MST_CLIENT
		WHERE CLIENT_CD = p_search_CLIENT_CD;
	 EXCEPTION
		WHEN NO_DATA_FOUND THEN
			v_table_rowid := NULL;
		WHEN OTHERS THEN
			v_error_code := -2;
			v_error_msg :=  SUBSTR('Retrieve  '|| v_table_name||' for '||p_search_CLIENT_CD||SQLERRM,1,200);
			RAISE v_err;
	END;
	
	IF v_table_rowid IS NOT NULL THEN
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
			v_error_code := -4;
			v_error_msg :=  SUBSTR('Retrieve T_MANY_HEADER for '|| v_table_name||SQLERRM,1,200);
			RAISE v_err;
		END;
	ELSE
		v_error_code := -5;
		v_error_msg := 'Client Code tidak terdaftar';
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
			SELECT  'AMT_INT_FLG'  AS field_name, p_AMT_INT_FLG AS field_value, DECODE(trim(v_rec.AMT_INT_FLG), trim(p_AMT_INT_FLG),'N','Y') upd_flg FROM dual
			UNION
			SELECT  'INT_ACCUMULATED'  AS field_name, p_INT_ACCUMULATED AS field_value, DECODE(trim(v_rec.INT_ACCUMULATED), trim(p_INT_ACCUMULATED),'N','Y') upd_flg FROM dual
			UNION
			SELECT  'TAX_ON_INTEREST'  AS field_name, p_TAX_ON_INTEREST AS field_value, DECODE(trim(v_rec.TAX_ON_INTEREST), trim(p_TAX_ON_INTEREST),'N','Y') upd_flg FROM dual
			UNION
		  SELECT  'CRE_DT'  AS field_name, TO_CHAR(SYSDATE,'yyyy/mm/dd hh24:mi:ss')  AS field_value, 'Y' upd_flg FROM dual
      WHERE P_UPD_STATUS = 'I'
      UNION
      SELECT  'UPD_DT'  AS field_name, TO_CHAR(SYSDATE,'yyyy/mm/dd hh24:mi:ss')  AS field_value, 'Y' upd_flg FROM dual
      WHERE P_UPD_STATUS = 'U'
      UNION
      SELECT  'USER_ID'  AS field_name, p_USER_ID AS field_value, 'Y' upd_flg FROM dual
      WHERE P_UPD_STATUS = 'I'
			UNION
		  SELECT  'UPD_BY'  AS field_name, p_USER_ID AS field_value, 'Y' upd_flg FROM dual
      WHERE P_UPD_STATUS = 'U'		
				) b
		WHERE a.field_name = b.field_name
		AND  P_UPD_STATUS <> 'C';
		 
	v_status := 'U';

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

END Sp_Interest_Type_Upd;
