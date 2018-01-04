create or replace 
PROCEDURE           "SP_LAP_APPROVE" (
		P_TABLE_NAME VARCHAR2,
	   p_menu_name					T_many_HEADER.menu_name%TYPE,
	   p_update_date				T_many_HEADER.update_date%TYPE,
	   p_update_seq					T_many_HEADER.update_seq%TYPE,
	   P_APPROVED_USER_ID				T_many_HEADER.user_id%TYPE,
	   P_APPROVED_IP_ADDRESS          T_many_HEADER.approved_ip_address%TYPE,
	   p_error_code					OUT NUMBER,
	   p_error_msg					OUT VARCHAR2
	   ) IS

v_err EXCEPTION;
v_error_code						NUMBER;
v_error_msg							VARCHAR2(200);
v_sql varchar2(200);
BEGIN

begin
v_sql := 'UPDATE '||P_TABLE_NAME||' SET APPROVED_STAT= '''||'A'||''', APPROVED_BY='''||P_APPROVED_USER_ID||''',APPROVED_DT = '''||sysdate||''' WHERE UPDATE_SEQ ='''||p_update_seq ||''' and update_date = '''||p_update_date||'''';

 EXECUTE IMMEDIATE v_sql;
  EXCEPTION
        WHEN OTHERS THEN
      ROLLBACK;
          	v_error_code := -70;
			v_error_msg := SUBSTR('UPDATE '||P_TABLE_NAME||SQLERRM,1,200);
            RAISE v_err;
     END;     

	
	BEGIN
	UPDATE T_MANY_HEADER
			SET approved_status = 'A',
			approved_user_id = p_approved_user_id,
			approved_date = SYSDATE,
			approved_ip_address = p_approved_ip_address
			WHERE menu_name = p_menu_name
			AND update_date = p_update_date
			AND update_seq = p_update_seq;
	
	 EXCEPTION
        WHEN OTHERS THEN
      ROLLBACK;
          	v_error_code := -80;
			v_error_msg := SUBSTR('UPDATE '||P_TABLE_NAME||SQLERRM,1,200);
            RAISE v_err;
     END;     
	
	
	
	
	
	COMMIT;
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
		ROLLBACK;
		p_error_code := -1;
		p_error_msg := SUBSTR(SQLERRM,1,200);
		RAISE;
END SP_LAP_APPROVE;