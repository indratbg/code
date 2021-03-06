create or replace PROCEDURE SPR_PERFORMANCE_BRANCH(
    P_BGN_DATE      DATE,
    P_END_DATE      DATE,
    P_BGN_BRANCH    VARCHAR2,
    P_END_BRANCH    VARCHAR2,
    P_BGN_REM       VARCHAR2,
    P_END_REM       VARCHAR2,
    P_CONTRACT_TYPE VARCHAR2,
    P_REPORT_MODE   VARCHAR2,
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
    SP_RPT_REMOVE_RAND('R_BRANCH_PERFORMANCE',V_RANDOM_VALUE,V_ERROR_MSG,V_ERROR_CD);
  EXCEPTION
  WHEN OTHERS THEN
    V_ERROR_CD  := -10;
    V_ERROR_MSG := SUBSTR('SP_RPT_REMOVE_RAND '||V_ERROR_MSG||SQLERRM(SQLCODE),1,200);
    RAISE V_err;
  END;
  
  IF P_REPORT_MODE='DETAIL' THEN
    BEGIN
      INSERT
      INTO R_BRANCH_PERFORMANCE
        (
          BRCH_CD ,
          BRCH_NAME ,
          REM_CD ,
          REM_NAME ,
          CONTRACT_TYPE ,
          VAL ,
          BROK ,
          COMMISSION ,
          AMT_FOR_CURR ,
          FROM_DATE ,
          TO_DATE ,
          USER_ID ,
          RAND_VALUE ,
          GENERATE_DATE,
          RPT_MODE
        )
      SELECT T_CONTRACTS.BRCH_CD         AS BRCH_CD,
        TAB_BRANCH.BRCH_NAME             AS BRCH_NAME,
        T_CONTRACTS.REM_CD               AS REM_CD,
        MST_SALES.REM_NAME               AS REM_NAME,
        T_CONTRACTS.CONTRACT_TYPE        AS CONTRACT_TYPE,
        NVL(T_CONTRACTS.VAL, 0)          AS VAL,
        NVL(T_CONTRACTS.BROK, 0)         AS BROK,
        NVL(T_CONTRACTS.COMMISSION, 0)   AS COMMISSION,
        NVL(T_CONTRACTS.AMT_FOR_CURR, 0) AS AMT_FOR_CURR,
        P_BGN_DATE,
        P_END_DATE,
        P_USER_ID,
        V_RANDOM_VALUE,
        P_GENERATE_DATE,
        P_REPORT_MODE
      FROM
        (SELECT TRIM(T_CONTRACTS.BRCH_CD)     AS BRCH_CD,
          TRIM(T_CONTRACTS.REM_CD)            AS REM_CD,
          SUBSTR(T_CONTRACTS.CONTR_NUM, 6, 1) AS CONTRACT_TYPE,
          SUM(T_CONTRACTS.VAL)                AS VAL,
          SUM(T_CONTRACTS.BROK)               AS BROK,
          SUM(T_CONTRACTS.COMMISSION)         AS COMMISSION,
          SUM(T_CONTRACTS.AMT_FOR_CURR)       AS AMT_FOR_CURR
        FROM INSISTPRO.T_CONTRACTS T_CONTRACTS
        WHERE T_CONTRACTS.CONTR_STAT           <> 'C'
        AND SUBSTR(T_CONTRACTS.CONTR_NUM, 6, 1) LIKE P_CONTRACT_TYPE--= 'R'
        AND T_CONTRACTS.CONTR_DT               >= P_BGN_DATE
        AND T_CONTRACTS.CONTR_DT                < P_END_DATE + 1
        AND TRIM(T_CONTRACTS.BRCH_CD) BETWEEN P_BGN_BRANCH AND P_END_BRANCH
        AND TRIM(T_CONTRACTS.REM_CD) BETWEEN P_BGN_REM AND P_END_REM
        GROUP BY TRIM(T_CONTRACTS.BRCH_CD),
          TRIM(T_CONTRACTS.REM_CD),
          SUBSTR(T_CONTRACTS.CONTR_NUM, 6, 1)
        UNION
        SELECT TRIM(T_CONTRACTS.BRCH_CD)      AS BRCH_CD,
          TRIM(T_CONTRACTS.REM_CD)            AS REM_CD,
          SUBSTR(T_CONTRACTS.CONTR_NUM, 6, 1) AS CONTRACT_TYPE,
          SUM(T_CONTRACTS.VAL)                AS VAL,
          SUM(T_CONTRACTS.BROK)               AS BROK,
          SUM(T_CONTRACTS.COMMISSION)         AS COMMISSION,
          SUM(T_CONTRACTS.AMT_FOR_CURR)       AS AMT_FOR_CURR
        FROM T_CONTRACTS T_CONTRACTS
        WHERE T_CONTRACTS.CONTR_STAT           <> 'C'
       AND SUBSTR(T_CONTRACTS.CONTR_NUM, 6, 1)  LIKE P_CONTRACT_TYPE-- 'I'
     --   AND SUBSTR(T_CONTRACTS.CONTR_NUM, 5, 1) = SUBSTR(T_CONTRACTS.CONTR_NUM, 7, 1)
        AND T_CONTRACTS.CONTR_DT               >= P_BGN_DATE
        AND T_CONTRACTS.CONTR_DT                < P_END_DATE + 1
        AND TRIM(T_CONTRACTS.BRCH_CD) BETWEEN P_BGN_BRANCH AND P_END_BRANCH
        AND TRIM(T_CONTRACTS.REM_CD) BETWEEN P_BGN_REM AND P_END_REM
        GROUP BY TRIM(T_CONTRACTS.BRCH_CD),
          TRIM(T_CONTRACTS.REM_CD),
          SUBSTR(T_CONTRACTS.CONTR_NUM, 6, 1)
        ) T_CONTRACTS,
        ( SELECT TRIM(MST_BRANCH.BRCH_NAME) AS BRCH_NAME, BRCH_CD FROM MST_BRANCH
        ) TAB_BRANCH,
        MST_SALES
      WHERE TRIM(T_CONTRACTS.BRCH_CD) = TRIM(TAB_BRANCH.BRCH_CD(+))
      AND TRIM(T_CONTRACTS.REM_CD)    = TRIM( MST_SALES.REM_CD(+))
      ORDER BY 1 ASC,
        2 ASC,
        3 ASC,
        4 ASC,
        5 ASC;
    EXCEPTION
    WHEN OTHERS THEN
      V_ERROR_CD  := -40;
      V_ERROR_MSG := SUBSTR('INSERT INTO R_BRANCH_PERFORMANCE '||SQLERRM(SQLCODE),1,200);
      RAISE V_err;
    END;
  END IF;
  
  IF P_REPORT_MODE='SUMMARY' THEN
    BEGIN
      INSERT
      INTO R_BRANCH_PERFORMANCE
        (
          BRCH_CD ,
          BRCH_NAME ,
          REM_CD ,
          REM_NAME ,
          CONTRACT_TYPE ,
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
      SELECT T_CONTRACTS.BRCH_CD AS BRCH_CD,
        TAB_BRANCH.BRCH_NAME     AS BRCH_NAME,
        NULL REM_CD,
        NULL REM_NAME,
        T_CONTRACTS.CONTRACT_TYPE        AS CONTRACT_TYPE,
        NVL(T_CONTRACTS.VAL, 0)          AS VAL,
        NVL(T_CONTRACTS.BROK, 0)         AS BROK,
        NVL(T_CONTRACTS.COMMISSION, 0)   AS COMMISSION,
        NVL(T_CONTRACTS.AMT_FOR_CURR, 0) AS AMT_FOR_CURR ,
        P_BGN_DATE,
        P_END_DATE,
        P_USER_ID,
        V_RANDOM_VALUE,
        P_GENERATE_DATE,
        P_REPORT_MODE
      FROM
        (SELECT TRIM(T_CONTRACTS.BRCH_CD) AS BRCH_CD,
          'R'                             AS CONTRACT_TYPE,
          SUM(T_CONTRACTS.VAL)            AS VAL,
          SUM(T_CONTRACTS.BROK)           AS BROK,
          SUM(T_CONTRACTS.COMMISSION)     AS COMMISSION,
          SUM(T_CONTRACTS.AMT_FOR_CURR)   AS AMT_FOR_CURR
        FROM INSISTPRO.T_CONTRACTS T_CONTRACTS
        WHERE T_CONTRACTS.CONTR_STAT           <> 'C'
        AND SUBSTR(T_CONTRACTS.CONTR_NUM, 6, 1) = 'R'
        AND T_CONTRACTS.CONTR_DT BETWEEN P_BGN_DATE AND P_END_DATE
        AND TRIM(T_CONTRACTS.BRCH_CD) BETWEEN P_BGN_BRANCH AND P_END_BRANCH
        AND TRIM(T_CONTRACTS.REM_CD) BETWEEN P_BGN_REM AND P_END_REM
        GROUP BY TRIM(T_CONTRACTS.BRCH_CD)
        UNION
        SELECT TRIM(T_CONTRACTS.BRCH_CD) AS BRCH_CD,
          'I'                            AS CONTRACT_TYPE,
          SUM(T_CONTRACTS.VAL)           AS VAL,
          SUM(T_CONTRACTS.BROK)          AS BROK,
          SUM(T_CONTRACTS.COMMISSION)    AS COMMISSION,
          SUM(T_CONTRACTS.AMT_FOR_CURR)  AS AMT_FOR_CURR
        FROM INSISTPRO.T_CONTRACTS T_CONTRACTS
        WHERE T_CONTRACTS.CONTR_STAT           <> 'C'
        AND SUBSTR(T_CONTRACTS.CONTR_NUM, 6, 1) = 'I'
  --      AND SUBSTR(T_CONTRACTS.CONTR_NUM, 5, 1) = SUBSTR(T_CONTRACTS.CONTR_NUM, 7, 1)
        AND T_CONTRACTS.CONTR_DT BETWEEN P_BGN_DATE AND P_END_DATE
        AND TRIM(T_CONTRACTS.BRCH_CD) BETWEEN P_BGN_BRANCH AND P_END_BRANCH
        AND TRIM(T_CONTRACTS.REM_CD) BETWEEN P_BGN_REM AND P_END_REM
        GROUP BY TRIM(T_CONTRACTS.BRCH_CD)
        ) T_CONTRACTS,
        ( SELECT TRIM(MST_BRANCH.BRCH_NAME) AS BRCH_NAME, BRCH_CD FROM MST_BRANCH
        ) TAB_BRANCH
      WHERE TRIM(T_CONTRACTS.BRCH_CD) = TRIM(TAB_BRANCH.BRCH_CD(+))
      ORDER BY 1 ASC,
        2 ASC,
        3 ASC,
        4 ASC,
        5 ASC;
    EXCEPTION
    WHEN OTHERS THEN
      V_ERROR_CD  := -50;
      V_ERROR_MSG := SUBSTR('INSERT INTO R_BRANCH_PERFORMANCE '||SQLERRM(SQLCODE),1,200);
      RAISE V_err;
    END;
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
END SPR_PERFORMANCE_BRANCH;