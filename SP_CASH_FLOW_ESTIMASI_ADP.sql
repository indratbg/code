CREATE OR REPLACE PROCEDURE SP_CASH_FLOW_ESTIMASI_ADP(
    P_DUE_DATE   DATE,
    P_USER_ID    VARCHAR2,
    P_RAND_VALUE NUMBER,
    P_ERROR_CD OUT NUMBER,
    P_ERROR_MSG OUT VARCHAR2)
IS
  V_ERR          EXCEPTION;
  V_ERROR_CODE   NUMBER;
  V_ERROR_MSG    VARCHAR2(200);
  V_BEG_BAL_DATE DATE;
  V_CNT          NUMBER;
  V_KATEGORI     VARCHAR2(20);
BEGIN

      BEGIN
        SELECT COUNT(1)
        INTO V_CNT
        FROM TMP_CASH_FLOW_ESTIMASI
        WHERE RAND_VALUE=P_RAND_VALUE
        AND USER_ID     =P_USER_ID;
      EXCEPTION
      WHEN OTHERS THEN
        V_ERROR_CODE:=-3;
        V_ERROR_MSG :=SUBSTR('SELECT COUNT TMP_CASH_FLOW_ESTIMASI '||SQLERRM,1,200);
        RAISE V_ERR;
      END;
      
      IF V_CNT>0 THEN
        BEGIN
          DELETE
          FROM TMP_CASH_FLOW_ESTIMASI
          WHERE RAND_VALUE=P_RAND_VALUE
          AND USER_ID     =P_USER_ID;
        EXCEPTION
        WHEN OTHERS THEN
          V_ERROR_CODE:=-4;
          V_ERROR_MSG :=SUBSTR('DELETE TMP_CASH_FLOW_ESTIMASI '||SQLERRM,1,200);
          RAISE V_ERR;
        END;
      END IF;
      
      V_BEG_BAL_DATE := P_DUE_DATE-TO_CHAR(P_DUE_DATE,'DD')+1;
      
      BEGIN
        INSERT
        INTO TMP_CASH_FLOW_ESTIMASI
          (
            KATEGORI,MASUK,KELUAR,RAND_VALUE, USER_ID
          )
        SELECT KATEGORI, SUM(DECODE(SIGN(NET_AMT),1,NET_AMT,0))MASUK, SUM(DECODE(SIGN(NET_AMT),-1,ABS(NET_AMT),0))KELUAR, P_RAND_VALUE,P_USER_ID
        FROM
          (
            SELECT kategori, sl_acct_cd, SUM(net_amt)net_amt
            FROM
              (
                SELECT DECODE(CLIENT_TYPE_3,'T','TO','RO')KATEGORI,sl_acct_cd, DECODE(A.DB_CR_FLG,'D',CURR_VAL,-CURR_VAL) NET_AMT
                FROM t_account_ledger a
                JOIN mst_client m
                ON a.SL_ACCT_CD=m.client_cd
                WHERE a.doc_date BETWEEN V_BEG_BAL_DATE AND P_DUE_DATE
                AND DUE_DATE         < P_DUE_DATE
                AND M.CLIENt_TYPE_1 <>'B'
                AND a.approved_sts   = 'A'
                AND M.APPROVED_STAT  ='A'
                AND A.REVERSAL_JUR   ='N'
                AND A.RECORD_SOURCE <>'RE'
                AND M.CUSTODIAN_CD  IS NULL--tidak custodian
                UNION ALL
                SELECT DECODE(CLIENT_TYPE_3,'T','TO','RO')KATEGORI,sl_acct_cd, NVL(b.deb_obal,0)-NVL(b.cre_obal,0) beg_bal
                FROM t_day_trs b
                JOIN MST_CLIENT M
                ON B.SL_ACCT_CD                          =M.CLIENT_CD
                WHERE b.trs_dt                           = V_BEG_BAL_DATE
                AND M.APPROVED_STAT                      ='A'
                AND M.CLIENt_TYPE_1                     <> 'B'
                AND M.CUSTODIAN_CD                      IS NULL--tidak custodian
                AND NVL(b.deb_obal,0)-NVL(b.cre_obal,0) <>0
              )
            GROUP BY kategori,sl_acct_cd
          )
        GROUP BY KATEGORI;
      EXCEPTION
      WHEN OTHERS THEN
        V_ERROR_CODE:=-10;
        V_ERROR_MSG :=SUBSTR('INSERT INTO TMP_CASH_FLOW_ESTIMASI '||SQLERRM,1,200);
        RAISE V_ERR;
      END;
      
      --OTHERS
      BEGIN
        INSERT INTO TMP_CASH_FLOW_ESTIMASI
          (KATEGORI,MASUK,keluar,RAND_VALUE,USER_ID
          )
        SELECT KATEGORI, SUM(DECODE(SIGN(NET_AMT),1,NET_AMT,0))MASUK, SUM(DECODE(SIGN(NET_AMT),-1,ABS(NET_AMT),0))KELUAR, P_RAND_VALUE,P_USER_ID
        FROM
          (
            SELECT KATEGORI,XN_DOC_NUM, SUM(NET_AMT)NET_AMT
            FROM
              (
                SELECT 'O' KATEGORI,A.XN_DOC_NUM,DECODE(DB_CR_FLG,'C',CURR_VAL,-CURR_VAL)NET_AMT
                FROM T_ACCOUNT_LEDGER A, (
                    SELECT XN_DOC_NUM, tal_id
                    FROM T_ACCOUNT_LEDGER
                    WHERE DOC_DATE      =P_DUE_DATE
                    AND DUE_DATE        =P_DUE_DATE
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
        V_ERROR_CODE :=-15;
        V_ERROR_MSG  :=SUBSTR('INSERT INTO TMP_CASH_FLOW_ESTIMASI OTHERS '||SQLERRM,1,200);
        RAISE V_ERR;
      END;
    
      
  COMMIT;
  P_ERROR_CD  :=1;
  P_ERROR_MSG :='';
EXCEPTION
WHEN V_ERR THEN
  ROLLBACK;
  P_ERROR_CD  := V_ERROR_CODE;
  P_ERROR_MSG := V_ERROR_MSG;
WHEN OTHERS THEN
  P_ERROR_CD  :=-1;
  P_ERROR_MSG :=SUBSTR(SQLCODE||' '||SQLERRM,1,200);
  RAISE;
END SP_CASH_FLOW_ESTIMASI_ADP;