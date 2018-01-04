create or replace PROCEDURE SPR_STOCK_HISTORY(
    P_BGN_DATE      DATE,
    P_END_DATE      DATE,
    P_ON_HAND       VARCHAR2,
    P_BGN_CLIENT    VARCHAR2,
    P_END_CLIENT    VARCHAR2,
    P_BGN_STOCK     VARCHAR2,
    P_END_STOCK     VARCHAR2,
    P_BGN_REM       VARCHAR2,
    P_END_REM       VARCHAR2,
    P_USER_ID       VARCHAR2,
    P_GENERATE_DATE DATE,
    P_RANDOM_VALUE OUT NUMBER,
    P_ERROR_CD OUT NUMBER,
    P_ERROR_MSG OUT VARCHAR2 )
IS
  V_ERROR_MSG    VARCHAR2(200);
  V_ERROR_CD     NUMBER(10);
  v_random_value NUMBER(10);
  V_ERR          EXCEPTION;
  V_BAL_DT       DATE;
BEGIN

  v_random_value := ABS(dbms_random.random);
  
  BEGIN
    SP_RPT_REMOVE_RAND('R_STOCK_HISTORY',V_RANDOM_VALUE,V_ERROR_MSG,V_ERROR_CD);
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
  
  V_BAL_DT :=P_BGN_DATE - TO_CHAR(P_BGN_DATE,'DD') +1;
  
  insert into tmp_stk_hist1
  SELECT doc_num,
          doc_dt,
          client_cd,
          NVL(C.STK_CD_NEW,STK_CD)stk_cd,
          status,
          DECODE(db_cr_flg,'D',1,-1) * DECODE(NVL(trim(gl_acct_cd),'36'),'36',-1,1) * (total_share_qty + withdrawn_share_qty) L_qty,
          0 F_qty,
          due_dt_for_cert AS due_date,
          DECODE(SUBSTR(doc_num,5,3),'JVB','BUY','JVS','SELL','JXB','BUY','JXS','SELL','JVA','REPO','JRR','REPO','BRR','REPO',
          DECODE(SUBSTR(trim(doc_num),5,1),'B','BUY','J','SELL','R','RECEIVE','W','WITHDRAW',SUBSTR(trim(doc_num),5,1))) Trx_cd,
          trim(doc_rem) doc_rem,
          price,
          NVL(approved_dt,cre_dt) cre_dt,
          v_random_value,
          P_USER_ID
        FROM t_stk_movement,
         (select stk_cd_new,stk_cd_old from t_change_stk_cd where eff_dt<=P_END_DATE)c
        WHERE doc_dt BETWEEN P_BGN_DATE AND P_END_DATE
        AND STK_CD=C.STK_CD_OLD(+)
        AND  nvl(c.stk_cd_new,stk_cd) BETWEEN P_BGN_STOCK AND P_END_STOCK
        AND client_cd                 >= P_BGN_CLIENT
        AND client_cd                 <= P_END_CLIENT
        AND (( SUBSTR(doc_num,5,2)    IN ('BR','JR','BI','JI','BO','JO','RS','WS')
        AND P_ON_HAND                  = 'N')
        OR ( SUBSTR(doc_num,5,2)      IN ('LS','XS','JV','JX','RS','WS','CS')
        AND P_ON_HAND                  = 'Y'))
        AND ((gl_acct_cd              IN ('14','51','12','13','10')
        AND P_ON_HAND                  = 'N' )
        OR (NVL(trim(gl_acct_cd),'36') = '36'
        AND P_ON_HAND                  = 'Y'))
        AND doc_stat                   = '2';
  
  insert into tmp_stk_hist2
SELECT '00' doc_num,
          NULL doc_dt,
          client_cd,
           NVL(C.STK_CD_NEW,STK_CD)stk_cd,
          'L' status,
          0 L_qty,
          0 F_qty,
          NULL AS due_date,
          NULL Trx_cd,
          'No transaction' doc_rem,
          0 price,
          NULL cre_dt,
          v_random_value,
          P_USER_ID
        FROM T_stkhand,
          (select stk_cd_new,stk_cd_old from t_change_stk_cd where eff_dt<=P_END_DATE)c
        WHERE  nvl(c.stk_cd_new,stk_cd) BETWEEN P_BGN_STOCK AND P_END_STOCK
         AND STK_CD=C.STK_CD_OLD(+)
        AND client_cd >= P_BGN_CLIENT
        AND client_cd <= P_END_CLIENT;  
  
  insert into tmp_stk_hist_qty1
  SELECT client_cd,
            NVL(C.STK_CD_NEW,STK_CD)stk_cd,
            DECODE(l_f,'L',DECODE(P_ON_HAND,'Y',beg_on_hand,beg_bal_qty),0) L_beg_qty,
            DECODE(l_f,'F',DECODE(P_ON_HAND,'Y',beg_on_hand,beg_bal_qty),0) F_beg_qty,
            v_random_value,
          P_USER_ID
          FROM T_stkbal,
           (select stk_cd_new,stk_cd_old from t_change_stk_cd where eff_dt<=P_END_DATE)c
          WHERE bal_dt     = V_BAL_DT
             AND  nvl(c.stk_cd_new,stk_cd) BETWEEN P_BGN_STOCK AND P_END_STOCK
           AND STK_CD=C.STK_CD_OLD(+)
          AND client_cd   >= P_BGN_CLIENT
          AND client_cd   <= P_END_CLIENT
          AND (beg_bal_qty > 0
          OR beg_on_hand   > 0);
  
  INSERT into tmp_stk_hist_qty2
    SELECT client_cd,
            NVL(C.STK_CD_NEW,STK_CD) stk_cd,
            0 L_beg_qty,
            0 F_beg_qty,
            v_random_value,
          P_USER_ID
          FROM T_stkhand,
           (select stk_cd_new,stk_cd_old from t_change_stk_cd where eff_dt<=P_END_DATE)c
          WHERE  nvl(c.stk_cd_new,stk_cd) BETWEEN P_BGN_STOCK AND P_END_STOCK
           AND STK_CD=C.STK_CD_OLD(+)
          AND client_cd >= P_BGN_CLIENT
          AND client_cd <= P_END_CLIENT;
  
  insert into tmp_stk_hist_qty3
   SELECT client_cd,
            NVL(C.STK_CD_NEW,STK_CD) stk_cd,
            DECODE(status,'L',NVL(DECODE(db_cr_flg,'D',1,-1) * DECODE(NVL(trim(gl_acct_cd),'36'),'36',-1,1) * (total_share_qty + withdrawn_share_qty),0),0) l_e_qty,
            DECODE(status,'F',NVL(DECODE(db_cr_flg,'D',1,-1) * DECODE(NVL(trim(gl_acct_cd),'36'),'36',-1,1) * (total_share_qty + withdrawn_share_qty),0),0) f_e_qty,
            v_random_value,
          P_USER_ID
          FROM t_stk_movement,
           (select stk_cd_new,stk_cd_old from t_change_stk_cd where eff_dt<=P_END_DATE)c
          WHERE doc_dt                  >= V_BAL_DT
          AND doc_dt                     < P_BGN_DATE
           AND STK_CD=C.STK_CD_OLD(+)
          AND  nvl(c.stk_cd_new,stk_cd) BETWEEN P_BGN_STOCK AND P_END_STOCK
          AND client_cd                 >= P_BGN_CLIENT
          AND client_cd                 <= P_END_CLIENT
          AND (( SUBSTR(doc_num,5,2)    IN ('BR','JR','BI','JI','BO','JO','RS','WS')
          AND P_ON_HAND                  = 'N')
          OR ( SUBSTR(doc_num,5,2)      IN ('LS','XS','JV','JX','RS','WS','CS')
          AND P_ON_HAND                  = 'Y'))
          AND ((gl_acct_cd              IN ('14','51','12','13','10')
          AND P_ON_HAND                  = 'N' )
          OR (NVL(trim(gl_acct_cd),'36') = '36'
          AND P_ON_HAND                  = 'Y'))
          AND doc_stat                   = '2';
  
  
  
  BEGIN
    INSERT
    INTO R_STOCK_HISTORY
      (
        FROM_DATE ,
        TO_DATE ,
        DOC_NUM ,
        CLIENT_CD ,
        CLIENT_NAME ,
        CLIENT_TYPE ,
        SUBREK ,
        CUSTODIAN_CD ,
        BRANCH_CODE ,
        STK_CD ,
        L_STK_QTY ,
        F_STK_QTY ,
        BAL_AMT ,
        TRX_BS ,
        TRX_DESC ,
        DOC_DT ,
        CRE_DT ,
        STATUS ,
        PRICE ,
        SUM_DET ,
        SUM_BAL ,
        DUE_DATE ,
        USER_ID ,
        RAND_VALUE ,
        GENERATE_DATE,
        IC_NUM,
        stk_desc
      )
      
    SELECT P_BGN_DATE,
      P_END_DATE,
      DOC_NUM,
      CLIENT_CD,
      CLIENT_NAME ,
      CLIENT_TYPE ,
      SUBREK ,
      CUSTODIAN_CD ,
      BRANCH_CODE ,
      STK_CD ,
      L_STK_QTY ,
      F_STK_QTY ,
      BAL_AMT ,
      TRX_BS ,
      TRX_DESC ,
      DOC_DT ,
      CRE_DT ,
      STATUS ,
      PRICE ,
      SUM_DET ,
      SUM_BAL ,
      DUE_DATE,
      P_USER_ID,
      V_RANDOM_VALUE,
      P_GENERATE_DATE,
      OLD_IC_NUM,
      stk_desc
    FROM
      (SELECT a.doc_num,
        a.client_cd,
        d.client_name client_name,
        d.client_type_1
        ||d.client_type_2
        ||d.client_type_3 client_type,
        S.SUBREK14 subrek,
        d.custodian_cd,
        D.BRANCH_CODE,
        a.stk_cd,
        L_qty l_stk_qty,
        F_qty f_stk_qty,
        SUM(a.l_qty) over ( PARTITION BY a.client_Cd, a.stk_cd ORDER BY a.client_Cd, a.stk_cd, a.doc_dt, a.cre_dt, a.doc_num) bal_amt,
        trx_cd trx_bs,
        trim(a.doc_rem) trx_desc,
        TRUNC(a.doc_dt) doc_dt,
        a.cre_dt,
        a.status,
        a.price,
        SUM( DECODE(trx_cd, NULL,0,ABS(l_qty))) over ( PARTITION BY a.client_Cd, a.stk_cd ) sum_det,
        SUM( DECODE(trx_cd, NULL,ABS(l_qty),0)) over ( PARTITION BY a.client_Cd, a.stk_cd ) sum_bal ,
        due_date,
        D.OLD_IC_NUM,
        f.stk_desc
      FROM
        ( select * from tmp_stk_hist1 where rand_value=v_random_value and USER_ID=P_USER_ID
        UNION ALL
         select * from tmp_stk_hist2 where rand_value=v_random_value and USER_ID=P_USER_ID
        UNION ALL
        SELECT '0' doc_num,
          TO_DATE('01/01/2000','dd/mm/yyyy') AS doc_dt,
          client_cd,
          stk_cd,
          'L' l_f,
          SUM(l_beg_qty) L_beg_qty,
          SUM(F_beg_qty) f_beg_qty,
          NULL AS due_date,
          NULL trx_Cd,
          'BEG BAL' AS doc_rem,
          0 price ,
          NULL cre_dt,
          v_random_value,
          p_user_id
        FROM
          (select * from tmp_stk_hist_qty1 where rand_value=v_random_value and USER_ID=P_USER_ID
          UNION ALL
         select * from tmp_stk_hist_qty2 where rand_value=v_random_value and USER_ID=P_USER_ID
          UNION ALL
         select * from tmp_stk_hist_qty3 where rand_value=v_random_value and USER_ID=P_USER_ID
          )
        GROUP BY client_cd,
          stk_cd
        ) a,
        mst_client d,
        mst_counter f,
        V_CLIENT_SUBREK14 S
      WHERE a.client_cd = d.client_cd(+)
      AND a.stk_cd      = f.stk_cd
      AND a.client_cd   = S.client_cd(+)
      AND trim(d.rem_cd) between p_bgn_rem and p_end_rem
      )
    WHERE (sum_det > 0
    OR sum_bal     > 0)
    ORDER BY client_Cd,
      stk_Cd,
      doc_dt ,
      cre_dt,
      doc_num ;
  EXCEPTION
  WHEN OTHERS THEN
    V_ERROR_CD  := -30;
    V_ERROR_MSG := SUBSTR('INSERT R_STOCK_HISTORY '||SQLERRM(SQLCODE),1,200);
    RAISE V_err;
  END;
  
    --delete table temp
    delete from TMP_STK_HIST1 where rand_value=v_random_value and user_id=p_user_id;
    delete from TMP_STK_HIST2 where rand_value=v_random_value and user_id=p_user_id;
    delete from TMP_STK_HIST_QTY1 where rand_value=v_random_value and user_id=p_user_id;
    delete from TMP_STK_HIST_QTY2 where rand_value=v_random_value and user_id=p_user_id;
    delete from tmp_STK_HIST_QTY3 where rand_value=v_random_value and user_id=p_user_id;

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
END SPR_STOCK_HISTORY;