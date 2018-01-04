create or replace 
PROCEDURE SP_FUND_BANK_BAL_IMPORT(
p_bank_cd mst_fund_bank.bank_cd%type,
p_data varchar2,
p_userid t_fund_bal_bank.user_id%type,
--vo_eff_dt out date,
VO_FAIL OUT NUMBER,
vo_errcd out number,
vo_errmsg out varchar2) IS
/******************************************************************************
   NAME:       FUND_BANK_MVMT_IMPORT
   PURPOSE:

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        24/07/2012          1. Created this procedure.

******************************************************************************/
--p_data t_fund_bank_format.coldesc%type,
cursor csr_fmt(a_bank_cd mst_fund_bank.bank_cd%type) is
SELECT
BANK_CD, LINE_TYPE, COLSEQ,
   COLTYPE, COLWIDTH, COLFMT,
   COLDESC, FIELDSEQ
FROM T_FUND_BANK_FORMAT
where bank_cd = a_bank_cd
and line_type = 'BAL'
and colseq > 0
order by colseq;



V_RDN T_BANK_BALANCE.RDN%TYPE;
V_SID T_BANK_BALANCE.SID%TYPE;
V_SRE T_BANK_BALANCE.SRE%TYPE;
V_NAMANASABAH T_BANK_BALANCE.NAMANASABAH%TYPE;
V_BALANCE T_BANK_BALANCE.BALANCE%TYPE;
V_TANGGALEFEKTIF T_BANK_BALANCE.TANGGALEFEKTIF%TYPE;
V_TANGGALTIMESTAMP T_BANK_BALANCE.TANGGALTIMESTAMP%TYPE;
V_CURRENCY T_BANK_BALANCE.CURRENCY%TYPE;
V_BANKID T_BANK_BALANCE.BANKID%TYPE;


v_delimtr char(1);
v_from number;
v_str varchar2(200);
v_date date;
v_num t_bank_BALANCE.BALANCE%type;
--v_ip char(4);
--v_cimb_tax_interest char(3);

 vl_err exception;
 Vl_ERRCD number;
 Vl_ERRMSG  varchar2(200);
 VL_FAIL CHAR(1);
 vl_cnt number;

v_data varchar2(500);
v_broker varchar2(2);
BEGIN

 begin
   SELECT COLFMT into v_delimtr
 FROM T_FUND_BANK_FORMAT
 where bank_cd = p_bank_cd
 and line_type = 'BAL'
 and coltype = 'DELIM';
 exception
 when no_data_found then
  Vl_ERRCD := -10;
  Vl_ERRMSG := 'Delimiter not found in T_FUND_BANK_FORMAT ';
  raise vl_err;
 end;

 BEGIN
 SELECT SUBSTR(BROKER_CD,1,2) into v_broker FROM V_BROKER_SUBREK;
  exception
 when no_data_found then
  Vl_ERRCD := -15;
  Vl_ERRMSG := 'SELECT BROKER CODE FROM V_BROKER_SUBREK';
  raise vl_err;
 end;

 


--v_data := '

/*
v_data := v_data||'201207232012-07-23-10.35.10.653000IDRBNGA3000000000000000C000001654125000N9154000001654125000';
v_data := v_data||'12072394252262                                                                                      ';
v_data := v_data||'Darmawan Suria 18.07.12                                                         DR 4800100418000 KE 0001460100096120                        005';
*/

--v_data :='1460100395003CPD260655487281PF001318400100TOPAS MULTI SECURITI                    0000000004288321210022012-10-02-06.03.17.655000IDR IDBNGA3';
--v_data :='1460100395003CPD260655487281PF001318400100TOPAS MULTI SECURITI                    0000000004288321210022012-10-02-06.03.17.655000IDR IDBNGA3';
 --V_DATA := P_DATA;
 --v_data :='YJ001;LAUTANDHANA SECURINDO                             ;4580438135;IDD121010793063;YJ001459500105;MULYA SETIA ATMADJA SKOM ;IDR;0000000942232.41;20130204;20130204093036;BCA02';

 

 v_from := 1;
 for rec in csr_fmt(p_bank_cd)
 loop

   v_str := substr(p_data, v_from, rec.colwidth);
   if rec.coltype = 'DATE' then
      v_date := to_date(v_str,rec.colfmt);
   end if;


   if rec.coltype = 'NUM' and rec.colfmt = '.' then
      v_num := to_number(v_str);
   end if;

   if rec.coltype = 'NUM' and rec.colfmt is null then
      if  instr('0123456789',substr(v_str,-1,1)) > 0 then

       if to_number(v_str) = 0 then
          v_num := 0;
       else
          v_num := to_number(v_str) / 100;
          end if;
      else
        v_num := -1;-- CIMB 
      end if;
   end if;

   if rec.fieldseq = 1 then
      V_RDN := trim(v_str);
   end if;

   if rec.fieldseq = 2 then
      V_SID := trim(v_str);
   end if;

   if rec.fieldseq = 3 then
      V_SRE := trim(v_str);
   end if;

   if rec.fieldseq = 4 then
      V_NAMANASABAH := substr(trim(v_str),1,25);
   end if;

   

   if rec.fieldseq = 5 then
      V_BALANCE := v_num;
   end if;

   if rec.fieldseq = 6 then
      V_TANGGALEFEKTIF := v_date;
   end if;

   if rec.fieldseq = 7 then
      V_TANGGALTIMESTAMP := v_date;
   end if;
   
   if rec.fieldseq = 8 then
      V_CURRENCY := trim(v_str);
   end if;

   if rec.fieldseq = 9 then
      V_BANKID := trim(v_str);
   end if;

   if v_delimtr is null  then
      v_from := v_from +  rec.colwidth;
	else
      v_from := v_from +  rec.colwidth +1;
   end if;

  end loop;

  --30MAR2016
  if V_BANKID = 'BNGA3' AND LENGTH(V_RDN)=13 AND SUBSTR(V_RDN,1,1)= '0' THEN
		V_RDN := SUBSTR(V_RDN,2);
  END IF;
  --END 30MAR2016
  if  v_broker = 'YJ' then

  BEGIN
  SELECT COUNT(1) INTO vL_cnt 
   FROM T_FUND_BAL_BANK
  WHERE status_dt= V_TANGGALEFEKTIF
  AND rdi_num = V_RDN;
  EXCEPTION
  WHEN NO_DATA_FOUND THEN
  	   vl_cnt := 0;
  WHEN OTHERS THEN
  Vl_ERRCD := -20;
  Vl_ERRMSG := ' T_FUND_BAL_BANK : '||V_TANGGALEFEKTIF||' NAMA NASABAH : '||V_NAMANASABAH||' '||SQLERRM(SQLCODE);
  RAISE vl_err;
  END;

  IF vl_cnt > 0  THEN
   		 BEGIN
		 UPDATE T_FUND_BAL_BANK
		 SET BALANCE = V_BALANCE,
		 	 		 CRE_DT =   SYSDATE,
					 bank_timestamp = V_TANGGALTIMESTAMP	
		 WHERE STATUS_DT = V_TANGGALEFEKTIF
		 AND RDI_NUM = V_RDN;
		 EXCEPTION
		    WHEN OTHERS THEN
		     VL_ERRCD := -30;
		      VL_ERRMSG := 'UPDATE  t_fund_bal_bank'||SUBSTR(SQLERRM(SQLCODE),1,100);
		      RAISE vl_err;
		   END;
	ELSE
		 BEGIN
	     INSERT INTO T_FUND_BAL_BANK
	      (rdi_num,	 nama, balance,
	      status_dt, user_id,   cre_dt, bank_timestamp, rdi_bank_cd)
	      VALUES
	     (V_RDN,V_NAMANASABAH,  V_BALANCE,
	   	  V_TANGGALEFEKTIF,   p_userid,	 SYSDATE, V_TANGGALTIMESTAMP, V_BANKID);
	  EXCEPTION
	    WHEN OTHERS THEN
	     VL_ERRCD := -40;
	      VL_ERRMSG := 'Insert t_fund_bal_bank'||SUBSTR(SQLERRM(SQLCODE),1,100);
	      RAISE vl_err;
		   END;
	END IF;
	
  end if;
	BEGIN
  		 SELECT COUNT(1) INTO vl_cnt
   		 FROM T_BANK_BALANCE
	  WHERE tanggalefektif= V_TANGGALEFEKTIF
	  AND rdn = V_RDN;
	    EXCEPTION
		WHEN NO_DATA_FOUND THEN
		vl_cnt := 0;
	  WHEN OTHERS THEN
	  Vl_ERRCD := -50;
	  Vl_ERRMSG :='retrieve T_BANK_BALANCE : '||V_TANGGALEFEKTIF||' NAMA NASABAH : '||V_NAMANASABAH||' '||SQLERRM(SQLCODE);
	  RAISE vl_err;
	 END;
	
	IF vl_cnt > 0 THEN
	BEGIN
	   UPDATE T_BANK_BALANCE
	   SET BALANCE = V_BALANCE,
	   	   tanggaltimestamp = V_TANGGALTIMESTAMP
		 WHERE tanggalefektif= V_TANGGALEFEKTIF
			  AND rdn = V_RDN;
			    EXCEPTION
				 WHEN OTHERS THEN
			  Vl_ERRCD := -60;
			  Vl_ERRMSG :='UPDATE T_BANK_BALANCE : '||V_TANGGALEFEKTIF||' NAMA NASABAH : '||V_NAMANASABAH||' '||SQLERRM(SQLCODE);
			  RAISE vl_err;
			 END;  
		ELSE	 
	   BEGIN
	     INSERT INTO T_BANK_BALANCE
	        (rdn,        sid,        sre,
	        namanasabah,        balance,        tanggalefektif,
	        tanggaltimestamp,        currency, bankid )
	      VALUES
	     (V_RDN, V_SID, V_SRE,
		 V_NAMANASABAH, V_BALANCE, V_TANGGALEFEKTIF,
		 V_TANGGALTIMESTAMP, V_CURRENCY, V_BANKID   );
	  EXCEPTION
	    WHEN OTHERS THEN
	     VL_ERRCD := -70;
	      VL_ERRMSG := 'Insert t_bank_balance'||SUBSTR(SQLERRM(SQLCODE),1,100);
	      RAISE vl_err;
	   END;
	END IF;
	
 vo_errcd := 1;
 vo_errmsg := '';
 --COMMIT;
  
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        NULL;
	WHEN vl_err THEN
		vo_errcd := VL_ERRCD;
		vo_errmsg :=  substr(VL_ERRMSG,1,200);
		ROLLBACK;
    WHEN OTHERS THEN
        -- Consider logging the error and then re-raise
	    ROLLBACK;
	    vo_errcd := -1;
	    vo_errmsg := SUBSTR(SQLERRM,1,200);
        RAISE;
END SP_FUND_BANK_BAL_IMPORT;