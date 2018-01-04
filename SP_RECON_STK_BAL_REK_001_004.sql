create or replace 
PROCEDURE SP_RECON_STK_BAL_REK_001_004(P_SUBREK_TYPE VARCHAR2,
									P_BGN_STK VARCHAR2,
									P_BGN_CLIENT VARCHAR2,
									P_END_STK VARCHAR2,
									P_END_CLIENT VARCHAR2,
									P_ALL_RECORD VARCHAR2,
									P_DT_END_DATE DATE,
									P_DT_BGN_DATE DATE,
									P_USER_ID VARCHAR2,
									P_GENERATE_DATE 	DATE,
									P_RANDOM_VALUE	OUT NUMBER,
								   P_ERROR_MSG OUT VARCHAR2,
								   P_ERROR_CD OUT NUMBER) IS


V_ERROR_MSG VARCHAR2(200);
V_ERROR_CD NUMBER(10);
v_random_value	NUMBER(10);
V_ERR EXCEPTION;

 BEGIN
 
 
   v_random_value := abs(dbms_random.random);

    BEGIN
        SP_RPT_REMOVE_RAND('R_RECON_STK_BAL_REK_001_004',V_RANDOM_VALUE,V_ERROR_MSG,V_ERROR_CD);
    EXCEPTION
        WHEN OTHERS THEN
             V_ERROR_CD := -10;
             V_ERROR_MSG := SUBSTR('SP_RPT_REMOVE_RAND '||V_ERROR_MSG||SQLERRM(SQLCODE),1,200);
            RAISE V_err;
    END;
	
	IF V_ERROR_CD<0 THEN
			V_ERROR_CD := -20;
             V_ERROR_MSG := SUBSTR('SP_RPT_REMOVE_RAND'||V_ERROR_MSG,1,200);
            RAISE V_ERR;
	END IF;
 
 
           
 
	BEGIN 
	INSERT INTO R_RECON_STK_BAL_REK_001_004(SKEY,SUBREK004,CLIENT_CD,SUBREK001,STK_CD,
										PDATE_THEO,PDATE_ONH,SECU_ONH,NORUT,IP_QTY,
										KSEI_QTY,SELISIH,USER_ID,GENERATE_DATE,RAND_VALUE,DT_BGN_DATE,DT_END_DATE)
										
    SELECT skey, subrek004,  client_cd, subrek001,stk_cd, 												
	    	pdate_theo, pdate_onh,  secu_onh, 										
			norut, 									
			DECODE(norut,1, ip_qty, 0) ip_qty, 									
			DECODE(norut,1, ksei_qty, 0) ksei_qty, 									
			DECODE( ip_qty,ksei_qty,'','SELISIH') Selisih,P_USER_ID, P_GENERATE_DATE, V_RANDOM_VALUE,
      P_DT_BGN_DATE,P_DT_END_DATE
FROM(												
 SELECT skey,subrek001,subrek004, 												
	  		 client_cd, 									
	  		  stk_cd, 									
	    	pdate_theo, pdate_onh,  secu_onh, 										
			SUM(  DECODE(P_SUBREK_TYPE,'001',secu_onh - acct13, acct13)) over (PARTITION BY skey, stk_cd ORDER BY skey, stk_cd ) AS ip_qty, 									
			SUM(  ksei) over (PARTITION BY skey, stk_cd ORDER BY skey, stk_cd ) AS ksei_qty, 									
			row_number() over  (PARTITION BY skey, stk_cd ORDER BY skey, stk_cd, client_cd DESC) norut 									
	 FROM( 											
	 SELECT skey, subrek001, subrek004,  client_cd, stk_cd, 											
				SUM(  secu_end_theo) secu_theo, 								
				SUM(  secu_end_onh) secu_onh, 								
				SUM(  acct13) acct13, 								
				SUM( pdate_beg_theo + pdate_mvmt_theo) pdate_theo, 								
				SUM( pdate_beg_onh + pdate_mvmt_onh) pdate_onh, 								
				SUM( ksei) ksei 								
		  FROM(										
		   SELECT subrek001,subrek004,skey, x.client_cd, x.stk_cd, 										
				       x.secu_end_theo, x.secu_end_onh * DECODE(P_SUBREK_TYPE,'004',0,1) secu_end_onh,								
						 x.secu_end_bal, x.secu_os_buy, x.secu_os_sell, 						
					   x.acct13 , x.curr_onh, x.pdate_beg_theo, x.pdate_beg_onh, 							
					   x.pdate_mvmt_theo, x.pdate_mvmt_onh, x.ksei 							
				FROM( 								
				 SELECT client_cd, stk_cd, 								
					       SUM(DECODE(trim(gl_acct_cd),'10',1,'12',1,'13',1,'14',1,'51',1,0) * (beg_bal + mvmt)) secu_end_theo, 							
					       SUM(DECODE(trim(gl_acct_cd),'36',1,'33',0,0) * (beg_bal + mvmt)) secu_end_onh, 							
					       SUM( beg_bal + mvmt) AS secu_end_bal, 							
						   SUM(DECODE(trim(gl_acct_cd),'59',-1,'55',-1,0) * (beg_bal + mvmt)) secu_os_buy, 						
						   SUM(DECODE(trim(gl_acct_cd),'17',1,'21',1,0) * (beg_bal + mvmt)) secu_os_sell, 						
						   SUM(DECODE(trim(gl_acct_cd),'09',1,0) * (beg_bal + mvmt)) acct13, 						
					       0 curr_onh, 							
					       0 pdate_beg_theo, 							
					        0 pdate_beg_onh, 							
							0 pdate_mvmt_theo, 					
							0 pdate_mvmt_onh, 					
			               0 ksei 									
		             FROM( SELECT client_cd, stk_cd, gl_acct_cd, 										
				     	          0 beg_bal, 							
								   DECODE(trim(gl_acct_cd), '36',-1, 1) * 				
								   DECODE(trim(db_cr_flg),'D',1,-1) * 				
								   (NVL(withdrawn_share_qty,0) + NVL(total_share_qty,0)) mvmt 				
							FROM T_STK_MOVEMENT 					
							WHERE doc_dt BETWEEN P_DT_BGN_DATE AND P_DT_END_DATE 					
							AND client_cd  BETWEEN P_BGN_CLIENT AND P_END_CLIENT 					
							AND stk_cd BETWEEN P_BGN_STK AND P_END_STK 					
							AND gl_acct_cd IS NOT NULL 					
							AND doc_stat = '2' 					
							UNION ALL 					
							SELECT  client_cd,  stk_cd,  gl_acct_cd, 					
							       DECODE(SIGN(TO_NUMBER(trim(gl_acct_cd)) - 37), 1,-1, 1) * 					
								   qty AS beg_bal, 				
								   0 mvmt 				
							  FROM T_SECU_BAL 					
							  WHERE bal_dt = P_DT_BGN_DATE 					
							  AND client_cd  BETWEEN P_BGN_CLIENT AND P_END_CLIENT 					
							  AND stk_cd BETWEEN P_BGN_STK AND P_END_STK 					
							  AND gl_acct_cd <> '33'					
							  ) 					
					GROUP BY client_cd, stk_cd, gl_acct_cd 							
					UNION ALL							
			        SELECT client_cd, stk_cd, 									
						   0 secu_end_theo, 						
						   0 secu_end_onh, 						
					       0 secu_end_bal, 							
						   0 secu_os_buy, 						
						   0 secu_os_sell, 						
						   0 curr_theo, 						
					       0 curr_onh, 							
					       0 pdate_beg_theo, 							
					        0 pdate_beg_onh, 							
							(NVL(DECODE(SUBSTR(doc_num,5,2),'BR',1,'JR',1,'BI',1,'JI',1,'RS',1,'WS',1,0) * 					
						  DECODE(trim(NVL(gl_acct_cd,'36')),'14',1,'51',1,'12',1,'13',1,'10',1,0) * DECODE(db_cr_flg,'D',1,-1) * 						
						  (total_share_qty + withdrawn_share_qty),0)) pdate_mvmt_theo, 						
						  (NVL(DECODE(SUBSTR(doc_num,5,2),'JV',1,'XS',0,'LS',0,'RS',1,'WS',1,'CS',1,0) * 						
						  DECODE(trim(NVL(gl_acct_cd,'36')),'36',1, 0) * DECODE(db_cr_flg,'D',-1,1) * 						
						  (total_share_qty + withdrawn_share_qty),0)) pdate_mvmt_onh, 						
			               0 ksei 									
					FROM T_STK_MOVEMENT 							
					WHERE doc_dt BETWEEN P_DT_BGN_DATE AND P_DT_END_DATE 							
					AND client_cd  BETWEEN P_BGN_CLIENT AND P_END_CLIENT 							
					AND stk_cd BETWEEN P_BGN_STK AND P_END_STK 							
					AND gl_acct_cd IS NOT NULL 							
					AND gl_acct_cd IN ('14','51','10','12','13','33','36') 							
					AND doc_stat = '2' 							
					AND SUBSTR(doc_num,5,3) <> 'JAD' 							
					UNION ALL 							
					SELECT client_cd, stk_cd, 							
						   0 secu_end_theo, 						
						   0 secu_end_onh, 						
					       0 secu_end_bal, 							
						   0 secu_os_buy, 						
						   0 secu_os_sell, 						
						   0 curr_theo, 						
					       0 curr_onh, 							
					       beg_bal_qty AS pdate_beg_theo, 							
					       beg_on_hand  + on_lent - on_borrow AS pdate_beg_onh, 							
					       0 pdate_mvmt_theo, 							
					       0 pdate_mvmt_onh, 							
			               0 ksei 									
					  FROM T_STKBAL 							
					  WHERE BAL_DT = P_DT_BGN_DATE 							
					    AND client_cd  BETWEEN P_BGN_CLIENT AND P_END_CLIENT 							
						AND stk_cd BETWEEN P_BGN_STK AND P_END_STK 						
					  AND   (beg_on_hand <> 0 OR beg_bal_qty <> 0 OR on_lent <> 0 OR on_borrow <> 0)							
					  ) x, 							
			     ( 									
				 SELECT subrek001,subrek004, 								
				 		 DECODE(P_SUBREK_TYPE,'001',subrek001,subrek004) skey, 						
				 		m.client_cd,						
						0 client004  						
			         FROM ( SELECT client_Cd									
					     FROM MST_CLIENT 							
						 WHERE susp_stat = 'N'						
						 UNION 						
						 SELECT client_Cd						
						 FROM T_CLIENT_CLOSING						
						 WHERE TRUNC(upd_dt) >= P_DT_END_DATE)						 m, 
						 v_client_subrek14 v 						
				    WHERE m.client_cd  BETWEEN P_BGN_CLIENT AND P_END_CLIENT 								
					  AND (( P_SUBREK_TYPE ='001') 							
					       OR ( P_SUBREK_TYPE ='004')) 							
					  AND m.client_cd = v.client_cd 							
					  AND SUBSTR(NVL(subrek001,'XXXXX0000'),6,4) <> '0000' 							
					  ) m 							
				WHERE x.client_cd = m.client_cd 								
				UNION ALL 								
			    SELECT  DECODE(P_SUBREK_TYPE,'001',sub_rek,'-') AS subrek001, 									
						DECODE(P_SUBREK_TYPE,'004',sub_rek, '-') AS subrek004, 						
						sub_rek AS skey, 						
						 '%' client_cd, stk_cd, 						
					   0 secu_end_theo, 							
					   0 secu_end_onh, 							
				       0 secu_end_bal, 								
					   0 secu_os_buy, 							
					   0 secu_os_sell, 							
					   0 curr_theo, 							
				       0  curr_onh, 								
					   0 pdate_beg_theo, 							
				       0 pdate_beg_onh, 								
				       0 pdate_mvmt_theo, 								
				       0 pdate_mvmt_onh, 								
		               qty AS ksei 										
		      FROM T_STK_KSEI 										
			  WHERE SUBSTR(sub_rek, 6,4) <> '0000' 									
			  AND SUBSTR(sub_rek, 10,3) = P_SUBREK_TYPE 									
             AND bal_dt = P_DT_END_DATE 												
             AND stk_cd BETWEEN P_BGN_STK AND P_END_STK 												
           UNION												
			    SELECT  DECODE(P_SUBREK_TYPE,'001',sub_rek,'-') AS subrek001, 									
						DECODE(P_SUBREK_TYPE,'004',sub_rek, '-') AS subrek004, 						
						sub_rek AS skey, 						
						 '%' client_cd, stk_cd, 						
					   0 secu_end_theo, 							
					   0 secu_end_onh, 							
				       0 secu_end_bal, 								
					   0 secu_os_buy, 							
					   0 secu_os_sell, 							
					   0 curr_theo, 							
				       0  curr_onh, 								
					   0 pdate_beg_theo, 							
				       0 pdate_beg_onh, 								
				       0 pdate_mvmt_theo, 								
				       0 pdate_mvmt_onh, 								
		               qty AS ksei 										
		      FROM T_STK_KSEI_HIST										
			  WHERE bal_dt = P_DT_END_DATE 									
           AND SUBSTR(sub_rek, 6,4) <> '0000' 												
			  AND SUBSTR(sub_rek, 10,3) = P_SUBREK_TYPE 									
             AND stk_cd BETWEEN P_BGN_STK AND P_END_STK 												
			  ) 									
		  GROUP BY  skey, subrek004,subrek001, client_cd, stk_cd 										
		  )										
		    WHERE secu_onh <> 0 OR ksei <> 0 OR acct13 <> 0										
		  ) 										
		  WHERE (client_cd <> '%' OR norut =1) 										
		  AND ( pdate_onh <> 0 OR secu_onh <> 0 OR NVL(ksei_qty,0) <> 0) 										
		  AND (NOT (NVL(ip_qty,0) =0 AND NVL(ksei_qty,0) = 0)) 										
			AND ((ksei_qty <> ip_qty AND P_ALL_RECORD = 'N') OR P_ALL_RECORD = 'Y') 									
	ORDER BY  stk_cd, skey, norut;											
	 EXCEPTION
			WHEN OTHERS THEN
				 V_ERROR_CD := -30;
				 V_ERROR_MSG := SUBSTR('INSERT R_RECON_STK_BAL_001_004 '||V_ERROR_MSG||SQLERRM(SQLCODE),1,200);
				RAISE V_err;
		END;
	
P_RANDOM_VALUE :=V_RANDOM_VALUE;	
P_ERROR_CD := 1 ;
P_ERROR_MSG := '';

 EXCEPTION
  WHEN V_ERR THEN
        ROLLBACK;
     P_ERROR_MSG := V_ERROR_MSG;
		P_ERROR_CD := V_ERROR_CD;
  WHEN OTHERS THEN
   P_ERROR_CD := -1 ;
   P_ERROR_MSG := SUBSTR(SQLERRM(SQLCODE),1,200);
   RAISE;
END SP_RECON_STK_BAL_REK_001_004;