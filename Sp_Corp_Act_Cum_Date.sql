create or replace PROCEDURE Sp_Corp_Act_Cum_Date( p_x_date DATE,
              p_recording_date DATE,
              p_distribution_date DATE,
              p_stk_cd MST_COUNTER.stk_cd%TYPE,
              P_PEMBAGI IN T_CORP_ACT.from_qty%TYPE,
              P_PENGALI IN T_CORP_ACT.to_qty%TYPE,
              p_ca_type T_CORP_ACT.ca_type%TYPE,
			  p_user_id T_CORP_ACT.user_id%TYPE,
			  p_error_code	OUT NUMBER,
			  p_error_msg	OUT VARCHAR2) IS
tmpVar NUMBER;
/******************************************************************************
   NAME:       CORP_ACT_CUM_DATE
   PURPOSE:

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        11/02/2012          1. Created this procedure.

   NOTES:
   28dec2017[indra] tambah di kursor beg_bal_qty - on_custody untuk ambil saham theo dari t_stkbal
   --07DEC2017[INDRA] RUBAH SPLIT DAN REVERSE SUPAYA PAKE CURSOR SUPAYA BISA DICALL MANUAL
  -- 2 Jul 2014 bonus pakai cursor spy bisa di run sesudah x date
   -- 3dec2013 ganti nama SP, sebelumnya REVERSE_stk_cum_date
       tambahan utk stk BONUS, DIVIDEN, hanya upd Bidprice
	   - output param Bid price dihapus
	   - IN param price dan doc rem dihapus

   -- 29oct 2013 - update T_CLOSE_PRICE  bidp = stk_clos *  dikali ratio
   -- 10May 2013 Table T_REVERSE_STK_QTY diganti dg T_CORP_ACT_FO spy dpt dipakai
      utk Corp Action lainnya
	  procedure ini juga dipakai utk Stk SPLIT , jika X-date jatuh pd tg 1,
	  procedure ini dijalankan pd hari seblm tgl 1, spy tgl 1 pagi qty di FO
	  sdh terupdate, krn T_STKHAND tidak bisa diupdate sebelum MONTH END

	 CORP ACT selain REVERSE, from_Dt dan TO_dt di T_CORP_ACT_FO diisi tg 1


   procedure ini dirun pd wkt cum date , stlh semua mutasi selesai diinput

******************************************************************************/

v_cum_dt DATE;
v_bgn_dt  DATE;

CURSOR Csr_bal IS
 SELECT client_cd, stk_cd,
	   SUM(theo_mvmt) bal_qty
	   FROM(	  SELECT client_cd, stk_cd,
		  (NVL(DECODE(SUBSTR(doc_num,5,2),'BR',1,'JR',1,'BI',1,'JI',1,'BO',1,'JO',1,'RS',1,'WS',1,0) *
		  DECODE(trim(NVL(gl_acct_cd,'36')),'14',1,'51',1,'12',1,'13',1,'10',1,0) * DECODE(db_cr_flg,'D',1,-1) *
		  (total_share_qty + withdrawn_share_qty),0)) theo_mvmt
	      FROM T_STK_MOVEMENT
		  WHERE doc_dt BETWEEN v_bgn_dt AND v_cum_dt
		AND stk_cd = p_stk_cd
		AND ((gl_acct_cd IN ('10','12','13','36','33','14','51','55','59','21','17','09','50')) OR (gl_acct_cd IS NULL)  )
		AND doc_stat    = '2'
 UNION ALL
 SELECT  client_cd, stk_cd, beg_bal_qty - on_custody
	FROM T_STKBAL
	WHERE bal_dt = v_bgn_dt
	AND stk_cd =p_stk_cd)
		GROUP BY  client_cd, stk_cd
	HAVING  SUM(theo_mvmt) > 0;


v_kebalikan NUMBER;
v_bid_price T_CLOSE_PRICE.STK_BIDP%TYPE;

v_err EXCEPTION;
v_error_code NUMBER;
v_error_msg VARCHAR2(200);
V_CNT NUMBER;
BEGIN
   tmpVar := 0;
   v_cum_dt := Get_Doc_Date(1,p_x_date);
   v_bgn_dt := v_cum_dt - TO_NUMBER(TO_CHAR(v_cum_dt,'dd')) + 1;
  
 BEGIN
 DELETE FROM T_CORP_ACT_FO
 WHERE stk_cd = p_stk_Cd
 AND from_dt =  p_x_date;
EXCEPTION
   WHEN OTHERS THEN
   v_error_code := -4;
   v_error_msg := SUBSTR('delete  T_CORP_ACT_FO '||SQLERRM,1,200);
	RAISE v_err;
 END;

 BEGIN
	SELECT	COUNT(1) INTO V_CNT FROM T_CORP_ACT WHERE STK_CD=p_stk_cd AND x_dt=p_x_date
	 AND RECORDING_DT=p_recording_date AND DISTRIB_DT=p_distribution_date AND CA_TYPE=p_ca_type;
	EXCEPTION
	   WHEN OTHERS THEN
	   v_error_code := -11;
	   v_error_msg := SUBSTR('CHECK T_CORP_ACT '||P_STK_CD||' '||SQLERRM,1,200);
		RAISE v_err;
	 END;

--07DEC2017
IF p_ca_type='REVERSE'  AND V_CNT>0 THEN

	FOR REC IN Csr_bal LOOP
			 BEGIN
			 INSERT INTO T_CORP_ACT_FO (
					   CA_TYPE, FROM_DT, TO_DT,
					   CLIENT_CD, STK_CD, QTY_RECEIVE,
					   QTY_WITHDRAW, USER_ID, CRE_DT,
					   STATUS)
			 VALUES(p_ca_type,p_x_date,p_distribution_date,
			 		REC.CLIENT_CD,REC.STK_CD,0,
			 		TRUNC(REC.bal_Qty - (REC.bal_Qty * P_PENGALI / P_PEMBAGI),0),
			 		p_user_id,SYSDATE,'A');
		EXCEPTION
	   WHEN OTHERS THEN
	   v_error_code := -16;
	   v_error_msg := SUBSTR('INSERT T_CORP_ACT_FO '||P_STK_CD||' '||SQLERRM,1,200);
		RAISE v_err;
	 END;

	END LOOP;

END IF;

IF p_ca_type='SPLIT' AND V_CNT>0 THEN
	
	FOR REC IN Csr_bal LOOP
			 BEGIN
			 INSERT INTO T_CORP_ACT_FO (
					   CA_TYPE, FROM_DT, TO_DT,
					   CLIENT_CD, STK_CD, QTY_RECEIVE,
					   QTY_WITHDRAW, USER_ID, CRE_DT,
					   STATUS)
			 VALUES(p_ca_type,p_x_date,p_distribution_date,
			 		REC.CLIENT_CD,REC.STK_CD,
			 		 TRUNC( (REC.bal_Qty * P_PENGALI / P_PEMBAGI) - REC.bal_Qty,0),0,
			 		p_user_id,SYSDATE,'A');
		EXCEPTION
	   WHEN OTHERS THEN
	   v_error_code := -19;
	   v_error_msg := SUBSTR('INSERT T_CORP_ACT_FO '||P_STK_CD||' '||SQLERRM,1,200);
		RAISE v_err;
	 END;

	END LOOP;
		
END IF;




--07DEC2017[INDRA] TIDAK DIPAKE, GUNAKAN KURSOR SUPAYA BISA DICALL MANUAL SPNYA SETIAP SAAT
/*
 IF  p_ca_type = 'REVERSE' THEN

				 	 v_kebalikan :=  p_pengali / p_pembagi;

					 BEGIN
					 INSERT INTO T_CORP_ACT_FO (
					   CA_TYPE, FROM_DT, TO_DT,
					   CLIENT_CD, STK_CD, QTY_RECEIVE,
					   QTY_WITHDRAW, USER_ID, CRE_DT,
					   STATUS)
					 SELECT 'REVERSE',x_dt, DISTRIB_DT, t.client_Cd, t.stk_cd, 0,
					 TRUNC(t.bal_Qty - (t.bal_Qty * to_qty / from_qty),0) withdr_qty,
					 p_user_id,SYSDATE, 'A'
					 FROM T_STKHAND t, T_CORP_ACT a
					 WHERE t.stk_cd = a.stk_cd
					 AND a.ca_type = 'REVERSE'
					 AND a.x_dt = p_x_date
					 AND t.bal_qty > 0;
					EXCEPTION
					   WHEN OTHERS THEN
					   v_error_code := -5;
					   v_error_msg := SUBSTR('Insert  T_CORP_ACT_FO '||SQLERRM,1,200);
					   RAISE v_err;
					 END;
	END IF;

 IF  p_ca_type = 'SPLIT' THEN

  	  v_kebalikan := p_pembagi / p_pengali;

		  	  BEGIN
			 INSERT INTO T_CORP_ACT_FO (
			   CA_TYPE, FROM_DT, TO_DT,
			   CLIENT_CD, STK_CD, QTY_RECEIVE,
			   QTY_WITHDRAW, USER_ID, CRE_DT,
			   STATUS)
			 SELECT 'SPLIT',x_dt, DISTRIB_DT, t.client_Cd, t.stk_cd,
			 TRUNC( (t.bal_Qty * to_qty / from_qty) - t.bal_Qty,0) recv_qty,
			 0, p_user_id,SYSDATE, 'A'
			 FROM T_STKHAND t, T_CORP_ACT a
			 WHERE t.stk_cd = a.stk_cd
			  AND t.stk_cd = p_stk_cd
			 AND a.ca_type = 'SPLIT'
			 AND a.x_dt = p_x_date
			 AND t.bal_qty <> 0;
			EXCEPTION
			   WHEN OTHERS THEN
			   v_error_code := -6;
			   v_error_msg := SUBSTR('Insert  T_CORP_ACT_FO '||SQLERRM,1,200);
			   RAISE v_err;
			 END;
  END IF;
*/

/* 20aug15 tdk dipakai lagi
  IF  p_ca_type = 'BONUS' OR p_ca_type = 'STKDIV' THEN

              FOR rec IN csr_bal LOOP

					  	  BEGIN
						 INSERT INTO T_CORP_ACT_FO (
						   CA_TYPE, FROM_DT, TO_DT,
						   CLIENT_CD, STK_CD, QTY_RECEIVE,
						   QTY_WITHDRAW, USER_ID, CRE_DT,
						   STATUS)
						 SELECT 'BONUS',x_dt, DISTRIB_DT, rec.client_Cd, p_stk_cd,
						 TRUNC( (rec.bal_Qty * to_qty / from_qty) ,0) recv_qty,
						 0, p_user_id,SYSDATE, 'A'
						 FROM  T_CORP_ACT a
						 WHERE  a.stk_cd = p_stk_cd
						 AND a.ca_type = 'BONUS'
						 AND a.x_dt = p_x_date
						 AND TRUNC( (rec.bal_Qty * to_qty / from_qty) ,0) > 0;
			EXCEPTION
			   WHEN OTHERS THEN
			   v_error_code := -6;
			   v_error_msg := SUBSTR('Insert  T_CORP_ACT_FO '||SQLERRM,1,200);
			   RAISE v_err;
			 END;

			END LOOP;

  	  v_kebalikan := (p_pembagi + p_pengali) / p_pembagi;

  END IF;
*/

-- utk SPLIT. REVERSE
-- krn Aug15 sp ini dicall dr SP CA JUR SCHED
--  upd T CLOSE PRICE sdh di SP CA JUR SCHED


  BEGIN
  UPDATE T_CLOSE_PRICE
  SET STK_BIDP = ROUND(stk_clos * v_kebalikan,0)
  WHERE stk_date = v_cum_dt
  AND stk_cd = p_stk_cd;
  EXCEPTION
	   WHEN OTHERS THEN
	   v_error_code := -8;
	   v_error_msg := SUBSTR('Insert  T_CLOSE_PRICE '||SQLERRM,1,200);
	   RAISE v_err;
  END;


   p_error_code := 1;
  p_error_msg := '';
   EXCEPTION
     WHEN NO_DATA_FOUND THEN
       NULL;
	 WHEN v_err THEN
	 	  p_error_code := v_error_code;
		  p_error_msg  := v_error_msg;
		  ROLLBACK;
     WHEN OTHERS THEN
	   p_error_code := -1;
	   p_error_msg := SUBSTR(SQLERRM,1,200);
       ROLLBACK;
       RAISE;
END Sp_Corp_Act_Cum_Date;