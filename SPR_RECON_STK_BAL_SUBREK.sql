create or replace PROCEDURE SPR_RECON_STK_BAL_SUBREK(
    P_SUBREK_TYPE   VARCHAR2,
    P_BGN_STK       VARCHAR2,
    P_BGN_CLIENT    VARCHAR2,
    P_END_STK       VARCHAR2,
    P_END_CLIENT    VARCHAR2,
    P_ALL_RECORD    VARCHAR2,
    P_DT_END_DATE   DATE,
    P_DT_BGN_DATE   DATE,
    P_SUBREK_GRUP   VARCHAR2,
    P_USER_ID       VARCHAR2,
    P_GENERATE_DATE DATE,
    P_RANDOM_VALUE OUT NUMBER,
    P_ERROR_MSG OUT VARCHAR2,
    P_ERROR_CD OUT NUMBER)
IS
-- [IN] 18MAY 2017 SUM( secu_end_onh) DIKOMEN BAGIAN HAVING SUPAYA MUNCUL QTY YG BEDA , DI INISTPRO 0 DAN DI KSEI>0
-- KARENA ADA KEMUNGKINAN DI 2 SUBREK MEMILIKI STOCK YANG SAMA

  V_ERROR_MSG    VARCHAR2(200);
  V_ERROR_CD     NUMBER(10);
  v_random_value NUMBER(10);
  V_ERR          EXCEPTION;
BEGIN

  v_random_value := ABS(dbms_random.random);
  
  BEGIN
    SP_RPT_REMOVE_RAND('R_RECON_STK_BAL_SUBREK',V_RANDOM_VALUE,V_ERROR_MSG,V_ERROR_CD);
  EXCEPTION
  WHEN OTHERS THEN
    V_ERROR_CD  := -10;
    V_ERROR_MSG := SUBSTR('SP_RPT_REMOVE_RAND '||V_ERROR_MSG||SQLERRM(SQLCODE),1,200);
    RAISE V_err;
  END;
  
  IF V_ERROR_CD  <0 THEN
    V_ERROR_CD  := -20;
    V_ERROR_MSG := SUBSTR('SP_RPT_REMOVE_RAND'||V_ERROR_MSG,1,200);
    RAISE V_ERR;
  END IF;
  
  BEGIN
    INSERT
    INTO R_RECON_STK_BAL_SUBREK
      (
        BGN_DATE ,
        END_DATE ,
        SUB_REK ,
        CLIENT_CD ,
        STK_CD ,
        SECU_THEO ,
        SECU_ONH ,
        SUBREK004 ,
        KSEI ,
        SELISIH ,
        USER_ID ,
        GENERATE_DATE ,
        RAND_VALUE
      )
    SELECT P_DT_BGN_DATE,
      P_DT_END_DATE,
      sub_rek,
      client_cd,
      stk_cd,
      SUM( secu_end_theo) secu_theo,
      SUM( secu_end_onh) secu_onh,
      SUM( subrek004) subrek004,
      SUM( ksei) ksei,
      SUM( secu_end_onh) - SUM( ksei) Selisih,
      P_USER_ID,
      P_GENERATE_DATE,
      V_RANDOM_VALUE
    FROM
      (SELECT DECODE( P_SUBREK_TYPE,'001',subrek001,'004',v.subrek004) AS sub_rek,
        x.client_cd,
        x.stk_cd,
        x.secu_end_theo,
        DECODE(P_SUBREK_TYPE,'001', x.secu_end_onh - x.subrek004,x.subrek004) secu_end_onh,
        x.secu_end_bal,
        x.secu_os_buy,
        x.secu_os_sell,
        x.subrek004 ,
        x.ksei
      FROM
        (SELECT client_cd,
          stk_cd,
          SUM(DECODE(trim(gl_acct_cd),'10',1,'12',1,'14',1,'51',1,0) * (beg_bal + mvmt)) secu_end_theo,
          SUM(DECODE(trim(gl_acct_cd),'36',1,'33',0,0)               * (beg_bal + mvmt)) secu_end_onh,
          SUM( beg_bal                                               + mvmt) AS secu_end_bal,
          SUM(DECODE(trim(gl_acct_cd),'59',                          -1,'55',-1,0) * (beg_bal + mvmt)) secu_os_buy,
          SUM(DECODE(trim(gl_acct_cd),'17',1,'21',1,0)               * (beg_bal + mvmt)) secu_os_sell,
          SUM(DECODE(trim(gl_acct_cd),'09',1,'13',1,0)               * (beg_bal + mvmt)) subrek004,
          0 ksei
        FROM
          (SELECT client_cd,
            NVL(C.STK_CD_NEW,STK_CD)stk_cd,
            gl_acct_cd,
            0 beg_bal,
            DECODE(trim(gl_acct_cd), '36',-1, 1) * DECODE(trim(db_cr_flg),'D',1,-1) * (NVL(withdrawn_share_qty,0) + NVL(total_share_qty,0)) mvmt
          FROM T_STK_MOVEMENT,
          (SELECT STK_CD_NEW, STK_CD_OLD FROM T_CHANGE_STK_CD WHERE EFF_DT<=P_DT_END_DATE)C
          WHERE doc_dt BETWEEN P_DT_BGN_DATE AND P_DT_END_DATE
          AND STK_CD = C.STK_CD_OLD(+)
          AND client_cd BETWEEN P_BGN_CLIENT AND P_END_CLIENT
          AND  NVL(C.STK_CD_NEW,STK_CD) BETWEEN P_BGN_STK AND P_END_STK
          AND gl_acct_cd IS NOT NULL
          AND doc_stat    = '2'
          UNION ALL
          SELECT client_cd,
            NVL(C.STK_CD_NEW,STK_CD)stk_cd,
            gl_acct_cd,
            DECODE(SIGN(TO_NUMBER(trim(gl_acct_cd)) - 37), 1,-1, 1) * qty AS beg_bal,
            0 mvmt
          FROM T_SECU_BAL,
           (SELECT STK_CD_NEW, STK_CD_OLD FROM T_CHANGE_STK_CD WHERE EFF_DT<=P_DT_END_DATE)C
          WHERE bal_dt = P_DT_BGN_DATE
          AND STK_CD = C.STK_CD_OLD(+)
          AND client_cd BETWEEN P_BGN_CLIENT AND P_END_CLIENT
          AND  NVL(C.STK_CD_NEW,STK_CD) BETWEEN P_BGN_STK AND P_END_STK
          AND gl_acct_cd <> '33'
          )
        GROUP BY client_cd,
          stk_cd,
          gl_acct_cd
        UNION ALL
        SELECT client_cd,
          t.stk_cd,
          0 secu_end_theo,
          0 secu_end_onh,
          0 secu_end_bal,
          0 secu_os_buy,
          0 secu_os_sell,
          qty subrek004,
          0 ksei
        FROM t_porto_jaminan t,
          (SELECT stk_cd,
            MAX(from_Dt) max_dt
          FROM t_porto_jaminan
          WHERE from_Dt <= P_DT_END_DATE
          GROUP BY stk_Cd
          ) a
        WHERE from_Dt = max_dt
        AND t.stk_cd  = a.stk_cd
        AND qty      <> 0
        ) x,
        v_client_subrek14 v, mst_client m
      WHERE x.client_Cd             = v.client_Cd
      AND v.client_cd = m.client_cd--18MAY
      AND M.SUSP_STAT<>'C'--18MAY
      AND ((SUBSTR(subrek001, 6,4) <> '0000'
      AND P_SUBREK_GRUP             = 'SUB')
      OR (SUBSTR(subrek001, 6,4)    = '0000'
      AND P_SUBREK_GRUP             = 'MAIN'))
      UNION ALL
      SELECT sub_rek,
        c.client_cd,
        stk_cd,
        0 secu_end_theo,
        0 secu_end_onh,
        0 secu_end_bal,
        0 secu_os_buy,
        0 secu_os_sell,
        0 curr_theo,
        qty AS ksei
      FROM
        (SELECT sub_rek,
          stk_cd,
          qty
        FROM T_STK_KSEI
        WHERE bal_dt = P_DT_END_DATE
        AND stk_cd BETWEEN P_BGN_STK AND P_END_STK
        AND STK_CD                 <> 'IDR'
        AND SUBSTR(sub_rek, 10,3)   = P_SUBREK_TYPE
        AND ((SUBSTR(sub_rek, 6,4) <> '0000'
        AND P_SUBREK_GRUP           = 'SUB')
        OR (SUBSTR(sub_rek, 6,4)    = '0000'
        AND P_SUBREK_GRUP           = 'MAIN'))
        UNION
        SELECT sub_rek,
          stk_cd,
          qty
        FROM T_STK_KSEI_HIST
        WHERE bal_dt = P_DT_END_DATE
        AND stk_cd BETWEEN P_BGN_STK AND P_END_STK
        AND STK_CD                 <> 'IDR'
        AND SUBSTR(sub_rek, 10,3)   = P_SUBREK_TYPE
        AND ((SUBSTR(sub_rek, 6,4) <> '0000'
        AND P_SUBREK_GRUP           = 'SUB')
        OR (SUBSTR(sub_rek, 6,4)    = '0000'
        AND P_SUBREK_GRUP           = 'MAIN'))
        ) b,
        (SELECT V.client_cd,
          subrek001
        FROM v_client_subrek14 V, MST_CLIENT M
        WHERE  v.client_cd = m.client_cd--18MAY
        AND M.SUSP_STAT<>'C'--18MAY
        AND V.client_cd BETWEEN P_BGN_CLIENT AND P_END_CLIENT
        UNION
        SELECT DISTINCT V.client_cd,
          subrek004
        FROM v_client_subrek14 V, MST_CLIENT M
        WHERE v.client_cd = m.client_cd--18MAY
        AND M.SUSP_STAT<>'C'--18MAY
        AND  V.client_cd BETWEEN P_BGN_CLIENT AND P_END_CLIENT
        ) c
      WHERE b.sub_rek = c.subrek001
      )
    GROUP BY sub_rek,
      client_cd,
      stk_cd
    HAVING 
    --18MAY 2017
    --(( P_SUBREK_TYPE   = '001'
    --AND SUM( secu_end_onh)  <> 0   
    --)
    --OR ( P_SUBREK_TYPE       = '004'
    --AND SUM( subrek004)     <> 0))
    --AND 
    (SUM(secu_end_onh ) <> SUM(ksei)
    OR P_ALL_RECORD          = 'Y')
  UNION ALL
  SELECT
    P_DT_BGN_DATE ,
    P_DT_END_DATE ,
    '' SUB_REK ,
    'HEADER' CLIENT_CD ,
    NULL STK_CD ,
     0 SECU_THEO ,
    0 SECU_ONH ,
    0 SUBREK004 ,
    0 KSEI ,
    0 SELISIH ,
    P_USER_ID ,
    P_GENERATE_DATE ,
    V_RANDOM_VALUE
    FROM DUAL
  ;
  --  ORDER BY CLIENT_CD,
--      sub_rek,
--      STK_CD;
      
  EXCEPTION
  WHEN OTHERS THEN
    V_ERROR_CD  := -30;
    V_ERROR_MSG := SUBSTR('INSERT R_RECON_STK_BAL_SUBREK '||V_ERROR_MSG||SQLERRM(SQLCODE),1,200);
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
END SPR_RECON_STK_BAL_SUBREK;