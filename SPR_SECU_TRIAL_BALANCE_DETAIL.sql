create or replace 
PROCEDURE SPR_SECU_TRIAL_BALANCE_DETAIL(
    P_END_DATE      DATE,
    P_BGN_ACCT      VARCHAR2,
    P_END_ACCT      VARCHAR2,
    P_BGN_CLIENT    VARCHAR2,
    P_END_CLIENT    VARCHAR2,
    P_BGN_STK       VARCHAR2,
    P_END_STK       VARCHAR2,
    P_SORT_BY VARCHAR2,
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
  --WITH CHANGE TICKER CODE
BEGIN

  V_RANDOM_VALUE := ABS(DBMS_RANDOM.RANDOM);
  
  BEGIN
    SP_RPT_REMOVE_RAND('R_SECU_TRIAL_BALANCE_DETAIL',V_RANDOM_VALUE,V_ERROR_MSG,V_ERROR_CD);
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
    INTO R_SECU_TRIAL_BALANCE_DETAIL
      (
        DOC_DATE ,
        GL_ACCT_CD ,
        CLIENT_CD ,
        CLIENT_NAME ,
        SUBREK001 ,
        OLD_CD ,
        STK_CD ,
        QTY ,
        DEBIT ,
        CREDIT ,
        END_QTY ,
        PRICE ,
        RASIO_S ,
        AMT ,
        SL_DESC ,
        SL_CODE ,
        USER_ID ,
        RAND_VALUE ,
        GENERATE_DATE,
        SORT_BY,
        CA_TYPE
      )
    SELECT P_END_DATE,
      p.GL_ACCT_CD,
      p.CLIENT_CD,
      m.client_name,
      s.subrek001,
      m.old_ic_num AS old_cd,
      p.STK_CD,
      p.QTY,
      p.DEBIT,
      p.CREDIT,
      p.END_QTY,
      NVL(C.close_price,0) Price,
      c.rasio_s,
      p.END_QTY * NVL(C.pricing,0) AMT,
      X.sl_desc,
      x.sl_code,
      P_USER_ID,
      V_RANDOM_VALUE,
      P_GENERATE_DATE,
      P_SORT_BY,
      C.CA_TYPE
    FROM
      (SELECT B2.gl_acct_cd,
        B2.CLIENT_CD,
        B2.stk_cd,
        MAX(NVL(B2.beg_bal,0)) qty,
        SUM(NVL(B2.D,0)) DEBIT,
        SUM(NVL(B2.C,0)) CREDIT,
        MAX(NVL(B2.beg_bal,0))+DECODE(SIGN(TO_NUMBER(B2.gl_acct_cd) - 30),-1, 1, -1) * (SUM(NVL(B2.D,0))-SUM(NVL(B2.C,0)) ) end_qty
      FROM
        (SELECT trim(gl_acct_cd) gl_acct_cd,
          client_cd,
          db_cr_flg,
          status,
          NVL(C.STK_CD_NEW,STK_CD)stk_cd,
          doc_dt,
          DECODE(trim(db_cr_flg),'D',NVL(withdrawn_share_qty,0) + NVL(total_share_qty,0)) D,
          DECODE(trim(db_cr_flg),'C',NVL(withdrawn_share_qty,0) + NVL(total_share_qty,0)) C,
          0 beg_bal
        FROM T_STK_MOVEMENT,
		 (SELECT STK_CD_NEW, STK_CD_OLD FROM T_CHANGE_STK_CD WHERE EFF_DT<=P_END_DATE)C
        WHERE doc_dt BETWEEN V_BGN_DATE AND P_END_DATE
		AND STK_CD = C.STK_CD_OLD(+)
        AND trim(gl_acct_cd) BETWEEN P_BGN_ACCT AND P_END_ACCT
        AND client_cd BETWEEN P_BGN_CLIENT AND P_END_CLIENT
        AND NVL(C.STK_CD_NEW,STK_CD) BETWEEN P_BGN_STK AND P_END_STK
        AND gl_acct_cd IS NOT NULL
        AND doc_stat    = '2'
        UNION ALL
        SELECT GL_ACCT_CD,CLIENT_CD,DB_CR_FLG,L_F,STK_CD,BAL_DT,D,C,SUM(QTY) beg_bal FROM
		(
		SELECT trim(gl_acct_cd) gl_acct_Cd,
          client_cd,
          NULL AS db_cr_flg,
          status l_f,
          NVL(C.STK_CD_NEW,STK_CD)stk_cd,
          bal_dt,
          0 D,
          0 C,
          NVL(qty,0)QTY
        FROM T_SECU_BAL,
		 (SELECT STK_CD_NEW, STK_CD_OLD FROM T_CHANGE_STK_CD WHERE EFF_DT<=P_END_DATE)C
        WHERE bal_dt = V_BGN_DATE
		AND STK_CD = C.STK_CD_OLD(+)
        AND trim(gl_acct_cd) BETWEEN P_BGN_ACCT AND P_END_ACCT
        AND client_cd BETWEEN P_BGN_CLIENT AND P_END_CLIENT
        AND  NVL(C.STK_CD_NEW,STK_CD) BETWEEN P_BGN_STK AND P_END_STK
		)
        GROUP BY stk_cd,
          client_cd,
          L_F,
          gl_acct_cd,
          bal_dt
        UNION ALL
        SELECT gl_acct_cd,
          client_Cd,
          NULL AS db_cr_flg,
          NULL l_f,
          reks_cd,
          V_BGN_DATE,
          SUM(deb_qty) deb_qty,
          SUM( cre_qty) cre_qty,
          SUM(bgn_qty) bgn_qty
        FROM
          (SELECT trim(gl_acct_cd) gl_acct_cd,
            broker_client_cd AS client_cd,
            reks_cd,
            DECODE(trim(gl_acct_cd),'10',debit - credit, credit - debit) bgn_qty,
            0 deb_qty,
            0 cre_qty
          FROM T_REKS_MOVEMENT,
            v_broker_subrek
          WHERE doc_dt < V_BGN_DATE
          AND doc_stat = '2'
          AND broker_client_cd BETWEEN P_BGN_CLIENT AND P_END_CLIENT
          AND P_BGN_STK = 'R'
          UNION ALL
          SELECT trim(gl_acct_cd) gl_acct_cd,
            broker_client_cd,
            reks_cd,
            0 bgn_qty,
            debit deb_qty,
            credit cre_qty
          FROM T_REKS_MOVEMENT,
            v_broker_subrek
          WHERE doc_dt BETWEEN V_BGN_DATE AND P_END_DATE
          AND doc_stat = '2'
          AND broker_client_cd BETWEEN P_BGN_CLIENT AND P_END_CLIENT
          AND P_BGN_STK = 'R'
          )
        GROUP BY gl_acct_cd,
          client_cd,
          reks_cd
        HAVING ( SUM(bgn_qty) <> 0
        OR SUM(deb_qty)       <> 0
        OR SUM( cre_qty)      <> 0 )
        ) B2
      GROUP BY B2.gl_acct_cd,
        B2.CLIENT_CD,
        B2.stk_cd
      ) P,
      (SELECT T.stk_cd,
        DECODE(T.stk_clos,0,T.stk_prev,T.stk_clos) close_price,
        DECODE(K.STK_CD,NULL,NULL,TO_CHAR(FROM_QTY)
        ||':'
        ||TO_CHAR( TO_QTY)) AS rasio_s,
        DECODE(K.STK_CD,NULL,DECODE(T.stk_clos,0,T.stk_prev,T.stk_clos), DECODE(T.stk_clos,0,T.stk_prev,T.stk_clos)/NVL(K.RASIO, 1)) pricing,
        CA_TYPE
      FROM T_CLOSE_PRICE T,
        (SELECT STK_CD,
          CA_TYPE,
          X_DT,
          RECORDING_DT,
          (FROM_QTY/TO_QTY) RASIO,
          FROM_QTY,
          TO_QTY
        FROM T_CORP_ACT
        WHERE CA_TYPE  IN ('SPLIT','REVERSE')
        AND P_END_DATE > '22MAR2012'
          --AND P_END_DATE < '29jun2015'
        AND X_DT         <= P_END_DATE
        AND RECORDING_DT >= P_END_DATE
        AND STK_CD BETWEEN P_BGN_STK AND P_END_STK
        AND approved_stat = 'A'
        ) K
      WHERE stk_date = V_PRICE_DATE
      AND T.stk_cd   = K.stk_cd (+)
      UNION ALL
      SELECT bond_cd,
        price,
        '',
        price / 100,
        NULL CA_TYPE
      FROM T_BOND_PRICE
      WHERE price_dt    = V_PRICE_DATE
      AND approved_stat = 'A'
      UNION ALL
      SELECT reks_cd,
        nab_unit,
        NULL,
        nab_unit,
        NULL CA_TYPE
      FROM T_REKS_NAB
      WHERE mkbd_dt     = P_END_DATE
      AND approved_stat = 'A'
      ) C,
      (SELECT trim(gl_acct_cd) gl_acct_cd,
        sl_code,
        sl_desc
      FROM MST_SECURITIES_LEDGER
      WHERE trim(gl_acct_cd) BETWEEN P_BGN_ACCT AND P_END_ACCT
      AND P_END_DATE BETWEEN ver_bgn_dt AND ver_end_dt
      ) X,
      MST_CLIENT m,
      v_client_subrek14 s
    WHERE p.stk_cd   = C.stk_cd (+)
    AND p.gl_acct_cd = x.gl_acct_cd
    AND p.client_cd  = m.client_cd
    AND p.client_cd  = s.client_cd (+)
    AND (p.QTY      <> 0
    OR p.DEBIT      <> 0
    OR p.CREDIT     <> 0
    OR p.END_QTY    <> 0);
  EXCEPTION
  WHEN OTHERS THEN
    V_ERROR_CD  := -40;
    V_ERROR_MSG := SUBSTR('INSERT INTO R_SECU_TRIAL_BALANCE_DETAIL '||SQLERRM(SQLCODE),1,200);
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
END SPR_SECU_TRIAL_BALANCE_DETAIL;