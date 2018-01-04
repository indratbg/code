create or replace PROCEDURE SP_TC_DOWNLOAD_MU(
    P_TRX_DATE   DATE,
    P_TRX_STATUS VARCHAR2,
    P_IM_CODE VARCHAR2,
    P_USER_ID    VARCHAR2,
    P_UPDATE_SEQ OUT NUMBER,
    P_ERROR_CODE OUT NUMBER,
    P_ERROR_MSG OUT VARCHAR2)
IS
  V_SEQ_NAME   VARCHAR2(20):='SEQ_SINVEST';
  v_err        EXCEPTION;
  V_ERROR_CODE NUMBER(5);
  V_ERROR_MSG  VARCHAR2(200);
  V_SQL        VARCHAR2(200);
  V_UPDATE_SEQ NUMBER;
  V_CNT        NUMBER(5);
  
  CURSOR CSR_DATA
  IS
    SELECT DECODE(P_TRX_STATUS,'A','NEWM','CANC') TRANSACTION_STATUS, NULL TC_REFERENCE_ID, T.CONTR_DT TRADE_DATE,
    T.DUE_DT_FOR_AMT SETTLEMENT_DATE,T.CONTR_NUM, p.BR_CODE, c.IM_CODE, c.FUND_CODE, T.stk_cd SECURITY_CODE,
    DECODE(SUBSTR(T.CONTR_NUM,5,1),'B','1','2') BUY_SELL, T.PRICE, T.QTY QUANTITY, T.VAL TRADE_AMOUNT, 
    T.COMMISSION COMMISSION, T.PPH SALES_TAX, T.TRANS_LEVY, T.VAT, NULL OTHER_CHARGES, 
    DECODE(SUBSTR(T.CONTR_NUM,5,1),'B',(T.AMT_FOR_CURR+T.PPH_OTHER_VAL),(T.AMT_FOR_CURR-T.PPH_OTHER_VAL)) GROSS_SETTLEMENT_AMOUNT, T.PPH_OTHER_VAL WHT_ON_COMMISSION, 
   T.AMT_FOR_CURR NET_SETTLEMENT_AMOUNT, T.CLIENT_CD
    FROM T_CONTRACTS T, MST_FUND_CLIENT C, (
        SELECT DSTR1 AS BR_CODE
        FROM MST_SYS_PARAM
        WHERE PARAM_ID='SINVEST'
        AND PARAM_CD1 ='BR_CODE'
      )
    P, mst_im m
  WHERE T.CLIENT_CD   = C.CLIENT_CD
  and c.im_code = m.im_code
  and m.approved_stat='A'
  AND C.APPROVED_STAT='A'
  AND ((T.CONTR_STAT='0'
  AND P_TRX_STATUS  ='A')
  OR(P_TRX_STATUS   ='C'
  AND t.CONTR_STAT <> '0') )
  AND T.CONTR_DT    =P_TRX_DATE
   AND ((C.IM_CODE = P_IM_CODE) OR P_IM_CODE = '%');
BEGIN

  --CREATE SEQUENCE FOR UPDATE_SEQ IM FILE
  BEGIN
    SELECT COUNT(1) INTO V_CNT FROM ALL_SEQUENCES WHERE SEQUENCE_NAME=V_SEQ_NAME;
  EXCEPTION
  WHEN OTHERS THEN
    V_ERROR_CODE:=-10;
    V_ERROR_MSG :=SUBSTR('CHECK SEQUENCE '||V_SEQ_NAME||'IN ALL_SEQUENCES'||SQLERRM,1,200);
    RAISE V_ERR;
  END;
  
  IF V_CNT=0 THEN
    v_sql:='CREATE SEQUENCE '||V_SEQ_NAME ||' INCREMENT BY 1 START WITH 1 MAXVALUE 999999 NOCACHE nocycle';
    BEGIN
      EXECUTE IMMEDIATE V_SQL;
    EXCEPTION
    WHEN OTHERS THEN
      V_ERROR_CODE:=-20;
      V_ERROR_MSG :=SUBSTR('CREATE SEQUENCE '||V_SEQ_NAME||' '||SQLERRM,1,200);
      RAISE V_ERR;
    END;
  END IF;
  
  BEGIN
    SELECT COUNT(1), MAX(UPDATE_SEQ)
    INTO V_CNT, V_UPDATE_SEQ
    FROM TC_DOWNLOAD
    WHERE TRADE_DATE=P_TRX_DATE;
  EXCEPTION
  WHEN OTHERS THEN
    V_ERROR_CODE:=-40;
    V_ERROR_MSG :=SUBSTR('SELECT FROM TC_DOWNLOAD '||SQLERRM,1,200);
    RAISE V_ERR;
  END;
    

IF P_TRX_STATUS='A' THEN
  
  IF V_UPDATE_SEQ IS NULL THEN
    V_SQL         := 'SELECT '||V_SEQ_NAME||'.NEXTVAL FROM DUAL';
    BEGIN
      EXECUTE IMMEDIATE V_SQL INTO V_UPDATE_SEQ;
    EXCEPTION
    WHEN OTHERS THEN
      V_ERROR_CODE:=-30;
      V_ERROR_MSG :=SUBSTR('SELECT SEQUENCE '||V_SEQ_NAME||' '||SQLERRM,1,200);
      RAISE V_ERR;
    END;
  END IF;
  

  
    FOR REC IN CSR_DATA
    LOOP
      BEGIN
        SELECT COUNT(1)
        INTO V_CNT
        FROM TC_DOWNLOAD
        WHERE TRADE_DATE=P_TRX_DATE
        AND CONTR_NUM  =REC.CONTR_NUM;
      EXCEPTION
      WHEN OTHERS THEN
        V_ERROR_CODE:=-40;
        V_ERROR_MSG :=SUBSTR('SELECT FROM TC_DOWNLOAD '||SQLERRM,1,200);
        RAISE V_ERR;
      END;
      
      IF V_CNT=0 THEN
        BEGIN
          INSERT
          INTO TC_DOWNLOAD
            (
              TRANSACTION_STATUS ,TC_REFERENCE_ID ,TRADE_DATE ,SETTLEMENT_DATE ,CONTR_NUM ,BR_CODE ,
              IM_CODE ,FUND_CODE ,SECURITY_CODE ,BUY_SELL ,PRICE ,QUANTITY ,TRADE_AMOUNT ,
              COMMISSION ,SALES_TAX ,LEVY ,VAT ,OTHER_CHARGES ,GROSS_SETTLEMENT_AMOUNT ,WHT_ON_COMMISSION ,NET_SETTLEMENT_AMOUNT ,
              TC_REFERENCE_NO ,GENERATE_DATE ,USER_ID ,UPDATE_SEQ
            )
            VALUES
            (
              REC.TRANSACTION_STATUS, REC.TC_REFERENCE_ID, REC.TRADE_DATE, REC.SETTLEMENT_DATE,REC.CONTR_NUM, REC.BR_CODE, 
              REC.IM_CODE, REC.FUND_CODE, REC.SECURITY_CODE, REC.BUY_SELL, REC.PRICE, REC.QUANTITY, REC.TRADE_AMOUNT,
              REC.COMMISSION, REC.SALES_TAX, REC.TRANS_LEVY, REC.VAT, REC.OTHER_CHARGES, REC.GROSS_SETTLEMENT_AMOUNT, REC.WHT_ON_COMMISSION,
              REC.NET_SETTLEMENT_AMOUNT, F_GET_TD_REF_NO_MU(REC.CLIENT_CD,REC.TRADE_DATE), SYSDATE , P_USER_ID, V_UPDATE_SEQ
            );
        EXCEPTION
        WHEN OTHERS THEN
          V_ERROR_CODE:=-40;
          V_ERROR_MSG :=SUBSTR('INSERT INTO TC_DOWNLOAD '||SQLERRM,1,200);
          RAISE V_ERR;
        END;
      END IF;--END V_CNT=0
    END LOOP;--END LOOP CSR_DATA
  END IF;
  
  COMMIT;
  
  P_UPDATE_SEQ :=V_UPDATE_SEQ;
  P_ERROR_CODE :=1;
  P_ERROR_MSG  :='';
  
EXCEPTION
WHEN V_ERR THEN
  ROLLBACK;
  P_ERROR_CODE :=V_ERROR_CODE;
  P_ERROR_MSG  :=V_ERROR_MSG;
  RAISE;
WHEN OTHERS THEN
  ROLLBACK;
  P_ERROR_CODE :=-1;
  P_ERROR_MSG  := SUBSTR(SQLERRM,1,200);
END SP_TC_DOWNLOAD_MU;