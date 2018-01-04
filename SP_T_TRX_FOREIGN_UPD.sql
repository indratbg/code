create or replace 
PROCEDURE Sp_T_TRX_FOREIGN_Upd(
	P_SEARCH_TGL_TRX T_TRX_FOREIGN.TGL_TRX%TYPE,
	P_SEARCH_NORUT T_TRX_FOREIGN.NORUT%TYPE,
	P_TGL_TRX		T_TRX_FOREIGN.TGL_TRX%TYPE,
	P_NORUT		T_TRX_FOREIGN.NORUT%TYPE,
	P_JENIS_TRX		T_TRX_FOREIGN.JENIS_TRX%TYPE,
	P_CURRENCY_TYPE		T_TRX_FOREIGN.CURRENCY_TYPE%TYPE,
	P_NILAI_RPH		T_TRX_FOREIGN.NILAI_RPH%TYPE,
	P_UNTUNG_UNREAL		T_TRX_FOREIGN.UNTUNG_UNREAL%TYPE,
	P_RUGI_UNREAL		T_TRX_FOREIGN.RUGI_UNREAL%TYPE,
	P_CRE_DT		T_TRX_FOREIGN.CRE_DT%TYPE,
	P_USER_ID		T_TRX_FOREIGN.USER_ID%TYPE,
	P_UPD_DT		T_TRX_FOREIGN.UPD_DT%TYPE,
	P_UPD_BY		T_TRX_FOREIGN.UPD_BY%TYPE,
	P_APPROVED_DT		T_TRX_FOREIGN.APPROVED_DT%TYPE,
	P_APPROVED_BY		T_TRX_FOREIGN.APPROVED_BY%TYPE,
	P_APPROVED_STAT		T_TRX_FOREIGN.APPROVED_STAT%TYPE,
	P_SEQNO		T_TRX_FOREIGN.SEQNO%TYPE,
	P_UPD_STATUS		T_TEMP_HEADER.STATUS%TYPE,
	p_ip_address		T_TEMP_HEADER.IP_ADDRESS%TYPE,
	p_cancel_reason		T_TEMP_HEADER.CANCEL_REASON%TYPE,
	p_error_code		OUT			NUMBER,
	p_error_msg		OUT			VARCHAR2
) IS



	v_err EXCEPTION;
	v_error_code				NUMBER;
	v_error_msg					VARCHAR2(1000);
	v_table_name 				T_TEMP_HEADER.table_name%TYPE := 'T_TRX_FOREIGN';
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
FROM T_TRX_FOREIGN
WHERE TGL_TRX = p_search_TGL_TRX
	AND NORUT = p_search_NORUT;

v_temp_detail  Types.temp_detail_rc;

v_rec T_TRX_FOREIGN%ROWTYPE;




v_cnt INTEGER;
 i INTEGER;
 V_FIELD_CNT NUMBER;
 v_pending_cnt NUMBER;
 va CHAR(1) := '@';
BEGIN

			IF 	  P_UPD_STATUS = 'I' AND (P_SEARCH_TGL_TRX <> P_TGL_TRX
								OR P_SEARCH_NORUT <> P_NORUT) THEN
			       v_error_code := -2001;
					IF P_SEARCH_TGL_TRX <> P_TGL_TRX THEN
				   		v_error_msg := 'jika INSERT, P_SEARCH_TGL_TRX harus sama dengan P_TGL_TRX';
					END IF;
					IF P_SEARCH_NORUT<> P_NORUT THEN
				   		v_error_msg := 'jika INSERT, P_SEARCH_NORUT harus sama dengan P_NORUT';
					END IF;

				   RAISE v_err;
			END IF;
			
             BEGIN
   	 		 SELECT ROWID INTO v_table_rowid
			 FROM T_TRX_FOREIGN
			 WHERE TGL_TRX = P_SEARCH_TGL_TRX
				AND NORUT = P_SEARCH_NORUT;
			 EXCEPTION
			 WHEN NO_DATA_FOUND THEN
			 	  v_table_rowid := NULL;
			WHEN OTHERS THEN
				     v_error_code := -2;
					 v_error_msg :=  SUBSTR('Retrieve  '|| v_table_name||' for '||P_SEARCH_TGL_TRX||SQLERRM,1,200);
					 RAISE v_err;
				  END;

			IF 	  P_UPD_STATUS = 'I' AND v_table_rowid IS NOT NULL THEN
			       v_error_code := -2001;
				   v_error_msg  := 'DUPLICATED CONTRACT DATE AND NORUT';
				   RAISE v_err;
			END IF;
			
			IF 	  P_UPD_STATUS = 'U' AND (P_SEARCH_TGL_TRX <> P_TGL_TRX
								OR P_SEARCH_NORUT<> P_NORUT) THEN
				 BEGIN
	   	 		 SELECT COUNT(1) INTO v_cnt
				 FROM T_TRX_FOREIGN
				 WHERE TGL_TRX = P_TGL_TRX
					AND NORUT = P_NORUT;
				 EXCEPTION
				 WHEN NO_DATA_FOUND THEN
				 	  v_cnt := 0;
				WHEN OTHERS THEN
					     v_error_code := -3;
						 v_error_msg :=  SUBSTR('Retrieve  '|| v_table_name||' for '||P_SEARCH_NORUT||SQLERRM,1,200);
						 RAISE v_err;
				  END; 
				  
				  IF v_cnt  > 0 THEN
					       v_error_code := -2003;
						   v_error_msg  := 'DUPLICATED DATE TRANSACTION AND NO URUT';
						   RAISE v_err;
				   END IF;
			END IF;
			
				  
				  
			IF v_table_rowid IS NULL THEN
					 BEGIN
					 SELECT COUNT(1) INTO v_pending_cnt
					 FROM (SELECT MAX(TGL_TRX) TGL_TRX, MAX(NORUT) NORUT
							FROM (SELECT DECODE (field_name, 'TGL_TRX', field_value, NULL) TGL_TRX,
								DECODE	(field_name, 'NORUT', field_value, NULL) NORUT
								 FROM T_TEMP_DETAIL D, T_TEMP_HEADER H
								 WHERE h.table_name = v_table_name
								 AND d.update_date = h.update_date
								 AND d.update_seq = h.update_seq
								 AND d.table_name = h.table_name
								 AND (d.field_name = 'TGL_TRX' OR d.field_name = 'NORUT') 
								 AND h.APPROVED_status = 'E'))
					 WHERE TGL_TRX = P_SEARCH_TGL_TRX
						AND NORUT = P_SEARCH_NORUT;
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
		
		(SELECT  'TGL_TRX'  AS field_name, TO_CHAR(p_TGL_TRX,'yyyy/mm/dd hh24:mi:ss')  AS field_value, DECODE(v_rec.TGL_TRX, p_TGL_TRX,'N','Y') upd_flg FROM dual
		UNION
		SELECT  'NORUT'  AS field_name, TO_CHAR(p_NORUT)  AS field_value, DECODE(v_rec.NORUT, p_NORUT,'N','Y') upd_flg FROM dual
		UNION
		SELECT  'JENIS_TRX'  AS field_name, p_JENIS_TRX AS field_value, DECODE(trim(v_rec.JENIS_TRX), trim(p_JENIS_TRX),'N','Y') upd_flg FROM dual
		UNION
		SELECT  'CURRENCY_TYPE'  AS field_name, p_CURRENCY_TYPE AS field_value, DECODE(trim(v_rec.CURRENCY_TYPE), trim(p_CURRENCY_TYPE),'N','Y') upd_flg FROM dual
		UNION
		SELECT  'NILAI_RPH'  AS field_name, TO_CHAR(p_NILAI_RPH)  AS field_value, DECODE(v_rec.NILAI_RPH, p_NILAI_RPH,'N','Y') upd_flg FROM dual
		UNION
		SELECT  'UNTUNG_UNREAL'  AS field_name, TO_CHAR(p_UNTUNG_UNREAL)  AS field_value, DECODE(v_rec.UNTUNG_UNREAL, p_UNTUNG_UNREAL,'N','Y') upd_flg FROM dual
		UNION
		SELECT  'RUGI_UNREAL'  AS field_name, TO_CHAR(p_RUGI_UNREAL)  AS field_value, DECODE(v_rec.RUGI_UNREAL, p_RUGI_UNREAL,'N','Y') upd_flg FROM dual
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

		UNION
		SELECT  'SEQNO'  AS field_name, TO_CHAR(p_SEQNO)  AS field_value, DECODE(v_rec.SEQNO, p_SEQNO,'N','Y') upd_flg FROM dual
		

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

END Sp_T_TRX_FOREIGN_Upd;