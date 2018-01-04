create or replace 
PROCEDURE           "SP_T_VD55_UPD" (
		P_SEARCH_MKBD_DATE			T_VD55.MKBD_DATE%TYPE,
		P_SEARCH_MKBD_CD			T_VD55.MKBD_CD%TYPE,
		P_MKBD_DATE		T_VD55.MKBD_DATE%TYPE,
		P_MKBD_CD		T_VD55.MKBD_CD%TYPE,
		P_LINE_DESC		T_VD55.LINE_DESC%TYPE,
		P_TANGGAL		T_VD55.TANGGAL%TYPE,
		P_QTY1		T_VD55.QTY1%TYPE,
		P_QTY2		T_VD55.QTY2%TYPE,
		P_CRE_DT		T_VD55.CRE_DT%TYPE,
		P_USER_ID		T_VD55.USER_ID%TYPE,
		P_UPD_DT		T_VD55.UPD_DT%TYPE,
		P_UPD_BY		T_VD55.UPD_BY%TYPE,
		P_UPD_STATUS			T_TEMP_HEADER.STATUS%TYPE,
	   P_IP_ADDRESS					T_TEMP_HEADER.IP_ADDRESS%TYPE,
	   P_CANCEL_REASON				T_TEMP_HEADER.CANCEL_REASON%TYPE,
	   P_ERROR_CODE					OUT			NUMBER,
	   P_ERROR_MSG					OUT			VARCHAR2
) IS

  v_err EXCEPTION;
v_error_code							NUMBER;
v_error_msg							VARCHAR2(1000);
v_table_name T_TEMP_HEADER.table_name%TYPE := 'T_VD55';
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
FROM T_VD55
WHERE MKBD_DATE = p_search_MKBD_DATE
	AND MKBD_CD = p_search_MKBD_CD;

  v_temp_detail  Types.temp_detail_rc;

v_rec T_VD55%ROWTYPE;

v_cnt INTEGER;
 i INTEGER;
 V_FIELD_CNT NUMBER;
 v_pending_cnt NUMBER;
 va CHAR(1) := '@';
BEGIN

			IF 	  P_UPD_STATUS = 'I' AND (p_search_MKBD_DATE <> P_MKBD_DATE
									 OR p_search_MKBD_CD <> P_MKBD_CD) THEN
			       v_error_code := -2001;
				   IF p_search_MKBD_DATE <> P_MKBD_DATE THEN
						v_error_msg := 'jika INSERT, p_search_MKBD_DATE harus sama dengan P_MKBD_DATE';
				   END IF;
				   IF p_search_MKBD_CD <> P_MKBD_CD THEN
						v_error_msg := 'jika INSERT, p_search_MKBD_CD harus sama dengan P_MKBD_CD';
				   END IF;
				   RAISE v_err;
			END IF;
			
             BEGIN
   	 		 SELECT ROWID INTO v_table_rowid
			 FROM T_VD55
			 WHERE MKBD_DATE = p_search_MKBD_DATE
				AND MKBD_CD = p_search_MKBD_CD;
			 EXCEPTION
			 WHEN NO_DATA_FOUND THEN
			 	  v_table_rowid := NULL;
			WHEN OTHERS THEN
				     v_error_code := -2;
					 v_error_msg :=  SUBSTR('Retrieve  '|| v_table_name||' for '||p_search_MKBD_DATE||SQLERRM,1,200);
					 RAISE v_err;
				  END;

			IF 	  P_UPD_STATUS = 'I' AND v_table_rowid IS NOT NULL THEN
			       v_error_code := -2001;
				   v_error_msg  := 'DUPLICATED VD55 PK';
				   RAISE v_err;
			END IF;
			
			IF 	  P_UPD_STATUS = 'U' AND (p_search_MKBD_DATE <> P_MKBD_DATE
									 OR p_search_MKBD_CD <> P_MKBD_CD) THEN
				 BEGIN
	   	 		 SELECT COUNT(1) INTO v_cnt
				 FROM T_VD55
				 WHERE MKBD_DATE = p_MKBD_DATE
					 AND MKBD_CD = p_MKBD_CD;
				 EXCEPTION
				 WHEN NO_DATA_FOUND THEN
				 	  v_cnt := 0;
				WHEN OTHERS THEN
					     v_error_code := -3;
						 v_error_msg :=  SUBSTR('Retrieve  '|| v_table_name||' for '||p_search_MKBD_DATE||SQLERRM,1,200);
						 RAISE v_err;
				  END; 
				  
				  IF v_cnt  > 0 THEN
					       v_error_code := -2003;
						   v_error_msg  := 'DUPLICATED VD55 PK';
						   RAISE v_err;
				   END IF;
			END IF;
			
			IF v_table_rowid IS NULL THEN
					 BEGIN
					 SELECT COUNT(1) INTO v_pending_cnt
					 FROM (SELECT MAX(MKBD_DATE) MKBD_DATE, MAX(MKBD_CD) MKBD_CD
							FROM (SELECT DECODE (field_name, 'MKBD_DATE', field_value, NULL) MKBD_DATE,
										 DECODE (field_name, 'MKBD_CD', field_value, NULL) MKBD_CD
								 FROM T_TEMP_DETAIL D, T_TEMP_HEADER H
								 WHERE h.table_name = v_table_name
								 AND d.update_date = h.update_date
								 AND d.update_seq = h.update_seq
								 AND d.table_name = h.table_name
								 AND (d.field_name = 'MKBD_DATE' OR d.field_name = 'MKBD_CD') 
								 AND h.APPROVED_status = 'E'))
					 WHERE MKBD_DATE = p_search_MKBD_DATE
						 AND MKBD_CD = p_search_MKBD_CD;
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
		( SELECT  'MKBD_DATE'  AS field_name, TO_CHAR(p_MKBD_DATE,'yyyy/mm/dd hh24:mi:ss')  AS field_value, DECODE(v_rec.MKBD_DATE, p_MKBD_DATE,'N','Y') upd_flg FROM dual
			UNION
			SELECT  'MKBD_CD'  AS field_name, p_MKBD_CD AS field_value, DECODE(trim(v_rec.MKBD_CD), trim(p_MKBD_CD),'N','Y') upd_flg FROM dual
			UNION
			SELECT  'LINE_DESC'  AS field_name, p_LINE_DESC AS field_value, DECODE(trim(v_rec.LINE_DESC), trim(p_LINE_DESC),'N','Y') upd_flg FROM dual
			UNION
			SELECT  'TANGGAL'  AS field_name, TO_CHAR(p_TANGGAL,'yyyy/mm/dd hh24:mi:ss')  AS field_value, DECODE(v_rec.TANGGAL, p_TANGGAL,'N','Y') upd_flg FROM dual
			UNION
			SELECT  'QTY1'  AS field_name, TO_CHAR(p_QTY1)  AS field_value, DECODE(v_rec.QTY1, p_QTY1,'N','Y') upd_flg FROM dual
			UNION
			SELECT  'QTY2'  AS field_name, TO_CHAR(p_QTY2)  AS field_value, DECODE(v_rec.QTY2, p_QTY2,'N','Y') upd_flg FROM dual
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

END Sp_T_VD55_Upd;