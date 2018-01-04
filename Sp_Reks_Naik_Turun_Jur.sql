create or replace 
PROCEDURE Sp_Reks_Naik_Turun_Jur(
    p_date DATE,
    p_folder_cd T_ACCOUNT_LEDGER.folder_cd%TYPE,
    p_user_id T_ACCOUNT_LEDGER.user_id%TYPE,
    p_ip_address T_MANY_HEADER.IP_ADDRESS%TYPE,
    p_error_code OUT NUMBER,
    p_error_msg OUT VARCHAR2)
IS
  tmpVar NUMBER;
  /******************************************************************************
  NAME:       SP_REKS_NAIK_TURUN_JUR
  PURPOSE:   generate kenaikan /penurunan reksadana
  REVISIONS:
  Ver        Date        Author           Description
  ---------  ----------  ---------------  ------------------------------------
  1.0        19/08/2011          1. Created this procedure.
  ******************************************************************************/
  CURSOR csr_reks
  IS
    SELECT t.reks_cd,
      reks_name,
      gl_a1,
      sl_a1,
      gl_a2,
      sl_a2,
      nab_unit * t.unit AS new_bal
    FROM
      (SELECT reks_cd,
        reks_name,
        reks_type,
        afiliasi,
        gl_a1,
        sl_a1,
        gl_a2,
        sl_a2,
        SUM(subs -redm) unit
      FROM T_REKS_TRX
      WHERE trx_date   <= p_date
      AND reks_type    <> 'RDPU'
      AND approved_stat = 'A'
      GROUP BY reks_cd,
        reks_name,
        reks_type,
        afiliasi,
        gl_a1,
        sl_a1,
        gl_a2,
        sl_a2
      HAVING SUM(subs -redm) > 0
      ) t,
    (SELECT reks_cd,
      nab_unit,
      nab
    FROM T_REKS_NAB
    WHERE mkbd_dt     = p_date
    AND approved_stat = 'A'
    ) n
  WHERE t.reks_cd = n.reks_cd;
  v_new_bal t_reks_nab.nab%TYPE;
  v_begin_date DATE;
  v_end_date   DATE;
  v_end_bal T_ACCOUNT_LEDGER.curr_val%TYPE;
  v_amount T_ACCOUNT_LEDGER.curr_val%TYPE;
  v_deb_gl_a T_ACCOUNT_LEDGER.gl_acct_cd%TYPE;
  v_deb_sl_a T_ACCOUNT_LEDGER.sl_acct_cd%TYPE;
  v_cre_gl_a T_ACCOUNT_LEDGER.gl_acct_cd%TYPE;
  v_cre_sl_a T_ACCOUNT_LEDGER.sl_acct_cd%TYPE;
  v_ledger_nar T_ACCOUNT_LEDGER.ledger_nar%TYPE;
  v_folder_cd T_ACCOUNT_LEDGER.folder_cd%TYPE;
  v_tal_id T_ACCOUNT_LEDGER.tal_id%TYPE;
  v_doc_num T_ACCOUNT_LEDGER.xn_doc_num%TYPE;
  v_gl_a T_ACCOUNT_LEDGER.gl_acct_cd%TYPE;
  v_sl_a T_ACCOUNT_LEDGER.sl_acct_cd%TYPE;
  v_acct T_ACCOUNT_LEDGER.acct_type%TYPE;
  v_db_cr_flg T_ACCOUNT_LEDGER.db_cr_flg%type;
  v_bal_reks t_account_ledger.curr_val%type;
  v_naikturun t_account_ledger.curr_val%type;
  v_err        EXCEPTION;
  v_error_code NUMBER;
  v_error_msg  VARCHAR2(200);
  v_li_cnt     NUMBER;
  v_tmp_gl_a T_ACCOUNT_LEDGER.gl_acct_cd%TYPE;
  v_tmp_sl_a T_ACCOUNT_LEDGER.sl_acct_cd%TYPE;
  v_folder_flg mst_sys_param.dflg1%type;
  v_rtn NUMBER;
  v_doc_num_folder T_ACCOUNT_LEDGER.xn_doc_num%TYPE;
  v_user_id T_ACCOUNT_LEDGER.user_id%TYPE;
  v_doc_date T_ACCOUNT_LEDGER.doc_date%TYPE;
  
  V_UPDATE_DATE DATE;
  V_UPDATE_SEQ  NUMBER(7);
  V_MENU_NAME   VARCHAR2(50):='NAIK TURUN JURNAL REKSADANA';
BEGIN

  BEGIN
    SELECT dflg1
    INTO v_folder_flg
    FROM mst_sys_param
    WHERE param_id='SYSTEM'
    AND PARAM_CD1 ='VCH_REF';
  EXCEPTION
  WHEN OTHERS THEN
    V_ERROR_CODE := -9;
    V_ERROR_MSG  := SUBSTR('SELECT  count T_REKS_NAB '|| SQLERRM(SQLCODE),1,200);
    RAISE V_ERR;
  END;
  
  BEGIN
    SELECT COUNT(1) INTO v_li_cnt FROM T_REKS_NAB WHERE mkbd_dt =p_date;
  EXCEPTION
  WHEN OTHERS THEN
    V_ERROR_CODE := -11;
    V_ERROR_MSG  := SUBSTR('SELECT  count T_REKS_NAB '|| SQLERRM(SQLCODE),1,200);
    RAISE V_ERR;
  END;
  
  IF v_li_cnt     = 0 THEN
    V_ERROR_CODE := -12;
    V_ERROR_MSG  := 'Batal, NAB belum ada';
    RAISE V_ERR;
  END IF;
  
  v_end_date := p_date;
  
  BEGIN
    SELECT MAX(trs_dt) INTO v_begin_date FROM T_DAY_TRS WHERE trs_dt <= p_date;
  EXCEPTION
  WHEN OTHERS THEN
    V_ERROR_CODE := -10;
    V_ERROR_MSG  := SUBSTR('SELECT  begin_date '|| SQLERRM(SQLCODE),1,200);
    RAISE V_ERR;
  END;
  
  -- MU gl=3500 , sl=000000  ,
  --di YJ gl= 5510 , sl=000000  juga krn utk test , utk prod YJ blm tau mau diisi apa nanti
  BEGIN
    SELECT dstr1,
      dstr2
    INTO v_gl_a,
      v_sl_a
    FROM MST_SYS_PARAM
    WHERE param_id='REKSADANA'
    AND param_cd1 ='GL_SL';
  EXCEPTION
  WHEN OTHERS THEN
    V_ERROR_CODE := -20;
    V_ERROR_MSG  := SUBSTR('SELECT MST_SYS_PARAM GL_SL '|| SQLERRM(SQLCODE),1,200);
    RAISE V_ERR;
  END;
  
  -- Masih blm tau v_acct isi apa , jadi default NULL seperti sebelumnya
  --  BEGIN
  --  SELECT dstr1 INTO v_acct
  --  FROM MST_SYS_PARAM
  --  WHERE param_id='REKSADANA' and param_cd1='ACCT';
  -- EXCEPTION
  --      WHEN OTHERS THEN
  --          V_ERROR_CODE := 30;
  --          V_ERROR_MSG := SUBSTR('SELECT MST_SYS_PARAM ACCT '|| SQLERRM(SQLCODE),1,200);
  --          RAISE V_ERR;
  --      END;
  
  v_acct:=NULL;
  
  FOR rec IN csr_reks
  LOOP
    v_new_bal := rec.new_bal;
    BEGIN
      SELECT SUM(bal) end_bal
      INTO v_end_bal
      FROM
        (SELECT sl_acct_cd,
          deb_obal - cre_obal AS bal
        FROM T_DAY_TRS
        WHERE trs_dt          = v_begin_date
        AND trim(gl_acct_cd) IN (rec.gl_a1,rec.gl_a2)
        AND sl_acct_cd       IN (rec.sl_a1,rec.sl_a2)
        UNION ALL
        SELECT sl_acct_cd,
          DECODE(db_cr_flg,'D',1,-1) * curr_val
        FROM T_ACCOUNT_LEDGER
        WHERE doc_date BETWEEN v_begin_date AND v_end_date
        AND (trim(gl_acct_cd) = trim(rec.gl_a1)
        OR trim(gl_acct_cd)   = trim(rec.gl_a2))
        AND (trim(sl_acct_cd) = trim(rec.sl_a1)
        OR trim(sl_acct_cd)   = trim(rec.sl_a2))
        AND approved_sts      = 'A'
        );
    EXCEPTION
    WHEN OTHERS THEN
      V_ERROR_CODE := -40;
      V_ERROR_MSG  := SUBSTR('SELECT end_bal '|| SQLERRM(SQLCODE),1,200);
      RAISE V_ERR;
    END;
    v_amount := ABS(v_end_bal - v_new_bal);
    ---------
    IF v_end_bal   <> v_new_bal AND v_new_bal <> 0 THEN
      IF v_new_bal  > v_end_bal THEN
        v_deb_gl_a := rec.gl_a2;
        v_deb_sl_a := rec.sl_a2;
        --  v_cre_gl_a := '5510';
        --  v_cre_sl_a := '000000';
        v_cre_gl_a   := v_gl_a;
        v_cre_sl_a   :=v_sl_a;
        v_ledger_nar := 'Kenaikan NAB Reksadana '||TO_CHAR(p_date,'dd/mm/yy');
      ELSE
        --  v_deb_gl_a := '5510';
        -- v_deb_sl_a := '000000';
        v_deb_gl_a   := v_gl_a;
        v_deb_sl_a   := v_sl_a;
        v_cre_gl_a   := rec.gl_a2;
        v_cre_sl_a   := rec.sl_a2;
        v_ledger_nar := 'Penurunan NAB Reksadana '||TO_CHAR(p_date,'dd/mm/yy');
      END IF;
      v_doc_num   := Get_Docnum_GL(p_Date,'GL');
      v_folder_cd := p_folder_cd;
	  
	  --11MARET2016
  --EXECUTE T MANY HEADER
  BEGIN
    Sp_T_Many_Header_Insert(V_MENU_NAME, 'I', P_USER_ID, P_IP_ADDRESS, NULL, V_UPDATE_DATE, V_UPDATE_SEQ, v_error_code, v_error_msg);
  EXCEPTION
  WHEN OTHERS THEN
    v_error_code := -110;
    v_error_msg  := SUBSTR('SP_T_MANY_HEADER_INSERT '|| SQLERRM(SQLCODE),1,200);
    RAISE V_ERR;
  END;
  
  IF V_ERROR_CODE <0 THEN
    v_error_code := -120;
    v_error_msg  :=SUBSTR('Sp_T_Many_Header_Insert : '||SQLERRM(SQLCODE),1,200);
    RAISE v_err;
  END IF;
  
   
  --INSERT KE T_MANY
  BEGIN
    Sp_T_Jvchh_Upd(v_doc_num, v_doc_num, 'GL', p_date, NULL, NULL, 'IDR', v_amount, v_ledger_nar, P_USER_ID, SYSDATE, NULL, v_folder_cd, 'N', 'I', p_ip_address, NULL, V_UPDATE_DATE, V_UPDATE_SEQ, 1, v_error_code, v_error_msg);
  EXCEPTION
  WHEN OTHERS THEN
    v_error_code := -240;
    v_error_msg  :=SUBSTR('Sp_T_JVCHH_Upd: '||v_doc_num||' '||SQLERRM,1,200);
    RAISE v_err;
  END;
  
  IF V_ERROR_CODE <0 THEN
    v_error_code := -250;
    v_error_msg  :=SUBSTR('Sp_T_JVCHH_Upd : '||v_doc_num||' '||SQLERRM,1,200);
    RAISE v_err;
  END IF;
  
  
	--END 11MARET2016  
	  /*
      BEGIN
        INSERT
        INTO T_JVCHH
          (
            JVCH_NUM,
            JVCH_TYPE,
            JVCH_DATE,
            GL_ACCT_CD,
            SL_ACCT_CD,
            CURR_CD,
            CURR_AMT,
            REMARKS,
            USER_ID,
            CRE_DT,
            UPD_DT,
            APPROVED_STS,
            APPROVED_BY,
            APPROVED_DT,
            FOLDER_CD
          )
          VALUES
          (
            v_doc_num,
            'GL',
            p_date,
            NULL,
            NULL,
            'IDR',
            v_amount,
            v_ledger_nar,
            p_user_id,
            SYSDATE,
            NULL,
            'A',
            NULL,
            SYSDATE,
            v_folder_cd
          );
      EXCEPTION
      WHEN OTHERS THEN
        --RAISE_APPLICATION_ERROR(-20100,'insert T_JVCHH  '||v_doc_num||SQLERRM);
        V_ERROR_CODE := -50;
        V_ERROR_MSG  := SUBSTR('insert T_JVCHH '|| SQLERRM(SQLCODE),1,200);
        RAISE V_ERR;
      END;
      */
      IF v_folder_flg = 'Y' THEN
      
        BEGIN
          SP_CHECK_FOLDER_CD ( v_folder_cd, p_date, v_rtn, v_doc_num_folder, v_user_id, v_doc_date);
        EXCEPTION
        WHEN OTHERS THEN
          --RAISE_APPLICATION_ERROR(-20100,'insert T_JVCHH  '||v_doc_num||SQLERRM);
          V_ERROR_CODE := -52;
          V_ERROR_MSG  := SUBSTR('SP_CHECK_FOLDER_CD '|| SQLERRM(SQLCODE),1,200);
          RAISE V_ERR;
        END;
        
        IF v_rtn        =1 THEN
          V_ERROR_CODE := -52;
          V_ERROR_MSG  := 'Folder Code '||v_folder_cd||' is already used by '||v_user_id ||' '||v_doc_num_folder ||' '||v_doc_date;
          RAISE V_ERR;
        END IF;
        
        BEGIN
          INSERT
          INTO T_FOLDER
            (
              FLD_MON,
              FOLDER_CD,
              DOC_DATE,
              DOC_NUM,
              USER_ID,
              CRE_DT,
              UPD_DT
            )
            VALUES
            (
              TO_CHAR(p_date,'ddmm'),
              v_folder_cd,
              p_date,
              v_doc_num,
              p_user_id,
              SYSDATE,
              NULL
            );
        EXCEPTION
        WHEN OTHERS THEN
          --RAISE_APPLICATION_ERROR(-20100,'insert T_FOLDER  '||v_doc_num||SQLERRM);
          V_ERROR_CODE := -60;
          V_ERROR_MSG  := SUBSTR('insert T_FOLDER '|| SQLERRM(SQLCODE),1,200);
          RAISE V_ERR;
        END;
      END IF;
      
      FOR v_seqno IN 1..2
      LOOP
      
        IF v_seqno     = 1 THEN
          v_db_cr_flg := 'D';
          v_tmp_gl_a  := v_deb_gl_a;
          v_tmp_sl_a  :=v_deb_sl_a;
        ELSE
          v_db_cr_flg := 'C';
          v_tmp_gl_a  := v_cre_gl_a;
          v_tmp_sl_a  :=v_cre_sl_a;
        END IF;
        
        BEGIN
          Gen_Trx_Jur_Line_Nextg(v_doc_num, NULL, p_date, p_date, p_date, v_seqno, v_acct, v_tmp_gl_a, v_tmp_sl_a, v_db_cr_flg, v_amount, v_ledger_nar, 'IDR', NULL, NULL, v_folder_cd, 'GL', 'A', p_user_id, 'N', v_error_code, v_error_msg);
        EXCEPTION
        WHEN OTHERS THEN
          V_ERROR_CODE := -70;
          V_ERROR_MSG  := SUBSTR('Gen_Trx_Jur_Line_Nextg '|| SQLERRM(SQLCODE),1,200);
          RAISE V_ERR;
        END;
        
        IF V_ERROR_CODE < 0 THEN
          V_ERROR_CODE := v_error_code;
          V_ERROR_MSG  := v_error_msg;
          RAISE V_ERR;
        END IF;
        
      END LOOP;
    END IF;
	
	--APPROVE JURNAL PERTAMA
  BEGIN
    Sp_T_Many_Approve( V_MENU_NAME, V_update_date, V_UPDATE_SEQ, p_user_id, p_ip_address, v_error_code, v_error_msg);
  EXCEPTION
  WHEN OTHERS THEN
    v_error_code := -260;
    v_error_msg  :=SUBSTR('Sp_T_Many_Approve: '||SQLERRM,1,200);
    RAISE v_err;
  END;
  
    -------
    IF v_end_bal <> v_new_bal AND v_new_bal = 0 THEN
      SELECT SUM(DECODE(trim(gl_acct_cd),rec.gl_a1,bal,0)) bal_reks,
        SUM(DECODE(trim(gl_acct_cd),rec.gl_a2,bal,0)) bal_naikturun
      INTO v_bal_reks,
        v_naikturun
      FROM
        (SELECT gl_acct_cd,
          sl_acct_cd,
          deb_obal - cre_obal AS bal
        FROM T_DAY_TRS
        WHERE trs_dt          = v_begin_date
        AND trim(gl_acct_cd) IN (rec.gl_a1,rec.gl_a2)
        AND sl_acct_cd       IN (rec.sl_a1,rec.sl_a2)
        UNION ALL
        SELECT gl_acct_cd,
          sl_acct_cd,
          DECODE(db_cr_flg,'D',1,-1) * curr_val
        FROM T_ACCOUNT_LEDGER
        WHERE doc_date BETWEEN v_begin_date AND v_end_date
        AND (trim(gl_acct_cd) = trim(rec.gl_a1)
        OR trim(gl_acct_cd)   = trim(rec.gl_a2))
        AND (trim(sl_acct_cd) = trim(rec.sl_a1)
        OR trim(sl_acct_cd)   = trim(rec.sl_a2))
        AND approved_sts      = 'A'
        );
      v_doc_num  := Get_Docnum_GL(p_Date,'GL');
      v_folder_cd:=p_folder_cd;
      ---
      v_tal_id      :=1;
      v_deb_gl_a    := rec.gl_a1;
      v_deb_sl_a    := rec.sl_a1;
      IF v_bal_reks  < 0 THEN
        v_db_cr_flg := 'D';
      ELSE
        v_db_cr_flg := 'C';
      END IF;
      v_amount     := ABS(v_bal_reks);
      v_ledger_nar := 'Penjualan '||rec.reks_name;
      
	  
	    
	  --11MARET2016
  --EXECUTE T MANY HEADER
  BEGIN
    Sp_T_Many_Header_Insert(V_MENU_NAME, 'I', P_USER_ID, P_IP_ADDRESS, NULL, V_UPDATE_DATE, V_UPDATE_SEQ, v_error_code, v_error_msg);
  EXCEPTION
  WHEN OTHERS THEN
    v_error_code := -110;
    v_error_msg  := SUBSTR('SP_T_MANY_HEADER_INSERT '|| SQLERRM(SQLCODE),1,200);
    RAISE V_ERR;
  END;
  
  IF V_ERROR_CODE <0 THEN
    v_error_code := -120;
    v_error_msg  :=SUBSTR('Sp_T_Many_Header_Insert : '||SQLERRM(SQLCODE),1,200);
    RAISE v_err;
  END IF;
  
   
  --INSERT KE T_MANY
  BEGIN
    Sp_T_Jvchh_Upd(v_doc_num, v_doc_num, 'GL', p_date, NULL, NULL, 'IDR', v_amount, v_ledger_nar, P_USER_ID, SYSDATE, NULL, v_folder_cd, 'N', 'I', p_ip_address, NULL, V_UPDATE_DATE, V_UPDATE_SEQ, 1, v_error_code, v_error_msg);
  EXCEPTION
  WHEN OTHERS THEN
    v_error_code := -240;
    v_error_msg  :=SUBSTR('Sp_T_JVCHH_Upd: '||v_doc_num||' ' ||SQLERRM,1,200);
    RAISE v_err;
  END;
  
  IF V_ERROR_CODE <0 THEN
    v_error_code := -250;
    v_error_msg  :=SUBSTR('Sp_T_JVCHH_Upd : '||v_doc_num||' '||SQLERRM,1,200);
    RAISE v_err;
  END IF;
	  
	  /*
      BEGIN
        INSERT
        INTO T_JVCHH
          (
            JVCH_NUM,
            JVCH_TYPE,
            JVCH_DATE,
            GL_ACCT_CD,
            SL_ACCT_CD,
            CURR_CD,
            CURR_AMT,
            REMARKS,
            USER_ID,
            CRE_DT,
            UPD_DT,
            APPROVED_STS,
            APPROVED_BY,
            APPROVED_DT,
            FOLDER_CD
          )
          VALUES
          (
            v_doc_num,
            'GL',
            p_date,
            NULL,
            NULL,
            'IDR',
            v_amount,
            v_ledger_nar,
            p_user_id,
            SYSDATE,
            NULL,
            'A',
            NULL,
            NULL,
            v_folder_cd
          );
      EXCEPTION
      WHEN OTHERS THEN
        --RAISE_APPLICATION_ERROR(-20100,'insert T_JVCHH  '||v_doc_num||SQLERRM);
        V_ERROR_CODE := -80;
        V_ERROR_MSG  := SUBSTR('insert T_JVCHH '|| SQLERRM(SQLCODE),1,200);
        RAISE V_ERR;
      END;
      */
      IF v_folder_flg = 'Y' THEN
        BEGIN
          SP_CHECK_FOLDER_CD ( v_folder_cd, p_date, v_rtn, v_doc_num_folder, v_user_id, v_doc_date);
        EXCEPTION
        WHEN OTHERS THEN
          --RAISE_APPLICATION_ERROR(-20100,'insert T_JVCHH  '||v_doc_num||SQLERRM);
          V_ERROR_CODE := -85;
          V_ERROR_MSG  := SUBSTR('SP_CHECK_FOLDER_CD '|| SQLERRM(SQLCODE),1,200);
          RAISE V_ERR;
        END;
        IF v_rtn        =1 THEN
          V_ERROR_CODE := -90;
          V_ERROR_MSG  := 'Folder Code '||v_folder_cd||' is already used by '||v_user_id ||' '||v_doc_num_folder ||' '||v_doc_date;
          RAISE V_ERR;
        END IF;
        
        BEGIN
          INSERT
          INTO T_FOLDER
            (
              FLD_MON,
              FOLDER_CD,
              DOC_DATE,
              DOC_NUM,
              USER_ID,
              CRE_DT,
              UPD_DT
            )
            VALUES
            (
              TO_CHAR(p_date,'ddmm'),
              v_folder_cd,
              p_date,
              v_doc_num,
              p_user_id,
              SYSDATE,
              NULL
            );
        EXCEPTION
        WHEN OTHERS THEN
          --RAISE_APPLICATION_ERROR(-20100,'insert T_FOLDER  '||v_doc_num||SQLERRM);
          V_ERROR_CODE := -100;
          V_ERROR_MSG  := SUBSTR('insert T_FOLDER '|| SQLERRM(SQLCODE),1,200);
          RAISE V_ERR;
        END;
        
      END IF;
      
      BEGIN
        Gen_Trx_Jur_Line_Nextg(v_doc_num, NULL, p_date, p_date, p_date, v_tal_id, v_acct, v_deb_gl_a, v_deb_sl_a, v_db_cr_flg, v_amount, v_ledger_nar, 'IDR', NULL, NULL, v_folder_cd, 'GL', 'A', p_user_id, 'N', v_error_code, v_error_msg);
      EXCEPTION
      WHEN OTHERS THEN
        V_ERROR_CODE := -100;
        V_ERROR_MSG  := SUBSTR('Gen_Trx_Jur_Line_Nextg '|| SQLERRM(SQLCODE),1,200);
        RAISE V_ERR;
      END;
      IF V_ERROR_CODE < 0 THEN
        V_ERROR_CODE := v_error_code;
        V_ERROR_MSG  := v_error_msg;
        RAISE V_ERR;
      END IF;
      ---
      v_tal_id      := 2;
      v_deb_gl_a    := rec.gl_a2;
      v_deb_sl_a    := rec.sl_a2;
      
      IF v_naikturun < 0 THEN
        v_db_cr_flg := 'D';
      ELSE
        v_db_cr_flg := 'C';
      END IF;
      v_amount := ABS(v_naikturun);
      
      BEGIN
        Gen_Trx_Jur_Line_Nextg(v_doc_num, NULL, p_date, p_date, p_date,                                                                          --p_arap_due_date
        v_tal_id, v_acct, v_deb_gl_a, v_deb_sl_a, v_db_cr_flg, v_amount, v_ledger_nar, 'IDR', NULL, NULL, v_folder_cd, 'GL', 'A', p_user_id, 'N',--manual
        v_error_code, v_error_msg);
      EXCEPTION
      WHEN OTHERS THEN
        V_ERROR_CODE := -70;
        V_ERROR_MSG  := SUBSTR('Gen_Trx_Jur_Line_Nextg '|| SQLERRM(SQLCODE),1,200);
        RAISE V_ERR;
      END;
      IF V_ERROR_CODE < 0 THEN
        V_ERROR_CODE := v_error_code;
        V_ERROR_MSG  := v_error_msg;
        RAISE V_ERR;
      END IF;
      ---
      v_tal_id      := 3;
      v_deb_gl_a    := v_gl_a;
      v_deb_sl_a    := v_sl_a;
      IF v_end_bal   < 0 THEN
        v_db_cr_flg := 'C';
      ELSE
        v_db_cr_flg := 'D';
      END IF;
      
      v_amount := ABS(v_end_bal);
      
      BEGIN
        Gen_Trx_Jur_Line_Nextg(v_doc_num, NULL, p_date, p_date, p_date,                                                                          --p_arap_due_date
        v_tal_id, v_acct, v_deb_gl_a, v_deb_sl_a, v_db_cr_flg, v_amount, v_ledger_nar, 'IDR', NULL, NULL, v_folder_cd, 'GL', 'A', p_user_id, 'N',--manual
        v_error_code, v_error_msg);
      EXCEPTION
      WHEN OTHERS THEN
        V_ERROR_CODE := -70;
        V_ERROR_MSG  := SUBSTR('Gen_Trx_Jur_Line_Nextg '|| SQLERRM(SQLCODE),1,200);
        RAISE V_ERR;
      END;
      
      IF V_ERROR_CODE < 0 THEN
        V_ERROR_CODE := v_error_code;
        V_ERROR_MSG  := v_error_msg;
        RAISE V_ERR;
      END IF;
      
	  	--APPROVE JURNAL KEDUA
  BEGIN
    Sp_T_Many_Approve( V_MENU_NAME, V_update_date, V_UPDATE_SEQ, p_user_id, p_ip_address, v_error_code, v_error_msg);
  EXCEPTION
  WHEN OTHERS THEN
    v_error_code := -260;
    v_error_msg  :=SUBSTR('Sp_T_Many_Approve: '||SQLERRM,1,200);
    RAISE v_err;
  END;
	  
	  
    END IF;
  END LOOP;
  p_error_code :=1;
  p_error_msg  :='';
  
EXCEPTION
WHEN NO_DATA_FOUND THEN
  NULL;
WHEN v_err THEN
  ROLLBACK;
  p_error_code := v_error_code;
  p_error_msg  :=v_error_msg;
WHEN OTHERS THEN
  ROLLBACK;
  p_error_code :=-1;
  p_error_msg  :=SUBSTR(SQLERRM,1,200);
  RAISE;
END Sp_Reks_Naik_Turun_Jur;