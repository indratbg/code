create or replace 
PROCEDURE           "SP_T_REKS_TRX_APPROVE" (
	   p_menu_name							  	T_MANY_HEADER.menu_name%TYPE,
	   p_update_date							T_MANY_HEADER.update_date%TYPE,
	   p_update_seq								T_MANY_HEADER.update_seq%TYPE,
	   p_approved_user_id				  T_MANY_HEADER.user_id%TYPE,
	   p_approved_ip_address 		 T_MANY_HEADER.ip_address%TYPE,
     
     p_error_code			OUT NUMBER,
	   p_error_msg			OUT VARCHAR2
	 
) IS

/******************************************************************************
   NAME:       SP_T_REKS_TRX_APPROVE
   PURPOSE:    

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        23/10/2013          1. Created this procedure.

******************************************************************************/

CURSOR csr_data IS 
SELECT DISTINCT RECORD_SEQ FROM T_MANY_DETAIL WHERE UPDATE_SEQ=p_update_seq AND UPDATE_DATE=p_update_date;



v_cnt NUMBER;


v_doc_dt t_reks_movement.doc_dt%TYPE;

v_reks_cd t_reks_movement.reks_cd%TYPE;
v_trx_type t_reks_movement.trx_type%TYPE;
v_debit t_reks_movement.debit%TYPE;
v_credit t_reks_movement.credit%TYPE;
v_doc_rem t_reks_movement.doc_rem%TYPE;

v_gl_acct_cd t_reks_movement.gl_acct_cd%TYPE;
v_diff_date date;
v_db_cr_flg t_reks_movement.db_cr_flg%TYPE;
v_seqno t_reks_movement.seqno%TYPE;
v_nab_unit t_reks_movement.nab_unit%TYPE;
v_nab_date t_reks_nab.nab_date%TYPE;
v_coy_client_cd t_reks_movement.client_cd%TYPE;
v_seqno INTEGER;
v_deb_acct t_reks_movement.gl_acct_cd%TYPE;
v_cre_acct t_reks_movement.gl_acct_cd%TYPE;

v_trx_date DATE;
v_mkbd_dt DATE;
v_doc_ref_num t_reks_trx.doc_ref_num%type;
v_client_type mst_secu_acct.CLIENT_TYPE%TYPE;
v_err EXCEPTION;
v_error_code							NUMBER;
v_error_msg							VARCHAR2(200);
v_table_rowid T_MANY_DETAIL.table_rowid%type;
v_status T_MANY_HEADER.status%type;
v_approved_user_id 				T_MANY_HEADER.user_id%TYPE;
v_doc_num   t_reks_movement.doc_num%TYPE;
v_count number;
v_table_name varchar2(50) :='T_REKS_TRX';




BEGIN

FOR rec in csr_data loop


  BEGIN
  SELECT UPD_STATUS INTO v_status from T_MANY_DETAIL where update_seq =  p_update_seq AND RECORD_SEQ= rec.record_seq and rownum=1;
  EXCEPTION
 	    WHEN OTHERS THEN
	   			v_error_code := -2;
				v_error_msg :=  SUBSTR('T_Many_Header '||SQLERRM,1,200);
				RAISE v_err;
	   END;
       SELECT trim(other_1) INTO v_coy_client_cd
		FROM mst_company;

--   v_trx_date:= '12sep14';
 --  v_trx_date:= p_doc_dt;
		IF v_status <> 'C' then
		BEGIN
		 SELECT MAX(TRX_DATE), MAX(REKS_CD), MAX(TRX_TYPE), MAX(SUBS), MAX(REDM),MAX(DOC_REF_NUM)
				 INTO v_doc_dt, v_reks_cd, v_trx_type, v_debit, v_credit,v_doc_ref_num
				   FROM(
		  		   SELECT DECODE(field_name,'TRX_DATE',field_value, NULL) TRX_DATE,
				   		  DECODE(field_name,'REKS_CD',field_value, NULL) REKS_CD,
							DECODE(field_name,'TRX_TYPE',field_value, NULL) TRX_TYPE,
							DECODE(field_name,'SUBS',field_value, NULL) SUBS,
							DECODE(field_name,'REDM',field_value, NULL) REDM,
							DECODE(field_name,'DOC_REF_NUM',field_value, NULL) DOC_REF_NUM
				   FROM  T_MANY_DETAIL
				  WHERE T_MANY_DETAIL.update_date = p_update_date
				  AND T_MANY_DETAIL.table_name = v_table_name
				  AND T_MANY_DETAIL.update_seq	 = p_update_seq
				  AND RECORD_SEQ=REC.RECORD_SEQ
				  AND T_MANY_DETAIL.field_name IN ( 'TRX_DATE','REKS_CD', 'TRX_TYPE','SUBS','REDM','DOC_REF_NUM'));
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
	
		
		
		BEGIN
		
		

		select NAB_UNIT INTO v_nab_unit from t_reks_nab where 
		  mkbd_dt = v_doc_dt ;

		 EXCEPTION
            WHEN NO_DATA_FOUND THEN
              v_nab_unit :=0;
							  	v_error_code := -5;
                v_error_msg := 'NAB ' ||to_char(v_doc_dt,'dd/mm/yyyy') ||' Not Found';
                RAISE v_err;
							
            WHEN OTHERS THEN
              v_error_code := -6;
              v_error_msg := SUBSTR(SQLERRM,1,200);
              RAISE v_err;
          END;
		  end if;

		 
		 IF v_status ='I' then
		 --------------------INSERT---------------------------
	   	 BEGIN   
		    SP_REKS_MOVEMENT_CREATE(
					v_doc_dt,
					v_coy_client_cd,
					v_reks_cd, 
					v_trx_type,
					v_debit,
					v_credit, 
					v_nab_unit,
					p_approved_user_id,
					v_status,
					v_doc_num,
					v_error_code,
					v_error_msg);
	   EXCEPTION
 	    WHEN OTHERS THEN
	   			v_error_code := -7;
				v_error_msg :=  SUBSTR('SP_REKS_MOVEMENT_CREATE '||v_table_name||SQLERRM,1,200);
				RAISE v_err;
	   END;
	   if v_error_code<0 then
     v_error_code := -8;
     v_error_msg := 'SP_REKS_MOVEMENT_CREATE '||v_table_name||' '||v_error_msg;
		end if;
  
    Begin
    
      UPDATE T_MANY_DETAIL SET FIELD_VALUE = v_doc_num where field_name ='DOC_REF_NUM' AND UPDATE_SEQ= p_update_seq AND UPD_STATUS='I';
     EXCEPTION
 	    WHEN OTHERS THEN
	   			v_error_code := -9;
				v_error_msg :=  SUBSTR('T_MANY_DETAIL'||SQLERRM,1,200);
				RAISE v_err;
	   END;
	--------------------END INSERT---------------------------
	
	ELSE
	 -----------------------UPDATE DAN CANCEL--------------------------

	   	 BEGIN   
		    SP_REKS_MOVEMENT_CREATE(
					v_doc_dt,
					v_coy_client_cd,
					v_reks_cd, 
					v_trx_type,
					v_debit,
					v_credit, 
					v_nab_unit,
					p_approved_user_id,
					v_status,
          v_doc_num,
          v_error_code,
          v_error_msg);
	   EXCEPTION
 	    WHEN OTHERS THEN
	   			v_error_code := -16;
				v_error_msg :=  SUBSTR('SP_REKS_MOVEMENT_CREATE '||v_table_name||SQLERRM,1,200);
				RAISE v_err;
	   END;
	   if v_error_code<0 then
     v_error_code := -17;
     v_error_msg := 'SP_REKS_MOVEMENT_CREATE '||v_table_name||' '||v_error_msg;
	 RAISE v_err;
		end if;
		
/*
		BEGIN
	   UPDATE T_MANY_DETAIL SET FIELD_VALUE = v_doc_num where FIELD_NAME='DOC_REF_NUM' AND UPDATE_SEQ = p_update_seq and upd_status ='I';
	   EXCEPTION
	
 	    WHEN OTHERS THEN
	   			v_error_code := -19;
				v_error_msg :=  SUBSTR('T_MANY_DETAIL'||SQLERRM,1,200);
				RAISE v_err;
	   END;
	*/ 
	BEGIN
	UPDATE T_MANY_DETAIL SET FIELD_VALUE= v_doc_num WHERE UPDATE_SEQ= p_update_seq AND FIELD_NAME='REVERSAL_JUR' and upd_status='U';
	 EXCEPTION
 	    WHEN OTHERS THEN
	   			v_error_code := -18;
				v_error_msg :=  SUBSTR('Sp_T_MANY_DETAIL '||v_table_name||SQLERRM,1,200);
				RAISE v_err;
	   END;
	   
	-----------------------END UPDATE--------------------------
	/*
	ELSE
	
	--------------------CANCEL----------------------------------
	
		BEGIN
--	SELECT FIELD_VALUE INTO v_doc_ref_num from T_MANY_DETAIL WHERE FIELD_NAME='DOC_REF_NUM' AND UPDATE_SEQ= p_update_seq;
		 
		SELECT table_rowid into v_table_rowid FROM T_MANY_DETAIL WHERE TABLE_NAME='T_REKS_TRX' AND UPDATE_SEQ= p_update_seq and rownum=1;
		 
		 
     EXCEPTION
 	    WHEN OTHERS THEN
	   			v_error_code := -21;
				v_error_msg :=  SUBSTR('T_MANY_HEADER'||SQLERRM,1,200);
				RAISE v_err;
	   END;
	   BEGIN
	   SELECT trx_date,reks_cd,trx_type,subs,redm,doc_ref_num into  v_doc_dt, v_reks_cd, v_trx_type, v_debit, v_credit,v_doc_ref_num 
	   from T_REKS_TRX WHERE rowid = v_table_rowid ;
	   EXCEPTION
 	    WHEN OTHERS THEN
	   			v_error_code := -22;
				v_error_msg :=  SUBSTR('T_REKS_TRX'||SQLERRM,1,200);
				RAISE v_err;
	   END;
	   
	   
	
	   	 BEGIN   
		    SP_REKS_MOVEMENT_CREATE(
					v_doc_dt,
					v_coy_client_cd,
					v_reks_cd, 
					v_trx_type,
					v_debit,
					v_credit, 
					v_nab_unit,
					p_approved_user_id,
					v_status,
					
          v_doc_num,
          v_error_code,
          v_error_msg);
	   EXCEPTION
 	    WHEN OTHERS THEN
	   			v_error_code := -23;
				v_error_msg :=  SUBSTR('SP_REKS_MOVEMENT_CREATE '||v_table_name||SQLERRM,1,200);
				RAISE v_err;
	   END;
	   if v_error_code<0 then
     v_error_code := -24;
     v_error_msg := 'SP_REKS_MOVEMENT_CREATE '||v_table_name||' '||v_error_msg;
	 RAISE v_err;
		end if;
		

	BEGIN
	UPDATE T_MANY_DETAIL SET FIELD_VALUE= v_doc_num WHERE UPDATE_SEQ= p_update_seq AND FIELD_NAME='REVERSAL_JUR' AND UPD_STATUS='U';
	 EXCEPTION
 	    WHEN OTHERS THEN
	   			v_error_code := -26;
				v_error_msg :=  SUBSTR('Sp_T_MANY_HEADER '||v_table_name||SQLERRM,1,200);
				RAISE v_err;
	   END;
	   
    --------------------END CANCEL----------------------------------
	*/
    END IF;
	
	END LOOP;
	BEGIN   
		     Sp_T_Many_Approve(p_menu_name,
			   p_update_date,
			   p_update_seq,
			   p_approved_user_id,
			   p_approved_ip_address,
			    v_error_code,
			   v_error_msg);
	   EXCEPTION
 	    WHEN OTHERS THEN
	   			v_error_code := -19;
				v_error_msg :=  SUBSTR('Sp_T_Many_Approve '||v_table_name||SQLERRM,1,200);
				RAISE v_err;
	   END;
	     if v_error_code<0 then
     v_error_code := -20;
     v_error_msg := 'SP_REKS_MOVEMENT_CREATE '||v_table_name||' '||v_error_msg;
	 RAISE v_err;
		end if;
		
		BEGIN
	  SELECT COUNT(1) INTO v_cnt from T_MANY_DETAIL where update_seq =  p_update_seq and upd_status ='U';
	  EXCEPTION
 	    WHEN OTHERS THEN
	   			v_error_code := -21;
				v_error_msg :=  SUBSTR('T_Many_Header '||SQLERRM,1,200);
				RAISE v_err;
	   END;
		
		IF v_cnt > 0 then
		
		BEGIN
		SELECT TABLE_ROWID INTO v_table_rowid from t_many_detail where update_seq = p_update_seq and upd_status = 'U' and rownum= 1 ;
		EXCEPTION
			WHEN OTHERS THEN
	   			v_error_code := -22;
				v_error_msg :=  SUBSTR(v_table_name||SQLERRM,1,200);
				RAISE v_err;
	   END;
		
		
		BEGIN
		UPDATE T_REKS_TRX SET APPROVED_STAT='C' WHERE rowid =v_table_rowid;
		EXCEPTION
			WHEN OTHERS THEN
	   			v_error_code := -23;
				v_error_msg :=  SUBSTR(v_table_name||SQLERRM,1,200);
				RAISE v_err;
	   END;
		END IF;

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
END SP_T_REKS_TRX_APPROVE;