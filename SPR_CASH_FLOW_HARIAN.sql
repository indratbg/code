create or replace PROCEDURE SPR_CASH_FLOW_HARIAN(P_REP_DATE DATE,
	P_USER_ID VARCHAR2,
	P_GENERATE_DATE DATE,
	P_RAND_VALUE OUT NUMBER,
  P_ERROR_CODE OUT NUMBER,
  P_ERROR_MSG OUT VARCHAR2)
IS


V_RANDOM_VALUE NUMBER(10,0);
V_ERR EXCEPTION;
V_ERROR_CODE NUMBER;
V_ERROR_MSG VARCHAR2(200);
V_BEG_BAL_BANK NUMBER;
V_BEG_BAL_DEPOSITO NUMBER;
V_BGN_BAL_DATE DATE;
V_REAL_BALANCE_BANK NUMBER;
V_EST_BALANCE_BANK NUMBER;
V_REAL_BALANCE_DEPOSITO NUMBER;
V_EST_BALANCE_DEPOSITO NUMBER;
i integer :=1;

CURSOR CSR_DATA IS
SELECT T.ORDER_NO,'BANK' MAIN,
T.KATEGORI,T.DESCRIPTION,NVL(A.MASUK,0) REAL_MASUK,NVL(A.KELUAR,0) REAL_KELUAR,
NVL(B.MASUK,0) EST_MASUK,
NVL(B.KELUAR,0) EST_KELUAR
FROM T_CASH_FLOW_KATEGORI T,
(
 SELECT KATEGORI,MASUK,KELUAR FROM TMP_CASH_FLOW_REAL  
 WHERE RAND_VALUE=V_RANDOM_VALUE AND USER_ID=P_USER_ID
 )A,
(
  SELECT  KATEGORI,MASUK,KELUAR FROM TMP_CASH_FLOW_ESTIMASI 
  WHERE RAND_VALUE=V_RANDOM_VALUE AND USER_ID=P_USER_ID
)B
  WHERE T.KATEGORI=A.KATEGORI(+)
  AND T.KATEGORI=B.KATEGORI(+)
  ORDER BY 1;

CURSOR CSR_JUR_EX IS
SELECT A.XN_DOC_NUM, B.PAYREC_NUM
FROM
  (
    SELECT XN_DOC_NUM, T_ACCOUNT_LEDGER.DOC_DATE, CLIENT_CD, CURR_VAL
    FROM T_ACCOUNT_LEDGER, T_PAYRECH
    WHERE DOC_DATE                        = P_REP_DATE
    AND t_account_ledger.due_date         = P_REP_DATE
    AND TRIM(T_ACCOUNT_LEDGER.GL_ACCT_CD) = '1200'
    AND RECORD_SOURCE                     = 'PD'
    AND XN_DOC_NUM                        = PAYREC_NUM
    AND CLIENT_CD                        IS NOT NULL
    AND TRIM(T_PAYRECH.ACCT_TYPE)         = 'RDM'
  )
  A, (
    SELECT PAYREC_NUM, T_ACCOUNT_LEDGER.DOC_DATE, CLIENT_CD, CURR_VAL
    FROM T_ACCOUNT_LEDGER, T_PAYRECH
    WHERE DOC_DATE                        = P_REP_DATE
    AND TRIM(T_ACCOUNT_LEDGER.GL_ACCT_CD) = '1200'
    AND t_account_ledger.due_date         = P_REP_DATE
    AND RECORD_SOURCE                     = 'RV'
    AND XN_DOC_NUM                        = PAYREC_NUM
    AND CLIENT_CD                        IS NOT NULL
    AND TRIM(T_PAYRECH.ACCT_TYPE)         = 'RDI'
  )
  B
WHERE A.DOC_DATE = B.DOC_DATE
AND A.CLIENT_CD  = B.CLIENT_CD
AND A.CURR_VAL   = B.CURR_VAL;

BEGIN

		V_RANDOM_VALUE := 28122017;--ABS(DBMS_RANDOM.RANDOM);
		 
		BEGIN
		  SP_RPT_REMOVE_RAND('R_CASH_FLOW_HARIAN',V_RANDOM_VALUE,V_ERROR_MSG,V_ERROR_CODE);
		EXCEPTION
		WHEN OTHERS THEN
		    V_ERROR_CODE  := -3;
		    V_ERROR_MSG := SUBSTR('SP_RPT_REMOVE_RAND '||V_ERROR_MSG||SQLERRM(SQLCODE),1,200);
		    RAISE V_ERR;
		END;
		
		
		IF V_ERROR_CODE  < 0 THEN
			V_ERROR_CODE  := -4;
			V_ERROR_MSG := SUBSTR('SP_RPT_REMOVE_RAND'||V_ERROR_MSG,1,200);
			RAISE V_ERR;
		END IF;


	 	--GET BEGINNING BALANCE DATE
	 	V_BGN_BAL_DATE := P_REP_DATE-TO_CHAR(P_REP_DATE,'DD')+1;

  		--GET BEGINNING BALANCE BANK
        BEGIN
        SELECT SUM(NVL(beg_bal, 0))  INTO V_BEG_BAL_BANK
           FROM
            ( SELECT SUM(NVL(b.deb_obal, 0) - NVL(b.cre_obal, 0)) BEG_BAL
                FROM t_day_trs b
                WHERE b.trs_dt           = V_BGN_BAL_DATE
                AND trim(b.gl_acct_cd) = '1200'
              UNION ALL
              SELECT     DECODE(d.db_cr_flg, 'D', 1, - 1) * NVL(d.curr_val, 0) MVMT_AMT
                FROM t_account_ledger d
                WHERE d.doc_date BETWEEN V_BGN_BAL_DATE AND(P_REP_DATE - 1)
                AND trim(d.gl_acct_cd) = '1200'
                AND d.approved_sts     = 'A'
            ) ;
        EXCEPTION
        WHEN OTHERS THEN
            V_ERROR_CODE := -10;
            V_ERROR_MSG  := SUBSTR('SELECT BEGINNING BALANCE YESTERDAY '||SQLERRM(SQLCODE), 1, 200) ;
            RAISE V_err;

        END;

        /*
        --GET BEGINNING BALANCE DEPOSITO
        BEGIN
        SELECT SUM(NVL(beg_bal, 0)) INTO V_BEG_BAL_DEPOSITO
                   FROM
                    (SELECT     SUM(NVL(b.deb_obal, 0) - NVL(b.cre_obal, 0)) BEG_BAL
                        FROM t_day_trs b
                        WHERE b.trs_dt           = V_BGN_BAL_DATE
                        AND trim(b.gl_acct_cd) = '1201'
                     UNION ALL
                     SELECT     DECODE(d.db_cr_flg, 'D', 1, - 1) * NVL(d.curr_val, 0) MVMT_AMT
                        FROM t_account_ledger d
                        WHERE d.doc_date BETWEEN V_BGN_BAL_DATE AND(P_REP_DATE - 1)
                        AND trim(d.gl_acct_cd) = '1201'
                        AND d.approved_sts     = 'A'
                    ) ;
        EXCEPTION
        WHEN OTHERS THEN
            V_ERROR_CODE := -11;
            V_ERROR_MSG  := SUBSTR('SELECT BEGINNING BALANCE YESTERDAY '||SQLERRM(SQLCODE), 1, 200) ;
            RAISE V_err;

        END;
        */
    --EXCLUDE JOURNAL
    FOR REC IN CSR_JUR_EX  LOOP
        BEGIN
          INSERT
          INTO TEMP_DAILY_CASH_FLOW
            (
              XN_DOC_NUM, RAND_VALUE, USER_ID
            )
            VALUES
            (
              REC.XN_DOC_NUM, V_RANDOM_VALUE, P_USER_ID
            ) ;
        EXCEPTION
        WHEN OTHERS THEN
          V_ERROR_CODE := -12;
          V_ERROR_MSG  := SUBSTR('INSERT XN_DOC_NUM TEMP_DAILY_CASH_FLOW '||SQLERRM(SQLCODE), 1, 200) ;
          RAISE V_ERR;
        END;
          
        BEGIN
          INSERT
          INTO TEMP_DAILY_CASH_FLOW
            (
              XN_DOC_NUM, RAND_VALUE, USER_ID
            )
            VALUES
            (
              REC.PAYREC_NUM, V_RANDOM_VALUE, P_USER_ID
            ) ;
        EXCEPTION
        WHEN OTHERS THEN
          V_ERROR_CODE := -13;
          V_ERROR_MSG  := SUBSTR('INSERT PAYREC_NUM TEMP_DAILY_CASH_FLOW '||SQLERRM(SQLCODE), 1, 200) ;
          RAISE V_ERR;
        END;

    END LOOP;

		BEGIN        
		SP_CASH_FLOW_REAL(
		    P_REP_DATE,
		    P_USER_ID,
		    V_RANDOM_VALUE,
		    V_ERROR_CODE,
		    V_ERROR_MSG);
		EXCEPTION
		WHEN OTHERS THEN
			V_ERROR_CODE:=-20;
			V_ERROR_MSG :=SUBSTR('CALL SP_CASH_FLOW_REAL '||SQLERRM,1,200);
			RAISE V_ERR;
		END;

		IF V_ERROR_CODE<0 THEN
			V_ERROR_CODE :=-25;
			V_ERROR_MSG := SUBSTR('CALL SP_CASH_FLOW_REAL '||V_ERROR_MSG,1,200);
			RAISE V_ERR;
		END IF;

		BEGIN        
		SP_CASH_FLOW_ESTIMASI(
		    P_REP_DATE,
		    P_USER_ID,
		    V_RANDOM_VALUE,
		    V_ERROR_CODE,
		    V_ERROR_MSG);
		EXCEPTION
		WHEN OTHERS THEN
			V_ERROR_CODE:=-30;
			V_ERROR_MSG :=SUBSTR('CALL SP_CASH_FLOW_ESTIMASI '||SQLERRM,1,200);
			RAISE V_ERR;
		END;

		IF V_ERROR_CODE<0 THEN
			V_ERROR_CODE :=-35;
			V_ERROR_MSG := SUBSTR('CALL SP_CASH_FLOW_ESTIMASI '||V_ERROR_MSG,1,200);
			RAISE V_ERR;
		END IF;


		V_REAL_BALANCE_BANK :=V_BEG_BAL_BANK;
		V_EST_BALANCE_BANK :=V_BEG_BAL_BANK;
	    V_REAL_BALANCE_DEPOSITO :=V_BEG_BAL_DEPOSITO;
	    V_EST_BALANCE_DEPOSITO :=V_BEG_BAL_DEPOSITO;


	    BEGIN
        INSERT INTO R_CASH_FLOW_HARIAN(ORDER_NO,REP_DATE,MAIN_KATEGORI,KATEGORI,DESCRIPTION,REAL_BALANCE,
           EST_BALANCE,RAND_VALUE,USER_ID,GENERATE_DATE)
        VALUES(0,P_REP_DATE,'BANK','00','BEGINNING BALANCE', V_BEG_BAL_BANK,
            V_BEG_BAL_BANK, V_RANDOM_VALUE,P_USER_ID,P_GENERATE_DATE);
        EXCEPTION
        WHEN OTHERS THEN
          V_ERROR_CODE:=-40;
          V_ERROR_MSG :=SUBSTR('INSERT INTO R_CASH_FLOW_HARIAN '||SQLERRM,1,200);
          RAISE V_ERR;
        END;
		            

		FOR REC IN CSR_DATA LOOP

	      	V_REAL_BALANCE_BANK :=V_REAL_BALANCE_BANK+REC.REAL_MASUK-REC.REAL_KELUAR;
	        V_EST_BALANCE_BANK :=V_EST_BALANCE_BANK+REC.EST_MASUK-REC.EST_KELUAR;
        
            BEGIN
            INSERT INTO R_CASH_FLOW_HARIAN(ORDER_NO,REP_DATE,MAIN_KATEGORI,KATEGORI,DESCRIPTION,REAL_MASUK,REAL_KELUAR,REAL_BALANCE,
                EST_MASUK,EST_KELUAR,EST_BALANCE,RAND_VALUE,USER_ID,GENERATE_DATE)
            VALUES(REC.ORDER_NO,P_REP_DATE,REC.MAIN,REC.KATEGORI,REC.DESCRIPTION, REC.REAL_MASUK,REC.REAL_KELUAR,V_REAL_BALANCE_BANK,
                REC.EST_MASUK,REC.EST_KELUAR,V_EST_BALANCE_BANK, V_RANDOM_VALUE,P_USER_ID,P_GENERATE_DATE);
            EXCEPTION
            WHEN OTHERS THEN
              V_ERROR_CODE:=-42;
              V_ERROR_MSG :=SUBSTR('INSERT INTO R_CASH_FLOW_HARIAN '||SQLERRM,1,200);
              RAISE V_ERR;
            END;
       
		END LOOP;


		--DELETE DATA TEMPORARY TABLE
		BEGIN 
		DELETE FROM TMP_CASH_FLOW_REAL WHERE RAND_VALUE=V_RANDOM_VALUE AND USER_ID=P_USER_ID;
		EXCEPTION
		WHEN OTHERS THEN
			V_ERROR_CODE :=-50;
			V_ERROR_MSG :=SUBSTR('DELETE FROM TMP_CASH_FLOW_REAL '||SQLERRM,1,200);
			RAISE V_ERR;
		END;

		BEGIN 
		DELETE FROM TMP_CASH_FLOW_ESTIMASI WHERE RAND_VALUE=V_RANDOM_VALUE AND USER_ID=P_USER_ID;
		EXCEPTION
		WHEN OTHERS THEN
			V_ERROR_CODE :=-55;
			V_ERROR_MSG :=SUBSTR('DELETE FROM TMP_CASH_FLOW_REAL '||SQLERRM,1,200);
			RAISE V_ERR;
		END;

    BEGIN 
		DELETE FROM TEMP_DAILY_CASH_FLOW WHERE RAND_VALUE=V_RANDOM_VALUE AND USER_ID=P_USER_ID;
		EXCEPTION
		WHEN OTHERS THEN
			V_ERROR_CODE :=-55;
			V_ERROR_MSG :=SUBSTR('DELETE FROM TMP_CASH_FLOW_REAL '||SQLERRM,1,200);
			RAISE V_ERR;
		END;


P_RAND_VALUE :=V_RANDOM_VALUE;
P_ERROR_CODE:=1;
P_ERROR_MSG:='';

EXCEPTION
WHEN V_ERR THEN
	ROLLBACK;
	P_ERROR_CODE :=V_ERROR_CODE;
	P_ERROR_MSG := V_ERROR_MSG;
WHEN OTHERS THEN
	ROLLBACK;
	P_ERROR_CODE :=-1;
	P_ERROR_MSG := SUBSTR(SQLERRM,1,200);
END SPR_CASH_FLOW_HARIAN;