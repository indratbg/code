create or replace PROCEDURE SP_DROPDOWN_DEPOSIT ( P_ERROR_CD OUT NUMBER,
    P_ERROR_MSG OUT VARCHAR2 )IS
 V_ERROR_MSG    VARCHAR2(200);
  V_ERROR_CD     NUMBER(10);
    V_ERR          EXCEPTION;
BEGIN


BEGIN
DELETE FROM temp_dropdown_deposit;
 EXCEPTION
    WHEN OTHERS THEN
      V_ERROR_CD  := -5;
      V_ERROR_MSG := SUBSTR('DELETE TABLE temp_dropdown_deposit'||SQLERRM(SQLCODE),1,200);
      RAISE V_err;
    END;



begin
insert into temp_dropdown_deposit
SELECT * FROM 
(
SELECT d.client_cd,t.curr_val,t.db_cr_flg,T.DOC_DATE,t.folder_cd, t.folder_cd||'  '|| trim(gl_acct_cd)||'  '|| db_cr_flg||'  '|| curr_val||'  '|| to_char(doc_date,'dd/mm/yyyy')||'  '||ledger_nar as text,  xn_doc_num, t.tal_id			
						 FROM  T_ACCOUNT_LEDGER t, T_CLIENT_DEPOSIT d			
						 WHERE t.doc_date >'01jan2015'
             AND trim(t.gl_acct_cd)= '2491' AND approved_sts ='A' AND t.xn_doc_num = d.doc_num(+)			
						 AND t.tal_id= d.tal_id(+) and d.doc_num is null and d.tal_id is null			
) ;       
 EXCEPTION
    WHEN OTHERS THEN
      V_ERROR_CD  := -10;
      V_ERROR_MSG := SUBSTR('INSERT INTO TABLE temp_dropdown_deposit'||SQLERRM(SQLCODE),1,200);
      RAISE V_err;
    END;
 
 P_ERROR_CD     := 1 ;
  P_ERROR_MSG    := '';
  
EXCEPTION
WHEN V_ERR THEN
  ROLLBACK;
  P_ERROR_MSG := V_ERROR_MSG;
  P_ERROR_CD  := V_ERROR_CD;
WHEN OTHERS THEN
  P_ERROR_CD  := -1 ;
  P_ERROR_MSG := SUBSTR(SQLERRM(SQLCODE),1,200);
  RAISE;
END SP_DROPDOWN_DEPOSIT;