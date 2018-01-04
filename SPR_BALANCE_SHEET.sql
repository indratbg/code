create or replace 
PROCEDURE Spr_Balance_Sheet(
    P_END_DATE      DATE,
    P_BRANCH_CD     VARCHAR2,
    P_USER_ID       VARCHAR2,
    P_GENERATE_DATE DATE,
    P_RANDOM_VALUE OUT NUMBER,
    P_ERROR_CD OUT NUMBER,
    P_ERROR_MSG OUT VARCHAR2 )
AS
  V_ERR           EXCEPTION;
  V_ERROR_CD      NUMBER(5);
  V_ERROR_MSG     VARCHAR2(200);
  V_RANDOM_VALUE  NUMBER(10);
  V_LAST_BAL_DATE DATE;
  V_BGN_BAL_DATE  DATE;
  V_GLA_LR T_ACCOUNT_LEDGER.GL_ACCT_CD%TYPE;
  V_BY_BRANCH    VARCHAR2(1);
  V_CURR_BRANCH  VARCHAR2(3);
  V_CHECK_BRANCH VARCHAR2(1);
  V_AKTIVA       NUMBER;
  V_LR_CURR_MON  NUMBER;
  v_brok_nettg_date date;
  v_brok         mst_gla_trx.jur_type%type;
  
/* NOTES
   28jul2016 - dgn netting utang/piutang broker 1453/2453
                call F_BALSH_JUL2016

*/
  
cursor csr_sum3 is
SELECT grp_1, grp_2,  grp_3, SUM(CURR_MON) CURR_MON,
        SUM(LAST_MON) LAST_MON,
        SUM(PREV_YEAR)PREV_YEAR
FROM R_BALANCE_SHEET
WHERE RAND_VALUE =  V_RANDOM_VALUE
    AND USER_ID  = P_USER_ID
  AND substr(gl_acct_cd,1,3) <> 'SUM'
  GROUP BY grp_1, grp_2 ,  grp_3
  ORDER BY grp_1, grp_2 ,  grp_3;
  
cursor csr_sum2 is
SELECT grp_1, grp_2,    SUM(CURR_MON) CURR_MON,
        SUM(LAST_MON) LAST_MON,
        SUM(PREV_YEAR)PREV_YEAR
FROM R_BALANCE_SHEET
WHERE RAND_VALUE =  V_RANDOM_VALUE
    AND USER_ID  = P_USER_ID
  AND substr(gl_acct_cd,1,3) <> 'SUM'
  GROUP BY grp_1, grp_2  
  ORDER BY grp_1, grp_2  ;
  
cursor csr_sum1 is
SELECT grp_1,      SUM(CURR_MON) CURR_MON,
        SUM(LAST_MON) LAST_MON,
        SUM(PREV_YEAR)PREV_YEAR
FROM R_BALANCE_SHEET
WHERE RAND_VALUE =  V_RANDOM_VALUE
    AND USER_ID  = P_USER_ID
  AND substr(gl_acct_cd,1,3) <> 'SUM'
  GROUP BY grp_1   
  ORDER BY grp_1 ;  
 
 
  
BEGIN
  V_RANDOM_VALUE := ABS(DBMS_RANDOM.RANDOM);

  BEGIN
    DELETE FROM R_BALANCE_SHEET WHERE USER_ID=P_USER_ID;
  EXCEPTION
  WHEN OTHERS THEN
    V_ERROR_CD  := -15;
    V_ERROR_MSG := SUBSTR('DELETE R_BALANCE_SHEET'||SQLERRM(SQLCODE),1,200);
    RAISE V_err;
  END;
  V_BGN_BAL_DATE  := P_END_DATE - TO_CHAR(P_END_DATE,'DD')+1;
  V_LAST_BAL_DATE := P_END_DATE -TO_CHAR(P_END_DATE,'DD');
  V_LAST_BAL_DATE := TO_DATE(TO_CHAR(P_END_DATE,'YYYY')||'0101','YYYYMMDD');
  
  begin
       SELECT  ddate1  INTO v_brok_nettg_date
        FROM MST_SYS_PARAM
        WHERE param_id = 'F_BALSH'
        AND param_cd1 = 'BROKNETG';  
       exception
       when no_data_found then
          v_brok  := 'X';
       end;
       
   If v_brok_nettg_date > p_end_date then
       v_brok  := 'X';
       else
      v_brok  := 'BROK';
    end if;
       
  BEGIN
    INSERT
    INTO R_BALANCE_SHEET
      (
        END_DATE ,
        GRP_1 ,
        GRP_2 ,
        GRP_3 ,
        GRP_4 ,
        GRP_5 ,
        GL_ACCT_CD ,
        MACCT_NAME ,
        CURR_MON ,
        LAST_MON ,
        PREV_YEAR ,
        MGRP_DESC ,
        USER_ID ,
        RAND_VALUE ,
        GENERATE_DATE
      )
    SELECT P_END_DATE,
      GRP_1,
      GRP_2,
      GRP_3,
      GRP_4,
      GRP_5,
      gl_AccT_cd,
      MACCT_NAME,
      CURR_MON,
      LAST_MON,
      PREV_YEAR,
      mgrp_desc,
      P_USER_ID,
      V_RANDOM_VALUE,
      P_GENERATE_DATE
    FROM
      (SELECT M1.grp_1,
        M1.grp_2,
        M1.grp_3,
        M1.grp_4,
        M1.grp_5,
        M1.GL_Acct10 AS gl_acct_cd,
        UPPER(C1.acct_name) macct_name,
        DECODE(M1.grp_1,1, NVL(t.curr_mon_A,0),NVL(t.curr_mon_P,0)) curr_mon,
        DECODE(M1.grp_1,1,NVL(t.last_mon_A,0),NVL(t.last_mon_P,0)) last_mon,
        DECODE(M1.grp_1,1,NVL(t.prev_year_A,0),NVL(t.prev_year_P,0)) prev_year,
        M1.LINE_desc AS mgrp_desc
      FROM
        (SELECT gl_acct_cd
          ||sl_acct_cd AS gl_Acct10,
          SUM(curr_mvmt_A + last_mon_A) curr_mon_A,
          SUM(last_mon_A) last_mon_A,
          SUM(prev_year_A) prev_year_A,
          SUM(curr_mvmt_P + last_mon_P) curr_mon_P,
          SUM(last_mon_P) last_mon_P,
          SUM(prev_year_P) prev_year_P
        FROM
          (SELECT trim(a.gl_acct_cd) gl_acct_cd,
            DECODE(trim(a.gl_acct_cd),'3000',trim(a.sl_acct_cd),'000000') sl_acct_cd,
            0 curr_mvmt_A,
            0 last_mon_A,
            (a.deb_obal - a.cre_obal) prev_year_A,
            0 curr_mvmt_P,
            0 last_mon_P,
            (a.cre_obal - a.deb_obal) prev_year_P
          FROM t_day_trs a,
            (SELECT gl_a
            FROM MST_GLA_TRX
            WHERE jur_type IN ('CLIE','T3','KPEI','T7', v_brok)
            ) v
          WHERE a.trs_dt   = V_LAST_BAL_DATE
          AND a.gl_acct_cd = v.gl_a (+)
          AND v.gl_A      IS NULL
          UNION ALL
          SELECT trim(b.gl_acct_cd) gl_acct_cd,
            DECODE(trim(b.gl_acct_cd),'3000',trim(b.sl_acct_cd),'000000') sl_acct_cd,
            0 curr_mvmt_A,
            (b.deb_obal - b.cre_obal) last_mon_A,
            0 prev_year_A,
            0 curr_mvmt_P,
            (b.cre_obal - b.deb_obal) last_mon_P,
            0 prev_year_P
          FROM t_day_trs b,
            (SELECT gl_a
            FROM MST_GLA_TRX
            WHERE jur_type IN ('CLIE','T3','KPEI','T7',v_brok)
            ) v
          WHERE b.trs_dt   = V_BGN_BAL_DATE
          AND b.gl_acct_cd = v.gl_a (+)
          AND v.gl_A      IS NULL
          UNION ALL
          SELECT trim(d.gl_acct_cd) gl_acct_cd,
            DECODE(trim(d.gl_acct_cd),'3000',trim(d.sl_acct_cd),'000000') sl_acct_cd,
            (DECODE(d.db_cr_flg,'D',1,-1) * d.curr_val) curr_mvmt_A,
            0 last_mon_A,
            0 prev_year_A,
            (DECODE(d.db_cr_flg,'D',-1,1) * d.curr_val) curr_mvmt_P,
            0 last_mon_P,
            0 prev_year_P
          FROM t_account_ledger d,
            (SELECT gl_a
            FROM MST_GLA_TRX
            WHERE jur_type IN ('CLIE','T3','KPEI','T7',v_brok)
            ) v
          WHERE d.doc_date BETWEEN V_BGN_BAL_DATE AND P_END_DATE
          AND d.approved_sts <> 'C'
          AND d.approved_sts <> 'E'
          AND d.gl_acct_cd    = v.gl_a (+)
          AND v.gl_A         IS NULL
          )
        GROUP BY gl_acct_cd,
          sl_Acct_cd
        UNION ALL
        SELECT trim(gl_a)
          ||'000000',
          F_BALSH_JUL2016(item_type,'A','CURR',P_END_DATE) curr_mvmt_A,
          F_BALSH_JUL2016(item_type,'A','LASTMON',P_END_DATE) last_mon_A,
          F_BALSH_JUL2016(item_type,'A','LASTYR',P_END_DATE) prev_year_A,
          0 curr_mvmt_P,
          0 last_mon_P,
          0 prev_year_P
        FROM
          (SELECT gl_a,
            DECODE(jur_type,'CLIED','TRX','KPEID','KPEI','BROKD','BROK','T3','ARAP35','T7','ARAP103') item_type
          FROM MST_GLA_TRX
          WHERE jur_type IN ( 'CLIED','KPEID','T3','T7', v_brok||'D')
          )
        UNION ALL
        SELECT DECODE(item_type,'ARAP159','2422',trim(gl_a))
          ||'000000' gl_a,
          0 curr_mvmt_A,
          0 last_mon_A,
          0 prev_year_A,
          F_BALSH_JUL2016(item_type,'P','CURR',P_END_DATE) curr_mvmt_P,
          F_BALSH_JUL2016(item_type,'P','LASTMON',P_END_DATE) last_mon_P,
          F_BALSH_JUL2016(item_type,'P','LASTYR',P_END_DATE) prev_year_P
        FROM
          (SELECT gl_a,
            DECODE(jur_type,'CLIEC','TRX','KPEIC','KPEI', 'BROKC','BROK','T3','ARAP159') item_type
          FROM MST_GLA_TRX
          WHERE jur_type IN ( 'CLIEC','KPEIC','T3',v_brok||'C')
         -- AND (db_CR_flg   = 'C'
        --  OR jur_type     = 'T3')
          )
        ) T,
        (SELECT trim(c.gl_a)
          ||trim(c.sl_a) gl_acct10,
          c.acct_name,
          c.acct_short
        FROM mst_gl_account c
        WHERE c.sl_A = '000000'
        OR c.gl_a    = '3000'
        ) C1,
        (SELECT SUBSTR(gl_acct_cd,1,4) gl_acct4,
          SUBSTR(gl_acct_cd,1,10) gl_Acct10,
          a.grp_1,
          a.grp_2,
          a.grp_3,
          a.grp_4,
          a.grp_5,
          LINE_desc
        FROM mst_group_account a
        WHERE a.pl_bs_flg = 'N'
        AND a.grp_5       = 0
        AND formula       = 'MAR2013'
        ) M1
      WHERE M1.gl_acct10 = T.gl_acct10 (+)
      AND M1.gl_acct10   = C1.gl_acct10
      UNION
      SELECT M2.grp_1,
        M2.grp_2,
        M2.grp_3,
        M2.grp_4,
        M2.grp_5,
        M2.gl_acct_cd,
        DECODE(trim(gl_AccT_cd),'BLANK',NULL,M2.LINE_desc) acct_name,
        NULL curr_mon,
        NULL last_mon,
        NULL prev_year,
        LINE_desc
      FROM mst_group_account M2
      WHERE M2.pl_bs_flg = 'N'
      AND M2.grp_5       > 0
      AND formula        = 'MAR2013'
      )
    ORDER BY grp_1,
      grp_2,
      grp_3,
      grp_4,
      GRP_5,
      GL_ACCT_CD ;
  EXCEPTION
  WHEN OTHERS THEN
    V_ERROR_CD  :=-20;
    V_ERROR_MSG :=SUBSTR('INSERT INTO R_BALANCE_SHEET '||SQLERRM,1,200);
    RAISE V_ERR;
  END;
  
  BEGIN
    SELECT GL_A||SL_A INTO V_GLA_LR FROM MST_GLA_TRX WHERE JUR_TYPE='LRTHISYR' AND BRCH_CD LIKE P_BRANCH_CD;
  EXCEPTION
  WHEN OTHERS THEN
    V_ERROR_CD  :=-30;
    V_ERROR_MSG :=SUBSTR('SELECT ACCOUNT LABA RUGI FROM MST_GLA_TRX'||SQLERRM,1,200);
    RAISE V_ERR;
  END;
  
  BEGIN
    SELECT DFLG1
    INTO V_CHECK_BRANCH
    FROM MST_SYS_PARAM
    WHERE PARAM_ID='SYSTEM'
    AND PARAM_CD1 ='CHECK'
    AND PARAM_CD2 ='ACCTBRCH';
  EXCEPTION
  WHEN OTHERS THEN
    V_ERROR_CD  :=-40;
    V_ERROR_MSG :=SUBSTR('CHECK BRANCH FROM MST_SYS_PARAM '||SQLERRM,1,200);
    RAISE V_ERR;
  END;
  
  BEGIN
    SELECT SUM(DECODE(m.jur_type,'EXPENSE',0,DECODE(t.db_cr_flg,'C',t.curr_val,-1 * t.curr_val))) - SUM(DECODE(M.jur_type,'EXPENSE',DECODE(T.DB_CR_FLG,'D',T.CURR_VAL,-1 * T.CURR_VAL),0))
    INTO V_LR_CURR_MON
    FROM T_ACCOUNT_LEDGER t,
      (SELECT gl_a,
        sl_a,
        brch_cd,
        p.jur_type
      FROM MST_GL_ACCOUNT,
        (SELECT SUBSTR(prm_cd_2,1,1)
          ||'%' prefix,
          prm_desc jur_type
        FROM MST_PARAMETER
        WHERE prm_cd_1 = 'PLACCT'
        ) p
      WHERE gl_a LIKE prefix
      AND ( V_CHECK_BRANCH = 'N'
      OR trim(brch_cd)     LIKE P_BRANCH_CD )
      ) M
    WHERE t.doc_date BETWEEN V_BGN_BAL_DATE AND P_END_DATE
    AND (t.gl_acct_cd) = m.gl_a
    AND t.sl_acct_Cd   = m.sl_a
    AND t.approved_sts = 'A';
  EXCEPTION
  WHEN OTHERS THEN
    V_ERROR_CD  :=-50;
    V_ERROR_MSG :=SUBSTR('SELECT LABA RUGI CURRENT MONTH '||SQLERRM,1,200);
    RAISE V_ERR;
  END;
  
  BEGIN
    UPDATE R_BALANCE_SHEET
    SET CURR_MON        = CURR_MON+V_LR_CURR_MON
    WHERE RAND_VALUE    =V_RANDOM_VALUE
    AND USER_ID         =P_USER_ID
    AND TRIM(GL_ACCT_CD)=TRIM(V_GLA_LR);
  EXCEPTION
  WHEN OTHERS THEN
    V_ERROR_CD  :=-60;
    V_ERROR_MSG :=SUBSTR('UPDATE LABA RUGI CURRENT MONTH '||SQLERRM,1,200);
    RAISE V_ERR;
  END;
  
-- SUM3
  for rec in csr_sum3 loop
      BEGIN
      UPDATE R_BALANCE_SHEET
      set curr_mon = rec.curr_mon,
          last_mon = rec.last_mon,
          prev_year = rec.prev_year
       where RAND_VALUE    =V_RANDOM_VALUE
       AND USER_ID         =P_USER_ID
       and trim(gl_acct_Cd ) = 'SUM3'
       and grp_1 = rec.grp_1
       and grp_2 = rec.grp_2
       and grp_3 = rec.grp_3;
       EXCEPTION
      WHEN OTHERS THEN
        V_ERROR_CD  :=-65;
        V_ERROR_MSG :=SUBSTR('UPDATE SUM3 grp = '||rec.grp_1||'  '||rec.grp_2||' '||rec.grp_3||' '||SQLERRM,1,200);
        RAISE V_ERR;
      END;
       
  end loop;

  -- SUM2
  for rec in csr_sum2 loop
      BEGIN
      UPDATE R_BALANCE_SHEET
      set curr_mon = rec.curr_mon,
          last_mon = rec.last_mon,
          prev_year = rec.prev_year
       where RAND_VALUE    =V_RANDOM_VALUE
       AND USER_ID         =P_USER_ID
       and trim(gl_acct_Cd ) = 'SUM2'
       and  grp_1 = rec.grp_1
       and grp_2 = rec.grp_2;
       EXCEPTION
      WHEN OTHERS THEN
        V_ERROR_CD  :=-70;
        V_ERROR_MSG :=SUBSTR('UPDATE SUM2 grp = '||rec.grp_1||'  '||rec.grp_2||' '||SQLERRM,1,200);
        RAISE V_ERR;
      END;
       
  end loop;
  
  -- SUM1
  for rec in csr_sum1 loop
      BEGIN
      UPDATE R_BALANCE_SHEET
      set curr_mon = rec.curr_mon,
          last_mon = rec.last_mon,
          prev_year = rec.prev_year
       where RAND_VALUE    =V_RANDOM_VALUE
       AND USER_ID         =P_USER_ID
       and trim(gl_acct_Cd ) = 'SUM1'
       and grp_1 = rec.grp_1;
       EXCEPTION
      WHEN OTHERS THEN
        V_ERROR_CD  :=-70;
        V_ERROR_MSG :=SUBSTR('UPDATE SUM1 grp = '||rec.grp_1||SQLERRM,1,200);
        RAISE V_ERR;
      END;
       
  end loop;

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
END Spr_Balance_Sheet;