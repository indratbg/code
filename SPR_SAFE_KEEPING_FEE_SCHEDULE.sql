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
V_CLIENT_NAME MST_CLIENT.CLIENT_NAME%TYPE;
V_SUBREK VARCHAR2(14);
V_SUBREK_TYPE T_SAFE_KEEPING_FEE.SUBREK_TYPE%TYPE;
  CURSOR CSR_DATA IS
          SELECT doc_dt, client_cd, stk_cd, SUM(onh_qty)-sum(repo_qty) onh_qty, sum(repo_qty) repo_qty
          FROM
            (
              SELECT doc_dt, t_stk_movement.client_cd, NVL(c.stk_cd_new,stk_cd)stk_cd,
              (NVL(DECODE(SUBSTR(doc_num,5,2),'JV',1,'XS',1,'LS',1,'RS',1,'WS',1,'CS',1,0) * 
              DECODE(trim(gl_acct_cd),'36',1, 0) * DECODE(db_cr_flg,'D',-1,1) * 
              (total_share_qty + withdrawn_share_qty),0)) onh_qty,            
              (NVL(DECODE(SUBSTR(doc_num,5,2),'JV',1,'XS',1,'LS',1,'RS',1,'WS',1,'CS',1,0) * 
              DECODE(trim(gl_acct_cd),'09',1, 0) * DECODE(db_cr_flg,'D',1,-1) * 
              (total_share_qty + withdrawn_share_qty),0)) repo_qty
              FROM t_stk_movement, (
                  SELECT stk_cd_new, stk_cd_old FROM t_change_stk_cd WHERE eff_dt<= V_DATE
                )c
              WHERE doc_dt = V_DATE
              AND stk_cd   =c.stk_cd_old(+)
              AND gl_acct_cd              IN ('36','09')
              AND doc_stat                 = '2'
              UNION ALL
              SELECT bal_dt, t_secu_bal.client_Cd, NVL(c.stk_cd_new,stk_cd)stk_Cd, 
              DECODE(trim(gl_acct_Cd),'36',qty,'35',qty,0) beg_onh,
               DECODE(trim(gl_acct_Cd),'09',qty,0) beg_repo
              FROM t_secu_bal, (
                  SELECT stk_cd_new, stk_cd_old FROM t_change_stk_cd WHERE eff_dt<= V_DATE
                ) c
              WHERE bal_dt = V_DATE
              AND stk_cd               =c.stk_cd_old(+)
              UNION ALL
              SELECT to_date(VS_DATE,'ddmmyyyy') , T_SAFE_KEEPING_FEE.client_cd, stk_cd, 
              decode(subrek_type, '001', qty, 0) onh_qty, 
              decode(subrek_type, '004', qty, 0) repo_qty
              FROM T_SAFE_KEEPING_FEE
              WHERE doc_dt                          = V_PREV_DATE
            )
          GROUP BY doc_dt,client_cd, stk_cd
          HAVING (SUM(onh_qty) >0  OR SUM(REPO_QTY) >0 );
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
  INSERT INTO TMP_SAFE_KEEPING_CLIENT(CLIENT_CD,CLIENT_NAME,SUBREK,RAND_VALUE,SUBREK_TYPE)
  SELECT M.CLIENT_CD, CLIENT_NAME, NVL(SUBREK,'0000') SUBREK,V_RANDOM_VALUE, SUBREK_TYPE
    FROM MST_CLIENT M 
    LEFT JOIN 
    (
        SELECT CLIENT_CD, SUBSTR(SUBREK001,6,4) AS SUBREK, '001' SUBREK_TYPE FROM V_CLIENT_SUBREK14
        UNION ALL
        SELECT CLIENT_CD, SUBSTR(SUBREK004,6,4) AS SUBREK, '004' SUBREK_TYPE FROM V_CLIENT_SUBREK14
    )V 
      ON M.CLIENT_CD = V.CLIENT_CD
      JOIN
  (
    SELECT CLIENT_CD
    FROM T_STK_MOVEMENT
    WHERE DOC_DT BETWEEN V_BGN_PREV_DATE AND V_END_PREV_DATE
    AND GL_ACCT_CD  IN ('36','09')
    AND DOC_STAT   = '2'
    UNION
    SELECT CLIENT_CD
    FROM T_SECU_BAL
    WHERE BAL_DT    = V_BGN_PREV_DATE
  )C
  ON M.CLIENT_CD = C.CLIENT_CD;
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
      
      --BARIS SUBREK 001 UNTUK ON HAND
      IF REC.ONH_QTY>0 THEN
          
           BEGIN
          SELECT CLIENT_NAME,SUBREK, SUBREK_TYPE INTO V_CLIENT_NAME,V_SUBREK,V_SUBREK_TYPE FROM TMP_SAFE_KEEPING_CLIENT 
          WHERE RAND_VALUE=V_RANDOM_VALUE AND CLIENT_CD=REC.CLIENT_CD AND SUBREK_TYPE='001';
          EXCEPTION
         WHEN OTHERS THEN
            V_ERROR_CD  := -92;
            V_ERROR_MSG := SUBSTR('SELECT SUBREK 001 FROM TMP_SAFE_KEEPING_CLIENT '||SQLERRM(SQLCODE),1,200);
            RAISE V_err;
          END;

          V_STK_VALUE := rec.onh_qty * V_Price;
          v_fee := rec.onh_qty * V_Price * V_rate;

            BEGIN
              INSERT
              INTO T_SAFE_KEEPING_FEE
                (
                  DOC_DT, CLIENT_CD, STK_CD, QTY, PRICE, STK_VALUE, FEE, CLIENT_NAME, SUBREK,GENERATE_DT, SUBREK_TYPE
                )
              VALUES(REC.DOC_DT, REC.CLIENT_CD,REC.STK_CD,REC.onh_qty, V_Price,V_STK_VALUE,v_fee,V_CLIENT_NAME,v_SUBREK, sysdate,V_SUBREK_TYPE);
            EXCEPTION
            WHEN OTHERS THEN
              V_ERROR_CD  := -100;
              V_ERROR_MSG := SUBSTR('INSERT T_SAFE_KEEPING_FEE UNTUK ON HAND '||V_ERROR_MSG||SQLERRM(SQLCODE),1,200);
              RAISE V_err;
            END;
    END IF;

    --BARIS SUBREK 001 UNTUK REPO
     IF REC.REPO_QTY>0 THEN
        
        BEGIN
          SELECT CLIENT_NAME,SUBREK,SUBREK_TYPE INTO V_CLIENT_NAME,V_SUBREK, V_SUBREK_TYPE FROM TMP_SAFE_KEEPING_CLIENT 
          WHERE RAND_VALUE=V_RANDOM_VALUE AND CLIENT_CD=REC.CLIENT_CD AND SUBREK_TYPE='004';
          EXCEPTION
         WHEN OTHERS THEN
            V_ERROR_CD  := -113;
           V_ERROR_MSG := SUBSTR('SELECT SUBREK 004 FROM TMP_SAFE_KEEPING_CLIENT '||SQLERRM(SQLCODE),1,200);
            RAISE V_err;
          END;

          V_STK_VALUE := rec.REPO_qty * V_Price;
          v_fee := rec.REPO_qty * V_Price * V_rate;

            BEGIN
              INSERT
              INTO T_SAFE_KEEPING_FEE
                (
                  DOC_DT, CLIENT_CD, STK_CD, QTY, PRICE, STK_VALUE, FEE, CLIENT_NAME, SUBREK,GENERATE_DT, SUBREK_TYPE
                )
              VALUES(REC.DOC_DT, REC.CLIENT_CD,REC.STK_CD,REC.REPO_QTY, V_Price,V_STK_VALUE,v_fee,V_CLIENT_NAME,v_SUBREK, sysdate,V_SUBREK_TYPE);
            EXCEPTION
            WHEN OTHERS THEN
              V_ERROR_CD  := -115;
              V_ERROR_MSG := SUBSTR('INSERT T_SAFE_KEEPING_FEE UNTUK REPO '||V_ERROR_MSG||SQLERRM(SQLCODE),1,200);
              RAISE V_err;
            END;
    END IF;



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
  SP_INSERT_ORCL_ERRLOG('INSISTPRO_RPT', 'ORCLBO', 'PROCEDURE : SPR_SAFE_KEEPING_FEE_SCHEDULE ', V_ERROR_CD||' '||V_ERROR_MSG);
END;
COMMIT;
  ROLLBACK;
 
WHEN OTHERS THEN
  ROLLBACK;
BEGIN
  SP_INSERT_ORCL_ERRLOG('INSISTPRO_RPT', 'ORCLBO', 'PROCEDURE : SPR_SAFE_KEEPING_FEE_SCHEDULE ', SUBSTR(SQLERRM(SQLCODE),1,200));
END;
  RAISE;
END SPR_SAFE_KEEPING_FEE_SCHEDULE;