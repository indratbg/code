create or replace 
PROCEDURE           "SP_T_TEMP_INSERT_REK_DANA" (
	   p_table_name 		   T_TEMP_HEADER.TABLE_NAME%TYPE,
	   p_table_rowid			T_TEMP_HEADER.TABLE_ROWID%TYPE,
	   p_status						  T_TEMP_HEADER.status%TYPE,
	   p_user_id             		T_TEMP_HEADER.user_id%TYPE,
	   p_ip_address            T_TEMP_HEADER.ip_address%TYPE,
	   p_cancel_reason	   T_TEMP_HEADER.cancel_reason%TYPE,   
	   p_temp_detail		IN OUT	 Types.TEMP_DETAIL_rc,
	   p_error_code			OUT NUMBER,
	   p_error_msg			OUT VARCHAR2
	   ) IS

v_err EXCEPTION;
v_error_code							NUMBER;
v_error_msg							VARCHAR2(200);
v_update_seq NUMBER;
v_update_Date DATE := SYSDATE;
v_cnt 		  	   	  		  					  NUMBER;

v_rec T_TEMP_DETAIL%ROWTYPE;
BEGIN
   v_update_seq := 0;

   BEGIN
   SELECT t_temp_Seq.NEXTVAL INTO v_update_seq  FROM dual;
   EXCEPTION
   WHEN OTHERS THEN
   			    v_error_code := -1;
				v_error_msg := SUBSTR('Temp_seq.nextval '||SQLERRM,1,200);
				RAISE v_err;
   END;

 BEGIN
   INSERT INTO IPNEXTG.T_TEMP_HEADER (
   UPDATE_DATE, TABLE_NAME, UPDATE_SEQ,
   TABLE_ROWID, STATUS, USER_ID,
   IP_ADDRESS, APPROVED_STATUS, APPROVED_USER_ID,
   APPROVED_DATE, APPROVED_IP_ADDRESS, REJECT_REASON,
   CANCEL_REASON)
VALUES ( v_update_Date, p_table_name , v_update_seq,
   p_table_rowid, p_status, p_user_id,
    p_ip_address , 'A',NULL ,
	NULL,NULL,NULL,
	p_cancel_reason );
	EXCEPTION
   WHEN OTHERS THEN
   			v_error_code := -2;
			v_error_msg := SUBSTR('Insert to T_TEMP_HEADER '||SQLERRM,1,200);
			RAISE v_err;
   END;

	LOOP
	FETCH p_temp_detail INTO v_rec;
	EXIT WHEN p_temp_detail%NOTFOUND;

		 	  BEGIN
			INSERT INTO IPNEXTG.T_TEMP_DETAIL (
		   UPDATE_DATE, TABLE_NAME, UPDATE_SEQ,
		   FIELD_NAME, FIELD_TYPE, FIELD_VALUE,
		   COLUMN_ID, UPD_FLG)
		VALUES (v_update_Date , p_table_name, v_update_seq,
		   v_rec.field_name,  v_rec.field_type , v_rec.field_value,
		   v_rec.column_id, v_rec.upd_flg );
		   EXCEPTION
   WHEN OTHERS THEN
   			v_error_code := -3;
			v_error_msg := SUBSTR('Insert to T_TEMP_DETAIL '||SQLERRM,1,200);
			RAISE v_err;
   END;

	END LOOP;
   
   BEGIN
   SELECT COUNT(1) INTO v_cnt
   FROM T_TEMP_DETAIL
   WHERE UPDATE_DATE = v_UPDATE_DATE
   AND TABLE_NAME = p_table_name
   AND   UPDATE_SEQ = v_UPDATE_SEQ
   AND upd_flg = 'Y'
   AND field_name <> 'UPD_BY'
   AND field_name <> 'UPD_DT'
   AND field_name <> 'CRE_DT';
	   EXCEPTION
   WHEN OTHERS THEN
   			v_error_code := -4;
			v_error_msg := SUBSTR('Insert to T_TEMP_DETAIL '||SQLERRM,1,200);
			RAISE v_err;
   END;
   
   IF v_cnt = 0 AND p_status <> 'C' THEN
   	  v_error_code := -99;
			v_error_msg  := 'Data tidak berubah';
			RAISE V_err;
   END IF;			
   
   p_error_code := 1;
	 p_error_msg := '';

   EXCEPTION
     WHEN NO_DATA_FOUND THEN
       NULL;
	 WHEN v_err THEN
       p_error_code := v_error_code;
		   p_error_msg :=  v_error_msg;
       IF v_error_code <> -99 THEN
         ROLLBACK;
       END IF;
   WHEN OTHERS THEN
     p_error_code := -1;
     p_error_msg := SUBSTR(SQLERRM,1,200);
     ROLLBACK;
     RAISE;
END SP_T_TEMP_INSERT_REK_DANA;