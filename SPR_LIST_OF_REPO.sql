CREATE OR REPLACE
PROCEDURE SPR_LIST_OF_REPO(
    P_BGN_DATE      DATE,
    P_END_DATE      DATE,
    P_BGN_STOCK     VARCHAR2,
    P_END_STOCK     VARCHAR2,
    P_BGN_CLIENT    VARCHAR2,
    P_END_CLIENT    VARCHAR2,
    P_BGN_BROKER    VARCHAR2,
    P_END_BROKER    VARCHAR2,
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
    SP_RPT_REMOVE_RAND('R_LIST_OF_REPO',V_RANDOM_VALUE,V_ERROR_MSG,V_ERROR_CD);
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
    INTO R_LIST_OF_REPO
      (
        DOC_NUM ,
        DOC_DT ,
        CLIENT_CD ,
        CLIENT_NAME ,
        STK_CD ,
        REPO_JUAL ,
        RETURN_JUAL ,
        REPO_BELI ,
        RETURN_BELI ,
        BROKER ,
        RETURN_DT ,
        USER_ID ,
        RAND_VALUE ,
        GENERATE_DATE,
        BGN_DATE,
        END_DATE
      )
    SELECT a.DOC_NUM,
      a.DOC_DT,
      a.CLIENT_CD,
      a.client_name,
      a.STK_CD,
      DECODE(a.acct_dbcr,'50C',a.TOTAL_SHARE_QTY,0) repo_jual,
      DECODE(b.acct_dbcr,'50D',b.TOTAL_SHARE_QTY,0) return_jual,
      DECODE(a.acct_dbcr,'09D',a.TOTAL_SHARE_QTY,0) repo_beli,
      DECODE(b.acct_dbcr,'09C',b.TOTAL_SHARE_QTY,0) return_beli,
      DECODE(NVL(a.ref_doc_num,'BROKER'),'BROKER',a.broker,'') broker,
      b.doc_dt AS return_dt,
      P_USER_ID,
      V_RANDOM_VALUE,
      P_GENERATE_DATE,
      P_BGN_DATE,
      P_END_DATE
    FROM
      (SELECT doc_num,
        doc_dt,
        T_STK_MOVEMENT.client_cd,
        client_name,
        stk_cd,
        trim(gl_acct_cd)
        ||db_cr_flg AS acct_dbcr,
        total_share_qty,
        ref_doc_num,
        broker
      FROM T_STK_MOVEMENT,
        mst_client
      WHERE SUBSTR(DOC_NUM,5,3) = 'JVA'
      AND doc_dt BETWEEN P_BGN_DATE AND P_END_DATE
      AND T_STK_MOVEMENT.client_cd BETWEEN P_BGN_CLIENT AND P_END_CLIENT
      AND stk_cd BETWEEN P_BGN_STOCK AND P_END_STOCK
      AND NVL(broker,'X') BETWEEN P_BGN_BROKER AND P_END_BROKER
      AND gl_acct_cd                  IN ('09','50')
      AND doc_stat                     = '2'
      AND T_STK_MOVEMENT.approved_stat = 'A'
      AND jur_type                     = 'REREPOC'
      AND T_STK_MOVEMENT.client_cd     = mst_client.client_cd
      ) a,
      (SELECT doc_num,
        doc_dt,
        client_cd,
        stk_cd,
        ref_doc_num,
        broker,
        trim(gl_acct_cd)
        ||db_cr_flg AS acct_dbcr,
        total_share_qty
      FROM T_STK_MOVEMENT
      WHERE SUBSTR(DOC_NUM,5,3) = 'JVA'
      AND doc_dt                > P_BGN_DATE
      AND client_cd BETWEEN P_BGN_CLIENT AND P_END_CLIENT
      AND stk_cd BETWEEN P_BGN_STOCK AND P_END_STOCK
      AND gl_acct_cd   IN ('09','50')
      AND doc_stat      = '2'
      AND approved_stat = 'A'
      AND jur_type      = 'REREPOCRTN'
      ) b
    WHERE a.doc_num = b.ref_doc_num(+)
    ORDER BY doc_dt ;
  EXCEPTION
  WHEN OTHERS THEN
    V_ERROR_CD  := -30;
    V_ERROR_MSG := SUBSTR('INSERT R_LIST_OF_REPO '||V_ERROR_MSG||SQLERRM(SQLCODE),1,200);
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
END SPR_LIST_OF_REPO;