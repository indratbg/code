create or replace PROCEDURE SP_AGING_MKBD51_103(
    P_REP_DATE DATE,
    P_USER_ID  VARCHAR2,
    P_RAND_VALUE OUT NUMBER,
    P_ERROR_CODE OUT NUMBER,
    P_ERROR_MSG OUT VARCHAR2)
IS
  V_ERROR_CODE   NUMBER(5);
  V_ERROR_MSG    VARCHAR2(200);
  V_ERR          EXCEPTION;
  V_RANDOM_VALUE NUMBER(10);
  V_BGN_DATE DATE;
  V_BGN_STOCK VARCHAR2(35):='%';
  V_END_STOCK VARCHAR2(35):='_';
  V_BGN_CLIENT VARCHAR2(12):='%';
  V_END_CLIENT VARCHAR2(12):='_';
BEGIN

  V_RANDOM_VALUE := ABS(DBMS_RANDOM.RANDOM);
  
  BEGIN
    SP_RPT_REMOVE_RAND('R_MKBD51_103_AR',V_RANDOM_VALUE,V_ERROR_MSG,V_ERROR_CODE);
  EXCEPTION
  WHEN OTHERS THEN
    V_ERROR_CODE  := -10;
    V_ERROR_MSG := SUBSTR('SP_RPT_REMOVE_RAND '||V_ERROR_MSG||SQLERRM(SQLCODE),1,200);
    RAISE V_err;
  END;
  
  
  IF V_ERROR_CODE  <0 THEN
    V_ERROR_CODE  := -20;
    V_ERROR_MSG := SUBSTR('SP_RPT_REMOVE_RAND'||V_ERROR_MSG,1,200);
    RAISE V_ERR;
  END IF;
  
  BEGIN
    INSERT
    INTO R_MKBD51_103_AR
      (
        REP_DATE, CLIENT_NAME,SID, CLIENT_CD, LESS4, T4, T5, T6, T7, MORE7, TOTAL, JAMINAN, MARGIN_YN, RAND_VALUE, USER_ID, GENERATE_DATE
      )
    SELECT P_REP_DATE, M.CLIENT_NAME, M.SID,A.CLIENT_CD, LESS4_AMT, T4_AMT, T5_AMT, T6_AMT, T7_AMT, MORE7_AMT, LESS4_AMT + T4_AMT + T5_AMT +T6_AMT + T7_AMT+ MORE7_AMT AS JUMLAH , NULL, DECODE(M.CLIENT_TYPE_3,'M','Y','N') MARGIN_YN, V_RANDOM_VALUE, P_USER_ID, SYSDATE GENERATE_DATE
    FROM
      (
        SELECT CLIENT_CD, SUM(LESS4_AMT) LESS4_AMT, SUM( T4_AMT) T4_AMT, SUM( T5_AMT) T5_AMT, SUM( T6_AMT) T6_AMT, SUM( T7_AMT) T7_AMT, SUM( MORE7_AMT) MORE7_AMT
        FROM
          (
            SELECT CLIENT_CD, OUTS_AMT, DOC_DATE, DECODE( SIGN(WORK_DAYS - 4), -1,OUTS_AMT,0) LESS4_AMT, DECODE(WORK_DAYS, 4,OUTS_AMT,0) T4_AMT, DECODE(WORK_DAYS, 5,OUTS_AMT,0) T5_AMT, DECODE(WORK_DAYS, 6,OUTS_AMT,0) T6_AMT, DECODE(WORK_DAYS, 7,OUTS_AMT,0) T7_AMT, DECODE(SIGN(WORK_DAYS - 7), 1,OUTS_AMT,0) MORE7_AMT
            FROM
              (
                SELECT CLIENT_CD, OUTS_AMT, DOC_DATE, GET_WORK_DAYS(DOC_DATE,P_REP_DATE) AS WORK_DAYS
                FROM R_OUTS_ARAP_CLIENT
                WHERE RAND_VALUE='120' and user_id='SA' AND GL_ACCT_CD='1424'
              )
          )
        GROUP BY CLIENT_CD
      )
      A, MST_CLIENT M
    WHERE A.CLIENT_CD = M.CLIENT_CD
    ORDER BY 1;
  EXCEPTION
  WHEN OTHERS THEN
    V_ERROR_CODE:=-20;
    V_ERROR_MSG :=SUBSTR('INSERT INTO R_MKBD51_103_AR '||SQLERRM,1,200);
    RAISE V_ERR;
  END;
  
  V_BGN_DATE :=TO_DATE('01'||TO_CHAR(P_REP_DATE,'MMYYYY'),'DDMMYYYY');
BEGIN
SPR_MKBD51_103_STK(
    V_BGN_DATE,
    P_REP_DATE,
    V_BGN_STOCK,
    V_END_STOCK,
    V_BGN_CLIENT,
    V_END_CLIENT,
    P_USER_ID,
    SYSDATE,
    V_RANDOM_VALUE,
    V_ERROR_CODE,
    V_ERROR_MSG);
EXCEPTION
  WHEN OTHERS THEN
    V_ERROR_CODE:=-40;
    V_ERROR_MSG :=SUBSTR('CALL SPR_MKBD51_103_STK '||SQLERRM,1,200);
    RAISE V_ERR;
  END;

  IF V_ERROR_CODE<0 THEN
 	V_ERROR_CODE:=-45;
    V_ERROR_MSG :=SUBSTR('CALL SPR_MKBD51_103_STK '||V_ERROR_MSG,1,200);
    RAISE V_ERR;
  END IF;



  P_ERROR_CODE :=1;
  P_ERROR_MSG  :='';
  P_RAND_VALUE :=V_RANDOM_VALUE;
  
EXCEPTION
WHEN V_ERR THEN
  ROLLBACK;
  P_ERROR_CODE :=V_ERROR_CODE;
  P_ERROR_MSG  :=V_ERROR_MSG;
WHEN OTHERS THEN
  ROLLBACK;
  P_ERROR_CODE:=-1;
  P_ERROR_MSG :=SUBSTR(SQLERRM,1,200);
  RAISE;
END SP_AGING_MKBD51_103;