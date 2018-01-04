create or replace 
PROCEDURE SPR_LIST_OF_PAY_RECV_SCHED(
    P_BGN_DATE   DATE,
    P_END_DATE   DATE,
    P_BGN_CLIENT VARCHAR2,
    P_END_CLIENT VARCHAR2,
    P_TYPE       VARCHAR2,
    P_BGN_BRANCH MST_BRANCH.BRCH_CD%TYPE,
    P_END_BRANCH MST_BRANCH.BRCH_CD%TYPE,
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
  dtmin1         DATE;
  dtmin2         DATE;
  dtmin3         DATE;
  dtmin4         DATE;
  dt7            DATE;
  dt90           DATE;
  dtmin90        DATE;
  dtmin7         DATE;
  dtplus1        DATE;
  dtplus2        DATE;
  dtplus3        DATE;
  
BEGIN

  V_RANDOM_VALUE := ABS(DBMS_RANDOM.RANDOM);
  
  IF P_TYPE       = 'TRX' THEN
  
    BEGIN
      SP_RPT_REMOVE_RAND('R_LIST_OF_PAY_RECV_SCHED_TRX',V_RANDOM_VALUE,V_ERROR_MSG,V_ERROR_CD);
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
    
    dtmin1 := get_doc_date(1,p_end_date);
    dtmin2 := get_doc_date(2,p_end_date);
    dtmin3 := get_doc_date(3,p_end_date);
    dtmin4 := get_doc_date(4,p_end_date);
    dtmin7 := get_doc_date(7,p_end_date);
    dt90   := P_END_DATE-90;
    
    BEGIN
      INSERT
      INTO R_LIST_OF_PAY_RECV_SCHED_TRX
        (
          CLIENT_CD ,
          CLIENT_NAME ,
          BRANCH_CODE ,
          OLD_CD ,
          REM_CD ,
          REM_NAME ,
          SUM_AMT ,
          AMT_MORE_90 ,
          AMT_MORE_7 ,
          AMT_MORE_3 ,
          AMT_MIN3 ,
          AMT_MIN2 ,
          AMT_MIN1 ,
          AMT0 ,
          RDI_BALANCE ,
          USER_ID ,
          RAND_VALUE ,
          GENERATEDATE,
          DT_MIN89
          ,DT_MIN8 
          ,DT_MIN7 
          ,DT_MIN4 
          ,DT_MIN3 
          ,DT_MIN2 
          ,DT_MIN1 
        )
      SELECT client_cd,
        client_name,
        branch_code,
        old_cd,
        rem_cd,
        rem_name,
        RDI_balance + sum_amt AS sum_amt,
        amt_more_90,
        amt_more_7,
        amt_more_3,
        amt_min3,
        amt_min2,
        amt_min1,
        amt0,
        RDI_balance,
        P_USER_ID,
        V_RANDOM_VALUE,
        P_GENERATE_DATE,
        P_END_DATE-89 DT_MIN89,
        GET_DOC_DATE(8,P_END_DATE) DT_MIN8,
        GET_DOC_DATE(7,P_END_DATE) DT_MIN7,
        GET_DOC_DATE(4,P_END_DATE) DT_MIN4,
        GET_DOC_DATE(3,P_END_DATE) DT_MIN3,
        GET_DOC_DATE(2,P_END_DATE) DT_MIN2,
        GET_DOC_DATE(1,P_END_DATE) DT_MIN1
      FROM
        (SELECT client_cd,
          client_name,
          branch_code,
          old_cd,
          rem_cd,
          rem_name,
          SUM(amt) sum_amt,
          SUM(DECODE(more_90,1,amt, 0)) amt_more_90,
          SUM(DECODE(more_7,1,amt, 0)) amt_more_7,
          SUM(DECODE(more_3,1,amt, 0)) amt_more_3,
          SUM(DECODE(dmin3,1,amt, 0)) amt_min3,
          SUM(DECODE(dmin2,1,amt, 0)) amt_min2,
          SUM(DECODE(dmin1,1,amt, 0)) amt_min1,
          SUM(DECODE(d0,1,amt, 0)) amt0,
          NVL(RDI_balance,0) * -1 rdi_balance
        FROM
          (SELECT client_cd,
            client_name,
            branch_code,
            old_cd,
            rem_cd,
            rem_name,
            doc_date,
            DECODE(SIGN(doc_date - dt90),-1,1,0,1,0) more_90,
            DECODE(SIGN(doc_date - dt90),-1,0,0,0,DECODE(SIGN(dt7 - doc_date),1,1,0)) more_7,
            DECODE(SIGN(doc_date - dt7),-1,0,DECODE(SIGN(dtmin4 - doc_date),-1,0,1)) more_3,
            DECODE(doc_date,P_END_DATE,1,0) d0,
            DECODE(doc_date,dtmin1,1,0) dmin1,
            DECODE(doc_date,dtmin2,1,0) dmin2,
            DECODE(doc_date,dtmin3,1,0) dmin3,
            os_amt AS amt,
            f_fund_bal(client_cd,P_END_DATE) RDI_balance
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
              x.descrip,
              m.client_name,
              m.branch_code,
              NVL(m.old_ic_num, '-') old_cd,
              m.rem_cd,
              m.rem_name
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
              ) p,
              (SELECT MST_CLIENT.client_cd,
                MST_CLIENT.client_name,
                MST_CLIENT.old_ic_num,
                MST_CLIENT.branch_code,
                trim(MST_CLIENT.rem_cd) AS rem_cd,
                MST_SALES.rem_name
              FROM MST_CLIENT,
                MST_SALES
              WHERE TRIM(MST_CLIENT.branch_code) BETWEEN P_BGN_BRANCH AND P_END_BRANCH
              AND trim(MST_CLIENT.rem_cd) = trim(MST_SALES.rem_cd)
              AND MST_CLIENT.SUSP_STAT <>'C'
              ) M
            WHERE x.doc_num                    = p.doc_ref_num (+)
            AND x.client_cd                    = p.sl_acct_cd (+)
            AND x.tal_id                       = p.tal_id (+)
            AND x.client_cd                    = m.client_cd
            AND x.orig_amt - NVL(p.pay_amt,0) <> 0
            )
          )
        GROUP BY client_cd,
          client_name,
          branch_code,
          old_cd,
          rem_cd,
          rem_name
        ) ;
    EXCEPTION
    WHEN OTHERS THEN
      V_ERROR_CD  := -50;
      V_ERROR_MSG := SUBSTR('INSERT R_LIST_OF_PAY_RECV_SCHED_TRX'||V_ERROR_MSG||SQLERRM(SQLCODE),1,200);
      RAISE V_err;
    END;
    
  END IF;
  
  IF P_TYPE = 'SETTLE' THEN
  
    BEGIN
      SP_RPT_REMOVE_RAND('R_LIST_OF_PAY_RECV_SCHED_SETT',V_RANDOM_VALUE,V_ERROR_MSG,V_ERROR_CD);
    EXCEPTION
    WHEN OTHERS THEN
      V_ERROR_CD  := -40;
      V_ERROR_MSG := SUBSTR('SP_RPT_REMOVE_RAND '||V_ERROR_MSG||SQLERRM(SQLCODE),1,200);
      RAISE V_err;
    END;
    
    IF V_ERROR_CD  <0 THEN
      V_ERROR_CD  := -50;
      V_ERROR_MSG := SUBSTR('SP_RPT_REMOVE_RAND'||V_ERROR_MSG,1,200);
      RAISE V_ERR;
    END IF;
    
    dtmin90 := P_END_DATE-90;
    dtmin7  := P_END_DATE-7;
    dtplus1 := GET_DUE_DATE(1,P_END_DATE);
    dtplus2 := GET_DUE_DATE(2,P_END_DATE);
    dtplus3 := GET_DUE_DATE(3,P_END_DATE);
    
    BEGIN
      INSERT
      INTO R_LIST_OF_PAY_RECV_SCHED_SETT
        (
          CLIENT_CD ,
          CLIENT_NAME ,
          BRANCH_CODE ,
          OLD_CD ,
          REM_CD ,
          REM_NAME ,
          SUM_AMT ,
          AMT_MORE_90 ,
          AMT_T7_90 ,
          AMT_T1_7 ,
          AMT_PLUS1 ,
          AMT_PLUS2 ,
          AMT_PLUS3 ,
          RDI_BALANCE ,
          USER_ID ,
          RAND_VALUE ,
          GENERATEDATE,
          DT_PLUS1,
          DT_PLUS2
        )
      SELECT client_cd,
        client_name,
        branch_code,
        old_cd,
        rem_cd,
        rem_name,
        sum_amt + RDI_BALANCE AS sum_amt,
        amt_more_90,
        amt_T7_90,
        amt_T1_7,
        amt_plus1,
        amt_plus2,
        amt_plus3,
        RDI_BALANCE ,
        P_USER_ID,
        V_RANDOM_VALUE,
        P_GENERATE_DATE,
        GET_DUE_DATE(1,P_END_DATE),
        GET_DUE_DATE(2,P_END_DATE)
      FROM
        (SELECT client_cd,
          client_name,
          branch_code,
          old_cd,
          rem_cd,
          rem_name,
          SUM(amt) sum_amt,
          SUM(DECODE(more_90,1,amt, 0)) amt_more_90,
          SUM(DECODE(T7_90,1,amt, 0)) amt_T7_90,
          SUM(DECODE(T1_7,1,amt, 0)) amt_T1_7,
          SUM(DECODE(dplus1,1,amt, 0)) amt_plus1,
          SUM(DECODE(dplus2,1,amt, 0)) amt_plus2,
          SUM(DECODE(dplus3,1,amt, 0)) amt_plus3,
          NVL(RDI_BALANCE,0) * -1 RDI_BALANCE
        FROM
          (SELECT client_cd,
            client_name,
            branch_code,
            old_cd,
            rem_cd,
            rem_name,
            doc_date,
            DECODE(SIGN(due_date - dtmin90),-1,1,0) more_90,
            DECODE(SIGN(due_date - dtmin90),-1,0,0,1,DECODE(SIGN(dtmin7 - due_date),1,1,0)) T7_90,
            DECODE(SIGN(due_date - dtmin7),-1,0,0,1,DECODE(SIGN(dtplus1 - due_date),1,1,0)) T1_7,
            DECODE(due_date,dtplus1,1,0) dplus1,
            DECODE(due_date,dtplus2,1,0) dplus2,
            DECODE(due_date,dtplus3,1,0) dplus3,
            os_amt                           AS amt,
            F_FUND_BAL(CLIENT_CD,P_END_DATE) AS RDI_BALANCE
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
              x.descrip,
              m.client_name,
              m.branch_code,
              NVL(m.old_ic_num, '-') old_cd,
              m.rem_cd,
              m.rem_name
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
              WHERE contr_dt    > '31jan10'
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
              ) p,
              (SELECT MST_CLIENT.client_cd,
                MST_CLIENT.client_name,
                MST_CLIENT.old_ic_num,
                MST_CLIENT.branch_code,
                trim(MST_CLIENT.rem_cd) AS rem_cd,
                MST_SALES.rem_name
              FROM MST_CLIENT,
                MST_SALES
              WHERE TRIM(MST_CLIENT.branch_code) BETWEEN P_BGN_BRANCH AND P_END_BRANCH
              AND trim(MST_CLIENT.rem_cd) = trim(MST_SALES.rem_cd)
             AND MST_CLIENT.SUSP_STAT <>'C'
              ) M
            WHERE x.doc_num                    = p.doc_ref_num (+)
            AND x.client_cd                    = p.sl_acct_cd (+)
            AND x.tal_id                       = p.tal_id (+)
            AND x.client_cd                    = m.client_cd
            AND x.orig_amt - NVL(p.pay_amt,0) <> 0
            )
          )
        GROUP BY client_cd,
          client_name,
          branch_code,
          old_cd,
          rem_cd,
          rem_name
        );
    EXCEPTION
    WHEN OTHERS THEN
      V_ERROR_CD  := -60;
      V_ERROR_MSG := SUBSTR('INSERT R_LIST_OF_PAY_RECV_SCHED_SETT'||V_ERROR_MSG||SQLERRM(SQLCODE),1,200);
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
END SPR_LIST_OF_PAY_RECV_SCHED;