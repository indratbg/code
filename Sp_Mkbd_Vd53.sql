create or replace 
PROCEDURE Sp_Mkbd_Vd53( 
p_update_date DATE,
p_update_seq NUMBER,
p_mkbd_date DATE,
p_price_date DATE,
p_user_id       insistpro_rpt.LAP_MKBD_VD51.user_id%TYPE,
 p_error_code			OUT			NUMBER,
p_error_msg				OUT			VARCHAR2
) IS

/******************************************************************************
   NAME:       SP_MKBD_VD53
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
--p_price_date date;



CURSOR csr_subtot_grp1 IS
SELECT f.grp1, SUM(l.c1) sum_amt
FROM insistpro_rpt. LAP_MKBD_VD53 l, 
( SELECT mkbd_cd, description,
					grp1, grp2, grp3
		  FROM FORM_MKBD
		  WHERE source = 'VD53'
			AND mkbd_cd > 7
		  AND v_end_date  BETWEEN ver_bgn_dt AND ver_end_dt
		 AND grp1 IS NOT NULL ) f
WHERE update_date = p_update_date
AND update_seq = p_update_seq
AND TO_NUMBER(l.mkbd_cd) = f.mkbd_cd
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
  INSERT INTO Insistpro_rpt.LAP_MKBD_VD53 (
   UPDATE_DATE, UPDATE_SEQ, MKBD_DATE, 
   VD, MKBD_CD, DESCRIPTION, 
   C1, persentase, user_id,approved_stat,CRE_DT, price_date) 
SELECT p_update_date update_date , p_update_seq update_seq , v_end_date AS mkbd_date,
     'VD53' AS vd,  LPAD(TO_CHAR(mk.mkbd_cd),2) mkbd_cd,  description,
				   NVL(curr_mon,0)  c1, 
       mk.persentase, p_user_id,'E' AS approved_stat, V_CRE_DT, p_price_date
FROM(		SELECT mkbd_cd,
			    SUM(beg_bal + trx_amt) curr_mon 
		  FROM( SELECT  m.mkbd_cd, 
							 (NVL(b.cre_obal,0) - NVL(b.deb_obal,0)) beg_bal,
							0 trx_amt
					FROM T_DAY_TRS b, MST_MAP_MKBD m
					WHERE b.trs_dt = v_begin_date
					  AND   b.gl_acct_cd   = m.GL_a
					  AND m.source = 'VD53'
					  AND v_end_date  BETWEEN m.ver_bgn_dt AND m.ver_end_dt
				UNION ALL
				  SELECT   m.mkbd_cd, 
								0 beg_bal,
								(DECODE(d.db_cr_flg,'C',NVL(d.curr_val,0),0) - DECODE(d.db_cr_flg,'D',NVL(d.curr_val,0),0)) trx_amt
					FROM T_ACCOUNT_LEDGER d, MST_MAP_MKBD m
					WHERE d.doc_date BETWEEN v_begin_date AND v_end_date
					AND d.approved_sts <> 'C' AND d.approved_sts <> 'E' 			
					AND   d.gl_acct_cd   = m.GL_a
					AND m.source = 'VD53'
					AND v_end_date  BETWEEN m.ver_bgn_dt AND m.ver_end_dt
				UNION ALL
				SELECT ASCII(mkbd_cd ) - 65 + 9 MKBD_CD, ranking, 0
				FROM insistpro_rpt. LAP_MKBD_VD510B
				WHERE update_date = p_update_date
						AND update_seq = p_update_seq
						AND mkbd_date = v_end_date
					    AND mkbd_cd IN ('A','B','C') 
				UNION ALL
				SELECT ASCII(mkbd_cd ) - 65 + 12 MKBD_CD, ranking, 0
				FROM insistpro_rpt. LAP_MKBD_VD510A
				WHERE update_date = p_update_date
						AND update_seq = p_update_seq
						AND mkbd_date = v_end_date
					    AND mkbd_cd IN ('A','B','C') 
				UNION ALL
					SELECT 15 mkbd_cd, 0, SUM(nilai_komitment - bank_garansi) * 0.25 AS penjaminan
							FROM T_PEE
							WHERE v_end_date BETWEEN eff_dt_fr  AND eff_dt_to
							AND approved_stat = 'A'
				UNION ALL		
					SELECT  16 mkbd_cd,  0,   
							SUM(DECODE(SIGN((0.5 * unsubscribe_qty * price)- (0.25 * (nilai_komitment - bank_garansi))),
						 -1,(0.5 * unsubscribe_qty * price),(0.25 * (nilai_komitment - bank_garansi)))) 
					FROM T_PEE
					WHERE v_end_date BETWEEN offer_dt_fr  AND offer_dt_to
					AND approved_stat = 'A'	
				UNION ALL		
					SELECT   17 mkbd_cd,  0, SUM(unsubscribe_qty * price)
					FROM T_PEE
					WHERE v_end_date BETWEEN allocate_dt  AND distrib_dt_fr
					AND approved_stat = 'A'
				UNION ALL		
					SELECT 19 mkbd_cd, 0,ROUND(SUM(nilai * 0.2 ),2) ranking
					FROM T_CORP_GUARANTEE
					WHERE v_end_date BETWEEN contract_dt AND end_contract_dt
					AND approved_stat = 'A'
				UNION ALL		
					SELECT 20 mkbd_cd,  0,	
					ROUND(SUM(DECODE(SIGN(NILAI - 150000000 - SUDAH_REAL ),1,NILAI - 150000000 - SUDAH_REAL,0) * 0.2),2) ranking
					FROM T_BELANJA_MODAL
					WHERE tgl_komitmen <=v_end_date
					AND nilai > sudah_real
					AND approved_stat = 'A'
				UNION ALL		
					SELECT 21 mkbd_cd,  0, 
					ROUND(SUM(rugi_unreal * 0.2),2) ranking
					FROM T_TRX_FOREIGN
					WHERE tgl_trx = v_end_date	 	
					AND approved_stat = 'A'
				UNION ALL
				SELECT ASCII(mkbd_cd ) - 65 + 23 MKBD_CD, ranking, 0
				FROM insistpro_rpt. LAP_MKBD_VD510C
				WHERE update_date = p_update_date
						AND update_seq = p_update_seq
						AND mkbd_date = v_end_date
					    AND mkbd_cd IN ('A','B','C','D') 
				UNION ALL
					SELECT 27 mkbd_cd, 0,
							SUM(DECODE(SIGN( (t.unit * n.nab_unit) - ( n.nab * m.risiko / 100)), 1, (t.unit * n.nab_unit) - ( n.nab * m.risiko / 100),0)) AS risiko
					FROM(  SELECT reks_cd, reks_name, reks_type, SUM(subs -redm) unit
								FROM T_REKS_TRX
								WHERE trx_date <= v_end_date
								  AND approved_STAT = 'A'
								GROUP BY  reks_cd, reks_name, reks_type
								HAVING SUM(subs -redm) > 0 ) t,
							(  SELECT reks_cd, nab_unit, nab
								FROM T_REKS_NAB 
								WHERE mkbd_dt = p_price_date
								  AND approved_STAT = 'A') n, 
							MST_REKS_TYPE m
					WHERE t.reks_cd = n.reks_cd
					AND t.reks_type = m.reks_type
				UNION ALL
				SELECT 28 MKBD_CD, lebih_client AS ranking, 0
				FROM insistpro_rpt. LAP_MKBD_VD510D
				WHERE update_date = p_update_date
						AND update_seq = p_update_seq
						AND mkbd_date = v_end_date
					    AND mkbd_cd IN ('A') 
				UNION ALL
				SELECT ASCII(mkbd_cd ) - 65 + 29   MKBD_CD, lebih_porto ranking, 0
				FROM insistpro_rpt. LAP_MKBD_VD510D
				WHERE update_date = p_update_date
						AND update_seq = p_update_seq
						AND mkbd_date = v_end_date
					    AND mkbd_cd IN ('A','B') 
					)
		GROUP BY MKBD_CD		) X,
( SELECT mkbd_cd, description,texttab,vis1, vis2, vis3,
         grp1, grp2, grp3, source, formulir AS Persentase
  FROM FORM_MKBD
  WHERE source IN ('VD53')
    AND mkbd_cd > 7) MK
WHERE mk.mkbd_cd = x.mkbd_cd(+)
ORDER BY mkbd_cd;
EXCEPTION
WHEN OTHERS THEN
	 		v_error_code := -3;
			v_error_msg :=  SUBSTR('Insert to LAP_MKBD_VD53 '||SQLERRM,1,200);
			RAISE v_err;
END;





	FOR rec IN csr_subtot_grp1  LOOP
			BEGIN
			UPDATE  insistpro_rpt.LAP_MKBD_VD53
			SET c1 = NVL(rec.sum_amt,0)
			WHERE  update_date = p_update_date
			AND update_seq = p_update_seq
			and mkbd_cd = rec.grp1;
		EXCEPTION
			WHEN OTHERS THEN
	 		v_error_code := -4;
			v_error_msg :=  SUBSTR('Update LAP_MKBD_VD53 line : '||rec.grp1||SQLERRM,1,200);
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

END Sp_Mkbd_Vd53;
