create or replace PROCEDURE SPR_REKAP_SALDO_AR(
    P_DATE          DATE,
    P_USER_ID       VARCHAR2,
    P_GENERATE_DATE DATE,
    P_RANDOM_VALUE OUT NUMBER,
    P_ERROR_CD OUT NUMBER,
    P_ERROR_MSG OUT VARCHAR2 )
IS
  V_ERROR_MSG    VARCHAR2(200);
  V_ERROR_CD     NUMBER(10);
  v_random_value NUMBER(10);
  V_ERR          EXCEPTION;
  vp_from_dt     DATE;
  vp_to_dt       DATE:=P_DATE;
BEGIN

  v_random_value := ABS(dbms_random.random);
  
  BEGIN
    SP_RPT_REMOVE_RAND('R_REKAP_SALDO_AR',V_RANDOM_VALUE,V_ERROR_MSG,V_ERROR_CD);
  EXCEPTION
  WHEN OTHERS THEN
    V_ERROR_CD  := -10;
    V_ERROR_MSG := SUBSTR('SP_RPT_REMOVE_RAND '||V_ERROR_MSG||SQLERRM(SQLCODE),1,200);
    RAISE V_err;
  END;
  
  IF V_ERROR_CD  <0 THEN
    V_ERROR_CD  := -20;
    V_ERROR_MSG := SUBSTR('SP_RPT_REMOVE_RAND'||V_ERROR_MSG,1,200);
    RAISE V_ERR;
  END IF;
  
  vp_from_dt := get_doc_date(3,P_DATE);
  
  vp_from_dt := TO_DATE('01'||TO_CHAR(vp_from_dt,'MMYYYY'),'DDMMYYYY');
  
  BEGIN
    INSERT
    INTO R_REKAP_SALDO_AR
      (
        BRCH_CD ,BRCH_NAME ,S_AMT ,T_AMT ,M_AMT ,TOT_AMT ,USER_ID ,RAND_VALUE ,GENERATE_DATE
      )
    SELECT a.brch_cd, brch_name, s_amt, t_amt, m_amt, tot_amt, P_USER_ID, v_random_value,P_GENERATE_DATE
    FROM
      (
        SELECT brch_cd, SUM(DECODE( client_type_3,'S',sum_amt, 0)) S_amt, SUM(DECODE( client_type_3,'T',sum_amt, 0)) T_amt, SUM(DECODE( client_type_3,'M',sum_amt, 0)) M_amt, SUM(sum_amt) tot_amt
        FROM
          (
            SELECT client_cd, brch_cd, client_type_3, SUM( amt) sum_amt
            FROM
              (
                SELECT sl_acct_cd client_cd, DECODE(rem_Cd, 'LOT','LO',trim(branch_code)) brch_cd, client_type_3, DECODE(db_cr_flg,'D',1,-1) * curr_val AS amt
                FROM t_account_ledger, mst_client
                WHERE sl_acct_Cd   = client_cd
                AND client_type_3 IN ('S','T','M')
                  --and client_Cd = 'MAGD005R'
                AND doc_date BETWEEN vp_from_dt AND vp_to_dt
                AND due_date    <= vp_to_dt
                AND approved_sts = 'A'
                AND reversal_jur = 'N'
                UNION ALL
                SELECT sl_acct_Cd, DECODE(rem_Cd, 'LOT','LO',trim(branch_code)), client_type_3, deb_obal - cre_obal begbal
                FROM t_day_trs, mst_client
                WHERE trs_Dt = vp_from_dt
                  --and sl_acct_cd = 'MAGD005R'
                AND sl_acct_Cd     = client_cd
                AND client_type_3 IN ('S','T','M')
              )
            GROUP BY client_cd, brch_cd, client_type_3
            HAVING SUM( amt) > 0
              -- and brch_cd = 'SB' and client_type_3 = 'S'
              --order by client_Cd
          )
        GROUP BY brch_cd
      )
      a, mst_branch b
    WHERE a.brch_cd = trim(b.brch_cd)
    ORDER BY 1;
  EXCEPTION
  WHEN OTHERS THEN
    V_ERROR_CD  := -30;
    V_ERROR_MSG := SUBSTR('INSERT R_REKAP_SALDO_AR '||V_ERROR_MSG||SQLERRM(SQLCODE),1,200);
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
END SPR_REKAP_SALDO_AR;