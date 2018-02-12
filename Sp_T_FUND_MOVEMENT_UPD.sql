create or replace PROCEDURE Sp_T_FUND_MOVEMENT_UPD(
	P_SEARCH_DOC_NUM T_FUND_MOVEMENT.DOC_NUM%TYPE,
	P_DOC_NUM		T_FUND_MOVEMENT.DOC_NUM%TYPE,
	P_DOC_DATE		T_FUND_MOVEMENT.DOC_DATE%TYPE,
	P_TRX_TYPE		T_FUND_MOVEMENT.TRX_TYPE%TYPE,
	P_CLIENT_CD		T_FUND_MOVEMENT.CLIENT_CD%TYPE,
	P_BRCH_CD		T_FUND_MOVEMENT.BRCH_CD%TYPE,
	P_SOURCE		T_FUND_MOVEMENT.SOURCE%TYPE,
	P_DOC_REF_NUM		T_FUND_MOVEMENT.DOC_REF_NUM%TYPE,
	P_TAL_ID_REF		T_FUND_MOVEMENT.TAL_ID_REF%TYPE,
	P_GL_ACCT_CD		T_FUND_MOVEMENT.GL_ACCT_CD%TYPE,
	P_SL_ACCT_CD		T_FUND_MOVEMENT.SL_ACCT_CD%TYPE,
	P_BANK_REF_NUM		T_FUND_MOVEMENT.BANK_REF_NUM%TYPE,
	P_BANK_MVMT_DATE		T_FUND_MOVEMENT.BANK_MVMT_DATE%TYPE,
	P_ACCT_NAME		T_FUND_MOVEMENT.ACCT_NAME%TYPE,
	P_REMARKS		T_FUND_MOVEMENT.REMARKS%TYPE,
	P_FROM_CLIENT		T_FUND_MOVEMENT.FROM_CLIENT%TYPE,
	P_FROM_ACCT		T_FUND_MOVEMENT.FROM_ACCT%TYPE,
	P_FROM_BANK		T_FUND_MOVEMENT.FROM_BANK%TYPE,
	P_TO_CLIENT		T_FUND_MOVEMENT.TO_CLIENT%TYPE,
	P_TO_ACCT		T_FUND_MOVEMENT.TO_ACCT%TYPE,
	P_TO_BANK		T_FUND_MOVEMENT.TO_BANK%TYPE,
	P_TRX_AMT		T_FUND_MOVEMENT.TRX_AMT%TYPE,
	P_CRE_DT		T_FUND_MOVEMENT.CRE_DT%TYPE,
	P_USER_ID		T_FUND_MOVEMENT.USER_ID%TYPE,
	P_CANCEL_DT		T_FUND_MOVEMENT.CANCEL_DT%TYPE,
	P_CANCEL_BY		T_FUND_MOVEMENT.CANCEL_BY%TYPE,
	--P_DOC_REF_NUM2		T_FUND_MOVEMENT.DOC_REF_NUM2%TYPE,
	P_FEE		T_FUND_MOVEMENT.FEE%TYPE,
	P_FOLDER_CD		T_FUND_MOVEMENT.FOLDER_CD%TYPE,
	P_FUND_BANK_CD		T_FUND_MOVEMENT.FUND_BANK_CD%TYPE,
	P_FUND_BANK_ACCT		T_FUND_MOVEMENT.FUND_BANK_ACCT%TYPE,
--	P_REVERSAL_JUR		T_FUND_MOVEMENT.REVERSAL_JUR%TYPE,
	P_UPD_DT		T_FUND_MOVEMENT.UPD_DT%TYPE,
	P_UPD_BY		T_FUND_MOVEMENT.UPD_BY%TYPE,
	P_UPD_STATUS					T_MANY_DETAIL.UPD_STATUS%TYPE,
	p_ip_address					T_MANY_HEADER.IP_ADDRESS%TYPE,
	p_cancel_reason					T_MANY_HEADER.CANCEL_REASON%TYPE,
	p_update_date					T_MANY_HEADER.UPDATE_DATE%TYPE,
	p_update_seq					T_MANY_HEADER.UPDATE_SEQ%TYPE,
	p_record_seq					T_MANY_DETAIL.RECORD_SEQ%TYPE,
	p_error_code					OUT			NUMBER,
	p_error_msg						OUT			VARCHAR2
) IS

--23feb fund_bank_cd, fund bank acct diisi di sp ini, bukan dr parameter

	v_err EXCEPTION;
	v_error_code				NUMBER;
	v_error_msg					VARCHAR2(1000);
	v_table_name 				T_MANY_DETAIL.table_name%TYPE := 'T_FUND_MOVEMENT';
	v_status        		    T_MANY_DETAIL.upd_status%TYPE;
	v_table_rowid	   			T_MANY_DETAIL.table_rowid%TYPE;

CURSOR csr_MANY_DETAIL IS
SELECT      column_id, column_name AS field_name,
                       DECODE(data_type,'VARCHAR2','S','CHAR','S','NUMBER','N','DATE','D','X') AS field_type
FROM all_tab_columns
WHERE table_name =v_table_name
AND OWNER = 'IPNEXTG';

CURSOR csr_table IS
SELECT *
FROM T_FUND_MOVEMENT
WHERE DOC_NUM = P_SEARCH_DOC_NUM;

v_MANY_DETAIL  Types.MANY_DETAIL_rc;

v_rec T_FUND_MOVEMENT%ROWTYPE;

v_cnt INTEGER;
 i INTEGER;
 V_FIELD_CNT NUMBER;
 v_pending_cnt NUMBER;
 va CHAR(1) := '@';
v_bank_cd mst_client_flacct.bank_cd%type;
v_bank_acct mst_client_flacct.bank_acct_num%type;
V_ACCT_NAME mst_client_flacct.ACCT_NAME%TYPE;
V_BGN_DATE date;
V_END_DATE date;
BEGIN

  --25JAN2018[INDRA]
  IF P_UPD_STATUS='I' THEN
    
     V_BGN_DATE :=P_DOC_DATE-TO_CHAR(P_DOC_DATE,'DD')+1;
      V_END_DATE := LAST_DAY(P_DOC_DATE); 
      
      begin
      SELECT COUNT(1) INTO V_CNT FROM
        (
              SELECT FOLDER_CD 
                FROM T_FUND_MOVEMENT
                WHERE DOC_DATE BETWEEN V_BGN_DATE AND V_END_DATE
                AND FOLDER_CD=P_FOLDER_CD
                UNION
                SELECT FIELD_VALUE 
                FROM
                  (
                  SELECT A.UPDATE_DATE,A.UPDATE_SEQ,A.FIELD_VALUE FROM T_MANY_DETAIL A
                  JOIN
                   ( 
                    SELECT UPDATE_DATE, UPDATE_SEQ, FIELD_VALUE
                    FROM T_MANY_DETAIL
                    WHERE UPDATE_DATE >TRUNC(SYSDATE)-10
                    AND TABLE_NAME    ='T_FUND_MOVEMENT'
                    AND FIELD_NAME  ='DOC_DATE'
                    AND TO_DATE(FIELD_VALUE,'YYYY/MM/DD HH24:MI:SS') BETWEEN V_BGN_DATE AND V_END_DATE
                    ) B ON A.UPDATE_DATE =B.UPDATE_DATE
                    AND A.UPDATE_sEQ=B.UPDATE_SEQ
                    WHERE  FIELD_NAME  ='FOLDER_CD'
                    AND TABLE_NAME    ='T_FUND_MOVEMENT'
                    AND A.FIELD_VALUE =P_FOLDER_CD
                  )
                  A
                JOIN
                  (
                    SELECT UPDATE_DATE, UPDATE_SEQ
                    FROM T_MANY_HEADER
                    WHERE UPDATE_DATE   >TRUNC(SYSDATE)-10
                    AND APPROVED_STATUS = 'E'
                  )
                  B
                ON A.UPDATE_DATE = B.UPDATE_DATE
                AND A.UPDATE_SEQ = B.UPDATE_SEQ
      );
       EXCEPTION
      WHEN OTHERS THEN
          v_error_code := -280;
            v_error_msg :=  SUBSTR('check folder code '||SQLERRM,1,200);
            RAISE v_err;
      END;
  
      IF V_CNT>0 THEN 
        v_error_code := -2006;
        v_error_msg := 'REF '||P_FOLDER_CD||' sudah digunakan';
        RAISE v_err;
      END IF;
  END IF;
  



  BEGIN
  SELECT BANK_CD, BANK_ACCT_NUM,ACCT_NAME INTO V_BANK_CD, v_bank_acct, V_ACCT_NAME FROM mst_client_flacct WHERE CLIENT_CD=P_CLIENT_CD AND ACCT_STAT IN ('A','B') AND APPROVED_stat='A';
  EXCEPTION
  WHEN OTHERS THEN
      v_error_code := -200;
        v_error_msg :=  SUBSTR('GET BANK_CD AND BANK_ACCT_NUM FROM mst_client_flacct '||SQLERRM,1,200);
        RAISE v_err;
  END;

/*
	IF 	P_UPD_STATUS = 'I' AND (P_SEARCH_DOC_REF_NUM <> P_DOC_REF_NUM) THEN
		v_error_code := -2001;
		IF P_SEARCH_DOC_REF_NUM <> p_DOC_REF_NUM THEN
			v_error_msg := 'jika INSERT, P_SEARCH_DOC_REF_NUM harus sama dengan P_DOC_REF_NUM';
		END IF;
		RAISE v_err;
	END IF;
	*/		
    BEGIN
   	 	SELECT ROWID INTO v_table_rowid
		FROM T_FUND_MOVEMENT
		WHERE DOC_NUM= P_SEARCH_DOC_NUM
		AND approved_sts = 'A';
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			v_table_rowid := NULL;
		WHEN OTHERS THEN
			v_error_code := -2;
			v_error_msg :=  SUBSTR('Retrieve  '|| v_table_name||' for '||P_SEARCH_DOC_NUM||SQLERRM,1,200);
			RAISE v_err;
	END;
	--12MAY2016---500,000,000,000
	IF P_TRX_AMT >= 500000000000 THEN
			v_error_code := -3;
			v_error_msg :=  'AMOUNT TO LARGE, PLEASE CHECK AMOUNT';
			RAISE v_err;
	END IF;
	
	
/*
	IF 	P_UPD_STATUS = 'I' AND v_table_rowid IS NOT NULL  THEN
		
			v_error_code := -2002;
			v_error_msg  := 'DUPLICATED DOC_REF_NUM' ;
			RAISE v_err;

	END IF;
	*/	
  /*
	IF 	P_UPD_STATUS = 'U' THEN
		IF	P_SEARCH_DOC_REF_NUM <> P_DOC_REF_NUM THEN
			BEGIN
				SELECT COUNT(1) INTO v_cnt
				FROM T_FUND_MOVEMENT
				WHERE DOC_REF_NUM = p_DOC_REF_NUM
				
				AND approved_sts = 'A';
			EXCEPTION
				WHEN NO_DATA_FOUND THEN
					v_cnt := 0;
				WHEN OTHERS THEN
					v_error_code := -2;
					v_error_msg :=  SUBSTR('Retrieve  '|| v_table_name||' for '||P_SEARCH_DOC_REF_NUM||SQLERRM,1,200);
					RAISE v_err;
			END;
				  
			IF v_cnt  > 0 THEN
				v_error_code := -2003;
				v_error_msg  := 'DUPLICATED DOC_REF_NUM';
				RAISE v_err;
			END IF;
		END IF;
	END IF;
			
    */	  
				  
	IF v_table_rowid IS NULL THEN
		BEGIN
			SELECT COUNT(1) INTO v_pending_cnt
			FROM (SELECT MAX(DOC_NUM) DOC_NUM
				  FROM (SELECT DECODE (field_name, 'DOC_NUM', field_value, NULL) DOC_NUM,
							 
							   d.update_seq, record_seq, field_name
						FROM T_MANY_DETAIL D, T_MANY_HEADER H
						WHERE d.table_name = v_table_name
						AND d.update_date = h.update_date
						AND d.update_seq = h.update_seq
						AND (d.field_name = 'DOC_NUM')
						AND h.APPROVED_status = 'E'
						ORDER BY d.update_seq, record_seq, field_name)
						GROUP BY update_seq, record_seq)	-- Agar SELECT MAX dapat me-retrieve composite primary key untuk setiap record
			WHERE DOC_NUM = P_SEARCH_DOC_NUM;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				v_pending_cnt := 0;
			WHEN OTHERS THEN
				v_error_code := -4;
				v_error_msg :=  SUBSTR('Retrieve T_MANY_HEADER for '|| v_table_name||SQLERRM,1,200);
				RAISE v_err;
		END;
	ELSE
		BEGIN
			SELECT COUNT(1) INTO v_pending_cnt
			FROM T_MANY_HEADER H, T_MANY_DETAIL D
			WHERE d.table_name = v_table_name
      AND H.UPDATE_DATE = D.UPDATE_DATE--24NOV
			AND h.update_seq = d.update_seq
			AND d.table_rowid = v_table_rowid
			AND h.APPROVED_status <> 'A'
			AND h.APPROVED_status <> 'R';
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				v_pending_cnt := 0;
			WHEN OTHERS THEN
				v_error_code := -5;
				v_error_msg :=  SUBSTR('Retrieve T_MANY_HEADER for '|| v_table_name||SQLERRM,1,200);
				RAISE v_err;
		END;
	END IF;

	IF  v_pending_cnt > 0 THEN
		v_error_code := -6;
		v_error_msg := 'Masih ada yang belum di-approve';
		RAISE v_err;
	END IF;

	OPEN csr_Table;
	FETCH csr_Table INTO v_rec;

	OPEN v_MANY_DETAIL FOR
		SELECT p_update_date AS update_date, p_update_seq AS update_seq, table_name, p_record_seq AS record_seq, v_table_rowid AS table_rowid, a.field_name,  field_type, b.field_value, p_upd_status AS status,  b.upd_flg
		FROM(
			SELECT  v_table_name AS table_name, column_name AS field_name, DECODE(data_type,'VARCHAR2','S','CHAR','S','NUMBER','N','DATE','D','X') AS field_type
			FROM all_tab_columns
			WHERE table_name = v_table_name
			AND OWNER = 'IPNEXTG') a,
		( 
			SELECT  'DOC_NUM'  AS field_name, p_DOC_NUM AS field_value, DECODE(trim(v_rec.DOC_NUM), trim(p_DOC_NUM),'N','Y') upd_flg FROM dual
			UNION
			SELECT  'DOC_DATE'  AS field_name, TO_CHAR(p_DOC_DATE,'yyyy/mm/dd hh24:mi:ss')  AS field_value, DECODE(v_rec.DOC_DATE, p_DOC_DATE,'N','Y') upd_flg FROM dual
			UNION
			SELECT  'TRX_TYPE'  AS field_name, p_TRX_TYPE AS field_value, DECODE(trim(v_rec.TRX_TYPE), trim(p_TRX_TYPE),'N','Y') upd_flg FROM dual
			UNION
			SELECT  'CLIENT_CD'  AS field_name, p_CLIENT_CD AS field_value, DECODE(trim(v_rec.CLIENT_CD), trim(p_CLIENT_CD),'N','Y') upd_flg FROM dual
			UNION
			SELECT  'BRCH_CD'  AS field_name, p_BRCH_CD AS field_value, DECODE(trim(v_rec.BRCH_CD), trim(p_BRCH_CD),'N','Y') upd_flg FROM dual
			UNION
			SELECT  'SOURCE'  AS field_name, p_SOURCE AS field_value, DECODE(trim(v_rec.SOURCE), trim(p_SOURCE),'N','Y') upd_flg FROM dual
			UNION
      SELECT  'DOC_REF_NUM'  AS field_name, P_DOC_REF_NUM AS field_value, DECODE(trim(v_rec.DOC_REF_NUM), trim(P_DOC_REF_NUM),'N','Y') upd_flg FROM dual
      UNION
      SELECT  'TAL_ID_REF'  AS field_name, TO_CHAR(P_TAL_ID_REF) AS field_value, DECODE(trim(v_rec.TAL_ID_REF), trim(P_TAL_ID_REF),'N','Y') upd_flg FROM dual
      UNION
      SELECT  'GL_ACCT_CD'  AS field_name, P_GL_ACCT_CD AS field_value, DECODE(trim(v_rec.GL_ACCT_CD), trim(P_GL_ACCT_CD),'N','Y') upd_flg FROM dual
      UNION
      SELECT  'SL_ACCT_CD'  AS field_name, P_SL_ACCT_CD AS field_value, DECODE(trim(v_rec.SL_ACCT_CD), trim(P_SL_ACCT_CD),'N','Y') upd_flg FROM dual
      UNION
      SELECT  'BANK_REF_NUM'  AS field_name, P_BANK_REF_NUM AS field_value, DECODE(trim(v_rec.BANK_REF_NUM), trim(P_BANK_REF_NUM),'N','Y') upd_flg FROM dual
      UNION
			SELECT  'BANK_MVMT_DATE'  AS field_name, TO_CHAR(p_BANK_MVMT_DATE,'yyyy/mm/dd hh24:mi:ss')  AS field_value, DECODE(v_rec.BANK_MVMT_DATE, p_BANK_MVMT_DATE,'N','Y') upd_flg FROM dual
			UNION
			SELECT  'ACCT_NAME'  AS field_name, NVL(p_ACCT_NAME,V_ACCT_NAME) AS field_value, DECODE(trim(v_rec.ACCT_NAME), trim(NVL(p_ACCT_NAME,V_ACCT_NAME)),'N','Y') upd_flg FROM dual
			UNION
			SELECT  'REMARKS'  AS field_name, p_REMARKS AS field_value, DECODE(trim(v_rec.REMARKS), trim(p_REMARKS),'N','Y') upd_flg FROM dual
			UNION
			SELECT  'FROM_CLIENT'  AS field_name, p_FROM_CLIENT AS field_value, DECODE(trim(v_rec.FROM_CLIENT), trim(p_FROM_CLIENT),'N','Y') upd_flg FROM dual
			UNION
			SELECT  'FROM_ACCT'  AS field_name, p_FROM_ACCT AS field_value, DECODE(trim(v_rec.FROM_ACCT), trim(p_FROM_ACCT),'N','Y') upd_flg FROM dual
			UNION
			SELECT  'FROM_BANK'  AS field_name, p_FROM_BANK AS field_value, DECODE(trim(v_rec.FROM_BANK), trim(p_FROM_BANK),'N','Y') upd_flg FROM dual
			UNION
			SELECT  'TO_CLIENT'  AS field_name, p_TO_CLIENT AS field_value, DECODE(trim(v_rec.TO_CLIENT), trim(p_TO_CLIENT),'N','Y') upd_flg FROM dual
			UNION
			SELECT  'TO_ACCT'  AS field_name, p_TO_ACCT AS field_value, DECODE(trim(v_rec.TO_ACCT), trim(p_TO_ACCT),'N','Y') upd_flg FROM dual
			UNION
			SELECT  'TO_BANK'  AS field_name, p_TO_BANK AS field_value, DECODE(trim(v_rec.TO_BANK), trim(p_TO_BANK),'N','Y') upd_flg FROM dual
			UNION
			SELECT  'TRX_AMT'  AS field_name, TO_CHAR(p_TRX_AMT)  AS field_value, DECODE(v_rec.TRX_AMT, p_TRX_AMT,'N','Y') upd_flg FROM dual
			UNION
			SELECT  'CANCEL_DT'  AS field_name, TO_CHAR(p_CANCEL_DT,'yyyy/mm/dd hh24:mi:ss')  AS field_value, DECODE(v_rec.CANCEL_DT, p_CANCEL_DT,'N','Y') upd_flg FROM dual
			UNION
			SELECT  'CANCEL_BY'  AS field_name, p_CANCEL_BY AS field_value, DECODE(trim(v_rec.CANCEL_BY), trim(p_CANCEL_BY),'N','Y') upd_flg FROM dual
			UNION
			SELECT  'FEE'  AS field_name, TO_CHAR(p_FEE)  AS field_value, DECODE(v_rec.FEE, p_FEE,'N','Y') upd_flg FROM dual
			UNION
			SELECT  'FOLDER_CD'  AS field_name, p_FOLDER_CD AS field_value, DECODE(trim(v_rec.FOLDER_CD), trim(p_FOLDER_CD),'N','Y') upd_flg FROM dual
			UNION
			SELECT  'FUND_BANK_CD'  AS field_name, V_BANK_CD AS field_value, DECODE(trim(v_rec.FUND_BANK_CD), trim(V_BANK_CD),'N','Y') upd_flg FROM dual
			UNION
			SELECT  'FUND_BANK_ACCT'  AS field_name, V_BANK_ACCT AS field_value, DECODE(trim(v_rec.FUND_BANK_ACCT), trim(V_BANK_ACCT),'N','Y') upd_flg FROM dual
			UNION
			SELECT  'CRE_DT'  AS field_name, TO_CHAR(SYSDATE,'yyyy/mm/dd hh24:mi:ss')  AS field_value, 'Y' upd_flg FROM dual
					WHERE P_UPD_STATUS = 'I'
			UNION
			SELECT  'USER_ID'  AS field_name, p_USER_ID AS field_value, 'Y' upd_flg FROM dual
					WHERE P_UPD_STATUS = 'I'
			UNION
			SELECT  'UPD_DT'  AS field_name, TO_CHAR(SYSDATE,'yyyy/mm/dd hh24:mi:ss')  AS field_value, 'Y' upd_flg FROM dual
					WHERE P_UPD_STATUS = 'U'
			UNION
			SELECT  'UPD_BY'  AS field_name, p_USER_ID AS field_value, 'Y' upd_flg FROM dual
					WHERE P_UPD_STATUS = 'U'
		) b
		WHERE a.field_name = b.field_name;
		 
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
		Sp_T_Many_Detail_Insert(p_update_date,   p_update_seq,   v_status, v_table_name, p_record_seq , v_table_rowid, v_MANY_DETAIL, v_error_code, v_error_msg);
	EXCEPTION
		WHEN OTHERS THEN
			v_error_code := -7;
			v_error_msg := SUBSTR('SP_T_MANY_DETAIL_INSERT '||v_table_name||SQLERRM,1,200);
			RAISE v_err;
	END;

	CLOSE v_MANY_DETAIL;
	CLOSE csr_Table;

	IF v_error_code < 0 THEN
	    v_error_code := -8;
		v_error_msg := 'SP_T_MANY_DETAIL_INSERT '||v_table_name||' '||v_error_msg;
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

END Sp_T_FUND_MOVEMENT_UPD;