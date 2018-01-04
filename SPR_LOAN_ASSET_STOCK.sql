create or replace PROCEDURE SPR_LOAN_ASSET_STOCK(
    P_BAL_DATE      DATE,
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
    P_BGN_STOCK     VARCHAR2,
    P_END_STOCK     VARCHAR2,
    P_PCTG          NUMBER,
    P_PCTG_DISC     NUMBER,
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
BEGIN

  V_RANDOM_VALUE := ABS(DBMS_RANDOM.RANDOM);
  
  BEGIN
    SP_RPT_REMOVE_RAND('R_LOAN_ASSET_STOCK',V_RANDOM_VALUE,V_ERROR_MSG,V_ERROR_CD);
  EXCEPTION
  WHEN OTHERS THEN
    V_ERROR_CD  := -10;
    V_ERROR_MSG := SUBSTR('SP_RPT_REMOVE_RAND '||V_ERROR_MSG||SQLERRM(SQLCODE),1,200);
    RAISE V_err;
  END;
  
  BEGIN
    INSERT
    INTO R_LOAN_ASSET_STOCK
      (
        BRANCH_CD ,BRANCH_NAME ,REM_CD ,REM_NAME ,CLIENT_CD ,CLIENT_NAME ,BALANCE ,BUYBACK ,BALANCE_PLUS_BUYBACK ,PORTFOLIO ,
        PORTFOLIO_PCTG ,PORTFOLIO_DISCT ,PORTFOLIO_DISCT_PCTG ,TRX_DATE ,BAL_DATE ,STK_DATE ,STK_CD ,QTY ,LOT ,PRICE ,STK_VAL ,USER_ID ,RAND_VALUE ,GENERATE_DATE
      )
    SELECT a.branch_cd, a.branch_name, a.rem_cd, a.rem_name, a.client_cd, a.client_name, a.balance, a.buyback, a.balance_plus_buyback,
    a.portfolio, a.portfolio_pctg, a.portfolio_disct, a.portfolio_disct_pctg, a.trx_date, a.bal_date, a.stk_date, b.stk_cd, b.bal_qty qty, 
    b.bal_qty/100 AS lot, c.stk_bidp AS price, b.bal_qty * c.stk_bidp AS stk_val, P_USER_ID, V_RANDOM_VALUE, P_GENERATE_DATE
    FROM
      (
        SELECT TRIM(mst_client.branch_code) branch_cd, mst_branch.brch_name branch_name, mst_client.rem_cd rem_cd, 
        mst_sales.rem_name rem_name, BALANCE.client_cd client_cd, mst_client.client_name client_name, BALANCE.balance balance,
        NVL(ABS(BUYBACK.buyback), 0) buyback, BALANCE.balance + NVL(ABS(BUYBACK.buyback), 0) balance_plus_buyback, 
        NVL(PORTFOLIO.portfolio, 0) portfolio, ROUND(DECODE(NVL(PORTFOLIO.portfolio, 0), 0, 0, (((BALANCE.balance + NVL(ABS(BUYBACK.buyback), 0)) / NVL(PORTFOLIO.portfolio, 0)) * 100))) AS portfolio_pctg, NVL(PORTFOLIO_DISCT.portfolio_disct, 0) AS portfolio_disct, ROUND(DECODE(NVL(PORTFOLIO_DISCT.portfolio_disct, 0), 0, DECODE(BALANCE.balance + NVL(ABS(BUYBACK.buyback), 0),0,0,ABS(BALANCE.balance) + NVL(ABS(BUYBACK.buyback), 0),999,0), (((BALANCE.balance + NVL(ABS(BUYBACK.buyback), 0)) / NVL(PORTFOLIO_DISCT.portfolio_disct, 0)) * 100))) AS portfolio_disct_pctg, P_TRX_DATE trx_date, P_BAL_DATE bal_date, P_PRICE_DATE stk_date
        FROM
          (
            SELECT client_cd AS client_cd, SUM(deb_todt - cre_todt + deb_obal - cre_obal) AS balance
            FROM
              (
                SELECT mst_client.client_cd AS client_cd, NVL(act_balance.deb_todt, 0) AS deb_todt, NVL(act_balance.cre_todt, 0) AS cre_todt,
                NVL(org_balance.deb_obal, 0) AS deb_obal, NVL(org_balance.cre_obal, 0) AS cre_obal
                FROM
                  (
                    SELECT mst_client.client_cd sl_acct_cd, SUM(DECODE(t_account_ledger.db_cr_flg, 'D', NVL(t_account_ledger.curr_val, 0), 0)) deb_todt, SUM(DECODE(t_account_ledger.db_cr_flg, 'C', NVL(t_account_ledger.curr_val, 0), 0)) cre_todt
                    FROM mst_client, lst_type3, t_account_ledger
                    WHERE mst_client.client_type_1 <> 'H'
                    AND mst_client.client_type_3    = lst_type3.cl_type3
                    AND lst_type3.margin_Cd BETWEEN P_BGN_MARGIN AND P_END_MARGIN
                    AND NVL(mst_Client.sett_off_cd,'Y') = 'Y'
                    AND mst_client.client_cd BETWEEN P_BGN_CLIENT AND P_END_CLIENT
                    AND mst_client.rem_cd BETWEEN P_BGN_REM AND P_END_REM
                    AND TRIM(mst_client.branch_code) BETWEEN P_BGN_BRANCH AND P_END_BRANCH
                    AND t_account_ledger.sl_acct_cd = mst_client.client_cd
                    AND t_account_ledger.doc_date BETWEEN P_BAL_DATE AND P_TRX_DATE
                    AND t_account_ledger.record_source <> 'OBAL'
                    AND t_account_ledger.approved_sts   ='A'
                    GROUP BY mst_client.client_cd
                  )
                  act_balance, (
                    SELECT mst_client.client_cd sl_acct_cd, SUM(NVL(t_day_trs.deb_obal, 0)) deb_obal, SUM(NVL(t_day_trs.cre_obal, 0)) cre_obal
                    FROM mst_client, lst_type3, t_day_trs
                    WHERE mst_client.client_type_1 <> 'H'
                    AND mst_client.client_type_3    = lst_type3.cl_type3
                    AND lst_type3.margin_Cd BETWEEN P_BGN_MARGIN AND P_END_MARGIN
                    AND NVL(mst_Client.sett_off_cd,'Y') = 'Y'
                    AND mst_client.client_cd BETWEEN P_BGN_CLIENT AND P_END_CLIENT
                    AND mst_client.rem_cd BETWEEN P_BGN_REM AND P_END_REM
                    AND TRIM(mst_client.branch_code) BETWEEN P_BGN_BRANCH AND P_END_BRANCH
                    AND t_day_trs.sl_acct_cd = mst_client.client_cd
                    AND t_day_trs.trs_dt     = P_BAL_DATE
                    GROUP BY mst_client.client_cd
                  )
                  org_balance, mst_client, lst_type3
                WHERE mst_client.client_type_3 = lst_type3.cl_type3
                AND lst_type3.margin_Cd BETWEEN P_BGN_MARGIN AND P_END_MARGIN
                AND NVL(mst_Client.sett_off_cd,'Y') = 'Y'
                AND mst_client.client_cd BETWEEN P_BGN_CLIENT AND P_END_CLIENT
                AND TRIM(mst_client.branch_code) BETWEEN P_BGN_BRANCH AND P_END_BRANCH
                AND (mst_client.rem_cd BETWEEN P_BGN_REM AND P_END_REM)
                AND act_balance.sl_acct_cd(+) = mst_client.client_cd
                AND org_balance.sl_acct_cd(+) = mst_client.client_cd
              --  ORDER BY mst_client.client_cd
              )
            GROUP BY client_cd
          )
          BALANCE, (
            SELECT client_cd, SUM(buyback) AS buyback
            FROM
              (
                SELECT A.client_cd AS client_cd, A.stk_cd AS stk_cd, A.bal_qty AS bal_qty, B.stk_clos AS stk_clos, (A.bal_qty * B.stk_clos) AS buyback
                FROM
                  (
                    SELECT mst_client.client_cd AS client_cd, t_stkhand.stk_cd AS stk_cd, t_stkhand.bal_qty AS bal_qty
                    FROM mst_client, lst_type3, t_stkhand
                    WHERE mst_client.client_type_1 <> 'H'
                    AND mst_client.client_type_3    = lst_type3.cl_type3
                    AND lst_type3.margin_Cd BETWEEN P_BGN_MARGIN AND P_END_MARGIN
                    AND NVL(mst_Client.sett_off_cd,'Y') = 'Y'
                    AND mst_client.client_cd BETWEEN P_BGN_CLIENT AND P_END_CLIENT
                    AND mst_client.rem_cd BETWEEN P_BGN_REM AND P_END_REM
                    AND TRIM(mst_client.branch_code) BETWEEN P_BGN_BRANCH AND P_END_BRANCH
                    AND t_stkhand.client_cd     = mst_client.client_cd
                    AND t_stkhand.STK_CD BETWEEN P_BGN_STOCK AND P_END_STOCK
                    AND TRIM(t_stkhand.bal_qty) < 0
                 --   ORDER BY mst_client.client_cd
                  )
                  A, (
                    SELECT t_close_price.stk_cd, t_close_price.stk_clos
                    FROM t_close_price, mst_counter
                    WHERE t_close_price.stk_date = P_PRICE_DATE
                    AND mst_counter.stk_cd       = t_close_price.stk_cd
                    AND mst_counter.STK_CD BETWEEN P_BGN_STOCK AND P_END_STOCK
                  )
                  B
                WHERE A.stk_cd = B.stk_cd
              )
            GROUP BY client_cd
          )
          BUYBACK, (
            SELECT client_cd AS client_cd, SUM(portfolio) AS portfolio
            FROM
              (
                SELECT A.client_cd, A.stk_cd, A.bal_qty, B.stk_bidp, (A.bal_qty * B.stk_bidp) AS portfolio
                FROM
                  (
                    SELECT mst_client.client_cd AS client_cd, t_stkhand.stk_cd AS stk_cd, t_stkhand.bal_qty AS bal_qty
                    FROM mst_client, lst_type3, t_stkhand
                    WHERE mst_client.client_type_1 <> 'H'
                    AND mst_client.client_type_3    = lst_type3.cl_type3
                    AND lst_type3.margin_Cd BETWEEN P_BGN_MARGIN AND P_END_MARGIN
                    AND NVL(mst_Client.sett_off_cd,'Y') = 'Y'
                    AND mst_client.client_cd BETWEEN P_BGN_CLIENT AND P_END_CLIENT
                    AND mst_client.rem_cd BETWEEN P_BGN_REM AND P_END_REM
                    AND TRIM(mst_client.branch_code) BETWEEN P_BGN_BRANCH AND P_END_BRANCH
                    AND t_stkhand.client_cd     = mst_client.client_cd
                    AND TRIM(t_stkhand.bal_qty) > 0
                    AND t_stkhand.STK_CD BETWEEN P_BGN_STOCK AND P_END_STOCK
            --        ORDER BY mst_client.client_cd
                  )
                  A, (
                    SELECT t_close_price.stk_cd, t_close_price.stk_bidp
                    FROM t_close_price, mst_counter
                    WHERE t_close_price.stk_date = P_PRICE_DATE
                    AND mst_counter.stk_cd       = t_close_price.stk_cd
                    AND mst_counter.STK_CD BETWEEN P_BGN_STOCK AND P_END_STOCK
                  )
                  B
                WHERE A.stk_cd = B.stk_cd
              )
            GROUP BY client_cd
          )
          PORTFOLIO, (
            SELECT CLIENT_CD, SUM(portfolio_disct) AS portfolio_disct
            FROM
              (
                SELECT A.client_cd, A.stk_cd, A.bal_qty, B.stk_bidp, (A.bal_qty * B.stk_bidp * (B.mrg_stk_cap / 100)) portfolio_disct
                FROM
                  (
                    SELECT mst_client.client_cd AS client_cd, TRIM(t_stkhand.stk_cd) AS stk_cd, t_stkhand.bal_qty AS bal_qty
                    FROM mst_client, lst_type3, t_stkhand
                    WHERE mst_client.client_type_1 <> 'H'
                    AND mst_client.client_type_3    = lst_type3.cl_type3
                    AND lst_type3.margin_Cd BETWEEN P_BGN_MARGIN AND P_END_MARGIN
                    AND NVL(mst_Client.sett_off_cd,'Y') = 'Y'
                    AND mst_client.client_cd BETWEEN P_BGN_CLIENT AND P_END_CLIENT
                    AND mst_client.rem_cd BETWEEN P_BGN_REM AND P_END_REM
                    AND TRIM(mst_client.branch_code) BETWEEN P_BGN_BRANCH AND P_END_BRANCH
                    AND t_stkhand.client_cd     = mst_client.client_cd
                    AND TRIM(t_stkhand.bal_qty) > 0
                    AND t_stkhand.STK_CD BETWEEN P_BGN_STOCK AND P_END_STOCK
                --    ORDER BY mst_client.client_cd
                  )
                  A, (
                    SELECT t_close_price.stk_cd, t_close_price.stk_bidp, mst_counter.mrg_stk_cap
                    FROM t_close_price, mst_counter
                    WHERE t_close_price.stk_date = P_PRICE_DATE
                    AND mst_counter.stk_cd       = t_close_price.stk_cd
                    AND mst_counter.STK_CD BETWEEN P_BGN_STOCK AND P_END_STOCK
                  )
                  B
                WHERE A.STK_CD = B.STK_CD
              )
            GROUP BY CLIENT_CD
          )
          PORTFOLIO_DISCT, mst_client, lst_type3, mst_branch, mst_sales
        WHERE mst_client.client_cd    = BALANCE.client_cd
        AND mst_client.client_type_1 <> 'H'
        AND mst_client.client_type_3  = lst_type3.cl_type3
        AND lst_type3.margin_Cd BETWEEN P_BGN_MARGIN AND P_END_MARGIN
        AND NVL(mst_Client.sett_off_cd,'Y') = 'Y'
        AND mst_client.client_cd BETWEEN P_BGN_CLIENT AND P_END_CLIENT
        AND TRIM(mst_client.branch_code) BETWEEN P_BGN_BRANCH AND P_END_BRANCH
        AND mst_client.rem_cd BETWEEN P_BGN_REM AND P_END_REM
        AND TRIM(mst_branch.brch_cd)     = TRIM(mst_client.branch_code)
        AND mst_sales.rem_cd             = mst_client.rem_cd
        AND PORTFOLIO.client_cd(+)       = BALANCE.client_cd
        AND BUYBACK.client_cd(+)         = BALANCE.client_cd
        AND PORTFOLIO_DISCT.client_cd(+) = BALANCE.client_cd
      )
      a, t_stkhand b, t_close_price c
    WHERE a.client_cd          =b.client_cd
    AND b.bal_qty             <>0
    AND (a.portfolio_pctg     >= P_PCTG
    OR a.portfolio_disct_pctg >= P_PCTG_DISC)
    AND c.stk_date             = P_PRICE_DATE
    AND c.stk_cd BETWEEN P_BGN_STOCK AND P_END_STOCK
    AND b.stk_cd=c.stk_cd;
   -- ORDER BY a.portfolio_disct_pctg DESC,a.portfolio_pctg DESC,a.client_cd,b.stk_cd;
  EXCEPTION
  WHEN OTHERS THEN
    V_ERROR_CD  := -50;
    V_ERROR_MSG := SUBSTR('INSERT INTO R_LOAN_ASSET_STOCK '||SQLERRM(SQLCODE),1,200);
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
END SPR_LOAN_ASSET_STOCK;