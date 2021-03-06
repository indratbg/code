create or replace FUNCTION F_GET_TD_REF_NO(
    P_TRX_DATE DATE)
  RETURN VARCHAR2
IS
  --V_TD_REF_NO FORMAT VARCHAR2(20) := 'YY99999';
  V_TODAY   DATE         :=TRUNC(SYSDATE);
  V_TD_REF_NO  VARCHAR2(20);
  V_CNT     NUMBER(4);
 PRAGMA AUTONOMOUS_TRANSACTION;
  v_sql VARCHAR2(400);
  V_SEQ_NAME VARCHAR2(30);
  v_err_cd number;
  v_err_msg varchar2(200);
BEGIN

V_SEQ_NAME :='SEQ_TD_REF_NO_'||TO_CHAR(P_TRX_DATE,'YYYY');
 BEGIN
    SELECT COUNT(1) INTO V_CNT FROM ALL_SEQUENCES WHERE SEQUENCE_NAME=V_SEQ_NAME;
  EXCEPTION
  WHEN OTHERS THEN
    RAISE_APPLICATION_ERROR(-20001,'CHECK SEQUENCE '||V_SEQ_NAME||'IN ALL_SEQUENCES'||SQLERRM);
  END;
  
  IF V_CNT=0 THEN
   
   v_sql:='CREATE SEQUENCE '||V_SEQ_NAME ||' INCREMENT BY 1 START WITH 1 MAXVALUE 9999 NOCACHE nocycle';
    BEGIN
      EXECUTE IMMEDIATE V_SQL;
    EXCEPTION
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR(-20002,'CREATE SEQUENCE '||V_SEQ_NAME||' '||SQLERRM);
    END;
  END IF;

    V_SQL := 'SELECT '||V_SEQ_NAME||'.NEXTVAL FROM DUAL';
    BEGIN
      EXECUTE IMMEDIATE V_SQL INTO V_CNT;
    EXCEPTION
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR(-2005,'CREATE SEQUENCE '||V_SEQ_NAME||' '||SQLERRM);
    END;
  
  V_TD_REF_NO :=TO_CHAR(P_TRX_DATE,'YY')||TO_CHAR(V_CNT,'fm00000');

RETURN V_TD_REF_NO;

END F_GET_TD_REF_NO;