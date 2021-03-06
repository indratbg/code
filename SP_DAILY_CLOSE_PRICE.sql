create or replace PROCEDURE SP_DAILY_CLOSE_PRICE(P_BGN_DATE DATE, P_END_DATE DATE,
P_ERROR_CODE OUT NUMBER,
P_ERROR_MSG OUT VARCHAR2) AS


V_ERR EXCEPTION;
V_ERROR_CD NUMBER;
V_ERROR_MSG VARCHAR2(200);

CURSOR CSR_STOCK IS
SELECT DISTINCT STK_CD
FROM
  (
    SELECT NVL(C.STK_CD_NEW,STK_CD)STK_CD
    FROM T_STK_MOVEMENT TMP, (
        SELECT STK_CD_NEW, STK_CD_OLD FROM T_CHANGE_STK_CD WHERE EFF_DT<= P_BGN_DATE
      )
      C
    WHERE DOC_DT BETWEEN P_BGN_DATE AND P_END_DATE
    AND STK_CD     =C.STK_CD_OLD(+)
    AND GL_ACCT_CD  IN ('36','09')
    AND DOC_STAT   = '2'
   -- AND STK_CD='MKNT'--UNTUK TEST
    UNION
    SELECT NVL(C.STK_CD_NEW,STK_CD)STK_CD
    FROM T_SECU_BAL, (
        SELECT STK_CD_NEW, STK_CD_OLD FROM T_CHANGE_STK_CD WHERE EFF_DT<= P_BGN_DATE
      )
      C
    WHERE BAL_DT    = P_BGN_DATE
    AND STK_CD      =C.STK_CD_OLD(+)
    --AND STK_CD='MKNT'--UNTUK TEST
  );

V_DAYS NUMBER;
V_RUNNING_DATE DATE;
V_PRICE NUMBER;
V_FOUNDED_FLG CHAR(1);
V_CUM_DATE DATE;
V_BGN_YEAR_DATE DATE;
BEGIN

	V_BGN_YEAR_DATE := TO_DATE('0101'||TO_CHAR(P_BGN_DATE,'YYYY'),'DDMMYYYY');

BEGIN
SELECT COUNT(1) INTO V_DAYS FROM T_DAILY_CLOS_PRICE WHERE STK_DATE BETWEEN P_BGN_DATE AND P_END_DATE;
EXCEPTION
WHEN OTHERS THEN
    V_ERROR_CD  := -15;
    V_ERROR_MSG := SUBSTR('SELECT COUNT T_DAILY_CLOS_PRICE '||SQLERRM(SQLCODE),1,200);
    RAISE V_ERR;
  END;

IF V_DAYS>0 THEN
	
	BEGIN
		DELETE FROM T_DAILY_CLOS_PRICE WHERE STK_DATE BETWEEN P_BGN_DATE AND P_END_DATE;
    EXCEPTION
	WHEN OTHERS THEN
    V_ERROR_CD  := -20;
    V_ERROR_MSG := SUBSTR('SELECT COUNT T_DAILY_CLOS_PRICE '||SQLERRM(SQLCODE),1,200);
    RAISE V_ERR;
  END;

END IF;


V_DAYS :=ROUND(TO_NUMBER(TO_CHAR(P_END_DATE,'DD')));

FOR REC IN CSR_STOCK LOOP
    V_RUNNING_DATE :=P_BGN_DATE;
    V_FOUNDED_FLG:='Y';
		FOR CNT_DAY IN 1..V_DAYS LOOP
		  
			IF (( F_IS_HOLIDAY(TO_CHAR(V_RUNNING_DATE,'DD/MM/YYYY')) = 0 AND CNT_DAY > 1) OR CNT_DAY = 1) AND V_FOUNDED_FLG='Y' THEN	
			--IF (( F_IS_HOLIDAY(TO_CHAR(V_RUNNING_DATE,'DD/MM/YYYY')) = 0 AND CNT_DAY > 1) OR CNT_DAY = 1) THEN	


					--JIKA STOCK SPLIT CLOS PRICE ANTARA X DATE - RECORDING DATE PAKE CLOS PRICE CUM DATE
					BEGIN
				      SELECT MAX(CUM_DT) INTO V_CUM_DATE FROM T_CORP_ACT WHERE CA_TYPE = 'SPLIT' AND STK_CD=REC.STK_CD
				      AND V_RUNNING_DATE BETWEEN X_DT AND RECORDING_DT AND APPROVED_STAT='A';
				    EXCEPTION
				      WHEN OTHERS THEN
				        V_ERROR_CD  := -72;
				        V_ERROR_MSG := SUBSTR('SELECT SPLIT FROM T_CORP_ACT '||SQLERRM(SQLCODE),1,200);
				        RAISE V_ERR;
				    END;

					 BEGIN
				      SELECT NVL(STK_CLOS,0) INTO V_PRICE FROM T_CLOSE_PRICE T 
				      JOIN (SELECT MAX(STK_DATE)STK_DATE FROM T_CLOSE_PRICE 
				      WHERE STK_DATE BETWEEN NVL(V_CUM_DATE,V_RUNNING_DATE)-30 AND NVL(V_CUM_DATE,V_RUNNING_DATE) 
				      AND STK_CD=REC.STK_CD )M
				      ON T.STK_DATE=M.STK_DATE
				      WHERE T.STK_CD=REC.STK_CD;
				      EXCEPTION
				      WHEN NO_DATA_FOUND THEN
				       V_PRICE:=0;
				       V_FOUNDED_FLG:='N';
				      WHEN OTHERS THEN
				        V_ERROR_CD  := -70;
				        V_ERROR_MSG := SUBSTR('SELECT CLOSE PRICE FROM T_CLOSE_PRICE '||NVL(V_CUM_DATE,V_RUNNING_DATE)||' '||REC.STK_CD||' '||SQLERRM(SQLCODE),1,200);
				        RAISE V_ERR;
				      END;

				    IF V_PRICE =0 THEN
				    BEGIN
				     SELECT  NVL(PRICE,0) INTO V_PRICE FROM T_PEE 
				      WHERE DISTRIB_DT_FR<=V_RUNNING_DATE AND STK_CD_KSEI=REC.STK_CD;
				    EXCEPTION
				    WHEN NO_DATA_FOUND THEN
				       V_PRICE:=0;
				      WHEN OTHERS THEN
				        V_ERROR_CD  := -80;
				        V_ERROR_MSG := SUBSTR('SELECT CLOSE PRICE FROM T_PEE '||V_RUNNING_DATE||' '||REC.STK_CD||' '||SQLERRM(SQLCODE),1,200);
				        RAISE V_ERR;
				      END;
				  END IF;
				  
				  IF V_PRICE =0 THEN
				  BEGIN
				  SELECT NVL(PRICE/100,0) INTO V_PRICE FROM T_BOND_PRICE T
				   JOIN (SELECT MAX(PRICE_DT)PRICE_DT FROM T_BOND_PRICE 
			      WHERE PRICE_DT <= V_RUNNING_DATE AND BOND_CD=REC.STK_CD)M
			      ON T.PRICE_DT=M.PRICE_DT
			      WHERE BOND_CD=REC.STK_CD;
			       EXCEPTION
				    WHEN NO_DATA_FOUND THEN
				       V_PRICE:=0;
				      WHEN OTHERS THEN
				        V_ERROR_CD  := -90;
				        V_ERROR_MSG := SUBSTR('SELECT CLOSE PRICE FROM T_BOND_PRICE '||V_RUNNING_DATE||' '||REC.STK_CD||' '||SQLERRM(SQLCODE),1,200);
				        RAISE V_ERR;
				      END;
				  END IF;


   		 END IF; --END IF GET CLOSE PRICE

   		 --UNTUK SAHAM DELISTING PRICE=0
   		 
			IF V_FOUNDED_FLG='N' THEN
		      	 BEGIN
				      SELECT NVL(STK_CLOS,0) INTO V_PRICE FROM T_CLOSE_PRICE T 
				      JOIN (SELECT MAX(STK_DATE)STK_DATE FROM T_CLOSE_PRICE 
				      WHERE STK_DATE BETWEEN  V_BGN_YEAR_DATE AND V_RUNNING_DATE 
				      AND STK_CD=REC.STK_CD )M
				      ON T.STK_DATE=M.STK_DATE
				      WHERE T.STK_CD=REC.STK_CD;
				      EXCEPTION
				      WHEN NO_DATA_FOUND THEN
				       V_PRICE:=0;
				      WHEN OTHERS THEN
				        V_ERROR_CD  := -91;
				        V_ERROR_MSG := SUBSTR('SELECT CLOSE PRICE FROM T_CLOSE_PRICE '||V_RUNNING_DATE||' '||REC.STK_CD||' '||SQLERRM(SQLCODE),1,200);
				        RAISE V_ERR;
				      END;

				      V_FOUNDED_FLG :='Y';
		      END IF;

		  	BEGIN
			INSERT INTO T_DAILY_CLOS_PRICE(STK_DATE,STK_CD,STK_CLOS,GENERATE_DATE)VALUES(V_RUNNING_DATE,REC.STK_CD,V_PRICE,SYSDATE);
			   EXCEPTION
		      WHEN OTHERS THEN
		        V_ERROR_CD  := -95;
		        V_ERROR_MSG := SUBSTR('INSERT INTO T_DAILY_CLOS_PRICE '||SQLERRM(SQLCODE),1,200);
		        RAISE V_ERR;
		      END;

		 
		V_RUNNING_DATE :=V_RUNNING_DATE+1;
	END LOOP;--END LOOP CNT DAYS

END LOOP; --END LOOP CURSOR STOCK
P_ERROR_CODE :=1;
		P_ERROR_MSG :='';

EXCEPTION
WHEN V_ERR THEN
	P_ERROR_CODE :=V_ERROR_CD;
	P_ERROR_MSG := V_ERROR_MSG;
	WHEN OTHERS THEN
		P_ERROR_CODE :=-1;
		P_ERROR_MSG := SUBSTR(SQLERRM,1,200);
END SP_DAILY_CLOSE_PRICE;