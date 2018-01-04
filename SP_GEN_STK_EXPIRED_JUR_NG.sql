create or replace 
PROCEDURE "SP_GEN_STK_EXPIRED_JUR_NG"  (
	   	  		  								  p_stk_cd MST_COUNTER.stk_cd%TYPE,
	   	  		  								  p_withdraw_dt DATE,
												  p_doc_rem				T_STK_MOVEMENT.doc_rem%TYPE,
												  p_user_id 			T_STK_MOVEMENT.user_id%TYPE,
												  P_IP_ADDRESS T_MANY_HEADER.IP_ADDRESS%TYPE,
												  p_error_code					OUT			NUMBER,
	   											  p_error_msg					OUT			VARCHAR2)
IS

-- utk menjurnal WITHDRAW STK pd expiry date saham RIGHT / WARRANT
-- jurnal date = sehari sesudah  tgl expiry


CURSOR csr_stk(a_bgn_dt DATE, a_end_dt DATE) IS
SELECT   b.client_cd, m.client_name, m.client_type_1||m.client_type_2||m.client_type_3 AS client_type,
		 			  m.client_type_1, m.client_type_3,
                    b.stk_cd, b.on_hand, b.on_37, t.on_custody,
                      t.on_lent, t.on_borrow, t.on_ksei, t.on_bank, NVL(t.repo_client,0) repo_client,
					  t.on_bae
FROM(  SELECT client_cd, stk_cd,  SUM(beg_onh+ mvmt)  on_hand,
                                  SUM(beg_37+ mvmt_37)  on_37
	   FROM(    SELECT client_cd, stk_cd,
				       DECODE(trim(gl_Acct_cd),'36',qty,0) beg_onh,
				       DECODE(trim(gl_Acct_cd),'37',qty,0) beg_37,
					   0 mvmt,
					   0 mvmt_37
				FROM T_SECU_BAL
				WHERE bal_dt = a_bgn_dt
				AND stk_cd = p_stk_cd
				AND gl_acct_cd IN ( '36','37')
				UNION ALL
				SELECT client_Cd, stk_cd, 0 beg_onh, 0 beg_37,
				DECODE(trim(gl_Acct_cd),'36',1,0) *
				DECODE(db_cr_flg,'D',-1,1) * (total_share_qty + withdrawn_share_qty) mvmt,
				DECODE(trim(gl_Acct_cd),'37',1,0) *
				DECODE(db_cr_flg,'D',-1,1) * (total_share_qty + withdrawn_share_qty) mvmt_37
				FROM T_STK_MOVEMENT
				WHERE doc_dt BETWEEN  a_bgn_dt AND a_end_dt
			   AND SUBSTR(DOC_NUM,5,3) IN ('RSN','WSN','JVB','JVS')
				AND gl_acct_cd IS NOT NULL
				AND gl_acct_cd IN ( '36','37')
				AND doc_stat = '2'
				AND stk_cd = p_stk_cd )
	WHERE beg_onh > 0 OR mvmt <> 0 OR beg_37 > 0 OR mvmt_37 <> 0
	GROUP BY client_cd, stk_cd) b,
	( SELECT *
	   FROM T_STKHAND
	   WHERE stk_cd = p_stk_cd) t,
    MST_CLIENT m
WHERE b.client_cd = m.client_cd
AND (b.on_hand > 0 OR b.on_37 > 0)
AND b.client_cd = t.client_cd;

--AND B.CLIENT_cD IN ('WIDJ002R');

--AND b.client_cd IN ( 'TANV001M')






rec csr_stk%ROWTYPE;

--v_mvmt_qty 	 T_STKHAND.bal_qty%TYPE;
v_receive_qty 	 T_STKHAND.bal_qty%TYPE;
v_withdraw_qty 	 T_STKHAND.bal_qty%TYPE;

--v_bal_qty 	 T_STKHAND.bal_qty%TYPE;
--v_on_hand 	 T_STKHAND.bal_qty%TYPE;
v_doc_num	 T_STK_MOVEMENT.doc_num%TYPE;
v_deb_acct T_STK_MOVEMENT.gl_acct_cd%TYPE;
v_cre_acct T_STK_MOVEMENT.gl_acct_cd%TYPE;
v_gl_acct T_STK_MOVEMENT.gl_acct_cd%TYPE;
v_coy_client_cd     MST_CLIENT.client_cd%TYPE;
--v_doc_stat T_STK_MOVEMENT.doc_stat%TYPE;
v_odd_lot			   insistpro.T_STK_MOVEMENT.odd_lot_doc%TYPE;
v_lot_size             MST_COUNTER.lot_size%TYPE;
v_lot                  T_STK_MOVEMENT.total_lot%TYPE;
v_remarks			   T_STK_MOVEMENT.doc_rem%TYPE;
v_s_d_type	 T_STK_MOVEMENT.s_d_type%TYPE;
v_margin_acct 		   T_STK_MOVEMENT.gl_acct_cd%TYPE;
v_dt_bgn1			   DATE;
v_dt_bgn			   DATE;
v_jur_type VARCHAR(20);

v_cnt 			 NUMBER;

 v_err EXCEPTION;
v_error_code							NUMBER;
v_error_msg							VARCHAR2(200);
V_DB_CR_FLG VARCHAR(1);
V_DOC_DATE DATE;
v_mvmt_type VARCHAR2(20);
v_client_type CHAR(1);
V_MENU_NAME T_MANY_HEADER.MENU_NAME%TYPE :='CORPORATE ACTION JOURNAL SCHED';
V_UPDATE_DATE DATE;
V_UPDATE_SEQ NUMBER(7);
BEGIN


v_dt_bgn1 :=   p_withdraw_dt  - TO_CHAR(p_withdraw_dt ,'dd') + 1;

-- CEK MONTH END 
BEGIN
	SELECT COUNT(1) INTO v_cnt
	FROM T_STKBAL
	WHERE bal_dt = v_dt_bgn1;
	EXCEPTION
	WHEN NO_DATA_FOUND THEN
	  v_cnt := 0;
	  v_error_code := -2;
	  v_error_msg := SUBSTR('GEN_STK_EXPIRED_JUR  FAILED, BELUM MONTH END ',1,200);
	  RAISE V_err;
	 WHEN OTHERS THEN
	  v_error_code := -3;
	  v_error_msg := SUBSTR('Cek T_STKBAL '||SQLERRM,1,200);
	  RAISE V_err;
	END;
	
BEGIN	
SELECT MAX(bal_dt) INTO v_dt_bgn
FROM T_SECU_BAL
WHERE bal_dt <= v_dt_bgn1;
EXCEPTION
	WHEN NO_DATA_FOUND THEN
	  v_error_code := -4;
	  v_error_msg := SUBSTR('T_SECU_BAL NOT FOUND ',1,200);
	  RAISE V_err;
	 WHEN OTHERS THEN
	  v_error_code := -5;
	  v_error_msg := SUBSTR('Cek T_SECU_BAL '||SQLERRM,1,200);
	  RAISE V_err;
	END;
	
BEGIN
   SELECT trim(other_1) INTO v_coy_client_cd
   FROM MST_COMPANY;
   EXCEPTION
   WHEN NO_DATA_FOUND THEN
    v_error_code := -6;
	  v_error_msg := SUBSTR('COMPANY NOT FOUND ',1,200);
	  RAISE V_err;
	 WHEN OTHERS THEN
	  v_error_code := -7;
	  v_error_msg := SUBSTR('RETRIEVE MST COMPANY  '||SQLERRM,1,200);
	  RAISE V_err;
   END;

   BEGIN
   SELECT  lot_size
   INTO	   v_lot_size
   FROM	  MST_COUNTER
   WHERE  stk_cd = P_STK_CD;
   EXCEPTION
   WHEN NO_DATA_FOUND THEN
   v_error_code := -8;
	  v_error_msg := SUBSTR(P_STK_CD||'  not in the STOCK MASTER',1,200);
	  RAISE V_err;
	 WHEN OTHERS THEN
	  v_error_code := -9;
	  v_error_msg := SUBSTR('RETRIEVE MST COUNTER  '||SQLERRM,1,200);
	  RAISE V_err;
   		   END;
   
         
/*
     BEGIN
SELECT dstr1 INTO v_margin_acct
	FROM MST_SYS_PARAM
	WHERE param_id = 'SYSTEM'
	AND   param_cd1 = 'MARGIN'
	AND   param_cd2 = 'SECULDG'
	AND P_withdraw_DT BETWEEN ddate1 AND ddate2;   
	EXCEPTION
   WHEN NO_DATA_FOUND THEN
   		v_margin_acct := '12';
   		--RAISE_APPLICATION_ERROR(-20100,'FAIL to get Margin acct'||SQLERRM);
   END;

	*/



   OPEN csr_stk(v_dt_bgn, p_withdraw_dt );
   LOOP
	 FETCH csr_stk INTO rec;
	 EXIT WHEN csr_stk%NOTFOUND;

	  v_withdraw_Qty := 0;
	  v_receive_Qty := 0;
      
  
       IF rec.on_hand <> 0 THEN
					   v_withdraw_Qty := rec.on_hand;
					   v_receive_qty := 0;
					   v_jur_type := 'WSN';
					   v_s_d_type := 'C';
						v_mvmt_type := 'WHDR';
		   --v_doc_num := Get_Stkmove_Docnum(p_withdraw_dt,rec.stk_cd,v_jur_type);17 jun
 		   --v_cnt  := v_cnt + 1;
 		   --v_doc_num := SUBSTR(v_doc_num,1,11)||LPAD(trim(TO_CHAR(v_cnt)),5,'0');
       
     
			V_DOC_NUM := Get_Stk_Jurnum(  p_withdraw_dt,v_jur_type );
		
  
			
			
		   IF MOD(v_withdraw_Qty,v_lot_size) = 0 THEN
			   v_odd_lot := 'N';
			ELSE
			   v_odd_lot := 'Y';
			END IF;

		   v_lot := FLOOR(v_withdraw_Qty / v_lot_size);

			   IF TRIM(rec.client_cd) = trim(v_coy_client_cd) OR (rec.client_type_1 = 'H') THEN
	 			  --v_gl_acct := 10;
				  v_client_type := rec.client_type_1;
	 			ELSE
	 			/*  IF F_Cek_Margin(rec.client_type_3) = 'M' THEN
	 			   	  v_gl_acct := v_margin_acct;
	 			   ELSE
	 	    		  v_gl_acct := '12';
				   END IF;*/
				     v_client_type :='%';
	 			END IF;			

			   -- v_cre_acct := v_gl_acct;
				--v_deb_acct := '36';
   
		--GET GL_ACCT_CD
		BEGIN
		Sp_Get_Secu_Acct ( P_withdraw_dt,
						   v_client_type,
						   v_mvmt_type,
						   v_deb_acct,
						   v_cre_acct,
						   v_error_code,
						   v_error_msg);
		EXCEPTION
			WHEN OTHERS THEN
			v_error_code := -10;
			v_error_msg :=SUBSTR('SP_GET_SECU_ACCT  '||SQLERRM(SQLCODE),1,200);
			RAISE V_ERR;
		END;
		IF v_error_code<0 THEN
			v_error_code := -15;
			v_error_msg :=SUBSTR('SP_GET_SECU_ACCT  '||SQLERRM(SQLCODE),1,200);
			RAISE V_ERR;
		END IF;		
    
   
    
/*
			   BEGIN
--				    Sp_Secu_Jurnal_Tes( v_doc_num,NULL,P_distrib_dt,
				    Sp_Secu_Jurnal( v_doc_num,NULL,P_withdraw_dt,
					        rec.client_cd,P_STK_Cd,v_s_d_type,
					       v_odd_lot,   v_lot,   v_receive_qty,
						   p_doc_rem,'2',0,
						   v_withdraw_qty,NULL,NULL,
						   v_deb_acct,   rec.client_type, 'D',
						   P_USER_ID, SYSDATE,NULL,
						   NULL,  NULL, 1,
						  0, 2, v_cre_acct, 'C');

			   EXCEPTION
			   		WHEN OTHERS THEN
					  v_error_code := -6;
					  v_error_msg := SUBSTR('Sp_Secu_Jurnal  '||rec.client_cd||SQLERRM,1,200);
					  RAISE V_err;
			   		 END;
*/




		--EXECUTE SP HEADER
         BEGIN
        Sp_T_Many_Header_Insert(V_MENU_NAME,
								 'I',
								 P_USER_ID,
								 P_IP_ADDRESS,
								 NULL,
								 V_UPDATE_DATE,
								 V_UPDATE_SEQ,
								 v_error_code,
								 v_error_msg);
        EXCEPTION
              WHEN OTHERS THEN
                 v_error_code := -20;
                 v_error_msg := SUBSTR('SP_T_MANY_HEADER_INSERT '|| SQLERRM(SQLCODE),1,200);
                RAISE V_ERR;
            END;
			

V_DOC_DATE :=P_withdraw_dt;

FOR I IN 1..2 LOOP

IF I =1 THEN
	V_DB_CR_FLG :='D';
	v_gl_acct :=v_deb_acct;
ELSE
	V_DB_CR_FLG :='C';
	v_gl_acct :=v_cre_acct;
END IF;
					 BEGIN
				Sp_T_Stk_Movement_Upd(	V_DOC_NUM,--SEARCH DOC_NUM
										V_DB_CR_FLG,--DB_CR_FLG
										I,--SEQNO
										V_DOC_NUM,--DOC_NUM
										NULL,--REF DOC NUM
										V_DOC_DATE,--DOC_DT
										REC.CLIENT_CD,--CLIENT_CD
										P_STK_CD,--STK_CD
										v_s_d_type,--S_D_TYPE
										v_odd_lot,--ODD LOT DOC
										v_lot,--TOTAL LOT
										v_receive_qty,--TOTAL SHARE QTY
										p_doc_rem,--DOC REM
										'2',--DOC_STAT
										v_withdraw_Qty,--WITHDRAWN_SHARE_QTY	
										NULL,--REGD_HLDR
										NULL,--WITHDRAW_REASON_CD	
										v_gl_acct,--GL_ACCT_CD
										 rec.client_type,--ACCT_TYPE	
										V_DB_CR_FLG,--DB_CR_FLG		
										'L',--STATUS
										V_DOC_DATE,--DUE_DT_FOR_CERT
										NULL,--STK_STAT
										NULL,--DUE_DT_ONHAND	
										I,--SEQNO	
										'0',--PRICE
										NULL,--PREV_DOC_NUM
										'N',--MANUAL
										v_mvmt_type,--JUR_TYPE	
										NULL,--BROKER	
										NULL,--P_REPO_REF,
                    null,--RATIO
                    null,--RATIO_REASON
										P_USER_ID,--USER ID
										SYSDATE,--CRE_DT
										NULL,--P_UPD_BY,
										NULL,--P_UPD_DT,
										'I',--P_UPD_STATUS,
										P_IP_ADDRESS,
										NULL,--P_CANCEL_REASON,
										V_UPDATE_DATE,--UPDATE DATE
										V_UPDATE_SEQ,--UPDATE_SEQ
										I,--RECORD SEQ
										v_error_code,
										v_error_msg);
		 
			EXCEPTION
				WHEN OTHERS THEN
					 v_error_code := -25;
					 v_error_msg :=SUBSTR('SP_T_STK_MOVEMENT_UPD '||SQLERRM(SQLCODE),1,200);
					RAISE V_ERR;
			END;
		
	IF v_error_code < 0 THEN
	    v_error_code := -30;
		v_error_msg := SUBSTR('SP_T_STK_MOVEMENT_UPD '||v_error_msg,1,200);
		RAISE V_ERR;
	END IF;
	
END LOOP;	
					 
					 
					 
					 
				/*	 
					 
				   BEGIN
				   UPDATE T_STKHAND
				      SET ON_HAND = ON_HAND - v_withdraw_Qty,
					  	  bal_qty =   bal_qty  - v_withdraw_Qty,   
					        UPD_DT = SYSDATE,
		   					upd_by = p_user_id
					WHERE CLIENT_CD = REC.CLIENT_CD
					AND STK_CD = P_STK_CD;
					 EXCEPTION
				   		WHEN OTHERS THEN
						v_error_code := -7;
					  v_error_msg := SUBSTR('UPD T_STKHAND  '||rec.client_cd||' '||P_STK_CD||SQLERRM,1,200);
					  RAISE V_err;
				   END;
*/
	   END IF;


   END LOOP;
   CLOSE csr_stk;

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
END Sp_Gen_Stk_Expired_Jur_Ng;