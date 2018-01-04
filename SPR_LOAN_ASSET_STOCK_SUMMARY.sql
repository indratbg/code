create or replace PROCEDURE SPR_LOAN_ASSET_STOCK_SUMMARY(
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
    SP_RPT_REMOVE_RAND('R_LOAN_ASSET_STOCK_SUMMARY',V_RANDOM_VALUE,V_ERROR_MSG,V_ERROR_CD);
  EXCEPTION
  WHEN OTHERS THEN
    V_ERROR_CD  := -10;
    V_ERROR_MSG := SUBSTR('SP_RPT_REMOVE_RAND '||V_ERROR_MSG||SQLERRM(SQLCODE),1,200);
    RAISE V_err;
  END;
  
  INSERT INTO TMP_LOAN2A_STKSUMM_CLIENT
    select client_cd
  FROM mst_client, lst_type3 
    WHERE mst_client.client_type_1 <> 'H'
    AND mst_client.client_type_1 <> 'B'
    AND mst_client.client_type_3    = lst_type3.cl_type3
    AND lst_type3.margin_Cd BETWEEN P_BGN_MARGIN AND P_END_MARGIN
    --AND NVL(mst_Client.sett_off_cd,'Y') = 'Y'
    AND mst_client.client_cd BETWEEN P_BGN_CLIENT AND P_END_CLIENT
    AND mst_client.rem_cd BETWEEN P_BGN_REM AND P_END_REM
    AND TRIM(mst_client.branch_code) BETWEEN P_BGN_BRANCH AND P_END_BRANCH
    AND susp_stat = 'N';

  
  BEGIN
    INSERT
    INTO R_LOAN_ASSET_STOCK_SUMMARY
      (
        STK_CD ,TOT_QTY ,TOT_LOT ,PRICE ,TOT_STK_VAL ,CLIENT_CD ,QTY ,LOT ,STK_VAL ,RAND_VALUE ,USER_ID ,GENERATE_DATE,ORIGINAL,DISCOUNT
      )
    SELECT Q1.STK_CD, Q2.TOT_QTY, Q2.TOT_LOT, Q1.PRICE, Q2.TOT_STK_VAL, Q1.CLIENT_CD, Q1.QTY, Q1.LOT, Q1.STK_VAL, V_RANDOM_VALUE, P_USER_ID, P_GENERATE_DATE, P_PCTG, P_PCTG_DISC
    FROM
      (
        SELECT XX.STK_CD, XX.QTY, XX.LOT, XX.PRICE, XX.STK_VAL, XX.CLIENT_CD
        FROM
          (
            SELECT A.BRANCH_CD, A.BRANCH_NAME, A.REM_CD, A.REM_NAME, A.CLIENT_CD, A.CLIENT_NAME, A.BALANCE, A.BUYBACK, A.BALANCE_PLUS_BUYBACK, A.PORTFOLIO, A.PORTFOLIO_PCTG, A.PORTFOLIO_DISCT, A.PORTFOLIO_DISCT_PCTG, A.TRX_DATE, A.BAL_DATE, A.STK_DATE, B.STK_CD, B.BAL_QTY QTY, B.BAL_QTY/500 AS LOT, C.STK_BIDP AS PRICE, B.BAL_QTY * C.STK_BIDP AS STK_VAL
            FROM
              (
                SELECT TRIM(MST_CLIENT.BRANCH_CODE) BRANCH_CD, MST_BRANCH.BRCH_NAME BRANCH_NAME, MST_CLIENT.REM_CD REM_CD, MST_SALES.REM_NAME REM_NAME, BALANCE.CLIENT_CD CLIENT_CD, TRIM(MST_CLIENT.CLIENT_NAME) CLIENT_NAME, BALANCE.BALANCE BALANCE, NVL(ABS(BUYBACK.BUYBACK), 0) BUYBACK, BALANCE.BALANCE + NVL(ABS(BUYBACK.BUYBACK), 0) BALANCE_PLUS_BUYBACK, NVL(PORTFOLIO.PORTFOLIO, 0) PORTFOLIO, ROUND(DECODE(NVL(PORTFOLIO.PORTFOLIO, 0), 0, 0, (((BALANCE.BALANCE + NVL(ABS(BUYBACK.BUYBACK), 0)) / NVL(PORTFOLIO.PORTFOLIO, 0)) * 100))) AS PORTFOLIO_PCTG, NVL(PORTFOLIO_DISCT.PORTFOLIO_DISCT, 0) AS PORTFOLIO_DISCT, ROUND(DECODE(NVL(PORTFOLIO_DISCT.PORTFOLIO_DISCT, 0), 0, DECODE(BALANCE.BALANCE + NVL(ABS(BUYBACK.BUYBACK), 0),0,0,ABS(BALANCE.BALANCE) + NVL(ABS(BUYBACK.BUYBACK), 0),999,0), (((BALANCE.BALANCE + NVL(ABS(BUYBACK.BUYBACK), 0)) / NVL(PORTFOLIO_DISCT.PORTFOLIO_DISCT, 0)) * 100))) AS PORTFOLIO_DISCT_PCTG, P_TRX_DATE TRX_DATE, P_BAL_DATE BAL_DATE, TRUNC( P_PRICE_DATE) STK_DATE
                FROM
                  (
                    SELECT CLIENT_CD AS CLIENT_CD, SUM(DEB_TODT - CRE_TODT + DEB_OBAL - CRE_OBAL) AS BALANCE
                    FROM
                      (
                        SELECT MST_CLIENT.CLIENT_CD AS CLIENT_CD, NVL(ACT_BALANCE.DEB_TODT, 0) AS DEB_TODT, NVL(ACT_BALANCE.CRE_TODT, 0) AS CRE_TODT, NVL(ORG_BALANCE.DEB_OBAL, 0) AS DEB_OBAL, NVL(ORG_BALANCE.CRE_OBAL, 0) AS CRE_OBAL
                        FROM
                          (
                            SELECT MST_CLIENT.CLIENT_CD SL_ACCT_CD, SUM(DECODE(T_ACCOUNT_LEDGER.DB_CR_FLG, 'D', NVL(T_ACCOUNT_LEDGER.CURR_VAL, 0), 0)) DEB_TODT, SUM(DECODE(T_ACCOUNT_LEDGER.DB_CR_FLG, 'C', NVL(T_ACCOUNT_LEDGER.CURR_VAL, 0), 0)) CRE_TODT
                            FROM MST_CLIENT, LST_TYPE3, T_ACCOUNT_LEDGER
                            WHERE MST_CLIENT.CLIENT_TYPE_1 <> 'H'
                            AND MST_CLIENT.CLIENT_TYPE_3    = LST_TYPE3.CL_TYPE3
                            AND LST_TYPE3.MARGIN_CD BETWEEN P_BGN_MARGIN AND P_END_MARGIN
                            AND NVL(MST_CLIENT.SETT_OFF_CD,'Y') = 'Y'
                            AND MST_CLIENT.CLIENT_CD BETWEEN P_BGN_CLIENT AND P_END_CLIENT
                            AND MST_CLIENT.REM_CD BETWEEN P_BGN_REM AND P_END_REM
                            AND TRIM(MST_CLIENT.BRANCH_CODE) BETWEEN P_BGN_BRANCH AND P_END_BRANCH
                            AND T_ACCOUNT_LEDGER.SL_ACCT_CD = MST_CLIENT.CLIENT_CD
                            AND T_ACCOUNT_LEDGER.DOC_DATE BETWEEN P_BAL_DATE AND P_TRX_DATE
                            AND T_ACCOUNT_LEDGER.RECORD_SOURCE <> 'OBAL'
                            AND T_ACCOUNT_LEDGER.APPROVED_STS   = 'A'
                            GROUP BY MST_CLIENT.CLIENT_CD
                          )
                          ACT_BALANCE, (
                            SELECT MST_CLIENT.CLIENT_CD SL_ACCT_CD, SUM(NVL(T_DAY_TRS.DEB_OBAL, 0)) DEB_OBAL, SUM(NVL(T_DAY_TRS.CRE_OBAL, 0)) CRE_OBAL
                            FROM MST_CLIENT, LST_TYPE3, T_DAY_TRS
                            WHERE MST_CLIENT.CLIENT_TYPE_1 <> 'H'
                            AND MST_CLIENT.CLIENT_TYPE_3    = LST_TYPE3.CL_TYPE3
                            AND LST_TYPE3.MARGIN_CD BETWEEN P_BGN_MARGIN AND P_END_MARGIN
                            AND NVL(MST_CLIENT.SETT_OFF_CD,'Y') = 'Y'
                            AND MST_CLIENT.CLIENT_CD BETWEEN P_BGN_CLIENT AND P_END_CLIENT
                            AND MST_CLIENT.REM_CD BETWEEN P_BGN_REM AND P_END_REM
                            AND TRIM(MST_CLIENT.BRANCH_CODE) BETWEEN P_BGN_BRANCH AND P_END_BRANCH
                            AND T_DAY_TRS.SL_ACCT_CD = MST_CLIENT.CLIENT_CD
                            AND T_DAY_TRS.TRS_DT     = P_BAL_DATE
                            GROUP BY MST_CLIENT.CLIENT_CD
                          )
                          ORG_BALANCE, MST_CLIENT, LST_TYPE3
                        WHERE MST_CLIENT.CLIENT_TYPE_3 = LST_TYPE3.CL_TYPE3
                        AND LST_TYPE3.MARGIN_CD BETWEEN P_BGN_MARGIN AND P_END_MARGIN
                        AND NVL(MST_CLIENT.SETT_OFF_CD,'Y') = 'Y'
                        AND MST_CLIENT.CLIENT_CD BETWEEN P_BGN_CLIENT AND P_END_CLIENT
                        AND TRIM(MST_CLIENT.BRANCH_CODE) BETWEEN P_BGN_BRANCH AND P_END_BRANCH
                        AND MST_CLIENT.REM_CD BETWEEN P_BGN_REM AND P_END_REM
                        AND ACT_BALANCE.SL_ACCT_CD(+) = MST_CLIENT.CLIENT_CD
                        AND ORG_BALANCE.SL_ACCT_CD(+) = MST_CLIENT.CLIENT_CD
                        ORDER BY MST_CLIENT.CLIENT_CD
                      )
                    GROUP BY CLIENT_CD
                  )
                  BALANCE, (
                    SELECT CLIENT_CD, SUM(BUYBACK) AS BUYBACK
                    FROM
                      (
                        SELECT A.CLIENT_CD AS CLIENT_CD, A.STK_CD AS STK_CD, A.BAL_QTY AS BAL_QTY, B.STK_CLOS AS STK_CLOS, (A.BAL_QTY * B.STK_CLOS) AS BUYBACK
                        FROM
                          (
                            SELECT MST_CLIENT.CLIENT_CD AS CLIENT_CD, T_STKHAND.STK_CD, T_STKHAND.BAL_QTY AS BAL_QTY
                            FROM MST_CLIENT, LST_TYPE3, T_STKHAND
                            WHERE MST_CLIENT.CLIENT_TYPE_1 <> 'H'
                            AND MST_CLIENT.CLIENT_TYPE_3    = LST_TYPE3.CL_TYPE3
                            AND LST_TYPE3.MARGIN_CD BETWEEN P_BGN_MARGIN AND P_END_MARGIN
                            AND NVL(MST_CLIENT.SETT_OFF_CD,'Y') = 'Y'
                            AND MST_CLIENT.CLIENT_CD BETWEEN P_BGN_CLIENT AND P_END_CLIENT
                            AND MST_CLIENT.REM_CD BETWEEN P_BGN_REM AND P_END_REM
                            AND TRIM(MST_CLIENT.BRANCH_CODE) BETWEEN P_BGN_BRANCH AND P_END_BRANCH
                            AND T_STKHAND.CLIENT_CD     = MST_CLIENT.CLIENT_CD
                            AND TRIM(T_STKHAND.BAL_QTY) < 0
                            ORDER BY MST_CLIENT.CLIENT_CD
                          )
                          A, (
                            SELECT T_CLOSE_PRICE.STK_CD, T_CLOSE_PRICE.STK_CLOS
                            FROM T_CLOSE_PRICE, MST_COUNTER
                            WHERE T_CLOSE_PRICE.STK_DATE = P_PRICE_DATE
                            AND MST_COUNTER.STK_CD       = T_CLOSE_PRICE.STK_CD
                          )
                          B
                        WHERE A.STK_CD = B.STK_CD
                      )
                    GROUP BY CLIENT_CD
                  )
                  BUYBACK, (
                    SELECT CLIENT_CD AS CLIENT_CD, SUM(PORTFOLIO) AS PORTFOLIO
                    FROM
                      (
                        SELECT A.CLIENT_CD, A.STK_CD, A.BAL_QTY, B.STK_BIDP, (A.BAL_QTY * B.STK_BIDP) AS PORTFOLIO
                        FROM
                          (
                            SELECT MST_CLIENT.CLIENT_CD AS CLIENT_CD, T_STKHAND.STK_CD AS STK_CD, T_STKHAND.BAL_QTY AS BAL_QTY
                            FROM MST_CLIENT, LST_TYPE3, T_STKHAND
                            WHERE MST_CLIENT.CLIENT_TYPE_1 <> 'H'
                            AND MST_CLIENT.CLIENT_TYPE_3    = LST_TYPE3.CL_TYPE3
                            AND LST_TYPE3.MARGIN_CD BETWEEN P_BGN_MARGIN AND P_END_MARGIN
                            AND NVL(MST_CLIENT.SETT_OFF_CD,'Y') = 'Y'
                            AND MST_CLIENT.CLIENT_CD BETWEEN P_BGN_CLIENT AND P_END_CLIENT
                            AND MST_CLIENT.REM_CD BETWEEN P_BGN_REM AND P_END_REM
                            AND TRIM(MST_CLIENT.BRANCH_CODE) BETWEEN P_BGN_BRANCH AND P_END_BRANCH
                            AND T_STKHAND.CLIENT_CD     = MST_CLIENT.CLIENT_CD
                            AND TRIM(T_STKHAND.BAL_QTY) > 0
                            ORDER BY MST_CLIENT.CLIENT_CD
                          )
                          A, (
                            SELECT T_CLOSE_PRICE.STK_CD, T_CLOSE_PRICE.STK_BIDP
                            FROM T_CLOSE_PRICE, MST_COUNTER
                            WHERE T_CLOSE_PRICE.STK_DATE = P_PRICE_DATE
                            AND MST_COUNTER.STK_CD       = T_CLOSE_PRICE.STK_CD
                          )
                          B
                        WHERE A.STK_CD = B.STK_CD
                      )
                    GROUP BY CLIENT_CD
                  )
                  PORTFOLIO, (
                    SELECT CLIENT_CD, SUM(PORTFOLIO_DISCT) AS PORTFOLIO_DISCT
                    FROM
                      (
                        SELECT A.CLIENT_CD, A.STK_CD, A.BAL_QTY, B.STK_BIDP, (A.BAL_QTY * B.STK_BIDP * (B.MRG_STK_CAP / 100)) PORTFOLIO_DISCT
                        FROM
                          (
                            SELECT MST_CLIENT.CLIENT_CD AS CLIENT_CD, T_STKHAND.STK_CD AS STK_CD, T_STKHAND.BAL_QTY AS BAL_QTY
                            FROM MST_CLIENT, LST_TYPE3, T_STKHAND
                            WHERE MST_CLIENT.CLIENT_TYPE_1 <> 'H'
                            AND MST_CLIENT.CLIENT_TYPE_3    = LST_TYPE3.CL_TYPE3
                            AND LST_TYPE3.MARGIN_CD BETWEEN P_BGN_MARGIN AND P_END_MARGIN
                            AND NVL(MST_CLIENT.SETT_OFF_CD,'Y') = 'Y'
                            AND MST_CLIENT.CLIENT_CD BETWEEN P_BGN_CLIENT AND P_END_CLIENT
                            AND MST_CLIENT.REM_CD BETWEEN P_BGN_REM AND P_END_REM
                            AND TRIM(MST_CLIENT.BRANCH_CODE) BETWEEN P_BGN_BRANCH AND P_END_BRANCH
                            AND T_STKHAND.CLIENT_CD     = MST_CLIENT.CLIENT_CD
                            AND TRIM(T_STKHAND.BAL_QTY) > 0
                            ORDER BY MST_CLIENT.CLIENT_CD
                          )
                          A, (
                            SELECT T_CLOSE_PRICE.STK_CD, T_CLOSE_PRICE.STK_BIDP, MST_COUNTER.MRG_STK_CAP
                            FROM T_CLOSE_PRICE, MST_COUNTER
                            WHERE T_CLOSE_PRICE.STK_DATE = P_PRICE_DATE
                            AND MST_COUNTER.STK_CD       = T_CLOSE_PRICE.STK_CD
                          )
                          B
                        WHERE A.STK_CD = B.STK_CD
                      )
                    GROUP BY CLIENT_CD
                  )
                  PORTFOLIO_DISCT, MST_CLIENT, LST_TYPE3, MST_BRANCH, MST_SALES
                WHERE MST_CLIENT.CLIENT_CD    = BALANCE.CLIENT_CD
                AND MST_CLIENT.CLIENT_TYPE_1 <> 'H'
                AND MST_CLIENT.CLIENT_TYPE_3  = LST_TYPE3.CL_TYPE3
                AND LST_TYPE3.MARGIN_CD BETWEEN P_BGN_MARGIN AND P_END_MARGIN
                AND NVL(MST_CLIENT.SETT_OFF_CD,'Y') = 'Y'
                AND MST_CLIENT.CLIENT_CD BETWEEN P_BGN_CLIENT AND P_END_CLIENT
                AND TRIM(MST_CLIENT.BRANCH_CODE) BETWEEN P_BGN_BRANCH AND P_END_BRANCH
                AND MST_CLIENT.REM_CD BETWEEN P_BGN_REM AND P_END_REM
                AND TRIM(MST_BRANCH.BRCH_CD)     = TRIM(MST_CLIENT.BRANCH_CODE)
                AND MST_SALES.REM_CD             = MST_CLIENT.REM_CD
                AND PORTFOLIO.CLIENT_CD(+)       = BALANCE.CLIENT_CD
                AND BUYBACK.CLIENT_CD(+)         = BALANCE.CLIENT_CD
                AND PORTFOLIO_DISCT.CLIENT_CD(+) = BALANCE.CLIENT_CD
              )
              A, T_STKHAND B, T_CLOSE_PRICE C
            WHERE A.CLIENT_CD          =B.CLIENT_CD
            AND B.BAL_QTY             <>0
            AND (A.PORTFOLIO_PCTG     >= P_PCTG
            OR A.PORTFOLIO_DISCT_PCTG >= P_PCTG_DISC)
            AND C.STK_DATE             = P_PRICE_DATE
            AND C.STK_CD LIKE P_BGN_STOCK
            AND B.STK_CD=C.STK_CD
            ORDER BY B.STK_CD,A.CLIENT_CD
          )
          XX
      )
      Q1, (
        SELECT YY.STK_CD TOT_STK_CD, SUM(YY.QTY) TOT_QTY, SUM(YY.LOT) TOT_LOT, YY.PRICE TOT_PRICE, SUM(YY.STK_VAL) TOT_STK_VAL
        FROM
          (
            SELECT A.BRANCH_CD, A.BRANCH_NAME, A.REM_CD, A.REM_NAME, A.CLIENT_CD, A.CLIENT_NAME, A.BALANCE, A.BUYBACK, A.BALANCE_PLUS_BUYBACK, A.PORTFOLIO, A.PORTFOLIO_PCTG, A.PORTFOLIO_DISCT, A.PORTFOLIO_DISCT_PCTG, A.TRX_DATE, A.BAL_DATE, A.STK_DATE, B.STK_CD, B.BAL_QTY QTY, B.BAL_QTY/500 AS LOT, C.STK_BIDP AS PRICE, B.BAL_QTY * C.STK_BIDP AS STK_VAL
            FROM
              (
                SELECT TRIM(MST_CLIENT.BRANCH_CODE) BRANCH_CD, MST_BRANCH.BRCH_NAME BRANCH_NAME, MST_CLIENT.REM_CD REM_CD, MST_SALES.REM_NAME REM_NAME, BALANCE.CLIENT_CD CLIENT_CD, TRIM(MST_CLIENT.CLIENT_NAME) CLIENT_NAME, BALANCE.BALANCE BALANCE, NVL(ABS(BUYBACK.BUYBACK), 0) BUYBACK, BALANCE.BALANCE + NVL(ABS(BUYBACK.BUYBACK), 0) BALANCE_PLUS_BUYBACK, NVL(PORTFOLIO.PORTFOLIO, 0) PORTFOLIO, ROUND(DECODE(NVL(PORTFOLIO.PORTFOLIO, 0), 0, 0, (((BALANCE.BALANCE + NVL(ABS(BUYBACK.BUYBACK), 0)) / NVL(PORTFOLIO.PORTFOLIO, 0)) * 100))) AS PORTFOLIO_PCTG, NVL(PORTFOLIO_DISCT.PORTFOLIO_DISCT, 0) AS PORTFOLIO_DISCT, ROUND(DECODE(NVL(PORTFOLIO_DISCT.PORTFOLIO_DISCT, 0), 0, DECODE(BALANCE.BALANCE + NVL(ABS(BUYBACK.BUYBACK), 0),0,0,ABS(BALANCE.BALANCE) + NVL(ABS(BUYBACK.BUYBACK), 0),999,0), (((BALANCE.BALANCE + NVL(ABS(BUYBACK.BUYBACK), 0)) / NVL(PORTFOLIO_DISCT.PORTFOLIO_DISCT, 0)) * 100))) AS PORTFOLIO_DISCT_PCTG, P_TRX_DATE TRX_DATE, P_BAL_DATE BAL_DATE, TRUNC( P_PRICE_DATE) STK_DATE
                FROM
                  (
                    SELECT CLIENT_CD AS CLIENT_CD, SUM(DEB_TODT - CRE_TODT + DEB_OBAL - CRE_OBAL) AS BALANCE
                    FROM
                      (
                        SELECT MST_CLIENT.CLIENT_CD AS CLIENT_CD, NVL(ACT_BALANCE.DEB_TODT, 0) AS DEB_TODT, NVL(ACT_BALANCE.CRE_TODT, 0) AS CRE_TODT, NVL(ORG_BALANCE.DEB_OBAL, 0) AS DEB_OBAL, NVL(ORG_BALANCE.CRE_OBAL, 0) AS CRE_OBAL
                        FROM
                          (
                            SELECT MST_CLIENT.CLIENT_CD SL_ACCT_CD, SUM(DECODE(T_ACCOUNT_LEDGER.DB_CR_FLG, 'D', NVL(T_ACCOUNT_LEDGER.CURR_VAL, 0), 0)) DEB_TODT, SUM(DECODE(T_ACCOUNT_LEDGER.DB_CR_FLG, 'C', NVL(T_ACCOUNT_LEDGER.CURR_VAL, 0), 0)) CRE_TODT
                            FROM MST_CLIENT, LST_TYPE3, T_ACCOUNT_LEDGER
                            WHERE MST_CLIENT.CLIENT_TYPE_1 <> 'H'
                            AND MST_CLIENT.CLIENT_TYPE_3    = LST_TYPE3.CL_TYPE3
                            AND LST_TYPE3.MARGIN_CD BETWEEN P_BGN_MARGIN AND P_END_MARGIN
                            AND NVL(MST_CLIENT.SETT_OFF_CD,'Y') = 'Y'
                            AND MST_CLIENT.CLIENT_CD BETWEEN P_BGN_CLIENT AND P_END_CLIENT
                            AND MST_CLIENT.REM_CD BETWEEN P_BGN_REM AND P_END_REM
                            AND TRIM(MST_CLIENT.BRANCH_CODE) BETWEEN P_BGN_BRANCH AND P_END_BRANCH
                            AND T_ACCOUNT_LEDGER.SL_ACCT_CD     = MST_CLIENT.CLIENT_CD
                            AND T_ACCOUNT_LEDGER.DOC_DATE      >= P_BAL_DATE
                            AND T_ACCOUNT_LEDGER.DOC_DATE       < P_TRX_DATE
                            AND T_ACCOUNT_LEDGER.RECORD_SOURCE <> 'OBAL'
                            AND T_ACCOUNT_LEDGER.APPROVED_STS  = 'A'
                            GROUP BY MST_CLIENT.CLIENT_CD
                          )
                          ACT_BALANCE, (
                            SELECT MST_CLIENT.CLIENT_CD SL_ACCT_CD, SUM(NVL(T_DAY_TRS.DEB_OBAL, 0)) DEB_OBAL, SUM(NVL(T_DAY_TRS.CRE_OBAL, 0)) CRE_OBAL
                            FROM MST_CLIENT, LST_TYPE3, T_DAY_TRS
                            WHERE MST_CLIENT.CLIENT_TYPE_1 <> 'H'
                            AND MST_CLIENT.CLIENT_TYPE_3    = LST_TYPE3.CL_TYPE3
                            AND LST_TYPE3.MARGIN_CD BETWEEN P_BGN_MARGIN AND P_END_MARGIN
                            AND NVL(MST_CLIENT.SETT_OFF_CD,'Y') = 'Y'
                            AND MST_CLIENT.CLIENT_CD BETWEEN P_BGN_CLIENT AND P_END_CLIENT
                            AND MST_CLIENT.REM_CD BETWEEN P_BGN_REM AND P_END_REM
                            AND TRIM(MST_CLIENT.BRANCH_CODE) BETWEEN P_BGN_BRANCH AND P_END_BRANCH
                            AND T_DAY_TRS.SL_ACCT_CD = MST_CLIENT.CLIENT_CD
                            AND T_DAY_TRS.TRS_DT     = P_BAL_DATE
                            GROUP BY MST_CLIENT.CLIENT_CD
                          )
                          ORG_BALANCE, MST_CLIENT, LST_TYPE3
                        WHERE MST_CLIENT.CLIENT_TYPE_3 = LST_TYPE3.CL_TYPE3
                        AND LST_TYPE3.MARGIN_CD BETWEEN P_BGN_MARGIN AND P_END_MARGIN
                        AND NVL(MST_CLIENT.SETT_OFF_CD,'Y') = 'Y'
                        AND MST_CLIENT.CLIENT_CD BETWEEN P_BGN_CLIENT AND P_END_CLIENT
                        AND TRIM(MST_CLIENT.BRANCH_CODE) BETWEEN P_BGN_BRANCH AND P_END_BRANCH
                        AND MST_CLIENT.REM_CD BETWEEN P_BGN_REM AND P_END_REM
                        AND ACT_BALANCE.SL_ACCT_CD(+) = MST_CLIENT.CLIENT_CD
                        AND ORG_BALANCE.SL_ACCT_CD(+) = MST_CLIENT.CLIENT_CD
                        ORDER BY MST_CLIENT.CLIENT_CD
                      )
                    GROUP BY CLIENT_CD
                  )
                  BALANCE, (
                    SELECT CLIENT_CD, SUM(BUYBACK) AS BUYBACK
                    FROM
                      (
                        SELECT A.CLIENT_CD AS CLIENT_CD, A.STK_CD AS STK_CD, A.BAL_QTY AS BAL_QTY, B.STK_CLOS AS STK_CLOS, (A.BAL_QTY * B.STK_CLOS) AS BUYBACK
                        FROM
                          (
                            SELECT MST_CLIENT.CLIENT_CD AS CLIENT_CD, T_STKHAND.STK_CD AS STK_CD, T_STKHAND.BAL_QTY AS BAL_QTY
                            FROM MST_CLIENT, LST_TYPE3, T_STKHAND
                            WHERE MST_CLIENT.CLIENT_TYPE_1 <> 'H'
                            AND MST_CLIENT.CLIENT_TYPE_3    = LST_TYPE3.CL_TYPE3
                            AND LST_TYPE3.MARGIN_CD BETWEEN P_BGN_MARGIN AND P_END_MARGIN
                            AND NVL(MST_CLIENT.SETT_OFF_CD,'Y') = 'Y'
                            AND MST_CLIENT.CLIENT_CD BETWEEN P_BGN_CLIENT AND P_END_CLIENT
                            AND MST_CLIENT.REM_CD BETWEEN P_BGN_REM AND P_END_REM
                            AND TRIM(MST_CLIENT.BRANCH_CODE) BETWEEN P_BGN_BRANCH AND P_END_BRANCH
                            AND T_STKHAND.CLIENT_CD     = MST_CLIENT.CLIENT_CD
                            AND TRIM(T_STKHAND.BAL_QTY) < 0
                            ORDER BY MST_CLIENT.CLIENT_CD
                          )
                          A, (
                            SELECT T_CLOSE_PRICE.STK_CD, T_CLOSE_PRICE.STK_CLOS
                            FROM T_CLOSE_PRICE, MST_COUNTER
                            WHERE T_CLOSE_PRICE.STK_DATE = P_PRICE_DATE
                            AND MST_COUNTER.STK_CD       = T_CLOSE_PRICE.STK_CD
                          )
                          B
                        WHERE A.STK_CD = B.STK_CD
                      )
                    GROUP BY CLIENT_CD
                  )
                  BUYBACK, (
                    SELECT CLIENT_CD AS CLIENT_CD, SUM(PORTFOLIO) AS PORTFOLIO
                    FROM
                      (
                        SELECT A.CLIENT_CD, A.STK_CD, A.BAL_QTY, B.STK_BIDP, (A.BAL_QTY * B.STK_BIDP) AS PORTFOLIO
                        FROM
                          (
                            SELECT MST_CLIENT.CLIENT_CD AS CLIENT_CD, T_STKHAND.STK_CD AS STK_CD, T_STKHAND.BAL_QTY AS BAL_QTY
                            FROM MST_CLIENT, LST_TYPE3, T_STKHAND
                            WHERE MST_CLIENT.CLIENT_TYPE_1 <> 'H'
                            AND MST_CLIENT.CLIENT_TYPE_3    = LST_TYPE3.CL_TYPE3
                            AND LST_TYPE3.MARGIN_CD BETWEEN P_BGN_MARGIN AND P_END_MARGIN
                            AND NVL(MST_CLIENT.SETT_OFF_CD,'Y') = 'Y'
                            AND MST_CLIENT.CLIENT_CD BETWEEN P_BGN_CLIENT AND P_END_CLIENT
                            AND MST_CLIENT.REM_CD BETWEEN P_BGN_REM AND P_END_REM
                            AND TRIM(MST_CLIENT.BRANCH_CODE) BETWEEN P_BGN_BRANCH AND P_END_BRANCH
                            AND T_STKHAND.CLIENT_CD     = MST_CLIENT.CLIENT_CD
                            AND TRIM(T_STKHAND.BAL_QTY) > 0
                            ORDER BY MST_CLIENT.CLIENT_CD
                          )
                          A, (
                            SELECT T_CLOSE_PRICE.STK_CD, T_CLOSE_PRICE.STK_BIDP
                            FROM T_CLOSE_PRICE, MST_COUNTER
                            WHERE T_CLOSE_PRICE.STK_DATE = P_PRICE_DATE
                            AND MST_COUNTER.STK_CD       = T_CLOSE_PRICE.STK_CD
                          )
                          B
                        WHERE A.STK_CD = B.STK_CD
                      )
                    GROUP BY CLIENT_CD
                  )
                  PORTFOLIO, (
                    SELECT CLIENT_CD, SUM(PORTFOLIO_DISCT) AS PORTFOLIO_DISCT
                    FROM
                      (
                        SELECT A.CLIENT_CD, A.STK_CD, A.BAL_QTY, B.STK_BIDP, (A.BAL_QTY * B.STK_BIDP * (B.MRG_STK_CAP / 100)) PORTFOLIO_DISCT
                        FROM
                          (
                            SELECT MST_CLIENT.CLIENT_CD AS CLIENT_CD, T_STKHAND.STK_CD AS STK_CD, T_STKHAND.BAL_QTY AS BAL_QTY
                            FROM MST_CLIENT, LST_TYPE3, T_STKHAND
                            WHERE MST_CLIENT.CLIENT_TYPE_1 <> 'H'
                            AND MST_CLIENT.CLIENT_TYPE_3    = LST_TYPE3.CL_TYPE3
                            AND LST_TYPE3.MARGIN_CD BETWEEN P_BGN_MARGIN AND P_END_MARGIN
                            AND NVL(MST_CLIENT.SETT_OFF_CD,'Y') = 'Y'
                            AND MST_CLIENT.CLIENT_CD BETWEEN P_BGN_CLIENT AND P_END_CLIENT
                            AND MST_CLIENT.REM_CD BETWEEN P_BGN_REM AND P_END_REM
                            AND TRIM(MST_CLIENT.BRANCH_CODE) BETWEEN P_BGN_BRANCH AND P_END_BRANCH
                            AND T_STKHAND.CLIENT_CD     = MST_CLIENT.CLIENT_CD
                            AND TRIM(T_STKHAND.BAL_QTY) > 0
                            ORDER BY MST_CLIENT.CLIENT_CD
                          )
                          A, (
                            SELECT T_CLOSE_PRICE.STK_CD, T_CLOSE_PRICE.STK_BIDP, MST_COUNTER.MRG_STK_CAP
                            FROM T_CLOSE_PRICE, MST_COUNTER
                            WHERE T_CLOSE_PRICE.STK_DATE = P_PRICE_DATE
                            AND MST_COUNTER.STK_CD       = T_CLOSE_PRICE.STK_CD
                          )
                          B
                        WHERE A.STK_CD = B.STK_CD
                      )
                    GROUP BY CLIENT_CD
                  )
                  PORTFOLIO_DISCT, MST_CLIENT, LST_TYPE3, MST_BRANCH, MST_SALES
                WHERE MST_CLIENT.CLIENT_CD    = BALANCE.CLIENT_CD
                AND MST_CLIENT.CLIENT_TYPE_1 <> 'H'
                AND MST_CLIENT.CLIENT_TYPE_3  = LST_TYPE3.CL_TYPE3
                AND LST_TYPE3.MARGIN_CD BETWEEN P_BGN_MARGIN AND P_END_MARGIN
                AND NVL(MST_CLIENT.SETT_OFF_CD,'Y') = 'Y'
                AND MST_CLIENT.CLIENT_CD BETWEEN P_BGN_CLIENT AND P_END_CLIENT
                AND TRIM(MST_CLIENT.BRANCH_CODE) BETWEEN P_BGN_BRANCH AND P_END_BRANCH
                AND MST_CLIENT.REM_CD BETWEEN P_BGN_REM AND P_END_REM
                AND TRIM(MST_BRANCH.BRCH_CD)     = TRIM(MST_CLIENT.BRANCH_CODE)
                AND MST_SALES.REM_CD             = MST_CLIENT.REM_CD
                AND PORTFOLIO.CLIENT_CD(+)       = BALANCE.CLIENT_CD
                AND BUYBACK.CLIENT_CD(+)         = BALANCE.CLIENT_CD
                AND PORTFOLIO_DISCT.CLIENT_CD(+) = BALANCE.CLIENT_CD
              )
              A, T_STKHAND B, T_CLOSE_PRICE C
            WHERE A.CLIENT_CD          =B.CLIENT_CD
            AND B.BAL_QTY             <>0
            AND (A.PORTFOLIO_PCTG     >= P_PCTG
            OR A.PORTFOLIO_DISCT_PCTG >= P_PCTG_DISC)
            AND C.STK_DATE             = P_PRICE_DATE
            AND B.STK_CD               =C.STK_CD
            AND C.STK_CD LIKE P_BGN_STOCK
            ORDER BY B.STK_CD,A.CLIENT_CD
          )
          YY
        GROUP BY YY.STK_CD,YY.PRICE
      )
      Q2
    WHERE Q1.STK_CD=Q2.TOT_STK_CD
    ORDER BY Q2.TOT_STK_VAL DESC;
  EXCEPTION
  WHEN OTHERS THEN
    V_ERROR_CD  := -50;
    V_ERROR_MSG := SUBSTR('INSERT INTO R_LOAN_ASSET_STOCK_SUMMARY '||SQLERRM(SQLCODE),1,200);
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
END SPR_LOAN_ASSET_STOCK_SUMMARY;