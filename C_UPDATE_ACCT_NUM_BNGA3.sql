CREATE OR REPLACE
PROCEDURE C_UPDATE_ACCT_NUM_BNGA3(P_USER_ID VARCHAR2,
P_ERROR_CD OUT NUMBER,
P_ERROR_MSG OUT VARCHAR2
  )
IS
  CURSOR CSR_DATA
  IS
       SELECT a.client_cd,
      C.NAMA ,
      C.REKENING_DANA_LAMA,
      C.REKENING_DANA_BARU,
      b.subrek001,
      a.bank_short_name,
      a.bank_acct_fmt,
      F_BANK_ACCT_MASK(C.REKENING_DANA_BARU,D.ACCT_MASK) bank_acct_fmt_NEW,
      a.from_dt,
      a.to_dt
    FROM mst_client_flacct a,
      v_client_subrek14 b,
      C_MUTASI_ACCT_BNGA3 c,
      MST_FUND_BANK D
    WHERE b.subrek001 = c.sre
    AND b.client_cd   = a.client_cd
    AND a.acct_stat   ='A' 
    AND D.BANK_CD = A.BANK_CD
	AND A.BANK_ACCT_NUM = C.REKENING_DANA_LAMA;
	--AND ROWNUM<6	;
	v_err_cd NUMBER;
  V_ERR_MSG                         VARCHAR2(200);
  v_err                             EXCEPTION;
  V_MENU_NAME T_MANY_HEADER.MENU_NAME%TYPE := 'UPDATE BANK ACCT NUM BNGA3';
  V_UPDATE_DATE T_MANY_HEADER.UPDATE_DATE%TYPE;
  V_UPDATE_SEQ T_MANY_HEADER.UPDATE_SEQ%TYPE;
  V_IP_ADDRESS T_MANY_HEADER.IP_ADDRESS%TYPE;
  V_TO_DATE DATE;
  V_RECORD_SEQ NUMBER;
BEGIN

V_IP_ADDRESS :=SYS_CONTEXT('USERENV','IP_ADDRESS');
  
  V_TO_DATE := GET_DOC_DATE('1',TRUNC(SYSDATE));

  --EXECUTE SP HEADER
  BEGIN
    Sp_T_Many_Header_Insert(V_MENU_NAME, 'I', P_USER_ID, V_IP_ADDRESS, NULL, V_UPDATE_DATE, V_UPDATE_SEQ, V_ERR_CD, V_ERR_MSG);
  EXCEPTION
  WHEN OTHERS THEN
    V_ERR_CD  := -10;
    V_ERR_MSG := SUBSTR('SP_T_MANY_HEADER_INSERT '|| SQLERRM(SQLCODE),1,200);
    RAISE V_ERR;
  END;

  V_RECORD_SEQ :=1;
  FOR rec IN csr_data
  LOOP
  
    --UPDATE ACCT STAT='C' MASING-MASING CLIENT
    BEGIN
      SP_MST_CLIENT_FLACCT_IMP_UPD (REC.CLIENT_CD,--P_SEARCH_CLIENT_CD, 
	  REC.REKENING_DANA_LAMA,--P_SEARCH_BANK_ACCT_NUM,
	  REC.CLIENT_CD,--P_CLIENT_CD,
	  'BNGA3',--P_BANK_CD, 
	  REC.REKENING_DANA_LAMA,--P_BANK_ACCT_NUM, 
	  REC.NAMA,--P_ACCT_NAME, 
	  'C',--P_ACCT_STAT, 
	 rec.bank_short_name,--P_BANK_SHORT_NAME, 
	 rec.bank_acct_fmt,-- P_BANK_ACCT_FMT, 
	  SYSDATE, 
	  P_USER_ID, 
	  NULL,--P_UPD_DT, 
	  NULL,--P_UPD_USER_ID, 
	  NULL,--P_UPD_BY, 
	  rec.from_dt,--P_FROM_DT,
	  V_TO_DATE,--P_TO_DT,
	  'U',--P_UPD_STATUS,
	  V_IP_ADDRESS, 
	  NULL,--p_cancel_reason, 
	  V_UPDATE_DATE,--p_update_date, 
	  V_UPDATE_SEQ,--p_update_seq, 
	  V_RECORD_SEQ,--p_record_seq, 
	  v_err_cd,--p_error_code, 
	  V_ERR_MSG--p_error_msg
	  );
    EXCEPTION
    WHEN OTHERS THEN
      V_ERR_CD  := -20;
      V_ERR_MSG := SUBSTR('SP_MST_CLIENT_FLACCT_IMP_UPD '|| SQLERRM(SQLCODE),1,200);
      RAISE V_ERR;
    END;
    
    IF V_ERR_CD  <0 THEN
      V_ERR_CD  := -30;
      V_ERR_MSG := SUBSTR(V_ERR_MSG,1,200);
      RAISE V_ERR;
    END IF;
    V_RECORD_SEQ := V_RECORD_SEQ+1;
	
	--INSERT REKNING BARU MASING-MASING NASABAH
	 BEGIN
      SP_MST_CLIENT_FLACCT_IMP_UPD (REC.CLIENT_CD,--P_SEARCH_CLIENT_CD, 
	  REC.REKENING_DANA_BARU,--P_SEARCH_BANK_ACCT_NUM,
	  REC.CLIENT_CD,--P_CLIENT_CD,
	  'BNGA3',--P_BANK_CD, 
	  REC.REKENING_DANA_BARU,--P_BANK_ACCT_NUM, 
	  REC.NAMA,--P_ACCT_NAME, 
	  'A',--P_ACCT_STAT, 
	 rec.bank_short_name,--P_BANK_SHORT_NAME, 
	 rec.bank_acct_fmt_NEW,-- P_BANK_ACCT_FMT, 
	  SYSDATE, 
	  P_USER_ID, 
	  NULL,--P_UPD_DT, 
	  NULL,--P_UPD_USER_ID, 
	  NULL,--P_UPD_BY, 
	  TRUNC(SYSDATE),--P_FROM_DT,
	   TO_DATE('2030-12-31','YYYY-MM-DD'),--P_TO_DT,
	  'I',--P_UPD_STATUS,
	  V_IP_ADDRESS, 
	  NULL,--p_cancel_reason, 
	  V_UPDATE_DATE,--p_update_date, 
	  V_UPDATE_SEQ,--p_update_seq, 
	  V_RECORD_SEQ,--p_record_seq, 
	  v_err_cd,--p_error_code, 
	  V_ERR_MSG--p_error_msg
	  );
    EXCEPTION
    WHEN OTHERS THEN
      V_ERR_CD  := -40;
      V_ERR_MSG := SUBSTR('SP_MST_CLIENT_FLACCT_IMP_UPD '|| SQLERRM(SQLCODE),1,200);
      RAISE V_ERR;
    END;
    
    IF V_ERR_CD  <0 THEN
      V_ERR_CD  := -50;
      V_ERR_MSG := SUBSTR(V_ERR_MSG,1,200);
      RAISE V_ERR;
    END IF;
	
	
	
	V_RECORD_SEQ := V_RECORD_SEQ+1;
  END LOOP;
  /*
  --APPROVE
  BEGIN
  Sp_T_Many_Approve( V_MENU_NAME,
				   V_UPDATE_DATE,
				   V_UPDATE_SEQ,
				   P_USER_ID,
				   V_IP_ADDRESS,
				   V_ERR_CD,
				   V_ERR_MSG);
	EXCEPTION
    WHEN OTHERS THEN
      V_ERR_CD  := -60;
      V_ERR_MSG := SUBSTR('SP_MST_CLIENT_FLACCT_IMP_UPD '|| SQLERRM(SQLCODE),1,200);
      RAISE V_ERR;
    END;
    
    IF V_ERR_CD  <0 THEN
      V_ERR_CD  := -70;
      V_ERR_MSG := SUBSTR(V_ERR_MSG,1,200);
      RAISE V_ERR;
    END IF;	   
  
  */
  P_ERROR_CD   := 1 ;
  P_ERROR_MSG := '';
EXCEPTION
WHEN V_ERR THEN
  P_ERROR_CD   := V_ERR_CD;
  P_ERROR_MSG := V_ERR_MSG;
  ROLLBACK;
  WHEN OTHERS THEN
   P_ERROR_CD   := -1;
  P_ERROR_MSG := SUBSTR(SQLERRM(SQLCODE),1,200);
  ROLLBACK;
END C_UPDATE_ACCT_NUM_BNGA3;