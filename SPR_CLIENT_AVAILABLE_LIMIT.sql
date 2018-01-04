create or replace 
PROCEDURE SPR_CLIENT_AVAILABLE_LIMIT(
    P_END_DATE      DATE,
    P_BGN_CLIENT    VARCHAR2,
    P_END_CLIENT    VARCHAR2,
    P_BGN_REM       VARCHAR2,
    P_END_REM       VARCHAR2,
    P_BGN_BRANCH    MST_BRANCH.BRCH_CD%TYPE,
    P_END_BRANCH    MST_BRANCH.BRCH_CD%TYPE,
    P_AVAIL         VARCHAR2,
    P_HAIRCUT       NUMBER,
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
  DT_BAL_DATE    DATE;
  DT_PRICE_DATE  DATE;
  
BEGIN

  V_RANDOM_VALUE := ABS(DBMS_RANDOM.RANDOM);
  
  BEGIN
    SP_RPT_REMOVE_RAND('R_CLIENT_AVAILABLE_LIMIT',V_RANDOM_VALUE,V_ERROR_MSG,V_ERROR_CD);
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
    SELECT MAX(stk_date)
    INTO DT_PRICE_DATE
    FROM T_CLOSE_PRICE
    WHERE STK_DATE<=GET_DOC_DATE(1,P_END_DATE);
  EXCEPTION
  WHEN OTHERS THEN
    V_ERROR_CD  := -50;
    V_ERROR_MSG := SUBSTR('SELECT LAST PRICE DATE FROM T_CLOSE_PRICE'||SQLERRM,1,200);
    RAISE V_err;
  END;
  
  DT_BAL_DATE := TO_DATE('01'||TO_CHAR(P_END_DATE,'MMYYYY'),'DDMMYYYY');
  
  BEGIN
    INSERT
    INTO R_CLIENT_AVAILABLE_LIMIT
      (
        CLIENT_CD ,
        CLIENT_NAME ,
        OLD_IC_NUM ,
        REM_CD ,
        REM_NAME ,
        MORE_3 ,
        OUTSAR ,
        OUTSAP ,
        OUTSAMT ,
        SHORT_AMT ,
        PORTO_AMT ,
        CR_LIM ,
        AVAIL_LIM ,
        DOC_DATE ,
        USER_ID ,
        RAND_VALUE ,
        GENERATEDATE
      )
    SELECT client_cd,
      client_name,
      old_ic_num,
      rem_cd,
      rem_name,
      more_3,
      outsAR,
      outsAP,
      outsamt,
      short_amt,
      porto_amt,
      cr_lim,
      avail_lim,
      P_END_DATE,
      P_USER_ID,
      V_RANDOM_VALUE,
      P_GENERATE_DATE
    FROM
      (SELECT m.client_cd,
        INITCAP(m.client_name) client_name,
        m.old_ic_num,
        m.rem_cd,
        m.rem_name,
        NVL(outs.more_3, 0) more_3,
        NVL(outs.outsAR,0) outsAr,
        NVL(outs.outsAP,0) outsap,
        NVL(outs.outsamt,0) outsamt,
        NVL(porto.short_amt,0) AS short_amt,
        NVL(porto.porto_amt,0) porto_amt,
        NVL(m.cr_lim,0) cr_lim,
        (( NVL(porto.porto_amt,0) / 2) - NVL(outs.outsamt,0) ) * 2 AS avail_lim
      FROM
        (SELECT client_cd,
          SUM(more_3) more_3,
          SUM(outsAR)  AS outsAR,
          SUM(outsAP)  AS outsAP,
          SUM(outsamt) AS outsamt
        FROM
          (SELECT client_cd,
            doc_date,
            due_date,
            DECODE(SIGN(due_date - P_END_DATE),-1,1,0,1) * os_amt                                    AS more_3,
            DECODE(SIGN(due_date - P_END_DATE),-1,0,0,0,1) * DECODE(SIGN(os_amt), 1,os_amt, 0)       AS outsar,
            DECODE(SIGN(due_date - P_END_DATE),-1,0,0,0,1) * DECODE(SIGN(os_amt), -1,ABS(os_amt), 0) AS outsap,
            os_amt                                                                                   AS outsamt
          FROM
            (SELECT x.client_Cd,
              x.doc_num,
              x.doc_folder,
              x.doc_date,
              x.due_date,
              x.orig_amt,
              x.orig_amt - NVL(p.pay_amt,0) AS os_amt,
              x.gl_acct_cd,
              x.xn_doc_num,
              x.descrip
            FROM
              (SELECT c.client_cd,
                c.contr_num                                                                                  AS doc_num,
                SUBSTR(c.contr_num,5,11)                                                                     AS doc_folder,
                c.contr_dt                                                                                   AS doc_date,
                c.due_dt_for_amt                                                                             AS due_date,
                DECODE(t.db_cr_flg,'D',1,-1) * c.amt_for_curr                                                AS orig_amt,
                DECODE(t.db_cr_flg,'D',1,-1) * (c.amt_for_curr - NVL(c.sett_val,0) - NVL(c.sett_for_curr,0)) AS os_amt,
                t.gl_acct_cd,
                t.xn_doc_num,
                1 tal_id,
                t.ledger_nar AS descrip
              FROM T_CONTRACTS c,
                T_ACCOUNT_LEDGER t
              WHERE contr_dt    > '31jan2010'
              AND c.contr_stat <> 'C'
              AND c.client_cd BETWEEN P_BGN_CLIENT AND P_END_CLIENT
              AND c.contr_dt     <= P_END_DATE
              AND t.sl_acct_cd    = c.client_cd
              AND c.contr_num     = t.doc_ref_num
              AND (t.rvpv_number IS NULL
              OR t.rvpv_number LIKE '%V%')
              UNION
              SELECT p.sl_acct_cd,
                p.payrec_num,
                p.ref_folder_cd,
                p.payrec_date,
                p.due_date,
                DECODE(p.db_cr_flg,'D',1,-1) * p.payrec_amt                                                AS orig_amt,
                DECODE(p.db_cr_flg,'D',1,-1) * (p.payrec_amt - NVL(p.sett_val,0) - NVL(p.sett_for_curr,0)) AS pay_amt,
                t.gl_acct_cd,
                t.xn_doc_num,
                DECODE(t.record_source,'CDUE',t.netting_flg,'MDUE',t.netting_flg,t.tal_id) AS tal_id,
                t.ledger_nar
              FROM T_PAYRECD p,
                T_ACCOUNT_LEDGER t
              WHERE p.record_source = 'ARAP'
              AND p.approved_sts   <> 'C'
              AND p.approved_sts   <> 'E'
              AND p.payrec_date    <= P_END_DATE
              AND p.sl_acct_cd BETWEEN P_BGN_CLIENT AND P_END_CLIENT
              AND p.payrec_num    = t.doc_ref_num
              AND p.sl_acct_cd    = t.sl_acct_cd
              AND p.tal_id        = t.netting_flg
              AND (t.rvpv_number IS NULL
              OR t.rvpv_number LIKE '%V%'
              OR t.rvpv_number LIKE '%DE%')
              ) X,
              (SELECT tal_id,
                doc_ref_num,
                sl_acct_cd,
                SUM(pay_amt) pay_amt
              FROM
                (SELECT d.tal_id,
                  d.doc_ref_num,
                  d.sl_acct_cd,
                  d.payrec_num,
                  DECODE(d.db_Cr_flg,'D',-1,1) * d.payrec_amt AS pay_amt
                FROM T_PAYRECD d,
                  T_PAYRECH h
                WHERE d.payrec_num  = h.payrec_num
                AND d.approved_sts <> 'C'
                AND d.approved_sts <> 'E'
                AND d.payrec_date  <= P_END_DATE
                AND d.sl_Acct_cd BETWEEN P_BGN_CLIENT AND P_END_CLIENT
                AND d.record_source <> 'ARAP'
                )
              GROUP BY tal_id,
                doc_ref_num,
                sl_acct_cd
              ) p
            WHERE x.doc_num                    = p.doc_ref_num (+)
            AND x.client_cd                    = p.sl_acct_cd (+)
            AND x.tal_id                       = p.tal_id (+)
            AND x.orig_amt - NVL(p.pay_amt,0) <> 0
            )
          )
        GROUP BY client_cd
        ) outs,
        (SELECT b.client_cd,
          SUM(bal_qty * NVL(p.stk_clos,0) * (100 - p.mrg_stk_cap) / 100) porto_amt,
          SUM(short   * bal_qty * NVL(p.stk_clos,0)) AS short_amt
        FROM
          (SELECT client_cd,
            stk_cd,
            SUM(beg_bal_qty             + theo_mvmt) bal_qty,
            DECODE(SIGN(SUM(beg_bal_qty + theo_mvmt)),-1,1,0) short
          FROM
            (SELECT client_cd,
              stk_cd,
              0 beg_bal_qty,
              (NVL(DECODE(SUBSTR(doc_num,5,2),'BR',1,'JR',1,'BI',1,'JI',1,'RS',1,'WS',1,0) * DECODE(db_cr_flg,'D',1,-1) * (total_share_qty + withdrawn_share_qty),0)) theo_mvmt
            FROM T_STK_MOVEMENT
            WHERE doc_dt BETWEEN dt_bal_date AND P_END_DATE
            AND client_cd BETWEEN P_BGN_CLIENT AND P_END_CLIENT
            AND gl_acct_cd IN ('10','12','13','14','51')
            AND doc_stat    = '2'
            AND s_d_type   <> 'V'
            UNION ALL
            SELECT client_cd,
              stk_cd,
              beg_bal_qty,
              0 theo_mvmt
            FROM T_STKBAL
            WHERE bal_dt = dt_bal_date
            AND client_cd BETWEEN P_BGN_CLIENT AND P_END_CLIENT
            )
          GROUP BY client_cd,
            stk_cd
          HAVING SUM(beg_bal_qty + theo_mvmt) <> 0
          ) b,
          (SELECT v_stk_clos.stk_cd,
            NVL(DECODE(v_stk_clos.stk_clos, 0, v_stk_clos.stk_prev, v_stk_clos.stk_clos), 0) stk_clos,
            NVL(MST_COUNTER.mrg_stk_cap,0) * P_HAIRCUT mrg_stk_cap
          FROM v_stk_clos,
            MST_COUNTER
          WHERE v_stk_clos.stk_date = DT_PRICE_DATE
          AND v_stk_clos.stk_cd     = MST_COUNTER.stk_cd
          ) p
        WHERE b.stk_cd = p.stk_cd (+)
        GROUP BY b.client_cd
        ) porto,
        (SELECT m.client_cd,
          m.old_ic_num,
          m.rem_cd,
          m.client_name,
          s.rem_name,
          m.cr_lim
        FROM MST_CLIENT m,
          MST_SALES s
        WHERE trim(m.rem_cd) BETWEEN P_BGN_REM AND P_END_REM
        AND TRIM(m.branch_code) BETWEEN P_BGN_BRANCH AND P_END_BRANCH
        AND m.client_cd BETWEEN P_BGN_CLIENT AND P_END_CLIENT
        AND trim(m.rem_cd)   = trim(s.rem_cd(+))
        AND m.susp_stat     <> 'C'
        AND m.client_type_1 <> 'H'
        ) m
      WHERE m.client_cd = porto.client_cd (+)
      AND m.client_cd   = outs.client_cd (+)
      )
    WHERE (avail_lim > 0
    AND P_AVAIL      = '>0'
    OR avail_lim     < 0
    AND P_AVAIL      = '<0'
    OR P_AVAIL       = '<>0')
    AND (outsAmt    <> 0
    OR porto_amt    <> 0);
  EXCEPTION
  WHEN OTHERS THEN
    V_ERROR_CD  := -60;
    V_ERROR_MSG := SUBSTR('INSERT R_CLIENT_AVAILABLE_LIMIT'||V_ERROR_MSG||SQLERRM(SQLCODE),1,200);
    RAISE V_err;
  END;
  
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
END SPR_CLIENT_AVAILABLE_LIMIT;