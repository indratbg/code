create or replace PROCEDURE SPR_PERFORMANCE_SALES(
    P_BGN_DATE DATE,
    P_END_DATE DATE,
    P_BGN_BRANCH MST_BRANCH.BRCH_CD%TYPE,
    P_END_BRANCH MST_BRANCH.BRCH_CD%TYPE,
    P_BGN_CTR_TYPE VARCHAR2,
    P_END_CTR_TYPE VARCHAR2,
    P_BGN_REM MST_SALES.REM_CD%TYPE,
    P_END_REM MST_SALES.REM_CD%TYPE,
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
  CURSOR CSR_COMM
  IS
    SELECT BRANCH_CODE,
      PRM_DESC,
      CLIENT_CD,
      CLIENT_NAME,
      REM_NAME,
      CLIENT_COMM,
      TOT_BRANCH,
      COMM_PERC,
      CNT,
      SEQNO,
      DECODE(SEQNO,1,TOT_COMM_PRC,COMM_PRC_prev)COMM_PRC_prev
      -- LAG( ) OVER (PARTITION BY BRANCH_CODE ORDER BY BRANCH_CODE, CLIENT_COMM DESC) TOTAL_PREV,
      --DECODE(SEQNO,1,TOT_COMM_PRC,) AKUM
      --TOT_COMM_PRC
      --last_value(COMM_PERC) OVER ( ORDER BY BRANCH_CODE,CLIENT_COMM DESC  ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS LastValue
      --DECODE(SEQNO,1,TOT_COMM_PRC,) AKUM_COMM
    FROM
      (SELECT B.BRANCH_CODE,
        P.BRCH_NAME AS PRM_DESC,
        B.CLIENT_CD,
        B.CLIENT_NAME,
        B.REM_NAME,
        B.CLIENT_COMM,
        A.TOT_BRANCH,
        ROUND(B.CLIENT_COMM/ A.TOT_BRANCH,4) COMM_PERC,
        A.CNT,
        row_number() OVER (PARTITION BY B.BRANCH_CODE ORDER BY B.BRANCH_CODE, B.CLIENT_COMM DESC) SEQNO,
        LAG( ROUND(B.CLIENT_COMM/ A.TOT_BRANCH,4), 1, 0) OVER (PARTITION BY B.BRANCH_CODE ORDER BY B.BRANCH_CODE, B.CLIENT_COMM DESC) AS COMM_PRC_prev,
        SUM(ROUND(B.CLIENT_COMM / A.TOT_BRANCH,4)) OVER(PARTITION BY B.BRANCH_CODE) TOT_COMM_PRC
      FROM
        (SELECT T.BRCH_CD BRANCH_CODE,
          SUM(T.COMMISSION) TOT_BRANCH,
          COUNT(DISTINCT TRIM(T.CLIENT_Cd)) CNT
        FROM T_CONTRACTS T,
          MST_CLIENT M
        WHERE T.CONTR_STAT <> 'C'
        AND T.CONTR_DT BETWEEN P_BGN_DATE AND P_END_DATE
        AND T.CLIENT_Cd                = M.CLIENT_Cd
        AND record_source <> 'IB'
        AND (SUBSTR(T.CONTR_NUM,6,1)   = P_BGN_CTR_TYPE
                OR P_BGN_CTR_TYPE             = '%')
        GROUP BY T.BRCH_CD
        ) A,
      (SELECT T.BRCH_CD BRANCH_CODE,
        TRIM(T.CLIENT_CD) CLIENT_CD,
        M.CLIENT_NAME,
        S.REM_NAME,
        SUM(T.COMMISSION) CLIENT_COMM
      FROM T_CONTRACTS T,
        MST_CLIENT M,
        MST_SALES S
      WHERE T.CONTR_STAT <> 'C'
      AND T.CONTR_DT BETWEEN P_BGN_DATE AND P_END_DATE
      AND T.CLIENT_Cd                = M.CLIENT_Cd
      AND TRIM(M.REM_CD)             = TRIM(S.REM_CD)
      AND ((SUBSTR(T.CONTR_NUM,5,3) IN ('BIB','JIJ')
      AND P_BGN_CTR_TYPE             = 'ALL')
      OR SUBSTR(T.CONTR_NUM,6,1)    <> 'I')
      GROUP BY T.BRCH_CD,
        T.CLIENT_CD,
        M.CLIENT_NAME,
        S.REM_NAME
      ) B,
      MST_BRANCH P
    WHERE TRIM(A.BRANCH_CODE) = TRIM(B.BRANCH_CODE)
    AND TRIM(P.BRCH_CD)       = TRIM(B.BRANCH_CODE)
    AND P.BRCH_CD LIKE P_BGN_BRANCH
      )
    ORDER BY BRANCH_CODE,
      CLIENT_COMM DESC;
    V_COMM_PRC_SELECTED NUMBER :=0;
  BEGIN
    V_RANDOM_VALUE := ABS(DBMS_RANDOM.RANDOM);
    BEGIN
      SP_RPT_REMOVE_RAND('R_SALES_PERFORMANCE',V_RANDOM_VALUE,V_ERROR_MSG,V_ERROR_CD);
    EXCEPTION
    WHEN OTHERS THEN
      V_ERROR_CD  := -10;
      V_ERROR_MSG := SUBSTR('SP_RPT_REMOVE_RAND '||V_ERROR_MSG||SQLERRM(SQLCODE),1,200);
      RAISE V_err;
    END;
    IF P_REPORT_MODE='DETAIL' THEN
      BEGIN
        INSERT
        INTO R_SALES_PERFORMANCE
          (
            BRCH_CD ,
            BRCH_NAME ,
            CONTRACT_TYPE ,
            REM_CD ,
            REM_NAME ,
            CLIENT_CD ,
            CLIENT_NAME ,
            OLT ,
            COMMISSION_PER ,
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
        SELECT (T_CONTRACTS.BRCH_CD) AS BRCH_CD,
          (MST_BRANCH.BRCH_NAME)     AS BRCH_NAME,
          T_CONTRACTS.CONTRACT_TYPE,
          (T_CONTRACTS.REM_CD)     AS REM_CD,
          (MST_SALES.REM_NAME)     AS REM_NAME,
          (T_CONTRACTS.CLIENT_CD)  AS CLIENT_CD,
          (MST_CLIENT.CLIENT_NAME) AS CLIENT_NAME,
          T_CONTRACTS.olt,
          T_CONTRACTS.COMMISSION_PER/100,
          (T_CONTRACTS.VAL)          AS VAL,
          (T_CONTRACTS.BROK)         AS BROK,
          (T_CONTRACTS.COMMISSION)   AS COMMISSION,
          (T_CONTRACTS.AMT_FOR_CURR) AS AMT_FOR_CURR,
          P_BGN_DATE,
          P_END_DATE,
          P_USER_ID,
          V_RANDOM_VALUE,
          P_GENERATE_DATE,
          P_REPORT_MODE
        FROM
          (SELECT BRCH_CD,
            CONTRACT_TYPE,
            REM_CD,
            CLIENT_CD,
            COMMISSION_PER,
            olt,
            SUM(VAL)          AS VAL,
            SUM(BROK)         AS BROK,
            SUM(COMMISSION)   AS COMMISSION,
            SUM(AMT_FOR_CURR) AS AMT_FOR_CURR
          FROM
            (SELECT trim(BRCH_CD) BRCH_Cd,
              SUBSTR(CONTR_NUM, 6, 1) AS CONTRACT_TYPE,
              trim(REM_CD) rem_cd,
              trim(CLIENT_CD) client_cd,
              BROK_PERC AS COMMISSION_PER,
              VAL,
              BROK,
              COMMISSION,
              AMT_FOR_CURR,
              Can_amd_flg AS olt
            FROM T_CONTRACTS
            WHERE CONTR_STAT         <> 'C'
            AND T_CONTRACTS.CONTR_DT >= P_BGN_DATE
            AND T_CONTRACTS.CONTR_DT  < P_END_DATE + 1
            AND trim(T_CONTRACTS.BRCH_CD) BETWEEN P_BGN_BRANCH AND P_END_BRANCH
            AND SUBSTR(T_CONTRACTS.CONTR_NUM, 6, 1) BETWEEN P_BGN_CTR_TYPE AND P_END_CTR_TYPE
            AND (T_CONTRACTS.REM_CD) BETWEEN P_BGN_REM AND P_END_REM
            AND record_source <> 'IB'
            )
          GROUP BY BRCH_CD,
            CONTRACT_TYPE,
            REM_CD,
            CLIENT_CD,
            COMMISSION_PER,
            olt
          ) T_CONTRACTS,
          MST_BRANCH,
          MST_SALES,
          MST_CLIENT
        WHERE TRIM(MST_BRANCH.BRCH_CD) = (T_CONTRACTS.BRCH_CD)
        AND (MST_SALES.REM_CD)         = TRIM(T_CONTRACTS.REM_CD)
        AND MST_CLIENT.CLIENT_CD       = T_CONTRACTS.CLIENT_CD
        ORDER BY (T_CONTRACTS.BRCH_CD) ASC,
          T_CONTRACTS.CONTRACT_TYPE DESC,
          (T_CONTRACTS.REM_CD) ASC,
          T_CONTRACTS.COMMISSION_PER ASC,
          (T_CONTRACTS.CLIENT_CD) ASC;
      EXCEPTION
      WHEN OTHERS THEN
        V_ERROR_CD  := -40;
        V_ERROR_MSG := SUBSTR('INSERT INTO R_SALES_PERFORMANCE '||SQLERRM(SQLCODE),1,200);
        RAISE V_err;
      END;
    END IF;
    IF P_REPORT_MODE='SUMMARY' THEN
      BEGIN
        INSERT
        INTO R_SALES_PERFORMANCE
          (
            BRCH_CD ,
            BRCH_NAME ,
            CONTRACT_TYPE ,
            REM_CD ,
            REM_NAME ,
            CLIENT_CD ,
            CLIENT_NAME ,
            OLT ,
            COMMISSION_PER ,
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
        SELECT TRIM(T_CONTRACTS.BRCH_CD) AS BRCH_CD,
          NULL BRANCH_NAME,
          SUBSTR(T_CONTRACTS.CONTR_NUM, 6, 1) AS CONTRACT_TYPE,
          TRIM(T_CONTRACTS.REM_CD)            AS REM_CD,
          TRIM(MST_SALES.REM_NAME)            AS REM_NAME,
          NULL CLIENT_CD,
          NULL CLIENT_NAME,
          NULL OLT,
          NULL COMMISSION_PER,
          SUM(T_CONTRACTS.VAL)          AS VAL,
          SUM(T_CONTRACTS.BROK)         AS BROK,
          SUM(T_CONTRACTS.COMMISSION)   AS COMMISSION,
          SUM(T_CONTRACTS.AMT_FOR_CURR) AS AMT_FOR_CURR,
          P_BGN_DATE,
          P_END_DATE,
          P_USER_ID,
          V_RANDOM_VALUE,
          P_GENERATE_DATE,
          P_REPORT_MODE
        FROM T_CONTRACTS,
          MST_SALES
        WHERE T_CONTRACTS.CONTR_STAT <> 'C'
        AND TRIM(MST_SALES.REM_CD)    = TRIM(T_CONTRACTS.REM_CD)
        AND T_CONTRACTS.CONTR_DT     >= P_BGN_DATE
        AND T_CONTRACTS.CONTR_DT      < P_END_DATE + 1
        AND TRIM(T_CONTRACTS.BRCH_CD) BETWEEN P_BGN_BRANCH AND P_END_BRANCH
        AND SUBSTR(T_CONTRACTS.CONTR_NUM, 6, 1) BETWEEN P_BGN_CTR_TYPE AND P_END_CTR_TYPE
        AND TRIM(T_CONTRACTS.REM_CD) BETWEEN P_BGN_REM AND P_END_REM
        AND record_source <> 'IB'
        GROUP BY SUBSTR(T_CONTRACTS.CONTR_NUM, 6, 1),
          TRIM(T_CONTRACTS.REM_CD),
          TRIM(MST_SALES.REM_NAME),
          TRIM(T_CONTRACTS.BRCH_CD);
      EXCEPTION
      WHEN OTHERS THEN
        V_ERROR_CD  := -50;
        V_ERROR_MSG := SUBSTR('INSERT INTO R_SALES_PERFORMANCE '||SQLERRM(SQLCODE),1,200);
        RAISE V_err;
      END;
    END IF;
    IF P_REPORT_MODE = 'COMMISSION' THEN
      FOR REC IN CSR_COMM
      LOOP
      
        IF REC.SEQNO = 1 THEN
          V_COMM_PRC_SELECTED := REC.COMM_PRC_PREV;
        END IF;
        BEGIN
          INSERT
          INTO R_SALES_PERFORMANCE
            (
              BRCH_CD ,
              BRCH_NAME ,
              CLIENT_CD ,
              CLIENT_NAME ,
              REM_NAME ,
              COMMISSION ,
              TOT_BRANCH ,
              COMMISSION_PER ,
              CNT ,
              FROM_DATE ,
              TO_DATE ,
              USER_ID ,
              RAND_VALUE ,
              GENERATE_DATE ,
              RPT_MODE,
              COMM_PRC_PREV,
              COMM_PRC_SELECTED
            )
            VALUES
            (
              REC.BRANCH_CODE,
              REC.PRM_DESC,
              REC.CLIENT_CD,
              REC.CLIENT_NAME,
              REC.REM_NAME,
              REC.CLIENT_COMM,
              REC.TOT_BRANCH,
              REC.COMM_PERC,
              REC.CNT,
              P_BGN_DATE,
              P_END_DATE,
              P_USER_ID,
              V_RANDOM_VALUE,
              P_GENERATE_DATE,
              P_REPORT_MODE,
              REC.COMM_PRC_PREV,
              V_COMM_PRC_SELECTED
            );
        EXCEPTION
        WHEN OTHERS THEN
          V_ERROR_CD  := -60;
          V_ERROR_MSG := SUBSTR('INSERT INTO R_SALES_PERFORMANCE '||SQLERRM(SQLCODE),1,200);
          RAISE V_err;
        END;
        
        V_COMM_PRC_SELECTED := V_COMM_PRC_SELECTED- REC.COMM_PERC;
        
      END LOOP;
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
  END SPR_PERFORMANCE_SALES;