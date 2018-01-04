CREATE OR REPLACE
PROCEDURE SPR_STOCK_TO_SETTLE(
    P_CONTR_DT_FROM DATE,
    P_CONTR_DT_TO   DATE,
    P_DUE_DT_FROM   DATE,
    P_DUE_DT_TO     DATE,
    P_BGN_STOCK     VARCHAR2,
    P_END_STOCK     VARCHAR2,
    P_USER_ID       VARCHAR2,
    P_GENERATE_DATE DATE,
    P_RANDOM_VALUE OUT NUMBER,
    P_ERROR_CD OUT NUMBER,
    P_ERROR_MSG OUT VARCHAR2 )
IS
  V_ERROR_MSG    VARCHAR2(200);
  V_ERROR_CD     NUMBER(10);
  v_random_value NUMBER(10);
  V_ERR          EXCEPTION;
BEGIN
  
  v_random_value := ABS(dbms_random.random);
  
  BEGIN
    SP_RPT_REMOVE_RAND('R_STOCK_TO_SETTLE',V_RANDOM_VALUE,V_ERROR_MSG,V_ERROR_CD);
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
  
  BEGIN
    INSERT
    INTO R_STOCK_TO_SETTLE
      (
        STK_CD ,
        STK_DESC ,
        MARKET_TYPE ,
        BS_BROKER_CD ,
        BUY ,
        SELL ,
        DISCREPANCY ,
        USER_ID ,
        RAND_VALUE ,
        GENERATE_DATE,
        CONTR_DT_FROM,
        CONTR_DT_TO
      )
    SELECT STK_CD      AS STK_CD,
      STK_DESC         AS STK_DESC,
      MARKET_TYPE      AS MARKET_TYPE,
      BS_BROKER_CD     AS BS_BROKER_CD,
      SUM(BUY)         AS BUY,
      SUM(SELL)        AS SELL,
      SUM(DISCREPANCY) AS DISCREPANCY,
      P_USER_ID,
      V_RANDOM_VALUE,
      P_GENERATE_DATE,
      p_contr_dt_from,
      P_CONTR_DT_TO
    FROM
      (SELECT T_CONTRACTS.STK_CD    AS STK_CD,
        MST_COUNTER.STK_DESC        AS STK_DESC,
        TRIM(T_CONTRACTS.MRKT_TYPE) AS MARKET_TYPE,
        DECODE(T_CONTRACTS.MRKT_TYPE, 'NG', TRIM(T_CONTRACTS.BUY_BROKER_CD)
        || '/'
        || TRIM(T_CONTRACTS.SELL_BROKER_CD), TO_CHAR(NULL))                                                                                         AS BS_BROKER_CD,
        DECODE(SUBSTR(T_CONTRACTS.CONTR_NUM, 5, 1), 'B', T_CONTRACTS.QTY, 0)                                                                        AS BUY,
        DECODE(SUBSTR(T_CONTRACTS.CONTR_NUM, 5, 1), 'J', T_CONTRACTS.QTY, 0)                                                                        AS SELL,
        DECODE(SUBSTR(T_CONTRACTS.CONTR_NUM, 5, 1), 'B', T_CONTRACTS.QTY, 0) - DECODE(SUBSTR(T_CONTRACTS.CONTR_NUM, 5, 1), 'J', T_CONTRACTS.QTY, 0) AS DISCREPANCY
      FROM INSISTPRO.T_CONTRACTS T_CONTRACTS,
        INSISTPRO.MST_COUNTER MST_COUNTER
      WHERE T_CONTRACTS.CONTR_STAT <> 'C'
      AND T_CONTRACTS.CONTR_DT BETWEEN P_CONTR_DT_FROM AND P_CONTR_DT_TO
      AND (TRIM(T_CONTRACTS.STK_CD) BETWEEN TRIM(P_BGN_STOCK) AND TRIM(P_END_STOCK))
      AND T_CONTRACTS.DUE_DT_FOR_CERT BETWEEN P_DUE_DT_FROM AND P_DUE_DT_TO
      AND TRIM(MST_COUNTER.STK_CD) = TRIM(T_CONTRACTS.STK_CD)
      ORDER BY T_CONTRACTS.STK_CD ASC
      )
    GROUP BY STK_CD,
      STK_DESC,
      MARKET_TYPE,
      BS_BROKER_CD
    ORDER BY STK_CD ASC,
      STK_DESC ASC,
      MARKET_TYPE ASC,
      BS_BROKER_CD ASC;
  EXCEPTION
  WHEN OTHERS THEN
    V_ERROR_CD  := -30;
    V_ERROR_MSG := SUBSTR('INSERT R_STOCK_TO_SETTLE '||V_ERROR_MSG||SQLERRM(SQLCODE),1,200);
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
END SPR_STOCK_TO_SETTLE;