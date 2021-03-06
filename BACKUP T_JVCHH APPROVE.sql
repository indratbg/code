create or replace 
PROCEDURE Sp_T_jvchh_Approve(
	   p_menu_name							T_MANY_HEADER.menu_name%TYPE,
	   p_update_date						T_MANY_HEADER.update_date%TYPE,
	   p_update_seq							T_MANY_HEADER.update_seq%TYPE,
	   p_approved_user_id				  	T_MANY_HEADER.user_id%TYPE,
	   p_approved_ip_address 		 		T_MANY_HEADER.ip_address%TYPE,
	   p_error_code							OUT NUMBER,
	   p_error_msg							OUT VARCHAR2
	   ) IS

CURSOR csr_data(a_table_name T_MANY_DETAIL.table_name%TYPE, a_record_seq  T_MANY_DETAIL.record_seq%TYPE)  IS
	SELECT T_MANY_HEADER.menu_name, T_MANY_HEADER.update_date, T_MANY_DETAIL.table_rowid,
	T_MANY_DETAIL.field_name, T_MANY_DETAIL.field_type, T_MANY_DETAIL.field_value
	FROM T_MANY_HEADER, T_MANY_DETAIL
	WHERE T_MANY_HEADER.update_date = p_update_date
	AND menu_name = p_menu_name
	AND table_name = a_table_name
	AND record_seq = a_record_seq
	AND upd_flg <> 'X'
  AND T_MANY_DETAIL.upd_status NOT IN ('X','Z')
	AND T_MANY_HEADER.update_seq = p_update_seq
	AND T_MANY_HEADER.update_date = T_MANY_DETAIL.update_date
	AND T_MANY_HEADER.update_seq = T_MANY_DETAIL.update_seq;
	
CURSOR csr_rec IS 
	SELECT DISTINCT table_name, record_seq, table_rowid, upd_status
	FROM T_MANY_DETAIL
	WHERE update_seq = p_update_seq
  AND upd_status NOT IN ('X','Z');
/*
  CURSOR csr_journal(a_xn_doc_num T_ACCOUNT_LEDGER.XN_DOC_NUM%TYPE) IS
		SELECT DISTINCT SL_ACCT_CD
		FROM T_ACCOUNT_LEDGER, MST_CLIENT
		WHERE XN_DOC_NUM = a_xn_doc_num
		AND T_ACCOUNT_LEDGER.SL_ACCT_CD = MST_CLIENT.CLIENT_CD;
*/
  
  
  
v_sql 							 	VARCHAR2(32767);
v_table_rowid						T_MANY_DETAIL.table_rowid%TYPE;
v_approved_date 					T_MANY_HEADER.approved_date%TYPE;
v_status							T_MANY_DETAIL.upd_status%TYPE;
v_field_cnt							NUMBER;
v_col_name            VARCHAR2(20);
 v_jvch_num T_JVCHH.JVCH_NUM%TYPE;
 v_jvch_date T_JVCHH.JVCH_DATE%TYPE;
 v_folder_cd T_JVCHH.FOLDER_CD%TYPE;
  h_status t_many_header.status%type;
 v_date varchar2(4);
v_err EXCEPTION;
v_error_code						NUMBER;
v_error_msg							VARCHAR2(200);
 v_cnt number(3);
BEGIN

		
  BEGIN
  SELECT UPD_STATUS INTO v_status from T_MANY_DETAIL where update_seq =  p_update_seq and update_date=p_update_date and rownum=1;
  EXCEPTION
 	    WHEN OTHERS THEN
	   			v_error_code := -2;
				v_error_msg :=  SUBSTR('T_Many_Detail '||SQLERRM,1,200);
				RAISE v_err;
	   END;
	  
	BEGIN
  SELECT STATUS INTO h_status from T_MANY_header where update_seq =  p_update_seq and update_date=p_update_date and rownum=1;
  EXCEPTION
 	    WHEN OTHERS THEN
	   			v_error_code := -2;
				v_error_msg :=  SUBSTR('T_Many_header '||SQLERRM,1,200);
				RAISE v_err;
	   END;

	   
	  
	  IF v_status <> 'C' then
	   	BEGIN
		SELECT MAX(JVCH_NUM),MAX(JVCH_DATE), MAX(FOLDER_CD)
				INTO v_jvch_num, v_jvch_date,v_folder_cd
				from ( SELECT DECODE(field_name,'JVCH_NUM',field_value, NULL) JVCH_NUM,
							DECODE(field_name,'JVCH_DATE',field_value, NULL) JVCH_DATE,
							DECODE(field_name,'FOLDER_CD',field_value, NULL) FOLDER_CD
				   FROM  T_MANY_DETAIL
				  WHERE T_MANY_DETAIL.update_date = p_update_date
				  AND T_MANY_DETAIL.table_name = 'T_JVCHH'
				  AND T_MANY_DETAIL.update_seq	 = p_update_seq
				  AND T_MANY_DETAIL.field_name IN ('JVCH_NUM','JVCH_DATE','FOLDER_CD'));
	    EXCEPTION
            WHEN NO_DATA_FOUND THEN
              v_error_code := -3;
							v_error_msg :=  SUBSTR(SQLERRM,1,200);
							RAISE v_err;
            WHEN OTHERS THEN
              v_error_code := -4;
              v_error_msg := SUBSTR(SQLERRM,1,200);
              RAISE v_err;
          END; 
		  
		  ---insert into t_folder---
			v_date:= trim(to_char(v_jvch_date,'mmyy'));
	begin
  SELECT COUNT(1) INTO v_cnt from t_folder where doc_num=v_jvch_num;
   EXCEPTION
 	    WHEN OTHERS THEN
	   			v_error_code := -2;
				v_error_msg :=  SUBSTR('T_Folder '||SQLERRM,1,200);
				RAISE v_err;
	   END;
  
  if v_cnt=0 then
		BEGIN
		INSERT INTO T_FOLDER(FLD_MON,FOLDER_CD,DOC_DATE,DOC_NUM,USER_ID,CRE_DT,UPD_DT,UPD_BY) 
					VALUES(v_date,v_folder_cd,v_jvch_date,v_jvch_num,p_approved_user_id,sysdate,sysdate,p_approved_user_id);
		 EXCEPTION
 	    WHEN OTHERS THEN
	   			v_error_code := -2;
				v_error_msg :=  SUBSTR('T_Folder '||SQLERRM,1,200);
				RAISE v_err;
	   END;
     
     end if;
	--- END insert into t_folder---   
		  
		  
		  
	 END IF;
	
	
	
		
		
		
		


	FOR rectab IN csr_rec LOOP
		v_table_rowid := rectab.table_rowid;
		v_status := rectab.upd_status;
		v_approved_date := SYSDATE;
		
		IF v_status <>  'C' THEN
			IF v_table_rowid IS NULL THEN
			-- INSERT
				v_sql := 'INSERT INTO '||rectab.table_name||'( ';
				v_field_cnt := 0;

				FOR rec IN csr_data(rectab.table_name, rectab.record_seq) LOOP
					IF v_field_cnt  > 0 THEN
						v_sql := v_sql||', ';
					END IF;

					v_field_cnt :=  v_field_cnt + 1;
					v_sql := v_sql||rec.field_name;
				END LOOP;
					
				v_sql := v_sql||') VALUES(';

				v_field_cnt := 0;
				
				FOR rec IN csr_data(rectab.table_name, rectab.record_seq) LOOP
					IF v_field_cnt > 0 THEN
						v_sql := v_sql||', ';
					END IF;

					v_field_cnt :=  v_field_cnt + 1;
					
					IF rec.field_value IS NULL THEN
						v_sql := v_sql||' NULL';
					ELSE
						IF rec.field_type = 'S' THEN
							v_sql := v_sql||''''||rec.field_value||'''';
						ELSIF 	 rec.field_type = 'N' THEN
							v_sql := v_sql||TO_NUMBER(rec.field_value);
						ELSIF  rec.field_type = 'D' THEN
							v_sql := v_sql||'TO_DATE('''||rec.field_value||''',''yyyy/mm/dd hh24:mi:ss'')';
						END IF;
					END IF;
				END LOOP;
				
				v_sql := v_sql||')  RETURNING ROWID INTO :v_table_rowid';

				BEGIN
					EXECUTE IMMEDIATE v_sql USING OUT v_table_rowid;
				EXCEPTION
					WHEN OTHERS THEN
						v_error_code := -2;
						v_error_msg :=  SUBSTR('exec immediate INSERT  '||SQLERRM,1,200);

						RAISE v_err;
				END;


			ELSE
			-- UPDATE
				v_sql := 'UPDATE '||rectab.table_name||'  SET  ';
				
				v_field_cnt := 0;
				
				FOR rec IN csr_data(rectab.table_name, rectab.record_seq) LOOP
					IF  v_field_cnt > 0 THEN
						v_sql := v_sql||', ';
					END IF;
					
					v_field_cnt :=  v_field_cnt + 1;

					v_sql := v_sql||rec.field_name||' = ';

				--	IF rec.field_name = 'APPROVED_STS' THEN
				--		v_sql := v_sql||'A';
				--	ELSIF rec.field_name = 'APPROVED_BY' THEN
				--		v_sql := v_sql||''||p_approved_user_id||'';
				--	ELSIF       rec.field_name = 'APPOVED_DT' THEN
				--		v_sql := v_sql||'TO_DATE('''||v_approved_date||''',''dd/mm/yyyy hh24:mi:ss'')';
				--	ELSE
						IF rec.field_value IS NULL THEN
							v_sql := v_sql||' NULL';
						ELSE
							IF rec.field_type = 'S' THEN
								v_sql := v_sql||''''||rec.field_value||'''';
							ELSIF 	 rec.field_type = 'N' THEN
								 v_sql := v_sql||TO_NUMBER(rec.field_value);
							ELSIF  rec.field_type = 'D' THEN
								v_sql := v_sql||'TO_DATE('''||rec.field_value||''',''yyyy/mm/dd hh24:mi:ss'')';
							END IF;
						END IF;
				--	END IF;
				END LOOP;

				v_sql := v_sql||' WHERE ROWID = :v_table_rowid';

				BEGIN
					EXECUTE IMMEDIATE v_sql USING  v_table_rowid;
				EXCEPTION
					WHEN OTHERS THEN
						v_error_code := -3;
						v_error_msg :=  SUBSTR('exec immediate UPDATE  '||SQLERRM,1,200);
						RAISE v_err;
				END;
			END IF;
		END IF;
		-- ASUMSI : tiap update, kolom APPROVE di update

		
		 BEGIN
    SELECT column_name
    into v_col_name
    FROM  all_tab_columns
    WHERE  table_name = rectab.table_name
    AND owner = 'IPNEXTG'
    AND  column_name IN  ('APPROVED_STS','APPROVED_STAT');
   EXCEPTION
    WHEN OTHERS THEN
          v_error_code := -5;
        v_error_msg :=  SUBSTR('APPROVED STATUS COLUMN  '||SQLERRM,1,200);
        RAISE v_err;
   END;
    v_sql := 'UPDATE '||rectab.table_name||'  SET  ';
	 IF v_status = 'C'  THEN
	 			 v_sql := v_sql||v_col_name||' ='||'''C'''||',';
	 ELSE
	 	 		 v_sql := v_sql||v_col_name||' ='||'''A'''||',';
	END IF;
		v_sql := v_sql||'APPROVED_BY = '''||p_approved_user_id||''''||',';
		IF v_status = 'I' THEN
			v_sql := v_sql||'CRE_DT = SYSDATE,';
		ELSIF 	v_status = 'U' THEN
			v_sql := v_sql||'UPD_DT = SYSDATE,';
		END IF;
		v_sql := v_sql||'APPROVED_DT = SYSDATE';
		v_sql := v_sql||' WHERE ROWID = :v_table_rowid';

		BEGIN
			EXECUTE IMMEDIATE v_sql USING  v_table_rowid;
		EXCEPTION
			WHEN OTHERS THEN
				v_error_code := -4;
				v_error_msg :=  SUBSTR('exec immediate UPDATE approved sts  '||v_sql,1,200);
				RAISE v_err;
		END;
	END LOOP;
 --
    BEGIN
		BEGIN	
			UPDATE T_MANY_HEADER
			SET approved_status = 'A',
			approved_user_id = p_approved_user_id,
			approved_date = SYSDATE,
			approved_ip_address = p_approved_ip_address
			WHERE menu_name = p_menu_name
			AND update_date = p_update_date
			AND update_seq = p_update_seq;
		EXCEPTION
			WHEN OTHERS THEN
				v_error_code := -5;
				v_error_msg :=  SUBSTR('Update t_MANY_HEADER  '||SQLERRM,1,200);
				RAISE v_err;
		END;	

	EXCEPTION
	WHEN OTHERS THEN
   		v_error_code := -5;
		v_error_msg :=  SUBSTR('Update T_MANY_HEADER '||SQLERRM,1,200);
		RAISE v_err;
	END;

	---CALL REVERSAL JURNAL-----
	
	/*
		if h_status ='U' or h_status = 'C' then
		
		begin
		Sp_Reverse_Acct_Ledger_Journal(v_jvch_date,
										v_jvch_num,
										p_approved_user_id,
										p_update_date,
										p_update_seq,
										p_approved_ip_address,
										v_error_code,
										v_error_msg);
										
										 EXCEPTION
		when no_data_found then
		v_error_code :=-12;
		v_error_msg := 'no_data_found';
		raise v_err;
		
 	    WHEN OTHERS THEN
	   			v_error_code := -2;
				v_error_msg :=  SUBSTR('Sp_Reverse_Acct_Ledger_Journal '||SQLERRM,1,200);
				RAISE v_err;
	   END;
		
		end if;
		---END CALL REVERSAL JURNAL----
	*/
	
	
	
   	p_error_code := 1;
	p_error_msg := '';
-- 		   IF p_commit = 1 THEN
-- 		   	  COMMIT;
-- 		   END IF;

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