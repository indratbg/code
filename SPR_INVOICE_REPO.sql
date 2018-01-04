create or replace 
PROCEDURE SPR_INVOICE_REPO(
    P_BGN_DATE      DATE,
    P_END_DATE      DATE,
    P_BGN_STOCK     VARCHAR2,
    P_END_STOCK     VARCHAR2,
    P_BGN_CLIENT    VARCHAR2,
    P_END_CLIENT    VARCHAR2,
    P_BGN_BROKER    VARCHAR2,
    P_END_BROKER    VARCHAR2,
    P_OTC           NUMBER,
	P_ACCT_JUAL T_STK_MOVEMENT.GL_ACCT_CD%TYPE,
	P_ACCT_BELI T_STK_MOVEMENT.GL_ACCT_CD%TYPE,
    P_USER_ID       VARCHAR2,
    P_GENERATE_DATE DATE,
    P_RANDOM_VALUE OUT NUMBER,
    P_ERROR_CD OUT NUMBER,
    P_ERROR_MSG OUT VARCHAR2 )
IS
  V_ERROR_MSG    VARCHAR2(200);
  V_ERROR_CD     NUMBER(10);
  v_random_value NUMBER(10);
  V_ERR          EXCEPTION;
BEGIN

  v_random_value := ABS(dbms_random.random);
  
  BEGIN
    SP_RPT_REMOVE_RAND('R_INVOICE_REPO',V_RANDOM_VALUE,V_ERROR_MSG,V_ERROR_CD);
  EXCEPTION
  WHEN OTHERS THEN
    V_ERROR_CD  := -10;
    V_ERROR_MSG := SUBSTR('SP_RPT_REMOVE_RAND '||V_ERROR_MSG||SQLERRM(SQLCODE),1,200);
    RAISE V_err;
  END;
  
  IF V_ERROR_CD  <0 THEN
    V_ERROR_CD  := -20;
    V_ERROR_MSG := SUBSTR('SP_RPT_REMOVE_RAND'||V_ERROR_MSG,1,200);
    RAISE V_ERR;
  END IF;
  
  BEGIN
    INSERT
    INTO R_INVOICE_REPO
      (
BGN_DATE
,END_DATE
,BROKER
,DOC_DT
,TYP
,STK_CD
,REPO_TYPE
,REPO
,RETRN
,STK_CNT
,DOC_REM
,CLIENT_CD
,CLIENT_NAME
,OTC
,ACOPEN_FEE_FLG
,USER_ID
,RAND_VALUE
,GENERATE_DATE
      )
 SELECT P_BGN_DATE, P_END_DATE, x.*	,
P_USER_ID, V_RANDOM_VALUE, P_GENERATE_DATE 
FROM( SELECT  a.withdraw_reason_cd AS broker, a.DOC_DT, 'D' typ,  a.STK_CD, 			
DECODE(trim(a.gl_acct_cd),'50','Repo Jual','Repo Beli') repo_type,			
DECODE(trim(a.gl_acct_cd),'50',DECODE(a.db_cr_flg,'C',1,0),DECODE(a.db_cr_flg,'D',1,0)) * a.TOTAL_SHARE_QTY repo,			
DECODE(trim(a.gl_acct_cd),'50',DECODE(a.db_cr_flg,'D',1,0),DECODE(a.db_cr_flg,'C',1,0)) * a.TOTAL_SHARE_QTY retrn,			
		0 stk_cnt, 	
		'Repo' doc_rem,	
		  a.CLIENT_CD,  b.client_name, 0 otc,	
      b.acopen_fee_flg			
FROM t_stk_movement a, mst_client b 			
WHERE a.gl_acct_Cd IN (P_ACCT_BELI,P_ACCT_JUAL) 			
AND SUBSTR(a.DOC_NUM,5,3) = 'JVA'			
AND a.client_cd = b.client_cd 			
AND a.doc_stat = '2' 			
AND a.doc_dt BETWEEN P_BGN_DATE AND P_END_DATE 			
AND a.client_cd BETWEEN P_BGN_CLIENT AND P_END_CLIENT 			
AND a.stk_cd BETWEEN P_BGN_STOCK AND P_END_STOCK 			
AND a.withdraw_reason_cd IS NOT NULL			
AND a.withdraw_reason_cd BETWEEN P_BGN_BROKER AND P_END_BROKER			
UNION ALL			
SELECT  a.withdraw_reason_cd AS broker, a.DOC_DT, 'S',  NULL,			
      NULL, 0, 0,			
		COUNT(DISTINCT a.stk_cd) stk_cnt, 	
		'summary' doc_rem,	
		 NULL,  NULL, P_OTC, null	
FROM t_stk_movement a, mst_client b 			
WHERE a.gl_acct_Cd IN (P_ACCT_BELI,P_ACCT_JUAL) 			
AND SUBSTR(a.DOC_NUM,5,3) = 'JVA'			
AND a.client_cd = b.client_cd 			
AND a.doc_stat = '2' 			
AND a.doc_dt BETWEEN P_BGN_DATE AND P_END_DATE 			
AND a.client_cd BETWEEN P_BGN_CLIENT AND P_END_CLIENT 			
AND a.stk_cd BETWEEN P_BGN_STOCK AND P_END_STOCK 			
AND a.withdraw_reason_cd IS NOT NULL			
AND a.withdraw_reason_cd BETWEEN P_BGN_BROKER AND P_END_BROKER			
GROUP BY  a.withdraw_reason_cd, a.DOC_DT) x			
ORDER BY x.broker, x.doc_dt, x.typ, x.stk_cd 			

  EXCEPTION
  WHEN OTHERS THEN
    V_ERROR_CD  := -30;
    V_ERROR_MSG := SUBSTR('INSERT R_INVOICE_REPO '||V_ERROR_MSG||SQLERRM(SQLCODE),1,200);
    RAISE V_err;
  END;
  
  P_RANDOM_VALUE :=V_RANDOM_VALUE;
  P_ERROR_CD     := 1 ;
  P_ERROR_MSG    := '';
  
EXCEPTION
WHEN V_ERR THEN
  ROLLBACK;
  P_ERROR_MSG := V_ERROR_MSG;
  P_ERROR_CD  := V_ERROR_CD;
WHEN OTHERS THEN
  P_ERROR_CD  := -1 ;
  P_ERROR_MSG := SUBSTR(SQLERRM(SQLCODE),1,200);
  RAISE;
END SPR_INVOICE_REPO;