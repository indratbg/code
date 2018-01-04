create or replace PROCEDURE SPR_RECON_OUTST_ARAP(
    P_BGN_DATE      DATE,
    P_END_DATE      DATE,
    P_OPTION        VARCHAR2,
    P_BGN_CLIENT     VARCHAR2,
    P_END_CLIENT     VARCHAR2,
    P_before_bgn_date varchar2,
    P_USER_ID       VARCHAR2,
    P_GENERATE_DATE DATE,
    P_RANDOM_VALUE OUT NUMBER,
    P_ERROR_CD OUT NUMBER,
    P_ERROR_MSG OUT VARCHAR2 )
IS
/*
    OCT 2016 sql dirubah
    18apr2016 dirubah krn netting flg di MU, YJ bukan number
    1jun2016 tambah: AND SUBSTR(t.ledger_nar,1,3) <> 'REV' 
*/

  V_ERROR_MSG    VARCHAR2(200);
  V_ERROR_CD     NUMBER(10);
  v_random_value NUMBER(10);
  V_ERR          EXCEPTION;
  V_BAL_DT       DATE;
  v_bgn_date     DATE;
  v_end_date     DATE;
  v_bgn_client   mst_client.client_Cd%type;
  v_end_client   mst_client.client_Cd%type;
  v_option       varchar2(5);
  v_before_bgn_date char(1);
BEGIN

  v_random_value := ABS(dbms_random.random);
  
  BEGIN
    SP_RPT_REMOVE_RAND('R_RECON_OUTSTANDING_ARAP',V_RANDOM_VALUE,V_ERROR_MSG,V_ERROR_CD);
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
  
  V_BAL_DT :=P_END_DATE - TO_CHAR(P_END_DATE,'DD') +1;
  v_end_date := p_end_date;
  
  select last_day(max(begin_date)) + 1 into v_bgn_date
  from t_begin_arap_outstand;
   
    v_bgn_client := P_BGN_CLIENT;
    v_end_client := P_END_CLIENT;

/*
  if p_client_Cd = '%' then
    v_bgn_client := 'V%';
    v_end_client := 'V_';
  else
      v_bgn_client := p_client_Cd;
      v_end_client := p_client_Cd;
   end if; 
  */
   v_option := p_option;
   v_before_bgn_date := 'Y';
   
    INSERT INTO TEMP_OUTS_TAL_SETTLE
    SELECT trim(t.sl_acct_Cd) sl_acct_Cd,doc_date, 
                            DECODE(SUBSTR(t.xn_doc_num,6,1),'I', t.doc_ref_num,t.xn_doc_num) doc_ref_num, 
                            t.tal_id AS doc_tal_id, 
                            doc_date AS jur_date, t.xn_doc_num, 
                             t.tal_id, 
                             trim(t.gl_acct_Cd) gl_acct_Cd, 
                             DECODE(db_Cr_flg,'D',1,-1) * curr_val AS  ori_amt, 
                             record_source ,    due_date, t.cre_DT, t.budget_cd  , null 
                      FROM T_ACCOUNT_LEDGER t,
                         (  SELECT m.client_Cd 	,   v_bgn_date 		AS begin_date		
                              FROM MST_CLIENT m 	, T_BEGIN_ARAP_OUTSTAND b	
                             WHERE  v_before_bgn_date = 'N'
                             AND m.clienT_cd = b.client_cd(+)
                             AND b.client_cd IS NULL
                             AND m.client_type_1 IN ('I','C') 
                             AND trim(m.client_Cd ) BETWEEN   v_bgn_client AND  v_end_client
                             UNION ALL
                             SELECT client_cd, begin_date
                             FROM T_BEGIN_ARAP_OUTSTAND
                             WHERE  v_before_bgn_date = 'Y'
                             AND  client_Cd   BETWEEN   v_bgn_client AND  v_end_client
                             ) m
                        WHERE t.sl_Acct_Cd = m.client_Cd 					
                         AND doc_Date BETWEEN m.begin_date  AND  v_end_date 
                         AND record_source IN ( 'CG','PD','RD','RVO','PVO','DNCN','GL') 
                         AND reversal_jur = 'N' 
                         AND t.approved_sts = 'A' ;
                         
    INSERT INTO TEMP_OUTS_TAL_SETTLE2                     
   SELECT trim(t.sl_acct_Cd) sl_acct_Cd,netting_date,  t.doc_ref_num, TO_NUMBER(t.netting_flg) AS doc_tal_id, 
                              doc_date AS jur_date, t.xn_doc_num, 
                              t.tal_id, 
                             trim(t.gl_acct_Cd) gl_acct_Cd, 
                             DECODE(db_Cr_flg,'D',1,-1) * curr_val AS  ori_amt, 
                             record_source ,    due_date, t.cre_Dt, t.budget_cd , null
                        FROM T_ACCOUNT_LEDGER t, 
                             (  SELECT m.client_Cd 	,   v_bgn_date 		AS begin_date		
                              FROM MST_CLIENT m 	, T_BEGIN_ARAP_OUTSTAND b	
                             WHERE  v_before_bgn_date = 'N'
                             AND m.clienT_cd = b.client_cd(+)
                             AND b.client_cd IS NULL
                             AND m.client_type_1 IN ('I','C') 
                             AND trim(m.client_Cd ) BETWEEN   v_bgn_client AND  v_end_client
                             UNION ALL
                             SELECT client_cd, begin_date
                             FROM T_BEGIN_ARAP_OUTSTAND
                             WHERE  v_before_bgn_date = 'Y'
                             AND  client_Cd   BETWEEN   v_bgn_client AND  v_end_client
                             ) m
                        WHERE t.sl_Acct_Cd = m.client_Cd 
                          AND doc_Date BETWEEN m.begin_date AND v_end_date 
                          AND netting_Date >= v_bgn_date 
                          AND record_source IN ( 'CDUE','MDUE') 
                          AND SUBSTR(t.ledger_nar,1,3) <> 'REV' 
                          AND reversal_jur = 'N' 
                          AND doc_ref_num IS NOT NULL 
                          AND t.approved_sts = 'A';
                          
  BEGIN
    INSERT
    INTO R_RECON_OUTSTANDING_ARAP
      (
        P_DOC_DATE ,
        CLIENT_CD ,
        CLIENT_NAME ,
        BRANCH_CODE ,
        OLD_IC_NUM ,
        GL_ACCT_CD ,
        OUTS_AMT ,
        TB_AMT ,
        SELISIH ,
        USER_ID ,
        RAND_VALUE ,
        GENERATE_DATE
      )
    SELECT v_end_date, 
    client_cd,
      client_name,
      branch_code,
      old_ic_num,
      gl_acct_cd,
      outs_amt,
      tb_amt,
      selisih ,
      P_USER_ID,
      V_RANDOM_VALUE,
      P_GENERATE_DATE
    FROM
      (

      SELECT sl_acct_Cd, gl_acct_cd , SUM(outs_amt) outs_amt,  SUM(tb_amt) tb_amt, SUM(outs_amt) - SUM(tb_amt) selisih       
      FROM(       
         SELECT trim(sl_acct_Cd) sl_acct_cd, trim(gl_acct_cd) gl_acct_cd,   outs_amt , 0 tb_amt 
         FROM(  
            SELECT sl_acct_Cd, doc_date,doc_ref_num, doc_tal_id, ori_amt, sett_amt,   
                  payrec_amt, payrec_date, gl_ref_num, payrec_num, gl_acct_cd ,ori_amt +sett_amt AS outs_amt  
            FROM(   
                SELECT t.sl_acct_Cd, t.doc_date, t.doc_ref_num, t.doc_tal_id, NVL(p.payrec_date,  t.jur_date) payrec_date, p.cre_dt, 
                    TO_CHAR(NVL(p.payrec_date,  t.jur_date),'yyyymmdd' )||TO_CHAR(NVL(p.cre_dt,t.cre_dt),'yyyymmdd hh24:mi:ss') pdate, 
                    t.ori_amt, 
                    DECODE(trim(t.budget_cd),'REKLAS',- t.ori_amt ,p.payrec_amt) payrec_amt, 
                    p.gl_ref_num, p.payrec_num, trim(NVL(p.gl_acct_cd, t.gl_acct_cd)) gl_acct_cd , 
                    SUM( NVL(payrec_amt,0)+ DECODE(trim(t.budget_cd),'REKLAS',- t.ori_amt ,0)) over (PARTITION BY t.sl_acct_cd, t.doc_date, t.doc_ref_num, t.doc_tal_id) AS sett_amt, 
                    MAX( TO_CHAR(NVL(p.payrec_date,  t.jur_date),'yyyymmdd' )||TO_CHAR(NVL(p.cre_dt,t.cre_dt),'yyyymmdd hh24:mi:ss')) over (PARTITION BY t.sl_acct_cd, t.doc_date, t.doc_ref_num, t.doc_tal_id) AS max_pdate 
                FROM( select * from TEMP_OUTS_TAL_SETTLE
                       UNION ALL   
                           select * from TEMP_OUTS_TAL_SETTLE2
              --ORDER BY 1,2, 3,4   
                  ) T,  
                  (   
                    SELECT d.sl_acct_Cd, d.doc_ref_num, 
                          NVL(doc_tal_id, D.tal_id) doc_tal_id, 
                          NVL(gl_ref_num, d.doc_ref_num) gl_ref_num, DECODE(d.db_Cr_flg,'D',1,-1) * payrec_amt payrec_amt,  payrec_date, 
                          payrec_num , d.tal_id, T_ACCOUNT_LEDGER.gl_acct_Cd, d.cre_dt 
                    FROM T_PAYRECD d,
                        ( SELECT m.client_Cd 	,   v_bgn_date 		AS begin_date		
                           FROM MST_CLIENT m 	, T_BEGIN_ARAP_OUTSTAND b	
                           WHERE  v_before_bgn_date = 'N'
                           AND m.clienT_cd = b.client_cd(+)
                           AND b.client_cd IS NULL
                           AND m.client_type_1 IN ('I','C') 
                           AND trim(m.client_Cd ) BETWEEN    v_bgn_client AND  v_end_client
                           UNION ALL
                           SELECT client_cd, begin_date
                           FROM T_BEGIN_ARAP_OUTSTAND
                           WHERE  v_before_bgn_date = 'Y'
                           AND  client_Cd   BETWEEN    v_bgn_client AND  v_end_client) m,
                        T_ACCOUNT_LEDGER 					
                    WHERE payrec_date BETWEEN m.begin_date		 AND  v_end_date 
                    AND  D.sl_Acct_Cd = m.client_Cd				
                    AND payrec_type IN ('RV','PV')  
                    AND d.record_source <> 'VCH' 
                    AND d.record_source <> 'ARAP' 
                    AND  D.approved_sts = 'A' 
                    AND gl_ref_num = xn_doc_num 
                    AND D.tal_id = T_ACCOUNT_LEDGER.tal_id 
                  ) p   
              WHERE t.sl_acct_Cd = p.sl_acct_Cd (+)   
              AND t.doc_ref_num = p.doc_ref_num (+)   
              AND t.doc_tal_id = p.doc_tal_id(+)  
              AND t.xn_doc_num = p.gl_ref_num(+)  
              AND t.tal_id = p.tal_id(+)  
              --ORDER BY 1,2,3,4, 5,6   
              )   
            WHERE ( sett_Amt = 0   OR payrec_date IS NOT NULL)  
            AND ( pdate = max_pdate OR payrec_date IS NULL)   
              --ORDER BY 1,2,3,4  
            )  
        --ORDER BY 1  
      UNION ALL       
        SELECT trim(sl_acct_Cd) sl_acct_cd, trim(gl_acct_cd) gl_acct_cd,   0 outs_amt, deb_obal - cre_obal AS tb_amt  
        FROM t_day_trs,   
            ( SELECT m.client_Cd 	,   v_bgn_date 		AS begin_date		
						         FROM MST_CLIENT m 	, T_BEGIN_ARAP_OUTSTAND b	
								 WHERE  v_before_bgn_date = 'N'
								 AND m.clienT_cd = b.client_cd(+)
								 AND b.client_cd IS NULL
								 AND m.client_type_1 IN ('I','C') 
								 AND trim(m.client_Cd ) BETWEEN    v_bgn_client AND  v_end_client
								 UNION ALL
								 SELECT client_cd, begin_date
								 FROM T_BEGIN_ARAP_OUTSTAND
								 WHERE  v_before_bgn_date = 'Y'
								 AND  client_Cd   BETWEEN    v_bgn_client AND  v_end_client) m 
        WHERE trs_dt = V_BAL_DT  
        AND sl_acct_cd = client_cd  
        AND sl_acct_cd BETWEEN  v_bgn_client AND v_end_client 
        UNION ALL 
        SELECT  trim(sl_acct_Cd) sl_acct_cd, trim(gl_acct_cd) gl_acct_cd,   0 outs_amt, DECODE(db_cr_flg,'D',1,-1) * curr_val 
        FROM t_account_ledger,  
            ( SELECT m.client_Cd 	,   v_bgn_date 		AS begin_date		
						         FROM MST_CLIENT m 	, T_BEGIN_ARAP_OUTSTAND b	
								 WHERE  v_before_bgn_date = 'N'
								 AND m.clienT_cd = b.client_cd(+)
								 AND b.client_cd IS NULL
								 AND m.client_type_1 IN ('I','C') 
								 AND trim(m.client_Cd ) BETWEEN    v_bgn_client AND  v_end_client
								 UNION ALL
								 SELECT client_cd, begin_date
								 FROM T_BEGIN_ARAP_OUTSTAND
								 WHERE  v_before_bgn_date = 'Y'
								 AND  client_Cd   BETWEEN    v_bgn_client AND  v_end_client) m 
        WHERE doc_date BETWEEN v_BAL_DT AND v_END_DATE  
        AND sl_acct_cd = client_cd  
        AND sl_acct_cd  BETWEEN  v_bgn_client AND v_end_client
        AND approved_sts = 'A'  
        --ORDER BY 1,2  
     )        
     GROUP BY sl_acct_cd, gl_acct_cd        
     HAVING ( SUM(outs_amt) <> 0 OR SUM(tb_amt)  <> 0)        
  -- AND SUM(outs_amt) <>   SUM(tb_amt)       --19APR2016
  --ORDER BY 1,2        
    ),
     ( SELECT client_Cd, client_name, branch_code, old_ic_num FROM MST_CLIENT
      )
    WHERE sl_acct_cd = client_cd
    AND (( outs_amt <> tb_amt AND v_OPTION    <> 'ALL')
          OR v_OPTION      = 'ALL' )
    ORDER BY client_cd,
      gl_acct_cd ;      

  EXCEPTION
  WHEN OTHERS THEN
    V_ERROR_CD  := -30;
    V_ERROR_MSG := SUBSTR('INSERT R_RECON_OUTSTANDING_ARAP '||V_ERROR_MSG||SQLERRM(SQLCODE),1,200);
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
END SPR_RECON_OUTST_ARAP;