create or replace PROCEDURE SP_GENXML_TOTCASHDIV(
    p_instruction_type VARCHAR2,--'WT'
    P_DISTRIB_DT           DATE,
    p_user_id R_XML.user_id%TYPE,
    p_menu_name R_XML.menu_name%TYPE, --'TRANSFER TOT CASH DIVIDEN'
    p_error_code OUT NUMBER,
    p_error_msg OUT VARCHAR2 )
IS

CURSOR CSR_DATA(A_RAND_VALUE NUMBER) IS
SELECT * FROM TMP_TOTCASHDIV WHERE RAND_VALUE=A_RAND_VALUE AND USER_ID=p_user_id;

  CURSOR csr_column_name
  IS
    SELECT prm_cd_1 AS SDI_type, (prm_cd_2) seqno, prm_desc AS col_name, prm_desc2 AS cdata
    FROM mst_parameter
    WHERE prm_cd_1 = p_instruction_type
    ORDER BY prm_cd_2;
    
  v_xml R_XML.xml%TYPE;
  v_cnt        NUMBER;
  v_err        EXCEPTION;
  v_error_code NUMBER;
  v_error_msg  VARCHAR2(200);
  v_col_data   VARCHAR2(100);
  v_seqno      NUMBER(5);
  V_RANDOM_VALUE NUMBER(10);
BEGIN

  V_RANDOM_VALUE :=ABS(DBMS_RANDOM.RANDOM);
  BEGIN
  DELETE FROM R_XML WHERE MENU_NAME=p_menu_name;
   EXCEPTION
    WHEN OTHERS THEN
      v_error_code := -2;
      v_error_msg  := SUBSTR('DELETE R_XML '||P_MENU_NAME||' '||SQLERRM,1,200);
      RAISE v_err;
    END;


  v_seqno := 1;
  
  BEGIN
    INSERT
    INTO R_XML
      (
        identifier, xml, seqno, user_id, menu_name
      )
      VALUES
      (
        p_instruction_type, '<Message>', v_seqno, p_user_id, p_menu_name
      );
  EXCEPTION
  WHEN OTHERS THEN
    v_error_code := -3;
    v_error_msg  := SUBSTR('INSERT INTO R_XML '||SQLERRM,1,200);
    RAISE v_err;
  END;
  
   v_seqno := v_seqno + 1;
  
  
  BEGIN
    SP_INSERT_TMP_TOTCASHDIV(p_instruction_type,P_DISTRIB_DT ,p_menu_name,V_RANDOM_VALUE,P_USER_ID, P_ERROR_CODE, P_ERROR_MSG);
  EXCEPTION
  WHEN OTHERS THEN
    v_error_code :=-10;
    v_error_msg  :=SUBSTR('CALL SP_INSERT_TMP_TOTCASHDIV '||SQLERRM,1,200);
    RAISE v_err;
  END;
  
  IF v_error_code <0 THEN
    v_error_code :=-15;
    v_error_msg  := SUBSTR('SP_INSERT_TMP_TOTCASHDIV '||v_error_msg,1,200);
    RAISE v_err;
  END IF;

  
FOR VAL IN CSR_DATA(V_RANDOM_VALUE) LOOP

  BEGIN
    INSERT
    INTO R_XML
      (
        identifier, xml, seqno, user_id, menu_name
      )
      VALUES
      (
        p_instruction_type, '<Record name="data">', v_seqno, p_user_id, p_menu_name
      );
  EXCEPTION
  WHEN OTHERS THEN
    v_error_code := -4;
    v_error_msg  := SUBSTR('INSERT INTO R_XML '||SQLERRM,1,200);
    RAISE v_err;
  END;
  
  v_seqno := v_seqno + 1;
  
  
  FOR REC IN csr_column_name
  LOOP
  
    BEGIN
      EXECUTE IMMEDIATE 'BEGIN SELECT COL'||TRIM(REC.SEQNO)||' INTO :v_col_data FROM TMP_TOTCASHDIV WHERE COL1='''||VAL.COL1||'''; END;' USING OUT v_col_data;
    EXCEPTION
    WHEN OTHERS THEN
      v_error_code := -13;
      v_error_msg  := SUBSTR('SELECT TMP_TOT_CASHDIV '|| REC.col_name ||SQLERRM,1,200);
      RAISE v_err;
    END;
    
    v_xml := '<Field name="'||REC.col_name||'">'||v_col_data||'</Field>';
    
    BEGIN
      INSERT
      INTO R_XML
        (
          identifier, xml, seqno, user_id, menu_name
        )
        VALUES
        (
          p_instruction_type,v_xml,v_seqno,p_user_id,p_menu_name
        );
    EXCEPTION
    WHEN OTHERS THEN
      v_error_code :=-30;
      v_error_msg  :=SUBSTR('INSERT INTO R_XML  '||SQLERRM,1,200);
      RAISE v_err;
    END;
    
    v_seqno := v_seqno + 1;
    
  END LOOP;
  
  BEGIN
    INSERT
    INTO R_XML
      (
        identifier, xml, seqno, user_id, menu_name
      )
      VALUES
      (
        p_instruction_type, '</Record>', v_seqno, p_user_id, p_menu_name
      );
  EXCEPTION
  WHEN OTHERS THEN
    v_error_code := -36;
    v_error_msg  := SUBSTR('INSERT INTO R_XML , '||SQLERRM,1,200);
    RAISE v_err;
  END;
  
    v_seqno := v_seqno + 1;
  END LOOP;--END LOOP FETCH CSR_DATA
  
  BEGIN
    INSERT
    INTO R_XML
      (
        identifier, xml, seqno, user_id, menu_name
      )
      VALUES
      (
        p_instruction_type, '</Message>', v_seqno, p_user_id, p_menu_name
      );
  EXCEPTION
  WHEN OTHERS THEN
    v_error_code := -41;
    v_error_msg  := SUBSTR('INSERT INTO R_XML '||SQLERRM,1,200);
    RAISE v_err;
  END;
  
  --DELETE TABLE TEMP
  BEGIN
  DELETE FROM TMP_TOTCASHDIV WHERE RAND_VALUE=V_RANDOM_VALUE AND USER_ID=P_USER_ID;
  EXCEPTION
  WHEN OTHERS THEN
    v_error_code := -50;
    v_error_msg  := SUBSTR('DELETE TABLE TMP_TOTCASHDIV'||SQLERRM,1,200);
    RAISE v_err;
  END;
  p_error_code := 1;
  p_error_msg  := '';
  
EXCEPTION
WHEN v_err THEN
  p_error_code := v_error_code;
  p_error_msg  := v_error_msg;
  ROLLBACK;
WHEN OTHERS THEN
  p_error_code := -1;
  p_error_msg  := SUBSTR(SQLERRM,1,200);
  ROLLBACK;
END SP_GENXML_TOTCASHDIV;