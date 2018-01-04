CREATE OR REPLACE
PROCEDURE SPR_LIST_OF_CHEQUE(
    P_BGN_DATE      DATE,
    P_END_DATE      DATE,
    P_BGN_CLIENT    VARCHAR2,
    P_END_CLIENT    VARCHAR2,
    P_BGN_BANK      VARCHAR2,
    P_END_BANK      VARCHAR2,
    P_VOUCHER_TYPE  VARCHAR2,
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
BEGIN

  V_RANDOM_VALUE := ABS(DBMS_RANDOM.RANDOM);
  
  BEGIN
    SP_RPT_REMOVE_RAND('R_LIST_OF_CHEQUE',V_RANDOM_VALUE,V_ERROR_MSG,V_ERROR_CD);
  EXCEPTION
  WHEN OTHERS THEN
    V_ERROR_CD  := -30;
    V_ERROR_MSG := SUBSTR('SP_RPT_REMOVE_RAND '||V_ERROR_MSG||SQLERRM(SQLCODE),1,200);
    RAISE V_err;
  END;
  
  IF V_ERROR_CD  <0 THEN
    V_ERROR_CD  := -40;
    V_ERROR_MSG := SUBSTR('SP_RPT_REMOVE_RAND'||V_ERROR_MSG,1,200);
    RAISE V_ERR;
  END IF;
  
  BEGIN
    INSERT
    INTO R_LIST_OF_CHEQUE
      (
        PAYREC_DATE ,
        FOLDER_CD ,
        CLIENT_CD ,
        CLIENT_NAME ,
        DESCRIP ,
        SL_ACCT_CD ,
        OLD_IC_NUM ,
        CHQ_NUM ,
        CHQ_AMT ,
        VOUCHER_TYPE ,
        USER_ID ,
        RAND_VALUE ,
        GENERATEDATE ,
        BGN_DATE ,
        END_DATE
      )
    SELECT h.payrec_date,
      h.folder_cd,
      h.client_cd,
      m.client_name,
      trim(h.remarks)
      ||trim(q.descrip) descrip,
      h.sl_acct_cd,
      m.old_ic_num,
      q.chq_num,
      DECODE(SUBSTR(h.payrec_num,5,1),'R',1,'P',-1) * q.chq_amt AS chq_amt ,
      P_VOUCHER_TYPE,
      P_USER_ID,
      V_RANDOM_VALUE,
      P_GENERATE_DATE,
      P_BGN_DATE,
      P_END_DATE
    FROM t_payrech h,
      t_cheq q,
      mst_client m
    WHERE h.payrec_date BETWEEN P_BGN_DATE AND P_END_DATE
    AND NVL(h.client_cd,'%') BETWEEN P_BGN_CLIENT AND P_END_CLIENT
    AND h.sl_acct_cd BETWEEN P_BGN_BANK AND P_END_BANK
    AND SUBSTR(H.PAYREC_TYPE,1,1) LIKE P_VOUCHER_TYPE
    AND h.approved_sts <> 'C'
    AND h.client_cd     = m.client_cd (+)
    AND h.payrec_num    = q.rvpv_number;
  EXCEPTION
  WHEN OTHERS THEN
    V_ERROR_CD  := -50;
    V_ERROR_MSG := SUBSTR('INSERT R_LIST_OF_CHEQUE'||V_ERROR_MSG||SQLERRM(SQLCODE),1,200);
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
END SPR_LIST_OF_CHEQUE;