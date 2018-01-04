create or replace PROCEDURE SP_XML_BTS(
    p_xml_type   varchar2, --OTC
    p_id             varchar2,
    p_user_id R_XML.user_id%TYPE,
    p_menu_name R_XML.menu_name%TYPE, --OTC TUNAI
    p_random_value number,--14sep2017[indra] untuk mengambil data berdasarkan rand value dari tabel temp
    p_error_code OUT NUMBER,
    p_error_msg OUT VARCHAR2 )
IS
--[INDRA] 14-09-2017 select berdasarkan rand value dan user id dari tabel temp
CURSOR CSR_DATA IS
SELECT * FROM TMP_BTS where rand_value=p_random_value and user_id=p_user_id;

  CURSOR csr_column_name
  IS
    SELECT prm_cd_1 AS SDI_type, (prm_cd_2) seqno, prm_desc AS col_name, prm_desc2 AS cdata
    FROM mst_parameter
    WHERE prm_cd_1 = p_xml_type
    ORDER BY prm_cd_1, TO_NUMBER(prm_cd_2);
  v_xml R_XML.xml%TYPE;
  v_cnt        NUMBER;
  v_err        EXCEPTION;
  v_error_code NUMBER;
  v_error_msg  VARCHAR2(200);
  v_col_data   VARCHAR2(100);
  v_seqno      NUMBER(5);

BEGIN

  BEGIN
  DELETE FROM R_XML 
  WHERE MENU_NAME=p_menu_name
  and identifier = p_id
  and user_id = p_user_id;
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
        p_id, '<Message>', v_seqno, p_user_id, p_menu_name
      );
  EXCEPTION
  WHEN OTHERS THEN
    v_error_code := -3;
    v_error_msg  := SUBSTR('INSERT INTO R_XML '||SQLERRM,1,200);
    RAISE v_err;
  END;
  
   v_seqno := v_seqno + 1;
  
  

  
FOR VAL IN CSR_DATA LOOP

  BEGIN
    INSERT
    INTO R_XML
      (
        identifier, xml, seqno, user_id, menu_name
      )
      VALUES
      (
        p_id, '<Record name="data">', v_seqno, p_user_id, p_menu_name
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
      EXECUTE IMMEDIATE 'BEGIN SELECT COL'||TRIM(REC.SEQNO)||' INTO :v_col_data FROM TMP_BTS WHERE COL1='''||VAL.COL1||'''; END;' USING OUT v_col_data;
    EXCEPTION
    WHEN OTHERS THEN
      v_error_code := -13;
      v_error_msg  := SUBSTR('SELECT TMP_BTS '|| REC.col_name ||SQLERRM,1,200);
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
          p_id,v_xml,v_seqno,p_user_id,p_menu_name
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
        p_id, '</Record>', v_seqno, p_user_id, p_menu_name
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
        p_id, '</Message>', v_seqno, p_user_id, p_menu_name
      );
  EXCEPTION
  WHEN OTHERS THEN
    v_error_code := -41;
    v_error_msg  := SUBSTR('INSERT INTO R_XML '||SQLERRM,1,200);
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
END SP_XML_BTS;