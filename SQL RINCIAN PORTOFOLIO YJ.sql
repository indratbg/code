SELECT s.rep_type, s.stk_Cd, NVL(p.price,0) price, 												
		s.port001 AS port001,										
		       s.port002,										
		  s.port004,										
		 s.client001,										
		       0 client002,										
		 s.client004,										
		 DECODE(SIGN(s.subrek_qty - s.client004),-1,0, s.subrek_qty - s.client004) AS subrek_qty,										
		 x.jumlah_acct										
FROM( SELECT '1' rep_type,stk_Cd, SUM(end_ksei * main001 * portofolio_ab) port001,												
	  		 	 0 port002,								
				SUM( end_ksei  *  main004 * portofolio_client) port004,								
				SUM(end_ksei * main001 * portofolio_client) client001,								
				SUM(end_ksei * subrek * client004) client004,								
				SUM(end_ksei * subrek) subrek_qty								
		FROM( SELECT client_cd, stk_cd, 										
		   		   end_ksei								
			   FROM( SELECT client_cd, stk_cd, 									
				   		  SUM(beg_ksei + ksei_mvmt) end_ksei						
				   FROM(  SELECT client_cd, stk_cd, 0 beg_ksei,   								
							  (NVL(DECODE(SUBSTR(doc_num,5,2),'JV',1,'RS',1,'WS',1,'CS',1,0) *					
							  DECODE(trim(NVL(gl_acct_cd,'36')),'36',1, 0) * DECODE(db_cr_flg,'D',-1,1) *					
							  (total_share_qty + withdrawn_share_qty),0)) ksei_mvmt					
						    FROM ipnextg.T_STK_MOVEMENT 						
						   WHERE doc_dt BETWEEN :dt_bgn_dt AND :dt_end_dt						
							-- AND stk_cd >= :s_bgn_stk					
							 --AND stk_cd <= :s_end_stk					
							 AND gl_acct_cd IN ('36')					
							 AND gl_acct_cd IS NOT NULL					
							 AND doc_stat    = '2'					
						 UNION ALL						
						 SELECT client_cd, stk_cd, 0 beg_ksei,   						
							  (NVL(  DECODE(db_cr_flg,'D',-1,1) *					
							  (total_share_qty + withdrawn_share_qty),0)) ksei_mvmt					
						    FROM ipnextg.T_STK_MOVEMENT 						
						   WHERE doc_dt BETWEEN (:dt_end_dt - 10) AND :dt_end_dt						
									AND  due_dt_for_cert >:dt_end_dt			
							-- AND stk_cd >= :s_bgn_stk					
							 --AND stk_cd <= :s_end_stk					
							 AND gl_acct_cd = 'RR'					
							 AND gl_acct_cd IS NOT NULL					
							 AND doc_stat    = '9'					
						 UNION ALL						
						 SELECT client_Cd, stk_Cd, 						
					        (DECODE(trim(gl_acct_Cd),'36',qty,0)) beg_ksei,							
					        0 ksei_mvmt							
						 FROM ipnextg.T_SECU_BAL						
						 WHERE bal_dt = :dt_bgn_dt						
						 --  AND stk_cd BETWEEN :s_bgn_stk AND :s_end_stk 						
						    )						
				   GROUP BY client_Cd, stk_Cd  )) a,								
			( SELECT m.client_cd, 									
			  m.client_name, 									
			  agreement_no, 									
		             DECODE(m.client_cd,:client_cd_ab, 1,0)  portofolio_ab,										
					    DECODE(m.client_cd,:client_cd_ab, 0,DECODE(c.client_cd,NULL,1,0))  portofolio_client,							
					    DECODE(m.client_cd,:client_cd_ab, 0,DECODE(c.client_cd,NULL,0,1))  client004,							
					    DECODE(SUBSTR(NVL(subrek,'XXXXX0000000'),6,7),'0000004',1,0) main004,							
					    DECODE(SUBSTR(NVL(subrek,'XXXXX0000000'),6,7),'0000001',1,0) main001,							
					    DECODE(SUBSTR(NVL(subrek,'XXXXX0000001'),6,4),'0000',0,1) subrek							
				FROM(								
				SELECT m.client_cd, client_name, agreement_no,								
					 DECODE(m.client_type_3,'M',NVL(p.subrekmargin,v.subrek001),NVL(v.subrek001,broker_001)) AS subrek							
			   FROM  ipnextg.MST_CLIENT m, ipnextg.v_client_subrek14 v,ipnextg.v_broker_subrek,									
			   ( SELECT dstr1 AS subrekmargin									
			      FROM ipnextg.MST_SYS_PARAM									
				  WHERE param_id = 'SYSTEM'								
				  AND param_cd1 ='MARGIN'								
				  AND param_cd2 = 'SUBREK'								
				  AND :dt_end_dt BETWEEN ddate1 AND ddate2 ) p								
			  WHERE m.client_cd = v.client_cd(+)) m,									
			    ( SELECT client_cd									
			       FROM IPNEXTG.T_CLIENT_DIJAMINKAN									
				   WHERE eff_Dt <= :dt_end_dt) c								
			   WHERE m.client_cd = c.client_cd(+)) c									
		WHERE  a.client_cd = c.client_cd										
        AND a.end_ksei <> 0												
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
					   WHERE doc_dt BETWEEN :dt_bgn_dt AND :dt_end_dt							
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
					 WHERE bal_dt = :dt_bgn_dt							
                  AND gl_acct_cd IN ('33','35')												
					UNION ALL							
				  SELECT client_cd, reks_cd, 0 beg_scrip, 								
						  0 scrip_mvmt,						
						  0 beg_custo, 						
						  (debit - credit) custo_mvmt						
					    FROM ipnextg.T_REKS_MOVEMENT 							
					   WHERE doc_dt <= :dt_end_dt							
					   AND gl_Acct_cd = '35'							
						 AND doc_stat    = '2')						
	 				 GROUP BY   client_cd, stk_Cd 							
			   HAVING SUM(beg_scrip + scrip_mvmt) <> 0 OR									
                   SUM(beg_custo + custo_mvmt) <> 0) a,												
			(  SELECT client_cd, client_name, agreement_no, 									
		             DECODE(client_cd,:client_cd_ab, 1,0)  portofolio_ab,										
					    DECODE(client_cd,:client_cd_ab, 0,1)  portofolio_client,							
					    DECODE(SUBSTR(NVL(agreement_no,'XXXXX0000000'),6,7),'0000004',1,0) rek004,							
					    DECODE(SUBSTR(NVL(agreement_no,'XXXXX0000000'),6,7),'0000001',1,0) rek001,							
					    DECODE(SUBSTR(NVL(agreement_no,'XXXXX0000001'),6,7),'0000001',0,'0000004',0,1) subrek							
			   FROM  ipnextg.MST_CLIENT    ) c									
		WHERE  a.client_cd = c.client_cd										
		GROUP BY stk_cd										
		 ) s, 										
	(  SELECT stk_cd, stk_clos AS price											
	     FROM ipnextg.T_CLOSE_PRICE											
	    WHERE stk_date = :dt_end_dt											
		UNION										
		SELECT BOND_CD, PRICE  										
		FROM ipnextg.T_BOND_PRICE										
		WHERE PRICE_DT =:dt_end_dt										
		UNION 										
		 SELECT reks_cd,  nab_unit										
		 FROM ipnextg.T_REKS_NAB										
		 WHERE mkbd_dt = :dt_end_dt) p,										
	( SELECT '%JUMLAH_ACCT',COUNT(1) Jumlah_acct											
	   FROM( SELECT DISTINCT agreement_no											
	          FROM( SELECT  m.client_cd, DECODE(s.subrek,NULL,m.agreement_no, s.subrek) agreement_no											
			          FROM( SELECT t.client_cd, t.old_str AS subrek									
									FROM( SELECT client_cd, MIN(cre_dt) mindt			
											FROM ipnextg.T_CLIENT_LOG	
											WHERE upd_dt > 	:dt_end_dt
											  AND SUBSTR(subrek,10,3) = '001'	
											  AND item_name = 'SUBREK'	
											GROUP BY client_cd) a,	
										ipnextg.T_CLIENT_LOG t, ipnextg.MST_CLIENT m 		
									WHERE a.client_cd = t.client_cd			
									AND a.mindt = t.cre_dt			
									AND t.item_name = 'SUBREK'			
									AND SUBSTR(subrek,10,3) = '001'			
									AND t.client_cd = m.client_cd 			
									AND ( :dt_end_dt > '31may2012' OR m.client_type_3 <> 'M')) s,			
							(  SELECT m.client_cd, v.subrek001 AS agreement_no, 					
							    r.open_date AS acct_open_dt					
							  FROM ipnextg.MST_CLIENT m, ipnextg.v_client_subrek14 v, ipnextg.MST_CLIENT_REKEFEK r 					
							 WHERE susp_stat <> 'C'					
							   AND client_type_1 <> 'B'					
							   AND m.client_cd = v.client_cd					
							   AND m.client_cd = r.client_cd					
							   AND r.subrek_cd = v.subrek001					
							   AND :dt_end_dt > '31may2012'					
							   UNION					
							   SELECT client_cd, 					
							    agreement_no, acct_open_dt					
							   FROM ipnextg.MST_CLIENT 					
							 WHERE susp_stat <> 'C'					
							   AND client_type_1 <> 'B'					
							   AND :dt_end_dt <= '31may2012'					
								AND client_type_3 <> 'M' ) m				
							WHERE m.acct_open_dt <= :dt_end_dt					
				         AND m.client_cd = s.client_Cd(+)	)							
			WHERE  agreement_no IS NOT NULL									
			  AND SUBSTR(NVL(agreement_no,'XXXXX0000001'),6,4) <> '0000'									
           AND SUBSTR(NVL(agreement_no,'XXXXX0000004'),10,3) <> '004'												
			UNION ALL 									
			SELECT subrek 									
				FROM ipnextg.T_CLIENT_LOG t, ipnextg.MST_CLIENT m								
				WHERE t.UPD_DT > :dt_end_dt 								
				AND t.item_name = 'CLOSED' 								
				AND t.subrek_mvmt <> 0								
	         AND SUBSTR(t.subrek,10,3) = '001'											
            AND t.client_cd = m.client_cd 												
				AND ( :dt_end_dt > '31may2012' OR m.client_type_3 <> 'M')								
	         AND m.acct_open_dt <= :dt_end_dt											
			MINUS									
		   SELECT  t.new_str										
				FROM( SELECT client_cd, MIN(cre_dt) mindt 								
						FROM ipnextg.T_CLIENT_LOG 						
						WHERE upd_dt > 	:dt_end_dt 					
						  AND item_name = 'SUBREK' 						
						  AND SUBSTR(subrek,10,3) = '001'						
						  AND SUBSTR(subrek,6,4) <> '0000'						
						GROUP BY client_cd) a, 						
					ipnextg.T_CLIENT_LOG t, ipnextg.MST_CLIENT m 							
					WHERE a.client_cd = t.client_cd 							
					AND a.mindt = t.cre_dt 							
					AND SUBSTR(subrek,10,3) = '001'							
					AND SUBSTR(subrek,6,4) <> '0000'							
					AND t.item_name = 'SUBREK'							
					AND t.client_cd = m.client_cd 							
					AND ( :dt_end_dt > '31may2012' OR m.client_type_3 <> 'M')							
					)			) x				
	    WHERE s.stk_cd = p.stk_cd(+)		