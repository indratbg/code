create or replace PROCEDURE SP_INTEREST_PROSES_UPD(
	P_PROCESS_TYPE VARCHAR2,
	P_CLIENT_TYPE VARCHAR2,
	P_BRANCH VARCHAR2,
	P_DUE_DATE_FROM DATE,
	P_DUE_DATE_TO DATE,
	P_JOURNAL_DATE DATE,
	P_UPD_STATUS T_MANY_DETAIL.UPD_STATUS%TYPE,
  P_USER_ID		T_MANY_HEADER.USER_ID%TYPE,
  P_IP_ADDRESS		T_MANY_HEADER.IP_ADDRESS%TYPE,
	p_record_seq					IPNEXTG.T_MANY_DETAIL.RECORD_SEQ%TYPE,
	p_error_code					OUT			NUMBER,
	p_error_msg						OUT			VARCHAR2
) IS



	v_err EXCEPTION;
	v_error_code				NUMBER;
	v_error_msg					VARCHAR2(200);
	v_table_name 				IPNEXTG.T_MANY_DETAIL.table_name%TYPE := 'T_INTEREST';
	v_table_rowid	   			IPNEXTG.T_MANY_DETAIL.table_rowid%TYPE;



v_MANY_DETAIL  IPNEXTG.Types.MANY_DETAIL_rc;

v_rec T_SECU_BAL%ROWTYPE;
V_Menu_Name T_MANY_HEADER.MENU_NAME%TYPE:='INTEREST PROCESS';
V_UPDATE_DATE		T_MANY_DETAIL.UPDATE_DATE%TYPE;
V_UPDATE_SEQ		T_MANY_DETAIL.UPDATE_SEQ%TYPE;
v_cnt INTEGER;
 i INTEGER;
 V_FIELD_CNT NUMBER;
 v_pending_cnt NUMBER;
 va CHAR(1) := '@';
BEGIN

  	--EXECUTE SP HEADER
			BEGIN
				Sp_T_Many_Header_Insert(V_Menu_Name,
									   P_UPD_STATUS,
									   P_USER_ID,
									   P_IP_ADDRESS,
									   NULL,
									   V_UPDATE_DATE,
									   V_UPDATE_SEQ,
									   v_error_code,
									   V_ERROR_MSG);
			EXCEPTION
				WHEN OTHERS THEN
					v_error_code := -11;
					V_Error_Msg := SUBSTR('SP_T_MANY_HEADER_INSERT '|| SQLERRM(SQLCODE),1,200);
					RAISE V_ERR;
			END; 


	--OPEN csr_Table;
	--FETCH csr_Table INTO v_rec;

	OPEN v_MANY_DETAIL FOR
		SELECT V_update_date AS update_date, V_update_seq AS update_seq, table_name, p_record_seq AS record_seq, v_table_rowid AS table_rowid, a.field_name,  field_type, b.field_value, p_upd_status AS status,  b.upd_flg
		FROM(
			SELECT v_table_name AS TABLE_NAME, 'PROSES_TYPE' AS FIELD_NAME, 'S' AS FIELD_TYPE FROM dual
      		UNION 
      		SELECT v_table_name AS TABLE_NAME, 'CLIENT_TYPE' AS FIELD_NAME, 'S' AS FIELD_TYPE FROM dual
      		UNION 
      		SELECT v_table_name AS TABLE_NAME, 'BRANCH' AS FIELD_NAME, 'S' AS FIELD_TYPE FROM dual
      		UNION 
      		SELECT v_table_name AS TABLE_NAME, 'DUE_DATE_FROM' AS FIELD_NAME, 'D' AS FIELD_TYPE FROM dual
      		UNION 
      		SELECT v_table_name AS TABLE_NAME, 'DUE_DATE_TO' AS FIELD_NAME, 'D' AS FIELD_TYPE FROM dual
      		UNION 
      		SELECT v_table_name AS TABLE_NAME, 'JOURNAL_DATE' AS FIELD_NAME, 'D'  AS FIELD_TYPE FROM dual
			) a,
			( 
				SELECT  'PROSES_TYPE'  AS field_name, P_PROCESS_TYPE  AS field_value, 'X' upd_flg FROM dual
				UNION
				SELECT  'CLIENT_TYPE'  AS field_name, P_CLIENT_TYPE  AS field_value, 'X' upd_flg FROM dual
				UNION
				SELECT  'BRANCH'  AS field_name, P_BRANCH  AS field_value, 'X' upd_flg FROM dual
				UNION
				SELECT  'DUE_DATE_FROM'  AS field_name, TO_CHAR(P_DUE_DATE_FROM,'yyyy/mm/dd hh24:mi:ss')  AS field_value, 'X' upd_flg FROM dual
				UNION
				SELECT  'DUE_DATE_TO'  AS field_name, TO_CHAR(P_DUE_DATE_TO,'yyyy/mm/dd hh24:mi:ss')  AS field_value, 'X' upd_flg FROM dual
				UNION
				SELECT  'JOURNAL_DATE'  AS field_name, TO_CHAR(P_JOURNAL_DATE,'yyyy/mm/dd hh24:mi:ss')  AS field_value, 'X' upd_flg FROM dual
			) b
			WHERE a.field_name = b.field_name;
	BEGIN
		Sp_T_MANY_DETAIL_Insert(V_update_date,   V_update_seq,  P_UPD_STATUS,v_table_name, p_record_seq , v_table_rowid, v_MANY_DETAIL, v_error_code, v_error_msg);
	EXCEPTION
		WHEN OTHERS THEN
			v_error_code := -7;
			v_error_msg := SUBSTR('SP_T_MANY_DETAIL_INSERT '||v_table_name||SQLERRM,1,200);
			RAISE v_err;
	END;

	CLOSE v_MANY_DETAIL;
--	CLOSE csr_Table;

	IF v_error_code < 0 THEN
	    v_error_code := -8;
		v_error_msg := 'SP_T_MANY_DETAIL_INSERT'||v_table_name||' '||v_error_msg;
		RAISE v_err;
	END IF;

BEGIN	
			UPDATE ipnextg.T_MANY_HEADER
			SET approved_status = 'A',
			approved_user_id = P_USER_ID,
			approved_date = SYSDATE,
			approved_ip_address = P_IP_ADDRESS
			WHERE menu_name = V_MENU_NAME
			AND update_date = V_UPDATE_DATE
			AND update_seq = V_UPDATE_SEQ;
		EXCEPTION
			WHEN OTHERS THEN
				v_error_code := -100;
				v_error_msg :=  SUBSTR('Update ipnextg.T_MANY_HEADER  '||SQLERRM,1,200);
				RAISE v_err;
		END;	
    
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

END SP_INTEREST_PROSES_UPD;