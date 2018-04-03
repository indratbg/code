create or replace PROCEDURE SP_TRF_STK_T2(
    p_trx_Date date,
    p_due_date date,
    P_USER_ID IN T_SECU_BAL.USER_ID%TYPE,
    P_ERROR_CODE OUT NUMBER,
    P_ERROR_MSG OUT VARCHAR2   ) IS
    
-- utk insert ke T_STK_004, shg stk yg ditransfer muncul di report rincian kolom client 004

V_ERR EXCEPTION;
V_ERROR_CODE NUMBER(5);
V_ERROR_MSG VARCHAR2(200);
BEGIN

    begin
    delete from T_STK_004
    where DOC_DT = trunc(sysdate);
    exception
    when others then
        V_ERROR_CODE := -10;
        V_ERROR_MSG := SUBSTR('delete T_STK_004 hari ini '||SQLERRM,1,200);
        RAISE V_ERR;
      END;
      
      begin 
      INSERT INTO T_STK_004
      SELECt trunc(sysdate) as doc_dt, a.client_Cd, stk_cd, 
        sum( decode(substr(contr_num,5,1),'J',1,-1) * qty) bal_qty,
        p_user_id, sysdate
        from t_contracts a, mst_client b
        where contr_dt between p_trx_Date and p_due_date
        and a.client_cd = b.client_cd
        and b.custodian_cd is null
        and contr_stat = '0'
        and mrkt_type = 'RG'
        and sett_qty =0
        and due_Dt_for_amt = p_due_date
        group by due_dt_for_amt,a.client_Cd, stk_cd
        having sum( decode(substr(contr_num,5,1),'J',1,-1) * qty) > 0;

      exception
    when others then
        V_ERROR_CODE := -20;
        V_ERROR_MSG := SUBSTR('delete T_STK_004 hari ini '||SQLERRM,1,200);
        RAISE V_ERR;
      END;
      
  	P_ERROR_CODE := 1;
	P_ERROR_MSG := '';

EXCEPTION
	WHEN NO_DATA_FOUND THEN
		NULL;
	WHEN v_err THEN
		ROLLBACK;
		p_error_code := v_error_code;
		p_error_msg := v_error_msg;
	WHEN OTHERS THEN
   -- 
		ROLLBACK;
		p_error_code := -1;
		p_error_msg := SUBSTR(SQLERRM(SQLCODE),1,200);
		RAISE;
END SP_TRF_STK_T2;