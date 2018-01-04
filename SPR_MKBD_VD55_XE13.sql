create or replace 
PROCEDURE SPR_MKBD_VD55_XE13(
    P_END_DATE      DATE,
    P_USER_ID       VARCHAR2,
    P_GENERATE_DATE DATE,
    P_RANDOM_VALUE OUT NUMBER,
    P_ERROR_CD OUT NUMBER,
    P_ERROR_MSG OUT VARCHAR2 )
AS
  V_ERR           EXCEPTION;
  V_ERROR_CD      NUMBER(5);
  V_ERROR_MSG     VARCHAR2(200);
  V_RANDOM_VALUE  NUMBER(10);
  V_BGN_DATE      DATE;
  V_COY_CLIENT_cD VARCHAR2(12);
BEGIN

  V_RANDOM_VALUE := ABS(DBMS_RANDOM.RANDOM);
  
  BEGIN
    SP_RPT_REMOVE_RAND('R_MKBD_VD55_XE13',V_RANDOM_VALUE,V_ERROR_MSG,V_ERROR_CD);
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

  V_BGN_DATE := P_END_DATE - TO_CHAR(P_END_DATE,'DD')+1;
  
  BEGIN
    SELECT TRIM(OTHER_1) INTO V_COY_CLIENT_cD FROM mst_company;
  EXCEPTION
  WHEN OTHERS THEN
    V_ERROR_CD  := -30;
    V_ERROR_MSG := SUBSTR('SELECT V_COY_CLIENT_cD FROM mst_company '||SQLERRM(SQLCODE),1,200);
    RAISE V_err;
  END;
  
  BEGIN
    INSERT
    INTO R_MKBD_VD55_XE13
      (
        MKBD_CD ,
        DESCRIPTION ,
        SUM_AMT ,
        AFFIL_F ,
        AFFIL_L ,
        NONAFFIL_F ,
        NONAFFIL_L ,
        TANGGAL ,
        QTY1 ,
        QTY2 ,
        TOT_QTY ,
        TXT0 ,
        TXT1 ,
        TXT2 ,
        TXT3 ,
        TXT4 ,
        TXT5 ,
        TXT6 ,
        TXT7 ,
        X1 ,
        X2 ,
        X3 ,
        X4 ,
        XEND ,
        RAND_VALUE ,
        USER_ID ,
        GENERATE_DATE
      )
    SELECT L.mkbd_cd,
      initcap(l.description),
      NVL(d.sum_amt,0) sum_amt,
      NVL(d.affil_f,0) affil_f,
      NVL(d.affil_l,0) affil_l,
      NVL(d.nonaffil_f, 0) nonaffil_f,
      NVL(d.nonaffil_l, 0) nonaffil_l,
      e.tanggal,
      e.qty1,
      e.qty2,
      e.qty1 + e.qty2 AS tot_qty,
      f.txt0,
      f.txt1,
      f.txt2,
      f.txt3,
      f.txt4,
      f.txt5,
      f.txt6,
      f.txt7,
      1184 x1,
      1358 x2,
      1842 x3,
      2386 x4,
      2944 xend,
      V_RANDOM_VALUE,
      P_USER_ID,
      P_GENERATE_DATE
    FROM
      (SELECT '  7' AS line_cd,
        SUM(NVL(T.VAL,0)) sum_amt,
        SUM(DECODE(NVL(m.cust_client_flg,'N'),'A',1,0) * DECODE(m.client_type_2,'F',1,0) * NVL(T.VAL,0)) AFFIL_F,
        SUM(DECODE(NVL(m.cust_client_flg,'N'),'A',1,0) * DECODE(m.client_type_2,'F',0,1) * NVL(T.VAL,0)) AFFIL_L,
        SUM(DECODE(NVL(m.cust_client_flg,'N'),'A',0,1) * DECODE(m.client_type_2,'F',1,0) * NVL(T.VAL,0)) NONAFFIL_F,
        SUM(DECODE(NVL(m.cust_client_flg,'N'),'A',0,1) * DECODE(m.client_type_2,'F',0,1) * NVL(T.VAL,0)) NONAFFIL_L
      FROM T_CONTRACTS T,
        (SELECT mst_client.client_Cd,
          NVL(mst_cif.client_type_2,mst_client.client_type_2) client_type_2,
          DECODE(t_client_afiliasi.client_Cd,NULL,'N','A') cust_client_flg
        FROM MST_CLIENT,
          MST_CIF,
          (SELECT client_cd
          FROM T_CLIENT_AFILIASI
          WHERE P_END_DATE BETWEEN from_dt AND to_dt
          ) T_CLIENT_AFILIASI
        WHERE mst_client.cifs    = mst_cif.cifs(+)
        AND mst_client.client_cd = T_CLIENT_AFILIASI.client_cd(+)
        ) M
      WHERE SUBSTR(TRIM(T.CONTR_NUM),5,3) IN ('BR0','BIB')
      AND T.CONTR_DT BETWEEN V_BGN_DATE AND P_END_DATE
      AND T.CONTR_STAT              <> 'C'
      AND T.CLIENT_CD               <> V_COY_CLIENT_cD
      AND SUBSTR(T.client_type,1,1) <> 'H'
      AND T.CLIENT_CD                = M.CLIENT_CD
      UNION ALL
      SELECT '10',
        SUM(NVL(T.VAL,0)) sum_amt,
        0 AFFIL_F,
        0 AFFIL_L,
        0 NONAFFIL_F,
        0 NONAFFIL_L
      FROM T_CONTRACTS T,
        MST_CLIENT M
      WHERE SUBSTR(TRIM(T.CONTR_NUM),5,3) = 'BR0'
      AND T.CONTR_DT BETWEEN V_BGN_DATE AND P_END_DATE
      AND T.CONTR_STAT            <> 'C'
      AND (T.CLIENT_CD             = V_COY_CLIENT_cD
      OR SUBSTR(T.client_type,1,1) = 'H')
      AND T.CLIENT_CD              = M.CLIENT_CD
      UNION ALL
      SELECT '11',
        SUM(NVL(T.VAL,0)) sum_amt,
        SUM(DECODE(NVL(m.cust_client_flg,'N'),'A',1,0) * DECODE(m.client_type_2,'F',1,0) * NVL(T.VAL,0)) AFFIL_F,
        SUM(DECODE(NVL(m.cust_client_flg,'N'),'A',1,0) * DECODE(m.client_type_2,'F',0,1) * NVL(T.VAL,0)) AFFIL_L,
        SUM(DECODE(NVL(m.cust_client_flg,'N'),'A',0,1) * DECODE(m.client_type_2,'F',1,0) * NVL(T.VAL,0)) NONAFFIL_F,
        SUM(DECODE(NVL(m.cust_client_flg,'N'),'A',0,1) * DECODE(m.client_type_2,'F',0,1) * NVL(T.VAL,0)) NONAFFIL_L
      FROM T_CONTRACTS T,
        (SELECT mst_client.client_Cd,
          NVL(mst_cif.client_type_2,mst_client.client_type_2) client_type_2,
          DECODE(t_client_afiliasi.client_Cd,NULL,'N','A') cust_client_flg
        FROM MST_CLIENT,
          MST_CIF,
          (SELECT client_cd
          FROM T_CLIENT_AFILIASI
          WHERE P_END_DATE BETWEEN from_dt AND to_dt
          ) T_CLIENT_AFILIASI
        WHERE mst_client.cifs    = mst_cif.cifs(+)
        AND mst_client.client_cd = T_CLIENT_AFILIASI.client_cd(+)
        ) M
      WHERE SUBSTR(TRIM(T.CONTR_NUM),5,3) IN ('JR0','JIJ')
      AND T.CONTR_DT BETWEEN V_BGN_DATE AND P_END_DATE
      AND T.CONTR_STAT              <> 'C'
      AND T.CLIENT_CD               <> V_COY_CLIENT_cD
      AND SUBSTR(T.client_type,1,1) <> 'H'
      AND T.CLIENT_CD                = M.CLIENT_CD
      UNION ALL
      SELECT '13',
        SUM(NVL(T.VAL,0)) sum_amt,
        0 AFFIL_F,
        0 AFFIL_L,
        0 NONAFFIL_F,
        0 NONAFFIL_L
      FROM T_CONTRACTS T,
        MST_CLIENT M
      WHERE SUBSTR(TRIM(T.CONTR_NUM),5,3) = 'JR0'
      AND T.CONTR_DT BETWEEN V_BGN_DATE AND P_END_DATE
      AND T.CONTR_STAT            <> 'C'
      AND (T.CLIENT_CD             = V_COY_CLIENT_cD
      OR SUBSTR(T.client_type,1,1) = 'H')
      AND T.CLIENT_CD              = M.CLIENT_CD
      UNION ALL
      SELECT '14',
        SUM(sum_amt) sum_amt,
        SUM( AFFIL_F) AFFIL_F,
        SUM( AFFIL_L) AFFIL_L,
        SUM( NONAFFIL_F) NONAFFIL_F,
        SUM( NONAFFIL_L) NONAFFIL_L
      FROM
        (SELECT SUM(NVL(T.VAL,0)) sum_amt,
          SUM( DECODE(NVL(m.cust_client_flg,'N'),'A',1,0) * DECODE(m.client_type_2,'F',1,0) * NVL(T.VAL,0)) AFFIL_F,
          SUM(DECODE(NVL(m.cust_client_flg,'N'),'A',1,0)  * DECODE(m.client_type_2,'F',0,1) * NVL(T.VAL,0)) AFFIL_L,
          SUM(DECODE(NVL(m.cust_client_flg,'N'),'A',0,1)  * DECODE(m.client_type_2,'F',1,0) * NVL(T.VAL,0)) NONAFFIL_F,
          SUM(DECODE(NVL(m.cust_client_flg,'N'),'A',0,1)  * DECODE(m.client_type_2,'F',0,1) * NVL(T.VAL,0)) NONAFFIL_L
        FROM T_CONTRACTS T,
          (SELECT mst_client.client_Cd,
            NVL(mst_cif.client_type_2,mst_client.client_type_2) client_type_2,
            DECODE(t_client_afiliasi.client_Cd,NULL,'N','A') cust_client_flg
          FROM MST_CLIENT,
            MST_CIF,
            (SELECT client_cd
            FROM T_CLIENT_AFILIASI
            WHERE P_END_DATE BETWEEN from_dt AND to_dt
            ) T_CLIENT_AFILIASI
          WHERE mst_client.cifs    = mst_cif.cifs(+)
          AND mst_client.client_cd = T_CLIENT_AFILIASI.client_cd(+)
          ) M
        WHERE SUBSTR(T.CONTR_NUM,6,1) = 'R'
        AND T.CONTR_DT BETWEEN V_BGN_DATE AND P_END_DATE
        AND T.CONTR_STAT              <> 'C'
        AND T.CLIENT_CD               <> V_COY_CLIENT_cD
        AND SUBSTR(T.client_type,1,1) <> 'H'
        AND T.CLIENT_CD                = M.CLIENT_CD
       --REQUEST BY INDRA MU 08NOV
       /*
        UNION ALL
        SELECT SUM(NVL(T.VAL,0)) sum_amt,
          0 AFFIL_F,
          0 AFFIL_L,
          0 NONAFFIL_F,
          0 NONAFFIL_L
        FROM T_CONTRACTS T,
          MST_CLIENT M
        WHERE SUBSTR(T.CONTR_NUM,6,1) = 'R'
        AND T.CONTR_DT BETWEEN V_BGN_DATE AND P_END_DATE
        AND T.CONTR_STAT            <> 'C'
        AND (T.CLIENT_CD             = V_COY_CLIENT_cD
        OR SUBSTR(T.client_type,1,1) = 'H')
        AND T.CLIENT_CD              = M.CLIENT_CD
        */
        )
      UNION ALL
      SELECT '15',
        SUM(NVL(T.VAL,0)) sum_amt,
        SUM(DECODE(NVL(m.cust_client_flg,'N'),'A',1,0) * DECODE(m.client_type_2,'F',1,0) * NVL(T.VAL,0)) AFFIL_F,
        SUM(DECODE(NVL(m.cust_client_flg,'N'),'A',1,0) * DECODE(m.client_type_2,'F',0,1) * NVL(T.VAL,0)) AFFIL_L,
        SUM(DECODE(NVL(m.cust_client_flg,'N'),'A',0,1) * DECODE(m.client_type_2,'F',1,0) * NVL(T.VAL,0)) NONAFFIL_F,
        SUM(DECODE(NVL(m.cust_client_flg,'N'),'A',0,1) * DECODE(m.client_type_2,'F',0,1) * NVL(T.VAL,0)) NONAFFIL_L
      FROM T_CONTRACTS T,
        (SELECT mst_client.client_Cd,
          NVL(mst_cif.client_type_2,mst_client.client_type_2) client_type_2,
          DECODE(t_client_afiliasi.client_Cd,NULL,'N','A') cust_client_flg
        FROM MST_CLIENT,
          MST_CIF,
          (SELECT client_cd
          FROM T_CLIENT_AFILIASI
          WHERE P_END_DATE BETWEEN from_dt AND to_dt
          ) T_CLIENT_AFILIASI
        WHERE mst_client.cifs    = mst_cif.cifs(+)
        AND mst_client.client_cd = T_CLIENT_AFILIASI.client_cd(+)
        ) M
      WHERE T.CONTR_DT BETWEEN V_BGN_DATE AND P_END_DATE
      AND T.CONTR_STAT   <> 'C'
      AND T.CLIENT_CD     = M.CLIENT_CD
      AND t.record_source = 'IC'
      UNION ALL
      SELECT '16',
        COUNT( subrek001) ,
        SUM(DECODE(client_type_2
        ||afil,'FA',1,0)) F_afil,
        SUM(DECODE(client_type_2
        ||afil,'LA',1,0)) L_afil,
        SUM(DECODE(client_type_2
        ||afil,'FN',1,0)) F_non_afil,
        SUM(DECODE(client_type_2
        ||afil,'LN',1,0)) L_non_afil
      FROM
        ( SELECT DISTINCT subrek001,
          DECODE(a.client_cd, NULL,'N','A') afil,
          client_type_2
        FROM
          (SELECT v.subrek001,
            v.client_cd,
            ms.client_type_2
          FROM v_client_subrek14 v,
            mst_client_rekefek m,
            v_broker_subrek b,
            mst_client ms
          WHERE v.subrek001  = m.SUBREK_CD
          AND( m.close_date IS NULL
          OR m.close_date    > P_END_DATE)
          AND m.open_date   <= P_END_DATE
          AND subrek001     <> b.BROKER_001
          AND v.client_cd    = ms.client_cd
          ) s,
          (SELECT CLIENT_CD
          FROM t_client_afiliasi
          WHERE P_END_DATE BETWEEN from_dt AND to_dt
          ) a
        WHERE s.client_cd = a.client_cd(+)
        )
      UNION ALL
      SELECT '17',
        COUNT(DISTINCT subrek001),
        COUNT(DISTINCT affil_f),
        COUNT(DISTINCT affil_l),
        COUNT(DISTINCT nonaffil_f),
        COUNT(DISTINCT nonaffil_l)
      FROM
        (SELECT m.client_cd,
          subrek001,
          DECODE(m.cust_client_flg,'A',DECODE(m.client_type_2,'F',m.subrek001,NULL),NULL) affil_f,
          DECODE(m.cust_client_flg,'A',DECODE(m.client_type_2,'F',NULL,m.subrek001),NULL) affil_l,
          DECODE(m.cust_client_flg,'A',NULL,DECODE(m.client_type_2,'F',m.subrek001,NULL)) nonaffil_f,
          DECODE(m.cust_client_flg,'A',NULL,DECODE(m.client_type_2,'F',NULL,m.subrek001)) nonaffil_l
        FROM
          (SELECT client_cd,
            subrek001,
            cust_client_flg,
            client_type_2,
            SUM(bal) AS endbal
          FROM
            (SELECT trim(a.sl_acct_cd) client_cd,
              v.subrek001,
              c.cust_client_flg,
              c.client_type_2,
              DECODE(a.db_cr_flg,'D',1,-1) * NVL(a.curr_val,0) bal
            FROM T_ACCOUNT_LEDGER a,
              v_client_subrek14 v,
              (SELECT mst_client.client_Cd,
                NVL(mst_cif.client_type_2,mst_client.client_type_2) client_type_2,
                DECODE(t_client_afiliasi.client_Cd,NULL,'N','A') cust_client_flg,
                client_type_3,
                agreement_no,
                acct_open_dt
              FROM MST_CLIENT,
                MST_CIF,
                (SELECT client_cd
                FROM T_CLIENT_AFILIASI
                WHERE P_END_DATE BETWEEN from_dt AND to_dt
                ) T_CLIENT_AFILIASI
              WHERE mst_client.cifs    = mst_cif.cifs(+)
              AND mst_client.client_cd = T_CLIENT_AFILIASI.client_cd(+)
              ) C
            WHERE (a.doc_date  <= P_END_DATE
            AND a.doc_date     >= V_BGN_DATE)
            AND a.approved_sts <> 'C'
            AND a.approved_sts <> 'E'
            AND a.sl_acct_cd    = c.client_cd
            AND a.sl_acct_cd    = v.client_cd (+)
            AND v.subrek001    IS NOT NULL
            UNION ALL
            SELECT trim(d.sl_acct_cd) client_cd,
              v.subrek001,
              c.cust_client_flg,
              c.client_type_2,
              NVL(d.deb_obal,0) - NVL(d.cre_obal,0) obal
            FROM T_DAY_TRS d,
              v_client_subrek14 v,
              (SELECT mst_client.client_Cd,
                NVL(mst_cif.client_type_2,mst_client.client_type_2) client_type_2,
                DECODE(t_client_afiliasi.client_Cd,NULL,'N','A') cust_client_flg,
                client_type_3,
                agreement_no,
                acct_open_dt
              FROM MST_CLIENT,
                MST_CIF,
                (SELECT client_cd
                FROM T_CLIENT_AFILIASI
                WHERE P_END_DATE BETWEEN from_dt AND to_dt
                ) T_CLIENT_AFILIASI
              WHERE mst_client.cifs    = mst_cif.cifs(+)
              AND mst_client.client_cd = T_CLIENT_AFILIASI.client_cd(+)
              ) C
            WHERE d.trs_dt   = V_BGN_DATE
            AND d.sl_acct_cd = c.client_cd
            AND d.sl_acct_cd = v.client_cd (+)
            AND v.subrek001 IS NOT NULL
            )
          GROUP BY client_cd,
            subrek001,
            cust_client_flg,
            client_type_2
          HAVING SUM(bal) > 0
          ) m
        )
      UNION ALL
      SELECT '19',
        COUNT(1) sum_amt,
        SUM(DECODE(NVL(m.cust_client_flg,'N'),'A',1,0) * DECODE(m.client_type_2,'F',1,0) * 1) AFFIL_F,
        SUM(DECODE(NVL(m.cust_client_flg,'N'),'A',1,0) * DECODE(m.client_type_2,'F',0,1) * 1) AFFIL_L,
        SUM(DECODE(NVL(m.cust_client_flg,'N'),'A',0,1) * DECODE(m.client_type_2,'F',1,0) * 1) NONAFFIL_F,
        SUM(DECODE(NVL(m.cust_client_flg,'N'),'A',0,1) * DECODE(m.client_type_2,'F',0,1) * 1) NONAFFIL_L
      FROM T_DTL_EXCHANGE T,
        (SELECT mst_client.client_Cd,
          NVL(mst_cif.client_type_2,mst_client.client_type_2) client_type_2,
          DECODE(t_client_afiliasi.client_Cd,NULL,'N','A') cust_client_flg,
          client_type_3,
          agreement_no,
          acct_open_dt,
          mst_cif.client_type_1
        FROM MST_CLIENT,
          MST_CIF,
          (SELECT client_cd
          FROM T_CLIENT_AFILIASI
          WHERE P_END_DATE BETWEEN from_dt AND to_dt
          ) T_CLIENT_AFILIASI
        WHERE mst_client.cifs    = mst_cif.cifs(+)
        AND mst_client.client_cd = T_CLIENT_AFILIASI.client_cd(+)
        ) M
      WHERE T.TRDG_DT BETWEEN V_BGN_DATE AND P_END_DATE
      AND t.END_CLIENT_CD <> V_COY_CLIENT_cD
      AND t.end_client_cd  = M.client_cd
      AND m.client_type_1 <> 'H'
      UNION ALL
      SELECT '20',
        COUNT(1) sum_amt,
        SUM(DECODE(NVL(m.cust_client_flg,'N'),'A',1,0) * DECODE(m.client_type_2,'F',1,0) * 1) AFFIL_F,
        SUM(DECODE(NVL(m.cust_client_flg,'N'),'A',1,0) * DECODE(m.client_type_2,'F',0,1) * 1) AFFIL_L,
        SUM(DECODE(NVL(m.cust_client_flg,'N'),'A',0,1) * DECODE(m.client_type_2,'F',1,0) * 1) NONAFFIL_F,
        SUM(DECODE(NVL(m.cust_client_flg,'N'),'A',0,1) * DECODE(m.client_type_2,'F',0,1) * 1) NONAFFIL_L
      FROM T_DTL_EXCHANGE T,
        MST_CLIENT M
      WHERE t.TRDG_DT BETWEEN V_BGN_DATE AND P_END_DATE
      AND t.end_client_cd  = M.client_cd
      AND (t.END_CLIENT_CD = V_COY_CLIENT_cD
      OR m.client_type_1   = 'H')
      ) D,
      (SELECT MKBD_CD,
        tanggal,
        qty1,
        qty2
      FROM T_VD55
      WHERE mkbd_date = P_END_DATE
      ) E,
      (SELECT '  2' mkbd_cd,
        nama_prsh AS txt0,
        NULL txt1,
        NULL txt2,
        NULL txt3,
        NULL txt4,
        NULL txt5,
        NULL txt6,
        NULL txt7
      FROM mst_company
      UNION
      SELECT '  3' mkbd_cd,
        TO_CHAR(P_END_DATE,'dd/mm/yy') AS txt0,
        NULL                           AS txt1,
        NULL txt2,
        NULL txt3,
        NULL txt4,
        NULL txt5,
        NULL txt6,
        NULL txt7
      FROM dual
      UNION
      SELECT '  4' mkbd_cd,
        contact_pers AS txt0,
        NULL         AS txt1,
        NULL txt2,
        NULL txt3,
        NULL txt4,
        NULL txt5,
        NULL txt6,
        NULL txt7
      FROM mst_company
      UNION
      SELECT '  5' mkbd_cd,
        NULL,
        'Terafiliasi' txt1,
        'Tidak Terafiliasi' txt2,
        'Total' AS txt3,
        NULL txt4,
        NULL txt5,
        NULL txt6,
        NULL txt7
      FROM dual
      UNION
      SELECT '  6' mkbd_cd,
        NULL,
        NULL txt1,
        NULL txt2,
        NULL txt3,
        'Asing' txt4,
        'Domestik' txt5,
        'Asing' txt6,
        'Domestik' txt7
      FROM dual
      UNION
      SELECT '25' mkbd_cd,
        NULL,
        NULL txt1,
        NULL txt2,
        'Total' txt3,
        NULL txt4,
        NULL txt5,
        'Berizin' txt6,
        'Tidak Berizin' txt7
      FROM dual
      UNION
      SELECT '36' mkbd_cd,
        NULL,
        NULL txt1,
        NULL txt2,
        'Total' txt3,
        NULL txt4,
        NULL txt5,
        'Keluar' txt6,
        'Masuk' txt7
      FROM dual
      UNION
      SELECT '40' mkbd_cd,
        NULL,
        NULL txt1,
        NULL txt2,
        NULL txt3,
        'Tanggal' txt4,
        NULL txt5,
        NULL txt6,
        NULL txt7
      FROM dual
      UNION
      SELECT '45' mkbd_cd,
        NULL,
        NULL txt1,
        NULL txt2,
        'Total' txt3,
        NULL txt4,
        NULL txt5,
        'Diselesaikan' txt6,
        'Belum Diselesaikan' txt7
      FROM dual
      ) F,
      ( SELECT * FROM LST_MKBD WHERE versi = 'Nov12' AND source = 'VD55'
      ) L
    WHERE d.line_cd (+) = l.mkbd_cd
    AND f.mkbd_cd (+)   = l.mkbd_cd
    AND e.mkbd_cd (+)   = l.mkbd_cd ;
  EXCEPTION
  WHEN OTHERS THEN
    V_ERROR_CD  := -40;
    V_ERROR_MSG := SUBSTR('INSERT INTO R_MKBD_VD55_XE13 '||SQLERRM(SQLCODE),1,200);
    RAISE V_err;
  END;
  
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
END SPR_MKBD_VD55_XE13;