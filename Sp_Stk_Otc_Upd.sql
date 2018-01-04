create or replace PROCEDURE Sp_Stk_Otc_Upd(p_Doc_num T_STK_MOVEMENT.doc_num%TYPE,
 p_SETTLE_DATE  T_STK_MOVEMENT.doc_dt%TYPE,
 p_CLIENT_CD	T_STK_MOVEMENT.client_Cd%TYPE,
 p_STK_CD       T_STK_MOVEMENT.stk_Cd%TYPE,
 p_QTY          T_STK_MOVEMENT.total_share_qty%TYPE,
 p_CUSTODIAN_CD T_STK_MOVEMENT.withdraw_reason_cd%TYPE,
 p_amount		T_STK_OTC.amount%TYPE,
 p_instruction_type T_STK_MOVEMENT.withdraw_reason_cd%TYPE,
p_to_client			T_STK_OTC.TO_CLIENT%TYPE,
p_sett_reason T_STK_OTC.sett_reason%TYPE,
p_xml_flg        T_STK_OTC.xml_flg%TYPE,
 p_user_id      T_STK_MOVEMENT.user_id%TYPE,
 p_err_code		OUT NUMBER,
 p_err_msg		OUT VARCHAR2)

 IS

/******************************************************************************
   NAME:       SP_STK_OTC_UPD
   PURPOSE:

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        16/09/2013          1. Created this procedure.

   NOTES:

   Automatically available Auto Replace Keywords:
      Object Name:     SP_STK_OTC_UPD
      Sysdate:         16/09/2013
      Date and Time:   16/09/2013, 15:03:51, and 16/09/2013 15:03:51
      Username:         (set in TOAD Options, Procedure Editor)
      Table Name:       (set in the "New PL/SQL Object" dialog)

******************************************************************************/
v_err EXCEPTION;
v_error_code NUMBER;
v_error_msg VARCHAR2(200);
v_cnt NUMBER;
v_instruction_type T_STK_OTC.instruction_type%TYPE;
BEGIN

   v_Cnt := 0;

   BEGIN
   SELECT COUNT(1) INTO v_cnt
   FROM T_STK_OTC
   WHERE doc_num = p_doc_num;
EXCEPTION
WHEN OTHERS THEN
	v_error_code :=-10;
	v_error_msg :=SUBSTR('SELECT COUNT '||p_Doc_num ||'FROM T_STK_OTC',1,200);
	RAISE v_err;
END;

   IF 	P_instruction_type = 'EXERCS' THEN 
    	   v_instruction_type := p_instruction_type;
		   
   ELSE		   
		   IF SUBSTR(p_doc_num,5,1) = 'R' THEN
		   	  IF p_amount = 0 THEN
			     v_instruction_type := 'RFOP';
			  ELSE
			     v_instruction_type := 'RVP';
			  END IF;
		   ELSE
		   	  IF p_amount = 0 THEN
			     v_instruction_type := 'DFOP';
			  ELSE
			     v_instruction_type := 'DVP';
			  END IF;
		
		   END IF;

		   IF p_custodian_cd IS NULL THEN
		         v_instruction_type := 'SECTRS';
		   END IF;

	END IF;	   

   IF v_cnt = 0  THEN

   	  BEGIN
		   INSERT INTO T_STK_OTC (
		   SETTLE_DATE, CLIENT_CD, BELI_JUAL,
		   STK_CD,  QTY,
		   CUSTODIAN_CD, INSTRUCTION_TYPE, DOC_NUM,
		   AMOUNT, CRE_DT, USER_ID, TO_CLIENT, XML_FLG,sett_reason)
		VALUES ( p_settle_date, p_client_Cd, SUBSTR(p_doc_num,5,1),
		    p_stk_Cd,  p_qty,
		    p_custodian_cd,
			v_instruction_type, p_doc_num,
		    p_amount, SYSDATE,p_user_id, p_to_client , p_xml_flg, p_sett_reason);
		EXCEPTION
		WHEN OTHERS THEN
			 v_error_code := -20;
			 v_error_msg := 'insert to T_STK_OTC '||SUBSTR(SQLERRM(SQLCODE),1,200);
			 RAISE v_err;
		END;

	ELSE

		BEGIN
			 UPDATE T_STK_OTC
			 SET xml_flg = p_xml_flg,
			          amount = p_amount,
					  INSTRUCTION_TYPE = v_instruction_type,
            sett_reason = p_sett_reason
			 WHERE settle_date = p_settle_date
			 AND doc_num = p_doc_num;
		EXCEPTION
		WHEN OTHERS THEN
		  v_error_code := -30;
			 v_error_msg := 'update to T_STK_OTC '||SUBSTR(SQLERRM(SQLCODE),1,200);
			 RAISE v_err;
		END;
	END IF;
 p_err_code  := 1;
  p_err_msg := '';

EXCEPTION
WHEN V_ERR THEN
  ROLLBACK;
  p_err_code  := v_error_code;
  p_err_msg := v_error_msg;
WHEN OTHERS THEN
  p_err_code  := -1 ;
  p_err_msg := SUBSTR(SQLERRM(SQLCODE),1,200);
  RAISE;
END Sp_Stk_Otc_Upd;