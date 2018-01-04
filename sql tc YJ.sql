	SELECT c.client_name, NVL(c.contact_pers,c.client_name) contact_pers,   c.old_ic_num,
			   c.def_addr_1,  c.def_addr_2, c.def_addr_3, c.post_cd, 
				f.phone_num, f.phone2_1, f.hp_num, f.fax_num,f.hand_phone1, 
				 c.e_mail1, c.print_flg, f.client_title, c.branch_code, 
			   r.brch_name, r.brch_acct_num,h.bank_name, h.short_bank_name, r.phone_num brch_phone, r.fax_num brch_fax, 
			   r.def_addr_1 brch_addr_1, r.def_addr_2 brch_addr_2, r.def_addr_3 brch_addr_3, 
			   r.telex_num dealing_phone, r.post_cd AS br_post_cd, 	  
				s.rem_name, m.nama_prsh, m.no_ijin1,
				b.acct_name AS client_bank_name,b.bank_acct_num client_bank_acct, b.bank_name client_bank, 
				d.tc_id,	 f.npwp_no,  f.sid, v.subrek001, 
				NVL(z.bank_acct_fmt,NULL) bank_rdi_acct, z.acct_name AS rdi_name, z.bank_short_name AS bank_rdi,
			   t.max_rg_t3||DECODE(t.max_rg_t3,NULL, t.max_ng_t3, DECODE(t.max_ng_t3,NULL,'','/'||t.max_ng_t3)) AS mrkt_t3, 
			   t.max_rg_t2||DECODE(t.max_rg_t2,NULL, t.max_ng_t2, DECODE(t.max_ng_t2,NULL,'','/'||t.max_ng_t2)) AS mrkt_t2, 
			   t.max_rg_t1||DECODE(t.max_rg_t1,NULL, t.max_ng_t1, DECODE(t.max_ng_t1,NULL,'','/'||t.max_ng_t1)) AS mrkt_t1, 
			   t.max_rg_t0||DECODE(t.max_rg_t0,NULL, t.max_ng_t0, DECODE(t.max_ng_t0,NULL,'','/'||t.max_ng_t0)) AS mrkt_t0, 
			   t.*
		FROM( SELECT  a.contr_dt,a.r_i, a.client_cd, a.beli_jual, a.stk_cd, a.status, a.lot_size, a.qty, 
						a.price, a.brok_perc, a.whpph23_perc, a.brch_cd, a.rem_Cd, 
						a.b_val, a.j_val, a.b_comm, a.j_comm, a.b_vat, a.j_vat, 
						a.b_levy, a.j_levy, a.b_pph, a.j_pph, a.b_whpph23, a.j_whpph23, 
						a.pph_perc, a.mrkt_type, a.due_dt_for_amt, a.kpei_due_dt, 
						SUM(NVL(b_amt_t3,0)) over (PARTITION BY a.contr_dt, a.client_cd, a.r_i, a.brok_perc  ORDER BY a.contr_dt, a.client_cd, a.r_i, a.brok_perc ) + NVL(minfee.b_t3_mf,0) sum_b_t3, 
						SUM(NVL(j_amt_t3,0)) over (PARTITION BY a.contr_dt, a.client_cd, a.r_i, a.brok_perc  ORDER BY a.contr_dt, a.client_cd, a.r_i, a.brok_perc ) - NVL(minfee.j_t3_mf,0) sum_j_t3, 
						SUM(NVL(b_amt_t2,0)) over (PARTITION BY a.contr_dt, a.client_cd, a.r_i, a.brok_perc  ORDER BY a.contr_dt, a.client_cd, a.r_i, a.brok_perc ) + NVL(minfee.b_t2_mf,0) sum_b_t2, 
						SUM(NVL(j_amt_t2,0)) over (PARTITION BY a.contr_dt, a.client_cd, a.r_i, a.brok_perc  ORDER BY a.contr_dt, a.client_cd, a.r_i, a.brok_perc ) - NVL(minfee.j_t2_mf,0) sum_j_t2, 
						SUM(NVL(b_amt_t1,0)) over (PARTITION BY a.contr_dt, a.client_cd, a.r_i, a.brok_perc  ORDER BY a.contr_dt, a.client_cd, a.r_i, a.brok_perc ) + NVL(minfee.b_t1_mf,0) sum_b_t1, 
						SUM(NVL(j_amt_t1,0)) over (PARTITION BY a.contr_dt, a.client_cd, a.r_i, a.brok_perc  ORDER BY a.contr_dt, a.client_cd, a.r_i, a.brok_perc ) - NVL(minfee.j_t1_mf,0) sum_j_t1, 
						SUM(NVL(b_amt_t0,0)) over (PARTITION BY a.contr_dt, a.client_cd, a.r_i, a.brok_perc  ORDER BY a.contr_dt, a.client_cd, a.r_i, a.brok_perc ) + NVL(minfee.b_t0_mf,0) sum_b_t0, 
						SUM(NVL(j_amt_t0,0)) over (PARTITION BY a.contr_dt, a.client_cd, a.r_i, a.brok_perc  ORDER BY a.contr_dt, a.client_cd, a.r_i, a.brok_perc ) - NVL(minfee.j_t0_mf,0) sum_j_t0, 
						MAX(days_3plus) over (PARTITION BY a.contr_dt, a.client_cd, a.r_i, a.brok_perc ORDER BY a.contr_dt, a.client_cd, a.r_i, a.brok_perc ) max_3plus,
						MAX(trx_due_t3) over (PARTITION BY a.contr_dt, a.client_cd, a.r_i, a.brok_perc ORDER BY a.contr_dt, a.client_cd, a.r_i, a.brok_perc ) due_t3, 
						MAX(trx_due_t2) over (PARTITION BY a.contr_dt, a.client_cd, a.r_i, a.brok_perc  ORDER BY a.contr_dt, a.client_cd, a.r_i, a.brok_perc ) due_t2, 
						MAX(trx_due_t1) over (PARTITION BY a.contr_dt, a.client_cd, a.r_i, a.brok_perc  ORDER BY a.contr_dt, a.client_cd, a.r_i, a.brok_perc ) due_t1, 
						MAX(NVL(rg_t3,0)) over (PARTITION BY a.contr_dt, a.client_cd, a.r_i, a.brok_perc ORDER BY a.contr_dt, a.client_cd, a.r_i, a.brok_perc ) max_rg_t3, 
						MAX(NVL(rg_t2,0)) over (PARTITION BY a.contr_dt, a.client_cd, a.r_i, a.brok_perc  ORDER BY a.contr_dt, a.client_cd, a.r_i, a.brok_perc ) max_rg_t2, 
						MAX(NVL(rg_t1,0)) over (PARTITION BY a.contr_dt, a.client_cd, a.r_i, a.brok_perc  ORDER BY a.contr_dt, a.client_cd, a.r_i, a.brok_perc ) max_rg_t1, 
						MAX(NVL(rg_t0,0)) over (PARTITION BY a.contr_dt, a.client_cd, a.r_i, a.brok_perc  ORDER BY a.contr_dt, a.client_cd, a.r_i, a.brok_perc ) max_rg_t0, 
						MAX(NVL(ng_t3,0)) over (PARTITION BY a.contr_dt, a.client_cd, a.r_i, a.brok_perc  ORDER BY a.contr_dt, a.client_cd, a.r_i, a.brok_perc ) max_ng_t3, 
						MAX(NVL(ng_t2,0)) over (PARTITION BY a.contr_dt, a.client_cd, a.r_i, a.brok_perc  ORDER BY a.contr_dt, a.client_cd, a.r_i, a.brok_perc ) max_ng_t2, 
						MAX(NVL(ng_t1,0)) over (PARTITION BY a.contr_dt, a.client_cd, a.r_i, a.brok_perc ORDER BY a.contr_dt, a.client_cd, a.r_i, a.brok_perc ) max_ng_t1, 
						MAX(NVL(ng_t0,0)) over (PARTITION BY a.contr_dt, a.client_cd, a.r_i, a.brok_perc ORDER BY a.contr_dt, a.client_cd, a.r_i, a.brok_perc ) max_ng_t0, 
						SUM(NVL(b_amt,0)) over (PARTITION BY a.contr_dt, a.client_cd, a.r_i, a.brok_perc  ORDER BY a.contr_dt, a.client_cd, a.r_i, a.brok_perc ) + NVL(minfee.b_mf_amt,0) sum_b_amt, 
						SUM(NVL(j_amt,0)) over (PARTITION BY a.contr_dt, a.client_cd, a.r_i, a.brok_perc  ORDER BY a.contr_dt, a.client_cd, a.r_i, a.brok_perc )  - NVL(minfee.j_mf_amt,0) sum_j_amt, 
						SUM(NVL(b_val,0)) over (PARTITION BY a.contr_dt, a.client_cd, a.r_i, a.brok_perc  ORDER BY a.contr_dt, a.client_cd, a.r_i, a.brok_perc )  sum_b_val, 
						SUM(NVL(j_val,0)) over (PARTITION BY a.contr_dt, a.client_cd, a.r_i, a.brok_perc  ORDER BY a.contr_dt, a.client_cd, a.r_i, a.brok_perc )   sum_j_val, 
						SUM(NVL(b_comm,0)) over (PARTITION BY a.contr_dt, a.client_cd, a.r_i, a.brok_perc  ORDER BY a.contr_dt, a.client_cd, a.r_i, a.brok_perc ) + NVL(minfee.b_mf_comm,0)  sum_b_comm, 
						SUM(NVL(j_comm,0)) over (PARTITION BY a.contr_dt, a.client_cd, a.r_i, a.brok_perc  ORDER BY a.contr_dt, a.client_cd, a.r_i, a.brok_perc ) + NVL(minfee.j_mf_comm,0) sum_j_comm, 
						SUM(NVL(b_vat,0)) over (PARTITION BY a.contr_dt, a.client_cd, a.r_i, a.brok_perc  ORDER BY a.contr_dt, a.client_cd, a.r_i, a.brok_perc ) + NVL(minfee.b_mf_vat,0) sum_b_vat, 
						SUM(NVL(j_vat,0)) over (PARTITION BY a.contr_dt, a.client_cd, a.r_i, a.brok_perc  ORDER BY a.contr_dt, a.client_cd, a.r_i, a.brok_perc ) + NVL(minfee.j_mf_vat,0) sum_j_vat, 
						SUM(NVL(b_levy,0)) over (PARTITION BY a.contr_dt, a.client_cd, a.r_i, a.brok_perc ORDER BY a.contr_dt, a.client_cd, a.r_i, a.brok_perc ) sum_b_levy, 
						SUM(NVL(j_levy,0)) over (PARTITION BY a.contr_dt, a.client_cd, a.r_i, a.brok_perc  ORDER BY a.contr_dt, a.client_cd, a.r_i, a.brok_perc ) sum_j_levy, 
						SUM(NVL(b_pph,0)) over (PARTITION BY a.contr_dt, a.client_cd, a.r_i, a.brok_perc  ORDER BY a.contr_dt, a.client_cd, a.r_i, a.brok_perc ) sum_b_pph, 
						SUM(NVL(j_pph,0)) over (PARTITION BY a.contr_dt, a.client_cd, a.r_i, a.brok_perc  ORDER BY a.contr_dt, a.client_cd, a.r_i, a.brok_perc ) sum_j_pph, 
						SUM(NVL(b_whpph23,0)) over (PARTITION BY a.contr_dt, a.client_cd, a.r_i, a.brok_perc  ORDER BY a.contr_dt, a.client_cd, a.r_i, a.brok_perc ) sum_b_whpph23, 
						SUM(NVL(j_whpph23,0)) over (PARTITION BY a.contr_dt, a.client_cd, a.r_i, a.brok_perc  ORDER BY a.contr_dt, a.client_cd, a.r_i, a.brok_perc ) sum_j_whpph23 
			FROM( 	SELECT  contr_dt, SUBSTR(contr_num,6,1) R_I, 
							client_cd, 
							SUBSTR(contr_num,5,1) beli_jual, 
							stk_cd, status,	lot_size, qty, 
							price,  NVL(brok_perc, 0) brok_perc, par_val AS whpph23_perc, brch_cd, rem_Cd, 
							pph_perc, Mrkt_type, due_dt_for_amt, kpei_due_dt,
							DECODE( SIGN(scrip_days_c - 3),-1,0,scrip_days_c) AS days_3plus, 
							amt_for_curr, 
						   DECODE(SUBSTR(contr_num,5,1),'B', amt_for_curr,0) b_amt,          DECODE(SUBSTR(contr_num,5,1),'J', amt_for_curr,0) j_amt, 
						   DECODE(SUBSTR(contr_num,5,1),'B', DECODE( SIGN(scrip_days_c - 3),-1,0,amt_for_curr ),0) b_amt_t3, 
						   DECODE(SUBSTR(contr_num,5,1),'J', DECODE( SIGN(scrip_days_c - 3),-1,0,amt_for_curr  ),0) j_amt_t3, 
						   DECODE(SUBSTR(contr_num,5,1),'B', DECODE( scrip_days_c,2,amt_for_curr,0 ),0) b_amt_t2, 
						   DECODE(SUBSTR(contr_num,5,1),'J', DECODE( scrip_days_c,2,amt_for_curr,0 ),0) j_amt_t2, 
						   DECODE(SUBSTR(contr_num,5,1),'B', DECODE( scrip_days_c,1,amt_for_curr,0 ),0) b_amt_t1, 
						   DECODE(SUBSTR(contr_num,5,1),'J', DECODE( scrip_days_c,1,amt_for_curr,0 ),0) j_amt_t1, 
						   DECODE(SUBSTR(contr_num,5,1),'B', DECODE( scrip_days_c,0,amt_for_curr,0 ),0) b_amt_t0, 
						   DECODE(SUBSTR(contr_num,5,1),'J', DECODE( scrip_days_c,0,amt_for_curr,0 ),0) j_amt_t0, 
						   DECODE(SUBSTR(contr_num,5,1),'B', DECODE(contra_num,'APRICE',net,VAL),0) b_val,          
							DECODE(SUBSTR(contr_num,5,1),'J', DECODE(contra_num,'APRICE',net,VAL),0) j_val, 
						   DECODE(SUBSTR(contr_num,5,1),'B', NVL(commission,0),0) b_comm,  DECODE(SUBSTR(contr_num,5,1),'J', NVL(commission,0),0)  j_comm, 
						   DECODE(SUBSTR(contr_num,5,1),'B', NVL(vat,0),0)   b_vat,        DECODE(SUBSTR(contr_num,5,1),'J', NVL(vat,0),0)  j_vat, 
						   DECODE(SUBSTR(contr_num,5,1),'B', NVL(trans_levy,0),0) b_levy,  DECODE(SUBSTR(contr_num,5,1),'J', NVL(trans_levy,0),0)  j_levy, 
						   DECODE(SUBSTR(contr_num,5,1),'B', NVL(pph,0),0)   b_pph,        DECODE(SUBSTR(contr_num,5,1),'J', NVL(pph,0),0)  j_pph, 
						   DECODE(SUBSTR(contr_num,5,1),'B', NVL(pph_other_val,0),0) * -1   b_whpph23,        DECODE(SUBSTR(contr_num,5,1),'J', NVL(pph_other_val,0),0) * -1 j_whpph23, 
							DECODE(SIGN(scrip_days_c - 3),-1,NULL, DECODE(mrkt_type,'RG',mrkt_type,'TS','RG',NULL)) rg_t3, 
							DECODE(scrip_days_c,2,DECODE(mrkt_type,'RG',mrkt_type,'TS','RG',NULL),NULL) rg_t2, 
							DECODE(scrip_days_c,1,DECODE(mrkt_type,'RG',mrkt_type,'TS','RG',NULL),NULL) rg_t1, 
							DECODE(scrip_days_c,0,DECODE(mrkt_type,'RG',mrkt_type,'TS','RG','TN','TN',NULL),NULL) rg_t0, 
							DECODE(SIGN(scrip_days_c - 3),-1,NULL, DECODE(mrkt_type,'NG',mrkt_type,NULL)) ng_t3, 
							DECODE(scrip_days_c,2,DECODE(mrkt_type,'NG',mrkt_type,NULL),NULL) ng_t2, 
							DECODE(scrip_days_c,1,DECODE(mrkt_type,'NG',mrkt_type,NULL),NULL) ng_t1, 
							DECODE(scrip_days_c,0,DECODE(mrkt_type,'NG',mrkt_type,NULL),NULL) ng_t0, 
							DECODE(SIGN(scrip_days_c - 3),-1,TO_DATE(NULL),due_dt_for_amt) trx_due_t3, 
							DECODE(scrip_days_c,2,due_dt_for_amt,TO_DATE(NULL)) trx_due_t2, 
							DECODE(scrip_days_c,1,due_dt_for_amt,TO_DATE(NULL)) trx_due_t1 
						FROM T_CONTRACTS 
						WHERE contr_dt BETWEEN  :vp_bgn_date AND  :vp_end_date 
						AND contr_stat <> 'C' 
						AND client_cd BETWEEN :vp_beg_client AND :vp_end_client 
						AND trim(brch_cd)   BETWEEN :vp_beg_branch AND :vp_end_branch 
						AND rem_cd    BETWEEN :vp_beg_rem    AND :vp_end_rem	) a, 
				(	SELECT  b1.doc_date, 'R' R_I, b1.sl_acct_cd client_Cd, b1.db_cr_flg,
							SUM(DECODE(b1.db_cr_flg||v.acct_type,'DCOMM',t.curr_val,0)) b_mf_comm, 
							SUM(DECODE(b1.db_cr_flg||v.acct_type,'CCOMM',t.curr_val,0)) j_mf_comm, 
							SUM(DECODE(b1.db_cr_flg||v.acct_type,'DPPNO',t.curr_val,'DPOSD',t.curr_val,0)) b_mf_vat, 
							SUM(DECODE(b1.db_cr_flg||v.acct_type,'CPPNO',t.curr_val,'CPOSD',t.curr_val,0)) j_mf_vat, 
							SUM(DECODE(b1.db_cr_flg||v.acct_type,'DCLIE',t.curr_val,0)) b_mf_amt, 
							SUM(DECODE(b1.db_cr_flg||v.acct_type,'CCLIE',t.curr_val,0)) j_mf_amt, 
							SUM(DECODE(b1.db_cr_flg||v.acct_type,'DCLIE',DECODE(SIGN(Get_Work_Days(t.doc_date, t.due_date) - 3),-1,0,t.curr_val),0)) b_t3_mf, 
							SUM(DECODE(b1.db_cr_flg||v.acct_type,'CCLIE',DECODE(SIGN(Get_Work_Days(t.doc_date, t.due_date) - 3),-1,0,t.curr_val),0)) j_t3_mf, 
							SUM(DECODE(b1.db_cr_flg||v.acct_type,'DCLIE',DECODE(Get_Work_Days(t.doc_date, t.due_date),2,t.curr_val,0),0)) b_t2_mf, 
							SUM(DECODE(b1.db_cr_flg||v.acct_type,'CCLIE',DECODE(Get_Work_Days(t.doc_date, t.due_date),2,t.curr_val,0),0)) j_t2_mf, 
							SUM(DECODE(b1.db_cr_flg||v.acct_type,'DCLIE',DECODE(Get_Work_Days(t.doc_date, t.due_date),1,t.curr_val,0),0)) b_t1_mf, 
							SUM(DECODE(b1.db_cr_flg||v.acct_type,'CCLIE',DECODE(Get_Work_Days(t.doc_date, t.due_date),1,t.curr_val,0),0)) j_t1_mf,
							SUM(DECODE(b1.db_cr_flg||v.acct_type,'DCLIE',DECODE(due_date,t.doc_date,t.curr_val,0),0)) b_t0_mf, 
							SUM(DECODE(b1.db_cr_flg||v.acct_type,'CCLIE',DECODE(due_date,t.doc_date,t.curr_val,0),0)) j_t0_mf
				 FROM T_ACCOUNT_LEDGER t, v_gl_acct_type v, 
				( SELECT xn_doc_num, doc_date,gl_a, sl_acct_cd, v.db_cr_flg  
					FROM T_ACCOUNT_LEDGER t, v_gl_acct_type v 
					WHERE SUBSTR(xn_doc_num,8,3) = 'MFE' 
					AND sl_acct_cd BETWEEN :vp_beg_client AND :vp_end_client 
					AND doc_date BETWEEN  :vp_bgn_date AND  :vp_end_date
					AND v.acct_type ='CLIE' 
					AND t.gl_acct_cd = v.GL_A) B1 
				WHERE  t.doc_date BETWEEN  :vp_bgn_date AND  :vp_end_date
				AND t.xn_doc_num = B1.xn_doc_num 
				AND t.gl_acct_cd = v.GL_A
				AND T.APPROVED_STS <> 'C' 
				GROUP BY  b1.doc_date, b1.sl_acct_cd, b1.db_cr_flg, v.acct_type ) MINFEE 
				WHERE  a.contr_dt = minfee.doc_date(+) 
				   AND a.r_i = minfee.r_i (+) 
					AND a.client_Cd = minfee.client_cd(+)   ) T, 
				 (SELECT CLIENT_CD,acct_name, BANK_ACCT_NUM, BANK_NAME
				 FROM V_CLIENT_BANK
				 WHERE DEFAULT_FLG ='Y') B,
				 (  SELECT CLient_cd,  tc_date, TC_ID||DECODE(tc_rev,0,'',' rev.'||TO_CHAR(tc_rev)) tc_id
					 FROM T_TC_DOC
					 WHERE tc_date BETWEEN  :vp_bgn_date AND  :vp_end_date 
						AND client_cd BETWEEN :vp_beg_client AND :vp_end_client
					AND tc_status = 0 ) D,
				MST_CLIENT C, MST_BRANCH R, MST_BANK_MASTER H,MST_SALES S, 
				MST_COMPANY M, MST_COUNTER N,mst_cif f, v_client_subrek14 v,  MST_CLIENT_FLACCT  Z
		WHERE c.client_cd = t.client_cd
		AND c.cifs = f.cifs(+)
		AND   trim(r.brch_cd)   = trim(t.brch_cd) 
		AND   trim(s.rem_cd)    = trim(t.rem_cd) 
		AND   trim(r.bank_cd)   = trim(h.bank_cd)
		AND   t.stk_cd          = n.stk_cd
		AND   c.client_cd = b.client_cd(+)
		AND  t.client_Cd = d.client_cd(+)
		AND  t.client_Cd = v.client_cd(+) 
		AND t.contr_dt = d.tc_date(+)
		AND t.client_cd = z.client_cd(+)