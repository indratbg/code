CREATE OR REPLACE PROCEDURE SPR_DAILY_CASH_FLOW(
        P_REP_DATE      DATE,
        P_USER_ID       VARCHAR2,
        P_GENERATE_DATE DATE,
        P_RAND_VALUE OUT NUMBER,
        P_ERROR_CODE OUT NUMBER,
        P_ERROR_MSG OUT VARCHAR2)
IS
    V_ERROR_CODE       NUMBER(5) ;
    V_ERROR_MSG        VARCHAR2(200) ;
    V_ERR              EXCEPTION;
    V_RANDOM_VALUE     NUMBER(10) ;
    V_BGN_BAL          DATE;
    V_BEG_BAL          NUMBER;
    V_DDMMYYYY         VARCHAR2(8) ;
    V_RUN_BAL_BANK     NUMBER;
    V_RUN_BAL_DEPOSITO NUMBER;
    V_BEG_BAL_DEPOSITO NUMBER;

    CURSOR CSR_DATA
    IS
         SELECT B.KATEGORI, B.DESCRIPTION, NVL(DEB_AMT, 0) DEB_AMT, NVL(CRE_AMT, 0) CRE_AMT, B.SESI_DEBIT, B.SESI_CREDIT, B.ORDER_NO, 
         DECODE( B.KATEGORI, 'BG', 'DEPOSITO', 'D', 'DEPOSITO', 'BANK') GL_DESC
               FROM
                ( SELECT KATEGORI, SUM(DECODE(SIGN(NET_AMT), 1, NET_AMT, 0)) DEB_AMT, SUM(DECODE(SIGN(NET_AMT), - 1, ABS(NET_AMT), 0)) CRE_AMT
                    FROM
                    ( SELECT XN_DOC_NUM, KATEGORI, SUM(NET_AMT) NET_AMT
                        FROM
                            ( SELECT A.XN_DOC_NUM, F_GET_CASHFLOW_CATEGORY(NVL(M.CLIENT_CD, TRIM(A.GL_ACCT_CD))) AS KATEGORI,
                                     DECODE(A.DB_CR_FLG, 'C', 1, - 1) * A.CURR_VAL AS NET_AMT
                                     FROM
                                    (SELECT T.XN_DOC_NUM, T.GL_ACCT_CD
                                       FROM T_ACCOUNT_LEDGER T,(
                                             SELECT XN_DOC_NUM
                                                   FROM TEMP_DAILY_CASH_FLOW
                                                    WHERE RAND_VALUE = V_RANDOM_VALUE
                                                    AND USER_ID    = P_USER_ID
                                        )TEMP
                                          WHERE T.DOC_DATE       = P_REP_DATE
                                          AND T.GL_ACCT_CD     = '1200'
                                          AND T.TAL_ID        IN(555, 5555)
                                          AND T.APPROVED_STS   = 'A'
                                          AND T.REVERSAL_JUR   = 'N'
                                          AND T.RECORD_SOURCE <> 'RE'
                                          AND T.XN_DOC_NUM     = TEMP.XN_DOC_NUM(+)
                                          AND TEMP.XN_DOC_NUM IS NULL
                                      ) P, T_ACCOUNT_LEDGER A,
                                        ( SELECT     CLIENT_CD
                                                   FROM MST_CLIENT, V_BROKER_SUBREK
                                                  WHERE CLIENT_CD     <> BROKER_CLIENT_CD
                                                    AND CLIENT_TYPE_1 <> 'B'
                                                    AND APPROVED_STAT  = 'A'
                                        )M
                              WHERE P.XN_DOC_NUM  = A.XN_DOC_NUM
                              AND A.GL_ACCT_CD <> P.GL_ACCT_CD
                              AND A.SL_ACCT_CD  = M.CLIENT_CD(+)
                              UNION ALL
                              SELECT XN_DOC_NUM, F_GET_CASHFLOW_CATEGORY(NVL(M.CLIENT_CD, TRIM(T.GL_ACCT_CD))) AS KATEGORI, 
                              DECODE(DB_CR_FLG, 'C', 1, - 1) * CURR_VAL AS NET_AMT
                                   FROM T_ACCOUNT_LEDGER T,
                                        (SELECT TABLE_ROWID FROM TEMP_DAILY_CASH_FLOW2
                                          WHERE RAND_VALUE = V_RANDOM_VALUE
                                          AND USER_ID    = P_USER_ID )E,
                                    (SELECT CLIENT_CD FROM MST_CLIENT, V_BROKER_SUBREK
                                      WHERE CLIENT_CD     <> BROKER_CLIENT_CD
                                      AND CLIENT_TYPE_1 <> 'B'
                                      AND APPROVED_STAT  = 'A'
                                    ) M
                            WHERE T.ROWID      = E.TABLE_ROWID
                            AND T.SL_ACCT_CD = M.CLIENT_CD(+)
                            )
                            GROUP BY XN_DOC_NUM, KATEGORI
                            HAVING SUM(NET_AMT) <> 0
                    )
                  GROUP BY KATEGORI
                ) A, T_CASH_FLOW_KATEGORI B
              WHERE A.KATEGORI(+) = B.KATEGORI
              ORDER BY B.ORDER_NO;

        CURSOR CSR_TEMP
        IS
             SELECT     A.XN_DOC_NUM, B.PAYREC_NUM
                   FROM
                    (SELECT XN_DOC_NUM, T_ACCOUNT_LEDGER.DOC_DATE, CLIENT_CD, CURR_VAL
                        FROM T_ACCOUNT_LEDGER, T_PAYRECH
                        WHERE DOC_DATE                          = P_REP_DATE
                        AND TRIM(T_ACCOUNT_LEDGER.GL_ACCT_CD) = '1200'
                        AND RECORD_SOURCE                     = 'PD'
                        AND XN_DOC_NUM                        = PAYREC_NUM
                        AND CLIENT_CD                        IS NOT NULL
                        AND TRIM(T_PAYRECH.ACCT_TYPE)         = 'RDM'
                    )A,
                    (
                     SELECT     PAYREC_NUM, T_ACCOUNT_LEDGER.DOC_DATE, CLIENT_CD, CURR_VAL
                        FROM T_ACCOUNT_LEDGER, T_PAYRECH
                        WHERE DOC_DATE                          = P_REP_DATE
                        AND TRIM(T_ACCOUNT_LEDGER.GL_ACCT_CD) = '1200'
                        --AND SL_ACCT_CD = 'ADIS003R'
                        AND RECORD_SOURCE             = 'RV'
                        AND XN_DOC_NUM                = PAYREC_NUM
                        AND CLIENT_CD                IS NOT NULL
                        AND TRIM(T_PAYRECH.ACCT_TYPE) = 'RDI'
                    )B
                WHERE A.DOC_DATE  = B.DOC_DATE
                AND A.CLIENT_CD = B.CLIENT_CD
                AND A.CURR_VAL  = B.CURR_VAL;

        V_DEBIT  NUMBER;
        V_CREDIT NUMBER;

        CURSOR CSR_UPD_BAL IS
         SELECT T.ROWID, T.*  FROM R_DAILY_CASH_FLOW T
                  WHERE RAND_VALUE = V_RANDOM_VALUE
                  AND USER_ID    = P_USER_ID
               ORDER BY SESI, SORTK;
               
    BEGIN
    
        V_RANDOM_VALUE := ABS(DBMS_RANDOM.RANDOM) ;
        BEGIN
            SP_RPT_REMOVE_RAND('R_DAILY_CASH_FLOW', V_RANDOM_VALUE, V_ERROR_MSG, V_ERROR_CODE) ;
        EXCEPTION
        WHEN OTHERS THEN
            V_ERROR_CODE := - 10;
            V_ERROR_MSG  := SUBSTR('SP_RPT_REMOVE_RAND '||V_ERROR_MSG||SQLERRM(SQLCODE), 1, 200) ;
            RAISE V_ERR;

        END;

        IF V_ERROR_CODE   < 0 THEN
            V_ERROR_CODE := - 20;
            V_ERROR_MSG  := SUBSTR('SP_RPT_REMOVE_RAND'||V_ERROR_MSG, 1, 200) ;
            RAISE V_ERR;

        END IF;
        V_BGN_BAL  := TO_DATE('01'||TO_CHAR(P_REP_DATE, 'MMYYYY'), 'DDMMYYYY') ;
        V_DDMMYYYY := TO_CHAR(P_REP_DATE, 'DDMMYYYY') ;
        
        --GET BEGINNING BALANCE BANK
        BEGIN

             SELECT     SUM(NVL(BEG_BAL, 0))
                   INTO V_BEG_BAL
                   FROM
                    (
                      SELECT SUM(NVL(B.DEB_OBAL, 0) - NVL(B.CRE_OBAL, 0)) BEG_BAL FROM T_DAY_TRS B
                        WHERE B.TRS_DT           = V_BGN_BAL
                        AND TRIM(B.GL_ACCT_CD) = '1200'
                      UNION ALL
                      SELECT     DECODE(D.DB_CR_FLG, 'D', 1, - 1) * NVL(D.CURR_VAL, 0) MVMT_AMT FROM T_ACCOUNT_LEDGER D
                        WHERE D.DOC_DATE BETWEEN V_BGN_BAL AND(P_REP_DATE - 1)
                        AND TRIM(D.GL_ACCT_CD) = '1200'
                        AND D.APPROVED_STS     = 'A'
                    );
        EXCEPTION
        WHEN OTHERS THEN
            V_ERROR_CODE := - 10;
            V_ERROR_MSG  := SUBSTR('SELECT BEGINNING BALANCE YESTERDAY '||SQLERRM(SQLCODE), 1, 200) ;
            RAISE V_ERR;

        END;
        
        --GET BEGINNING BALANCE DEPOSITO
        BEGIN
             SELECT     SUM(NVL(BEG_BAL, 0)) INTO V_BEG_BAL_DEPOSITO
                   FROM
                    (
                      SELECT SUM(NVL(B.DEB_OBAL, 0) - NVL(B.CRE_OBAL, 0)) BEG_BAL
                        FROM T_DAY_TRS B
                        WHERE B.TRS_DT           = V_BGN_BAL
                        AND TRIM(B.GL_ACCT_CD) = '1201'
                      UNION ALL
                      SELECT  DECODE(D.DB_CR_FLG, 'D', 1, - 1) * NVL(D.CURR_VAL, 0) MVMT_AMT
                        FROM T_ACCOUNT_LEDGER D
                        WHERE D.DOC_DATE BETWEEN V_BGN_BAL AND(P_REP_DATE - 1)
                        AND TRIM(D.GL_ACCT_CD) = '1201'
                        AND D.APPROVED_STS     = 'A'
                    ) ;

        EXCEPTION
        WHEN OTHERS THEN
            V_ERROR_CODE := - 11;
            V_ERROR_MSG  := SUBSTR('SELECT BEGINNING BALANCE YESTERDAY '||SQLERRM(SQLCODE), 1, 200) ;
            RAISE V_ERR;

        END;
        
        BEGIN
             INSERT INTO TEMP_DAILY_CASH_FLOW
                    (XN_DOC_NUM, RAND_VALUE, USER_ID
                    )
            SELECT DISTINCT XN_DOC_NUM, V_RANDOM_VALUE, P_USER_ID
                   FROM T_ACCOUNT_LEDGER
                  WHERE DOC_DATE         = P_REP_DATE
                    AND APPROVED_STS     = 'A'
                    AND TRIM(GL_ACCT_CD) = '1111'
                    AND REVERSAL_JUR     = 'N'
                    AND RECORD_SOURCE   <> 'RE';

        EXCEPTION
        WHEN OTHERS THEN
            V_ERROR_CODE := - 12;
            V_ERROR_MSG  := SUBSTR('SELECT DOC_NUM T_ACCOUNT_LEDGER '||SQLERRM(SQLCODE), 1, 200) ;
            RAISE V_ERR;
        END;

        --16NOV2017 UNTUK AMBIL BARIS YANG DISISIPKAN DIANTARA JURNAL INSTRANSIT 1111
        
         INSERT
               INTO TEMP_DAILY_CASH_FLOW2
         SELECT     A.ROWID, V_RANDOM_VALUE, P_USER_ID
               FROM T_ACCOUNT_LEDGER A,(
                    SELECT DISTINCT XN_DOC_NUM
                          FROM T_ACCOUNT_LEDGER
                          WHERE DOC_DATE         = P_REP_DATE
                          AND APPROVED_STS     = 'A'
                          AND TRIM(GL_ACCT_CD) = '1111'
                          AND REVERSAL_JUR     = 'N'
                          AND RECORD_SOURCE   <> 'RE'
                )B
              WHERE A.XN_DOC_NUM      = B.XN_DOC_NUM
              AND A.GL_ACCT_CD NOT IN('1200', '1111') ;

        FOR REC IN CSR_TEMP
        LOOP
        
            BEGIN
                 INSERT INTO TEMP_DAILY_CASH_FLOW
                        (
                            XN_DOC_NUM, RAND_VALUE, USER_ID
                        )
                        VALUES
                        (
                            REC.XN_DOC_NUM, V_RANDOM_VALUE, P_USER_ID
                        ) ;
            EXCEPTION
            WHEN OTHERS THEN
                V_ERROR_CODE := - 13;
                V_ERROR_MSG  := SUBSTR('INSERT DOC_NUM T_ACCOUNT_LEDGER '||SQLERRM(SQLCODE), 1, 200) ;
                RAISE V_ERR;
            END;
            
            BEGIN
                 INSERT INTO TEMP_DAILY_CASH_FLOW
                        (
                            XN_DOC_NUM, RAND_VALUE, USER_ID
                        )
                        VALUES
                        (
                            REC.PAYREC_NUM, V_RANDOM_VALUE, P_USER_ID
                        ) ;
            EXCEPTION
            WHEN OTHERS THEN
                V_ERROR_CODE := - 14;
                V_ERROR_MSG  := SUBSTR('INSERT DOC_NUM T_ACCOUNT_LEDGER '||SQLERRM(SQLCODE), 1, 200) ;
                RAISE V_ERR;
            END;

        END LOOP;

        FOR REC IN CSR_DATA
        LOOP

            IF REC.SESI_DEBIT = 1 THEN
                V_DEBIT      := REC.DEB_AMT;
            ELSE
                V_DEBIT := 0;
            END IF;

            IF REC.SESI_CREDIT = 1 THEN
                V_CREDIT      := REC.CRE_AMT;
            ELSE
                V_CREDIT := 0;
            END IF;
            
            --SESI 1
            BEGIN
                 INSERT INTO R_DAILY_CASH_FLOW
                        (
                            SESI, DESCRIPTION, BEG_BAL, DEBIT, CREDIT, RAND_VALUE, USER_ID, GENERATE_DATE, SORTK, GL_DESC
                        )
                        VALUES
                        (
                            1, REC.DESCRIPTION, DECODE(REC.GL_DESC, 'BANK', V_BEG_BAL, V_BEG_BAL_DEPOSITO), V_DEBIT, V_CREDIT, V_RANDOM_VALUE,
                            P_USER_ID, P_GENERATE_DATE, REC.ORDER_NO, REC.GL_DESC
                        ) ;
            EXCEPTION
            WHEN OTHERS THEN
                V_ERROR_CODE := - 30;
                V_ERROR_MSG  := SUBSTR('INSERT INTO R_DAILY_CASH_FLOW '||SQLERRM(SQLCODE), 1, 200) ;
                RAISE V_ERR;

            END;

            IF REC.SESI_DEBIT = 2 THEN
                V_DEBIT      := REC.DEB_AMT;
            ELSE
                V_DEBIT := 0;
            END IF;

            IF REC.SESI_CREDIT = 2 THEN
                V_CREDIT      := REC.CRE_AMT;
            ELSE
                V_CREDIT := 0;
            END IF;
            
            --SESI 2
            BEGIN
                 INSERT INTO R_DAILY_CASH_FLOW
                        (
                            SESI, DESCRIPTION, BEG_BAL, DEBIT, CREDIT, RAND_VALUE, USER_ID, GENERATE_DATE, SORTK, GL_DESC
                        )
                        VALUES
                        (
                            2, REC.DESCRIPTION, DECODE(REC.GL_DESC, 'BANK', V_BEG_BAL, V_BEG_BAL_DEPOSITO), V_DEBIT, V_CREDIT, V_RANDOM_VALUE,
                            P_USER_ID, P_GENERATE_DATE, REC.ORDER_NO, REC.GL_DESC
                        ) ;
            EXCEPTION
            WHEN OTHERS THEN
                V_ERROR_CODE := - 40;
                V_ERROR_MSG  := SUBSTR('INSERT INTO R_DAILY_CASH_FLOW '||SQLERRM(SQLCODE), 1, 200) ;
                RAISE V_ERR;
            END;

        END LOOP;
        V_RUN_BAL_BANK     := V_BEG_BAL;
        V_RUN_BAL_DEPOSITO := V_BEG_BAL_DEPOSITO;

        FOR REC IN CSR_UPD_BAL
        LOOP

            IF REC.GL_DESC      = 'BANK' THEN
                V_RUN_BAL_BANK := V_RUN_BAL_BANK + ( REC.DEBIT - REC.CREDIT );

            ELSE
                V_RUN_BAL_DEPOSITO := V_RUN_BAL_DEPOSITO +(REC.DEBIT - REC.CREDIT) ;
            END IF;
            
            BEGIN
                 UPDATE R_DAILY_CASH_FLOW
                    SET RUNNING_BALANCE = DECODE(REC.GL_DESC, 'BANK', V_RUN_BAL_BANK, V_RUN_BAL_DEPOSITO)
                      WHERE ROWID       = REC.ROWID;

            EXCEPTION
            WHEN OTHERS THEN
                V_ERROR_CODE := - 50;
                V_ERROR_MSG  := SUBSTR('INSERT INTO R_DAILY_CASH_FLOW '||SQLERRM(SQLCODE), 1, 200) ;
                RAISE V_ERR;
            END;

        END LOOP;
        
        BEGIN
             DELETE FROM TEMP_DAILY_CASH_FLOW WHERE RAND_VALUE = V_RANDOM_VALUE AND USER_ID    = P_USER_ID;
        EXCEPTION
        WHEN OTHERS THEN
            V_ERROR_CODE := - 60;
            V_ERROR_MSG  := SUBSTR('DELETE  TMP_DAILY_CASH_FLOW WHERE '||V_RANDOM_VALUE||' '||SQLERRM(SQLCODE), 1, 200) ;
            RAISE V_ERR;

        END;
        
        BEGIN
             DELETE FROM TEMP_DAILY_CASH_FLOW2 WHERE RAND_VALUE = V_RANDOM_VALUE AND USER_ID    = P_USER_ID;
        EXCEPTION
        WHEN OTHERS THEN
            V_ERROR_CODE := - 60;
            V_ERROR_MSG  := SUBSTR('DELETE  TMP_DAILY_CASH_FLOW2 WHERE '||V_RANDOM_VALUE||' '||SQLERRM(SQLCODE), 1, 200) ;
            RAISE V_ERR;
        END;
        
        COMMIT;
        P_ERROR_CODE := 1;
        P_ERROR_MSG  := '';
        P_RAND_VALUE := V_RANDOM_VALUE;

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
    END SPR_DAILY_CASH_FLOW;