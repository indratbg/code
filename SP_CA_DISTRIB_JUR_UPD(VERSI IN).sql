create or replace 
PROCEDURE SP_CA_DISTRIB_JUR_UPD(
                        P_TODAY_DT 				  DATE,
                        P_CUM_DT 				  	   T_CORP_ACT.CUM_DT%TYPE,
                        P_X_DT 					  			T_CORP_ACT.X_DT%TYPE,
                        P_RECORDING_DT 		T_CORP_ACT.DISTRIB_DT%TYPE,
                        P_DISTRIB_DT 				T_CORP_ACT.RECORDING_DT%TYPE,
                        P_CA_TYPE 						T_CORP_ACT.CA_TYPE%TYPE,
                        P_STK_CD 						T_STK_MOVEMENT.STK_CD%TYPE,
                      	P_JUR_TYPE					T_STK_MOVEMENT.JUR_TYPE%TYPE,	
                        P_REMARKS 					T_STK_MOVEMENT.DOC_REM%TYPE,
                        P_MANUAL 					   T_STK_MOVEMENT.MANUAL%TYPE,
                        P_USER_ID						T_STK_MOVEMENT.USER_ID%TYPE,
                        P_MENU_NAME 			T_MANY_HEADER.MENU_NAME%TYPE,
                        P_IP_ADDRESS 			T_MANY_HEADER.IP_ADDRESS%TYPE,
                        P_ERRCD	 							OUT NUMBER,
                        P_ERRMSG	 					OUT VARCHAR2
                        ) IS

tmpVar NUMBER;
/******************************************************************************
   NAME:       SP_CA_DISTRIB_JUR_UPD
   PURPOSE: corporate action jurnal yg dijurnal hanya pada Distribution date    

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        13/08/2015          1. Created this procedure.

   NOTES:

   

******************************************************************************/

V_BGN_DT							DATE;  									   
V_TODAY								  DATE:=TRUNC(SYSDATE);
V_STK_CD T_STK_MOVEMENT.STK_CD%TYPE;
  CURSOR CSR_DATA(A_STK_CD T_STK_MOVEMENT.STK_CD%TYPE) IS
SELECT  CA_TYPE, p_stk_cd, CUM_DT,X_DT,RECORDING_DT,
				 DISTRIB_DT ,CLIENT_CD, CLIENT_NAME, BRANCH_CODE,CLIENT_TYPE,
     			 FROM_QTY, TO_QTY,BEGIN_QTY, RECV_QTY,	 END_QTY,
	 			 CUM_BEGIN_QTY,	CUM_RECV_QTY, CUM_END_QTY,
				  FLOOR((BEGIN_QTY - CUM_BEGIN_QTY)  * TO_QTY/FROM_QTY)  SEL_RECV,
				 END_QTY - CUM_END_QTY AS SEL_END_QTY,
				 (END_QTY - CUM_END_QTY)  -  (  begin_qty -  cum_begin_qty)  AS  SEL_SPLIT_REVERSE
FROM(
	SELECT  A.CLIENT_CD, A.STK_CD, CA_TYPE, FROM_QTY, TO_QTY,  CLIENT_TYPE,
	    BEGIN_QTY,
		FLOOR(A.BEGIN_QTY * TO_QTY/FROM_QTY) RECV_QTY,
		DECODE(C.CA_TYPE,'SPLIT',0,'REVERSE',0,A.BEGIN_QTY) +FLOOR(A.BEGIN_QTY * TO_QTY/FROM_QTY) END_QTY,
		CUM_BEGIN_QTY,
		FLOOR(CUM_BEGIN_QTY * TO_QTY/FROM_QTY) CUM_RECV_QTY,
		DECODE(C.CA_TYPE,'SPLIT',0,'REVERSE',0,CUM_BEGIN_QTY) + FLOOR(CUM_BEGIN_QTY * TO_QTY/FROM_QTY) CUM_END_QTY,
		M.CLIENT_NAME, M.BRANCH_CODE	,C.DISTRIB_DT, C.X_DT, C.RECORDING_DT, C.CUM_DT
	FROM(
	SELECT CLIENT_CD, STK_CD,
		   SUM( NVL(MVMT_QTY,0)) BEGIN_QTY,
		   SUM(NVL(CUM_QTY,0))  CUM_BEGIN_QTY
	FROM(
		SELECT CLIENT_CD, STK_CD,  MVMT_QTY,
		   	DECODE(SIGN(DOC_DT - P_CUM_DT), 1, 0, MVMT_QTY) CUM_QTY
		FROM(
			   SELECT DOC_DT,  CLIENT_CD, STK_CD,
				  DECODE(SUBSTR(DOC_NUM,5,2),'BR',1,'JR',1,'BI',1,'JI',1,'BO',1,'JO',1,'RS',1,'WS',1,0) *
				  DECODE(DB_CR_FLG,'D',1,-1) *  (TOTAL_SHARE_QTY + WITHDRAWN_SHARE_QTY) MVMT_QTY
			      FROM IPNEXTG.T_STK_MOVEMENT
				  WHERE DOC_DT BETWEEN V_BGN_DT AND P_RECORDING_DT
				  AND DOC_DT <= V_TODAY
				AND STK_CD = A_STK_CD--DECODE(P_CA_TYPE,'RIGHT',SUBSTR(P_STK_CD,1,4),'WARRANT',SUBSTR(P_STK_CD,1,4),P_STK_CD)
				AND TRIM(GL_ACCT_CD) IN ('10','12','13','14','51')
				AND DOC_STAT    = '2'
				AND DUE_DT_FOR_CERT <= P_RECORDING_DT
        AND s_d_type NOT  IN  ('H','B','S','R'))
		 UNION ALL
		SELECT  CLIENT_CD, STK_CD, BEG_BAL_QTY, BEG_BAL_QTY
			FROM IPNEXTG.T_STKBAL
			WHERE BAL_DT = V_BGN_DT
			AND STK_CD =A_STK_CD-- DECODE(P_CA_TYPE,'RIGHT',SUBSTR(P_STK_CD,1,4),'WARRANT',SUBSTR(P_STK_CD,1,4),P_STK_CD)
      )
	GROUP BY  CLIENT_CD, STK_CD
	HAVING  SUM(MVMT_QTY) > 0
	) A,
	( SELECT CLIENT_CD,  DECODE(CLIENT_CD, C.COY_CLIENT_CD,'H', DECODE(CLIENT_TYPE_1,'H','H','%')) AS CLIENT_TYPE,CLIENT_NAME,BRANCH_CODE
	  FROM IPNEXTG.MST_CLIENT,
		  ( SELECT TRIM(OTHER_1) COY_CLIENT_CD FROM IPNEXTG.MST_COMPANY) C
	  WHERE CLIENT_TYPE_1 <> 'B'	AND custodian_cd IS NULL
	 ) M,
	  ( SELECT STK_CD, CA_TYPE, FROM_QTY, TO_QTY, DISTRIB_DT,X_DT, RECORDING_DT, CUM_DT
	     FROM IPNEXTG.T_CORP_ACT
	 WHERE STK_CD= A_STK_CD--DECODE(P_CA_TYPE,'RIGHT',SUBSTR(P_STK_CD,1,4),'WARRANT',SUBSTR(P_STK_CD,1,4),P_STK_CD)
	 AND CUM_DT = P_CUM_DT
	 AND CA_TYPE = P_CA_TYPE
	AND APPROVED_STAT = 'A') C
WHERE A.CLIENT_CD = M.CLIENT_CD
AND A.STK_CD = C.STK_CD);



V_ERR			EXCEPTION;
  V_ERR_CD NUMBER;
  V_ERR_MSG VARCHAR2(200);
  
    V_DOC_NUM T_STK_MOVEMENT.DOC_NUM%TYPE;
  V_DOC_DATE T_STK_MOVEMENT.DOC_DT%TYPE :=P_DISTRIB_DT;
  V_SD_TYPE T_STK_MOVEMENT.S_D_TYPE%TYPE;
  V_LOT_SIZE T_STK_MOVEMENT.WITHDRAWN_SHARE_QTY%TYPE;
  V_TOTAL_LOT T_STK_MOVEMENT.TOTAL_LOT%TYPE;
  V_QTY T_STK_MOVEMENT.WITHDRAWN_SHARE_QTY%TYPE;
  V_REMARKS T_STK_MOVEMENT.DOC_REM%TYPE;
  V_TOTAL_SHARE_QTY T_STK_MOVEMENT.TOTAL_SHARE_QTY%TYPE;
    V_WITHDRAWN_SHARE_QTY T_STK_MOVEMENT.TOTAL_SHARE_QTY%TYPE;
  V_GL_ACCT_CD T_STK_MOVEMENT.GL_ACCT_CD%TYPE;
  V_PRICE T_STK_MOVEMENT.PRICE%TYPE:=0;
  V_AVG_PRICE  T_STK_MOVEMENT.PRICE%TYPE;
  V_UPDATE_DATE T_MANY_HEADER.UPDATE_DATE%TYPE;
  V_UPDATE_SEQ 	T_MANY_HEADER.UPDATE_SEQ%TYPE;
  V_DOC_TYPE VARCHAR2(3);
  V_JUR_TYPE T_STK_MOVEMENT.JUR_TYPE%TYPE;
  V_ODD_LOT_DOC T_STK_MOVEMENT.ODD_LOT_DOC%TYPE;
  V_DB_CR_FLG T_STK_MOVEMENT.DB_CR_FLG%TYPE;
  V_CLIENT_TYPE MST_CLIENT.CLIENT_TYPE_1%TYPE;
  V_MENU_NAME T_MANY_HEADER.menu_name%TYPE :=P_MENU_NAME;

  V_DEB_GL_ACCT_CD T_STK_MOVEMENT.GL_ACCT_CD%TYPE;
  V_CRE_GL_ACCT_CD T_STK_MOVEMENT.GL_ACCT_CD%TYPE;


  
v_jur_type_suffix MST_SYS_PARAM.dflg1%TYPE;
v_bal_dt		  						   DATE;  
V_cnt									   NUMBER;
 
BEGIN

	--S_D_TYPE and JUR TYPE
	IF P_CA_TYPE = 'RIGHT' OR P_CA_TYPE='WARRANT' THEN
		 V_SD_TYPE := 'H';
		 V_JUR_TYPE := 'HMETDN';
		 V_STK_CD := SUBSTR(P_STK_CD,1,4);
	ELSIF P_CA_TYPE = 'BONUS' OR P_CA_TYPE='STKDIV' THEN
		V_SD_TYPE := 'B';
		V_JUR_TYPE := P_CA_TYPE||'N';
		 V_STK_CD := P_STK_CD;
	ELSIF P_CA_TYPE = 'SPLIT' THEN
		V_SD_TYPE := 'S';
		V_JUR_TYPE := P_CA_TYPE||'N';
		V_STK_CD := P_STK_CD;
	ELSE--REVERSE
		V_SD_TYPE := 'R';
		V_JUR_TYPE := P_CA_TYPE||'N';
		V_STK_CD := P_STK_CD;
	END IF;
	
	
	
    BEGIN
    SELECT COUNT(1) INTO V_CNT FROM T_STK_MOVEMENT WHERE
    DOC_DT=P_DISTRIB_DT AND
    STK_CD =P_STK_CD AND
	DOC_STAT='2' AND 
    s_d_type IN ('S','R','H','B')and 
	 JUR_TYPE = V_JUR_TYPE and
	 SEQNO=1;
    EXCEPTION
      WHEN OTHERS THEN
      V_ERR_CD := -2;
      V_ERR_MSG :=SUBSTR('T_STK_MOVEMENT  '||SQLERRM(SQLCODE),1,200);
      RAISE V_ERR;
		END;
  IF V_CNT>0 THEN
			V_ERR_CD := -3;
			V_ERR_MSG :='Jurnal '||P_CA_TYPE||'  '||P_STK_CD||' sudah ada';
			RAISE V_ERR;
		END IF;




	 v_jur_type_suffix := SUBSTR( p_jur_type, LENGTH(p_jur_type), 1);

	 IF v_jur_type_suffix  ='C' THEN
		v_bal_dt	 := TO_DATE('01/'||TO_CHAR(P_CUM_DT,'MM/YYYY'),'DD/MM/YYYY');
	ELSIF  v_jur_type_suffix ='X' THEN
		v_bal_dt	 := TO_DATE('01/'||TO_CHAR(P_X_DT,'MM/YYYY'),'DD/MM/YYYY');
	ELSE
		v_bal_dt	 := TO_DATE('01/'||TO_CHAR(P_DISTRIB_DT,'MM/YYYY'),'DD/MM/YYYY');
	END IF;


	 BEGIN
			SELECT COUNT(1) INTO V_CNT FROM T_STKBAL WHERE BAL_DT = v_bal_dt;
		EXCEPTION
		WHEN OTHERS THEN
		V_ERR_CD := -4;
		V_ERR_MSG :=SUBSTR('T_STKBAL  '||SQLERRM(SQLCODE),1,200);
		RAISE V_ERR;
		END;
		IF V_CNT=0 THEN
			V_ERR_CD := -5;
			V_ERR_MSG :='Belum month end, proses batal ';
			RAISE V_ERR;
		END IF;
   
 		V_BGN_DT := TO_DATE('01/'||TO_CHAR(P_CUM_DT,'MM/YYYY'),'DD/MM/YYYY');

		BEGIN
		SELECT LOT_SIZE INTO V_LOT_SIZE 
		FROM MST_COUNTER 
		WHERE STK_CD = P_STK_CD;--DECODE(P_CA_TYPE,'RIGHT',SUBSTR(P_STK_CD,1,4),'WARRANT',SUBSTR(P_STK_CD,1,4),P_STK_CD);
		EXCEPTION
		WHEN NO_DATA_FOUND THEN
		v_lot_size := 100;
				WHEN OTHERS THEN
					 V_ERR_CD := -7;
					 V_ERR_MSG := SUBSTR('MST_COUNTER  '||SQLERRM(SQLCODE),1,200);
					RAISE V_ERR;
			END;

	
  

  		 FOR REC IN CSR_DATA(V_STK_CD) LOOP

		 	 	 V_REMARKS := REPLACE(REPLACE(P_REMARKS,'?C',REC.CLIENT_CD),'?S',P_STK_CD);
   
   				  BEGIN
		        Sp_T_Many_Header_Insert(V_MENU_NAME,
		                               'I',
		                               P_USER_ID,
		                               P_IP_ADDRESS,
		                               NULL,
		                               V_UPDATE_DATE,
		                               V_UPDATE_SEQ,
		                               V_ERR_CD,
		                               V_ERR_MSG);
		        EXCEPTION
		              WHEN OTHERS THEN
		                 V_ERR_CD := -20;
		                 V_ERR_MSG := SUBSTR('SP_T_MANY_HEADER_INSERT '|| SQLERRM(SQLCODE),1,200);
		                RAISE V_ERR;
		            END;

					
					IF P_Ca_type = 'REVERSE' THEN 
					   			 		V_QTY := rec.BEGIN_QTY - rec.END_QTY;
					ELSIF P_Ca_type = 'SPLIT' THEN 			
						  			   V_QTY :=  rec.END_QTY - rec.BEGIN_QTY;
					ELSE
									      V_QTY :=  rec.RECV_QTY;
					END IF;					  

					IF MOD(V_QTY,V_LOT_SIZE) = 0 THEN
						V_ODD_LOT_DOC :='N';
					ELSE
						V_ODD_LOT_DOC :='Y';
					END IF;
					V_TOTAL_LOT := TRUNC(V_QTY/V_LOT_SIZE);

					
					IF P_Ca_type = 'REVERSE' THEN 
										V_DOC_TYPE :='WSN';
										V_TOTAL_SHARE_QTY := 0;
										V_WITHDRAWN_SHARE_QTY :=V_QTY;
					ELSE
										V_DOC_TYPE :='RSN';
										V_TOTAL_SHARE_QTY := V_QTY;
										V_WITHDRAWN_SHARE_QTY :=0;
										
					END IF;
					
					V_DOC_NUM := Get_Stk_Jurnum(  P_DISTRIB_DT,V_DOC_TYPE );
					
					--GET GL_ACCT_CD
			      BEGIN
			      Sp_Get_Secu_Acct ( V_DOC_DATE,
	                             REC.CLIENT_TYPE,
	                             V_JUR_TYPE,
	                             V_DEB_GL_ACCT_CD,
	                             V_CRE_GL_ACCT_CD,
	                             V_ERR_CD,
	                             V_ERR_MSG);
			      EXCEPTION
			        WHEN OTHERS THEN
				        V_ERR_CD := -10;
				        V_ERR_MSG :=SUBSTR('SP_GET_SECU_ACCT  '||SQLERRM(SQLCODE),1,200);
				        RAISE V_ERR;
			      END;
			      IF V_ERR_CD<0 THEN
				        V_ERR_CD := -15;
				        V_ERR_MSG :=SUBSTR('SP_GET_SECU_ACCT  '||V_ERR_MSG||SQLERRM(SQLCODE),1,200);
				        RAISE V_ERR;
			      END IF;


				FOR I IN 1..2 LOOP
						IF I = 1 THEN
							V_GL_ACCT_CD := V_DEB_GL_ACCT_CD;
							V_DB_CR_FLG := 'D';
						ELSE
							V_GL_ACCT_CD := V_CRE_GL_ACCT_CD;
							V_DB_CR_FLG := 'C';
						END IF;
	
						BEGIN
						Sp_T_Stk_Movement_Upd(	V_DOC_NUM,--SEARCH DOC_NUM
	                                  V_DB_CR_FLG,--DB_CR_FLG
	                                  I,--SEQNO
	                                  V_DOC_NUM,--DOC_NUM
	                                  NULL,--REF DOC NUM
	                                  V_DOC_DATE,--DOC_DT
	                                  REC.CLIENT_CD,--CLIENT_CD
	                                  P_STK_CD,--STK_CD
	                                  V_SD_TYPE,--S_D_TYPE
	                                  V_ODD_LOT_DOC,--ODD LOT DOC
	                                  V_TOTAL_LOT,--TOTAL LOT
	                                  V_TOTAL_SHARE_QTY,--TOTAL SHARE QTY
	                                  V_REMARKS,--DOC REM
	                                  '2',--DOC_STAT
	                                  V_WITHDRAWN_SHARE_QTY,--WITHDRAWN_SHARE_QTY
	                                  NULL,--REGD_HLDR
	                                  NULL,--WITHDRAW_REASON_CD
	                                  V_GL_ACCT_CD,--GL_ACCT_CD
	                                  NULL,--ACCT_TYPE
	                                  V_DB_CR_FLG,--DB_CR_FLG
	                                  'L',--STATUS
	                                  V_DOC_DATE,--DUE_DT_FOR_CERT
	                                  NULL,--STK_STAT
	                                  NULL,--DUE_DT_ONHAND
	                                  I,--SEQNO
	                                  V_PRICE,--PRICE
	                                  NULL,--PREV_DOC_NUM
	                                  P_MANUAL,--MANUAL
	                                  V_JUR_TYPE,--JUR_TYPE
	                                  NULL,--BROKER
	                                  NULL,--P_REPO_REF,
	                                  NULL,--RATIO
	                                  NULL,--RATIO_REASON
	                                  P_USER_ID,--USER ID
	                                  SYSDATE,--CRE_DT
	                                  NULL,--P_UPD_BY,
	                                  NULL,--P_UPD_DT,
	                                  'I',--P_UPD_STATUS,
	                                  P_IP_ADDRESS,
	                                  NULL,--P_CANCEL_REASON,
	                                  V_UPDATE_DATE,--UPDATE DATE
	                                  V_UPDATE_SEQ,--UPDATE_SEQ
	                                  I,--RECORD SEQ
	                                  V_ERR_CD,
	                                  V_ERR_MSG);
	
						EXCEPTION
							WHEN OTHERS THEN
								 V_ERR_CD := -25;
								 V_ERR_MSG :=SUBSTR('SP_T_STK_MOVEMENT_UPD '||SQLERRM(SQLCODE),1,200);
								RAISE V_ERR;
						END;
	
						IF V_ERR_CD < 0 THEN
						    V_ERR_CD := -30;
							V_ERR_MSG := SUBSTR('SP_T_STK_MOVEMENT_UPD '||V_ERR_MSG,1,200);
							RAISE V_ERR;
						END IF;
	
			  END LOOP; --END LOOP JURNAL 

					
					
   		END LOOP;
		
      P_ERRCD := 1;
    P_ERRMSG := '';

EXCEPTION
    WHEN V_ERR THEN
        ROLLBACK;
         P_ERRCD := V_ERR_CD;
        P_ERRMSG := V_ERR_MSG;
    WHEN OTHERS THEN
       ROLLBACK;
        P_ERRCD := -1;
        P_ERRMSG := SUBSTR(SQLERRM(SQLCODE),1,200);
END SP_CA_DISTRIB_JUR_UPD;