create or replace 
PROCEDURE Sp_Mkbd_Vd51( 
p_update_date DATE,
p_update_seq NUMBER,
p_mkbd_date DATE,
p_price_date DATE,
p_user_id       insistpro_rpt.LAP_MKBD_VD51.user_id%TYPE,
p_error_code			OUT			NUMBER,
p_error_msg				OUT			VARCHAR2
) IS


/******************************************************************************
   NAME:       SP_MKBD_VD51
   PURPOSE:    

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        02/02/2015          1. Created this procedure.

   NOTES:


******************************************************************************/

v_begin_date DATE;
v_end_date DATE;
v_begin_prev DATE;
v_cre_dt DATE:=SYSDATE;

--p_price_date DATE;

CURSOR csr_subtot_grp1 IS
SELECT f.grp1, SUM(l.c1) sum_amt
FROM insistpro_rpt.LAP_MKBD_VD51 l, 
( SELECT mkbd_cd, description,
					grp1, grp2, grp3
		  FROM FORM_MKBD
		  WHERE source = 'VD51'
			AND mkbd_cd > 7
			AND grp1 IS NOT NULL
		  AND v_end_date  BETWEEN ver_bgn_dt AND ver_end_dt) f
WHERE update_date = p_update_date
AND update_seq = p_update_seq
AND l.mkbd_cd = f.mkbd_cd
GROUP BY f.grp1;

CURSOR csr_subtot_grp2  IS
SELECT f.grp2, SUM(l.c1) sum_amt
FROM insistpro_rpt.LAP_MKBD_VD51 l, 
( SELECT mkbd_cd, description,
					grp1, grp2, grp3
		  FROM FORM_MKBD
		  WHERE source = 'VD51'
			AND mkbd_cd > 7
			AND grp2 IS NOT NULL
		  AND v_end_date  BETWEEN ver_bgn_dt AND ver_end_dt) f
WHERE update_date = p_update_date
AND update_seq = p_update_seq
AND l.mkbd_cd = f.mkbd_cd
GROUP BY f.grp2;

v_err EXCEPTION;
v_error_code				NUMBER;
v_error_msg					VARCHAR2(200);

BEGIN
   
   v_end_date := p_mkbd_date;
   v_begin_date := TO_DATE('01'||TO_CHAR(p_mkbd_date,'/mm/yy'), 'dd/mm/yy');
   v_begin_prev := v_begin_date - 1;
   v_begin_prev := TO_DATE('01'||TO_CHAR(v_begin_prev,'/mm/yy'), 'dd/mm/yy');
   
  
  BEGIN
   INSERT INTO insistpro_rpt.LAP_MKBD_VD51 (
   UPDATE_DATE, UPDATE_SEQ, MKBD_DATE, 
   VD, MKBD_CD, DESCRIPTION, 
   C1, user_id, approved_stat,CRE_DT, price_date) 
SELECT  p_update_date update_date , p_update_seq update_seq , P_MKbd_date AS mkbd_date,
     'VD51' AS vd, LPAD(TO_CHAR(mk.mkbd_cd),3) mkbd_cd,  description,
				   NVL(curr_mon,0)  c1, p_user_id,'E' AS approved_stat,V_CRE_DT, p_price_date
FROM(	SELECT mkbd_cd,
				 SUM(beg_bal + trx_amt) curr_mon
		 FROM(  SELECT  m.mkbd_cd, 
							 (NVL(b.deb_obal,0) - NVL(b.cre_obal,0)) beg_bal,
							0 trx_amt
					FROM T_DAY_TRS b, MST_MAP_MKBD m
					WHERE b.trs_dt = v_begin_date
					  AND   b.gl_acct_cd   = m.GL_a
					  AND m.source = 'VD51'
					  AND v_end_date  BETWEEN m.ver_bgn_dt AND m.ver_end_dt
					UNION ALL
				  SELECT   m.mkbd_cd, 
								0 beg_bal,
								(DECODE(d.db_cr_flg,'D',NVL(d.curr_val,0),0) - DECODE(d.db_cr_flg,'C',NVL(d.curr_val,0),0)) trx_amt
					FROM T_ACCOUNT_LEDGER d, MST_MAP_MKBD m
					WHERE d.doc_date BETWEEN v_begin_date AND v_end_date
					AND d.approved_sts <> 'C' AND d.approved_sts <> 'E' 			
					AND   d.gl_acct_cd   = m.GL_a
					AND m.source = 'VD51'
					AND v_end_date  BETWEEN m.ver_bgn_dt AND m.ver_end_dt
				UNION ALL
					SELECT 16 mkbd_cd, 0 beg_bal,
					SUM(DECODE(SIGN( (to_dt - v_end_date) - 90), -1, amount,0, amount,0)) less3mon
					FROM T_DEPOSIT
					WHERE to_dt > v_end_date
				UNION ALL
					SELECT 18 mkbd_cd,0 beg_bal,
					SUM(DECODE( SIGN(more3mon - jaminan_lps), -1,more3mon,jaminan_lps)) dijamin
					FROM( SELECT bank_cd, jaminan_lps, amount,
					DECODE(SIGN( (to_dt - v_end_date) - 90), 1, amount,0) more3mon
					FROM T_DEPOSIT
					WHERE to_dt > v_end_date)
				UNION ALL
					SELECT 20 mkbd_cd,0 beg_bal,
					SUM( DECODE( SIGN(more3mon - jaminan_lps), -1,0,more3mon- jaminan_lps)) tdk_dijamin
					FROM( SELECT bank_cd, jaminan_lps, amount,
					DECODE(SIGN( (to_dt - v_end_date) - 90), 1, amount,0) more3mon
					FROM T_DEPOSIT
					WHERE to_dt > v_end_date)
				UNION ALL
				SELECT DECODE(a.secu_type,'EBE',27,'OSK',26,'SBN',25) mkbd_cd,
                  SUM(DECODE(t.db_Cr_flg,'D',1,-1) * t.curr_val) amt, 0
				FROM( SELECT DISTINCT h.repo_num, h.client_Cd, h.sett_val, v.doc_num, h. secu_type
						FROM T_REPO h, T_REPO_HIST s, T_REPO_VCH v
							WHERE h.repo_num = v.repo_num
                     AND h.approved_stat = 'A'
                     AND v.approved_stat = 'A'
							AND h.repo_num = s.repo_num
							AND s.due_date >= v_end_date ) a,
							 T_ACCOUNT_LEDGER t,
						( SELECT mkbd_cd, gl_a
						  FROM  MST_MAP_MKBD
						  WHERE source = 'VD51'
							AND mkbd_cd =27) m
				WHERE a.doc_num = t.xn_doc_num
				AND t.doc_date <= v_end_date
				AND trim(t.gl_acct_Cd) = trim(m.gl_A)
				AND sl_Acct_Cd = a.CLIENT_CD
				AND t.approved_sts = 'A'
				AND t.reversal_jur = 'N'
				GROUP BY a.secu_type
				UNION ALL
					SELECT 34 mkbd_cd, DECODE(SIGN(amt),-1,0,amt), 0 
					FROM( SELECT  SUM(beg_bal + mvmt) amt
							FROM(	SELECT  (b.deb_obal -b.cre_obal) beg_bal, 0 mvmt
									FROM T_DAY_TRS b
									WHERE b.trs_dt = v_begin_prev
									AND   b.gl_acct_cd IN ( SELECT gl_a FROM v_gl_acct_type WHERE acct_type IN ('CLIE'))
									UNION ALL
									SELECT  0 beg_bal, 
										  DECODE(d.db_cr_flg,'D',1,-1) * d.curr_val mvmt
									FROM T_ACCOUNT_LEDGER d
									WHERE d.doc_date BETWEEN v_begin_prev AND v_end_date 
									AND d.approved_sts <> 'C' AND d.approved_sts <> 'E' 		
									AND d.due_date  <= v_end_date	
                  AND   d.gl_acct_cd IN ( SELECT gl_a FROM v_gl_acct_type WHERE acct_type IN ('CLIE'))
                  ))
				   UNION ALL
				   SELECT 	mkbd_cd, 0 beg_bal, GREATEST(net_trx,0) + buy_trx
				   FROM( SELECT   due_date, sl_acct_cd,
										34 mkbd_cd, 
										SUM(DECODE(t.mrkt_type,'RG',DECODE(d.db_cr_flg,'D',1,-1) * curr_val,0)) net_trx,
										SUM(DECODE(D.Db_Cr_Flg,'D',DECODE(T.Mrkt_Type,'RG',0,1) * Curr_Val,0)) Buy_Trx
							  FROM T_ACCOUNT_LEDGER d,
									( SELECT DECODE(SUBSTR(contr_num,6,1),'I',SUBSTR(contr_num,1,6)||'0'||SUBSTR(contr_num,8,7), contr_num) AS contr_num, 
											 DECODE(SUBSTR(contr_num,6,1),'I',SUBSTR(contr_num,5,2),mrkt_type) mrkt_type
						              FROM 	T_CONTRACTS
										  WHERE  contr_dt BETWEEN v_begin_date - 30  AND v_end_date 
										  AND contr_stat <>'C'
										  AND record_source <> 'IB'
 											UNION ALL
										  SELECT doc_num, 'RG'
										  FROM T_BOND_TRX
										 WHERE  trx_date BETWEEN v_begin_date - 30     AND v_end_date 
										  AND approved_sts <> 'C'
										  AND value_dt >v_end_date) t
									  WHERE d.doc_Date BETWEEN v_begin_date - 30 AND v_end_date 
									  AND d.due_Date > v_end_date 
									  AND d.approved_sts <> 'C' AND d.approved_sts <> 'E' 			
										AND   d.gl_acct_cd  IN ( SELECT gl_a FROM v_gl_acct_type WHERE acct_type IN ('CLIE'))
									  AND d.xn_doc_num = t.CONTR_NUM
						 GROUP BY   due_date,sl_acct_cd   ) 
				   WHERE net_trx > 0 OR buy_trx >0
				UNION ALL
				  SELECT  34 mkbd_cd, 0 beg_bal, SUM(curr_val)
				  FROM T_ACCOUNT_LEDGER d
				  WHERE doc_Date BETWEEN v_begin_date - 30 AND v_end_date 
				  AND due_Date > v_end_date 
				  AND approved_sts <> 'C' AND approved_sts <> 'E' 
				  AND reversal_jur = 'N'			
				  AND record_source = 'GL'
				  AND   xn_doc_num LIKE '%GLAMFE%'
				  AND tal_id = 1
				UNION ALL
					SELECT 30 mkbd_cd, DECODE(SIGN(amt),-1,0,amt), 0 
					FROM( SELECT  SUM(beg_bal + mvmt) amt
							FROM(	SELECT (b.deb_obal -b.cre_obal) beg_bal, 0 mvmt
									FROM T_DAY_TRS b
									WHERE b.trs_dt = v_begin_prev
									AND   b.gl_acct_cd  IN ( SELECT gl_a FROM v_gl_acct_type WHERE acct_type IN ('KPEI'))
									UNION ALL
									SELECT  0 beg_bal, 
										  DECODE(d.db_cr_flg,'D',1,-1) * d.curr_val mvmt
									FROM T_ACCOUNT_LEDGER d
									WHERE d.doc_date BETWEEN v_begin_prev AND v_end_date 
									AND d.approved_sts <> 'C' AND d.approved_sts <> 'E'
									AND d.due_date  <= v_end_date	
									AND   d.gl_acct_cd  IN ( SELECT gl_a FROM v_gl_acct_type WHERE acct_type IN ('KPEI')) ))
				   UNION ALL
				   SELECT 	mkbd_cd, 0 beg_bal, GREATEST(net_trx,0)
				   FROM( SELECT   due_date, 
										30 mkbd_cd, 
										SUM(DECODE(d.db_cr_flg,'D',1,-1) * curr_val) net_trx
							  FROM T_ACCOUNT_LEDGER d
									  WHERE d.doc_Date BETWEEN v_begin_date - 30 AND v_end_date 
									  AND d.due_Date > v_end_date 
									  AND d.approved_sts <> 'C' AND d.approved_sts <> 'E' 			
									  AND d.reversal_jur = 'N' 		
                  AND   d.gl_acct_cd IN ( SELECT gl_a FROM v_gl_acct_type WHERE acct_type IN ('KPEI'))
										AND d.record_source = 'CG'
						 GROUP BY   due_date   ) 
				   WHERE net_trx > 0
				 UNION ALL
					SELECT 35 mkbd_cd, SUM(	n.end_bal), 0
						FROM(	SELECT client_cd,   SUM(beg_bal + mvmt ) end_bal
								FROM(  SELECT TRIM(T_ACCOUNT_LEDGER.sl_acct_cd)  client_cd, 0 beg_bal,
												DECODE(T_ACCOUNT_LEDGER.db_cr_flg, 'D', 1, -1) * NVL(T_ACCOUNT_LEDGER.curr_val, 0) mvmt 
										 FROM T_ACCOUNT_LEDGER
										WHERE T_ACCOUNT_LEDGER.doc_date >= v_begin_date 
										 AND  T_ACCOUNT_LEDGER.doc_date <= v_end_date 
										 AND  T_ACCOUNT_LEDGER.approved_sts  <> 'C' 
										 AND  T_ACCOUNT_LEDGER.approved_sts  <> 'E'
                 						 AND  T_ACCOUNT_LEDGER.gl_acct_cd    IN ( SELECT gl_a FROM v_gl_acct_type WHERE acct_type IN ('T3'))
										UNION ALL	  
										 SELECT TRIM(T_DAY_TRS.sl_acct_cd), 
												(NVL(T_DAY_TRS.deb_obal, 0) - NVL(T_DAY_TRS.cre_obal, 0)) beg_bal, 0 mvmt 
											 FROM T_DAY_TRS  
											WHERE T_DAY_TRS.gl_acct_cd   IN ( SELECT gl_a FROM v_gl_acct_type WHERE acct_type IN ('T3'))
											  AND  T_DAY_TRS.trs_dt = v_begin_date)
								GROUP BY client_cd
								HAVING SUM(beg_bal + mvmt ) > 0) n,
							( SELECT m.client_cd, m.client_name
								FROM MST_CLIENT m, LST_TYPE3 l
								WHERE m.client_type_3 = l.cl_type3
								 AND  m.client_type_1 <> 'B'
								 AND  l.margin_cd = 'M') m
						WHERE m.client_cd         = n.client_cd		
				  UNION ALL
					SELECT  mkbd_cd, 0, market_Value							   
					FROM(	SELECT  stk_cd, jatuhtempo, price, nominal, market_value,
									sisa_thn,
									DECODE(SIGN(sisa_thn - 7),1,DECODE(SIGN(sisa_thn - 15), 1,63, 62) ,61   )  mkbd_cd,
									DECODE(sisa_thn,0,0,DECODE(SIGN(sisa_thn - 7),1,DECODE(SIGN(sisa_thn - 15), 1,0.1,0.075),0.05   ) ) haircut
							FROM( SELECT  t.stk_cd, m.pp_to_dt jatuhtempo, p.price/100 AS price, t.bal_qty AS nominal, 
										p.price *  t.bal_qty/100 AS market_value,
										 (m.pp_to_dt - v_end_date) / 365 AS sisa_thn 
									 FROM( SELECT  stk_cd, SUM(qty) AS bal_qty
											  FROM V_OWN_PORTO
											WHERE DOC_DT BETWEEN v_begin_date AND v_end_date
											GROUP BY stk_cd) t,
									MST_COUNTER m,
									T_BOND_PRICE p,
                           ( SELECT COUNT(1) cnt
                              FROM MST_SYS_PARAM
                              WHERE param_id = 'MKBD'
							  AND param_cd1 = 'VD51'
							  AND param_cd2= 'BOND'
							  AND v_end_date BETWEEN ddate1 AND ddate2
							  AND dflg1 = 'Y') r
									WHERE t.stk_cd = m.stk_cd
									AND trim(m.CTR_TYPE) = 'OB'
									AND m.sbi_flg = 'Y'
									AND m.pp_to_dt >= v_end_Date 
									AND p.price_dt = v_end_date
									AND p.bond_cd = t.stk_Cd
                           AND r.cnt = 1) 
								WHERE sisa_thn > 0)
					UNION ALL
					  SELECT mkbd_cd, 0,  market_value
						FROM( SELECT   t.stk_cd, 
											p.price *  t.bal_qty/100 AS market_value, 
											h.haircut/100 AS haircut 
								 FROM(  SELECT stk_cd, SUM(qty) AS bal_qty
									FROM v_OWN_PORTO
									 WHERE doc_dt BETWEEN v_begin_date AND v_end_date 
									 GROUP BY stk_cd ) t, 				 				
									MST_COUNTER m, 
									T_BOND_PRICE p, 
									T_BOND_HAIRCUT h 
								WHERE t.stk_cd = m.stk_cd 
								AND trim(m.CTR_TYPE) = 'OB' 
								AND m.sbi_flg <> 'Y' 
								AND m.pp_to_dt >= v_end_Date 
								AND p.price_dt = v_end_date 
								AND p.bond_cd = t.stk_Cd 
								AND v_end_Date BETWEEN h.eff_dt_from AND h.eff_dt_to 
								AND h.rate_cd = p.bond_rate ) a,
							(  SELECT faktorisasi, mkbd_cd
							FROM FORM_MKBD 
							WHERE mkbd_cd BETWEEN 65 AND 69
							AND source = 'VD51'
							AND v_end_date BETWEEN ver_bgn_dt AND ver_end_dt ) f
						WHERE a.haircut = f.faktorisasi
					UNION ALL
					SELECT mkbd_cd, 0,  market_value
					FROM(  SELECT t.stk_cd,
									t.bal_qty AS nominal,
									p.stk_clos AS price,
									t.bal_qty * p.stk_clos AS market_value,
									b.haircut_mkbd
								FROM(  SELECT t.stk_cd,  HAIRCUT_MKBD
											FROM v_STK_HAIRCUT_MKBD  t, 
											 ( SELECT stk_cd, MAX(eff_dt) max_dt 
												 FROM V_STK_HAIRCUT_MKBD 
												 WHERE eff_dt <= v_end_date
												 GROUP BY stk_cd) mx 
											WHERE t.eff_dt = mx.max_Dt
											AND t.stk_cd = mx.stk_cd) b,  
									( SELECT  stk_cd, SUM(qty) AS bal_qty 
									  FROM V_OWN_PORTO 
									WHERE DOC_DT BETWEEN v_begin_date AND v_end_date
									GROUP BY stk_cd) t,
									T_CLOSE_PRICE p
								WHERE  t.bal_qty > 0
								AND p.stk_date = p_price_date
								AND p.stk_cd = t.stk_cd
								AND t.stk_cd = b.stk_cd	) a,
						( SELECT faktorisasi, mkbd_cd
							FROM FORM_MKBD 
							WHERE mkbd_cd BETWEEN 71 AND 80
							AND source = 'VD51'
							AND v_end_date BETWEEN ver_bgn_dt AND ver_end_dt ) f
					WHERE a.haircut_mkbd = f.faktorisasi
					UNION ALL
					SELECT m.mkbd_cd, 0,
					SUM(t.unit * n.nab_unit) AS market_value
					FROM( SELECT reks_cd,  reks_type,SUM(subs -redm) unit
							FROM T_REKS_TRX
							WHERE trx_date <= v_end_date
                        AND approved_stat = 'A'
							GROUP BY  reks_cd,  reks_type
							HAVING SUM(subs -redm) > 0 ) t,
						(  SELECT reks_cd, nab_unit, nab
							FROM T_REKS_NAB 
							WHERE mkbd_dt = p_price_date
                       AND approved_stat = 'A') n,
						MST_REKS_TYPE m	 
					WHERE t.reks_cd = n.reks_cd
					       AND t.reks_type= m.reks_type
					GROUP BY m.mkbd_cd
					UNION ALL
					SELECT  99 mkbd_cd, 0, SUM(b.end_repo * c.price) amt 		
					 FROM( SELECT  stk_cd, 
										SUM(repo_jual) end_repo
										FROM V_OWN_PORTO 
									  WHERE doc_dt BETWEEN v_begin_date AND v_end_date 
								GROUP BY stk_cd ) b,
						( SELECT v.stk_cd, DECODE(NVL(stk_clos,0),0,NVL(stk_prev,0),stk_clos) price 
							FROM v_stk_clos v,  MST_COUNTER m 
							WHERE v.stk_date = p_price_date
							       AND v.stk_Cd = m.stk_cd
								   AND m.ctr_type <> 'OB'  ) c	
						WHERE  b.stk_cd = c.stk_cd
					UNION ALL
						SELECT 103 mkbd_cd, SUM(	n.end_bal), 0
						FROM(	SELECT client_cd,   SUM(beg_bal + mvmt ) end_bal
								FROM(  SELECT TRIM(T_ACCOUNT_LEDGER.sl_acct_cd)  client_cd, 0 beg_bal,
												DECODE(T_ACCOUNT_LEDGER.db_cr_flg, 'D', 1, -1) * NVL(T_ACCOUNT_LEDGER.curr_val, 0) mvmt 
										 FROM T_ACCOUNT_LEDGER
										WHERE T_ACCOUNT_LEDGER.doc_date >= v_begin_date 
										 AND  T_ACCOUNT_LEDGER.doc_date <= v_end_date 
										 AND  T_ACCOUNT_LEDGER.approved_sts  <> 'C' 
										 AND  T_ACCOUNT_LEDGER.approved_sts  <> 'E'
                  	 AND  T_ACCOUNT_LEDGER.gl_acct_cd     IN ( SELECT gl_a FROM v_gl_acct_type WHERE acct_type IN ('T3'))
										UNION ALL	  
										 SELECT TRIM(T_DAY_TRS.sl_acct_cd), 
												(NVL(T_DAY_TRS.deb_obal, 0) - NVL(T_DAY_TRS.cre_obal, 0)) beg_bal, 0 mvmt 
											 FROM T_DAY_TRS  
											WHERE  T_DAY_TRS.gl_acct_cd     IN ( SELECT gl_a FROM v_gl_acct_type WHERE acct_type IN ('T3'))
											  AND  T_DAY_TRS.trs_dt = v_begin_date
											  )
								GROUP BY client_cd
								HAVING SUM(beg_bal + mvmt ) > 0) n,
							( SELECT m.client_cd, m.client_name
								FROM MST_CLIENT m, LST_TYPE3 l
								WHERE m.client_type_3 = l.cl_type3
								 AND  m.client_type_1 <> 'B'
								 AND  l.margin_cd = 'R') m
						WHERE m.client_cd         = n.client_cd)
		GROUP BY mkbd_cd	) X,
		( SELECT mkbd_cd, description,
					grp1, grp2, grp3
		  FROM FORM_MKBD
		  WHERE source = 'VD51'
			AND mkbd_cd > 7
		  AND v_end_date  BETWEEN ver_bgn_dt AND ver_end_dt) MK
	WHERE mk.mkbd_cd = x.mkbd_cd(+)
	ORDER BY 1;
EXCEPTION
WHEN OTHERS THEN
	 		v_error_code := -3;
			v_error_msg :=  SUBSTR('Insert to LAP_MKBD_VD51 '||SQLERRM,1,200);
			RAISE v_err;
END;
	
	
	FOR rec IN csr_subtot_grp1  LOOP
			BEGIN
			UPDATE insistpro_rpt.LAP_MKBD_VD51
			SET c1 = rec.sum_amt
			WHERE  update_date = p_update_date
			AND update_seq = p_update_seq
			and mkbd_cd = rec.grp1;
			EXCEPTION
			WHEN OTHERS THEN
	 		v_error_code := -4;
			v_error_msg :=  SUBSTR('Update LAP_MKBD_VD51 line : '||rec.grp1||SQLERRM,1,200);
			RAISE v_err;
			END;
	END LOOP;
	
	FOR rec IN csr_subtot_grp2 LOOP
			BEGIN
			UPDATE insistpro_rpt.LAP_MKBD_VD51
			SET c1 = rec.sum_amt
			WHERE  update_date = p_update_date
			AND update_seq = p_update_seq
			and mkbd_cd = rec.grp2;
			EXCEPTION
			WHEN OTHERS THEN
	 		v_error_code := -4;
			v_error_msg :=  SUBSTR('Update LAP_MKBD_VD51 line : '||rec.grp2||SQLERRM,1,200);
			RAISE v_err;
			END;			
	END LOOP;
	
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
END Sp_Mkbd_Vd51;
