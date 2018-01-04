create or replace PROCEDURE SPR_JOURNAL_LIST(
    P_BGN_DATE      DATE,
    P_END_DATE      DATE,
    P_TYPE          VARCHAR2,
    P_USER_ID       VARCHAR2,
    P_GENERATE_DATE DATE,
    P_RANDOM_VALUE OUT NUMBER,
    P_ERROR_CD OUT NUMBER,
    P_ERROR_MSG OUT VARCHAR2 )
AS
-- 16feb2017 SA : koreksi jur Type ROUND termasuk di bagian trx
--                          tambah record_source = 'INT'
  V_ERR          EXCEPTION;
  V_ERROR_CD     NUMBER(5);
  V_ERROR_MSG    VARCHAR2(200);
  V_RANDOM_VALUE NUMBER(10);
  
BEGIN
  v_random_value := ABS(dbms_random.random);
  
  BEGIN
    SP_RPT_REMOVE_RAND('R_JOURNAL_LIST',V_RANDOM_VALUE,V_ERROR_MSG,V_ERROR_CD);
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
    INTO R_JOURNAL_LIST
      (
        SEQCD ,
        DOC_DATE ,
        SDOC_A ,
        SDOC_B ,
        SDOC_NUM ,
        TAL_ID ,
        GL_ACCT_CD ,
        SL_ACCT_CD ,
        ACCT_NAME ,
        LEDGER_NAR ,
        DEBIT ,
        CREDIT ,
        AMT ,
        FOLDER_CD ,
        TYP ,
        USER_ID ,
        RAND_VALUE ,
        GENERATE_DATE ,
        BGN_DATE ,
        END_DATE
      )
    SELECT SEQCD ,
      DOC_DATE ,
      SDOC_A ,
      SDOC_B ,
      SDOC_NUM ,
      TAL_ID ,
      GL_ACCT_CD ,
      SL_ACCT_CD ,
      ACCT_NAME ,
      LEDGER_NAR ,
      DEBIT ,
      CREDIT ,
      AMT ,
      FOLDER_CD ,
      TYP,
      P_USER_ID,
      V_RANDOM_VALUE,
      P_GENERATE_DATE,
      P_BGN_DATE,
      P_END_DATE
    FROM
      (SELECT '01' SEQCD,
        t.doc_date,
        '0'
        ||SUBSTR(DECODE(t.doc_ref_num,NULL,t.xn_doc_num,t.doc_ref_num),5,1) sdoc_A,
        c.stk_cd
        ||DECODE(SUBSTR(t.gl_acct_cd,1,2),'13',m.bah_acct_short,'62',m.bah_acct_short,t.sl_acct_cd) sdoc_B,
        DECODE(t.doc_ref_num,NULL,t.xn_doc_num,t.doc_ref_num) sdoc_num,
        t.tal_id,
        t.gl_acct_cd,
        DECODE(SUBSTR(t.gl_acct_cd,1,2),'13',m.bah_acct_short,'62',m.bah_acct_short,t.sl_acct_cd) sl_acct_cd,
        DECODE(SUBSTR(t.gl_acct_cd,1,2),'13',m.bah_acct_name,m.acct_name) acct_name,
        t.ledger_nar,
        DECODE(t.db_cr_flg,'D',t.curr_val,0) debit,
        DECODE(t.db_cr_flg,'C',t.curr_val,0) credit,
        t.curr_val amt,
        t.folder_cd,--24JUN2016
        'I' typ
      FROM T_ACCOUNT_LEDGER t,
        T_CONTRACTS c,
        (SELECT m.gl_a,
          m.sl_a,
          bah_acct_short,
          bah_acct_name,
          acct_name
        FROM MST_GL_ACCOUNT m,
          (SELECT trim(gl_a) gl_a FROM MST_GLA_TRX WHERE jur_type IN ( 'CLIE' ,'PORT','BROK')--27jun2016 tambah BROK
          ) g
        WHERE trim(m.gl_a) = g.gl_a
        ) m
      WHERE t.sl_acct_cd = m.sl_a
      AND t.gl_acct_cd   = m.gl_a
      AND t.doc_date BETWEEN P_BGN_DATE AND P_END_DATE
      AND t.approved_sts  = 'A'
      AND T.REVERSAL_JUR  = 'N'
      AND P_TYPE         <> 'REVERSAL'
      AND t.record_source = 'CG'
      AND (t.xn_doc_num   = c.contr_num
      OR t.doc_ref_num    = c.contr_num)
      UNION
      SELECT '01' SEQCD,
        t.doc_date,
        '2'
        ||t.xn_doc_num sdoc_A,
        '' sdoc_B,
        t.xn_doc_num sdoc_num,
        t.tal_id,
        t.gl_acct_cd,
        t.sl_acct_cd,
        m.acct_name acct_name,
        t.ledger_nar,
        DECODE(t.db_cr_flg,'D',t.curr_val,0) debit,
        DECODE(t.db_cr_flg,'C',t.curr_val,0) credit,
        t.curr_val amt,
        t.folder_cd,--24JUN2016
        'I' typ
      FROM T_ACCOUNT_LEDGER t,
        MST_GL_ACCOUNT m
      WHERE t.doc_date BETWEEN P_BGN_DATE AND P_END_DATE
      AND t.approved_sts           = 'A'
      AND T.REVERSAL_JUR           = 'N'
      AND P_TYPE                  <> 'REVERSAL'
      AND SUBSTR(t.xn_doc_num,8,3) = 'MFE'
      AND t.gl_acct_cd             = m.gl_a
      AND t.sl_acct_cd             = m.sl_a
      UNION
      SELECT '01' SEQCD,
        t.doc_date,
        '1' sdoc_a,
        '9999'
        ||TO_CHAR(t.tal_id,'00') sdoc_b,
        '' sdoc_num,
        t.tal_id,
        trim(t.gl_acct_cd),
        trim(t.sl_acct_cd),
        'TOTAL' acct_name,
        trim(t.ledger_nar),
        SUM(DECODE(t.db_cr_flg,'D',t.curr_val,0)) debit,
        SUM(DECODE(t.db_cr_flg,'C',t.curr_val,0)) credit,
        SUM(t.curr_val) amt,
        ' ' folder_cd,
        'I' typ
      FROM T_ACCOUNT_LEDGER t,
        (SELECT m.gl_a,
          m.sl_a,
          bah_acct_short,
          bah_acct_name,
          acct_name
        FROM MST_GL_ACCOUNT m,
          ( SELECT trim(gl_a) gl_a FROM MST_GLA_TRX WHERE jur_type IN ( 'TRX','ROUND' )
          ) g
        WHERE trim(m.gl_a) = g.gl_a
        ) m
      WHERE t.sl_acct_cd = m.sl_a
      AND t.gl_acct_cd   = m.gl_a
      AND t.doc_date BETWEEN P_BGN_DATE AND P_END_DATE
      AND t.record_source = 'CG'
      AND t.approved_sts  = 'A'
      AND T.REVERSAL_JUR  = 'N'
      AND P_TYPE         <> 'REVERSAL'
      GROUP BY t.doc_date,
        t.tal_id,
        t.gl_acct_cd,
        t.sl_acct_cd,
        t.ledger_nar
      UNION
      SELECT '02' SEQCD,
        t.doc_date,
        c.contr_num
        ||DECODE(t.record_source,'CG','1','2') sdoc_A,
        t.xn_doc_num sdoc_B,
        t.xn_doc_num sdoc_num,
        t.tal_id,
        t.gl_acct_cd,
        DECODE(SUBSTR(t.gl_acct_cd,1,2),'13',m.bah_acct_short,'62',m.bah_acct_short,t.sl_acct_cd) sl_acct_cd,
        DECODE(SUBSTR(t.gl_acct_cd,1,2),'13',m.bah_acct_name,m.acct_name) acct_name,
        t.ledger_nar,
        DECODE(t.db_cr_flg,'D',t.curr_val,0) debit,
        DECODE(t.db_cr_flg,'C',t.curr_val,0) credit,
        t.curr_val amt,
        ' ' folder_cd,
        'I' typ
      FROM T_ACCOUNT_LEDGER t,
        MST_GL_ACCOUNT M,
        T_CONTRACTS c
      WHERE t.doc_date BETWEEN P_BGN_DATE AND P_END_DATE
      AND c.contr_dt BETWEEN P_BGN_DATE AND P_END_DATE
      AND C.CONTR_STAT    = 'C'
      AND t.approved_sts    = 'A'--16feb
      AND C.REVERSAL_JUR IS NOT NULL
      AND P_TYPE          = 'REVERSAL'
      AND t.gl_acct_cd    = m.gl_a
      AND t.sl_acct_cd    = m.sl_a
      AND( t.xn_doc_num   = c.contr_num
      OR t.xn_doc_num     = c.reversal_jur)
      UNION
      SELECT '04' SEQCD,
        t.doc_date,
        b.approved_Sts
        ||B.doc_num
        ||DECODE(T.RECORD_SOURCe,'CG','_1','_2') sdoc_a,
        TO_CHAR(t.tal_id,'00') sdoc_b,
        xn_doc_num sdoc_num,
        t.tal_id,
        trim(t.gl_acct_cd),
        trim(t.sl_acct_cd),
        acct_name,
        trim(t.ledger_nar),
        (DECODE(t.db_cr_flg,'D',t.curr_val,0)) debit,
        (DECODE(t.db_cr_flg,'C',t.curr_val,0)) credit,
        (t.curr_val) amt,
        ' ' folder_cd,
        DECODE(record_source,'CG',b.approved_sts,'R') typ
      FROM T_ACCOUNT_LEDGER t,
        MST_GL_ACCOUNT m,
        (SELECT trx_date,
          doc_num,
          reversal_doc_num,
          approved_sts
        FROM T_BOND_TRX
        WHERE TRX_date BETWEEN P_BGN_DATE AND P_END_DATE
        AND doc_num              IS NOT NULL
        AND ( ( reversal_doc_num IS NOT NULL
        AND P_TYPE                = 'REVERSAL')
        OR ( approved_sts         = 'A'
        AND P_TYPE               <> 'REVERSAL'))
        ) b
      WHERE t.doc_date BETWEEN P_BGN_DATE AND P_END_DATE
      AND t.approved_sts    = 'A'
      AND ( B.DOC_NUM       = T.XN_DOC_NUM
      OR B.REVERSAL_DOC_NUM = T.XN_DOC_NUM )
      AND t.gl_acct_cd      = m.gl_a
      AND t.sl_acct_cd      = m.sl_a
      UNION
      SELECT DECODE(record_source,'CG','01','RV','05','RVO','05','RD','06','PV','07','PVO','07','PD','08', 'GL','10','DNCN','11','INT',11,'CDUE','12','MDUE','12','20') SEQCD,
        t.doc_date,
        t.xn_doc_num sdoc_A,
        '' sdoc_b,
        t.xn_doc_num sdoc_num,
        t.tal_id,
        t.gl_acct_cd,
        t.sl_acct_cd,
        m.acct_name acct_name,
        t.ledger_nar,
        DECODE(t.db_cr_flg,'D',t.curr_val,0) debit,
        DECODE(t.db_cr_flg,'C',t.curr_val,0) credit,
        t.curr_val amt,
        t.folder_cd folder_cd,
        DECODE(SUBSTR(xn_doc_num,5,1),'R','R','P','P','M') typ
      FROM T_ACCOUNT_LEDGER t,
        MST_GL_ACCOUNT m
      WHERE t.sl_acct_cd = m.sl_a
      AND t.gl_acct_cd   = m.gl_a
      AND t.doc_date BETWEEN P_BGN_DATE AND P_END_DATE
      AND t.approved_sts            = 'A'
      AND (t.record_source         <> 'CG'
      AND P_TYPE                    = 'ALL' )
      AND SUBSTR(t.xn_doc_num,8,3) <> 'MFE'
      AND t.record_source          <> 'RE'
      AND t.reversal_jur            = 'N'
      AND P_TYPE                   <> 'REVERSAL'
      UNION
      SELECT DECODE(PAYREC_TYPE,'RV','3005','RD','3006','PV','3007','PD','3008','GL','3010','DNCN','3011','INT','3011') SEQCD,
        t.doc_date,
        DECODE(T.REVERSAL_JUR,'N',t.xn_doc_num, T.REVERSAL_JUR)
        ||DECODE(RECORD_SOURCE,'RE','X','') sdoc_A,
        t.xn_doc_num sdoc_b,
        t.xn_doc_num sdoc_num,
        t.tal_id,
        t.gl_acct_cd,
        t.sl_acct_cd,
        m.acct_name acct_name,
        t.ledger_nar,
        DECODE(t.db_cr_flg,'D',t.curr_val,0) debit,
        DECODE(t.db_cr_flg,'C',t.curr_val,0) credit,
        t.curr_val amt,
        t.folder_cd folder_cd,
        DECODE(SUBSTR(xn_doc_num,5,1),'R','R','P','P','M') TYP
      FROM T_ACCOUNT_LEDGER t,
        MST_GL_ACCOUNT m,
        (SELECT PAYREC_NUM ,
          REVERSAL_JUR,
          PAYREC_TYPE
        FROM T_PAYRECH
        WHERE PAYREC_DATE <= P_END_DATE
        AND REVERSAL_JUR  IS NOT NULL
        AND REVERSAL_JUR  <> 'N'
        UNION ALL
        SELECT JVCH_NUM,
          REVERSAL_JUR,
          'GL'
        FROM T_JVCHH
        WHERE JVCH_DATE  <= P_END_DATE
        AND REVERSAL_JUR IS NOT NULL
        AND REVERSAL_JUR <> 'N'
        UNION ALL
        SELECT DNCN_NUM,
          REVERSAL_JUR,
          'DNCN'
        FROM T_DNCNH
        WHERE DNCN_DATE  <= P_END_DATE
        AND REVERSAL_JUR IS NOT NULL
        AND REVERSAL_JUR <> 'N'
        ) H
      WHERE t.sl_acct_cd = m.sl_a
      AND t.gl_acct_cd   = m.gl_a
      AND t.doc_date BETWEEN P_BGN_DATE AND P_END_DATE
      AND t.approved_sts            = 'A'
      AND (t.record_source         <> 'CG'
      AND P_TYPE                    = 'REVERSAL' )
      AND SUBSTR(t.xn_doc_num,8,3) <> 'MFE'
      AND (T.XN_DOC_NUM             = H.PAYREC_NUM
      OR H.REVERSAL_JUR             = T.XN_DOC_NUM)
      )
    ORDER BY doc_date,
      seqcd,
      sdoc_a,
      sdoc_b,
      tal_id ;
  EXCEPTION
  WHEN OTHERS THEN
    V_ERROR_CD  :=-30;
    V_ERROR_MSG := SUBSTR('INSERT INTO R_JOURNAL_LIST '||SQLERRM(SQLCODE),1,200);
    RAISE V_ERR;
  END;
  
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
END SPR_JOURNAL_LIST;