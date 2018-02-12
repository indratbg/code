create or replace PROCEDURE Sp_Ca_Jur_MANUAL(P_DATE DATE, 
	P_STK_CD T_CORP_ACT.STK_CD%TYPE,
	P_CA_TYPE T_CORP_ACT.CA_TYPE%TYPE,
	P_ERROR_CODE OUT NUMBER,
	P_ERROR_MSG OUT VARCHAR2) IS

--08FEB TAMBAH CSR_SPLIT_REVERSE UNTUK INSERT KE T_CORP_ACT_FO YG KEMUNGKINAN ADA 
--CLIENT YG RECV/WHDR DIANTARA X DATE DAN RECODING DATE
--24nov2017 indra
V_MENU_NAME T_MANY_HEADER.MENU_NAME%TYPE :='CORPORATE ACTION JOURNAL SCHED';

CURSOR csr_distrib_dt   IS
SELECT 	STK_CD, CA_TYPE, CUM_DT,
						   X_DT, RECORDING_DT, DISTRIB_DT,
						   FROM_QTY, TO_QTY,rate, STK_CD_MERGE
FROM T_CORP_ACT
WHERE (ca_type IN ('SPLIT','REVERSE','RIGHT','WARRANT','BONUS','STKDIV','MERGE'))
AND DISTRIB_DT =P_DATE
AND (CA_TYPE = P_CA_TYPE OR P_CA_TYPE='%')
AND (STK_CD = P_STK_CD OR P_STK_CD='%')
AND approved_stat = 'A';


CURSOR csr_x_date  IS
SELECT 	STK_CD, CA_TYPE, CUM_DT, X_DT, RECORDING_DT, DISTRIB_DT, FROM_QTY, TO_QTY,rate
FROM T_CORP_ACT
WHERE (ca_type IN ('SPLIT','REVERSE'))
AND X_DT =P_DATE
AND (CA_TYPE = P_CA_TYPE OR P_CA_TYPE='%')
AND (STK_CD = P_STK_CD OR P_STK_CD='%')
AND approved_stat = 'A';


CURSOR csr_xdate_avgprice  IS
SELECT 	STK_CD, CA_TYPE, CUM_DT, X_DT, RECORDING_DT, DISTRIB_DT, FROM_QTY, TO_QTY,rate
FROM T_CORP_ACT
--13jan17WHERE ca_type IN ('SPLIT','REVERSE','BONUS','STKDIV')
WHERE ca_type IN ('SPLIT','REVERSE')
AND X_DT =P_DATE
AND (CA_TYPE = P_CA_TYPE OR P_CA_TYPE='%')
AND (STK_CD = P_STK_CD OR P_STK_CD='%')
AND approved_stat = 'X';

CURSOR CSR_APPROVE IS
SELECT UPDATE_DATE,UPDATE_SEQ FROM T_MANY_HEADER
WHERE update_date >  TRUNC(SYSDATE)
AND MENU_NAME=V_MENU_NAME
AND APPROVED_STATUS='E';


CURSOR csr_Expiry_date IS
SELECT a.stk_Cd, withdraw_dt, ca_type
FROM
  (
    SELECT stk_Cd, withdraw_dt, 'HMETD' ca_type
    FROM
      (
        SELECT Get_Due_Date(1,pp_to_dt) withdraw_dt, stk_Cd
        FROM MST_COUNTER
        WHERE (ctr_type = 'RT'
        OR ctr_type     = 'WR')
        AND (STK_CD     = P_STK_CD
        OR P_STK_CD     ='%')
        AND PP_TO_DT   IS NOT NULL
      )
    WHERE withdraw_Dt IS NOT NULL
    AND withdraw_Dt    = P_DATE
  )
  a, (
    SELECT DISTINCT stk_cd
    FROM T_STK_MOVEMENT
    WHERE doc_dt            = P_DATE
    AND s_d_type            = 'C'
    AND WITHDRAWN_SHARE_QTY > 0
    AND (STK_CD             = P_STK_CD
    OR P_STK_CD             ='%')
    AND doc_stat            = '2'
  )
  t
WHERE a.stk_Cd IS NOT NULL
AND a.stk_Cd    = t.stk_cd(+)
AND t.stk_cd   IS NULL;

--08feb2018 untuk insert ke t_corp_act_fo recv/whdr pada x_dt-recording_dt
CURSOR CSR_SPLIT_REVERSE IS
SELECT CA_TYPE,STK_CD,CUM_DT,X_DT,RECORDING_DT,DISTRIB_DT,FROM_QTY,TO_QTY 
FROM T_CORP_ACT WHERE approved_stat='A'
AND CA_TYPE IN('SPLIT','REVERSE')
AND P_DATE BETWEEN X_DT AND RECORDING_DT;


V_ERR EXCEPTION;
V_ERR_CD NUMBER(5);
V_ERR_MSG VARCHAR(200);


V_BGN_DT DATE;
V_IP_ADDRESS T_MANY_HEADER.IP_ADDRESS%TYPE;
v_cnt NUMBER;
v_doc_rem	T_STK_MOVEMENT.doc_rem%TYPE;
V_STK_CD   T_STK_MOVEMENT.stk_Cd%TYPE;
v_kebalikan NUMBER;
V_PRICE NUMBER;
--V_FLG VARCHAR2(1):='Y';
v_mvmt_type  T_STK_MOVEMENT.jur_type%TYPE;
v_jur_type  T_STK_MOVEMENT.jur_type%TYPE;
v_jur_type_suffix MST_SYS_PARAM.dflg1%TYPE;

v_PAPE MST_SYS_PARAM.dflg1%TYPE;
BEGIN

SELECT dflg1 INTO v_pape
FROM MST_SYS_PARAM
WHERE param_id = 'CORP_ACT'
AND param_cd1 = 'PAPE';

V_IP_ADDRESS :=SYS_CONTEXT('USERENV','IP_ADDRESS');
      
--=================================================DISTRIB DT ============================
		FOR rec IN csr_distrib_dt  LOOP

				IF REC.CA_TYPE ='RIGHT' OR REC.CA_TYPE = 'WARRANT' THEN
					v_mvmt_type := 'HMETD';
				ELSE
					v_mvmt_type := rec.ca_type; 
				END IF;		

				IF v_pape = 'Y' THEN
					v_jur_type_suffix := 'D';
				ELSE
					v_jur_type_suffix  := 'N';
				END IF;	 

				v_jur_type := v_mvmt_type||v_jur_type_suffix;
				V_STK_CD := REC.STK_CD;



				-- 			IF REC.CA_TYPE ='STKDIV' THEN
				-- 					V_PRICE := REC.RATE;
				-- 			ELSE
				V_PRICE :=0;
				--			END IF;


				V_BGN_DT := TO_DATE('01/'||TO_CHAR(REC.CUM_DT,'MM/YYYY'),'DD/MM/YYYY');
				--20JAN2017 UNTUK MEMBUAT ANGKA 0 DI DEPAN KOMA JIKA RASIO PECAHAN DESIMAL DAN DI BAWAH 1
				select REC.CA_TYPE||' '||decode(FLOOR(REC.FROM_QTY),0, rtrim(to_char(REC.FROM_QTY, 'FM90D99'), to_char(0, 'D')),REC.FROM_QTY)||' : '
				||decode(FLOOR(REC.TO_QTY),0, rtrim(to_char(REC.TO_QTY, 'FM90D99'), to_char(0, 'D')),REC.TO_QTY) into v_doc_rem from dual;

				--v_doc_rem := REC.CA_TYPE||' '||REC.FROM_QTY ||' : '||REC.TO_QTY;

				IF   v_jur_type_suffix = 'D' THEN 

						BEGIN
						Sp_Ca_Jur_Upd(REC.RECORDING_DT,
										V_BGN_DT,
										rec.recording_dt,
										REC.CUM_DT,
										REC.X_DT,
										REC.CA_TYPE,
										V_STK_CD,
										'SYSTEM',
										V_IP_ADDRESS,
										v_doc_rem,
										v_jur_type_suffix, -- D / N
										V_MENU_NAME,
										'N',-- manual
										V_ERR_CD,
										V_ERR_MSG);
						EXCEPTION
						WHEN OTHERS THEN
							V_ERR_CD := -500;
							V_ERR_MSG :=SUBSTR('SP_CA_JUR_UPD'||SQLERRM(SQLCODE),1,200);
							RAISE V_ERR;
						END;

						IF V_ERR_CD < 0 THEN
							V_ERR_CD := -510;
							V_ERR_MSG := SUBSTR('SP_CA_JUR_UPD '||V_ERR_MSG,1,200);
							RAISE V_ERR;
						END IF;

				ELSE

						BEGIN
						Sp_Ca_Distrib_Jur_Upd( rec.distrib_Dt,
												rec.CUM_DT,
												rec.X_DT,
												rec.RECORDING_DT,
												rec.DISTRIB_DT,
												rec.CA_TYPE,
												v_STK_CD,
												REC.STK_CD_MERGE,
												v_jur_type_suffix, 	
												V_doc_rem,
												'N',--P_MANUAL
												'SYSTEM',
												V_MENU_NAME,
												V_IP_ADDRESS,
												V_ERR_CD,
												V_ERR_MSG);
						EXCEPTION
						WHEN OTHERS THEN
							V_ERR_CD := -520;
							V_ERR_MSG :=SUBSTR('Sp_Ca_Distrib_Jur_Upd'||SQLERRM(SQLCODE),1,200);
							RAISE V_ERR;
						END;

						IF V_ERR_CD < 0 THEN
							V_ERR_CD := -530;
							V_ERR_MSG := SUBSTR('Sp_Ca_Distrib_Jur_Upd '||V_ERR_MSG,1,200);
							RAISE V_ERR;
						End If;
						--5nov15
						BEGIN
						UPDATE T_CORP_ACT_FO SET STATUS='C' WHERE STK_CD= V_STK_CD AND FROM_DT= REC.X_DT AND TO_DT=REC.DISTRIB_DT AND CA_TYPE= REC.CA_TYPE;
						EXCEPTION
						WHEN OTHERS THEN
							V_ERR_CD := -540;
							V_ERR_MSG :=SUBSTR('UPDATE T_CORP_ACT_FO, SET STATUS=C '||SQLERRM(SQLCODE),1,200);
							Raise V_Err;
						END;

				END IF;

				FOR JUR IN CSR_APPROVE LOOP
						BEGIN
						Sp_T_Stk_Movement_Approve( TRIM(V_MENU_NAME),
												  jur.update_date,
												  jur.update_seq,
												  'SYSTEM',
												  V_IP_ADDRESS,
												  V_ERR_CD,
												  V_ERR_MSG);
						EXCEPTION
						WHEN OTHERS THEN
							V_ERR_CD := -550;
							V_ERR_MSG :=SUBSTR('SP_T_STK_MOVEMENT_APPROVE'||SQLERRM(SQLCODE),1,200);
							RAISE V_ERR;
						END;

						IF V_ERR_CD < 0 THEN
							V_ERR_CD := -560;
							V_ERR_MSG := SUBSTR('SP_T_STK_MOVEMENT_APPROVE '||V_ERR_MSG,1,200);
							RAISE V_ERR;
						END IF;

				END LOOP;

				IF REC.CA_TYPE = 'MERGE' then

						BEGIN
						SP_Gen_Avg_Price (rec.distrib_Dt,
										  rec.distrib_Dt,
										  '%', --p_beg_client 	IN T_CONTRACTS.client_Cd%TYPE,
										  '_',--p_end_client 	IN T_CONTRACTS.client_Cd%TYPE,
										  v_STK_CD,
										  v_STK_CD,
										  'SYSTEM',
										  V_IP_ADDRESS,
										  V_ERR_CD,
										  v_err_msg); --p_user_id
						EXCEPTION
						WHEN OTHERS THEN
							V_ERR_CD := -570;
							v_err_msg := SUBSTR('SP_Gen_Avg_Price '||SQLERRM,200);
							RAISE v_err;
						END;

						IF v_err_cd < 0 THEN
							V_ERR_CD := -580;
							v_err_msg :=SUBSTR( 'SP_Gen_Avg_Price '||v_err_msg ||SQLERRM,200);
							RAISE v_err;
						END IF;

						BEGIN
						SP_Gen_Avg_Price (rec.distrib_Dt,
										rec.distrib_Dt,
										'%', --p_beg_client 	IN T_CONTRACTS.client_Cd%TYPE,
										'_',--p_end_client 	IN T_CONTRACTS.client_Cd%TYPE,
										REC.STK_CD_MERGE,
										REC.STK_CD_MERGE,
										'SYSTEM',
										V_IP_ADDRESS,
										V_ERR_CD,
										v_err_msg); --p_user_id
						EXCEPTION
						WHEN OTHERS THEN
							V_ERR_CD := -570;
							v_err_msg := SUBSTR('SP_Gen_Avg_Price '||SQLERRM,200);
							RAISE v_err;
						END;

						IF v_err_cd < 0 THEN
							V_ERR_CD := -590;
							v_err_msg :=SUBSTR( 'SP_Gen_Avg_Price '||v_err_msg ||SQLERRM,200);
							RAISE v_err;
						END IF;

				end if; --IF REC.CA_TYPE = 'MERGE' then


		END LOOP;
--=============================================== X DATE ==========================
		FOR rec IN csr_x_date LOOP

				IF v_PAPE = 'N' THEN 

						-- save ke T CORP ACT FO
						BEGIN
						Sp_Corp_Act_Cum_Date( rec.x_dt,
											rec.RECORDING_DT,
											rec.DISTRIB_DT,
											rec.stk_cd,
											rec.from_qty, -- pembagi
											rec.to_qty, --P_PENGALI
											rec.ca_type,
											'SYSTEM', --p_user_id,
											V_ERR_CD,
											V_ERR_MSG);
						EXCEPTION
						WHEN OTHERS THEN
							V_ERR_CD := -31;
							V_ERR_MSG :=SUBSTR('Sp_Corp_Act_Cum_Date'||SQLERRM(SQLCODE),1,200);
							RAISE V_ERR;
						END;

						IF V_ERR_CD < 0 THEN
							V_ERR_CD := -32;
							V_ERR_MSG := SUBSTR('Sp_Corp_Act_Cum_Date '||V_ERR_MSG,1,200);
							RAISE V_ERR;
						END IF;

				--		   	IF v_PAPE = 'N' THEN 
				ELSE

						BEGIN
						SELECT COUNT(1) INTO v_cnt
						FROM T_STK_MOVEMENT
						WHERE DOC_DT = REC.X_DT
						AND stk_Cd= rec.stk_Cd
						AND  doc_stat = '2'
						AND s_d_type IN ('S','R')
						AND jur_type IN ('SPLITX','REVERSEX')
						AND seqno = 1;
						EXCEPTION
						WHEN NO_DATA_FOUND THEN
							v_cnt := 0;
						WHEN OTHERS THEN
							V_ERR_CD := -30;
							V_ERR_MSG :=SUBSTR('read T STK MOVEMENT '||SQLERRM(SQLCODE),1,200);
							RAISE V_ERR;
						END;

						v_price :=0;

						IF V_cnt = 0 THEN

							V_BGN_DT := TO_DATE('01/'||TO_CHAR(REC.CUM_DT,'MM/YYYY'),'DD/MM/YYYY');


								IF REC.CA_TYPE='SPLIT' THEN
									v_doc_rem := 'SPLIT '||REC.FROM_QTY ||' : '||REC.TO_QTY;
								ELSIF REC.CA_TYPE ='REVERSE' THEN
									v_doc_rem := 'REVERSE '||REC.FROM_QTY ||' : '||REC.TO_QTY;
								END IF;

								BEGIN
								Sp_Ca_Jur_Upd(REC.RECORDING_DT,
											V_BGN_DT,
											REC.CUM_DT, --V_TODAY,
											REC.CUM_DT,
											REC.X_DT,
											REC.CA_TYPE,
											REC.STK_CD,
											'SYSTEM',
											V_IP_ADDRESS,
											v_doc_rem,
											'X',
											V_MENU_NAME,
											'N',
											V_ERR_CD,
											V_ERR_MSG);
								EXCEPTION
								WHEN OTHERS THEN
									V_ERR_CD := -35;
									V_ERR_MSG :=SUBSTR('SP_CA_JUR_UPD'||SQLERRM(SQLCODE),1,200);
									RAISE V_ERR;
								END;

								IF V_ERR_CD < 0 THEN
									V_ERR_CD := -37;
									V_ERR_MSG := SUBSTR('SP_CA_JUR_UPD '||V_ERR_MSG,1,200);
									RAISE V_ERR;
								END IF;


								FOR JUR IN CSR_APPROVE LOOP

										BEGIN
										Sp_T_Stk_Movement_Approve( TRIM(V_MENU_NAME),
																jur.update_date,
																jur.update_seq,
																'SYSTEM',
																V_IP_ADDRESS,
																V_ERR_CD,
																V_ERR_MSG);
										EXCEPTION
										WHEN OTHERS THEN
											V_ERR_CD := -40;
											V_ERR_MSG :=SUBSTR('SP_T_STK_MOVEMENT_APPROVE'||SQLERRM(SQLCODE),1,200);
											RAISE V_ERR;
										END;

										IF V_ERR_CD < 0 THEN
											V_ERR_CD := -45;
											V_ERR_MSG := SUBSTR('SP_T_STK_MOVEMENT_APPROVE '||V_ERR_MSG,1,200);
											RAISE V_ERR;
										END IF;

								END LOOP;

						--				IF V_cnt = 0 THEN
						END IF;

				--		   	IF v_PAPE = 'N' THEN 
				END IF; 

		END LOOP;


 --================ upd CLOSE PRICE dan calc AVG PRICE utk SPLIT REVERSE BONUS STKDIV ===============
		FOR recv IN csr_xdate_avgprice LOOP

				IF recv.ca_type = 'SPLIT' OR recv.ca_type = 'REVERSE'  THEN
					v_kebalikan := recv.from_qty / recv.to_qty;
				END IF ;

				IF recv.ca_type = 'BONUS' OR recv.ca_type = 'STKDIV'  THEN
					v_kebalikan := recv.from_qty / (recv.from_qty + recv.to_qty);
				END IF ;

				IF recv.ca_type = 'SPLIT' OR recv.ca_type = 'REVERSE'  THEN

						BEGIN
						UPDATE T_CLOSE_PRICE
						SET STK_BIDP = ROUND(stk_clos *  v_kebalikan,0)
						WHERE stk_date = recv.cum_dt
						AND stk_cd = RECv.STK_CD;
						EXCEPTION
						WHEN OTHERS THEN
							V_ERR_CD := -48;
							v_err_msg := SUBSTR('Update T_CLOSE_PRICE '||SQLERRM,1,200);
							RAISE v_err;
						END;

				END IF;

				BEGIN
				SP_Gen_Avg_Price (recv.x_dt,
								  recv.x_dt,
								  '%', --p_beg_client 	IN T_CONTRACTS.client_Cd%TYPE,
								  '_',--p_end_client 	IN T_CONTRACTS.client_Cd%TYPE,
								  recv.stk_cd,
								  recv.stk_cd,
								  'SYSTEM',
								  V_IP_ADDRESS,
								  V_ERR_CD,
								  v_err_msg); --p_user_id
				EXCEPTION
				WHEN OTHERS THEN
					V_ERR_CD := -49;
					v_err_msg := SUBSTR('SP_Gen_Avg_Price '||SQLERRM,200);
					RAISE v_err;
				END;

				IF v_err_cd < 0 THEN
					V_ERR_CD := -50;
					v_err_msg :=SUBSTR( 'SP_Gen_Avg_Price '||v_err_msg ||SQLERRM,200);
					RAISE v_err;
				END IF;

		END LOOP;

-- ===========================================STK EXPIRED ========================
		FOR rece IN csr_Expiry_date LOOP

				v_doc_rem := 'Closed';

				BEGIN
				Sp_Gen_Stk_Expired_Jur_Ng  ( rece.stk_cd,
											rece.withdraw_dt,
											v_doc_rem,
											'SYSTEM',
											v_ip_address,
											V_ERR_CD,
											V_ERR_MSG);
				EXCEPTION
				WHEN OTHERS THEN
					V_ERR_CD := -51;
					V_ERR_MSG := SUBSTR('SP_GEN_STK_EXPIRED_JUR_NG '||V_ERR_MSG||SUBSTR(SQLERRM,200),1,200);
					RAISE v_err;
				END;

				IF V_ERR_CD < 0 THEN
					V_ERR_CD := -53;
					V_ERR_MSG := 'SP_GEN_STK_EXPIRED_JUR_NG '||v_err_msg||' '||SUBSTR(SQLERRM,200);
					RAISE v_err;
				END IF;



				FOR JUR IN CSR_APPROVE LOOP
				BEGIN
				Sp_T_Stk_Movement_Approve( TRIM(V_MENU_NAME),
										jur.update_date,
										jur.update_seq,
										'SYSTEM',
										V_IP_ADDRESS,
										V_ERR_CD,
										V_ERR_MSG);
				EXCEPTION
				WHEN OTHERS THEN
					V_ERR_CD := -40;
					V_ERR_MSG :=SUBSTR('SP_T_STK_MOVEMENT_APPROVE'||SQLERRM(SQLCODE),1,200);
					RAISE V_ERR;
				END;

				IF V_ERR_CD < 0 THEN
					V_ERR_CD := -45;
					V_ERR_MSG := SUBSTR('SP_T_STK_MOVEMENT_APPROVE '||V_ERR_MSG,1,200);
					RAISE V_ERR;
					END IF;
				END LOOP;

		END LOOP;

		  --08FEB2018
		FOR REC IN CSR_SPLIT_REVERSE LOOP

				BEGIN
			  	SP_CORP_ACT_X_DATE(P_DATE,-- P_TODAY
								   REC.X_DT,-- P_X_DATE,
								   REC.RECORDING_DT,-- P_RECORDING_DATE,
								   REC.DISTRIB_DT,-- P_DISTRIBUTION_DATE,
								   REC.STK_CD,-- P_STK_CD,
								   REC.FROM_QTY,-- P_PEMBAGI,
								   REC.TO_QTY,-- P_PENGALI,
								   REC.CA_TYPE,--P_CA_TYPE,
								   'SYSTEM',
								   V_ERR_CD,
								   V_ERR_MSG);
				EXCEPTION
				WHEN OTHERS THEN
					V_ERR_CD := -40;
					V_ERR_MSG :=SUBSTR('CALL SP_CORP_ACT_X_DATE'||SQLERRM(SQLCODE),1,200);
					RAISE V_ERR;
				END;

		  		IF V_ERR_CD < 0 THEN
					V_ERR_CD := -45;
					V_ERR_MSG := SUBSTR('CALL SP_CORP_ACT_X_DATE '||V_ERR_MSG,1,200);
					RAISE V_ERR;
				END IF;

		END LOOP;


P_ERROR_CODE:=1;
P_ERROR_MSG:='';

COMMIT;
EXCEPTION
    WHEN V_ERR THEN
      ROLLBACK;
      P_ERROR_CODE:=V_ERR_CD;
      P_ERROR_MSG:=V_ERR_MSG;
		WHEN OTHERS THEN
      P_ERROR_CODE:=-1;
      P_ERROR_MSG:=SUBSTR(SQLERRM,1,200);
END Sp_Ca_Jur_MANUAL;