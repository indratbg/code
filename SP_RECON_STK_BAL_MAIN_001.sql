create or replace 
PROCEDURE SP_RECON_STK_BAL_MAIN_001(P_BGN_STK VARCHAR2,
											P_CURR VARCHAR2,
											P_BGN_CLIENT VARCHAR2,
											P_END_STK VARCHAR2,
											P_END_CLIENT VARCHAR2,
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
 
--          V_ERROR_CD := -100;
--             V_ERROR_MSG := P_END_STK;
--            RAISE V_err;
-- 
 
   v_random_value := abs(dbms_random.random);

    BEGIN
        SP_RPT_REMOVE_RAND('R_RECON_STK_BAL_MAIN_ACCT_001',V_RANDOM_VALUE,V_ERROR_MSG,V_ERROR_CD);
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
	INSERT INTO R_RECON_STK_BAL_MAIN_001(SUB_REK,STK_CD,SECU_THEO,SECU_ONH,SECU_OS_BUY,SECU_OS_SELL,
							CURR_THEO,CURR_ONH,PDATE_THEO,PDATE_ONH,KSEI,
							C_THEO,C_ONH,SELISIH,USER_ID,GENERATE_DATE, RAND_VALUE,DT_BGN_DATE,DT_END_DATE)
	SELECT  '001' AS sub_rek,  d.stk_cd, d.secu_theo, d.secu_onh, d.secu_os_buy, d.secu_os_sell, 							
			d.curr_theo, d.curr_onh, 					
			d.pdate_theo, d.pdate_onh, 					
			d.ksei, 					
			d.c_theo, 					
			d.c_onh,					
 			d.pdate_onh - d.ksei as selisih,p_user_id, p_generate_date,		V_RANDOM_VALUE,
      P_DT_BGN_DATE,P_DT_END_DATE
	 FROM(  SELECT    stk_cd, 							
				SUM(  secu_end_theo) secu_theo, 				
				SUM(  secu_end_onh) secu_onh, 				
				SUM( secu_os_buy) secu_os_buy, 				
				SUM( secu_os_sell) secu_os_sell, 				
				SUM(  curr_theo) curr_theo, 				
				SUM( curr_onh) curr_onh, 				
				SUM( pdate_beg_theo + pdate_mvmt_theo) pdate_theo, 				
				SUM( pdate_beg_onh + pdate_mvmt_onh) pdate_onh, 				
				SUM( ksei) ksei, 				
				SUM(DECODE(P_CURR,'Y', curr_theo, pdate_beg_theo + pdate_mvmt_theo )) c_theo, 				
				SUM(DECODE(P_CURR,'Y',curr_onh,pdate_beg_onh + pdate_mvmt_onh)) c_onh 				
		  FROM(  SELECT m.sub_rek,  x.stk_cd,						
				       x.secu_end_theo, x.secu_end_onh, x.secu_end_bal, x.secu_os_buy, x.secu_os_sell,				
					   x.curr_theo, x.curr_onh, x.pdate_beg_theo, x.pdate_beg_onh, 			
					   x.pdate_mvmt_theo, x.pdate_mvmt_onh, x.ksei			
				FROM(  SELECT client_cd, stk_cd, 				
					       SUM(DECODE(trim(gl_acct_cd),'10',1,'12',1,'13',1,'14',1,'51',1,0) * (beg_bal + mvmt)) secu_end_theo, 			
					       SUM(DECODE(trim(gl_acct_cd),'36',1,'33',0,0) * (beg_bal + mvmt)) secu_end_onh, 			
					       SUM( beg_bal + mvmt) AS secu_end_bal, 			
						   SUM(DECODE(trim(gl_acct_cd),'59',-1,'55',-1,0) * (beg_bal + mvmt)) secu_os_buy, 		
						   SUM(DECODE(trim(gl_acct_cd),'17',1,'21',1,0) * (beg_bal + mvmt)) secu_os_sell, 		
						   0 curr_theo, 		
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
							FROM t_stk_movement 	
							WHERE doc_dt BETWEEN P_DT_BGN_DATE AND P_DT_END_DATE 	
							AND client_cd  BETWEEN P_BGN_CLIENT AND P_END_CLIENT 	
							AND SUBSTR(client_cd,8,1) <> 'M' 	
							AND stk_cd BETWEEN P_BGN_STK AND P_END_STK 	
							AND gl_acct_cd IS NOT NULL 	
							AND doc_stat = '2' 	
							UNION ALL 	
							SELECT  client_cd,  stk_cd,  gl_acct_cd, 	
							       DECODE(SIGN(TO_NUMBER(trim(gl_acct_cd)) - 37), 1,-1, 1) * 	
								   qty AS beg_bal, 
								   0 mvmt 
							  FROM t_secu_bal 	
							  WHERE bal_dt = P_DT_BGN_DATE 	
							  AND client_cd  BETWEEN P_BGN_CLIENT AND P_END_CLIENT 	
							  AND SUBSTR(client_cd,8,1) <> 'M' 	
							  AND stk_cd BETWEEN P_BGN_STK AND P_END_STK 	
							  AND gl_acct_cd <> '33') 	
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
							(NVL(DECODE(SUBSTR(doc_num,5,2),'BR',1,'JR',1,'BI',1,'JI',1,'RS',1,'WS',1,'BO',1,'JO',1,0) * 	
						  DECODE(trim(NVL(gl_acct_cd,'36')),'14',1,'51',1,'12',1,'13',1,'10',1,0) * DECODE(db_cr_flg,'D',1,-1) * 		
						  (total_share_qty + withdrawn_share_qty),0)) pdate_mvmt_theo, 		
						  (NVL(DECODE(SUBSTR(doc_num,5,2),'JV',1,'XS',0,'LS',0,'RS',1,'WS',1,'CS',1,0) * 		
						  DECODE(trim(NVL(gl_acct_cd,'36')),'36',1, 0) * DECODE(db_cr_flg,'D',-1,1) * 		
						  (total_share_qty + withdrawn_share_qty),0)) pdate_mvmt_onh, 		
			               0 ksei 					
					FROM t_stk_movement 			
					WHERE doc_dt BETWEEN P_DT_BGN_DATE AND P_DT_END_DATE 			
					AND client_cd  BETWEEN P_BGN_CLIENT AND P_END_CLIENT 			
					AND SUBSTR(client_cd,8,1) <> 'M' 			
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
					       beg_on_hand + on_lent - on_borrow AS pdate_beg_onh, 			
					       0 pdate_mvmt_theo, 			
					       0 pdate_mvmt_onh, 			
			               0 ksei 					
					  FROM t_stkbal 			
					  WHERE BAL_DT = P_DT_BGN_DATE 			
					    AND client_cd  BETWEEN P_BGN_CLIENT AND P_END_CLIENT 			
						AND SUBSTR(client_cd,8,1) <> 'M' 		
					  AND stk_cd BETWEEN P_BGN_STK AND P_END_STK 			
					  AND   (beg_on_hand <> 0 OR beg_bal_qty <> 0 OR on_lent <> 0 OR on_borrow <> 0)	 ) x, 		
			     ( SELECT agreement_no AS sub_rek, client_cd 					
			         FROM mst_client 					
				    WHERE client_cd  BETWEEN P_BGN_CLIENT AND P_END_CLIENT 				
					  AND client_type_3 <> 'M' 			
					  AND SUBSTR(nvl(agreement_no,'XXXXX0000001'),6,7) = '0000001') m 			
				WHERE x.client_cd = m.client_cd 				
				UNION ALL 				
			    SELECT  sub_rek, stk_cd, 					
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
		      FROM t_stk_ksei						
			  WHERE SUBSTR(sub_rek, 6,7) = '0000001' 					
             and bal_dt = P_DT_END_DATE								
             AND stk_cd BETWEEN P_BGN_STK AND P_END_STK) 								
 		  GROUP BY  stk_cd	) d 					
          WHERE  ((d.secu_theo <> d.pdate_theo OR d.secu_theo <>  d.c_theo OR d.pdate_theo <> d.c_theo) 								
			  OR (d.secu_onh <> d.pdate_onh OR d.secu_onh <>  d.c_onh OR d.pdate_onh <> d.c_onh) 					
			  OR (d.secu_onh <> d.ksei OR d.pdate_onh <> d.ksei));					
		
	 EXCEPTION
			WHEN OTHERS THEN
				 V_ERROR_CD := -30;
				 V_ERROR_MSG := SUBSTR('INSERT R_STK_BAL_MAIN_ACCT_001 '||V_ERROR_MSG||SQLERRM(SQLCODE),1,200);
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
END SP_RECON_STK_BAL_MAIN_001;