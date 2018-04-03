create or replace PROCEDURE SPR_PROFIT_LOSS_RECAP(
    P_BGN_DATE      DATE,
    P_END_DATE      DATE,
    P_USER_ID       VARCHAR2,
    P_GENERATE_DATE DATE,
    P_RANDOM_VALUE OUT NUMBER,
    P_ERROR_CD OUT NUMBER,
    P_ERROR_MSG OUT VARCHAR2 )
AS
  V_ERR          EXCEPTION;
  V_ERROR_CD     NUMBER(5);
  V_ERROR_MSG    VARCHAR2(200);
  V_RANDOM_VALUE NUMBER(10);
BEGIN
  V_RANDOM_VALUE := ABS(DBMS_RANDOM.RANDOM);
  BEGIN
    SP_RPT_REMOVE_RAND('R_PROFIT_LOSS_RECAP',V_RANDOM_VALUE,V_ERROR_MSG,V_ERROR_CD);
  EXCEPTION
  WHEN OTHERS THEN
    V_ERROR_CD  := -10;
    V_ERROR_MSG := SUBSTR('SP_RPT_REMOVE_RAND '||V_ERROR_MSG||SQLERRM(SQLCODE),1,200);
    RAISE V_err;
  END;
  BEGIN
    INSERT
    INTO R_PROFIT_LOSS_RECAP
      (
        GRP1 ,
        GL_ACCT_GROUP ,
        GL_ACCT_CD ,
        SUBACCT ,
        LR_FAKTOR ,
        ACCT_NAME ,
        AMT1 ,
        AMT2 ,
        AMT3 ,
        AMT4 ,
        AMT5 ,
        AMT6 ,
        AMT7 ,
        AMT8 ,
        AMT9 ,
        AMT10 ,
        AMT11 ,
        AMT12,
        TOT_AMT ,
        MAIN_ACCT_NAME ,
        GL_ACCT_GROUP_NAME ,
        USER_ID ,
        RAND_VALUE ,
        GENERATE_DATE ,
        BGN_DATE ,
        END_DATE
      )
    SELECT grp1,
      gl_acct_group,
       gl_acct_Cd,
       subacct,
      lr_faktor,
      acct_name,
      amt1,
      amt2,
      amt3,
      amt4,
      amt5,
      amt6,
      amt7,
      amt8,
      amt9,
      amt10,
      amt11,
      amt12,
      tot_amt,
      main_acct_name,
      gl_Acct_group_name,
      P_USER_ID,
      v_random_value, 
      P_GENERATE_DATE,
      P_BGN_DATE,
      P_END_DATE
    FROM (
            SELECT 1 as GRP1,
            '01'                AS gl_acct_group,
          'PENDAPATAN'              AS gl_acct_group_name,
          '6XXX'                    AS gl_acct_cd,
          'KOMISI PERDAGANGAN EFEK' AS main_acct_name,
          '0000'                  AS subacct,
           1 lr_faktor,
          'KOMISI PERDAGANGAN EFEK' AS acct_name,
        SUM(DECODE(acct_prefix,'10',commission,0)) amt1,
        SUM(DECODE(acct_prefix,'20',commission,0)) amt2,
        SUM(DECODE(acct_prefix,'30',commission,0)) amt3,
        SUM(DECODE(acct_prefix,'50',commission,0)) amt4,
        SUM(DECODE(acct_prefix,'60',commission,0)) amt5,
        SUM(DECODE(acct_prefix,'80',commission,0)) amt6,
        SUM(DECODE(acct_prefix,'81',commission,0)) amt7,
        SUM(DECODE(acct_prefix,'82',commission,0)) amt8,
        SUM(DECODE(acct_prefix,'83',commission,0)) amt9,
        SUM(DECODE(acct_prefix,'84',commission,0)) amt10,
        SUM(DECODE(acct_prefix,'86',commission,0)) amt11,
        SUM(DECODE(acct_prefix,'89',commission,0)) amt12,
         SUM(commission) tot_amt
      FROM T_CONTRACTS,
        MST_BRANCH,
        MST_CLIENT
      WHERE T_CONTRACTS.contr_dt BETWEEN P_BGN_DATE AND P_END_DATE
      AND (T_CONTRACTS.contr_stat   <> 'C')
      AND T_CONTRACTS.RECORD_SOURCE <> 'IB'
      AND trim(T_CONTRACTS.brch_cd)  = MST_BRANCH.brch_cd
      AND T_CONTRACTS.client_Cd      = MST_CLIENT.client_cd
UNION ALL
SELECT decode(v.gl_acct_group,'03',2,1) grp1,
            v.gl_acct_group,
          decode(v.gl_acct_group,'03','PENDAPATAN LAIN-LAIN',v.gl_acct_group_name) gl_acct_group_name,
          v.gl_a                     AS gl_acct_cd,
          v.main_acct_name ,
          substr(v.sl_a,3,4)               AS subacct,
        lr_faktor,
          v.acct_name,
        amt1, amt2, amt3, amt4, amt5, amt6, amt7, amt8, amt9, amt10, amt11, amt12, tot_amt
     from(   
          SELECT   acct_Cd,
        SUM(DECODE(branch,'10',bal_amt, 0))  amt1,
        SUM(DECODE(branch,'20',bal_amt,0)) amt2,
        SUM(DECODE(branch,'30',bal_amt,0)) amt3,
        SUM(DECODE(branch,'50',bal_amt,0)) amt4,
        SUM(DECODE(branch,'60',bal_amt,0)) amt5,
        SUM(DECODE(branch,'80',bal_amt,0)) amt6,
        SUM(DECODE(branch,'81',bal_amt,0)) amt7,
        SUM(DECODE(branch,'82',bal_amt,0)) amt8,
        SUM(DECODE(branch,'83',bal_amt,0)) amt9,
        SUM(DECODE(branch,'84',bal_amt,0)) amt10,
        SUM(DECODE(branch,'86',bal_amt,0)) amt11,
        SUM(DECODE(branch,'89',bal_amt,0)) amt12,
        SUM(bal_amt  ) tot_amt
        from(
            SELECT trim(gl_acct_Cd) gl_acct_Cd,
              sl_acct_cd,
            SUBSTR(sl_acct_cd,1,2) branch,
            trim(gl_acct_Cd) ||SUBSTR(sl_acct_cd,3,4) acct_cd,
              SUM(DECODE(db_Cr_flg,'D',1,-1) * curr_val * faktor) AS bal_amt
            FROM T_ACCOUNT_LEDGER,
              (SELECT GL_A_CD,SL_A,acct_cd_2,FAKTOR FROM v_labarugi_acct_APR2014 WHERE P_BGN_DATE < TO_DATE('01012018','DDMMYYYY')
               UNION
               SELECT GL_A_CD,SL_A,acct_cd_2, FAKTOR FROM v_labarugi_acct_2018 WHERE P_BGN_DATE >= TO_DATE('01012018','DDMMYYYY') 
                )v
            WHERE doc_date BETWEEN P_BGN_DATE AND P_END_DATE
            AND T_ACCOUNT_LEDGER.gl_acct_cd = V.Gl_a_cd
            AND T_ACCOUNT_LEDGER.sl_acct_cd = v.sl_A
            AND approved_sts                = 'A'
            and T_ACCOUNT_LEDGER.gl_acct_cd <> '5600'
          GROUP BY acct_cd_2, gl_acct_Cd,
            sl_acct_cd) 
            where branch <> '90'
         group  by   acct_cd 
         ) t, 
         ( select decode( acct_Cd, '5300100087',  '53000087', acct_cd_2) acct_Cd_3,
         gl_acct_group,
          gl_acct_group_name,
          gl_a,
          main_acct_name,
          sl_a,
          acct_name,
          acct_cd_2,
          lr_faktor
           from 
           (SELECT gl_acct_group,gl_acct_group_name,gl_a, main_acct_name, sl_a, acct_name,acct_Cd,acct_cd_2,lr_faktor  
            FROM v_labarugi_acct_APR2014 WHERE P_BGN_DATE < TO_DATE('01012018','DDMMYYYY')
            UNION
            SELECT gl_acct_group,gl_acct_group_name,gl_a, main_acct_name, sl_a, acct_name,acct_Cd,acct_cd_2,lr_faktor 
            FROM v_labarugi_acct_2018 WHERE P_BGN_DATE >= TO_DATE('01012018','DDMMYYYY')
            )
           where substr(sl_a,1,2)= '10') v
     where t.acct_Cd = v.acct_cd_3   
     )
      order by grp1, gl_acct_group, gl_acct_cd,  subAcct;
  EXCEPTION
  WHEN OTHERS THEN
    V_ERROR_CD  :=-30;
    V_ERROR_MSG :=SUBSTR('INSERT INTO R_PROFIT_LOSS_RECAP '||SQLERRM,1,200);
    RAISE V_err;
  END;
  P_RANDOM_VALUE := v_random_value;
  P_ERROR_CD     := 1 ;
  P_ERROR_MSG    := '';
EXCEPTION
WHEN V_ERR THEN
  ROLLBACK;
  P_ERROR_MSG := V_ERROR_MSG;
  P_ERROR_CD  := V_ERROR_CD;
WHEN OTHERS THEN
  P_ERROR_CD  := -1 ;
  P_ERROR_MSG := SUBSTR(SQLERRM(SQLCODE),1,200);
  RAISE;
END SPR_PROFIT_LOSS_RECAP;