create or replace 
FUNCTION Get_Docnum_Fund (p_tgl IN DATE,
                                           p_mode IN CHAR)
RETURN VARCHAR2
IS
-- parameter p_mode berisi R atau W

  v_doc_num    	T_FUND_MOVEMENT.doc_NUM%TYPE;


  vcounter   NUMBER(8) := 0;

BEGIN
  -- Format : mmyyRF0000001  ( 7 digit)for Receipt Voucher Entry - masuk ke  dana client
  -- Format : mmyyWF0000001  for Withdraw Voucher Entry - keluar dr dana client
  -- EF = reversal

  v_doc_num := trim(TO_CHAR(p_tgl,'mmyy')||p_mode)||'F';

 IF TO_CHAR(P_TGL,'YYMM') < TO_CHAR(SYSDATE,'YYMM') THEN
 
 BEGIN
 	SELECT NVL(MAX(DOC_NUM),0) + 1 INTO vcounter 
		FROM
		(
		SELECT MAX(to_number(SUBSTR(DOC_NUM,7,7))) DOC_NUM FROM T_FUND_MOVEMENT WHERE TO_CHAR(DOC_DATE,'MMYY') = TO_CHAR(P_TGL,'MMYY')
		AND LENGTH(DOC_NUM) =13
			UNION
			SELECT to_number(SUBSTR(DOC_NUM,7,7))
			FROM
			(
				SELECT MAX(DOC_NUM) DOC_NUM, MAX(DOC_DATE) DOC_DATE
				FROM 
				(
					SELECT DECODE(field_name,'DOC_NUM',field_value, NULL) DOC_NUM,
					DECODE(field_name,'DOC_DATE',field_value, NULL) DOC_DATE,
					a.UPDATE_DATE, a.UPDATE_SEQ, RECORD_SEQ
					FROM T_MANY_DETAIL a JOIN T_MANY_HEADER b
					ON a.UPDATE_SEQ = b.UPDATE_SEQ
					AND a.UPDATE_DATE = b.UPDATE_DATE
          AND a.TABLE_NAME='T_FUND_MOVEMENT'
					WHERE FIELD_NAME IN ('DOC_NUM','DOC_DATE')
					AND APPROVED_STATUS = 'E'
				)
				GROUP BY UPDATE_DATE, UPDATE_SEQ, RECORD_SEQ
			)
			WHERE SUBSTR(DOC_DATE,1,7) = TO_CHAR(p_tgl,'yyyy/mm')
			AND LENGTH(DOC_NUM) = 13
		);
  EXCEPTION
      WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20100,'RETRIEVE FROM T_FUN_MOVEMENT '||SQLERRM);
    END;
	ELSE
	
	SELECT SEQ_FUND_JUR.NEXTVAL INTO VCOUNTER FROM DUAL;
 
 END IF;
 
 IF VCOUNTER IS NULL THEN
 VCOUNTER :=1;
 END IF;
 
 
   v_doc_num := v_doc_num||TO_CHAR(NVL(vcounter,0),'fm0000000');

  RETURN v_doc_num;
   EXCEPTION
     WHEN NO_DATA_FOUND THEN
       NULL;
     WHEN OTHERS THEN
       -- Consider logging the error and then re-raise
       RAISE;
END Get_Docnum_Fund;