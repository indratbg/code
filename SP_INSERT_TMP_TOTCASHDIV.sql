create or replace PROCEDURE SP_INSERT_TMP_TOTCASHDIV(
    p_instruction_type VARCHAR2,
    P_DISTRIB_DT           DATE,
    p_menu_name        VARCHAR2,
    P_RANDOM_VALUE NUMBER,
    P_USER_ID VARCHAR2,
    P_ERROR_CODE OUT NUMBER,
    P_ERROR_MSG OUT VARCHAR2 )
IS
-- 22jun2017 gen xml WT utk trf total cash div dr subrek YJ ke bank
  
  vs_distrib_dt varchar2(8);
  
  V_ERR        EXCEPTION;
  V_ERROR_CODE NUMBER(5);
  V_ERROR_MSG  VARCHAR2(200);
  
BEGIN

    vs_distrib_dt := to_char(p_distrib_dt,'yyyymmdd');
    
    BEGIN
      INSERT
      INTO TMP_TOTCASHDIV
        (
          COL1 , COL2 , COL3 , COL4 , COL5 , COL6 , COL7 , COL8 , COL9, RAND_VALUE, USER_ID 
        )
      select vs_distrib_dt||'_DEV_'||stk_Cd as externalReference,
            broker_cd as participantCode, 
            subrek AS participantAccount,
            bank_acct as beneficiaryAccount,
            bank_cd as beneficiaryInstitution,
            vs_distrib_dt as valueDate,
            'IDR' as currencyCode,
            trim(to_char(div_amt)) as cashAmount,
            'DEV_'||stk_Cd as description,
            P_RANDOM_VALUE, P_USER_ID
         from            
        (select stk_cd, sum(div_amt) div_amt
            from t_cash_dividen
            where distrib_dt = p_distrib_dt
            and approved_stat = 'A'
            group by stk_cd),
         v_broker_subrek,
         ( select dstr1 as subrek, dstr2 as bank_acct, param_cd3 as bank_cd
             from MST_SYS_PARAM
             where param_id = 'XML TRF TOT DIVIDEN'
             ) order by 1;
    EXCEPTION
    WHEN OTHERS THEN
      V_ERROR_CODE :=-10;
      V_ERROR_MSG  :=SUBSTR( 'INSERT INTO TMP_TOTCASHDIV ' || SQLERRM,1,200);
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
END SP_INSERT_TMP_TOTCASHDIV;