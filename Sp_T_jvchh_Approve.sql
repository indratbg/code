create or replace PROCEDURE Sp_T_jvchh_Approve(
	   p_menu_name							T_MANY_HEADER.menu_name%TYPE,
	   p_update_date						T_MANY_HEADER.update_date%TYPE,
	   p_update_seq							T_MANY_HEADER.update_seq%TYPE,
	   p_approved_user_id				  	T_MANY_HEADER.user_id%TYPE,
	   p_approved_ip_address 		 		T_MANY_HEADER.ip_address%TYPE,
	   p_error_code							OUT NUMBER,
	   p_error_msg							OUT VARCHAR2
	   ) IS

	/*
CURSOR csr_rec IS 
	SELECT DISTINCT table_name, record_seq, table_rowid, upd_status
	FROM T_MANY_DETAIL
	WHERE update_seq = p_update_seq
  AND upd_status NOT IN ('X','Z');
  
CURSOR csr_jurnal is
 SELECT distinct TABLE_ROWID from t_many_detail
 where update_seq = p_update_seq
 and update_date=p_update_date 
 and upd_status = 'U' ;
 */
 --[INDRA] 20 NOV 2017 DELETE T_DAILY_OTC_JUR UNTUK JURNAL OTC HARIAN

  v_rowid_t_jvchh T_MANY_DETAIL.table_rowid%TYPE;
v_sql 							 	VARCHAR2(32767);
v_table_rowid						T_MANY_DETAIL.table_rowid%TYPE;
v_approved_date 					T_MANY_HEADER.approved_date%TYPE;
v_status							T_MANY_DETAIL.upd_status%TYPE;
v_field_cnt							NUMBER;
v_col_name            VARCHAR2(20);
 v_jvch_num_lama T_JVCHH.JVCH_NUM%TYPE;
 v_jvch_num_baru T_JVCHH.JVCH_NUM%TYPE;
 v_jvch_date T_JVCHH.JVCH_DATE%TYPE;
 v_folder_cd T_JVCHH.FOLDER_CD%TYPE;
  h_status t_many_header.status%type;
  n_jvch_date T_JVCHH.JVCH_DATE%TYPE;
   v_reversal_jur t_jvchh.reversal_jur%type;
   t_gl_acct_cd t_account_ledger.gl_acct_cd%type;
   t_sl_acct_cd t_account_ledger.sl_acct_cd%type;
   t_curr_val t_account_ledger.curr_val%type;
   t_db_cr_flg t_account_ledger.db_cr_flg%type;
   x_jvch_date t_jvchh.jvch_date%type;
   v_sl_acct_cd t_account_ledger.sl_acct_cd%type;
   v_gl_acct_cd t_account_ledger.gl_acct_cd%type;
   v_curr_val t_account_ledger.curr_val%type;
   v_db_cr_flg t_account_ledger.db_cr_flg%type;
 v_date varchar2(4);
v_err EXCEPTION;
v_error_code						NUMBER;
v_error_msg							VARCHAR2(2000);
 v_cnt number(3);
v_check boolean:=false;

BEGIN

		
  BEGIN
  SELECT STATUS INTO v_status from T_MANY_header where update_seq =  p_update_seq and update_date=p_update_date;
  EXCEPTION
 	    WHEN OTHERS THEN
	   			v_error_code := -40;
				v_error_msg :=  SUBSTR('T_Many_Header '||SQLERRM,1,200);
				RAISE v_err;
	   END;
--panggil sp approved
	begin
	Sp_T_Many_Approve(p_menu_name,
					   p_update_date,
					   p_update_seq,
					   p_approved_user_id,
					   p_approved_ip_address,
					   v_error_code,
					   v_error_msg);
EXCEPTION
	WHEN OTHERS THEN
   		v_error_code := -60;
		v_error_msg :=  SUBSTR('Sp_T_Many_Approve '||SQLERRM,1,200);
		RAISE v_err;
	END;
	
		IF v_error_code < 0 THEN
    v_error_code := -70;
		v_error_msg := SUBSTR('Sp_T_Many_Approve '||v_error_msg||' '||SQLERRM,1,200);
		RAISE v_err;
	END IF;

	
  
  --cek
  begin
  select count(1) into v_cnt from t_many_detail where update_seq=p_update_seq and update_date=p_update_date
    and table_name='T_JVCHH' and upd_status='C' and rownum=1;
    EXCEPTION
	WHEN OTHERS THEN
   		v_error_code := -80;
		v_error_msg :=  SUBSTR(' t_many_detail  '||SQLERRM,1,200);
		RAISE v_err;
	END;
  
  if v_cnt >0 then
  
  --doc_num lama
  begin
  select field_value into v_jvch_num_lama from t_many_detail where update_seq=p_update_seq and update_date=p_update_date and table_rowid is not null and field_name='JVCH_NUM'; --doc_num lama
   EXCEPTION
	WHEN OTHERS THEN
   		v_error_code := -90;
		v_error_msg :=  SUBSTR('t_many_detail  '||SQLERRM,1,200);
		RAISE v_err;
	END;
  
  --if v_status = 'U' then
  
  begin
  select field_value into v_reversal_jur from t_many_detail where update_seq=p_update_seq and update_date=p_update_date and field_name='JVCH_NUM' and record_seq=2; --doc_num reversal
   EXCEPTION
	WHEN OTHERS THEN
   		v_error_code := -100;
		v_error_msg :=  SUBSTR('SELECT T_MANY_DETAIL '||SQLERRM,1,200);
		RAISE v_err;
	END;
--  --else
--   begin
--  select field_value into v_reversal_jur from t_many_detail where update_seq=p_update_seq and update_date=p_update_date and field_name='JVCH_NUM' and record_seq=1; --doc_num reversal
--   EXCEPTION
--	WHEN OTHERS THEN
--   		v_error_code := -110;
--		v_error_msg :=  SUBSTR('SELECT T_MANY_DETAIL '||SQLERRM,1,200);
--		RAISE v_err;
--	END;
  --end if;
  --update field reversal_jur jurnal yang lama
  begin
  update t_jvchh set reversal_jur = v_reversal_jur where jvch_num = v_jvch_num_lama;
    EXCEPTION
	WHEN OTHERS THEN
   		v_error_code := -120;
		v_error_msg :=  SUBSTR('update t_jvchh '||SQLERRM,1,200);
		RAISE v_err;
	END;
  --update field reversal_jur jurnal yang lama
  begin
  update t_account_ledger set reversal_jur = v_reversal_jur where xn_doc_num = v_jvch_num_lama;
    EXCEPTION
	WHEN OTHERS THEN
   		v_error_code := -130;
		v_error_msg :=  SUBSTR('update t_account_ledger  '||SQLERRM,1,200);
		RAISE v_err;
	END;
  
  --[INDRA] 20 NOV 2017 DELETE T_DAILY_OTC_JUR UNTUK JURNAL OTC HARIAN
  BEGIN
  SELECT COUNT(1) INTO V_CNT FROM T_DAILY_OTC_JUR WHERE XN_DOC_NUM=v_jvch_num_lama;
  EXCEPTION
  WHEN OTHERS THEN
      v_error_code := -132;
    v_error_msg :=  SUBSTR('SELECT T_DAILY_OTC_JUR  XN_DOC_NUM '||v_jvch_num_lama||' '||SQLERRM,1,200);
    RAISE v_err;
  END;

IF V_CNT>0 THEN
  BEGIN
    DELETE FROM T_DAILY_OTC_JUR WHERE XN_DOC_NUM=v_jvch_num_lama;
   EXCEPTION
  WHEN OTHERS THEN
      v_error_code := -135;
    v_error_msg :=  SUBSTR('DELETE FROM T_DAILY_OTC_JUR  DOC_NUM '||v_jvch_num_lama||' '|| SQLERRM,1,200);
    RAISE v_err;
  END;
END IF;

  --04APR2017 T_REPO_VCH JIKA JURNAL REPO INTEREST
  BEGIN
 SELECT COUNT(1) INTO V_CNT FROM T_REPO_VCH WHERE DOC_NUM=v_jvch_num_lama;
  EXCEPTION
	WHEN OTHERS THEN
   		v_error_code := -140;
		v_error_msg :=  SUBSTR('SELECT COUNT FROM T_REPO_VCH  '||SQLERRM,1,200);
		RAISE v_err;
	END;
  
    IF  V_CNT>0 THEN
    
    BEGIN
    SELECT FIELD_VALUE INTO v_jvch_num_baru
    FROM t_many_detail
    WHERE update_seq=P_UPDATE_SEQ AND UPDATE_DATE=P_UPDATE_DATE
    AND record_seq  =1
    AND table_name  ='T_ACCOUNT_LEDGER'
    AND FIELD_NAME='XN_DOC_NUM';
    EXCEPTION
    WHEN OTHERS THEN
   		v_error_code := -150;
      v_error_msg :=  SUBSTR('GET DOC_NUM BARU '||SQLERRM,1,200);
      RAISE v_err;
    END;
    
    BEGIN
      UPDATE T_REPO_VCH SET DOC_NUM=v_jvch_num_baru, DOC_REF_NUM= v_jvch_num_baru,UPD_DT=SYSDATE,UPD_BY=p_approved_user_id WHERE  DOC_NUM=v_jvch_num_lama;
   EXCEPTION
    WHEN OTHERS THEN
   		v_error_code := -160;
      v_error_msg :=  SUBSTR('UPDATE T_REPO_VCH'||SQLERRM,1,200);
      RAISE v_err;
    END;
      
    END IF;
    
 
  end if;
  commit;
  p_error_code := 1;
	p_error_msg := '';


	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			NULL;
		WHEN v_err THEN
			p_error_code := v_error_code;
			p_error_msg :=  v_error_msg;
			ROLLBACK;

		WHEN OTHERS THEN
			ROLLBACK;
			p_error_code := -1;
			p_error_msg := SUBSTR(SQLERRM,1,200);
			RAISE;
END Sp_T_jvchh_Approve;