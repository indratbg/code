create or replace PROCEDURE SPR_RISK_MGMT_PORTO(
    P_TRX_DATE      DATE,
    P_PRICE_DATE    DATE,
    P_BGN_MARGIN    VARCHAR2,
    P_END_MARGIN    VARCHAR2,
    P_BGN_CLIENT    VARCHAR2,
    P_END_CLIENT    VARCHAR2,
    P_BGN_BRANCH    VARCHAR2,
    P_END_BRANCH    VARCHAR2,
    P_BGN_REM       VARCHAR2,
    P_END_REM       VARCHAR2,
    P_BGN_STOCK     VARCHAR2,
    P_END_STOCK     VARCHAR2,
    P_REPORT_TYPE VARCHAR2,--PORTFOLIO/ BUYBACK
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
  V_BAL_DATE     DATE;
BEGIN

  V_RANDOM_VALUE := ABS(DBMS_RANDOM.RANDOM);
  
  BEGIN
    SP_RPT_REMOVE_RAND('R_RISK_PORTO',V_RANDOM_VALUE,V_ERROR_MSG,V_ERROR_CD);
  EXCEPTION
  WHEN OTHERS THEN
    V_ERROR_CD  := -10;
    V_ERROR_MSG := SUBSTR('SP_RPT_REMOVE_RAND '||V_ERROR_MSG||SQLERRM(SQLCODE),1,200);
    RAISE V_err;
  END;
  
  V_BAL_DATE := TO_DATE('01'||TO_CHAR(P_TRX_DATE,'MMYYYY'),'DDMMYYYY');
  
  BEGIN
    INSERT
    INTO R_RISK_PORTO
      (
        BRANCH_CODE ,BRCH_NAME ,REM_CD ,REM_NAME ,CLIENT_CD ,CLIENT_NAME ,STK_CD ,BAL_QTY ,STK_BIDP ,BUYBACK ,PORTFOLIO ,LAYER ,
        MRG_STK_CAP ,PRTFL_D ,USER_ID ,RAND_VALUE ,GENERATE_DATE
      )
    SELECT branch_code, brch_name, rem_cd,rem_name,client_cd, client_name, stk_cd, BAL_QTY, STK_BIDP,
    (DECODE(SIGN(BAL_QTY),1,0,-1 * bal_qty) * STK_BIDP) AS buyback, (DECODE(SIGN(BAL_QTY),1,bal_qty,0) * STK_BIDP) AS Portfolio,
    LAYER, MRG_STK_CAP, DECODE(SIGN(BAL_QTY),1,BAL_QTY,0) * STK_BIDP * MRG_STK_CAP / 100 AS PRTFL_D, P_USER_ID, V_RANDOM_VALUE, P_GENERATE_DATE
    FROM
      (
        SELECT c.branch_code, c.brch_name, c.rem_cd,c.rem_name,b.client_cd, c.client_name, b.stk_cd,
        NVL(b.theo_qty,0) bal_qty, p.stk_bidp, p.LAYER, DECODE(c.margin_cd,'M',p.margin_stk_cap, p.regular_stk_cap) mrg_stk_cap
        FROM
          (
            SELECT client_cd, stk_cd, SUM(beg_theo +theo_mvmt) theo_qty
            FROM
              (
                SELECT client_cd, stk_cd, 0 beg_theo, (NVL(DECODE(SUBSTR(doc_num,5,2),'BR',1,'JR',1,'BI',1,'JI',1,'RS',1,'WS',1,0) * DECODE(db_cr_flg,'D',1,-1) * (total_share_qty + withdrawn_share_qty),0)) theo_mvmt
                FROM T_STK_MOVEMENT
                WHERE doc_dt BETWEEN V_BAL_DATE AND P_TRX_DATE
                AND stk_cd BETWEEN P_BGN_STOCK AND P_END_STOCK
                 AND client_cd BETWEEN P_BGN_CLIENT AND P_END_CLIENT
                AND gl_acct_cd IN ('10','12','13','14','51')
                AND doc_stat    = '2'
                AND s_d_type   <> 'V'
                UNION ALL
                SELECT client_cd, stk_cd, beg_bal_qty, 0 theo_mvmt
                FROM T_STKBAL
                WHERE bal_dt = V_BAL_DATE
                AND client_cd BETWEEN P_BGN_CLIENT AND P_END_CLIENT
                AND stk_cd BETWEEN P_BGN_STOCK AND P_END_STOCK
              )
            GROUP BY client_cd, stk_cd
          )
          b, (
            SELECT m.client_cd, m.client_name, m.branch_code, m.rem_cd, l.margin_cd, b.brch_name, s.rem_name
            FROM MST_CLIENT m, LST_TYPE3 l, MST_BRANCH b, MST_SALES s
            WHERE m.client_cd BETWEEN P_BGN_CLIENT AND P_END_CLIENT
            AND m.client_type_3 = l.cl_type3
            AND l.margin_cd BETWEEN P_BGN_MARGIN AND P_END_MARGIN
            AND trim(m.BRANCH_CODE) BETWEEN P_BGN_BRANCH AND P_END_BRANCH
            AND m.REM_CD BETWEEN P_BGN_REM AND P_END_REM
            AND trim(m.branch_code) = trim(b.brch_cd)
            AND m.rem_cd            = s.rem_cd
          )
          c, (
            SELECT MST_COUNTER.STK_CD, NVL(T_CLOSE_PRICE.STK_BIDP,0) STK_BIDP, MST_COUNTER.LAYER, MST_COUNTER.MRG_STK_CAP AS regular_stk_cap, 
            DECODE(SIGN(P_PRICE_DATE - TO_DATE('01/01/09','dd/mm/yy')), 1, NVL(V_MARGIN_STK.MRG_STK_CAP, 0), MST_COUNTER.MRG_STK_CAP) AS margin_stk_cap
            FROM
              (
                SELECT stk_cd,stk_bidp FROM T_CLOSE_PRICE WHERE STK_DATE = P_PRICE_DATE
              )
              T_CLOSE_PRICE, MST_COUNTER, V_MARGIN_STK
            WHERE MST_COUNTER.STK_cD BETWEEN P_BGN_STOCK AND P_END_STOCK
            AND MST_COUNTER.STK_CD = T_CLOSE_PRICE.STK_CD (+)
            AND MST_COUNTER.STK_CD = V_MARGIN_STK.STK_CD (+)
          )
          p
        WHERE b.client_cd = c.client_cd
        AND b.stk_cd      = p.stk_cd (+)
        AND b.theo_qty   <> 0
        AND ((b.theo_qty>0 AND P_REPORT_TYPE='PORTFOLIO') OR ((DECODE(SIGN(b.theo_qty),1,0,-1 * B.theo_qty) * STK_BIDP)<0 AND P_REPORT_TYPE='BUYBACK') )
      );
  EXCEPTION
  WHEN OTHERS THEN
    V_ERROR_CD  := -50;
    V_ERROR_MSG := SUBSTR('INSERT INTO R_PORTFOLIO '||SQLERRM(SQLCODE),1,200);
    RAISE V_err;
  END;
  
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
END SPR_RISK_MGMT_PORTO;