SELECT 'CASHDIV' ca_type, STK_CD, :P_DISTRIB_DT distrib_dt, CLIENT_CD,QTY, SELISIH,							
		:P_RATE rate,					
    --CASH_DIVIDEN							
    GROSS, TAX_PCN, ROUND(TAX_PCN * GROSS,2) TAX, ROUND(CASH_DIVIDEN -  ROUND(TAX_PCN * GROSS,2),2) DEVIDEN,							
		:P_USER_ID user_id , 0 VL_RANDOM_VALUE, BRANCH_CODE, REM_CD, 					
		REM_NAME, CLIENT_TYPE_3, CLIENT_NAME,					
		CLIENT_TYPE_1,CLIENT_TYPE_2, 'Y' FLG, NVL(RECOV_CHARGE_FLG,'N') RECOV_CHARGE_FLG,					
		TO_DATE(:P_GENERATE_DATE,'YYYY-MM-DD') generate_date, TO_DATE(:P_RECORDING_DT,'YYYY-MM-DD') recording_dt,:P_CUM_DT	cum_dt				
		FROM(					
	SELECT M.BRANCH_CODE, M.REM_CD, S.REM_NAME, M.CLIENT_TYPE_3, 						
	B.CLIENT_CD, M.CLIENT_NAME, B.STK_CD, B.CUM_QTY, B.QTY, DECODE(:P_PENGALI,0,0,(B.QTY * :P_PENGALI / :P_PEMBAGI)) DIV_STK,						
	(B.QTY * :P_RATE + DECODE(:P_PENGALI,0,0,TRUNC(B.QTY * :P_PENGALI / :P_PEMBAGI,0)) * :P_PRICE ) GROSS, P.TAX_PCN,						
	B.QTY * :P_RATE AS CASH_DIVIDEN, SELISIH,						
	M.CLIENT_TYPE_2,  M.CLIENT_TYPE_1, NVL(M.RECOV_CHARGE_FLG,'N') RECOV_CHARGE_FLG  						
	FROM(   SELECT CLIENT_CD, STK_CD, SUM(QTY) CUM_QTY, 						
	                                   SUM(ONH)  ONH, DECODE(SIGN(TRUNC(SYSDATE) - TO_DATE(:P_RECORDING_DT,'YYYY-MM-DD')),1,SUM(ONH),SUM(QTY)) QTY,						
		    DECODE(SIGN(TRUNC(SYSDATE) - TO_DATE(:P_RECORDING_DT,'YYYY-MM-DD')),1,SUM(ONH) - SUM(QTY),0) SELISIH					
		FROM(  SELECT CLIENT_CD, STK_CD, BEG_BAL_QTY AS QTY, BEG_ON_HAND AS ONH					
				FROM IPNEXTG.T_STKBAL 			
				 WHERE BAL_DT = TO_DATE(:P_BGN_DT,'YYYY-MM-DD')			
				AND STK_CD = :P_STK_CD 			
			UNION ALL				
			  SELECT CLIENT_CD, STK_CD,   				  
				DECODE(DB_CR_FLG,'D',1,-1) * (TOTAL_SHARE_QTY + WITHDRAWN_SHARE_QTY) MVMT, 0 ONH			
			FROM IPNEXTG.T_STK_MOVEMENT 				
			  WHERE DOC_DT BETWEEN  TO_DATE(:P_BGN_DT,'YYYY-MM-DD') AND TO_DATE(:P_CUM_DT,'YYYY-MM-DD')				
			AND SUBSTR(DOC_NUM,5,2) IN ('RS','WS','JR','BR','JI','BI')				
			 AND GL_ACCT_CD IS NOT NULL 				
			 AND TRIM(GL_ACCT_CD) IN ('10','12','13','14','51')				
			 AND DOC_STAT = '2' 				
			AND STK_CD = :P_STK_CD				
			UNION ALL				
			  SELECT CLIENT_CD, STK_CD,   0 ,				  
				DECODE(DB_CR_FLG,'D',-1,1) * (TOTAL_SHARE_QTY + WITHDRAWN_SHARE_QTY)  ONH			
			FROM IPNEXTG.T_STK_MOVEMENT 				
			  WHERE DOC_DT BETWEEN  TO_DATE(:P_BGN_DT,'YYYY-MM-DD') AND		TO_DATE(:P_RECORDING_DT,'YYYY-MM-DD')		
			  AND TO_DATE(:P_RECORDING_DT,'YYYY-MM-DD') < TRUNC(SYSDATE)				
			 AND GL_ACCT_CD IS NOT NULL 				
			 AND TRIM(GL_ACCT_CD) IN ('36')				
			 AND DOC_STAT = '2' 				
			AND STK_CD = :P_STK_CD				
			) 				
			GROUP BY CLIENT_CD, STK_CD				
			HAVING SUM( QTY) > 0 ) B, 				
	(   SELECT CLIENT_CD,  TO_NUMBER(TAX_RATE) / 100 TAX_PCN 						
			FROM(   SELECT M.CLIENT_CD,   				
					DECODE(A.RATE_OVER25PERSEN,NULL, DECODE(M.RATE_NO,2,R.RATE_2,1,R.RATE_1,0), A.RATE_OVER25PERSEN)  TAX_RATE		
				FROM(  SELECT CLIENT_CD, NVL(MST_CIF.BIZ_TYPE, MST_CLIENT.BIZ_TYPE) BIZ_TYPE, 			
				 		NVL(MST_CIF.NPWP_NO, MST_CLIENT.NPWP_NO) NPWP_NO,	
						 DECODE(CLIENT_CD,TRIM(OTHER_1),'H',NVL(MST_CIF.CLIENT_TYPE_1,MST_CLIENT.CLIENT_TYPE_1)) AS CLIENT_TYPE_1,	
						  NVL(MST_CIF.CLIENT_TYPE_2,MST_CLIENT.CLIENT_TYPE_2)CLIENT_TYPE_2,	
						  DECODE(NVL(MST_CIF.NPWP_NO, MST_CLIENT.NPWP_NO),NULL,2,1)    	
						  * DECODE(NVL(MST_CIF.BIZ_TYPE, MST_CLIENT.BIZ_TYPE),'PF',0,'FD',0,1)  RATE_NO	
					FROM IPNEXTG.MST_CLIENT, IPNEXTG.MST_COMPANY, IPNEXTG.MST_CIF		
					WHERE  MST_CLIENT.CIFS = MST_CIF.CIFS(+)		
					AND NVL(MST_CIF.CLIENT_TYPE_1,MST_CLIENT.CLIENT_TYPE_1) <> 'B') M,		
					( SELECT CLIENT_CD, RATE_1 AS RATE_OVER25PERSEN		
					  FROM IPNEXTG.MST_TAX_RATE		
						WHERE TO_DATE(:P_RECORDING_DT,'YYYY-MM-DD') BETWEEN BEGIN_DT AND END_DT	
						AND TAX_TYPE = 'DIVTAX'	
						AND CLIENT_CD IS NOT NULL	
						AND STK_CD IS NOT NULL	
						AND STK_CD = :P_STK_CD ) A,	
					( SELECT *		
					  FROM IPNEXTG.MST_TAX_RATE		
						WHERE TO_DATE(:P_RECORDING_DT,'YYYY-MM-DD') BETWEEN BEGIN_DT AND END_DT	
						AND TAX_TYPE = 'DIVTAX'	
						AND CLIENT_CD IS  NULL	
						AND STK_CD IS  NULL ) R	
					WHERE  M.CLIENT_TYPE_2 LIKE R.CLIENT_TYPE_2		
					AND M.CLIENT_TYPE_1 LIKE R.CLIENT_TYPE_1		
					AND M.CLIENT_CD = A.CLIENT_CD (+))) P,		
		IPNEXTG.MST_CLIENT M, IPNEXTG.MST_SALES S 					
		WHERE  B.CLIENT_CD = P.CLIENT_CD (+) 					
		AND B.CLIENT_CD = M.CLIENT_CD					
		AND M.BRANCH_CODE BETWEEN :P_BGN_BRANCH AND :P_END_BRANCH					
		AND M.CLIENT_CD BETWEEN :P_BGN_CLIENT AND :P_END_CLIENT					
		AND M.REM_CD = S.REM_CD					
		AND B.ONH > 0)					
