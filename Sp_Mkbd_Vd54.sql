create or replace PROCEDURE Sp_Mkbd_Vd54( 
p_update_date DATE,
p_update_seq NUMBER,
p_mkbd_date DATE,
p_price_date date,
p_user_id       insistpro_rpt.LAP_MKBD_VD51.user_id%TYPE,
p_error_code			OUT			NUMBER,
p_error_msg				OUT			VARCHAR2
) IS

/******************************************************************************
   NAME:       SP_MKBD_VD54
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
v_nab t_reks_nab.nab%type;
v_risiko NUMBER;
v_err EXCEPTION;
v_error_code				NUMBER;
v_error_msg					VARCHAR2(200);

BEGIN

   v_end_date := p_mkbd_date;
   v_begin_date := TO_DATE('01'||TO_CHAR(p_mkbd_date,'/mm/yy'), 'dd/mm/yy');
   v_begin_prev := v_begin_date - 1;
   v_begin_prev := TO_DATE('01'||TO_CHAR(v_begin_prev,'/mm/yy'), 'dd/mm/yy');
   
  
  BEGIN
   INSERT INTO Insistpro_rpt.LAP_MKBD_VD54 (
   UPDATE_DATE, UPDATE_SEQ, MKBD_DATE, 
   VD, MKBD_CD, REKS_TYPE_TXT, 
    reks_type, reks_cd,
   REKS_NAME, AFILIASI, MARKET_VALUE, 
   NAB, RISIKO_PERSEN, BATASAN_MKBD, 
   RISIKO, user_id, APPROVED_STAT,CRE_DT, price_date) 
SELECT p_update_date update_date , p_update_seq update_seq , p_mkbd_date AS mkbd_date,
     'VD54' AS vd, 
	  TO_CHAR(TO_NUMBER(m.mkbd_cd) -  76)||'.'|| 
TO_CHAR(ROW_NUMBER(  ) over (PARTITION BY m.mkbd_cd ORDER BY m.mkbd_cd, a.reks_cd NULLs last ) )  mkbd_cd,
m.reks_type_txt,  m.reks_type, a.reks_cd,
NVL(a.reks_name,'NIHIL') reks_name, 
DECODE(a.afiliasi,'Y','Afiliasi','Tidak') afiliasi,
NVL(a.unit,0) * NVL(a.nab_unit,0) AS market_value, 
NVL(a.nab,0) nab,
m.risiko / 100 AS risiko_persen,
 NVL(a.nab,0) * m.risiko / 100 batasan_mkbd,
 GREATEST( (NVL(a.unit,0) * NVL(a.nab_unit,0))- ( NVL(a.nab,0) * m.risiko / 100), 0) risiko,
 p_user_id, 'E' approved_stat, V_CRE_DT, p_price_date
FROM( SELECT t.reks_cd, t.reks_name, t.reks_type, t.afiliasi,t.unit, n.nab_unit, n.nab
				FROM(SELECT reks_cd, reks_name, reks_type, afiliasi, SUM(subs -redm) unit
						FROM T_REKS_TRX
						WHERE trx_date <= v_end_date
                    AND approved_stat = 'A'
						GROUP BY  reks_cd, reks_name, reks_type, afiliasi
						HAVING SUM(subs -redm) > 0 ) t,
						( SELECT reks_cd, nab_unit, nab
						FROM T_REKS_NAB 
						WHERE mkbd_dt = p_price_date
                    AND approved_stat = 'A') n
				WHERE t.reks_cd = n.reks_cd ) a,		
				MST_REKS_TYPE m
WHERE  a.reks_type= m.reks_type;
EXCEPTION
WHEN OTHERS THEN
	 		v_error_code := -3;
			v_error_msg :=  SUBSTR('Insert to LAP_MKBD_VD54 '||SQLERRM,1,200);
			RAISE v_err;
END;
	

BEGIN
SELECT SUM(risiko), sum(nab) INTO v_risiko, v_nab
FROM insistpro_rpt.LAP_MKBD_VD54
WHERE  UPDATE_DATE = p_update_date
AND UPDATE_SEQ = p_update_seq
AND  MKBD_DATE = p_mkbd_date 
  AND  VD = 'VD54';
EXCEPTION
WHEN OTHERS THEN
	 		v_error_code := -4;
			v_error_msg :=  SUBSTR('SUM(risiko) '||SQLERRM,1,200);
			RAISE v_err;
END;

  
  IF v_nab > 0 THEN
  	 		  BEGIN
		  	  INSERT INTO insistpro_rpt.LAP_MKBD_VD54 (
		   UPDATE_DATE, UPDATE_SEQ, MKBD_DATE, 
		   VD, MKBD_CD,  reks_name,
		   RISIKO, APPROVED_STAT,USER_ID)
		   VALUES( P_UPDATE_DATE, P_UPDATE_SEQ, P_MKBD_DATE, 
		   'VD54', 'T',		'Nilai Yang Ditambahkan Sebagai Ranking Liabilities',   v_RISIKO, 'E',P_USER_ID);
		   
		   EXCEPTION
		   WHEN OTHERS THEN
	 		v_error_code := -5;
			v_error_msg :=  SUBSTR('Insert SUM(risiko) '||SQLERRM,1,200);
			RAISE v_err;
			END;

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
	      ROLLBACK;
	   p_error_code := -1;
	   p_error_msg := SUBSTR(SQLERRM,1,200);
       RAISE;
END Sp_Mkbd_Vd54;