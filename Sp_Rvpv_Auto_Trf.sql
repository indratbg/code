create or replace PROCEDURE Sp_Rvpv_Auto_Trf (
	p_due_date			DATE,
	p_brch_cd 			MST_BRANCH.brch_cd%TYPE,
	p_fund_bank_cd 		MST_FUND_BANK.bank_cd%TYPE,
	p_arap 				MST_BRANCH.brch_cd%TYPE,
	p_ap_vch 			OUT NUMBER,
	p_ar_vch 			OUT NUMBER,
	p_success_cnt		OUT NUMBER,
	p_fail_cnt			OUT NUMBER,
	p_fail_msg			OUT VARCHAR2,
	p_user_id 			T_PAYRECH.user_id%TYPE,
	p_ip_address		T_MANY_HEADER.ip_address%TYPE,
	p_error_code		OUT NUMBER,
	p_error_msg			OUT VARCHAR2
) IS
-- 3mar2017 bank tidak bulat, spy recehan di rdi  bersih
-- 29dec2016 tambah  record_source <> 'INT' jur interest sblm ahir bln
--1DEC2016 - pembetulan di  T_PAYRECD.DOC TAL ID 
--           CURSOR csr_outs, CURSOR csr_outs_full dan di SeLECT join
--14JAN15 jika RDI ACCT_STAT = 'I' dan saldo AR, tarik RDI
--                           RDI ACCT_STAT = 'I' dan saldo AP, tidak ditransfer ke RDI

--12dec14 AND REVERSAL_JUR = 'N'

-- efektif 23dec13 - memakai MST_SYS_PARAM
--10dec13 - BANKQQ diganti 1200 300031 bca, 1200 1000020 permata
--                    sementara code diganti BANKBCA dan BANKPMT

-- tambahan param p_brch_cd, p_fund_bank_cd , p_arap spy sama dg danasakti
-- akan dipakai sedikit demi sedikit

-- 03sep13 - rubah query di cursor, baca vocer RDI yg blm di approve,
--           ini utk mengulang proses auto vch, jika berhenti ditengah proses
-- 12JUN 13 sore - minimum trf diganti jadi 1 rupiah
-- 7 - 8 MAY 2013 jika RV dan outstanding ar/AP KURANG DARI jumlah yg akan diambil dr RDI
--              voucher tetap di generate
--                Jika RV dan outstanding ar/AP LEBIH  DARI jumlah yg akan diambil dr RDI,
--                        DAN selisihnya < 100,  voucher tetap di generate
--          Diluar kondisi tsb diatas , outstanding ar/AP hrs SAMA dg umlah yg akan diambil dr RDI,
--                jika tidak, voucher TIDAK di generate , insert ke T_AUTO_TRF_FAIL

-- 4 JAN 2013 mulai limit 500 rb dihapus
-- 11dec2012 mulai dipakai, spy clie 2490 yg setor ke rdi, dpt dibuatkan vocer RD
-- 27apr2012 dirubah tuk mengatasi DEVIDEN, klo yg murni regular , deviden tidak ditransfer ke RDI
--21apr2012 dirubah utk mengatasi : jika ada est keluar / masuk ,
--          tetapi tidak ada outstanging, krn sdh diambil di vch tgl ssdh hari ini
--          dlm kasus ini, vocer tidak terjadi, proses dilanjutkan

--17apr 2012 dirubah spy bisa dipake utk PERMATA
--p_client_cd mst_client.client_cd%type,
-- 09 MAR2017 [IN] PINDAHIN MST_SYS_PARAM WHERE PARAM_CD1=ROUND KE DALAM LOOPING, KARENA ROUNDING BERUBAH BERDASARKAN BANK
/******************************************************************************

   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        06/03/2012          1. Created this procedure.



******************************************************************************/

CURSOR csr_trf (a_bal_dt DATE, a_dt_end0 DATE, a_min_balance NUMBER, a_min_trf NUMBER, a_brch_cd MST_BRANCH.brch_cd%TYPE) IS
	SELECT branch_code,client_cd,client_name,  bank_acct_fmt, bank_cd, bank_name,
	rdi_stat,brch_sort, acct_type, fund_bal, UPTO_T0, EST_QQ_MASUK, EST_QQ_KELUAR
	FROM
	( 
		SELECT  TRIM(m.branch_code) branch_code, m.client_cd,m.client_name,
		  m.bank_acct_fmt, m.bank_cd, m.bank_name, m.rdi_stat,m.brch_sort, m.acct_type,
		   m.fund_bal, NVL(upto_t0,0) upto_t0,
		DECODE(SIGN(avail_fund_bal - NVL(ar_t0,0)), -1,F_Limit_Ambil_Rdi(client_type_3,avail_fund_bal), 
		                                                                                                 DECODE(rdi_stat,'I',avail_fund_bal,NVL(ar_t0,0))) est_qq_masuk,
--12jan15	DECODE(rdi_stat,'A',NVL(ar_t0,0),'I',avail_fund_bal)) est_qq_masuk,
--19jan15  DECODE(rdi_stat2,'A', NVL(ap_T0,0),0) est_qq_keluar
        DECODE(rdi_stat,'A', NVL(ap_T0,0),0)  est_qq_keluar
		FROM
		(
			SELECT client_Cd, upto_t0, DECODE(SIGN(upto_t0), 1, upto_t0, 0) AR_t0, DECODE(SIGN(upto_t0), -1, ABS(upto_t0), 0) AP_t0
			FROM
			( 
				SELECT client_Cd, SUM(upto_t0) upto_t0
				FROM
				(
					SELECT a.xn_doc_num, a.tal_id, a.sl_acct_cd client_cd, DECODE(a.db_Cr_flg,'D',1,-1) * a.curr_val upto_t0
					FROM T_ACCOUNT_LEDGER a, MST_CLIENT m, MST_GLA_TRX g
					WHERE a.doc_date BETWEEN a_bal_dt AND a_dt_end0
					AND a.sl_acct_cd = m.client_cd
					AND a.gl_acct_cd = RPAD(g.gl_a,12)
					AND g.jur_type = 'ARAP'
			--		and a.sl_acct_cd = 'KANG001R'
					AND a.due_date <= a_dt_end0
					AND a.approved_sts = 'A'
					AND reversal_jur = 'N'
					AND record_source <> 'RE'
					UNION ALL
					SELECT gl_Acct_cd,1,sl_acct_cd, (deb_obal - cre_obal) beg_bal
					FROM T_DAY_TRS, MST_CLIENT, MST_GLA_TRX g
					WHERE trs_dt = a_bal_dt	
					AND T_DAY_TRS.sl_acct_cd = MST_CLIENT.client_Cd
					AND T_DAY_TRS.gl_acct_cd = RPAD(g.gl_a,12)
					AND g.jur_type = 'ARAP'
			--		and t_day_trs.sl_acct_cd =  'KANG001R'
					AND (deb_obal - cre_obal) <> 0
				)
				GROUP BY client_cd
			)
		) a,
		(
			SELECT  m.client_cd, branch_code, client_name, 
			DECODE(GREATEST(a_dt_end0,TO_DATE('03/01/2013','dd/mm/yyyy')), a_dt_end0,'X',client_type_3) client_type_3,
			trim(m.client_type_1||m.client_type_2||m.client_type_3) AS acct_type, 
			DECODE(trim(m.rem_cd), 'LOT','LO',trim(branch_code)) brch_sort, 
			f.bank_acct_fmt, f.bank_cd, b.bank_name, f.acct_stat AS rdi_stat,
			DECODE(f.client_cd, NULL, 0, -1 * NVL( F_Fund_Bal(m.client_cd, a_dt_end0),0)) fund_bal, 
			DECODE(f.client_cd, NULL, 0, GREATEST(NVL( F_Fund_Bal(m.client_cd, a_dt_end0),0) - a_min_balance,0)) avail_fund_bal
			FROM MST_CLIENT m, MST_CLIENT_FLACCT f, MST_FUND_BANK b
			WHERE m.client_cd = f.client_cd
			AND f.bank_cd = b.bank_cd
  -- 		AND m.client_cd =  'KANG001R'
			AND m.susp_stat = 'N'
 --			and f.bank_cd = 'PRMT2'
			AND ( f.acct_stat = 'A' OR f.acct_stat = 'I' OR F.acct_Stat = 'D')
		) M,
		( 
			SELECT MAX(client_cd) client_cd, MAX(payrec_date) payrec_date, MAX(acct_type) acct_type
			FROM
			(
				SELECT DECODE(field_name,'CLIENT_CD',field_value, NULL) client_cd,
						DECODE(field_name,'PAYREC_DATE',TO_DATE(field_value,'YYYY/MM/DD HH24:MI:SS'), NULL) payrec_date,
						DECODE(field_name,'ACCT_TYPE',field_value, NULL) acct_type,
				a.update_date, a.update_seq, record_seq
				FROM T_MANY_DETAIL a JOIN T_MANY_HEADER b
				ON a.update_date = b.update_date
				AND a.update_seq = b.update_seq
				WHERE approved_status = 'E'
				AND table_name = 'T_PAYRECH'
				AND record_seq = 1
				AND field_name IN ('CLIENT_CD','PAYREC_DATE','ACCT_TYPE')
			)
			GROUP BY update_date, update_seq, record_seq
			HAVING TRUNC(MAX(payrec_date)) = a_dt_end0
			AND MAX(ACCT_TYPE) = 'RDI'
		) p
		WHERE a.client_cd(+) = m.client_cd
		AND p.client_cd(+) = m.client_cd
		AND p.client_cd IS NULL
		AND (m.brch_sort = a_brch_cd OR a_brch_cd = '%')
		AND (upto_t0 <> 0 OR ( avail_fund_bal <> 0 AND rdi_stat = 'I'))
	)
	WHERE est_qq_masuk >= a_min_trf OR est_qq_keluar >= a_min_trf
	ORDER BY brch_sort,client_cd;


CURSOR csr_outs(a_client MST_CLIENT.client_cd%TYPE, a_end_os DATE, a_payrec_type t_payrech.payrec_type%TYPE) IS
	SELECT client_cd, branch_code, doc_num, doc_folder, 
	doc_Date, due_Date, db_cr_flg,
	 orig_amt, os_amt, gl_acct_cd, descrip, 
	 record_source, xn_doc_num, tal_id,  gl_date,  doc_tal_id,
	 DECODE(a_payrec_type,'PV',DECODE(db_cr_flg,'C','2C','1D'),DECODE(db_cr_flg,'C','1C','2D')) sortk
	FROM
	(
		SELECT TRIM(sl_acct_cd) client_cd, TRIM(branch_code) branch_code, 
		DECODE(doc_ref_num,NULL,xn_doc_num,doc_ref_num) doc_num, 
		folder_cd doc_folder, 
		DECODE(SUBSTR(record_source,2,3),'DUE',netting_date,doc_date) doc_Date, 
		due_Date, T_ACCOUNT_LEDGER.db_cr_flg, (DECODE(T_ACCOUNT_LEDGER.db_cr_flg,'C',-1,1) * curr_val) orig_amt,
		(DECODE(T_ACCOUNT_LEDGER.db_cr_flg,'C',-1,1) * (curr_val - NVL(sett_val,0))) os_amt,
		gl_acct_cd, ledger_nar descrip, 
		record_source, xn_doc_num, tal_id, doc_date AS gl_date,
        DECODE(SUBSTR(record_source,2,3),'DUE',netting_flg,tal_id) doc_tal_id
		FROM T_ACCOUNT_LEDGER, MST_CLIENT, MST_GLA_TRX g
		WHERE doc_date > a_end_os - 20
		AND sl_acct_cd = a_client
		AND sl_acct_cd = client_cd
		AND T_ACCOUNT_LEDGER.gl_acct_cd = RPAD(g.gl_a,12)
		AND g.jur_type = 'ARAP'
		AND doc_date <=  a_end_os
		AND NVL(due_date, doc_date) <=  a_end_os
		AND record_source <> 'RV'
		AND record_source <> 'PV'
		AND approved_sts = 'A'
		AND REVERSAL_JUR = 'N'
		AND record_source <> 'RE'
        AND record_source <> 'INT'
		AND curr_val > NVL(sett_val,0)
		AND NVL(sett_for_curr,0) = 0
		AND NVL(sett_curr_min,0) = 0
	)
	ORDER BY sortk, doc_date, xn_doc_num, tal_id;
	--ORDER BY doc_date, xn_doc_num, tal_id;

--and (nvl(a.BUDGET_CD,'X') <> rpad('DIVIDEN',9,' ')  or m.client_type_3 <> 'R')

CURSOR csr_outs_full(a_client MST_CLIENT.client_cd%TYPE, a_end_os DATE, a_payrec_type t_payrech.payrec_type%TYPE) IS
	SELECT client_cd, branch_code, doc_num, doc_folder, 
	doc_Date, due_Date, db_cr_flg,
	orig_amt, os_amt, gl_acct_cd, descrip, 
	record_source, xn_doc_num, tal_id,  gl_date, doc_tal_id,
	DECODE(a_payrec_type,'PV',DECODE(db_cr_flg,'C','2C','1D'),DECODE(db_cr_flg,'C','1C','2D')) sortk
	FROM
	(
		SELECT TRIM(sl_acct_cd) client_cd, TRIM(branch_code) branch_code, 
		DECODE(doc_ref_num,NULL,xn_doc_num,doc_ref_num) doc_num, 
		folder_cd doc_folder, 
		DECODE(SUBSTR(record_source,2,3),'DUE',netting_date,doc_date) doc_Date, 
		due_Date, T_ACCOUNT_LEDGER.db_cr_flg, (DECODE(T_ACCOUNT_LEDGER.db_cr_flg,'C',-1,1) * curr_val) orig_amt,
		(DECODE(T_ACCOUNT_LEDGER.db_cr_flg,'C',-1,1) * (curr_val - NVL(sett_val,0))) os_amt,
		gl_acct_cd, ledger_nar descrip, 
		record_source, xn_doc_num, tal_id, doc_date AS gl_date,
        DECODE(SUBSTR(record_source,2,3),'DUE',netting_flg,tal_id) doc_tal_id
		FROM T_ACCOUNT_LEDGER, MST_CLIENT, MST_GLA_TRX g
		WHERE doc_date > acct_open_dt - 10
		AND sl_acct_cd = a_client
		AND sl_acct_cd = client_cd
		AND T_ACCOUNT_LEDGER.gl_acct_cd = RPAD(g.gl_a,12)
		AND g.jur_type = 'ARAP'
		AND doc_date <=  a_end_os
		AND NVL(due_date, doc_date) <=  a_end_os
		AND record_source <> 'RV'
		AND record_source <> 'PV'
		AND approved_sts = 'A'
		AND REVERSAL_JUR = 'N'
		AND record_source <> 'RE'
		AND curr_val > NVL(sett_val,0)
		AND NVL(sett_for_curr,0) = 0
		AND NVL(sett_curr_min,0) = 0
	)
	ORDER BY sortk, doc_date, xn_doc_num, tal_id;

v_nl CHAR(2);
v_bal_dt DATE;
v_dt_end0 DATE;
--v_dt_end1 date;
v_min_balance NUMBER;
v_min_trf NUMBER;
v_cnt NUMBER;
v_continue CHAR(1);

v_ip_bank_cd  T_CHEQ.BANK_CD%TYPE;
v_payee_bank_cd T_CHEQ.payee_bank_cd%TYPE;
v_bank_gla   T_ACCOUNT_LEDGER.gl_acct_cd%TYPE;
v_bank_sla   T_ACCOUNT_LEDGER.sl_acct_cd%TYPE;
v_bank_amt   T_ACCOUNT_LEDGER.curr_val%TYPE;
v_round_amt   T_ACCOUNT_LEDGER.curr_val%TYPE;
v_bank_db_cr  T_ACCOUNT_LEDGER.db_cr_flg%TYPE;
v_ledger_nar  T_ACCOUNT_LEDGER.ledger_nar%TYPE;
v_tot_settle  T_ACCOUNT_LEDGER.curr_val%TYPE;
v_settle_amt  T_ACCOUNT_LEDGER.curr_val%TYPE;
v_db_cr_flg   T_ACCOUNT_LEDGER.db_cr_flg%TYPE;
v_round_db_cr_flg T_ACCOUNT_LEDGER.db_cr_flg%TYPE;
v_round_gl_a   T_ACCOUNT_LEDGER.gl_acct_cd%TYPE;
v_round_sl_a   T_ACCOUNT_LEDGER.sl_acct_cd%TYPE;
v_bank_acct_num MST_BANK_ACCT.bank_acct_cd%TYPE;

v_fund_bank		MST_FUND_BANK.bank_cd%TYPE;
--v_fund_bank_bca MST_FUND_BANK.bank_cd%TYPE := 'BCA02';
--v_fund_bank_permata MST_FUND_BANK.bank_cd%TYPE := 'PRMT2';

v_doc_num   T_ACCOUNT_LEDGER.xn_doc_num%TYPE;
v_folder_cd   T_ACCOUNT_LEDGER.folder_cd%TYPE;
v_payrec_type T_PAYRECH.payrec_type%TYPE;
v_folder_type T_PAYRECH.payrec_type%TYPE;
v_folder_prefix T_PAYRECH.payrec_type%TYPE;
v_num_cheq    T_PAYRECH.num_cheq%TYPE;
v_folder_ap_cnt NUMBER;
v_folder_aR_cnt NUMBER;

v_ap_vch_cnt NUMBER;
v_ar_vch_cnt NUMBER;
V_CNT_TAL NUMBER;
V_CNT_PAYREC NUMBER;
V_SUM_TAL NUMBER;

v_client_cd				MST_CLIENT.CLIENT_CD%TYPE;
v_cifs					MST_CIF.cifs%TYPE;
v_acct_type				T_ACCOUNT_LEDGER.acct_type%TYPE;
v_payee_name			MST_CLIENT_BANK.acct_name%TYPE;
v_transfer_fee			T_CHEQ.deduct_fee%TYPE;
v_rdi_bank_cd			MST_FUND_BANK.ip_bank_cd%TYPE;
v_olt_flg				CHAR(1);
v_sys_param_flg			MST_SYS_PARAM.dflg1%TYPE;
v_sys_param_str			MST_SYS_PARAM.dstr1%TYPE;
v_recv_cheq_flg			CHAR(1);
v_rounding_flg			VARCHAR2(4);

v_success_cnt			NUMBER := 0;
v_fail_cnt				NUMBER := 0;
v_fail_flg				BOOLEAN;
v_fail_msg				VARCHAR2(200);

v_many_detail  			Types.many_detail_rc;
v_detail_record_seq		T_MANY_DETAIL.record_seq%TYPE;
v_ledger_record_seq 	T_MANY_DETAIL.record_seq%TYPE;
v_sys_cursor 			sys_refcursor;

-- Menggunakan user-defined record karena urutan field tabel T_ACCOUNT_LEDGER di database development dan production berbeda
TYPE v_ledger_record_type IS RECORD
(
	XN_DOC_NUM   		T_ACCOUNT_LEDGER.xn_doc_num%TYPE, 
	TAL_ID        		T_ACCOUNT_LEDGER.tal_id%TYPE, 
	DOC_REF_NUM         T_ACCOUNT_LEDGER.doc_ref_num%TYPE, 
	ACCT_TYPE           T_ACCOUNT_LEDGER.acct_type%TYPE, 
	SL_ACCT_CD          T_ACCOUNT_LEDGER.sl_acct_cd%TYPE,  
	GL_ACCT_CD          T_ACCOUNT_LEDGER.gl_acct_cd%TYPE,  
	CHQ_SNO             T_ACCOUNT_LEDGER.chq_sno%TYPE, 
	CURR_CD             T_ACCOUNT_LEDGER.curr_cd%TYPE, 
	BRCH_CD             T_ACCOUNT_LEDGER.brch_cd%TYPE,  
	CURR_VAL            T_ACCOUNT_LEDGER.curr_val%TYPE,  
	XN_VAL              T_ACCOUNT_LEDGER.xn_val%TYPE,  
	BUDGET_CD           T_ACCOUNT_LEDGER.budget_cd%TYPE,  
	DB_CR_FLG           T_ACCOUNT_LEDGER.db_cr_flg%TYPE,  
	LEDGER_NAR          T_ACCOUNT_LEDGER.ledger_nar%TYPE,  
	CASHIER_ID          T_ACCOUNT_LEDGER.cashier_id%TYPE,         
	DOC_DATE            T_ACCOUNT_LEDGER.doc_date%TYPE,  
	DUE_DATE            T_ACCOUNT_LEDGER.due_date%TYPE,  
	NETTING_DATE        T_ACCOUNT_LEDGER.netting_date%TYPE,  
	NETTING_FLG         T_ACCOUNT_LEDGER.netting_flg%TYPE,  
	RECORD_SOURCE       T_ACCOUNT_LEDGER.record_source%TYPE,  
	SETT_FOR_CURR       T_ACCOUNT_LEDGER.sett_for_curr%TYPE,  
	SETT_STATUS         T_ACCOUNT_LEDGER.sett_status%TYPE,  
	RVPV_NUMBER         T_ACCOUNT_LEDGER.rvpv_number%TYPE,        
	FOLDER_CD           T_ACCOUNT_LEDGER.folder_cd%TYPE,  
	SETT_VAL            T_ACCOUNT_LEDGER.sett_val%TYPE,  
	ARAP_DUE_DATE       T_ACCOUNT_LEDGER.arap_due_date%TYPE,  
	REVERSAL_JUR        T_ACCOUNT_LEDGER.reversal_jur%TYPE,  
	MANUAL              T_ACCOUNT_LEDGER.manual%TYPE,  
	SETT_CURR_MIN       T_ACCOUNT_LEDGER.sett_curr_min%TYPE		
);

--TYPE v_ledger_tab_type IS TABLE OF v_ledger_record_type;
--TYPE v_detail_tab_type IS TABLE OF T_PAYRECD%ROWTYPE;
TYPE t_many_detail_table IS TABLE OF T_MANY_DETAIL%ROWTYPE;

v_ledger_rec			v_ledger_record_type;
v_detail_rec			T_PAYRECD%ROWTYPE;

--v_ledger_tab			v_ledger_tab_type := v_ledger_tab_type();
--v_detail_tab			v_detail_tab_type := v_detail_tab_type();
v_tab t_many_detail_table := t_many_detail_table();

v_update_seq			T_MANY_HEADER.update_seq%TYPE;
v_update_date			T_MANY_HEADER.update_date%TYPE;

v_error_code			NUMBER;
v_error_msg				VARCHAR2(200);

v_err					EXCEPTION;

BEGIN
/*
	BEGIN
		SELECT COUNT(*) INTO v_cnt
		FROM
		(
			SELECT DECODE(field_name,'CLIENT_CD',field_value, NULL) client_cd,
			DECODE(field_name,'PAYREC_DATE',TO_DATE(field_value,'YYYY/MM/DD HH24:MI:SS'), NULL) payrec_date,
			a.update_date, a.update_seq, record_seq
			FROM T_MANY_DETAIL a JOIN T_MANY_HEADER b
			ON a.update_seq = b.update_seq
			AND a.update_date = b.update_date
			WHERE menu_name = 'GENERATE VOUCHER TRANSFER RDI'
			AND approved_status = 'E'
			AND table_name = 'T_PAYRECH'
			AND field_name IN ('CLIENT_CD','PAYREC_DATE')
		)
		GROUP BY update_date, update_seq, record_seq
		HAVING MAX(payrec_date) = TRUNC(SYSDATE)
	EXCEPTION
		WHEN OTHERS THEN
			v_error_code := -2;
			v_error_msg := SUBSTR('SELECT T_MANY_DETAIL '||SQLERRM,1,200);
			RAISE v_err;
	END;
*/

--    IF v_cnt > 0 THEN
--         RAISE_APPLICATION_ERROR(-20100,'Voucher sebelumnya belum di-approve '||v_nl||SQLERRM);
--    END IF;

--	SELECT TRUNC(SYSDATE)  INTO v_dt_end0 FROM dual;
  --SELECT TO_DATE('13/12/13','dd/mm/yy')  INTO v_dt_end0 FROM dual;

  -- v_dt_end1 := GET_DUE_DATE(1,v_dt_end0); -- next work day
	
	v_dt_end0 := p_due_date;

	v_bal_dt := Get_Doc_Date(3,v_dt_end0);
	v_bal_dt := v_bal_dt - TO_NUMBER(TO_CHAR(v_bal_dt,'dd') ) + 1;

	BEGIN
		SELECT bank_cd INTO v_fund_bank
		FROM MST_FUND_BANK
		WHERE default_flg = 'Y';
	EXCEPTION
		WHEN OTHERS THEN
			v_error_code := -2;
			v_error_msg := SUBSTR('SELECT MST_FUND_BANK '||SQLERRM,1,200);
			RAISE v_err;
	END;

	BEGIN
		SELECT TO_NUMBER(prm_desc) INTO v_min_balance
		FROM MST_PARAMETER
		WHERE prm_cd_1 = 'BRDMIN'
		AND prm_cd_2 = v_fund_bank;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			v_min_balance := 0;
		WHEN OTHERS THEN
			v_error_code := -3;
			v_error_msg := SUBSTR('SELECT MST_PARAMETER BRDMIN '||SQLERRM,1,200);
			RAISE v_err;
	END;

	BEGIN
		SELECT TO_NUMBER(prm_desc) INTO v_min_trf
		FROM MST_PARAMETER
		WHERE prm_cd_1 = 'TRFMIN'
		AND prm_cd_2 = v_fund_bank;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			v_min_trf := 0;
		WHEN OTHERS THEN
			v_error_code := -4;
			v_error_msg := SUBSTR('SELECT MST_PARAMETER TRFMIN '||SQLERRM,1,200);
			RAISE v_err;
	END;
	
	--round dipindah ke dalam looping
	
	BEGIN
		SELECT dflg1 INTO v_recv_cheq_flg
		FROM MST_SYS_PARAM
		WHERE param_id = 'SYSTEM' 
		AND param_cd1 = 'CHEQ' 
		AND param_cd2 = 'RV';
	EXCEPTION
		WHEN OTHERS THEN
			v_error_code := -6;
			v_error_msg := SUBSTR('SELECT MST_SYS_PARAM '||SQLERRM,1,200);
			RAISE v_err;
	END;

	v_ap_vch_cnt := 0;
	v_ar_vch_cnt := 0;
	v_fail_cnt := 0;

	FOR REC IN csr_trf(v_bal_dt, v_dt_end0, v_min_balance, v_min_trf, p_brch_cd)
---------------------------------------------------------------------------------------------    
	LOOP
		SAVEPOINT init_state;
		

	BEGIN
		SELECT DECODE(dflg1,'Y',dstr1,dflg1) INTO v_rounding_flg
		FROM MST_SYS_PARAM
		WHERE param_id = 'RVPV_AUTO_TRF'
		AND param_cd1 = 'ROUND'
		AND PARAM_CD2 = rec.bank_cd;
	EXCEPTION
		WHEN OTHERS THEN
			v_error_code := -5;
			v_error_msg := SUBSTR('SELECT MST_SYS_PARAM ROUND '||SQLERRM,1,200);
			RAISE v_err;
	END;




		v_fail_flg := FALSE;
	
   	   	BEGIN
			SELECT dstr1 INTO v_folder_prefix
			FROM MST_SYS_PARAM
			WHERE param_id = 'RVPV_AUTO_TRF'
			AND param_cd1 = 'PREFIX'
			AND (param_cd2 = rec.branch_code OR param_cd2 = '%')
			AND param_cd3 = rec.bank_cd;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				v_folder_prefix := NULL;
			WHEN OTHERS THEN
				v_error_code := -11;
				v_error_msg := SUBSTR('SELECT MST_SYS_PARAM '||SQLERRM,1,200);
				RAISE v_err;
		END;

		BEGIN
			SELECT trim(gl_a), trim(sl_a) INTO v_bank_gla, v_bank_sla
			FROM MST_GLA_TRX
			WHERE jur_type = 'BANKRDI'
			AND (trim(brch_cd) = trim(rec.branch_code) OR brch_cd = '%')
			AND fund_bank_cd = rec.bank_cd;
		EXCEPTION
			WHEN OTHERS THEN
				v_error_code := -12;
				v_error_msg := SUBSTR('SELECT MST_GLA_TRX '||SQLERRM,1,200);
				RAISE v_err;
		END;

		BEGIN
			SELECT dstr1, dstr2 INTO v_ip_bank_cd, v_payee_bank_cd
			FROM MST_SYS_PARAM
			WHERE param_id = 'RVPV_AUTO_TRF'
			AND param_cd1 = 'BANKRDI'
			AND param_cd2 = rec.bank_cd
			AND (param_cd3 = TRIM(rec.branch_code) OR param_cd3 = '%');
		EXCEPTION
--			WHEN NO_DATA_FOUND THEN
--				v_folder_prefix := NULL;
			WHEN OTHERS THEN
				v_error_code := -13;
				v_error_msg := SUBSTR('SELECT MST_SYS_PARAM '||SQLERRM,1,200);
				RAISE v_err;
		END;
		
		IF v_rounding_flg <> 'N' THEN
			BEGIN
				SELECT gl_a, sl_a INTO v_round_gl_a, v_round_sl_a
				FROM MST_GLA_TRX
				WHERE jur_type = 'ROUND'
				AND (brch_cd = '%' OR brch_cd = TRIM(rec.branch_code));
			EXCEPTION
				WHEN OTHERS THEN
					v_error_code := -14;
					v_error_msg := SUBSTR('SELECT MST_PARAMETER ROUND '||SQLERRM,1,200);
					RAISE v_err;
			END;
		END IF;

		IF rec.est_qq_keluar > 0 THEN
		    v_payrec_type := 'PV';
		ELSE
			IF rec.rdi_stat = 'I' THEN
			  	v_payrec_type := 'RD';
			ELSE
		    	v_payrec_type := 'RV';
			END IF;
		END IF;

		v_doc_num := Get_Docnum_Vch(v_dt_end0,v_payrec_type);

		v_tot_settle := 0;
		
		BEGIN
			Sp_T_Many_Header_Insert('GENERATE VOUCHER TRANSFER RDI', 'I', p_user_id, p_ip_address, NULL, v_update_date, v_update_seq, v_error_code, v_error_msg);
		EXCEPTION
			WHEN OTHERS THEN
				v_error_code := -15;
				v_error_msg := SUBSTR('SP_T_MANY_HEADER '||SQLERRM,1,200);
				RAISE v_err;
		END;
		
		v_detail_record_seq := 1;
		
		IF v_error_code < 0 THEN
			v_error_code := -16;
			v_error_msg := SUBSTR('SP_T_MANY_HEADER '||v_error_msg,1,200);
			RAISE v_err;
		END IF;
		
		SAVEPOINT before_settle;

		IF rec.rdi_stat = 'A'  THEN
			FOR routs IN csr_outs( rec.client_cd, v_dt_end0, v_payrec_type)
			LOOP
			    v_settle_amt := 0;
				IF v_payrec_type = 'PV' THEN
				
					IF v_tot_settle < rec.est_qq_keluar THEN
					
						IF routs.db_cr_flg = 'D' THEN
							v_tot_settle := v_tot_settle - routs.os_amt;
							v_settle_amt := routs.os_amt;
						ELSE
						
							IF (v_tot_settle + ABS(routs.os_amt)) <= rec.est_qq_keluar THEN
								v_settle_amt := ABS(routs.os_amt);
							ELSE
								v_settle_amt := rec.est_qq_keluar - v_tot_settle;
							END IF;
							
							v_tot_settle := v_tot_settle +  v_settle_amt;
						END IF;
						
					END IF;

				ELSE
					IF v_tot_settle < rec.est_qq_masuk THEN
					
						IF routs.db_cr_flg = 'C' THEN
							v_tot_settle := v_tot_settle - ABS(routs.os_amt);
							v_settle_amt := ABS(routs.os_amt);
						ELSE
						
							IF (v_tot_settle + ABS(routs.os_amt)) <= rec.est_qq_masuk THEN
								v_settle_amt := ABS(routs.os_amt);
							ELSE
								v_settle_amt := rec.est_qq_masuk - v_tot_settle;
							END IF;
							
							v_tot_settle := v_tot_settle +  v_settle_amt;
						END IF;
						
					END IF;
					
				END IF;

    			IF V_settle_amt <> 0 THEN

					IF routs.db_cr_flg = 'D' THEN
						v_db_cr_flg := 'C';
					ELSE
						v_db_cr_flg := 'D';
					END IF;
				
					--OPEN v_Many_detail FOR	
						SELECT v_update_date AS update_date, v_update_seq AS update_seq, table_name, v_detail_record_seq AS record_seq, NULL AS table_rowid, a.field_name,field_type, b.field_value, 'I' AS status,  b.upd_flg
						BULK COLLECT INTO v_tab
						FROM(
							SELECT 'T_PAYRECD' AS table_name, column_name AS field_name,
								   DECODE(data_type,'VARCHAR2','S','CHAR','S','NUMBER','N','DATE','D','X') AS field_type
							FROM all_tab_columns
							WHERE table_name = 'T_PAYRECD'
							AND OWNER = 'IPNEXTG'
						) a,
						( SELECT  'PAYREC_NUM'  AS field_name, v_doc_num AS field_value, 'Y' upd_flg FROM dual
							UNION ALL
							SELECT  'PAYREC_TYPE'  AS field_name, v_payrec_type AS field_value, 'Y' upd_flg FROM dual
							UNION ALL
							SELECT  'PAYREC_DATE'  AS field_name, TO_CHAR(v_dt_end0,'yyyy/mm/dd hh24:mi:ss')  AS field_value, 'Y' upd_flg FROM dual
							UNION ALL
							SELECT  'CLIENT_CD'  AS field_name, routs.client_cd AS field_value, 'Y' upd_flg FROM dual
							UNION ALL
							SELECT  'GL_ACCT_CD'  AS field_name, routs.gl_acct_cd AS field_value, 'Y' upd_flg FROM dual
							UNION ALL
							SELECT  'SL_ACCT_CD'  AS field_name, routs.client_cd AS field_value, 'Y' upd_flg FROM dual
							UNION ALL
							SELECT  'DB_CR_FLG'  AS field_name, v_db_cr_flg AS field_value, 'Y' upd_flg FROM dual
							UNION ALL
							SELECT  'PAYREC_AMT'  AS field_name, TO_CHAR(v_settle_amt)  AS field_value, 'Y' upd_flg FROM dual
							UNION ALL
							SELECT  'DOC_REF_NUM' AS field_name, routs.doc_num AS field_value, 'Y' upd_flg FROM dual
							UNION ALL
							SELECT  'TAL_ID'  AS field_name, /*DECODE(routs.record_source,'CDUE','1',TO_CHAR(routs.tal_id))*/ TO_CHAR(routs.tal_id)  AS field_value, 'Y' upd_flg FROM dual
							UNION ALL
							SELECT  'REMARKS'  AS field_name, routs.descrip AS field_value, 'Y' upd_flg FROM dual
							UNION ALL
							SELECT  'RECORD_SOURCE'  AS field_name,  DECODE(routs.record_source,'RD','PDRD','PD','PDRD','RVO','PVRV','PVO','PVRV',routs.record_source) AS field_value, 'Y' upd_flg FROM dual
							UNION ALL
							SELECT  'DOC_DATE'  AS field_name, TO_CHAR(routs.doc_date,'yyyy/mm/dd hh24:mi:ss')  AS field_value, 'Y' upd_flg FROM dual
							UNION ALL
							SELECT  'REF_FOLDER_CD'  AS field_name, routs.doc_folder AS field_value, 'Y' upd_flg FROM dual
							UNION ALL
							SELECT  'GL_REF_NUM'  AS field_name, routs.xn_doc_num AS field_value, 'Y' upd_flg FROM dual
							UNION ALL
							SELECT  'BRCH_CD'  AS field_name, routs.branch_code AS field_value, 'Y' upd_flg FROM dual
							UNION ALL
--1DEC16							SELECT  'DOC_TAL_ID'  AS field_name, DECODE(routs.record_source,'CDUE','1',TO_CHAR(routs.tal_id))  AS field_value, 'Y' upd_flg FROM dual
							SELECT  'DOC_TAL_ID'  AS field_name,  TO_CHAR(routs.doc_tal_id)  AS field_value, 'Y' upd_flg FROM dual
							UNION ALL
							SELECT  'DUE_DATE'  AS field_name, TO_CHAR(routs.due_date,'yyyy/mm/dd hh24:mi:ss')  AS field_value, 'Y' upd_flg FROM dual
							UNION ALL
							SELECT  'CRE_DT'  AS field_name, TO_CHAR(SYSDATE,'yyyy/mm/dd hh24:mi:ss')  AS field_value, 'Y' upd_flg FROM dual
							UNION ALL
							SELECT  'USER_ID'  AS field_name, p_USER_ID AS field_value, 'Y' upd_flg FROM dual				
						) b
						WHERE a.field_name = b.field_name;
						
					FORALL i in v_tab.first .. v_tab.last
						INSERT INTO T_MANY_DETAIL
						VALUES v_tab(i);
		
					/*BEGIN
						Sp_T_Many_Detail_Insert(v_update_date, v_update_seq, 'I', 'T_PAYRECD', v_detail_record_seq, NULL, v_MANY_DETAIL, v_error_code, v_error_msg);
					EXCEPTION
						WHEN OTHERS THEN
							v_error_code := -21;
							v_error_msg := SUBSTR('SP_T_MANY_DETAIL_INSERT T_PAYRECD '||rec.CLIENT_cd||SQLERRM,1,200);
							RAISE v_err;
					END;
					
					CLOSE v_many_detail;*/
					
					v_detail_record_seq := v_detail_record_seq + 1;
					
					/*IF v_error_code < 0 THEN
						v_error_code := -22;
						v_error_msg := SUBSTR('SP_T_MANY_DETAIL_INSERT T_PAYRECD '||rec.CLIENT_cd||' '||v_error_msg,1,200);
						RAISE v_err;
					END IF; */

--			test		BEGIN
--						Sp_Rvpv_Settled(routs.doc_num,rec.client_cd, v_settle_amt,routs.xn_doc_num, routs.gl_acct_cd, routs.tal_id,routs.record_source,routs.doc_date,routs.due_date,'I',p_user_id);
--					EXCEPTION
--						WHEN OTHERS THEN
--						    v_error_code := -23;
--							v_error_msg := SUBSTR('SP_RVPV_SETTLED '||rec.CLIENT_cd||SQLERRM,1,200);
--							RAISE v_err;
--					END;

				END IF;
			END LOOP;
			
		ELSIF rec.rdi_stat = 'I' AND rec.est_qq_masuk > 0 THEN

			v_payrec_type := 'RD';
			v_db_cr_flg := 'C';
			
			--OPEN v_Many_detail FOR	
				SELECT v_update_date AS update_date, v_update_seq AS update_seq, table_name, v_detail_record_seq AS record_seq, NULL AS table_rowid, a.field_name,field_type, b.field_value, 'I' AS status,  b.upd_flg
				BULK COLLECT INTO v_tab
				FROM(
					SELECT 'T_PAYRECD' AS table_name, column_name AS field_name,
						   DECODE(data_type,'VARCHAR2','S','CHAR','S','NUMBER','N','DATE','D','X') AS field_type
					FROM all_tab_columns
					WHERE table_name = 'T_PAYRECD'
					AND OWNER = 'IPNEXTG'
				) a,
				( SELECT  'PAYREC_NUM'  AS field_name, v_doc_num AS field_value, 'Y' upd_flg FROM dual
					UNION ALL
					SELECT  'PAYREC_TYPE'  AS field_name, v_payrec_type AS field_value, 'Y' upd_flg FROM dual
					UNION ALL
					SELECT  'PAYREC_DATE'  AS field_name, TO_CHAR(v_dt_end0,'yyyy/mm/dd hh24:mi:ss')  AS field_value, 'Y' upd_flg FROM dual
					UNION ALL
					SELECT  'CLIENT_CD'  AS field_name, rec.client_cd AS field_value, 'Y' upd_flg FROM dual
					UNION ALL
					SELECT  'GL_ACCT_CD'  AS field_name, '1422' AS field_value, 'Y' upd_flg FROM dual
					UNION ALL
					SELECT  'SL_ACCT_CD'  AS field_name, rec.client_cd AS field_value, 'Y' upd_flg FROM dual
					UNION ALL
					SELECT  'DB_CR_FLG'  AS field_name, v_db_cr_flg AS field_value, 'Y' upd_flg FROM dual
					UNION ALL
					SELECT  'PAYREC_AMT'  AS field_name, TO_CHAR(rec.est_qq_masuk)  AS field_value, 'Y' upd_flg FROM dual
					UNION ALL
					SELECT  'DOC_REF_NUM' AS field_name, /*TO_CHAR(v_dt_end0,'mmyy')||'ZZ1234567'*/ v_doc_num AS field_value, 'Y' upd_flg FROM dual
					UNION ALL
					SELECT  'TAL_ID'  AS field_name, '1'  AS field_value, 'Y' upd_flg FROM dual
					UNION ALL
					SELECT  'REMARKS'  AS field_name, 'Pb dari Rek Dana' AS field_value, 'Y' upd_flg FROM dual
					UNION ALL
					SELECT  'RECORD_SOURCE'  AS field_name, 'VCH' AS field_value, 'Y' upd_flg FROM dual
					UNION ALL
					SELECT  'DOC_DATE'  AS field_name, TO_CHAR(v_dt_end0,'yyyy/mm/dd hh24:mi:ss')  AS field_value, 'Y' upd_flg FROM dual
					UNION ALL
					SELECT  'REF_FOLDER_CD'  AS field_name, NULL AS field_value, 'Y' upd_flg FROM dual
					UNION ALL
					SELECT  'GL_REF_NUM'  AS field_name, v_doc_num AS field_value, 'Y' upd_flg FROM dual
					UNION ALL
					SELECT  'BRCH_CD'  AS field_name, rec.branch_code AS field_value, 'Y' upd_flg FROM dual
					UNION ALL
					SELECT  'DOC_TAL_ID'  AS field_name, '1'  AS field_value, 'Y' upd_flg FROM dual
					UNION ALL
					SELECT  'DUE_DATE'  AS field_name, TO_CHAR(v_dt_end0,'yyyy/mm/dd hh24:mi:ss')  AS field_value, 'Y' upd_flg FROM dual
					UNION ALL
					SELECT  'CRE_DT'  AS field_name, TO_CHAR(SYSDATE,'yyyy/mm/dd hh24:mi:ss')  AS field_value, 'Y' upd_flg FROM dual
					UNION ALL
					SELECT  'USER_ID'  AS field_name, p_USER_ID AS field_value, 'Y' upd_flg FROM dual				
				) b
				WHERE a.field_name = b.field_name;
			
			FORALL i in v_tab.first .. v_tab.last
				INSERT INTO T_MANY_DETAIL
				VALUES v_tab(i);
	
			/*BEGIN
				Sp_T_Many_Detail_Insert(v_update_date, v_update_seq, 'I', 'T_PAYRECD', v_detail_record_seq, NULL, v_MANY_DETAIL, v_error_code, v_error_msg);
			EXCEPTION
				WHEN OTHERS THEN
					v_error_code := -31;
					v_error_msg := SUBSTR('SP_T_MANY_DETAIL_INSERT T_PAYRECD '||rec.CLIENT_cd||SQLERRM,1,200);
					RAISE v_err;
			END;
			
			CLOSE v_many_detail;*/
			
			v_detail_record_seq := v_detail_record_seq + 1;
			
			/*IF v_error_code < 0 THEN
				v_error_code := -32;
				v_error_msg := SUBSTR('SP_T_MANY_DETAIL_INSERT T_PAYRECD '||rec.CLIENT_cd||' '||v_error_msg,1,200);
				RAISE v_err;
			END IF; */

			v_tot_settle := rec.est_qq_masuk;
			v_round_amt :=0;
		END IF;
-- 8 may 13 jika tot settle kurang dr est_qq_masuk , lanjut
-- bisa mengakibatkan balance di GL maupun di RDI


--	If the amount of recent outstanding transactions doesn't match with transfer amount, redo the process using outstanding transactions starting from client's account opening date
		IF v_tot_settle <> (rec.est_qq_masuk + rec.est_qq_keluar) THEN
			v_tot_settle := 0;
		
			ROLLBACK TO before_settle;
---------------------------------------------------------------------------------------			
			FOR routs IN csr_outs_full( rec.client_cd, v_dt_end0, v_payrec_type)
			LOOP
			    v_settle_amt := 0;
				IF v_payrec_type = 'PV' THEN
				
					IF v_tot_settle < rec.est_qq_keluar THEN
					
						IF routs.db_cr_flg = 'D' THEN
							v_tot_settle := v_tot_settle - routs.os_amt;
							v_settle_amt := routs.os_amt;
						ELSE
						
							IF (v_tot_settle + ABS(routs.os_amt)) <= rec.est_qq_keluar THEN
								v_settle_amt := ABS(routs.os_amt);
							ELSE
								v_settle_amt := rec.est_qq_keluar - v_tot_settle;
							END IF;
							
							v_tot_settle := v_tot_settle +  v_settle_amt;
						END IF;
						
					END IF;

				ELSE
					IF v_tot_settle < rec.est_qq_masuk THEN
					
						IF routs.db_cr_flg = 'C' THEN
							v_tot_settle := v_tot_settle - ABS(routs.os_amt);
							v_settle_amt := ABS(routs.os_amt);
						ELSE
						
							IF (v_tot_settle + ABS(routs.os_amt)) <= rec.est_qq_masuk THEN
								v_settle_amt := ABS(routs.os_amt);
							ELSE
								v_settle_amt := rec.est_qq_masuk - v_tot_settle;
							END IF;
							
							v_tot_settle := v_tot_settle +  v_settle_amt;
						END IF;
						
					END IF;
					
				END IF;

    			IF V_settle_amt <> 0 THEN

					IF routs.db_cr_flg = 'D' THEN
						v_db_cr_flg := 'C';
					ELSE
						v_db_cr_flg := 'D';
					END IF;
				

					SELECT v_update_date AS update_date, v_update_seq AS update_seq, table_name, v_detail_record_seq AS record_seq, NULL AS table_rowid, a.field_name,field_type, b.field_value, 'I' AS status,  b.upd_flg
					BULK COLLECT INTO v_tab
					FROM(
						SELECT 'T_PAYRECD' AS table_name, column_name AS field_name,
							   DECODE(data_type,'VARCHAR2','S','CHAR','S','NUMBER','N','DATE','D','X') AS field_type
						FROM all_tab_columns
						WHERE table_name = 'T_PAYRECD'
						AND OWNER = 'IPNEXTG'
					) a,
					( SELECT  'PAYREC_NUM'  AS field_name, v_doc_num AS field_value, 'Y' upd_flg FROM dual
						UNION ALL
						SELECT  'PAYREC_TYPE'  AS field_name, v_payrec_type AS field_value, 'Y' upd_flg FROM dual
						UNION ALL
						SELECT  'PAYREC_DATE'  AS field_name, TO_CHAR(v_dt_end0,'yyyy/mm/dd hh24:mi:ss')  AS field_value, 'Y' upd_flg FROM dual
						UNION ALL
						SELECT  'CLIENT_CD'  AS field_name, routs.client_cd AS field_value, 'Y' upd_flg FROM dual
						UNION ALL
						SELECT  'GL_ACCT_CD'  AS field_name, routs.gl_acct_cd AS field_value, 'Y' upd_flg FROM dual
						UNION ALL
						SELECT  'SL_ACCT_CD'  AS field_name, routs.client_cd AS field_value, 'Y' upd_flg FROM dual
						UNION ALL
						SELECT  'DB_CR_FLG'  AS field_name, v_db_cr_flg AS field_value, 'Y' upd_flg FROM dual
						UNION ALL
						SELECT  'PAYREC_AMT'  AS field_name, TO_CHAR(v_settle_amt)  AS field_value, 'Y' upd_flg FROM dual
						UNION ALL
						SELECT  'DOC_REF_NUM' AS field_name, routs.doc_num AS field_value, 'Y' upd_flg FROM dual
						UNION ALL
						SELECT  'TAL_ID'  AS field_name, /*DECODE(routs.record_source,'CDUE','1',TO_CHAR(routs.tal_id))*/ TO_CHAR(routs.tal_id)  AS field_value, 'Y' upd_flg FROM dual
						UNION ALL
						SELECT  'REMARKS'  AS field_name, routs.descrip AS field_value, 'Y' upd_flg FROM dual
						UNION ALL
						SELECT  'RECORD_SOURCE'  AS field_name,  DECODE(routs.record_source,'RD','PDRD','PD','PDRD','RVO','PVRV','PVO','PVRV',routs.record_source) AS field_value, 'Y' upd_flg FROM dual
						UNION ALL
						SELECT  'DOC_DATE'  AS field_name, TO_CHAR(routs.doc_date,'yyyy/mm/dd hh24:mi:ss')  AS field_value, 'Y' upd_flg FROM dual
						UNION ALL
						SELECT  'REF_FOLDER_CD'  AS field_name, routs.doc_folder AS field_value, 'Y' upd_flg FROM dual
						UNION ALL
						SELECT  'GL_REF_NUM'  AS field_name, routs.xn_doc_num AS field_value, 'Y' upd_flg FROM dual
						UNION ALL
						SELECT  'BRCH_CD'  AS field_name, routs.branch_code AS field_value, 'Y' upd_flg FROM dual
						UNION ALL
--1DEC16						SELECT  'DOC_TAL_ID'  AS field_name, DECODE(routs.record_source,'CDUE','1',TO_CHAR(routs.tal_id))  AS field_value, 'Y' upd_flg FROM dual
						SELECT  'DOC_TAL_ID'  AS field_name,  TO_CHAR(routs.doc_tal_id)  AS field_value, 'Y' upd_flg FROM dual
                        UNION ALL
						SELECT  'DUE_DATE'  AS field_name, TO_CHAR(routs.due_date,'yyyy/mm/dd hh24:mi:ss')  AS field_value, 'Y' upd_flg FROM dual
						UNION ALL
						SELECT  'CRE_DT'  AS field_name, TO_CHAR(SYSDATE,'yyyy/mm/dd hh24:mi:ss')  AS field_value, 'Y' upd_flg FROM dual
						UNION ALL
						SELECT  'USER_ID'  AS field_name, p_USER_ID AS field_value, 'Y' upd_flg FROM dual				
					) b
					WHERE a.field_name = b.field_name;
						
					FORALL i in v_tab.first .. v_tab.last
						INSERT INTO T_MANY_DETAIL
						VALUES v_tab(i);
					
					v_detail_record_seq := v_detail_record_seq + 1;

--					BEGIN
--						Sp_Rvpv_Settled(routs.doc_num,rec.client_cd, v_settle_amt,routs.xn_doc_num, routs.gl_acct_cd, routs.tal_id,routs.record_source,routs.doc_date,routs.due_date,'I',p_user_id);
--					EXCEPTION
--						WHEN OTHERS THEN
--						    v_error_code := -23;
--							v_error_msg := SUBSTR('SP_RVPV_SETTLED '||rec.CLIENT_cd||SQLERRM,1,200);
--							RAISE v_err;
--					END;

				END IF;
			END LOOP;
		END IF;

		v_continue := 'N';

		IF ((v_tot_settle < rec.est_qq_masuk) OR (v_tot_settle - rec.est_qq_masuk) < 100) AND rec.est_qq_keluar = 0 AND v_tot_settle <> 0 THEN
-- 		if ((v_tot_settle - rec.est_qq_masuk) > -1 and (v_tot_settle - rec.est_qq_masuk) < 100 ) and rec.est_qq_keluar = 0 then
			v_continue := 'Y';
		END IF;

-- 8 may 13 end

-- 7 may 13 dikomen    if v_tot_settle = (rec.est_qq_masuk + rec.est_qq_keluar) then
		IF v_tot_settle = (rec.est_qq_masuk + rec.est_qq_keluar) OR v_continue = 'Y' THEN
    -- v_tot_settle = 0 jika tidak ada detail outstanding, kemungkinan sdh disettle di vocer
    -- tgl sesudah hari ini

			IF rec.est_qq_keluar > 0 THEN
				v_folder_type := 'P';

				v_ledger_nar := 'PB ke Rek Dana';
				v_num_cheq    := 1;

			ELSE
			
				v_folder_type := 'R';

				v_ledger_nar := 'PB dari Rek Dana';
				
				IF v_recv_cheq_flg = 'Y' THEN
					v_num_cheq := 1;
				ELSE
					v_num_cheq := 0;
				END IF;
				
			END IF;

			v_folder_cd := F_Get_Folder_Num(v_dt_end0, trim(v_folder_prefix||v_folder_type));


			IF rec.est_qq_keluar > 0 THEN
				IF v_rounding_flg <> 'N' THEN
					IF v_rounding_flg = 'UP' THEN
						v_bank_amt := ROUND(rec.est_qq_keluar,0);			
					ELSE
						v_bank_amt := TRUNC(rec.est_qq_keluar,0);
					END IF;
					
					v_round_amt := v_bank_amt - rec.est_qq_keluar;
				ELSE
					v_bank_amt := rec.est_qq_keluar;
					v_round_amt := 0;
				END IF;
			ELSE
-- 7may13     	 v_bank_amt := round(rec.est_qq_masuk,0);
-- 7may13     	 v_round_amt := v_bank_amt - rec.est_qq_masuk;

				IF v_rounding_flg <> 'N' THEN
					IF v_rounding_flg = 'UP' THEN
						v_bank_amt := ROUND(v_tot_settle,0);
					ELSE
						v_bank_amt := TRUNC(v_tot_settle,0);
					END IF;	
						
					v_round_amt := v_bank_amt - v_tot_settle;
				ELSE
					v_bank_amt := v_tot_settle;
					v_round_amt := 0;
				END IF;
			END IF;
			
			--OPEN v_MANY_DETAIL FOR
				SELECT v_update_date AS update_date, v_update_seq AS update_seq, table_name, 1 AS record_seq, NULL AS table_rowid, a.field_name,  field_type, b.field_value, 'I' AS status,  b.upd_flg
				BULK COLLECT INTO v_tab
				FROM(
					SELECT  'T_PAYRECH' AS table_name, column_name AS field_name, DECODE(data_type,'VARCHAR2','S','CHAR','S','NUMBER','N','DATE','D','X') AS field_type
					FROM all_tab_columns
					WHERE table_name = 'T_PAYRECH'
					AND OWNER = 'IPNEXTG'
				) a,
				( 
					SELECT  'PAYREC_NUM'  AS field_name, v_doc_num AS field_value, 'Y' upd_flg FROM dual
					UNION ALL
					SELECT  'PAYREC_TYPE'  AS field_name, v_payrec_type AS field_value, 'Y' upd_flg FROM dual
					UNION ALL
					SELECT  'PAYREC_DATE'  AS field_name, TO_CHAR(v_dt_end0,'yyyy/mm/dd hh24:mi:ss')  AS field_value, 'Y' upd_flg FROM dual
					UNION ALL
					SELECT  'ACCT_TYPE'  AS field_name, 'RDI' AS field_value, 'Y' upd_flg FROM dual
					UNION ALL
					SELECT  'SL_ACCT_CD'  AS field_name, v_bank_sla AS field_value, 'Y' upd_flg FROM dual
					UNION ALL
					SELECT  'CURR_CD'  AS field_name, 'IDR' AS field_value, 'Y' upd_flg FROM dual
					UNION ALL
					SELECT  'CURR_AMT'  AS field_name, TO_CHAR(v_bank_amt)  AS field_value, 'Y' upd_flg FROM dual
					UNION ALL
					SELECT  'REMARKS'  AS field_name, v_ledger_nar AS field_value, 'Y' upd_flg FROM dual
					UNION ALL
					SELECT  'GL_ACCT_CD'  AS field_name, v_bank_gla AS field_value, 'Y' upd_flg FROM dual
					UNION ALL
					SELECT  'CLIENT_CD'  AS field_name, rec.client_cd AS field_value, 'Y' upd_flg FROM dual
					UNION ALL
					SELECT  'FOLDER_CD'  AS field_name, v_folder_cd AS field_value, 'Y' upd_flg FROM dual
					UNION ALL
					SELECT  'NUM_CHEQ'  AS field_name, TO_CHAR(v_num_cheq) AS field_value, 'Y' upd_flg FROM dual
					UNION ALL
					SELECT  'CLIENT_BANK_ACCT'  AS field_name, rec.bank_acct_fmt AS field_value, 'Y' upd_flg FROM dual
					UNION ALL
					SELECT  'CLIENT_BANK_NAME'  AS field_name, rec.bank_name AS field_value, 'Y' upd_flg FROM dual
					UNION ALL
					SELECT  'REVERSAL_JUR'  AS field_name, 'N' AS field_value, 'Y' upd_flg FROM dual
					UNION ALL
					SELECT  'USER_ID'  AS field_name, p_USER_ID AS field_value, 'Y' upd_flg FROM dual
					UNION ALL
					SELECT  'CRE_DT'  AS field_name, TO_CHAR(SYSDATE,'yyyy/mm/dd hh24:mi:ss')  AS field_value, 'Y' upd_flg FROM dual

				) b
				WHERE a.field_name = b.field_name;
				
			FORALL i in v_tab.first .. v_tab.last
				INSERT INTO T_MANY_DETAIL
				VALUES v_tab(i);

			/*BEGIN
				Sp_T_Many_Detail_Insert(v_update_date, v_update_seq, 'I', 'T_PAYRECH', 1, NULL, v_MANY_DETAIL, v_error_code, v_error_msg);
			EXCEPTION
				WHEN OTHERS THEN
					v_error_code := -41;
					v_error_msg := SUBSTR('SP_T_MANY_DETAIL_INSERT T_PAYRECH '||rec.client_cd||SQLERRM,1,200);
					RAISE v_err;
			END;
			
			CLOSE v_many_detail;
			
			IF v_error_code < 0 THEN
				v_error_code := -42;
				v_error_msg := 'SP_T_MANY_DETAIL_INSERT T_PAYRECH '||rec.client_cd||' '||v_error_msg;
				RAISE v_err;
			END IF;*/		

			IF v_round_amt <> 0 THEN

				IF v_payrec_type = 'PV' THEN
					IF v_round_amt > 0  THEN
						v_round_db_cr_flg := 'D';
					ELSE
						v_round_db_cr_flg := 'C';
					END IF;
				ELSE
					IF v_round_amt > 0  THEN
						v_round_db_cr_flg := 'C';
					ELSE
						v_round_db_cr_flg := 'D';
					END IF;
				END IF;

		    END IF;

		    BEGIN
				OPEN v_sys_cursor FOR
					SELECT v_DOC_NUM xn_doc_num, DECODE(sortk,555,555,ROWNUM) tal_id, NULL AS doc_ref_num,
						NULL AS acct_type, SL_ACCT_CD, GL_ACCT_CD,
						NULL AS CHQ_SNO, 'IDR' AS CURR_CD,
						rec.branch_code BRCH_CD, ABS(net_amt) AS CURR_VAL, ABS(net_amt) AS XN_VAL,
						NULL AS BUDGET_CD, DB_CR_FLG, LEDGER_NAR,
						NULL CASHIER_ID,
						v_dt_end0 AS DOC_DATE, v_dt_end0 AS DUE_DATE,
						v_dt_end0 NETTING_DATE, NULL NETTING_FLG, RECORD_SOURCE,
						0 AS SETT_FOR_CURR, NULL AS SETT_STATUS, v_DOC_NUM AS RVPV_NUMBER,
						v_folder_cd AS FOLDER_CD, 0 AS  SETT_VAL, v_dt_end0 ARAP_DUE_DATE, 'N' REVERSAL_JUR, 'N' MANUAL, 0 SETT_CURR_MIN
					FROM
					(
						SELECT sortk, gl_acct_cd, sl_acct_cd,ledger_nar,
						DECODE(SIGN(net_amt),1,'D',-1,'C') AS DB_CR_FLG, net_amt, RECORD_SOURCE
						FROM
						( 
							SELECT sortk, gl_acct_cd, sl_acct_cd,ledger_nar, record_source, SUM(net_amt) net_amt
							FROM
							(
								SELECT 1 sortk, gl_acct_cd, sl_acct_cd, 'TR '||TO_CHAR(doc_date,'dd/mm/yy') AS ledger_nar,
								DECODE(db_cr_flg,'D',payrec_amt,- payrec_amt) net_amt, payrec_type RECORD_SOURCE
								FROM 
								(
									SELECT MAX(GL_ACCT_CD) GL_ACCT_CD, MAX(SL_ACCT_CD) SL_ACCT_CD, TO_DATE(MAX(DOC_DATE),'yyyy/mm/dd hh24:mi:ss') DOC_DATE, MAX(DB_CR_FLG) DB_CR_FLG, MAX(PAYREC_AMT) PAYREC_AMT, MAX(PAYREC_TYPE) PAYREC_TYPE, MAX(RECORD_SOURCE) RECORD_SOURCE
									FROM
									(
										SELECT DECODE(field_name,'GL_ACCT_CD',field_value, NULL) GL_ACCT_CD,
												DECODE(field_name,'SL_ACCT_CD',field_value, NULL) SL_ACCT_CD,
												DECODE(field_name,'DOC_DATE',field_value, NULL) DOC_DATE,
												DECODE(field_name,'DB_CR_FLG',field_value, NULL) DB_CR_FLG,
												DECODE(field_name,'PAYREC_AMT',field_value, NULL) PAYREC_AMT,
												DECODE(field_name,'PAYREC_TYPE',field_value, NULL) PAYREC_TYPE,
												DECODE(field_name,'RECORD_SOURCE',field_value, NULL) RECORD_SOURCE,
												record_seq
										FROM  T_MANY_DETAIL
										WHERE T_MANY_DETAIL.update_date = v_update_date
										AND T_MANY_DETAIL.update_seq = v_update_seq
										AND T_MANY_DETAIL.table_name = 'T_PAYRECD'
										AND T_MANY_DETAIL.field_name IN ('GL_ACCT_CD', 'SL_ACCT_CD', 'DOC_DATE', 'DB_CR_FLG', 'PAYREC_AMT', 'PAYREC_TYPE', 'RECORD_SOURCE')
									)
									GROUP BY record_seq
								)
								WHERE record_source IN ('CG','CDUE')
								UNION ALL
								SELECT 2 sortk, gl_acct_cd, sl_acct_cd, v_ledger_nar,
								DECODE(db_cr_flg,'D',payrec_amt,- payrec_amt) net_amt,
								payrec_type RECORD_SOURCE
								FROM 
								(
									SELECT MAX(GL_ACCT_CD) GL_ACCT_CD, MAX(SL_ACCT_CD) SL_ACCT_CD, TO_DATE(MAX(DOC_DATE),'yyyy/mm/dd hh24:mi:ss') DOC_DATE, MAX(DB_CR_FLG) DB_CR_FLG, MAX(PAYREC_AMT) PAYREC_AMT, MAX(PAYREC_TYPE) PAYREC_TYPE, MAX(RECORD_SOURCE) RECORD_SOURCE
									FROM
									(
										SELECT DECODE(field_name,'GL_ACCT_CD',field_value, NULL) GL_ACCT_CD,
												DECODE(field_name,'SL_ACCT_CD',field_value, NULL) SL_ACCT_CD,
												DECODE(field_name,'DOC_DATE',field_value, NULL) DOC_DATE,
												DECODE(field_name,'DB_CR_FLG',field_value, NULL) DB_CR_FLG,
												DECODE(field_name,'PAYREC_AMT',field_value, NULL) PAYREC_AMT,
												DECODE(field_name,'PAYREC_TYPE',field_value, NULL) PAYREC_TYPE,
												DECODE(field_name,'RECORD_SOURCE',field_value, NULL) RECORD_SOURCE,
												record_seq
										FROM  T_MANY_DETAIL
										WHERE T_MANY_DETAIL.update_date = v_update_date
										AND T_MANY_DETAIL.update_seq = v_update_seq
										AND T_MANY_DETAIL.table_name = 'T_PAYRECD'
										AND T_MANY_DETAIL.field_name IN ('GL_ACCT_CD', 'SL_ACCT_CD', 'DOC_DATE', 'DB_CR_FLG', 'PAYREC_AMT', 'PAYREC_TYPE', 'RECORD_SOURCE')
									)
									GROUP BY record_seq
								)
								WHERE sl_acct_cd = rec.client_Cd
								AND record_source <> 'CG'
								AND record_source <> 'CDUE'
							)
							GROUP BY sortk,  gl_acct_cd, sl_acct_cd, ledger_nar, record_source
							HAVING SUM(net_amt) <> 0
						)
						UNION ALL
						SELECT 3 sortk, v_round_gl_a, v_round_sl_a,'Pembulatan', v_round_db_cr_flg, v_round_amt, v_payrec_type record_source
						FROM dual
						WHERE v_round_amt <> 0
						UNION ALL
						SELECT 555 sortk, gl_acct_cd, sl_acct_cd,TRIM(remarks)||' '||CLIENT_CD, DECODE(payrec_type,'PV','C','D') db_cr_flg, TO_NUMBER(curr_amt),
		                payrec_type record_source
						FROM 
						(
							SELECT MAX(GL_ACCT_CD) GL_ACCT_CD, MAX(SL_ACCT_CD) SL_ACCT_CD, MAX(REMARKS) REMARKS, MAX(DB_CR_FLG) DB_CR_FLG, MAX(CURR_AMT) CURR_AMT, MAX(PAYREC_TYPE) PAYREC_TYPE, MAX(CLIENT_CD) CLIENT_CD
							FROM
							(
								SELECT DECODE(field_name,'GL_ACCT_CD',field_value, NULL) GL_ACCT_CD,
										DECODE(field_name,'SL_ACCT_CD',field_value, NULL) SL_ACCT_CD,
										DECODE(field_name,'REMARKS',field_value, NULL) REMARKS,
										DECODE(field_name,'DB_CR_FLG',field_value, NULL) DB_CR_FLG,
										DECODE(field_name,'CURR_AMT',field_value, NULL) CURR_AMT,
										DECODE(field_name,'PAYREC_TYPE',field_value, NULL) PAYREC_TYPE,
										DECODE(field_name,'CLIENT_CD',field_value, NULL) CLIENT_CD,
										record_seq
								FROM  T_MANY_DETAIL
								WHERE T_MANY_DETAIL.update_date = v_update_date
								AND T_MANY_DETAIL.update_seq = v_update_seq
								AND T_MANY_DETAIL.table_name = 'T_PAYRECH'
								AND T_MANY_DETAIL.field_name IN ('GL_ACCT_CD', 'SL_ACCT_CD', 'REMARKS', 'DB_CR_FLG', 'CURR_AMT', 'PAYREC_TYPE', 'CLIENT_CD')
							)
							GROUP BY record_seq
						)						
					)
					ORDER BY sortk, gl_acct_cd;
			EXCEPTION
				WHEN OTHERS THEN
					v_error_code := -51;
					v_error_msg := SUBSTR('OPEN v_sys_cursor: T_ACCOUNT_LEDGER '||rec.client_cd||SQLERRM,1,200);
					RAISE v_err;
			END;
			
			v_ledger_record_seq  := 1;
			
			BEGIN
				SELECT dflg1 INTO v_sys_param_flg
				FROM MST_SYS_PARAM
				WHERE param_id = 'SYSTEM'
				AND param_cd1 = 'DOC_REF';
			EXCEPTION
				WHEN OTHERS THEN
					v_error_code := -61;
					v_error_msg := SUBSTR('Retrieve MST_SYS_PARAM for doc_ref'||SQLERRM,1,200);
					RAISE v_err;
			END;
			
			LOOP
				FETCH v_sys_cursor INTO v_ledger_rec;
				EXIT WHEN v_sys_cursor%NOTFOUND;
				
				BEGIN
					SELECT COUNT(*) INTO v_cnt
					FROM MST_CLIENT
					WHERE client_cd = v_ledger_rec.sl_acct_cd;
				EXCEPTION
					WHEN OTHERS THEN
						v_error_code := -62;
						v_error_msg := SUBSTR('COUNT MST_CLIENT '||SQLERRM,1,200);
						RAISE v_err;
				END;
				
				v_acct_type := NULL;
				
				IF v_cnt > 0 THEN
					BEGIN
						SELECT acct_type INTO v_acct_type
						FROM MST_GL_ACCOUNT
						WHERE TRIM(gl_a) = TRIM(v_ledger_rec.gl_acct_cd)
						AND sl_a = v_ledger_rec.sl_acct_cd;
					EXCEPTION
						WHEN OTHERS THEN
							v_error_code := -63;
							v_error_msg := SUBSTR('RETRIEVE MST_GL_ACCOUNT '||v_ledger_rec.gl_acct_cd||' '||v_ledger_rec.sl_acct_cd||' '||SQLERRM,1,200);
							RAISE v_err;
					END;
				END IF;
				
				--OPEN v_Many_detail FOR
					SELECT v_update_date AS update_date, v_update_seq AS update_seq, table_name, v_ledger_record_seq AS record_seq, NULL AS table_rowid, a.field_name,  field_type, b.field_value, 'I' AS status,  b.upd_flg
					BULK COLLECT INTO v_tab
					FROM(
						SELECT  'T_ACCOUNT_LEDGER' AS table_name, column_name AS field_name,
								DECODE(data_type,'VARCHAR2','S','CHAR','S','NUMBER','N','DATE','D','X') AS field_type
						FROM all_tab_columns
						WHERE table_name = 'T_ACCOUNT_LEDGER'
						AND OWNER = 'IPNEXTG'
					) a,
					( SELECT  'XN_DOC_NUM'  AS field_name, v_ledger_rec.xn_doc_num AS field_value, 'Y' upd_flg FROM dual
						UNION ALL
						SELECT  'TAL_ID'  AS field_name, TO_CHAR(v_ledger_rec.TAL_ID)  AS field_value, 'Y' upd_flg FROM dual
						UNION ALL
						SELECT  'DOC_REF_NUM'  AS field_name, DECODE(v_sys_param_flg,'Y',v_ledger_rec.xn_doc_num,NULL) AS field_value, 'N' upd_flg FROM dual
						UNION ALL
						SELECT  'ACCT_TYPE'  AS field_name, v_acct_type AS field_value, 'N' upd_flg FROM dual
						UNION ALL
						SELECT  'SL_ACCT_CD'  AS field_name, v_ledger_rec.SL_ACCT_CD AS field_value, 'Y' upd_flg FROM dual
						UNION ALL
						SELECT  'GL_ACCT_CD'  AS field_name, v_ledger_rec.GL_ACCT_CD AS field_value, 'Y' upd_flg FROM dual
						UNION ALL
						SELECT  'CHRG_CD'  AS field_name, NULL AS field_value, 'Y' upd_flg FROM dual
						UNION ALL
						SELECT  'CHQ_SNO'  AS field_name, NULL  AS field_value, 'Y' upd_flg FROM dual
						UNION ALL
						SELECT  'CURR_CD'  AS field_name, v_ledger_rec.CURR_CD AS field_value, 'Y' upd_flg FROM dual
						UNION ALL
						SELECT  'BRCH_CD'  AS field_name, v_ledger_rec.brch_cd AS field_value, 'Y' upd_flg FROM dual
						UNION ALL
						SELECT  'CURR_VAL'  AS field_name, TO_CHAR(v_ledger_rec.CURR_VAL)  AS field_value, 'Y' upd_flg FROM dual
						UNION ALL
						SELECT  'XN_VAL'  AS field_name, TO_CHAR(v_ledger_rec.XN_VAL)  AS field_value, 'Y' upd_flg FROM dual
						UNION ALL
						SELECT  'BUDGET_CD'  AS field_name, DECODE(v_payrec_type,'PV','PVCH','RVCH') AS field_value, 'Y' upd_flg FROM dual
						UNION ALL
						SELECT  'DB_CR_FLG'  AS field_name, v_ledger_rec.DB_CR_FLG AS field_value, 'Y' upd_flg FROM dual
						UNION ALL
						SELECT  'LEDGER_NAR'  AS field_name, v_ledger_rec.LEDGER_NAR AS field_value, 'Y' upd_flg FROM dual
						UNION ALL
						SELECT  'CASHIER_ID'  AS field_name, NULL AS field_value, 'Y' upd_flg FROM dual
						UNION ALL
						SELECT  'DOC_DATE'  AS field_name, TO_CHAR(v_ledger_rec.DOC_DATE,'yyyy/mm/dd hh24:mi:ss')  AS field_value, 'Y' upd_flg FROM dual
						UNION ALL
						SELECT  'DUE_DATE'  AS field_name, TO_CHAR(v_ledger_rec.DUE_DATE,'yyyy/mm/dd hh24:mi:ss')  AS field_value, 'Y' upd_flg FROM dual
						UNION ALL
						SELECT  'NETTING_DATE'  AS field_name, TO_CHAR(v_ledger_rec.NETTING_DATE,'yyyy/mm/dd hh24:mi:ss')  AS field_value, 'Y' upd_flg FROM dual
						UNION ALL
						SELECT  'NETTING_FLG'  AS field_name, NULL AS field_value, 'Y' upd_flg FROM dual
						UNION ALL
						SELECT  'RECORD_SOURCE'  AS field_name, v_ledger_rec.RECORD_SOURCE AS field_value, 'Y' upd_flg FROM dual
						UNION ALL
						SELECT  'SETT_FOR_CURR'  AS field_name, TO_CHAR(v_ledger_rec.SETT_FOR_CURR)  AS field_value, 'Y' upd_flg FROM dual
						UNION ALL
						SELECT  'SETT_STATUS'  AS field_name, NULL AS field_value, 'Y' upd_flg FROM dual
						UNION ALL
						SELECT  'RVPV_NUMBER'  AS field_name, v_ledger_rec.RVPV_NUMBER AS field_value, 'Y' upd_flg FROM dual
						UNION ALL
						SELECT  'FOLDER_CD'  AS field_name, v_ledger_rec.FOLDER_CD AS field_value, 'Y' upd_flg FROM dual
						UNION ALL
						SELECT  'SETT_VAL'  AS field_name, TO_CHAR(v_ledger_rec.SETT_VAL)  AS field_value, 'Y' upd_flg FROM dual
						UNION ALL
						SELECT  'ARAP_DUE_DATE'  AS field_name, TO_CHAR(v_ledger_rec.ARAP_DUE_DATE,'yyyy/mm/dd hh24:mi:ss')  AS field_value, 'Y' upd_flg FROM dual
						UNION ALL
						SELECT  'RVPV_GSSL'  AS field_name, NULL AS field_value, 'Y' upd_flg FROM dual
						UNION ALL
						SELECT  'REVERSAL_JUR'  AS field_name, v_ledger_rec.REVERSAL_JUR AS field_value, 'Y' upd_flg FROM dual
						UNION ALL
						SELECT  'MANUAL'  AS field_name, v_ledger_rec.MANUAL AS field_value, 'Y' upd_flg FROM dual
						UNION ALL
						SELECT  'CRE_DT'  AS field_name, TO_CHAR(SYSDATE,'yyyy/mm/dd hh24:mi:ss')  AS field_value, 'Y' upd_flg FROM dual
						UNION ALL
						SELECT  'USER_ID'  AS field_name, p_USER_ID AS field_value, 'Y' upd_flg FROM dual
					) b
					WHERE a.field_name = b.field_name;
					
				FORALL i in v_tab.first .. v_tab.last
					INSERT INTO T_MANY_DETAIL
					VALUES v_tab(i);
			
				/*BEGIN
					Sp_T_Many_Detail_Insert(v_update_date, v_update_seq, 'I', 'T_ACCOUNT_LEDGER', v_ledger_record_seq, NULL, v_MANY_DETAIL, v_error_code, v_error_msg);
				EXCEPTION
					WHEN OTHERS THEN
						v_error_code := -64;
						v_error_msg := SUBSTR('SP_T_MANY_DETAIL_INSERT T_ACCOUNT_LEDGER '||rec.CLIENT_cd||' '||SQLERRM,1,200);
						RAISE v_err;
				END;
				
				CLOSE v_many_detail;
				
				IF v_error_code < 0 THEN
					v_error_code := -65;
					v_error_msg := 'SP_T_MANY_DETAIL_INSERT T_ACCOUNT_LEDGER '||rec.CLIENT_cd||' '||v_error_msg;
					RAISE v_err;
				END IF;*/
				
				v_ledger_record_seq := v_ledger_record_seq + 1;
			END LOOP;
			
			CLOSE v_sys_cursor;
			
			BEGIN
				OPEN v_sys_cursor FOR
					SELECT xn_doc_num payrec_num, v_payrec_type payrec_type, v_dt_end0 payrec_date,
					rec.client_cd client_cd, gl_acct_cd, sl_acct_cd,
					db_cr_flg, SYSDATE,NULL,
					NULL, NULL, NULL,
					curr_val payrec_amt, p_user_id, /*TO_CHAR(v_dt_end0,'MMYY')||'ZZ1234567'*/ xn_doc_num doc_ref_num,
					tal_id, ledger_nar remarks,'VCH' record_source,
					NULL doc_date, V_FOLDER_CD ref_folder_cd, xn_doc_num gl_ref_num, 0, 0, rec.branch_code brch_cd,  tal_id doc_tal_id, NULL, v_dt_end0 due_date, NULL, 0
					FROM 
					(
						SELECT MAX(XN_DOC_NUM) XN_DOC_NUM, MAX(GL_ACCT_CD) GL_ACCT_CD, MAX(SL_ACCT_CD) SL_ACCT_CD, MAX(DB_CR_FLG) DB_CR_FLG, MAX(CURR_VAL) CURR_VAL, MAX(TAL_ID) TAL_ID, MAX(LEDGER_NAR) LEDGER_NAR
						FROM
						(
							SELECT DECODE(field_name,'XN_DOC_NUM',field_value, NULL) XN_DOC_NUM,
									DECODE(field_name,'GL_ACCT_CD',field_value, NULL) GL_ACCT_CD,
									DECODE(field_name,'SL_ACCT_CD',field_value, NULL) SL_ACCT_CD,
									DECODE(field_name,'DB_CR_FLG',field_value, NULL) DB_CR_FLG,
									DECODE(field_name,'CURR_VAL',field_value, NULL) CURR_VAL,
									DECODE(field_name,'TAL_ID',field_value, NULL) TAL_ID,
									DECODE(field_name,'LEDGER_NAR',field_value, NULL) LEDGER_NAR,
									record_seq
							FROM  T_MANY_DETAIL
							WHERE T_MANY_DETAIL.update_date = v_update_date
							AND T_MANY_DETAIL.update_seq = v_update_seq
							AND T_MANY_DETAIL.table_name = 'T_ACCOUNT_LEDGER'
							AND T_MANY_DETAIL.field_name IN ('XN_DOC_NUM', 'GL_ACCT_CD','SL_ACCT_CD','DB_CR_FLG','CURR_VAL','TAL_ID','LEDGER_NAR')
						)
						GROUP BY RECORD_SEQ
					)
					WHERE gl_acct_cd = v_round_gl_a
					AND sl_acct_cd = v_round_sl_a;
			EXCEPTION
				WHEN OTHERS THEN
					v_error_code := -71;
					v_error_msg := SUBSTR('OPEN v_sys_cursor: T_PAYRECD '||rec.client_cd||SQLERRM,1,200);
					RAISE v_err;
			END;
			
			LOOP 
				FETCH v_sys_cursor INTO v_detail_rec;
				EXIT WHEN v_sys_cursor%NOTFOUND;
				
				--OPEN v_Many_detail FOR	
					SELECT v_update_date AS update_date, v_update_seq AS update_seq, table_name, v_detail_record_seq AS record_seq, NULL AS table_rowid, a.field_name,field_type, b.field_value, 'I' AS status,  b.upd_flg
					BULK COLLECT INTO v_tab
					FROM(
						SELECT 'T_PAYRECD' AS table_name, column_name AS field_name,
		                       DECODE(data_type,'VARCHAR2','S','CHAR','S','NUMBER','N','DATE','D','X') AS field_type
						FROM all_tab_columns
						WHERE table_name = 'T_PAYRECD'
						AND OWNER = 'IPNEXTG'
					) a,
					( SELECT  'PAYREC_NUM'  AS field_name, v_detail_rec.payrec_num AS field_value, 'Y' upd_flg FROM dual
						UNION ALL
						SELECT  'PAYREC_TYPE'  AS field_name, v_detail_rec.PAYREC_TYPE AS field_value, 'Y' upd_flg FROM dual
						UNION ALL
						SELECT  'PAYREC_DATE'  AS field_name, TO_CHAR(v_detail_rec.payrec_date,'yyyy/mm/dd hh24:mi:ss')  AS field_value, 'Y' upd_flg FROM dual
						UNION ALL
						SELECT  'CLIENT_CD'  AS field_name, v_detail_rec.client_cd AS field_value, 'Y' upd_flg FROM dual
						UNION ALL
						SELECT  'GL_ACCT_CD'  AS field_name, v_detail_rec.gl_acct_cd AS field_value, 'Y' upd_flg FROM dual
						UNION ALL
						SELECT  'SL_ACCT_CD'  AS field_name, v_detail_rec.sl_acct_cd AS field_value, 'Y' upd_flg FROM dual
						UNION ALL
						SELECT  'DB_CR_FLG'  AS field_name, v_detail_rec.DB_CR_FLG AS field_value, 'Y' upd_flg FROM dual
						UNION ALL
						SELECT  'PAYREC_AMT'  AS field_name, TO_CHAR(v_detail_rec.payrec_amt)  AS field_value, 'Y' upd_flg FROM dual
						UNION ALL
						SELECT  'DOC_REF_NUM'  AS field_name, v_detail_rec.doc_ref_num AS field_value, 'Y' upd_flg FROM dual
						UNION ALL
						SELECT  'TAL_ID'  AS field_name, TO_CHAR(v_detail_rec.tal_id)  AS field_value, 'Y' upd_flg FROM dual
						UNION ALL
						SELECT  'REMARKS'  AS field_name, v_detail_rec.remarks AS field_value, 'Y' upd_flg FROM dual
						UNION ALL
						SELECT  'RECORD_SOURCE'  AS field_name, v_detail_rec.record_source AS field_value, 'Y' upd_flg FROM dual
						UNION ALL
						SELECT  'DOC_DATE'  AS field_name, TO_CHAR(v_detail_rec.doc_date,'yyyy/mm/dd hh24:mi:ss')  AS field_value, 'Y' upd_flg FROM dual
						UNION ALL
						SELECT  'REF_FOLDER_CD'  AS field_name, v_detail_rec.ref_folder_cd AS field_value, 'Y' upd_flg FROM dual
						UNION ALL
						SELECT  'GL_REF_NUM'  AS field_name, v_detail_rec.gl_ref_num AS field_value, 'Y' upd_flg FROM dual
						UNION ALL
						SELECT  'BRCH_CD'  AS field_name, v_detail_rec.BRCH_CD AS field_value, 'Y' upd_flg FROM dual
						UNION ALL
						SELECT  'DOC_TAL_ID'  AS field_name, TO_CHAR(v_detail_rec.doc_tal_id)  AS field_value, 'Y' upd_flg FROM dual
						UNION ALL
						SELECT  'DUE_DATE'  AS field_name, TO_CHAR(v_detail_rec.DUE_DATE,'yyyy/mm/dd hh24:mi:ss')  AS field_value, 'Y' upd_flg FROM dual
						UNION ALL
						SELECT  'CRE_DT'  AS field_name, TO_CHAR(SYSDATE,'yyyy/mm/dd hh24:mi:ss')  AS field_value, 'Y' upd_flg FROM dual
						UNION ALL
						SELECT  'USER_ID'  AS field_name, p_USER_ID AS field_value, 'Y' upd_flg FROM dual				
					) b
					WHERE a.field_name = b.field_name;
				
				FORALL i in v_tab.first .. v_tab.last
					INSERT INTO T_MANY_DETAIL
					VALUES v_tab(i);
				
				/*BEGIN
					Sp_T_Many_Detail_Insert(v_update_date, v_update_seq, 'I', 'T_PAYRECD', v_detail_record_seq, NULL, v_MANY_DETAIL, v_error_code, v_error_msg);
				EXCEPTION
					WHEN OTHERS THEN
						v_error_code := -72;
						v_error_msg := SUBSTR('SP_T_MANY_DETAIL_INSERT T_PAYRECD '||rec.CLIENT_cd||SQLERRM,1,200);
						RAISE v_err;
				END;
				
				CLOSE v_many_detail;*/
				
				v_detail_record_seq := v_detail_record_seq + 1;
				
				/*IF v_error_code < 0 THEN
					v_error_code := -73;
					v_error_msg := 'SP_T_MANY_DETAIL_INSERT T_PAYRECD '||rec.CLIENT_cd||' '||v_error_msg;
					RAISE v_err;
				END IF; */
			
			END LOOP;
			
			CLOSE v_sys_cursor;
			
			v_transfer_fee := 0;

			IF v_payrec_type = 'PV' OR v_recv_cheq_flg = 'Y' THEN								
				/*BEGIN
					SELECT cifs, bank_acct_num, olt INTO v_cifs, v_bank_acct_num, v_olt_flg
					FROM MST_CLIENT
					WHERE client_cd = rec.client_cd;
				EXCEPTION
					WHEN OTHERS THEN
						v_error_code := -82;
						v_error_msg := SUBSTR('RETRIEVE MST_CLIENT '||SQLERRM,1,200);
						RAISE v_err;
				END;						
			
				BEGIN
					SELECT acct_name, bank_cd INTO v_payee_name, v_payee_bank_cd
					FROM MST_CLIENT_BANK 
					WHERE cifs = v_cifs
					AND bank_acct_num = v_bank_acct_num;
				EXCEPTION
					WHEN OTHERS THEN
						v_error_code := -83;
						v_error_msg := SUBSTR('RETRIEVE MST_CLIENT_BANK '|| rec.client_cd || ' ' ||SQLERRM,1,200);
						RAISE v_err;
				END;
				
				BEGIN
					SELECT ip_bank_cd INTO v_rdi_bank_cd
					FROM MST_FUND_BANK 
					WHERE bank_cd = 
					(
						SELECT bank_cd 
						FROM MST_CLIENT_FLACCT
						WHERE client_cd = rec.client_cd
						AND acct_stat IN ('A','I')
					);
				EXCEPTION
					WHEN OTHERS THEN
						v_error_code := -84;
						v_error_msg := SUBSTR('RETRIEVE MST_FUND_BANK '||SQLERRM,1,200);
						RAISE v_err;
				END;
				
				BEGIN
					SELECT F_TRANSFER_FEE(v_bank_amt, v_rdi_bank_cd, v_payee_bank_cd, p_brch_cd, v_olt_flg, 'Y') INTO v_transfer_fee
					FROM dual;
				EXCEPTION
					WHEN OTHERS THEN
						v_error_code := -85;
						v_error_msg := SUBSTR('F_TRANSFER_FEE '||SQLERRM,1,200);
						RAISE v_err;
				END;*/
				
				--OPEN v_Many_detail FOR
					SELECT v_update_date AS update_date, v_update_seq AS update_seq, table_name, 1 AS record_seq, NULL AS table_rowid, a.field_name,field_type, b.field_value, 'I' AS status,  b.upd_flg
					BULK COLLECT INTO v_tab
					FROM(
						SELECT  'T_CHEQ' AS table_name, column_name AS field_name,
								DECODE(data_type,'VARCHAR2','S','CHAR','S','NUMBER','N','DATE','D','X') AS field_type
						FROM all_tab_columns
						WHERE table_name = 'T_CHEQ'
						AND OWNER = 'IPNEXTG'
					) a,
					( SELECT  'BANK_CD'  AS field_name, v_ip_bank_cd AS field_value, 'Y' upd_flg FROM dual
						UNION ALL
						SELECT  'SL_ACCT_CD'  AS field_name, v_bank_sla AS field_value, 'Y' upd_flg FROM dual
						UNION ALL
						SELECT  'BG_CQ_FLG'  AS field_name, 'RD' AS field_value, 'Y' upd_flg FROM dual
						UNION ALL
						SELECT  'CHQ_NUM'  AS field_name, v_folder_cd AS field_value, 'Y' upd_flg FROM dual
						UNION ALL
						SELECT  'CHQ_DT'  AS field_name, TO_CHAR(v_dt_end0,'yyyy/mm/dd hh24:mi:ss')  AS field_value, 'Y' upd_flg FROM dual
						UNION ALL
						SELECT  'CHQ_AMT'  AS field_name, TO_CHAR(v_bank_amt)  AS field_value, 'Y' upd_flg FROM dual
						UNION ALL
						SELECT  'RVPV_NUMBER'  AS field_name, v_doc_num AS field_value, 'Y' upd_flg FROM dual
						UNION ALL
						SELECT  'CHQ_STAT'  AS field_name, 'A' AS field_value, 'Y' upd_flg FROM dual
						UNION ALL
						SELECT  'PAYEE_BANK_CD'  AS field_name, v_PAYEE_BANK_CD AS field_value, 'Y' upd_flg FROM dual
						UNION ALL
						SELECT  'PAYEE_ACCT_NUM'  AS field_name, rec.bank_acct_fmt AS field_value, 'Y' upd_flg FROM dual
						UNION ALL
						SELECT  'DEDUCT_FEE'  AS field_name, '0'  AS field_value, 'Y' upd_flg FROM dual
						UNION ALL
						SELECT  'SEQNO'  AS field_name, '1'  AS field_value, 'Y' upd_flg FROM dual
						UNION ALL
						SELECT  'PAYEE_NAME'  AS field_name, v_payee_name AS field_value, 'Y' upd_flg FROM dual
						UNION ALL
						SELECT  'DESCRIP'  AS field_name, 'PB rek dana' AS field_value, 'Y' upd_flg FROM dual
						UNION ALL
						SELECT  'CHQ_SEQ'  AS field_name, '1'  AS field_value, 'Y' upd_flg FROM dual
						UNION ALL
						SELECT  'CRE_DT'  AS field_name, TO_CHAR(SYSDATE,'yyyy/mm/dd hh24:mi:ss')  AS field_value, 'Y' upd_flg FROM dual
						UNION ALL
						SELECT  'USER_ID'  AS field_name, p_USER_ID AS field_value, 'Y' upd_flg FROM dual
					) b
					WHERE a.field_name = b.field_name;	    

				FORALL i in v_tab.first .. v_tab.last
					INSERT INTO T_MANY_DETAIL
					VALUES v_tab(i);
						 
				/*BEGIN
					Sp_T_Many_Detail_Insert(v_update_date, v_update_seq, 'I', 'T_CHEQ', 1, NULL, v_MANY_DETAIL, v_error_code, v_error_msg);
				EXCEPTION
					WHEN OTHERS THEN
						v_error_code := -86;
						v_error_msg := SUBSTR('SP_T_MANY_DETAIL_INSERT T_CHEQ '||rec.CLIENT_cd||SQLERRM,1,200);
						RAISE v_err;
				END;
				
				CLOSE v_many_detail;
		
				IF v_error_code < 0 THEN
					v_error_code := -87;
					v_error_msg := 'SP_T_MANY_DETAIL_INSERT T_CHEQ '||rec.CLIENT_cd||' '||v_error_msg;
					RAISE v_err;
				END IF;*/
     		END IF;

/* sdh di insert di GET FOLDER NUM
		    BEGIN
		    INSERT INTO T_FOLDER (
		       FLD_MON, FOLDER_CD, DOC_DATE,
		       DOC_NUM, USER_ID, CRE_DT,
		       UPD_DT)
		    VALUES ( TO_CHAR(v_dt_end0,'MMYY'), v_folder_cd, v_dt_end0,
		        v_doc_num, p_user_id, SYSDATE, NULL );
		    EXCEPTION
		      WHEN OTHERS THEN
		      RAISE_APPLICATION_ERROR(-20100,'INSERT T_FOLDER '||rec.CLIENT_cd||' - '||v_doc_num||v_nl||SQLERRM);
		     END; */
			 
			--OPEN v_MANY_DETAIL FOR
				SELECT v_update_date AS update_date, v_update_seq AS update_seq, table_name, 1 AS record_seq, NULL AS table_rowid, a.field_name,  field_type, b.field_value, 'I' AS status,  b.upd_flg
				BULK COLLECT INTO v_tab
				FROM(
					SELECT  'T_FOLDER' AS table_name, column_name AS field_name, DECODE(data_type,'VARCHAR2','S','CHAR','S','NUMBER','N','DATE','D','X') AS field_type
					FROM all_tab_columns
					WHERE table_name = 'T_FOLDER'
					AND OWNER = 'IPNEXTG') a,
				( 
					SELECT  'FLD_MON'  AS field_name, TO_CHAR(v_dt_end0,'MMYY') AS field_value, 'Y' upd_flg FROM dual
					UNION ALL
					SELECT  'FOLDER_CD'  AS field_name, v_FOLDER_CD AS field_value, 'Y' upd_flg FROM dual
					UNION ALL
					SELECT  'DOC_DATE'  AS field_name, TO_CHAR(v_dt_end0,'yyyy/mm/dd hh24:mi:ss')  AS field_value, 'Y' upd_flg FROM dual
					UNION ALL
					SELECT  'DOC_NUM'  AS field_name, v_DOC_NUM AS field_value, 'Y' upd_flg FROM dual
					UNION ALL
					SELECT  'USER_ID'  AS field_name, p_USER_ID AS field_value, 'Y' upd_flg FROM dual
					UNION ALL
					SELECT  'CRE_DT'  AS field_name, TO_CHAR(SYSDATE,'yyyy/mm/dd hh24:mi:ss')  AS field_value, 'Y' upd_flg FROM dual			
				) b
				WHERE a.field_name = b.field_name;
				
			FORALL i in v_tab.first .. v_tab.last
				INSERT INTO T_MANY_DETAIL
				VALUES v_tab(i);
					
			/*BEGIN
				Sp_T_Many_Detail_Insert(v_update_date, v_update_seq, 'I', 'T_FOLDER', 1, NULL, v_MANY_DETAIL, v_error_code, v_error_msg);
			EXCEPTION
				WHEN OTHERS THEN
					v_error_code := -91;
					v_error_msg := SUBSTR('SP_T_MANY_DETAIL_INSERT T_FOLDER '||rec.CLIENT_cd||SQLERRM,1,200);
					RAISE v_err;
			END;
		
			CLOSE v_many_detail;

			IF v_error_code < 0 THEN
				v_error_code := -92;
				v_error_msg := 'SP_T_MANY_DETAIL_INSERT T_FOLDER '||rec.CLIENT_cd||' '||v_error_msg;
				RAISE v_err;
			END IF;*/
			
			BEGIN	
				SELECT COUNT(1)--, SUM(DECODE(DB_CR_FLG,'D',1,-1) * CURR_VAL)
				INTO V_CNT_TAL--, V_SUM_TAL
				FROM T_MANY_DETAIL
				WHERE UPDATE_DATE = v_update_date
				AND UPDATE_SEQ = v_update_seq
				AND TABLE_NAME = 'T_ACCOUNT_LEDGER'
				AND FIELD_NAME = 'XN_DOC_NUM'
				AND FIELD_VALUE = V_DOC_NUM;
			EXCEPTION
				WHEN OTHERS THEN
					v_error_code := -101;
					v_error_msg := SUBSTR('RETRIEVE T_MANY_DETAIL '||SQLERRM,1,200);
					RAISE v_err;
			END;
			
			BEGIN
				SELECT SUM(DECODE(DB_CR_FLG,'D',1,-1) * CURR_VAL) 
				INTO V_SUM_TAL
				FROM
				(
					SELECT MAX(DB_CR_FLG) DB_CR_FLG, MAX(CURR_VAL) CURR_VAL
					FROM
					(
						SELECT DECODE(field_name,'DB_CR_FLG',field_value, NULL) DB_CR_FLG,
								DECODE(field_name,'CURR_VAL',field_value, NULL) CURR_VAL,
								record_seq
						FROM  T_MANY_DETAIL
						WHERE T_MANY_DETAIL.update_date = v_update_date
						AND T_MANY_DETAIL.update_seq = v_update_seq
						AND T_MANY_DETAIL.table_name = 'T_ACCOUNT_LEDGER'
						AND T_MANY_DETAIL.field_name IN ('DB_CR_FLG', 'CURR_VAL')
					)
					GROUP BY RECORD_SEQ
				);
			EXCEPTION
				WHEN OTHERS THEN
					v_error_code := -102;
					v_error_msg := SUBSTR('RETRIEVE T_MANY_DETAIL '||SQLERRM,1,200);
					RAISE v_err;
			END;
			
			BEGIN
				SELECT COUNT(1)
				INTO V_CNT_PAYREC
				FROM T_MANY_DETAIL
				WHERE UPDATE_DATE = v_update_date
				AND UPDATE_SEQ = v_update_seq
				AND TABLE_NAME = 'T_PAYRECD'
				AND FIELD_NAME = 'PAYREC_NUM'
				AND FIELD_VALUE = V_DOC_NUM;
			EXCEPTION
				WHEN OTHERS THEN
					v_error_code := -103;
					v_error_msg := SUBSTR('RETRIEVE T_MANY_DETAIL '||SQLERRM,1,200);
					RAISE v_err;
			END;

		    IF V_CNT_TAL = 0 THEN
				v_fail_flg := TRUE;
				v_fail_msg := 'TIDAK ADA JURNAL '||rec.client_cd||' '||v_doc_num;
				--RAISE_APPLICATION_ERROR(-20100,'NO T_A_L RECORD '||rec.CLIENT_cd||' - '||v_doc_num||v_nl||SQLERRM);

		    ELSIF V_CNT_PAYREC = 0 THEN
				v_fail_flg := TRUE;
				v_fail_msg := 'TIDAK ADA DETAIL VCH '||rec.client_cd||' '||v_doc_num;
				--RAISE_APPLICATION_ERROR(-20100,'NO T_PAYRECD RECORD '||rec.CLIENT_cd||' - '||v_doc_num||v_nl||SQLERRM);

		    ELSIF V_SUM_TAL <> 0 THEN
				v_fail_flg := TRUE;
				v_fail_msg := 'JURNAL TIDAK BALANCE '||rec.client_cd||' '||v_doc_num;
				--RAISE_APPLICATION_ERROR(-20100,'JURNAL TIDAK BALANCE '||rec.CLIENT_cd||' - '||v_doc_num||v_nl||SQLERRM);
		    END IF;

			IF v_fail_flg = FALSE THEN
				IF v_payrec_type = 'PV' THEN
					v_ap_vch_cnt := v_ap_vch_cnt + 1;
				ELSE
					v_ar_vch_cnt := v_ar_vch_cnt + 1;
				END IF;
			END IF;
		ELSE
			v_fail_flg := TRUE;
			--v_fail_msg := ''||rec.client_cd||' '||v_doc_num;
		END IF;

		IF v_fail_flg THEN
			ROLLBACK TO init_state;
		
			BEGIN -- 7MAY 13
				INSERT INTO T_AUTO_TRF_FAIL 
				(
					PAYREC_DATE, PAYREC_TYPE, CLIENT_CD,
					OUTS_AMT, TRF_AMT, CRE_DT,
					USER_ID, VCH_TYPE, DESCRIP
				)
				VALUES 
				( 
					v_dt_end0,v_payrec_type, rec.client_Cd,
					v_tot_settle, (rec.est_qq_masuk + rec.est_qq_keluar), SYSDATE,p_user_id,'KBB', v_fail_msg
				);
			EXCEPTION
				WHEN OTHERS THEN
					v_error_code := -111;
					v_error_msg := SUBSTR('INSERT T_AUTO_TRF '||rec.client_cd||' '||SQLERRM,1,200);
					RAISE v_err;
			END;

			v_fail_cnt := v_fail_cnt + 1;
			
		ELSE	
			v_success_cnt := v_success_cnt + 1;
		END IF;

	END LOOP;

	p_ap_vch := v_ap_vch_cnt;
	p_ar_vch := v_ar_vch_cnt;
	p_success_cnt := v_success_cnt;
	p_fail_cnt := v_fail_cnt;
	p_fail_msg := v_fail_msg;
	
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
		p_error_code := -1;
		p_error_msg := SUBSTR(SQLERRM,1,200);
		ROLLBACK;
		RAISE;
END Sp_Rvpv_Auto_Trf;