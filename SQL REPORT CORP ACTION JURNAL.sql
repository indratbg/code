SELECT  a.client_cd,m.client_name, a.stk_cd, ca_type,a.bal_qty, on_custody,client_type, from_qty, to_qty,		
	ROUND(a.bal_qty * to_qty/from_qty,0) recv_qty,
	decode(c.ca_type,'SPLIT',0,'REVERSE',0,a.bal_qty) +ROUND(a.bal_qty * to_qty/from_qty,0) end_qty,	
	GREATEST(a.bal_qty  - ROUND(a.bal_qty * to_qty/from_qty,0),0) whdr_qty,	
	GREATEST(ROUND(a.bal_qty * to_qty/from_qty,0) - a.bal_Qty, 0) split_qty,
   M.BRANCH_CODE, C.RECORDING_DT,C.X_DT,C.DISTRIB_DT,C.CUM_DT
FROM( SELECT client_cd, stk_cd,		
	   SUM( NVL(theo_mvmt,0)) bal_qty, SUM(NVL(on_custody,0)) on_custody	
	   FROM(	  SELECT client_cd, stk_cd, 
		  DECODE(SUBSTR(doc_num,5,2),'BR',1,'JR',1,'BI',1,'JI',1,'BO',1,'JO',1,'RS',1,'WS',1,0) *
		  DECODE(db_cr_flg,'D',1,-1) *  (total_share_qty + withdrawn_share_qty) theo_mvmt,
		  DECODE(trim(gl_acct_Cd),'33',1,0) *
		  DECODE(db_cr_flg,'C',1,-1) *  (total_share_qty + withdrawn_share_qty) on_custody
	      FROM T_STK_MOVEMENT 	
		  WHERE doc_dt BETWEEN :v_bgn_dt AND :v_cum_dt
		AND stk_cd = :p_stk_cd
		AND trim(gl_acct_cd) IN ('10','12','13','14','51','33')
		AND doc_stat    = '2' 
 UNION ALL		
SELECT  client_cd, stk_cd, beg_bal_qty, on_custody		
	FROM T_STKBAL	
	WHERE bal_dt = :v_bgn_dt	
	AND stk_cd = :p_stk_cd) 	
		GROUP BY  client_cd, stk_cd
	HAVING  SUM(theo_mvmt) > 0) a,	
( SELECT client_Cd, client_type_3, DECODE(client_Cd, c.coy_client_cd,'H', DECODE(client_type_1,'H','H',margin_cd)) AS client_type,
  BRANCH_CODE,CLIENT_NAME
  FROM MST_CLIENT, LST_TYPE3, 		
  ( SELECT trim(other_1) coy_client_Cd FROM MST_COMPANY) c		
  WHERE client_type_1 <> 'B'		
  AND client_type_3 = cl_type3) m,		
  ( SELECT stk_cd, ca_type, from_qty, to_qty, RECORDING_DT, X_DT, DISTRIB_DT, CUM_DT		
     FROM t_corp_act		
	 WHERE stk_cd= :p_stk_cd	
	 AND cum_dt = :v_cum_dt	
	 AND ca_type = :p_ca_type	
	and approved_stat = 'A') c	
WHERE a.client_cd = m.client_cd		
AND a.stk_Cd = c.stk_cd;		
