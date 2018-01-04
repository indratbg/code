create or replace 
PROCEDURE           "SP_RINCIAN_PORTO_REJECT" (
	   p_menu_name					T_many_HEADER.menu_name%TYPE,
	   p_update_date				T_many_HEADER.update_date%TYPE,
	   p_update_seq					T_many_HEADER.update_seq%TYPE,
	   p_reject_user_id				T_many_HEADER.user_id%TYPE,
	   p_reject_ip_address          T_many_HEADER.approved_ip_address%TYPE,
	   p_reject_reason				VARCHAR2,
	   p_error_code					OUT NUMBER,
	   p_error_msg					OUT VARCHAR2
	   ) IS

v_err EXCEPTION;
v_error_code						NUMBER;
v_error_msg							VARCHAR2(200);
BEGIN


-- ip_address yg mereject ??
	BEGIN
	UPDATE INSISTPRO_RPT.LAP_RINCIAN_PORTO SET APPROVED_STAT='C' WHERE UPDATE_SEQ = P_UPDATE_SEQ AND UPDATE_DATE=P_UPDATE_DATE;

EXCEPTION
	WHEN NO_DATA_FOUND THEN 
		v_error_code := -2;
		v_error_msg := SUBSTR('NO DATA FOUND INSISTPRO_RPT.LAP_RINCIAN_PORTO '||SQLERRM,1,200);
		RAISE v_err;
   
	WHEN OTHERS THEN
		v_error_code := -3;
		v_error_msg := SUBSTR('Update INSISTPRO_RPT.LAP_RINCIAN_PORTO '||SQLERRM,1,200);
		RAISE v_err;
	END;



	BEGIN
		UPDATE T_many_HEADER
		SET approved_status = 'R',
		approved_user_id = p_reject_user_id,
		approved_date = SYSDATE,
		approved_ip_address = p_reject_ip_address,
		reject_reason = p_reject_reason
		WHERE menu_name = p_menu_name
		AND update_date = p_update_date
		AND update_seq = p_update_seq
		AND approved_status = 'E';
	EXCEPTION
	WHEN NO_DATA_FOUND THEN 
		v_error_code := -4;
		v_error_msg := SUBSTR('No found T_many_Header '||SQLERRM,1,200);
		RAISE v_err;
   
	WHEN OTHERS THEN
		v_error_code := -5;
		v_error_msg := SUBSTR('Update T_many_Header '||SQLERRM,1,200);
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
END SP_RINCIAN_PORTO_REJECT;