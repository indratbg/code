create or replace PROCEDURE SP_MST_CLIENT_APPROVE
(
   p_menu_name						T_MANY_HEADER.menu_name%TYPE,
   p_update_date					T_MANY_HEADER.update_date%TYPE,
   p_update_seq						T_MANY_HEADER.update_seq%TYPE,
   p_approved_user_id				T_MANY_HEADER.user_id%TYPE,
   p_approved_ip_address 		 	T_MANY_HEADER.ip_address%TYPE,
   p_error_code						OUT NUMBER,
   p_error_msg						OUT VARCHAR2
)
IS
	v_client_cd 					MST_CLIENT.client_cd%TYPE;
	v_cifs							MST_CLIENT.cifs%TYPE;
	v_client_name 					MST_CLIENT.client_name%TYPE;
	v_subrek001						MST_CLIENT_REKEFEK.subrek_cd%TYPE;
	v_subrek004						MST_CLIENT_REKEFEK.subrek_cd%TYPE;
	v_acct_open_dt					DATE;
	v_brch_cd						MST_BRANCH.brch_cd%TYPE;
	v_rem_cd						MST_CLIENT.rem_cd%TYPE;
	v_client_type_1					MST_CLIENT.client_type_1%TYPE;
	v_client_type_2					MST_CLIENT.client_type_2%TYPE;
	v_client_type_3					MST_CLIENT.client_type_3%TYPE;
	v_olt							MST_CLIENT.olt%TYPE;
	v_user_id						MST_CLIENT.user_id%TYPE;
	v_upd_by						MST_CLIENT.upd_by%TYPE;
	v_affiliated 					MST_CLIENT.cust_client_flg%TYPE;
	v_custodian_cd					MST_CLIENT.custodian_cd%TYPE;
	v_int_on_receivable				MST_CLIENT.int_on_receivable%TYPE;
	v_int_on_payable				MST_CLIENT.int_on_payable%TYPE;
	v_commission_per				MST_CLIENT.commission_per%TYPE;
	
	v_branch_change_flg				NUMBER;
	v_rem_change_flg				NUMBER;
	
	--v_autho_user_id					T_APPROVE_CLIENT.autho_user_id%TYPE;
	
	v_sid							MST_CLIENT.sid%TYPE;
	v_ic_type						MST_CLIENT.ic_type%TYPE;
	v_client_ic_num					MST_CLIENT.client_ic_num%TYPE;
	
	v_to_dt							T_CLIENT_AFILIASI.to_dt%TYPE;
	
	v_cnt							NUMBER:=0;
	v_upd_flg						T_MANY_DETAIL.upd_flg%TYPE;

	v_err 							EXCEPTION;
	v_error_code					NUMBER;
	v_error_msg						VARCHAR2(200);
	v_table_name 					T_MANY_DETAIL.table_name%TYPE := 'MST_CLIENT';
	v_status        		    	T_MANY_DETAIL.upd_status%TYPE;
	v_cif_status 					T_MANY_DETAIL.upd_status%TYPE;
	v_table_rowid					T_MANY_DETAIL.table_rowid%TYPE;
	V_CNT_STATUS VARCHAR2(1);
BEGIN

BEGIN
select COUNT(1) INTO V_CNT_STATUS from app_running_status where menu_name='CONGEN' AND RUNNING_CHECK='CONGEN' AND STATUS='Y';
EXCEPTION
WHEN OTHERS THEN
	v_error_code := -120;
	v_error_msg :=  SUBSTR('SELECT RUNNING PROCESS FROM app_running_status '||SQLERRM,1,200);
	RAISE v_err;
END;
	IF V_CNT_STATUS>0 THEN
		v_error_code := -130;
		v_error_msg :=  'Sedang contract generation, silahkan tunggu beberapa saat';
		RAISE v_err;
	END IF;




	BEGIN
		SELECT STATUS INTO v_status
		FROM T_MANY_HEADER
		WHERE UPDATE_SEQ = p_update_seq
		AND UPDATE_DATE = p_update_date;
	EXCEPTION
		WHEN OTHERS THEN
			v_error_code := -2;
			v_error_msg :=  SUBSTR('Retrieve  T_MANY_HEADER for '||p_update_seq||SQLERRM,1,200);
			RAISE v_err;
	END;

	BEGIN
		SELECT MAX(CLIENT_CD), MAX(CIFS), MAX(CLIENT_NAME), MAX(SUBREK001), MAX(SUBREK004), TO_DATE(MAX(ACCT_OPEN_DT),'yyyy/mm/dd hh24:mi:ss'), MAX(BRANCH_CODE), MAX(REM_CD),
		MAX(CLIENT_TYPE_1), MAX(CLIENT_TYPE_2), MAX(CLIENT_TYPE_3), MAX(AFFILIATED), MAX(OLT), MAX(CUSTODIAN_CD), MAX(COMMISSION_PER), MAX(BRANCH_CHANGE_FLG), MAX(REM_CHANGE_FLG), MAX(USER_ID), MAX(UPD_BY)
		INTO v_client_cd, v_cifs, v_client_name, v_subrek001, v_subrek004, v_acct_open_dt, v_brch_cd, v_rem_cd, v_client_type_1, v_client_type_2, v_client_type_3, v_affiliated, v_olt, v_custodian_cd, v_commission_per, v_branch_change_flg, v_rem_change_flg, v_user_id, v_upd_by
		FROM
		(
			SELECT DECODE(field_name,'CLIENT_CD',field_value, NULL) CLIENT_CD,
				   DECODE(field_name,'CIFS',field_value, NULL) CIFS,
				   DECODE(field_name,'CLIENT_NAME',field_value, NULL) CLIENT_NAME,
				   DECODE(field_name,'SUBREK001',field_value, NULL) SUBREK001,
				   DECODE(field_name,'SUBREK004',field_value, NULL) SUBREK004,
				   DECODE(field_name,'ACCT_OPEN_DT',field_value, NULL) ACCT_OPEN_DT,
				   DECODE(field_name,'BRANCH_CODE',field_value, NULL) BRANCH_CODE,
				   DECODE(field_name,'REM_CD',field_value, NULL) REM_CD,
				   DECODE(field_name,'CLIENT_TYPE_1',field_value, NULL) CLIENT_TYPE_1,
				   DECODE(field_name,'CLIENT_TYPE_2',field_value, NULL) CLIENT_TYPE_2,
				   DECODE(field_name,'CLIENT_TYPE_3',field_value, NULL) CLIENT_TYPE_3,
				   DECODE(field_name,'CUST_CLIENT_FLG',field_value, NULL) AFFILIATED,					   
				   DECODE(field_name,'OLT',field_value, NULL) OLT,
				   DECODE(field_name,'CUSTODIAN_CD',field_value, NULL) CUSTODIAN_CD,
				   DECODE(field_name,'COMMISSION_PER',field_value, NULL) COMMISSION_PER,
				   DECODE(field_name,'BRANCH_CHANGE_FLG',field_value, NULL) BRANCH_CHANGE_FLG,
				   DECODE(field_name,'REM_CHANGE_FLG',field_value, NULL) REM_CHANGE_FLG,
				   DECODE(field_name,'USER_ID',field_value, NULL) USER_ID,
				   DECODE(field_name,'UPD_BY',field_value, NULL) UPD_BY
			FROM  T_MANY_DETAIL
			WHERE T_MANY_DETAIL.update_date = p_update_date
			AND T_MANY_DETAIL.update_seq = p_update_seq
			AND T_MANY_DETAIL.table_name = v_table_name
			AND T_MANY_DETAIL.field_name IN ('CLIENT_CD', 'CIFS', 'CLIENT_NAME', 'SUBREK001', 'SUBREK004', 'ACCT_OPEN_DT', 'BRANCH_CODE', 'REM_CD', 'CLIENT_TYPE_1','CLIENT_TYPE_2', 'CLIENT_TYPE_3', 'CUST_CLIENT_FLG', 'OLT', 'CUSTODIAN_CD', 'COMMISSION_PER', 'BRANCH_CHANGE_FLG', 'REM_CHANGE_FLG', 'USER_ID','UPD_BY')
		);
	EXCEPTION
		WHEN OTHERS THEN
			v_error_code := -3;
			v_error_msg :=  SUBSTR('Retrieve  T_MANY_DETAIL '||SQLERRM,1,200);
			RAISE v_err;
	END;
	/*
	IF v_commission_per = 0 THEN
		BEGIN
			SELECT autho_user_id INTO v_autho_user_id
			FROM T_APPROVE_CLIENT
			WHERE autho_user_id = p_approved_user_id
			AND item_name = 'KOMISI';
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				v_error_code := -4;
				v_error_msg := 'You are not authorized to approve this client';
				RAISE v_err;
				
			WHEN OTHERS THEN
				v_error_code := -5;
				v_error_msg :=  SUBSTR('Retrieve  T_APPROVE_CLIENT '||SQLERRM,1,200);
				RAISE v_err;
		END;
	END IF;*/
		
	IF v_status = 'I' THEN
		BEGIN
			SP_GEN_INTEREST_RATE_CLIENT(v_client_cd, v_acct_open_dt, v_brch_cd, v_client_type_3, v_olt, v_user_id,v_error_code, v_error_msg);
		EXCEPTION
			WHEN OTHERS THEN
				v_error_code := -6;
				v_error_msg :=  SUBSTR('SP_GEN_INTEREST_RATE_CLIENT '||SQLERRM,1,200);
				RAISE v_err;
		END;
		--06OCT 2017 KRNA UBAH GEN_INTEREST_RATE_CLIENT=>SP_GEN_INTEREST_RATE_CLIENT
    IF v_error_code<0 THEN
        v_error_code := -1003;
				v_error_msg :=  SUBSTR('SP_GEN_INTEREST_RATE_CLIENT '||v_error_msg,1,200);
				RAISE v_err;
    END IF;
    
		BEGIN
			SELECT INT_ON_RECEIVABLE, INT_ON_PAYABLE
			INTO v_int_on_receivable, v_int_on_payable
			FROM T_INTEREST_RATE
			WHERE client_cd = v_client_cd
      AND APPROVED_STAT='A';
		EXCEPTION
			WHEN OTHERS THEN
				v_error_code := -7;
				v_error_msg :=  SUBSTR('Retrieve T_INTEREST_RATE '||SQLERRM,1,200);
				RAISE v_err;
		END;
		
		BEGIN
			SP_GEN_GL_ACCOUNT_ARAP(v_client_type_1, v_client_type_2, v_client_type_3, v_affiliated, v_client_cd, v_client_name, v_brch_cd, v_user_id, v_error_code, v_error_msg);
		EXCEPTION
			WHEN OTHERS THEN
				v_error_code := -8;
				v_error_msg :=  SUBSTR('SP_GEN_GL_ACCOUNT_ARAP '||SQLERRM,1,200);
				RAISE v_err;
		END;
		
		IF v_error_code < 0 THEN
			v_error_code := -9;
			v_error_msg := 'SP_GEN_GL_ACCOUNT_ARAP '||v_error_msg;
			RAISE v_err;
		END IF;

		BEGIN
			UPDATE T_MANY_DETAIL 
			SET FIELD_VALUE = v_int_on_payable 
			WHERE UPDATE_SEQ = p_update_seq 
			AND UPDATE_DATE = p_update_date 
			AND TABLE_NAME = 'MST_CLIENT' 
			AND FIELD_NAME = 'INT_ON_PAYABLE';
		EXCEPTION
			WHEN OTHERS THEN
				v_error_code := -10;
				v_error_msg := SUBSTR('UPDATE T_MANY_DETAIL '||SQLERRM,1,200);
				RAISE v_err;
		END;
		
		BEGIN
			UPDATE T_MANY_DETAIL 
			SET FIELD_VALUE = v_int_on_receivable 
			WHERE UPDATE_SEQ = p_update_seq 
			AND UPDATE_DATE = p_update_date 
			AND TABLE_NAME = 'MST_CLIENT' 
			AND FIELD_NAME = 'INT_ON_RECEIVABLE';
		EXCEPTION
			WHEN OTHERS THEN
				v_error_code := -11;
				v_error_msg := SUBSTR('UPDATE T_MANY_DETAIL '||SQLERRM,1,200);
				RAISE v_err;
		END;
	ELSIF v_status = 'U' THEN
		BEGIN
			SELECT COUNT(1) INTO v_cnt
			FROM T_MANY_DETAIL
			WHERE UPDATE_DATE = p_update_date
			AND UPDATE_SEQ = p_update_seq
			AND TABLE_NAME = 'MST_CLIENT'
			AND FIELD_NAME IN ('CLIENT_NAME','BRANCH_CODE','CUST_CLIENT_FLG')
			AND UPD_FLG = 'Y';
		EXCEPTION
			WHEN OTHERS THEN
				v_error_code := -12;
				v_error_msg := SUBSTR('RETRIEVE T_MANY_DETAIL '||SQLERRM,1,200);
				RAISE v_err;
		END;
		
		IF v_cnt > 0 THEN
			BEGIN
				SP_GEN_GL_ACCOUNT_ARAP(v_client_type_1, v_client_type_2, v_client_type_3, v_affiliated, v_client_cd, v_client_name, v_brch_cd, v_user_id, v_error_code, v_error_msg);
			EXCEPTION
				WHEN OTHERS THEN
					v_error_code := -13;
					v_error_msg :=  SUBSTR('SP_GEN_GL_ACCOUNT_ARAP '||SQLERRM,1,200);
					RAISE v_err;
			END;
			
			IF v_error_code < 0 THEN
				v_error_code := -14;
				v_error_msg := 'SP_GEN_GL_ACCOUNT_ARAP '||v_error_msg;
				RAISE v_err;
			END IF;
		END IF;
		/* --comment by AS: 05 Oct 2017 --update flag OLT tidak boleh mempengaruhi interest rate
		BEGIN
			SELECT COUNT(1) INTO v_cnt
			FROM T_MANY_DETAIL
			WHERE UPDATE_DATE = p_update_date
			AND UPDATE_SEQ = p_update_seq
			AND TABLE_NAME = 'MST_CLIENT'
			AND FIELD_NAME = 'OLT'
			AND UPD_FLG = 'Y';
		EXCEPTION
			WHEN OTHERS THEN
				v_error_code := -15;
				v_error_msg := SUBSTR('RETRIEVE T_MANY_DETAIL '||SQLERRM,1,200);
				RAISE v_err;
		END;
		
		IF v_cnt > 0 THEN
			BEGIN
				GEN_INTEREST_RATE_CLIENT(v_client_cd, v_acct_open_dt, v_brch_cd, v_client_type_3, v_olt, v_user_id);
			EXCEPTION
				WHEN OTHERS THEN
					v_error_code := -16;
					v_error_msg :=  SUBSTR('GEN_INTEREST_RATE_CLIENT '||SQLERRM,1,200);
					RAISE v_err;
			END;
		END IF;*/
	END IF;
	
	IF v_status = 'U' THEN
		v_cif_status := 'U';
	ELSE
		BEGIN
			SELECT UPD_STATUS INTO v_cif_status
			FROM T_MANY_DETAIL
			WHERE UPDATE_SEQ = p_update_seq
			AND UPDATE_DATE = p_update_date
			AND TABLE_NAME = 'MST_CIF'
			AND ROWNUM = 1;
		EXCEPTION
			WHEN OTHERS THEN
				v_error_code := -17;
				v_error_msg :=  SUBSTR('Retrieve T_MANY_DETAIL '||SQLERRM,1,200);
				RAISE v_err;
		END;
	END IF;
	
	IF v_user_id IS NULL THEN
		v_user_id := v_upd_by;
	END IF;
	
	BEGIN
		IF v_custodian_cd IS NULL THEN
			IF v_cif_status = 'I' THEN  -- NEW CIF
				UPD_REKEFEK(v_client_cd, v_cifs, v_subrek001, NULL, 'A', v_user_id);
			ELSE                        -- EXISTING CIF
				BEGIN
					SELECT COUNT(1) INTO v_cnt
					FROM MST_CLIENT_REKEFEK
					WHERE CIFS = v_cifs
					AND SUBSTR(SUBREK_CD,10,3) = '004';
				EXCEPTION
					WHEN OTHERS THEN
						v_error_code := -18;
						v_error_msg :=  SUBSTR('Retrieve MST_CLIENT_REKEFEK '||SQLERRM,1,200);
						RAISE v_err;
				END;
				
				--IF v_cnt = 0 AND v_subrek004 <> 'YJ001000000492' THEN -- Belum punya subrek004
				--	UPD_REKEFEK(v_client_cd, v_cifs, v_subrek001, v_subrek004, 'A', v_user_id);
				--ELSE
				--	UPD_REKEFEK(v_client_cd, v_cifs, v_subrek001, NULL, 'A', v_user_id);
				--END IF;
				
				IF SUBSTR(v_subrek004,6,7) <> '0000004' THEN
					UPD_REKEFEK(v_client_cd, v_cifs, v_subrek001, v_subrek004, 'A', v_user_id);
				ELSE
					UPD_REKEFEK(v_client_cd, v_cifs, v_subrek001, NULL, 'A', v_user_id);
				END IF;
			END IF;
--		ELSE
--			UPD_REKEFEK(v_client_cd, v_cifs, NULL, NULL, 'A', v_user_id);
		END IF;
	EXCEPTION
		WHEN OTHERS THEN
			v_error_code := -19;
			v_error_msg :=  SUBSTR('UPD_REKEFEK '||SQLERRM,1,200);
			RAISE v_err;	
	END;
	
	BEGIN
		UPDATE T_MANY_DETAIL 
		SET FIELD_VALUE = FIELD_VALUE * 100 
		WHERE UPDATE_SEQ = p_update_seq 
		AND UPDATE_DATE = p_update_date 
		AND FIELD_NAME IN ('REBATE','COMMISSION_PER','COMMISSION_PER_BUY','COMMISSION_PER_SELL'); --RD ADD REBATE 2 OKTOBER 2017
	EXCEPTION
		WHEN OTHERS THEN
			v_error_code := -20;
			v_error_msg := SUBSTR('UPDATE T_MANY_DETAIL '||SQLERRM,1,200);
			RAISE v_err;
	END;
	
	BEGIN
		SP_T_MANY_APPROVE(p_menu_name, p_update_date, p_update_seq, p_approved_user_id, p_approved_ip_address, v_error_code, v_error_msg); 
	EXCEPTION
		WHEN OTHERS THEN
			v_error_code := -21;
			v_error_msg := SUBSTR('SP_T_MANY_APPROVE '||SQLERRM,1,200);
			RAISE v_err;
	END;
	
	IF v_error_code < 0 THEN
		v_error_code := -22;
		v_error_msg := 'SP_T_MANY_APPROVE '||v_error_msg;
		RAISE v_err;
	END IF; 
	
	BEGIN
		UPDATE T_MANY_DETAIL 
		SET FIELD_VALUE = FIELD_VALUE / 100 
		WHERE UPDATE_SEQ = p_update_seq 
		AND UPDATE_DATE = p_update_date 
		AND FIELD_NAME IN ('REBATE','COMMISSION_PER','COMMISSION_PER_BUY','COMMISSION_PER_SELL'); --RD ADD REBATE 2 OKTOBER 2017
	EXCEPTION
		WHEN OTHERS THEN
			v_error_code := -23;
			v_error_msg := SUBSTR('UPDATE T_MANY_DETAIL '||SQLERRM,1,200);
			RAISE v_err;
	END;
	
	BEGIN
		SELECT SID, CLIENT_IC_NUM, IC_TYPE 
		INTO v_sid, v_client_ic_num, v_ic_type
		FROM MST_CIF 
		WHERE cifs = v_cifs;
	EXCEPTION
		WHEN OTHERS THEN 
			v_error_code := -24;
			v_error_msg :=  SUBSTR('Retrieve MST_CIF '||SQLERRM,1,200);
			RAISE v_err;
	END;
	
	BEGIN
		UPDATE MST_CLIENT
		SET SID = v_sid, CLIENT_IC_NUM = v_client_ic_num, IC_TYPE = v_ic_type, CLIENT_TYPE_2 = v_client_type_2
		WHERE cifs = v_cifs
		AND susp_stat = 'N';
	EXCEPTION
		WHEN OTHERS THEN 
			v_error_code := -25;
			v_error_msg :=  SUBSTR('UPDATE MST_CLIENT '||SQLERRM,1,200);
			RAISE v_err;
	END;
	
	BEGIN
		SELECT TO_DT INTO v_to_dt
		FROM T_CLIENT_AFILIASI
		WHERE CLIENT_CD = v_client_cd;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			v_to_dt := NULL;
		WHEN OTHERS THEN 
			v_error_code := -26;
			v_error_msg :=  SUBSTR('RETRIEVE T_CLIENT_AFILIASI '||SQLERRM,1,200);
			RAISE v_err;
	END;
	
	IF v_affiliated = 'A' THEN
		IF v_to_dt IS NULL THEN
			BEGIN
				INSERT INTO T_CLIENT_AFILIASI (FROM_DT, TO_DT, CLIENT_CD, USER_ID, CRE_DT, APPROVED_BY, APPROVED_DT, APPROVED_STS)
				VALUES(TRUNC(SYSDATE), TO_DATE('2050-01-01','YYYY-MM-DD'), v_client_cd, NVL(v_upd_by, v_user_id), SYSDATE, p_approved_user_id, SYSDATE, 'A');
			EXCEPTION
				WHEN OTHERS THEN 
					v_error_code := -27;
					v_error_msg :=  SUBSTR('INSERT TO T_CLIENT_AFILIASI '||SQLERRM,1,200);
					RAISE v_err;
			END;
		ELSIF v_to_dt < TO_DATE('2050-01-01','YYYY-MM-DD') THEN
			BEGIN
				UPDATE T_CLIENT_AFILIASI
				SET TO_DT = TO_DATE('2050-01-01','YYYY-MM-DD'),
				UPD_BY = v_upd_by,
				UPD_DT = SYSDATE
				WHERE CLIENT_CD = v_client_cd;
			EXCEPTION
				WHEN OTHERS THEN 
					v_error_code := -28;
					v_error_msg :=  SUBSTR('UPDATE T_CLIENT_AFILIASI '||SQLERRM,1,200);
					RAISE v_err;
			END;
		END IF;	
	ELSE
		IF v_to_dt IS NOT NULL AND v_to_dt = TO_DATE('2050-01-01','YYYY-MM-DD') THEN
			BEGIN
				UPDATE T_CLIENT_AFILIASI
				SET TO_DT = TRUNC(SYSDATE) - 1,
				UPD_BY = v_upd_by,
				UPD_DT = SYSDATE
				WHERE CLIENT_CD = v_client_cd;
			EXCEPTION
				WHEN OTHERS THEN 
					v_error_code := -29;
					v_error_msg :=  SUBSTR('UPDATE T_CLIENT_AFILIASI '||SQLERRM,1,200);
					RAISE v_err;
			END;
		END IF;
	END IF;	
	
	IF v_branch_change_flg = 1 THEN
		BEGIN
			UPDATE MST_CLIENT
			SET BRANCH_CODE = v_brch_cd
			WHERE cifs = v_cifs
			AND susp_stat = 'N';
		EXCEPTION
			WHEN OTHERS THEN 
				v_error_code := -30;
				v_error_msg :=  SUBSTR('UPDATE MST_CLIENT '||SQLERRM,1,200);
				RAISE v_err;
		END;
	END IF;
	
	IF v_rem_change_flg = 1 THEN
		BEGIN
			UPDATE MST_CLIENT
			SET REM_CD = v_rem_cd
			WHERE cifs = v_cifs
			AND susp_stat = 'N';
		EXCEPTION
			WHEN OTHERS THEN 
				v_error_code := -31;
				v_error_msg :=  SUBSTR('UPDATE MST_CLIENT '||SQLERRM,1,200);
				RAISE v_err;
		END;
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
		p_error_code := -1;
		p_error_msg := SUBSTR(SQLERRM,1,200);
		ROLLBACK;
		RAISE;
END SP_MST_CLIENT_APPROVE;