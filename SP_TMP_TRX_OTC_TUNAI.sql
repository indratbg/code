create or replace PROCEDURE SP_TMP_TRX_OTC_TUNAI(
    p_trx_dt IN DATE,
    p_due_dt IN DATE,
    p_trx_type IN CHAR,
    p_rute  IN CHAR,-- ini dummy
    p_mode IN CHAR,
    p_client_type IN CHAR,
    p_RI IN CHAR,  
    P_RANDOM_VALUE NUMBER,
    P_USER_ID VARCHAR2,             
    P_ERROR_CODE OUT NUMBER,
    P_ERROR_MSG OUT VARCHAR2 )
IS

--[INDRA]14-09-2017 TAMBAH PARAM P_RANDOM_VALUE DAN P_USER_ID KE TABEL TEMP
  V_ERR        EXCEPTION;
  V_ERROR_CODE NUMBER(5);
  V_ERROR_MSG  VARCHAR2(200);
BEGIN
  
    BEGIN
      INSERT
      INTO TMP_OTC
        (
          COL1 , COL2 , COL3 , COL4 , COL5 , COL6 , COL7 , COL8 , COL9 , COL10 , COL11 , COL12 , COL13 , COL14 , COL15 , COL16, RAND_VALUE, USER_ID
        )
      SELECT    TO_CHAR(     p_due_dt,'yyyymmdd')||'_'||t.extref||'_'||instructiontype externalReference,
              instructiontype,
              broker_cd AS participantCode,
              participantAccount,
              broker_cd AS counterpartCode,
              'LOCAL'  securityCodeType,
              t.STK_CD AS securityCode,
              ABS(t.sumqty) AS numberOfSecurities,
              TO_CHAR(     p_trx_dt,'yyyymmdd') AS  tradeDate,
              'IDR' AS currencyCode,
              NULL settlementAmount,
              TO_CHAR(     p_due_dt,'yyyymmdd') AS settlementDate,
                'EXCHG' AS purpose,
                 tc_id  AS tradingReference,
                 NULL AS settlementReason,
                 DECODE(     p_trx_type,'B','BUY ','SELL ')||' TRX '||TO_CHAR(     p_trx_dt,'yyyymmdd')||' '||
                 client_cd AS description, P_RANDOM_VALUE,P_USER_ID
		  FROM( SELECT
		   		   DECODE(SUBSTR(     s_route,6,5),'MAIN1',sourceAccount,targetAccount ) ParticipantAccount,
		   		   stk_cd,  x.client_cd,  ABS(sumqty) sumqty, client_name,
				  stk_cd||'_'||x.client_cd extref,
				   RPAD(stk_cd,7)||'_'||x.client_cd sortk,
				   d.tc_id, 
				   DECODE(    SUBSTR(     s_route,1,5),'MAIN1','RFOP','DFOP')  instructiontype,  seqno, s_route
					FROM(
					SELECT  sourceAccount,targetAccount, MAX(client_name) client_name, client_cd,
		   		   				 stk_cd,  SUM(net_qty) sumqty, seqno, s_route
						FROM(
						SELECT DECODE(SUBSTR(     s_route,1,5),'SUBR1',subrek001,'PAIR1',DECODE(trim(mrkt_type),'TS',broker_001,pair001),
					                           'MAIN1',broker_001)  AS sourceAccount,
		         			DECODE(SUBSTR(     s_route,6,5),'SUBR1',subrek001,'PAIR1',DECODE(trim(mrkt_type),'TS',broker_001,pair001) ,
				                           'MAIN1',broker_001)  AS targetAccount,
							mrkt_type,
						  		client_cd,   stk_cd, client_name,
							 net_qty, seqno, s_route
						  FROM
							(
							SELECT  NVL(subrek001, broker_001) AS subrek001,
							 NVL(subrek004,broker_004) AS subrek004,
							  NVL(pair001, broker_001) AS pair001,
							  broker_001, broker_004,
							  TRADE.client_cd, stk_cd, DECODE(trim(mrkt_type),'TS','TS','RG') mrkt_type,
							   MST_CLIENT.client_name,
							 ( DECODE(buysell, p_trx_type,1,-1) * qty) net_qty,
							 seqno, s_route
							FROM( SELECT client_cd, stk_Cd, buysell, mrkt_type, SUM(cumqty * lotsize) AS qty
													FROM(SELECT clearingaccount AS client_cd, symbol AS stk_cd, cumqty,
													                 DECODE(side,1,'B','J') BuySell, lotsize, DECODE(execbroker, contrabroker,'TS','RG') mrkt_type
													FROM  FOTD_TRADE--V_FOTD_TRADE 14 SEP2017 DI DEV TIDAK ADA, JADI DIGANTI DENGAN FOTD_TRADE
													WHERE trade_date =  p_trx_dt 
													AND symbolsfx = '0TN'
													AND p_RI = 'R')
											GROUP BY client_cd, stk_Cd, buysell, mrkt_type
									              ) TRADE, 
							v_client_subrek14, v_broker_subrek,
							 ( SELECT MST_CLIENT.client_cd,
							   DECODE(custodian_cd,NULL,MST_CIF.cif_name,nama_prsh) AS client_name,
							  custodian_cd,
							 client_type_3
							    FROM MST_CLIENT,MST_CIF, MST_COMPANY
								WHERE MST_CLIENT.cifs IS NOT NULL
								AND MST_CLIENT.cifs =MST_CIF.cifs
								AND MST_CLIENT.client_type_1 <> 'B') MST_CLIENT,
							( SELECT 1 seqno, DECODE( p_trx_type,'B',	 'PAIR1MAIN1','SUBR1MAIN1') AS s_route 
							FROM dual WHERE  p_ri = 'R'
			   				UNION
			   				SELECT 2 seqno, DECODE( p_trx_type,'B',	 'MAIN1SUBR1', 'MAIN1PAIR1') AS s_route 
							FROM dual  WHERE  p_ri = 'R'
							UNION
			   				SELECT 1 seqno, DECODE( p_trx_type,'B',	 'MAIN1SUBR1', 'SUBR1MAIN1') AS s_route 
							FROM dual  WHERE  p_ri = 'I'
							) route			
						  WHERE  TRADE.client_cd = MST_CLIENT.client_cd
							AND TRADE.client_cd = v_client_subrek14.client_cd(+)
							AND ((  v_client_subrek14.pair001  <> v_client_subrek14.subrek001 AND    p_mode = 'SUB2SUB') OR
							           (     p_mode = 'VIAMAIN')  OR mrkt_type = 'TS')
							AND (  (      p_client_type = '%' AND custodian_cd IS  NULL)
								  OR  (      p_client_type = 'C' AND custodian_cd IS  NOT NULL)
								  OR    p_client_type = 'A') ))
								  WHERE  ( sourceaccount <> targetaccount OR mrkt_type = 'TS')
							GROUP BY sourceAccount,targetAccount, client_Cd, stk_cd, mrkt_type, seqno,s_route
							) x ,
		               ( SELECT tc_id, client_cd
						  FROM T_TC_DOC
						  WHERE tc_date =    p_trx_dt
						  AND tc_status = 0) d,
							v_broker_subrek
							WHERE sumqty > 0 
			--	AND sourceaccount <> targetaccount
						AND x.client_cd = d.client_cd(+)
						) T,
						v_broker_subrek 
				ORDER BY instructiontype, t.sortk;
    EXCEPTION
    WHEN OTHERS THEN
      V_ERROR_CODE :=-10;
      V_ERROR_MSG  :=SUBSTR( 'INSERT INTO TMP_OTC ' || SQLERRM,1,200);
      RAISE V_ERR;
    END;
  
  
  P_ERROR_CODE:=1;
  P_ERROR_MSG :='';
EXCEPTION
WHEN V_ERR THEN
  ROLLBACK;
  P_ERROR_CODE :=V_ERROR_CODE ;
  P_ERROR_MSG  := V_ERROR_MSG;
WHEN OTHERS THEN
  ROLLBACK;
  P_ERROR_CODE :=-1;
  P_ERROR_MSG  :=SUBSTR( SQLERRM(SQLCODE),1,200);
END SP_TMP_TRX_OTC_TUNAI;