create or replace 
PROCEDURE SP_MST_CLIENT_FLACCT_IMPRT_UPD(
		P_SEARCH_CLIENT_CD		MST_CLIENT_FLACCT.CLIENT_CD%TYPE,
		P_SEARCH_BANK_ACCT_NUM		MST_CLIENT_FLACCT.BANK_ACCT_NUM%TYPE,
		P_CLIENT_CD		MST_CLIENT_FLACCT.CLIENT_CD%TYPE,
		P_BANK_CD		MST_CLIENT_FLACCT.BANK_CD%TYPE,
		P_BANK_ACCT_NUM		MST_CLIENT_FLACCT.BANK_ACCT_NUM%TYPE,
		P_ACCT_NAME		MST_CLIENT_FLACCT.ACCT_NAME%TYPE,
		P_ACCT_STAT		MST_CLIENT_FLACCT.ACCT_STAT%TYPE,
		P_BANK_SHORT_NAME		MST_CLIENT_FLACCT.BANK_SHORT_NAME%TYPE,
		P_BANK_ACCT_FMT		MST_CLIENT_FLACCT.BANK_ACCT_FMT%TYPE,
		P_CRE_DT		MST_CLIENT_FLACCT.CRE_DT%TYPE,
		P_USER_ID		MST_CLIENT_FLACCT.USER_ID%TYPE,
		P_UPD_DT		MST_CLIENT_FLACCT.UPD_DT%TYPE,
		P_UPD_USER_ID		MST_CLIENT_FLACCT.UPD_USER_ID%TYPE,
		P_UPD_BY		MST_CLIENT_FLACCT.UPD_BY%TYPE,
		P_FROM_DT		MST_CLIENT_FLACCT.FROM_DT%TYPE,
		P_TO_DT		MST_CLIENT_FLACCT.TO_DT%TYPE,
		P_UPD_STATUS		T_TEMP_HEADER.STATUS%TYPE,
		p_ip_address		T_TEMP_HEADER.IP_ADDRESS%TYPE,
		p_cancel_reason		T_TEMP_HEADER.CANCEL_REASON%TYPE,
		p_error_code		OUT			NUMBER,
		p_error_msg		OUT			VARCHAR2
) IS



	v_err EXCEPTION;
	v_error_code				NUMBER;
	v_error_msg					VARCHAR2(1000);
	v_table_name 				T_TEMP_HEADER.table_name%TYPE := 'MST_CLIENT_FLACCT';
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
FROM MST_CLIENT_FLACCT
WHERE CLIENT_CD = p_search_CLIENT_CD
	AND BANK_ACCT_NUM = p_search_BANK_ACCT_NUM;

v_temp_detail  Types.temp_detail_rc;

v_rec MST_CLIENT_FLACCT%ROWTYPE;




v_cnt INTEGER;
 i INTEGER;
 V_FIELD_CNT NUMBER;
 v_pending_cnt NUMBER;
 va CHAR(1) := '@';
BEGIN

			IF 	  P_UPD_STATUS = 'I' AND (P_SEARCH_CLIENT_CD <> P_CLIENT_CD
								OR P_SEARCH_BANK_ACCT_NUM <> P_BANK_ACCT_NUM) THEN
			       v_error_code := -2001;
					IF P_SEARCH_CLIENT_CD <> P_CLIENT_CD THEN
				   		v_error_msg := 'jika INSERT, P_SEARCH_CLIENT_CD harus sama dengan P_CLIENT_CD';
					END IF;
					IF P_SEARCH_BANK_ACCT_NUM<> P_BANK_ACCT_NUM THEN
				   		v_error_msg := 'jika INSERT, P_SEARCH_BANK_ACCT_NUM harus sama dengan P_BANK_ACCT_NUM';
					END IF;

				   RAISE v_err;
			END IF;
			
             BEGIN
   	 		 SELECT ROWID INTO v_table_rowid
			 FROM MST_CLIENT_FLACCT
			 WHERE CLIENT_CD = P_SEARCH_CLIENT_CD
				AND BANK_ACCT_NUM = P_SEARCH_BANK_ACCT_NUM;
			 EXCEPTION
			 WHEN NO_DATA_FOUND THEN
			 	  v_table_rowid := NULL;
			WHEN OTHERS THEN
				     v_error_code := -2;
					 v_error_msg :=  SUBSTR('Retrieve  '|| v_table_name||' for '||P_SEARCH_CLIENT_CD||SQLERRM,1,200);
					 RAISE v_err;
				  END;

			IF 	  P_UPD_STATUS = 'I' AND v_table_rowid IS NOT NULL THEN
			       v_error_code := -2001;
				   v_error_msg  := 'DUPLICATED CLIENT CD DAN NOMOR REKENING DANA';
				   RAISE v_err;
			END IF;
			
			IF 	  P_UPD_STATUS = 'U' AND (P_SEARCH_CLIENT_CD <> P_CLIENT_CD
								OR P_SEARCH_BANK_ACCT_NUM<> P_BANK_ACCT_NUM) THEN
				 BEGIN
	   	 		 SELECT COUNT(1) INTO v_cnt
				 FROM MST_CLIENT_FLACCT
				 WHERE CLIENT_CD = P_CLIENT_CD
					AND BANK_ACCT_NUM = P_BANK_ACCT_NUM;
				 EXCEPTION
				 WHEN NO_DATA_FOUND THEN
				 	  v_cnt := 0;
				WHEN OTHERS THEN
					     v_error_code := -3;
						 v_error_msg :=  SUBSTR('Retrieve  '|| v_table_name||' for '||P_SEARCH_BANK_ACCT_NUM||SQLERRM,1,200);
						 RAISE v_err;
				  END; 
				  
				  IF v_cnt  > 0 THEN
					       v_error_code := -2003;
						   v_error_msg  := 'DUPLICATED CLIENT CD DAN NOMOR REKENING DANA';
						   RAISE v_err;
				   END IF;
			END IF;
			
				  
				  
			IF v_table_rowid IS NULL THEN
					 BEGIN
					 SELECT COUNT(1) INTO v_pending_cnt
					 FROM (SELECT MAX(CLIENT_CD) CLIENT_CD, MAX(BANK_ACCT_NUM) BANK_ACCT_NUM
							FROM (SELECT DECODE (field_name, 'CLIENT_CD', field_value, NULL) CLIENT_CD,
								DECODE	(field_name, 'BANK_ACCT_NUM', field_value, NULL) BANK_ACCT_NUM
								 FROM T_TEMP_DETAIL D, T_TEMP_HEADER H
								 WHERE h.table_name = v_table_name
								 AND d.update_date = h.update_date
								 AND d.update_seq = h.update_seq
								 AND d.table_name = h.table_name
								 AND (d.field_name = 'CLIENT_CD' OR d.field_name = 'BANK_ACCT_NUM') 
								 AND h.APPROVED_status = 'E'))
					 WHERE CLIENT_CD = P_SEARCH_CLIENT_CD
						AND BANK_ACCT_NUM = P_SEARCH_BANK_ACCT_NUM;
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
		(SELECT  'CLIENT_CD'  AS field_name, p_CLIENT_CD AS field_value, DECODE(trim(v_rec.CLIENT_CD), trim(p_CLIENT_CD),'N','Y') upd_flg FROM dual
		UNION
		SELECT  'BANK_CD'  AS field_name, p_BANK_CD AS field_value, DECODE(trim(v_rec.BANK_CD), trim(p_BANK_CD),'N','Y') upd_flg FROM dual
		UNION
		SELECT  'BANK_ACCT_NUM'  AS field_name, p_BANK_ACCT_NUM AS field_value, DECODE(trim(v_rec.BANK_ACCT_NUM), trim(p_BANK_ACCT_NUM),'N','Y') upd_flg FROM dual
		UNION
		SELECT  'ACCT_NAME'  AS field_name, p_ACCT_NAME AS field_value, DECODE(trim(v_rec.ACCT_NAME), trim(p_ACCT_NAME),'N','Y') upd_flg FROM dual
		UNION
		SELECT  'ACCT_STAT'  AS field_name, p_ACCT_STAT AS field_value, DECODE(trim(v_rec.ACCT_STAT), trim(p_ACCT_STAT),'N','Y') upd_flg FROM dual
		UNION
		SELECT  'BANK_SHORT_NAME'  AS field_name, p_BANK_SHORT_NAME AS field_value, DECODE(trim(v_rec.BANK_SHORT_NAME), trim(p_BANK_SHORT_NAME),'N','Y') upd_flg FROM dual
		UNION
		SELECT  'BANK_ACCT_FMT'  AS field_name, p_BANK_ACCT_FMT AS field_value, DECODE(trim(v_rec.BANK_ACCT_FMT), trim(p_BANK_ACCT_FMT),'N','Y') upd_flg FROM dual
		UNION
		SELECT  'UPD_USER_ID'  AS field_name, p_UPD_USER_ID AS field_value, DECODE(trim(v_rec.UPD_USER_ID), trim(p_UPD_USER_ID),'N','Y') upd_flg FROM dual
		UNION
		SELECT  'FROM_DT'  AS field_name, TO_CHAR(p_FROM_DT,'yyyy/mm/dd hh24:mi:ss')  AS field_value, DECODE(v_rec.FROM_DT, p_FROM_DT,'N','Y') upd_flg FROM dual
		UNION
		SELECT  'TO_DT'  AS field_name, TO_CHAR(p_TO_DT,'yyyy/mm/dd hh24:mi:ss')  AS field_value, DECODE(v_rec.TO_DT, p_TO_DT,'N','Y') upd_flg FROM dual
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

END SP_MST_CLIENT_FLACCT_IMPRT_UPD;