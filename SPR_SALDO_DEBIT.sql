CREATE OR REPLACE
PROCEDURE SPR_SALDO_DEBIT(
    P_END_DATE      DATE,
    P_TYPE          VARCHAR2,
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
  s_type         VARCHAR2(1);
BEGIN
  V_RANDOM_VALUE := ABS(DBMS_RANDOM.RANDOM);
  BEGIN
    SP_RPT_REMOVE_RAND('R_SALDO_DEBIT',V_RANDOM_VALUE,V_ERROR_MSG,V_ERROR_CD);
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
  s_type        := P_TYPE;
  BEGIN
    INSERT
    INTO R_SALDO_DEBIT
      (
        MKBD_CD ,GL_ACCT_CD ,MARGIN_CD ,CLIENT_CD ,CLIENT_NAME ,END_BAL ,
        END_DATE ,USER_ID ,RAND_VALUE ,GENERATE_DATE,typ
      )
    SELECT DECODE(s_type,'R','103','35') AS mkbd_cd, gl_acct_cd, margin_cd,
      sl_acct_cd client_cd, m.client_name, n.end_bal,P_END_DATE, P_USER_ID,
      V_RANDOM_VALUE,P_GENERATE_DATE,s_type
    FROM
      (
        SELECT gl_acct_cd, acct_type,sl_acct_cd, SUM(amt ) end_bal
        FROM
          (
            SELECT gl_acct_cd, sl_acct_cd, a.jur_type AS acct_type, DECODE(
              T_ACCOUNT_LEDGER.db_cr_flg, 'D', 1, -1) * NVL(
              T_ACCOUNT_LEDGER.curr_val, 0) amt
            FROM MST_CLIENT, T_ACCOUNT_LEDGER, (
                SELECT gl_a, jur_type
                FROM MST_GLA_TRX
                WHERE jur_type IN ('T3','T7')
              )
              a
            WHERE T_ACCOUNT_LEDGER.sl_acct_cd = MST_CLIENT.client_cd
            AND T_ACCOUNT_LEDGER.doc_date BETWEEN dt_begin_date AND dt_end_date
            AND T_ACCOUNT_LEDGER.approved_sts = 'A'
            AND T_ACCOUNT_LEDGER.gl_acct_cd   = a.gl_A
            UNION ALL
            SELECT gl_acct_cd, sl_acct_cd, a.jur_type AS acct_type, (NVL(
              T_DAY_TRS.deb_obal, 0) - NVL(T_DAY_TRS.cre_obal, 0)) beg_bal
            FROM MST_CLIENT, T_DAY_TRS, (
                SELECT gl_a, jur_type
                FROM MST_GLA_TRX
                WHERE jur_type IN ('T3','T7')
              )
              a
            WHERE T_DAY_TRS.sl_acct_cd = MST_CLIENT.client_cd
            AND T_DAY_TRS.gl_acct_cd   = a.gl_A
            AND T_DAY_TRS.trs_dt       = dt_begin_date
          )
        GROUP BY gl_acct_cd, sl_acct_cd, acct_type
        HAVING SUM(amt ) > 0
      )
      n, (
        SELECT m.client_cd, m.client_name, margin_cd
        FROM MST_CLIENT m, LST_TYPE3 l
        WHERE m.client_type_3 = l.cl_type3
        AND m.client_type_1  <> 'B'
      )
      m
    WHERE m.client_cd = n.sl_acct_cd
    AND
      (
        (
          s_type = 'R'
        AND
          (
            margin_cd  = 'R'
          OR acct_type = 'T7'
          )
        )
      OR
        (
          s_type      = 'M'
        AND margin_cd = 'M'
        AND acct_type = 'T3'
        )
      )
    ORDER BY 2,3,4;
  EXCEPTION
  WHEN OTHERS THEN
    V_ERROR_CD  := -60;
    V_ERROR_MSG := SUBSTR('INSERT R_SALDO_DEBIT'||V_ERROR_MSG||SQLERRM(SQLCODE)
    , 1,200);
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
END SPR_SALDO_DEBIT;