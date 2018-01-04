create or replace PROCEDURE SPR_SAFE_KEEPING_FEE_SCHEDULE
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
 v_random_value number(10,0);
  V_ERR          EXCEPTION;
  V_PRICE T_CLOSE_PRICE.stk_clos%TYPE;
  V_STK_VALUE NUMBER;
  v_fee number;
  V_BGN_PREV_DATE DATE;
  V_END_PREV_DATE DATE;
  V_TODAY_DATE DATE:=TRUNC(SYSDATE);
V_CNT NUMBER;
  CURSOR CSR_DATA IS
    SELECT doc_dt, a.client_cd, a.stk_cd, onh_qty,
      client_name, C.SUBREK
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
              AND stk_cd               =c.stk_cd_old(+)
              AND TMP.rand_value       = v_random_value
              AND t_secu_bal.client_cd = TMP.Client_cd
              UNION ALL
              SELECT to_date(VS_DATE,'ddmmyyyy') , T_SAFE_KEEPING_FEE.client_cd, stk_cd, qty
              FROM T_SAFE_KEEPING_FEE, TMP_SAFE_KEEPING_CLIENT TMP
              WHERE T_SAFE_KEEPING_FEE.DOC_DT BETWEEN V_BGN_PREV_DATE AND V_END_PREV_DATE
              AND doc_dt                          = V_PREV_DATE
              AND TMP.rand_value                  = v_random_value
              AND T_SAFE_KEEPING_FEE.client_cd    = TMP.Client_cd
            )
          GROUP BY doc_dt,client_cd, stk_cd
          HAVING SUM(onh_qty) <> 0
        )
        a, TMP_SAFE_KEEPING_CLIENT c
      WHERE a.client_Cd = c.client_Cd
      AND C.RAND_VALUE=v_random_value;
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
  
  V_END_PREV_DATE := V_TODAY_DATE - TO_CHAR(V_TODAY_DATE,'DD');
  V_BGN_PREV_DATE := TO_DATE('01'||TO_CHAR(V_END_PREV_DATE,'MMYYYY'),'DDMMYYYY');

--CEK APAKAH DATA SUDAH ADA APA BELUM
BEGIN
SELECT COUNT(1) INTO V_CNT FROM T_SAFE_KEEPING_FEE WHERE DOC_DT BETWEEN V_BGN_PREV_DATE AND V_END_PREV_DATE;
EXCEPTION
  WHEN OTHERS THEN
    V_ERROR_CD  := -30;
    V_ERROR_MSG := SUBSTR('SELECT COUNT T_SAFE_KEEPING_FEE '||SQLERRM(SQLCODE),1,200);
    RAISE V_err;
  END;
IF V_CNT>0 THEN
    BEGIN
    DELETE FROM T_SAFE_KEEPING_FEE WHERE DOC_DT BETWEEN V_BGN_PREV_DATE AND V_END_PREV_DATE;
    EXCEPTION
  WHEN OTHERS THEN
    V_ERROR_CD  := -40;
    V_ERROR_MSG := SUBSTR('DELETE FROM T_SAFE_KEEPING_FEE DOC_DT '||V_END_PREV_DATE||' '||SQLERRM(SQLCODE),1,200);
    RAISE V_err;
  END;
END IF;

--SAVE DAILY CLOSE PRICE
  BEGIN
  SP_DAILY_CLOSE_PRICE(V_BGN_PREV_DATE, V_END_PREV_DATE, V_ERROR_CD,V_ERROR_MSG);
  EXCEPTION
  WHEN OTHERS THEN
    V_ERROR_CD  := -45;
    V_ERROR_MSG := SUBSTR('CALL SP_DAILY_CLOSE_PRICE '||SQLERRM(SQLCODE),1,200);
    RAISE V_err;
  END;

  IF V_ERROR_CD<0 THEN
    V_ERROR_CD  := -46;
    V_ERROR_MSG := SUBSTR('CALL SP_DAILY_CLOSE_PRICE '||V_ERROR_MSG,1,200);
    RAISE V_err;
  END IF;


 BEGIN
  INSERT INTO TMP_SAFE_KEEPING_CLIENT
 select client_cd,client_name,subrek, v_random_value
  from (
  SELECT m.client_Cd, client_name, nvl(subrek001,'0000') subrek
  FROM mst_client m, 
  ( select client_cd, SUBSTR(subrek001,6,4) as subrek001
    from v_client_subrek14 ) v
  WHERE m.client_cd = v.client_cd(+)
  );
   EXCEPTION
  WHEN OTHERS THEN
    V_ERROR_CD  := -50;
    V_ERROR_MSG := SUBSTR('INSERT INTO TMP_SAFE_KEEPING_CLIENT '||SQLERRM(SQLCODE),1,200);
    RAISE V_err;
  END;
  
  V_BGN_DATE       := V_BGN_PREV_DATE;
  V_date           := V_BGN_DATE;
  V_PREV_DATE      := V_BGN_DATE;
  v_jumlah_tgl     := to_number(TO_CHAR(V_END_PREV_DATE ,'dd'));
  v_rate           := 0.005 /100/365;
  
  FOR I_date               IN 1..v_jumlah_tgl
  LOOP
  
    VS_DATE                                        := TO_CHAR( V_DATE,'ddmmyyyy');
    V_PRICE_DATE                                   := V_DATE;
    FOR REC IN CSR_DATA LOOP

    BEGIN
    SELECT STK_CLOS INTO V_PRICE FROM T_DAILY_CLOS_PRICE WHERE STK_CD=REC.STK_CD AND stk_date=V_Price_Date;
     EXCEPTION
     WHEN NO_DATA_FOUND THEN
     V_PRICE :=0;
     WHEN OTHERS THEN
        V_ERROR_CD  := -92;
        V_ERROR_MSG := SUBSTR('SELECT CLOSE PRICE FROM T_DAILY_CLOS_PRICE '||V_Price_Date||' '||rec.stk_cd||' '||SQLERRM(SQLCODE),1,200);
        RAISE V_err;
      END;

      V_STK_VALUE := rec.onh_qty * V_Price;
      v_fee := rec.onh_qty * V_Price * V_rate;

    BEGIN
      INSERT
      INTO T_SAFE_KEEPING_FEE
        (
          DOC_DT, CLIENT_CD, STK_CD, QTY, PRICE, STK_VALUE, FEE, CLIENT_NAME, SUBREK,GENERATE_DT
        )
      VALUES(REC.DOC_DT, REC.CLIENT_CD,REC.STK_CD,REC.onh_qty, V_Price,V_STK_VALUE,v_fee,REC.CLIENT_NAME,REC.SUBREK, sysdate);
    EXCEPTION
    WHEN OTHERS THEN
      V_ERROR_CD  := -100;
      V_ERROR_MSG := SUBSTR('INSERT T_SAFE_KEEPING_FEE '||V_ERROR_MSG||SQLERRM(SQLCODE),1,200);
      RAISE V_err;
    END;
    END LOOP;

    V_Prev_date := V_date;
    V_date      := V_date + 1;
   
  END LOOP;
  
 begin
  delete from TMP_SAFE_KEEPING_CLIENT where RAND_VALUE=v_random_value;
  EXCEPTION
    WHEN OTHERS THEN
      V_ERROR_CD  := -110;
      V_ERROR_MSG := SUBSTR('DELETE TMP_SAFE_KEEPING_CLIENT '||SQLERRM(SQLCODE),1,200);
      RAISE V_err;
    END;
  COMMIT;

EXCEPTION
WHEN V_ERR THEN
begin
  delete from TMP_SAFE_KEEPING_CLIENT where RAND_VALUE=v_random_value;
  EXCEPTION
    WHEN OTHERS THEN
      V_ERROR_CD  := -110;
      V_ERROR_MSG := SUBSTR('DELETE TMP_SAFE_KEEPING_CLIENT '||SQLERRM(SQLCODE),1,200);
      RAISE V_err;
END;
BEGIN
  SP_INSERT_ORCL_ERRLOG('IPNEXTG', 'ORCLBO', 'PROCEDURE : SPR_SAFE_KEEPING_FEE_SCHEDULE ', V_ERROR_CD||' '||V_ERROR_MSG);
END;
COMMIT;
  ROLLBACK;
 
WHEN OTHERS THEN
  ROLLBACK;
BEGIN
  SP_INSERT_ORCL_ERRLOG('IPNEXTG', 'ORCLBO', 'PROCEDURE : SPR_SAFE_KEEPING_FEE_SCHEDULE ', SUBSTR(SQLERRM(SQLCODE),1,200));
END;
  RAISE;
END SPR_SAFE_KEEPING_FEE_SCHEDULE;