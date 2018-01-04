create or replace PROCEDURE SPR_TRIAL_BALANCE(
    P_BGN_DATE      DATE,
    P_END_DATE      DATE,
    P_BGN_ACCT      VARCHAR2,
    P_END_ACCT      VARCHAR2,
    P_BGN_SUB       VARCHAR2,
    P_END_SUB       VARCHAR2,
    P_BRANCH        VARCHAR2,
    P_MODE          VARCHAR2,
    P_USER_ID       VARCHAR2,
    P_GENERATE_DATE DATE,
    P_RANDOM_VALUE OUT NUMBER,
    P_ERROR_CD OUT NUMBER,
    P_ERROR_MSG OUT VARCHAR2 )
AS
  V_ERR           EXCEPTION;
  V_ERROR_CD      NUMBER(5);
  V_ERROR_MSG     VARCHAR2(200);
  V_RANDOM_VALUE  NUMBER(10);
  V_BGN_BAL       DATE;
  v_bgn_date_min1 DATE;
  V_BROKER_CD     VARCHAR2(2);
BEGIN
  V_RANDOM_VALUE := ABS(DBMS_RANDOM.RANDOM);
  BEGIN
    SP_RPT_REMOVE_RAND('R_TRIAL_BALANCE',V_RANDOM_VALUE,V_ERROR_MSG,V_ERROR_CD);
  EXCEPTION
  WHEN OTHERS THEN
    V_ERROR_CD  := -10;
    V_ERROR_MSG := SUBSTR('SP_RPT_REMOVE_RAND '||V_ERROR_MSG||SQLERRM(SQLCODE),1,200);
    RAISE V_err;
  END;
  
  IF V_ERROR_CD  <0 THEN
    V_ERROR_CD  := -20;
    V_ERROR_MSG := SUBSTR('SP_RPT_REMOVE_RAND'||V_ERROR_MSG,1,200);
    RAISE V_ERR;
  END IF;
  
  V_BGN_BAL       := P_BGN_DATE - TO_CHAR(P_BGN_DATE,'DD')+1;
  
  v_bgn_date_min1 := P_BGN_DATE -1;
  
  BEGIN
    SELECT SUBSTR(BROKER_CD,1,2) INTO V_BROKER_CD FROM V_BROKER_SUBREK;
  EXCEPTION
  WHEN OTHERS THEN
    V_ERROR_CD  := -30;
    V_ERROR_MSG := SUBSTR('SELECT BROKER CODE '||SQLERRM(SQLCODE),1,200);
    RAISE V_err;
  END;
  
  IF P_MODE ='DETAIL'  THEN
  
    BEGIN
      INSERT
      INTO R_TRIAL_BALANCE
        (
          BGN_DATE ,
          END_DATE ,
          GL_ACCT ,
          SL_ACCT ,
          MAIN_ACCT_NAME ,
          ACCT_NAME ,
          BEG_BAL ,
          DEBIT ,
          CREDIT ,
          END_BAL ,
          RPT_MODE ,
          USER_ID ,
          RAND_VALUE ,
          GENERATE_DATE,
          BROKER_CD
        )
      SELECT P_BGN_DATE,
        P_END_DATE,
        trim(M.GL_A) gl_acct,
        M.SL_A sl_acct,
        c.main_acct_name,
        m.acct_name,
        SUM(NVL(a.beg_bal,0)) beg_bal,
        SUM(NVL(A.debit,0)) debit,
        SUM(NVL(A.credit,0)) credit,
        SUM(NVL(a.beg_bal,0) + NVL(A.debit,0) - NVL(A.credit,0)) end_bal ,
        P_MODE,
        P_USER_ID,
        V_RANDOM_VALUE,
        P_GENERATE_DATE,
        V_BROKER_CD
      FROM
        (SELECT a.GL_ACCT_CD,
          a.sl_acct_cd,
          0 beg_bal,
          (DECODE(a.db_cr_flg,'D',NVL(a.curr_val,0),0)) debit,
          (DECODE(a.db_cr_flg,'D',0,NVL(a.curr_val,0))) credit
        FROM t_account_ledger a
        WHERE a.doc_date BETWEEN P_BGN_DATE AND P_END_DATE
        AND trim(a.gl_acct_cd) BETWEEN P_BGN_ACCT AND P_END_ACCT
        AND a.approved_sts <> 'C'
        AND a.approved_sts <> 'E'
        AND a.sl_acct_cd BETWEEN P_BGN_SUB AND P_END_SUB
        UNION ALL
        SELECT b.GL_ACCT_CD,
          b.sl_acct_cd,
          NVL(b.deb_obal,0) - NVL(b.cre_obal,0) beg_bal,
          0,0
        FROM t_day_trs b
        WHERE b.trs_dt = V_BGN_BAL
        AND trim(b.gl_acct_cd) BETWEEN P_BGN_ACCT AND P_END_ACCT
        AND b.sl_acct_cd BETWEEN P_BGN_SUB AND P_END_SUB
        UNION ALL
        SELECT d.GL_ACCT_CD,
          d.sl_acct_cd,
          (DECODE(d.db_cr_flg,'D',1,-1) * NVL(d.curr_val,0)) mvmt,
          0,
          0
        FROM t_account_ledger d
        WHERE d.doc_date BETWEEN V_BGN_BAL AND (P_BGN_DATE - 1)
        AND trim(d.gl_acct_cd) BETWEEN P_BGN_ACCT AND P_END_ACCT
        AND d.approved_sts = 'A'
        AND d.sl_acct_cd BETWEEN P_BGN_SUB AND P_END_SUB
        ) A,
        (SELECT gl_a,
          acct_name main_acct_name
        FROM mst_gl_account
        WHERE sl_a = '000000'
        ) C,
        (SELECT gl_a,
          sl_a,
          acct_name
        FROM mst_gl_account
        WHERE PRT_TYPE <> 'S'
        AND NVL(acct_type,'123456') <> 'LRTHIS'--30AUG2016
        AND trim(gl_a) BETWEEN P_BGN_ACCT AND P_END_ACCT
        AND sl_a BETWEEN P_BGN_SUB AND P_END_SUB
         AND (TRIM(BRCH_CD) LIKE P_BRANCH OR BRCH_CD IS NULL)--30aug2016
        ) M
      WHERE M.gl_a = A.gl_acct_cd
      AND M.sl_a   = A.sl_acct_cd
      AND M.gl_a   = C.gl_a
      GROUP BY M.GL_A,
        M.sl_a,
        m.acct_name,
        c.main_acct_name
      HAVING (SUM(NVL(A.debit,0)) <> 0
      OR SUM(NVL(A.credit,0))     <> 0
      OR SUM(NVL(A.beg_bal,0))    <> 0)
      ORDER BY 3,4 ;
    EXCEPTION
    WHEN OTHERS THEN
      V_ERROR_CD  :=-40;
      V_ERROR_MSG := SUBSTR('INSERT INTO R_TRIAL_BALANCE '||SQLERRM(SQLCODE),1,200);
      RAISE V_ERR;
    END;
    
  END IF;
  
  IF P_MODE ='SUMMARY' THEN
  
    BEGIN
      INSERT
      INTO R_TRIAL_BALANCE
        (
          BGN_DATE ,
          END_DATE ,
          GL_ACCT ,
          SL_ACCT ,
          MAIN_ACCT_NAME ,
          ACCT_NAME ,
          BEG_BAL ,
          DEBIT ,
          CREDIT ,
          END_BAL ,
          RPT_MODE ,
          USER_ID ,
          RAND_VALUE ,
          GENERATE_DATE,
          BROKER_CD
        )
      SELECT P_BGN_DATE,
        P_END_DATE,
        TRIM(M.GL_A) GL_ACCT,
        NULL SL_ACCT,
        c.main_acct_name,
        NULL ACCT_NAME,
        SUM(NVL(a.beg_bal,0)) beg_bal,
        SUM(NVL(A.debit,0)) debit,
        SUM(NVL(A.credit,0)) credit,
        SUM(NVL(a.beg_bal,0) + NVL(A.debit,0) - NVL(A.credit,0)) end_bal ,
        P_MODE,
        P_USER_ID,
        V_RANDOM_VALUE,
        P_GENERATE_DATE,
        V_BROKER_CD
      FROM
        (SELECT a.GL_ACCT_CD,
          a.sl_acct_cd,
          0 beg_bal,
          (DECODE(a.db_cr_flg,'D',NVL(a.curr_val,0),0)) debit,
          (DECODE(a.db_cr_flg,'D',0,NVL(a.curr_val,0))) credit
        FROM t_account_ledger a
        WHERE a.doc_date BETWEEN P_BGN_DATE AND P_END_DATE
        AND trim(a.gl_acct_cd) BETWEEN P_BGN_ACCT AND P_END_ACCT
        AND a.approved_sts <> 'C'
        AND a.approved_sts <> 'E'
        UNION ALL
        SELECT b.GL_ACCT_CD,
          b.sl_acct_cd,
          NVL(b.deb_obal,0) - NVL(b.cre_obal,0) beg_bal,
          0,0
        FROM t_day_trs b
        WHERE b.trs_dt = V_BGN_BAL
        AND trim(b.gl_acct_cd) BETWEEN P_BGN_ACCT AND P_END_ACCT
        UNION ALL
        SELECT d.GL_ACCT_CD,
          d.sl_acct_cd,
          (DECODE(d.db_cr_flg,'D',1,-1) * NVL(d.curr_val,0)) mvmt,
          0,
          0
        FROM t_account_ledger d
        WHERE d.doc_date BETWEEN V_BGN_BAL AND v_bgn_date_min1
        AND trim(d.gl_acct_cd) BETWEEN P_BGN_ACCT AND P_END_ACCT
        AND d.approved_sts = 'A'
        ) A,
        (SELECT gl_a,
          acct_name main_acct_name
        FROM mst_gl_account
        WHERE sl_a = '000000'
        ) C,
        (SELECT gl_a,
          sl_a,
          acct_name
        FROM mst_gl_account
        WHERE PRT_TYPE <> 'S'
        AND NVL(acct_type,'123456') <> 'LRTHIS'--30AUG2016
        AND trim(gl_a) BETWEEN P_BGN_ACCT AND P_END_ACCT
        AND (TRIM(BRCH_CD) LIKE P_BRANCH OR BRCH_CD IS NULL)--30aug2016
        ) M
      WHERE M.gl_a = A.gl_acct_cd
      AND M.sl_a   = A.sl_acct_cd
      AND M.gl_a   = C.gl_a
      GROUP BY M.GL_A,
        c.main_acct_name
      HAVING (SUM(NVL(A.debit,0)) <> 0
      OR SUM(NVL(A.credit,0))     <> 0
      OR SUM(NVL(A.beg_bal,0))    <> 0)
      ORDER BY 3;
    EXCEPTION
    WHEN OTHERS THEN
      V_ERROR_CD  :=-50;
      V_ERROR_MSG := SUBSTR('INSERT INTO R_TRIAL_BALANCE, SUMMARY  '||SQLERRM(SQLCODE),1,200);
      RAISE V_ERR;
    END;
    
  END IF;
  /*
  IF P_MODE ='DETAIL' AND V_BROKER_CD ='PF' THEN
    BEGIN
      INSERT
      INTO R_TRIAL_BALANCE
        (
          BGN_DATE ,
          END_DATE ,
          GL_ACCT ,
          SL_ACCT ,
          MAIN_ACCT_NAME ,
          ACCT_NAME ,
          BEG_BAL ,
          DEBIT ,
          CREDIT ,
          END_BAL ,
          RPT_MODE ,
          BROKER_CD ,
          BRANCH_CODE ,
          USER_ID ,
          RAND_VALUE ,
          GENERATE_DATE
        )
 
      SELECT P_BGN_DATE,
        P_END_DATE,
        trim(M1.GL_A) gl_acct,
        M1.SL_A sl_acct,
        --trim(M1.GL_A) +'000000' AS gl_acct2,
        c1.acct_name2 AS MAIN_ACCT_NAME,
        m1.acct_name  AS ACCT_NAME ,
        SUM(NVL(B1.deb_obal,0)) +SUM(NVL(D1.deb_todt,0)) - SUM(NVL(B1.cre_obal,0)) - SUM(NVL(D1.cre_todt,0)) beg_bal,
        SUM(NVL(A1.debit,0)) debit,
        SUM(NVL(A1.credit,0)) credit,
        SUM(NVL(B1.deb_obal,0)) +SUM(NVL(D1.deb_todt,0)) - SUM(NVL(B1.cre_obal,0)) -SUM(NVL(D1.cre_todt,0)) + SUM(NVL(A1.debit,0)) - SUM(NVL(A1.credit,0)) end_bal,
        P_MODE,
        V_BROKER_CD,
        M1.BRCH_CD ,
        P_USER_ID,
        V_RANDOM_VALUE,
        P_GENERATE_DATE
      FROM
        (SELECT a.GL_ACCT_CD,
          a.sl_acct_cd,
          SUM(DECODE(a.db_cr_flg,'D',NVL(a.curr_val,0),0)) debit,
          SUM(DECODE(a.db_cr_flg,'D',0,NVL(a.curr_val,0))) credit
        FROM T_ACCOUNT_LEDGER a
        WHERE a.doc_date BETWEEN P_BGN_DATE AND P_END_DATE
        AND trim(a.gl_acct_cd) BETWEEN P_BGN_ACCT AND P_END_ACCT
        AND a.sl_acct_cd BETWEEN P_BGN_SUB AND P_END_SUB
        AND a.approved_sts <> 'C'
        AND a.approved_sts <> 'E'
        GROUP BY a.gl_acct_cd,
          a.sl_acct_cd
        ) A1,
        (SELECT b.GL_ACCT_CD,
          b.sl_acct_cd,
          NVL(b.deb_obal,0) deb_obal,
          NVL(b.cre_obal,0) cre_obal
        FROM T_DAY_TRS b
        WHERE b.trs_dt = V_BGN_BAL
        AND trim(b.gl_acct_cd) BETWEEN P_BGN_ACCT AND P_END_ACCT
        AND b.sl_acct_cd BETWEEN P_BGN_SUB AND P_END_SUB
        ) B1,
        (SELECT c.gl_a,
          c.acct_name acct_name2
        FROM MST_GL_ACCOUNT c
        WHERE c.sl_a = '000000'
        AND trim(c.gl_a) BETWEEN P_BGN_ACCT AND P_END_ACCT
        AND c.brch_cd like P_BRANCH
        ) C1,
        (SELECT d.GL_ACCT_CD,
          d.sl_acct_cd,
          SUM(DECODE(d.db_cr_flg,'D',NVL(d.curr_val,0),0)) deb_todt,
          SUM(DECODE(d.db_cr_flg,'C',NVL(d.curr_val,0),0)) cre_todt
        FROM T_ACCOUNT_LEDGER D
        WHERE d.doc_date BETWEEN V_BGN_BAL AND v_bgn_date_min1
        AND trim(d.gl_acct_cd) BETWEEN P_BGN_ACCT AND P_END_ACCT
        AND (d.sl_acct_cd) BETWEEN P_BGN_SUB AND P_END_SUB
        AND d.approved_sts <> 'C'
        AND d.approved_sts <> 'E'
        GROUP BY d.gl_acct_cd,
          d.sl_acct_cd
        ) D1,
        (SELECT *
        FROM MST_GL_ACCOUNT
        WHERE prt_type              <> 'S'
        AND NVL(acct_type,'123456') <> 'LRTHIS'
        AND trim(brch_cd) LIKE P_BRANCH
        AND trim(gl_a) BETWEEN P_BGN_ACCT AND P_END_ACCT
        AND (sl_a) BETWEEN P_BGN_SUB AND P_END_SUB
        ) M1
      WHERE M1.gl_a = A1.gl_acct_cd (+)
      AND M1.sl_a   = A1.sl_acct_cd (+)
      AND M1.gl_a   = B1.gl_acct_cd (+)
      AND M1.sl_a   = B1.sl_acct_cd (+)
      AND M1.gl_a   = D1.gl_acct_cd (+)
      AND M1.sl_a   = D1.sl_acct_cd (+)
      AND M1.gl_a   = C1.gl_a
      GROUP BY M1.GL_A,
        M1.sl_a,
        m1.acct_name,
        c1.acct_name2 ,
        M1.BRCH_CD
      HAVING (SUM(NVL(A1.debit,0))                                                                                <> 0
      OR SUM(NVL(A1.credit,0))                                                                                    <> 0
      OR ( SUM(NVL(B1.deb_obal,0)) - SUM(NVL(B1.cre_obal,0)) + SUM(NVL(D1.deb_todt,0)) - SUM(NVL(D1.cre_todt,0))) <> 0) ;
    EXCEPTION
    WHEN OTHERS THEN
      V_ERROR_CD  :=-60;
      V_ERROR_MSG := SUBSTR('INSERT INTO R_TRIAL_BALANCE, DETAIL PF'||SQLERRM(SQLCODE),1,200);
      RAISE V_ERR;
    END;
    
  END IF;
*/
/*
   IF P_MODE ='SUMMARY' AND V_BROKER_CD='PF' THEN
    BEGIN
      INSERT
      INTO R_TRIAL_BALANCE
        (
          BGN_DATE ,
          END_DATE ,
          GL_ACCT ,
          SL_ACCT ,
          MAIN_ACCT_NAME ,
          ACCT_NAME ,
          BEG_BAL ,
          DEBIT ,
          CREDIT ,
          END_BAL ,
          RPT_MODE ,
          USER_ID ,
          RAND_VALUE ,
          GENERATE_DATE,
          BROKER_CD
        )
      SELECT P_BGN_DATE,
        P_END_DATE,
        trim(M1.GL_A) gl_acct,
     NULL SL_ACCT, --  M1.SL_A sl_acct,
        --trim(M1.GL_A) +'000000' AS gl_acct2,
        INITCAP(c1.acct_name2) AS MAIN_ACCT_NAME,
    NULL ACCT_NAME, --   m1.acct_name  AS ACCT_NAME ,
        SUM(NVL(B1.deb_obal,0)) +SUM(NVL(D1.deb_todt,0)) - SUM(NVL(B1.cre_obal,0)) - SUM(NVL(D1.cre_todt,0)) beg_bal,
        SUM(NVL(A1.debit,0)) debit,
        SUM(NVL(A1.credit,0)) credit,
        SUM(NVL(B1.deb_obal,0)) +SUM(NVL(D1.deb_todt,0)) - SUM(NVL(B1.cre_obal,0)) -SUM(NVL(D1.cre_todt,0)) + SUM(NVL(A1.debit,0)) - SUM(NVL(A1.credit,0)) end_bal,
        P_MODE,
        --M1.BRCH_CD, 
        P_USER_ID,
        V_RANDOM_VALUE,
        P_GENERATE_DATE,
        V_BROKER_CD
      FROM
        (SELECT a.GL_ACCT_CD,
          a.sl_acct_cd,
          SUM(DECODE(a.db_cr_flg,'D',NVL(a.curr_val,0),0)) debit,
          SUM(DECODE(a.db_cr_flg,'D',0,NVL(a.curr_val,0))) credit
        FROM T_ACCOUNT_LEDGER a
        WHERE a.doc_date BETWEEN P_BGN_DATE AND P_END_DATE
        AND trim(a.gl_acct_cd) BETWEEN P_BGN_ACCT AND P_END_ACCT
     --   AND a.sl_acct_cd BETWEEN P_BGN_SUB AND P_END_SUB
        AND a.approved_sts <> 'C'
        AND a.approved_sts <> 'E'
        GROUP BY a.gl_acct_cd,
          a.sl_acct_cd
        ) A1,
        (SELECT b.GL_ACCT_CD,
          b.sl_acct_cd,
          NVL(b.deb_obal,0) deb_obal,
          NVL(b.cre_obal,0) cre_obal
        FROM T_DAY_TRS b
        WHERE b.trs_dt = V_BGN_BAL
        AND trim(b.gl_acct_cd) BETWEEN P_BGN_ACCT AND P_END_ACCT
       -- AND b.sl_acct_cd BETWEEN P_BGN_SUB AND P_END_SUB
        ) B1,
        (SELECT c.gl_a,
          c.acct_name acct_name2
        FROM MST_GL_ACCOUNT c
        WHERE c.sl_a = '000000'
        AND trim(c.gl_a) BETWEEN P_BGN_ACCT AND P_END_ACCT
        AND c.brch_cd like P_BRANCH
        ) C1,
        (SELECT d.GL_ACCT_CD,
          d.sl_acct_cd,
          SUM(DECODE(d.db_cr_flg,'D',NVL(d.curr_val,0),0)) deb_todt,
          SUM(DECODE(d.db_cr_flg,'C',NVL(d.curr_val,0),0)) cre_todt
        FROM T_ACCOUNT_LEDGER D
        WHERE d.doc_date BETWEEN V_BGN_BAL AND v_bgn_date_min1
        AND trim(d.gl_acct_cd) BETWEEN P_BGN_ACCT AND P_END_ACCT
       -- AND (d.sl_acct_cd) BETWEEN P_BGN_SUB AND P_END_SUB
        AND d.approved_sts <> 'C'
        AND d.approved_sts <> 'E'
        GROUP BY d.gl_acct_cd,
          d.sl_acct_cd
        ) D1,
        (SELECT *
        FROM MST_GL_ACCOUNT
        WHERE prt_type              <> 'S'
        AND NVL(acct_type,'123456') <> 'LRTHIS'
        AND trim(brch_cd) LIKE P_BRANCH
        AND trim(gl_a) BETWEEN P_BGN_ACCT AND P_END_ACCT
   --     AND (sl_a) BETWEEN P_BGN_SUB AND P_END_SUB
        ) M1
      WHERE M1.gl_a = A1.gl_acct_cd (+)
      AND M1.sl_a   = A1.sl_acct_cd (+)
      AND M1.gl_a   = B1.gl_acct_cd (+)
      AND M1.sl_a   = B1.sl_acct_cd (+)
      AND M1.gl_a   = D1.gl_acct_cd (+)
      AND M1.sl_a   = D1.sl_acct_cd (+)
      AND M1.gl_a   = C1.gl_a
      GROUP BY M1.GL_A,
        --M1.sl_a,
        --m1.acct_name,
        c1.acct_name2-- ,
       -- M1.BRCH_CD
      HAVING (SUM(NVL(A1.debit,0))                                                                                <> 0
      OR SUM(NVL(A1.credit,0))                                                                                    <> 0
      OR ( SUM(NVL(B1.deb_obal,0)) - SUM(NVL(B1.cre_obal,0)) + SUM(NVL(D1.deb_todt,0)) - SUM(NVL(D1.cre_todt,0))) <> 0) 
      ORDER BY GL_ACCT;
    EXCEPTION
    WHEN OTHERS THEN
      V_ERROR_CD  :=-50;
      V_ERROR_MSG := SUBSTR('INSERT INTO R_TRIAL_BALANCE, SUMMARY  '||SQLERRM(SQLCODE),1,200);
      RAISE V_ERR;
    END;
    
  END IF;
*/
  
  P_RANDOM_VALUE := v_random_value;
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
END SPR_TRIAL_BALANCE;