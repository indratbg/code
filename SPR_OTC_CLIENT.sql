create or replace PROCEDURE SPR_OTC_CLIENT(
   P_BGN_DT DATE,
   P_END_DT DATE,
   P_CHARGE_FLG VARCHAR2, --% ALL, N = NONCHARGEABLE, Y=CHARGEABLE
    P_USER_ID       VARCHAR2,
    P_GENERATE_DATE DATE,
    P_RANDOM_VALUE OUT NUMBER,
    P_ERROR_CD OUT NUMBER,
    P_ERROR_MSG OUT VARCHAR2 )
IS
  V_ERROR_MSG    VARCHAR2(200);
  V_ERROR_CD     NUMBER(10);
  v_random_value NUMBER(10);
  V_ERR          EXCEPTION;
  P_OTC_FEE NUMBER:=20000;
BEGIN
  
  v_random_value := ABS(dbms_random.random);
  
  BEGIN
    SP_RPT_REMOVE_RAND('R_OTC_CLIENT',V_RANDOM_VALUE,V_ERROR_MSG,V_ERROR_CD);
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
    INSERT INTO R_OTC_CLIENT (ACOPEN_FEE_FLG,CLIENT_CD, CLIENT_NAME, OTC_CLIENT, USER_ID, RAND_VALUE, GENERATE_DATE )
      
      SELECT CHARGE_FLG,CLIENT_CD,CLIENT_NAME,SUM_OTC, P_USER_ID,V_RANDOM_VALUE,P_GENERATE_DATE
      FROM 
      (
          SELECT DECODE(B.TIDAK_DIJURNAL,'Y','N','Y')CHARGE_FLG,A.CLIENT_CD,A.CLIENT_NAME,SUM_OTC
          FROM MST_CLIENT A
          JOIN
            (
              SELECT client_cd,tidak_dijurnal, MAX(sum_otc)sum_otc
              FROM t_daily_otc_jur
              WHERE JUR_DATE BETWEEN P_BGN_DT AND P_END_DT
              GROUP BY client_cd,tidak_dijurnal
            )
            B
          ON A.CLIENT_CD     =B.CLIENT_CD
          AND A.APPROVED_STAT='A'
          UNION ALL
          SELECT 'N' CHARGE_FLG, client_cd,CLIENT_NAME,SUM( DECODE(net_qty , 0,0, P_OTC_FEE)) OTC_CLIENT
          FROM
            (
              SELECT A.DOC_DT, A.CLIENT_CD, b.CLIENT_NAME, A.STK_CD, SUM(A.TOTAL_SHARE_QTY - A.WITHDRAWN_SHARE_QTY) AS NET_QTY
              FROM IPNEXTG.T_STK_MOVEMENT A, IPNEXTG.MST_CLIENT B
              WHERE A.SEQNO              = 1
              AND A.CLIENT_CD            = B.CLIENT_CD
              AND SUBSTR(A.DOC_NUM,5,3) IN ('RSN','WSN','JVS','JVB')
              AND A.DOC_STAT             = '2'
              AND A.DOC_DT BETWEEN P_BGN_DT AND P_END_DT
              AND A.BROKER       IS NOT NULL
              AND B.ACOPEN_FEE_FLG='N'
              AND B.APPROVED_STAT ='A'
              GROUP BY A.DOC_DT, A.CLIENT_CD, A.STK_CD, b.CLIENT_NAME
            )
          GROUP BY client_Cd, CLIENT_NAME
      )
      WHERE (CHARGE_FLG=P_CHARGE_FLG OR P_CHARGE_FLG='%');
  EXCEPTION
  WHEN OTHERS THEN
    V_ERROR_CD  := -30;
    V_ERROR_MSG := SUBSTR('INSERT R_OTC_CLIENT '||V_ERROR_MSG||SQLERRM(SQLCODE),1,200);
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
END SPR_OTC_CLIENT;