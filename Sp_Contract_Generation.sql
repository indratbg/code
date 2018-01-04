create or replace 
PROCEDURE Sp_Contract_Generation (
                                                p_exchange_date   DATE,
                                                p_user_id       VARCHAR2,
												p_trx_cnt          OUT NUMBER,
                                                p_error_code							OUT NUMBER,
                                                p_error_msg							OUT VARCHAR2)
IS
-- Sep15 SP ini pakai jurnal transaksi sesuai PAPE, dmn BEI fee dipecah
--29jan15 trx TS pakai securities jurnal account code sama dg NEGO
--21oct14  get_contract_number diganti GET_CONTR_NUM didlmnya pakai CONTR_NUM_SEQ
--20may11 kolom SCRIP_DAYS_C di T_CONTRACTS diisi dgn due days,
-- diambil dr variable vdue_kpei, berasal dr mst_settlement / mst-settlement_client
-- krn SCRIP_DAYS_C akan digunakan di trade confirmation, spy bisa print beberapa tgl sekaligus

   CURSOR csr_buy(p_date   DATE)
   IS
   SELECT T_DTL_EXCHANGE.end_client_cd client_cd,
          T_DTL_EXCHANGE.stk_cd,
          TRUNC(T_DTL_EXCHANGE.trdg_dt) exchange_date,
          T_DTL_EXCHANGE.price,
          T_DTL_EXCHANGE.mrkt_type,
          T_DTL_EXCHANGE.org_sales_person_cd,
          T_DTL_EXCHANGE.status stk_status,
          DECODE(mrkt_type,'NG',buy_broker_cd,'  ') AS buy_broker,
		  DECODE(mrkt_type,'NG',sell_broker_cd,'  ') AS sell_broker,
		  SUM(T_DTL_EXCHANGE.qty) qty,
		  SUM( DECODE(ses_num,1,0,1)) sum_session
   FROM T_DTL_EXCHANGE
   WHERE TRUNC(T_DTL_EXCHANGE.trdg_dt) = TRUNC(p_date)
   AND   T_DTL_EXCHANGE.buy_sell_ind = 'P'
   AND   T_DTL_EXCHANGE.con_gen_flg = 'N'
   GROUP BY T_DTL_EXCHANGE.end_client_cd,
            T_DTL_EXCHANGE.stk_cd,
            TRUNC(T_DTL_EXCHANGE.trdg_dt) ,
            T_DTL_EXCHANGE.price,
            T_DTL_EXCHANGE.mrkt_type,
            T_DTL_EXCHANGE.org_sales_person_cd,
            T_DTL_EXCHANGE.status,
			DECODE(mrkt_type,'NG',buy_broker_cd,'  '),
            DECODE(mrkt_type,'NG',sell_broker_cd,'  ');

--			Decode(INSTR('TNNG',mrkt_type),0,'  ',buy_broker_cd),
--            Decode(INSTR('TNNG',mrkt_type),0,'  ',sell_broker_cd);


   CURSOR csr_sell(p_date  DATE)
   IS
   SELECT T_DTL_EXCHANGE.end_client_cd client_cd,
          T_DTL_EXCHANGE.stk_cd,
          TRUNC(T_DTL_EXCHANGE.trdg_dt) exchange_date,
          T_DTL_EXCHANGE.price,
          T_DTL_EXCHANGE.mrkt_type,
          T_DTL_EXCHANGE.org_sales_person_cd,
          T_DTL_EXCHANGE.status stk_status,
          DECODE(T_DTL_EXCHANGE.mrkt_type,'NG',buy_broker_cd,'  ') AS buy_broker,
		  DECODE(T_DTL_EXCHANGE.mrkt_type,'NG',sell_broker_cd,'  ') AS sell_broker,
          SUM(T_DTL_EXCHANGE.qty) qty,
		  SUM( DECODE(ses_num,1,0,1)) sum_session
   FROM T_DTL_EXCHANGE
   WHERE TRUNC(T_DTL_EXCHANGE.trdg_dt) = TRUNC(p_date)
   AND   T_DTL_EXCHANGE.buy_sell_ind = 'S'
   AND   T_DTL_EXCHANGE.con_gen_flg = 'N'
   GROUP BY T_DTL_EXCHANGE.end_client_cd ,
            T_DTL_EXCHANGE.stk_cd,
            TRUNC(T_DTL_EXCHANGE.trdg_dt) ,
            T_DTL_EXCHANGE.price,
            T_DTL_EXCHANGE.mrkt_type,
            T_DTL_EXCHANGE.org_sales_person_cd,
            T_DTL_EXCHANGE.status,
			DECODE(T_DTL_EXCHANGE.mrkt_type,'NG',buy_broker_cd,'  '),
			DECODE(T_DTL_EXCHANGE.mrkt_type,'NG',sell_broker_cd,'  ');


   CURSOR csr_settle_client(p_client_cd      MST_SETTLEMENT_CLIENT.client_cd%TYPE,
                            p_market_type    MST_SETTLEMENT_CLIENT.market_type%TYPE,
							p_ctr_type       MST_SETTLEMENT_CLIENT.ctr_type%TYPE,
							p_trans_type     VARCHAR2,
                            p_date           DATE)
   IS
     SELECT msc.csd_script due_script,
            msc.csd_value  due_value,
            msc.kds_script due_ksei,
            msc.kds_value  due_kpei
     FROM MST_SETTLEMENT_CLIENT msc
     WHERE msc.client_cd = p_client_cd
     AND   msc.market_type = p_market_type
	 AND   msc.ctr_type = p_ctr_type
	 AND   msc.sale_sts = p_trans_type
	 AND   TRUNC(msc.eff_dt) = p_date;

--    dicomment 8 dec 09
--      AND   TRUNC(msc.eff_dt) = (SELECT MAX(TRUNC(x.eff_dt) )
--                                 FROM mst_settlement_client x
--                                 WHERE x.client_cd = msc.client_cd
--                                 AND   x.market_type = msc.market_type
--                                 AND   TRUNC(x.eff_dt) <= p_date);

   CURSOR csr_settle_type(p_client_type    MST_SETTLEMENT.cl_type1%TYPE,
                          p_market_type    MST_SETTLEMENT.market_type%TYPE,
						  p_ctr_type       MST_SETTLEMENT.ctr_type%TYPE,
						  p_trans_type     VARCHAR2,
                          p_date           DATE)
   IS
     SELECT ms.csd_script due_script,
            ms.csd_value  due_value,
            ms.kds_script due_ksei,
            ms.kds_value  due_kpei
     FROM MST_SETTLEMENT ms
     WHERE ms.cl_type1 = p_client_type
     AND   ms.market_type = p_market_type
	 AND   ms.ctr_type = p_ctr_type
	 AND   ms.sale_sts = p_trans_type
     AND   TRUNC(ms.eff_dt) = (SELECT MAX(TRUNC(x.eff_dt) )
                               FROM MST_SETTLEMENT x
                               WHERE x.cl_type1 = ms.cl_type1
                               AND   x.market_type = ms.market_type
                               AND   TRUNC(x.eff_dt) <= p_date);

   CURSOR csr_counter(p_stk_cd     MST_COUNTER.stk_cd%TYPE,
                      p_stk_sts    MST_COUNTER.stk_stat%TYPE)
   IS
     SELECT mco.stk_cd,
            mco.levy_appl_flg,
            mco.pph_appl_flg,
            mco.vat_appl_flg,
            mco.lot_size
     FROM MST_COUNTER mco
     WHERE trim(mco.stk_cd) = trim(p_stk_cd);

   /*variabel untuk cari due date*/

   vdue_script        NUMBER := 0;
   vdue_value         NUMBER := 0;
   vdue_ksei          NUMBER := 0;
   vdue_kpei          NUMBER := 0;

   vdue_date_script   DATE;
   vdue_date_value    DATE;
   vdue_date_ksei     DATE;
   vdue_date_kpei     DATE;

   vcount             NUMBER := 0;
   v_trx_cnt          NUMBER := 0;

   vclient_type       VARCHAR2(4) := NULL;

   rec_settle_client  csr_settle_client%ROWTYPE;
   rec_settle_type    csr_settle_type%ROWTYPE;

   /*variable untuk calculation*/

   rec_counter        csr_counter%ROWTYPE;

   vapp_levy          CHAR(1);
   vapp_pph           CHAR(1);
   vapp_vat           CHAR(1);
   vapp_whpph23		  CHAR(1);
   vbrokerage_pct     MST_CLIENT.commission_per%TYPE;
   vlevy_pct          MST_COMPANY.levy_pct%TYPE;
   vpph_pct           MST_COMPANY.pph_pct%TYPE;
   vvat_pct           MST_COMPANY.vat_pct%TYPE;
   vwhpph23_pct		  MST_COMPANY.kom_fee_pct%TYPE;
   vwhpph23           NUMBER := 0;
   v_coy_pph_pct           MST_COMPANY.pph_pct%TYPE;
   v_coy_vat_pct           MST_COMPANY.vat_pct%TYPE;
   vbrokerage_amt     NUMBER := 0;
   vlevy_amt          NUMBER := 0;
   vpph_amt           NUMBER := 0;
   vvat_amt           NUMBER := 0;
   vcommision_amt     NUMBER := 0;
   vamtbrok           NUMBER := 0;

   vlot_size          MST_COUNTER.lot_size%TYPE;
   vodd_lot_ind       T_CONTRACTS.odd_lot_ind%TYPE;
   vstk_type          MST_COUNTER.ctr_type%TYPE;
   vstk_scripless     MST_COUNTER.stk_scripless%TYPE;
   vbranch_id         T_CONTRACTS.brch_cd%TYPE;
   vrem_type          MST_SALES.rem_type%TYPE;
   vmain_rem_cd       MST_CLIENT.rem_cd%TYPE;
   vsession_num       T_DTL_EXCHANGE.ses_num%TYPE;

   vamt_for_cur       T_CONTRACTS.amt_for_curr%TYPE;

   vcontract_num      T_CONTRACTS.contr_num%TYPE;
   vlevy_tax_amt      T_CONTRACTS.LEVY_TAX%TYPE;

   vcheck_contract    VARCHAR2(50);

   vgl_acct_cd        T_STK_MOVEMENT.gl_acct_cd%TYPE;

   v_coy_client_cd    MST_CLIENT.client_cd%TYPE;
   v_olt                          MST_CLIENT.olt%TYPE;

   v_client_type_secu_acct MST_SECU_ACCT.client_type%TYPE;
   v_stk_mvmt_type  MST_SECU_ACCT.mvmt_type%TYPE;
   v_deb_acct		T_STK_MOVEMENT.gl_acct_cd%TYPE;
   v_cre_acct		T_STK_MOVEMENT.gl_acct_cd%TYPE;
   v_doc_rem       T_STK_MOVEMENT.doc_rem%TYPE;
   v_seq1 NUMBER;
   v_seq2 NUMBER;

   v_nl				  CHAR(2);
   vneedcalcYj       BOOLEAN;
   vneedcalcQQ       BOOLEAN;
   V_SPERR			 NUMBER(2);
 --  v_short           varchar2(256);

v_err 					EXCEPTION;
v_error_code			NUMBER;
v_error_msg				VARCHAR2(1000);


BEGIN

	 v_nl := CHR(10)||CHR(13);

	 
	 BEGIN
	 SELECT COUNT(1) INTO vcount 
	 FROM T_DTL_EXCHANGE
     WHERE TRUNC(T_DTL_EXCHANGE.trdg_dt) = TRUNC(p_exchange_date)
           AND   T_DTL_EXCHANGE.con_gen_flg = 'N';
	EXCEPTION
	WHEN OTHERS THEN
				v_error_code := -9;
	       v_error_msg := SUBSTR(' select T_DTL_EXCHANGE '||SQLERRM,1,200);
           RAISE v_err;
	END;
		   
	IF vcount = 0 THEN
		   v_error_code := -8;
	       v_error_msg := SUBSTR(' no data on T DTL EXCHANGE, Belum import '||SQLERRM,1,200);
           RAISE v_err;	
	END IF;	   
	 
   BEGIN

	   SELECT trim(NVL(other_1,'X')),
	   		  NVL(pph_pct,0),
	          NVL(vat_pct,0)
	   INTO v_coy_client_cd, v_coy_pph_pct,v_coy_vat_pct
	   FROM MST_COMPANY;
        EXCEPTION
           WHEN NO_DATA_FOUND THEN
		   v_error_code := -3;
	       v_error_msg := 'no Data  in mst_company';
           RAISE v_err;
            WHEN OTHERS THEN
			v_error_code := -4;
	       v_error_msg := SUBSTR(' mst_company '||SQLERRM,1,200);
           RAISE v_err;
   
   END;

   BEGIN
   SELECT TO_NUMBER(prm_desc) INTO vwhpph23_pct
	FROM MST_PARAMETER
	WHERE prm_cd_1 = 'WHTAX'
	AND prm_cd_2 = (SELECT MAX(prm_cd_2)
				    FROM MST_PARAMETER
					WHERE prm_cd_1 = 'WHTAX'
					AND TO_DATE(prm_cd_2,'yymmdd') <= p_exchange_date);
   EXCEPTION
   WHEN NO_DATA_FOUND THEN
   		vwhpph23_pct := 0;
	WHEN OTHERS THEN
		   v_error_code := -5;
	       v_error_msg := SUBSTR(' find WHTAX on mst_parameter '||SQLERRM,1,200);
           RAISE v_err;	
   END;

	   V_SEQ1 := 1;
	   V_SEQ2 := 2;

   FOR rec_buy IN csr_buy(p_exchange_date)
   LOOP


      BEGIN
      SELECT mc.client_type_1||mc.client_type_2||mc.client_type_3 client_type,
	         mc.rem_cd,
	   		 NVL(mc.commission_per,0),
                mc.levy_appl_flg,
                mc.pph_appl_flg,
                mc.vat_appl_flg,
				mc.branch_code,
				NVL(mc.desp_pref,'N'),
				DECODE(mc.olt,'N',NULL,'Y')
      INTO vclient_type,
	       vmain_rem_cd,
		   vbrokerage_pct,
		   vapp_levy,
		   vapp_pph,
		   vapp_vat,
		   vbranch_id,
		   vapp_whpph23,
		   v_olt
      FROM MST_CLIENT mc
      WHERE mc.client_cd = rec_buy.client_cd;
	  EXCEPTION
      WHEN NO_DATA_FOUND THEN
			v_error_code := -10;
	       v_error_msg := SUBSTR(rec_buy.client_cd||' not found in  mst_client '||SQLERRM,1,200);
           RAISE v_err;
	  WHEN OTHERS THEN
			v_error_code := -15;
	       v_error_msg := SUBSTR(' select mst_client for  '||rec_buy.client_cd||SQLERRM,1,200);
           RAISE v_err;
            --RAISE_APPLICATION_ERROR(-20100,'Cannot find client_cd '||rec_buy.client_cd||' in mst_client');
      END;

       BEGIN
	   SELECT mc.ctr_type, mc.STK_SCRIPLESS
       INTO vstk_type, vstk_scripless
	   FROM MST_COUNTER mc
	   WHERE mc.stk_cd = rec_buy.stk_cd;
	  EXCEPTION
      WHEN NO_DATA_FOUND THEN
			v_error_code := -20;
	       v_error_msg := SUBSTR(rec_buy.stk_cd||' not found in  mst_counter for  '||SQLERRM,1,200);
          --  RAISE_APPLICATION_ERROR(-20100,'Cannot find stock code '||rec_buy.stk_cd||' in mst_counter');
	  WHEN OTHERS THEN
			v_error_code := -9;
	       v_error_msg := SUBSTR(' select mst_counter for  '||rec_buy.stk_cd||SQLERRM,1,200);
           RAISE v_err;
      END;

       OPEN csr_settle_client(rec_buy.client_cd,rec_buy.mrkt_type,vstk_type,'P',rec_buy.exchange_date);
       FETCH csr_settle_client INTO rec_settle_client;
       IF csr_settle_client%FOUND THEN
          vdue_script := rec_settle_client.due_script;
          vdue_value  := rec_settle_client.due_value;
          vdue_ksei   := rec_settle_client.due_ksei;
          vdue_kpei   := rec_settle_client.due_kpei;
       ELSE

          OPEN csr_settle_type(vclient_type,rec_buy.mrkt_type,vstk_type,'P',rec_buy.exchange_date);
          FETCH csr_settle_type INTO rec_settle_type;
          IF csr_settle_type%FOUND THEN
             vdue_script := rec_settle_type.due_script;
             vdue_value  := rec_settle_type.due_value;
             vdue_ksei   := rec_settle_type.due_ksei;
             vdue_kpei   := rec_settle_type.due_kpei;
          ELSE
		  v_error_code := -25;
	       v_error_msg := SUBSTR('Mst_settlement not found for client_cd = '||rec_buy.client_cd||' client type '||vclient_type||SQLERRM,1,200);
           RAISE v_err;
 --            RAISE_APPLICATION_ERROR(-20100,'Mst_settlement not found for client_cd = '||rec_buy.client_cd||' client type '||vclient_type);
          END IF;

          CLOSE csr_settle_type;

       END IF;

       CLOSE csr_settle_client;

       vdue_date_script := Get_Due_Date(vdue_script,rec_buy.exchange_date);

       IF vdue_value = vdue_script THEN
          vdue_date_value := vdue_date_script;
       ELSE
          vdue_date_value := Get_Due_Date(vdue_value,rec_buy.exchange_date);
       END IF;

       IF vdue_ksei = vdue_script THEN
          vdue_date_ksei := vdue_date_script;
       ELSIF vdue_ksei = vdue_value THEN
          vdue_date_ksei := vdue_date_value;
       ELSE
          vdue_date_ksei := Get_Due_Date(vdue_ksei,rec_buy.exchange_date);
       END IF;

       IF vdue_kpei = vdue_script THEN
          vdue_date_kpei := vdue_date_script;
       ELSIF vdue_kpei = vdue_value THEN
          vdue_date_kpei := vdue_date_value;
       ELSIF vdue_kpei = vdue_ksei THEN
          vdue_date_kpei := vdue_date_ksei;
       ELSE
          vdue_date_kpei := Get_Due_Date(vdue_kpei,rec_buy.exchange_date);
       END IF;



	   OPEN csr_counter(rec_buy.stk_cd,rec_buy.stk_status);
       FETCH csr_counter INTO rec_counter;
       IF csr_counter%FOUND THEN
          IF vapp_levy = 'Y' THEN
             vapp_levy := rec_counter.levy_appl_flg;
          END IF;
          IF vapp_vat = 'Y' THEN
             vapp_vat := rec_counter.vat_appl_flg;
          END IF;
          vlot_size := rec_counter.lot_size;
       ELSE
	   	   v_error_code := -30;
	       v_error_msg := SUBSTR('Master stock for  '||rec_buy.stk_cd||' not found',1,200);
           RAISE v_err;
 --         RAISE_APPLICATION_ERROR(-20100,'Master stock for this stock_cd '||rec_buy.stk_cd||' not found');
       END IF;
       CLOSE csr_counter;

       vvat_pct := v_coy_vat_pct;
       vpph_pct := v_coy_pph_pct;

	   vbrokerage_amt := TRUNC((rec_buy.qty * rec_buy.price) * vbrokerage_pct/10000,2);

	   vamtBrok 	:= (rec_buy.qty * rec_buy.price) + vbrokerage_amt;

	   BEGIN

		    SELECT levy_pct 		   INTO vlevy_pct
			FROM(
			SELECT  NVL(ml.levy_pct,0) levy_pct
					   FROM MST_LEVY ml
					   WHERE trim(ml.mrkt_type) = rec_buy.mrkt_type
					   AND   ml.stk_type = vstk_type
					   AND   ml.value_from <= vamtBrok
					   AND   ml.value_to >= vamtBrok
					   AND   TRUNC(ml.eff_dt) <= rec_buy.exchange_date
					   ORDER BY ml.eff_dt DESC)
					   WHERE   ROWNUM = 1;

		   EXCEPTION
	          WHEN NO_DATA_FOUND THEN
			     	   v_error_code := -35;
				       v_error_msg := SUBSTR('levy percent for  '||vstk_type||' not found in mst_levy',1,200);
			           RAISE v_err;
--	                 RAISE_APPLICATION_ERROR(-20100,'Cannot find levy_pct for stock type '||vstk_type||' in mst_levy');
			WHEN OTHERS THEN
			     	   v_error_code := -40;
				       v_error_msg := SUBSTR(' find levy percent for  '||vstk_type||' in mst_levy'||SQLERRM,1,200);
			           RAISE v_err;
			
	   END;

       IF vapp_levy = 'N' THEN
          vlevy_pct := 0;
       END IF;
       IF vapp_vat = 'N' THEN
          vvat_pct := 0;
       END IF;

       vlevy_amt 			:= TRUNC((rec_buy.qty * rec_buy.price) * vlevy_pct/10000,2);
	   IF vbrokerage_amt = 0 THEN
	      vvat_amt := 0;
		  vcommision_amt := 0;
		  vwhpph23 := 0;
	   ELSE
       	   vvat_amt 			:= TRUNC(((vbrokerage_amt - vlevy_amt) / 11),2);
           vcommision_amt := TRUNC(vbrokerage_amt - (vlevy_amt + vvat_amt),2);
		   IF vapp_whpph23 = 'Y' AND rec_buy.exchange_date > TO_DATE('30/11/08','dd/mm/yy') THEN
		  	  vwhpph23 := TRUNC((vbrokerage_amt - (vlevy_amt + vvat_amt))  * vwhpph23_pct / 100, 2);
		   ELSE
		  	  vwhpph23 := 0;
		   END IF;

	   END IF;

	   IF rec_buy.exchange_date > TO_DATE('31/12/07','dd/mm/yy') THEN
	      vlevy_tax_amt := 0;
	   ELSE
          vlevy_tax_amt	:= TRUNC((vlevy_amt * (75/100))/10, 2);
	   END IF;

	   vamt_for_cur 	:= (rec_buy.qty * rec_buy.price) + vcommision_amt + vvat_amt + vlevy_amt - vwhpph23;


--21oct14       vcontract_num  := Get_Contract_Number(rec_buy.exchange_date,'BUY','REGULAR');
       vcontract_num  := Get_Contr_Num(rec_buy.exchange_date,'BUY','REGULAR');


       /*find ses num for t_contracts*/

	   IF rec_buy.sum_session = 0 THEN
	   	  vsession_num := 1;
	   ELSE
	   	  vsession_num := 2;
	   END IF;



	   IF MOD(rec_buy.qty,vlot_size) <> 0 THEN
	      vlot_size := 0;
	      vodd_lot_ind := 'Y';
	   ELSE
	      vlot_size := rec_buy.qty/vlot_size;
		  vodd_lot_ind := 'N';
       END IF;


       /*insert to t_contracts*/

       BEGIN
           INSERT INTO T_CONTRACTS (
               ADV_PAYMT_FLG, ADV_SCRIP_FLG, AMEND_DT,
      	       KPEI_DUE_DT, KSEI_DUE_DT, AMT_FOR_CURR,
      	       BRCH_CD, BROK, BROK_PERC,
      	       CAN_AMD_FLG, CLIENT_CD, CLIENT_TYPE,
      	       COMMISSION, CONTR_DT, CONTR_NUM,
      	       CONTR_STAT, CONTRA_FLAG, CONTRA_NUM,
      	       CRE_DT, CURR_CD, DUE_DT_FOR_AMT,
      	       DUE_DT_FOR_CERT, EXCH_CD, GAIN_LOSS_AMT,
      	       GAIN_LOSS_IND, LEVY_PERC, LOT_SIZE,
      	       MRKT_TYPE, NET, ODD_LOT_IND,
      	       PAR_VAL, PAYMT_LAST_DT, PPH,
      	       PPH_PERC, PRICE, QTY,
      	       REM_CD, SCRIP_DAYS_C, SCRIP_LAST_DT,
      	       SESS_NO, SETT_FOR_CURR, SETT_QTY,
      	       SETT_VAL, SETTLE_CURR_TMP, STATUS,
      	       STK_CD, TRANS_LEVY, UPD_DT,
      	       USER_ID, VAL, VAL_STAT,
      	       VAT, PPH_OTHER_VAL, MAIN_REM_CD, RECORD_SOURCE, LEVY_TAX,
			   BUY_BROKER_CD, SELL_BROKER_CD)
           VALUES (
               NULL,NULL,NULL,
               vdue_date_kpei,vdue_date_ksei,vamt_for_cur,
               vbranch_id ,vbrokerage_amt,vbrokerage_pct,
               v_olt,  trim(rec_buy.client_cd),vclient_type,
               vcommision_amt,p_exchange_date , vcontract_num,
               '0',NULL,NULL,
               SYSDATE,'IDR',vdue_date_value,
               vdue_date_script,'IDX', NULL ,
               NULL,vlevy_pct,vlot_size,
               rec_buy.mrkt_type, rec_buy.qty * rec_buy.price, vodd_lot_ind ,
               vwhpph23_pct,NULL,vpph_amt,
               vpph_pct,rec_buy.price, rec_buy.qty,
               vmain_rem_cd, vdue_kpei, NULL,
               vsession_num, 0, 0,
               0, 0, rec_buy.stk_status,
               trim(rec_buy.stk_cd), vlevy_amt, NULL,
               p_user_id,rec_buy.qty * rec_buy.price, 'N',
               vvat_amt, vwhpph23, vmain_rem_cd , 'CG', vlevy_tax_amt,
			   rec_buy.buy_broker, rec_buy.sell_broker);
		   EXCEPTION
              WHEN OTHERS THEN
			     	   v_error_code := -45;
				       v_error_msg := SUBSTR(' Error insert T_CONTRACTS : '||vcontract_num||SQLERRM,1,200);
			           RAISE v_err;
--                  RAISE_APPLICATION_ERROR(-20100,'Error insert T_CONTRACTS : '||vcontract_num||v_nl||SQLERRM);

       END;
	   
	   v_trx_cnt  := v_trx_cnt +1;

	   BEGIN
	  Sp_Contract_Accledgerpp(vcontract_num,'D',p_user_id,v_error_code,v_error_msg);
	  EXCEPTION
	  WHEN OTHERS THEN 
			     	   v_error_code := -50;
				       v_error_msg := SUBSTR(' Sp_Contract_Accledger for : '||vcontract_num||SQLERRM,1,200);
			           RAISE v_err;
	  END;

	  IF v_error_code < 0 THEN
			           RAISE v_err;
	  END IF;
	  


	   /*insert ke t_stk_movement*/


/*       IF (trim(rec_buy.client_cd) = trim(v_coy_client_cd)) OR (SUBSTR(vclient_type,1,1) = 'H') THEN
	     vgl_acct_cd := 10;
	   ELSE
	     vgl_acct_cd := 14;
	   END IF;



	   BEGIN
	   		Sp_Jurnalstock(
	           vcontract_num,  vcontract_num,exchange_date,
	           rec_buy.client_cd, rec_buy.stk_cd,'T',
	           vodd_lot_ind, vlot_size, rec_buy.qty,
	           'CONTRACT BUY', '2','1',
	           0, NULL,
	           NULL, vgl_acct_cd,vclient_type,
	           'D', p_user_id, SYSDATE,
		    NULL, vdue_date_script, vdue_date_script,1,V_SPERR);
		   EXCEPTION
              WHEN OTHERS THEN
                  RAISE_APPLICATION_ERROR(-20100,'Error insert contract to T_STK_MOVEMENT : '||vcontract_num||v_nl||SQLERRM);
	   END;
	   IF V_SPERR < 0 THEN
                  RAISE_APPLICATION_ERROR(-20100,'Error insert contract to T_STK_MOVEMENT : '||vcontract_num||v_nl||SQLERRM);
	   END IF;

-- 	   if vstk_scripless = 'Y' then						12 APR 06
-- 		  vgl_acct_cd := 59;
-- 	   else
-- 		  vgl_acct_cd := 55;
-- 	   end if;

   	   IF rec_buy.mrkt_type = 'NG' OR rec_buy.mrkt_type = 'TS'  THEN					--29jan15 ditmbah TS
		  vgl_acct_cd := 55;
	   ELSE
		  vgl_acct_cd := 59;
	   END IF;

	   BEGIN
	   		Sp_Jurnalstock(
	           vcontract_num,  vcontract_num,exchange_date,
	           rec_buy.client_cd, rec_buy.stk_cd,'T',
	           vodd_lot_ind, vlot_size, rec_buy.qty,
	           'CONTRACT BUY', '2','1',
	           0, NULL,
	           NULL, vgl_acct_cd,vclient_type,
	           'C', p_user_id, SYSDATE,
		    NULL, vdue_date_script, vdue_date_script,2,V_SPERR);
		   EXCEPTION
              WHEN OTHERS THEN
                  RAISE_APPLICATION_ERROR(-20100,'Error insert contract to T_STK_MOVEMENT : '||vcontract_num||v_nl||SQLERRM);
	   END;
	   IF V_SPERR < 0 THEN
                  RAISE_APPLICATION_ERROR(-20100,'Error insert contract to T_STK_MOVEMENT : '||vcontract_num||v_nl||SQLERRM);
	   END IF;
*/
		       IF (trim(rec_buy.client_cd) = trim(v_coy_client_cd)) OR (SUBSTR(vclient_type,1,1) = 'H') THEN
			   	  						   v_client_type_secu_acct := 'H';
		       ELSE
			   	  						   v_client_type_secu_acct := '%';
			   END IF;

			    IF rec_buy.mrkt_type = 'NG' OR rec_buy.mrkt_type = 'TS'  THEN
							   v_stk_mvmt_type := 'TRXBN';
		       ELSE
							   v_stk_mvmt_type := 'TRXBR';
			   END IF;

			     BEGIN
				 Sp_Get_Secu_Acct(p_exchange_date, v_client_type_secu_acct,
				 							    v_stk_mvmt_type, v_deb_acct, v_cre_acct, v_error_code, v_error_msg);
				 EXCEPTION
				 WHEN OTHERS THEN
				 	  		v_error_code := -55;
							v_error_msg :=  SUBSTR('SP_GET_SECU_ACCT '||SQLERRM,1,200);
							RAISE v_err;
				 END;
				  IF v_error_code < 0 THEN
			   	  			    RAISE v_err;
			   END IF;
			   
			   BEGIN
			    SELECT SUBSTR(ledger_nar,1,40) INTO v_doc_rem
				FROM T_ACCOUNT_LEDGER
				WHERE xn_doc_num =	vcontract_num
				AND tal_id = 1;
				EXCEPTION
				WHEN OTHERS THEN
				 	  		v_error_code := -60;
							v_error_msg :=  SUBSTR('find ledger nar in T A L '||vcontract_num||SQLERRM,1,200);
							RAISE v_err;
				END;
					   
			     BEGIN
			    Sp_Secu_Jurnal_Nextg( vcontract_num,vcontract_num,p_exchange_date,
				       rec_buy.client_cd, rec_buy.stk_cd,    'T',
				      vodd_lot_ind,   vlot_size, rec_buy.qty,
					  v_doc_rem,'2',0,
					   0,NULL,NULL,
					   v_deb_acct,   vclient_type, 'D',
					   TRIM(p_user_id), SYSDATE,NULL,
					   vdue_date_script,  vdue_date_script,  V_SEQ1,
					   rec_buy.price,  'N', v_stk_mvmt_type,
					   V_SEQ2,  v_cre_acct, 'C',
				   v_error_code,v_error_msg);
			   EXCEPTION
			   		WHEN OTHERS THEN
					  	 	v_error_code := -65;
							v_error_msg :=  SUBSTR('insert  buy '||rec_buy.client_cd||' '||rec_buy.stk_cd||'  on T_STK_MOVEMENT '||SQLERRM,1,200);
							RAISE v_err;
			   END;
				  IF v_error_code < 0 THEN
			   	  			    RAISE v_err;
			   END IF;

			   
			   BEGIN
			   Sp_Upd_T_Stkhand(
			   rec_buy.client_cd, rec_buy.stk_cd, '%',
			   NULL, rec_buy.qty,  	v_stk_mvmt_type,
			   	P_USER_ID, v_error_code,v_error_msg);
				EXCEPTION
			   		WHEN OTHERS THEN
					  	 	v_error_code := -70;
							v_error_msg :=  SUBSTR('iSp_Upd_T_Stkhand '||rec_buy.client_cd||' '||rec_buy.stk_cd||SQLERRM,1,200);
							RAISE v_err;
			   END;
				  IF v_error_code < 0 THEN
			   	  			    RAISE v_err;
			   END IF;


   END LOOP;


   /*cursor sell begin*/
   FOR rec_sell IN csr_sell(p_exchange_date)
   LOOP

   	  BEGIN
      SELECT mc.client_type_1||mc.client_type_2||mc.client_type_3 client_type,
	         mc.rem_cd,
	   		 NVL(mc.commission_per,0) commision_pct,
                mc.levy_appl_flg,
                mc.pph_appl_flg,
                mc.vat_appl_flg,
				mc.branch_code,
				NVL(mc.desp_pref,'N'),
				DECODE(mc.olt,'N',NULL,'Y')
      INTO vclient_type,
	       vmain_rem_cd,
		   vbrokerage_pct,
		   vapp_levy,
		   vapp_pph,
		   vapp_vat,
		   vbranch_id,
		   vapp_whpph23,
		   v_olt
      FROM MST_CLIENT mc
      WHERE mc.client_cd = rec_sell.client_cd;
	  EXCEPTION
	        WHEN NO_DATA_FOUND THEN
			v_error_code := -100;
	       v_error_msg := SUBSTR(rec_sell.client_cd||' not found in  mst_client '||SQLERRM,1,200);
           RAISE v_err;
	  WHEN OTHERS THEN
			v_error_code := -105;
	       v_error_msg := SUBSTR(' select mst_client for  '||rec_sell.client_cd||SQLERRM,1,200);
           RAISE v_err;
	  
--            RAISE_APPLICATION_ERROR(-20100,'Cannot find client_cd '||rec_sell.client_cd||' in mst_client');
       END;

	  BEGIN
	  SELECT mc.ctr_type, mc.stk_scripless
      INTO vstk_type, vstk_scripless
	  FROM MST_COUNTER mc
	  WHERE mc.stk_cd = rec_sell.stk_cd;
      EXCEPTION
      WHEN NO_DATA_FOUND THEN
			v_error_code := -110;
	       v_error_msg := SUBSTR(rec_sell.stk_cd||' not found in  mst_counter for  '||SQLERRM,1,200);
	  WHEN OTHERS THEN
			v_error_code := -115;
	       v_error_msg := SUBSTR(' select mst_counter for  '||rec_sell.stk_cd||SQLERRM,1,200);
           RAISE v_err;
	  
--            RAISE_APPLICATION_ERROR(-20100,'Cannot find stock code '||rec_sell.stk_cd||' in mst_counter');
      END;

      OPEN csr_settle_client(rec_sell.client_cd,rec_sell.mrkt_type,vstk_type,'S',rec_sell.exchange_date);
       FETCH csr_settle_client INTO rec_settle_client;
       IF csr_settle_client%FOUND THEN
          vdue_script := rec_settle_client.due_script;
          vdue_value  := rec_settle_client.due_value;
          vdue_ksei   := rec_settle_client.due_ksei;
          vdue_kpei   := rec_settle_client.due_kpei;
       ELSE

          OPEN csr_settle_type(vclient_type,rec_sell.mrkt_type,vstk_type,'S',rec_sell.exchange_date);
          FETCH csr_settle_type INTO rec_settle_type;
          IF csr_settle_type%FOUND THEN
             vdue_script := rec_settle_type.due_script;
             vdue_value  := rec_settle_type.due_value;
             vdue_ksei   := rec_settle_type.due_ksei;
             vdue_kpei   := rec_settle_type.due_kpei;
          ELSE
		  v_error_code := -120;
	       v_error_msg := SUBSTR('Mst_settlement not found for client_cd = '||rec_sell.client_cd||' client type '||vclient_type||SQLERRM,1,200);
           RAISE v_err;

--             RAISE_APPLICATION_ERROR(-20100,'Mst_settlement not found for client_cd = '||rec_sell.client_cd);
          END IF;

          CLOSE csr_settle_type;

       END IF;

       CLOSE csr_settle_client;

       vdue_date_script := Get_Due_Date(vdue_script,rec_sell.exchange_date);

       IF vdue_value = vdue_script THEN
          vdue_date_value := vdue_date_script;
       ELSE
          vdue_date_value := Get_Due_Date(vdue_value,rec_sell.exchange_date);
       END IF;

       IF vdue_ksei = vdue_script THEN
          vdue_date_ksei := vdue_date_script;
       ELSIF vdue_ksei = vdue_value THEN
          vdue_date_ksei := vdue_date_value;
       ELSE
          vdue_date_ksei := Get_Due_Date(vdue_ksei,rec_sell.exchange_date);
       END IF;

       IF vdue_kpei = vdue_script THEN
          vdue_date_kpei := vdue_date_script;
       ELSIF vdue_kpei = vdue_value THEN
          vdue_date_kpei := vdue_date_value;
       ELSIF vdue_kpei = vdue_ksei THEN
          vdue_date_kpei := vdue_date_ksei;
       ELSE
          vdue_date_kpei := Get_Due_Date(vdue_kpei,rec_sell.exchange_date);
       END IF;

--        begin
--
--          select nvl(mc.commission_per,0) commision_pct,
--                 mc.levy_appl_flg,
--                 mc.pph_appl_flg,
--                 mc.vat_appl_flg
--          into vbrokerage_pct,vapp_levy,vapp_pph,vapp_vat
--          from mst_client mc
--          where mc.client_cd = rec_sell.client_cd;
--
--        exception
--        when no_data_found then
--             raise_application_error(-20100,'Cannot find client_cd '||rec_sell.client_cd||' in mst_client');
--        end;

	   OPEN csr_counter(rec_sell.stk_cd,rec_sell.stk_status);
       FETCH csr_counter INTO rec_counter;
       IF csr_counter%FOUND THEN
          IF vapp_levy = 'Y' THEN
             vapp_levy := rec_counter.levy_appl_flg;
          END IF;
          IF vapp_pph = 'Y' THEN
             vapp_pph := rec_counter.pph_appl_flg;
          END IF;
          IF vapp_vat = 'Y' THEN
             vapp_vat := rec_counter.vat_appl_flg;
          END IF;
          vlot_size := rec_counter.lot_size;
       ELSE
	   	   v_error_code := -125;
	       v_error_msg := SUBSTR('Master stock for  '||rec_sell.stk_cd||' not found',1,200);
           RAISE v_err;
	   
--          RAISE_APPLICATION_ERROR(-20100,'Master stock for this stock_cd '||rec_sell.stk_cd||' not found');
       END IF;
       CLOSE csr_counter;

	   vvat_pct := v_coy_vat_pct;
       vpph_pct := v_coy_pph_pct;

--        begin
--
--          select nvl(mco.pph_pct,0),
--                 nvl(mco.vat_pct,0)
--          into vpph_pct,vvat_pct
--          from mst_company mco
--          where mco.kd_broker = broker_cd;
--
--          exception
--             when no_data_found then
--                  raise_application_error(-20100,'Cannot find broker_cd '||broker_cd||' in mst_company');
--        end;

	   IF vapp_pph = 'N' THEN
          vpph_pct := 0;
       END IF;

	   IF vbrokerage_pct = 0 THEN
	      vbrokerage_amt := 0;
	   ELSE
	   	  vbrokerage_amt := TRUNC((rec_sell.qty * rec_sell.price) * (vbrokerage_pct + vpph_pct)/10000,2);
	   END IF;

	   vamtbrok := (rec_sell.qty * rec_sell.price) - vbrokerage_amt;

	   BEGIN

		    SELECT levy_pct 		   INTO vlevy_pct
			FROM(
			SELECT  NVL(ml.levy_pct,0) levy_pct
					   FROM MST_LEVY ml
					   WHERE trim(ml.mrkt_type) = rec_sell.mrkt_type
					   AND   ml.stk_type = vstk_type
					   AND   ml.value_from <= vamtBrok
					   AND   ml.value_to >= vamtBrok
					   AND   TRUNC(ml.eff_dt) <= rec_sell.exchange_date
					   ORDER BY ml.eff_dt DESC)
					   WHERE   ROWNUM = 1;


	   EXCEPTION
            WHEN NO_DATA_FOUND THEN
			     	   v_error_code := -130;
				       v_error_msg := SUBSTR('levy percent for  '||vstk_type||' not found in mst_levy',1,200);
			           RAISE v_err;
			WHEN OTHERS THEN
			     	   v_error_code := -135;
				       v_error_msg := SUBSTR(' find levy percent for  '||vstk_type||' in mst_levy'||SQLERRM,1,200);
			           RAISE v_err;
			
--                 RAISE_APPLICATION_ERROR(-20100,'Cannot find levy_pct for stock type '||vstk_type||' in mst_levy');

	   END;

       IF vapp_levy = 'N' THEN
          vlevy_pct := 0;
       END IF;

       IF vapp_vat = 'N' THEN
          vvat_pct := 0;
       END IF;


       vpph_amt := TRUNC((rec_sell.qty * rec_sell.price) * vpph_pct/10000,2);
       vlevy_amt := TRUNC((rec_sell.qty * rec_sell.price) * vlevy_pct/10000,2);
	   IF vbrokerage_amt = 0 THEN
	   	  vvat_amt := 0;
		  vcommision_amt := 0;
		  vwhpph23 := 0;
	   ELSE
	       vvat_amt := TRUNC( ((vbrokerage_amt - (vpph_amt + vlevy_amt)) / 11),2);
	       vcommision_amt := TRUNC(vbrokerage_amt - (vlevy_amt + vpph_amt + vvat_amt), 2);
		   IF vapp_whpph23 = 'Y' AND rec_sell.exchange_date > TO_DATE('30/11/08','dd/mm/yy') THEN
		  	 vwhpph23 := TRUNC((vbrokerage_amt - (vlevy_amt + vpph_amt + vvat_amt))  * vwhpph23_pct / 100, 2);
		   ELSE
		     vwhpph23 := 0;
		   END IF;

	   END IF;


	   vamt_for_cur := (rec_sell.qty * rec_sell.price) - vcommision_amt - vvat_amt - vlevy_amt - vpph_amt  + vwhpph23;
       IF rec_sell.exchange_date > TO_DATE('31/12/07','dd/mm/yy') THEN
	      vlevy_tax_amt := 0;
	   ELSE
	      vlevy_tax_amt	:= TRUNC((vlevy_amt * (75/100))/10,2);
	   END IF;


--21oct14       vcontract_num  := Get_Contract_Number(rec_sell.exchange_date,'SELL','REGULAR');
       vcontract_num  := Get_Contr_Num(rec_sell.exchange_date,'SELL','REGULAR');


       /*find ses num for t_contracts*/
	   IF rec_sell.sum_session = 0 THEN
	   	  vsession_num := 1;
	   ELSE
	   	  vsession_num := 2;
	   END IF;


	   IF MOD(rec_sell.qty,vlot_size) <> 0 THEN
	      vlot_size := 0;
	      vodd_lot_ind := 'Y';
	   ELSE
	      vlot_size := rec_sell.qty/vlot_size;
		  vodd_lot_ind := 'N';
       END IF;


       /*insert to t_contracts*/

       BEGIN

           INSERT INTO T_CONTRACTS (
                  ADV_PAYMT_FLG, ADV_SCRIP_FLG, AMEND_DT,
                  KPEI_DUE_DT, KSEI_DUE_DT, AMT_FOR_CURR,
                  BRCH_CD, BROK, BROK_PERC,
                  CAN_AMD_FLG, CLIENT_CD, CLIENT_TYPE,
                  COMMISSION, CONTR_DT, CONTR_NUM,
                  CONTR_STAT, CONTRA_FLAG, CONTRA_NUM,
                  CRE_DT, CURR_CD, DUE_DT_FOR_AMT,
                  DUE_DT_FOR_CERT, EXCH_CD, GAIN_LOSS_AMT,
                  GAIN_LOSS_IND, LEVY_PERC, LOT_SIZE,
                  MRKT_TYPE, NET, ODD_LOT_IND,
                  PAR_VAL, PAYMT_LAST_DT, PPH,
                  PPH_PERC, PRICE, QTY,
                  REM_CD, SCRIP_DAYS_C, SCRIP_LAST_DT,
                  SESS_NO, SETT_FOR_CURR, SETT_QTY,
                  SETT_VAL, SETTLE_CURR_TMP, STATUS,
                  STK_CD, TRANS_LEVY, UPD_DT,
                  USER_ID, VAL, VAL_STAT,
                  VAT, PPH_OTHER_VAL, MAIN_REM_CD, RECORD_SOURCE, LEVY_TAX,
				  BUY_BROKER_CD, SELL_BROKER_CD)
           VALUES(
                  NULL, NULL, NULL,
                  vdue_date_kpei,vdue_date_ksei,vamt_for_cur,
                  vbranch_id ,vbrokerage_amt,vbrokerage_pct,
                  v_olt, trim(rec_sell.client_cd),vclient_type,
                  vcommision_amt,p_exchange_date , vcontract_num,
                  '0',NULL,NULL,
                  SYSDATE,'IDR',vdue_date_value,
                  vdue_date_script,'IDX', NULL ,
                  NULL, vlevy_pct,vlot_size,
                  rec_sell.mrkt_type, rec_sell.qty * rec_sell.price, vodd_lot_ind,
                  vwhpph23_pct, NULL, vpph_amt,
                  vpph_pct, rec_sell.price, rec_sell.qty,
                  vmain_rem_cd , vdue_kpei, NULL,
                  vsession_num, NULL, 0,
                  0, NULL, rec_sell.stk_status,
                  trim(rec_sell.stk_cd), vlevy_amt, NULL,
                  p_user_id, rec_sell.qty * rec_sell.price, 'N',
                  vvat_amt, vwhpph23, vmain_rem_cd , 'CG', vlevy_tax_amt,
        		   rec_sell.buy_broker, rec_sell.sell_broker);
		   EXCEPTION
              WHEN OTHERS THEN
			     	   v_error_code := -140;
				       v_error_msg := SUBSTR(' Error insert T_CONTRACTS : '||vcontract_num||SQLERRM,1,200);
			           RAISE v_err;
			  
--                  RAISE_APPLICATION_ERROR(-20100,'Error insert T_CONTRACTS : '||vcontract_num||v_nl||SQLERRM);

       END;
	   
	   v_trx_cnt := v_trx_cnt + 1;

    BEGIN
	  Sp_Contract_Accledgerpp(vcontract_num,'C',p_user_id,v_error_code,v_error_msg);
	  EXCEPTION
	  WHEN OTHERS THEN 
			     	   v_error_code := -145;
				       v_error_msg := SUBSTR(' Sp_Contract_Accledger for : '||vcontract_num||SQLERRM,1,200);
			           RAISE v_err;
	  END;

	  IF v_error_code < 0 THEN
			           RAISE v_err;
	  END IF;


  	   /*insert ke t_stk_movement*/


--        if vstk_scripless = 'Y' then						  12 apr 06
--           vgl_acct_cd := 21;
-- 	   else
--   	   	  vgl_acct_cd := 17;
-- 	   end if;

/*
	   IF rec_sell.mrkt_type = 'NG' OR rec_sell.mrkt_type = 'TS'  THEN					-- 29jan15 tambah TS
	   	  vgl_acct_cd := 17;
	   ELSE
	   	   vgl_acct_cd := 21;
	   END IF;

	   BEGIN
  		   Sp_Jurnalstock (
		             vcontract_num,  vcontract_num,p_exchange_date,
	             rec_sell.client_cd, rec_sell.stk_cd,'T',
	             vodd_lot_ind, vlot_size, rec_sell.qty,
	             'CONTRACT SELL', '2','1',
	             0, NULL,
	             NULL, vgl_acct_cd,vclient_type,
	             'D', p_user_id, SYSDATE,
			 NULL, vdue_date_script, vdue_date_script,1,V_SPERR);
			 EXCEPTION
              WHEN OTHERS THEN
                  RAISE_APPLICATION_ERROR(-20100,'Error insert contract to T_STK_MOVEMENT : '||vcontract_num||v_nl||SQLERRM);
	   END;
	   IF V_SPERR < 0 THEN
          RAISE_APPLICATION_ERROR(-20100,'Error insert contract to T_STK_MOVEMENT : '||vcontract_num||v_nl||SQLERRM);
	   END IF;

	   IF (trim(rec_sell.client_cd) = trim(v_coy_client_cd)) OR (SUBSTR(vclient_type,1,1) = 'H') THEN
	     vgl_acct_cd := 10;
	   ELSE
		 vgl_acct_cd := 51;
	   END IF;

	   BEGIN
  		   Sp_Jurnalstock (
	             vcontract_num,  vcontract_num,p_exchange_date,
	             rec_sell.client_cd, rec_sell.stk_cd,'T',
	             vodd_lot_ind, vlot_size, rec_sell.qty,
	             'CONTRACT SELL', '2','1',
	             0, NULL,
	             NULL, vgl_acct_cd,vclient_type,
	             'C', p_user_id, SYSDATE,
			 NULL, vdue_date_script, vdue_date_script,2,V_SPERR);
			 EXCEPTION
              WHEN OTHERS THEN
                  RAISE_APPLICATION_ERROR(-20100,'Error insert contract to T_STK_MOVEMENT : '||vcontract_num||v_nl||SQLERRM);
	   END;
	   IF V_SPERR < 0 THEN
                RAISE_APPLICATION_ERROR(-20100,'Error insert contract to T_STK_MOVEMENT :'||TO_CHAR(V_SPERR)||vcontract_num||v_nl||SQLERRM);
	   END IF;
*/

		       IF (trim(rec_sell.client_cd) = trim(v_coy_client_cd)) OR (SUBSTR(vclient_type,1,1) = 'H') THEN
			   	  						   v_client_type_secu_acct := 'H';
		       ELSE
			   	  						   v_client_type_secu_acct := '%';
			   END IF;

			    IF rec_sell.mrkt_type = 'NG' OR rec_sell.mrkt_type = 'TS'  THEN
							   v_stk_mvmt_type := 'TRXJN';
		       ELSE
							   v_stk_mvmt_type := 'TRXJR';
			   END IF;

			     BEGIN
				 Sp_Get_Secu_Acct(p_exchange_date, v_client_type_secu_acct,
				 							    v_stk_mvmt_type, v_deb_acct, v_cre_acct, v_error_code, v_error_msg);
				 EXCEPTION
				 WHEN OTHERS THEN
				 	  		  v_error_code := -150;
							v_error_msg :=  SUBSTR('SP_GET_SECU_ACCT '||SQLERRM,1,200);
							RAISE v_err;
				 END;
				  IF v_error_code < 0 THEN
			   	  			    RAISE v_err;
			   END IF;


			   BEGIN
			    SELECT SUBSTR(ledger_nar,1,40) INTO v_doc_rem
				FROM T_ACCOUNT_LEDGER
				WHERE xn_doc_num =	vcontract_num
				AND tal_id = 1;
				EXCEPTION
				WHEN OTHERS THEN
				 	  		v_error_code := -155;
							v_error_msg :=  SUBSTR('find ledger nar in T A L '||vcontract_num||SQLERRM,1,200);
							RAISE v_err;
				END;


			     BEGIN
			    Sp_Secu_Jurnal_Nextg( vcontract_num,vcontract_num,p_exchange_date,
				       rec_sell.client_cd, rec_sell.stk_cd,    'T',
				      vodd_lot_ind,   vlot_size, rec_sell.qty,
					  v_doc_rem,'2',0,
					   0,NULL,NULL,
					   v_deb_acct,   vclient_type, 'D',
					   TRIM(p_user_id), SYSDATE,NULL,
					   vdue_date_script,  vdue_date_script,  V_SEQ1,
					   rec_sell.price,  'N', v_stk_mvmt_type,
					   V_SEQ2,  v_cre_acct, 'C',
				   v_error_code,v_error_msg);
			   EXCEPTION
			   		WHEN OTHERS THEN
					  	 	v_error_code := -160;
							v_error_msg :=  SUBSTR('insert  buy '||rec_sell.client_cd||' '||rec_sell.stk_cd||'  on T_STK_MOVEMENT '||SQLERRM,1,200);
							RAISE v_err;
			   END;
				  IF v_error_code < 0 THEN
			   	  			    RAISE v_err;
			   END IF;

			   BEGIN
			   Sp_Upd_T_Stkhand(
			   rec_sell.client_cd, rec_sell.stk_cd, '%',
			   NULL, rec_sell.qty,  	v_stk_mvmt_type,
			   	P_USER_ID, v_error_code,v_error_msg);
				EXCEPTION
			   		WHEN OTHERS THEN
					  	 	v_error_code := -165;
							v_error_msg :=  SUBSTR('iSp_Upd_T_Stkhand '||rec_sell.client_cd||' '||rec_sell.stk_cd||SQLERRM,1,200);
							RAISE v_err;
			   END;
				  IF v_error_code < 0 THEN
			   	  			    RAISE v_err;
			   END IF;



		       IF (trim(rec_sell.client_cd) = v_coy_client_cd)  THEN
			      vNeedCalcYJ := TRUE;
			   END IF;
-- 	   IF  (SUBSTR(vclient_type,1,1) = 'H') THEN
-- 	      vNeedCalcQQ := TRUE;
-- 	   END IF;
   END LOOP;


--- utk con_gen manual harap remark baris ini
   vcheck_contract := Chek_Generated_Contract(p_exchange_date);
   IF vcheck_contract <> 'MATCH' THEN
       v_error_code := -170;
		v_error_msg :=  'Contracts do not match with exchanges';
		RAISE v_err;
       --RAISE_APPLICATION_ERROR(-20010,'Contracts do not match with exchanges');
   END IF;
--- sampai sini

-- UPDATE CON_GEN_FLG
   BEGIN
   UPDATE T_DTL_EXCHANGE
       SET con_gen_flg = 'Y'
       WHERE TRUNC(trdg_dt) = p_exchange_date;
   EXCEPTION
      WHEN OTHERS THEN
	  v_error_code := -175;
  	  v_error_msg :=  SUBSTR('Error update T_DTL_EXCHANGE '||v_nl||SQLERRM,1,200);
	  RAISE v_err;
      --RAISE_APPLICATION_ERROR(-20100,'Error update T_DTL_EXCHANGE '||v_nl||SQLERRM);
   END;

   --- utk con_gen manual harap remark baris ini

   -- 6sep12 dipindahkan seblm gen labarugi, spy klo genlabarugi macet, sp ini sdh jalan
--     Sp_Upd_T0stkhand(p_exchange_date, p_user_id,V_SPERR);
-- 	IF V_SPERR <> 1 THEN
-- 	      RAISE_APPLICATION_ERROR(-20010,'Error executing procedure sp_upd_t0stkhand');
-- 	--   	  ROLLBACK;
-- 	END IF;

--    IF vNeedCalcYJ = TRUE THEN
--       BEGIN
--       Sp_Gen_Labarugi_Pe(p_exchange_date, p_user_id,v_error_code,v_error_msg);
-- 	  EXCEPTION
-- 	  WHEN OTHERS THEN
-- 	     RAISE;
-- 	  END;
--    END IF;

--    if vNeedCalcQQ = true then
--       GEN_QQ_LABARUGI(exchange_date,  p_user_id, v_short);
--    end if;



--    IF p_exchange_Date < TO_DATE('01/10/2010','DD/MM/YYYY') THEN
--       Gen_Min_Fee(p_exchange_date,p_exchange_date,'%','_','B','J',p_user_id);
--    END IF;

-- sampai sini

   		  p_trx_cnt := v_trx_cnt;
		  p_error_code := 1;
		  p_error_msg := '';

EXCEPTION
	WHEN v_err THEN
       p_error_code := v_error_code;
	   p_error_msg :=  v_error_msg;
	   ROLLBACK;   
    WHEN OTHERS THEN
       ROLLBACK;
	   p_error_code := -1;
	   p_error_msg := SUBSTR(SQLERRM,1,200);
       RAISE;


END Sp_Contract_Generation;
