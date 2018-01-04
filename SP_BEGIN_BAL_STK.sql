create or replace PROCEDURE Sp_Begin_Bal_Stk(P_BAL_DATE IN DATE,
							   P_START_DATE IN DATE,
							   P_END_DATE IN DATE,
							   P_USER_ID IN T_SECU_BAL.USER_ID%TYPE,
							   P_IP_ADDRESS IN T_MANY_HEADER.IP_ADDRESS%TYPE,
							   P_ERROR_CODE OUT NUMBER,
							   P_ERROR_MSG OUT VARCHAR2   ) IS

-- 10apr2017 dirubah spy T STKBAL tidak ambil dr T STKHANd, diambil dr T STK MOVEMENT dan T SECU BAL
-- shg proses ini dapat diulang
-- 2mar15 cek secu jurnal bond trx at value date

CURSOR csr_main IS
	SELECT GL_ACCT_CD, CLIENT_CD, STK_CD,END_QTY,l_f
	FROM(	
      SELECT client_cd,  stk_cd,  gl_acct_cd,	SUM(qty) end_qty,l_f
			FROM( 
          SELECT client_cd,  stk_cd,  gl_acct_cd,
          DECODE(trim(db_cr_flg),'D',1, -1) * DECODE(SIGN(TO_NUMBER(gl_acct_cd) - 30),-1, 1, -1) * (NVL(withdrawn_share_qty,0) + NVL(total_share_qty,0)) qty, 'L' l_f
					FROM T_STK_MOVEMENT 
					WHERE doc_stat = '2'
					AND doc_dt BETWEEN p_start_date AND p_end_date
--					AND client_Cd = p_client_cd
--				AND stk_cd = p_stk_cd
          UNION ALL
          SELECT  client_cd,  stk_cd, gl_acct_cd, qty beg_bal, 'L' l_f
					FROM T_SECU_BAL 
					WHERE bal_dt = p_start_date
--					AND client_Cd = p_client_cd
--					AND stk_cd = p_stk_cd
					) 
				GROUP BY client_cd, stk_cd,gl_acct_cd,l_f
			--	ORDER BY 1,3
				)
  WHERE end_qty <> 0;
  

CURSOR csr_stkbal IS
      SELECT client_cd,  stk_cd,  l_f,
                 SUM(decode(gl_acct_cd, '12', 1,'14',1,'10',1,'09',1,'51',-1,0) *qty) theo_qty,
                 SUM(decode(gl_acct_cd, '36',1,0) *qty) onh_qty,
                 SUM(decode(gl_acct_cd, '59',1,'55',1,0) *qty) os_buy,
                 SUM(decode(gl_acct_cd, '21',1,'17',1,0) *qty) os_sell,
                 SUM(decode(gl_acct_cd, '09',1,0) *qty) repo_beli,
                 SUM(decode(gl_acct_cd, '33',1,0) *qty) on_custody,
                 SUM(decode(gl_acct_cd, '13',1,0) *qty) subrek_004
			FROM( 
          SELECT client_cd,  stk_cd,  trim(gl_acct_cd) gl_acct_cd,
          DECODE(trim(db_cr_flg),'D',1, -1) * DECODE(SIGN(TO_NUMBER(gl_acct_cd) - 30),-1, 1, -1)
          * (NVL(withdrawn_share_qty,0) + NVL(total_share_qty,0)) qty, 'L' l_f
					FROM T_STK_MOVEMENT 
					WHERE doc_stat = '2'
					AND doc_dt BETWEEN p_start_date AND p_end_date
--					AND client_Cd = p_client_cd
--					AND stk_cd = p_stk_cd
          UNION ALL
         select t.client_Cd, t.stk_cd, trim(t.gl_acct_cd) gl_acct_cd,
         qty, 'L' l_f
            from t_secu_bal t
            where bal_dt = p_start_date
--            and client_Cd = p_client_cd
--            and stk_Cd = p_stk_cd
                    ) 
				GROUP BY client_cd, stk_cd,l_f;
			
v_cnt NUMBER;
v_max_dt DATE;
V_ERR EXCEPTION;
V_ERROR_CODE NUMBER(5);
V_ERROR_MSG VARCHAR2(200);
V_MENU_NAME T_MANY_HEADER.MENU_NAME%TYPE:='MONTH END STOCK';
V_UPDATE_DATE T_MANY_HEADER.UPDATE_DATE%TYPE;
V_UPDATE_SEQ T_MANY_HEADER.UPDATE_SEQ%TYPE;
BEGIN



		BEGIN
		DELETE FROM c_stkhand_month_end;
		EXCEPTION
		WHEN OTHERS THEN
			V_ERROR_CODE := -4;
			V_ERROR_MSG := SUBSTR('DELETE c_stkhand_month_end'|| SQLERRM,1,200);
			RAISE V_ERR;
		END;
		--BACKUP T_STKHAND
		BEGIN
		INSERT INTO c_stkhand_month_end
		select A.* FROM T_STKHAND a, MST_CLIENT b
			WHERE a.client_Cd = b.client_cd
			AND b.susp_stat <> 'C';
		EXCEPTION
		WHEN OTHERS THEN
			V_ERROR_CODE := -5;
			V_ERROR_MSG := SUBSTR('Select T_STKBAL'|| SQLERRM,1,200);
			RAISE V_ERR;
		END;

		BEGIN
      SELECT COUNT(1) INTO v_cnt FROM T_STKBAL WHERE BAL_DT = P_BAL_DATE ;
		EXCEPTION
		WHEN OTHERS THEN
			V_ERROR_CODE := -10;
			V_ERROR_MSG := SUBSTR('Select T_STKBAL'|| SQLERRM,1,200);
			RAISE V_ERR;
		END;
		
		IF v_cnt >0 THEN
			BEGIN
			DELETE FROM  T_STKBAL WHERE BAL_DT = P_BAL_DATE;
			EXCEPTION
			WHEN OTHERS THEN
				V_ERROR_CODE := -11;
				V_ERROR_MSG := SUBSTR('DELETE T_STKBAL '||P_BAL_DATE||' '|| SQLERRM,1,200);
				RAISE V_ERR;
			END;		

			BEGIN
			DELETE FROM  T_SECU_BAL WHERE BAL_DT = P_BAL_DATE;
			EXCEPTION
			WHEN OTHERS THEN
				V_ERROR_CODE := -12;
				V_ERROR_MSG := SUBSTR('DELETE T_SECU_BAL '||P_BAL_DATE||' '|| SQLERRM,1,200);
				RAISE V_ERR;
			END;		
    commit;

		END IF;


		BEGIN
        SELECT COUNT(1) INTO v_cnt  FROM T_CONTRACTS WHERE contr_dt BETWEEN p_end_date -20 AND p_end_date
        AND contr_stat <> 'C'		AND due_dt_for_amt <= p_end_date  AND NVL(sett_qty,0) < qty;
		EXCEPTION
		WHEN OTHERS THEN
			V_ERROR_CODE := -16;
			V_ERROR_MSG := SUBSTR('Select t_contracts'|| SQLERRM,1,200);
			RAISE V_ERR;
		END;
			
		IF v_cnt >0 THEN
				V_ERROR_CODE := -17;
				V_ERROR_MSG := SUBSTR('Some transaction NOT SETTLED',1,200);
				RAISE V_ERR;
		END IF;

-- 2mar15 cek secu jurnal bond trx at value date
   		  v_cnt :=0;
		  BEGIN
   		  SELECT COUNT(1), MAX(value_dt)  INTO v_cnt, v_max_dt
			FROM T_BOND_TRX
			WHERE trx_date BETWEEN p_start_date AND p_end_date
			AND value_dt <= p_end_date
			AND approved_sts = 'A'
			AND doc_num IS NOT NULL
			AND settle_Secu_flg IS NULL;
			EXCEPTION
			WHEN NO_DATA_FOUND THEN
			       v_cnt := 0;
			WHEN OTHERS THEN
			V_ERROR_CODE := -10;
			V_ERROR_MSG := SUBSTR('Cek bond trx VALUE DATE jurnal '||' '||SQLERRM,1,200);
			RAISE V_ERR;
			END;

			IF v_cnt > 0 THEN
				V_ERROR_CODE := -20;
				V_ERROR_MSG := SUBSTR('Bond trx value date '||TO_CHAR(v_max_dt,'dd/mm/yy')||' belum dijurnal',1,200);
				RAISE V_ERR;
			END IF;

			
			
			
				--02SEP2015
				--EXECUTE SP HEADER
         BEGIN
        Sp_T_Many_Header_Insert(V_MENU_NAME,
                               'I',
                               P_USER_ID,
                               P_IP_ADDRESS,
                               NULL,
                               V_UPDATE_DATE,
                               V_UPDATE_SEQ,
                               V_ERROR_CODE,
                               V_ERROR_MSG);
        EXCEPTION
              WHEN OTHERS THEN
                 V_ERROR_CODE := -30;
                 V_ERROR_MSG := SUBSTR('SP_T_MANY_HEADER_INSERT '|| SQLERRM(SQLCODE),1,200);
                RAISE V_ERR;
            END;
			
			BEGIN
			Sp_Month_End_T_Stkbal_Upd(	P_BAL_DATE,--P_BAL_DT,
										'I',--P_UPD_STATUS,
										V_UPDATE_DATE,--P_UPDATE_DATE,
										V_UPDATE_SEQ,--P_UPDATE_SEQ,
										1,
										V_ERROR_CODE,
										V_ERROR_MSG);
			  EXCEPTION
              WHEN OTHERS THEN
                 V_ERROR_CODE := -40;
                 V_ERROR_MSG := SUBSTR('SP_MONTH_END_T_STKBAL_UPD '|| SQLERRM(SQLCODE),1,200);
                RAISE V_ERR;
            END;
			
			IF V_ERROR_CODE < 0 THEN
				V_ERROR_CODE := -50;
				V_ERROR_MSG := SUBSTR('SP_MONTH_END_T_STKBAL_UPD '||V_ERROR_MSG,1,200);
				RAISE V_ERR;
			END IF;
			
		BEGIN	
			UPDATE T_MANY_HEADER
			SET approved_status = 'A',
			approved_user_id = P_USER_ID,
			approved_date = SYSDATE,
			approved_ip_address = P_IP_ADDRESS
			WHERE menu_name = V_MENU_NAME
			AND update_date = V_UPDATE_DATE
			AND update_seq = V_UPDATE_SEQ;
		EXCEPTION
			WHEN OTHERS THEN
				v_error_code := -60;
				v_error_msg :=  SUBSTR('Update t_MANY_HEADER  '||SQLERRM,1,200);
				RAISE v_err;
		END;	
			
			

   FOR REC IN CSR_MAIN LOOP

		  BEGIN

		  INSERT INTO IPNEXTG.T_SECU_BAL (
 			   BAL_DT, CLIENT_CD, STK_CD,
 			   STATUS, GL_ACCT_CD, QTY,
 			   CRE_DT, USER_ID)
 	      VALUES (p_bal_date, rec.client_cd, rec.stk_cd,
 			    rec.l_f, trim(rec.gl_acct_cd), rec.end_qty,
 			    SYSDATE, p_USER_ID);

		  EXCEPTION
		 	WHEN OTHERS THEN
			V_ERROR_CODE := -80;
			V_ERROR_MSG := SUBSTR('insert on T_SECU_BAL '||rec.client_cd||' '||rec.stk_cd||' '||rec.gl_acct_cd||' '||SQLERRM,1,200);
			RAISE V_ERR;
		  END;


       
   END LOOP;

   FOR RECS IN CSR_STKBAL LOOP
			 
		  BEGIN
        Insert into T_STKBAL (BAL_DT,CLIENT_CD,STK_CD,L_F,
        BEG_BAL_QTY,BEG_ON_HAND,OS_BUY,OS_SELL,
        ON_LENT,ON_BORROW,
        REPO_BELI,REPO_JUAL,
        ON_BAE,ON_CUSTODY,
        REPO_CLIENT,REPOJ_CLIENT_IN,
        AVG_PRICE,
        CRE_DT,USER_ID,UPD_DT,UPD_BY,
        OS_CORP_ACT,OS_BONUS,SUBREK_004) 
        values (p_bal_date, recs.client_cd, recs.stk_cd, recs.l_f,
        recs.theo_qty, recs.onh_qty, recs.os_buy,  recs.os_sell,
        0,0,
        recs.repo_beli,0,
        0,recs.on_custody,
        0,0,
        0,
        sysdate, p_user_id, null, null,
        0, 0, recs.subrek_004);
		  EXCEPTION
		 	WHEN OTHERS THEN
			V_ERROR_CODE := -90;
			V_ERROR_MSG := SUBSTR('insert on T_STKBAL '||recs.client_cd||' '||recs.stk_cd||' '||SQLERRM,1,200);
			RAISE V_ERR;
		  END;

	END LOOP;
  commit;
	P_ERROR_CODE := 1;
	P_ERROR_MSG := '';

EXCEPTION
	WHEN NO_DATA_FOUND THEN
		NULL;
	WHEN v_err THEN
		ROLLBACK;
		p_error_code := v_error_code;
		p_error_msg := v_error_msg;
	WHEN OTHERS THEN
   -- Consider logging the error and then re-raise
		ROLLBACK;
		p_error_code := -1;
		p_error_msg := SUBSTR(SQLERRM(SQLCODE),1,200);
		RAISE;
END Sp_Begin_Bal_Stk;