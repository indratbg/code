CREATE OR REPLACE
PROCEDURE SPR_STOCK_TO_SETTLE_DETAIL(
    P_CONTR_DT_FROM DATE,
    P_CONTR_DT_TO   DATE,
    P_DUE_DT_FROM   DATE,
    P_DUE_DT_TO     DATE,
    P_BGN_STOCK     VARCHAR2,
    P_END_STOCK     VARCHAR2,
    P_BGN_CLIENT    VARCHAR2,
    P_END_CLIENT    VARCHAR2,
    P_MARKET_TYPE   VARCHAR2,
    P_STOCK_TYPE    VARCHAR2,
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
    SP_RPT_REMOVE_RAND('R_STOCK_TO_SETTLE_DETAIL',V_RANDOM_VALUE,V_ERROR_MSG,V_ERROR_CD);
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
    INTO R_STOCK_TO_SETTLE_DETAIL
      (
        CONTR_DT_FROM ,
        CONTR_DT_TO ,
        DUE_DT_FROM ,
        DUE_DT_TO ,
        STK_CD ,
        STK_DESC ,
        CLIENT_CD ,
        CLIENT_NAME ,
        SUB_REK ,
        CUSTODIAN ,
        MARKET_TYPE ,
        BS_BROKER_CD ,
        BUY ,
        SELL ,
        DISCREPANCY ,
        USER_ID ,
        RAND_VALUE ,
        GENERATE_DATE
      )
    SELECT P_CONTR_DT_FROM,
      P_CONTR_DT_TO,
      P_DUE_DT_FROM,
      P_DUE_DT_TO,
      STK_CD      AS STK_CD,
      STK_DESC    AS STK_DESC,
      CLIENT_CD   AS CLIENT_CD,
      CLIENT_NAME AS CLIENT_NAME,
      sub_rek,
      Custodian,
      MARKET_TYPE      AS MARKET_TYPE,
      BS_BROKER_CD     AS BS_BROKER_CD,
      SUM(BUY)         AS BUY,
      SUM(SELL)        AS SELL,
      SUM(DISCREPANCY) AS DISCREPANCY ,
      P_USER_ID,
      V_RANDOM_VALUE,
      P_GENERATE_DATE
    FROM
      (SELECT t_contracts.STK_CD    AS STK_CD,
        mst_counter.STK_DESC        AS STK_DESC,
        t_contracts.CLIENT_CD       AS CLIENT_CD,
        mst_client.CLIENT_NAME      AS CLIENT_NAME,
        v_client_subrek14.subrek14  AS SUB_REK,
        mst_client.custodian_cd     AS Custodian,
        TRIM(t_contracts.MRKT_TYPE) AS MARKET_TYPE,
        DECODE(t_contracts.MRKT_TYPE, 'NG', TRIM(t_contracts.BUY_BROKER_CD)
        || '/'
        || TRIM(t_contracts.SELL_BROKER_CD), TO_CHAR(NULL))                                                                                         AS BS_BROKER_CD,
        DECODE(SUBSTR(t_contracts.CONTR_NUM, 5, 1), 'B', t_contracts.QTY, 0)                                                                        AS BUY,
        DECODE(SUBSTR(t_contracts.CONTR_NUM, 5, 1), 'J', t_contracts.QTY, 0)                                                                        AS SELL,
        DECODE(SUBSTR(t_contracts.CONTR_NUM, 5, 1), 'B', t_contracts.QTY, 0) - DECODE(SUBSTR(t_contracts.CONTR_NUM, 5, 1), 'J', t_contracts.QTY, 0) AS DISCREPANCY
      FROM t_contracts,
        mst_counter,
        mst_client,
        v_client_subrek14
      WHERE t_contracts.CONTR_STAT <> 'C'
      AND t_contracts.CONTR_DT BETWEEN P_CONTR_DT_FROM AND P_CONTR_DT_TO
      AND t_contracts.STK_CD BETWEEN P_BGN_STOCK AND P_END_STOCK
      AND t_contracts.DUE_DT_FOR_CERT BETWEEN P_DUE_DT_FROM AND P_DUE_DT_TO
      AND t_contracts.CLIENT_CD BETWEEN P_BGN_CLIENT AND P_END_CLIENT
      AND mst_counter.STK_CD         = t_contracts.STK_CD
      AND mst_client.CLIENT_CD       = t_contracts.CLIENT_CD
      AND t_contracts.CLIENT_CD      = v_client_subrek14.client_cd(+)
      AND (t_contracts.mrkt_type     = P_MARKET_TYPE
      OR P_MARKET_TYPE               = 'ALL')
      AND ((mst_client.custodian_cd IS NOT NULL
      AND P_STOCK_TYPE               = 'CUSTODY')
      OR P_STOCK_TYPE                = 'ALL')
      ORDER BY t_contracts.STK_CD ASC,
        t_contracts.CLIENT_CD ASC
      )
    GROUP BY STK_CD,
      STK_DESC,
      CLIENT_CD,
      CLIENT_NAME,
      SUB_REK,
      custodian,
      MARKET_TYPE,
      BS_BROKER_CD
    ORDER BY STK_CD ASC,
      STK_DESC ASC,
      CLIENT_CD ASC,
      CLIENT_NAME ASC,
      MARKET_TYPE ASC,
      BS_BROKER_CD ASC ;
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
END SPR_STOCK_TO_SETTLE_DETAIL;