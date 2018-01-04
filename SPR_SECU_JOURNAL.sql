create or replace 
PROCEDURE SPR_SECU_JOURNAL(
    P_FROM_DATE     DATE,
    P_TO_DATE       DATE,
    P_DOC_NUM       VARCHAR2,
    P_USER_ID       VARCHAR2,
    P_GENERATE_DATE DATE,
    P_RANDOM_VALUE OUT NUMBER,
    P_ERROR_MSG OUT VARCHAR2,
    P_ERROR_CD OUT NUMBER)
IS
  V_ERROR_MSG    VARCHAR2(200);
  V_ERROR_CD     NUMBER(10);
  v_random_value NUMBER(10);
  V_ERR          EXCEPTION;
BEGIN
  v_random_value := ABS(dbms_random.random);
  
  BEGIN
    SP_RPT_REMOVE_RAND('R_SECU_JOURNAL',V_RANDOM_VALUE,V_ERROR_MSG,V_ERROR_CD);
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
    INTO R_SECU_JOURNAL
      ( FROM_DATE,
      TO_DATE,
        DOC_NUM,
        DOC_DATE,
        DOC_REM,
        CLIENT_CD,
        STK_CD,
        seqno,
        QTY,
        price,
        DB_CR_FLG,
        SL_CODE,
        SL_DESC,
        USER_ID,
        RAND_VALUE,
        GENERATE_DATE
      )
    SELECT P_FROM_DATE,
    P_TO_DATE,
    doc_num,
      doc_dt,
      doc_rem,
      client_Cd,
      stk_cd,
      seqno,
      total_share_qty + withdrawn_share_qty AS qty,
      price,
      db_cr_flg,
      sl_code,
      sl_desc,
      P_USER_ID,
      v_random_value,
      P_GENERATE_DATE
    FROM T_STK_MOVEMENT,
      MST_SECURITIES_LEDGER
    WHERE doc_dt BETWEEN P_FROM_DATE AND P_TO_DATE
    AND doc_num                   like '%'||P_DOC_NUM
    AND T_STK_MOVEMENT.gl_acct_cd = MST_SECURITIES_LEDGER.gl_acct_Cd
    AND doc_dt BETWEEN ver_bgn_dt AND ver_end_Dt
    ORDER BY seqno;
  EXCEPTION
  WHEN OTHERS THEN
    V_ERROR_CD  := -30;
    V_ERROR_MSG := SUBSTR('INSERT R_SECU_JOURNAL '||V_ERROR_MSG||SQLERRM(SQLCODE),1,200);
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
END SPR_SECU_JOURNAL;