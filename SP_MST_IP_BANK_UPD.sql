create or replace PROCEDURE SP_MST_IP_BANK_UPD(
    P_SEARCH_BANK_CD MST_IP_BANK.BANK_CD%TYPE,
    P_BANK_CD MST_IP_BANK.BANK_CD%TYPE,
    P_BI_CODE MST_IP_BANK.BI_CODE%TYPE,
    P_BANK_SHORT_NAME MST_IP_BANK.BANK_SHORT_NAME%TYPE,
    P_BANK_NAME MST_IP_BANK.BANK_NAME%TYPE,
    P_CRE_DT MST_IP_BANK.CRE_DT%TYPE,
    P_USER_ID MST_IP_BANK.USER_ID%TYPE,
    P_UPD_DT MST_IP_BANK.UPD_DT%TYPE,
    P_UPD_BY MST_IP_BANK.UPD_BY%TYPE,
    P_UPD_STATUS T_TEMP_HEADER.STATUS%TYPE,
    p_ip_address T_TEMP_HEADER.IP_ADDRESS%TYPE,
    p_cancel_reason T_TEMP_HEADER.CANCEL_REASON%TYPE,
    p_error_code OUT NUMBER,
    p_error_msg OUT VARCHAR2 )
IS
  v_err        EXCEPTION;
  v_error_code NUMBER;
  v_error_msg  VARCHAR2(200);
  v_table_name T_TEMP_HEADER.table_name%TYPE := 'MST_IP_BANK';
  v_status T_TEMP_HEADER.status%TYPE;
  v_table_rowid T_TEMP_HEADER.table_rowid%TYPE;
  CURSOR csr_temp_detail
  IS
    SELECT column_id, column_name AS field_name, DECODE(data_type,'VARCHAR2','S','CHAR','S','NUMBER','N','DATE','D','X') AS field_type
    FROM all_tab_columns
    WHERE table_name =v_table_name
    AND OWNER        = 'IPNEXTG';
  CURSOR csr_table
  IS
    SELECT * FROM MST_IP_BANK WHERE BANK_CD = P_SEARCH_BANK_CD;
  v_temp_detail Types.temp_detail_rc;
  v_rec MST_IP_BANK%ROWTYPE;
  v_cnt         INTEGER;
  i             INTEGER;
  V_FIELD_CNT   NUMBER;
  v_pending_cnt NUMBER;
  va            CHAR(1) := '@';
BEGIN
  IF P_UPD_STATUS = 'I' AND P_SEARCH_BANK_CD <> P_BANK_CD THEN
    v_error_code := -2001;
    v_error_msg  := 'jika INSERT, P_SEARCH_BANK_CD harus sama dengan P_BANK_CD';
    RAISE v_err;
  END IF;
  BEGIN
    SELECT ROWID
    INTO v_table_rowid
    FROM MST_IP_BANK
    WHERE BANK_CD = P_SEARCH_BANK_CD;
  EXCEPTION
  WHEN NO_DATA_FOUND THEN
    v_table_rowid := NULL;
  WHEN OTHERS THEN
    v_error_code := -3;
    v_error_msg  := SUBSTR('Retrieve  '|| v_table_name||' for '||P_SEARCH_BANK_CD||SQLERRM,1,200);
    RAISE v_err;
  END;
  IF P_UPD_STATUS = 'I' AND v_table_rowid IS NOT NULL THEN
    v_error_code := -2002;
    v_error_msg  := 'DUPLICATED BANK CODE';
    RAISE v_err;
  END IF;
  
  IF P_UPD_STATUS = 'U' AND P_SEARCH_BANK_CD <> P_BANK_CD THEN
    BEGIN
      SELECT COUNT(1) INTO v_cnt FROM MST_IP_BANK WHERE BANK_CD = P_BANK_CD;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      v_cnt := 0;
    WHEN OTHERS THEN
      v_error_code := -3;
      v_error_msg  := SUBSTR('Retrieve  '|| v_table_name||' for '||P_BANK_CD||SQLERRM,1,200);
      RAISE v_err;
    END;
    IF v_cnt        > 0 THEN
      v_error_code := -2003;
      v_error_msg  := 'DUPLICATED BANK CODE';
      RAISE v_err;
    END IF;
  END IF;
  
  IF v_table_rowid IS NULL THEN
    BEGIN
      SELECT COUNT(1)
      INTO v_pending_cnt
      FROM T_TEMP_DETAIL D, T_TEMP_HEADER H
      WHERE h.table_name    = v_table_name
      AND d.update_date     = h.update_date
      AND d.update_seq      =h.update_seq
      AND d.table_name      = h.table_name
      AND d.field_name      = 'BANK_CD'
      AND d.field_value     = P_SEARCH_BANK_CD
      AND h.APPROVED_status = 'E';
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      v_pending_cnt := 0;
    WHEN OTHERS THEN
      v_error_code := -2;
      v_error_msg  := SUBSTR('Retrieve T_TEMP_HEADER for '|| v_table_name||SQLERRM,1,200);
      RAISE v_err;
    END;
    
  ELSE
  
    BEGIN
      SELECT COUNT(1)
      INTO v_pending_cnt
      FROM T_TEMP_HEADER H
      WHERE h.table_name    = v_table_name
      AND h.table_rowid     = v_table_rowid
      AND h.APPROVED_status = 'E';
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      v_pending_cnt := 0;
    WHEN OTHERS THEN
      v_error_code := -4;
      v_error_msg  := SUBSTR('Retrieve T_TEMP_HEADER for '|| v_table_name||SQLERRM,1,200);
      RAISE v_err;
    END;
    
  END IF;
  
  IF v_pending_cnt > 0 THEN
    v_error_code  := -5;
    v_error_msg   := 'Masih ada yang belum di-approve';
    RAISE v_err;
  END IF;
  
  OPEN csr_Table;
  FETCH csr_Table
  INTO v_rec;
  OPEN v_Temp_detail FOR SELECT update_date, table_name,  0 update_seq,  a.field_name,  field_type,  b.field_value,  a.column_id,  b.upd_flg FROM
  (
    SELECT SYSDATE AS update_date, v_table_name AS table_name, column_id, column_name AS field_name, DECODE(data_type,'VARCHAR2','S','CHAR','S','NUMBER','N','DATE','D','X') AS field_type
    FROM all_tab_columns
    WHERE table_name =v_table_name
    AND OWNER        = 'IPNEXTG'
  )
  a, (
    SELECT 'BANK_CD' AS field_name, p_BANK_CD AS field_value, DECODE(trim(v_rec.BANK_CD), trim(p_BANK_CD),'N','Y') upd_flg
    FROM dual
    UNION
    SELECT 'BI_CODE' AS field_name, p_BI_CODE AS field_value, DECODE(trim(v_rec.BI_CODE), trim(p_BI_CODE),'N','Y') upd_flg
    FROM dual
    UNION
    SELECT 'BANK_SHORT_NAME' AS field_name, p_BANK_SHORT_NAME AS field_value, DECODE(trim(v_rec.BANK_SHORT_NAME), trim(p_BANK_SHORT_NAME),'N','Y') upd_flg
    FROM dual
    UNION
    SELECT 'BANK_NAME' AS field_name, p_BANK_NAME AS field_value, DECODE(trim(v_rec.BANK_NAME), trim(p_BANK_NAME),'N','Y') upd_flg
    FROM dual
    UNION
    SELECT 'CRE_DT' AS field_name, TO_CHAR(p_CRE_DT,'yyyy/mm/dd hh24:mi:ss') AS field_value, DECODE(v_rec.CRE_DT, p_CRE_DT,'N','Y') upd_flg
    FROM dual
    WHERE P_UPD_STATUS = 'I'
    UNION
    SELECT 'USER_ID' AS field_name, p_USER_ID AS field_value, DECODE(trim(v_rec.USER_ID), trim(p_USER_ID),'N','Y') upd_flg
    FROM dual
    WHERE P_UPD_STATUS = 'I'
    UNION
    SELECT 'UPD_DT' AS field_name, TO_CHAR(p_UPD_DT,'yyyy/mm/dd hh24:mi:ss') AS field_value, DECODE(v_rec.UPD_DT, p_UPD_DT,'N','Y') upd_flg
    FROM dual
    WHERE P_UPD_STATUS = 'U'
    UNION
    SELECT 'UPD_BY' AS field_name, p_UPD_BY AS field_value, DECODE(trim(v_rec.UPD_BY), trim(p_UPD_BY),'N','Y') upd_flg
    FROM dual
    WHERE P_UPD_STATUS = 'U'
    UNION
    SELECT 'UPD_BY' AS field_name, p_USER_ID AS field_value, 'Y' upd_flg
    FROM dual
    WHERE P_UPD_STATUS = 'U'
  )
  b WHERE a.field_name = b.field_name AND P_UPD_STATUS <> 'C';
  
  IF v_table_rowid    IS NOT NULL THEN
    IF P_UPD_STATUS    = 'C' THEN
      v_status        := 'C';
    ELSE
      v_status := 'U';
    END IF;
  ELSE
    v_status := 'I';
  END IF;
  
  BEGIN
    Sp_T_Temp_Insert(v_table_name, v_table_rowid, v_status,p_user_id, p_ip_address , p_cancel_reason, v_temp_detail, v_error_code, v_error_msg);
  EXCEPTION
  WHEN OTHERS THEN
    v_error_code := -6;
    v_error_msg  := SUBSTR('SP_T_TEMP_INSERT '||v_table_name||SQLERRM,1,200);
    RAISE v_err;
  END;
  
  CLOSE v_Temp_detail;
  CLOSE csr_Table;
  
  IF v_error_code < 0 THEN
    --v_error_code := -7;
    v_error_msg  := 'SP_T_TEMP_INSERT '||v_table_name||' '||v_error_code||' '||v_error_msg;
    RAISE v_err;
  END IF;
  
  p_error_code := 1;
  p_error_msg  := '';
  
EXCEPTION
WHEN NO_DATA_FOUND THEN
  NULL;
WHEN v_err THEN
  ROLLBACK;
  p_error_code := v_error_code;
  p_error_msg  := v_error_msg;
WHEN OTHERS THEN
  -- Consider logging the error and then re-raise
  ROLLBACK;
  p_error_code := -1;
  p_error_msg  := SUBSTR(SQLERRM(SQLCODE),1,200);
  RAISE;
END SP_MST_IP_BANK_UPD;