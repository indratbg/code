create or replace 
PROCEDURE SPR_R_T_DHK(	P_SETTLE_DATE DATE,
                      P_OPTIONS VARCHAR2,
                       P_USER_ID			VARCHAR2,
                       P_GENERATE_DATE 	DATE,
                       P_RANDOM_VALUE	OUT NUMBER,
                       P_ERRCD	 		OUT NUMBER,
                       P_ERRMSG	 		OUT VARCHAR2
                      ) IS
  v_random_value	NUMBER(10);
  v_err			EXCEPTION;
  v_err_cd number(10);
  v_err_msg number(10);
  V_trx_date date;
BEGIN

    v_random_value := abs(dbms_random.random);
    BEGIN
        SP_RPT_REMOVE_RAND('R_T_DHK',V_RANDOM_VALUE,v_err_cd,v_err_msg);
    EXCEPTION
        WHEN OTHERS THEN
             v_err_cd := -2;
             v_err_msg := substr('SP_RPT_REMOVE_RAND'||v_err_msg,1,200);
            RAISE V_err;
    END;
    v_trx_date :=GET_DOC_DATE(3,p_settle_date);
    
  BEGIN
  --INSERT KE TABLE REPORT
  INSERT INTO R_T_DHK(SETTLE_DATE,CLIENT_NAME,SID,SUBREK001,SUBREK004,STK_CD,IP_BUY,
						IP_SELL, DHK_BUY, DHK_SELL, USER_ID, RAND_VALUE, GENERATE_DATE)
	SELECT P_SETTLE_DATE,client_name, sid, subrek001, subrek004, stk_Cd, ip_buy,
			ip_sell,dhk_buy,dhk_sell, P_USER_ID, V_RANDOM_VALUE, P_GENERATE_DATE									
FROM(												
SELECT 	MAX(client_name) client_name, sid, subrek001, subrek004,			stk_Cd,								
                  DECODE(SIGN(SUM(ip_buy - ip_sell)), 1,SUM(ip_buy - ip_sell), 0) ip_buy,												
                  DECODE(SIGN(SUM(ip_buy - ip_sell)), -1,SUM(ip_sell - ip_buy),0) ip_sell,												
                  SUM(dhk_buy) dhk_buy,												
                  SUM(dhk_sell) dhk_sell												
FROM(												
SELECT a.CLIENT_CD ,												
	   		m.client_name,									
			DECODE(m.custodian_cd, NULL, m.sid, c.broker_sid) sid,									
			NVL(b.pair001,c.broker_001) AS subrek001,									
			NVL(b.subrek004,c.broker_004) AS subrek004, 									
			stk_Cd,									
			DECODE(SIGN(net_qty),1, net_qty,0) AS ip_buy,									
			DECODE(SIGN(net_qty),-1, ABS(net_qty),0) AS ip_sell,									
			0 dhk_buy, 									
			0 dhk_sell 									
		FROM( SELECT client_cd, stk_Cd,										
			SUM(DECODE(SUBSTR(contr_num,5,1),'B',1,-1) * qty) net_qty									
				FROM T_CONTRACTS								
				WHERE contr_dt BETWEEN v_trx_date AND  P_SETTLE_DATE								
				AND contr_stat <> 'C'								
				AND  due_dt_for_amt= P_SETTLE_DATE								
				AND mrkt_type <> 'NG'								
				AND mrkt_type <> 'TS'								
				GROUP BY client_Cd, stk_Cd								
				) a, v_client_subrek14 b,								
			mst_client m, v_broker_subrek c									
		WHERE a.client_cd = b.client_Cd(+)										
		AND a.client_cd = m.client_Cd										
UNION ALL												
 SELECT  NULL client_cd, NULL client_name, sid, subrek001, subrek004, stk_cd, 0 ip_buy, 0 ip_sell, net_buy dhk_buy, net_sell dhk_sell												
  FROM T_DHK												
  WHERE settle_date = P_SETTLE_DATE												
  AND stk_Cd <> 'IDR'												
   ) d												
   GROUP BY SID, subrek001, subrek004, stk_Cd												
)												
WHERE    (( (ip_buy <> dhk_buy) OR (ip_sell <> dhk_sell)) AND P_OPTIONS = 'DIFF') OR P_OPTIONS = 'ALL'												
ORDER BY  stk_cd, subrek001		;										


    EXCEPTION
    WHEN NO_DATA_FOUND THEN
    V_ERR_CD := -100;
    V_ERR_MSG :='NO DATA FOUND';
    RAISE V_ERR;
        WHEN OTHERS THEN
             v_err_cd := -3;
             v_err_msg := SQLERRM(SQLCODE);
            RAISE V_err;
    END;

    p_random_value := v_random_value;
    p_errcd := 1;
    p_errmsg := '';
  
EXCEPTION
    WHEN V_err THEN
        ROLLBACK;
		 p_errcd := v_err_cd;
        p_errmsg := v_err_msg;
    WHEN OTHERS THEN
        ROLLBACK;
        p_errcd := -1;
        p_errmsg := SUBSTR(SQLERRM(SQLCODE),1,200);
END SPR_R_T_DHK;