create or replace 
PROCEDURE SP_Suspend_APPROVE (
	   p_table_name							  	T_TEMP_HEADER.table_name%TYPE,
	   p_update_date							T_TEMP_HEADER.update_date%TYPE,
	   p_update_seq								T_TEMP_HEADER.update_seq%TYPE,
	   p_approved_user_id				  T_TEMP_HEADER.user_id%TYPE,
	   p_approved_ip_address 		 T_TEMP_HEADER.ip_address%TYPE,
	   p_reject_reason  T_TEMP_HEADER.reject_reason%TYPE,
	    p_error_code			OUT NUMBER,
	   p_error_msg			OUT VARCHAR2
	   ) IS


/******************************************************************************
   NAME:       SP_T_TEMP_APPROVE
   PURPOSE:

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        24/09/2013          1. Created this procedure.

   NOTES:
******************************************************************************/


CURSOR csr_data  IS
SELECT h.table_name, h.update_date, h.table_rowid,
	   d.field_name, d.field_type, d.field_value,
	   d.column_id
FROM IPNEXTG.T_TEMP_HEADER h, IPNEXTG.T_TEMP_DETAIL d
WHERE h.update_date = p_update_date
AND h.table_name = p_table_name
AND h.update_seq	 = p_update_seq
AND h.update_date = d.update_date
AND h.table_name = d.table_name
AND h.update_seq	 = d.update_seq
ORDER BY column_id;

v_sql 							 VARCHAR2(32767);
v_table_rowid							 T_TEMP_HEADER.table_rowid%TYPE;
v_existing_rowid							 T_TEMP_HEADER.table_rowid%TYPE;
v_approved_date 					T_TEMP_HEADER.approved_date%TYPE;
v_status										T_TEMP_HEADER.status%TYPE;
v_field_cnt										NUMBER;
v_col_name            VARCHAR2(20);

v_err EXCEPTION;
v_error_code							NUMBER;
v_error_msg							VARCHAR2(200);
BEGIN


   BEGIN
   SELECT table_rowid, table_rowid, status  INTO v_table_rowid, v_existing_rowid,	v_status
   FROM T_TEMP_HEADER
   WHERE table_name = p_table_name
   AND update_seq = p_update_seq
   AND update_date = p_update_date;
   EXCEPTION
   WHEN NO_DATA_FOUND THEN
   		 v_table_rowid := NULL;

   WHEN OTHERS THEN
   			v_error_code := -1;
			v_error_msg :=  SUBSTR('T_TEMP_HEADER '||SQLERRM,1,200);
			RAISE v_err;

   END;

   v_approved_date := SYSDATE;
   	 IF v_status <>  'C' THEN
			   IF v_table_rowid IS NULL OR  v_status =  'R' THEN
			   -- INSERT


				  	  v_sql := 'INSERT INTO '||p_table_name||'( ';
					  v_field_cnt := 0;

			    	  FOR rec IN csr_data LOOP
					  	  	  IF   v_field_cnt  > 0 THEN
							  	  v_sql := v_sql||', ';
							 END IF;

							  v_field_cnt :=  v_field_cnt + 1;
					  	  	  v_sql := v_sql||rec.field_name;
					  END LOOP;
					    v_sql := v_sql||') VALUES(';

						v_field_cnt := 0;
						 FOR rec IN csr_data LOOP
-- 						 	  IF  rec.column_id = 22 THEN
-- 									  	  v_error_code := LENGTH(v_sql);
-- 
-- 									 END IF;

								 	  IF   v_field_cnt  > 0  THEN
									  	  v_sql := v_sql||', ';
									 END IF;

									 v_field_cnt :=  v_field_cnt + 1;
										 	 IF rec.field_value IS NULL OR rec.field_name = 'UPD_BY' OR rec.field_name = 'UPD_DT' THEN
											 					v_sql := v_sql||' NULL';
										    ELSE
										 	 	 IF rec.field_type = 'S' THEN
												 			v_sql := v_sql||''''||replace(rec.field_value,'''','''''')||'''';--23 jan replace ' dengan ''
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
			      		v_sql := 'UPDATE '||p_table_name||'  SET  ';


						FOR rec IN csr_data LOOP
								 	  IF  rec.column_id > 1 THEN
									  	  v_sql := v_sql||', ';
									 END IF;


								 	 v_sql := v_sql||rec.field_name||' = ';

			-- 						 IF rec.field_name = 'APPROVED_STS' THEN
			-- 						 				   v_sql := v_sql||'A';
			-- 						 ELSIF 		rec.field_name = 'APPROVED_BY' THEN
			-- 										   v_sql := v_sql||''||p_approved_user_id||'';
			-- 						ELSIF       rec.field_name = 'APPOVED_DT' THEN
			-- 											v_sql := v_sql||'TO_DATE('''||v_approved_date||''',''dd/mm/yyyy hh24:mi:ss'')';
			-- 						ELSE

										 	 IF rec.field_value IS NULL THEN
											 					v_sql := v_sql||' NULL';
										ELSE
										 	 	 IF rec.field_type = 'S' THEN
												 			v_sql := v_sql||''''||replace(rec.field_value,'''','''''')||'''';--23 jan replace ' dengan ''
												ELSIF 	 rec.field_type = 'N' THEN
														   v_sql := v_sql||TO_NUMBER(rec.field_value);
												ELSIF  rec.field_type = 'D' THEN
													    v_sql := v_sql||'TO_DATE('''||rec.field_value||''',''yyyy/mm/dd hh24:mi:ss'')';
												END IF;
										END IF;
			--						END IF;

			  			 END LOOP;

						 v_sql := v_sql||' WHERE ROWID = :p_table_rowid';

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
    SELECT     column_name
    INTO v_col_name
    FROM  all_tab_columns
    WHERE  table_name = p_table_name
    AND owner = 'IPNEXTG'
    AND  column_name IN  (  'APPROVED_STAT');
   EXCEPTION
   WHEN NO_DATA_FOUND THEN
          v_col_name := 'N';
    WHEN OTHERS THEN
          v_error_code := -5;
        v_error_msg :=  SUBSTR('APPROVED STATUS COLUMN  '||SQLERRM,1,200);
        RAISE v_err;
   END;
   
   IF v_col_name = 'N' THEN
		   BEGIN
		    SELECT     column_name
		    INTO v_col_name
		    FROM  all_tab_columns
		    WHERE  table_name = p_table_name
		    AND owner = 'IPNEXTG'
		    AND  column_name IN  (  'APPROVED_STS');
		   EXCEPTION
		   WHEN NO_DATA_FOUND THEN
		           v_error_code := -6;
		        v_error_msg :=  SUBSTR('APPROVED STATUS COLUMN  '||SQLERRM,1,200);
		        RAISE v_err;
		    WHEN OTHERS THEN
		          v_error_code := -7;
		        v_error_msg :=  SUBSTR('APPROVED STATUS COLUMN  '||SQLERRM,1,200);
		        RAISE v_err;
		   END;
   END IF;
   
   
     v_sql := 'UPDATE '||p_table_name||'  SET  ';
	 IF v_status = 'C'  THEN
	 			 v_sql := v_sql||v_col_name||' ='||'''C'''||',';
	 ELSE
	 	 		 v_sql := v_sql||v_col_name||' ='||'''A'''||',';
	END IF;
	 v_sql := v_sql||'APPROVED_BY = '''||p_approved_user_id||''''||',';
	/* IF v_status = 'I' THEN
	 			 	 v_sql := v_sql||'CRE_DT = SYSDATE,';
	ELSIF 	v_status = 'U' THEN
	 			 	 v_sql := v_sql||'UPD_DT = SYSDATE,';
	END IF;*/
	 v_sql := v_sql||'APPROVED_DT = SYSDATE';
	 v_sql := v_sql||' WHERE ROWID = :p_table_rowid';

	 BEGIN
    EXECUTE IMMEDIATE v_sql USING  v_table_rowid;
	EXCEPTION
			   WHEN OTHERS THEN
			   			v_error_code := -8;
						v_error_msg :=  SUBSTR('exec immediate UPDATE approved sts  '||SQLERRM,1,200);
						RAISE v_err;
			   END;
 --

  
	 IF v_status = 'R'  THEN
	 			    v_sql := 'UPDATE '||p_table_name||'  SET  ';
	 			 v_sql := v_sql||v_col_name||' ='||'''C'''||',';
				  v_sql := v_sql||'APPROVED_BY = '''||p_approved_user_id||''''||',';
	 
				 v_sql := v_sql||'APPROVED_DT = SYSDATE';
				 v_sql := v_sql||' WHERE ROWID = :p_table_rowid';

				 BEGIN
			    EXECUTE IMMEDIATE v_sql USING  v_existing_rowid;
				EXCEPTION
						   WHEN OTHERS THEN
						   			v_error_code := -9;
									v_error_msg :=  SUBSTR('exec immediate UPDATE approved sts  '||SQLERRM,1,200);
									RAISE v_err;
			   END;
	END IF;		   
 --

 BEGIN
   UPDATE T_TEMP_HEADER
   SET approved_status = 'A',
   approved_user_id = p_approved_user_id,
    approved_date = SYSDATE,
	approved_ip_address = p_approved_ip_address,
   table_rowid = v_table_rowid,
   reject_reason=p_reject_reason
   WHERE table_name =p_table_name
   AND update_date = p_update_date
   AND update_seq = p_update_seq;
   EXCEPTION
   WHEN OTHERS THEN
   			v_error_code := -5;
			v_error_msg :=  SUBSTR('Update t_TEMP_HEADER  '||SQLERRM,1,200);
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
END SP_Suspend_APPROVE;