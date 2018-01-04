create or replace 
PROCEDURE SP_UPLOAD_T_SUBREK_KSEI_LOG(
	P_STATUS_DT		T_SUBREK_KSEI.STATUS_DT%TYPE,
	p_record_seq T_MANY_DETAIL.RECORD_SEQ%TYPE,
	P_USER_ID T_MANY_HEADER.USER_ID%TYPE,
	p_upd_status T_MANY_DETAIL.UPD_STATUS%TYPE,
	P_IP_ADDRESS T_MANY_HEADER.IP_ADDRESS%TYPE,
	p_error_code					OUT			NUMBER,
	p_error_msg						OUT			VARCHAR2
) IS



	v_err EXCEPTION;
	v_error_code				NUMBER;
	v_error_msg					VARCHAR2(1000);
	v_table_name 				IPNEXTG.T_MANY_DETAIL.table_name%TYPE := 'T_SUBREK_KSEI';
	v_table_rowid	   			IPNEXTG.T_MANY_DETAIL.table_rowid%TYPE;

CURSOR csr_table IS
SELECT *
FROM T_SUBREK_KSEI;

v_MANY_DETAIL  IPNEXTG.Types.MANY_DETAIL_rc;

v_rec T_SUBREK_KSEI%ROWTYPE;

v_cnt INTEGER;
 i INTEGER;
 V_FIELD_CNT NUMBER;
 v_pending_cnt NUMBER;
  V_MENU_NAME T_MANY_HEADER.MENU_NAME%type :='UPLOAD SUBREK AND SID';
  V_UPDATE_DATE T_MANY_HEADER.UPDATE_DATE%TYPE;
  V_UPDATE_SEQ T_MANY_HEADER.UPDATE_SEQ%TYPE;
BEGIN

--EXECUTE T MANY HEADER
  
  BEGIN
    Sp_T_Many_Header_Insert(V_MENU_NAME, 'I', P_USER_ID, P_IP_ADDRESS, NULL, V_UPDATE_DATE, V_UPDATE_SEQ, v_error_code, v_error_msg);
  EXCEPTION
  WHEN OTHERS THEN
    v_error_code := -10;
    v_error_msg  := SUBSTR('SP_T_MANY_HEADER_INSERT '|| SQLERRM(SQLCODE),1,200);
    RAISE V_ERR;
  END;
  
  IF V_ERROR_CODE <0 THEN
    v_error_code := -20;
    v_error_msg  :=SUBSTR('Sp_T_Many_Header_Insert : '||SQLERRM(SQLCODE),1,200);
    RAISE v_err;
  END IF;



	OPEN csr_Table;
	FETCH csr_Table INTO v_rec;

	OPEN v_MANY_DETAIL FOR
		SELECT V_update_date AS update_date, V_update_seq AS update_seq, table_name, p_record_seq AS record_seq, v_table_rowid AS table_rowid, a.field_name,  field_type, b.field_value, p_upd_status AS status,  b.upd_flg
		FROM(
			SELECT  v_table_name AS table_name, column_name AS field_name, DECODE(data_type,'VARCHAR2','S','CHAR','S','NUMBER','N','DATE','D','X') AS field_type
			FROM all_tab_columns
			WHERE table_name = v_table_name
			AND COLUMN_NAME = 'STATUS_DT'
         AND OWNER='IPNEXTG'
			) a,
		( 
			SELECT  'STATUS_DT'  AS field_name, TO_CHAR(P_STATUS_DT,'yyyy/mm/dd hh24:mi:ss')  AS field_value, DECODE(v_rec.STATUS_DT, P_STATUS_DT,'N','Y') upd_flg FROM dual
			
		) b
		WHERE a.field_name = b.field_name;


	BEGIN
		Sp_T_MANY_DETAIL_Insert(V_update_date,   V_update_seq,   P_UPD_STATUS,v_table_name, p_record_seq , v_table_rowid, v_MANY_DETAIL, v_error_code, v_error_msg);
	EXCEPTION
		WHEN OTHERS THEN
			v_error_code := -30;
			v_error_msg := SUBSTR('SP_T_MANY_DETAIL_INSERT '||v_table_name||SQLERRM,1,200);
			RAISE v_err;
	END;

	CLOSE v_MANY_DETAIL;
	CLOSE csr_Table;

	IF v_error_code < 0 THEN
	    v_error_code := -40;
		v_error_msg := 'SP_T_MANY_DETAIL_INSERT'||v_table_name||' '||v_error_msg;
		RAISE v_err;
	END IF;


  BEGIN
    Sp_T_Many_Approve( V_MENU_NAME, V_update_date, V_UPDATE_SEQ, p_user_id, p_ip_address, v_error_code, v_error_msg);
  EXCEPTION
  WHEN OTHERS THEN
    v_error_code := -50;
    v_error_msg  :=SUBSTR('Sp_T_Many_Approve: '||SQLERRM,1,200);
    RAISE v_err;
  END;
  
  IF V_ERROR_CODE <0 THEN
    v_error_code := -60;
    v_error_msg  :=SUBSTR('Sp_T_Many_Approve : '||SQLERRM,1,200);
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
END SP_UPLOAD_T_SUBREK_KSEI_LOG;