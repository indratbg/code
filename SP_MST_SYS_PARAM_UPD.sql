create or replace PROCEDURE SP_MST_SYS_PARAM_UPD (
        P_SEARCH_PARAM_ID		MST_SYS_PARAM.PARAM_ID%TYPE,
		P_SEARCH_PARAM_CD1		MST_SYS_PARAM.PARAM_CD1%TYPE,
		P_SEARCH_PARAM_CD2		MST_SYS_PARAM.PARAM_CD2%TYPE,
		P_SEARCH_PARAM_CD3		MST_SYS_PARAM.PARAM_CD3%TYPE,
        P_PARAM_ID		MST_SYS_PARAM.PARAM_ID%TYPE,
		P_PARAM_CD1		MST_SYS_PARAM.PARAM_CD1%TYPE,
		P_PARAM_CD2		MST_SYS_PARAM.PARAM_CD2%TYPE,
		P_PARAM_CD3		MST_SYS_PARAM.PARAM_CD3%TYPE,
		P_DSTR1		MST_SYS_PARAM.DSTR1%TYPE,
		P_DSTR2		MST_SYS_PARAM.DSTR2%TYPE,
		P_DNUM1		MST_SYS_PARAM.DNUM1%TYPE,
		P_DNUM2		MST_SYS_PARAM.DNUM2%TYPE,
		P_DDATE1		MST_SYS_PARAM.DDATE1%TYPE,
		P_DDATE2		MST_SYS_PARAM.DDATE2%TYPE,
		P_DFLG1		MST_SYS_PARAM.DFLG1%TYPE,
		P_DFLG2		MST_SYS_PARAM.DFLG2%TYPE,
		P_CRE_DT MST_SYS_PARAM.CRE_DT%TYPE,
		P_USER_ID MST_SYS_PARAM.USER_ID%TYPE,
		P_UPD_DT MST_SYS_PARAM.UPD_DT%TYPE,
		P_UPD_BY MST_SYS_PARAM.UPD_BY%TYPE,
		P_UPD_STATUS					T_TEMP_HEADER.STATUS%TYPE,
	   p_ip_address								T_TEMP_HEADER.IP_ADDRESS%TYPE,
	   p_cancel_reason						T_TEMP_HEADER.CANCEL_REASON%TYPE,
	   p_error_code					OUT			NUMBER,
	   p_error_msg					OUT			VARCHAR2
) IS

  v_err EXCEPTION;
v_error_code							NUMBER;
v_error_msg							VARCHAR2(200);
v_table_name T_TEMP_HEADER.table_name%TYPE := 'MST_SYS_PARAM';
v_status               T_TEMP_HEADER.status%TYPE;
v_table_rowid				   T_TEMP_HEADER.table_rowid%TYPE;
CURSOR csr_temp_detail IS
SELECT      column_id, column_name AS field_name,
                       DECODE(data_type,'VARCHAR2','S','CHAR','S','NUMBER','N','DATE','D','X') AS field_type
FROM all_tab_columns
WHERE table_name =v_table_name
AND OWNER = 'IPNEXTG';

v_temp_detail  Types.temp_detail_rc;

v_rec MST_SYS_PARAM%ROWTYPE;


v_cnt INTEGER;
 i INTEGER;
 V_FIELD_CNT NUMBER;
 v_pending_cnt NUMBER;
 va CHAR(1) := '@';
BEGIN

			IF 	  P_UPD_STATUS = 'I' THEN
			       v_error_code := -2001;
				   IF  P_SEARCH_PARAM_ID <> P_PARAM_ID THEN
				   	   v_error_msg  := 'jika INSERT, P_SEARCH_PARAM_ID harus sama dengan P_PARAM_ID';
                RAISE v_err;
					END IF;
					IF  P_SEARCH_PARAM_CD1 <> P_PARAM_CD1 THEN
				   	   v_error_msg  := 'jika INSERT, p_search_PRM_CD_1 harus sama dengan p_PRM_CD_1';
                RAISE v_err;
					END IF;
					IF  P_SEARCH_PARAM_CD2 <> P_PARAM_CD2 THEN
				   	   v_error_msg  := 'jika INSERT, p_search_PRM_CD_2 harus sama dengan p_PRM_CD_2';
                RAISE v_err;
					END IF;
					IF  P_SEARCH_PARAM_CD3 <> P_PARAM_CD3 THEN
				   	   v_error_msg  := 'jika INSERT, p_search_PRM_CD_3 harus sama dengan p_PRM_CD_3';
                RAISE v_err;
					END IF;
					   
			END IF;
			
             BEGIN
   	 		 SELECT ROWID INTO v_table_rowid
			 FROM MST_SYS_PARAM
			 WHERE PARAM_ID = P_SEARCH_PARAM_ID
			 AND PARAM_CD1 = P_SEARCH_PARAM_CD1
			 AND PARAM_CD2 = P_SEARCH_PARAM_CD2
			 AND PARAM_CD3 = P_SEARCH_PARAM_CD3;
			 EXCEPTION
			 WHEN NO_DATA_FOUND THEN
			 	  v_table_rowid := NULL;
			WHEN OTHERS THEN
				     v_error_code := -2;
					 v_error_msg :=  SUBSTR('Retrieve  '|| v_table_name||' for '||P_SEARCH_PARAM_ID||SQLERRM,1,200);
					 RAISE v_err;
				  END;

			IF 	  P_UPD_STATUS = 'I' AND v_table_rowid IS NOT NULL THEN
			       v_error_code := -2001;
				   v_error_msg  := 'DUPLICATED ';
				   RAISE v_err;
			END IF;
			
			IF 	  P_UPD_STATUS = 'U'   AND (P_SEARCH_PARAM_ID <> P_PARAM_ID OR  P_SEARCH_PARAM_CD1	 <> P_PARAM_CD1	
          OR P_SEARCH_PARAM_CD2 <> P_PARAM_CD2 OR P_SEARCH_PARAM_CD3 <> P_SEARCH_PARAM_CD3)		 THEN
				 BEGIN
	   	 		 SELECT COUNT(1) INTO v_cnt
				 FROM MST_SYS_PARAM
				 WHERE PARAM_ID = P_PARAM_ID
			 		AND PARAM_CD1=P_PARAM_CD1
			 		AND PARAM_CD2 = P_PARAM_CD2
			 		AND PARAM_cD3=P_PARAM_CD3;
				 EXCEPTION
				 WHEN NO_DATA_FOUND THEN
				 	  v_cnt := 0;
				WHEN OTHERS THEN
					     v_error_code := -2005;
						 v_error_msg :=  SUBSTR('Retrieve  '|| v_table_name||' for '||P_PARAM_ID||SQLERRM,1,200);
						 RAISE v_err;
				  END; 
				  
				  IF v_cnt  > 0 THEN
					       v_error_code := -2003;
						   v_error_msg  := 'DUPLICATED ';
						   RAISE v_err;
				   END IF;
			END IF;
			
				  
				  
			IF v_table_rowid IS NULL THEN
					 BEGIN
					 SELECT COUNT(1) INTO v_pending_cnt
					 FROM(  SELECT MAX(PARAM_ID) PARAM_ID,MAX(P_PARAM_CD1) PARAM_CD1, MAX(PARAM_CD2)PARAM_CD2, MAX(PARAM_CD3)PARAM_CD3
								FROM( SELECT DECODE(field_name, 'PARAM_ID',field_value, NULL) PARAM_ID,
										 DECODE(field_name, 'PARAM_CD1',field_value, NULL) PARAM_CD1,
										 DECODE(field_name, 'PARAM_CD2',field_value, NULL) PARAM_CD2,
										 DECODE(field_name, 'PARAM_CD3',field_value, NULL) PARAM_CD3
									 FROM T_TEMP_DETAIL D, T_TEMP_HEADER H
									 WHERE h.table_name =v_table_name
									 AND d.update_date = h.update_date
									 AND d.update_seq =h.update_seq
									 AND  d.table_name = h.table_name
									 AND d.field_name IN ('PARAM_ID','PARAM_CD1','PARAM_CD2','PARAM_CD3')					           
									 AND h.APPROVED_status = 'E'))
							WHERE  PARAM_ID = P_PARAM_ID
							AND PARAM_CD1 = P_PARAM_CD1
							AND PARAM_CD2 = P_PARAM_CD2
							AND PARAM_CD3 = P_PARAM_CD3;
					EXCEPTION
					WHEN NO_DATA_FOUND THEN
						v_pending_cnt := 0;
					WHEN OTHERS THEN
						v_error_code := -4;
						v_error_msg :=  SUBSTR('Retrieve T_TEMP_HEADER for '|| v_table_name||SQLERRM,1,200);
						RAISE v_err;
					END;
			ELSE
					BEGIN
					 SELECT COUNT(1) INTO v_pending_cnt
					 FROM T_TEMP_HEADER H
					 WHERE h.table_name = v_table_name
					  AND   h.table_rowid = v_table_rowid
					 AND h.APPROVED_status = 'E';
					 EXCEPTION
					 WHEN NO_DATA_FOUND THEN
					         v_pending_cnt := 0;
					WHEN OTHERS THEN
							 v_error_code := -5;
							 v_error_msg :=  SUBSTR('Retrieve T_TEMP_HEADER for '|| v_table_name||SQLERRM,1,200);
							 RAISE v_err;
					END;
			END IF;



			IF  v_pending_cnt > 0 THEN
				v_error_code := -6;
				v_error_msg := 'Masih ada yang belum di-approve';
				RAISE v_err;
			END IF;




		OPEN v_Temp_detail FOR
		SELECT update_date, table_name,  0 update_seq,  a.field_name,  field_type, b.field_value, a.column_id, b.upd_flg
		FROM(
		 SELECT  SYSDATE AS  update_date, v_table_name AS table_name, column_id,    column_name AS field_name,
		                       					DECODE(data_type,'VARCHAR2','S','CHAR','S','NUMBER','N','DATE','D','X') AS field_type
										FROM all_tab_columns
										WHERE table_name =v_table_name
										AND OWNER = 'IPNEXTG') a,
		(  
			SELECT  'PARAM_ID'  AS field_name, p_PARAM_ID AS field_value, DECODE(trim(v_rec.PARAM_ID), trim(p_PARAM_ID),'N','Y') upd_flg FROM dual
			UNION
			SELECT  'PARAM_CD1'  AS field_name, p_PARAM_CD1 AS field_value, DECODE(trim(v_rec.PARAM_CD1), trim(p_PARAM_CD1),'N','Y') upd_flg FROM dual
			UNION
			SELECT  'PARAM_CD2'  AS field_name, p_PARAM_CD2 AS field_value, DECODE(trim(v_rec.PARAM_CD2), trim(p_PARAM_CD2),'N','Y') upd_flg FROM dual
			UNION
			SELECT  'PARAM_CD3'  AS field_name, p_PARAM_CD3 AS field_value, DECODE(trim(v_rec.PARAM_CD3), trim(p_PARAM_CD3),'N','Y') upd_flg FROM dual
			UNION
			SELECT  'DSTR1'  AS field_name, p_DSTR1 AS field_value, DECODE(trim(v_rec.DSTR1), trim(p_DSTR1),'N','Y') upd_flg FROM dual
			UNION
			SELECT  'DSTR2'  AS field_name, p_DSTR2 AS field_value, DECODE(trim(v_rec.DSTR2), trim(p_DSTR2),'N','Y') upd_flg FROM dual
			UNION
			SELECT  'DNUM1'  AS field_name, TO_CHAR(p_DNUM1)  AS field_value, DECODE(v_rec.DNUM1, p_DNUM1,'N','Y') upd_flg FROM dual
			UNION
			SELECT  'DNUM2'  AS field_name, TO_CHAR(p_DNUM2)  AS field_value, DECODE(v_rec.DNUM2, p_DNUM2,'N','Y') upd_flg FROM dual
			UNION
			SELECT  'DDATE1'  AS field_name, TO_CHAR(p_DDATE1,'yyyy/mm/dd hh24:mi:ss')  AS field_value, DECODE(v_rec.DDATE1, p_DDATE1,'N','Y') upd_flg FROM dual
			UNION
			SELECT  'DDATE2'  AS field_name, TO_CHAR(p_DDATE2,'yyyy/mm/dd hh24:mi:ss')  AS field_value, DECODE(v_rec.DDATE2, p_DDATE2,'N','Y') upd_flg FROM dual
			UNION
			SELECT  'DFLG1'  AS field_name, p_DFLG1 AS field_value, DECODE(trim(v_rec.DFLG1), trim(p_DFLG1),'N','Y') upd_flg FROM dual
			UNION
			SELECT  'DFLG2'  AS field_name, p_DFLG2 AS field_value, DECODE(trim(v_rec.DFLG2), trim(p_DFLG2),'N','Y') upd_flg FROM dual
			UNION
			SELECT  'CRE_DT'  AS field_name, TO_CHAR(p_CRE_DT,'yyyy/mm/dd hh24:mi:ss')  AS field_value, DECODE(v_rec.CRE_DT, p_CRE_DT,'N','Y') upd_flg FROM dual
			WHERE P_UPD_STATUS = 'I'
			UNION
			SELECT  'USER_ID'  AS field_name, p_USER_ID AS field_value, DECODE(trim(v_rec.USER_ID), trim(p_USER_ID),'N','Y') upd_flg FROM dual
			WHERE P_UPD_STATUS = 'I'
			UNION
			SELECT  'UPD_DT'  AS field_name, TO_CHAR(p_UPD_DT,'yyyy/mm/dd hh24:mi:ss')  AS field_value, DECODE(v_rec.UPD_DT, p_UPD_DT,'N','Y') upd_flg FROM dual
			WHERE P_UPD_STATUS = 'U'
			UNION
			SELECT  'UPD_BY'  AS field_name, p_UPD_BY AS field_value, DECODE(trim(v_rec.UPD_BY), trim(p_UPD_BY),'N','Y') upd_flg FROM dual
			WHERE P_UPD_STATUS = 'U'
		) b
		 WHERE a.field_name = b.field_name
				AND  P_UPD_STATUS <> 'C';
		 
IF v_table_rowid IS NOT NULL THEN
	    IF P_UPD_STATUS = 'C' THEN
		   				  v_status := 'C';
		   ELSE
	       	   			  v_status := 'U';
		   END IF;
	ELSE
		 v_status := 'I';
 END IF;


 BEGIN
    Sp_T_Temp_Insert(v_table_name,   v_table_rowid,   v_status,P_USER_ID, p_ip_address , p_cancel_reason, v_temp_detail, v_error_code, v_error_msg);
EXCEPTION
WHEN OTHERS THEN
		 v_error_code := -7;
		  v_error_msg := SUBSTR('SP_T_TEMP_INSERT '||v_table_name||SQLERRM,1,200);
		  RAISE v_err;
END;

	CLOSE v_Temp_detail;
	

	IF v_error_code < 0 THEN
	      v_error_code := -8;
		  v_error_msg := 'SP_T_TEMP_INSERT '||v_table_name||' '||v_error_msg;
		  RAISE v_err;
	  END IF;

	  COMMIT;
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
       -- Consider logging the error and then re-raise
	      ROLLBACK;
	   p_error_code := -1;
	   p_error_msg := SUBSTR(SQLERRM,1,200);
       RAISE;

END SP_MST_SYS_PARAM_UPD;