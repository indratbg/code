create or replace PROCEDURE Sp_Bond_Trx_Secu_Nextg(
    P_TRX_DATE DATE,
    P_TRX_SEQ_NO T_BOND_TRX.TRX_SEQ_NO%TYPE,
    P_Jur_date DATE,
    P_KSEI t_bond_trx.trx_type%type,
    P_USER_ID T_ACCOUNT_LEDGER.USER_ID%TYPE,
    P_UPD_STATUS T_MANY_DETAIL.UPD_STATUS%TYPE,
    P_menu_name T_MANY_HEADER.MENU_NAME%TYPE,
    p_ip_address T_MANY_HEADER.IP_ADDRESS%TYPE,
    p_cancel_reason T_MANY_HEADER.CANCEL_REASON%TYPE,
    p_update_date T_MANY_HEADER.UPDATE_DATE%TYPE,
    p_update_seq T_MANY_HEADER.UPDATE_SEQ%TYPE,
    p_record_seq T_MANY_DETAIL.RECORD_SEQ%TYPE,
    p_error_code OUT NUMBER,
    p_error_msg OUT VARCHAR2)
IS
  /******************************************************************************
  NAME:       Sp_Bond_Trx_Secu_Nextg
  PURPOSE:   generate securities journal
  REVISIONS:
  Ver        Date        Author           Description
  ---------  ----------  ---------------  ------------------------------------
  1.0        22/01/2014          1. Created this procedure.
  25JAN2018[INDRA] JURNAL AT VALUE DATE
  LAUT001R    LAWAN   Pilihan didropdown
  ksei        ksei    All
  custody     ksei    Lawan
  ksei        custody   YJ
  custody     custody   No


  27aug14 - jika governmn bond, wkt settle pakai gl_acct_cd 35 di mkbd vd57.31
  efek di bank kustodian
  -- 7oct15 - jurnal pada value dt utk Lawan Internal (eg  SUS, BRU)
  jurnal kedua 55  35 / 35   17 kalau trx di custodi,  55  36 / 36  17 kalau trx di ksei
  pake DUEBBONDC/K  DUEJBONDC/K
  --  18jul16 - tambah parameter P_KSEI , spy user settlement dpt input bond ada di KSEI wkt value dt
  krn fixed income kadang tidk input KSEI di custodian_cd
  -- 10jan2018 trx bond, jika custodian = KSEI, di jurnal value dt internal,
  field broker diisi KSEI, spy keluar di otc fee
  NOTES:
  ******************************************************************************/
  CURSOR csr_trx
  IS
    SELECT t.trx_date,t.trx_seq_no, t.trx_type, t.bond_cd, t.nominal, t.value_dt,
    custodian_cd, price, lawan, lawan_type, secu_jur_trx, secu_jur_lawan,
    doc_num, m.BOND_GROUP_CD, NVL(journal_status,'N') journal_status
    FROM T_BOND_TRX T, MST_BOND m
    WHERE t.trx_date    =p_trx_date
    AND t.trx_seq_no    = p_trx_seq_no
    AND t.approved_sts <> 'C'
    AND t.bond_cd       = m.bond_cd;
    
  v_many_detail Types.many_detail_rc;
  v_table_name VARCHAR2(50) := 'T_BOND_TRX';
  v_doc_num T_STK_MOVEMENT.doc_num%TYPE;
  V_REF_DOC_NUM T_STK_MOVEMENT.ref_doc_num%TYPE;
  v_db_cr_flg T_STK_MOVEMENT.db_cr_flg%TYPE;
  v_client_Cd T_STK_MOVEMENT.client_cd%TYPE;
  v_coy_client_Cd T_STK_MOVEMENT.client_cd%TYPE;
  v_deb_acct T_STK_MOVEMENT.gl_acct_cd%TYPE;
  v_cre_acct T_STK_MOVEMENT.gl_acct_cd%TYPE;
  V_DOC_REM T_STK_MOVEMENT.doc_rem%TYPE;
  V_S_D_TYPE T_STK_MOVEMENT.S_D_TYPE%TYPE;
  v_stk_mvmt_type T_STK_MOVEMENT.JUR_TYPE%TYPE;
  v_jur_type T_STK_MOVEMENT.JUR_TYPE%TYPE;
  v_custodian_cd T_STK_MOVEMENT.broker%type;
  V_SEQNO T_STK_MOVEMENT.SEQNO%TYPE;
  V_SEQNO_2 T_STK_MOVEMENT.SEQNO%TYPE;
  v_buy T_STKHAND.os_buy%TYPE;
  v_sell T_STKHAND.os_buy%TYPE;
  v_client_type_secu_acct MST_SECU_ACCT.client_type%TYPE;
  v_BELI_JUAL  CHAR(1);
  
  I            INTEGER;
  I_jurnal     INTEGER;
  v_cnt        NUMBER;
  v_milyar     NUMBER := 1000000000;
  v_qty_m      NUMBER;
  i_cnt_jur    NUMBER;
  i_cnt_client NUMBER;
  v_err        EXCEPTION;
  v_error_code NUMBER;
  v_error_msg  VARCHAR2(200);
BEGIN

      BEGIN
        SELECT trim(other_1) INTO v_coy_client_cd FROM MST_COMPANY;
      EXCEPTION
      WHEN NO_DATA_FOUND THEN
        v_error_code := -20;
        v_error_msg  := ' MST_COMPANY not found';
      WHEN OTHERS THEN
        v_error_code := -30;
        v_error_msg  := SUBSTR('select MST_COMPANY '||SQLERRM,1,200);
        RAISE v_err;
      END;
  
      FOR rec IN csr_trx  LOOP
      
               
      
          IF rec.lawan_type = 'I' THEN
            i_cnt_client   := 2;
          ELSE
            i_cnt_client := 1;
          END IF;
        
          FOR i IN 1.. i_cnt_client LOOP
          
            -- 1 LAUT001R
            -- 2 internal client
            v_custodian_cd := NULL;
            
            IF I            = 1 THEN
              v_client_cd  := trim(v_coy_client_cd);
            ELSE
            
              IF rec.lawan_type = 'I' THEN
              
                BEGIN
                  SELECT trim(sl_acct_cd)
                  INTO v_client_Cd
                  FROM MST_LAWAN_BOND_TRX
                  WHERE lawan = rec.lawan;
                EXCEPTION
                WHEN OTHERS THEN
                  v_error_code := -40;
                  v_error_msg  := SUBSTR('select MST_LAWAN_BOND_TRX '||SQLERRM,1,200);
                  RAISE v_err;
                END;
                
              ELSE
              
                v_client_Cd := 'X';
                
              END IF;
              
            END IF;
            
            IF I               = 1 THEN
            
              IF P_JUR_DATE    = REC.TRX_DATE AND rec.doc_num IS NOT NULL AND rec.secu_jur_trx IS NULL THEN
                v_jur_type    := 'TRX';
              ELSIF P_JUR_DATE = REC.VALUE_DT AND rec.doc_num IS NOT NULL AND rec.secu_jur_trx IS NOT NULL THEN
                v_jur_type    := 'DUE';
              ELSE
                v_error_code := -6;
                v_error_msg  := 'Transaksi tidak dapat dijurnal';
                RAISE v_err;
              END IF;
              
            END IF;
            
            IF v_jur_type = 'TRX' THEN
              I_CNT_JUR  := 1;
            ELSE
              IF I         = 1 THEN
                I_cnt_jur := 1;
              ELSE
                I_cnt_jur := 2;
              END IF;
            END IF;
            
            FOR I_jurnal IN 1..i_cnt_jur LOOP
            
              v_custodian_cd     := NULL;
              IF v_jur_type       = 'TRX' THEN
                IF I              = 1 THEN -- LAUT
                  IF rec.trx_type = 'B' THEN
                    v_beli_jual  := 'B';
                    --                  v_deb_acct := '10';
                    --                 v_cre_acct := '55';
                    v_buy     := rec.nominal;
                    v_sell    := 0;
                    v_doc_rem := 'Buy ';
                  ELSE
                    v_beli_jual := 'J';
                    --                  v_deb_acct := '17';
                    --                 v_cre_acct := '10';
                    v_buy     := 0;
                    v_sell    := rec.nominal;
                    v_doc_rem := 'Sell ';
                  END IF;
                  
                  v_stk_mvmt_type         := 'TRX'||v_beli_jual||'BOND';
                  v_client_type_secu_acct :='H';
                  v_qty_m                 := ROUND(rec.nominal / v_milyar,2);
                  v_doc_rem               := v_doc_rem||rec.bond_cd||' '||TO_CHAR(v_qty_m)||' M  @'||rec.price;
                  
                ELSE --          IF I = 1 THEN
                  -- I = 2 internal CLIENT ALWI/WIEN
                  IF rec.trx_type = 'B' THEN
                    v_beli_jual  := 'J';
                    --jual
                    -- v_deb_acct := '17';
                    -- v_cre_acct := '51';
                    v_buy     := 0;
                    v_sell    := rec.nominal;
                    v_doc_rem := 'Sell ';
                  ELSE
                    v_beli_jual := 'B';
                    -- Beli
                    -- v_deb_acct := '14';
                    -- v_cre_acct := '55';
                    v_buy     := rec.nominal;
                    v_sell    := 0;
                    v_doc_rem := 'Buy ';
                  END IF;
                  v_stk_mvmt_type         := 'TRX'||v_beli_jual||'N'; --'TRXBN' / TRXJN
                  v_client_type_secu_acct := '%';
                  v_qty_m                 := ROUND(rec.nominal / v_milyar,2);
                  v_doc_rem               := v_doc_rem||rec.bond_cd||' '||TO_CHAR(v_qty_m)||' M  @'||rec.price;
                END IF; -- laut/ internal
                
                IF I             = 1 THEN
                  V_DOC_NUM     := rec.doc_num;
                  V_REF_DOC_NUM := V_DOC_NUM;
                ELSE
                  V_DOC_NUM := rec.doc_num;
                  V_DOC_NUM := SUBSTR(V_DOC_NUM, 1,4)||v_beli_jual||SUBSTR(V_DOC_NUM, 6,9);
                END IF;
                V_S_D_TYPE := 'O';
                V_SEQNO    := 1;
                V_SEQNO_2  := 2;
              END IF; --p_jur_date = rec.trx_date THEN
              
              IF v_jur_type       = 'DUE' THEN
              
                IF I              = 1 THEN -- LAUT
                
                      IF rec.trx_type = 'B' THEN
                            v_beli_jual  := 'B';
                            --                            v_deb_acct := '55';
                            --                           IF rec.bond_group_Cd = '03' AND p_jur_date > '31aug14' THEN
                            --                              v_cre_acct := '35';
                            --                           ELSE
                            --                               v_cre_acct := '36';
                            --                          END IF;
                            v_doc_rem := 'Settle Buy ';
                            v_buy     := rec.nominal;
                            v_sell    := 0;
                      ELSE
                            v_beli_jual := 'J';
                            --                            IF rec.bond_group_Cd = '03'  AND p_jur_date > '31aug14' THEN
                            --                                 v_deb_acct := '35';
                            --                           ELSE
                            --                                 v_deb_acct := '36';
                            --                           END IF;
                            --                           v_cre_acct := '17';
                            v_doc_rem := 'Settle Sell ';
                            v_buy     := 0;
                            v_sell    := rec.nominal;
                      END IF;
                      
                      v_stk_mvmt_type                := 'DUE'||v_beli_jual||'BOND';
                      
                      --IF SUBSTR(rec.custodian_cd,1,4) = 'KSEI' OR P_KSEI = 'Y' THEN--25jan2018 [indra]
                      IF P_KSEI = 'ALL' OR P_KSEI='YJ' THEN
                            v_stk_mvmt_type              := v_stk_mvmt_type||'K';
                      ELSE
                        --JIKA P_KSEI =NO/LAWAN
                           v_stk_mvmt_type := v_stk_mvmt_type||'C'; -- di custodian bank
                      END IF;
                      
                      v_client_type_secu_acct := '%';
                      v_qty_m                 := ROUND( rec.nominal / v_milyar, 2);
                      v_doc_rem               := v_doc_rem||rec.bond_cd||' '||TO_CHAR(v_qty_m)||' M  @'||rec.price;
                      V_REF_DOC_NUM           := rec.secu_jur_trx;
                  
                END IF;       --          IF I = 1 THEN
                
                IF I                = 2 THEN -- lawan
                
                      IF I_jurnal       = 1 THEN -- JVB/JVS
                      
                            IF rec.trx_type = 'B' THEN
                                  v_beli_jual  := 'J';
                                  --jual
                                  --                        v_deb_acct := '51';
                                  --                         v_cre_acct := '17';
                                  v_buy     := 0;
                                  v_sell    := rec.nominal;
                                  v_doc_rem := 'Settle Sell ';
                            ELSE
                                  v_beli_jual := 'B';
                                  -- Beli
                                  --                         v_deb_acct := '55';
                                  --                          v_cre_acct := '14';
                                  v_buy     := rec.nominal;
                                  v_sell    := 0;
                                  v_doc_rem := 'Settle Buy ';
                            END IF;
                        
                            v_stk_mvmt_type                := 'DUE'||v_beli_jual||'N1'; -- 'DUEBN1'; 'DUEJN1';
                            
                          -- IF SUBSTR(rec.custodian_cd,1,4) = 'KSEI' AND (P_KSEI = 'ALL' OR P_KSEI='LAWAN') THEN
                            IF P_KSEI = 'ALL' OR P_KSEI='LAWAN' THEN
                                  v_custodian_cd               := 'KSEI';
                            END IF;
                        
                      ELSE
                          
                            IF rec.trx_type = 'B' THEN
                                  v_beli_jual  := 'J';
                                  --jual
                                  --                        v_deb_acct := '36';
                                  --                         v_cre_acct := '12';
                                  v_buy     := 0;
                                  v_sell    := rec.nominal;
                                  v_doc_rem := 'Settle Sell ';
                            ELSE
                                  v_beli_jual := 'B';
                                  -- Beli
                                  --                         v_deb_acct := '12';
                                  --                          v_cre_acct := '36';
                                  v_buy     := rec.nominal;
                                  v_sell    := 0;
                                  v_doc_rem := 'Settle Buy ';
                            END IF;
                            
                            -- 7oct15  v_stk_mvmt_type := 'DUE'||v_beli_jual||'N2';  --'DUEJN2';'DUEBN2';
                            v_stk_mvmt_type                := 'DUE'||v_beli_jual||'BOND';
                            
                            --IF SUBSTR(rec.custodian_cd,1,4) = 'KSEI' AND (P_KSEI = 'ALL' OR P_KSEI='LAWAN' ) THEN
                            IF P_KSEI = 'ALL' OR P_KSEI='LAWAN'  THEN
                                  v_stk_mvmt_type              := v_stk_mvmt_type||'K';
                            ELSE
                                  v_stk_mvmt_type := v_stk_mvmt_type||'C'; -- di custodian bank
                            END IF;
                            
                          END IF;
                          
                          v_client_type_secu_acct := '%';
                          v_qty_m                 := ROUND(rec.nominal / v_milyar,2);
                          v_doc_rem               := v_doc_rem||rec.bond_cd||' '||TO_CHAR(v_qty_m)||' M  @'||rec.price;
                          V_REF_DOC_NUM           := rec.secu_jur_lawan;

                END IF; --          IF I = 2 THEN
                
                V_S_D_TYPE := 'V';
                IF I_jurnal = 1 THEN
                      --21oct                   V_DOC_NUM := Get_Stkmove_Jurnum(NULL, p_jur_date,'JV'||v_beli_jual);
                      IF v_beli_jual = 'J' THEN
                        v_beli_jual := 'S';
                      END IF;
                      V_DOC_NUM := Get_Stk_Jurnum( p_jur_date,'JV'||v_beli_jual);
                      V_SEQNO   := 1;
                      V_SEQNO_2 := 2;
                  
                ELSE
                      V_SEQNO   := 3;
                      V_SEQNO_2 := 4;
                END IF;
                
              END IF; --p_jur_date = rec.value_dt THEN
              
              BEGIN
                Sp_Get_Secu_Acct(P_jur_date, v_client_type_secu_acct, v_stk_mvmt_type, v_deb_acct, v_cre_acct, v_error_code, v_error_msg);
              EXCEPTION
              WHEN OTHERS THEN
                v_error_code := -80;
                v_error_msg  := SUBSTR('SP_GET_SECU_ACCT '||SQLERRM,1,200);
                RAISE v_err;
              END;
              
              IF v_error_code < 0 THEN
                    RAISE v_err;
              END IF;
              
              BEGIN
                Sp_Secu_Jurnal_Nextg( V_DOC_NUM, 
                V_REF_DOC_NUM, 
                P_jur_date, 
                V_CLIENT_CD, 
                rec.bond_cd, 
                V_S_D_TYPE, 
                'N', --V_ODD_LOT_DOC
                0, --V_TOTAL_LOT
                rec.nominal, --V_TOTAL_SHARE_QTY
                V_DOC_REM, '2', --V_DOC_STAT
                NULL,--V_STK_STAT
                0, --V_WITHDRAWN_SHARE_QTY
                NULL,--V_REGD_HLDR
                v_custodian_cd, --10jan2018--rec.custodian_cd, --V_WITHDRAW_REASON_CD
                V_DEB_ACCT,
                NULL, --V_ACCT_TYPE
                'D',  --V_DB_CR_FLG
                P_USER_ID,
                SYSDATE,
                NULL, --V_UPD_DT IN T_STK_MOVEMENT.UPD_DT%TYPE,
                rec.value_dt,--V_DUE_DT_FOR_CERT IN T_STK_MOVEMENT.DUE_DT_FOR_CERT%TYPE,
                rec.value_dt, --V_DUE_DT_ONHAND IN T_STK_MOVEMENT.DUE_DT_ONHAND%TYPE,
                V_SEQNO, rec.price, --V_PRICE IN T_STK_MOVEMENT.PRICE%TYPE,
                'Y', --MANUAL
                v_stk_mvmt_type,
                V_SEQNO_2, 
                V_CRE_ACCT, 
                'C', 
                v_error_code, 
                v_error_msg);--V_DB_CR_FLG_2
              EXCEPTION
              WHEN OTHERS THEN
                v_error_code := -90;
                v_error_msg  := SUBSTR('Sp_Secu_Jurnal_Nextg '||V_DOC_REM||SQLERRM,1,200);
                RAISE v_err;
              END;
              
              IF v_error_code < 0 THEN
                RAISE v_err;
              END IF;
              
              IF v_jur_type = 'TRX' THEN
                  
                    IF I        = 1 THEN -- laut
                          BEGIN
                            UPDATE T_BOND_TRX
                            SET secu_jur_trx = v_doc_num
                            WHERE trx_date   = rec.trx_date
                            AND trx_seq_no   = rec.trx_seq_no;
                          EXCEPTION
                          WHEN OTHERS THEN
                            v_error_code := -100;
                            v_error_msg  := SUBSTR('UPDATE T_BOND_TRX secu_jur_trx, trx seq no '||TO_CHAR(rec.trx_seq_no)||SQLERRM,1,200);
                            RAISE v_err;
                          END;
                    END IF;
                    
                    IF I = 2 THEN -- lawan
                        BEGIN
                          UPDATE T_BOND_TRX
                          SET secu_jur_lawan = v_doc_num
                          WHERE trx_date     = rec.trx_date
                          AND trx_seq_no     = rec.trx_seq_no;
                        EXCEPTION
                        WHEN OTHERS THEN
                          v_error_code := -110;
                          v_error_msg  := SUBSTR('UPDATE T_BOND_TRX secu_jur_lawan, trx seq no '||TO_CHAR(rec.trx_seq_no)||SQLERRM,1,200);
                          RAISE v_err;
                        END;
                    END IF;
                
              END IF; --IF p_jur_date = rec.trx_date THEN
              
              IF v_jur_type = 'DUE' AND i_jurnal = 1 THEN
                    --                         UPDATE T_STKHAND
                    --                              SET os_buy = NVL(os_buy,0) - v_buy,
                    --                                       os_sell = NVL(os_sell,0) - v_sell,
                    --                              on_hand = NVL(on_hand,0) + v_buy -  v_sell,
                    --                              upd_dt = SYSDATE,
                    --                              upd_by = p_user_id
                    --                             WHERE  client_Cd = V_CLIENT_CD
                    --                               AND stk_cd = rec.bond_cd;
                    BEGIN
                      UPDATE T_BOND_TRX
                      SET settle_secu_flg = 'Y'
                      WHERE trx_date      = rec.trx_date
                      AND trx_seq_no      = rec.trx_seq_no;
                    EXCEPTION
                    WHEN OTHERS THEN
                      v_error_code := -120;
                      v_error_msg  := SUBSTR('UPDATE T_BOND_TRX settle_secu_flg, trx seq no '||TO_CHAR(rec.trx_seq_no)||SQLERRM,1,200);
                      RAISE v_err;
                    END;
                
              END IF; -- p_jur_date = rec.value_dt THEN
              
              IF I_jurnal = 1 THEN
                    -- gl_Acct_cd = %. p_db_cr_flg tdk perlu diisi , spy upd sekaligus, tdk perlu call 2x
                    BEGIN
                      Sp_Upd_T_Stkhand(V_CLIENT_CD, rec.bond_cd, '%', 'D', rec.nominal, v_stk_mvmt_type, p_user_id, v_error_code, v_error_msg);
                    EXCEPTION
                    WHEN OTHERS THEN
                      v_error_code := -100;
                      v_error_msg  := SUBSTR('Sp_Upd_T_Stkhand '||v_client_cd||' '||rec.bond_cd||' '||v_stk_mvmt_type||SQLERRM,1,200);
                      RAISE v_err;
                    END;
                    
                    IF v_error_code < 0 THEN
                      RAISE v_err;
                    END IF;
              END IF;
              
            END LOOP; -- jurnal cnt
            
          END LOOP;   -- 1..2 laut/internal client
        
      END LOOP;     --rec IN csr_trx LOOP
  
      IF P_MENU_NAME = 'GEN SECU JOURNAL VALUE DT' THEN
      
          OPEN v_many_detail FOR SELECT p_update_date AS    update_date,p_update_seq update_seq,table_name,p_record_seq AS record_seq, NULL AS table_rowid, a.field_name, field_type, b.field_value, p_upd_status  AS status, b.upd_flg 
          FROM   (
                    SELECT SYSDATE AS update_date, v_table_name AS table_name, column_id, column_name AS field_name, 
                    DECODE(data_type,'VARCHAR2','S','CHAR','S','NUMBER','N','DATE','D','X') AS field_type
                    FROM all_tab_columns
                    WHERE table_name = v_table_name
                    AND OWNER        = 'IPNEXTG'
                  )
                  a, (
                    SELECT 'TRX_DATE' AS field_name, TO_CHAR(P_TRX_DATE,'yyyy/mm/dd hh24:mi:ss') AS field_value, 'N' upd_flg
                    FROM dual
                    UNION
                    SELECT 'TRX_SEQ_NO' AS field_name, TO_CHAR(P_TRX_SEQ_NO) AS field_value, 'N' upd_flg
                    FROM dual
                  )
                  b WHERE a.field_name = b.field_name;
                  
                BEGIN
                  Sp_T_Many_Detail_Insert(p_update_date, p_update_seq, P_UPD_STATUS , v_table_name, p_record_seq , NULL, v_MANY_DETAIL, v_error_code, v_error_msg);
                EXCEPTION
                WHEN OTHERS THEN
                  v_error_code := -39;
                  v_error_msg  := SUBSTR('SP_T_MANY_DETAIL_INSERT '||v_table_name||SQLERRM,1,200);
                  RAISE v_err;
                END;
          CLOSE v_many_detail;
    END IF;
    
    
--COMMIT;
P_error_code:= 1;
P_error_msg := '';
EXCEPTION
WHEN v_err THEN
  P_error_code := v_error_code;
  P_error_msg  := v_error_msg;
  ROLLBACK;
WHEN OTHERS THEN
  -- Consider logging the error and then re-raise
  P_error_code := -1;
  P_error_msg  := SUBSTR(SQLERRM,1,200);
  ROLLBACK;
  RAISE;
END Sp_Bond_Trx_Secu_Nextg;