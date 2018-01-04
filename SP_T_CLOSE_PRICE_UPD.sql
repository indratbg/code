create or replace 
PROCEDURE           "SP_T_CLOSE_PRICE_UPD" (
		P_SEARCH_STK_DATE		T_CLOSE_PRICE.STK_DATE%TYPE,
		P_SEARCH_STK_CD		T_CLOSE_PRICE.STK_CD%TYPE,
		P_STK_DATE		T_CLOSE_PRICE.STK_DATE%TYPE,
		P_STK_CD		T_CLOSE_PRICE.STK_CD%TYPE,
		P_STK_NAME		T_CLOSE_PRICE.STK_NAME%TYPE,
		P_STK_PREV		T_CLOSE_PRICE.STK_PREV%TYPE,
		P_STK_HIGH		T_CLOSE_PRICE.STK_HIGH%TYPE,
		P_STK_LOW		T_CLOSE_PRICE.STK_LOW%TYPE,
		P_STK_CLOS		T_CLOSE_PRICE.STK_CLOS%TYPE,
		P_STK_VOLM		T_CLOSE_PRICE.STK_VOLM%TYPE,
		P_STK_AMT		T_CLOSE_PRICE.STK_AMT%TYPE,
		P_STK_INDX		T_CLOSE_PRICE.STK_INDX%TYPE,
		P_STK_PIDX		T_CLOSE_PRICE.STK_PIDX%TYPE,
		P_STK_ASKP		T_CLOSE_PRICE.STK_ASKP%TYPE,
		P_STK_ASKV		T_CLOSE_PRICE.STK_ASKV%TYPE,
		P_STK_ASKF		T_CLOSE_PRICE.STK_ASKF%TYPE,
		P_STK_BIDP		T_CLOSE_PRICE.STK_BIDP%TYPE,
		P_STK_BIDV		T_CLOSE_PRICE.STK_BIDV%TYPE,
		P_STK_BIDF		T_CLOSE_PRICE.STK_BIDF%TYPE,
		P_STK_OPEN		T_CLOSE_PRICE.STK_OPEN%TYPE,
		P_CRE_DT		T_CLOSE_PRICE.CRE_DT%TYPE,
		P_USER_ID		T_CLOSE_PRICE.USER_ID%TYPE,
		P_UPD_DT		T_CLOSE_PRICE.UPD_DT%TYPE,
		P_UPD_BY		T_CLOSE_PRICE.UPD_BY%TYPE,
		P_ISIN_CODE 	T_CLOSE_PRICE.ISIN_CODE%TYPE,--27APR2016
		P_UPD_STATUS			T_TEMP_HEADER.STATUS%TYPE,
	   P_IP_ADDRESS					T_TEMP_HEADER.IP_ADDRESS%TYPE,
	   P_CANCEL_REASON				T_TEMP_HEADER.CANCEL_REASON%TYPE,
	   P_ERROR_CODE					OUT			NUMBER,
	   P_ERROR_MSG					OUT			VARCHAR2
) IS

  v_err EXCEPTION;
v_error_code							NUMBER;
v_error_msg							VARCHAR2(1000);
v_table_name T_TEMP_HEADER.table_name%TYPE := 'T_CLOSE_PRICE';
v_status               T_TEMP_HEADER.status%TYPE;
v_table_rowid				   T_TEMP_HEADER.table_rowid%TYPE;

CURSOR csr_temp_detail IS
SELECT      column_id, column_name AS field_name,
                       DECODE(data_type,'VARCHAR2','S','CHAR','S','NUMBER','N','DATE','D','X') AS field_type
FROM all_tab_columns
WHERE table_name =v_table_name
AND OWNER = 'IPNEXTG';

CURSOR csr_table IS
SELECT *
FROM T_CLOSE_PRICE
WHERE STK_DATE = p_search_STK_DATE
	AND STK_CD = p_search_STK_CD;

  v_temp_detail  Types.temp_detail_rc;

v_rec T_CLOSE_PRICE%ROWTYPE;

v_cnt INTEGER;
 i INTEGER;
 V_FIELD_CNT NUMBER;
 v_pending_cnt NUMBER;
 va CHAR(1) := '@';
BEGIN

			IF 	  P_UPD_STATUS = 'I' AND (p_search_STK_DATE <> P_STK_DATE
									 OR p_search_STK_CD <> P_STK_CD) THEN
			       v_error_code := -2001;
				   IF p_search_STK_DATE <> P_STK_DATE THEN
						v_error_msg := 'jika INSERT, p_search_STK_DATE harus sama dengan P_STK_DATE';
				   END IF;
				   IF p_search_STK_CD <> P_STK_CD THEN
						v_error_msg := 'jika INSERT, p_search_STK_CD harus sama dengan P_STK_CD';
				   END IF;
				   RAISE v_err;
			END IF;
			
             BEGIN
   	 		 SELECT ROWID INTO v_table_rowid
			 FROM T_CLOSE_PRICE
			 WHERE STK_DATE = p_search_STK_DATE
				AND STK_CD = p_search_STK_CD;
			 EXCEPTION
			 WHEN NO_DATA_FOUND THEN
			 	  v_table_rowid := NULL;
			WHEN OTHERS THEN
				     v_error_code := -2;
					 v_error_msg :=  SUBSTR('Retrieve  '|| v_table_name||' for '||p_search_STK_DATE||SQLERRM,1,200);
					 RAISE v_err;
				  END;

			IF 	  P_UPD_STATUS = 'I' AND v_table_rowid IS NOT NULL THEN
			       v_error_code := -2001;
				   v_error_msg  := 'DUPLICATED T_Close_Price PK';
				   RAISE v_err;
			END IF;
			
			IF 	  P_UPD_STATUS = 'U' AND (p_search_STK_DATE <> P_STK_DATE
									 OR p_search_STK_CD <> P_STK_CD) THEN
				 BEGIN
	   	 		 SELECT COUNT(1) INTO v_cnt
				 FROM T_CLOSE_PRICE
				 WHERE STK_DATE = p_STK_DATE
					 AND STK_CD = p_STK_CD;
				 EXCEPTION
				 WHEN NO_DATA_FOUND THEN
				 	  v_cnt := 0;
				WHEN OTHERS THEN
					     v_error_code := -3;
						 v_error_msg :=  SUBSTR('Retrieve  '|| v_table_name||' for '||p_search_STK_DATE||SQLERRM,1,200);
						 RAISE v_err;
				  END; 
				  
				  IF v_cnt  > 0 THEN
					       v_error_code := -2003;
						   v_error_msg  := 'DUPLICATED T_Close_Price PK';
						   RAISE v_err;
				   END IF;
			END IF;
			
			IF v_table_rowid IS NULL THEN
					 BEGIN
					 SELECT COUNT(1) INTO v_pending_cnt
					 FROM (SELECT MAX(STK_DATE) STK_DATE, MAX(STK_CD) STK_CD
							FROM (SELECT DECODE (field_name, 'STK_DATE', field_value, NULL) STK_DATE,
										 DECODE (field_name, 'STK_CD', field_value, NULL) STK_CD
								 FROM T_TEMP_DETAIL D, T_TEMP_HEADER H
								 WHERE h.table_name = v_table_name
								 AND d.update_date = h.update_date
								 AND d.update_seq = h.update_seq
								 AND d.table_name = h.table_name
								 AND (d.field_name = 'STK_DATE' OR d.field_name = 'STK_CD') 
								 AND h.APPROVED_status = 'E'))
					 WHERE STK_DATE = p_search_STK_DATE
						 AND STK_CD = p_search_STK_CD;
					 EXCEPTION
					 WHEN NO_DATA_FOUND THEN
					         v_pending_cnt := 0;
					WHEN OTHERS THEN
							 v_error_code := -4;
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
							 v_error_code := -5;
							 v_error_msg :=  SUBSTR('Retrieve T_TEMP_HEADER for '|| v_table_name||SQLERRM,1,200);
							 RAISE v_err;
					END;
			END IF;
      
			IF  v_pending_cnt > 0 THEN
				v_error_code := -6;
				v_error_msg := 'Masih ada yang belum di-approve';
				RAISE v_err;
			END IF;

			OPEN csr_Table;
			FETCH csr_Table INTO v_rec;


		OPEN v_Temp_detail FOR
		SELECT update_date, table_name,  0 update_seq,  a.field_name,  field_type, b.field_value, a.column_id, b.upd_flg
		FROM(
		 SELECT  SYSDATE AS  update_date, v_table_name AS table_name, column_id, column_name AS field_name,
		                       					DECODE(data_type,'VARCHAR2','S','CHAR','S','NUMBER','N','DATE','D','X') AS field_type
										FROM all_tab_columns
										WHERE table_name = v_table_name
										AND OWNER = 'IPNEXTG') a,
		(SELECT  'STK_DATE'  AS field_name, TO_CHAR(p_STK_DATE,'yyyy/mm/dd hh24:mi:ss')  AS field_value, DECODE(v_rec.STK_DATE, p_STK_DATE,'N','Y') upd_flg FROM dual
			UNION
			SELECT  'STK_CD'  AS field_name, p_STK_CD AS field_value, DECODE(trim(v_rec.STK_CD), trim(p_STK_CD),'N','Y') upd_flg FROM dual
			UNION
			SELECT  'STK_NAME'  AS field_name, p_STK_NAME AS field_value, DECODE(trim(v_rec.STK_NAME), trim(p_STK_NAME),'N','Y') upd_flg FROM dual
			UNION
			SELECT  'STK_PREV'  AS field_name, TO_CHAR(p_STK_PREV)  AS field_value, DECODE(v_rec.STK_PREV, p_STK_PREV,'N','Y') upd_flg FROM dual
			UNION
			SELECT  'STK_HIGH'  AS field_name, TO_CHAR(p_STK_HIGH)  AS field_value, DECODE(v_rec.STK_HIGH, p_STK_HIGH,'N','Y') upd_flg FROM dual
			UNION
			SELECT  'STK_LOW'  AS field_name, TO_CHAR(p_STK_LOW)  AS field_value, DECODE(v_rec.STK_LOW, p_STK_LOW,'N','Y') upd_flg FROM dual
			UNION
			SELECT  'STK_CLOS'  AS field_name, TO_CHAR(p_STK_CLOS)  AS field_value, DECODE(v_rec.STK_CLOS, p_STK_CLOS,'N','Y') upd_flg FROM dual
			UNION
			SELECT  'STK_VOLM'  AS field_name, TO_CHAR(p_STK_VOLM)  AS field_value, DECODE(v_rec.STK_VOLM, p_STK_VOLM,'N','Y') upd_flg FROM dual
			UNION
			SELECT  'STK_AMT'  AS field_name, TO_CHAR(p_STK_AMT)  AS field_value, DECODE(v_rec.STK_AMT, p_STK_AMT,'N','Y') upd_flg FROM dual
			UNION
			SELECT  'STK_INDX'  AS field_name, TO_CHAR(p_STK_INDX)  AS field_value, DECODE(v_rec.STK_INDX, p_STK_INDX,'N','Y') upd_flg FROM dual
			UNION
			SELECT  'STK_PIDX'  AS field_name, TO_CHAR(p_STK_PIDX)  AS field_value, DECODE(v_rec.STK_PIDX, p_STK_PIDX,'N','Y') upd_flg FROM dual
			UNION
			SELECT  'STK_ASKP'  AS field_name, TO_CHAR(p_STK_ASKP)  AS field_value, DECODE(v_rec.STK_ASKP, p_STK_ASKP,'N','Y') upd_flg FROM dual
			UNION
			SELECT  'STK_ASKV'  AS field_name, TO_CHAR(p_STK_ASKV)  AS field_value, DECODE(v_rec.STK_ASKV, p_STK_ASKV,'N','Y') upd_flg FROM dual
			UNION
			SELECT  'STK_ASKF'  AS field_name, p_STK_ASKF AS field_value, DECODE(trim(v_rec.STK_ASKF), trim(p_STK_ASKF),'N','Y') upd_flg FROM dual
			UNION
			SELECT  'STK_BIDP'  AS field_name, TO_CHAR(p_STK_BIDP)  AS field_value, DECODE(v_rec.STK_BIDP, p_STK_BIDP,'N','Y') upd_flg FROM dual
			UNION
			SELECT  'STK_BIDV'  AS field_name, TO_CHAR(p_STK_BIDV)  AS field_value, DECODE(v_rec.STK_BIDV, p_STK_BIDV,'N','Y') upd_flg FROM dual
			UNION
			SELECT  'STK_BIDF'  AS field_name, p_STK_BIDF AS field_value, DECODE(trim(v_rec.STK_BIDF), trim(p_STK_BIDF),'N','Y') upd_flg FROM dual
			UNION
			SELECT  'STK_OPEN'  AS field_name, TO_CHAR(p_STK_OPEN)  AS field_value, DECODE(v_rec.STK_OPEN, p_STK_OPEN,'N','Y') upd_flg FROM dual
			UNION
			SELECT  'USER_ID'  AS field_name, p_USER_ID AS field_value, 'Y' upd_flg FROM dual
			WHERE P_UPD_STATUS = 'I'
			UNION
			SELECT  'CRE_DT'  AS field_name, TO_CHAR(SYSDATE,'yyyy/mm/dd hh24:mi:ss')  AS field_value, 'Y' upd_flg FROM dual
            WHERE P_UPD_STATUS = 'I'
			UNION
			SELECT  'UPD_DT'  AS field_name, TO_CHAR(SYSDATE,'yyyy/mm/dd hh24:mi:ss')  AS field_value, 'Y' upd_flg FROM dual
            WHERE P_UPD_STATUS = 'U'
			UNION
			SELECT  'UPD_BY'  AS field_name, p_USER_ID AS field_value, 'Y' upd_flg FROM dual
            WHERE P_UPD_STATUS = 'U'
			UNION
			SELECT  'ISIN_CODE'  AS field_name, TO_CHAR(P_ISIN_CODE)  AS field_value, DECODE(v_rec.ISIN_CODE, P_ISIN_CODE,'N','Y') upd_flg FROM dual--27APR2016
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
    Sp_T_Temp_Insert(v_table_name,   v_table_rowid,   v_status,p_user_id, p_ip_address , p_cancel_reason, v_temp_detail, v_error_code, v_error_msg);
EXCEPTION
WHEN OTHERS THEN
		 v_error_code := -7;
		  v_error_msg := SUBSTR('SP_T_TEMP_INSERT '||v_table_name||SQLERRM,1,200);
		  RAISE v_err;
END;

	CLOSE v_Temp_detail;
	CLOSE csr_Table;

	IF v_error_code < 0 THEN
	      v_error_code := -8;
		  v_error_msg := 'SP_T_TEMP_INSERT '||v_table_name||' '||v_error_msg;
		  RAISE v_err;
	  END IF;


	    p_error_code := 1;
	   p_error_msg := '';

   EXCEPTION
     WHEN NO_DATA_FOUND THEN
    p_error_code := -1;
	   p_error_msg := SUBSTR(SQLERRM,1,200);
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

END Sp_T_CLOSE_PRICE_Upd;