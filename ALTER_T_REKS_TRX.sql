ALTER TABLE T_REKS_TRX add(
   UPD_DT DATE,
  UPD_BY VARCHAR2(10),
  APPROVED_DT DATE,
   APPROVED_BY VARCHAR2(10),
   APPROVED_STAT CHAR(1),    
	REVERSAL_JUR VARCHAR2(17));
   
 
UPDATE T_REKS_TRX SET APPROVED_STAT = 'A';

   
   
   