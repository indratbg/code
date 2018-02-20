create or replace PROCEDURE SP_GEN_TOS_PAYMENT_VCH(
    P_PAYREC_DATE DATE,
    P_CLIENT_CD   VARCHAR2,
    P_REMARKS     VARCHAR2,
    P_PEMBULATAN  NUMBER,
    P_FOLDER_CD   VARCHAR2,
    P_BANK_CD     VARCHAR2,
    P_USER_ID T_MANY_HEADER.USER_ID%TYPE,
    P_IP_ADDRESS T_MANY_HEADER.IP_ADDRESS%TYPE,
    P_ERROR_CODE OUT NUMBER,
    P_ERROR_MSG OUT VARCHAR2)
IS


  V_MENU_NAME T_MANY_HEADER.MENU_NAME%TYPE:='GENERATE PAYMENT TENDER OFFER SELL';
  V_UPDATE_DATE T_MANY_HEADER.UPDATE_DATE%TYPE;
  V_UPDATE_SEQ T_MANY_HEADER.UPDATE_SEQ%TYPE;
  V_GL_ACCT_CD T_PAYRECH.GL_ACCT_CD%TYPE;
  V_SL_ACCT_CD T_PAYRECH.SL_ACCT_CD%TYPE;
  v_err        EXCEPTION;
  v_error_msg  VARCHAR2(200);
  v_error_code NUMBER(5);
  V_RECORD_SEQ NUMBER;
  
  ---CURSOR UNTUK DETAIL DI PAYRECD
  CURSOR CSR_DATA
  IS
    SELECT b.TAL_ID, B.XN_DOC_NUM, B.FOLDER_CD, C.BRANCH_CODE brch_cd, C.CLIENT_CD, D.ACCT_NAME AS CLIENT_NAME,
      D.BANK_CD, D.BANK_BRANCH,C.BANK_ACCT_NUM, B.GL_ACCT_CD, B.SL_ACCT_CD, 'TENDER OFFER '  ||e.stk_cd ||' - '||B.SL_ACCT_CD REMARKS,
      B.CURR_VAL AS curr_amt,  f.bank_short_name rdi_bank_cd,
      'TENDER OFFER '|| E.stk_cd  ||' ' ||trim(TO_CHAR(E.qty,'9,999,999,999,999,999'))||' @' ||E.PRICE AS LEDGER_NAR,  C.OLT
    FROM T_PAYRECH A,
      T_ACCOUNT_LEDGER B,
      MST_CLIENT C,
      MST_CLIENT_BANK D,
      T_TENDER_OFFER_SELL E,
      MST_CLIENT_FLACCT F
    WHERE A.PAYREC_NUM  =B.XN_DOC_NUM
    AND B.SL_ACCT_CD    =C.CLIENT_CD
    --AND B.SL_ACCT_CD    = D.CLIENT_CD
    AND C.CIFS= D.CIFS
    AND C.BANK_ACCT_NUM=d.bank_acct_num
    AND C.BANK_CD=D.BANK_CD
    AND B.XN_DOC_NUM = E.RVPV_NUMBER
    AND B.SL_ACCT_CD    =E.CLIENT_CD
    AND B.SL_ACCT_CD    = F.CLIENT_CD
    AND C.CLIENT_TYPE_3 = 'R'
    --AND C.BANK_ACCT_NUM = D.BANK_ACCT_NUM
    AND A.PAYREC_DATE   = P_PAYREC_DATE
    AND E.PAYMENT_DT    = P_PAYREC_DATE
    AND B.SL_ACCT_CD    = P_CLIENT_CD
    AND A.ACCT_TYPE     ='TOS'
    AND F.ACCT_STAT     ='A'
    AND (B.SETT_VAL     < B.CURR_VAL)
    AND B.SETT_FOR_CURR =0
    ORDER BY E.STK_CD,
      C.BRANCH_CODE,
      B.SL_ACCT_CD;

  CURSOR CSR_GRP
  IS
    SELECT DISTINCT BRCH_CD, CLIENT_CD, CLIENT_NAME,  BANK_CD, BANK_ACCT_NUM,rdi_bank_cd,  OLT, GL_ACCT_CD,
      SL_ACCT_CD, SUM(CURR_AMT) OVER (PARTITION BY BRCH_CD,CLIENT_CD) AS TOTAL, P_REMARKS                                           AS remarks
    FROM
      (SELECT  C.BRANCH_CODE brch_cd, C.CLIENT_CD, C.CLIENT_NAME, C.OLT, D.BANK_CD,C.BANK_ACCT_NUM,
        B.GL_ACCT_CD,  B.SL_ACCT_CD, B.CURR_VAL AS curr_amt,f.bank_short_name rdi_bank_cd, e.stk_cd
      FROM T_PAYRECH A,
        T_ACCOUNT_LEDGER B,
        MST_CLIENT C,
        MST_CLIENT_BANK D,
        T_TENDER_OFFER_SELL E,
        MST_CLIENT_FLACCT F
      WHERE A.PAYREC_NUM  =B.XN_DOC_NUM
      AND B.SL_ACCT_CD    =C.CLIENT_CD
      --AND B.SL_ACCT_CD    = D.CLIENT_CD
      AND C.CIFS= D.CIFS
       AND C.BANK_ACCT_NUM=d.bank_acct_num
    AND C.BANK_CD=D.BANK_CD
      AND B.XN_DOC_NUM = E.RVPV_NUMBER
      AND B.SL_ACCT_CD    =E.CLIENT_CD
      AND B.SL_ACCT_CD    = F.CLIENT_CD
      AND C.CLIENT_TYPE_3 = 'R'
      --AND C.BANK_ACCT_NUM = D.BANK_ACCT_NUM
      AND A.PAYREC_DATE   =P_PAYREC_DATE
      AND E.PAYMENT_DT    = P_PAYREC_DATE
        --AND TRIM(C.BRANCH_CODE) like '$branch_cd'
      AND B.SL_ACCT_CD   = P_CLIENT_CD
      AND trim(A.ACCT_TYPE)    ='TOS'
      AND F.ACCT_STAT    ='A'
      AND (B.SETT_VAL    < B.CURR_VAL)
      AND B.SETT_FOR_CURR=0
      );
  v_sys_param_flg VARCHAR2(1);
  V_SEQNO         NUMBER;
  V_FOLDER_FLG MST_SYS_PARAM.DFLG1%TYPE;
  V_PAYREC_NUM T_PAYRECH.PAYREC_NUM%TYPE;
  v_folder_cd T_FOLDER.FOLDER_CD%TYPE;
  V_CLIENT_BANK_NAME T_PAYRECH.CLIENT_BANK_NAME%TYPE;
  V_FLD_MON T_FOLDER.FLD_MON%TYPE;
  V_RTN NUMBER(1);
  V_DOC_NUM T_FOLDER.DOC_NUM%TYPE;
  V_DOC_DATE DATE;
  V_DB_CR_FLG T_ACCOUNT_LEDGER.DB_CR_FLG%TYPE;
  V_TAL_ID T_ACCOUNT_LEDGER.TAL_ID%TYPE;
  v_round_gl_a MST_GLA_TRX.GL_A%TYPE;
  v_round_sl_a MST_GLA_TRX.SL_A%TYPE;
  V_BANK_SL_A T_ACCOUNT_LEDGER.SL_ACCT_CD%TYPE;
  V_BANK_GL_A T_ACCOUNT_LEDGER.GL_ACCT_CD%TYPE;
  V_CURR_VAL T_ACCOUNT_LEDGER.CURR_VAL%TYPE;
  V_LEDGER_NAR T_ACCOUNT_LEDGER.LEDGER_NAR%TYPE;
  V_CRE_DT DATE :=SYSDATE;
  V_RECORD_SOURCE T_ACCOUNT_LEDGER.RECORD_SOURCE%TYPE;
  V_USER_ID T_FOLDER.USER_ID%TYPE;
  V_DOC_REF_NUM T_ACCOUNT_LEDGER.DOC_REF_NUM%TYPE;
  V_ACCT_TYPE T_ACCOUNT_LEDGER.ACCT_TYPE%TYPE;
  V_BANK_CD MST_BANK_ACCT.BANK_CD%TYPE;
  v_transfer_fee T_CHEQ.deduct_fee%TYPE:=0;
  V_BALANCE T_PAYRECH.curr_amt%TYPE;
  --V_TAL_ID_ROUND NUMBER;
BEGIN

  BEGIN
    SELECT DSTR1, DSTR2  INTO V_BANK_GL_A,  V_BANK_SL_A
    FROM MST_SYS_PARAM
    WHERE PARAM_ID='GEN_PAYMENT_VOC_DIV'
    AND PARAM_CD1 ='GL_ACCT'
    AND PARAM_CD2 = P_BANK_CD;
  EXCEPTION
  WHEN OTHERS THEN
    v_error_code :=-10;
    v_error_msg  := SUBSTR('SELECT ACCOUNT CODE FROM MST_SYS_PARAM '||SQLERRM,1,200);
    RAISE v_err;
  END;
  
  BEGIN
    SELECT BANK_CD  INTO V_BANK_CD
    FROM MST_BANK_ACCT
    WHERE GL_ACCT_CD = V_BANK_GL_A
    AND SL_ACCT_CD   = V_BANK_SL_A;
  EXCEPTION
  WHEN OTHERS THEN
    v_error_code :=-20;
    v_error_msg  := SUBSTR('SELECT BAK_CD FROM MST_BANK_ACCT'||SQLERRM,1,200);
    RAISE v_err;
  END;
  
  BEGIN
    SELECT dflg1 INTO v_sys_param_flg FROM MST_SYS_PARAM
    WHERE param_id = 'SYSTEM'
    AND param_cd1  = 'DOC_REF';
  EXCEPTION
  WHEN OTHERS THEN
    v_error_code := -30;
    v_error_msg  := SUBSTR('Retrieve MST_SYS_PARAM for doc_ref'||SQLERRM,1,200);
    RAISE v_err;
  END;
  
  BEGIN
    SELECT DFLG1 INTO V_FOLDER_FLG
    FROM MST_SYS_PARAM
    WHERE param_id = 'SYSTEM'
    AND param_cd1  = 'VCH_REF';
  EXCEPTION
  WHEN OTHERS THEN
    V_ERROR_CODE :=-40;
    V_ERROR_MSG  :=SUBSTR('SELECT CLIENT_CD AB FROM MST_COMPANY'||SQLERRM,1,200);
    RAISE V_ERR;
  END;
  
  --T_PAYRECH
  IF P_PEMBULATAN<>0 THEN
    V_SEQNO      :=3;
  ELSE
    V_SEQNO :=2;
  END IF;
  
  --EXECUTE SP HEADER
  BEGIN
    Sp_T_Many_Header_Insert(V_MENU_NAME, 'I', P_USER_ID, P_IP_ADDRESS, NULL, V_UPDATE_DATE, V_UPDATE_SEQ, V_ERROR_CODE, V_ERROR_MSG);
  EXCEPTION
  WHEN OTHERS THEN
    V_ERROR_CODE := -50;
    V_ERROR_MSG  := SUBSTR('SP_T_MANY_HEADER_INSERT '|| SQLERRM(SQLCODE),1,200);
    RAISE V_ERR;
  END;
  
  ---------------------UNTUK HEADER T_PAYRECH DAN T_ACCOUNT_LEDGER-------------------
  FOR REC IN CSR_GRP
  LOOP
    IF P_PEMBULATAN <> 0 THEN
      V_BALANCE     := REC.TOTAL + P_PEMBULATAN;
    ELSE
      V_BALANCE := REC.TOTAL;
    END IF;
    
    --GET CLIENT_BANK_NAME
    BEGIN
      SELECT B.BANK_NAME||' '||A.BANK_BRANCH INTO V_CLIENT_BANK_NAME
      FROM MST_CLIENT_BANK A,
        MST_IP_BANK B,
        MST_CLIENT C
      WHERE A.BANK_CD     = B.BANK_CD
      AND B.APPROVED_STAT = 'A'
      AND A.CIFS     =C.CIFS
      AND A.BANK_ACCT_NUM = C.BANK_ACCT_NUM
      AND A.BANK_CD = C.BANK_CD
      AND C.CLIENT_CD     =REC.CLIENT_CD;
    EXCEPTION
    WHEN OTHERS THEN
      V_ERROR_CODE := -60;
      V_ERROR_MSG  := SUBSTR('SELECT CLIENT BANK NAME '|| SQLERRM(SQLCODE),1,200);
      RAISE V_ERR;
    END;
    
    --------------------CALL SP_T_PAYRECH_UPD-----------------------------------
    BEGIN
      SP_T_PAYRECH_UPD ( V_PAYREC_NUM, --P_SEARCH_PAYRECH_NUM
      V_PAYREC_NUM,                    --P_PAYRECH_NUM
      'PV',                            --PAYRECH_TYPE
      P_PAYREC_DATE,                   --P_PAYREC_DATE,
      'RDM',                           --P_ACCT_TYPE,
      V_BANK_SL_A,                     -- P_SL_ACCT_CD,
      'IDR',                           --P_CURR_CD,
      V_BALANCE,                       --P_CURR_AMT,
      REC.CLIENT_NAME,                 --P_PAYREC_FRTO,
      REC.REMARKS,                     --P_REMARKS,
      V_BANK_GL_A,                     -- P_GL_ACCT_CD,
      REC.CLIENT_CD,                   --P_CLIENT_CD,
      NULL,                            --P_CHECK_NUM,
      P_FOLDER_CD,                     --P_FOLDER_CD
      1,                               --P_NUM_CHEQ,
      REC.BANK_ACCT_NUM,               --P_CLIENT_BANK_ACCT,
      V_CLIENT_BANK_NAME,              --P_CLIENT_BANK_NAME,
      'N',                             --P_REVERSAL_JUR,
      P_USER_ID,                       --P_USER_ID
      V_CRE_DT,                        --P_CRE_DT,
      NULL,                            --P_UPD_BY,
      NULL,                            --P_UPD_DT,
      'I',                             --P_UPD_STATUS,
      p_ip_address, NULL,              --p_cancel_reason,
      V_UPDATE_DATE,                   -- p_update_date,
      V_UPDATE_SEQ,                    -- p_update_seq,
      1,                               --p_record_seq,
      V_ERROR_CODE,                    --p_error_code,
      V_ERROR_MSG                      --p_error_msg
      ) ;
    EXCEPTION
    WHEN OTHERS THEN
      V_ERROR_CODE := -70;
      V_ERROR_MSG  :=SUBSTR('SP_T_PAYRECH_UPD'||SQLERRM,1,200);
      RAISE V_ERR;
    END;
    
    IF V_ERROR_CODE <0 THEN
      V_ERROR_CODE := -80;
      V_ERROR_MSG  :=SUBSTR('SP_T_PAYRECH_UPD '||V_ERROR_MSG,1,200);
      RAISE V_ERR;
    END IF;
    --------------------END CALL SP_T_PAYRECH_UPD-----------------------------------
    
    ----------------GET TRANFER FEE---------------------------
    BEGIN
      SELECT F_TRANSFER_FEE(V_BALANCE, REC.BANK_CD, REC.rdi_bank_cd, REC.BRCH_CD, REC.OLT, 'Y', REC.CLIENT_CD)--AS:06Oct2017
      INTO v_transfer_fee
      FROM dual;
    EXCEPTION
    WHEN OTHERS THEN
      v_error_code := -90;
      v_error_msg  := SUBSTR('F_TRANSFER_FEE '||SQLERRM,1,200);
      RAISE v_err;
    END;
    ----------------END GET TRANFER FEE---------------------------
    
    IF v_transfer_fee > 0 THEN
      v_transfer_fee := v_transfer_fee * -1;
    END IF;
    
    ---------------------------------T_CHEQ----------------------------
    BEGIN
      Sp_T_CHEQ_Upd( V_PAYREC_NUM,-- P_SEARCH_RVPV_NUMBER
      1,                          --P_SEARCH_CHQ_SEQ
      P_FOLDER_CD,                --P_SEARCH_CHQ_NUM
      V_BANK_CD,                  --P_BANK_CD
      V_BANK_SL_A,                -- P_SL_ACCT_CD
      'RD',                       --P_BG_CQ_FLG
      P_FOLDER_CD,                -- P_CHQ_NUM
      P_PAYREC_DATE,              -- P_CHQ_DT
      V_BALANCE,                  -- P_CHQ_AMT
      V_PAYREC_NUM,               --P_RVPV_NUMBER
      'A',                        --P_CHQ_STAT
      REC.BANK_CD,                --P_PAYEE_BANK_CD
      REC.BANK_ACCT_NUM,          --P_PAYEE_ACCT_NUM
      v_transfer_fee,             --P_DEDUCT_FEE
      NULL,                       --P_PRINT_FLG
      NULL,                       --P_PR_TRF_FLG
      NULL,                       --P_UPD_USER_ID
      1,                          --P_SEQNO
      REC.CLIENT_NAME,            --P_PAYEE_NAME
      REC.CLIENT_NAME,            --P_DESCRIP
      1,                          --P_CHQ_SEQ
      P_USER_ID,                  -- P_USER_ID
      V_CRE_DT,                   -- P_CRE_DT
      NULL,                       --P_UPD_BY
      NULL,                       --P_UPD_DT
      'I',                        --P_UPD_STATUS
      P_IP_ADDRESS,               -- p_ip_address
      NULL,                       --p_cancel_reason
      V_UPDATE_DATE,              -- p_update_date
      V_UPDATE_SEQ,               -- p_update_seq
      1,                          --p_record_seq
      V_ERROR_CODE,               -- p_error_code
      V_ERROR_MSG                 -- p_error_msg
      ) ;
    EXCEPTION
    WHEN OTHERS THEN
      V_ERROR_CODE := -100;
      V_ERROR_MSG  :=SUBSTR('Sp_T_CHEQ_Upd'||SQLERRM,1,200);
      RAISE V_ERR;
    END;
    
    IF V_ERROR_CODE <0 THEN
      V_ERROR_CODE := -110;
      V_ERROR_MSG  :=SUBSTR('Sp_T_CHEQ_Upd '||V_ERROR_MSG,1,200);
      RAISE V_ERR;
    END IF;
    ---------------------------------T_CHEQ----------------------------
    
    ------------------------T_FOLDER--------------------------------
    IF V_FOLDER_FLG='Y' THEN
      V_FLD_MON   :=TO_CHAR(P_PAYREC_DATE,'MMYY');
      BEGIN
        SP_CHECK_FOLDER_CD( P_FOLDER_CD, P_PAYREC_DATE,--p_date
        V_RTN,                                         --p_rtn
        V_DOC_NUM,                                     -- p_doc_num
        V_USER_ID,                                     -- p_user_id
        V_DOC_DATE                                     --p_doc_date
        );
      EXCEPTION
      WHEN OTHERS THEN
        V_ERROR_CODE := -120;
        V_ERROR_MSG  :=SUBSTR('SP_CHECK_FOLDER_CD'||SQLERRM,1,200);
        RAISE V_ERR;
      END;
      
      IF V_ERROR_CODE <0 THEN
        V_ERROR_CODE := -130;
        V_ERROR_MSG  :=SUBSTR('SP_CHECK_FOLDER_CD '||V_ERROR_MSG,1,200);
        RAISE V_ERR;
      END IF;
      
      IF V_RTN        =1 THEN
        V_ERROR_CODE :=-140;
        V_ERROR_MSG  :='File Code '||v_folder_cd||' is already used by '||P_USER_ID||' '|| V_DOC_NUM||' '||V_DOC_DATE;
        RAISE V_ERR;
      END IF;
      
      BEGIN
        SP_T_FOLDER_UPD ( V_PAYREC_NUM,--P_SEARCH_DOC_NUM
        V_FLD_MON,                     --P_FLD_MON
        P_FOLDER_CD, P_PAYREC_DATE,    --P_DOC_DATE
        V_PAYREC_NUM,                  --P_DOC_NUM
        P_USER_ID,                     --P_USER_ID
        V_CRE_DT,                      --P_CRE_DT
        NULL,                          --P_UPD_BY
        NULL,                          --P_UPD_DT
        'I',                           --P_UPD_STATUS
        p_ip_address, NULL,            --p_cancel_reason
        V_UPDATE_DATE,                 --p_update_date
        V_UPDATE_SEQ,                  --p_update_seq
        1,                             --p_record_seq
        v_error_code,                  --p_error_code
        v_error_msg                    --p_error_msg
        );
      EXCEPTION
      WHEN OTHERS THEN
        V_ERROR_CODE := -150;
        V_ERROR_MSG  :=SUBSTR('SP_T_FOLDER_UPD'||SQLERRM,1,200);
        RAISE V_ERR;
      END;
      IF V_ERROR_CODE <0 THEN
        V_ERROR_CODE := -160;
        V_ERROR_MSG  :=SUBSTR('SP_T_FOLDER_UPD '||V_ERROR_MSG,1,200);
        RAISE V_ERR;
      END IF;
    END IF;--END V_FOLDER_FLG
    ------------------------END T_FOLDER--------------------------------
    
    ----GET ACCOUNT CODE ROUNDING---------------------
    BEGIN
      SELECT TRIM(A.GL_A),A.SL_A INTO v_round_gl_a, v_round_sl_a
       FROM MST_GL_ACCOUNT A,MST_BRANCH B, MST_GLA_TRX G
      WHERE JUR_TYPE='ROUND'
      AND TRIM(A.GL_A)=G.GL_A
      AND SUBSTR(A.SL_A,1,2)=B.ACCT_PREFIX
      AND A.APPROVED_STAT='A'
      AND B.APPROVED_STAT='A'
      AND B.BRCH_CD=TRIM(REC.BRCH_CD);
    EXCEPTION
    WHEN OTHERS THEN
      V_ERROR_CODE := -170;
      V_ERROR_MSG  := SUBSTR('SELECT ROUND ACCOUNT CODE FROM MST_GLA_TRX '|| SQLERRM(SQLCODE),1,200);
      RAISE V_ERR;
    END;
    ----END GET ACCOUNT CODE ROUNDING---------------------
    
    -----GET ACCT TYPE-------------------------
    BEGIN
      SELECT ACCT_TYPE  INTO V_ACCT_TYPE
      FROM MST_CLIENT A,
        MST_GL_ACCOUNT B
      WHERE A.CLIENT_CD=B.SL_A
      AND A.CLIENT_CD  =REC.CLIENT_CD
      AND TRIM(B.GL_A) =TRIM(REC.GL_ACCT_CD);
    EXCEPTION
    WHEN OTHERS THEN
      V_ERROR_CODE := -180;
      V_ERROR_MSG  :=SUBSTR('SELECT ACCT_TYPE FROM MST_GL_ACCOUNT'||SQLERRM,1,200);
      RAISE V_ERR;
    END;
    
    -----END GET ACCT TYPE-------------------------
    IF V_SYS_PARAM_FLG='Y' THEN
      V_DOC_REF_NUM  := V_PAYREC_NUM;
    ELSE
      V_DOC_REF_NUM :=NULL;
    END IF;
    
    ---------------T_ACCOUNT_LEDGER--------------------------
    FOR I IN 1..V_SEQNO
    LOOP
      IF V_SEQNO           =3 THEN
        IF I               =1 THEN
          V_TAL_ID        :=I;
          V_DB_CR_FLG     :='D';
          V_GL_ACCT_CD    :=REC.GL_ACCT_CD;
          V_SL_ACCT_CD    :=REC.SL_ACCT_CD;
          V_CURR_VAL      := REC.TOTAL;
          V_LEDGER_NAR    := REC.REMARKS;
          V_RECORD_SOURCE :='PV';
        ELSIF I            =2 THEN
          V_TAL_ID        :=I;
          V_GL_ACCT_CD    :=v_round_gl_a;
          V_SL_ACCT_CD    :=v_round_sl_a;
          V_CURR_VAL      := ABS(P_PEMBULATAN);
          V_LEDGER_NAR    := 'PBLTN';
          V_RECORD_SOURCE :='PVO';
          V_ACCT_TYPE     :=NULL;
          IF P_PEMBULATAN  >0 THEN
            V_DB_CR_FLG   :='D';
          ELSE
            V_DB_CR_FLG :='C';
          END IF;
        ELSE
          V_TAL_ID        :='555';
          V_GL_ACCT_CD    :=V_BANK_GL_A;
          V_SL_ACCT_CD    :=V_BANK_SL_A;
          V_CURR_VAL      := REC.TOTAL+P_PEMBULATAN;
          V_LEDGER_NAR    := REC.REMARKS;
          V_RECORD_SOURCE :='PV';
          V_ACCT_TYPE     :=NULL;
          --V_TAL_ID_ROUND  :=I;
          V_DB_CR_FLG :='C';
        END IF;
      ELSE
        V_LEDGER_NAR    := REC.REMARKS;
        V_RECORD_SOURCE :='PV';
        IF I             =1 THEN
          V_TAL_ID      :=I;
          V_DB_CR_FLG   :='D';
          V_GL_ACCT_CD  :=REC.GL_ACCT_CD;
          V_SL_ACCT_CD  :=REC.SL_ACCT_CD;
          V_CURR_VAL    := REC.TOTAL;
          V_ACCT_TYPE   :=NULL;
        ELSE
          V_TAL_ID     :='555';
          V_DB_CR_FLG  :='C';
          V_GL_ACCT_CD :=V_BANK_GL_A;
          V_SL_ACCT_CD :=V_BANK_SL_A;
          V_CURR_VAL   := REC.TOTAL;
          V_ACCT_TYPE  :=NULL;
        END IF;
      END IF;
      
      ---------------------------BEGIN T_ACCOUNT_LEDGER--------------------------
      BEGIN
        Sp_T_ACCOUNT_LEDGER_Upd( V_PAYREC_NUM,--P_SEARCH_XN_DOC_NUM,
        V_TAL_ID,                             --P_SEARCH_TAL_ID,
        V_PAYREC_NUM,                         --P_XN_DOC_NUM,
        V_TAL_ID,                             --P_TAL_ID,
        V_DOC_REF_NUM,                        --P_DOC_REF_NUM,
        V_ACCT_TYPE,                          --P_ACCT_TYPE,
        V_SL_ACCT_CD,                         --  P_SL_ACCT_CD,
        V_GL_ACCT_CD,                         -- P_GL_ACCT_CD,
        NULL,                                 --P_CHRG_CD,
        NULL,                                 --P_CHQ_SNO,
        'IDR',                                --P_CURR_CD,
        REC.brch_cd,                          --  P_BRCH_CD,
        V_CURR_VAL,                           -- P_CURR_VAL,
        V_CURR_VAL,                           -- P_XN_VAL,
        'PVCH',                               --P_BUDGET_CD,
        V_DB_CR_FLG,                          --P_DB_CR_FLG,
        V_LEDGER_NAR,                         --P_LEDGER_NAR,
        NULL,                                 --P_CASHIER_ID,
        P_PAYREC_DATE,                        --P_DOC_DATE,
        P_PAYREC_DATE,                        --P_DUE_DATE,
        P_PAYREC_DATE,                        --P_NETTING_DATE,
        NULL,                                 --P_NETTING_FLG,
        V_RECORD_SOURCE,                      --P_RECORD_SOURCE,
        0,                                    --P_SETT_FOR_CURR,
        NULL,                                 --P_SETT_STATUS,
        V_PAYREC_NUM,                         -- P_RVPV_NUMBER,
        v_folder_cd,                          --P_FOLDER_CD
        0,                                    --P_SETT_VAL,
        P_PAYREC_DATE,                        --P_ARAP_DUE_DATE,
        NULL,                                 --P_RVPV_GSSL,
        NULL,                                 --P_CASH_WITHDRAW_AMT,
        NULL,                                 --P_CASH_WITHDRAW_REASON,
        P_USER_ID,                            --P_USER_ID
        V_CRE_DT,                             --P_CRE_DT,
        NULL,                                 --P_UPD_BY,
        NULL,                                 --P_UPD_DT,
        'N',                                  --P_REVERSAL_JUR,
        'N',                                  --P_MANUAL,
        'I',                                  --P_UPD_STATUS,
        p_ip_address, NULL,                   --p_cancel_reason,
        V_UPDATE_DATE,                        -- p_update_date,
        V_UPDATE_SEQ,                         -- p_update_seq,
        I,                                    --p_record_seq,
        V_ERROR_CODE,                         -- p_error_code,
        V_ERROR_MSG                           --p_error_msg,
        );
      EXCEPTION
      WHEN OTHERS THEN
        V_ERROR_CODE := -190;
        V_ERROR_MSG  :=SUBSTR('Sp_T_ACCOUNT_LEDGER_Upd'||SQLERRM,1,200);
        RAISE V_ERR;
      END;
      IF V_ERROR_CODE <0 THEN
        V_ERROR_CODE := -200;
        V_ERROR_MSG  :=SUBSTR('Sp_T_ACCOUNT_LEDGER_Upd '||V_ERROR_MSG,1,200);
        RAISE V_ERR;
      END IF;
    END LOOP;
    -----------END T_ACCOUNT_LEDGER--------------------------
  END LOOP;
  --------------------- END UNTUK HEADER T_PAYRECH DAN T_ACCOUNT_LEDGER-------------------
  
  --------------------------BEGIN FOR T_PAYRECD AND SETTLE VOUCHER RECEIPT EACH CLIENT-----------------------------------
  V_RECORD_SEQ :=1;
  FOR REC IN CSR_DATA
  LOOP
    V_RECORD_SOURCE :='PDRD';
    
    ---------------------------CALL T_PAYRECD EACH CLIENT-------------------------------
    BEGIN
      Sp_T_PAYRECD_Upd( V_PAYREC_NUM,-- P_SEARCH_PAYREC_NUM
      V_DOC_REF_NUM,                 --P_SEARCH_DOC_REF_NUM
      REC.TAL_ID,                    --P_SEARCH_TAL_ID
      V_PAYREC_NUM,                  --P_PAYREC_NUM
      'PV',                          --P_PAYREC_TYPE
      P_PAYREC_DATE,                 --P_PAYREC_DATE
      REC.CLIENT_CD,                 --P_CLIENT_CD
      REC.GL_ACCT_CD,                --P_GL_ACCT_CD
      REC.SL_ACCT_CD,                --P_SL_ACCT_CD
      'D',                           --P_DB_CR_FLG
      REC.curr_amt,                  --P_PAYREC_AMT
      REC.XN_DOC_NUM,                --P_DOC_REF_NUM
      REC.TAL_ID,                    --P_TAL_ID
      REC.LEDGER_NAR,                -- P_REMARKS
      V_RECORD_SOURCE,               --P_RECORD_SOURCE
      P_PAYREC_DATE,                 --P_DOC_DATE
      REC.FOLDER_CD,                 -- P_REF_FOLDER_CD
      REC.XN_DOC_NUM,                -- P_GL_REF_NUM
      0,                             --P_SETT_FOR_CURR
      0,                             --P_SETT_VAL
      REC.brch_cd,                   -- P_BRCH_CD
      REC.TAL_ID,                    --P_DOC_TAL_ID
      NULL,                          --P_SOURCE_TYPE
      P_PAYREC_DATE,                 --P_DUE_DATE
      P_USER_ID,                     --P_USER_ID
      V_CRE_DT,                      --P_CRE_DT
      NULL,                          --P_UPD_BY
      NULL,                          --P_UPD_DT
      'I',                           --P_UPD_STATUS
      p_ip_address, NULL,            --p_cancel_reason
      V_UPDATE_DATE,                 -- p_update_date
      V_UPDATE_SEQ,                  --p_update_seq
      V_RECORD_SEQ,                  -- p_record_seq
      V_ERROR_CODE,                  -- p_error_code
      V_ERROR_MSG                    -- p_error_msg
      );
    EXCEPTION
    WHEN OTHERS THEN
      V_ERROR_CODE := -210;
      V_ERROR_MSG  :=SUBSTR('Sp_T_PAYRECD_Upd '||SQLERRM,1,200);
      RAISE V_ERR;
    END;
    
    IF V_ERROR_CODE <0 THEN
      V_ERROR_CODE := -220;
      V_ERROR_MSG  :=SUBSTR('Sp_T_PAYRECD_Upd '||V_ERROR_MSG,1,200);
      RAISE V_ERR;
    END IF;
    ---------------------------CALL T_PAYRECD EACH CLIENT-------------------------------
    
    -------------------CALL SP_Rvpv_Settled-------------------------------------
    BEGIN
      SP_Rvpv_Settled( REC.XN_DOC_NUM,-- p_contr_num
      REC.CLIENT_CD,                  --p_client_cd
      REC.CURR_AMT,                   --p_amt
      REC.XN_DOC_NUM,                 --p_gl_ref_num
      REC.GL_ACCT_CD,                 -- p_gl_acct_cd
      REC.tal_id,                     -- p_tal_id
      V_RECORD_SOURCE,                --p_record_source
      P_PAYREC_DATE,                  -- p_doc_date
      P_PAYREC_DATE,                  --p_due_date
      'I',                            --p_status
      p_user_id );
    EXCEPTION
    WHEN OTHERS THEN
      V_ERROR_CODE := -230;
      V_ERROR_MSG  :=SUBSTR('SP_Rvpv_Settled '||SQLERRM,1,200);
      RAISE V_ERR;
    END;
    
    IF V_ERROR_CODE <0 THEN
      V_ERROR_CODE := -240;
      V_ERROR_MSG  :=SUBSTR('SP_Rvpv_Settled '||V_ERROR_MSG,1,200);
      RAISE V_ERR;
    END IF;
    -------------------END SP_Rvpv_Settled-------------------------------------
    
    ----------------JIKA PEMBULATAN <> 0 TAMBAHKAN 1 BARIS PADA T_PAYRECD-------------------
    IF P_PEMBULATAN   <> 0  AND V_RECORD_SEQ=1 THEN
      V_LEDGER_NAR    := 'PBLTN';
      V_RECORD_SOURCE :='PVO';
      V_RECORD_SEQ    :=V_RECORD_SEQ+1;
      
      IF P_PEMBULATAN  >0 THEN
        V_DB_CR_FLG   :='D';
      ELSE
        V_DB_CR_FLG:='C';
      END IF;
      
      BEGIN
        Sp_T_PAYRECD_Upd( V_PAYREC_NUM,-- P_SEARCH_PAYREC_NUM
        V_DOC_REF_NUM,                 --P_SEARCH_DOC_REF_NUM
        '2',                --P_SEARCH_TAL_ID
        V_PAYREC_NUM,                  --P_PAYREC_NUM
        'PV',                          --P_PAYREC_TYPE
        P_PAYREC_DATE,                 --P_PAYREC_DATE
        REC.CLIENT_CD,                 --P_CLIENT_CD
        v_round_gl_a,                  --P_GL_ACCT_CD
        v_round_sl_a,                  --P_SL_ACCT_CD
        V_DB_CR_FLG,                   --P_DB_CR_FLG
        ABS(P_PEMBULATAN),             --P_PAYREC_AMT
        V_PAYREC_NUM,                  --P_DOC_REF_NUM
        '2',                --P_TAL_ID
        V_LEDGER_NAR,                  -- P_REMARKS
        V_RECORD_SOURCE,               --P_RECORD_SOURCE
        P_PAYREC_DATE,                 --P_DOC_DATE
        P_FOLDER_CD,                   -- P_REF_FOLDER_CD
        V_PAYREC_NUM,                  -- P_GL_REF_NUM
        0,                             --P_SETT_FOR_CURR
        0,                             --P_SETT_VAL
        REC.brch_cd,                   -- P_BRCH_CD
        '2',                --P_DOC_TAL_ID
        NULL,                          --P_SOURCE_TYPE
        P_PAYREC_DATE,                 --P_DUE_DATE
        P_USER_ID,                     --P_USER_ID
        V_CRE_DT,                      --P_CRE_DT
        NULL,                          --P_UPD_BY
        NULL,                          --P_UPD_DT
        'I',                           --P_UPD_STATUS
        p_ip_address, NULL,            --p_cancel_reason
        V_UPDATE_DATE,                 -- p_update_date
        V_UPDATE_SEQ,                  --p_update_seq
        V_RECORD_SEQ,                  -- p_record_seq
        V_ERROR_CODE,                  -- p_error_code
        V_ERROR_MSG                    -- p_error_msg
        );
      EXCEPTION
      WHEN OTHERS THEN
        V_ERROR_CODE := -250;
        V_ERROR_MSG  :=SUBSTR('Sp_T_PAYRECD_Upd '||SQLERRM,1,200);
        RAISE V_ERR;
      END;
      
      IF V_ERROR_CODE <0 THEN
        V_ERROR_CODE := -260;
        V_ERROR_MSG  :=SUBSTR('Sp_T_PAYRECD_Upd '||V_ERROR_MSG,1,200);
        RAISE V_ERR;
      END IF;
    END IF;
    ----------------JIKA PEMBULATAN <> 0 TAMBAHKAN 1 BARIS PADA T_PAYRECD-------------------
    V_RECORD_SEQ :=V_RECORD_SEQ+1;
  END LOOP;
  --------------------------END FOR T_PAYRECD-----------------------------------
  P_ERROR_CODE := 1;
  P_ERROR_MSG  := '';
  
EXCEPTION
WHEN NO_DATA_FOUND THEN
  NULL;
WHEN v_err THEN
  ROLLBACK;
  p_error_code := v_error_code;
  p_error_msg  := v_error_msg;
WHEN OTHERS THEN
  -- Consider logging the error and then re-raise
  ROLLBACK;
  p_error_code := -1;
  p_error_msg  := SUBSTR(SQLERRM(SQLCODE),1,200);
  RAISE;
END SP_GEN_TOS_PAYMENT_VCH;