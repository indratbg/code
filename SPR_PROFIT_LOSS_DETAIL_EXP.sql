create or replace PROCEDURE SPR_PROFIT_LOSS_DETAIL_EXP(
    P_BGN_DATE      DATE,
    P_END_DATE      DATE,
    P_BGN_MON NUMBER,
    P_END_MON NUMBER,
    P_USER_ID       VARCHAR2,
    P_GENERATE_DATE DATE,
    P_RANDOM_VALUE OUT NUMBER,
    P_ERROR_CODE OUT NUMBER,
    P_ERROR_MSG OUT VARCHAR2)
IS
  v_random_value NUMBER(10) ;
  v_err          EXCEPTION;
  v_error_cd     NUMBER(5) ;
  v_error_msg    VARCHAR2(200) ;
BEGIN
  v_random_value := ABS(dbms_random.random) ;
  BEGIN
    SP_RPT_REMOVE_RAND('R_PROFIT_LOSS_DETAIL_EXP', V_RANDOM_VALUE, v_error_cd, v_error_msg) ;
  EXCEPTION
  WHEN OTHERS THEN
    v_error_cd  := - 2;
    v_error_msg := SUBSTR('SP_RPT_REMOVE_RAND '||SQLERRM(SQLCODE),1,200) ;
    RAISE V_err;
  END;
  
  IF v_error_cd  <0 THEN
    v_error_cd  := - 5;
    v_error_msg := SUBSTR('SP_RPT_REMOVE_RAND '||v_error_msg,1,200) ;
    RAISE V_err;
  END IF;
  
  BEGIN
    INSERT
    INTO R_PROFIT_LOSS_DETAIL_EXP
      (
        SORTK ,BRCH_NAME ,GL_ACCT_CD ,GL_ACCT_NAME ,SL_ACCT_CD ,SL_ACCT_NAME ,MON01 ,MON02 ,MON03 ,MON04 ,MON05 ,MON06 
        ,MON07 ,MON08 ,MON09 ,MON10 ,MON11 ,MON12 ,LINE_TOTAL ,USER_ID ,RAND_VALUE ,GENERATE_DATE ,BGN_DATE ,END_DATE,
        BGN_MON, END_MON
      )
    SELECT a.gl_acct_Cd||acct_brch||a.sl_acct_cd AS sortk, brch_name, a.gl_acct_Cd AS gl_acct_cd,
    UPPER(DECODE(trim(a.gl_acct_cd),'5200','BIAYA PENJUALAN','5300','BIAYA Administrasi dan Umum')) gl_acct_name,
    TRIM(a.sl_acct_cd) AS sl_acct_cd, v.acct_name AS sl_acct_name, 
    ROUND(NVL(A.mon01, 0), 0) AS MON01, 
    ROUND(NVL(A.mon02, 0), 0) AS MON02,
    ROUND(NVL(A.mon03, 0), 0) AS MON03,
    ROUND(NVL(A.mon04, 0), 0) AS MON04,
    ROUND(NVL(A.mon05, 0), 0) AS MON05, 
    ROUND(NVL(A.mon06, 0), 0) AS MON06,
    ROUND(NVL(A.mon07, 0), 0) AS MON07,
    ROUND(NVL(A.mon08, 0), 0) AS MON08,
    ROUND(NVL(A.mon09, 0), 0) AS MON09,
    ROUND(NVL(A.mon10, 0), 0) AS MON10, 
    ROUND(NVL(A.mon11, 0), 0) AS MON11,
    ROUND(NVL(A.mon12, 0), 0) AS MON12,
    0 LINE_TOTAL, P_USER_ID, V_RANDOM_VALUE, P_GENERATE_DATE, P_BGN_DATE, P_END_DATE, P_BGN_MON, P_END_MON
    FROM
      (
        SELECT TRIM(t_account_ledger.gl_acct_cd) gl_acct_CD, t_account_ledger.sl_acct_cd, 
        SUBSTR(t_account_ledger.sl_acct_cd,1,2) acct_brch, 
        SUM(DECODE(TO_CHAR(t_account_ledger.doc_date,'MM'), '01',1,0) * DECODE(t_account_ledger.db_cr_flg, 'D', 1, -1) * NVL(t_account_ledger.curr_val, 0)) AS Mon01, 
        SUM(DECODE(TO_CHAR(t_account_ledger.doc_date,'MM'), '02',1,0) * DECODE(t_account_ledger.db_cr_flg, 'D', 1, -1) * NVL(t_account_ledger.curr_val, 0)) AS Mon02, 
        SUM(DECODE(TO_CHAR(t_account_ledger.doc_date,'MM'), '03',1,0) * DECODE(t_account_ledger.db_cr_flg, 'D', 1, -1) * NVL(t_account_ledger.curr_val, 0)) AS Mon03, 
        SUM(DECODE(TO_CHAR(t_account_ledger.doc_date,'MM'), '04',1,0) * DECODE(t_account_ledger.db_cr_flg, 'D', 1, -1) * NVL(t_account_ledger.curr_val, 0)) AS Mon04, 
        SUM(DECODE(TO_CHAR(t_account_ledger.doc_date,'MM'), '05',1,0) * DECODE(t_account_ledger.db_cr_flg, 'D', 1, -1) * NVL(t_account_ledger.curr_val, 0)) AS Mon05, 
        SUM(DECODE(TO_CHAR(t_account_ledger.doc_date,'MM'), '06',1,0) * DECODE(t_account_ledger.db_cr_flg, 'D', 1, -1) * NVL(t_account_ledger.curr_val, 0)) AS Mon06, 
        SUM(DECODE(TO_CHAR(t_account_ledger.doc_date,'MM'), '07',1,0) * DECODE(t_account_ledger.db_cr_flg, 'D', 1, -1) * NVL(t_account_ledger.curr_val, 0)) AS Mon07, 
        SUM(DECODE(TO_CHAR(t_account_ledger.doc_date,'MM'), '08',1,0) * DECODE(t_account_ledger.db_cr_flg, 'D', 1, -1) * NVL(t_account_ledger.curr_val, 0)) AS Mon08, 
        SUM(DECODE(TO_CHAR(t_account_ledger.doc_date,'MM'), '09',1,0) * DECODE(t_account_ledger.db_cr_flg, 'D', 1, -1) * NVL(t_account_ledger.curr_val, 0)) AS Mon09, 
        SUM(DECODE(TO_CHAR(t_account_ledger.doc_date,'MM'), '10',1,0) * DECODE(t_account_ledger.db_cr_flg, 'D', 1, -1) * NVL(t_account_ledger.curr_val, 0)) AS Mon10, 
        SUM(DECODE(TO_CHAR(t_account_ledger.doc_date,'MM'), '11',1,0) * DECODE(t_account_ledger.db_cr_flg, 'D', 1, -1) * NVL(t_account_ledger.curr_val, 0)) AS Mon11, 
        SUM(DECODE(TO_CHAR(t_account_ledger.doc_date,'MM'), '12',1,0) * DECODE(t_account_ledger.db_cr_flg, 'D', 1, -1) * NVL(t_account_ledger.curr_val, 0)) AS Mon12
        FROM t_account_ledger
        WHERE t_account_ledger.doc_date BETWEEN P_BGN_DATE AND P_END_DATE
        AND (t_account_ledger.approved_sts     = 'A')
      --  AND reversal_jur                       = 'N'--13 OCT2017, SUPAYA JURNAL REVERSAL MUNCUL SEBAGAI PEMBALIK JURNAL YANG DICANCEL/UPDATE
        --AND RECORD_SOURCE<>'RE'--13 OCT2017
        AND trim(T_ACCOUNT_LEDGER.gl_acct_cd) IN ('5200','5300')
        AND sl_acct_cd NOT LIKE '90%'
        GROUP BY t_account_ledger.gl_acct_cd, T_ACCOUNT_LEDGER.sl_acct_cd
      )
      A, (
        SELECT gl_a, sl_a, acct_name, brch_name
        FROM mst_gl_account m, mst_branch b
        WHERE gl_a LIKE '5%'
        AND SUBSTR(sl_a,1,2) = b.acct_prefix
      )
      v
    WHERE trim(A.gl_acct_cd) = trim(v.gl_a)
    AND a.sl_acct_cd         = v.sl_A
    AND (a.mon01            <> 0
    OR a.mon02              <> 0
    OR a.mon03              <> 0
    OR a.mon04              <> 0
    OR a.mon05              <> 0
    OR a.mon06              <> 0
    OR a.mon07              <> 0
    OR a.mon08              <> 0
    OR a.mon09              <> 0
    OR a.mon10              <> 0
    OR a.mon11              <> 0
    OR a.mon12              <> 0)
    ORDER BY 1 ASC;
  EXCEPTION
  WHEN OTHERS THEN
    v_error_cd  := - 10;
    v_error_msg := SUBSTR('INSERT INTO R_PROFIT_LOSS_DETAIL_EXP '||SQLERRM(SQLCODE),1,200) ;
    RAISE V_err;
  END;
  
  --UPDATE R_PROFIT_LOSS_DETAIL_EXP KOLOM LINE_TOTAL
  BEGIN
    UPDATE R_PROFIT_LOSS_DETAIL_EXP
    SET LINE_TOTAL  =MON01+ MON02+ MON03+ MON04+ MON05+ MON06+ MON07+ MON08+ MON09+ MON10+ MON11+ MON12
    WHERE RAND_VALUE=V_RANDOM_VALUE
    AND USER_ID     =P_USER_ID;
  EXCEPTION
  WHEN OTHERS THEN
    v_error_cd  := - 10;
    v_error_msg := SUBSTR('UPDATE LINE TOTAL R_PROFIT_LOSS_DETAIL_EXP '||SQLERRM(SQLCODE),1,200) ;
    RAISE V_err;
  END;
  
  p_random_value := v_random_value;
  P_ERROR_CODE        := 1;
  P_ERROR_MSG       := '';
  
EXCEPTION
WHEN V_err THEN
  ROLLBACK;
  P_ERROR_CODE := v_error_cd;
  P_ERROR_MSG  := v_error_msg;
WHEN OTHERS THEN
  ROLLBACK;
  P_ERROR_CODE := - 1;
  P_ERROR_MSG  := SUBSTR(SQLERRM(SQLCODE), 1, 200) ;
END SPR_PROFIT_LOSS_DETAIL_EXP;