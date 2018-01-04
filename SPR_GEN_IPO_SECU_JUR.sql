create or replace 
PROCEDURE SPR_GEN_IPO_SECU_JUR(	 P_STK_CD VARCHAR2,
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
BEGIN
    v_random_value := abs(dbms_random.random);
    BEGIN
        SP_RPT_REMOVE_RAND('R_GEN_IPO_SECU_JUR',V_RANDOM_VALUE,P_ERRCD,P_ERRMSG);
    EXCEPTION
        WHEN OTHERS THEN
             v_err_cd := -2;
             v_err_msg := SQLERRM(SQLCODE);
            RAISE V_err;
    END;
  BEGIN
 
  --INSERT KE TABLE REPORT
  INSERT INTO R_GEN_IPO_SECU_JUR(STK_CD,DISTRIB_DT,CLIENT_CD, CLIENT_NAME, BRANCH_CODE, PRICE, QTY,
								CLIENT_TYPE,CUSTODIAN_CD,IPO_TYPE ,CLIENT_TYPE_SECU_ACCT,
								RAND_VALUE,GENERATE_DATE, USER_ID)
              
	 SELECT  P.STK_CD,P.DISTRIB_DT_FR,t.client_cd, m.client_name, m.branch_code, ROUND(p.price * 1.01,0) price, t.fixed_qty AS qty,
	trim(m.client_type_1)||trim(m.client_type_2)||trim(m.client_type_3) AS client_type, m.custodian_cd,	'Fixed' ipo_type,
	decode(t.client_cd, v.broker_client_Cd,'H',decode(m.client_type_1,'H','H','%')) as client_type_secu_acct,
  v_random_value, p_generate_date, p_user_id
	FROM T_IPO_CLIENT t, T_PEE p, MST_CLIENT m, v_broker_subrek v	
	WHERE p.stk_cd = P_STK_CD	
	AND t.stk_Cd = P_STK_CD	
	AND t.client_cd = m.client_cd	
	AND t.fixed_qty > 0	
	AND t.approved_stat = 'A'	
	UNION ALL	
	SELECT P_STK_CD, P.DISTRIB_DT_FR,t.client_cd, m.client_name,m.branch_code,  p.price, t.alloc_qty AS qty,
	trim(m.client_type_1)||trim(m.client_type_2)||trim(m.client_type_3) AS client_type,
	m.custodian_cd,	'Pooling' ipo_type,
	decode(t.client_cd, v.broker_client_Cd,'H',decode(m.client_type_1,'H','H','%')) as client_type_secu_acct,
   v_random_value, p_generate_date, p_user_id
	FROM T_IPO_CLIENT t, T_PEE p, MST_CLIENT m, v_broker_subrek v	
	WHERE p.stk_cd = P_STK_CD	
	AND t.stk_Cd = P_STK_CD	
	AND t.client_cd = m.client_cd	
	AND  t.alloc_qty > 0 	
	AND t.approved_stat = 'A';	


    EXCEPTION
    WHEN NO_DATA_FOUND THEN
    V_ERR_CD := -10;
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
END SPR_GEN_IPO_SECU_JUR;