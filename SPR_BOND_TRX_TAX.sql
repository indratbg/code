CREATE OR REPLACE
PROCEDURE SPR_BOND_TRX_TAX(
    P_BGN_DATE      DATE,
    P_END_DATE      DATE,
    P_TRX_DATE_FLG  VARCHAR2,
    P_VALUE_DT_FLG  VARCHAR2,
    P_BGN_TRX_ID    VARCHAR2,
    P_END_TRX_ID    VARCHAR2,
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
  V_D_T1         DATE;
BEGIN
  V_RANDOM_VALUE := ABS(DBMS_RANDOM.RANDOM);
  BEGIN
    SP_RPT_REMOVE_RAND('R_BOND_TRX_TAX',V_RANDOM_VALUE,V_ERROR_MSG,V_ERROR_CD);
  EXCEPTION
  WHEN OTHERS THEN
    V_ERROR_CD  := -30;
    V_ERROR_MSG := SUBSTR('SP_RPT_REMOVE_RAND '||V_ERROR_MSG||SQLERRM(SQLCODE),1,200);
    RAISE V_err;
  END;
  IF V_ERROR_CD  <0 THEN
    V_ERROR_CD  := -40;
    V_ERROR_MSG := SUBSTR('SP_RPT_REMOVE_RAND'||V_ERROR_MSG,1,200);
    RAISE V_ERR;
  END IF;
  BEGIN
    INSERT
    INTO R_BOND_TRX_TAX
      (
        TRX_DATE ,
        TRX_ID ,
        SHORT_DESC ,
        TRANS_TYPE ,
        LAWAN_NAME ,
        NOMINAL ,
        MATURITY_DATE ,
        INTEREST_RATE ,
        FREQUENCY ,
        INT_RATE ,
        LAST_COUPON ,
        NEXT_COUPON ,
        PERIOD_DAYS ,
        VALUE_DT ,
        PRICE ,
        ACCRUED_DAYS ,
        PROCEED ,
        ACCRUED_INTEREST ,
        TOTAL_PROCEED ,
        CAPITAL_GAIN ,
        PURCHASED_PRICE ,
        NET_AMOUNT ,
        ACCT_6150 ,
        PREPAID ,
        CLIENTS ,
        PROFIT_BROKER ,
        CLIENTS_TAX_PAY ,
        BROKER_TAX_PAY ,
        BUKTI_PAJAK ,
        TRX_SEQ_NO ,
        TRX_ID_YYMM ,
        USER_ID ,
        RAND_VALUE ,
        GENERATE_DATE
      )
    SELECT trx_Date,
      trx_id,
      DECODE(MST_BOND.Bond_group_cd,'02',short_desc,T_BOND_TRX.Bond_cd) short_desc,
      DECODE(trx_type,'B','Buy','Sell') trans_type,
      lawan_name,
      nominal,
      maturity_date,
      MST_BOND.interest interest_Rate,
      DECODE(int_freq,'3 MONTHS',4,'SEMI-ANNUAL',2,1) frequency,
      T_BOND_TRX.int_rate * 100 int_rate,
      period_from last_coupon,
      period_to next_coupon,
      period_to - period_from AS period_days,
      value_dt,
      price,
      T_BOND_TRX.accrued_days,
      cost proceed,
      accrued_int accrued_interest,
      cost + accrued_int total_proceed,
      DECODE(trx_type,'B',DECODE(T_BOND_TRX.lawan_type,'I',capital_gain,0), capital_gain) capital_gain,
      buy_price purchased_price,
      net_amount,
      DECODE(trx_type,'S',capital_Gain - capital_tax,0)                                         AS acct_6150,
      DECODE(trx_type,'S', capital_tax,0)                                                       AS PREPAID,
      DECODE(trx_type,'B',DECODE(T_BOND_TRX.lawan_type,'I',capital_Gain - capital_tax,0),0)     AS CLIENTS,
      DECODE(T_BOND_TRX.lawan_type,'I', DECODE(trx_type,'S',capital_tax,0),0)                   AS PROFIT_BROKER,
      DECODE(T_BOND_TRX.lawan_type,'I', DECODE(trx_type,'B',capital_tax,0),0)                   AS CLIENTS_TAX_PAY,
      DECODE(trx_type,'B',DECODE(T_BOND_TRX.lawan_type,'I', 0,capital_tax + accrued_int_tax),0) AS BROKER_TAX_PAY,
      bukti_pajak,
      trx_seq_no,
      trx_id_yymm ,
      P_USER_ID,
      V_RANDOM_VALUE,
      P_GENERATE_DATE
    FROM T_BOND_TRX,
      MST_BOND,
      MST_LAWAN_BOND_TRX,
      T_BOND_COUPON
    WHERE ((TRX_DATE BETWEEN P_BGN_DATE AND P_END_DATE
    AND P_TRX_DATE_FLG = 'Y' )
    OR (value_Dt BETWEEN P_BGN_DATE AND P_END_DATE
    AND P_VALUE_DT_FLG = 'Y' ))
    AND trx_id_yymm BETWEEN P_BGN_TRX_ID AND P_END_TRX_ID
    AND T_BOND_TRX.approved_sts <>'C'
    AND T_BOND_TRX.bond_cd       =MST_BOND.bond_cd
    AND T_BOND_TRX.lawan         = MST_LAWAN_BOND_TRX.lawan
    AND T_BOND_TRX.bond_cd       =T_BOND_COUPON.bond_cd(+)
    AND T_BOND_TRX.trx_date      > period_from(+)
    AND T_BOND_TRX.trx_date     <= period_to(+);
--    ORDER BY trx_id_yymm,
   --   trx_ref;
  EXCEPTION
  WHEN OTHERS THEN
    V_ERROR_CD  := -60;
    V_ERROR_MSG := SUBSTR('INSERT R_BOND_TRX_TAX'||V_ERROR_MSG||SQLERRM(SQLCODE),1,200);
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
END SPR_BOND_TRX_TAX;