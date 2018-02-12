create or replace PROCEDURE         SP_Fund_Bank_Mvmt_Import (
p_bank_cd MST_FUND_BANK.bank_cd%TYPE,
p_importseq NUMBER,
p_data varchar2,
vo_eff_dt OUT DATE,
VO_FAIL OUT NUMBER,
vo_errcd OUT NUMBER,
vo_errmsg OUT varchar2) IS
/******************************************************************************
   NAME:       FUND_BANK_MVMT_IMPORT
   PURPOSE:

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        24/07/2012          1. Created this procedure.
              19/04/2013 kalo invalid SID / SUBREK tetap masuk ke T_BANK_MUTATION
			             dan T_BANK_MUTATION_FAIL

******************************************************************************/
--p_data t_fund_bank_format.coldesc%type,
CURSOR csr_fmt(a_bank_cd MST_FUND_BANK.bank_cd%TYPE) IS
SELECT
BANK_CD, LINE_TYPE, COLSEQ,
   COLTYPE, COLWIDTH, COLFMT,
   COLDESC, FIELDSEQ
FROM T_FUND_BANK_FORMAT
WHERE bank_cd = a_bank_cd
AND line_type = 'MVMT'
AND colseq > 0
ORDER BY colseq;



V_KODEAB T_BANK_MUTATION.KODEAB%TYPE;
V_NAMAAB T_BANK_MUTATION.NAMAAB%TYPE;
V_RDN T_BANK_MUTATION.RDN%TYPE;
V_SID T_BANK_MUTATION.SID%TYPE;
V_SRE T_BANK_MUTATION.SRE%TYPE;
V_NAMANASABAH T_BANK_MUTATION.NAMANASABAH%TYPE;
V_TANGGALEFEKTIF T_BANK_MUTATION.TANGGALEFEKTIF%TYPE;
V_TANGGALTIMESTAMP T_BANK_MUTATION.TANGGALTIMESTAMP%TYPE;
V_INSTRUCTIONFROM T_BANK_MUTATION.INSTRUCTIONFROM%TYPE;
V_COUNTERPARTACCOUNT T_BANK_MUTATION.COUNTERPARTACCOUNT%TYPE;
V_TYPEMUTASI T_BANK_MUTATION.TYPEMUTASI%TYPE;
V_TRANSACTIONTYPE T_BANK_MUTATION.TRANSACTIONTYPE%TYPE;
V_CURRENCY T_BANK_MUTATION.CURRENCY%TYPE;
V_BEGINNINGBALANCE T_BANK_MUTATION.BEGINNINGBALANCE%TYPE;
V_TRANSACTIONVALUE T_BANK_MUTATION.TRANSACTIONVALUE%TYPE;
V_CLOSINGBALANCE T_BANK_MUTATION.CLOSINGBALANCE%TYPE;
V_REMARK T_BANK_MUTATION.REMARK%TYPE;
V_BANKREFERENCE T_BANK_MUTATION.BANKREFERENCE%TYPE;
V_BANKID T_BANK_MUTATION.BANKID%TYPE;


 v_delimtr CHAR(1);
 v_from NUMBER;
 v_str VARCHAR2(500);
 v_date DATE;
 v_num T_BANK_MUTATION.TRANSACTIONVALUE%TYPE;
v_ip CHAR(4);
v_cimb_tax_interest CHAR(3);

 vl_err EXCEPTION;
 Vl_ERRCD NUMBER;
 Vl_ERRMSG		VARCHAR2(1000);
 VL_FAIL CHAR(1);
 vl_cnt NUMBER;

 v_data VARCHAR2(500);

BEGIN
    
   BEGIN
   SELECT COLFMT INTO v_delimtr
	FROM T_FUND_BANK_FORMAT
	WHERE bank_cd = p_bank_cd
	AND line_type = 'MVMT'
	AND coltype = 'DELIM';
	EXCEPTION
	WHEN NO_DATA_FOUND THEN
		Vl_ERRCD := -1;
		Vl_ERRMSG := 'Delimiter not found in T_FUND_BANK_FORMAT ';
		RAISE vl_err;
	END;

--v_data := 'YJ001;LAUTANDHANA SECURINDO                             ;4586043307;IDD310319746838;YJ001244900133;LAUW DITA SUSANTI        ;20150204;20150204111934;4583010541             ;4586043307             ;C;NTRF;IDR;0000048195347.20;0000001413200.00;0000049608547.20;AP-LAUW006T       SB 4AP0275        ;000000204111934                         ;BCA02        ';

--v_data := p_data;

--FOR rec  IN csr_data LOOP
  --  v_data := rec.data;

	v_from := 1;
	FOR rec IN csr_fmt(p_bank_cd)
	LOOP
		v_str := SUBSTR(p_data, v_from, rec.colwidth);
		IF rec.coltype = 'DATE' THEN
		   v_date := TO_DATE(v_str,rec.colfmt);
		END IF;

		IF rec.coltype = 'NUM' AND rec.colfmt = '.' THEN
		   v_num := TO_NUMBER(v_str);
		END IF;

		IF rec.coltype = 'NUM' AND rec.colfmt IS NULL THEN
		   IF  INSTR('0123456789',SUBSTR(v_str,-1,1)) > 0 THEN

			   IF TO_NUMBER(v_str) = 0 THEN
			      v_num := 0;
				ELSE
			   v_num := TO_NUMBER(v_str) / 100;
			   END IF;
		   ELSE
		   	  v_num := -1;
		   END IF;
		END IF;

		IF rec.fieldseq = 1 THEN
		   V_KODEAB := trim(v_str);
		END IF;

		IF rec.fieldseq = 2 THEN
		   V_NAMAAB := SUBSTR(trim(v_str),1,25);
		END IF;

		IF rec.fieldseq = 3 THEN
      IF REC.BANK_CD='BNGA3' THEN
          V_RDN := SUBSTR(trim(v_str),2);
       ELSE
          V_RDN := trim(v_str);
       END IF;
		END IF;

		IF rec.fieldseq = 4 THEN
		   V_SID := trim(v_str);
		END IF;

		IF rec.fieldseq = 5 THEN
		   V_SRE := trim(v_str);
		END IF;

		IF rec.fieldseq = 6 THEN
		   V_NAMANASABAH := SUBSTR(trim(v_str),1,25);
		END IF;

		IF rec.fieldseq = 7 THEN
		   V_TANGGALEFEKTIF := v_date;
		      vo_eff_dt := v_date;

		END IF;

		IF rec.fieldseq = 8 THEN
		   V_TANGGALTIMESTAMP := v_date;
		END IF;

		IF rec.fieldseq = 9 THEN
		   V_INSTRUCTIONFROM := trim(v_str);
		END IF;

		IF rec.fieldseq = 10 THEN
		   V_COUNTERPARTACCOUNT := trim(v_str);
		END IF;

		IF rec.fieldseq = 11 THEN
		   V_TYPEMUTASI := trim(v_str);
		END IF;

		IF rec.fieldseq = 12 THEN
		   V_TRANSACTIONTYPE := trim(v_str);
		END IF;

		IF rec.fieldseq = 13 THEN
		   V_CURRENCY := trim(v_str);
		END IF;

		IF rec.fieldseq = 14 THEN
		   V_BEGINNINGBALANCE := v_num;
		END IF;

		IF rec.fieldseq = 15 THEN
		   V_TRANSACTIONVALUE := v_num;
		END IF;

		IF rec.fieldseq = 16 THEN
		   IF v_num = -1 THEN
		      IF V_TYPEMUTASI = 'D' THEN
		   	  V_CLOSINGBALANCE := V_BEGINNINGBALANCE - V_TRANSACTIONVALUE;
			  ELSE
		   	  V_CLOSINGBALANCE := V_BEGINNINGBALANCE + V_TRANSACTIONVALUE;
			  END IF;
		   ELSE
		   	  V_CLOSINGBALANCE := v_num;
		   END IF;
		   IF   V_BEGINNINGBALANCE = -1 THEN
		   		IF V_TYPEMUTASI = 'D' THEN
				   V_BEGINNINGBALANCE :=V_CLOSINGBALANCE + V_TRANSACTIONVALUE;
				ELSE
		   			V_BEGINNINGBALANCE :=V_CLOSINGBALANCE - V_TRANSACTIONVALUE;
				END IF;
		   END IF;
		END IF;

		IF rec.fieldseq = 17 THEN
		   V_REMARK := SUBSTR(trim(v_str),1,36);
		END IF;

		IF rec.fieldseq = 18 THEN
		   V_BANKREFERENCE := trim(v_str);
		END IF;

		IF rec.fieldseq = 19 THEN
		   V_BANKID := trim(v_str);

		END IF;

		IF rec.fieldseq = 97 THEN -- utk CIMB

		   V_cimb_tax_interest:= trim(v_str);
		END IF;

		IF rec.fieldseq = 98 THEN -- utk CIMB

		   V_ip := trim(v_str);
		END IF;

		IF v_delimtr IS NULL THEN
		   IF rec.fieldseq = 98 THEN -- utk CIMB
		   v_from := v_from;
		   ELSE
		   v_from := v_from +  rec.colwidth;
		   END IF;
		ELSE
		   v_from := v_from +  rec.colwidth +1;
		END IF;


	END LOOP;
    
	IF V_INSTRUCTIONFROM IS NULL THEN -- utk CIMB
	   IF v_typemutasi = 'C' THEN
	   	  V_INSTRUCTIONFROM := 'X';
		ELSE
		  V_INSTRUCTIONFROM := v_rdn;
	   END IF;
	END IF;

	IF V_COUNTERPARTACCOUNT IS NULL THEN -- utk CIMB
	   IF v_typemutasi = 'D' THEN
	   	  V_COUNTERPARTACCOUNT := v_rdn;
		ELSE
		  V_COUNTERPARTACCOUNT := 'X';
	   END IF;
	END IF;

	IF v_bankid = 'BNGA3' THEN
		IF v_ip = '@IP@' THEN -- utk CIMB
		   v_transactiontype := v_ip;
		ELSE
			  v_transactiontype :=v_cimb_tax_interest;										
			-- IF v_cimb_tax_interest = '198' OR v_cimb_tax_interest = '160' OR v_cimb_tax_interest = '005' THEN							
			 --  v_transactiontype := v_cimb_tax_interest;							
			   		IF v_bankreference IS NULL THEN 					
			   	  	 v_bankreference := v_rdn||v_cimb_tax_interest;		
				   END IF;						
				   IF v_transactiontype  = '198'  THEN						
				   	  					  v_remark := 'Tax';
					ELSIF  v_transactiontype  = '160' THEN 					
					  					  v_remark := 'Interest';
					 END IF;					  
				   		 				
			 --END IF;  		
		END IF;
	END IF;


	BEGIN
	Fund_Bank_Mvmt_Validation(V_KODEAB,
		V_NAMAAB,
		V_RDN,
		V_SID,
		V_SRE,
		V_NAMANASABAH,
		V_TANGGALEFEKTIF,
		V_TANGGALTIMESTAMP,
		V_INSTRUCTIONFROM,
		V_COUNTERPARTACCOUNT,
		V_TYPEMUTASI,
		V_TRANSACTIONTYPE,
		V_CURRENCY,
		V_BEGINNINGBALANCE,
		V_TRANSACTIONVALUE,
		V_CLOSINGBALANCE,
		V_REMARK,
		V_BANKREFERENCE,
		V_BANKID,
		P_IMPORTSEQ,
		VL_FAIL,
		Vl_ERRCD,
		Vl_ERRMSG
		);
	EXCEPTION
	WHEN OTHERS THEN
		 Vl_ERRCD := -1;
		Vl_ERRMSG := 'SP BANK VALIDATION : '||V_BANKREFERENCE||V_NAMANASABAH||SQLERRM(SQLCODE);
		RAISE vl_err;
	END;

	IF VL_FAIL = 'Y' THEN
	   VO_FAIL := 1;
	ELSE
	    IF VL_FAIL = 'I' THEN
	   	   VO_FAIL := 1;
		ELSE
		    VO_FAIL := 0;
		END IF;

		BEGIN
		Sp_Bank_Mutation_Update(V_KODEAB,
			V_NAMAAB,
			V_RDN,
			V_SID,
			V_SRE,
			V_NAMANASABAH,
			V_TANGGALEFEKTIF,
			V_TANGGALTIMESTAMP,
			V_INSTRUCTIONFROM,
			V_COUNTERPARTACCOUNT,
			V_TYPEMUTASI,
			V_TRANSACTIONTYPE,
			V_CURRENCY,
			V_BEGINNINGBALANCE,
			V_TRANSACTIONVALUE,
			V_CLOSINGBALANCE,
			V_REMARK,
			V_BANKREFERENCE,
			V_BANKID,
			P_IMPORTSEQ,
			Vl_ERRCD,
			Vl_ERRMSG);
		EXCEPTION
		WHEN OTHERS THEN
			 Vl_ERRCD := -1;
			Vl_ERRMSG := 'SP bank ref : '||V_BANKREFERENCE||V_NAMANASABAH||SQLERRM(SQLCODE);
			RAISE vl_err;
		END;
    
	END IF;

	IF vl_errcd	= -1 THEN
	   vo_errcd := vl_errcd;
	   RAISE vl_err;
	END IF;


	vo_errcd := 1;
	vo_errmsg := '';
   EXCEPTION
     WHEN vl_err THEN
	 vo_errcd := vl_errcd;
	 vo_errmsg := Vl_ERRMSG;
   
		ROLLBACK;
    WHEN OTHERS THEN
    ROLLBACK;
    VO_ERRCD := -888;
    VO_ERRMSG := SUBSTR(SQLERRM(SQLCODE),1,200);
    RAISE;
    
  
END SP_Fund_Bank_Mvmt_Import;