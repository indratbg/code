create or replace 
procedure SP_GEN_TC_CLOB(
P_TC_DATE	T_TC_DOC.TC_DATE%TYPE,
P_TC_ID		T_TC_DOC.TC_ID%TYPE,
P_TC_REV	T_TC_DOC.TC_REV%TYPE,
P_TC_CLOB_ENG IN	CLOB,
P_TC_CLOB_IND IN	CLOB,
P_TC_MATRIX_ENG IN CLOB,
P_TC_MATRIX_IND IN CLOB,
P_UPD_STAT    NUMBER,
P_ERROR_CODE	OUT NUMBER,
P_ERROR_MSG		OUT VARCHAR2
) as

--v_clob_eng clob;
--v_clob_ind clob;
v_err	EXCEPTION;
v_error_code	NUMBER;
v_error_msg		VARCHAR2(200);
v_cnt  NUMBER;
v_pending_cnt NUMBER;
nloop_eng NUMBER;
nloop_ind NUMBER;
nloop_eng_mx NUMBER;
nloop_ind_mx NUMBER;
n NUMBER;
i NUMBER := 1;

BEGIN

  nloop_eng := CEIL(LENGTH(P_TC_CLOB_ENG)/4000);
  nloop_ind := CEIL(LENGTH(P_TC_CLOB_IND)/4000);
  nloop_eng_mx := CEIL(LENGTH(P_TC_MATRIX_ENG)/4000);
  nloop_ind_mx := CEIL(LENGTH(P_TC_MATRIX_IND)/4000);
  
  BEGIN
    SELECT count(1) into v_cnt from T_TC_DOC
    where TC_DATE = P_TC_DATE
		AND TC_ID = P_TC_ID
		AND TC_REV = P_TC_REV
    AND TC_TYPE = 'CONGEN'
    AND TC_STATUS = -1;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      v_cnt := 0;
    WHEN OTHERS THEN
      v_error_code := -2;
      v_error_msg := SUBSTR('Retrieve TC from T_TC_DOC '||v_cnt||' '||SQLERRM,1,200);
      RAISE v_err;
  END;
  
  IF v_cnt <= 0 THEN
    v_error_code := -3;
    v_error_msg := 'TC Not Found';
    RAISE v_err;
  END IF;
  
  IF P_UPD_STAT = 0 THEN
    BEGIN
      UPDATE T_TC_DOC set TC_CLOB_ENG = empty_clob(), TC_CLOB_IND = empty_clob()
      where TC_DATE = P_TC_DATE
      AND TC_ID = P_TC_ID
      AND TC_REV = P_TC_REV
      AND TC_TYPE = 'CONGEN'
      AND TC_STATUS = -1;
    
    EXCEPTION
      WHEN OTHERS THEN
      v_error_code := -4;
      v_error_msg := SUBSTR('UPDATE CLOB from T_TC_DOC '||SQLERRM,1,200);
      RAISE v_err;
    END;
    
  END IF;

  FOR n in 1..nloop_eng LOOP
    BEGIN
    /*
		select TC_CLOB_ENG into v_clob_eng from T_TC_DOC 
		where TC_DATE = P_TC_DATE
		AND TC_ID = P_TC_ID
		AND TC_REV = P_TC_REV
    AND TC_TYPE = 'CONGEN'
    AND TC_STATUS = -1
		for update;
    --dbms_lob.open(v_clob_eng,dbms_lob.lob_readwrite);
		dbms_lob.write(v_clob_eng,length(P_TC_CLOB_ENG), 1,P_TC_CLOB_ENG);
    --dbms_lob.close(v_clob_eng);
    */
      UPDATE T_TC_DOC SET TC_CLOB_ENG = TC_CLOB_ENG||SUBSTR(P_TC_CLOB_ENG,((n-1)*4000+i),4000)
      WHERE TC_DATE = P_TC_DATE
      AND TC_ID = P_TC_ID
      AND TC_REV = P_TC_REV
      AND TC_TYPE = 'CONGEN'
      AND TC_STATUS = -1;
    EXCEPTION
      WHEN OTHERS THEN
      v_error_code := -5;
      v_error_msg := SUBSTR('UPDATE CLOB eng into T_TC_DOC '||SQLERRM,1,200);
      RAISE v_err;
    
    END;
  EXIT WHEN v_error_code < 0;
  END LOOP;
  
  FOR n in 1..nloop_ind LOOP
    BEGIN
    /*
		select TC_CLOB_IND into v_clob_ind from T_TC_DOC 
		where TC_DATE = P_TC_DATE
		AND TC_ID = P_TC_ID
		AND TC_REV = P_TC_REV
    AND TC_TYPE = 'CONGEN'
    AND TC_STATUS = -1
		for update;
    --dbms_lob.open(v_clob_ind,dbms_lob.lob_readwrite);
		dbms_lob.write(v_clob_ind,length(P_TC_CLOB_IND), 1,P_TC_CLOB_IND);
    --dbms_lob.close(v_clob_ind);
    */
      UPDATE T_TC_DOC SET TC_CLOB_IND = TC_CLOB_IND||SUBSTR(P_TC_CLOB_IND,((n-1)*4000+i),4000)
      WHERE TC_DATE = P_TC_DATE
      AND TC_ID = P_TC_ID
      AND TC_REV = P_TC_REV
      AND TC_TYPE = 'CONGEN'
      AND TC_STATUS = -1;
    EXCEPTION
      WHEN OTHERS THEN
      v_error_code := -6;
      v_error_msg := SUBSTR('UPDATE CLOB ind into T_TC_DOC '||SQLERRM,1,200);
      RAISE v_err;
    
    END;
  EXIT WHEN v_error_code < 0;
  END LOOP;
  
  FOR n in 1..nloop_eng_mx LOOP
    BEGIN
    /*
		select TC_CLOB_ENG into v_clob_eng from T_TC_DOC 
		where TC_DATE = P_TC_DATE
		AND TC_ID = P_TC_ID
		AND TC_REV = P_TC_REV
    AND TC_TYPE = 'CONGEN'
    AND TC_STATUS = -1
		for update;
    --dbms_lob.open(v_clob_eng,dbms_lob.lob_readwrite);
		dbms_lob.write(v_clob_eng,length(P_TC_CLOB_ENG), 1,P_TC_CLOB_ENG);
    --dbms_lob.close(v_clob_eng);
    */
      UPDATE T_TC_DOC SET TC_MATRIX_ENG = TC_MATRIX_ENG||SUBSTR(P_TC_MATRIX_ENG,((n-1)*4000+i),4000)
      WHERE TC_DATE = P_TC_DATE
      AND TC_ID = P_TC_ID
      AND TC_REV = P_TC_REV
      AND TC_TYPE = 'CONGEN'
      AND TC_STATUS = -1;
    EXCEPTION
      WHEN OTHERS THEN
      v_error_code := -7;
      v_error_msg := SUBSTR('UPDATE CLOB eng into T_TC_DOC '||SQLERRM,1,200);
      RAISE v_err;
    
    END;
  EXIT WHEN v_error_code < 0;
  END LOOP;
  
  FOR n in 1..nloop_ind_mx LOOP
    BEGIN
    /*
		select TC_CLOB_IND into v_clob_ind from T_TC_DOC 
		where TC_DATE = P_TC_DATE
		AND TC_ID = P_TC_ID
		AND TC_REV = P_TC_REV
    AND TC_TYPE = 'CONGEN'
    AND TC_STATUS = -1
		for update;
    --dbms_lob.open(v_clob_ind,dbms_lob.lob_readwrite);
		dbms_lob.write(v_clob_ind,length(P_TC_CLOB_IND), 1,P_TC_CLOB_IND);
    --dbms_lob.close(v_clob_ind);
    */
      UPDATE T_TC_DOC SET TC_MATRIX_IND = TC_MATRIX_IND||SUBSTR(P_TC_MATRIX_IND,((n-1)*4000+i),4000)
      WHERE TC_DATE = P_TC_DATE
      AND TC_ID = P_TC_ID
      AND TC_REV = P_TC_REV
      AND TC_TYPE = 'CONGEN'
      AND TC_STATUS = -1;
    EXCEPTION
      WHEN OTHERS THEN
      v_error_code := -8;
      v_error_msg := SUBSTR('UPDATE CLOB ind into T_TC_DOC '||SQLERRM,1,200);
      RAISE v_err;
    
    END;
  EXIT WHEN v_error_code < 0;
  END LOOP; 
  
	P_ERROR_CODE := 1;
	P_ERROR_MSG := '';
  --COMMIT;
EXCEPTION
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
      
END;