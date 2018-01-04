create or replace 
FUNCTION         F_SID (P_SID VARCHAR2)
RETURN VARCHAR AS

V_SID VARCHAR2(30);
--vl_err			EXCEPTION;
BEGIN
   IF LENGTH(P_SID) >0 THEN
      V_SID := Substr(P_SID,1,2)||'-'||Substr(P_SID,3,1)||'-'||Substr(P_SID,4,4)||'-'||Substr(P_SID,8,6)||'-'||Substr(P_SID,-2);
    END IF;
      RETURN  V_SID;
	
END F_SID;