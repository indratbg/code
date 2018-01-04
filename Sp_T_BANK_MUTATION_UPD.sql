create or replace 
PROCEDURE Sp_T_BANK_MUTATION_UPD(
	P_SEARCH_RDN		T_BANK_MUTATION.RDN%TYPE,
	P_SEARCH_BANKREFERENCE T_BANK_MUTATION.BANKREFERENCE%TYPE,
	P_SEARCH_TANGGALEFEKTIF T_BANK_MUTATION.TANGGALEFEKTIF%TYPE,
	P_SEARCH_BANKID T_BANK_MUTATION.BANKID%TYPE,
	P_SEARCH_TRANSACTIONTYPE T_BANK_MUTATION.TRANSACTIONTYPE%TYPE,
	P_CLIENT_CD MST_CLIENT.CLIENT_CD%TYPE,
	P_BRCH_CD MST_CLIENT.BRANCH_CODE%TYPE,
  P_FROMBANK t_fund_movement.from_bank%TYPE,
	P_KODEAB		T_BANK_MUTATION.KODEAB%TYPE,
	P_NAMAAB		T_BANK_MUTATION.NAMAAB%TYPE,
	P_RDN		T_BANK_MUTATION.RDN%TYPE,
	P_SID		T_BANK_MUTATION.SID%TYPE,
	P_SRE		T_BANK_MUTATION.SRE%TYPE,
	P_NAMANASABAH		T_BANK_MUTATION.NAMANASABAH%TYPE,
	P_TANGGALEFEKTIF		T_BANK_MUTATION.TANGGALEFEKTIF%TYPE,
	P_TANGGALTIMESTAMP		T_BANK_MUTATION.TANGGALTIMESTAMP%TYPE,
	P_INSTRUCTIONFROM		T_BANK_MUTATION.INSTRUCTIONFROM%TYPE,
	P_COUNTERPARTACCOUNT		T_BANK_MUTATION.COUNTERPARTACCOUNT%TYPE,
	P_TYPEMUTASI		T_BANK_MUTATION.TYPEMUTASI%TYPE,
	P_TRANSACTIONTYPE		T_BANK_MUTATION.TRANSACTIONTYPE%TYPE,
	P_CURRENCY		T_BANK_MUTATION.CURRENCY%TYPE,
	P_BEGINNINGBALANCE		T_BANK_MUTATION.BEGINNINGBALANCE%TYPE,
	P_TRANSACTIONVALUE		T_BANK_MUTATION.TRANSACTIONVALUE%TYPE,
	P_CLOSINGBALANCE		T_BANK_MUTATION.CLOSINGBALANCE%TYPE,
	P_REMARK		T_BANK_MUTATION.REMARK%TYPE,
	P_BANKREFERENCE		T_BANK_MUTATION.BANKREFERENCE%TYPE,
	P_BANKID		T_BANK_MUTATION.BANKID%TYPE,
	P_IMPORTSEQ		T_BANK_MUTATION.IMPORTSEQ%TYPE,
	P_IMPORTDATE		T_BANK_MUTATION.IMPORTDATE%TYPE,
	P_UPD_STATUS					T_MANY_DETAIL.UPD_STATUS%TYPE,
	p_ip_address					T_MANY_HEADER.IP_ADDRESS%TYPE,
	p_cancel_reason					T_MANY_HEADER.CANCEL_REASON%TYPE,
	p_update_date					T_MANY_HEADER.UPDATE_DATE%TYPE,
	p_update_seq					T_MANY_HEADER.UPDATE_SEQ%TYPE,
	p_record_seq					T_MANY_DETAIL.RECORD_SEQ%TYPE,
	p_error_code					OUT			NUMBER,
	p_error_msg						OUT			VARCHAR2
) IS



	v_err EXCEPTION;
	v_error_code				NUMBER;
	v_error_msg					VARCHAR2(1000);
	v_table_name 				T_MANY_DETAIL.table_name%TYPE := 'T_BANK_MUTATION';
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
FROM T_BANK_MUTATION
WHERE RDN= P_SEARCH_RDN
	AND BANKREFERENCE=P_SEARCH_BANKREFERENCE
	AND TANGGALEFEKTIF=P_SEARCH_TANGGALEFEKTIF
	AND BANKID=P_SEARCH_BANKID
	AND TRANSACTIONTYPE=P_SEARCH_TRANSACTIONTYPE;

v_MANY_DETAIL  Types.MANY_DETAIL_rc;

v_rec T_BANK_MUTATION%ROWTYPE;

v_cnt INTEGER;
 i INTEGER;
 V_FIELD_CNT NUMBER;
 v_pending_cnt NUMBER;
 va CHAR(1) := '@';
BEGIN


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
		SELECT v_table_name, 'CLIENT_CD', 'S' FROM dual
		UNION
		SELECT v_table_name, 'BRANCH_CODE', 'S' FROM dual
    	UNION
		SELECT v_table_name, 'FROMBANK', 'S' FROM dual
    	UNION
		SELECT v_table_name, 'CLIENT_NAME', 'S' FROM dual
      
      ) a,
		( 	SELECT  'CLIENT_CD'  AS field_name, p_CLIENT_CD AS field_value, 'X' upd_flg FROM dual
			UNION
			SELECT 'BRANCH_CODE'  AS field_name, p_BRCH_CD AS field_value, 'X' upd_flg FROM dual
			UNION
      SELECT  'FROMBANK'  AS field_name, P_FROMBANK AS field_value, 'X' upd_flg FROM dual
			UNION
      SELECT  'CLIENT_NAME'  AS field_name, p_NAMANASABAH AS field_value, 'X' upd_flg FROM dual
      UNION
			SELECT  'KODEAB'  AS field_name, p_KODEAB AS field_value, DECODE(trim(v_rec.KODEAB), trim(p_KODEAB),'N','Y') upd_flg FROM dual
			UNION
			SELECT  'NAMAAB'  AS field_name, p_NAMAAB AS field_value, DECODE(trim(v_rec.NAMAAB), trim(p_NAMAAB),'N','Y') upd_flg FROM dual
			UNION
			SELECT  'RDN'  AS field_name, p_RDN AS field_value, DECODE(trim(v_rec.RDN), trim(p_RDN),'N','Y') upd_flg FROM dual
			UNION
			SELECT  'SID'  AS field_name, p_SID AS field_value, DECODE(trim(v_rec.SID), trim(p_SID),'N','Y') upd_flg FROM dual
			UNION
			SELECT  'SRE'  AS field_name, p_SRE AS field_value, DECODE(trim(v_rec.SRE), trim(p_SRE),'N','Y') upd_flg FROM dual
			UNION
			SELECT  'NAMANASABAH'  AS field_name, p_NAMANASABAH AS field_value, DECODE(trim(v_rec.NAMANASABAH), trim(p_NAMANASABAH),'N','Y') upd_flg FROM dual
			UNION
			SELECT  'TANGGALEFEKTIF'  AS field_name, TO_CHAR(p_TANGGALEFEKTIF,'yyyy/mm/dd hh24:mi:ss')  AS field_value, DECODE(v_rec.TANGGALEFEKTIF, p_TANGGALEFEKTIF,'N','Y') upd_flg FROM dual
			UNION
			SELECT  'TANGGALTIMESTAMP'  AS field_name, TO_CHAR(p_TANGGALTIMESTAMP,'yyyy/mm/dd hh24:mi:ss')  AS field_value, DECODE(v_rec.TANGGALTIMESTAMP, p_TANGGALTIMESTAMP,'N','Y') upd_flg FROM dual
			UNION
			SELECT  'INSTRUCTIONFROM'  AS field_name, p_INSTRUCTIONFROM AS field_value, DECODE(trim(v_rec.INSTRUCTIONFROM), trim(p_INSTRUCTIONFROM),'N','Y') upd_flg FROM dual
			UNION
			SELECT  'COUNTERPARTACCOUNT'  AS field_name, p_COUNTERPARTACCOUNT AS field_value, DECODE(trim(v_rec.COUNTERPARTACCOUNT), trim(p_COUNTERPARTACCOUNT),'N','Y') upd_flg FROM dual
			UNION
			SELECT  'TYPEMUTASI'  AS field_name, p_TYPEMUTASI AS field_value, DECODE(trim(v_rec.TYPEMUTASI), trim(p_TYPEMUTASI),'N','Y') upd_flg FROM dual
			UNION
			SELECT  'TRANSACTIONTYPE'  AS field_name, p_TRANSACTIONTYPE AS field_value, DECODE(trim(v_rec.TRANSACTIONTYPE), trim(p_TRANSACTIONTYPE),'N','Y') upd_flg FROM dual
			UNION
			SELECT  'CURRENCY'  AS field_name, p_CURRENCY AS field_value, DECODE(trim(v_rec.CURRENCY), trim(p_CURRENCY),'N','Y') upd_flg FROM dual
			UNION
			SELECT  'BEGINNINGBALANCE'  AS field_name, TO_CHAR(p_BEGINNINGBALANCE)  AS field_value, DECODE(v_rec.BEGINNINGBALANCE, p_BEGINNINGBALANCE,'N','Y') upd_flg FROM dual
			UNION
			SELECT  'TRANSACTIONVALUE'  AS field_name, TO_CHAR(p_TRANSACTIONVALUE)  AS field_value, DECODE(v_rec.TRANSACTIONVALUE, p_TRANSACTIONVALUE,'N','Y') upd_flg FROM dual
			UNION
			SELECT  'CLOSINGBALANCE'  AS field_name, TO_CHAR(p_CLOSINGBALANCE)  AS field_value, DECODE(v_rec.CLOSINGBALANCE, p_CLOSINGBALANCE,'N','Y') upd_flg FROM dual
			UNION
			SELECT  'REMARK'  AS field_name, p_REMARK AS field_value, DECODE(trim(v_rec.REMARK), trim(p_REMARK),'N','Y') upd_flg FROM dual
			UNION
			SELECT  'BANKREFERENCE'  AS field_name, p_BANKREFERENCE AS field_value, DECODE(trim(v_rec.BANKREFERENCE), trim(p_BANKREFERENCE),'N','Y') upd_flg FROM dual
			UNION
			SELECT  'BANKID'  AS field_name, p_BANKID AS field_value, DECODE(trim(v_rec.BANKID), trim(p_BANKID),'N','Y') upd_flg FROM dual
			UNION
			SELECT  'IMPORTSEQ'  AS field_name, TO_CHAR(p_IMPORTSEQ)  AS field_value, DECODE(v_rec.IMPORTSEQ, p_IMPORTSEQ,'N','Y') upd_flg FROM dual
			UNION
			SELECT  'IMPORTDATE'  AS field_name, TO_CHAR(p_IMPORTDATE,'yyyy/mm/dd hh24:mi:ss')  AS field_value, DECODE(v_rec.IMPORTDATE, p_IMPORTDATE,'N','Y') upd_flg FROM dual

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

END Sp_T_BANK_MUTATION_UPD;