CREATE OR REPLACE
PROCEDURE SPR_BOND_TRX_CTP(
    P_DATE          DATE,
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
    SP_RPT_REMOVE_RAND('R_BOND_TRX_CTP',V_RANDOM_VALUE,V_ERROR_MSG,V_ERROR_CD);
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
    INTO R_BOND_TRX_CTP
      (
        REPORT_TYPE ,
        POSITION ,
        SECURITIES_ID ,
        TRANSACTION_TYPE ,
        CP_FIRM_ID ,
        PRICE ,
        YIELD ,
        VOLUME ,
        TRADE_DATE ,
        TRADE_TIME ,
        VAS ,
        SETTLEMENT_DATE ,
        TRX_PARTIES_CODE_DELIVERER ,
        REMARKS_DELIVERER ,
        REFERENCE_DELIVERER ,
        CUSTODIAN_DELIVERER ,
        TRX_PARTIES_CODE_RECEIVER ,
        REMARKS_RECEIVER ,
        REFERENCE_RECEIVER ,
        CUSTODIAN_RECEIVER ,
        SECOND_LEG_PRICE ,
        SECOND_LEG_YIELD ,
        SECOND_LEG_RATE ,
        REVERSE_DATE ,
        LATE_TYPE ,
        LATE_REASON ,
        USER_ID ,
        RAND_VALUE ,
        GENERATE_DATE
      )
    SELECT REPORT_TYPE,
      BUY_SELL_IND AS Position,
      BOND_CD      AS securities_id,
      TRANS_TYPE transaction_type,
      FIRM_ID                    AS cp_firm_id,
      TO_CHAR(PRICE,'999.99999') AS price,
      TO_CHAR(YIELD,'999.99999') yield,
      NOMINAL AS volume,
      TO_CHAR(TRUNC(TRADE_DATETIME),'mm/dd/yyyy') trade_date,
      TO_CHAR(SYSDATE ,'hh24:mi') trade_time,
      VAS,
      TO_CHAR(SETTLEMENT_DATE,'mm/dd/yyyy') SETTLEMENT_DATE,
      D_PARTY_CD AS trx_parties_code_deliverer,
      D_REMARKS  AS remarks_deliverer,
      D_REF      AS reference_deliverer,
      D_CUSTODY custodian_deliverer,
      R_PARTY_CD AS trx_parties_code_receiver,
      R_REMARKS  AS remarks_receiver,
      R_REF      AS reference_receiver,
      R_CUSTODY custodian_receiver,
      RETURN_VALUE AS second_leg_price,
      RETURN_YIELD AS second_leg_yield,
      REPO_RATE    AS second_leg_rate,
      RETURN_DATE reverse_date,
      LATE_TYPE,
      LATE_REASON,
      P_USER_ID,
      V_RANDOM_VALUE,
      P_GENERATE_DATE
    FROM T_BOND_TRX_CTP
    WHERE trx_Date = P_DATE
    AND xls        = 'N'
    ORDER BY trx_id_yymm,
      trx_seq_no;
  EXCEPTION
  WHEN OTHERS THEN
    V_ERROR_CD  := -30;
    V_ERROR_MSG := SUBSTR('INSERT R_BOND_TRX_CTP '||V_ERROR_MSG||SQLERRM(SQLCODE),1,200);
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
END SPR_BOND_TRX_CTP;