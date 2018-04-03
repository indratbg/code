create or replace PROCEDURE SPR_AGING_ARAP_REGULAR(
    P_REP_DATE DATE,
    P_BRANCH VARCHAR2,--% =ALL
    P_OUTS_TYPE VARCHAR2,--%=ALL, AR,AP=SPECIFIED
    P_OWNER VARCHAR2,--CLIENT,KPEI,BROKER
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
  V_DATE_MIN4 DATE;
  V_DATE_T1 DATE;
  V_DATE_T2 DATE;
  V_DATE_T3 DATE;
BEGIN
  
  v_random_value := ABS(dbms_random.random);
  
  BEGIN
    SP_RPT_REMOVE_RAND('R_AGING_ARAP_REGULAR',V_RANDOM_VALUE,V_ERROR_MSG,V_ERROR_CD);
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
  

  V_DATE_MIN4 := GET_DOC_DATE(4,P_REP_DATE);
  V_DATE_T1 :=GET_DUE_DATE(1,P_REP_DATE);
  V_DATE_T2 :=GET_DUE_DATE(2,P_REP_DATE);
  V_DATE_T3 :=GET_DUE_DATE(3,P_REP_DATE);


  --CLIENT regular
  IF P_OWNER='CLIENT' THEN
  
          BEGIN
          INSERT INTO R_AGING_ARAP_REGULAR(ARAP_TYPE,CLIENT_CD,CLIENT_NAME,CLIENT_TYPE,BRANCH_CODE,
            AMT_T1,AMT_T2,AMT_T3,USER_ID,RAND_VALUE,GENERATE_DATE)
          SELECT ARAP_TYPE, CLIENT_CD, CLIENT_NAME, CLIENT_TYPE_3, BRANCH_CODE,     
                  AMT_T1, AMT_T2, AMT_T3 ,P_USER_ID,V_RANDOM_VALUE,P_GENERATE_DATE     
          FROM( SELECT ARAP_TYPE, T.CLIENT_CD, CLIENT_NAME, CLIENT_TYPE_3, BRANCH_CODE,     
                            DECODE( ARAP_TYPE,'1AR', DECODE( SIGN(AMT_T1), 1, AMT_T1,0), DECODE( SIGN(AMT_T1), -1, -AMT_T1,0)) AMT_T1,      
                            DECODE( ARAP_TYPE,'1AR', DECODE( SIGN(AMT_T2), 1, AMT_T2,0), DECODE( SIGN(AMT_T2), -1, -AMT_T2,0)) AMT_T2,      
                            DECODE( ARAP_TYPE,'1AR', DECODE( SIGN(AMT_T3), 1, AMT_T3,0), DECODE( SIGN(AMT_T3), -1, -AMT_T3,0)) AMT_T3     
                  FROM(     
                          SELECT CLIENT_CD, SUM(DECODE( DUE_DATE, V_DATE_T1, AMT, 0)) AMT_T1,     
                          SUM(DECODE( DUE_DATE,V_DATE_T2, AMT, 0)) AMT_T2,      
                          SUM(DECODE( DUE_DATE, V_DATE_T3, AMT, 0)) AMT_T3      
                           FROM (     
                                  SELECT T.CLIENT_CD, DUE_DT_FOR_AMT AS DUE_DATE, DECODE(SUBSTR(CONTR_NUM,5,1),'B',1,-1) * AMT_FOR_CURR AS AMT      
                                  FROM T_CONTRACTS T, MST_CLIENT M      
                                  WHERE CONTR_DT BETWEEN V_DATE_MIN4 AND P_REP_DATE     
                                  AND T.CLIENT_CD = M.CLIENT_CD   
                                  AND M.CLIENT_TYPE_3 IN ( 'R','K','N')   
                                  AND CONTR_STAT <> 'C'  
                                  AND ((TRIM(M.BRANCH_CODE)= P_BRANCH AND P_BRANCH <> '%')OR P_BRANCH='%')
                                  AND DUE_DT_FOR_AMT BETWEEN V_DATE_T1 AND V_DATE_T3      
                                  )     
                          GROUP BY CLIENT_CD      
                          ) T,      
                          ( SELECT '1AR' AS ARAP_TYPE FROM DUAL     
                          UNION ALL     
                          SELECT '2AP' FROM DUAL),      
                          MST_CLIENT M      
                  WHERE T.CLIENT_CD =M.CLIENT_CD      
          );   
          EXCEPTION
          WHEN OTHERS THEN
            V_ERROR_CD :=-20;
            V_ERROR_MSG :=SUBSTR('INSERT INTO R_AGING_ARAP_REGULAR CLIENT '||SQLERRM,1,200);
            RAISE V_ERR; 
            END;
  END IF;

   --KPEI 
  IF P_OWNER='KPEI' THEN
        BEGIN
          INSERT INTO R_AGING_ARAP_REGULAR(ARAP_TYPE,CLIENT_CD,CLIENT_NAME,CLIENT_TYPE,BRANCH_CODE,
            AMT_T1,AMT_T2,AMT_T3,USER_ID,RAND_VALUE,GENERATE_DATE)
         SELECT ARAP_TYPE, 'KPEI' CLIENT_CD, NULL CLIENT_NAME, NULL CLIENT_TYPE_3, NULL BRANCH_CODE,      
                        DECODE( ARAP_TYPE,'1AR', DECODE( SIGN(AMT_T1), 1, AMT_T1,0), DECODE( SIGN(AMT_T1), -1, -AMT_T1,0)) AMT_T1,      
                        DECODE( ARAP_TYPE,'1AR', DECODE( SIGN(AMT_T2), 1, AMT_T2,0), DECODE( SIGN(AMT_T2), -1, -AMT_T2,0)) AMT_T2,      
                        DECODE( ARAP_TYPE,'1AR', DECODE( SIGN(AMT_T3), 1, AMT_T3,0), DECODE( SIGN(AMT_T3), -1, -AMT_T3,0)) AMT_T3,
                        P_USER_ID,V_RANDOM_VALUE,P_GENERATE_DATE       
              FROM(     
                      SELECT  SUM(DECODE( DUE_DATE, V_DATE_T1, AMT, 0)) AMT_T1,     
                      SUM(DECODE( DUE_DATE,V_DATE_T2, AMT, 0)) AMT_T2,      
                      SUM(DECODE( DUE_DATE, V_DATE_T3, AMT, 0)) AMT_T3      
                      FROM(     
                               SELECT  DUE_DATE, DECODE(DB_CR_FLG,'D',1,-1) * CURR_VAL AS AMT       
                              FROM T_ACCOUNT_LEDGER     
                              WHERE SL_ACCT_CD = 'KPEI'     
                              AND DOC_DATE BETWEEN V_DATE_MIN4 AND P_REP_DATE     
                              AND RECORD_SOURCE = 'CG'      
                              AND DUE_DATE  BETWEEN V_DATE_T1 AND V_DATE_T3    
                              AND APPROVED_STS = 'A')     
                       ) T,     
                       ( SELECT '1AR' AS ARAP_TYPE FROM DUAL      
                      UNION ALL     
                      SELECT '2AP' FROM DUAL);     
              EXCEPTION
        WHEN OTHERS THEN
          V_ERROR_CD :=-25;
          V_ERROR_MSG :=SUBSTR('INSERT INTO R_AGING_ARAP_REGULAR KPEI '||SQLERRM,1,200);
          RAISE V_ERR; 
        END;

  END IF;

     --BROKER 
  IF P_OWNER='BROKER' THEN
  
        BEGIN
          INSERT INTO R_AGING_ARAP_REGULAR(ARAP_TYPE,CLIENT_CD,CLIENT_NAME,CLIENT_TYPE,BRANCH_CODE,
            AMT_T1,AMT_T2,AMT_T3,USER_ID,RAND_VALUE,GENERATE_DATE)
       SELECT ARAP_TYPE, SL_ACCT_CD CLIENT_CD, BROKER_NAME AS CLIENT_NAME, NULL CLIENT_TYPE_3, NULL BRANCH_CODE,      
                  DECODE( ARAP_TYPE,'1AR', DECODE( SIGN(AMT_T1), 1, AMT_T1,0), DECODE( SIGN(AMT_T1), -1, -AMT_T1,0)) AMT_T1,      
                  DECODE( ARAP_TYPE,'1AR', DECODE( SIGN(AMT_T2), 1, AMT_T2,0), DECODE( SIGN(AMT_T2), -1, -AMT_T2,0)) AMT_T2,      
                  DECODE( ARAP_TYPE,'1AR', DECODE( SIGN(AMT_T3), 1, AMT_T3,0), DECODE( SIGN(AMT_T3), -1, -AMT_T3,0)) AMT_T3,
                   P_USER_ID,V_RANDOM_VALUE,P_GENERATE_DATE       
        FROM(     
                SELECT SL_ACCT_CD,  SUM(DECODE( DUE_DATE, V_DATE_T1, AMT, 0)) AMT_T1,     
                SUM(DECODE( DUE_DATE,V_DATE_T2, AMT, 0)) AMT_T2,      
                SUM(DECODE( DUE_DATE, V_DATE_T3, AMT, 0)) AMT_T3      
                FROM(     
                         SELECT  SL_ACCT_CD, DUE_DATE, DECODE(DB_CR_FLG,'D',1,-1) * CURR_VAL AS AMT       
                        FROM T_ACCOUNT_LEDGER,      
                                ( SELECT GL_A FROM MST_GLA_TRX WHERE JUR_TYPE = 'BROK')     
                        WHERE GL_ACCT_CD = GL_A     
                        AND DOC_DATE BETWEEN V_DATE_MIN4 AND P_REP_DATE     
                        AND RECORD_SOURCE = 'CG'      
                        AND DUE_DATE  BETWEEN V_DATE_T1 AND V_DATE_T3      
                        AND APPROVED_STS = 'A')     
                  GROUP BY SL_ACCT_CD) T,     
                 ( SELECT '1AR' AS ARAP_TYPE FROM DUAL      
                UNION ALL     
                SELECT '2AP' FROM DUAL),      
                (       
                   SELECT BROKER_CD, MAX(BROKER_NAME) BROKER_NAME     
                   FROM(      
                        SELECT TRIM(BROKER_CD) BROKER_CD, BROKER_NAME FROM MST_BROKER     
                          UNION     
                          SELECT TRIM(CLIENT_CD), CLIENT_NAME FROM MST_CLIENT WHERE CLIENT_TYPE_1 = 'B')      
                    GROUP BY BROKER_CD)                               
                WHERE (AMT_T1 + AMT_T2 + AMT_T3 ) <> 0      
                AND SL_ACCT_CD = BROKER_CD;      
              EXCEPTION
        WHEN OTHERS THEN
          V_ERROR_CD :=-30;
          V_ERROR_MSG :=SUBSTR('INSERT INTO R_AGING_ARAP_REGULAR BROKER '||SQLERRM,1,200);
          RAISE V_ERR; 
        END;

  END IF;
   
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
END SPR_AGING_ARAP_REGULAR;