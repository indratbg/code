create or replace 
PROCEDURE Sp_Mst_Client_Flacct_Imp(
       P_USER_ID IN MST_CLIENT_FLACCT.USER_ID%TYPE,
	   P_IP_ADDRESS T_TEMP_HEADER.IP_ADDRESS%TYPE,
       VO_MSSG_ERR OUT VARCHAR2,
       VO_ERR_CD OUT NUMBER) IS
	   
	   
CURSOR CSR_RDI IS
SELECT c.client_cd,
	c.bank_cd bank_cd,
	c.rek_dana, UPPER(trim(c.name)) name,
   b.bank_name Bank_name, F_Norek(b.acct_mask,c.rek_dana) AS bank_acct_fmt
FROM(
	SELECT client_Cd, t.bank_cd, t.rek_dana, t.name
	FROM(
			 SELECT subrek001, MST_CLIENT.client_cd
		  FROM MST_CLIENT, v_client_subrek14
		 WHERE susp_stat = 'N'
		 AND client_type_1 <> 'B'
		 AND MST_CLIENT.client_cd = v_client_subrek14.client_cd
		 AND SUBSTR(subrek001,6,4) <> '0000'
		 AND subrek001 IS NOT NULL
		 ) m,
		T_REK_DANA_KSEI t
		WHERE t.subrek = m.subrek001 ) c,
   ( SELECT client_Cd
     FROM MST_CLIENT_FLACCT
	 WHERE acct_stat <> 'C'
	 AND approved_stat = 'A') f,
   MST_FUND_BANK b
   WHERE    c.client_Cd = f.client_cd(+)
   AND f.client_Cd IS NULL
   AND c.bank_Cd= b.bank_Cd;


V_UPDATE_DATE T_TEMP_HEADER.UPDATE_DATE%TYPE;
V_UPDATE_SEQ T_TEMP_HEADER.UPDATE_SEQ%TYPE;
VL_MSSG_ERR VARCHAR2(200);
VL_ERR_CD NUMBER;
VL_M VARCHAR2(200);
VL_C NUMBER;
V_CLIENT_CD MST_CLIENT_FLACCT.CLIENT_CD%TYPE;
V_BANK_ACCT_NUM MST_CLIENT_FLACCT.BANK_ACCT_NUM%TYPE;
VL_ERR EXCEPTION;

X_CLIENT_CD MST_CLIENT_FLACCT.CLIENT_CD%TYPE;
X_BANK_CD  MST_CLIENT_FLACCT.BANK_CD%TYPE;
X_REK_DANA MST_CLIENT_FLACCT.BANK_ACCT_NUM%TYPE;
X_NAME MST_CLIENT_FLACCT.ACCT_NAME%TYPE;
X_BANK_ACCT_FMT MST_CLIENT_FLACCT.BANK_ACCT_FMT%TYPE;
X_BANK_NAME MST_CLIENT_FLACCT.bank_short_name%TYPE;

v_cnt NUMBER(10);

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
			        Sp_Mst_Client_Flacct_Upd(rec.CLIENT_CD,
			                                  rec.REK_DANA,
			                                  rec.CLIENT_CD,
			                                  rec.BANK_CD,
			                                  rec.REK_DANA,
			                                  rec.NAME,
			                                  'A',
			                                  rec.BANK_NAME,
			                                  rec.BANK_ACCT_FMT,
			                                  TRUNC(SYSDATE),
			                                  TO_DATE('2030-12-31','YYYY-MM-DD'),
			                                  NULL,
			                                   P_USER_ID,
			                                   NULL,
			                                    P_USER_ID,
			                                   'I',
			                                   P_IP_ADDRESS,
			                                   NULL,
			                                  VL_ERR_CD,
			                                   VL_MSSG_ERR);
			    EXCEPTION
			 	    WHEN OTHERS THEN
				   			VL_ERR_CD := -4;
							 VL_MSSG_ERR :=  SUBSTR('Sp_Mst_Client_Flacct_Upd '||SQLERRM(sqlcode),1,200);
							RAISE VL_ERR;
				   END;
				   IF VL_ERR_CD<0 THEN
			     VL_ERR_CD := -5;
			    VL_MSSG_ERR := 'Sp_Mst_Client_Flacct_Upd   '||VL_MSSG_ERR;
				 RAISE VL_ERR;
					END IF;
   
/*
			    BEGIN
			   SELECT COUNT(1) INTO v_cnt
			           FROM   (SELECT  UPDATE_DATE,UPDATE_SEQ 
			                  FROM  T_TEMP_DETAIL  
			                  WHERE  table_name ='MST_CLIENT_FLACCT'
			                  AND FIELD_NAME='BANK_ACCT_NUM'  
			                  AND  FIELD_VALUE=  rec.rek_dana)  a,
			                  (SELECT  UPDATE_DATE,UPDATE_SEQ 
			                  FROM  T_TEMP_DETAIL  
			                  WHERE  table_name ='MST_CLIENT_FLACCT'
			                  AND  FIELD_NAME='CLIENT_CD'  
			                  AND  FIELD_VALUE=rec.client_cd
			                  )  b
			                  WHERE  a.update_date =  b.update_date
			                    AND a.update_seq=b.update_seq;
			    EXCEPTION   
			   WHEN OTHERS THEN
					   VL_MSSG_ERR := 'MST_CLIENT_FLACCT'||SQLERRM;
					   VL_ERR_CD := -7;
					   RAISE VL_ERR;
			   END;
  
  
			    IF v_cnt > 1 THEN
						    VL_MSSG_ERR := 'UPDATE SEQ DAN UPDATE DATE LEBIH DARI 1';
						   VL_ERR_CD := -8;
					--	   RAISE VL_ERR;
				END IF;		   
*/			   
    
			    BEGIN
			   SELECT  MAX(A.UPDATE_DATE), MAX(A.UPDATE_SEQ)  INTO V_UPDATE_DATE,V_UPDATE_SEQ 
			           FROM   (SELECT  UPDATE_DATE,UPDATE_SEQ 
			                  FROM  T_TEMP_DETAIL  
			                  WHERE  table_name ='MST_CLIENT_FLACCT'
			                  AND FIELD_NAME='BANK_ACCT_NUM'  
			                  AND  FIELD_VALUE=  rec.rek_dana)  a,
			                  (SELECT  UPDATE_DATE,UPDATE_SEQ 
			                  FROM  T_TEMP_DETAIL  
			                  WHERE  table_name ='MST_CLIENT_FLACCT'
			                  AND  FIELD_NAME='CLIENT_CD'  
			                  AND  FIELD_VALUE=rec.client_cd
			                  )  b
			                  WHERE  a.update_date =  b.update_date
			                    AND a.update_seq=b.update_seq;
			    EXCEPTION   
			   WHEN OTHERS THEN
			   VL_MSSG_ERR := 'MST_CLIENT_FLACCT DAN CEK REKENING DANA INBOX'||SQLERRM;
			   VL_ERR_CD := -9;
			   RAISE VL_ERR;
			   END;
   
			    BEGIN
			   Sp_T_Temp_Approve('MST_CLIENT_FLACCT',
			                     V_UPDATE_DATE,
			                     V_UPDATE_SEQ,
			                     P_USER_ID,
			                     P_IP_ADDRESS,
			                     VL_ERR_CD,
			                     VL_MSSG_ERR);
			     EXCEPTION
			 WHEN OTHERS THEN
			 VL_MSSG_ERR := 'SP_T_TEMP_APPROVE'||SQLERRM;
			 VL_ERR_CD := -10;
			 RAISE VL_ERR;
			 END;
 

			 END LOOP;
			 
			 
			
			 BEGIN
			  Sp_Aktifkan_Rekdana;
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
			 END;
			 
			    IF VL_C < 0 THEN
			   VL_MSSG_ERR := VL_M;
			   RAISE VL_ERR;
			 END IF; */


VO_ERR_CD := 1 ;
VO_MSSG_ERR := '';

 EXCEPTION
  WHEN VL_ERR THEN
  VO_ERR_CD := VL_ERR_CD;
	   VO_MSSG_ERR :=  VL_MSSG_ERR;
  ROLLBACK;
 
       

END Sp_Mst_Client_Flacct_Imp;