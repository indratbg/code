create or replace 
PROCEDURE Sp_T_Many_Approve(
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

v_sql 							 	VARCHAR2(32767);
v_table_rowid						T_MANY_DETAIL.table_rowid%TYPE;
v_approved_date 					T_MANY_HEADER.approved_date%TYPE;
v_status							T_MANY_DETAIL.upd_status%TYPE;
v_field_cnt							NUMBER;
v_col_name            VARCHAR2(20);

v_err EXCEPTION;
v_error_code						NUMBER;
v_error_msg							VARCHAR2(200);

BEGIN
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
							v_sql := v_sql||''''||replace(rec.field_value,'''','''''')||'''';
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
								v_sql := v_sql||''''||replace(rec.field_value,'''','''''')||'''';
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
		/*IF v_status = 'I' THEN
			v_sql := v_sql||'CRE_DT = SYSDATE,';
		ELSIF 	v_status = 'U' THEN
			v_sql := v_sql||'UPD_DT = SYSDATE,';
		END IF;*/
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
END Sp_T_Many_Approve;