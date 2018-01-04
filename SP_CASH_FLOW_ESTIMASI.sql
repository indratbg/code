create or replace PROCEDURE SP_CASH_FLOW_ESTIMASI(P_DUE_DATE DATE, 
	P_USER_ID VARCHAR2,
	P_RAND_VALUE NUMBER,
	P_ERROR_CD OUT NUMBER, 
	P_ERROR_MSG OUT VARCHAR2)
IS

V_ERR EXCEPTION;
V_ERROR_CODE NUMBER;
V_ERROR_MSG VARCHAR2(200);
V_TRX_DATE DATE;   
V_BEG_BAL_DATE DATE;
V_CNT NUMBER;
V_CLIENT_TYPE_3 MST_CLIENT.CLIENT_TYPE_3%TYPE :='%';
V_KATEGORI VARCHAR2(20);

CURSOR CSR_RETAIL IS

SELECT KATEGORI,SUM(AMT)AMT,
SUM(DECODE(SIGN(AMT),1,DECODE(SIGN(AMT-SALDO_RDI),-1,AMT,SALDO_RDI ),0)) EST_RDI, 
SUM(DECODE(SIGN(AMT),1,DECODE(SIGN(AMT-SALDO_RDI),-1,0,(AMT-SALDO_RDI) ),0)) EST_NASABAH
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
    AND (M.CLIENT_TYPE_3 = V_CLIENT_TYPE_3 OR V_CLIENT_TYPE_3  ='%')
    AND CONTR_STAT      <>'C'
    GROUP BY T.CLIENT_CD
   --BIAYA BIAYA
    UNION ALL
     SELECT F_GET_CASHFLOW_CATEGORY(client_cd)kategori,CLIENT_CD, SUM(DECODE(DB_CR_FLG,'D',CURR_VAL,-CURR_VAL))NET_AMT
    FROM T_ACCOUNT_LEDGER A, MST_CLIENT M, 
    (SELECT XN_DOC_NUM FROM TEMP_DAILY_CASH_FLOW 
      WHERE RAND_VALUE=P_RAND_VALUE AND USER_ID=P_USER_ID) TEMP 
    WHERE A.SL_ACCT_CD =M.CLIENT_CD
    AND A.XN_DOC_NUM = TEMP.XN_DOC_NUM(+)
    AND TEMP.XN_DOC_NUM IS NULL
    AND A.APPROVED_STS ='A'
    AND M.APPROVED_STAT='A'
    AND A.REVERSAL_JUR ='N'
     AND M.CLIENt_TYPE_1 <> 'B'
    AND (M.CLIENT_TYPE_3= V_CLIENT_TYPE_3 OR V_CLIENT_TYPE_3='%')
    AND DOC_DATE       =P_DUE_DATE
    AND RECORD_SOURCE IN ('GL', 'PD', 'RD', 'RVO', 'PVO','INT','DNCN')
    GROUP BY CLIENT_CD
     --OUTSTANDING AR/AP (UTANG/PIUTANG) NASABAH
    UNION ALL
    SELECT F_GET_CASHFLOW_CATEGORY(SL_ACCT_CD)KATEGORI,sl_acct_cd,
    SUM(DECODE(A.DB_CR_FLG,'D',CURR_VAL,-CURR_VAL)) NET_AMT
    FROM t_account_ledger a join mst_client m on a.SL_ACCT_CD=m.client_cd
    WHERE a.doc_date BETWEEN V_BEG_BAL_DATE AND P_DUE_DATE
    AND DUE_DATE       < P_DUE_DATE
    AND M.CLIENt_TYPE_1<>'B'
    AND (M.CLIENT_TYPE_3= V_CLIENT_TYPE_3 OR V_CLIENT_TYPE_3='%')
    AND a.approved_sts = 'A'
    and M.APPROVED_STAT='A'
    AND A.REVERSAL_JUR ='N'
    GROUP BY SL_ACCT_CD
    HAVING SUM(DECODE(A.DB_CR_FLG,'D',CURR_VAL,-CURR_VAL)) <>0
    UNION ALL
    SELECT F_GET_CASHFLOW_CATEGORY(SL_ACCT_CD)KATEGORI,sl_acct_cd,SUM(NVL(b.deb_obal,0)-NVL(b.cre_obal,0)) beg_bal
    FROM t_day_trs b JOIN MST_CLIENT M ON B.SL_ACCT_CD=M.CLIENT_CD
    WHERE b.trs_dt = V_BEG_BAL_DATE
    AND M.APPROVED_STAT ='A'
    AND M.CLIENt_TYPE_1 <>'B'
   AND (M.CLIENT_TYPE_3 = V_CLIENT_TYPE_3 OR V_CLIENT_TYPE_3='%')
    GROUP BY SL_ACCT_CD
    HAVING SUM(NVL(b.deb_obal,0) - NVL(b.cre_obal,0)) <>0
    
    )
    GROUP BY KATEGORI,CLIENT_CD
  ) 
  GROUP BY KATEGORI;

BEGIN

	BEGIN
	SELECT COUNT(1) INTO V_CNT FROM TMP_CASH_FLOW_ESTIMASI WHERE RAND_VALUE=P_RAND_VALUE AND USER_ID=P_USER_ID;
	EXCEPTION
	WHEN OTHERS THEN
	V_ERROR_CODE:=-3;
	V_ERROR_MSG:=SUBSTR('SELECT COUNT TMP_CASH_FLOW_ESTIMASI '||SQLERRM,1,200);
	RAISE V_ERR;
	END;
	IF V_CNT>0 THEN
		BEGIN
		DELETE FROM TMP_CASH_FLOW_ESTIMASI WHERE RAND_VALUE=P_RAND_VALUE AND USER_ID=P_USER_ID;
		EXCEPTION
		WHEN OTHERS THEN
		V_ERROR_CODE:=-4;
		V_ERROR_MSG:=SUBSTR('DELETE TMP_CASH_FLOW_ESTIMASI '||SQLERRM,1,200);
		RAISE V_ERR;
		END;
	END IF;

	  V_TRX_DATE	:= GET_DOC_DATE(3,P_DUE_DATE);
  	V_BEG_BAL_DATE := GET_DOC_DATE(3,P_DUE_DATE);
  	V_BEG_BAL_DATE := V_BEG_BAL_DATE - TO_CHAR(V_BEG_BAL_DATE,'DD')+1;
	
      --BROKER DAN KPEI
      BEGIN
      INSERT INTO TMP_CASH_FLOW_ESTIMASI(KATEGORI,MASUK,KELUAR, RAND_VALUE, USER_ID)
		--PROYEKSI NEGO/BROKER JUAL BELI
     SELECT B.SUB_KATEGORI , DECODE(SUB_KATEGORI,'BJ',DECODE(SIGN(NET_AMT),1,NET_AMT,0),0) MASUK, 
     DECODE(SUB_KATEGORI,'BB',DECODE(SIGN(NET_AMT),-1,ABS(NET_AMT),0),0) KELUAR,
     P_RAND_VALUE,P_USER_ID
      FROM
        (
          SELECT 'B' KATEGORI, SUM(DECODE(SUBSTR(CONTR_NUM,5,1),'B', -NET, NET))NET_AMT
          FROM t_contracts
          WHERE CONTR_DT  >= V_TRX_DATE
          AND due_dt_for_amt =P_DUE_DATE
          AND mrkt_type ='NG'
          AND CONTR_STAT <> 'C'
          AND APPROVED_STAT='A'
          AND DECODE(SUBSTR(CONTR_NUM,5,1),'J',trim(SELL_BROKER_CD),trim(BUY_BROKER_CD) ) = 'YJ'
        )
        A, (
          SELECT 'B' KATEGORI,'BB' SUB_KATEGORI FROM DUAL
          UNION
          SELECT 'B' KATEGORI,'BJ' SUB_KATEGORI FROM DUAL
        )
        B
      WHERE A.KATEGORI=B.KATEGORI 
      UNION ALL
      --PROYEKSI KPEI BELI/JUAL
      SELECT SUB_KATEGORI KATEGORI, DECODE(B.SUB_KATEGORI,'KJ',SUM(DECODE(SIGN(NET_AMT),1,NET_AMT,0)),0)MASUK,
      DECODE(B.SUB_KATEGORI,'KB',SUM(DECODE(SIGN(NET_AMT),-1,ABS(NET_AMT),0)),0)KELUAR,
      P_RAND_VALUE,P_USER_ID
      FROM
      (
          SELECT 'K' AS KATEGORI,SL_ACCT_CD, SUM(DECODE(DB_CR_FLG,'D',1,-1)*CURR_VAL) NET_AMT
          FROM T_ACCOUNT_LEDGER T JOIN MST_GLA_TRX G ON TRIM(T.GL_ACCT_CD) = G.GL_A 			
          WHERE T.DOC_DATE between V_TRX_DATE AND P_DUE_DATE 
          AND T.DUE_DATE between V_TRX_DATE AND P_DUE_DATE 			
          AND G.JUR_TYPE='KPEI'
          AND T.SL_ACCT_CD='KPEI'
          AND	T.RECORD_SOURCE IN ('CG','GL') 
          AND	T.APPROVED_STS = 'A' 
          AND T.REVERSAL_JUR = 'N'   
          GROUP BY SL_ACCT_CD
      )A,
      (SELECT 'K' KATEGORI,'KB' SUB_KATEGORI FROM DUAL
      UNION 
      SELECT 'K' KATEGORI,'KJ' SUB_KATEGORI FROM DUAL
      )B
      WHERE A.KATEGORI=B.KATEGORI
       GROUP BY B.SUB_KATEGORI;   
      EXCEPTION
      WHEN OTHERS THEN
      V_ERROR_CODE:=-10;
      V_ERROR_MSG:=SUBSTR('INSERT INTO TMP_CASH_FLOW_ESTIMASI KPEI/BROKER '||SQLERRM,1,200);
      RAISE V_ERR;
      END;



      FOR REC IN CSR_RETAIL LOOP

  		 
					IF REC.KATEGORI ='RR' THEN
						V_KATEGORI :='RRBRDN';
					ELSIF REC.KATEGORI ='RM' THEN
						V_KATEGORI :='RMBRDN';
					ELSIF REC.KATEGORI ='T' THEN
						V_KATEGORI :='TBRDN';
					ELSIF REC.KATEGORI ='IR' THEN
						V_KATEGORI :='IRB';
					END IF;

          BEGIN
					INSERT INTO TMP_CASH_FLOW_ESTIMASI(KATEGORI,MASUK,KELUAR,RAND_VALUE, USER_ID)
	  				VALUES(V_KATEGORI,DECODE(REC.KATEGORI,'IR',DECODE(SIGN(REC.AMT),1,REC.AMT,0),REC.EST_RDI), 0, P_RAND_VALUE,P_USER_ID);
         EXCEPTION
              WHEN OTHERS THEN
              V_ERROR_CODE:=-10;
              V_ERROR_MSG:=SUBSTR('INSERT INTO TMP_CASH_FLOW_ESTIMASI '||SQLERRM,1,200);
              RAISE V_ERR;
              END;

	 				IF REC.KATEGORI <> 'IR' THEN

						IF REC.KATEGORI ='RR' THEN
							V_KATEGORI :='RRBNSB';
						ELSIF REC.KATEGORI ='RM' THEN
							V_KATEGORI :='RMBNSB';
						ELSIF REC.KATEGORI ='T' THEN
							V_KATEGORI :='TBNSB';
						END IF;
							
           BEGIN
						INSERT INTO TMP_CASH_FLOW_ESTIMASI(KATEGORI,MASUK,KELUAR,RAND_VALUE, USER_ID)
		  				VALUES(V_KATEGORI,REC.EST_NASABAH, 0, P_RAND_VALUE,P_USER_ID);
            EXCEPTION
              WHEN OTHERS THEN
              V_ERROR_CODE:=-10;
              V_ERROR_MSG:=SUBSTR('INSERT INTO TMP_CASH_FLOW_ESTIMASI '||SQLERRM,1,200);
              RAISE V_ERR;
              END;
	  				END IF;

  		

	  			IF REC.KATEGORI ='RR' THEN
					V_KATEGORI :='RRJ';
				ELSIF REC.KATEGORI ='RM' THEN
					V_KATEGORI :='RMJ';
				ELSIF REC.KATEGORI ='T' THEN
					V_KATEGORI :='TJ';
				ELSIF REC.KATEGORI = 'IR' THEN
					V_KATEGORI :='IRJ';
				END IF;
				
        BEGIN
				INSERT INTO TMP_CASH_FLOW_ESTIMASI(KATEGORI,MASUK,KELUAR,RAND_VALUE, USER_ID)
  				VALUES(V_KATEGORI,0,ABS(REC.AMT),P_RAND_VALUE,P_USER_ID);
          EXCEPTION
              WHEN OTHERS THEN
              V_ERROR_CODE:=-10;
              V_ERROR_MSG:=SUBSTR('INSERT INTO TMP_CASH_FLOW_ESTIMASI '||SQLERRM,1,200);
              RAISE V_ERR;
              END;


      END LOOP;

		--FIXED INCOME ESTIMASI
    BEGIN
		INSERT INTO TMP_CASH_FLOW_ESTIMASI(KATEGORI,MASUK,KELUAR,RAND_VALUE, USER_ID)
		SELECT KATEGORI, SUM(SELL)masuk,SUM(BUY)keluar, P_RAND_VALUE,P_USER_ID
    FROM
      (
        SELECT DECODE(TRX_TYPE,'B','FB','FJ')KATEGORI,DECODE(TRX_TYPE,'S',NET_AMOUNT,0)SELL,DECODE(TRX_TYPE,'B',NET_AMOUNT,0)BUY
        FROM T_BOND_TRX
        WHERE T_BOND_TRX.approved_sts = 'A'
        AND T_BOND_TRX.lawan_type    <> 'I'
        AND nvl(journal_status,'X') = 'A'
        AND VALUE_DT                  =P_DUE_DATE
      )
    GROUP BY KATEGORI;
		  EXCEPTION
		WHEN OTHERS THEN
      V_ERROR_CODE:=-30;
      V_ERROR_MSG:=SUBSTR('INSERT INTO TMP_CASH_FLOW_ESTIMASI FIXED INCOME '||SQLERRM,1,200);
      RAISE V_ERR;
		END;

COMMIT;
P_ERROR_CD :=1;
P_ERROR_MSG :='';

EXCEPTION
WHEN V_ERR THEN
ROLLBACK;
P_ERROR_CD := V_ERROR_CODE;
P_ERROR_MSG := V_ERROR_MSG;
WHEN OTHERS THEN
P_ERROR_CD :=-1;
P_ERROR_MSG :=SUBSTR(SQLCODE||' '||SQLERRM,1,200);
RAISE;
END SP_CASH_FLOW_ESTIMASI;