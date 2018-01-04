create or replace 
PROCEDURE           "SP_T_BANK_MUTASI_APPROVE" (
	   p_menu_name							  	T_MANY_HEADER.menu_name%TYPE,
	   p_update_date							T_MANY_HEADER.update_date%TYPE,
	   p_update_seq								T_MANY_HEADER.update_seq%TYPE,
	   p_approved_user_id				  T_MANY_HEADER.user_id%TYPE,
	   p_approved_ip_address 		 T_MANY_HEADER.ip_address%TYPE,
     
     p_error_code			OUT NUMBER,
	   p_error_msg			OUT VARCHAR2
	 
) IS

/******************************************************************************
   NAME:      SP_T_BANK_MUTASI_APPROVE
   PURPOSE:    

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        23/10/2013          1. Created this procedure.

******************************************************************************/


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

vl_transactiontype t_bank_mutation.transactiontype%type;
--vl_INSTRUCTIONFROM  T_BANK_MUTATION.INSTRUCTIONFROM%type;
vl_ACCT_NAME  T_BANK_MUTATION.namanasabah%type;
vl_TRX_AMT  T_BANK_MUTATION.TRANSACTIONVALUE%type;
vl_typemutasi T_BANK_MUTATION.typemutasi%type;
vl_bank_timestamp T_BANK_MUTATION.TANGGALTIMESTAMP%type;


v_client_cd mst_Client.Client_Cd%type;
v_branch_code  mst_Client.branch_code%type;
v_FROMBANK t_fund_movement.from_bank%TYPE;
v_INSTRUCTIONFROM  T_BANK_MUTATION.INSTRUCTIONFROM%type;
v_remark t_fund_movement.remarks%type;
v_RDN  T_BANK_MUTATION.RDN%type;
v_bankreference T_BANK_MUTATION.BANKREFERENCE%type;
v_tanggalefektif T_BANK_MUTATION.tanggalefektif%type;
v_bankid T_BANK_MUTATION.bankid%type;
v_transactiontype T_BANK_MUTATION.transactiontype%type;

v_status CHAR(1);


v_err EXCEPTION;
v_error_code							NUMBER;
v_error_msg							VARCHAR2(200);

v_table_name varchar(50):='T_FUND_MOVEMENT';
BEGIN



  BEGIN
  SELECT UPD_STATUS INTO v_status from T_MANY_DETAIL where update_seq =  p_update_seq and update_date=p_update_date and rownum=1;
  EXCEPTION
 	    WHEN OTHERS THEN
	   			v_error_code := -2;
				v_error_msg :=  SUBSTR('T_Many_Detail '||SQLERRM,1,200);
				RAISE v_err;
	   END;
	   

		IF v_status <> 'C' then
		BEGIN
		 SELECT MAX(CLIENT_CD),trim(MAX(BRANCH_CODE)), MAX(FROMBANK), MAX(INSTRUCTIONFROM), MAX(REMARK),MAX(RDN),MAX(BANKREFERENCE),MAX(TANGGALEFEKTIF),MAX(BANKID),MAX(TRANSACTIONTYPE)
				 INTO v_client_cd,v_branch_code , v_frombank, v_INSTRUCTIONFROM,v_remark,v_rdn,v_bankreference,v_tanggalefektif,v_bankid,v_transactiontype
				   FROM(
		  		   SELECT DECODE(field_name,'CLIENT_CD',field_value, NULL) CLIENT_CD,
							DECODE(field_name,'BRANCH_CODE',field_value, NULL) BRANCH_CODE,
							DECODE(field_name,'FROMBANK',field_value, NULL) FROMBANK,
							DECODE(field_name,'INSTRUCTIONFROM',field_value, NULL) INSTRUCTIONFROM,
							DECODE(field_name,'REMARK',field_value, NULL) REMARK,
							DECODE(field_name,'RDN',field_value, NULL) RDN,
							DECODE(field_name,'BANKREFERENCE',field_value, NULL) BANKREFERENCE,
							DECODE(field_name,'TANGGALEFEKTIF',field_value, NULL) TANGGALEFEKTIF,
							DECODE(field_name,'BANKID',field_value, NULL) BANKID,
							DECODE(field_name,'TRANSACTIONTYPE',field_value, NULL) TRANSACTIONTYPE
							
				   FROM  T_MANY_DETAIL
				  WHERE T_MANY_DETAIL.update_date = p_update_date
				  AND T_MANY_DETAIL.table_name = v_table_name
				  AND T_MANY_DETAIL.update_seq	 = p_update_seq
				  AND T_MANY_DETAIL.field_name IN ('CLIENT_CD', 'BRANCH_CODE','FROMBANK','INSTRUCTIONFROM','REMARK','RDN','BANKREFERENCE','TANGGALEFEKTIF','BANKID','TRANSACTIONTYPE'));
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

		 IF v_status ='I' then
		 --------------------INSERT---------------------------
	
    select  namanasabah, transactionvalue, typemutasi, tanggaltimestamp
	 into vl_ACCT_NAME, vl_TRX_AMT,vl_typemutasi, vl_bank_timestamp
	 from t_bank_mutation
	 where rdn = v_rdn
	 and bankreference = v_bankreference
	 and tanggalefektif =  TO_DATE(v_tanggalefektif,'YYYY/MM/DD HH24:MI:SS')
	 and bankid = v_bankid
	 and transactiontype = v_transactiontype;
	 
	 
	 if vl_typemutasi = 'C' then
	 	vl_trx_type := 'R';
	 else
	 	vl_trx_type := 'W';
	 end if;
	 
	  vl_doc_num := Get_Docnum_Fvch(TO_DATE(v_tanggalefektif,'YYYY/MM/DD HH24:MI:SS'),vl_trx_type);
	 
	 
	  if v_bankid = 'BNGA3' then
	 	 vl_ip_bank_cd:= 'NGA';
		 vl_remarks :=  v_remark;
		 if   trim(v_transactiontype) = '198' then
		 	 vl_transactiontype :='NTAX';
		elsif  trim(v_transactiontype) = '160' then
		 	 vl_transactiontype :='NINT';
		else
			 vl_transactiontype :='NTRF';
			 --vl_INSTRUCTIONFROM := '-';
		end if;
	end if;

	 if v_bankid = 'BCA02' then
		vl_ip_bank_cd:= 'BCA';
		vl_transactiontype :=v_transactiontype;
		if   trim(v_transactiontype) = 'NTRF' then
			 vl_remarks := 'Setoran '||v_CLIENT_cD;
		end if;
		if   trim(v_transactiontype) = 'NKOR' then
			 vl_remarks := 'Koreksi '||v_CLIENT_cD;
		end if;
			 
		
	end if;
	 
	 
	  if vl_typemutasi = 'C' and vl_transactiontype = 'NTRF' THEN


	   vl_from_client := 'LUAR';
	   vl_to_client := 'FUND';
	   
	   vl_from_bank := v_frombank;
	   
	   vl_to_bank := vl_ip_bank_cd;
	   vl_from_acct := v_INSTRUCTIONFROM;
	   vl_to_acct := v_RDN;
	end if;
	
	
	 if vl_typemutasi = 'C' and vl_transactiontype = 'NKOR' THEN


	   vl_from_client := 'KOREKSI';
	   vl_to_client := 'FUND';
	   
	   vl_from_bank := v_frombank;
	   
	   vl_to_bank := vl_ip_bank_cd;
	   vl_from_acct := v_INSTRUCTIONFROM;
	   vl_to_acct := v_RDN;
	end if;
	 
	 
	 if vl_typemutasi = 'C' and vl_transactiontype = 'NINT' THEN
	   vl_remarks := 'Bunga '||vl_ip_bank_cd;
	   vl_from_client := 'BUNGA';
	   vl_to_client := v_CLIENT_cD;
	   vl_from_bank := vl_ip_bank_cd;
	   vl_to_bank := vl_ip_bank_cd;
	   vl_from_acct := '-';
	   vl_to_acct := v_RDN;
	end if;

	if vl_typemutasi = 'D' and vl_transactiontype = 'NTAX' THEN
	   vl_remarks := 'Tax ';
	   vl_from_client := v_CLIENT_cD;
	   vl_to_client := 'TAX';
	   vl_from_bank := vl_ip_bank_cd;
	   vl_to_bank := vl_ip_bank_cd;
   	   vl_from_acct :=v_RDN;
	   vl_to_acct := '-';
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
  VALUES ( vl_doc_num , TO_DATE(v_tanggalefektif,'YYYY/MM/DD HH24:MI:SS'), vl_trx_type,
     v_client_cd, trim(v_branch_code) , 'MUTASI',
	  NULL,     NULL,     NULL,
	  v_transactiontype,     substr(v_bankreference,1,20),   vl_bank_timestamp,
	  vl_acct_name,     vl_remarks,    vl_from_client,
	  vl_from_acct,     vl_from_bank ,  vl_to_client,
     vl_to_acct,     vl_to_bank,     vl_TRX_AMT,
     SYSDATE,     p_approved_user_id,     sysdate,
     'A',      p_approved_user_id,     NULL,
     NULL,     NULL,v_bankid,
    vl_to_acct);
  exception
  WHEN OTHERS THEN
   v_error_code := -5;
   v_error_msg:=  v_client_cd||' INSERT t_fund_movement '||SQLERRM;
   raise v_err;
  end;

  
  BEGIN

  FOR i IN  1..2
  LOOP

   IF i = 1 THEN
               vl_debit   := vl_TRX_AMT;
               vl_credit  := 0;
            ELSE
               vl_debit   := 0;
               vl_credit  :=vl_TRX_AMT;
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
	 APPROVED_BY, CANCEL_DT,     CANCEL_BY)
    VALUES( vl_doc_num ,      I,      vl_trx_type,
     TO_DATE(v_tanggalefektif,'YYYY/MM/DD HH24:MI:SS'),      vl_fl_acct_cd,      v_client_cd ,
      vl_debit,      vl_credit,      SYSDATE ,
      p_approved_user_id,     sysdate,      'A'
      , p_approved_user_id     ,NULL      ,NULL );
   exception
     WHEN OTHERS THEN
    v_error_code := -6;
    v_error_msg := v_client_cd||' INSERT t_fund_ledger '||SQLERRM;
    raise v_err;
   end;
  END LOOP;
  end;
  
  
  
  
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
				v_error_code := -7;
				v_error_msg :=  SUBSTR('Update t_MANY_HEADER  '||SQLERRM,1,200);
				RAISE v_err;
		END;	
		

	--------------------END INSERT---------------------------

    END IF;
 p_error_code := 1;
p_error_msg := '';
commit;   
		   
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
END SP_T_BANK_MUTASI_APPROVE;