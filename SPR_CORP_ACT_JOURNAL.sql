create or replace PROCEDURE SPR_CORP_ACT_JOURNAL(
    P_RECORDING_DT  DATE,
    P_TODAY_DT      DATE,
    P_BGN_DT        DATE,
    P_CUM_DT        DATE,
    P_CA_TYPE       VARCHAR2,
    P_STK_CD        VARCHAR2,
    P_STK_CD_MERGE  VARCHAR2,
    P_USER_ID       VARCHAR2,
    P_GENERATE_DATE DATE,
    P_RANDOM_VALUE OUT NUMBER,
    P_ERRCD OUT NUMBER,
    P_ERRMSG OUT VARCHAR2)
IS
  /************************************************************************************************
  22 mar 2017 ubah pembulatan diambil dari T_CORP_ACT
  23 JAN 2017 PERUBAHAN SAHAM YANG DITERIMA STOCK DIVIDEN YAITU DIPOTONG DENGAN TAX=CASH DIVIDEN
  *************************************************************************************************/
  v_random_value NUMBER(10) ;
  v_err          EXCEPTION;
  v_err_cd       NUMBER(10) ;
  v_err_msg      VARCHAR2(200) ;
  V_TODAY        DATE := p_today_dt; --TRUNC(SYSDATE);
  v_stk_cd       VARCHAR2(50) ;
BEGIN
  v_random_value := ABS(dbms_random.random) ;
  BEGIN
    SP_RPT_REMOVE_RAND('R_CORP_ACT_JOURNAL', V_RANDOM_VALUE, P_ERRCD, P_ERRMSG) ;
  EXCEPTION
  WHEN OTHERS THEN
    v_err_cd  := - 2;
    v_err_msg := SQLERRM(SQLCODE) ;
    RAISE V_err;
  END;
  IF p_ca_type = 'RIGHT' OR P_CA_TYPE = 'WARRANT' THEN
    --v_stk_cd := substr(p_stk_cd,1,4);
    v_stk_cd := SUBSTR(p_stk_cd, 1, INSTR(p_stk_cd, '-') - 1) ;--perubahan ticker code
  ELSE
    v_stk_cd := P_STK_CD;
  END IF;
  BEGIN
    --INSERT KE TABLE REPORT
    INSERT
    INTO R_CORP_ACT_JOURNAL
      (
        CA_TYPE, STK_CD, CUM_DT, X_DT, RECORDING_DT, DISTRIB_DT, CLIENT_CD, CLIENT_NAME, BRANCH_CODE, CLIENT_TYPE, FROM_QTY, TO_QTY,
        BEGIN_QTY, RECV_QTY, END_QTY, CUM_BEGIN_QTY, CUM_RECV_QTY, CUM_END_QTY, SEL_RECV, SEL_END_QTY, USER_ID, GENERATE_DATE, 
        RAND_VALUE, SEL_SPLIT_REVERSE, REM_CD, STK_CD_MERGE
      )
    SELECT ca_type, p_stk_cd, CUM_DT, X_DT, RECORDING_DT, DISTRIB_DT, client_cd, CLIENT_NAME, TRIM(BRANCH_CODE), client_type, from_qty, 
    to_qty, begin_qty, recv_qty, DECODE(CA_TYPE,'STKDIV',BEGIN_QTY+RECV_QTY,END_QTY) END_QTY, cum_begin_qty, cum_recv_qty, 
    cum_end_qty, recv_qty - cum_recv_qty sel_recv, end_qty - cum_end_qty AS sel_end_qty, P_USER_ID, P_GENERATE_DATE, V_RANDOM_VALUE,
    (END_QTY - CUM_END_QTY) -(begin_qty - cum_begin_qty) AS SEL_SPLIT_REVERSE, REM_CD, P_STK_CD_MERGE
    FROM
      (
        SELECT a.client_cd, a.stk_cd, ca_type, from_qty, to_qty, client_type, begin_qty,
          CASE
            WHEN C.ROUNDING='CEIL'
            THEN CEIL(DECODE(C.CA_TYPE,'STKDIV',(A.BEGIN_QTY * TO_QTY / FROM_QTY) - DECODE(C.TAX_FLG,'Y',(A.BEGIN_QTY * TO_QTY / FROM_QTY * M.TAX_PCN),0), A.BEGIN_QTY * TO_QTY / FROM_QTY))
            WHEN C.ROUNDING='ROUND'
            THEN ROUND(DECODE(C.CA_TYPE,'STKDIV',(A.BEGIN_QTY * TO_QTY / FROM_QTY) - DECODE(C.TAX_FLG,'Y',(A.BEGIN_QTY * TO_QTY / FROM_QTY * M.TAX_PCN),0), A.BEGIN_QTY * TO_QTY / FROM_QTY),NVL(C.ROUND_POINT,0))
            ELSE FLOOR(DECODE(C.CA_TYPE,'STKDIV',(A.BEGIN_QTY * TO_QTY / FROM_QTY) - DECODE(C.TAX_FLG,'Y',(A.BEGIN_QTY * TO_QTY / FROM_QTY * M.TAX_PCN),0), A.BEGIN_QTY * TO_QTY / FROM_QTY))
          END RECV_QTY,
          CASE
            WHEN C.ROUNDING='CEIL'
            THEN DECODE(C.CA_TYPE, 'SPLIT', 0, 'REVERSE', 0, A.BEGIN_QTY) + CEIL(A.BEGIN_QTY * TO_QTY / FROM_QTY)
            WHEN C.ROUNDING='ROUND'
            THEN DECODE(C.CA_TYPE, 'SPLIT', 0, 'REVERSE', 0, A.BEGIN_QTY) + ROUND(A.BEGIN_QTY * TO_QTY / FROM_QTY,C.ROUND_POINT)
            ELSE DECODE(C.CA_TYPE, 'SPLIT', 0, 'REVERSE', 0, A.BEGIN_QTY) + FLOOR(A.BEGIN_QTY * TO_QTY / FROM_QTY)
          END END_QTY, cum_begin_qty, FLOOR(cum_begin_qty                 * to_qty / from_qty) cum_recv_qty,
          DECODE(C.CA_TYPE, 'SPLIT', 0, 'REVERSE', 0, CUM_BEGIN_QTY) + FLOOR(CUM_BEGIN_QTY * TO_QTY / FROM_QTY) CUM_END_QTY, 
          M.CLIENT_NAME, M.BRANCH_CODE, C.DISTRIB_DT, C.X_DT, C.RECORDING_DT, C.CUM_DT, M.REM_CD
        FROM
          (
            SELECT client_cd, stk_cd, SUM(NVL(mvmt_qty, 0)) begin_qty, SUM(NVL(cum_qty, 0)) cum_begin_qty
            FROM
              (
                SELECT client_Cd, stk_cd, mvmt_qty, DECODE(SIGN(doc_dt - P_CUM_DT), 1, 0, mvmt_qty) cum_qty
                FROM
                  (
                    SELECT doc_dt, client_cd, stk_cd, DECODE(SUBSTR(doc_num, 5, 2), 'BR', 1, 'JR', 1, 'BI', 1, 'JI', 1, 'BO', 1, 'JO', 1, 'RS', 1, 'WS', 1, 0) * DECODE(db_cr_flg, 'D', 1, - 1) *(total_share_qty + withdrawn_share_qty) mvmt_qty
                    FROM IPNEXTG.T_STK_MOVEMENT
                    WHERE doc_dt BETWEEN P_BGN_DT AND P_RECORDING_DT
                    AND doc_dt           <= V_TODAY
                    AND stk_cd            = v_STK_CD
                    AND trim(gl_acct_cd) IN('10', '12', '13', '14', '51')
                    AND doc_stat          = '2'
                    AND due_dt_for_cert  <= P_RECORDING_DT
                    AND s_d_type NOT     IN('H', 'B', 'S', 'R')
                  )
                UNION ALL
                SELECT client_cd, stk_cd, beg_bal_qty - NVL(on_custody, 0), beg_bal_qty
                FROM IPNEXTG.T_STKBAL
                WHERE bal_dt = P_BGN_DT
                AND stk_cd   = v_STK_CD
              )
            GROUP BY client_cd, stk_cd
            HAVING SUM(mvmt_qty) > 0
          )
          a,(--23JAN2017 UNTUK MENDAPATKAN % PAJAK
            SELECT CLIENT_CD, CLIENT_TYPE, BRANCH_CODE,REM_CD, CLIENT_NAME, TO_NUMBER(TAX_RATE) / 100 TAX_PCN
            FROM
              (
                SELECT M.CLIENT_CD, M.CLIENT_NAME, DECODE(A.RATE_OVER25PERSEN, NULL, DECODE(M.RATE_NO, 2, R.RATE_2, 1, R.RATE_1, 0), A.RATE_OVER25PERSEN) TAX_RATE, CLIENT_TYPE, BRANCH_CODE,REM_CD
                FROM
                  (
                    SELECT CLIENT_CD, MST_CLIENT.CLIENT_NAME, DECODE(CLIENT_CD, TRIM(OTHER_1), 'H', NVL(MST_CIF.CLIENT_TYPE_1, MST_CLIENT.CLIENT_TYPE_1)) AS CLIENT_TYPE_1, NVL(MST_CIF.CLIENT_TYPE_2, MST_CLIENT.CLIENT_TYPE_2) CLIENT_TYPE_2, DECODE( NVL(MST_CIF.NPWP_NO, MST_CLIENT.NPWP_NO), NULL, 2, 1) * DECODE(NVL(MST_CIF.BIZ_TYPE, MST_CLIENT.BIZ_TYPE), 'PF', 0, 'FD', 0, 1) RATE_NO, MST_CLIENT.BRANCH_CODE, DECODE(MST_CLIENT.CLIENT_CD, C.COY_CLIENT_CD, 'H', DECODE(MST_CLIENT.CLIENT_TYPE_1, 'H', 'H', '%')) AS CLIENT_TYPE, MST_CLIENT.REM_CD
                    FROM MST_CLIENT, MST_COMPANY, MST_CIF,(
                        SELECT TRIM(OTHER_1) COY_CLIENT_CD FROM IPNEXTG.MST_COMPANY
                      )
                      C
                    WHERE MST_CLIENT.CIFS         = MST_CIF.CIFS(+)
                    AND MST_CLIENT.CLIENT_TYPE_1 <> 'B'
                    AND MST_CLIENT.CUSTODIAN_CD  IS NULL
                  )
                  M,(
                    SELECT CLIENT_CD, RATE_1 AS RATE_OVER25PERSEN
                    FROM MST_TAX_RATE
                    WHERE P_RECORDING_DT BETWEEN BEGIN_DT AND END_DT
                    AND TAX_TYPE      = 'DIVTAX'
                    AND CLIENT_CD    IS NOT NULL
                    AND STK_CD       IS NOT NULL
                    AND STK_CD        = P_STK_CD
                    AND APPROVED_STAT = 'A'
                  )
                  A,(
                    SELECT client_type_1, client_type_2, rate_1, rate_2
                    FROM MST_TAX_RATE
                    WHERE P_RECORDING_DT BETWEEN BEGIN_DT AND END_DT
                    AND TAX_TYPE      = 'DIVTAX'
                    AND CLIENT_CD    IS NULL
                    AND STK_CD       IS NULL
                    AND APPROVED_STAT = 'A'
                  )
                  R
                WHERE M.CLIENT_TYPE_2 LIKE R.CLIENT_TYPE_2
                AND M.CLIENT_TYPE_1 LIKE R.CLIENT_TYPE_1
                AND M.CLIENT_CD = A.CLIENT_CD (+)
              )
              --END 23JAN2017
          )
          m,(--25JAN2017, UNTUK CEK KAPAN MENGGUNAKAN PEMOTONGAN PAJAK DAN TIDAK
            SELECT DECODE(CA_TYPE, 'RIGHT', v_stk_cd, 'WARRANT', v_stk_cd, A.STK_CD) STK_CD, CA_TYPE, FROM_QTY, TO_QTY, DISTRIB_DT, X_DT, RECORDING_DT, CUM_DT, DECODE(B.STK_CD,NULL,'Y','N')TAX_FLG , A.ROUNDING, A.ROUND_POINT
            FROM T_CORP_ACT A, (
                SELECT STK_CD
                FROM T_CORP_ACT
                WHERE STK_CD=P_STK_CD
                AND CUM_DT  = P_CUM_DT
                  --   AND X_DT = P_X_DT
                  -- AND DISTRIB_DT = P_DISTRIB_DT
                AND CA_TYPE       ='CASHDIV'
                AND APPROVED_STAT = 'A'
              )
              B
            WHERE A.STK_CD     = B.STK_CD(+)
            AND A.STK_CD       = P_STK_CD
            AND A.CUM_DT       = P_CUM_DT
            AND A.RECORDING_DT = P_RECORDING_DT
              --AND A.X_DT =P_X_DT
              -- AND A.DISTRIB_DT = P_DISTRIB_DT
            AND A.CA_TYPE       = P_CA_TYPE
            AND A.APPROVED_STAT = 'A'
              --END 25JAN2017
          )
          c
        WHERE a.client_cd = m.client_cd
        AND a.stk_Cd      = C.stk_cd
      );
  EXCEPTION
  WHEN NO_DATA_FOUND THEN
    V_ERR_CD  := - 100;
    V_ERR_MSG := 'NO DATA FOUND';
    RAISE V_ERR;
  WHEN OTHERS THEN
    v_err_cd  := - 3;
    v_err_msg := SQLERRM(SQLCODE) ;
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
  p_errcd  := - 1;
  p_errmsg := SUBSTR(SQLERRM(SQLCODE), 1, 200) ;
END SPR_CORP_ACT_JOURNAL;