create or replace FUNCTION F_GET_TD_REF_NO_MU(
    P_CLIENT_CD VARCHAR2,
    P_TRX_DATE  DATE)
  RETURN VARCHAR2
IS
  --V_TD_REF_NO FORMAT VARCHAR2(20) := 'DDMMYYSUBR9999';
  V_TODAY     DATE :=TRUNC(SYSDATE);
  V_TD_REF_NO VARCHAR2(20);
  V_CNT       NUMBER(4);
  PRAGMA AUTONOMOUS_TRANSACTION;
  v_sql      VARCHAR2(250);
  V_SEQ_NAME VARCHAR2(30);
  V_SUBREK   VARCHAR2(4);
  v_error    EXCEPTION;
  V_SEQ NUMBER;
BEGIN
  V_SEQ_NAME :='SEQ_TD_REF_NO_MU_'||TO_CHAR(P_TRX_DATE,'MMYY');
  
  BEGIN
    SELECT COUNT(1) INTO V_CNT FROM ALL_SEQUENCES WHERE SEQUENCE_NAME=V_SEQ_NAME;
  EXCEPTION
  WHEN OTHERS THEN
    RAISE_APPLICATION_ERROR(-2001,'CHECK SEQUENCE '||V_SEQ_NAME||'IN ALL_SEQUENCES'||SQLERRM);
  END;
  
IF V_CNT=0 THEN
  v_sql:='CREATE SEQUENCE '||V_SEQ_NAME ||' INCREMENT BY 1 START WITH 1 MAXVALUE 9999 NOCACHE nocycle';
  BEGIN
    EXECUTE IMMEDIATE V_SQL;
  EXCEPTION
  WHEN OTHERS THEN
    RAISE_APPLICATION_ERROR(-2002,'CREATE SEQUENCE '||V_SEQ_NAME||' '||SQLERRM);
  END;
END IF;

  V_SQL := 'SELECT '||V_SEQ_NAME||'.NEXTVAL FROM DUAL';
  BEGIN
    EXECUTE IMMEDIATE V_SQL INTO V_SEQ;
  EXCEPTION
  WHEN OTHERS THEN
    RAISE_APPLICATION_ERROR(-2006,'SELECT SEQUENCE '||V_SEQ_NAME||' '||SQLERRM);
  END;


BEGIN
  SELECT SUBSTR(SUBREK001,5,4)
  INTO V_SUBREK
  FROM V_CLIENT_SUBREK14
  WHERE CLIENT_CD=P_CLIENT_CD;
EXCEPTION
WHEN OTHERS THEN
  RAISE_APPLICATION_ERROR(-2007,'SELECT V_CLIENT_SUBREK14 '||P_CLIENT_CD||' '||V_SEQ_NAME||' '||SQLERRM);
END;

V_TD_REF_NO :=TO_CHAR(P_TRX_DATE,'DDMMYY')||V_SUBREK||TO_CHAR(V_SEQ,'fm0000');

RETURN V_TD_REF_NO;

END F_GET_TD_REF_NO_MU;