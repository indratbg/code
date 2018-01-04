create or replace 
PROCEDURE "SP_GEN_TRADING_REF_APPROVE" (
	   p_menu_name							T_MANY_HEADER.menu_name%TYPE,
	   p_update_date						T_MANY_HEADER.update_date%TYPE,
	   p_update_seq							T_MANY_HEADER.update_seq%TYPE,
	   p_approved_user_id				  	T_MANY_HEADER.user_id%TYPE,
	   p_approved_ip_address 		 		T_MANY_HEADER.ip_address%TYPE,
	   P_trx_date DATE,
	   P_CLIENT_CD T_CONTRACTS.CLIENT_CD%TYPE,
	   P_MODE NUMBER,
	   P_TC_ID        T_TC_DOC.TC_ID%TYPE,
	   
	   p_error_code							OUT NUMBER,
	   p_error_msg							OUT VARCHAR2
	   ) IS

/******************************************************************************
   NAME:       SP_GEN_TRADING_REF_APPROVE
   PURPOSE:

	Updating records in T_TC_DOC which have temporary values from SP_GEN_TRADING_REF_UPD
	including replacing the {tc_id} in TC_CLOB with the properly calculated TC_ID
	--AS--


   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        12/06/2014          1. Created this procedure.

   NOTES:
******************************************************************************/
/*
CURSOR CSR_TC IS
SELECT record_seq, upd_status,
(SELECT TO_DATE(field_value,'yyyy/mm/dd hh24:mi:ss') FROM T_MANY_DETAIL da 
        WHERE da.update_date = dd.update_date 
        AND da.update_seq = dd.update_seq
        AND da.table_name = 'T_TC_DOC'
        AND da.field_name = 'TC_DATE'
        AND da.record_seq = dd.record_seq) tc_date, 
(SELECT field_value FROM T_MANY_DETAIL da 
        WHERE da.update_date = dd.update_date 
        AND da.update_seq = dd.update_seq
        AND da.table_name = 'T_TC_DOC'
        AND da.field_name = 'TC_ID'
        AND da.record_seq = dd.record_seq) tc_id,
(SELECT TO_NUMBER(field_value) FROM T_MANY_DETAIL da 
        WHERE da.update_date = dd.update_date 
        AND da.update_seq = dd.update_seq
        AND da.table_name = 'T_TC_DOC'
        AND da.field_name = 'TC_REV'
        AND da.record_seq = dd.record_seq) tc_rev,
(SELECT field_value FROM T_MANY_DETAIL da 
        WHERE da.update_date = dd.update_date 
        AND da.update_seq = dd.update_seq
        AND da.table_name = 'T_TC_DOC'
        AND da.field_name = 'CLIENT_CD'
        AND da.record_seq = dd.record_seq) CLIENT_CD		
FROM T_MANY_DETAIL dd WHERE dd.update_date = p_update_date AND dd.update_seq = p_update_seq 
	AND dd.table_name = 'T_TC_DOC' AND  dd.field_name IN ('TC_DATE') ORDER BY dd.record_seq;
*/
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
			AND (P_TC_ID = '%' or P_TC_ID is null or P_TC_ID = '')
			GROUP BY CLIENT_CD
			HAVING MAX(DECODE(TC_TYPE,'TN','ZZ',TC_TYPE)) <> 'ZZ'
		) C
		WHERE  T.CLIENT_CD = C.CLIENT_CD(+)
)
 WHERE  contr_cre_dt > nvl(tc_cre_dt, to_date('01/01/2000','dd/mm/yyyy'))
 ORDER BY 1;
tmpVar NUMBER;
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

	FOR REC IN CSR_TRX LOOP
		v_create := 'N';
-- 		IF rec.client_Cd = 'ANDI020R' THEN
-- 			v_create := 'N';
-- 		END IF;

		IF rec.tc_id  IS NULL  THEN
		   	v_create := 'Y';
			v_status := 0;
		ELSE
		        IF P_mode = 1 OR P_mode = 3 THEN
					IF  rec.contr_cre_dt > rec.tc_cre_dt THEN
						v_create := 'Y';
						v_status := 0;
					END IF;
                ELSE
					v_create := 'Y';
					v_status := 0;
				END IF;
		END IF;


		IF rec.tc_id  IS NOT NULL   AND  v_create = 'Y' THEN
			BEGIN
				UPDATE T_TC_DOC
				SET tc_status = 5, upd_by = p_approved_user_id, upd_dt = SYSDATE
				WHERE tc_date = p_trx_date
				AND client_cd = rec.client_cd
				AND ((P_TC_ID <> '%' AND TC_ID = rec.tc_id )
					OR P_TC_ID = '%')
				AND tc_status = 0;
			EXCEPTION
				WHEN OTHERS THEN
					v_error_code := -8;
					v_error_msg :=  SUBSTR('UPDATE  T_TC_DOC '||SQLERRM,1,200);
					RAISE v_err;
			END;
		END IF;

        IF   v_create = 'Y' THEN
		--
			IF rec.tc_id IS NULL OR P_TC_ID = 'NEW'  OR  (P_mode = 1 AND rec.cnt_Tunai = 0 AND rec.tc_type <> 'CONGEN') THEN
				BEGIN
					SELECT seq_tc.NEXTVAL INTO v_seq FROM dual;
				EXCEPTION
					WHEN OTHERS THEN
						v_error_code := -3;
						v_error_msg :=  SUBSTR('Get Sequence '||SQLERRM,1,200);
						RAISE v_err;
				END;

				v_trading_ref := v_kode_ab||'/'||trim(TO_CHAR(v_seq,'000000'))||'/';

				BEGIN
					SELECT  v_trading_ref||trim(TO_CHAR(p_trx_date,'RM'))||TO_CHAR(p_trx_date,'/yyyy') INTO  v_trading_ref
					FROM dual;
				EXCEPTION
					WHEN OTHERS THEN
						v_error_code := -4;
						v_error_msg :=  SUBSTR('Generate Trading Reference ID'||SQLERRM,1,200);
						RAISE v_err;
				END;

				v_revisi := 0;
			ELSE
				v_trading_ref := rec.tc_id;
				v_revisi :=rec.NEW_TC_REV;
			END IF;

			BEGIN
				UPDATE T_TC_DOC
				SET TC_ID = v_trading_ref,
				TC_STATUS = v_status,
				TC_REV = v_revisi,
				TC_CLOB_ENG = REPLACE(TC_CLOB_ENG,'{tc_id}',v_trading_ref),
				TC_CLOB_IND = REPLACE(TC_CLOB_IND,'{tc_id}',v_trading_ref),
        TC_MATRIX_ENG = REPLACE(TC_MATRIX_ENG,'{tc_id}',v_trading_ref),
				TC_MATRIX_IND = REPLACE(TC_MATRIX_IND,'{tc_id}',v_trading_ref)
				WHERE
				TC_DATE = P_TRX_DATE AND
				CLIENT_CD = rec.client_cd AND
				TC_REV = -1 AND
				TC_STATUS = -1;
			EXCEPTION
				WHEN OTHERS THEN
					v_error_code := -9;
					v_error_msg :=  SUBSTR('UPDATE T_TC_DOC '||SQLERRM,1,200);
					RAISE v_err;
			END;
		END IF;
		
	END LOOP;
  
  BEGIN
      Sp_T_Many_Approve(p_menu_name,
         p_update_date,
         p_update_seq,
         p_approved_user_id,
         p_approved_ip_address,
         v_error_code,
         v_error_msg);
     EXCEPTION
    WHEN OTHERS THEN
        v_error_code := -10;
        v_error_msg :=  SUBSTR('Sp_T_Many_Approve '||p_menu_name||SQLERRM,1,200);
        RAISE v_err;
     END;
  
    IF v_error_code < 0 THEN
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
END SP_GEN_TRADING_REF_APPROVE;