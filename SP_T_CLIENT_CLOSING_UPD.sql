create or replace PROCEDURE           "SP_T_CLIENT_CLOSING_UPD" (
       p_search_CLIENT_CD		MST_CLIENT.CLIENT_CD%TYPE,
	   P_CLIENT_CD		T_CLIENT_CLOSING.CLIENT_CD%TYPE,
		P_CLIENT_NAME		T_CLIENT_CLOSING.CLIENT_NAME%TYPE,
		P_CRE_DT		T_CLIENT_CLOSING.CRE_DT%TYPE,
		P_UPD_DT		T_CLIENT_CLOSING.UPD_DT%TYPE,
		P_USER_ID		T_CLIENT_CLOSING.USER_ID%TYPE,
		P_NEW_STAT		T_CLIENT_CLOSING.NEW_STAT%TYPE,
		P_FROM_STAT		T_CLIENT_CLOSING.FROM_STAT%TYPE,
		P_UPD_BY		T_CLIENT_CLOSING.UPD_BY%TYPE,
		 P_UPD_STATUS			T_MANY_DETAIL.UPD_STATUS%TYPE,
	   p_ip_address			T_MANY_HEADER.IP_ADDRESS%TYPE,
	   p_cancel_reason			T_MANY_HEADER.CANCEL_REASON%TYPE,
	   p_update_date			T_MANY_HEADER.UPDATE_DATE%TYPE,
	   p_update_seq			T_MANY_HEADER.UPDATE_SEQ%TYPE,
	   p_record_seq			T_MANY_DETAIL.RECORD_SEQ%TYPE,
	   p_error_code					OUT			NUMBER,
	   p_error_msg					OUT			VARCHAR2
) IS

  v_err EXCEPTION;
v_error_code							NUMBER;
v_error_msg							VARCHAR2(200);
v_table_name  T_MANY_DETAIL.table_name%TYPE;
v_status               T_MANY_DETAIL.upd_status%TYPE;
v_table_rowid				   T_MANY_DETAIL.table_rowid%TYPE;

CURSOR csr_MANY_detail IS
SELECT      column_id, column_name AS field_name,
                       DECODE(data_type,'VARCHAR2','S','CHAR','S','NUMBER','N','DATE','D','X') AS field_type
FROM all_tab_columns
WHERE table_name =v_table_name
AND OWNER = 'IPNEXTG';

CURSOR csr_table IS
SELECT *
FROM MST_CLIENT
WHERE user_id = p_search_CLIENT_CD;

  v_MANY_detail  Types.MANY_detail_rc;
  
 i INTEGER;
 V_FIELD_CNT NUMBER;
 v_pending_cnt NUMBER;
 va CHAR(1) := '@';

 v_bal_qty     T_STKHAND.bal_Qty%TYPE;
  v_on_hand   T_STKHAND.bal_Qty%TYPE;
  v_bal_arap  T_ACCOUNT_LEDGER.curr_val%TYPE;
  v_bal_dt    DATE;
  v_outstanding NUMBER;
   v_margin  NUMBER;
	v_regular  NUMBER;
 v_sibling NUMBER;
 v_fund_bal  T_ACCOUNT_LEDGER.curr_val%TYPE;
 v_margin_client_cd  VARCHAR2(8);
 v_tplus_client_cd VARCHAR2(8);
 v_sid MST_CLIENT.SID%TYPE;
 
BEGIN
  IF P_UPD_STATUS = 'X' THEN
    v_table_name := 'MST_GL_ACCOUNT';
  ELSIF P_UPD_STATUS = 'Y' THEN
    v_table_name := 'MST_CLIENT_FLACCT';
  ELSIF P_UPD_STATUS = 'Z' THEN
    v_table_name := 'MST_CLIENT';
  ELSE
    v_table_name := 'T_CLIENT_CLOSING';
  END IF;
   
				BEGIN
				SELECT NVL(F_Fund_Bal(p_search_CLIENT_CD, TRUNC(SYSDATE)),0) INTO v_fund_bal FROM dual;
				EXCEPTION
				WHEN NO_DATA_FOUND THEN
					         v_fund_bal := 0;
				WHEN OTHERS THEN
					v_error_code := -12;
					v_error_msg :=  SUBSTR('F_FUND_BAL for '||p_search_CLIENT_CD||SQLERRM,1,200);
							 RAISE v_err;
				END;

				IF v_fund_bal > 0 THEN
				   			 v_error_code := -2008;
				   			 v_error_msg := 'Balance Rekening Dana still exists ('||v_fund_bal||') , not allowed to close !';
				 			 RAISE v_err;
				END IF;
        
        BEGIN
				SELECT NVL(F_Fund_KSEI(p_search_CLIENT_CD, TRUNC(SYSDATE)),0) INTO v_fund_bal FROM dual;
				EXCEPTION
				WHEN NO_DATA_FOUND THEN
					         v_fund_bal := 0;
				WHEN OTHERS THEN
					v_error_code := -13;
					v_error_msg :=  SUBSTR('F_FUND_KSEI for '||p_search_CLIENT_CD||SQLERRM,1,200);
							 RAISE v_err;
				END;

				IF v_fund_bal <> 0 THEN
				   			 v_error_code := -2009;
				   			 v_error_msg := 'Balance Dana KSEI still exists ('||v_fund_bal||') , not allowed to close !';
				 			 RAISE v_err;
				END IF;
	
	IF P_UPD_STATUS = 'I' THEN
				
	--[INDRA] 08/11/2017 cek juka masih ada belum diapprove
	BEGIN
			SELECT COUNT(1) INTO v_pending_cnt
			FROM T_MANY_DETAIL D, T_MANY_HEADER H
			WHERE d.table_name = v_table_name
			AND d.update_date = h.update_date
			AND d.update_seq = h.update_seq
			AND d.field_name = 'CLIENT_CD'
			AND d.field_value = p_search_CLIENT_CD
			AND h.APPROVED_status = 'E';
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				v_pending_cnt := 0;
			WHEN OTHERS THEN
				v_error_code := -4;
				v_error_msg :=  SUBSTR('Retrieve T_MANY_HEADER for '|| v_table_name||SQLERRM,1,200);
				RAISE v_err;
		END;


	IF  v_pending_cnt > 0 THEN
		v_error_code := -6;
		v_error_msg := 'Masih ada yang belum di-approve';
		RAISE v_err;
	END IF;
  
		--end cek inbox



		OPEN v_MANY_DETAIL FOR
      SELECT p_update_date AS update_date, p_update_seq AS update_seq, table_name, p_record_seq AS record_seq, NULL AS table_rowid, a.field_name,  field_type, b.field_value, p_upd_status AS status,  b.upd_flg
      FROM(
        SELECT  v_table_name AS table_name, column_name AS field_name, DECODE(data_type,'VARCHAR2','S','CHAR','S','NUMBER','N','DATE','D','X') AS field_type
        FROM all_tab_columns
        WHERE table_name = v_table_name
        AND OWNER = 'IPNEXTG') a,
		(  SELECT  'CLIENT_CD'  AS field_name, p_CLIENT_CD AS field_value, 'Y' upd_flg FROM dual
			UNION
			SELECT  'CLIENT_NAME'  AS field_name, p_CLIENT_NAME AS field_value, 'Y' upd_flg FROM dual
			UNION
			SELECT  'NEW_STAT'  AS field_name, p_NEW_STAT AS field_value, 'Y' upd_flg FROM dual
			UNION
			SELECT  'FROM_STAT'  AS field_name, p_FROM_STAT AS field_value, 'Y' upd_flg FROM dual
			UNION
			SELECT  'CRE_DT'  AS field_name, TO_CHAR(SYSDATE,'yyyy/mm/dd hh24:mi:ss')  AS field_value, 'Y' upd_flg FROM dual
      UNION
      SELECT  'USER_ID'  AS field_name, p_USER_ID AS field_value, 'Y' upd_flg FROM dual
		 ) b
		WHERE a.field_name = b.field_name;

		 v_status := 'I';
		 
	ELSIF P_UPD_STATUS = 'X' THEN --GL Account
		
		BEGIN
			SELECT ROWID INTO v_table_rowid FROM MST_GL_ACCOUNT WHERE trim(sl_a) = trim(P_CLIENT_CD) AND trim(gl_a) = trim(P_CLIENT_NAME);
		EXCEPTION
			WHEN OTHERS THEN
			v_error_code := -13;
			v_error_msg :=  SUBSTR('Retrieve GL_ACCOUNT for '||P_CLIENT_NAME ||SQLERRM,1,200);
			RAISE v_err;
		END;
		
	--[INDRA] 08/11/2017 cek juka masih ada belum diapprove
	BEGIN
			SELECT COUNT(1) INTO v_pending_cnt
			FROM T_MANY_DETAIL D, T_MANY_HEADER H
			WHERE d.table_name = v_table_name
      		AND H.UPDATE_DATE = D.UPDATE_DATE
			AND h.update_seq = d.update_seq
			AND d.table_rowid = v_table_rowid
			AND h.APPROVED_status <> 'A'
			AND h.APPROVED_status <> 'R';
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				v_pending_cnt := 0;
			WHEN OTHERS THEN
				v_error_code := -7;
				v_error_msg :=  SUBSTR('Retrieve T_MANY_HEADER for '|| v_table_name||SQLERRM,1,200);
				RAISE v_err;
		END;

		
	IF  v_pending_cnt > 0 THEN
		v_error_code := -8;
		v_error_msg := 'Masih ada yang belum di-approve';
		RAISE v_err;
	END IF;
  
		--end cek inbox


		OPEN v_MANY_DETAIL FOR
      SELECT p_update_date AS update_date, p_update_seq AS update_seq, table_name, p_record_seq AS record_seq, v_table_rowid AS table_rowid, a.field_name,  field_type, b.field_value, 'U' AS status,  b.upd_flg
      FROM(
        SELECT  v_table_name AS table_name, column_name AS field_name, DECODE(data_type,'VARCHAR2','S','CHAR','S','NUMBER','N','DATE','D','X') AS field_type
        FROM all_tab_columns
        WHERE table_name = v_table_name
        AND OWNER = 'IPNEXTG') a,
		(  SELECT  'SL_A'  AS field_name, p_CLIENT_CD AS field_value, 'N' upd_flg FROM dual
			UNION
			SELECT  'GL_A'  AS field_name, p_CLIENT_NAME AS field_value, 'N' upd_flg FROM dual
			UNION
			SELECT  'ACCT_STAT'  AS field_name, 'C' AS field_value, 'Y' upd_flg FROM dual
			UNION
      SELECT  'UPD_DT'  AS field_name, TO_CHAR(SYSDATE,'yyyy/mm/dd hh24:mi:ss')  AS field_value, 'Y' upd_flg FROM dual
      UNION
      SELECT  'UPD_BY'  AS field_name, p_USER_ID AS field_value, 'Y' upd_flg FROM dual
		 ) b
		WHERE a.field_name = b.field_name;

		 v_status := 'U';
     
  ELSIF P_UPD_STATUS = 'Y' THEN -- Client Flacct
	
		BEGIN
			SELECT ROWID INTO v_table_rowid FROM MST_CLIENT_FLACCT WHERE client_cd = P_CLIENT_CD AND trim(bank_acct_num) = trim(P_CLIENT_NAME);
		EXCEPTION
			WHEN OTHERS THEN
			v_error_code := -14;
			v_error_msg :=  SUBSTR('Retrieve MST_CLIENT_FLACCT for '||p_search_CLIENT_CD ||SQLERRM,1,200);
			RAISE v_err;
		END;
	

--[INDRA] 08/11/2017 cek juka masih ada belum diapprove
	BEGIN
			SELECT COUNT(1) INTO v_pending_cnt
			FROM T_MANY_DETAIL D, T_MANY_HEADER H
			WHERE d.table_name = v_table_name
      		AND H.UPDATE_DATE = D.UPDATE_DATE
			AND h.update_seq = d.update_seq
			AND d.table_rowid = v_table_rowid
			AND h.APPROVED_status <> 'A'
			AND h.APPROVED_status <> 'R';
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				v_pending_cnt := 0;
			WHEN OTHERS THEN
				v_error_code := -9;
				v_error_msg :=  SUBSTR('Retrieve T_MANY_HEADER for '|| v_table_name||SQLERRM,1,200);
				RAISE v_err;
		END;

		
	IF  v_pending_cnt > 0 THEN
		v_error_code := -10;
		v_error_msg := 'Masih ada yang belum di-approve';
		RAISE v_err;
	END IF;
  
		--end cek inbox

		OPEN v_MANY_DETAIL FOR
      SELECT p_update_date AS update_date, p_update_seq AS update_seq, table_name, p_record_seq AS record_seq, v_table_rowid AS table_rowid, a.field_name,  field_type, b.field_value, 'U' AS status,  b.upd_flg
      FROM(
        SELECT  v_table_name AS table_name, column_name AS field_name, DECODE(data_type,'VARCHAR2','S','CHAR','S','NUMBER','N','DATE','D','X') AS field_type
        FROM all_tab_columns
        WHERE table_name = v_table_name
        AND OWNER = 'IPNEXTG') a,
		(  SELECT  'CLIENT_CD'  AS field_name, p_CLIENT_CD AS field_value, 'N' upd_flg FROM dual
			UNION
      SELECT  'BANK_ACCT_NUM'  AS field_name, p_CLIENT_NAME AS field_value, 'N' upd_flg FROM dual
			UNION
			SELECT  'ACCT_STAT'  AS field_name, 'C' AS field_value, 'Y' upd_flg FROM dual
			UNION
      --SELECT  'TO_DT'  As Field_Name, To_Char(trunc(SYSDATE),'yyyy/mm/dd')  As Field_Value, 'Y' Upd_Flg From Dual
      --UNION
      SELECT  'UPD_DT'  AS field_name, TO_CHAR(SYSDATE,'yyyy/mm/dd hh24:mi:ss')  AS field_value, 'Y' upd_flg FROM dual
      UNION
      SELECT  'UPD_BY'  AS field_name, p_USER_ID AS field_value, 'Y' upd_flg FROM dual
		 ) b
		WHERE a.field_name = b.field_name;

		 v_status := 'U';
	
	ELSE -- Master Client
	
		BEGIN
			SELECT ROWID, SID INTO v_table_rowid, v_sid FROM MST_CLIENT WHERE client_cd = P_CLIENT_CD;
		EXCEPTION
			WHEN OTHERS THEN
			v_error_code := -15;
			v_error_msg :=  SUBSTR('Retrieve MST_CLIENT for '||p_search_CLIENT_CD||SQLERRM,1,200);
			RAISE v_err;
		END;


		--[INDRA] 08/11/2017 cek juka masih ada belum diapprove
	BEGIN
			SELECT COUNT(1) INTO v_pending_cnt
			FROM T_MANY_DETAIL D, T_MANY_HEADER H
			WHERE d.table_name = v_table_name
      		AND H.UPDATE_DATE = D.UPDATE_DATE
			AND h.update_seq = d.update_seq
			AND d.table_rowid = v_table_rowid
			AND h.APPROVED_status <> 'A'
			AND h.APPROVED_status <> 'R';
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				v_pending_cnt := 0;
			WHEN OTHERS THEN
				v_error_code := -11;
				v_error_msg :=  SUBSTR('Retrieve T_MANY_HEADER for '|| v_table_name||SQLERRM,1,200);
				RAISE v_err;
		END;

		
	IF  v_pending_cnt > 0 THEN
		v_error_code := -12;
		v_error_msg := 'Masih ada yang belum di-approve';
		RAISE v_err;
	END IF;
	
		OPEN v_MANY_DETAIL FOR
      SELECT p_update_date AS update_date, p_update_seq AS update_seq, table_name, p_record_seq AS record_seq, v_table_rowid AS table_rowid, a.field_name,  field_type, b.field_value, 'U' AS status,  b.upd_flg
      FROM(
        SELECT  v_table_name AS table_name, column_name AS field_name, DECODE(data_type,'VARCHAR2','S','CHAR','S','NUMBER','N','DATE','D','X') AS field_type
        FROM all_tab_columns
        WHERE table_name = v_table_name
        AND OWNER = 'IPNEXTG') a,
		(  SELECT  'CLIENT_CD'  AS field_name, p_CLIENT_CD AS field_value, 'N' upd_flg FROM dual
			UNION
			SELECT  'SUSP_STAT'  AS field_name, 'C' AS field_value, 'Y' upd_flg FROM dual
			UNION
      SELECT  'SID'  AS field_name, v_sid AS field_value, 'N' upd_flg FROM dual
			UNION
      SELECT  'CLOSED_DATE'  AS field_name, TO_CHAR(SYSDATE,'yyyy/mm/dd') AS field_value, 'Y' upd_flg FROM dual
			UNION
      SELECT  'UPD_DT'  AS field_name, TO_CHAR(SYSDATE,'yyyy/mm/dd hh24:mi:ss')  AS field_value, 'Y' upd_flg FROM dual
      UNION
      SELECT  'UPD_BY'  AS field_name, p_USER_ID AS field_value, 'Y' upd_flg FROM dual
		 ) b
		WHERE a.field_name = b.field_name;

		 v_status := 'U';
	
	END IF;
		 
 BEGIN
   Sp_T_Many_Detail_Insert(p_update_date,   p_update_seq,   v_status, v_table_name, p_record_seq , v_table_rowid, v_MANY_DETAIL, v_error_code, v_error_msg);
EXCEPTION
WHEN OTHERS THEN
		 v_error_code := -13;
		  v_error_msg := SUBSTR('SP_T_MANY_INSERT '||v_table_name||SQLERRM,1,200);
		  RAISE v_err;
END;

	CLOSE v_MANY_detail;

	IF v_error_code < 0 THEN
	      v_error_code := -14;
		  v_error_msg := 'SP_T_MANY_INSERT '||v_table_name||' '||v_error_msg;
		  RAISE v_err;
	  END IF;

     p_error_code := 1;
	 p_error_msg := '';

   EXCEPTION
     WHEN NO_DATA_FOUND THEN
       NULL;
	   WHEN v_err THEN
	   ROLLBACK;
	   p_error_code := v_error_code;
	  p_error_msg := v_error_msg;
     WHEN OTHERS THEN
       -- Consider logging the error and then re-raise
       ROLLBACK;
	   p_error_code := -1;
	   p_error_msg := SUBSTR(SQLERRM(SQLCODE),1,200);
       RAISE;

END Sp_T_Client_Closing_Upd;