create or replace PROCEDURE SPR_PPN_KELUARAN(
    P_BGN_DATE DATE,
    P_END_DATE DATE,
    P_MODE     VARCHAR2,--DETAIL/SUMMARY
    P_CLIENT_CD docnum_array,
    P_NO_SERIES     number_array,
    P_NO_SERIES_FLG varchar_array,
    P_PRINT_FLG     VARCHAR2,
    P_USER_ID       VARCHAR2,
    P_GENERATE_DATE DATE,
    P_RANDOM_VALUE OUT NUMBER,
    P_ERROR_CD OUT NUMBER,
    P_ERROR_MSG OUT VARCHAR2 )
AS
  V_ERR          EXCEPTION;
  V_ERROR_CD     NUMBER(5);
  V_ERROR_MSG    VARCHAR2(200);
  V_RANDOM_VALUE NUMBER(10);
  V_BROK_CD      VARCHAR2(5);
BEGIN
  V_RANDOM_VALUE := ABS(DBMS_RANDOM.RANDOM);
  BEGIN
    SELECT BROKER_CD INTO V_BROK_CD FROM V_BROKER_SUBREK;
  EXCEPTION
  WHEN OTHERS THEN
    V_ERROR_CD  := -15;
    V_ERROR_MSG := SUBSTR('SELECT BROKER_CD FROM V_BROKER_SUBREK '||SQLERRM(SQLCODE),1,200);
    RAISE V_err;
  END;
  BEGIN
    SP_RPT_REMOVE_RAND('R_PPN_KELUARAN',V_RANDOM_VALUE,V_ERROR_MSG,V_ERROR_CD);
  EXCEPTION
  WHEN OTHERS THEN
    V_ERROR_CD  := -10;
    V_ERROR_MSG := SUBSTR('SP_RPT_REMOVE_RAND'||V_ERROR_MSG||SQLERRM(SQLCODE),1,200);
    RAISE V_err;
  END;
  IF V_ERROR_CD  <0 THEN
    V_ERROR_CD  := -20;
    V_ERROR_MSG := SUBSTR('SP_RPT_REMOVE_RAND'||V_ERROR_MSG,1,200);
    RAISE V_ERR;
  END IF;
  --------------------SUMMARY---------------------
  IF P_MODE      ='SUMMARY' THEN
    IF V_BROK_CD = 'MU001' AND P_PRINT_FLG = 'Y' THEN --if MU
      FOR i IN 1..P_CLIENT_CD.COUNT
      LOOP
        BEGIN
          INSERT
          INTO R_PPN_KELUARAN
            (
              CLIENT_CD ,
              CLIENT_TYPE_1 ,
              CLIENT_NAME ,
              NPWP_NO ,
              ALAMAT ,
              DPP ,
              PPN ,
              TANGGAL ,
              USER_ID ,
              RAND_VALUE ,
              GENERATE_DATE ,
              BGN_DATE ,
              END_DATE,
              RPT_TYPE,
              AMOUNT,
              NO_SERIES,
              NO_SERIES_FLG,
              BROKER_CD
            )
          SELECT m.client_cd,
            m.CLIENT_TYPE_1,
            client_name,
            DECODE(LENGTH(m.npwp_no),15,F_FORMAT_NPWP(m.npwp_no),m.npwp_no) AS npwp_no,
            DECODE(m.client_type_1,'I', m.addr_ktp, m.addr_corr)            AS alamat,
            t.commission                                                    AS DPP,
            ROUND(t.PPN,0) ppn,
            P_END_DATE AS tanggal,
            P_USER_ID,
            V_RANDOM_VALUE,
            P_GENERATE_DATE,
            P_BGN_DATE,
            P_END_DATE,
            P_MODE,
            NULL,
            P_NO_SERIES(I),
            P_NO_SERIES_FLG(I),
            V_BROK_CD
          FROM
            (SELECT client_cd,
              SUM(curr_val) PPN,
              SUM(COMMISSION) Commission
            FROM
              (SELECT client_cd,
                t.curr_val,
                c.COMMISSION
              FROM
                (SELECT client_cd,
                  commission,
                  DECODE(SUBSTR(contr_num,6,1), 'I',SUBSTR(contr_num,1,6)
                  ||'0'
                  ||SUBSTR(contr_num,8,7),contr_num) contr_num
                FROM T_CONTRACTS
                WHERE contr_dt BETWEEN P_BGN_DATE AND P_END_DATE
                AND SUBSTR(contr_num,5,3) <> 'BIJ'
                AND SUBSTR(contr_num,5,3) <> 'JIB'
                AND contr_stat            <> 'C'
                ) c,
                T_ACCOUNT_LEDGER t
              WHERE t.doc_date BETWEEN P_BGN_DATE AND P_END_DATE
              AND trim(t.gl_acct_cd) = '2523'
              AND t.approved_sts    <> 'C'
              AND t.xn_doc_num       = c.CONTR_NUM
              UNION ALL
              SELECT c.client_cd,
                DECODE(trim(t.gl_acct_cd),'2523',t.curr_val,0),
                DECODE(trim(t.gl_acct_cd),'6100',t.curr_val,0)
              FROM
                (SELECT xn_doc_num,
                  sl_acct_cd AS client_cd
                FROM T_ACCOUNT_LEDGER
                WHERE doc_date BETWEEN P_BGN_DATE AND P_END_DATE
                AND SUBSTR(xn_doc_num,8,3) = 'MFE'
                AND approved_sts          <> 'C'
                AND reversal_jur           = 'N'
                AND record_source         <> 'RE'
                AND tal_id                 = 1
                ) c,
                T_ACCOUNT_LEDGER t
              WHERE t.doc_date BETWEEN P_BGN_DATE AND P_END_DATE
              AND trim(t.gl_acct_cd) IN ('2523','6100')
              AND t.xn_doc_num        = c.xn_doc_NUM
              )
            GROUP BY client_cd
            ) t,
            (SELECT m.client_cd,
              f.cif_name AS client_name,
              f.npwp_no,
              f.client_type_1,
              trim(m.def_addr_1)
              ||' '
              ||trim(m.def_addr_2)
              ||' '
              ||trim(m.def_addr_3)
              ||' '
              ||trim(m.post_cd)
              ||' '
              ||m.DEF_CITY addr_corr,
              trim(i.id_addr)
              ||' '
              ||trim(i.id_rtrw)
              ||' '
              ||DECODE(i.id_klurahn,NULL,'','Kel.'
              ||trim(i.id_klurahn))
              ||' '
              || DECODE(i.id_kcamatn,NULL,'','Kec.'
              ||trim(i.id_kcamatn))
              ||' '
              ||trim(id_kota)
              ||' '
              ||trim(id_post_Cd) AS addr_ktp
            FROM mst_client m,
              mst_cif f,
              mst_client_indi i
            WHERE m.cifs = f.cifs(+)
            AND m.cifs   = i.cifs(+)
            ) m
          WHERE t.client_cd = m.client_cd
          AND T.CLIENT_CD   = P_CLIENT_CD(I);
        EXCEPTION
        WHEN OTHERS THEN
          V_ERROR_CD  := -25;
          V_ERROR_MSG := SUBSTR('INSERT R_PPN_KELUARAN'||SQLERRM(SQLCODE),1,200);
          RAISE V_err;
        END;
      END LOOP;
    END IF;
    IF (V_BROK_CD = 'MU001' AND P_PRINT_FLG = 'N') OR (P_PRINT_FLG = 'Y' AND V_BROK_CD <> 'MU001' ) THEN
      BEGIN
        INSERT
        INTO R_PPN_KELUARAN
          (
            CLIENT_CD ,
            CLIENT_TYPE_1 ,
            CLIENT_NAME ,
            NPWP_NO ,
            ALAMAT ,
            DPP ,
            PPN ,
            TANGGAL ,
            USER_ID ,
            RAND_VALUE ,
            GENERATE_DATE ,
            BGN_DATE ,
            END_DATE,
            RPT_TYPE,
            BROKER_CD
          )
        SELECT 'TXT' CLIENT_CD,
          NULL,
          NULL,
          NULL,
          NULL,
          NULL,
          NULL,
          NULL,
          P_USER_ID,
          V_RANDOM_VALUE,
          P_GENERATE_DATE,
          P_BGN_DATE,
          P_END_DATE,
          P_MODE,
          V_BROK_CD
        FROM DUAL
        UNION ALL
        SELECT m.client_cd,
          m.CLIENT_TYPE_1,
          client_name,
          DECODE(LENGTH(m.npwp_no),15,F_FORMAT_NPWP(m.npwp_no),m.npwp_no) AS npwp_no,
          DECODE(m.client_type_1,'I', m.addr_ktp, m.addr_corr)            AS alamat,
          t.commission                                                    AS DPP,
          ROUND(t.PPN,0) ppn,
          P_END_DATE AS tanggal,
          P_USER_ID,
          V_RANDOM_VALUE,
          P_GENERATE_DATE,
          P_BGN_DATE,
          P_END_DATE,
          P_MODE,
          V_BROK_CD
        FROM
          (SELECT client_cd,
            SUM(curr_val) PPN,
            SUM(COMMISSION) Commission
          FROM
            (SELECT client_cd,
              t.curr_val,
              c.COMMISSION
            FROM
              (SELECT client_cd,
                commission,
                DECODE(SUBSTR(contr_num,6,1), 'I',SUBSTR(contr_num,1,6)
                ||'0'
                ||SUBSTR(contr_num,8,7),contr_num) contr_num
              FROM T_CONTRACTS
              WHERE contr_dt BETWEEN P_BGN_DATE AND P_END_DATE
              AND SUBSTR(contr_num,5,3) <> 'BIJ'
              AND SUBSTR(contr_num,5,3) <> 'JIB'
              AND contr_stat            <> 'C'
              ) c,
              T_ACCOUNT_LEDGER t
            WHERE t.doc_date BETWEEN P_BGN_DATE AND P_END_DATE
            AND trim(t.gl_acct_cd) = '2523'
            AND t.approved_sts    <> 'C'
            AND t.xn_doc_num       = c.CONTR_NUM
            UNION ALL
            SELECT c.client_cd,
              DECODE(trim(t.gl_acct_cd),'2523',t.curr_val,0),
              DECODE(trim(t.gl_acct_cd),'6100',t.curr_val,0)
            FROM
              (SELECT xn_doc_num,
                sl_acct_cd AS client_cd
              FROM T_ACCOUNT_LEDGER
              WHERE doc_date BETWEEN P_BGN_DATE AND P_END_DATE
              AND SUBSTR(xn_doc_num,8,3) = 'MFE'
              AND approved_sts          <> 'C'
              AND reversal_jur           = 'N'
              AND record_source         <> 'RE'
              AND tal_id                 = 1
              ) c,
              T_ACCOUNT_LEDGER t
            WHERE t.doc_date BETWEEN P_BGN_DATE AND P_END_DATE
            AND trim(t.gl_acct_cd) IN ('2523','6100')
            AND t.xn_doc_num        = c.xn_doc_NUM
            )
          GROUP BY client_cd
          ) t,
          (SELECT m.client_cd,
            f.cif_name AS client_name,
            f.npwp_no,
            f.client_type_1,
            trim(m.def_addr_1)
            ||' '
            ||trim(m.def_addr_2)
            ||' '
            ||trim(m.def_addr_3)
            ||' '
            ||trim(m.post_cd)
            ||' '
            ||m.DEF_CITY addr_corr,
            trim(i.id_addr)
            ||' '
            ||trim(i.id_rtrw)
            ||' '
            ||DECODE(i.id_klurahn,NULL,'','Kel.'
            ||trim(i.id_klurahn))
            ||' '
            || DECODE(i.id_kcamatn,NULL,'','Kec.'
            ||trim(i.id_kcamatn))
            ||' '
            ||trim(id_kota)
            ||' '
            ||trim(id_post_Cd) AS addr_ktp
          FROM mst_client m,
            mst_cif f,
            mst_client_indi i
          WHERE m.cifs = f.cifs(+)
          AND m.cifs   = i.cifs(+)
          ) m
        WHERE t.client_cd = m.client_cd;
      EXCEPTION
      WHEN OTHERS THEN
        V_ERROR_CD  :=-30;
        V_ERROR_MSG :=SUBSTR('INSERT INTO R_PPN_KELUARAN '||SQLERRM,1,200);
        RAISE V_ERR;
      END;
    END IF;
  END IF;
  --------------------END SUMMARY----------------------
  ------------------DETAIL-------------------------
  IF P_MODE='DETAIL' THEN
    BEGIN
      INSERT
      INTO R_PPN_KELUARAN
        (
          CLIENT_CD ,
          CLIENT_TYPE_1 ,
          CLIENT_NAME ,
          NPWP_NO ,
          ALAMAT ,
          DPP ,
          PPN ,
          TANGGAL ,
          USER_ID ,
          RAND_VALUE ,
          GENERATE_DATE ,
          BGN_DATE ,
          END_DATE ,
          RPT_TYPE ,
          AMOUNT,
          BROKER_CD
        )
      SELECT 'TXT' CLIENT_CD,
        NULL,
        NULL,
        NULL,
        NULL,
        NULL,
        NULL,
        NULL,
        P_USER_ID,
        V_RANDOM_VALUE,
        P_GENERATE_DATE,
        P_BGN_DATE,
        P_END_DATE,
        P_MODE,
        NULL,
        V_BROK_CD
      FROM DUAL
      UNION ALL
      SELECT c.client_cd,
        NULL,
        m.client_name,
        NULL npwp_no,
        NULL ALAMAT,
        NULL DPP,
        NULL PPN,
        t.doc_date,
        P_USER_ID,
        V_RANDOM_VALUE,
        P_GENERATE_DATE,
        P_BGN_DATE,
        P_END_DATE,
        P_MODE,
        t.curr_val Amount,
        V_BROK_CD
      FROM
        (SELECT client_cd,
          DECODE(SUBSTR(contr_num,6,1), 'I',SUBSTR(contr_num,1,6)
          ||'0'
          ||SUBSTR(contr_num,8,7),contr_num) contr_num
        FROM t_contracts
        WHERE contr_dt BETWEEN P_BGN_DATE AND P_END_DATE
        AND SUBSTR(contr_num,5,3) <> 'BIJ'
        AND SUBSTR(contr_num,5,3) <> 'JIB'
        AND contr_stat            <> 'C'
        ) c,
        t_account_ledger t,
        mst_client m
      WHERE t.doc_date BETWEEN P_BGN_DATE AND P_END_DATE
      AND t.gl_acct_cd    = '2523'
      AND t.record_source = 'CG'
      AND t.approved_sts  = 'A'
      AND t.xn_doc_num    = c.CONTR_NUM
      AND c.client_cd     = m.client_cd
      ORDER BY c.client_cd,
        t.doc_date;
    EXCEPTION
    WHEN OTHERS THEN
      V_ERROR_CD  :=-40;
      V_ERROR_MSG :=SUBSTR('INSERT INTO R_PPN_KELUARAN '||SQLERRM,1,200);
      RAISE V_ERR;
    END;
  END IF;
  ------------------END DETAIL-------------------------
  P_RANDOM_VALUE := v_random_value;
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
END SPR_PPN_KELUARAN;