CREATE OR REPLACE
PROCEDURE SPR_PORTO_STOCK(
    P_END_DATE      DATE,
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
BEGIN
  V_RANDOM_VALUE := ABS(DBMS_RANDOM.RANDOM);
  BEGIN
    SP_RPT_REMOVE_RAND('R_PORTO_STOCK',V_RANDOM_VALUE,V_ERROR_MSG,V_ERROR_CD);
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
  dt_end_date   :=P_END_DATE;
  dt_begin_date := TO_DATE('01'||TO_CHAR(dt_end_date,'MMYYYY'),'DDMMYYYY');
  BEGIN
    INSERT
    INTO
      R_PORTO_STOCK
      (
        STK_CD ,
        NOMINAL ,
        PRICE ,
        MARKET_VALUE ,
        HAIRCUT_MKBD ,
        HAIRCUT_AMT ,
        SELISIH ,
        RANKING ,
        EKUITAS ,
        EKUITAS02 ,
        MKBD_VD51 ,
        MKBD_VD59 ,
        END_DATE ,
        USER_ID ,
        RAND_VALUE ,
        GENERATE_DATE
      )
    SELECT
      t.stk_cd,
      t.bal_qty              AS nominal,
      p.stk_clos             AS price,
      t.bal_qty * p.stk_clos AS market_value,
      NVL(b.haircut_mkbd,0) haircut_mkbd,
      NVL(b.haircut_mkbd,0)  * (t.bal_qty * p.stk_clos ) AS haircut_amt,
      (t.bal_qty             * p.stk_clos ) - (0.2 * e.ekuitas ) selisih,
      DECODE(SIGN((t.bal_qty * p.stk_clos ) - (0.2 * e.ekuitas ) ), 1, (
      t.bal_qty              * p.stk_clos ) - (0.2 * e.ekuitas ),0) ranking,
      e.ekuitas,
      (0.2 * e.ekuitas ) ekuitas02,
      mkbd_vd51,
      mkbd_vd59,
      P_END_DATE,
      P_USER_ID,
      V_RANDOM_VALUE,
      P_GENERATE_DATE
    FROM
      (
        SELECT
          stk_cd,
          HAIRCUT_MKBD,
          mkbd_vd51,
          mkbd_vd59
        FROM
          (
            SELECT
              t.stk_cd,
              HAIRCUT_MKBD
            FROM
              v_STK_HAIRCUT_MKBD t,
              (
                SELECT
                  stk_cd,
                  MAX(eff_dt) max_dt
                FROM
                  V_STK_HAIRCUT_MKBD
                WHERE
                  eff_dt <= dt_end_date
                GROUP BY
                  stk_cd
              )
              mx
            WHERE
              t.eff_dt   = mx.max_Dt
            AND t.stk_cd = mx.stk_cd
          )
          ,
          (
            SELECT
              faktorisasi ,
              mkbd_cd mkbd_vd51
            FROM
              FORM_MKBD
            WHERE
              mkbd_cd BETWEEN 71 AND 80
            AND source = 'VD51'
            AND dt_end_date BETWEEN ver_bgn_dt AND ver_end_dt
          )
          vd51,
          (
            SELECT
              faktorisasi ,
              mkbd_cd mkbd_vd59
            FROM
              FORM_MKBD
            WHERE
              mkbd_cd BETWEEN 45 AND 54
            AND source = 'VD59'
            AND dt_end_date BETWEEN ver_bgn_dt AND ver_end_dt
          )
          vd59
        WHERE
          HAIRCUT_MKBD   = vd51.faktorisasi
        AND HAIRCUT_MKBD = vd59.faktorisasi
      )
      b,
      (
        SELECT
          SUM(beg_bal) ekuitas
        FROM
          (
            SELECT
              (NVL(b.cre_obal,0) - NVL(b.deb_obal,0)) beg_bal
            FROM
              T_DAY_TRS b,
              MST_MAP_MKBD m
            WHERE
              b.trs_dt       = dt_begin_date
            AND b.gl_acct_cd = m.GL_a
            AND m.source     = 'VD52'
            AND m.mkbd_cd   IN ('167','168','169','170')
            AND dt_end_date BETWEEN m.ver_bgn_dt AND m.ver_end_dt
            UNION ALL
            SELECT
              (DECODE(d.db_cr_flg,'C',NVL(d.curr_val,0),0) - DECODE(d.db_cr_flg
              ,'D',NVL(d.curr_val,0),0)) trx_amt
            FROM
              T_ACCOUNT_LEDGER d,
              MST_MAP_MKBD m
            WHERE
              d.doc_date BETWEEN dt_begin_date AND dt_end_date
            AND d.approved_sts <> 'C'
            AND d.approved_sts <> 'E'
            AND d.gl_acct_cd    = m.GL_a
            AND m.source        = 'VD52'
            AND m.mkbd_cd      IN ('167','168','169','170')
            AND dt_end_date BETWEEN m.ver_bgn_dt AND m.ver_end_dt
            UNION ALL
            SELECT
              SUM( DECODE(t.db_cr_flg,'C',1,-1 ) * t.curr_val) pl
            FROM
              (
                SELECT
                  gl_acct_cd,
                  db_cr_flg,
                  curr_val
                FROM
                  T_ACCOUNT_LEDGER
                WHERE
                  approved_sts   <> 'C'
                AND approved_sts <> 'E'
                AND doc_date BETWEEN dt_begin_date AND dt_end_date
              )
              t,
              (
                SELECT
                  prm_cd_2 AS prefix,
                  prm_desc acct_type
                FROM
                  MST_PARAMETER
                WHERE
                  prm_cd_1 = 'PLACCT'
              )
              m
            WHERE
              t.gl_acct_cd LIKE prefix
          )
      )
      e,
      (
        SELECT
          stk_cd,
          SUM(qty) AS bal_qty
        FROM
          v_OWN_PORTO
        WHERE
          doc_dt BETWEEN dt_begin_date AND dt_end_date
        GROUP BY
          stk_cd
      )
      t,
      (
        SELECT
          cp.stk_Cd,
          TRUNC( stk_clos * NVL(to_qty,1) /NVL(from_qty,1), 0) AS stk_clos
        FROM
          (
            SELECT
              stk_Cd,
              stk_clos
            FROM
              T_CLOSE_PRICE
            WHERE
              stk_date = dt_end_date
          )
          cp,
          (
            SELECT
              stk_Cd,
              to_qty ,
              from_qty
            FROM
              T_CORP_ACT
            WHERE
              ca_type IN ('SPLIT','REVERSE')
            AND dt_end_date BETWEEN x_dt AND recording_Dt
            AND approved_stat = 'A'
          )
          ca
        WHERE
          cp.stk_cd = ca.stk_cd(+)
      )
      p
    WHERE
      t.bal_qty  > 0
    AND p.stk_cd = t.stk_cd
    AND t.stk_cd = b.stk_cd(+)
    ORDER BY
      haircut_mkbd,
      stk_Cd;
  EXCEPTION
  WHEN OTHERS THEN
    V_ERROR_CD  := -60;
    V_ERROR_MSG := SUBSTR('INSERT R_PORTO_STOCK'||V_ERROR_MSG||SQLERRM(SQLCODE) , 1, 200);
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
END SPR_PORTO_STOCK;