create or replace 
PROCEDURE           "SP_FL_BCA_INTEREST_APPROVE" (
      v_tanggalefektif t_bank_mutation.tanggalefektif%type,
      v_client_cd mst_client.client_cd%type,
      v_transactiontype t_bank_mutation.transactiontype%type,
	   p_menu_name							  	T_MANY_HEADER.menu_name%TYPE,
	   p_update_date							T_MANY_HEADER.update_date%TYPE,
	   p_update_seq								T_MANY_HEADER.update_seq%TYPE,
	   p_approved_user_id				  T_MANY_HEADER.user_id%TYPE,
	   p_approved_ip_address 		 T_MANY_HEADER.ip_address%TYPE,
     p_error_code			OUT NUMBER,
	   p_error_msg			OUT VARCHAR2
	 
) IS

/******************************************************************************
   NAME:      SP_FL_BCA_INTEREST_APPROVE
   PURPOSE:    

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        23/10/2013          1. Created this procedure.

******************************************************************************/

--v_tanggalefektif T_BANK_MUTATION.tanggalefektif%type;
  
cursor csr_int is
select a.TANGGALTimestamp, a.typemutasi,  a.RDN, c.branch_code, c.client_cd, c.client_name,
	 a.TRANSACTIONVALUE, 
 a.BANKREFERENCE, a.namanasabah, b.cnt ,
a.tanggalefektif, a.bankid, a.transactiontype

from( select nvl(bank_ref_num,'X') bank_ref_num, BANK_ACCT_NUM, doc_Date, sl_acct_Cd
	    from T_fund_movement a , mst_client_flacct b
		where doc_date = v_tanggalefektif
		and approved_sts <> 'C'
		and (a.sl_acct_Cd = 'NINT'  or a.sl_acct_Cd = 'NTAX' )
		and a.client_Cd = b.client_Cd) d,
 		t_bank_mutation a, 
		( select BANK_ACCT_NUM, max(client_cd) as client_cd, count(1) as cnt
			from 	mst_client_flacct
			where acct_stat <> 'C' 
		group by BANK_ACCT_NUM
		having count(1) = 1) b, mst_client c
where a.TanggalEfektif = v_tanggalefektif
--and   (a.transactiontype = 'NINT'  or a.transactiontype = 'NTAX' )
and b.client_cd = c.client_cd
and a.rdn = b.BANK_ACCT_NUM
and a.rdn = d.BANK_ACCT_NUM(+)
and d.BANK_ACCT_NUM is null
and a.TanggalEfektif = d.doc_date(+)
and d.doc_date is null
and a.transactiontype = d.sl_acct_cd(+)
and d.sl_acct_cd is null
and c.client_cd= v_client_cd
and a.transactiontype=v_transactiontype
order by c.branch_code, c.client_cd,  a.TANGGALTimestamp;


Vl_DOC_NUM T_FUND_LEDGER.doc_num%TYPE;
vl_debit  T_FUND_LEDGER.debit%TYPE;
vl_credit  T_FUND_LEDGER.credit%TYPE;
vl_fl_acct_cd T_FUND_LEDGER.acct_cd%TYPE;
vl_bank_Cd mst_fund_bank.bank_Cd%TYPE;

vl_trx_type t_fund_movement.trx_type%type;
vl_remarks t_fund_movement.remarks%type;
VL_FROM_BANK t_fund_movement.from_bank%TYPE;
VL_to_BANK t_fund_movement.to_bank%TYPE;
VL_FROM_acct t_fund_movement.from_acct%TYPE;
VL_TO_ACCT t_fund_movement.to_acct%TYPE;
VL_FROM_CLIENT t_fund_movement.from_client%TYPE;
VL_TO_CLIENT t_fund_movement.to_client%TYPE;
vl_ip_bank_cd t_fund_movement.to_bank%TYPE;
v_remarks t_fund_movement.remarks%type;
v_status CHAR(1);
v_err EXCEPTION;
v_error_code							NUMBER;
v_error_msg							VARCHAR2(200);

vl_cnt  number;
v_table_name varchar(50):='T_FUND_MOVEMENT';
BEGIN



--  BEGIN
--  SELECT UPD_STATUS INTO v_status from T_MANY_DETAIL where update_seq =  p_update_seq and update_date=p_update_date and rownum=1;
--  EXCEPTION
-- 	    WHEN OTHERS THEN
--	   			v_error_code := -2;
--				v_error_msg :=  SUBSTR('T_Many_Detail '||SQLERRM,1,200);
--				RAISE v_err;
--	   END;
	  /* 

		IF v_status <> 'C' then
		BEGIN
		 SELECT MAX(REMARKS)
				 INTO v_remarks
				   FROM(
		  		   SELECT	DECODE(field_name,'REMARKS',field_value, NULL) REMARKS
				   FROM  T_MANY_DETAIL
				  WHERE T_MANY_DETAIL.update_date = p_update_date
				  AND T_MANY_DETAIL.table_name = v_table_name
				  AND T_MANY_DETAIL.update_seq	 = p_update_seq
				  AND T_MANY_DETAIL.field_name IN ('REMARKS'));
				  EXCEPTION
            WHEN NO_DATA_FOUND THEN
              v_error_code := -3;
							v_error_msg :=  SUBSTR(SQLERRM,1,200);
							RAISE v_err;
            WHEN OTHERS THEN
              v_error_code := -4;
              v_error_msg := SUBSTR(SQLERRM,1,200);
              RAISE v_err;
          END; 
	
		  end if;

		*/
		  
		

		-- IF v_status ='I' then
			--------------------INSERT---------------------------
		vl_cnt := 0;
  
		 for rec in csr_int loop

		 if rec.typemutasi = 'C' then
		 	vl_trx_type := 'R';
		 else
		 	vl_trx_type := 'W';
		 end if;
	
		 vl_doc_num := Get_Docnum_Fund(rec.tanggalefektif,vl_trx_type);
	
  
  BEGIN
  update t_many_detail set field_value= vl_doc_num where update_seq=p_update_seq and update_date=p_UPDATE_date and field_name='DOC_NUM';
  EXCEPTION
		WHEN OTHERS THEN
			v_error_code := -3;
			v_error_msg := 'T_MANY_DETAIL '||SQLERRM;
			RAISE v_err;
	END;
  
	
		 if rec.bankid = 'BCA02' then
			vl_ip_bank_cd:= 'BCA';
			--vl_transactiontype :=rec.transactiontype;
		--	vl_remarks := 'Setoran '||rec.CLIENT_cD;
		end if;
	
	
		if rec.typemutasi = 'C' and rec.transactiontype = 'NINT' THEN
		   vl_remarks := 'Bunga '||vl_ip_bank_cd;
		   vl_from_client := 'BUNGA';
		   vl_to_client := rec.CLIENT_cD;
		   vl_from_bank := vl_ip_bank_cd;
		   vl_to_bank := vl_ip_bank_cd;
		   vl_from_acct :=  rec.RDN;--15 april 2015
		   vl_to_acct := rec.RDN;
		end if;
	
		if rec.typemutasi = 'D' and rec.transactiontype = 'NTAX' THEN
		   vl_remarks := 'Tax ';
		   vl_from_client := rec.CLIENT_cD;
		   vl_to_client := 'TAX';
		   vl_from_bank := vl_ip_bank_cd;
		   vl_to_bank := vl_ip_bank_cd;
	   	   vl_from_acct :=rec.RDN;
		   vl_to_acct := rec.RDN;--15 april 2015
		end if;
	
	
		 	 BEGIN
		  INSERT INTO T_FUND_MOVEMENT (
		   DOC_NUM, DOC_DATE, TRX_TYPE,
		   CLIENT_CD, BRCH_CD, SOURCE,
		   DOC_REF_NUM,   TAL_ID_REF, GL_ACCT_CD,
		   SL_ACCT_CD,   BANK_REF_NUM, BANK_MVMT_DATE,
		   acct_name, REMARKS,   FROM_CLIENT,
		   FROM_ACCT, FROM_BANK,   TO_CLIENT,
		   TO_ACCT, TO_BANK,   TRX_AMT,
		   CRE_DT, USER_ID,   APPROVED_DT,
		   APPROVED_STS, APPROVED_BY,   CANCEL_DT,
		   CANCEL_BY, DOC_REF_NUM2,FUND_BANK_CD,
       FUND_BANK_ACCT)
		  VALUES ( vl_doc_num , rec.tanggalefektif, vl_trx_type,
		     rec.client_cd, trim(rec.branch_code), 'MUTASI',
			  NULL,     NULL,     NULL,
			  rec.transactiontype,     substr(rec.bankreference,1,20),   rec.tanggaltimestamp,
			  rec.namanasabah,     vl_remarks,    vl_from_client,
			  vl_from_acct,     vl_from_bank ,  vl_to_client,
		     vl_to_acct,     vl_to_bank,     rec.transactionvalue,
		     SYSDATE,     p_approved_user_id,     sysdate,
		     'A',     p_approved_user_id,     NULL,
		     NULL,     NULL,rec.bankid,
		    vl_from_acct);
		  exception
		  WHEN OTHERS THEN
		   v_error_code := -4;
		   v_error_msg :=  rec.client_cd||' INSERT t_fund_movement '||SQLERRM;
		   raise v_err;
		  end;
	
		  BEGIN
		
		  FOR i IN  1..2
		  LOOP
		
		   IF i = 1 THEN
		               vl_debit   := rec.transactionvalue;
		               vl_credit  := 0;
		            ELSE
		               vl_debit   := 0;
		               vl_credit  :=rec.transactionvalue;
		    END IF;
		
		
		    IF (i = 1 and vl_trx_type = 'R') or (i = 2 and vl_trx_type = 'W') THEN
		  	   vl_fl_acct_cd  := 'DBEBAS';
		 	ELSE
		  		vl_fl_acct_cd  := 'KNPR';
		 	END IF;
		
		   begin
		    INSERT INTO T_FUND_LEDGER (
		     DOC_NUM,  SEQNO, TRX_TYPE,
			 DOC_DATE, ACCT_CD, CLIENT_CD,
			 DEBIT,    CREDIT, CRE_DT,
			 USER_ID,  APPROVED_DT,     APPROVED_STS,
			 APPROVED_BY, CANCEL_DT,     CANCEL_BY,manual)
		    VALUES( vl_doc_num ,      I,      vl_trx_type,
		      rec.tanggalefektif,      vl_fl_acct_cd,      rec.client_cd ,
		      vl_debit,      vl_credit,      SYSDATE ,
		      p_approved_user_id,      sysdate,      'A'
		      ,  p_approved_user_id      ,NULL      ,NULL ,'Y');
		   exception
		     WHEN OTHERS THEN
		    v_error_code := -5;
		    v_error_msg := rec.client_cd||' INSERT t_fund_ledger '||SQLERRM;
		    raise v_err;
		   end;
		  END LOOP;
		  end;

		  vl_cnt := vl_cnt +1;
		  
	end loop;
	
	
  
  BEGIN	
			UPDATE T_MANY_HEADER
			SET approved_status = 'A',
			approved_user_id = p_approved_user_id,
			approved_date = SYSDATE,
			approved_ip_address = p_approved_ip_address
			WHERE menu_name = p_menu_name
			AND update_date = p_update_date
			AND update_seq = p_update_seq;
		EXCEPTION
			WHEN OTHERS THEN
				v_error_code := -6;
				v_error_msg :=  SUBSTR('Update t_MANY_HEADER  '||SQLERRM,1,200);
				RAISE v_err;
		END;	
		

	--------------------END INSERT---------------------------

   -- END IF;
 p_error_code := 1;
p_error_msg := '';
--commit;   
		   
   EXCEPTION
     WHEN NO_DATA_FOUND THEN
       NULL;
	 WHEN v_err THEN
           p_error_code := v_error_code;
		   p_error_msg :=  v_error_msg;
	      ROLLBACK;
	   
     WHEN OTHERS THEN
       ROLLBACK;
	   p_error_code := -1;
	   p_error_msg := SUBSTR(SQLERRM,1,200);
       RAISE;
END SP_FL_BCA_INTEREST_APPROVE;