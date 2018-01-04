create or replace 
PROCEDURE SPR_STOCK_POSITION_INTERNAL(
    P_DOC_DATE          DATE,
    P_BGN_STK_CD        VARCHAR2,
    P_END_STK_CD        VARCHAR2,
    P_BGN_CLIENT        VARCHAR2,
    P_END_CLIENT        VARCHAR2,
    P_BGN_REM           VARCHAR2,
    P_END_REM           VARCHAR2,
    P_BGN_BRANCH        VARCHAR2,
    P_END_BRANCH        VARCHAR2,
    P_POSITION          VARCHAR2,
    P_CUSTODY           VARCHAR2,
    P_BGN_CLIENT_TYPE_3 VARCHAR2,
    P_END_CLIENT_TYPE_3 VARCHAR2,
    P_BGN_MARGIN        VARCHAR2,
    P_END_MARGIN        VARCHAR2,
    P_GROUP_BY          VARCHAR2,
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
BEGIN
  v_random_value := ABS(dbms_random.random);
  BEGIN
    SP_RPT_REMOVE_RAND('R_STOCK_POSITION_INTERNAL',V_RANDOM_VALUE,V_ERROR_MSG,V_ERROR_CD);
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
  V_BGN_DATE := P_DOC_DATE - TO_CHAR(P_DOC_DATE ,'dd') + 1;
  --    V_ERROR_CD  := -10;
  --    V_ERROR_MSG := P_BGN_CLIENT_TYPE_3 ||' '||P_end_CLIENT_TYPE_3;
  --    RAISE V_err;
  --
  --
  BEGIN
    INSERT
    INTO R_STOCK_POSITION_INTERNAL
      (
        DOC_DATE ,
        CLIENT_CD ,
        OLD_IC_NUM ,
        CLIENT_NAME ,
        BRANCH_CODE ,
        REM_CD ,
        STK_CD ,
        STK_NAME ,
        CLIENT_TYPE_1 ,
        SUB_REK ,
        CUSTODIAN_CD ,
        THEO_QTY ,
        ONH_QTY ,
        SCRIP_QTY ,
        OS_BUY ,
        OS_SELL ,
        REPO_BUY_CLIENT ,
        REPO_BUY_BROKER ,
        REPO_SELL_CLIENT ,
        REPO_SELL_BROKER ,
        USER_ID ,
        RAND_VALUE ,
        GENERATE_DATE,
        GROUP_BY,
        POSITION,
        JAMINAN
      )
    SELECT P_DOC_DATE,
    trim(c.client_cd) client_cd,
      old_ic_num,
      c.client_name,
      c.branch_code,
      c.rem_cd,
      trim(t.stk_cd) stk_cd,
      f.stk_desc stk_name,
      c.client_type_1,
      SUBSTR(c.subrek14,7) sub_rek,
      c.custodian_cd,
      theo_qty,
      onh_qty,
      scrip_qty,
      os_buy,
      os_sell,
      repo_buy_client,
      repo_buy_broker,
      repo_sell_client,
      repo_sell_broker,
      P_USER_ID,
      v_random_value,
      P_GENERATE_DATE,
      P_GROUP_BY,
      P_POSITION,
      jaminan
    FROM
      (SELECT client_cd,
        stk_cd,
        SUM(theo_qty) theo_qty,
        SUM(onh_qty) onh_qty,
        SUM(jaminan) jaminan,
        SUM(scrip_qty) scrip_qty,
        SUM(os_buy) os_buy,
        SUM(os_sell) os_sell,
        NVL(SUM(repo_buy_client),0) repo_buy_client,
        NVL(SUM(repo_buy_broker),0) repo_buy_broker,
        NVL(SUM(repo_sell_client),0) repo_sell_client,
        NVL(SUM(repo_sell_broker),0) repo_sell_broker
      FROM
        (SELECT client_cd,
          stk_cd,
          (NVL(DECODE(SUBSTR(doc_num,5,2),'BR',1,'JR',1,'BI',1,'JI',1,'BO',1,'JO',1,'RS',1,'WS',1,0) * DECODE(trim(NVL(gl_acct_cd,'36')),'14',1,'51',1,'12',1,'13',1,'10',1,0) * DECODE(db_cr_flg,'D',1,-1) * (total_share_qty + withdrawn_share_qty),0)) theo_qty,
          (NVL(DECODE(SUBSTR(doc_num,5,2),'JV',1,'XS',1,'LS',1,'RS',1,'WS',1,'CS',1,0)               * DECODE(trim(NVL(gl_acct_cd,'36')),'36',1, '35',1,0) * DECODE(db_cr_flg,'D',-1,1) * (total_share_qty + withdrawn_share_qty),0)) onh_qty,
          (NVL(DECODE(SUBSTR(doc_num,5,2),'BR',1,'JR',1,'BI',1,'JI',1,'JA',1,'RS',1,'WS',1,0)        * DECODE(trim(NVL(gl_acct_cd,'36')),'13',1,0) * DECODE(db_cr_flg,'D',1,-1) * (total_share_qty + withdrawn_share_qty),0)) jaminan,
          (NVL(DECODE(NVL(trim(gl_acct_cd),'XX'),'33',1,0)                                           * DECODE(db_cr_flg,'D',-1,1) * (total_share_qty + withdrawn_share_qty),0)) scrip_qty,
          (NVL(DECODE(NVL(trim(gl_acct_cd),'XX'),'59',                                               -1,'55',-1,0) * DECODE(db_cr_flg,'D',1,-1) * (total_share_qty),0)) os_buy,
          (NVL(DECODE(NVL(trim(gl_acct_cd),'XX'),'21',1,'17',1,0)                                    * DECODE(db_cr_flg,'D',1,-1) * (total_share_qty),0)) os_sell,
          (NVL(DECODE(NVL(trim(gl_acct_cd),'XX'),'09',1,0)                                           * DECODE(db_cr_flg,'D',1,-1) * DECODE(SUBSTR(NVL(ref_doc_num,'XXXX'),1,4),'XXXX',0,1) * (total_share_qty),0)) repo_buy_client,
          (NVL(DECODE(NVL(trim(gl_acct_cd),'XX'),'09',1,0)                                           * DECODE(db_cr_flg,'D',1,-1) * DECODE(SUBSTR(NVL(ref_doc_num,'XXXX'),1,4),'XXXX',1,0) * (total_share_qty),0)) repo_buy_broker,
          (NVL(DECODE(NVL(trim(gl_acct_cd),'XX'),'50',                                               -1,0) * DECODE(db_cr_flg,'D',1,-1) * DECODE(SUBSTR(NVL(ref_doc_num,'XXXX'),1,4),'XXXX',0,1) * (total_share_qty),0)) repo_sell_client,
          (NVL(DECODE(NVL(trim(gl_acct_cd),'XX'),'50',                                               -1,0) * DECODE(db_cr_flg,'D',1,-1) * DECODE(SUBSTR(NVL(ref_doc_num,'XXXX'),1,4),'XXXX',1,0) * (total_share_qty),0)) repo_sell_broker
        FROM T_STK_MOVEMENT
        WHERE doc_dt BETWEEN V_BGN_DATE AND P_DOC_DATE
        AND client_cd BETWEEN P_BGN_CLIENT AND P_END_CLIENT
        AND stk_cd BETWEEN P_BGN_STK_CD AND P_END_STK_CD
        AND ((gl_acct_cd IN ('10','12','13','36','35','33','14','51','55','59','21','17','09','50'))
        OR (gl_acct_cd   IS NULL) )
        AND doc_stat      = '2'
        UNION ALL
        SELECT client_Cd,
          stk_Cd,
          DECODE(trim(gl_acct_Cd),'14',1,'51',1,'12',1,'13',1,'10',1,0) * qty beg_theo,
          DECODE(trim(gl_acct_Cd),'36',qty,'35',qty,0) beg_onh,
          DECODE(trim(gl_acct_Cd),'13',qty,0) beg_jaminan,
          DECODE(trim(gl_acct_Cd),'33',qty,0) beg_scrip,
          DECODE(trim(gl_acct_Cd),'59',qty,'55',qty,0) beg_os_buy,
          DECODE(trim(gl_acct_Cd),'21',qty,'17',qty,0) beg_os_sell,
          DECODE(trim(gl_acct_Cd),'09',qty,0) repo_client_buy,
          0 repo_broker_buy,
          DECODE(trim(gl_acct_Cd),'50',qty,0) repo_client_sell,
          0 repo_broker_sell
        FROM T_SECU_BAL
        WHERE bal_dt = V_BGN_DATE
        AND client_cd BETWEEN P_BGN_CLIENT AND P_END_CLIENT
        AND stk_cd BETWEEN P_BGN_STK_CD AND P_END_STK_CD
        UNION ALL
        SELECT client_cd,
          t.stk_cd,
          0 beg_theo,
          0 beg_onh,
          qty beg_jaminan,
          0 beg_scrip,
          0 beg_os_buy,
          0 beg_os_sell,
          0 repo_client_buy,
          0 repo_broker_buy,
          0 repo_client_sell,
          0 repo_broker_sell
        FROM t_porto_jaminan t,
          (SELECT stk_cd,
            MAX(from_Dt) max_dt
          FROM t_porto_jaminan
          WHERE from_Dt <= P_DOC_DATE
          GROUP BY stk_Cd
          ) a
        WHERE from_Dt = max_dt
        AND t.stk_cd  = a.stk_cd
        AND qty      <> 0
        )
      GROUP BY client_cd,
        stk_cd
      ) t,
      (SELECT m.client_cd,
        m.old_ic_num,
        client_name,
        branch_code,
        rem_cd,
        custodian_cd,
        client_type_1,
        v.subrek14
      FROM MST_CLIENT m,
        v_client_subrek14 v,
        LST_TYPE3 l
      WHERE m.client_cd BETWEEN P_BGN_CLIENT AND P_END_CLIENT
      AND m.client_Cd = v.client_cd(+)
      AND trim(m.branch_code) BETWEEN P_BGN_BRANCH AND P_END_BRANCH
      AND trim(m.rem_cd) BETWEEN P_BGN_REM AND P_END_REM
      AND m.client_type_3 = l.cl_type3
      AND m.client_type_3 BETWEEN P_BGN_CLIENT_TYPE_3 AND P_END_CLIENT_TYPE_3
      AND l.margin_cd BETWEEN P_BGN_MARGIN AND P_END_MARGIN
      AND ((custodian_cd IS NOT NULL
      AND P_CUSTODY       = 'Y')
      OR P_CUSTODY        = 'N')
      ) c,
      MST_COUNTER f
    WHERE t.client_cd      = c.client_cd
    AND t.stk_cd           = f.stk_cd
    AND ((( theo_qty      <> 0
    OR onh_qty            <> 0
    OR scrip_qty          <> 0
    OR os_buy             <> 0
    OR os_sell            <> 0
    OR repo_buy_client    <> 0
    OR repo_buy_broker    <> 0
    OR repo_sell_client   <> 0
    OR repo_sell_broker   <> 0 )
    AND P_POSITION         = 'ALL' )
    OR ( (repo_buy_client <> 0
    OR repo_buy_broker    <> 0
    OR repo_sell_client   <> 0
    OR repo_sell_broker   <> 0 )
    AND P_POSITION         = 'R')
    OR ( scrip_qty        <> 0
    AND P_POSITION         = 'S')
    OR ( theo_qty          < 0
    AND P_POSITION         = 'SHORT') )
      UNION ALL
       SELECT P_DOC_DATE,
         'TXT' CLIENT_CD,
         NULL OLD_IC_NUM,
         NULL CLIENT_NAME,
         NULL BRANCH_CODE,
         NULL REM_CD,
         NULL STK_CD,
         NULL STK_NAME,
         NULL CLIENT_TYPE_1,
         NULL SUB_REK,
         NULL CUSTODIAN_CD,
         NULL THEO_QTY,
         NULL ONH_QTY,
         NULL SCRIP_QTY,
         NULL OS_BUY,
         NULL OS_SELL,
         NULL REPO_BUY_CLIENT,
         NULL REPO_BUY_BROKER,
         NULL REPO_SELL_CLIENT,
         NULL REPO_SELL_BROKER,
         P_USER_ID,
         V_RANDOM_VALUE,
         P_GENERATE_DATE,
         P_GROUP_BY,
         P_POSITION,
         NULL JAMINAN
       FROM DUAL
      ORDER BY client_Cd,
      stk_Cd
      ;
      
  EXCEPTION
  WHEN OTHERS THEN
    V_ERROR_CD  := -30;
    V_ERROR_MSG := SUBSTR('INSERT R_STOCK_POSITION_INTERNAL '||V_ERROR_MSG||SQLERRM(SQLCODE),1,200);
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
END SPR_STOCK_POSITION_INTERNAL;