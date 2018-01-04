create or replace 
FUNCTION F_GET_FOLDER_NUM  (p_doc_date   DATE,
	   	  		  		   				   p_prefix     T_FOLDER.FOLDER_CD%TYPE
										   )
RETURN VARCHAR2 IS

v_seq_num	  NUMBER;
v_folder_cd	  T_ACCOUNT_LEDGER.folder_cd%TYPE;
v_fld_prefix  CHAR(3);

BEGIN

 --  v_fld_prefix := 'IJ-';
	v_fld_prefix := p_prefix;

	IF trim(p_prefix) = 'IJ-' THEN
		SELECT MAX(TO_NUMBER(SUBSTR(FOLDER_CD,4,4))) INTO v_seq_num
		FROM 
		(
			SELECT folder_cd
			FROM T_FOLDER
			WHERE fld_mon = TO_CHAR(p_doc_date,'mmyy')
			AND SUBSTR(folder_cd,1,3) = v_fld_prefix
			AND SUBSTR(doc_num,5,3) in ('DNA','CNA')
			UNION
			SELECT folder_cd
			FROM
			(
				SELECT MAX(FOLDER_CD) FOLDER_CD, TO_CHAR(TO_DATE(MAX(FLD_MON),'YYYY/MM/DD HH24:MI:SS'),'MMYY') FLD_MON, MAX(DOC_NUM) DOC_NUM
				FROM 
				(
					SELECT DECODE(field_name,'FOLDER_CD',field_value, NULL) FOLDER_CD,
							DECODE(field_name,'PAYREC_DATE',field_value, NULL) FLD_MON,
							DECODE(field_name,'PAYREC_NUM',field_value, NULL) DOC_NUM,
					a.UPDATE_DATE, a.UPDATE_SEQ, RECORD_SEQ
					FROM T_MANY_DETAIL a JOIN T_MANY_HEADER b
					ON a.UPDATE_SEQ = b.UPDATE_SEQ
					AND a.UPDATE_DATE = b.UPDATE_DATE
					WHERE TABLE_NAME = 'T_PAYRECH'
					AND FIELD_NAME IN ('FOLDER_CD','PAYREC_DATE','PAYREC_NUM')
					AND APPROVED_STATUS = 'E'
				)
				GROUP BY UPDATE_DATE, UPDATE_SEQ, RECORD_SEQ
			)
			WHERE fld_mon = TO_CHAR(p_doc_date,'mmyy')
			AND SUBSTR(folder_cd,1,3) = v_fld_prefix
			AND SUBSTR(doc_num,5,3) in ('DNA','CNA')
		);
	ELSE
		SELECT MAX(TO_NUMBER(SUBSTR(FOLDER_CD,4,4))) INTO v_seq_num
		FROM 
		(
			SELECT folder_cd
			FROM T_FOLDER
			WHERE fld_mon = TO_CHAR(p_doc_date,'mmyy')
			AND SUBSTR(folder_cd,1,3) = v_fld_prefix
			UNION
			SELECT folder_cd
			FROM
			(
				SELECT MAX(FOLDER_CD) FOLDER_CD, TO_CHAR(TO_DATE(MAX(FLD_MON),'YYYY/MM/DD HH24:MI:SS'),'MMYY') FLD_MON
				FROM 
				(
					SELECT DECODE(field_name,'FOLDER_CD',field_value, NULL) FOLDER_CD,
							DECODE(field_name,'PAYREC_DATE',field_value, NULL) FLD_MON,
					a.UPDATE_DATE, a.UPDATE_SEQ, RECORD_SEQ
					FROM T_MANY_DETAIL a JOIN T_MANY_HEADER b
					ON a.UPDATE_SEQ = b.UPDATE_SEQ
					AND a.UPDATE_DATE = b.UPDATE_DATE
					WHERE TABLE_NAME = 'T_PAYRECH'
					AND FIELD_NAME IN ('FOLDER_CD','PAYREC_DATE')
					AND APPROVED_STATUS = 'E'
				)
				GROUP BY UPDATE_DATE, UPDATE_SEQ, RECORD_SEQ
			)
			WHERE fld_mon = TO_CHAR(p_doc_date,'mmyy')
			AND SUBSTR(folder_cd,1,3) = v_fld_prefix
		);
	END IF;


	IF NVL(v_seq_num,0) < 1000 AND trim(p_prefix) = 'IJ-' THEN
		v_seq_num := 1000;
	END IF;

	v_seq_num := NVL(v_seq_num,0) + 1;
	v_folder_cd := v_fld_prefix||TO_CHAR(v_seq_num,'fm0000');

	RETURN v_folder_cd;
	
EXCEPTION
	WHEN NO_DATA_FOUND THEN
		NULL;
	WHEN OTHERS THEN
		-- Consider logging the error and then re-raise
	RAISE;
END F_GET_FOLDER_NUM;