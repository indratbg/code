create or replace PROCEDURE SPR_BOND_TRX_SUMMARY(
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

  v_random_value := ABS(dbms_random.random);
  BEGIN
    SP_RPT_REMOVE_RAND('R_BOND_TRX_SUMMARY',V_RANDOM_VALUE,V_ERROR_MSG,V_ERROR_CD);
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
    INTO R_BOND_TRX_SUMMARY
      (
        TRX_ID, TRX_SEQ_NO ,SELLER ,BUYER ,TRADE_DATE ,SETTLE_DATE ,INSTRUMENT ,VALUE ,BUY_PRICE ,
        SELL_PRICE ,SPREAD_PERC ,SPREAD_NOMINAL ,USER_ID ,RAND_VALUE ,GENERATE_DATE
      )
    SELECT A.TRX_ID,NVL(a.trx_seq_no,b.trx_seq_no)trx_seq_no,A.SELLER,B.BUYER,A.TRADE_DATE,A.SETTLE_DATE,A.INSTRUMENT,
      CASE
        WHEN a.buy_seq_cnt=1
        THEN b.VALUE
        ELSE a.value
      END value,A.BUY_PRICE,B.SELL_PRICE, (B.SELL_PRICE-A.BUY_PRICE)SPREAD_PERC, ((B.SELL_PRICE-A.BUY_PRICE) *
      CASE
        WHEN a.buy_seq_cnt=1
        THEN b.VALUE
        ELSE a.value
      END)/100 SPREAD_NOMINAL, P_USER_ID,V_RANDOM_VALUE,P_GENERATE_DATE
    FROM
      (
        SELECT TRX_ID,TRX_SEQ_NO,A.TRX_TYPE,a.lawan SELLER, NULL BUYER, TRX_DATE TRADE_DATE, VALUE_DT AS SETTLE_DATE, BOND_CD INSTRUMENT,
        NOMINAL AS VALUE, PRICE BUY_PRICE, PRICE SELL_PRICE, COUNT(DISTINCT buy_trx_seq)over(partition BY trx_id)buy_seq_cnt
        FROM t_bond_trx A
        WHERE trx_dATE BETWEEN P_BGN_DATE AND P_END_DATE
        AND TRX_TYPE      ='B'
        AND A.APPROVED_STS='A'
        AND LAWAN_TYPE   <>'I'
      )
      A, (
        SELECT TRX_ID,TRX_SEQ_NO,A.TRX_TYPE,NULL SELLER, a.lawan BUYER, MIN(TRX_DATE)OVER(PARTITION BY TRX_ID) TRADE_DATE,
        VALUE_DT AS SETTLE_DATE, BOND_CD INSTRUMENT, NOMINAL AS VALUE, PRICE BUY_PRICE, PRICE SELL_PRICE , 
        COUNT(DISTINCT buy_trx_seq)over(partition BY trx_id)buy_seq_cnt
        FROM t_bond_trx A
        WHERE trx_dATE BETWEEN P_BGN_DATE AND P_END_DATE
        AND TRX_TYPE      ='S'
        AND A.APPROVED_STS='A'
        AND LAWAN_TYPE   <>'I'
      )
      B
    WHERE A.instrument=B.instrument(+)
    AND A.TRX_ID      =B.TRX_ID(+)
    ORDER BY TO_NUMBER(A.TRX_ID),A.trx_seq_no;
  EXCEPTION
  WHEN OTHERS THEN
    V_ERROR_CD  :=-30;
    V_ERROR_MSG := SUBSTR('INSERT INTO R_BOND_TRX_SUMMARY '||SQLERRM(SQLCODE),1,200);
    RAISE V_ERR;
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
END SPR_BOND_TRX_SUMMARY;