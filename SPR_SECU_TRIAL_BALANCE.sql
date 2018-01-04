CREATE OR REPLACE
PROCEDURE SPR_SECU_TRIAL_BALANCE(
    P_END_DATE      DATE,
    P_USER_ID       VARCHAR2,
    P_GENERATE_DATE DATE,
    P_RANDOM_VALUE OUT NUMBER,
    P_ERROR_CD OUT NUMBER,
    P_ERROR_MSG OUT VARCHAR2 )
AS
  V_ERR          EXCEPTION;
  V_ERROR_CD     NUMBER(5);
  V_ERROR_MSG    VARCHAR2(200);
  V_RANDOM_VALUE NUMBER(10);
  V_BGN_DATE     DATE;
  V_PRICE_DATE DATE;
BEGIN

  V_RANDOM_VALUE := ABS(DBMS_RANDOM.RANDOM);
  
  BEGIN
    SP_RPT_REMOVE_RAND('R_SECU_TRIAL_BALANCE',V_RANDOM_VALUE,V_ERROR_MSG,V_ERROR_CD);
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
  
  V_BGN_DATE := P_END_DATE - TO_CHAR(P_END_DATE,'DD')+1;
  V_PRICE_DATE := P_END_DATE;
  IF P_END_DATE >= TRUNC(SYSDATE) THEN

    BEGIN
      SELECT MAX(STK_DATE) INTO V_PRICE_DATE FROM T_CLOSE_PRICE WHERE STK_DATE<=P_END_DATE;
    EXCEPTION
    WHEN OTHERS THEN
      V_ERROR_CD  := -23;
      V_ERROR_MSG := SUBSTR('GET PRICE DATE'||V_ERROR_MSG,1,200);
    RAISE V_ERR;
    END;

  END IF;
  
  BEGIN
    INSERT
    INTO R_SECU_TRIAL_BALANCE
      (
        AS_AT ,
        AKTIVAPASIVA ,
        GL_ACCT_CD ,
        SL_DESC ,
        SL_CODE ,
        BAL_QTY ,
        DEBIT ,
        CREDIT ,
        END_QTY ,
        AMT ,
        USER_ID ,
        RAND_VALUE ,
        GENERATE_DATE
      )
    SELECT P_END_DATE,
      NULL AKTIVAPASIVA ,
      NULL GL_ACCT_CD ,
      'HEADER' SL_DESC ,
      'HEADER' SL_CODE ,
      NULL BAL_QTY ,
      NULL DEBIT ,
      NULL CREDIT ,
      NULL END_QTY ,
      NULL AMT ,
      P_USER_ID ,
      V_RANDOM_VALUE,
      P_GENERATE_DATE
    FROM DUAL
    UNION ALL
    SELECT P_END_DATE,
      DECODE(X.gl_acct_cd - 30, ABS(X.gl_acct_cd - 30), 2, 1) AktivaPasiva,
      X.gl_acct_cd,
      X.sl_desc,
      x.sl_code,
      (NVL(t1.bal_qty,0)) bal_qty,
      (NVL(t1.debit,0)) debit,
      (NVL(t1.credit,0)) credit,
      (NVL(t1.end_qty,0)) end_qty,
      (NVL(t1.amt,0)) amt,
      P_USER_ID,
      V_RANDOM_VALUE,
      P_GENERATE_DATE
    FROM
      (SELECT t.gl_acct_cd,
        SUM(NVL(t.qty,0)) bal_qty,
        SUM(NVL(t.debit,0)) debit,
        SUM(NVL(t.credit,0)) credit,
        SUM(NVL(t.end_qty,0)) end_qty,
        SUM(NVL(t.end_qty,0) * NVL(c.pricing,0)) amt
      FROM
        (SELECT trim(B2.gl_acct_cd) gl_acct_cd,
          B2.stk_cd,
          NVL(B2.beg_bal,0) qty,
          NVL((B2.D),0) DEBIT,
          NVL((B2.C),0) CREDIT,
          NVL(B2.beg_bal,0)+DECODE(SIGN(TO_NUMBER(B2.gl_acct_cd)-30),-1,1,-1) * (NVL(B2.D,0)-NVL(B2.C,0)) end_qty
        FROM
          (SELECT gl_acct_cd,
            stk_cd,
            SUM(DECODE(trim(db_cr_flg),'D',NVL(withdrawn_share_qty,0) + NVL(total_share_qty,0))) D,
            SUM(DECODE(trim(db_cr_flg),'C',NVL(withdrawn_share_qty,0) + NVL(total_share_qty,0))) C,
            0 beg_bal
          FROM T_STK_MOVEMENT
          WHERE doc_stat  = '2'
          AND gl_acct_cd IS NOT NULL
          AND doc_dt BETWEEN V_BGN_DATE AND P_END_DATE
          GROUP BY gl_acct_cd,
            stk_cd
          UNION ALL
          SELECT gl_acct_cd,
            stk_cd,
            0 D,
            0 C,
            SUM(qty) beg_bal
          FROM T_SECU_BAL t
          WHERE t.bal_dt = V_BGN_DATE
          GROUP BY gl_acct_cd,
            stk_cd
          UNION ALL
          SELECT gl_acct_cd,
            reks_cd,
            SUM(deb_qty) deb_qty,
            SUM( cre_qty) cre_qty,
            SUM(bgn_qty) bgn_qty
          FROM
            (SELECT trim(gl_acct_cd) gl_acct_cd,
              reks_cd,
              DECODE(trim(gl_acct_cd),'10',debit - credit, credit - debit) bgn_qty,
              0 deb_qty,
              0 cre_qty
            FROM T_REKS_MOVEMENT
            WHERE doc_dt < V_BGN_DATE
            AND doc_stat = '2'
            UNION ALL
            SELECT trim(gl_acct_cd) gl_acct_cd,
              reks_cd,
              0 bgn_qty,
              debit deb_qty,
              credit cre_qty
            FROM T_REKS_MOVEMENT
            WHERE doc_dt BETWEEN V_BGN_DATE AND P_END_DATE
            AND doc_stat = '2'
            )
          GROUP BY gl_acct_cd,
            reks_cd
          HAVING ( SUM(bgn_qty) <> 0
          OR SUM(deb_qty)       <> 0
          OR SUM( cre_qty)      <> 0 )
          ) B2
        ) T,
        (SELECT T.stk_cd,
          DECODE(K.STK_CD,NULL, DECODE(T.stk_clos,0,T.stk_prev,T.stk_clos), DECODE(T.stk_clos,0,T.stk_prev,T.stk_clos)/NVL(K.rasio,1)) pricing
        FROM T_CLOSE_PRICE T,
          (SELECT STK_CD,
            CA_TYPE,
            X_DT,
            RECORDING_DT,
            (FROM_QTY/TO_QTY) rasio
          FROM INSISTPRO.T_CORP_ACT
          WHERE CA_TYPE    IN ('SPLIT','REVERSE')
          AND P_END_DATE    > '22MAR2012'
          AND X_DT         <= P_END_DATE
          AND RECORDING_DT >= P_END_DATE
          AND approved_stat = 'A'
          ) K
        WHERE stk_date = V_PRICE_DATE
        AND T.stk_cd   = K.stk_cd (+)
        UNION
        SELECT bond_cd,
          price / 100
        FROM T_BOND_PRICE
        WHERE price_dt    = V_PRICE_DATE
        AND approved_stat = 'A'
        UNION
        SELECT reks_cd,
          nab_unit
        FROM T_REKS_NAB
        WHERE mkbd_dt     = P_END_DATE
        AND approved_stat = 'A'
        ) C
      WHERE t.stk_cd = c.stk_cd (+)
      GROUP BY t.gl_acct_cd
      ) T1,
      (SELECT trim(gl_acct_cd) gl_acct_cd,
        sl_desc,
        sl_code
      FROM MST_SECURITIES_LEDGER
      WHERE P_END_DATE BETWEEN ver_bgn_dt AND ver_end_dt
      ) X
    WHERE X.gl_acct_cd = t1.gl_acct_cd(+)
    ORDER BY 2,5;
  EXCEPTION
  WHEN OTHERS THEN
    V_ERROR_CD  := -40;
    V_ERROR_MSG := SUBSTR('INSERT INTO R_SECU_TRIAL_BALANCE '||SQLERRM(SQLCODE),1,200);
    RAISE V_err;
  END;
  
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
END SPR_SECU_TRIAL_BALANCE;