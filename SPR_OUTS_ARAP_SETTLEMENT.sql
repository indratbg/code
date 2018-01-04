create or replace PROCEDURE SPR_OUTS_ARAP_SETTLEMENT(
    P_AS_AT     DATE,
    P_FROM_DATE DATE,
    P_TO_DATE   DATE,
    P_BGN_CLIENT mst_client.CLIENT_CD%TYPE,
    P_END_CLIENT mst_client.CLIENT_CD%TYPE,
    P_BRANCH_CD mst_client.BRANCH_CODE%TYPE,
    P_SORT_BY       VARCHAR2,
    P_USER_ID       VARCHAR2,
    P_GENERATE_DATE DATE,
    P_RANDOM_VALUE OUT NUMBER,
    P_ERROR_CD OUT NUMBER,
    P_ERROR_MSG OUT VARCHAR2 )
IS
  V_ERROR_MSG    VARCHAR2(200);
  V_ERROR_CD     NUMBER(10);
  V_RANDOM_VALUE NUMBER(10);
  V_ERR          EXCEPTION;
  v_cnt number(5);
BEGIN

  V_RANDOM_VALUE := ABS(DBMS_RANDOM.RANDOM);
  
  BEGIN
    SP_RPT_REMOVE_RAND('R_OUTS_ARAP_SETTLEMENT',V_RANDOM_VALUE,V_ERROR_MSG,V_ERROR_CD);
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
  
  INSERT INTO TMP_OUTS_TAL_SETTLE
  SELECT trim(t.sl_acct_Cd) sl_acct_Cd,
            doc_date,
            DECODE(SUBSTR(t.xn_doc_num,6,1),'I', t.doc_ref_num,t.xn_doc_num) doc_ref_num, 
            t.tal_id AS doc_tal_id,
            doc_date AS jur_date,
            t.xn_doc_num,
            t.tal_id,
            trim(t.gl_acct_Cd) gl_acct_Cd,
            DECODE(db_Cr_flg,'D',1,-1) * curr_val AS  ori_amt,
            record_source ,
            due_date,
            t.cre_DT,
            t.budget_cd,
            t.ledger_nar,
            V_RANDOM_VALUE, P_USER_ID
          FROM T_ACCOUNT_LEDGER t,
            ( select client_cd
              from MST_CLIENT
               where client_type_1 IN ('I','C')
                 and client_cd BETWEEN P_BGN_CLIENT AND P_END_CLIENT) m
          WHERE t.sl_Acct_Cd   = m.client_Cd
          AND doc_Date BETWEEN P_FROM_DATE AND P_TO_DATE
          AND record_source IN ( 'CG','PD','RD','RVO','PVO','DNCN','GL')
          AND t.approved_sts = 'A'
          AND t.reversal_jur = 'N';
  
  
  
 INSERT INTO TMP_OUTS_TAL_SETTLE2
  SELECT trim(t.sl_acct_Cd) sl_acct_Cd,
            netting_date,
            t.doc_ref_num,
            TO_NUMBER(t.netting_flg) AS doc_tal_id,
            doc_date                 AS jur_date,
            t.xn_doc_num,
            t.tal_id,
            trim(t.gl_acct_Cd) gl_acct_Cd,
            DECODE(db_Cr_flg,'D',1,-1) * curr_val AS ori_amt,
            record_source ,
            due_date,
            t.cre_Dt,
            t.budget_cd,
            t.ledger_nar,
            V_RANDOM_VALUE, P_USER_ID
          FROM T_ACCOUNT_LEDGER t,
              ( select client_cd
              from MST_CLIENT
               where client_type_1 IN ('I','C')
                 and client_cd BETWEEN P_BGN_CLIENT AND P_END_CLIENT) m
          WHERE t.sl_Acct_Cd   = m.client_Cd
          AND doc_Date > P_FROM_DATE
          AND netting_Date BETWEEN P_FROM_DATE AND P_TO_DATE
          AND record_source          IN ( 'CDUE','MDUE')
          AND doc_ref_num            IS NOT NULL
          AND SUBSTR(ledger_nar,1,3) <> 'REV'
          AND t.approved_sts          = 'A'
          AND reversal_jur = 'N';
  
  INSERT INTO TMP_OUTS_PAYREC_SETTLE
  SELECT d.sl_acct_Cd,
            d.doc_ref_num,
            NVL(doc_tal_id, D.tal_id) doc_tal_id,
            NVL(gl_ref_num, d.doc_ref_num) gl_ref_num,
            DECODE(d.db_Cr_flg,'D',1,-1) * payrec_amt payrec_amt,
            d.payrec_date,
            d.payrec_num ,
            d.tal_id,
            T_ACCOUNT_LEDGER.gl_acct_Cd,
            d.cre_dt ,
            h.folder_cd,
            V_RANDOM_VALUE, P_USER_ID
          FROM T_PAYRECD d,
            T_PAYRECH h,
            T_ACCOUNT_LEDGER
          WHERE d.payrec_date BETWEEN P_FROM_DATE AND P_AS_AT
          AND d.payrec_type IN ('RV','PV')
          AND d.payrec_num   = h.payrec_num
          AND D.sl_Acct_Cd BETWEEN P_BGN_CLIENT AND P_END_CLIENT
          AND d.record_source <> 'VCH'
          AND d.record_source <> 'ARAP'
          AND D.approved_sts   = 'A'
          AND gl_ref_num       = xn_doc_num
          AND D.tal_id         = T_ACCOUNT_LEDGER.tal_id;
  

  BEGIN
    INSERT
    INTO R_OUTS_ARAP_SETTLEMENT
      (
        CLIENT_CD ,
        CLIENT_NAME ,
        BRANCH_CODE ,
        OLD_IC_NUM ,
        DOC_DATE ,
        LEDGER_NAR ,
        ORI_AMT ,
        PAYREC_AMT ,
        OUTS_DET ,
        PAYREC_DATE ,
        FOLDER_CD ,
        PAYREC_NUM ,
        DOC_REF_NUM ,
        SEQNO ,
        SUM_OUTS ,
        FROM_DATE ,
        TO_DATE ,
        USER_ID ,
        RAND_VALUE ,
        GENERATE_DATE,
        AS_AT
      )
    SELECT client_Cd,
      client_name,
      branch_code,
      old_ic_num,
      doc_date,
      ledger_nar,
      ori_amt,
      payrec_amt,
      outs_det,
      payrec_date,
      folder_cd,
      payrec_num,
      doc_ref_num,
      seqno,
      SUM(DECODE(seqno,1, ori_amt,0) + NVL(payrec_amt, 0)) over (PARTITION BY client_cd) AS sum_outs,
      P_FROM_DATE,
      P_TO_DATE,
      P_USER_ID,
      V_RANDOM_VALUE,
      P_GENERATE_DATE,
      P_AS_AT
    FROM
      (SELECT client_Cd,
        client_name,
        branch_code,
        old_ic_num,
        doc_date,
        ledger_nar,
        ori_amt,
        payrec_amt,
        ori_amt +cum_pay AS outs_det,
        payrec_date,
        folder_cd,
        payrec_num,
        doc_ref_num,
        doc_tal_id,
        row_number( ) over (PARTITION BY doc_ref_num, doc_tal_id ORDER BY doc_ref_num, doc_tal_id, payrec_date, cre_dt) AS seqno
      FROM
        (SELECT t.sl_acct_Cd,
          t.doc_date,
          t.doc_ref_num,
          t.doc_tal_id,
          p.payrec_date payrec_date,
          p.cre_dt,
          TO_CHAR(NVL(p.payrec_date, t.jur_date),'yyyymmdd' )
          ||TO_CHAR(NVL(p.cre_dt,t.cre_dt),'yyyymmdd hh24:mi:ss') pdate,
          t.ori_amt,
          DECODE(trim(t.budget_cd),'REKLAS',- t.ori_amt ,p.payrec_amt) payrec_amt,
          p.gl_ref_num,
          p.payrec_num,
          trim(NVL(p.gl_acct_cd, t.gl_acct_cd)) gl_acct_cd ,
          t.ledger_nar,
          folder_cd,
          SUM( NVL(payrec_amt,0)+ DECODE(trim(t.budget_cd),'REKLAS',- t.ori_amt ,0)) over (PARTITION BY t.sl_acct_cd, t.doc_date, t.doc_ref_num, t.doc_tal_id)   AS sett_amt,
          SUM( NVL(payrec_amt,0)+ DECODE(trim(t.budget_cd),'REKLAS',- t.ori_amt ,0)) over (PARTITION BY t.sl_acct_cd, t.doc_date, t.doc_ref_num, t.doc_tal_id 
              ORDER BY t.sl_acct_cd, t.doc_date, t.doc_ref_num, t.doc_tal_id, payrec_date, p.cre_dt) AS cum_pay,
          MAX( TO_CHAR(NVL(p.payrec_date, t.jur_date),'yyyymmdd' )
          ||TO_CHAR(NVL(p.cre_dt,t.cre_dt),'yyyymmdd hh24:mi:ss')) over (PARTITION BY t.sl_acct_cd, t.doc_date, t.doc_ref_num, t.doc_tal_id) AS max_pdate
        FROM
          ( 
          SELECT * FROM TMP_OUTS_TAL_SETTLE where rand_value=V_RANDOM_VALUE and USER_ID=P_USER_ID
          UNION ALL
          SELECT * FROM TMP_OUTS_TAL_SETTLE2 where rand_value=V_RANDOM_VALUE and USER_ID=P_USER_ID
          ) T,
          (
          SELECT * FROM TMP_OUTS_PAYREC_SETTLE where rand_value=V_RANDOM_VALUE and USER_ID=P_USER_ID
          ) p
        WHERE t.sl_acct_Cd = p.sl_acct_Cd (+)
        AND t.doc_ref_num  = p.doc_ref_num (+)
        AND t.doc_tal_id   = p.doc_tal_id(+)
        AND t.xn_doc_num   = p.gl_ref_num(+)
        AND t.tal_id       = p.tal_id(+)
        ) ,
        (SELECT client_cd,
          client_name,
          old_ic_num,
          branch_code
        FROM MST_CLIENT
        WHERE TRIM(branch_code) LIKE TRIM(P_BRANCH_CD)
        )
      WHERE ( sett_Amt = 0 OR payrec_date  IS NOT NULL)
      AND (( pdate     = max_pdate AND payrec_date IS NULL)
              OR payrec_date  IS NOT NULL)
      AND sl_acct_Cd   = client_cd
      ) ORDER BY client_cd, doc_date, doc_ref_num, doc_tal_id, seqno;
  EXCEPTION
  WHEN OTHERS THEN
    V_ERROR_CD  := -50;
    V_ERROR_MSG := SUBSTR('INSERT R_OUTS_ARAP_SETTLEMENT '||V_ERROR_MSG||SQLERRM(SQLCODE),1,200);
    RAISE V_err;
  END;
  
  --delete table temp
delete from TMP_OUTS_PAYREC_SETTLE where rand_value=V_RANDOM_VALUE and USER_ID=P_USER_ID;
delete from TMP_OUTS_TAL_SETTLE2 where rand_value=V_RANDOM_VALUE and USER_ID=P_USER_ID;
delete from TMP_OUTS_TAL_SETTLE where rand_value=V_RANDOM_VALUE and USER_ID=P_USER_ID;
  
  
  
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
END SPR_OUTS_ARAP_SETTLEMENT;