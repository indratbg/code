create or replace PROCEDURE SP_Rvpv_Trf_Fl(  p_payrec_num         T_PAYRECH.payrec_num%TYPE,
         p_user_id                    T_ACCOUNT_LEDGER.user_id%TYPE,
		 p_approved_user_id			  T_MANY_HEADER.user_id%TYPE,
		 vo_errcode		OUT			  NUMBER,
		 vo_errmsg		OUT			  VARCHAR2
)  IS
tmpVar NUMBER;
/******************************************************************************
   NAME:       RVPV_TRF_FL
   PURPOSE:   bikin vocer utk transfer dr / ke rek dana
13 JUN 2017 UNTUK HADLE JURNAL YJFUND YANG ACCT TYPE VOUCHER 'ROR'
21APR2017 UBAH UNTUK HANDLE JURNAL VOUCHER INTRANSIT MU
14jun 13 - spy bisa dipakai utk vocer trf saldo AP ke KSEI ,
           T_PAYRECH.acct_type = 'KSEI''
		   tiap PV vocer generate FL RECEIVE jurnal
		   tiap RV vocer generate FL WITHDRAW jurnal


   NOTES:
******************************************************************************/





CURSOR csr_fl( a_doc_num  T_PAYRECH.payrec_num%TYPE)  IS
SELECT payrec_num, payrec_type, payrec_DATE, p.client_cd,
DECODE(mc.client_type_3,'M','M','R') m_r_type,
p.gl_acct_cd AS bank_gl_acct_cd,
p.sl_acct_cd AS bank_sl_acct_cd,
 t.tal_id AS bank_tal_id,
 t.ledger_nar AS bank_ledger_nar,
t.curr_val AS bank_amt,
b.bank_acct_cd AS pe_bank_acct,
bm.BANK_NAME AS pe_bank_name,
f.BANK_ACCT_NUM fund_bank_acct,
NVL(f.bank_short_name,'KSEI') fund_bank_name,
f.acct_name AS fund_acct_name,
f.bank_cd AS fund_bank_cd
FROM T_PAYRECH p, T_ACCOUNT_LEDGER t,
MST_CLIENT mc,
MST_BANK_ACCT b, MST_BANK_MASTER bm,
( SELECT client_cd, bank_acct_num, bank_short_name, acct_name, bank_cd
   FROM mst_client_flacct
   WHERE acct_stat <> 'C')  f
WHERE payrec_num = a_doc_num
AND payrec_num = xn_doc_num
AND trim(t.gl_acct_cd) = trim(p.gl_acct_cd)
AND trim(t.gl_acct_cd) = trim(b.GL_ACCT_CD)
AND t.sl_acct_cd = b.sl_acct_cd
AND b.bank_cd = bm.bank_cd (+)
AND p.client_cd = mc.client_cd
AND p.client_cd = f.client_cd (+);


CURSOR csr_tarikan(a_doc_num  T_PAYRECH.payrec_num%TYPE) IS
SELECT q.seqno,
f.BANK_ACCT_NUM fund_bank_acct,
f.bank_short_name fund_bank_name,
q.PAYEE_BANK_CD,
q.PAYEE_ACCT_NUM,
q.PAYEE_NAME
FROM T_PAYRECH h, T_CHEQ q,
( SELECT client_cd, bank_acct_num, bank_short_name, acct_name
   FROM mst_client_flacct
   WHERE acct_stat <> 'C')  f
WHERE h.payrec_num = a_doc_num
AND h.payrec_type IN ( 'PV','PD')
--AND h.acct_type ='RDM'--13JUN2017
AND h.acct_type IN ('RDM','ROR')--13JUN2017 
AND h.payrec_num = q.RVPV_NUMBER
AND h.client_cd = f.client_cd;


v_payrec_num T_PAYRECH.payrec_num%TYPE;
v_doc_num    T_ACCOUNT_LEDGER.xn_doc_num%TYPE;
v_ledger_nar T_ACCOUNT_LEDGER.ledger_nar%TYPE;
v_record_source T_ACCOUNT_LEDGER.record_source%TYPE;
v_folder_cd  T_ACCOUNT_LEDGER.folder_cd%TYPE;
v_payrec_type         T_PAYRECH.payrec_type%TYPE;
vi_payrec_type         T_PAYRECH.payrec_type%TYPE;
v_client  T_PAYRECH.client_cd%TYPE;
--v_rek_dana T_PAYRECH.rek_dana_flg%TYPE;
v_payrec_date T_PAYRECH.payrec_date%TYPE;
v_DOC_REF_NUM T_PAYRECD.DOC_REF_NUM%TYPE;
v_budget_cd T_ACCOUNT_LEDGER.budget_cd%TYPE;
v_DOC_REF_NUM2 T_FUND_MOVEMENT.doc_ref_num2%TYPE;
v_acct_type T_PAYRECH.acct_type%TYPE;
v_transfer_fee T_FUND_MOVEMENT.fee%TYPE;
--v_bank_cd T_FUND_MOVEMENT.fund_bank_cd%TYPE;

v_fund_bank_acct mst_client_flacct.BANK_ACCT_NUM%TYPE;
v_fund_bank_name mst_client_flacct.bank_short_name%TYPE;
v_fund_acct_name mst_client_flacct.acct_name%TYPE;

v_mode CHAR(1);
v_fl_source    T_FUND_MOVEMENT.source%TYPE;
v_nl CHAR(2);
v_Cnt NUMBER;
v_intransit_cnt NUMBER;
v_create_vch CHAR(1);
v_fl_type CHAR(1);

v_db_cr_arap CHAR(1);
v_lawan VARCHAR2(10);
v_gla_bank_intransit T_PAYRECD.gl_acct_cd%TYPE;
vl_err EXCEPTION;

BEGIN

BEGIN
SELECT gl_a INTO v_gla_bank_intransit
FROM MST_GLA_TRX
WHERE jur_type = 'BANKINTR';
EXCEPTION
WHEN NO_DATA_FOUND THEN
   v_gla_bank_intransit :='@';
WHEN OTHERS THEN
	 vo_errcode := -1;
	 vo_errmsg := 'MST_GLA_TRX '||SQLERRM;
   RAISE vl_err;
END;

BEGIN
SELECT COUNT(h.payrec_num) INTO v_cnt
FROM T_PAYRECH h,
T_PAYRECD d,
( SELECT client_cd, acct_stat
   FROM mst_client_flacct
   WHERE acct_stat <> 'C')  f
WHERE h.payrec_num = p_payrec_num
AND d.payrec_num = p_payrec_num
AND h.client_cd IS NOT NULL
AND trim(h.acct_type) <> 'DIV'
AND h.client_cd = f.client_cd (+)
AND (( f.acct_stat = 'A'
		AND (TRIM(d.gl_Acct_cd) = trim(v_gla_bank_intransit) OR
			h.payrec_type = 'RV' OR h.payrec_type = 'PV'  ))
--	OR (  h.acct_type IN ('RDI','RDM')   ) );--13JUN2017
OR (  h.acct_type IN ('RDI','RDM','ROR')   ) );
EXCEPTION
WHEN NO_DATA_FOUND THEN
   v_cnt := 0 ;
WHEN OTHERS THEN
	 vo_errcode := -2;
	 vo_errmsg := 'Get '||p_payrec_num||SQLERRM;
   RAISE vl_err;
END;

 IF v_cnt = 0 THEN
    RETURN;
 END IF;

   BEGIN
   SELECT  payrec_date, BANK_ACCT_NUM, bank_short_name, acct_name, folder_cd, acct_type--, bank_cd
   INTO v_payrec_date, v_fund_bank_acct, v_fund_bank_name, v_fund_acct_name, v_folder_cd, v_acct_type--, v_bank_cd
   FROM T_PAYRECH,
   ( SELECT client_cd, BANK_ACCT_NUM, bank_short_name, acct_name--, bank_cd
   FROM mst_client_flacct
   WHERE acct_stat <> 'C')  f
   WHERE payrec_num = p_payrec_num
   AND T_PAYRECH.client_cd = f.client_Cd(+)
   AND ((f.client_Cd IS NULL AND T_PAYRECH.acct_type = 'KSEI') OR
        f.client_Cd IS NOT NULL);
   EXCEPTION
   WHEN NO_DATA_FOUND THEN
   		vo_errcode := -3;
		 vo_errmsg := 'MST CLIENT FLACCT not found '||p_payrec_num||SQLERRM;
	   RAISE vl_err;
	WHEN OTHERS THEN
		 vo_errcode := -4;
		 vo_errmsg := 'Get MST CLIENT FLACCT '||p_payrec_num||SQLERRM;
	   RAISE vl_err;
	END;

   BEGIN
   SELECT COUNT(1) INTO v_intransit_cnt
   FROM T_PAYRECD
   WHERE payrec_num = p_payrec_num
   AND TRIM(gl_acct_cd) = v_gla_bank_intransit;
   EXCEPTION
   WHEN NO_DATA_FOUND THEN
      v_intransit_cnt := 0;
	  WHEN OTHERS THEN
		 vo_errcode := -5;
		 vo_errmsg := 'Get gla_bank_intransit '||p_payrec_num||SQLERRM;
	   RAISE vl_err;
   END;

   vi_payrec_type := SUBSTR(p_payrec_num,5,2);


   IF vi_payrec_type = 'RD' THEN

   	  IF v_intransit_cnt > 0 THEN -- receive dr clie ke bank PE, transfer ke rek dana
        v_create_vch := 'P';
   		V_fl_type := 'R';
	  ELSE
        v_create_vch := 'N';
   		V_fl_type := 'W';

	  END IF;


   END IF;

   IF vi_payrec_type = 'RV' THEN

        v_create_vch := 'N';
   V_fl_type := 'W';

   END IF;

   IF vi_payrec_type = 'PV' THEN

        v_create_vch := 'N';
   		V_fl_type := 'R';

   END IF;

    IF vi_payrec_type = 'PD' THEN
	   IF trim(v_acct_type) = 'RDM' OR trim(V_ACCT_TYPE)='ROR' THEN
	   	   v_create_vch := 'N';
   		   V_fl_type := 'R';
         --21APR2017 UNTUK PDA INTRANSIT MU
         IF v_intransit_cnt>0 THEN
            v_create_vch := 'R';
            V_fl_type := 'W';
         END IF;
		ELSE
		  v_create_vch := 'R';
   		  V_fl_type := 'W';
		END IF;
	END IF;

 v_record_source := 'VCH';
    v_doc_ref_num := '0112ZZ1234567';

 IF v_create_vch = 'R' THEN
    v_payrec_type := 'RD';
    v_ledger_nar := 'Pindah DARI Rek dana';
	v_budget_Cd := 'RVCH';
 ELSIF v_create_vch = 'P' THEN
     v_payrec_type := 'PD';
    v_ledger_nar := 'Pindah KE Rek dana';
	v_budget_Cd := 'PVCH';

 END IF;

 IF v_create_vch = 'N' THEN
    v_doc_num := p_payrec_num;
	v_doc_ref_num2 := NULL;
 ELSE
        v_doc_num := Get_Docnum_Vch(v_payrec_date, v_create_vch||'F');
        v_doc_num := SUBSTR(v_doc_num,1,6)||'A'||SUBSTR(v_doc_num,8);
		v_doc_ref_num2 := v_doc_num;

		v_folder_cd := F_Get_Folder_Num(v_payrec_date, 'F'||v_create_vch);
		
		IF v_folder_cd IS NOT NULL THEN
			BEGIN 
			  INSERT INTO T_FOLDER (
				FLD_MON, FOLDER_CD, DOC_DATE, 
				DOC_NUM, USER_ID, CRE_DT, 
				UPD_DT)
			  VALUES(
				to_char(v_payrec_date,'mmyy'),
				v_folder_cd,
				v_payrec_date,
				v_doc_num,
				p_user_id,
				SYSDATE,
				NULL);
			EXCEPTION
			  WHEN OTHERS THEN
				vo_errcode := -100;
				vo_errmsg :=SUBSTR('INSERT INTO T_FOLDER '||SQLERRM,1,200);
				RAISE VL_ERR;
			END;	  
		END IF;

	BEGIN
     INSERT INTO IPNEXTG.T_PAYRECH (
     PAYREC_NUM, PAYREC_TYPE, PAYREC_DATE,
     ACCT_TYPE, SL_ACCT_CD, CURR_CD,
     CURR_AMT, PAYREC_FRTO, REMARKS,
     USER_ID, CRE_DT, UPD_DT,
     APPROVED_STS, APPROVED_BY, APPROVED_DT,
     GL_ACCT_CD, CLIENT_CD, CHECK_NUM,
     FOLDER_CD, NUM_CHEQ)
  SELECT
   v_doc_NUM, v_PAYREC_TYPE, PAYREC_DATE,
     ACCT_TYPE, SL_ACCT_CD, CURR_CD,
     CURR_AMT, 'REK DANA', v_ledger_nar,
     p_USER_ID, SYSDATE, SYSDATE,
     APPROVED_STS, NULL, SYSDATE,
     GL_ACCT_CD, CLIENT_CD, CHECK_NUM,
     v_FOLDER_CD, NUM_CHEQ
     FROM T_PAYRECH
     WHERE payrec_num = p_payrec_num;
	 EXCEPTION
	 WHEN OTHERS THEN
	  vo_errcode := -6;
		 vo_errmsg := 'insert T_PAYRECH '||v_doc_NUM||SQLERRM;
	   RAISE vl_err;
	 END;

	 BEGIN
  INSERT INTO IPNEXTG.T_PAYRECD (
     PAYREC_NUM, PAYREC_TYPE, PAYREC_DATE,
     CLIENT_CD, GL_ACCT_CD, SL_ACCT_CD,
     DB_CR_FLG, CRE_DT, UPD_DT,
     APPROVED_STS, APPROVED_BY, APPROVED_DT,
     PAYREC_AMT, USER_ID, DOC_REF_NUM,
     TAL_ID, REMARKS, RECORD_SOURCE,
     DOC_DATE, REF_FOLDER_CD, GL_REF_NUM)
  SELECT
  v_doc_NUM, v_payrec_type, PAYREC_DATE,
     CLIENT_CD, GL_ACCT_CD, SL_ACCT_CD,
     DECODE(DB_CR_FLG,'C','D','C'), SYSDATE, SYSDATE,
     APPROVED_STS, NULL, SYSDATE,
     PAYREC_AMT, p_USER_ID, v_doc_NUM,
     TAL_ID, v_ledger_nar, RECORD_SOURCE,
     DOC_DATE, REF_FOLDER_CD, GL_REF_NUM
     FROM T_PAYRECD
     WHERE payrec_num = p_payrec_num;
	 EXCEPTION
	 WHEN OTHERS THEN
	  vo_errcode := -7;
		 vo_errmsg := 'insert T_PAYRECD '||v_doc_NUM||SQLERRM;
	   RAISE vl_err;
	 END;



	 BEGIN
     INSERT INTO IPNEXTG.T_ACCOUNT_LEDGER (
     XN_DOC_NUM, TAL_ID, DOC_REF_NUM,
     ACCT_TYPE, SL_ACCT_CD, GL_ACCT_CD,
     CHRG_CD, CHQ_SNO, CURR_CD,
     BRCH_CD, CURR_VAL, XN_VAL,
     BUDGET_CD, DB_CR_FLG, LEDGER_NAR,
     CASHIER_ID, USER_ID, CRE_DT,
     UPD_DT, DOC_DATE, DUE_DATE,
     NETTING_DATE, NETTING_FLG, RECORD_SOURCE,
     SETT_FOR_CURR, SETT_STATUS, RVPV_NUMBER,
     APPROVED_STS, APPROVED_BY, APPROVED_DT,
     FOLDER_CD, SETT_VAL)
     SELECT
     v_DOC_NUM, TAL_ID, v_DOC_NUM,
     ACCT_TYPE, SL_ACCT_CD, GL_ACCT_CD,
     CHRG_CD, CHQ_SNO, CURR_CD,
     BRCH_CD, CURR_VAL, XN_VAL,
     v_budget_Cd, DECODE(DB_CR_FLG,'D','C','D'), LEDGER_NAR,
     CASHIER_ID, p_USER_ID, SYSDATE,
     SYSDATE, DOC_DATE, DUE_DATE,
     NETTING_DATE, NETTING_FLG, RECORD_SOURCE,
     SETT_FOR_CURR, SETT_STATUS, RVPV_NUMBER,
     APPROVED_STS, NULL, SYSDATE,
     v_FOLDER_CD, SETT_VAL
     FROM  T_ACCOUNT_LEDGER
     WHERE xn_doc_num = p_payrec_num;
	 EXCEPTION
	 WHEN OTHERS THEN
	  vo_errcode := -8;
		 vo_errmsg := 'insert TAL '||v_DOC_NUM||SQLERRM;
	   RAISE vl_err;
	 END;

 END IF;

 FOR rec IN csr_fl(v_doc_num)
 LOOP


 	 IF v_fl_type = 'R' THEN

       v_mode := 'R';
       IF trim(V_ACCT_TYPE) ='ROR' THEN
          v_fl_source := 'VCHFUND';
        ELSE
          v_fl_source := 'VCH';
        END IF;
        
        SP_Fl_Jurnal(rec.payrec_DATE,
                  v_mode,
    			  v_fl_source,
                  rec.client_cd,
                  rec.m_r_type,
                  p_payrec_num,
                  rec.bank_tal_id,
                  rec.bank_gl_acct_cd,
                  rec.bank_sl_acct_cd,
   			   	  rec.fund_acct_name,
                  'Terima dr PE',
   			   	  'PE',
    			   rec.pe_bank_acct,
    			   rec.pe_bank_name,
    			   rec.client_cd,
    			   REC.fund_BANK_ACCT,
    			   rec.fund_bank_name,
                  ABS(rec.bank_amt),
				  rec.fund_bank_cd,
   				  v_doc_ref_num2,
				  NULL,
				  0, NULL,
                  p_user_id,
				  p_approved_user_id);

      END IF;

	  IF v_fl_type = 'W' THEN

           v_mode := 'W';
     	  IF trim(V_ACCT_TYPE) ='ROR' THEN
          v_fl_source := 'VCHFUND';
        ELSE
          v_fl_source := 'VCH';
        END IF;

           SP_Fl_Jurnal(rec.payrec_DATE,
                     v_mode,
					 v_fl_source,
                     rec.client_cd,
                     rec.m_r_type,
                     p_payrec_num,
                     rec.bank_tal_id,
                     rec.bank_gl_acct_cd,
                     rec.bank_sl_acct_cd,
					 rec.fund_acct_name,
                     'Transfer ke PE',
					 rec.client_cd,
			         REC.fund_BANK_ACCT,
			         rec.fund_bank_name,
			          'PE',
			         rec.pe_bank_acct,
			         rec.pe_bank_name,
                     ABS(rec.bank_amt),
					 rec.fund_bank_cd,
					v_doc_ref_num2,
					NULL,0,NULL,
                    p_user_id,
					p_approved_user_id);


	    END IF;

      FOR recw IN csr_tarikan( p_payrec_num )
      LOOP
  
             v_mode := 'W';
           IF trim(V_ACCT_TYPE) ='ROR' THEN
          v_fl_source := 'VCHFUND';
        ELSE
          v_fl_source := 'VCH';
        END IF;
  
         BEGIN
         SELECT doc_num, NVL(T_CHEQ.deduct_fee,0)
         INTO v_doc_ref_num2, v_transfer_fee
         FROM T_FUND_MOVEMENT, T_CHEQ
         WHERE doc_date = rec.payrec_DATE
         AND doc_ref_num = p_payrec_num
         AND trx_type = 'R'
         AND approved_sts = 'A'
         AND T_CHEQ.chq_dt =rec.payrec_DATE
         AND T_CHEQ.rvpv_number = p_payrec_num;
         EXCEPTION
         WHEN NO_DATA_FOUND THEN
           vo_errcode := -9;
           vo_errmsg := 'T_FUND_MOVEMENT doc_ref_num = '||p_payrec_num||SQLERRM;
             RAISE vl_err;
         END;
  
             SP_Fl_Jurnal(rec.payrec_DATE,
                       v_mode,
             v_fl_source,
                       rec.client_cd,
                       rec.m_r_type,
                       NULL,
                       rec.bank_tal_id,
                       rec.bank_gl_acct_cd,
                       rec.bank_sl_acct_cd,
             recW.payee_name,
                       trim(rec.bank_ledger_nar)||' '||v_folder_cd,
               'FUND',
                rec.fund_bank_acct,
                rec.fund_bank_name,
                 'LUAR',
                recW.payee_acct_num,
                recW.payee_bank_cd,
                         ABS(rec.bank_amt),
            rec.fund_bank_cd,
            v_doc_ref_num2,
            NULL,
            v_transfer_fee,
            NULL,
                      p_user_id,
            p_approved_user_id);
  
      -- v_doc_ref_num2  := RFxxx
         BEGIN
         SELECT doc_num INTO v_doc_num
         FROM T_FUND_MOVEMENT
         WHERE doc_date = rec.payrec_DATE
         AND doc_ref_num IS NULL
         AND doc_ref_num2 = v_doc_ref_num2
         AND trx_type = 'W'
         AND approved_sts = 'A';
         EXCEPTION
         WHEN NO_DATA_FOUND THEN
           vo_errcode := -10;
           vo_errmsg := 'T_FUND_MOVEMENT doc_ref_num2 = '||v_doc_ref_num2||SQLERRM;
             RAISE vl_err;
         END;
         -- v_doc_num berisi WFxxx
  
         BEGIN
        UPDATE T_FUND_MOVEMENT
        SET doc_ref_num2 = v_doc_num
        WHERE doc_date = rec.payrec_DATE
         AND doc_num = v_doc_ref_num2
         AND trx_type = 'R'
         AND approved_sts = 'A';
         EXCEPTION
         WHEN NO_DATA_FOUND THEN
           vo_errcode := -11;
           vo_errmsg := 'upd T_FUND_MOVEMENT doc_num = '||v_doc_ref_num2||SQLERRM;
             RAISE vl_err;
         END;
  
  --================================begin insert to cash transaction untuk voucher acct type 'ROR'=========================================
          IF trim(V_ACCT_TYPE) = 'ROR' THEN
            --CALL SP_CASH_TRX_INSERT
          --  v_doc_num := Get_Docnum_Fund(v_payrec_date,'W');
            BEGIN
            SP_PAYMENT_INSERT(
                    v_payrec_date,
                    v_doc_num,
                    ABS(rec.bank_amt),--vi_curr_credit,
                    rec.client_cd,--vi_sl_code,
                    p_user_id,--vi_user_id,
                    vo_errcode,
                    vo_errmsg);
             EXCEPTION
                   WHEN NO_DATA_FOUND THEN
                     vo_errcode := -15;
                     vo_errmsg := SUBSTR('CALL SP_CASH_TRX_INSERT '||SQLERRM,1,200);
                       RAISE vl_err;
                   END;
          
              IF  vo_errcode <0 THEN
                  vo_errcode := -20;
                  vo_errmsg := SUBSTR('CALL SP_CASH_TRX_INSERT '||vo_errmsg,1,200);
                  RAISE vl_err;
              END IF; 
          
          END IF;--END IF ACCT TYPE=ROR

--================================end insert to cash transaction untuk voucher acct type 'ROR'=========================================

      END LOOP;

     END LOOP;



	 vo_errcode :=1;
	 vo_errmsg := ' ';
   EXCEPTION
     WHEN vl_err THEN
	 	  ROLLBACK;

     WHEN NO_DATA_FOUND THEN
       NULL;
     WHEN OTHERS THEN
		vo_errcode := -99;
		vo_errmsg := SUBSTR(SQLERRM(SQLCODE),1,200);
       -- Consider logging the error and then re-raise
       RAISE;
END SP_Rvpv_Trf_Fl;