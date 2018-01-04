create or replace 
PROCEDURE SPR_KPEI_BROK(
    P_END_DATE      DATE,
    p_acct_type     VARCHAR2,
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
  dt_end_date    DATE;
  dt_begin_date  DATE;
  dt_begin_prev  DATE;
  dt_min30       DATE;
BEGIN
  V_RANDOM_VALUE := ABS(DBMS_RANDOM.RANDOM);
  BEGIN
    SP_RPT_REMOVE_RAND('R_KPEI_BROK',V_RANDOM_VALUE,V_ERROR_MSG,V_ERROR_CD);
  EXCEPTION
  WHEN OTHERS THEN
    V_ERROR_CD  := -30;
    V_ERROR_MSG := SUBSTR('SP_RPT_REMOVE_RAND '||V_ERROR_MSG||SQLERRM(SQLCODE),
    1,200);
    RAISE V_err;
  END;
  IF V_ERROR_CD  <0 THEN
    V_ERROR_CD  := -40;
    V_ERROR_MSG := SUBSTR('SP_RPT_REMOVE_RAND'||V_ERROR_MSG,1,200);
    RAISE V_ERR;
  END IF;
  dt_end_date   :=P_END_DATE;
  dt_begin_date := TO_DATE('01'||TO_CHAR(dt_end_date,'MMYYYY'),'DDMMYYYY');
  dt_begin_prev := GET_DOC_DATE(3,P_END_DATE);
  dt_begin_prev := TO_DATE('01'||TO_CHAR(dt_begin_prev,'MMYYYY'),'DDMMYYYY');
  dt_min30      :=dt_begin_date - 30;
  BEGIN
    INSERT
    INTO
      R_KPEI_BROK
      (
        SL_ACCT_CD ,
        PIUTANG_ACCT ,
        UTANG_ACCT ,
        DUE_DATE ,
        PIUTANG_KPEI ,
        UTANG_KPEI ,
        NET_PIUTANG ,
        NET_UTANG ,
        END_DATE ,
        USER_ID ,
        RAND_VALUE ,
        GENERATE_DATE,
        ACCT_TYPE
      )
    SELECT
      sl_acct_cd,
      b.piutang_acct,
      b.utang_acct,
      t.due_date,
      t.piutang_kpei,
      t.utang_kpei,
      DECODE(SIGN( t.net_kpei),1,t.net_kpei,0) net_piutang,
      DECODE(SIGN( t.net_kpei),-1,t.net_kpei,0) net_utang,
      P_END_DATE,
      P_USER_ID,
      V_RANDOM_VALUE,
      P_GENERATE_DATE,
      P_ACCT_TYPE
    FROM
      (
        SELECT
          dt_end_date due_date,
          sl_acct_cd,
          0 piutang_kpei,
          0 utang_kpei,
          SUM(beg_bal + mvmt) net_kpei
        FROM
          (
            SELECT
              sl_acct_cd,
              (b.deb_obal -b.cre_obal) beg_bal,
              0 mvmt
            FROM
              T_DAY_TRS b,
              (
                SELECT
                  gl_a
                FROM
                  MST_GLA_TRX
                WHERE
                  jur_type = p_acct_type
              )
              a
            WHERE
              b.trs_dt       = dt_begin_prev
            AND b.gl_acct_cd = a.gl_A
            AND
              (
                deb_obal - cre_obal
              )
              <> 0
            UNION ALL
            SELECT
              sl_acct_cd,
              0 beg_bal,
              DECODE(d.db_cr_flg,'D',1,-1) * d.curr_val mvmt
            FROM
              T_ACCOUNT_LEDGER d,
              (
                SELECT
                  gl_a
                FROM
                  MST_GLA_TRX
                WHERE
                  jur_type = p_acct_type
              )
              a
            WHERE
              d.doc_date BETWEEN dt_begin_prev AND dt_end_date
            AND d.approved_sts <> 'C'
            AND d.approved_sts <> 'E'
            AND d.due_date     <= dt_end_date
            AND d.gl_acct_cd    = a.gl_A
          )
        GROUP BY
          sl_acct_cd
        HAVING
          (
            SUM(beg_bal + mvmt) <> 0
          OR sl_acct_cd          = 'KPEI'
          )
        UNION ALL
        SELECT
          due_date,
          sl_acct_cd,
          SUM(DECODE(d.db_cr_flg, 'D',1,0)   * curr_val) piutang_kpei,
          SUM(DECODE(d.db_cr_flg, 'C',1,0)   * curr_val) utang_kpei,
          SUM(DECODE(d.db_cr_flg, 'D',1,'C', -1) * curr_val) net_kpei
        FROM
          T_ACCOUNT_LEDGER d,
          (
            SELECT
              gl_a
            FROM
              MST_GLA_TRX
            WHERE
              jur_type = p_acct_type
          )
          a
        WHERE
          d.doc_date BETWEEN dt_min30 AND dt_end_date
        AND d.due_Date      > dt_end_date
        AND d.approved_sts <> 'C'
        AND d.approved_sts <> 'E'
        AND d.gl_acct_cd    = a.gl_A
        AND d.record_source = 'CG'
        AND reversal_jur    = 'N'
        GROUP BY
          sl_acct_cd,
          due_date
      )
      t,
      (
        SELECT
          MAX(DECODE(jur_type, p_acct_type
          ||'D',gl_A,NULL)) piutang_acct,
          MAX(DECODE(jur_type, p_acct_type
          ||'C',gl_A,NULL)) utang_acct
        FROM
          MST_GLA_TRX
        WHERE
          jur_type IN ( p_acct_type
          ||'D',p_acct_type
          ||'C')
      )
      b ;
  EXCEPTION
  WHEN OTHERS THEN
    V_ERROR_CD  := -60;
    V_ERROR_MSG := SUBSTR('INSERT R_KPEI_BROK'||V_ERROR_MSG||SQLERRM(SQLCODE ) , 1,
    200);
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
END SPR_KPEI_BROK;