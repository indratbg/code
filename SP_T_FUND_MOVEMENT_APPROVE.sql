create or replace PROCEDURE           "SP_T_FUND_MOVEMENT_APPROVE" (
         p_menu_name                                              T_MANY_HEADER.menu_name%TYPE,
         p_update_date                                      T_MANY_HEADER.update_date%TYPE,
         p_update_seq                                             T_MANY_HEADER.update_seq%TYPE,
         p_approved_user_id                       T_MANY_HEADER.user_id%TYPE,
         p_approved_ip_address             T_MANY_HEADER.ip_address%TYPE,
     
     p_error_code             OUT NUMBER,
         p_error_msg                OUT VARCHAR2
       
) IS

/******************************************************************************
   NAME:      SP_T_FUND_MOVEMENT_APPROVE
   PURPOSE:    

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        23/10/2013          1. Created this procedure.

******************************************************************************/

CURSOR csr_data IS 
SELECT DISTINCT RECORD_SEQ FROM T_MANY_DETAIL WHERE UPDATE_SEQ=p_update_seq AND UPDATE_DATE=p_update_date;

v_cnt NUMBER;
v_status T_MANY_HEADER.status%type;
c_status T_MANY_HEADER.status%type;
v_doc_num T_FUND_MOVEMENT.DOC_NUM%TYPE;
v_trx_type T_FUND_MOVEMENT.TRX_TYPE%TYPE;
v_doc_date T_FUND_MOVEMENT.DOC_DATE%TYPE;
v_client_cd T_FUND_MOVEMENT.CLIENT_CD%TYPE;
v_trx_amt T_FUND_MOVEMENT.TRX_AMT%TYPE;
v_table_rowid T_MANY_DETAIL.TABLE_ROWID%TYPE;
m_trx_type T_FUND_MOVEMENT.TRX_TYPE%TYPE;
m_doc_date T_FUND_MOVEMENT.DOC_DATE%TYPE;
m_client_cd T_FUND_MOVEMENT.CLIENT_CD%TYPE;
m_trx_amt T_FUND_MOVEMENT.TRX_AMT%TYPE;

v_err EXCEPTION;
v_error_code                                          NUMBER;
v_error_msg                                     VARCHAR2(200);
v_table_name varchar(50):='T_FUND_MOVEMENT';
V_MENU_NAME T_MANY_HEADER.MENU_NAME%TYPE;
V_MODE VARCHAR2(1);
V_SALDO NUMBER;
v_source t_fund_movement.source%type;
BEGIN



  BEGIN
  SELECT MENU_NAME INTO V_MENU_NAME from T_MANY_HEADER where update_seq =  p_update_seq and update_date=p_update_date;
  EXCEPTION
          WHEN OTHERS THEN
                        v_error_code := -2;
                        v_error_msg :=  SUBSTR('T_Many_Detail '||SQLERRM,1,200);
                        RAISE v_err;
         END;


IF V_MENU_NAME <> 'IPO FUND ENTRY' THEN

FOR rec in csr_data loop

  BEGIN
  SELECT UPD_STATUS INTO v_status from T_MANY_DETAIL where update_seq =  p_update_seq and update_date=p_update_date AND RECORD_SEQ= rec.record_seq and rownum=1;
  EXCEPTION
          WHEN OTHERS THEN
                        v_error_code := -2;
                        v_error_msg :=  SUBSTR('T_Many_Detail '||SQLERRM,1,200);
                        RAISE v_err;
         END;
         
         
  BEGIN
  SELECT STATUS INTO c_status from T_MANY_HEADER where update_seq =  p_update_seq AND update_date=p_update_date and rownum=1;
  EXCEPTION
          WHEN OTHERS THEN
                        v_error_code := -3;
                        v_error_msg :=  SUBSTR('T_Many_Header '||SQLERRM,1,200);
                        RAISE v_err;
         END;

            IF v_status <> 'C' then
            BEGIN
             SELECT MAX(DOC_NUM), MAX(TRX_TYPE), to_date(MAX(DOC_DATE),'yyyy/mm/dd hh24:mi:ss'), MAX(CLIENT_CD), MAX(TRX_AMT),MAX(SOURCE)
                         INTO v_doc_num, v_trx_type, v_doc_date, v_client_cd,v_trx_amt, v_source
                           FROM(
                           SELECT DECODE(field_name,'DOC_NUM',field_value, NULL) DOC_NUM,
                                      DECODE(field_name,'TRX_TYPE',field_value, NULL) TRX_TYPE,
                                          DECODE(field_name,'DOC_DATE',field_value, NULL) DOC_DATE,
                                          DECODE(field_name,'CLIENT_CD',field_value, NULL) CLIENT_CD,
                                          DECODE(field_name,'TRX_AMT',field_value, NULL) TRX_AMT,
                                          DECODE(field_name,'SOURCE',field_value, NULL) SOURCE
                                          
                           FROM  T_MANY_DETAIL
                          WHERE T_MANY_DETAIL.update_date = p_update_date
                          AND T_MANY_DETAIL.table_name = v_table_name
                          AND T_MANY_DETAIL.update_seq       = p_update_seq
                          AND RECORD_SEQ=REC.RECORD_SEQ
                          AND T_MANY_DETAIL.field_name IN ('DOC_NUM','TRX_TYPE', 'DOC_DATE','CLIENT_CD','TRX_AMT'));
                          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              v_error_code := -4;
                                          v_error_msg :=  SUBSTR(SQLERRM,1,200);
                                          RAISE v_err;
            WHEN OTHERS THEN
              v_error_code := -5;
              v_error_msg := SUBSTR(SQLERRM,1,200);
              RAISE v_err;
          END; 
      
              end if;

            
              
            

             IF v_status ='I' then
             --------------------INSERT---------------------------
             IF v_trx_type ='I' THEN
             V_MODE := 'R';
             ELSIF V_TRX_TYPE ='O' THEN
             V_MODE :='W';
             ELSE
             V_MODE := v_trx_type;
             END IF;
             
             --05apr2016
            BEGIN
                  SELECT F_FUND_BAL(v_client_cd, TRUNC(SYSDATE)) INTO V_SALDO FROM DUAL;
            EXCEPTION
          WHEN OTHERS THEN
                        v_error_code := -200;
                        v_error_msg :=  SUBSTR('CEK SALDO F_FUND_BAL'||SQLERRM,1,200);
                        RAISE v_err;
          END;
             IF V_MODE ='W' AND V_SALDO < v_trx_amt and v_source<> 'H2H' THEN
                        v_error_code := -210;
                        v_error_msg :=  'Saldo anda tidak mencukupi, saldo anda saat ini sebesar '||V_SALDO;
                        RAISE v_err;
             END IF;
             
             
            BEGIN
                  SELECT GET_DOCNUM_FUND(v_doc_date,V_MODE) into v_doc_num from dual;
                         EXCEPTION
          WHEN OTHERS THEN
                        v_error_code := -6;
                        v_error_msg :=  SUBSTR('GET_DOCNUM_FUND'||SQLERRM,1,200);
                        RAISE v_err;
         END;
             BEGIN   
                SP_FL_JURNAL_FUND_MOVEMENT(
                              v_doc_num,
                              v_trx_type,
                              v_doc_date, 
                              v_client_cd,
                              v_trx_amt,
                              p_approved_user_id,
                              v_status,
                              v_error_code,
                              v_error_msg);
         EXCEPTION
          WHEN OTHERS THEN
                        v_error_code := -7;
                        v_error_msg :=  SUBSTR('SP_FL_JURNAL '||v_table_name||SQLERRM,1,200);
                        RAISE v_err;
         END;
         if v_error_code<0 then
     v_error_code := -8;
     v_error_msg := 'SP_FL_JURNAL '||v_table_name||' '||v_error_msg;
       raise v_err;
            end if;
  
    Begin
    
      UPDATE T_MANY_DETAIL SET FIELD_VALUE = v_doc_num where  UPDATE_SEQ= p_update_seq and update_date=p_update_date AND field_name ='DOC_NUM' AND UPD_STATUS='I';
     EXCEPTION
          WHEN OTHERS THEN
                        v_error_code := -9;
                        v_error_msg :=  SUBSTR('T_MANY_DETAIL'||SQLERRM,1,200);
                        RAISE v_err;
         END;
      --------------------END INSERT---------------------------
            
      ELSE
       -----------------------UPDATE --------------------------
      
       -----CEK UPDATE--------------------------
            
-------------AMBIL DATA ASLI---------
            BEGIN
            SELECT TABLE_ROWID INTO v_table_rowid from t_many_detail where update_seq = p_update_seq and update_date=p_update_date and upd_status = 'U' and rownum= 1 ;
            EXCEPTION
                  WHEN OTHERS THEN
                        v_error_code := -10;
                        v_error_msg :=  SUBSTR(v_table_name||SQLERRM,1,200);
                        RAISE v_err;
         END;
         
         BEGIN
         SELECT TRX_TYPE,DOC_DATE,CLIENT_CD,TRX_AMT INTO v_trx_type,v_doc_date,v_client_cd,v_trx_amt from t_fund_movement where rowid=v_table_rowid;
         EXCEPTION
                  WHEN OTHERS THEN
                        v_error_code := -11;
                        v_error_msg :=  SUBSTR(v_table_name||SQLERRM,1,200);
                        RAISE v_err;
         END;

-------------END AMBIL DATA ASLI---------
            BEGIN
            SELECT MAX(TRX_TYPE), MAX(DOC_DATE), MAX(CLIENT_CD), MAX(TRX_AMT)
                         INTO m_trx_type, m_doc_date, m_client_cd,m_trx_amt
                           FROM(
                           SELECT   DECODE(field_name,'TRX_TYPE',field_value, NULL) TRX_TYPE,
                                          DECODE(field_name,'DOC_DATE',field_value, NULL) DOC_DATE,
                                          DECODE(field_name,'CLIENT_CD',field_value, NULL) CLIENT_CD,
                                          DECODE(field_name,'TRX_AMT',field_value, NULL) TRX_AMT
                                          
                           FROM  T_MANY_DETAIL
                          WHERE T_MANY_DETAIL.update_date = p_update_date
                          AND T_MANY_DETAIL.table_name = v_table_name
                          AND T_MANY_DETAIL.update_seq       = p_update_seq
                        AND T_MANY_DETAIL.UPD_STATUS='I'
                          AND T_MANY_DETAIL.field_name IN ('TRX_TYPE', 'DOC_DATE','CLIENT_CD','TRX_AMT'));
                          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              v_error_code := -12;
                                          v_error_msg :=  SUBSTR(SQLERRM,1,200);
                                          RAISE v_err;
            WHEN OTHERS THEN
              v_error_code := -13;
              v_error_msg := SUBSTR(SQLERRM,1,200);
              RAISE v_err;
          END; 
       
              
              -------END CEK UPDATE-------------
      
      IF c_status ='C' or v_trx_type <> m_trx_type or v_doc_date <> m_doc_date or v_trx_amt <> m_trx_amt then
       BEGIN   
                Sp_Reverse_Fundmvmt(
            v_doc_date, --1 des 14
                              v_doc_num,
                              p_approved_user_id,
                              v_error_code,
                              v_error_msg);
         EXCEPTION
          WHEN OTHERS THEN
                        v_error_code := -14;
                        v_error_msg :=  SUBSTR('SP_FL_JURNAL '||v_table_name||SQLERRM,1,200);
                        RAISE v_err;
         END;
         if v_error_code<0 then
     v_error_code := -15;
     v_error_msg := 'SP_FL_JURNAL '||v_table_name||' '||v_error_msg;
       RAISE v_err;
            end if;
            

            
      end if;
 
 
    BEGIN
            SELECT TABLE_ROWID INTO v_table_rowid from t_many_detail where update_seq = p_update_seq and update_date=p_update_date and upd_status = 'U' and rownum= 1 ;
            EXCEPTION
                  WHEN OTHERS THEN
                        v_error_code := -18;
                        v_error_msg :=  SUBSTR(v_table_name||SQLERRM,1,200);
                        RAISE v_err;
         END;
         
     
     
   /*  
 BEGIN
            UPDATE T_FUND_MOVEMENT SET REVERSAL_JUR=v_doc_num WHERE rowid =v_table_rowid;
       EXCEPTION
          WHEN OTHERS THEN
                        v_error_code := -19;
                        v_error_msg :=  SUBSTR('Sp_T_MANY_DETAIL '||v_table_name||SQLERRM,1,200);
                        RAISE v_err;
         END;
     */
         -----------UPDATE RECORD UNTUK YANG DICANCEL-------------
        IF c_status='C' then
        
            
             BEGIN
            UPDATE T_MANY_DETAIL SET FIELD_VALUE=SYSDATE WHERE  UPDATE_SEQ=p_update_seq AND UPDATE_DATE=p_update_date AND FIELD_NAME='CANCEL_DT' ;
            EXCEPTION
                  WHEN OTHERS THEN
                        v_error_code := -20;
                        v_error_msg :=  SUBSTR(v_table_name||SQLERRM,1,200);
                        RAISE v_err;
         END;
         BEGIN
            UPDATE T_MANY_DETAIL SET FIELD_VALUE=p_approved_user_id WHERE UPDATE_SEQ=p_update_seq and update_date=p_update_date and FIELD_NAME='CANCEL_BY';
            EXCEPTION
          WHEN OTHERS THEN
                        v_error_code := -21;
                        v_error_msg :=  SUBSTR('Sp_T_MANY_DETAIL '||v_table_name||SQLERRM,1,200);
                        RAISE v_err;
         END;
      


         
       END IF;
         -----------END UPDATE RECORD UNTUK YANG DICANCEL-------------
      -----------------------END UPDATE--------------------------
      
    END IF;
      
      END LOOP;
      end if;--end menu name
      BEGIN   
                 Sp_T_Many_Approve(p_menu_name,
                     p_update_date,
                     p_update_seq,
                     p_approved_user_id,
                     p_approved_ip_address,
                      v_error_code,
                     v_error_msg);
         EXCEPTION
          WHEN OTHERS THEN
                        v_error_code := -19;
                        v_error_msg :=  SUBSTR('Sp_T_Many_Approve '||v_table_name||SQLERRM,1,200);
                        RAISE v_err;
         END;
           if v_error_code<0 then
     v_error_code := -20;
     v_error_msg := 'SP_FL_JURNAL '||v_table_name||' '||v_error_msg;
       RAISE v_err;
            end if;
            
            BEGIN
        SELECT COUNT(1) INTO v_cnt from T_MANY_DETAIL where update_seq =  p_update_seq and update_date=p_update_date and upd_status ='U';
        EXCEPTION
          WHEN OTHERS THEN
                        v_error_code := -23;
                        v_error_msg :=  SUBSTR('T_Many_Header '||SQLERRM,1,200);
                        RAISE v_err;
         END;
            
            IF v_cnt > 0 then
            
            BEGIN
            SELECT TABLE_ROWID INTO v_table_rowid from t_many_detail where update_seq = p_update_seq and  update_date=p_update_date and upd_status = 'U' and rownum= 1 ;
            EXCEPTION
                  WHEN OTHERS THEN
                        v_error_code := -24;
                        v_error_msg :=  SUBSTR(v_table_name||SQLERRM,1,200);
                        RAISE v_err;
         END;
            
            IF c_status ='C' or v_trx_type <> m_trx_type or v_doc_date <> m_doc_date or v_trx_amt <> m_trx_amt then
            BEGIN
            UPDATE T_FUND_MOVEMENT SET APPROVED_STS='C' WHERE rowid =v_table_rowid;
            EXCEPTION
                  WHEN OTHERS THEN
                        v_error_code := -25;
                        v_error_msg :=  SUBSTR(v_table_name||SQLERRM,1,200);
                        RAISE v_err;
         END;
 
     
      end if;
            END IF;

    COMMIT;
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
       ROLLBACK;
         p_error_code := -1;
         p_error_msg := SUBSTR(SQLERRM,1,200);
       RAISE;
END SP_T_FUND_MOVEMENT_APPROVE;