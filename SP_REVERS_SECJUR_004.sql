create or replace 
PROCEDURE SP_REVERS_SECJUR_004(
    p_date DATE,
    p_user_id t_stk_movement.user_id%type,
    P_ERROR_CD OUT NUMBER,
    P_ERROR_MSG OUT VARCHAR2 )
IS
  tmpVar      NUMBER;
  V_ERROR_CD  NUMBER;
  V_ERROR_MSG VARCHAR2(200);
  V_ERR       EXCEPTION;
  
  CURSOR csr_reversal( a_date_min1 DATE)
  IS
    SELECT doc_num,
      client_cd,
      stk_cd,
      NVL( DECODE(db_cr_flg,'D',1,-1) * (total_share_qty + withdrawn_share_qty),0) qty004
    FROM t_stk_movement
    WHERE doc_dt    = a_date_min1
    AND gl_acct_cd IN ('13')
    AND gl_acct_cd IS NOT NULL
    AND doc_stat    = '2'
    AND db_cr_flg   = 'D'
    AND s_d_type    = '4';
    
  V_DOC_NUM T_STK_MOVEMENT.DOC_NUM%TYPE;
  V_DATE_MIN1 DATE;
  v_cnt       NUMBER;
  V_JUR_TYPE T_STK_MOVEMENT.JUR_TYPE%TYPE :='DARI004';
 --V_GL_ACCT_DEB T_STK_MOVEMENT.gl_Acct_cd%TYPE;
--V_GL_ACCT_CRE T_STK_MOVEMENT.gl_Acct_cd%TYPE;
--v_gl_acct_cd t_stk_movement.gl_Acct_cd%type;
--V_DB_CR_FLG T_STK_MOVEMENT.db_cr_flg%TYPE;
BEGIN

  tmpVar      := 0;
  v_date_min1 := get_doc_date(1, p_date);
  
  BEGIN
    SELECT COUNT(1)
    INTO v_cnt
    FROM t_stk_movement
    WHERE doc_dt         = p_date
    AND trim(gl_Acct_cd) = '13'
    AND db_cr_flg        = 'C'
    AND s_d_type         = '4'
    AND doc_stat         = '2';
  EXCEPTION
  WHEN no_data_found THEN
    v_cnt := 0;
  WHEN OTHERS THEN
    V_ERROR_CD  := -10;
    V_ERROR_MSG := 'select reversal jurnal 004 on t_STK_MOVEMENT '||SQLERRM;
    RAISE V_ERR;
  END;
  
  IF v_cnt > 0 THEN
    RETURN;
  END IF;
  
  -- jurnal reversal
 
  FOR rec IN csr_reversal(v_date_min1)
  LOOP
  
    V_DOC_NUM := Get_Stk_Jurnum( p_date, 'JA4');
    
    BEGIN
      Sp_Secu_Jurnal_Nextg ( V_DOC_NUM, NULL, p_date, rec.CLIENT_CD,
      rec.STK_CD, '4', NULL,
      0, rec.qty004, 'Kembalikan 004', 
      '2', NULL, 0, 
      NULL, NULL, '12', 
      NULL, 'D', p_user_id,
      SYSDATE, NULL, NULL,
      NULL, 1, 0, 'N',--MANUAL
      V_JUR_TYPE,                                                                                                                                                                                                       --JUR TYPE
      2, '13', 'C', V_ERROR_CD, V_ERROR_MSG );
    EXCEPTION
    WHEN OTHERS THEN
      V_ERROR_CD  := -10;
      V_ERROR_MSG := 'insert '||REC.client_cd||'  on t_STK_MOVEMENT '||SQLERRM;
      RAISE V_ERR;
    END;
    
  --call sp_upd_stkhand  
       
          BEGIN
            Sp_Upd_T_Stkhand ( rec.CLIENT_CD, REC.STK_CD , '%' , NULL, rec.qty004, V_JUR_TYPE, P_USER_ID, V_ERROR_CD, V_ERROR_MSG );
          EXCEPTION
          WHEN OTHERS THEN
            V_ERROR_CD  := -30;
            V_ERROR_MSG := 'Sp_Upd_T_Stkhand UPDATE T_STKHAND'||SQLERRM;
            RAISE V_ERR;
          END;
          
          IF V_ERROR_CD  <0 THEN
            V_ERROR_CD  := -40;
            V_ERROR_MSG := 'Sp_Upd_T_Stkhand '||V_ERROR_MSG;
            RAISE V_ERR;
          END IF;
  END LOOP;
  
  P_ERROR_CD  := 1 ;
  P_ERROR_MSG := '';
  
EXCEPTION
WHEN V_ERR THEN
  ROLLBACK;
  P_ERROR_MSG := SUBSTR(V_ERROR_MSG,1,200);
  P_ERROR_CD  := V_ERROR_CD;
WHEN OTHERS THEN
  P_ERROR_CD  := -1 ;
  P_ERROR_MSG := SUBSTR(SQLERRM(SQLCODE),1,200);
  RAISE;
END SP_REVERS_SECJUR_004;