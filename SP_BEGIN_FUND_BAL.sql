create or replace 
PROCEDURE SP_BEGIN_FUND_BAL(P_BAL_DATE IN DATE,
	   	  		  					   P_NEW_BAL_DATE IN DATE,
	   	  		  					   P_USER_ID IN t_fund_bal.USER_ID%type,
	   	  		  					   P_ERROR_CODE OUT NUMBER,
	   	  		  					   P_ERROR_MSG OUT VARCHAR2) IS

cursor csr_fl( a_begin_date date, a_end_date date) is

	select client_cd, acct_cd,
	decode(sign(sum(debit-credit)),1,sum(debit-credit),0) as balance_debit,
	abs(decode(sign(sum(debit-credit)),1,0,sum(debit-credit))) as balance_credit
from( select client_cd, acct_cd,
			debit,
			credit
	from t_fund_ledger
	WHERE doc_date between a_begin_date AND a_end_date
	and approved_sts = 'A'
	union all
	select client_cd, acct_cd,
		   debit,
		   credit
	from t_fund_bal
	where bal_dt = a_begin_date)
--WHERE CLIENT_CD = 'ALVI002R'	
group by acct_cd, client_cd
order by client_cd, acct_cd;


v_cnt NUMBER;
v_begin_date date;
v_end_date date;

v_err EXCEPTION;
v_error_code NUMBER;
v_error_msg VARCHAR2(2000);

BEGIN

	 v_end_date := p_new_bal_date - 1;
	 v_begin_date := p_bal_date;
	 v_cnt := -1;
	--12juli 2016
	begin
		update t_fund_bal set debit=0, credit=0 where bal_dt=p_new_bal_date;
	EXCEPTION
			 WHEN OTHERS THEN
				v_error_code := -5;
				v_error_msg  := SUBSTR('update t_fund_bal, set debit=0 and credit=0 '||SQLERRM,1,200);
				RAISE v_err;
		END ;	
	 
	 
	 
   FOR REC IN csr_fl( v_begin_date, v_end_date) LOOP

   	   begin
		select count(1)
		into v_cnt
		from t_fund_bal
		where bal_dt = p_new_bal_date
		and client_cd = rec.client_cd
		and acct_cd = rec.acct_cd;
		exception
		when no_data_found then
		v_cnt := 0;
		end;


		if v_cnt > 0 then
	       begin
	   		update t_fund_bal
	 		set debit = rec.balance_debit,
				credit = rec.balance_credit,
				cre_dt = sysdate,
				user_id = p_user_id
	 			where client_cd = rec.client_cd
				and acct_cd = rec.acct_cd
				AND BAL_DT = P_NEW_BAL_DATE;
		 	EXCEPTION
	     		 WHEN OTHERS THEN
	     		  	v_error_code := -10;
					v_error_msg  := SUBSTR('update t_fund_bal '||SQLERRM,1,200);
					RAISE v_err;
	       	  		
		 	END ;

		else
		    if rec.balance_debit <> 0 or rec.balance_credit <> 0 then
		 	begin
			  	INSERT INTO T_fund_BAL (
	 			   BAL_DT, acct_cd,CLIENT_CD,
	 			   debit, credit, gl_a,sl_a,
	 			   CRE_DT, USER_ID)
	 	      	 VALUES (p_new_bal_date, rec.acct_cd, rec.client_cd,
	 			    rec.balance_debit, rec.balance_credit, null, null,
	 			    sysdate, p_USER_ID);
				EXCEPTION
		     		 WHEN OTHERS THEN
	     		  		v_error_code := -20;
						v_error_msg  := SUBSTR('INSERT INTO T_fund_BAL '||SQLERRM,1,200);
						RAISE v_err;
			 	END ;
			end if;
		 end if;

   END LOOP;

-- if v_cnt = -1 then
--    	  begin
-- 	   delete from t_fund_bal
-- 	   where bal_dt = p_new_bal_date;
-- 	   EXCEPTION
--    		 WHEN OTHERS THEN
--    	  		 RAISE;
--  	  END ;
-- 	  end if;
	
	p_error_code	:= 1;
	p_error_msg		:= '';

   EXCEPTION
     WHEN NO_DATA_FOUND THEN
       NULL;
     WHEN v_err THEN
      ROLLBACK;
     	p_error_code := v_error_code;
     	p_error_msg :=v_error_msg;
     WHEN OTHERS THEN
      ROLLBACK;
     	p_error_code :=-1;
     	p_error_msg :=SUBSTR(SQLERRM,1,200);
       RAISE;
END SP_BEGIN_FUND_BAL;