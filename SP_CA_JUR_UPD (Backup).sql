create or replace 
PROCEDURE SP_CA_JUR_UPD(P_BGN_DT DATE,
                        P_CUM_DT T_CORP_ACT.CUM_DT%TYPE,
                        P_X_DT T_CORP_ACT.X_DT%TYPE,
                        P_CA_TYPE T_CORP_ACT.CA_TYPE%TYPE,
                        P_STK_CD T_STK_MOVEMENT.STK_CD%TYPE,
                        P_USER_ID			T_STK_MOVEMENT.USER_ID%TYPE,
                        p_ip_address T_MANY_HEADER.IP_ADDRESS%TYPE,
                        P_REMARKS T_STK_MOVEMENT.DOC_REM%TYPE,
						P_JOURNAL CHAR,
                        P_ERRCD	 		OUT NUMBER,
                        P_ERRMSG	 		OUT VARCHAR2
                        ) IS
  
  v_err			EXCEPTION;
  v_err_cd number;
  v_err_msg VARCHAR2(200);
  v_doc_num T_STK_MOVEMENT.DOC_NUM%TYPE;
  V_DOC_DATE T_STK_MOVEMENT.DOC_DT%TYPE;
  v_sd_type T_STK_MOVEMENT.S_D_TYPE%TYPE;
  V_LOT_SIZE T_STK_MOVEMENT.WITHDRAWN_SHARE_QTY%TYPE;
  v_total_lot T_STK_MOVEMENT.TOTAL_LOT%TYPE;
  v_qty T_STK_MOVEMENT.WITHDRAWN_SHARE_QTY%TYPE;
  V_REMARKS T_STK_MOVEMENT.DOC_REM%TYPE;
  V_WITHDRAWN_SHARE_QTY NUMBER(10);
  v_gl_acct_cd T_STK_MOVEMENT.GL_ACCT_CD%TYPE;
  V_PRICE T_STK_MOVEMENT.PRICE%TYPE :=0;
  V_UPDATE_DATE T_MANY_HEADER.UPDATE_DATE%TYPE;
  V_UPDATE_SEQ 	T_MANY_HEADER.UPDATE_SEQ%TYPE;
  V_DOC_TYPE varchar2(3);
  V_JUR_TYPE T_STK_MOVEMENT.JUR_TYPE%TYPE;
  V_ODD_LOT_DOC T_STK_MOVEMENT.ODD_LOT_DOC%TYPE;
  V_DB_CR_FLG T_STK_MOVEMENT.DB_CR_FLG%TYPE;
  V_TOTAL_SHARE_QTY T_STK_MOVEMENT.TOTAL_SHARE_QTY%TYPE;
  v_client_type MST_CLIENT.CLIENT_TYPE_1%TYPE;
  v_menu_name VARCHAR2(30):='CORPORATE ACTION JOURNAL';
  CURSOR csr_data is
  SELECT  a.client_cd,m.client_name, a.stk_cd, ca_type,a.bal_qty, on_custody,client_type, from_qty, to_qty,		
	ROUND(a.bal_qty * to_qty/from_qty,0) recv_qty,
	decode(c.ca_type,'SPLIT',0,'REVERSE',0,a.bal_qty) +ROUND(a.bal_qty * to_qty/from_qty,0) end_qty,	
	GREATEST(a.bal_qty  - ROUND(a.bal_qty * to_qty/from_qty,0),0) whdr_qty,	
	GREATEST(ROUND(a.bal_qty * to_qty/from_qty,0) - a.bal_Qty, 0) split_qty,
   M.BRANCH_CODE, C.RECORDING_DT,C.X_DT,C.DISTRIB_DT,C.CUM_DT
FROM( SELECT client_cd, stk_cd,		
	   SUM( NVL(theo_mvmt,0)) bal_qty, SUM(NVL(on_custody,0)) on_custody	
	   FROM(	  SELECT client_cd, stk_cd, 
		  DECODE(SUBSTR(doc_num,5,2),'BR',1,'JR',1,'BI',1,'JI',1,'BO',1,'JO',1,'RS',1,'WS',1,0) *
		  DECODE(db_cr_flg,'D',1,-1) *  (total_share_qty + withdrawn_share_qty) theo_mvmt,
		  DECODE(trim(gl_acct_Cd),'33',1,0) *
		  DECODE(db_cr_flg,'C',1,-1) *  (total_share_qty + withdrawn_share_qty) on_custody
	      FROM T_STK_MOVEMENT 	
		  WHERE doc_dt BETWEEN P_BGN_DT AND P_CUM_DT
		AND stk_cd = SUBSTR(P_STK_CD,1,4)
		AND trim(gl_acct_cd) IN ('10','12','13','14','51','33')
		AND doc_stat    = '2' 
 UNION ALL		
SELECT  client_cd, stk_cd, beg_bal_qty, on_custody		
	FROM T_STKBAL	
	WHERE bal_dt = P_BGN_DT	
	AND stk_cd = SUBSTR(P_STK_CD,1,4)) 	
		GROUP BY  client_cd, stk_cd
	HAVING  SUM(theo_mvmt) > 0) a,	
( SELECT client_Cd, client_type_3, DECODE(client_Cd, c.coy_client_cd,'H', DECODE(client_type_1,'H','H',margin_cd)) AS client_type,
  BRANCH_CODE,CLIENT_NAME
  FROM MST_CLIENT, LST_TYPE3, 		
  ( SELECT trim(other_1) coy_client_Cd FROM MST_COMPANY) c		
  WHERE client_type_1 <> 'B'		
  AND client_type_3 = cl_type3) m,		
  ( SELECT stk_cd, ca_type, from_qty, to_qty, RECORDING_DT, X_DT, DISTRIB_DT, CUM_DT		
     FROM t_corp_act		
	 WHERE stk_cd= SUBSTR(P_STK_CD,1,4)	
	 AND cum_dt = P_CUM_DT	
	 AND ca_type = P_CA_TYPE	
	and approved_stat = 'A') c	
WHERE a.client_cd = m.client_cd		
AND a.stk_Cd = c.stk_cd ORDER BY M.CLIENT_CD;		

  
BEGIN
 
      
    
  FOR rec in csr_data loop
  
 	--JURNAL PADA CUM DATE UNTUK CA TYPE RIGHT, WARRANT, BONUS, STKDIV 
	IF P_JOURNAL = 'C' AND (P_CA_TYPE = 'RIGHT' OR P_CA_TYPE = 'WARRANT' OR P_CA_TYPE = 'BONUS' OR P_CA_TYPE = 'STKDIV') then

	FOR I IN 1..2 LOOP
		
	IF I=1 THEN
	--GET DOC NUM
		V_DOC_TYPE :='RSN';
		v_doc_num := Get_Stk_Jurnum(  P_CUM_DT,V_DOC_TYPE );
		V_DOC_DATE :=P_CUM_DT;
		V_JUR_TYPE :='CORPACTC';
	  --execute sp header
         begin
        SP_T_MANY_HEADER_INSERT(V_MENU_NAME,
								 'I',
								 p_user_id,
								 p_ip_address,
								 null,
								 V_UPDATE_DATE,
								 V_UPDATE_seq,
								 v_err_cd,
								 v_err_msg);
        EXCEPTION
              WHEN OTHERS THEN
                 v_err_cd := -2;
                 v_err_msg := substr('SP_T_MANY_HEADER_INSERT '|| SQLERRM(SQLCODE),1,200);
                RAISE V_err;
            END;
	
	END IF;  
	
		IF P_CA_TYPE = 'RIGHT' OR P_CA_TYPE='WARRANT' THEN 
		v_sd_type := 'H';
		END IF;
		IF P_CA_TYPE = 'BONUS' OR P_CA_TYPE='STKDIV' THEN 
		v_sd_type := 'B';
		END IF;

		
		BEGIN
		SELECT lot_size INTO V_LOT_SIZE FROM MST_COUNTER WHERE stk_cd = P_STK_CD;
		EXCEPTION
				WHEN OTHERS THEN
					 v_err_cd := -3;
					 v_err_msg := substr('MST_COUNTER  '||SQLERRM(SQLCODE),1,200);
					RAISE V_err;
			END;
	if p_ca_type ='RIGHT' or p_ca_type ='WARRANT' or p_ca_type= 'BONUS' OR P_CA_TYPE='STKDIV' then
		v_qty :=rec.recv_qty;
	end if;
	
		IF MOD(v_qty,V_LOT_SIZE) = 0 THEN
			V_ODD_LOT_DOC :='N';
		ELSE
			V_ODD_LOT_DOC :='Y';
		END IF;
		
		
		v_total_lot := trunc(v_qty/v_lot_size);
		V_TOTAL_SHARE_QTY :=V_QTY;
		V_WITHDRAWN_SHARE_QTY :=0;
		
		IF P_CA_TYPE ='RIGHT' THEN
		V_REMARKS := P_REMARKS;--'HMETD ' ||REC.FROM_QTY ||' : '||REC.TO_QTY;
		END IF;
		IF P_CA_TYPE ='WARRANT' THEN
		V_REMARKS := P_REMARKS;--'HMETD ' ||REC.FROM_QTY ||' : '||REC.TO_QTY;
		END IF;
		IF P_CA_TYPE='BONUS' THEN
		V_REMARKS := P_REMARKS;--'BONUS '||REC.FROM_QTY ||' : '||REC.TO_QTY;
		END IF;
		IF P_CA_TYPE ='STKDIV' THEN
		V_REMARKS := P_REMARKS;--'DIVIDEN '||REC.FROM_QTY ||' : '||REC.TO_QTY;
		END IF;
		

		IF I=1 THEN
		V_DB_CR_FLG := 'D';
		ELSE
		V_DB_CR_FLG := 'C';
		END IF;
		
		IF V_DB_CR_FLG ='D' or I=1 THEN
				BEGIN
				SELECT deb_acct INTO v_gl_acct_cd FROM mst_secu_acct WHERE V_DOC_DATE between eff_dt_from and eff_dt_to and  mvmt_type  = V_JUR_TYPE and client_type LIKE '%'||rec.client_type;
				EXCEPTION
						WHEN OTHERS THEN
							v_err_cd := -4;
							v_err_msg :='MST_SECU_ACCT '||SUBSTR(SQLERRM(SQLCODE),1,200);
							RAISE V_err;
				END;
		ELSE
				BEGIN
				SELECT cre_acct INTO v_gl_acct_cd FROM mst_secu_acct WHERE V_DOC_DATE between eff_dt_from and eff_dt_to and  mvmt_type  = V_JUR_TYPE and CLIENT_TYPE LIKE '%'|| rec.client_type;
				EXCEPTION
						WHEN OTHERS THEN
							v_err_cd := -5;
							 v_err_msg :=SUBSTR('MST_SECU_ACCT '||SQLERRM(SQLCODE),1,200);
							RAISE V_err;
				END;
		END IF;

		BEGIN
    
				Sp_T_STK_MOVEMENT_Upd(	v_doc_num,--search doc_num
										V_DB_CR_FLG,--db_cr_flg
										I,--seqno
										v_doc_num,--doc_num
										NULL,--ref doc num
										V_DOC_DATE,--doc_dt
										rec.client_cd,--client_cd
										P_STK_CD,--stk_cd
										v_sd_type,--s_d_type
										v_odd_lot_doc,--odd lot doc
										v_total_lot,--total lot
										V_TOTAL_SHARE_QTY,--total share qty
										V_REMARKS,--doc rem
										'2',--doc_stat
										V_WITHDRAWN_SHARE_QTY,--WITHDRAWN_SHARE_QTY	
										NULL,--REGD_HLDR
										NULL,--WITHDRAW_REASON_CD	
										v_gl_acct_cd,--GL_ACCT_CD
										null,--ACCT_TYPE	
										V_DB_CR_FLG,--DB_CR_FLG		
										'L',--STATUS
										V_DOC_DATE,--DUE_DT_FOR_CERT
										null,--STK_STAT
										null,--DUE_DT_ONHAND	
										I,--SEQNO	
										V_PRICE,--PRICE
										NULL,--PREV_DOC_NUM
										'Y',--MANUAL
										V_JUR_TYPE,--JUR_TYPE	
										NULL,--BROKER	
										NULL,--P_REPO_REF,
										P_USER_ID,--user id
										SYSDATE,--CRE_DT
										NULL,--P_UPD_BY,
										NULL,--P_UPD_DT,
										'I',--P_UPD_STATUS,
										p_ip_address,
										NULL,--p_cancel_reason,
										v_update_date,--update date
										v_update_seq,--update_seq
										I,--record seq
										v_err_cd,
										v_err_msg);
		 
			EXCEPTION
				WHEN OTHERS THEN
					 v_err_cd := -6;
					 v_err_msg :=SUBSTR('Sp_T_STK_MOVEMENT_Upd '||SQLERRM(SQLCODE),1,200);
					RAISE V_err;
			END;
		
	IF v_err_cd < 0 THEN
	    v_err_cd := -7;
		v_err_msg := SUBSTR('Sp_T_STK_MOVEMENT_Upd '||v_err_msg,1,200);
		RAISE v_err;
	END IF;
  
	END LOOP; --end loop jurnal
	END IF; --END JURNAL PADA CUM DATE UNTUK RIGHT, WARRANT, BONUS, STKDIV
	
	
	--JURNAL PADA X DATE UNTUK SPLIT DAN REVERSE (WHDR)
	IF P_JOURNAL = 'X' AND (P_CA_TYPE ='SPLIT' OR P_CA_TYPE='REVERSE') THEN
	--JURNAL X DATE UNTUK TYPE WHDR
	FOR I IN 1..2 LOOP
	IF I=1 THEN
		--GET DOC NUM
			V_DOC_TYPE :='WSN';
			v_doc_num := Get_Stk_Jurnum(  P_X_DT ,V_DOC_TYPE );
		--DOC DATE
		V_DOC_DATE :=P_X_DT;
		V_JUR_TYPE :='WHDR';
	  --execute sp header
         begin
        SP_T_MANY_HEADER_INSERT(V_MENU_NAME,
								 'I',
								 p_user_id,
								 p_ip_address,
								 null,
								 V_UPDATE_DATE,
								 V_UPDATE_seq,
								 v_err_cd,
								 v_err_msg);
            EXCEPTION
              WHEN OTHERS THEN
                 v_err_cd := -8;
                 v_err_msg := substr('SP_T_MANY_HEADER_INSERT '|| SQLERRM(SQLCODE),1,200);
                RAISE V_err;
            END;
	END IF;  
	--S_D_TYPE
	v_sd_type := 'W';

		BEGIN
		SELECT lot_size INTO V_LOT_SIZE FROM MST_COUNTER WHERE stk_cd = P_STK_CD;
		EXCEPTION
				WHEN OTHERS THEN
					 v_err_cd := -9;
					 v_err_msg := substr('MST_COUNTER  '||SQLERRM(SQLCODE),1,200);
					RAISE V_err;
			END;
	if p_ca_type ='SPLIT' or  p_ca_type ='REVERSE' then
		v_qty :=rec.bal_Qty;--JURNAL PERTAMA UNTUK SPLIT ATAU REVERSE(WHDR)
	end if;
	
	
		IF MOD(v_qty,V_LOT_SIZE) = 0 THEN
			V_ODD_LOT_DOC :='N';
		ELSE
			V_ODD_LOT_DOC :='Y';
		END IF;
		
		
		v_total_lot := trunc(v_qty/v_lot_size);
		V_TOTAL_SHARE_QTY :=0;
		V_WITHDRAWN_SHARE_QTY :=V_QTY;
		
		IF P_CA_TYPE ='SPLIT' THEN
		V_REMARKS := P_REMARKS;--'SPLIT '||REC.FROM_QTY ||' : '||REC.TO_QTY;
		END IF;
		IF P_CA_TYPE ='REVERSE' THEN
		V_REMARKS := P_REMARKS;--'REVERSE '||REC.FROM_QTY ||' : '||REC.TO_QTY;
		END IF;
	
	
		IF I=1 THEN
		V_DB_CR_FLG := 'D';
		ELSE
		V_DB_CR_FLG := 'C';
		END IF;
		
		IF V_DB_CR_FLG ='D' or I=1 THEN
				BEGIN
				SELECT deb_acct INTO v_gl_acct_cd FROM mst_secu_acct WHERE V_DOC_DATE between eff_dt_from and eff_dt_to and  mvmt_type  = V_JUR_TYPE and CLIENT_TYPE LIKE '%'|| rec.client_type;
				EXCEPTION
						WHEN OTHERS THEN
							v_err_cd := -10;
							v_err_msg :='MST_SECU_ACCT '||SUBSTR(SQLERRM(SQLCODE),1,200);
							RAISE V_err;
				END;
		ELSE
				BEGIN
				SELECT cre_acct INTO v_gl_acct_cd FROM mst_secu_acct WHERE V_DOC_DATE between eff_dt_from and eff_dt_to and  mvmt_type  = V_JUR_TYPE and CLIENT_TYPE LIKE '%'|| rec.client_type;
				EXCEPTION
						WHEN OTHERS THEN
							v_err_cd := -11;
							 v_err_msg :=SUBSTR('MST_SECU_ACCT '||SQLERRM(SQLCODE),1,200);
							RAISE V_err;
				END;
		END IF;

		BEGIN
				Sp_T_STK_MOVEMENT_Upd(	v_doc_num,--search doc_num
										V_DB_CR_FLG,--db_cr_flg
										I,--seqno
										v_doc_num,--doc_num
										NULL,--ref doc num
										V_DOC_DATE,--doc_dt
										rec.client_cd,--client_cd
										P_STK_CD,--stk_cd
										v_sd_type,--s_d_type
										v_odd_lot_doc,--odd lot doc
										v_total_lot,--total lot
										V_TOTAL_SHARE_QTY,--total share qty
										V_REMARKS,--doc rem
										'2',--doc_stat
										V_WITHDRAWN_SHARE_QTY,--WITHDRAWN_SHARE_QTY	
										NULL,--REGD_HLDR
										NULL,--WITHDRAW_REASON_CD	
										v_gl_acct_cd,--GL_ACCT_CD
										null,--ACCT_TYPE	
										V_DB_CR_FLG,--DB_CR_FLG		
										'L',--STATUS
										V_DOC_DATE,--DUE_DT_FOR_CERT
										null,--STK_STAT
										null,--DUE_DT_ONHAND	
										I,--SEQNO	
										V_PRICE,--PRICE
										NULL,--PREV_DOC_NUM
										'Y',--MANUAL
										V_JUR_TYPE,--JUR_TYPE	
										NULL,--BROKER	
										NULL,--P_REPO_REF,
										P_USER_ID,--user id
										SYSDATE,--CRE_DT
										NULL,--P_UPD_BY,
										NULL,--P_UPD_DT,
										'I',--P_UPD_STATUS,
										p_ip_address,
										NULL,--p_cancel_reason,
										v_update_date,--update date
										v_update_seq,--update_seq
										I,--record seq
										v_err_cd,
										v_err_msg);
		 
			EXCEPTION
				WHEN OTHERS THEN
					 v_err_cd := -12;
					 v_err_msg :=SUBSTR('Sp_T_STK_MOVEMENT_Upd '||SQLERRM(SQLCODE),1,200);
					RAISE V_err;
			END;
		
	IF v_err_cd < 0 THEN
	    v_err_cd := -13;
		v_err_msg := SUBSTR('Sp_T_STK_MOVEMENT_Upd '||v_err_msg,1,200);
		RAISE v_err;
	END IF;
  
	END LOOP; ----JURNAL X DATE UNTUK TYPE WHDR
		
		
	--JURNAL X DATE UNTUK TYPE SPLITX ATAU REVERSEX
	FOR I IN 1..2 LOOP
	IF I=1 THEN
		--GET DOC NUM
			V_DOC_TYPE :='RSN';
			v_doc_num := Get_Stk_Jurnum(  P_X_DT ,V_DOC_TYPE );
		--DOC DATE
		V_DOC_DATE :=P_X_DT;
		
		IF P_CA_TYPE = 'SPLIT' THEN
		V_JUR_TYPE :='SPLITX';
		ELSE
		V_JUR_TYPE :='REVERSEX';
		END IF;
		
	  --execute sp header
         begin
        SP_T_MANY_HEADER_INSERT(V_MENU_NAME,
								 'I',
								 p_user_id,
								 p_ip_address,
								 null,
								 V_UPDATE_DATE,
								 V_UPDATE_seq,
								 v_err_cd,
								 v_err_msg);
            EXCEPTION
              WHEN OTHERS THEN
                 v_err_cd := -14;
                 v_err_msg := substr('SP_T_MANY_HEADER_INSERT '|| SQLERRM(SQLCODE),1,200);
                RAISE V_err;
            END;
	END IF;  
	--S_D_TYPE
	IF P_CA_TYPE = 'SPLIT' THEN
		v_sd_type := 'S';
	ELSE
		v_sd_type := 'R';
	END IF;

		BEGIN
		SELECT lot_size INTO V_LOT_SIZE FROM MST_COUNTER WHERE stk_cd = P_STK_CD;
		EXCEPTION
				WHEN OTHERS THEN
					 v_err_cd := -15;
					 v_err_msg := substr('MST_COUNTER  '||SQLERRM(SQLCODE),1,200);
					RAISE V_err;
			END;
	if p_ca_type ='SPLIT' or  p_ca_type ='REVERSE' then
		v_qty :=rec.end_Qty;--JURNAL kedua UNTUK SPLIT ATAU REVERSE
	end if;
	
	
		IF MOD(v_qty,V_LOT_SIZE) = 0 THEN
			V_ODD_LOT_DOC :='N';
		ELSE
			V_ODD_LOT_DOC :='Y';
		END IF;
		
		
		v_total_lot := trunc(v_qty/v_lot_size);
		V_TOTAL_SHARE_QTY :=V_QTY;
		V_WITHDRAWN_SHARE_QTY :=0;
		
		
		IF P_CA_TYPE ='SPLIT' THEN
		V_REMARKS := P_REMARKS;--'SPLIT '||REC.FROM_QTY ||' : '||REC.TO_QTY;
		END IF;
		IF P_CA_TYPE ='REVERSE' THEN
		V_REMARKS := P_REMARKS;--'REVERSE '||REC.FROM_QTY ||' : '||REC.TO_QTY;
		END IF;
	
		IF I=1 THEN
		V_DB_CR_FLG := 'D';
		ELSE
		V_DB_CR_FLG := 'C';
		END IF;
		
		IF V_DB_CR_FLG ='D' or I=1 THEN
				BEGIN
				SELECT deb_acct INTO v_gl_acct_cd FROM mst_secu_acct WHERE V_DOC_DATE between eff_dt_from and eff_dt_to and  mvmt_type  = V_JUR_TYPE and CLIENT_TYPE LIKE '%'|| rec.client_type;
				EXCEPTION
						WHEN OTHERS THEN
							v_err_cd := -16;
							v_err_msg :='MST_SECU_ACCT '||SUBSTR(SQLERRM(SQLCODE),1,200);
							RAISE V_err;
				END;
		ELSE
				BEGIN
				SELECT cre_acct INTO v_gl_acct_cd FROM mst_secu_acct WHERE V_DOC_DATE between eff_dt_from and eff_dt_to and  mvmt_type  = V_JUR_TYPE and CLIENT_TYPE LIKE '%'|| rec.client_type;
				EXCEPTION
						WHEN OTHERS THEN
							v_err_cd := -17;
							 v_err_msg :=SUBSTR('MST_SECU_ACCT '||SQLERRM(SQLCODE),1,200);
							RAISE V_err;
				END;
		END IF;

		BEGIN
				Sp_T_STK_MOVEMENT_Upd(	v_doc_num,--search doc_num
										V_DB_CR_FLG,--db_cr_flg
										I,--seqno
										v_doc_num,--doc_num
										NULL,--ref doc num
										V_DOC_DATE,--doc_dt
										rec.client_cd,--client_cd
										P_STK_CD,--stk_cd
										v_sd_type,--s_d_type
										v_odd_lot_doc,--odd lot doc
										v_total_lot,--total lot
										V_TOTAL_SHARE_QTY,--total share qty
										V_REMARKS,--doc rem
										'2',--doc_stat
										V_WITHDRAWN_SHARE_QTY,--WITHDRAWN_SHARE_QTY	
										NULL,--REGD_HLDR
										NULL,--WITHDRAW_REASON_CD	
										v_gl_acct_cd,--GL_ACCT_CD
										null,--ACCT_TYPE	
										V_DB_CR_FLG,--DB_CR_FLG		
										'L',--STATUS
										V_DOC_DATE,--DUE_DT_FOR_CERT
										null,--STK_STAT
										null,--DUE_DT_ONHAND	
										I,--SEQNO	
										V_PRICE,--PRICE
										NULL,--PREV_DOC_NUM
										'Y',--MANUAL
										V_JUR_TYPE,--JUR_TYPE	
										NULL,--BROKER	
										NULL,--P_REPO_REF,
										P_USER_ID,--user id
										SYSDATE,--CRE_DT
										NULL,--P_UPD_BY,
										NULL,--P_UPD_DT,
										'I',--P_UPD_STATUS,
										p_ip_address,
										NULL,--p_cancel_reason,
										v_update_date,--update date
										v_update_seq,--update_seq
										I,--record seq
										v_err_cd,
										v_err_msg);
		 
			EXCEPTION
				WHEN OTHERS THEN
					 v_err_cd := -18;
					 v_err_msg :=SUBSTR('Sp_T_STK_MOVEMENT_Upd '||SQLERRM(SQLCODE),1,200);
					RAISE V_err;
			END;
		
	IF v_err_cd < 0 THEN
	    v_err_cd := -19;
		v_err_msg := SUBSTR('Sp_T_STK_MOVEMENT_Upd '||v_err_msg,1,200);
		RAISE v_err;
	END IF;
  
	END LOOP; ----JURNAL X DATE UNTUK TYPE SPLITX ATAU REVERSEX
	
	
	
	END IF;
	
	--JURNAL UNTUK SPLIT ATAU REVERSE PADA DISTRIB DATE
	IF P_JOURNAL = 'D' AND (P_CA_TYPE = 'SPLIT' OR P_CA_TYPE='REVERSE') THEN
	
	FOR I IN 1..2 LOOP
	IF I=1 THEN
		--GET DOC NUM
			V_DOC_TYPE :='RSN';
			v_doc_num := Get_Stk_Jurnum(  REC.DISTRIB_DT,V_DOC_TYPE );
		--DOC DATE
		V_DOC_DATE :=REC.DISTRIB_DT;
		
		IF P_CA_TYPE = 'SPLIT' THEN
		V_JUR_TYPE :='SPLITD';
		ELSE
		V_JUR_TYPE :='REVERSED';
		END IF;
		
	  --execute sp header
         begin
        SP_T_MANY_HEADER_INSERT(V_MENU_NAME,
								 'I',
								 p_user_id,
								 p_ip_address,
								 null,
								 V_UPDATE_DATE,
								 V_UPDATE_seq,
								 v_err_cd,
								 v_err_msg);
            EXCEPTION
              WHEN OTHERS THEN
                 v_err_cd := -20;
                 v_err_msg := substr('SP_T_MANY_HEADER_INSERT '|| SQLERRM(SQLCODE),1,200);
                RAISE V_err;
            END;
	END IF;  
	--S_D_TYPE
	IF P_CA_TYPE = 'SPLIT' THEN
		v_sd_type := 'S';
	ELSE
		v_sd_type := 'R';
	END IF;

		BEGIN
		SELECT lot_size INTO V_LOT_SIZE FROM MST_COUNTER WHERE stk_cd = P_STK_CD;
		EXCEPTION
				WHEN OTHERS THEN
					 v_err_cd := -21;
					 v_err_msg := substr('MST_COUNTER  '||SQLERRM(SQLCODE),1,200);
					RAISE V_err;
			END;
	if p_ca_type ='SPLIT' or  p_ca_type ='REVERSE' then
		v_qty :=rec.end_Qty;--JURNAL UNTUK SPLIT ATAU REVERSE PADA DISTRIB DATE
	end if;
	
	
		IF MOD(v_qty,V_LOT_SIZE) = 0 THEN
			V_ODD_LOT_DOC :='N';
		ELSE
			V_ODD_LOT_DOC :='Y';
		END IF;
		
		
		v_total_lot := trunc(v_qty/v_lot_size);
		V_TOTAL_SHARE_QTY :=V_QTY;
		V_WITHDRAWN_SHARE_QTY :=0;
		
		
		IF P_CA_TYPE ='SPLIT' THEN
		V_REMARKS := 'SPLIT '||REC.FROM_QTY ||' : '||REC.TO_QTY;
		END IF;
		IF P_CA_TYPE ='REVERSE' THEN
		V_REMARKS := 'REVERSE '||REC.FROM_QTY ||' : '||REC.TO_QTY;
		END IF;
	
	
		IF I=1 THEN
		V_DB_CR_FLG := 'D';
		ELSE
		V_DB_CR_FLG := 'C';
		END IF;
		
		IF V_DB_CR_FLG ='D' or I=1 THEN
				IF P_CA_TYPE ='REVERSE' THEN
					BEGIN
					SELECT deb_acct INTO v_gl_acct_cd FROM mst_secu_acct WHERE V_DOC_DATE between eff_dt_from and eff_dt_to and  mvmt_type  = V_JUR_TYPE ;--and CLIENT_TYPE LIKE '%'|| rec.client_type;
					EXCEPTION
							WHEN OTHERS THEN
								v_err_cd := -22;
								v_err_msg :='MST_SECU_ACCT '||SUBSTR(SQLERRM(SQLCODE),1,200);
								RAISE V_err;
					END;
				ELSE
					BEGIN
					SELECT deb_acct INTO v_gl_acct_cd FROM mst_secu_acct WHERE V_DOC_DATE between eff_dt_from and eff_dt_to and  mvmt_type  = V_JUR_TYPE and CLIENT_TYPE LIKE '%'|| rec.client_type;
					EXCEPTION
							WHEN OTHERS THEN
								v_err_cd := -22;
								v_err_msg :='MST_SECU_ACCT '||SUBSTR(SQLERRM(SQLCODE),1,200);
								RAISE V_err;
					END;
					
				END IF;
		ELSE
			
			IF P_CA_TYPE='REVERSE' THEN
				BEGIN
				SELECT cre_acct INTO v_gl_acct_cd FROM mst_secu_acct WHERE V_DOC_DATE between eff_dt_from and eff_dt_to and  mvmt_type  = V_JUR_TYPE ;-- and CLIENT_TYPE LIKE '%'|| rec.client_type;
				EXCEPTION
						WHEN OTHERS THEN
							v_err_cd := -23;
							 v_err_msg :=SUBSTR('MST_SECU_ACCT '||SQLERRM(SQLCODE),1,200);
							RAISE V_err;
				END;
			
			ELSE
		
				BEGIN
				SELECT cre_acct INTO v_gl_acct_cd FROM mst_secu_acct WHERE V_DOC_DATE between eff_dt_from and eff_dt_to and  mvmt_type  = V_JUR_TYPE and CLIENT_TYPE LIKE '%'|| rec.client_type;
				EXCEPTION
						WHEN OTHERS THEN
							v_err_cd := -23;
							 v_err_msg :=SUBSTR('MST_SECU_ACCT '||SQLERRM(SQLCODE),1,200);
							RAISE V_err;
				END;
				
				END IF;
		END IF;

		BEGIN
				Sp_T_STK_MOVEMENT_Upd(	v_doc_num,--search doc_num
										V_DB_CR_FLG,--db_cr_flg
										I,--seqno
										v_doc_num,--doc_num
										NULL,--ref doc num
										V_DOC_DATE,--doc_dt
										rec.client_cd,--client_cd
										P_STK_CD,--stk_cd
										v_sd_type,--s_d_type
										v_odd_lot_doc,--odd lot doc
										v_total_lot,--total lot
										V_TOTAL_SHARE_QTY,--total share qty
										V_REMARKS,--doc rem
										'2',--doc_stat
										V_WITHDRAWN_SHARE_QTY,--WITHDRAWN_SHARE_QTY	
										NULL,--REGD_HLDR
										NULL,--WITHDRAW_REASON_CD	
										v_gl_acct_cd,--GL_ACCT_CD
										null,--ACCT_TYPE	
										V_DB_CR_FLG,--DB_CR_FLG		
										'L',--STATUS
										V_DOC_DATE,--DUE_DT_FOR_CERT
										null,--STK_STAT
										null,--DUE_DT_ONHAND	
										I,--SEQNO	
										V_PRICE,--PRICE
										NULL,--PREV_DOC_NUM
										'Y',--MANUAL
										V_JUR_TYPE,--JUR_TYPE	
										NULL,--BROKER	
										NULL,--P_REPO_REF,
										P_USER_ID,--user id
										SYSDATE,--CRE_DT
										NULL,--P_UPD_BY,
										NULL,--P_UPD_DT,
										'I',--P_UPD_STATUS,
										p_ip_address,
										NULL,--p_cancel_reason,
										v_update_date,--update date
										v_update_seq,--update_seq
										I,--record seq
										v_err_cd,
										v_err_msg);
		 
			EXCEPTION
				WHEN OTHERS THEN
					 v_err_cd := -24;
					 v_err_msg :=SUBSTR('Sp_T_STK_MOVEMENT_Upd '||SQLERRM(SQLCODE),1,200);
					RAISE V_err;
			END;
		
	IF v_err_cd < 0 THEN
	    v_err_cd := -25;
		v_err_msg := SUBSTR('Sp_T_STK_MOVEMENT_Upd '||v_err_msg,1,200);
		RAISE v_err;
	END IF;
  
	END LOOP; ----JURNAL DISTRIB DATE UNTUK TYPE SPLITD OR REPVERSED
	
	END IF;
	
	
		--JURNAL PADA DISTRIB UNTUK CA TYPE RIGHT, WARRANT, BONUS, STKDIV 
	IF P_JOURNAL = 'D' AND (P_CA_TYPE = 'RIGHT' OR P_CA_TYPE = 'WARRANT' OR P_CA_TYPE = 'BONUS' OR P_CA_TYPE = 'STKDIV') then

	FOR I IN 1..2 LOOP
		
	IF I=1 THEN
	--GET DOC NUM
		V_DOC_TYPE :='RSN';
		v_doc_num := Get_Stk_Jurnum(  REC.DISTRIB_DT ,V_DOC_TYPE );
		V_DOC_DATE := REC.DISTRIB_DT;
		V_JUR_TYPE :='CORPACTD';
	  --execute sp header
         begin
        SP_T_MANY_HEADER_INSERT(V_MENU_NAME,
								 'I',
								 p_user_id,
								 p_ip_address,
								 null,
								 V_UPDATE_DATE,
								 V_UPDATE_seq,
								 v_err_cd,
								 v_err_msg);
            EXCEPTION
              WHEN OTHERS THEN
                 v_err_cd := -26;
                 v_err_msg := substr('SP_T_MANY_HEADER_INSERT '|| SQLERRM(SQLCODE),1,200);
                RAISE V_err;
            END;
	
	END IF;  
	
		IF P_CA_TYPE = 'RIGHT' OR P_CA_TYPE='WARRANT' THEN 
		v_sd_type := 'H';
		END IF;
		IF P_CA_TYPE = 'BONUS' OR P_CA_TYPE='STKDIV' THEN 
		v_sd_type := 'B';
		END IF;

		
		BEGIN
		SELECT lot_size INTO V_LOT_SIZE FROM MST_COUNTER WHERE stk_cd = P_STK_CD;
		EXCEPTION
				WHEN OTHERS THEN
					 v_err_cd := -27;
					 v_err_msg := substr('MST_COUNTER  '||SQLERRM(SQLCODE),1,200);
					RAISE V_err;
			END;
	if p_ca_type ='RIGHT' or p_ca_type ='WARRANT' or p_ca_type= 'BONUS' OR P_CA_TYPE='STKDIV' then
		v_qty :=rec.recv_qty;
	end if;
	
		IF MOD(v_qty,V_LOT_SIZE) = 0 THEN
			V_ODD_LOT_DOC :='N';
		ELSE
			V_ODD_LOT_DOC :='Y';
		END IF;
		
		
		v_total_lot := trunc(v_qty/v_lot_size);
		V_TOTAL_SHARE_QTY :=V_QTY;
		V_WITHDRAWN_SHARE_QTY :=0;
		
		IF P_CA_TYPE ='RIGHT' THEN
		V_REMARKS := P_REMARKS;--'HMETD ' ||REC.FROM_QTY ||' : '||REC.TO_QTY;
		END IF;
		IF P_CA_TYPE ='WARRANT' THEN
		V_REMARKS := P_REMARKS;--'HMETD ' ||REC.FROM_QTY ||' : '||REC.TO_QTY;
		END IF;
		IF P_CA_TYPE='BONUS' THEN
		V_REMARKS :='BONUS '||REC.FROM_QTY ||' : '||REC.TO_QTY;
		END IF;
		IF P_CA_TYPE ='STKDIV' THEN
		V_REMARKS := 'DIVIDEN '||REC.FROM_QTY ||' : '||REC.TO_QTY;
		END IF;
		
	
	
		IF I=1 THEN
		V_DB_CR_FLG := 'D';
		ELSE
		V_DB_CR_FLG := 'C';
		END IF;
		
		IF V_DB_CR_FLG ='D' or I=1 THEN
				BEGIN
				SELECT deb_acct INTO v_gl_acct_cd FROM mst_secu_acct WHERE V_DOC_DATE between eff_dt_from and eff_dt_to and  mvmt_type  = V_JUR_TYPE and CLIENT_TYPE LIKE '%'|| rec.client_type;
				EXCEPTION
						WHEN OTHERS THEN
							v_err_cd := -28;
							v_err_msg :='MST_SECU_ACCT '||SUBSTR(SQLERRM(SQLCODE),1,200);
							RAISE V_err;
				END;
		ELSE
				BEGIN
				SELECT cre_acct INTO v_gl_acct_cd FROM mst_secu_acct WHERE V_DOC_DATE between eff_dt_from and eff_dt_to and  mvmt_type  = V_JUR_TYPE and CLIENT_TYPE LIKE '%'|| rec.client_type;
				EXCEPTION
						WHEN OTHERS THEN
							v_err_cd := -29;
							 v_err_msg :=SUBSTR('MST_SECU_ACCT '||SQLERRM(SQLCODE),1,200);
							RAISE V_err;
				END;
		END IF;

		BEGIN
    
				Sp_T_STK_MOVEMENT_Upd(	v_doc_num,--search doc_num
										V_DB_CR_FLG,--db_cr_flg
										I,--seqno
										v_doc_num,--doc_num
										NULL,--ref doc num
										V_DOC_DATE,--doc_dt
										rec.client_cd,--client_cd
										P_STK_CD,--stk_cd
										v_sd_type,--s_d_type
										v_odd_lot_doc,--odd lot doc
										v_total_lot,--total lot
										V_TOTAL_SHARE_QTY,--total share qty
										V_REMARKS,--doc rem
										'2',--doc_stat
										V_WITHDRAWN_SHARE_QTY,--WITHDRAWN_SHARE_QTY	
										NULL,--REGD_HLDR
										NULL,--WITHDRAW_REASON_CD	
										v_gl_acct_cd,--GL_ACCT_CD
										null,--ACCT_TYPE	
										V_DB_CR_FLG,--DB_CR_FLG		
										'L',--STATUS
										V_DOC_DATE,--DUE_DT_FOR_CERT
										null,--STK_STAT
										null,--DUE_DT_ONHAND	
										I,--SEQNO	
										V_PRICE,--PRICE
										NULL,--PREV_DOC_NUM
										'Y',--MANUAL
										V_JUR_TYPE,--JUR_TYPE	
										NULL,--BROKER	
										NULL,--P_REPO_REF,
										P_USER_ID,--user id
										SYSDATE,--CRE_DT
										NULL,--P_UPD_BY,
										NULL,--P_UPD_DT,
										'I',--P_UPD_STATUS,
										p_ip_address,
										NULL,--p_cancel_reason,
										v_update_date,--update date
										v_update_seq,--update_seq
										I,--record seq
										v_err_cd,
										v_err_msg);
		 
			EXCEPTION
				WHEN OTHERS THEN
					 v_err_cd := -30;
					 v_err_msg :=SUBSTR('Sp_T_STK_MOVEMENT_Upd '||SQLERRM(SQLCODE),1,200);
					RAISE V_err;
			END;
		
	IF v_err_cd < 0 THEN
	    v_err_cd := -31;
		v_err_msg := SUBSTR('Sp_T_STK_MOVEMENT_Upd '||v_err_msg,1,200);
		RAISE v_err;
	END IF;
  
	END LOOP; --end loop jurnal
	END IF; --END JURNAL PADA DISTRIB DATE UNTUK RIGHT, WARRANT, BONUS, STKDIV
	
	
end loop;--end loop cursor
    p_errcd := 1;
    p_errmsg := '';
  
EXCEPTION
    WHEN v_err THEN
        ROLLBACK;
         p_errcd := v_err_cd;
        p_errmsg := v_err_msg;
    WHEN OTHERS THEN
       ROLLBACK;
        p_errcd := -1;
        p_errmsg := SUBSTR(SQLERRM(SQLCODE),1,200);
END SP_CA_JUR_UPD;