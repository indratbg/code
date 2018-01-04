create or replace 
PROCEDURE SPR_RECON_SUBREK_AND_SID(
    P_END_DATE      DATE,
    P_SUBREK_001    VARCHAR2,
    P_SUBREK_004    VARCHAR2,
    P_OPTION        VARCHAR2,--PILIHAN  SUBREK/SID
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
  --V_BAL_DT       DATE;
  V_DATE DATE;
  
BEGIN

  v_random_value := ABS(dbms_random.random);
  
  IF P_OPTION     ='SUBREK' THEN
  
    BEGIN
      SP_RPT_REMOVE_RAND('R_RECONCILE_SUBREK',V_RANDOM_VALUE,V_ERROR_MSG,V_ERROR_CD);
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
      INTO R_RECONCILE_SUBREK
        (
          SORTK ,
          KETERANGAN ,
          SUBREK ,
          CLIENT_CD ,
          CLIENT_NAME ,
          USER_ID ,
          RAND_VALUE ,
          GENERATE_DATE,
          END_DATE
        )
      SELECT SORTK,
        KETERANGAN ,
        SUBREK ,
        CLIENT_CD ,
        CLIENT_NAME ,
        P_USER_ID,
        V_RANDOM_VALUE,
        P_GENERATE_DATE ,
        P_END_DATE
      FROM
        (SELECT 1 sortk,
          'Ada di CBEST, tidak ada di insistpro' Keterangan,
          s.subrek AS subrek,
          '' client_cd,
          s.client_name
        FROM
          (SELECT subrek_cd
          FROM mst_client_rekefek
          WHERE SUBSTR(subrek_cd,6,4) <> '0000'
          ) a,
          ( SELECT * FROM t_subrek_ksei WHERE status_dt =P_END_DATE
          ) s
        WHERE a.subrek_cd(+) = trim(s.subrek)
        AND (a.subrek_cd    IS NULL)
        UNION ALL
        SELECT 2 sortk,
          'Belum punya 004' keterangan,
          s1.subrek,
          s1.client_cd,
          s1.client_name
        FROM
          (SELECT subrek001 AS subrek,
            mst_client.client_cd,
            mst_client.client_name
          FROM v_client_subrek14,
            mst_client
          WHERE subrek004                IS NULL
          AND v_client_subrek14.client_cd = mst_client.client_cd
          AND mst_client.susp_stat       <> 'C'
          ) s1
        WHERE P_SUBREK_004 = 'Y'
        UNION ALL
        SELECT 3 sortk,
          'Belum punya 001 ' keterangan,
          subrek_cd subrek,
          mst_client_rekefek.client_cd,
          client_name
        FROM mst_client_rekefek,
          mst_client,
          (SELECT trim(other_1) coy_cd FROM mst_company
          )
        WHERE status                    <> 'C'
        AND SUBSTR(subrek_cd, 6,4)       = '0000'
        AND mst_client_rekefek.client_cd = mst_client.client_cd
        AND susp_stat                   <> 'C'
        AND mst_client.custodian_Cd     IS NULL
        AND mst_client.client_cd        <> coy_cd
        AND P_SUBREK_001                 = 'Y'
        UNION ALL
        SELECT 4 sortk,
          'Tidak ada/closed di CBEST, ada di Insistpro ' Keterangan,
          a.subrek_cd AS subrek,
          m.client_cd,
          m.client_name
        FROM
          (SELECT mst_client_rekefek.client_cd,
            subrek_cd
          FROM mst_client_rekefek,
            mst_client
          WHERE SUBSTR(subrek_Cd,6,4)     <> '0000'
          AND status                       = 'A'
          AND open_date                   <= P_END_DATE
          AND mst_client_rekefek.client_cd = mst_client.client_cd
          AND susp_stat                   <> 'C'
          ) a,
          ( SELECT * FROM t_subrek_ksei WHERE status_dt =P_END_DATE
          ) s,
          mst_client m
        WHERE a.subrek_cd = trim(s.subrek(+))
        AND a.client_cd   = m.client_cd
        AND s.subrek     IS NULL
        UNION ALL
        SELECT 5 sortk,
          'Ada di CBEST, sudah closed di insistpro' Keterangan,
          s.subrek,
          '' client_cd,
          s.client_name
        FROM
          (SELECT subrek_cd
          FROM mst_client_rekefek,
            mst_client
          WHERE mst_client_rekefek.client_cd = mst_client.client_cd
          AND susp_stat                     <> 'N'
          AND status                         = 'C'
          ) a,
          ( SELECT * FROM t_subrek_ksei WHERE status_dt =P_END_DATE
          ) s
        WHERE a.subrek_cd= trim(s.subrek)
        UNION ALL
        SELECT 6 sortk,
          'Satu SID punya lebih dari satu sub rek 004' Keterangan,
          subrek_cd,
          client_cd,
          sid
          ||' '
          ||client_name
        FROM
          (SELECT m.client_cd,
            m.sid,
            m.client_name,
            t.subrek_cd,
            COUNT( DISTINCT t.subrek_cd ) over (partition BY m.sid) cnt
          FROM mst_client_rekefek t,
            mst_client m
          WHERE t.cifs                 = m.cifs
          AND SUBSTR(t.subrek_cd,10,3) = '004'
          AND t.STATUS                 = 'A'
          AND m.susp_stat              = 'N'
          AND m.sid                   IS NOT NULL
          AND open_date               <= P_END_DATE
          AND acct_open_dt            <= P_END_DATE
          )
        WHERE cnt > 1
        UNION ALL
        SELECT 7 sortk,
          'Jumlah sub rek ' Keterangan,
          'di KSEI',
          'sub rek '
          ||rek_type AS subrek,
          TO_CHAR(COUNT(subrek)) cnt
        FROM
          (SELECT SUBSTR(subrek,10,3) rek_type,
            subrek
          FROM t_subrek_ksei
          WHERE status_dt         = P_END_DATE
          AND SUBSTR(subrek,6,4) <> '0000'
          )
        GROUP BY rek_type
        UNION
        SELECT 7 sortk,
          'Jumlah sub rek ' Keterangan,
          'di Insistpro',
          'sub rek 001',
          TO_CHAR(COUNT(DISTINCT subrek001)) cnt
        FROM mst_client m,
          v_client_subrek14 v,
          mst_client_rekefek r
        WHERE m.client_cd          = v.client_Cd
        AND m.susp_stat            = 'N'
        AND v.subrek001            = r.subrek_cd
        AND open_date             <= P_END_DATE
        AND SUBSTR(subrek001,6,4) <> '0000'
        UNION
        SELECT 7 sortk,
          'Jumlah sub rek ' Keterangan,
          'di Insistpro',
          'sub rek 004' ,
          TO_CHAR(COUNT(DISTINCT subrek004)) cnt
        FROM mst_client m,
          v_client_subrek14 v,
          mst_client_rekefek r
        WHERE m.client_cd          = v.client_Cd
        AND m.susp_stat            = 'N'
        AND v.subrek004            = r.subrek_cd
        AND open_date             <= P_END_DATE
        AND SUBSTR(subrek004,6,4) <> '0000'
        );
        --where rownum<100;
    EXCEPTION
    WHEN OTHERS THEN
      V_ERROR_CD  := -30;
      V_ERROR_MSG := SUBSTR('INSERT R_RECONCILE_SUBREK '||V_ERROR_MSG||SQLERRM(SQLCODE),1,200);
      RAISE V_err;
    END;
    
  ELSE --UNTUK RECONCILE SID
  
    BEGIN
      SP_RPT_REMOVE_RAND('R_RECONCILE_SID',V_RANDOM_VALUE,V_ERROR_MSG,V_ERROR_CD);
    EXCEPTION
    WHEN OTHERS THEN
      V_ERROR_CD  := -40;
      V_ERROR_MSG := SUBSTR('SP_RPT_REMOVE_RAND '||V_ERROR_MSG||SQLERRM(SQLCODE),1,200);
      RAISE V_err;
    END;
    
    IF V_ERROR_CD  <0 THEN
      V_ERROR_CD  := -50;
      V_ERROR_MSG := SUBSTR('SP_RPT_REMOVE_RAND'||V_ERROR_MSG,1,200);
      RAISE V_ERR;
    END IF;
    
    BEGIN
      INSERT
      INTO R_RECONCILE_SID
        (
          SORTK ,
          KETERANGAN ,
          SID ,
          SUBREK ,
          CLIENT_CD ,
          IP_SID ,
          CLIENT_NAME ,
          USER_ID ,
          RAND_VALUE ,
          GENERATE_DATE,
          END_DATE
        )
      SELECT SORTK ,
        KETERANGAN ,
        SID ,
        SUBREK ,
        CLIENT_CD ,
        IP_SID ,
        CLIENT_NAME ,
        P_USER_ID,
        V_RANDOM_VALUE,
        P_GENERATE_DATE ,
        P_END_DATE
      FROM
        (SELECT '1' sortk,
          'Ada di KSEI, Tidak ada di IP' keterangan,
          a.ksei_sid sid,
          '' subrek,
          '' client_cd,
          '' ip_sid,
          a.ksei_name AS client_name
        FROM
          (SELECT sid ksei_sid,
            MIN(client_name) ksei_name
          FROM t_subrek_ksei
          WHERE status_dt = P_END_DATE
          AND sid        IS NOT NULL
          GROUP BY sid
          ) a,
          (SELECT c.sid,
            MIN(c.cif_name) AS client_name
          FROM mst_client m,
            MST_CIF C
          WHERE susp_stat   in ('N','Y')--24MAY
          AND acct_open_dt <= P_END_DATE
          AND M.SID        IS NOT NULL
         -- AND CUSTODIAN_CD IS NULL--24MAY
          AND m.cifs        = c.cifs
          GROUP BY c.sid
          ) b
        WHERE a.ksei_sid = b.sid(+)
        AND b.sid       IS NULL
        UNION ALL
        SELECT '2' sortk,
          'Ada di IP, Tidak ada di KSEI' keterangan,
          '' sid,
          '' subrek,
          '' client_cd,
          b.sid,
          b.client_name
        FROM
          (SELECT sid ksei_sid,
            MIN(client_name) ksei_name
          FROM t_subrek_ksei
          WHERE status_dt = P_END_DATE
          AND sid        IS NOT NULL
          GROUP BY sid
          ) a,
          (SELECT c.sid,
            MIN(c.cif_name) AS client_name
          FROM mst_client m,
            MST_CIF C
          WHERE susp_stat   IN  ('N','Y')--24MAY
          AND acct_open_dt <= P_END_DATE
          AND M.SID        IS NOT NULL
          --AND CUSTODIAN_CD IS NULL--24MAY
          AND m.cifs        = c.cifs
          GROUP BY c.sid
          ) b
        WHERE b.sid     = a.ksei_sid(+)
        AND a.ksei_sid IS NULL
        UNION ALL
        SELECT '3' sortk,
          'SID TIDAK SAMA' keterangan,
          t.sid,
          t.subrek,
          m.client_cd,
          m.ip_sid,
          m.client_name
        FROM
          (SELECT m.client_Cd,
            v.subrek001 AS subrek,
            NVL(c.sid,'X') ip_sid,
            acct_open_Dt,
            cif_name client_name
          FROM MST_CLIENT m,
            v_client_subrek14 v,
            MST_CIF C
          WHERE susp_stat    IN ('N','Y')--24MAY
          AND m.acct_open_dt < P_END_DATE
          AND m.cifs         = c.cifs
          AND m.client_cd    = v.client_cd
          UNION ALL
          SELECT m.client_Cd,
            v.subrek004,
            NVL(c.sid,'X') ip_sid,
            acct_open_Dt,
            cif_name client_name
          FROM MST_CLIENT m,
            v_client_subrek14 v,
            MST_CIF C
          WHERE susp_stat    IN ('N','Y')--24MAY
          AND m.acct_open_dt < P_END_DATE
          AND m.cifs         = c.cifs
          AND m.client_cd    = v.client_cd
          ) m,
          (SELECT NVL(sid,'X') sid,
            subrek
          FROM T_SUBREK_KSEI
          WHERE status_dt = P_END_DATE
          ) t
        WHERE t.subrek = m.subrek
        AND t.sid     <> m.ip_sid
        UNION ALL
        SELECT '4' sortk,
          'TIDAK PUNYA SID' keterangan,
          t.sid,
          t.subrek,
          m.client_cd,
          m.ip_sid,
          m.client_name
        FROM
          (SELECT m.client_Cd,
            v.subrek001 AS subrek,
            NVL(c.sid,'X') ip_sid,
            acct_open_Dt,
            cif_name client_name
          FROM MST_CLIENT m,
            v_client_subrek14 v,
            MST_CIF C
          WHERE susp_stat    IN('N','Y')--24MAY
          AND m.acct_open_dt < P_END_DATE
          AND m.cifs         = c.cifs
          AND m.client_cd    = v.client_cd
          UNION ALL
          SELECT m.client_Cd,
            v.subrek004,
            NVL(c.sid,'X') ip_sid,
            acct_open_Dt,
            cif_name client_name
          FROM MST_CLIENT m,
            v_client_subrek14 v,
            MST_CIF C
          WHERE susp_stat    IN ('N','Y')--24MAY
          AND m.acct_open_dt < P_END_DATE
          AND m.cifs         = c.cifs
          AND m.client_cd    = v.client_cd
          ) m,
          (SELECT NVL(sid,'X') sid,
            subrek
          FROM T_SUBREK_KSEI
          WHERE status_dt = P_END_DATE
          ) t
        WHERE t.subrek = m.subrek
        AND t.sid      = 'X'
        AND m.ip_sid   = 'X'
        UNION ALL
        SELECT '9' sortk,
          'JUMLAH SID ' keterangan,
          '' sid,
          '' subrek,
          '' client_cd,
          '' ip_sid,
          'di KSEI         '
          ||TO_CHAR(COUNT(DISTINCT sid)) AS client_name
        FROM t_subrek_ksei
        WHERE status_dt = P_END_DATE
        AND sid        IS NOT NULL
        UNION ALL
        SELECT '9' sortk,
          'Jumlah SID ' keterangan,
          '' sid,
          '' subrek,
          '' client_cd,
          '' ip_sid,
          'di Insistpro  '
          ||TO_CHAR(COUNT(DISTINCT c.sid)) AS client_name
        FROM mst_client m,
          MST_CIF C
        WHERE m.susp_stat   IN ('N','Y')--24MAY
        AND m.cifs          = c.cifs
        AND m.acct_open_dt <= P_END_DATE
        AND M.SID          IS NOT NULL
        --AND m.custodian_cd IS NULL--24MAY
        ORDER BY sortk,
          client_cd,
          client_name
        );
    EXCEPTION
    WHEN OTHERS THEN
      V_ERROR_CD  := -60;
      V_ERROR_MSG := SUBSTR('INSERT R_RECONCILE_SID '||V_ERROR_MSG||SQLERRM(SQLCODE),1,200);
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
END SPR_RECON_SUBREK_AND_SID;