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
      DECODE(gl_acct_group,'01','6XXX',gl_acct_Cd) gl_acct_Cd,
      DECODE(trim(gl_acct_cd),'6210','0006',t.subacct) subacct,
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
      DECODE(grp1,2,'PENDAPATAN LAIN-LAIN',gl_Acct_group_name) gl_Acct_group_name,
      P_USER_ID,
      v_random_value, 
      P_GENERATE_DATE,
      P_BGN_DATE,
      P_END_DATE
    FROM
      (SELECT DECODE(SUBSTR(acct_cd,1,4),'6509',2,'6511',2,1) grp1,
        gl_acct_group,
        DECODE(acct_cd,'52000003','610A',SUBSTR(acct_cd,1,4)) gl_acct_cd,
        SUBSTR(acct_cd,5,4) subacct,
        lr_faktor,
        SUM(DECODE(branch,'10',bal_amt, 0)) + SUM(amt50) amt1,
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
        SUM(bal_amt + amt50 ) tot_amt
      FROM
        (SELECT gl_acct_Cd,
          sl_acct_cd,
          branch,
          trim(gl_acct_Cd)
          ||SUBSTR(sl_acct_cd,3,4) acct_cd,
          bal_amt,
          amt50
        FROM
          (SELECT trim(gl_acct_Cd) gl_acct_cd,
            sl_acct_cd,
            SUBSTR(sl_acct_cd,1,2) branch,
            SUBSTR(sl_acct_cd,3,4) subacct,
            SUM(bal_amt       * faktor) bal_amt,
            SUM(DECODE(faktor,-0.5,bal_amt * faktor,0) ) amt50
          FROM
            (SELECT trim(gl_acct_Cd) gl_acct_Cd,
              sl_acct_cd,
              faktor,
              DECODE(db_Cr_flg,'D',1,-1) * curr_val AS bal_amt
            FROM T_ACCOUNT_LEDGER,
              ( SELECT gl_a_cd, sl_a, faktor FROM v_labarugi_acct_apr2014
              ) v
            WHERE doc_date BETWEEN P_BGN_DATE AND P_END_DATE
            AND T_ACCOUNT_LEDGER.gl_acct_cd = V.Gl_a_cd
            AND T_ACCOUNT_LEDGER.sl_acct_cd = v.sl_A
            AND approved_sts                = 'A'
            )
          GROUP BY gl_acct_Cd,
            sl_acct_cd
          )
        ),
        ( SELECT DISTINCT trim(acct_cd_2) acct_Cd_2,
          gl_acct_group,
          lr_faktor
        FROM v_labarugi_acct_apr2014
        )
      WHERE bal_amt  <> 0
      AND acct_cd     = acct_cd_2
      AND branch      < '90'
      AND gl_acct_cd <> '5600'
      GROUP BY gl_acct_group,
        acct_Cd,
        lr_faktor
      UNION ALL
      SELECT 2,
        '01',
        gl_acct_cd ,
        DECODE(gl_acct_cd,'6502','0001','6550','0002','6510','0003') subacct,
        1,
        -1 * SUM(bal_amt),
        0,0,0,0,0,0,0,0,0,0,0,
        -1 * SUM(bal_amt)
      FROM
        (SELECT DECODE(trim(gl_acct_cd),'6502','6502','6503','6502','5600','6502',trim(gl_acct_cd)) gl_acct_cd ,
          (DECODE(db_Cr_flg,'D',1,-1) * curr_val) AS bal_amt
        FROM T_ACCOUNT_LEDGER
        WHERE doc_date BETWEEN P_BGN_DATE AND P_END_DATE
        AND T_ACCOUNT_LEDGER.gl_acct_cd IN ('6502','6503','5600','6510','6550')
        AND approved_sts                 = 'A'
        )
      GROUP BY gl_acct_cd
      UNION ALL
      SELECT 1,
        '01',
        '6100',
        '0000',
        1,
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
      ) t,
      ( SELECT DISTINCT trim(gl_a_Cd) gl_a_Cd,
        SUBSTR(acct_Cd_2,5,4) AS subacct,
        acct_name,
        main_acct_name,
        gl_Acct_group_name
      FROM v_labarugi_account
      WHERE sl_a LIKE '10%'
      UNION ALL
      SELECT '6100',
        '0000',
        'Komisi Perdagangan Efek ',
        'Pendapatan',
        'PENDAPATAN'
      FROM dual
      UNION ALL
      SELECT '610A','0003', 'Komisi Sales', 'Pendapatan', 'PENDAPATAN' FROM dual
      UNION ALL
      SELECT '6502',
        '0001',
        'Budep  Giro - Net',
        'Pendapatan',
        'PENDAPATAN'
      FROM dual
      UNION ALL
      SELECT '6510',
        '0003',
        'Pendapatan Reverse Repo',
        'Pendapatan',
        'PENDAPATAN'
      FROM dual
      UNION ALL
      SELECT '6511',
        '0000',
        'Pendapatan Reverse Repo',
        'Pendapatan',
        'PENDAPATAN'
      FROM dual
      UNION ALL
      SELECT '6550','0002', 'Selisih Kurs', 'Pendapatan', 'PENDAPATAN' FROM dual
      ) s
    WHERE (t.gl_acct_cd) = (s.gl_a_cd(+))
    AND (t.subacct)      = (s.subacct(+))
    ORDER BY 1,2,3,
      4;
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