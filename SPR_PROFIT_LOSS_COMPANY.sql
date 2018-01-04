create or replace PROCEDURE SPR_PROFIT_LOSS_COMPANY(
    P_END_DATE      DATE,
    P_BGN_BRANCH    VARCHAR2,
    P_END_BRANCH    VARCHAR2,
    P_USER_ID       VARCHAR2,
    P_GENERATE_DATE DATE,
    P_RANDOM_VALUE OUT NUMBER,
    P_ERROR_CD OUT NUMBER,
    P_ERROR_MSG OUT VARCHAR2 )
IS
  v_random_value NUMBER(10);
  
cursor csr_sum4 is
SELECT R.GRP_1, R.GRP_2, R.GRP_3, R.GRP_4, C.GRP_5,  
  SUM(curr_mon) curr_mon,  SUM(last_mon) last_mon,  SUM(bal_ytd) bal_ytd
  FROM R_PROFIT_LOSS_COMPANY  R,
  (   SELECT GRP_1, GRP_2, GRP_3, GRP_4, GRP_5
    FROM MST_GROUP_ACCOUNT
	WHERE pl_bs_flg = 'L' 	AND   gl_acct_cd = 'SUM4'
	) C
  WHERE generate_date = P_GENERATE_DATE
  AND RAND_VALUE = V_RANDOM_VALUE
  AND GL_acct_Cd <> 'BLANK'
  AND GL_acct_Cd <> 'SUM4'
  AND GL_acct_Cd <> 'LR3'
  AND R.GRP_1 = C.GRP_1 AND R.GRP_2 = C.GRP_2  AND R.GRP_3 = C.GRP_3 AND R.GRP_4 = C.GRP_4
  AND  R.GRP_5 <> C.GRP_5
  GROUP BY R.GRP_1, R.GRP_2, R.GRP_3, R.GRP_4, C.GRP_5; 
  
--cursor csr_LR3 is
--SELECT R.GRP_1, R.GRP_2, R.GRP_3,  C.GRP_4,  C.GRP_5, 
--  SUM(lr_curr_mon) curr_mon,  SUM(lr_last_mon) last_mon,  SUM(lr_bal_ytd) bal_ytd
--  FROM R_PROFIT_LOSS_COMPANY  R,
--  (   SELECT GRP_1, GRP_2, GRP_3, GRP_4, GRP_5
--    FROM MST_GROUP_ACCOUNT
--	WHERE pl_bs_flg = 'L' 	AND   gl_acct_cd = 'LR3'
--	) C
--  WHERE generate_date = P_GENERATE_DATE
--  AND RAND_VALUE = V_RANDOM_VALUE
--  AND GL_acct_Cd <> 'BLANK'
--  AND GL_acct_Cd <> 'SUM4'
--  AND GL_acct_Cd <> 'LR3'
--  AND R.GRP_1 = C.GRP_1 AND R.GRP_2 = C.GRP_2  AND R.GRP_3 = C.GRP_3 
--  GROUP BY R.GRP_1, R.GRP_2, R.GRP_3,  C.GRP_4,  C.GRP_5; 
    
cursor csr_LR2 is    
SELECT R.GRP_1, R.GRP_2, C.GRP_3,  C.GRP_4,  C.GRP_5,
  SUM(lr_curr_mon) curr_mon,  SUM(lr_last_mon) last_mon,  SUM(lr_bal_ytd) bal_ytd
  FROM R_PROFIT_LOSS_COMPANY  R,
  (   SELECT GRP_1, GRP_2, GRP_3, GRP_4, GRP_5
    FROM MST_GROUP_ACCOUNT
	WHERE pl_bs_flg = 'L' 	AND   gl_acct_cd = 'LR2'
	) C
  WHERE generate_date =  P_GENERATE_DATE
  AND RAND_VALUE =  V_RANDOM_VALUE
  AND GL_acct_Cd <> 'BLANK'
  AND GL_acct_Cd <> 'SUM4'
  AND GL_acct_Cd <> 'LR3'
    AND GL_acct_Cd <> 'LR2'
  AND R.GRP_1 = C.GRP_1 AND R.GRP_2 = C.GRP_2  AND R.GRP_3 <= C.GRP_3  
GROUP BY R.GRP_1, R.GRP_2, C.GRP_3, C.GRP_4,  C.GRP_5; 
    

  

  V_ERROR_MSG    VARCHAR2(200);
  V_ERROR_CD     NUMBER(10);

  V_ERR          EXCEPTION;
  V_BGN_DATE     DATE;
  V_LAST_BAL_DATE DATE;
  V_BGN_BAL_DATE  DATE;
    
BEGIN

  v_random_value := ABS(dbms_random.random);
  --v_random_value :=0;
  
  BEGIN
    SP_RPT_REMOVE_RAND('R_PROFIT_LOSS_COMPANY',V_RANDOM_VALUE,V_ERROR_MSG,V_ERROR_CD);
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
  
  V_BGN_DATE := to_date('01/'||to_char(p_end_date,'MM/YYYY'),'DD/MM/YYYY');
  V_BGN_BAL_DATE := V_BGN_DATE;
  V_LAST_BAL_DATE := V_BGN_DATE  - 1;
  V_LAST_BAL_DATE := to_date('01/'||to_char(V_LAST_BAL_DATE,'MM/YYYY'),'DD/MM/YYYY');
   
  BEGIN
    INSERT
    INTO R_PROFIT_LOSS_COMPANY
      (
        BGN_DT ,
        END_DT ,
        GRP_1 ,
        GRP_2 ,
        GRP_3 ,
        GRP_4 ,
        GRP_5 ,
        GL_ACCT_CD ,
        MACCT_NAME ,
        CURR_MON ,
        LAST_MON ,
        BAL_YTD ,
        LR_CURR_MON ,
        LR_LAST_MON ,
        LR_BAL_YTD ,
        USER_ID,
        RAND_VALUE ,
        GENERATE_DATE
      )
    SELECT V_BGN_DATE,
      P_END_DATE,
      M1.grp_1,
      M1.grp_2,
      M1.grp_3,
      M1.grp_4,
      M1.grp_5,
      M1.GL_Acct_cd,
      DECODE(NVL(M1.Line_desc,'X'),'X',D1.acct_name, M1.line_desc) macct_name,
      DECODE(d1.pl_CD,'EXPENSE',DECODE(grp_3,2,-1,1), -1)  * SUM(NVL(A1.curr_mon,0)) curr_mon,
      DECODE(d1.pl_CD,'EXPENSE',DECODE(grp_3,2,-1,1), -1)  * SUM(NVL(B1.beg_bal,0) - NVL(E1.lastbal,0)) last_mon,
      DECODE(d1.pl_CD,'EXPENSE',DECODE(grp_3,2,-1,1), -1)  * SUM(NVL(B1.beg_bal,0) +NVL(A1.curr_mon,0)) bal_ytd,
                              -1 * SUM(NVL(A1.curr_mon,0)) LR_curr_mon,
                              -1 * SUM(NVL(B1.beg_bal,0) - NVL(E1.lastbal,0)) lr_last_mon,
                              -1 * SUM(NVL(B1.beg_bal,0) +NVL(A1.curr_mon,0)) lr_bal_ytd,
      P_USER_ID,
      V_RANDOM_VALUE,
      P_GENERATE_DATE
    FROM
      (SELECT trim(a.GL_ACCT_CD) AGl_Acct,
        SUM(DECODE(a.db_cr_flg,'D',1,-1) * NVL(a.curr_val,0)) curr_mon
      FROM T_ACCOUNT_LEDGER a,
        MST_GL_ACCOUNT g
      WHERE a.doc_date BETWEEN V_BGN_DATE AND P_END_DATE
      AND a.approved_sts    <> 'C'
      AND a.approved_sts    <> 'E'
      AND trim(a.gl_acct_cd )= trim(g.gl_a)
      AND a.sl_acct_cd       = g.sl_a
      AND trim(NVL(g.brch_cd,'%')) BETWEEN P_BGN_BRANCH AND P_END_BRANCH
      GROUP BY trim(a.GL_ACCT_CD)
      ) A1,
      (SELECT trim(e.GL_ACCT_CD) EGl_Acct,
        SUM(NVL(e.deb_obal,0) - NVL(e.cre_obal,0)) lastbal
      FROM T_DAY_TRS e,
        MST_GL_ACCOUNT g
      WHERE e.trs_dt         = V_LAST_BAL_DATE
      AND trim(e.gl_acct_cd) = trim(g.gl_a)
      AND e.sl_acct_cd       = g.sl_a
      AND trim(NVL(g.brch_cd,'%')) BETWEEN P_BGN_BRANCH AND P_END_BRANCH
      GROUP BY trim(e.GL_ACCT_CD)
      ) E1,
      (SELECT trim(b.GL_ACCT_CD) BGl_Acct,
        SUM(NVL(b.deb_obal,0) - NVL(b.cre_obal,0)) beg_bal
      FROM T_DAY_TRS b,
        MST_GL_ACCOUNT g
      WHERE b.trs_dt         = V_BGN_BAL_DATE
      AND trim(b.gl_acct_cd) = trim(g.gl_a)
      AND b.sl_acct_cd       = g.sl_a
      AND trim(NVL(g.brch_cd,'%')) BETWEEN P_BGN_BRANCH AND P_END_BRANCH
      GROUP BY trim(b.GL_ACCT_CD)
      ) B1,
      ( SELECT DISTINCT trim( gl_a) Cgl_acct
      FROM MST_GL_ACCOUNT
      WHERE trim(NVL(brch_cd,'%')) BETWEEN P_BGN_BRANCH AND P_END_BRANCH
      ) C1,
      (SELECT trim(gl_a) Dgl_acct,      acct_name, db_Cr_flg, PL_CD
      FROM MST_GL_ACCOUNT, 
      ( SELECT SUBSTR(PRM_CD_2,1,1) AS PREFIX_GLA, PRM_DESC PL_CD
      FROM MST_PARAMETER
      WHERE prm_cd_1 = 'PLACCT') P
      WHERE sl_a = '000000'
      AND SUBSTR(gl_a,1,1) = Prefix_gla(+)
      ) D1,
      MST_GROUP_ACCOUNT M1
    WHERE M1.pl_bs_flg            = 'L'
    AND Cgl_acct                  = Agl_acct (+)
    AND Cgl_acct                  = BGL_acct (+)
    AND Cgl_acct                  = EGL_acct (+)
    AND Cgl_acct                  = DGL_acct (+)
    AND SUBSTR(M1.gl_acct_cd,1,4) = trim(C1.Cgl_acct)
    GROUP BY M1.grp_1,
      M1.grp_2,
      M1.grp_3,
      M1.grp_4,
      M1.grp_5,
      M1.gl_acct_cd,
      D1.acct_name, D1.PL_CD,
      M1.line_desc
    UNION
    SELECT  V_BGN_DATE,
      P_END_DATE,
      M2.grp_1,
      M2.grp_2,
      M2.grp_3,
      M2.grp_4,
      M2.grp_5,
      M2.gl_acct_cd,
      M2.LINE_desc,
      0 curr_mon,
      0 last_mon,
      0 end_bal,
      0 lr_curr_mon,
      0 lr_last_mon,
      0 lr_end_bal,
       P_USER_ID,
      V_RANDOM_VALUE,
      P_GENERATE_DATE
    FROM MST_GROUP_ACCOUNT M2
    WHERE M2.pl_bs_flg = 'L'
    AND (M2.gl_acct_cd BETWEEN 'A%' AND 'Z_')
    ORDER BY 1,2,3,4,5;
  EXCEPTION
  WHEN OTHERS THEN
    V_ERROR_CD  := -30;
    V_ERROR_MSG := SUBSTR('INSERT R_PROFIT_LOSS_COMPANY '||V_ERROR_MSG||SQLERRM(SQLCODE),1,200);
    RAISE V_err;
  END;
   
  
   for rec in csr_sum4 loop
     begin
      update R_PROFIT_LOSS_COMPANY
      set curr_mon = rec.curr_mon, 
          last_mon = rec.last_mon,
          bal_ytd = rec.bal_ytd
      where generate_Date = p_generate_Date
      and rand_value = V_random_value
      and grp_1 = rec.grp_1
      and grp_2 = rec.grp_2
      and grp_3 = rec.grp_3
      and grp_4 = rec.grp_4
      and grp_5 = rec.grp_5;
      EXCEPTION
    WHEN OTHERS THEN
      V_ERROR_CD  := -40;
      V_ERROR_MSG := SUBSTR('UPD SUM4 R_PROFIT_LOSS_COMPANY '||V_ERROR_MSG||SQLERRM(SQLCODE),1,200);
      RAISE V_err;
    END;
  end loop;
   
--   for rec in csr_lr3 loop
--        begin
--        update R_PROFIT_LOSS_COMPANY
--        set curr_mon = rec.curr_mon, 
--            last_mon = rec.last_mon,
--            bal_ytd = rec.bal_ytd
--        where generate_Date = p_generate_Date
--        and rand_value = V_random_value
--        and grp_1 = rec.grp_1
--        and grp_2 = rec.grp_2
--        and grp_3 = rec.grp_3
--        and grp_4 = rec.grp_4
--        and grp_5 = rec.grp_5;
--        EXCEPTION
--        WHEN OTHERS THEN
--          V_ERROR_CD  := -40;
--          V_ERROR_MSG := SUBSTR('UPD LR3 R_PROFIT_LOSS_COMPANY '||V_ERROR_MSG||SQLERRM(SQLCODE),1,200);
--          RAISE V_err;
--        END;
--  end loop;
  
  for rec in csr_lr2 loop
    begin
        update R_PROFIT_LOSS_COMPANY
        set curr_mon = rec.curr_mon, 
            last_mon = rec.last_mon,
            bal_ytd = rec.bal_ytd
        where generate_Date = p_generate_Date
        and rand_value = V_random_value
        and grp_1 = rec.grp_1
        and grp_2 = rec.grp_2
        and grp_3 = rec.grp_3
        and grp_4 = rec.grp_4
        and grp_5 = rec.grp_5;
        EXCEPTION
        WHEN OTHERS THEN
          V_ERROR_CD  := -40;
          V_ERROR_MSG := SUBSTR('UPD LR2 R_PROFIT_LOSS_COMPANY '||V_ERROR_MSG||SQLERRM(SQLCODE),1,200);
          RAISE V_err;
        END;        
  end loop;
  
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
END SPR_PROFIT_LOSS_COMPANY;