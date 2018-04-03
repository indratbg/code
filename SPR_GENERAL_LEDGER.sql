create or replace PROCEDURE SPR_GENERAL_LEDGER(
    dt_bgn_date DATE,
    dt_end_date DATE,
    as_bgn_acct T_ACCOUNT_LEDGER.GL_ACCT_cD%TYPE,
    as_end_acct T_ACCOUNT_LEDGER.GL_ACCT_cD%TYPE,
    as_bgn_sub T_ACCOUNT_LEDGER.SL_ACCT_CD%TYPE,
    as_end_sub T_ACCOUNT_LEDGER.SL_ACCT_CD%TYPE,
    as_bgn_branch VARCHAR2,
    as_reversal     VARCHAR2,
    P_MODE          VARCHAR2,
    P_USER_ID       VARCHAR2,
    P_GENERATE_DATE DATE,
    P_RANDOM_VALUE OUT NUMBER,
    P_ERROR_CD OUT NUMBER,
    P_ERROR_MSG OUT VARCHAR2 )
AS

--4sep17 order by dihapus, krn sdh ada di appl, REGULAR : ORDER BY sortk1, doc-date, seqno
--                                                                    BY ACCT, order by GLacct, doc-date

  V_ERR          EXCEPTION;
  V_ERROR_CD     NUMBER(5);
  V_ERROR_MSG    VARCHAR2(200);
  v_random_value NUMBER(10);
  dt_begin_bal   DATE;
  DT_BGN_MIN1    DATE;
BEGIN

  v_random_value := ABS(dbms_random.random);
  dt_begin_bal := TO_DATE('01'||TO_CHAR(dt_bgn_date,'MMYYYY'),'DDMMYYYY');

  IF P_MODE       ='REGULAR' THEN
    BEGIN
      SP_RPT_REMOVE_RAND('R_GENERAL_LEDGER_REG',V_RANDOM_VALUE,V_ERROR_MSG,V_ERROR_CD);
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
    
 
    DT_BGN_MIN1  := DT_BGN_DATE-1;
    --25SEP2017
    BEGIN
    INSERT INTO TMP_GL_1
        SELECT DECODE(b.reversal_jur,'N','','1') sort_doc_num,
              ' ' xn_doc_num,
              0 tal_id,
              ' ' folder_cd,
              b.doc_date,
              b.gl_acct_cd,
              b.sl_acct_cd,
              b.db_cr_flg,
              SUM(b.curr_val) curr_val,
              b.ledger_nar
              ||DECODE(b.doc_date,b.due_date,' TN') ledger_nar,
              b.doc_date cre_dt,
              V_RANDOM_VALUE,
              P_USER_ID
            FROM T_ACCOUNT_LEDGER b,
              (SELECT MST_GL_ACCOUNT.gl_A,
                MST_GL_ACCOUNT.sl_a,
                brch_cd,
                NVL(jur_type,'NONTRX') jur_type
              FROM MST_GL_ACCOUNT,
                (SELECT gl_a, jur_type FROM mst_gla_trx WHERE jur_type = 'TRX'
                ) g
              WHERE TRIM(mst_gl_account.gl_a) = g.gl_a(+)
              AND  TRIM(mst_gl_account.gl_a) BETWEEN trim(as_bgn_acct) AND trim(as_end_acct)
               AND MST_GL_ACCOUNT.sl_a BETWEEN as_bgn_sub AND as_end_sub
              --AND NVL(acct_type,'123456') = 'LRTHIS' --31AUG2016
              AND ( ( mst_gl_account.brch_cd = as_bgn_branch and as_bgn_branch <> '%') OR as_bgn_branch = '%' )
              AND mst_gl_account.prt_type <> 'S'
              ) m
            WHERE trim(b.gl_acct_cd) BETWEEN trim(as_bgn_acct) AND trim(as_end_acct)
            AND b.sl_acct_cd BETWEEN as_bgn_sub AND as_end_sub
            AND b.doc_date BETWEEN dt_bgn_date AND dt_end_date
            AND b.approved_sts   = 'A'
            AND TRIM(B.GL_ACCT_cD)     = TRIM(M.GL_A)
            AND B.SL_ACCT_CD     = M.SL_A
            AND m.jur_type       = 'TRX'
            AND b.record_source  = 'CG'
            --17oct16AND ( b.reversal_jur = 'Y'
            --    OR ( b.reversal_jur <> 'N' AND as_reversal      = 'N') )
            GROUP BY b.doc_date,
              b.gl_acct_cd,
              b.sl_acct_cd,
              DECODE(b.reversal_jur,'N','','1') ,
              b.db_cr_flg,
              b.ledger_nar,
              b.due_date;
     EXCEPTION
    WHEN OTHERS THEN
      V_ERROR_CD  :=-3;
      V_ERROR_MSG := SUBSTR('INSERT INTO TMP_GL_1 '||SQLERRM(SQLCODE),1,200);
      RAISE V_ERR;
    END;
    --25SEP2017
    BEGIN
    INSERT INTO TMP_GL_2
      SELECT a.xn_doc_num,
              a.xn_doc_num,
              a.tal_id,
              a.folder_cd,
              a.doc_date,
              a.gl_acct_cd,
              a.sl_acct_cd,
              a.db_cr_flg,
              a.curr_val,
              a.ledger_nar,
              a.cre_dt,
              V_RANDOM_VALUE,
              P_USER_ID
            FROM T_ACCOUNT_LEDGER a,
              (SELECT MST_GL_ACCOUNT.gl_A,
                MST_GL_ACCOUNT.sl_a,
                brch_cd,
                NVL(jur_type,'NONTRX') jur_type
              FROM MST_GL_ACCOUNT,
                (SELECT gl_a, jur_type FROM mst_gla_trx WHERE jur_type = 'TRX'
                ) g
              WHERE TRIM(mst_gl_account.gl_a) = g.gl_a(+)
                AND  TRIM(mst_gl_account.gl_a) BETWEEN trim(as_bgn_acct) AND trim(as_end_acct)
               AND MST_GL_ACCOUNT.sl_a BETWEEN as_bgn_sub AND as_end_sub
              --    AND NVL(acct_type,'123456') = 'LRTHIS' --31AUG2016
              AND ( (mst_gl_account.brch_cd = as_bgn_branch and as_bgn_branch<>'%')  OR as_bgn_branch = '%' )
              AND mst_gl_account.prt_type <> 'S'
              ) m
            WHERE trim(a.gl_acct_cd) BETWEEN trim(as_bgn_acct) AND trim(as_end_acct)
            AND a.sl_acct_cd BETWEEN as_bgn_sub AND as_end_sub
            AND a.doc_date BETWEEN dt_bgn_date AND dt_end_date
            AND a.approved_sts = 'A'
            AND TRIM(A.GL_ACCT_cD)     = TRIM(M.GL_A)
            AND A.SL_ACCT_CD     = M.SL_A
            AND record_source   <> 'RE'
            AND (m.jur_type      = 'NONTRX'  OR ( m.jur_type      = 'TRX' AND a.record_source <> 'CG'  )) --17oct16
             --17oct16AND record_source   <> 'RE'
            --17oct16AND (reversal_jur    = 'N' OR as_reversal       = 'Y')
            ;
              EXCEPTION
      WHEN OTHERS THEN
        V_ERROR_CD  :=-4;
        V_ERROR_MSG := SUBSTR('INSERT INTO TMP_GL_2 '||SQLERRM(SQLCODE),1,200);
        RAISE V_ERR;
      END;
    --25SEP2017
    BEGIN
      INSERT INTO TMP_GL_3
        SELECT   sort_doc_num,
                xn_doc_num,
                tal_id,
                folder_cd,
               doc_date,
               gl_acct_cd,
               sl_acct_cd,
               db_cr_flg,
              SUM( curr_val) curr_val,
               ledger_nar,
                 cre_dt,
                 V_RANDOM_VALUE,
                 P_USER_ID
            FROM(               
                SELECT DECODE( b.record_source ,'CG','2',NULL,a.xn_doc_num, b.xn_doc_num) sort_doc_num,  
                  DECODE( b.record_source ,'CG',' ',b.xn_doc_num) xn_doc_num,
                  DECODE( b.record_source ,'CG',0, NULL, a.tal_id,DECODE(a.doc_date, b.doc_date,777, a.tal_id)) tal_id,
                  DECODE( b.record_source ,'CG','RJ ',a.folder_cd) folder_cd,
                  a.doc_date,   
                  a.gl_acct_cd,
                  a.sl_acct_cd,
                  a.db_cr_flg,
                  a.curr_val,
                  a.ledger_nar,
                  DECODE( b.record_source ,'CG',b.doc_date,NULL,a.doc_date, b.cre_Dt) cre_dt
                FROM
                  (SELECT a.xn_doc_num,
                    a.tal_id,
                    NVL(a.folder_cd,'RJ') folder_cd,
                    a.doc_date,
                    a.gl_acct_cd,
                    a.sl_acct_cd,
                    a.db_cr_flg,
                    a.curr_val,
                    a.ledger_nar,
                    a.cre_dt
                  FROM T_ACCOUNT_LEDGER a,
                    MST_GL_ACCOUNT m
                  WHERE trim(a.gl_acct_cd) BETWEEN trim(as_bgn_acct) AND trim(as_end_acct)
                  AND a.sl_acct_cd BETWEEN as_bgn_sub AND as_end_sub
                  AND a.doc_date BETWEEN dt_bgn_date AND dt_end_date
                  AND  TRIM(m.gl_a) BETWEEN trim(as_bgn_acct) AND trim(as_end_acct)
                  AND m.sl_a BETWEEN as_bgn_sub AND as_end_sub
                  AND a.approved_sts = 'A'
                  AND TRIM(A.GL_ACCT_cD)   = TRIM(M.GL_A)
                  AND A.SL_ACCT_CD   = M.SL_A
                  AND ( ( m.brch_cd = as_bgn_branch and as_bgn_branch <>'%') OR as_bgn_branch='%')
                  AND record_source = 'RE'
                  AND as_reversal   = 'Y'
                  ) a,
                  (SELECT a.xn_doc_num,
                    reversal_jur,
                    a.tal_id,
                    a.folder_cd,
                    a.doc_date,
                    a.gl_acct_cd,
                    a.sl_acct_cd,
                    a.db_cr_flg,
                    a.curr_val,
                    a.ledger_nar,
                    a.cre_dt, a.record_source
                  FROM T_ACCOUNT_LEDGER a,
                    (SELECT MST_GL_ACCOUNT.gl_A,
                      MST_GL_ACCOUNT.sl_a,
                      brch_cd,
                      NVL(jur_type,'NONTRX') jur_type
                    FROM MST_GL_ACCOUNT,
                      (SELECT gl_a, jur_type FROM mst_gla_trx WHERE jur_type = 'TRX'
                      ) g
                    WHERE mst_gl_account.gl_a = g.gl_a(+)
                    AND  TRIM(MST_GL_ACCOUNT.gl_a) BETWEEN trim(as_bgn_acct) AND trim(as_end_acct)
                   AND MST_GL_ACCOUNT.sl_a BETWEEN as_bgn_sub AND as_end_sub
                    AND (TRIM(mst_gl_account.brch_cd) LIKE as_bgn_branch
                    OR mst_gl_account.brch_Cd   IS NULL)
                    AND mst_gl_account.prt_type <> 'S'
                    ) m
                  WHERE trim(a.gl_acct_cd) BETWEEN trim(as_bgn_acct) AND trim(as_end_acct)
                  AND a.sl_acct_cd BETWEEN as_bgn_sub AND as_end_sub
                  AND a.doc_date BETWEEN dt_bgn_date AND dt_end_date
                   AND  a.doc_date <= dt_end_date  
                  AND a.approved_sts   = 'A'
                  AND A.GL_ACCT_cD     = M.GL_A
                  AND A.SL_ACCT_CD     = M.SL_A
                  AND reversal_jur    <> 'N'
                  AND as_reversal      = 'Y'
                  ) b
                WHERE a.xn_doc_num = b.reversal_jur(+)
                AND a.tal_id       = b.tal_id(+)
                AND as_reversal    = 'Y'
            )  GROUP BY  doc_date,
               gl_acct_cd,
               sl_acct_cd,
               sort_doc_num,
                xn_doc_num,
                tal_id,
                folder_cd,
               db_cr_flg,
              ledger_nar, cre_dt ;
      EXCEPTION
    WHEN OTHERS THEN
      V_ERROR_CD  :=-5;
      V_ERROR_MSG := SUBSTR('INSERT INTO TMP_GL_3 '||SQLERRM(SQLCODE),1,200);
      RAISE V_ERR;
    END;
    
    BEGIN
      INSERT
      INTO R_GENERAL_LEDGER_REG
        (
          BRANCH_CODE ,
          TGL_ACCT_CD ,
          TSL_ACCT_CD ,
          ACCT_NAME ,
          DOC_NUM ,
          FOLDER_CD ,
          DOC_DATE ,
          LEDGER_NAR ,
          BEG_BAL ,
          DEBIT ,
          CREDIT ,
          CUM_BAL ,
          SEQNO ,
          SORTK1 ,
          SORT_DOC_NUM ,
          USER_ID ,
          RAND_VALUE ,
          GENERATE_DATE,
          BGN_DATE,
          END_DATE,
          TAL_ID,
          cre_dt,
          RPT_MODE
        )
      SELECT branch_code,
        tgl_acct_cd,
        tsl_acct_cd,
        acct_name,
        doc_num,
        folder_cd,
        tdoc_date AS doc_date,
        ledger_nar,
        beg_bal,
        debit,
        credit,
        SUM(DECODE(seqno,1,beg_bal,0) + debit - credit) over (PARTITION BY tgl_acct_cd, tsl_acct_cd ORDER BY tgl_acct_cd, tsl_acct_cd, seqno ) AS cum_bal,
        Seqno,
        sortk1,
        sort_doc_num ,
        P_USER_ID,
        V_RANDOM_VALUE,
        P_GENERATE_DATE,
        DT_BGN_DATE,
        dt_end_date,
        TAL_ID,
        cre_dt,
        P_MODE
      FROM
        (SELECT branch_code,
          tgl_acct_cd,
          tsl_acct_cd,
          acct_name,
          tdoc_date,
          cre_dt,
          xn_doc_num,
          tal_id,
          doc_num,
          folder_cd,
          ledger_nar,
          beg_bal,
          debit,
          credit,
          row_number( ) OVER (PARTITION BY tgl_acct_cd, tsl_acct_cd ORDER BY tgl_acct_cd, tsl_acct_cd, tdoc_date,cre_dt,sort_doc_num,tal_id) Seqno,
          sortk1,
          sort_doc_num
        FROM
          (SELECT NVL(A1.xn_doc_num,'X') doc_num,
            xn_doc_num,
            tal_id,
            NVL(A1.folder_cd,' ') folder_cd,
            NVL(A1.doc_date,dt_bgn_date) tdoc_date,
            DECODE(m.brch_cd,NULL, NVL(branch_code,'  '),m.brch_cd) branch_code,
            trim(m.gl_a) tgl_acct_cd,
            trim(m.sl_a) tsl_acct_cd,
            NVL(C1.beg_bal,0) beg_bal,
            DECODE(NVL(A1.db_cr_flg,'D'),'D',NVL(A1.curr_val,0), 0) debit,
            DECODE(NVL(A1.db_cr_flg,'D'),'C',NVL(A1.curr_val,0), 0) credit,
            NVL(A1.ledger_nar, 'TIDAK ADA TRANSAKSI') ledger_nar,
            m.acct_name,
            NVL(A1.cre_dt,dt_bgn_date) cre_dt,
            trim(m.gl_a )
            || trim(m.sl_a ) sortk1,
            sort_doc_num
          FROM
            (
            --PART 1
            SELECT * FROM TMP_GL_1 WHERE RAND_VALUE=V_RANDOM_VALUE AND USER_ID=P_USER_ID
              --END PART 1
            UNION ALL
            --PART 2
            SELECT * FROM TMP_GL_2 WHERE RAND_VALUE=V_RANDOM_VALUE AND USER_ID=P_USER_ID
            --END PART 2
            UNION ALL
            --PART 3
            SELECT * FROM TMP_GL_3 WHERE RAND_VALUE=V_RANDOM_VALUE AND USER_ID=P_USER_ID
            --END PART 3
            ) A1,
            (SELECT gl_acct_cd,
              sl_acct_cd,
              SUM(beg_bal) beg_bal
            FROM
              (SELECT C.gl_acct_cd,
                C.sl_acct_cd,
                (DECODE(C.db_cr_flg,'D',1,-1) * NVL(C.curr_val,0)) beg_bal
              FROM T_ACCOUNT_LEDGER C,
                MST_GL_ACCOUNT m
              WHERE trim(C.gl_acct_cd) BETWEEN trim(as_bgn_acct) AND trim(as_end_acct)
            --  AND NVL(m.acct_type,'123456') = 'LRTHIS' --31AUG2016
              AND c.sl_acct_cd BETWEEN as_bgn_sub AND as_end_sub
              AND (trim(c.brch_cd) LIKE trim(as_bgn_branch)
              OR c.brch_Cd IS NULL)
              AND C.doc_date BETWEEN dt_begin_bal AND dt_bgn_min1
              AND C.approved_sts = 'A'
              AND TRIM(c.gl_acct_cd)   = TRIM(m.gl_a)
              AND c.sl_acct_cd   = m.sl_a
              AND  TRIM(M.gl_a) BETWEEN trim(as_bgn_acct) AND trim(as_end_acct)
              AND M.sl_a BETWEEN as_bgn_sub AND as_end_sub
              UNION ALL
              SELECT d.gl_acct_cd,
                d.sl_acct_cd,
                d.deb_obal - cre_obal AS beg_bal
              FROM T_DAY_TRS d,
                MST_GL_ACCOUNT m
              WHERE d.trs_dt = dt_begin_bal
              AND trim(d.gl_acct_cd) BETWEEN trim(as_bgn_acct) AND trim(as_end_acct)
                AND  TRIM(M.gl_a) BETWEEN trim(as_bgn_acct) AND trim(as_end_acct)
              AND M.sl_a BETWEEN as_bgn_sub AND as_end_sub
             -- AND NVL(m.acct_type,'123456') = 'LRTHIS' --31AUG2016
              AND d.sl_acct_cd BETWEEN as_bgn_sub AND as_end_sub
              AND TRIM(d.gl_acct_cd) = TRIM(m.gl_a)
              AND d.sl_acct_cd = m.sl_a
              AND (( m.brch_cd = as_bgn_branch and as_bgn_branch <> '%') OR as_bgn_branch='%')
              )
            GROUP BY gl_acct_cd,
              sl_acct_cd
            ) C1,
            MST_GL_ACCOUNT m,
            MST_CLIENT ms
          WHERE trim(M.GL_A) BETWEEN trim(as_bgn_acct) AND trim(as_end_acct)
       --  AND NVL(m.acct_type,'123456') = 'LRTHIS' --31AUG2016
          AND m.sl_a BETWEEN as_bgn_sub AND as_end_sub
          AND ( ( m.brch_cd = as_bgn_branch and as_bgn_branch <> '%') or as_bgn_branch = '%')
          AND m.prt_type          <> 'S'
          AND m.gl_a               = A1.gl_acct_cd (+)
          AND m.sl_a               = A1.sl_acct_cd (+)
          AND m.gl_a               = C1.gl_acct_cd (+)
          AND m.sl_a               = C1.sl_acct_cd (+)
          AND M.SL_A               = ms.client_cd (+)
          AND (NVL(A1.curr_val,0) <> 0
          OR NVL(C1.beg_bal,0)    <> 0 )
          )
        );
--4sep17        ORDER BY sortk1,
 --4sep17         tdoc_date,
--4sep17          seqno;
--4sep17        cre_dt,
--4sep17         sort_doc_num,
--4sep17         tal_id ;
    EXCEPTION
    WHEN OTHERS THEN
      V_ERROR_CD  :=-10;
      V_ERROR_MSG := SUBSTR('INSERT INTO R_GENERAL_LEDGER_REG '||SQLERRM(SQLCODE),1,200);
      RAISE V_ERR;
    END;
    
    --25SEP2017
    DELETE FROM TMP_GL_1 WHERE RAND_VALUE=V_RANDOM_VALUE AND USER_ID=P_USER_ID;
    DELETE FROM TMP_GL_2 WHERE RAND_VALUE=V_RANDOM_VALUE AND USER_ID=P_USER_ID;
    DELETE FROM TMP_GL_3 WHERE RAND_VALUE=V_RANDOM_VALUE AND USER_ID=P_USER_ID;
    
  END IF;
  
  --BY ACCT
  IF P_MODE ='ACCT' THEN
    BEGIN
      SP_RPT_REMOVE_RAND('R_GENERAL_LEDGER_ACCT',V_RANDOM_VALUE,V_ERROR_MSG,V_ERROR_CD);
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
      INTO R_GENERAL_LEDGER_ACCT
        (
          DOC_DATE ,
          GL_ACCT_CD ,
          ACCT_NAME ,
          DEBIT ,
          CREDIT ,
          OBAL ,
          cum_bal,
          USER_ID ,
          RAND_VALUE ,
          GENERATE_DATE ,
          BGN_DATE ,
          END_DATE ,
          RPT_MODE
        )
     SELECT DOC_DATE,
  GL_ACCT_CD,
  ACCT_NAME,
  DEBIT,
  CREDIT,
  OBAL,
  SUM(DECODE(seqno,1,OBAL,0) + debit - credit) over (PARTITION BY GL_ACCT_CD ORDER BY GL_ACCT_CD,DOC_DATE ) AS cum_bal,
  P_USER_ID,
  V_RANDOM_VALUE,
  P_GENERATE_DATE,
  DT_BGN_DATE,
  dt_end_date,
  P_MODE
FROM
  (SELECT NVL(A1.doc_date,dt_bgn_date) doc_date,
    trim(m.gl_a) gl_acct_cd,
    m.acct_name,
    nvl(a1.debit,0)debit,
    nvl(A1.CREDIT,0)credit,
    NVL(D1.OBAL,0) OBAL,
    row_number( ) OVER (PARTITION BY M.GL_a ORDER BY m.gl_a,DOC_DATE) Seqno
  FROM
    (SELECT b.doc_date,
      TRIM(b.gl_acct_cd) gl_acct_cd,
      SUM(DECODE(b.db_cr_flg,'D',b.curr_val,0)) debit,
      SUM(DECODE(B.DB_CR_FLG,'C',B.CURR_VAL,0)) CREDIT
    FROM t_account_ledger b,
      mst_gl_account mb
    WHERE TRIM(b.gl_acct_cd) BETWEEN TRIM(as_bgn_acct) AND TRIM(as_end_acct)
      AND  TRIM(MB.gl_a) BETWEEN trim(as_bgn_acct) AND trim(as_end_acct)
    AND MB.sl_a BETWEEN as_bgn_sub AND as_end_sub
    AND b.doc_date BETWEEN dt_bgn_date AND dt_end_date
    AND b.approved_sts = 'A'
    AND TRIM(B.GL_ACCT_cD)    = TRIM(MB.GL_A)
    AND B.SL_ACCT_CD    = MB.SL_A
    AND (( MB.brch_cd = as_bgn_branch and as_bgn_branch<>'%') or as_bgn_branch='%')
    AND mb.prt_type    <> 'S'
    GROUP BY b.doc_date,
      b.gl_acct_cd
    ) A1,
    (SELECT TRIM(GL_ACCT_CD) gl_acct_cd,
      SUM( deb_obal - cre_obal) obal
    FROM t_day_trs d
    WHERE trs_dt = dt_begin_bal
    AND TRIM(gl_acct_cd) BETWEEN TRIM(as_bgn_acct) AND TRIM(as_end_acct)
    GROUP BY gl_acct_cd
    ) D1,
    mst_gl_account m
  WHERE M.GL_A BETWEEN TRIM(as_bgn_acct) AND TRIM(as_end_acct)
   AND (( m.brch_cd = as_bgn_branch and as_bgn_branch<>'%') or as_bgn_branch='%')
  AND m.sl_a            = '000000'
  AND TRIM(m.gl_a)            = A1.gl_acct_cd (+)
  AND TRIM(m.gl_a)            = D1.gl_acct_cd (+)
  AND (NVL(A1.DEBIT,0) <> 0
  OR NVL(A1.CREDIT,0)  <> 0
  OR NVL(D1.OBAL,0)    <> 0 )
  );
--ORDER BY GL_ACCT_CD,
--  DOC_DATE;
    EXCEPTION
    WHEN OTHERS THEN
      V_ERROR_CD  :=-10;
      V_ERROR_MSG := SUBSTR('INSERT INTO R_GENERAL_LEDGER_ACCT '||SQLERRM(SQLCODE),1,200);
      RAISE V_ERR;
    END;
  END IF;
  
  P_RANDOM_VALUE := v_random_value;
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
END SPR_GENERAL_LEDGER;