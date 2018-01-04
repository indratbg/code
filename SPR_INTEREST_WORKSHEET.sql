create or replace PROCEDURE SPR_INTEREST_WORKSHEET(
    dt_bgn_dt       DATE,
    dt_end_dt       DATE,
    s_bgn_client    VARCHAR2,
    s_end_client    VARCHAR2,
    as_deposit      VARCHAR2,
    s_bgn_branch    VARCHAR2,
    s_end_branch    VARCHAR2,
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
BEGIN
  --  V_ERROR_CD  := -10;
  --    V_ERROR_MSG :=s_bgn_branch||' '||s_end_branch;
  --    RAISE V_err;
  v_random_value := ABS(dbms_random.random);
  BEGIN
    SP_RPT_REMOVE_RAND('R_INTEREST_WORKSHEET',V_RANDOM_VALUE,V_ERROR_MSG,
    V_ERROR_CD);
  EXCEPTION
  WHEN OTHERS THEN
    V_ERROR_CD  := -10;
    V_ERROR_MSG := SUBSTR('SP_RPT_REMOVE_RAND '||V_ERROR_MSG||SQLERRM(SQLCODE),
    1,200);
    RAISE V_err;
  END;
  IF V_ERROR_CD  <0 THEN
    V_ERROR_CD  := -20;
    V_ERROR_MSG := SUBSTR('SP_RPT_REMOVE_RAND'||V_ERROR_MSG,1,200);
    RAISE V_ERR;
  END IF;
  BEGIN
    INSERT
    INTO
      R_INTEREST_WORKSHEET
      (
        INT_DT ,
        CLIENT_CD ,
        XN_DOC_NUM ,
        INT_PER ,
        INT_AMT ,
        DENDA ,
        KOMPENSASI ,
        INT_ACCUM ,
        INT_CRE_ACCUM ,
        TODAY_TRX ,
        NONTRX ,
        POSTED_INT ,
        CLIENT_NAME ,
        INT_ON_RECEIVABLE ,
        INT_ON_PAYABLE ,
        EFF_DT ,
        PPH23 ,
        CLIENT_TYPE_3 ,
        INT_ACCUMULATED ,
        BRANCH_CODE ,
        OLD_IC_NUM ,
        TRX_DT_BELI ,
        TRX_DT_JUAL ,
        ON_BAL_SH ,
        SUM_INT_AMT ,
        HUTANG_PPH23 ,
        USER_ID ,
        RAND_VALUE ,
        GENERATE_DATE,
        FROM_DUE_DT,
        TO_DUE_DT,
        sortk,
        INT_DEB_ACCUM
      )
    SELECT
      INT_DT,
      a.CLIENT_CD,
      XN_DOC_NUM,
      INT_PER,
      INT_AMT,
      DECODE(SIGN(int_amt), -1,0,int_amt) denda,
      DECODE(SIGN(int_amt), -1, int_amt,0) kompensasi,
      INT_ACCUM,
      INT_CRE_ACCUM,
      TODAY_TRX,
      NONTRX,
      Posted_int,
      CLIENT_NAME,
      r.int_on_receivable,
      r.INT_ON_PAYABLE,
      r.eff_Dt,
      pph23,
      CLIENT_TYPE_3,
      INT_ACCUMULATED,
      BRANCH_CODE,
      OLD_IC_NUM,
      TRX_DT_BELI,
      TRX_DT_JUAL,
      ON_BAL_SH,
      sum_int_amt,
      DECODE(SIGN(sum_int_amt),-1, ROUND(ABS(sum_int_amt)/ (100 - pph23) *
      pph23,0), 0) hutang_pph23,
      P_USER_ID,
      V_RANDOM_VALUE,
      P_GENERATE_DATE,
      dt_bgn_dt,
      dt_end_dt,
      sortk,
      INT_DEB_ACCUM
    FROM
      (
        SELECT
          int_dt,
          client_cd,
          NULL xn_doc_num,
          int_amt,
          int_accum,
          int_per,
          today_trx,
          nontrx,
          trx_dt_beli,
          trx_dt_jual,
          int_cre_accum,
          0 posted_int,
          SUM( int_amt) over (PARTITION BY client_cd) sum_int_amt,
          SUM(posted_int) over (PARTITION BY client_cd) sum_posted_int,
          1 sortk,
          INT_DEB_ACCUM
          --      SUM(ABS( int_accum))  over (PARTITION BY client_cd)
          -- sum_int_accum,
          --                        SUM(ABS(today_trx) + ABS(nontrx)) over (
          -- PARTITION BY client_cd) sum_int_mvmt
        FROM
          T_INTEREST
        WHERE
          CLIENT_CD BETWEEN s_bgn_client AND s_end_client
        AND INT_DT BETWEEN dt_bgn_dt AND dt_end_dt
        UNION ALL
        SELECT
          doc_date,
          sl_acct_cd,
          folder_cd,
          0,0,0,
          0,0,
          NULL,
          NULL,
          0,
          curr_val,
          0,
          0,
          2 sortk,
          0
        FROM
          t_account_ledger
        WHERE
          doc_date BETWEEN dt_bgn_dt AND dt_end_dt
        AND sl_Acct_Cd BETWEEN s_bgn_client AND s_end_client
        and record_source IN ('INT','DNCN')
        AND approved_sts = 'A'
        AND reversal_jur = 'N'
        AND folder_Cd LIKE 'IJ%'
      )
      a,
      (
        SELECT
          t.client_cd,
          t.eff_Dt,
          INT_ON_RECEIVABLE,
          INT_ON_PAYABLE
        FROM
          t_interest_rate t,
          (
            SELECT
              client_Cd,
              MAX(eff_dt) max_Dt
            FROM
              t_interest_rate
            WHERE
              eff_dt <= dt_end_dt
            GROUP BY
              client_cd
          )
          mx
        WHERE
          t.client_cd = mx.client_cd
        AND t.eff_dt  = max_dt
      )
      r,
      (
        SELECT
          client_cd,
          CLIENT_NAME,
          CLIENT_TYPE_3,
          DECODE(CLIENT_TYPE_2,'F',20,15) pph23,
          NVL(INT_ACCUMULATED,'Y') AS INT_ACCUMULATED,
          BRANCH_CODE,
          OLD_IC_NUM,
          NVL(AMT_INT_FLG,'Y') ON_BAL_SH
        FROM
          MST_CLIENT
        WHERE
          client_cd BETWEEN s_bgn_client AND s_end_client
        AND trim(BRANCH_CODE) BETWEEN s_bgn_branch AND s_end_branch
        AND
          (
            (
              client_type_3 = as_deposit
            )
          OR
            (
              as_deposit       = '%'
            AND client_type_3 <> 'D'
            )
          )
      )
      m
    WHERE
      a.CLIENT_CD   = m.CLIENT_CD
    AND a.CLIENT_CD = r.CLIENT_CD;
    -- AND a.xn_doc_num = h.xn_doc_num(+)
    -- AND ((a.sum_int_accum <> 0 ) OR  (a.sum_int_mvmt <> 0 ))
    --ORDER BY BRANCH_CODE, a.CLIENT_CD, INT_DT;
  EXCEPTION
  WHEN OTHERS THEN
    V_ERROR_CD  := -50;
    V_ERROR_MSG := SUBSTR('INSERT R_INTEREST_WORKSHEET '||V_ERROR_MSG||SQLERRM(
    SQLCODE),1,200);
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
END SPR_INTEREST_WORKSHEET;