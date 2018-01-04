CREATE OR REPLACE PROCEDURE SPR_ARAP_AGING_MKBD(
    P_END_DATE      DATE,
    P_BRANCH_CD     VARCHAR2,
    P_USER_ID       VARCHAR2,
    P_GENERATE_DATE DATE,
    P_RANDOM_VALUE OUT NUMBER,
    P_ERRCD OUT NUMBER,
    P_ERRMSG OUT VARCHAR2 )
IS

  V_RANDOM_VALUE NUMBER(10);
  V_ERR          EXCEPTION;
  V_ERR_CD       NUMBER(10);
  V_ERR_MSG      VARCHAR2(200);
  dt_begin_date  DATE;
  dt_end_min5    DATE;
  dt_t1_date     DATE;
  dt_end_date    DATE;
  dt_t2_date     DATE;
  dt_t3_date     DATE;
  
BEGIN

  V_RANDOM_VALUE := ABS(DBMS_RANDOM.RANDOM);
  
  BEGIN
    SP_RPT_REMOVE_RAND('R_ARAP_AGING_MKBD',V_RANDOM_VALUE,V_ERR_CD,V_ERR_MSG);
  EXCEPTION
  WHEN OTHERS THEN
    V_ERR_CD  := -2;
    V_ERR_MSG := SUBSTR('SP_RPT_REMOVE_RAND'||V_ERR_MSG,1,200);
    RAISE V_ERR;
  END;
  
  dt_begin_date := TO_DATE('01'||TO_CHAR(P_END_DATE,'MMYYYY'),'DDMMYYYY');
  dt_end_date   :=P_END_DATE;
  dt_end_min5   := Get_doc_date(5, dt_end_date);
  dt_t1_date    := Get_Due_Date(1,dt_end_date);
  dt_t2_date    := Get_Due_Date(2,dt_end_date);
  dt_t3_date    := Get_Due_Date(3,dt_end_date);
  
  BEGIN
    INSERT
    INTO R_ARAP_AGING_MKBD
      (
        SORTK ,CLIENT_TYPE ,CLIENT_CD ,CLIENT_TYPE_3 ,CLIENT_NAME ,BRANCH_CODE ,BRCH_NAME ,NET_T0 ,NET_T1 ,NET_T2
        ,NET_T3 ,BAL_1422 ,DEBIT_1422 ,BAL_1424 ,NET_T0_BUY ,NET_T0_SELL ,NET_T1_BUY ,NET_T1_SELL ,NET_T2_BUY
        ,NET_T2_SELL ,NET_T3_BUY ,NET_T3_SELL ,T1_DATE ,T2_DATE ,T3_DATE ,END_DATE ,USER_ID ,RAND_VALUE ,GENERATE_DATE,
        BRANCH_OPTION
      )
    SELECT DECODE(trim(m.client_type_3),'M','3','T','2','1') SORTK, DECODE(trim(m.client_type_3),'M','M','T','T','R') client_Type,
    x.client_Cd, m.client_type_3, m.client_name, m.branch_code, m.brch_name, x.net_t0, x.net_t1, x.net_t2, x.net_t3, x.bal_1422,
    DECODE(SIGN(x.bal_1422),1,x.bal_1422,0) AS debit_1422, x.bal_1424, net_t0_buy, net_t0_sell , net_t1_buy, net_t1_sell , net_t2_buy,
    net_t2_sell , net_t3_buy, net_t3_sell , dt_end_date t1_date, Get_Doc_Date(1,dt_end_date) t2_Date, Get_Doc_Date(2,dt_end_date) t3_date,
    P_END_DATE, P_USER_ID, V_RANDOM_VALUE, P_GENERATE_DATE, P_BRANCH_CD
    FROM
      (
        SELECT client_cd, SUM(net_t0) net_t0, SUM(net_t0_buy) net_t0_buy, SUM(net_t0_sell) net_t0_sell ,
        SUM(net_t1) net_t1, SUM(net_t1_buy) net_t1_buy, SUM(net_t1_sell) net_t1_sell , SUM(net_t2) net_t2, SUM(net_t2_buy) net_t2_buy,
        SUM(net_t2_sell) net_t2_sell , SUM(net_t3) net_t3, SUM(net_t3_buy) net_t3_buy, SUM(net_t3_sell) net_t3_sell , SUM(bal_1422) bal_1422,
        SUM(bal_1424) bal_1424
        FROM
          (
            SELECT sl_acct_cd AS client_cd, net_t0_buy + net_t0_sell AS net_t0, net_t0_buy, net_t0_sell , net_t1_buy + net_t1_sell AS net_t1,
            net_t1_buy, net_t1_sell, net_t2_buy + net_t2_sell AS net_t2, net_t2_buy, net_t2_sell, net_t3_buy + net_t3_sell AS net_t3, net_t3_buy,
            net_t3_sell, 0 bal_1422, 0 bal_1424
            FROM
              (
                SELECT '1TRANSAKSI' sortk, sl_acct_cd, mrkt_type,Beli_jual, SUM(DECODE(SIGN(net_t0),1,net_t0,0)) net_t0_buy, 
                SUM(DECODE(SIGN(net_t0),-1,net_t0,0)) net_t0_sell, SUM(DECODE(SIGN(net_t1),1,net_t1,0)) net_t1_buy,
                SUM(DECODE(SIGN(net_t1),-1,net_t1,0)) net_t1_sell, SUM(DECODE(SIGN(net_t2),1,net_t2,0)) net_t2_buy, 
                SUM(DECODE(SIGN(net_t2),-1,net_t2,0)) net_t2_sell, SUM(DECODE(SIGN(net_t3),1,net_t3,0)) net_t3_buy,
                SUM(DECODE(SIGN(net_t3),-1,net_t3,0)) net_t3_sell, MAX( t1_date) t1_date, MAX( t2_date) t2_date, 
                MAX( t3_date) t3_date
                FROM
                  (
                    SELECT d.sl_acct_cd, d.mrkt_type, d.beli_jual, 0 net_t0, SUM(DECODE(n.norut,1,DECODE(d.db_cr_flg, 'D',1,'C',-1) * curr_val,0)) net_t1, 
                    SUM(DECODE(n.norut,2,DECODE(d.db_cr_flg, 'D',1,'C',-1) * curr_val,0)) net_t2, 
                    SUM(DECODE(n.norut,3,DECODE(d.db_cr_flg, 'D',1,'C',-1) * curr_val,0)) net_t3, t1_date, t2_date, t3_date
                    FROM
                      (
                        SELECT norut, doc_date, MAX(DECODE(norut,1,doc_date,NULL)) over ( ) t1_date,
                        MAX(DECODE(norut,2,doc_date,NULL)) over ( ) t2_date,
                        MAX(DECODE(norut,3,doc_date,NULL)) over ( ) t3_date
                        FROM
                          (
                            SELECT row_number( ) over (ORDER BY doc_date DESC) norut , doc_date
                            FROM
                              (
                                SELECT DISTINCT doc_date
                                FROM T_ACCOUNT_LEDGER d, MST_GLA_TRX a
                                WHERE d.doc_date BETWEEN dt_end_min5 AND dt_end_date
                                AND d.due_Date      > dt_end_date
                                AND d.approved_sts  = 'A'
                                AND a.jur_type      = 'CLIE'
                                AND d.gl_acct_cd    = a.gl_A
                                AND d.record_source = 'CG'
                              )
                          )
                      )
                      n, (
                        SELECT d1.sl_acct_cd, d1.doc_date, d1.db_cr_flg, d1.curr_val, t.mrkt_type, t.beli_jual
                        FROM
                          (
                            SELECT DECODE(SUBSTR(contr_num,6,1),'I',SUBSTR(contr_num,1,6)||'0'||SUBSTR(contr_num,8,7), contr_num) AS contr_num,
                            mrkt_type, DECODE(mrkt_type||SUBSTR(contr_num,6,1),'RGR','',SUBSTR(contr_num,5,1)) Beli_jual
                            FROM T_CONTRACTS
                            WHERE contr_dt BETWEEN dt_end_min5 AND dt_end_date
                            AND due_dt_for_amt > dt_end_date
                            AND contr_stat    <>'C'
                            AND record_source <> 'IB'
                            UNION ALL
                            SELECT doc_num, 'RG' mrkt_type, '' Beli_jual
                            FROM T_BOND_TRX
                            WHERE trx_date BETWEEN dt_end_min5 AND dt_end_date
                            AND value_dt     > dt_end_date
                            AND approved_sts = 'A'
                            AND doc_num     IS NOT NULL
                          )
                          t, (
                            SELECT t1.xn_doc_num, t1.sl_acct_cd, t1.doc_date, t1.db_cr_flg, t1.curr_val
                            FROM T_ACCOUNT_LEDGER t1, MST_GLA_TRX a
                            WHERE t1.doc_date BETWEEN dt_end_min5 AND dt_end_date
                            AND t1.due_Date      > dt_end_date
                            AND t1.approved_sts  = 'A'
                            AND t1.record_source = 'CG'
                            AND a.jur_type       = 'CLIE'
                            AND t1.gl_acct_cd    = a.gl_A
                          )
                          d1
                        WHERE d1.xn_doc_num = t.contr_num
                      )
                      d
                    WHERE d.doc_date = n.doc_date
                    GROUP BY d.sl_acct_cd, d.mrkt_type, d.beli_jual,d.doc_date, t1_date,t2_date,t3_date
                  )
                GROUP BY sl_acct_cd, mrkt_type,Beli_jual
                UNION ALL
                SELECT '2MIN FEE' sortk, sl_acct_cd, 'RG' mrkt_type, '' beli_jual, 0 net_t0_buy, 0 net_t0_sell,
                SUM(DECODE(due_date,dt_t1_date,curr_val,0)) net_t1_buy, 0 net_t1_sell, SUM(DECODE(due_date,dt_t2_date,curr_val,0)) net_t2_buy, 
                0 net_t2_sell, SUM(DECODE(due_date,dt_t3_date,curr_val,0)) net_t3_buy, 0 net_t3_sell, dt_t1_date, dt_t2_date, dt_t3_date
                FROM T_ACCOUNT_LEDGER
                WHERE doc_date BETWEEN dt_end_min5 AND dt_end_date
                AND due_date      > dt_end_date
                AND approved_sts <> 'C'
                AND approved_sts <> 'E'
                AND reversal_jur  = 'N'
                AND record_source = 'GL'
                AND xn_doc_num LIKE '%GLAMFE%'
                AND tal_id = 1
                GROUP BY SL_ACCT_CD
              )
              t
            UNION ALL
            SELECT sl_acct_cd, 0, 0,0,0, 0, 0,0,0, 0, 0,0,0, DECODE(trim(gl_acct_Cd),'1422', bal, 0) bal_1422,
            DECODE(trim(gl_acct_Cd),'1424', bal, 0) bal_1424
            FROM
              (
                SELECT sl_acct_cd, gl_acct_cd, SUM( beg_bal + mvmt) bal
                FROM
                  (
                    SELECT sl_acct_cd, gl_acct_cd, (b.deb_obal -b.cre_obal) beg_bal, 0 mvmt
                    FROM T_DAY_TRS b
                    WHERE b.trs_dt          = dt_begin_date
                    AND trim(b.gl_acct_cd) IN ('1422','1424')
                    UNION ALL
                    SELECT sl_acct_cd, gl_acct_cd,0 beg_bal, DECODE(d.db_cr_flg,'D',1,-1) * d.curr_val mvmt
                    FROM T_ACCOUNT_LEDGER d
                    WHERE d.doc_date BETWEEN dt_begin_date AND dt_end_date
                    AND d.approved_sts     <> 'C'
                    AND d.approved_sts     <> 'E'
                    AND trim(d.gl_acct_cd) IN ('1422','1424')
                  )
                GROUP BY sl_acct_cd, gl_acct_cd
                HAVING SUM( beg_bal + mvmt) <> 0
              )
          )
        GROUP BY client_cd
      )
      x, (
        SELECT client_Cd, client_name, client_type_3, MST_CLIENT.branch_code, brch_name
        FROM MST_CLIENT, MST_BRANCH
        WHERE trim(MST_CLIENT. branch_code) = MST_BRANCH.brch_Cd
        AND (trim(MST_CLIENT. branch_code)  = P_BRANCH_CD
        OR P_BRANCH_CD                      = '%')
      )
      m
    WHERE x.client_cd = m.client_cd;
  --  ORDER BY 1, 2,3;
    
  EXCEPTION
  WHEN NO_DATA_FOUND THEN
    V_ERR_CD  := -100;
    V_ERR_MSG :='NO DATA FOUND';
    RAISE V_ERR;
  WHEN OTHERS THEN
    V_ERR_CD  := -3;
    V_ERR_MSG :=SUBSTR('INSERT INTO R_ARAP_AGING_MKBD '|| SQLERRM(SQLCODE),1,200);
    RAISE V_ERR;
  END;
  P_RANDOM_VALUE := V_RANDOM_VALUE;
  P_ERRCD        := 1;
  P_ERRMSG       := '';
EXCEPTION
WHEN V_ERR THEN
  ROLLBACK;
  P_ERRCD  := V_ERR_CD;
  P_ERRMSG := V_ERR_MSG;
WHEN OTHERS THEN
  ROLLBACK;
  P_ERRCD  := -1;
  P_ERRMSG := SUBSTR(SQLERRM(SQLCODE),1,200);
END SPR_ARAP_AGING_MKBD;