CREATE OR REPLACE FUNCTION Get_Docnum_Fund(
    p_tgl  IN DATE,
    p_mode IN CHAR)
  RETURN VARCHAR2
IS
  -- [indra] 07/09/2017 ubah sequence, create sequence per bulan supaya tidak unique constraint jika jurnal back dated
  -- 28apr15 cek ke t MANY detail  utk jurnal bln lalu
  -- parameter p_mode berisi R atau W atau E reversal
  v_doc_num T_FUND_MOVEMENT.doc_NUM%TYPE;
  v_mmyy T_FUND_MOVEMENT.doc_NUM%TYPE;
  vcounter  NUMBER(8) := 0;
  v_from_dt DATE;
  v_to_dt   DATE;
  PRAGMA autonomous_transaction;
  V_SEQ_NAME VARCHAR2(30);
  V_CNT      NUMBER;
  V_STR      VARCHAR2(200);
BEGIN
  -- Format : mmyyRF0000001  ( 7 digit)for Receipt Voucher Entry - masuk ke  dana client
  -- Format : mmyyWF0000001  for Withdraw Voucher Entry - keluar dr dana client
  -- EF = reversal
  
  V_SEQ_NAME :='SEQ_JUR_FUND'||TO_CHAR(p_tgl,'MMYY');
  v_doc_num  := trim(TO_CHAR(p_tgl,'mmyy')||p_mode)||'F';
  v_mmyy     := TO_CHAR(P_TGL,'MMYY')||'%';
  
  BEGIN
    SELECT COUNT(1) INTO V_CNT FROM ALL_SEQUENCES WHERE SEQUENCE_NAME=V_SEQ_NAME;
  EXCEPTION
  WHEN OTHERS THEN
    RAISE_APPLICATION_ERROR(-20100,'CHECK SEQUENCE '||V_SEQ_NAME||'IN ALL_SEQUENCES'||SQLERRM);
  END;
  
IF V_CNT = 0 THEN

  BEGIN
    SELECT NVL(MAX(DOC_NUM),0) + 1
    INTO vcounter
    FROM
      (
        SELECT TO_NUMBER(SUBSTR(DOC_NUM,7,7)) DOC_NUM
        FROM T_FUND_LEDGER
        WHERE doc_num LIKE v_mmyy
        UNION
        SELECT TO_NUMBER(SUBSTR(field_value,7,7)) DOC_NUM
        FROM
          (
            SELECT update_date, update_seq, field_value
            FROM T_MANY_DETAIL
            WHERE UPDATE_DATE BETWEEN v_from_dt AND v_to_dt
            AND TABLE_NAME ='T_FUND_LEDGER'
            AND FIELD_NAME = 'DOC_NUM'
            AND FIELD_VALUE LIKE v_mmyy
          )
          a
        JOIN
          (
            SELECT update_date, update_seq
            FROM T_MANY_HEADER
            WHERE UPDATE_DATE BETWEEN v_from_dt AND v_to_dt
            AND APPROVED_STATUS = 'E'
          )
          b
        ON a.UPDATE_DATE = b.UPDATE_DATE
        AND a.UPDATE_SEQ = b.UPDATE_SEQ
      );
  EXCEPTION
  WHEN OTHERS THEN
    RAISE_APPLICATION_ERROR(-20100,'RETRIEVE FROM T_FUND_MOVEMENT '||SQLERRM);
  END;
  
  BEGIN
    V_STR :='CREATE SEQUENCE '||V_SEQ_NAME||' MINVALUE 0 MAXVALUE 9999999 INCREMENT BY 1 START WITH '||vcounter;
    EXECUTE IMMEDIATE V_STR;
  EXCEPTION
  WHEN OTHERS THEN
    RAISE_APPLICATION_ERROR(-20300,'CREATE SEQUENCE '||V_SEQ_NAME||SQLERRM);
  END;
  
END IF;

BEGIN
  V_STR :='SELECT '||V_SEQ_NAME||'.NEXTVAL FROM DUAL';
  EXECUTE IMMEDIATE V_STR INTO vcounter;
EXCEPTION
WHEN OTHERS THEN
  RAISE_APPLICATION_ERROR(-20400,'GET SEQ USING EXECUTE IMMEDIATE '||SQLERRM);
END;

v_doc_num := v_doc_num||TO_CHAR(NVL(vcounter,0),'fm0000000');
RETURN v_doc_num;
EXCEPTION
WHEN NO_DATA_FOUND THEN
  NULL;
WHEN OTHERS THEN
  -- Consider logging the error and then re-raise
  RAISE;
END Get_Docnum_Fund;