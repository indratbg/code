create or replace 
PROCEDURE SP_RECON_STK_BAL_MAIN_004(P_BGN_STK VARCHAR2,
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
	INSERT INTO R_RECON_STK_BAL_MAIN_004(MAIN_REK,STK_CD,SECU_END_BAL,KSEI,SELISIH,DT_BGN_DATE,
										DT_END_DATE,USER_ID, GENERATE_DATE, RAND_VALUE)
										
		SELECT  '004' AS Main_rek,  d.stk_cd, d.secu_end_bal, d.ksei, d.secu_end_bal - d.ksei as selisih, P_DT_BGN_DATE,
			P_DT_END_DATE,P_USER_ID,P_GENERATE_DATE,V_RANDOM_VALUE
	 FROM(  SELECT    stk_cd, 						
				SUM(  secu_end_bal) secu_end_bal, 			
				SUM( ksei) ksei 			
		  FROM(    SELECT client_cd, stk_cd, 					
					       SUM( bal) AS secu_end_bal, 		
			               0 ksei 				
		             FROM( SELECT client_cd, stk_cd, gl_acct_cd, 					
						  DECODE(trim(db_cr_flg),'D',1,-1) * 	
						   (NVL(withdrawn_share_qty,0) + NVL(total_share_qty,0)) bal 	
							FROM t_stk_movement 
							WHERE doc_dt BETWEEN P_DT_BGN_DATE AND P_DT_END_DATE 
							AND client_cd  BETWEEN P_BGN_CLIENT AND P_END_CLIENT 
							AND stk_cd BETWEEN P_BGN_STK AND P_END_STK 
							AND gl_acct_cd = '13' 
							AND doc_stat = '2' 
							UNION ALL 
							SELECT  client_cd,  stk_cd,  gl_acct_cd, 
							       qty 
							  FROM t_secu_bal 
							  WHERE bal_dt = P_DT_BGN_DATE 
							  AND client_cd  BETWEEN P_BGN_CLIENT AND P_END_CLIENT 
							  AND stk_cd BETWEEN P_BGN_STK AND P_END_STK 
							  AND gl_acct_cd = '13') 
					GROUP BY client_cd, stk_cd, gl_acct_cd 		
					UNION ALL 		
			    SELECT  '-' client_cd, stk_cd, 				
				       0 secu_end_bal, 			
		               qty AS ksei 					
		      FROM T_stk_ksei					
			  WHERE SUBSTR(sub_rek, 6,7) = '0000004'				
             and bal_dt = P_DT_END_DATE 							
				AND stk_cd BETWEEN P_BGN_STK AND P_END_STK			
				) 			
 		  GROUP BY  stk_cd	) d 				
          WHERE  (d.secu_end_bal <> d.ksei); 							
					
		
		
	 EXCEPTION
			WHEN OTHERS THEN
				 V_ERROR_CD := -30;
				 V_ERROR_MSG := SUBSTR('INSERT R_RECON_STK_BAL_MAIN_004 '||V_ERROR_MSG||SQLERRM(SQLCODE),1,200);
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
END SP_RECON_STK_BAL_MAIN_004;