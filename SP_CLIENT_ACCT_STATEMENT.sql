create or replace PROCEDURE SP_CLIENT_ACCT_STATEMENT ( p_external_ref T_CLIENT_ACCT_STATEMENT.external_ref%TYPE
				   , p_seq_no T_CLIENT_ACCT_STATEMENT.seq_no%TYPE
				   , p_acct_num T_CLIENT_ACCT_STATEMENT.acct_num%TYPE
				   , p_curr_cd T_CLIENT_ACCT_STATEMENT.curr_cd%TYPE
				   , p_trx_date T_CLIENT_ACCT_STATEMENT.trx_date%TYPE
				   , p_trx_type T_CLIENT_ACCT_STATEMENT.trx_type%TYPE
				   , p_trx_cd T_CLIENT_ACCT_STATEMENT.trx_cd%TYPE
				   , p_acct_debit T_CLIENT_ACCT_STATEMENT.acct_debit%TYPE
				   , p_acct_credit T_CLIENT_ACCT_STATEMENT.acct_credit%TYPE
				   , p_trx_amt T_CLIENT_ACCT_STATEMENT.trx_amt%TYPE
				   , p_open_bal T_CLIENT_ACCT_STATEMENT.open_bal%TYPE
				   , p_close_bal T_CLIENT_ACCT_STATEMENT.close_bal%TYPE
				   , p_description T_CLIENT_ACCT_STATEMENT.description%TYPE
				   , p_user_id VARCHAR2
				   , p_ip_address VARCHAR2 
				   , p_error_code OUT NUMBER
				   , p_error_msg OUT VARCHAR2 )
IS
	v_err EXCEPTION;
	v_error_cd NUMBER ( 5 );
	v_error_msg VARCHAR2 ( 200 );
	v_cnt NUMBER;
BEGIN
	BEGIN
		SELECT COUNT (1)
		  INTO v_cnt
		  FROM T_CLIENT_ACCT_STATEMENT
		 WHERE external_ref = p_external_ref;
		EXCEPTION
			WHEN OTHERS	THEN
				v_error_cd := - 10;
				v_error_msg := SUBSTR ( 'SELECT COUNT EXTERNAL_REF FROM T_CLIENT_ACCT_STATEMENT' || SQLERRM , 1, 200 );
				RAISE V_ERR;
	  END;

	IF v_cnt = 0	THEN
		BEGIN
			INSERT INTO T_CLIENT_ACCT_STATEMENT ( external_ref
							    , seq_no
							    , acct_num
							    , curr_cd
							    , trx_date
							    , trx_type
							    , trx_cd
							    , acct_debit
							    , acct_credit
							    , trx_amt
							    , open_bal
							    , close_bal
							    , description
							    , cre_dt )
			VALUES ( p_external_ref
			       , p_seq_no
			       , p_acct_num
			       , p_curr_cd
			       , p_trx_date
			       , p_trx_type
			       , p_trx_cd
			       , p_acct_debit
			       , p_acct_credit
			       , p_trx_amt
			       , p_open_bal
			       , p_close_bal
			       , p_description
			       , SYSDATE );
			EXCEPTION
				WHEN OTHERS	THEN
					v_error_cd := - 20;
					v_error_msg := SUBSTR ( 'INSERT INTO T_CLIENT_ACCT_STATEMENT ' || SQLERRM , 1 , 200 );
					RAISE V_ERR;
		  END;

    commit;

		BEGIN
			SP_FUND_AUTO_BCA ( p_external_ref
					 , p_acct_num
					 , p_user_id
					 , p_ip_address
					 , v_error_cd
					 , v_error_msg );
			EXCEPTION
				WHEN OTHERS	THEN
					v_error_cd := - 30;
					v_error_msg := SUBSTR ( 'CALL SP_FUND_AUTO_BCA ' || SQLERRM, 1 , 200 );
					RAISE V_ERR;
		END;

		IF v_error_cd < 0 THEN
			v_error_cd := - 35;
			v_error_msg := SUBSTR ( 'SP_FUND_AUTO_BCA ' ||v_error_cd||' '|| v_error_msg, 1, 200 );
			RAISE V_ERR;
		END IF;

	END IF;

	P_ERROR_CODE := 1;
	P_ERROR_MSG := '';
	EXCEPTION
		WHEN V_ERR THEN
			ROLLBACK;
			BEGIN
				Sp_Insert_Orcl_Errlog('IPNEXTG', 'ORCLBO', 'PROCEDURE : SP_CLIENT_ACCT_STATEMENT', v_error_cd||' '||v_error_msg);
			END;
		WHEN OTHERS THEN
			BEGIN
				Sp_Insert_Orcl_Errlog('IPNEXTG', 'ORCLBO', 'PROCEDURE : SP_CLIENT_ACCT_STATEMENT', SUBSTR('-1 '||SQLERRM,1,200));
			END;
			RAISE;
END SP_CLIENT_ACCT_STATEMENT;