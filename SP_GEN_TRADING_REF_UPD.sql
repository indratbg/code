create or replace 
PROCEDURE           "SP_GEN_TRADING_REF_UPD" (
P_trx_date DATE,
P_CLIENT_CD T_CONTRACTS.CLIENT_CD%TYPE,
P_MODE NUMBER,
P_TC_ID        T_TC_DOC.TC_ID%TYPE,
P_USER_ID T_TC_DOC.CRE_BY%TYPE,

P_UPD_STATUS			T_MANY_DETAIL.UPD_STATUS%TYPE,
p_ip_address			T_MANY_HEADER.IP_ADDRESS%TYPE,
p_cancel_reason			T_MANY_HEADER.CANCEL_REASON%TYPE,
p_update_date			T_MANY_HEADER.UPDATE_DATE%TYPE,
p_update_seq			T_MANY_HEADER.UPDATE_SEQ%TYPE,

p_error_code	OUT		NUMBER,
p_error_msg		OUT		VARCHAR2)

IS

/******************************************************************************
   NAME:       SP_GEN_TRADING_REF_UPD
   PURPOSE:
	
	Replacing the functionality of the original SP_GEN_TRADING_REF which inserts
	data into T_TC_DOC but instead of using the properly calculated TC_ID, TC_REV,
	and TC_STATUS, those 3 attributes are filled with temporary values which are:
	TC_ID = 'TEMP'||client_cd
	TC_REV = 0
	TC_STATUS = -1
	
	These attributes will later be replaced(updated) with the properly calculated values
	provided in SP_GEN_TRADING_REF_APPROVE
	--AS--

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        28/04/2015          1. Created this procedure.

   NOTES:
******************************************************************************/


tmpVar NUMBER;

CURSOR csr_trx IS
 SELECT CLIENT_CD, BRCH_CD, REM_CD, contr_cre_dt,CLIENT_NAME, cnt_tunai, TC_ID, TC_CRE_DT , TC_STATUS, new_tc_rev, TC_TYPE
 FROM(

 	   SELECT  T.CLIENT_CD, T.BRCH_CD, T.REM_CD, t.contr_cre_dt,
		CLIENT_NAME, cnt_tunai, c.TC_ID, NVL(C.TC_CRE_DT,TO_DATE(NULL)) TC_CRE_DT , C.TC_STATUS, DECODE(c.tc_id,NULL,0,c.NEW_TC_REV) new_tc_rev, TC_TYPE
		FROM
		(
		SELECT  CLIENT_CD, BRCH_CD, REM_CD, contr_cre_dt, CLIENT_NAME, cnt_tunai
 		FROM(
			SELECT  T1.CLIENT_CD, T1.BRCH_CD, T1.REM_CD, T1.contr_cre_dt, MST_CLIENT.CLIENT_NAME, t1.cnt_tunai
			FROM
			( 	SELECT client_Cd, brch_cd, rem_cd, MAX(cre_dt) contr_cre_dt, MAX(DECODE(contr_dt,due_dt_for_amt,1,0)) AS cnt_Tunai
				FROM T_CONTRACTS
				WHERE CONTR_DT =  P_TRX_DATE
				AND CONTR_STAT <> 'C'
				GROUP BY client_Cd, brch_cd, rem_cd
			) t1,
			MST_CLIENT
			WHERE  (P_mode = 1		OR ( P_mode = 3 AND t1.client_cd = P_CLIENT_CD))
			AND T1.CLIENT_CD = MST_CLIENT.CLIENT_CD
		UNION ALL
			SELECT CLIENT_CD, TRIM(BRANCH_CODE), TRIM(REM_CD), SYSDATE, CLIENT_NAME, DECODE(P_TC_ID,'TN',1,0)
		FROM MST_CLIENT
		WHERE client_cd = P_CLIENT_CD
		AND  P_mode = 2) ) T,
		(
			SELECT CLIENT_CD, CRE_DT AS TC_CRE_DT, TC_ID, TC_STATUS, TC_REV + 1 AS NEW_TC_REV, TC_TYPE
			FROM T_TC_DOC
			WHERE TC_DATE =  P_TRX_DATE
			AND TC_STATUS = 0
			AND ( TC_ID = P_TC_ID OR (P_TC_ID = '%' AND TC_TYPE = 'TN') OR  ( P_TC_ID = 'TN' AND TC_TYPE = 'TN'))
			UNION ALL
			SELECT CLIENT_CD, MAX(CRE_DT),MAX(tc_ID) TC_ID,0,MAX(TC_REV) + 1 AS NEW_TC_REV, MAX(DECODE(TC_TYPE,'TN','ZZ',TC_TYPE)) TC_TYPE
			FROM T_TC_DOC
			WHERE TC_DATE =  P_TRX_DATE
			AND TC_STATUS = 0
			AND P_TC_ID = '%'
			GROUP BY CLIENT_CD
			HAVING MAX(DECODE(TC_TYPE,'TN','ZZ',TC_TYPE)) <> 'ZZ'
		) C
		WHERE  T.CLIENT_CD = C.CLIENT_CD(+)
)
 WHERE  contr_cre_dt > NVL(tc_cre_dt, TO_DATE('01/01/2000','dd/mm/yyyy'))
 ORDER BY 1;

v_kode_ab CHAR(2);
v_trading_ref T_TC_DOC.tc_id%TYPE;
v_seq NUMBER;
v_revisi NUMBER;
v_cnt NUMBER;
--v_max_dt DATE;
 v_create CHAR(1) := 'N';
 v_status NUMBER := 0;

 v_err 					EXCEPTION;
v_error_code			NUMBER;
v_error_msg				VARCHAR2(1000);

v_many_detail  Types.many_detail_rc;
v_table_name 		T_many_DETAIL.table_name%TYPE := 'T_TC_DOC';
v_table_rowid		T_many_DETAIL.table_rowid%TYPE := NULL;

v_record_seq  NUMBER;

v_loop varchar2(1):='N';

BEGIN
	tmpVar := 0;
	BEGIN
		SELECT SUBSTR(BROKER_CD,1,2) INTO v_kode_ab  FROM v_broker_subrek;
	EXCEPTION
		WHEN OTHERS THEN
			v_error_code := -2;
			v_error_msg :=  SUBSTR('Retrieve  V_BROKER_SUBREK '||SQLERRM,1,200);
			RAISE v_err;
	END;
  
    v_record_seq := 1;

	For Rec In Csr_Trx Loop
		
    V_Trading_Ref :='TEMP'||Rec.Client_Cd;
    V_Status  := -1;
    v_revisi  := -1;

		BEGIN
			SELECT COUNT(1) INTO tmpVar FROM T_TC_DOC WHERE TC_DATE = P_TRX_DATE AND CLIENT_CD = rec.client_cd AND TC_STATUS = -1;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
			tmpVar := 0;
			WHEN OTHERS THEN
				v_error_code := -3;
				v_error_msg :=  SUBSTR('Retrieve T_TC_DOC '||SQLERRM,1,200);
				RAISE v_err;
		END;
		
		If Tmpvar > 0 Then
			v_error_code := -43;
			v_error_msg := 'Masih ada yang belum diapprove!';
			RAISE v_err;
		END IF;
		EXIT WHEN tmpVar > 0;
		BEGIN
			INSERT INTO IPNEXTG.T_TC_DOC (
				TC_ID, TC_DATE, TC_STATUS,
				TC_REV, CLIENT_CD, CLIENT_NAME,
				BRCH_CD, REM_CD, TC_TYPE,
				CRE_DT, CRE_BY, TC_CLOB_ENG, TC_CLOB_IND, TC_MATRIX_ENG, TC_MATRIX_IND)
			VALUES ( v_trading_ref , p_trx_date , v_status,
				v_revisi, rec.client_cd, rec.client_name,
				trim(rec.brch_cd), rec.rem_cd, DECODE(p_mode,2,DECODE(rec.cnt_tunai,1,'TN','FIXED'),'CONGEN'),
				SYSDATE, p_user_id, empty_clob(), empty_clob(), empty_clob(), empty_clob());
        
		EXCEPTION
			WHEN OTHERS THEN
				v_error_code := -9;
				v_error_msg :=  SUBSTR('INSERT to T_TC_DOC '||SQLERRM,1,200);
				RAISE v_err;
		END;
		
		OPEN v_many_detail FOR
		SELECT p_update_date AS update_date, p_update_seq AS update_seq, v_table_name AS table_name, v_record_seq AS record_seq, v_table_rowid AS table_rowid, a.field_name,  field_type, b.field_value, P_UPD_STATUS AS status,  b.upd_flg
		  FROM(
			 SELECT  SYSDATE AS  update_date, v_table_name AS table_name, column_id, column_name AS field_name,
													DECODE(data_type,'VARCHAR2','S','CHAR','S','NUMBER','N','DATE','D','X') AS field_type
											FROM all_tab_columns
											WHERE table_name = v_table_name
											AND OWNER = 'IPNEXTG') a,
			( 
						SELECT  'TC_DATE'  AS field_name, TO_CHAR(P_TRX_DATE,'yyyy/mm/dd hh24:mi:ss')  AS field_value, 'X' upd_flg FROM dual
						UNION
						SELECT  'TC_ID'  AS field_name, v_trading_ref AS field_value, 'X' upd_flg FROM dual
						UNION
						SELECT  'TC_REV'  AS field_name, TO_CHAR(v_revisi) AS field_value, 'X' upd_flg FROM dual
            UNION
            SELECT 'CLIENT_CD' AS field_name, rec.client_cd AS field_value, 'X' upd_flg FROM dual
            UNION
            SELECT 'TC_STATUS' AS field_name, TO_CHAR(P_MODE) AS field_value, 'X' upd_flg FROM dual
					 ) b
			 WHERE a.field_name = b.field_name;
		 
		 BEGIN
			Sp_T_Many_Detail_Insert(p_update_date, p_update_seq, p_upd_status, v_table_name, v_record_seq , v_table_rowid, v_MANY_DETAIL, v_error_code, v_error_msg);
		EXCEPTION
		WHEN OTHERS THEN
			 v_error_code := -8;
			  v_error_msg := SUBSTR('SP_T_MANY_DETAIL_INSERT '||v_table_name||SQLERRM,1,200);
			  RAISE v_err;
		END;	
		
  V_Record_Seq := V_Record_Seq + 1;
  v_loop :='Y';
	END LOOP;

  If V_Loop <> 'Y' Then
        V_Error_Code := -11;
			  V_Error_Msg := 'Tidak ada data yang digenerate/ sama dengan yang digenerate sebelumnya';
			  RAISE v_err;
  end if;

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
END SP_GEN_TRADING_REF_UPD;