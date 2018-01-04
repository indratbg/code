create or replace 
PROCEDURE SPR_CORP_ACT_JOURNAL(	P_BGN_DT DATE,
								P_CUM_DT DATE,
								 P_CA_TYPE VARCHAR2,
								 P_STK_CD VARCHAR2,
								 P_USER_ID			VARCHAR2,
								 P_GENERATE_DATE 	DATE,
								 P_RANDOM_VALUE	OUT NUMBER,
								 P_ERRCD	 		OUT NUMBER,
								 P_ERRMSG	 		OUT VARCHAR2
								) IS
  v_random_value	NUMBER(10);
  v_err			EXCEPTION;
  v_err_cd number(10);
  v_err_msg number(10);
BEGIN
    v_random_value := abs(dbms_random.random);

    BEGIN
        SP_RPT_REMOVE_RAND('R_CORP_ACT_JOURNAL',V_RANDOM_VALUE,P_ERRCD,P_ERRMSG);
    EXCEPTION
        WHEN OTHERS THEN
             v_err_cd := -2;
             v_err_msg := SQLERRM(SQLCODE);
            RAISE V_err;
    END;
  BEGIN
  
  
  --INSERT KE TABLE REPORT
  
  INSERT INTO R_CORP_ACT_JOURNAL(CLIENT_CD,CLIENT_NAME,STK_CD,CA_TYPE,BAL_QTY,
				ON_CUSTODY,CLIENT_TYPE,FROM_QTY,TO_QTY,RECV_QTY,
				END_QTY,
				WHDR_QTY,
				SPLIT_QTY,
				USER_ID,GENERATE_DATE,
				RAND_VALUE,BRANCH_CODE,RECORDING_DT,DISTRIB_DT,X_DT,CUM_DT)
				
	SELECT  a.client_cd,m.client_name, a.stk_cd, ca_type,a.bal_qty, 
			on_custody,client_type, from_qty, to_qty, ROUND(a.bal_qty * to_qty/from_qty,0) recv_qty,
	decode(c.ca_type,'SPLIT',0,'REVERSE',0,a.bal_qty) +ROUND(a.bal_qty * to_qty/from_qty,0) end_qty, 
	GREATEST(a.bal_qty  - ROUND(a.bal_qty * to_qty/from_qty,0),0) whdr_qty,	
	GREATEST(ROUND(a.bal_qty * to_qty/from_qty,0) - a.bal_Qty, 0) split_qty,
	p_user_id, p_generate_date, 
	v_random_value, TRIM(M.BRANCH_CODE), C.RECORDING_DT,C.DISTRIB_DT,C.X_DT,C.CUM_DT
	FROM( SELECT client_cd, stk_cd,		
	   SUM( NVL(theo_mvmt,0)) bal_qty, SUM(NVL(on_custody,0)) on_custody	
	   FROM(	  SELECT client_cd, stk_cd, 
		  DECODE(SUBSTR(doc_num,5,2),'BR',1,'JR',1,'BI',1,'JI',1,'BO',1,'JO',1,'RS',1,'WS',1,0) *
		  DECODE(db_cr_flg,'D',1,-1) *  (total_share_qty + withdrawn_share_qty) theo_mvmt,
		  DECODE(trim(gl_acct_Cd),'33',1,0) *
		  DECODE(db_cr_flg,'C',1,-1) *  (total_share_qty + withdrawn_share_qty) on_custody
	      FROM IPNEXTG.T_STK_MOVEMENT 	
		  WHERE doc_dt BETWEEN P_BGN_DT AND P_CUM_DT
		AND stk_cd = P_STK_CD
		AND trim(gl_acct_cd) IN ('10','12','13','14','51','33')
		AND doc_stat    = '2' 
 UNION ALL		
SELECT  client_cd, stk_cd, beg_bal_qty, on_custody		
	FROM IPNEXTG.T_STKBAL	
	WHERE bal_dt = P_BGN_DT	
	AND stk_cd = P_STK_CD) 	
		GROUP BY  client_cd, stk_cd
	HAVING  SUM(theo_mvmt) > 0) a,	
( SELECT client_Cd, client_type_3, DECODE(client_Cd, c.coy_client_cd,'H', DECODE(client_type_1,'H','H',margin_cd)) AS client_type,
  BRANCH_CODE,CLIENT_NAME
  FROM IPNEXTG.MST_CLIENT, IPNEXTG.LST_TYPE3, 		
  ( SELECT trim(other_1) coy_client_Cd FROM IPNEXTG.MST_COMPANY) c		
  WHERE client_type_1 <> 'B'		
  AND client_type_3 = cl_type3) m,		
  ( SELECT stk_cd, ca_type, from_qty, to_qty, RECORDING_DT, X_DT, DISTRIB_DT, CUM_DT		
     FROM IPNEXTG.t_corp_act		
	 WHERE stk_cd= P_STK_CD	
	 AND cum_dt = P_CUM_DT	
	 AND ca_type = P_CA_TYPE	
	and approved_stat = 'A') c	
WHERE a.client_cd = m.client_cd		
AND a.stk_Cd = c.stk_cd;		

    EXCEPTION
        WHEN OTHERS THEN
             v_err_cd := -3;
             v_err_msg := SQLERRM(SQLCODE);
            RAISE V_err;
    END;

    p_random_value := v_random_value;
    p_errcd := 1;
    p_errmsg := '';
  
EXCEPTION
    WHEN V_err THEN
        ROLLBACK;
		 p_errcd := v_err_cd;
        p_errmsg := v_err_msg;
    WHEN OTHERS THEN
        ROLLBACK;
        p_errcd := -1;
        p_errmsg := SUBSTR(SQLERRM(SQLCODE),1,200);
END SPR_CORP_ACT_JOURNAL;