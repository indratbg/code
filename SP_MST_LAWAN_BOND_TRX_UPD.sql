create or replace 
PROCEDURE           SP_MST_Lawan_Bond_Trx_UPD (
       p_search_LAWAN	 			MST_LAWAN_BOND_TRX.LAWAN%TYPE,
		P_LAWAN		MST_LAWAN_BOND_TRX.LAWAN%TYPE,
		P_LAWAN_NAME		MST_LAWAN_BOND_TRX.LAWAN_NAME%TYPE,
		P_LAWAN_TYPE		MST_LAWAN_BOND_TRX.LAWAN_TYPE%TYPE,
		P_PHONE		MST_LAWAN_BOND_TRX.PHONE%TYPE,
		P_FAX		MST_LAWAN_BOND_TRX.FAX%TYPE,
		P_CONTACT_PERSON		MST_LAWAN_BOND_TRX.CONTACT_PERSON%TYPE,
		P_CAPITAL_TAX_PCN		MST_LAWAN_BOND_TRX.CAPITAL_TAX_PCN%TYPE,
		P_DEB_GL_ACCT		MST_LAWAN_BOND_TRX.DEB_GL_ACCT%TYPE,
		P_CRE_GL_ACCT		MST_LAWAN_BOND_TRX.CRE_GL_ACCT%TYPE,
		P_SL_ACCT_CD		MST_LAWAN_BOND_TRX.SL_ACCT_CD%TYPE,
		P_CRE_DT		MST_LAWAN_BOND_TRX.CRE_DT%TYPE,
		P_USER_ID		MST_LAWAN_BOND_TRX.USER_ID%TYPE,
		P_UPD_DT		MST_LAWAN_BOND_TRX.UPD_DT%TYPE,
		P_UPD_BY		MST_LAWAN_BOND_TRX.UPD_BY%TYPE,
	
		P_CTP_CD		MST_LAWAN_BOND_TRX.CTP_CD%TYPE,
		P_E_MAIL		MST_LAWAN_BOND_TRX.E_MAIL%TYPE,
		P_CUSTODY_CBEST_CD		MST_LAWAN_BOND_TRX.CUSTODY_CBEST_CD%TYPE,


			P_UPD_STATUS					T_TEMP_HEADER.STATUS%TYPE,
	   p_ip_address								T_TEMP_HEADER.IP_ADDRESS%TYPE,
	   p_cancel_reason						T_TEMP_HEADER.CANCEL_REASON%TYPE,
	   p_error_code					OUT			NUMBER,
	   p_error_msg					OUT			VARCHAR2
) IS



  v_err EXCEPTION;
v_error_code							NUMBER;
v_error_msg							VARCHAR2(200);
v_table_name T_TEMP_HEADER.table_name%TYPE := 'MST_LAWAN_BOND_TRX';
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
FROM MST_LAWAN_BOND_TRX
WHERE LAWAN = p_search_LAWAN;

  v_temp_detail  Types.temp_detail_rc;

v_rec MST_LAWAN_BOND_TRX%ROWTYPE;




v_cnt INTEGER;
 i INTEGER;
 V_FIELD_CNT NUMBER;
 v_pending_cnt NUMBER;
 va CHAR(1) := '@';
BEGIN

			IF 	  P_UPD_STATUS = 'I' AND p_search_LAWAN <> p_LAWAN THEN
			       v_error_code := -2001;
				   v_error_msg  := 'jika INSERT, p_search_LAWAN harus sama dengan p_LAWAN';
				   RAISE v_err;
			END IF;
			
             BEGIN
   	 		 SELECT ROWID INTO v_table_rowid
			 FROM MST_LAWAN_BOND_TRX
			 WHERE TRIM(LAWAN) = TRIM(p_search_LAWAN);
			 EXCEPTION
			 WHEN NO_DATA_FOUND THEN
			 	  v_table_rowid := NULL;
			WHEN OTHERS THEN
				     v_error_code := -2;
					 v_error_msg :=  SUBSTR('Retrieve  '|| v_table_name||' for '||p_search_LAWAN||SQLERRM,1,200);
					 RAISE v_err;
				  END;

			IF 	  P_UPD_STATUS = 'I' AND v_table_rowid IS NOT NULL THEN
			       v_error_code := -2001;
				   v_error_msg  := 'DUPLICATED BOND CODE';
				   RAISE v_err;
			END IF;
			
			IF 	  P_UPD_STATUS = 'U'   AND p_search_LAWAN <> p_LAWAN THEN
				 BEGIN
	   	 		 SELECT COUNT(1) INTO v_cnt
				 FROM MST_LAWAN_BOND_TRX
				 WHERE TRIM(LAWAN) = TRIM(p_LAWAN);
				 EXCEPTION
				 WHEN NO_DATA_FOUND THEN
				 	  v_cnt := 0;
				WHEN OTHERS THEN
					     v_error_code := -3;
						 v_error_msg :=  SUBSTR('Retrieve  '|| v_table_name||' for '||p_LAWAN||SQLERRM,1,200);
						 RAISE v_err;
				  END; 
				  
				  IF v_cnt  > 0 THEN
					       v_error_code := -2003;
						   v_error_msg  := 'DUPLICATED BOND CODE';
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
					 AND d.field_name = 'LAWAN'
					 AND   d.field_value = p_search_LAWAN
					 AND h.APPROVED_status = 'E';
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

    OPEN csr_table;
    FETCH csr_table INTO v_rec;

		OPEN v_Temp_detail FOR
		SELECT update_date, table_name,  0 update_seq,  a.field_name,  field_type, b.field_value, a.column_id, b.upd_flg
		FROM(
		 SELECT  SYSDATE AS  update_date, v_table_name AS table_name, column_id,    column_name AS field_name,
		                       					DECODE(data_type,'VARCHAR2','S','CHAR','S','NUMBER','N','DATE','D','X') AS field_type
										FROM all_tab_columns
										WHERE table_name =v_table_name
										AND OWNER = 'IPNEXTG') a,
		( 
					SELECT  'LAWAN'  AS field_name, p_LAWAN AS field_value, DECODE(trim(v_rec.LAWAN), trim(p_LAWAN),'N','Y') upd_flg FROM dual
UNION
SELECT  'LAWAN_NAME'  AS field_name, p_LAWAN_NAME AS field_value, DECODE(trim(v_rec.LAWAN_NAME), trim(p_LAWAN_NAME),'N','Y') upd_flg FROM dual
UNION
SELECT  'LAWAN_TYPE'  AS field_name, p_LAWAN_TYPE AS field_value, DECODE(trim(v_rec.LAWAN_TYPE), trim(p_LAWAN_TYPE),'N','Y') upd_flg FROM dual
UNION
SELECT  'PHONE'  AS field_name, p_PHONE AS field_value, DECODE(trim(v_rec.PHONE), trim(p_PHONE),'N','Y') upd_flg FROM dual
UNION
SELECT  'FAX'  AS field_name, p_FAX AS field_value, DECODE(trim(v_rec.FAX), trim(p_FAX),'N','Y') upd_flg FROM dual
UNION
SELECT  'CONTACT_PERSON'  AS field_name, p_CONTACT_PERSON AS field_value, DECODE(trim(v_rec.CONTACT_PERSON), trim(p_CONTACT_PERSON),'N','Y') upd_flg FROM dual
UNION
SELECT  'CAPITAL_TAX_PCN'  AS field_name, TO_CHAR(p_CAPITAL_TAX_PCN)  AS field_value, DECODE(v_rec.CAPITAL_TAX_PCN, p_CAPITAL_TAX_PCN,'N','Y') upd_flg FROM dual
UNION
SELECT  'DEB_GL_ACCT'  AS field_name, p_DEB_GL_ACCT AS field_value, DECODE(trim(v_rec.DEB_GL_ACCT), trim(p_DEB_GL_ACCT),'N','Y') upd_flg FROM dual
UNION
SELECT  'CRE_GL_ACCT'  AS field_name, p_CRE_GL_ACCT AS field_value, DECODE(trim(v_rec.CRE_GL_ACCT), trim(p_CRE_GL_ACCT),'N','Y') upd_flg FROM dual
UNION
SELECT  'SL_ACCT_CD'  AS field_name, p_SL_ACCT_CD AS field_value, DECODE(trim(v_rec.SL_ACCT_CD), trim(p_SL_ACCT_CD),'N','Y') upd_flg FROM dual
UNION
SELECT  'CRE_DT'  AS field_name, TO_CHAR(p_CRE_DT,'yyyy/mm/dd hh24:mi:ss')  AS field_value, DECODE(v_rec.CRE_DT, p_CRE_DT,'N','Y') upd_flg FROM dual
UNION
SELECT  'USER_ID'  AS field_name, p_USER_ID AS field_value, DECODE(trim(v_rec.USER_ID), trim(p_USER_ID),'N','Y') upd_flg FROM dual
UNION
SELECT  'UPD_DT'  AS field_name, TO_CHAR(p_UPD_DT,'yyyy/mm/dd hh24:mi:ss')  AS field_value, DECODE(v_rec.UPD_DT, p_UPD_DT,'N','Y') upd_flg FROM dual
UNION
SELECT  'UPD_BY'  AS field_name, p_UPD_BY AS field_value, DECODE(trim(v_rec.UPD_BY), trim(p_UPD_BY),'N','Y') upd_flg FROM dual
UNION
SELECT  'CTP_CD'  AS field_name, p_CTP_CD AS field_value, DECODE(trim(v_rec.CTP_CD), trim(p_CTP_CD),'N','Y') upd_flg FROM dual
UNION
SELECT  'E_MAIL'  AS field_name, p_E_MAIL AS field_value, DECODE(trim(v_rec.E_MAIL), trim(p_E_MAIL),'N','Y') upd_flg FROM dual
UNION
SELECT  'CUSTODY_CBEST_CD'  AS field_name, p_CUSTODY_CBEST_CD AS field_value, DECODE(trim(v_rec.CUSTODY_CBEST_CD), trim(p_CUSTODY_CBEST_CD),'N','Y') upd_flg FROM dual


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
	

	IF v_error_code < 0 THEN
	      v_error_code := -8;
		  v_error_msg := 'SP_T_TEMP_INSERT '||v_table_name||' '||v_error_msg;
		  RAISE v_err;
	  END IF;

	  COMMIT;
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

END Sp_MST_LAWAN_BOND_TRX_Upd;