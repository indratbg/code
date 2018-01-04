create or replace 
PROCEDURE Sp_Mkbd_Vd57( 
p_update_date DATE,
p_update_seq NUMBER,
p_mkbd_date DATE,
p_price_date DATE,
p_user_id       insistpro_rpt.LAP_MKBD_VD51.user_id%TYPE,
p_error_code			OUT			NUMBER,
p_error_msg				OUT			VARCHAR2
) IS

/******************************************************************************
   NAME:       SP_MKBD_VD57
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
SELECT f.grp1, SUM(l.c1) sum_c1, SUM(l.c2) sum_c2, SUM(l.c3) sum_c3, SUM(l.c4) sum_c4 
FROM insistpro_rpt.LAP_MKBD_VD57 l, 
( SELECT mkbd_cd, description,
					grp1, grp2, grp3
		  FROM FORM_MKBD
		  WHERE source = 'VD57'
			AND mkbd_cd > 7
			AND grp1 IS NOT NULL
		  AND v_end_date  BETWEEN ver_bgn_dt AND ver_end_dt) f
WHERE update_date = p_update_date
AND update_seq = p_update_seq
AND l.mkbd_cd = f.mkbd_cd
GROUP BY f.grp1;

CURSOR csr_subtot_grp2  IS
SELECT f.grp2, SUM(l.c1) sum_c1, SUM(l.c2) sum_c2, SUM(l.c3) sum_c3, SUM(l.c4) sum_c4 
FROM insistpro_rpt.LAP_MKBD_VD57 l, 
( SELECT mkbd_cd, description,
					grp1, grp2, grp3
		  FROM FORM_MKBD
		  WHERE source = 'VD57'
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
INSERT INTO INSISTPRO_RPT.LAP_MKBD_VD57 (
   UPDATE_DATE, UPDATE_SEQ, MKBD_DATE, 
   VD, MKBD_CD, description,
   c1, c2, c3, c4,user_id, approved_stat, CRE_DT, price_date)
       SELECT  p_update_date update_date , p_update_seq update_seq , p_mkbd_date AS mkbd_date,
     'VD57' AS vd,  LPAD(TO_CHAR(mk.mkbd_cd),2) mkbd_cd,    
   description, 
      NVL(c1,0)  c1, 
   DECODE(vis2,0,0,NVL(afiliated,0) + NVL(dimiliki,0)) c2, 
   DECODE(vis3,0,0,NVL(c1,0) -   NVL(afiliated,0) - NVL(dimiliki,0) -  NVL(tdk_dipisah,0)) AS c3,
    DECODE(vis4,0,0,NVL(tdk_dipisah,0) ) c4,
	p_user_id, 'E' approved_stat, V_CRE_DT, p_price_date
 FROM(	SELECT c1.mkbd_cd,  SUM(f.amount) c1, 
				SUM(DECODE(c1.mkbd_cd,'11',1,'12',1,0) * f.afil_amount) afiliated,
				SUM(DECODE(c1.mkbd_cd,'29',1,'30',1,'31',1,'32',1,'33',1,'35',1,0) * f.porto_amount) dimiliki,
				SUM(DECODE(c1.mkbd_cd,'34',f.amount,'33',(dijaminkan_amount + repo_amount))) AS tdk_dipisah
		 FROM( SELECT gl_acct_cd, amount, afil_amount, porto_amount, 
		  SUM(DECODE(trim(gl_acct_cd),'13',1,0) * dijaminkan_amount) over ( ) dijaminkan_amount,
		 	   		  SUM(DECODE(trim(gl_acct_cd),'09',1,'50',1,0) * (amount)) over ( )  repo_amount
 		 	   FROM(  SELECT  t.gl_acct_cd, SUM(t.end_qty * s.pricing) amount, SUM(t.end_afil_qty * s.pricing) afil_amount,
		 	   		   SUM(t.end_porto_qty * s.pricing) porto_amount,
					   SUM( t.dijaminkan_qty * s.pricing) dijaminkan_amount,
					   SUM( t.repo_margin_qty * s.pricing) repo_margin_amount
					FROM( SELECT gl_acct_cd, stk_cd,  SUM( qty ) end_qty,  SUM( afil_qty ) end_afil_qty,
						  		 SUM( porto_qty ) end_porto_qty,
								  SUM( dijaminkan ) dijaminkan_qty,
								  SUM(DECODE(trim(gl_acct_cd),'09', margin_qty, '50',margin_qty,0)) repo_margin_qty
							FROM( SELECT trim(gl_acct_cd) gl_acct_cd, stk_cd, 
									  	 mvmt_qty AS  qty,
									     DECODE(m.afil,'A',mvmt_qty,0) 	 afil_qty,
										 DECODE(m.client_type_1,'H',1,DECODE(m.client_cd, trim(c.other_1),1,0)) * mvmt_qty AS porto_qty,
										 DECODE(m.client_type_3,'M',mvmt_qty,0) AS margin_qty,
										 DECODE(trim(gl_acct_cd),'13',mvmt_qty,0) AS dijaminkan  
									FROM( SELECT gl_Acct_cd, stk_cd, client_cd, DECODE(SIGN(TO_NUMBER(gl_acct_cd) - 30),-1,1,-1) *
										  		 DECODE(trim(db_cr_flg),'D',1,-1) * 
												 (NVL(withdrawn_share_qty,0) + NVL(total_share_qty,0)) AS mvmt_qty
									 FROM T_STK_MOVEMENT 
									 WHERE trim(doc_stat) = 2
									AND gl_acct_cd IS NOT NULL
									AND doc_dt BETWEEN v_begin_date AND v_end_date
									 ) t, 
									( SELECT MST_CLIENT.client_cd, afil, client_type_1, client_type_3 
									   FROM MST_CLIENT, 
									   ( SELECT client_cd, 'A' afil
									      FROM T_CLIENT_AFILIASI
										  WHERE v_end_date BETWEEN from_dt AND  to_Dt) ta 
									   WHERE MST_CLIENT.client_cd = ta.client_cd(+)) m, 
									 MST_COMPANY c
									WHERE t.client_cd = m.client_cd
									UNION ALL
									SELECT  trim(gl_acct_cd) gl_acct_cd, stk_cd, qty,
										   DECODE(m.afil,'A',qty,0) 	 afil_qty,
										   DECODE(m.client_type_1,'H',1,DECODE(m.client_cd, trim(c.other_1),1,0)) * qty porto_qty,
										   DECODE(m.client_type_3,'M',qty,0) AS margin_qty,
										   DECODE(trim(gl_acct_cd),'13',qty,0) AS dijaminkan  
									FROM T_SECU_BAL  t, 
									( SELECT MST_CLIENT.client_cd, afil, client_type_1, client_type_3 
									   FROM MST_CLIENT, 
									   ( SELECT client_cd, 'A' afil
									      FROM T_CLIENT_AFILIASI
										  WHERE v_end_date BETWEEN from_dt AND  to_Dt) ta 
									   WHERE MST_CLIENT.client_cd = ta.client_cd(+)) m, 
									MST_COMPANY c
									WHERE bal_dt = v_begin_date 
									AND t.client_cd = m.client_cd
									UNION ALL
									SELECT  trim(gl_acct_cd) gl_acct_cd, reks_cd, DECODE(trim(gl_acct_cd),'10',debit - credit, credit - debit),
									        0 afil_qty,
											DECODE(trim(gl_acct_cd),'10',debit - credit, credit - debit) porto_qty,
											0 margin_qty,
											0 dijaminkan 
									FROM T_REKS_MOVEMENT
									WHERE doc_dt < = v_end_date
									AND doc_stat = '2')
							GROUP BY gl_acct_cd, stk_cd
							) t,
						(  SELECT v.stk_cd, stk_clos,DECODE(stk_clos,0,stk_prev,stk_clos) * NVL(r.kebalikan,1) pricing
							FROM( SELECT stk_date, stk_cd, stk_prev, stk_clos
							     FROM V_STK_CLOS 
								 WHERE stk_date = p_price_date
								 UNION
								 SELECT price_dt, bond_cd, 0, price / 100 AS price
							     FROM T_BOND_PRICE
								 WHERE price_dt = p_price_date
								 UNION 
								 SELECT mkbd_dt, reks_cd, 0, nab_unit
								 FROM T_REKS_NAB
								 WHERE mkbd_dt = p_price_date
                           AND approved_stat = 'A')	v,
								( SELECT stk_cd, to_qty /from_qty AS kebalikan
									FROM T_CORP_ACT
									WHERE ca_type = 'REVERSE'
									AND v_end_date BETWEEN x_dt AND recording_dt 
									AND v_end_date > TO_DATE('01/07/2012','dd/mm/yyyy')
									AND v_end_date <= TO_DATE('29/06/2015','dd/mm/yyyy')
									UNION
								  SELECT stk_cd, to_qty /from_qty AS kebalikan
									FROM T_CORP_ACT
									WHERE ca_type = 'SPLIT'
									AND v_end_date BETWEEN x_dt AND recording_dt 
									AND v_end_date > TO_DATE('21/10/2013','dd/mm/yyyy')
									AND v_end_date <= TO_DATE('29/06/2015','dd/mm/yyyy')) r
							WHERE v.stk_cd = r.stk_cd(+)) S
						WHERE t.stk_cd = s.stk_cd (+)
						GROUP BY t.gl_acct_cd)) F,
				(	SELECT trim(mg.gl_a) gl_a, m.mkbd_cd
				  FROM FORM_MKBD m, MST_MAP_MKBD mg
				  WHERE m.source = 'VD57'
					 AND v_end_date  BETWEEN mg.ver_bgn_dt AND mg.ver_end_dt
					 AND v_end_date  BETWEEN m.ver_bgn_dt AND m.ver_end_dt
					 AND mg.mkbd_cd  = m.mkbd_cd
					AND mg.source = 'VD57') C1
			WHERE C1.gl_a = F.gl_acct_cd(+)
			GROUP BY c1.MKBD_CD	) X,
( SELECT mkbd_cd, description,texttab,vis1, vis2, vis3, vis4,
         grp1, grp2, grp3
  FROM FORM_MKBD
  WHERE source = 'VD57'
   AND mkbd_cd > 6) MK
WHERE mk.mkbd_cd = x.mkbd_cd(+);	
EXCEPTION
WHEN OTHERS THEN
	 		v_error_code := -3;
			v_error_msg :=  SUBSTR('Insert to LAP_MKBD_VD57 '||SQLERRM,1,200);
			RAISE v_err;
END;


	FOR rec IN csr_subtot_grp1  LOOP
			BEGIN
			UPDATE insistpro_rpt.LAP_MKBD_VD57
			SET c1 = NVL(rec.sum_c1,0),
				   	  c2 = NVL(rec.sum_c2,0),
					  c3 = NVL(rec.sum_c3,0),
					  c4 = NVL(rec.sum_c4,0)
			WHERE  update_date = p_update_date
			AND update_seq = p_update_seq
			and mkbd_cd = rec.grp1;
			EXCEPTION
			WHEN OTHERS THEN
	 		v_error_code := -4;
			v_error_msg :=  SUBSTR('Update LAP_MKBD_VD57 line : '||rec.grp1||SQLERRM,1,200);
			RAISE v_err;
			END;
	END LOOP;
	
	FOR rec IN csr_subtot_grp2 LOOP
			BEGIN
			UPDATE insistpro_rpt.LAP_MKBD_VD57
			SET c1 = NVL(rec.sum_c1,0),
				   	  c2 = NVL(rec.sum_c2,0),
					  c3 = NVL(rec.sum_c3,0),
					  c4 = NVL(rec.sum_c4,0)
			WHERE  update_date = p_update_date
			AND update_seq = p_update_seq
			and mkbd_cd = rec.grp2;
			EXCEPTION
			WHEN OTHERS THEN
	 		v_error_code := -5;
			v_error_msg :=  SUBSTR('Update LAP_MKBD_VD57 line : '||rec.grp2||SQLERRM,1,200);
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
END Sp_Mkbd_Vd57;
