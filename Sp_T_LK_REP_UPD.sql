create or replace 
PROCEDURE Sp_T_LK_REP_UPD(
	   P_end_DATE DATE,
	   P_LINE_NUM T_LK_REP.line_num%TYPE,
	   P_COL2            T_LK_REP.col2%TYPE,
	   P_COL4           T_LK_REP.col4%TYPE,
	   P_COL5           T_LK_REP.col5%TYPE,
	   P_COL6           T_LK_REP.col6%TYPE,
	   P_COL7           T_LK_REP.col7%TYPE,
	   P_UPD_STATUS T_LK_REP.col1%TYPE,
	   P_USER_ID VARCHAR2,
	   P_ERROR_CODE OUT NUMBER,
	   P_ERROR_MSG OUT VARCHAR2)
 IS
tmpVar NUMBER;
/******************************************************************************
   NAME:       SP_LK_KONSOL_UPD
   PURPOSE:    

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        28/05/2014          1. Created this procedure.

   NOTES:

   

******************************************************************************/

 v_cnt NUMBER;					 
								
v_err EXCEPTION;
v_error_code NUMBER;
v_error_msg VARCHAR2(200);						
BEGIN
   	 BEGIN
	 SELECT COUNT(1) INTO v_cnt
	 FROM T_LK_REP
	 WHERE report_date = p_end_date;
	 EXCEPTION
	 WHEN NO_DATA_FOUND THEN
	v_Cnt := 0;
	WHEN OTHERS THEN
		 				v_error_code := -2;
						v_error_msg := SUBSTR('Retrieve T_LK_REP'||SQLERRM,1,200);
						RAISE v_err;
		END;	
	
	 
	 IF v_cnt = 0  AND P_UPD_STATUS = 'I' THEN
	 
	    BEGIN
	    INSERT INTO T_LK_REP
	 	SELECT 		p_end_date AS REPORT_DATE, LINE_NUM, COL1, 
		   COL2, COL3, NULL COL4, 
		   COL5, COL6, COL7, 
		   COL8, COL9, COLX, 
		   CRE_DT, p_user_id AS USER_ID
		FROM T_LK_REP
		WHERE report_date = ( SELECT MAX(report_date)
		                                                FROM T_LK_REP
														WHERE report_date < p_end_date);
		EXCEPTION
		WHEN OTHERS THEN
		 				v_error_code := -3;
						v_error_msg := SUBSTR('Insert blank T_LKREP  '||SQLERRM,1,200);
						RAISE v_err;
		END;				  									
		
		BEGIN
		  UPDATE T_LK_REP
			   SET col2 = TO_CHAR(p_end_date,'yyyymmdd')
		 WHERE report_date =p_end_date
			   AND line_num = 3;
			   EXCEPTION
		     WHEN OTHERS THEN
		 				v_error_code := -4;
						v_error_msg := SUBSTR('UPdate line 3 T_LKREP  '||SQLERRM,1,200);
						RAISE v_err;
		END;			   
			   				
	 END IF;
	 
	  IF v_cnt > 0  AND P_UPD_STATUS = 'U' THEN
   
   	  	 	   BEGIN
   	  	 	   UPDATE T_LK_REP
			   SET col2 = p_col2,
			             col4 = p_col4,
			             col5 = p_col5,
			             col6 = p_col6,
			             col7 = p_col7
			   WHERE report_date =p_end_date
			   AND line_num = p_line_num;
			   EXCEPTION
		     WHEN OTHERS THEN
		 				v_error_code := -4;
						v_error_msg := SUBSTR('Insert blank T_LKREP  '||SQLERRM,1,200);
						RAISE v_err;
		END;		
      END IF;
	  
	  IF p_upd_status = 'S' THEN 
	  
	  	 			  BEGIN
	  	 			DELETE FROM T_LK_REP_SAVE
					WHERE report_date = p_end_date;
					EXCEPTION
							WHEN OTHERS THEN
		 				v_error_code := -5;
						v_error_msg := SUBSTR('Delete T_LK_REP_SAVE  '||SQLERRM,1,200);
						RAISE v_err;
						END;		
					
					BEGIN
					INSERT INTO T_LK_REP_SAVE
					SELECT REPORT_DATE, 
					   LINE_NUM, COL1, COL2, 
					   COL3, COL4, COL5, 
					   COL6, COL7, COL8, 
					   COL9, CRE_DT,USER_ID
					FROM LAP_LK_KONSOL
					WHERE report_date = p_end_date
					AND user_id = p_user_id;
					EXCEPTION
					WHEN OTHERS THEN
		 				v_error_code := -6;
						v_error_msg := SUBSTR('Insert to  T_LK_REP_SAVE '||SQLERRM,1,200);
						RAISE v_err;
						END;		
					
	  END IF;
	  
			  COMMIT;	   
  P_error_code:= 1;
	P_error_msg := '';
   EXCEPTION
     WHEN v_err THEN
	        P_error_code := v_error_code;
				P_error_msg := v_error_msg;
				ROLLBACK;
     WHEN NO_DATA_FOUND THEN
       NULL;
     WHEN OTHERS THEN
       -- Consider logging the error and then re-raise
	   ROLLBACK;
	   
	   P_error_code := -1;
	   P_error_msg :=  SUBSTR(SQLERRM,1,200);
       RAISE;
END Sp_T_LK_REP_UPD;