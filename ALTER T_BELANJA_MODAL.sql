ALTER TABLE T_BELANJA_MODAL ADD(
   UPD_DT DATE,
  UPD_BY VARCHAR2(10),
  APPROVED_DT DATE,
   APPROVED_BY VARCHAR2(10),
   APPROVED_STAT CHAR(1),
   SEQNO NUMBER);
   
   UPDATE T_BELANJA_MODAL SET APPROVED_STAT = 'A';