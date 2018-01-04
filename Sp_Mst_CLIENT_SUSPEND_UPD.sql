create or replace 
PROCEDURE Sp_Mst_CLIENT_SUSPEND_UPD (
				p_search_CLIENT_CD 		MST_CLIENT.CLIENT_CD%TYPE,
			P_CLIENT_CD		MST_CLIENT.CLIENT_CD%TYPE,

			P_CIF_NUMBER		MST_CLIENT.CIF_NUMBER%TYPE,

			P_CLIENT_NAME		MST_CLIENT.CLIENT_NAME%TYPE,

			P_CLIENT_NAME_ABBR		MST_CLIENT.CLIENT_NAME_ABBR%TYPE,

			P_CLIENT_TYPE_1		MST_CLIENT.CLIENT_TYPE_1%TYPE,

			P_CLIENT_TYPE_2		MST_CLIENT.CLIENT_TYPE_2%TYPE,

			P_CLIENT_TYPE_3		MST_CLIENT.CLIENT_TYPE_3%TYPE,

			P_CLIENT_TITLE		MST_CLIENT.CLIENT_TITLE%TYPE,

			P_CLIENT_BIRTH_DT		MST_CLIENT.CLIENT_BIRTH_DT%TYPE,

			P_RELIGION		MST_CLIENT.RELIGION%TYPE,

			P_ACCT_OPEN_DT		MST_CLIENT.ACCT_OPEN_DT%TYPE,

			P_CLIENT_RACE		MST_CLIENT.CLIENT_RACE%TYPE,

			P_CLIENT_IC_NUM		MST_CLIENT.CLIENT_IC_NUM%TYPE,

			P_CHQ_PAYEE_NAME		MST_CLIENT.CHQ_PAYEE_NAME%TYPE,

			P_SETT_OFF_CD		MST_CLIENT.SETT_OFF_CD%TYPE,

			P_STK_EXCH		MST_CLIENT.STK_EXCH%TYPE,

		P_IC_TYPE		MST_CLIENT.IC_TYPE%TYPE,

			P_CURR_CD		MST_CLIENT.CURR_CD%TYPE,

			P_DEF_CURR_CD		MST_CLIENT.DEF_CURR_CD%TYPE,

			P_REM_CD		MST_CLIENT.REM_CD%TYPE,

			P_BANK_CD		MST_CLIENT.BANK_CD%TYPE,

			P_BANK_BRCH_CD		MST_CLIENT.BANK_BRCH_CD%TYPE,

			P_DEF_CONTRA_FLG		MST_CLIENT.DEF_CONTRA_FLG%TYPE,

			P_CUST_CLIENT_FLG		MST_CLIENT.CUST_CLIENT_FLG%TYPE,

			P_CR_LIM		MST_CLIENT.CR_LIM%TYPE,

			P_SUSP_STAT		MST_CLIENT.SUSP_STAT%TYPE,

			P_DEF_ADDR_1		MST_CLIENT.DEF_ADDR_1%TYPE,

			P_DEF_ADDR_2		MST_CLIENT.DEF_ADDR_2%TYPE,

			P_DEF_ADDR_3		MST_CLIENT.DEF_ADDR_3%TYPE,

			P_POST_CD		MST_CLIENT.POST_CD%TYPE,

			P_CONTACT_PERS		MST_CLIENT.CONTACT_PERS%TYPE,

			P_PHONE_NUM		MST_CLIENT.PHONE_NUM%TYPE,

			P_HP_NUM		MST_CLIENT.HP_NUM%TYPE,

			P_FAX_NUM		MST_CLIENT.FAX_NUM%TYPE,

			P_E_MAIL1		MST_CLIENT.E_MAIL1%TYPE,

			P_HAND_PHONE1		MST_CLIENT.HAND_PHONE1%TYPE,

			P_PHONE2_1		MST_CLIENT.PHONE2_1%TYPE,

			P_REGN_CD		MST_CLIENT.REGN_CD%TYPE,

			P_DESP_PREF		MST_CLIENT.DESP_PREF%TYPE,

			P_STOP_PAY		MST_CLIENT.STOP_PAY%TYPE,

			P_OLD_IC_NUM		MST_CLIENT.OLD_IC_NUM%TYPE,

			P_PRINT_FLG		MST_CLIENT.PRINT_FLG%TYPE,

			P_REM_OWN_TRADE		MST_CLIENT.REM_OWN_TRADE%TYPE,

			P_AVG_FLG		MST_CLIENT.AVG_FLG%TYPE,

			P_CLIENT_NAME_EXT		MST_CLIENT.CLIENT_NAME_EXT%TYPE,

			P_BRANCH_CODE		MST_CLIENT.BRANCH_CODE%TYPE,

			P_PPH_APPL_FLG		MST_CLIENT.PPH_APPL_FLG%TYPE,

			P_LEVY_APPL_FLG		MST_CLIENT.LEVY_APPL_FLG%TYPE,

			P_INT_ON_PAYABLE		MST_CLIENT.INT_ON_PAYABLE%TYPE,

			P_INT_ON_RECEIVABLE		MST_CLIENT.INT_ON_RECEIVABLE%TYPE,

			P_INT_ON_ADV_RECD		MST_CLIENT.INT_ON_ADV_RECD%TYPE,

			P_GRACE_PERIOD		MST_CLIENT.GRACE_PERIOD%TYPE,

			P_INT_REC_DAYS		MST_CLIENT.INT_REC_DAYS%TYPE,

			P_INT_PAY_DAYS		MST_CLIENT.INT_PAY_DAYS%TYPE,

			P_TAX_ON_INTEREST		MST_CLIENT.TAX_ON_INTEREST%TYPE,

			P_AGREEMENT_NO		MST_CLIENT.AGREEMENT_NO%TYPE,

			P_NPWP_NO		MST_CLIENT.NPWP_NO%TYPE,

			P_REBATE		MST_CLIENT.REBATE%TYPE,

			P_REBATE_BASIS		MST_CLIENT.REBATE_BASIS%TYPE,

			P_COMMISSION_PER		MST_CLIENT.COMMISSION_PER%TYPE,

			P_ACOPEN_FEE_FLG		MST_CLIENT.ACOPEN_FEE_FLG%TYPE,

			P_NEXT_ROLLOVER_DT		MST_CLIENT.NEXT_ROLLOVER_DT%TYPE,

			P_AC_EXPIRY_DT		MST_CLIENT.AC_EXPIRY_DT%TYPE,

			P_COMMIT_FEE_DT		MST_CLIENT.COMMIT_FEE_DT%TYPE,

			P_ROLL_FEE_DT		MST_CLIENT.ROLL_FEE_DT%TYPE,

			P_RECOV_CHARGE_FLG		MST_CLIENT.RECOV_CHARGE_FLG%TYPE,

			P_UPD_DT		MST_CLIENT.UPD_DT%TYPE,

			P_CRE_DT		MST_CLIENT.CRE_DT%TYPE,

			P_USER_ID		MST_CLIENT.USER_ID%TYPE,

			P_REBATE_TOTTRADE		MST_CLIENT.REBATE_TOTTRADE%TYPE,

			P_AMT_INT_FLG		MST_CLIENT.AMT_INT_FLG%TYPE,

			P_INTERNET_CLIENT		MST_CLIENT.INTERNET_CLIENT%TYPE,

			P_CONTRA_DAYS		MST_CLIENT.CONTRA_DAYS%TYPE,

			P_VAT_APPL_FLG		MST_CLIENT.VAT_APPL_FLG%TYPE,

			P_INT_ACCUMULATED		MST_CLIENT.INT_ACCUMULATED%TYPE,

			P_BANK_ACCT_NUM		MST_CLIENT.BANK_ACCT_NUM%TYPE,

			P_CUSTODIAN_CD		MST_CLIENT.CUSTODIAN_CD%TYPE,

			P_OLT		MST_CLIENT.OLT%TYPE,

			P_SID		MST_CLIENT.SID%TYPE,

			P_BIZ_TYPE		MST_CLIENT.BIZ_TYPE%TYPE,

			P_CIFS		MST_CLIENT.CIFS%TYPE,

			P_UPD_BY		MST_CLIENT.UPD_BY%TYPE,

			P_REFERENCE_NAME		MST_CLIENT.REFERENCE_NAME%TYPE,

			P_TRADE_CONF_SEND_TO		MST_CLIENT.TRADE_CONF_SEND_TO%TYPE,

			P_TRADE_CONF_SEND_FREQ		MST_CLIENT.TRADE_CONF_SEND_FREQ%TYPE,

			P_DEF_CITY		MST_CLIENT.DEF_CITY%TYPE,

			P_COMMISSION_PER_SELL		MST_CLIENT.COMMISSION_PER_SELL%TYPE,

			P_COMMISSION_PER_BUY		MST_CLIENT.COMMISSION_PER_BUY%TYPE,

			P_RECOMMENDED_BY_CD		MST_CLIENT.RECOMMENDED_BY_CD%TYPE,

			P_RECOMMENDED_BY_OTHER		MST_CLIENT.RECOMMENDED_BY_OTHER%TYPE,

			P_TRANSACTION_LIMIT		MST_CLIENT.TRANSACTION_LIMIT%TYPE,

			P_INIT_DEPOSIT_AMOUNT		MST_CLIENT.INIT_DEPOSIT_AMOUNT%TYPE,

			P_INIT_DEPOSIT_EFEK		MST_CLIENT.INIT_DEPOSIT_EFEK%TYPE,

			P_INIT_DEPOSIT_EFEK_PRICE		MST_CLIENT.INIT_DEPOSIT_EFEK_PRICE%TYPE,

			P_INIT_DEPOSIT_EFEK_DATE		MST_CLIENT.INIT_DEPOSIT_EFEK_DATE%TYPE,

			P_ID_COPY_FLG		MST_CLIENT.ID_COPY_FLG%TYPE,

			P_NPWP_COPY_FLG		MST_CLIENT.NPWP_COPY_FLG%TYPE,

			P_KORAN_COPY_FLG		MST_CLIENT.KORAN_COPY_FLG%TYPE,

			P_COPY_OTHER_FLG		MST_CLIENT.COPY_OTHER_FLG%TYPE,

			P_COPY_OTHER		MST_CLIENT.COPY_OTHER%TYPE,

			P_CLIENT_CLASS		MST_CLIENT.CLIENT_CLASS%TYPE,

			P_SUSP_TRX		MST_CLIENT.SUSP_TRX%TYPE,
			P_UPD_STATUS					T_TEMP_HEADER.STATUS%TYPE,
	   p_ip_address								T_TEMP_HEADER.IP_ADDRESS%TYPE,
	   p_cancel_reason						T_TEMP_HEADER.CANCEL_REASON%TYPE,
	   p_error_code					OUT			NUMBER,
	   p_error_msg					OUT			VARCHAR2
) IS



  v_err EXCEPTION;
v_error_code							NUMBER;
v_error_msg							VARCHAR2(200);
v_table_name T_TEMP_HEADER.table_name%TYPE := 'MST_CLIENT';
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
FROM MST_CLIENT
WHERE CLIENT_CD = P_SEARCH_CLIENT_CD;

  v_temp_detail  Types.temp_detail_rc;

v_rec MST_CLIENT%ROWTYPE;




v_cnt INTEGER;
 i INTEGER;
 V_FIELD_CNT NUMBER;
 v_pending_cnt NUMBER;
 va CHAR(1) := '@';
BEGIN

			IF 	  P_UPD_STATUS = 'I' AND P_SEARCH_CLIENT_CD <> P_CLIENT_CD THEN
			       v_error_code := -2001;
				   v_error_msg  := 'jika INSERT, P_SEARCH_CLIENT_CD harus sama dengan P_CLIENT_CD';
				   RAISE v_err;
			END IF;
			
             BEGIN
   	 		 SELECT ROWID INTO v_table_rowid
			 FROM MST_CLIENT
			 WHERE TRIM(CLIENT_CD) = TRIM(P_SEARCH_CLIENT_CD);
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
				   v_error_msg  := 'DUPLICATED CLIENT_CD';
				   RAISE v_err;
			END IF;
			
			IF 	  P_UPD_STATUS = 'U'   AND P_SEARCH_CLIENT_CD <> P_CLIENT_CD THEN
				 BEGIN
	   	 		 SELECT COUNT(1) INTO v_cnt
				 FROM MST_CLIENT
				 WHERE TRIM(CLIENT_CD) = TRIM(P_CLIENT_CD);
				 EXCEPTION
				 WHEN NO_DATA_FOUND THEN
				 	  v_cnt := 0;
				WHEN OTHERS THEN
					     v_error_code := -3;
						 v_error_msg :=  SUBSTR('Retrieve  '|| v_table_name||' for '||P_CLIENT_CD||SQLERRM,1,200);
						 RAISE v_err;
				  END; 
				  
				  IF v_cnt  > 0 THEN
					       v_error_code := -2003;
						   v_error_msg  := 'DUPLICATED CLIENT_CD';
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
					 AND d.field_name = 'CLIENT_CD'
					 AND   d.field_value = P_SEARCH_CLIENT_CD
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
					SELECT  'CLIENT_CD'  AS field_name, p_CLIENT_CD AS field_value, DECODE(trim(v_rec.CLIENT_CD), trim(p_CLIENT_CD),'N','Y') upd_flg FROM dual
UNION
SELECT  'CIF_NUMBER'  AS field_name, TO_CHAR(p_CIF_NUMBER)  AS field_value, DECODE(v_rec.CIF_NUMBER, p_CIF_NUMBER,'N','Y') upd_flg FROM dual
UNION
SELECT  'CLIENT_NAME'  AS field_name, p_CLIENT_NAME AS field_value, DECODE(trim(v_rec.CLIENT_NAME), trim(p_CLIENT_NAME),'N','Y') upd_flg FROM dual
UNION
SELECT  'CLIENT_NAME_ABBR'  AS field_name, p_CLIENT_NAME_ABBR AS field_value, DECODE(trim(v_rec.CLIENT_NAME_ABBR), trim(p_CLIENT_NAME_ABBR),'N','Y') upd_flg FROM dual
UNION
SELECT  'CLIENT_TYPE_1'  AS field_name, p_CLIENT_TYPE_1 AS field_value, DECODE(trim(v_rec.CLIENT_TYPE_1), trim(p_CLIENT_TYPE_1),'N','Y') upd_flg FROM dual
UNION
SELECT  'CLIENT_TYPE_2'  AS field_name, p_CLIENT_TYPE_2 AS field_value, DECODE(trim(v_rec.CLIENT_TYPE_2), trim(p_CLIENT_TYPE_2),'N','Y') upd_flg FROM dual
UNION
SELECT  'CLIENT_TYPE_3'  AS field_name, p_CLIENT_TYPE_3 AS field_value, DECODE(trim(v_rec.CLIENT_TYPE_3), trim(p_CLIENT_TYPE_3),'N','Y') upd_flg FROM dual
UNION
SELECT  'CLIENT_TITLE'  AS field_name, p_CLIENT_TITLE AS field_value, DECODE(trim(v_rec.CLIENT_TITLE), trim(p_CLIENT_TITLE),'N','Y') upd_flg FROM dual
UNION
SELECT  'CLIENT_BIRTH_DT'  AS field_name, TO_CHAR(p_CLIENT_BIRTH_DT,'yyyy/mm/dd hh24:mi:ss')  AS field_value, DECODE(v_rec.CLIENT_BIRTH_DT, p_CLIENT_BIRTH_DT,'N','Y') upd_flg FROM dual
UNION
SELECT  'RELIGION'  AS field_name, p_RELIGION AS field_value, DECODE(trim(v_rec.RELIGION), trim(p_RELIGION),'N','Y') upd_flg FROM dual
UNION
SELECT  'ACCT_OPEN_DT'  AS field_name, TO_CHAR(p_ACCT_OPEN_DT,'yyyy/mm/dd hh24:mi:ss')  AS field_value, DECODE(v_rec.ACCT_OPEN_DT, p_ACCT_OPEN_DT,'N','Y') upd_flg FROM dual
UNION
SELECT  'CLIENT_RACE'  AS field_name, p_CLIENT_RACE AS field_value, DECODE(trim(v_rec.CLIENT_RACE), trim(p_CLIENT_RACE),'N','Y') upd_flg FROM dual
UNION
SELECT  'CLIENT_IC_NUM'  AS field_name, p_CLIENT_IC_NUM AS field_value, DECODE(trim(v_rec.CLIENT_IC_NUM), trim(p_CLIENT_IC_NUM),'N','Y') upd_flg FROM dual
UNION
SELECT  'CHQ_PAYEE_NAME'  AS field_name, p_CHQ_PAYEE_NAME AS field_value, DECODE(trim(v_rec.CHQ_PAYEE_NAME), trim(p_CHQ_PAYEE_NAME),'N','Y') upd_flg FROM dual
UNION
SELECT  'SETT_OFF_CD'  AS field_name, p_SETT_OFF_CD AS field_value, DECODE(trim(v_rec.SETT_OFF_CD), trim(p_SETT_OFF_CD),'N','Y') upd_flg FROM dual
UNION
SELECT  'STK_EXCH'  AS field_name, p_STK_EXCH AS field_value, DECODE(trim(v_rec.STK_EXCH), trim(p_STK_EXCH),'N','Y') upd_flg FROM dual
UNION
SELECT  'IC_TYPE'  AS field_name, p_IC_TYPE AS field_value, DECODE(trim(v_rec.IC_TYPE), trim(p_IC_TYPE),'N','Y') upd_flg FROM dual
UNION
SELECT  'CURR_CD'  AS field_name, p_CURR_CD AS field_value, DECODE(trim(v_rec.CURR_CD), trim(p_CURR_CD),'N','Y') upd_flg FROM dual
UNION
SELECT  'DEF_CURR_CD'  AS field_name, p_DEF_CURR_CD AS field_value, DECODE(trim(v_rec.DEF_CURR_CD), trim(p_DEF_CURR_CD),'N','Y') upd_flg FROM dual
UNION
SELECT  'REM_CD'  AS field_name, p_REM_CD AS field_value, DECODE(trim(v_rec.REM_CD), trim(p_REM_CD),'N','Y') upd_flg FROM dual
UNION
SELECT  'BANK_CD'  AS field_name, p_BANK_CD AS field_value, DECODE(trim(v_rec.BANK_CD), trim(p_BANK_CD),'N','Y') upd_flg FROM dual
UNION
SELECT  'BANK_BRCH_CD'  AS field_name, p_BANK_BRCH_CD AS field_value, DECODE(trim(v_rec.BANK_BRCH_CD), trim(p_BANK_BRCH_CD),'N','Y') upd_flg FROM dual
UNION
SELECT  'DEF_CONTRA_FLG'  AS field_name, p_DEF_CONTRA_FLG AS field_value, DECODE(trim(v_rec.DEF_CONTRA_FLG), trim(p_DEF_CONTRA_FLG),'N','Y') upd_flg FROM dual
UNION
SELECT  'CUST_CLIENT_FLG'  AS field_name, p_CUST_CLIENT_FLG AS field_value, DECODE(trim(v_rec.CUST_CLIENT_FLG), trim(p_CUST_CLIENT_FLG),'N','Y') upd_flg FROM dual
UNION
SELECT  'CR_LIM'  AS field_name, TO_CHAR(p_CR_LIM)  AS field_value, DECODE(v_rec.CR_LIM, p_CR_LIM,'N','Y') upd_flg FROM dual
UNION
SELECT  'SUSP_STAT'  AS field_name, p_SUSP_STAT AS field_value, DECODE(trim(v_rec.SUSP_STAT), trim(p_SUSP_STAT),'N','Y') upd_flg FROM dual
UNION
SELECT  'DEF_ADDR_1'  AS field_name, p_DEF_ADDR_1 AS field_value, DECODE(trim(v_rec.DEF_ADDR_1), trim(p_DEF_ADDR_1),'N','Y') upd_flg FROM dual
UNION
SELECT  'DEF_ADDR_2'  AS field_name, p_DEF_ADDR_2 AS field_value, DECODE(trim(v_rec.DEF_ADDR_2), trim(p_DEF_ADDR_2),'N','Y') upd_flg FROM dual
UNION
SELECT  'DEF_ADDR_3'  AS field_name, p_DEF_ADDR_3 AS field_value, DECODE(trim(v_rec.DEF_ADDR_3), trim(p_DEF_ADDR_3),'N','Y') upd_flg FROM dual
UNION
SELECT  'POST_CD'  AS field_name, p_POST_CD AS field_value, DECODE(trim(v_rec.POST_CD), trim(p_POST_CD),'N','Y') upd_flg FROM dual
UNION
SELECT  'CONTACT_PERS'  AS field_name, p_CONTACT_PERS AS field_value, DECODE(trim(v_rec.CONTACT_PERS), trim(p_CONTACT_PERS),'N','Y') upd_flg FROM dual
UNION
SELECT  'PHONE_NUM'  AS field_name, p_PHONE_NUM AS field_value, DECODE(trim(v_rec.PHONE_NUM), trim(p_PHONE_NUM),'N','Y') upd_flg FROM dual
UNION
SELECT  'HP_NUM'  AS field_name, p_HP_NUM AS field_value, DECODE(trim(v_rec.HP_NUM), trim(p_HP_NUM),'N','Y') upd_flg FROM dual
UNION
SELECT  'FAX_NUM'  AS field_name, p_FAX_NUM AS field_value, DECODE(trim(v_rec.FAX_NUM), trim(p_FAX_NUM),'N','Y') upd_flg FROM dual
UNION
SELECT  'E_MAIL1'  AS field_name, p_E_MAIL1 AS field_value, DECODE(trim(v_rec.E_MAIL1), trim(p_E_MAIL1),'N','Y') upd_flg FROM dual
UNION
SELECT  'HAND_PHONE1'  AS field_name, p_HAND_PHONE1 AS field_value, DECODE(trim(v_rec.HAND_PHONE1), trim(p_HAND_PHONE1),'N','Y') upd_flg FROM dual
UNION
SELECT  'PHONE2_1'  AS field_name, p_PHONE2_1 AS field_value, DECODE(trim(v_rec.PHONE2_1), trim(p_PHONE2_1),'N','Y') upd_flg FROM dual
UNION
SELECT  'REGN_CD'  AS field_name, p_REGN_CD AS field_value, DECODE(trim(v_rec.REGN_CD), trim(p_REGN_CD),'N','Y') upd_flg FROM dual
UNION
SELECT  'DESP_PREF'  AS field_name, p_DESP_PREF AS field_value, DECODE(trim(v_rec.DESP_PREF), trim(p_DESP_PREF),'N','Y') upd_flg FROM dual
UNION
SELECT  'STOP_PAY'  AS field_name, p_STOP_PAY AS field_value, DECODE(trim(v_rec.STOP_PAY), trim(p_STOP_PAY),'N','Y') upd_flg FROM dual
UNION
SELECT  'OLD_IC_NUM'  AS field_name, p_OLD_IC_NUM AS field_value, DECODE(trim(v_rec.OLD_IC_NUM), trim(p_OLD_IC_NUM),'N','Y') upd_flg FROM dual
UNION
SELECT  'PRINT_FLG'  AS field_name, p_PRINT_FLG AS field_value, DECODE(trim(v_rec.PRINT_FLG), trim(p_PRINT_FLG),'N','Y') upd_flg FROM dual
UNION
SELECT  'REM_OWN_TRADE'  AS field_name, p_REM_OWN_TRADE AS field_value, DECODE(trim(v_rec.REM_OWN_TRADE), trim(p_REM_OWN_TRADE),'N','Y') upd_flg FROM dual
UNION
SELECT  'AVG_FLG'  AS field_name, p_AVG_FLG AS field_value, DECODE(trim(v_rec.AVG_FLG), trim(p_AVG_FLG),'N','Y') upd_flg FROM dual
UNION
SELECT  'CLIENT_NAME_EXT'  AS field_name, p_CLIENT_NAME_EXT AS field_value, DECODE(trim(v_rec.CLIENT_NAME_EXT), trim(p_CLIENT_NAME_EXT),'N','Y') upd_flg FROM dual
UNION
SELECT  'BRANCH_CODE'  AS field_name, p_BRANCH_CODE AS field_value, DECODE(trim(v_rec.BRANCH_CODE), trim(p_BRANCH_CODE),'N','Y') upd_flg FROM dual
UNION
SELECT  'PPH_APPL_FLG'  AS field_name, p_PPH_APPL_FLG AS field_value, DECODE(trim(v_rec.PPH_APPL_FLG), trim(p_PPH_APPL_FLG),'N','Y') upd_flg FROM dual
UNION
SELECT  'LEVY_APPL_FLG'  AS field_name, p_LEVY_APPL_FLG AS field_value, DECODE(trim(v_rec.LEVY_APPL_FLG), trim(p_LEVY_APPL_FLG),'N','Y') upd_flg FROM dual
UNION
SELECT  'INT_ON_PAYABLE'  AS field_name, TO_CHAR(p_INT_ON_PAYABLE)  AS field_value, DECODE(v_rec.INT_ON_PAYABLE, p_INT_ON_PAYABLE,'N','Y') upd_flg FROM dual
UNION
SELECT  'INT_ON_RECEIVABLE'  AS field_name, TO_CHAR(p_INT_ON_RECEIVABLE)  AS field_value, DECODE(v_rec.INT_ON_RECEIVABLE, p_INT_ON_RECEIVABLE,'N','Y') upd_flg FROM dual
UNION
SELECT  'INT_ON_ADV_RECD'  AS field_name, TO_CHAR(p_INT_ON_ADV_RECD)  AS field_value, DECODE(v_rec.INT_ON_ADV_RECD, p_INT_ON_ADV_RECD,'N','Y') upd_flg FROM dual
UNION
SELECT  'GRACE_PERIOD'  AS field_name, TO_CHAR(p_GRACE_PERIOD)  AS field_value, DECODE(v_rec.GRACE_PERIOD, p_GRACE_PERIOD,'N','Y') upd_flg FROM dual
UNION
SELECT  'INT_REC_DAYS'  AS field_name, TO_CHAR(p_INT_REC_DAYS)  AS field_value, DECODE(v_rec.INT_REC_DAYS, p_INT_REC_DAYS,'N','Y') upd_flg FROM dual
UNION
SELECT  'INT_PAY_DAYS'  AS field_name, TO_CHAR(p_INT_PAY_DAYS)  AS field_value, DECODE(v_rec.INT_PAY_DAYS, p_INT_PAY_DAYS,'N','Y') upd_flg FROM dual
UNION
SELECT  'TAX_ON_INTEREST'  AS field_name, p_TAX_ON_INTEREST AS field_value, DECODE(trim(v_rec.TAX_ON_INTEREST), trim(p_TAX_ON_INTEREST),'N','Y') upd_flg FROM dual
UNION
SELECT  'AGREEMENT_NO'  AS field_name, p_AGREEMENT_NO AS field_value, DECODE(trim(v_rec.AGREEMENT_NO), trim(p_AGREEMENT_NO),'N','Y') upd_flg FROM dual
UNION
SELECT  'NPWP_NO'  AS field_name, p_NPWP_NO AS field_value, DECODE(trim(v_rec.NPWP_NO), trim(p_NPWP_NO),'N','Y') upd_flg FROM dual
UNION
SELECT  'REBATE'  AS field_name, TO_CHAR(p_REBATE)  AS field_value, DECODE(v_rec.REBATE, p_REBATE,'N','Y') upd_flg FROM dual
UNION
SELECT  'REBATE_BASIS'  AS field_name, p_REBATE_BASIS AS field_value, DECODE(trim(v_rec.REBATE_BASIS), trim(p_REBATE_BASIS),'N','Y') upd_flg FROM dual
UNION
SELECT  'COMMISSION_PER'  AS field_name, TO_CHAR(p_COMMISSION_PER)  AS field_value, DECODE(v_rec.COMMISSION_PER, p_COMMISSION_PER,'N','Y') upd_flg FROM dual
UNION
SELECT  'ACOPEN_FEE_FLG'  AS field_name, p_ACOPEN_FEE_FLG AS field_value, DECODE(trim(v_rec.ACOPEN_FEE_FLG), trim(p_ACOPEN_FEE_FLG),'N','Y') upd_flg FROM dual
UNION
SELECT  'NEXT_ROLLOVER_DT'  AS field_name, TO_CHAR(p_NEXT_ROLLOVER_DT,'yyyy/mm/dd hh24:mi:ss')  AS field_value, DECODE(v_rec.NEXT_ROLLOVER_DT, p_NEXT_ROLLOVER_DT,'N','Y') upd_flg FROM dual
UNION
SELECT  'AC_EXPIRY_DT'  AS field_name, TO_CHAR(p_AC_EXPIRY_DT,'yyyy/mm/dd hh24:mi:ss')  AS field_value, DECODE(v_rec.AC_EXPIRY_DT, p_AC_EXPIRY_DT,'N','Y') upd_flg FROM dual
UNION
SELECT  'COMMIT_FEE_DT'  AS field_name, TO_CHAR(p_COMMIT_FEE_DT,'yyyy/mm/dd hh24:mi:ss')  AS field_value, DECODE(v_rec.COMMIT_FEE_DT, p_COMMIT_FEE_DT,'N','Y') upd_flg FROM dual
UNION
SELECT  'ROLL_FEE_DT'  AS field_name, TO_CHAR(p_ROLL_FEE_DT,'yyyy/mm/dd hh24:mi:ss')  AS field_value, DECODE(v_rec.ROLL_FEE_DT, p_ROLL_FEE_DT,'N','Y') upd_flg FROM dual
UNION
SELECT  'RECOV_CHARGE_FLG'  AS field_name, p_RECOV_CHARGE_FLG AS field_value, DECODE(trim(v_rec.RECOV_CHARGE_FLG), trim(p_RECOV_CHARGE_FLG),'N','Y') upd_flg FROM dual
UNION
SELECT  'REBATE_TOTTRADE'  AS field_name, TO_CHAR(p_REBATE_TOTTRADE)  AS field_value, DECODE(v_rec.REBATE_TOTTRADE, p_REBATE_TOTTRADE,'N','Y') upd_flg FROM dual
UNION
SELECT  'AMT_INT_FLG'  AS field_name, p_AMT_INT_FLG AS field_value, DECODE(trim(v_rec.AMT_INT_FLG), trim(p_AMT_INT_FLG),'N','Y') upd_flg FROM dual
UNION
SELECT  'INTERNET_CLIENT'  AS field_name, p_INTERNET_CLIENT AS field_value, DECODE(trim(v_rec.INTERNET_CLIENT), trim(p_INTERNET_CLIENT),'N','Y') upd_flg FROM dual
UNION
SELECT  'CONTRA_DAYS'  AS field_name, p_CONTRA_DAYS AS field_value, DECODE(trim(v_rec.CONTRA_DAYS), trim(p_CONTRA_DAYS),'N','Y') upd_flg FROM dual
UNION
SELECT  'VAT_APPL_FLG'  AS field_name, p_VAT_APPL_FLG AS field_value, DECODE(trim(v_rec.VAT_APPL_FLG), trim(p_VAT_APPL_FLG),'N','Y') upd_flg FROM dual
UNION
SELECT  'INT_ACCUMULATED'  AS field_name, p_INT_ACCUMULATED AS field_value, DECODE(trim(v_rec.INT_ACCUMULATED), trim(p_INT_ACCUMULATED),'N','Y') upd_flg FROM dual
UNION
SELECT  'BANK_ACCT_NUM'  AS field_name, p_BANK_ACCT_NUM AS field_value, DECODE(trim(v_rec.BANK_ACCT_NUM), trim(p_BANK_ACCT_NUM),'N','Y') upd_flg FROM dual
UNION
SELECT  'CUSTODIAN_CD'  AS field_name, p_CUSTODIAN_CD AS field_value, DECODE(trim(v_rec.CUSTODIAN_CD), trim(p_CUSTODIAN_CD),'N','Y') upd_flg FROM dual
UNION
SELECT  'OLT'  AS field_name, p_OLT AS field_value, DECODE(trim(v_rec.OLT), trim(p_OLT),'N','Y') upd_flg FROM dual
UNION
SELECT  'SID'  AS field_name, p_SID AS field_value, DECODE(trim(v_rec.SID), trim(p_SID),'N','Y') upd_flg FROM dual
UNION
SELECT  'BIZ_TYPE'  AS field_name, p_BIZ_TYPE AS field_value, DECODE(trim(v_rec.BIZ_TYPE), trim(p_BIZ_TYPE),'N','Y') upd_flg FROM dual
UNION
SELECT  'CIFS'  AS field_name, p_CIFS AS field_value, DECODE(trim(v_rec.CIFS), trim(p_CIFS),'N','Y') upd_flg FROM dual

UNION
SELECT  'REFERENCE_NAME'  AS field_name, p_REFERENCE_NAME AS field_value, DECODE(trim(v_rec.REFERENCE_NAME), trim(p_REFERENCE_NAME),'N','Y') upd_flg FROM dual
UNION
SELECT  'TRADE_CONF_SEND_TO'  AS field_name, p_TRADE_CONF_SEND_TO AS field_value, DECODE(trim(v_rec.TRADE_CONF_SEND_TO), trim(p_TRADE_CONF_SEND_TO),'N','Y') upd_flg FROM dual
UNION
SELECT  'TRADE_CONF_SEND_FREQ'  AS field_name, p_TRADE_CONF_SEND_FREQ AS field_value, DECODE(trim(v_rec.TRADE_CONF_SEND_FREQ), trim(p_TRADE_CONF_SEND_FREQ),'N','Y') upd_flg FROM dual
UNION
SELECT  'DEF_CITY'  AS field_name, p_DEF_CITY AS field_value, DECODE(trim(v_rec.DEF_CITY), trim(p_DEF_CITY),'N','Y') upd_flg FROM dual
UNION
SELECT  'COMMISSION_PER_SELL'  AS field_name, TO_CHAR(p_COMMISSION_PER_SELL)  AS field_value, DECODE(v_rec.COMMISSION_PER_SELL, p_COMMISSION_PER_SELL,'N','Y') upd_flg FROM dual
UNION
SELECT  'COMMISSION_PER_BUY'  AS field_name, TO_CHAR(p_COMMISSION_PER_BUY)  AS field_value, DECODE(v_rec.COMMISSION_PER_BUY, p_COMMISSION_PER_BUY,'N','Y') upd_flg FROM dual
UNION
SELECT  'RECOMMENDED_BY_CD'  AS field_name, p_RECOMMENDED_BY_CD AS field_value, DECODE(trim(v_rec.RECOMMENDED_BY_CD), trim(p_RECOMMENDED_BY_CD),'N','Y') upd_flg FROM dual
UNION
SELECT  'RECOMMENDED_BY_OTHER'  AS field_name, p_RECOMMENDED_BY_OTHER AS field_value, DECODE(trim(v_rec.RECOMMENDED_BY_OTHER), trim(p_RECOMMENDED_BY_OTHER),'N','Y') upd_flg FROM dual
UNION
SELECT  'TRANSACTION_LIMIT'  AS field_name, TO_CHAR(p_TRANSACTION_LIMIT)  AS field_value, DECODE(v_rec.TRANSACTION_LIMIT, p_TRANSACTION_LIMIT,'N','Y') upd_flg FROM dual
UNION
SELECT  'INIT_DEPOSIT_AMOUNT'  AS field_name, TO_CHAR(p_INIT_DEPOSIT_AMOUNT)  AS field_value, DECODE(v_rec.INIT_DEPOSIT_AMOUNT, p_INIT_DEPOSIT_AMOUNT,'N','Y') upd_flg FROM dual
UNION
SELECT  'INIT_DEPOSIT_EFEK'  AS field_name, p_INIT_DEPOSIT_EFEK AS field_value, DECODE(trim(v_rec.INIT_DEPOSIT_EFEK), trim(p_INIT_DEPOSIT_EFEK),'N','Y') upd_flg FROM dual
UNION
SELECT  'INIT_DEPOSIT_EFEK_PRICE'  AS field_name, TO_CHAR(p_INIT_DEPOSIT_EFEK_PRICE)  AS field_value, DECODE(v_rec.INIT_DEPOSIT_EFEK_PRICE, p_INIT_DEPOSIT_EFEK_PRICE,'N','Y') upd_flg FROM dual
UNION
SELECT  'INIT_DEPOSIT_EFEK_DATE'  AS field_name, TO_CHAR(p_INIT_DEPOSIT_EFEK_DATE,'yyyy/mm/dd hh24:mi:ss')  AS field_value, DECODE(v_rec.INIT_DEPOSIT_EFEK_DATE, p_INIT_DEPOSIT_EFEK_DATE,'N','Y') upd_flg FROM dual
UNION
SELECT  'ID_COPY_FLG'  AS field_name, p_ID_COPY_FLG AS field_value, DECODE(trim(v_rec.ID_COPY_FLG), trim(p_ID_COPY_FLG),'N','Y') upd_flg FROM dual
UNION
SELECT  'NPWP_COPY_FLG'  AS field_name, p_NPWP_COPY_FLG AS field_value, DECODE(trim(v_rec.NPWP_COPY_FLG), trim(p_NPWP_COPY_FLG),'N','Y') upd_flg FROM dual
UNION
SELECT  'KORAN_COPY_FLG'  AS field_name, p_KORAN_COPY_FLG AS field_value, DECODE(trim(v_rec.KORAN_COPY_FLG), trim(p_KORAN_COPY_FLG),'N','Y') upd_flg FROM dual
UNION
SELECT  'COPY_OTHER_FLG'  AS field_name, p_COPY_OTHER_FLG AS field_value, DECODE(trim(v_rec.COPY_OTHER_FLG), trim(p_COPY_OTHER_FLG),'N','Y') upd_flg FROM dual
UNION
SELECT  'COPY_OTHER'  AS field_name, p_COPY_OTHER AS field_value, DECODE(trim(v_rec.COPY_OTHER), trim(p_COPY_OTHER),'N','Y') upd_flg FROM dual
UNION
SELECT  'CLIENT_CLASS'  AS field_name, p_CLIENT_CLASS AS field_value, DECODE(trim(v_rec.CLIENT_CLASS), trim(p_CLIENT_CLASS),'N','Y') upd_flg FROM dual
UNION
SELECT  'SUSP_TRX'  AS field_name, p_SUSP_TRX AS field_value, DECODE(trim(v_rec.SUSP_TRX), trim(p_SUSP_TRX),'N','Y') upd_flg FROM dual
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

END Sp_Mst_CLIENT_SUSPEND_UPD;