create or replace 
FUNCTION         F_SUBREK (P_SUBREK VARCHAR2)
RETURN VARCHAR AS

V_SUBREK VARCHAR2(30);
--vl_err			EXCEPTION;
BEGIN
  IF LENGTH(P_SUBREK)>0 THEN
		V_SUBREK := Substr(P_SUBREK,1,5)||'-'||Substr(P_SUBREK,6,4)||'-'||Substr(P_SUBREK,10,3)||'-'||substr(P_SUBREK,-2);
   END IF;
      RETURN  V_SUBREK;
	
END F_SUBREK;