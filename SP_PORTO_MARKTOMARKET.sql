create or replace 
PROCEDURE SP_PORTO_MARKTOMARKET(
    P_DATE DATE,
    P_FOLDER_CD T_JVCHH.FOLDER_CD%TYPE,
    P_USER_ID T_MANY_HEADER.USER_ID%TYPE,
    P_IP_ADDRESS T_MANY_HEADER.IP_ADDRESS%TYPE,
    p_error_code OUT NUMBER,
    p_error_msg OUT VARCHAR2 )
IS
  tmpVar NUMBER;
  /******************************************************************************
  NAME:       SP_PORTO_MARKTOMARKET
  PURPOSE: Gen gL jurnal kenaikan/penurunan porto
  REVISIONS:
  Ver        Date        Author           Description
  ---------  ----------  ---------------  ------------------------------------
  1.0        25/09/2015          1. Created this procedure.
  NOTES:
  ******************************************************************************/
  v_laba_rugi T_ACCOUNT_LEDGER.curr_val%TYPE;
  v_gla_lr T_ACCOUNT_LEDGER.Gl_acct_cd%TYPE;
  v_sla_lr T_ACCOUNT_LEDGER.sl_acct_cd%TYPE;
  v_gla_porto T_ACCOUNT_LEDGER.Gl_acct_cd%TYPE;
  v_sla_porto T_ACCOUNT_LEDGER.sl_acct_cd%TYPE;
  V_Gl_Acct_Cd T_ACCOUNT_LEDGER.GL_ACCT_CD%TYPE;
  V_Sl_Acct_Cd T_ACCOUNT_LEDGER.SL_ACCT_CD%TYPE;
  V_DOC_NUM T_JVCHH.JVCH_NUM%TYPE;
  v_begin_date DATE;
  v_end_date   DATE;
  V_CRE_DT     DATE :=SYSDATE;
  V_ERR        EXCEPTION;
  v_error_code NUMBER(5);
  v_error_msg  VARCHAR2(200);
  V_MENU_NAME T_MANY_HEADER.MENU_NAME%TYPE:='GENERATE PORTOFOLIO MARK TO MARKET JOURNAL';
  V_UPDATE_DATE T_MANY_HEADER.UPDATE_DATE%TYPE;
  V_UPDATE_SEQ T_MANY_HEADER.UPDATE_SEQ%TYPE;
  v_db_cr_flg T_account_ledger.db_cr_flg%type;
  v_ledger_nar T_account_ledger.ledger_nar%type;
  V_SIGN VARCHAR2(1);
  V_DOC_REF T_ACCOUNT_LEDGER.DOC_REF_NUM%TYPE;
  V_CEK_FOLDER VARCHAR2(1);
  v_proses     VARCHAR2(1):='N';
  V_DOC_NUM_CHECK T_ACCOUNT_LEDGER.XN_DOC_NUM%TYPE;
  V_RTN            NUMBER;
  V_DOC_DATE_CHECK DATE;
  V_user_id_CHECK T_MANY_HEADER.USER_ID%TYPE;
BEGIN
  tmpVar       := 0;
  v_begin_date := P_DATE - TO_CHAR(P_DATE,'DD') + 1;
  v_end_date   :=P_DATE;
  BEGIN
    SELECT TRUNC(SUM(labarugi),2)
    INTO v_laba_rugi
    FROM
      (SELECT a.stk_cd,
        qty * ( NVL(stk_clos,0) - NVL(stk_prev,0)) AS labarugi
      FROM
        (SELECT stk_cd,
          SUM(qty) qty
        FROM v_own_porto
        WHERE doc_dt BETWEEN v_begin_date AND v_end_date
        GROUP BY stk_cd
        HAVING SUM(qty) > 0
        ) a,
        (SELECT stk_Cd,
          stk_clos,
          stk_prev
        FROM T_CLOSE_PRICE
        WHERE stk_Date =
          (SELECT MAX(stk_date)
          FROM T_CLOSE_PRICE
          WHERE stk_date BETWEEN v_end_date -20 AND v_end_date
          )
        ) b
      WHERE a.stk_Cd = b.stk_Cd
      );
  EXCEPTION
  WHEN OTHERS THEN
    v_error_code :=-10;
    V_ERROR_MSG  := SUBSTR('SELECT labarugi FROM v_own_porto AND T_CLOSE_PRICE'||SQLERRM,1,200);
    RAISE V_ERR;
  END;
  --  gen journal :terdiri dr 2 baris,
  -- baca MST SYS PARAM utk gla , sla , 2 records
  -- param_id = PORTO_MARKTOMARKET, param_cd1= GLACCT
  -- param_cd2 = 'PORTO', dstr1 = 1373, dstr2 = 000001 contoh
  -- param_cd2 = 'LR', dstr1 = 6200, dstr2 = 000001 contoh
  /* jika v_laba rugi < 0  penurunan
  jurnal                      1373 000001 C  amount = abs(v-laba rugi)
  6200 000001 D   amount = abs(v-laba rugi)
  ledger nar = Penurunan portofolio
  jika 0 tidak generate jurnal
  jika > 0 kenaikan
  1373 000001 D  amount = abs(v-laba rugi)
  6200 000001 C   amount = abs(v-laba rugi)
  ledger nar = Kenaikan portofolio
  crea T JVCHH masukkan ke T MANY, langsung aprov
  jurnal dibuat pake sp GEN TRX JUR LINE NEXTG
  */
  BEGIN
    SELECT DSTR1,
      DSTR2
    INTO v_gla_porto,
      v_sla_porto
    FROM Mst_Sys_Param
    WHERE Param_Id='PORTO_MARKTOMARKET'
    AND PARAM_CD1 ='GLACCT'
    AND PARAM_CD2 ='PORTO';
  EXCEPTION
  WHEN OTHERS THEN
    v_error_code :=-20;
    V_ERROR_MSG  := SUBSTR('SELECT GL_ACCT PORTO FROM Mst_Sys_Param'||SQLERRM,1,200);
    RAISE V_ERR;
  End;
  
  BEGIN
    SELECT DSTR1,
      DSTR2
    INTO v_gla_lr,
      v_sla_lr
    FROM Mst_Sys_Param
    WHERE Param_Id='PORTO_MARKTOMARKET'
    AND PARAM_CD1 ='GLACCT'
    AND PARAM_CD2 ='LR';
  EXCEPTION
  WHEN OTHERS THEN
    v_error_code :=-30;
    V_ERROR_MSG  := SUBSTR('SELECT GL_ACCT  LR FROM Mst_Sys_Param'||SQLERRM,1,200);
    RAISE V_ERR;
  End;
  
  BEGIN
    SELECT DFLG1
    INTO V_SIGN
    FROM MST_SYS_PARAM
    WHERE param_id='SYSTEM'
    AND param_cd1 ='DOC_REF';
  EXCEPTION
  WHEN OTHERS THEN
    v_error_code :=-30;
    V_ERROR_MSG  := SUBSTR('SELECT GL_ACCT  LR FROM Mst_Sys_Param'||SQLERRM,1,200);
    RAISE V_ERR;
  End;
  
  BEGIN
    SELECT DFLG1
    INTO V_CEK_FOLDER
    FROM MST_SYS_PARAM
    WHERE param_id='SYSTEM'
    AND PARAM_CD1 ='VCH_REF';
  EXCEPTION
  WHEN OTHERS THEN
    v_error_code :=-35;
    V_ERROR_MSG  := SUBSTR('CEK USING FOLDER_CD FROM Mst_Sys_Param'||SQLERRM,1,200);
    RAISE V_ERR;
  End;
  
  --EXECUTE SP HEADER
  BEGIN
    Sp_T_Many_Header_Insert(V_MENU_NAME, 'I', P_USER_ID, P_IP_ADDRESS, NULL, V_UPDATE_DATE, V_UPDATE_SEQ, v_error_code, v_error_msg);
  EXCEPTION
  WHEN OTHERS THEN
    v_error_code := -20;
    v_error_msg  := SUBSTR('SP_T_MANY_HEADER_INSERT '|| SQLERRM(SQLCODE),1,200);
    RAISE V_ERR;
  End;
  
  V_Doc_Num   := Get_Docnum_Gl(P_Date,'GL');
  
  IF V_SIGN    ='Y' THEN
    V_DOC_REF := V_DOC_NUM;
  End If;
  
  --PENURUNAN
  If V_Laba_Rugi    < 0 Or V_Laba_Rugi > 0 Then
  
    IF v_laba_rugi  < 0 THEN
      v_ledger_nar := 'PENURUNAN PORTOFOLIO';
    ELSE
      v_ledger_nar := 'KENAIKAN PORTOFOLIO';
    End If;
    
    BEGIN
      Sp_T_JVCHH_Upd( v_doc_num,--P_SEARCH_JVCH_NUM,
      v_doc_num,                --P_JVCH_NUM,
      'GL',                     --P_JVCH_TYPE,
      p_date,                   --P_JVCH_DATE,
      NULL,                     --P_GL_ACCT_CD,
      NULL,                     --P_SL_ACCT_CD,
      'IDR',                    --P_CURR_CD,
      ABS(v_laba_rugi),         --P_CURR_AMT,
      v_ledger_nar,             --P_REMARKS,
      P_USER_ID, V_CRE_DT,      --P_CRE_DT,
      NULL,                     --P_UPD_DT,
      P_FOLDER_CD,              --P_FOLDER_CD,
      'N',                      --P_REVERSAL_JUR,
      'I',                      --P_UPD_STATUS,
      p_ip_address, NULL,       --p_cancel_reason,
      V_UPDATE_DATE,            --p_update_date,
      V_UPDATE_SEQ,             --p_update_seq,
      1,                        --p_record_seq,
      v_error_code, v_error_msg);
    EXCEPTION
    WHEN OTHERS THEN
      V_Error_Code := -30;
      v_error_msg  :=SUBSTR('Error insert to T_JVCHH : '||v_doc_num||' '||SQLERRM(SQLCODE),1,200);
      raise v_err;
    End;
    
    IF v_error_code <0 THEN
      v_error_code := -35;
      v_error_msg  :=SUBSTR('Error insert to T_JVCHH : '||v_error_msg,1,200);
      raise v_err;
    End If;
    
    --INSERT INTO T FOLDER
    If V_Cek_Folder ='Y' Then
    
      --CEK FOLDER CD
      BEGIN
        SP_CHECK_FOLDER_CD(p_folder_cd, p_date, V_RTN, V_DOC_NUM_CHECK, V_user_id_CHECK, V_DOC_DATE_CHECK);
      EXCEPTION
      WHEN OTHERS THEN
        v_error_code := -37;
        V_Error_Msg  := SUBSTR('SP_CHECK_FOLDER_CD : '||V_DOC_NUM||' '||p_folder_cd||' '||SQLERRM,1,200);
        RAISE V_Err;
      End;
      
      --JIKA FOLDER CODE SUDAH DIPAKE
      IF V_RTN        =1 THEN
        V_Error_Code := -38;
        V_Error_Msg  := 'FILE NUMBER '|| P_FOLDER_CD || ' IS ALREADY USED BY '||V_user_id_CHECK||' '|| V_DOC_NUM_CHECK||' '|| TO_CHAR(V_DOC_DATE_CHECK,'DD-MON-YYYY');
        RAISE V_Err;
      End If;
      
      --INSERT KE T_FOLDER
      BEGIN
        INSERT
        INTO T_FOLDER
          (
            FLD_MON,
            FOLDER_CD,
            DOC_DATE,
            DOC_NUM,
            USER_ID,
            CRE_DT,
            UPD_DT,
            APPROVED_DT,
            APPROVED_BY,
            APPROVED_STAT
          )
          VALUES
          (
            TO_CHAR(P_DATE,'mmyy'),
            P_FOLDER_CD,
            P_DATE,
            V_DOC_NUM,
            p_user_id,
            SYSDATE,
            NULL,
            SYSDATE,
            P_USER_ID,
            'A'
          );
      EXCEPTION
      WHEN OTHERS THEN
        v_error_code := -40;
        V_Error_Msg  := SUBSTR('Error insert T_FOLDER : '||V_DOC_NUM||' '||P_FOLDER_CD||' '||SQLERRM,1,200);
        RAISE V_Err;
      End;
      
    End If;
    
    For I In 1..2  Loop
    
      If V_Laba_Rugi   < 0 Then
      
        IF i           =1 THEN
          v_db_cr_flg := 'C';
        ELSE
          v_db_cr_flg := 'D';
        End If;
        
      Else
      
        IF i           =1 THEN
          v_db_cr_flg := 'D';
        ELSE
          v_db_cr_flg := 'C';
        End If;
        
      End If;
      
      IF I            =1 THEN
        V_Gl_Acct_Cd := v_gla_porto;
        v_sl_acct_cd := v_sla_porto;
      ELSE
        V_Gl_Acct_Cd := v_gla_lr;
        V_Sl_Acct_Cd := v_sla_lr;
      End If;
      
      BEGIN
        Gen_Trx_Jur_Line_Nextg( v_doc_num, --p_doc_num
        V_DOC_REF,                         --P_DOC_REF_NUM
        P_DATE,                            --p_date
        P_DATE,                            --p_due_date
        P_DATE,                            --p_arap_due_date
        I,                                 --p_tal_id
        NULL,                              --p_acct_type
        V_Gl_Acct_Cd,                      --p_gl_acct_cd
        v_sl_acct_cd,                      --p_sl_acct_cd
        v_db_cr_flg,                       --p_db_cr_flg
        ABS(v_laba_rugi),                  --p_curr_val
        v_ledger_nar,                      --p_ledger_nar
        'IDR',                             --p_curr_cd
        NULL,                              --p_budget_cd
        NULL,                              --p_brch_cd
        p_folder_cd,                       --p_folder_cd ,
        'GL',                              --p_record_source
        'A',                               --p_approved_sts
        p_user_id, 'N',                    --p_manual
        v_error_code, V_ERROR_MSG);
      EXCEPTION
      WHEN OTHERS THEN
        V_Error_Code := -70;
        V_Error_Msg  := SUBSTR('insert T_ACCOUNT_LEDGER : '||v_doc_num||' '||SQLERRM,1,200);
        RAISE v_err;
      End;
      
      IF v_error_code < 0 THEN
        v_error_code := -75;
        V_ERROR_MSG  := SUBSTR(V_ERROR_MSG||' '||SQLERRM,1,200);
        RAISE v_err;
      End If;
      
    End Loop;
    
    --approve untuk header T_JVCHH
    BEGIN
      SP_T_MANY_APPROVE(V_MENU_NAME,--P_MENU_NAME,
      V_UPDATE_DATE,                --P_UPDATE_DATE,
      V_UPDATE_SEQ,                 --P_UPDATE_SEQ,
      P_USER_ID,                    --P_APPROVED_USER_ID,
      P_IP_ADDRESS,                 --P_APPROVED_IP_ADDRESS,
      v_error_code, V_ERROR_MSG);
    EXCEPTION
    WHEN OTHERS THEN
      V_Error_Code := -80;
      V_ERROR_MSG  :=SUBSTR('SP_T_MANY_APPROVE : '||' '||SQLERRM(SQLCODE),1,200);
      RAISE V_ERR;
    End;
    
    IF v_error_code <0 THEN
      v_error_code := -85;
      V_ERROR_MSG  :=SUBSTR('SP_T_MANY_APPROVE : '||V_ERROR_MSG,1,200);
      RAISE V_ERR;
    End If;
    
    V_Proses :='Y';
    
  End If;--END KENAIKAN PENURUNAN
  
  IF v_proses     ='N' THEN
    v_error_code := -90;
    V_ERROR_MSG  := 'Laba rugi '||v_laba_rugi ||' tidak ada jurnal yang dijurnal';
    RAISE V_ERR;
  End If;
  
  p_error_code:=1;
  p_error_msg :='';
EXCEPTION
WHEN NO_DATA_FOUND THEN
  NULL;
WHEN v_err THEN
  p_error_code := v_error_code;
  p_error_msg  := v_error_msg;
  ROLLBACK;
WHEN OTHERS THEN
  p_error_code := -1;
  p_error_msg  := SUBSTR(SQLERRM,1,200);
  ROLLBACK;
END SP_PORTO_MARKTOMARKET;