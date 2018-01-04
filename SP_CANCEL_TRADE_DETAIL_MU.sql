create or replace PROCEDURE SP_CANCEL_TRADE_DETAIL_MU(
    P_TRX_DATE   DATE,
    P_CONTR_NUM VARCHAR2,
    P_ERROR_CODE OUT NUMBER,
    P_ERROR_MSG OUT VARCHAR2)
IS
  V_ERR        EXCEPTION;
  V_ERROR_CODE NUMBER(5);
  V_ERROR_MSG  VARCHAR2(200);
  
BEGIN

  BEGIN
    UPDATE TD_DOWNLOAD
    SET TRANSACTION_STATUS='CANC'
    WHERE TRADE_DATE      =P_TRX_DATE
    AND CONTR_NUM        =P_CONTR_NUM;
  EXCEPTION
  WHEN NO_DATA_FOUND THEN
    NULL;
  WHEN OTHERS THEN
    V_ERROR_CODE:=-10;
    V_ERROR_MSG :=SUBSTR('UDATE TD_DOWNLOAD WHERE TRADE DATE '||TO_CHAR(P_TRX_DATE,'DD-MM-YYYY')||' '||P_CONTR_NUM ||' '||SQLERRM,1,200);
  END;

  P_ERROR_CODE :=1;
  P_ERROR_MSG  :='';
EXCEPTION
WHEN V_ERR THEN
  ROLLBACK;
  P_ERROR_CODE :=V_ERROR_CODE;
  P_ERROR_MSG  :=V_ERROR_MSG;
WHEN OTHERS THEN
  ROLLBACK;
  P_ERROR_CODE :=-1;
  P_ERROR_MSG  := SUBSTR(SQLERRM,1,200);
  raise;
END SP_CANCEL_TRADE_DETAIL_MU;