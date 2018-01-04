create or replace 
PROCEDURE Spr_Lk_Konsol(
    p_update_date date,
    p_update_seq number,
	   P_end_DATE DATE,
	   P_USER_ID VARCHAR2,
	--   P_RND_NUM OUT NUMBER,
	   P_ERROR_CODE OUT NUMBER,
	   P_ERROR_MSG OUT VARCHAR2)
 IS

--   P_report_type          VARCHAR2,
-- 	   P_GL_A            VARCHAR2,
-- 	   P_SL_A         VARCHAR2,
-- 	   P_LK_ACCT VARCHAR2,
-- 	   P_ENTITY    VARCHAR2,
/******************************************************************************
   NAME:       SPR_LK_KONSOL
   PURPOSE:

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        07/03/2014          1. Created this procedure.

   NOTES:



******************************************************************************/

v_begin_date DATE;
v_end_date DATE;
v_begin_prev DATE;
--v_rnd_num NUMBER(10);

CURSOR csr_rep  IS
SELECT f.line_num, f.line_type||DECODE(f.line_type,'H',TO_CHAR(f.line_num),'') col1,f.lk_acct AS col2,
	     ROUND(NVL(a.col3 + f.colx,0),0) col3,	 col4, DECODE(f.col5,NULL,DECODE(NVL(a.col5,0),0,NULL,ROUND(a.col5,0)),f.col5) col5,
		  f.col6, f.col7, NULL col8, NULL col9
		FROM
				(SELECT lk_acct, SUM(DECODE(col_num,3,amt,0) * DECODE(SUBSTR(lk_acct,1,1),'2',-1,'3',-1,1))  AS col3,
								   SUM(DECODE(col_num,5, amt,0)) AS col5
				FROM(
					SELECT  m.lk_acct, NVL(m.col_num,3) col_num,
							 (NVL(b.deb_obal,0) - NVL(b.cre_obal,0)) * NVL(SIGN,1) amt
					FROM T_DAY_TRS b, MST_MAP_LK m
					WHERE b.trs_dt =  V_begin_date
					  AND   b.gl_acct_cd   = m.GL_a
					  AND    (b.sl_acct_cd = m.sl_a OR m.sl_a = '#')
					  AND m.entity_cd = 'YJ'
					  AND  V_end_date  BETWEEN m.ver_bgn_dt AND m.ver_end_dt
					  AND m.approved_Stat = 'A'
					UNION ALL
				  SELECT   m.lk_acct,  NVL(m.col_num,3) col_num,
								DECODE(d.db_cr_flg,'D',1,-1) * d.curr_val  * NVL(SIGN,1)  trx_amt
					FROM T_ACCOUNT_LEDGER d, MST_MAP_LK m
					WHERE d.doc_date BETWEEN  V_begin_date AND  V_end_date
					AND d.approved_sts = 'A'
					AND   d.gl_acct_cd   = m.GL_a
					AND    (d.sl_acct_cd = m.sl_a OR m.sl_a = '#')
					AND m.entity_cd = 'YJ'
					AND  V_end_date  BETWEEN m.ver_bgn_dt AND m.ver_end_dt
					  AND m.approved_Stat = 'A'
					UNION ALL
					SELECT  m.lk_acct, NVL(m.col_num,3) col_num,
							 (NVL(b.deb_obal,0) - NVL(b.cre_obal,0)) * NVL(SIGN,1) amt
					FROM syn_lim_T_DAY_TRS b, MST_MAP_LK m
					WHERE b.trs_dt =  V_begin_date
					  AND   b.gl_acct_cd   = m.GL_a
					  AND    (b.sl_acct_cd = m.sl_a OR m.sl_a = '#')
					  AND m.entity_cd = 'LIM'
					  AND  V_end_date  BETWEEN m.ver_bgn_dt AND m.ver_end_dt
					  AND m.approved_Stat = 'A'
					UNION ALL
				  SELECT   m.lk_acct,  NVL(m.col_num,3) col_num,
								DECODE(d.db_cr_flg,'D',1,-1) * d.curr_val  * NVL(SIGN,1)  trx_amt
					FROM syn_lim_T_ACCOUNT_LEDGER d, MST_MAP_LK m
					WHERE d.doc_date BETWEEN  V_begin_date AND  V_end_date
					AND d.approved_sts = 'A'
					AND   d.gl_acct_cd   = m.GL_a
					AND    (d.sl_acct_cd = m.sl_a OR m.sl_a = '#')
					AND m.entity_cd = 'LIM'
					AND  V_end_date  BETWEEN m.ver_bgn_dt AND m.ver_end_dt
					  AND m.approved_Stat = 'A'
					UNION ALL
				  SELECT   m.lk_acct,  3 col_num,
								DECODE(d.db_cr_flg,'D',1,-1) * d.curr_val  * NVL(SIGN,1)  trx_amt
					FROM T_CONSOL_JRN d, MST_MAP_LK m
					WHERE d.doc_date BETWEEN  V_begin_date AND  V_end_date
					AND d.approved_sts = 'A'
					AND   d.gl_acct_cd   = m.GL_a
					AND    (d.sl_acct_cd = m.sl_a OR m.sl_a = '#')
					AND m.entity_cd = 'YJ'
					AND  V_end_date  BETWEEN m.ver_bgn_dt AND m.ver_end_dt
					  AND m.approved_Stat = 'A'
					) GROUP BY lk_acct
					) a,
					( SELECT line_num,col1 AS line_type, col2 AS lk_acct,
					  		 			NVL(colx,0) colx,
										 col4,
					                      col5,
										  col6, col7
					FROM INSISTPRO.T_LK_REP
					WHERE report_date =  V_end_date
						  AND col1 = 'D') f
				WHERE f.lk_acct = a.lk_acct(+)
				UNION ALL
				SELECT f.line_num, f.line_type||DECODE(f.line_type,'H',TO_CHAR(f.line_num),'') col1,
				                  col2, NULL col3,  NULL col4, NULL col5, NULL col6, NULL col7, NULL col8, NULL col9
				FROM INSISTPRO.T_LK_REP,
				(
				SELECT line_num, line_type, lk_acct
					 FROM FORM_LK
					 WHERE line_type = 'H'
					 AND  V_end_date  BETWEEN ver_bgn_dt AND ver_end_dt
					 ) f
				WHERE report_date =  V_end_date
				AND INSISTPRO.T_LK_REP.line_num = f.line_num
					ORDER BY 1;


CURSOR csr_Step IS
SELECT DISTINCT 1 flow, step1 AS step
FROM FORM_LK
WHERE v_end_date BETWEEN ver_bgn_dt AND ver_end_dt
AND line_type = 'D'
AND step1 IS NOT NULL
UNION
SELECT DISTINCT 2 flow, step2
FROM FORM_LK
WHERE v_end_date BETWEEN ver_bgn_dt AND ver_end_dt
AND line_type = 'D'
AND step2 IS NOT NULL
ORDER BY 2;

CURSOR csr_sum1( a_flow NUMBER, a_step FORM_LK.step1%TYPE) IS
SELECT suma, SUM(col3* signa) sum_amt
FROM
(SELECT col2, col3
FROM LAP_LK_KONSOL r
WHERE update_date = p_update_date and update_seq=p_update_seq--rnd_num = v_rnd_num
AND user_id = p_user_id) r,
(
 SELECT lk_acct, suma,  signa, stepa
FROM(
 SELECT lk_acct, DECODE(a_flow,1,sum1,sum2) suma,
 DECODE(a_flow,1,sign1,sign2) signa,
 DECODE(a_flow,1,step1,step2) stepa
 FROM FORM_LK
WHERE v_end_date BETWEEN ver_bgn_dt AND ver_end_dt
AND line_type = 'D')
WHERE stepa = a_step
AND suma IS NOT NULL
) f
WHERE r.col2 = f.lk_acct
GROUP BY suma;

CURSOR csr_sum2 IS
SELECT sum2, SUM(col3* sign2) sum_amt
FROM
(SELECT col2, col3
FROM LAP_LK_KONSOL r
WHERE update_date = p_update_date and update_seq=p_update_seq--rnd_num = v_rnd_num
AND user_id = p_user_id) r,
( SELECT lk_acct, sum2, sign2
FROM FORM_LK
WHERE v_end_date BETWEEN ver_bgn_dt AND ver_end_dt
AND sum2 IS NOT NULL) f
WHERE r.col2 = f.lk_acct
GROUP BY sum2;

CURSOR csr_1421_2421 IS
SELECT lk_acct, SUM(amt) amt
FROM(
SELECT DECODE(SIGN(amt),-1,'20420','10720') lk_acct, ABS(amt) amt
					FROM( SELECT  SUM(amt) amt
							FROM(	SELECT  (b.deb_obal -b.cre_obal) amt
									FROM T_DAY_TRS b, v_gl_acct_type a
									WHERE b.trs_dt = v_begin_prev
									AND a.acct_type IN (  'CLIE')
									--AND b.sl_acct_cd = 'MANO001T'
									AND   b.gl_acct_cd = a.gl_A
									UNION ALL
									SELECT    DECODE(d.db_cr_flg,'D',1,-1) * d.curr_val mvmt
									FROM T_ACCOUNT_LEDGER d, v_gl_acct_type a
									WHERE d.doc_date BETWEEN v_begin_prev AND v_end_date
									AND d.approved_sts <> 'C' AND d.approved_sts <> 'E'
									AND d.due_date  <= v_end_date
									AND a.acct_type IN (  'CLIE')
									--AND d.sl_acct_cd = 'MANO001T'
									AND   d.gl_acct_cd = a.gl_A ))
				   UNION ALL
				   SELECT 	 lk_acct,
				   DECODE( lk_acct,'10720',DECODE(SIGN(trx_amt),-1,0, trx_amt)+ NVL(buy_trx,0), DECODE( SIGN(trx_amt),-1, ABS(trx_amt),0)+ NVL(sell_trx,0)) net_trx
--				   SELECT 	due_date, sl_acct_cd, lk_acct, trx_amt, buy_trx, sell_trx,
--				   DECODE( lk_acct,'10720',DECODE(SIGN(trx_amt),-1,0, trx_amt)+ NVL(buy_trx,0), DECODE( SIGN(trx_amt),-1, ABS(trx_amt),0)+ NVL(sell_trx,0)) net_trx
				   FROM(
				    SELECT   due_date, sl_acct_cd,
										SUM(DECODE(t.mrkt_type,'RG',DECODE(d.db_cr_flg,'D',1,-1) * curr_val,0)) trx_amt,
										SUM(DECODE(d.db_cr_flg,'D',DECODE(t.mrkt_type,'RG',0,1) * curr_val,0)) buy_trx,
										SUM(DECODE(d.db_cr_flg,'C',DECODE(t.mrkt_type,'RG',0,1) * curr_val,0)) sell_trx
							  FROM T_ACCOUNT_LEDGER d, v_gl_acct_type a,
									( SELECT DECODE(SUBSTR(contr_num,6,1),'I',SUBSTR(contr_num,1,6)||'0'||SUBSTR(contr_num,8,7), contr_num) AS contr_num,
											 DECODE(SUBSTR(contr_num,6,1),'I',SUBSTR(contr_num,5,2),mrkt_type) mrkt_type
						              FROM 	T_CONTRACTS
										  WHERE  contr_dt BETWEEN v_begin_date - 30  AND v_end_date
										  AND contr_stat <>'C'
										  									--AND client_cd = 'EBET001R'
										  AND record_source <> 'IB'
										  UNION ALL
								  SELECT  doc_num AS CONTR_NUM, 'RG' AS MRKT_TYPE
								  FROM T_BOND_TRX
								 WHERE  trx_date BETWEEN V_begin_date - 30     AND V_end_date
								  AND approved_sts = 'A'
								  AND value_dt > V_end_date
										  ) t
									  WHERE d.doc_Date BETWEEN v_begin_date - 30 AND v_end_date
									  AND d.due_Date > v_end_date
									  AND d.approved_sts <> 'C' AND d.approved_sts <> 'E'
									  AND a.acct_type IN (  'CLIE')
									  AND   d.gl_acct_cd = a.gl_A
									  									--AND d.sl_acct_cd = 'EBET001R'
									  AND d.xn_doc_num = t.CONTR_NUM
						 GROUP BY   due_date,sl_acct_cd ) a,
						 ( SELECT '10720' lk_acct
						   FROM dual
						   UNION ALL
						   SELECT '20420'
						   FROM dual) b
						   UNION ALL
				  SELECT  '10720' lk_acct,  SUM(curr_val)
				  FROM T_ACCOUNT_LEDGER d
				  WHERE doc_Date BETWEEN v_begin_date - 30 AND v_end_date
				  AND due_Date > v_end_date
				  AND approved_sts <> 'C' AND approved_sts <> 'E'
				  AND REVERSAL_JUR = 'N'
				  AND record_source = 'GL'
				  AND   xn_doc_num LIKE '%GLAMFE%'
				  AND tal_id = 1)
						 GROUP BY lk_acct;

CURSOR csr_1422_1424 IS
SELECT  lk_acct, 	SUM (ABS(end_bal)) amt
						FROM(
							SELECT DECODE(SIGN(SUM(amt)),1,'10720','20420') lk_acct,  client_cd, gl_acct_cd,   SUM(amt ) end_bal
								FROM(  SELECT T_ACCOUNT_LEDGER.gl_Acct_cd, TRIM(T_ACCOUNT_LEDGER.sl_acct_cd)  client_cd,
												DECODE(T_ACCOUNT_LEDGER.db_cr_flg, 'D', 1, -1) * curr_val amt
										 FROM T_ACCOUNT_LEDGER, v_gl_acct_type a
										WHERE doc_date BETWEEN v_begin_date AND v_end_date
										 AND  approved_sts  = 'A'
										 AND  T_ACCOUNT_LEDGER.gl_acct_cd   = a.gl_A
										 AND a.acct_type IN ( 'T3','T7')
										UNION ALL
										 SELECT gl_acct_cd, TRIM(T_DAY_TRS.sl_acct_cd),
											deb_obal - cre_obal amt
											 FROM T_DAY_TRS, v_gl_acct_type a
											WHERE  T_DAY_TRS.gl_acct_cd   = a.gl_A
											  AND  T_DAY_TRS.trs_dt = v_begin_date
											  AND a.acct_type  IN ( 'T3','T7')
											  )
								GROUP BY client_cd, gl_acct_cd
								) n
								 GROUP BY lk_acct;




 v_curr4200    T_ACCOUNT_LEDGER.curr_val%TYPE;
  v_labarugi_lim T_ACCOUNT_LEDGER.curr_val%TYPE;
   v_col3   T_ACCOUNT_LEDGER.curr_val%TYPE;
   v_kpei_debit      T_ACCOUNT_LEDGER.curr_val%TYPE;
   v_kpei_credit        T_ACCOUNT_LEDGER.curr_val%TYPE;
 v_all 		   CHAR(1);
 v_cnt NUMBER;

v_err EXCEPTION;
v_error_code NUMBER;
v_error_msg VARCHAR2(200);
BEGIN

	 BEGIN
	 SELECT COUNT(1) INTO v_cnt
	 FROM INSISTPRO.T_LK_REP
	 WHERE report_date = p_end_date;
	 EXCEPTION
	 WHEN NO_DATA_FOUND THEN
	 v_error_code := -2001;
						 v_error_msg := SUBSTR('Belum create New Report '||TO_CHAR(p_end_date,'dd/mm/yyyy')||SQLERRM,1,200);
						 RAISE v_err;
	 END;

	 IF v_cnt = 0 THEN
	  v_error_code := -2001;
						 v_error_msg := SUBSTR('Belum create New Report '||TO_CHAR(p_end_date,'dd/mm/yyyy')||SQLERRM,1,200);
						 RAISE v_err;
	 END IF;

   v_end_date := p_end_date;
   --v_rnd_num := dbms_random.random;
  -- P_RND_NUM := v_rnd_num;

   v_begin_date := p_end_date - TO_NUMBER( TO_CHAR(p_end_date,'dd')) + 1;
   v_begin_prev := v_begin_date;




  DELETE FROM LAP_LK_KONSOL
  --WHERE rnd_num = v_rnd_num
  WHERE  user_id = p_user_id;

  FOR rec IN csr_rep LOOP

	  	  INSERT INTO LAP_LK_KONSOL (
			   RND_NUM, USER_ID, REPORT_DATE, LINE_NUM,
			   COL1, COL2, COL3,
			    col4, COL5, COL6,
			   COL7, COL8, COL9,
			   CRE_DT,APPROVED_STAT, APPROVED_BY, APPROVED_DT,update_date,update_seq)
			VALUES ( null, p_user_id, p_end_date, rec.LINE_NUM,
			   rec.COL1, rec.COL2, rec.COL3,
			    rec.col4, rec.COL5, rec.COL6,
			   rec.COL7, rec.COL8, rec.COL9,SYSDATE,'E',NULL,NULL,p_update_date,p_update_seq);

  END LOOP;
   v_begin_prev := v_begin_date;



						  FOR rec IN csr_1421_2421 LOOP

						  	  	  	 UPDATE lap_lk_konsol
									 SET col3 = NVL(col3,0) + rec.amt
									 WHERE  update_date = p_update_date and update_seq=p_update_seq--rnd_num = v_rnd_num
									 AND user_id = p_user_id
									 AND col2 = rec.lk_acct;
						  END LOOP;

						   v_begin_prev := v_begin_date;

						  FOR rec IN csr_1422_1424 LOOP

						  	  	  	 UPDATE lap_lk_konsol
									 SET col3 = NVL(col3,0) + rec.amt
									 WHERE update_date = p_update_date and update_seq=p_update_seq--rnd_num = v_rnd_num
									 AND user_id = p_user_id
									 AND col2 = rec.lk_acct;
						  END LOOP;


					SELECT SUM(kpei_debit)  kpei_debit, SUM(kpei_credit)  kpei_credit
					      INTO v_kpei_debit, v_kpei_credit
			         FROM(
					SELECT  (DECODE(SIGN(amt),-1,0,amt)) kpei_debit,
					                    (DECODE(SIGN(amt),-1,ABS(amt),0)) kpei_credit
					FROM(
					 SELECT  SUM(beg_bal + mvmt) amt
							FROM(	SELECT (b.deb_obal -b.cre_obal) beg_bal, 0 mvmt
									FROM T_DAY_TRS b, v_gl_acct_type a
									WHERE b.trs_dt = v_begin_prev
									AND a.acct_type IN ( 'KPEI')
									AND   b.gl_acct_cd = a.gl_A
									UNION ALL
									SELECT  0 beg_bal,
										  DECODE(d.db_cr_flg,'D',1,-1) * d.curr_val mvmt
									FROM T_ACCOUNT_LEDGER d, v_gl_acct_type a
									WHERE d.doc_date BETWEEN v_begin_prev AND v_end_date
									AND d.approved_sts <> 'C' AND d.approved_sts <> 'E'
									AND d.due_date  <= v_end_date
									AND a.acct_type IN ( 'KPEI')
									AND   d.gl_acct_cd = a.gl_A ))
				   UNION ALL
				   SELECT 	 DECODE(SIGN(net_trx),-1,0,net_trx) kpei_debit,
					                    DECODE(SIGN(net_trx),-1,ABS(net_trx),0) kpei_credit
				   FROM(
				   SELECT   due_date,
										30 mkbd_cd,
										SUM(DECODE(d.db_cr_flg,'D',1,-1) * curr_val) net_trx
							  FROM T_ACCOUNT_LEDGER d, v_gl_acct_type a
									  WHERE d.doc_Date BETWEEN v_begin_date - 30 AND v_end_date
									  AND d.due_Date > v_end_date
									  AND d.approved_sts <> 'C' AND d.approved_sts <> 'E'
									  AND REVERSAL_JUR = 'N'
									  AND a.acct_type IN ( 'KPEI')
										AND   d.gl_acct_cd = a.gl_A
										AND d.record_source = 'CG'
						 GROUP BY   due_date
						 ) );


						UPDATE LAP_LK_KONSOL
						  SET col3 = NVL(col3,0) + v_kpei_debit
						 WHERE update_date = p_update_date and update_seq=p_update_seq--rnd_num = v_rnd_num
						 AND user_id = p_user_id
						  AND col2 IN ('10600');


						UPDATE LAP_LK_KONSOL
						  SET col3 = NVL(col3,0) + v_kpei_credit
						 WHERE update_date = p_update_date and update_seq=p_update_seq--rnd_num = v_rnd_num
						 AND user_id = p_user_id
						  AND col2 IN ('20300');

						  SELECT ROUND(SUM(curr4200), 0)
						  INTO v_curr4200
						FROM
						 ( SELECT 'YJ' entity, SUM(DECODE(SUBSTR(t.gl_acct_cd,1,1),'6',DECODE(t.db_cr_flg,'C',t.curr_val,-1 * t.curr_val),0))
							- SUM(DECODE(SUBSTR(t.gl_acct_cd,1,1),'5',DECODE(t.db_cr_flg,'D',t.curr_val,-1 * t.curr_val),0)) 	curr4200
							FROM T_ACCOUNT_LEDGER t
							WHERE t.doc_date BETWEEN v_begin_date AND v_end_date
							AND  t.approved_sts = 'A'
							UNION ALL
							SELECT 'LIM' entity, (SUM(DECODE(SUBSTR(t.gl_acct_cd,1,1),'6',DECODE(t.db_cr_flg,'C',t.curr_val,-1 * t.curr_val),0))
							- SUM(DECODE(SUBSTR(t.gl_acct_cd,1,1),'5',DECODE(t.db_cr_flg,'D',t.curr_val,-1 * t.curr_val),0)) ) *  0.9998
							FROM syn_lim_T_ACCOUNT_LEDGER t
							WHERE t.doc_date BETWEEN v_begin_date AND v_end_date
							AND  t.approved_sts = 'A'
							UNION ALL
							SELECT 'LIM' entity,  (cre_obal - deb_obal) * 0.9998 bal4200
							FROM syn_lim_T_DAY_TRS
							WHERE trs_dt = v_begin_date
							AND gl_acct_cd = '4200'
							);

-- 						  SELECT col3 INTO v_col3
-- 						  FROM LAP_LK_KONSOL
-- 						  WHERE col2 = '30620'
-- 						  AND user_id = p_user_id;




						  UPDATE LAP_LK_KONSOL
						  SET col3 = NVL(col3,0) + v_curr4200
						 WHERE update_date = p_update_date and update_seq=p_update_seq--rnd_num = v_rnd_num
						 AND user_id = p_user_id
						  AND col2 IN ('30620'); -- labarugi YJ

-- 						  UPDATE LAP_LK_KONSOL
-- 						  SET col3 = NVL(col3,0) +  v_labarugi_lim
-- 						 WHERE rnd_num = v_rnd_num
-- 						 AND user_id = p_user_id
-- 						  AND col2 IN ('48300','49300');
						     --  48200 dari jurnal consol
							 -- tahapannya
							 -- step 6 copy 48200 ke 49200
							 -- step 7  47000 - 49200 dimasukkan ke 48100
							 -- step 8  48100 dimasukkan ke 49100
							 -- step 9  di field step2 : jumlahkan 48100, 48200 ke 48300
							 --                                             jumlahkan 49100, 49200 ke 49300


							 v_begin_prev := v_begin_date;

				FOR rstep IN csr_step LOOP

							   FOR rec IN csr_sum1(rstep.flow,  rstep.step)  LOOP

							  	  	  	 UPDATE LAP_LK_KONSOL
										 SET col3 = rec.sum_amt
										 WHERE update_date = p_update_date and update_seq=p_update_seq--rnd_num = v_rnd_num
										 AND user_id = p_user_id
										 AND col2 = rec.suma;
							  END LOOP;


						   v_begin_prev := v_begin_date;

				END LOOP;

 p_error_code := 1;
	   p_error_msg := '';
	   COMMIT;

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

END Spr_Lk_Konsol;