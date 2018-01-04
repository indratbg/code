create or replace PROCEDURE SPR_SECU_GENERAL_LEDGER(
    P_END_DATE      DATE,
    P_BGN_ACCT      VARCHAR2,
    P_END_ACCT      VARCHAR2,
    P_BGN_CLIENT    VARCHAR2,
    P_END_CLIENT    VARCHAR2,
    P_BGN_STK       VARCHAR2,
    P_END_STK       VARCHAR2,
    P_REVERSAL_JUR  VARCHAR2,
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
  V_BGN_DATE     DATE;
  --WITH CHANGE TICKER CODE--
BEGIN

  v_random_value := ABS(dbms_random.random);
  
  BEGIN
    SP_RPT_REMOVE_RAND('R_SECU_GENERAL_LEDGER',V_RANDOM_VALUE,V_ERROR_MSG,V_ERROR_CD);
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
  
  V_BGN_DATE := P_END_DATE - TO_CHAR(P_END_DATE,'DD')+1;
  
  BEGIN
    INSERT
    INTO R_SECU_GENERAL_LEDGER
      (
        LINETYPE ,
        KDOC ,
        DOC_NUM ,
        GL_ACCT_CD ,
        SL_DESC ,
        SL_CODE ,
        CLIENT_CD ,
        CLIENT_NAME ,
        AGREEMENT_NO ,
        STK_CD ,
        DOC_DT ,
        DOC_REM ,
        QTY ,
        DEBIT ,
        CREDIT ,
        BALANCE,
        REF_DOC_NUM ,
        OLD_CD ,
        APPROVED_DT ,
        BGN_DATE ,
        END_DATE ,
        USER_ID ,
        RAND_VALUE ,
        GENERATE_DATE
      )
    SELECT linetype,
      kdoc,
      doc_num,
      gl_acct_cd,
      sl_desc,
      sl_code,
      client_cd,
      client_name,
      agreement_no,
      stk_cd,
      doc_dt,
      doc_rem,
      qty,
      debit,
      credit,
      SUM(DECODE(LINETYPE,1,QTY,DEBIT+(CREDIT *-1)))OVER(PARTITION BY client_cd,stk_cd order by gl_acct_cd,client_cd,stk_cd,doc_dt,approved_dt,doc_num) BALANCE,
      ref_doc_num,
      old_cd,
      approved_dt,
      V_BGN_DATE,
      P_END_DATE,
      P_USER_ID,
      V_RANDOM_VALUE,
      P_GENERATE_DATE
    FROM
      (SELECT b2.linetype,
        kdoc,
        doc_num,
        TRIM(B2.gl_acct_cd)gl_acct_cd,
        B.sl_desc,
        B.sl_code,
        trim(B2.client_cd) CLIENT_CD,
        c.client_name,
        s.subrek14 as agreement_no,--c.agreement_no,--28NOV2016, DIAMBIL DARI V_CLIENT_SUBREK14 FIELD_SUBRE14
        trim(B2.stk_cd) STK_CD,
        B2.doc_dt,
        B2.doc_rem,
        NVL(B2.total_qty,0) qty,
        DECODE(SIGN(TO_NUMBER(B2.gl_acct_cd) - 30),1,NVL(B2.C,0),NVL(B2.D,0)) DEBIT,
        DECODE(SIGN(TO_NUMBER(B2.gl_acct_cd) - 30),1,NVL(B2.D,0),NVL(B2.C,0)) CREDIT,
        B2.ref_doc_num,
        c.old_ic_num AS old_cd,
        B2.approved_dt
      FROM
        (SELECT '2' linetype,
          doc_num kdoc,
          doc_num,
          gl_acct_cd,
          client_cd,
          db_cr_flg,
          nvl(c.stk_cd_new,stk_cd)stk_cd,
          doc_dt,
          doc_rem,
          ref_doc_num,
          status,
          NVL(DECODE(trim(db_cr_flg),'D',withdrawn_share_qty + total_share_qty),0) D,
          NVL(DECODE(trim(db_cr_flg),'C',withdrawn_share_qty +total_share_qty),0) C,
          0 total_qty,
          NVL(approved_dt,cre_dt) AS approved_dt
        FROM T_STK_MOVEMENT,
        (select stk_cd_new, stk_cd_old from t_change_stk_cd where eff_dt<=P_END_DATE)c
        WHERE doc_dt BETWEEN V_BGN_DATE AND P_END_DATE
        and stk_cd=c.stk_cd_old(+)
        AND client_cd BETWEEN P_BGN_CLIENT AND P_END_CLIENT
        AND nvl(c.stk_cd_new,stk_cd) BETWEEN P_BGN_STK AND P_END_STK
        AND trim(gl_acct_cd) BETWEEN P_BGN_ACCT AND P_END_ACCT
        AND gl_acct_cd   IS NOT NULL
        AND doc_stat      = '2'
        AND approved_stat ='A'
        UNION ALL
        SELECT '2' linetype,
          DECODE(prev_doc_num, NULL, doc_num, prev_doc_num) kdoc,
          doc_num,
          gl_acct_cd,
          client_cd,
          db_cr_flg,
          nvl(c.stk_cd_new,stk_cd)stk_cd,
          doc_dt,
          doc_rem,
          ref_doc_num,
          status,
          NVL(DECODE(trim(db_cr_flg),'D',withdrawn_share_qty + total_share_qty),0) D,
          NVL(DECODE(trim(db_cr_flg),'C',withdrawn_share_qty +total_share_qty),0) C,
          0 total_qty,
          NVL(approved_dt,cre_dt) AS approved_dt
        FROM T_STK_MOVEMENT,
          (select stk_cd_new, stk_cd_old from t_change_stk_cd where eff_dt<=P_END_DATE)c
        WHERE doc_dt BETWEEN V_BGN_DATE AND P_END_DATE
          and stk_cd=c.stk_cd_old(+)
        AND client_cd BETWEEN P_BGN_CLIENT AND P_END_CLIENT
         AND nvl(c.stk_cd_new,stk_cd) BETWEEN P_BGN_STK AND P_END_STK
        AND trim(gl_acct_cd) BETWEEN P_BGN_ACCT AND P_END_ACCT
        AND gl_acct_cd   IS NOT NULL
        AND approved_stat ='A'
        AND doc_stat     IN ( '9','3')
        AND P_REVERSAL_JUR = 'Y'
        UNION ALL
        SELECT '1' line_type,
          NULL kdoc,
          NULL doc_num,
          gl_acct_cd,
          client_cd,
          NULL AS db_cr_flg,
          nvl(c.stk_cd_new,stk_cd)stk_cd,
          bal_dt,
          'Beginning Balance' AS doc_rem,
          NULL AS ref_doc_num,
          status l_f,
          0 D,
          0 C,
          qty total_qty,
          bal_dt AS approved_dt
        FROM T_SECU_BAL,
        (select stk_cd_new, stk_cd_old from t_change_stk_cd where eff_dt<=P_END_DATE)c
        WHERE bal_dt = V_BGN_DATE
          and stk_cd=c.stk_cd_old(+)
        AND client_cd BETWEEN P_BGN_CLIENT AND P_END_CLIENT
         AND nvl(c.stk_cd_new,stk_cd) BETWEEN P_BGN_STK AND P_END_STK
        AND trim(gl_Acct_cd) BETWEEN P_BGN_ACCT AND P_END_ACCT
        UNION ALL
          (SELECT '1' line_type,
            NULL kdoc,
            NULL doc_num,
            tm.gl_acct_cd,
            tm.client_cd,
            'D' db_cr_flg,
            tm.stk_cd,
            V_BGN_DATE bal_dt,
            'Beginning Balance' AS doc_rem,
            NULL                AS ref_doc_num,
            NULL l_f,
            0 D,
            0 C,
            0 total_qty,
            V_BGN_DATE
          FROM
            (SELECT nvl(c.stk_cd_new,stk_cd)stk_cd2,T_SECU_BAL.*
            FROM T_SECU_BAL,
            (select stk_cd_new, stk_cd_old from t_change_stk_cd where eff_dt<=P_END_DATE)c
            WHERE bal_dt = V_BGN_DATE
              and stk_cd=c.stk_cd_old(+)
            AND client_cd BETWEEN P_BGN_CLIENT AND P_END_CLIENT
            AND nvl(c.stk_cd_new,stk_cd) BETWEEN P_BGN_STK AND P_END_STK
            AND trim(gl_Acct_cd) BETWEEN P_BGN_ACCT AND P_END_ACCT
            ) se,
            ( SELECT DISTINCT gl_acct_cd,
              client_cd,
              nvl(c.stk_cd_new,stk_cd)stk_cd
            FROM T_STK_MOVEMENT,
            (select stk_cd_new, stk_cd_old from t_change_stk_cd where eff_dt<=P_END_DATE)c
            WHERE doc_dt BETWEEN V_BGN_DATE AND P_END_DATE
            AND client_cd BETWEEN P_BGN_CLIENT AND P_END_CLIENT
            AND nvl(c.stk_cd_new,stk_cd) BETWEEN P_BGN_STK AND P_END_STK
            AND trim(gl_acct_cd) BETWEEN P_BGN_ACCT AND P_END_ACCT
            AND gl_acct_cd IS NOT NULL
            AND doc_stat    = '2'
            ) tm
          WHERE se.gl_acct_cd (+) = tm.gl_acct_cd
          AND se.client_cd (+)    = tm.client_cd
          AND se.stk_cd2 (+)       = tm.stk_cd
          AND se.gl_acct_cd      IS NULL
          )
        )B2,
        (SELECT gl_acct_Cd,
          sl_desc,
          sl_code
        FROM MST_SECURITIES_LEDGER
        WHERE trim(gl_acct_cd) BETWEEN P_BGN_ACCT AND P_END_ACCT
        AND P_END_DATE BETWEEN ver_bgn_dt AND ver_end_dt
        ) B,
        MST_CLIENT C,
        v_client_subrek14 s
      WHERE C.CLIENT_CD=S.CLIENT_CD 
      AND B2.client_cd BETWEEN P_BGN_CLIENT AND P_END_CLIENT
      AND B2.stk_cd BETWEEN P_BGN_STK AND P_END_STK
      AND B.GL_ACCT_Cd          = B2.gl_acct_Cd(+)
      AND (NVL(B2.total_qty,0) <> 0
      OR NVL(B2.D, 0)          <> 0
      OR NVL(B2.C, 0)          <> 0
      OR b2.linetype            = '1')
      AND B2.client_cd          = C.client_cd
      );
    
   
  EXCEPTION
  WHEN OTHERS THEN
    V_ERROR_CD  := -50;
    V_ERROR_MSG := SUBSTR('INSERT R_SECU_GENERAL_LEDGER '||V_ERROR_MSG||SQLERRM(SQLCODE),1,200);
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
END SPR_SECU_GENERAL_LEDGER;