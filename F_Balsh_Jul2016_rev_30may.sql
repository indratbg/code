create or replace FUNCTION F_Balsh_Jul2016(
	   p_item_type 	  VARCHAR2,
	   p_section VARCHAR2,
	   p_period		 VARCHAR2,
	   p_end_date	DATE,
	   p_branch  MST_GL_ACCOUNT.brch_cd%TYPE
) RETURN NUMBER IS
tmpVar NUMBER;
/******************************************************************************
   NAME:       F_BALSH
   PURPOSE: dipakai di datawindow d_bs_mar2013

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   28jul2016  utang/piutang broker di netting 1453, 2453
              utk saldo kredit di bagian pasiva ( 1422 kredit)
              create di MST GLA TRX jur type SKRD , gl_acct 1422 utk MU, 2422 utk YJ
              spy di MU tidak dobel krn di aktiva ada 1422

                 12dec2014 tambah   AND REVERSAL_JUR = 'N'

   1.0        11/03/2013          1. Created this function.

   			  30aug13 - sql utk item type ARAP103 dirubah spy dpt dipakai di PF / MU


   NOTES:

   p_section = 'A - aktiva, P pasiva

   AKTIVA p_item_type = BELI, TRX
                        saldo DEBIT  ARAP MARGIN
						KPEI
						AKTIVA KEUANGAN LAIN ARAP REGULAR

	PASIVA 				JUAL  TRX
						saldo KREDIT ARAP
						KPEI

	P_period = CURR, LASTMON, LASTYEAR

	jika p_item_type = 'ARAP' diberi suffix nomor baris di MKBD

select gl_a, F_BALSH(item_type,'A','CURR','1mar13','1mar13','11mar13') curr,
	    F_BALSH(item_type,'A','LASTMON','1mar13','1mar13','11mar13') lastmon,
		 F_BALSH(item_type,'A','LASTYR','1mar13','1mar13','11mar13') lastyr
from
(select gl_a, decode(jur_type,'CLIE','TRX','KPEI','KPEI','T3','ARAP35','ARAP103') item_type
from MST_GLA_TRX
where jur_type in ( 'CLIE','KPEI','T3','T7')
and db_CR_flg = 'D')

select decode(item_type,'ARAP159','2422',gl_a) gl_a, F_BALSH(item_type,'P','CURR',:dt_end_date) curr,
	    F_BALSH(item_type,'P','LASTMON',:dt_end_date) lastmon,
		 F_BALSH(item_type,'P','LASTYR',:dt_end_date) lastyr
from
(select gl_a, decode(jur_type,'CLIE','TRX','KPEI','KPEI','T3','ARAP159') item_type
from MST_GLA_TRX
where jur_type in ( 'CLIE','KPEI','T3')
and (db_CR_flg = 'C' or jur_type = 'T3'))

30 may 2017 komen where brch_cd dari mst_gl_account krna gk pake  index
******************************************************************************/

v_gl_a T_ACCOUNT_LEDGER.gl_acct_cd%TYPE;
v_amt  T_ACCOUNT_LEDGER.curr_val%TYPE;
v_item_type MST_GLA_TRX.jur_type%TYPE;


v_begin_date DATE;
v_end_date DATE;
v_begin_prev DATE;
v_year CHAR(4);
v_ts_netting_dt DATE;
v_brok_netting_dt DATE;
v_nettg CHAR(1);

BEGIN
   tmpVar := 0;

   v_end_date := p_end_date;
   v_begin_date :=  v_end_date - TO_NUMBER(TO_CHAR(p_end_date,'dd') ) + 1;


	IF p_period = 'LASTMON' THEN
	   v_end_date := v_begin_date - 1;
	   v_begin_date :=  v_end_date - TO_NUMBER(TO_CHAR(v_end_date,'dd') ) + 1;
	END IF;

	IF p_period = 'LASTYR' THEN
	   v_year := TO_CHAR(TO_NUMBER(TO_CHAR(p_end_date,'yyyy') ) - 1);
	   v_end_date := TO_DATE('31/12/'||v_year,'dd/mm/yyyy');
	   v_begin_date :=  TO_DATE('01/12/'||v_year,'dd/mm/yyyy');
	END IF;

    v_begin_prev := v_begin_date - 1;
   v_begin_prev := v_begin_prev - TO_NUMBER(TO_CHAR(v_begin_prev,'dd') ) + 1;

   IF p_item_type = 'TRX' THEN

		 SELECT gl_a INTO v_gl_a
		 FROM MST_GLA_TRX
		 WHERE ((JUR_type = 'CLIED' AND p_section = 'A')
		      OR (JUR_type = 'CLIEC' AND p_section = 'P'));

		SELECT ddate1 INTO v_ts_netting_dt
		FROM MST_SYS_PARAM
		WHERE param_id = 'F_BALSH'
		AND param_cd1 = 'TSNETTG';



		IF p_section = 'A' THEN
			SELECT SUM(	amt) INTO v_amt
			FROM(
				SELECT v_gl_a AS gl_a, DECODE(SIGN(amt),-1,0,amt) amt
				FROM( SELECT  SUM(amt) amt
						FROM(	SELECT  (b.deb_obal -b.cre_obal) amt
								FROM T_DAY_TRS b, MST_GLA_TRX a, MST_GL_ACCOUNT g
								WHERE b.trs_dt = v_begin_prev
								AND a.JUR_type IN (  'CLIE')
								AND   b.gl_acct_cd = a.gl_A
								AND p_period = 'CURR'
								AND b.gl_acct_cd = g.gl_a
								AND b.sl_acct_cd = g.sl_a
								--AND ((g.brch_cd) = p_branch OR p_branch = '%')
								UNION ALL
								SELECT DECODE(d.db_cr_flg,'D',1,-1) * d.curr_val mvmt
								FROM T_ACCOUNT_LEDGER d, MST_GLA_TRX a, MST_GL_ACCOUNT g
								WHERE d.doc_date BETWEEN v_begin_prev AND v_end_date
								AND d.approved_sts = 'A'
								AND d.due_date  <= v_end_date
								AND a.jur_type IN (  'CLIE')
								AND p_period = 'CURR'
								AND   d.gl_acct_cd = a.gl_A 
								AND d.gl_acct_cd = g.gl_a
								AND d.sl_acct_cd = g.sl_a
								--AND ((g.brch_cd) = p_branch OR p_branch = '%')
                ))
			   UNION ALL
			   SELECT 	v_gl_a AS gl_a,  GREATEST(net_trx,0) + buy_trx
			   FROM( SELECT   due_date, sl_acct_cd,
									MAX(DECODE(trim(a.jur_type), 'CLIE',34)) mkbd_cd,
									SUM(DECODE(t.mrkt_type,'RG',DECODE(d.db_cr_flg,'D',1,-1) * curr_val,0)) net_trx,
									SUM(DECODE(t.mrkt_type,'RG',0,DECODE(d.db_cr_flg,'D',1,0) * curr_val)) buy_trx
						  FROM T_ACCOUNT_LEDGER d, MST_GLA_TRX a, MST_GL_ACCOUNT g,
								( SELECT DECODE(SUBSTR(contr_num,6,1),'I',SUBSTR(contr_num,5,2),mrkt_type) mrkt_type,
							                       DECODE(SUBSTR(contr_num,6,1),'I',SUBSTR(contr_num,1,6)||'0'||SUBSTR(contr_num,8,7), contr_num) AS contr_num
						            FROM 	T_CONTRACTS
									  WHERE  contr_dt BETWEEN v_begin_date - 30  AND v_end_date
									  AND v_end_date  >= v_ts_netting_dt
									  AND contr_stat <>'C'
									  AND record_source <> 'IB'
									  UNION ALL
								  SELECT 'RG' AS MRKT_TYPE, doc_num AS CONTR_NUM
								  FROM T_BOND_TRX
								 WHERE  trx_date BETWEEN v_begin_date - 30     AND v_end_date
								  AND approved_sts = 'A'
								  AND value_dt > v_end_date
									 AND doc_num IS NOT NULL
								   UNION ALL
								   SELECT DECODE(SUBSTR(contr_num,6,1),'I','NG',DECODE(mrkt_type,'TS','RG',mrkt_type)) mrkt_type,
								                     DECODE(SUBSTR(contr_num,6,1),'I',SUBSTR(contr_num,1,6)||'0'||SUBSTR(contr_num,8,7), contr_num) AS contr_num
									FROM T_CONTRACTS
									WHERE contr_dt BETWEEN v_begin_date - 30  AND v_end_date
									AND  v_end_date  < v_ts_netting_dt
									AND contr_stat <>'C'
								    AND record_source <> 'IB'
									) t
								  WHERE d.doc_Date BETWEEN v_begin_date - 30 AND v_end_date
								  AND d.due_Date > v_end_date
								  AND d.approved_sts = 'A'
								  AND a.jur_type IN (  'CLIE')
								  AND   d.gl_acct_cd = a.gl_A
								  AND d.xn_doc_num = t.CONTR_NUM
								  AND   d.gl_acct_cd = g.gl_A
								  AND   d.sl_acct_cd = g.sl_A
								  --AND ((g.brch_cd) = p_branch  OR p_branch = '%')
					 GROUP BY   due_date,sl_acct_cd   )
			   WHERE net_trx > 0 OR buy_trx >0
			UNION ALL
			  SELECT  v_gl_a AS gl_a,  SUM(curr_val)
			  FROM T_ACCOUNT_LEDGER d, MST_GL_ACCOUNT g
			  WHERE doc_Date BETWEEN v_begin_date - 30 AND v_end_date
			  AND due_Date > v_end_date
			  AND approved_sts = 'A'
			  AND record_source = 'GL'
			  AND   xn_doc_num LIKE '%GLAMFE%'
			  AND tal_id = 1
			  AND REVERSAL_JUR = 'N'
			  AND   d.gl_acct_cd = g.gl_A
			  AND   d.sl_acct_cd = g.sl_A
			 -- AND ((g.brch_cd) = p_branch  OR p_branch = '%')
			  );

		END IF;

		IF p_section = 'P' THEN

				SELECT SUM(	amt) INTO v_amt
				FROM(
					SELECT v_gl_a AS gl_a,  DECODE(SIGN(amt),-1,0,amt) amt
					FROM( SELECT  SUM(amt) amt
						FROM( SELECT  (b.cre_obal -b.deb_obal) amt
								FROM T_DAY_TRS b, MST_GLA_TRX a, MST_GL_ACCOUNT g
								WHERE b.trs_dt = v_begin_prev
								AND a.jur_type IN (  'CLIE')
								AND p_period = 'CURR'
								AND   b.gl_acct_cd = a.gl_A
								AND b.gl_acct_cd = g.gl_a
								AND b.sl_acct_cd = g.sl_a
								--AND (trim(g.brch_cd) = p_branch OR p_branch = '%')
							  UNION ALL
							  SELECT DECODE(d.db_cr_flg,'C',1,-1) * d.curr_val mvmt
							  FROM T_ACCOUNT_LEDGER d, MST_GLA_TRX a, MST_GL_ACCOUNT g
							  WHERE d.doc_date BETWEEN v_begin_prev AND v_end_date
								AND d.approved_sts <> 'C' AND d.approved_sts <> 'E'
								AND d.due_date  <= v_end_date
								AND a.jur_type IN (  'CLIE')
								AND p_period = 'CURR'
								AND   d.gl_acct_cd = a.gl_A
								AND d.gl_acct_cd = g.gl_a
								AND d.sl_acct_cd = g.sl_a
								--AND (trim(g.brch_cd) = p_branch OR p_branch = '%')
                ))
				  UNION ALL
				  SELECT 	v_gl_a AS gl_a,   GREATEST(net_trx,0) + sell_trx
				   FROM( SELECT   due_date, sl_acct_cd,
										MAX(DECODE(trim(a.jur_type), 'CLIE',133)) mkbd_cd,
										SUM(DECODE(t.mrkt_type,'RG',DECODE(d.db_cr_flg,'C',1,-1) * curr_val,0)) net_trx,
									    SUM(DECODE(t.mrkt_type,'RG',0,DECODE(d.db_cr_flg,'C',1,0) * curr_val)) sell_trx
							  FROM T_ACCOUNT_LEDGER d, MST_GLA_TRX a, MST_GL_ACCOUNT g,
							  (  SELECT DECODE(SUBSTR(contr_num,6,1),'I',SUBSTR(contr_num,5,2),mrkt_type) mrkt_type,
							                       DECODE(SUBSTR(contr_num,6,1),'I',SUBSTR(contr_num,1,6)||'0'||SUBSTR(contr_num,8,7), contr_num) AS contr_num
						            FROM 	T_CONTRACTS
									  WHERE  contr_dt BETWEEN v_begin_date - 30  AND v_end_date
									  AND v_end_date  >= v_ts_netting_dt
									  AND contr_stat <>'C'
									  AND record_source <> 'IB'
									  UNION ALL
								  SELECT 'RG' AS MRKT_TYPE, doc_num AS CONTR_NUM
								  FROM T_BOND_TRX
								 WHERE  trx_date BETWEEN v_begin_date - 30     AND v_end_date
								  AND approved_sts = 'A'
								  AND value_dt > v_end_date
									 AND doc_num IS NOT NULL
								   UNION ALL
								   SELECT DECODE(SUBSTR(contr_num,6,1),'I','NG',DECODE(mrkt_type,'TS','RG',mrkt_type)) mrkt_type,
								                     DECODE(SUBSTR(contr_num,6,1),'I',SUBSTR(contr_num,1,6)||'0'||SUBSTR(contr_num,8,7), contr_num) AS contr_num
									FROM T_CONTRACTS
									WHERE contr_dt BETWEEN v_begin_date - 30  AND v_end_date
									AND  v_end_date  < v_ts_netting_dt
									AND contr_stat <>'C'
								    AND record_source <> 'IB'
							   ) t
									  WHERE d.doc_Date BETWEEN v_begin_date - 30 AND v_end_date
									  AND d.due_Date > v_end_date
									  AND d.approved_sts ='A'
									  AND a.jur_type IN (  'CLIE')
									  AND   d.gl_acct_cd = a.gl_A
									  AND d.record_source = 'CG'
									  AND d.xn_doc_num = t.CONTR_NUM
									  AND d.gl_acct_cd = g.gl_a
									AND d.sl_acct_cd = g.sl_a
								--	AND (trim(g.brch_cd) = p_branch OR p_branch = '%')
						 GROUP BY   due_date,sl_acct_cd  )
				  WHERE net_trx > 0 OR sell_trx >0);

		END IF;

   END IF;



    IF (p_item_type = 'KPEI') OR   (p_item_type = 'BROK') THEN
--		 SELECT gl_a INTO v_gl_a
--			 FROM MST_GLA_TRX
--			 WHERE  ((P_SECTION = 'A' AND JUR_TYPE in ( 'KPEID','BROKD'))
--			      OR (p_section = 'P' AND JUR_TYPE in ( 'KPEIC','BROKC')));

       v_item_type := p_item_type;

       IF (p_item_type = 'KPEI')   THEN
              v_nettg := 'Y';
       ELSE
           BEGIN
           SELECT DECODE(SIGN(ddate1 - v_end_date),1,'N','Y')  INTO v_nettg
            FROM MST_SYS_PARAM
            WHERE param_id = 'F_BALSH'
            AND param_cd1 = 'BROKNETG';
           EXCEPTION
           WHEN NO_DATA_FOUND THEN
              v_nettg := 'N';
          END;
		  
          IF v_nettg = 'N' THEN
             IF p_section = 'A' THEN
                v_item_type := v_item_type||'D';
             ELSE
                v_item_type := v_item_type||'C';
            END IF;
          END IF;
      END IF;



		--IF p_section = 'A' THEN
		   	SELECT SUM(	amt) INTO v_amt
				FROM(
					SELECT 	 DECODE(SIGN(amt),-1,0,amt) amt
					FROM( SELECT  SUM(amt) amt
							FROM(	SELECT   (b.deb_obal -b.cre_obal) * DECODE( p_section,'A',1,-1) amt
									FROM T_DAY_TRS b, MST_GLA_TRX a, MST_GL_ACCOUNT g
									WHERE v_nettg = 'Y'
                  					AND b.trs_dt = v_begin_prev
									AND a.jur_type =  v_item_type
									AND   b.gl_acct_cd = a.gl_A
									AND b.gl_acct_cd = g.gl_a
									AND b.sl_acct_cd = g.sl_a
								--	AND ((g.brch_cd) = p_branch OR p_branch = '%')
									UNION ALL
									SELECT   DECODE(d.db_cr_flg,'D',1,-1)* DECODE( p_section,'A',1,-1) * d.curr_val mvmt
									FROM T_ACCOUNT_LEDGER d, MST_GLA_TRX a, MST_GL_ACCOUNT g
									WHERE v_nettg = 'Y'
                  					AND d.doc_date BETWEEN v_begin_prev AND v_end_date
									AND d.approved_sts = 'A'
									AND d.due_date  <= v_end_date
									AND a.jur_type =  v_item_type
									AND   d.gl_acct_cd = a.gl_A 
									AND d.gl_acct_cd = g.gl_a
									AND d.sl_acct_cd = g.sl_a
									--AND ((g.brch_cd) = p_branch OR p_branch = '%') 
                  ))
            UNION ALL
            SELECT  	 NVL(SUM( net_trx ), 0)
            FROM( SELECT   sl_acct_Cd, due_date, SUM(curr_Val) net_trx
						  FROM( SELECT  DECODE(v_item_type ,'KPEI', v_item_type, d.sl_acct_cd) sl_acct_cd,  due_date,
									 		 			DECODE(d.db_cr_flg,'D',1,-1) * DECODE( p_section,'A',1,-1) * curr_val AS curr_Val
			                         FROM T_ACCOUNT_LEDGER d, MST_GLA_TRX a, MST_GL_ACCOUNT g
			                          WHERE v_nettg = 'Y'
			                          AND d.doc_Date BETWEEN v_begin_date - 30 AND v_end_date
			                          AND d.due_Date > v_end_date
			                          AND d.approved_sts  = 'A'
			                          AND a.jur_type =  v_item_type
			                          AND   d.gl_acct_cd = a.gl_A
			                          AND d.record_source = 'CG'
			                          AND REVERSAL_JUR = 'N'
									  AND d.gl_acct_cd = g.gl_a
									  AND d.sl_acct_cd = g.sl_a
									  --AND ((g.brch_cd) = p_branch OR p_branch = '%')
                    )
                   GROUP BY  sl_acct_Cd,  due_date   )
				   WHERE net_trx > 0
           UNION ALL
           SELECT SUM( (b.deb_obal - b.cre_obal) * DECODE(  p_section,'A',1,-1))  last_mon
              FROM T_DAY_TRS b,
            (SELECT gl_a
            FROM MST_GLA_TRX
            WHERE jur_type =   v_item_type ) v
          WHERE v_nettg = 'N'
          AND b.trs_dt   =   v_end_date + 1
          AND b.gl_acct_cd = v.gl_a
           )  ;
		--END IF;

		/*IF p_section = 'P' THEN
		   		SELECT SUM(	amt) INTO v_amt
				FROM(
					SELECT v_gl_a AS gl_a, DECODE(SIGN(amt),-1,0,amt) amt
					FROM( SELECT  SUM(amt) amt
							FROM(	SELECT  (b.cre_obal -b.deb_obal) amt
									FROM T_DAY_TRS b, MST_GLA_TRX a
									WHERE b.trs_dt = v_begin_prev
									AND a.jur_type IN ( 'KPEI', 'BROK')
									AND   b.gl_acct_cd = a.gl_A
								  UNION ALL
								  SELECT  DECODE(d.db_cr_flg,'C',1,-1) * d.curr_val mvmt
								  FROM T_ACCOUNT_LEDGER d, MST_GLA_TRX a
								  WHERE d.doc_date BETWEEN v_begin_prev AND v_end_date
									AND d.approved_sts <> 'C' AND d.approved_sts <> 'E'
									AND d.due_date  <= v_end_date
									AND a.jur_type IN ( 'KPEI', 'BROK')
									AND   d.gl_acct_cd = a.gl_A))
				  UNION ALL
				  SELECT v_gl_a AS gl_a,   GREATEST(net_trx,0)
				   FROM( SELECT   due_date,
										MAX(DECODE(trim(a.jur_type), 'KPEI',129)) mkbd_cd,
										SUM(DECODE(d.db_cr_flg,'C',1,-1) * curr_val) net_trx
							  FROM T_ACCOUNT_LEDGER d, MST_GLA_TRX a
							  WHERE d.doc_Date BETWEEN v_begin_date - 30 AND v_end_date
							  AND d.due_Date > v_end_date
							  AND d.approved_sts <> 'C' AND d.approved_sts <> 'E'
							  AND a.jur_type IN ( 'KPEI', 'BROK')
							  AND d.gl_acct_cd = a.gl_a
						 GROUP BY   due_date  )
				  WHERE net_trx > 0 );


		END IF;*/


	END IF;


	IF p_item_type = 'ARAP35' THEN



		SELECT  SUM(	n.end_bal) INTO v_amt
		FROM(	SELECT client_cd,   SUM(beg_bal + mvmt ) end_bal
				FROM(  SELECT TRIM(T_ACCOUNT_LEDGER.sl_acct_cd)  client_cd, 0 beg_bal,
								DECODE(T_ACCOUNT_LEDGER.db_cr_flg, 'D', 1, -1) * NVL(T_ACCOUNT_LEDGER.curr_val, 0) mvmt
						 FROM T_ACCOUNT_LEDGER, MST_GLA_TRX a, MST_GL_ACCOUNT g
						WHERE T_ACCOUNT_LEDGER.doc_date BETWEEN v_begin_date AND   v_end_date 
						 AND  T_ACCOUNT_LEDGER.approved_sts  = 'A'
						 AND  T_ACCOUNT_LEDGER.gl_acct_cd   = a.gl_A
						 AND a.jur_type = 'T3'
						 AND T_ACCOUNT_LEDGER.gl_acct_cd = g.gl_a
						 AND T_ACCOUNT_LEDGER.sl_acct_cd = g.sl_a
						 --AND (trim(g.brch_cd) = p_branch OR p_branch = '%')
						UNION ALL
						 SELECT TRIM(T_DAY_TRS.sl_acct_cd),
								(NVL(T_DAY_TRS.deb_obal, 0) - NVL(T_DAY_TRS.cre_obal, 0)) beg_bal, 0 mvmt
							 FROM T_DAY_TRS, MST_GLA_TRX a, MST_GL_ACCOUNT g
							WHERE  T_DAY_TRS.gl_acct_cd   = a.gl_A
							  AND  T_DAY_TRS.trs_dt = v_begin_date
							  AND a.jur_type  = 'T3'
							  AND T_DAY_TRS.gl_acct_cd = g.gl_a
							  AND T_DAY_TRS.sl_acct_cd = g.sl_a
							  --AND (trim(g.brch_cd) = p_branch OR p_branch = '%')
                )
				GROUP BY client_cd
				HAVING SUM(beg_bal + mvmt ) > 0) n,
			( SELECT m.client_cd, m.client_name
				FROM MST_CLIENT m, LST_TYPE3 l
				WHERE m.client_type_3 = l.cl_type3
				 AND  m.client_type_1 <> 'B'
				 AND  l.margin_cd = 'M') m
		WHERE m.client_cd         = n.client_cd;

	END IF;

	IF p_item_type = 'ARAP103' THEN


		SELECT  SUM(	n.end_bal) INTO v_amt
		FROM(	SELECT gl_Acct_cd,client_cd,   SUM(beg_bal + mvmt ) end_bal
				FROM(  SELECT TRIM(T_ACCOUNT_LEDGER.gl_acct_cd) gl_Acct_cd,
					   		  TRIM(T_ACCOUNT_LEDGER.sl_acct_cd)  client_cd,
					   		   0 beg_bal,
								DECODE(T_ACCOUNT_LEDGER.db_cr_flg, 'D', 1, -1) * NVL(T_ACCOUNT_LEDGER.curr_val, 0) mvmt
						 FROM T_ACCOUNT_LEDGER, MST_GLA_TRX a, MST_GL_ACCOUNT g
						WHERE T_ACCOUNT_LEDGER.doc_date  BETWEEN v_begin_date AND   v_end_date 
						 AND  T_ACCOUNT_LEDGER.approved_sts  = 'A'
						 AND  T_ACCOUNT_LEDGER.gl_acct_cd   = a.gl_A
						 AND a.jur_type IN ( 'T3','T7')
						 AND T_ACCOUNT_LEDGER.gl_acct_cd = g.gl_a
						 AND T_ACCOUNT_LEDGER.sl_acct_cd = g.sl_a
						 --AND (trim(g.brch_cd) = p_branch OR p_branch = '%')
						UNION ALL
						 SELECT TRIM(T_DAY_TRS.gl_acct_cd) gl_Acct_cd,
						 		TRIM(T_DAY_TRS.sl_acct_cd),
								(NVL(T_DAY_TRS.deb_obal, 0) - NVL(T_DAY_TRS.cre_obal, 0)) beg_bal, 0 mvmt
							 FROM T_DAY_TRS, MST_GLA_TRX a, MST_GL_ACCOUNT g
							WHERE  T_DAY_TRS.gl_acct_cd   = a.gl_A
							  AND  T_DAY_TRS.trs_dt = TRUNC(v_begin_date)
							  AND a.jur_type  IN ( 'T3','T7')
							  AND T_DAY_TRS.gl_acct_cd = g.gl_a
							  AND T_DAY_TRS.sl_acct_cd = g.sl_a
							--  AND (trim(g.brch_cd)= p_branch OR p_branch = '%')
							  )
				GROUP BY gl_Acct_cd,client_cd
				HAVING SUM(beg_bal + mvmt ) > 0) n,
			( SELECT m.client_cd, m.client_name, l.margin_cd
				FROM MST_CLIENT m, LST_TYPE3 l
				WHERE m.client_type_3 = l.cl_type3
				 AND  m.client_type_1 <> 'B') m,
			( SELECT trim(gl_a) gl_a
			   FROM	  MST_GLA_TRX
			   WHERE jur_type  = 'T7') v
		WHERE m.client_cd         = n.client_cd
		AND (	margin_cd = 'R' 	OR n.gl_acct_cd = v.gl_A);

	END IF;

	IF p_item_type = 'ARAP159' THEN

		SELECT  -1 * SUM(	n.end_bal) INTO v_amt
		FROM(	SELECT client_cd,   SUM(beg_bal + mvmt ) end_bal
				FROM(  SELECT TRIM(MST_CLIENT.client_cd)  client_cd, 0 beg_bal,
								DECODE(T_ACCOUNT_LEDGER.db_cr_flg, 'D', 1, -1) * NVL(T_ACCOUNT_LEDGER.curr_val, 0) mvmt
						 FROM MST_CLIENT,
								T_ACCOUNT_LEDGER, MST_GLA_TRX a, MST_GL_ACCOUNT g
						WHERE   T_ACCOUNT_LEDGER.sl_acct_cd = MST_CLIENT.client_cd
						 AND  T_ACCOUNT_LEDGER.doc_date  BETWEEN v_begin_date AND   v_end_date 
						 AND  T_ACCOUNT_LEDGER.approved_sts  = 'A'
						 AND  T_ACCOUNT_LEDGER.gl_acct_cd   = a.gl_A
						 AND a.jur_type = 'T3'
						 AND T_ACCOUNT_LEDGER.gl_acct_cd = g.gl_a
						 AND T_ACCOUNT_LEDGER.sl_acct_cd = g.sl_a
						 --AND (trim(g.brch_cd) = p_branch OR p_branch = '%')
						UNION ALL
						 SELECT TRIM(MST_CLIENT.client_cd),
								(NVL(T_DAY_TRS.deb_obal, 0) - NVL(T_DAY_TRS.cre_obal, 0)) beg_bal, 0 mvmt
							 FROM MST_CLIENT,		T_DAY_TRS, MST_GLA_TRX a, MST_GL_ACCOUNT g
							WHERE   T_DAY_TRS.sl_acct_cd = MST_CLIENT.client_cd
							  AND  T_DAY_TRS.gl_acct_cd   = a.gl_A
							 AND  T_DAY_TRS.trs_dt = TRUNC(v_begin_date)
							 AND a.jur_type  = 'T3'
							 AND T_DAY_TRS.gl_acct_cd = g.gl_a
							 AND T_DAY_TRS.sl_acct_cd = g.sl_a
							 --AND (trim(g.brch_cd) = p_branch OR p_branch = '%')
               )
				GROUP BY client_cd
				HAVING SUM(beg_bal + mvmt ) < 0) n;

	END IF;

   RETURN v_amt;
   EXCEPTION
     WHEN NO_DATA_FOUND THEN
       NULL;
     WHEN OTHERS THEN
       -- Consider logging the error and then re-raise
       RAISE;
END F_Balsh_Jul2016;