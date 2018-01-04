create or replace PROCEDURE SPR_TMP_CLIENT_MKBD51_103(
    P_BGN_DATE      DATE,
    P_END_DATE      DATE,
    P_GL_A VARCHAR2,
    P_USER_ID       VARCHAR2,
    P_GENERATE_DATE DATE,
    P_RANDOM_VALUE  NUMBER,
    P_ERROR_CD OUT NUMBER,
    P_ERROR_MSG OUT VARCHAR2 )
AS
  V_ERR           EXCEPTION;
  V_ERROR_CD      NUMBER(5);
  V_ERROR_MSG     VARCHAR2(200);
  V_RANDOM_VALUE  NUMBER(10);
  V_BGN_BAL       DATE;
  v_bgn_date_min1 DATE;
  V_BROKER_CD     VARCHAR2(2);
BEGIN

  V_RANDOM_VALUE := ABS(DBMS_RANDOM.RANDOM);
  
  BEGIN
    SP_RPT_REMOVE_RAND('TMP_CLIENT_MKBD51_103',P_RANDOM_VALUE,V_ERROR_MSG,V_ERROR_CD);
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
  
  V_BGN_BAL := TO_DATE('01'||TO_CHAR(P_END_DATE,'MMYYYY'),'DDMMYYYY');
  
  BEGIN
    INSERT
    INTO TMP_CLIENT_MKBD51_103
      (
        SL_ACCT, RAND_VALUE, USER_ID, GENERATE_DATE
      )
    SELECT sl_acct_cd,P_RANDOM_VALUE,P_USER_ID,P_GENERATE_DATE
    FROM
      (
        SELECT a.sl_acct_cd , SUM(DECODE(DB_CR_FLG,'D',1,-1)*CURR_VAL) MVMT
        FROM t_account_ledger a
        WHERE a.doc_date BETWEEN P_BGN_DATE AND P_END_DATE
        AND trim(a.gl_acct_cd) =P_GL_A
        AND a.approved_sts     = 'A'
        GROUP BY SL_ACCT_CD
        UNION ALL
        SELECT b.sl_acct_cd, SUM(NVL(b.deb_obal,0) - NVL(b.cre_obal,0)) BEG_BAL
        FROM t_day_trs b
        WHERE b.trs_dt         = V_BGN_BAL
        AND trim(b.gl_acct_cd) =P_GL_A
        GROUP BY SL_aCCT_CD
      )
    GROUP BY SL_ACCT_CD
    HAVING SUM(MVMT)<>0
    ORDER BY 1;
  EXCEPTION
  WHEN OTHERS THEN
    V_ERROR_CD  :=-40;
    V_ERROR_MSG := SUBSTR('INSERT INTO TMP_CLIENT_MKBD51_103 '||SQLERRM(SQLCODE),1,200);
    RAISE V_ERR;
  END;
  
  P_ERROR_CD  := 1 ;
  P_ERROR_MSG := '';
  
EXCEPTION
WHEN V_ERR THEN
  ROLLBACK;
  P_ERROR_MSG := V_ERROR_MSG;
  P_ERROR_CD  := V_ERROR_CD;
WHEN OTHERS THEN
  P_ERROR_CD  := -1 ;
  P_ERROR_MSG := SUBSTR(SQLERRM(SQLCODE),1,200);
  RAISE;
END SPR_TMP_CLIENT_MKBD51_103;