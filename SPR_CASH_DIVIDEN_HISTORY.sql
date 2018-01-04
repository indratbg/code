create or replace 
PROCEDURE SPR_CASH_DIVIDEN_HISTORY(
    P_BGN_DATE      DATE,
    P_END_DATE      DATE,
    P_CLIENT_CD     VARCHAR2,
    P_STK_CD        VARCHAR2,
    P_BRANCH_CD mst_client.branch_code%type,
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
  --V_BAL_DT       DATE;
  V_DATE DATE;
BEGIN

  v_random_value := ABS(dbms_random.random);
  
  BEGIN
    SP_RPT_REMOVE_RAND('R_CASH_DIVIDEN_HIST',V_RANDOM_VALUE,V_ERROR_MSG,V_ERROR_CD);
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
    SELECT DDATE1
    INTO V_DATE
    FROM mst_sys_param
    WHERE param_id='CASH DIVIDEN HIST'
    AND param_cd1 ='START'
    AND param_cd2 ='TCASHDIV';
  EXCEPTION
  WHEN OTHERS THEN
    V_ERROR_CD  := -30;
    V_ERROR_MSG := SUBSTR('SELECT DATE FROM MST_SYS_PARAM '||SQLERRM(SQLCODE),1,200);
    RAISE V_err;
  END;
  
  IF V_DATE> P_BGN_DATE THEN
    
    BEGIN
      INSERT
      INTO R_CASH_DIVIDEN_HIST
        (
          PAYREC_DATE ,
          CIFS ,
          CLIENT_CD ,
          CLIENT_NAME ,
          BRANCH_CODE ,
          STK_CD ,
          REM_NAME ,
          DIV_AMT ,
          TAX ,
          USER_ID ,
          RAND_VALUE ,
          GENERATE_DATE
        )
      SELECT d.payrec_date,
        f.cifs,
        d.client_cd,
        c.client_name,
        c.branch_code,
        a.stk_cd,
        c.rem_name,
        d.payrec_amt,
        ROUND(d.payrec_amt / 9,2) tax,
        P_USER_ID,
        V_RANDOM_VALUE,
        P_GENERATE_DATE
      FROM
        (SELECT payrec_num,
          --DECODE(LENGTH(p.client_Cd),10,SUBSTR(p.client_cd,1,4),SUBSTR(p.client_Cd,3,4)) stk_cd
        DECODE(LENGTH(p.client_Cd),10,SUBSTR(SUBSTR(p.client_Cd,3),1,LENGTH(SUBSTR(p.client_Cd,3))-6),SUBSTR(p.client_Cd,3)) stk_cd--05SEP2016
        FROM T_PAYRECH p,
          MST_CLIENT m
        WHERE p.payrec_date BETWEEN P_BGN_DATE AND P_END_DATE
        AND p.payrec_type  = 'RD'
        AND p.client_Cd   IS NOT NULL
        AND p.client_Cd   <> 'KPEI'
        AND p.client_Cd    = m.client_cd(+)
        AND m.client_Cd   IS NULL
        AND p.approved_sts ='A'
        ) a,
        T_PAYRECD D,
        (SELECT client_Cd,
          cifs,
          client_name,
          branch_code,
          rem_name
        FROM MST_CLIENT,
          mst_sales
        WHERE MST_CLIENT.rem_Cd = mst_sales.rem_cd(+)
        AND trim(MST_CLIENT.BRANCH_CODE) LIKE P_BRANCH_CD--24AUG2016
        ) C,
        MST_CIF f
      WHERE A.payrec_num = d.payrec_num
      AND d.client_cd    = c.client_cd
      AND f.cifs         = c.cifs
      AND (f.cifs        = P_CLIENT_CD
      OR P_CLIENT_CD     = 'A')
      AND (a.stk_Cd      = P_STK_CD
      OR P_STK_CD        = 'A')
       --AND (trim(c.branch_code) = :s_branch_code OR :s_branch_code = 'A')
      ORDER BY 2,
        1 ;
    EXCEPTION
    WHEN OTHERS THEN
      V_ERROR_CD  := -40;
      V_ERROR_MSG := SUBSTR('INSERT R_CASH_DIVIDEN_HIST '||V_ERROR_MSG||SQLERRM(SQLCODE),1,200);
      RAISE V_err;
    END;
    
  ELSE

    BEGIN
      INSERT
      INTO R_CASH_DIVIDEN_HIST
        (
          PAYREC_DATE ,
          CIFS ,
          CLIENT_CD ,
          CLIENT_NAME ,
          BRANCH_CODE ,
          STK_CD ,
          REM_NAME ,
          DIV_AMT ,
          TAX ,
          USER_ID ,
          RAND_VALUE ,
          GENERATE_DATE
        )
      SELECT p.payrec_date,
        c.cifs,
        c.client_cd,
        c.client_name,
        c.branch_code,
        t.stk_cd,
        c.rem_name,
        t.div_amt,
        t.tax_amt tax ,
        P_USER_ID,
        V_RANDOM_VALUE,
        P_GENERATE_DATE
      FROM
        (SELECT distrib_dt,
          stk_cd,
          t.client_cd,
          tax_amt,
          div_amt,
          m.cifs
        FROM t_cash_dividen t,
          MST_CLIENT m
        WHERE t.approved_stat ='A'
        AND t.client_cd       = m.client_Cd
        ) t,
        (SELECT payrec_num,
          payrec_date,
          --DECODE(LENGTH(p.client_Cd),10,SUBSTR(p.client_cd,1,4),SUBSTR(p.client_Cd,3,4)) stk_cd
          DECODE(LENGTH(p.client_Cd),10,SUBSTR(SUBSTR(p.client_Cd,3),1,LENGTH(SUBSTR(p.client_Cd,3))-6),SUBSTR(p.client_Cd,3)) stk_cd--05SEP2016
        FROM T_PAYRECH p,
          MST_CLIENT m
        WHERE p.payrec_date BETWEEN P_BGN_DATE AND P_END_DATE
        AND p.payrec_type  = 'RD'
        AND p.client_Cd   IS NOT NULL
        AND p.client_Cd   <> 'KPEI'
        AND p.client_Cd    = m.client_cd(+)
        AND m.client_Cd   IS NULL
        AND p.approved_sts ='A'
        ) p,
        (SELECT client_Cd,
          mst_client.cifs,
          cif_name AS client_name,
          branch_code,
          rem_name
        FROM MST_CLIENT,
          MST_CIF,
          mst_sales
        WHERE mst_client.cifs IS NOT NULL
        AND (mst_client.cifs    like P_CLIENT_CD or p_client_cd='A')
        AND mst_client.cifs    = mst_cif.cifs
        AND trim(MST_CLIENT.BRANCH_CODE) LIKE P_BRANCH_CD--24AUG2016 
        AND MST_CLIENT.rem_Cd  = mst_sales.rem_cd(+)
        ) C
      WHERE p.payrec_date = t.distrib_dt
      AND p.stk_cd        = t.stk_cd
      AND t.client_Cd     = c.client_Cd
      and (p.stk_cd = p_stk_cd or p_stk_cd ='A')
      ORDER BY 2 ;
    EXCEPTION
    WHEN OTHERS THEN
      V_ERROR_CD  := -40;
      V_ERROR_MSG := SUBSTR('INSERT R_CASH_DIVIDEN_HIST '||V_ERROR_MSG||SQLERRM(SQLCODE),1,200);
      RAISE V_err;
    END;
    
  END IF;
  
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
END SPR_CASH_DIVIDEN_HISTORY;