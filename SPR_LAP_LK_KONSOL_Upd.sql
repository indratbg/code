create or replace PROCEDURE SPR_LAP_LK_KONSOL_Upd(
	P_REPORT_DATE		LAP_LK_KONSOL.REPORT_DATE%TYPE,
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
	v_table_name 				IPNEXTG.T_MANY_DETAIL.table_name%TYPE := 'LAP_LK_KONSOL';
	v_table_rowid	   			IPNEXTG.T_MANY_DETAIL.table_rowid%TYPE;
  v_MANY_DETAIL  IPNEXTG.Types.MANY_DETAIL_rc;

BEGIN


	OPEN v_MANY_DETAIL FOR
		SELECT p_update_date AS update_date, p_update_seq AS update_seq, v_table_name AS table_name, p_record_seq AS record_seq,
    NULL AS table_rowid, 'REPORT_DATE'  AS field_name,'D'  field_type,  TO_CHAR(P_REPORT_DATE,'yyyy/mm/dd hh24:mi:ss')  AS field_value, 
    p_upd_status AS status,  'Y' upd_flg FROM DUAL;
    
	BEGIN
		Sp_T_MANY_DETAIL_Insert(p_update_date,   p_update_seq,   p_upd_status,v_table_name, p_record_seq , v_table_rowid, v_MANY_DETAIL, v_error_code, v_error_msg);
	EXCEPTION
		WHEN OTHERS THEN
			v_error_code := -7;
			v_error_msg := SUBSTR('SP_T_MANY_DETAIL_INSERT '||v_table_name||SQLERRM,1,200);
			RAISE v_err;
	END;

	CLOSE v_MANY_DETAIL;

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

END SPR_LAP_LK_KONSOL_Upd;