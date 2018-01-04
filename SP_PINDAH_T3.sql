create or replace 
PROCEDURE Sp_Pindah_T3 (p_due_date DATE,
						P_IP_ADDRESS VARCHAR2,
					   p_user_id   T_ACCOUNT_LEDGER.user_id%TYPE,
					   p_error_code OUT NUMBER,
					   p_error_msg OUT VARCHAR2)
IS
-- 7 sep 15 dirubah spy dpt dipakai di PF , 
--        field budget_Cd, netting flg diisi
--        pakai F_GL_ACCT_T3_SEP2015
--23jun15 sdh dirubah/tes utk NEXTG
--16jun15 - tambah MANUAL di T A L
-- 12dec2014 AND REVERSAL_JUR = 'N'
-- 13MAR 12 client 2490 kalo Debit pindah ke 1422
-- 10jun09

v_jurnum 		 T_ACCOUNT_LEDGER.xn_doc_num%TYPE;
v_rtn    		 NUMBER;
v_db_cr_flg      T_ACCOUNT_LEDGER.db_cr_flg%TYPE;
v_deb            T_ACCOUNT_LEDGER.curr_val%TYPE;
v_cre            T_ACCOUNT_LEDGER.curr_val%TYPE;
v_ledger_nar     T_ACCOUNT_LEDGER.ledger_nar%TYPE;
v_doc_date		 T_ACCOUNT_LEDGER.doc_date%TYPE;
v_ar_acct1 		 T_ACCOUNT_LEDGER.gl_acct_cd%TYPE;
--v_ar_acct2		 T_ACCOUNT_LEDGER.gl_acct_cd%TYPE;
v_ap_acct1		 T_ACCOUNT_LEDGER.gl_acct_cd%TYPE;
--v_ap_acct2 		 T_ACCOUNT_LEDGER.gl_acct_cd%TYPE;

--v_2490_mkbd_cd    MST_GL_ACCOUNT.mkbd_cd%TYPE;
--v_2490_mkbd_group    MST_GL_ACCOUNT.mkbd_group%TYPE;
v_acct_type			   T_ACCOUNT_LEDGER.acct_type%TYPE;
v_jur_type			      T_ACCOUNT_LEDGER.budget_Cd%TYPE := 'TRF3';

v_nl             CHAR(2);
v_mmyy           T_FOLDER.FLD_MON%TYPE;
v_nextval NUMBER;
V_SQL VARCHAR2(200);
v_error_code NUMBER(5);
v_error_msg VARCHAR2(200);
v_err  EXCEPTION;
p_journal_dt DATE:=p_due_date;
p_folder_cd VARCHAR2(10):='MJ-T3';
V_REMARKS VARCHAR2(50);
V_UPDATE_DATE DATE;
V_UPDATE_SEQ NUMBER(7);
V_MENU_NAME VARCHAR2(50):='TRANSFER AR/AP ON T3';
V_CNT NUMBER;
BEGIN
v_nl := CHR(10)||CHR(13);

v_doc_date := Get_Doc_Date(3, p_due_date);

	BEGIN
SELECT MAX(DECODE(db_Cr_flg,'D',gl_a,NULL)) ar_acct,
	   				MAX(DECODE(db_Cr_flg,'C',gl_a,NULL)) ap_acct
		INTO    	v_ar_acct1, 		v_ap_acct1
FROM v_gl_acct_type
WHERE acct_type = 'CLIE';
EXCEPTION
WHEN NO_DATA_FOUND THEN
			v_error_code := -5;
			v_error_msg := SUBSTR(' v_gl_acct_type for type CLIE not found '||SQLERRM,1,200);
			RAISE v_err;
	WHEN OTHERS THEN
			v_error_code := -6;
			v_error_msg := SUBSTR('v_gl_acct_type '||SQLERRM,1,200);
			RAISE v_err;		
	END;
--v_ar_acct1 := '1421';--p_ar_acct;
--v_ap_acct1 := '2421';--p_ap_acct;
--v_ar_acct2 := '1431';
--v_ap_acct2 := '2431';

/*
-- get mkbd_Cd acct 2490

begin
SELECT mkbd_cd, mkbd_group INTO
       v_2490_mkbd_cd, v_2490_mkbd_group
FROM MST_GL_ACCOUNT
WHERE gl_a = '2490'
AND sl_a = '000000';
exception
WHEN OTHERS THEN
			v_error_code := -5;
			v_error_msg := SUBSTR('MST_GL_ACCOUNT '||SQLERRM,1,200);
			RAISE v_err;
	END;
*/

	BEGIN
	SELECT dstr1 INTO v_acct_type
	FROM MST_SYS_PARAM
	WHERE param_id = 'PINDAH_T3'
	AND param_cd1 = 'ACCTTYPE';
	EXCEPTION
	WHEN OTHERS THEN
			v_error_code := -7;
			v_error_msg := SUBSTR('MST_GL_ACCOUNT '||SQLERRM,1,200);
			RAISE v_err;
	END;
	
    -- get GL NUMber
	v_jurnum  := Get_Docnum_Gl(p_journal_dt,'GL');

--	v_jurnum  := SUBSTR(v_jurnum,1,6)||'A'||SUBSTR(v_jurnum,8,7);

	BEGIN
		SELECT SEQ_TAL_ID.NEXTVAL INTO v_NEXTVAL FROM dual;
	EXCEPTION
 	WHEN OTHERS THEN
	 v_error_code := -10;
			v_error_msg := SUBSTR('NEXT VAL SEQUENCE SEQ_TAL_ID'||v_jurnum||v_nl||SQLERRM,1,200);
			RAISE v_err;
 	END;

	v_sql := 'alter sequence SEQ_TAL_ID increment by -' || TO_CHAR(v_NEXTVAL) || ' minvalue 0';
	BEGIN
		EXECUTE IMMEDIATE v_sql;
	EXCEPTION
WHEN OTHERS THEN
	 ROLLBACK;
          	v_error_code := -15;
			v_error_msg :=SUBSTR('alter SEQUENCE SEQ_TAL_ID'||v_nl||SQLERRM,1,200);
            RAISE v_err;
 	END;


	BEGIN
		SELECT SEQ_TAL_ID.NEXTVAL
		INTO v_NEXTval
		FROM dual;
	EXCEPTION
	WHEN OTHERS THEN
	 	v_error_code := -20;
			v_error_msg :=SUBSTR('GET NEXT VAL  SEQUENCE SEQ_TAL_ID'||v_nl||SQLERRM,1,200);
            RAISE v_err;
 	END;

	BEGIN
		EXECUTE IMMEDIATE 'alter sequence SEQ_TAL_ID increment by 1';
	EXCEPTION
	WHEN OTHERS THEN
	 v_error_code := -25;
			v_error_msg :=SUBSTR('GET NEXT VAL  SEQUENCE SEQ_TAL_ID'||v_nl||SQLERRM,1,200);
            RAISE v_err;
 	END;



V_REMARKS := 'TRANSFER AR/AP FROM '||TO_CHAR(v_doc_date,'dd/mm/yy');


--EXECUTE T MANY HEADER
  BEGIN
        Sp_T_Many_Header_Insert(V_MENU_NAME,
								 'I',
								 P_USER_ID,
								 P_IP_ADDRESS,
								 NULL,
								 V_UPDATE_DATE,
								 V_UPDATE_SEQ,
								 v_error_code,
								 v_error_msg);
        EXCEPTION
              WHEN OTHERS THEN
                 v_error_code := -30;
                 v_error_msg := SUBSTR('SP_T_MANY_HEADER_INSERT '|| SQLERRM(SQLCODE),1,200);
                RAISE V_ERR;
            END;

		IF V_ERROR_CODE<0 THEN
					v_error_code := -35;
					v_error_msg :=SUBSTR('Sp_T_Many_Header_Insert : '||SQLERRM(SQLCODE),1,200);
					RAISE v_err;
		END IF;
	
	/*	
	BEGIN
	INSERT INTO T_JVCHH (
	   JVCH_NUM, JVCH_TYPE, JVCH_DATE,
	   GL_ACCT_CD, SL_ACCT_CD, CURR_CD,
	   CURR_AMT, REMARKS, USER_ID,
	   CRE_DT, UPD_DT, APPROVED_STS,
	   APPROVED_BY, APPROVED_DT, FOLDER_CD,reversal_jur)
	VALUES ( v_jurnum, 'P3', p_journal_dt,
	    NULL, NULL, 'IDR',
	    0, 'TRANSFER AR/AP FROM '||TO_CHAR(v_doc_date,'dd/mm/yy'), p_user_id,
	    SYSDATE, NULL, 'A',
	    p_user_id, sysdate, p_folder_cd,'N');
	EXCEPTION
	  WHEN OTHERS THEN
	   v_error_code := -30;
			v_error_msg :=SUBSTR('Error insert to T_JVCHH : '||v_jurnum||v_nl||SQLERRM,1,200);
            RAISE v_err;
	END;
*/


	
	v_ledger_nar := 'REVERSAL TR '||TO_CHAR(v_doc_date,'dd/mm/yy');

	BEGIN
	INSERT INTO T_ACCOUNT_LEDGER(XN_DOC_NUM,TAL_ID,
			ACCT_TYPE, SL_ACCT_CD, GL_ACCT_CD,
			BRCH_CD, CURR_VAL, SETT_VAL, DB_CR_FLG,
			LEDGER_NAR,  USER_ID, CRE_DT,
			DOC_DATE, DUE_DATE , RECORD_SOURCE,
			APPROVED_DT, APPROVED_STS, FOLDER_CD,
			MANUAL,approved_by,xn_val,
			budget_Cd)
	SELECT v_jurnum, seq_tal_id.NEXTVAL,
	 A.acct_type, A.sl_acct_cd, A.gl_acct_cd,
	 A.brch_cd, A.amt, A.amt, A.dbcr,
	 v_ledger_nar, p_user_id, SYSDATE,
	 p_journal_dt, p_due_date, 'CDUE',
	 SYSDATE, 'A', p_folder_cd,
	 'N',p_user_id,A.amt,
	 v_jur_type
	FROM (
	SELECT  acct_type, sl_acct_cd, gl_acct_cd,  brch_cd, SUM(curr_val - NVL(sett_val, 0)) amt,
	DECODE(db_cr_flg,'D','C','D') dbcr
	FROM T_ACCOUNT_LEDGER
	WHERE doc_date BETWEEN v_doc_date AND p_due_date  
	AND due_date = p_due_date
	AND gl_acct_cd IN (v_AR_acct1, v_AP_acct1	)
	AND record_source = 'CG'
	AND approved_sts <> 'C'
	AND REVERSAL_JUR = 'N'
--	and tal_id = 1  SPY TITIP YG TAL_ID = 2 TIDAK HILANG
	AND NVL(sett_val, 0) < curr_val
	AND NVL(sett_for_curr, 0) = 0
	GROUP BY sl_acct_cd, acct_type, gl_acct_cd, brch_cd, db_cr_flg) A;
	EXCEPTION
	WHEN OTHERS THEN
			v_error_code := -50;
			v_error_msg :=SUBSTR('Reversal of AR/AP to T_ACCOUNT_LEDGER  '||v_nl||SQLERRM,1,200);
            RAISE v_err;
	END;


	-- reversal partial settled
	BEGIN
	INSERT INTO T_ACCOUNT_LEDGER(XN_DOC_NUM,TAL_ID,
			ACCT_TYPE, SL_ACCT_CD, GL_ACCT_CD,
			BRCH_CD, CURR_VAL, SETT_VAL, DB_CR_FLG,
			LEDGER_NAR,  USER_ID, CRE_DT,
			DOC_DATE, DUE_DATE , RECORD_SOURCE,
			 APPROVED_DT, APPROVED_STS, FOLDER_CD,
			MANUAL,approved_by,xn_val,
			budget_Cd)
	SELECT v_jurnum, seq_tal_id.NEXTVAL,
	 A.acct_type, A.sl_acct_cd, F_Gl_Acct_T3_Sep2015(a.sl_acct_cd, a.db_cr_flg),
	 A.brch_cd, A.amt, A.amt, A.dbcr,
	 v_ledger_nar, p_user_id, SYSDATE,
	 p_journal_dt, p_due_date, 'CDUE',
	 SYSDATE, 'A', p_folder_cd,
	 'N',p_user_id,A.amt,
	 v_jur_type
	FROM (
	SELECT  acct_type, sl_acct_cd, gl_acct_cd,  brch_cd,db_cr_flg, SUM(NVL(sett_val, 0)) amt,
	DECODE(db_cr_flg,'D','C','D') dbcr
	FROM T_ACCOUNT_LEDGER
	WHERE doc_date BETWEEN v_doc_date AND p_due_date  
	AND   due_date = p_due_date
	AND gl_acct_cd IN (v_AR_acct1, v_AP_acct1	)
	AND record_source = 'CG'
	AND approved_sts <> 'C'
	AND REVERSAL_JUR = 'N'
--	and tal_id = 1  SPY TITIP YG TAL_ID = 2 TIDAK HILANG
	AND NVL(sett_val, 0) < curr_val
	AND NVL(sett_val, 0) > 0
	AND NVL(sett_for_curr, 0) = 0
	GROUP BY sl_acct_cd, acct_type, gl_acct_cd, brch_cd, db_cr_flg) A;
	EXCEPTION
	WHEN OTHERS THEN
			v_error_code := -55;
			v_error_msg :=SUBSTR('Reversal of AR/AP to T_ACCOUNT_LEDGER  '||v_nl||SQLERRM,1,200);
            RAISE v_err;
	END;


--dikomen 7sep15 SELECT v_jurnum, seq_tal_id.NEXTVAL, DECODE(SUBSTR(xn_doc_num,6,1),'I',doc_ref_num, xn_doc_num),
	BEGIN
	INSERT INTO T_ACCOUNT_LEDGER(XN_DOC_NUM,TAL_ID, Doc_ref_num,
			ACCT_TYPE, SL_ACCT_CD, GL_ACCT_CD,
			BRCH_CD, CURR_VAL, 	DB_CR_FLG,
			LEDGER_NAR,  USER_ID, CRE_DT,
			DOC_DATE, DUE_DATE , RECORD_SOURCE,
			 APPROVED_DT, APPROVED_STS, FOLDER_CD,
			MANUAL, NETTING_DATE, NETTING_FLG,
			 SETT_VAL,approved_by,xn_val,
			budget_Cd)
	SELECT v_jurnum, seq_tal_id.NEXTVAL, xn_doc_num,
	 v_acct_type, sl_acct_cd, F_Gl_Acct_T3_Sep2015(sl_acct_cd, db_cr_flg),  brch_cd, curr_val, db_cr_flg,
	 ledger_nar, p_user_id, SYSDATE,
	 p_journal_dt, due_date, 'CDUE',
	 SYSDATE, 'A', p_folder_cd,
	  'N', doc_date, '1',
	 NVL(sett_val, 0),p_user_id,curr_val,
	 v_jur_type
	FROM T_ACCOUNT_LEDGER
	WHERE doc_date BETWEEN v_doc_date AND p_due_date  
	AND   due_date = p_due_date
	AND gl_acct_cd IN (v_AR_acct1, v_AP_acct1	)
	AND record_source = 'CG'
	AND approved_sts <> 'C'
	AND REVERSAL_JUR = 'N'
--	and tal_id = 1     SPY TITIP YG TAL_ID = 2 TIDAK HILANG
	AND NVL(sett_val, 0) < curr_val
	AND NVL(sett_for_curr, 0) = 0;
	EXCEPTION
	WHEN OTHERS THEN
		v_error_code := -60;
			v_error_msg :=SUBSTR('Insert  to T_ACCOUNT_LEDGER  '||v_nl||SQLERRM,1,200);
            RAISE v_err;
	END;

/* tidak ada lagi
    BEGIN
	INSERT INTO t_account_ledger(XN_DOC_NUM,TAL_ID,
			ACCT_TYPE, SL_ACCT_CD, GL_ACCT_CD,
			BRCH_CD, CURR_VAL, SETT_VAL, DB_CR_FLG,
			LEDGER_NAR,  USER_ID, CRE_DT,
			DOC_DATE, DUE_DATE , RECORD_SOURCE,
			 APPROVED_STS, FOLDER_CD)
	SELECT v_jurnum, seq_tal_id.NEXTVAL,
	acct_type, sl_acct_cd, gl_acct_cd,
	brch_cd, curr_val, curr_val, DECODE(db_cr_flg,'D','C','D') dbcr,
	'REVERSAL MINFEE '||TO_CHAR(doc_date,'dd/mm/yy'), p_user_id, SYSDATE,
	 p_journal_dt, p_due_date, 'MDUE',
	 'A', p_folder_cd
	FROM t_account_ledger
	WHERE  due_date = p_due_date
	AND gl_acct_cd IN (v_AR_acct1, v_AP_acct1	)
	AND record_source = 'GL'
	AND approved_sts <> 'C'
	AND SUBSTR(xn_doc_num,8,3) = 'MFE'
	AND NVL(sett_val, 0) = 0
	AND NVL(sett_for_curr, 0) = 0;
	EXCEPTION
	WHEN OTHERS THEN
	RAISE_APPLICATION_ERROR(-20100,'Reversal of MINFEE on T_ACCOUNT_LEDGER  '||v_nl||SQLERRM);
	END;


	BEGIN
	INSERT INTO t_account_ledger(XN_DOC_NUM,TAL_ID, Doc_ref_num,
			ACCT_TYPE, SL_ACCT_CD, GL_ACCT_CD,
			BRCH_CD, CURR_VAL, 	DB_CR_FLG,
			LEDGER_NAR,  USER_ID, CRE_DT,
			DOC_DATE, DUE_DATE , RECORD_SOURCE,
			 APPROVED_STS, FOLDER_CD, NETTING_DATE)
	SELECT v_jurnum, seq_tal_id.NEXTVAL, xn_doc_num,
	 'AR', sl_acct_cd, F_Gl_Acct_T3(sl_acct_cd),  brch_cd, curr_val, db_cr_flg,
	 ledger_nar, p_user_id, SYSDATE,
	 p_journal_dt, due_date, 'MDUE',
	 'A', p_folder_cd, doc_date
	FROM t_account_ledger
	WHERE  due_date = p_due_date
	AND gl_acct_cd IN (v_AR_acct1, v_AP_acct1, v_AR_acct2, v_AP_acct2	)
	AND record_source = 'DNCN'
	AND approved_sts <> 'C'
	AND SUBSTR(xn_doc_num,8,3) = 'MFE'
	AND NVL(sett_val, 0) = 0
	AND NVL(sett_for_curr, 0) = 0;
	EXCEPTION
	WHEN OTHERS THEN
	RAISE_APPLICATION_ERROR(-20100,'insert of MINFEE '||p_new_acct||' on T_ACCOUNT_LEDGER  '||v_nl||SQLERRM);
	END;
*/


		--- create records on MST_GL_ACCOUNT 2490
/* 8JAN15
	BEGIN
    INSERT INTO MST_GL_ACCOUNT
(gl_acct_cd,  ACCT_NAME, ACCT_TYPE, DB_CR_FLG, ACCT_SHORT,
 PRT_TYPE, ACCT_STAT, USER_ID, CRE_DT,
 MKBD_CD, MKBD_GROUP, GL_A, SL_A)
SELECT DISTINCT  '2490'||trim(t.sl_acct_cd), c.client_name, 'AP', 'C', '2490',
'D', 'A', p_user_id, SYSDATE, v_2490_mkbd_cd, v_2490_mkbd_group, '2490', trim(t.sl_acct_cd)
	FROM T_ACCOUNT_LEDGER t, MST_CLIENT c
	WHERE  t.due_date = p_due_date
	AND t.gl_acct_cd IN (v_AR_acct1, v_AP_acct1	)
	AND t.record_source = 'CG'
	AND t.approved_sts <> 'C'
	--and t.tal_id = 1
	AND NVL(t.sett_val, 0) < curr_val
	AND NVL(t.sett_for_curr, 0) = 0
	AND t.sl_acct_cd = c.client_cd
 AND NVL(c.RECOV_CHARGE_FLG,'N') = 'Y'
	AND  NOT EXISTS
	(SELECT m.gl_acct_cd
	FROM MST_GL_ACCOUNT m
	WHERE m.gl_a = '2490'
	   AND m.sl_a = t.sl_acct_cd
	   AND m.acct_stat = 'A');
	EXCEPTION
	WHEN OTHERS THEN
	RAISE_APPLICATION_ERROR(-20100,'Insert '||v_2490_mkbd_cd||' '||v_2490_mkbd_group||' '||'2490'||' '||' to MST_GL_ACCOUNT  '||v_nl||SQLERRM);
	END;
*/



	BEGIN
	UPDATE T_ACCOUNT_LEDGER
	SET sett_val = curr_val,
	    rvpv_number = v_jurnum,
		upd_dt = SYSDATE
	WHERE doc_date BETWEEN v_doc_date AND p_due_date  
	AND   due_date = p_due_date
	AND gl_acct_cd IN (v_AR_acct1, v_AP_acct1	)
	AND record_source = 'CG'
	AND approved_sts <> 'C'
	AND NVL(sett_val, 0) < curr_val
	AND NVL(sett_for_curr, 0) = 0;
	EXCEPTION
	WHEN OTHERS THEN
	v_error_code := -65;
			v_error_msg :=SUBSTR('Update sett_val '||v_ar_acct1||'/'||v_ap_acct1||' on T_ACCOUNT_LEDGER  '||v_nl||SQLERRM,1,200);
            RAISE v_err;
	END;


/* tidak ada min fee
    BEGIN
	UPDATE t_account_ledger
	SET sett_val = curr_val,
	    rvpv_number = v_jurnum,
		upd_dt = SYSDATE
	WHERE  due_date = p_due_date
	AND gl_acct_cd IN (v_AR_acct1, v_AP_acct1	)
	AND record_source = 'DNCN'
	AND approved_sts <> 'C'
	AND SUBSTR(xn_doc_num,8,3) = 'MFE'
	AND NVL(sett_val, 0) = 0
	AND NVL(sett_for_curr, 0) = 0;
	EXCEPTION
	WHEN OTHERS THEN
	RAISE_APPLICATION_ERROR(-20100,'Update sett_val MFE '||p_ar_acct||'/'||p_ap_acct||' on T_ACCOUNT_LEDGER  '||v_nl||SQLERRM);
	END;
*/

	BEGIN
		SELECT SUM(DECODE(db_cr_flg,'D',curr_val, 0)), SUM(DECODE(db_cr_flg,'C',curr_val, 0)), COUNT(1)
		INTO v_deb, v_cre, V_CNT
		FROM T_ACCOUNT_LEDGER
		WHERE xn_doc_num = v_jurnum;
	EXCEPTION
	WHEN OTHERS THEN
			v_error_code := -70;
			v_error_msg :=SUBSTR('SELECT COUNT T_ACCOUNT_LEDGER '||SQLERRM,1,200);
            RAISE v_err;
	END;

	
	
	IF v_deb <> v_cre THEN
			v_error_code := -85;
			v_error_msg :=SUBSTR('Journal is not balance !!! '||v_nl||SQLERRM,1,200);
            RAISE v_err;
	 END IF;
	   
	   	--	UPDATE T_JVCHH
	   	--	SET curr_amt = v_deb
	   	--	WHERE jvch_num = v_jurnum;
		
-- 	BEGIN
-- 		SELECT COUNT(1) INTO V_CNT FROM T_ACCOUNT_LEDGER WHERE XN_DOC_NUM= v_jurnum;
-- 	EXCEPTION
-- 	WHEN OTHERS THEN
-- 			v_error_code := -80;
-- 			v_error_msg :=SUBSTR('SELECT T_ACCOUNT_LEDGER '||SQLERRM,1,200);
--             RAISE v_err;
-- 	END;
	
	IF V_CNT=0 THEN
		v_error_code := -83;
			v_error_msg :='No Data Found to Transfer AR/AP';
            RAISE v_err;
	END IF;
		--INSERT KE T_MANY

		BEGIN
		Sp_T_Jvchh_Upd(v_jurnum,
						v_jurnum,
						'P3',
						p_journal_dt,
						NULL,
						NULL,
						'IDR',
						v_deb,
						V_REMARKS,
						P_USER_ID,
						SYSDATE,
						NULL,
						P_FOLDER_CD,
						'N',
						'I',
						p_ip_address,
						NULL,
						V_UPDATE_DATE,
						V_UPDATE_SEQ,
						1,
						v_error_code,
						v_error_msg);
		EXCEPTION
			  WHEN OTHERS THEN
			   v_error_code := -90;
					v_error_msg :=SUBSTR('Sp_T_JVCHH_Upd: '||v_jurnum||v_nl||SQLERRM,1,200);
					RAISE v_err;
			END;

		IF V_ERROR_CODE<0 THEN
					v_error_code := -95;
					v_error_msg :=SUBSTR('Sp_T_JVCHH_Upd : '||v_jurnum||v_nl||SQLERRM,1,200);
					RAISE v_err;
		END IF;

	
	BEGIN
		 Sp_T_Many_Approve( V_MENU_NAME,
						   V_update_date,
						   V_UPDATE_SEQ,
						   p_user_id,
						   p_ip_address,
						   v_error_code,
						   v_error_msg);
	EXCEPTION
			  WHEN OTHERS THEN
			   v_error_code := -105;
					v_error_msg :=SUBSTR('Sp_T_Many_Approve: '||SQLERRM,1,200);
					RAISE v_err;
			END;

		IF V_ERROR_CODE<0 THEN
					v_error_code := -110;
					v_error_msg :=SUBSTR('Sp_T_Many_Approve : '||SQLERRM,1,200);
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
		ROLLBACK;
		p_error_code := -1;
		p_error_msg := SUBSTR(SQLERRM,1,200);
		RAISE;
END Sp_Pindah_T3;
