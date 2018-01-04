create or replace PROCEDURE Sp_Xfertostkhand_Nextg(
    p_sett_date IN DATE,
    p_contr_num IN T_CONTRACTS.contr_num%TYPE,
    p_entry_qty IN T_STKHAND.ON_HAND%TYPE,
    p_option in VARCHAR2,--UNTUK MENANDAI ALL TRANSACTION='A' DAN SELECTED TRANSACTION='S'
    p_user_id   IN T_STK_MOVEMENT.user_id%TYPE,
  P_IP_ADDRESS IN T_MANY_HEADER.IP_ADDRESS%TYPE,
    p_error_code OUT NUMBER,
    p_error_msg OUT VARCHAR2 )
AS
--18sep2017 [indra] tambah client_cd,option ke t_many_header
-- 8 DEC 2016 koreksi SELECTED Jual, jika p_entry_qty > (qty - sett_qty)
  --24nov2016, cek sett_qty dari aplikasi apakah sama dengan yang di kursor
  --             utk mnghindari 2x disettle
  -- 1jul15 dipersiapkan utk NEXTG
  --22apr15 memakai SP secu jurnal_nextg spy mengisi field MANUAL, approv stat, jur type
  --                 memakai SP get secu acct utk mengambil gl acct berdasarkan jur-type
  -- 6feb15 - rubah utk transaksi TS
  --21oct14 pakai GET STK JURNUM .didlmnya pakai SEQuence SEQ STK JUR
  -- 8aug14 utk change ticker
  -- reverse stk tdk berpengaruh di proses ini sejak withdraw jurnal baru ada wkt
  --   distribution date.  Qty di FO, berubah berdasarkan T cor act fo
  -- 8Juli 2013 Margin ke subrek 001
  --mulai dipakai 120oct11
  -- 21jan11 - dirubah utk menangani  reverse stk
  -- trx yg stknya direverse dan  due date kpei nya (disettlenya) diantara X date dan recording date,
  -- jika trx buy, jurnal settle spt biasa, hanya qty nya adalah  qty sesudah direverse
  --   krn pd X date sudah dibuat kebalikan jurnal beli BRR, sebnyak qty yg dikurangkan dr buy qty .
  --         spy di lap porto tampil qty yg blm direverse, mk dibuat dummy jurnal  doc_stat = '9'
  --         dg gl_acct_cd = 'RR', credit sebanyak qty yg dikurangkan dr buy qty
  -- jika trx sell, jurnal settle spt biasa, hanya qty nya adalah  qty sesudah direverse
  --   krn pd X date sudah dibuat kebalikan jurnal jual JRR, sebnyak qty yg dikurangkan dr sellqty .
  --         spy di lap porto tampil qty yg blm direverse, mk dibuat dummy jurnal  doc_stat = '9'
  --         dg gl_acct_cd = 'RR', debit sebanyak qty yg dikurangkan dr sell qty yg disettle
  v_bgn_dt DATE;
  v_rec T_CONTRACTS%ROWTYPE;
  v_table_rowid         T_MANY_DETAIL.table_rowid%TYPE;
  V_upd_status VARCHAR2(1) :='X';
  v_MANY_DETAIL  Types.MANY_DETAIL_rc;
  v_menu_name T_MANY_HEADER.MENU_NAME%TYPE :='UPDATE STOCK ON HAND';
  V_UPDATE_DATE DATE;
  V_UPDATE_SEQ T_MANY_HEADER.UPDATE_SEQ%TYPE;
  V_RECORD_sEQ NUMBER(5);
  
  
  CURSOR CONTR_BUY
  IS
    SELECT t.*, r.stk_cd_new
    FROM T_CONTRACTS t,
        ( select stk_cd_old, stk_cd_new
            from T_CHANGE_STK_CD
            where eff_Dt <= p_sett_date) r
    WHERE t.contr_dt BETWEEN v_bgn_dt AND p_sett_date
    AND ( t.contr_num           = p_contr_num
    OR p_contr_num              = '%')
    AND SUBSTR(t.contr_num,5,1) = 'B'
      --AND t.contr_num ='0415BR0173384'
    AND t.contr_stat      = '0'
    AND record_source    <> 'IB' -- broker trx titipan
    AND t.due_dt_for_cert = p_sett_date
    AND NVL(t.sett_qty,0) < qty
    AND t.stk_cd          = r.stk_cd_old (+)
    ORDER BY client_cd;
  --     8aug14  SELECT t.*, NVL(r.from_qty,0) from_qty, NVL(r.to_qty,0) to_qty, r.distrib_dt
  --    FROM T_CONTRACTS t,
  --       (SELECT stk_cd, ca_type, from_Qty, to_qty, distrib_dt
  --                 FROM T_CORP_ACT
  --     WHERE CA_TYPE = 'REVERSE'
  --     AND   ad_sett_date BETWEEN x_dt AND recording_dt ) r
  --       WHERE t.contr_stat = '0'
  --    AND SUBSTR(t.contr_num,5,1) = 'B'
  --    AND record_source <> 'IB' -- broker trx titipan
  --       AND  t.due_dt_for_cert  = ad_sett_date
  --    AND NVL(t.sett_qty,0) = 0
  --       AND t.stk_cd = r.stk_cd (+);
  
  CURSOR CONTR_SELL
  IS
    SELECT t.*, r.stk_cd_new
    FROM T_CONTRACTS t,
        ( select stk_cd_old, stk_cd_new
            from T_CHANGE_STK_CD
            where eff_Dt <= p_sett_date) r
    WHERE t.contr_dt BETWEEN v_bgn_dt AND p_sett_date
    AND ( t.contr_num           = p_contr_num
    OR p_contr_num              = '%')
    AND SUBSTR(t.contr_num,5,1) = 'J'
      --AND t.contr_num ='0415JR0173986'
    AND t.contr_stat      = '0'
    AND record_source    <> 'IB' -- broker trx titipan
    AND t.due_dt_for_cert = p_sett_date
    AND NVL(t.sett_qty,0) < qty
    AND t.stk_cd          = r.stk_cd_old (+)
    ORDER BY client_Cd;
  -- 8aug14       SELECT t.*, NVL(r.from_qty,0) from_qty, NVL(r.to_qty,0) to_qty, r.distrib_dt
  --    FROM T_CONTRACTS t,
  --       (SELECT stk_cd, ca_type, from_Qty, to_qty, distrib_dt
  --                 FROM T_CORP_ACT
  --     WHERE CA_TYPE = 'REVERSE'
  --     AND   ad_sett_date BETWEEN x_dt AND recording_dt ) r
  --       WHERE t.contr_stat = '0'
  --    AND SUBSTR(t.contr_num,5,1) = 'J'
  --    AND record_source <> 'IB' -- broker trx titipan
  --       AND  t.due_dt_for_cert  = ad_sett_date
  --    AND NVL(t.sett_qty,0) = 0
  --       AND t.stk_cd = r.stk_cd (+);

  v_err        EXCEPTION;
  v_error_code NUMBER;
  v_error_msg  VARCHAR2(1000);
  vs_docnum T_STK_MOVEMENT.doc_num%TYPE;
  --vs_gl_acct_cd  T_STK_MOVEMENT.gl_acct_cd%TYPE;
  v_deb_acct T_STK_MOVEMENT.gl_acct_cd%TYPE;
  v_cre_acct T_STK_MOVEMENT.gl_acct_cd%TYPE;
  V_OHQTY T_STKHAND.ON_HAND%TYPE;
  V_SETT_SELL T_STKHAND.ON_HAND%TYPE;
  vstk_scripless MST_COUNTER.stk_scripless%TYPE;
  v_coy_client_cd MST_CLIENT.client_cd%TYPE;
  v_withdraw_reason_cd T_STK_MOVEMENT.withdraw_reason_cd%TYPE;
  v_jur_qty T_STKHAND.ON_HAND%TYPE;
  v_bal_qty_old T_STKHAND.BAL_QTY%TYPE;
  v_stk_cd T_STK_MOVEMENT.stk_cd%TYPE;
  v_lot T_STK_MOVEMENT.total_lot%TYPE;
  v_odd_lot_doc T_STK_MOVEMENT.odd_lot_doc%TYPE;
  v_lot_size MST_COUNTER.lot_size%TYPE;
  v_jur_type T_STK_MOVEMENT.jur_type%TYPE;
  v_Client_type MST_SECU_ACCT.CLIENT_TYPE%TYPE;
  
  v_cnt      NUMBER;
  v_jur      NUMBER;
  v_seq1     NUMBER;
  v_seq2     NUMBER;
  v_cnt_buy  NUMBER;
  v_cnt_sell NUMBER;
  v_margin_acct T_STK_MOVEMENT.gl_acct_cd%TYPE;
  V_Bgn_Mon Date;
  v_db_cr_flg t_account_ledger.db_cr_flg%type;
  v_gl_acct_cd  T_STK_MOVEMENT.GL_ACCT_CD%TYPE;
  v_table_name        T_MANY_DETAIL.table_name%TYPE := 'T_CONTRACTS';
  v_status                T_MANY_DETAIL.upd_status%TYPE;
  

BEGIN

  --delete C_STKHAND_UPD_BFR
  IF p_option ='A' THEN
    BEGIN
      DELETE FROM C_STKHAND_UPD_BFR ; 
    EXCEPTION
    WHEN OTHERS THEN
      v_error_code := -5;
      v_error_msg  := SUBSTR('DELETE C_STKHAND_UPD_BFR '||SQLERRM,1,200);
      RAISE v_err;
    End;
    
    BEGIN
      DELETE FROM C_STKHAND_UPD_AFT ; 
    EXCEPTION
    WHEN OTHERS THEN
      v_error_code := -6;
      v_error_msg  := SUBSTR('DELETE C_STKHAND_UPD_AFT '||SQLERRM,1,200);
      RAISE v_err;
    End;
  END IF;
  
  -- cek beginning balance
  V_Bgn_Mon := P_Sett_Date - To_Number(To_Char(P_Sett_Date,'dd')) + 1;
  
  BEGIN
    SELECT stk_cd
    INTO v_stk_cd
    FROM T_STKBAL
    WHERE bal_dt = v_bgn_mon
    AND ROWNUM   = 1;
  EXCEPTION
  WHEN NO_DATA_FOUND THEN
    v_error_code := -10;
    v_error_msg  := 'BEGINNING BALANCE belum diproses !';
    RAISE v_err;
  WHEN OTHERS THEN
    v_error_code := -20;
    v_error_msg  := SUBSTR('Retrieve  T_STKBAL  '||SQLERRM,1,200);
    RAISE v_err;
  End;
  
  v_cnt      := 1;
  v_cnt_buy  := 0;
  v_cnt_sell := 0;
  V_Bgn_Dt   := Get_Doc_Date(5, P_Sett_Date);
  
  BEGIN
    SELECT trim(NVL(other_1,'X')) INTO v_coy_client_cd FROM MST_COMPANY;
  EXCEPTION
  WHEN NO_DATA_FOUND THEN
    v_error_code := -30;
    v_error_msg  := SUBSTR('Retrieve  MST COMPANY '||SQLERRM,1,200);
    RAISE v_err;
  WHEN OTHERS THEN
    v_error_code := -40;
    v_error_msg  := SUBSTR('Retrieve  MST COMPANY '||SQLERRM,1,200);
    RAISE v_err;
  End;
  
  --    BEGIN
  --    SELECT dstr1 INTO v_margin_acct
  --    FROM MST_SYS_PARAM
  --    WHERE param_id = 'SYSTEM'
  --    AND   param_cd1 = 'MARGIN'
  --    AND   param_cd2 = 'SECULDG'
  --    AND p_sett_date BETWEEN ddate1 AND ddate2;
  --    EXCEPTION
  --    WHEN NO_DATA_FOUND THEN
  --     v_error_code := -4;
  --     v_error_msg :=  SUBSTR('Retrieve  MST SYS PARAM '||SQLERRM,1,200);
  --     RAISE v_err;
  --    WHEN OTHERS THEN
  --     v_error_code := -5;
  --     v_error_msg :=  SUBSTR('Retrieve  MST SYS PARAM '||SQLERRM,1,200);
  --     RAISE v_err;
  --    END;
  
  
  BEGIN
    SP_T_MANY_HEADER_INSERT ( v_menu_name,
                             'I',
                             p_user_id,
                             p_ip_address,
                             null,
                             v_update_date,
                             v_update_seq,
                             v_error_code,
                             v_error_msg);
  exception
  WHEN OTHERS THEN
    v_error_code := -40;
    v_error_msg  := SUBSTR('Retrieve  MST COMPANY '||SQLERRM,1,200);
    RAISE v_err;
  End;
  
  
  V_RECORD_sEQ :=1;
  For C1 In Contr_Buy  Loop
  
  
  --24nov2016, cek sett_qty dari aplikasi apakah sama dengan yang di kursor
    IF p_option ='S' AND (c1.qty - nvl(c1.sett_qty,0)) <> p_entry_qty THEN
     v_error_code := -42;
        v_error_msg  := 'Settle quantity not equal with transaction displayed';
        RAISE v_err;
    END IF;
  
  --BACKUP T_STKHAND
  
    IF c1.stk_cd_new IS NOT NULL THEN
      v_stk_Cd       :=c1.stk_cd_new;
    ELSE
      v_stk_Cd :=c1.stk_cd;
    End If;
  
  BEGIN
  INSERT INTO C_STKHAND_UPD_BFR 
    SELECT A.*, C1.CONTR_NUM FROM T_STKHAND A WHERE STK_CD = V_Stk_Cd AND CLIENT_CD = C1.CLIENT_CD ; 
    EXCEPTION
  WHEN OTHERS THEN
    v_error_code := -42;
    v_error_msg  := SUBSTR('INSERT C_STKHAND_UPD_BFR '||SQLERRM,1,200);
    RAISE v_err;
  End;  
  
    V_Cnt_Buy := V_Cnt_Buy + 1;
    
    BEGIN
      SELECT lot_size INTO v_lot_size FROM MST_COUNTER WHERE stk_cd = c1.stk_cd;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      v_error_code := -50;
      v_error_msg  := SUBSTR('Retrieve  MST_COUNTER '||SQLERRM,1,200);
      RAISE v_err;
    WHEN OTHERS THEN
      v_error_code := -60;
      v_error_msg  := SUBSTR('Retrieve  MST_COUNTER '||SQLERRM,1,200);
      RAISE v_err;
    End;
    
    IF P_OPTION = 'A' THEN
      V_Jur_Qty        := C1.Qty - nvl(c1.sett_qty,0);
    ELSE
      V_Jur_Qty :=P_ENTRY_QTY;
    END IF;
    
  
    if v_jur_qty <> 0 then
  

  --INSERT INTO T_MANY_DETAIL
  OPEN v_MANY_DETAIL FOR
    SELECT v_update_date AS update_date, v_update_seq AS update_seq, table_name, V_RECORD_sEQ AS record_seq, v_table_rowid AS table_rowid, a.field_name,  field_type, b.field_value, V_upd_status AS status,  b.upd_flg
    FROM(
      SELECT  v_table_name AS table_name, column_name AS field_name, DECODE(data_type,'VARCHAR2','S','CHAR','S','NUMBER','N','DATE','D','X') AS field_type
      FROM all_tab_columns
      WHERE table_name = v_table_name
      UNION
       SELECT v_table_name, 'DUE_DATE', 'D' FROM dual
       UNION
       SELECT v_table_name, 'OPTION', 'S' FROM dual
      ) a,
    ( 
      SELECT  'DUE_DATE'  AS field_name, TO_CHAR(P_Sett_Date,'yyyy/mm/dd hh24:mi:ss')  AS field_value, 'X' upd_flg FROM dual
      UNION
        SELECT  'CONTR_NUM'  AS field_name,  TO_CHAR(C1.CONTR_NUM) AS field_value, 'X' upd_flg FROM dual
        UNION 
        SELECT  'CLIENT_CD'  AS field_name,  TO_CHAR(C1.CLIENT_CD) AS field_value, 'X' upd_flg FROM dual
        UNION
        SELECT  'OPTION'  AS field_name,  DECODE(P_OPTION,'A','ALL','SELECTED') AS field_value, 'X' upd_flg FROM dual
    ) b
    WHERE a.field_name = b.field_name;
    BEGIN
    Sp_T_MANY_DETAIL_Insert(v_update_date,   v_update_seq,   V_UPD_STATUS,v_table_name, V_RECORD_sEQ , v_table_rowid, v_MANY_DETAIL, v_error_code, v_error_msg);
  EXCEPTION
    WHEN OTHERS THEN
      v_error_code := -61;
      v_error_msg := SUBSTR('SP_T_MANY_DETAIL_INSERT '||v_table_name||SQLERRM,1,200);
      RAISE v_err;
  END;

  CLOSE v_MANY_DETAIL;
  

  IF v_error_code < 0 THEN
      v_error_code := -62;
    v_error_msg := 'SP_T_MANY_DETAIL_INSERT'||v_table_name||' '||v_error_msg;
    RAISE v_err;
  END IF;
  
    BEGIN
        UPDATE T_CONTRACTS
        SET sett_qty    = NVL(sett_qty,0) + V_Jur_Qty,
          upd_dt        = SYSDATE,
          upd_by        = p_user_id
        WHERE contr_num = c1.contr_num;
      EXCEPTION
      WHEN OTHERS THEN
        v_error_code := -70;
        v_error_msg  := SUBSTR('UPDATE T_CONTRACTS '||c1.contr_num||SQLERRM,1,200);
        RAISE v_err;
      End;
     
    
    -- 21oct14     vs_docnum := Get_Stkmove_Jurnum(trim(v_stk_cd),C1.due_dt_for_cert,'JVB');
    Vs_Docnum := Get_Stk_Jurnum(C1.Due_Dt_For_Cert,'JVB');
    
    For V_Jur In 1..2  Loop
    
      V_Withdraw_Reason_Cd    := Null;
      
      IF v_jur                 = 1 THEN
    
    If C1.Mrkt_Type      = 'NG' Or C1.Mrkt_Type = 'TS' Or Substr(C1.Contr_Num,6,1) = 'I' Then
          
            --v_deb_acct  := 55;
            If C1.Mrkt_Type <> 'TS' Then
            
              --8juli13 dikomen if SUBSTR(c1.contr_num,6,1) <> 'I' then  -- utk titip KI trx 18JUN13
              v_withdraw_reason_cd := SUBSTR(c1.sell_broker_cd,1,2)||'001';
              --end if;
            End If;
            
            v_jur_type := 'DUEBN1'; -- 12 Debit - 14 Credit
          ELSE
            --v_deb_acct  := 59;
            v_withdraw_reason_cd := NULL;
            V_Jur_Type           := 'DUEBR1'; -- 12 Debit - 14 Credit
            
          END IF;
      
        If Trim(C1.Client_Cd) <> Trim(V_Coy_Client_Cd) And Substr(Trim(C1.Client_Type),1,1) <> 'H' Then
        
          
          -- v_cre_acct := 36;
          v_seq1 := 1;
          V_Seq2 := 2;
          
        Else --IF TRIM(C1.CLIENT_CD) <> trim(v_coy_client_cd)
        
         -- v_jur_qty := 0;
          v_seq1    := 0;
          V_Seq2    := 0;
          
        End If; --IF TRIM(C1.CLIENT_CD) <> trim(v_coy_client_cd)
        
      ELSE      --IF v_jur = 1 THEN
        --                 IF TRIM(C1.CLIENT_CD) <> trim(v_coy_client_cd)
        --                 AND SUBSTR(TRIM(C1.CLIENT_TYPE),1,1) <> 'H' THEN
        --
        --     --             IF  F_Cek_Margin(SUBSTR(c1.client_cd,8,1)) = 'M' THEN
        --     --
        --     --                v_deb_acct := v_margin_acct;
        --     --
        --     --             ELSE
        --     --
        --     --                v_deb_acct := 12;
        --     --
        --     --             END IF;
        --                       --v_cre_acct := 14;
        IF c1.mrkt_type = 'NG' OR c1.mrkt_type = 'TS' OR SUBSTR(c1.contr_num,6,1) = 'I' THEN
          v_jur_type   := 'DUEBN2'; --  55 debit   36 credit
        ELSE
          v_jur_type := 'DUEBR2'; -- 59 debit   36 credit
        END IF;
        --               ELSE
        --                 v_jur_qty := 0;
        --               END IF;
        --                 v_seq1 := 3;
        --                 v_seq2 := 4;
        
        v_seq1 := v_seq2 + 1;
        V_Seq2 := V_Seq1 + 1;
        
      End If; --IF v_jur = 1 THEN
      
    
        
        V_Client_Type := '%';
        
        BEGIN
          Sp_Get_Secu_Acct(p_sett_date, v_Client_type, v_jur_type, v_deb_acct, v_cre_acct, v_error_code, v_error_msg);
        EXCEPTION
        WHEN OTHERS THEN
          v_error_code := -90;
          v_error_msg  := SUBSTR('SP_GET_SECU_ACCT '||SQLERRM,1,200);
          RAISE v_err;
        End;
        
        IF v_error_code < 0 THEN
          v_error_code := -100;
          v_error_msg  := SUBSTR('SP_GET_SECU_ACCT '||v_error_msg,1,200);
          RAISE v_err;
        End If;
     
    
        FOR I IN 1..2 LOOP 
          if I = 1 then
            v_db_cr_flg :='D';
            v_gl_acct_cd := v_deb_acct;
          else
            v_db_cr_flg :='C';
            v_gl_acct_cd := v_cre_acct;
          end if;
        
              --UPDATE T_STKHAND UNTUK DEBIT
            BEGIN
                 Sp_Upd_T_Stkhand
                (
                  C1.CLIENT_CD,
                  Trim(V_Stk_Cd),
                  v_gl_acct_cd,
                  v_db_cr_flg,
                  V_Jur_Qty,
                  v_jur_type,
                  P_USER_ID,
                  v_error_code,
                  v_error_msg
                );
            EXCEPTION
            WHEN OTHERS THEN
                v_error_code := -103;
                v_error_msg  := SUBSTR('Sp_Upd_T_Stkhand '||SQLERRM,1,200);
                RAISE v_err;
            End;
            
            IF v_error_code<0 THEN
                v_error_code := -105;
                v_error_msg  := SUBSTR('Sp_Upd_T_Stkhand '||v_error_msg,1,200);
                RAISE v_err;
            END IF;
        END LOOP;

    IF v_seq1                      > 0 THEN
        V_Lot                          := Floor(V_Jur_Qty / V_Lot_Size);
        
        IF MOD( v_jur_qty , v_lot_size) > 0 THEN
          V_ODD_LOT_DOC                := 'Y';
        ELSE
          V_ODD_LOT_DOC := 'N';
        End If;
    
    
        BEGIN
          Sp_Secu_Jurnal_Nextg( Vs_Docnum,
                                Trim(C1.Contr_Num),
                                P_Sett_Date, 
                                Trim(C1.Client_Cd),
                                Trim(V_Stk_Cd), 
                                'V', 
                                V_Odd_Lot_Doc, 
                                V_Lot, 
                                V_Jur_Qty, 
                                'BUY '||Trim(V_Stk_Cd)||' SETTLED',
                                '2',
                                0, 
                                0,
                                Null,
                                V_Withdraw_Reason_Cd , 
                                V_Deb_Acct, 
                                C1.Client_Type, 
                                'D', 
                                Trim(P_User_Id), 
                                Sysdate,
                                Null, 
                                C1.Due_Dt_For_Cert, 
                                C1.Due_Dt_For_Cert, 
                                V_Seq1, 
                                C1.Price, 
                                'N', 
                                V_Jur_Type, 
                                V_Seq2, 
                                V_Cre_Acct, 
                                'C', 
                                V_Error_Code,
                                v_error_msg);
        EXCEPTION
        WHEN OTHERS THEN
          v_error_code := -110;
          v_error_msg  := SUBSTR('insert  buy '||c1.client_cd||' '||v_stk_cd||'  on T_STK_MOVEMENT '||SQLERRM,1,200);
          RAISE v_err;
        End;
        
        IF v_error_code < 0 THEN
          v_error_code := -120;
          v_error_msg  := SUBSTR('Sp_Secu_Jurnal_Nextg '||v_error_msg,1,200);
          RAISE v_err;
        End If;
        
      End If; 
      
    END LOOP;
    --COMMIT;
  end if;--end if v jur qty <> 0

  --BACKUP T_STKHAND 

  BEGIN
  INSERT INTO C_STKHAND_UPD_AFT 
    SELECT A.*, C1.CONTR_NUM FROM T_STKHAND A WHERE STK_CD = V_Stk_Cd AND CLIENT_CD = C1.CLIENT_CD ; 
  EXCEPTION
    WHEN OTHERS THEN
    v_error_code := -122;
    v_error_msg  := SUBSTR('INSERT C_STKHAND_UPD_BFR '||SQLERRM,1,200);
    RAISE v_err;
  End;  
  
    V_RECORD_sEQ := V_RECORD_sEQ+1;
  END LOOP;
  
  --=============================================SELL  SELL  SELL==========================================
  
    
  For C2 In Contr_Sell  Loop


  --24nov2016, cek sett_qty dari aplikasi apakah sama dengan yang di kursor
    IF p_option ='S' AND (c2.qty - nvl(c2.sett_qty,0)) <> p_entry_qty THEN
     v_error_code := -125;
        v_error_msg  := 'Settle quantity not equal with transaction displayed';
        RAISE v_err;
    END IF;

    IF c2.stk_cd_new IS NOT NULL THEN
      v_stk_Cd       :=c2.stk_cd_new;
    ELSE
      v_stk_Cd :=c2.stk_cd;
    End If;
    
  --BACKUP T_STKHAND 
  BEGIN
  INSERT INTO C_STKHAND_UPD_BFR 
    SELECT A.*, C2.CONTR_NUM FROM T_STKHAND A WHERE STK_CD = v_stk_Cd AND CLIENT_CD = C2.CLIENT_CD ; 
    EXCEPTION
  WHEN OTHERS THEN
    v_error_code := -126;
    v_error_msg  := SUBSTR('INSERT C_STKHAND_UPD_BFR '||SQLERRM,1,200);
    RAISE v_err;
  End;  
  

    v_cnt_sell       := v_cnt_sell + 1;
    V_Ohqty          := 0;
   

    
    BEGIN
      SELECT ON_HAND
      INTO V_OHQTY
      FROM T_STKHAND
      WHERE CLIENT_CD = C2.CLIENT_CD
      AND STK_cD      = v_stk_Cd
      AND L_F         = C2.STATUS;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      V_OHQTY := 0;
    WHEN OTHERS THEN
      v_error_code := -130;
      v_error_msg  := SUBSTR('retrieve T_STKHAND '||c2.client_cd||' '||v_stk_cd||SQLERRM,1,200);
      RAISE v_err;
    End;
     
    BEGIN
      SELECT stk_scripless,
        lot_size
      INTO vstk_scripless,
        v_lot_size
      FROM MST_COUNTER
      WHERE stk_cd = v_stk_Cd;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      v_error_code := -140;
      v_error_msg  := SUBSTR('Retrieve  MST_COUNTER '||SQLERRM,1,200);
      RAISE v_err;
    WHEN OTHERS THEN
      v_error_code := -150;
      v_error_msg  := SUBSTR('Retrieve  MST_COUNTER '||SQLERRM,1,200);
      RAISE v_err;
    End;
    
    --     8aug14    IF c2.from_qty > 0 THEN
    --            v_jur_qty := ROUND(c2.qty / c2.from_qty * c2.to_Qty, 0);
    --         ELSE
    --         END IF;
    
    
   IF P_OPTION    = 'A' THEN
        IF c2.qty   <= V_OHQTY THEN
          v_jur_qty := c2.qty - nvl(c2.sett_qty,0);
        ELSE
          --  8aug14 IF c2.from_qty > 0 THEN
          --             v_jur_qty := ROUND(V_OHQTY / c2.from_qty * c2.to_qty, 0);
          --      ELSE
          v_jur_qty := V_OHQTY;
          --        END IF;
        END IF;
  ELSE
        IF P_ENTRY_QTY<=V_OHQTY THEN
              IF P_ENTRY_QTY>= c2.qty - nvl(c2.sett_qty,0) THEN--27APR2017
                  V_JUR_QTY :=  c2.qty - nvl(c2.sett_qty,0);
              ELSE
                  V_JUR_QTY := P_ENTRY_QTY;
              END IF;
    
        ELSE
          --V_JUR_QTY :=V_OHQTY;
          
          --08dec2016, supaya yang disettle tidak melebihi qty yang di t_stkhand      
          IF V_OHQTY <  c2.qty - nvl(c2.sett_qty,0) THEN
              V_JUR_QTY :=V_OHQTY;
          ELSE
               V_JUR_QTY :=  c2.qty - nvl(c2.sett_qty,0);
          END IF;
        
        END IF;
  END IF; 
    
   if V_JUR_QTY <> 0 then
   
   --INSERT INTO T_MANY_DETAIL


  OPEN v_MANY_DETAIL FOR
    SELECT v_update_date AS update_date, v_update_seq AS update_seq, table_name, V_RECORD_sEQ AS record_seq, v_table_rowid AS table_rowid, a.field_name,  field_type, b.field_value, V_upd_status AS status,  b.upd_flg
    FROM(
      SELECT  v_table_name AS table_name, column_name AS field_name, DECODE(data_type,'VARCHAR2','S','CHAR','S','NUMBER','N','DATE','D','X') AS field_type
      FROM all_tab_columns
      WHERE table_name = v_table_name
      UNION
      SELECT v_table_name, 'DUE_DATE', 'D' FROM dual
      UNION
      SELECT v_table_name, 'OPTION', 'S' FROM dual
      ) a,
    ( 
      SELECT 'DUE_DATE' AS field_name,TO_CHAR(P_SETT_DATE,'YYYY/MM/DD HH24:MI:SS') AS field_value, 'X' upd_flg FROM dual
      UNION
      SELECT  'CONTR_NUM'  AS field_name,  C2.CONTR_NUM AS field_value, 'X' upd_flg FROM dual
      UNION 
        SELECT  'CLIENT_CD'  AS field_name,  TO_CHAR(C2.CLIENT_CD) AS field_value, 'X' upd_flg FROM dual
        UNION
        SELECT  'OPTION'  AS field_name,  DECODE(P_OPTION,'A','ALL','SELECTED') AS field_value, 'X' upd_flg FROM dual
    ) b
    WHERE a.field_name = b.field_name;
  
  BEGIN
    Sp_T_Many_Detail_Insert(v_update_date,   v_update_seq,   v_upd_status, v_table_name, v_record_seq , v_table_rowid, v_MANY_DETAIL, v_error_code, v_error_msg);
  EXCEPTION
    WHEN OTHERS THEN
      v_error_code := -7;
      v_error_msg := SUBSTR('SP_T_MANY_DETAIL_INSERT '||v_table_name||SQLERRM,1,200);
      RAISE v_err;
  END;
  
  CLOSE v_MANY_DETAIL;


  IF v_error_code < 0 THEN
    v_error_code := -152;
    v_error_msg := 'SP_T_MANY_DETAIL_INSERT'||v_table_name||' '||v_error_msg;
    RAISE v_err;
  END IF;
    
    BEGIN
      UPDATE T_CONTRACTS
      Set Sett_Qty    = Nvl(Sett_Qty,0) + V_Jur_Qty,
        Upd_Dt        = Sysdate,
        upd_by        = p_user_id
      WHERE contr_num = c2.contr_num;
    EXCEPTION
    WHEN OTHERS THEN
      v_error_code := -160;
      v_error_msg  := SUBSTR('UPDATE T_CONTRACTS '||c2.contr_num||SQLERRM,1,200);
      RAISE v_err;
    End;
    
    --21oct14    vs_docnum := Get_Stkmove_Jurnum(trim(v_stk_cd),c2.due_dt_for_cert,'JVS');
    vs_docnum := Get_Stk_Jurnum(c2.due_dt_for_cert,'JVS');
    For V_Jur In 1..2   Loop
      IF v_jur  = 1 THEN
        V_Withdraw_Reason_Cd  := Null;
        
          
        IF c2.mrkt_type = 'NG' OR c2.mrkt_type = 'TS' OR SUBSTR(c2.contr_num,6,1) = 'I' THEN
          --v_cre_acct := 17;
          -- 8juli13 dikomen if SUBSTR(c2.contr_num,6,1) <> 'I' then  -- utk titip KI trx 18JUN13
          IF c2.mrkt_type        <> 'TS' THEN
            v_withdraw_reason_cd := SUBSTR(c2.buy_broker_cd,1,2)||'001';
          END IF;
          --end if;
          V_Jur_Type := 'DUEJN1'; -- 51debit 12 credit
          
        ELSE
          --v_cre_acct := 21;
          v_withdraw_reason_cd := NULL;
          v_jur_type           := 'DUEJR1';-- 51debit 12 credit
        End If;
        
        IF TRIM(C2.CLIENT_CD) <> trim(v_coy_client_cd) AND SUBSTR(TRIM(C2.CLIENT_TYPE),1,1) <> 'H' THEN
          -- v_deb_acct := 36;
          v_seq1         := 1;
          V_Seq2         := 2;
        ELSE
          v_seq1 := 0;
          v_seq2 := 0;
        End If;
        
      ELSE
        --         IF TRIM(C2.CLIENT_CD) <> trim(v_coy_client_cd)
        --            AND SUBSTR(TRIM(C2.CLIENT_TYPE),1,1) <> 'H' THEN
        --v_deb_acct := 51;
        v_seq1 := v_seq2 + 1;
        v_seq2 := v_seq1 + 1;
        --           IF  F_Cek_Margin(SUBSTR(c2.client_cd,8,1)) = 'M' THEN
        --
        --            v_cre_acct:= v_margin_acct;
        --
        --              ELSE
        --
        --            v_cre_acct := 12;
        --
        --              END IF;
        IF c2.mrkt_type = 'NG' OR c2.mrkt_type = 'TS' OR SUBSTR(c2.contr_num,6,1) = 'I' THEN
          v_jur_type   := 'DUEJN2'; --  36 credit 17debit
        ELSE
          v_jur_type := 'DUEJR2'; --  36 credit 21 debit
        END IF;
        --         ELSE
        --             v_jur_qty := 0;
        --         END IF;
      END IF;
      
        V_Client_Type := '%';
        
        BEGIN
          Sp_Get_Secu_Acct(p_sett_date, v_Client_type, v_jur_type, v_deb_acct, v_cre_acct, v_error_code, v_error_msg);
        EXCEPTION
        WHEN OTHERS THEN
          v_error_code := -180;
          v_error_msg  := SUBSTR('SP_GET_SECU_ACCT '||SQLERRM,1,200);
          RAISE v_err;
        End;
        
        IF v_error_code < 0 THEN
       v_error_code := -190;
          v_error_msg  := SUBSTR('SP_GET_SECU_ACCT '||v_error_msg||SQLERRM,1,200);
          RAISE v_err;
        End If;
    
        FOR I IN 1..2 LOOP 
            if I = 1 then
              v_db_cr_flg :='D';
              v_gl_acct_cd := v_deb_acct;
            else
              v_db_cr_flg :='C';
              v_gl_acct_cd := v_cre_acct;
            end if;
    
            --UPDATE T_STKHAND UNTUK DEBIT
            BEGIN
                Sp_Upd_T_Stkhand
                (
                C2.CLIENT_CD,
                v_stk_Cd,
                v_gl_acct_cd,
                v_db_cr_flg,
                V_Jur_Qty,
                v_jur_type,
                P_USER_ID,
                v_error_code,
                v_error_msg
                );
              EXCEPTION
            WHEN OTHERS THEN
                v_error_code := -193;
                v_error_msg  := SUBSTR('Sp_Upd_T_Stkhand '||SQLERRM,1,200);
                RAISE v_err;
            End;
            
            IF v_error_code<0 THEN
                v_error_code := -195;
                v_error_msg  := SUBSTR('Sp_Upd_T_Stkhand '||v_error_msg,1,200);
                RAISE v_err;
            END IF;
        END LOOP;
    
      IF v_seq1  > 0 THEN
        v_lot  := FLOOR(v_jur_qty / v_lot_size);
        IF MOD( v_jur_qty , v_lot_size) > 0 THEN
          V_ODD_LOT_DOC                := 'Y';
        ELSE
          V_ODD_LOT_DOC := 'N';
        END IF;
        --      Sp_Secu_Jurnal_Tes( vs_docnum,TRIM(c2.contr_num),ad_sett_date,
        BEGIN
          Sp_Secu_Jurnal_Nextg( Vs_Docnum,
                              Trim(C2.Contr_Num),
                              P_Sett_Date, 
                              Trim(C2.Client_Cd),
                              Trim(V_Stk_Cd), 
                              'V', 
                              V_Odd_Lot_Doc, 
                              V_Lot, 
                              V_Jur_Qty, 
                              'SELL '||Trim(V_Stk_Cd)||' SETTLED',
                              '2',
                              0, 
                              0,
                              Null,
                              V_Withdraw_Reason_Cd, 
                              V_Deb_Acct, 
                              C2.Client_Type, 
                              'D', 
                              Trim(P_User_Id), 
                              Sysdate,Null, 
                              C2.Due_Dt_For_Cert, 
                              C2.Due_Dt_For_Cert, 
                              V_Seq1, 
                              C2.Price, 
                              'N', 
                              V_Jur_Type, 
                              V_Seq2, 
                              V_Cre_Acct, 
                              'C', 
                              V_Error_Code,
                              v_error_msg);
        EXCEPTION
        WHEN OTHERS THEN
          v_error_code := -200;
          v_error_msg  := SUBSTR('insert  sell '||c2.client_cd||' '||c2.stk_cd||'  on T_STK_MOVEMENT '||SQLERRM,1,200);
          RAISE v_err;
        End;
        
        IF v_error_code < 0 THEN
       v_error_code := -210;
          v_error_msg  := SUBSTR('Sp_Secu_Jurnal_Nextg '|| v_error_msg|| SQLERRM,1,200);
          RAISE v_err;
       
        END IF;
      END IF;
      --COMMIT;
    END LOOP;
  end if; --end if V_JUR_QTY <>0
  
   --BACKUP T_STKHAND 
  BEGIN
  INSERT INTO C_STKHAND_UPD_AFT 
    SELECT A.*, C2.CONTR_NUM FROM T_STKHAND A WHERE STK_CD = v_stk_Cd AND CLIENT_CD = C2.CLIENT_CD ; 
  EXCEPTION
    WHEN OTHERS THEN
    v_error_code := -112;
    v_error_msg  := SUBSTR('INSERT C_STKHAND_UPD_BFR '||SQLERRM,1,200);
    RAISE v_err;
  End;  
  
  V_RECORD_sEQ := V_RECORD_sEQ+1;
  
  END LOOP;
  
  --APPROVE T_MANY
  BEGIN
  Sp_T_Many_Approve(v_menu_name,          
           v_update_date,       
           v_update_seq,          
           p_user_id,
           p_ip_address,    
           v_error_code,          
           v_error_msg);
  EXCEPTION
  WHEN OTHERS THEN
    v_error_code := -115;
    v_error_msg  := SUBSTR('INSERT C_T_CONTRACTS_UPD_AFT '||SQLERRM,1,200);
    RAISE v_err;
  End;    
  
    IF v_error_code < 0 THEN
        v_error_code := -210;
        v_error_msg  := SUBSTR('Sp_T_Many_Approve '|| v_error_msg,1,200);
        RAISE v_err;
    END IF;      
  IF (v_cnt_buy                  + v_cnt_sell ) = 0 THEN
    v_error_code              := -220;
    v_error_msg               := 'No unsettled transaction to process !';
    RAISE v_err;
  END IF;

  p_error_code := 1;
  p_error_msg  := '';
EXCEPTION
WHEN NO_DATA_FOUND THEN
  NULL;
WHEN v_err THEN
  p_error_code := v_error_code;
  p_error_msg  := v_error_msg;
  ROLLBACK;
WHEN OTHERS THEN
  -- Consider logging the error and then re-raise
  ROLLBACK;
  p_error_code := -1;
  p_error_msg  := SUBSTR(SQLERRM,1,200);
  RAISE;
END Sp_Xfertostkhand_Nextg;