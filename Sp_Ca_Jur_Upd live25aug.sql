create or replace 
PROCEDURE Sp_Ca_Jur_Upd(P_RECORDING_DT DATE,
                        P_BGN_DT DATE,
                        P_TODAY_DT DATE,
                        P_CUM_DT T_CORP_ACT.CUM_DT%TYPE,
                        P_X_DT T_CORP_ACT.X_DT%TYPE,
                        P_CA_TYPE T_CORP_ACT.CA_TYPE%TYPE,
                        P_STK_CD T_STK_MOVEMENT.STK_CD%TYPE,
                        P_USER_ID			T_STK_MOVEMENT.USER_ID%TYPE,
                        P_IP_ADDRESS T_MANY_HEADER.IP_ADDRESS%TYPE,
                        P_REMARKS T_STK_MOVEMENT.DOC_REM%TYPE,
                        P_JOURNAL CHAR,
                        P_MENU_NAME VARCHAR2,
                        P_MANUAL VARCHAR2,
                     --   P_PRICE NUMBER,
                        P_ERRCD	 		OUT NUMBER,
                        P_ERRMSG	 		OUT VARCHAR2
                        ) IS

  V_ERR			EXCEPTION;
  V_ERR_CD NUMBER;
  V_ERR_MSG VARCHAR2(200);
  V_DOC_NUM T_STK_MOVEMENT.DOC_NUM%TYPE;
  V_DOC_DATE T_STK_MOVEMENT.DOC_DT%TYPE;
  V_SD_TYPE T_STK_MOVEMENT.S_D_TYPE%TYPE;
  V_LOT_SIZE T_STK_MOVEMENT.WITHDRAWN_SHARE_QTY%TYPE;
  V_TOTAL_LOT T_STK_MOVEMENT.TOTAL_LOT%TYPE;
  V_QTY T_STK_MOVEMENT.WITHDRAWN_SHARE_QTY%TYPE;
  V_REMARKS T_STK_MOVEMENT.DOC_REM%TYPE;
  V_WITHDRAWN_SHARE_QTY NUMBER(10);
  V_GL_ACCT_CD T_STK_MOVEMENT.GL_ACCT_CD%TYPE;
  V_PRICE T_STK_MOVEMENT.PRICE%TYPE:=0;
  V_AVG_PRICE  T_STK_MOVEMENT.PRICE%TYPE;
  V_UPDATE_DATE T_MANY_HEADER.UPDATE_DATE%TYPE;
  V_UPDATE_SEQ 	T_MANY_HEADER.UPDATE_SEQ%TYPE;
  V_DOC_TYPE VARCHAR2(3);
  V_JUR_TYPE T_STK_MOVEMENT.JUR_TYPE%TYPE;
  V_ODD_LOT_DOC T_STK_MOVEMENT.ODD_LOT_DOC%TYPE;
  V_DB_CR_FLG T_STK_MOVEMENT.DB_CR_FLG%TYPE;
  V_TOTAL_SHARE_QTY T_STK_MOVEMENT.TOTAL_SHARE_QTY%TYPE;
  V_CLIENT_TYPE MST_CLIENT.CLIENT_TYPE_1%TYPE;
  V_MENU_NAME VARCHAR2(30):=P_MENU_NAME;
  V_TODAY DATE :=P_TODAY_DT;
  V_DEB_GL_ACCT_CD VARCHAR2(5);
  V_CRE_GL_ACCT_CD VARCHAR2(5);
  V_BGN_DT DATE;
  V_CNT NUMBER;
  V_DISTRIB_DT DATE;
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
				  WHERE DOC_DT BETWEEN P_BGN_DT AND P_RECORDING_DT
				  AND DOC_DT <= V_TODAY
				AND STK_CD = A_STK_CD--DECODE(P_CA_TYPE,'RIGHT',SUBSTR(P_STK_CD,1,4),'WARRANT',SUBSTR(P_STK_CD,1,4),P_STK_CD)
				AND TRIM(GL_ACCT_CD) IN ('10','12','13','14','51')
				AND DOC_STAT    = '2'
				AND DUE_DT_FOR_CERT <= P_RECORDING_DT
        AND s_d_type NOT  IN  ('H','B','S','R'))
		 UNION ALL
		SELECT  CLIENT_CD, STK_CD, BEG_BAL_QTY, BEG_BAL_QTY
			FROM IPNEXTG.T_STKBAL
			WHERE BAL_DT = P_BGN_DT
			AND STK_CD = A_STK_CD--DECODE(P_CA_TYPE,'RIGHT',SUBSTR(P_STK_CD,1,4),'WARRANT',SUBSTR(P_STK_CD,1,4),P_STK_CD)
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


BEGIN


	BEGIN
		SELECT DISTRIB_DT INTO V_DISTRIB_DT
		FROM T_CORP_ACT
		WHERE STK_CD = DECODE(P_CA_TYPE,'RIGHT',SUBSTR(P_STK_CD,1,4),'WARRANT',SUBSTR(P_STK_CD,1,4),P_STK_CD)
		AND CA_TYPE = P_CA_TYPE
		AND x_dt = P_X_DT;
	EXCEPTION
			WHEN OTHERS THEN
			V_ERR_CD := -6;
			V_ERR_MSG :=SUBSTR('T_CORP_ACT  '||SQLERRM(SQLCODE),1,200);
			RAISE V_ERR;
			END;

	IF P_JOURNAL ='C' THEN
		V_BGN_DT := TO_DATE('01/'||TO_CHAR(P_CUM_DT,'MM/YYYY'),'DD/MM/YYYY');
	ELSIF P_JOURNAL ='X' THEN
		V_BGN_DT := TO_DATE('01/'||TO_CHAR(P_X_DT,'MM/YYYY'),'DD/MM/YYYY');
	ELSE
		V_BGN_DT := TO_DATE('01/'||TO_CHAR(V_DISTRIB_DT,'MM/YYYY'),'DD/MM/YYYY');
	END IF;


	 BEGIN
			SELECT COUNT(1) INTO V_CNT FROM T_STKBAL WHERE BAL_DT = V_BGN_DT;
		EXCEPTION
		WHEN OTHERS THEN
		V_ERR_CD := -4;
		V_ERR_MSG :=SUBSTR('T_STKBAL  '||SQLERRM(SQLCODE),1,200);
		RAISE V_ERR;
		END;
		IF V_CNT=0 THEN
			V_ERR_CD := -5;
			V_ERR_MSG :='Belum month end ';
			RAISE V_ERR;
		END IF;


		V_BGN_DT := TO_DATE('01/'||TO_CHAR(P_CUM_DT,'MM/YYYY'),'DD/MM/YYYY');



		BEGIN
		SELECT LOT_SIZE INTO V_LOT_SIZE FROM MST_COUNTER WHERE STK_CD = DECODE(P_CA_TYPE,'RIGHT',SUBSTR(P_STK_CD,1,4),'WARRANT',SUBSTR(P_STK_CD,1,4),P_STK_CD);
		EXCEPTION
		WHEN NO_DATA_FOUND THEN
		v_lot_size := 100;
				WHEN OTHERS THEN
					 V_ERR_CD := -7;
					 V_ERR_MSG := SUBSTR('MST_COUNTER  '||SQLERRM(SQLCODE),1,200);
					RAISE V_ERR;
			END;

		--S_D_TYPE
		IF P_CA_TYPE = 'RIGHT' OR P_CA_TYPE='WARRANT' THEN
		V_SD_TYPE := 'H';
		V_STK_CD := SUBSTR(P_STK_CD,1,4);
		ELSIF P_CA_TYPE = 'BONUS' OR P_CA_TYPE='STKDIV' THEN
		V_SD_TYPE := 'B';
		V_STK_CD := P_STK_CD;
		ELSIF P_CA_TYPE = 'SPLIT' THEN
			V_SD_TYPE := 'S';
			V_STK_CD := P_STK_CD;
		ELSE--REVERSE
			V_SD_TYPE := 'R';
			V_STK_CD := P_STK_CD;
		END IF;

		--SET JUR TYPE
		IF P_JOURNAL='C' THEN
			V_DOC_DATE :=P_CUM_DT;
			IF P_CA_TYPE ='RIGHT' OR P_CA_TYPE='WARRANT' THEN
					V_JUR_TYPE :='HMETDC';
			ELSIF P_CA_TYPE='BONUS' THEN
					V_JUR_TYPE :='BONUSC';
			ELSE
					V_JUR_TYPE := 'STKDIVC';
			END IF;
		ELSIF P_JOURNAL='X' THEN
			V_DOC_DATE :=P_X_DT;
		ELSE--PADA DISTRIBUTION DATE
			V_DOC_DATE :=V_DISTRIB_DT;
			IF P_CA_TYPE ='RIGHT' OR P_CA_TYPE='WARRANT' THEN
				V_JUR_TYPE :='HMETDD';
			ELSIF P_CA_TYPE='BONUS' THEN
				V_JUR_TYPE :='BONUSD';
			ELSIF P_CA_TYPE='STKDIV' THEN
				V_JUR_TYPE := 'STKDIVD';
			ELSIF P_CA_TYPE = 'SPLIT' THEN
				V_JUR_TYPE :='SPLITD';
			ELSE
				V_JUR_TYPE :='REVERSED';
			END IF;

		END IF;




  FOR REC IN CSR_DATA(V_STK_CD) LOOP

		V_REMARKS := REPLACE(REPLACE(P_REMARKS,'?C',REC.CLIENT_CD),'?S',P_STK_CD);
--    IF P_CA_TYPE = 'STKDIV' THEN
--    V_PRICE := P_PRICE;
--    ELSE
--    V_PRICE :=0;
--    END IF;

		--EXECUTE SP HEADER
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

 	--JURNAL PADA CUM DATE UNTUK CA TYPE RIGHT, WARRANT, BONUS, STKDIV
	IF P_JOURNAL = 'C' AND (P_CA_TYPE = 'RIGHT' OR P_CA_TYPE = 'WARRANT' OR P_CA_TYPE = 'BONUS' OR P_CA_TYPE = 'STKDIV') THEN
			--GET DOC NUM
			V_DOC_TYPE :='RSN';
			V_DOC_NUM := Get_Stk_Jurnum(  P_CUM_DT,V_DOC_TYPE );
			V_QTY :=REC.CUM_RECV_QTY;
			IF MOD(V_QTY,V_LOT_SIZE) = 0 THEN
				V_ODD_LOT_DOC :='N';
			ELSE
				V_ODD_LOT_DOC :='Y';
			END IF;
			V_TOTAL_LOT := TRUNC(V_QTY/V_LOT_SIZE);
			V_TOTAL_SHARE_QTY :=V_QTY;
			V_WITHDRAWN_SHARE_QTY :=0;

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

		  END LOOP; --END LOOP JURNAL PADA CUM DATE UNTUK RIGHT, WARRANT, BONUS, STKDIV
	END IF; --END JURNAL PADA CUM DATE UNTUK RIGHT, WARRANT, BONUS, STKDIV

	--JURNAL PADA X DATE UNTUK SPLIT DAN REVERSE (WHDR)
	IF P_JOURNAL = 'X' AND (P_CA_TYPE ='SPLIT' OR P_CA_TYPE='REVERSE') THEN
	--JURNAL X DATE UNTUK TYPE WHDR
	--GET DOC NUM
			V_DOC_TYPE :='WSN';

			V_DOC_NUM := Get_Stk_Jurnum( P_X_DT ,V_DOC_TYPE );

			V_QTY :=REC.CUM_BEGIN_QTY;--JURNAL PERTAMA UNTUK SPLIT ATAU REVERSE(WHDR)
				IF MOD(V_QTY,V_LOT_SIZE) = 0 THEN
					V_ODD_LOT_DOC :='N';
				ELSE
					V_ODD_LOT_DOC :='Y';
				END IF;
			V_TOTAL_LOT := TRUNC(V_QTY/V_LOT_SIZE);
			V_TOTAL_SHARE_QTY :=0;
			V_WITHDRAWN_SHARE_QTY :=V_QTY;
			--V_JUR_TYPE :='WHDR';
			V_JUR_TYPE := p_ca_type||'W';


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
		        V_ERR_CD := -31;
		        V_ERR_MSG :=SUBSTR('SP_GET_SECU_ACCT  '||SQLERRM(SQLCODE),1,200);
		        RAISE V_ERR;
		      END;
		      IF V_ERR_CD<0 THEN
		        V_ERR_CD := -32;
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
								 V_ERR_CD := -40;
								 V_ERR_MSG :=SUBSTR('SP_T_STK_MOVEMENT_UPD '||SQLERRM(SQLCODE),1,200);
								RAISE V_ERR;
						END;

						IF V_ERR_CD < 0 THEN
							V_ERR_CD := -45;
							V_ERR_MSG := SUBSTR('SP_T_STK_MOVEMENT_UPD '||V_ERR_MSG,1,200);
							RAISE V_ERR;
						END IF;

				END LOOP; ----JURNAL X DATE UNTUK TYPE WHDR

	--JURNAL KEDUA X DATE UNTUK TYPE SPLITX ATAU REVERSEX
	--GET DOC NUM
				V_DOC_TYPE :='RSN';
				V_DOC_NUM := Get_Stk_Jurnum(P_X_DT ,V_DOC_TYPE );
				IF P_CA_TYPE = 'SPLIT' THEN
				   			 V_JUR_TYPE :='SPLITX';
				ELSE
							 V_JUR_TYPE :='REVERSEX';
				END IF;

				V_QTY :=REC.CUM_END_QTY;--JURNAL KEDUA UNTUK SPLIT ATAU REVERSE
				IF MOD(V_QTY,V_LOT_SIZE) = 0 THEN
					V_ODD_LOT_DOC :='N';
				ELSE
					V_ODD_LOT_DOC :='Y';
				END IF;
   			    V_TOTAL_LOT := TRUNC(V_QTY/V_LOT_SIZE);
					V_TOTAL_SHARE_QTY :=V_QTY;
					V_WITHDRAWN_SHARE_QTY :=0;


			---GET GL_ACCT_CD
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
						V_ERR_CD := -55;
						V_ERR_MSG :=SUBSTR('SP_GET_SECU_ACCT  '||SQLERRM(SQLCODE),1,200);
						RAISE V_ERR;
					END;
					IF V_ERR_CD<0 THEN
						V_ERR_CD := -60;
						V_ERR_MSG :=SUBSTR('SP_GET_SECU_ACCT  '||SQLERRM(SQLCODE),1,200);
						RAISE V_ERR;
					END IF;

	 --EXECUTE SP HEADER
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
		                 V_ERR_CD := -50;
		                 V_ERR_MSG := SUBSTR('SP_T_MANY_HEADER_INSERT '|| SQLERRM(SQLCODE),1,200);
		                RAISE V_ERR;
		            END;

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
								 V_ERR_CD := -65;
								 V_ERR_MSG :=SUBSTR('SP_T_STK_MOVEMENT_UPD '||SQLERRM(SQLCODE),1,200);
								RAISE V_ERR;
						END;

						IF V_ERR_CD < 0 THEN
							V_ERR_CD := -70;
							V_ERR_MSG := SUBSTR('SP_T_STK_MOVEMENT_UPD '||V_ERR_MSG,1,200);
							RAISE V_ERR;
						END IF;

			  	END LOOP; ----JURNAL X DATE UNTUK TYPE SPLITX ATAU REVERSEX
	END IF;

	--JURNAL UNTUK SPLIT ATAU REVERSE PADA DISTRIB DATE
	IF P_JOURNAL = 'D' AND (P_CA_TYPE = 'SPLIT' OR P_CA_TYPE='REVERSE') THEN
			IF P_CA_TYPE = 'SPLIT' THEN
		      	   			 V_JUR_TYPE :='SPLITD';
		      ELSE
		      	  			 V_JUR_TYPE :='REVERSED';
		      END IF;

    --GET DOC NUM
				V_DOC_TYPE :='RSN';
				V_DOC_NUM := Get_Stk_Jurnum( V_DOC_DATE,V_DOC_TYPE );

				V_QTY :=REC.CUM_END_QTY;--JURNAL UNTUK SPLIT ATAU REVERSE PADA DISTRIB DATE

				IF MOD(V_QTY,V_LOT_SIZE) = 0 THEN
					V_ODD_LOT_DOC :='N';
				ELSE
					V_ODD_LOT_DOC :='Y';
				END IF;
				V_TOTAL_LOT := TRUNC(V_QTY/V_LOT_SIZE);
				V_TOTAL_SHARE_QTY :=V_QTY;
				V_WITHDRAWN_SHARE_QTY :=0;



						---GET GL_ACCT_CD
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
						V_ERR_CD := -72;
						V_ERR_MSG :=SUBSTR('SP_GET_SECU_ACCT  '||SQLERRM(SQLCODE),1,200);
						RAISE V_ERR;
					END;
					IF V_ERR_CD<0 THEN
						V_ERR_CD := -74;
						V_ERR_MSG :=SUBSTR('SP_GET_SECU_ACCT  '||SQLERRM(SQLCODE),1,200);
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
										 V_ERR_CD := -80;
										 V_ERR_MSG :=SUBSTR('SP_T_STK_MOVEMENT_UPD '||SQLERRM(SQLCODE),1,200);
										RAISE V_ERR;
								END;

								IF V_ERR_CD < 0 THEN
								    V_ERR_CD := -85;
									V_ERR_MSG := SUBSTR('SP_T_STK_MOVEMENT_UPD '||V_ERR_MSG,1,200);
									RAISE V_ERR;
								END IF;

		  			END LOOP; ----JURNAL DISTRIB DATE UNTUK TYPE SPLITD OR REPVERSED

	--JURNAL SPLIT/REVERSE PADA DISTRIB DATE  JIKA SEL_SPLIT_REVERSE <>0
					IF REC.SEL_SPLIT_REVERSE <> 0 THEN
							--GET DOC NUM
								IF REC.SEL_SPLIT_REVERSE >0 THEN
									V_DOC_TYPE :='RSN';
									V_JUR_TYPE :='RECV';
								ELSE
									V_DOC_TYPE :='WSN';
									V_JUR_TYPE :='WHDR';
								END IF;
								V_DOC_NUM := Get_Stk_Jurnum(  V_DOC_DATE,V_DOC_TYPE );

								--EXECUTE SP HEADER
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
						                 V_ERR_CD := -90;
						                 V_ERR_MSG := SUBSTR('SP_T_MANY_HEADER_INSERT '|| SQLERRM(SQLCODE),1,200);
						                RAISE V_ERR;
						            END;


								V_QTY :=ABS(REC.SEL_SPLIT_REVERSE);
								IF MOD(V_QTY,V_LOT_SIZE) = 0 THEN
									V_ODD_LOT_DOC :='N';
								ELSE
									V_ODD_LOT_DOC :='Y';
								END IF;
								V_TOTAL_LOT := TRUNC(V_QTY/V_LOT_SIZE);

								IF REC.SEL_SPLIT_REVERSE >0 THEN
									V_TOTAL_SHARE_QTY :=V_QTY;
									V_WITHDRAWN_SHARE_QTY :=0;
								ELSE
									V_TOTAL_SHARE_QTY :=0;
									V_WITHDRAWN_SHARE_QTY :=V_QTY;
								END IF;

								---GET GL_ACCT_CD
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
									V_ERR_CD := -95;
									V_ERR_MSG :=SUBSTR('SP_GET_SECU_ACCT  '||SQLERRM(SQLCODE),1,200);
									RAISE V_ERR;
								END;

								IF V_ERR_CD<0 THEN
									V_ERR_CD := -100;
									V_ERR_MSG :=SUBSTR('SP_GET_SECU_ACCT  '||SQLERRM(SQLCODE),1,200);
									RAISE V_ERR;
								END IF;

							--get avg price
					/*		BEGIN
							SELECT avg_buy_price INTO v_avg_price
							FROM T_AVG_PRICE
							WHERE avg_dt = p_x_dt
							AND client_Cd = rec.client_cd
							AND stk_cd = p_stk_cd;
							EXCEPTION
									WHEN OTHERS THEN
									V_ERR_CD := -101;
									V_ERR_MSG :=SUBSTR('GET AVG PRICE  '||rec.client_cd||' '||SQLERRM(SQLCODE),1,200);
									RAISE V_ERR;
								END; */


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
                                            V_SD_type,--S_D_TYPE
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
                                            V_AVG_PRICE,--PRICE
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
											 V_ERR_CD := -105;
											 V_ERR_MSG :=SUBSTR('SP_T_STK_MOVEMENT_UPD '||SQLERRM(SQLCODE),1,200);
											RAISE V_ERR;
									END;

									IF V_ERR_CD < 0 THEN
										V_ERR_CD := -110;
										V_ERR_MSG := SUBSTR('SP_T_STK_MOVEMENT_UPD '||V_ERR_MSG,1,200);
										RAISE V_ERR;
									END IF;

							END LOOP; ----JURNAL DISTRIB DATE UNTUK TYPE SPLITD OR REPVERSED


					END IF;--END JURNAL SPLIT/REVERSE PADA DISTRIB DATE  JIKA SEL_SPLIT_REVERSE<>0

	END IF;--END JURNAL REVERSE OR SPLIT IN DISTRIB DATE

		--JURNAL PADA DISTRIB UNTUK RIGHT, WARRANT, BONUS, STKDIV
	IF P_JOURNAL = 'D' AND (P_CA_TYPE = 'RIGHT' OR P_CA_TYPE = 'WARRANT' OR P_CA_TYPE = 'BONUS' OR P_CA_TYPE = 'STKDIV') THEN

		--GET DOC NUM
			V_DOC_TYPE :='RSN';
			V_DOC_NUM := Get_Stk_Jurnum(  V_DOC_DATE ,V_DOC_TYPE );

			--V_QTY :=REC.RECV_QTY; 9jul15
			V_QTY :=REC.CUM_RECV_QTY;
			IF MOD(V_QTY,V_LOT_SIZE) = 0 THEN
				V_ODD_LOT_DOC :='N';
			ELSE
				V_ODD_LOT_DOC :='Y';
			END IF;
			V_TOTAL_LOT := TRUNC(V_QTY/V_LOT_SIZE);

			V_TOTAL_SHARE_QTY :=V_QTY;
			V_WITHDRAWN_SHARE_QTY :=0;

				  IF P_CA_TYPE ='RIGHT' OR P_CA_TYPE='WARRANT' THEN
				 			  V_JUR_TYPE :='HMETDD';
				ELSIF P_CA_TYPE='BONUS' THEN
								V_JUR_TYPE :='BONUSD';
				ELSIF P_CA_TYPE='STKDIV' THEN
					  			V_JUR_TYPE := 'STKDIVD';
				END IF;

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
						V_ERR_CD := -95;
						V_ERR_MSG :=SUBSTR('SP_GET_SECU_ACCT  '||SQLERRM(SQLCODE),1,200);
						RAISE V_ERR;
					END;

					IF V_ERR_CD<0 THEN
						V_ERR_CD := -100;
						V_ERR_MSG :=SUBSTR('SP_GET_SECU_ACCT  '||SQLERRM(SQLCODE),1,200);
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
									 V_ERR_CD := -120;
									 V_ERR_MSG :=SUBSTR('SP_T_STK_MOVEMENT_UPD '||SQLERRM(SQLCODE),1,200);
									RAISE V_ERR;
							END;

							IF V_ERR_CD < 0 THEN
								V_ERR_CD := -125;
								V_ERR_MSG := SUBSTR('SP_T_STK_MOVEMENT_UPD '||V_ERR_MSG,1,200);
								RAISE V_ERR;
							END IF;

					END LOOP; --END LOOP JURNAL


	--BUAT JURNAL PADA DITRIB_DATE JIKA SEL_END_QTY<>0 UNTUK CA TYPE  RIGHT WARRANT BONUS STKDIV
-- 9Jul15				IF REC.SEL_END_QTY <> 0 AND REC.CUM_END_QTY  <> 0 THEN
				IF REC.SEL_END_QTY <> 0  THEN

				--GET DOC NUM
--9jul15						IF  REC.SEL_END_QTY > 0 AND REC.CUM_END_QTY  > 0 THEN
						IF  REC.SEL_END_QTY > 0  THEN
							V_DOC_TYPE :='RSN';
							V_JUR_TYPE :='RECV';
						ELSE
							V_DOC_TYPE :='WSN';
							V_JUR_TYPE :='WHDR';
						END IF;
						V_DOC_NUM := Get_Stk_Jurnum(  V_DOC_DATE ,V_DOC_TYPE );
				 --EXECUTE SP HEADER
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
			                 V_ERR_CD := -130;
			                 V_ERR_MSG := SUBSTR('SP_T_MANY_HEADER_INSERT '|| SQLERRM(SQLCODE),1,200);
			                RAISE V_ERR;
			            END;

					--S_D_TYPE

						V_QTY :=ABS(REC.SEL_RECV);--SEL_END_QTY SEBELUMNYA(21 MAY 2015)
						IF MOD(V_QTY,V_LOT_SIZE) = 0 THEN
							V_ODD_LOT_DOC :='N';
						ELSE
							V_ODD_LOT_DOC :='Y';
						END IF;
			           V_TOTAL_LOT := TRUNC(V_QTY/V_LOT_SIZE);

--9jul15	0					IF  REC.SEL_END_QTY > 0 AND REC.CUM_END_QTY  > 0 THEN
						IF  REC.SEL_END_QTY > 0  THEN
								V_TOTAL_SHARE_QTY :=V_QTY;
								V_WITHDRAWN_SHARE_QTY :=0;
						ELSE
						V_TOTAL_SHARE_QTY :=0;
								V_WITHDRAWN_SHARE_QTY :=V_QTY;
						END IF;


					---GET GL_ACCT_CD
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
						V_ERR_CD := -135;
						V_ERR_MSG :=SUBSTR('SP_GET_SECU_ACCT  '||SQLERRM(SQLCODE),1,200);
						RAISE V_ERR;
					END;
					IF V_ERR_CD<0 THEN
						V_ERR_CD := -140;
						V_ERR_MSG :=SUBSTR('SP_GET_SECU_ACCT  '||SQLERRM(SQLCODE),1,200);
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
									 V_ERR_CD := -145;
									 V_ERR_MSG :=SUBSTR('SP_T_STK_MOVEMENT_UPD '||SQLERRM(SQLCODE),1,200);
									RAISE V_ERR;
							END;

							IF V_ERR_CD < 0 THEN
								V_ERR_CD := -150;
								V_ERR_MSG := SUBSTR('SP_T_STK_MOVEMENT_UPD '||V_ERR_MSG,1,200);
								RAISE V_ERR;
							END IF;
					END LOOP; --END LOOP JURNAL
				END IF;--BUAT JURNAL PADA DITRIB_DATE JIKA SEL_END_QTY<>0 UNTUK CA TYPE  RIGHT WARRANT BONUS STKDIV
	END IF; --END JURNAL PADA DISTRIB DATE UNTUK RIGHT, WARRANT, BONUS, STKDIV
END LOOP;--END LOOP CURSOR


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
END Sp_Ca_Jur_Upd;