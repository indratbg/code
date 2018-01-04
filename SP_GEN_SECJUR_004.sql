create or replace 
PROCEDURE Sp_Gen_Secjur_004(
    p_curr_date DATE,
    p_user_id T_STK_MOVEMENT.user_id%TYPE,
    P_ERROR_CD OUT NUMBER,
    P_ERROR_MSG OUT VARCHAR2)

--May 2016 change ticker
IS
  tmpVar      NUMBER;
  V_ERROR_CD  NUMBER;
  V_ERROR_MSG VARCHAR2(200);
  V_ERR       EXCEPTION;

  CURSOR csr_004( a_trx_dt DATE, a_due_dt DATE, a_bgn_dt DATE, a_dt_min1 DATE, a_dt_t1 DATE, a_dt_t2 DATE )
  IS
    SELECT s3.client_cd,
      s3.stk_cd,
      onh_amt,
      t3_trf004,
      sisa_3,
      NVL(t2_sell,0) t2_sell,
      NVL(t1_sell,0) t1_sell,
      DECODE( SIGN( NVL(sisa_3,0) - NVL(t2_sell,0)), -1, NVL(sisa_3,0),NVL(t2_sell,0)) t2_trf004,
      NVL(sisa_3,0)               - DECODE( SIGN( NVL(sisa_3,0) - NVL(t2_sell,0)), -1, NVL(sisa_3,0),NVL(t2_sell,0)) AS sisa_2
    FROM
      (SELECT NVL(onh.client_cd, t3.client_cd) client_cd,
        NVL(onh.stk_cd, t3.stk_cd) stk_cd,
        NVL(onh_amt,0) onh_amt,
        NVL(t3_net,0) t3_trf004,
        NVL(onh_amt,0) - NVL(t3_net,0) AS sisa_3
      FROM
          (SELECT client_cd,
            stk_cd,
            SUM(onh) onh_amt
          FROM
              (
              select client_cd, nvl(c.stk_cd_new,stk_cd) stk_cd, onh from --07sep2016
              (
              SELECT client_cd,
                stk_cd,
                (NVL(DECODE(SUBSTR(doc_num,5,2),'JV',1,'RS',1,'WS',1,'CS',1,0) * DECODE(trim(NVL(gl_acct_cd,'36')),'36',1, 0) * DECODE(db_cr_flg,'D',-1,1) * (total_share_qty + withdrawn_share_qty),0)) onh
              FROM T_STK_MOVEMENT
              WHERE doc_dt BETWEEN a_bgn_dt AND a_dt_min1
              AND gl_acct_cd IN ('36')
              AND gl_acct_cd IS NOT NULL
              AND doc_stat    = '2'
              --AND client_Cd = 'WIMP001R'
              UNION ALL
--              SELECT client_cd, stk_cd,
--                    (NVL(DECODE(SUBSTR(doc_num,5,2),'RS',1,'WS',1,0) *
--                      DECODE(trim(NVL(gl_acct_cd,'36')),'36',1, 0) * DECODE(db_cr_flg,'D',-1,1) *
--                      (total_share_qty + withdrawn_share_qty),0)) onh
--                FROM T_STK_MOVEMENT
--              WHERE doc_dt  = a_due_dt
--               AND gl_acct_cd IN ('36')
--               AND gl_acct_cd IS NOT NULL
--               AND doc_stat    = '2'
--               AND Jur_type IN ('RECVT','WHDRT')
               --AND client_Cd = 'WIMP001R'
--              UNION ALL
              SELECT client_Cd,
                stk_Cd,
                qty onh
              FROM T_SECU_BAL
              WHERE bal_dt    = a_bgn_dt
              AND gl_acct_cd IN ('36')
              --AND client_Cd = 'WIMP001R'
              UNION ALL
              SELECT client_cd,
                stk_cd,
                0
              FROM T_STKHAND
              WHERE (bal_qty <> 0
              OR on_hand     <> 0
              OR os_buy      <> 0
              OR os_sell     <> 0 )
              --AND client_Cd = 'WIMP001R'
              UNION ALL
              SELECT client_cd, stk_cd, -1 * qty
              FROM v_porto_jaminan
              --WHERE client_Cd = 'WIMP001R'
              )s,
              (SELECT stk_cd_old, stk_cd_new FROM T_CHANGE_STK_CD WHERE eff_Dt <= a_due_dt)c--07sep2016
                where s.stk_cd=c.stk_cd_old(+) 
           )
          GROUP BY client_Cd, stk_Cd)    onh,
          ( SELECT client_cd, NVL(stk_cd_new,stk_cd) stk_cd,
              SUM( DECODE(SUBSTR(contr_num,5,1),'B',-1,1) * qty) t3_net
            FROM T_CONTRACTS,
                  ( SELECT stk_cd_old, stk_cd_new
                          FROM T_CHANGE_STK_CD
                      WHERE eff_Dt <= a_due_dt)
            WHERE contr_dt  = a_trx_dt
            AND kpei_due_dt = a_due_dt
            AND contr_stat <> 'C'
            AND mrkt_type  <> 'NG'
            AND mrkt_type  <> 'TS'
            --AND client_Cd = 'WIMP001R'
            AND stk_cd = stk_cd_old(+)
            GROUP BY client_cd, stk_cd, stk_cd_new   ) t3
       WHERE onh.client_cd = t3.client_cd (+)
       AND onh.stk_cd      = t3.stk_cd(+) ) s3,
      ( SELECT client_cd, stk_cd,
          DECODE(SIGN(t2_sell),-1, ABS(t2_sell), 0) AS t2_sell,
          DECODE(SIGN(t1_sell),-1, ABS(t1_sell), 0) AS t1_sell
        FROM
          ( SELECT client_cd, NVL(stk_cd_new,stk_cd) stk_cd,
              (SUM( DECODE(SUBSTR(contr_num,5,1),'B',1,-1) * DECODE(kpei_due_dt, a_dt_t1,1,0) * qty)) t2_sell,
              (SUM( DECODE(SUBSTR(contr_num,5,1),'B',1,-1) * DECODE(kpei_due_dt, a_dt_t2,1,0) * qty)) t1_sell
            FROM T_CONTRACTS,
                  ( SELECT stk_cd_old, stk_cd_new
                          FROM T_CHANGE_STK_CD
                      WHERE eff_Dt <= a_due_dt)
            WHERE contr_dt > ( a_dt_t1 - 20)
            AND kpei_due_dt BETWEEN a_dt_t1 AND a_dt_t2
            AND contr_stat <> 'C'
            AND mrkt_type  <> 'NG'
            AND mrkt_type  <> 'TS'
            --AND client_Cd = 'WIMP001R'
            AND stk_cd = stk_cd_old(+)
            AND client_cd ||stk_cd NOT IN  ( SELECT trim(client_cd)||trim(stk_cd) FROM v_porto_jaminan )
            GROUP BY client_cd,  stk_cd, stk_cd_new   )
        WHERE t2_Sell < 0  OR t1_sell    < 0     ) t2
    WHERE s3.client_cd = t2.client_cd(+)
    AND s3.stk_cd      = t2.stk_cd(+)
    --AND s3.stk_cd IN ( 'SSMS','JT33')
      --   and s3.client_cd = 'SAND001R'
      --and (s3.t3_trf004 <> 0 or t2.t2_sell <> 0 or t2.t1_sell <> 0)
    ORDER BY 1,2;


    CURSOR csr_jur
    IS
      SELECT doc_num
      FROM T_STK_MOVEMENT
      WHERE doc_dt         = p_curr_date
      AND trim(gl_Acct_cd) = '13'
      AND db_cr_flg        = 'D'
      AND doc_stat         = '2';


    V_DOC_NUM T_STK_MOVEMENT.DOC_NUM%TYPE;
    V_trx_dt    DATE;
    v_due_dt    DATE;
    v_bgn_dt    DATE;
    v_dt_min1   DATE;
    v_dt_t1     DATE;
    v_dt_t2     DATE;
    v_t1_sell   NUMBER;
    v_t1_trf004 NUMBER;
    v_tot_004   NUMBER;
    v_qty004    NUMBER;
    v_in_004    NUMBER;
    v_out_004   NUMBER;
    v_sisa004   NUMBER;
    v_cnt       NUMBER;
    V_JUR_TYPE T_STK_MOVEMENT.JUR_TYPE%TYPE :='KE004';
  --  v_db_cr_flg t_stk_movement.db_cr_flg%type;
    V_REVERSAL_DOC_NUM T_STK_MOVEMENT.DOC_NUM%TYPE;
    --V_GL_ACCT_DEB T_STK_MOVEMENT.gl_Acct_cd%TYPE;
   --V_GL_ACCT_CRE T_STK_MOVEMENT.gl_Acct_cd%TYPE;
  --  v_gl_acct_cd t_stk_movement.gl_Acct_cd%type;
  BEGIN

    V_due_DT  := p_curr_date;
    v_trx_dt  := Get_Doc_Date(3,v_due_dt);
    v_bgn_dt  := v_due_dt - TO_NUMBER( TO_CHAR(v_due_dt,'dd') ) + 1;
    v_dt_min1 := Get_Doc_Date(1,v_due_dt);
    v_dt_t1   := Get_Due_Date(1,v_due_dt);
    v_dt_t2   := Get_Due_Date(2,v_due_dt);

    BEGIN
      Sp_Revers_Secjur_004(p_curr_date, p_user_id, V_ERROR_CD, V_ERROR_MSG);
    EXCEPTION
    WHEN OTHERS THEN
      V_ERROR_CD  := -5;
      V_ERROR_MSG := 'select  jurnal 004 on t_STK_MOVEMENT '||SQLERRM;
      RAISE V_ERR;
    END;

    IF V_ERROR_CD  <0 THEN
      V_ERROR_CD  := -7;
      V_ERROR_MSG := 'SP_REVERS_SECJUR_004 '||V_ERROR_MSG;
      RAISE V_ERR;
    END IF;

    v_cnt := 0;

    BEGIN
      SELECT COUNT(1)
      INTO v_cnt
      FROM T_STK_MOVEMENT
      WHERE doc_dt         = p_curr_date
      AND trim(gl_Acct_cd) = '13'
      AND db_cr_flg        = 'D'
      AND s_d_type         = '4'
      AND doc_stat         = '2';
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      v_cnt := 0;
    WHEN OTHERS THEN
      V_ERROR_CD  := -10;
      V_ERROR_MSG := 'select  jurnal 004 on t_STK_MOVEMENT '||SQLERRM;
      RAISE V_ERR;
    END;

    IF v_cnt > 0 THEN

      FOR reca IN csr_jur
      LOOP
        -- diganti sp REVERS STKMVM
        BEGIN
          Sp_Reverse_Stkmvmt( p_curr_date, reca.doc_num, P_USER_ID, V_REVERSAL_DOC_NUM, V_ERROR_CD, V_ERROR_MSG);
        EXCEPTION
        WHEN OTHERS THEN
          V_ERROR_CD  := -20;
          V_ERROR_MSG := 'Sp_Reverse_Stkmvmt Cancel jurnal 004 on t_STK_MOVEMENT '||SQLERRM;
          RAISE V_ERR;
        END;

        IF V_ERROR_CD  <0 THEN
          V_ERROR_CD  := -25;
          V_ERROR_MSG := 'Sp_Reverse_Stkmvmt '||V_ERROR_MSG;
          RAISE V_ERR;
        END IF;

      END LOOP;

    END IF;

    FOR rec IN csr_004( v_trx_dt, v_due_dt, v_bgn_dt, v_dt_min1, v_dt_t1, v_dt_t2 )
    LOOP

      IF rec.sisa_2  = 0 THEN
        v_t1_trf004 := 0;
      ELSE
        IF rec.sisa_2 >= rec.t1_sell THEN
          v_t1_trf004 := rec.t1_sell;
        ELSE
          v_t1_trf004 := rec.sisa_2;
        END IF;
      END IF;

      v_tot_004 := rec.t3_trf004+ rec.t2_trf004 + v_t1_trf004;

      BEGIN
        SELECT SUM(NVL( DECODE(db_cr_flg,'D',1,-1) * (total_share_qty + withdrawn_share_qty),0)) qty004
        INTO v_qty004
        FROM( SELECT client_cd,NVL(stk_cd_new,stk_cd) stk_cd, db_cr_flg, total_share_Qty , withdrawn_share_qty
              FROM T_STK_MOVEMENT,
                  ( SELECT stk_cd_old, stk_cd_new
                          FROM T_CHANGE_STK_CD
                      WHERE eff_Dt <= v_due_dt)
              WHERE doc_dt    = v_dt_min1
              AND gl_acct_cd IN ('13')
              AND gl_acct_cd IS NOT NULL
              AND doc_stat    = '2'
              AND db_cr_flg   = 'D'
              AND s_d_type    = '4'
              AND client_cd   = rec.client_cd
              AND stk_cd      = stk_cd_old(+))
        WHERE stk_cd      = rec.stk_cd
        GROUP BY client_Cd,    stk_Cd;
      EXCEPTION
      WHEN NO_DATA_FOUND THEN
        v_qty004:= 0;
      WHEN OTHERS THEN
        V_ERROR_CD  := -30;
        V_ERROR_MSG :='select qty004 '||REC.client_cd||'  on t_stk_movement '||SQLERRM;
        RAISE V_ERR;
      END;
      --decode( sign(tot_004), 1, decode(sign(tot_004 - qty004),-1,0,tot_004 - qty004 ), 0) IN_004
      --  decode( sign(tot_004), 1, decode(sign(tot_004 - qty004),-1,qty004 -tot_004,0 ),-1, abs(tot_004),0) out_004,
      --(tot_004 - t3_trf004) as sisa002
      v_sisa004   := v_tot_004 - rec.t3_trf004;
      IF v_sisa004 > 0 THEN

        V_DOC_NUM := Get_Stk_Jurnum( p_curr_date,'JA4');

        BEGIN
          Sp_Secu_Jurnal_Nextg ( V_DOC_NUM, NULL, p_curr_date, 
          rec.CLIENT_CD, rec.STK_CD,'4',
          NULL, 0, v_sisa004 ,
          'Pindah ke 004', '2', NULL, 
          0, NULL, NULL,
          '13', NULL, 'D', 
          p_user_id, SYSDATE, NULL,
          p_curr_date, p_curr_date, 1,
          0, 'N',V_JUR_TYPE,                                                                                                                                                                                                           --JUR TYPE
          2, '12', 'C' , V_ERROR_CD, V_ERROR_MSG);
        EXCEPTION
        WHEN OTHERS THEN
          V_ERROR_CD  := -50;
          V_ERROR_MSG := 'insert pindahke 004'||REC.client_cd||'  on T_STK_MOVEMENT '||SQLERRM ;
          RAISE V_ERR;
        END;

        IF V_ERROR_CD  <0 THEN
          V_ERROR_CD  := -55;
          V_ERROR_MSG := 'Sp_Secu_Jurnal_Nextg'||V_ERROR_MSG;
          RAISE V_ERR;
        END IF;

        -- call sp upd_t stkhand
          BEGIN
            Sp_Upd_T_Stkhand ( rec.CLIENT_CD, REC.STK_CD , '%' , NULL, v_sisa004, V_JUR_TYPE, P_USER_ID, V_ERROR_CD, V_ERROR_MSG );
          EXCEPTION
          WHEN OTHERS THEN
            V_ERROR_CD  := -60;
            V_ERROR_MSG := 'Sp_Upd_T_Stkhand UPDATE T_STKHAND'||SQLERRM;
            RAISE V_ERR;
          END;

          IF V_ERROR_CD  <0 THEN
            V_ERROR_CD  := -65;
            V_ERROR_MSG := 'Sp_Upd_T_Stkhand '||V_ERROR_MSG;
            RAISE V_ERR;
          END IF;

      END IF;

    END LOOP;

    P_ERROR_CD  := 1 ;
    P_ERROR_MSG := '';

  EXCEPTION
  WHEN V_ERR THEN
    ROLLBACK;
    P_ERROR_MSG := SUBSTR(V_ERROR_MSG,1,200);
    P_ERROR_CD  := V_ERROR_CD;
  WHEN OTHERS THEN
    P_ERROR_CD  := -1 ;
    P_ERROR_MSG := SUBSTR(SQLERRM(SQLCODE),1,200);
    RAISE;
  END Sp_Gen_Secjur_004;