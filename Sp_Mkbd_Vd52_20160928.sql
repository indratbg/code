create or replace PROCEDURE Sp_Mkbd_Vd52_20160928(
p_update_date DATE,
p_update_seq NUMBER,
p_mkbd_date DATE,
p_price_date DATE,
p_user_id       LAP_MKBD_VD52.user_id%TYPE,
 p_error_code			OUT			NUMBER,
p_error_msg				OUT			VARCHAR2
) IS
/******************************************************************************
   NAME:       SP_MKBD_VD52
   PURPOSE:

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        02/02/2015          1. Created this procedure.

   NOTES:
28sep 2016   - utk baris 141  utang Perusahaan Efek Lain (broker) - transaksi jual
       dirubah dgn netting antara jurnal broker jual dan beli (YJ/MU :1453 dan 2453)
       broker yg sama , due date yg sama
       account broker hrs dicabut dr MAP MKBD

******************************************************************************/

v_begin_date DATE;
v_end_date DATE;
v_begin_prev DATE;
v_cre_dt DATE:=SYSDATE;
v_brok_nettg_date DATE;
v_brok         ipnextg.mst_gla_trx.jur_type%TYPE;
v_brok_nettg_yn VARCHAR2(1);

CURSOR csr_subtot_grp1 IS
SELECT f.grp1, SUM(l.c1) sum_amt
FROM LAP_MKBD_VD52 l,
( SELECT mkbd_cd, description,
					grp1, grp2, grp3
		  FROM ipnextg.FORM_MKBD
		  WHERE source = 'VD52'
			AND mkbd_cd > 7
		  AND v_end_date  BETWEEN ver_bgn_dt AND ver_end_dt) f
WHERE update_date = p_update_date
AND update_seq = p_update_seq
AND TO_NUMBER( l.mkbd_cd) = f.mkbd_cd
AND f.grp1 IS NOT NULL
GROUP BY f.grp1;

CURSOR csr_subtot_grp2  IS
SELECT f.grp2, SUM(l.c1) sum_amt
FROM LAP_MKBD_VD52 l,
( SELECT mkbd_cd, description,
					grp1, grp2, grp3
		  FROM ipnextg.FORM_MKBD
		  WHERE source = 'VD52'
			AND mkbd_cd > 7
		  AND v_end_date  BETWEEN ver_bgn_dt AND ver_end_dt) f
WHERE update_date = p_update_date
AND update_seq = p_update_seq
AND TO_NUMBER(l.mkbd_cd) = f.mkbd_cd
AND f.grp2 IS NOT NULL
GROUP BY f.grp2;

v_err EXCEPTION;
v_error_code				NUMBER;
v_error_msg					VARCHAR2(200);
V_RANDOM_VALUE NUMBER(10);
BEGIN

	V_RANDOM_VALUE :=abs(dbms_random.random);
   v_end_date := p_mkbd_date;
   v_begin_date := TO_DATE('01'||TO_CHAR(p_mkbd_date,'/mm/yy'), 'dd/mm/yy');
   v_begin_prev := v_begin_date - 1;
   v_begin_prev := TO_DATE('01'||TO_CHAR(v_begin_prev,'/mm/yy'), 'dd/mm/yy');

    BEGIN
		    SELECT NVL( ddate1,p_mkbd_date + 1), NVL(dflg1,'N')  INTO v_brok_nettg_date, v_brok_nettg_yn
        FROM ipnextg.MST_SYS_PARAM
        WHERE param_id = 'F_BALSH'
        AND param_cd1 = 'BROKNETG';
   EXCEPTION
   WHEN NO_DATA_FOUND THEN
      v_brok  := 'X';
      v_brok_nettg_yn := 'N';
      v_brok_nettg_date  := p_mkbd_date + 1;
   END;

   IF v_brok_nettg_date > p_mkbd_date OR v_brok_nettg_yn = 'N' THEN
       v_brok  := 'X';
       ELSE
      v_brok  := 'BROK';
    END IF;


INSERT INTO TMP_VD52_MAP
SELECT  m.mkbd_cd,
							 (NVL(b.cre_obal,0) - NVL(b.deb_obal,0)) beg_bal,
							0 trx_amt, V_RANDOM_VALUE, p_user_id
					FROM ipnextg.T_DAY_TRS b, MST_MAP_MKBD m
					WHERE b.trs_dt = v_begin_date
					  AND   b.gl_acct_cd   = m.GL_a
					  AND m.source = 'VD52'
					  AND v_end_date  BETWEEN m.ver_bgn_dt AND m.ver_end_dt;

INSERT INTO TMP_vd52_map2
 SELECT   m.mkbd_cd,
								0 beg_bal,
								(DECODE(d.db_cr_flg,'C',NVL(d.curr_val,0),0) - DECODE(d.db_cr_flg,'D',NVL(d.curr_val,0),0)) trx_amt,
								 V_RANDOM_VALUE, p_user_id
					FROM ipnextg.T_ACCOUNT_LEDGER d, MST_MAP_MKBD m
					WHERE d.doc_date BETWEEN v_begin_date AND v_end_date
					AND d.approved_sts <> 'C' AND d.approved_sts <> 'E'
					AND   d.gl_acct_cd   = m.GL_a
					AND m.source = 'VD52'
					AND v_end_date  BETWEEN m.ver_bgn_dt AND m.ver_end_dt;

INSERT INTO TMP_vd52_map3
	SELECT 133 mkbd_cd, DECODE(SIGN(amt),-1,0,amt), 0, V_RANDOM_VALUE, p_user_id
					FROM( SELECT  SUM(beg_bal + mvmt) amt
						FROM( SELECT  (b.cre_obal -b.deb_obal) beg_bal, 0 mvmt
								FROM ipnextg.T_DAY_TRS b
								WHERE b.trs_dt = v_begin_prev
								AND   b.gl_acct_cd IN ( SELECT gl_a FROM ipnextg.MST_GLA_TRX WHERE JUR_TYPE IN ('CLIE'))
							  UNION ALL
							  SELECT  0 beg_bal,
									  DECODE(d.db_cr_flg,'C',1,-1) * d.curr_val mvmt
							  FROM ipnextg.T_ACCOUNT_LEDGER d
							  WHERE d.doc_date BETWEEN v_begin_prev AND v_end_date
								AND d.approved_sts <> 'C' AND d.approved_sts <> 'E'
								AND d.due_date  <= v_end_date
                AND   d.gl_acct_cd IN ( SELECT gl_a FROM ipnextg.MST_GLA_TRX WHERE JUR_TYPE IN ('CLIE')) ));

INSERT INTO TMP_VD52_CONTR
SELECT   due_date, sl_acct_cd,
                    133 mkbd_cd,
										SUM(DECODE(t.mrkt_type,'RG',DECODE(d.db_cr_flg,'C',1,-1) * curr_val,0)) net_trx,
										SUM(DECODE(t.mrkt_type,'RG',0,DECODE(d.db_cr_flg,'C',1,0) * curr_val)) sell_trx,
										 V_RANDOM_VALUE, p_user_id
							  FROM ipnextg.T_ACCOUNT_LEDGER d,
							  ( SELECT DECODE(SUBSTR(contr_num,6,1),'I',SUBSTR(contr_num,5,2),mrkt_type) mrkt_type,
									   DECODE(SUBSTR(contr_num,6,1),'I',SUBSTR(contr_num,1,6)||'0'||SUBSTR(contr_num,8,7), contr_num) AS contr_num
							    FROM ipnextg.T_CONTRACTS
								 WHERE contr_dt BETWEEN v_begin_date - 30  AND v_end_date
								  AND  contr_stat <>'C'
								  AND record_source <> 'IB'
 								UNION ALL
								  SELECT 'RG' AS MRKT_TYPE, doc_num AS CONTR_NUM
								  FROM ipnextg.T_BOND_TRX
								 WHERE  trx_date BETWEEN v_begin_date - 30     AND v_end_date
								  AND approved_sts = 'A'
								  AND value_dt >v_end_date
							   ) t
									  WHERE d.doc_Date BETWEEN v_begin_date - 30 AND v_end_date
									  AND d.due_Date > v_end_date
									  AND d.approved_sts <> 'C' AND d.approved_sts <> 'E'
									  AND d.reversal_jur = 'N'
                      AND   d.gl_acct_cd IN ( SELECT gl_a FROM ipnextg.MST_GLA_TRX WHERE JUR_TYPE IN ('CLIE'))
									  AND d.record_source = 'CG'
									  AND d.xn_doc_num = t.CONTR_NUM
						 GROUP BY   due_date,sl_acct_cd  ;

INSERT INTO TMP_VD52_BROK
	SELECT   mkbd_cd, DECODE(SIGN(amt),-1,0,amt), 0, V_RANDOM_VALUE, p_user_id
					FROM( SELECT   DECODE(JUR_TYPE,'KPEI', 129, 141) mkbd_cd,  SUM(bal_amt) amt
							FROM(	SELECT  JUR_TYPE, (b.cre_obal -b.deb_obal) bal_amt
									FROM ipnextg.T_DAY_TRS b,
									( SELECT gl_a, JUR_TYPE FROM ipnextg.MST_GLA_TRX WHERE JUR_TYPE IN ('KPEI',v_BROK)) g
									WHERE b.trs_dt =  v_begin_prev
                  	AND   b.gl_acct_cd    = g.gl_a
								  UNION ALL
								  SELECT  JUR_TYPE,
										  DECODE(d.db_cr_flg,'C',1,-1) * d.curr_val mvmt
								  FROM ipnextg.T_ACCOUNT_LEDGER d,
									( SELECT gl_a, JUR_TYPE FROM ipnextg.MST_GLA_TRX WHERE JUR_TYPE IN ('KPEI',v_BROK)) g
								  WHERE d.doc_date BETWEEN  v_begin_prev AND  v_end_date
									AND d.approved_sts = 'A'
									AND d.due_date  <=  v_end_date
                  AND   d.gl_acct_cd  = g.gl_a)
									GROUP BY jur_type
									);
INSERT INTO TMP_VD52_BROK2
	  SELECT 	mkbd_cd,  GREATEST(net_trx,0), 0, V_RANDOM_VALUE, p_user_id
							   FROM( SELECT   JUR_TYPE,  sl_Acct_Cd,  due_date,
										DECODE(JUR_TYPE,'KPEI', 129, 141) mkbd_cd,
										SUM(DECODE(d.db_cr_flg,'C',1,-1) * curr_val) net_trx
							  FROM ipnextg.T_ACCOUNT_LEDGER d,
							  ( SELECT gl_a, JUR_TYPE FROM ipnextg.MST_GLA_TRX WHERE JUR_TYPE IN ('KPEI',v_BROK) ) g
							  WHERE d.doc_Date BETWEEN  v_begin_date - 30 AND  v_end_date
							  AND d.due_Date > v_end_date
							  AND d.approved_sts  = 'A'
                AND d.reversal_jur = 'N'
                AND   d.gl_acct_cd = g.gl_a
							AND d.record_source = 'CG'
						 GROUP BY    JUR_TYPE, sl_Acct_Cd, due_date )
				  WHERE net_trx > 0;

   BEGIN
   INSERT INTO LAP_MKBD_VD52 (
   UPDATE_DATE, UPDATE_SEQ, MKBD_DATE,
   VD, MKBD_CD, DESCRIPTION,
   C1,user_id, approved_stat,CRE_DT, price_date)
SELECT  p_update_date update_date , p_update_seq update_seq , P_MKbd_date AS mkbd_date,
     'VD52' AS vd, LPAD(TO_CHAR(mk.mkbd_cd),3) mkbd_cd,  description,
				   NVL(curr_mon,0)  c1,p_user_id, 'E' approved_stat,V_CRE_DT, p_price_date
FROM(		SELECT mkbd_cd,
			       SUM(beg_bal + trx_amt) curr_mon
			FROM( SELECT * FROM TMP_VD52_MAP WHERE RAND_VALUE=V_RANDOM_VALUE AND USER_ID=p_user_id
					UNION ALL
				 SELECT * FROM TMP_vd52_map2 WHERE RAND_VALUE=V_RANDOM_VALUE AND USER_ID=p_user_id
					UNION ALL
				SELECT * FROM TMP_VD52_MAP3 WHERE RAND_VALUE=V_RANDOM_VALUE AND USER_ID=p_user_id
				  UNION ALL
				  SELECT 	mkbd_cd, 0 beg_bal,  GREATEST(net_trx,0) + sell_trx, V_RANDOM_VALUE, p_user_id
				   FROM( SELECT * FROM TMP_vd52_contr WHERE RAND_VALUE=V_RANDOM_VALUE AND USER_ID=p_user_id)
				  WHERE net_trx > 0 OR sell_trx >0
					UNION ALL
--28sep 2016 begin
          SELECT * FROM TMP_VD52_BROK WHERE RAND_VALUE=V_RANDOM_VALUE AND USER_ID=p_user_id
          UNION ALL
					SELECT * FROM TMP_VD52_BROK2	 WHERE RAND_VALUE=V_RANDOM_VALUE AND USER_ID=p_user_id
--28sep 2016 end
				  UNION ALL
					SELECT m.mkbd_cd, -1 * SUM(	n.end_bal), 0, V_RANDOM_VALUE, p_user_id
						FROM(	SELECT client_cd,   SUM(beg_bal + mvmt ) end_bal
								FROM(  SELECT TRIM(MST_CLIENT.client_cd)  client_cd, 0 beg_bal,
												DECODE(T_ACCOUNT_LEDGER.db_cr_flg, 'D', 1, -1) * NVL(T_ACCOUNT_LEDGER.curr_val, 0) mvmt
										 FROM ipnextg.T_ACCOUNT_LEDGER, ipnextg.MST_CLIENT
										WHERE     T_Account_Ledger.Doc_Date BETWEEN  V_Begin_Date AND V_End_Date
										 AND  T_ACCOUNT_LEDGER.gl_acct_cd    IN ( SELECT gl_a FROM ipnextg.MST_GLA_TRX WHERE JUR_TYPE IN ('T3'))
										 AND T_ACCOUNT_LEDGER.sl_acct_cd = MST_CLIENT.client_cd
										 AND  T_ACCOUNT_LEDGER.approved_sts  <> 'C'
										 AND  T_ACCOUNT_LEDGER.approved_sts  <> 'E'
										UNION ALL
										 SELECT TRIM(MST_CLIENT.client_cd),
												(NVL(T_DAY_TRS.deb_obal, 0) - NVL(T_DAY_TRS.cre_obal, 0)) beg_bal, 0 mvmt
											 FROM ipnextg.T_DAY_TRS, ipnextg.MST_CLIENT
											WHERE   T_DAY_TRS.trs_dt = v_begin_date
											AND  T_DAY_TRS.gl_acct_cd    IN ( SELECT gl_a FROM ipnextg.MST_GLA_TRX WHERE JUR_TYPE IN ('T3'))
											 AND  T_DAY_TRS.sl_acct_cd = MST_CLIENT.client_cd)
								GROUP BY client_cd
								HAVING SUM(beg_bal + mvmt ) < 0) n,
								( SELECT mkbd_cd, gl_a
								FROM MST_MAP_MKBD
								WHERE v_end_date BETWEEN ver_bgn_dt AND ver_end_dt
								AND gl_a = 'SKRE'
								AND  source = 'VD52') m
							GROUP BY m.mkbd_cd
				  UNION ALL
					SELECT 170 mkbd_cd, 0, SUM(  DECODE(t.db_cr_flg,'C',1,-1  ) *  t.curr_val) pl, V_RANDOM_VALUE, p_user_id
					FROM(  SELECT gl_acct_cd, db_cr_flg, curr_val
									FROM ipnextg.T_ACCOUNT_LEDGER
									WHERE doc_date BETWEEN v_begin_date AND v_end_date
									 AND approved_sts <> 'C' AND approved_sts <> 'E' )t,
								(   SELECT prm_cd_2 AS prefix, prm_desc JUR_TYPE
								FROM ipnextg.MST_PARAMETER
								WHERE prm_cd_1 = 'PLACCT')m
					WHERE t.gl_acct_cd LIKE prefix					)
		GROUP BY MKBD_CD		) X,
( SELECT mkbd_cd, description,texttab,vis1, vis2, vis3, vis4,
         grp1, grp2, grp3
  FROM ipnextg.FORM_MKBD
  WHERE source = 'VD52'
   AND mkbd_cd > 7) MK
WHERE mk.mkbd_cd = x.mkbd_cd(+);
EXCEPTION
WHEN OTHERS THEN
	 		v_error_code := -3;
			v_error_msg :=  SUBSTR('Insert to LAP_MKBD_VD52 '||SQLERRM,1,200);
			RAISE v_err;
END;


	FOR rec IN csr_subtot_grp1  LOOP
			BEGIN
			UPDATE LAP_MKBD_VD52
			SET c1 = rec.sum_amt
			WHERE update_date = p_update_date
			AND update_seq = p_update_seq
			 AND mkbd_cd = rec.grp1;
			EXCEPTION
			WHEN OTHERS THEN
			 		v_error_code := -4;
					v_error_msg :=  SUBSTR('Update to LAP_MKBD_VD52 '||rec.grp1||SQLERRM,1,200);
			RAISE v_err;
			END;
	END LOOP;

	FOR rec IN csr_subtot_grp2 LOOP
				BEGIN
			UPDATE LAP_MKBD_VD52
			SET C1 = Rec.Sum_Amt
          --approved_dt = sysdate
			WHERE update_date = p_update_date
			AND update_seq = p_update_seq
			 AND mkbd_cd = rec.grp2;
			EXCEPTION
			WHEN OTHERS THEN
			 		v_error_code := -4;
					v_error_msg :=  SUBSTR('Update to LAP_MKBD_VD52 '||rec.grp2||SQLERRM,1,200);
			RAISE v_err;
			END;
	END LOOP;

--DELETE TABLE TEMP
DELETE FROM TMP_VD52_BROK WHERE RAND_VALUE=V_RANDOM_VALUE AND USER_ID=P_USER_ID;
DELETE FROM TMP_VD52_BROK2 WHERE RAND_VALUE=V_RANDOM_VALUE AND USER_ID=P_USER_ID;
DELETE FROM TMP_VD52_CONTR WHERE RAND_VALUE=V_RANDOM_VALUE AND USER_ID=P_USER_ID;
DELETE FROM TMP_VD52_MAP WHERE RAND_VALUE=V_RANDOM_VALUE AND USER_ID=P_USER_ID;
DELETE FROM TMP_VD52_MAP2 WHERE RAND_VALUE=V_RANDOM_VALUE AND USER_ID=P_USER_ID;
DELETE FROM TMP_VD52_MAP3 WHERE RAND_VALUE=V_RANDOM_VALUE AND USER_ID=P_USER_ID; 

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
END Sp_Mkbd_Vd52_20160928;