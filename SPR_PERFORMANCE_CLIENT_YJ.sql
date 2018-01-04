create or replace PROCEDURE SPR_PERFORMANCE_CLIENT_YJ(
    P_BGN_DATE      DATE,
    P_END_DATE      DATE,
    P_BGN_BRANCH    VARCHAR2,
    P_END_BRANCH    VARCHAR2,
    P_BGN_CTR_TYPE  VARCHAR2,
    P_END_CTR_TYPE  VARCHAR2,
    P_BGN_CLIENT    VARCHAR2,
    P_END_CLIENT    VARCHAR2,
    P_REPORT_MODE   VARCHAR2,
    P_CORP          VARCHAR2,
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
--[INDRA] 19SEP2017 UNTUK SUMMARY UBAH QUERY SUPAYA KALAU PILIH ALL GRUP BERDASARKAN INSTITUSI, INDIVIDUAL, LOT DENGAN SALES, LOT TANPA SALES
--[INDRA] 13NOV2017 GUNAKAN FIELD T_CONTRACTS.CAN_AMD_FLG UNTUK CEK NASABAH OLNLINE TRADING
  CURSOR CSR_TOTAL_LOT IS
SELECT SUM(DECODE(SUBSTR(CONTR_NUM,5,1),'J',VAL,0)) NET_SELL, SUM(DECODE(SUBSTR(CONTR_NUM,5,1),'B',VAL,0))NET_BUY,
      SUM(DECODE(SUBSTR(CONTR_NUM,5,1),'J',AMT_FOR_CURR,0))GROSS_SELL, SUM(DECODE(SUBSTR(CONTR_NUM,5,1),'B',AMT_FOR_CURR,0))GROSS_BUY,
      DECODE(T_CONTRACTS.REM_CD,'LOT','LOT TANPA SALES','LOT DENGAN SALES')SORTK
      FROM T_CONTRACTS,
            MST_CLIENT
          WHERE T_CONTRACTS.CONTR_STAT                  <> 'C'
          AND record_source <> 'IB'
          AND T_CONTRACTS.CONTR_DT                      >= P_BGN_DATE
          AND T_CONTRACTS.CONTR_DT                       < P_END_DATE + 1
          AND TRIM(T_CONTRACTS.BRCH_CD) BETWEEN P_BGN_BRANCH AND P_END_BRANCH
          AND T_CONTRACTS.CLIENT_CD BETWEEN P_BGN_CLIENT AND P_END_CLIENT
          AND SUBSTR(T_CONTRACTS.CONTR_NUM, 6, 1) BETWEEN P_BGN_CTR_TYPE AND P_END_CTR_TYPE
          AND MST_CLIENT.CLIENT_CD = T_CONTRACTS.CLIENT_CD
          AND T_CONTRACTS.CAN_AMD_FLG              = 'Y' --13NOV2017
          GROUP BY DECODE(T_CONTRACTS.REM_CD,'LOT','LOT TANPA SALES','LOT DENGAN SALES');
BEGIN

  V_RANDOM_VALUE := ABS(DBMS_RANDOM.RANDOM);
  
  BEGIN
    SP_RPT_REMOVE_RAND('R_CLIENT_PERFORMANCE',V_RANDOM_VALUE,V_ERROR_MSG,V_ERROR_CD);
  EXCEPTION
  WHEN OTHERS THEN
    V_ERROR_CD  := -10;
    V_ERROR_MSG := SUBSTR('SP_RPT_REMOVE_RAND '||V_ERROR_MSG||SQLERRM(SQLCODE),1,200);
    RAISE V_err;
  END;
  
  IF P_REPORT_MODE='DETAIL' THEN
    BEGIN
      INSERT
      INTO R_CLIENT_PERFORMANCE
        (
          BRCH_CD ,
          BRCH_NAME ,
          CLIENT_CD ,
          CLIENT_NAME ,
          CONTRACT_TYPE ,
          TRANSACTION_TYPE ,
          VAL ,
          BROK ,
          COMMISSION ,
          AMT_FOR_CURR ,
          FROM_DATE ,
          TO_DATE ,
          USER_ID ,
          RAND_VALUE ,
          GENERATE_DATE ,
          RPT_MODE
        )
      SELECT T_CONTRACT_detail.BRCH_CD     AS BRCH_CD,
        MST_BRANCH.BRCH_NAME               AS BRCH_NAME,
        T_CONTRACT_DETAIL.CLIENT_CD        AS CLIENT_CD,
        MST_CLIENT.CLIENT_NAME             AS CLIENT_NAME,
        T_CONTRACT_DETAIL.CONTRACT_TYPE    AS CONTRACT_TYPE,
        T_CONTRACT_DETAIL.TRANSACTION_TYPE AS TRANSACTION_TYPE,
        T_CONTRACT_DETAIL.VAL              AS VAL,
        T_CONTRACT_DETAIL.BROK             AS BROK,
        T_CONTRACT_DETAIL.COMMISSION       AS COMMISSION,
        T_CONTRACT_DETAIL.AMT_FOR_CURR     AS AMT_FOR_CURR ,
        P_BGN_DATE,
        P_END_DATE,
        P_USER_ID,
        V_RANDOM_VALUE,
        P_GENERATE_DATE,
        P_REPORT_MODE
      FROM
        (SELECT BRCH_CD,
          CLIENT_CD,
          CONTRACT_TYPE,
          TRANSACTION_TYPE,
          CAN_AMD_FLG,
          SUM(VAL) VAL,
          SUM(BROK) BROK,
          SUM(COMMISSION) COMMISSION,
          SUM(AMT_FOR_CURR) AMT_FOR_CURR
        FROM
          (SELECT TRIM(t.BRCH_CD)     AS BRCH_CD,
            t.CLIENT_CD,
            SUBSTR(t.CONTR_NUM, 6, 1) AS CONTRACT_TYPE,
            SUBSTR(t.CONTR_NUM, 5, 1) AS TRANSACTION_TYPE,
            t.VAL,
            t.BROK,
            t.COMMISSION,
            t.AMT_FOR_CURR,
            t.CAN_AMD_FLG
          FROM T_CONTRACTS t
          WHERE t.CONTR_STAT                  <> 'C'
          AND record_source <> 'IB'
          AND t.CONTR_DT                      >= P_BGN_DATE
          AND t.CONTR_DT                       < P_END_DATE + 1
          AND TRIM(t.BRCH_CD) BETWEEN P_BGN_BRANCH AND P_END_BRANCH
          AND SUBSTR(t.CONTR_NUM, 6, 1) BETWEEN P_BGN_CTR_TYPE AND P_END_CTR_TYPE
          AND (t.CLIENT_CD) BETWEEN P_BGN_CLIENT AND P_END_CLIENT
          )
        GROUP BY BRCH_CD,
          CLIENT_CD,
          CONTRACT_TYPE,
          TRANSACTION_TYPE,
          CAN_AMD_FLG
        ) T_CONTRACT_DETAIL,
        MST_BRANCH,
        MST_CLIENT
      WHERE T_CONTRACT_DETAIL.BRCH_CD   = TRIM(MST_BRANCH.BRCH_CD)
      AND (T_CONTRACT_DETAIL.CLIENT_CD) = mst_CLIENT.CLIENT_CD
       AND ((MST_CLIENT.CLIENT_TYPE_1 = 'C'
      AND P_CORP                     = 'CORP')
     --OR(MST_CLIENT.OLT              = 'Y' AND P_CORP                     ='LOT')
     OR(T_CONTRACT_DETAIL.CAN_AMD_FLG  = 'Y' AND P_CORP ='LOT')--13nov2017
      OR P_CORP                      = 'ALL');
    EXCEPTION
    WHEN OTHERS THEN
      V_ERROR_CD  := -40;
      V_ERROR_MSG := SUBSTR('INSERT INTO R_CLIENT_PERFORMANCE '||SQLERRM(SQLCODE),1,200);
      RAISE V_err;
    END;
  END IF;
  
  IF P_REPORT_MODE='SUMMARY_TRX' OR P_REPORT_MODE='SUMMARY_CL' THEN
    BEGIN
      INSERT
      INTO R_CLIENT_PERFORMANCE
        (
          BRCH_CD ,
          BRCH_NAME ,
          CLIENT_CD ,
          CLIENT_NAME ,
          REM_CD ,
          CONTRACT_TYPE ,
          TRANSACTION_TYPE ,
          VAL ,
          BROK ,
          COMMISSION ,
          AMT_FOR_CURR ,
          FROM_DATE ,
          TO_DATE ,
          USER_ID ,
          RAND_VALUE ,
          GENERATE_DATE ,
          RPT_MODE, 
          SORTK,
          NET
        )
      SELECT TRIM(T_CONTRACTS.BRCH_CD) AS BRCH_CD,
        NULL BRANCH_NAME,
        T_CONTRACTS.CLIENT_CD,
        INITCAP(MST_CLIENT.CLIENT_NAME) AS CLIENT_NAME,
        TRIM(T_CONTRACTS.REM_CD)              AS REM_CD,
        NULL CONTRACT_TYPE,
        NULL TRANSACTION_TYPE,
        SUM(T_CONTRACTS.VAL)          AS VAL,
        SUM(T_CONTRACTS.BROK)         AS BROK,
        SUM(T_CONTRACTS.COMMISSION)   AS COMMISSION,
        SUM(T_CONTRACTS.AMT_FOR_CURR) AS AMT_FOR_CURR,
        P_BGN_DATE,
        P_END_DATE,
        P_USER_ID,
        V_RANDOM_VALUE,
        P_GENERATE_DATE,
        P_REPORT_MODE,
        --DECODE(T_CONTRACTS.REM_CD,'LOT','1LOT TANPA SALES','2LOT DENGAN SALES'),--19SEP2017
       CASE WHEN T_CONTRACTS.REM_CD='LOT'  AND T_CONTRACTS.CAN_AMD_FLG  = 'Y' THEN
      'LOT TANPA SALES'
      WHEN T_CONTRACTS.REM_CD<> 'LOT' AND T_CONTRACTS.CAN_AMD_FLG = 'Y' THEN
      'LOT DENGAN SALES'
       WHEN MST_CLIENT.CLIENT_TYPE_1= 'I' AND nvl(T_CONTRACTS.CAN_AMD_FLG,'N')  = 'N' THEN
      'INDIVIDUAL'
      ELSE
      'INSTITUSI'
      END SORTK,
        SUM(T_CONTRACTS.NET) AS NET
      FROM T_CONTRACTS,
        MST_CLIENT
      WHERE T_CONTRACTS.CONTR_STAT                  <> 'C'
      AND record_source <> 'IB'
  --    AND NOT ((SUBSTR(T_CONTRACTS.CONTR_NUM, 5, 1) <> SUBSTR(T_CONTRACTS.CONTR_NUM, 7, 1))
  --    AND (SUBSTR(T_CONTRACTS.CONTR_NUM, 6, 1)       = 'I'))
      AND T_CONTRACTS.CONTR_DT                      >= P_BGN_DATE
      AND T_CONTRACTS.CONTR_DT                       < P_END_DATE + 1
      AND TRIM(T_CONTRACTS.BRCH_CD) BETWEEN P_BGN_BRANCH AND P_END_BRANCH
      AND T_CONTRACTS.CLIENT_CD BETWEEN P_BGN_CLIENT AND P_END_CLIENT
      AND SUBSTR(T_CONTRACTS.CONTR_NUM, 6, 1) BETWEEN P_BGN_CTR_TYPE AND P_END_CTR_TYPE
      AND MST_CLIENT.CLIENT_CD = T_CONTRACTS.CLIENT_CD
      AND ((MST_CLIENT.CLIENT_TYPE_1 = 'C'
      AND P_CORP                     = 'CORP')
      --OR(MST_CLIENT.OLT              = 'Y' AND P_CORP                     ='LOT') --13 NOV
      OR(T_CONTRACTS.CAN_AMD_FLG = 'Y' AND P_CORP                     ='LOT') --13 NOV
      OR P_CORP                      = 'ALL')
      GROUP BY T_CONTRACTS.BRCH_CD,
        T_CONTRACTS.CLIENT_CD,
        MST_CLIENT.CLIENT_NAME,
        T_CONTRACTS.REM_CD,
        MST_CLIENT.CLIENT_TYPE_1,
        T_CONTRACTS.CAN_AMD_FLG
      ORDER BY TRIM(T_CONTRACTS.BRCH_CD) ASC,
        TRIM(T_CONTRACTS.CLIENT_CD) ASC ;
    EXCEPTION
    WHEN OTHERS THEN
      V_ERROR_CD  := -50;
      V_ERROR_MSG := SUBSTR('INSERT INTO R_CLIENT_PERFORMANCE '||SQLERRM(SQLCODE),1,200);
      RAISE V_err;
    END;

     --UPDATE NET_SELL, NET_BUY, GROSS_SELL, GROSS_BUY
IF P_CORP <> 'LOT' THEN
      BEGIN
        UPDATE R_CLIENT_PERFORMANCE SET (NET_SELL, NET_BUY,GROSS_SELL,GROSS_BUY) = 
        (SELECT SUM(DECODE(SUBSTR(CONTR_NUM,5,1),'J',VAL,0)) NET_SELL, SUM(DECODE(SUBSTR(CONTR_NUM,5,1),'B',VAL,0))NET_BUY,
      SUM(DECODE(SUBSTR(CONTR_NUM,5,1),'J',AMT_FOR_CURR,0))GROSS_SELL, SUM(DECODE(SUBSTR(CONTR_NUM,5,1),'B',AMT_FOR_CURR,0))GROSS_BUY
      FROM T_CONTRACTS,
            MST_CLIENT
          WHERE T_CONTRACTS.CONTR_STAT                  <> 'C'
          AND record_source <> 'IB'
          AND T_CONTRACTS.CONTR_DT                      >= P_BGN_DATE
          AND T_CONTRACTS.CONTR_DT                       < P_END_DATE + 1
          AND TRIM(T_CONTRACTS.BRCH_CD) BETWEEN P_BGN_BRANCH AND P_END_BRANCH
          AND T_CONTRACTS.CLIENT_CD BETWEEN P_BGN_CLIENT AND P_END_CLIENT
          AND SUBSTR(T_CONTRACTS.CONTR_NUM, 6, 1) BETWEEN P_BGN_CTR_TYPE AND P_END_CTR_TYPE
          AND MST_CLIENT.CLIENT_CD = T_CONTRACTS.CLIENT_CD
          AND ((MST_CLIENT.CLIENT_TYPE_1 = 'C'
          AND P_CORP                     = 'CORP')
          --OR(MST_CLIENT.OLT              = 'Y'  AND P_CORP                     ='LOT')--13NOV2017
          OR(T_CONTRACTS.CAN_AMD_FLG = 'Y'  AND P_CORP                     ='LOT')--13NOV2017
          OR P_CORP                      = 'ALL'))
          where rand_value=V_RANDOM_VALUE and user_id=P_USER_ID;
       EXCEPTION
        WHEN OTHERS THEN
          V_ERROR_CD  := -60;
          V_ERROR_MSG := SUBSTR('UPDATE NET_SELL, NET_BUY, GROSS_SELL, GROSS_BUY R_CLIENT_PERFORMANCE '||SQLERRM(SQLCODE),1,200);
          RAISE V_err;
        END;

    ELSE

      FOR REC IN CSR_TOTAL_LOT LOOP
      BEGIN
          UPDATE R_CLIENT_PERFORMANCE SET NET_SELL=REC.NET_SELL, NET_BUY=REC.NET_BUY,GROSS_SELL=REC.GROSS_SELL,GROSS_BUY=REC.GROSS_BUY  
          where rand_value=V_RANDOM_VALUE and user_id=P_USER_ID
            AND SORTK = REC.SORTK;
         EXCEPTION
          WHEN OTHERS THEN
            V_ERROR_CD  := -65;
            V_ERROR_MSG := SUBSTR('UPDATE NET_SELL, NET_BUY, GROSS_SELL, GROSS_BUY R_CLIENT_PERFORMANCE LOT'||SQLERRM(SQLCODE),1,200);
            RAISE V_err;
          END;
    END LOOP;
    END IF;--END IF UPDATE R_CLIENT_PERFORMANCE

  END IF;

 

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
END SPR_PERFORMANCE_CLIENT_YJ;