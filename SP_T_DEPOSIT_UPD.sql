create or replace 
PROCEDURE "SP_T_DEPOSIT_UPD" (
	P_SEARCH_SEQNO		T_DEPOSIT.SEQNO%TYPE,
	P_BANK_CD		T_DEPOSIT.BANK_CD%TYPE,
	P_BANK_TYPE		T_DEPOSIT.BANK_TYPE%TYPE,
	P_BANK_BRANCH		T_DEPOSIT.BANK_BRANCH%TYPE,
	P_FROM_DT		T_DEPOSIT.FROM_DT%TYPE,
	P_TO_DT		T_DEPOSIT.TO_DT%TYPE,
	P_AMOUNT		T_DEPOSIT.AMOUNT%TYPE,
	P_JAMINAN_LPS		T_DEPOSIT.JAMINAN_LPS%TYPE,
	P_USER_ID		T_DEPOSIT.USER_ID%TYPE,
	P_CRE_DT		T_DEPOSIT.CRE_DT%TYPE,
	P_UPD_DT		T_DEPOSIT.UPD_DT%TYPE,
	P_UPD_BY		T_DEPOSIT.UPD_BY%TYPE,
	P_REF_NUM		T_DEPOSIT.REF_NUM%TYPE,
	
	P_SEQNO		T_DEPOSIT.SEQNO%TYPE,
	P_UPD_STATUS		T_TEMP_HEADER.STATUS%TYPE,
	p_ip_address		T_TEMP_HEADER.IP_ADDRESS%TYPE,
	p_cancel_reason		T_TEMP_HEADER.CANCEL_REASON%TYPE,
	p_error_code		OUT		NUMBER,
	p_error_msg		OUT		VARCHAR2
) IS

	v_err EXCEPTION;
	v_error_code				NUMBER;
	v_error_msg					VARCHAR2(1000);
	v_table_name 				T_TEMP_HEADER.table_name%TYPE := 'T_DEPOSIT';
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
FROM T_DEPOSIT
WHERE SEQNO = p_search_SEQNO;

v_temp_detail  Types.temp_detail_rc;

v_rec T_DEPOSIT%ROWTYPE;

v_cnt INTEGER;
 i INTEGER;
 V_FIELD_CNT NUMBER;
 v_pending_cnt NUMBER;
 va CHAR(1) := '@';
BEGIN
			
             BEGIN
   	 		 SELECT ROWID INTO v_table_rowid
			 FROM T_DEPOSIT
			 WHERE SEQNO = p_search_SEQNO;
			 EXCEPTION
			 WHEN NO_DATA_FOUND THEN
			 	  v_table_rowid := NULL;
			WHEN OTHERS THEN
				     v_error_code := -2;
					 v_error_msg :=  SUBSTR('Retrieve  '|| v_table_name||' for '||p_search_SEQNO||SQLERRM,1,200);
					 RAISE v_err;
				  END;

			IF v_table_rowid IS NULL THEN
					 BEGIN
					 SELECT COUNT(1) INTO v_pending_cnt
					 FROM (SELECT MAX(SEQNO) SEQNO
							FROM (SELECT DECODE (field_name, 'SEQNO', field_value, NULL) SEQNO
								 FROM T_TEMP_DETAIL D, T_TEMP_HEADER H
								 WHERE h.table_name = v_table_name
								 AND d.update_date = h.update_date
								 AND d.update_seq = h.update_seq
								 AND d.table_name = h.table_name
								 AND d.field_name = 'SEQNO' 
								 AND h.APPROVED_status = 'E'))
					 WHERE SEQNO = p_search_SEQNO;
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
		(SELECT  'BANK_CD'  AS field_name, p_BANK_CD AS field_value, DECODE(trim(v_rec.BANK_CD), trim(p_BANK_CD),'N','Y') upd_flg FROM dual
UNION
SELECT  'BANK_TYPE'  AS field_name, p_BANK_TYPE AS field_value, DECODE(trim(v_rec.BANK_TYPE), trim(p_BANK_TYPE),'N','Y') upd_flg FROM dual
UNION
SELECT  'BANK_BRANCH'  AS field_name, p_BANK_BRANCH AS field_value, DECODE(trim(v_rec.BANK_BRANCH), trim(p_BANK_BRANCH),'N','Y') upd_flg FROM dual
UNION
SELECT  'FROM_DT'  AS field_name, TO_CHAR(p_FROM_DT,'yyyy/mm/dd hh24:mi:ss')  AS field_value, DECODE(v_rec.FROM_DT, p_FROM_DT,'N','Y') upd_flg FROM dual
UNION
SELECT  'TO_DT'  AS field_name, TO_CHAR(p_TO_DT,'yyyy/mm/dd hh24:mi:ss')  AS field_value, DECODE(v_rec.TO_DT, p_TO_DT,'N','Y') upd_flg FROM dual
UNION
SELECT  'AMOUNT'  AS field_name, TO_CHAR(p_AMOUNT)  AS field_value, DECODE(v_rec.AMOUNT, p_AMOUNT,'N','Y') upd_flg FROM dual
UNION
SELECT  'JAMINAN_LPS'  AS field_name, TO_CHAR(p_JAMINAN_LPS)  AS field_value, DECODE(v_rec.JAMINAN_LPS, p_JAMINAN_LPS,'N','Y') upd_flg FROM dual
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
SELECT  'REF_NUM'  AS field_name, p_REF_NUM AS field_value, DECODE(trim(v_rec.REF_NUM), trim(p_REF_NUM),'N','Y') upd_flg FROM dual
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

END Sp_T_DEPOSIT_Upd;
