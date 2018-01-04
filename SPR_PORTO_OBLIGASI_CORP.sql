CREATE OR REPLACE PROCEDURE SPR_PORTO_OBLIGASI_CORP(
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
    SP_RPT_REMOVE_RAND('R_PORTO_OBLIGASI_CORP',V_RANDOM_VALUE,V_ERROR_MSG,V_ERROR_CD);
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
    INTO R_PORTO_OBLIGASI_CORP
      (
        STK_CD ,
        JATUHTEMPO ,
        BOND_RATE ,
        PRICE ,
        NOMINAL ,
        MARKET_VALUE ,
        HAIRCUT ,
        HAIRCUT_AMT ,
        SELISIH ,
        EKUITAS ,
        RISIKO ,
        MKBD_VD51 ,
        MKBD_VD59 ,
        END_DATE ,
        USER_ID ,
        RAND_VALUE ,
        GENERATE_DATE
      )
    SELECT t.stk_cd,
      m.pp_to_dt jatuhtempo,
      p.bond_rate,
      p.price                                       AS price,
      t.bal_qty                                     AS nominal,
      p.price  * t.bal_qty/100                      AS market_value,
      h.haircut/100                                 AS haircut,
      p.price  * t.bal_qty/100 * h.haircut/100      AS haircut_amt,
      (p.price * t.bal_qty/100) - (e.ekuitas * 0.2) AS selisih,
      e.ekuitas,
      DECODE( SIGN((p.price * t.bal_qty/100) - (e.ekuitas * 0.2)), 1, (p.price * t.bal_qty/100) - (e.ekuitas * 0.2), 0) risiko,
      f.mkbd_cd AS mkbd_vd51,
      g.mkbd_cd AS mkbd_vd59 ,
      P_END_DATE,
      P_USER_ID,
      V_RANDOM_VALUE,
      P_GENERATE_DATE
    FROM
      (SELECT SUM(beg_bal) ekuitas
      FROM
        (SELECT (NVL(b.cre_obal,0) - NVL(b.deb_obal,0)) beg_bal
        FROM T_DAY_TRS b,
          MST_MAP_MKBD m
        WHERE b.trs_dt   = dt_begin_date
        AND b.gl_acct_cd = m.GL_a
        AND m.source     = 'VD52'
        AND m.mkbd_cd   IN ('167','168','169','170')
        AND dt_end_date BETWEEN m.ver_bgn_dt AND m.ver_end_dt
        UNION ALL
        SELECT (DECODE(d.db_cr_flg,'C',NVL(d.curr_val,0),0) - DECODE(d.db_cr_flg,'D',NVL(d.curr_val,0),0)) trx_amt
        FROM T_ACCOUNT_LEDGER d,
          MST_MAP_MKBD m
        WHERE d.doc_date BETWEEN dt_begin_date AND dt_end_date
        AND d.approved_sts <> 'C'
        AND d.approved_sts <> 'E'
        AND d.gl_acct_cd    = m.GL_a
        AND m.source        = 'VD52'
        AND m.mkbd_cd      IN ('167','168','169','170')
        AND dt_end_date BETWEEN m.ver_bgn_dt AND m.ver_end_dt
        UNION ALL
        SELECT SUM( DECODE(t.db_cr_flg,'C',1,-1 ) * t.curr_val) pl
        FROM
          (SELECT gl_acct_cd,
            db_cr_flg,
            curr_val
          FROM T_ACCOUNT_LEDGER
          WHERE approved_sts <> 'C'
          AND approved_sts   <> 'E'
          AND doc_date BETWEEN dt_begin_date AND dt_end_date
          )t,
          (SELECT prm_cd_2 AS prefix,
            prm_desc acct_type
          FROM MST_PARAMETER
          WHERE prm_cd_1 = 'PLACCT'
          )m
        WHERE t.gl_acct_cd LIKE prefix
        )
      ) e,
      (SELECT faktorisasi * 100 faktor,
        mkbd_cd
      FROM FORM_MKBD
      WHERE mkbd_cd BETWEEN '065' AND '069'
      AND source = 'VD51'
      AND dt_end_date BETWEEN ver_bgn_dt AND ver_end_dt
      ) f,
      (SELECT faktorisasi * 100 faktor,
        mkbd_cd
      FROM FORM_MKBD
      WHERE mkbd_cd BETWEEN '039' AND '043'
      AND source = 'VD59'
      AND dt_end_date BETWEEN ver_bgn_dt AND ver_end_dt
      ) g,
      (SELECT stk_cd,
        SUM(qty) AS bal_qty
      FROM v_OWN_PORTO
      WHERE doc_dt BETWEEN dt_begin_date AND dt_end_date
      GROUP BY stk_cd
      ) t,
      MST_COUNTER m,
      T_BOND_PRICE p,
      T_BOND_HAIRCUT h
    WHERE t.stk_cd       = m.stk_cd
    AND trim(m.CTR_TYPE) = 'OB'
    AND m.sbi_flg       <> 'Y'
    AND m.pp_to_dt      >= dt_end_date
    AND p.price_dt       = dt_end_date
    AND p.bond_cd        = t.stk_Cd
    AND dt_end_date BETWEEN h.eff_dt_from AND h.eff_dt_to
    AND h.rate_cd = p.bond_rate
    AND h.haircut = f.faktor
    AND h.haircut = g.faktor ;
  EXCEPTION
  WHEN OTHERS THEN
    V_ERROR_CD  := -60;
    V_ERROR_MSG := SUBSTR('INSERT R_PORTO_OBLIGASI_CORP'||V_ERROR_MSG||SQLERRM(SQLCODE) , 1, 200);
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
END SPR_PORTO_OBLIGASI_CORP;