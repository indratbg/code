create or replace 
PROCEDURE SPR_RVP_DVP(
    P_TRX_DATE   DATE,
    P_VALUE_DATE DATE,
    P_SEQ_NO DOCNUM_ARRAY,
    P_SUFFIX_SURAT VARCHAR2,
    P_NO_SURAT VARCHAR_ARRAY,
    P_BROK_PHONE_EXT VARCHAR2,
    P_BROK_CONT_PERS VARCHAR2,
    P_SIGN_BY_1      VARCHAR2,
    P_SIGN_BY_2      VARCHAR2,
    P_USER_ID        VARCHAR2,
    P_GENERATE_DATE  DATE,
    P_RANDOM_VALUE OUT NUMBER,
    P_ERROR_CD OUT NUMBER,
    P_ERROR_MSG OUT VARCHAR2 )
IS
  V_ERROR_MSG    VARCHAR2(200);
  V_ERROR_CD     NUMBER(10);
  v_random_value NUMBER(10);
  V_ERR          EXCEPTION;
  V_SIGN_BY_1 VARCHAR2(20);
  V_SIGN_BY_2 VARCHAR2(20);
  V_SIGN_BY_1_POSITION VARCHAR2(20);
  V_SIGN_BY_2_POSITION VARCHAR2(20);
BEGIN

  v_random_value := ABS(dbms_random.random);
  
  BEGIN
    SP_RPT_REMOVE_RAND('R_RPV_DVP',V_RANDOM_VALUE,V_ERROR_MSG,V_ERROR_CD);
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
    SELECT PRM_DESC, PRM_DESC2 INTO V_SIGN_BY_1, V_SIGN_BY_1_POSITION FROM MST_PARAMETER WHERE PRM_CD_1='SIGNBY' AND PRM_CD_2=P_SIGN_BY_1;
  EXCEPTION
  WHEN OTHERS THEN
    V_ERROR_CD  := -30;
    V_ERROR_MSG := SUBSTR('SELECT SIGN_BY_1 FROM MST_PARAMETER'||SQLERRM(SQLCODE),1,200);
    RAISE V_err;
  END;
  
  BEGIN
    SELECT PRM_DESC, PRM_DESC2 INTO V_SIGN_BY_2, V_SIGN_BY_2_POSITION FROM MST_PARAMETER WHERE PRM_CD_1='SIGNBY' AND PRM_CD_2=P_SIGN_BY_2;
  EXCEPTION
  WHEN OTHERS THEN
    V_ERROR_CD  := -40;
    V_ERROR_MSG := SUBSTR('SELECT SIGN_BY_2 FROM MST_PARAMETER'||SQLERRM(SQLCODE),1,200);
    RAISE V_err;
  END;


  
  FOR I IN 1..P_SEQ_NO.COUNT
  LOOP
  
    BEGIN
      INSERT
      INTO R_RPV_DVP
        (
          CUSTODY_NAME ,
          TGL_SURAT ,
          TRX_SEQ_NO ,
          TRX_TYPE ,
          CTP_NUM ,
          ATTN ,
          NO_SURAT ,
          PHONE_NUM ,
          CUSTODY_FAX_PHONE ,
          BROKER_FAX_PHONE ,
          TRANS_TYPE ,
          BOND_CD ,
          NOMINAL ,
          PRICE ,
          COST ,
          ACCRUED_INT ,
          ACCRUED_INT_TAX ,
          CAPITAL_TAX ,
          NET_AMOUNT ,
          TRX_DATE ,
          VALUE_DT ,
          SR_CUSTODY_CD ,
          LAWAN_CUSTODY_NAME ,
          NAMA_PRSH ,
          NET_AMT_STR ,
          SORTKEY ,
          USER_ID ,
          RAND_VALUE ,
          GENERATE_DATE ,
          SIGN_BY_1 ,
          SIGN_BY_2 ,
          BROKER_CONTACT_PERS ,
          BROKER_PHONE_EXT,
          SIGN_BY_1_POSITION,
          SIGN_BY_2_POSITION
        )
      SELECT c.custody_name,
        TRUNC(SYSDATE) tgl_surat,
        TRX_SEQ_NO,
        TRX_TYPE,
        CTP_NUM,
        c.contact_person AS attn,
        RPAD(trim(SUBSTR( P_NO_SURAT(I),ROWNUM * 7 - 6, 7))
        ||P_SUFFIX_SURAT ,25) AS no_surat,
        p.PHONE_NUM,
        c.fax_num
        ||'/'
        ||c.phone_num AS custody_fax_phone,
        p.FAX_NUM
        ||'/'
        ||p.PHONE_NUM broker_fax_phone,
        DECODE(settlement_instr,'RVP','Receipt Versus Payment','Delivery Versus Payment')
        || DECODE(ctp_num,NULL,'','('
        ||ctp_num
        ||')') AS trans_type,
        BOND_CD,
        NOMINAL,
        PRICE,
        COST,
        ACCRUED_INT,
        ACCRUED_INT_TAX,
        TRUNC(CAPITAL_TAX) capital_tax,
        NET_AMOUNT,
        TRX_DATE,
        VALUE_DT,
        -- c.CUSTODY_NAME,
        c.acct_num
        ||'/'
        ||c.SR_CUSTODY_CD AS sr_custody_cd,
        NVL(d.custody_name,lawan_name)
        ||DECODE(l.lawan_type,'B','',' ifo '
        ||l.lawan_name) lawan_custody_name,
        nama_prsh,
        trim(TO_CHAR(net_amount,'999G999G999G999G999D99')) net_amt_str,
        LPAD(trx_id,3) sortkey,
        P_USER_ID,
        V_RANDOM_VALUE,
        P_GENERATE_DATE,
        V_SIGN_BY_1,
        V_SIGN_BY_2,
        P_BROK_CONT_PERS,
        P_BROK_PHONE_EXT,
        V_SIGN_BY_1_POSITION,
        V_SIGN_BY_2_POSITION
      FROM T_BOND_TRX T,
        MST_LAWAN_BOND_TRX L,
        MST_BANK_CUSTODY c,
        MST_COMPANY p,
        MST_BANK_CUSTODY d
      WHERE t.trx_Date = P_TRX_DATE
      AND t.value_dt   = P_VALUE_DATE
        --  AND INSTR(P_SEQ_NO(I), LPAD(trim(TO_CHAR(t.trx_seq_no)),2)||'*') > 0
      AND T.TRX_SEQ_NO                = P_SEQ_NO(I)
      AND t.lawan                     = l.lawan
      AND t.custodian_Cd              = c.CBEST_CD
      AND NVL(l.custody_cbest_cd,'X') = d.cbest_cd(+) ;
    EXCEPTION
    WHEN OTHERS THEN
      V_ERROR_CD  := -50;
      V_ERROR_MSG := SUBSTR('INSERT R_RPV_DVP '||V_ERROR_MSG||SQLERRM(SQLCODE),1,200);
      RAISE V_err;
    END;
  END LOOP;
  
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
END SPR_RVP_DVP;