CREATE OR REPLACE
PROCEDURE SPR_LIST_OF_BOND_TRX(
    P_BGN_DATE      DATE,
    P_END_DATE      DATE,
    --P_TICKET_NO_FROM VARCHAR2,
 --   P_TICKET_NO_TO VARCHAR2,
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
    SP_RPT_REMOVE_RAND('R_LIST_OF_BOND_TRX',V_RANDOM_VALUE,V_ERROR_MSG,V_ERROR_CD);
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
    INTO R_LIST_OF_BOND_TRX
      (
        TRX_DATE ,
        VALUE_DT ,
        TRX_ID ,
        TRX_TYPE ,
        BOND_CD ,
        LAWAN ,
        TRX_SEQ_NO ,
        NOMINAL ,
        SISA_NOMINAL ,
        PRICE ,
        ACCRUED_INT ,
        CAPITAL_TAX ,
        ACCRUED_INT_TAX ,
        NET_AMOUNT ,
        BUKTI_PAJAK ,
        SHORT_DESC ,
        LAWAN_NAME ,
        USER_ID ,
        RAND_VALUE ,
        GENERATE_DATE
      )
    SELECT trx_Date,
      value_dt,
      trx_id,
      trx_type,
      T_BOND_TRX.bond_cd,
      T_BOND_TRX.lawan,
      trx_seq_no,
      nominal,
      sisa_nominal,
      price ,
      accrued_int,
      capital_tax,
      accrued_int_tax,
      net_amount,
      bukti_pajak,
      DECODE(MST_BOND.Bond_group_cd,'02',short_desc,'') short_desc,
      lawan_name ,
      P_USER_ID,
      V_RANDOM_VALUE,
      P_GENERATE_DATE
    FROM T_BOND_TRX,
      MST_BOND,
      MST_LAWAN_BOND_TRX
    WHERE (TRX_DATE BETWEEN P_BGN_DATE AND P_END_DATE OR 
     value_Dt BETWEEN P_BGN_DATE AND P_END_DATE )
--    OR ( trx_date > (P_BGN_VAL_DATE - 400)
  --  AND value_Dt BETWEEN P_BGN_VAL_DATE AND P_END_VAL_DATE)
  --  )
    AND T_BOND_TRX.approved_sts <>'C'
    AND T_BOND_TRX.bond_cd       =MST_BOND.bond_cd
    AND T_BOND_TRX.lawan         = MST_LAWAN_BOND_TRX.lawan
    --AND T_BOND_TRX.TRX_ID_YYMM BETWEEN P_TICKET_NO_FROM AND P_TICKET_NO_TO
    ORDER BY value_dt,
      TO_NUMBER(trx_id),
      trx_date,
      trx_seq_no ;
  EXCEPTION
  WHEN OTHERS THEN
    V_ERROR_CD  := -30;
    V_ERROR_MSG := SUBSTR('INSERT R_LIST_OF_BOND_TRX '||V_ERROR_MSG||SQLERRM(SQLCODE),1,200);
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
END SPR_LIST_OF_BOND_TRX;