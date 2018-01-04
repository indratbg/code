create or replace 
PROCEDURE SPR_REPO_HARIAN(
    P_END_DATE      DATE,
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
  V_BGN_REPO     DATE;
  V_KODE_BROKER VARCHAR2(2);
  V_NAMA_AB MST_COMPANY.NAMA_PRSH%TYPE;
  
  --WITH CHANGE TICKER CODE--
  
BEGIN

  v_random_value := ABS(dbms_random.random);
  
  BEGIN
    SP_RPT_REMOVE_RAND('R_REPO_HARIAN',V_RANDOM_VALUE,V_ERROR_MSG,V_ERROR_CD);
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
    INTO V_BGN_REPO
    FROM MST_SYS_PARAM
    WHERE PARAM_ID='REPO_HARIAN'
    AND PARAM_cD1 ='REPORT'
    AND PARAM_CD2 ='START';
  EXCEPTION
  WHEN OTHERS THEN
    V_ERROR_CD  := -30;
    V_ERROR_MSG := 'SELECT BEGIN REPO FROM MST_SYS_PARAM';
    RAISE V_err;
  END;
   

   BEGIN
  SELECT SUBSTR(BROKER_CD,1,2) into V_KODE_BROKER FROM V_BROKER_SUBREK;
  EXCEPTION
  WHEN OTHERS THEN
    V_ERROR_CD  := -40;
    V_ERROR_MSG := 'SELECT BROKER CODE FROM  V_BROKER_SUBREK';
    RAISE V_err;
  END;
  
  BEGIN
	SELECT NAMA_PRSH INTO V_NAMA_AB FROM MST_COMPANY;
  EXCEPTION
  WHEN OTHERS THEN
    V_ERROR_CD  := -45;
    V_ERROR_MSG := 'SELECT NAMA PERUSAHAAN FROM MST_COMPANY';
    RAISE V_err;
  END;


  BEGIN
    INSERT
    INTO R_REPO_HARIAN
      (
        REPORT_DATE ,
        REPO_NUM ,
        REPO_TYPE ,
        CLIENT_CD ,
        REPO_DATE ,
        EXTENT_DT ,
        DUE_DATE ,
        STK_CD ,
        SUM_QTY ,
        BOND_QTY ,
        SUM_AMT ,
        DAYS ,
        REPO_REF ,
        LAWAN ,
        STK_PRICE ,
        BOND_PRICE ,
        AGUNAN_PRC ,
        USER_ID ,
        RAND_VALUE ,
        GENERATE_DATE,
        nama_prsh,
        kode_ab
      )
	  SELECT 
	  P_END_DATE ,
       NULL REPO_NUM ,
       NULL REPO_TYPE ,
       'TXT' CLIENT_CD ,
       NULL REPO_DATE ,
       NULL EXTENT_DT ,
       NULL DUE_DATE ,
       NULL STK_CD ,
       NULL SUM_QTY ,
       NULL BOND_QTY ,
       NULL SUM_AMT ,
       NULL DAYS ,
       NULL REPO_REF ,
       NULL LAWAN ,
       NULL STK_PRICE ,
       NULL BOND_PRICE ,
       NULL AGUNAN_PRC ,
        P_USER_ID,
        V_RANDOM_VALUE ,
        P_GENERATE_DATE,
        V_NAMA_AB,
        V_KODE_BROKER
		FROM DUAL
	  UNION ALL
    SELECT P_END_DATE,
      e.repo_num,
      e.repo_type,
      e.client_cd,
      e.repo_date,
      e.extent_dt,
      e.due_date,
      a.stk_cd,
      a.sum_qty,
      a.bond_qty,
      d.sum_amt,
      e.due_date - e.extent_dt AS days,
      e.repo_ref,
      e.lawan,
      NVL(c.stk_price, 0)                  AS stk_price,
      NVL(c.bond_price, 0)                 AS bond_price,
      ROUND(b.agunan / d.sum_amt * 100, 0) AS agunan_prc ,
      P_USER_ID,
      V_RANDOM_VALUE,
      P_GENERATE_DATE,
      F.nama_prsh,
      V_KODE_BROKER
    FROM
      (SELECT repo_num,
        a1.stk_cd,
        SUM(DECODE(m1.ctr_type,'OB',0,qty)) sum_qty,
        SUM(DECODE(m1.ctr_type,'OB',qty,0)) bond_qty
      FROM
        (SELECT DECODE(h.repo_type,'REPO',2,1) repo_type,
          h.client_cd,
          h.repo_date,
          r.repo_num,
          m.doc_num,
          m.doc_dt,
          NVL(C.STK_CD_NEW,m.stk_cd)STK_CD,
          m.total_share_qty * DECODE(trim(gl_acct_cd),'50',1,-1) * DECODE(m.db_cr_flg,'D',-1,1) qty,
          m.doc_rem
        FROM T_REPO_STK r,
          T_STK_MOVEMENT m,
          T_REPO h,
		  (SELECT STK_CD_NEW, STK_CD_OLD FROM T_CHANGE_STK_CD WHERE EFF_DT<=P_END_DATE)C
        WHERE r.doc_num   = m.doc_num
        AND m.gl_acct_cd IN ('09','50')
        AND m.doc_num LIKE '%JVA%'
        AND m.doc_stat = '2'
        AND m.doc_dt BETWEEN V_BGN_REPO AND P_END_DATE
		AND M.STK_CD=C.STK_CD_OLD(+)
        AND r.repo_num = h.repo_num
        ) a1,
        MST_COUNTER m1
      WHERE a1.stk_Cd = m1.stk_cd
      GROUP BY repo_num,
        a1.stk_cd
      ) a,
      (SELECT b1.repo_num,
        SUM(NVL(b2.price, 0) * b1.repo_qty) AS agunan
      FROM
        (
		SELECT REPO_NUM, STK_CD, SUM(REPO_QTY)REPO_QTY FROM--09SEP2016
		(
		SELECT r.repo_num,
           NVL(C.STK_CD_NEW,m.stk_cd)STK_CD,
          m.total_share_qty * DECODE(trim(gl_acct_cd),'50',1,-1) * DECODE(m.db_cr_flg,'D',-1,1)AS repo_qty
        FROM T_REPO_STK r,
          T_STK_MOVEMENT m,
          T_REPO h,
		   (SELECT STK_CD_NEW, STK_CD_OLD FROM T_CHANGE_STK_CD WHERE EFF_DT<=P_END_DATE)C
        WHERE r.doc_num   = m.doc_num
        AND m.gl_acct_cd IN ('09','50')
        AND m.doc_num LIKE '%JVA%'
        AND m.doc_stat = '2'
        AND m.doc_dt BETWEEN V_BGN_REPO AND P_END_DATE
        AND r.repo_num      = h.repo_num
		AND M.STK_CD=C.STK_CD_OLD(+)
        AND h.approved_stat = 'A'
       )
		GROUP BY repo_num,
          stk_cd
       
	   ) b1,
        (SELECT stk_cd,
          DECODE(NVL(stk_clos,0),0,NVL(stk_prev,0),stk_clos) price
        FROM v_stk_clos
        WHERE stk_date = P_END_DATE
        UNION
        SELECT bond_cd ,
          price/ 100 price
        FROM T_BOND_PRICE
        WHERE price_dt    = P_END_DATE
        AND approved_stat = 'A'
        ) b2
      WHERE b1.stk_cd = b2.stk_cd(+)
      GROUP BY b1.repo_num
      ) b,
      (SELECT stk_cd,
        DECODE(NVL(stk_clos,0),0,NVL(stk_prev,0),stk_clos) stk_price,
        0 bond_price
      FROM v_stk_clos
      WHERE stk_date = P_END_DATE
      UNION
      SELECT bond_cd ,
        0,
        price bond_price
      FROM T_BOND_PRICE
      WHERE price_dt = P_END_DATE
      ) c,
      (SELECT REPO_NUM,
        SUM(amt) AS sum_amt
      FROM T_REPO_VCH
      WHERE doc_dt BETWEEN V_BGN_REPO AND P_END_DATE
      AND approved_stat = 'A'
      GROUP BY repo_num
      ) d,
      (SELECT r.repo_num,
        DECODE(r.repo_type,'REPO',2,1) repo_type,
        r.client_cd,
        r.repo_date,
        r.due_date,
        r.extent_dt,
        NVL(r.extent_num, r.repo_ref) repo_ref,
        m.client_name lawan
      FROM T_REPO R,
        MST_CLIENT m
      WHERE r.client_cd   = m.client_cd
      AND r.approved_stat = 'A'
      ) e,
      MST_COMPANY f
    WHERE e.repo_num             = a.repo_num
    AND e.repo_num               = d.repo_num
    AND d.sum_amt                > 0
    AND (a.sum_qty + a.bond_qty) > 0
    AND a.stk_cd                 = c.stk_cd(+)
    AND E.REPO_NUM               = B.REPO_NUM
    ORDER BY repo_num,stk_cd;
  EXCEPTION
  WHEN OTHERS THEN
    V_ERROR_CD  := -50;
    V_ERROR_MSG := SUBSTR('INSERT R_REPO_HARIAN '||V_ERROR_MSG||SQLERRM(SQLCODE),1,200);
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
END SPR_REPO_HARIAN;