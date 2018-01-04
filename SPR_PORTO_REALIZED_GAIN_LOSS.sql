CREATE OR REPLACE PROCEDURE SPR_PORTO_REALIZED_GAIN_LOSS(
    P_BGN_DATE DATE,
    P_END_DATE DATE,
    P_BGN_CLIENT mst_client.CLIENT_CD%TYPE,
    P_END_CLIENT mst_client.CLIENT_CD%TYPE,
    P_BGN_STK VARCHAR2,
    P_END_STK VARCHAR2,
    P_BGN_REM MST_SALES.REM_CD%TYPE,
    P_END_REM MST_SALES.REM_CD%TYPE,
    P_BGN_BRANCH MST_CLIENT.BRANCH_CODE%TYPE,
    P_END_BRANCH MST_CLIENT.BRANCH_CODE%TYPE,
    P_USER_ID       VARCHAR2,
    P_GENERATE_DATE DATE,
    P_RANDOM_VALUE OUT NUMBER,
    P_ERROR_CD OUT NUMBER,
    P_ERROR_MSG OUT VARCHAR2 )
IS
  V_ERROR_MSG    VARCHAR2(200);
  V_ERROR_CD     NUMBER(10);
  V_RANDOM_VALUE NUMBER(10);
  V_ERR          EXCEPTION;
BEGIN
  v_random_value := ABS(dbms_random.random);
  BEGIN
    SP_RPT_REMOVE_RAND('R_REALIZED_GAIN_LOSS',V_RANDOM_VALUE,V_ERROR_MSG,
    V_ERROR_CD);
  EXCEPTION
  WHEN OTHERS THEN
    V_ERROR_CD  := -10;
    V_ERROR_MSG := SUBSTR('SP_RPT_REMOVE_RAND '||V_ERROR_MSG||SQLERRM(SQLCODE),
    1,200);
    RAISE V_err;
  END;
  IF V_ERROR_CD  <0 THEN
    V_ERROR_CD  := -20;
    V_ERROR_MSG := SUBSTR('SP_RPT_REMOVE_RAND'||V_ERROR_MSG,1,200);
    RAISE V_ERR;
  END IF;
  BEGIN
    INSERT
    INTO
      R_REALIZED_GAIN_LOSS
      (
        CLIENT_CD ,
        CLIENT_NAME ,
        CONTR_DT ,
        STK_CD ,
        QUANTITY ,
        SELL_AMT ,
        BUY_VALUE ,
        BUY_PRICE ,
        REM_CD ,
        BRCH ,
        SEQNO ,
        AVG_SELL_PRICE ,
        RAND_VALUE ,
        USER_ID ,
        GENERATE_DATE,
        BGN_DATE,
        END_DATE
      )
    -- select *
    --from(
    SELECT
      m.client_cd,
      m.client_name,
      a.avg_dt contr_dt,
      NVL(c.stk_cd_new,a.stk_cd) stk_cd,
      a.real_qty quantity,
      (a.real_qty / a.sell_qty * a.sell_amt) sell_amt,
      a.real_qty  * a.avg_buy_price buy_value,
      a.avg_buy_price buy_price,
      m.rem_cd,
      m.branch_code brch,
      a.seqno,
      (a.sell_amt / a.sell_qty) AS avg_sell_price,
      V_RANDOM_VALUE,
      P_USER_ID,
      P_GENERATE_DATE,
      P_BGN_DATE,
      P_END_DATE
    FROM
      t_avg_price a,
      mst_client m,
      (
        SELECT
          stk_cd_old,
          stk_cd_new
        FROM
          T_CHANGE_STK_CD
        WHERE
          eff_Dt <= P_BGN_DATE
      )
      c
    WHERE
      NVL(a.real_qty,0) <> 0
    AND a.avg_dt BETWEEN P_BGN_DATE AND P_END_DATE
    AND a.client_cd BETWEEN P_BGN_CLIENT AND P_END_CLIENT
    AND a.stk_Cd BETWEEN P_BGN_STK AND P_END_STK
    AND a.client_Cd = m.client_cd
    AND m.rem_cd BETWEEN P_BGN_REM AND P_END_REM
    AND m.branch_code BETWEEN P_BGN_BRANCH AND P_END_BRANCH
    AND a.stk_Cd = c.stk_cd_old(+) ;
    --)
    --order by  client_cd,  stk_Cd, contr_dt ,  seqno
  EXCEPTION
  WHEN OTHERS THEN
    V_ERROR_CD  := -50;
    V_ERROR_MSG := SUBSTR('INSERT R_REALIZED_GAIN_LOSS '||V_ERROR_MSG||SQLERRM(
    SQLCODE),1,200);
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
END SPR_PORTO_REALIZED_GAIN_LOSS;