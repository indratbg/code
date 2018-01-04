create or replace 
	PROCEDURE SPR_T_STK_KSEI(	P_BAL_DT DATE, 
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
  v_stk_cd varchar2(50) ;
BEGIN
    v_random_value := abs(dbms_random.random);

    BEGIN
        SP_RPT_REMOVE_RAND('R_T_STK_KSEI',V_RANDOM_VALUE,P_ERRCD,P_ERRMSG);
    EXCEPTION
        WHEN OTHERS THEN
             v_err_cd := -2;
             v_err_msg := SQLERRM(SQLCODE);
            RAISE V_err;
    END;
    

    
    
	BEGIN
	INSERT INTO R_T_STK_KSEI(IMPORT_DT,BAL_DT,SUB_REK,STK_CD,QTY,FREE,USER_ID,GENERATE_DATE,RAND_VALUE)
	SELECT IMPORT_DT ,BAL_DT,SUB_REK,STK_CD,QTY,FREE,P_USER_ID,P_GENERATE_DATE,V_RANDOM_VALUE FROM T_STK_KSEI
	WHERE BAL_DT = P_BAL_DT;
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
END SPR_T_STK_KSEI;