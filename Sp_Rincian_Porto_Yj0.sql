create or replace 
PROCEDURE Sp_Rincian_Porto_Yj(P_UPDATE_DATE DATE,
													P_UPDATE_SEQ NUMBER,
													P_END_DT DATE,
													P_BGN_DT DATE,
													P_USER_ID VARCHAR2,
													P_ERROR_CD OUT NUMBER,
													P_ERROR_MSG OUT VARCHAR2)
													IS
													

V_CLIENT_CD_AB VARCHAR2(12);
v_error_cd NUMBER(5);
v_error_msg VARCHAR2(200);
V_ERR EXCEPTION;
BEGIN



	BEGIN
		SELECT TRIM(OTHER_1) INTO v_client_cd_ab FROM IPNEXTG.MST_COMPANY;
	EXCEPTION
	WHEN OTHERS THEN
		v_error_cd := -5;
		v_error_msg :=SUBSTR('SELECT MST COMPANY'||SQLERRM(SQLCODE),1,200);
		RAISE V_ERR;
	END;




BEGIN
INSERT INTO LAP_RINCIAN_PORTO (UPDATE_DATE,UPDATE_SEQ,REPORT_DATE,REP_TYPE,STK_CD,PRICE,
								PORT001,PORT002,PORT004,CLIENT001,CLIENT002,
								CLIENT004,SUBREK_QTY,JUMLAH_ACCT,USER_ID,APPROVED_STAT,
								APPROVED_BY,APPROVED_DT)
SELECT P_UPDATE_DATE,P_UPDATE_SEQ,P_END_DT, s.rep_type, s.stk_Cd, NVL(p.price,0) price, 												
		(s.port001 - s.port004) AS port001, s.port002, s.port004, s.client001, 0 client002,		
		 s.client004, DECODE(SIGN(s.subrek_qty - s.client004),-1,0, s.subrek_qty - s.client004) AS subrek_qty, x.jumlah_acct ,P_USER_ID,'E',
		 NULL,NULL										
FROM( SELECT '1' rep_type,stk_Cd, SUM(end_ksei * main001 * portofolio_ab) port001,
	  		 	 0 port002,
				SUM( end_004 *  portofolio_ab ) port004,
				SUM(end_ksei * main001 	 * portofolio_client) client001,
				SUM(end_004 * subrek * portofolio_client) client004,
				SUM(end_ksei * subrek) subrek_qty							
		FROM(
		SELECT client_cd, stk_cd, 
		   		   end_ksei, end_004
			   FROM( SELECT client_cd, stk_cd, 
				   		  SUM(beg_ksei + ksei_mvmt) end_ksei,
				   		  SUM(beg_004 + mvmt_004) end_004
				   FROM(  SELECT client_cd, stk_cd, 0 beg_ksei,  0 beg_004, 
							  (NVL(DECODE(SUBSTR(doc_num,5,2),'JV',1,'RS',1,'WS',1,'CS',1,0) *
							  DECODE(trim(gl_acct_cd),'36',1, 0) * DECODE(db_cr_flg,'D',-1,1) *
							  (total_share_qty + withdrawn_share_qty),0)) ksei_mvmt,
							  (NVL(DECODE(SUBSTR(doc_num,5,2),'JV',1,'JA',1,0) *
							  DECODE(trim(gl_acct_cd),'09',1,'13',1, 0) * DECODE(db_cr_flg,'D',1,-1) *
							  (total_share_qty + withdrawn_share_qty),0)) mvmt_004
						    FROM T_STK_MOVEMENT 
						   WHERE doc_dt BETWEEN p_bgn_dt AND p_end_dt
--							 AND stk_cd BETWEEN :s_bgn_stk AND :s_end_stk 
							 AND gl_acct_cd IN ('36','09','13')
							 AND gl_acct_cd IS NOT NULL
							 AND doc_stat    = '2'
						 UNION ALL	
						 SELECT client_Cd, stk_Cd, 
					        (DECODE(trim(gl_acct_Cd),'36',qty,0)) beg_ksei,
							DECODE(trim(gl_acct_Cd),'09',qty,'13',qty,0) beg_004,
					        0 ksei_mvmt,
							0 mvmt_004
						 FROM T_SECU_BAL
						 WHERE bal_dt = p_bgn_dt
						   AND  gl_acct_cd IN ('36','09','13')
--						   AND stk_cd BETWEEN :s_bgn_stk AND :s_end_stk 
						 UNION ALL
							 SELECT a. client_cd, a.stk_cd, beg_ksei,   beg_004, 
							 		   			  ksei_mvmt, mvmt_004
							 FROM 
							( SELECT doc_dt, client_cd, stk_cd, 0 beg_ksei,  0 beg_004, 
								  (NVL(DECODE(SUBSTR(doc_num,5,2),'RS',1,'WS',1,0) *
								  DECODE(trim(gl_acct_cd),'36',-1, 0) * DECODE(db_cr_flg,'D',-1,1) *
								  (total_share_qty + withdrawn_share_qty),0)) ksei_mvmt,
								  0 mvmt_004
							    FROM T_STK_MOVEMENT 
							   WHERE doc_dt BETWEEN (p_bgn_dt - 20) AND p_end_dt
--							 AND stk_cd BETWEEN :s_bgn_stk AND :s_end_stk 
								 AND gl_acct_cd IN ('36')
								 AND jur_type IN ('SPLITW','REVERSEW')
								 AND doc_stat    = '2') a,
							( SELECT stk_cd, x_dt
							   FROM T_CORP_ACT
							   WHERE ca_type IN ('SPLIT','REVERSE')
							   AND 	p_end_dt BETWEEN x_dt AND  recording_dt) b
							  WHERE a.stk_cd = b.stk_cd
							  AND a.doc_dt = b.x_dt
					 UNION ALL 
	                         SELECT v_CLIENT_CD_ab, t.stk_cd,0 beg_ksei, 0 beg_004,						
							                  0 ksei_mvmt,  t.qty AS  mvmt_004		
							  FROM( SELECT stk_cd, MAX(from_dt) max_dt			
							        FROM  T_PORTO_JAMINAN			
	                          WHERE from_dt <= p_end_dt
--							  stk_cd BETWEEN :s_bgn_stk AND :s_end_stk									
									GROUP BY stk_cd) mx,	
								   T_PORTO_JAMINAN t		
							  WHERE t.stk_cd = mx.stk_cd			
							    AND t.from_dt = mx.max_dt			
--	                      AND t.stk_cd BETWEEN :s_bgn_stk AND :s_end_stk									
						    )
				   GROUP BY client_Cd, stk_Cd  )) a,		   							
			( SELECT client_cd, 
			  client_name, 
			  agreement_no, 
		                 DECODE(client_cd,v_client_cd_ab, 1,DECODE(trim(client_type_1),'H', 1,0))  portofolio_ab,
					     DECODE(client_cd,v_client_cd_ab, 0, DECODE(trim(client_type_1),'H', 0,1)  )  portofolio_client,
					    DECODE(SUBSTR(NVL(subrek,'XXXXX0000000'),6,7),'0000004',1,0) main004,
					    DECODE(SUBSTR(NVL(subrek,'XXXXX0000000'),6,7),'0000001',1,0) main001,
					    DECODE(SUBSTR(NVL(subrek,'XXXXX0000001'),6,4),'0000',0,1) subrek
				FROM(		
				SELECT m.client_cd, client_name, agreement_no,client_type_1,
					 DECODE(m.client_type_3,'M',NVL(p.subrekmargin,v.subrek001),NVL(v.subrek001,broker_001)) AS subrek
			   FROM  MST_CLIENT m, v_client_subrek14 v,v_broker_subrek,
			   ( SELECT dstr1 AS subrekmargin
			      FROM MST_SYS_PARAM
				  WHERE param_id = 'SYSTEM'
				  AND param_cd1 ='MARGIN'
				  AND param_cd2 = 'SUBREK'
				  AND p_end_dt BETWEEN ddate1 AND ddate2 ) p
			  WHERE m.client_cd = v.client_cd(+)) ) c
		WHERE  a.client_cd = c.client_cd
          AND (a.end_ksei <> 0 OR end_004 <> 0)
		GROUP BY stk_cd 										
		UNION ALL										
	SELECT '2' rep_type,  stk_Cd, SUM(end_scrip  *   portofolio_ab) port001,											
			SUM(end_scrip  *   portofolio_client) port002,									
		SUM(end_custo  *   portofolio_ab)  port004,										
		SUM(end_custo  *   portofolio_client) client001,										
		0 client004,										
		0  subrek_qty										
		FROM( 										
		SELECT client_cd, stk_cd, SUM(beg_scrip + scrip_mvmt) end_scrip,										
                   SUM(beg_custo + custo_mvmt) end_custo												
			   FROM(  SELECT client_cd, stk_cd, 0 beg_scrip, 									
						  (NVL(DECODE(SUBSTR(doc_num,5,2),'JV',1,'RS',1,'WS',1,'CS',1,0) *						
						  DECODE(trim(NVL(gl_acct_cd,'XX')),'33',1, 0) * DECODE(db_cr_flg,'D',-1,1) *						
						  (total_share_qty + withdrawn_share_qty),0)) scrip_mvmt,						
						  0 beg_custo, 						
						  NVL(DECODE(SUBSTR(doc_num,5,2),'JV',1,'RS',1,'WS',1,'CS',1,0) *						
						  DECODE(trim(NVL(gl_acct_cd,'XX')),'35',1, 0) * DECODE(db_cr_flg,'D',-1,1) *						
						  (total_share_qty + withdrawn_share_qty),0) custo_mvmt						
					    FROM ipnextg.T_STK_MOVEMENT 							
					   WHERE doc_dt BETWEEN P_BGN_DT AND P_END_DT							
						 AND gl_acct_cd IN ('33','35')						
						 AND gl_acct_cd IS NOT NULL						
						 AND doc_stat    = '2' 						
					 UNION ALL							
					 SELECT client_Cd, stk_Cd, 							
				        (DECODE(trim(gl_acct_Cd),'33',qty,0)) beg_scrip,								
				        0 scrip_mvmt, 								
						DECODE(trim(gl_acct_Cd),'35',qty,0) beg_custo, 						
						0 custo_mvmt						
					 FROM ipnextg.T_SECU_BAL							
					 WHERE bal_dt = P_BGN_DT							
                  AND gl_acct_cd IN ('33','35')												
					UNION ALL							
				  SELECT client_cd, reks_cd, 0 beg_scrip, 								
						  0 scrip_mvmt,						
						  0 beg_custo, 						
						  (debit - credit) custo_mvmt						
					    FROM ipnextg.T_REKS_MOVEMENT 							
					   WHERE doc_dt <= P_END_DT							
					   AND gl_Acct_cd = '35'							
						 AND doc_stat    = '2')						
	 				 GROUP BY   client_cd, stk_Cd 							
			   HAVING SUM(beg_scrip + scrip_mvmt) <> 0 OR									
                   SUM(beg_custo + custo_mvmt) <> 0) a,												
			(  SELECT client_cd, client_name, agreement_no, 									
		             DECODE(client_cd,V_CLIENT_CD_AB, 1,0)  portofolio_ab,										
					    DECODE(client_cd,V_CLIENT_CD_AB, 0,1)  portofolio_client,							
					    DECODE(SUBSTR(NVL(agreement_no,'XXXXX0000000'),6,7),'0000004',1,0) rek004,							
					    DECODE(SUBSTR(NVL(agreement_no,'XXXXX0000000'),6,7),'0000001',1,0) rek001,							
					    DECODE(SUBSTR(NVL(agreement_no,'XXXXX0000001'),6,7),'0000001',0,'0000004',0,1) subrek							
			   FROM  ipnextg.MST_CLIENT    ) c									
		WHERE  a.client_cd = c.client_cd										
		GROUP BY stk_cd										
		 ) s, 										
	(  SELECT stk_cd, stk_clos AS price											
	     FROM ipnextg.T_CLOSE_PRICE											
	    WHERE stk_date = P_END_DT											
		UNION										
		SELECT BOND_CD, PRICE  										
		FROM ipnextg.T_BOND_PRICE										
		WHERE PRICE_DT =P_END_DT										
		UNION 										
		 SELECT reks_cd,  nab_unit										
		 FROM ipnextg.T_REKS_NAB										
		 WHERE mkbd_dt = P_END_DT) p,	
(  SELECT   '%JUMLAH_ACCT',COUNT( DISTINCT v.subrek001) Jumlah_acct
		FROM v_client_subrek14 v, mst_client_rekefek m, v_broker_subrek b
		WHERE  v.subrek001 = m.SUBREK_CD
		AND( m.close_date IS NULL OR m.close_date > p_end_dt)
		AND m.open_date <= p_end_dt
		AND subrek001 <> b.BROKER_001)	 x	
	    WHERE s.stk_cd = p.stk_cd(+)
ORDER BY 1,2;

EXCEPTION		
WHEN OTHERS THEN
	v_error_cd := -10;
	v_error_msg :=SUBSTR('INSERT INTO LAP_RINCIAN_PORTO'||SQLERRM(SQLCODE),1,200);
	RAISE V_ERR;
END;


p_error_cd := 1;
p_error_msg :='';



EXCEPTION
	WHEN NO_DATA_FOUND THEN
		NULL;
	WHEN v_err THEN
		ROLLBACK;
		P_ERROR_CD := v_error_cd;
		P_ERROR_MSG := v_error_msg;
	WHEN OTHERS THEN
		ROLLBACK;
		P_ERROR_CD := -1;
		P_ERROR_MSG := SUBSTR(SQLERRM(SQLCODE),1,200);
		RAISE;
END Sp_Rincian_Porto_Yj;
