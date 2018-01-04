create or replace 
PROCEDURE Sp_rincian_porto_approve(
	   p_menu_name							T_MANY_HEADER.menu_name%TYPE,
	   p_update_date						T_MANY_HEADER.update_date%TYPE,
	   p_update_seq							T_MANY_HEADER.update_seq%TYPE,
	   p_approved_user_id				  	T_MANY_HEADER.user_id%TYPE,
	   p_approved_ip_address 		 		T_MANY_HEADER.ip_address%TYPE,
	   p_error_code							OUT NUMBER,
	   p_error_msg							OUT VARCHAR2
	   ) IS




v_err EXCEPTION;
v_error_code						NUMBER;
v_error_msg							VARCHAR2(200);
BEGIN
	
	BEGIN
	UPDATE INSISTPRO_RPT.LAP_RINCIAN_PORTO SET APPROVED_STS ='A',approved_by=p_approved_user_id, APPROVED_DT = SYSDATE WHERE UPDATE_SEQ=P_UPDATE_SEQ AND UPDATE_DATE=P_UPDATE_DATE;
	EXCEPTION
			WHEN OTHERS THEN
				v_error_code := -3;
				v_error_msg :=  SUBSTR('UPDATE LAP_RINCIAN_PORTO '||SQLERRM,1,200);
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
				v_error_code := -4;
				v_error_msg :=  SUBSTR('Update t_MANY_HEADER  '||SQLERRM,1,200);
				RAISE v_err;
		END;	
/*
	EXCEPTION
	WHEN OTHERS THEN
   		v_error_code := -5;
		v_error_msg :=  SUBSTR('Update T_MANY_HEADER '||SQLERRM,1,200);
		RAISE v_err;
	END;
*/
   	p_error_code := 1;
	p_error_msg := '';
-- 		   IF p_commit = 1 THEN
-- 		   	  COMMIT;
-- 		   END IF;

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
END Sp_rincian_porto_approve;