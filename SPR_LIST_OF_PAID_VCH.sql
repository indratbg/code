create or replace 
PROCEDURE SPR_LIST_OF_PAID_VCH(
    P_BGN_DATE      DATE,
    P_END_DATE      DATE,
    P_BGN_CLIENT    VARCHAR2,
    P_END_CLIENT    VARCHAR2,
    P_VCH_TYPE      VARCHAR2,
    P_TYPE          VARCHAR2,
    P_BGN_FOLDER_CD VARCHAR2,
    P_END_FOLDER_CD VARCHAR2,
    P_USER_ID       VARCHAR2,
    P_GENERATE_DATE DATE,
    P_RANDOM_VALUE OUT NUMBER,
    P_ERROR_CD OUT NUMBER,
    P_ERROR_MSG OUT VARCHAR2 )
IS
  V_ERROR_MSG    VARCHAR2(200);
  V_ERROR_CD     NUMBER(10);
  V_RANDOM_VALUE NUMBER(10);
  V_ERR          EXCEPTION;
  
BEGIN

  V_RANDOM_VALUE := ABS(DBMS_RANDOM.RANDOM);
  
  IF P_TYPE       ='INVOICE' THEN
  
    BEGIN
      SP_RPT_REMOVE_RAND('R_LIST_OF_PAID_INVOICE',V_RANDOM_VALUE,V_ERROR_MSG,V_ERROR_CD);
    EXCEPTION
    WHEN OTHERS THEN
      V_ERROR_CD  := -30;
      V_ERROR_MSG := SUBSTR('SP_RPT_REMOVE_RAND '||V_ERROR_MSG||SQLERRM(SQLCODE),1,200);
      RAISE V_err;
    END;
    
    IF V_ERROR_CD  <0 THEN
      V_ERROR_CD  := -40;
      V_ERROR_MSG := SUBSTR('SP_RPT_REMOVE_RAND'||V_ERROR_MSG,1,200);
      RAISE V_ERR;
    END IF;
    
    BEGIN
      INSERT
      INTO R_LIST_OF_PAID_INVOICE
        (
          CONTR_NUM ,
          CONTR_DT ,
          CLIENT_CD ,
          STK_CD ,
          AMT_FOR_CURR ,
          LEDGER_NAR ,
          OLD_IC_NUM ,
          FOLDER_CD ,
          SL_ACCT_CD ,
          PAYREC_DATE ,
          GL_ACCT_CD ,
          CHQ_NUM ,
          BGN_DATE ,
          END_DATE ,
          VCH_TYPE ,
          USER_ID ,
          RAND_VALUE ,
          GENERATEDATE,
          REF_NUM
        )
      SELECT a.contr_num,
        a.contr_dt,
        a.client_cd,
        a.stk_Cd,
        a.amt_for_curr,
        a.ledger_nar,
        a.old_ic_num,
        b.folder_cd,
        b.sl_acct_cd,
        b.payrec_date,
        b.gl_Acct_cd,
        q.chq_num ,
        P_BGN_DATE,
        P_END_DATE,
        P_VCH_TYPE ,
        P_USER_ID,
        V_RANDOM_VALUE,
        P_GENERATE_DATE,
        SUBSTR(A.CONTR_NUM,7)REF_NUM
      FROM
        (SELECT t.contr_num,
          t.contr_dt,
          t.client_cd,
          t.stk_Cd,
          t.amt_for_curr,
          tal.ledger_nar,
          m.old_ic_num
        FROM t_contracts t,
          t_account_ledger tal,
          mst_client m
        WHERE t.contr_dt BETWEEN P_BGN_DATE AND P_END_DATE
        AND t.client_cd BETWEEN P_BGN_CLIENT AND P_END_CLIENT
        AND t.contr_stat <> 'C'
        AND t.contr_num   = tal.xn_doc_num
        AND t.client_cd   = tal.sl_acct_cd
        AND t.client_cd   = m.client_cd
        UNION ALL
        SELECT d.gl_ref_num,
          d.contr_dt,
          d.client_cd,
          NULL,
          d.mf_amt,
          'Fee Broker',
          NULL
        FROM t_min_fee d
        WHERE d.contr_dt BETWEEN P_BGN_DATE AND P_END_DATE
        AND d.client_cd BETWEEN P_BGN_CLIENT AND P_END_CLIENT
        ) a,
        (SELECT p.doc_ref_num,
          p.sl_acct_cd,
          p.payrec_date,
          h.payrec_num,
          h.folder_Cd,
          h.gl_acct_cd
        FROM t_payrecd p,
          t_payrech h
        WHERE p.payrec_num = h.payrec_num
        AND SUBSTR(H.PAYREC_TYPE,1,1) LIKE P_VCH_TYPE
        AND p.approved_sts <> 'C'
        ) b,
        t_cheq q
      WHERE a.contr_num = b.doc_ref_num
      AND a.client_cd   = b.sl_acct_cd
      AND b.payrec_num  = q.rvpv_number(+);
    EXCEPTION
    WHEN OTHERS THEN
      V_ERROR_CD  := -50;
      V_ERROR_MSG := SUBSTR('INSERT R_LIST_OF_PAID_INVOICE'||V_ERROR_MSG||SQLERRM(SQLCODE),1,200);
      RAISE V_err;
    END;
    
  END IF;
  
  IF P_TYPE ='VOUCHER' THEN
  
    BEGIN
      SP_RPT_REMOVE_RAND('R_LIST_OF_PAID_INVOICE',V_RANDOM_VALUE,V_ERROR_MSG,V_ERROR_CD);
    EXCEPTION
    WHEN OTHERS THEN
      V_ERROR_CD  := -30;
      V_ERROR_MSG := SUBSTR('SP_RPT_REMOVE_RAND '||V_ERROR_MSG||SQLERRM(SQLCODE),1,200);
      RAISE V_err;
    END;
    
    IF V_ERROR_CD  <0 THEN
      V_ERROR_CD  := -40;
      V_ERROR_MSG := SUBSTR('SP_RPT_REMOVE_RAND'||V_ERROR_MSG,1,200);
      RAISE V_ERR;
    END IF;
    
    BEGIN
      INSERT
      INTO R_LIST_OF_PAID_VCH
        (
          PAYREC_NUM ,
          DOC_DATE ,
          SL_ACCT_CD ,
          CLIENT_CD ,
          PAYREC_AMT ,
          REMARKS ,
          DB_CR_FLG ,
          SOURCE_FOLDER_CD ,
          OLD_IC_NUM ,
          DOC_REF_NUM ,
          PAYREC_DATE ,
          B_PAYREC_NUM ,
          FOLDER_CD ,
          GL_ACCT_CD ,
          SETTLED_AMT ,
          CHQ_NUM ,
          BGN_DATE ,
          END_DATE ,
          VCH_TYPE ,
          USER_ID ,
          RAND_VALUE ,
          GENERATEDATE
        )
      SELECT a.payrec_num,
        a.doc_date,
        a.sl_acct_cd,
        a.client_cd,
        a.payrec_amt,
        a.remarks,
        a.db_cr_flg,
        a.source_folder_cd,
        a.old_ic_num,
        b.doc_ref_num,
        b.payrec_date,
        b.payrec_num b_payrec_num,
        b.folder_Cd,
        b.gl_acct_cd,
        b.payrec_amt settled_amt,
        q.chq_num,
        P_BGN_DATE,
        P_END_DATE,
        P_VCH_TYPE,
        P_USER_ID,
        V_RANDOM_VALUE,
        P_GENERATE_DATE
      FROM
        (SELECT t.payrec_num,
          t.payrec_Date doc_date,
          t.sl_acct_cd,
          t.client_cd,
          t.payrec_amt,
          t.remarks,
          t.db_cr_flg,
          NVL(th.folder_cd,t.ref_folder_cd) source_folder_cd,
          m.old_ic_num,
          t.tal_id
        FROM t_payrecd t,
          t_payrech th,
          mst_client m
        WHERE t.payrec_date BETWEEN P_BGN_DATE AND P_END_DATE
        AND t.sl_acct_cd BETWEEN P_BGN_CLIENT AND P_END_CLIENT
        AND NVL(th.folder_cd,t.ref_folder_cd) BETWEEN P_BGN_FOLDER_CD AND P_END_FOLDER_CD
        AND SUBSTR(th.PAYREC_TYPE,1,1) LIKE P_VCH_TYPE
        AND t.approved_sts           <> 'C'
        AND t.record_source           = 'ARAP'
        AND SUBSTR(t.payrec_num,8,3) <> 'MFE'
        AND t.payrec_num              = th.payrec_num (+)
        AND t.sl_acct_cd              = m.client_cd
        ) a,
        (SELECT p.doc_ref_num,
          p.sl_acct_cd,
          p.payrec_date,
          p.payrec_num,
          h.folder_Cd,
          h.gl_acct_cd,
          p.payrec_amt,
          p.doc_tal_id
        FROM t_payrecd p,
          t_payrech h
        WHERE p.payrec_num   = h.payrec_num (+)
        AND p.record_source <> 'ARAP'
        AND p.approved_sts  <> 'C'
        ) b,
        t_cheq q
      WHERE a.payrec_num = b.doc_ref_num
      AND a.sl_acct_cd   = b.sl_acct_cd
      AND a.tal_id       = b.doc_tal_id
      AND b.payrec_num   = q.rvpv_number (+);
    EXCEPTION
    WHEN OTHERS THEN
      V_ERROR_CD  := -60;
      V_ERROR_MSG := SUBSTR('INSERT R_LIST_OF_PAID_VCH'||V_ERROR_MSG||SQLERRM(SQLCODE),1,200);
      RAISE V_err;
    END;
    
  END IF;
  
  P_RANDOM_VALUE :=V_RANDOM_VALUE;
  P_ERROR_CD     := 1 ;
  P_ERROR_MSG    := '';
  
EXCEPTION
WHEN V_ERR THEN
  ROLLBACK;
  P_ERROR_MSG := V_ERROR_MSG;
  P_ERROR_CD  := V_ERROR_CD;
WHEN OTHERS THEN
  P_ERROR_CD  := -1 ;
  P_ERROR_MSG := SUBSTR(SQLERRM(SQLCODE),1,200);
  RAISE;
END SPR_LIST_OF_PAID_VCH;