create or replace 
PROCEDURE           SP_MST_Bond_UPD (
       p_search_Bond_CD 			MST_BOND.BOND_CD%TYPE,
			P_BOND_CD		MST_BOND.BOND_CD%TYPE,
P_BOND_DESC		MST_BOND.BOND_DESC%TYPE,
P_INT_TYPE		MST_BOND.INT_TYPE%TYPE,
P_INTEREST		MST_BOND.INTEREST%TYPE,
P_FEE_IJARAH		MST_BOND.FEE_IJARAH%TYPE,
P_NISBAH		MST_BOND.NISBAH%TYPE,
P_ISSUE_DATE		MST_BOND.ISSUE_DATE%TYPE,
P_LISTING_DATE		MST_BOND.LISTING_DATE%TYPE,
P_MATURITY_DATE		MST_BOND.MATURITY_DATE%TYPE,
P_ISIN_CODE		MST_BOND.ISIN_CODE%TYPE,
P_ISSUER		MST_BOND.ISSUER%TYPE,
P_SEC_SECTOR		MST_BOND.SEC_SECTOR%TYPE,
P_BOND_GROUP_CD		MST_BOND.BOND_GROUP_CD%TYPE,
P_PRODUCT_TYPE		MST_BOND.PRODUCT_TYPE%TYPE,
P_SHORT_DESC		MST_BOND.SHORT_DESC%TYPE,
P_INT_FREQ		MST_BOND.INT_FREQ%TYPE,
P_DAY_COUNT_BASIS		MST_BOND.DAY_COUNT_BASIS%TYPE,
P_GL_ACCT_CD		MST_BOND.GL_ACCT_CD%TYPE,
P_SL_ACCT_CD		MST_BOND.SL_ACCT_CD%TYPE,
P_CRE_DT		MST_BOND.CRE_DT%TYPE,
P_USER_ID		MST_BOND.USER_ID%TYPE,
P_UPD_DT		MST_BOND.UPD_DT%TYPE,
P_UPD_BY		MST_BOND.UPD_BY%TYPE,


			P_UPD_STATUS					T_TEMP_HEADER.STATUS%TYPE,
	   p_ip_address								T_TEMP_HEADER.IP_ADDRESS%TYPE,
	   p_cancel_reason						T_TEMP_HEADER.CANCEL_REASON%TYPE,
	   p_error_code					OUT			NUMBER,
	   p_error_msg					OUT			VARCHAR2
) IS



  v_err EXCEPTION;
v_error_code							NUMBER;
v_error_msg							VARCHAR2(200);
v_table_name T_TEMP_HEADER.table_name%TYPE := 'MST_BOND';
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
FROM MST_BOND
WHERE BOND_CD = p_search_BOND_CD;

  v_temp_detail  Types.temp_detail_rc;

v_rec MST_BOND%ROWTYPE;




v_cnt INTEGER;
 i INTEGER;
 V_FIELD_CNT NUMBER;
 v_pending_cnt NUMBER;
 va CHAR(1) := '@';
BEGIN

			IF 	  P_UPD_STATUS = 'I' AND p_search_bond_cd <> p_bond_cd THEN
			       v_error_code := -2001;
				   v_error_msg  := 'jika INSERT, p_search_bond_cd harus sama dengan p_bond_cd';
				   RAISE v_err;
			END IF;
			
             BEGIN
   	 		 SELECT ROWID INTO v_table_rowid
			 FROM MST_BOND
			 WHERE TRIM(BOND_CD) = TRIM(p_search_BOND_CD);
			 EXCEPTION
			 WHEN NO_DATA_FOUND THEN
			 	  v_table_rowid := NULL;
			WHEN OTHERS THEN
				     v_error_code := -2;
					 v_error_msg :=  SUBSTR('Retrieve  '|| v_table_name||' for '||p_search_BOND_CD||SQLERRM,1,200);
					 RAISE v_err;
				  END;

			IF 	  P_UPD_STATUS = 'I' AND v_table_rowid IS NOT NULL THEN
			       v_error_code := -2001;
				   v_error_msg  := 'DUPLICATED BOND CODE';
				   RAISE v_err;
			END IF;
			
			IF 	  P_UPD_STATUS = 'U'   AND p_search_BOND_CD <> p_BOND_CD THEN
				 BEGIN
	   	 		 SELECT COUNT(1) INTO v_cnt
				 FROM MST_BOND
				 WHERE TRIM(BOND_CD) = TRIM(p_BOND_CD);
				 EXCEPTION
				 WHEN NO_DATA_FOUND THEN
				 	  v_cnt := 0;
				WHEN OTHERS THEN
					     v_error_code := -3;
						 v_error_msg :=  SUBSTR('Retrieve  '|| v_table_name||' for '||p_BOND_CD||SQLERRM,1,200);
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
					 AND d.field_name = 'BOND_CD'
					 AND   d.field_value = p_search_BOND_CD
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
					SELECT  'BOND_CD'  AS field_name, p_BOND_CD AS field_value, DECODE(trim(v_rec.BOND_CD), trim(p_BOND_CD),'N','Y') upd_flg FROM dual
UNION
SELECT  'BOND_DESC'  AS field_name, p_BOND_DESC AS field_value, DECODE(trim(v_rec.BOND_DESC), trim(p_BOND_DESC),'N','Y') upd_flg FROM dual
UNION
SELECT  'INT_TYPE'  AS field_name, p_INT_TYPE AS field_value, DECODE(trim(v_rec.INT_TYPE), trim(p_INT_TYPE),'N','Y') upd_flg FROM dual
UNION
SELECT  'INTEREST'  AS field_name, TO_CHAR(p_INTEREST)  AS field_value, DECODE(v_rec.INTEREST, p_INTEREST,'N','Y') upd_flg FROM dual
UNION
SELECT  'FEE_IJARAH'  AS field_name, TO_CHAR(p_FEE_IJARAH)  AS field_value, DECODE(v_rec.FEE_IJARAH, p_FEE_IJARAH,'N','Y') upd_flg FROM dual
UNION
SELECT  'NISBAH'  AS field_name, TO_CHAR(p_NISBAH)  AS field_value, DECODE(v_rec.NISBAH, p_NISBAH,'N','Y') upd_flg FROM dual
UNION
SELECT  'ISSUE_DATE'  AS field_name, TO_CHAR(p_ISSUE_DATE,'yyyy/mm/dd hh24:mi:ss')  AS field_value, DECODE(v_rec.ISSUE_DATE, p_ISSUE_DATE,'N','Y') upd_flg FROM dual
UNION
SELECT  'LISTING_DATE'  AS field_name, TO_CHAR(p_LISTING_DATE,'yyyy/mm/dd hh24:mi:ss')  AS field_value, DECODE(v_rec.LISTING_DATE, p_LISTING_DATE,'N','Y') upd_flg FROM dual
UNION
SELECT  'MATURITY_DATE'  AS field_name, TO_CHAR(p_MATURITY_DATE,'yyyy/mm/dd hh24:mi:ss')  AS field_value, DECODE(v_rec.MATURITY_DATE, p_MATURITY_DATE,'N','Y') upd_flg FROM dual
UNION
SELECT  'ISIN_CODE'  AS field_name, p_ISIN_CODE AS field_value, DECODE(trim(v_rec.ISIN_CODE), trim(p_ISIN_CODE),'N','Y') upd_flg FROM dual
UNION
SELECT  'ISSUER'  AS field_name, p_ISSUER AS field_value, DECODE(trim(v_rec.ISSUER), trim(p_ISSUER),'N','Y') upd_flg FROM dual
UNION
SELECT  'SEC_SECTOR'  AS field_name, p_SEC_SECTOR AS field_value, DECODE(trim(v_rec.SEC_SECTOR), trim(p_SEC_SECTOR),'N','Y') upd_flg FROM dual
UNION
SELECT  'BOND_GROUP_CD'  AS field_name, p_BOND_GROUP_CD AS field_value, DECODE(trim(v_rec.BOND_GROUP_CD), trim(p_BOND_GROUP_CD),'N','Y') upd_flg FROM dual
UNION
SELECT  'PRODUCT_TYPE'  AS field_name, p_PRODUCT_TYPE AS field_value, DECODE(trim(v_rec.PRODUCT_TYPE), trim(p_PRODUCT_TYPE),'N','Y') upd_flg FROM dual
UNION
SELECT  'SHORT_DESC'  AS field_name, p_SHORT_DESC AS field_value, DECODE(trim(v_rec.SHORT_DESC), trim(p_SHORT_DESC),'N','Y') upd_flg FROM dual
UNION
SELECT  'INT_FREQ'  AS field_name, p_INT_FREQ AS field_value, DECODE(trim(v_rec.INT_FREQ), trim(p_INT_FREQ),'N','Y') upd_flg FROM dual
UNION
SELECT  'DAY_COUNT_BASIS'  AS field_name, p_DAY_COUNT_BASIS AS field_value, DECODE(trim(v_rec.DAY_COUNT_BASIS), trim(p_DAY_COUNT_BASIS),'N','Y') upd_flg FROM dual
UNION
SELECT  'GL_ACCT_CD'  AS field_name, p_GL_ACCT_CD AS field_value, DECODE(trim(v_rec.GL_ACCT_CD), trim(p_GL_ACCT_CD),'N','Y') upd_flg FROM dual
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

END Sp_Mst_Bond_Upd;