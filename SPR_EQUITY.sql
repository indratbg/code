create or replace PROCEDURE SPR_EQUITY(
    P_AS_PER_DATE   DATE,
    P_PRICE_DATE DATE,
    P_BGN_ACCT_TYPE VARCHAR2,
    P_END_ACCT_TYPE VARCHAR2,
    P_LIMIT         NUMBER,
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
  V_BGN_DATE     DATE;
  V_PRICE_DATE   DATE:=P_PRICE_DATE;
BEGIN
  V_RANDOM_VALUE := ABS(DBMS_RANDOM.RANDOM);
  BEGIN
    SP_RPT_REMOVE_RAND('R_EQUITY',V_RANDOM_VALUE,V_ERROR_MSG,V_ERROR_CD);
  EXCEPTION
  WHEN OTHERS THEN
    V_ERROR_CD  := -10;
    V_ERROR_MSG := SUBSTR('SP_RPT_REMOVE_RAND '||V_ERROR_MSG||SQLERRM(SQLCODE),1,200);
    RAISE V_err;
  END;
  
  V_BGN_DATE := TO_DATE('01'||TO_CHAR(P_AS_PER_DATE,'MMYYYY'),'DDMMYYYY');
  
  BEGIN
    INSERT
    INTO R_EQUITY
      (
        BRANCH_CODE ,REM_CD ,CLIENT_CD ,CLIENT_NAME ,BALANCE ,BUYBACK ,BALANCE_PLUS_BUYBACK ,PORTFOLIO ,PORTFOLIO_PCTG ,
        PORTFOLIO_DISCT ,EQUITY ,PORTFOLIO_DISCT_PCTG ,PRICE_DATE,USER_ID ,RAND_VALUE ,GENERATE_DATE
      )
    SELECT BRANCH_CODE, REM_CD, CLIENT_CD, CLIENT_NAME, BALANCE, BUYBACK, BALANCE_PLUS_BUYBACK, PORTFOLIO, PORTFOLIO_PCTG, 
    PORTFOLIO_DISCT, EQUITY, PORTFOLIO_DISCT_PCTG,V_PRICE_DATE, P_USER_ID, V_RANDOM_VALUE, P_GENERATE_DATE
    FROM
      (
        SELECT BRANCH_CODE, REM_CD, CLIENT_CD, CLIENT_NAME, BALANCE, BUYBACK, BALANCE_PLUS_BUYBACK, PORTFOLIO, PORTFOLIO_PCTG, 
        PORTFOLIO_DISCT, BALANCE_PLUS_BUYBACK - PORTFOLIO_DISCT AS EQUITY,
        ROUND(DECODE(PORTFOLIO_DISCT, 0, DECODE(BALANCE_PLUS_BUYBACK,0,0,ABS(BALANCE) + BUYBACK,999,0), BALANCE_PLUS_BUYBACK / PORTFOLIO_DISCT * 100)) AS PORTFOLIO_DISCT_PCTG
        FROM
          (
            SELECT MC.BRANCH_CODE AS BRANCH_CODE, MC.REM_CD AS REM_CD, MC.CLIENT_CD AS CLIENT_CD, MC.CLIENT_NAME AS CLIENT_NAME, 
            BALANCE.BALANCE AS BALANCE, NVL(SAHAM.BUYBACK, 0) AS BUYBACK, 
            NVL(BALANCE.BALANCE,0) + NVL(SAHAM.BUYBACK, 0) AS BALANCE_PLUS_BUYBACK, NVL(SAHAM.PORTFOLIO, 0) AS PORTFOLIO, 
            ROUND(DECODE(NVL(SAHAM.PORTFOLIO, 0), 0, 0, (((BALANCE.BALANCE + NVL(SAHAM.BUYBACK, 0)) / NVL(SAHAM.PORTFOLIO, 0)) * 100))) AS PORTFOLIO_PCTG, 
            NVL(SAHAM.PORTFOLIO_DISCT, 0) AS PORTFOLIO_DISCT
            FROM
              (
                SELECT SL_ACCT_CD AS CLIENT_CD, SUM(BEG_BAL + MVMT) AS BALANCE
                FROM
                  (
                    SELECT TRIM(T.SL_ACCT_CD) AS SL_ACCT_CD, 0 BEG_BAL, DECODE(DB_CR_FLG, 'D', 1,-1) * T.CURR_VAL AS MVMT
                    FROM T_ACCOUNT_LEDGER T, MST_CLIENT M
                    WHERE T.DOC_DATE BETWEEN V_BGN_DATE AND P_AS_PER_DATE
                    AND T.SL_ACCT_CD     = M.CLIENT_CD
                    AND m.CLIENT_CD BETWEEN P_BGN_CLIENT AND P_END_CLIENT
                    AND TRIM(m.BRANCH_CODE) BETWEEN P_BGN_BRANCH AND P_END_BRANCH
                    AND m.REM_CD BETWEEN P_BGN_REM AND P_END_REM
                    AND M.SUSP_STAT = 'N'
                    AND T.RECORD_SOURCE <> 'OBAL'
                    AND T.APPROVED_STS  <> 'C'
                    AND T.APPROVED_STS  <> 'E'
                    UNION ALL
                    SELECT TRIM(T.SL_ACCT_CD) AS SL_ACCT_CD, T.DEB_OBAL - T.CRE_OBAL AS BEG_BAL, 0 MVMT
                    FROM T_DAY_TRS T, MST_CLIENT M
                    WHERE T.TRS_DT   = V_BGN_DATE
                    AND m.CLIENT_CD BETWEEN P_BGN_CLIENT AND P_END_CLIENT
                    AND TRIM(m.BRANCH_CODE) BETWEEN P_BGN_BRANCH AND P_END_BRANCH
                    AND m.REM_CD BETWEEN P_BGN_REM AND P_END_REM
                    AND M.SUSP_STAT = 'N'
                    AND T.SL_ACCT_CD = M.CLIENT_CD
                    UNION ALL
                    SELECT CLIENT_CD, 0 BEG_BAL, -NVL(F_FUND_BAL(MST_CLIENT.CLIENT_CD, P_AS_PER_DATE),0) MVMT
                    FROM MST_CLIENT
                    WHERE SUSP_STAT = 'N'
                    AND CLIENT_CD BETWEEN P_BGN_CLIENT AND P_END_CLIENT
                    AND TRIM(BRANCH_CODE) BETWEEN P_BGN_BRANCH AND P_END_BRANCH
                    AND REM_CD BETWEEN P_BGN_REM AND P_END_REM
                    AND SUSP_STAT = 'N'
                  )
                GROUP BY SL_ACCT_CD
              )
              BALANCE, (
                SELECT CLIENT_CD, SUM(STK_VAL) AS STK_VAL, DECODE(SIGN(SUM(STK_VAL)),1,0,0,0,-1 * SUM(STK_VAL)) AS BUYBACK, 
                DECODE(SIGN(SUM(STK_VAL)),1, SUM(STK_VAL),0) AS PORTFOLIO, DECODE(SIGN(SUM(DISCT_VAL)),1, SUM(DISCT_VAL),0) AS PORTFOLIO_DISCT
                FROM
                  (
                    SELECT B.CLIENT_CD, B.STK_CD, NVL(B.THEO_QTY,0) THEO_QTY, NVL(P.PRICE,0) PRICE, NVL(B.THEO_QTY,0) * NVL(P.PRICE,0) STK_VAL,
                    NVL(B.THEO_QTY,0) * NVL(P.PRICE,0) * NVL(DECODE(C.MARGIN_CD,'M',P.MRG_STK_CAP,P.REG_STK_CAP ), 0) / 100 DISCT_VAL
                    FROM
                      (
                        SELECT CLIENT_CD, STK_CD, SUM(BEG_THEO + THEO_MVMT) THEO_QTY, COUNT(1) CNT
                        FROM
                          (
                            SELECT CLIENT_CD, STK_CD, 0 BEG_THEO, (NVL(DECODE(SUBSTR(DOC_NUM,5,2),'BR',1,'JR',1,'BI',1,'JI',1,'RS',1,'WS',1,0) * DECODE(DB_CR_FLG,'D',1,-1) * (TOTAL_SHARE_QTY + WITHDRAWN_SHARE_QTY),0)) THEO_MVMT
                            FROM T_STK_MOVEMENT
                            WHERE DOC_DT BETWEEN V_BGN_DATE AND P_AS_PER_DATE
                            AND CLIENT_CD BETWEEN P_BGN_CLIENT AND P_END_CLIENT
                            AND GL_ACCT_CD IN ('10','12','13','14','51')
                            AND DOC_STAT    = '2'
                            AND S_D_TYPE   <> 'V'
                            UNION ALL
                            SELECT CLIENT_CD, STK_CD, BEG_BAL_QTY, 0 THEO_MVMT
                            FROM T_STKBAL
                            WHERE BAL_DT = V_BGN_DATE
                            AND CLIENT_CD BETWEEN P_BGN_CLIENT AND P_END_CLIENT
                          )
                        GROUP BY CLIENT_CD, STK_CD
                      )
                      B, (
                        SELECT M.CLIENT_CD, L.MARGIN_CD
                        FROM MST_CLIENT M, LST_TYPE3 L
                        WHERE M.CLIENT_CD BETWEEN P_BGN_CLIENT AND P_END_CLIENT
                        AND M.CLIENT_TYPE_3 = L.CL_TYPE3
                        AND L.MARGIN_CD BETWEEN P_BGN_ACCT_TYPE AND P_END_ACCT_TYPE
                        AND TRIM(m.BRANCH_CODE) BETWEEN P_BGN_BRANCH AND P_END_BRANCH
                        AND m.REM_CD BETWEEN P_BGN_REM AND P_END_REM
                        AND M.SUSP_STAT = 'N'
                      )
                      C, (
                        SELECT T_CLOSE_PRICE.STK_CD, T_CLOSE_PRICE.STK_BIDP AS PRICE, 
                        DECODE(SIGN(V_PRICE_DATE - TO_DATE('01/01/09','dd/mm/yy')), 1, V_MARGIN_STK.MRG_STK_CAP, V_MARGIN_STK.REG_STK_CAP) AS MRG_STK_CAP, 
                        V_MARGIN_STK.REG_STK_CAP, V_MARGIN_STK.TPL_STK_CAP
                        FROM T_CLOSE_PRICE, V_MARGIN_STK
                        WHERE T_CLOSE_PRICE.STK_DATE = V_PRICE_DATE
                        AND V_MARGIN_STK.STK_CD      = T_CLOSE_PRICE.STK_CD
                      )
                      P
                    WHERE B.CLIENT_CD = C.CLIENT_CD
                    AND B.STK_CD      = P.STK_CD (+)
                    AND THEO_QTY     <> 0
                  )
                GROUP BY CLIENT_CD
              )
              SAHAM, (
                SELECT CLIENT_CD, BRANCH_CODE,REM_CD, CLIENT_NAME
                FROM MST_CLIENT, LST_TYPE3
                WHERE MST_CLIENT.CLIENT_TYPE_3 = LST_TYPE3.CL_TYPE3
                AND LST_TYPE3.MARGIN_CD BETWEEN P_BGN_ACCT_TYPE AND P_END_ACCT_TYPE
                AND MST_CLIENT.SUSP_STAT = 'N'
                AND MST_CLIENT.CLIENT_CD BETWEEN P_BGN_CLIENT AND P_END_CLIENT
                AND TRIM(MST_CLIENT.BRANCH_CODE) BETWEEN P_BGN_BRANCH AND P_END_BRANCH
                AND MST_CLIENT.REM_CD BETWEEN P_BGN_REM AND P_END_REM
              )
              MC
            WHERE MC.CLIENT_CD           = BALANCE.CLIENT_CD(+)
            AND MC.CLIENT_CD             = SAHAM.CLIENT_CD (+)
            AND (NVL(BALANCE.BALANCE,0) <> 0
            OR NVL(SAHAM.PORTFOLIO,0)   <> 0)
          )
      )
    WHERE (EQUITY >= (-1 *P_LIMIT)
    OR P_LIMIT     = 0 );
  EXCEPTION
  WHEN OTHERS THEN
    V_ERROR_CD  := -50;
    V_ERROR_MSG := SUBSTR('INSERT INTO R_EQUITY '||SQLERRM(SQLCODE),1,200);
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
END SPR_EQUITY;