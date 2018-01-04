create or replace PROCEDURE SPR_SAFE_KEEPING_FEE(
    P_REPORT_DATE DATE,
    P_REPORT_TYPE T_STK_MOVEMENT.USER_ID%type, -- 'DETAIL /SUMMARY
    P_BGN_CLIENT T_STK_MOVEMENT.CLIENT_CD%type,
    P_END_CLIENT T_STK_MOVEMENT.CLIENT_CD%type,
    P_BGN_SUBREK VARCHAR2,
    P_END_SUBREK VARCHAR2,
    P_USER_ID T_STK_MOVEMENT.USER_ID%type,
    P_RANDOM_VALUE OUT NUMBER,
    P_ERROR_CD OUT NUMBER,
    P_ERROR_MSG OUT VARCHAR2 )
IS
  I_date         INTEGER;
  v_jumlah_tgl   NUMBER;
  VS_DATE        VARCHAR2(8); --ddmmyyyy
  V_BGN_DATE     DATE;
  V_date         DATE;
  V_PREV_DATE    DATE;
  V_PRICE_DATE   DATE;
  v_rate         NUMBER;
  V_ERROR_MSG    VARCHAR2(200);
  V_ERROR_CD     NUMBER(10);
  v_random_value NUMBER(10);
  V_ERR          EXCEPTION;
BEGIN
  v_random_value := ABS(dbms_random.random);
  
  BEGIN
    SP_RPT_REMOVE_RAND('R_SAFE_KEEPING_FEE',V_RANDOM_VALUE,V_ERROR_MSG,V_ERROR_CD);
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
  --BEGIN
  INSERT INTO TMP_SAFE_KEEPING_CLIENT
  SELECT m.client_Cd, client_name, subrek001, v_random_value
  FROM mst_client m, v_client_subrek14 v
  WHERE m.client_cd = v.client_cd
  AND M.CLIENT_CD BETWEEN P_BGN_CLIENT AND P_END_CLIENT
  AND SUBSTR(subrek001,6,4) BETWEEN P_BGN_SUBREK AND P_END_SUBREK;
  
  V_BGN_DATE       := P_REPORT_DATE - TO_CHAR(P_REPORT_DATE ,'dd') + 1;
  V_date           := V_BGN_DATE;
  V_PREV_DATE      := V_BGN_DATE;
  v_jumlah_tgl     := to_number(TO_CHAR(P_REPORT_DATE ,'dd'));
  v_rate           := 0.005 /100/365;
  
  FOR I_date               IN 1..v_jumlah_tgl
  LOOP
  
    VS_DATE                                        := TO_CHAR( V_DATE,'ddmmyyyy');
    V_PRICE_DATE                                   := V_DATE;
    
    IF F_IS_HOLIDAY( TO_CHAR( V_DATE,'dd/mm/yyyy')) = 1 THEN
      BEGIN
        SELECT MAX(stk_date)
        INTO V_Price_Date
        FROM T_CLOSE_PRICe
        WHERE stk_date BETWEEN V_DAte - 30 AND V_date;
      EXCEPTION
      WHEN OTHERS THEN
        V_ERROR_CD  := -30;
        V_ERROR_MSG := SUBSTR('INSERT R_SAFE_KEEPING_FEE '||V_ERROR_MSG||SQLERRM(SQLCODE),1,200);
        RAISE V_err;
      END;
    END IF;
    
    BEGIN
      INSERT
      INTO R_SAFE_KEEPING_FEE
        (
          DOC_DT, CLIENT_CD, STK_CD, QTY, PRICE, STK_VALUE, FEE, CLIENT_NAME, SUBREK, RAND_VALUE, USER_ID, GENERATE_DT
        )
      SELECT doc_dt, a.client_cd, a.stk_cd, onh_qty, price, onh_qty * price stk_value, onh_qty * price * V_rate fee, 
      client_name, SUBSTR(subrek,6,4)SUBREK, v_random_value, P_USER_ID, sysdate
      FROM
        (
          SELECT doc_dt, client_cd, stk_cd, SUM(onh_qty) onh_qty
          FROM
            (
              SELECT doc_dt, t_stk_movement.client_cd, NVL(c.stk_cd_new,stk_cd)stk_cd,
              (NVL(DECODE(SUBSTR(doc_num,5,2),'JV',1,'XS',1,'LS',1,'RS',1,'WS',1,'CS',1,0) * 
              DECODE(trim(NVL(gl_acct_cd,'36')),'36',1, 0) * DECODE(db_cr_flg,'D',-1,1) * 
              (total_share_qty + withdrawn_share_qty),0)) onh_qty
              FROM t_stk_movement, TMP_SAFE_KEEPING_CLIENT TMP, (
                  SELECT stk_cd_new, stk_cd_old FROM t_change_stk_cd WHERE eff_dt<= V_DATE
                )
                c
              WHERE doc_dt = V_DATE
              AND stk_cd   =c.stk_cd_old(+)
              AND t_stk_movement.client_cd BETWEEN P_BGN_CLIENT AND P_END_CLIENT
              AND gl_acct_cd              IN ('36')
              AND doc_stat                 = '2'
              AND TMP.rand_value           = v_random_value
              AND t_stk_movement.client_cd = TMP.Client_cd
              UNION ALL
              SELECT bal_dt, t_secu_bal.client_Cd, NVL(c.stk_cd_new,stk_cd)stk_Cd, DECODE(trim(gl_acct_Cd),'36',qty,'35',qty,0) beg_onh
              FROM t_secu_bal, TMP_SAFE_KEEPING_CLIENT TMP, (
                  SELECT stk_cd_new, stk_cd_old FROM t_change_stk_cd WHERE eff_dt<= V_DATE
                )
                c
              WHERE bal_dt = V_DATE
              AND t_secu_bal.client_cd BETWEEN P_BGN_CLIENT AND P_END_CLIENT
              AND stk_cd               =c.stk_cd_old(+)
              AND TMP.rand_value       = v_random_value
              AND t_secu_bal.client_cd = TMP.Client_cd
              UNION ALL
              SELECT to_date(VS_DATE,'ddmmyyyy') , R_SAFE_KEEPING_FEE.client_cd, stk_cd, qty
              FROM R_SAFE_KEEPING_FEE, TMP_SAFE_KEEPING_CLIENT TMP
              WHERE R_SAFE_KEEPING_FEE.rand_value = v_random_value
              AND doc_dt                          = V_PREV_DATE
              AND TMP.rand_value                  = v_random_value
              AND R_SAFE_KEEPING_FEE.client_cd    = TMP.Client_cd
            )
          GROUP BY doc_dt,client_cd, stk_cd
          HAVING SUM(onh_qty) <> 0
        )
        a, (
          SELECT to_date(VS_DATE,'ddmmyyyy') stk_date, stk_cd, stk_clos AS price
          FROM T_CLOSE_PRICE
          WHERE stk_date = V_PRICE_DATE
        )
        b, TMP_SAFE_KEEPING_CLIENT c
      WHERE a.stk_cd  = b.stk_cd
      AND a.doc_dt    = b.stk_date
      AND a.client_Cd = c.client_Cd;
    EXCEPTION
    WHEN OTHERS THEN
      V_ERROR_CD  := -30;
      V_ERROR_MSG := SUBSTR('INSERT R_SAFE_KEEPING_FEE '||V_ERROR_MSG||SQLERRM(SQLCODE),1,200);
      RAISE V_err;
    END;
    
    V_Prev_date := V_date;
    V_date      := V_date + 1;
    
  END LOOP;
  
  delete from TMP_SAFE_KEEPING_CLIENT where RAND_VALUE=v_random_value;
  
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
END SPR_SAFE_KEEPING_FEE;