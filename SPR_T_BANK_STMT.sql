CREATE OR REPLACE
PROCEDURE SPR_T_BANK_STMT(
    period_from     DATE,
    period_to       DATE,
    p_gl_acct       VARCHAR2,
    p_sl_acct       VARCHAR2,
    s_option        VARCHAR2,
    P_USER_ID       VARCHAR2,
    P_GENERATE_DATE DATE,
    P_RANDOM_VALUE OUT NUMBER,
    P_ERRCD OUT NUMBER,
    P_ERRMSG OUT VARCHAR2 )
IS
  v_random_value NUMBER(10);
  v_err          EXCEPTION;
  v_err_cd       NUMBER(10);
  v_err_msg      VARCHAR2(200);
  --v_begin_date date;
  
   V_period_from     DATE :=period_from;
    V_period_to       DATE :=period_to;
    V_p_gl_acct       VARCHAR2(10) := p_gl_acct;
    V_p_sl_acct       VARCHAR2(10) :=p_sl_acct;
    V_s_option        VARCHAR2(10) :=s_option;
  
  
BEGIN

  v_random_value := ABS(dbms_random.random);
  
  BEGIN
    SP_RPT_REMOVE_RAND('R_T_BANK_STMT',V_RANDOM_VALUE,v_err_cd,v_err_msg);
  EXCEPTION
  WHEN OTHERS THEN
    v_err_cd  := -2;
    v_err_msg := SUBSTR('SP_RPT_REMOVE_RAND'||v_err_msg,1,200);
    RAISE V_err;
  END;
  --  v_begin_date :=  p_stmt_date  - TO_CHAR(p_stmt_date ,'dd') + 1;
  
  BEGIN
    --INSERT KE TABLE REPORT
    INSERT
    INTO R_T_BANK_STMT
      (
        TRX_DATE,
        AMOUNT,
        DC,
        B_CRE,
        B_DEB,
        IP_DEB,
        IP_CRE,
        SUM_B,
        SUM_IP,
        NET_B,
        NET_IP,
        SUM_NET_B,
        SUM_NET_IP,
        DESCRIP,
        USER_ID,
        RAND_VALUE,
        GENERATE_DATE
      )
    SELECT trx_date,
      amount,
      dc,
      b_cre,
      b_deb,
      ip_deb,
      ip_cre ,
      sum_b,
      sum_ip,
      net_b,
      net_ip ,
      sum_net_b,
      sum_net_ip,
      DECODE((b_cre+b_deb),0,ledger_nar, description) descrip,
      P_USER_ID,
      V_RANDOM_VALUE,
      P_GENERATE_DATE
    FROM
      (SELECT trx_date,
        amount,
        dc,
        b_cre,
        b_deb,
        ip_deb,
        ip_cre ,
        sum_b,
        sum_ip,
        net_b,
        net_ip ,
        sum_net_b,
        sum_net_ip
      FROM
        (SELECT trx_date,
          amount,
          dc,
          b_cre,
          b_deb,
          ip_deb,
          ip_cre,
          SUM( b_deb  + b_cre) over ( PARTITION BY trx_date, dc ) sum_b,
          SUM( ip_deb + ip_cre) over ( PARTITION BY trx_date, dc ) sum_ip,
          SUM(        -b_deb + b_cre) over ( PARTITION BY trx_date ) net_b,
          SUM( ip_deb - ip_cre) over ( PARTITION BY trx_date ) net_ip,
          SUM(        -b_deb + b_cre) over ( ) sum_net_b,
          SUM( ip_deb - ip_cre) over ( ) sum_net_ip
        FROM
          (SELECT trx_date,
            amount,
            dc,
            SUM(b_cre) b_cre,
            SUM(b_deb) b_deb,
            SUM(ip_deb) ip_deb,
            SUM(ip_cre) ip_cre
          FROM
            (SELECT trx_date,
              amount,
              DECODE(db_cr_flg,'DB','C','D') dc,
              DECODE(db_cr_flg,'CR',amount,0) b_cre,
              DECODE(db_cr_flg,'DB',amount,0) b_deb,
              0 ip_deb,
              0 ip_cre
            FROM T_BANK_STMT
            WHERE trx_date BETWEEN V_period_from AND V_period_to
            AND trim(gl_acct_cd) = V_p_gl_acct
            AND sl_acct_cd       = V_p_sl_acct
            UNION ALL
            SELECT doc_date,
              curr_val ip_amt,
              db_cr_flg,
              0 b_cred,
              0 b_deb,
              DECODE(db_cr_flg,'D', curr_val, 0) ip_deb,
              DECODE(db_cr_flg,'C', curr_val, 0) ip_cre
            FROM T_ACCOUNT_LEDGER
            WHERE doc_date BETWEEN V_period_from AND V_period_to
            AND trim(gl_acct_cd) = V_p_gl_acct
            AND sl_acct_cd       = V_p_sl_acct
            AND approved_sts     = 'A'
            )
          GROUP BY trx_date,
            amount,
            dc
          HAVING (SUM(b_cre + b_deb) <> SUM(ip_deb + ip_cre )
          AND V_s_option                = 'DIFF')
          OR V_s_option                 = 'ALL'
          )
        )
      WHERE (((sum_b <> sum_ip)
      AND (net_b     <> net_ip)
      AND V_s_option    = 'DIFF')
      OR V_s_option     = 'ALL')
      ) a,
      (SELECT doc_date,
        curr_Val,
        db_cr_flg,
        MAX(ledger_nar) ledger_nar,
        MAX(description) description
      FROM
        (SELECT doc_date,
          curr_val,
          db_cr_flg,
          ledger_nar ,
          NULL description
        FROM T_ACCOUNT_LEDGER
        WHERE doc_date BETWEEN V_period_from AND V_period_to
        AND trim(gl_acct_cd) = V_p_gl_acct
        AND sl_acct_cd       = V_p_sl_acct
        AND approved_sts     = 'A'
        UNION ALL
        SELECT trx_date,
          amount,
          DECODE(db_cr_flg,'DB','C','D') dc,
          NULL ledger_nar,
          description
        FROM T_BANK_STMT
        WHERE trx_date BETWEEN V_period_from AND V_period_to
        AND trim(gl_acct_cd) = V_p_gl_acct
        AND sl_acct_cd       = V_p_sl_acct
        )
      GROUP BY doc_date,
        curr_val,
        db_cr_flg
      ) b
    WHERE a.trx_date = b.doc_date
    AND a.amount     = b.curr_val
    AND a.dc         = b.db_Cr_flg
    ORDER BY trx_date;
    
  EXCEPTION
  WHEN NO_DATA_FOUND THEN
    V_ERR_CD  := -100;
    V_ERR_MSG :='NO DATA FOUND';
    RAISE V_ERR;
  WHEN OTHERS THEN
    v_err_cd  := -3;
    v_err_msg := SQLERRM(SQLCODE);
    RAISE V_err;
  END;
  
  p_random_value := v_random_value;
  p_errcd        := 1;
  p_errmsg       := '';
  
EXCEPTION
WHEN V_err THEN
  ROLLBACK;
  p_errcd  := v_err_cd;
  p_errmsg := v_err_msg;
WHEN OTHERS THEN
  ROLLBACK;
  p_errcd  := -1;
  p_errmsg := SUBSTR(SQLERRM(SQLCODE),1,200);
END SPR_T_BANK_STMT;