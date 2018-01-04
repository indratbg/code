create or replace 
PROCEDURE SPR_CLIENT_ACTIVITY_PF(
    P_BGN_DATE DATE,
    P_END_DATE DATE,
    P_BGN_BRANCH T_CONTRACTS.BRCH_CD%TYPE,
    P_END_BRANCH T_CONTRACTS.BRCH_CD%TYPE,
    P_BGN_STOCK     VARCHAR2,
    P_END_STOCK     VARCHAR2,
    P_BGN_CLIENT    VARCHAR2,
    P_END_CLIENT    VARCHAR2,
    P_BGN_REM       VARCHAR2,
    P_END_REM       VARCHAR2,
    P_CUSTODY       VARCHAR2,
    P_STA           VARCHAR2,
    P_STA_TYPE      VARCHAR2,
    P_MRKT_TYPE     VARCHAR2,
    P_BGN_MRKT_TYPE VARCHAR2,
    P_END_MRKT_TYPE VARCHAR2,
    P_BGN_DAYS      NUMBER,
    P_END_DAYS      NUMBER,
    P_PRICE         NUMBER,
    P_CLIENT_TYPE3  VARCHAR2,
    P_GROUP_BY      VARCHAR2,
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

  V_RANDOM_VALUE := ABS(DBMS_RANDOM.RANDOM);
  
  BEGIN
    SP_RPT_REMOVE_RAND('R_CLIENT_ACTIVITY',V_RANDOM_VALUE,V_ERROR_MSG,V_ERROR_CD);
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
    INTO R_CLIENT_ACTIVITY
      (
        FROM_DATE,
        TO_DATE,
        CLIENT_CD ,
        CLIENT_NAME ,
        REM_CD ,
        REM_NAME ,
        CONTR_NUM ,
        BJ ,
        CONTR_DT ,
        DUE_DT_FOR_AMT ,
        STK_CD ,
        PRICE ,
        QTY ,
        LOT_SIZE ,
        NET ,
        COMMISSION ,
        VAT ,
        TRANS_LEVY ,
        PPH ,
        BROK ,
        BROK_PERC ,
        BRCH_CD ,
        MRKT_TYPE ,
        AMT ,
        CUSTODIAN ,
        USER_ID ,
        RAND_VALUE ,
        GENERATE_DATE,
        CUSTODY_FLG,
        GROUP_BY,
        BROK_CD,
        BROK_NAME,
        OLD_IC_NUM
      )
    SELECT P_BGN_DATE,
      P_END_DATE,
      CLIENT_CD,
      CLIENT_NAME,
      REM_CD,
      REM_NAME,
      CONTR_NUM ,
      BJ ,
      CONTR_DT ,
      DUE_DT_FOR_AMT ,
      STK_CD ,
      PRICE ,
      QTY ,
      LOT_SIZE ,
      NET ,
      COMM ,
      VAT ,
      TRANS_LEVY ,
      PPH ,
      TOT_FEE ,
      BROK_PERSEN ,
      BRCH_CD ,
      MRKT_TYPE ,
      AMT ,
      NULL CUSTODIAN ,
      P_USER_ID ,
      V_RANDOM_VALUE,
      P_GENERATE_DATE,
      P_CUSTODY,
      P_GROUP_BY,
      BROKER_CD,
      BROKER_NAME,
      OLD_IC_NUM
    FROM
      (SELECT "MST_CLIENT".CLIENT_CD,
        MST_CLIENT.CLIENT_NAME,
        "MST_SALES".REM_CD,
        "MST_SALES".REM_NAME,
        T_CONTRACTS."CONTR_NUM",
        "T_CONTRACTS"."BJ",
        "T_CONTRACTS"."MRKT_TYPE",
        "T_CONTRACTS".CONTR_DT,
        T_CONTRACTS."DUE_DT_FOR_AMT",
        "T_CONTRACTS".STK_CD,
        "T_CONTRACTS".PRICE,
        "T_CONTRACTS"."QTY",
        T_CONTRACTS."LOT_SIZE",
        T_CONTRACTS."NET",
        T_CONTRACTS."COMM",
        T_CONTRACTS."VAT",
        T_CONTRACTS."TRANS_LEVY",
        T_CONTRACTS."PPH",
        T_CONTRACTS."TOT_FEE",
        T_CONTRACTS."BROK_PERSEN",
        T_CONTRACTS."BRCH_CD",
        DECODE("T_CONTRACTS"."BJ",'B',1,-1) * "T_CONTRACTS"."AMT_FOR_CURR" AS AMT,
        "T_CONTRACTS"."BROKER_CD",
        MST_CLIENT."OLD_IC_NUM",
        B.BROKER_NAME
      FROM
        (SELECT "T_CONTRACTS"."CLIENT_CD",
          "T_CONTRACTS"."REM_CD",
          T_CONTRACTS."CONTR_NUM",
          SUBSTR("T_CONTRACTS"."CONTR_NUM",5,1) BJ,
          "T_CONTRACTS"."MRKT_TYPE",
          "T_CONTRACTS"."CONTR_DT",
          T_CONTRACTS."DUE_DT_FOR_AMT",
          "T_CONTRACTS"."KPEI_DUE_DT",
          "T_CONTRACTS"."STK_CD",
          "T_CONTRACTS"."PRICE",
          "T_CONTRACTS"."QTY",
          T_CONTRACTS."LOT_SIZE",
          T_CONTRACTS."NET",
          DECODE(COMMISSION,0,0, COMMISSION - TRANS_LEVY) COMM,
          T_CONTRACTS."VAT",
          "T_CONTRACTS"."TRANS_LEVY",
          T_CONTRACTS."PPH",
          T_CONTRACTS."BROK"            AS "TOT_FEE",
          T_CONTRACTS."BROK_PERC" / 100 AS BROK_PERSEN,
          T_CONTRACTS."BRCH_CD",
          "T_CONTRACTS"."AMT_FOR_CURR",
          NVL(TRIM(DECODE(SUBSTR("T_CONTRACTS"."CONTR_NUM",5,1),'B',"T_CONTRACTS"."SELL_BROKER_CD","T_CONTRACTS"."BUY_BROKER_CD")),'@@') BROKER_CD,
          "T_CONTRACTS"."SCRIP_DAYS_C" AS KPEI_DUE_DAYS
        FROM T_CONTRACTS
        WHERE ( (SUBSTR(CONTR_NUM,6,1) = 'R')
        OR (SUBSTR(CONTR_NUM,6,1)      = 'I') )
        AND ( CONTR_DT                >= P_BGN_DATE )
        AND ( CONTR_DT                <= P_END_DATE )
        AND ( CLIENT_CD               >= P_BGN_CLIENT )
        AND ( CLIENT_CD               <= P_END_CLIENT )
        AND ( TRIM(REM_CD)            >= P_BGN_REM )
        AND ( TRIM(REM_CD)            <= P_END_REM )
        AND ( STK_CD                  >= P_BGN_STOCK )
        AND ( STK_CD                  <= P_END_STOCK )
        AND (("T_CONTRACTS"."PRICE"    = P_PRICE)--25APR2016
        OR (P_PRICE                    = 0) )
          --AND ( PRICE                   >= :S_BGN_PRICE )
          --AND ( PRICE                   <= :S_END_PRICE )
        AND ( BRCH_CD >= P_BGN_BRANCH )
        AND ( BRCH_CD <= P_END_BRANCH )
        AND ( SUBSTR((CONTR_NUM),5,1) LIKE P_STA )
        AND ( SUBSTR((CONTR_NUM),6,1) LIKE P_STA_TYPE )
        AND MRKT_TYPE LIKE P_BGN_MRKT_TYPE
        AND SCRIP_DAYS_C BETWEEN P_BGN_DAYS AND P_END_DAYS
        AND CONTR_STAT <> 'C'
        ) "T_CONTRACTS",
        "MST_CLIENT",
        "MST_SALES",
        (SELECT TRIM(CLIENT_NAME_ABBR) AS BROKER_CD,
          CLIENT_NAME                  AS BROKER_NAME
        FROM MST_CLIENT
        WHERE LENGTH(CLIENT_NAME_ABBR) = 2
        ) B
      WHERE ( "T_CONTRACTS"."CLIENT_CD"  = "MST_CLIENT"."CLIENT_CD" )
      AND ( TRIM("T_CONTRACTS"."REM_CD") = TRIM("MST_SALES"."REM_CD") )
      AND "T_CONTRACTS"."BROKER_CD"      = B.BROKER_CD (+)
      AND P_CUSTODY <> 'Y'
      UNION
      SELECT "T_MIN_FEE"."CLIENT_CD",
        NULL,
        "MST_CLIENT"."REM_CD",
        NULL REM_NAME,
        'Min Fee',
        NULL BJ,
        NULL MRKT_TYPE,
        T_MIN_FEE."CONTR_DT",
        TO_DATE(NULL),
        '_Fee',
        0,
        0,
        0,
        0,
        T_MIN_FEE."COMMISSION",
        T_MIN_FEE."VAT",
        0,
        0,
        T_MIN_FEE."MF_AMT",
        0,
        MST_CLIENT."BRANCH_CODE",
        T_MIN_FEE."MF_AMT",
        NULL BROKER_CD,
        "MST_CLIENT"."OLD_IC_NUM",
        NULL BROKER_NAME
      FROM "T_MIN_FEE",
        "MST_CLIENT"
      WHERE "T_MIN_FEE"."CONTR_DT" BETWEEN P_BGN_DATE AND P_END_DATE
      AND "T_MIN_FEE"."CLIENT_CD" BETWEEN P_BGN_CLIENT AND P_END_CLIENT
      AND "T_MIN_FEE"."CLIENT_CD" = "MST_CLIENT"."CLIENT_CD"
      AND "MST_CLIENT"."BRANCH_CODE" BETWEEN P_BGN_BRANCH AND P_END_BRANCH
      AND "MST_CLIENT"."REM_CD" BETWEEN P_BGN_REM AND P_END_REM
      AND SUBSTR(P_BGN_STOCK,1,1) = '%'
      AND P_STA                   = '%'
      AND P_STA_TYPE              = '%'
      AND P_MRKT_TYPE             = '%'
      AND P_BGN_DAYS             <> P_END_DAYS
        --AND :S_BGN_PRICE          <> :S_END_PRICE
      AND P_CUSTODY <> 'Y'
      );
  EXCEPTION
  WHEN OTHERS THEN
    V_ERROR_CD  := -40;
    V_ERROR_MSG := SUBSTR('INSERT R_CLIENT_ACTIVITY UNTUK PF'||V_ERROR_MSG||SQLERRM(SQLCODE),1,200);
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
END SPR_CLIENT_ACTIVITY_PF;