create or replace PROCEDURE SPR_AVAILABLE_ASSETS(
    P_REP_DATE      DATE,
    P_USER_ID       VARCHAR2,
    P_GENERATE_DATE DATE,
    P_RAND_VALUE OUT NUMBER,
    P_ERROR_CODE OUT NUMBER,
    P_ERROR_MSG OUT VARCHAR2)
IS
  V_ERROR_CODE   NUMBER(5);
  V_ERROR_MSG    VARCHAR2(200);
  V_ERR          EXCEPTION;
  V_RANDOM_VALUE NUMBER(10);
  V_BGN_BAL      DATE;
BEGIN

  V_RANDOM_VALUE := ABS(DBMS_RANDOM.RANDOM);
  BEGIN
    SP_RPT_REMOVE_RAND('R_AVAILABLE_ASSETS',V_RANDOM_VALUE,V_ERROR_MSG,V_ERROR_CODE);
  EXCEPTION
  WHEN OTHERS THEN
    V_ERROR_CODE := -10;
    V_ERROR_MSG  := SUBSTR('SP_RPT_REMOVE_RAND '||V_ERROR_MSG||SQLERRM(SQLCODE),1,200);
    RAISE V_err;
  END;
  
  IF V_ERROR_CODE <0 THEN
    V_ERROR_CODE := -20;
    V_ERROR_MSG  := SUBSTR('SP_RPT_REMOVE_RAND'||V_ERROR_MSG,1,200);
    RAISE V_ERR;
  END IF;
  
  V_BGN_BAL :=TO_DATE('01'||TO_CHAR(P_REP_DATE,'MMYYYY'),'DDMMYYYY');
    
  BEGIN
    INSERT
    INTO R_AVAILABLE_ASSETS
      (
        SL_ACCT_CD, ACCT_NAME, BEG_BAL, DEBIT, CREDIT, END_BAL, AVAIL_ASSET, RAND_VALUE, USER_ID, GENERATE_DATE, BGN_BAL_DATE, MUTASI_DATE
      )
    SELECT M.SL_A, TRIM(m.acct_name)ACCT_NAME, SUM(NVL(a.beg_bal,0)) beg_bal, SUM(NVL(A.debit,0)) debit, SUM(NVL(A.credit,0)) credit, SUM(NVL(a.beg_bal,0) + NVL(A.debit,0) - NVL(A.credit,0)) end_bal,
    DECODE(SIGN(SUM(NVL(a.beg_bal,0))-SUM(NVL(A.credit,0))),-1,0,(SUM(NVL(a.beg_bal,0))-SUM(NVL(A.credit,0) )) ) AVAIL_BAL, V_RANDOM_VALUE, P_USER_ID,P_GENERATE_DATE,
    P_REP_DATE-1,P_REP_DATE
    FROM
      (
        SELECT a.GL_ACCT_CD, a.sl_acct_cd, 0 beg_bal, (DECODE(a.db_cr_flg,'D',NVL(a.curr_val,0),0)) debit, (DECODE(a.db_cr_flg,'D',0,NVL(a.curr_val,0))) credit
        FROM t_account_ledger a
        WHERE a.doc_date      = P_REP_DATE
        AND trim(a.gl_acct_cd)='1200'
        AND a.approved_sts   <> 'C'
        AND a.approved_sts   <> 'E'
        UNION ALL
        SELECT b.GL_ACCT_CD, b.sl_acct_cd, NVL(b.deb_obal,0) - NVL(b.cre_obal,0) beg_bal, 0,0
        FROM t_day_trs b
        WHERE b.trs_dt        = V_BGN_BAL
        AND trim(b.gl_acct_cd)='1200'
        UNION ALL
        SELECT d.GL_ACCT_CD, d.sl_acct_cd, (DECODE(d.db_cr_flg,'D',1,-1) * NVL(d.curr_val,0)) mvmt, 0, 0
        FROM t_account_ledger d
        WHERE d.doc_date BETWEEN V_BGN_BAL AND (P_REP_DATE - 1)
        AND trim(d.gl_acct_cd)='1200'
        AND d.approved_sts    = 'A'
      )
      A, (
        SELECT gl_a, acct_name main_acct_name
        FROM mst_gl_account
        WHERE sl_a = '000000'
      )
      C, (
        SELECT gl_a, sl_a, acct_name
        FROM mst_gl_account
        WHERE PRT_TYPE              <> 'S'
        AND NVL(acct_type,'123456') <> 'LRTHIS'--30AUG2016
        AND trim(gl_a)               ='1200'
      )
      M
    WHERE M.gl_a = A.gl_acct_cd
    AND M.sl_a   = A.sl_acct_cd
    AND M.gl_a   = C.gl_a
    GROUP BY M.GL_A, M.sl_a, m.acct_name, c.main_acct_name
    HAVING (SUM(NVL(A.debit,0)) <> 0
    OR SUM(NVL(A.credit,0))     <> 0
    OR SUM(NVL(A.beg_bal,0))    <> 0)
    ORDER BY 1 ;
  EXCEPTION
  WHEN OTHERS THEN
    V_ERROR_CODE := -3;
    V_ERROR_MSG  := SUBSTR('INSERT INTO R_AVAILABLE_ASSETS '||SQLERRM(SQLCODE),1,200);
    RAISE V_err;
  END;
  
  COMMIT;
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
END SPR_AVAILABLE_ASSETS;