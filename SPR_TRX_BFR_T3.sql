CREATE OR REPLACE
PROCEDURE SPR_TRX_BFR_T3(
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
  dt_begin_prev  DATE;
  dt_end_date    DATE;
  dt_begin_date  DATE;
BEGIN
  V_RANDOM_VALUE := ABS(DBMS_RANDOM.RANDOM);
  BEGIN
    SP_RPT_REMOVE_RAND('R_TRX_BFR_T3',V_RANDOM_VALUE,V_ERROR_MSG,V_ERROR_CD);
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
  BEGIN
    INSERT
    INTO R_TRX_BFR_T3
      (
        SORTK ,SL_ACCT_CD ,MRKT_TYPE ,BELI_JUAL ,NET_T0 ,NET_T1 ,NET_T2 ,NET_T3
        ,NET_T0_BUY ,NET_T0_SELL ,NET_T1_BUY ,NET_T1_SELL ,NET_T2_BUY ,
        NET_T2_SELL ,NET_T3_BUY ,NET_T3_SELL ,NET_BUY ,NET_SELL ,T1_DATE ,
        T2_DATE ,T3_DATE ,AR_ACCT ,AP_ACCT ,END_DATE ,USER_ID ,RAND_VALUE ,
        GENERATE_DATE
      )
    SELECT sortk, sl_acct_cd, DECODE(mrkt_type,'RG','',mrkt_type) mrkt_type,
      Beli_jual, net_t0_buy + net_t0_sell AS net_t0, net_t1_buy + net_t1_sell AS net_t1,
      net_t2_buy + net_t2_sell AS net_t2, net_t3_buy + net_t3_sell AS net_t3,
      net_t0_buy, net_t0_sell, net_t1_buy, net_t1_sell, net_t2_buy,
      net_t2_sell, net_t3_buy,net_t3_sell, ( net_t0_buy+ net_t1_buy +
      net_t2_buy                                       + net_t3_buy) net_buy, (
      net_t0_sell                                      +net_t1_sell +
      net_t2_sell                                      + net_t3_sell) net_sell,
      t1_date, t2_date, t3_date, ar_acct, ap_acct , P_END_DATE, P_USER_ID,
      V_RANDOM_VALUE,P_GENERATE_DATE
    FROM
      (
        SELECT 'TRANSAKSI' sortk, sl_acct_cd, mrkt_type,Beli_jual, SUM(DECODE(
          SIGN(net_t0),1,net_t0,0)) net_t0_buy, SUM(DECODE(SIGN(net_t0),-1,
          net_t0,0)) net_t0_sell, SUM(DECODE(SIGN(net_t1),1,net_t1,0))
          net_t1_buy, SUM(DECODE(SIGN(net_t1),-1,net_t1,0)) net_t1_sell, SUM(
          DECODE(SIGN(net_t2),1,net_t2,0)) net_t2_buy, SUM(DECODE(SIGN(net_t2),
                                              -1,net_t2,0)) net_t2_sell, SUM(DECODE(SIGN(net_t3),1,net_t3,0))
          net_t3_buy, SUM(DECODE(SIGN(net_t3),-1,net_t3,0)) net_t3_sell, MAX(
          t1_date) t1_date, MAX( t2_date) t2_date, MAX( t3_date) t3_date
        FROM
          (
            SELECT sl_acct_cd, 'RG' mrkt_type,'' Beli_jual, SUM( beg_bal + mvmt
              ) net_t0,0 net_t1,0 net_t2,0 net_t3, TO_DATE(NULL) t1_date,
              TO_DATE(NULL) t2_date, TO_DATE(NULL) t3_date
            FROM
              (
                SELECT sl_acct_cd, (b.deb_obal -b.cre_obal) beg_bal, 0 mvmt
                FROM T_DAY_TRS b, v_gl_acct_type a
                WHERE b.trs_dt   = dt_begin_prev
                AND a.acct_type  = 'CLIE'
                AND b.gl_acct_cd = a.gl_A
                UNION ALL
                SELECT sl_acct_cd, 0 beg_bal, DECODE(d.db_cr_flg,'D',1,-1) *
                  d.curr_val mvmt
                FROM T_ACCOUNT_LEDGER d, v_gl_acct_type a
                WHERE d.doc_date BETWEEN dt_begin_prev AND dt_end_date
                AND d.approved_sts <> 'C'
                AND d.approved_sts <> 'E'
                AND d.due_date     <= dt_end_date
                AND a.acct_type     = 'CLIE'
                AND d.gl_acct_cd    = a.gl_A
              )
            GROUP BY sl_acct_cd
            HAVING SUM( beg_bal + mvmt) <> 0
            UNION ALL
            SELECT d.sl_acct_cd, d.mrkt_type, d.beli_jual, 0 net_t0, SUM(DECODE
              (n.norut,1,DECODE(d.db_cr_flg, 'D',1,'C',                  -1) * curr_val,0))
              net_t1, SUM(DECODE(n.norut,2,DECODE(d.db_cr_flg, 'D',1,'C',-1) *
              curr_val,0)) net_t2, SUM(DECODE(n.norut,3,DECODE(d.db_cr_flg, 'D'
              ,1,'C',-1) * curr_val,0)) net_t3, t1_date, t2_date, t3_date
            FROM
              (
                SELECT norut, due_date, MAX(DECODE(norut,1,due_date,NULL)) over
                  ( ) t1_date, MAX(DECODE(norut,2,due_date,NULL)) over ( )
                  t2_date, MAX(DECODE(norut,3,due_date,NULL)) over ( ) t3_date
                FROM
                  (
                    SELECT row_number( ) over (ORDER BY due_date) norut ,
                      due_date
                    FROM
                      (
                        SELECT DISTINCT due_date
                        FROM T_ACCOUNT_LEDGER d, v_gl_acct_type a
                        WHERE d.doc_date BETWEEN dt_begin_date - 30 AND
                          dt_end_date
                        AND d.due_Date      > dt_end_date
                        AND d.reversal_jur  = 'N'
                        AND d.approved_sts <> 'C'
                        AND d.approved_sts <> 'E'
                        AND a.acct_type     = 'CLIE'
                        AND d.gl_acct_cd    = a.gl_A
                        AND d.record_source = 'CG'
                      )
                  )
              )
              n, (
                SELECT d1.sl_acct_cd, d1.due_date, d1.db_cr_flg, d1.curr_val,
                  t.mrkt_type, DECODE(mrkt_type,'RG','',t.Beli_jual) beli_jual
                FROM
                  (
                    SELECT DECODE(SUBSTR(contr_num,6,1),'I',SUBSTR(contr_num,1,
                      6)||'0'||SUBSTR(contr_num,8,7), contr_num) AS contr_num,
                      DECODE(SUBSTR(contr_num,6,1),'I',SUBSTR(contr_num,5,2),
                      mrkt_type) mrkt_type, SUBSTR(contr_num,5,1) Beli_jual
                    FROM T_CONTRACTS
                    WHERE contr_dt BETWEEN dt_begin_date - 30 AND dt_end_date
                    AND contr_stat            <>'C'
                    AND SUBSTR(contr_num,5,3) <> 'BIJ'
                    AND SUBSTR(contr_num,5,3) <> 'JIB'
                    UNION ALL
                    SELECT doc_num, 'RG' mrkt_type, trx_type
                    FROM T_BOND_TRX
                    WHERE trx_date BETWEEN dt_begin_date - 30 AND dt_end_date
                    AND approved_sts = 'A'
                    AND doc_num     IS NOT NULL
                  )
                  t, (
                    SELECT t1.*
                    FROM T_ACCOUNT_LEDGER t1, v_gl_acct_type a
                    WHERE t1.doc_date BETWEEN dt_begin_date - 30 AND
                      dt_end_date
                    AND t1.due_Date      > dt_end_date
                    AND t1.approved_sts <> 'C'
                    AND t1.approved_sts <> 'E'
                    AND t1.record_source = 'CG'
                    AND t1.reversal_jur  = 'N'
                    AND a.acct_type      = 'CLIE'
                    AND t1.gl_acct_cd    = a.gl_A
                  )
                  d1
                WHERE d1.xn_doc_num = t.contr_num
              )
              d
            WHERE d.due_date = n.due_date
            GROUP BY d.sl_acct_cd, d.mrkt_type, d.beli_jual,d.due_date, t1_date
              ,t2_date,t3_date
            ORDER BY 1, 2,3
          )
        GROUP BY sl_acct_cd, mrkt_type,Beli_jual
        UNION ALL
        SELECT '2MIN FEE' sortk, sl_acct_cd, 'RG' mrkt_type, '' beli_jual, 0
          net_t0_buy, 0 net_t0_sell, SUM(DECODE(due_date,get_due_date(1,
          dt_end_date),curr_val,0)) net_t1_buy, 0 net_t1_sell, SUM(DECODE(
          due_date,get_due_date(2,dt_end_date),curr_val,0)) net_t2_buy, 0
          net_t2_sell, SUM(DECODE(due_date,get_due_date(3,dt_end_date),curr_val
          ,0)) net_t3_buy, 0 net_t3_sell, get_due_date(1,dt_end_date) t1_date,
          get_due_date(2,dt_end_date) t2_date, get_due_date(3,dt_end_date)
          t3_date
        FROM T_ACCOUNT_LEDGER
        WHERE doc_date BETWEEN dt_begin_date - 30 AND dt_end_date
        AND due_Date      > dt_end_date
        AND approved_sts <> 'C'
        AND approved_sts <> 'E'
        AND record_source = 'GL'
        AND reversal_jur  = 'N'
        AND xn_doc_num LIKE '%GLAMFE%'
        AND tal_id = 1
        GROUP BY SL_ACCT_CD
      )
      t, (
        SELECT MAX(DECODE(db_cr_flg, 'D',gl_A,NULL)) ar_acct, MAX(DECODE(
          db_cr_flg, 'C',gl_A,NULL)) ap_acct
        FROM v_gl_acct_type
        WHERE acct_type = 'CLIE'
      )
      b;
  EXCEPTION
  WHEN OTHERS THEN
    V_ERROR_CD  := -60;
    V_ERROR_MSG := SUBSTR('INSERT R_TRX_BFR_T3'||V_ERROR_MSG||SQLERRM(SQLCODE),
    1,200);
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
END SPR_TRX_BFR_T3;