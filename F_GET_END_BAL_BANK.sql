create or replace FUNCTION F_GET_END_BAL_BANK(P_DATE DATE) RETURN NUMBER AS


/*
PARAM P_TYPE IN=AKTUAL DANA MASUK, OUT=AKTUAL DANA KELUAR
*/
V_AMT NUMBER;
V_BGN_BAL_DATE DATE;
BEGIN


  V_BGN_BAL_DATE :=P_DATE-TO_CHAR(P_DATE,'DD')+1;

    SELECT SUM(NVL(beg_bal, 0))  INTO V_AMT
           FROM
            ( SELECT SUM(NVL(b.deb_obal, 0) - NVL(b.cre_obal, 0)) BEG_BAL
                FROM t_day_trs b
                WHERE b.trs_dt           = V_BGN_BAL_DATE
                AND trim(b.gl_acct_cd) = '1200'
              UNION ALL
              SELECT     DECODE(d.db_cr_flg, 'D', 1, - 1) * NVL(d.curr_val, 0) MVMT_AMT
                FROM t_account_ledger d
                WHERE d.doc_date BETWEEN V_BGN_BAL_DATE AND P_DATE
                AND trim(d.gl_acct_cd) = '1200'
                AND d.approved_sts     = 'A'
            ) ;

RETURN V_AMT;

END F_GET_END_BAL_BANK;