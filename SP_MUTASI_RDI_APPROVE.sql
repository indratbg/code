create or replace 
PROCEDURE         SP_MUTASI_RDI_APPROVE  (
	   p_menu_name							  	T_MANY_HEADER.menu_name%TYPE,
	   p_update_date							T_MANY_HEADER.update_date%TYPE,
	   p_update_seq								T_MANY_HEADER.update_seq%TYPE,
	   p_approved_user_id				  T_MANY_HEADER.user_id%TYPE,
	   p_approved_ip_address 		 T_MANY_HEADER.ip_address%TYPE,
		p_error_code			OUT NUMBER,
	   p_error_msg			OUT VARCHAR2

) IS

/******************************************************************************
   NAME:      SP_MUTASI_RDI_APPROVE
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


v_doc_num t_fund_movement.doc_num%TYPE;
v_doc_date t_fund_movement.doc_date%type;
v_trx_type t_fund_movement.trx_type%type;
v_source t_fund_movement.source%type;
v_sl_acct_cd t_fund_movement.sl_acct_cd%type;
v_bank_ref_num t_fund_movement.bank_ref_num%type;
v_bank_mvmt_date t_fund_movement.bank_mvmt_date%type;
v_acct_name t_fund_movement.acct_name%type;
v_remarks t_fund_movement.remarks%type;
v_from_client t_fund_movement.from_client%TYPE;
v_to_client t_fund_movement.to_client%TYPE;
v_to_acct t_fund_movement.to_acct%TYPE;
v_to_bank t_fund_movement.to_bank%type;
v_trx_amt t_fund_movement.trx_amt%type;
v_user_id t_fund_movement.user_id%TYPE;
v_fund_bank_cd t_fund_movement.fund_bank_cd%type;
v_fund_bank_acct t_fund_movement.fund_bank_acct%type;
v_from_acct t_fund_movement.from_acct%TYPE;
v_from_bank t_fund_movement.from_bank%TYPE;
v_typemutasi t_bank_mutation.typemutasi%type;
vl_trx_type t_fund_movement.trx_type%type;



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
		 SELECT MAX(DOC_NUM), MAX(DOC_DATE),MAX(TRX_TYPE), MAX(CLIENT_CD),MAX(BRCH_CD),
				MAX(SOURCE),MAX(SL_ACCT_CD), MAX(BANK_REF_NUM), MAX(BANK_MVMT_DATE), MAX(ACCT_NAME),
				MAX(REMARKS),MAX(FROM_CLIENT),MAX(FROM_ACCT),MAX(FROM_BANK),MAX(TO_CLIENT),MAX(TO_ACCT),MAX(TO_BANK),
				MAX(TRX_AMT),MAX(USER_ID),MAX(FUND_BANK_CD),MAX(FUND_BANK_ACCT),MAX(TYPEMUTASI)
				 INTO v_doc_num,v_doc_date,v_trx_type,v_client_cd,v_branch_code,
						v_source,v_sl_acct_cd,v_bank_ref_num,v_bank_mvmt_date,v_acct_name,
						v_remarks,v_from_client,v_from_acct,v_from_bank,v_to_client,v_to_acct,v_to_bank,
						v_trx_amt,v_user_id,v_fund_bank_cd,v_fund_bank_acct,v_typemutasi
				   FROM(
		  		   SELECT DECODE(field_name,'DOC_NUM',field_value, NULL) DOC_NUM,
							DECODE(field_name,'DOC_DATE',field_value, NULL) DOC_DATE,
							DECODE(field_name,'TRX_TYPE',field_value, NULL) TRX_TYPE,
							DECODE(field_name,'CLIENT_CD',field_value, NULL) CLIENT_CD,
							DECODE(field_name,'BRCH_CD',field_value, NULL) BRCH_CD,
							DECODE(field_name,'SOURCE',field_value, NULL) SOURCE,
							DECODE(field_name,'SL_ACCT_CD',field_value, NULL) SL_ACCT_CD,
							DECODE(field_name,'BANK_REF_NUM',field_value, NULL) BANK_REF_NUM,
							DECODE(field_name,'BANK_MVMT_DATE',field_value, NULL) BANK_MVMT_DATE,
							DECODE(field_name,'ACCT_NAME',field_value, NULL) ACCT_NAME,
							DECODE(field_name,'REMARKS',field_value, NULL) REMARKS,
							DECODE(field_name,'FROM_CLIENT',field_value, NULL) FROM_CLIENT,
							DECODE(field_name,'FROM_ACCT',field_value, NULL) FROM_ACCT,
							DECODE(field_name,'FROM_BANK',field_value, NULL) FROM_BANK,
							DECODE(field_name,'TO_CLIENT',field_value, NULL) TO_CLIENT,
							DECODE(field_name,'TO_ACCT',field_value, NULL) TO_ACCT,
							DECODE(field_name,'TO_BANK',field_value, NULL) TO_BANK,
							DECODE(field_name,'TRX_AMT',field_value, NULL) TRX_AMT,
							DECODE(field_name,'USER_ID',field_value, NULL) USER_ID,
							DECODE(field_name,'FUND_BANK_CD',field_value, NULL) FUND_BANK_CD,
							DECODE(field_name,'FUND_BANK_ACCT',field_value, NULL) FUND_BANK_ACCT,
							DECODE(field_name,'TYPEMUTASI',field_value, NULL) TYPEMUTASI

				   FROM  T_MANY_DETAIL
				  WHERE T_MANY_DETAIL.update_date = p_update_date
				  AND T_MANY_DETAIL.table_name = v_table_name
				  AND T_MANY_DETAIL.update_seq	 = p_update_seq
				  AND T_MANY_DETAIL.field_name IN ('DOC_NUM','DOC_DATE','TRX_TYPE','CLIENT_CD','BRCH_CD','SOURCE','SL_ACCT_CD','BANK_REF_NUM','BANK_MVMT_DATE','ACCT_NAME','REMARKS','FROM_CLIENT','FROM_ACCT','FROM_BANK','TO_CLIENT','TO_ACCT','TO_BANK','TRX_AMT','USER_ID','FUND_BANK_CD','FUND_BANK_ACCT','TYPEMUTASI'));
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

   if v_TYPEMUTASI = 'C' then
	 	vl_trx_type := 'R';
	 else
	 	vl_trx_type := 'W';
	 end if;


	  vl_doc_num := Get_Docnum_Fund(TO_DATE(v_doc_date,'YYYY/MM/DD HH24:MI:SS'),vl_trx_type);

  BEGIN
  update t_many_detail set field_value= vl_doc_num where update_seq=p_update_seq and update_date=p_UPDATE_date and field_name='DOC_NUM';
  EXCEPTION
		WHEN OTHERS THEN
			v_error_code := -5;
			v_error_msg := 'T_MANY_DETAIL '||SQLERRM;
			RAISE v_err;
	END;

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
  VALUES ( vl_doc_num , v_doc_date, v_trx_type,
     v_client_cd, trim(v_branch_code) , v_source,
	  NULL,     NULL,     NULL,
	  v_sl_acct_cd, v_bank_ref_num, v_bank_mvmt_date,
	  v_acct_name,     v_remarks,    v_from_client,
	  v_from_acct,     v_from_bank ,  v_to_client,
     v_to_acct,     v_to_bank,     v_TRX_AMT,
     SYSDATE,     p_approved_user_id,     sysdate,
     'A',      p_approved_user_id,     NULL,
     NULL,     NULL,v_fund_bank_cd,
    v_fund_bank_acct);
  exception
  WHEN OTHERS THEN
   v_error_code := -6;
   v_error_msg:=  v_client_cd||' INSERT t_fund_movement '||SQLERRM;
   raise v_err;
  end;

  BEGIN

  FOR i IN  1..2
  LOOP

   IF i = 1 THEN
               vl_debit   := v_TRX_AMT;
               vl_credit  := 0;
            ELSE
               vl_debit   := 0;
               vl_credit  :=v_TRX_AMT;
    END IF;


    IF (i = 1 and v_trx_type = 'R') or (i = 2 and v_trx_type = 'W') THEN
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
    VALUES( vl_doc_num ,      I,      v_trx_type,
     v_doc_date,      vl_fl_acct_cd,      v_client_cd ,
      vl_debit,      vl_credit,      SYSDATE ,
      p_approved_user_id,     sysdate,      'A'
      , p_approved_user_id     ,NULL      ,NULL,'Y' );
   exception
     WHEN OTHERS THEN
    v_error_code := -7;
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
				v_error_code := -8;
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
END SP_MUTASI_RDI_APPROVE;