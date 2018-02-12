create or replace PROCEDURE SP_CASH_FLOW_REAL_ADP(
    P_REP_DATE   DATE,
    P_USER_ID    VARCHAR2,
    P_RAND_VALUE NUMBER,
    P_ERROR_CODE OUT NUMBER,
    P_ERROR_MSG OUT VARCHAR2)
IS
  V_ERROR_CODE NUMBER(5) ;
  V_ERROR_MSG  VARCHAR2(200) ;
  V_ERR        EXCEPTION;
  V_KATEGORI   VARCHAR2(50);
    V_CNT NUMBER;


  BEGIN
  
  ----RETAIL REGULAR/TPLUS
   BEGIN
   INSERT INTO TMP_CASH_FLOW_REAL(KATEGORI,MASUK,keluar,RAND_VALUE,USER_ID)
   SELECT  KATEGORI, SUM(DECODE(SIGN(NET_AMT),-1,ABS(NET_AMT),0))MASUK, SUM(DECODE(SIGN(NET_AMT),1,NET_AMT,0))KELUAR, P_RAND_VALUE, P_USER_ID
    FROM
      (
          SELECT DECODE(CLIENT_TYPE_3,'T','T','R')KATEGORI, M.CLIENT_CD, SUM(DECODE(DB_cR_FLG,'D',CURR_VAL,-CURR_VAL)) NET_AMT
          FROM T_ACCOUNT_LEDGER A
          JOIN MST_CLIENT M
          ON A.SL_ACCT_CD     =M.CLIENT_CD
          WHERE A.APPROVED_STS='A'
          AND M.APPROVED_STAT ='A'
          AND A.DOC_DATE = P_REP_DATE
          AND M.CLIENT_TYPE_1<>'C'
        GROUP BY CLIENT_TYPE_3,M.CLIENT_CD
      )
    GROUP BY KATEGORI;
  EXCEPTION
          WHEN OTHERS THEN
          V_ERROR_CODE :=-23;
          V_ERROR_MSG :=SUBSTR('INSERT INTO TMP_CASH_FLOW_REAL TPLUS/REGULAR '||SQLERRM,1,200);
          RAISE V_ERR;
        END;

   
  --OTHERS
  BEGIN
        INSERT INTO TMP_CASH_FLOW_REAL(KATEGORI,MASUK,keluar,RAND_VALUE,USER_ID)
        SELECT KATEGORI, SUM(DECODE(SIGN(NET_AMT),1,NET_AMT,0))MASUK, SUM(DECODE(SIGN(NET_AMT),-1,ABS(NET_AMT),0))KELUAR, P_RAND_VALUE,P_USER_ID
          FROM
            (
              SELECT KATEGORI,XN_DOC_NUM, SUM(NET_AMT)NET_AMT
              FROM
                (
                  SELECT 'O' KATEGORI,A.XN_DOC_NUM,DECODE(DB_CR_FLG,'C',CURR_VAL,-CURR_VAL)NET_AMT, A.LEDGER_NAR
                  FROM T_ACCOUNT_LEDGER A, (
                      SELECT XN_DOC_NUM, tal_id
                      FROM T_ACCOUNT_LEDGER
                      WHERE DOC_DATE      =P_REP_DATE
                      AND DUE_DATE       =P_REP_DATE
                      AND TRIM(GL_ACCT_CD)='1200'
                      AND REVERSAL_JUR    ='N'
                      AND APPROVED_STS    ='A'
                      AND record_source  <> 'RE'
                    )
                    B, (
                      SELECT jur_type, gl_a
                      FROM MST_GLA_TRX
                      WHERE jur_type IN ( 'ARAP','BROK', 'KPEI')
                    )
                    C, MST_CLIENT M
                  WHERE A.XN_DOC_NUM        =B.XN_DOC_NUM
                  AND TRIM(A.GL_ACCT_CD)    = C.GL_A(+)
                  AND C.GL_A               IS NULL
                  AND A.SL_ACCT_CD          = M.CLIENT_CD(+)
                  AND M.CLIENT_CD          IS NULL
                  AND a.tal_id             <> b.tal_id
                  AND TRIM(GL_ACCT_CD) NOT IN ('1111','2461','1461')
                )
              GROUP BY KATEGORI,XN_DOC_NUM
            )
          GROUP BY KATEGORI;
        EXCEPTION
            WHEN OTHERS THEN
            V_ERROR_CODE :=-40;
            V_ERROR_MSG :=SUBSTR('INSERT INTO TMP_CASH_FLOW_REAL OTHERS '||SQLERRM,1,200);
            RAISE V_ERR;
          END;
  
        
    COMMIT;
    P_ERROR_CODE := 1;
    P_ERROR_MSG  := '';
  EXCEPTION
  WHEN V_ERR THEN
    ROLLBACK;
    P_ERROR_CODE := V_ERROR_CODE;
    P_ERROR_MSG  := V_ERROR_MSG;
  WHEN OTHERS THEN
    ROLLBACK;
    P_ERROR_CODE := - 1;
    P_ERROR_MSG  := SUBSTR(SQLERRM, 1, 200) ;
    RAISE;
  END SP_CASH_FLOW_REAL_ADP;