CREATE OR REPLACE
PROCEDURE SP_GEN_VOUCHER_DIV(
    P_DISTRIB_DT DATE,
    P_BRANCH_CD  VARCHAR2,
    P_FOLDER_CD  VARCHAR2,
    P_USER_ID T_MANY_HEADER.USER_ID%TYPE,
    P_IP_ADDRESS T_MANY_HEADER.IP_ADDRESS%TYPE,
    P_ERROR_CODE OUT NUMBER,
    P_ERROR_MSG OUT VARCHAR2)
IS
  CURSOR CSR_DIV
  IS
    SELECT A.*
    FROM
      (SELECT DECODE(B.DFLG1,'Y',C.PARAM_CD3
        ||A.STK_CD,P_BRANCH_CD
        ||A.STK_CD
        ||TO_CHAR(A.DISTRIB_DT,'DDMMYY')) AS STK_DIV,
        A.*
      FROM T_CORP_ACT A,
        (SELECT DFLG1
        FROM MST_SYS_PARAM
        WHERE PARAM_ID='VOUCHER_DIVIDEN'
        AND PARAM_CD1 ='BRANCH'
        AND PARAM_CD2 ='ALL'
        ) B,
      (SELECT *
      FROM MST_SYS_PARAM
      WHERE PARAM_ID='VOUCHER_DIVIDEN'
      AND PARAM_CD1 ='GL_ACCT'
      AND PARAM_CD2 ='BANK'
      AND PARAM_CD3 LIKE '%'
        ||P_BRANCH_CD
      ) C
    WHERE A.CA_TYPE    ='CASHDIV'
    AND A.DISTRIB_DT   =P_DISTRIB_DT
    AND A.APPROVED_STAT='A'
      ) A,
      T_PAYRECH C
    WHERE A.STK_DIV   = C.CLIENT_CD(+)
    AND A.DISTRIB_DT  =C.PAYREC_DATE(+)
    AND C.ACCT_TYPE(+)='DIV'
    AND C.CLIENT_CD  IS NULL
    ORDER BY A.STK_CD ;
    CURSOR CSR_CLIENT(A_STK_CD T_CORP_ACT.STK_CD%TYPE, A_CLIENT_AB VARCHAR2,A_AB_GL_A VARCHAR2,A_AB_SL_A VARCHAR2, A_CHECK_BRANCH VARCHAR2)
    IS
      SELECT DECODE(A.CLIENT_CD,A_CLIENT_AB,A_AB_GL_A,trim(F_GL_ACCT_T3_JAN2016(a.CLIENT_CD,'C'))) GL_ACCT_CD,
        DECODE(a.CLIENT_CD,A_CLIENT_AB,A_AB_SL_A,a.client_cd) SL_ACCT_CD,
        DIV_AMT PAYREC_AMT,
        'C' DB_CR_FLG,
        'DIV '
        || stk_cd
        ||' '
        ||trim(TO_CHAR(qty,'9,999,999,999,999,999'))
        ||' @'
        ||RATE REMARKS,
        selisih_qty,
        SUM(div_amt) over( PARTITION BY stk_cd) TOTAL
      FROM T_CASH_DIVIDEN a,
        mst_client b
      WHERE stk_cd   =A_STK_CD
      AND CA_TYPE    ='CASHDIV'
      AND distrib_dt = P_DISTRIB_DT
      AND a.client_cd=b.client_cd
      AND trim(b.branch_code) LIKE DECODE(A_CHECK_BRANCH,'Y','%',P_BRANCH_CD)
      ORDER BY a.client_cd;
    --22JUNI 2016 UNTUK UPDATE RVPV NUMBER=DOC NUM VOUCHER RECEIPT
    CURSOR CSR_CASH_DIVIDEN(A_CUM_DATE T_CASH_DIVIDEN.CUM_DATE%TYPE,A_DISTRIB_DT T_CASH_DIVIDEN.DISTRIB_DT%TYPE,A_STK_CD T_CASH_DIVIDEN.STK_CD%TYPE)
    IS
      SELECT *
      FROM T_CASH_DIVIDEN
      WHERE CUM_DATE = A_CUM_DATE
      AND DISTRIB_DT = A_DISTRIB_DT
      AND STK_CD     = A_STK_CD
      AND CA_TYPE    ='CASHDIV'
      ORDER BY CLIENT_CD;
    V_AB_GL_A T_PAYRECH.GL_ACCT_CD%TYPE;
    V_AB_SL_A T_PAYRECH.SL_ACCT_CD%TYPE;
    V_CHECK_BRANCH MST_SYS_PARAM.DFLG1%TYPE;
    V_ERROR_CODE NUMBER;
    V_ERROR_MSG  VARCHAR2(200);
    V_ERR        EXCEPTION;
    V_MENU_NAME T_MANY_HEADER.MENU_NAME%TYPE:='GENERATE VOUCHER DIVIDEN ALL';
    V_UPDATE_DATE T_MANY_HEADER.UPDATE_DATE%TYPE;
    V_UPDATE_SEQ T_MANY_HEADER.UPDATE_SEQ%TYPE;
    V_CLIENT_AB T_ACCOUNT_LEDGER.SL_ACCT_CD%TYPE;
    I NUMBER;
    J NUMBER;
    V_PAYREC_NUM T_PAYRECH.PAYREC_NUM%TYPE;
    V_GL_ACCT_CD T_PAYRECH.GL_ACCT_CD%TYPE;
    V_SL_ACCT_CD T_PAYRECH.SL_ACCT_CD%TYPE;
    V_BRANCH MST_GL_ACCOUNT.BRCH_CD%TYPE;
    V_CLIENT_CD T_PAYRECH.CLIENT_CD%TYPE;
    --V_TAL_ID NUMBER;
    V_DOC_REF_NUM T_ACCOUNT_LEDGER.DOC_REF_NUM%TYPE;
    V_REF_FLG MST_SYS_PARAM.DFLG1%TYPE;
    V_ACCT_TYPE T_ACCOUNT_LEDGER.ACCT_TYPE%TYPE;
    V_BRANCH_CD MST_GL_ACCOUNT.BRCH_CD%TYPE;
    --V_DB_CR_FLG T_ACCOUNT_LEDGER.DB_CR_FLG%TYPE;
    --V_SETT_STATUS T_ACCOUNT_LEDGER.SETT_STATUS%TYPE;
    V_RECORD_SEQ NUMBER(5);
    V_FOLDER_FLG MST_SYS_PARAM.DFLG1%TYPE;
    V_FLD_MON T_FOLDER.FLD_MON%TYPE;
    V_RTN NUMBER(1);
    V_DOC_NUM T_FOLDER.DOC_NUM%TYPE;
    V_DOC_DATE DATE;
    V_USER_ID T_FOLDER.USER_ID%TYPE;
    v_folder_cd T_FOLDER.folder_cd%type;
    V_FOLDER_SEQ   NUMBER(3);
    V_CNT          NUMBER;
    V_CNT_STK      NUMBER :=0;
    V_FILE_POSTFIX NUMBER;
    V_FILE_PREFIX  NUMBER;
    V_SEQ_CASH     NUMBER;
  BEGIN
    BEGIN
      SELECT DSTR1,
        DSTR2
      INTO V_AB_GL_A,
        V_AB_SL_A
      FROM MST_SYS_PARAM
      WHERE param_id='VOUCHER_DIVIDEN'
      AND PARAM_CD1 ='GL_ACCT'
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
      WHERE param_id='VOUCHER_DIVIDEN'
      AND PARAM_CD1 ='BRANCH'
      AND param_cd2 ='ALL';
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
      SELECT DSTR1,
        DSTR2,
        PARAM_CD3
      INTO V_GL_ACCT_CD,
        V_SL_ACCT_CD,
        V_BRANCH
      FROM MST_SYS_PARAM
      WHERE param_id='VOUCHER_DIVIDEN'
      AND PARAM_CD1 ='GL_ACCT'
      AND PARAM_CD2 ='BANK'
      AND PARAM_CD3 LIKE '%'
        ||P_BRANCH_CD;
    EXCEPTION
    WHEN OTHERS THEN
      V_ERROR_CODE :=-40;
      V_ERROR_MSG  :=SUBSTR('SELECT CLIENT_CD AB FROM MST_COMPANY'||SQLERRM,1,200);
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
      V_ERROR_CODE :=-30;
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
      V_ERROR_CODE :=-50;
      V_ERROR_MSG  :=SUBSTR('SELECT CLIENT_CD AB FROM MST_COMPANY'||SQLERRM,1,200);
      RAISE V_ERR;
    END;
    BEGIN
      SELECT DNUM1
      INTO V_FILE_POSTFIX
      FROM MST_SYS_PARAM
      WHERE PARAM_ID='VOUCHER_DIVIDEN'
      AND PARAM_CD1 ='FILE_NO';
    EXCEPTION
    WHEN OTHERS THEN
      V_ERROR_CODE :=-50;
      V_ERROR_MSG  :=SUBSTR('SELECT CLIENT_CD AB FROM MST_COMPANY'||SQLERRM,1,200);
      RAISE V_ERR;
    END;
    --ambil angka folder code
    IF V_FOLDER_FLG  ='Y' THEN
      V_FILE_PREFIX := ABS(LENGTH(P_FOLDER_CD)          -V_FILE_POSTFIX);
      V_FOLDER_SEQ  := TO_NUMBER(NVL(SUBSTR(P_FOLDER_CD,-V_FILE_POSTFIX),0));
    END IF;
    I:=1;
    FOR REC IN CSR_DIV
    LOOP
      --CEK MASIH ADA BELUM DIAPPROVE
      BEGIN
        SELECT COUNT(*)
        INTO V_CNT
        FROM T_MANY_HEADER A,
          T_MANY_DETAIL B
        WHERE A.UPDATE_DATE  =B.UPDATE_DATE
        AND A.UPDATE_SEQ     =B.UPDATE_SEQ
        AND A.APPROVED_STATUS='E'
        AND MENU_NAME        ='GENERATE VOUCHER DIVIDEN ALL'
        AND B.TABLE_NAME     ='T_PAYRECH'
        AND B.FIELD_NAME     ='CLIENT_CD'
        AND B.FIELD_VALUE    =REC.STK_DIV;
      EXCEPTION
      WHEN OTHERS THEN
        V_ERROR_CODE := -55;
        V_ERROR_MSG  := SUBSTR('SP_T_MANY_HEADER_INSERT '|| SQLERRM(SQLCODE),1,200);
        RAISE V_ERR;
      END;
      IF V_CNT        >0 THEN
        V_ERROR_CODE := -57;
        V_ERROR_MSG  := 'Masih ada yang belum diapprove';
        RAISE V_ERR;
      END IF;
      --EXECUTE SP HEADER
      BEGIN
        Sp_T_Many_Header_Insert(V_MENU_NAME, 'I', P_USER_ID, P_IP_ADDRESS, NULL, V_UPDATE_DATE, V_UPDATE_SEQ, V_ERROR_CODE, V_ERROR_MSG);
      EXCEPTION
      WHEN OTHERS THEN
        V_ERROR_CODE := -60;
        V_ERROR_MSG  := SUBSTR('SP_T_MANY_HEADER_INSERT '|| SQLERRM(SQLCODE),1,200);
        RAISE V_ERR;
      END;
      --SETT FOLDER CD
      IF V_FOLDER_FLG='Y' THEN
        V_FOLDER_CD := TRIM(SUBSTR(P_FOLDER_CD,1,V_FILE_PREFIX)||TO_CHAR(V_FOLDER_SEQ,'fm'||RPAD('0', V_FILE_POSTFIX,'0')));
      END IF;
      IF V_CHECK_BRANCH='Y' THEN
        V_BRANCH      := V_BRANCH;
        V_CLIENT_CD   := TRIM(V_BRANCH)||REC.STK_CD;
      ELSE
        V_BRANCH    := P_BRANCH_CD;
        V_CLIENT_CD := TRIM(V_BRANCH)||REC.STK_CD||TO_CHAR(REC.DISTRIB_DT,'DDMMYY');
      END IF;
      --BUAT MASING MASING VOUCHER
      J           :=1;
      V_RECORD_SEQ:=1;
      FOR JUR IN CSR_CLIENT(REC.STK_CD,V_CLIENT_AB,V_AB_GL_A,V_AB_SL_A,V_CHECK_BRANCH)
      LOOP
        IF J               =1 THEN
          V_CNT_STK       :=1;
          IF V_REF_FLG     ='Y' THEN
            V_DOC_REF_NUM := V_PAYREC_NUM;
          END IF;
          --CALL SP_T_PAYRECH_UPD
          BEGIN
            SP_T_PAYRECH_UPD ( V_PAYREC_NUM,   --P_SEARCH_PAYRECH_NUM
            V_PAYREC_NUM,                      --P_PAYRECH_NUM
            'RD',                              --PAYRECH_TYPE
            REC.DISTRIB_DT,                    --P_PAYREC_DATE,
            'DIV',                             --P_ACCT_TYPE,
            V_SL_ACCT_CD,                      -- P_SL_ACCT_CD,
            'IDR',                             --P_CURR_CD,
            JUR.TOTAL,                         --P_CURR_AMT,
            NULL,                              --P_PAYREC_FRTO,
            'DIV '||REC.STK_CD||' @'||REC.RATE,--P_REMARKS,
            V_GL_ACCT_CD,                      -- P_GL_ACCT_CD,
            V_CLIENT_CD,                       --P_CLIENT_CD,
            NULL,                              --P_CHECK_NUM,
            v_folder_cd, NULL,                 --P_NUM_CHEQ,
            NULL,                              --P_CLIENT_BANK_ACCT,
            NULL,                              --P_CLIENT_BANK_NAME,
            'N',                               --P_REVERSAL_JUR,
            P_USER_ID, SYSDATE,                --P_CRE_DT,
            NULL,                              --P_UPD_BY,
            NULL,                              --P_UPD_DT,
            'I',                               --P_UPD_STATUS,
            p_ip_address, NULL,                --p_cancel_reason,
            V_UPDATE_DATE,                     -- p_update_date,
            V_UPDATE_SEQ,                      -- p_update_seq,
            J,                                 --p_record_seq,
            V_ERROR_CODE,                      --p_error_code,
            V_ERROR_MSG                        --p_error_msg
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
          ------------UPDATE RVPV NUMBER T_CASH_DIVIDEN----------------

          V_SEQ_CASH:=1;
          FOR CLI IN CSR_CASH_DIVIDEN(REC.CUM_DT,REC.DISTRIB_DT,REC.STK_CD)
          LOOP
            BEGIN
              Sp_T_CASH_DIVIDEN_Upd( CLI.CA_TYPE,-- P_SEARCH_CA_TYPE
              CLI.STK_CD,                        -- P_SEARCH_STK_CD  T_CASH_DIVIDEN.STK_CD%TYPE,
              CLI.DISTRIB_DT,                    -- P_SEARCH_DISTRIB_DT  T_CASH_DIVIDEN.DISTRIB_DT%TYPE,
              CLI.CLIENT_CD,                     -- P_SEARCH_CLIENT_CD  T_CASH_DIVIDEN.CLIENT_CD%TYPE,
              CLI.CA_TYPE,                       -- P_CA_TYPE  T_CASH_DIVIDEN.CA_TYPE%TYPE,
              CLI.STK_CD,                        -- P_STK_CD  T_CASH_DIVIDEN.STK_CD%TYPE,
              CLI.DISTRIB_DT,                    -- P_DISTRIB_DT  T_CASH_DIVIDEN.DISTRIB_DT%TYPE,
              CLI.CLIENT_CD,                     -- P_CLIENT_CD  T_CASH_DIVIDEN.CLIENT_CD%TYPE,
              CLI.QTY,                           -- P_QTY  T_CASH_DIVIDEN.QTY%TYPE,
              CLI.RATE,                          -- P_RATE  T_CASH_DIVIDEN.RATE%TYPE,
              CLI.GROSS_AMT,                     -- P_GROSS_AMT  T_CASH_DIVIDEN.GROSS_AMT%TYPE,
              CLI.TAX_PCN,                       -- P_TAX_PCN  T_CASH_DIVIDEN.TAX_PCN%TYPE,
              CLI.TAX_AMT,                       -- P_TAX_AMT  T_CASH_DIVIDEN.TAX_AMT%TYPE,
              CLI.DIV_AMT,                       -- P_DIV_AMT  T_CASH_DIVIDEN.DIV_AMT%TYPE,
              CLI.CRE_DT,                        -- P_CRE_DT  T_CASH_DIVIDEN.CRE_DT%TYPE,
              CLI.USER_ID,                       -- P_USER_ID  T_CASH_DIVIDEN.USER_ID%TYPE,
              SYSDATE,                           -- P_UPD_DT  T_CASH_DIVIDEN.UPD_DT%TYPE,
              P_USER_ID,                         -- P_UPD_BY  T_CASH_DIVIDEN.UPD_BY%TYPE,
              V_PAYREC_NUM,                      --P_RVPV_NUMBER  T_CASH_DIVIDEN.RVPV_NUMBER%TYPE,
              CLI.CUM_DATE,                      -- P_CUM_DATE  T_CASH_DIVIDEN.CUM_DATE%TYPE,
              CLI.CUM_QTY,                       -- P_CUM_QTY  T_CASH_DIVIDEN.CUM_QTY%TYPE,
              CLI.ONH,                           -- P_ONH  T_CASH_DIVIDEN.ONH%TYPE,
              CLI.SELISIH_QTY,                   -- P_SELISIH_QTY  T_CASH_DIVIDEN.SELISIH_QTY%TYPE,
              CLI.CUMDT_DIV_AMT,                 -- P_CUMDT_DIV_AMT  T_CASH_DIVIDEN.CUMDT_DIV_AMT%TYPE,
              CLI.RVPV_KOREKSI,                  -- P_RVPV_KOREKSI  T_CASH_DIVIDEN.RVPV_KOREKSI%TYPE,
              'U',                               -- P_UPD_STATUS     T_MANY_DETAIL.UPD_STATUS%TYPE,
              p_ip_address,                      --    T_MANY_HEADER.IP_ADDRESS%TYPE,
              NULL,                              --p_cancel_reason     T_MANY_HEADER.CANCEL_REASON%TYPE,
              V_UPDATE_DATE,                     -- p_update_date     T_MANY_HEADER.UPDATE_DATE%TYPE,
              V_UPDATE_SEQ,                      -- p_update_seq     T_MANY_HEADER.UPDATE_SEQ%TYPE,
              V_SEQ_CASH,                        -- p_record_seq     T_MANY_DETAIL.RECORD_SEQ%TYPE,
              V_ERROR_CODE,                      -- p_error_code     OUT   NUMBER,
              V_ERROR_MSG                        -- p_error_msg      OUT   VARCHAR2
              );
            EXCEPTION
            WHEN OTHERS THEN
              V_ERROR_CODE := -85;
              V_ERROR_MSG  :=SUBSTR('Sp_T_CASH_DIVIDEN_Upd'||SQLERRM,1,200);
              RAISE V_ERR;
            END;
            IF V_ERROR_CODE <0 THEN
              V_ERROR_CODE := -87;
              V_ERROR_MSG  :=SUBSTR('Sp_T_CASH_DIVIDEN_Upd '||V_ERROR_MSG,1,200);
              RAISE V_ERR;
            END IF;
            V_SEQ_CASH := V_SEQ_CASH+1;

          END LOOP;


------------END UPDATE RVPV NUMBER T_CASH_DIVIDEN----------------
          IF V_FOLDER_FLG='Y' THEN
            V_FLD_MON   :=TO_CHAR(REC.DISTRIB_DT,'MMYY');
            BEGIN
              SP_CHECK_FOLDER_CD( v_folder_cd, REC.DISTRIB_DT,--p_date
              V_RTN,                                          --p_rtn
              V_DOC_NUM,                                      -- p_doc_num
              V_USER_ID,                                      -- p_user_id
              V_DOC_DATE                                      --p_doc_date
              );
            EXCEPTION
            WHEN OTHERS THEN
              V_ERROR_CODE := -90;
              V_ERROR_MSG  :=SUBSTR('SP_T_PAYRECH_UPD'||SQLERRM,1,200);
              RAISE V_ERR;
            END;
            IF V_ERROR_CODE <0 THEN
              V_ERROR_CODE := -100;
              V_ERROR_MSG  :=SUBSTR('SP_T_PAYRECH_UPD '||V_ERROR_MSG,1,200);
              RAISE V_ERR;
            END IF;
            IF V_RTN        =1 THEN
              V_ERROR_CODE :=-110;
              V_ERROR_MSG  :='File Code '||v_folder_cd||' is already used by '||P_USER_ID||' '|| V_DOC_NUM||' '||V_DOC_DATE;
              RAISE V_ERR;
            END IF;
            BEGIN
              SP_T_FOLDER_UPD ( V_PAYREC_NUM,--P_SEARCH_DOC_NUM
              V_FLD_MON,                     --P_FLD_MON
              v_folder_cd, REC.DISTRIB_DT,   --P_DOC_DATE
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
              V_ERROR_CODE := -120;
              V_ERROR_MSG  :=SUBSTR('SP_T_PAYRECH_UPD'||SQLERRM,1,200);
              RAISE V_ERR;
            END;
            IF V_ERROR_CODE <0 THEN
              V_ERROR_CODE := -130;
              V_ERROR_MSG  :=SUBSTR('SP_T_PAYRECH_UPD '||V_ERROR_MSG,1,200);
              RAISE V_ERR;
            END IF;
          END IF;--END V_FOLDER_FLG
          --CALL Sp_T_ACCOUNT_LEDGER_Upd UNTUK BARIS BANK
          BEGIN
            Sp_T_ACCOUNT_LEDGER_Upd( V_PAYREC_NUM,--P_SEARCH_XN_DOC_NUM,
            555,                                  --P_SEARCH_TAL_ID,
            V_PAYREC_NUM,                         --P_XN_DOC_NUM,
            555,                                  --P_TAL_ID,
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
            'DIVIDEN',                            --P_BUDGET_CD,
            'D',                                  --P_DB_CR_FLG,
            JUR.REMARKS,                          --P_LEDGER_NAR,
            NULL,                                 --P_CASHIER_ID,
            REC.DISTRIB_DT,                       --P_DOC_DATE,
            REC.DISTRIB_DT,                       --P_DUE_DATE,
            REC.DISTRIB_DT,                       --P_NETTING_DATE,
            NULL,                                 --P_NETTING_FLG,
            'RD',                                 --P_RECORD_SOURCE,
            0,                                    --P_SETT_FOR_CURR,
            'N',                                  --P_SETT_STATUS,
            V_PAYREC_NUM,                         -- P_RVPV_NUMBER,
            v_folder_cd,                          --P_FOLDER_CD
            0,                                    --P_SETT_VAL,
            REC.DISTRIB_DT,                       --P_ARAP_DUE_DATE,
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
            V_ERROR_CODE := -140;
            V_ERROR_MSG  :=SUBSTR('Sp_T_ACCOUNT_LEDGER_Upd'||SQLERRM,1,200);
            RAISE V_ERR;
          END;
          IF V_ERROR_CODE <0 THEN
            V_ERROR_CODE := -150;
            V_ERROR_MSG  :=SUBSTR('Sp_T_ACCOUNT_LEDGER_Upd '||V_ERROR_MSG,1,200);
            RAISE V_ERR;
          END IF;
          J            :=J            +1;
          V_RECORD_SEQ := V_RECORD_SEQ+1;
        END IF;--END IF I=1
        BEGIN
          SELECT ACCT_TYPE,
            BRCH_CD
          INTO V_ACCT_TYPE,
            V_BRANCH_CD
          FROM MST_GL_ACCOUNT
          WHERE TRIM(GL_A) = JUR.GL_ACCT_CD
          AND SL_A         = JUR.SL_ACCT_CD
          AND PRT_TYPE    <>'S'
          AND acct_stat    = 'A'
          AND APPROVED_STAT='A';
        EXCEPTION
        WHEN OTHERS THEN
          V_ERROR_CODE := -160;
          V_ERROR_MSG  :=SUBSTR('SELECT ACCT_TYPE'||SQLERRM,1,200);
          RAISE V_ERR;
        END;
        --CALL Sp_T_ACCOUNT_LEDGER_Upd UNTUK BARIS CLIENT
        BEGIN
          Sp_T_ACCOUNT_LEDGER_Upd( V_PAYREC_NUM,--P_SEARCH_XN_DOC_NUM,
          J,                                    --P_SEARCH_TAL_ID,
          V_PAYREC_NUM,                         --P_XN_DOC_NUM,
          J,                                    --P_TAL_ID,
          V_DOC_REF_NUM,                        --P_DOC_REF_NUM,
          V_ACCT_TYPE,                          --P_ACCT_TYPE,
          JUR.SL_ACCT_CD,                       --  P_SL_ACCT_CD,
          JUR.GL_ACCT_CD,                       -- P_GL_ACCT_CD,
          NULL,                                 --P_CHRG_CD,
          NULL,                                 --P_CHQ_SNO,
          'IDR',                                --P_CURR_CD,
          V_BRANCH_CD,                          --  P_BRCH_CD,
          JUR.PAYREC_AMT,                       -- P_CURR_VAL,
          JUR.PAYREC_AMT,                       -- P_XN_VAL,
          'DIVIDEN',                            --P_BUDGET_CD,
          'C',                                  --P_DB_CR_FLG,
          JUR.REMARKS,                          --P_LEDGER_NAR,
          NULL,                                 --P_CASHIER_ID,
          REC.DISTRIB_DT,                       --P_DOC_DATE,
          REC.DISTRIB_DT,                       --P_DUE_DATE,
          REC.DISTRIB_DT,                       --P_NETTING_DATE,
          NULL,                                 --P_NETTING_FLG,
          'RD',                                 --P_RECORD_SOURCE,
          0,                                    --P_SETT_FOR_CURR,
          'N',                                  --P_SETT_STATUS,
          V_PAYREC_NUM,                         -- P_RVPV_NUMBER,
          v_folder_cd, 0,                       --P_SETT_VAL,
          REC.DISTRIB_DT,                       --P_ARAP_DUE_DATE,
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
          V_ERROR_CODE := -170;
          V_ERROR_MSG  :=SUBSTR('Sp_T_ACCOUNT_LEDGER_Upd'||SQLERRM,1,200);
          RAISE V_ERR;
        END;
        IF V_ERROR_CODE <0 THEN
          V_ERROR_CODE := -180;
          V_ERROR_MSG  :=SUBSTR('Sp_T_ACCOUNT_LEDGER_Upd '||V_ERROR_MSG,1,200);
          RAISE V_ERR;
        END IF;
        --CAL SP_T_PAYRECD UNTUK CLIENT
        BEGIN
          Sp_T_PAYRECD_Upd( V_PAYREC_NUM,-- P_SEARCH_PAYREC_NUM
          V_PAYREC_NUM,                  --P_SEARCH_DOC_REF_NUM
          J,                             --P_SEARCH_TAL_ID
          V_PAYREC_NUM,                  --P_PAYREC_NUM
          'RD',                          --P_PAYREC_TYPE
          REC.DISTRIB_DT,                --P_PAYREC_DATE
          JUR.SL_ACCT_CD,                --P_CLIENT_CD
          JUR.GL_ACCT_CD,                --P_GL_ACCT_CD
          JUR.SL_ACCT_CD,                --P_SL_ACCT_CD
          'C',                           --P_DB_CR_FLG
          JUR.PAYREC_AMT,                --P_PAYREC_AMT
          V_PAYREC_NUM,                  --P_DOC_REF_NUM
          J,                             --P_TAL_ID
          JUR.REMARKS,                   -- P_REMARKS
          'VCH',                         --P_RECORD_SOURCE
          REC.DISTRIB_DT,                --P_DOC_DATE
          v_folder_cd,                   -- P_REF_FOLDER_CD
          V_PAYREC_NUM,                  -- P_GL_REF_NUM
          0,                             --P_SETT_FOR_CURR
          0,                             --P_SETT_VAL
          V_BRANCH_CD,                   -- P_BRCH_CD
          J,                             --P_DOC_TAL_ID
          NULL,                          --P_SOURCE_TYPE
          REC.DISTRIB_DT,                --P_DUE_DATE
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
          V_ERROR_CODE := -190;
          V_ERROR_MSG  :=SUBSTR('Sp_T_PAYRECD_Upd '||SQLERRM,1,200);
          RAISE V_ERR;
        END;
        IF V_ERROR_CODE <0 THEN
          V_ERROR_CODE := -200;
          V_ERROR_MSG  :=SUBSTR('Sp_T_PAYRECD_Upd '||V_ERROR_MSG,1,200);
          RAISE V_ERR;
        END IF;
        J            := J          +1;
        V_RECORD_SEQ :=V_RECORD_SEQ+1;
      END LOOP;
      I            :=I           +1;
      V_FOLDER_SEQ :=V_FOLDER_SEQ+1;
    END LOOP;
    IF V_CNT_STK    =0 THEN
      V_ERROR_CODE := -250;
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
  END SP_GEN_VOUCHER_DIV;