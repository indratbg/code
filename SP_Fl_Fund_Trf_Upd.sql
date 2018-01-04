create or replace 
PROCEDURE SP_Fl_Fund_Trf_Upd( p_doc_num T_FUND_MOVEMENT.DOC_NUM%TYPE,
							 p_trf_id T_FUND_TRF.trf_id%TYPE,
							 p_trf_type T_FUND_TRF.trf_type%TYPE,
							 p_upd_mode CHAR,
                             p_new_trf_flg T_FUND_TRF.trf_flg%TYPE,
                             p_user_id T_FUND_MOVEMENT.user_id%TYPE,
                             vo_errmsg	OUT VARCHAR2,
                             vo_errcode	OUT NUMBER ) IS

/******************************************************************************
   NAME:       FL_FUND_TRF_UPD
   PURPOSE:

******************************************************************************/


v_new_flg T_FUND_TRF.trf_flg%TYPE;
v_old_flg T_FUND_TRF.trf_flg%TYPE;
vl_err	EXCEPTION;
v_cnt NUMBER;
Begin
 

 
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
		WHEN OTHERS THEN
		vo_errmsg	:= 'T_FUND_TRF ' || p_doc_num ||SQLERRM;
		vo_errcode	:= -3;
		RAISE vl_err;
		END;

		IF v_cnt = 0  THEN
 -- 23dec, karena perubahan 1202 ke 1200  	SELECT doc_date,p_trf_id,doc_num, DECODE(trim(gl_Acct_cd),'1202','BCA',trim(from_bank)),
   	   BEGIN
	   INSERT INTO T_FUND_TRF (
	   TRF_DATE, TRF_ID, DOC_NUM, FUND_BANK_CD,
	   CLIENT_CD, TRF_TYPE, TRF_FLG,
	   TRF_TIMESTAMP, TRF_AMT, CRE_DT,
	   UPD_DT, USER_ID)
		SELECT doc_date,p_trf_id,doc_num, 'BCA',
		client_cd, trim(p_trf_type) , trim(p_new_trf_flg),
		SYSDATE, trx_amt,SYSDATE,
		NULL, p_user_id
		FROM T_FUND_MOVEMENT
		WHERE doc_num = p_doc_num;
		EXCEPTION
		WHEN OTHERS THEN
		vo_errmsg	:= 'FL_FUND_TRF ' || p_doc_num ||SQLERRM;
		vo_errcode	:= -3;
		RAISE vl_err;
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
		vo_errmsg	:= 'FL_FUND_TRF ' || p_doc_num ||SQLERRM;
		vo_errcode	:= -3;
		RAISE vl_err;
		END;
   END IF;



   IF p_upd_mode = 'DEL' THEN
  -- RDCL tidak jadi ditransfer , sebelumnya sudah diselect
	  BEGIN
	  DELETE FROM T_FUND_TRF
	  WHERE doc_num = p_doc_num
	  AND trf_flg = 'N';
	  EXCEPTION
		WHEN OTHERS THEN
		vo_errmsg	:= 'delete T_FUND_TRF ' || p_doc_num ||SQLERRM;
		vo_errcode	:= -3;
		RAISE vl_err;
		END;
   END IF;

   vo_errcode := 1;
	vo_errmsg	:= '';
   EXCEPTION
     When Vl_Err Then
       ROLLBACK;

     WHEN OTHERS THEN
       ROLLBACK;
	vo_errmsg	:= SQLERRM;
	vo_errcode	:= -1;
END SP_Fl_Fund_Trf_Upd;