create or replace 
PROCEDURE SP_MST_MAP_LK_UPD(
	P_SEARCH_VER_BGN_DT			MST_MAP_LK.VER_BGN_DT%TYPE,
	P_SEARCH_ENTITY_CD				MST_MAP_LK.ENTITY_CD%TYPE,
	P_SEARCH_LK_ACCT				MST_MAP_LK.LK_ACCT%TYPE,
	P_SEARCH_GL_A				MST_MAP_LK.GL_A%TYPE,
	P_SEARCH_SL_A				MST_MAP_LK.SL_A%TYPE,
	P_SEARCH_COL_NUM				MST_MAP_LK.COL_NUM%TYPE,
	P_VER_BGN_DT		MST_MAP_LK.VER_BGN_DT%TYPE,
	P_VER_END_DT		MST_MAP_LK.VER_END_DT%TYPE,
	P_ENTITY_CD		MST_MAP_LK.ENTITY_CD%TYPE,
	P_LK_ACCT		MST_MAP_LK.LK_ACCT%TYPE,
	P_GL_A		MST_MAP_LK.GL_A%TYPE,
	P_SL_A		MST_MAP_LK.SL_A%TYPE,
	P_COL_NUM		MST_MAP_LK.COL_NUM%TYPE,
	P_SIGN		MST_MAP_LK.SIGN%TYPE,
	P_CRE_DT		MST_MAP_LK.CRE_DT%TYPE,
	P_USER_ID		MST_MAP_LK.USER_ID%TYPE,
	P_UPD_DT		MST_MAP_LK.UPD_DT%TYPE,
	P_UPD_BY		MST_MAP_LK.UPD_BY%TYPE,
	P_UPD_STATUS				T_TEMP_HEADER.STATUS%TYPE,
	p_ip_address				T_TEMP_HEADER.IP_ADDRESS%TYPE,
	p_cancel_reason				T_TEMP_HEADER.CANCEL_REASON%TYPE,
	p_error_code				OUT			NUMBER,
	p_error_msg					OUT			VARCHAR2
) IS

	v_err EXCEPTION;
	v_error_code				NUMBER;
	v_error_msg					VARCHAR2(1000);
	v_table_name 				T_TEMP_HEADER.table_name%TYPE := 'MST_MAP_LK';
	v_status        		    T_TEMP_HEADER.status%TYPE;
	v_table_rowid	   			T_TEMP_HEADER.table_rowid%TYPE;


CURSOR csr_temp_detail IS
SELECT      column_id, column_name AS field_name,
                       DECODE(data_type,'VARCHAR2','S','CHAR','S','NUMBER','N','DATE','D','X') AS field_type
FROM all_tab_columns
WHERE table_name =v_table_name
AND OWNER = 'IPNEXTG';

CURSOR csr_table IS
SELECT *
FROM MST_MAP_LK
WHERE VER_BGN_DT = P_SEARCH_VER_BGN_DT
	AND ENTITY_CD = P_SEARCH_ENTITY_CD
	AND LK_ACCT = P_SEARCH_LK_ACCT
	AND TRIM(GL_A) = TRIM(P_SEARCH_GL_A)
	AND SL_A = P_SEARCH_SL_A
	AND COL_NUM = P_SEARCH_COL_NUM;

v_temp_detail  Types.temp_detail_rc;

v_rec MST_MAP_LK%ROWTYPE;



v_cnt INTEGER;
 i INTEGER;
 V_FIELD_CNT NUMBER;
 v_pending_cnt NUMBER;
 va CHAR(1) := '@';
BEGIN

			IF 	  P_UPD_STATUS = 'I' AND (P_SEARCH_VER_BGN_DT <> P_VER_BGN_DT
								OR P_SEARCH_ENTITY_CD <> P_ENTITY_CD
								OR P_SEARCH_LK_ACCT <> P_LK_ACCT
								OR TRIM(P_SEARCH_GL_A) <> TRIM(P_GL_A)
								OR P_SEARCH_SL_A <> P_SL_A
								OR P_SEARCH_COL_NUM <> P_COL_NUM) THEN
			       v_error_code := -2001;
					IF P_SEARCH_VER_BGN_DT <> P_VER_BGN_DT THEN
				   		v_error_msg := 'jika INSERT, P_SEARCH_VER_BGN_DT harus sama dengan P_VER_BGN_DT';
					END IF;
					IF P_SEARCH_ENTITY_CD <> P_ENTITY_CD THEN
				   		v_error_msg := 'jika INSERT, P_SEARCH_ENTITY_CD harus sama dengan P_ENTITY_CD';
					END IF;
					IF P_SEARCH_LK_ACCT <> P_LK_ACCT THEN
				   		v_error_msg := 'jika INSERT, P_SEARCH_LK_ACCT harus sama dengan P_LK_ACCT';
					END IF;
					IF TRIM(P_SEARCH_GL_A) <> TRIM(P_GL_A) THEN
				   		v_error_msg := 'jika INSERT, P_SEARCH_GL_A harus sama dengan P_GL_A';
					END IF;
					IF P_SEARCH_SL_A <> P_SL_A THEN
				   		v_error_msg := 'jika INSERT, P_SEARCH_SL_A harus sama dengan P_SL_A';
					END IF;
					IF P_SEARCH_COL_NUM <> P_COL_NUM THEN
				   		v_error_msg := 'jika INSERT, P_SEARCH_COL_NUM harus sama dengan P_COL_NUM';
					END IF;

				   RAISE v_err;
			END IF;

            BEGIN
   	 		 SELECT ROWID INTO v_table_rowid
			 FROM MST_MAP_LK
			  WHERE VER_BGN_DT = P_SEARCH_VER_BGN_DT
					AND ENTITY_CD = p_SEARCH_ENTITY_CD
					AND LK_ACCT = p_SEARCH_LK_ACCT
					AND TRIM(GL_A) = TRIM(p_SEARCH_GL_A)
					AND SL_A = p_SEARCH_SL_A
					AND COL_NUM = p_SEARCH_COL_NUM;
			 EXCEPTION
			 WHEN NO_DATA_FOUND THEN
			 	  v_table_rowid := NULL;
			WHEN OTHERS THEN
				     v_error_code := -2;
					 v_error_msg :=  SUBSTR('Retrieve  '|| v_table_name|| ' ' ||SQLERRM,1,200);
					 RAISE v_err;
				  END;

			IF 	  P_UPD_STATUS = 'I' AND v_table_rowid IS NOT NULL THEN
			       v_error_code := -2001;
				   v_error_msg  := 'DUPLICATED VERSION BEGIN DATE, ENTITY CODE, LK_ACCT, GL_A, SL_A, COL NUM';
				   RAISE v_err;
			END IF;

			IF 	  P_UPD_STATUS = 'U' AND (P_SEARCH_VER_BGN_DT <> P_VER_BGN_DT
								OR P_SEARCH_ENTITY_CD <> P_ENTITY_CD
								OR P_SEARCH_LK_ACCT <> P_LK_ACCT
								OR TRIM(P_SEARCH_GL_A) <> TRIM(P_GL_A)
								OR P_SEARCH_SL_A <> P_SL_A
								OR P_SEARCH_COL_NUM <> P_COL_NUM) THEN
				 BEGIN
	   	 		 SELECT COUNT(1) INTO v_cnt
				 FROM MST_MAP_LK
				 WHERE VER_BGN_DT = P_VER_BGN_DT
					AND ENTITY_CD = p_ENTITY_CD
					AND LK_ACCT = p_LK_ACCT
					AND TRIM(GL_A) = TRIM(p_GL_A)
					AND SL_A = p_SL_A
					AND COL_NUM = p_COL_NUM;
				 EXCEPTION
				 WHEN NO_DATA_FOUND THEN
				 	  v_cnt := 0;
				WHEN OTHERS THEN
					     v_error_code := -3;
						 v_error_msg :=  SUBSTR('Retrieve  '|| v_table_name|| ' ' || SQLERRM,1,200);
						 RAISE v_err;
				  END;

				  IF v_cnt  > 0 THEN
					       v_error_code := -2003;
						   v_error_msg  := 'DUPLICATED VERSION BEGIN DATE, ENTITY CODE, LK_ACCT, GL_A, SL_A, COL NUM';
						   RAISE v_err;
				   END IF;
			END IF;

--			BEGIN
--				SELECT 1 INTO v_cnt FROM dual
--				WHERE P_GL_ACCT_CD IN ('SUM','TXT','BLANK','CALC','SUM1','SUM2','SUM3');
--			EXCEPTION
--				WHEN NO_DATA_FOUND THEN
--					v_cnt := 0;
--				WHEN OTHERS THEN
--					v_error_code := -4;
--					v_error_msg := SUBSTR('Retrieve FROM dual ' || SQLERRM,1,200);
--					RAISE v_err;
--			END;


			IF v_table_rowid IS NULL THEN
					 BEGIN
					 SELECT COUNT(1) INTO v_pending_cnt
					 FROM (SELECT MAX(VER_BGN_DT) VER_BGN_DT, MAX(ENTITY_CD) ENTITY_CD, MAX(LK_ACCT) LK_ACCT, MAX(GL_A) GL_A, MAX(SL_A) SL_A, MAX(COL_NUM) COL_NUM
							FROM (SELECT DECODE (field_name, 'VER_BGN_DT', field_value, NULL) VER_BGN_DT,
								DECODE	(field_name, 'ENTITY_CD', field_value, NULL) ENTITY_CD,
								DECODE	(field_name, 'LK_ACCT', field_value, NULL) LK_ACCT,
								DECODE	(field_name, 'GL_A', field_value, NULL) GL_A,
								DECODE	(field_name, 'SL_A', field_value, NULL) SL_A,
								DECODE	(field_name, 'COL_NUM', field_value, NULL) COL_NUM,
								h.update_seq
								 FROM T_TEMP_DETAIL D, T_TEMP_HEADER H
								 WHERE h.table_name = v_table_name
								 AND d.update_date = h.update_date
								 AND d.update_seq = h.update_seq
								 AND d.table_name = h.table_name
								 AND (d.field_name = 'VER_BGN_DT'
										OR d.field_name = 'ENTITY_CD'
										OR d.field_name = 'LK_ACCT'
										OR d.field_name = 'GL_A'
										OR d.field_name = 'SL_A'
										OR d.field_name = 'COL_NUM')
								 AND h.APPROVED_status = 'E')
							GROUP BY update_seq
							)
					  WHERE VER_BGN_DT = P_VER_BGN_DT
								AND ENTITY_CD = p_ENTITY_CD
								AND LK_ACCT = p_LK_ACCT
								AND GL_A = p_GL_A
								AND SL_A = p_SL_A
								AND COL_NUM = p_COL_NUM;
					 EXCEPTION
					 WHEN NO_DATA_FOUND THEN
					         v_pending_cnt := 0;
					WHEN OTHERS THEN
							 v_error_code := -8;
							 v_error_msg :=  SUBSTR('Retrieve T_TEMP_HEADER for '|| v_table_name||SQLERRM,1,200);
							 RAISE v_err;
					END;
			ELSE
					BEGIN
					 SELECT COUNT(1) INTO v_pending_cnt
					 FROM T_TEMP_HEADER H
					 WHERE h.table_name = v_table_name
					  AND   h.table_rowid = v_table_rowid
					 AND h.APPROVED_status <> 'A'
           			 AND h.APPROVED_status <> 'R';
					 EXCEPTION
					 WHEN NO_DATA_FOUND THEN
					         v_pending_cnt := 0;
					WHEN OTHERS THEN
							 v_error_code := -9;
							 v_error_msg :=  SUBSTR('Retrieve T_TEMP_HEADER for '|| v_table_name||SQLERRM,1,200);
							 RAISE v_err;
					END;
			END IF;



			IF  v_pending_cnt > 0 THEN
				v_error_code := -10;
				v_error_msg := 'Masih ada yang belum di-approve';
				RAISE v_err;
			END IF;

			--v_FORMULA := 'MAR2013';



			OPEN csr_Table;
			FETCH csr_Table INTO v_rec;


		OPEN v_Temp_detail FOR
		SELECT update_date, table_name,  0 update_seq,  a.field_name,  field_type, b.field_value, a.column_id, b.upd_flg
		FROM(
		 SELECT  SYSDATE AS  update_date, v_table_name AS table_name, column_id, column_name AS field_name,
		                       					DECODE(data_type,'VARCHAR2','S','CHAR','S','NUMBER','N','DATE','D','X') AS field_type
										FROM all_tab_columns
										WHERE table_name = v_table_name
										AND OWNER = 'IPNEXTG') a,
		(SELECT  'VER_BGN_DT'  AS field_name, TO_CHAR(p_VER_BGN_DT,'yyyy/mm/dd hh24:mi:ss')  AS field_value, DECODE(v_rec.VER_BGN_DT, p_VER_BGN_DT,'N','Y') upd_flg FROM dual
		UNION
		SELECT  'VER_END_DT'  AS field_name, TO_CHAR(p_VER_END_DT,'yyyy/mm/dd hh24:mi:ss')  AS field_value, DECODE(v_rec.VER_END_DT, p_VER_END_DT,'N','Y') upd_flg FROM dual
		UNION
		SELECT  'ENTITY_CD'  AS field_name, p_ENTITY_CD AS field_value, DECODE(trim(v_rec.ENTITY_CD), trim(p_ENTITY_CD),'N','Y') upd_flg FROM dual
		UNION
		SELECT  'LK_ACCT'  AS field_name, p_LK_ACCT AS field_value, DECODE(trim(v_rec.LK_ACCT), trim(p_LK_ACCT),'N','Y') upd_flg FROM dual
		UNION
		SELECT  'GL_A'  AS field_name, p_GL_A AS field_value, DECODE(trim(v_rec.GL_A), trim(p_GL_A),'N','Y') upd_flg FROM dual
		UNION
		SELECT  'SL_A'  AS field_name, p_SL_A AS field_value, DECODE(trim(v_rec.SL_A), trim(p_SL_A),'N','Y') upd_flg FROM dual
		UNION
		SELECT  'COL_NUM'  AS field_name, TO_CHAR(p_COL_NUM)  AS field_value, DECODE(v_rec.COL_NUM, p_COL_NUM,'N','Y') upd_flg FROM dual
		UNION
		SELECT  'SIGN'  AS field_name, TO_CHAR(p_SIGN)  AS field_value, DECODE(v_rec.SIGN, p_SIGN,'N','Y') upd_flg FROM dual
		UNION
		SELECT  'CRE_DT'  AS field_name, TO_CHAR(SYSDATE,'yyyy/mm/dd hh24:mi:ss')  AS field_value, 'Y' upd_flg FROM dual
		WHERE P_UPD_STATUS = 'I'
		UNION
		SELECT  'UPD_DT'  AS field_name, TO_CHAR(SYSDATE,'yyyy/mm/dd hh24:mi:ss')  AS field_value, 'Y' upd_flg FROM dual
		WHERE P_UPD_STATUS = 'U'
		UNION
		SELECT  'USER_ID'  AS field_name, p_USER_ID AS field_value, 'Y' upd_flg FROM dual
		WHERE P_UPD_STATUS = 'I'
		UNION
		SELECT  'UPD_BY'  AS field_name, p_USER_ID AS field_value, 'Y' upd_flg FROM dual
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
    Sp_T_Temp_Insert(v_table_name,   v_table_rowid,   v_status,p_user_id, p_ip_address , p_cancel_reason, v_temp_detail, v_error_code, v_error_msg);
EXCEPTION
WHEN OTHERS THEN
		 v_error_code := -11;
		  v_error_msg := SUBSTR('SP_T_TEMP_INSERT '||v_table_name||SQLERRM,1,200);
		  RAISE v_err;
END;

	CLOSE v_Temp_detail;
	CLOSE csr_Table;

	IF v_error_code < 0 THEN
	      v_error_code := -12;
		  v_error_msg := 'SP_T_TEMP_INSERT '||v_table_name||' '||v_error_msg;
		  RAISE v_err;
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
       -- Consider logging the error and then re-raise
	      ROLLBACK;
	   p_error_code := -1;
	   p_error_msg := SUBSTR(SQLERRM,1,200);
       RAISE;

END SP_MST_MAP_LK_UPD;