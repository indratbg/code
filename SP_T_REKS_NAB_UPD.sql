CREATE OR REPLACE PROCEDURE "SP_T_REKS_NAB_UPD"(
    P_SEARCH_REKS_CD T_REKS_NAB.REKS_CD%TYPE,
    P_SEARCH_NAB_DATE T_REKS_NAB.NAB_DATE%TYPE,
    P_SEARCH_SEQNO T_REKS_NAB.SEQNO%TYPE,
    P_REKS_CD T_REKS_NAB.REKS_CD%TYPE,
    P_NAB_DATE T_REKS_NAB.NAB_DATE%TYPE,
    P_NAB_UNIT T_REKS_NAB.NAB_UNIT%TYPE,
    P_NAB T_REKS_NAB.NAB%TYPE,
    P_USER_ID T_REKS_NAB.USER_ID%TYPE,
    P_CRE_DT T_REKS_NAB.CRE_DT%TYPE,
    P_MKBD_DT T_REKS_NAB.MKBD_DT%TYPE,
    P_UPD_BY T_REKS_NAB.UPD_BY%TYPE,
    P_UPD_DT T_REKS_NAB.UPD_DT%TYPE,
    P_UPD_STATUS T_TEMP_HEADER.STATUS%TYPE,
    p_ip_address T_TEMP_HEADER.IP_ADDRESS%TYPE,
    p_cancel_reason T_TEMP_HEADER.CANCEL_REASON%TYPE,
    p_error_code OUT NUMBER,
    p_error_msg OUT VARCHAR2 )
IS
  v_err        EXCEPTION;
  v_error_code NUMBER;
  v_error_msg  VARCHAR2(1000);
  v_table_name T_TEMP_HEADER.table_name%TYPE := 'T_REKS_NAB';
  v_status T_TEMP_HEADER.status%TYPE;
  v_table_rowid T_TEMP_HEADER.table_rowid%TYPE;
  
  CURSOR csr_temp_detail
  IS
    SELECT column_id, column_name AS field_name, 
    DECODE(data_type,'VARCHAR2','S','CHAR','S','NUMBER','N','DATE','D','X') AS field_type
    FROM all_tab_columns
    WHERE table_name =v_table_name
    AND OWNER        = 'IPNEXTG';
  CURSOR csr_table
  IS
    SELECT *
    FROM T_REKS_NAB
    WHERE REKS_CD = p_search_REKS_CD
    AND NAB_DATE  = p_search_NAB_DATE
    AND SEQNO     =P_SEARCH_SEQNO;
    
  v_temp_detail Types.temp_detail_rc;
  v_rec T_REKS_NAB%ROWTYPE;
  v_cnt         INTEGER;
  i             INTEGER;
  V_FIELD_CNT   NUMBER;
  v_pending_cnt NUMBER;
  va            CHAR(1) := '@';
  V_SEQNO       NUMBER;
  
BEGIN
    
      IF P_UPD_STATUS='I' THEN
        BEGIN
          SELECT SEQ_BERSAMA.NEXTVAL INTO V_SEQNO FROM DUAL WHERE P_UPD_STATUS='I';
        EXCEPTION
        WHEN OTHERS THEN
          V_ERROR_CODE := -5;
          V_ERROR_MSG  := SUBSTR('SELECT SEQ_BERSAMA '|| SQLERRM,1,200);
          RAISE V_ERR;
        END;
      END IF;
      
      IF P_UPD_STATUS        = 'I' AND (p_search_REKS_CD <> p_REKS_CD OR P_Search_Nab_Date <> P_NAB_DATE) THEN
        v_error_code        := -2001;
        IF p_search_REKS_CD <> p_REKS_CD THEN
          v_error_msg       := 'jika INSERT, p_search_REKS_CD harus sama dengan P_REKS_CD';
        END IF;
        IF P_Search_Nab_Date <> P_NAB_DATE THEN
          v_error_msg        := 'jika INSERT, P_Search_Nab_Date harus sama dengan P_NAB_DATE';
        END IF;
        RAISE v_err;
      END IF;
      
      
      BEGIN
        SELECT ROWID INTO v_table_rowid  FROM T_REKS_NAB
        WHERE REKS_CD = p_search_REKS_CD
        AND NAB_DATE  = p_search_NAB_DATE
        AND SEQNO     =P_SEARCH_SEQNO;
      EXCEPTION
      WHEN NO_DATA_FOUND THEN
          v_table_rowid := NULL;
      WHEN OTHERS THEN
          v_error_code := -2;
          v_error_msg  := SUBSTR('Retrieve  '|| v_table_name||' for '||p_search_REKS_CD||SQLERRM,1,200);
          RAISE v_err;
      END;
      
      IF P_UPD_STATUS = 'I' AND v_table_rowid IS NOT NULL THEN
          v_error_code := -2001;
          v_error_msg  := 'DUPLICATED REKS CODE AND NAB DATE AND SEQNO';
          RAISE v_err;
      END IF;
      
      IF P_UPD_STATUS ='I' THEN
      
            BEGIN
              SELECT COUNT(1)
              INTO V_CNT
              FROM T_REKS_NAB
              WHERE NAB_DATE   =P_SEARCH_NAB_DATE
              AND REKS_CD      =P_SEARCH_REKS_CD
              AND MKBD_DT      =P_MKBD_DT
              AND APPROVED_STAT='A';
            EXCEPTION
            WHEN OTHERS THEN
              V_ERROR_CODE := -5;
              V_ERROR_MSG  := SUBSTR('SELECT COUNT REKS_CD'||P_SEARCH_REKS_CD||'NAB DATE '||P_SEARCH_NAB_DATE|| SQLERRM,1,200);
              RAISE V_ERR;
            END;
            
      ELSIF P_UPD_STATUS='U' AND (P_SEARCH_REKS_CD<>P_REKS_CD OR P_SEARCH_NAB_DATE <> P_NAB_DATE) THEN
      
            BEGIN
              SELECT COUNT(1)
              INTO V_CNT
              FROM T_REKS_NAB
              WHERE NAB_DATE   =P_NAB_DATE
              AND REKS_CD      =P_REKS_CD
              AND MKBD_DT      =P_MKBD_DT
              AND APPROVED_STAT='A';
            EXCEPTION
            WHEN OTHERS THEN
              V_ERROR_CODE := -90;
              V_ERROR_MSG  := SUBSTR('SELECT COUNT REKS_CD'||P_SEARCH_REKS_CD||'NAB DATE '||P_SEARCH_NAB_DATE|| SQLERRM,1,200);
              RAISE V_ERR;
            END;
            
      END IF;
      
      IF V_CNT        >0 THEN
        V_ERROR_CODE := -10;
        V_ERROR_MSG  := 'Data sudah ada untuk mkbd date '||p_mkbd_dt;
        RAISE V_ERR;
      END IF;
      
      
      IF v_table_rowid IS NULL THEN
            BEGIN
              SELECT COUNT(1) INTO v_pending_cnt FROM
                (
                  SELECT MAX(REKS_CD) REKS_CD, MAX(MKBD_DT) MKBD_DT,MAX(NAB_DATE) NAB_DATE
                  FROM
                    (
                      SELECT DECODE (field_name, 'REKS_CD', field_value, NULL) REKS_CD, 
                      DECODE (field_name, 'NAB_DATE', field_value, NULL) NAB_DATE, 
                      DECODE (field_name, 'MKBD_DT', field_value, NULL) MKBD_DT, 
                      h.update_seq
                      FROM T_TEMP_DETAIL D, T_TEMP_HEADER H
                      WHERE h.table_name    = v_table_name
                      AND d.update_date     = h.update_date
                      AND d.update_seq      = h.update_seq
                      AND d.table_name      = h.table_name
                      AND d.field_name     IN ('REKS_CD','NAB_DATE','MKBD_DT')
                      AND h.APPROVED_status = 'E'
                    )
                  GROUP BY update_seq
                )
              WHERE REKS_CD = p_search_REKS_CD
              AND NAB_DATE  = p_SEARCH_NAB_DATE
              AND MKBD_DT   = p_MKBD_DT;
            EXCEPTION
            WHEN NO_DATA_FOUND THEN
              v_pending_cnt := 0;
            WHEN OTHERS THEN
              v_error_code := -4;
              v_error_msg  := SUBSTR('Retrieve T_TEMP_HEADER for '|| v_table_name||SQLERRM,1,200);
              RAISE v_err;
            END;
        
      ELSE
          
            BEGIN
              SELECT COUNT(1)
              INTO v_pending_cnt
              FROM T_TEMP_HEADER H
              WHERE h.table_name     = v_table_name
              AND h.table_rowid      = v_table_rowid
              AND h.APPROVED_status <> 'A'
              AND h.APPROVED_status <>'R';
            EXCEPTION
            WHEN NO_DATA_FOUND THEN
              v_pending_cnt := 0;
            WHEN OTHERS THEN
              v_error_code := -5;
              v_error_msg  := SUBSTR('Retrieve T_TEMP_HEADER for '|| v_table_name||SQLERRM,1,200);
              RAISE v_err;
            END;
      END IF;
      
      
      IF v_pending_cnt > 0 THEN
        v_error_code  := -6;
        v_error_msg   := 'Masih ada yang belum di-approve';
        RAISE v_err;
      END IF;
      
      OPEN csr_Table;
      
      FETCH csr_Table  INTO v_rec;
      OPEN v_Temp_detail FOR SELECT update_date, table_name,  0 update_seq, a.field_name, field_type, b.field_value, a.column_id, b.upd_flg FROM
      (
        SELECT SYSDATE AS update_date, v_table_name AS table_name, column_id, column_name AS field_name, 
        DECODE(data_type,'VARCHAR2','S','CHAR','S','NUMBER','N','DATE','D','X') AS field_type
        FROM all_tab_columns
        WHERE table_name = v_table_name
        AND OWNER        = 'IPNEXTG'
      )
      a, (
        SELECT 'REKS_CD' AS field_name, p_REKS_CD AS field_value, DECODE(trim(v_rec.REKS_CD), trim(p_REKS_CD),'N','Y') upd_flg
        FROM dual
        UNION
        SELECT 'NAB_DATE' AS field_name, TO_CHAR(p_NAB_DATE,'yyyy/mm/dd hh24:mi:ss') AS field_value, DECODE(v_rec.NAB_DATE, p_NAB_DATE,'N','Y') upd_flg
        FROM dual
        UNION
        SELECT 'NAB_UNIT' AS field_name, TO_CHAR(p_NAB_UNIT) AS field_value, DECODE(v_rec.NAB_UNIT, p_NAB_UNIT,'N','Y') upd_flg
        FROM dual
        UNION
        SELECT 'NAB' AS field_name, TO_CHAR(p_NAB) AS field_value, DECODE(v_rec.NAB, p_NAB,'N','Y') upd_flg
        FROM dual
        UNION
        SELECT 'USER_ID' AS field_name, p_USER_ID AS field_value, DECODE(trim(v_rec.USER_ID), trim(p_USER_ID),'N','Y') upd_flg
        FROM dual
        WHERE P_UPD_STATUS='I'
        UNION
        SELECT 'CRE_DT' AS field_name, TO_CHAR(p_CRE_DT,'yyyy/mm/dd hh24:mi:ss') AS field_value, DECODE(v_rec.CRE_DT, p_CRE_DT,'N','Y') upd_flg
        FROM dual
        WHERE P_UPD_STATUS='I'
        UNION
        SELECT 'MKBD_DT' AS field_name, TO_CHAR(p_MKBD_DT,'yyyy/mm/dd hh24:mi:ss') AS field_value, DECODE(v_rec.MKBD_DT, p_MKBD_DT,'N','Y') upd_flg
        FROM dual
        UNION
        SELECT 'UPD_BY' AS field_name, p_UPD_BY AS field_value, DECODE(trim(v_rec.UPD_BY), trim(p_UPD_BY),'N','Y') upd_flg
        FROM dual
        WHERE P_UPD_STATUS='U'
        UNION
        SELECT 'UPD_DT' AS field_name, TO_CHAR(p_UPD_DT,'yyyy/mm/dd hh24:mi:ss') AS field_value, DECODE(v_rec.UPD_DT, p_UPD_DT,'N','Y') upd_flg
        FROM dual
        WHERE P_UPD_STATUS='U'
        UNION
        SELECT 'SEQNO' AS field_name, TO_CHAR(V_SEQNO) AS field_value, 'Y' upd_flg
        FROM dual
        WHERE P_UPD_STATUS='I'
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
        v_error_code := -7;
        v_error_msg  := SUBSTR('SP_T_TEMP_INSERT '||v_table_name||SQLERRM,1,200);
        RAISE v_err;
      END;
      
      CLOSE v_Temp_detail;
      CLOSE csr_Table;
      
      IF v_error_code < 0 THEN
        v_error_code := -8;
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
  p_error_code := -1;
  p_error_msg  := SUBSTR(SQLERRM,1,200);
  RAISE;
END Sp_T_REKS_NAB_Upd;