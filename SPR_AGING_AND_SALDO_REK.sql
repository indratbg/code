create or replace PROCEDURE SPR_AGING_AND_SALDO_REK(
    P_END_DATE DATE,
    P_BGN_BRANCH varchar2,
    P_END_BRANCH varchar2,
    P_BGN_CLIENT MST_CLIENT.CLIENT_CD%TYPE,
    P_END_CLIENT MST_CLIENT.CLIENT_CD%TYPE,
    P_FUND_BAL      VARCHAR2,
    P_ARAP          VARCHAR2,
    P_USER_ID       VARCHAR2,
    P_GENERATE_DATE DATE,
    P_RANDOM_VALUE OUT NUMBER,
    P_ERROR_CD OUT NUMBER,
    P_ERROR_MSG OUT VARCHAR2 )
IS
  V_ERROR_MSG    VARCHAR2(200);
  V_ERROR_CD     NUMBER(10);
  V_RANDOM_VALUE NUMBER(10);
  V_ERR          EXCEPTION;
  V_D_T1         DATE;
  V_START_DATE DATE;
BEGIN
    
  V_RANDOM_VALUE := ABS(DBMS_RANDOM.RANDOM);
  
  BEGIN
    SP_RPT_REMOVE_RAND('R_AGING_AND_SALDO_REK',V_RANDOM_VALUE,V_ERROR_MSG,V_ERROR_CD);
  EXCEPTION
  WHEN OTHERS THEN
    V_ERROR_CD  := -30;
    V_ERROR_MSG := SUBSTR('SP_RPT_REMOVE_RAND '||V_ERROR_MSG||SQLERRM(SQLCODE),1,200);
    RAISE V_err;
  END;
  
  IF V_ERROR_CD  <0 THEN
    V_ERROR_CD  := -40;
    V_ERROR_MSG := SUBSTR('SP_RPT_REMOVE_RAND'||V_ERROR_MSG,1,200);
    RAISE V_ERR;
  END IF;
  
  --YJ 01JAN2007
  BEGIN
  SELECT DDATE1 INTO V_START_DATE FROM MST_SYS_PARAM WHERE PARAM_ID='AGING SALDO REKDANA' AND PARAM_CD1='START' AND PARAM_CD2='DATE';
  EXCEPTION
  WHEN OTHERS THEN
    V_ERROR_CD  := -33;
    V_ERROR_MSG := SUBSTR('SELECT START DATE FROM MST_SYS_PARAM '||SQLERRM(SQLCODE),1,200);
    RAISE V_err;
  END;
  
  
  V_D_T1 :=GET_Due_DATE(1,P_END_DATE);
  
  BEGIN
    INSERT
    INTO R_AGING_AND_SALDO_REK
      (
        CLIENT_CD ,
        CLIENT_TYPE_3 ,
        BRANCH_CODE ,
        CLIENT_NAME ,
        OUTS_AMT ,
        OUTS_T0 ,
        OUTS_T1 ,
        OUTS_BEYOND ,
        BANK_ACCT_FMT ,
        FUND_BAL ,
        SORTK ,
        SORTK3 ,
        JENIS ,
        DUE_DATE ,
        USER_ID ,
        RAND_VALUE ,
        GENERATE_DATE,
        END_DATE
      )
    SELECT t.client_cd,
      m.client_type_3,
     -- m.type_2490,
      m.branch_code,
      m.client_name,
      t.outs_amt,
      t.outs_t0,
      t.outs_t1,
      t.outs_beyond,
      m.bank_acct_fmt,
      m.fund_bal,
      m.sortk,
      --  M.SORTK2,
      M.SORTK3,
      DECODE(m.sortk,1,'R',2,'T',3,'N',4,'M') AS jenis,
      -- decode(m.type_2490,'2490','2490','') as type_1422
      GET_DUE_DATE(1,P_END_DATE),
      P_USER_ID,
      V_RANDOM_VALUE,
      P_GENERATE_DATE,
      P_END_DATE
    FROM
      (SELECT client_cd,
        SUM(outs_amt) outs_amt,
        SUM(DECODE(t0,1,outs_amt,0)) outs_t0,
        SUM(DECODE(t1,1,outs_amt,0)) outs_t1,
        SUM(DECODE(t_beyond,1,outs_amt,0)) outs_beyond
      FROM
        (SELECT sl_acct_cd CLIENT_CD,
          DECODE(db_cr_flg,'D',1,-1) * ( NVL(CURR_VAL,0) - NVL(SETT_VAL,0)) OUTS_AMT,
          DECODE(SIGN(P_END_DATE - due_date ),-1,0,1) t0,
          DECODE(SIGN(V_D_T1     - due_date),0,1,0) t1,
          DECODE(SIGN(V_D_T1     - due_date),-1,1,0) t_beyond
        FROM t_account_ledger t,
          mst_client m
        WHERE t.sl_acct_cd   = m.client_cd
        AND M.CLIENT_CD BETWEEN P_BGN_CLIENT AND P_END_CLIENT
        AND t.doc_date  > V_START_DATE --TO_DATE('01APR2007','DDMONYYYY') --'1APR07'
        AND T.REVERSAL_JUR ='N'
        AND RECORD_SOURCE <> 'RE'
        AND ( t.record_source    <> 'RV'
        AND t.record_source    <> 'PV' )
        AND (CURR_VAL - NVL(SETT_VAL,0) - NVL(SETT_FOR_CURR,0) ) > 0
        AND approved_sts   = 'A'
        )
      GROUP BY client_cd
      ) t,
      (SELECT client_cd,
        acct_open_dt,
        client_name,
        branch_code,
        bank_acct_fmt,
        fund_bal,
        client_Type_3,
        type_2490,
        DECODE(client_type_3,'T',2,'N',3,'M',4,1) sortk,
       -- DECODE(type_2490,'2490',2,1) SORTK2,
        DECODE(client_type_3,'R',1,'S',2,'D',3,'K',4,5) SORTK3
      FROM
        (SELECT mst_client.client_cd,
          NVL(f_fund_bal(mst_client.client_Cd,P_END_DATE),0) fund_bal,
          acct_open_dt,
          client_name,
          branch_code,
          bank_acct_fmt,
          client_Type_3,
          DECODE(NVL(recov_charge_flg,'N'),'Y','2490','1422') AS type_2490
        FROM mst_client,
          mst_client_flacct
        WHERE susp_stat          = 'N'
        AND mst_client.CLIENT_CD BETWEEN P_BGN_CLIENT AND P_END_CLIENT
        AND mst_client.client_Cd = mst_client_flacct.client_Cd(+)
        )
      ) m
    WHERE t.client_cd = m.client_Cd
    AND ((t.outs_t0   > 0 AND P_ARAP        = 'AR' )
    OR (t.outs_t0     < 0 AND P_ARAP        = 'AP')
    OR ( P_ARAP       = 'ALL'))
    AND ( (m.fund_bal > 0 AND P_FUND_BAL    = 'ADA')
        OR P_FUND_BAL     = 'ALL')
    AND trim(m.branch_code) BETWEEN P_BGN_BRANCH AND P_END_BRANCH;
  EXCEPTION
  WHEN OTHERS THEN
    V_ERROR_CD  := -60;
    V_ERROR_MSG := SUBSTR('INSERT R_AGING_AND_SALDO_REK '||SQLERRM,1,200);
    RAISE V_err;
  END;
  
  P_RANDOM_VALUE :=V_RANDOM_VALUE;
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
END SPR_AGING_AND_SALDO_REK;