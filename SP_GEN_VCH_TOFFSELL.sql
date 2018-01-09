create or replace PROCEDURE SP_GEN_VCH_TOFFSELL(
    P_PAYMENT_DATE DATE,
    P_STK_CD       VARCHAR2,
    P_FOLDER_CD    VARCHAR2,
    P_BRANCH_CD    VARCHAR2,
    P_USER_ID T_MANY_HEADER.USER_ID%TYPE,
    P_IP_ADDRESS T_MANY_HEADER.IP_ADDRESS%TYPE,
    P_ERROR_CODE OUT NUMBER,
    P_ERROR_MSG OUT VARCHAR2)
IS
  CURSOR CSR_CLIENT
  IS
    SELECT A.*,'TENDER OFFER SELL '||STK_CD||' '||TRIM(TO_CHAR(QTY,'9,999,999,999,999,999'))||' @'||PRICE LEDGER_NAR, SUM(NET_AMT)OVER() TOTAL
    FROM T_TENDER_OFFER_SELL A
    JOIN MST_CLIENT B
    ON A.CLIENT_CD=B.CLIENT_CD
    WHERE CA_TYPE ='TOFFSELL'
    AND STK_CD    =P_STK_CD
    AND PAYMENT_DT    =P_PAYMENT_DATE
    AND TRIM(BRANCH_CODE) LIKE P_BRANCH_CD
    ORDER BY A.CLIENT_CD;
  V_TAL_ID NUMBER;
  V_AB_GL_A T_PAYRECH.GL_ACCT_CD%TYPE;
  V_AB_SL_A T_PAYRECH.SL_ACCT_CD%TYPE;
  V_CHECK_BRANCH MST_SYS_PARAM.DFLG1%TYPE;
  V_ERROR_CODE NUMBER;
  V_ERROR_MSG  VARCHAR2(200);
  V_ERR        EXCEPTION;
  V_MENU_NAME T_MANY_HEADER.MENU_NAME%TYPE:='GENERATE VOUCHER TENDER OFFER SELL';
  V_UPDATE_DATE T_MANY_HEADER.UPDATE_DATE%TYPE;
  V_UPDATE_SEQ T_MANY_HEADER.UPDATE_SEQ%TYPE;
  V_CLIENT_AB T_ACCOUNT_LEDGER.SL_ACCT_CD%TYPE;
  V_PAYREC_NUM T_PAYRECH.PAYREC_NUM%TYPE;
  V_GL_ACCT_CD T_PAYRECH.GL_ACCT_CD%TYPE;
  V_SL_ACCT_CD T_PAYRECH.SL_ACCT_CD%TYPE;
  V_BRANCH MST_GL_ACCOUNT.BRCH_CD%TYPE;
  V_CLIENT_CD T_PAYRECH.CLIENT_CD%TYPE;
  V_DOC_REF_NUM T_ACCOUNT_LEDGER.DOC_REF_NUM%TYPE;
  V_REF_FLG MST_SYS_PARAM.DFLG1%TYPE;
  V_ACCT_TYPE T_ACCOUNT_LEDGER.ACCT_TYPE%TYPE;
  V_RECORD_SEQ NUMBER(5);
  V_FLD_MON T_FOLDER.FLD_MON%TYPE;
  V_RTN NUMBER(1);
  V_DOC_NUM T_FOLDER.DOC_NUM%TYPE;
  V_DOC_DATE DATE;
  V_USER_ID T_FOLDER.USER_ID%TYPE;
  V_CNT NUMBER;
  V_FOLDER_FLG MST_SYS_PARAM.DFLG1%TYPE;
  V_CNT_STK   NUMBER:=0;
  V_BRANCH_CD VARCHAR2(2);
BEGIN

  BEGIN
    SELECT DSTR1, DSTR2
    INTO V_AB_GL_A, V_AB_SL_A
    FROM MST_SYS_PARAM
    WHERE param_id='VOUCHER TENDER OFFER'
    AND PARAM_CD1 ='GL ACCT'
    AND PARAM_CD2 ='PORTO';
  EXCEPTION
  WHEN OTHERS THEN
    V_ERROR_CODE :=-10;
    V_ERROR_MSG  :=SUBSTR('SELECT ACCOUNT CODE BROKER FROM MST_SYS_PARAM'||SQLERRM,1,200);
    RAISE V_ERR;
  END;
  
  BEGIN
    SELECT DFLG1
    INTO V_CHECK_BRANCH
    FROM MST_SYS_PARAM
    WHERE param_id='SYSTEM'
    AND PARAM_CD1 ='CHECK'
    AND param_cd2 ='ACCTBRCH';
  EXCEPTION
  WHEN OTHERS THEN
    V_ERROR_CODE :=-20;
    V_ERROR_MSG  :=SUBSTR('CHECK USING BRANCH FROM MST_SYS_PARAM'||SQLERRM,1,200);
    RAISE V_ERR;
  END;
  
  BEGIN
    SELECT TRIM(OTHER_1) INTO V_CLIENT_AB FROM MST_COMPANY;
  EXCEPTION
  WHEN OTHERS THEN
    V_ERROR_CODE :=-30;
    V_ERROR_MSG  :=SUBSTR('SELECT CLIENT_CD AB FROM MST_COMPANY'||SQLERRM,1,200);
    RAISE V_ERR;
  END;
  
  BEGIN
    SELECT DSTR1, DSTR2, PARAM_CD3
    INTO V_GL_ACCT_CD, V_SL_ACCT_CD, V_BRANCH
    FROM MST_SYS_PARAM
    WHERE param_id='VOUCHER TENDER OFFER'
    AND PARAM_CD1 ='GL ACCT'
    AND PARAM_CD2 ='BANK'
    AND PARAM_CD3 LIKE '%' ||P_BRANCH_CD;
  EXCEPTION
  WHEN OTHERS THEN
    V_ERROR_CODE :=-40;
    V_ERROR_MSG  :=SUBSTR('SELECT GL BANK FROM MST_SYS_PARAM'||SQLERRM,1,200);
    RAISE V_ERR;
  END;
  
  BEGIN
    SELECT DFLG1
    INTO V_REF_FLG
    FROM MST_SYS_PARAM
    WHERE param_id = 'SYSTEM'
    AND param_cd1  = 'DOC_REF';
  EXCEPTION
  WHEN OTHERS THEN
    V_ERROR_CODE :=-50;
    V_ERROR_MSG  :=SUBSTR('SELECT CLIENT_CD AB FROM MST_COMPANY'||SQLERRM,1,200);
    RAISE V_ERR;
  END;
  
  BEGIN
    SELECT DFLG1
    INTO V_FOLDER_FLG
    FROM MST_SYS_PARAM
    WHERE param_id = 'SYSTEM'
    AND param_cd1  = 'VCH_REF';
  EXCEPTION
  WHEN OTHERS THEN
    V_ERROR_CODE :=-60;
    V_ERROR_MSG  :=SUBSTR('SELECT CLIENT_CD AB FROM MST_COMPANY'||SQLERRM,1,200);
    RAISE V_ERR;
  END;
  
  --EXECUTE SP HEADER
  BEGIN
    Sp_T_Many_Header_Insert(V_MENU_NAME, 'I', P_USER_ID, P_IP_ADDRESS, NULL, V_UPDATE_DATE, V_UPDATE_SEQ, V_ERROR_CODE, V_ERROR_MSG);
  EXCEPTION
  WHEN OTHERS THEN
    V_ERROR_CODE := -70;
    V_ERROR_MSG  := SUBSTR('SP_T_MANY_HEADER_INSERT '|| SQLERRM(SQLCODE),1,200);
    RAISE V_ERR;
  END;
  
  --BUAT  VOUCHER
  V_RECORD_SEQ:=1;
  V_TAL_ID    :=2;
  
  FOR JUR IN CSR_CLIENT
  LOOP--SETT FOLDER CD
  
    IF V_CHECK_BRANCH='N' THEN
      V_BRANCH      := V_BRANCH;
      V_CLIENT_CD   := TRIM(V_BRANCH)||JUR.STK_CD;
    ELSE
      V_BRANCH    := P_BRANCH_CD;
      V_CLIENT_CD := TRIM(V_BRANCH)||JUR.STK_CD||TO_CHAR(JUR.TRX_DT,'DDMMYY');
    END IF;
    
    
    V_CNT_STK         :=1;
    IF V_RECORD_SEQ    =1 THEN
    
    --cek apakah sudah dibuat voucher
    BEGIN
    SELECT COUNT(1) INTO V_CNT FROM T_PAYRECH WHERE PAYREC_DATE=JUR.PAYMENT_DT AND CLIENT_CD=V_CLIENT_CD AND trim(ACCT_TYPE)='TOS';
    EXCEPTION
    WHEN OTHERS THEN
      V_ERROR_CODE := -77;
      V_ERROR_MSG  := SUBSTR('CHECK VOUCHER FROM T_PAYRECH '|| SQLERRM(SQLCODE),1,200);
      RAISE V_ERR;
    END;

    IF V_CNT        >0 THEN
      V_ERROR_CODE := -78;
      V_ERROR_MSG  := 'Voucher sudah dibuat';
      RAISE V_ERR;
    END IF;

    
    --CEK MASIH ADA BELUM DIAPPROVE
    BEGIN
      SELECT COUNT(*)
      INTO V_CNT
      FROM T_MANY_HEADER A, T_MANY_DETAIL B
      WHERE A.UPDATE_DATE  =B.UPDATE_DATE
      AND A.UPDATE_SEQ     =B.UPDATE_SEQ
      AND A.APPROVED_STATUS='E'
      AND MENU_NAME        =V_MENU_NAME
      AND B.TABLE_NAME     ='T_PAYRECH'
      AND B.FIELD_NAME     ='CLIENT_CD'
      AND B.FIELD_VALUE    =V_CLIENT_CD;
    EXCEPTION
    WHEN OTHERS THEN
      V_ERROR_CODE := -80;
      V_ERROR_MSG  := SUBSTR('SP_T_MANY_HEADER_INSERT '|| SQLERRM(SQLCODE),1,200);
      RAISE V_ERR;
    END;
    
    IF V_CNT        >0 THEN
      V_ERROR_CODE := -90;
      V_ERROR_MSG  := 'Masih ada yang belum diapprove';
      RAISE V_ERR;
    END IF;
    
      IF V_REF_FLG     ='Y' THEN
        V_DOC_REF_NUM := V_PAYREC_NUM;
      END IF;
      
      --CALL SP_T_PAYRECH_UPD
      BEGIN
        SP_T_PAYRECH_UPD ( V_PAYREC_NUM,                --P_SEARCH_PAYRECH_NUM
        V_PAYREC_NUM,                                   --P_PAYRECH_NUM
        'RD',                                           --PAYRECH_TYPE
        JUR.PAYMENT_DT,                                 --P_PAYREC_DATE,
        'TOS',                                          --P_ACCT_TYPE,
        V_SL_ACCT_CD,                                   -- P_SL_ACCT_CD,
        'IDR',                                          --P_CURR_CD,
        JUR.TOTAL,                                      --P_CURR_AMT,
        NULL,                                           --P_PAYREC_FRTO,
        'TENDER OFFER SELL '||P_STK_CD||' @'||JUR.PRICE,--P_REMARKS,
        V_GL_ACCT_CD,                                   -- P_GL_ACCT_CD,
        V_CLIENT_CD,                                    --P_CLIENT_CD,
        NULL,                                           --P_CHECK_NUM,
        P_FOLDER_CD, NULL,                              --P_NUM_CHEQ,
        NULL,                                           --P_CLIENT_BANK_ACCT,
        NULL,                                           --P_CLIENT_BANK_NAME,
        'N',                                            --P_REVERSAL_JUR,
        P_USER_ID, SYSDATE,                             --P_CRE_DT,
        NULL,                                           --P_UPD_BY,
        NULL,                                           --P_UPD_DT,
        'I',                                            --P_UPD_STATUS,
        p_ip_address, NULL,                             --p_cancel_reason,
        V_UPDATE_DATE,                                  -- p_update_date,
        V_UPDATE_SEQ,                                   -- p_update_seq,
        1,                                              --p_record_seq,
        V_ERROR_CODE,                                   --p_error_code,
        V_ERROR_MSG                                     --p_error_msg
        ) ;
      EXCEPTION
      WHEN OTHERS THEN
        V_ERROR_CODE := -100;
        V_ERROR_MSG  :=SUBSTR('SP_T_PAYRECH_UPD'||SQLERRM,1,200);
        RAISE V_ERR;
      END;
      
      IF V_ERROR_CODE <0 THEN
        V_ERROR_CODE := -110;
        V_ERROR_MSG  :=SUBSTR('SP_T_PAYRECH_UPD '||V_ERROR_MSG,1,200);
        RAISE V_ERR;
      END IF;
      
      IF V_FOLDER_FLG='Y' THEN
      
        V_FLD_MON   :=TO_CHAR(JUR.PAYMENT_DT,'MMYY');
        
        BEGIN
          SP_CHECK_FOLDER_CD( P_FOLDER_CD, JUR.PAYMENT_DT,--p_date
          V_RTN,                                      --p_rtn
          V_DOC_NUM,                                  -- p_doc_num
          V_USER_ID,                                  -- p_user_id
          V_DOC_DATE                                  --p_doc_date
          );
        EXCEPTION
        WHEN OTHERS THEN
          V_ERROR_CODE := -120;
          V_ERROR_MSG  :=SUBSTR('SP_T_PAYRECH_UPD'||SQLERRM,1,200);
          RAISE V_ERR;
        END;
        
        IF V_ERROR_CODE <0 THEN
          V_ERROR_CODE := -130;
          V_ERROR_MSG  :=SUBSTR('SP_T_PAYRECH_UPD '||V_ERROR_MSG,1,200);
          RAISE V_ERR;
        END IF;
        
        IF V_RTN        =1 THEN
          V_ERROR_CODE :=-140;
          V_ERROR_MSG  :='File Code '||P_FOLDER_CD||' is already used by '||P_USER_ID||' '|| V_DOC_NUM||' '||V_DOC_DATE;
          RAISE V_ERR;
        END IF;
        
        BEGIN
          SP_T_FOLDER_UPD ( V_PAYREC_NUM,--P_SEARCH_DOC_NUM
          V_FLD_MON,                     --P_FLD_MON
          P_FOLDER_CD, JUR.PAYMENT_DT,   --P_DOC_DATE
          V_PAYREC_NUM,                  --P_DOC_NUM
          P_USER_ID, SYSDATE,            --P_CRE_DT
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
          V_ERROR_MSG  :=SUBSTR('SP_T_PAYRECH_UPD'||SQLERRM,1,200);
          RAISE V_ERR;
        END;
        
        IF V_ERROR_CODE <0 THEN
          V_ERROR_CODE := -160;
          V_ERROR_MSG  :=SUBSTR('SP_T_PAYRECH_UPD '||V_ERROR_MSG,1,200);
          RAISE V_ERR;
        END IF;
      END IF;--END V_FOLDER_FLG
    END IF;  --END V_RECORD_SEQ=1
    
    ------------UPDATE RVPV NUMBER T_TENDER_OFFER_SELL----------------
    BEGIN
      Sp_T_TENDER_OFFER_SELL_UPD(JUR.CA_TYPE ,--P_SEARCH_CA_TYPE
      P_STK_CD,                               --P_SEARCH_STK_CD
      JUR.TRX_DT,                             --P_SEARCH_TRX_DT
      JUR.CLIENT_CD,                          --P_SEARCH_CLIENT_CD
      JUR.CA_TYPE,                            --P_CA_TYPE
      P_STK_CD,                               --P_STK_CD
      JUR.TRX_DT,                             --P_TRX_DT
      JUR.CLIENT_CD,                          --P_CLIENT_CD
      JUR.QTY,                                --P_QTY
      JUR.PRICE,                              --P_PRICE
      JUR.GROSS_AMT,                          --P_GROSS_AMT
      JUR.FEE_PCN,                            --P_FEE_PCN
      JUR.FEE_AMT,                            --P_FEE_AMT
      JUR.NET_AMT,                            --P_NET_AMT
      NULL,                                   --P_CRE_DT
      NULL,                                   --P_USER_ID
      NULL,                                   --P_UPD_DT
      NULL,                                   --P_UPD_BY
      V_PAYREC_NUM,                           --P_RVPV_NUMBER
      JUR.PAYMENT_DT,            --P_PAYMENT_DT
      JUR.ROUNDING,--P_ROUNDING
      JUR.ROUND_POINT,--P_ROUND_POINT
      'U',                                    --P_UPD_STATUS
      P_IP_ADDRESS,                           --p_ip_address
      NULL,                                   --p_cancel_reason
      V_UPDATE_DATE,                          --p_update_date
      V_UPDATE_SEQ,                           --p_update_seq
      V_RECORD_SEQ,                           --p_record_seq
      V_ERROR_CODE,                           --p_error_code
      V_ERROR_MSG                             --p_error_msg
      );
    EXCEPTION
    WHEN OTHERS THEN
      V_ERROR_CODE := -170;
      V_ERROR_MSG  :=SUBSTR('CALL Sp_T_TENDER_OFFER_SELL_UPD'||SQLERRM,1,200);
      RAISE V_ERR;
    END;
    
    IF V_ERROR_CODE <0 THEN
      V_ERROR_CODE := -180;
      V_ERROR_MSG  :=SUBSTR('Sp_T_TENDER_OFFER_SELL_UPD '||V_ERROR_MSG,1,200);
      RAISE V_ERR;
    END IF;
    
    ------------END UPDATE RVPV NUMBER Sp_T_TENDER_OFFER_SELL_UPD----------------
    
    IF V_RECORD_SEQ=1 THEN
      --CALL Sp_T_ACCOUNT_LEDGER_Upd UNTUK BARIS BANK
      BEGIN
        Sp_T_ACCOUNT_LEDGER_Upd( V_PAYREC_NUM,--P_SEARCH_XN_DOC_NUM,
        555,                                 --P_SEARCH_TAL_ID,
        V_PAYREC_NUM,                         --P_XN_DOC_NUM,
        555,                                 --P_TAL_ID,
        V_DOC_REF_NUM,                        --P_DOC_REF_NUM,
        V_ACCT_TYPE,                          --P_ACCT_TYPE,
        V_SL_ACCT_CD,                         --  P_SL_ACCT_CD,
        V_GL_ACCT_CD,                         -- P_GL_ACCT_CD,
        NULL,                                 --P_CHRG_CD,
        NULL,                                 --P_CHQ_SNO,
        'IDR',                                --P_CURR_CD,
        V_BRANCH_CD,                          --  P_BRCH_CD,
        JUR.TOTAL,                            -- P_CURR_VAL,
        JUR.TOTAL,                            -- P_XN_VAL,
        'TOFFSELL',                            --P_BUDGET_CD,
        'D',                                  --P_DB_CR_FLG,
        'TENDER OFFER SELL '||P_STK_CD||' @'||JUR.PRICE,                       --P_LEDGER_NAR,
        NULL,                                 --P_CASHIER_ID,
        JUR.PAYMENT_DT,                           --P_DOC_DATE,
        JUR.PAYMENT_DT,                           --P_DUE_DATE,
        JUR.PAYMENT_DT,                           --P_NETTING_DATE,
        NULL,                                 --P_NETTING_FLG,
        'RD',                                 --P_RECORD_SOURCE,
        0,                                    --P_SETT_FOR_CURR,
        'N',                                  --P_SETT_STATUS,
        V_PAYREC_NUM,                         -- P_RVPV_NUMBER,
        P_FOLDER_CD,                          --P_FOLDER_CD
        0,                                    --P_SETT_VAL,
        JUR.PAYMENT_DT,                           --P_ARAP_DUE_DATE,
        NULL,                                 --P_RVPV_GSSL,
        NULL,                                 --P_CASH_WITHDRAW_AMT,
        NULL,                                 --P_CASH_WITHDRAW_REASON,
        P_USER_ID, SYSDATE,                   --P_CRE_DT,
        NULL,                                 --P_UPD_BY,
        NULL,                                 --P_UPD_DT,
        'N',                                  --P_REVERSAL_JUR,
        'N',                                  --P_MANUAL,
        'I',                                  --P_UPD_STATUS,
        p_ip_address, NULL,                   --p_cancel_reason,
        V_UPDATE_DATE,                        -- p_update_date,
        V_UPDATE_SEQ,                         -- p_update_seq,
        V_RECORD_SEQ,                         --p_record_seq,
        V_ERROR_CODE,                         -- p_error_code,
        V_ERROR_MSG                           --p_error_msg,
        ) ;
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
      
      V_RECORD_SEQ :=V_RECORD_SEQ+1;
    END IF;--END IF RECORD SEQ 1
    
    --END INSERT BARIS BANK T_ACCOUNT_LEDGER
    IF JUR.CLIENT_CD = V_CLIENT_AB THEN
      V_GL_ACCT_CD  :=V_AB_GL_A;
      V_SL_ACCT_CD  := V_AB_SL_A;
    ELSE
      V_GL_ACCT_CD :=F_GL_ACCT_T3_JAN2016(JUR.CLIENT_CD,'C');
      V_SL_ACCT_CD := JUR.CLIENT_CD;
    END IF;
    
    BEGIN
      SELECT ACCT_TYPE, BRCH_CD
      INTO V_ACCT_TYPE, V_BRANCH_CD
      FROM MST_GL_ACCOUNT
      WHERE TRIM(GL_A) = TRIM(V_GL_ACCT_CD)
      AND SL_A         = V_SL_ACCT_CD
      AND PRT_TYPE    <>'S'
      AND acct_stat    = 'A'
      AND APPROVED_STAT='A';
    EXCEPTION
    WHEN OTHERS THEN
      V_ERROR_CODE := -210;
      V_ERROR_MSG  :=SUBSTR('SELECT ACCT_TYPE '||V_GL_ACCT_CD||' '||V_SL_ACCT_CD||' '||SQLERRM,1,200);
      RAISE V_ERR;
    END;
    
    --CALL Sp_T_ACCOUNT_LEDGER_Upd UNTUK BARIS CLIENT
    BEGIN
      Sp_T_ACCOUNT_LEDGER_Upd( V_PAYREC_NUM,--P_SEARCH_XN_DOC_NUM,
      V_TAL_ID,                             --P_SEARCH_TAL_ID,
      V_PAYREC_NUM,                         --P_XN_DOC_NUM,
      V_TAL_ID,                             --P_TAL_ID,
      V_DOC_REF_NUM,                        --P_DOC_REF_NUM,
      'AP',                          --P_ACCT_TYPE,
      V_SL_ACCT_CD,                         --  P_SL_ACCT_CD,
      V_GL_ACCT_CD,                         -- P_GL_ACCT_CD,
      NULL,                                 --P_CHRG_CD,
      NULL,                                 --P_CHQ_SNO,
      'IDR',                                --P_CURR_CD,
      V_BRANCH_CD,                          --  P_BRCH_CD,
      JUR.NET_AMT,                          -- P_CURR_VAL,
      JUR.NET_AMT,                          -- P_XN_VAL,
      'TOFFSELL',                           --P_BUDGET_CD,
      'C',                                  --P_DB_CR_FLG,
      JUR.LEDGER_NAR,                       --P_LEDGER_NAR,
      NULL,                                 --P_CASHIER_ID,
      JUR.PAYMENT_DT,                           --P_DOC_DATE,
      JUR.PAYMENT_DT,                           --P_DUE_DATE,
      JUR.PAYMENT_DT,                           --P_NETTING_DATE,
      NULL,                                 --P_NETTING_FLG,
      'RD',                                 --P_RECORD_SOURCE,
      0,                                    --P_SETT_FOR_CURR,
      'N',                                  --P_SETT_STATUS,
      V_PAYREC_NUM,                         -- P_RVPV_NUMBER,
      P_FOLDER_CD, 0,                       --P_SETT_VAL,
      JUR.PAYMENT_DT,                           --P_ARAP_DUE_DATE,
      NULL,                                 --P_RVPV_GSSL,
      NULL,                                 --P_CASH_WITHDRAW_AMT,
      NULL,                                 --P_CASH_WITHDRAW_REASON,
      P_USER_ID, SYSDATE,                   --P_CRE_DT,
      NULL,                                 --P_UPD_BY,
      NULL,                                 --P_UPD_DT,
      'N',                                  --P_REVERSAL_JUR,
      'N',                                  --P_MANUAL,
      'I',                                  --P_UPD_STATUS,
      p_ip_address, NULL,                   --p_cancel_reason,
      V_UPDATE_DATE,                        -- p_update_date,
      V_UPDATE_SEQ,                         -- p_update_seq,
      V_RECORD_SEQ,                         --p_record_seq,
      V_ERROR_CODE,                         -- p_error_code,
      V_ERROR_MSG                           --p_error_msg,
      ) ;
    EXCEPTION
    WHEN OTHERS THEN
      V_ERROR_CODE := -220;
      V_ERROR_MSG  :=SUBSTR('Sp_T_ACCOUNT_LEDGER_Upd'||SQLERRM,1,200);
      RAISE V_ERR;
    END;
    
    IF V_ERROR_CODE <0 THEN
      V_ERROR_CODE := -230;
      V_ERROR_MSG  :=SUBSTR('Sp_T_ACCOUNT_LEDGER_Upd '||V_ERROR_MSG,1,200);
      RAISE V_ERR;
    END IF;
    
    --CAL SP_T_PAYRECD UNTUK CLIENT
    BEGIN
      Sp_T_PAYRECD_Upd( V_PAYREC_NUM,-- P_SEARCH_PAYREC_NUM
      V_PAYREC_NUM,                  --P_SEARCH_DOC_REF_NUM
      V_TAL_ID,                      --P_SEARCH_TAL_ID
      V_PAYREC_NUM,                  --P_PAYREC_NUM
      'RD',                          --P_PAYREC_TYPE
      JUR.PAYMENT_DT,                    --P_PAYREC_DATE
      JUR.CLIENT_CD,                 --P_CLIENT_CD
      V_GL_ACCT_CD,                  --P_GL_ACCT_CD
      V_SL_ACCT_CD,                  --P_SL_ACCT_CD
      'C',                           --P_DB_CR_FLG
      JUR.NET_AMT,                   --P_PAYREC_AMT
      V_PAYREC_NUM,                  --P_DOC_REF_NUM
      V_TAL_ID,                      --P_TAL_ID
      JUR.LEDGER_NAR,                -- P_REMARKS
      'VCH',                         --P_RECORD_SOURCE
      JUR.PAYMENT_DT,                    --P_DOC_DATE
      P_FOLDER_CD,                   -- P_REF_FOLDER_CD
      V_PAYREC_NUM,                  -- P_GL_REF_NUM
      0,                             --P_SETT_FOR_CURR
      0,                             --P_SETT_VAL
      V_BRANCH_CD,                   -- P_BRCH_CD
      V_TAL_ID,                      --P_DOC_TAL_ID
      NULL,                          --P_SOURCE_TYPE
      JUR.PAYMENT_DT,                    --P_DUE_DATE
      P_USER_ID, SYSDATE,            --P_CRE_DT
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
      V_ERROR_CODE := -240;
      V_ERROR_MSG  :=SUBSTR('Sp_T_PAYRECD_Upd '||SQLERRM,1,200);
      RAISE V_ERR;
    END;
    
    IF V_ERROR_CODE <0 THEN
      V_ERROR_CODE := -250;
      V_ERROR_MSG  :=SUBSTR('Sp_T_PAYRECD_Upd '||V_ERROR_MSG,1,200);
      RAISE V_ERR;
    END IF;
    V_TAL_ID     :=V_TAL_ID    +1;
    V_RECORD_SEQ :=V_RECORD_SEQ+1;
  END LOOP;
  
  IF V_CNT_STK    =0 THEN
    V_ERROR_CODE := -260;
    V_ERROR_MSG  :='Tidak ada voucher yang dibuat';
    RAISE V_ERR;
  END IF;
  
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
END SP_GEN_VCH_TOFFSELL;