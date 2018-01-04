create or replace 
PROCEDURE SPR_TRX_HARIAN(
						p_update_date DATE,
						p_update_seq NUMBER,
						P_TRX_DATE DATE,
						P_USER_ID VARCHAR2,
						P_APPROVED_BY VARCHAR2,
						P_APPROVED_STS VARCHAR2,
						P_ERROR_CD OUT NUMBER,
						P_ERROR_MSG OUT VARCHAR2
						 )

 IS
tmpVar NUMBER;
/******************************************************************************
   NAME:       SP_MKBD_VD51
   PURPOSE:

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        02/02/2015          1. Created this procedure.

   NOTES:


******************************************************************************/

v_client_cd varchar2(20);
V_ERR EXCEPTION;
V_ERROR_CD  NUMBER(2);
V_ERROR_MSG VARCHAR2(200);


CURSOR csr_lap(a_client_cd varchar2) IS
SELECT P_TRX_DATE TRX_DT, GRP, SEQNO, DESCRIP, NVL(BELI,0) beli, NVL(JUAL,0) jual				
FROM( SELECT 1 grp, 1 SEQNO, 'PORTOFOLIO' AS DESCRIP, SUM(DECODE(SUBSTR(CONTR_NUM,5,1),'B',VAL,0)) BELI,				
       SUM(DECODE(SUBSTR(CONTR_NUM,5,1),'J',VAL,0)) JUAL				
FROM INSISTPRO.T_CONTRACTS				
WHERE CONTR_DT = P_TRX_DATE				
AND CONTR_STAT <> 'C'				
AND SUBSTR(CONTR_NUM,6,1) = 'R'				
AND (SUBSTR(CLIENT_TYPE,1,1) = 'H' OR CLIENT_CD = a_client_cd)				
UNION				
SELECT 1 grp, 2 SEQNO, 'NASABAH', SUM(DECODE(SUBSTR(CONTR_NUM,5,1),'B',VAL,0)) BELI,				
       SUM(DECODE(SUBSTR(CONTR_NUM,5,1),'J',VAL,0)) JUAL				
FROM INSISTPRO.T_CONTRACTS				
WHERE CONTR_DT = P_TRX_DATE				
AND CONTR_STAT <> 'C'				
AND   SUBSTR(CONTR_NUM,6,1) = 'R'				
AND (SUBSTR(CLIENT_TYPE,1,1) <> 'H' AND CLIENT_CD <> a_client_cd)				
UNION				
SELECT 2 grp, 3 SEQNO, 'REGULAR', SUM(DECODE(SUBSTR(CONTR_NUM,5,1),'B',VAL,0)) BELI,				
       SUM(DECODE(SUBSTR(CONTR_NUM,5,1),'J',VAL,0)) JUAL				
FROM INSISTPRO.T_CONTRACTS				
WHERE CONTR_DT = P_TRX_DATE				
AND CONTR_STAT <> 'C'				
AND  SUBSTR(CONTR_NUM,6,1) = 'R'				
AND SUBSTR(CLIENT_CD,8,1) IN ( 'R','T') 		
AND (SUBSTR(CLIENT_TYPE,1,1) <> 'H' AND CLIENT_CD <> a_client_cd)				
UNION				
SELECT 2 grp, 4 SEQNO, 'MARGIN', SUM(DECODE(SUBSTR(CONTR_NUM,5,1),'B',VAL,0)) BELI,				
       SUM(DECODE(SUBSTR(CONTR_NUM,5,1),'J',VAL,0)) JUAL				
FROM INSISTPRO.T_CONTRACTS				
WHERE CONTR_DT = P_TRX_DATE				
AND CONTR_STAT <> 'C'				
AND   SUBSTR(CONTR_NUM,6,1) = 'R'				
AND SUBSTR(CLIENT_CD,8,1) = 'M' 				
AND (SUBSTR(CLIENT_TYPE,1,1) <> 'H' AND CLIENT_CD <> a_client_cd)				
UNION				
SELECT 2 grp, 5 SEQNO, 'SHORT',  SUM(DECODE(SUBSTR(CONTR_NUM,5,1),'B',VAL,0)) BELI,				
       SUM(DECODE(SUBSTR(CONTR_NUM,5,1),'J',VAL,0)) JUAL				
FROM INSISTPRO.T_CONTRACTS				
WHERE CONTR_DT = P_TRX_DATE				
AND CONTR_STAT <> 'C'				
AND   SUBSTR(CONTR_NUM,6,1) = 'R'				
AND SUBSTR(CLIENT_CD,8,1) = 'S' 				
AND (SUBSTR(CLIENT_TYPE,1,1) <> 'H' AND CLIENT_CD <> a_client_cd)				
UNION				
SELECT 3 grp, 6 SEQNO, 'LOKAL', SUM(DECODE(SUBSTR(CONTR_NUM,5,1),'B',VAL,0)) BELI,				
       SUM(DECODE(SUBSTR(CONTR_NUM,5,1),'J',VAL,0)) JUAL				
FROM INSISTPRO.T_CONTRACTS				
WHERE CONTR_DT = P_TRX_DATE				
AND CONTR_STAT <> 'C'				
AND   SUBSTR(CONTR_NUM,6,1) = 'R'				
AND SUBSTR(CLIENT_TYPE,2,1) = 'L' 				
AND (SUBSTR(CLIENT_TYPE,1,1) <> 'H' AND CLIENT_CD <> a_client_cd)				
UNION				
SELECT 3 grp, 7 SEQNO, 'ASING', SUM(DECODE(SUBSTR(CONTR_NUM,5,1),'B',VAL,0)) BELI,				
       SUM(DECODE(SUBSTR(CONTR_NUM,5,1),'J',VAL,0)) JUAL				
FROM INSISTPRO.T_CONTRACTS				
WHERE CONTR_DT = P_TRX_DATE				
AND CONTR_STAT <> 'C'				
AND   SUBSTR(CONTR_NUM,6,1) = 'R'				
AND SUBSTR(CLIENT_TYPE,2,1) = 'F'				
AND (SUBSTR(CLIENT_TYPE,1,1) <> 'H' AND CLIENT_CD <> a_client_cd)) ;						


BEGIN
--get client_cd
  begin
  select trim(other_1) into v_client_cd from IPNEXTG.mst_company;
  EXCEPTION
        WHEN OTHERS THEN
            V_ERROR_CD := -3;
            V_ERROR_MSG := SQLERRM(SQLCODE);
            RAISE V_ERR;
    END;

	FOR rec in CSR_LAP(v_client_cd) LOOP
	--insert LAP_TRX_HARIAN
	BEGIN
	
	INSERT INTO LAP_TRX_HARIAN (UPDATE_DATE,UPDATE_SEQ,TRX_DT,GRP,SEQNO,
								DESCRIP,BELI, JUAL, USER_ID, APPROVED_DT,
								APPROVED_BY,APPROVED_STS)
			VALUES(P_UPDATE_DATE,P_UPDATE_SEQ,REC.TRX_DT,REC.GRP,REC.SEQNO,
					REC.DESCRIP,REC.BELI, REC.JUAL, P_USER_ID,null,
					P_APPROVED_BY, P_APPROVED_STS);					
	
	 EXCEPTION
        WHEN OTHERS THEN
          V_ERROR_CD := -4;
            V_ERROR_MSG := SQLERRM(SQLCODE);
            RAISE V_ERR;
    END;
	END LOOP;
	
	V_ERROR_CD := 1;
	V_ERROR_MSG :='';
   EXCEPTION
     WHEN V_ERR THEN
      ROLLBACK;
       P_ERROR_CD := V_ERROR_CD;
	   P_ERROR_MSG := SUBSTR(V_ERROR_MSG,1,200);
     WHEN OTHERS THEN
	 ROLLBACK;
       -- Consider logging the error and then re-raise
       RAISE;
END SPR_TRX_HARIAN;