create or replace 
PROCEDURE Sp_T_CORP_GUARANTEE_Upd(
	P_SEARCH_CONTRACT_DT T_CORP_GUARANTEE.CONTRACT_DT%TYPE,
	P_SEARCH_GUARANTEED T_CORP_GUARANTEE.GUARANTEED%TYPE,
	P_CONTRACT_DT		T_CORP_GUARANTEE.CONTRACT_DT%TYPE,
	P_END_CONTRACT_DT		T_CORP_GUARANTEE.END_CONTRACT_DT%TYPE,
	P_GUARANTEED		T_CORP_GUARANTEE.GUARANTEED%TYPE,
	P_AFILIASI		T_CORP_GUARANTEE.AFILIASI%TYPE,
	P_RINCIAN		T_CORP_GUARANTEE.RINCIAN%TYPE,
	P_JANGKA		T_CORP_GUARANTEE.JANGKA%TYPE,
	P_NILAI		T_CORP_GUARANTEE.NILAI%TYPE,
	P_CRE_DT		T_CORP_GUARANTEE.CRE_DT%TYPE,
	P_USER_ID		T_CORP_GUARANTEE.USER_ID%TYPE,
	P_UPD_DT		T_CORP_GUARANTEE.UPD_DT%TYPE,
	P_UPD_BY		T_CORP_GUARANTEE.UPD_BY%TYPE,
	P_UPD_STATUS		T_TEMP_HEADER.STATUS%TYPE,
	p_ip_address		T_TEMP_HEADER.IP_ADDRESS%TYPE,
	p_cancel_reason		T_TEMP_HEADER.CANCEL_REASON%TYPE,
	p_error_code		OUT			NUMBER,
	p_error_msg		OUT			VARCHAR2
) IS



	v_err EXCEPTION;
	v_error_code				NUMBER;
	v_error_msg					VARCHAR2(1000);
	v_table_name 				T_TEMP_HEADER.table_name%TYPE := 'T_CORP_GUARANTEE';
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
FROM T_CORP_GUARANTEE
WHERE CONTRACT_DT = p_search_CONTRACT_DT
	AND GUARANTEED = p_search_GUARANTEED;

v_temp_detail  Types.temp_detail_rc;

v_rec T_CORP_GUARANTEE%ROWTYPE;




v_cnt INTEGER;
 i INTEGER;
 V_FIELD_CNT NUMBER;
 v_pending_cnt NUMBER;
 va CHAR(1) := '@';
BEGIN

			IF 	  P_UPD_STATUS = 'I' AND (p_search_CONTRACT_DT <> p_CONTRACT_DT
								OR p_search_GUARANTEED <> P_GUARANTEED) THEN
			       v_error_code := -2001;
					IF p_search_CONTRACT_DT <> p_CONTRACT_DT THEN
				   		v_error_msg := 'jika INSERT, p_search_CONTRACT_DT harus sama dengan P_CONTRACT_DT';
					END IF;
					IF P_SEARCH_GUARANTEED<> P_GUARANTEED THEN
				   		v_error_msg := 'jika INSERT, P_SEARCH_GUARANTEED harus sama dengan P_GUARANTEED';
					END IF;

				   RAISE v_err;
			END IF;
			
             BEGIN
   	 		 SELECT ROWID INTO v_table_rowid
			 FROM T_CORP_GUARANTEE
			 WHERE CONTRACT_DT = p_search_CONTRACT_DT
				AND GUARANTEED = p_search_GUARANTEED;
			 EXCEPTION
			 WHEN NO_DATA_FOUND THEN
			 	  v_table_rowid := NULL;
			WHEN OTHERS THEN
				     v_error_code := -2;
					 v_error_msg :=  SUBSTR('Retrieve  '|| v_table_name||' for '||p_search_CONTRACT_DT||SQLERRM,1,200);
					 RAISE v_err;
				  END;

			IF 	  P_UPD_STATUS = 'I' AND v_table_rowid IS NOT NULL THEN
			       v_error_code := -2001;
				   v_error_msg  := 'DUPLICATED CONTRACT DATE AND GUARANTEED';
				   RAISE v_err;
			END IF;
			
			IF 	  P_UPD_STATUS = 'U' AND (p_search_CONTRACT_DT <> P_CONTRACT_DT
								OR P_SEARCH_GUARANTEED<> P_GUARANTEED) THEN
				 BEGIN
	   	 		 SELECT COUNT(1) INTO v_cnt
				 FROM T_CORP_GUARANTEE
				 WHERE CONTRACT_DT = p_CONTRACT_DT
					AND GUARANTEED = P_GUARANTEED;
				 EXCEPTION
				 WHEN NO_DATA_FOUND THEN
				 	  v_cnt := 0;
				WHEN OTHERS THEN
					     v_error_code := -3;
						 v_error_msg :=  SUBSTR('Retrieve  '|| v_table_name||' for '||p_search_GUARANTEED||SQLERRM,1,200);
						 RAISE v_err;
				  END; 
				  
				  IF v_cnt  > 0 THEN
					       v_error_code := -2003;
						   v_error_msg  := 'DUPLICATED CONTRACT DATE AND GUARANTEED';
						   RAISE v_err;
				   END IF;
			END IF;
			
				  
				  
			IF v_table_rowid IS NULL THEN
					 BEGIN
					 SELECT COUNT(1) INTO v_pending_cnt
					 FROM (SELECT MAX(CONTRACT_DT) CONTRACT_DT, MAX(GUARANTEED) GUARANTEED
							FROM (SELECT DECODE (field_name, 'CONTRACT_DT', field_value, NULL) CONTRACT_DT,
								DECODE	(field_name, 'GUARANTEED', field_value, NULL) GUARANTEED
								 FROM T_TEMP_DETAIL D, T_TEMP_HEADER H
								 WHERE h.table_name = v_table_name
								 AND d.update_date = h.update_date
								 AND d.update_seq = h.update_seq
								 AND d.table_name = h.table_name
								 AND (d.field_name = 'CONTRACT_DT' OR d.field_name = 'GUARANTEED') 
								 AND h.APPROVED_status = 'E'))
					 WHERE CONTRACT_DT = p_search_CONTRACT_DT
						AND GUARANTEED = p_search_GUARANTEED;
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
		(
		 SELECT  'CONTRACT_DT'  AS field_name, TO_CHAR(p_CONTRACT_DT,'yyyy/mm/dd hh24:mi:ss')  AS field_value, DECODE(v_rec.CONTRACT_DT, p_CONTRACT_DT,'N','Y') upd_flg FROM dual
			UNION
			SELECT  'END_CONTRACT_DT'  AS field_name, TO_CHAR(p_END_CONTRACT_DT,'yyyy/mm/dd hh24:mi:ss')  AS field_value, DECODE(v_rec.END_CONTRACT_DT, p_END_CONTRACT_DT,'N','Y') upd_flg FROM dual
			UNION
			SELECT  'GUARANTEED'  AS field_name, p_GUARANTEED AS field_value, DECODE(trim(v_rec.GUARANTEED), trim(p_GUARANTEED),'N','Y') upd_flg FROM dual
			UNION
			SELECT  'AFILIASI'  AS field_name, p_AFILIASI AS field_value, DECODE(trim(v_rec.AFILIASI), trim(p_AFILIASI),'N','Y') upd_flg FROM dual
			UNION
			SELECT  'RINCIAN'  AS field_name, p_RINCIAN AS field_value, DECODE(trim(v_rec.RINCIAN), trim(p_RINCIAN),'N','Y') upd_flg FROM dual
			UNION
			SELECT  'JANGKA'  AS field_name, p_JANGKA AS field_value, DECODE(trim(v_rec.JANGKA), trim(p_JANGKA),'N','Y') upd_flg FROM dual
			UNION
			SELECT  'NILAI'  AS field_name, TO_CHAR(p_NILAI)  AS field_value, DECODE(v_rec.NILAI, p_NILAI,'N','Y') upd_flg FROM dual
			UNION
			SELECT  'CRE_DT'  AS field_name, TO_CHAR(p_CRE_DT,'yyyy/mm/dd hh24:mi:ss')  AS field_value, DECODE(v_rec.CRE_DT, p_CRE_DT,'N','Y') upd_flg FROM dual
			UNION
			SELECT  'USER_ID'  AS field_name, p_USER_ID AS field_value, DECODE(trim(v_rec.USER_ID), trim(p_USER_ID),'N','Y') upd_flg FROM dual
			UNION
			SELECT  'UPD_DT'  AS field_name, TO_CHAR(p_UPD_DT,'yyyy/mm/dd hh24:mi:ss')  AS field_value, DECODE(v_rec.UPD_DT, p_UPD_DT,'N','Y') upd_flg FROM dual
			UNION
			SELECT  'UPD_BY'  AS field_name, p_UPD_BY AS field_value, DECODE(trim(v_rec.UPD_BY), trim(p_UPD_BY),'N','Y') upd_flg FROM dual

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

END Sp_T_CORP_GUARANTEE_Upd;