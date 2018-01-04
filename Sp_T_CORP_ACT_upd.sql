create or replace PROCEDURE "SP_T_CORP_ACT_UPD"(
    P_SEARCH_STK_CD T_CORP_ACT.STK_CD%TYPE,
    P_SEARCH_CA_TYPE T_CORP_ACT.CA_TYPE%TYPE,
    P_SEARCH_X_DT T_CORP_ACT.X_DT%TYPE,
    P_STK_CD T_CORP_ACT.STK_CD%TYPE,
    P_CA_TYPE T_CORP_ACT.CA_TYPE%TYPE,
    P_STK_CD_MERGE T_CORP_ACT.STK_CD_MERGE%TYPE,
    P_CUM_DT T_CORP_ACT.CUM_DT%TYPE,
    P_X_DT T_CORP_ACT.X_DT%TYPE,
    P_RECORDING_DT T_CORP_ACT.RECORDING_DT%TYPE,
    P_DISTRIB_DT T_CORP_ACT.DISTRIB_DT%TYPE,
    P_FROM_QTY T_CORP_ACT.FROM_QTY%TYPE,
    P_TO_QTY T_CORP_ACT.TO_QTY%TYPE,
    P_CRE_DT T_CORP_ACT.CRE_DT%TYPE,
    P_USER_ID T_CORP_ACT.USER_ID%TYPE,
    P_RATE T_CORP_ACT.RATE%TYPE,
    P_ROUNDING T_CORP_ACT.ROUNDING%TYPE,
    P_ROUND_POINT T_CORP_ACT.ROUND_POINT%TYPE,
    P_UPD_DT T_CORP_ACT.UPD_DT%TYPE,
    P_UPD_BY T_CORP_ACT.UPD_BY%TYPE,
    P_UPD_STATUS T_TEMP_HEADER.STATUS%TYPE,
    p_ip_address T_TEMP_HEADER.IP_ADDRESS%TYPE,
    p_cancel_reason T_TEMP_HEADER.CANCEL_REASON%TYPE,
    p_error_code OUT NUMBER,
    p_error_msg OUT VARCHAR2)
IS
  v_err        EXCEPTION;
  v_error_code NUMBER;
  v_error_msg  VARCHAR2(1000) ;
  v_table_name T_TEMP_HEADER.table_name%TYPE := 'T_CORP_ACT';
  v_status T_TEMP_HEADER.status%TYPE;
  v_table_rowid T_TEMP_HEADER.table_rowid%TYPE;
  CURSOR csr_temp_detail
  IS
     SELECT   column_id, column_name AS field_name, DECODE(data_type, 'VARCHAR2', 'S', 'CHAR', 'S', 'NUMBER', 'N', 'DATE', 'D', 'X') AS field_type
         FROM all_tab_columns
        WHERE table_name = v_table_name
        AND OWNER        = 'IPNEXTG';
  CURSOR csr_table
  IS
     SELECT   *
         FROM T_CORP_ACT
        WHERE STK_CD = p_search_STK_CD
        AND CA_TYPE  = p_search_CA_TYPE
        AND X_DT     = p_search_X_DT;
  v_temp_detail Types.temp_detail_rc;
  v_rec T_CORP_ACT%ROWTYPE;
  v_cnt         INTEGER;
  i             INTEGER;
  V_FIELD_CNT   NUMBER;
  v_pending_cnt NUMBER;
  va            CHAR(1) := '@';
BEGIN

  IF P_UPD_STATUS       = 'I' AND(p_search_STK_CD <> p_STK_CD OR p_search_X_DT <> P_X_DT OR P_SEARCH_CA_TYPE <> P_CA_TYPE) THEN
    v_error_code       := - 2001;
    IF p_search_STK_CD <> p_STK_CD THEN
      v_error_msg      := 'jika INSERT, p_search_STK_CD harus sama dengan P_STK_CD';
    END IF;
    
    IF p_search_CA_TYPE <> p_CA_TYPE THEN
      v_error_msg       := 'jika INSERT, p_search_CA_TYPE harus sama dengan P_CA_TYPE';
    END IF;
    
    IF p_search_X_DT <> p_X_DT THEN
      v_error_msg    := 'jika INSERT, p_search_X_DT harus sama dengan P_X_DT';
    END IF;
    RAISE v_err;
  END IF;
  
  BEGIN
     SELECT   ROWID
         INTO v_table_rowid
         FROM T_CORP_ACT
        WHERE STK_CD = p_search_STK_CD
        AND CA_TYPE  = P_SEARCH_CA_TYPE
        AND X_DT     = p_search_X_DT;
  EXCEPTION
  WHEN NO_DATA_FOUND THEN
    v_table_rowid := NULL;
  WHEN OTHERS THEN
    v_error_code := - 2;
    v_error_msg  := SUBSTR('Retrieve  '|| v_table_name||' for '||p_search_STK_CD||SQLERRM, 1, 200) ;
    RAISE v_err;
  END;
  
  IF P_UPD_STATUS = 'I' AND v_table_rowid IS NOT NULL THEN
    v_error_code := - 2001;
    v_error_msg  := 'DUPLICATED STOCK CODE, CA_TYPE AND X DATE';
    RAISE v_err;
  END IF;
  
  IF P_UPD_STATUS = 'U' AND(p_search_STK_CD <> P_STK_CD OR P_SEARCH_CA_TYPE <> P_CA_TYPE OR p_search_X_DT <> P_X_DT) THEN
    BEGIN
       SELECT   COUNT(1)
           INTO v_cnt
           FROM T_CORP_ACT
          WHERE STK_CD = p_STK_CD
          AND ca_type  = p_ca_type
          AND X_DT     = p_X_DT;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      v_cnt := 0;
    WHEN OTHERS THEN
      v_error_code := - 3;
      v_error_msg  := SUBSTR('Retrieve  '|| v_table_name||' for '||p_search_STK_CD||SQLERRM, 1, 200) ;
      RAISE v_err;
    END;
    
    IF v_cnt        > 0 THEN
      v_error_code := - 2003;
      v_error_msg  := 'DUPLICATED STOCK CODE AND X DATE';
      RAISE v_err;
    END IF;
    
  END IF;
  
  IF v_table_rowid IS NULL THEN
    BEGIN
       SELECT   COUNT(1)
           INTO v_pending_cnt
           FROM
          (
             SELECT   MAX(STK_CD) STK_CD, MAX(CA_TYPE) CA_TYPE, MAX(X_DT) X_DT
                 FROM
                (
                   SELECT   DECODE(field_name, 'STK_CD', field_value, NULL) STK_CD, DECODE(field_name, 'CA_TYPE', field_value, NULL) CA_TYPE, DECODE(field_name, 'X_DT', field_value, NULL) X_DT
                       FROM T_TEMP_DETAIL D, T_TEMP_HEADER H
                      WHERE h.table_name    = v_table_name
                      AND d.update_date     = h.update_date
                      AND d.update_seq      = h.update_seq
                      AND d.table_name      = h.table_name
                      AND(d.field_name      = 'STK_CD'
                      OR d.field_name       = 'CA_TYPE'
                      OR d.field_name       = 'X_DT')
                      AND h.APPROVED_status = 'E'
                )
          )
          WHERE STK_CD = p_search_STK_CD
          AND CA_TYPE  = p_search_CA_TYPE
          AND X_DT     = p_search_X_DT;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      v_pending_cnt := 0;
    WHEN OTHERS THEN
      v_error_code := - 4;
      v_error_msg  := SUBSTR('Retrieve T_TEMP_HEADER for '|| v_table_name||SQLERRM, 1, 200) ;
      RAISE v_err;
    END;
    
  ELSE
  
    BEGIN
       SELECT   COUNT(1)
           INTO v_pending_cnt
           FROM T_TEMP_HEADER H
          WHERE h.table_name     = v_table_name
          AND h.table_rowid      = v_table_rowid
          AND h.APPROVED_status <> 'A'
          AND h.APPROVED_status <> 'R';
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      v_pending_cnt := 0;
    WHEN OTHERS THEN
      v_error_code := - 5;
      v_error_msg  := SUBSTR('Retrieve T_TEMP_HEADER for '|| v_table_name||SQLERRM, 1, 200) ;
      RAISE v_err;
    END;
    
  END IF;
  
  IF v_pending_cnt > 0 THEN
    v_error_code  := - 6;
    v_error_msg   := 'Masih ada yang belum di-approve';
    RAISE v_err;
  END IF;
  
  OPEN csr_Table;
  FETCH csr_Table
       INTO v_rec;
  OPEN v_Temp_detail FOR SELECT update_date,
  table_name,  0 update_seq,  a.field_name,  field_type,  b.field_value,  a.column_id,  b.upd_flg FROM
  (
     SELECT   SYSDATE AS update_date, v_table_name AS table_name, column_id, column_name AS field_name, DECODE(data_type, 'VARCHAR2', 'S', 'CHAR', 'S', 'NUMBER', 'N', 'DATE', 'D', 'X') AS field_type
         FROM all_tab_columns
        WHERE table_name = v_table_name
        AND OWNER        = 'IPNEXTG'
  )
  a,(
     SELECT 'STK_CD' AS field_name, p_STK_CD AS field_value, DECODE(trim(v_rec.STK_CD), trim(p_STK_CD), 'N', 'Y') upd_flg  FROM dual
      UNION
     SELECT 'CA_TYPE' AS field_name, p_CA_TYPE AS field_value, DECODE(trim(v_rec.CA_TYPE), trim(p_CA_TYPE), 'N', 'Y') upd_flg   FROM dual
      UNION
     SELECT 'STK_CD_MERGE' AS field_name, P_STK_CD_MERGE AS field_value, DECODE(trim(v_rec.STK_CD_MERGE), trim(P_STK_CD_MERGE), 'N', 'Y') upd_flg    FROM dual
      UNION
     SELECT 'CUM_DT' AS field_name, TO_CHAR(p_CUM_DT, 'yyyy/mm/dd hh24:mi:ss') AS field_value, DECODE(v_rec.CUM_DT, p_CUM_DT, 'N', 'Y') upd_flg FROM dual
      UNION
     SELECT 'X_DT' AS field_name, TO_CHAR(p_X_DT, 'yyyy/mm/dd hh24:mi:ss') AS field_value, DECODE(v_rec.X_DT, p_X_DT, 'N', 'Y') upd_flg  FROM dual
      UNION
     SELECT 'RECORDING_DT' AS field_name, TO_CHAR(p_RECORDING_DT, 'yyyy/mm/dd hh24:mi:ss') AS field_value, DECODE(v_rec.RECORDING_DT, p_RECORDING_DT, 'N', 'Y') upd_flg   FROM dual
      UNION
     SELECT 'DISTRIB_DT' AS field_name, TO_CHAR(p_DISTRIB_DT, 'yyyy/mm/dd hh24:mi:ss') AS field_value, DECODE(v_rec.DISTRIB_DT, p_DISTRIB_DT, 'N', 'Y') upd_flg    FROM dual
      UNION
     SELECT 'FROM_QTY' AS field_name, TO_CHAR(p_FROM_QTY) AS field_value, DECODE(v_rec.FROM_QTY, p_FROM_QTY, 'N', 'Y') upd_flg      FROM dual
      UNION
     SELECT 'TO_QTY' AS field_name, TO_CHAR(p_TO_QTY) AS field_value, DECODE(v_rec.TO_QTY, p_TO_QTY, 'N', 'Y') upd_flg      FROM dual
      UNION
     SELECT 'CRE_DT' AS field_name, TO_CHAR(SYSDATE, 'yyyy/mm/dd hh24:mi:ss') AS field_value, 'Y' upd_flg      FROM dual   WHERE P_UPD_STATUS = 'I'
      UNION
     SELECT 'USER_ID' AS field_name, p_USER_ID AS field_value, 'Y' upd_flg       FROM dual
        WHERE P_UPD_STATUS = 'I'
      UNION
     SELECT 'RATE' AS field_name, TO_CHAR(p_RATE) AS field_value, DECODE(v_rec.RATE, p_RATE, 'N', 'Y') upd_flg      FROM dual
      UNION
      SELECT 'ROUNDING' AS field_name, TO_CHAR(P_ROUNDING) AS field_value, DECODE(v_rec.ROUNDING, P_ROUNDING, 'N', 'Y') upd_flg      FROM dual
      UNION
      SELECT 'ROUND_POINT' AS field_name, TO_CHAR(P_ROUND_POINT) AS field_value, DECODE(v_rec.ROUND_POINT, P_ROUND_POINT, 'N', 'Y') upd_flg      FROM dual
      UNION
     SELECT 'UPD_DT' AS field_name, TO_CHAR(SYSDATE, 'yyyy/mm/dd hh24:mi:ss') AS field_value, 'Y' upd_flg  FROM dual     WHERE P_UPD_STATUS = 'U'
      UNION
     SELECT 'UPD_BY' AS field_name, p_USER_ID AS field_value, 'Y' upd_flg     FROM dual
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
    Sp_T_Temp_Insert(v_table_name, v_table_rowid, v_status, p_user_id, p_ip_address, p_cancel_reason, v_temp_detail, v_error_code, v_error_msg) ;
  EXCEPTION
  WHEN OTHERS THEN
    v_error_code := - 7;
    v_error_msg  := SUBSTR('SP_T_TEMP_INSERT '||v_table_name||SQLERRM, 1, 200) ;
    RAISE v_err;
  END;
  
  CLOSE v_Temp_detail;
  CLOSE csr_Table;
  
  IF v_error_code < 0 THEN
    v_error_code := - 8;
    v_error_msg  := 'SP_T_TEMP_INSERT '||v_table_name||' '||v_error_msg;
    RAISE v_err;
  END IF;
  
  p_error_code := 1;
  p_error_msg  := '';
  
EXCEPTION
WHEN NO_DATA_FOUND THEN
  NULL;
WHEN v_err THEN
  p_error_code := v_error_code;
  p_error_msg  := v_error_msg;
  ROLLBACK;
WHEN OTHERS THEN
  -- Consider logging the error and then re-raise
  ROLLBACK;
  p_error_code := - 1;
  p_error_msg  := SUBSTR(SQLERRM, 1, 200) ;
  RAISE;
END Sp_T_CORP_ACT_upd;