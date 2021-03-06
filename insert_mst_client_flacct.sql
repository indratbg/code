create or replace 
PROCEDURE INSERT_MST_CLIENT_FLACCT(
       P_USER_ID IN MST_CLIENT_FLACCT.USER_ID%TYPE,
	   P_IP_ADDRESS T_TEMP_HEADER.IP_ADDRESS%TYPE,
       VO_MSSG_ERR OUT VARCHAR2,
       VO_ERR_CD OUT NUMBER) IS
CURSOR CSR_RDI IS
SELECT M.CLIENT_CD,
	C.BANK_CD BANK_CD,
	C.REK_DANA, UPPER(C.NAME) NAME,
	B.BANK_NAME BANK_NAME, F_NOREK(B.ACCT_MASK,C.REK_DANA) AS BANK_ACCT_FMT
FROM
( 
 SELECT SUBREK001, MST_CLIENT.CLIENT_CD
 FROM MST_CLIENT, V_CLIENT_SUBREK14
 WHERE SUSP_STAT = 'N'
 AND CLIENT_TYPE_1 <> 'B'
 AND MST_CLIENT.CLIENT_CD = V_CLIENT_SUBREK14.CLIENT_CD
 AND SUBSTR(SUBREK001,6,4) <> '0000'
 AND SUBREK001 IS NOT NULL
-- AND CLIENT_CD NOT IN (SELECT CLIENT_CD FROM C_DOUBLE_SUBREKEFEK )
 --GROUP BY AGREEMENT_NO
) M,
T_REK_DANA_KSEI C,
MST_CLIENT_FLACCT F,
MST_FUND_BANK B
WHERE M.SUBREK001 = C.SUBREK
AND M.CLIENT_CD = F.CLIENT_CD (+)
AND B.BANK_CD = C.BANK_CD
AND F.CLIENT_CD IS NULL;


VL_MSSG_ERR VARCHAR2(200);
VL_ERR_CD NUMBER(2);
VL_M VARCHAR2(200);
VL_C NUMBER(2);
V_CLIENT_CD MST_CLIENT_FLACCT.CLIENT_CD%TYPE;
V_BANK_ACCT_NUM MST_CLIENT_FLACCT.BANK_ACCT_NUM%TYPE;
VL_ERR EXCEPTION;

BEGIN

  BEGIN
  DELETE FROM T_REK_DANA_KSEI
  WHERE REK_DANA IS NULL;
   EXCEPTION
   WHEN OTHERS THEN
   VL_MSSG_ERR := 'DELETE T_REK_DANA_KSEI '||SQLERRM;
   VL_ERR_CD := -1;
   RAISE VL_ERR;
   END;


FOR REC IN CSR_RDI LOOP
BEGIN
SELECT CLIENT_CD,BANK_ACCT_NUM INTO V_CLIENT_CD,V_BANK_ACCT_NUM FROM MST_CLIENT_FLACCT ;
EXCEPTION   
   WHEN OTHERS THEN
   VL_MSSG_ERR := 'MST_CLIENT_FLACCT'||SQLERRM;
   VL_ERR_CD := -2;
   RAISE VL_ERR;
   END;
   

IF REC.CLIENT_CD <> V_CLIENT_CD OR REC.REK_DANA <> V_BANK_ACCT_NUM THEN

   BEGIN
    INSERT INTO MST_CLIENT_FLACCT (
     CLIENT_CD, BANK_CD, BANK_ACCT_NUM,
     ACCT_NAME, ACCT_STAT, BANK_SHORT_NAME,
     BANK_ACCT_FMT, CRE_DT, USER_ID,
     UPD_DT, UPD_USER_ID)
     VALUES(REC.CLIENT_CD,REC.BANK_CD,REC.REK_DANA,
            REC.NAME,'I',REC.BANK_NAME,
            REC.BANK_ACCT_FMT,SYSDATE, P_USER_ID,
            NULL,NULL);
   EXCEPTION   
   WHEN OTHERS THEN
   VL_MSSG_ERR := 'INSERT TO MST_CLIENT_FLACCT '||SQLERRM;
   VL_ERR_CD := -3;
   RAISE VL_ERR;
   END;
   
   BEGIN
   SP_MST_CLIENT_FLACCT_IMPRT_UPD(REC.CLIENT_CD,
									REC.REK_DANA,
									REC.CLIENT_CD,
									REC.BANK_CD,
									REC.REK_DANA,
									REC.NAME,
									'I',
									REC.BANK_NAME,
									REC.BANK_ACCT_FMT,
									TRUNC(sysdate,'YYYY-MM-DD'),
									 P_USER_ID,
									 sysdate,
									 P_USER_ID,
									  P_USER_ID,
									 'I',
									 P_IP_ADDRESS,
									VL_ERR_CD,
									 VL_MSSG_ERR);

    EXCEPTION
 	    WHEN OTHERS THEN
	   			VL_ERR_CD := -4;
				 VL_MSSG_ERR :=  SUBSTR('SP_MST_CLIENT_FLACCT_IMPRT_UPD '||SQLERRM,1,200);
				RAISE VL_ERR;
	   END;
	   if VL_ERR_CD<0 then
     VL_ERR_CD := -5;
    VL_MSSG_ERR := 'SP_MST_CLIENT_FLACCT_IMPRT_UPD   '||VL_MSSG_ERR;
	 raise VL_ERR;
		end if;
  
   
END IF;
 END LOOP;

 BEGIN
  SP_AKTIFKAN_REKDANA;
 EXCEPTION
 WHEN OTHERS THEN
 VL_MSSG_ERR := 'SP_AKTIFKAN_REKDANA '||SQLERRM;
 VL_ERR_CD := -6;
 RAISE VL_ERR;
 END;

/*BEGIN
  BO2FO_SUSPEND_REKDANA(VL_C,VL_M);
 EXCEPTION
  WHEN OTHERS THEN
   VL_MSSG_ERR := 'SP_TIDAK_DITEMUKAN'||SQLERRM;
   VL_ERR_CD := -2;
   RAISE VL_ERR;
 END;*/
    IF VL_C < 0 THEN
   VL_MSSG_ERR := VL_M;
   RAISE VL_ERR;
 END IF;


VL_ERR_CD := 1 ;
VL_MSSG_ERR := '';

 EXCEPTION
  WHEN VL_ERR THEN
  ROLLBACK;
       

END INSERT_MST_CLIENT_FLACCT;