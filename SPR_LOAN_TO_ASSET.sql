CREATE OR REPLACE PROCEDURE SPR_LOAN_TO_ASSET(
    P_TRX_DATE      DATE,
    P_PRICE_DATE    DATE,
    P_BGN_MARGIN    VARCHAR2,
    P_END_MARGIN    VARCHAR2,
    P_BGN_CLIENT    VARCHAR2,
    P_END_CLIENT    VARCHAR2,
    P_BGN_BRANCH    VARCHAR2,
    P_END_BRANCH    VARCHAR2,
    P_BGN_REM       VARCHAR2,
    P_END_REM       VARCHAR2,
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
  V_BAL_DATE     DATE;
BEGIN

  V_RANDOM_VALUE := ABS(DBMS_RANDOM.RANDOM);
  
  BEGIN
    SP_RPT_REMOVE_RAND('R_LOAN_TO_ASSET',V_RANDOM_VALUE,V_ERROR_MSG,V_ERROR_CD);
  EXCEPTION
  WHEN OTHERS THEN
    V_ERROR_CD  := -10;
    V_ERROR_MSG := SUBSTR('SP_RPT_REMOVE_RAND '||V_ERROR_MSG||SQLERRM(SQLCODE),1,200);
    RAISE V_err;
  END;
  
  V_BAL_DATE := TO_DATE('01'||TO_CHAR(P_TRX_DATE,'MMYYYY'),'DDMMYYYY');
  
  BEGIN
    INSERT
    INTO R_LOAN_TO_ASSET
      (
        BRANCH_CD ,BRANCH_NAME ,REM_CD ,REM_NAME ,CLIENT_CD ,CLIENT_NAME ,BALANCE ,BUYBACK ,
        BALANCE_PLUS_BUYBACK ,PORTFOLIO ,PORTFOLIO_PCTG ,PORTFOLIO_DISCT ,PORTFOLIO_DISCT_PCTG ,USER_ID ,RAND_VALUE ,GENERATE_DATE
      )
    SELECT mc.branch_cd, mc.branch_name, mc. rem_cd, mc.rem_name, mc. client_cd,
    mc.client_name, NVL(BALANCE.balance,0) balance, NVL(SAHAM.buyback, 0) buyback, NVL(BALANCE.balance,0) + NVL(SAHAM.buyback, 0) AS balance_plus_buyback, NVL(SAham.portfolio, 0) portfolio, DECODE(NVL(SAham.portfolio, 0), 0, 0, (((BALANCE.balance + NVL(ABS(SAHAM.buyback), 0)) / NVL(SAham.portfolio, 0)) * 100)) AS portfolio_pctg, NVL(SAham.portfolio_disct, 0) portfolio_disct, DECODE(NVL(Saham.portfolio_disct, 0), 0, 0, (((BALANCE.balance + NVL(ABS(Saham.buyback), 0)) / NVL(SAham.portfolio_disct, 0)) * 100)) AS portfolio_disct_pctg, P_USER_ID, V_RANDOM_VALUE, P_GENERATE_DATE
    FROM
      (
        SELECT client_cd, SUM(beg_bal + mvmt) balance
        FROM
          (
            SELECT TRIM(MST_CLIENT.client_cd) client_cd, 0 beg_bal,
            DECODE(T_ACCOUNT_LEDGER.db_cr_flg, 'D', 1,-1) * T_ACCOUNT_LEDGER.curr_val mvmt
            FROM MST_CLIENT, T_ACCOUNT_LEDGER
            WHERE MST_CLIENT.client_cd BETWEEN P_BGN_CLIENT AND P_END_CLIENT
            AND TRIM(MST_CLIENT.rem_cd) BETWEEN P_BGN_REM AND P_END_REM
            AND TRIM(MST_CLIENT.branch_code) BETWEEN P_BGN_BRANCH AND P_END_BRANCH
            AND T_ACCOUNT_LEDGER.sl_acct_cd = MST_CLIENT.client_cd
            AND T_ACCOUNT_LEDGER.doc_date BETWEEN V_BAL_DATE AND P_TRX_DATE
            AND T_ACCOUNT_LEDGER.approved_sts = 'A'
            UNION ALL
            SELECT TRIM(MST_CLIENT.client_cd) client_cd, T_DAY_TRS.deb_obal - T_DAY_TRS.cre_obal beg_bal, 0 mvmt
            FROM MST_CLIENT, T_DAY_TRS
            WHERE MST_CLIENT.client_cd BETWEEN P_BGN_CLIENT AND P_END_CLIENT
            AND MST_CLIENT.rem_cd BETWEEN P_BGN_REM AND P_END_REM
            AND TRIM(MST_CLIENT.branch_code) BETWEEN P_BGN_BRANCH AND P_END_BRANCH
            AND T_DAY_TRS.sl_acct_cd = MST_CLIENT.client_cd
            AND T_DAY_TRS.trs_dt     = V_BAL_DATE
            UNION ALL
            SELECT CLIENT_CD, ABS(DECODE(SIGN(rekdana_balance),-1, rekdana_balance,0)) - ABS(DECODE(SIGN(rekdana_balance),-1, 0, rekdana_balance)) beg_bal, 0 mvmt
            FROM
              (
                SELECT CLIENT_CD, NVL(F_FUND_BAL(MST_CLIENT.client_cd, P_TRX_DATE),0) rekdana_balance
                FROM MST_CLIENT
                WHERE SUSP_STAT = 'N'
                AND MST_CLIENT.client_cd BETWEEN P_BGN_CLIENT AND P_END_CLIENT
              )
          )
        GROUP BY client_cd
      )
      BALANCE, (
        SELECT client_cd, SUM(stk_val) AS stk_val, DECODE(SIGN(SUM(stk_val)),1,0,-1 * SUM(stk_val)) AS buyback,
        DECODE(SIGN(SUM(stk_val)),1, SUM(stk_val),0) AS portfolio, DECODE(SIGN(SUM(disct_val)),1, SUM(disct_val),0) AS portfolio_disct
        FROM
          (
            SELECT b.client_cd, b.stk_cd, NVL(b.theo_qty,0) theo_qty, NVL(p.price,0) price,
            NVL(b.theo_qty,0) * NVL(p.price,0) stk_val, NVL(b.theo_qty,0) * NVL(p.price,0) * NVL(DECODE(c.margin_cd,'M',p.mrg_stk_cap,p.reg_stk_cap ), 0) / 100 disct_val
            FROM
              (
                SELECT client_cd, stk_cd, SUM(beg_theo + theo_mvmt) theo_qty
                FROM
                  (
                    SELECT client_cd, stk_cd, 0 beg_theo,
                    (NVL(DECODE(SUBSTR(doc_num,5,2),'BR',1,'JR',1,'BI',1,'JI',1,'RS',1,'WS',1,0) * DECODE(db_cr_flg,'D',1,-1) * (total_share_qty + withdrawn_share_qty),0)) theo_mvmt
                    FROM T_STK_MOVEMENT
                    WHERE doc_dt BETWEEN V_BAL_DATE AND P_TRX_DATE
                    AND client_cd  >= P_BGN_CLIENT
                    AND client_cd  <= P_END_CLIENT
                    AND gl_acct_cd IN ('10','12','13','14','51')
                    AND doc_stat    = '2'
                    AND s_d_type   <> 'V'
                    UNION ALL
                    SELECT client_cd, stk_cd, beg_bal_qty, 0 theo_mvmt
                    FROM T_STKBAL
                    WHERE bal_dt = V_BAL_DATE
                    AND client_cd BETWEEN P_BGN_CLIENT AND P_END_CLIENT
                  )
                GROUP BY client_cd, stk_cd
              )
              b, (
                SELECT m.client_cd, l.margin_cd
                FROM MST_CLIENT m, LST_TYPE3 l
                WHERE m.client_cd BETWEEN P_BGN_CLIENT AND P_END_CLIENT
                AND m.client_type_3 = l.cl_type3
                AND l.margin_cd BETWEEN P_BGN_MARGIN AND P_END_MARGIN
              )
              c, (
                SELECT T_CLOSE_PRICE.stk_cd, T_CLOSE_PRICE.stk_bidp AS price, DECODE(SIGN(P_PRICE_DATE - TO_DATE('01/01/09','dd/mm/yy')), 1,
                V_MARGIN_STK.MRG_STK_CAP, V_MARGIN_STK.reg_STK_CAP) AS mrg_stk_cap, v_margin_stk.Reg_stk_cap, v_margin_stk.tpl_stk_cap
                FROM T_CLOSE_PRICE, v_margin_stk
                WHERE T_CLOSE_PRICE.stk_date = P_PRICE_DATE
                AND v_margin_stk.stk_cd      = T_CLOSE_PRICE.stk_cd
              )
              p
            WHERE b.client_cd = c.client_cd
            AND b.stk_cd      = p.stk_cd (+)
            AND b.theo_qty   <> 0
          )
        GROUP BY client_Cd
      )
      SAHAM, (
        SELECT TRIM(MST_CLIENT.branch_code) branch_cd, TRIM(MST_BRANCH.brch_name) branch_name, TRIM(MST_CLIENT.rem_cd) rem_cd, 
        TRIM(MST_SALES.rem_name) rem_name, MST_CLIENT.client_cd client_cd, TRIM(MST_CLIENT.client_name) client_name
        FROM MST_CLIENT, LST_TYPE3, MST_BRANCH, MST_SALES
        WHERE MST_CLIENT.client_cd BETWEEN P_BGN_CLIENT AND P_END_CLIENT
        AND TRIM(MST_CLIENT.branch_code) BETWEEN P_BGN_BRANCH AND P_END_BRANCH
        AND MST_CLIENT.rem_cd BETWEEN P_BGN_REM AND P_END_REM
        AND MST_CLIENT.client_type_3  = LST_TYPE3.cl_type3
        AND MST_CLIENT.client_type_1 <> 'B'
        AND MST_CLIENT.client_type_1 <> 'H'
        AND MST_CLIENT.susp_stat      = 'N'
        AND LST_TYPE3.margin_cd BETWEEN P_BGN_MARGIN AND P_END_MARGIN
        AND TRIM(MST_BRANCH.brch_cd) = TRIM(MST_CLIENT.branch_code)
        AND TRIM(MST_SALES.rem_cd)   = TRIM(MST_CLIENT.rem_cd)
      )
      mc
    WHERE Mc.client_cd           = BALANCE.client_cd (+)
    AND Mc.client_cd             = saham.client_Cd (+)
    AND (NVL(BALANCE.balance,0) <> 0
    OR NVL(saham.stk_val,0)     <> 0)
    ORDER BY 1,3, 5;
  EXCEPTION
  WHEN OTHERS THEN
    V_ERROR_CD  := -50;
    V_ERROR_MSG := SUBSTR('INSERT INTO R_LOAN_TO_ASSET '||SQLERRM(SQLCODE),1,200);
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
END SPR_LOAN_TO_ASSET;