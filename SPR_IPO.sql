create or replace PROCEDURE SPR_IPO(
	vp_stk_cd			MST_COUNTER.STK_CD%TYPE,
	vp_brch_cd			R_IPO_LIST.BRCH_CD%TYPE,
	vp_client_from		R_IPO_LIST.CLIENT_CD%TYPE,
	vp_client_to		R_IPO_LIST.CLIENT_CD%TYPE,
	vp_paym_dt			R_IPO_LIST.PAYM_DT%TYPE,
	vp_report_type		NUMBER, -- 1 = Invoice, 2 = IPO List, 3 = Refund
  P_QTY_FLG NUMBER,--0 = All pooling dan fixed, 1 = Fixed , 2 = Pooling
	vp_userid			VARCHAR2,
	vp_generate_date	DATE,
	vo_random_value		OUT NUMBER,
	vo_errcd	 		OUT NUMBER,
	vo_errmsg			OUT VARCHAR2
) IS

	vl_random_value		NUMBER(10);
	vl_err				EXCEPTION;

BEGIN
    vl_random_value := ABS(dbms_random.random);

    BEGIN
        SP_RPT_REMOVE_RAND('R_IPO_LIST',vl_random_value,vo_errcd,vo_errmsg);
    EXCEPTION
        WHEN OTHERS THEN
            vo_errcd := -2;
            vo_errmsg := SQLERRM(SQLCODE);
            RAISE vl_err;
    END;  

	IF vp_report_type = 1 THEN
		INSERT INTO R_IPO_LIST
		(
			client_cd,  
			price,							
			stk_name,							
			paym_dt,							
			f_qty,							
			p_qty,							
			f_stk_value, 							
			p_stk_value, 							
			f_fee,							
			p_fee,							
			f_inv_amt,							
			p_inv_amt,							
			inv_amt,
			client_name,	
			brch_cd,	
			def_addr_1,
			def_addr_2,
			def_addr_3,
			post_cd,
			phone_num,
			fax_num,
			acct_num,
			bank_name,
			acct_name,
			nama_prsh,
			broker_addr1,
			broker_addr2,
			broker_addr3,
			broker_post_cd,
			broker_phone,
			broker_fax,
			rand_value,
			user_id,
			generate_date
		)
		SELECT t.client_cd,  
			t.price,							
			t.stk_name,							
			NVL(vp_paym_dt,t.paym_dt),							
			t.f_qty,							
			t.p_qty,							
			t.f_stk_value, 							
			t.p_stk_value, 							
			t.f_fee,							
			t.p_fee,							
			t.f_stk_value + t.f_fee AS f_inv_amt,							
			t.p_stk_value + t.p_fee AS p_inv_amt,							
			t.f_stk_value + t.f_fee + t.p_stk_value + t.p_fee AS inv_amt,
			m.client_name,	
			m.brch_cd,	
			m.def_addr_1,
			m.def_addr_2,
			m.def_addr_3,
			m.post_cd,
			m.phone_num,
			m.fax_num,
			m.acct_num,
			m.bank_name,
			m.acct_name,
			c.nama_prsh,
			c.broker_addr1,
			c.broker_addr2,
			c.broker_addr3,
			c.broker_post_cd,
			c.broker_phone,
			c.broker_fax,
			vl_random_value,
			vp_userid,
			vp_generate_date
		FROM
		(
			SELECT t.client_cd, p.price, p.stk_name,							
				p.paym_dt, t.fixed_qty f_qty,	
				t.pool_qty p_qty,	
				t.fixed_qty * p.price f_stk_value, 	
				ROUND(t.fixed_qty * p.price * t.ipo_perc/100, 0) f_fee,	
				t.pool_qty * p.price p_stk_value, 	
				0 p_fee	
			FROM T_IPO_CLIENT t, T_PEE p	
			WHERE p.stk_cd = vp_stk_cd	
			AND t.client_cd BETWEEN vp_client_from AND vp_client_to
			AND t.stk_Cd = vp_stk_cd 	
			AND t.approved_stat = 'A'
		) t,							
		(    
			SELECT MST_CLIENT.client_cd,					
				brch_cd, 					
				client_name, 					
				MST_CLIENT.def_addr_1, 
				MST_CLIENT.def_addr_2,
				MST_CLIENT.def_addr_3,
				MST_CLIENT.post_Cd, 
				MST_CIF.phone_num, 
				MST_CIF.Fax_num,
				NVL(f.bank_acct_num,brch_acct_num) acct_num,
				NVL(f.bank_name, b.bank_name) AS bank_name,
				NVL(acct_name, nama_prsh) acct_name
			FROM
			( 
				SELECT brch_cd, brch_acct_num, k.BANK_NAME					
				FROM MST_BRANCH b, MST_BANK_MASTER k		
				WHERE b.BANK_CD = k.bank_cd
			) b,
			( 
				SELECT client_cd, bank_acct_num, bank_short_name AS bank_name, acct_name				
				FROM MST_CLIENT_FLACCT		
				WHERE acct_stat <> 'C'
			) f,
			MST_COMPANY,
			MST_CLIENT,
			MST_CIF
			WHERE TRIM(branch_code) LIKE vp_brch_cd					
			AND TRIM(branch_code) = brch_cd
			AND MST_CLIENT.cifs = MST_CIF.cifs
			AND MST_CLIENT.client_cd = f.client_cd(+)
		) m,					
		(  
			SELECT nama_prsh, def_addr_1 AS broker_addr1, 					
				def_addr_2 AS broker_addr2,
				def_addr_3 AS broker_addr3,
				post_Cd AS broker_post_cd, 
				phone_num AS broker_phone, 
				Fax_num AS broker_fax
			FROM MST_COMPANY 
		) c					
		WHERE t.client_cd = m.client_cd;
	
	ELSE
		INSERT INTO R_IPO_LIST
		(
			client_cd,
			price,							
			stk_name,							
			paym_dt,							
			f_qty,							
			p_qty,							
			refund_qty,							
			distrib_qty,							
			stk_value, 							
			fee,							
			inv_amt,							
			client_name,							
			brch_cd,							
			subrek,
			refund_only_flg,
			rand_value,
			user_id,
			generate_date
		)
		SELECT t.client_cd,
			t.price,							
			t.stk_name,							
			NVL(vp_paym_dt,t.paym_dt),				
			t.f_qty,							
			t.p_qty,							
			t.p_qty - t.alloc_qty AS refund_qty,							
			t.f_Qty + t.alloc_qty AS distrib_qty,							
			DECODE(vp_report_type, 2, t.f_stk_value + t.p_stk_value, (t.p_qty - t.alloc_qty) * t.price) AS stk_value, 							
			t.f_fee + t.p_fee AS fee,							
			t.f_stk_value + t.f_fee + t.p_stk_value + t.p_fee AS inv_amt,							
			m.client_name,							
			TRIM(m.branch_code) branch_code,							
			m.subrek,
			DECODE(vp_report_type,3,'Y','N') AS refund_only_flg,
			vl_random_value,
			vp_userid,
			vp_generate_date			
		FROM
		( 
			SELECT t.client_cd, p.price, p.stk_name,							
				p.paym_dt, t.fixed_qty f_qty, t.pool_qty p_qty,	
				DECODE(t.alloc_qty,0,0, t.alloc_qty) AS alloc_qty,							
				t.fixed_qty * p.price f_stk_value, 	
				ROUND(t.fixed_qty * p.price * t.ipo_perc/100, 0) f_fee,	
				t.alloc_qty * p.price p_stk_value, 	
				0 p_fee	
			FROM T_IPO_CLIENT t, T_PEE p				
			WHERE p.stk_cd = vp_stk_cd				
			AND t.client_cd BETWEEN vp_client_from AND vp_client_to				
			AND t.stk_Cd = vp_stk_cd				
			AND t.approved_stat = 'A'
      and ((P_QTY_FLG=0) or (P_QTY_FLG=1 and t.fixed_qty>0) or (P_QTY_FLG=2 and t.alloc_qty>0))
		) t,							
		(
			SELECT m.client_cd,					
			branch_code, 					
			client_name,					
			SUBSTR(subrek001,6,4)||'-'||SUBSTR(subrek001,13,2) AS subrek							
			FROM MST_CLIENT m, V_CLIENT_SUBREK14 v					
			WHERE m.client_cd = v.client_cd
			AND TRIM(branch_code) LIKE vp_brch_cd        
		) m			
		WHERE t.client_cd = m.client_cd
		AND (vp_report_type <> 3 OR t.p_qty - t.alloc_qty > 0);					

	END IF;
	
    vo_random_value := vl_random_value;
    vo_errcd := 1;
    vo_errmsg := '';
	COMMIT;
  
EXCEPTION
    WHEN vl_err THEN
        ROLLBACK;
        vo_random_value := 0;
        vo_errmsg := SUBSTR(vo_errmsg,1,200);
    WHEN OTHERS THEN
        ROLLBACK;
        vo_random_value := 0;
        vo_errcd := -1;
        vo_errmsg := SUBSTR(SQLERRM(SQLCODE),1,200);
END;