create or replace 
PROCEDURE Sp_Reverse_Stkmvmt(
P_DATE 	  		  T_STK_MOVEMENT.doc_dt%TYPE,
P_DOC_NUM  T_STK_MOVEMENT.doc_num%TYPE,
P_USER_ID     T_STK_MOVEMENT.USER_ID%TYPE,
P_REVERSAL_DOC_NUM  OUT T_STK_MOVEMENT.doc_num%TYPE,
P_error_code OUT   NUMBER,
P_error_msg	 OUT	VARCHAR2)
 IS
/******************************************************************************
   NAME:       SP_REVERSAL_STKMVMT
   PURPOSE:    reversal dr stk movement jurnal -  doc_num = mmyyREVxxxxx
                               DOC STAT = '3'
                               dan update T_STKHAND

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        13/10/2014          1. Created this procedure.

   NOTES:


******************************************************************************/

v_DOC_NUM 						T_STK_MOVEMENT.doc_num%TYPE;
v_client_cd								T_STK_MOVEMENT.client_cd%TYPE;
v_stk_cd								T_STK_MOVEMENT.stk_cd%TYPE;
v_qty									    T_STK_MOVEMENT.total_share_qty%TYPE;

v_err EXCEPTION;
v_error_code				NUMBER;
v_error_msg					VARCHAR2(1000);
BEGIN

		BEGIN
		   SELECT client_Cd, stk_Cd, total_share_qty + withdrawn_share_qty
		   INTO v_client_cd, v_stk_cd, v_qty
		   FROM T_STK_MOVEMENT
		   WHERE doc_num = p_doc_num
		   AND seqno = 1;
		EXCEPTION
	   WHEN OTHERS THEN
			v_error_code := -5;
			v_error_msg  := SUBSTR('Select T_STK_MOVEMENT' ||SQLERRM,1,200);
			RAISE v_err;
	   END;

   v_DOC_NUM := Get_Stk_Jurnum(p_date,'REV');

   BEGIN
   INSERT INTO IPNEXTG.T_STK_MOVEMENT (
   DOC_NUM, REF_DOC_NUM, DOC_DT,
   CLIENT_CD, STK_CD, S_D_TYPE,
   ODD_LOT_DOC, TOTAL_LOT, TOTAL_SHARE_QTY,
   DOC_REM, DOC_STAT, WITHDRAWN_SHARE_QTY,
   REGD_HLDR, WITHDRAW_REASON_CD, GL_ACCT_CD,
   ACCT_TYPE, DB_CR_FLG, USER_ID,
   CRE_DT, UPD_DT, STATUS,
   DUE_DT_FOR_CERT, STK_STAT, DUE_DT_ONHAND,
   SEQNO, PRICE, APPROVED_DT,
   APPROVED_BY, APPROVED_STAT,PREV_DOC_NUM,MANUAL)
   SELECT
   v_DOC_NUM, REF_DOC_NUM, p_Date AS DOC_DT,
   CLIENT_CD, STK_CD,  S_D_TYPE,
   ODD_LOT_DOC, TOTAL_LOT, TOTAL_SHARE_QTY,
   'Rv '||DOC_REM, '3' DOC_STAT, WITHDRAWN_SHARE_QTY,
   REGD_HLDR, WITHDRAW_REASON_CD, GL_ACCT_CD,
   ACCT_TYPE, DECODE(DB_CR_FLG,'D','C','D'), P_USER_ID,
   SYSDATE CRE_DT, NULL UPD_DT, STATUS,
   DUE_DT_FOR_CERT, STK_STAT, DUE_DT_ONHAND,
   DECODE(SEQNO,1,2,1), PRICE, SYSDATE APPROVED_DT,
   P_USER_ID APPROVED_BY, APPROVED_STAT, DOC_NUM, 'Y' AS "MANUAL"
   FROM T_STK_MOVEMENT
   WHERE doc_num = P_doc_num
   ORDER BY seqno DESC;
   EXCEPTION
   WHEN OTHERS THEN
   		v_error_code := -10;
		v_error_msg  := SUBSTR('create reverse secu jurnal '||p_doc_num||SQLERRM,1,200);
		RAISE v_err;
   END;

   BEGIN
   UPDATE T_STK_MOVEMENT
   SET doc_stat = '9',
             upd_dt = SYSDATE,
			upd_by = p_user_id
	WHERE doc_num = p_doc_num;
	EXCEPTION
	WHEN OTHERS THEN
	v_error_code := -15;
		v_error_msg  := SUBSTR('upd doc_stat reversed secu jurnal '||p_doc_num||SQLERRM,1,200);
		RAISE v_err;
   END;


   P_REVERSAL_DOC_NUM := v_doc_num;
   p_error_code := 1;
   p_error_msg := '';

   EXCEPTION
     WHEN NO_DATA_FOUND THEN
       NULL;
	   WHEN v_err THEN
	   p_error_code := v_error_code;
	   p_error_msg :=  v_error_msg;
	   ROLLBACK;
     WHEN OTHERS THEN
       -- Consider logging the error and then re-raise
	      ROLLBACK;
	   p_error_code := -1;
	   p_error_msg := SUBSTR(SQLERRM,1,200);
       RAISE;
END Sp_Reverse_Stkmvmt;
