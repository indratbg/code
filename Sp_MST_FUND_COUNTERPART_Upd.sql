create or replace PROCEDURE "SP_MST_FUND_COUNTERPART_UPD" (
		P_SEARCH_FUND_CODE		MST_FUND_COUNTERPART.FUND_CODE%TYPE,
		P_FUND_CODE		MST_FUND_COUNTERPART.FUND_CODE%TYPE,
		P_FUND_NAME		MST_FUND_COUNTERPART.FUND_NAME%TYPE,
    P_IM_CODE		MST_FUND_COUNTERPART.IM_CODE%TYPE,
		P_COUNTERPART		MST_FUND_COUNTERPART.COUNTERPART%TYPE,
		P_FUND_TYPE		MST_FUND_COUNTERPART.FUND_TYPE%TYPE,
		P_PORTFOLIO_ID		MST_FUND_COUNTERPART.PORTFOLIO_ID%TYPE,
		P_SELLER_TAX_ID		MST_FUND_COUNTERPART.SELLER_TAX_ID%TYPE,
		P_CRE_BY		MST_FUND_COUNTERPART.CRE_BY%TYPE,
		P_CRE_DT		MST_FUND_COUNTERPART.CRE_DT%TYPE,
		P_UPD_BY		MST_FUND_COUNTERPART.UPD_BY%TYPE,
		P_UPD_DT		MST_FUND_COUNTERPART.UPD_DT%TYPE,
		P_UPD_STATUS					T_TEMP_HEADER.STATUS%TYPE,
	   p_ip_address								T_TEMP_HEADER.IP_ADDRESS%TYPE,
	   p_cancel_reason						T_TEMP_HEADER.CANCEL_REASON%TYPE,
	   p_error_code					OUT			NUMBER,
	   p_error_msg					OUT			VARCHAR2
) IS

  v_err EXCEPTION;
v_error_code							NUMBER;
v_error_msg							VARCHAR2(200);
v_table_name T_TEMP_HEADER.table_name%TYPE := 'MST_FUND_COUNTERPART';
v_status               T_TEMP_HEADER.status%TYPE;
v_table_rowid				   T_TEMP_HEADER.table_rowid%TYPE;

CURSOR csr_temp_detail IS
SELECT      column_id, column_name AS field_name,
                       DECODE(data_type,'VARCHAR2','S','CHAR','S','NUMBER','N','DATE','D','X') AS field_type
FROM all_tab_columns
WHERE table_name =v_table_name;
--AND OWNER = 'IPNEXTG';

CURSOR csr_table IS
SELECT *
FROM MST_FUND_COUNTERPART
WHERE FUND_CODE = P_SEARCH_FUND_CODE;

v_rec MST_FUND_COUNTERPART%ROWTYPE;

  v_temp_detail  Types.temp_detail_rc;



v_cnt INTEGER;
 i INTEGER;
 V_FIELD_CNT NUMBER;
 v_pending_cnt NUMBER;
 va CHAR(1) := '@';
BEGIN

		IF 	  P_UPD_STATUS = 'I' AND P_SEARCH_FUND_CODE <> P_FUND_CODE THEN
			       v_error_code := -2001;
				   v_error_msg  := 'jika INSERT, P_SEARCH_FUND_CODE harus sama dengan P_FUND_CODE';
				   RAISE v_err;
			END IF;
			
             BEGIN
   	 		 SELECT ROWID INTO v_table_rowid
			 FROM MST_FUND_COUNTERPART
			 WHERE FUND_CODE = P_SEARCH_FUND_CODE;
			 EXCEPTION
			 WHEN NO_DATA_FOUND THEN
			 	  v_table_rowid := NULL;
			WHEN OTHERS THEN
				     v_error_code := -2;
					 v_error_msg :=  SUBSTR('Retrieve  '|| v_table_name||' for '||P_SEARCH_FUND_CODE||SQLERRM,1,200);
					 RAISE v_err;
				  END;

			IF 	  P_UPD_STATUS = 'I' AND v_table_rowid IS NOT NULL THEN
			       v_error_code := -2002;
				   v_error_msg  := 'DUPLICATED FUND CODE';
				   RAISE v_err;
			END IF;
			
			IF 	  P_UPD_STATUS = 'U'   AND P_SEARCH_FUND_CODE  <> P_FUND_CODE THEN
				 BEGIN
	   	 		 SELECT COUNT(1) INTO v_cnt
				 FROM MST_FUND_COUNTERPART
				 WHERE FUND_CODE = P_FUND_CODE;
				 EXCEPTION
				 WHEN NO_DATA_FOUND THEN
				 	  v_cnt := 0;
				WHEN OTHERS THEN
					     v_error_code := -3;
						 v_error_msg :=  SUBSTR('Retrieve  '|| v_table_name||' for '||P_FUND_CODE||SQLERRM,1,200);
						 RAISE v_err;
				  END; 
				  
				  IF v_cnt  > 0 THEN
					       v_error_code := -2003;
						   v_error_msg  := 'DUPLICATED FUND CODE';
						   RAISE v_err;
				   END IF;
			END IF;
				  
						  
				  
			IF v_table_rowid IS NULL THEN
					 BEGIN
					 SELECT COUNT(1) INTO v_pending_cnt
					 FROM T_TEMP_DETAIL D, T_TEMP_HEADER H
					 WHERE h.table_name = v_table_name
					 AND d.update_date = h.update_date
					 AND d.update_seq =h.update_seq
					 AND  d.table_name = h.table_name
					 AND d.field_name = 'FUND_CODE'
					 AND   d.field_value = P_SEARCH_FUND_CODE
					 AND h.APPROVED_status = 'E';
					 EXCEPTION
					 WHEN NO_DATA_FOUND THEN
					         v_pending_cnt := 0;
					WHEN OTHERS THEN
							 v_error_code := -3;
							 v_error_msg :=  SUBSTR('Retrieve T_TEMP_HEADER for '|| v_table_name||SQLERRM,1,200);
							 RAISE v_err;
					END;
			ELSE
					BEGIN
					 SELECT COUNT(1) INTO v_pending_cnt
					 FROM T_TEMP_HEADER H
					 WHERE h.table_name = v_table_name
					  AND   h.table_rowid = v_table_rowid
					 AND h.APPROVED_status = 'E'; 
					 EXCEPTION
					 WHEN NO_DATA_FOUND THEN
					         v_pending_cnt := 0;
					WHEN OTHERS THEN
							 v_error_code := -4;
							 v_error_msg :=  SUBSTR('Retrieve T_TEMP_HEADER for '|| v_table_name||SQLERRM,1,200);
							 RAISE v_err;
					END;
			END IF;



			IF  v_pending_cnt > 0 THEN
				v_error_code := -5;
				v_error_msg := 'Masih ada yang belum di-approve';
				RAISE v_err;
			END IF;

		OPEN csr_Table;
		FETCH csr_Table INTO v_rec;


		OPEN v_Temp_detail FOR
		SELECT update_date, table_name,  0 update_seq,  a.field_name,  field_type, b.field_value, a.column_id, b.upd_flg
		FROM(
		 SELECT  SYSDATE AS  update_date, v_table_name AS table_name, column_id,    column_name AS field_name,
                              DECODE(data_type,'VARCHAR2','S','CHAR','S','NUMBER','N','DATE','D','X') AS field_type
              FROM all_tab_columns
              WHERE table_name =v_table_name

										) a,
		( 
			SELECT  'FUND_CODE'  AS field_name, p_FUND_CODE AS field_value, DECODE(trim(v_rec.FUND_CODE), trim(p_FUND_CODE),'N','Y') upd_flg FROM dual
			UNION
			SELECT  'FUND_NAME'  AS field_name, p_FUND_NAME AS field_value, DECODE(trim(v_rec.FUND_NAME), trim(p_FUND_NAME),'N','Y') upd_flg FROM dual
			UNION
			SELECT  'IM_CODE'  AS field_name, p_IM_CODE AS field_value, DECODE(trim(v_rec.IM_CODE), trim(p_IM_CODE),'N','Y') upd_flg FROM dual
			UNION
			SELECT  'COUNTERPART'  AS field_name, p_COUNTERPART AS field_value, DECODE(trim(v_rec.COUNTERPART), trim(p_COUNTERPART),'N','Y') upd_flg FROM dual
			UNION
			SELECT  'FUND_TYPE'  AS field_name, p_FUND_TYPE AS field_value, DECODE(trim(v_rec.FUND_TYPE), trim(p_FUND_TYPE),'N','Y') upd_flg FROM dual
			UNION
			SELECT  'PORTFOLIO_ID'  AS field_name, p_PORTFOLIO_ID AS field_value, DECODE(trim(v_rec.PORTFOLIO_ID), trim(p_PORTFOLIO_ID),'N','Y') upd_flg FROM dual
			UNION
			SELECT  'SELLER_TAX_ID'  AS field_name, p_SELLER_TAX_ID AS field_value, DECODE(trim(v_rec.SELLER_TAX_ID), trim(p_SELLER_TAX_ID),'N','Y') upd_flg FROM dual
			UNION
			SELECT  'CRE_BY'  AS field_name, p_CRE_BY AS field_value, DECODE(trim(v_rec.CRE_BY), trim(p_CRE_BY),'N','Y') upd_flg FROM dual
			WHERE P_UPD_STATUS='I'
			UNION
			SELECT  'CRE_DT'  AS field_name, TO_CHAR(p_CRE_DT,'yyyy/mm/dd hh24:mi:ss')  AS field_value, DECODE(v_rec.CRE_DT, p_CRE_DT,'N','Y') upd_flg FROM dual
			WHERE P_UPD_STATUS='I'
			UNION
			SELECT  'UPD_BY'  AS field_name, p_UPD_BY AS field_value, DECODE(trim(v_rec.UPD_BY), trim(p_UPD_BY),'N','Y') upd_flg FROM dual
			WHERE P_UPD_STATUS='U'
			UNION
			SELECT  'UPD_DT'  AS field_name, TO_CHAR(p_UPD_DT,'yyyy/mm/dd hh24:mi:ss')  AS field_value, DECODE(v_rec.UPD_DT, p_UPD_DT,'N','Y') upd_flg FROM dual
			WHERE P_UPD_STATUS='U'
		  ) b
		 WHERE a.field_name = b.field_name
				AND  P_UPD_STATUS <> 'C';

		 
IF v_table_rowid IS NOT NULL THEN
	    IF P_UPD_STATUS = 'C' THEN
		   				  v_status := 'C';
		   ELSE
	       	   			  v_status := 'U';
		   END IF;
	ELSE
		 v_status := 'I';
 END IF;

 BEGIN
    Sp_T_Temp_Insert(v_table_name,   v_table_rowid,   v_status,P_CRE_BY, p_ip_address , p_cancel_reason, v_temp_detail, v_error_code, v_error_msg);
EXCEPTION
WHEN OTHERS THEN
		 v_error_code := -6;
		  v_error_msg := SUBSTR('SP_T_TEMP_INSERT '||v_table_name||SQLERRM,1,200);
		  RAISE v_err;
END;

	CLOSE v_Temp_detail;
	CLOSE csr_Table;
	
	IF v_error_code < 0 THEN
	      v_error_code := -7;
		  v_error_msg := 'SP_T_TEMP_INSERT '||v_table_name||' '||v_error_msg;
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

END Sp_MST_FUND_COUNTERPART_Upd;