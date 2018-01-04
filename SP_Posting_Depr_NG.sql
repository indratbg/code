create or replace 
PROCEDURE SP_Posting_Depr_NG (p_date    T_ACCOUNT_LEDGER.doc_date%TYPE,
	   	  		  						  p_mmyy    T_MON_DEPR.DEPR_MON%TYPE,
										  p_folder  T_ACCOUNT_LEDGER.folder_cd%TYPE,
	   	  		  						  p_user_id T_MON_DEPR.user_id%TYPE,
										  p_ip_address t_many_header.ip_address%type,
										  p_error_code out number,
										  p_error_msg out varchar2)
IS

CURSOR csr_depr IS
	   SELECT t.asset_cd, m.branch_cd, m.asset_type, m.ASSET_DESC, t.depr_amt
	   FROM MST_FIXED_ASSET m, T_MON_DEPR t
	   WHERE m.asset_stat = 'ACTIVE'
	     AND t.ASSET_CD = m.asset_cd
	     AND t.DEPR_MON = p_mmyy
		 AND NVL(t.depr_amt,0) <> 0
     AND M.BRANCH_CD <> 'BD'
	   ORDER BY m.branch_cd, m.asset_type, t.asset_cd;

v_doc_num	     T_ACCOUNT_LEDGER.XN_DOC_NUM%TYPE;
v_gl_acct_db 	 T_ACCOUNT_LEDGER.gl_acct_cd%TYPE;
v_gl_acct_cr 	 T_ACCOUNT_LEDGER.gl_acct_cd%TYPE;

v_sl_acct_db 	 T_ACCOUNT_LEDGER.sl_acct_cd%TYPE;
v_sl_acct_cr 	 T_ACCOUNT_LEDGER.sl_acct_cd%TYPE;

v_depr_amt       T_ACCOUNT_LEDGER.curr_val%TYPE;
v_tal_id		 T_ACCOUNT_LEDGER.tal_id%TYPE;
v_mmyy           T_FOLDER.FLD_MON%TYPE;

v_acct_prefix    CHAR(2);
v_acct_str       MST_PARAMETER.PRM_DESC2%TYPE;

rec				 csr_depr%ROWTYPE;
v_nl 	   CHAR(2);

v_err exception;
v_error_cd number;
v_error_msg varchar2(200);
V_UPDATE_DATE T_MANY_HEADER.UPDATE_DATE%TYPE;
V_UPDATE_SEQ T_MANY_HEADER.UPDATE_SEQ%TYPE;
v_curr_AMT t_jvchh.curr_AMT%type;
V_MENU_NAME T_MANY_HEADER.MENU_NAME%TYPE:='POSTING MONTHLY DEPRECIATION';
V_DOC_DATE DATE;
V_RTN NUMBER;
V_DFLG1 VARCHAR2(1);
V_user_id T_MANY_HEADER.USER_ID%TYPE;
v_doc_num_out t_jvchh.jvch_num%type;
BEGIN

			v_nl := CHR(10)||CHR(13);
	   
			BEGIN
		   DELETE FROM T_JVCHH
		   WHERE jvch_num in(select xn_doc_num from t_account_ledger
							 WHERE budget_cd = 'DEPR'
							 AND doc_date = p_date);
		   EXCEPTION
			  WHEN OTHERS THEN
				v_error_cd := -10;
				v_error_msg :=substr('Delete DEPR from T_JVCHH  : '||v_nl||SQLERRM(SQLCODE),1,200);
				raise v_err;
		   END;
		   
       
      BEGIN
      DELETE FROM T_FOLDER WHERE DOC_NUM IN (select xn_doc_num from t_account_ledger
                                             WHERE budget_cd = 'DEPR'
                                             AND doc_date = p_date);
       EXCEPTION
			  WHEN OTHERS THEN
				v_error_cd := -11;
				v_error_msg :=substr('Delete OLD FILE NUMBER from T_FOLDER  : '||v_nl||SQLERRM(SQLCODE),1,200);
				raise v_err;
		   END;
      
      
      
			BEGIN
		   DELETE FROM T_ACCOUNT_LEDGER
		   WHERE budget_cd = 'DEPR'
			 AND doc_date = p_date;
		   EXCEPTION
			  WHEN OTHERS THEN
			  v_error_cd := -20;
			  v_error_msg :=substr('Delete DEPR from T_ACCOUNT_LEDGER  : '||v_nl||SQLERRM(SQLCODE),1,200);
			  raise v_err;
		   END;
			
		

   v_doc_num := Get_Docnum_GL(p_date,'GL');

	v_tal_id := 0;
	v_curr_AMT :=0;
   OPEN csr_depr;
   LOOP
	   FETCH csr_depr INTO rec;
       EXIT WHEN csr_depr%NOTFOUND;

	   v_depr_amt := rec.depr_amt;
	   
	    BEGIN
	   SELECT acct_prefix INTO v_acct_prefix
	   FROM MST_BRANCH
	   WHERE brch_cd = rec.branch_cd;
	   EXCEPTION
      WHEN NO_DATA_FOUND THEN
        v_error_cd := -30;
        v_error_msg :=substr('BRANCH CODE : '||rec.branch_cd||' NOT FOUND in MST_BRANCH'||v_nl||SQLERRM(SQLCODE),1,200);
        raise v_err;
        WHEN OTHERS THEN
          v_error_cd := -35;
          v_error_msg :=substr('FIND BRANCH PREFIX BRANCH CODE IN MST BRANCH'||v_nl||SQLERRM(SQLCODE),1,200);
        raise v_err;
       END;

       BEGIN
	   SELECT SUBSTR(prm_desc2,1,20) INTO v_acct_str
	   FROM MST_PARAMETER
	   WHERE prm_cd_1 = 'FASSET'
	     AND prm_cd_2 = rec.asset_type;
	   EXCEPTION
      WHEN NO_DATA_FOUND THEN
			v_error_cd := -40;
			v_error_msg :=substr('ASSET TYPE : '||rec.asset_type||' NOT FOUND in MST_PARAMETER'||v_nl||SQLERRM(SQLCODE),1,200);
			raise v_err;
		WHEN OTHERS THEN
			v_error_cd := -50;
			v_error_msg :=substr('SELECT MST_PARAMETER '||v_nl||SQLERRM(SQLCODE),1,200);
			raise v_err;
       END;


          
	       v_gl_acct_db := SUBSTR(v_acct_str,1,4);
	   	   v_gl_acct_cr := SUBSTR(v_acct_str,11,4);
		   v_sl_acct_DB := v_acct_prefix||SUBSTR(v_acct_str,7,4);
		   v_sl_acct_CR := v_acct_prefix||SUBSTR(v_acct_str,17,4);

	   BEGIN
	   SELECT gl_acct_cd INTO v_acct_str
	   FROM MST_GL_ACCOUNT
	   WHERE gl_a = RPAD(v_gl_acct_db,12)
	   AND   sl_a = trim(v_sl_acct_db);
	   EXCEPTION
      WHEN NO_DATA_FOUND THEN
			v_error_cd := -60;
			v_error_msg :=substr('ACCOUNT CODE : '||trim(v_gl_acct_db)||' '||trim(v_sl_acct_db)|| rec.asset_type||rec.branch_cd||' NOT FOUND in MST_GL_ACCOUNT'||v_nl||SQLERRM(SQLCODE),1,200);
			raise v_err;
		WHEN OTHERS THEN
			v_error_cd := -70;
			v_error_msg :=substr('SELECT MST_GL_ACCOUNT '||v_nl||SQLERRM(SQLCODE),1,200);
			raise v_err;
       END;

	   BEGIN
	   SELECT gl_acct_cd INTO v_acct_str
	   FROM MST_GL_ACCOUNT
	   WHERE gl_a = RPAD(v_gl_acct_cr,12)
	   AND   sl_a = trim(v_sl_acct_cr);
	   EXCEPTION
      WHEN NO_DATA_FOUND THEN
			v_error_cd := -80;
			v_error_msg :=substr('ACCOUNT CODE : '||trim(v_gl_acct_cr)||trim(v_sl_acct_cr)||' NOT FOUND in MST_GL_ACCOUNT'||v_nl||SQLERRM(SQLCODE),1,200);
			raise v_err;
	WHEN OTHERS THEN
			v_error_cd := -90;
			v_error_msg :=substr('SELECT MST_GL_ACCOUNT '||v_nl||SQLERRM(SQLCODE),1,200);
			raise v_err;
       END;

-- 	   else
-- 	      if substr(rec.asset_cd,1,1) = 'P' then
-- 			   v_gl_acct_db := '5300';
-- 		   	   v_gl_acct_cr := '1821';
-- 	           v_sl_acct_CR := v_acct_prefix||'00001';
-- 			   v_sl_acct_DB := v_acct_prefix||'00089';
-- 		  else
--              if substr(rec.asset_cd,1,1) = 'S' then
-- 				   v_gl_acct_db := '5300';
-- 			   	   v_gl_acct_cr := '1831';
-- 		           v_sl_acct_CR := v_acct_prefix||'00001';
-- 				   v_sl_acct_DB := v_acct_prefix||'00090';
-- 			 end if;
-- 		  end if;
-- 	   end if;



		v_tal_id := v_tal_id + 1;

		BEGIN
		INSERT INTO T_ACCOUNT_LEDGER(XN_DOC_NUM,TAL_ID,
			 SL_ACCT_CD, GL_ACCT_CD,   CURR_VAL,
			DB_CR_FLG, LEDGER_NAR,  USER_ID , CRE_DT , UPD_DT ,
			DOC_DATE , DUE_DATE , RECORD_SOURCE, APPROVED_STS, FOLDER_CD,BUDGET_CD,MANUAL,APPROVED_BY,APPROVED_DT)
		VALUES(v_doc_num, v_tal_id, v_sl_acct_DB, v_gl_acct_DB, v_depr_amt,
		    'D', SUBSTR(rec.asset_cd||' '||rec.asset_desc,1,50), p_user_id, SYSDATE, NULL,
			   p_date, p_date, 'GL', 'A', p_folder,'DEPR','N',P_USER_ID,SYSDATE);
	     EXCEPTION
      WHEN OTHERS THEN
			v_error_cd := -100;
			v_error_msg :=substr('INSERT TO T_ACCOUNT_LEDGER : '||v_gl_acct_db||v_sl_acct_db||v_nl||SQLERRM(SQLCODE),1,200);
			raise v_err;
       END;

		v_tal_id := v_tal_id + 1;
		BEGIN
		INSERT INTO T_ACCOUNT_LEDGER(XN_DOC_NUM,TAL_ID,
			 SL_ACCT_CD, GL_ACCT_CD,   CURR_VAL,
			DB_CR_FLG, LEDGER_NAR,  USER_ID , CRE_DT , UPD_DT ,
			DOC_DATE , DUE_DATE , RECORD_SOURCE, APPROVED_STS, FOLDER_CD,BUDGET_CD,MANUAL,APPROVED_BY,APPROVED_DT)
		VALUES(v_doc_num, v_tal_id, v_sl_acct_CR, v_gl_acct_CR, v_depr_amt,
		    'C', SUBSTR(rec.asset_cd||' '||rec.asset_desc,1,50), p_user_id, SYSDATE, NULL,
			   p_date, p_date, 'GL', 'A', p_folder,'DEPR','N',P_USER_ID,SYSDATE);
	     EXCEPTION
      WHEN OTHERS THEN
			v_error_cd := -110;
			v_error_msg :=substr('INSERT TO T_ACCOUNT_LEDGER : '||v_gl_acct_cr||v_sl_acct_cr||v_nl||SQLERRM(SQLCODE),1,200);
			raise v_err;
       END;


	V_CURR_AMT :=V_CURR_AMT+v_depr_amt;

   END LOOP;

   
   IF V_TAL_ID >0 THEN
	
		--EXECUTE SP HEADER
         BEGIN
        Sp_T_Many_Header_Insert(V_MENU_NAME,
								 'I',
								 P_USER_ID,
								 P_IP_ADDRESS,
								 NULL,
								 V_UPDATE_DATE,
								 V_UPDATE_SEQ,
								 v_error_cd,
								 v_error_msg);
        EXCEPTION
              WHEN OTHERS THEN
                 v_error_cd := -20;
                 v_error_msg := SUBSTR('SP_T_MANY_HEADER_INSERT '|| SQLERRM(SQLCODE),1,200);
                RAISE V_ERR;
            END;


			BEGIN
			Sp_T_JVCHH_Upd(	v_doc_num,--P_SEARCH_JVCH_NUM,
							v_doc_num,--P_JVCH_NUM,
							'GL',--P_JVCH_TYPE,
							p_date,--P_JVCH_DATE,
							NULL,--P_GL_ACCT_CD,
							NULL,--P_SL_ACCT_CD,
							'IDR',--P_CURR_CD,
							0,--P_CURR_AMT,
							'DEPRECIATION',--P_REMARKS,
							P_USER_ID,
							SYSDATE,--P_CRE_DT,
							NULL,--P_UPD_DT,
							p_folder,--P_FOLDER_CD,
							'N',--P_REVERSAL_JUR,
							'I',--P_UPD_STATUS,
							p_ip_address,
							NULL,--p_cancel_reason,
							V_UPDATE_DATE,--p_update_date,
							V_UPDATE_SEQ,--p_update_seq,
							1,--p_record_seq,
							v_error_cd,
							v_error_msg);
			EXCEPTION
			  WHEN OTHERS THEN
				v_error_cd := -120;
				v_error_msg :=substr('Error insert to T_JVCHH : '||v_doc_num||v_nl||SQLERRM(SQLCODE),1,200);
				raise v_err;
			END;
			IF v_error_cd<0 then
				v_error_cd := -125;
				v_error_msg :=substr('Error insert to T_JVCHH : '||v_error_msg,1,200);
				raise v_err;
			end if;
	
  BEGIN
  UPDATE T_MANY_DETAIL SET FIELD_VALUE=V_CURR_AMT WHERE UPDATE_SEQ =V_UPDATE_SEQ AND UPDATE_DATE=V_UPDATE_DATE AND TABLE_NAME='T_JVCHH' AND FIELD_NAME='CURR_AMT';
  EXCEPTION
			  WHEN OTHERS THEN
				v_error_cd := -130;
				v_error_msg :=substr('Error insert to T_JVCHH : '||v_doc_num||v_nl||SQLERRM(SQLCODE),1,200);
				raise v_err;
			END;
      
			BEGIN
			Sp_T_Many_Approve(V_MENU_NAME,--p_menu_name,
							   V_UPDATE_DATE,--p_update_date,
							   V_UPDATE_SEQ,--p_update_seq,
							   P_USER_ID,--p_approved_user_id,
							   P_IP_ADDRESS,--p_approved_ip_address,
							   v_error_cd,
							   v_error_msg);
			EXCEPTION
			  WHEN OTHERS THEN
				v_error_cd := -140;
				v_error_msg :=substr('Sp_T_Many_Approve : '||v_nl||SQLERRM(SQLCODE),1,200);
				raise v_err;
			END;
			IF v_error_cd<0 then
				v_error_cd := -150;
				v_error_msg :=substr('Sp_T_Many_Approve : '||v_error_msg,1,200);
				raise v_err;
			end if;
	else
		v_error_cd := -160;
		v_error_msg :='Not Data Found to Process Depreciation';
		raise v_err;
			END IF;--END NOT FOUND
	BEGIN
	SELECT DFLG1 INTO V_DFLG1 FROM MST_SYS_PARAM WHERE param_id='GL_JOURNAL_ENTRY' and param_cd1='DOC_REF';
	EXCEPTION
	  WHEN OTHERS THEN
	  	v_error_cd := -170;
		v_error_msg :=substr('Check parameter penggunaan file number'||v_nl||SQLERRM(SQLCODE),1,200);
		raise v_err;
	END;
	
			IF V_DFLG1='Y' THEN

			v_mmyy := TO_CHAR(p_date,'mmyy');
			BEGIN
			UPDATE T_FOLDER
			SET doc_num = v_doc_num
			WHERE folder_cd = p_folder
			AND fld_mon = v_mmyy;
			EXCEPTION
			  WHEN OTHERS THEN
				v_error_cd := -180;
				v_error_msg :=substr('Update T_FOLDER : '||v_doc_num||v_nl||SQLERRM(SQLCODE),1,200);
				raise v_err;
			END;
			
						IF SQL%NOTFOUND THEN
							BEGIN
							INSERT INTO T_FOLDER (
						   FLD_MON, FOLDER_CD, DOC_DATE,
						   DOC_NUM, USER_ID, CRE_DT,approved_dt,approved_by,approved_stat)
						   VALUES ( p_mmyy, p_folder, p_date,
							v_doc_num, p_user_id, SYSDATE,sysdate,p_user_id,'A' );
							EXCEPTION
							WHEN OTHERS THEN
								v_error_cd := -210;
								v_error_msg :=substr('Error insert to T_FOLDER : '||v_doc_num||v_nl||SQLERRM(SQLCODE),1,200);
								raise v_err;
							END; 
				
			END IF;--END NOTFOUND
	END IF;--END CHECK FOLDER_CD
	p_error_code := 1;
	p_error_msg := '';

EXCEPTION
    WHEN NO_DATA_FOUND THEN
		NULL;
	WHEN v_err THEN
		p_error_code := v_error_cD;
		p_error_msg :=  v_error_msg;
		ROLLBACK;
    WHEN OTHERS THEN
       -- Consider logging the error and then re-raise
	    ROLLBACK;
		p_error_code := -1;
		p_error_msg := SUBSTR(SQLERRM,1,200);
		RAISE;		
END SP_Posting_Depr_NG;