create or replace 
PROCEDURE SP_FUND_BAL_BANK_DELETE(p_status_dt date) IS
tmpVar NUMBER;
/******************************************************************************
   NAME:       FUND_BAL_BANK_DELETE
   PURPOSE:    

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        12/02/2012          1. Created this procedure.

   NOTES:

   Automatically available Auto Replace Keywords:
      Object Name:     FUND_BAL_BANK_DELETE
      Sysdate:         12/02/2012
      Date and Time:   12/02/2012, 08:37:16, and 12/02/2012 08:37:16
      Username:         (set in TOAD Options, Procedure Editor)
      Table Name:       (set in the "New PL/SQL Object" dialog)

******************************************************************************/
BEGIN
   tmpVar := 0;
   begin
   delete from t_fund_bal_bank
   where status_dt = p_status_dt;
   exception
   when others then
   raise_application_error(-20100,'delete t_fund_bal_bank '||sqlerrm);
   end;
   
   EXCEPTION
     WHEN NO_DATA_FOUND THEN
       NULL;
     WHEN OTHERS THEN
       -- Consider logging the error and then re-raise
       RAISE;
END SP_FUND_BAL_BANK_DELETE;



