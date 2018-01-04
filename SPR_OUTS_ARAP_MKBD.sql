create or replace PROCEDURE SPR_OUTS_ARAP_MKBD(
    --P_FROM_DATE DATE,
    P_TO_DATE   DATE,
    P_BGN_CLIENT mst_client.CLIENT_CD%TYPE, --diisi %
    P_END_CLIENT mst_client.CLIENT_CD%TYPE, -- diisi _
    P_USER_ID       VARCHAR2,
    P_RANDOM_VALUE  NUMBER,
    P_ERROR_CD OUT NUMBER,
    P_ERROR_MSG OUT VARCHAR2 )
IS
/*
 oct 2017 utk aging mkbd 51 - 103 piutang nsb
    terdiri dari 2 flow 
        1. utk mayoritas data, From date ditentukan dr MST SYS PARAM
        2. utk client yg Outstandingnya seblm From date, diproses by client,
           dg from date dari T_BEGIN_ARAP_OUTSTAND
*/

  V_Flow number; 
  A_FLOW number;
   VP_FROM_DATE DATE;
   
Cursor csr_client is
select client_cd, begin_Date 
from T_BEGIN_ARAP_OUTSTAND
where status = 'A'
and begin_date < VP_FROM_DATE
and (a_flow = 2 or (a_flow = 1 and rownum = 1)) ;

  
    VP_TO_DATE   DATE;
    VP_BGN_CLIENT mst_client.CLIENT_CD%TYPE;
    VP_END_CLIENT mst_client.CLIENT_CD%TYPE;
    VP_GENERATE_DATE DATE;
    

  --v_flow = 1 utk mayoritas , yg from date dari  MST Sys param
 --               proses semua client
 -- v_ flow = 2 utk yg outstandingnya tertera di T_BEGIN_ARAP_OUTSTAND, proses by client
 
  V_ERROR_MSG    VARCHAR2(200);
  V_ERROR_CD     NUMBER(10);
  V_RANDOM_VALUE NUMBER(10);
  V_ERR          EXCEPTION;
BEGIN


  v_random_value := P_RANDOM_VALUE;

    begin
    select ddate1 into vp_from_date
    from mst_sys_param
    where param_id = 'AGING_MKBD51_103'
    and param_cd1 = 'FROMDATE';
    EXCEPTION
    WHEN NO_DATA_FOUND THEN 
            V_ERROR_CD  := -11;
            V_ERROR_MSG := SUBSTR('FROMDATE not found in mst_sys_param  '||SQLERRM(SQLCODE),1,200);
            RAISE V_err;
      WHEN OTHERS THEN
            V_ERROR_CD  := -12;
            V_ERROR_MSG := SUBSTR('Get FROMDATE fom mst_sys_param  '||SQLERRM(SQLCODE),1,200);
            RAISE V_err;
       END;  

--  VP_FROM_DATE := P_FROM_DATE;
  VP_TO_DATE   := P_TO_DATE;
   VP_GENERATE_DATE := sysdate;
   

  
   FOR v_flow in 1..2      loop

        a_flow := v_flow;
        
       FOR rec in csr_client loop
                    IF v_flow = 1 then 
                         
                          VP_BGN_CLIENT := '%';
                          VP_END_CLIENT := '_';
        
--                            select last_day(max(begin_date)) + 1 into  VP_FROM_DATE
--                            from T_BEGIN_ARAP_OUTSTAND;
                            
                    ELSE
                          VP_BGN_CLIENT := rec.client_cd;
                          VP_END_CLIENT :=  rec.client_cd;
                        
                          VP_FROM_DATE := rec.begin_date;
                    END IF;


                      ---TAL BAGIAN 1
                      BEGIN
                      INSERT INTO TMP_OUTS_TAL
                      SELECT trim(t.sl_acct_Cd) sl_acct_Cd,
                              doc_date,
                              DECODE(SUBSTR(t.xn_doc_num,6,1),'I', t.doc_ref_num,t.xn_doc_num) doc_ref_num,
                              t.tal_id AS doc_tal_id,
                              doc_date AS jur_date,
                              t.xn_doc_num,
                              t.tal_id,
                              trim(t.gl_acct_Cd) gl_acct_Cd,
                              DECODE(db_Cr_flg,'D',1,-1) * curr_val AS ori_amt,
                              record_source ,
                              due_date,
                              t.cre_DT,
                              t.budget_cd,
                              t.ledger_nar,
                              t.folder_cd,
                              null, --M.OLD_IC_NUM,
                              null, --M.CLIENT_NAME,
                              null, --m.branch_code,
                              V_RANDOM_VALUE,
                              P_USER_ID
                            FROM T_ACCOUNT_LEDGER t,
                              ( select sl_acct as client_Cd 
                                  from TMP_CLIENT_MKBD51_103
                                where sl_acct BETWEEN VP_BGN_CLIENT AND VP_END_CLIENT 
                                AND RAND_VALUE=P_RANDOM_VALUE AND USER_ID=P_USER_ID
                                ) m
                            WHERE t.sl_Acct_Cd   = m.client_Cd
                            AND doc_Date BETWEEN VP_FROM_DATE AND VP_TO_DATE
                            AND record_source IN ( 'CG','PD','RD','RVO','PVO','DNCN','GL','INT')
                          --  and gl_Acct_cd = '1424'
                            AND reversal_jur   = 'N'
                            AND t.approved_sts = 'A';
                      EXCEPTION
                      WHEN OTHERS THEN
                            V_ERROR_CD  := -20;
                            V_ERROR_MSG := SUBSTR('INSERT INTO TMP_OUTS_TAL  '||SQLERRM(SQLCODE),1,200);
                            RAISE V_err;
                       END;     
                            
                          
                     ---TAL BAGIAN 2
                     BEGIN  
                     INSERT  INTO TMP_OUTS_TAL2
                       SELECT trim(t.sl_acct_Cd) sl_acct_Cd,
                              netting_date,
                              t.doc_ref_num,
                              TO_NUMBER(t.netting_flg) AS doc_tal_id,
                              doc_date                 AS jur_date,
                              t.xn_doc_num,
                              t.tal_id,
                              trim(t.gl_acct_Cd) gl_acct_Cd,
                              DECODE(db_Cr_flg,'D',1,-1) * curr_val AS ori_amt,
                              record_source ,
                              due_date,
                              t.cre_Dt,
                              t.budget_cd,
                              t.ledger_nar ,
                              folder_cd,
                              null, --M.OLD_IC_NUM,
                              null, --M.CLIENT_NAME,
                              null, --m.branch_code,
                              V_RANDOM_VALUE,
                              P_USER_ID
                            FROM T_ACCOUNT_LEDGER t,
                             ( select  sl_acct as client_Cd 
                                  from TMP_CLIENT_MKBD51_103
                                where sl_acct BETWEEN VP_BGN_CLIENT AND VP_END_CLIENT 
                                AND RAND_VALUE=P_RANDOM_VALUE AND USER_ID=P_USER_ID
                                ) m
                            WHERE t.sl_Acct_Cd   = m.client_Cd
                            AND doc_Date BETWEEN VP_FROM_DATE AND VP_TO_DATE
                            AND netting_Date           >= VP_FROM_DATE
                            AND record_source          IN ( 'CDUE','MDUE')
                            AND doc_ref_num            IS NOT NULL
                           --  AND SUBSTR(ledger_nar,1,3) <> 'REV'
                            AND reversal_jur            = 'N'
                            AND t.approved_sts          = 'A';
                      EXCEPTION
                      WHEN OTHERS THEN
                            V_ERROR_CD  := -30;
                            V_ERROR_MSG := SUBSTR('INSERT INTO TMP_OUTS_TAL2  '||SQLERRM(SQLCODE),1,200);
                            RAISE V_err;
                       END; 
                       
                      -- BAGIAN PAYRECH
                      BEGIN
                      INSERT INTO TMP_OUTS_PAYREC
                      SELECT d.sl_acct_Cd,
                              d.doc_ref_num,
                              NVL(doc_tal_id, D.tal_id) doc_tal_id,
                              NVL(gl_ref_num, d.doc_ref_num) gl_ref_num,
                              DECODE(d.db_Cr_flg,'D',1,-1) * payrec_amt payrec_amt,
                              d.payrec_date,
                              d.payrec_num ,
                              d.tal_id,
                              T_ACCOUNT_LEDGER.gl_acct_Cd,
                              d.cre_dt,
                              V_RANDOM_VALUE,
                              P_USER_ID
                            FROM T_PAYRECD d,
                             -- T_PAYRECH h,
                              T_ACCOUNT_LEDGER
                            WHERE d.payrec_date BETWEEN VP_FROM_DATE AND VP_TO_DATE
                            AND d.payrec_type IN ('RV','PV')
                           -- AND d.payrec_num   = h.payrec_num
                            AND D.sl_Acct_Cd BETWEEN VP_BGN_CLIENT AND VP_END_CLIENT
                            AND d.record_source <> 'VCH'
                            AND d.record_source <> 'ARAP'
                            AND D.approved_sts = 'A'
                            AND gl_ref_num     = xn_doc_num
                            AND D.tal_id       = T_ACCOUNT_LEDGER.tal_id;
                      EXCEPTION
                      WHEN OTHERS THEN
                            V_ERROR_CD  := -40;
                            V_ERROR_MSG := SUBSTR('INSERT INTO TMP_OUTS_PAYREC  '||SQLERRM(SQLCODE),1,200);
                            RAISE V_err;
                       END; 
                      
                      BEGIN
                        INSERT
                        INTO R_OUTS_ARAP_CLIENT
                          (
                            CLIENT_CD ,
                            DOC_DATE ,
                            LEDGER_NAR ,
                            FOLDER_CD ,
                            DUE_DATE ,
                            ORI_AMT ,
                            OUTS_AMT ,
                            GL_ACCT_CD ,
                            DOC_REF_NUM ,
                            CLIENT_NAME,
                            old_ic_num,
                            BRANCH_CD ,
                            FROM_DATE ,
                            TO_DATE ,
                            USER_ID ,
                            RAND_VALUE ,
                            GENERATE_DATE ,
                             SORT_BY
                          )
                        SELECT sl_acct_Cd,
                          doc_date,
                          ledger_nar,
                          folder_cd,
                          due_date,
                          ori_amt,
                          DECODE(ori_amt +sett_amt , ori_amt +cum_pay , ori_amt +cum_pay , 0) AS outs_amt ,
                          gl_acct_cd ,
                          doc_ref_num,
                          CLIENT_NAME,
                          OLD_IC_NUM,
                          branch_code,
                          VP_FROM_DATE,
                          VP_TO_DATE,
                          P_USER_ID,
                          V_RANDOM_VALUE,
                          VP_GENERATE_DATE,
                          null -- P_SORT_BY  
                        FROM
                          (SELECT t.sl_acct_Cd,
                            t.doc_date,
                            t.doc_ref_num,
                            t.doc_tal_id,
                            NVL(p.payrec_date, t.jur_date) payrec_date,
                            p.cre_dt,
                            TO_CHAR(NVL(p.payrec_date, t.jur_date),'yyyymmdd' )
                            ||TO_CHAR(NVL(p.cre_dt,t.cre_dt),'yyyymmdd hh24:mi:ss') pdate,
                            t.ori_amt,
                            DECODE(trim(t.budget_cd),'REKLAS',- t.ori_amt ,p.payrec_amt) payrec_amt,
                            p.gl_ref_num,
                            p.payrec_num,
                            trim(NVL(p.gl_acct_cd, t.gl_acct_cd)) gl_acct_cd ,
                            t.ledger_nar,
                            t.due_date,
                            t.folder_cd,
                            SUM( NVL(payrec_amt,0)+ DECODE(trim(t.budget_cd),'REKLAS',- t.ori_amt ,0)) over (PARTITION BY t.sl_acct_cd, t.doc_date, t.doc_ref_num, t.doc_tal_id)   AS sett_amt,
                            SUM( NVL(payrec_amt,0)+ DECODE(trim(t.budget_cd),'REKLAS',- t.ori_amt ,0)) over (PARTITION BY t.sl_acct_cd, t.doc_date, t.doc_ref_num, t.doc_tal_id 
                               ORDER BY t.sl_acct_cd, t.doc_date, t.doc_ref_num, t.doc_tal_id, payrec_date, p.cre_dt) AS cum_pay,
                            MAX( TO_CHAR(NVL(p.payrec_date, t.jur_date),'yyyymmdd' )
                            ||TO_CHAR(NVL(p.cre_dt,t.cre_dt),'yyyymmdd hh24:mi:ss')) over (PARTITION BY t.sl_acct_cd, t.doc_date, t.doc_ref_num, t.doc_tal_id) AS max_pdate ,
                            T.OLD_IC_NUM,
                            T.CLIENT_NAME,
                            t.branch_code
                          FROM
                            (SELECT * FROM TMP_OUTS_TAL WHERE RAND_VALUE=V_RANDOM_VALUE AND USER_ID=P_USER_ID
                            UNION ALL
                            SELECT * FROM TMP_OUTS_TAL2  WHERE RAND_VALUE=V_RANDOM_VALUE AND USER_ID=P_USER_ID
                            ) T,
                            (SELECT * FROM TMP_OUTS_PAYREC  WHERE RAND_VALUE=V_RANDOM_VALUE AND USER_ID=P_USER_ID
                            ) p
                          WHERE t.sl_acct_Cd = p.sl_acct_Cd (+)
                          AND t.doc_ref_num  = p.doc_ref_num (+)
                          AND t.doc_tal_id   = p.doc_tal_id(+)
                          AND t.xn_doc_num   = p.gl_ref_num(+)
                          AND t.tal_id       = p.tal_id(+)
                          )
                        WHERE ( sett_Amt          = 0    OR payrec_date           IS NOT NULL)
                        AND ( pdate               = max_pdate    OR payrec_date           IS NULL)
                        AND (ori_amt +sett_amt ) <> 0
                        ORDER BY sl_acct_Cd,
                          doc_date,
                          doc_ref_num;
                      EXCEPTION
                      WHEN OTHERS THEN
                        V_ERROR_CD  := -50;
                        V_ERROR_MSG := SUBSTR('INSERT R_OUTS_ARAP_CLIENT '||V_ERROR_MSG||SQLERRM(SQLCODE),1,200);
                        RAISE V_err;
                      END;
                      --DELETE TABEL TEMP
                      
                      BEGIN
                      DELETE FROM TMP_OUTS_PAYREC WHERE RAND_VALUE=V_RANDOM_VALUE AND USER_ID=P_USER_ID;
                      EXCEPTION
                      WHEN OTHERS THEN
                        V_ERROR_CD  := -60;
                        V_ERROR_MSG := SUBSTR('Delete TMP_OUTS_PAYREC '||V_ERROR_MSG||SQLERRM(SQLCODE),1,200);
                        RAISE V_err;
                      END;
                      
                      BEGIN
                      DELETE FROM TMP_OUTS_TAL2 WHERE RAND_VALUE=V_RANDOM_VALUE AND USER_ID=P_USER_ID;
                      EXCEPTION
                      WHEN OTHERS THEN
                        V_ERROR_CD  := -70;
                        V_ERROR_MSG := SUBSTR('Delete TMP_OUTS_TAL2 '||V_ERROR_MSG||SQLERRM(SQLCODE),1,200);
                        RAISE V_err;
                      END;
                      
                      BEGIN
                      DELETE FROM TMP_OUTS_TAL WHERE RAND_VALUE=V_RANDOM_VALUE AND USER_ID=P_USER_ID;
                       EXCEPTION
                      WHEN OTHERS THEN
                        V_ERROR_CD  := -80;
                        V_ERROR_MSG := SUBSTR('Delete TMP_OUTS_TAL '||V_ERROR_MSG||SQLERRM(SQLCODE),1,200);
                        RAISE V_err;
                      END; 

        END LOOP;   
END LOOP;

--timestamp selesai
begin
update  R_OUTS_ARAP_CLIENT
set generate_date = sysdate
where rand_value = V_RANDOM_VALUE
and rownum = 1;
 EXCEPTION
  WHEN OTHERS THEN
    V_ERROR_CD  := -90;
    V_ERROR_MSG := SUBSTR('update timestamp ke R_OUTS_ARAP_CLIENT'||V_ERROR_MSG||SQLERRM(SQLCODE),1,200);
    RAISE V_err;
  END; 

--commit;

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
END SPR_OUTS_ARAP_MKBD;