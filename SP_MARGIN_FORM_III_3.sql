create or replace PROCEDURE SP_MARGIN_FORM_III_3(
    P_END_DATE DATE,
    P_UPDATE_DATE T_MANY_HEADER.UPDATE_DATE%TYPE,
    P_UPDATE_SEQ T_MANY_HEADER.UPDATE_SEQ%TYPE,
    P_USER_ID T_MANY_HEADER.USER_ID%TYPE,
    P_IP_ADDRESS T_MANY_HEADER.IP_ADDRESS%TYPE,
    P_ERROR_CD OUT NUMBER,
    P_ERROR_MSG OUT VARCHAR2 )
AS

    ---perubahan change ticker code---
CURSOR CSR_UPD(A_CLIENT_CD MST_CLIENT.CLIENT_CD%TYPE) IS
SELECT client_Cd,
  ( sum_bal1)   / days1 avg_bal1,
  ( sum_bal3)   / days3 avg_bal3,
  ( sum_bal6)   / days6 avg_bal6,
  ( sum_ratio1) / days1 avg_ratio1,
  ( sum_ratio3) / days3 avg_ratio3,
  ( sum_ratio6) / days6 avg_ratio6
FROM
  (SELECT client_Cd,
    SUM(bal_1) sum_bal1,
    SUM(bal_3) sum_bal3,
    SUM(bal_6) sum_bal6,
    SUM(ratio_1) sum_ratio1,
    SUM(ratio_3) sum_ratio3,
    SUM(ratio_6) sum_ratio6
  FROM
    (SELECT doc_date,
      amt.client_Cd,
      daily_bal,
      bal_1,
      bal_3,
      bal_6,
      stk_Val_1,
      stk_Val_3,
      stk_Val_6,
      DECODE(stk_val_1, 0,0, bal_1 / stk_val_1 * 100) ratio_1,
      DECODE(stk_val_3, 0,0, bal_3 / stk_val_3 * 100) ratio_3,
      DECODE(stk_val_6, 0,0, bal_6 / stk_val_6 * 100) ratio_6
    FROM
      (SELECT client_Cd,
        doc_date,
        daily_bal,
        DECODE( SIGN(doc_date - (P_END_DATE -29)),1,1,0) * daily_bal  AS bal_1,
        DECODE( SIGN(doc_date - (P_END_DATE -89)),1,1,0) * daily_bal  AS bal_3,
        DECODE( SIGN(doc_date - (P_END_DATE -179)),1,1,0) * daily_bal AS bal_6
      FROM
        (SELECT doc_date,
          client_cd,
          DECODE(SIGN(daily_bal),-1,0, daily_bal) daily_bal,
          SUM(ABS(daily_bal)) over (PARTITION BY client_Cd ORDER BY client_Cd) AS client_bal
        FROM
          (SELECT client_cd,
            doc_date,
            SUM( amt_per_date) over (PARTITION BY client_cd ORDER BY client_cd,doc_date) daily_bal
          FROM
            (SELECT sl_acct_cd client_cd,
              doc_date,
              SUM(bal_amt) amt_per_date
            FROM
              (SELECT t.doc_date,
                t.sl_acct_cd,
                (DECODE(t.db_cr_flg, 'D', 1,-1) * t.curr_val) bal_amt
              FROM T_ACCOUNT_LEDGER t,
                MST_CLIENT,
                ( SELECT gl_a FROM MST_GLA_TRX WHERE JUR_TYPE = 'T3'
                ) v,
                (SELECT (P_END_DATE -180) - TO_NUMBER(TO_CHAR(P_END_DATE - 180,'dd')) + 1 AS dt_bgn_dt6
                FROM dual
                ) d
              WHERE t.doc_date BETWEEN d.dt_bgn_dt6 AND P_END_DATE
              AND sl_acct_cd     = A_CLIENT_CD
              AND t.approved_sts = 'A'
              AND t.gl_acct_cd   = v.gl_a
              AND t.sl_acct_cd   = client_cd
              AND client_type_3  = 'M'
              UNION ALL
              SELECT trs_dt,
                sl_acct_cd,
                (deb_obal - cre_obal) obal
              FROM T_DAY_TRS,
                MST_CLIENT,
                ( SELECT gl_a FROM MST_GLA_TRX WHERE JUR_TYPE = 'T3'
                ) v,
                (SELECT (P_END_DATE -180) - TO_NUMBER(TO_CHAR(P_END_DATE - 180,'dd')) + 1 AS dt_bgn_dt6
                FROM dual
                ) d
              WHERE trs_dt      = d.dt_bgn_dt6
              AND sl_acct_cd    = A_CLIENT_CD
              AND gl_acct_cd    = v.gl_a
              AND sl_acct_cd    = client_cd
              AND client_type_3 = 'M'
              UNION ALL
              SELECT stk_date AS daily_date,
                client_cd,
                0
              FROM
                ( SELECT DISTINCT stk_date
                FROM T_CLOSE_PRICE
                WHERE stk_date BETWEEN (P_END_DATE - 180) AND P_END_DATE
                ) a,
                MST_CLIENT
              WHERE client_type_1 = 'I'
              AND client_type_3   = 'M'
              AND client_cd       = A_CLIENT_CD
              )
            GROUP BY doc_date,
              sl_acct_cd
            )
          )
          --ORDER BY 2
        )
      WHERE client_bal > 0
      AND doc_date     > (P_END_DATE - 180)
      ) amt,
      (SELECT client_cd,
        doc_dt,
        sum_stk_val,
        DECODE( SIGN(doc_dt - (P_END_DATE -29)),1,1,0) * sum_stk_val   AS stk_val_1,
        DECODE( SIGN(doc_dt - (P_END_DATE - 89)),1,1,0) * sum_stk_val  AS stk_val_3,
        DECODE( SIGN(doc_dt - (P_END_DATE - 179)),1,1,0) * sum_stk_val AS stk_val_6
      FROM
        (SELECT client_cd,
          doc_dt,
          SUM( stk_val) sum_stk_val
        FROM
          (SELECT client_cd,
            stk.stk_cd,
            doc_dt,
            daily_qty,
            price,
            daily_qty * price AS stk_val
          FROM
            (SELECT client_cd,
              stk_cd,
              doc_dt,
              daily_qty,
              SUM(daily_qty) over (PARTITION BY client_cd, stk_cd) client_stk_qty
            FROM
              (SELECT client_cd,
                stk_cd,
                doc_dt,
                SUM(onh_qty) over (PARTITION BY client_cd, stk_cd ORDER BY client_cd, stk_cd, doc_dt) daily_qty
              FROM
                (SELECT client_cd,
                  stk_cd,
                  doc_dt,
                  SUM(onh_qty) onh_qty
                FROM
                  (SELECT T_STK_MOVEMENT.client_cd,
                    nvl(c.stk_cd_new,stk_cd)stk_cd,
                    doc_dt,
                    NVL(DECODE(trim(NVL(gl_acct_cd,'36')),'36',1,0) * DECODE(db_cr_flg,'D',-1,1) * (total_share_qty + withdrawn_share_qty),0) onh_qty
                  FROM T_STK_MOVEMENT,
                    MST_CLIENT,
                    (SELECT (P_END_DATE -180) - TO_NUMBER(TO_CHAR(P_END_DATE - 180,'dd')) + 1 AS dt_bgn_dt6
                    FROM dual
                    ) d,
          (select stk_cd_new, stk_cd_old from t_change_stk_cd where eff_dt<=P_END_DATE)c
                  WHERE doc_dt BETWEEN d.dt_bgn_dt6 AND P_END_DATE
                  AND gl_acct_cd               ='36'
                  AND doc_stat                 = '2'
                  AND T_STK_MOVEMENT.client_cd = MST_CLIENT.client_cd
                  AND stk_cd = c.stk_cd_old(+)
                  AND client_type_3            = 'M'
                  AND T_STK_MOVEMENT.client_cd = A_CLIENT_CD
                  UNION ALL
                  SELECT T_SECU_BAL.client_cd,
                       nvl(c.stk_cd_new,stk_cd)stk_cd,
                    bal_dt,
                    qty
                  FROM T_SECU_BAL,
                    MST_CLIENT,
                    (SELECT (P_END_DATE -180) - TO_NUMBER(TO_CHAR(P_END_DATE - 180,'dd')) + 1 AS dt_bgn_dt6
                    FROM dual
                    ) d,
          (select stk_cd_new, stk_cd_old from t_change_stk_cd where eff_dt<=P_END_DATE)c
                  WHERE bal_dt             = d.dt_bgn_dt6
                  AND gl_acct_cd           ='36'
                  AND T_SECU_BAL.client_cd = MST_CLIENT.client_cd
                  AND stk_cd = c.stk_cd_old(+)
                  AND client_type_3        = 'M'
                  AND T_SECU_BAL.client_cd = A_CLIENT_CD
                  UNION ALL
                  SELECT MST_CLIENT.client_cd,
                    nvl(c.stk_cd_new,stk_cd)stk_cd,
                    stk_date AS daily_date,
                    0
                  FROM
                    ( SELECT DISTINCT stk_date
                    FROM T_CLOSE_PRICE
                    WHERE stk_date BETWEEN (P_END_DATE - 180) AND P_END_DATE
                    ) a,
                    MST_CLIENT,
                    T_STKHAND,
          (select stk_cd_new, stk_cd_old from t_change_stk_cd where eff_dt<=P_END_DATE)c
                  WHERE client_type_1      = 'I'
                  AND client_type_3        = 'M'
                  AND MST_CLIENT.client_cd = A_CLIENT_CD
                  AND MST_CLIENT.client_cd = T_STKHAND.client_cd
            AND stk_cd = c.stk_cd_old(+)
                    --ORDER BY stk_cd, stk_date
                  )
                GROUP BY client_cd,
                  stk_cd,
                  doc_dt
                )
              )
              --ORDER BY 1,2, 3
            ) stk,
            ( SELECT stk_date, stk_cd, stk_clos AS price FROM T_CLOSE_PRICE
            ) p
          WHERE stk.doc_dt   = p.stk_date
          AND stk.stk_cd     = p.stk_cd
          AND client_stk_qty > 0
          )
          --ORDER BY 1,2, 3
        GROUP BY client_cd,
          doc_dt
        )
        --ORDER BY 1,2, 3
      ) porto
    WHERE amt.client_Cd = porto.client_cd
    AND amt.doc_date    = porto.doc_dt
      --ORDER BY client_cd,  doc_date
    )
  GROUP BY client_Cd
  ),
  (SELECT SUM( DECODE(SIGN(stk_date - (P_END_DATE -29)),1,1,0)) days1,
    SUM(DECODE(SIGN(stk_date        - (P_END_DATE -89)),1,1,0)) days3,
    SUM(DECODE(SIGN(stk_date        - (P_END_DATE -179)),1,1,0)) days6
  FROM
    (SELECT DISTINCT stk_date
    FROM T_CLOSE_PRICE
    WHERE stk_date BETWEEN P_END_DATE - 180 AND P_END_DATE
    )
  ) ;


CURSOR CSR_DATA IS
SELECT CLIENT_CD FROM LAP_MARGIN_FORM_III_I_3 
WHERE UPDATE_DATE = P_UPDATE_DATE
AND UPDATE_SEQ = P_UPDATE_SEQ;



  V_ERR       EXCEPTION;
  V_ERROR_CD  NUMBER(5);
  V_ERROR_MSG VARCHAR2(200);
  V_CRE_DT    DATE:=SYSDATE;
  V_BGN_DATE  DATE;
  V_BROKER_CD VARCHAR2(2);
  V_NAMA_PRSH mst_company.nama_prsh%TYPE;
  V_MARGIN_FLG VARCHAR2(1);
BEGIN




BEGIN
  select nama_prsh, substr(broker_cd,1,2)kode_ab INTO V_NAMA_PRSH, V_BROKER_CD from v_broker_subrek a, mst_company;
EXCEPTION
  WHEN OTHERS THEN
    V_ERROR_CD  :=-5;
    V_ERROR_MSG := SUBSTR('SELECT BROKER_NAME  AND BROKER CODE FROM MST_COMPANY '||SQLERRM(SQLCODE),1,200);
    RAISE V_ERR;
  END;


  BEGIN
  SELECT dflg1 INTO V_MARGIN_FLG FROM  MST_SYS_PARAM WHERE PARAM_ID='FORM_MARGIN' AND PARAM_CD1='FORM_III' AND PARAM_CD2='BAL_AMT';
  EXCEPTION
   WHEN OTHERS THEN
    V_ERROR_CD  :=-6;
    V_ERROR_MSG := SUBSTR('SELECT PARAM BAL_AMT FROM MST_SYS_PARAM '||SQLERRM(SQLCODE),1,200);
    RAISE V_ERR;
  END;


  V_BGN_DATE := TO_DATE('01'||TO_CHAR(P_END_DATE,'MMYYYY'),'DDMMYYYY');
  
  BEGIN
    INSERT
    INTO LAP_MARGIN_FORM_III_I_3
      (
        UPDATE_DATE ,
        UPDATE_SEQ ,
        REPORT_DATE ,
        CLIENT_CD ,
        CL_TYPE ,
        END_BAL ,
        PERC_BAL ,
        M_RATIO ,
        AVG_STK ,
        LESS50 ,
        LESS65 ,
        LESS80 ,
        MORE80 ,
        AVG1 ,
        AVG3 ,
        AVG6 ,
        AVG_RATIO1 ,
        AVG_RATIO3 ,
        AVG_RATIO6 ,
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
      det.client_cd,
      det.cl_type,
      det.end_bal,
      det.end_bal / sum_bal * 100 AS perc_bal,
      det.m_ratio,
      det.avg_stk,
      DECODE(SIGN(det.m_ratio - 50),1,0,det.end_bal) less50,
      DECODE(SIGN(det.m_ratio - 50),1,DECODE(SIGN(det.m_ratio - 65),1,0,det.end_bal),0) less65,
      DECODE(SIGN(det.m_ratio - 65),1,DECODE(SIGN(det.m_ratio - 80),1,0,det.end_bal),0) less80,
      DECODE(SIGN(det.m_ratio - 80),1,det.end_bal,0) more80,
      0 avg1,
      0 avg3,
      0 avg6,
      0 avg_ratio1,
      0 avg_ratio3,
      0 avg_ratio6 ,
      V_CRE_DT,
      P_USER_ID,
      'E',
      NULL,
      NULL,
      V_NAMA_PRSH,
      V_BROKER_CD
    FROM
      (SELECT amt.client_cd,
        amt.cl_type,
        ROUND(amt.end_bal,0) end_bal,
        porto.stk_sum,
        porto.stk_cnt,
        amt.end_bal       / porto.stk_sum * 100 AS m_ratio,
        ROUND(amt.end_bal / porto.stk_cnt , 0)  AS avg_stk,
        SUM(end_bal) over ( ) sum_bal
      FROM
        (SELECT n.client_cd,
          DECODE(m.client_type_1,'I','I','C','L')
          ||DECODE(m.client_type_2,'L','N','F','A') cl_type,
          SUM(n.bal_amt) end_bal
        FROM
          (SELECT TRIM(MST_CLIENT.client_cd) client_cd,
            DECODE(T_ACCOUNT_LEDGER.db_cr_flg, 'D', 1, -1) * NVL(T_ACCOUNT_LEDGER.curr_val, 0) bal_amt
          FROM MST_CLIENT,
            T_ACCOUNT_LEDGER ,
            ( SELECT gl_a FROM MST_GLA_TRX WHERE JUR_TYPE = 'T3'
            ) v
          WHERE T_ACCOUNT_LEDGER.sl_acct_cd = MST_CLIENT.client_cd
          AND T_ACCOUNT_LEDGER.doc_date BETWEEN V_BGN_DATE AND P_END_DATE
          AND T_ACCOUNT_LEDGER.approved_sts = 'A'
          AND T_ACCOUNT_LEDGER.gl_acct_cd   = v.gl_a
          UNION ALL
          SELECT TRIM(MST_CLIENT.client_cd),
            (NVL(T_DAY_TRS.deb_obal, 0) - NVL(T_DAY_TRS.cre_obal, 0)) beg_bal
          FROM MST_CLIENT,
            T_DAY_TRS,
            ( SELECT gl_a FROM MST_GLA_TRX WHERE JUR_TYPE = 'T3'
            ) v
          WHERE T_DAY_TRS.sl_acct_cd = MST_CLIENT.client_cd
          AND T_DAY_TRS.trs_dt       = V_BGN_DATE
          AND T_DAY_TRS.gl_acct_cd   = v.gl_a
          ) n,
          MST_CLIENT m,
          LST_TYPE3
        WHERE m.client_cd       = n.client_cd
        AND m.client_type_3     = LST_TYPE3.cl_type3
        AND m.client_type_1    <> 'B'
        AND LST_TYPE3.margin_cd = 'M'
        GROUP BY n.client_cd,
          m.client_type_1,
          m.client_type_2
        HAVING ( (SUM(bal_amt ) >= 500000000 AND V_MARGIN_FLG='Y' ) OR(SUM(bal_amt ) > 0 AND  V_MARGIN_FLG='N' ) )
        ) amt,
        (SELECT t.client_cd,
          SUM(t.onh_qty * p.stk_clos) AS stk_sum,
          COUNT(t.stk_cd)             AS stk_cnt
        FROM
          (SELECT a.client_cd,
            a.stk_cd,
            SUM(a.onh_qty) onh_qty
          FROM
            (SELECT client_cd,
              nvl(c.stk_cd_new,stk_cd)stk_cd,
              NVL( DECODE(trim(NVL(gl_acct_cd,'36')),'36',1,0) * DECODE(db_cr_flg,'D',-1,1) * (total_share_qty + withdrawn_share_qty),0) onh_qty
            FROM T_STK_MOVEMENT,
      (select stk_cd_new, stk_cd_old from t_change_stk_cd where eff_dt<=P_END_DATE)c
            WHERE doc_dt BETWEEN V_BGN_DATE AND P_END_DATE
            AND gl_acct_cd ='36'
            AND doc_stat   = '2'
      AND STK_CD = c.stk_cd_old(+)
            UNION ALL
            SELECT client_cd,
               nvl(c.stk_cd_new,stk_cd)stk_cd,
              qty
            FROM T_SECU_BAL,
      (select stk_cd_new, stk_cd_old from t_change_stk_cd where eff_dt<=P_END_DATE)c
            WHERE bal_dt   = V_BGN_DATE
            AND gl_acct_cd ='36'
      AND STK_CD = c.stk_cd_old(+)
            ) a
          GROUP BY a.client_cd,
            a.stk_cd
          ) t,
          ( SELECT stk_cd, stk_clos FROM T_CLOSE_PRICE WHERE stk_date = P_END_DATE
          ) p
        WHERE t.onh_qty > 0
        AND t.stk_cd    = p.stk_cd
        GROUP BY t.client_cd
        ) porto
      WHERE amt.client_cd = porto.client_cd (+)
      ) det ;
  EXCEPTION
  WHEN OTHERS THEN
    V_ERROR_CD  :=-10;
    V_ERROR_MSG := SUBSTR('INSERT INTO LAP_MARGIN_FORM_III_I_3 '||SQLERRM(SQLCODE),1,200);
    RAISE V_ERR;
  END;
  

--UPDATE AVG EXPOSURE AND RATIO AVG
FOR REC IN CSR_DATA LOOP
  FOR AVG IN CSR_UPD(REC.CLIENT_CD) LOOP
     BEGIN
       UPDATE LAP_MARGIN_FORM_III_I_3 SET AVG1=AVG.avg_bal1,
                                         AVG3 = AVG.avg_bal3,
                                         AVG6 = AVG.avg_bal6,
                                         AVG_RATIO1 = AVG.avg_ratio1,
                                         AVG_RATIO3 = AVG.avg_ratio3,
                                         AVG_RATIO6 = AVG.avg_ratio6
        WHERE UPDATE_DATE = P_UPDATE_DATE AND UPDATE_SEQ=P_UPDATE_SEQ AND CLIENT_CD = AVG.CLIENT_CD;
     EXCEPTION
     WHEN OTHERS THEN
     V_ERROR_CD :=-20;
     V_ERROR_MSG :=SUBSTR('UPDATE AVG EXPOSURE AND RATIO AVG '||SQLERRM(SQLCODE),1,200);
     RAISE V_ERR;
     END;
  END LOOP;
END LOOP;

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
END SP_MARGIN_FORM_III_3;