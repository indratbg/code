create or replace FUNCTION F_GET_TA_REF(
    P_TRX_DATE DATE)
  RETURN VARCHAR2
IS
  --TA REF LIM FORMAT VARCHAR2(20) := '9999/LIM/HO/MM/YYYY';
  V_TODAY   DATE         :=TRUNC(SYSDATE);
  
  V_TA_REF  VARCHAR2(20);
  V_CNT     NUMBER(4);
 PRAGMA AUTONOMOUS_TRANSACTION;
  v_sql VARCHAR2(250);
  V_SEQ_NAME VARCHAR2(30) :='SEQ_IM_FILE_LIM';
BEGIN

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


  IF TO_NUMBER(TO_CHAR(P_TRX_DATE,'MM')) > TO_NUMBER(TO_CHAR(V_TODAY,'MM')) THEN
  
    v_sql                               :='DROP SEQUENCE '||V_SEQ_NAME;
    BEGIN
      EXECUTE IMMEDIATE V_SQL;
    EXCEPTION
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR(-2003,'DROP SEQUENCE '||V_SEQ_NAME||' '||SQLERRM);
    END;
    
    v_sql:='CREATE SEQUENCE '||V_SEQ_NAME||' INCREMENT BY 1 START WITH 1 MAXVALUE 9999 NOCACHE nocycle';
    
    BEGIN
      EXECUTE IMMEDIATE V_SQL;
    EXCEPTION
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR(-2004,'CREATE SEQUENCE '||V_SEQ_NAME||' '||SQLERRM);
    END;
  
  END IF;
  
  IF V_CNT>0 THEN
    V_SQL := 'SELECT '||V_SEQ_NAME||'.NEXTVAL FROM DUAL';
    BEGIN
      EXECUTE IMMEDIATE V_SQL INTO V_CNT;
    EXCEPTION
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR(-2005,'CREATE SEQUENCE '||V_SEQ_NAME||' '||SQLERRM);
    END;
  END IF;
  
  V_TA_REF :=TO_CHAR(V_CNT,'fm0000')||'/LIM/HO/'||TO_CHAR(P_TRX_DATE,'MM/YYYY');

RETURN V_TA_REF;

END F_GET_TA_REF;