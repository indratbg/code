create or replace 
PROCEDURE SP_INSERT_T_CASH_DIVIDEN (
  P_USER_ID VARCHAR2,
  P_RAND_VALUE NUMBER,
  vo_errcd OUT NUMBER,
  vo_errmsg OUT VARCHAR2 
)IS

V_ERR EXCEPTION;
v_cnt number;
--v_sign boolean:=true;
 V_CLIENT_CD T_CASH_DIVIDEN.CLIENT_CD%TYPE;   
V_CEK BOOLEAN:=FALSE;


Cursor Csr_Data Is
select * from insistpro_rpt.r_t_cash_dividen A 
where rand_value=p_rand_value and 
user_id=p_user_id;



BEGIN


	for rec in csr_data loop
  V_CEK :=FALSE;
  
	
	BEGIN
	select client_cd INTO V_CLIENT_CD from t_cash_dividen where ca_type = 'CASHDIV' and  STK_CD= REC.STK_CD and distrib_dt=rec.distrib_dt AND client_cd=rec.client_cd order by client_cd;
	EXCEPTION
	WHEN NO_DATA_FOUND THEN
		V_CEK :=TRUE;
	  WHEN OTHERS THEN
		vo_errcd := -3;
		vo_errmsg := SUBSTR('SELECT T_CASH_DIVIDEN'||rec.client_cd||SQLERRM,1,200);
		RAISE V_ERR;
	END;

	IF V_CEK =true THEN
	BEGIN
		 INSERT INTO T_CASH_DIVIDEN (CA_TYPE,STK_CD,DISTRIB_DT,CLIENT_CD,QTY,
							RATE,GROSS_AMT, TAX_PCN, TAX_AMT, DIV_AMT,
							CRE_DT,USER_ID, UPD_DT,UPD_BY, APPROVED_DT,
							APPROVED_BY, APPROVED_STAT,RVPV_NUMBER,CUM_DATE,CUM_QTY,
							ONH,SELISIH_QTY,CUMDT_DIV_AMT,RVPV_KOREKSI)
		values(rec.ca_type,rec.stk_cd,rec.distrib_dt,rec.client_cd, rec.cum_qty+rec.selisih_qty,
			rec.rate,rec.gross_amt,(rec.tax_pcn*100),rec.tax_amt, rec.div_amt,
			sysdate,p_user_id,null,null,sysdate,
			p_user_id, 'A',rec.rvpv_number, rec.cum_dt, rec.cum_qty,
			rec.onh, rec.selisih_qty,rec.div_amt,null);					
	EXCEPTION
    WHEN OTHERS THEN
		vo_errcd := -4;
		vo_errmsg := SUBSTR('INSERT  T_CASH_DIVIDEN'||rec.client_cd||SQLERRM,1,200);
		RAISE V_ERR;
    END;
	
	ELSE
		IF REC.CUM_DT = TRUNC(SYSDATE) THEN
		BEGIN
		UPDATE T_CASH_DIVIDEN SET CUMDT_DIV_AMT = REC.SELISIH WHERE CA_TYPE='CASHDIV' AND CLIENT_CD=REC.CLIENT_CD AND STK_CD = REC.STK_CD AND DISTRIB_DT = REC.DISTRIB_DT;
	EXCEPTION
    WHEN OTHERS THEN
		vo_errcd := -5;
		vo_errmsg := SUBSTR('UPDATE T_CASH_DIVIDEN'||SQLERRM,1,200);
		RAISE V_ERR;
    END;
	else
			
			IF REC.SELISIH_QTY <> 0 THEN
					BEGIN
					UPDATE T_CASH_DIVIDEN SET QTY=REC.QTY, RATE =REC.RATE, GROSS_AMT = REC.GROSS_AMT, TAX_AMT = REC.TAX_AMT,  DIV_AMT = REC.DIV_AMT,
											 ONH = REC.ONH, SELISIH_QTY = REC.SELISIH_QTY 
											 WHERE CA_TYPE='CASHDIV' AND CLIENT_CD=REC.CLIENT_CD AND STK_CD = REC.STK_CD AND DISTRIB_DT = REC.DISTRIB_DT;
					EXCEPTION
					WHEN OTHERS THEN
						vo_errcd := -6;
						vo_errmsg := SUBSTR('UPDATE T_CASH_DIVIDEN'||SQLERRM,1,200);
						RAISE V_ERR;
					END;
			END IF;
	END IF;
	end if;	
	end loop;
	
	
	/*

  BEGIN
 INSERT INTO T_CASH_DIVIDEN (CA_TYPE,STK_CD,DISTRIB_DT,CLIENT_CD,QTY,
							RATE,GROSS_AMT, TAX_PCN, TAX_AMT, DIV_AMT,
							CRE_DT,USER_ID, UPD_DT,UPD_BY, APPROVED_DT,
							APPROVED_BY, APPROVED_STAT,RVPV_NUMBER,CUM_DATE,CUM_QTY,
							ONH,SELISIH_QTY,CUMDT_DIV_AMT,RVPV_KOREKSI)
					SELECT CA_TYPE, STK_CD, DISTRIB_DT,CLIENT_CD,CUM_QTY+SELISIH_QTY,
							RATE,GROSS_AMT,TAX_PCN, TAX_AMT,DIV_AMT,
							SYSDATE,P_USER_ID,NULL,NULL,SYSDATE,
							P_USER_ID,'A',RVPV_NUMBER,CUM_DT,CUM_QTY,
							ONH,SELISIH_QTY,DIV_AMT,null	FROM insistpro_rpt.R_T_CASH_DIVIDEN WHERE RAND_VALUE=P_RAND_VALUE AND USER_ID =P_USER_ID;
 
 
  EXCEPTION
    WHEN OTHERS THEN
    vo_errcd := -3;
	vo_errmsg := SUBSTR('INSERT INTO T_CASH_DIVIDEN'||SQLERRM,1,200);
  RAISE V_ERR;
    END;
 */
  
  
    vo_errcd := 1;
    vo_errmsg := '';
  
EXCEPTION
WHEN V_ERR THEN
rollback;
			vo_errcd := vo_errcd;
            vo_errmsg := vo_errmsg;
            
        WHEN OTHERS THEN
      ROLLBACK;
            vo_errcd := -1;
            vo_errmsg := SUBSTR(SQLERRM(SQLCODE),1,200);
            raise ;
    
END SP_INSERT_T_CASH_DIVIDEN;