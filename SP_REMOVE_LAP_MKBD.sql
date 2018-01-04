create or replace 
procedure SP_REMOVE_LAP_MKBD (P_TABLE_NAME VARCHAR2,
									P_USER_ID LAP_MKBD_VD51.USER_ID%TYPE,
									P_MKBD_DATE LAP_MKBD_VD51.MKBD_DATE%TYPE,
									p_error_code					OUT NUMBER,
									p_error_msg					OUT VARCHAR2)
									IS
V_ERR EXCEPTION;
V_SQL VARCHAR2(200);	
V_ERROR_CD NUMBER(5);
V_ERROR_MSG VARCHAR2(200);
BEGIN
  BEGIN
	 V_SQL := 'DELETE FROM ' || P_TABLE_NAME || ' WHERE MKBD_DATE = TO_DATE('''||P_MKBD_DATE||''',''YYYY-MM-DD HH24:MI:SS'')'; 
  EXECUTE IMMEDIATE V_SQL;
  EXCEPTION
        WHEN OTHERS THEN
      ROLLBACK;
            V_ERROR_CD := -2;
           V_ERROR_MSG := V_SQL;
            RAISE V_ERR;
     END;       
  
  COMMIT;
   	p_error_code := 1;
	p_error_msg := '';
  
EXCEPTION
    WHEN V_ERR THEN
    ROLLBACK;
      p_error_code := V_ERROR_CD;
           p_error_msg :=V_ERROR_MSG;
        WHEN OTHERS THEN
      ROLLBACK;
            p_error_code := -1;
           p_error_msg := substr(SQLERRM(SQLCODE),1,200);
            raise ;
			
END SP_REMOVE_LAP_MKBD;