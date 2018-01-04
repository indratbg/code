create or replace 
PROCEDURE Sp_Change_Ticker (
p_user_id T_STK_MOVEMENT.user_id%TYPE)
 IS

/******************************************************************************
   NAME:       Sp_Change_Ticker versi CHANDRA
   PURPOSE:
   Gen jurnal and upd T STKHAND
   - jika ada repo
      - create jurnal return dg stk code lama
      - create jurnal repo dgn stk code baru

   - INI TDK JADI jika ada outstanding buy/ sell,
--      1.create jurnal dg :
--        new stk code,
--        gl_acct_cd dan Db-cr_flg sama spt jurnal transaksi
--        doc_num = jika outstanding buy : '%RSN%', sell : '%WSN%'
--        jur_type = jika outstanding buy :RECVT, sell : WHDRT
--
--      2. settle trx jurnal
--            dg jurnal date = efektif chg ticker date
--            Doc_num = '%JVB%' or '%JVS%'
--            old stk code
--
--       3. create jurnal Recv / sell utk mereverse, upd yg terjadi di step 2,
--          dan spy terlihat di stk history


    - jika ada on hand
          create jurnal withdraw
          dg jurnal date = efektif chg ticker date
          doc_num =   '%WSN%'
          jur_type =   WHDRT

      - 
           calc avg price utk new stk cd dan old stk_cd

    - porto sendiri yg dijaminkan
    - STK HAIRCUT KOMITE, STK HAIRCUT KPEI (for trading)
    - balance gl_acct porto sendiri ( 1030 PF,/ 1300 MU)

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        06/08/2014          1. Created this procedure.

	            11 may 2016 - rewrite


   NOTES:


******************************************************************************/
v_eff_dt_from       DATE;
v_eff_dt_to         DATE;
v_jur_dt      DATE;

CURSOR csr_onh IS
SELECT x.client_cd, stk_cd_old, on_hand, bal_qty, on_hand - NVL(os_sell,0) AS whdr_qty,
       os_buy, os_sell, on_bae,
	   				repo_beli, subrek_004,
					stk_cd_new, x.client_type, x.acct_type, x.lot_size, p.avg_price,
                  x.eff_dt
FROM( SELECT t.client_cd, t.stk_cd stk_cd_old, t.on_hand, t.bal_qty, t.os_buy, t.os_sell, t.on_bae,
	  		 			  t.repo_beli,  t.subrek_004, c.stk_cd_new,  r.lot_size,
                  DECODE(t.client_Cd,  trim(p.other_1),'H', DECODE(m.client_type_1, 'H','H','%')) client_type,
				  trim(m.client_type_1)||trim(m.client_type_2)||trim(m.client_type_3) acct_type,
				  c.EFF_DT
				FROM T_STKHAND t,
				MST_CLIENT m,
				MST_COMPANY p,
				MST_COUNTER r,
				( SELECT eff_Dt, stk_cd_old, stk_cd_new
				  FROM T_CHANGE_STK_CD
				  WHERE eff_Dt BETWEEN v_eff_dt_from AND v_eff_dt_to)  c
				WHERE t.stk_cd = c.stk_cd_old
				AND t.stk_cd= r.stk_cd
				AND t.client_Cd = m.client_cd
       -- AND t.client_Cd IN ('REKS051R')
				AND ( t.on_hand  - NVL(os_sell,0))  <> 0 ) x,
			( SELECT b.client_cd, mx.stk_cd, mx.max_dt AS avg_dt, b.avg_buy_price AS avg_price
			   FROM( SELECT client_Cd, a.stk_cd, MAX(avg_dt) max_dt
			                   FROM T_AVG_PRICE a, T_CHANGE_STK_CD c
							   WHERE a.stk_Cd =c.stk_cd_old
							   GROUP BY client_cd, a.stk_cd) mx,
							   T_AVG_PRICE b
				WHERE b.client_cd = mx.client_cd
				AND b.stk_cd = mx.stk_cd
				AND b.avg_dt = mx.max_dt )  p
WHERE x.client_cd = p.client_cd (+)
AND x.stk_cd_old = p.stk_cd(+)
ORDER BY 1;




CURSOR csr_repo IS
SELECT t.repo_num, t.doc_num, t.ref_doc_num, doc_dt, t.client_cd,    stk_cd_old,
       t.stk_cd_new, total_share_qty, withdrawn_share_qty,
	   		t.S_D_TYPE,	 t.acct_type, t.TOTAL_LOT, t.ODD_LOT_DOC, t.DOC_REM
FROM
( SELECT stk_cd_new,s.repo_num, t.doc_num, t.ref_doc_num, doc_dt, t.client_cd,
      t.stk_cd AS stk_cd_old,
     total_share_qty, withdrawn_share_qty,
	   		t.S_D_TYPE,	 t.acct_type, t.TOTAL_LOT, t.ODD_LOT_DOC, t.DOC_REM
	FROM T_STK_MOVEMENT T, T_REPO_STK	s,
	( SELECT stk_cd_old, stk_cd_new
	  FROM T_CHANGE_STK_CD
	  WHERE v_jur_Dt BETWEEN eff_dt AND get_due_date(3,eff_dt))  c
	WHERE s.doc_num = t.doc_num
	AND t.doc_dt <=  v_jur_dt
  --AND t.client_Cd IN ('AISH001R','ANDI006R', 'KATA001R')
	AND s.mvmt_type = 'REPO'
	AND t.seqno = 1
	AND t.doc_stat = '2'
	AND t.ref_doc_num IN ('UNSETTLED','REPO CLIENT')
	AND t.stk_cd = c.stk_cd_old) T,
(
	SELECT MAX(repo_ref) repo_num, MAX(ref_doc_num) ref_doc_num, MAX(s_d_type) s_d_type
	FROM
	(
		SELECT DECODE(field_name,'REPO_REF',field_value, NULL) repo_ref,
		DECODE(field_name,'REF_DOC_NUM',field_value, NULL) ref_doc_num,
		DECODE(field_name,'S_D_TYPE',field_value, NULL) s_d_type,
		a.update_date, a.update_seq, record_seq
		FROM T_MANY_DETAIL a JOIN T_MANY_HEADER b
		ON a.update_seq = b.update_seq
		AND a.update_date = b.update_date
		WHERE menu_name = 'STOCK MOVEMENT ENTRY'
		AND field_name IN ('REPO_REF','REF_DOC_NUM','S_D_TYPE')
		AND approved_status = 'E'
		AND status = 'I'
		AND record_seq = 1
	)
	GROUP BY update_date, update_seq, record_seq
	HAVING MAX(s_d_type) IN ('I','J')
) m
WHERE t.doc_num = m.ref_doc_num(+)
AND m.ref_doc_num IS NULL
;



CURSOR csr_ticker IS
SELECT eff_Dt, stk_cd_old, stk_cd_new
				  FROM T_CHANGE_STK_CD
				  WHERE v_jur_Dt BETWEEN eff_dt AND get_due_date(3,eff_dt);

---T_PORTO_JAMINAN
CURSOR CSR_JAMINAN(A_EFF_DT DATE) IS
SELECT A.*,B.STK_CD_NEW,B.STK_CD_OLD,B.EFF_DT 
FROM T_PORTO_JAMINAN A, T_CHANGE_STK_CD B
WHERE A.STK_CD=B.STK_CD_OLD
AND A.FROM_DT=(SELECT MAX(FROM_DT) FROM T_PORTO_JAMINAN
               WHERE STK_CD=B.STK_CD_OLD)
AND B.EFF_DT=A_EFF_DT;

--T_HAIRCUT_MKBD
CURSOR CSR_HAIRCUT(A_EFF_DT DATE) IS
SELECT C.STK_CD_NEW ,T.* FROM  
	(SELECT * FROM T_CHANGE_STK_CD WHERE EFF_DT=A_EFF_DT)C,
      T_HAIRCUT_KOMITE T,
	 ( SELECT stk_cd, MAX(eff_dt) max_dt 
	 FROM T_HAIRCUT_KOMITE 
	 WHERE eff_dt <= A_EFF_DT
	 GROUP BY stk_cd) mx
WHERE T.EFF_DT=MX.MAX_DT
AND T.STK_CD=MX.STK_CD
AND T.STK_CD = C.STK_CD_OLD;
--ORDER BY T.STK_CD


v_flow INTEGER;
v_max_flow INTEGER;
v_cnt NUMBER;

v_jur_type T_STK_MOVEMENT.DOC_NUM%TYPE;
v_doc_num T_STK_MOVEMENT.DOC_NUM%TYPE;
v_stk_cd  				T_STK_MOVEMENT.STK_CD%TYPE;
V_DB_CR_FLG  T_STK_MOVEMENT.DB_CR_FLG%TYPE;
V_DB_CR_FLG2  T_STK_MOVEMENT.DB_CR_FLG%TYPE;
V_GL_ACCT_CD  T_STK_MOVEMENT.GL_ACCT_CD%TYPE;
V_GL_ACCT_CD2  T_STK_MOVEMENT.GL_ACCT_CD%TYPE;
v_deb_qty   T_STK_MOVEMENT.TOTAL_SHARE_QTY%TYPE;
v_cre_qty   T_STK_MOVEMENT.TOTAL_SHARE_QTY%TYPE;
V_DOC_REM	T_STK_MOVEMENT.DOC_REM%TYPE;
V_TOTAL_LOT  T_STK_MOVEMENT.TOTAL_LOT%TYPE;
V_ODD_LOT_DOC	T_STK_MOVEMENT.ODD_LOT_DOC%TYPE;
v_s_d_type T_STK_MOVEMENT.s_d_type%TYPE;
v_mvmt_type T_STK_MOVEMENT.jur_type%TYPE;
v_mvmt_type_upd T_STK_MOVEMENT.jur_type%TYPE; -- for upd T STKHAND

v_ref_doc_num T_STK_MOVEMENT.ref_doc_num%TYPE;
v_jur T_STK_MOVEMENT.seqno%TYPE;
v_max_jur T_STK_MOVEMENT.seqno%TYPE;
v_client_type  CHAR(1);
v_cre_dt DATE;

v_loop         INTEGER;
v_err 					EXCEPTION;
v_error_code			NUMBER;
v_error_msg				VARCHAR2(1000);
BEGIN


	 v_jur_dt   := TRUNC(SYSDATE);
 --v_jur_dt := '13sep2016';


      BEGIN
      SELECT eff_dt, get_due_date(2,eff_dt) INTO v_eff_dt_from, v_eff_dt_to
	  FROM T_CHANGE_STK_CD
	  WHERE  v_jur_dt BETWEEN eff_dt AND get_due_date(2,eff_dt)
    AND ROWNUM =1;
	  EXCEPTION
	  WHEN NO_DATA_FOUND THEN
	       v_error_code := -3;
				v_error_msg :=   'TIDAK ADA CHANGE TICKER ' ;
				RAISE v_err;
		WHEN OTHERS THEN
			  v_error_code := -2;
				v_error_msg :=  SUBSTR('Retrieve  t_Change_Stk '||SQLERRM,1,200);
				RAISE v_err;
		END;


		  V_DB_CR_FLG := 'D';
		  V_DB_CR_FLG2 := 'C';

    FOR repo IN Csr_repo LOOP

      FOR v_loop IN 1..2 LOOP

          v_doc_num := Get_Stk_Jurnum(v_jur_dt,'JVA');

          IF v_loop = 1 THEN --RETURN REPO dg kode lama
            v_mvmt_type := 'REREPOCRTN';
            v_stk_cd := repo.stk_cd_old;
            v_ref_doc_num := repo.doc_num;
            v_S_D_TYPE := 'J';
            v_doc_rem := 'RETURN REPO '||repo.client_cd;


          ELSE
            v_mvmt_type := 'REREPOC'; -- create repo dgn NEW STK CODE
            v_stk_cd := repo.stk_cd_new;
            v_ref_doc_num := repo.ref_doc_num;
            v_S_D_TYPE := 'J';
            v_doc_rem := repo.doc_rem;

          END IF;

          BEGIN
            Sp_Get_Secu_Acct(v_jur_dt, '%', v_mvmt_type,V_GL_ACCT_CD, V_GL_ACCT_CD2,v_error_code ,v_error_msg);
          EXCEPTION
          WHEN OTHERS THEN
                v_error_code := -5;
                v_error_msg :=  SUBSTR('sp_get_secu_acct '||v_mvmt_type||' '||repo.client_cd||SQLERRM,1,200);
                RAISE v_err;
          END;

          IF v_error_code < 0 THEN
             RAISE v_err;
          END IF;

          BEGIN
              Sp_Secu_Jurnal_Nextg
              (
              V_DOC_NUM,
              v_ref_doc_num,
              V_jur_DT,
              repo.CLIENT_CD,
              v_stk_cd,
              v_S_D_TYPE,
              repo.ODD_LOT_DOC,
              repo.TOTAL_LOT,
              repo.TOTAL_SHARE_QTY,
              v_doc_rem,
              '2',--V_DOC_STAT
              NULL, --V_STK_STAT
              repo.WITHDRAWN_SHARE_QTY,
              NULL, --V_REGD_HLDR
              NULL, --V_WITHDRAW_REASON_CD
              V_GL_ACCT_CD,
              NULL, --V_ACCT_TYPE	IN	T_STK_MOVEMENT.ACCT_TYPE%TYPE,
              V_DB_CR_FLG,
              P_USER_ID,
              SYSDATE,
              NULL, --UPD_DT
              v_jur_dt, --V_DUE_DT_FOR_CERT
              v_jur_dt, --V_DUE_DT_ONHAND
              1, --v_jur
              0, --_PRICE
              'N', -- v_manual
              v_mvmt_type,
              2, --v_jur_2
              V_GL_ACCT_CD2,
              V_DB_CR_FLG2,
              v_error_code,
              v_error_msg
              );
          EXCEPTION
          WHEN OTHERS THEN
                v_error_code := -10;
                v_error_msg :=  SUBSTR('Sp_Secu_Jurnal_Nextg debit '||V_GL_ACCT_CD||' credit '||V_GL_ACCT_CD2||' '||repo.client_cd||SQLERRM,1,200);
                RAISE v_err;
          END;
          IF v_error_code < 0 THEN
             RAISE v_err;
          END IF;

          BEGIN
              Sp_Upd_T_Stkhand
              ( repo.CLIENT_CD,
                v_STK_CD,
                '%', --P_GL_ACCT_CD,
                'D', --dummy
                repo.TOTAL_SHARE_QTY,
                v_mvmt_type,
                P_USER_ID,
                v_error_code,
                v_error_msg);
          EXCEPTION
          WHEN OTHERS THEN
                    v_error_code := -15;
                    v_error_msg :=  SUBSTR('Sp_Upd_T_Stkhand '||v_mvmt_type||' '||repo.client_cd||SQLERRM,1,200);
                    RAISE v_err;
          END;
          IF v_error_code < 0 THEN
             RAISE v_err;
          END IF;


          IF v_loop = 1 THEN
              v_mvmt_type := 'RETURN';
          ELSE
              v_mvmt_type := 'REPO';
          END IF;

          BEGIN
          INSERT INTO IPNEXTG.T_REPO_STK (
             REPO_NUM, DOC_NUM, MVMT_TYPE,
             USER_ID, CRE_DT, UPD_DT,
             UPD_BY, APPROVED_DT, APPROVED_BY,
             APPROVED_STAT)
          VALUES ( repo.repo_num, V_DOC_NUM, v_mvmt_type,
              p_user_id, SYSDATE, NULL,
              NULL, SYSDATE, p_user_id, 'A');
          EXCEPTION
          WHEN OTHERS THEN
                v_error_code := -20;
                v_error_msg :=  SUBSTR('Sp_Upd_T_Stkhand '||v_mvmt_type||' '||repo.client_cd||SQLERRM,1,200);
                RAISE v_err;
          END;

          IF v_loop = 1 THEN
              BEGIN
                UPDATE T_STK_MOVEMENT
                SET ref_doc_num = 'SETTLED'
                WHERE doc_num = repo.doc_num;
              EXCEPTION
                  WHEN OTHERS THEN
                        v_error_code := -25;
                        v_error_msg :=  SUBSTR('UPDATE T_STK_MOVEMENT ref_doc_num'||repo.doc_num||' '||repo.client_cd||SQLERRM,1,200);
                        RAISE v_err;
              END;
          END IF;


      END LOOP;
		END LOOP;





--ON HAND ================================ON HAND=============================
   	FOR rec IN csr_onh LOOP


				     v_max_flow := 2;
					-- 1 recv , 2 withdraw

	  	   FOR v_flow IN 1..v_max_flow LOOP
  	  		  v_deb_qty := 0;
  	  		  v_cre_qty := 0;


					  IF rec.whdr_qty > 0 THEN

                  IF v_flow = 1   AND rec.whdr_qty > 0  THEN    -- receive

                        v_jur_type := 'RSN';
                        v_mvmt_type := 'RECV';
                        v_s_d_type := 'C';

                        v_deb_qty  := rec.whdr_qty;
                        v_cre_qty  := 0;

                        v_stk_cd := rec.stk_cd_new;
                        v_doc_rem := 'Move from '||rec.stk_cd_old;

                  END IF;

                  IF v_flow = 2    AND rec.whdr_qty > 0 THEN -- withdraw stk cd old
                        v_jur_type := 'WSN';
                        v_mvmt_type := 'WHDR';
                        v_s_d_type := 'C';
                        v_deb_qty  := 0;
                        v_cre_qty  := rec.whdr_qty;
                        v_stk_cd := rec.stk_cd_old;
                        v_doc_rem := 'Move to '||rec.stk_cd_new;
                  END IF;

								  V_TOTAL_LOT := TRUNC(rec.whdr_qty / rec.lot_size, 0);
								  IF MOD( rec.whdr_qty, rec.lot_size) > 0 THEN
								  	 	  V_ODD_LOT_DOC	:= 'Y';
									ELSE
										  V_ODD_LOT_DOC	:= 'N';
									END IF;


                  v_doc_num := Get_Stk_Jurnum(v_jur_dt,v_jur_type);

                  BEGIN
                 Sp_Get_Secu_Acct(v_jur_dt, rec.client_type, v_mvmt_type,V_GL_ACCT_CD, V_GL_ACCT_CD2,v_error_code ,v_error_msg);
                    EXCEPTION
                    WHEN OTHERS THEN
                          v_error_code := -85;
                          v_error_msg :=  SUBSTR('sp_get_secu_acct '||v_mvmt_type||' '||rec.client_cd||SQLERRM,1,200);
                          RAISE v_err;
                    END;
                  IF v_error_code < 0 THEN
                     RAISE v_err;
                  END IF;

                  v_mvmt_type := v_mvmt_type||'T';
                  IF v_mvmt_type = 'WHDRT' THEN
                       v_cre_dt := v_jur_dt + 0.1;
                  ELSE
                        v_cre_dt := v_jur_dt;
                  END IF;

                    BEGIN
                    Sp_Secu_Jurnal_Nextg
                    (
                    V_DOC_NUM,
                    NULL, --REF_DOC_NUM%TYPE,
                    V_jur_DT,
                    rec.CLIENT_CD,
                    v_STK_CD,
                    V_S_D_TYPE,
                    V_ODD_LOT_DOC,
                    V_TOTAL_LOT,
                    v_deb_qty, --V_TOTAL_SHARE_QTY
                    V_DOC_REM,
                    '2',--V_DOC_STAT
                    'L', --V_STK_STAT
                    v_cre_qty, --V_WITHDRAWN_SHARE_QTY
                    NULL, --V_REGD_HLDR
                    NULL, --V_WITHDRAW_REASON_CD
                    V_GL_ACCT_CD,
                    rec.acct_type, --V_ACCT_TYPE	IN	T_STK_MOVEMENT.ACCT_TYPE%TYPE,
                    V_DB_CR_FLG,
                    P_USER_ID,
                    V_CRE_DT,
                    NULL, --UPD_DT
                    v_jur_dt, --V_DUE_DT_FOR_CERT
                    v_jur_dt, --V_DUE_DT_ONHAND
                    1, --v_jur
                    rec.avg_price, --V_PRICE
                    'N', -- v_manual
                    v_mvmt_TYPE,
                    2, --v_jur_2
                    V_GL_ACCT_CD2,
                    V_DB_CR_FLG2,
                    v_error_code,
                    v_error_msg
                    );
                    EXCEPTION
                    WHEN OTHERS THEN
                          v_error_code := -95;
                          v_error_msg :=  SUBSTR('sp_secu_jurnal debit '||V_GL_ACCT_CD||' credit '||V_GL_ACCT_CD2||' '||rec.client_cd||SQLERRM,1,200);
                          RAISE v_err;
                    END;
                  IF v_error_code < 0 THEN
                     RAISE v_err;
                  END IF;

                  BEGIN
                    Sp_Upd_T_Stkhand
                    ( rec.CLIENT_CD,
                      v_STK_CD,
                      '%', --P_GL_ACCT_CD,
                      'D', --dummy
                      rec.whdr_qty,
                      SUBSTR(v_mvmt_type,1,4),
                      P_USER_ID,
                      v_error_code,
                      v_error_msg);
                  EXCEPTION
                    WHEN OTHERS THEN
                          v_error_code := -105;
                          v_error_msg :=  SUBSTR('Sp_Upd_T_Stkhand '||v_mvmt_type||' '||rec.client_cd||SQLERRM,1,200);
                          RAISE v_err;
                    END;
                    IF v_error_code < 0 THEN
                       RAISE v_err;
                    END IF;

						END IF;

				END LOOP;

		  END LOOP;

--------------------------------------AVG PRICE =======================================

     FOR rect IN csr_ticker LOOP

        BEGIN
        Sp_Gen_Avg_Price(v_jur_dt,v_jur_dt, '%','_',rect.stk_cd_old,rect.stk_cd_old,p_user_id, NULL, v_error_code,v_error_msg);
            EXCEPTION
            WHEN OTHERS THEN
                  v_error_code := -115;
                  v_error_msg :=  SUBSTR('Gen_Avg_Price '||rect.stk_cd_old||SQLERRM,1,200);
                  RAISE v_err;
            END;

        BEGIN
        Sp_Gen_Avg_Price(v_jur_dt,v_jur_dt,'%','_',rect.stk_cd_new,rect.stk_cd_new,p_user_id,NULL, v_error_code,v_error_msg);
            EXCEPTION
            WHEN OTHERS THEN
                  v_error_code := -125;
                  v_error_msg :=  SUBSTR('Gen_Avg_Price '||rect.stk_cd_old||SQLERRM,1,200);
                  RAISE v_err;
            END;


     END LOOP;

----T_PORTO_JAMINAN----

FOR REC IN CSR_JAMINAN(v_jur_dt) LOOP

    BEGIN
    SELECT COUNT(1) INTO V_CNT FROM T_PORTO_JAMINAN WHERE FROM_DT=v_jur_dt AND STK_CD=REC.STK_CD_NEW AND CLIENT_CD=REC.CLIENT_cD;
    EXCEPTION
    WHEN OTHERS THEN
          v_error_code := -5;
          v_error_msg :=  SUBSTR('INSERT INTO T_PORTO_JAMINAN STOCK LAMA '||SQLERRM,1,200);
          RAISE v_err;
      END;
  
    IF V_CNT=0 THEN

          --SET QTY=0 UNTUK STK_CD LAMA
          BEGIN
          INSERT INTO T_PORTO_JAMINAN(FROM_DT,CLIENT_CD,STK_CD,QTY,CRE_DT,USER_ID,APPROVED_DT,APPROVED_BY,APPROVED_STAT)
          VALUES(REC.EFF_DT,REC.CLIENT_CD,REC.STK_CD,0,SYSDATE,P_USER_ID,SYSDATE,P_USER_ID,'A');
          EXCEPTION
          WHEN OTHERS THEN
                v_error_code := -6;
                v_error_msg :=  SUBSTR('INSERT INTO T_PORTO_JAMINAN STOCK LAMA '||SQLERRM,1,200);
                RAISE v_err;
          END;
    
          --SET QTY=QTY TERAKHIR UNTUK STK_CD BARU
          BEGIN
          INSERT INTO T_PORTO_JAMINAN(FROM_DT,CLIENT_CD,STK_CD,QTY,CRE_DT,USER_ID,APPROVED_DT,APPROVED_BY,APPROVED_STAT)
          VALUES(REC.EFF_DT,REC.CLIENT_CD,REC.STK_CD_NEW,REC.QTY,SYSDATE,P_USER_ID,SYSDATE,P_USER_ID,'A');
          EXCEPTION
          WHEN OTHERS THEN
                v_error_code := -7;
                v_error_msg :=  SUBSTR('INSERT INTO T_PORTO_JAMINAN STOCK BARU '||SQLERRM,1,200);
                RAISE v_err;
          END;
    
    END IF;

END LOOP;
----END T_PORTO_JAMINAN----

---T_HAIRCUT_KOMITE
FOR REC IN CSR_HAIRCUT(v_jur_dt) LOOP

	BEGIN
	SELECT COUNT(1) INTO V_CNT FROM T_HAIRCUT_KOMITE WHERE EFF_DT=v_jur_dt and stk_cd=rec.stk_cd_new;
    EXCEPTION
    WHEN OTHERS THEN
		v_error_code := -7;
		v_error_msg :=  SUBSTR('SELECT COUNT STK_CD_NEW FROM T_HAIRCUT_KOMITE '||SQLERRM,1,200);
		RAISE v_err;
    END;
	
	if v_cnt=0 then
	
	BEGIN
	INSERT INTO T_HAIRCUT_KOMITE(STATUS_DT,STK_CD,HAIRCUT,CREATE_DT,EFF_DT,APPROVED_STAT, USER_ID)
	VALUES(V_JUR_DT, REC.STK_CD_NEW,REC.HAIRCUT, SYSDATE,V_JUR_DT,'A',P_USER_ID);
	 EXCEPTION
    WHEN OTHERS THEN
		v_error_code := -7;
		v_error_msg :=  SUBSTR('INSERT INTO T_HAIRCUT_KOMITE STOCK BARU '||SQLERRM,1,200);
		RAISE v_err;
    END;
	
	end if;	  

END LOOP;
-----END T_HAIRCUT_KOMITE

  	COMMIT;

EXCEPTION
WHEN V_ERR THEN
	ROLLBACK;
	Sp_Insert_Orcl_Errlog('INSISTPRO', 'ORCLBO', 'PROCEDURE : SP_CHANGE_TICKER', TO_CHAR(v_error_code)||' '||v_error_msg);
WHEN NO_DATA_FOUND THEN
	NULL;
	--Sp_Insert_Orcl_Errlog('INSISTPRO', 'ORCLBO', 'PROCEDURE : SP_CHANGE_TICKER', SUBSTR(SQLERRM(SQLCODE),1,200));
WHEN OTHERS THEN
	Sp_Insert_Orcl_Errlog('INSISTPRO', 'ORCLBO', 'PROCEDURE : SP_CHANGE_TICKER', SUBSTR(SQLERRM(SQLCODE),1,200));
         -- Consider logging the error and then re-raise
	RAISE;
END Sp_Change_Ticker;