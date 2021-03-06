create or replace FUNCTION Get_Docnum_Gl(
    p_tgl       IN DATE,
    p_jvch_type IN CHAR)
  RETURN VARCHAR2
IS
  -- func ini tidak di pake utk GLADPR/ GLAMFE ( msh pake GET DOCNUM_JVCH)
  vs_jvch_num T_JVCHH.JVCH_NUM%TYPE;
  vs_doccd VARCHAR2(10) := NULL;
  v_mmyy T_JVCHH.JVCH_NUM%TYPE;
  vcounter NUMBER(10) := 0;
  --v_from_dt DATE;
  --v_to_dt DATE;
  V_SEQ_NAME VARCHAR2(30);
  V_CNT      NUMBER(1);
  V_STR      VARCHAR2(200);
  PRAGMA autonomous_transaction;
  -- [IN] 07 MAR 2017 DITAMBAH UNION KE T_PAYRECH DAN INBOX VOUCHER KARENA MENGGUNAKAN SEQUENCE YANG SAMA DENGAN VOUCHER
BEGIN
  -- Format : mmyyGL0000001  for general ledger
  V_SEQ_NAME :='SEQ_JUR_'||TO_CHAR(p_tgl,'MMYY');
  --IF ps_jvch = 'GL' THEN
  vs_doccd := trim(TO_CHAR(p_tgl,'mmyy'))||trim(p_jvch_type);
  v_mmyy   := TO_CHAR(p_tgl,'mmyy');
  
  BEGIN
    SELECT COUNT(1) INTO V_CNT FROM ALL_SEQUENCES WHERE SEQUENCE_NAME=V_SEQ_NAME;
  EXCEPTION
  WHEN OTHERS THEN
    RAISE_APPLICATION_ERROR(-20100,'CHECK SEQUENCE '||V_SEQ_NAME||'IN ALL_SEQUENCES'||SQLERRM);
  END;
  
IF V_CNT =0 THEN

  BEGIN
    SELECT NVL(MAX(JVCH_NUM),0) + 1
    INTO vcounter
    FROM
      (
        SELECT SUBSTR(JVCH_NUM,8,7) JVCH_NUM
        FROM T_JVCHH
        WHERE JVCH_NUM LIKE vs_doccd||'%'
        AND SUBSTR(JVCH_NUM,8,3)<>'MFE'
        and SUBSTR(JVCH_NUM,8,3)<>'INT'
        UNION
        SELECT SUBSTR(field_value,8,7) JVCH_NUM
        FROM T_MANY_DETAIL a
        JOIN T_MANY_HEADER b
        ON a.UPDATE_DATE     = b.UPDATE_DATE
        AND a.UPDATE_SEQ     = b.UPDATE_SEQ
        WHERE b.UPDATE_DATE >=TRUNC(SYSDATE)
        AND TABLE_NAME       = 'T_JVCHH'
        AND FIELD_NAME       = 'JVCH_NUM'
        AND FIELD_VALUE LIKE vs_doccd||'%'
        AND APPROVED_STATUS = 'E'
        UNION
        SELECT SUBSTR(payrec_num,8,7) FROM T_PAYRECH a WHERE PAYREC_NUM LIKE vs_doccd||'%'
        UNION
        SELECT SUBSTR(field_value,8,7)
        FROM T_MANY_DETAIL a
        JOIN T_MANY_HEADER b
        ON a.UPDATE_DATE    = b.UPDATE_DATE
        AND a.UPDATE_SEQ    = b.UPDATE_SEQ
        WHERE b.UPDATE_DATE>=TRUNC(SYSDATE)
        AND TABLE_NAME      = 'T_PAYRECH'
        AND FIELD_NAME      = 'PAYREC_NUM'
        AND FIELD_VALUE LIKE vs_doccd||'%'
        AND APPROVED_STATUS = 'E'
      );
  EXCEPTION
  WHEN OTHERS THEN
    RAISE_APPLICATION_ERROR(-20100,'RETRIEVE FROM T_JVCHH '||SQLERRM);
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

vs_jvch_num := vs_doccd||'A'||TO_CHAR(NVL(vcounter,0),'fm0000000');

RETURN vs_jvch_num;

END Get_Docnum_Gl;