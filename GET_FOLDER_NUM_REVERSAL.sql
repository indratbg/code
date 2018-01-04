create or replace 
FUNCTION "GET_FOLDER_NUM_REVERSAL"  (p_doc_date   DATE,
	   	  		  		   				   p_prefix     T_FOLDER.FOLDER_CD%TYPE,
										   p_doc_num     T_ACCOUNT_LEDGER.xn_doc_num%TYPE,
										   p_user_id     T_ACCOUNT_LEDGER.user_id%TYPE
										   )
RETURN VARCHAR2 IS

v_seq_num	  NUMBER;
v_folder_cd	  T_ACCOUNT_LEDGER.folder_cd%TYPE;
v_fld_prefix  CHAR(3);

BEGIN

 --  v_fld_prefix := 'IJ-';
   v_fld_prefix := p_prefix;

   IF trim(p_prefix) = 'IJ-' THEN
	   SELECT MAX(TO_NUMBER(SUBSTR(t.FOLDER_CD,4,4))) INTO v_seq_num
	   FROM T_FOLDER t
	   WHERE t.fld_mon = TO_CHAR(p_doc_date,'mmyy')
	     AND SUBSTR(t.folder_cd,1,3) = v_fld_prefix
		 AND SUBSTR(t.doc_num,8,3) = 'INT';
   ELSE
	   SELECT MAX(TO_NUMBER(SUBSTR(t.FOLDER_CD,4,4))) INTO v_seq_num
	   FROM T_FOLDER t
	   WHERE t.fld_mon = TO_CHAR(p_doc_date,'mmyy')
	     AND SUBSTR(t.folder_cd,1,3) = v_fld_prefix;

   END IF;


   IF NVL(v_seq_num,0) < 1000 AND trim(p_prefix) = 'IJ-' THEN
      v_seq_num := 1000;
   END IF;

   v_seq_num := NVL(v_seq_num,0) + 1;
   v_folder_cd := v_fld_prefix||TO_CHAR(v_seq_num,'fm0000');



   RETURN v_folder_cd;
   EXCEPTION
     WHEN NO_DATA_FOUND THEN
       NULL;
     WHEN OTHERS THEN
       -- Consider logging the error and then re-raise
       RAISE;
END GET_FOLDER_NUM_REVERSAL;