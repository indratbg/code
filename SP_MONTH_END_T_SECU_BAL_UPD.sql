create or replace 
PROCEDURE SP_MONTH_END_T_SECU_BAL_UPD(
	P_BAL_DT		T_SECU_BAL.BAL_DT%TYPE,
	P_UPD_STATUS T_MANY_DETAIL.UPD_STATUS%TYPE,
	P_UPDATE_DATE		T_MANY_DETAIL.UPDATE_DATE%TYPE,
	P_UPDATE_SEQ		T_MANY_DETAIL.UPDATE_SEQ%TYPE,
	p_record_seq					IPNEXTG.T_MANY_DETAIL.RECORD_SEQ%TYPE,
	p_error_code					OUT			NUMBER,
	p_error_msg						OUT			VARCHAR2
) IS



	v_err EXCEPTION;
	v_error_code				NUMBER;
	v_error_msg					VARCHAR2(1000);
	v_table_name 				IPNEXTG.T_MANY_DETAIL.table_name%TYPE := 'T_SECU_BAL';
	v_table_rowid	   			IPNEXTG.T_MANY_DETAIL.table_rowid%TYPE;

CURSOR csr_table IS
SELECT *
FROM T_SECU_BAL;

v_MANY_DETAIL  IPNEXTG.Types.MANY_DETAIL_rc;

v_rec T_SECU_BAL%ROWTYPE;

v_cnt INTEGER;
 i INTEGER;
 V_FIELD_CNT NUMBER;
 v_pending_cnt NUMBER;
 va CHAR(1) := '@';
BEGIN

	OPEN csr_Table;
	FETCH csr_Table INTO v_rec;

	OPEN v_MANY_DETAIL FOR
		SELECT p_update_date AS update_date, p_update_seq AS update_seq, table_name, p_record_seq AS record_seq, v_table_rowid AS table_rowid, a.field_name,  field_type, b.field_value, p_upd_status AS status,  b.upd_flg
		FROM(
			SELECT  v_table_name AS table_name, column_name AS field_name, DECODE(data_type,'VARCHAR2','S','CHAR','S','NUMBER','N','DATE','D','X') AS field_type
			FROM all_tab_columns
			WHERE table_name = v_table_name
			AND COLUMN_NAME = 'BAL_DT'
			) a,
		( 
			SELECT  'BAL_DT'  AS field_name, TO_CHAR(P_BAL_DT,'yyyy/mm/dd hh24:mi:ss')  AS field_value, DECODE(v_rec.BAL_DT, P_BAL_DT,'N','Y') upd_flg FROM dual
			
		) b
		WHERE a.field_name = b.field_name;


	BEGIN
		Sp_T_MANY_DETAIL_Insert(p_update_date,   p_update_seq,   P_UPD_STATUS,v_table_name, p_record_seq , v_table_rowid, v_MANY_DETAIL, v_error_code, v_error_msg);
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

END SP_MONTH_END_T_SECU_BAL_UPD;