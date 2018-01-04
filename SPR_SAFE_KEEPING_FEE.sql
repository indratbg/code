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
  V_PRICE T_CLOSE_PRICE.stk_clos%TYPE;
  V_STK_VALUE NUMBER;
  v_fee number;
  V_CNT NUMBER;
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
        
        
        IF TO_CHAR(P_REPORT_DATE,'MMYYYY') = TO_CHAR(SYSDATE,'MMYYYY') THEN
           V_ERROR_CD  := -5;
            V_ERROR_MSG := 'Hanya boleh generate stock safe keeping fee bulan lalu';
            RAISE V_ERR;
        END IF;
        
        --ambil dri hasil scehdule jika tersedia
        V_BGN_DATE := TO_DATE('01'||TO_CHAR(P_REPORT_DATE,'MMYYYY'),'DDMMYYYY');
        
        BEGIN
        SELECT COUNT(1) INTO V_CNT FROM T_SAFE_KEEPING_FEE WHERE DOC_DT BETWEEN V_BGN_DATE AND P_REPORT_DATE
        AND CLIENT_CD BETWEEN P_BGN_CLIENT AND P_END_CLIENT
         AND SUBREK BETWEEN P_BGN_SUBREK AND P_END_SUBREK;
        EXCEPTION
        WHEN OTHERS THEN
          V_ERROR_CD  := -10;
          V_ERROR_MSG := SUBSTR('SELECT COUNT FROM T_SAFE_KEEPING_FEE '||SQLERRM(SQLCODE),1,200);
          RAISE V_err;
        END;
           
        IF V_CNT=0 THEN
          V_ERROR_CD  := -11;
          V_ERROR_MSG := 'Report belum tersedia';
          RAISE V_err;
        END IF;


        IF P_REPORT_TYPE = 'SUMMARY' THEN

        INSERT INTO R_SAFE_KEEPING_FEE
                    (
                      CLIENT_CD, CLIENT_NAME, SUBREK, STK_VALUE, FEE, RAND_VALUE, USER_ID, GENERATE_DT
                    )
                    SELECT CLIENT_CD,MAX(CLIENT_NAME)CLIENT_NAME, MAX(SUBREK)SUBREK, SUM(STK_VALUE)STK_VALUE,
                    round(sum(stk_value) * 0.005/100 / 365, 2) as fee, V_RANDOM_VALUE, P_USER_ID,sysdate
                    FROM T_SAFE_KEEPING_FEE WHERE DOC_DT BETWEEN V_BGN_DATE AND P_REPORT_DATE
                     AND CLIENT_CD BETWEEN P_BGN_CLIENT AND P_END_CLIENT
                     AND SUBREK BETWEEN P_BGN_SUBREK AND P_END_SUBREK    
                    GROUP BY CLIENT_CD;
         --DETAIL             
        ELSE

              BEGIN
              INSERT INTO R_SAFE_KEEPING_FEE
                    (
                      DOC_DT, CLIENT_CD, STK_CD, QTY, PRICE, STK_VALUE, FEE, CLIENT_NAME, SUBREK, RAND_VALUE, USER_ID, GENERATE_DT
                    )
               SELECT DOC_DT,CLIENT_CD,STK_CD,QTY,PRICE,STK_VALUE,FEE,CLIENT_NAME,SUBREK,V_RANDOM_VALUE,P_USER_ID,sysdate
               FROM T_SAFE_KEEPING_FEE WHERE DOC_DT BETWEEN V_BGN_DATE AND P_REPORT_DATE
               AND CLIENT_CD BETWEEN P_BGN_CLIENT AND P_END_CLIENT
               AND SUBREK BETWEEN P_BGN_SUBREK AND P_END_SUBREK;     
                EXCEPTION
                  WHEN OTHERS THEN
                    V_ERROR_CD  := -17;
                    V_ERROR_MSG := SUBSTR('INSERT INTO R_SAFE_KEEPING_FEE FROM T_SAFE_KEEPING_FEE '||SQLERRM(SQLCODE),1,200);
                    RAISE V_err;
                  END;

          END IF;
  
  COMMIT;

  P_RANDOM_VALUE :=V_RANDOM_VALUE;
  P_ERROR_CD     := 1 ;
  P_ERROR_MSG    := '';
EXCEPTION
WHEN V_ERR THEN
  rollback;
  P_ERROR_MSG := V_ERROR_MSG;
  P_ERROR_CD  := V_ERROR_CD;
WHEN OTHERS THEN
  P_ERROR_CD  := -1 ;
  P_ERROR_MSG := SUBSTR(SQLERRM(SQLCODE),1,200);
  RAISE;
END SPR_SAFE_KEEPING_FEE;