
  CREATE OR REPLACE FORCE VIEW "IPNEXTG"."V_GENERATE_OTC_FEE" ("CLIENT_CD", "CLIENT_NAME", "SUM_OTC_CLIENT", "SUM_OTC_REPO_JUAL", "SUM_OTC_REPO_BELI", "JUR", "CLOSED") AS 
  SELECT client_cd, client_name, 						
       SUM(otc_client) sum_otc_client, 0 sum_otc_repo_jual, 						
       0 sum_otc_repo_beli,						
       jur, closed						
FROM(  SELECT  x.DOC_DT, x.CLIENT_CD, x.STK_CD, 						
				 x.withdraw_reason_cd, x.client_name, 		
					x.otc_client * DECODE(SIGN(rw_cnt),0,1,  DECODE(SIGN(y.net_qty * x.doc_type),0,0,1,1,-1,0) 	
		                                 * DECODE(x.doc_num,y.minr_doc_num,1,y.minw_doc_num,1,0) ) otc_client, 				
					DECODE(c.client_cd,NULL,jur,'N') jur ,  DECODE(c.client_cd,NULL,'','CLOSED') closed	
		FROM( SELECT  a.DOC_DT, a.CLIENT_CD, a.STK_CD, a.doc_num,a.total_share_qty + a.withdrawn_share_qty AS qty, 				
				 a.withdraw_reason_cd, b.client_name, 		
				  DECODE(LENGTH(trim(a.client_cd)),2,0,1) * 20000 otc_client, 		
				  DECODE(SUBSTR(a.doc_num,5,3),'RSN',1,'WSN',-1,0) AS doc_type, 		
				  b.acopen_fee_flg jur		
				FROM T_STK_MOVEMENT a, MST_CLIENT b		
				WHERE a.seqno = 1 		
				AND SUBSTR(a.DOC_NUM,5,3) IN ('RSN','WSN','JVB','JVS') 		
				AND a.client_cd = b.client_cd 		
				AND a.doc_stat = '2' 		
				--AND a.doc_dt BETWEEN to_date('1jan2013','ddmmyyyy') AND sysdate 	
				AND a.withdraw_reason_cd IS NOT NULL) x, 		
			(  SELECT  a.DOC_DT, a.CLIENT_CD, a.STK_CD, 			
					SUM(DECODE(SUBSTR(doc_num,5,1),'J',0,a.total_share_qty - a.withdrawn_share_qty)) AS net_qty, 	
					MIN(DECODE(SUBSTR(doc_num,5,1),'R',doc_num,'_')) minr_doc_num, 	
					MIN(DECODE(SUBSTR(doc_num,5,1),'W',doc_num,'_')) minw_doc_num,	
					SUM(DECODE(SUBSTR(doc_num,5,1),'R',1,0)) *	SUM(DECODE(SUBSTR(doc_num,5,1),'W',1,0)) RW_cnt  
				FROM T_STK_MOVEMENT a 		
				WHERE a.seqno = 1 		
				AND SUBSTR(a.DOC_NUM,5,3) IN ('RSN','WSN','JVS','JVB') 		
				AND a.doc_stat = '2' 		
				--AND a.doc_dt BETWEEN to_date('1jan2013','ddmmyyyy') AND sysdate 	 		
				AND a.withdraw_reason_cd IS NOT NULL 		
				GROUP BY a.DOC_DT, a.CLIENT_CD, a.STK_CD) y, 		
			( SELECT client_cd			
			FROM T_CLIENT_CLOSING			
			WHERE --TRUNC(cre_Dt) BETWEEN ( to_date('1jan2013','ddmmyyyy') - 32) AND  sysdate		
--			AND
			new_stat = 'C') c			
	WHERE x.doc_dt = y.doc_dt 					
	AND x.client_cd = y.client_cd 					
	AND x.stk_cd = y.stk_cd 					
	AND x.client_Cd = c.client_cd(+)) 					
GROUP BY client_cd, client_name,jur, closed 		

UNION 						
SELECT '_REPO','OTC REPO', 0, 						
      SUM(stk_cnt * repo_jual) sum_otc_repo_jual, 						
      SUM(stk_cnt * repo_beli) sum_otc_repo_beli,						
      'Y' jur, '' closed 						
FROM( SELECT  a.withdraw_reason_cd AS broker, a.DOC_DT, 						
		COUNT(DISTINCT a.stk_cd) stk_cnt, 				
		 DECODE(trim(a.gl_acct_cd),'50',1,0) * 20000 repo_jual, 				
       DECODE(trim(a.gl_acct_cd),'09',1,0) * 20000 repo_beli 						
FROM T_STK_MOVEMENT a, MST_CLIENT b 						
WHERE a.gl_acct_cd <> '36' 						
AND SUBSTR(a.DOC_NUM,5,3) = 'JVA' 						
AND a.client_cd = b.client_cd 						
AND a.doc_stat = '2' 						
--AND a.doc_dt BETWEEN to_date('1jan2013','ddmmyyyy') AND sysdate 						
AND a.withdraw_reason_cd IS NOT NULL 						
AND b.acopen_fee_flg = 'Y' 						
GROUP BY  a.withdraw_reason_cd, a.DOC_DT, a.gl_acct_cd);
 
