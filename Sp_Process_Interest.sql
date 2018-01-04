create or replace PROCEDURE Sp_Process_Interest(
      p_client_cd   ipnextg.MST_CLIENT.client_cd%TYPE,
		  p_bgn_date    ipnextg.T_ACCOUNT_LEDGER.doc_date%TYPE,
		  p_end_date    ipnextg.T_ACCOUNT_LEDGER.doc_date%TYPE,
		  p_close_date	ipnextg.T_ACCOUNT_LEDGER.doc_date%TYPE,
          p_brch_cd     ipnextg.MST_BRANCH.brch_cd%TYPE,
          p_cancel_posted_interest ipnextg.T_ACCOUNT_LEDGER.approved_sts%Type,
		  p_user_id     ipnextg.T_ACCOUNT_LEDGER.user_id%TYPE,
		  p_ip_address  ipnextg.T_MANY_HEADER.IP_ADDRESS%TYPE,
		  o_client_cnt  OUT NUMBER,
		  p_error_code OUT NUMBER,
		  p_error_msg  OUT VARCHAR2)
IS
-- 2 may 2017 SP_PROC_INT_T_INTEREST_UPD diganti SP_INTEREST_PROCESS_UPD
-- DEC 2016 
--       calculation selalu dimulai tgl 1
--       tdk ada pilihan client type D
--       INT_DEB_ACCUM di T INTEREST baris tgl 1, dipakai utk balance carried fwd dr bulan lalu
--           disebut jg beginning balance
--       OVR_flg asumsi tidak dipakai lagi
--       POST_FLG berisi Y jika posting pakai piiihan Posting month end
--
--        jika CALC Selected client dan interest worksheet yg akan di calc, sdh diposting
--        POST_FLG = Y, tampil konfirmasi message, apa tetap akan di calc.
--                                 jika tetap akan di calc,  p_cancel_posted_interest = Y , else N


--  Oct2016 pakai Temp table
--  25may15 koreksi pd F_calc_interest : IF a_deposit > 0 then --
-- 30JAN 2015 pakai DEPOSIT

-- modifikasi 11 Jan 2010 - bunga tunggal mulai berlaku 01 jan 2010
--             int_accumulated dari existing client, jika berisi Y, dianggap N
--             Parameter P_SOA: jika Y, beginning balance diambil dr T_DAY_TRS dan T_A_L
--                                      hanya berlaku utk proses satu client    
--                              jika N, diambil dr T_INTEREST
--                                      berlaku utk proses semua client
--                              sp proses_interest_2 tidak dipakai lagi
--    
-- modifikasi  OCTOBER 2008 :
--	
-- 			  dapat process secara BATCH, jika p_client_cd diisi BATCH
--			  jika BATCH, periode yg di proses mengikuti bulannya sysdate database
--			  process secara BATCH utk periode NOVEMBER 2008
--
--			  Hanya utk process client yang BUKAN DEPOSIT
--			  BATCH Belum dipakai 

-- 			   process utk client deposit (client_type_3 ), period sama dg tgl calendar
--			   utk client non deposit, int_cre_accum diisi - ini utk statement of account n client limit   

-- modifikasi  NOVEMBER 2008 :

-- 			   periode interest non deposit menjadi 31oct08 - 30 nov 08 
--			   utk bln Dec 08 - period menjadi sama dengan calendar date 


-- PROCEDURE untuk PROCESS INTEREST mulai NOV 2005
-- perubahan :
-- INT_ACCCUM - 2 decimal
-- interest dihitung s/d hari kerja terahir minus satu
--          misalnya : hari kerja terahir SENIN 31 OCT , interest dihitung s/d 28 Oct,
--          karena 29 hari sabtu, 30 oct hr minggu
--          posting date /journal date = 31 Oct , hari kerja terahir
--          Bulan selanjutnya dihitung mulai dr 29 Oct
--  Interest AP (saldo credit/ minus) dihitung dg bunga berbunga / bunga majemuk
--          Kolom int_cre_accum dan int_deb_accum tidak dipakai lagi
--          kolom int_cre_accum hanya dipakai di bln NOV 2005 utk mengambil interest credit/ AP
--          bulan SEp , yg diakumulasi ke int_accum (SALDO) 1 NOV 2005
--       PERKECUALIAN : untuk CLIENT DEPOSIT (client yg tidak melakukan transaksi,
--          hanya menyimpan uang di YJ), interest AP tidak dihitung bunga berbunga, tapi bunga tunggal
--          Bunga hanya ditambahkan tiap bulan, jika bunga tidak diambil
--          Client Deposit ditandai dgn INT_ACCUMULATED = 'N'
--
-- OFF BALANCE SHEET CLIENT - hanya create tg terahir dan INT_ACCUM = saldo akhir
--

vp_client_cd  ipnextg.MST_CLIENT.client_cd%TYPE;
v_tmp_client_cd ipnextg.MST_CLIENT.client_cd%TYPE;
v_stamp_client	ipnextg.MST_CLIENT.client_cd%TYPE;
vp_bgn_date    ipnextg.T_ACCOUNT_LEDGER.doc_date%TYPE;
vp_end_date    ipnextg.T_ACCOUNT_LEDGER.doc_date%TYPE;

   CURSOR csr_detail(a_client_cd IN VARCHAR2, a_bgn_date IN DATE, a_end_date IN DATE)
   IS
   	 SELECT INT_DT, INT_VALUE AS int_adjust,  INT_ACCUM, TODAY_TRX, NONTRX, NVL(sett_int_cre, 0) AS sett_int_cre,
            ABS(NVL(deposit,0)) deposit
     FROM T_INTEREST
     WHERE client_cd = trim(a_client_cd)
     AND post_flg = 'E'
     AND int_dt BETWEEN a_bgn_date AND a_end_date
     ORDER BY int_dt;


  CURSOR csr_client(as_bgn_client ipnextg.T_CONTRACTS.client_cd%TYPE,
                    as_end_client ipnextg.T_CONTRACTS.client_cd%TYPE)
  IS
  	SELECT m.client_cd
	FROM( SELECT DISTINCT client_cd
	      FROM T_INTEREST
        WHERE  post_flg = 'Y' 
        AND int_dt BETWEEN p_bgn_date AND p_end_date) t,
		   ipnextg.MST_CLIENT m
	WHERE m.client_cd BETWEEN as_bgn_client AND as_end_client
--   AND trim(m.branch_code) = 'JK'
	AND (NVL(M.INT_ON_RECEIVABLE,0) <> 0 OR NVL(M.INT_ON_PAYABLE,0) <> 0)
	AND NVL(AMT_INT_FLG,'Y') = 'Y'
	AND NVL(SUSP_STAT,'N') = 'N'
  AND  client_type_3 <> 'D'  
--  AND ((m.client_type_3 = 'D'  AND p_client_cd = 'D') OR
--         (m.client_type_3 <> 'D' AND p_client_cd = '%' ) OR
--         (p_client_cd <> 'D' AND p_client_cd <> '%' ))
	AND m.client_cd = t.client_cd (+)
	AND t.client_cd IS NULL
    order by m.client_cd;
	
--	and ( post_flg <> 'Y' and (int_dt between a_bgn_date and a_end_date));

  CURSOR csr_rate (as_client_cd ipnextg.T_CONTRACTS.client_cd%TYPE,
                   ad_bgn_dt    DATE,
				   ad_end_dt    DATE)
  IS
  		SELECT EFF_DT, INT_ON_RECEIVABLE, INT_ON_PAYABLE
			FROM ipnextg.T_INTEREST_RATE
			WHERE CLIENT_Cd = as_client_cd
			AND EFF_DT >= (SELECT NVL(MAX(EFF_DT), ad_bgn_dt)
                                      FROM ipnextg.T_INTEREST_RATE
                                     WHERE EFF_DT <= ad_bgn_dt
                                     AND client_Cd = as_client_cd
                                     AND APPROVED_STAT='A')
			AND EFF_DT < (ad_end_dt + 1)
      AND APPROVED_STAT='A'
		  ORDER BY EFF_DT;



  TYPE t_rate_table IS TABLE OF csr_rate%ROWTYPE INDEX BY BINARY_INTEGER;

  v_rate_table t_rate_table;

  v_detail									csr_detail%ROWTYPE;
  v_client										csr_client%ROWTYPE;
  v_rate_rec                                csr_rate%ROWTYPE;

  v_int_day									T_INTEREST.int_day%TYPE;
  v_int_amt									T_INTEREST.int_amt%TYPE;
  v_pay_annual_days					ipnextg.MST_CLIENT.INT_PAY_DAYS%TYPE;
  v_rec_annual_days					ipnextg.MST_CLIENT.INT_REC_DAYS%TYPE;
  v_client_type_3					  ipnextg.MST_CLIENT.client_type_3%TYPE;
  v_int_pay									ipnextg.MST_CLIENT.INT_ON_PAYABLE%TYPE;
  v_int_rec									ipnextg.MST_CLIENT.INT_ON_RECEIVABLE%TYPE;
  v_int_accumulated					ipnextg.MST_CLIENT.INT_ACCUMULATED%TYPE;
  v_off_bal_sh              ipnextg.MST_CLIENT.AMT_INT_FLG%TYPE;
  v_today_mvmt				        T_INTEREST.today_trx%TYPE;
--  v_principal_accum				  t_interest.INT_VALUE%type;
  v_int_amt_prev						T_INTEREST.int_amt%TYPE;
  v_int_flg					        T_INTEREST.int_flg%TYPE;
  v_post_flg				        T_INTEREST.post_flg%TYPE;
  v_max_int_date						DATE;
  iday									    NUMBER;
  v_int_accum   		        T_INTEREST.int_amt%TYPE;
  v_int_accum_prev 		      T_INTEREST.int_amt%TYPE;
  v_int_cre_accum_prev      T_INTEREST.int_cre_accum%TYPE;
  v_int_cre_accum           T_INTEREST.int_cre_accum%TYPE;
  v_int_deb_accum_prev      T_INTEREST.int_deb_accum%TYPE;
  v_int_deb_accum           T_INTEREST.int_deb_accum%TYPE;
  v_int_adjust						  T_INTEREST.int_value%TYPE;
  v_int_adj_accum					  T_INTEREST.int_value%TYPE;
  v_int_adj_accum_prev			T_INTEREST.int_value%TYPE;

  v_min_amt                       T_INTEREST.int_deb_accum%TYPE;

  v_last_dt								DATE;
  v_rtn									  NUMBER;
  v_new       						BOOLEAN; -- new month or new client
  v_int_dt								DATE;
  v_trx_cnt                             NUMBER;
  v_client_cnt                          NUMBER;
  v_record_cnt                          NUMBER;
  v_bgn_day                             NUMBER;
  v_end_day                             NUMBER;

  v_insert							BOOLEAN;
  --v_nl									CHAR(2);
  v_GL_BAL              CHAR(1);
  v_prefix_client       varchar2(1);
  v_all_client          varchar2(2);
  vstr                  VARCHAR2(15);
  v_brch_cd             varchar2(2);
  v_bgn_client ipnextg.T_CONTRACTS.client_cd%TYPE;
  v_end_client ipnextg.T_CONTRACTS.client_cd%TYPE;
  v_int_mmyy   T_INTEREST.xn_doc_num%TYPE;
  v_beg_bal    ipnextg.T_ACCOUNT_LEDGER.curr_val%TYPE;
  v_start_date          DATE;
  v_round               char(1);

  v_err EXCEPTION;
  v_error_code NUMBER;
  v_error_msg VARCHAR2(200);
  v_menu_name ipnextg.T_MANY_HEADER.MENU_NAME%TYPE:='INTEREST PROCESS';
  V_UPDATE_DATE ipnextg.T_MANY_HEADER.UPDATE_DATE%TYPE;
  V_UPDATE_SEQ ipnextg.T_MANY_HEADER.UPDATE_SEQ%TYPE;

  FUNCTION f_Calc_interest (a_int_accumulated IN ipnextg.MST_CLIENT.INT_ACCUMULATED%TYPE,
  		   			a_int_dt          IN T_INTEREST.int_dt%TYPE,
							a_int_amt_prev    IN T_INTEREST.int_amt%TYPE,
							a_int_accum_prev  IN T_INTEREST.int_accum%TYPE,
--							a_int_deb_accum_prev in t_interest.int_deb_accum%type,
							a_int_cre_accum_prev IN T_INTEREST.int_cre_accum%TYPE,
							a_int_adj_accum_prev IN T_INTEREST.int_value%TYPE,
							a_today_mvmt IN T_INTEREST.int_accum%TYPE,
							a_int_pay		  IN ipnextg.MST_CLIENT.INT_ON_PAYABLE%TYPE,
							a_int_rec		  IN ipnextg.MST_CLIENT.INT_ON_RECEIVABLE%TYPE,
							a_pay_annual_days IN ipnextg.MST_CLIENT.INT_PAY_DAYS%TYPE,
							a_rec_annual_days IN ipnextg.MST_CLIENT.INT_REC_DAYS%TYPE,
							a_int_adj	      IN T_INTEREST.int_value%TYPE,
							a_insert          IN BOOLEAN,
							a_user_id         IN VARCHAR2,
							a_client_cd       IN T_INTEREST.client_cd%TYPE,
 							a_deposit		  IN T_INTEREST.int_cre_accum%TYPE,
  		   			a_int_accum       OUT T_INTEREST.int_accum%TYPE,
  		   			a_int_amt         OUT T_INTEREST.int_amt%TYPE,
--							a_int_deb_accum   out t_interest.int_deb_accum%type,
							a_int_cre_accum   OUT T_INTEREST.int_cre_accum%TYPE,
							a_int_adj_accum   OUT T_INTEREST.int_value%TYPE
  		   				   ) RETURN NUMBER IS

  v_int_per					T_INTEREST.int_per%TYPE;
  lv_int_flg				T_INTEREST.int_flg%TYPE;
  v_principal_accum T_INTEREST.int_accum%TYPE;
  v_beg_balance     T_INTEREST.int_accum%TYPE;
  l_int_pay		      ipnextg.T_INTEREST_RATE.INT_ON_PAYABLE%TYPE;
  l_int_rec		      ipnextg.T_INTEREST_RATE.INT_ON_RECEIVABLE%TYPE;
  l_idx             INTEGER;

	BEGIN

    IF a_int_accumulated = 'Y' AND a_int_dt < '01-Jan-2010' THEN
      -- Bunga berbunga metod
        v_principal_accum 	:= a_today_mvmt + a_int_accum_prev + a_int_amt_prev;
    END IF;



		IF a_int_accumulated = 'N' OR a_int_dt >= '01-jan-2010' THEN

		   v_principal_accum 	:= a_today_mvmt + a_int_accum_prev;

		END IF;


		IF a_int_dt > p_close_date THEN

		   v_principal_accum 	:= 0;

		END IF;


     IF v_off_bal_sh = 'Y' THEN
  
         l_int_pay := 0;
         l_int_rec := 0;
  
      ELSE
  
  
  
        IF v_rate_table.COUNT = 0 THEN
            l_int_rec := 0;
            l_int_pay := 0;
         ELSE
  
            l_idx := a_int_dt - vp_bgn_date + 1;
            l_int_rec := v_rate_table(l_idx).int_on_receivable;
            l_int_pay := v_rate_table(l_idx).int_on_payable;
          
        END IF;
  
      END IF;


	    IF v_principal_accum  < 0 THEN
--	        v_principal_accum 	:= v_principal_accum  * (-1) ;
	        v_int_per 					:= l_int_pay;
	        lv_int_flg 					:= 'C';

          IF ABS(v_principal_accum) > v_min_amt THEN
              IF v_round = 'Y' then 										
                 a_int_amt			:= ROUND(v_principal_accum * (l_int_pay / 100) / a_pay_annual_days,0);							
              else   										
                  a_int_amt			:= v_principal_accum * (l_int_pay / 100) / a_pay_annual_days;							
              end if;    										

          ELSE
             a_int_amt			:= 0;
          END IF;


        ELSE

          v_int_per 					:= l_int_rec;
          lv_int_flg 					:= 'D';

          IF ABS(v_principal_accum) > v_min_amt THEN
             -- IF   v_client_type_3 = 'D'  THEN --30jan15
                IF a_deposit > 0 THEN --25may15
                     IF v_principal_accum <=  a_deposit THEN 
                        a_int_amt			:= ROUND(v_principal_accum * (l_int_pay / 100) / a_rec_annual_days,0);
                        v_int_per 			 :=l_int_pay;
                      ELSE
                           a_int_amt		:= ROUND(a_deposit * (l_int_pay / 100) / a_rec_annual_days,0)
                                            + ROUND((v_principal_accum - a_deposit ) * (l_int_rec / 100) / a_rec_annual_days,0);			
                      END IF;		
                  ELSE
                     IF v_round = 'Y' then 										
                         a_int_amt			:=  	ROUND(v_principal_accum  * (l_int_rec / 100) / a_rec_annual_days,0);						
                      ELSE    										
                         a_int_amt			:=  	v_principal_accum  * (l_int_rec / 100) / a_rec_annual_days;						
                      END IF;   										

                  END IF;	
            ELSE
               a_int_amt			:= 0;
            END IF;

	    END IF;



--		a_int_accum := round(v_principal_accum, 0);
      a_int_accum := v_principal_accum;

--		IF a_int_accumulated = 'N' THEN
			a_int_cre_accum     := NVL(a_int_cre_accum_prev, 0) + a_int_amt;
--		END IF;

      IF a_int_dt > p_close_date THEN
  
         a_int_cre_accum		:= 0;
      END IF;

      a_int_adj_accum     := NVL(a_int_adj_accum_prev, 0) + NVL(a_int_adj,0);
		
       IF to_char(a_int_dt,'dd') = '01' then
            v_beg_balance := a_int_accum_prev;
        else    
            v_beg_balance := 0;
        end if;

      IF a_insert = FALSE THEN
    
          BEGIN
          UPDATE T_INTEREST
            SET INT_VALUE = a_int_adj_accum,
            INT_PER = v_int_per,
            INT_FLG = lv_int_flg,
            INT_AMT = a_int_amt,
            USER_ID = a_user_id,
            UPD_DT  = SYSDATE,
            INT_ACCUM = a_int_accum,
    		INT_DEB_ACCUM = v_beg_balance,
            INT_CRE_ACCUM = a_int_cre_accum,
            POST_FLG = 'N'
          WHERE client_cd = trim(a_client_cd)
            AND int_dt = TRUNC(a_int_dt);
           EXCEPTION
               WHEN OTHERS THEN
                --   Sp_Insert_Orcl_Errlog(p_user_id, 'ORCLBO', 'PROSES_INTEREST', VL_ERRMSG);
               --RAISE_APPLICATION_ERROR(-20100,'Error update '||trim(a_client_cd)||' - '||TO_CHAR(a_int_dt,'dd/mm/yy')||' on T_INTEREST'||v_nl||SQLERRM);
               v_error_code := -610;
                v_error_msg  := SUBSTR('Error update '||trim(a_client_cd)||' - '||TO_CHAR(a_int_dt,'dd/mm/yy')||' on T_INTEREST'||SQLERRM,1,200);
                RAISE v_err;
            END;
      ELSE
    
          BEGIN
            INSERT INTO T_INTEREST(INT_DT, CLIENT_CD, XN_DOC_NUM,
            INT_VALUE, INT_PER, INT_FLG , INT_AMT, INT_DAY, POST_FLG,
            USER_ID, CRE_DT, UPD_DT, INT_ACCUM, OVR_FLG, TODAY_TRX, NONTRX,
            INT_DEB_ACCUM, INT_CRE_ACCUM, DEPOSIT, POSTED_INT)
            --,UPD_BY,APPROVED_STS,APPROVED_BY,APPROVED_DT)
            VALUES(a_int_dt, a_client_cd, v_int_mmyy,
              a_int_adj_accum, v_int_per, lv_int_flg, a_int_amt, 1,  'N',
            a_user_id, SYSDATE, SYSDATE, a_int_accum, 'N', 0, 0,
            v_beg_balance, a_int_cre_accum, a_deposit, 0);
            --,NULL,'A',p_user_id,SYSDATE);
          EXCEPTION
               WHEN OTHERS THEN
    
              -- RAISE_APPLICATION_ERROR(-20100,'Error insert '||trim(a_client_cd)||' - '||TO_CHAR(a_int_dt,'dd/mm/yy')||' on T_INTEREST'||v_nl||SQLERRM);
                v_error_code := -620;
                v_error_msg  := SUBSTR('Error insert '||trim(a_client_cd)||' - '||TO_CHAR(a_int_dt,'dd/mm/yy')||' on T_INTEREST'||SQLERRM,1,200);
                RAISE v_err;
            END;
    
            v_record_cnt := v_record_cnt + 1;
    
      END IF;


	RETURN 1;

	EXCEPTION
	WHEN v_err THEN  
    RAISE v_err;
     RETURN -1;
	WHEN OTHERS THEN
		v_error_code := -630;
		v_error_msg  := SUBSTR('Error f_Calc_interest '||SQLERRM,1,200);
    
		RAISE v_err;
    RETURN -1;
	END;
-- -------------------------------------------------------------------------------------------


FUNCTION F_GEN_BEG_BAL (a_client ipnextg.MST_CLIENT.client_cd%TYPE)
                       -- a_end_client ipnextg.MST_CLIENT.client_cd%TYPE)
         RETURN NUMBER IS

L_bal_dt DATE;
BEGIN

   l_bal_dt := p_bgn_date - TO_NUMBER(TO_CHAR(p_bgn_date,'dd'));
   l_bal_dt := l_bal_dt - TO_NUMBER(TO_CHAR(l_bal_dt,'dd')) + 1;

   BEGIN
     insert into TMP_INT_BEG_BAL
	   SELECT  l_bal_dt,sl_acct_cd, sum(beg_bal)  
	   FROM
	   (SELECT sl_acct_cd,  (deb_obal - cre_obal) beg_bal
	   FROM ipnextg.T_DAY_TRS,
          ( select client_Cd
            from ipnextg.MST_CLIENT
            --where ( a_client = '%' OR client_cd =  a_client )
            where  client_cd like  a_client 
            and susp_stat = 'N'
            --and amt_int_flg = 'Y'
            and client_type_3 <> 'B') 
	   WHERE trs_dt = l_bal_dt
	   AND sl_acct_cd =  client_cd
     union all
     SELECT sl_acct_cd,  (DECODE(db_cr_flg,'D',1,-1) * curr_val) trx_amt
	   FROM ipnextg.T_ACCOUNT_LEDGER,
          ( select client_Cd
            from ipnextg.MST_CLIENT
            --where ( a_client = '%' OR client_cd =  a_client )
            where  client_cd like  a_client 
            and susp_stat = 'N'
            --and amt_int_flg = 'Y'
            and client_type_3 <> 'B')
	   WHERE sl_acct_cd =  client_cd
     AND doc_date BETWEEN l_bal_dt AND p_bgn_date
	   AND due_date < p_bgn_date
	   AND approved_sts = 'A' )
	   GROUP BY sl_acct_cd 
	   ;
   EXCEPTION
   WHEN NO_DATA_FOUND THEN
      v_error_code := -700;
      v_error_msg  := 'NO DATA FOUND';
       RAISE v_err;
	  RETURN -1;
   WHEN OTHERS THEN
     v_beg_bal := 0;
     v_error_code := -710;
	 v_error_msg  := SUBSTR('Error F_GEN_BEG_BAL '||SQLERRM,1,200);
    
   --RAISE v_err;
	  RETURN -1;
	END;

RETURN 1;
EXCEPTION
	WHEN v_err THEN
      --RAISE v_err;
      RETURN -1;
	WHEN OTHERS THEN
	    v_error_code := -720;
      v_error_msg  := SUBSTR('Error F_GET_BEG_BAL '||SQLERRM,1,200);
    
		--RAISE v_err;
	   RETURN -1;
	END;

--PROC BEGIN-----------------------------------------------------------------------------------------

BEGIN

   

   BEGIN
     Select ddate1 into v_start_date
     from ipnextg.mst_sys_param
     where param_id = 'PROCESS INTEREST'
     and param_cd1 = 'START';
   exception
   when no_data_found then 
      V_ERROR_CODE := -50;
      V_ERROR_MSG := SUBSTR('START DATE in MST SYS PARAM NOT FOUND'|| SQLERRM(SQLCODE),1,200);
      RAISE V_ERR;
   when others then 
      V_ERROR_CODE := -60;
      V_ERROR_MSG := SUBSTR('Get start date from MST SYS PARAM '|| SQLERRM(SQLCODE),1,200);
      RAISE V_ERR;
   end;
   
   if  p_bgn_date < v_start_date then
      V_ERROR_CODE := -70;
      V_ERROR_MSG := 'MENU INI MULAI DIPAKAI '||to_char(v_start_date,'dd/mm/yyyy');
      RAISE V_ERR;
   end if;
   
   v_prefix_client := '';
   v_all_client := v_prefix_client||'%';
	 IF (trim(p_client_cd) = 'BATCH' or trim(p_client_cd) = '%') THEN
      vp_client_cd := v_all_client;
   ELSE
	    vp_client_cd := p_client_cd;
	 END IF;

   vp_bgn_date  := p_bgn_date;
   vp_end_date  := p_end_date;
   v_brch_cd := trim(p_brch_cd);
    
	 IF trim(p_client_cd) = '%' THEN
      v_tmp_client_cd:='ALL';
	 ELSE 
      v_tmp_client_cd:=trim(p_client_cd);
	 END IF;
/*
	 	 
    BEGIN
     sp_T_MANY_HEADER_Insert(v_menu_name,
                           'I',
                           P_USER_ID,
                           P_IP_ADDRESS,
                           NULL,
                           V_UPDATE_DATE,
                           V_UPDATE_SEQ,
                           V_ERROR_CODE,
                           V_ERROR_MSG);
    EXCEPTION
          WHEN OTHERS THEN
             V_ERROR_CODE := -80;
             V_ERROR_MSG := SUBSTR('SP_ipnextg.T_MANY_HEADER_INSERT '|| SQLERRM(SQLCODE),1,200);
            RAISE V_ERR;
    END;
  
		BEGIN
		SP_PROC_INT_T_INTEREST_UPD(	v_tmp_client_cd,
											P_BGN_DATE,
											P_END_DATE,
											P_CLOSE_DATE,
											'I',
											V_UPDATE_DATE,
											V_UPDATE_SEQ,
											1,
											V_ERROR_CODE,
											V_ERROR_MSG);
		  EXCEPTION
             WHEN OTHERS THEN
                V_ERROR_CODE := -90;
                V_ERROR_MSG := SUBSTR('SP_PROC_INT_T_INTEREST_UPD '|| SQLERRM(SQLCODE),1,200);
               RAISE V_ERR;
           END;
		
		IF V_ERROR_CODE < 0 THEN
			V_ERROR_CODE := -80;
			V_ERROR_MSG := SUBSTR('SP_PROC_INT_T_INTEREST_UPD '||V_ERROR_MSG,1,200);
			RAISE V_ERR;
		END IF;
			
		BEGIN	
			UPDATE ipnextg.T_MANY_HEADER
			SET approved_status = 'A',
			approved_user_id = P_USER_ID,
			approved_date = SYSDATE,
			approved_ip_address = P_IP_ADDRESS
			WHERE menu_name = V_MENU_NAME
			AND update_date = V_UPDATE_DATE
			AND update_seq = V_UPDATE_SEQ;
		EXCEPTION
			WHEN OTHERS THEN
				v_error_code := -100;
				v_error_msg :=  SUBSTR('Update ipnextg.T_MANY_HEADER  '||SQLERRM,1,200);
				RAISE v_err;
		END;	
*/
    
     IF trim(vp_client_cd) = v_all_client THEN -- ALL CLIENTS

          begin
          delete from T_INTEREST_FAIL;
           EXCEPTION
          WHEN OTHERS THEN
            v_error_code := -110;
            v_error_msg :=  SUBSTR('DELETE T_INTEREST all client  '||SQLERRM,1,200);
            RAISE v_err;    
          end;
          
           
          begin
               insert into T_INTEREST_FAIL
               Select   client_Cd, p_user_id, sysdate,  vp_bgn_date, vp_end_date, 'SUDAH MONTH END POSTING'
               from T_INTEREST
               where  int_dt BETWEEN vp_bgn_date AND vp_end_date
               AND client_cd  like v_all_client 
               AND post_flg = 'Y'
               group by client_Cd;
           EXCEPTION
          WHEN OTHERS THEN
            v_error_code := -110;
            v_error_msg :=  SUBSTR('DELETE T_INTEREST all client  '||SQLERRM,1,200);
            RAISE v_err;    
          end;
          
          begin
            DELETE FROM T_INTEREST
            WHERE client_cd IN (SELECT client_cd
                                FROM ipnextg.MST_CLIENT
                                WHERE  branch_code like v_brch_cd)
                      --client_type_3 <> 'D'
            and client_cd like v_all_client --hanyautk tes
            AND int_dt BETWEEN vp_bgn_date AND vp_end_date
            AND post_flg <> 'Y';
       --     AND ovr_flg = 'N';
          EXCEPTION
          WHEN OTHERS THEN
            v_error_code := -110;
            v_error_msg :=  SUBSTR('DELETE T_INTEREST all client  '||SQLERRM,1,200);
            RAISE v_err;
          END;	
       
           BEGIN
          Sp_Crea_Int_Batch(v_all_client, vp_bgn_date, vp_end_date,v_brch_cd, p_user_id,v_error_code,v_error_msg);
          EXCEPTION
            WHEN OTHERS THEN
              v_error_code:= -120;
              v_error_msg := substr('Sp_Crea_Int_Batch all client: '||sqlerrm,1,200);
              RAISE v_err;	
          END;
          IF v_error_code <0 THEN
             RAISE v_err;
          END IF;

 	   
          BEGIN
          Sp_Crea_Int_Nontrx(v_all_client, vp_bgn_date, vp_end_date, v_brch_cd,p_user_id,v_error_code,v_error_msg);
          EXCEPTION
            WHEN OTHERS THEN
              v_error_code:= -130;
              v_error_msg := substr('Sp_Crea_Int_Nontrx all client '||sqlerrm,1,200);
              RAISE v_err;	
          END;
          IF v_error_code <0 THEN
            RAISE v_err;
          END IF; 	

    ELSE

	     IF trim(vp_client_cd) = 'D' THEN -- ALL DEPOSIT CLIENTS

          BEGIN
          DELETE FROM T_INTEREST
          WHERE client_cd IN (SELECT client_cd
                                FROM ipnextg.MST_CLIENT
                              WHERE client_type_3 = 'D')
          AND int_dt BETWEEN vp_bgn_date AND vp_end_date
              AND post_flg <> 'Y';
         -- AND ovr_flg = 'N';
          EXCEPTION
          WHEN OTHERS THEN
            v_error_code := -140;
            v_error_msg :=  SUBSTR('DELETE T_INTEREST client type D  '||SQLERRM,1,200);
            RAISE v_err;
          END;	
            
          BEGIN
          Sp_Crea_Int_Batch('D', vp_bgn_date, vp_end_date, v_brch_cd,p_user_id,v_error_code,v_error_msg);
          EXCEPTION
            WHEN OTHERS THEN
              v_error_code:= -150;
              v_error_msg := substr('Sp_Crea_Int_Batch client type D: '||sqlerrm,1,200);
              RAISE v_err;	
          END;
          IF v_error_code <0 THEN
             RAISE v_err;
          END IF;
    
           
           BEGIN
            Sp_Crea_Int_Nontrx('D', vp_bgn_date, vp_end_date, v_brch_cd,p_user_id,v_error_code,v_error_msg);
            EXCEPTION
            WHEN OTHERS THEN
              v_error_code:= -160;
              v_error_msg := substr('Sp_Crea_Int_Nontrx  client type D: '||sqlerrm,1,200);
              RAISE v_err;	
          END;
          IF v_error_code <0 THEN
            RAISE v_err;
          END IF;

	--v_nl := chr(10)||chr(13);
      ELSE --IF trim(vp_client_cd) = 'D' THEN

          BEGIN
          DELETE T_INTEREST
          WHERE int_dt BETWEEN vp_bgn_date AND vp_end_date
            AND client_cd = vp_client_cd
           -- AND post_flg <> 'Y';
          AND (post_flg <> 'Y' or p_cancel_posted_interest = 'Y');
          --AND ovr_flg = 'N';
          EXCEPTION
            WHEN OTHERS THEN
              v_error_code := -170;
              v_error_msg :=  SUBSTR('DELETE T_INTEREST '||vp_client_cd||SQLERRM,1,200);
              RAISE v_err;
            END;	
            
           BEGIN
            Sp_Crea_Int_Batch(vp_client_cd, vp_bgn_date, vp_end_date,v_brch_cd, p_user_id,v_error_code,v_error_msg);
            EXCEPTION
              WHEN OTHERS THEN
                v_error_code:= -180;
                v_error_msg := substr('Sp_Crea_Int_Batch : '||vp_client_cd||sqlerrm,1,200);
                RAISE v_err;	
            END;
            IF v_error_code <0 THEN
               RAISE v_err;
            END IF;
  
            BEGIN
            Sp_Crea_Int_Nontrx(vp_client_cd, vp_bgn_date, vp_end_date, v_brch_cd,p_user_id,v_error_code,v_error_msg);
            EXCEPTION
            WHEN OTHERS THEN
              v_error_code:= -200;
              v_error_msg := substr('Sp_Crea_Int_Nontrx : '||vp_client_cd||sqlerrm,1,200);
              RAISE v_err;	
            END;
            IF v_error_code <0 THEN
              
              RAISE v_err;
            END IF;

   		 END IF; --IF trim(vp_client_cd) = 'D' THEN
    END IF; --IF trim(vp_client_cd) = v_all_client THEN
     

--  	COMMIT;
--  	RETURN;


	--v_nl := CHR(10)||CHR(13);

     --      v_min_amt := 500000;											
    BEGIN											
     Select dnum1 into  v_min_amt											
     from ipnextg.mst_sys_param											
     where param_id = 'PROCESS INTEREST'											
     and param_cd1 = 'MINIMUM'											
     and param_cd2 = 'BALANCE';											
     exception											
     when no_data_found then 											
        V_ERROR_CODE := -205;											
        V_ERROR_MSG := SUBSTR('MINIMUM BALANCE in MST SYS PARAM NOT FOUND'|| SQLERRM(SQLCODE),1,200);											
        RAISE V_ERR;											
     when others then 											
        V_ERROR_CODE := -206;											
        V_ERROR_MSG := SUBSTR('Get MINIMUM BALANCE from MST SYS PARAM '|| SQLERRM(SQLCODE),1,200);											
        RAISE V_ERR;											
     end;											
     											
     BEGIN											
     Select dflg1 into  v_round											
     from ipnextg.mst_sys_param											
     where param_id = 'PROCESS INTEREST'											
     and param_cd1 = 'ROUND';											
     exception											
     when no_data_found then 											
        V_ERROR_CODE := -207;											
        V_ERROR_MSG := SUBSTR('ROUNDING FLAG in MST SYS PARAM NOT FOUND'|| SQLERRM(SQLCODE),1,200);											
        RAISE V_ERR;											
     when others then 											
        V_ERROR_CODE := -208;											
        V_ERROR_MSG := SUBSTR('Get ROUNDING FLAG from MST SYS PARAM '|| SQLERRM(SQLCODE),1,200);											
        RAISE V_ERR;											
     end;											

    
      IF vp_client_cd = v_all_client OR vp_client_cd = 'D' THEN
          v_bgn_client := v_all_client;
          v_end_client := v_prefix_client||'_';
    
      ELSE
          v_bgn_client := trim(vp_client_cd);
          v_end_client := trim(vp_client_cd);
      END IF;

     v_int_mmyy :=   TO_CHAR(vp_end_date,'mmyy');
     v_client_cnt := 0;

-- v_bgn_client := 'DIAN006R';
--	 v_end_client := 'DIAN006R';

     IF F_GEN_BEG_BAL(trim(v_bgn_client)) < 1 THEN
        raise v_err;
     end if;   
   
     OPEN csr_client(v_bgn_client, v_end_client);
     LOOP
     FETCH csr_client INTO v_client;
     EXIT WHEN csr_client%NOTFOUND;
  
          BEGIN
          SELECT INT_ON_PAYABLE, INT_ON_RECEIVABLE,INT_PAY_DAYS, INT_REC_DAYS,INT_ACCUMULATED,
               DECODE(NVL(AMT_INT_FLG,'Y'),'N','Y','N'), CLIENT_TYPE_3
          INTO v_int_pay, v_int_rec, v_pay_annual_days, v_rec_annual_days,v_int_accumulated,
               v_off_bal_sh, v_client_type_3
          FROM ipnextg.MST_CLIENT WHERE CLIENT_CD = trim(v_client.client_cd);
          EXCEPTION
              WHEN NO_DATA_FOUND THEN
                v_error_code:= -210;
                v_error_msg := substr('NOT FOUND in MST_CLIENT '||vp_client_cd||sqlerrm,1,200);
                RAISE v_err;	
          
              WHEN OTHERS THEN
                v_error_code:= -220;
                v_error_msg := substr('Select MST CLIENT '||vp_client_cd||sqlerrm,1,200);
                RAISE v_err;	
              END;
              
          v_record_cnt := 0;
  
   --  read interest rates into table
  
           v_rate_table.DELETE;
           v_end_day := vp_end_date - vp_bgn_date + 1;
      
           FOR iday IN 1..v_end_day LOOP
        
            v_rate_table(iday).int_on_receivable := 0;
            v_rate_table(iday).int_on_payable := 0;
        
           END LOOP;
  
           OPEN csr_rate(v_client.client_cd, vp_bgn_date, vp_end_date);
            LOOP
            FETCH csr_rate INTO v_rate_rec;
            EXIT WHEN csr_rate%NOTFOUND;
  
                IF v_rate_rec.eff_dt <= vp_bgn_date THEN
                   v_bgn_day :=  1;
                ELSE
                   v_bgn_day :=  v_rate_rec.eff_dt - vp_bgn_date + 1;
                END IF;
            
                v_end_day := vp_end_date - vp_bgn_date + 1;
  
                FOR iday IN v_bgn_day..v_end_day LOOP
            
            
                  v_rate_table(iday).int_on_receivable := v_rate_rec.int_on_receivable;
                  v_rate_table(iday).int_on_payable := v_rate_rec.int_on_payable;
            
            
                END LOOP;
                v_bgn_day :=  1;
           END LOOP; --OPEN csr_rate
           CLOSE csr_rate;
  
           IF v_off_bal_sh = 'Y' THEN
        
              v_int_pay := 0;
              v_int_rec := 0;
        
           END IF;
  
     
	-- search last record to get last date
    --  int_value = interest adjustment lastmonth, folder_cd = 'IJ%'

--25jul2016 dikomen     IF vp_client_cd = '%' OR vp_client_cd = 'D' OR 
--	   (vp_client_cd <> '%' AND vp_client_cd <> 'D' AND P_SOA = 'N') THEN
--  diganti yg berikut ini ,v_GL_BAL = 'N'-> diambil dr interest worksheet ( T INTEREST)
--                          v_GL_BAL = 'Y'-> diambil dr GL balance T DAY TRS
 /*   BEGIN
    select trim(dflg1 ) into v_GL_BAL
    from mst_sys_param
    where param_id = 'INTEREST'
    and param_cd1 = 'BEGBALGL';
    EXCEPTION
    WHEN OTHERS THEN 
      v_error_code := -220;
      v_error_msg  := SUBSTR('Error finding MST_SYS_PARAM param_id = INTEREST '||SQLERRM,1,200);
      RAISE v_err;
    end;  
    
     IF v_GL_BAL = 'N' then
	     v_new := FALSE;
       BEGIN
       SELECT   int_amt, int_accum + NVL(int_value,0), int_flg, int_dt, post_flg,
                NVL(int_deb_accum,0), NVL(int_cre_accum,0), 0 
        INTO   v_int_amt_prev, v_int_accum_prev, v_int_flg, v_max_int_date, v_post_flg,
               v_int_deb_accum_prev, v_int_cre_accum_prev, v_int_adj_accum_prev
        FROM T_INTEREST
        WHERE client_cd = trim(v_client.client_cd)
        AND (
			     (int_dt = (SELECT MAX(b.int_dt) FROM T_INTEREST b
			              WHERE b.client_cd = trim(v_client.client_cd)
						    AND post_flg = 'Y' 
							AND INT_DT < vp_bgn_date)));
	
        EXCEPTION
        when no_data_found then
                  v_new := TRUE;
                  v_int_amt_prev := 0;
                  v_int_accum_prev := 0;

                  v_max_int_date := '01-jan-2000';
                  v_int_deb_accum_prev := 0;
                  v_int_cre_accum_prev := 0;
                  v_int_adj_accum_prev := 0;
           WHEN OTHERS THEN
-- 25jul2016    IF SQL%NOTFOUND THEN  -- check for 'no data found'
--                  v_new := TRUE;
--                  v_int_amt_prev := 0;
--                  v_int_accum_prev := 0;
--
--                  v_max_int_date := '01-jan-2000';
--                  v_int_deb_accum_prev := 0;
--                  v_int_cre_accum_prev := 0;
--                  v_int_adj_accum_prev := 0;
--			  
--              END IF;
              v_error_code := -220;
							v_error_msg  := SUBSTR('Error interest previous month '||v_client.client_cd||v_nl||SQLERRM,1,200);
							RAISE v_err;
           END;
     ELSE
	    
         IF F_GET_BEG_BAL(trim(v_client.client_cd)) = 1 THEN
           v_int_accum_prev := v_beg_bal;
        ELSE
              v_int_accum_prev := 0;
        END IF;
        v_int_amt_prev := 0;
        v_int_deb_accum_prev := 0;
        v_int_cre_accum_prev := 0;
        v_int_adj_accum_prev := 0;
        v_max_int_date := '01-jan-2000';
        v_new := FALSE;
	 
	 END IF;*/
   
   

   
           BEGIN
           select beg_bal into v_int_accum_prev
           from TMP_INT_BEG_BAL
           where client_cd = trim(v_client.client_cd);
           exception
           when no_data_found then
            v_int_accum_prev := 0;
           when others then
              v_error_code := -230;
              v_error_msg  := SUBSTR('Error interest beginning balance '||v_client.client_cd||SQLERRM,1,200);
              RAISE v_err;
           end;   
      
/*DEC 2016           v_new := FALSE;   
           begin   
           SELECT MAX(b.int_dt) into v_max_int_date
           FROM T_INTEREST b
           WHERE b.client_cd = trim(v_client.client_cd)
             AND post_flg = 'Y' 
             AND INT_DT < vp_bgn_date;   
           exception
           when no_data_found then
            v_new := TRUE;
            v_int_amt_prev := 0;
            v_max_int_date := TO_DATE('01/01/2000','dd/mm/yyyy');
            v_int_deb_accum_prev := 0;
            v_int_cre_accum_prev := 0;
            v_int_adj_accum_prev := 0;
           when others then
              v_error_code := -240;
              v_error_msg  := SUBSTR('Error interest terahir diposting '||v_client.client_cd||SQLERRM,1,200);
              RAISE v_err;
           end;     
         
           if v_max_int_date is null then
              v_new := TRUE;
              v_int_amt_prev := 0;
              v_max_int_date := TO_DATE('01/01/2000','dd/mm/yyyy');
              v_int_deb_accum_prev := 0;
              v_int_cre_accum_prev := 0;
              v_int_adj_accum_prev := 0;
           end if;
   
          If (TO_CHAR(p_bgn_date,'dd') <> '01') then
              
                BEGIN
                SELECT   int_amt, int_accum, int_flg, 
                         NVL(int_cre_accum,0), 0 
                INTO   v_int_amt_prev, v_int_accum_prev, v_int_flg,  
                        v_int_cre_accum_prev, v_int_adj_accum_prev
                FROM T_INTEREST
                WHERE client_cd = trim(v_client.client_cd)
                AND int_dt = v_max_int_date;
          
                EXCEPTION
                when no_data_found then
                          v_new := TRUE;
                          v_int_amt_prev := 0;
                          v_int_accum_prev := 0;
        
                          v_max_int_date := TO_DATE('01/01/2000','dd/mm/yyyy');
                          v_int_deb_accum_prev := 0;
                          v_int_cre_accum_prev := 0;
                          v_int_adj_accum_prev := 0;
                   WHEN OTHERS THEN
                   v_error_code := -250;
                    v_error_msg  := SUBSTR('Error interest terahir diposting '||v_client.client_cd||SQLERRM,1,200);
                    RAISE v_err;
                   END;
             ELSE
                
                  v_int_amt_prev := 0;
                  v_int_deb_accum_prev := 0;
                  v_int_cre_accum_prev := 0;
                  v_int_adj_accum_prev := 0;
             END If;*/
         
-- dec2016 IF v_max_int_date < vp_end_date  THEN -- yg sudah posting tidak diproses
      
-- dec2016            IF v_new = TRUE  THEN
               v_int_amt_prev := 0;
               --v_int_accum_prev := 0; -- ???
        
              -- v_max_int_date := '01jan2000';
              v_max_int_date :=  TO_DATE('01/01/2000','dd/mm/yyyy');
              v_int_deb_accum_prev := 0;
              v_int_cre_accum_prev := 0;
              v_int_adj_accum_prev := 0;
 -- dec2016           END IF;
      
      
        -- INI HANYA UTK NOV 2005  or CLIENT DEPOSIT
      --		IF    (v_new = FALSE AND vp_bgn_date = TO_DATE('01/11/05','dd/mm/yy') )
      --		   OR  v_int_accumulated = 'D' OR  v_int_accumulated = 'N'
      
  /*               IF v_int_accumulated = 'D' OR  v_int_accumulated = 'N' THEN
           
      
              IF v_client_type_3 = 'D' THEN
                  IF v_int_accumulated = 'N' AND (TO_CHAR(p_bgn_date,'dd') = '01') THEN   -- 01 NOV 2008 utk client deposit
                        v_int_accum_prev := v_int_accum_prev + v_int_cre_accum_prev;
                        v_int_deb_accum_prev := 0;
                        v_int_cre_accum_prev := 0;
                        v_int_adj_accum_prev := 0;
                  END IF;
      --          ELSE
      --             IF v_int_amt_prev < 0 THEN --??????
      --                v_int_amt_prev := 0;      -- krn int amt 31OCT05 sdh trmasuk di int_cre_accum_prev
      --             END IF;
      
   	 		   IF   (v_int_cre_accum_prev <> 0)
        --		   and p_chg_mon = true
               THEN
      
      --tdk dipake lagi			     BEGIN 
                 UPDATE T_INTEREST
                  SET nontrx = NVL(nontrx,0) +  v_int_cre_accum_prev,
                      user_id = p_user_id,
                      upd_dt = SYSDATE
                  WHERE client_cd = trim(v_client.client_cd)
                  AND int_dt = vp_bgn_date;
                  EXCEPTION
                       WHEN OTHERS THEN
                        v_error_code := -220;
                        v_error_msg  := SUBSTR('Error update nontrx with int_cre_accum '||v_client.client_cd||' - '||TO_CHAR(vp_bgn_date,'dd/mm/yy')||' to T_INTEREST'||v_nl||SQLERRM,1,200);
                        RAISE v_err;
                    END;
                  IF SQL%NOTFOUND THEN
      
                     BEGIN
                      INSERT INTO T_INTEREST(INT_DT, CLIENT_CD, XN_DOC_NUM,
                  INT_VALUE, INT_PER, INT_FLG , INT_AMT, INT_DAY, POST_FLG,
                  USER_ID, CRE_DT, UPD_DT, INT_ACCUM, OVR_FLG, TODAY_TRX, NONTRX,
                  INT_DEB_ACCUM, INT_CRE_ACCUM, deposit,UPD_BY,APPROVED_STS,APPROVED_BY,APPROVED_DT)
                      VALUES(vp_bgn_date, trim(v_client.client_cd), v_int_mmyy,
                    0, 0, NULL, 0, 0,  'E',
                  p_user_id, SYSDATE, SYSDATE, 0, 'N', 0,  v_int_cre_accum_prev,
                  0,0, 0,NULL,'A',p_user_id,SYSDATE );
                  EXCEPTION
                       WHEN OTHERS THEN
                       --RAISE_APPLICATION_ERROR(-20100,'Error update nontrx with int_cre_accum '||v_client.client_cd||' - '||TO_CHAR(vp_bgn_date,'dd/mm/yy')||' to T_INTEREST'||v_nl||SQLERRM);
                      v_error_code := -230;
                    v_error_msg  := SUBSTR('Error update nontrx with int_cre_accum '||v_client.client_cd||' - '||TO_CHAR(vp_bgn_date,'dd/mm/yy')||' to T_INTEREST'||v_nl||SQLERRM,1,200);
                    RAISE v_err;
                    END;
      
                  END IF;
      
      
                v_int_deb_accum_prev := 0;
                v_int_cre_accum_prev := 0;
                v_int_adj_accum_prev := 0;
               END IF; 
             END IF; --IF v_client_type_3 = 'D' THEN
                 
      
              IF   (v_int_cre_accum_prev <> 0) AND   (TO_CHAR(p_bgn_date,'dd') <> '01')
             --and p_chg_mon = false
             THEN
                  BEGIN
                  UPDATE T_INTEREST
                  SET int_cre_accum = NVL(int_cre_accum,0) +  NVL(sett_int_cre,0) + v_int_cre_accum_prev,
                    user_id = p_user_id,
                    upd_dt = SYSDATE
                  WHERE trim(client_cd) = trim(v_client.client_cd)
                  AND TRUNC(int_dt) = (v_max_int_date + 1);
                  IF SQL%NOTFOUND THEN
      --
                     BEGIN
                      INSERT INTO T_INTEREST(INT_DT, CLIENT_CD, XN_DOC_NUM,
                      INT_VALUE, INT_PER, INT_FLG , INT_AMT, INT_DAY, POST_FLG,
                      USER_ID, CRE_DT, UPD_DT, INT_ACCUM, OVR_FLG, TODAY_TRX, NONTRX,
                      INT_DEB_ACCUM, INT_CRE_ACCUM, deposit)
                      --,UPD_BY,APPROVED_STS,APPROVED_BY,APPROVED_DT)
                      VALUES(v_max_int_date + 1, trim(v_client.client_cd), v_int_mmyy,
                        0, 0, NULL, 0, 0,  'E',
                      p_user_id, SYSDATE, SYSDATE, 0, 'N', 0, 0,
                      0, v_int_cre_accum_prev, 0);
                      --NULL,'A',p_user_id,SYSDATE );
                    EXCEPTION
                       WHEN OTHERS THEN
                      v_error_code := -270;
                      v_error_msg  := SUBSTR('Error update nontrx with int_cre_accum '||v_client.client_cd||' - '||TO_CHAR(vp_bgn_date,'dd/mm/yy')||' to T_INTEREST'||SQLERRM,1,200);
                      RAISE v_err;
                    END;
          --
                  END IF;
                  EXCEPTION
                   WHEN OTHERS THEN
                        v_error_code := -280;
                      v_error_msg  := SUBSTR('Error update nontrx with int_cre_accum '||v_client.client_cd||' - '||TO_CHAR(vp_bgn_date,'dd/mm/yy')||' to T_INTEREST'||SQLERRM,1,200);
                      RAISE v_err;
                    END;
      --
              END IF; --		   IF   (v_int_cre_accum_prev <> 0) AND   (TO_CHAR(p_bgn_date,'dd') <> '01')
     
      
            END IF; -- IF v_int_accumulated = 'D' OR  v_int_accumulated = 'N' THEN
  */     
          
--    DEC2016        IF v_int_accumulated = 'Y' AND vp_bgn_date > TO_DATE('01/01/2010','dd/mm/yyyy') THEN
--              v_int_deb_accum_prev := 0;
--              v_int_accum_prev := v_int_accum_prev + v_int_cre_accum_prev;
--              v_int_cre_accum_prev := 0;
--              v_int_amt_prev := 0;
--            END IF;
                
--            IF v_max_int_date < vp_bgn_date THEN
               v_max_int_date := vp_bgn_date - 1;
--            END IF;
      
            IF v_max_int_date < vp_end_date   THEN
        
            -- interest for contracts with due date between last date of calc'd interest or
            --                        with due date before today date and  new client
            --                        with due date before today date and client with restarting transaction
        
                   v_trx_cnt := 0;
        
               OPEN csr_detail(v_client.client_cd, vp_bgn_date, vp_end_date);
               LOOP
                    FETCH csr_detail INTO v_detail;
                    EXIT WHEN csr_detail%NOTFOUND;
        
                    v_trx_cnt := v_trx_cnt + 1;
        
                    IF (v_int_accum_prev + v_int_amt_prev) <> 0 THEN
                        v_int_day := v_detail.int_dt - v_max_int_date;
                        v_int_dt := v_max_int_date;
        
                        FOR iday IN 1..v_int_day LOOP
        
                            IF iday = v_int_day THEN
            
            
                                 v_today_mvmt :=   v_detail.today_trx + v_detail.nontrx;
                    
                                 v_int_cre_accum_prev := v_int_cre_accum_prev + v_detail.sett_int_cre;
                                 v_int_adjust :=   v_detail.int_adjust;
                                 v_insert     := FALSE;
                            ELSE
                                v_today_mvmt := 0;
                                v_int_adjust := 0;
                                v_insert := TRUE;
                            END IF;
        
                            v_int_dt := v_int_dt + 1;
                
                            v_rtn := f_calc_interest(v_int_accumulated,
                                  v_int_dt,
                                  v_int_amt_prev,
                                  v_int_accum_prev,
                    --								v_int_deb_accum_prev,
                                  v_int_cre_accum_prev,
                                  v_int_adj_accum_prev,
                                  v_today_mvmt,
                                  v_int_pay,
                                  v_int_rec,
                                  v_pay_annual_days,
                                  v_rec_annual_days,
                                  v_int_adjust,
                                  v_insert,
                                  p_user_id,
                                  v_client.client_cd,
                                  v_detail.deposit,
                                  v_int_accum,
                                  v_int_amt,
                    --								v_int_deb_accum,
                                  v_int_cre_accum,
                                  v_int_adj_accum    );
            
                                v_int_accum_prev := v_int_accum;
                                v_int_amt_prev   := v_int_amt;
                    --							v_int_deb_accum_prev := v_int_deb_accum;
                                v_int_cre_accum_prev := v_int_cre_accum;
                                v_int_adj_accum_prev := v_int_adj_accum;
                              
                            END LOOP; --FOR iday IN 1..v_int_day LOOP
                        ELSE -- v_int_accum_prev > 0 then
        
                  -- v_int_accum_prev = 0 or v_new = true
        
        
                               v_today_mvmt :=  (v_detail.today_trx + v_detail.nontrx);
                               v_int_cre_accum_prev := v_int_cre_accum_prev + v_detail.sett_int_cre;
                               v_int_adjust := v_detail.int_adjust;
                               v_int_dt := v_detail.int_dt;
                               v_rtn := f_calc_interest(v_int_accumulated,
                                              v_int_dt,
                                              v_int_amt_prev, -- zer0
                                              v_int_accum_prev, -- zero
                                --								v_int_deb_accum_prev,
                                              v_int_cre_accum_prev,
                                              v_int_adj_accum_prev,
                                              v_today_mvmt,
                                              v_int_pay,
                                              v_int_rec,
                                              v_pay_annual_days,
                                              v_rec_annual_days,
                                              v_int_adjust,
                                              FALSE,   -- update
                                              p_user_id,
                                              v_client.client_cd,
                                              v_detail.deposit,
                                              v_int_accum,
                                              v_int_amt,
                                --								v_int_deb_accum,
                                              v_int_cre_accum,
                                              v_int_adj_accum    );
                    
                                v_int_accum_prev := v_int_accum;
                                v_int_amt_prev   := v_int_amt;
                    --							v_int_deb_accum_prev := v_int_deb_accum;
                                v_int_cre_accum_prev := v_int_cre_accum;
                                v_int_adj_accum_prev := v_int_adj_accum;
                        END IF; -- v_int_accum_prev > 0 then
        
                        v_max_int_date   := v_int_dt;
        
               END LOOP;
               CLOSE csr_detail;
        
        
               IF (ABS(v_int_accum_prev) + ABS(v_int_amt_prev) + ABS(v_int_cre_accum_prev)) <> 0
                  OR v_trx_cnt > 0 THEN
        
                 iday := vp_end_date - TRUNC(v_max_int_date);
        
                 IF iday > 0 AND  v_max_int_date > TO_DATE('01/01/2000','dd/mm/yyyy') THEN
        
                       v_int_day := vp_end_date - TRUNC(v_max_int_date);
                       v_int_dt  := v_max_int_date;
              
                       FOR iday IN 1..v_int_day LOOP
            
                          v_int_dt := v_int_dt + 1;
            
                          v_rtn := f_calc_interest(v_int_accumulated,
                                v_int_dt,
                                v_int_amt_prev,
                                v_int_accum_prev,
                      --					v_int_deb_accum_prev,
                                v_int_cre_accum_prev,
                                v_int_adj_accum_prev,
                                0,
                                v_int_pay,
                                v_int_rec,
                                v_pay_annual_days,
                                v_rec_annual_days,
                                0,
                                TRUE, -- INSERT
                                p_user_id,
                                v_client.client_cd,
                                0,
                                v_int_accum,
                                v_int_amt,
              --							v_int_deb_accum,
                                v_int_cre_accum,
                                v_int_adj_accum    );
            
                            IF v_rtn = -1 THEN
                               EXIT;
                            END IF;
            
                            v_int_accum_prev := v_int_accum;
                            v_int_amt_prev   := v_int_amt;
                            v_int_deb_accum_prev := v_int_deb_accum;
                            v_int_cre_accum_prev := v_int_cre_accum;
                            v_int_adj_accum_prev := v_int_adj_accum;
            --           FOR iday IN 1..v_int_day LOOP
                       END LOOP;
        
                 END IF; -- iday > 0 and  v_max_int_date > '01-jan-2000'
        
               ELSE
      
             -- interest ZERO - create one last line
                v_rtn := v_rtn;  -- dummy , 
                -- yg dibwh ini dikomen OCT2016, krn beg bal dihitung, bukan diambil
                -- dr wks
               /* v_rtn := f_calc_interest(v_int_accumulated,
                          vp_end_date,
                  v_int_amt_prev,
                  v_int_accum_prev,
        --					v_int_deb_accum_prev,
                  v_int_cre_accum_prev,
                  v_int_adj_accum_prev,
                  0,
                  v_int_pay,
                  v_int_rec,
                  v_pay_annual_days,
                  v_rec_annual_days,
                  0,
                  TRUE, -- INSERT
                  p_user_id,
                  v_client.client_cd,
                  0,
                  v_int_accum,
                  v_int_amt,
        --							v_int_deb_accum,
                  v_int_cre_accum,
                  v_int_adj_accum    );
      
                  IF v_rtn = -1 THEN
                     EXIT;
                  END IF; */
      
                END IF; -- (abs(v_int_accum_prev) + abs(v_int_amt_prev) + abs(v_int_cre_accum_prev)) <> 0
           
            END IF; -- v_max_int_date < vp_end_date
      
--         END IF; -- v_max_int_date < vp_end_date
        
        IF v_record_cnt > 0 THEN
           v_client_cnt := v_client_cnt + 1;
           v_record_cnt := 0;
        END IF;

   END LOOP;
   CLOSE csr_client;

--TIMESTAMP
    IF trim(vp_client_cd) = '%' OR trim(vp_client_cd) = 'D' THEN
    
       IF trim(vp_client_cd) = '%' THEN
          v_stamp_client := 'TIMESTAMP';
       ELSE
          v_stamp_client := 'STAMPDEPO';
       END IF;
    
        v_insert := FALSE;
        BEGIN
        SELECT cre_dt INTO v_int_dt
        FROM  T_INTEREST
        WHERE client_cd = v_stamp_client
        AND int_dt = vp_end_date;
        EXCEPTION
           WHEN NO_DATA_FOUND THEN
               v_insert := TRUE;
             WHEN OTHERS THEN
             -- RAISE_APPLICATION_ERROR(-20100,'Error read timestamp  to T_INTEREST'||v_nl||SQLERRM);
              v_error_code := -260;
          v_error_msg  := SUBSTR('Error read timestamp  to T_INTEREST'||SQLERRM,1,200);
          RAISE v_err;
        END;
    
        IF v_insert = TRUE THEN
             BEGIN
              INSERT INTO T_INTEREST(INT_DT, CLIENT_CD, XN_DOC_NUM,
          INT_VALUE, INT_PER, INT_FLG , INT_AMT, INT_DAY, POST_FLG,
          USER_ID, CRE_DT, UPD_DT, INT_ACCUM, OVR_FLG, TODAY_TRX, NONTRX,
          INT_DEB_ACCUM, INT_CRE_ACCUM, deposit, posted_int)
          --,UPD_BY,APPROVED_STS,APPROVED_BY,APPROVED_DT)
                VALUES(vp_end_date, v_stamp_client, NULL,
            0, 0, NULL, 0, 0,  'Y',
          p_user_id, SYSDATE, SYSDATE, 0, 'N', 0, 0,
          0, 0, 0, 0);
          --,NULL,'A',p_user_id,SYSDATE );
          EXCEPTION
               WHEN OTHERS THEN
               -- RAISE_APPLICATION_ERROR(-20100,'Error insert timestamp  to T_INTEREST'||v_nl||SQLERRM);
                v_error_code := -270;
            v_error_msg  := SUBSTR('Error insert timestamp  to T_INTEREST'||SQLERRM,1,200);
            RAISE v_err;
            END;
        ELSE
            BEGIN
              UPDATE T_INTEREST
              SET cre_dt = SYSDATE, upd_dt = SYSDATE
              WHERE client_cd = v_stamp_client
              AND int_dt = vp_end_date;
              EXCEPTION
               WHEN OTHERS THEN
               -- RAISE_APPLICATION_ERROR(-20100,'Error update timestamp  to T_INTEREST'||v_nl||SQLERRM);
                v_error_code := -280;
            v_error_msg  := SUBSTR('Error update timestamp  to T_INTEREST'||SQLERRM,1,200);
            RAISE v_err;
          END;
        END IF;
    END IF;

   o_client_cnt := v_client_cnt;

   --IF p_user_id = 'SCHED' THEN
    --   COMMIT;
   --END IF;

      p_error_code :=1;
      p_error_msg :='';

EXCEPTION
  WHEN NO_DATA_FOUND THEN
		NULL;
  WHEN v_err THEN
  		ROLLBACK;
  		p_error_code := v_error_code;
    	p_error_msg :=v_error_msg;
  WHEN OTHERS THEN
  		ROLLBACK;
   		p_error_code :=-1;
   		p_error_msg :=SUBSTR(SQLERRM,1,200);
  RAISE;
END Sp_Process_Interest;