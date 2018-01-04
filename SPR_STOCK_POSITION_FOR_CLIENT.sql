CREATE OR REPLACE
PROCEDURE SPR_STOCK_POSITION_FOR_CLIENT(
    P_DOC_DATE          DATE,
    P_BGN_STK_CD        VARCHAR2,
    P_END_STK_CD        VARCHAR2,
    P_BGN_CLIENT        VARCHAR2,
    P_END_CLIENT        VARCHAR2,
    P_BGN_REM           VARCHAR2,
    P_END_REM           VARCHAR2,
    P_BGN_BRANCH        VARCHAR2,
    P_END_BRANCH        VARCHAR2,
    P_PRICE_OPTION      VARCHAR2,
    P_CUSTODY           VARCHAR2,
    P_BGN_CLIENT_TYPE_3 VARCHAR2,
    P_END_CLIENT_TYPE_3 VARCHAR2,
    P_BGN_MARGIN        VARCHAR2,
    P_END_MARGIN        VARCHAR2,
    P_USER_ID           VARCHAR2,
    P_GENERATE_DATE     DATE,
    P_RANDOM_VALUE OUT NUMBER,
    P_ERROR_CD OUT NUMBER,
    P_ERROR_MSG OUT VARCHAR2 )
IS
  V_ERROR_MSG    VARCHAR2(200);
  V_ERROR_CD     NUMBER(10);
  v_random_value NUMBER(10);
  V_ERR          EXCEPTION;
  V_BGN_DATE     DATE;
  V_END_DATE     DATE :=P_DOC_DATE;
  V_BROKER_CD    VARCHAR2(2);
BEGIN

  v_random_value := ABS(dbms_random.random);
  
  BEGIN
    SP_RPT_REMOVE_RAND('R_STK_POSITION_CLIENT',V_RANDOM_VALUE,V_ERROR_MSG,V_ERROR_CD);
  EXCEPTION
  WHEN OTHERS THEN
    V_ERROR_CD  := -10;
    V_ERROR_MSG := SUBSTR('SP_RPT_REMOVE_RAND '||SQLERRM(SQLCODE),1,200);
    RAISE V_err;
  END;
  
  IF V_ERROR_CD  <0 THEN
    V_ERROR_CD  := -20;
    V_ERROR_MSG := SUBSTR('SP_RPT_REMOVE_RAND'||V_ERROR_MSG,1,200);
    RAISE V_ERR;
  END IF;
  
  V_BGN_DATE := P_DOC_DATE - TO_CHAR(P_DOC_DATE ,'dd') + 1;
  
  --SELECT BROKER_CD
  BEGIN
    SELECT SUBSTR(BROKER_CD,1,2) INTO V_BROKER_CD FROM V_BROKER_SUBREK;
  EXCEPTION
  WHEN OTHERS THEN
    V_ERROR_CD  := -22;
    V_ERROR_MSG := SUBSTR('SELECT BROKER_CD  '||SQLERRM(SQLCODE),1,200);
    RAISE V_err;
  END;
  
  IF P_PRICE_OPTION ='Y' AND V_BROKER_CD <> 'PF' THEN
  
    BEGIN
      INSERT
      INTO R_STK_POSITION_CLIENT
        (
          DOC_DATE ,
          CLIENT_CD ,
          CLIENT_NAME ,
          REM_CD ,
          BRANCH_CODE ,
          BRCH_NAME ,
          SUBREK ,
          OLD_CD ,
          STK_CD ,
          L_F ,
         -- THEO_QTY ,
          BAL_QTY ,
          AVG_PRICE ,
          AVG_VALUE ,
          STK_PRICE ,
          MARKET_VAL ,
          PRICE_OPTION ,
          STK_VAL ,
          USER_ID ,
          RAND_VALUE ,
          GENERATE_DATE,
          CUSTODIAN_CD
        )
      SELECT P_DOC_DATE,
        trim(c.client_cd) client_cd,
        c.client_name,
        c.rem_cd,
        c.branch_code,
        C.BRCH_NAME,
        NVL(C.SUBREK001,C.BANK_BRCH_CD) AGREEMENT_NO,
        NULL OLD_CD,
        TRIM(C.STK_CD) STK_CD,
        'L' AS L_F,
        --F.STK_DESC STK_NAME,
        DECODE(NVL(b.on_bae,0) + NVL(repo_buy_client_mvmt,0), 0,NVL(b.beg_bal_qty,0) + NVL(theo_mvmt,0),0) theo_qty,
        0 AVG_PRICE,
        0 AVG_VALUE,
        NVL(p.price,0) price,
        0 MARKET_VAL,
        P_PRICE_OPTION,
        DECODE(NVL(b.on_bae,0) + NVL(repo_buy_client_mvmt,0), 0,NVL(b.beg_bal_qty,0) + NVL(theo_mvmt,0),0) * NVL(p.price,0) stk_val,
        P_USER_ID,
        V_RANDOM_VALUE,
        P_GENERATE_DATE,
        C.CUSTODIAN_CD
      FROM
        (SELECT client_cd,
          stk_cd,
          SUM(theo_mvmt) theo_mvmt,
          SUM(repo_buy_client_mvmt) repo_buy_client_mvmt,
          COUNT(1) cnt
        FROM
          (SELECT client_cd,
            stk_cd,
            gl_acct_cd,
            SUBSTR(doc_num,5,2) doc_type,
            (NVL(DECODE(SUBSTR(doc_num,5,2),'BR',1,'JR',1,'BI',1,'JI',1,'RS',1,'WS',1,0) * DECODE(db_cr_flg,'D',1,-1) * (total_share_qty + withdrawn_share_qty),0)) theo_mvmt,
            (NVL(DECODE(NVL(trim(gl_acct_cd),'XX'),'09',1,0)                             * DECODE(db_cr_flg,'D',1,-1) * DECODE(SUBSTR(NVL(ref_doc_num,'XXXX'),1,4),'XXXX',0,1) * (total_share_qty),0)) repo_buy_client_mvmt
          FROM t_stk_movement
          WHERE doc_dt BETWEEN V_BGN_DATE AND V_END_DATE
          AND stk_cd     >= P_BGN_STK_CD
          AND stk_cd     <= P_END_STK_CD
          AND client_cd  >= P_BGN_CLIENT
          AND client_cd  <= P_END_CLIENT
          AND gl_acct_cd IN ('10','12','13','14','51','09')
          AND doc_stat    = '2'
          )
        GROUP BY client_cd,
          stk_cd
        ) a,
        (SELECT *
        FROM t_stkbal
        WHERE bal_dt = V_BGN_DATE
        AND client_cd BETWEEN P_BGN_CLIENT AND P_END_CLIENT
        AND stk_cd BETWEEN P_BGN_STK_CD AND P_END_STK_CD
        ) b,
        (SELECT t.client_cd,
          t.stk_cd,
          t.l_f,
          M.BRANCH_CODE,
          M.CLIENT_NAME,
          M.AGREEMENT_NO,
          M.REM_CD,
          P.BRCH_NAME,
          M.BANK_BRCH_CD ,
          V.SUBREK001,
          M.CUSTODIAN_CD
        FROM t_stkhand t,
          mst_client m,
          lst_type3 l,
          mst_branch p ,
          v_client_subrek14 v
        WHERE t.client_cd BETWEEN P_BGN_CLIENT AND P_END_CLIENT
        AND t.stk_cd BETWEEN P_BGN_STK_CD AND P_END_STK_CD
        AND T.CLIENT_CD = M.CLIENT_CD
        AND m.client_cd = v.client_cd(+)
        AND TRIM(M.BRANCH_CODE) BETWEEN P_BGN_BRANCH AND P_END_BRANCH
        AND trim(m.rem_cd) BETWEEN P_BGN_REM AND P_END_REM
        AND trim(m.branch_code) = trim(p.brch_cd)
        AND m.client_type_3     = l.cl_type3
        AND l.margin_cd BETWEEN P_BGN_MARGIN AND P_END_MARGIN
        ) c,
        (SELECT stk_cd,
          DECODE(stk_clos,'0',stk_prev,stk_clos) price
        FROM v_stk_clos
        WHERE STK_DATE = P_DOC_DATE
        UNION ALL
        SELECT BOND_CD,PRICE FROM T_BOND_PRICE WHERE price_dt=P_DOC_DATE
        ) p,
        mst_counter f
      WHERE c.client_cd                              = b.client_cd(+)
      AND c.stk_cd                                   = b.stk_cd(+)
      AND c.client_cd                                = a.client_cd(+)
      AND c.stk_cd                                   = a.stk_cd(+)
      AND c.stk_cd                                   = f.stk_cd
      AND c.stk_cd                                   = p.stk_cd (+)
      AND (NVL(B.BEG_BAL_QTY,0) + NVL(THEO_MVMT,0)) <> 0
      UNION ALL
      SELECT P_DOC_DATE ,
        'TXT' CLIENT_CD ,
        NULL CLIENT_NAME ,
        NULL REM_CD ,
        NULL BRANCH_CODE ,
        NULL BRCH_NAME ,
        NULL SUBREK ,
        NULL OLD_CD ,
        NULL STK_CD ,
        NULL L_F ,
        NULL THEO_QTY ,
        NULL AVG_PRICE ,
        NULL AVG_VALUE ,
        NULL STK_PRICE ,
        NULL MARKET_VAL ,
        P_PRICE_OPTION,
        NULL STK_VAL ,
        P_USER_ID ,
        V_RANDOM_VALUE,
        P_GENERATE_DATE,
        NULL CUSTODIAN_CD
      FROM DUAL;
    EXCEPTION
    WHEN OTHERS THEN
      V_ERROR_CD  := -30;
      V_ERROR_MSG := SUBSTR('INSERT R_STK_POSITION_CLIENT '||V_ERROR_MSG||SQLERRM(SQLCODE),1,200);
      RAISE V_err;
    END;
    
  ELSE--WITHOUT PRICE
  
    IF V_BROKER_CD <> 'PF' THEN
    
      BEGIN
        INSERT
        INTO R_STK_POSITION_CLIENT
          (
            DOC_DATE ,
            CLIENT_CD ,
            CLIENT_NAME ,
            REM_CD ,
            BRANCH_CODE ,
            BRCH_NAME ,
            SUBREK ,
            OLD_CD ,
            STK_CD ,
            L_F ,
            BAL_QTY ,
            AVG_PRICE ,
            AVG_VALUE ,
            STK_PRICE ,
            MARKET_VAL ,
            USER_ID ,
            RAND_VALUE ,
            GENERATE_DATE,
            PRICE_OPTION,
            CUSTODIAN_CD
          )
        SELECT P_DOC_DATE,
          trim(c.client_cd) client_cd,
          c.client_name,
          c.rem_cd,
          c.branch_code,
          c.brch_name,
          c.subrek,
          c.old_ic_num AS OLD_CD,
          trim(c.stk_cd) stk_cd,
          'L' AS L_F,
          --f.stk_desc stk_name,
          --c.sid,
          --c.custodian_cd,
          NVL(b.beg_bal_qty,0) + NVL(theo_mvmt,0) theo_qty,
          --nvl(b.beg_on_hand,0) + nvl(onh_mvmt,0)  onh_qty
          NVL(B.AVG_PRICE,0),
          0 AVG_VALUE,
          0 STK_PRICE,
          0 MARKET_VAL,
          P_USER_ID,
          V_RANDOM_VALUE,
          P_GENERATE_DATE,
          P_PRICE_OPTION,
          C.CUSTODIAN_CD
        FROM
          (SELECT client_cd,
            stk_cd,
            SUM(onh_mvmt) onh_mvmt,
            SUM(theo_mvmt) theo_mvmt,
            COUNT(1) cnt
          FROM
            (SELECT client_cd,
              stk_cd,
              gl_acct_cd,
              SUBSTR(doc_num,5,2) doc_type,
              (NVL(DECODE(SUBSTR(doc_num,5,2),'BR',1,'JR',1,'BI',1,'JI',1,'BO',1,'JO',1,'RS',1,'WS',1,0) * DECODE(trim(NVL(gl_acct_cd,'36')),'14',1,'51',1,'12',1,'13',1,'10',1,0) * DECODE(db_cr_flg,'D',1,-1) * (total_share_qty + withdrawn_share_qty),0)) theo_mvmt,
              (NVL(DECODE(SUBSTR(doc_num,5,2),'JV',1,'XS',1,'LS',1,'RS',1,'WS',1,'CS',1,0)               * DECODE(trim(NVL(gl_acct_cd,'36')),'36',1, 0) * DECODE(db_cr_flg,'D',-1,1) * (total_share_qty + withdrawn_share_qty),0)) onh_mvmt
            FROM t_stk_movement
            WHERE doc_dt BETWEEN V_BGN_DATE AND P_DOC_DATE
            AND stk_cd       >= P_BGN_STK_CD
            AND stk_cd       <= P_END_STK_CD
            AND client_cd    >= P_BGN_CLIENT
            AND client_cd    <= P_END_CLIENT
            AND ((gl_acct_cd IN ('10','12','13','36','14','51','55','59','21','17','09','50'))
            OR (gl_acct_cd   IS NULL) )
            AND doc_stat      = '2'
            )
          GROUP BY client_cd,
            stk_cd
          ) a,
          (SELECT *
          FROM t_stkbal
          WHERE bal_dt = V_BGN_DATE
          AND client_cd BETWEEN P_BGN_CLIENT AND P_END_CLIENT
          AND stk_cd BETWEEN P_BGN_STK_CD AND P_END_STK_CD
          ) b,
          (SELECT t.client_cd,
            t.stk_cd,
            t.l_f,
            m.client_name,
            m.rem_cd,
            s.subrek14 AS subrek,
            m.branch_code,
            p.brch_name,
            m.custodian_cd,
            m.sid,
            m.old_ic_num
          FROM t_stkhand t,
            mst_client m,
            lst_type3 l,
            mst_branch p,
            v_client_subrek14 s
          WHERE t.client_cd BETWEEN P_BGN_CLIENT AND P_END_CLIENT
          AND t.stk_cd BETWEEN P_BGN_STK_CD AND P_END_STK_CD
          AND t.client_cd = m.client_cd
          AND trim(m.branch_code) BETWEEN P_BGN_BRANCH AND P_END_BRANCH
          AND trim(m.rem_cd) BETWEEN P_BGN_REM AND P_END_REM
          AND trim(m.branch_code) = trim(p.brch_cd)
          AND m.client_type_3 BETWEEN P_BGN_CLIENT_TYPE_3 AND P_END_CLIENT_TYPE_3
          AND m.client_type_3 = l.cl_type3
          AND l.margin_cd BETWEEN P_BGN_MARGIN AND P_END_MARGIN
          AND ((custodian_cd IS NOT NULL
          AND P_CUSTODY       = 'Y')
          OR P_CUSTODY        = 'N')
          AND t.client_cd     = s.client_cd (+)
          ) c,
          mst_counter f
        WHERE c.client_cd                               = b.client_cd(+)
        AND c.stk_cd                                    = b.stk_cd(+)
        AND c.client_cd                                 = a.client_cd(+)
        AND c.stk_cd                                    = a.stk_cd(+)
        AND c.stk_cd                                    = f.stk_cd
        AND ((NVL(b.beg_bal_qty,0) + NVL(theo_mvmt,0)) <> 0
        OR (NVL(b.beg_on_hand,0)   + NVL(onh_mvmt,0))  <> 0 )
        UNION ALL
        SELECT P_DOC_DATE ,
          'TXT' CLIENT_CD ,
          NULL CLIENT_NAME ,
          NULL REM_CD ,
          NULL BRANCH_CODE ,
          NULL BRCH_NAME ,
          NULL SUBREK ,
          NULL OLD_CD ,
          NULL STK_CD ,
          NULL L_F ,
          NULL BAL_QTY ,
          NULL AVG_PRICE ,
          NULL AVG_VALUE ,
          NULL STK_PRICE ,
          NULL MARKET_VAL ,
          P_USER_ID,
          V_RANDOM_VALUE,
          P_GENERATE_DATE,
          P_PRICE_OPTION,
          NULL CUSTODIAN_CD
        FROM DUAL;
      EXCEPTION
      WHEN OTHERS THEN
        V_ERROR_CD  := -40;
        V_ERROR_MSG := SUBSTR('INSERT R_STK_POSITION_CLIENT '||V_ERROR_MSG||SQLERRM(SQLCODE),1,200);
        RAISE V_err;
      END;
      
    ELSE
    
      BEGIN
        INSERT
        INTO R_STK_POSITION_CLIENT
          (
            DOC_DATE ,
            CLIENT_CD ,
            CLIENT_NAME ,
            REM_CD ,
            BRANCH_CODE ,
            BRCH_NAME ,
            SUBREK ,
            OLD_CD ,
            STK_CD ,
            L_F ,
            BAL_QTY ,
            AVG_PRICE ,
            AVG_VALUE ,
            STK_PRICE ,
            MARKET_VAL ,
            PRICE_OPTION ,
            STK_VAL ,
            USER_ID ,
            RAND_VALUE ,
            GENERATE_DATE ,
           -- THEO_QTY,
            CUSTODIAN_CD
          )
        SELECT P_DOC_DATE,
          trim(t.client_cd) client_cd,
          trim(c.client_name) client_name,
          trim(c.rem_cd) rem_cd,
          c.branch_code,
          b.brch_name,
          v.subrek14 subrek,
          c.old_ic_num old_cd,
          trim(t.stk_cd) stk_cd,
          trim(t.l_f) l_f,
          t.bal_qty,
          t.avg_price,
          t.bal_qty * t.avg_price AS avg_value,
          NVL(p.stk_price, 0) stk_price,
          t.bal_qty * NVL(p.stk_price, 0) AS market_val,
          P_PRICE_OPTION,
          0 STK_VAL,
          P_USER_ID,
          V_RANDOM_VALUE,
          P_GENERATE_DATE,
          --0 THEO_QTY,
          C.CUSTODIAN_CD
        FROM
          (SELECT client_cd,
            stk_cd,
            'L' AS l_f,
            SUM(beg_bal + theo_mvmt) bal_qty,
            MAX(avg_price) avg_price
          FROM
            (SELECT client_cd,
              stk_cd,
              0 beg_bal,
              (NVL(DECODE(SUBSTR(doc_num,5,2),'BR',1,'JR',1,'BI',1,'JI',1,'RS',1,'WS',1,0) * DECODE(trim(NVL(gl_acct_cd,'36')),'14',1,'51',1,'12',1,'13',1,'10',1,0) * DECODE(db_cr_flg,'D',1,-1) * (total_share_qty + withdrawn_share_qty),0)) theo_mvmt,
              0 avg_price
            FROM t_stk_movement
            WHERE doc_dt BETWEEN V_BGN_DATE AND P_DOC_DATE
            AND stk_cd     >= P_BGN_STK_CD
            AND stk_cd     <= P_END_STK_CD
            AND client_cd  >= P_BGN_CLIENT
            AND client_cd  <= P_END_CLIENT
            AND gl_acct_cd IS NOT NULL
            AND gl_acct_cd IN ('10','12','13','14','51')
            AND doc_stat    = '2'
            UNION ALL
            SELECT client_cd,
              stk_cd,
              beg_bal_qty,
              0,
              0
            FROM t_stkbal
            WHERE bal_dt = V_BGN_DATE
            AND client_cd BETWEEN P_BGN_CLIENT AND P_END_CLIENT
            AND stk_cd BETWEEN P_BGN_STK_CD AND P_END_STK_CD
            UNION ALL
            SELECT a.client_cd,
              a.stk_cd,
              0 beg_bal,
              0 theo_mvmt,
              a.avg_buy_price AS avg_price
            FROM
              (SELECT client_cd,
                stk_cd,
                MAX(avg_dt) max_dt
              FROM t_avg_price
              WHERE avg_dt < P_DOC_DATE
              AND client_cd BETWEEN P_BGN_CLIENT AND P_END_CLIENT
              AND stk_cd BETWEEN P_BGN_STK_CD AND P_END_STK_CD
              GROUP BY client_cd,
                stk_cd
              ) mx,
              t_avg_price a
            WHERE a.avg_dt  = mx.max_dt
            AND a.client_cd = mx.client_cd
            AND a.stk_cd    = mx.stk_cd
            )
          GROUP BY client_cd,
            stk_cd
          HAVING SUM(beg_bal + theo_mvmt) <> 0
          ) t,
          (SELECT t.stk_cd,
            NVL(DECODE(stk_clos, 0, stk_prev, stk_clos), 0) stk_price
          FROM
            (SELECT MAX(stk_date) max_date
            FROM t_close_price
            WHERE stk_date BETWEEN TRUNC(sysdate) - 30 AND TRUNC(sysdate)
            ) mx,
            t_close_price t
          WHERE t.stk_date = mx.max_Date
          ) p,
          mst_client c,
          lst_type3 l,
          mst_branch b ,
          v_Client_Subrek14 v
        WHERE t.client_cd   = c.client_cd
        AND trim(c.rem_cd) >= P_BGN_REM
        AND trim(c.rem_cd) <= P_END_REM
        AND c.client_type_3 = l.cl_type3
        AND l.margin_cd BETWEEN P_BGN_MARGIN AND P_END_MARGIN
        AND trim(b.brch_cd) = trim(c.branch_code)
        AND c.client_cd     =v.client_Cd(+)
        AND trim(c.branch_code) BETWEEN P_BGN_BRANCH AND P_END_BRANCH
        AND t.stk_cd = p.stk_cd (+)
        UNION ALL
        SELECT P_DOC_DATE ,
          'TXT' CLIENT_CD ,
          NULL CLIENT_NAME ,
          NULL REM_CD ,
          NULL BRANCH_CODE ,
          NULL BRCH_NAME ,
          NULL SUBREK ,
          NULL OLD_CD ,
          NULL STK_CD ,
          NULL L_F ,
          NULL BAL_QTY ,
          NULL AVG_PRICE ,
          NULL AVG_VALUE ,
          NULL STK_PRICE ,
          NULL MARKET_VAL ,
          P_PRICE_OPTION ,
          NULL STK_VAL ,
          P_USER_ID ,
          V_RANDOM_VALUE ,
          P_GENERATE_DATE ,
         -- NULL THEO_QTY,
          NULL CUSTODIAN_CD
        FROM DUAL;
      EXCEPTION
      WHEN OTHERS THEN
        V_ERROR_CD  := -50;
        V_ERROR_MSG := SUBSTR('INSERT R_STK_POSITION_CLIENT '||V_ERROR_MSG||SQLERRM(SQLCODE),1,200);
        RAISE V_err;
      END;
    END IF;
  END IF;
  
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
END SPR_STOCK_POSITION_FOR_CLIENT;