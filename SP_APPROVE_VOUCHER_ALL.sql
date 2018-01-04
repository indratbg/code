create or replace PROCEDURE SP_APPROVE_VOUCHER_ALL(
    p_update_seq NUM_ARRAY,
    p_user_id    VARCHAR2 ,
    p_ip_address VARCHAR2 ,
    p_error_code OUT NUMBER ,
    p_error_msg OUT VARCHAR2 )
IS
  v_err       EXCEPTION;
  v_error_cd  NUMBER ( 5 );
  v_error_msg VARCHAR2 ( 4000 );
  v_cnt       NUMBER:=0;
  V_MENU_NAME T_MANY_HEADER.MENU_NAME%TYPE;
  V_UPDATE_DATE T_MANY_HEADER.UPDATE_DATE%TYPE;
--  V_CLIENT_CD T_PAYRECH.CLIENT_CD%TYPE;
--  V_DOC_NUM_MSG VARCHAR2(4000);
BEGIN

  FOR I IN 1..p_update_seq.COUNT LOOP
  
  BEGIN
  SELECT UPDATE_DATE,MENU_NAME INTO V_UPDATE_DATE,V_MENU_NAME FROM T_MANY_HEADER WHERE UPDATE_SEQ=p_update_seq(I) AND APPROVED_STATUS='E';
   EXCEPTION
    WHEN OTHERS THEN
      v_error_cd  :=-5;
      v_error_msg :=SUBSTR('GET UPDATE DATE, MENU NAME FROM T_MANY_HEADER , UPDATE SEQ ='||P_UPDATE_SEQ(I)||' '||SQLERRM,1,4000);
      RAISE V_ERR;
    END;
    
    BEGIN
      SP_T_PAYRECH_APPROVE(V_MENU_NAME, V_UPDATE_DATE, P_UPDATE_SEQ(I), p_user_id, p_ip_address, v_error_cd, V_ERROR_MSG);
    EXCEPTION
    WHEN OTHERS THEN
      v_error_cd  :=-10;
      v_error_msg :=SUBSTR('CALL SP_T_PAYRECH_APPROVE , UPDATE SEQ ='||P_UPDATE_SEQ(I)||' '||SQLERRM,1,4000);
      RAISE V_ERR;
    END;
    
    IF v_error_cd  <0 THEN
      v_cnt       :=0;
      v_error_cd  :=-15;
      v_error_msg :=SUBSTR('UPDATE SEQ ='||P_UPDATE_SEQ(I)||' '||V_ERROR_MSG,1,4000);
      RAISE V_ERR;
    END IF;
    
--    BEGIN
--    SELECT FIELD_VALUE INTO V_CLIENT_CD FROM T_MANY_DETAIL WHERE UPDATE_SEQ=P_UPDATE_SEQ(I) AND UPDATE_DATE=V_UPDATE_DATE
--    AND TABLE_NAME = 'T_PAYRECH' AND FIELD_NAME='CLIENT_CD' AND RECORD_SEQ=1;
--     EXCEPTION
--    WHEN OTHERS THEN
--      v_error_cd  :=-20;
--      v_error_msg :=SUBSTR('CALL SP_T_PAYRECH_APPROVE , UPDATE SEQ ='||P_UPDATE_SEQ(I)||' '||SQLERRM,1,4000);
--      RAISE V_ERR;
--    END;
--    
     v_cnt := v_cnt+1;
--     IF v_cnt>1 THEN
--        V_DOC_NUM_MSG :=substr(V_DOC_NUM_MSG||', '||V_CLIENT_CD,1,4000);  
--      ELSE
--       V_DOC_NUM_MSG :=V_CLIENT_CD;  
--      END IF;
    
  END LOOP;
 
  P_ERROR_CODE  := 1;
  P_ERROR_MSG :=SUBSTR('Successfully approve '||V_CNT||' Voucher(s)',1,4000);
  
EXCEPTION
WHEN V_ERR THEN
  ROLLBACK;
  P_ERROR_CODE := v_error_cd;
  P_ERROR_MSG  := V_ERROR_MSG;
WHEN OTHERS THEN
  P_ERROR_CODE := - 1;
  P_ERROR_MSG  := SUBSTR ( SQLERRM ( SQLCODE ), 1 , 4000 );
  RAISE;
END SP_APPROVE_VOUCHER_ALL;