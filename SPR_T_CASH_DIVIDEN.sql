create or replace PROCEDURE Spr_T_Cash_Dividen(
    p_cum_dt IPNEXTG.T_CORP_ACT.cum_dt%TYPE,
    P_DISTRIB_DT IPNEXTG.T_CORP_ACT.DISTRIB_DT%TYPE,
    P_RECORDING_DT IPNEXTG.T_CORP_ACT.RECORDING_DT%TYPE,
    P_STK_CD IPNEXTG.T_SECU_BAL.STK_CD%TYPE,
    P_PEMBAGI NUMBER,
    P_PENGALI NUMBER,
    P_PRICE   NUMBER,
    P_END_BRANCH IPNEXTG.MST_BRANCH.BRCH_CD%TYPE,
    P_BGN_BRANCH IPNEXTG.MST_BRANCH.BRCH_CD%TYPE,
    P_BGN_CLIENT IPNEXTG.MST_CLIENT.CLIENT_CD%TYPE,
    P_END_CLIENT IPNEXTG.MST_CLIENT.CLIENT_CD%TYPE,
    P_RATE          NUMBER,
    P_BGN_DT        DATE,
    P_USER_ID       VARCHAR2,
    P_RVPV_NUMBER   VARCHAR2,
    p_generate_date DATE,
    vo_random_value OUT NUMBER,
    vo_errcd OUT NUMBER,
    vo_errmsg OUT VARCHAR2 )
IS
  vl_random_value NUMBER(10);
  vl_err          EXCEPTION;
  v_bgn_dt        DATE;
BEGIN
  Vl_Random_Value := ABS(Dbms_Random.Random);
  /*
  BEGIN
  Sp_Rpt_Remove_Rand('R_T_CASH_DIVIDEN',vl_random_value,vo_errcd,vo_errmsg);
  EXCEPTION
  WHEN OTHERS THEN
  vo_errcd := -2;
  vo_errmsg := SQLERRM(SQLCODE);
  RAISE vl_err;
  END;
  */
  
  BEGIN
    DELETE FROM R_T_CASH_DIVIDEN WHERE STK_CD=P_STK_CD AND USER_ID=P_USER_ID;
  EXCEPTION
  WHEN OTHERS THEN
    Vo_Errcd  := -2;
    Vo_Errmsg := 'DELETE OLD STOCK FROM R_T_CASH_DIVIDEN'|| SQLERRM(SQLCODE);
    RAISE vl_err;
  END;
  
  BEGIN
    SELECT MAX(BAL_DT)
    INTO v_bgn_dt
    FROM IPNEXTG.t_secu_bal
    WHERE bal_dt <= p_recording_dt;
  EXCEPTION
  WHEN OTHERS THEN
    vo_errcd  := -3;
    vo_errmsg := SQLERRM(SQLCODE);
    RAISE vl_err;
  END;
  
  BEGIN
    INSERT
    INTO R_T_CASH_DIVIDEN
      (
        CA_TYPE,STK_CD,CUM_DT,DISTRIB_DT,RECORDING_DT, CLIENT_CD,QTY,RATE,GROSS_AMT,TAX_PCN, TAX_AMT,DIV_AMT,selisih,BRANCH_CODE,REM_CD, REM_NAME,
        CLIENT_NAME,CLIENT_TYPE_1,CLIENT_TYPE_2,CLIENT_TYPE_3, RVPV_NUMBER,ONH,RECOV_CHARGE_FLG,FLG,RAND_VALUE, GENERATE_DATE,USER_ID,CUM_QTY,
        SELISIH_QTY,SELISIH_AMT,NO_RDI
      )
      (
        SELECT 'CASHDIV', stk_cd, p_cum_dt,P_DISTRIB_DT,P_recording_dt, Z.client_cd, qty, P_RATE, DECODE(P_PENGALI,0,gross,CASH_DIVIDEN)GROSS, tax_pcn,
          --ROUND(tax_pcn * gross,2) tax,
          CASE
            WHEN ROUNDING='CEIL'
            THEN CEIL(tax_pcn * gross)
            WHEN ROUNDING='ROUND'
            THEN ROUND(tax_pcn * gross,NVL(ROUND_POINT,0))
            ELSE FLOOR(tax_pcn * gross)
          END TAX,
          --ROUND(cash_dividen -  ROUND(tax_pcn * gross,2),2) deviden,
          CASE
            WHEN ROUNDING='CEIL'
            THEN CEIL(cash_dividen - CEIL(tax_pcn * gross))
            WHEN ROUNDING='ROUND'
            THEN ROUND(cash_dividen- ROUND(tax_pcn * gross,NVL(ROUND_POINT,0)),NVL(ROUND_POINT,0))
            ELSE FLOOR(cash_dividen  - FLOOR(tax_pcn * gross))
          END deviden, selisih, branch_code, rem_cd, rem_name, client_name,client_type_1,client_type_2,client_type_3, P_RVPV_NUMBER,onh, 
          NVL(recov_charge_flg,'N') recov_charge_flg, 'Y' flg, vl_random_value, p_generate_date, P_user_id,cum_QTY,NVL(DECODE(ONH,0,0,(ONH-CUM_QTY)),0),NULL, DECODE(X.ACCT_STAT,'A','Y','I','Y','N')
        FROM
          (
            SELECT m.branch_code, m.rem_cd, s.rem_name, m.client_type_3, b.client_cd, m.client_name, b.stk_cd, b.cum_qty, b.qty, 
            DECODE(P_PENGALI,0,0,(b.qty * P_PENGALI / P_PEMBAGI)) div_stk, (b.qty * P_RATE + DECODE(P_PENGALI,0,0,TRUNC(b.qty * P_PENGALI / P_PEMBAGI,0)) * P_PRICE ) gross, p.tax_pcn, b.qty * P_RATE AS cash_dividen, selisih, m.client_type_2, m.client_type_1, NVL(m.recov_charge_flg,'N') recov_charge_flg,ONH, A.ROUNDING,A.ROUND_POINT
            FROM
              (
                SELECT client_cd, stk_cd, cum_QTY,ONH, QTY,SELISIH
                FROM--14JUL2016
                  (
                    SELECT client_cd, stk_cd, SUM(qty) cum_QTY, SUM(onh) onh, DECODE(SIGN(TRUNC(SYSDATE) - p_recording_dt),1,SUM(onh),SUM(qty)) qty, 
                    DECODE(SIGN(TRUNC(SYSDATE) - p_recording_dt),1,SUM(onh) - SUM(qty),0) selisih
                    FROM
                      (
                        SELECT client_cd, stk_cd, beg_bal_qty AS qty, beg_on_hand AS onh
                        FROM ipnextg.T_STKBAL
                        WHERE bal_dt = v_bgn_dt
                        AND stk_cd   = P_STK_CD
                        UNION ALL
                        SELECT client_Cd, stk_cd, DECODE(db_cr_flg,'D',1,-1) * (total_share_qty + withdrawn_share_qty) mvmt, 0 onh
                        FROM ipnextg.T_STK_MOVEMENT
                        WHERE doc_dt BETWEEN v_bgn_dt AND P_cum_dt
                        AND SUBSTR(doc_num,5,2) IN ('RS','WS','JR','BR','JI','BI')
                        AND gl_acct_cd          IS NOT NULL
                        AND trim(gl_acct_cd)    IN ('10','12','13','14','51')
                        AND s_d_type            <> 'B'
                        AND doc_stat             = '2'
                        AND stk_cd               = P_STK_CD
                        UNION ALL
                        SELECT client_Cd, stk_cd, 0 , DECODE(db_cr_flg,'D',-1,1) * (total_share_qty + withdrawn_share_qty) onh
                        FROM ipnextg.T_STK_MOVEMENT
                        WHERE doc_dt BETWEEN v_bgn_dt AND p_recording_dt
                        AND p_recording_dt    < TRUNC(SYSDATE)
                        AND gl_acct_cd       IS NOT NULL
                        AND trim(gl_acct_cd) IN ('36')
                        AND doc_stat          = '2'
                        AND stk_cd            = P_STK_CD
                      )
                    GROUP BY client_cd, stk_cd
                      --HAVING SUM( qty) > 0 and  SUM(onh)  >  0
                  )
                WHERE QTY>0
                AND ONH  >0
              )
              b, (
                SELECT client_cd, TO_NUMBER(tax_rate) / 100 tax_pcn
                FROM
                  (
                    SELECT m.client_cd, DECODE(a.rate_over25persen,NULL, DECODE(m.rate_no,2,r.rate_2,1,r.rate_1,0), a.rate_over25persen) tax_rate
                    FROM
                      (
                        SELECT client_cd, NVL(mst_cif.biz_type, mst_client.biz_type) biz_type, NVL(mst_cif.npwP_no, mst_client.npwp_no) npwp_no,
                        DECODE(client_cd,trim(other_1),'H',NVL(mst_cif.client_type_1,mst_client.client_type_1)) AS client_type_1, 
                        NVL(mst_cif.client_type_2,mst_client.client_type_2)client_type_2, 
                        DECODE(NVL(mst_cif.npwP_no, mst_client.npwp_no),NULL,2,1) * DECODE(NVL(mst_cif.biz_type, mst_client.biz_type),'PF',0,'FD',0,1) rate_no
                        FROM ipnextg.MST_CLIENT, ipnextg.mst_company, ipnextg.mst_Cif
                        WHERE mst_client.cifs                                    = mst_cif.cifs(+)
                        AND NVL(mst_cif.client_type_1,mst_client.client_type_1) <> 'B'
                      )
                      m, (
                        SELECT client_cd, rate_1 AS rate_over25persen
                        FROM ipnextg.MST_TAX_RATE
                        WHERE p_recording_dt BETWEEN BEGIN_DT AND end_dt
                        AND tax_type     = 'DIVTAX'
                        AND client_cd   IS NOT NULL
                        AND stk_cd      IS NOT NULL
                        AND STK_CD       = P_STK_CD
                        AND APPROVED_STAT='A'
                      )
                      a, (
                        SELECT *
                        FROM ipnextg.MST_TAX_RATE
                        WHERE p_recording_dt BETWEEN BEGIN_DT AND end_dt
                        AND tax_type     = 'DIVTAX'
                        AND client_cd   IS NULL
                        AND STK_CD      IS NULL
                        AND APPROVED_STAT='A'
                      )
                      r
                    WHERE m.client_type_2 LIKE r.client_type_2
                    AND m.client_type_1 LIKE r.client_type_1
                    AND m.client_cd = a.client_cd (+)
                  )
              )
              p, ipnextg.MST_CLIENT m, ipnextg.MST_SALES s, (SELECT STK_CD,CUM_DT,RECORDING_DT,DISTRIB_DT,ROUNDING,ROUND_POINT FROM T_CORP_ACT WHERE CA_TYPE='CASHDIV' AND APPROVED_STAT='A') A
            WHERE b.client_cd   = p.client_cd (+)
            AND B.CLIENT_CD     = M.CLIENT_CD
            AND M.CUSTODIAN_CD IS NULL--13MAY2016
            AND trim(m.branch_code) BETWEEN P_BGN_BRANCH AND P_END_BRANCH
            AND m.client_cd BETWEEN P_BGN_CLIENT AND P_END_CLIENT
            AND TRIM(m.rem_cd) = TRIM(s.rem_cd)
            AND b.onh          > 0
            AND A.CUM_DT       = P_CUM_DT
            AND A.RECORDING_DT = P_RECORDING_DT
            AND A.DISTRIB_DT   =P_DISTRIB_DT
            AND A.STK_CD       =P_STK_CD
            AND A.STK_CD       =B.STK_CD
          )
          Z ,( SELECT CLIENT_CD, ACCT_STAT FROM MST_CLIENT_FLACCT WHERE APPROVED_STAT='A' AND ACCT_STAT <> 'C')X
        WHERE Z.CLIENT_CD = X.CLIENT_CD(+)
      );
  EXCEPTION
  WHEN OTHERS THEN
    vo_errcd  := -4;
    vo_errmsg := SQLERRM(SQLCODE);
    RAISE vl_err;
  END;
  
  vo_random_value := vl_random_value;
  vo_errcd        := 1;
  vo_errmsg       := '';
  COMMIT;
  
EXCEPTION
WHEN vl_err THEN
  ROLLBACK;
  vo_random_value := 0;
  vo_errmsg       := SUBSTR(vo_errmsg,1,200);
WHEN OTHERS THEN
  ROLLBACK;
  vo_random_value := 0;
  vo_errcd        := -1;
  VO_ERRMSG       := SUBSTR(SQLERRM(SQLCODE),1,200);
END Spr_T_Cash_Dividen;