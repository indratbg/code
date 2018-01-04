create or replace 
trigger "IPNEXTG"."TI_T_TRX_FOREIGN" 
BEFORE INSERT ON T_TRX_FOREIGN
FOR EACH ROW

BEGIN
  SELECT NVL(MAX(SEQNO)+1,1) INTO :new.SEQNO
  FROM T_TRX_FOREIGN;
END;