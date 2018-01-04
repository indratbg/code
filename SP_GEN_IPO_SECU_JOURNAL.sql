create or replace 
PROCEDURE SP_GEN_IPO_SECU_JOURNAL(
				P_STK_CD_TEMP T_PEE.STK_CD%TYPE,
				P_STK_CD_KSEI T_PEE.STK_CD%TYPE,
				P_REMARKS VARCHAR2,
				P_USER_ID VARCHAR2,
				P_IP_ADDRESS T_MANY_HEADER.IP_ADDRESS%TYPE,
				P_ERRCD OUT NUMBER,
				P_ERRMSG OUT VARCHAR2)
				IS

V_JUR_TYPE VARCHAR2(10);
V_DB_CR_FLG VARCHAR(1);
V_MENU_NAME VARCHAR2(50):='GENERATE IPO SECURITES JOURNAL';
V_UPDATE_DATE DATE;
V_UPDATE_SEQ NUMBER;
V_DEB_GL_ACCT_CD MST_SECU_ACCT.DEB_ACCT%TYPE;
V_DOC_TYPE VARCHAR2(10);
V_DOC_NUM VARCHAR(17);
V_SD_TYPE CHAR(1);
V_ERR_CD NUMBER;
V_ERR_MSG VARCHAR(200);
V_TOTAL_SHARE_QTY NUMBER;
V_WITHDRAWN_SHARE_QTY NUMBER;
V_ODD_LOT_DOC CHAR(1);
V_TOTAL_LOT NUMBER;
V_DOC_DATE DATE;
V_REMARKS VARCHAR2(50);
V_LOT_SIZE T_STK_MOVEMENT.WITHDRAWN_SHARE_QTY%TYPE;
V_CRE_GL_ACCT_CD  VARCHAR2(5);
V_ERR EXCEPTION;
V_QTY T_STK_MOVEMENT.WITHDRAWN_SHARE_QTY%TYPE;
V_GL_ACCT_CD VARCHAR2(5);
--V_PRICE T_STK_MOVEMENT.PRICE%TYPE;
V_CNT NUMBER;
CURSOR CSR_DATA IS
 SELECT  P.STK_CD,P.DISTRIB_DT_FR,t.client_cd, m.client_name, m.branch_code, ROUND(p.price * 1.01,0) price, t.fixed_qty AS qty,
	trim(m.client_type_1)||trim(m.client_type_2)||trim(m.client_type_3) AS client_type, m.custodian_cd,	'Fixed ' ipo_type,
	decode(t.client_cd, v.broker_client_Cd,'H',decode(m.client_type_1,'H','H','%')) as client_type_secu_acct
	FROM T_IPO_CLIENT t, T_PEE p, MST_CLIENT m, v_broker_subrek v	
	WHERE p.stk_cd = P_STK_CD_TEMP	
	AND t.stk_Cd = P_STK_CD_TEMP	
	AND t.client_cd = m.client_cd	
	AND t.fixed_qty > 0	
	AND t.approved_stat = 'A'	
	UNION ALL	
	SELECT P.STK_CD, P.DISTRIB_DT_FR,t.client_cd, m.client_name,m.branch_code,  p.price, t.alloc_qty AS qty,
	trim(m.client_type_1)||trim(m.client_type_2)||trim(m.client_type_3) AS client_type,
	m.custodian_cd,	'Pooling ' ipo_type,
	decode(t.client_cd, v.broker_client_Cd,'H',decode(m.client_type_1,'H','H','%')) as client_type_secu_acct
	FROM T_IPO_CLIENT t, T_PEE p, MST_CLIENT m, v_broker_subrek v	
	WHERE p.stk_cd = P_STK_CD_TEMP	
	AND t.stk_Cd = P_STK_CD_TEMP	
	AND t.client_cd = m.client_cd	
	AND  t.alloc_qty > 0 	
	AND t.approved_stat = 'A';	
  
 CURSOR CSR_PENDING (A_DOC_DT T_STK_MOVEMENT.DOC_DT%TYPE,A_STK_CD T_STK_MOVEMENT.STK_CD%TYPE,A_JUR_TYPE T_STK_MOVEMENT.JUR_TYPE%TYPE)IS
  SELECT DISTINCT DOC_DT,STK_CD,JUR_TYPE FROM (SELECT (SELECT TO_DATE(FIELD_VALUE,'YYYY/MM/DD HH24:MI:SS') FROM T_MANY_DETAIL DA 
					        WHERE DA.TABLE_NAME = 'T_STK_MOVEMENT' 
					        AND DA.UPDATE_DATE = DD.UPDATE_DATE
					        AND DA.UPDATE_SEQ = DD.UPDATE_SEQ
					        AND DA.FIELD_NAME = 'DOC_DT'
					        AND DA.RECORD_SEQ = DD.RECORD_SEQ) DOC_DT, 
					(SELECT FIELD_VALUE FROM T_MANY_DETAIL DA 
					        WHERE DA.TABLE_NAME = 'T_STK_MOVEMENT' 
					        AND DA.UPDATE_DATE = DD.UPDATE_DATE
					        AND DA.UPDATE_SEQ = DD.UPDATE_SEQ
					        AND DA.FIELD_NAME = 'STK_CD'
					        AND DA.RECORD_SEQ = DD.RECORD_SEQ) STK_CD,
					(SELECT FIELD_VALUE FROM T_MANY_DETAIL DA 
					        WHERE DA.TABLE_NAME = 'T_STK_MOVEMENT' 
					        AND DA.UPDATE_DATE = DD.UPDATE_DATE
					        AND DA.UPDATE_SEQ = DD.UPDATE_SEQ
					        AND DA.FIELD_NAME = 'JUR_TYPE'
					        AND DA.RECORD_SEQ = DD.RECORD_SEQ) JUR_TYPE
					FROM T_MANY_DETAIL DD, T_MANY_HEADER HH WHERE DD.TABLE_NAME = 'T_STK_MOVEMENT' AND DD.UPDATE_DATE = HH.UPDATE_DATE
					AND DD.UPDATE_SEQ = HH.UPDATE_SEQ AND DD.RECORD_SEQ =1 AND MENU_NAME ='GENERATE IPO SECURITES JOURNAL'
					AND DD.FIELD_NAME = 'DOC_DT' AND HH.APPROVED_STATUS = 'E' ORDER BY HH.UPDATE_SEQ)
					WHERE DOC_DT = A_DOC_DT AND STK_CD = A_STK_CD AND JUR_TYPE = A_JUR_TYPE;
BEGIN

V_JUR_TYPE :='IPO';
V_SD_TYPE :='C';
BEGIN
		SELECT LOT_SIZE INTO V_LOT_SIZE FROM MST_COUNTER WHERE STK_CD = P_STK_CD_KSEI;
		EXCEPTION
		WHEN OTHERS THEN
			 V_ERR_CD := -5;
			 V_ERR_MSG := SUBSTR('MST_COUNTER  '||SQLERRM(SQLCODE),1,200);
			RAISE V_ERR;
		END;
   V_CNT:=1;
FOR REC IN CSR_DATA LOOP
		V_DOC_DATE := REC.DISTRIB_DT_FR;
		V_DOC_TYPE :='RSN';
		V_DOC_NUM := Get_Stk_Jurnum(  REC.DISTRIB_DT_FR,V_DOC_TYPE );
		V_REMARKS := REC.IPO_TYPE||P_REMARKS;
		
    IF V_CNT =1 THEN
    
  BEGIN
  UPDATE T_PEE SET STK_CD_KSEI = P_STK_CD_KSEI WHERE STK_CD = P_STK_CD_TEMP AND DISTRIB_DT_FR = REC.DISTRIB_DT_FR;
  	EXCEPTION
				WHEN OTHERS THEN
					 V_ERR_CD := -6;
					 V_ERR_MSG :=SUBSTR('SP_T_STK_MOVEMENT_UPD '||SQLERRM(SQLCODE),1,200);
					RAISE V_ERR;
      END;
    
    
     FOR CEK IN CSR_PENDING( REC.DISTRIB_DT_FR,P_STK_CD_KSEI,v_jur_type) loop
    	 V_ERR_CD := -6;
			 V_ERR_MSG := 'Masih ada yang belum diapprove';
			RAISE V_ERR;
    END LOOP;
    END IF;
    
--GET GL_ACCT_CD
		BEGIN
		SP_GET_SECU_ACCT ( REC.DISTRIB_DT_FR,
                       REC.CLIENT_TYPE_secu_acct,
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
			V_ERR_MSG :=SUBSTR('SP_GET_SECU_ACCT  '||SQLERRM(SQLCODE)||v_err_cd||v_err_msg,1,200);
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
                 V_ERR_CD := -20;
                 V_ERR_MSG := SUBSTR('SP_T_MANY_HEADER_INSERT '|| SQLERRM(SQLCODE),1,200);
                RAISE V_ERR;
            END;
	
	v_qty := rec.qty;
	
	IF MOD(V_QTY,V_LOT_SIZE) = 0 THEN
		V_ODD_LOT_DOC :='N';
	ELSE
		V_ODD_LOT_DOC :='Y';
	END IF;
	V_TOTAL_LOT := TRUNC(V_QTY/V_LOT_SIZE);
	V_TOTAL_SHARE_QTY :=V_QTY;
	V_WITHDRAWN_SHARE_QTY :=0;
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
                                P_STK_CD_KSEI,--STK_CD
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
                                REC.PRICE,--PRICE
                                NULL,--PREV_DOC_NUM
                                'Y',--MANUAL
                                V_JUR_TYPE,--JUR_TYPE	
                                NULL,--BROKER	
                                NULL,--P_REPO_REF,
                                null,--RATIO
                                null,--RATIO_REASON
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
	END LOOP;	
			V_CNT :=V_CNT+1;
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
END SP_GEN_IPO_SECU_JOURNAL;