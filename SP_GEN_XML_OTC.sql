create or replace PROCEDURE SP_GEN_XML_OTC(
    p_instruction_type VARCHAR2,--'SECTRS','DFOP','DVP','RFOP','RVP'
    P_DUE_DT           DATE,
    p_user_id R_XML.user_id%TYPE,
    p_menu_name R_XML.menu_name%TYPE, --OTC / SECTR / VCA
    p_error_code OUT NUMBER,
    p_error_msg OUT VARCHAR2 )
IS

  v_random_value NUMBER(10);

CURSOR CSR_DATA(A_RAND_VALUE NUMBER) IS
SELECT * FROM TMP_OTC WHERE RAND_VALUE=A_RAND_VALUE AND USER_ID=P_USER_ID; 

  CURSOR csr_column_name
  IS
    SELECT prm_cd_1 AS SDI_type, (prm_cd_2) seqno, prm_desc AS col_name, prm_desc2 AS cdata
    FROM mst_parameter
    WHERE prm_cd_1 = p_menu_name
    ORDER BY prm_cd_2;

  v_xml R_XML.xml%TYPE;
  v_cnt        NUMBER;
  v_err        EXCEPTION;
  v_error_code NUMBER;
  v_error_msg  VARCHAR2(200);
  v_col_data   VARCHAR2(100);
  v_seqno      NUMBER(5);

BEGIN
  v_random_value := ABS(dbms_random.random);
  
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
    SP_INSERT_TMP_OTC(p_instruction_type,P_DUE_DT ,p_menu_name,v_random_value, P_USER_ID, P_ERROR_CODE, P_ERROR_MSG);
  EXCEPTION
  WHEN OTHERS THEN
    v_error_code :=-10;
    v_error_msg  :=SUBSTR('CALL SP_INSERT_TMP_OTC '||SQLERRM,1,200);
    RAISE v_err;
  END;
  
  IF v_error_code <0 THEN
    v_error_code :=-15;
    v_error_msg  := SUBSTR('SP_INSERT_TMP_OTC '||v_error_msg,1,200);
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
      EXECUTE IMMEDIATE 'BEGIN SELECT COL'||TRIM(REC.SEQNO)||' INTO :v_col_data FROM TMP_OTC WHERE COL1='''||VAL.COL1||'''; END;' USING OUT v_col_data;
    EXCEPTION
    WHEN OTHERS THEN
      v_error_code := -13;
      v_error_msg  := SUBSTR('SELECT TMP_OTC '|| REC.col_name ||SQLERRM,1,200);
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
  


BEGIN
DELETE FROM TMP_OTC WHERE RAND_VALUE=V_RANDOM_VALUE AND USER_ID=P_USER_ID;
 EXCEPTION
    WHEN OTHERS THEN
      V_ERROR_CODE :=-50;
      V_ERROR_MSG  :=SUBSTR( 'DELETE TMP_OTC ' || SQLERRM,1,200);
      RAISE V_ERR;
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
END SP_GEN_XML_OTC;