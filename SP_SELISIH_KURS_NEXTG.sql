create or replace 
PROCEDURE SP_SELISIH_KURS_NEXTG(
    p_date DATE,
    p_Gl_acct_Cd T_ACCOUNT_LEDGER.GL_ACCT_CD%TYPE,
    P_Sl_acct_Cd T_ACCOUNT_LEDGER.SL_ACCT_CD%TYPE,
    P_FOLDER_CD T_ACCOUNT_LEDGER.FOLDER_CD%TYPE,
    P_USER_ID T_ACCOUNT_LEDGER.USER_ID%TYPE,
    P_IP_ADDRESS T_MANY_HEADER.IP_ADDRESS%TYPE,
    p_error_code OUT NUMBER,
    p_error_msg OUT VARCHAR2)
IS
  tmpVar NUMBER;
  /******************************************************************************
  NAME:       SP_SELISIH_KURS
  PURPOSE:
  REVISIONS:
  Ver        Date        Author           Description
  ---------  ----------  ---------------  ------------------------------------
  1.0        02/01/2015          1. Created this procedure.
  NOTES:
  Automatically available Auto Replace Keywords:
  Object Name:     SP_SELISIH_KURS
  Sysdate:         02/01/2015
  Date and Time:   02/01/2015, 15:55:20, and 02/01/2015 15:55:20
  Username:         (set in TOAD Options, Procedure Editor)
  Table Name:       (set in the "New PL/SQL Object" dialog)
  ******************************************************************************/
  V_bal_dt DATE;
  v_f_bal_amt t_bal_foreign_currency.bal_amount%type;
  v_selisih_kurs t_account_ledger.curr_Val%type;
  v_today_rate t_exch_rate.rate%type;
  v_prev_rate t_exch_rate.rate%type;
  v_xn_doc_num T_ACCOUNT_LEDGER.xn_doc_num%TYPE;
  v_db_cr_flg T_ACCOUNT_LEDGER.db_cr_flg%TYPE;
  v_ledger_nar T_ACCOUNT_LEDGER.ledger_nar%TYPE;
  v_err        EXCEPTION;
  v_error_code NUMBER;
  v_error_msg  VARCHAR2(200);
  V_MENU_NAME T_MANY_HEADER.MENU_NAME%type :='GENENERATE SELISIH KURS';
  V_UPDATE_DATE T_MANY_HEADER.UPDATE_DATE%TYPE;
  V_UPDATE_SEQ T_MANY_HEADER.UPDATE_SEQ%TYPE;
  V_FOLDER VARCHAR2(1);
  V_FLD_MON T_FOLDER.FLD_MON%TYPE;
  V_FOLDER_CD T_FOLDER.FOLDEr_CD%TYPE;
  V_DOC_NUM T_FOLDER.DOC_NUM%TYPE;
  V_RTN NUMBER(2);
  V_DOC_DATE T_FOLDER.DOC_DATE%TYPE;
  V_USER_ID T_FOLDER.USER_ID%TYPE;
BEGIN
  BEGIN
    SELECT t.bal_amount,
      NVL(t.bal_amount,0) * (NVL(e.rate,0) - NVL(r.rate,0) ) AS selisih_kurs,
      e.rate                                                 AS today_rate,
      r.rate                                                 AS prev_rate
    INTO v_f_bal_amt,
      v_selisih_kurs,
      v_today_rate,
      v_prev_rate
    FROM
      (SELECT MAX(BAL_DT) AS max_dt
      FROM T_BAL_FOREIGN_CURRENCY
      WHERE GL_ACCT_CD = P_GL_ACCT_CD
      AND SL_ACCT_CD   = P_SL_ACCT_CD
      AND BAL_DT      <= P_DATE
      AND APPROVED_STS='A'
      ) a,
      T_BAL_FOREIGN_CURRENCY t,
      ( SELECT curr_cd, rate FROM t_exch_rate WHERE exch_dt = p_date
      ) e,
      (SELECT g.curr_Cd,
        g.rate
      FROM
        (SELECT curr_cd,
          MAX(exch_dt) max_exch_Dt
        FROM t_exch_rate
        WHERE EXCH_DT < P_DATE
        AND APPROVED_STAT='A'
        GROUP BY curr_Cd
        ) f,
        t_exch_rate g
      WHERE f.curr_cd   = g.curr_cd
      AND F.MAX_EXCH_DT = G.EXCH_DT
      ) r
    WHERE t.GL_ACCT_CD = P_GL_ACCT_CD
    AND t.SL_ACCT_CD   = P_SL_ACCT_CD
    AND t.bal_Dt       = a.max_dt
    AND t.curr_cd      = e.curr_cd(+)
    AND t.curr_cd      = r.curr_cd(+);
  EXCEPTION
  WHEN OTHERS THEN
    v_error_code := -10;
    v_error_msg  := SUBSTR('Selisih Kurs NOL '||SQLERRM,1,200);
    RAISE V_ERR;
  END;
  
  IF v_f_bal_amt IS NULL THEN
    v_error_code := -20;
    v_error_msg  := SUBSTR('Foreign curr balance not found ',1,200);
    RAISE v_err;
  END IF;
  
  IF v_today_rate IS NULL THEN
    v_error_code  := -30;
    v_error_msg   := SUBSTR('today  exchange rate NOT FOUND ',1,200);
    RAISE v_err;
  END IF;
  
  IF v_prev_rate IS NULL THEN
    v_error_code := -40;
    v_error_msg  := SUBSTR('previous exchange rate NOT FOUND ',1,200);
    RAISE v_err;
  END IF;
  
  IF v_selisih_kurs = 0 THEN
    v_error_code   := -50;
    v_error_msg    := SUBSTR('Selisih Kurs NOL ',1,200);
    RAISE v_err;
  END IF;
  --EXECUTE T MANY HEADER
  
  BEGIN
    Sp_T_Many_Header_Insert(V_MENU_NAME, 'I', P_USER_ID, P_IP_ADDRESS, NULL, V_UPDATE_DATE, V_UPDATE_SEQ, v_error_code, v_error_msg);
  EXCEPTION
  WHEN OTHERS THEN
    v_error_code := -110;
    v_error_msg  := SUBSTR('SP_T_MANY_HEADER_INSERT '|| SQLERRM(SQLCODE),1,200);
    RAISE V_ERR;
  END;
  
  IF V_ERROR_CODE <0 THEN
    v_error_code := -55;
    v_error_msg  :=SUBSTR('Sp_T_Many_Header_Insert : '||SQLERRM(SQLCODE),1,200);
    RAISE v_err;
  END IF;
  
  BEGIN
    SELECT DFLG1
    INTO V_FOLDER
    FROM MST_SYS_PARAM
    WHERE PARAM_ID='SYSTEM'
    AND PARAM_CD1 ='VCH_REF';
  EXCEPTION
  WHEN OTHERS THEN
    v_error_code := -72;
    v_error_msg  := SUBSTR('CEK PENGGUNAAN FOLDER CD PADA MST_SYS_PARAM '||SQLERRM,1,200);
    RAISE v_err;
  END;
  
  IF V_FOLDER='Y' THEN
  
    BEGIN
      SP_CHECK_FOLDER_CD( P_FOLDER_CD, P_DATE, V_RTN, V_DOC_NUM, V_USER_ID, V_DOC_DATE);
    EXCEPTION
    WHEN OTHERS THEN
      V_ERROR_CODE := -190;
      V_ERROR_MSG  := SUBSTR('SP_CHECK_FOLDER_CD '|| SQLERRM(SQLCODE),1,200);
      RAISE V_ERR;
    END;
    
    IF V_ERROR_CODE <0 THEN
      V_ERROR_CODE := -200;
      V_ERROR_MSG  := SUBSTR('SP_CHECK_FOLDER_CD '|| V_ERROR_MSG,1,200);
      RAISE V_ERR;
    END IF;
    
    IF V_RTN        =1 THEN
      V_ERROR_CODE := -210;
      V_ERROR_MSG  := 'File Code '||P_FOLDER_CD||' is already used by '||V_USER_ID|| ' '||V_DOC_NUM|| ' '|| TO_CHAR(P_DATE,'DD-MON-YYYY');
      RAISE V_ERR;
    END IF;
    
    V_FOLDER_CD :=P_FOLDER_CD;
    
  ELSE
    V_FOLDER_CD :='';
  END IF;
  --v_xn_doc_num := GET_DOCNUM_JVCH(p_date,'GL');
  v_xn_doc_num     :=Get_Docnum_Gl(p_date,'GL');
  IF v_selisih_kurs > 0 THEN
    v_db_cr_flg    := 'D';
  ELSE
    v_db_cr_flg := 'C';
  END IF;
  v_ledger_nar := 'SELISIH KURS';
  --03MAY2016
  /*
  Gen_GLJur_LINE(
  p_date,
  p_folder_cd,
  v_xn_doc_num,
  1,
  p_gl_acct_cd,
  p_sl_acct_cd,
  v_db_cr_flg,
  abs(v_selisih_kurs),
  v_ledger_nar,
  p_user_id);
  */
  BEGIN
    INSERT
    INTO T_ACCOUNT_LEDGER
      (
        XN_DOC_NUM,
        TAL_ID,
        ACCT_TYPE,
        SL_ACCT_CD,
        GL_ACCT_CD,
        BRCH_CD,
        CURR_VAL,
        SETT_VAL,
        DB_CR_FLG,
        LEDGER_NAR,
        USER_ID,
        CRE_DT,
        DOC_DATE,
        DUE_DATE ,
        RECORD_SOURCE,
        APPROVED_DT,
        APPROVED_STS,
        FOLDER_CD,
        MANUAL,
        approved_by,
        xn_val,
        budget_Cd,
        CURR_CD,
        SETT_FOR_CURR,
        RVPV_NUMBER,
        reversal_jur
      )
      VALUES
      (
        V_XN_DOC_NUM,
        1,
        NULL,
        P_SL_ACCT_CD,
        P_GL_ACCT_CD,
        NULL,
        ABS(V_SELISIH_KURS),
        0,
        v_db_cr_flg,
        v_ledger_nar,
        p_user_id,
        sysdate,
        p_date,
        p_date,
        'GL',
        Sysdate,
        'A',
        V_FOLDER_CD,
        'N',
        P_USER_ID,
        ABS(v_selisih_kurs),
        NULL,
        'IDR',
        0,
        V_XN_DOC_NUM,
        'N'
      );
  EXCEPTION
  WHEN OTHERS THEN
    v_error_code := -60;
    v_error_msg  :=SUBSTR('Reversal of AR/AP to T_ACCOUNT_LEDGER  '||SQLERRM(SQLCODE),1,200);
    RAISE v_err;
  END;
  IF v_db_cr_flg = 'D' THEN
    v_db_cr_flg := 'C';
  ELSE
    v_db_cr_flg := 'D';
  END IF;
  --03MAY2016
  /*   Gen_GLJur_LINE(
  p_date,
  p_folder_cd,
  v_xn_doc_num,
  2,
  '6550',
  '000000',
  v_db_cr_flg,
  abs(v_selisih_kurs),
  v_ledger_nar,
  p_user_id);
  */
  BEGIN
  
    INSERT
    INTO T_ACCOUNT_LEDGER
      (
        XN_DOC_NUM,
        TAL_ID,
        ACCT_TYPE,
        SL_ACCT_CD,
        GL_ACCT_CD,
        BRCH_CD,
        CURR_VAL,
        SETT_VAL,
        DB_CR_FLG,
        LEDGER_NAR,
        USER_ID,
        CRE_DT,
        DOC_DATE,
        DUE_DATE ,
        RECORD_SOURCE,
        APPROVED_DT,
        APPROVED_STS,
        FOLDER_CD,
        MANUAL,
        approved_by,
        xn_val,
        budget_Cd,
        CURR_CD,
         SETT_FOR_CURR,
        RVPV_NUMBER,
        reversal_jur
      )
      VALUES
      (
        V_XN_DOC_NUM,
        2,
        NULL,
        '000000',
        '6500',
        NULL,
        ABS(V_SELISIH_KURS),
        0,
        v_db_cr_flg,
        V_LEDGER_NAR,
        P_USER_ID,
        SYSDATE,
        p_date,
        p_date,
        'GL',
        Sysdate,
        'A',
        V_FOLDER_CD,
        'N',
        P_USER_ID,
        ABS(V_SELISIH_KURS),
        NULL,
        'IDR',
         0,
        V_XN_DOC_NUM,
        'N'
      );
  EXCEPTION
  WHEN OTHERS THEN
    v_error_code := -70;
    v_error_msg  :=SUBSTR('INSERT INTO T_ACCOUNT_LEDGER  '||SQLERRM(SQLCODE),1,200);
    RAISE v_err;
  END;
  
  IF V_FOLDER  ='Y' THEN
    V_FLD_MON := TO_CHAR(P_DATE,'MMYY');
    
    BEGIN
      SP_T_FOLDER_UPD (V_XN_DOC_NUM, V_FLD_MON, V_FOLDER_CD, p_date, v_xn_doc_num, P_USER_ID, SYSDATE, NULL,--P_UPD_BY,
      NULL,                                                                                                 --P_UPD_DT,
      'I',                                                                                                  --P_UPD_STATUS,
      p_ip_address, NULL, V_update_date, v_update_seq, 1, v_error_code, v_error_msg );
    EXCEPTION
    WHEN OTHERS THEN
      v_error_code := -35;
      v_error_msg  := SUBSTR('SP_T_FOLDER_UPD '||SQLERRM(SQLCODE),1,200);
      RAISE v_err;
    END;
    
    IF v_error_code <0 THEN
      v_error_code := -40;
      v_error_msg  := SUBSTR('SP_T_FOLDER_UPD '||v_error_msg||' '||SQLERRM,1,200);
      RAISE v_err;
    END IF;
    
  END IF;
  
  BEGIN
    Sp_T_Jvchh_Upd(v_xn_doc_num, v_xn_doc_num, 'GL', P_DATE, NULL, NULL, 'IDR', ABS(v_selisih_kurs), v_ledger_nar, P_USER_ID, SYSDATE, NULL, P_FOLDER_CD, 'N', 'I', p_ip_address, NULL, V_UPDATE_DATE, V_UPDATE_SEQ, 1, v_error_code, v_error_msg);
  EXCEPTION
  WHEN OTHERS THEN
    v_error_code := -90;
    v_error_msg  :=SUBSTR('Sp_T_JVCHH_Upd: '||v_xn_doc_num||SQLERRM(SQLCODE),1,200);
    RAISE v_err;
  END;
  
  IF V_ERROR_CODE <0 THEN
    v_error_code := -95;
    v_error_msg  :=SUBSTR('Sp_T_JVCHH_Upd : '||v_xn_doc_num||SQLERRM(SQLCODE),1,200);
    RAISE v_err;
  END IF;
  
  BEGIN
    Sp_T_Many_Approve( V_MENU_NAME, V_update_date, V_UPDATE_SEQ, p_user_id, p_ip_address, v_error_code, v_error_msg);
  EXCEPTION
  WHEN OTHERS THEN
    v_error_code := -105;
    v_error_msg  :=SUBSTR('Sp_T_Many_Approve: '||SQLERRM,1,200);
    RAISE v_err;
  END;
  
  IF V_ERROR_CODE <0 THEN
    v_error_code := -110;
    v_error_msg  :=SUBSTR('Sp_T_Many_Approve : '||SQLERRM,1,200);
    RAISE v_err;
  END IF;
  
  p_error_code := 1;
  p_error_msg  := '';
EXCEPTION
WHEN NO_DATA_FOUND THEN
  p_error_code := -1;
  p_error_msg  := SUBSTR(SQLERRM,1,200);
WHEN v_err THEN
  p_error_code := v_error_code;
  p_error_msg  := v_error_msg;
  ROLLBACK;
WHEN OTHERS THEN
  ROLLBACK;
  p_error_code := -1;
  p_error_msg  := SUBSTR(SQLERRM,1,200);
  RAISE;
END SP_SELISIH_KURS_NEXTG;