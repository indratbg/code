create or replace PROCEDURE SP_FUND_AUTO_BCA_FAIL(
    P_TANGGALEFEKTIF DATE,
    P_FROM_DATE      DATE,
    P_TO_DATE        DATE,
    P_RDN T_CLIENT_ACCT_STMT_FAIL.ACCT_NUM%TYPE,
    P_CLIENT_CD MST_CLIENT_FLACCT.CLIENT_CD%TYPE,
    P_EXTERNAL_REF T_CLIENT_ACCT_STMT_FAIL.EXTERNAL_REF%TYPE,
    p_user_id T_MANY_HEADER.USER_ID%TYPE,
    p_ip_address T_MANY_HEADER.IP_ADDRESS%TYPE,
    P_ERROR_CODE OUT NUMBER,
    P_ERROR_MSG OUT VARCHAR2)
IS
  V_ERROR_CODE NUMBER(5);
  V_ERROR_MSG  VARCHAR2(200);
  V_ERR        EXCEPTION;
  CURSOR CSR_FUND
  IS
    SELECT M.CLIENT_CD, TRIM(M.BRANCH_CODE) BRANCH_CODE, T.ACCT_NUM , M.CLIENT_NAME, TRUNC(TRX_DATE) AS TANGGALEFEKTIF, 
    TRX_DATE AS TANGGALTIMESTAMP, T.TRX_CD , T.TRX_TYPE , T.TRX_AMT , DECODE(T.TRX_TYPE,'NINT','Bunga',R.DESCRIP) ||' ' ||M.CLIENT_CD AS REMARKS,
    R.FUND_BANK_CD , t.ACCT_DEBIT, T.ACCT_CREDIT, T.EXTERNAL_REF
    FROM
      (
        SELECT A.external_ref,acct_num,trx_date,trx_type, trx_cd,acct_debit,acct_credit,trx_amt,close_bal,open_bal
        FROM t_client_acct_stmt_fail A, (
            SELECT REPLACE(REPLACE(bank_acct_cd,'-',''),'.','') pe_bank_acct
            FROM MST_BANK_ACCT
            WHERE bank_acct_cd <> 'X'
          )
        P
      WHERE A.ACCT_NUM    =P.PE_BANK_ACCT(+)
      AND P.PE_BANK_ACCT IS NULL
    --  AND A.trx_date BETWEEN GET_DOC_DATE(1,P_FROM_DATE) AND GET_DUE_DATE(1,P_TO_DATE)
      AND A.ACCT_NUM     = P_RDN
      AND A.EXTERNAL_REF = P_EXTERNAL_REF
     -- AND TRUNC(TRX_DATE)    =TRUNC(SYSDATE)
      )
      T , mst_client M, (
        SELECT MAX(CLIENT_CD)CLIENT_CD,BANK_ACCT_NUM
        FROM MST_CLIENT_FLACCT
        WHERE ACCT_STAT    in ('A','B')
        AND BANK_CD       ='BCA02'
        AND BANK_ACCT_NUM =P_RDN
        GROUP BY BANK_ACCT_NUM
      )
      C, MST_RDI_TRX_TYPE R, (
        SELECT NVL(bank_ref_num,'X') bank_ref_num, fund_bank_acct AS BANK_ACCT_NUM, doc_Date, sl_acct_cd, BANK_MVMT_DATE
        FROM T_FUND_MOVEMENT
        WHERE doc_date BETWEEN GET_DOC_DATE(1,P_FROM_DATE) AND GET_DUE_DATE(1,P_TO_DATE)
        AND source        = 'H2H'
        AND approved_sts <> 'C'
      )
      F
    WHERE M.CLIENT_CD     =C.CLIENT_CD
    AND M.CIFS           IS NOT NULL
    AND M.SUSP_STAT       ='N'
    AND t.acct_num        = C.bank_acct_num
    AND T.TRX_TYPE        = R.RDI_TRX_TYPE
    AND T.TRX_CD = R.DB_CR_FLG
    AND T.ACCT_NUM        = F.BANK_ACCT_NUM(+)
    AND T.EXTERNAL_REF    = F.BANK_REF_NUM(+)
    AND T.TRX_DATE        = F.BANK_MVMT_DATE(+)
    AND T.TRX_TYPE        = F.SL_ACCT_CD(+)
    AND F.bank_ref_num   IS NULL
    AND F.BANK_ACCT_NUM  IS NULL
    AND F.BANK_MVMT_DATE IS NULL
    AND F.SL_ACCT_CD     IS NULL;
    V_FROM_BANK T_FUND_MOVEMENT.FROM_BANK%TYPE;
    V_TO_BANK T_FUND_MOVEMENT.TO_BANK%TYPE;
    V_FROM_CLIENT T_FUND_MOVEMENT.FROM_CLIENT%TYPE;
    V_TO_CLIENT T_FUND_MOVEMENT.TO_CLIENT%TYPE;
    V_FROM_ACCT T_FUND_MOVEMENT.FROM_ACCT%TYPE;
    V_TO_ACCT T_FUND_MOVEMENT.TO_ACCT%TYPE;
    V_FUND_BANK_CD T_FUND_MOVEMENT.FUND_BANK_CD%TYPE;
    V_FUND_BANK_ACCT T_FUND_MOVEMENT.FUND_BANK_ACCT%TYPE;
    V_MENU_NAME T_MANY_HEADER.MENU_NAME%TYPE :='FUND AUTO JOURNAL BCA';
    V_UPDATE_SEQ T_MANY_HEADER.UPDATE_SEQ%TYPE;
    V_UPDATE_DATE T_MANY_HEADER.UPDATE_DATE%TYPE;
    V_DOC_NUM T_FUND_MOVEMENT.DOC_NUM%TYPE;
    V_TRX_TYPE T_FUND_MOVEMENT.TRX_TYPE%TYPE;
    V_BANK_CD T_FUND_MOVEMENT.FUND_BANK_CD%TYPE;
    V_CNT_INBOX NUMBER;
  BEGIN
    FOR REC IN CSR_FUND
    LOOP
   
        ---CHECK INBOX
        BEGIN
            select COUNT(1) INTO V_CNT_INBOX from
            t_many_header a, t_many_detail b
            where  B.update_date=A.update_date
            AND B.TABLE_NAME='T_FUND_MOVEMENT'
            and B.update_seq=A.update_seq 
            and b.field_name='BANK_REF_NUM'
            AND B.FIELD_VALUE= P_EXTERNAL_REF
            AND A.APPROVED_STATUS='E'
            AND B.UPDATE_DATE>TRUNC(SYSDATE)-10;
        EXCEPTION
        WHEN OTHERS THEN
          V_ERROR_CODE :=-5;
          V_ERROR_MSG  := SUBSTR('CHECK INBOX FUND MOVEMENT '||sqlerrm,1,200);
          RAISE V_ERR;
        END;
        
        IF V_CNT_INBOX  >0 THEN
          V_ERROR_CODE :=-10;
          V_ERROR_MSG  := 'Client '||p_client_cd ||' masih ada yang belum diapprove';
          RAISE V_ERR;
        END IF;--JIKA TIDAK ADA DI INBOX
        
        BEGIN
          SP_T_MANY_HEADER_INSERT ( V_MENU_NAME, 'I', p_user_id, p_ip_address, NULL, V_UPDATE_DATE, V_UPDATE_SEQ , V_ERROR_CODE , V_ERROR_MSG );
        EXCEPTION
        WHEN OTHERS THEN
          V_ERROR_CODE :=-10;
          V_ERROR_MSG  := SUBSTR('CALL SP_T_MANY_HEADER_INSERT '||sqlerrm,1,200);
          RAISE V_ERR;
        END;
        
        --TRX TYPE
        IF REC.TRX_CD ='C' THEN
          V_TRX_TYPE :='R';
        ELSE
          V_TRX_TYPE :='W';
        END IF;
        
        V_FUND_BANK_CD     := REC.FUND_BANK_CD;
        V_FUND_BANK_ACCT   :=REC.ACCT_NUM;
        V_BANK_CD          :='BCA';
        
        IF REC.TRX_TYPE     ='NTRF' AND REC.TRX_CD='C' THEN
          IF REC.ACCT_DEBIT ='0000000000' THEN
            V_FROM_BANK    := 'XXX';
          ELSE
            V_FROM_BANK := 'BCA';
          END IF;
          
          V_TO_BANK     := V_BANK_CD ;
          V_FROM_CLIENT :='LUAR';
          V_TO_CLIENT   :='FUND';
          V_FROM_ACCT   := REC.ACCT_DEBIT;
          V_TO_ACCT     := REC.ACCT_CREDIT;
          
        END IF;
        
        IF REC.TRX_TYPE  ='NKOR' AND REC.TRX_CD='C' THEN
          V_FROM_BANK   := 'XXX';
          V_TO_BANK     := V_BANK_CD;
          V_FROM_CLIENT :='KOREKSI';
          V_TO_CLIENT   :='FUND';
          V_FROM_ACCT   := REC.ACCT_DEBIT;
          V_TO_ACCT     := REC.ACCT_NUM;
        END IF;
        
        IF REC.TRX_TYPE  ='NINT' AND REC.TRX_CD='C' THEN
          V_FROM_BANK   :=V_BANK_CD;
          V_TO_BANK     := V_BANK_CD;
          V_FROM_CLIENT :='BUNGA';
          V_TO_CLIENT   := REC.CLIENT_CD;
          V_FROM_ACCT   := REC.ACCT_NUM;
          V_TO_ACCT     := REC.ACCT_NUM;
        END IF;
        
        IF REC.TRX_TYPE  ='NTAX' AND REC.TRX_CD='D' THEN
          V_FROM_BANK   := V_BANK_CD;
          V_TO_BANK     := V_BANK_CD;
          V_FROM_CLIENT :=REC.CLIENT_CD;
          V_TO_CLIENT   := 'TAX';
          V_FROM_ACCT   := REC.ACCT_NUM;
          V_TO_ACCT     := REC.ACCT_NUM;
        END IF;
        
        BEGIN
          Sp_T_FUND_MOVEMENT_UPD( V_DOC_NUM,--P_SEARCH_DOC_NUM
          V_DOC_NUM,                        --P_DOC_NUM
          P_TANGGALEFEKTIF,                 --P_DOC_DATE
          V_TRX_TYPE,                       --P_TRX_TYPE
          P_CLIENT_CD,                      --P_CLIENT_CD
          REC.BRANCH_CODE,                  --P_BRCH_CD
          'H2H',                         --P_SOURCE
          NULL,                             --P_DOC_REF_NUM
          NULL,                             --P_TAL_ID_REF
          NULL,                             --P_GL_ACCT_CD
          REC.TRX_TYPE,                     --P_SL_ACCT_CD
          REC.EXTERNAL_REF,                 --P_BANK_REF_NUM
          REC.TANGGALTIMESTAMP,             --P_BANK_MVMT_DATE
          REC.CLIENT_NAME,                  --P_ACCT_NAME
          REC.REMARKS,                      --P_REMARKS
          V_FROM_CLIENT,                    --P_FROM_CLIENT
          V_FROM_ACCT,                      --P_FROM_ACCT
          V_FROM_BANK,                      --P_FROM_BANK
          V_TO_CLIENT,                      --P_TO_CLIENT
          V_TO_ACCT,                        --P_TO_ACCT
          V_TO_BANK,                        --P_TO_BANK
          REC.TRX_AMT,                      --P_TRX_AMT
          SYSDATE,                          --P_CRE_DT
          P_USER_ID , NULL,                 --P_CANCEL_DT
          NULL,                             --P_CANCEL_BY
          0,                                --P_FEE
          NULL,                             --P_FOLDER_CD
          V_FUND_BANK_CD,                   -- P_FUND_BANK_CD
          V_FUND_BANK_ACCT,                 -- P_FUND_BANK_ACCT
          NULL,                             --P_UPD_DT
          NULL,                             --P_UPD_BY
          'I',                              --P_UPD_STATUS
          p_ip_address, NULL,               --p_cancel_reason
          V_UPDATE_DATE,                    -- p_update_date
          V_UPDATE_SEQ,                     --p_update_seq
          1,                                --p_record_seq
          V_ERROR_CODE,                     -- p_error_code
          V_ERROR_MSG                       --p_error_msg
          );
        EXCEPTION
        WHEN OTHERS THEN
          V_ERROR_CODE :=-80;
          V_ERROR_MSG  := SUBSTR('CALL Sp_T_FUND_MOVEMENT_UPD '||SQLERRM,1,200);
          RAISE V_ERR;
        END;
        
        IF V_ERROR_CODE <0 THEN
          V_ERROR_CODE :=-85;
          V_ERROR_MSG  := SUBSTR(V_ERROR_MSG,1,200);
          RAISE V_ERR;
        END IF;

      
    END LOOP;
    
    P_ERROR_CODE:=1;
    P_ERROR_MSG :='';
    
  EXCEPTION
  WHEN V_ERR THEN
    ROLLBACK;
    P_ERROR_CODE := V_ERROR_CODE;
    P_ERROR_MSG  := V_ERROR_MSG;
  WHEN OTHERS THEN
    P_ERROR_CODE := -1 ;
    P_ERROR_MSG  := SUBSTR(SQLERRM(SQLCODE),1,200);
    RAISE;
  END SP_FUND_AUTO_BCA_FAIL;