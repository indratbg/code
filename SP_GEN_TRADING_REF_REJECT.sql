create or replace 
PROCEDURE "SP_GEN_TRADING_REF_REJECT" (
	  p_menu_name							T_MANY_HEADER.menu_name%TYPE,
	   p_update_date						T_MANY_HEADER.update_date%TYPE,
	   p_update_seq							T_MANY_HEADER.update_seq%TYPE,
	   p_reject_user_id				  	T_MANY_HEADER.user_id%TYPE,
	   p_reject_ip_address 		 		T_MANY_HEADER.ip_address%TYPE,
	   p_reject_reason						T_MANY_HEADER.reject_reason%TYPE,
	   p_error_code							OUT NUMBER,
	   p_error_msg							OUT VARCHAR2
	   ) IS

/******************************************************************************
   NAME:       SP_GEN_TRADING_REF_REJECT
   PURPOSE:

	Deleting records in T_TC_DOC which have temporary values from SP_GEN_TRADING_REF_UPD
	--AS--


   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        12/06/2014          1. Created this procedure.

   NOTES:
******************************************************************************/

CURSOR CSR_TC IS
SELECT record_seq, upd_status,
(SELECT TO_DATE(field_value,'yyyy/mm/dd hh24:mi:ss') FROM T_MANY_DETAIL da 
        WHERE da.update_date = dd.update_date 
        AND da.update_seq = dd.update_seq
        AND da.table_name = 'T_TC_DOC'
        AND da.field_name = 'TC_DATE'
        AND da.record_seq = dd.record_seq) tc_date, 
(SELECT field_value FROM T_MANY_DETAIL da 
        WHERE da.update_date = dd.update_date 
        AND da.update_seq = dd.update_seq
        AND da.table_name = 'T_TC_DOC'
        AND da.field_name = 'TC_ID'
        AND da.record_seq = dd.record_seq) tc_id,
(SELECT field_value FROM T_MANY_DETAIL da 
        WHERE da.update_date = dd.update_date 
        AND da.update_seq = dd.update_seq
        AND da.table_name = 'T_TC_DOC'
        AND da.field_name = 'CLIENT_CD'
        AND da.record_seq = dd.record_seq) CLIENT_CD		
FROM T_MANY_DETAIL dd WHERE dd.update_date = p_update_date AND dd.update_seq = p_update_seq 
	AND dd.table_name = 'T_TC_DOC' AND  dd.field_name IN ('TC_DATE') ORDER BY dd.record_seq;

 v_err 					EXCEPTION;
v_error_code			NUMBER;
v_error_msg				VARCHAR2(1000);
BEGIN

	FOR REC IN CSR_TC LOOP
		BEGIN
			DELETE FROM T_TC_DOC
			WHERE
			TC_ID = rec.tc_id AND
			TC_DATE = rec.tc_date AND
			CLIENT_CD = rec.client_cd AND
			TC_REV = -1 AND
			TC_STATUS = -1;
		EXCEPTION
			WHEN OTHERS THEN
				v_error_code := -2;
				v_error_msg :=  SUBSTR('UPDATE T_TC_DOC '||SQLERRM,1,200);
				RAISE v_err;
		END;
		
	END LOOP;
  
  BEGIN
		  Sp_T_Many_Reject(p_menu_name,
			   p_update_date,
			   p_update_seq,
			   p_reject_user_id,
			   p_reject_ip_address,
			   p_reject_reason,
			   v_error_code,
			   v_error_msg);
	   EXCEPTION
		WHEN OTHERS THEN
				v_error_code := -3;
				v_error_msg :=  SUBSTR('Sp_T_Many_Reject '||p_menu_name||SQLERRM,1,200);
				RAISE v_err;
	   END;

		IF v_error_code < 0 THEN
					RAISE v_err;
	   END IF;

	p_error_code := 1;
	p_error_msg := '';

EXCEPTION
    WHEN NO_DATA_FOUND THEN
	   p_error_code := -1;
	   p_error_msg := SUBSTR(SQLERRM,1,200);
	   RAISE;
	 WHEN v_err THEN
		   p_error_code := v_error_code;
		   p_error_msg :=  v_error_msg;
		  ROLLBACK;
	 WHEN OTHERS THEN
	   ROLLBACK;
	   p_error_code := -1;
	   p_error_msg := SUBSTR(SQLERRM,1,200);
	   RAISE;
END SP_GEN_TRADING_REF_REJECT;