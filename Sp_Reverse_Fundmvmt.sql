create or replace 
PROCEDURE Sp_Reverse_Fundmvmt(
P_DATE 	  		  T_FUND_MOVEMENT.doc_date%TYPE,
P_DOC_NUM  T_FUND_MOVEMENT.doc_num%TYPE,
P_USER_ID     T_FUND_MOVEMENT.user_id%TYPE,
p_error_code OUT NUMBER,
p_error_msg			OUT				VARCHAR2)
 IS

/******************************************************************************
   NAME:       SP_REVERSE_FUNDMVMT
   PURPOSE:

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        08/10/2014          1. Created this procedure.

   NOTES:


******************************************************************************/

 v_err EXCEPTION;
v_error_code							NUMBER;
v_error_msg							VARCHAR2(200);

v_reversal_doc_num  T_FUND_MOVEMENT.doc_num%TYPE;
BEGIN

			v_reversal_doc_num := Get_Docnum_Fund(p_Date, 'E');

		   BEGIN
		   INSERT INTO IPNEXTG.T_FUND_LEDGER (
		   DOC_NUM, SEQNO, TRX_TYPE,
		   DOC_DATE, ACCT_CD, CLIENT_CD,
		   DEBIT, CREDIT, CRE_DT,
		   USER_ID, APPROVED_DT, APPROVED_STS,
		   APPROVED_BY,manual)
		SELECT  v_reversal_doc_num, DECODE(SEQNO,1,2,1), 'E' TRX_TYPE,
		   p_DATE, ACCT_CD, CLIENT_CD,
			CREDIT, DEBIT, SYSDATE CRE_DT,
		   p_USER_ID, NULL, 'A' ,
		   NULL,'Y'
		   FROM T_FUND_LEDGER
		   WHERE doc_num = p_doc_num;
		   EXCEPTION
		   WHEN OTHERS THEN
				 v_error_code := -2;
				 v_error_msg :=  SUBSTR('insert reversal fund ledger '|| p_doc_num||SQLERRM,1,200);
				 RAISE v_err;
			END;

			BEGIN
		   UPDATE T_FUND_MOVEMENT
			SET REVERSAL_JUR = v_reversal_doc_num
			WHERE doc_num = p_doc_num;
		   EXCEPTION
		   WHEN OTHERS THEN
				 v_error_code := -3;
				 v_error_msg :=  SUBSTR('update fund movement '|| p_doc_num||SQLERRM,1,200);
				 RAISE v_err;
			END;

   EXCEPTION
     WHEN NO_DATA_FOUND THEN
       NULL;
	   WHEN v_err THEN
		P_ERROR_Code := v_error_code;
		P_ERROR_MSG :=  V_ERROR_MSG;
		ROLLBACK;
     WHEN OTHERS THEN
       -- Consider logging the error and then re-raise
	    ROLLBACK;
		P_ERROR_Code := -1;
		P_ERROR_MSG := SUBSTR(SQLERRM,1,200);
		RAISE;		
END Sp_Reverse_Fundmvmt;