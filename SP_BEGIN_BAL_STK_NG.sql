create or replace 
PROCEDURE SP_BEGIN_BAL_STK_NG(P_BAL_DATE IN DATE,
							   P_START_DATE IN DATE,
							   P_END_DATE IN DATE,
							   P_USER_ID IN T_SECU_BAL.USER_ID%TYPE,
							   P_ERROR_CODE OUT NUMBER,
							   P_ERROR_MSG OUT VARCHAR2   ) IS

-- 2mar15 cek secu jurnal bond trx at value date

CURSOR csr_main IS
	SELECT GL_ACCT_CD, CLIENT_CD, STK_CD, L_F, END_QTY
	FROM(	SELECT b.gl_acct_cd,  b.CLIENT_CD,  b.STK_CD, b.L_F,
				   NVL(MAX(B2.beg_bal),0)+DECODE(SIGN(TO_NUMBER(B.gl_acct_cd) - 30),-1, 1, -1) * (NVL(SUM(A.D),0)-NVL(SUM(A.C),0) ) end_qty
			FROM( SELECT gl_acct_cd, client_cd, db_cr_flg, status, stk_cd,
					DECODE(trim(db_cr_flg),'D',NVL(withdrawn_share_qty,0) + NVL(total_share_qty,0)) D,
					DECODE(trim(db_cr_flg),'C',NVL(withdrawn_share_qty,0) + NVL(total_share_qty,0)) C
					FROM T_STK_MOVEMENT
					WHERE doc_stat = '2'
					AND doc_dt(+) BETWEEN p_start_date AND p_end_date) A,
				(SELECT  DISTINCT t.client_cd,  t.stk_cd, t.l_f, m.gl_acct_cd
					FROM T_STKHAND t, MST_SECURITIES_LEDGER m )B,
				(SELECT  client_cd,  stk_cd, status, gl_acct_cd, qty beg_bal
					FROM T_SECU_BAL
					WHERE bal_dt = p_start_date
					) B2
				WHERE B.stk_cd = A.stk_cd(+)
				AND B.client_cd = A.client_cd(+)
				AND B.gl_acct_cd = A.gl_acct_cd(+)
				AND B.client_cd = B2.client_cd(+)
				AND B.stk_cd = B2.stk_cd(+)
				AND B.gl_acct_cd = B2.gl_acct_cd(+)
				GROUP BY b.client_cd, b.stk_cd,b.L_F, b.gl_acct_cd)
	WHERE end_qty <> 0;

-- where t.client_cd = 'BAMB001M') B,
v_cnt NUMBER;
v_max_dt DATE;
V_ERR EXCEPTION;
V_ERROR_CODE NUMBER(5);
V_ERROR_MSG VARCHAR2(200);
BEGIN

		BEGIN
		SELECT COUNT(1) INTO v_cnt FROM T_STKBAL WHERE BAL_DT = P_BAL_DATE ;
		EXCEPTION
		WHEN OTHERS THEN
			V_ERROR_CODE := -10;
			V_ERROR_MSG := SUBSTR('Select T_STKBAL'|| SQLERRM,1,200);
			RAISE V_ERR;
		END;
		
		IF v_cnt >0 THEN
		V_ERROR_CODE := -15;
				V_ERROR_MSG := SUBSTR('Sudah diproses',1,200);
				RAISE V_ERR;
		END IF;


		begin
		select count(1) into v_cnt  from t_contracts where contr_dt between p_end_date -20 and p_end_date
														and contr_stat <> 'C'		
														and due_dt_for_amt <= p_end_date
														and nvl(sett_qty,0) < qty;
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

		begin
		select count(1) into v_cnt from t_bond_trx where trx_date between p_end_date -20 and p_end_date
														and approved_sts = 'A'			
														and value_dt <=  p_end_date
														and doc_num is not null		
														and nvl(settle_secu_flg,'N') = 'N';
		EXCEPTION
		WHEN OTHERS THEN
			V_ERROR_CODE := -18;
			V_ERROR_MSG := SUBSTR('Select t_contracts'|| SQLERRM,1,200);
			RAISE V_ERR;
		END;
			
		IF v_cnt >0 THEN
				V_ERROR_CODE := -19;
				V_ERROR_MSG := SUBSTR('Bond Transaction belum disettle',1,200);
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

			
				
-- T stk BAL
			BEGIN
				INSERT INTO IPNEXTG.T_STKBAL (
			   BAL_DT, CLIENT_CD, STK_CD,
			   L_F, BEG_BAL_QTY, BEG_ON_HAND,
			   OS_BUY, OS_SELL, ON_LENT,
			   ON_BORROW, REPO_BELI, REPO_JUAL,
			   ON_BAE, ON_CUSTODY, REPO_CLIENT,
			   REPOJ_CLIENT_IN, AVG_PRICE, CRE_DT,
			   USER_ID, UPD_DT, UPD_BY,
			   OS_CORP_ACT, OS_BONUS)
						SELECT
			p_bal_date, T_STKHAND.CLIENT_CD, STK_CD,
			 L_F,   BAL_QTY, ON_HAND,
			 OS_BUY,   OS_SELL,  ON_LENT,
			   ON_BORROW, REPO_BELI, REPO_JUAL,
		 ON_BAE, 	   ON_CUSTODY,  REPO_CLIENT,
			   REPOJ_CLIENT_IN, AVG_PRICE, SYSDATE,
			   p_user_id, T_STKHAND.UPD_DT, T_STKHAND.UPD_BY,
			   OS_CORP_ACT,	   OS_BONUS
			FROM IPNEXTG.T_STKHAND, MST_CLIENT
			WHERE T_STKHAND.client_Cd = MST_CLIENT.client_cd
			AND MST_CLIENT.susp_stat <> 'C';
			EXCEPTION
				WHEN OTHERS THEN
					V_ERROR_CODE := -30;
					V_ERROR_MSG := SUBSTR('INSERT INTO IPNEXTG.T_STKBAL ',1,200);
					RAISE V_ERR;
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
	  		--RAISE_APPLICATION_ERROR(-20100,'insert on T_SECU_BAL '||rec.client_cd||' '||rec.stk_cd||' '||rec.gl_acct_cd||' '||SQLERRM);
			V_ERROR_CODE := -40;
			V_ERROR_MSG := SUBSTR('insert on T_SECU_BAL '||rec.client_cd||' '||rec.stk_cd||' '||rec.gl_acct_cd||' '||SQLERRM,1,200);
			RAISE V_ERR;
		  END;

   END LOOP;


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
END SP_BEGIN_BAL_STK_NG;