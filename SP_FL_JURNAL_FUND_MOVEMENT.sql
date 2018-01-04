create or replace 
PROCEDURE SP_FL_JURNAL_FUND_MOVEMENT(
					p_doc_num  T_FUND_MOVEMENT.DOC_NUM%TYPE,
					p_trx_type T_FUND_MOVEMENT.TRX_TYPE%TYPE,
					p_doc_date T_FUND_MOVEMENT.DOC_DATE%TYPE,
					p_client_cd T_FUND_MOVEMENT.CLIENT_CD%TYPE,
					p_trx_amt T_FUND_MOVEMENT.TRX_AMT%TYPE,
					p_approved_user_id  T_MANY_HEADER.user_id%TYPE,
					p_status T_MANY_HEADER.status%TYPE,
					p_error_code out number,
					p_error_msg	out	VARCHAR2
)
IS

/******************************************************************************
   NAME:       SP_FL_JURNAL
   PURPOSE:

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        12/09/2014          1. Created this procedure.

   NOTES:
******************************************************************************/
v_doc_num T_FUND_MOVEMENT.DOC_NUM%TYPE;
v_seqno number;
v_acct_cd T_FUND_LEDGER.ACCT_CD%TYPE;
v_debit T_FUND_LEDGER.DEBIT%TYPE;
v_credit T_FUND_LEDGER.CREDIT%TYPE;
v_err EXCEPTION;
v_error_code							NUMBER;
v_error_msg							VARCHAR2(200);
v_table_name varchar(50):='T_FUND_LEDGER';
BEGIN	
		IF p_status ='I' THEN
		-----------INSERT--------------
		
		FOR v_seqno IN 1..2 LOOP
		
		
		
		if p_trx_type = 'R' then
			if v_seqno =1 then
			v_acct_cd := 'DBEBAS';
			v_debit:= p_trx_amt;
			v_credit := 0;
			else
			v_acct_cd := 'KNPR';
			v_debit:= 0;
			v_credit := p_trx_amt;
			end if;
		elsif p_trx_type= 'W' then
			if v_seqno = 1 then
				v_acct_cd := 'DBEBAS';
				v_debit:= 0;
				v_credit :=p_trx_amt ;
			else
				v_acct_cd := 'KNPR';
				v_debit:= p_trx_amt;
				v_credit := 0;
			end if;
		elsif p_trx_type ='I' THEN
			if v_seqno = 1 then
				v_acct_cd := 'DNU';
				v_debit:= p_trx_amt;
				v_credit :=0 ;
			else
				v_acct_cd := 'KNU';
				v_debit:= 0;
				v_credit := p_trx_amt;
			end if;
		ELSif P_TRX_TYPE ='O' THEN
			if v_seqno = 1 then
				v_acct_cd := 'KNU';
				v_debit:= p_trx_amt;
				v_credit :=0 ;
			else
				v_acct_cd := 'DNU';
				v_debit:= 0;
				v_credit := p_trx_amt;
			end if;
		
		else
			if v_seqno = 1 then
			v_acct_cd := 'DBEBAS';
			v_debit:= p_trx_amt;
			v_credit := 0;
			else
			v_acct_cd := 'KNPR';
			v_debit:= 0;
			v_credit := p_trx_amt;
			end if;
		
		end if;

		BEGIN
					INSERT INTO IPNEXTG.T_FUND_LEDGER (
							   DOC_NUM, SEQNO, TRX_TYPE,
							   DOC_DATE,ACCT_CD,CLIENT_CD,
							   DEBIT,CREDIT, CRE_DT,
							   USER_ID, APPROVED_STS,APPROVED_DT,APPROVED_BY,MANUAL)
			VALUES (p_doc_num , DECODE(v_seqno,1,1,2), p_trx_type,
					p_doc_date,v_acct_cd,p_client_cd,
					v_debit,v_credit,sysdate,
					p_approved_user_id,'A',sysdate,p_approved_user_id,'Y');
				 EXCEPTION
            WHEN NO_DATA_FOUND THEN
              v_error_code := -2;
							v_error_msg :=  SUBSTR(SQLERRM,1,200);
							RAISE v_err;
            WHEN OTHERS THEN
              v_error_code := -3;
              v_error_msg := SUBSTR(SQLERRM,1,200);
              RAISE v_err;
          END;
		  

      
      
      
      
      
      
       END LOOP;
	   ----------------END INSERT----------------
	   /*ELSE
	   ---PANGGIL REVERSAL JURNAL-----
     
     
	    BEGIN   
		   Sp_Reverse_Fundmvmt(
        sysdate, 
          p_doc_num,
          p_approved_user_id,
					p_error_code,
					p_error_msg);
	   EXCEPTION
 	    WHEN OTHERS THEN
	   			v_error_code := -4;
				v_error_msg :=  SUBSTR('Sp_Reverse_Fundmvmt '||v_table_name||SQLERRM,1,200);
				RAISE v_err;
	   END;
	   if v_error_code<0 then
     v_error_code := -5;
     v_error_msg := 'Sp_Reverse_Fundmvmt '||v_table_name||' '||v_error_msg;
	 RAISE v_err;
		end if;
*/
	   
	   ---------------------UPDATE--------------------
	/*   FOR v_seqno IN 1..2 LOOP
		
		
		
		if p_trx_type = 'R' then
			if v_seqno =1 then
			v_acct_cd := 'DBEBAS';
			v_debit:= 0;
			v_credit := p_trx_amt;
			else
			v_acct_cd := 'KNPR';
			v_debit:= p_trx_amt;
			v_credit := 0;
			end if;
		elsif p_trx_type= 'W' then
			if v_seqno = 1 then
				v_acct_cd := 'KNPR';
				v_debit:= 0;
				v_credit := p_trx_amt;
			else
				v_acct_cd := 'DBEBAS';
				v_debit:= p_trx_amt;
				v_credit := 0;
			end if;
		else
			if v_seqno = 1 then
			v_acct_cd := 'DBEBAS';
			v_debit:= 0;
			v_credit := p_trx_amt;
			else
			v_acct_cd := 'KNPR';
			v_debit:= p_trx_amt;
			v_credit := 0;
			end if;
		
		end if;
		
			BEGIN
					INSERT INTO IPNEXTG.T_FUND_LEDGER (
							   DOC_NUM, SEQNO, TRX_TYPE,
							   DOC_DATE,ACCT_CD,CLIENT_CD,
							   DEBIT,CREDIT, CRE_DT,
							   USER_ID, APPROVED_STS,APPROVED_DT,APPROVED_BY)
			VALUES (p_doc_num , DECODE(v_seqno,1,1,2), p_trx_type,
					p_doc_date,v_acct_cd,p_client_cd,
					v_debit,v_credit,sysdate,
					p_approved_user_id,'A',sysdate,p_approved_user_id);
				 EXCEPTION
            WHEN NO_DATA_FOUND THEN
              v_error_code := -2;
							v_error_msg :=  SUBSTR(SQLERRM,1,200);
							RAISE v_err;
            WHEN OTHERS THEN
              v_error_code := -3;
              v_error_msg := SUBSTR(SQLERRM,1,200);
              RAISE v_err;
          END;
		  
       END LOOP;
	   
	   --------------------END UPDATE-----------------
*/
	   
	   END IF; 
	   
	   
		--p_doc_num:=v_doc_num;
		p_error_code :=  1;
		p_error_msg :=  '';
   EXCEPTION
     WHEN NO_DATA_FOUND THEN
       NULL;
       WHEN v_err THEN
           p_error_code := v_error_code;
		   p_error_msg :=  v_error_msg;
	      ROLLBACK;

     WHEN OTHERS THEN
       -- Consider logging the error and then re-raise
       v_error_code :=-1;
        v_error_msg := SUBSTR(SQLERRM,1,200);
        ROLLBACK;
       RAISE;
END SP_FL_JURNAL_FUND_MOVEMENT;