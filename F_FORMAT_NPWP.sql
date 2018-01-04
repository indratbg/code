create or replace 
FUNCTION         F_FORMAT_NPWP (P_NPWP VARCHAR2)
RETURN VARCHAR AS

V_NPWP VARCHAR2(30);
BEGIN
  IF LENGTH(P_NPWP)=15 THEN
		V_NPWP := Substr(P_NPWP,1,2)||'.'||Substr(P_NPWP,3,3)||'.'||Substr(P_NPWP,6,3)||'.'||substr(P_NPWP,9,1)||'-'||substr(P_NPWP,10,3)||'.'||
		substr(P_NPWP,15,3);
  END IF;
   RETURN  V_NPWP;
	
END F_FORMAT_NPWP;