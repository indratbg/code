create or replace PROCEDURE SP_XML_FUND_KSEI(
    P_DOC_DATE   IN DATE,
    p_bgn_client IN mst_client.client_Cd%type,
    p_end_client IN mst_client.client_Cd%type,
    P_RESELECT IN VARCHAR2,
    p_user_id    IN mst_client.user_id%type,
    P_ID OUT R_XML.IDENTIFIER%TYPE,
    P_ERROR_CODE OUT NUMBER,
    P_ERROR_MSG OUT VARCHAR2 )
IS
  /* ----------------------------
  [indra] 14-09-2017 ubah tabel temp ke tabel asli
  Purpose : to transfer from broker main account di ksei ke subrek client
  - saldo kredit di simpan di ksei
  */
  v_xml_type VARCHAR2(3);
  v_id R_XML.IDENTIFIER%type;
  v_menu_name R_XML.menu_name%TYPE;
  v_cnt        NUMBER;
  V_ERR        EXCEPTION;
  V_ERROR_CODE NUMBER(5);
  V_ERROR_MSG  VARCHAR2(200);
  v_random_value NUMBER(10);
BEGIN

 v_random_value := ABS(dbms_random.random);
  v_menu_name := 'TRANSFER TO KSEI';
  
  BEGIN
    INSERT
    INTO TMP_BTS
      (
        --     EXTERNALREFERENCE , INSTRUCTIONTYPE , PARTICIPANTCODE ,PARTICIPANTACCOUNT ,
        --     COUNTERPARTACCOUNT , VALUEDATE , CURRENCYCODE , CASHAMOUNT ,  DESCRIPTION
        COL1, COL2, COL3, COL4, COL5, COL6, COL7,COL8,COL9, rand_value, user_id
      )
    SELECT to_client AS extref, 'BTS', broker_cd, broker_001, to_acct, TO_CHAR(doc_date, 'yyyymmdd') valueDate, 'IDR' currency, trx_amt, client_name descrip,
    v_random_value, p_user_id
    FROM t_fund_ksei, v_broker_subrek, mst_client
    WHERE doc_date =P_DOC_DATE
    AND to_client  = mst_client.client_Cd
    AND to_client BETWEEN p_bgn_client AND p_end_client
    AND trx_type                 = 'R'
    AND (XML IS NULL  OR ( XML = 'Y' AND P_RESELECT = 'Y'))
    AND t_fund_ksei.approved_sts = 'A'
    ORDER BY doc_date, to_client;
  EXCEPTION
  WHEN OTHERS THEN
    V_ERROR_CODE :=-10;
    V_ERROR_MSG  :=SUBSTR( 'INSERT INTO TMP_BTS ' || SQLERRM,1,200);
    RAISE V_ERR;
  END;
  
 -- SELECT COUNT(1) INTO v_cnt FROM TMP_BTS;
  
  BEGIN
    SELECT valuedate||p_user_id
    INTO v_id
    FROM
      (
        SELECT to_client AS extref, 'BTS', broker_cd, broker_001, to_acct, TO_CHAR(doc_date, 'yyyymmdd') valueDate, 'IDR' currency, trx_amt, client_name descrip
        FROM t_fund_ksei, v_broker_subrek, mst_client
        WHERE doc_date =P_DOC_DATE
        AND to_client  = mst_client.client_Cd
        AND to_client BETWEEN p_bgn_client AND p_end_client
        AND trx_type     = 'R'
        AND (XML IS NULL  OR ( XML = 'Y' AND P_RESELECT = 'Y'))
        AND approved_sts = 'A'
        ORDER BY doc_date, to_client
      )
    WHERE rownum = 1;
  EXCEPTION
  when no_data_found then
    V_ERROR_CODE :=-14;
    V_ERROR_MSG  :='NO DATA FOUND';
    RAISE V_ERR;
  WHEN OTHERS THEN
    V_ERROR_CODE :=-15;
    V_ERROR_MSG  :=SUBSTR( 'SELECT IDENTIFIER FROM XML QUERY' || SQLERRM,1,200);
    RAISE V_ERR;
  END;
  
  BEGIN
    SP_XML_BTS( 'BTS', v_id, p_user_id, v_menu_name,v_random_value, V_ERROR_CODE, V_ERROR_MSG );
  EXCEPTION
  WHEN OTHERS THEN
    V_ERROR_CODE :=-30;
    V_ERROR_MSG  :=SUBSTR( 'CALL SP_XML_BTS' || SQLERRM,1,200);
    RAISE V_ERR;
  END;
  
  IF v_error_code < 0 THEN
    V_ERROR_CODE :=-35;
    V_ERROR_MSG  :=SUBSTR('SP_XML_BTS '|| V_ERROR_MSG,1,200);
    RAISE V_ERR;
  END IF;
  
  BEGIN
    UPDATE t_fund_ksei
    SET xml       ='Y'
    WHERE DOC_DATE=P_DOC_DATE
    AND CLIENT_CD BETWEEN p_bgn_client AND p_end_client
    AND TRX_TYPE    ='R'
    AND APPROVED_STS='A';
  EXCEPTION
  WHEN OTHERS THEN
    V_ERROR_CODE :=-50;
    V_ERROR_MSG  :=SUBSTR( 'UPDATE t_fund_ksei SET XML=Y ' || SQLERRM,1,200);
    RAISE V_ERR;
  END;
  
  --delete data from table tem
  begin
  delete from TMP_BTS where rand_value=v_random_value and user_id=p_user_id;
    EXCEPTION
  WHEN OTHERS THEN
    V_ERROR_CODE :=-60;
    V_ERROR_MSG  :=SUBSTR( 'Delete tmp_bts ' || SQLERRM,1,200);
    RAISE V_ERR;
  END;
  
  P_ID        := v_id;
  P_ERROR_CODE:=1;
  P_ERROR_MSG :='';
  
EXCEPTION
WHEN V_ERR THEN
  ROLLBACK;
  P_ERROR_CODE :=V_ERROR_CODE ;
  P_ERROR_MSG  := V_ERROR_MSG;
WHEN OTHERS THEN
  ROLLBACK;
  P_ERROR_CODE :=-1;
  P_ERROR_MSG  :=SUBSTR( SQLERRM(SQLCODE),1,200);
END SP_XML_FUND_KSEI;