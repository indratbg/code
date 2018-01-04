create or replace 
procedure SP_MKBD_GEN(p_update_date DATE,
								p_update_seq NUMBER,
								p_mkbd_date DATE,
								p_user_id       insistpro_rpt.lap_mkbd_vd51.user_id%TYPE,
								p_error_code			OUT			NUMBER,
								p_error_msg				OUT			VARCHAR2
								)IS


v_error_code NUMBER;
v_error_msg VARCHAR2(200);
V_ERR EXCEPTION;
V_SQL 	VARCHAR2(32767);
BEGIN

FOR I IN 1..9 LOOP
		--MKBD VD51-59
	V_SQL :='	BEGIN
			Sp_Mkbd_Vd5'||I||'(:p_update_date,
							:p_update_seq,
							:p_mkbd_date,
							:p_user_id,
							:p_error_code,
							:p_error_msg);
			END;';
	
	
		BEGIN
			EXECUTE IMMEDIATE v_sql USING p_update_date,P_UPDATE_SEQ,P_MKBD_DATE,P_USER_ID,OUT P_ERROR_CODE,OUT P_ERROR_MSG ;
		EXCEPTION
			WHEN OTHERS THEN
				v_error_code := -4;
				v_error_msg :=  SUBSTR('exec immediate UPDATE approved sts  '||v_sql,1,200);
				RAISE v_err;
		END;
	
END LOOP;

	
	 FOR SP IN ASCII('A')..ASCII('I') LOOP
		--MKBD VD510A-510I
	V_SQL :='	BEGIN
			Sp_Mkbd_Vd5'||CHR(SP)||'(:p_update_date,
							:p_update_seq,
							:p_mkbd_date,
							:p_user_id,
							:p_error_code,
							:p_error_msg);
			END;';
	
	
		BEGIN
			EXECUTE IMMEDIATE v_sql USING p_update_date,P_UPDATE_SEQ,P_MKBD_DATE,P_USER_ID,OUT P_ERROR_CODE,OUT P_ERROR_MSG ;
		EXCEPTION
			WHEN OTHERS THEN
				v_error_code := -5;
				v_error_msg :=  SUBSTR('exec immediate UPDATE approved sts  '||v_sql,1,200);
				RAISE v_err;
		END;
	
		END LOOP;
	
	IF v_error_code < 0 THEN
	    v_error_code := -6;
		v_error_msg := 'SP MKBD GEN '||v_error_msg;
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
	      ROLLBACK;
	   p_error_code := -1;
	   p_error_msg := SUBSTR(SQLERRM,1,200);
       RAISE;
END SP_MKBD_GEN;