CREATE OR REPLACE PROCEDURE SP_DAILY_OTC_JUR
(   P_OTC_DATE DATE,
    P_JOURNAL_DATE DATE,
    P_FOLDER_CD T_ACCOUNT_LEDGER.FOLDER_CD%TYPE,
    P_USER_ID IN T_ACCOUNT_LEDGER.USER_ID%TYPE,
    P_IP_ADDRESS T_MANY_HEADER.IP_ADDRESS%TYPE,
                 P_ERROR_CODE OUT NUMBER,
                 P_ERROR_MSG OUT VARCHAR2   ) IS 

CURSOR CSR_JUR IS
SELECT T.CLIENT_CD, MAX(T.SUM_OTC)SUM_OTC, TRIM(BRANCH_CODE) BRANCH_CODE
FROM T_DAILY_OTC_JUR T, MST_CLIENT M
WHERE T.JUR_DATE = P_OTC_DATE
AND T.XN_DOC_NUM IS NULL
AND T.TIDAK_DIJURNAL = 'N'
AND T.CLIENT_CD = M.CLIENT_CD
GROUP BY T.CLIENT_CD,TRIM(BRANCH_CODE);

SELECT T.CLIENT_CD, MAX(T.SUM_OTC)SUM_OTC, TRIM(BRANCH_CODE) BRANCH_CODE
FROM T_DAILY_OTC_JUR T, MST_CLIENT M
WHERE T.JUR_DATE = P_OTC_DATE
AND T.XN_DOC_NUM IS NULL
AND T.TIDAK_DIJURNAL = 'N'
AND T.CLIENT_CD = M.CLIENT_CD
GROUP BY T.CLIENT_CD,TRIM(BRANCH_CODE);

  V_DBCR_FLG                T_ACCOUNT_LEDGER.DB_CR_FLG%TYPE;
  V_GL_ACCT_CD              T_ACCOUNT_LEDGER.GL_ACCT_CD%TYPE;
  V_SL_ACCT_CD              T_ACCOUNT_LEDGER.SL_ACCT_CD%TYPE;
  V_GLA_BIAYA_YMH             T_ACCOUNT_LEDGER.GL_ACCT_CD%TYPE;
  V_SLA_BIAYA_YMH             T_ACCOUNT_LEDGER.SL_ACCT_CD%TYPE;
  V_GLA_JASA T_ACCOUNT_LEDGER.GL_ACCT_CD%TYPE;
  V_SLA_JASA              T_ACCOUNT_LEDGER.SL_ACCT_CD%TYPE;
  V_TAL_ID                  T_ACCOUNT_LEDGER.TAL_ID%TYPE;
  V_FOLDER_CD                              T_ACCOUNT_LEDGER.FOLDER_CD%TYPE;
  V_LEDGER_NAR                            T_ACCOUNT_LEDGER.LEDGER_NAR%TYPE;
  V_RECORD_SOURCE                       T_ACCOUNT_LEDGER.RECORD_SOURCE%TYPE;
  V_NL                    CHAR(2);
  
  
  
  
V_JVCH_NUM T_JVCHH.JVCH_NUM%TYPE;
V_JVCH_DATE T_JVCHH.JVCH_DATE%TYPE;
V_DOC_REF CHAR(1);
V_DOC_REF_NUM T_ACCOUNT_LEDGER.XN_DOC_NUM%TYPE;
V_ACCT_TYPE MST_GL_ACCOUNT.ACCT_TYPE%TYPE;
V_GRAND_TOTAL T_ACCOUNT_LEDGER.CURR_VAL%TYPE;
V_CEK_FOLDER CHAR(1);
V_RECORD_SEQ                                    NUMBER;

V_ERR EXCEPTION;
V_ERROR_CD NUMBER;
V_ERROR_MSG VARCHAR2(200);
V_MENU_NAME T_MANY_HEADER.MENU_NAME%TYPE :='DAILY OTC JUR';
V_UPDATE_DATE T_MANY_HEADER.UPDATE_DATE%TYPE;
V_UPDATE_SEQ T_MANY_HEADER.UPDATE_SEQ%TYPE;
V_FLD_MON T_FOLDER.FLD_MON%TYPE;
V_RTN NUMBER(1);
V_DOC_NUM T_FOLDER.DOC_NUM%TYPE;
V_DOC_DATE DATE;    
V_USER_ID T_FOLDER.USER_ID%TYPE;
V_NONCHARGEABLE_AMT NUMBER;
BEGIN

    V_NL := CHR(10)||CHR(13);
    V_GRAND_TOTAL  := 0;
 
  BEGIN
    SELECT DFLG1 INTO V_DOC_REF FROM MST_SYS_PARAM 
    WHERE PARAM_ID = 'SYSTEM' AND PARAM_CD1 = 'DOC_REF';
  EXCEPTION
    WHEN OTHERS THEN
      V_ERROR_CD := -4;
      V_ERROR_MSG := SUBSTR('SELECT DOC_REF FROM MST_SYS_PARAM '|| SQLERRM(SQLCODE),1,200);
      RAISE V_ERR;
  END;
    
  BEGIN
    SELECT DFLG1 INTO V_CEK_FOLDER FROM MST_SYS_PARAM 
    WHERE PARAM_ID='SYSTEM' AND PARAM_CD1='VCH_REF';
  EXCEPTION
    WHEN OTHERS THEN
      V_ERROR_CD :=-10;
      V_ERROR_MSG := SUBSTR('CEK USING FOLDER_CD FROM MST_SYS_PARAM'||SQLERRM,1,200);
      RAISE V_ERR;
  END;  
  
-- GL ACCT CD BIAYA YANG MSH HRS DIBAYAR
  BEGIN
    SELECT DSTR1, DSTR2 INTO V_GLA_BIAYA_YMH, V_SLA_BIAYA_YMH 
        FROM MST_SYS_PARAM 
    WHERE PARAM_ID='OTC_JOURNAL' AND PARAM_CD1='YMH';
  EXCEPTION
    WHEN OTHERS THEN
      V_ERROR_CD :=-15;
      V_ERROR_MSG := SUBSTR('GL ACCT CD BIAYA YMH FROM MST_SYS_PARAM'||SQLERRM,1,200);
      RAISE V_ERR;
  END;  
-- GL ACCT CD BIAYA YANG MSH HRS DIBAYAR
  BEGIN
    SELECT DSTR1, DSTR2 INTO V_GLA_JASA, V_SLA_JASA
        FROM MST_SYS_PARAM 
    WHERE PARAM_ID='OTC_JOURNAL' AND PARAM_CD1='JASA';
  EXCEPTION
    WHEN OTHERS THEN
      V_ERROR_CD :=-16;
      V_ERROR_MSG := SUBSTR('GL ACCT CD BIAYA JASA KSEI FROM MST_SYS_PARAM'||SQLERRM,1,200);
      RAISE V_ERR;
  END;
    
      BEGIN
        SP_T_MANY_HEADER_INSERT(V_MENU_NAME,
                     'I',
                     P_USER_ID,
                     P_IP_ADDRESS,
                     NULL,
                     V_UPDATE_DATE,
                     V_UPDATE_SEQ,
                     V_ERROR_CD,
                     V_ERROR_MSG);
      EXCEPTION
        WHEN OTHERS THEN
          V_ERROR_CD := -11;
          V_ERROR_MSG := SUBSTR('SP_T_MANY_HEADER_INSERT '|| SQLERRM(SQLCODE),1,200);
          RAISE V_ERR;
      END; 
         
            IF V_ERROR_CD < 0 THEN 
                V_ERROR_CD := -95;
                V_ERROR_MSG := SUBSTR(V_ERROR_MSG||V_NL||SQLERRM,1,200);
                RAISE V_ERR;
            END IF;
            
            V_JVCH_DATE := P_JOURNAL_DATE;
            V_TAL_ID := 0;
            V_FOLDER_CD := P_FOLDER_CD;
            V_RECORD_SOURCE := 'GL';


        FOR REC IN CSR_JUR LOOP
        
            IF V_TAL_ID = 0 THEN 
                V_JVCH_NUM := GET_DOCNUM_GL( V_JVCH_DATE, 'GL'); 
            END IF;
            
            V_DBCR_FLG := 'D';
                    
            V_GL_ACCT_CD := F_GL_ACCT_T3_JAN2016(REC.CLIENT_CD,V_DBCR_FLG);
            V_SL_ACCT_CD := REC.CLIENT_CD;
            
    -- INSERT T_ACCOUNT_LEDGER
            V_TAL_ID :=  V_TAL_ID + 1;
            V_LEDGER_NAR := 'BIAYA OTC';
            V_ACCT_TYPE := 'AR';
            
            IF  V_DOC_REF ='Y' THEN
                V_DOC_REF_NUM := V_JVCH_NUM;
            END IF;
            
             
  
    -- AR/ AP     
            BEGIN
            SP_T_ACCOUNT_LEDGER_UPD(
                V_JVCH_NUM, --P_SEARCH_XN_DOC_NUM
                V_TAL_ID, --P_SEARCH_TAL_ID 
                V_JVCH_NUM, --P_XN_DOC_NUM 
                V_TAL_ID, --P_TAL_ID   
                V_DOC_REF_NUM, --P_DOC_REF_NUM   
                V_ACCT_TYPE,  
                V_SL_ACCT_CD,
                V_GL_ACCT_CD,
                NULL, --    P_CHRG_CD,
                NULL,--    P_CHQ_SNO
                'IDR',--    P_CURR_CD
                REC.BRANCH_CODE,--    P_BRCH_CD
                REC.SUM_OTC, --    P_CURR_VAL 
                REC.SUM_OTC,  --    P_XN_VAL
                'OTCFEE', --    P_BUDGET_CD   
                V_DBCR_FLG, --    P_DB_CR_FLG
                V_LEDGER_NAR,
                NULL,--      P_CASHIER_ID
                V_JVCH_DATE,--    P_DOC_DATE 
                V_JVCH_DATE,--   P_DUE_DATE 
                V_JVCH_DATE,--   P_NETTING_DATE 
                NULL,--  P_NETTING_FLG  
                 V_RECORD_SOURCE,
                0,--   P_SETT_FOR_CURR 
                NULL,--  P_SETT_STATUS    
                NULL,--      P_RVPV_NUMBER
                V_FOLDER_CD,--    P_FOLDER_CD 
                0,--     P_SETT_VAL   
                V_JVCH_DATE,--     P_ARAP_DUE_DATE
                NULL,--      P_RVPV_GSSL
                NULL,--     P_CASH_WITHDRAW_AMT       NUMBER,
                NULL,--       P_CASH_WITHDRAW_REASON  
                P_USER_ID,
                SYSDATE,  --  P_CRE_DT   
                 NULL,--            T_ACCOUNT_LEDGER.UPD_BY%TYPE,
                 NULL,--     P_UPD_DT 
                 'N', --   P_REVERSAL_JUR  
                 'N', --   P_MANUAL  
                 'I',--                 P_UPD_STATUS
                P_IP_ADDRESS, 
                NULL,--P_CANCEL_REASON,
                V_UPDATE_DATE,--P_UPDATE_DATE,
                V_UPDATE_SEQ,--P_UPDATE_SEQ,
                V_TAL_ID,--P_RECORD_SEQ,
                V_ERROR_CD,--P_ERROR_CODE,
                V_ERROR_MSG
                );
                      
            EXCEPTION
      WHEN OTHERS THEN
        V_ERROR_CD := -70;
        V_ERROR_MSG := SUBSTR('INSERT T_ACCOUNT_LEDGER : '||V_JVCH_NUM||V_NL||SQLERRM,1,200);
        RAISE V_ERR;
            END;
      
            IF V_ERROR_CD < 0 THEN 
                V_ERROR_CD := -75;
                V_ERROR_MSG := SUBSTR(V_ERROR_MSG||V_NL||SQLERRM,1,200);
                RAISE V_ERR;
            END IF;

        END LOOP;            

        IF V_TAL_ID > 0 THEN
            
        V_TAL_ID :=  V_TAL_ID + 1;
      V_LEDGER_NAR := 'BIAYA OTC NONCHARGEABLE';
            V_GL_ACCT_CD := V_GLA_JASA;
            V_SL_ACCT_CD := V_SLA_JASA;
            V_DBCR_FLG := 'D';
            BEGIN
        SELECT NVL(SUM(SUM_OTC),0) INTO V_NONCHARGEABLE_AMT FROM T_DAILY_OTC_JUR A JOIN (
        SELECT MAX(ROWID) TABLE_ROWID FROM T_DAILY_OTC_JUR 
        WHERE JUR_DATE=P_OTC_DATE
        AND TIDAK_DIJURNAL= 'Y'
        AND XN_DOC_NUM IS NULL
        GROUP BY CLIENT_CD
        )B ON A.ROWID=B.TABLE_ROWID;
      EXCEPTION
      WHEN OTHERS THEN
        V_ERROR_CD := -78;
        V_ERROR_MSG := SUBSTR('SUM NONCHARGEABLE : '||V_NL||SQLERRM,1,200);
        RAISE V_ERR;
            END;

            IF V_NONCHARGEABLE_AMT>0 THEN
        -- BIAYA OTC NONCHARGEABLE      
                BEGIN
                SP_T_ACCOUNT_LEDGER_UPD(
                    V_JVCH_NUM, --P_SEARCH_XN_DOC_NUM
                    V_TAL_ID, --P_SEARCH_TAL_ID 
                    V_JVCH_NUM, --P_XN_DOC_NUM 
                    V_TAL_ID, --P_TAL_ID   
                    V_DOC_REF_NUM, --P_DOC_REF_NUM   
                    NULL,  
                    V_SL_ACCT_CD,
                    V_GL_ACCT_CD,
                    NULL, --    P_CHRG_CD,
                    NULL,--    P_CHQ_SNO
                    'IDR',--    P_CURR_CD
                    NULL,--    P_BRCH_CD
                    V_NONCHARGEABLE_AMT, --    P_CURR_VAL 
                    V_NONCHARGEABLE_AMT,  --    P_XN_VAL
                    'OTCFEE', --    P_BUDGET_CD   
                    V_DBCR_FLG, --    P_DB_CR_FLG
                    V_LEDGER_NAR,
                    NULL,--      P_CASHIER_ID
                    V_JVCH_DATE,--    P_DOC_DATE 
                    V_JVCH_DATE,--   P_DUE_DATE 
                    V_JVCH_DATE,--   P_NETTING_DATE 
                    NULL,--  P_NETTING_FLG  
                     V_RECORD_SOURCE,
                    0,--   P_SETT_FOR_CURR 
                    NULL,--  P_SETT_STATUS    
                    NULL,--      P_RVPV_NUMBER
                    V_FOLDER_CD,--    P_FOLDER_CD 
                    0,--     P_SETT_VAL   
                    V_JVCH_DATE,--     P_ARAP_DUE_DATE
                    NULL,--      P_RVPV_GSSL
                    NULL,--     P_CASH_WITHDRAW_AMT       NUMBER,
                    NULL,--       P_CASH_WITHDRAW_REASON  
                    P_USER_ID,
                    SYSDATE,  --  P_CRE_DT   
                     NULL,--            T_ACCOUNT_LEDGER.UPD_BY%TYPE,
                     NULL,--     P_UPD_DT 
                     'N', --   P_REVERSAL_JUR  
                     'N', --   P_MANUAL  
                     'I',--                 P_UPD_STATUS
                    P_IP_ADDRESS, 
                    NULL,--P_CANCEL_REASON,
                    V_UPDATE_DATE,--P_UPDATE_DATE,
                    V_UPDATE_SEQ,--P_UPDATE_SEQ,
                    V_TAL_ID,--P_RECORD_SEQ,
                    V_ERROR_CD,--P_ERROR_CODE,
                    V_ERROR_MSG
                    );
                EXCEPTION
          WHEN OTHERS THEN
            V_ERROR_CD := -79;
            V_ERROR_MSG := SUBSTR('INSERT T_ACCOUNT_LEDGER : '||V_JVCH_NUM||V_NL||SQLERRM,1,200);
            RAISE V_ERR;
                END;
          
                IF V_ERROR_CD < 0 THEN 
                    V_ERROR_CD := -80;
                    V_ERROR_MSG := SUBSTR(V_ERROR_MSG||V_NL||SQLERRM,1,200);
                    RAISE V_ERR;
                END IF;

            END IF;

 -- 2510            
 
            V_TAL_ID :=  V_TAL_ID + 1;
            V_LEDGER_NAR := 'BIAYA YMH OTC';
            V_GL_ACCT_CD := V_GLA_BIAYA_YMH;
            V_SL_ACCT_CD := V_SLA_BIAYA_YMH;
            V_DBCR_FLG := 'C';
            
             BEGIN
        SELECT NVL(SUM(SUM_OTC),0) INTO V_GRAND_TOTAL FROM T_DAILY_OTC_JUR A JOIN (
          SELECT MAX(ROWID) TABLE_ROWID FROM T_DAILY_OTC_JUR 
          WHERE JUR_DATE=P_OTC_DATE
          AND XN_DOC_NUM IS NULL
          GROUP BY CLIENT_CD
          )B ON A.ROWID=B.TABLE_ROWID;
      EXCEPTION
      WHEN OTHERS THEN
        V_ERROR_CD := -81;
        V_ERROR_MSG := SUBSTR('SUM ALL OTC : '||V_NL||SQLERRM,1,200);
        RAISE V_ERR;
            END;

            
            BEGIN
            SP_T_ACCOUNT_LEDGER_UPD(
                V_JVCH_NUM, --P_SEARCH_XN_DOC_NUM
                V_TAL_ID, --P_SEARCH_TAL_ID 
                V_JVCH_NUM, --P_XN_DOC_NUM 
                V_TAL_ID, --P_TAL_ID   
                V_DOC_REF_NUM, --P_DOC_REF_NUM   
                NULL,  
                V_SL_ACCT_CD,
                V_GL_ACCT_CD,
                NULL, --    P_CHRG_CD,
                NULL,--    P_CHQ_SNO
                'IDR',--    P_CURR_CD
                NULL,--    P_BRCH_CD
                V_GRAND_TOTAL, --    P_CURR_VAL 
                V_GRAND_TOTAL,  --    P_XN_VAL
                'OTCFEE', --    P_BUDGET_CD   
                V_DBCR_FLG, --    P_DB_CR_FLG
                V_LEDGER_NAR,
                NULL,--      P_CASHIER_ID
                V_JVCH_DATE,--    P_DOC_DATE 
                NULL,--   P_DUE_DATE  
                NULL,--   P_NETTING_DATE  
                NULL,--  P_NETTING_FLG  
                 V_RECORD_SOURCE,
                NULL,--   P_SETT_FOR_CURR 
                NULL,--  P_SETT_STATUS    
                NULL,--      P_RVPV_NUMBER
                V_FOLDER_CD,--    P_FOLDER_CD 
                NULL,--     P_SETT_VAL    
                NULL,--     P_ARAP_DUE_DATE
                NULL,--      P_RVPV_GSSL
                NULL,--     P_CASH_WITHDRAW_AMT       NUMBER,
                NULL,--       P_CASH_WITHDRAW_REASON  
                P_USER_ID,
                SYSDATE,  --  P_CRE_DT   
                 NULL,--            T_ACCOUNT_LEDGER.UPD_BY%TYPE,
                 NULL,--     P_UPD_DT 
                 'N', --   P_REVERSAL_JUR  
                 'N', --   P_MANUAL  
                 'I',--                 P_UPD_STATUS
                P_IP_ADDRESS, 
                NULL,--P_CANCEL_REASON,
                V_UPDATE_DATE,--P_UPDATE_DATE,
                V_UPDATE_SEQ,--P_UPDATE_SEQ,
                V_TAL_ID,--P_RECORD_SEQ,
                V_ERROR_CD,--P_ERROR_CODE,
                V_ERROR_MSG
                );
            EXCEPTION
      WHEN OTHERS THEN
        V_ERROR_CD := -25;
        V_ERROR_MSG := SUBSTR('SP_T_JVCHH_UPD '|| SQLERRM(SQLCODE),1,200);
        RAISE V_ERR;
          END;          
                
            IF  V_ERROR_CD < 0 THEN
                V_ERROR_CD := -30;
                V_ERROR_MSG :=SUBSTR('CALL SP_T_JVCHH_UPD : '||V_ERROR_MSG,1,200);
                RAISE V_ERR;
            END IF;   
            
                  
            IF V_ERROR_CD < 0 THEN 
                V_ERROR_CD := -95;
                V_ERROR_MSG := SUBSTR(V_ERROR_MSG||V_NL||SQLERRM,1,200);
                RAISE V_ERR;
            END IF;
  
    
            BEGIN              
            SP_T_JVCHH_UPD (
              V_JVCH_NUM, --P_SEARCH_JVCH_NUM
              V_JVCH_NUM, --    T_JVCHH.JVCH_NUM%TYPE,
              V_RECORD_SOURCE,  --  T_JVCHH.JVCH_TYPE%TYPE,
              V_JVCH_DATE, --   T_JVCHH.JVCH_DATE%TYPE,
              NULL,--   T_JVCHH.GL_ACCT_CD%TYPE,
              NULL, --  T_JVCHH.SL_ACCT_CD%TYPE,
              'IDR',  --    T_JVCHH.CURR_CD%TYPE,
              V_GRAND_TOTAL, --   T_JVCHH.CURR_AMT%TYPE,
              'BIAYA OTC', --   T_JVCHH.REMARKS%TYPE,
              P_USER_ID, --   T_JVCHH.USER_ID%TYPE,
              SYSDATE,  --  T_JVCHH.CRE_DT%TYPE,
              NULL,   --T_JVCHH.UPD_DT%TYPE,
              V_FOLDER_CD,   --   T_JVCHH.FOLDER_CD%TYPE,
              'N', --   T_JVCHH.REVERSAL_JUR%TYPE,
              'I',  -- P_UPD_STATUS         T_MANY_DETAIL.UPD_STATUS%TYPE,
              P_IP_ADDRESS, --        T_MANY_HEADER.IP_ADDRESS%TYPE,
              NULL,--P_CANCEL_REASON,
              V_UPDATE_DATE,--P_UPDATE_DATE,
              V_UPDATE_SEQ,--P_UPDATE_SEQ,
              1, --V_RECORD_SEQ,
              V_ERROR_CD,--P_ERROR_CODE,
              V_ERROR_MSG--P_ERROR_MSG    
              );   
  
        EXCEPTION
      WHEN OTHERS THEN
        V_ERROR_CD := -25;
        V_ERROR_MSG := SUBSTR('SP_T_JVCHH_UPD '|| SQLERRM(SQLCODE),1,200);
        RAISE V_ERR;
          END;          
                
            IF  V_ERROR_CD < 0 THEN
                V_ERROR_CD := -30;
                V_ERROR_MSG :=SUBSTR('CALL SP_T_JVCHH_UPD : '||V_ERROR_MSG,1,200);
                RAISE V_ERR;
            END IF;  

            IF V_CEK_FOLDER='Y' THEN


            V_FLD_MON   :=TO_CHAR(V_JVCH_DATE,'MMYY');
            BEGIN
              SP_CHECK_FOLDER_CD( P_FOLDER_CD, V_JVCH_DATE,--P_DATE
              V_RTN,                                         --P_RTN
              V_DOC_NUM,                                     -- P_DOC_NUM
              V_USER_ID,                                     -- P_USER_ID
              V_DOC_DATE                                     --P_DOC_DATE
              );
            EXCEPTION
            WHEN OTHERS THEN
              V_ERROR_CD := -135;
              V_ERROR_MSG  :=SUBSTR('SP_CHECK_FOLDER_CD'||SQLERRM,1,200);
              RAISE V_ERR;
            END;
            
            IF V_ERROR_CD <0 THEN
              V_ERROR_CD := -140;
              V_ERROR_MSG  :=SUBSTR('SP_CHECK_FOLDER_CD '||V_ERROR_MSG,1,200);
              RAISE V_ERR;
            END IF;
            
            IF V_RTN        =1 THEN
              V_ERROR_CD :=-145;
              V_ERROR_MSG  :='FILE CODE '||V_FOLDER_CD||' IS ALREADY USED BY '||P_USER_ID||' '|| V_DOC_NUM||' '||V_DOC_DATE;
              RAISE V_ERR;
            END IF;


                    BEGIN              
                     SP_T_FOLDER_UPD (
                        V_JVCH_NUM, --P_SEARCH_DOC_NUM   
                        TO_CHAR(V_JVCH_DATE,'MMYY'), --P_FLD_MON        
                        V_FOLDER_CD,
                        V_JVCH_DATE,
                        V_JVCH_NUM, --          T_FOLDER.DOC_NUM%TYPE,
                        P_USER_ID,
                        SYSDATE, --P_CRE_DT
                        NULL,-- P_UPD_BY
                        NULL,-- P_UPD_DT
                        'I', --P_UPD_STATUS 
                        P_IP_ADDRESS,
                        NULL,--P_CANCEL_REASON
                        V_UPDATE_DATE,
                        V_UPDATE_SEQ,
                        1,--P_RECORD_SEQ,
                        V_ERROR_CD,--P_ERROR_CODE,
                        V_ERROR_MSG--P_ERROR_MSG 
                          );   
          
                    EXCEPTION
                    WHEN OTHERS THEN
                        V_ERROR_CD := -150;
                        V_ERROR_MSG := SUBSTR('SP_T_FOLDER_UPD '|| SQLERRM(SQLCODE),1,200);
                        RAISE V_ERR;
                    END;          
                                        
                    IF  V_ERROR_CD < 0 THEN
                        V_ERROR_CD := -155;
                        V_ERROR_MSG :=SUBSTR('CALL SP_T_FOLDER_UPD : '||V_ERROR_MSG,1,200);
                        RAISE V_ERR;
                    END IF;
            END IF;
            
                --CALL SP_T_MANY_APPROVE
            BEGIN
                SP_T_MANY_APPROVE(V_MENU_NAME,--P_MENU_NAME,
                                 V_UPDATE_DATE,--P_UPDATE_DATE,
                                 V_UPDATE_SEQ,--P_UPDATE_SEQ,
                                 P_USER_ID,--P_APPROVED_USER_ID,
                                 P_IP_ADDRESS,--P_APPROVED_IP_ADDRESS,
                                 V_ERROR_CD,
                                 V_ERROR_MSG);
            EXCEPTION
                WHEN OTHERS THEN
                    V_ERROR_CD := -160;
                    V_ERROR_MSG :=SUBSTR('SP_T_MANY_APPROVE : '||V_NL||SQLERRM(SQLCODE),1,200);
                    RAISE V_ERR;
            END;
                
            IF  V_ERROR_CD < 0 THEN
                V_ERROR_CD := -170;
                V_ERROR_MSG :=SUBSTR('SP_T_MANY_APPROVE : '||V_ERROR_MSG,1,200);
                RAISE V_ERR;
            END IF;             
              
             BEGIN    
            UPDATE T_DAILY_OTC_JUR
            SET XN_DOC_NUM = V_JVCH_NUM
            WHERE JUR_DATE = P_OTC_DATE
            AND XN_DOC_NUM IS NULL;
            EXCEPTION
    WHEN OTHERS THEN
      V_ERROR_CD := -180;
      V_ERROR_MSG := SUBSTR('SELECT DOC_REF FROM MST_SYS_PARAM '|| SQLERRM(SQLCODE),1,200);
      RAISE V_ERR;
  
            END;
            
        END IF;   -- V_TAL_ID > 0 ADA JURNAL
        
  P_ERROR_CODE:=1;
  P_ERROR_MSG:='';
  
EXCEPTION
WHEN V_ERR THEN
  ROLLBACK;
  P_ERROR_CODE :=V_ERROR_CD;
  P_ERROR_MSG  :=V_ERROR_MSG;
WHEN OTHERS THEN
  ROLLBACK;
  P_ERROR_CODE :=-1;
  P_ERROR_MSG  :=SUBSTR(SQLERRM,1,200);
  RAISE;       
END SP_DAILY_OTC_JUR;