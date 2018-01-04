CREATE OR REPLACE
PROCEDURE SPR_FUND_LEDGER(
    P_BGN_DATE      DATE,
    P_END_DATE      DATE,
    P_PAYREC_NUM    VARCHAR2,
    P_CLIENT_CD     VARCHAR2,
    P_USER_ID       VARCHAR2,
    P_GENERATE_DATE DATE,
    P_RANDOM_VALUE OUT NUMBER,
    P_ERROR_MSG OUT VARCHAR2,
    P_ERROR_CD OUT NUMBER)
IS
  V_ERROR_MSG    VARCHAR2(200);
  V_ERROR_CD     NUMBER(10);
  v_random_value NUMBER(10);
  V_ERR          EXCEPTION;
BEGIN

  v_random_value := ABS(dbms_random.random);
  
  BEGIN
    SP_RPT_REMOVE_RAND('R_FUND_LEDGER',V_RANDOM_VALUE,V_ERROR_MSG,V_ERROR_CD);
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
    INTO R_FUND_LEDGER
      (
        FROM_DATE,
        TO_DATE,
        DOC_NUM,
        DOC_DATE,
        FOLDER_CD,
        CLIENT_CD,
        DEBIT,
        CREDIT,
        CLIENT_NAME,
        REMARKS,
        ACCT_NAME,
        GL_ACCT_CD,
        SL_ACCT_CD,
        acct_grp,
        DB_CR,
        USER_ID,
        RAND_VALUE,
        GENERATE_DATE
      )
    SELECT P_BGN_DATE,
      P_END_DATE,
      x.payrec_num,
      x.doc_date,
      x.folder_cd,
      x.client_cd,
      x.debit,
      x.credit,
      mc.client_name,
      x.remarks,
      mf.acct_name,
      x.gl_acct_cd,
      x.sl_acct_cd,
      x.acct_grp,
      x.db_cr ,
      P_USER_ID,
      v_random_value,
      P_GENERATE_DATE
    FROM
      (SELECT t.doc_date,
        p.payrec_num,
        SUBSTR(t.acct_cd,1,1) acct_grp,
        DECODE(t.debit,0,'2C','1D') db_cr,
        t.client_cd,
        t.acct_Cd,
        t.debit,
        t.credit,
        NVL(p.remarks,h.remarks) remarks,
        NVL(p.folder_cd,h.doc_num) AS folder_cd,
        NULL GL_ACCT_CD,
        NULL SL_ACCT_CD
      FROM T_FUND_LEDGER t,
        T_FUND_MOVEMENT h,
        T_PAYRECH p
      WHERE (t.client_cd = P_CLIENT_CD
      OR P_CLIENT_CD     = 'CLIENT'
      OR P_CLIENT_CD     = 'ALL')
      AND t.doc_date BETWEEN P_BGN_DATE AND P_END_DATE
      AND t.approved_sts = 'A'
      AND t.doc_num      = h.doc_num
      AND h.doc_ref_num LIKE P_PAYREC_NUM
      AND h.doc_ref_num = p.payrec_num (+)
      UNION ALL
      SELECT t.doc_date,
        t.doc_num,
        SUBSTR(t.acct_cd,1,1) acct_grp,
        DECODE(t.debit,0,'2C','1D') db_cr,
        t.client_cd,
        t.acct_Cd,
        t.debit,
        t.credit,
        'Rvsl '
        ||NVL(p.folder_cd,h.doc_num) remarks,
        t.doc_num AS folder_cd,
        NULL GL_ACCT_CD,
        NULL SL_ACCT_CD
      FROM T_FUND_LEDGER t,
        T_FUND_MOVEMENT h,
        T_PAYRECH p
      WHERE (t.client_cd = P_CLIENT_CD
      OR P_CLIENT_CD     = 'CLIENT'
      OR P_CLIENT_CD     = 'ALL')
      AND t.doc_date BETWEEN P_BGN_DATE AND P_END_DATE
      AND t.approved_sts  = 'A'
      AND h.reversal_jur IS NOT NULL
      AND t.doc_num       = h.reversal_jur
      AND h.doc_ref_num LIKE P_PAYREC_NUM
      AND h.doc_ref_num = p.payrec_num (+)
      UNION ALL
      SELECT t.DOC_DATE,
        t.xn_doc_num,
        SUBSTR(f.FL_ACCT_cd,1,1) acct_grp,
        DECODE(f.FL_DB_CR,'D','1D','2C') db_cr,
        NVL(t.client_cd,'-') CLIENT_CD,
        f.FL_ACCT_cd,
        DECODE(f.FL_DB_CR,'D',t.curr_val,0) deb_amt,
        DECODE(f.FL_DB_CR,'C',t.curr_val,0) cre_amt,
        t.ledger_nar,
        t.folder_cd,
        t.GL_ACCT_CD,
        t.SL_ACCT_CD
      FROM
        (SELECT a.DOC_DATE,
          a.gl_acct_cd,
          a.SL_ACCT_CD,
          a.curr_val,
          a.db_cr_flg,
          a.xn_doc_num,
          DECODE(SUBSTR(a.folder_cd,1,1),'F',f.folder_cd
          ||'/'
          ||a.folder_Cd,a.folder_Cd) AS folder_cd,
          a.ledger_nar,
          p.client_cd,
          trim(b.acct_type) AS acct_type
        FROM T_ACCOUNT_LEDGER a,
          MST_GL_ACCOUNT b,
          (SELECT payrec_num               AS doc_num,
            NVL(MST_CLIENT.client_cd,'PE') AS client_cd
          FROM T_PAYRECH,
            MST_CLIENT
          WHERE payrec_date BETWEEN P_BGN_DATE AND P_END_DATE
          AND payrec_num LIKE P_PAYREC_NUM
          AND T_PAYRECH.client_Cd = MST_CLIENT.client_cd(+)
          UNION
          SELECT jvch_num AS doc_num,
            'PE'          AS client_cd
          FROM T_JVCHH
          WHERE jvch_date BETWEEN P_BGN_DATE AND P_END_DATE
          ) p,
          (SELECT doc_ref_num2,
            T_PAYRECH.folder_cd
          FROM T_FUND_MOVEMENT,
            T_PAYRECH
          WHERE doc_date BETWEEN P_BGN_DATE AND P_END_DATE
          AND doc_ref_num2 IS NOT NULL
          AND T_FUND_MOVEMENT.doc_ref_num LIKE P_PAYREC_NUM
          AND T_FUND_MOVEMENT.doc_ref_num = T_PAYRECH.payrec_num
          ) f
        WHERE a.doc_date BETWEEN P_BGN_DATE AND P_END_DATE
        AND a.approved_sts <> 'C'
        AND b.acct_type    IN ('BANK','KAS')
        AND a.GL_ACCT_CD    = b.GL_A
        AND a.SL_ACCT_CD    = b.sl_a
        AND a.xn_doc_num    = p.doc_num
        AND a.xn_doc_num    = f.doc_ref_num2 (+)
        AND (p.client_cd    = P_CLIENT_CD
        OR (P_CLIENT_CD     = 'CLIENT'
        AND p.client_cd    <> 'PE')
        OR P_CLIENT_CD      = 'ALL')
        ) t,
        (SELECT 'BANK' acct_type,
          'DPE' FL_aCCT_cd,
          'D' FL_DB_CR,
          'D' DB_CR_FLG
        FROM dual
        UNION
        SELECT 'BANK' acct_type,
          'KBPE' FL_aCCT_cd,
          'C' FL_DB_CR,
          'D' DB_CR_FLG
        FROM dual
        UNION
        SELECT 'BANK' acct_type,
          'DPE' FL_aCCT_cd,
          'C' FL_DB_CR,
          'C' DB_CR_FLG
        FROM dual
        UNION
        SELECT 'BANK' acct_type,
          'KBPE' FL_aCCT_cd,
          'D' FL_DB_CR,
          'C' DB_CR_FLG
        FROM dual
        UNION
        SELECT 'KAS' acct_type, 'DPE' FL_aCCT_cd, 'D' FL_DB_CR,'D' DB_CR_FLG FROM dual
        UNION
        SELECT 'KAS' acct_type,
          'KKPE' FL_aCCT_cd,
          'C' FL_DB_CR,
          'D' DB_CR_FLG
        FROM dual
        UNION
        SELECT 'KAS' acct_type, 'DPE' FL_aCCT_cd, 'C' FL_DB_CR,'C' DB_CR_FLG FROM dual
        UNION
        SELECT 'KAS' acct_type,
          'KKPE' FL_aCCT_cd,
          'D' FL_DB_CR,
          'C' DB_CR_FLG
        FROM dual
        ) f
      WHERE t.db_cr_flg = f.db_cr_flg
      AND t.acct_type   = f.acct_type
      ) x,
      MST_FUND_ACCT mf,
      MST_CLIENT mc
    WHERE x.acct_cd = mf.acct_cd
    AND x.client_cd = mc.client_cd (+)
    ORDER BY doc_date,
      folder_cd,
      payrec_num,
      acct_grp,
      db_cr;
  EXCEPTION
  WHEN OTHERS THEN
    V_ERROR_CD  := -30;
    V_ERROR_MSG := SUBSTR('INSERT R_FUND_LEDGER '||V_ERROR_MSG||SQLERRM(SQLCODE),1,200);
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
END SPR_FUND_LEDGER;