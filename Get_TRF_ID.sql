create or replace FUNCTION Get_TRF_ID (p_tgl IN DATE)
RETURN Varchar2
IS


  v_doc_num    	T_FUND_TRF.trf_id%TYPE;


  vcounter   NUMBER(8) := 0;
--25JAN2017 TAMBAH UNION DENGAN T_H2H_REF_HEADER KARENA DIPAKAI JUGA UNTUK HOST TO HOST
BEGIN
 
 v_doc_num := to_char(p_tgl,'yymmdd');
/*
  SELECT MAX(TO_NUMBER(SUBSTR(a.TRF_ID,7,2))) INTO vcounter
   FROM T_FUND_TRF a
  WHERE TRF_DATE = P_TGL
  AND SUBSTR(a.TRF_ID,1,6) = trim(v_doc_num);
*/
    SELECT MAX(TO_NUMBER(SUBSTR(TRF_ID,7,2)))
    INTO VCOUNTER
    FROM
      (
        SELECT TRF_ID
        FROM T_FUND_TRF
        WHERE TRF_DATE         = P_TGL
        AND SUBSTR(TRF_ID,1,6) = trim(v_doc_num)
        UNION
        SELECT TRF_ID
        FROM T_H2H_REF_HEADER
        WHERE TRF_DATE         =P_TGL
        AND SUBSTR(TRF_ID,1,6) = trim(v_doc_num)
      );

   v_doc_num := v_doc_num||trim(TO_CHAR(NVL(vcounter,0)+1,'fm00'));

  RETURN v_doc_num;
   EXCEPTION
     WHEN NO_DATA_FOUND THEN
       NULL;
     WHEN OTHERS THEN
       -- Consider logging the error and then re-raise
       RAISE;
END Get_TRF_ID;