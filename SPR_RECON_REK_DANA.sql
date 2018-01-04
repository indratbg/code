create or replace PROCEDURE SPR_RECON_REK_DANA(
    P_DATE          DATE,
    P_RECON_OPTION  VARCHAR2,
    P_BANK_CD       VARCHAR2,
    P_USER_ID       VARCHAR2,
    P_GENERATE_DATE DATE,
    P_RANDOM_VALUE OUT NUMBER,
    P_ERRCD OUT NUMBER,
    P_ERRMSG OUT VARCHAR2 )
IS
  v_random_value NUMBER(10);
  v_err          EXCEPTION;
  v_err_cd       NUMBER(10);
  v_err_msg      VARCHAR2(200);
  V_BAL_DATE DATE;
BEGIN
  v_random_value   := ABS(dbms_random.random);
  
    begin  
        select max(tanggalefektif) into V_BAL_DATE				
        from t_bank_balance				
        where tanggalefektif >= (trunc(sysdate) -10);				
    EXCEPTION
        WHEN OTHERS THEN
            v_err_cd  := -3;
            v_err_msg :='SELECT MAX TANGGAL EFEKTIF FROM T_BANK_BALANCE'|| SQLERRM(SQLCODE) ;
            RAISE V_err;
    END;

  
  IF P_RECON_OPTION ='KSEI' THEN
  
    BEGIN
      SP_RPT_REMOVE_RAND('R_RECON_REK_DANA_KSEI',V_RANDOM_VALUE,P_ERRCD,P_ERRMSG);
    EXCEPTION
    WHEN OTHERS THEN
      v_err_cd  := -5;
      v_err_msg := SQLERRM(SQLCODE) ;
      RAISE V_err;
    END;
    
    BEGIN
      INSERT
      INTO R_RECON_REK_DANA_KSEI
        (
          BAL_DT,
          KODE,
          CLIENT_CD,
          NAME,
          REK_DANA,
          IP_SUBREK,
          KSEI_SUBREK,
          IP_SID,
          KSEI_SID,
          KETERANGAN,
          USER_ID,
          RAND_VALUE,
          GENERATE_DATE
        )
      SELECT P_DATE ,
        KODE,
        CLIENT_CD,
        NAME,
        REK_DANA,
        F_SUBREK(IP_SUBREK),
        F_SUBREK(KSEI_SUBREK),
        F_SID(IP_SID),
        F_SID(KSEI_SID),
        KETERANGAN,
        p_user_id,
        v_random_value,
        p_generate_date
      FROM
        (SELECT 0 kode,
          NULL client_cd,
          NULL name,
          NULL rek_Dana,
          NULL ip_subrek,
          NULL ksei_subrek,
          NULL ip_sid,
          NULL ksei_sid,
          'data KSEI imported on : '
          ||TO_CHAR(TRUNC(create_dt),'dd/mm/yy') keterangan
        FROM T_REK_DANA_KSEI
        WHERE ROWNUM = 1
        UNION ALL
        SELECT 1 kode,
          v.client_cd,
          t.name,
          f_bank_acct_mask(t.rek_Dana,NVL(mf.acct_mask,0)),
          v.subrek001 ip_subrek,
          t.subRek ksei_subrek,
          NULL ip_sid,
          t.sid ksei_sid,
          'ADA DI KSEI TIDAK ADA DI INSISTPRO' keterangan
        FROM T_REK_DANA_KSEI t,
          v_client_subrek14 v,
          ( SELECT bank_acct_num FROM MST_CLIENT_FLACCT WHERE acct_stat <> 'C' AND APPROVED_STAT='A'
          ) f,
          MST_FUND_BANK mf
        WHERE t.subrek       = v.subrek001(+)
        AND t.rek_Dana       = f.bank_acct_num(+)
        AND f.bank_acct_num IS NULL
        AND t.bank_cd        = mf.bank_cd
        UNION ALL
        SELECT 2 kode,
          mcf.client_cd,
          mcf.acct_name,
          f_bank_acct_mask(mcf.bank_Acct_num,NVL(mf.acct_mask,0)),
          v.subrek001 ip_subrek,
          t.subRek ksei_subrek,
          NULL ip_sid,
          t.sid ksei_sid,
          'ADA DI INSISTPRO TIDAK ADA DI KSEI' KETERANGAN
        FROM MST_CLIENT_FLACCT mcf,
          MST_CLIENT m,
          v_client_subrek14 v,
          T_REK_DANA_KSEI t,
          MST_FUND_BANK mf
        WHERE mcf.client_cd   = m.client_Cd(+)
        AND mcf.acct_stat    <> 'C'
        AND mcf.APPROVED_STAT='A'
        AND mcf.client_cd     = v.client_Cd(+)
        AND mcf.bank_acct_num = rek_Dana (+)
        AND rek_dana         IS NULL
        AND mcf.bank_cd       = mf.bank_cd
        UNION ALL
        SELECT 3 kode,
          mcf.client_cd,
          mcf.acct_name,
          f_bank_acct_mask(mcf.bank_Acct_num,NVL(mf.acct_mask,0)),
          v.subrek001,
          t.subrek ksei_subrek,
          f.sid ip_sid,
          t.sid ksei_sid,
          'SID/ SUB REKENING TIDAK SAMA' KETERANGAN
        FROM MST_CLIENT_FLACCT mcf,
          MST_CLIENT m,
          v_client_subrek14 v,
          MST_CIF f,
          ( SELECT rek_dana, sid, subrek, bank_cd FROM T_REK_DANA_KSEI
          ) t,
          MST_FUND_BANK mf
        WHERE mcf.client_cd   = m.client_Cd
        AND mcf.acct_stat    <> 'C'
        AND mcf.APPROVED_STAT='A'
        AND mcf.bank_cd       = t.bank_cd
        AND m.cifs            = f.cifs
        AND mcf.client_cd     = v.client_Cd(+)
        AND mcf.bank_acct_num = rek_dana
        AND mcf.bank_cd       = mf.bank_cd
        AND (t.sid           <> f.sid
        OR t.subrek          <> v.subrek001)
        UNION ALL
        SELECT 9 kode,
          bank_cd,
          'di KSEI      '
          ||TO_CHAR(COUNT(DISTINCT rek_dana)) cnt,
          NULL,
          NULL ip_subrek,
          NULL ksei_subrek,
          NULL ip_sid,
          NULL ksei_sid,
          'jumlah Rek dana '
        FROM T_REK_DANA_KSEI
        GROUP BY bank_Cd
        UNION ALL
        SELECT 9 kode,
          bank_cd,
          'di Insistpro '
          ||TO_CHAR(COUNT(DISTINCT bank_acct_num)),
          NULL,
          NULL ip_subrek,
          NULL ksei_subrek,
          NULL ip_sid,
          NULL ksei_sid,
          'jumlah Rek dana '
        FROM MST_CLIENT_FLACCT
        WHERE acct_stat <> 'C'
        AND APPROVED_STAT='A'
        GROUP BY bank_Cd
        );
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      V_ERR_CD  := -10;
      V_ERR_MSG :='NO DATA FOUND';
      RAISE V_ERR;
    WHEN OTHERS THEN
      v_err_cd  := -15;
      v_err_msg := SQLERRM(SQLCODE);
      RAISE V_err;
    END;
    
  ELSIF P_RECON_OPTION='BANK_PEMBAYAR' THEN
  
    BEGIN
      SP_RPT_REMOVE_RAND('R_RECON_REK_DANA_BANK_PEMBAYAR',V_RANDOM_VALUE,P_ERRCD,P_ERRMSG);
    EXCEPTION
    WHEN OTHERS THEN
      v_err_cd  := -300;
      v_err_msg := SQLERRM(SQLCODE);
      RAISE V_err;
    END;
    
    
    BEGIN
      INSERT
      INTO R_RECON_REK_DANA_BANK_PEMBAYAR
        (
          BAL_DT,
          KODE,
          CLIENT_CD,
          OPEN_DT,
          NAME,
          REK_DANA,
          IP_SUBREK,
          BANK_SUBREK,
          IP_SID,
          BANK_SID,
          KETERANGAN,
          USER_ID,
          RAND_VALUE,
          GENERATE_DATE
        )
      SELECT V_BAL_DATE,
        KODE,
        CLIENT_CD,
        OPEN_DT,
        NAME,
        REK_DANA,
        F_SUBREK( IP_SUBREK),
        F_SUBREK(BANK_SUBREK),
        F_SID(IP_SID),
        F_SID(BANK_SID),
        KETERANGAN,
        P_USER_ID,
        v_random_value,
        p_generate_date
      FROM
        (SELECT 0 kode,
          NULL client_cd,
          TO_DATE(NULL) open_dt,
          NULL name,
          NULL rek_Dana,
          NULL ip_subRek ,
          NULL bank_subrek,
          NULL ip_sid,
          NULL bank_sid,
          'Balance '
          ||P_BANK_CD
          ||' : '
          ||TO_CHAR(P_DATE,'dd/mm/yy') keterangan
        FROM dual
        UNION ALL
        SELECT 1 kode,
          v.client_cd,
          v.acct_open_dt,
          t.namanasabah,
          t.rDn,
          v.subrek001 ,
          t.sRe bank_subrek,
          v.sid ip_sid,
          t.sid bank_sid,
          'ADA DI '
          ||P_BANK_CD
          ||' TIDAK ADA DI INSISTPRO' keterangan
        FROM
          (SELECT rdn,
            sre,
            namanasabah,
            sid
          FROM T_BANK_BALANCE
          WHERE tanggalefektif = V_BAL_DATE
          and bankid = p_bank_cd--18jan2016
          ) t,
          (SELECT subrek001,
            m.client_cd,
            acct_open_dt,
            f.sid
          FROM v_client_subrek14 v,
            MST_CLIENT m,
            MST_CIF f
          WHERE m.client_cd =v.client_cd(+)
          AND m.cifs        = f.cifs
          ) v,
          (SELECT bank_acct_num
          FROM MST_CLIENT_FLACCT
          WHERE acct_stat <> 'C'
          AND APPROVED_STAT='A'
          AND bank_cd      = P_BANK_CD
          ) f
        WHERE t.sre          = v.subrek001(+)
        AND t.rDn            = f.bank_acct_num(+)
        AND f.bank_acct_num IS NULL
        UNION ALL
        SELECT 2 kode,
          mcf.client_cd,
          m.acct_open_dt,
          mcf.acct_name,
          mcf.bank_Acct_num,
          v.subrek001,
          NULL bca_subrek,
          f.sid ip_sid,
          NULL bca_sid,
          'ADA DI INSISTPRO TIDAK ADA DI '
          ||P_BANK_CD KETERANGAN
        FROM MST_CLIENT_FLACCT mcf,
          MST_CLIENT m,
          v_client_subrek14 v,
          MST_CIF f,
          ( SELECT rdn FROM T_BANK_BALANCE WHERE tanggalefektif = V_BAL_DATE  
          and bankid = p_bank_cd--18jan2016
          ) t
        WHERE mcf.client_cd   = m.client_Cd
        AND mcf.acct_stat    <> 'C'
        AND mcf.APPROVED_STAT='A'
        AND mcf.bank_cd       =P_BANK_CD
        AND m.cifs            = f.cifs
        AND mcf.client_cd     = v.client_Cd(+)
        AND mcf.bank_acct_num = rdn (+)
        AND rdn              IS NULL
        UNION ALL
        SELECT 3 kode,
          mcf.client_cd,
          m.acct_open_dt,
          mcf.acct_name,
          mcf.bank_Acct_num,
          v.subrek001,
          t.sre bank_subrek,
          f.sid ip_sid,
          t.sid bank_sid,
          'SID atau SUB REKENING TIDAK SAMA' KETERANGAN
        FROM MST_CLIENT_FLACCT mcf,
          MST_CLIENT m,
          v_client_subrek14 v,
          MST_CIF f,
          ( SELECT rdn, sid, sre FROM T_BANK_BALANCE WHERE tanggalefektif = V_BAL_DATE
             and bankid = p_bank_cd--18jan2016
          ) t
        WHERE mcf.client_cd   = m.client_Cd
        AND mcf.acct_stat    <> 'C'
        AND mcf.APPROVED_STAT='A'
        AND mcf.bank_cd       = P_BANK_CD
        AND m.cifs            = f.cifs
        AND mcf.client_cd     = v.client_Cd(+)
        AND mcf.bank_acct_num = rdn
        AND (t.sid           <> f.sid
        OR t.sre             <> v.subrek001)
        UNION ALL
        SELECT 9 kode,
          bankid,
          TO_DATE(NULL),
          'di '
          ||P_BANK_CD
          ||'      : '
          ||TO_CHAR(COUNT(rdn)) cnt,
          NULL,
          NULL ip_subrek,
          NULL bank_subrek,
          NULL ip_sid,
          NULL bank_sid,
          'jumlah Rek dana '
        FROM T_BANK_BALANCE
        WHERE tanggalefektif = V_BAL_DATE
        GROUP BY bankID
        UNION ALL
        SELECT 9 kode,
          bank_cd,
          TO_DATE(NULL),
          'di Insistpro : '
          ||TO_CHAR(COUNT(bank_acct_num)),
          NULL,
          NULL ip_subrek,
          NULL bank_subrek,
          NULL ip_sid,
          NULL bank_sid,
          'jumlah Rek dana '
        FROM MST_CLIENT_FLACCT
        WHERE acct_stat <> 'C'
        AND APPROVED_STAT='A'
        AND bank_cd      = P_BANK_CD
        GROUP BY bank_Cd
        );
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      V_ERR_CD  := -20;
      V_ERR_MSG :='NO DATA FOUND';
      RAISE V_ERR;
    WHEN OTHERS THEN
      v_err_cd  := -25;
      v_err_msg := SQLERRM(SQLCODE);
      RAISE V_err;
    END;
    
  ELSE--RECONCILE WITH MULTI BANK
  
    BEGIN
      SP_RPT_REMOVE_RAND('R_RECON_REK_DANA_MULTI_BANK',V_RANDOM_VALUE,P_ERRCD,P_ERRMSG);
    EXCEPTION
    WHEN OTHERS THEN
      v_err_cd  := -27;
      v_err_msg := SQLERRM(SQLCODE) ;
      RAISE V_err;
    END;
    
    BEGIN
      INSERT
      INTO R_RECON_REK_DANA_MULTI_BANK
        (
          KODE,
          BANKID,
          CLIENT_CD,
          OPEN_DT,
          NAME,
          REK_DANA,
          IP_SUBREK,
          BANK_SUBREK,
          IP_SID,
          BANK_SID,
          KETERANGAN,
          USER_ID,
          RAND_VALUE,
          GENERATE_DATE
        )
      SELECT KODE,
        BANKID,
        CLIENT_CD,
        OPEN_DT,
        NAME,
        REK_DANA,
        F_SUBREK(IP_SUBREK),
        F_SUBREK(BANK_SUBREK),
        F_SID(IP_SID),
        F_SID(BANK_SID),
        KETERANGAN,
        P_USER_ID,
        v_random_value,
        p_generate_date
      FROM
        (SELECT 0 kode,
          NULL bankid,
          NULL client_cd,
          TO_DATE(NULL) open_dt,
          NULL name,
          NULL rek_Dana,
          NULL ip_subRek ,
          NULL bank_subrek,
          NULL ip_sid,
          NULL bank_sid,
          'Balance Bank'
          ||' : '
          ||TO_CHAR(P_DATE,'dd/mm/yy') keterangan
        FROM dual
        UNION ALL
        SELECT 1 kode,
          bankid,
          v.client_cd,
          v.acct_open_dt,
          t.namanasabah,
          t.rDn,
          v.subrek001 ,
          t.sRe bank_subrek,
          v.sid ip_sid,
          t.sid bank_sid,
          'ADA DI '
          ||bankid
          ||' TIDAK ADA/closed DI INSISTPRO' keterangan
        FROM
          (SELECT rdn,
            sre,
            namanasabah,
            sid,
            bankid
          FROM T_BANK_BALANCE
          WHERE tanggalefektif = P_DATE
          ) t,
          (SELECT subrek001,
            m.client_cd,
            acct_open_dt,
            f.sid
          FROM v_client_subrek14 v,
            MST_CLIENT m,
            MST_CIF f
          WHERE m.client_cd =v.client_cd(+)
          AND m.cifs        = f.cifs
          ) v,
          (SELECT bank_acct_num,
            bank_cd
          FROM MST_CLIENT_FLACCT
          WHERE acct_stat <> 'C'
          AND APPROVED_STAT='A'
          ) f
        WHERE t.sre          = v.subrek001(+)
        AND t.rDn            = f.bank_acct_num(+)
        AND t.bankid         = f.bank_cd(+)
        AND f.bank_acct_num IS NULL
        AND f.bank_cd       IS NULL
        UNION ALL
        SELECT 2 kode,
          mcf.bank_cd,
          mcf.client_cd,
          m.acct_open_dt,
          mcf.acct_name,
          mcf.bank_Acct_num,
          v.subrek001,
          NULL bca_subrek,
          f.sid ip_sid,
          NULL bca_sid,
          'ADA DI INSISTPRO TIDAK ADA DI '
          ||mcf.bank_cd KETERANGAN
        FROM
          (SELECT client_cd,
            bank_acct_num,
            bank_cd,
            acct_name
          FROM MST_CLIENT_FLACCT
          WHERE acct_stat <> 'C'
          AND APPROVED_STAT='A'
          ) mcf,
          MST_CLIENT m,
          v_client_subrek14 v,
          MST_CIF f,
          ( SELECT rdn, bankid FROM T_BANK_BALANCE WHERE tanggalefektif =  P_DATE
          ) t
        WHERE mcf.client_cd   = m.client_Cd
        AND m.cifs            = f.cifs
        AND mcf.client_cd     = v.client_Cd(+)
        AND mcf.bank_acct_num = rdn (+)
        AND mcf.bank_cd       = bankid(+)
        AND rdn              IS NULL
        AND bankid           IS NULL
        UNION ALL
        SELECT 3 kode,
          bankid,
          mcf.client_cd,
          m.acct_open_dt,
          mcf.acct_name,
          mcf.bank_Acct_num,
          v.subrek001,
          t.sre bank_subrek,
          f.sid ip_sid,
          t.sid bank_sid,
          'SID atau SUB REKENING TIDAK SAMA '
          ||bankid KETERANGAN
        FROM MST_CLIENT_FLACCT mcf,
          MST_CLIENT m,
          v_client_subrek14 v,
          MST_CIF f,
          (SELECT rdn,
            sid,
            sre,
            bankid
          FROM T_BANK_BALANCE
          WHERE tanggalefektif = P_DATE
          ) t
        WHERE mcf.client_cd   = m.client_Cd
        AND mcf.acct_stat    <> 'C'
        AND mcf.APPROVED_STAT='A'
        AND mcf.bank_cd       = t.bankid
        AND m.cifs            = f.cifs
        AND mcf.client_cd     = v.client_Cd(+)
        AND mcf.bank_acct_num = rdn
        AND (t.sid           <> f.sid
        OR t.sre             <> v.subrek001)
        UNION ALL
        SELECT 8 kode,
          NULL bankid,
          bankid client_cd,
          TO_DATE(NULL),
          'di '
          ||bankID
          ||'      : '
          ||TO_CHAR(COUNT(rdn)) cnt,
          NULL,
          NULL ip_subrek,
          NULL bank_subrek,
          NULL ip_sid,
          NULL bank_sid,
          'jumlah Rek dana di bank '
        FROM T_BANK_BALANCE
        WHERE tanggalefektif = P_DATE
        GROUP BY bankID
        UNION ALL
        SELECT 9 kode,
          NULL bank_cd,
          bank_cd client_cd,
          TO_DATE(NULL),
          'di Insistpro : '
          ||TO_CHAR(COUNT(DISTINCT bank_acct_num)),
          NULL,
          NULL ip_subrek,
          NULL bank_subrek,
          NULL ip_sid,
          NULL bank_sid,
          'jumlah Rek dana di insistpro '
        FROM MST_CLIENT_FLACCT
        WHERE acct_stat <> 'C'
        AND APPROVED_STAT='A'
        GROUP BY bank_Cd
        ORDER BY 1,2
        );
        
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      V_ERR_CD  := -30;
      V_ERR_MSG :='NO DATA FOUND';
      RAISE V_ERR;
    WHEN OTHERS THEN
      v_err_cd  := -35;
      v_err_msg := SQLERRM(SQLCODE);
      RAISE V_err;
    END;
    
  END IF;
  
  p_random_value := v_random_value;
  P_ERRCD        := 1;
  p_errmsg       := '';
  
EXCEPTION
WHEN V_err THEN
  ROLLBACK;
  p_errcd  := v_err_cd;
  p_errmsg := v_err_msg;
WHEN OTHERS THEN
  ROLLBACK;
  p_errcd  := -1;
  p_errmsg := SUBSTR(SQLERRM(SQLCODE),1,200);
END SPR_RECON_REK_DANA;