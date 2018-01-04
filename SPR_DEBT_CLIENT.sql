create or replace PROCEDURE SPR_DEBT_CLIENT(
    P_REP_DATE      DATE,
    P_BGN_CLIENT    VARCHAR2,
    P_END_CLIENT    VARCHAR2,
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
  V_BGN_DATE     DATE;
  V_ON_BALANCE   NUMBER;
  V_OFF_BALANCE  NUMBER;
  V_STK_JAMINAN  NUMBER;
  V_PRICE_DATE DATE;
  CURSOR CSR_DATA
  IS
    SELECT A.CLIENT_CD,A.SID,A.CIFS, A.CLIENT_NAME, B.BASIC_LIMIT
    FROM MST_CLIENT A,FOMH_CLIENT_LIMIT B
    WHERE A.CLIENT_CD=B.CLIENT_CD
    AND BASIC_LIMIT  >0
    AND A.CLIENT_CD BETWEEN P_BGN_CLIENT AND P_END_CLIENT
    AND A.APPROVED_STAT='A';
BEGIN

  V_RANDOM_VALUE := ABS(DBMS_RANDOM.RANDOM);
  
  BEGIN
    SP_RPT_REMOVE_RAND('R_DEBT_CLIENT',V_RANDOM_VALUE,V_ERROR_MSG,V_ERROR_CODE);
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
  
  V_BGN_DATE := GET_DOC_DATE(3,P_REP_DATE);
  V_BGN_DATE :=TO_DATE('01'||TO_CHAR(V_BGN_DATE,'MMYYYY'),'DDMMYYYY');
  
  BEGIN
   SELECT MAX(stk_date) INTO V_PRICE_DATE
              FROM t_close_price
              WHERE stk_date  <=P_REP_DATE
              AND approved_stat='A';
   EXCEPTION
  WHEN OTHERS THEN
    V_ERROR_CODE := -3;
    V_ERROR_MSG  := SUBSTR('SELECT PRICE DATE '||SQLERRM(SQLCODE),1,200);
    RAISE V_err;
  END;           
  
  FOR REC IN CSR_DATA
  LOOP
    BEGIN
      SELECT NVL(SUM(TOTAL_QTY*PRICE),0)
      INTO V_STK_JAMINAN
      FROM
        ( 
        SELECT STK_CD,SUM(BEG_BAL+MVMT) TOTAL_QTY FROM (
        SELECT client_cd, stk_cd, 0 beg_bal,                            
        (NVL(DECODE(SUBSTR(doc_num,5,2),'BR',1,'JR',1,'BI',1,'JI',1,'BO',1,'JO',1,'RS',1,'WS',1,0) *                          
        DECODE(db_cr_flg,'D',1,-1) *  (total_share_qty + withdrawn_share_qty),0)) mvmt                          
        FROM T_STK_MOVEMENT                             
        WHERE  DOC_DT BETWEEN V_BGN_DATE AND P_REP_DATE
        AND client_cd= REC.CLIENT_CD
        AND gl_acct_cd IN ('10','12','13','14','51')                            
        AND doc_stat    = '2'                             
        AND s_d_type <> 'V'                             
        UNION ALL                             
        SELECT client_cd, stk_cd, beg_bal_qty AS beg_bal, 0 mvmt                            
        FROM T_STKBAL                             
        WHERE bal_dt =V_BGN_DATE                        
        AND client_cd =REC.CLIENT_CD
        )
        GROUP BY STK_CD
        HAVING SUM(BEG_BAL+MVMT)>0
        )
        A, (
          SELECT stk_cd,
          CASE
          WHEN STK_BIDP>0
          THEN STK_BIDP
          ELSE STK_CLOS
          END PRICE
          FROM T_CLOSE_PRICE
          WHERE approved_stat='A'
          AND stk_date       =V_PRICE_DATE
        )
        B
      WHERE A.STK_CD=B.STK_CD;
    EXCEPTION
    WHEN OTHERS THEN
      V_ERROR_CODE:=-5;
      V_ERROR_MSG :=SUBSTR('SELECT JAMINAN STOCK'||SQLERRM,1,200);
      RAISE V_ERR;
    END;
    
    BEGIN
      SELECT SUM(bal_amt) + NVL(F_FUND_BAL(REC.CLIENT_CD, P_REP_DATE),0)
      INTO V_ON_BALANCE
      FROM
        (
          SELECT NVL(SUM(DECODE(db_cr_flg, 'D', curr_val, - curr_val)),0) bal_amt
          FROM T_ACCOUNT_LEDGER
          WHERE doc_date BETWEEN V_BGN_DATE AND P_REP_DATE
          and due_date<=P_REP_DATE
          AND approved_sts <> 'C'
          AND approved_sts <> 'E'
          AND sl_acct_cd    =REC.CLIENT_CD
          UNION ALL
          SELECT NVL(SUM(deb_obal - cre_obal),0) beg_bal
          FROM T_DAY_TRS
          WHERE trs_dt   = V_BGN_DATE
          AND sl_acct_cd =REC.CLIENT_CD
        );
    EXCEPTION
    WHEN OTHERS THEN
      V_ERROR_CODE:=-10;
      V_ERROR_MSG :=SUBSTR('SELECT ON BALANCE '||SQLERRM,1,200);
      RAISE V_ERR;
    END;
    
    IF V_ON_BALANCE <0 THEN
      V_ON_BALANCE :=0;
    END IF;
    
    V_OFF_BALANCE :=F_GET_DUE_FUNDBAL(REC.CLIENT_CD,P_REP_DATE);
    
    IF V_STK_JAMINAN >0 OR V_ON_BALANCE>0 OR V_OFF_BALANCE>0 THEN
    BEGIN
      INSERT
      INTO R_DEBT_CLIENT
        (
          SID, CIFS, CLIENT_CD,CLIENT_NAME, STK_JAMINAN, ON_BAL, OFF_BAL, RAND_VALUE, USER_ID, GENERATE_DATE, BASIC_LIM
        )
        VALUES
        (
          REC.SID,REC.CIFS,REC.CLIENT_CD,REC.CLIENT_NAME,V_STK_JAMINAN, V_ON_BALANCE,V_OFF_BALANCE, V_RANDOM_VALUE,P_USER_ID,P_GENERATE_DATE,
          REC.BASIC_LIMIT
        );
    EXCEPTION
    WHEN OTHERS THEN
      V_ERROR_CODE:=-20;
      V_ERROR_MSG :=SUBSTR('SELECT ON BALANCE '||SQLERRM,1,200);
      RAISE V_ERR;
    END;
    END IF;
  END LOOP;

BEGIN
  UPDATE R_DEBT_CLIENT R
SET TOT_AR =
  (
        SELECT SUM(on_bal+off_bal) tot_ar
        FROM R_DEBT_CLIENT
        WHERE rand_value=R.RAND_VALUE
        AND USER_ID = R.USER_ID
        AND CIFS = R.CIFS
        GROUP BY cifs
      )
WHERE RAND_VALUE=V_RANDOM_VALUE
AND USER_ID     =P_USER_ID
AND EXISTS (  SELECT 1
        FROM R_DEBT_CLIENT
        WHERE rand_value=R.RAND_VALUE
        AND USER_ID = R.USER_ID
        AND CIFS=R.CIFS
        GROUP BY cifs);
EXCEPTION
    WHEN OTHERS THEN
      V_ERROR_CODE:=-25;
      V_ERROR_MSG :=SUBSTR('UPDATE TOTAL AR R_DEBT_CLIENT '||SQLERRM,1,200);
      RAISE V_ERR;
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
END SPR_DEBT_CLIENT;