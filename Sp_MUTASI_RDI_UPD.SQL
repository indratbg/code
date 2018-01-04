create or replace 
PROCEDURE Sp_MUTASI_RDI_UPD(
	P_CLIENT_CD MST_CLIENT.CLIENT_CD%TYPE,
	P_BRCH_CD MST_CLIENT.BRANCH_CODE%TYPE,
	P_FROMBANK t_fund_movement.from_bank%TYPE,
	--P_KODEAB		T_BANK_MUTATION.KODEAB%TYPE,
	--P_NAMAAB		T_BANK_MUTATION.NAMAAB%TYPE,
	P_RDN		T_BANK_MUTATION.RDN%TYPE,
	--P_SID		T_BANK_MUTATION.SID%TYPE,
	--P_SRE		T_BANK_MUTATION.SRE%TYPE,
	P_NAMANASABAH		T_BANK_MUTATION.NAMANASABAH%TYPE,
	P_TANGGALEFEKTIF		T_BANK_MUTATION.TANGGALEFEKTIF%TYPE,
	P_TANGGALTIMESTAMP		T_BANK_MUTATION.TANGGALTIMESTAMP%TYPE,
	P_INSTRUCTIONFROM		T_BANK_MUTATION.INSTRUCTIONFROM%TYPE,
	--P_COUNTERPARTACCOUNT		T_BANK_MUTATION.COUNTERPARTACCOUNT%TYPE,
	P_TYPEMUTASI		T_BANK_MUTATION.TYPEMUTASI%TYPE,
	P_TRANSACTIONTYPE		T_BANK_MUTATION.TRANSACTIONTYPE%TYPE,
	--P_CURRENCY		T_BANK_MUTATION.CURRENCY%TYPE,
	--P_BEGINNINGBALANCE		T_BANK_MUTATION.BEGINNINGBALANCE%TYPE,
	P_TRANSACTIONVALUE		T_BANK_MUTATION.TRANSACTIONVALUE%TYPE,
	--P_CLOSINGBALANCE		T_BANK_MUTATION.CLOSINGBALANCE%TYPE,
	P_REMARK		T_BANK_MUTATION.REMARK%TYPE,
	P_BANKREFERENCE		T_BANK_MUTATION.BANKREFERENCE%TYPE,
	P_BANKID		T_BANK_MUTATION.BANKID%TYPE,
	--P_IMPORTSEQ		T_BANK_MUTATION.IMPORTSEQ%TYPE,
--	P_IMPORTDATE		T_BANK_MUTATION.IMPORTDATE%TYPE,
  P_USER_ID T_FUND_MOVEMENT.USER_ID%TYPE,
	P_UPD_STATUS					T_MANY_DETAIL.UPD_STATUS%TYPE,
	p_ip_address					T_MANY_HEADER.IP_ADDRESS%TYPE,
	p_cancel_reason					T_MANY_HEADER.CANCEL_REASON%TYPE,
	p_update_date					T_MANY_HEADER.UPDATE_DATE%TYPE,
	p_update_seq					T_MANY_HEADER.UPDATE_SEQ%TYPE,
	p_record_seq					T_MANY_DETAIL.RECORD_SEQ%TYPE,
	p_error_code					OUT			NUMBER,
	p_error_msg						OUT			VARCHAR2
) IS




Vl_DOC_NUM T_FUND_LEDGER.doc_num%TYPE;
--vl_debit  T_FUND_LEDGER.debit%TYPE;
--vl_credit  T_FUND_LEDGER.credit%TYPE;
--vl_fl_acct_cd T_FUND_LEDGER.acct_cd%TYPE;
--vl_bank_Cd mst_fund_bank.bank_Cd%TYPE;

vl_trx_type t_fund_movement.trx_type%type;
--vl_remarks t_fund_movement.remarks%type;
VL_FROM_BANK t_fund_movement.from_bank%TYPE;
VL_to_BANK t_fund_movement.to_bank%TYPE;
VL_FROM_acct t_fund_movement.from_acct%TYPE;
VL_TO_ACCT t_fund_movement.to_acct%TYPE;
VL_FROM_CLIENT t_fund_movement.from_client%TYPE;
VL_TO_CLIENT t_fund_movement.to_client%TYPE;
vl_ip_bank_cd t_fund_movement.to_bank%TYPE;

vl_transactiontype t_bank_mutation.transactiontype%type;
--vl_INSTRUCTIONFROM  T_BANK_MUTATION.INSTRUCTIONFROM%type;
--vl_ACCT_NAME  T_BANK_MUTATION.namanasabah%type;
--vl_TRX_AMT  T_BANK_MUTATION.TRANSACTIONVALUE%type;

--vl_bank_timestamp T_BANK_MUTATION.TANGGALTIMESTAMP%type;

	v_err EXCEPTION;
	v_error_code				NUMBER;
	v_error_msg					VARCHAR2(1000);
	v_table_name 				T_MANY_DETAIL.table_name%TYPE := 'T_FUND_MOVEMENT';
	v_status        		    T_MANY_DETAIL.upd_status%TYPE;
	v_table_rowid	   			T_MANY_DETAIL.table_rowid%TYPE;

CURSOR csr_MANY_DETAIL IS
SELECT      column_id, column_name AS field_name,
                       DECODE(data_type,'VARCHAR2','S','CHAR','S','NUMBER','N','DATE','D','X') AS field_type
FROM all_tab_columns
WHERE table_name =v_table_name
AND OWNER = 'IPNEXTG';

CURSOR csr_table IS
SELECT *
FROM T_FUND_MOVEMENT
WHERE DOC_NUM= '';

v_MANY_DETAIL  Types.MANY_DETAIL_rc;

v_rec T_FUND_MOVEMENT%ROWTYPE;

v_cnt INTEGER;
 i INTEGER;
 V_FIELD_CNT NUMBER;
 v_pending_cnt NUMBER;
 va CHAR(1) := '@';
BEGIN


 
	 if P_TYPEMUTASI = 'C' then
	 	vl_trx_type := 'R';
	 else
	 	vl_trx_type := 'W';
	 end if;
	 
	 
	 -- vl_doc_num := Get_Docnum_Fvch(TO_DATE(P_TANGGALEFEKTIF,'YYYY/MM/DD HH24:MI:SS'),vl_trx_type);
	 
	  if P_bankid = 'BNGA3' then
	 	 vl_ip_bank_cd:= 'NGA';
		-- vl_remarks :=  P_REMARK;
		 if   trim(P_TRANSACTIONTYPE) = '198' then
		 	 vl_transactiontype :='NTAX';
		elsif  trim(P_TRANSACTIONTYPE) = '160' then
		 	 vl_transactiontype :='NINT';
		else
			 vl_transactiontype :='NTRF';
			 --vl_INSTRUCTIONFROM := '-';
		end if;
	end if;

	 if P_bankid = 'BCA02' then
		vl_ip_bank_cd:= 'BCA';
		vl_transactiontype :=P_TRANSACTIONTYPE;
	--	if   trim(P_TRANSACTIONTYPE) = 'NTRF' then
			-- vl_remarks := 'Setoran '||p_CLIENT_cD;
		--end if;
		--if   trim(P_TRANSACTIONTYPE) = 'NKOR' then
			-- vl_remarks := 'Koreksi '||p_CLIENT_cD;
		--end if;
			 
		
	end if;
	 
	 
	  if P_TYPEMUTASI = 'C' and vl_transactiontype = 'NTRF' THEN


	   vl_from_client := 'LUAR';
	   vl_to_client := 'FUND';
	   
	   vl_from_bank := p_frombank;
	   
	   vl_to_bank := vl_ip_bank_cd;
	   vl_from_acct := p_INSTRUCTIONFROM;
	   vl_to_acct := P_RDN;
	end if;
	
	
	 if P_TYPEMUTASI = 'C' and vl_transactiontype = 'NKOR' THEN


	   vl_from_client := 'KOREKSI';
	   vl_to_client := 'FUND';
	   
	   vl_from_bank := p_frombank;
	   
	   vl_to_bank := vl_ip_bank_cd;
	   vl_from_acct := p_INSTRUCTIONFROM;
	   vl_to_acct := P_RDN;
	end if;
	 
	 
	 if P_TYPEMUTASI = 'C' and vl_transactiontype = 'NINT' THEN
	  -- vl_remarks := 'Bunga '||vl_ip_bank_cd;
	   vl_from_client := 'BUNGA';
	   vl_to_client := p_CLIENT_cD;
	   vl_from_bank := vl_ip_bank_cd;
	   VL_TO_BANK := VL_IP_BANK_CD;
	   vl_from_acct := P_RDN;
	   vl_to_acct := P_RDN;
	end if;

	if P_TYPEMUTASI = 'D' and vl_transactiontype = 'NTAX' THEN
	 --  vl_remarks := 'Tax ';
	   vl_from_client := p_CLIENT_cD;
	   vl_to_client := 'TAX';
	   vl_from_bank := vl_ip_bank_cd;
	   vl_to_bank := vl_ip_bank_cd;
   	   VL_FROM_ACCT :=P_RDN;
	   vl_to_acct := P_RDN;
	end if;

	OPEN csr_Table;
	FETCH csr_Table INTO v_rec;

	OPEN v_MANY_DETAIL FOR
		SELECT p_update_date AS update_date, p_update_seq AS update_seq, table_name, p_record_seq AS record_seq, v_table_rowid AS table_rowid, a.field_name,  field_type, b.field_value, p_upd_status AS status,  b.upd_flg
		FROM(
			SELECT  v_table_name AS table_name, column_name AS field_name, 
                  DECODE(data_type,'VARCHAR2','S','CHAR','S','NUMBER','N','DATE','D','X') AS field_type
			FROM all_tab_columns
			WHERE table_name = v_table_name
			AND OWNER = 'IPNEXTG'
      	UNION
      SELECT v_table_name, 'TYPEMUTASI', 'S' FROM dual
	
      ) a,
		( 	SELECT  'TYPEMUTASI'  AS field_name, P_TYPEMUTASI AS field_value, 'X' upd_flg FROM dual
    UNION
    SELECT  'DOC_NUM'  AS field_name,  vl_doc_num AS field_value,DECODE(trim(v_rec.TRX_TYPE), trim(vl_doc_num),'N','Y') upd_flg FROM dual
UNION
SELECT  'DOC_DATE'  AS field_name, TO_CHAR(p_TANGGALEFEKTIF,'yyyy/mm/dd hh24:mi:ss')  AS field_value, DECODE(v_rec.DOC_DATE, p_TANGGALEFEKTIF,'N','Y') upd_flg FROM dual
UNION
SELECT  'TRX_TYPE'  AS field_name, vl_trx_type AS field_value, DECODE(trim(v_rec.TRX_TYPE), trim(vl_trx_type),'N','Y') upd_flg FROM dual
UNION
SELECT  'CLIENT_CD'  AS field_name, p_CLIENT_CD AS field_value, DECODE(trim(v_rec.CLIENT_CD), trim(p_CLIENT_CD),'N','Y') upd_flg FROM dual
UNION
SELECT  'BRCH_CD'  AS field_name, p_BRCH_CD AS field_value, DECODE(trim(v_rec.BRCH_CD), trim(p_BRCH_CD),'N','Y') upd_flg FROM dual
UNION
SELECT  'SOURCE'  AS field_name, 'MUTASI' AS field_value,  'N' upd_flg FROM dual
UNION
SELECT  'DOC_REF_NUM'  AS field_name, '' AS field_value,  'N' upd_flg FROM dual
UNION
SELECT  'TAL_ID_REF'  AS field_name, ''  AS field_value, 'N' upd_flg FROM dual
UNION
SELECT  'GL_ACCT_CD'  AS field_name,'' AS field_value, 'N' upd_flg FROM dual
UNION
SELECT  'SL_ACCT_CD'  AS field_name, vl_transactiontype AS field_value, DECODE(trim(v_rec.SL_ACCT_CD), trim(vl_transactiontype),'N','Y') upd_flg FROM dual
UNION
SELECT  'BANK_REF_NUM'  AS field_name, substr(P_BANKREFERENCE,1,20) AS field_value, DECODE(trim(v_rec.BANK_REF_NUM), trim(substr(P_BANKREFERENCE,1,20)),'N','Y') upd_flg FROM dual
UNION
SELECT  'BANK_MVMT_DATE'  AS field_name, TO_CHAR(P_TANGGALTIMESTAMP,'yyyy/mm/dd hh24:mi:ss')  AS field_value, DECODE(v_rec.BANK_MVMT_DATE, P_TANGGALTIMESTAMP,'N','Y') upd_flg FROM dual
UNION
SELECT  'ACCT_NAME'  AS field_name, P_NAMANASABAH AS field_value, DECODE(trim(v_rec.ACCT_NAME), trim(P_NAMANASABAH),'N','Y') upd_flg FROM dual
UNION
SELECT  'REMARKS'  AS field_name, p_REMARK AS field_value, DECODE(trim(v_rec.REMARKS), trim(p_REMARK),'N','Y') upd_flg FROM dual
UNION
SELECT  'FROM_CLIENT'  AS field_name, vl_from_client AS field_value, DECODE(trim(v_rec.FROM_CLIENT), trim(vl_from_client),'N','Y') upd_flg FROM dual
UNION
SELECT  'FROM_ACCT'  AS field_name, vl_from_acct AS field_value,DECODE(trim(v_rec.FROM_ACCT), trim(vl_from_acct),'N','Y') upd_flg FROM dual
UNION
SELECT  'FROM_BANK'  AS field_name, vl_from_bank AS field_value, DECODE(trim(v_rec.FROM_BANK), trim(vl_from_bank),'N','Y') upd_flg FROM dual
UNION
SELECT  'TO_CLIENT'  AS field_name, vl_to_client AS field_value, DECODE(trim(v_rec.TO_CLIENT), trim(vl_to_client),'N','Y') upd_flg FROM dual
UNION
SELECT  'TO_ACCT'  AS field_name, vl_to_acct AS field_value, DECODE(trim(v_rec.TO_ACCT), trim(vl_to_acct),'N','Y') upd_flg FROM dual
UNION
SELECT  'TO_BANK'  AS field_name,vl_to_bank AS field_value,DECODE(trim(v_rec.TO_BANK), trim(vl_to_bank),'N','Y') upd_flg FROM dual
UNION
SELECT  'TRX_AMT'  AS field_name, TO_CHAR	(P_TRANSACTIONVALUE)  AS field_value, DECODE(v_rec.TRX_AMT,	P_TRANSACTIONVALUE,'N','Y') upd_flg FROM dual
UNION
SELECT  'CRE_DT'  AS field_name, TO_CHAR(SYSDATE,'yyyy/mm/dd hh24:mi:ss')  AS field_value, DECODE(v_rec.CRE_DT, SYSDATE,'N','Y') upd_flg FROM dual
UNION
SELECT  'USER_ID'  AS field_name, p_USER_ID AS field_value, DECODE(trim(v_rec.USER_ID), trim(p_USER_ID),'N','Y') upd_flg FROM dual
UNION
SELECT  'CANCEL_DT'  AS field_name, '' AS field_value, 'N' upd_flg FROM dual
UNION
SELECT  'CANCEL_BY'  AS field_name,'' AS field_value, 'N' upd_flg FROM dual
UNION
SELECT  'DOC_REF_NUM2'  AS field_name,'' AS field_value, 'N' upd_flg FROM dual
UNION
SELECT  'FEE'  AS field_name, ''  AS field_value, 'N' upd_flg FROM dual
UNION
SELECT  'FOLDER_CD'  AS field_name,'' AS field_value, 'N' upd_flg FROM dual
UNION
SELECT  'FUND_BANK_CD'  AS field_name, P_BANKID AS field_value, DECODE(trim(v_rec.FUND_BANK_CD), trim(P_BANKID),'N','Y') upd_flg FROM dual
UNION
SELECT  'FUND_BANK_ACCT'  AS field_name, vl_to_acct AS field_value, DECODE(trim(v_rec.FUND_BANK_ACCT), trim(vl_to_acct),'N','Y')  upd_flg FROM dual
UNION
SELECT  'REVERSAL_JUR'  AS field_name, '' AS field_value, 'N' upd_flg FROM dual
UNION
SELECT  'UPD_DT'  AS field_name,''  AS field_value, 'N' upd_flg FROM dual
UNION
SELECT  'UPD_BY'  AS field_name,'' AS field_value,'N' upd_flg FROM dual


		) b
		WHERE a.field_name = b.field_name;
	BEGIN
		Sp_T_Many_Detail_Insert(p_update_date,   p_update_seq,   'I', 'T_FUND_MOVEMENT', p_record_seq , v_table_rowid, v_MANY_DETAIL, v_error_code, v_error_msg);
	EXCEPTION
		WHEN OTHERS THEN
			v_error_code := -7;
			v_error_msg := SUBSTR('SP_T_MANY_DETAIL_INSERT '||v_table_name||SQLERRM,1,200);
			RAISE v_err;
	END;

	CLOSE v_MANY_DETAIL;
	CLOSE csr_Table;

	IF v_error_code < 0 THEN
	    v_error_code := -8;
		v_error_msg := 'SP_T_MANY_DETAIL_INSERT '||v_table_name||' '||v_error_msg;
		RAISE v_err;
	END IF;

--COMMIT;
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

END Sp_MUTASI_RDI_UPD;