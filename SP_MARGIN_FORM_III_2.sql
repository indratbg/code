create or replace 
PROCEDURE SP_MARGIN_FORM_III_2(
    P_END_DATE DATE,
    P_UPDATE_DATE T_MANY_HEADER.UPDATE_DATE%TYPE,
    P_UPDATE_SEQ T_MANY_HEADER.UPDATE_SEQ%TYPE,
    P_USER_ID T_MANY_HEADER.USER_ID%TYPE,
    P_IP_ADDRESS T_MANY_HEADER.IP_ADDRESS%TYPE,
    P_ERROR_CD OUT NUMBER,
    P_ERROR_MSG OUT VARCHAR2 )
AS
  V_ERR       EXCEPTION;
  V_ERROR_CD  NUMBER(5);
  V_ERROR_MSG VARCHAR2(200);
  V_CRE_DT    DATE:=SYSDATE;
  V_BGN_DATE  DATE;
  V_BROKER_CD VARCHAR2(2);
  V_NAMA_PRSH mst_company.nama_prsh%TYPE;
    ---perubahan change ticker code---
BEGIN


BEGIN
  select nama_prsh, substr(broker_cd,1,2)kode_ab INTO V_NAMA_PRSH, V_BROKER_CD from v_broker_subrek a, mst_company;
EXCEPTION
  WHEN OTHERS THEN
    V_ERROR_CD  :=-5;
    V_ERROR_MSG := SUBSTR('INSERT INTO LAP_MARGIN_FORM_III_I_1 '||SQLERRM(SQLCODE),1,200);
    RAISE V_ERR;
  END;


  V_BGN_DATE := TO_DATE('01'||TO_CHAR(P_END_DATE,'MMYYYY'),'DDMMYYYY');
  
  BEGIN
    INSERT
    INTO LAP_MARGIN_FORM_III_I_2
      (
        UPDATE_DATE ,
        UPDATE_SEQ ,
        REPORT_DATE ,
        STK_CD ,
        STK_VALUE ,
        STK_PERC ,
        CNT_MARGIN,
        CRE_DT ,
        USER_ID ,
        APPROVED_STAT ,
        APPROVED_BY ,
        APPROVED_DT,
        nama_prsh,
        kode_ab
      )
    SELECT P_UPDATE_DATE,
      P_UPDATE_SEQ,
      P_END_DATE,
      b1.stk_cd,
      b1.stk_value,
      B1.STK_VALUE / B1.TOT_VALUE * 100 AS STK_PERC,
      b1.cnt_margin ,
      V_CRE_DT,
      P_USER_ID,
      'E',
      NULL,
      NULL,
      V_NAMA_PRSH,
      V_BROKER_CD
    FROM
      (SELECT b.stk_cd,
        b.onh_qty,
        p.price     * b.onh_qty AS stk_value,
        SUM(p.price * b.onh_qty) over ( ) tot_value,
        b.cnt_margin
      FROM
        (SELECT stk_cd,
          SUM(onh_qty) onh_qty,
          COUNT(client_cd) cnt_margin
        FROM
          (SELECT a.stk_cd,
            a.client_cd,
            SUM(a.onh_qty) onh_qty
          FROM
            (SELECT client_cd,
              nvl(c.stk_cd_new,stk_cd)stk_cd,
              NVL(DECODE(trim(NVL(gl_acct_cd,'36')),'36',1,0) * DECODE(db_cr_flg,'D',-1,1) * (total_share_qty + withdrawn_share_qty),0) onh_qty
            FROM T_STK_MOVEMENT,
			(select stk_cd_old,stk_cd_new from t_change_stk_cd where eff_dt<=P_END_DATE)c
            WHERE doc_dt BETWEEN V_BGN_DATE AND P_END_DATE
			AND stk_Cd = c.stk_cd_old(+)
            AND gl_acct_cd ='36'
            AND doc_stat   = '2'
            UNION ALL
            SELECT client_cd,
               nvl(c.stk_cd_new,stk_cd)stk_cd,
              qty
            FROM T_SECU_BAL,
			(select stk_cd_old,stk_cd_new from t_change_stk_cd where eff_dt<=P_END_DATE)c
            WHERE bal_dt   = V_BGN_DATE
			AND stk_Cd = c.stk_cd_old(+)
            AND gl_acct_cd ='36'
            ) a,
            (SELECT n.client_cd,
              SUM(n.beg_bal + n.mvmt ) end_bal
            FROM
              (SELECT TRIM(MST_CLIENT.client_cd) client_cd,
                0 beg_bal,
                DECODE(T_ACCOUNT_LEDGER.db_cr_flg, 'D', 1, -1) * NVL(T_ACCOUNT_LEDGER.curr_val, 0) mvmt
              FROM MST_CLIENT,
                T_ACCOUNT_LEDGER,
                ( SELECT gl_a FROM MST_GLA_TRX WHERE JUR_TYPE = 'T3'
                ) v
              WHERE T_ACCOUNT_LEDGER.sl_acct_cd = MST_CLIENT.client_cd
              AND T_ACCOUNT_LEDGER.doc_date BETWEEN V_BGN_DATE AND P_END_DATE
              AND T_ACCOUNT_LEDGER.approved_sts = 'A'
              AND T_ACCOUNT_LEDGER.gl_acct_cd   = v.gl_a
              UNION ALL
              SELECT TRIM(MST_CLIENT.client_cd),
                (NVL(T_DAY_TRS.deb_obal, 0) - NVL(T_DAY_TRS.cre_obal, 0)) beg_bal,
                0 mvmt
              FROM MST_CLIENT,
                T_DAY_TRS,
                ( SELECT gl_a FROM MST_GLA_TRX WHERE JUR_TYPE = 'T3'
                ) v
              WHERE T_DAY_TRS.sl_acct_cd = MST_CLIENT.client_cd
              AND T_DAY_TRS.gl_acct_cd   = v.gl_a
              AND T_DAY_TRS.trs_dt       = TRUNC(V_BGN_DATE)
              ) n,
              MST_CLIENT m,
              LST_TYPE3
            WHERE m.client_cd       = n.client_cd
            AND m.client_type_3     = LST_TYPE3.cl_type3
            AND m.client_type_1    <> 'B'
            AND LST_TYPE3.margin_cd = 'M'
            GROUP BY n.client_cd
            HAVING SUM(beg_bal + mvmt ) > 0
            ) bal
          WHERE a.client_cd = bal.client_cd
          GROUP BY a.stk_cd,
            a.client_cd
          )
        WHERE onh_qty <> 0
        GROUP BY stk_cd
        ) b,
        (SELECT stk_cd,
          stk_clos AS price
        FROM T_CLOSE_PRICE
        WHERE stk_date = P_END_DATE
        ) p
      WHERE b.stk_cd = p.stk_cd
      AND b.onh_qty <> 0
      ) b1 ;
  EXCEPTION
  WHEN OTHERS THEN
    V_ERROR_CD  :=-10;
    V_ERROR_MSG := SUBSTR('INSERT INTO LAP_MARGIN_FORM_III_I_2 '||SQLERRM(SQLCODE),1,200);
    RAISE V_ERR;
  END;
  
  P_ERROR_CD  := 1 ;
  P_ERROR_MSG := '';
  
EXCEPTION
WHEN V_ERR THEN
  ROLLBACK;
  P_ERROR_MSG := V_ERROR_MSG;
  P_ERROR_CD  := V_ERROR_CD;
WHEN OTHERS THEN
  P_ERROR_CD  := -1 ;
  P_ERROR_MSG := SUBSTR(SQLERRM(SQLCODE),1,200);
  RAISE;
END SP_MARGIN_FORM_III_2;