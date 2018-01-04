CREATE OR REPLACE PROCEDURE SP_UPD_STK_HAIRCUT(
    p_user_id MST_COUNTER.user_id%TYPE,
    P_ERROR_CD OUT NUMBER,
    P_ERROR_MSG OUT VARCHAR2)
IS

  V_ERR       EXCEPTION;
  V_ERROR_CD  NUMBER(5);
  V_ERROR_MSG VARCHAR2(200);
  
  CURSOR csr_stk
  IS
    SELECT m.stk_cd, c.haircut,c.status_Dt
    FROM MST_COUNTER m, T_STK_HAIRCUT c, (
        SELECT stk_cd, MAX(status_dt) max_date FROM T_STK_HAIRCUT GROUP BY stk_cd
      )
    d
  WHERE m.stk_cd  = c.stk_cd
  AND c.stk_cd    = d.stk_cd
  AND c.status_dt = d.max_date;
BEGIN

  FOR rec IN csr_stk
  LOOP
  
    BEGIN
      UPDATE MST_COUNTER
      SET rem_stk_cap = rec.haircut, upd_dt = SYSDATE, user_id = p_user_id
      WHERE stk_cd    = rec.stk_cd;
    EXCEPTION
    WHEN OTHERS THEN
      V_ERROR_CD  :=-10;
      V_ERROR_MSG :=SUBSTR('UPDATE MST_COUNTER '||SQLERRM,1,200);
      RAISE V_ERR;
    END;
    
  END LOOP;
  
  P_ERROR_CD :=1;
  P_ERROR_MSG:='';
  
EXCEPTION
WHEN NO_DATA_FOUND THEN
  NULL;
WHEN V_ERR THEN
  ROLLBACK;
  P_ERROR_CD  :=V_ERROR_CD;
  P_ERROR_MSG := V_ERROR_MSG;
WHEN OTHERS THEN
  -- Consider logging the error and then re-raise
  P_ERROR_CD :=-1;
  P_ERROR_MSG:=SUBSTR(SQLERRM,1,200);
  RAISE;
END SP_UPD_STK_HAIRCUT;