create or replace 
PROCEDURE Spr_RECON_RDI(
    P_END_DATE      DATE,
    P_PEMBULATAN    VARCHAR2,
    P_BANK_CD VARCHAR2,
    P_USER_ID       VARCHAR2,
    p_generate_date DATE,
    vo_random_value OUT NUMBER,
    vo_errcd OUT NUMBER,
    vo_errmsg OUT VARCHAR2 )
IS
  vl_random_value NUMBER(10);
  vl_err          EXCEPTION;
  v_bgn_dt        DATE;
  
  V_ERROR_CD NUMBER(5);
  V_ERROR_MSG VARCHAR2(200);
  V_BEGIN_DATE DATE;
BEGIN

  Vl_Random_Value := ABS(Dbms_Random.Random);
  
  BEGIN
    Sp_Rpt_Remove_Rand('R_RECON_RDI',vl_random_value,V_ERROR_CD,V_ERROR_MSG);
  EXCEPTION
  WHEN OTHERS THEN
    V_ERROR_CD  := -2;
    V_ERROR_MSG := SUBSTR('Sp_Rpt_Remove_Rand'||SQLERRM(SQLCODE),1,200);
    RAISE vl_err;
  END;
  
  V_BEGIN_DATE :=P_END_DATE - to_char(p_end_date,'dd') + 1 ;
    
  BEGIN
    INSERT
    INTO r_RECON_RDI
      ( TO_DATE,
        CLIENT_CD,
        BRANCH_CODE,
        BANK_ACCT_FMT,
        CLIENT_NAME,
        SALDO_INSISTPRO,
        SALDO_BCA,
        SELISIH,
        RDI_BANK_CD,
        USER_ID,
        RAND_VALUE,
        GENERATE_DATE,
        RECON_OPTION
      )
    SELECT  P_END_DATE,d.client_cd,
      trim(m.branch_code),
      NVL(f.bank_acct_fmt,'TAK ADA') bank_acct_fmt,
      m.client_name,
      ip_bal saldo_insistpro,
      bank_bal saldo_bca,
      ABS(ip_bal - bank_bal) selisih,
      rdi_bank_cd ,
      P_USER_ID,
      Vl_Random_Value,
      P_GENERATE_DATE,
      DECODE(P_PEMBULATAN,'Y','Selisih pembulatan tampil','Selisih pembulatan tidak tampil')RECON_OPTION
    FROM
      (SELECT client_cd,
        bank_acct_num,
        SUM(ip_bal) ip_bal,
        SUM(bank_bal) bank_bal
      FROM
        (SELECT a.client_Cd,
          NVL(mf.bank_acct_num, 'TAK ADA') bank_acct_num,
          end_bal AS ip_bal,
          0 bank_bal
        FROM
          (SELECT client_Cd,
            SUM(amt) end_bal
          FROM
            (SELECT client_cd,
              debit - credit AS amt
            FROM t_fund_bal
            WHERE bal_dt = V_BEGIN_DATE
            AND acct_cd  = 'DBEBAS'
            UNION ALL
            SELECT client_cd,
              debit - credit AS amt
            FROM T_FUND_LEDGER t
            WHERE t.doc_date BETWEEN V_BEGIN_DATE AND P_END_DATE
            AND t.approved_sts = 'A'
            AND t.acct_cd      = 'DBEBAS'
            )
          GROUP BY client_cd
          ) a,
          (SELECT client_cd,
            bank_acct_num,
            MST_FUND_bANK.BANK_cD,
            default_flg
          FROM mst_client_flacct,
            mst_fund_bank
          WHERE mst_fund_bank.bank_cd      = mst_client_flacct.bank_cd
          AND mst_client_flacct.acct_stat <> 'C'
          AND MST_FUND_BANK.BANK_CD = P_BANK_CD
          ) mf
        WHERE a.client_cd           = mf.client_cd --(+)--17FEB2016
      --  AND NVL(MF.default_flg,'X') = 'Y'--05FEB2016
        UNION ALL
        SELECT NVL(f.client_cd,'TAK ADA') client_cd,
          rdi_num,
          0 ip_bal,
          balance bank_bal
        FROM T_FUND_BAL_BANK t,
          (SELECT mst_client_flacct.client_cd,
            mst_client_flacct.bank_acct_num
          FROM mst_client_flacct,
            mst_fund_bank
          WHERE --default_flg                = 'Y'--05FEB
          --AND 
          mst_client_flacct.bank_cd    = mst_fund_bank.bank_cd
          AND mst_client_flacct.acct_stat <> 'C'
          AND mst_fund_bank.BANK_CD = P_BANK_CD
          ) f
        WHERE status_dt = P_END_DATE
        AND t.rdi_num   = f.BANK_ACCT_NUM (+)
        AND T.RDI_BANK_CD = P_BANK_CD--17FEB2016
        )
      GROUP BY client_cd,
        bank_acct_num
      ) d,
      MST_CLIENT m,
      mst_client_flacct f,
      ( SELECT bank_Cd rdi_bank_cd FROM mst_fund_bank WHERE BANK_CD = P_BANK_CD --default_flg = 'Y'05FEB
      ) B
    WHERE D.BANK_ACCT_NUM           = F.BANK_ACCT_NUM --(+)02may
    AND D.CLIENT_CD                 = M.CLIENT_CD--(+)02may
    and m.client_cd = f.client_cd--02may
    AND ABS(d.ip_bal   - d.bank_bal) <> 0
    AND ((ABS(d.ip_bal -d.bank_bal)   < 1
    AND P_PEMBULATAN                  = 'Y' )
    OR (ABS(d.ip_bal -d.bank_bal)     > 1
    AND P_PEMBULATAN                  = 'N' ))
    ORDER BY 1,
      2;
  EXCEPTION
  WHEN OTHERS THEN
   V_ERROR_CD  := -10;
    V_ERROR_MSG := SUBSTR('INSERT INTO R_RECON_RDI'||SQLERRM(SQLCODE),1,200);
    RAISE vl_err;
  END;
  
  vo_random_value := vl_random_value;
  vo_errcd        := 1;
  vo_errmsg       := '';
  
  --COMMIT;
  
EXCEPTION
WHEN vl_err THEN
  ROLLBACK;
  vo_random_value := 0;
  vo_errcd        := V_ERROR_CD;
  vo_errmsg       := SUBSTR(V_ERROR_MSG,1,200);
WHEN OTHERS THEN
  ROLLBACK;
  vo_random_value := 0;
  vo_errcd        := -1;
  vo_errmsg       := SUBSTR(SQLERRM(SQLCODE),1,200);
END Spr_RECON_RDI;