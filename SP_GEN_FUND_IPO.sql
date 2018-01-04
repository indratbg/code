create or replace 
PROCEDURE SP_GEN_FUND_IPO(P_STK_CD T_PEE.STK_CD%TYPE,
							P_TAHAP VARCHAR2,
							P_FOLDER_CD T_FOLDER.FOLDER_CD%TYPE,
							P_GL_ACCT_CD_BANK T_PAYRECH.GL_ACCT_CD%TYPE,
							P_SL_ACCT_CD_BANK T_PAYRECH.SL_ACCT_CD%TYPE,
							P_GL_ACCT_CD_HUTANG T_PAYRECH.GL_ACCT_CD%TYPE,
							P_SL_ACCT_CD_HUTANG T_PAYRECH.SL_ACCT_CD%TYPE,
              P_REMARKS T_PAYRECH.REMARKS%TYPE,
              P_CLIENT_CD MST_CLIENT.CLIENT_CD%TYPE,
              P_BRANCH_CD MST_CLIENT.BRANCH_CODE%TYPE,
              P_USER T_FUND_MOVEMENT.USER_ID%TYPE,
							P_USER_ID T_FUND_MOVEMENT.USER_ID%TYPE,
							P_IP_ADDRESS T_MANY_HEADER.IP_ADDRESS%TYPE,
							P_ERROR_CODE	OUT NUMBER,
							P_ERROR_MSG	OUT VARCHAR2
							) is

CURSOR CSR_PENERIMAAN_DANA IS
SELECT client_Cd, client_name, fixed_qty, pool_qty, alloc_qty, price,amount,fund_ipo,bal_rdi							
FROM(				  				
SELECT T_IPO_CLIENT.client_Cd, client_name, fixed_qty, pool_qty, alloc_qty, T_PEE.price,								
	   (fixed_qty * price * 1) + ( alloc_qty * price) AS amount,							
	  NVL( f_fund_ipo(P_STK_CD,T_IPO_CLIENT.client_Cd, 'ALOKASI'),0) fund_ipo,							
	  NVL(F_Fund_Bal(T_IPO_CLIENT.client_cd, TRUNC(SYSDATE)),0) bal_rdi							
	FROM T_IPO_CLIENT, MST_CLIENT, T_PEE								
	WHERE T_IPO_CLIENT.stk_cd = P_STK_CD
	AND T_IPO_CLIENT.approved_stat = 'A'								
	AND T_IPO_CLIENT.client_Cd = MST_CLIENT.client_Cd								
	AND T_IPO_CLIENT.stk_cd =  T_PEE.stk_cd
  AND MST_CLIENT.CLIENT_CD LIKE '%'||P_CLIENT_CD
  AND MST_CLIENT.BRANCH_CODE LIKE '%'||P_BRANCH_CD
  AND T_IPO_CLIENT.USER_ID LIKE '%'|| P_USER
  )								
	WHERE  amount > fund_ipo;

CURSOR CSR_PENJATAHAN IS
SELECT client_Cd, client_name, fixed_qty, pool_qty, alloc_qty, price,amount,fund_ipo						
FROM(							
SELECT T_IPO_CLIENT.client_Cd, client_name, fixed_qty, pool_qty, alloc_qty, T_PEE.price,							
	   (fixed_qty * price * 1) + ( alloc_qty * price) AS amount,						
	  NVL( f_fund_ipo(p_stk_cd,T_IPO_CLIENT.client_Cd, 'ALOKASI'),0) fund_ipo						
	FROM T_IPO_CLIENT, MST_CLIENT, T_PEE							
	WHERE T_IPO_CLIENT.stk_cd = P_stk_cd							
	AND T_IPO_CLIENT.approved_stat = 'A'							
	AND T_IPO_CLIENT.client_Cd = MST_CLIENT.client_Cd							
	AND T_IPO_CLIENT.stk_cd =  T_PEE.stk_cd
    AND MST_CLIENT.CLIENT_CD LIKE '%'||P_CLIENT_CD
  AND MST_CLIENT.BRANCH_CODE LIKE '%'||P_BRANCH_CD)							
	WHERE amount <= fund_ipo
  AND FUND_IPO>0;

CURSOR CSR_REFUND IS
 	SELECT client_Cd, client_name, fixed_qty, pool_qty, alloc_qty,									
	  price,amount,fund_ipo, paid_ipo, (fund_ipo - paid_ipo) refund								
FROM(									
	SELECT T_IPO_CLIENT.client_Cd, client_name, fixed_qty, pool_qty, alloc_qty,	T_PEE.price,									
	   (fixed_qty * price * 1) + ( alloc_qty * price) AS amount,								
	  NVL( f_fund_ipo(p_stk_cd,T_IPO_CLIENT.client_Cd, 'ALOKASI'),0) fund_ipo,								
	  NVL( f_fund_ipo(p_stk_cd,T_IPO_CLIENT.client_Cd, 'PAID'),0) paid_ipo								
	FROM T_IPO_CLIENT, MST_CLIENT, T_PEE									
	WHERE T_IPO_CLIENT.stk_cd = p_stk_cd									
	AND T_IPO_CLIENT.approved_stat = 'A'									
	AND T_IPO_CLIENT.client_Cd = MST_CLIENT.client_Cd									
	AND T_IPO_CLIENT.stk_cd =  T_PEE.stk_cd
    AND MST_CLIENT.CLIENT_CD LIKE '%'||P_CLIENT_CD
  AND MST_CLIENT.BRANCH_CODE LIKE '%'||P_BRANCH_CD)									
	WHERE  paid_ipo < fund_ipo ;
						
 V_ERR EXCEPTION;
V_ERROR_CODE NUMBER;
V_ERROR_MSG VARCHAR(200); 
V_OFFER_DT_TO T_PEE.OFFER_DT_TO%TYPE;
V_OFFER_DT_FR T_PEE.OFFER_DT_FR%TYPE;
V_DISTRIB_DT_TO T_PEE.DISTRIB_DT_TO%TYPE;
V_ALLOCATE_DT T_PEE.ALLOCATE_DT%TYPE;
V_PAYM_DT T_PEE.PAYM_DT%TYPE;
V_PRICE T_PEE.PRICE%TYPE;
V_MENU_NAME VARCHAR2(100):='IPO FUND ENTRY';
V_UPDATE_DATE T_MANY_HEADER.UPDATE_DATE%TYPE;
V_UPDATE_SEQ T_MANY_HEADER.UPDATE_SEQ%TYPE;
V_DOC_NUM T_FUND_MOVEMENT.DOC_NUM%TYPE;
V_TRX_TYPE T_FUND_MOVEMENT.TRX_TYPE%TYPE;
V_BRANCH_CODE MST_CLIENT.BRANCH_CODE%TYPE;
V_REMARKS T_FUND_MOVEMENT.REMARKS%TYPE;
V_BANK_CD MST_CLIENT_FLACCT.BANK_CD%TYPE;
V_BANK_ACCT_NUM MST_CLIENT_FLACCT.BANK_ACCT_NUM%TYPE;
V_ACCT_CD T_FUND_LEDGER.ACCT_CD%TYPE;
V_DEBIT T_FUND_MOVEMENT.TRX_AMT%TYPE;
V_CREDIT T_FUND_MOVEMENT.TRX_AMT%TYPE;
V_PAYREC_NUM T_PAYRECH.PAYREC_NUM%TYPE;
V_ACCT_TYPE T_PAYRECH.ACCT_TYPE%TYPE;
V_GL_ACCT_CD T_PAYRECH.GL_aCCT_CD%TYPE;
V_SL_ACCT_CD T_PAYRECH.SL_ACCT_CD%TYPE;
--V_GL_ACCT_HUTANG T_PAYRECH.GL_aCCT_CD%TYPE;
--V_SL_ACCT_HUTANG T_PAYRECH.SL_ACCT_CD%TYPE;
V_PAYREC_TYPE T_PAYRECH.PAYREC_TYPE%TYPE;
V_TOTAL_AMOUNT T_PAYRECH.CURR_AMT%TYPE;
V_DOC_REF_NUM T_PAYRECD.DOC_REF_NUM%TYPE;
V_DB_CR_FLG T_ACCOUNT_LEDGER.DB_CR_FLG%TYPE;
V_SIGN VARCHAR2(1);
V_FLD_MON T_FOLDER.FLD_MON%TYPE;
V_RECORD_SEQ NUMBER;
V_SEQ_LEDGER NUMBER;
V_RTN NUMBER;
V_DOC_DATE DATE;
V_USER_ID VARCHAR2(10);
V_CNT NUMBER;
V_SEQ_FUND NUMBER;
V_IPO_BANK_CD T_PEE.IPO_BANK_CD%TYPE;
V_IPO_BANK_ACCT T_PEE.IPO_BANK_ACCT%TYPE;
BEGIN

BEGIN
	SELECT OFFER_DT_FR,OFFER_DT_TO,DISTRIB_DT_TO,ALLOCATE_DT,PAYM_DT,PRICE,IPO_BANK_CD,IPO_BANK_ACCT INTO
		V_OFFER_DT_FR, V_OFFER_DT_TO, V_DISTRIB_DT_TO, V_ALLOCATE_DT, V_PAYM_DT, V_PRICE,V_IPO_BANK_CD,V_IPO_BANK_ACCT FROM T_PEE WHERE STK_CD=P_STK_CD;
EXCEPTION
   WHEN OTHERS THEN
				     V_ERROR_CODE := -10;
					 V_ERROR_MSG :=  SUBSTR('SELECT TPEE '||SQLERRM,1,200);
					 RAISE v_err;
	END;

		
	BEGIN
		SELECT DFLG1 INTO V_SIGN FROM MST_SYS_PARAM WHERE PARAM_ID='SYSTEM' AND PARAM_CD1='DOC_REF';
	EXCEPTION
		WHEN OTHERS THEN
		 V_ERROR_CODE := -20;
		 V_ERROR_MSG :=  SUBSTR('CEK SIGN DOC REF FROM SYSTEM '||SQLERRM,1,200);
		 RAISE v_err;
	END;
	
	IF P_TAHAP= 'PENERIMAAN' THEN    
	
	V_TRX_TYPE :='O';
	V_REMARKS :='Pemesanan IPO '|| p_stk_cd;
	
		FOR REC IN CSR_PENERIMAAN_DANA LOOP
		
		
		BEGIN
			 select COUNT(1) INTO V_CNT from (SELECT
						 (SELECT TO_DATE(FIELD_VALUE,'YYYY/MM/DD HH24:MI:SS') FROM T_MANY_DETAIL DA 
								WHERE DA.TABLE_NAME = 'T_FUND_MOVEMENT' 
								AND DA.UPDATE_DATE = DD.UPDATE_DATE
								AND DA.UPDATE_SEQ = DD.UPDATE_SEQ
								AND DA.FIELD_NAME = 'DOC_DATE'
								AND DA.RECORD_SEQ = DD.RECORD_SEQ) DOC_DATE, 
						(SELECT FIELD_VALUE FROM T_MANY_DETAIL DA 
								WHERE DA.TABLE_NAME = 'T_FUND_MOVEMENT' 
								AND DA.UPDATE_DATE = DD.UPDATE_DATE
								AND DA.UPDATE_SEQ = DD.UPDATE_SEQ
								AND DA.FIELD_NAME = 'TRX_TYPE'
								AND DA.RECORD_SEQ = DD.RECORD_SEQ) TRX_TYPE, 
						(SELECT FIELD_VALUE FROM T_MANY_DETAIL DA 
								WHERE DA.TABLE_NAME = 'T_FUND_MOVEMENT' 
								AND DA.UPDATE_DATE = DD.UPDATE_DATE
								AND DA.UPDATE_SEQ = DD.UPDATE_SEQ
								AND DA.FIELD_NAME = 'CLIENT_CD'
								AND DA.RECORD_SEQ = DD.RECORD_SEQ) CLIENT_CD,
						(SELECT FIELD_VALUE FROM T_MANY_DETAIL DA 
								WHERE DA.TABLE_NAME = 'T_FUND_MOVEMENT' 
								AND DA.UPDATE_DATE = DD.UPDATE_DATE
								AND DA.UPDATE_SEQ = DD.UPDATE_SEQ
								AND DA.FIELD_NAME = 'TRX_AMT'
								AND DA.RECORD_SEQ = DD.RECORD_SEQ) TRX_AMT
						FROM T_MANY_DETAIL DD, T_MANY_HEADER HH WHERE DD.TABLE_NAME = 'T_FUND_MOVEMENT' AND DD.UPDATE_DATE = HH.UPDATE_DATE
											  AND DD.UPDATE_SEQ = HH.UPDATE_SEQ  AND  DD.RECORD_SEQ =1
											 AND DD.FIELD_NAME = 'DOC_DATE' AND HH.APPROVED_STATUS = 'E' ORDER BY HH.UPDATE_SEQ
											 )
											 where client_cd=REC.CLIENT_CD AND TRX_TYPE=V_TRX_TYPE AND TRX_AMT=REC.AMOUNT and doc_date=V_OFFER_DT_FR;
            EXCEPTION
              WHEN OTHERS THEN
                 V_ERROR_CODE := -25;
                 V_ERROR_MSG := SUBSTR('CEK PENDING INBOX  '|| SQLERRM(SQLCODE),1,200);
                RAISE V_ERR;
            END;          
		IF V_CNT>0 THEN
				V_ERROR_CODE := -27;
                 V_ERROR_MSG := 'Masih belum diapprove';
                RAISE V_ERR;
		END IF;
		
		BEGIN
			SELECT COUNT(1) INTO V_CNT FROM T_FUND_MOVEMENT 
			WHERE DOC_DATE=V_OFFER_DT_FR AND SOURCE='IPO' AND SL_ACCT_CD=P_STK_CD AND CLIENT_CD=REC.CLIENT_CD AND TRX_AMT =REC.AMOUNT;
		EXCEPTION
		WHEN NO_DATA_FOUND THEN
			NULL;
		WHEN OTHERS THEN
			V_ERROR_CODE := -28;
            V_ERROR_MSG := SUBSTR('CEK JURNAL T FUND MOVEMENT'|| SQLERRM(SQLCODE),1,200);
            RAISE V_ERR;
		END;
		
		IF V_CNT>0 THEN
            V_ERROR_CODE := -29;
            V_ERROR_MSG := 'Client '|| REC.CLIENT_CD ||' sudah dijurnal';
            RAISE V_ERR;
		END IF;
		/*
    IF REC.AMOUNT> REC.BAL_RDI THEN
            V_ERROR_CODE := -30;
            V_ERROR_MSG := 'Amount '|| REC.CLIENT_CD ||' harus lebih besar dari saldo saat ini';
            RAISE V_ERR;
    END IF;
    IF REC.AMOUNT = 0 THEN
            V_ERROR_CODE := -31;
            V_ERROR_MSG := REC.CLIENT_CD ||' amount 0, client tidak disimpan';
            RAISE V_ERR;
    END IF;
    */
    
		--INSERT KE T MANY HEADER
			--EXECUTE SP HEADER
         BEGIN
        Sp_T_Many_Header_Insert(V_MENU_NAME,
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
                 V_ERROR_CODE := -31;
                 V_ERROR_MSG := SUBSTR('SP_T_MANY_HEADER_INSERT '|| SQLERRM(SQLCODE),1,200);
                RAISE V_ERR;
            END;
			
			BEGIN
				SELECT BRANCH_CODE INTO V_BRANCH_CODE FROM MST_CLIENT WHERE CLIENT_CD= REC.CLIENT_CD;
			 EXCEPTION
              WHEN OTHERS THEN
                 V_ERROR_CODE := -40;
                 V_ERROR_MSG := SUBSTR(' FIND BRACNH CODE FOR CLIENT '|| REC.CLIENT_CD||' '|| SQLERRM(SQLCODE),1,200);
                RAISE V_ERR;
            END;
			BEGIN
				SELECT BANK_CD,BANK_ACCT_NUM INTO V_BANK_CD,V_BANK_ACCT_NUM FROM MST_CLIENT_FLACCT WHERE CLIENT_CD= REC.CLIENT_CD AND ACCT_STAT <> 'C' ;
			 EXCEPTION
              WHEN OTHERS THEN
                 V_ERROR_CODE := -50;
                 V_ERROR_MSG := SUBSTR('FIND BANK_CD AND BANK_ACCT_NUM MST_CLIENT_FLACCT '|| REC.CLIENT_CD||' '||SQLERRM(SQLCODE),1,200);
                RAISE V_ERR;
            END;
			
      
      
			--INSERT KE T FUND MOVEMENT
			
			 V_DOC_NUM :=Get_Docnum_Fund (v_offer_dt_fr, V_TRX_TYPE);
			
			
			BEGIN
			 Sp_T_FUND_MOVEMENT_UPD(V_DOC_NUM,
									V_DOC_NUM,
									V_OFFER_DT_FR,
									V_TRX_TYPE,
									REC.CLIENT_CD,
									TRIM(V_BRANCH_CODE),
									'IPO',--P_SOURCE,
								  null,--P_DOC_REF_NUM,
								  NULL,--P_TAL_ID_REF,
								  NULL,--P_GL_ACCT_CD,
								  P_STK_CD,--P_SL_ACCT_CD,
								  NULL,--P_BANK_REF_NUM,
									NULL,--P_BANK_MVMT_DATE,
									REC.CLIENT_NAME,--P_ACCT_NAME,
									V_REMARKS,
									REC.CLIENT_CD,--P_FROM_CLIENT,
									V_BANK_ACCT_NUM,--P_FROM_ACCT,
									V_BANK_CD,--P_FROM_BANK,
									REC.CLIENT_CD,--P_TO_CLIENT,
									V_BANK_ACCT_NUM,--P_TO_ACCT,
									V_BANK_CD,--P_TO_BANK,
									REC.AMOUNT,--P_TRX_AMT,
									sysdate,--P_CRE_DT,
									P_USER_ID,
									null,--P_CANCEL_DT,
									null,--P_CANCEL_BY,
									0,--P_FEE,
									P_FOLDER_CD,--P_FOLDER_CD,
									V_BANK_CD,--P_FUND_BANK_CD,
									V_BANK_ACCT_NUM,--P_FUND_BANK_ACCT,
									null,--P_UPD_DT,
									null,--P_UPD_BY,
									'I',--P_UPD_STATUS,
									p_ip_address,
									null,--p_cancel_reason,
									V_UPDATE_DATE,
									V_UPDATE_SEQ,
									1,
									V_ERROR_CODE,
									V_ERROR_MSG);
			  EXCEPTION
              WHEN OTHERS THEN
                 V_ERROR_CODE := -60;
                 V_ERROR_MSG := SUBSTR('Sp_T_FUND_MOVEMENT_UPD '|| SQLERRM(SQLCODE),1,200);
                RAISE V_ERR;
            END;
		IF 	V_ERROR_CODE<0 THEN
				V_ERROR_CODE := -70;
                V_ERROR_MSG := SUBSTR('Sp_T_FUND_MOVEMENT_UPD '|| V_ERROR_MSG,1,200);
                RAISE V_ERR;
		END IF;		
						
		--SAVE KE T FUND LEDGER
				V_RECORD_SEQ:=1;
				FOR J IN 1..2 LOOP
				
				IF J =1 THEN
						V_ACCT_CD :='DNU';
						V_DEBIT := REC.AMOUNT;
						V_CREDIT :=0;
				ELSE
						V_ACCT_CD :='KNU';
						V_DEBIT :=0;
						V_CREDIT := REC.AMOUNT;
				END IF;
				
				
				BEGIN
				 Sp_T_FUND_LEDGER_UPD(	V_DOC_NUM,
										J,
										V_DOC_NUM,
										J,
										V_TRX_TYPE,
										V_OFFER_DT_FR,
										V_ACCT_CD,
										REC.CLIENT_CD,
										V_DEBIT,--P_DEBIT,
										V_CREDIT,--P_CREDIT,
										SYSDATE,--P_CRE_DT,
										P_USER_ID,
										NULL,--P_CANCEL_DT,
										NULL,--P_CANCEL_BY,
										NULL,--P_UPD_DT,
										NULL,--P_UPD_BY,
										'N',--P_MANUAL
										'I',--P_UPD_STATUS,
										p_ip_address,
										NULL,--p_cancel_reason,
										V_UPDATE_DATE,--p_update_date,
										V_UPDATE_SEQ,--p_update_seq,
										V_RECORD_SEQ,--p_record_seq,
										V_ERROR_CODE,
										V_ERROR_MSG);
			EXCEPTION
              WHEN OTHERS THEN
                 V_ERROR_CODE := -80;
                 V_ERROR_MSG := SUBSTR('Sp_T_FUND_LEDGER_UPD '|| SQLERRM(SQLCODE),1,200);
                RAISE V_ERR;
            END;
			IF 	V_ERROR_CODE<0 THEN
					V_ERROR_CODE := -90;
					V_ERROR_MSG := SUBSTR('Sp_T_FUND_LEDGER_UPD '|| V_ERROR_MSG,1,200);
					RAISE V_ERR;
			END IF;					
									
			IF 	V_ACCT_CD = 'DNU' THEN

					--SAVE KE T IPO FUND
					BEGIN
					 SP_T_IPO_FUND_UPD(	P_STK_CD,--P_SEARCH_STK_CD,
										REC.CLIENT_CD,--P_SEARCH_CLIENT_CD,
										P_STK_CD,
										REC.CLIENT_CD,--P_CLIENT_CD,
										'ALOKASI',--P_TAHAP,
										V_DOC_NUM,--P_DOC_NUM,
										SYSDATE,--P_CRE_DT,
										P_USER_ID,
										'I',--P_UPD_STATUS,
										p_ip_address,
										NULL,--p_cancel_reason,
										V_UPDATE_DATE,--p_update_date,
										V_UPDATE_SEQ,--p_update_seq,
										1,--p_record_seq,
										V_ERROR_CODE,
										V_ERROR_MSG); 
					EXCEPTION
					  WHEN OTHERS THEN
						 V_ERROR_CODE := -100;
						 V_ERROR_MSG := SUBSTR('SP_T_IPO_FUND_UPD '|| SQLERRM(SQLCODE),1,200);
						RAISE V_ERR;
					END;
					
					IF 	V_ERROR_CODE<0 THEN
							V_ERROR_CODE := -110;
							V_ERROR_MSG := SUBSTR('SP_T_IPO_FUND_UPD '|| V_ERROR_MSG,1,200);
							RAISE V_ERR;
					END IF;		
			
			END IF;		
			V_RECORD_SEQ := V_RECORD_SEQ+1;			
		END LOOP;
			
		
			
		END LOOP;
	
	ELSIF P_TAHAP='PENJATAHAN' THEN
		
			--EXECUTE SP HEADER
         BEGIN
        Sp_T_Many_Header_Insert(V_MENU_NAME,
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
                 V_ERROR_CODE := -120;
                 V_ERROR_MSG := SUBSTR('SP_T_MANY_HEADER_INSERT '|| SQLERRM(SQLCODE),1,200);
                RAISE V_ERR;
            END;
			
		IF 	P_SL_ACCT_CD_BANK IS NOT NULL  AND P_GL_ACCT_CD_BANK IS NOT NULL AND P_GL_ACCT_CD_HUTANG IS NOT NULL AND P_SL_ACCT_CD_HUTANG IS NOT NULL THEN
			
		V_PAYREC_TYPE :='RD';
		V_REMARKS :=P_REMARKS;
		V_TOTAL_AMOUNT :=0;
		--V_DOC_REF_NUM := TO_CHAR(V_ALLOCATE_DT ,'ddMM')||'ZZ1234567';
			BEGIN
			SP_T_PAYRECH_UPD (	V_PAYREC_NUM,--P_SEARCH_PAYREC_NUM,
								V_PAYREC_NUM,--P_PAYREC_NUM,
								V_PAYREC_TYPE,--P_PAYREC_TYPE,
								V_ALLOCATE_DT,--P_PAYREC_DATE,
								NULL,--P_ACCT_TYPE,
								P_SL_ACCT_CD_BANK,--P_SL_ACCT_CD,
								'IDR',--P_CURR_CD,
								V_TOTAL_AMOUNT,--P_CURR_AMT,
								NULL,--P_PAYREC_FRTO,
								V_REMARKS,--P_REMARKS,
								P_GL_ACCT_CD_BANK,--P_GL_ACCT_CD,
								NULL,--P_CLIENT_CD,
								NULL,--P_CHECK_NUM,
								P_FOLDER_CD,
								NULL,--P_NUM_CHEQ,
								NULL,--P_CLIENT_BANK_ACCT,
								NULL,--P_CLIENT_BANK_NAME,
								'N',--P_REVERSAL_JUR,
								P_USER_ID,
								SYSDATE,--P_CRE_DT,
								NULL,--P_UPD_BY,
								NULL,--P_UPD_DT,
								'I',--P_UPD_STATUS,
								p_ip_address,
								NULL,--p_cancel_reason,
								V_UPDATE_DATE,--p_update_date,
								V_UPDATE_SEQ,--p_update_seq,
								1,--p_record_seq,
								V_ERROR_CODE,
								V_ERROR_MSG); 
		EXCEPTION
			WHEN OTHERS THEN
				 V_ERROR_CODE := -130;
				 V_ERROR_MSG := SUBSTR('Sp_T_FUND_MOVEMENT_UPD '|| SQLERRM(SQLCODE),1,200);
				RAISE V_ERR;
			END;
		IF 	V_ERROR_CODE<0 THEN
			V_ERROR_CODE := -140;
			V_ERROR_MSG := SUBSTR('Sp_T_FUND_MOVEMENT_UPD '|| V_ERROR_MSG,1,200);
			RAISE V_ERR;
		END IF;		
		
		BEGIN
		Sp_T_PAYRECD_Upd(	V_PAYREC_NUM,--P_SEARCH_PAYREC_NUM,
							V_PAYREC_NUM,--P_SEARCH_DOC_REF_NUM,
							2,--P_SEARCH_TAL_ID,
							V_PAYREC_NUM,--P_PAYREC_NUM,
							V_PAYREC_TYPE,--P_PAYREC_TYPE,
							V_ALLOCATE_DT,--P_PAYREC_DATE,
							NULL,--P_CLIENT_CD,
							P_GL_ACCT_CD_HUTANG,--P_GL_ACCT_CD,
							P_SL_ACCT_CD_HUTANG,--P_SL_ACCT_CD,
							'C',--P_DB_CR_FLG,
							0,--P_PAYREC_AMT,
							V_PAYREC_NUM,--P_DOC_REF_NUM,
							2,--P_TAL_ID,
							V_REMARKS,--P_REMARKS,
							'VCH',--P_RECORD_SOURCE,
							V_ALLOCATE_DT,--P_DOC_DATE,
							NULL,--P_REF_FOLDER_CD,
							NULL,--P_GL_REF_NUM,
							0,--P_SETT_FOR_CURR,
							0,--P_SETT_VAL,
							NULL,--P_BRCH_CD,
							NULL,--_DOC_TAL_ID,
							null,--P_SOURCE_TYPE,
							V_ALLOCATE_DT,--P_DUE_DATE,
							P_USER_ID,
							SYSDATE,--P_CRE_DT,
							NULL,--P_UPD_BY,
							NULL,--P_UPD_DT,
							'I',--P_UPD_STATUS,
							p_ip_address,
							NULL,--p_cancel_reason,
							V_UPDATE_DATE,--p_update_date,
							V_UPDATE_SEQ,--p_update_seq,
							1,--p_record_seq,
							V_ERROR_CODE,
							V_ERROR_MSG);
		EXCEPTION
			WHEN OTHERS THEN
				 V_ERROR_CODE := -150;
				 V_ERROR_MSG := SUBSTR('Sp_T_PAYRECD_Upd '|| SQLERRM(SQLCODE),1,200);
				RAISE V_ERR;
			END;
		IF 	V_ERROR_CODE<0 THEN
			V_ERROR_CODE := -160;
			V_ERROR_MSG := SUBSTR('Sp_T_PAYRECD_Upd '|| V_ERROR_MSG,1,200);
			RAISE V_ERR;
		END IF;		
		
		
		
	FOR I IN 1..2 LOOP
	
		IF I =1 THEN
			V_DB_CR_FLG :='D';
			V_GL_ACCT_CD:= P_GL_ACCT_CD_BANK;
			V_SL_ACCT_CD :=P_SL_ACCT_CD_BANK;
		ELSE
			V_DB_CR_FLG :='C';
			V_GL_ACCT_CD := P_GL_ACCT_CD_HUTANG;
			V_SL_ACCT_CD := P_SL_ACCT_CD_HUTANG;
		END IF;
		
		IF V_SIGN ='Y' THEN
			V_DOC_REF_NUM:=V_PAYREC_NUM;
		END IF;
		
		
		BEGIN
		 Sp_T_ACCOUNT_LEDGER_Upd(	V_PAYREC_NUM,--P_SEARCH_XN_DOC_NUM,
									I,--P_SEARCH_TAL_ID,
									V_PAYREC_NUM,--P_XN_DOC_NUM,
									I,--P_TAL_ID,
									V_DOC_REF_NUM,--P_DOC_REF_NUM,
									NULL,--P_ACCT_TYPE,
									V_SL_ACCT_CD,--P_SL_ACCT_CD,
									V_GL_ACCT_CD,--P_GL_ACCT_CD,
									NULL,--P_CHRG_CD,
									NULL,--P_CHQ_SNO,
									'IDR',--P_CURR_CD,
									NULL,--P_BRCH_CD,
									0,--P_CURR_VAL,
									0,--P_XN_VAL,
									'RVCH',--P_BUDGET_CD,
									V_DB_CR_FLG,--P_DB_CR_FLG,
									V_REMARKS,--P_LEDGER_NAR,
									NULL,--P_CASHIER_ID,
									V_ALLOCATE_DT,--P_DOC_DATE,
									V_ALLOCATE_DT,--P_DUE_DATE,
									NULL,--P_NETTING_DATE,
									NULL,--P_NETTING_FLG,
									'RD',--P_RECORD_SOURCE,
									0,--P_SETT_FOR_CURR,
									NULL,--P_SETT_STATUS,
									NULL,--P_RVPV_NUMBER,
									P_FOLDER_CD,
									0,--P_SETT_VAL,
									V_ALLOCATE_DT,--P_ARAP_DUE_DATE,
									NULL,--P_RVPV_GSSL,
									P_USER_ID,
									SYSDATE,--P_CRE_DT,
									NULL,--P_UPD_BY,
									NULL,--P_UPD_DT,
									'N',--P_REVERSAL_JUR,
									'Y',--P_MANUAL,
									'I',--P_UPD_STATUS,
									p_ip_address,
									NULL,--p_cancel_reason,
									V_UPDATE_DATE,--p_update_date,
									V_UPDATE_SEQ,--p_update_seq,
									I,--p_record_seq,
									p_error_code,
									p_error_msg);
		EXCEPTION
			WHEN OTHERS THEN
				 V_ERROR_CODE := -170;
				 V_ERROR_MSG := SUBSTR('Sp_T_ACCOUNT_LEDGER_Upd '|| SQLERRM(SQLCODE),1,200);
				RAISE V_ERR;
			END;
		IF 	V_ERROR_CODE<0 THEN
			V_ERROR_CODE := -180;
			V_ERROR_MSG := SUBSTR('Sp_T_ACCOUNT_LEDGER_Upd '|| V_ERROR_MSG,1,200);
			RAISE V_ERR;
		END IF;		
		
	END LOOP;
	
	
	BEGIN
	SP_CHECK_FOLDER_CD(	P_FOLDER_CD,
						V_ALLOCATE_DT,
						V_RTN,
						V_PAYREC_NUM,
						V_USER_ID,
						V_DOC_DATE);
			EXCEPTION
			WHEN OTHERS THEN
				 V_ERROR_CODE := -190;
				 V_ERROR_MSG := SUBSTR('SP_CHECK_FOLDER_CD '|| SQLERRM(SQLCODE),1,200);
				RAISE V_ERR;
			END;
		IF 	V_ERROR_CODE<0 THEN
			V_ERROR_CODE := -200;
			V_ERROR_MSG := SUBSTR('SP_CHECK_FOLDER_CD '|| V_ERROR_MSG,1,200);
			RAISE V_ERR;
		END IF;		
		
		IF V_RTN=1 THEN
			V_ERROR_CODE := -210;
			V_ERROR_MSG := 'File Code '||P_FOLDER_CD||' is already used by '||V_USER_ID|| ' '||V_PAYREC_NUM|| ' '||  TO_CHAR(V_PAYM_DT,'DD-MON-YYYY');
			RAISE V_ERR;
		
		END IF;
		
	
		
		V_FLD_MON :=TO_CHAR(V_ALLOCATE_DT,'MMYY');
		BEGIN
		 SP_T_FOLDER_UPD (V_PAYREC_NUM,--P_SEARCH_DOC_NUM,
							V_FLD_MON,--P_FLD_MON,
							P_FOLDER_CD,
							V_ALLOCATE_DT,--P_DOC_DATE,
							V_PAYREC_NUM,--P_DOC_NUM,
							P_USER_ID,
							SYSDATE,--P_CRE_DT,
							NULL,--P_UPD_BY,
							NULL,--P_UPD_DT,
							'I',--P_UPD_STATUS,
							p_ip_address,
							NULL,--p_cancel_reason,
							V_UPDATE_DATE,--p_update_date,
							V_UPDATE_SEQ,--p_update_seq,
							1,--p_record_seq,
							V_ERROR_CODE,
							V_ERROR_MSG);
		EXCEPTION
			WHEN OTHERS THEN
				 V_ERROR_CODE := -220;
				 V_ERROR_MSG := SUBSTR('SP_T_FOLDER_UPD '|| SQLERRM(SQLCODE),1,200);
				RAISE V_ERR;
			END;
		IF 	V_ERROR_CODE<0 THEN
			V_ERROR_CODE := -230;
			V_ERROR_MSG := SUBSTR('Sp_T_ACCOUNT_LEDGER_Upd '|| V_ERROR_MSG,1,200);
			RAISE V_ERR;
		END IF;		
		
		END IF;
		
		V_RECORD_SEQ:=2;
		V_SEQ_LEDGER :=1;
		
		FOR REC IN CSR_PENJATAHAN LOOP
		
			BEGIN
			SELECT COUNT(1) INTO V_CNT FROM T_FUND_MOVEMENT 
			WHERE DOC_DATE=V_ALLOCATE_DT AND SOURCE='IPO' AND SL_ACCT_CD=P_STK_CD AND TRX_TYPE='O' AND CLIENT_CD=REC.CLIENT_CD AND TRX_AMT =REC.AMOUNT;
		EXCEPTION
		WHEN NO_DATA_FOUND THEN
			NULL;
		WHEN OTHERS THEN
			V_ERROR_CODE := -231;
            V_ERROR_MSG := SUBSTR('CEK JURNAL T FUND MOVEMENT'|| SQLERRM(SQLCODE),1,200);
            RAISE V_ERR;
		END;
		
		IF V_CNT>0 THEN
			V_ERROR_CODE := -232;
            V_ERROR_MSG := 'Client '|| REC.CLIENT_CD ||' sudah dijurnal ';
            RAISE V_ERR;
		END IF;
		
		
		
			V_REMARKS :=P_REMARKS;
			V_TRX_TYPE :='O';
			V_DOC_NUM := GET_DOCNUM_FUND(V_ALLOCATE_DT,'W');
			
			BEGIN
			 select COUNT(1) INTO V_CNT from (SELECT
						 (SELECT TO_DATE(FIELD_VALUE,'YYYY/MM/DD HH24:MI:SS') FROM T_MANY_DETAIL DA 
								WHERE DA.TABLE_NAME = 'T_FUND_MOVEMENT' 
								AND DA.UPDATE_DATE = DD.UPDATE_DATE
								AND DA.UPDATE_SEQ = DD.UPDATE_SEQ
								AND DA.FIELD_NAME = 'DOC_DATE'
								AND DA.RECORD_SEQ = DD.RECORD_SEQ) DOC_DATE, 
						(SELECT FIELD_VALUE FROM T_MANY_DETAIL DA 
								WHERE DA.TABLE_NAME = 'T_FUND_MOVEMENT' 
								AND DA.UPDATE_DATE = DD.UPDATE_DATE
								AND DA.UPDATE_SEQ = DD.UPDATE_SEQ
								AND DA.FIELD_NAME = 'TRX_TYPE'
								AND DA.RECORD_SEQ = DD.RECORD_SEQ) TRX_TYPE, 
						(SELECT FIELD_VALUE FROM T_MANY_DETAIL DA 
								WHERE DA.TABLE_NAME = 'T_FUND_MOVEMENT' 
								AND DA.UPDATE_DATE = DD.UPDATE_DATE
								AND DA.UPDATE_SEQ = DD.UPDATE_SEQ
								AND DA.FIELD_NAME = 'CLIENT_CD'
								AND DA.RECORD_SEQ = DD.RECORD_SEQ) CLIENT_CD,
						(SELECT FIELD_VALUE FROM T_MANY_DETAIL DA 
								WHERE DA.TABLE_NAME = 'T_FUND_MOVEMENT' 
								AND DA.UPDATE_DATE = DD.UPDATE_DATE
								AND DA.UPDATE_SEQ = DD.UPDATE_SEQ
								AND DA.FIELD_NAME = 'TRX_AMT'
								AND DA.RECORD_SEQ = DD.RECORD_SEQ) TRX_AMT
						FROM T_MANY_DETAIL DD, T_MANY_HEADER HH WHERE DD.TABLE_NAME = 'T_FUND_MOVEMENT' AND DD.UPDATE_DATE = HH.UPDATE_DATE
											  AND DD.UPDATE_SEQ = HH.UPDATE_SEQ  AND  DD.RECORD_SEQ =DECODE(P_GL_ACCT_CD_BANK,NULL,1,2)
											 AND DD.FIELD_NAME = 'DOC_DATE' AND HH.APPROVED_STATUS = 'E' ORDER BY HH.UPDATE_SEQ
											 )
											 where client_cd=REC.CLIENT_CD AND TRX_TYPE=V_TRX_TYPE AND TRX_AMT=REC.AMOUNT and doc_date= v_allocate_dt;
            EXCEPTION
              WHEN OTHERS THEN
                 V_ERROR_CODE := -235;
                 V_ERROR_MSG := SUBSTR('CEK PENDING INBOX  '|| SQLERRM(SQLCODE),1,200);
                RAISE V_ERR;
            END;          
		IF V_CNT>0 THEN
				V_ERROR_CODE := -237;
                 V_ERROR_MSG := 'Masih belum diapprove';
                RAISE V_ERR;
		END IF;
		
		
			
			
			BEGIN
				SELECT BRANCH_CODE INTO V_BRANCH_CODE FROM MST_CLIENT WHERE CLIENT_CD= REC.CLIENT_CD;
			 EXCEPTION
              WHEN OTHERS THEN
                 V_ERROR_CODE := -240;
                  V_ERROR_MSG := SUBSTR(' FIND BRACNH CODE FOR CLIENT '|| REC.CLIENT_CD||' '|| SQLERRM(SQLCODE),1,200);
                RAISE V_ERR;
            END;
			
			BEGIN
				SELECT BANK_CD,BANK_ACCT_NUM INTO V_BANK_CD,V_BANK_ACCT_NUM FROM MST_CLIENT_FLACCT WHERE CLIENT_CD= REC.CLIENT_CD AND ACCT_STAT <> 'C' ;
			 EXCEPTION
              WHEN OTHERS THEN
                 V_ERROR_CODE := -250;
                 V_ERROR_MSG := SUBSTR('FIND BANK_CD AND BANK_ACCT_NUM MST_CLIENT_FLACCT  '|| SQLERRM(SQLCODE),1,200);
                RAISE V_ERR;
            END;
			
			
			
			V_TOTAL_AMOUNT :=REC.AMOUNT;
			
			IF 	P_SL_ACCT_CD_BANK IS NOT NULL  AND P_GL_ACCT_CD_BANK IS NOT NULL AND P_GL_ACCT_CD_HUTANG IS NOT NULL AND P_SL_ACCT_CD_HUTANG IS NOT NULL THEN
				V_SEQ_FUND := V_RECORD_SEQ;
			ELSE
				V_SEQ_FUND := 1;
			END IF;
			
			BEGIN
			 Sp_T_FUND_MOVEMENT_UPD(V_DOC_NUM,
									V_DOC_NUM,
									V_ALLOCATE_DT,
									V_TRX_TYPE,
									REC.CLIENT_CD,
									TRIM(V_BRANCH_CODE),
									'IPO',--P_SOURCE,
									  null,--P_DOC_REF_NUM,
									  NULL,--P_TAL_ID_REF,
									  NULL,--P_GL_ACCT_CD,
									  P_STK_CD,--P_SL_ACCT_CD,
									  NULL,--P_BANK_REF_NUM,
									NULL,--P_BANK_MVMT_DATE,
									REC.CLIENT_NAME,--P_ACCT_NAME,
									V_REMARKS,
									REC.CLIENT_CD,--P_FROM_CLIENT,
									V_IPO_BANK_ACCT,--P_FROM_ACCT,
									V_IPO_BANK_CD,--P_FROM_BANK,
									REC.CLIENT_CD,--P_TO_CLIENT,
									'-',--P_TO_ACCT,
									'LUAR',--P_TO_BANK,
									REC.AMOUNT,--P_TRX_AMT,
									sysdate,--P_CRE_DT,
									P_USER_ID,
									null,--P_CANCEL_DT,
									null,--P_CANCEL_BY,
									0,--P_FEE,
									P_FOLDER_CD,--P_FOLDER_CD,
									V_BANK_CD,--P_FUND_BANK_CD,
									V_BANK_ACCT_NUM,--P_FUND_BANK_ACCT,
									null,--P_UPD_DT,
									null,--P_UPD_BY,
									'I',--P_UPD_STATUS,
									p_ip_address,
									null,--p_cancel_reason,
									V_UPDATE_DATE,
									V_UPDATE_SEQ,
									V_SEQ_FUND,
									V_ERROR_CODE,
									V_ERROR_MSG);
			  EXCEPTION
              WHEN OTHERS THEN
                 V_ERROR_CODE := -260;
                 V_ERROR_MSG := SUBSTR('Sp_T_FUND_MOVEMENT_UPD '|| SQLERRM(SQLCODE),1,200);
                RAISE V_ERR;
            END;
		IF 	V_ERROR_CODE<0 THEN
				V_ERROR_CODE := -270;
                V_ERROR_MSG := SUBSTR('Sp_T_FUND_MOVEMENT_UPD '|| V_ERROR_MSG,1,200);
                RAISE V_ERR;
		END IF;		
				FOR J IN 1..2 LOOP
					IF  J=1 THEN
						V_ACCT_CD :='KNU';
						V_DEBIT := REC.AMOUNT;
						V_CREDIT :=0;
					 ELSE
						V_ACCT_CD :='DNU';
						V_DEBIT := 0;
						V_CREDIT :=REC.AMOUNT;
					END IF;
				BEGIN
				Sp_T_FUND_LEDGER_UPD(	V_DOC_NUM,
										J,
										V_DOC_NUM,
										J,
										V_TRX_TYPE,
										V_ALLOCATE_DT,
										V_ACCT_CD,
										REC.CLIENT_CD,
										V_DEBIT,--P_DEBIT,
										V_CREDIT,--P_CREDIT,
										SYSDATE,--P_CRE_DT,
										P_USER_ID,
										NULL,--P_CANCEL_DT,
										NULL,--P_CANCEL_BY,
										NULL,--P_UPD_DT,
										NULL,--P_UPD_BY,
										'N',--P_MANUAL
										'I',--P_UPD_STATUS,
										p_ip_address,
										NULL,--p_cancel_reason,
										V_UPDATE_DATE,--p_update_date,
										V_UPDATE_SEQ,--p_update_seq,
										V_SEQ_LEDGER,--p_record_seq,
										V_ERROR_CODE,
										V_ERROR_MSG);
				EXCEPTION
				  WHEN OTHERS THEN
					 V_ERROR_CODE := -280;
					 V_ERROR_MSG := SUBSTR('Sp_T_FUND_LEDGER_UPD '|| SQLERRM(SQLCODE),1,200);
					RAISE V_ERR;
				END;
				IF 	V_ERROR_CODE<0 THEN
						V_ERROR_CODE := -290;
						V_ERROR_MSG := SUBSTR('Sp_T_FUND_LEDGER_UPD '|| V_ERROR_MSG,1,200);
						RAISE V_ERR;
				END IF;	
        V_SEQ_LEDGER := V_SEQ_LEDGER+1;
			END LOOP;
				V_RECORD_sEQ:=V_RECORD_SEQ+1;
		END LOOP;
		
		IF 	P_SL_ACCT_CD_BANK IS NOT NULL  AND P_GL_ACCT_CD_BANK IS NOT NULL AND P_GL_ACCT_CD_HUTANG IS NOT NULL AND P_SL_ACCT_CD_HUTANG IS NOT NULL THEN
		
		BEGIN
		UPDATE T_MANY_DETAIL SET FIELD_VALUE=V_TOTAL_AMOUNT WHERE UPDATE_SEQ=V_UPDATE_SEQ AND UPDATE_DATE=V_UPDATE_DATE AND TABLE_NAME='T_PAYRECH' AND FIELD_NAME='CURR_AMT';
		EXCEPTION
			WHEN OTHERS THEN
				 V_ERROR_CODE := -300;
				 V_ERROR_MSG := SUBSTR('UPDATE T_PAYRECH FIELD NAME CURR_AMT PADA PAYRECH '|| SQLERRM(SQLCODE),1,200);
				RAISE V_ERR;
			END;
		BEGIN
			UPDATE T_MANY_DETAIL SET FIELD_VALUE=V_TOTAL_AMOUNT WHERE UPDATE_SEQ=V_UPDATE_SEQ AND UPDATE_DATE=V_UPDATE_DATE AND TABLE_NAME='T_PAYRECD' AND FIELD_NAME='PAYREC_AMT';
		EXCEPTION
			WHEN OTHERS THEN
				 V_ERROR_CODE := -310;
				 V_ERROR_MSG := SUBSTR('UPDATE T_PAYRECD FIELD PAYREC_AMT  '|| SQLERRM(SQLCODE),1,200);
				RAISE V_ERR;
			END;
		BEGIN
			UPDATE T_MANY_DETAIL SET FIELD_VALUE=V_TOTAL_AMOUNT WHERE UPDATE_SEQ=V_UPDATE_SEQ AND UPDATE_DATE=V_UPDATE_DATE AND TABLE_NAME='T_ACCOUNT_LEDGER' AND FIELD_NAME IN ('CURR_VAL','XN_VAL');
		EXCEPTION
			WHEN OTHERS THEN
				 V_ERROR_CODE := -320;
				 V_ERROR_MSG := SUBSTR('UPDATE T_PAYRECD FIELD PAYREC_AMT  '|| SQLERRM(SQLCODE),1,200);
				RAISE V_ERR;
			END;
		END IF; --END UPDATE VOUCHER DI T MANY
		
	ELSE--REFUND
	
	V_TRX_TYPE :='P';
	V_REMARKS :='Refund IPO '|| p_stk_cd;
	FOR REC IN  CSR_REFUND LOOP
	
	BEGIN
			 select COUNT(1) INTO V_CNT from (SELECT
						 (SELECT TO_DATE(FIELD_VALUE,'YYYY/MM/DD HH24:MI:SS') FROM T_MANY_DETAIL DA 
								WHERE DA.TABLE_NAME = 'T_FUND_MOVEMENT' 
								AND DA.UPDATE_DATE = DD.UPDATE_DATE
								AND DA.UPDATE_SEQ = DD.UPDATE_SEQ
								AND DA.FIELD_NAME = 'DOC_DATE'
								AND DA.RECORD_SEQ = DD.RECORD_SEQ) DOC_DATE, 
						(SELECT FIELD_VALUE FROM T_MANY_DETAIL DA 
								WHERE DA.TABLE_NAME = 'T_FUND_MOVEMENT' 
								AND DA.UPDATE_DATE = DD.UPDATE_DATE
								AND DA.UPDATE_SEQ = DD.UPDATE_SEQ
								AND DA.FIELD_NAME = 'TRX_TYPE'
								AND DA.RECORD_SEQ = DD.RECORD_SEQ) TRX_TYPE, 
						(SELECT FIELD_VALUE FROM T_MANY_DETAIL DA 
								WHERE DA.TABLE_NAME = 'T_FUND_MOVEMENT' 
								AND DA.UPDATE_DATE = DD.UPDATE_DATE
								AND DA.UPDATE_SEQ = DD.UPDATE_SEQ
								AND DA.FIELD_NAME = 'CLIENT_CD'
								AND DA.RECORD_SEQ = DD.RECORD_SEQ) CLIENT_CD,
						(SELECT FIELD_VALUE FROM T_MANY_DETAIL DA 
								WHERE DA.TABLE_NAME = 'T_FUND_MOVEMENT' 
								AND DA.UPDATE_DATE = DD.UPDATE_DATE
								AND DA.UPDATE_SEQ = DD.UPDATE_SEQ
								AND DA.FIELD_NAME = 'TRX_AMT'
								AND DA.RECORD_SEQ = DD.RECORD_SEQ) TRX_AMT
						FROM T_MANY_DETAIL DD, T_MANY_HEADER HH WHERE DD.TABLE_NAME = 'T_FUND_MOVEMENT' AND DD.UPDATE_DATE = HH.UPDATE_DATE
											  AND DD.UPDATE_SEQ = HH.UPDATE_SEQ  AND  DD.RECORD_SEQ =1
											 AND DD.FIELD_NAME = 'DOC_DATE' AND HH.APPROVED_STATUS = 'E' ORDER BY HH.UPDATE_SEQ
											 )
											 where client_cd=REC.CLIENT_CD AND TRX_TYPE=V_TRX_TYPE AND TRX_AMT=REC.AMOUNT;
            EXCEPTION
              WHEN OTHERS THEN
                 V_ERROR_CODE := -325;
                 V_ERROR_MSG := SUBSTR('CEK PENDING INBOX  '|| SQLERRM(SQLCODE),1,200);
                RAISE V_ERR;
            END;          
		IF V_CNT>0 THEN
				V_ERROR_CODE := -327;
                 V_ERROR_MSG := 'Masih belum diapprove';
                RAISE V_ERR;
		END IF;
		
		BEGIN
			SELECT COUNT(1) INTO V_CNT FROM T_FUND_MOVEMENT 
			WHERE DOC_DATE=V_PAYM_DT AND SOURCE='IPO' AND SL_ACCT_CD=P_STK_CD AND CLIENT_CD=REC.CLIENT_CD AND TRX_AMT =REC.AMOUNT;
		EXCEPTION
		WHEN NO_DATA_FOUND THEN
			NULL;
		WHEN OTHERS THEN
			V_ERROR_CODE := -328;
            V_ERROR_MSG := SUBSTR('CEK JURNAL T FUND MOVEMENT'|| SQLERRM(SQLCODE),1,200);
            RAISE V_ERR;
		END;
		
		IF V_CNT>0 THEN
			V_ERROR_CODE := -329;
            V_ERROR_MSG := 'Client '|| REC.CLIENT_CD ||' sudah dijurnal';
            RAISE V_ERR;
		END IF;
	
		--INSERT KE T MANY HEADER
			--EXECUTE SP HEADER
         BEGIN
        Sp_T_Many_Header_Insert(V_MENU_NAME,
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
                 V_ERROR_CODE := -330;
                 V_ERROR_MSG := SUBSTR('SP_T_MANY_HEADER_INSERT '|| SQLERRM(SQLCODE),1,200);
                RAISE V_ERR;
            END;
			
			BEGIN
				SELECT BRANCH_CODE INTO V_BRANCH_CODE FROM MST_CLIENT WHERE CLIENT_CD= REC.CLIENT_CD;
			 EXCEPTION
              WHEN OTHERS THEN
                 V_ERROR_CODE := -340;
                  V_ERROR_MSG := SUBSTR(' FIND BRACNH CODE FOR CLIENT '|| REC.CLIENT_CD||' '|| SQLERRM(SQLCODE),1,200);
                RAISE V_ERR;
            END;
			BEGIN
				SELECT BANK_CD,BANK_ACCT_NUM INTO V_BANK_CD,V_BANK_ACCT_NUM FROM MST_CLIENT_FLACCT WHERE CLIENT_CD= REC.CLIENT_CD AND ACCT_STAT <> 'C' ;
			 EXCEPTION
              WHEN OTHERS THEN
                 V_ERROR_CODE := -350;
                 V_ERROR_MSG := SUBSTR('SP_T_MANY_HEADER_INSERT '|| SQLERRM(SQLCODE),1,200);
                RAISE V_ERR;
            END;
			
			--INSERT KE T FUND MOVEMENT
			V_RECORD_SEQ:=1;
			FOR I IN 1..2 LOOP
			 V_DOC_NUM :=Get_Docnum_Fund (V_PAYM_DT, 'P');
			
			BEGIN
			 Sp_T_FUND_MOVEMENT_UPD(V_DOC_NUM,
									V_DOC_NUM,
									V_PAYM_DT,
									V_TRX_TYPE,
									REC.CLIENT_CD,
									TRIM(V_BRANCH_CODE),
									'IPO',--P_SOURCE,
                  null,--P_DOC_REF_NUM,
                  NULL,--P_TAL_ID_REF,
                  NULL,--P_GL_ACCT_CD,
                  P_STK_CD,--P_SL_ACCT_CD,
                  NULL,--P_BANK_REF_NUM,
									NULL,--P_BANK_MVMT_DATE,
									REC.CLIENT_NAME,--P_ACCT_NAME,
									V_REMARKS,
									REC.CLIENT_CD,--P_FROM_CLIENT,
									V_BANK_ACCT_NUM,--P_FROM_ACCT,
									V_BANK_CD,--P_FROM_BANK,
									REC.CLIENT_CD,--P_TO_CLIENT,
									V_BANK_ACCT_NUM,--P_TO_ACCT,
									V_BANK_CD,--P_TO_BANK,
									REC.AMOUNT,--P_TRX_AMT,
									sysdate,--P_CRE_DT,
									P_USER_ID,
									null,--P_CANCEL_DT,
									null,--P_CANCEL_BY,
									0,--P_FEE,
									P_FOLDER_CD,--P_FOLDER_CD,
									V_BANK_CD,--P_FUND_BANK_CD,
									V_BANK_ACCT_NUM,--P_FUND_BANK_ACCT,
									null,--P_UPD_DT,
									null,--P_UPD_BY,
									'I',--P_UPD_STATUS,
									p_ip_address,
									null,--p_cancel_reason,
									V_UPDATE_DATE,
									V_UPDATE_SEQ,
									I,
									V_ERROR_CODE,
									V_ERROR_MSG);
			  EXCEPTION
              WHEN OTHERS THEN
                 V_ERROR_CODE := -360;
                 V_ERROR_MSG := SUBSTR('Sp_T_FUND_MOVEMENT_UPD '|| SQLERRM(SQLCODE),1,200);
                RAISE V_ERR;
            END;
		IF 	V_ERROR_CODE<0 THEN
				V_ERROR_CODE := -370;
                V_ERROR_MSG := SUBSTR('Sp_T_FUND_MOVEMENT_UPD '|| V_ERROR_MSG,1,200);
                RAISE V_ERR;
		END IF;		
						
		--SAVE KE T FUND LEDGER
				FOR J IN 1..2 LOOP
				
				IF I =1 THEN
					IF J=1 THEN
						V_ACCT_CD :='DBEBAS';
						V_DEBIT := REC.AMOUNT;
						V_CREDIT :=0;
					ELSE
						V_ACCT_CD :='DNU';
						V_DEBIT :=0;
						V_CREDIT := REC.AMOUNT;
					END IF;
				ELSE
					IF J=1 THEN
						V_ACCT_CD :='KNU';
						V_DEBIT := REC.AMOUNT;
						V_CREDIT :=0;
					ELSE
						V_ACCT_CD :='KNPR';
						V_DEBIT :=0;
						V_CREDIT := REC.AMOUNT;
					END IF;
				
				END IF;
				
				
				BEGIN
				 Sp_T_FUND_LEDGER_UPD(	V_DOC_NUM,
										J,
										V_DOC_NUM,
										J,
										V_TRX_TYPE,
										V_PAYM_DT,
										V_ACCT_CD,
										REC.CLIENT_CD,
										V_DEBIT,--P_DEBIT,
										V_CREDIT,--P_CREDIT,
										SYSDATE,--P_CRE_DT,
										P_USER_ID,
										NULL,--P_CANCEL_DT,
										NULL,--P_CANCEL_BY,
										NULL,--P_UPD_DT,
										NULL,--P_UPD_BY,
										'N',--P_MANUAL
										'I',--P_UPD_STATUS,
										p_ip_address,
										NULL,--p_cancel_reason,
										V_UPDATE_DATE,--p_update_date,
										V_UPDATE_SEQ,--p_update_seq,
										V_RECORD_SEQ,--p_record_seq,
										V_ERROR_CODE,
										V_ERROR_MSG);
			EXCEPTION
              WHEN OTHERS THEN
                 V_ERROR_CODE := -380;
                 V_ERROR_MSG := SUBSTR('Sp_T_FUND_LEDGER_UPD '|| SQLERRM(SQLCODE),1,200);
                RAISE V_ERR;
            END;
			IF 	V_ERROR_CODE<0 THEN
					V_ERROR_CODE := -390;
					V_ERROR_MSG := SUBSTR('Sp_T_FUND_LEDGER_UPD '|| V_ERROR_MSG,1,200);
					RAISE V_ERR;
			END IF;								
				V_RECORD_SEQ := V_RECORD_SEQ+1;			
				END LOOP;

			END LOOP;
		
	
	END LOOP;
	
	END IF;

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
       -- Consider logging the error and then re-raise
	    ROLLBACK;
		p_error_code := -1;
		p_error_msg := SUBSTR(SQLERRM,1,200);
		RAISE;		
							
END SP_GEN_FUND_IPO;