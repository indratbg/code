create or replace PROCEDURE SPR_OUTS_ARAP_CLIENT(
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

    VP_AS_AT     DATE;
    VP_FROM_DATE DATE;
    VP_TO_DATE   DATE;
    VP_BGN_CLIENT mst_client.CLIENT_CD%TYPE;
    VP_END_CLIENT mst_client.CLIENT_CD%TYPE;
    VP_BRANCH_CD VARCHAR2(3);

  V_ERROR_MSG    VARCHAR2(200);
  V_ERROR_CD     NUMBER(10);
  V_RANDOM_VALUE NUMBER(10);
  V_ERR          EXCEPTION;
BEGIN

  v_random_value := ABS(dbms_random.random);
  
  BEGIN
    SP_RPT_REMOVE_RAND('R_OUTS_ARAP_CLIENT',V_RANDOM_VALUE,V_ERROR_MSG,V_ERROR_CD);
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
  
  VP_AS_AT := P_AS_AT;
  VP_FROM_DATE := P_FROM_DATE;
  VP_TO_DATE   := P_TO_DATE;
  VP_BGN_CLIENT := P_BGN_CLIENT;
  VP_END_CLIENT := P_END_CLIENT;
  VP_BRANCH_CD := trim(P_BRANCH_CD)||'%';
  
  begin
  select begin_Date into VP_FROM_DATE
  from T_BEGIN_ARAP_OUTSTAND
  where VP_BGN_CLIENT = client_Cd;
  exception
  when no_data_found then
   select max(vp_from_date) into VP_FROM_DATE
    from(
    select last_day(max(begin_date)) + 1 as VP_FROM_DATE
    from T_BEGIN_ARAP_OUTSTAND
    union all
    select P_FROM_DATE from dual);
  end;
  
  ---TAL BAGIAN 1
  INSERT INTO TMP_OUTS_TAL
  SELECT trim(t.sl_acct_Cd) sl_acct_Cd,
          doc_date,
          DECODE(SUBSTR(t.xn_doc_num,6,1),'I', t.doc_ref_num,t.xn_doc_num) doc_ref_num,
          t.tal_id AS doc_tal_id,
          doc_date AS jur_date,
          t.xn_doc_num,
          t.tal_id,
          trim(t.gl_acct_Cd) gl_acct_Cd,
          DECODE(db_Cr_flg,'D',1,-1) * curr_val AS ori_amt,
          record_source ,
          due_date,
          t.cre_DT,
          t.budget_cd,
          t.ledger_nar,
          t.folder_cd,
          M.OLD_IC_NUM,
          M.CLIENT_NAME,
          m.branch_code,
          RAND_VALUE,
          P_USER_ID
        FROM T_ACCOUNT_LEDGER t,
          ( select client_Cd, client_name, branch_code, old_ic_num
              from MST_CLIENT 
            where client_Cd BETWEEN VP_BGN_CLIENT AND VP_END_CLIENT 
            and client_type_1 IN ('I','C')
            and branch_code like vp_branch_cd) m
        WHERE t.sl_Acct_Cd   = m.client_Cd
        AND doc_Date BETWEEN VP_FROM_DATE AND VP_TO_DATE
        AND record_source IN ( 'CG','PD','RD','RVO','PVO','DNCN','GL','INT')
        AND reversal_jur   = 'N'
        AND t.approved_sts = 'A';
        
 ---TAL BAGIAN 2
 INSERT  INTO TMP_OUTS_TAL2
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
          t.ledger_nar ,
          folder_cd,
          M.OLD_IC_NUM,
          M.CLIENT_NAME,
          m.branch_code,
          RAND_VALUE,
          P_USER_ID
        FROM T_ACCOUNT_LEDGER t,
         ( select client_Cd, client_name, branch_code, old_ic_num
              from MST_CLIENT 
            where client_Cd BETWEEN VP_BGN_CLIENT AND VP_END_CLIENT 
            and client_type_1 IN ('I','C')
            and branch_code like vp_branch_cd) m
        WHERE t.sl_Acct_Cd   = m.client_Cd
        AND doc_Date BETWEEN VP_FROM_DATE AND VP_TO_DATE
        AND netting_Date           >= VP_FROM_DATE
        AND record_source          IN ( 'CDUE','MDUE')
        AND doc_ref_num            IS NOT NULL
        AND SUBSTR(ledger_nar,1,3) <> 'REV'
        AND reversal_jur            = 'N'
        AND t.approved_sts          = 'A';
  
  -- BAGIAN PAYRECH
  INSERT INTO TMP_OUTS_PAYREC
  SELECT d.sl_acct_Cd,
          d.doc_ref_num,
          NVL(doc_tal_id, D.tal_id) doc_tal_id,
          NVL(gl_ref_num, d.doc_ref_num) gl_ref_num,
          DECODE(d.db_Cr_flg,'D',1,-1) * payrec_amt payrec_amt,
          d.payrec_date,
          d.payrec_num ,
          d.tal_id,
          T_ACCOUNT_LEDGER.gl_acct_Cd,
          d.cre_dt,
          RAND_VALUE,
          P_USER_ID
        FROM T_PAYRECD d,
          T_PAYRECH h,
          T_ACCOUNT_LEDGER
        WHERE d.payrec_date BETWEEN VP_FROM_DATE AND VP_TO_DATE
        AND d.payrec_type IN ('RV','PV')
        AND d.payrec_num   = h.payrec_num
        AND D.sl_Acct_Cd BETWEEN VP_BGN_CLIENT AND VP_END_CLIENT
        AND d.record_source <> 'VCH'
        AND d.record_source <> 'ARAP'
          --AND d.doc_ref_num =  '1214BR0070201'
        AND D.approved_sts = 'A'
        AND gl_ref_num     = xn_doc_num
        AND D.tal_id       = T_ACCOUNT_LEDGER.tal_id;
  
  BEGIN
    INSERT
    INTO R_OUTS_ARAP_CLIENT
      (
        CLIENT_CD ,
        DOC_DATE ,
        LEDGER_NAR ,
        FOLDER_CD ,
        DUE_DATE ,
        ORI_AMT ,
        OUTS_AMT ,
        GL_ACCT_CD ,
        DOC_REF_NUM ,
        CLIENT_NAME,
        old_ic_num,
        BRANCH_CD ,
        FROM_DATE ,
        TO_DATE ,
        USER_ID ,
        RAND_VALUE ,
        GENERATE_DATE ,
         SORT_BY
      )
    SELECT sl_acct_Cd,
      doc_date,
      ledger_nar,
      folder_cd,
      due_date,
      ori_amt,
      DECODE(ori_amt +sett_amt , ori_amt +cum_pay , ori_amt +cum_pay , 0) AS outs_amt ,
      gl_acct_cd ,
      doc_ref_num,
      CLIENT_NAME,
      OLD_IC_NUM,
      branch_code,
      VP_FROM_DATE,
      VP_TO_DATE,
      P_USER_ID,
      V_RANDOM_VALUE,
      P_GENERATE_DATE,
      P_SORT_BY  
    FROM
      (SELECT t.sl_acct_Cd,
        t.doc_date,
        t.doc_ref_num,
        t.doc_tal_id,
        NVL(p.payrec_date, t.jur_date) payrec_date,
        p.cre_dt,
        TO_CHAR(NVL(p.payrec_date, t.jur_date),'yyyymmdd' )
        ||TO_CHAR(NVL(p.cre_dt,t.cre_dt),'yyyymmdd hh24:mi:ss') pdate,
        t.ori_amt,
        DECODE(trim(t.budget_cd),'REKLAS',- t.ori_amt ,p.payrec_amt) payrec_amt,
        p.gl_ref_num,
        p.payrec_num,
        trim(NVL(p.gl_acct_cd, t.gl_acct_cd)) gl_acct_cd ,
        t.ledger_nar,
        t.due_date,
        t.folder_cd,
        SUM( NVL(payrec_amt,0)+ DECODE(trim(t.budget_cd),'REKLAS',- t.ori_amt ,0)) over (PARTITION BY t.sl_acct_cd, t.doc_date, t.doc_ref_num, t.doc_tal_id)   AS sett_amt,
        SUM( NVL(payrec_amt,0)+ DECODE(trim(t.budget_cd),'REKLAS',- t.ori_amt ,0)) over (PARTITION BY t.sl_acct_cd, t.doc_date, t.doc_ref_num, t.doc_tal_id 
           ORDER BY t.sl_acct_cd, t.doc_date, t.doc_ref_num, t.doc_tal_id, payrec_date, p.cre_dt) AS cum_pay,
        MAX( TO_CHAR(NVL(p.payrec_date, t.jur_date),'yyyymmdd' )
        ||TO_CHAR(NVL(p.cre_dt,t.cre_dt),'yyyymmdd hh24:mi:ss')) over (PARTITION BY t.sl_acct_cd, t.doc_date, t.doc_ref_num, t.doc_tal_id) AS max_pdate ,
        T.OLD_IC_NUM,
        T.CLIENT_NAME,
        t.branch_code
      FROM
        (SELECT * FROM TMP_OUTS_TAL WHERE RAND_VALUE=V_RANDOM_VALUE AND USER_ID=P_USER_ID
        UNION ALL
        SELECT * FROM TMP_OUTS_TAL2  WHERE RAND_VALUE=V_RANDOM_VALUE AND USER_ID=P_USER_ID
        ) T,
        (SELECT * FROM TMP_OUTS_PAYREC  WHERE RAND_VALUE=V_RANDOM_VALUE AND USER_ID=P_USER_ID
        ) p
      WHERE t.sl_acct_Cd = p.sl_acct_Cd (+)
      AND t.doc_ref_num  = p.doc_ref_num (+)
      AND t.doc_tal_id   = p.doc_tal_id(+)
      AND t.xn_doc_num   = p.gl_ref_num(+)
      AND t.tal_id       = p.tal_id(+)
      )
    WHERE ( sett_Amt          = 0
    OR payrec_date           IS NOT NULL)
    AND ( pdate               = max_pdate
    OR payrec_date           IS NULL)
    AND (ori_amt +sett_amt ) <> 0
    ORDER BY sl_acct_Cd,
      doc_date,
      doc_ref_num;
  EXCEPTION
  WHEN OTHERS THEN
    V_ERROR_CD  := -50;
    V_ERROR_MSG := SUBSTR('INSERT R_OUTS_ARAP_CLIENT '||V_ERROR_MSG||SQLERRM(SQLCODE),1,200);
    RAISE V_err;
  END;
  --DELETE TABEL TEMP
  DELETE FROM TMP_OUTS_PAYREC WHERE RAND_VALUE=V_RANDOM_VALUE AND USER_ID=P_USER_ID;
  DELETE FROM TMP_OUTS_TAL2 WHERE RAND_VALUE=V_RANDOM_VALUE AND USER_ID=P_USER_ID;
  DELETE FROM TMP_OUTS_TAL WHERE RAND_VALUE=V_RANDOM_VALUE AND USER_ID=P_USER_ID;

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
END SPR_OUTS_ARAP_CLIENT;