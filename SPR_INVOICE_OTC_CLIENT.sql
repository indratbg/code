create or replace 
PROCEDURE SPR_INVOICE_OTC_CLIENT(
    P_BGN_DATE      DATE,
    P_END_DATE      DATE,
    P_BGN_STOCK     VARCHAR2,
    P_END_STOCK     VARCHAR2,
    P_BGN_CLIENT    VARCHAR2,
    P_END_CLIENT    VARCHAR2,
    P_BGN_BROKER    VARCHAR2,
    P_END_BROKER    VARCHAR2,
    P_OTC           NUMBER,
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
BEGIN

  v_random_value := ABS(dbms_random.random);
  
  BEGIN
    SP_RPT_REMOVE_RAND('R_INVOICE_OTC_CLIENT',V_RANDOM_VALUE,V_ERROR_MSG,V_ERROR_CD);
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
    INSERT
    INTO R_INVOICE_OTC_CLIENT
      (
        BGN_DATE ,
        END_DATE ,
        DOC_DT ,
        CLIENT_CD ,
        STK_CD ,
        DOC_NUM ,
        TOTAL_SHARE_QTY ,
        WITHDRAWN_SHARE_QTY ,
        DOC_REM ,
        PRICE ,
        BROKER,
        CLIENT_NAME ,
        OTC,
        ACOPEN_FEE_FLG ,
        USER_ID ,
        RAND_VALUE ,
        GENERATE_DATE,
        NON_CHARGEABLE,
        CHARGEABLE,
        GRAND_OTC,
        GRAND_TOTAL_SHARE_QTY,
        GRAND_TOTAL_WITHDRAWN_QTY
      )
      
      SELECT P_BGN_DATE,
      P_END_DATE,
      DOC_DT ,
        CLIENT_CD ,
        STK_CD ,
        DOC_NUM ,
        TOTAL_SHARE_QTY ,
        WITHDRAWN_SHARE_QTY ,
        DOC_REM ,
        PRICE ,
        BROKER,
        CLIENT_NAME ,
        OTC,
        ACOPEN_FEE_FLG ,
          P_USER_ID,
      V_RANDOM_VALUE,
      P_GENERATE_DATE,
       sum(decode(acopen_fee_flg,'N',OTC,0)) over() non_charable ,
        sum(decode(acopen_fee_flg,'Y',OTC,0)) over() chargeable ,
         SUM(OTC) OVER() GRAND_OTC,
        SUM(TOTAL_SHARE_QTY) OVER()GRAND_TOTAL_SHARE_QTY,
        SUM(WITHDRAWN_SHARE_QTY) OVER() GRAND_WITHDRAWN_SHARE_QTY
       FROM (
    SELECT 
      x.DOC_DT,
      x.CLIENT_CD,
      x.STK_CD,
      x.doc_num,
      x.TOTAL_SHARE_QTY,
      x.WITHDRAWN_SHARE_QTY,
      x.doc_rem,
      x.price,
      x.broker,
      x.client_name,
      x.otc * DECODE(SIGN(rw_cnt),0,1, DECODE(SIGN(y.net_qty * x.doc_type),0,0,1,1,-1,0) * DECODE(x.doc_num,y.minr_doc_num,1,y.minw_doc_num,1,0) ) otc,
      x.acopen_fee_flg 
    
      
    FROM
      (SELECT a.DOC_DT,
        a.CLIENT_CD,
        a.STK_CD,
        (DECODE(SUBSTR(a.DOC_NUM,7,1),'J',0,'S',0,a.TOTAL_SHARE_QTY)) TOTAL_SHARE_QTY,
        (DECODE(SUBSTR(a.DOC_NUM,7,1),'J',a.TOTAL_SHARE_QTY,'S',a.TOTAL_SHARE_QTY,a.WITHDRAWN_SHARE_QTY)) WITHDRAWN_SHARE_QTY,
        DECODE(a.s_d_type,'V','Trx',SUBSTR(a.DOC_NUM,5,1)) doc_rem,
        a.price,
        a.withdraw_reason_cd,
        b.client_name,
        P_OTC otc,
        b.acopen_fee_flg,
        a.doc_num,
        a.broker,
        DECODE(SUBSTR(a.doc_num,5,3),'RSN',1,'WSN',-1,0) AS doc_type
      FROM t_stk_movement a,
        mst_client b
      WHERE a.seqno              = 1
      AND SUBSTR(a.DOC_NUM,5,3) IN ('RSN','WSN','JVB','JVS')
      AND a.client_cd            = b.client_cd
      AND a.doc_stat             = '2'
      AND a.doc_dt BETWEEN P_BGN_DATE AND P_END_DATE
      AND a.client_cd BETWEEN P_BGN_CLIENT AND P_END_CLIENT
      AND a.stk_cd BETWEEN P_BGN_STOCK AND P_END_STOCK
      AND a.broker IS NOT NULL
      AND a.broker BETWEEN P_BGN_BROKER AND P_END_BROKER
      ) x,
      (SELECT a.DOC_DT,
        a.CLIENT_CD,
        a.STK_CD,
        SUM(DECODE(SUBSTR(doc_num,5,1),'J',0,a.total_share_qty - a.withdrawn_share_qty)) AS net_qty,
        MIN(DECODE(SUBSTR(doc_num,5,1),'R',doc_num,'_')) minr_doc_num,
        MIN(DECODE(SUBSTR(doc_num,5,1),'W',doc_num,'_')) minw_doc_num,
        SUM(DECODE(SUBSTR(doc_num,5,1),'R',1,0)) * SUM(DECODE(SUBSTR(doc_num,5,1),'W',1,0)) RW_cnt
      FROM t_stk_movement a
      WHERE a.seqno              = 1
      AND SUBSTR(a.DOC_NUM,5,3) IN ('RSN','WSN','JVS','JVB')
      AND a.doc_stat             = '2'
      AND a.doc_dt BETWEEN P_BGN_DATE AND P_END_DATE
      AND a.broker IS NOT NULL
      GROUP BY a.DOC_DT,
        a.CLIENT_CD,
        a.STK_CD
      ) y
    WHERE x.doc_dt  = y.doc_dt
    AND x.client_cd = y.client_cd
    AND x.stk_cd    = y.stk_cd 
    );
  EXCEPTION
  WHEN OTHERS THEN
    V_ERROR_CD  := -30;
    V_ERROR_MSG := SUBSTR('INSERT R_INVOICE_OTC_CLIENT '||V_ERROR_MSG||SQLERRM(SQLCODE),1,200);
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
END SPR_INVOICE_OTC_CLIENT;