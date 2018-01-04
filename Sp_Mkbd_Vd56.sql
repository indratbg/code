create or replace 
PROCEDURE Sp_Mkbd_Vd56( 
p_update_date DATE,
p_update_seq NUMBER,
p_mkbd_date DATE,
p_price_date DATE,
p_user_id       insistpro_rpt.LAP_MKBD_VD51.user_id%TYPE,
p_error_code			OUT			NUMBER,
p_error_msg				OUT			VARCHAR2
) IS

/******************************************************************************
   NAME:       SP_MKBD_VD56
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
CURSOR csr_subtot_grp1 IS
SELECT f.grp1, SUM(l.c1) sum_amt
FROM insistpro_rpt.LAP_MKBD_VD56 l, 
( SELECT mkbd_cd, description,
					grp1, grp2, grp3
		  FROM FORM_MKBD
		  WHERE source = 'VD56'
			AND mkbd_cd > 7
			AND grp1 IS NOT NULL
		  AND v_end_date  BETWEEN ver_bgn_dt AND ver_end_dt) f
WHERE update_date = p_update_date
AND update_seq = p_update_seq
AND l.mkbd_cd = f.mkbd_cd
GROUP BY f.grp1;

v_err EXCEPTION;
v_error_code				NUMBER;
v_error_msg					VARCHAR2(200);

BEGIN

   
   v_end_date := p_mkbd_date;
   v_begin_date := TO_DATE('01'||TO_CHAR(p_mkbd_date,'/mm/yy'), 'dd/mm/yy');
   v_begin_prev := v_begin_date - 1;
   v_begin_prev := TO_DATE('01'||TO_CHAR(v_begin_prev,'/mm/yy'), 'dd/mm/yy');
   
   
  BEGIN 
INSERT INTO INSISTPRO_RPT.LAP_MKBD_VD56 (
   UPDATE_DATE, UPDATE_SEQ, MKBD_DATE, 
   VD, MKBD_CD, NORUT, 
   DESCRIPTION, C1, C2, 
   C3, C4, MILIK, 
   BANK_ACCT_CD, CURRENCY, user_id, APPROVED_STAT,CRE_DT, price_date) 
SELECT  p_update_date update_date , p_update_seq  update_seq , p_mkbd_date AS mkbd_date,
     'VD56' AS vd,  LPAD(TO_CHAR(mkbd_cd),2) mkbd_cd,     norut,
   description,     c1,  c2, 
    c3,  c4, milik, 
	bank_acct_cd,  currency, p_user_id, 'E' APPROVED_STAT, V_CRE_DT, p_price_date
FROM( 
		SELECT	 	 mk.mkbd_cd,    -1 norut,
		   description,   NVL(sum_amt,0)  c1, NVL(c2,0) c2, 
		   NVL(c3,0) c3, NVL(c4,0) c4,
		  NULL  milik, NULL bank_acct_cd, NULL currency
		 FROM( SELECT  mkbd_cd,
				       SUM(sum_amt) sum_amt,
		             SUM(c2) c2,
					 SUM(c3) c3,
		             SUM(c4) c4    
				FROM( SELECT mkbd_cd,
						       SUM(amt) sum_amt,
				             DECODE(mkbd_cd,17,SUM(amt),19,SUM(amt),SUM(c2)) c2,
							 DECODE(mkbd_cd,13,SUM(amt),SUM(c3)) c3,
				             SUM(c4) c4 
						FROM( SELECT  m.mkbd_cd, 
									 (NVL(b.deb_obal,0) - NVL(b.cre_obal,0)) amt,
		                       0 c2, 0 c3, 0 c4
							FROM T_DAY_TRS b, MST_MAP_MKBD m
							WHERE b.trs_dt = v_begin_date
							  AND   b.gl_acct_cd   = m.GL_a
							  AND m.source = 'VD56'
							  AND v_end_date  BETWEEN m.ver_bgn_dt AND m.ver_end_dt
						UNION ALL
						  SELECT   m.mkbd_cd, 
										(DECODE(d.db_cr_flg,'D',NVL(d.curr_val,0),0) - DECODE(d.db_cr_flg,'C',NVL(d.curr_val,0),0)) trx_amt,
		                       0, 0, 0
							FROM T_ACCOUNT_LEDGER d, MST_MAP_MKBD m
							WHERE d.doc_date BETWEEN v_begin_date AND v_end_date
							AND d.approved_sts <> 'C' AND d.approved_sts <> 'E' 			
							AND   d.gl_acct_cd   = m.GL_a
							AND m.source = 'VD56'
							AND v_end_date  BETWEEN m.ver_bgn_dt AND m.ver_end_dt
						UNION ALL
							SELECT mkbd_cd, amt,
							 DECODE(MKBD_CD,10,DECODE(afil,'A',n.amt,0),0) afiliasi,
							 DECODE(MKBD_CD,10,DECODE(afil,'A',0,n.amt),amt) tdk_afiliasi,
							   0 c4 
							FROM(	 SELECT n1.CLIENT_CD, MKBD_CD,   NVL( afil,'N') afil,
											 SUM(mvmt ) amt
									FROM( SELECT T_FUND_LEDGER.CLIENT_cD, M.mkbd_cd, 
											DECODE( SUBSTR(T_FUND_LEDGER.acct_cd,1,1),'D',1,-1) *										
											(T_FUND_LEDGER.DEBIT - T_FUND_LEDGER.CREDIT) mvmt 
											 FROM T_FUND_LEDGER, MST_MAP_MKBD m,  
											 ( SELECT client_Cd
													 FROM MST_CLIENT
													 UNION ALL
													 SELECT 'UMUM'
													 FROM dual) MST_CLIENT
											WHERE   T_FUND_LEDGER.CLIENT_CD = MST_CLIENT.client_cd
											 AND  T_FUND_LEDGER.doc_date >= TRUNC(v_begin_date) 
											 AND  T_FUND_LEDGER.doc_date <= TRUNC(v_end_date) 
											 AND  T_FUND_LEDGER.approved_sts  = 'A' 
											 AND  T_FUND_LEDGER.acct_cd   = TRIM(M.gl_A) 
											 AND  m.source = 'VD56'
											AND v_end_date  BETWEEN m.ver_bgn_dt AND m.ver_end_dt
		                            UNION ALL	  
		                            SELECT T_FUND_BAL.CLIENT_cD, M.mkbd_cd, 
													DECODE( SUBSTR(T_FUND_BAL.acct_cd,1,1),'D',1,-1) *										
															(NVL(T_FUND_BAL.debit, 0) - NVL(T_FUND_BAL.credit, 0)) beg_bal
												 FROM T_FUND_BAL,MST_MAP_MKBD m,
												 ( SELECT client_Cd
														 FROM MST_CLIENT
														 UNION ALL
														 SELECT 'UMUM'
														 FROM dual) MST_CLIENT
												WHERE   T_FUND_BAL.client_cd = MST_CLIENT.client_cd 
		                               AND  T_FUND_BAL.acct_cd = TRIM(m.gl_a)
												 AND  T_FUND_BAL.bal_dt = TRUNC(v_begin_date)
												AND  m.source = 'VD56'
												AND v_end_date  BETWEEN m.ver_bgn_dt AND m.ver_end_dt  ) n1,
									( SELECT client_Cd, 'A' afil
											   FROM T_CLIENT_AFILIASI
											   WHERE v_end_date BETWEEN from_dt AND to_dt) AFIL 	
									WHERE n1.client_Cd = afil.client_cd(+)		   					
									GROUP BY n1.CLIENT_CD, MKBD_CD,    afil
		                      HAVING SUM(mvmt ) <> 0) N 
						UNION ALL
							SELECT mkbd_cd, amt,
							 DECODE(MKBD_CD,10,DECODE(afil,'A',n.amt,0),0) afiliasi,
							 DECODE(MKBD_CD,10,DECODE(afil,'A',0,n.amt),0) tdk_afiliasi,
							 DECODE(mkbd_cd,20,n.amt,0) c4
							FROM(	   SELECT CLIENT_CD, MKBD_CD,    afil,
											 SUM(mvmt ) amt
									FROM(	SELECT T_FUND_KSEI_LEDGER.CLIENT_cD, M.mkbd_cd, 
										   								 NVL(AFIL.client_cd,'N') AS afil,
																		DECODE( SUBSTR(T_FUND_KSEI_LEDGER.acct_cd,1,1),'D',1,-1) *										
																		(T_FUND_KSEI_LEDGER.DEBIT - T_FUND_KSEI_LEDGER.CREDIT) mvmt 
											 FROM MST_CLIENT,T_FUND_KSEI_LEDGER, MST_MAP_MKBD m,
											 ( SELECT client_Cd
											   FROM T_CLIENT_AFILIASI
											   WHERE v_end_date BETWEEN from_dt AND to_dt) AFIL
											WHERE   T_FUND_KSEI_LEDGER.CLIENT_CD = MST_CLIENT.client_cd
											 AND  T_FUND_KSEI_LEDGER.doc_date <= TRUNC(v_end_date) 
											 AND  T_FUND_KSEI_LEDGER.approved_sts  = 'A' 
											 AND  T_FUND_KSEI_LEDGER.acct_cd   = TRIM(M.gl_A) 
											 AND  m.source = 'VD56'
											AND v_end_date  BETWEEN m.ver_bgn_dt AND m.ver_end_dt
											AND T_FUND_KSEI_LEDGER.CLIENT_CD = AFIL.CLIENT_CD(+))
									GROUP BY CLIENT_CD, MKBD_CD,    afil
		                      HAVING SUM(mvmt ) <> 0 ) N )
							  GROUP BY MKBD_CD	
						UNION ALL	
						 SELECT B.MKBD_CD, A.TOT_SALDO_KREDIT, 
						 		DECODE(b.mkbd_cd,10,a.tot_saldo_kre_afil,0) c2,
								DECODE(b.mkbd_cd,10,A.TOT_SALDO_KREDIT - a.tot_saldo_kre_afil,0)  c3,  
						 		DECODE(b.mkbd_cd,20,A.TOT_SALDO_KREDIT,0) c4
						 FROM( SELECT  SUM(ABS(SALDO_KREDIT)) TOT_SALDO_KREDIT,
						 		 		  SUM(ABS(saldo_kre_afil)) tot_saldo_kre_afil
							  	FROM( SELECT a1.client_cd,   
									 SUM(beg_bal + mvmt ) SALDO_KREDIT,
									 SUM(DECODE(afil,'A',beg_bal + mvmt,0)) saldo_kre_afil
									 FROM(  SELECT TRIM(MST_CLIENT.client_cd)  client_cd, 0 beg_bal,
												DECODE(T_ACCOUNT_LEDGER.db_cr_flg, 'D', 1, -1) * NVL(T_ACCOUNT_LEDGER.curr_val, 0) mvmt
											 FROM T_ACCOUNT_LEDGER, MST_CLIENT 
											WHERE   T_ACCOUNT_LEDGER.sl_acct_cd = MST_CLIENT.client_cd
											 AND  T_ACCOUNT_LEDGER.doc_date BETWEEN v_begin_date AND v_end_date
											 AND  T_ACCOUNT_LEDGER.approved_sts  = 'A' 
											 AND  T_ACCOUNT_LEDGER.gl_acct_cd   IN ( SELECT gl_a FROM v_gl_acct_type WHERE acct_type IN ('T3')) 
											UNION ALL	  
											 SELECT TRIM(MST_CLIENT.client_cd), 
													(NVL(T_DAY_TRS.deb_obal, 0) - NVL(T_DAY_TRS.cre_obal, 0)) beg_bal, 
													0 mvmt
												 FROM T_DAY_TRS, MST_CLIENT		
												WHERE T_DAY_TRS.trs_dt = v_begin_date   
												  AND  T_DAY_TRS.gl_acct_cd     IN ( SELECT gl_a FROM v_gl_acct_type WHERE acct_type IN ('T3'))
												 AND  T_DAY_TRS.sl_acct_cd = MST_CLIENT.client_cd) A1,
										 ( SELECT client_Cd, 'A' afil
									   FROM T_CLIENT_AFILIASI
									   WHERE v_end_date BETWEEN from_dt AND to_dt) AFIL 
									   WHERE a1.client_Cd = afil.client_cd(+)
									GROUP BY a1.client_cd, afil
									HAVING SUM(beg_bal + mvmt ) < 0 )) A,
									( SELECT 10 MKBD_CD FROM DUAL
									  UNION 
									  SELECT 20 MKBD_CD FROM DUAL) B)
								GROUP BY MKBD_CD) X,
				( SELECT mkbd_cd, description,texttab,vis1, vis2, vis3, vis4,
				         grp1, grp2, grp3
				  FROM FORM_MKBD
				  WHERE source = 'VD56'
				   AND mkbd_cd > 6) MK
				WHERE mk.mkbd_cd = x.mkbd_cd(+) 
UNION ALL
SELECT 24 mkbd_cd,
	row_number( ) over (ORDER BY gl_acct_cd, sl_acct_cd) AS norut, 
   bank_name,
   0 c1, 0 c2, FOREX_AMT  c3,  sum_amt c4,
   milik,
   bank_acct_cd,  currency   
FROM( SELECT T.gl_acct_cd, T.sl_acct_cd, T.milik,    
              m.bank_acct_cd, DECODE(t.sl_acct_cd,'000000','Petty Cash',m.bank_name) BANK_NAME,
              T.SUM_AMT, M.CURR_CD currency,
			  DECODE(M.CURR_CD,'IDR',T.SUM_AMT,ROUND(T.SUM_AMT / M.RATE,2) ) FOREX_AMT
		FROM( SELECT gl_acct_cd,sl_acct_cd, milik, SUM(amt) sum_amt
				FROM( SELECT gl_acct_cd, sl_acct_cd, milik,  amt
						 FROM(   SELECT  b.gl_acct_cd,DECODE( trim(g.acct_type),'KAS','000000',b.sl_acct_cd) sl_acct_cd, 
												'SENDIRI' milik, 
											 (NVL(b.deb_obal,0) - NVL(b.cre_obal,0)) amt
									FROM T_DAY_TRS b, MST_MAP_MKBD m,     MST_GL_ACCOUNT g
									WHERE b.trs_dt = v_begin_date
									  AND   b.gl_acct_cd   = m.GL_a
									  AND m.source = 'VD56'
									  AND m.MKBD_CD  BETWEEN 18 AND 19
									  AND v_end_date  BETWEEN m.ver_bgn_dt AND m.ver_end_dt
									 AND b.gl_acct_cd = g.gl_a
										 AND b.Sl_acct_cd = g.Sl_a
										 AND G.PRT_TYPE = 'D'
									UNION ALL
								  SELECT   d.gl_acct_cd,DECODE( trim(g.acct_type),'KAS','000000',d.sl_acct_cd) sl_acct_cd,
											  'SENDIRI' milik, 
												(DECODE(d.db_cr_flg,'D',NVL(d.curr_val,0),0) - DECODE(d.db_cr_flg,'C',NVL(d.curr_val,0),0)) trx_amt
									FROM T_ACCOUNT_LEDGER d, MST_MAP_MKBD m,  MST_GL_ACCOUNT g
									WHERE d.doc_date BETWEEN v_begin_date AND v_end_date
									AND d.approved_sts <> 'C' AND d.approved_sts <> 'E' 			
									AND   d.gl_acct_cd   = m.GL_a
									AND   d.Gl_acct_cd   = G.GL_a
										 AND D.Sl_acct_cd = g.Sl_a
									AND m.source = 'VD56'
									AND m.MKBD_CD BETWEEN 18 AND 19
									AND v_end_date  BETWEEN m.ver_bgn_dt AND m.ver_end_dt
										AND G.PRT_TYPE = 'D')) 
									GROUP BY gl_acct_cd,sl_acct_cd, milik
								  HAVING SUM(amt) > 0
								  ORDER BY gl_acct_cd,sl_acct_cd  ) t,
			  ( SELECT a.gl_acct_cd, a.sl_acct_cd, a.bank_acct_cd, b.RTGS_CD||' '||trim(b.short_bank_name) bank_name, 
			  		   A.CURR_CD, NVL(E.RATE,1) RATE 
			  FROM( SELECT B.CURR_CD, RATE
			  		FROM( SELECT CURR_CD, MAX(EXCH_DT) MAXDT
						  FROM T_EXCH_RATE
						  WHERE EXCH_DT <= v_end_date
						  GROUP BY CURR_CD) A,
						 T_EXCH_RATE B
					WHERE A.CURR_CD= B.CURR_CD
					AND A.MAXDT = B.EXCH_DT ) E,
			     MST_BANK_MASTER b,
			 MST_BANK_ACCT a
			 WHERE a.bank_CD = b.bank_cd
			 AND A.CURR_CD = E.CURR_CD(+)) m     
		WHERE  t.sl_acct_cd = m.sl_acct_cd (+)
		AND t.gl_acct_cd = m.gl_acct_cd (+)
		UNION ALL
  		 SELECT '@@@@'  GL_ACCT_cD, '-', T.MILIK, m.BANK_ACCT_CD, M.BANK_NAME,
		 T.SUM_AMT, 'IDR' currency, T.SUM_AMT   
		 FROM(
		  SELECT  bank_cd, milik, SUM(amt) sum_amt
				FROM(  SELECT bank_cd,  milik, client_cd,  amt
						 FROM(     SELECT  b.CLIENT_cd, NVL(a.bank_cd,'KSEI') bank_cd,
												DECODE(m.mkbd_cd, 13,'NSBH UMUM','NASABAH') milik, 
											 DEBIT - CREDIT amt
									FROM T_FUND_BAL b, MST_MAP_MKBD m, MST_CLIENT_FLACCT a
									WHERE b.BAL_DT = v_begin_date
									  AND   b.acct_cd   = TRIM(m.GL_a)
									  AND m.source = 'VD56'
									  AND m.MKBD_CD  BETWEEN 10 AND 12
									  AND v_end_date  BETWEEN m.ver_bgn_dt AND m.ver_end_dt
                             AND b.client_cd = a.client_cd(+)
									  AND b.BAL_DT BETWEEN a.from_Dt AND a.to_dt	
									UNION ALL
								  SELECT   d.CLIENT_cd, NVL(a.bank_cd,'KSEI') bank_cd,
								  'NASABAH' milik, 
									DEBIT -CREDIT  trx_amt
									FROM T_FUND_MOVEMENT h, T_FUND_LEDGER d, MST_MAP_MKBD m, MST_CLIENT_FLACCT a
									WHERE h.doc_date BETWEEN v_begin_date AND v_end_date
									AND h.approved_sts <> 'C' AND h.approved_sts <> 'E' 			
                           			AND h.doc_num = d.doc_num
									AND   d.ACCT_cd   = TRIM(m.GL_a)
									AND m.source = 'VD56'
								   AND m.MKBD_CD BETWEEN 10 AND 12
									AND v_end_date  BETWEEN m.ver_bgn_dt AND m.ver_end_dt
                           			AND h.client_cd = a.client_cd(+)
									AND h.fund_bank_cd = NVL(a.bank_cd, h.fund_bank_cd)
								UNION ALL
								  SELECT   d.CLIENT_cd, p.ipo_bank_cd bank_cd, 
								  'NSBH UMUM' milik, 
									DEBIT -CREDIT  trx_amt 
									FROM T_FUND_MOVEMENT h, T_FUND_LEDGER d, MST_MAP_MKBD m, T_PEE p 
									WHERE h.doc_date BETWEEN p.offer_dt_fr AND p.distrib_dt_to 
									AND h.approved_sts = 'A' 
                           			AND h.doc_num = d.doc_num 
									AND   d.ACCT_cd   = TRIM(m.GL_a)
									AND  h.sl_acct_cd = p.stk_cd
									AND m.source = 'VD56' 
								   AND m.MKBD_CD = 13 
									AND v_end_date  BETWEEN m.ver_bgn_dt AND m.ver_end_dt 
								UNION ALL
								  SELECT   d.CLIENT_cd, 'ZKSEI' bank_cd,
								  'NASABAH' milik, 
									DEBIT -CREDIT  trx_amt
									FROM T_FUND_KSEI_LEDGER d, MST_MAP_MKBD m
									WHERE d.doc_date <= v_end_date
									AND d.approved_sts <> 'C' AND d.approved_sts <> 'E' 			
									AND   d.ACCT_cd   = TRIM(m.GL_a)
									AND m.source = 'VD56'
								   AND m.MKBD_CD = 10 
									AND v_end_date  BETWEEN m.ver_bgn_dt AND m.ver_end_dt  )
								  ) GROUP BY bank_cD, milik
								  HAVING ( SUM(amt) <> 0 OR milik <> 'NSBH UMUM')
								   ) t,
			  		( SELECT    bank_cd, SWIFT_CD||'-'||bank_name AS bank_name, '-' bank_acct_cd  
					  FROM   MST_FUND_BANK 
					  UNION 
					  SELECT 'ZKSEI',swift_cd||'-KSEI', 'SUB REK KSEI' bank_acct_cd 
					  FROM   MST_FUND_BANK 
					  WHERE default_flg = 'Y'
					  UNION	
					  SELECT ipo_bank_cd, SWIFT_CD||'-'||bank_name AS bank_name, ipo_bank_acct AS bank_acct_cd 
					  FROM t_pee, 
					    ( SELECT ip_bank_cd,  bank_name, SUBSTR(bi_code,1,3) swift_cd
						   FROM mst_bank_bi) p
					  WHERE v_end_date BETWEEN offer_dt_fr AND distrib_dt_to
					  AND ipo_bank_cd= ip_bank_cd
					  ) m 
				WHERE  t.bank_cd = m.bank_cd (+))
UNION ALL
SELECT 24 mkbd_cd,
0 AS norut, 
  NULL bank_name,
   0 c1, 0 c2, 0  c3,  0 c4,
    NULL milik,
   NULL bank_acct_cd,  NULL currency  
FROM dual); 
EXCEPTION
WHEN OTHERS THEN
	 		v_error_code := -3;
			v_error_msg :=  SUBSTR('Insert to LAP_MKBD_VD56 '||SQLERRM,1,200);
			RAISE v_err;
END;
	

	FOR rec IN csr_subtot_grp1  LOOP
			BEGIN
			UPDATE insistpro_rpt.LAP_MKBD_VD56
			SET c1 = NVL(rec.sum_amt,0)
			WHERE  update_date = p_update_date
			AND update_seq = p_update_seq
			and mkbd_cd = rec.grp1;
			EXCEPTION
			WHEN OTHERS THEN
	 		v_error_code := -4;
			v_error_msg :=  SUBSTR('Update LAP_MKBD_VD56 line : '||rec.grp1||SQLERRM,1,200);
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

END Sp_Mkbd_Vd56;
