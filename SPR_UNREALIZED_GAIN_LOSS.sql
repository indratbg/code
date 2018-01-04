create or replace PROCEDURE SPR_UNREALIZED_GAIN_LOSS(
    dt_beg_dt       DATE,
    dt_end_dt       DATE,
    s_bgn_client    VARCHAR2,
    s_end_client    VARCHAR2,
    s_bgn_stk       VARCHAR2,
    s_end_stk       VARCHAR2,
    s_bgn_branch    VARCHAR2,
    s_end_branch    VARCHAR2,
    s_bgn_rem       VARCHAR2,
    s_end_rem       VARCHAR2,
    as_limit        VARCHAR2,
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
  dt_price_date  DATE;
BEGIN

  v_random_value := ABS(dbms_random.random);
  
  BEGIN
    SP_RPT_REMOVE_RAND('R_UNREALIZED_GAIN_LOSS',V_RANDOM_VALUE,V_ERROR_MSG, V_ERROR_CD);
  EXCEPTION
  WHEN OTHERS THEN
    V_ERROR_CD  := -10;
    V_ERROR_MSG := SUBSTR('SP_RPT_REMOVE_RAND '||V_ERROR_MSG||SQLERRM(SQLCODE), 1,200);
    RAISE V_err;
  END;
  
  IF V_ERROR_CD  <0 THEN
    V_ERROR_CD  := -20;
    V_ERROR_MSG := SUBSTR('SP_RPT_REMOVE_RAND'||V_ERROR_MSG,1,200);
    RAISE V_ERR;
  END IF;
  
  dt_price_date := dt_end_dt;--'15apr2015';

  
  
  BEGIN
    INSERT
    INTO R_UNREALIZED_GAIN_LOSS
      (
        CLIENT_CD ,TYP ,OLD_CD ,CLIENT_NAME ,BRANCH_CODE ,REM_CD ,REM_NAME ,SUBREK ,SID ,STK_CD ,STK_DESC ,END_THEO ,END_ONH ,AVG_PRICE ,CLOSE_PRICE ,STK_VAL ,MARKET_VAL ,GAINLOSS ,GAINLOSS_PERC ,OUTSAR ,OUTSAP ,REKDANA_BALANCE ,OUTSAMT ,SHORT_AMT ,PORTO_AMT ,CR_LIM ,AVAIL_LIM ,USER_ID ,RAND_VALUE ,GENERATE_DATE, FROM_DATE, END_DATE
      )
    SELECT c.client_cd, 1 AS typ, m.old_cd, m.client_name, m.branch_code, m.rem_cd, m.rem_name, m.subrek, f_sid(m.sid) as sid, c.stk_cd, e.stk_desc, c.end_theo, c.end_onh, NVL( d.avg_price,0) avg_price, NVL(e.close_price,0) close_price, c.end_theo * NVL( d.avg_price,0) AS stk_val, c.end_theo * NVL(e.close_price,0) AS market_val, c.end_theo * NVL(e.close_price,0) - c.end_theo * NVL( d.avg_price,0) AS gainloss, DECODE( c.end_theo * NVL( d.avg_price,0), 0,0, ROUND(( c.end_theo * NVL(e.close_price,0) - c.end_theo * NVL( d.avg_price,0)) / (c.end_theo * NVL( d.avg_price,0)) * 100,2)) gainloss_perc, 0 outsAR, 0 outsAP, 0 rekdana_balance, 0 outsamt, 0 short_amt, 0 porto_amt, 0 cr_lim, 0 avail_lim , P_USER_ID, v_random_value, P_GENERATE_DATE, dt_beg_dt,dt_end_dt
    FROM
      (
        SELECT client_cd, stk_cd, SUM(beg_bal_qty + theo_mvmt) end_theo, SUM(beg_on_hand + onh_mvmt) end_onh
        FROM
          (
            SELECT client_cd, NVL( stk_cd_new,stk_cd) stk_cd, beg_bal_qty, theo_mvmt, beg_on_hand, onh_mvmt
            FROM
              (
                SELECT t.client_cd, t.stk_cd, 0 beg_bal_qty, 0 beg_on_hand, DECODE(trim(t.gl_acct_cd),'33',0,'36',0,1) * DECODE(t.db_cr_flg,'D',1,-1) * (t.total_share_qty + t.withdrawn_share_qty) theo_mvmt, DECODE(trim(t.gl_acct_cd),'33',1,'36',1,0) * DECODE(t.db_cr_flg,'C',1,-1) * (t.total_share_qty + t.withdrawn_share_qty) onh_mvmt
                FROM T_STK_MOVEMENT t
                WHERE t.doc_stat           = '2'
                AND t.gl_acct_cd          IN ('14','51','12','13','10','33','36')
                AND SUBSTR(t.doc_num,5,3) <> 'JVA'
                AND SUBSTR(t.doc_num,5,3) <> 'JAD'
                AND t.doc_dt BETWEEN dt_beg_dt AND dt_end_dt
                AND t.client_cd BETWEEN s_bgn_client AND s_end_client
                AND t.stk_cd BETWEEN s_bgn_stk AND s_end_stk
                UNION ALL
                SELECT t.client_cd, t.stk_cd, t.beg_bal_qty, t.beg_on_hand, 0 theo_mvmt, 0 onh_mvmt
                FROM T_STKBAL t
                WHERE t.client_cd BETWEEN s_bgn_client AND s_end_client
                AND t.stk_cd BETWEEN s_bgn_stk AND s_end_stk
                AND t.bal_dt = dt_beg_dt
              )
              s, (
                SELECT stk_Cd_old, stk_cd_new
                FROM T_CHANGE_STK_CD
                WHERE eff_dt <= dt_end_dt
              )
              c
            WHERE s.stk_cd = c.stk_cd_old(+)
          )
        GROUP BY client_cd, stk_cd
        HAVING SUM(beg_bal_qty + theo_mvmt) <> 0
      )
      C, (
        SELECT p.client_cd, p.stk_cd, p.avg_buy_price AS avg_price
        FROM T_AVG_PRICE P, (
            SELECT client_cd, stk_cd, MAX(avg_dt) maxdt
            FROM T_AVG_PRICE
            WHERE avg_dt <= dt_end_dt
            GROUP BY client_cd, stk_cd
          )
          P1
        WHERE p.avg_dt  = p1.maxdt
        AND p.client_cd = p1.client_cd
        AND p.stk_cd    = p1.stk_cd
        AND p.client_cd BETWEEN s_bgn_client AND s_end_client
        AND p.stk_cd BETWEEN s_bgn_stk AND s_end_stk
      )
      D, (
        SELECT MST_COUNTER.stk_cd,INITCAP(NVL(v_stk_clos.stk_name,MST_COUNTER.stk_desc)) stk_desc , NVL(DECODE(v_stk_clos.stk_clos, 0, v_stk_clos.stk_prev, v_stk_clos.stk_clos), 0) close_price
        FROM v_stk_clos, MST_COUNTER
        WHERE v_stk_clos.stk_date(+) = dt_price_date
        AND MST_COUNTER.stk_cd       = v_stk_clos.stk_cd(+)
      )
      E, (
        SELECT client_cd, MST_CLIENT.old_ic_num AS old_cd, client_name, branch_code, MST_CLIENT.rem_cd, rem_name, agreement_no AS subrek, MST_CLIENT.sid
        FROM MST_CLIENT, MST_SALES
        WHERE MST_CLIENT.client_cd BETWEEN s_bgn_client AND s_end_client
        AND trim(MST_CLIENT.rem_cd) BETWEEN s_bgn_rem AND s_end_rem
        AND trim(MST_CLIENT.branch_code) BETWEEN s_bgn_branch AND s_end_branch
        AND trim(MST_CLIENT.rem_cd) = trim(MST_SALES.rem_cd)
      )
      M
    WHERE c.client_cd = d.client_cd (+)
    AND c.stk_cd      = d.stk_cd (+)
    AND c.stk_cd      = e.stk_cd (+)
    AND c.client_cd   = m.client_cd
    
    UNION ALL
    SELECT client_cd, 2 AS typ, old_cd, client_name, branch_code, rem_cd, rem_name, subrek, f_sid(sid) as sid, '-' stk_cd, NULL stk_desc, 0 end_theo, 0 end_onh, 0 avg_price, 0 close_price, 0 stk_val, 0 market_val, 0 gainloss, 0 gainloss_perc, outsAR, outsAP, rekdana_balance, outsamt, short_amt, porto_amt, cr_lim, avail_lim , P_USER_ID, v_random_value, P_GENERATE_DATE, dt_beg_dt,dt_end_dt
    FROM
      (
        SELECT m.client_cd, m.client_name, m.old_ic_num AS old_cd, m.branch_code,m.rem_cd, s.rem_name, m.agreement_no AS subrek, m.sid, NVL(outs.outsAR,0) outsAr, NVL(outs.outsAP,0) outsap, NVL(outs.outsamt,0) outsamt, NVL(porto.short_amt,0) AS short_amt, NVL(porto.porto_amt,0) porto_amt, NVL(m.cr_lim, 0) cr_lim, (( NVL(porto.porto_amt,0) / 2) - NVL(outs.outsamt,0) ) * 2 AS avail_lim , NVL(rekdana_balance,0) AS rekdana_balance
        FROM
          (
            SELECT client_cd, SUM(NVL(outsAR,0)) AS outsAR, SUM(NVL(outsAP,0)) AS outsAP, SUM(NVL(outsamt,0)) - NVL(rekdana_balance,0) AS outsamt, rekdana_balance
            FROM
              (
                SELECT client_cd, doc_date, due_date, DECODE(SIGN(due_date- dt_end_dt),-1,0,0,0,1) * DECODE(SIGN(os_amt), 1,os_amt, 0) AS outsar, DECODE(SIGN(due_date- dt_end_dt),-1,0,0,0,1) * DECODE(SIGN(os_amt), -1,ABS(os_amt), 0) AS outsap, os_amt AS outsamt , rekdana_balance
                FROM
                  (
                    SELECT x.client_Cd, x.doc_num, x.doc_folder, x.doc_date, x.due_date, x.orig_amt, x.orig_amt - NVL(p.pay_amt,0) AS os_amt, x.gl_acct_cd, x.xn_doc_num, x.descrip , fb.rekdana_balance
                    FROM
                      (
                        SELECT c.client_cd, c.contr_num AS doc_num, SUBSTR(c.contr_num,5,11) AS doc_folder, c.contr_dt AS doc_date, c.due_dt_for_amt AS due_date, DECODE(t.db_cr_flg,'D',1,-1) * c.amt_for_curr AS orig_amt, DECODE(t.db_cr_flg,'D',1,-1) * (c.amt_for_curr - NVL(c.sett_val,0) - NVL(c.sett_for_curr,0)) AS os_amt, t.gl_acct_cd, t.xn_doc_num, to_number(1) tal_id, t.ledger_nar AS descrip
                        FROM T_CONTRACTS c, T_ACCOUNT_LEDGER t
                        WHERE contr_dt    > '31jan2010'
                        AND as_limit      = 'Y'
                        AND c.contr_stat <> 'C'
                        AND c.client_cd BETWEEN s_bgn_client AND s_end_client
                        AND c.contr_dt     <= dt_end_dt
                        AND t.sl_acct_cd    = c.client_cd
                        AND c.contr_num     = t.doc_ref_num
                        AND (t.rvpv_number IS NULL
                        OR t.rvpv_number LIKE '%V%')
                        UNION
                        SELECT p.sl_acct_cd, p.payrec_num, p.ref_folder_cd, p.payrec_date, p.due_date, DECODE(p.db_cr_flg,'D',1,-1) * p.payrec_amt AS orig_amt, DECODE(p.db_cr_flg,'D',1,-1) * (p.payrec_amt - NVL(p.sett_val,0) - NVL(p.sett_for_curr,0)) AS pay_amt, t.gl_acct_cd, t.xn_doc_num, to_number(DECODE(t.record_source,'CDUE',t.netting_flg,'MDUE',t.netting_flg,t.tal_id)) AS tal_id, t.ledger_nar
                        FROM T_PAYRECD p, T_ACCOUNT_LEDGER t
                        WHERE p.record_source = 'ARAP'
                        AND as_limit          = 'Y'
                        AND p.approved_sts   <> 'C'
                        AND p.approved_sts   <> 'E'
                        AND p.payrec_date    <= dt_end_dt
                        AND p.sl_acct_cd BETWEEN s_bgn_client AND s_end_client
                        AND p.payrec_num    = t.doc_ref_num
                        AND p.sl_acct_cd    = t.sl_acct_cd
                        AND p.tal_id        = NVL(t.netting_flg,t.tal_id)
                        AND (t.rvpv_number IS NULL
                        OR t.xn_doc_num     = t.rvpv_number
                        OR t.rvpv_number LIKE '%V%'
                        OR t.rvpv_number LIKE '%DE%' )
                      )
                      X, (
                        SELECT doc_tal_id, doc_ref_num, sl_acct_cd, SUM(pay_amt) pay_amt
                        FROM
                          (
                            SELECT NVL(d.doc_tal_id,d.tal_id) doc_tal_id, d.doc_ref_num, d.sl_acct_cd, d.payrec_num, DECODE(d.db_Cr_flg,'D',-1,1) * d.payrec_amt AS pay_amt
                            FROM T_PAYRECD d, T_PAYRECH h
                            WHERE d.payrec_num  = h.payrec_num
                            AND as_limit        = 'Y'
                            AND d.approved_sts <> 'C'
                            AND d.approved_sts <> 'E'
                            AND d.payrec_date  <= dt_end_dt
                            AND d.sl_Acct_cd BETWEEN s_bgn_client AND s_end_client
                            AND d.record_source <> 'ARAP'
                          )
                        GROUP BY doc_tal_id, doc_ref_num, sl_acct_cd
                      )
                      p, (
                        SELECT CLIENT_CD, NVL(F_FUND_BAL(MST_CLIENT.client_cd, dt_end_dt),0) rekdana_balance
                        FROM MST_CLIENT
                        WHERE SUSP_STAT = 'N'
                        AND MST_CLIENT.client_cd BETWEEN s_bgn_client AND s_end_client
                      )
                      fb
                    WHERE x.doc_num                    = p.doc_ref_num (+)
                    AND x.client_cd                    = p.sl_acct_cd (+)
                    AND x.tal_id                       = p.doc_tal_id (+)
                    AND x.client_cd                    = fb.client_Cd (+)
                    AND (x.orig_amt - NVL(p.pay_amt,0)<> 0
                    OR fb.rekdana_balance             <> 0)
                  )
              )
            GROUP BY client_cd , rekdana_balance
          )
          outs, (
            SELECT b.client_cd, SUM(bal_qty * NVL(p.stk_clos,0) * (100 - NVL(p.mrg_stk_cap,0)) / 100) porto_amt, SUM(short * bal_qty * NVL(p.stk_clos,0)) AS short_amt
            FROM
              (
                SELECT client_cd, stk_cd, SUM(beg_bal_qty + theo_mvmt) bal_qty, DECODE(SIGN(SUM(beg_bal_qty + theo_mvmt)),-1,1,0) short
                FROM
                  (
                    SELECT client_cd, NVL( stk_cd_new, stk_cd) stk_cd, beg_bal_qty,theo_mvmt
                    FROM
                      (
                        SELECT client_cd, stk_cd, 0 beg_bal_qty, (NVL(DECODE(SUBSTR(doc_num,5,2),'BR',1,'JR',1,'BI',1,'JI',1,'RS',1,'WS',1,0) * DECODE(db_cr_flg,'D',1,-1) * (total_share_qty + withdrawn_share_qty),0)) theo_mvmt
                        FROM T_STK_MOVEMENT
                        WHERE doc_dt BETWEEN dt_beg_dt AND dt_end_dt
                        AND client_cd BETWEEN s_bgn_client AND s_end_client
                        AND gl_acct_cd IN ('10','12','13','14','51')
                        AND doc_stat    = '2'
                        AND s_d_type   <> 'V'
                        AND as_limit    = 'Y'
                        UNION ALL
                        SELECT client_cd, stk_cd, beg_bal_qty, 0 theo_mvmt
                        FROM T_STKBAL
                        WHERE bal_dt = dt_beg_dt
                        AND as_limit = 'Y'
                        AND client_cd BETWEEN s_bgn_client AND s_end_client
                      )
                      s, (
                        SELECT stk_Cd_old, stk_cd_new
                        FROM T_CHANGE_STK_CD
                        WHERE eff_dt <= dt_end_dt
                      )
                      c
                    WHERE s.stk_cd = c.stk_cd_old(+)
                  )
                GROUP BY client_cd, stk_cd
                HAVING SUM(beg_bal_qty + theo_mvmt) <> 0
              )
              b, (
                SELECT MST_COUNTER.stk_cd,INITCAP(NVL(v_stk_clos.stk_name,MST_COUNTER.stk_desc)) stk_desc, NVL(DECODE(v_stk_clos.stk_clos, 0, v_stk_clos.stk_prev, v_stk_clos.stk_clos), 0) stk_clos, NVL(MST_COUNTER.mrg_stk_cap,0) mrg_stk_cap
                FROM v_stk_clos, MST_COUNTER
                WHERE v_stk_clos.stk_date(+) = dt_price_date
                AND MST_COUNTER.stk_cd       = v_stk_clos.stk_cd(+)
              )
              p
            WHERE b.stk_cd = p.stk_cd (+)
            GROUP BY b.client_cd
          )
          porto, MST_CLIENT m, MST_SALES s
        WHERE m.client_cd  = porto.client_cd (+)
        AND m.client_cd    = outs.client_cd (+)
        AND trim(m.rem_cd) = trim(s.rem_cd(+))
        AND trim(M.rem_cd) BETWEEN s_bgn_rem AND s_end_rem
        AND trim(M.branch_code) BETWEEN s_bgn_branch AND s_end_branch
        AND as_limit         = 'Y'
        AND m.susp_stat     <> 'C'
        AND m.client_type_1 <> 'H'
      )
    WHERE (outsAmt     <> 0
    OR porto_amt       <> 0
    OR rekdana_balance <> 0);
    --ORDER BY  rem_cd, client_cd;
    
  EXCEPTION
  WHEN OTHERS THEN
    V_ERROR_CD  := -50;
    V_ERROR_MSG := SUBSTR('INSERT R_UNREALIZED_GAIN_LOSS '||V_ERROR_MSG||SQLERRM( SQLCODE),1,200);
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
END SPR_UNREALIZED_GAIN_LOSS;