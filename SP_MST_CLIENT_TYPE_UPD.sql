create or replace 
PROCEDURE           SP_MST_CLIENT_TYPE_UPD (
		P_SEARCH_CL_TYPE1	MST_CLIENT_TYPE.CL_TYPE1%TYPE,
		P_SEARCH_CL_TYPE2	MST_CLIENT_TYPE.CL_TYPE1%TYPE,
		P_SEARCH_CL_TYPE3	MST_CLIENT_TYPE.CL_TYPE1%TYPE,
		P_CL_TYPE1		MST_CLIENT_TYPE.CL_TYPE1%TYPE,
		P_CL_TYPE2		MST_CLIENT_TYPE.CL_TYPE2%TYPE,
		P_CL_TYPE3		MST_CLIENT_TYPE.CL_TYPE3%TYPE,
		P_TYPE_DESC		MST_CLIENT_TYPE.TYPE_DESC%TYPE,
		P_DUP_CONTRACT		MST_CLIENT_TYPE.DUP_CONTRACT%TYPE,
		P_AVG_CONTRACT		MST_CLIENT_TYPE.AVG_CONTRACT%TYPE,
		P_NETT_ALLOW		MST_CLIENT_TYPE.NETT_ALLOW%TYPE,
		P_REBATE_PCT		MST_CLIENT_TYPE.REBATE_PCT%TYPE,
		P_COMM_PCT		MST_CLIENT_TYPE.COMM_PCT%TYPE,
		P_USER_ID		MST_CLIENT_TYPE.USER_ID%TYPE,
		P_CRE_DT		MST_CLIENT_TYPE.CRE_DT%TYPE,
		P_UPD_DT		MST_CLIENT_TYPE.UPD_DT%TYPE,
		P_OS_P_ACCT_CD		MST_CLIENT_TYPE.OS_P_ACCT_CD%TYPE,
		P_OS_S_ACCT_CD		MST_CLIENT_TYPE.OS_S_ACCT_CD%TYPE,
		P_OS_CONTRA_G_ACCT_CD		MST_CLIENT_TYPE.OS_CONTRA_G_ACCT_CD%TYPE,
		P_OS_CONTRA_L_ACCT_CD		MST_CLIENT_TYPE.OS_CONTRA_L_ACCT_CD%TYPE,
		P_OS_SETOFF_G_ACCT_CD		MST_CLIENT_TYPE.OS_SETOFF_G_ACCT_CD%TYPE,
		P_OS_SETOFF_L_ACCT_CD		MST_CLIENT_TYPE.OS_SETOFF_L_ACCT_CD%TYPE,
		P_INT_ON_PAYABLE		MST_CLIENT_TYPE.INT_ON_PAYABLE%TYPE,
		P_INT_ON_RECEIVABLE		MST_CLIENT_TYPE.INT_ON_RECEIVABLE%TYPE,
		P_INT_ON_PAY_CHRG_CD		MST_CLIENT_TYPE.INT_ON_PAY_CHRG_CD%TYPE,
		P_INT_ON_REC_CHRG_CD		MST_CLIENT_TYPE.INT_ON_REC_CHRG_CD%TYPE,
		P_UPD_STATUS		T_TEMP_HEADER.STATUS%TYPE,
		p_ip_address		T_TEMP_HEADER.IP_ADDRESS%TYPE,
		p_cancel_reason		T_TEMP_HEADER.CANCEL_REASON%TYPE,
		p_error_code		OUT			NUMBER,
		p_error_msg		OUT			VARCHAR2
) IS

	v_err EXCEPTION;
	v_error_code				NUMBER;
	v_error_msg					VARCHAR2(1000);
	v_table_name 				T_TEMP_HEADER.table_name%TYPE := 'MST_CLIENT_TYPE';
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
FROM MST_CLIENT_TYPE
WHERE CL_TYPE1 = p_search_CL_TYPE1
	AND CL_TYPE2 = p_search_CL_TYPE2
	AND CL_TYPE3 = p_search_CL_TYPE3;

v_temp_detail  Types.temp_detail_rc;

v_rec MST_CLIENT_TYPE%ROWTYPE;




v_cnt INTEGER;
 i INTEGER;
 V_FIELD_CNT NUMBER;
 v_pending_cnt NUMBER;
 va CHAR(1) := '@';
BEGIN

			IF 	  P_UPD_STATUS = 'I' AND (p_search_CL_TYPE1 <> p_CL_TYPE1
								OR p_search_CL_TYPE2 <> P_CL_TYPE2 
								OR P_SEARCH_CL_TYPE3 <> P_CL_TYPE3) THEN
			       v_error_code := -2001;
					IF p_search_CL_TYPE1 <> p_CL_TYPE1 THEN
				   		v_error_msg := 'jika INSERT, p_search_CL_TYPE1 harus sama dengan P_CL_TYPE1';
					END IF;
					IF p_search_CL_TYPE2 <> p_CL_TYPE2 THEN
				   		v_error_msg := 'jika INSERT, p_search_CL_TYPE2 harus sama dengan P_CL_TYPE2';
					END IF;
					IF p_search_CL_TYPE3 <> p_CL_TYPE3 THEN
				   		v_error_msg := 'jika INSERT, p_search_CL_TYPE3 harus sama dengan P_CL_TYPE3';
					END IF;

				   RAISE v_err;
			END IF;
			
             BEGIN
   	 		 SELECT ROWID INTO v_table_rowid
			 FROM MST_CLIENT_TYPE
			 WHERE CL_TYPE1 = p_search_CL_TYPE1
				AND CL_TYPE2 = p_search_CL_TYPE2
				AND CL_TYPE3 = p_search_CL_TYPE3;
			 EXCEPTION
			 WHEN NO_DATA_FOUND THEN
			 	  v_table_rowid := NULL;
			WHEN OTHERS THEN
				     v_error_code := -2;
					 v_error_msg :=  SUBSTR('Retrieve  '|| v_table_name||SQLERRM,1,200);
					 RAISE v_err;
				  END;

			IF 	  P_UPD_STATUS = 'I' AND v_table_rowid IS NOT NULL THEN
			       v_error_code := -2001;
				   v_error_msg  := 'DUPLICATED CL TYPE 1 AND CL TYPE 2 AND CL TYPE 3 ';
				   RAISE v_err;
			END IF;
			
			IF 	  P_UPD_STATUS = 'U' AND (p_search_CL_TYPE1 <> P_CL_TYPE1
								OR p_search_CL_TYPE2 <> P_CL_TYPE2 
								OR p_search_CL_TYPE3 <> P_CL_TYPE3 ) THEN
				 BEGIN
	   	 		 SELECT COUNT(1) INTO v_cnt
				 FROM MST_CLIENT_TYPE
				 WHERE CL_TYPE1 = p_CL_TYPE1
					AND CL_TYPE2 = p_CL_TYPE2
					AND CL_TYPE3 = P_CL_TYPE3;
				 EXCEPTION
				 WHEN NO_DATA_FOUND THEN
				 	  v_cnt := 0;
				WHEN OTHERS THEN
					     v_error_code := -3;
						 v_error_msg :=  SUBSTR('Retrieve  '|| v_table_name||' '||SQLERRM,1,200);
						 RAISE v_err;
				  END; 
				  
				  IF v_cnt  > 0 THEN
					       v_error_code := -2003;
						   v_error_msg  := 'DUPLICATED CL TYPE1 AND CL TYPE2 AND CL TYPE 3';
						   RAISE v_err;
				   END IF;
			END IF;
			
				  
				  
			IF v_table_rowid IS NULL THEN
					 BEGIN
					 SELECT COUNT(1) INTO v_pending_cnt
					 FROM (SELECT MAX(CL_TYPE1) CL_TYPE1, MAX(CL_TYPE2) CL_TYPE2, MAC(CL_TYPE3) CL_TYPE3
							FROM (SELECT 
								DECODE (field_name, 'CL_TYPE1', field_value, NULL) CL_TYPE1,
								DECODE	(field_name, 'CL_TYPE2', field_value, NULL) CL_TYPE2,
								DECODE	(field_name, 'CL_TYPE3', field_value, NULL) CL_TYPE3
								 FROM T_TEMP_DETAIL D, T_TEMP_HEADER H
								 WHERE h.table_name = v_table_name
								 AND d.update_date = h.update_date
								 AND d.update_seq = h.update_seq
								 AND d.table_name = h.table_name
								 AND (d.field_name = 'CL_TYPE1' OR d.field_name = 'CL_TYPE2' OR d.field_name = ' CL_TYPE3') 
								 AND h.APPROVED_status = 'E'))
					 WHERE CL_TYPE1 = p_search_CL_TYPE1
						AND CL_TYPE2 = p_search_CL_TYPE2
						AND CL_TYPE3 = p_search_CL_TYPE3;
					 EXCEPTION
					 WHEN NO_DATA_FOUND THEN
					         v_pending_cnt := 0;
					WHEN OTHERS THEN
							 v_error_code := -4;
							 v_error_msg :=  SUBSTR('Retrieve T_TEMP_HEADER for '|| v_table_name||' '||SQLERRM,1,200);
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
		
SELECT  'CL_TYPE1'  AS field_name, p_CL_TYPE1 AS field_value, DECODE(trim(v_rec.CL_TYPE1), trim(p_CL_TYPE1),'N','Y') upd_flg FROM dual
UNION
SELECT  'CL_TYPE2'  AS field_name, p_CL_TYPE2 AS field_value, DECODE(trim(v_rec.CL_TYPE2), trim(p_CL_TYPE2),'N','Y') upd_flg FROM dual
UNION
SELECT  'CL_TYPE3'  AS field_name, p_CL_TYPE3 AS field_value, DECODE(trim(v_rec.CL_TYPE3), trim(p_CL_TYPE3),'N','Y') upd_flg FROM dual
UNION
SELECT  'TYPE_DESC'  AS field_name, p_TYPE_DESC AS field_value, DECODE(trim(v_rec.TYPE_DESC), trim(p_TYPE_DESC),'N','Y') upd_flg FROM dual
UNION
SELECT  'DUP_CONTRACT'  AS field_name, p_DUP_CONTRACT AS field_value, DECODE(trim(v_rec.DUP_CONTRACT), trim(p_DUP_CONTRACT),'N','Y') upd_flg FROM dual
UNION
SELECT  'AVG_CONTRACT'  AS field_name, p_AVG_CONTRACT AS field_value, DECODE(trim(v_rec.AVG_CONTRACT), trim(p_AVG_CONTRACT),'N','Y') upd_flg FROM dual
UNION
SELECT  'NETT_ALLOW'  AS field_name, p_NETT_ALLOW AS field_value, DECODE(trim(v_rec.NETT_ALLOW), trim(p_NETT_ALLOW),'N','Y') upd_flg FROM dual
UNION
SELECT  'REBATE_PCT'  AS field_name, TO_CHAR(p_REBATE_PCT)  AS field_value, DECODE(v_rec.REBATE_PCT, p_REBATE_PCT,'N','Y') upd_flg FROM dual
UNION
SELECT  'COMM_PCT'  AS field_name, TO_CHAR(p_COMM_PCT)  AS field_value, DECODE(v_rec.COMM_PCT, p_COMM_PCT,'N','Y') upd_flg FROM dual
UNION
SELECT  'USER_ID'  AS field_name, p_USER_ID AS field_value, DECODE(trim(v_rec.USER_ID), trim(p_USER_ID),'N','Y') upd_flg FROM dual
UNION
SELECT  'CRE_DT'  AS field_name, TO_CHAR(p_CRE_DT,'yyyy/mm/dd hh24:mi:ss')  AS field_value, DECODE(v_rec.CRE_DT, p_CRE_DT,'N','Y') upd_flg FROM dual
UNION
SELECT  'UPD_DT'  AS field_name, TO_CHAR(p_UPD_DT,'yyyy/mm/dd hh24:mi:ss')  AS field_value, DECODE(v_rec.UPD_DT, p_UPD_DT,'N','Y') upd_flg FROM dual
UNION
SELECT  'OS_P_ACCT_CD'  AS field_name, p_OS_P_ACCT_CD AS field_value, DECODE(trim(v_rec.OS_P_ACCT_CD), trim(p_OS_P_ACCT_CD),'N','Y') upd_flg FROM dual
UNION
SELECT  'OS_S_ACCT_CD'  AS field_name, p_OS_S_ACCT_CD AS field_value, DECODE(trim(v_rec.OS_S_ACCT_CD), trim(p_OS_S_ACCT_CD),'N','Y') upd_flg FROM dual
UNION
SELECT  'OS_CONTRA_G_ACCT_CD'  AS field_name, p_OS_CONTRA_G_ACCT_CD AS field_value, DECODE(trim(v_rec.OS_CONTRA_G_ACCT_CD), trim(p_OS_CONTRA_G_ACCT_CD),'N','Y') upd_flg FROM dual
UNION
SELECT  'OS_CONTRA_L_ACCT_CD'  AS field_name, p_OS_CONTRA_L_ACCT_CD AS field_value, DECODE(trim(v_rec.OS_CONTRA_L_ACCT_CD), trim(p_OS_CONTRA_L_ACCT_CD),'N','Y') upd_flg FROM dual
UNION
SELECT  'OS_SETOFF_G_ACCT_CD'  AS field_name, p_OS_SETOFF_G_ACCT_CD AS field_value, DECODE(trim(v_rec.OS_SETOFF_G_ACCT_CD), trim(p_OS_SETOFF_G_ACCT_CD),'N','Y') upd_flg FROM dual
UNION
SELECT  'OS_SETOFF_L_ACCT_CD'  AS field_name, p_OS_SETOFF_L_ACCT_CD AS field_value, DECODE(trim(v_rec.OS_SETOFF_L_ACCT_CD), trim(p_OS_SETOFF_L_ACCT_CD),'N','Y') upd_flg FROM dual
UNION
SELECT  'INT_ON_PAYABLE'  AS field_name, TO_CHAR(p_INT_ON_PAYABLE)  AS field_value, DECODE(v_rec.INT_ON_PAYABLE, p_INT_ON_PAYABLE,'N','Y') upd_flg FROM dual
UNION
SELECT  'INT_ON_RECEIVABLE'  AS field_name, TO_CHAR(p_INT_ON_RECEIVABLE)  AS field_value, DECODE(v_rec.INT_ON_RECEIVABLE, p_INT_ON_RECEIVABLE,'N','Y') upd_flg FROM dual
UNION
SELECT  'INT_ON_PAY_CHRG_CD'  AS field_name, p_INT_ON_PAY_CHRG_CD AS field_value, DECODE(trim(v_rec.INT_ON_PAY_CHRG_CD), trim(p_INT_ON_PAY_CHRG_CD),'N','Y') upd_flg FROM dual
UNION
SELECT  'INT_ON_REC_CHRG_CD'  AS field_name, p_INT_ON_REC_CHRG_CD AS field_value, DECODE(trim(v_rec.INT_ON_REC_CHRG_CD), trim(p_INT_ON_REC_CHRG_CD),'N','Y') upd_flg FROM dual

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

END Sp_MST_CLIENT_TYPE_Upd;