create or replace PROCEDURE SP_XML_TRX_TUNAI 
    (   p_trx_dt IN DATE,
        p_due_dt  date,
      p_trx_type varchar2,
      p_user_id varchar2,
      p_error_code OUT NUMBER,
      p_error_msg OUT VARCHAR2 )
IS
 --[INDRA]14-09-2017 UBAH LOGIC PAKAI RANDOM VALUE UNTUK MENGGANTIKAN TABEL TEMP DENGAN TABEL ASLI
  v_cnt number;
  v_trx_type varchar2(3); 
  v_err        EXCEPTION;
  v_error_code NUMBER;
  v_error_msg  VARCHAR2(200);
 V_RANDOM_VALUE NUMBER(10);
 
BEGIN

v_random_value := ABS(dbms_random.random);

  If p_trx_type = 'ALL' then
      v_trx_type := 'B';
  else
      v_trx_type := p_trx_type;
  end if;    
  
  If v_trx_type = 'B' then 
        
   -- step 1  CLW   Pindah dari subrek 004 ke sub rek 001 pasangannya
       begin
       SP_TMP_TRX_STK_TUNAI(
            p_trx_dt,
            p_due_dt,
            'B', --p_trx_type 
            'SUBR4PAIR1', --p_rute  
            null, --p_mode IN CHAR,
            '%', --p_client_type IN CHAR,
            'R',  --p_RI IN CHAR,
            V_RANDOM_VALUE,
            p_user_id,                   
            v_ERROR_CODE,
            v_ERROR_MSG);
         exception 
         WHEN OTHERS THEN
            v_error_code := -41;
            v_error_msg  := SUBSTR('INSERT INTO TMP_OTC '||SQLERRM,1,200);
            RAISE v_err;
          END;
       
--           select count(1)  into v_cnt
--           from TMP_OTC;
           
            begin    
                SP_XML_TRX_STK(
                 'CLW', -- p_xml_type
                    P_DUE_DT,
                   '1 CLW BUY',   --p_id
                p_user_id,
                'CLW TUNAI', --p_menu_name R_XML.menu_name%TYPE, --OTC / SECTR / VCA
                V_RANDOM_VALUE,
                v_error_code,
                v_error_msg );
             exception 
         WHEN OTHERS THEN
            v_error_code := -41;
            v_error_msg  := SUBSTR('INSERT INTO R_ '||SQLERRM,1,200);
            RAISE v_err;
          END;
     
    -- step 2 OTC   utk TS  atau subrek 001 yg tidak berpasangan dgn 004
    -- buat xml OTC - DFOP dari pasangan subrek 004 ( PAIR 1) dan RFOP pada subrek 001
   
        begin
        SP_TMP_TRX_OTC_TUNAI(
            p_trx_dt,
            p_due_dt,
            'B', --p_trx_type 
            null, --p_rute  
            'SUB2SUB', --p_mode IN CHAR,
            '%', --p_client_type IN CHAR,
            'R',  --p_RI IN CHAR,   
            V_RANDOM_VALUE,
            P_USER_ID,
            v_ERROR_CODE,
            v_ERROR_MSG);
         exception 
         WHEN OTHERS THEN
            v_error_code := -41;
            v_error_msg  := SUBSTR('INSERT INTO TMP_OTC '||SQLERRM,1,200);
            RAISE v_err;
          END;
             
--           select count(1)  into v_cnt
--           from TMP_OTC;
           
            begin    
                SP_XML_TRX_STK(
                 'OTC',
                    P_DUE_DT,
                   '2 OTC BUY',   
                p_user_id,
                'OTC TUNAI', --p_menu_name R_XML.menu_name%TYPE, --OTC / SECTR / VCA
                V_RANDOM_VALUE,
                v_error_code,
                v_error_msg );
             exception 
         WHEN OTHERS THEN
            v_error_code := -41;
            v_error_msg  := SUBSTR('INSERT INTO R_ '||SQLERRM,1,200);
            RAISE v_err;
          END;
                  
                
        -- step 3 utk transaksi TITIP NET BELI
       
   -- step 4  utk transaksi client yg sahamnya di bank custody

  end if; -- If v_trx_type := 'B' then 
  
  
   If p_trx_type = 'ALL' or p_trx_type = 'J' then
         v_trx_type := 'J';
--   step 1 utk TS  atau subrek 001 yg tidak berpasangan dgn 004

        Delete from TMP_OTC;

        begin
        SP_TMP_TRX_OTC_TUNAI(
            p_trx_dt,
            p_due_dt,
            'J', --p_trx_type 
            null, --p_rute  
            'SUB2SUB', --p_mode IN CHAR,
            '%', --p_client_type IN CHAR,
            'R',  --p_RI IN CHAR,               
             V_RANDOM_VALUE,
            p_user_id,          
            v_ERROR_CODE,
            v_ERROR_MSG);
         exception 
         WHEN OTHERS THEN
            v_error_code := -41;
            v_error_msg  := SUBSTR('INSERT INTO TMP_OTC '||SQLERRM,1,200);
            RAISE v_err;
          END;
             
--           select count(1)  into v_cnt
--           from TMP_OTC;
--           
            begin    
                SP_XML_TRX_STK(
                 'OTC',
                    P_DUE_DT,
                   '3 OTC SELL',   
                p_user_id,
                'OTC TUNAI', --p_menu_name R_XML.menu_name%TYPE, --OTC / SECTR / VCA,
                V_RANDOM_VALUE,
                v_error_code,
                v_error_msg );
             exception 
         WHEN OTHERS THEN
            v_error_code := -41;
            v_error_msg  := SUBSTR('INSERT INTO R_ '||SQLERRM,1,200);
            RAISE v_err;
          END;
                  

-- step 2 utk transaksi TITIP NET JUAL


--step 3  Pindah dari subrek 001 ke sub rek 004 pasangannya
       begin
       SP_TMP_TRX_STK_TUNAI(
            p_trx_dt,
            p_due_dt,
            'J', --p_trx_type 
            'PAIR1SUBR4', --p_rute  
            null, --p_mode IN CHAR,
            '%', --p_client_type IN CHAR,
            'R',  --p_RI IN CHAR,             
             V_RANDOM_VALUE,
            p_user_id,          
            v_ERROR_CODE,
            v_ERROR_MSG);
         exception 
         WHEN OTHERS THEN
            v_error_code := -41;
            v_error_msg  := SUBSTR('INSERT INTO TMP_OTC '||SQLERRM,1,200);
            RAISE v_err;
          END;
--       
--           select count(1)  into v_cnt
--           from TMP_OTC;
           
            begin    
                SP_XML_TRX_STK(
                 'CDS', -- p_xml_type
                    P_DUE_DT,
                   '4 CDS SELL',   --p_id
                p_user_id,
                'CDS TUNAI', --p_menu_name R_XML.menu_name%TYPE, --OTC / SECTR / VCA
                V_RANDOM_VALUE,
                v_error_code,
                v_error_msg );
             exception 
         WHEN OTHERS THEN
            v_error_code := -41;
            v_error_msg  := SUBSTR('INSERT INTO R_ '||SQLERRM,1,200);
            RAISE v_err;
          END;

--step 4  utk transaksi client yg sahamnya di bank custody

   end if;
  
  
BEGIN
DELETE FROM TMP_OTC WHERE RAND_VALUE=V_RANDOM_VALUE AND USER_ID=P_USER_ID;
 EXCEPTION
    WHEN OTHERS THEN
      V_ERROR_CODE :=-50;
      V_ERROR_MSG  :=SUBSTR( 'DELETE TMP_OTC ' || SQLERRM,1,200);
      RAISE V_ERR;
    END;


  p_error_code := 1;
  p_error_msg  := '';
  
EXCEPTION
WHEN v_err THEN
  p_error_code := v_error_code;
  p_error_msg  := v_error_msg;
  ROLLBACK;
WHEN OTHERS THEN
  p_error_code := -1;
  p_error_msg  := SUBSTR(SQLERRM,1,200);
  ROLLBACK;
END SP_XML_TRX_TUNAI;