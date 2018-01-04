create or replace PROCEDURE SP_TMP_TRX_STK_TUNAI(
    p_trx_dt IN DATE,
    p_due_dt IN DATE,
    p_trx_type IN CHAR,
    p_rute  IN CHAR,
    p_mode IN CHAR, -- dummy
    p_client_type IN CHAR,
    p_RI IN CHAR, 
    P_RANDOM_VALUE NUMBER,
    P_USER_ID VARCHAR2,                  
    P_ERROR_CODE OUT NUMBER,
    P_ERROR_MSG OUT VARCHAR2 )
IS
--[INDRA]14-09-2017 TAMBAH PARAM P_RANDOM_VALUE DAN P_USER_ID KE TABEL TEMP
  v_xml_type varchar2(3);

  V_ERR        EXCEPTION;
  V_ERROR_CODE NUMBER(5);
  V_ERROR_MSG  VARCHAR2(200);
BEGIN
  
    if p_trx_type = 'B' then 
       v_xml_type := 'CDS';
       
    else
        v_xml_type := 'CLW';
     end if;
     
    BEGIN
      INSERT
      INTO TMP_OTC
        (
          COL1 , COL2 , COL3 , COL4 , COL5 , COL6 , COL7 , COL8 , COL9 , COL10, RAND_VALUE, USER_ID
        )
      SELECT    TO_CHAR(   p_due_dt,'yyyymmdd')||'_'||t.extref||'_'||v_xml_type externalReference,
        broker_cd AS participantCode,sourceAccount,targetAccount,
        '' AS currencyCode,'LOCAL'  securityCodeType,t.STK_CD AS securityCode,
        ABS(t.sumqty) AS instrumentQuantity, TO_CHAR(   p_due_dt,'yyyymmdd') AS settlementDate,
        DECODE(   p_trx_type,'B','BUY ','SELL ')||' TRX '||TO_CHAR(   p_trx_dt,'yyyymmdd')||' '||
        client_name AS description, P_RANDOM_VALUE,P_USER_ID
FROM(        
		  SELECT  DECODE(SUBSTR(    p_rute,1,5),'MAIN1',broker_001,'MAIN4',broker_004,sourceAccount ) sourceAccount,
   		DECODE(SUBSTR(    p_rute,6,5),'MAIN1',broker_001,'MAIN4',broker_004,targetAccount ) targetAccount,
   		stk_cd,    ABS(sumqty) sumqty, client_name, 
		   DECODE(    p_rute,'SUBR4PAIR1',sourceAccount||'_'||stk_cd,'PAIR1SUBR4',targetAccount||'_'||stk_cd,stk_cd) extref,
		   DECODE(    p_rute,'SUBR4PAIR1',sourceAccount||'_'||stk_cd,'PAIR1SUBR4',targetAccount||'_'||stk_cd,RPAD(stk_cd,7)) sortk
			FROM(       
			 SELECT  sourceAccount,targetAccount, MAX(client_name) client_name,  
  		   				 stk_cd,  SUM(qty) sumqty
			FROM(
				 SELECT DECODE(SUBSTR(    p_rute,1,5),'SUBR1',subrek001,'SUBR4',subrek004,'PAIR1',pair001,
			                           'MAIN1',DECODE(SUBSTR(    p_rute,6,5),'MAIN4', subrek001,broker_001),'MAIN4',broker_004)  AS sourceAccount,
         			DECODE(SUBSTR(    p_rute,6,5),'SUBR1',subrek001,'SUBR4',subrek004,'PAIR1',pair001,
		                           'MAIN1',DECODE(SUBSTR(   p_rute,1,5),'MAIN4',subrek001,broker_001),'MAIN4', broker_004)  AS targetAccount,
				  		client_cd,   stk_cd, client_name,
					 qty
				  FROM( SELECT  NVL(subrek001, broker_001) AS subrek001, 
													 NVL(subrek004,broker_004) AS subrek004,
													  NVL(pair001, broker_001) AS pair001, 
													  broker_001, broker_004,
													  TRADE.client_cd, stk_cd,
													   MST_CLIENT.client_name,
													 ( DECODE(BuySell, p_trx_type,1,-1) * qty ) qty
									FROM( SELECT client_cd, stk_Cd, buysell, SUM(cumqty * lotsize) AS qty
													FROM(SELECT clearingaccount AS client_cd, symbol AS stk_cd, cumqty,
													                 DECODE(side,1,'B','J') BuySell, lotsize
													FROM FOTD_TRADE--V_FOTD_TRADE_H 14 SEP2017 DI DEV TIDAK ADA, JADI DIGANTI DENGAN FOTD_TRADE
													WHERE trade_date =  p_trx_dt 
													AND symbolsfx = '0TN'
													AND  execbroker  <> contrabroker)
														GROUP BY client_cd, stk_Cd, buysell
									              ) TRADE, 
												  v_client_subrek14, v_broker_subrek,
												 ( SELECT MST_CLIENT.client_cd, 
												   DECODE(custodian_cd,NULL,MST_CIF.cif_name,nama_prsh) AS client_name,
												  custodian_cd,
												 client_type_3
												    FROM MST_CLIENT,MST_CIF, MST_COMPANY
													WHERE MST_CLIENT.cifs IS NOT NULL
													AND MST_CLIENT.cifs =MST_CIF.cifs
													AND MST_CLIENT.client_type_1 <> 'B') MST_CLIENT
						  WHERE  TRADE.client_cd = MST_CLIENT.client_cd
							AND TRADE.client_cd = v_client_subrek14.client_cd(+)
		               AND INSTR(   p_rute,'4') > 0
							AND (  (    p_client_type = 'R' AND custodian_cd IS  NULL)
							      OR (    p_client_type = '%' AND custodian_cd IS  NULL)
								  OR  (    p_client_type = 'C' AND custodian_cd IS  NOT NULL)
								  OR (    p_client_type = 'A')) ))
					GROUP BY sourceAccount,targetAccount,  stk_cd 
					) ,
					v_broker_subrek
				WHERE sumqty > 0
				AND sourceaccount <> targetaccount 
                ORDER BY stk_cd, client_name
				) T,
				v_broker_subrek;
			--	ORDER BY t.stk_cd, t.client_name;
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
END SP_TMP_TRX_STK_TUNAI;