create or replace PROCEDURE SP_CASH_FLOW_ESTIMASI(
    P_DUE_DATE   DATE,
    P_USER_ID    VARCHAR2,
    P_RAND_VALUE NUMBER,
    P_ERROR_CD OUT NUMBER,
    P_ERROR_MSG OUT VARCHAR2)
IS
  V_ERR          EXCEPTION;
  V_ERROR_CODE   NUMBER;
  V_ERROR_MSG    VARCHAR2(200);
  V_TRX_DATE     DATE;
  V_BEG_BAL_DATE DATE;
  V_CNT          NUMBER;
  V_CLIENT_TYPE_3 MST_CLIENT.CLIENT_TYPE_3%TYPE :='%';
  V_KATEGORI VARCHAR2(20);
  
  CURSOR CSR_RETAIL
  IS
   SELECT KATEGORI, SUM(DECODE(SIGN(AMT),1,DECODE(SIGN(AMT-SALDO_RDI),-1,AMT,SALDO_RDI ),0)) EST_RDI,
    SUM(DECODE(SIGN(AMT),1,DECODE(SIGN(AMT-SALDO_RDI),-1,0,(AMT-SALDO_RDI) ),0)) EST_NASABAH, SUM(decode(SIGN(AMT),-1,ABS(AMT),0))KELUAR
    FROM
      (
        SELECT KATEGORI,CLIENT_CD,SUM(AMT)AMT,NVL(F_FUND_BAL(CLIENT_CD,P_DUE_DATE),0)SALDO_RDI
        FROM
          (
            SELECT F_GET_CASHFLOW_CATEGORY(T.client_cd)kategori,T.CLIENT_CD,
            SUM(DECODE(SUBSTR(CONTR_NUM,5,1),'B',amt_for_curr,-amt_for_curr))AMT
            FROM T_CONTRACTS T
            JOIN MST_CLIENT M
            ON T.CLIENT_CD       =M.CLIENT_CD
            WHERE CONTR_DT      >= V_TRX_DATE
            AND due_dt_for_amt   =P_DUE_DATE
            AND M.APPROVED_STAT  ='A'
            AND M.CLIENt_TYPE_1 <> 'B'
            AND CONTR_STAT      <>'C'
            AND M.CUSTODIAN_CD IS NULL--tidak custodian
            GROUP BY T.CLIENT_CD
          --BIAYA BIAYA
          UNION ALL
           SELECT F_GET_CASHFLOW_CATEGORY(T.CLIENT_CD) KATEGORI,T.CLIENT_CD,NET_AMT
          FROM TMP_CASH_FLOW_BIAYA T
          JOIN MST_CLIENT M
          ON T.CLIENT_CD=M.CLIENT_CD
          WHERE RAND_VALUE=P_RAND_VALUE 
          AND M.CUSTODIAN_CD IS NULL
          AND T.USER_ID=P_USER_ID
          --OUTSTANDING AR/AP (UTANG/PIUTANG) NASABAH
          UNION ALL
           SELECT F_GET_CASHFLOW_CATEGORY(SL_ACCT_CD) KATEGORI,SL_ACCT_CD,NET_AMT
          FROM TMP_CASH_FLOW_OUTS T
          JOIN MST_CLIENT M
          ON T.SL_ACCT_CD=M.CLIENT_CD
          WHERE RAND_VALUE=P_RAND_VALUE 
          AND M.CUSTODIAN_CD IS NULL
          AND T.USER_ID=P_USER_ID
          )
        GROUP BY KATEGORI,CLIENT_CD
      )
    GROUP BY KATEGORI;
    
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
    
    V_TRX_DATE     := GET_DOC_DATE(3,P_DUE_DATE);
    V_BEG_BAL_DATE := GET_DOC_DATE(3,P_DUE_DATE);
    V_BEG_BAL_DATE := V_BEG_BAL_DATE - TO_CHAR(V_BEG_BAL_DATE,'DD')+1;
    
    --BROKER DAN KPEI
    BEGIN
      INSERT INTO TMP_CASH_FLOW_ESTIMASI
        (KATEGORI,MASUK,KELUAR, RAND_VALUE, USER_ID
        )
      --PROYEKSI NEGO/BROKER JUAL BELI
      SELECT B.SUB_KATEGORI , DECODE(SUB_KATEGORI,'BJ',DECODE(SIGN(NET_AMT),1,NET_AMT,0),0) MASUK, DECODE(SUB_KATEGORI,'BB',DECODE(SIGN(NET_AMT),-1,ABS(NET_AMT),0),0) KELUAR, P_RAND_VALUE,P_USER_ID
      FROM
        (
          SELECT 'B' KATEGORI, SUM(DECODE(SUBSTR(CONTR_NUM,5,1),'B', -NET, NET))NET_AMT
          FROM t_contracts
          WHERE CONTR_DT  >= V_TRX_DATE
          AND due_dt_for_amt =P_DUE_DATE
          AND mrkt_type ='NG'
          AND CONTR_STAT <> 'C'
          AND APPROVED_STAT ='A'
          AND DECODE(SUBSTR(CONTR_NUM,5,1),'J',trim(SELL_BROKER_CD),trim(BUY_BROKER_CD) ) = 'YJ'
        )
        A, (
          SELECT 'B' KATEGORI,'BB' SUB_KATEGORI FROM DUAL
          UNION
          SELECT 'B' KATEGORI,'BJ' SUB_KATEGORI FROM DUAL
        ) B
      WHERE A.KATEGORI=B.KATEGORI
      UNION ALL
      --PROYEKSI KPEI BELI/JUAL
      SELECT SUB_KATEGORI KATEGORI, DECODE(B.SUB_KATEGORI,'KJ',SUM(DECODE(SIGN(NET_AMT),1,NET_AMT,0)),0)MASUK, DECODE(B.SUB_KATEGORI,'KB',SUM(DECODE(SIGN(NET_AMT),-1,ABS(NET_AMT),0)),0)KELUAR, P_RAND_VALUE,P_USER_ID
      FROM
        (
          SELECT 'K' AS KATEGORI,DOC_DATE,DUE_DATE, SUM(DECODE(DB_CR_FLG,'D',1,-1)*CURR_VAL) NET_AMT
          FROM T_ACCOUNT_LEDGER T
          JOIN MST_GLA_TRX G
          ON TRIM(T.GL_ACCT_CD) = G.GL_A
          WHERE T.DOC_DATE BETWEEN V_TRX_DATE AND P_DUE_DATE
          AND T.DUE_DATE = P_DUE_DATE
          AND G.JUR_TYPE       ='KPEI'
          AND T.SL_ACCT_CD     ='KPEI'
          AND T.RECORD_SOURCE IN ('CG','GL')
          AND T.APPROVED_STS   = 'A'
          AND T.REVERSAL_JUR   = 'N'
          GROUP BY DOC_DATE,DUE_DATE
        )
        A, (
          SELECT 'K' KATEGORI,'KB' SUB_KATEGORI FROM DUAL
          UNION
          SELECT 'K' KATEGORI,'KJ' SUB_KATEGORI FROM DUAL
        ) B
      WHERE A.KATEGORI=B.KATEGORI
      GROUP BY B.SUB_KATEGORI;
    EXCEPTION
    WHEN OTHERS THEN
      V_ERROR_CODE:=-10;
      V_ERROR_MSG :=SUBSTR('INSERT INTO TMP_CASH_FLOW_ESTIMASI KPEI/BROKER '||SQLERRM,1,200);
      RAISE V_ERR;
    END;
    --19FEB2018 SQL BIAYA RETAIL DAN INSTITUSI DIGABUNG
    BEGIN
    INSERT INTO TMP_CASH_FLOW_BIAYA(CLIENT_CD,NET_AMT,RAND_VALUE,USER_ID)
    SELECT  A.SL_ACCT_CD, SUM(DECODE(DB_CR_FLG,'D',CURR_VAL,-CURR_VAL))NET_AMT,P_RAND_VALUE,P_USER_ID
    FROM T_ACCOUNT_LEDGER A, MST_CLIENT M, (
    SELECT XN_DOC_NUM
    FROM TEMP_DAILY_CASH_FLOW
    WHERE RAND_VALUE=P_RAND_VALUE
    AND USER_ID     =P_USER_ID
    )
    TEMP,
    (SELECT GL_A FROM MST_GLA_TRX WHERE JUR_TYPE='REPO')G
    WHERE A.SL_ACCT_CD          =M.CLIENT_CD
    AND A.XN_DOC_NUM            = TEMP.XN_DOC_NUM(+)
    AND TEMP.XN_DOC_NUM        IS NULL
    AND A.APPROVED_STS          ='A'
    AND M.APPROVED_STAT         ='A'
    AND A.REVERSAL_JUR          ='N'
    AND M.CLIENt_TYPE_1        <> 'B'
    AND DOC_DATE                = P_DUE_DATE
    AND TRIM(A.GL_aCCT_CD) = G.GL_A(+)
    AND G.GL_A IS NULL
    and a.record_source <> 'RE'
    AND RECORD_SOURCE          IN ('GL', 'PD', 'RD', 'RVO', 'PVO','INT','DNCN')
    GROUP BY A.DUE_DATE, A.SL_ACCT_CD;
   EXCEPTION
    WHEN OTHERS THEN
      V_ERROR_CODE:=-13;
      V_ERROR_MSG :=SUBSTR('INSERT INTO TMP_CASH_FLOW_ESTIMASI KPEI/BROKER '||SQLERRM,1,200);
      RAISE V_ERR;
    END;
    
    --19feb2018 gabung untuk sql outstanding retail dan institusi
    BEGIN
    INSERT INTO TMP_CASH_FLOW_OUTS(SL_ACCT_CD,NET_AMT,RAND_VALUE,USER_ID)
    select sl_Acct_cd,sum(net_amt)net_amt,P_RAND_VALUE,P_USER_ID from
    (
    SELECT SL_ACCT_CD, DECODE(A.DB_CR_FLG,'D',CURR_VAL,-CURR_VAL) NET_AMT
      FROM T_ACCOUNT_LEDGER A, MST_CLIENT M, (
          SELECT GL_A FROM MST_GLA_TRX WHERE JUR_TYPE='REPO'
        ) G
      WHERE A.SL_ACCT_CD=M.CLIENT_CD
      AND A.DOC_DATE BETWEEN V_BEG_BAL_DATE AND P_DUE_DATE
      AND DUE_DATE          < P_DUE_DATE
      AND M.CLIENT_TYPE_1  <>'B'
      AND A.APPROVED_STS    = 'A'
      AND M.APPROVED_STAT   ='A'
      AND A.REVERSAL_JUR    ='N'
      AND A.RECORD_SOURCE  <>'RE'
      AND TRIM(A.GL_ACCT_CD)=G.GL_A(+)
      AND G.GL_A           IS NULL
      UNION ALL
      SELECT SL_ACCT_CD, NVL(B.DEB_OBAL,0)-NVL(B.CRE_OBAL,0) BEG_BAL
      FROM T_DAY_TRS B, MST_CLIENT M, (
          SELECT GL_A FROM MST_GLA_TRX WHERE JUR_TYPE='REPO'
        )G
      WHERE B.SL_ACCT_CD                       =M.CLIENT_CD
      AND TRIM(B.GL_ACCT_CD)                   = G.GL_A(+)
      AND G.GL_A                              IS NULL
      AND B.TRS_DT                             = V_BEG_BAL_DATE
      AND M.APPROVED_STAT                      ='A'
      AND M.CLIENT_TYPE_1                     <> 'B'
      AND NVL(B.DEB_OBAL,0)-NVL(B.CRE_OBAL,0) <>0
      )
      group by sl_acct_cd; 
    EXCEPTION
    WHEN OTHERS THEN
      V_ERROR_CODE:=-14;
      V_ERROR_MSG :=SUBSTR('INSERT INTO TMP_CASH_FLOW_ESTIMASI KPEI/BROKER '||SQLERRM,1,200);
      RAISE V_ERR;
    END;
    
    --institusi
    BEGIN
    INSERT INTO TMP_CASH_FLOW_ESTIMASI(KATEGORI,MASUK,KELUAR,RAND_VALUE,USER_ID)
    SELECT B.SUB_KATEGORI KATEGORI,DECODE(B.SUB_KATEGORI,'IRB',MASUK,0)MASUK,DECODE(B.SUB_KATEGORI,'IRJ',KELUAR,0)KELUAR,
    P_RAND_VALUE,P_USER_ID
    FROM
      (
      SELECT KATEGORI,SUM(DECODE(SIGN(NET_AMT),1,NET_AMT,0))MASUK,SUM(DECODE(SIGN(NET_AMT),-1,ABS(NET_AMT),0))KELUAR
      FROM
        (
          SELECT 'IR' KATEGORI,T.CLIENT_CD, SUM(DECODE(SUBSTR(CONTR_NUM,5,1),'B',amt_for_curr,-amt_for_curr)) NET_AMT
          FROM T_CONTRACTS T
          JOIN MST_CLIENT M
          ON T.CLIENT_CD                          =M.CLIENT_CD
          WHERE CONTR_DT                         >= V_TRX_DATE
          AND due_dt_for_amt                      =P_DUE_DATE
          AND M.APPROVED_STAT                     ='A'
          AND M.CLIENt_TYPE_1                    <> 'B'
          AND CONTR_STAT                         <>'C'
          AND M.CUSTODIAN_CD IS NOT NULL
          AND CLIENT_TYPE_3<>'M'
          GROUP BY T.DUE_DT_FOR_AMT,T.CLIENT_CD
          --BIAYA BIAYA
          UNION ALL
            SELECT 'IR' KATEGORI,T.CLIENT_CD,NET_AMT
          FROM TMP_CASH_FLOW_BIAYA T
          JOIN MST_CLIENT M
          ON T.CLIENT_CD=M.CLIENT_CD
          WHERE RAND_VALUE=P_RAND_VALUE 
          AND M.CUSTODIAN_CD IS NOT NULL
          AND T.USER_ID=P_USER_ID
          --OUTSTANDING
          UNION ALL
          SELECT 'IR' KATEGORI,SL_ACCT_CD,NET_AMT
          FROM TMP_CASH_FLOW_OUTS T
          JOIN MST_CLIENT M
          ON T.SL_ACCT_CD=M.CLIENT_CD
          WHERE RAND_VALUE=P_RAND_VALUE 
          AND M.CUSTODIAN_CD IS NOT NULL
          AND T.USER_ID=P_USER_ID
        )
        GROUP BY KATEGORI
        )A,
        (SELECT 'IR' KATEGORI,'IRB' SUB_KATEGORI FROM DUAL
        UNION 
        SELECT 'IR' KATEGORI,'IRJ' SUB_KATEGORI FROM DUAL
        )B
        WHERE A.KATEGORI=B.KATEGORI;
     EXCEPTION
    WHEN OTHERS THEN
      V_ERROR_CODE:=-10;
      V_ERROR_MSG :=SUBSTR('INSERT INTO TMP_CASH_FLOW_ESTIMASI KPEI/BROKER '||SQLERRM,1,200);
      RAISE V_ERR;
    END;
    
    
    FOR REC IN CSR_RETAIL
    LOOP
    
            IF REC.KATEGORI    ='RR' THEN
              V_KATEGORI      :='RRBRDN';
            ELSIF REC.KATEGORI ='RM' THEN
              V_KATEGORI      :='RMBRDN';
            ELSIF REC.KATEGORI ='T' THEN
              V_KATEGORI      :='TBRDN';
            END IF;
            
            BEGIN
              INSERT
              INTO TMP_CASH_FLOW_ESTIMASI
                (
                  KATEGORI,MASUK,KELUAR,RAND_VALUE, USER_ID
                )
                VALUES
                (
                  V_KATEGORI,REC.EST_RDI, 0, P_RAND_VALUE,P_USER_ID
                );
            EXCEPTION
            WHEN OTHERS THEN
              V_ERROR_CODE:=-10;
              V_ERROR_MSG :=SUBSTR('INSERT INTO TMP_CASH_FLOW_ESTIMASI '||SQLERRM,1,200);
              RAISE V_ERR;
            END;
           
            IF REC.KATEGORI    ='RR' THEN
              V_KATEGORI      :='RRBNSB';
            ELSIF REC.KATEGORI ='RM' THEN
              V_KATEGORI      :='RMBNSB';
            ELSIF REC.KATEGORI ='T' THEN
              V_KATEGORI      :='TBNSB';
            END IF;
        
            BEGIN
              INSERT
              INTO TMP_CASH_FLOW_ESTIMASI
                (
                  KATEGORI,MASUK,KELUAR,RAND_VALUE, USER_ID
                )
                VALUES
                (
                  V_KATEGORI,REC.EST_NASABAH, 0, P_RAND_VALUE,P_USER_ID
                );
            EXCEPTION
            WHEN OTHERS THEN
              V_ERROR_CODE:=-10;
              V_ERROR_MSG :=SUBSTR('INSERT INTO TMP_CASH_FLOW_ESTIMASI '||SQLERRM,1,200);
              RAISE V_ERR;
            END;
      
          IF REC.KATEGORI    ='RR' THEN
            V_KATEGORI      :='RRJ';
          ELSIF REC.KATEGORI ='RM' THEN
            V_KATEGORI      :='RMJ';
          ELSIF REC.KATEGORI ='T' THEN
            V_KATEGORI      :='TJ';
          END IF;
          
          
          BEGIN
            INSERT
            INTO TMP_CASH_FLOW_ESTIMASI
              (
                KATEGORI,MASUK,KELUAR,RAND_VALUE, USER_ID
              )
              VALUES
              (
                V_KATEGORI,0,REC.KELUAR,P_RAND_VALUE,P_USER_ID
              );
          EXCEPTION
          WHEN OTHERS THEN
            V_ERROR_CODE:=-10;
            V_ERROR_MSG :=SUBSTR('INSERT INTO TMP_CASH_FLOW_ESTIMASI '||SQLERRM,1,200);
            RAISE V_ERR;
          END;
          
    END LOOP;
    --15FEB TIDAK PAKE ESTIMASI UNTUK FIXED INCOME
    /*
    --FIXED INCOME ESTIMASI
    BEGIN
      INSERT INTO TMP_CASH_FLOW_ESTIMASI
        (KATEGORI,MASUK,KELUAR,RAND_VALUE, USER_ID
        )
      SELECT B.SUB_KATEGORI KATEGORI, DECODE(B.SUB_KATEGORI,'FJ',MASUK,0)MASUK,DECODE(B.SUB_KATEGORI,'FB',KELUAR,0)KELUAR, P_RAND_VALUE,P_USER_ID
      FROM
        (
          SELECT KATEGORI, SUM(DECODE(SIGN(NET_AMT),1,NET_AMT,0))MASUK, SUM(DECODE(SIGN(NET_AMT),-1,ABS(NET_AMT),0))KELUAR
          FROM
            (
              SELECT 'F' KATEGORI,TRX_DATE,TO_CHAR(TRX_SEQ_NO)TRX_SEQ_NO,SUM(DECODE(TRX_TYPE,'S',NET_AMOUNT,-NET_AMOUNT))NET_AMT
              FROM T_BOND_TRX
              WHERE T_BOND_TRX.approved_sts = 'A'
              AND T_BOND_TRX.lawan_type    <> 'I'
              AND NVL(journal_status,'X')   = 'A'
              AND VALUE_DT                  =P_DUE_DATE
              GROUP BY TRX_DATE,TRX_SEQ_NO
              UNION ALL
              SELECT 'F' KATEGORI,P_DUE_DATE,A.payrec_num,SUM(DECODE(db_Cr_flg,'C',PAYREC_AMT,-PAYREC_AMT))NET_AMT
              FROM t_payrech a
              JOIN t_payrecd b
              ON a.payrec_num=b.payrec_num
              JOIN MST_CLIENT M
              ON A.CLIENT_CD   =M.CLIENT_CD
              AND B.SL_ACCT_CD =M.CLIENT_CD
              JOIN MST_GLA_TRX G
              ON TRIM(A.GL_aCCT_CD) = G.GL_A
              LEFT JOIN
                (
                  SELECT XN_DOC_NUM
                  FROM TEMP_DAILY_CASH_FLOW
                  WHERE RAND_VALUE=P_RAND_VALUE
                  AND USER_ID     =P_USER_ID
                )
                TEMP
              ON A.PAYREC_NUM               = TEMP.XN_DOC_NUM
              LEFT JOIN (SELECT GL_A FROM MST_GLA_TRX WHERE JUR_TYPE='REPO')R
              ON TRIM(B.GL_ACCT_cD) = R.GL_A
              WHERE a.APPROVED_STS          ='A'
              AND TEMP.XN_DOC_NUM          IS NULL
              AND B.APPROVED_STS            ='A'
              AND M.APPROVED_STAT           ='A'
              AND M.CLIENT_TYPE_1          <> 'B'
              AND a.client_cd               =b.client_cd
              AND G.JUR_TYPE='BANK'
              AND A.PAYREC_DATE             =P_DUE_DATE
              AND SUBSTR(B.DOC_REF_NUM,6,1) = 'O'--08jan2018
              AND A.PAYREC_TYPE            IN('PV','RV','PD','RD')
              AND R.GL_A IS NULL
              GROUP BY A.payrec_num
            )
          GROUP BY KATEGORI
        )
        a, (
          SELECT 'F' KATEGORI, 'FJ' SUB_KATEGORI FROM DUAL
          UNION ALL
          SELECT 'F' KATEGORI, 'FB' SUB_KATEGORI FROM DUAL
        )
        B
      WHERE A.KATEGORI=B.KATEGORI; 
    EXCEPTION
    WHEN OTHERS THEN
      V_ERROR_CODE:=-30;
      V_ERROR_MSG :=SUBSTR('INSERT INTO TMP_CASH_FLOW_ESTIMASI FIXED INCOME '||SQLERRM,1,200);
      RAISE V_ERR;
    END;
    */
    /*
  --OTHERS
  BEGIN
        INSERT INTO TMP_CASH_FLOW_ESTIMASI(KATEGORI,MASUK,keluar,RAND_VALUE,USER_ID)
       SELECT KATEGORI, SUM(DECODE(SIGN(NET_AMT),1,NET_AMT,0))MASUK, SUM(DECODE(SIGN(NET_AMT),-1,ABS(NET_AMT),0))KELUAR, P_RAND_VALUE,P_USER_ID
          FROM
            (
              SELECT KATEGORI,XN_DOC_NUM, SUM(NET_AMT)NET_AMT
              FROM
                (
                  SELECT 'O' KATEGORI,A.XN_DOC_NUM,DECODE(DB_CR_FLG,'C',CURR_VAL,-CURR_VAL)NET_AMT
                  FROM T_ACCOUNT_LEDGER A, (
                      SELECT XN_DOC_NUM, tal_id
                      FROM T_ACCOUNT_LEDGER, MST_GLA_TRX G
                      WHERE DOC_DATE      =P_DUE_DATE
                      AND DUE_DATE       =P_DUE_DATE
                      AND TRIM(GL_ACCT_CD)=G.GL_A
                      AND G.JUR_TYPE='BANK'
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
          */
          /*
          --REPO TIDAK PAKE ESTIMASI
           BEGIN
        INSERT INTO TMP_CASH_FLOW_ESTIMASI(KATEGORI,MASUK,keluar,RAND_VALUE,USER_ID)
          SELECT 'REPO' KATEGORI,RETURN_VAL MASUK, 0 KELUAR, P_RAND_VALUE,P_USER_ID 
          FROM T_REPO  WHERE DUE_DATE=P_DUE_DATE
        AND APPROVED_STAT='A';
         EXCEPTION
            WHEN OTHERS THEN
            V_ERROR_CODE :=-50;
            V_ERROR_MSG :=SUBSTR('INSERT INTO TMP_CASH_FLOW_REAL REPO '||SQLERRM,1,200);
            RAISE V_ERR;
          END;
    */
    
    --DELETE TMP_CASH_FLOW_OUTS
    BEGIN
    DELETE FROM TMP_CASH_FLOW_OUTS WHERE RAND_vALUE=P_RAND_VALUE AND USER_ID=P_USER_ID;
    EXCEPTION
    WHEN OTHERS THEN
      V_ERROR_CODE :=-55;
      V_ERROR_MSG :=SUBSTR(' DELETE FROM TMP_CASH_FLOW_OUTS  '||SQLERRM,1,200);
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
  END SP_CASH_FLOW_ESTIMASI;