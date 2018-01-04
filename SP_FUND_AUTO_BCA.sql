create or replace PROCEDURE SP_FUND_AUTO_BCA(
    P_EXTERNAL_REF t_client_acct_statement.EXTERNAL_REF%TYPE,
    P_BANK_ACCT_NUM MST_CLIENT_FLACCT.BANK_ACCT_NUM%TYPE,
    p_user_id T_MANY_HEADER.USER_ID%TYPE,
    p_ip_address T_MANY_HEADER.IP_ADDRESS%TYPE,
    P_ERROR_CODE OUT NUMBER,
    P_ERROR_MSG OUT VARCHAR2)
IS
  V_ERROR_CODE NUMBER(5);
  V_ERROR_MSG  VARCHAR2(200);
  V_ERR        EXCEPTION;
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
  V_BANK_CD T_FUND_MOVEMENT.FUND_BANK_CD%TYPE;
  V_CNT_INBOX    NUMBER;
  V_CNT          NUMBER;
  V_FAIL_RDI_FLG VARCHAR2(1):='N';
  --V_FAIL_BANK_FLG   VARCHAR2(1):='N';
  --V_FAIL_TRX_CD_FLG VARCHAR2(1):='N';
  --DECLARE VAR FOR QUERY
  V_CLIENT_CD mst_client.CLIENT_CD%TYPE;
  V_CLIENT_NAME mst_client.CLIENT_NAME%TYPE;
  V_CIFS MST_CLIENT.CIFS%TYPE;
  V_EXTERNAL_REF t_client_acct_statement.EXTERNAL_REF%TYPE;
  --V_SEQNO t_client_acct_statement.SEQ_NO%TYPE;
  --V_CURR_CD t_client_acct_statement.CURR_CD%TYPE;
  V_ACCT_NUM t_client_acct_statement.ACCT_NUM%TYPE;
  V_TANGGALEFEKTIF t_client_acct_statement.TRX_DATE%TYPE;
  V_TRX_TYPE t_client_acct_statement.TRX_TYPE%TYPE;
  V_TRX_CD t_client_acct_statement.TRX_CD%TYPE;
  V_ACCT_DEBIT t_client_acct_statement.ACCT_DEBIT%TYPE;
  V_ACCT_CREDIT t_client_acct_statement.ACCT_CREDIT%TYPE;
  V_TRX_AMT t_client_acct_statement.TRX_AMT%TYPE;
  V_TANGGALTIMESTAMP T_FUND_MOVEMENT.BANK_MVMT_DATE%TYPE;
  V_BRANCH_CODE T_FUND_MOVEMENT.BRCH_CD%TYPE;
  V_REMARKS T_FUND_MOVEMENT.REMARKS%TYPE;
  V_DESCRIP MST_RDI_TRX_TYPE.DESCRIP%TYPE;
  V_TYPE T_FUND_MOVEMENT.TRX_TYPE%TYPE;
  V_CLOSING_HOUR MST_SYS_PARAM.DSTR1%TYPE;
  V_DATE_HOUR DATE;
  V_EXPIRED_FLG VARCHAR2(1):='N';
BEGIN

  BEGIN
    SELECT EXTERNAL_REF,ACCT_NUM,TRX_DATE,TRX_TYPE, TRX_CD, ACCT_DEBIT,ACCT_CREDIT ,TRX_AMT, R.DESCRIP,  COUNT(1) OVER( )CNT
    INTO V_EXTERNAL_REF, V_ACCT_NUM,V_TANGGALTIMESTAMP,V_TRX_TYPE,V_TRX_CD,V_ACCT_DEBIT,V_ACCT_CREDIT,V_TRX_AMT, V_DESCRIP, V_CNT
    FROM IPNEXTG.t_client_acct_statement A, IPNEXTG.MST_RDI_TRX_TYPE R, (
        SELECT REPLACE(REPLACE(BANK_ACCT_CD,'-',''),'.','') PE_BANK_ACCT
        FROM IPNEXTG.MST_BANK_ACCT
        WHERE BANK_ACCT_CD <> 'X'
      )
      B
    WHERE EXTERNAL_REF = P_EXTERNAL_REF
   -- AND TRUNC(TRX_DATE)    =TRUNC(SYSDATE)
    AND A.TRX_TYPE    = R.RDI_TRX_TYPE
    AND A.TRX_CD      =R.DB_CR_FLG
    AND A.ACCT_DEBIT  = B.PE_BANK_ACCT(+)
    AND PE_BANK_ACCT IS NULL;
  EXCEPTION
  WHEN NO_DATA_FOUND THEN
    V_CNT:=0;
  WHEN OTHERS THEN
    V_ERROR_CODE :=-10;
    V_ERROR_MSG  := SUBSTR('RETRIEVE DATA FROM t_client_acct_statement '||sqlerrm,1,200);
    RAISE V_ERR;
  END;
       
  --JIKA DATA YANG MASUK VALID
  IF V_CNT>0 THEN
  
    --20JAN2017
    --JIKA TANGGALTIMESTAMP LEBIH DARI JAM 16:00 DARI TANGGAL YANG BERJALAN, MAKA TANGGAL JURNALNYA DIBUAT TANGGAL KEESOKAN HARINYA
    BEGIN
      SELECT DSTR1
      INTO V_CLOSING_HOUR
      FROM MST_SYS_PARAM
      WHERE PARAM_ID='HOST TO HOST'
      AND PARAM_CD1 ='NOTIF'
      AND PARAM_CD2 ='YJ';
    EXCEPTION
    WHEN OTHERS THEN
      V_ERROR_CODE :=-12;
      V_ERROR_MSG  := SUBSTR('GET CLOSING HOUR FROM MST_SYS_PARAM '||sqlerrm,1,200);
      RAISE V_ERR;
    END;
    
      --CEK  TANGGAL JIKA EXPIRED
    IF V_TANGGALTIMESTAMP<TRUNC(SYSDATE)-2 THEN
      V_EXPIRED_FLG:='Y';
    END IF;
    
    IF V_EXPIRED_FLG <> 'Y' THEN
    
    V_DATE_HOUR          := TO_DATE(TO_CHAR(TRUNC(V_TANGGALTIMESTAMP),'DD-MM-YYYY')||V_CLOSING_HOUR,'DD-MM-YYYY HH24:MI:SS');
    IF V_TANGGALTIMESTAMP > V_DATE_HOUR THEN
      V_TANGGALEFEKTIF   :=GET_DUE_DATE(1,TRUNC(V_TANGGALTIMESTAMP));
    ELSE
      V_TANGGALEFEKTIF :=TRUNC(V_TANGGALTIMESTAMP);
    END IF;

    --CEK APAKAH HARI LIBUR
    IF F_IS_HOLIDAY(TO_CHAR(V_TANGGALEFEKTIF,'DD/MM/YYYY')) = 1 THEN
        V_TANGGALEFEKTIF   :=GET_DUE_DATE(1,V_TANGGALEFEKTIF);
    END IF;

    --SET TANGGAL TRX DATE SEBAGAI TANGGAL JURNAL JIKA TRX TYPE NINT DAN NTAX
    IF V_TRX_TYPE = 'NINT' OR V_TRX_TYPE='NTAX' THEN
        V_TANGGALEFEKTIF :=TRUNC(V_TANGGALTIMESTAMP);
    END IF;
    
    --CEK RDI VALID/INVALID
    BEGIN
      SELECT MAX(A.CLIENT_CD)CLIENT_CD,MAX(B.ACCT_NAME) CLIENT_NAME,MAX(A.CIFS)CIFS,TRIM(MAX(A.BRANCH_CODE))BRANCH_CODE, COUNT(B.CLIENT_CD)CNT
      INTO V_CLIENT_CD, V_CLIENT_NAME, V_CIFS, V_BRANCH_CODE, V_CNT
      FROM MST_CLIENT A, MST_CLIENT_FLACCT B
      WHERE A.CLIENT_CD  =B.CLIENT_CD
      AND B.BANK_ACCT_NUM=V_ACCT_NUM
      AND B.BANK_CD      ='BCA02'
      --AND A.SUSP_STAT    ='N'
      AND B.ACCT_STAT    IN ('A','B')
      AND A.CIFS        IS NOT NULL
      GROUP BY B.BANK_ACCT_NUM;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      V_FAIL_RDI_FLG :='Y';
    WHEN OTHERS THEN
      V_ERROR_CODE :=-30;
      V_ERROR_MSG  := SUBSTR('CHECK RDN FROM MST_CLIENT_FLACCT '||sqlerrm,1,200);
      RAISE V_ERR;
    END;
    
    IF V_CNT          >1 THEN
      V_FAIL_RDI_FLG :='Y';
    END IF;    
    
    BEGIN
      SELECT COUNT(1)
      INTO V_CNT
      FROM T_FUND_MOVEMENT
      WHERE DOC_DATE    =V_TANGGALEFEKTIF
      AND SOURCE        = 'H2H'
      AND BANK_REF_NUM  = V_EXTERNAL_REF
      AND client_cd     = V_CLIENT_CD
      AND TRX_AMT       = V_TRX_AMT
      AND APPROVED_STS <> 'C';
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      V_CNT :=0;
    WHEN OTHERS THEN
      V_ERROR_CODE :=-50;
      V_ERROR_MSG  := SUBSTR('CHECK JOURNAL FROM T_FUND_MOVEMENT '||V_CLIENT_CD||' '||sqlerrm,1,200);
      RAISE V_ERR;
    END;
    
    END IF;
    
    --BUAT JURNAL JIKA DATA VALID
    IF V_CNT=0 AND V_FAIL_RDI_FLG <> 'Y' AND V_EXPIRED_FLG <>'Y' THEN
    
        BEGIN
          SP_T_MANY_HEADER_INSERT ( V_MENU_NAME, 'I', p_user_id, p_ip_address, NULL, V_UPDATE_DATE, V_UPDATE_SEQ , V_ERROR_CODE , V_ERROR_MSG );
        EXCEPTION
        WHEN OTHERS THEN
          V_ERROR_CODE :=-70;
          V_ERROR_MSG  := SUBSTR('CALL SP_T_MANY_HEADER_INSERT '||sqlerrm,1,200);
          RAISE V_ERR;
        END;
        
        --TRX TYPE
        IF V_TRX_CD ='C' THEN
          V_TYPE   :='R';
        ELSE
          V_TYPE :='W';
        END IF;
        
        V_FUND_BANK_CD   := 'BCA02';
        V_FUND_BANK_ACCT := V_ACCT_NUM;
        V_BANK_CD        := 'BCA';
        
        IF V_TRX_TYPE     = 'NTRF' AND V_TRX_CD ='C' THEN
          IF V_ACCT_DEBIT ='0000000000' OR V_ACCT_DEBIT ='0' THEN
            V_FROM_BANK  := 'XXX';
          ELSE
            V_FROM_BANK := 'BCA';
          END IF;
          V_TO_BANK     := V_BANK_CD ;
          V_FROM_CLIENT :='LUAR';
          V_TO_CLIENT   :='FUND';
          V_FROM_ACCT   := V_ACCT_DEBIT;
          V_TO_ACCT     := V_ACCT_NUM;
        END IF;
        
        IF V_TRX_TYPE    ='NKOR' AND V_TRX_CD ='C' THEN
          V_FROM_BANK   := 'XXX';
          V_TO_BANK     := V_BANK_CD;
          V_FROM_CLIENT :='KOREKSI';
          V_TO_CLIENT   :='FUND';
          V_FROM_ACCT   := V_ACCT_DEBIT;
          V_TO_ACCT     := V_ACCT_NUM;
        END IF;
        
        IF V_TRX_TYPE    ='NINT' AND V_TRX_CD ='C' THEN
          V_FROM_BANK   :=V_BANK_CD;
          V_TO_BANK     := V_BANK_CD;
          V_FROM_CLIENT :='BUNGA';
          V_TO_CLIENT   := V_CLIENT_CD;
          V_FROM_ACCT   := V_ACCT_NUM;
          V_TO_ACCT     := V_ACCT_NUM;
        END IF;
        
        IF V_TRX_TYPE    ='NTAX' AND V_TRX_CD ='D' THEN
          V_FROM_BANK   := V_BANK_CD;
          V_TO_BANK     := V_BANK_CD;
          V_FROM_CLIENT := V_CLIENT_CD;
          V_TO_CLIENT   := 'TAX';
          V_FROM_ACCT   := V_ACCT_NUM;
          V_TO_ACCT     := V_ACCT_NUM;
        END IF;
        
        IF V_TRX_TYPE = 'NINT' THEN
          V_REMARKS  :='Bunga '||V_CLIENT_CD;
        ELSE
          V_REMARKS :=V_DESCRIP||' '||V_CLIENT_CD;
        END IF;
        
        BEGIN
          Sp_T_FUND_MOVEMENT_UPD( V_DOC_NUM,--P_SEARCH_DOC_NUM
          V_DOC_NUM,                        --P_DOC_NUM
          V_TANGGALEFEKTIF,                 --P_DOC_DATE
          V_TYPE,                           --P_TRX_TYPE
          V_CLIENT_CD,                      --P_CLIENT_CD
          V_BRANCH_CODE,                    --P_BRCH_CD
          'H2H',                            --P_SOURCE
          NULL,                             --P_DOC_REF_NUM
          NULL,                             --P_TAL_ID_REF
          NULL,                             --P_GL_ACCT_CD
          V_TRX_TYPE,                       --P_SL_ACCT_CD
          V_EXTERNAL_REF,                   --P_BANK_REF_NUM
          V_TANGGALTIMESTAMP,               --P_BANK_MVMT_DATE
          V_CLIENT_NAME,                    --P_ACCT_NAME
          V_REMARKS,                        --P_REMARKS
          V_FROM_CLIENT,                    --P_FROM_CLIENT
          V_FROM_ACCT,                      --P_FROM_ACCT
          V_FROM_BANK,                      --P_FROM_BANK
          V_TO_CLIENT,                      --P_TO_CLIENT
          V_TO_ACCT,                        --P_TO_ACCT
          V_TO_BANK,                        --P_TO_BANK
          V_TRX_AMT,                        --P_TRX_AMT
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
          V_ERROR_CODE :=-90;
          V_ERROR_MSG  := SUBSTR(V_ERROR_MSG,1,200);
          RAISE V_ERR;
        END IF;
        
        --LANGSUNG APPROVE UNTUK NINT DAN NTAX, yang berjalan sekarang langsung approve
        IF V_TRX_TYPE ='NINT' OR V_TRX_TYPE ='NTAX' THEN
        
          BEGIN
            SP_T_FUND_MOVEMENT_APPROVE (V_MENU_NAME,-- p_menu_name
            V_UPDATE_DATE,                          -- p_update_date
            V_UPDATE_SEQ,                           --a p_update_seq
            P_USER_ID,                              -- p_approved_user_id
            p_ip_address,                           -- p_approved_ip_address
            V_ERROR_CODE, V_ERROR_MSG);
          EXCEPTION
          WHEN OTHERS THEN
            V_ERROR_CODE :=-90;
            V_ERROR_MSG  := SUBSTR('CALL SP_T_FUND_MOVEMENT_APPROVE '||SQLERRM,1,200);
            RAISE V_ERR;
          END;
          
          IF V_ERROR_CODE <0 THEN
            V_ERROR_CODE :=-95;
            V_ERROR_MSG  := SUBSTR(V_CLIENT_CD||' '||V_ERROR_CODE||' '||V_ERROR_MSG,1,200);
            RAISE V_ERR;
          END IF;
          
        END IF;
      
    END IF;  --end bUAT JURNAL JIKA DATA BELUM DIJURNAL
    
    IF V_FAIL_RDI_FLG='Y'  OR V_EXPIRED_FLG='Y' THEN
      BEGIN
        SELECT COUNT(1)
        INTO V_CNT
        FROM T_CLIENT_ACCT_STMT_FAIL
        WHERE EXTERNAL_REF = V_EXTERNAL_REF;
      EXCEPTION
      WHEN OTHERS THEN
        V_ERROR_CODE :=-100;
        V_ERROR_MSG  :=SUBSTR('SELECT COUNT T_CLIENT_ACCT_STMT_FAIL '||V_EXTERNAL_REF ||' '||SQLERRM,1,200);
        RAISE V_ERR;
      END;
      
      IF V_CNT =0 THEN
      
        BEGIN
          INSERT
          INTO T_CLIENT_ACCT_STMT_FAIL
            (
              EXTERNAL_REF , SEQ_NO , ACCT_NUM , CURR_CD , TRX_DATE , TRX_TYPE , TRX_CD , ACCT_DEBIT , ACCT_CREDIT , TRX_AMT , OPEN_BAL , CLOSE_BAL , DESCRIPTION , CRE_DT
            )
          SELECT EXTERNAL_REF , SEQ_NO , ACCT_NUM , CURR_CD , TRX_DATE , TRX_TYPE , TRX_CD , ACCT_DEBIT , ACCT_CREDIT , TRX_AMT , OPEN_BAL , CLOSE_BAL , DESCRIPTION , CRE_DT
          FROM t_client_acct_statement
          WHERE EXTERNAL_REF=P_EXTERNAL_REF;
        EXCEPTION
        WHEN OTHERS THEN
          V_ERROR_CODE :=-110;
          V_ERROR_MSG  :=SUBSTR('INSERT INTO T_CLIENT_ACCT_STMT_FAIL '||SQLERRM,1,200);
          RAISE V_ERR;
        END;
        
      END IF;--END IF NO DATA FOUND IN T_CLIENT_ACCT_STMT_FAIL
      
    END IF;  --END JIKA 1 RDN DIMILIKI LEBIH DARI 1 NASABAH
    
  END IF;    --END IF DATA VALID FOR JOURNAL
  
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
END SP_FUND_AUTO_BCA;