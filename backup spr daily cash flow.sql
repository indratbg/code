create or replace PROCEDURE SPR_DAILY_CASH_FLOW(
    P_REP_DATE      DATE,
    P_USER_ID       VARCHAR2,
    P_GENERATE_DATE DATE,
    P_RAND_VALUE OUT NUMBER,
    P_ERROR_CODE OUT NUMBER,
    P_ERROR_MSG OUT VARCHAR2)
IS
  V_ERROR_CODE      NUMBER(5);
  V_ERROR_MSG       VARCHAR2(200);
  V_ERR             EXCEPTION;
  V_RANDOM_VALUE    NUMBER(10);
  V_BGN_BAL         DATE;
  V_BEG_BAL         NUMBER;
  V_DDMMYYYY        VARCHAR2(8);
  V_RUNNING_BALANCE NUMBER;
  CURSOR CSR_DATA
  IS
    SELECT B.kategori,B.DESCRIPTION, NVL(DEB_AMT,0)deb_amt, NVL(CRE_AMT,0)cre_amt, B.SESI_DEBIT,B.SESI_CREDIT, B.ORDER_NO
    FROM
      (
        SELECT KATEGORI, SUM(deb_amt) deb_amt, SUM(cre_amt) cre_amt
        FROM
          (
            SELECT a.xn_doc_num, a.doc_date, DECODE(a.db_cr_flg,'C', 1, 0) * a.curr_val AS deb_amt, DECODE(a.db_cr_flg,'D', 1, 0) * a.curr_val AS cre_amt, DECODE(m.client_cd,NULL,p.client_cd, m.kategori) AS kategori
            FROM
              (
                SELECT h.payrec_num, DECODE(TRIM(T.GL_ACCT_CD),'1201','D',h.client_cd)CLIENT_CD, T.GL_ACCT_CD
                FROM t_account_ledger t, (
                    SELECT payrec_num, DECODE(sl_acct_cd,'300030','F',DECODE(acct_type,'NEGO','B',DECODE(client_cd,'KPEI','K','O'))) client_cd
                    FROM t_payrech
                    WHERE payrec_date =P_REP_DATE
                    AND approved_sts  = 'A'
                  )
                h, TEMP_DAILY_CASH_FLOW TEMP
              WHERE t.doc_date     =P_REP_DATE
              AND t.gl_acct_cd    IN ( '1200','1201')
              AND t.approved_sts   = 'A'
              AND t.reversal_jur   = 'N'
              AND t.record_source <> 'RE'
              AND t.xn_doc_num     = h.payrec_num
              AND T.XN_DOC_NUM     = TEMP.XN_DOC_NUM(+)
              AND TEMP.XN_DOC_NUM IS NULL
              )
              p, t_account_ledger a, (
                SELECT client_cd, F_GET_CLIENT_TYPE_DESC(MST_CLIENT.CLIENT_CD) kategori
                FROM mst_client, v_broker_subrek
                WHERE client_cd <> broker_client_cd
              )
              m
            WHERE p.payrec_num = a.xn_doc_num
            AND a.gl_acct_cd  <> P.GL_ACCT_CD
            AND a.sl_acct_cd   = m.client_cd(+)
          )
        GROUP BY kategori
        HAVING SUM(DEB_AMT)<>0
        OR SUM(CRE_AMT)    <>0
      )
      A, T_CASH_FLOW_KATEGORI B
    WHERE A.KATEGORI(+)=B.KATEGORI
    ORDER BY B.ORDER_NO;
    
    CURSOR CSR_TEMP
    IS
      SELECT a.xn_doc_num, b.payrec_num
      FROM
        (
          SELECT xn_doc_num, t_account_ledger.doc_date, client_cd, curr_val
          FROM t_account_ledger, t_payrech
          WHERE doc_date                        = P_REP_DATE
          AND TRIM(t_account_ledger.gl_acct_cd) = '1200'
          AND record_source                     = 'PD'
          AND xn_doc_num                        = payrec_num
          AND client_cd                        IS NOT NULL
          AND trim(t_payrech.acct_type)         = 'RDM'
        )
      a, (
        SELECT payrec_num,t_account_ledger.doc_date, client_cd, curr_val
        FROM t_account_ledger, t_payrech
        WHERE doc_date                        = P_REP_DATE
        AND TRIM(t_account_ledger.gl_acct_cd) = '1200'
          --and sl_acct_cd = 'ADIS003R'
        AND record_source             = 'RV'
        AND xn_doc_num                = payrec_num
        AND client_cd                IS NOT NULL
        AND trim(t_payrech.acct_type) = 'RDI'
      )
      b
    WHERE a.doc_date = b.doc_date
    AND a.client_cd  = b.client_cd
    AND a.curr_val   = b.curr_val;
    V_DEBIT  NUMBER;
    V_CREDIT NUMBER;
    CURSOR CSR_UPD_BAL
    IS
      SELECT T.ROWID,T.*
      FROM R_DAILY_CASH_FLOW T
      WHERE RAND_VALUE=V_RANDOM_VALUE
      AND USER_ID     =P_USER_ID
      ORDER BY SESI,SORTK;
  BEGIN
  
    V_RANDOM_VALUE := ABS(DBMS_RANDOM.RANDOM);
    BEGIN
      SP_RPT_REMOVE_RAND('R_DAILY_CASH_FLOW',V_RANDOM_VALUE,V_ERROR_MSG,V_ERROR_CODE);
    EXCEPTION
    WHEN OTHERS THEN
      V_ERROR_CODE := -10;
      V_ERROR_MSG  := SUBSTR('SP_RPT_REMOVE_RAND '||V_ERROR_MSG||SQLERRM(SQLCODE),1,200);
      RAISE V_err;
    END;
    
    IF V_ERROR_CODE <0 THEN
      V_ERROR_CODE := -20;
      V_ERROR_MSG  := SUBSTR('SP_RPT_REMOVE_RAND'||V_ERROR_MSG,1,200);
      RAISE V_ERR;
    END IF;
    
    V_BGN_BAL  :=TO_DATE('01'||TO_CHAR(P_REP_DATE,'MMYYYY'),'DDMMYYYY');
    V_DDMMYYYY := TO_CHAR( p_rep_date,'ddmmyyyy');
    
    --GET BEGINNING BALANCE
    BEGIN
      SELECT SUM(NVL(beg_bal,0))
      INTO V_BEG_BAL
      FROM
        (
          SELECT SUM(NVL(b.deb_obal,0) - NVL(b.cre_obal,0)) beg_bal
          FROM t_day_trs b
          WHERE b.trs_dt         = V_BGN_BAL
          AND trim(b.gl_acct_cd)IN ( '1200','1201')
          UNION ALL
          SELECT (DECODE(d.db_cr_flg,'D',1,-1) * NVL(d.curr_val,0)) mvmt
          FROM t_account_ledger d
          WHERE d.doc_date BETWEEN V_BGN_BAL AND (P_REP_DATE - 1)
          AND trim(d.gl_acct_cd)                            IN ( '1200','1201')
          AND d.approved_sts      = 'A'
        );
    EXCEPTION
    WHEN OTHERS THEN
      V_ERROR_CODE := -10;
      V_ERROR_MSG  := SUBSTR('SELECT BEGINNING BALANCE YESTERDAY '||SQLERRM(SQLCODE),1,200);
      RAISE V_err;
    END;
    
    BEGIN
      INSERT INTO TEMP_DAILY_CASH_FLOW
        (XN_DOC_NUM, RAND_VALUE,USER_ID
        )
      SELECT DISTINCT XN_DOC_NUM, V_RANDOM_VALUE,P_USER_ID
      FROM t_account_ledger
      WHERE doc_date      =P_REP_DATE
      AND approved_sts    ='A'
      AND trim(gl_acct_cd)='1111'
      AND reversal_jur    ='N'
      AND RECORD_SOURCE  <>'RE';
    EXCEPTION
    WHEN OTHERS THEN
      V_ERROR_CODE := -12;
      V_ERROR_MSG  := SUBSTR('SELECT DOC_NUM T_ACCOUNT_LEDGER '||SQLERRM(SQLCODE),1,200);
      RAISE V_err;
    END;
    
    FOR REC IN CSR_TEMP
    LOOP
    
      BEGIN
        INSERT
        INTO TEMP_DAILY_CASH_FLOW
          (
            XN_DOC_NUM, RAND_VALUE,USER_ID
          )
          VALUES
          (
            REC.XN_DOC_NUM, V_RANDOM_VALUE,P_USER_ID
          );
      EXCEPTION
      WHEN OTHERS THEN
        V_ERROR_CODE := -13;
        V_ERROR_MSG  := SUBSTR('INSERT DOC_NUM T_ACCOUNT_LEDGER '||SQLERRM(SQLCODE),1,200);
        RAISE V_err;
      END;
      
      BEGIN
        INSERT
        INTO TEMP_DAILY_CASH_FLOW
          (
            XN_DOC_NUM, RAND_VALUE,USER_ID
          )
          VALUES
          (
            REC.PAYREC_NUM, V_RANDOM_VALUE,P_USER_ID
          );
      EXCEPTION
      WHEN OTHERS THEN
        V_ERROR_CODE := -14;
        V_ERROR_MSG  := SUBSTR('INSERT DOC_NUM T_ACCOUNT_LEDGER '||SQLERRM(SQLCODE),1,200);
        RAISE V_err;
      END;
    END LOOP;
    
    V_RUNNING_BALANCE :=V_BEG_BAL;
    FOR REC IN CSR_DATA
    LOOP
    
      IF REC.SESI_DEBIT=1 THEN
        V_DEBIT       :=REC.DEB_AMT;
      ELSE
        V_DEBIT:=0;
      END IF;
      IF REC.SESI_CREDIT=1 THEN
        V_CREDIT       :=REC.CRE_AMT;
      ELSE
        V_CREDIT :=0;
      END IF;
      
      --SESI 1
      BEGIN
        INSERT
        INTO R_DAILY_CASH_FLOW
          (
            SESI,DESCRIPTION, BEG_BAL, DEBIT, CREDIT, RUNNING_BALANCE, RAND_VALUE, USER_ID, GENERATE_DATE,SORTK
          )
          VALUES
          (
            1,REC.DESCRIPTION, V_BEG_BAL, V_DEBIT, V_CREDIT,V_RUNNING_BALANCE ,V_RANDOM_VALUE,P_USER_ID,P_GENERATE_DATE,REC.ORDER_NO
          );
      EXCEPTION
      WHEN OTHERS THEN
        V_ERROR_CODE := -30;
        V_ERROR_MSG  := SUBSTR('INSERT INTO R_DAILY_CASH_FLOW '||SQLERRM(SQLCODE),1,200);
        RAISE V_err;
      END;
      
      IF REC.SESI_DEBIT=2 THEN
        V_DEBIT       :=REC.DEB_AMT;
      ELSE
        V_DEBIT:=0;
      END IF;
      IF REC.SESI_CREDIT=2 THEN
        V_CREDIT       :=REC.CRE_AMT;
      ELSE
        V_CREDIT :=0;
      END IF;
      
      --SESI 2
      BEGIN
        INSERT
        INTO R_DAILY_CASH_FLOW
          (
            SESI,DESCRIPTION, BEG_BAL, DEBIT, CREDIT, RUNNING_BALANCE, RAND_VALUE, USER_ID, GENERATE_DATE,SORTK
          )
          VALUES
          (
            2,REC.DESCRIPTION, V_BEG_BAL, V_DEBIT, V_CREDIT,V_RUNNING_BALANCE ,V_RANDOM_VALUE,P_USER_ID,P_GENERATE_DATE,REC.ORDER_NO
          );
      EXCEPTION
      WHEN OTHERS THEN
        V_ERROR_CODE := -40;
        V_ERROR_MSG  := SUBSTR('INSERT INTO R_DAILY_CASH_FLOW '||SQLERRM(SQLCODE),1,200);
        RAISE V_err;
      END;
    END LOOP;
    
    FOR REC IN CSR_UPD_BAL
    LOOP
      V_RUNNING_BALANCE := V_RUNNING_BALANCE +  ( REC.DEBIT-REC.CREDIT);
      BEGIN
        UPDATE R_DAILY_CASH_FLOW
        SET RUNNING_BALANCE = V_RUNNING_BALANCE
        WHERE ROWID         =REC.ROWID;
      EXCEPTION
      WHEN OTHERS THEN
        V_ERROR_CODE := -50;
        V_ERROR_MSG  := SUBSTR('INSERT INTO R_DAILY_CASH_FLOW '||SQLERRM(SQLCODE),1,200);
        RAISE V_err;
      END;
    END LOOP;
    
    BEGIN
      DELETE
      FROM TEMP_DAILY_CASH_FLOW
      WHERE RAND_VALUE=V_RANDOM_VALUE
      AND USER_ID     =P_USER_ID;
    EXCEPTION
    WHEN OTHERS THEN
      V_ERROR_CODE := -60;
      V_ERROR_MSG  := SUBSTR('DELETE  TMP_DAILY_CASH_FLOW WHERE '||V_RANDOM_VALUE||' '||SQLERRM(SQLCODE),1,200);
      RAISE V_err;
    END;
    
    COMMIT;
    
    P_ERROR_CODE :=1;
    P_ERROR_MSG  :='';
    P_RAND_VALUE :=V_RANDOM_VALUE;
  EXCEPTION
  WHEN V_ERR THEN
    ROLLBACK;
    P_ERROR_CODE :=V_ERROR_CODE;
    P_ERROR_MSG  :=V_ERROR_MSG;
  WHEN OTHERS THEN
    ROLLBACK;
    P_ERROR_CODE:=-1;
    P_ERROR_MSG :=SUBSTR(SQLERRM,1,200);
    RAISE;
  END SPR_DAILY_CASH_FLOW;