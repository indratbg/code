create or replace 
PROCEDURE SPR_R_LK_KONSOL_DETAIL(P_END_DATE DATE,
								P_BGN_DATE DATE,
								P_LK_ACCT_CD VARCHAR2,
								P_GL_A VARCHAR2,
								P_SL_A VARCHAR2,
								P_ENTITY_CD VARCHAR2,
								 P_USER_ID			VARCHAR2,
								 P_GENERATE_DATE 	DATE,
								 P_RANDOM_VALUE	OUT NUMBER,
								 P_ERRCD	 		OUT NUMBER,
								 P_ERRMSG	 		OUT VARCHAR2
								) IS
  v_random_value	NUMBER(10);
  v_err			EXCEPTION;
  v_err_cd number(10);
  v_err_msg number(10);
BEGIN

    v_random_value := abs(dbms_random.random);
    BEGIN
        SP_RPT_REMOVE_RAND('R_LK_KONSOL_DETAIL',V_RANDOM_VALUE,v_err_cd,v_err_msg);
    EXCEPTION
        WHEN OTHERS THEN
             v_err_cd := -2;
             v_err_msg := substr('SP_RPT_REMOVE_RAND'||v_err_msg,1,200);
            RAISE V_err;
    END;
  BEGIN
 
  --INSERT KE TABLE REPORT
  INSERT INTO R_LK_KONSOL_DETAIL(LK_ACCT_CD,GL_ACCT_CD,SL_ACCT_CD,COL3,	BY_ENTITY,
								BY_ACCT,USER_ID,RAND_VALUE,	GENERATE_DATE,ENTITY_CD)

		SELECT LK_ACCT, GL_ACCT_CD, SL_ACCT_CD, COL3,
		SUM(COL3) OVER (PARTITION BY LK_ACCT, ENTITY_CD ORDER BY LK_ACCT, ENTITY_CD) AS BY_ENTITY,
  SUM(COL3) OVER (PARTITION BY LK_ACCT ORDER BY LK_ACCT) AS BY_ACCT,
  P_USER_ID,V_RANDOM_VALUE, P_GENERATE_DATE,ENTITY_CD
FROM
  (SELECT LK_ACCT
    ||ENTITY_CD KEY1,
    LK_ACCT,
    ENTITY_CD,
    GL_ACCT_CD,
    SL_ACCT_CD,
    SUM(AMT * DECODE(SUBSTR(LK_ACCT,1,1),'2',-1,'3',-1,1)) AS COL3
  FROM
    (SELECT M.LK_ACCT,
      M.ENTITY_CD,
      GL_ACCT_CD,
      DECODE( M.SL_A,'#',M.SL_A, B.SL_ACCT_CD) AS SL_ACCT_CD,
      (NVL(B.DEB_OBAL,0) - NVL(B.CRE_OBAL,0)) * NVL(SIGN,1) AMT
    FROM T_DAY_TRS B,
      MST_MAP_LK M
    WHERE B.TRS_DT          = P_BGN_DATE
    AND B.GL_ACCT_CD        = M.GL_A
    AND (TRIM(B.GL_ACCT_CD) = P_GL_A
    OR P_GL_A              = '%')
    AND (M.LK_ACCT          = P_LK_ACCT_CD
    OR P_LK_ACCT_CD           ='%')
    AND (B.SL_ACCT_CD       = M.SL_A
    OR M.SL_A               = '#')
    AND ( B.SL_ACCT_CD LIKE P_SL_A)
    AND M.ENTITY_CD = 'YJ'
    AND P_ENTITY_CD  <> 'LIM'
    AND P_END_DATE BETWEEN M.VER_BGN_DT AND M.VER_END_DT
    AND M.APPROVED_STAT = 'A'
    UNION ALL
    SELECT M.LK_ACCT,
      M.ENTITY_CD,
      GL_ACCT_CD,
      DECODE( M.SL_A,'#',M.SL_A, D.SL_ACCT_CD) AS SL_ACCT_CD,
      DECODE(D.DB_CR_FLG,'D',1,-1) * D.CURR_VAL * NVL(SIGN,1) TRX_AMT
    FROM T_ACCOUNT_LEDGER D,
      MST_MAP_LK M
    WHERE D.DOC_DATE BETWEEN P_BGN_DATE AND P_END_DATE
    AND D.APPROVED_STS      = 'A'
    AND D.GL_ACCT_CD        = M.GL_A
    AND (TRIM(D.GL_ACCT_CD) = P_GL_A
    OR P_GL_A              = '%')
    AND (M.LK_ACCT          = P_LK_ACCT_CD
    OR P_LK_ACCT_CD           ='%')
    AND (D.SL_ACCT_CD       = M.SL_A
    OR M.SL_A               = '#')
    AND ( D.SL_ACCT_CD LIKE P_SL_A)
    AND M.ENTITY_CD = 'YJ'
    AND P_ENTITY_CD  <> 'LIM'
    AND P_END_DATE BETWEEN M.VER_BGN_DT AND M.VER_END_DT
    AND M.APPROVED_STAT = 'A'
    UNION ALL
    SELECT M.LK_ACCT,
      M.ENTITY_CD,
      GL_ACCT_CD,
      DECODE( M.SL_A,'#',M.SL_A, B.SL_ACCT_CD) AS SL_ACCT_CD,
      (NVL(B.DEB_OBAL,0) - NVL(B.CRE_OBAL,0)) * NVL(SIGN,1) AMT
    FROM SYN_LIM_T_DAY_TRS B,
      MST_MAP_LK M
    WHERE B.TRS_DT          = P_BGN_DATE
    AND B.GL_ACCT_CD        = M.GL_A
    AND (TRIM(B.GL_ACCT_CD) = P_GL_A
    OR P_GL_A              = '%')
    AND (M.LK_ACCT          = P_LK_ACCT_CD
    OR P_LK_ACCT_CD           ='%')
    AND (B.SL_ACCT_CD       = M.SL_A
    OR M.SL_A               = '#')
    AND ( B.SL_ACCT_CD LIKE P_SL_A)
    AND M.ENTITY_CD = 'LIM'
    AND P_ENTITY_CD  <> 'YJ'
    AND P_END_DATE BETWEEN M.VER_BGN_DT AND M.VER_END_DT
    AND M.APPROVED_STAT = 'A'
    UNION ALL
    SELECT M.LK_ACCT,
      M.ENTITY_CD,
      GL_ACCT_CD,
      DECODE( M.SL_A,'#',M.SL_A, D.SL_ACCT_CD) AS SL_ACCT_CD,
      DECODE(D.DB_CR_FLG,'D',1,-1) * D.CURR_VAL * NVL(SIGN,1) TRX_AMT
    FROM SYN_LIM_T_ACCOUNT_LEDGER D,
      MST_MAP_LK M
    WHERE D.DOC_DATE BETWEEN P_BGN_DATE AND P_END_DATE
    AND D.APPROVED_STS      = 'A'
    AND D.GL_ACCT_CD        = M.GL_A
    AND (TRIM(D.GL_ACCT_CD) = P_GL_A
    OR P_GL_A              = '%')
    AND (M.LK_ACCT          = P_LK_ACCT_CD
    OR P_LK_ACCT_CD           ='%')
    AND (D.SL_ACCT_CD       = M.SL_A
    OR M.SL_A               = '#')
    AND ( D.SL_ACCT_CD LIKE P_SL_A)
    AND M.ENTITY_CD = 'LIM'
    AND P_ENTITY_CD  <> 'YJ'
    AND P_END_DATE BETWEEN M.VER_BGN_DT AND M.VER_END_DT
    AND M.APPROVED_STAT = 'A'
    )
  GROUP BY LK_ACCT,
    ENTITY_CD,
    GL_ACCT_CD,
    SL_ACCT_CD
  )
ORDER BY LK_ACCT,
  ENTITY_CD,
  GL_ACCT_CD,
  SL_ACCT_CD;
	

			
			
			
			

    EXCEPTION
    WHEN NO_DATA_FOUND THEN
    V_ERR_CD := -100;
    V_ERR_MSG :='NO DATA FOUND';
    RAISE V_ERR;
        WHEN OTHERS THEN
             v_err_cd := -3;
             v_err_msg := SQLERRM(SQLCODE);
            RAISE V_err;
    END;

    p_random_value := v_random_value;
    p_errcd := 1;
    p_errmsg := '';
  
EXCEPTION
    WHEN V_err THEN
        ROLLBACK;
		 p_errcd := v_err_cd;
        p_errmsg := v_err_msg;
    WHEN OTHERS THEN
        ROLLBACK;
        p_errcd := -1;
        p_errmsg := SUBSTR(SQLERRM(SQLCODE),1,200);
END SPR_R_LK_KONSOL_DETAIL;