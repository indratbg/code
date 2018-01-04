create or replace 
PROCEDURE SPR_CLIENT_PORTOFOLIO(
    P_END_DATE      DATE,
    P_BGN_CLIENT    VARCHAR2,
    P_END_CLIENT    VARCHAR2,
    P_LIMIT_FLG VARCHAR2,
    P_BGN_BRANCH MST_BRANCH.BRCH_CD%TYPE,
    P_END_BRANCH MST_BRANCH.BRCH_CD%TYPE,
    P_BGN_REM MST_SALES.REM_CD%TYPE,
    P_END_REM MST_SALES.REM_CD%TYPE,
    P_BGN_STOCK MST_COUNTER.STK_CD%TYPE,
    P_END_STOCK MST_COUNTER.STK_CD%TYPE,
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
  V_BGN_DATE DATE;
  V_PRICE_DATE DATE;

BEGIN

  V_RANDOM_VALUE := ABS(DBMS_RANDOM.RANDOM);
 
    BEGIN
      SP_RPT_REMOVE_RAND('R_CLIENT_PORTOFOLIO',V_RANDOM_VALUE,V_ERROR_MSG,V_ERROR_CD);
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


    V_BGN_DATE := TO_DATE('01'||TO_CHAR(P_END_DATE,'MMYYYY'),'DDMMYYYY');

    BEGIN
      SELECT MAX(STK_DATE) INTO V_PRICE_DATE FROM t_close_price WHERE STK_DATE=GET_DOC_DATE(1,P_END_DATE);
     EXCEPTION
    WHEN OTHERS THEN
      V_ERROR_CD  := -30;
      V_ERROR_MSG := SUBSTR('SELECT MAX CLOSE PRICE DATE '||SQLERRM(SQLCODE),1,200);
      RAISE V_err;
    END;
    
    BEGIN
      INSERT
      INTO R_CLIENT_PORTOFOLIO
        (CLIENT_CD
,TYP
,OLD_CD
,CLIENT_NAME
,BRANCH_CODE
,REM_CD
,REM_NAME
,STK_CD
,STK_DESC
,END_THEO
,END_ONH
,AVG_PRICE
,CLOSE_PRICE
,BID_PRICE
,STK_VAL
,MARKET_VAL
,GAINLOSS
,GAINLOSS_PERC
,DISC_PERC
,PORTO_DISCT
,OUTSAR
,OUTSAP
,OUTSAMT
,SHORT_AMT
,PORTO_AMT
,CR_LIM
,AVAIL_LIM
,DOC_DATE
,USER_ID
,RAND_VALUE
,GENERATEDATE
        )
    SELECT  c.client_cd,                                      
                    1 AS typ,                                     
                    m.old_cd,                                     
                    m.client_name,                                      
                    m.branch_code,                                      
                    m.rem_cd,                                     
                    m.rem_name,                                       
                    c.stk_cd,                                       
                     e.stk_desc,                                      
                     c.end_theo,                                      
                     c.end_onh,                                     
                     NVL( d.avg_price,0) avg_price,                                       
                     NVL(e.close_price,0) close_price,                                      
           nvl(e.bid_price,0) bid_price,                            
                     c.end_theo * NVL( d.avg_price,0) AS stk_val,                                     
                     c.end_theo * NVL(e.close_price,0) AS market_val,                                     
                     c.end_theo * NVL(e.close_price,0) - c.end_theo * NVL( d.avg_price,0)  AS gainloss,                                     
                     DECODE( c.end_theo * NVL( d.avg_price,0), 0,0,                                       
                     ROUND(( c.end_theo * NVL(e.close_price,0) - c.end_theo * NVL( d.avg_price,0)) / (c.end_theo * NVL( d.avg_price,0)) * 100,2)) gainloss_perc,                                      
                     e.disc_perc,                                       
                     c.end_theo * NVL(e.bid_price,0) * e.disc_perc  AS porto_disct,                                     
                     0 outsAR,                                      
                     0 outsAP,                                      
                     0 outsamt,                                       
                     0 short_amt,                                       
                     0 porto_amt,                                       
                     0 cr_lim,                                      
                 0 avail_lim ,
                 P_END_DATE,
                 P_USER_ID,
                 V_RANDOM_VALUE,
                 P_GENERATE_DATE                                 
FROM(   SELECT client_cd, stk_cd,                                     
                        SUM(beg_bal_qty + theo_mvmt) end_theo,                                
                        SUM(beg_on_hand + onh_mvmt) end_onh                               
      FROM( select client_cd,   NVL(c.stk_cd_new,stk_cd) stk_cd,                                
              beg_bal_qty,                        
               beg_on_hand, theo_mvmt, onh_mvmt                         
          FROM( SELECT t.client_cd, t.stk_cd,                         
                          0 beg_bal_qty,              
                          0 beg_on_hand,              
                          DECODE(trim(t.gl_acct_cd),'33',0,'36',0,1) * DECODE(t.db_cr_flg,'D',1,-1) * (t.total_share_qty + t.withdrawn_share_qty) theo_mvmt,              
                          DECODE(trim(t.gl_acct_cd),'33',1,'36',1,0) * DECODE(t.db_cr_flg,'C',1,-1) * (t.total_share_qty + t.withdrawn_share_qty) onh_mvmt              
              FROM T_STK_MOVEMENT t                         
              WHERE t.doc_stat = '2'                        
                  AND t.gl_acct_cd IN ('14','51','12','13','10','33','36')                    
                  AND SUBSTR(t.doc_num,5,2) IN ('BR', 'JR', 'RS', 'WS','BI','JI')                     
                  AND t.doc_dt BETWEEN V_BGN_DATE AND P_END_DATE                    
                  AND t.client_cd BETWEEN P_BGN_CLIENT AND P_END_CLIENT                     
                  AND t.stk_cd BETWEEN P_BGN_STOCK AND P_END_STOCK                    
              UNION ALL                       
              SELECT t.client_cd, t.stk_cd,                         
                      t.beg_bal_qty,                
                      t.beg_on_hand,                
                        0 theo_mvmt,              
                        0 onh_mvmt                
              FROM T_STKBAL t                         
              WHERE t.client_cd BETWEEN P_BGN_CLIENT AND P_END_CLIENT                         
              AND t.stk_cd BETWEEN P_BGN_STOCK AND P_END_STOCK                        
              AND t.bal_dt = V_BGN_DATE ) s,                        
            ( SELECT stk_cd_old, stk_cd_new                         
              FROM T_CHANGE_STK_CD                        
              WHERE   eff_dt <= P_END_DATE ) c                      
            WHERE s.stk_cd = c.stk_cd_old(+))                         
      GROUP BY client_cd, stk_cd                                
      HAVING SUM(beg_bal_qty + theo_mvmt) <> 0) C,                                
    (      SELECT p.client_cd, p.stk_cd,  p.avg_buy_price AS avg_price                                  
        FROM T_AVG_PRICE P,                               
              (  SELECT client_cd, stk_cd, MAX(avg_dt) maxdt                        
                FROM T_AVG_PRICE                      
                WHERE  avg_dt <= P_END_DATE                       
              GROUP BY client_cd, stk_cd ) P1                         
        WHERE p.avg_dt = p1.maxdt                               
        AND p.client_cd = p1.client_cd                              
        AND p.stk_cd = p1.stk_cd                              
        AND p.client_cd BETWEEN P_BGN_CLIENT AND P_END_CLIENT                               
        AND p.stk_cd BETWEEN P_BGN_STOCK AND P_END_STOCK) D,                              
    (  SELECT MST_COUNTER.stk_cd,                                   
        INITCAP(NVL(t_close_price.stk_name,MST_COUNTER.stk_desc)) stk_desc,                               
        NVL(DECODE(t_close_price.stk_clos, 0, t_close_price.stk_prev, t_close_price.stk_clos), 0)  close_price,                             
        t_close_price.stk_bidp bid_price,                             
                NVL(stk_haircut.haircut,0) / 100 AS disc_perc                                       
              FROM( select b.stk_cd, 100 - b.haircut as haircut                                   
            from(  select stk_cd, max(status_dt) max_dt                         
                from t_stk_haircut                      
                where status_dt < V_PRICE_DATE                      
                group by stk_cd) a,                     
                t_stk_haircut b                     
                where b.stk_cd = a.stk_cd                     
                and b.status_dt = a.max_dt                      
              ) stk_haircut,                        
         t_close_price,  MST_COUNTER                              
            where t_close_price.stk_date = V_PRICE_DATE                                 
        and MST_COUNTER.stk_cd = t_close_price.stk_cd(+)                              
        and MST_COUNTER.stk_cd = stk_haircut.stk_cd(+)  )  E,                             
    (  SELECT client_cd, MST_CLIENT.old_ic_num AS old_cd, client_name, branch_code,                                   
                            MST_CLIENT.rem_cd, rem_name                                     
      FROM MST_CLIENT, MST_SALES                                
      WHERE MST_CLIENT.client_cd BETWEEN P_BGN_CLIENT AND P_END_CLIENT                                
      AND trim(MST_CLIENT.rem_cd) BETWEEN P_BGN_REM AND P_END_REM                                 
      AND trim(MST_CLIENT.branch_code)  BETWEEN P_BGN_BRANCH AND P_END_BRANCH                               
            AND trim(MST_CLIENT.rem_cd) = trim(MST_SALES.rem_cd)) M                                     
WHERE  c.client_cd  = d.client_cd (+)                                       
AND c.stk_cd  = d.stk_cd (+)                                      
AND c.stk_cd  = e.stk_cd (+)                                      
AND c.client_cd = m.client_cd                                     
UNION ALL                                     
SELECT client_cd,                                     
                    2 AS typ,                                     
                    old_cd,                                     
                    client_name,                                      
                    branch_code,                                      
                    rem_cd,                                     
                    rem_name,                                       
                    '-' stk_cd,                                       
                    NULL stk_desc,                                      
                    0 end_theo,                                     
                    0 end_onh,                                      
                    0 avg_price,                                      
                    0 close_price,                                      
          0 bid_price,                            
                    0 stk_val,                                      
                    0 market_val,                                     
                    0 gainloss,                                     
                    0 gainloss_perc,                                      
                    0 disc_perc,                                      
                     0 porto_disct,                                     
               outsAR,                              
                       outsAP,                                      
                       outsamt,                                       
                       short_amt,                                       
                       porto_amt,                                       
                       cr_lim,                                      
                  avail_lim  ,
                    P_END_DATE,
                 P_USER_ID,
                 V_RANDOM_VALUE,
                 P_GENERATE_DATE                                       
     FROM(  SELECT m.client_cd, INITCAP(m.client_name) client_name,                                     
             m.old_ic_num AS old_cd, m.branch_code,m.rem_cd, s.rem_name,                          
                    NVL(outs.outsAR,0) outsAr,                                      
              NVL(outs.outsAP,0) outsap,                        
              NVL(outs.outsamt,0) outsamt,                        
                        NVL(porto.short_amt,0) AS short_amt,                                      
                        NVL(porto.porto_amt,0) porto_amt, NVL(m.cr_lim, 0) cr_lim,                                      
                 (( NVL(porto.porto_amt,0) / 2) - NVL(outs.outsamt,0)    ) * 2 AS avail_lim                                 
             FROM( SELECT client_cd,                                      
                   SUM(NVL(outsAR,0)) AS outsAR,                        
                   SUM(NVL(outsAP,0)) AS outsAP,                        
                          SUM(NVL(outsamt,0)) AS outsamt                                      
              FROM(  SELECT client_cd,                              
                                 doc_date, due_date,                                      
                      DECODE(SIGN(due_date- P_END_DATE),-1,0,0,0,1) * DECODE(SIGN(os_amt), 1,os_amt, 0)  AS outsar,               
                      DECODE(SIGN(due_date- P_END_DATE),-1,0,0,0,1) * DECODE(SIGN(os_amt), -1,ABS(os_amt), 0)  AS outsap,               
                            os_amt AS outsamt                                                             
                         FROM(               SELECT x.client_Cd, x.doc_num, x.doc_folder, x.doc_date, x.due_date,                                     
                           x.orig_amt,                  
                         x.orig_amt - NVL(p.pay_amt,0) AS os_amt,               
                         x.gl_acct_cd,                
                         x.xn_doc_num,                
                         x.descrip                
                    FROM(  SELECT c.client_cd,                  
                                  c.contr_num AS doc_num,                   
                                 SUBSTR(c.contr_num,5,11) AS doc_folder,                  
                               c.contr_dt AS doc_date,              
                              c.due_dt_for_amt AS due_date,             
                               DECODE(t.db_cr_flg,'D',1,-1) * c.amt_for_curr AS orig_amt,               
                             DECODE(t.db_cr_flg,'D',1,-1) * (c.amt_for_curr - NVL(c.sett_val,0) - NVL(c.sett_for_curr,0)) AS os_amt,            
                             t.gl_acct_cd,            
                                t.xn_doc_num, 1 tal_id,                 
                             t.ledger_nar AS descrip            
                        FROM T_CONTRACTS c, T_ACCOUNT_LEDGER t              
                        WHERE contr_dt > '31jan2010'              
                                                AND P_LIMIT_FLG = 'Y'                                       
                          AND c.contr_stat <> 'C'                 
                        AND c.client_cd BETWEEN P_BGN_CLIENT AND P_END_CLIENT               
                        AND c.contr_dt <= P_END_DATE              
                        AND t.sl_acct_cd = c.client_cd              
                        AND c.contr_num = t.doc_ref_num               
                        AND (t.rvpv_number IS NULL OR t.rvpv_number LIKE '%V%')             
                        UNION                 
                        SELECT p.sl_acct_cd,                
                               p.payrec_num,                  
                            p.ref_folder_cd,          
                               p.payrec_date, p.due_date,               
                            DECODE(p.db_cr_flg,'D',1,-1) * p.payrec_amt AS orig_amt,          
                            DECODE(p.db_cr_flg,'D',1,-1) * (p.payrec_amt - NVL(p.sett_val,0) - NVL(p.sett_for_curr,0)) AS pay_amt,          
                            t.gl_acct_cd,         
                                t.xn_doc_num,                 
                                DECODE(t.record_source,'CDUE',t.netting_flg,'MDUE',t.netting_flg,t.tal_id) AS tal_id,               
                            t.ledger_nar          
                        FROM T_PAYRECD p, T_ACCOUNT_LEDGER t              
                        WHERE p.record_source = 'ARAP'              
                                                AND P_LIMIT_FLG = 'Y'                                       
                        AND p.approved_sts <> 'C'               
                        AND p.approved_sts <> 'E'               
                        AND p.payrec_date <= P_END_DATE               
                        AND p.sl_acct_cd BETWEEN P_BGN_CLIENT AND P_END_CLIENT              
                        AND p.payrec_num = t.doc_ref_num              
                        AND p.sl_acct_cd = t.sl_acct_cd             
                          AND p.tal_id = t.netting_flg                  
                        AND (t.rvpv_number IS NULL OR t.rvpv_number LIKE '%V%' OR t.rvpv_number LIKE '%DE%')      ) X,          
                    (   SELECT tal_id, doc_ref_num, sl_acct_cd,                   
                               SUM(pay_amt) pay_amt                 
                      FROM(                 
                           SELECT d.tal_id, d.doc_ref_num, d.sl_acct_cd,              
                                  d.payrec_num,   DECODE(d.db_Cr_flg,'D',-1,1) * d.payrec_amt AS pay_amt              
                           FROM T_PAYRECD d, T_PAYRECH h            
                           WHERE d.payrec_num = h.payrec_num            
                                                    AND P_LIMIT_FLG = 'Y'                                       
                           AND d.approved_sts <> 'C'            
                           AND d.approved_sts <> 'E'            
                           AND d.payrec_date <= P_END_DATE            
                           AND d.sl_Acct_cd BETWEEN P_BGN_CLIENT AND P_END_CLIENT           
                           AND d.record_source <> 'ARAP')           
                       GROUP BY tal_id, doc_ref_num, sl_acct_cd   ) p             
                    WHERE x.doc_num = p.doc_ref_num (+)                 
                    AND x.client_cd = p.sl_acct_cd (+)                  
                    AND x.tal_id = p.tal_id (+)                 
                    AND x.orig_amt - NVL(p.pay_amt,0) <> 0))                  
                GROUP BY client_cd   ) outs,                              
        ( SELECT  b.client_cd,   SUM(bal_qty *  NVL(p.bid_price,0) * p.disc_perc) porto_amt,                              
                                            SUM(short * bal_qty *  NVL(p.bid_price,0)) AS short_amt                                     
                         FROM(SELECT client_cd, stk_cd,                         
                                              SUM(beg_bal_qty + theo_mvmt) bal_qty,                                     
                                              DECODE(SIGN(SUM(beg_bal_qty + theo_mvmt)),-1,1,0) short                                       
                          FROM( SELECT client_cd, NVL(c.stk_cd_new,stk_cd) stk_cd,   beg_bal_qty,    theo_mvmt            
                                FROM( SELECT client_cd, stk_cd, 0 beg_bal_qty,          
                                    (NVL(DECODE(SUBSTR(doc_num,5,2),'BR',1,'JR',1,'BI',1,'JI',1,'RS',1,'WS',1,0) *    
                                    DECODE(db_cr_flg,'D',1,-1) *  (total_share_qty + withdrawn_share_qty),0)) theo_mvmt   
                                    FROM T_STK_MOVEMENT     
                                  WHERE doc_dt BETWEEN V_BGN_DATE AND P_END_DATE    
                                   AND client_cd BETWEEN P_BGN_CLIENT AND P_END_CLIENT    
                                   AND gl_acct_cd IN ('10','12','13','14','51')     
                                   AND doc_stat    = '2'    
                                   AND s_d_type <> 'V'    
                                   AND P_LIMIT_FLG = 'Y'    
                                  UNION ALL     
                                   SELECT client_cd, stk_cd, beg_bal_qty, 0 theo_mvmt     
                                    FROM T_STKBAL   
                                   WHERE bal_dt = V_BGN_DATE    
                                    AND P_LIMIT_FLG = 'Y'     
                                    AND client_cd BETWEEN P_BGN_CLIENT AND P_END_CLIENT  ) s,   
                                ( SELECT stk_cd_old, stk_cd_new     
                                      FROM T_CHANGE_STK_CD  
                                    WHERE   eff_dt <= P_END_DATE ) c
                              WHERE s.stk_cd = c.stk_cd_old(+))         
                          GROUP BY client_cd, stk_cd              
                          HAVING SUM(beg_bal_qty + theo_mvmt) <> 0) b,            
                        (  SELECT MST_COUNTER.stk_cd,               
                            INITCAP(NVL(t_close_price.stk_name,MST_COUNTER.stk_desc)) stk_desc,           
                            NVL(DECODE(t_close_price.stk_clos, 0, t_close_price.stk_prev, t_close_price.stk_clos), 0)  close_price,         
                            t_close_price.stk_bidp bid_price,         
                                          NVL(stk_haircut.haircut,0) / 100 AS disc_perc                         
                                FROM( select b.stk_cd, 100 - b.haircut as haircut                 
                              from(  select stk_cd, max(status_dt) max_dt       
                                  from t_stk_haircut    
                                  where status_dt < V_PRICE_DATE    
                                  group by stk_cd) a,   
                                  t_stk_haircut b   
                                  where b.stk_cd = a.stk_cd   
                                  and b.status_dt = a.max_dt    
                                ) stk_haircut,      
                           t_close_price,  MST_COUNTER            
                              where t_close_price.stk_date = V_PRICE_DATE               
                          and MST_COUNTER.stk_cd = t_close_price.stk_cd(+)            
                          and MST_COUNTER.stk_cd = stk_haircut.stk_cd(+)  ) p           
                                  WHERE  b.stk_cd = p.stk_cd (+)                                  
                                      GROUP BY b.client_cd       ) porto,                                     
        MST_CLIENT m, MST_SALES s                             
        WHERE m.client_cd = porto.client_cd (+)                             
        AND m.client_cd = outs.client_cd (+)                              
        AND trim(m.rem_cd) = trim(s.rem_cd(+))                              
               AND trim(M.rem_cd) BETWEEN P_BGN_REM AND P_END_REM                                       
         AND trim(M.branch_code)  BETWEEN P_BGN_BRANCH AND P_END_BRANCH                               
            AND P_LIMIT_FLG = 'Y'                                     
        AND m.susp_stat <> 'C'                              
            AND m.client_type_1 <> 'H')                                       
       WHERE (outsAmt <> 0 OR porto_amt <> 0) ;
    EXCEPTION
    WHEN OTHERS THEN
      V_ERROR_CD  := -60;
      V_ERROR_MSG := SUBSTR('INSERT R_CLIENT_PORTOFOLIO'||V_ERROR_MSG||SQLERRM(SQLCODE),1,200);
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
END SPR_CLIENT_PORTOFOLIO;