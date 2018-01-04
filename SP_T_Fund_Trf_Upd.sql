create or replace 
PROCEDURE SP_T_Fund_Trf_Upd
( 	p_doc_date DATE,
	p_doc_num		T_FUND_MOVEMENT.DOC_NUM%TYPE,
	p_trf_id		T_FUND_TRF.trf_id%TYPE,
	p_trf_type		T_FUND_TRF.trf_type%TYPE,
	p_upd_mode		CHAR,
	p_trf_flg		T_FUND_TRF.trf_flg%TYPE,
	P_User_Id		T_Fund_Movement.User_Id%Type,
	P_Error_Code	Out Number,
	p_error_msg		OUT  VARCHAR2
) IS

v_new_flg		T_FUND_TRF.trf_flg%TYPE;
v_old_flg		T_FUND_TRF.trf_flg%TYPE;
v_err			EXCEPTION;
v_error_code	NUMBER;
v_error_msg		VARCHAR2(200);
v_cnt			NUMBER;

BEGIN

	IF p_upd_mode  = 'NEW'  THEN
-- yg berasal dari RDCL : trf_flg = N
--                 PERD   trf_flg langsung = Y
        
		BEGIN
			SELECT COUNT(1) INTO v_cnt
			FROM T_FUND_TRF
			WHERE  doc_num = p_doc_num
			AND trf_id = p_trf_id
			AND trf_flg = 'N';-- yg lama
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				v_cnt := 0;
		END;

		IF v_cnt = 0 THEN
	 -- 23dec, karena perubahan 1202 ke 1200  	SELECT doc_date,p_trf_id,doc_num, DECODE(trim(gl_Acct_cd),'1202','BCA',trim(from_bank)),
			BEGIN
				INSERT INTO T_FUND_TRF 
				(
					TRF_DATE, TRF_ID, DOC_NUM, FUND_BANK_CD,
					CLIENT_CD, TRF_TYPE, TRF_FLG,
					TRF_TIMESTAMP, TRF_AMT, CRE_DT,
					UPD_DT, USER_ID
				)
				SELECT doc_date, p_trf_id, doc_num, 'BCA',
				client_cd, TRIM(p_trf_type), TRIM(p_trf_flg),
				SYSDATE, trx_amt, SYSDATE,
				NULL, p_user_id
				FROM T_FUND_MOVEMENT
				WHERE doc_num = p_doc_num;
			EXCEPTION
				WHEN OTHERS THEN
					v_error_code := -2;
					v_error_msg := SUBSTR('FL_FUND_TRF ' || p_doc_num || ' ' || SQLERRM,1,200);
					RAISE v_err;
			END;

		END IF;
	END IF;

	IF p_upd_mode = 'UPD'  THEN
 -- RDCL jika sudah ditransfer , trf_flg = Y
 -- RDCL

		v_new_flg := 'Y';
		v_old_flg := 'N';

		BEGIN
			UPDATE T_FUND_TRF
			SET trf_flg = v_new_flg,
			trf_id  = p_trf_id,
			trf_timestamp = SYSDATE,
			upd_dt = SYSDATE
			WHERE doc_num = p_doc_num
			AND trf_flg = v_old_flg;
		EXCEPTION
			WHEN OTHERS THEN
				v_error_code := -3;
				v_error_msg := SUBSTR('FL_FUND_TRF ' || p_doc_num || ' ' || SQLERRM,1,200);
				RAISE v_err;
		END;
	END IF;

  
	If P_Upd_Mode  = 'DELETE'  Then			
		BEGIN
			DELETE FROM t_fund_trf			
			WHERE trf_date = p_doc_date		
			AND doc_num = p_doc_num;
		EXCEPTION
			WHEN OTHERS THEN
				v_error_code := -5;
				v_error_msg	:= SUBSTR('delete T_FUND_TRF ' || p_doc_num || ' ' || SQLERRM,1,200);
				RAISE v_err;
		END;			
	end if;

	p_error_code := 1;
	p_error_msg	:= '';
	
EXCEPTION
	WHEN v_err THEN
		p_error_code := v_error_code;
		p_error_msg :=  v_error_msg;
		ROLLBACK;	   
	WHEN OTHERS THEN
		p_error_code := -1;
		p_error_msg := SUBSTR(SQLERRM,1,200);
		ROLLBACK;
END SP_T_Fund_Trf_Upd;