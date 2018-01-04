create or replace 
PROCEDURE Sp_T_REK_DANA_KSEI_Upd(
		P_SEARCH_REK_DANA	T_REK_DANA_KSEI.REK_DANA%TYPE,
		P_SEARCH_BANK_CD		T_REK_DANA_KSEI.BANK_CD%TYPE,
		P_SID		T_REK_DANA_KSEI.SID%TYPE,
		P_SUBREK		T_REK_DANA_KSEI.SUBREK%TYPE,
		P_NAME		T_REK_DANA_KSEI.NAME%TYPE,
		P_REK_DANA		T_REK_DANA_KSEI.REK_DANA%TYPE,
		P_BANK_CD		T_REK_DANA_KSEI.BANK_CD%TYPE,
		P_CREATE_DT		T_REK_DANA_KSEI.CREATE_DT%TYPE,
		P_CRE_DT		T_REK_DANA_KSEI.CRE_DT%TYPE,
		P_UPD_DT		T_REK_DANA_KSEI.UPD_DT%TYPE,
		P_USER_ID		T_REK_DANA_KSEI.USER_ID%TYPE,
		P_UPD_BY		T_REK_DANA_KSEI.UPD_BY%TYPE,
		P_UPD_STATUS		T_TEMP_HEADER.STATUS%TYPE,
		p_ip_address		T_TEMP_HEADER.IP_ADDRESS%TYPE,
		p_cancel_reason		T_TEMP_HEADER.CANCEL_REASON%TYPE,
		p_error_code		OUT			NUMBER,
		p_error_msg		OUT			VARCHAR2
) IS



	v_err EXCEPTION;
	v_error_code				NUMBER;
	v_error_msg					VARCHAR2(1000);
	v_table_name 				T_TEMP_HEADER.table_name%TYPE := 'T_REK_DANA_KSEI';
	v_status        		    T_TEMP_HEADER.status%TYPE;
	v_table_rowid	   			T_TEMP_HEADER.table_rowid%TYPE;

CURSOR csr_temp_detail IS
SELECT      column_id, column_name AS field_name,
                       DECODE(data_type,'VARCHAR2','S','CHAR','S','NUMBER','N','DATE','D','X') AS field_type
FROM all_tab_columns
WHERE table_name =v_table_name
AND OWNER = 'IPNEXTG';

CURSOR csr_table IS
SELECT *
FROM T_REK_DANA_KSEI
WHERE REK_DANA = p_search_REK_DANA
	AND BANK_CD = p_search_BANK_CD;

v_temp_detail  Types.temp_detail_rc;

v_rec T_REK_DANA_KSEI%ROWTYPE;




v_cnt INTEGER;
 i INTEGER;
 V_FIELD_CNT NUMBER;
 v_pending_cnt NUMBER;
 va CHAR(1) := '@';
BEGIN

			IF 	  P_UPD_STATUS = 'I' AND (P_SEARCH_REK_DANA <> P_REK_DANA
								OR P_SEARCH_BANK_CD <> P_BANK_CD) THEN
			       v_error_code := -2001;
					IF P_SEARCH_REK_DANA <> P_REK_DANA THEN
				   		v_error_msg := 'jika INSERT, P_SEARCH_REK_DANA harus sama dengan P_REK_DANA';
					END IF;
					IF P_SEARCH_BANK_CD<> P_BANK_CD THEN
				   		v_error_msg := 'jika INSERT, P_SEARCH_BANK_CDharus sama dengan P_BANK_CD';
					END IF;

				   RAISE v_err;
			END IF;
			
             BEGIN
   	 		 SELECT ROWID INTO v_table_rowid
			 FROM T_REK_DANA_KSEI
			 WHERE REK_DANA = P_SEARCH_REK_DANA
				AND BANK_CD = P_SEARCH_BANK_CD;
			 EXCEPTION
			 WHEN NO_DATA_FOUND THEN
			 	  v_table_rowid := NULL;
			WHEN OTHERS THEN
				     v_error_code := -2;
					 v_error_msg :=  SUBSTR('Retrieve  '|| v_table_name||' for '||P_SEARCH_REK_DANA||SQLERRM,1,200);
					 RAISE v_err;
				  END;

			IF 	  P_UPD_STATUS = 'I' AND v_table_rowid IS NOT NULL THEN
			       v_error_code := -2001;
				   v_error_msg  := 'DUPLICATED REKENENING DANA AND BANK CD';
				   RAISE v_err;
			END IF;
			
			IF 	  P_UPD_STATUS = 'U' AND (P_SEARCH_REK_DANA <> P_REK_DANA
								OR P_SEARCH_BANK_CD<> P_BANK_CD) THEN
				 BEGIN
	   	 		 SELECT COUNT(1) INTO v_cnt
				 FROM T_REK_DANA_KSEI
				 WHERE REK_DANA = P_REK_DANA
					AND BANK_CD = P_BANK_CD;
				 EXCEPTION
				 WHEN NO_DATA_FOUND THEN
				 	  v_cnt := 0;
				WHEN OTHERS THEN
					     v_error_code := -3;
						 v_error_msg :=  SUBSTR('Retrieve  '|| v_table_name||' for '||P_SEARCH_BANK_CD||SQLERRM,1,200);
						 RAISE v_err;
				  END; 
				  
				  IF v_cnt  > 0 THEN
					       v_error_code := -2003;
						   v_error_msg  := 'DUPLICATED REKENENING DANA AND BANK CD';
						   RAISE v_err;
				   END IF;
			END IF;
			
				  
				  
			IF v_table_rowid IS NULL THEN
					 BEGIN
					 SELECT COUNT(1) INTO v_pending_cnt
					 FROM (SELECT MAX(REK_DANA) REK_DANA, MAX(BANK_CD) BANK_CD
							FROM (SELECT DECODE (field_name, 'REK_DANA', field_value, NULL) REK_DANA,
								DECODE	(field_name, 'BANK_CD', field_value, NULL) BANK_CD
								 FROM T_TEMP_DETAIL D, T_TEMP_HEADER H
								 WHERE h.table_name = v_table_name
								 AND d.update_date = h.update_date
								 AND d.update_seq = h.update_seq
								 AND d.table_name = h.table_name
								 AND (d.field_name = 'REK_DANA' OR d.field_name = 'BANK_CD') 
								 AND h.APPROVED_status = 'E'))
					 WHERE REK_DANA = P_SEARCH_REK_DANA
						AND BANK_CD = P_SEARCH_BANK_CD;
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
					 AND h.APPROVED_status <> 'A'
           			 AND h.APPROVED_status <>'R';
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
		(SELECT  'SID'  AS field_name, p_SID AS field_value, DECODE(trim(v_rec.SID), trim(p_SID),'N','Y') upd_flg FROM dual
		UNION
		SELECT  'SUBREK'  AS field_name, p_SUBREK AS field_value, DECODE(trim(v_rec.SUBREK), trim(p_SUBREK),'N','Y') upd_flg FROM dual
		UNION
		SELECT  'NAME'  AS field_name, p_NAME AS field_value, DECODE(trim(v_rec.NAME), trim(p_NAME),'N','Y') upd_flg FROM dual
		UNION
		SELECT  'REK_DANA'  AS field_name, p_REK_DANA AS field_value, DECODE(trim(v_rec.REK_DANA), trim(p_REK_DANA),'N','Y') upd_flg FROM dual
		UNION
		SELECT  'BANK_CD'  AS field_name, p_BANK_CD AS field_value, DECODE(trim(v_rec.BANK_CD), trim(p_BANK_CD),'N','Y') upd_flg FROM dual
		UNION
		SELECT  'CREATE_DT'  AS field_name, TO_CHAR(p_CREATE_DT,'yyyy/mm/dd hh24:mi:ss')  AS field_value, DECODE(v_rec.CREATE_DT, p_CREATE_DT,'N','Y') upd_flg FROM dual
		UNION
		SELECT  'CRE_DT'  AS field_name, TO_CHAR(SYSDATE,'yyyy/mm/dd hh24:mi:ss')  AS field_value, 'Y' upd_flg FROM dual
		WHERE P_UPD_STATUS = 'I'
		UNION
		SELECT  'USER_ID'  AS field_name, p_USER_ID AS field_value, 'Y' upd_flg FROM dual
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

END Sp_T_REK_DANA_KSEI_Upd;