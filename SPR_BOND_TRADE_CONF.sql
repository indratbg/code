create or replace 
PROCEDURE SPR_BOND_TRADE_CONF(
  --  P_BGN_DATE      DATE,
   -- P_END_DATE      DATE,
   	vp_doc_num 			DOCNUM_ARRAY,
   -- P_SEQNO         NUMBER,
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
    SP_RPT_REMOVE_RAND('R_BOND_TRADE_CONF',V_RANDOM_VALUE,V_ERROR_MSG,V_ERROR_CD);
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
  
  	FOR i IN 1..vp_doc_num.count LOOP
  BEGIN
    INSERT
    INTO R_BOND_TRADE_CONF
      (
        TRX_TYPE,
        LAWAN_NAME,
        CTP_NUM,
        TRX_DATE,
        TRX_ID,
        TRX_REF,
        FAX,
        CONTACT_PERSON,
        BOND_DESC,
        SELLER,
        BUYER,
        NOMINAL,
        MATURITY_DATE,
        INTEREST,
        PERIOD_FROM,
        PERIOD_TO,
        VALUE_DT,
        PRICE,
        ACCRUED_DAYS,
        PROCEED,
        ACCRUED_INT,
        TOT_PROCEED,
        CAPITAL_TAX,
        ACCRUED_INT_TAX,
        NET_AMOUNT,
        CAPITAL_TAX_PCN,
        DAY_COUNT_BASIS,
        CUSTODY_NAME,
        SECURITIES_ACCT,
        NAMA_PRSH,
        NPWP,
        DIRECTOR,
        JABATAN,
        BUY_PRICE,
        BUY_DT,
        TRX_SEQ_NO,
        PHONE_NUM,
        SELLER_BUY_DT,
        SETTLEMENT_INSTR,
        MULTI_BUY_PRICE,
        USER_ID,
        RAND_VALUE,
        GENERATE_DATE,
        DOC_NUM
      )
    SELECT trx_type,
      lawan_name,
      NVL(ctp_num,'Trade Confirmation') ctp_num,
      trx_date,
      trx_id,
      trx_ref,
      L.fax,
      L.contact_person,
      m. bond_desc,
      DECODE(trx_type,'B',L.lawan_name, nama_prsh) AS seller,
      DECODE(trx_type,'B',nama_prsh,L.lawan_name ) AS buyer,
      nominal,
      m.maturity_date,
      m.interest,
      last_coupon AS period_from,
      next_coupon AS period_to,
      value_dt,
      price,
      accrued_days,
      proceed,
      accrued_int,
      proceed + accrued_int        AS tot_proceed,
              -1 * capital_tax     AS capital_tax,
              -1 * accrued_int_tax AS accrued_int_tax,
      net_amount,
      DECODE(trx_type
      ||L.lawan_type,'SR',0.15,l.capital_tax_pcn) capital_tax_pcn,
      '('
      ||LOWER(m.day_count_basis)
      ||' basis)' day_count_basis,
      DECODE(m.bond_group_cd,'02',swift_code,p.custody_name) custody_name,
      DECODE(m.bond_group_cd,'02','C-BEST-'
      ||kode_ab,p.securities_Acct) securities_Acct,
      nama_prsh,
      no_ijin1 AS npwp,
      s.director,
      s.jabatan,
      buy_price,
      buy_dt,
      trx_seq_no,
      c.phone_num,
      seller_buy_Dt,
      settlement_instr,
      multi_buy_price,
      P_USER_ID,
      V_RANDOM_VALUE,
      P_GENERATE_DATE,
       to_char(trx_date,'yyyymmdd')||trx_seq_no AS DOC_NUM
    FROM
      (SELECT trx_date,
        trx_id,
        bond_cd,
        lawan,
        ctp_num,
        trx_ref,
        trx_type,
        nominal,
        value_dt,
        price,
        accrued_days,
        cost AS proceed,
        accrued_int,
        capital_tax,
        accrued_int_tax,
        net_amount,
        custodian_cd,
        buy_price,
        buy_dt,
        trx_seq_no,
        seller_buy_Dt,
        last_coupon,
        next_coupon,
        settlement_instr,
        sign_by,
        NVL(multi_buy_price,'N') multi_buy_price
      FROM T_BOND_TRX
      WHERE-- trx_date = P_BGN_DATE --AND P_END_DATE
      --AND INSTR(P_SEQNO,LPAD(TO_CHAR(trx_seq_no),4) ) > 0
      --and trx_seq_no = P_SEQNO
      to_char(trx_date,'yyyymmdd')||trx_seq_no =vp_doc_num(i)
      AND APPROVED_STS                               <> 'C'
      ) t,
      MST_LAWAN_BOND_TRX L,
      MST_BOND m,
      (SELECT no_ijin1,
        '021 '
        ||phone_num phone_num,
        SUBSTR(nama_prsh,1,4)
        ||INITCAP(SUBSTR(nama_prsh,5) ) AS nama_prsh
      FROM MST_COMPANY
      ) c,
      (SELECT prm_cd_2 custody_cd,
        prm_desc custody_name,
        SUBSTR(prm_desc2,1,20) AS securities_Acct
      FROM MST_PARAMETER
      WHERE prm_cd_1 = 'CUSTO'
      ) p,
      (SELECT prm_cd_2 SIGN_by,
        INITCAP(prm_desc) director,
        INITCAP(prm_desc2) AS jabatan
      FROM MST_PARAMETER
      WHERE prm_cd_1 = 'SIGNBY'
      ) s,
      (SELECT prm_desc kode_ab,
        prm_desc2 AS swift_code
      FROM MST_PARAMETER
      WHERE prm_cd_1 = 'AB'
      AND prm_cd_2   = '000'
      ) r
    WHERE t.lawan      = L.lawan
    AND t.bond_cd      = m.bond_cd
    AND t.custodian_cd = p.custody_Cd
    AND t.sign_by      = s.sign_by(+)
    ORDER BY trx_date,
      trx_id,
      trx_seq_no ;
  EXCEPTION
  WHEN OTHERS THEN
    V_ERROR_CD  := -30;
    V_ERROR_MSG := SUBSTR('INSERT R_BOND_TRADE_CONF '||V_ERROR_MSG||SQLERRM(SQLCODE),1,200);
    RAISE V_err;
  END;
  
  end loop;
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
END SPR_BOND_TRADE_CONF;