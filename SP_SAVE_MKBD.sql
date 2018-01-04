CREATE OR REPLACE
PROCEDURE SP_SAVE_MKBD(
    P_DATE    IN DATE,
    P_AMOUNT  IN T_MKBD.AMT%TYPE,
    P_USER_ID IN T_MKBD.USER_ID%TYPE,
    P_ERROR_CODE OUT NUMBER,
    P_ERROR_MSG OUT VARCHAR2 )
AS
  V_CNT        NUMBER;
  V_ERR        EXCEPTION;
  V_ERROR_CODE NUMBER;
  V_ERROR_MSG  VARCHAR2(200);
BEGIN
  BEGIN
    SELECT COUNT(1) INTO V_CNT FROM T_MKBD WHERE MKBD_DT = P_DATE;
  EXCEPTION
  WHEN NO_DATA_FOUND THEN
    V_CNT := 0;
  WHEN OTHERS THEN
    V_ERROR_CODE := -10;
    V_ERROR_MSG  := SUBSTR('SELECT COUNT FROM T_MKBD'||SQLERRM,1,200);
    RAISE V_ERR;
  END;
  
  IF V_CNT >= 1 THEN
    BEGIN
      UPDATE T_MKBD
      SET AMT       = P_AMOUNT,
        USER_ID     = P_USER_ID,
        CRE_DT      = SYSDATE
      WHERE MKBD_DT = P_DATE;
    EXCEPTION
    WHEN OTHERS THEN
      --RAISE_APPLICATION_ERROR(-20100,'UPDATE T_MKBD '||TO_CHAR(P_DATE,'DD/MM/YY')||SQLERRM);
      V_ERROR_CODE := -20;
      V_ERROR_MSG  := SUBSTR('UPDATE T_MKBD '||TO_CHAR(P_DATE,'DD/MM/YY')||SQLERRM,1,200);
      RAISE V_ERR;
    END ;
    
  ELSE
  
    BEGIN
      INSERT
      INTO T_MKBD
        (
          MKBD_DT,
          AMT,
          USER_ID,
          CRE_DT
        )
        VALUES
        (
          P_DATE,
          P_AMOUNT,
          P_USER_ID,
          SYSDATE
        );
    EXCEPTION
    WHEN OTHERS THEN
      --RAISE_APPLICATION_ERROR(-20100,'INSERT T_MKBD '||TO_CHAR(P_DATE,'DD/MM/YY')||SQLERRM);
      V_ERROR_CODE := -30;
      V_ERROR_MSG  := SUBSTR('UPDATE T_MKBD '||TO_CHAR(P_DATE,'DD/MM/YY')||SQLERRM,1,200);
      RAISE V_ERR;
    END;
    
  END IF;
  
  P_ERROR_CODE := 1;
  P_ERROR_MSG  := '';
  
EXCEPTION
WHEN NO_DATA_FOUND THEN
  NULL;
WHEN V_ERR THEN
  P_ERROR_CODE := V_ERROR_CODE;
  P_ERROR_MSG  := V_ERROR_MSG;
  ROLLBACK;
WHEN OTHERS THEN
  -- CONSIDER LOGGING THE ERROR AND THEN RE-RAISE
  ROLLBACK;
  P_ERROR_CODE := -1;
  P_ERROR_MSG  := SUBSTR(SQLERRM,1,200);
  RAISE;
END SP_SAVE_MKBD;