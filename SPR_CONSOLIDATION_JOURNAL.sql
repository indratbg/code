create or replace 
PROCEDURE SPR_CONSOLIDATION_JOURNAL(	P_DOC_DATE DATE,
								P_XN_DOC_NUM VARCHAR2,
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
        SP_RPT_REMOVE_RAND('R_T_CONSOL_JRN',V_RANDOM_VALUE,P_ERRCD,P_ERRMSG);
    EXCEPTION
        WHEN OTHERS THEN
             v_err_cd := -2;
             v_err_msg := SQLERRM(SQLCODE);
            RAISE V_err;
    END;
  BEGIN
 
  --INSERT KE TABLE REPORT
  INSERT INTO R_T_CONSOL_JRN(XN_DOC_NUM,DOC_DATE,TAL_ID,ENTITY,GL_ACCT_CD,
							SL_ACCT_CD,DB_CR_FLG,CURR_VAL,LEDGER_NAR,RAND_VALUE,
							USER_ID,GENERATE_DATE)
	select xn_doc_num,doc_date,TAL_ID,entity,gl_acct_cd,
		sl_acct_cd,decode(db_cr_flg,'D','Debit','Credit'),curr_val,ledger_nar, v_random_value,
		P_User_Id,P_Generate_Date From T_Consol_Jrn 
		where doc_date=P_DOC_DATE AND XN_DOC_NUM LIKE '%'||P_XN_DOC_NUM and approved_sts='A' order by xn_doc_num;

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
END SPR_CONSOLIDATION_JOURNAL;