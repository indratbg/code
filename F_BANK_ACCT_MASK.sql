create or replace FUNCTION F_BANK_ACCT_MASK
( p_bank_acct_num VARCHAR2,
  p_format VARCHAR2 )
RETURN VARCHAR2 IS
tmpVar NUMBER;
/******************************************************************************
   NAME:       F_BANK_ACCT_MASK
   PURPOSE:

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        11/03/2014          1. Created this function.

   NOTES:

******************************************************************************/
v_len NUMBER;
v_pos NUMBER;
i NUMBER;
v_formatted VARCHAR2(50);
BEGIN

       
   tmpVar := 0;
   v_pos := 0;
   v_len := LENGTH(trim(p_format));
   IF v_len=1  OR p_format IS NULL THEN
    v_formatted :=p_bank_acct_num;
   ELSE

   FOR i IN 1..v_len LOOP
       IF SUBSTR(p_format,i,1) ='#' THEN
          v_pos := v_pos + 1;
           v_formatted := v_formatted||SUBSTR(p_bank_acct_num,v_pos,1);
    ELSE
                 v_formatted := v_formatted||'.';
    END IF;


   END LOOP;

   END IF;

   RETURN v_formatted;
   EXCEPTION
     WHEN NO_DATA_FOUND THEN
       NULL;
     WHEN OTHERS THEN
       -- Consider logging the error and then re-raise
       RAISE;
END F_BANK_ACCT_MASK;