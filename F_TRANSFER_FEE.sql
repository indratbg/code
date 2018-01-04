create or replace 
FUNCTION F_TRANSFER_FEE
(p_amount 		  T_FUND_MOVEMENT.trx_amt%TYPE,
P_rdi_bank       MST_BANK_ACCT.bank_cd%TYPE,
P_to_bank       MST_BANK_ACCT.bank_cd%TYPE,
P_branch_code MST_BRANCH.brch_cd%TYPE,
P_olt                         MST_CLIENT.olt%TYPE,
p_from_rdi					   MST_CLIENT.olt%TYPE
)
RETURN NUMBER IS
v_biaya NUMBER;
/******************************************************************************
   NAME:       F_TRANSFER_FEE
   PURPOSE:    transfer dana antar bank

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        11/11/2014          1. Created this function.

   NOTES:



******************************************************************************/
BEGIN
   v_biaya  := 0;

IF p_amount = 0 THEN
	RETURN 0;
END IF;

IF  p_amount < 500000000 THEN
	IF p_from_rdi = 'Y' THEN
	   v_biaya := 5000;
	ELSE
   	  v_biaya := 10000;
	END IF;
ELSE
	v_biaya := 20000;
END IF;

IF p_to_bank  IS NOT NULL  THEN

	IF p_to_bank = p_rdi_bank THEN
		v_biaya := 0;
	END IF;
END IF;

 IF p_branch_code IS NOT NULL THEN

	IF trim(p_branch_code) = 'BD' OR p_olt = 'Y' THEN
		v_biaya := -1 * v_biaya;
	END IF;
END IF;

RETURN v_biaya;

   EXCEPTION
     WHEN NO_DATA_FOUND THEN
       NULL;
     WHEN OTHERS THEN
       -- Consider logging the error and then re-raise
       RAISE;
END F_TRANSFER_FEE;
