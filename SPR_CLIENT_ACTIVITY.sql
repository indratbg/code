create or replace PROCEDURE SPR_CLIENT_ACTIVITY(
    P_BGN_DATE      DATE,
    P_END_DATE      DATE,
    P_BGN_BRANCH    T_CONTRACTS.BRCH_CD%TYPE,
    P_END_BRANCH    T_CONTRACTS.BRCH_CD%TYPE,
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
    P_GROUP_BY VARCHAR2,
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
        BROK_NAME
      )
    SELECT P_BGN_DATE,
      P_END_DATE,
      MST_CLIENT.CLIENT_CD,
      MST_CLIENT.CLIENT_NAME,
      T_CONTRACTS.REM_CD,
      MST_SALES.REM_NAME,
      T_CONTRACTS.CONTR_NUM,
      T_CONTRACTS.BJ,
      T_CONTRACTS.CONTR_DT,
      T_CONTRACTS.DUE_DT_FOR_AMT,
      T_CONTRACTS.STK_CD,
      T_CONTRACTS.PRICE,
      T_CONTRACTS.QTY,
      T_CONTRACTS.LOT_SIZE,
      T_CONTRACTS.NET,
      T_CONTRACTS.COMMISSION,
      T_CONTRACTS.VAT,
      T_CONTRACTS.TRANS_LEVY,
      T_CONTRACTS.PPH,
      T_CONTRACTS.BROK,
      T_CONTRACTS.BROK_PERC/100 BROK_PERC,
      T_CONTRACTS.BRCH_CD,
      T_CONTRACTS.MRKT_TYPE,
      T_CONTRACTS.AMT,
      p.CUSTODY_NAME AS custodian ,
      P_USER_ID,
      V_RANDOM_VALUE,
      P_GENERATE_DATE,
      P_CUSTODY,
      P_GROUP_BY,
      BROK_CD,--22APR2016
      BROKER_NAME--22APR2016
    FROM
      (SELECT T_CONTRACTS.CONTR_NUM,
        T_CONTRACTS.CLIENT_CD,
        T_CONTRACTS.MAIN_REM_CD AS REM_CD,
        SUBSTR(T_CONTRACTS.CONTR_NUM,5,1) BJ,
        T_CONTRACTS.CONTR_DT,
        T_CONTRACTS.DUE_DT_FOR_AMT,
        T_CONTRACTS.STK_CD,
        T_CONTRACTS.PRICE,
        T_CONTRACTS.QTY,
        T_CONTRACTS.LOT_SIZE,
        T_CONTRACTS.NET,
        T_CONTRACTS.COMMISSION,
        T_CONTRACTS.VAT,
        T_CONTRACTS.TRANS_LEVY,
        T_CONTRACTS.PPH,
        T_CONTRACTS.BROK,
        T_CONTRACTS.BROK_PERC,
        T_CONTRACTS.BRCH_CD,
        --DECODE(T_CONTRACTS.MRKT_TYPE,'RG','',T_CONTRACTS.MRKT_TYPE) AS mrkt_type,--21apr2016
         T_CONTRACTS.MRKT_TYPE,
        DECODE(SUBSTR(T_CONTRACTS.CONTR_NUM,5,1),'B',T_CONTRACTS.AMT_FOR_CURR,'J', (T_CONTRACTS.AMT_FOR_CURR * -1)) amt,
        DECODE(SUBSTR(T_CONTRACTS.CONTR_NUM,5,1),'J',TRIM(T_CONTRACTS.BUY_BROKER_CD),TRIM(T_CONTRACTS.SELL_BROKER_CD)) AS BROK_CD--22APR2016
      FROM T_CONTRACTS,
        MST_SALES
      WHERE T_CONTRACTS.CONTR_DT BETWEEN P_BGN_DATE AND P_END_DATE
      AND ( (SUBSTR((T_CONTRACTS.CONTR_NUM),6,1) = 'R')
      OR (SUBSTR((T_CONTRACTS.CONTR_NUM),6,1)    = 'I') )
      AND  T_CONTRACTS.CLIENT_CD BETWEEN P_BGN_CLIENT AND P_END_CLIENT 
      AND  T_CONTRACTS.CONTR_STAT <> 'C' 
      AND  T_CONTRACTS.STK_CD BETWEEN P_BGN_STOCK AND P_END_STOCK 
      AND  T_CONTRACTS.MRKT_TYPE BETWEEN P_BGN_MRKT_TYPE AND P_END_MRKT_TYPE 
      AND  T_CONTRACTS.BRCH_CD BETWEEN P_BGN_BRANCH AND P_END_BRANCH 
      AND  TRIM(T_CONTRACTS.MAIN_REM_CD) BETWEEN P_BGN_REM AND P_END_REM 
      AND  TRIM(T_CONTRACTS.MAIN_REM_CD) = TRIM(MST_SALES.REM_CD) 
      AND  SUBSTR((T_CONTRACTS.CONTR_NUM),5,1) LIKE P_STA 
      AND  SUBSTR((T_CONTRACTS.CONTR_NUM),6,1) LIKE P_STA_TYPE 
      AND ((T_CONTRACTS.PRICE = P_PRICE)
      OR (P_PRICE                 = 0) )
      AND (T_CONTRACTS.CLIENT_TYPE LIKE '%'
        ||P_CLIENT_TYPE3
        ||'%')
      AND ( MRKT_TYPE LIKE P_MRKT_TYPE
      OR (MRKT_TYPE   = 'TS'
      AND P_MRKT_TYPE = 'NG'))
      AND SCRIP_DAYS_C BETWEEN P_BGN_DAYS AND P_END_DAYS
      UNION ALL
      SELECT 'Min fee' CONTR_NUM,
        b.sl_acct_cd client_cd,
        trim(b.rem_cd) MAIN_REM_CD,
        ' ' BJ,
        b.doc_date,
        b.due_date,
        'ZZZZ' STK_CD,
        0 PRICE,
        0 QTY,
        0 LOT_SIZE,
        0 NET,
        SUM(DECODE(g.jur_type,'COMM', DECODE(a.db_cr_flg,'C',1,-1) * a.curr_val,0)) COMMISSION,
        SUM(DECODE(g.jur_type,'PPNO', DECODE(a.db_cr_flg,'C',1,-1) * a.curr_val,0)) VAT,
        0 TRANS_LEVY,
        0 PPH,
        SUM(DECODE(g.jur_type,'CLIE', DECODE(a.db_cr_flg,'D',1,-1) * a.curr_val,0)) BROK,
        0 BROK_PERC,
        trim(b.branch_code) BRCH_CD,
        '' mrkt_type,
        SUM(DECODE(g.jur_type,'CLIE', DECODE(A.db_cr_flg,'D',1,-1) * A.curr_val,0)) amt,
        '' BROK_CD
      FROM T_ACCOUNT_LEDGER a,
        (SELECT tal.xn_doc_num,
          tal.sl_acct_cd,
          tal.doc_date,
          tal.due_date,
          m.branch_code,
          m.rem_cd
        FROM T_ACCOUNT_LEDGER tal,
          MST_CLIENT m
        WHERE tal.doc_date BETWEEN P_BGN_DATE AND P_END_DATE
        AND tal.sl_acct_cd BETWEEN P_BGN_CLIENT AND P_END_CLIENT
        AND tal.xn_doc_num LIKE '%MFE%'
        AND tal.approved_sts <> 'C'
        AND tal.tal_id        = 1
        AND tal.sl_acct_cd    = m.client_cd
        AND trim(m.branch_code) BETWEEN P_BGN_BRANCH AND P_END_BRANCH
        AND trim(m.rem_cd) BETWEEN P_BGN_REM AND P_END_REM
        AND m.client_type_3 LIKE P_CLIENT_TYPE3
        ) b,
        (SELECT gl_a,
          jur_type
        FROM MST_GLA_TRX
        WHERE jur_type IN ('CLIE','PPNO','POSD','COMM')
        ) g
      WHERE a.xn_doc_num  = b.xn_doc_num
      AND a.gl_acct_Cd    = g.gl_a
      AND P_STA           = '%'
      AND P_STA_TYPE      = '%'
      AND P_BGN_MRKT_TYPE = '%'
      GROUP BY b.sl_acct_cd,
        b.doc_date,
        b.due_date,
        b.branch_code,
        b.rem_cd
      ) T_CONTRACTS,
      MST_CLIENT,
      MST_SALES,
      mst_bank_custody p,
      MST_BROKER r
    WHERE ( T_CONTRACTS.CLIENT_CD   = MST_CLIENT.CLIENT_CD )
    AND ( T_CONTRACTS.REM_CD        = MST_SALES.REM_CD )
    AND T_CONTRACTS.BROK_CD = R.BROKER_CD(+)--22APR2016
    AND (( MST_CLIENT.CUSTODIAN_CD IS NOT NULL
    AND P_CUSTODY                       = 'Y')
    OR P_CUSTODY                        = 'N')
    AND (MST_CLIENT.CUSTODIAN_CD    = p.CBEST_CD(+) );
  EXCEPTION
  WHEN OTHERS THEN
    V_ERROR_CD  := -30;
    V_ERROR_MSG := SUBSTR('INSERT R_CLIENT_ACTIVITY '||V_ERROR_MSG||SQLERRM(SQLCODE),1,200);
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
END SPR_CLIENT_ACTIVITY;