create or replace 
PROCEDURE SPR_RECON_RINCIAN_PORTO(p_date date,
									P_OPTION VARCHAR2,
									P_USER_ID VARCHAR2,
									P_GENERATE_DATE 	DATE,
									P_RANDOM_VALUE	OUT NUMBER,
								   P_ERROR_MSG OUT VARCHAR2,
								   P_ERROR_CD OUT NUMBER) IS


V_ERROR_MSG VARCHAR2(200);
V_ERROR_CD NUMBER(10);
v_random_value	NUMBER(10);
V_ERR EXCEPTION;
v_DT_BGN_DATE DATE;
V_DT_END_DATE DATE;
V_IMPORT_DATE DATE;

 BEGIN
 
 
   v_random_value := abs(dbms_random.random);

    BEGIN
        SP_RPT_REMOVE_RAND('R_RECON_RINCIAN_PORTO',V_RANDOM_VALUE,V_ERROR_MSG,V_ERROR_CD);
    EXCEPTION
        WHEN OTHERS THEN
             V_ERROR_CD := -10;
             V_ERROR_MSG := SUBSTR('SP_RPT_REMOVE_RAND '||SQLERRM(SQLCODE),1,200);
            RAISE V_err;
    END;
	
	IF V_ERROR_CD<0 THEN
			V_ERROR_CD := -20;
             V_ERROR_MSG := SUBSTR('SP_RPT_REMOVE_RAND'||V_ERROR_MSG,1,200);
            RAISE V_ERR;
	END IF;
 
	BEGIN
		SELECT MAX(IMPORT_DATE) INTO V_IMPORT_DATE FROM T_STK_KSEI WHERE BAL_DT=P_DATE;
	EXCEPTION
        WHEN OTHERS THEN
             V_ERROR_CD := -30;
             V_ERROR_MSG := SUBSTR('SELECT MAX IMPORT DATE FROM T STK KSEI '||SQLERRM(SQLCODE),1,200);
            RAISE V_err;
    END;
	
	V_DT_BGN_DT := TO_DATE('01/'||TO_CHAR(P_DATE,'MM/YYYY'));
	V_DT_END_DATE := P_DATE;
	
 
 
	BEGIN 
	INSERT INTO R_RECON_RINCIAN_PORTO(REPORT_DATE,STK_CD,PORT001,PORT004,CLIENT001,
									CLIENT004,SUBREK_QTY,KPORT001,KPORT004,KCLIENT004,
									KSUBREK_QTY,USER_ID,RAND_VALUE,GENERATE_DATE)
			
		SELECT report_date, stk_cd, SUM(port001) port001, SUM(port004) port004,  SUM(client001) client001,
				SUM(client004) client004, SUM(subrek_qty) subrek_qty, SUM( kport001) kport001, SUM(kport004) kport004,  SUM(kclient004) kclient004, 
				SUM( ksubrek_qty) ksubrek_qty ,P_USER_ID,V_RANDOM_VALUE, P_GENERATE_DATE
		FROM( 
		SELECT report_date, stk_cd, port001  AS port001, port004, client001, client004, subrek_qty, 
		 0 kport001, 0 kport004,  0 kclient004, 0 ksubrek_qty 
		FROM insistpro_rpt.lap_rincian_porto 
		WHERE report_date = p_date 
		AND rep_type = 1 
		UNION ALL 
		SELECT bal_dt, stk_Cd,  0 port001, 0 port004, 0 client001, 0 client004, 0 subrek_qty, 
		SUM(kport001) kport001, SUM(kport004) kport004, 
		SUM(kclient004) kclient004, SUM(ksubrek_qty) ksubrek_qty 
		FROM( 
		SELECT bal_dt, stk_Cd, SUBSTR(sub_rek,6,4) subrek, 
		DECODE(SUBSTR(sub_rek,10,3),'001',1,0) * DECODE(SUBSTR(sub_rek,6,4),'0000',0,1) * qty ksubrek_qty, 
		DECODE(SUBSTR(sub_rek,10,3),'004',1,0) * DECODE(SUBSTR(sub_rek,6,4),'0000',0,1) * qty kclient004, 
		DECODE(SUBSTR(sub_rek,10,3),'001',1,0) * DECODE(SUBSTR(sub_rek,6,4),'0000',1,0) * qty kport001, 
		DECODE(SUBSTR(sub_rek,10,3),'004',1,0) * DECODE(SUBSTR(sub_rek,6,4),'0000',1,0) * qty  kport004 
		FROM t_Stk_ksei
		 WHERE bal_dt = p_date 
		 AND import_dt = V_IMPORT_DATE
		 AND stk_Cd <> 'IDR' 
		 AND qty <> 0 )
		GROUP BY bal_dt, stk_Cd) 
		GROUP BY report_date, stk_cd 
		HAVING ( SUM(port001 + client001)  <> SUM(kport001) OR SUM(port004) <> SUM(kport004) 
				OR SUM(client004) <> SUM(kclient004) OR SUM(subrek_qty) <> SUM(ksubrek_qty ) 
				 OR p_option = 'ALL') 
		ORDER BY 2;
								
   
   
	 EXCEPTION
			WHEN OTHERS THEN
				 V_ERROR_CD := -40;
				 V_ERROR_MSG := SUBSTR('INSERT R_RECON_RINCIAN_PORTO '||V_ERROR_MSG||SQLERRM(SQLCODE),1,200);
				RAISE V_err;
		END;
	
P_RANDOM_VALUE :=V_RANDOM_VALUE;	
P_ERROR_CD := 1 ;
P_ERROR_MSG := '';

 EXCEPTION
  WHEN V_ERR THEN
        ROLLBACK;
     P_ERROR_MSG := V_ERROR_MSG;
		P_ERROR_CD := V_ERROR_CD;
  WHEN OTHERS THEN
   P_ERROR_CD := -1 ;
   P_ERROR_MSG := SUBSTR(SQLERRM(SQLCODE),1,200);
   RAISE;
END SPR_RECON_RINCIAN_PORTO;