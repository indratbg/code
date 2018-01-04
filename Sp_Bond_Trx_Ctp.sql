create or replace 
PROCEDURE Sp_Bond_Trx_Ctp(
    P_TRX_DATE DATE,
    P_TRX_SEQ_NO T_BOND_TRX.TRX_SEQ_NO%TYPE,
    P_TRADE_DATETIME DATE,
    P_YIELD T_BOND_TRX_CTP.yield%TYPE,
    P_LAWAN_CUSTODY_CD T_BOND_TRX_CTP.d_custody%TYPE,
    P_USER_ID T_BOND_TRX.USER_ID%TYPE,
    P_SAVE_CSV T_BOND_TRX.approved_sts%TYPE,
    p_error_code OUT NUMBER,
    p_error_msg OUT VARCHAR2)
IS

  tmpVar NUMBER;
  /******************************************************************************
  NAME:       SP_BOND_TRX_CTP
  PURPOSE:
  REVISIONS:
  Ver        Date        Author           Description
  ---------  ----------  ---------------  ------------------------------------
  1.0        17/04/2014          1. Created this procedure.
  NOTES: generates record on T_BOND_TRX_CTP
  dari table itu oleh aplikasi di save ke excel file
  ******************************************************************************/
  v_pe_ctp_cd MST_LAWAN_BOND_TRX.ctp_Cd%TYPE;
  CURSOR csr_trx
  IS
    SELECT t.bond_cd,
      t.trx_type,
      t.lawan,
      t.nominal,
      t.price,
      t.value_dt,
      t.report_type,
      t.trx_id_yymm,
      DECODE(report_type,'TWO', l.ctp_cd, NULL) AS firm_id,
      t.ctp_trx_type,
      DECODE(trx_type,'S',v_pe_ctp_cd, l.ctp_cd) AS D_party_cd,
      DECODE(trx_type,'S', d.sr_custody_CD, P_LAWAN_CUSTODY_CD ) D_custody,
      DECODE(report_type,'ONE', DECODE(trx_type,'B',v_pe_ctp_cd, l.ctp_cd), NULL)                AS R_party_cd,
      DECODE(report_type,'ONE', DECODE(trx_type,'B',d.sr_custody_CD, P_LAWAN_CUSTODY_CD ), NULL) AS R_custody
    FROM T_BOND_TRX t,
      MST_LAWAN_BOND_TRX l,
      MST_BANK_CUSTODY d
    WHERE trx_date     = p_trx_date
    AND trx_seq_no     = p_trx_seq_no
    AND t.lawan        = l.lawan
    AND t.custodian_cd = d.cbest_Cd
    AND (report_type   ='ONE'
    OR trx_type        = 'S');
  v_cnt        NUMBER;
  v_err        EXCEPTION;
  v_error_code NUMBER;
  v_error_msg  VARCHAR2(200);
BEGIN

  tmpVar := 0;
  BEGIN
  SELECT 'S-'
    ||SUBSTR(prm_desc,1,2)
  INTO v_pe_ctp_cd
  FROM MST_PARAMETER
  WHERE prm_Cd_1 = 'AB'
  AND prm_cd_2   = '000';
    EXCEPTION
      WHEN OTHERS THEN
        v_error_code :=-5;
        v_error_msg  := SUBSTR('SELECT CTP_CD FROM MST_PARAMETER'||SQLERRM,1,200);
        RAISE v_err;
      END;
      
  IF P_SAVE_CSV  = 'Y' THEN
    BEGIN
         UPDATE T_BOND_TRX_CTP SET xls = 'Y' WHERE trx_date = p_trx_date AND xls = 'N';
     EXCEPTION
      WHEN OTHERS THEN
        v_error_code :=-10;
        v_error_msg  := SUBSTR('UPDATE T_BOND_TRX_CTP SET XLS=Y '||SQLERRM,1,200);
        RAISE v_err;
      END;
  ELSE
  
    FOR rec IN csr_trx
    LOOP
      BEGIN
        SELECT COUNT(1)
        INTO v_cnt
        FROM T_BOND_TRX_CTP
        WHERE upld_date = TRUNC(SYSDATE)
        AND trx_date    = p_trx_date
        AND trx_seq_no  = p_trx_seq_no;
      EXCEPTION
      WHEN OTHERS THEN
        v_error_code :=-20;
        v_error_msg  := SUBSTR('SELECT COUNT T_BOND_TRX_CTP'||SQLERRM,1,200);
        RAISE v_err;
      END;
      
      IF v_cnt = 0 THEN
      
        BEGIN
          INSERT
          INTO T_BOND_TRX_CTP
            (
              UPLD_DATE,
              TRX_DATE,
              TRX_SEQ_NO,
              REPORT_TYPE,
              BUY_SELL_IND,
              BOND_CD,
              TRANS_TYPE,
              FIRM_ID,
              PRICE,
              YIELD,
              NOMINAL,
              TRADE_DATETIME,
              VAS,
              SETTLEMENT_DATE,
              D_PARTY_CD,
              D_REMARKS,
              D_REF,
              D_CUSTODY,
              R_PARTY_CD,
              R_REMARKS,
              R_REF,
              R_CUSTODY,
              RETURN_VALUE,
              RETURN_YIELD,
              REPO_RATE,
              RETURN_DATE,
              LATE_TYPE,
              LATE_REASON,
              CRE_DT,
              USER_ID,
              TRX_ID_YYMM,
              XLS
            )
            VALUES
            (
              TRUNC(SYSDATE) ,
              p_TRX_DATE,
              p_TRX_SEQ_NO,
              rec.REPORT_TYPE,
              rec.trx_type,
              rec.bond_cd,
              rec.ctp_trx_type,
              rec.firm_id,
              rec.price,
              P_yield,
              rec.nominal/1000000000,
              p_TRADE_DATETIME,
              'N',
              rec.value_Dt,
              rec.D_party_cd,
              NULL,
              NULL,
              rec.D_custody,
              rec.R_party_cd ,
              NULL,
              NULL,
              rec.R_custody,
              NULL,
              NULL,
              NULL,
              NULL,
              NULL,
              NULL,
              SYSDATE ,
              p_user_id,
              rec.trx_id_yymm,
              'N');
        EXCEPTION
        WHEN OTHERS THEN
          v_error_code :=-30;
          v_error_msg  := SUBSTR('INSERT T_BOND_TRX_CTP'||SQLERRM(SQLCODE),1,200);
          RAISE v_err;
        END;
        
      ELSE
      
        BEGIN
          UPDATE T_BOND_TRX_CTP
          SET REPORT_TYPE   = rec.REPORT_TYPE,
            BUY_SELL_IND    = rec.trx_type,
            BOND_CD         = rec.bond_cd,
            TRANS_TYPE      = rec.ctp_trx_type,
            FIRM_ID         = rec.firm_id,
            PRICE           = rec.price,
            YIELD           = P_yield,
            NOMINAL         = rec.nominal/1000000000,
            TRADE_DATETIME  = p_TRADE_DATETIME,
            VAS             = 'N',
            SETTLEMENT_DATE = rec.value_Dt,
            D_PARTY_CD      = rec.D_party_cd,
            D_CUSTODY       = rec.D_CUSTODY,
            R_PARTY_CD      = rec.R_party_cd,
            R_CUSTODY       = rec.R_CUSTODY,
            CRE_DT          = SYSDATE,
            USER_ID         = P_user_id,
            TRX_ID_YYMM     = rec.trx_id_yymm,
            XLS             = 'N'
          WHERE upld_date   = TRUNC(SYSDATE)
          AND trx_date      = p_trx_date
          AND trx_seq_no    = p_trx_seq_no;
        EXCEPTION
        WHEN OTHERS THEN
          v_error_code :=-40;
          v_error_msg  := SUBSTR('UPDATE T_BOND_TRX_CTP'||SQLERRM,1,200);
          RAISE v_err;
        END;
      END IF;
    END LOOP;
  END IF;
  
  --COMMIT;
  
  P_error_code:= 1;
  P_error_msg := '';
  
EXCEPTION
WHEN v_err THEN
  P_error_code := v_error_code;
  P_error_msg  := v_error_msg;
  ROLLBACK;
WHEN NO_DATA_FOUND THEN
  NULL;
WHEN OTHERS THEN
  -- Consider logging the error and then re-raise
  ROLLBACK;
  P_error_code := -1;
  P_error_msg  := SUBSTR(SQLERRM,1,200);
  RAISE;
END Sp_Bond_Trx_Ctp;