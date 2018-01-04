create or replace 
PROCEDURE SPR_LIST_OF_VCH(
    P_BGN_DATE         DATE,
    P_END_DATE         DATE,
    P_BGN_CLIENT       VARCHAR2,
    P_END_CLIENT       VARCHAR2,
    P_BGN_FOLDER_CD    VARCHAR2,
    P_END_FOLDER_CD    VARCHAR2,
    P_BGN_VOUCHER_TYPE VARCHAR2,
    P_END_VOUCHER_TYPE VARCHAR2,
    P_REPORT_MODE      VARCHAR2,
    P_USER_ID          VARCHAR2,
    P_GENERATE_DATE    DATE,
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

    
   
  IF P_REPORT_MODE='SUMMARY' THEN

    BEGIN
      SP_RPT_REMOVE_RAND('R_LIST_OF_VCH_SUMMARY',V_RANDOM_VALUE,V_ERROR_MSG,V_ERROR_CD);
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
      INTO R_LIST_OF_VCH_SUMMARY
        (
          OLD_IC_NUM ,
          CHQ_NUM ,
          M_NAME ,
          PAYREC_NUM ,
          PAYREC_TYPE ,
          PAYREC_DATE ,
          ACCT_TYPE ,
          SL_ACCT_CD ,
          CURR_CD ,
          CURR_AMT ,
          PAYREC_FRTO ,
          REMARKS ,
          USER_ID ,
          CRE_DT ,
          UPD_DT ,
          APPROVED_STS ,
          APPROVED_BY ,
          APPROVED_DT ,
          GL_ACCT_CD ,
          CLIENT_CD ,
          CHECK_NUM ,
          FOLDER_CD ,
          NUM_CHEQ ,
          CLIENT_BANK_ACCT ,
          CLIENT_BANK_NAME ,
          REVERSAL_JUR ,
          UPD_BY ,
          BGN_DATE ,
          END_DATE ,
          USER_ID_RPT ,
          RAND_VALUE ,
          GENERATEDATE ,
          VOUCHER_TYPE
        )
      SELECT m.old_ic_num,
        NVL(m.client_name, '-') AS m_name,
        q.CHQ_NUM,
        H.PAYREC_NUM ,
        H.PAYREC_TYPE ,
        H.PAYREC_DATE ,
        H.ACCT_TYPE ,
        H.SL_ACCT_CD ,
        H.CURR_CD ,
        H.CURR_AMT ,
        H.PAYREC_FRTO ,
        H.REMARKS ,
        H.USER_ID ,
        H.CRE_DT ,
        H.UPD_DT ,
        H.APPROVED_STS ,
        H.APPROVED_BY ,
        H.APPROVED_DT ,
        H.GL_ACCT_CD ,
        H.CLIENT_CD ,
        H.CHECK_NUM ,
        H.FOLDER_CD ,
        H.NUM_CHEQ ,
        H.CLIENT_BANK_ACCT ,
        H.CLIENT_BANK_NAME ,
        H.REVERSAL_JUR ,
        H.UPD_BY,
        P_BGN_DATE,
        P_END_DATE,
        P_USER_ID,
        V_RANDOM_VALUE,
        P_GENERATE_DATE,
        P_BGN_VOUCHER_TYPE
      FROM t_payrech h,
        mst_client m,
        t_cheq q
      WHERE h.payrec_date BETWEEN P_BGN_DATE AND P_END_DATE
      AND NVL(h.client_cd,'%') BETWEEN P_BGN_CLIENT AND P_END_CLIENT
      AND trim(h.folder_cd) BETWEEN P_BGN_FOLDER_CD AND P_END_FOLDER_CD
    AND SUBSTR(h.payrec_type,1,1) BETWEEN P_BGN_VOUCHER_TYPE AND P_END_VOUCHER_TYPE
      AND NVL(h.client_cd,'@@') = m.client_cd (+)
      AND h.approved_sts       <> 'C'
      AND h.payrec_num          = q.RVPV_NUMBER (+);
    EXCEPTION
    WHEN OTHERS THEN
      V_ERROR_CD  := -50;
      V_ERROR_MSG := SUBSTR('INSERT R_LIST_OF_VCH_SUMMARY '||V_ERROR_MSG||SQLERRM(SQLCODE),1,200);
      RAISE V_err;
    END;
    
  END IF;
  
  IF P_REPORT_MODE='DETAIL' THEN
  
    BEGIN
      SP_RPT_REMOVE_RAND('R_LIST_OF_VCH_DETAIL',V_RANDOM_VALUE,V_ERROR_MSG,V_ERROR_CD);
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
      INTO R_LIST_OF_VCH_DETAIL
        (
          PTYPE ,
          APPROVED_STS ,
          PAYREC_DATE ,
          FOLDER_CD ,
          GRP ,
          CLIENT_CD ,
          CLIENT_NAME ,
          TAL_ID ,
          DOC_DATE ,
          REF_FOLDER_CD ,
          REMARKS ,
          GL_ACCT_CD ,
          SL_ACCT_CD ,
          DB_CR_FLG ,
          PAYREC_AMT ,
          CHQ_NUM ,
          OLD_IC_NUM ,
          M_NAME ,
          BGN_DATE ,
          END_DATE ,
          USER_ID ,
          RAND_VALUE ,
          GENERATEDATE,
          VOUCHER_TYPE
        )
      SELECT T.PTYPE ,
        T.APPROVED_STS ,
        T.PAYREC_DATE ,
        T.FOLDER_CD ,
        T.GRP ,
        T.CLIENT_CD ,
        T.CLIENT_NAME ,
        T.TAL_ID ,
        T.DOC_DATE ,
        T.REF_FOLDER_CD,
        T.REMARKS,
        T.GL_ACCT_CD ,
        T.SL_ACCT_CD ,
        T.DB_CR_FLG ,
        T.PAYREC_AMT ,
        T.CHQ_NUM ,
        m.old_ic_num,
        NVL(m.client_name, t.client_name) AS m_name,
        P_BGN_DATE,
        P_END_DATE,
        P_USER_ID,
        V_RANDOM_VALUE,
        P_GENERATE_DATE,
        P_BGN_VOUCHER_TYPE
      FROM
        (SELECT SUBSTR(h.payrec_num,5,1) AS ptype,
          h.approved_sts,
          h.payrec_date,
          h.folder_Cd,
          1 AS grp,
          h.client_cd,
          ' - ' AS client_name,
          d.tal_id,
          d.doc_date,
          d.ref_folder_cd,
          d.remarks,
          d.gl_acct_cd,
          d.sl_acct_cd,
          d.db_cr_flg,
          d.payrec_amt,
          NULL AS chq_num
        FROM
          (SELECT payrec_num,
            tal_id,
            doc_date,
            gl_acct_cd,
            sl_acct_cd,
            db_cr_flg,
            payrec_amt,
            remarks,
            DECODE(SUBSTR(record_source,2,3),'DUE',SUBSTR(doc_ref_num,8,7), DECODE(record_source,'CG',SUBSTR(doc_ref_num,8,7),ref_folder_cd)) ref_folder_cd
          FROM t_payrecd
          WHERE payrec_date BETWEEN P_BGN_DATE AND P_END_DATE
          AND approved_sts <> 'C'
          ) d,
          t_payrech h
        WHERE h.payrec_date BETWEEN P_BGN_DATE AND P_END_DATE
        AND NVL(h.client_cd,'%') BETWEEN P_BGN_CLIENT AND P_END_CLIENT
        AND trim(h.folder_cd) BETWEEN P_BGN_FOLDER_CD AND P_END_FOLDER_CD
        AND SUBSTR(h.payrec_type,1,1) BETWEEN P_BGN_VOUCHER_TYPE AND P_END_VOUCHER_TYPE
        AND h.payrec_num    = d.payrec_num
        AND h.approved_sts <> 'C'
        UNION ALL
        SELECT SUBSTR(h.payrec_num,5,1) AS ptype,
          h.approved_sts,
          h.payrec_date,
          h.folder_Cd,
          2 AS grp,
          h.client_cd,
          ' - ' AS client_name,
          0,
          c.chq_dt,
          NULL,
          NULL,
          NULL,
          c.sl_acct_cd,
          NULL,
          c.chq_amt,
          c.chq_num
        FROM t_cheq c,
          t_payrech h
        WHERE h.payrec_date BETWEEN P_BGN_DATE AND P_END_DATE
        AND NVL(h.client_cd,'%') BETWEEN P_BGN_CLIENT AND P_END_CLIENT
        AND trim(h.folder_cd) BETWEEN P_BGN_FOLDER_CD AND P_END_FOLDER_CD
        AND SUBSTR(h.payrec_type,1,1)BETWEEN P_BGN_VOUCHER_TYPE AND P_END_VOUCHER_TYPE
        AND h.payrec_num    = c.rvpv_number
        AND h.approved_sts <> 'C'
        ) t,
        mst_client m
      WHERE NVL(t.client_cd,'@@') = m.client_cd (+) ;
    EXCEPTION
    WHEN OTHERS THEN
      V_ERROR_CD  := -50;
      V_ERROR_MSG := SUBSTR('INSERT R_LIST_OF_VCH_DETAIL'||V_ERROR_MSG||SQLERRM(SQLCODE),1,200);
      RAISE V_err;
    END;
    
  END IF;
  

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
END SPR_LIST_OF_VCH;