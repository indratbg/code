create or replace PROCEDURE SP_CASH_FLOW_REAL(
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
 V_CLIENT_TYPE_3 MST_CLIENT.CLIENT_TYPE_3%TYPE:='%';
    V_CNT NUMBER;


  BEGIN
  ----RETAIL REGULAR/MARGIN/TPLUS/INSTITUSI
   BEGIN
   INSERT INTO TMP_CASH_FLOW_REAL(KATEGORI,MASUK,keluar,RAND_VALUE,USER_ID)
   SELECT B.sub_kategori KATEGORI, 
    DECODE(B.SUB_KATEGORI,'RRBRDN',MASUK,'RMBRDN',MASUK,'TBRDN',MASUK,'IRB',MASUK,0) MASUK, 
    DECODE(B.SUB_KATEGORI,'RRJ',keluar,'RMJ',keluar,'TJ',keluar,'IRJ',keluar,0) keluar, P_RAND_VALUE,P_USER_ID
    FROM
      (select kategori, sum(decode(sign(net_amt),1,net_amt,0))masuk,sum(decode(sign(net_amt),-1,abs(net_amt),0))keluar from (
          SELECT payrec_num,kategori,SUM(net_amt)net_amt
          FROM
            (
              SELECT a.payrec_num,F_GET_CASHFLOW_CATEGORY(B.CLIENT_CD)kategori,B.CLIENT_CD, DECODE(B.DB_CR_FLG,'C',B.PAYREC_AMT,-B.PAYREC_AMT)NET_AMT
              FROM t_payrech a
              JOIN t_payrecd b
              ON a.payrec_num=b.payrec_num
              JOIN MST_CLIENT M
              ON A.CLIENT_CD   =M.CLIENT_CD
              AND B.SL_ACCT_CD =M.CLIENT_CD
              LEFT JOIN
                (
                  SELECT XN_DOC_NUM
                  FROM TEMP_DAILY_CASH_FLOW
                  WHERE RAND_VALUE=P_RAND_VALUE
                  AND USER_ID     =P_USER_ID
                )
                TEMP
              ON A.PAYREC_NUM        = TEMP.XN_DOC_NUM
              WHERE a.APPROVED_STS   ='A'
              AND TEMP.XN_DOC_NUM   IS NULL
              AND B.APPROVED_STS     ='A'
              AND M.APPROVED_STAT    ='A'
              AND M.CLIENT_TYPE_1   <> 'B'
              AND a.client_cd        =b.client_cd
              AND TRIM(A.GL_aCCT_CD) ='1200'
              AND A.PAYREC_DATE      =P_REP_DATE
              AND SUBSTR(B.DOC_REF_NUM,6,1) <> 'O'--08jan2018
              AND A.PAYREC_TYPE IN('PV','RV','PD','RD')
              AND (M.CLIENT_TYPE_3= V_CLIENT_TYPE_3 OR V_CLIENT_TYPE_3 ='%')
            )
          GROUP BY payrec_num,kategori
          )
          group by kategori
      )a, 
      (
        SELECT 'RR' KATEGORI,'RRBRDN' SUB_KATEGORI FROM DUAL
        UNION
        SELECT 'RR' KATEGORI,'RRJ' SUB_KATEGORI FROM DUAL
        UNION
        SELECT 'RM' KATEGORI,'RMBRDN' SUB_KATEGORI FROM DUAL
        UNION
        SELECT 'RM' KATEGORI,'RMJ' SUB_KATEGORI FROM DUAL
        UNION
        SELECT 'T' KATEGORI,'TBRDN' SUB_KATEGORI FROM DUAL
        UNION
        SELECT 'T' KATEGORI,'TJ' SUB_KATEGORI FROM DUAL
        UNION
        SELECT 'IR' KATEGORI,'IRB' SUB_KATEGORI FROM DUAL
        UNION
        SELECT 'IR' KATEGORI,'IRJ' SUB_KATEGORI FROM DUAL
      )B
    WHERE A.KATEGORI=B.KATEGORI;
    EXCEPTION
      WHEN OTHERS THEN
      V_ERROR_CODE :=-10;
      V_ERROR_MSG :=SUBSTR('INSERT INTO TMP_CASH_FLOW_REAL'||SQLERRM,1,200);
      RAISE V_ERR;
    END;
  
  --BROKER
    BEGIN
    INSERT INTO TMP_CASH_FLOW_REAL(KATEGORI,MASUK,keluar,RAND_VALUE,USER_ID)
   SELECT b.sub_kategori kategori, DECODE(sub_kategori,'BJ',MASUK,0)MASUK, DECODE(sub_kategori,'BB',KELUAR,0)KELUAR, P_RAND_VALUE,P_USER_ID
      FROM
        (
          SELECT kategori, SUM(DECODE(SIGN(net_amt),1,net_amt,0))masuk, SUM(DECODE(SIGN(net_amt),-1,ABS(net_amt),0))keluar
          FROM
            (
              SELECT kategori, payrec_num, SUM(net_amt)net_amt
              FROM
                (
                  SELECT 'B' KATEGORI,a.payrec_num, DECODE(b.db_cr_flg,'C',B.PAYREC_AMT,-B.PAYREC_AMT)NET_AMT
                  FROM t_payrech a
                  JOIN t_payrecd b
                  ON a.payrec_num=b.payrec_num
                  JOIN
                    (
                      SELECT CLIENT_CD
                      FROM MST_CLIENT
                      WHERE APPROVED_STAT='A'
                      AND CLIENT_TYPE_1  ='B'
                      UNION
                      SELECT BROKER_CD FROM MST_BROKER
                    )
                    M
                  ON A.CLIENT_CD         =M.CLIENT_CD
                  AND B.CLIENT_cD        =M.CLIENT_CD
                  WHERE a.APPROVED_STS   ='A'
                  AND B.APPROVED_STS     ='A'
                  AND a.client_cd        =b.client_cd
                  AND TRIM(A.GL_aCCT_CD) ='1200'
                  AND A.PAYREC_DATE      =P_REP_DATE
                  AND A.PAYREC_TYPE IN('PV','RV')
                )
              GROUP BY kategori,payrec_num
            )
          GROUP BY kategori
        )
        a, (
          SELECT 'B' KATEGORI, 'BJ' SUB_KATEGORI FROM DUAL
          UNION ALL
          SELECT 'B' KATEGORI, 'BB' SUB_KATEGORI FROM DUAL
        )
        B
      WHERE a.kategori=b.kategori;
    EXCEPTION
      WHEN OTHERS THEN
      V_ERROR_CODE :=-20;
      V_ERROR_MSG :=SUBSTR('INSERT INTO TMP_CASH_FLOW_REAL BOKER/NEGO '||SQLERRM,1,200);
      RAISE V_ERR;
    END;

    --KPEI
    BEGIN
    INSERT INTO TMP_CASH_FLOW_REAL(KATEGORI,MASUK,keluar,RAND_VALUE,USER_ID)
     SELECT SUB_KATEGORI KATEGORI, DECODE(SUB_KATEGORI,'KJ',MASUK,0)MASUK, DECODE(SUB_KATEGORI,'KB',KELUAR,0)KELUAR, P_RAND_VALUE,P_USER_ID
      FROM
        (
          SELECT KATEGORI, SUM(DECODE(SIGN(NET_AMT),1,NET_AMT,0))MASUK, SUM(DECODE(SIGN(NET_AMT),-1,ABS(NET_AMT),0))KELUAR
          FROM
            (
              SELECT KATEGORI, PAYREC_NUM, SUM(NET_AMT)NET_AMT
              FROM
                (
                  SELECT 'K' KATEGORI,A.PAYREC_NUM,DECODE(B.DB_CR_FLG,'D',-B.PAYREC_AMT,B.PAYREC_AMT)NET_AMT
                  FROM t_payrech a
                  JOIN t_payrecd b
                  ON a.payrec_num                    =b.payrec_num
                  WHERE a.APPROVED_STS               ='A'
                  AND B.APPROVED_STS                 ='A'
                  AND a.client_cd                    =b.client_cd
                  AND TRIM(A.GL_aCCT_CD)             ='1200'
                  AND A.PAYREC_DATE                  =P_REP_DATE
                  AND SUBSTR(B.DOC_REF_NUM,5,2) NOT IN ('BO','JO')
                  AND A.PAYREC_TYPE                 IN('PV','RV')
                  AND A.ACCT_TYPE                    ='KPEI'
                )
              GROUP BY KATEGORI,PAYREC_NUM
            )
          GROUP BY KATEGORI
        )
        A, (
          SELECT 'K' KATEGORI, 'KJ' SUB_KATEGORI FROM DUAL
          UNION ALL
          SELECT 'K' KATEGORI, 'KB' SUB_KATEGORI FROM DUAL
        )
        B
      WHERE A.KATEGORI=B.KATEGORI;
      EXCEPTION
        WHEN OTHERS THEN
        V_ERROR_CODE :=-30;
        V_ERROR_MSG :=SUBSTR('INSERT INTO TMP_CASH_FLOW_REAL KPEI '||SQLERRM,1,200);
        RAISE V_ERR;
      END;

      --FIXED INCOME
       BEGIN
        INSERT INTO TMP_CASH_FLOW_REAL(KATEGORI,MASUK,keluar,RAND_VALUE,USER_ID)
          SELECT B.SUB_KATEGORI KATEGORI, DECODE(SUB_KATEGORI,'FJ',MASUK,0)MASUK, DECODE(SUB_KATEGORI,'FB',KELUAR,0)KELUAR,
            P_RAND_VALUE,P_USER_ID
          FROM
            (
              SELECT kategori, SUM(DECODE(SIGN(NET_AMT),1,NET_AMT,0))MASUK, SUM(DECODE(SIGN(NET_AMT),-1,ABS(NET_AMT),0))KELUAR
              FROM
                (
                  SELECT 'F' KATEGORI,rvpv_number, SUM(DECODE(TRX_TYPE,'S',NET_AMOUNT,-NET_AMOUNT))NET_AMT
                  FROM T_BOND_TRX
                  WHERE VALUE_DT              =P_REP_DATE
                  AND APPROVED_STS            ='A'
                  AND T_BOND_TRX.lawan_type  <> 'I'
                  AND NVL(journal_status,'X') = 'A'
                  AND RVPV_NUMBER            IS NOT NULL
                  GROUP BY rvpv_number
                  UNION
                  SELECT 'F' KATEGORI,payrec_num,SUM(DECODE(db_Cr_flg,'C',PAYREC_AMT,-PAYREC_AMT))NET_AMT
                  FROM t_payrecd A, MST_CLIENT M
                  WHERE payrec_date            = P_REP_DATE
                  AND payrec_type             IN ('RV','PV')
                  AND SUBSTR(doc_ref_num ,6,1) = 'O'
                  AND A.approved_sts           = 'A'
                  AND M.APPROVED_STAT          ='A'
                  AND M.CLIENT_TYPE_1         <>'B'
                  AND A.CLIENT_CD              = M.CLIENT_CD
                  GROUP BY payrec_num
                )
              GROUP BY KATEGORI
            )
            A, (
              SELECT 'F' KATEGORI, 'FJ' SUB_KATEGORI FROM DUAL
              UNION ALL
              SELECT 'F' KATEGORI, 'FB' SUB_KATEGORI FROM DUAL
            )
            B
          WHERE A.KATEGORI = B.KATEGORI; 
         EXCEPTION
            WHEN OTHERS THEN
            V_ERROR_CODE :=-40;
            V_ERROR_MSG :=SUBSTR('INSERT INTO TMP_CASH_FLOW_REAL FIXED INCOME '||SQLERRM,1,200);
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
                  SELECT 'O' KATEGORI,A.XN_DOC_NUM,DECODE(DB_CR_FLG,'C',CURR_VAL,-CURR_VAL)NET_AMT
                  FROM T_ACCOUNT_LEDGER A, (
                      SELECT XN_DOC_NUM, tal_id
                      FROM T_ACCOUNT_LEDGER
                      WHERE DOC_DATE      =P_REP_DATE
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
  END SP_CASH_FLOW_REAL;