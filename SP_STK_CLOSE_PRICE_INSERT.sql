create or replace PROCEDURE SP_STK_CLOSE_PRICE_INSERT(
p_STK_DATE t_close_price.STK_DATE%type,
p_STK_CD   t_close_price.STK_CD%type,
p_STK_NAME t_close_price.STK_NAME%type,
p_STK_PREV t_close_price.STK_PREV%type,
p_STK_HIGH t_close_price.STK_HIGH%type,
p_STK_LOW  t_close_price.STK_LOW%type,
p_STK_CLOS t_close_price.STK_CLOS%type,
p_STK_VOLM t_close_price.STK_VOLM%type,
p_STK_AMT  t_close_price.STK_AMT%type,
p_STK_INDX t_close_price.STK_INDX%type,
p_STK_PIDX t_close_price.STK_PIDX%type,
p_STK_ASKP t_close_price.STK_ASKP%type,
p_STK_ASKV t_close_price.STK_ASKV%type,
p_STK_ASKF t_close_price.STK_ASKF%type,
p_STK_BIDP t_close_price.STK_BIDP%type,
p_STK_BIDV t_close_price.STK_BIDV%type,
p_STK_BIDF t_close_price.STK_BIDF%type,
p_STK_OPEN t_close_price.STK_OPEN%type,
p_BIDP_ZERO t_close_price.STK_PREV%type,
P_ISIN_CODE 	T_CLOSE_PRICE.ISIN_CODE%TYPE,--27APR2016
p_user_id t_close_price.user_id%type,
p_ip_address t_temp_header.ip_address%type,
p_error_code out number,
p_error_msg out varchar2

) IS

tmpVar NUMBER;
v_bidv t_close_price.STK_BIDV%type;
v_bidp t_close_price.STK_BIDP%type;
v_clos t_close_price.STK_CLOS%type;
v_error_code				NUMBER;
v_error_msg				VARCHAR2(1000);
v_err EXCEPTION;	
V_UPDATE_DATE T_TEMP_DETAIL.UPDATE_DATE%TYPE;
V_UPDATE_SEQ T_TEMP_DETAIL.UPDATE_SEQ%TYPE;
v_sign char(1);
V_CNT NUMBER(1);
V_OLD_STK_CD T_CHANGE_STK_CD.STK_CD_OLD%TYPE;
BEGIN
   tmpVar := 0;
   begin
    select dflg1 into v_sign from mst_sys_param where param_id='STK CLOSE PRICE' and param_cd1='CEKBIDP' ;
  EXCEPTION   
			   WHEN OTHERS THEN
			   v_error_code := -5;
			   v_error_msg:=  substr('SELECT mst_sys_param'||SQLERRM,1,200);
			   raise v_err; 
			   END;
         
   if p_stk_clos = 0 then
   	  v_clos := p_stk_prev;
	else
		v_clos := p_stk_clos;
	end if;
 

   if v_sign='Y' and p_bidp_zero >= 50 then  -- lebih dr 50%
	  v_bidp := v_clos;
   else
   	   v_bidp := p_stk_bidp;
	end if;

  if p_stk_bidv is null or p_stk_bidv = null  then
  v_bidv :=0;
  else
  v_bidv := P_STK_BIDV;
  end if;

BEGIN
			SP_T_CLOSE_PRICE_UPD(P_STK_DATE,
									P_STK_CD,
									P_STK_DATE,
									P_STK_CD,
									P_STK_NAME,
									P_STK_PREV,
									P_STK_HIGH,
									P_STK_LOW,
									P_STK_CLOS,
									P_STK_VOLM,
									P_STK_AMT,
									P_STK_INDX,
									P_STK_PIDX,
									P_STK_ASKP,
									P_STK_ASKV,
									P_STK_ASKF,
									V_BIDP,
									V_BIDV,
									P_STK_BIDF,
									P_STK_OPEN,
									TRUNC(SYSDATE),
									P_USER_ID,
									NULL,
									NULL,
									P_ISIN_CODE,
									'I',
									p_ip_address,
									NULL,
									v_error_code,
									v_error_msg
			);
 exception
  WHEN OTHERS THEN
   v_error_code := -6;
   v_error_msg:=  substr('INSERT t_close_price '||SQLERRM,1,200);
   raise v_err;
  end;
  if v_error_code <0 then
      v_error_code := -7;
		v_error_msg := 'SP_T_CLOSE_PRICE_UPD '||v_error_msg;
		RAISE v_err;
  end if;
  

  --UPDATE MST_COUNTER FIELD ISIN CODE
  BEGIN
		UPDATE MST_COUNTER SET ISIN_CODE=P_ISIN_CODE , UPD_BY=P_USER_ID, UPD_DT=SYSDATE WHERE STK_CD=P_STK_CD;
   EXCEPTION
  WHEN OTHERS THEN
   v_error_code := -8;
   v_error_msg:=  substr('UPDATE ISIN CODE AT MST_COUNTER'||SQLERRM,1,200);
   raise v_err;
  end;
  
  ------CHANGE TICKER CODE-------------
  ---INSERT NEW LINE FOR OLD STK_CD IF OLD STK CD HAS CHANGE
  BEGIN
   SELECT COUNT(1),STK_CD_OLD INTO V_CNT, V_OLD_STK_CD FROM T_CHANGE_STK_CD
   WHERE P_STK_DATE BETWEEN EFF_DT AND GET_DUE_DATE(2,EFF_DT)
   AND STK_CD_NEW=P_STK_CD
   GROUP BY STK_CD_OLD;
  EXCEPTION
  WHEN NO_DATA_FOUND THEN
	V_CNT:=0;
  WHEN OTHERS THEN
   v_error_code := -9;
   v_error_msg:=  substr('CHECK NEW STOCK CODE FROM T_CHANGE_STK_CD '||SQLERRM,1,200);
   raise v_err;
  end;
  IF V_CNT>0 THEN
	
BEGIN
			SP_T_CLOSE_PRICE_UPD(P_STK_DATE,
									V_OLD_STK_CD,
									P_STK_DATE,
									V_OLD_STK_CD,
									P_STK_NAME,
									P_STK_PREV,
									P_STK_HIGH,
									P_STK_LOW,
									P_STK_CLOS,
									P_STK_VOLM,
									P_STK_AMT,
									P_STK_INDX,
									P_STK_PIDX,
									P_STK_ASKP,
									P_STK_ASKV,
									P_STK_ASKF,
									V_BIDP,
									V_BIDV,
									P_STK_BIDF,
									P_STK_OPEN,
									TRUNC(SYSDATE),
									P_USER_ID,
									NULL,
									NULL,
									P_ISIN_CODE,
									'I',
									p_ip_address,
									NULL,
									v_error_code,
									v_error_msg
			);
 exception
  WHEN OTHERS THEN
   v_error_code := -20;
   v_error_msg:=  substr('INSERT t_close_price '||SQLERRM,1,200);
   raise v_err;
  end;
  if v_error_code <0 then
      v_error_code := -25;
		v_error_msg := 'SP_T_CLOSE_PRICE_UPD '||v_error_msg;
		RAISE v_err;
  end if;
  
     BEGIN
			   SELECT  MAX(A.UPDATE_DATE), MAX(A.UPDATE_SEQ)  INTO V_UPDATE_DATE,V_UPDATE_SEQ 
			           FROM   (SELECT  UPDATE_DATE,UPDATE_SEQ 
			                  FROM  T_TEMP_DETAIL  
			                  WHERE UPDATE_DATE>=TRUNC(SYSDATE)-1--04JAN2016, SUPAYA MENGGUNAKAN INDEX 
                        AND table_name ='T_CLOSE_PRICE'
			                  AND FIELD_NAME='STK_DATE'  
			                  AND  FIELD_VALUE=  TO_CHAR(P_STK_DATE,'YYYY/MM/DD HH24:MI:SS'))  a,
			                  (SELECT  UPDATE_DATE,UPDATE_SEQ 
			                  FROM  T_TEMP_DETAIL  
                        WHERE UPDATE_DATE>=TRUNC(SYSDATE)-1--04JAN2016, SUPAYA MENGGUNAKAN INDEX
			                  AND  table_name ='T_CLOSE_PRICE'
			                  AND  FIELD_NAME='STK_CD'  
			                  AND  FIELD_VALUE=V_OLD_STK_CD
			                  )  b
			                  WHERE  a.update_date =  b.update_date
			                    AND a.update_seq=b.update_seq;
			    EXCEPTION   
			   WHEN OTHERS THEN
			   v_error_code := -30;
			   v_error_msg:=  substr('SELECT T_TEMP_DETAIL'||SQLERRM,1,200);
			   raise v_err; 
			   END;
  
  BEGIN
	SP_T_TEMP_APPROVE ( 'T_CLOSE_PRICE',
					   v_update_date,
					   v_update_seq,
					   p_user_id,
					   p_ip_address,
						v_error_code,
					   v_error_msg
	   );
	 exception
  WHEN OTHERS THEN
   v_error_code := -35;
   v_error_msg:=  substr('SP_T_TEMP_APPROVE '||SQLERRM,1,200);
   raise v_err;
  end;
  if v_error_code <0 then
      v_error_code := -40;
		v_error_msg := 'SP_T_TEMP_APPROVE '||v_error_msg;
		RAISE v_err;
  end if;
	
  
  END IF;
  
  ------CHANGE TICKER CODE-------------
--update_t temp header 

			    BEGIN
			   SELECT  MAX(A.UPDATE_DATE), MAX(A.UPDATE_SEQ)  INTO V_UPDATE_DATE,V_UPDATE_SEQ 
			           FROM   (SELECT  UPDATE_DATE,UPDATE_SEQ 
			                  FROM  T_TEMP_DETAIL  
			                  WHERE  table_name ='T_CLOSE_PRICE'
			                  AND FIELD_NAME='STK_DATE'  
			                  AND  FIELD_VALUE=  TO_CHAR(P_STK_DATE,'YYYY/MM/DD HH24:MI:SS'))  a,
			                  (SELECT  UPDATE_DATE,UPDATE_SEQ 
			                  FROM  T_TEMP_DETAIL  
			                  WHERE  table_name ='T_CLOSE_PRICE'
			                  AND  FIELD_NAME='STK_CD'  
			                  AND  FIELD_VALUE=P_STK_CD
			                  )  b
			                  WHERE  a.update_date =  b.update_date
			                    AND a.update_seq=b.update_seq;
			    EXCEPTION   
			   WHEN OTHERS THEN
			   v_error_code := -50;
			   v_error_msg:=  substr('SELECT T_TEMP_DETAIL'||SQLERRM,1,200);
			   raise v_err; 
			   END;
			   /*
			   
			   BEGIN
			   UPDATE T_TEMP_HEADER SET APPROVED_STATUS='A',APPROVED_USER_ID= P_USER_ID, APPROVED_IP_ADDRESS=P_IP_ADDRESS,APPROVED_DATE=SYSDATE;
			    EXCEPTION   
			   WHEN OTHERS THEN
			   v_error_code := -9;
			   v_error_msg:=  'UPDATE T_TEMP_HEADER';
			   raise v_err; 
			   END;
			   
   begin
   INSERT INTO T_CLOSE_PRICE (
   STK_DATE, STK_CD, STK_NAME,
   STK_PREV, STK_HIGH, STK_LOW,
   STK_CLOS, STK_VOLM, STK_AMT,
   STK_INDX, STK_PIDX, STK_ASKP,
   STK_ASKV, STK_ASKF, STK_BIDP,
   STK_BIDV, STK_BIDF, STK_OPEN,
   CRE_DT,USER_ID,APPROVED_DT,
   APPROVED_BY,APPROVED_STAT)
	VALUES ( p_STK_DATE, p_STK_CD, p_STK_NAME,
	p_STK_PREV, p_STK_HIGH, p_STK_LOW,
	p_STK_CLOS, p_STK_VOLM, p_STK_AMT,
	p_STK_INDX, p_STK_PIDX, p_STK_ASKP,
	p_STK_ASKV, p_STK_ASKF, V_BIDP,
	p_STK_BIDV, p_STK_BIDF, p_STK_OPEN,
	TRUNC(SYSDATE),P_USER_ID,SYSDATE,
	P_USER_ID,'A');
	exception
	when others then
		-- RAISE_APPLICATION_ERROR(-20100,'  insert to T_CLOSE_PRICE '||p_stk_cd||SQLERRM);
		  v_error_code := -10;
   v_error_msg:= ' INSERT t_close_price '||p_stk_cd||SQLERRM;
   raise v_err; 
	end;
*/
	BEGIN
	SP_T_TEMP_APPROVE ( 'T_CLOSE_PRICE',
					   v_update_date,
					   v_update_seq,
					   p_user_id,
					   p_ip_address,
						v_error_code,
					   v_error_msg
	   );
	 exception
  WHEN OTHERS THEN
   v_error_code := -55;
   v_error_msg:=  substr('SP_T_TEMP_APPROVE '||SQLERRM,1,200);
   raise v_err;
  end;
  
  if v_error_code <0 then
     v_error_code := -60;
     v_error_msg := 'SP_T_TEMP_APPROVE '||v_error_msg;
     RAISE v_err;
  end if;
	
	
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
       -- Consider logging the error and then re-raise
      ROLLBACK;
	   p_error_code := -1;
	   p_error_msg := SUBSTR(SQLERRM,1,200);
       RAISE;
END SP_STK_CLOSE_PRICE_INSERT;