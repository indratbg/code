create or replace PROCEDURE SPR_MARGIN_TRX_CAPPING_ZERO(
    P_BGN_DATE      DATE,
    P_END_DATE      DATE,
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
    SP_RPT_REMOVE_RAND('R_MARGIN_TRX',V_RANDOM_VALUE,V_ERROR_MSG,V_ERROR_CD);
  EXCEPTION
  WHEN OTHERS THEN
    V_ERROR_CD  := -10;
    V_ERROR_MSG := SUBSTR('SP_RPT_REMOVE_RAND '||V_ERROR_MSG||SQLERRM(SQLCODE),1,200);
    RAISE V_err;
  END;
  BEGIN
    INSERT
    INTO R_MARGIN_TRX
      (
        CONTR_DT ,BRCH_CD ,REM_CD ,CLIENT_CD ,B_S ,STK_CD ,PRICE ,QTY ,LOT ,USER_ID ,RAND_VALUE ,GENERATE_DATE
      )
    SELECT contr_dt,brch_cd,rem_cd,client_cd, DECODE(SUBSTR(contr_num,5,1),'B','BUY','SELL') B_S, T.stk_cd, price, SUM(qty) qty,
    SUM(qty/100) lot, P_USER_ID, V_RANDOM_VALUE, P_GENERATE_DATE
    FROM t_contracts T, (
        SELECT stk_cd FROM mst_margin_stk
      )S
    WHERE CONTR_DT BETWEEN P_BGN_DATE AND P_END_DATE
    AND contr_stat='0'
    AND T.STK_CD  = S.STK_CD(+)
    AND S.STK_CD IS NULL
      --and stk_cd not in (select stk_cd from mst_margin_stk)
    AND SUBSTR(client_type,3,1)='M'
    GROUP BY contr_dt,brch_cd,rem_cd,client_cd, DECODE(SUBSTR(contr_num,5,1),'B','BUY','SELL'), T.stk_cd,price;
    --order by contr_dt,brch_cd,rem_cd,client_cd,stk_cd,price;
  EXCEPTION
  WHEN OTHERS THEN
    V_ERROR_CD  := -50;
    V_ERROR_MSG := SUBSTR('INSERT INTO R_MARGIN_TRX '||SQLERRM(SQLCODE),1,200);
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
END SPR_MARGIN_TRX_CAPPING_ZERO;