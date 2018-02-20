create or replace FUNCTION F_GET_FUND_FOLDER_CD(
    P_DOC_DATE DATE,
    P_PREFIX   VARCHAR2)
  RETURN VARCHAR2
AS
  V_FOLDER_CD T_FUND_MOVEMENT.FOLDER_CD%TYPE;
  PRAGMA autonomous_transaction;
  V_SEQ_NAME VARCHAR2(30);
  vcounter   NUMBER(5);
  v_mmyy     VARCHAR2(20);
  V_CNT      NUMBER;
  V_STR      VARCHAR2(200);
  V_BGN_DATE DATE;
  V_END_DATE DATE;
BEGIN
      V_SEQ_NAME :='SEQ_FUND_FOLDER_CD'||TO_CHAR(P_DOC_DATE,'MMYY');
      --v_mmyy     := TO_CHAR(P_DOC_DATE,'MMYY')||'%';
      V_BGN_DATE :=P_DOC_DATE-TO_CHAR(P_DOC_DATE,'DD')+1;
      V_END_DATE := LAST_DAY(P_DOC_DATE); 
      
      BEGIN
        SELECT COUNT(1) INTO V_CNT FROM ALL_SEQUENCES WHERE SEQUENCE_NAME=V_SEQ_NAME;
      EXCEPTION
      WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20100,'CHECK SEQUENCE '||V_SEQ_NAME||'IN ALL_SEQUENCES'||SQLERRM);
      END;
      
        IF V_CNT = 0 THEN
        
          BEGIN
          SELECT NVL(MAX(FOLDER_CD),0) + 1 INTO vcounter
            FROM
              (
              SELECT SUBSTR(FOLDER_CD,3) FOLDER_CD
                FROM T_FUND_MOVEMENT
                WHERE DOC_DATE BETWEEN V_BGN_DATE AND V_END_DATE
                AND FOLDER_CD IS NOT NULL
                AND APPROVED_STS='A'
                UNION
                SELECT SUBSTR(FIELD_VALUE,3) FOLDER_CD
                FROM
                  (
                  SELECT A.UPDATE_DATE,A.UPDATE_SEQ,A.FIELD_VALUE FROM T_MANY_DETAIL A
                  JOIN
                   ( 
                    SELECT UPDATE_DATE, UPDATE_SEQ, FIELD_VALUE
                    FROM T_MANY_DETAIL
                    WHERE UPDATE_DATE >TRUNC(SYSDATE)-10
                    AND TABLE_NAME    ='T_FUND_MOVEMENT'
                    AND FIELD_NAME  ='DOC_DATE'
                    AND TO_DATE(FIELD_VALUE,'YYYY/MM/DD HH24:MI:SS') BETWEEN V_BGN_DATE AND V_END_DATE
                    ) B ON A.UPDATE_DATE =B.UPDATE_DATE
                    AND A.UPDATE_sEQ=B.UPDATE_SEQ
                    WHERE  FIELD_NAME  ='FOLDER_CD'
                    AND TABLE_NAME    ='T_FUND_MOVEMENT'
                    AND A.FIELD_VALUE  IS NOT NULL
                  )
                  A
                JOIN
                  (
                    SELECT UPDATE_DATE, UPDATE_SEQ
                    FROM T_MANY_HEADER
                    WHERE UPDATE_DATE   >TRUNC(SYSDATE)-10
                    AND APPROVED_STATUS = 'E'
                  )
                  B
                ON A.UPDATE_DATE = B.UPDATE_DATE
                AND A.UPDATE_SEQ = B.UPDATE_SEQ
              );
              
          EXCEPTION
          WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20100,'RETRIEVE FROM T_FUND_MOVEMENT '||SQLERRM);
          END;
          
          BEGIN
            V_STR :='CREATE SEQUENCE '||V_SEQ_NAME||' MINVALUE 0 MAXVALUE 9999 INCREMENT BY 1 START WITH '||vcounter||'NOCACHE ORDER NOCYCLE';
            EXECUTE IMMEDIATE V_STR;
          EXCEPTION
          WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20300,'CREATE SEQUENCE '||V_SEQ_NAME||SQLERRM);
          END;
          
        END IF;
        
        BEGIN
          V_STR :='SELECT '||V_SEQ_NAME||'.NEXTVAL FROM DUAL';
          EXECUTE IMMEDIATE V_STR INTO vcounter;
        EXCEPTION
        WHEN OTHERS THEN
          RAISE_APPLICATION_ERROR(-20400,'GET SEQ USING EXECUTE IMMEDIATE '||SQLERRM);
        END;
        
        V_FOLDER_CD := P_PREFIX||TO_CHAR(NVL(vcounter,0),'fm0000');
        
        RETURN V_FOLDER_CD;
EXCEPTION
WHEN NO_DATA_FOUND THEN
  NULL;
WHEN OTHERS THEN
  -- Consider logging the error and then re-raise
  RAISE;
END F_GET_FUND_FOLDER_CD;