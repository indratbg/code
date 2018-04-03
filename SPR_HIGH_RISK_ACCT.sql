create or replace PROCEDURE SPR_HIGH_RISK_ACCT(
    P_TRX_DATE      DATE,
    P_PRICE_DATE    DATE,
    P_BGN_MARGIN    VARCHAR2,
    P_END_MARGIN    VARCHAR2,
    P_LIMIT         NUMBER,
    P_LIMIT_disct   NUMBER,
    P_HRA_TYPE      VARCHAR2,
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
  V_HIGH_RISK_TYPE VARCHAR2(50);
BEGIN

  V_RANDOM_VALUE := ABS(DBMS_RANDOM.RANDOM);
  
  BEGIN
    SP_RPT_REMOVE_RAND('R_HIGH_RISK_ACCT',V_RANDOM_VALUE,V_ERROR_MSG,V_ERROR_CD);
  EXCEPTION
  WHEN OTHERS THEN
    V_ERROR_CD  := -10;
    V_ERROR_MSG := SUBSTR('SP_RPT_REMOVE_RAND '||V_ERROR_MSG||SQLERRM(SQLCODE),1,200);
    RAISE V_err;
  END;
  
  V_BAL_DATE := TO_DATE('01'||TO_CHAR(P_TRX_DATE,'MMYYYY'),'DDMMYYYY');
  
  IF P_HRA_TYPE ='LB' THEN
    V_HIGH_RISK_TYPE :='Loan Besar';
  ELSIF P_HRA_TYPE ='LS' THEN
    V_HIGH_RISK_TYPE :='Loan Short';
  ELSIF P_HRA_TYPE ='MC' THEN
    V_HIGH_RISK_TYPE :='Margin Call';
  ELSIF P_HRA_TYPE ='LWS' THEN
    V_HIGH_RISK_TYPE :='Margin Without Stock';
  ELSE
    V_HIGH_RISK_TYPE :='Margin Call Problematic Client';
  END IF;
  
    delete from TMP_HRA_CLIENT
  where rand_value = v_random_value
    and user_id = p_user_id;
    
    INSERT INTO TMP_HRA_CLIENT
    SELECT M.client_cd, V_RANDOM_VALUE, p_user_id
        FROM MST_CLIENT M, LST_TYPE3
        WHERE M.client_type_3 = LST_TYPE3.cl_type3
        AND LST_TYPE3.margin_Cd BETWEEN P_BGN_MARGIN AND P_END_MARGIN
        AND M.susp_stat = 'N'
        AND M.client_cd BETWEEN P_BGN_CLIENT AND P_END_CLIENT
        AND TRIM(M.branch_code) BETWEEN P_BGN_BRANCH AND P_END_BRANCH
        AND TRIM(M.rem_cd) BETWEEN P_BGN_REM AND P_END_REM
      AND ( (NOT EXISTS (SELECT client_cd FROM T_CLIENT_MRG_PROBLEM P where P.CLIENT_CD=M.CLIENT_CD AND P_TRX_DATE between bgn_dt and end_dt) AND P_HRA_TYPE <> 'MP') 
        OR ( EXISTS (SELECT client_cd FROM T_CLIENT_MRG_PROBLEM P where P.CLIENT_CD=M.CLIENT_CD AND P_TRX_DATE between bgn_dt and end_dt) AND P_HRA_TYPE <> 'MP'));

    
  BEGIN
    INSERT
    INTO R_HIGH_RISK_ACCT
      (
        BRANCH_CODE ,REM_CD ,CLIENT_CD ,CLIENT_NAME ,BALANCE ,BUYBACK ,BALANCE_PLUS_BUYBACK ,PORTFOLIO ,PORTFOLIO_PCTG ,
        PORTFOLIO_DISCT ,PORTFOLIO_DISCT_PCTG ,USER_ID ,RAND_VALUE ,GENERATE_DATE, HIGH_RISK_TYPE
      )
    SELECT branch_code, rem_cd, client_cd, client_name, balance, buyback, balance_plus_buyback, portfolio, portfolio_pctg,
    portfolio_disct, portfolio_disct_pctg, P_USER_ID, V_RANDOM_VALUE, P_GENERATE_DATE, V_HIGH_RISK_TYPE
    FROM
      (
        SELECT branch_code, rem_cd, client_cd, client_name, balance, buyback, balance_plus_buyback, portfolio, portfolio_pctg,
        portfolio_disct, ROUND(DECODE(portfolio_disct, 0, DECODE(balance_plus_buyback,0,0,ABS(balance) + buyback,999,0), balance_plus_buyback / portfolio_disct * 100)) AS portfolio_disct_pctg
        FROM
          (
            SELECT mc.branch_code AS branch_code, mc.rem_cd AS rem_cd, mc.client_cd AS client_cd, mc.client_name AS client_name, 
            BALANCE.balance AS balance, NVL(SAHAM.buyback, 0) AS buyback, NVL(BALANCE.balance,0) + NVL(SAHAM.buyback, 0) AS balance_plus_buyback,
            NVL(SAHAM.portfolio, 0) AS portfolio, ROUND(DECODE(NVL(SAHAM.portfolio, 0), 0, 0, (((BALANCE.balance + NVL(SAHAM.buyback, 0)) / NVL(SAHAM.portfolio, 0)) * 100))) AS portfolio_pctg,
            NVL(SAHAM.portfolio_disct, 0) AS portfolio_disct
            FROM
              (
                SELECT sl_acct_cd AS client_cd, SUM(beg_bal + mvmt) AS balance
                FROM
                  (
                    SELECT TRIM(T.sl_acct_cd) AS sl_acct_cd, 0 beg_bal, DECODE(db_cr_flg, 'D', 1,-1) * T.curr_val AS mvmt
                    FROM T_ACCOUNT_LEDGER t,
                            ( select client_cd
                                  from TMP_HRA_CLIENT 
                                  where rand_value = v_random_value
                                  and user_id = p_user_id) m
                    WHERE T.doc_date BETWEEN V_BAL_DATE AND P_TRX_DATE
                    --AND M.client_cd  BETWEEN P_BGN_CLIENT AND P_END_CLIENT
                    AND t.sl_acct_cd     = m.client_cd
                    AND T.record_source <> 'RE'
                    AND T.approved_sts  = 'A'
                    AND T.reversal_jur = 'N'
                    --AND M.susp_stat = 'N'
                    UNION ALL
                    SELECT TRIM(T.sl_acct_cd) AS sl_acct_cd, T.deb_obal - T.cre_obal AS beg_bal, 0 mvmt
                    FROM T_DAY_TRS t, TMP_HRA_CLIENT m
                    WHERE T.trs_dt   = V_BAL_DATE
                    AND t.sl_acct_cd = m.client_cd
                    and m.rand_value = v_random_value
                    and m.user_id = p_user_id
                   -- AND M.client_cd  BETWEEN P_BGN_CLIENT AND P_END_CLIENT
                   -- AND M.susp_stat = 'N'
                    UNION ALL
                    SELECT CLIENT_CD, 0 beg_bal, -NVL(F_FUND_BAL(client_cd, P_TRX_DATE),0) mvmt
                    FROM TMP_HRA_CLIENT
                    where rand_value = v_random_value
                    and user_id = p_user_id
                   -- WHERE SUSP_STAT = 'N'
                   -- AND client_cd  BETWEEN P_BGN_CLIENT AND P_END_CLIENT
                  )
                GROUP BY sl_acct_cd
              )BALANCE, 
              ( SELECT client_cd, SUM(stk_val) AS stk_val, DECODE(SIGN(SUM(stk_val)),1,0,0,0,-1 * SUM(stk_val)) AS buyback, 
                DECODE(SIGN(SUM(stk_val)),1, SUM(stk_val),0) AS portfolio, DECODE(SIGN(SUM(disct_val)),1, SUM(disct_val),0) AS portfolio_disct
                FROM
                  (
                    SELECT b.client_cd, b.stk_cd, NVL(b.theo_qty,0) theo_qty, NVL(p.price,0) price, NVL(b.theo_qty,0) * NVL(p.price,0) stk_val,
                    NVL(b.theo_qty,0) * NVL(p.price,0) * NVL(DECODE(c.margin_cd,'M',p.mrg_stk_cap,p.reg_stk_cap ), 0) / 100 disct_val
                    FROM
                      (
                        SELECT client_cd, stk_cd, SUM(beg_theo + theo_mvmt) theo_qty, COUNT(1) cnt
                        FROM
                          (
                            SELECT T_STK_MOVEMENT.client_cd, stk_cd, 0 beg_theo, (NVL(DECODE(SUBSTR(doc_num,5,2),'BR',1,'JR',1,'BI',1,'JI',1,'RS',1,'WS',1,0) * DECODE(db_cr_flg,'D',1,-1) * (total_share_qty + withdrawn_share_qty),0)) theo_mvmt
                            FROM T_STK_MOVEMENT, 
                                        ( select client_cd
                                          from TMP_HRA_CLIENT 
                                          where rand_value = v_random_value
                                          and user_id = p_user_id) m
                            WHERE doc_dt BETWEEN V_BAL_DATE AND P_TRX_DATE
                            AND T_STK_MOVEMENT.client_cd  = m.client_cd
                            AND gl_acct_cd IN ('10','12','13','14','51')
                            AND doc_stat    = '2'
                            AND s_d_type   <> 'V'
                            UNION ALL
                            SELECT T_STKBAL.client_cd, stk_cd, beg_bal_qty, 0 theo_mvmt
                            FROM T_STKBAL,  
                                        ( select client_cd
                                          from TMP_HRA_CLIENT 
                                          where rand_value = v_random_value
                                          and user_id = p_user_id) m
                            WHERE bal_dt = V_BAL_DATE
                            AND T_STKBAL.client_cd  = m.client_cd
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
                        SELECT T_CLOSE_PRICE.stk_cd, T_CLOSE_PRICE.stk_bidp AS price, 
                        DECODE(SIGN(P_PRICE_DATE - TO_DATE('01/01/09','dd/mm/yy')), 1, V_MARGIN_STK.MRG_STK_CAP, V_MARGIN_STK.reg_STK_CAP) AS mrg_stk_cap, 
                        v_margin_stk.Reg_stk_cap, v_margin_stk.tpl_stk_cap
                        FROM T_CLOSE_PRICE, v_margin_stk
                        WHERE T_CLOSE_PRICE.stk_date = P_PRICE_DATE
                        AND v_margin_stk.stk_cd      = T_CLOSE_PRICE.stk_cd
                      )
                      p
                    WHERE b.client_cd = c.client_cd
                    AND b.stk_cd      = p.stk_cd (+)
                    AND theo_qty     <> 0
                  )
                GROUP BY client_Cd
              ) SAHAM, 
              (
                SELECT M.client_cd, branch_code,rem_cd, client_name
                FROM MST_CLIENT M,  
                        ( select client_cd
                          from TMP_HRA_CLIENT 
                          where rand_value = v_random_value
                          and user_id = p_user_id) t
                WHERE T.client_cd  = m.client_cd
              ) mc
            WHERE mc.client_cd           = BALANCE.CLIENT_CD(+)
            AND mc.client_cd             = saham.client_cd (+)
            AND (NVL(balance.balance,0) <> 0
            OR NVL(saham.portfolio,0)   <> 0)
          )
      );
--    WHERE ( (portfolio_pctg  >= P_LIMIT OR 
--                    (portfolio_disct_pctg >= P_LIMIT_disct    AND portfolio_disct_pctg <> 999)
--                    OR portfolio_disct_pctg   = 999 )
--                 AND (P_HRA_TYPE           = 'MC'    OR P_HRA_TYPE             = 'MP') )
--    OR (P_HRA_TYPE            = 'LB'    AND balance_plus_buyback >= P_LIMIT)
--    OR (P_HRA_TYPE            = 'LS'    AND buyback              <> 0)
--    OR (P_HRA_TYPE            = 'LW'    AND portfolio             = 0    AND buyback              <> 0);
  EXCEPTION
  WHEN OTHERS THEN
    V_ERROR_CD  := -50;
    V_ERROR_MSG := SUBSTR('INSERT INTO R_HIGH_RISK_ACCT '||SQLERRM(SQLCODE),1,200);
    RAISE V_err;
  END;
  
    delete from TMP_HRA_CLIENT
  where rand_value = v_random_value
    and user_id = p_user_id;
  
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
END SPR_HIGH_RISK_ACCT;