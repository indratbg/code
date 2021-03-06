create or replace PROCEDURE SP_GET_TXT_MKBD(
    P_UPDATE_DATE T_MANY_HEADER.UPDATE_DATE%TYPE,
    P_UPDATE_SEQ T_MANY_HEADER.UPDATE_SEQ%TYPE,
    P_USER_ID T_MANY_HEADER.USER_ID%TYPE,
    P_MENU_NAME T_MANY_HEADER.MENU_NAME%TYPE,
    P_ERROR_CD OUT NUMBER,
    P_ERROR_MSG OUT VARCHAR2)
IS
  V_ERR       EXCEPTION;
  V_ERROR_CD  NUMBER(5);
  V_ERROR_MSG VARCHAR2(200);
  V_DIREKTUR MST_COMPANY.NAMA_PRSH%TYPE;
  V_KODE_AB MST_PARAMETER.PRM_DESC%TYPE;
  V_CNT NUMBER;
BEGIN

BEGIN
DELETE FROM R_TXT WHERE MENU_NAME=P_MENU_NAME;
EXCEPTION
WHEN OTHERS THEN
    V_ERROR_CD  := -5;
    V_ERROR_MSG := SUBSTR('DELETE DATA FROM R_TXT WITH '||P_MENU_NAME||' '|| SQLERRM(SQLCODE),1,200);
    RAISE V_ERR;
  END;
  
--DIREKTUR
BEGIN
 INSERT INTO R_TXT
      (IDENTIFIER,TXT,SEQNO,USER_ID,MENU_NAME
      )
      SELECT IDENTIFIER,TXT,ROWNUM,P_USER_ID,P_MENU_NAME FROM
      (
select '01' IDENTIFIER,'Kode AB|'||substr(prm_desc,1,2)||'|||||||||' TXT from mst_parameter where  prm_cd_1 = 'AB' and prm_cd_2 ='000' 
UNION ALL
SELECT '02' IDENTIFIER,'Tanggal|'||TO_CHAR(MKBD_DATE,'YYYYMMDD')||'|||||||||'TXT FROM LAP_MKBD_VD51 WHERE   update_seq      = P_UPDATE_SEQ
    AND update_date     = P_UPDATE_DATE
    AND APPROVED_STAT ='A' AND ROWNUM=1
UNION ALL
select '03' IDENTIFIER, 'Direktur|'||contact_pers||'|||||||||' TXT from mst_company 
);
EXCEPTION
WHEN OTHERS THEN
    V_ERROR_CD  := -5;
    V_ERROR_MSG := SUBSTR('SELECT CONTACT PERSON FROM MST_COMPANY'|| SQLERRM(SQLCODE),1,200);
    RAISE V_ERR;
  END;


  --VD51
  BEGIN
    INSERT INTO R_TXT
      (IDENTIFIER,TXT,SEQNO,USER_ID,MENU_NAME
      )
    SELECT '04' AS IDENTIFIER, VD||'.'||TRIM(A.MKBD_CD)||'|'||DECODE(B.VIS1,1,TRIM(TO_CHAR(A.C1,'9999999999999999990.99')),'')||'|||||||||' AS text_vd51, 
    ROW_NUMBER() OVER ( ORDER BY A.mkbd_cd ) AS SEQNO, P_USER_ID, P_MENU_NAME
    FROM INSISTPRO_RPT.LAP_MKBD_VD51 a,IPNEXTG.form_mkbd B
    WHERE A.MKBD_CD     =B.MKBD_CD
    AND b.source        ='VD51'
    AND update_seq      = P_UPDATE_SEQ
    AND update_date     = P_UPDATE_DATE
    AND A.APPROVED_STAT ='A'
    ORDER BY a.mkbd_cd;
  EXCEPTION
  WHEN NO_DATA_FOUND THEN
    NULL;
  WHEN OTHERS THEN
    V_ERROR_CD  := -10;
    V_ERROR_MSG := SUBSTR('INSERT INTO R_TXT VD51'|| SQLERRM(SQLCODE),1,200);
    RAISE V_ERR;
  END;
  --VD52
  BEGIN
    INSERT INTO R_TXT
      (IDENTIFIER,TXT,SEQNO,USER_ID,MENU_NAME
      )
    SELECT '05' AS IDENTIFIER, VD||'.'||TRIM(A.MKBD_CD)||'|'||DECODE(B.VIS1,1,TRIM(TO_CHAR(A.C1,'9999999999999999990.99')),'')||'|||||||||' AS text_vd52, 
    ROW_NUMBER() OVER ( ORDER BY A.mkbd_cd ) AS SEQNO, P_USER_ID, P_MENU_NAME
    FROM INSISTPRO_RPT.LAP_MKBD_VD52 a,IPNEXTG.form_mkbd B
    WHERE A.MKBD_CD     =B.MKBD_CD
    AND b.source        ='VD52'
    AND update_seq      = P_UPDATE_SEQ
    AND update_date     = P_UPDATE_DATE
    AND A.APPROVED_STAT ='A'
    ORDER BY a.mkbd_cd;
  EXCEPTION
  WHEN NO_DATA_FOUND THEN
    NULL;
  WHEN OTHERS THEN
    V_ERROR_CD  := -20;
    V_ERROR_MSG := SUBSTR('INSERT INTO R_TXT VD52'|| SQLERRM(SQLCODE),1,200);
    RAISE V_ERR;
  END;
  --VD53
  BEGIN
    INSERT INTO R_TXT
      (IDENTIFIER,TXT,SEQNO,USER_ID,MENU_NAME
      )
    SELECT '06' AS IDENTIFIER,VD||'.'||TRIM(A.MKBD_CD)||'|'||DECODE(B.VIS1,1,TRIM(TO_CHAR(A.C1,'9999999999999999990.99')),'')||'|||||||||' AS text_vd53 , 
    ROW_NUMBER() OVER ( ORDER BY A.mkbd_cd ) AS SEQNO, P_USER_ID, P_MENU_NAME
    FROM insistpro_rpt.LAP_MKBD_VD53 a,IPNEXTG.form_mkbd B
    WHERE A.MKBD_CD     =B.MKBD_CD
    AND b.source        ='VD53'
    AND update_seq      = P_UPDATE_SEQ
    AND update_date     = P_UPDATE_DATE
    AND A.APPROVED_STAT ='A'
    ORDER BY a.mkbd_cd;
  EXCEPTION
  WHEN NO_DATA_FOUND THEN
    NULL;
  WHEN OTHERS THEN
    V_ERROR_CD  := -30;
    V_ERROR_MSG := SUBSTR('INSERT INTO R_TXT VD53'|| SQLERRM(SQLCODE),1,200);
    RAISE V_ERR;
  END;
  --VD54
  BEGIN
    INSERT INTO R_TXT
      (IDENTIFIER,TXT,SEQNO,USER_ID,MENU_NAME
      )
    SELECT '07' AS IDENTIFIER, VD||'.'||TRIM(MKBD_CD)||'|'||TRIM(REKS_TYPE)||'|'||TRIM(REKS_CD)||'|'||TRIM(AFILIASI)||'|'|| TRIM(TO_CHAR(MARKET_VALUE,'99999999999999999999999999990.99'))||'|' || TRIM(TO_CHAR(NAB,'99999999999999999999999999990.99'))||'||'|| TRIM(TO_CHAR(BATASAN_MKBD,'99999999999999999999999999990.99'))||'|'|| TRIM(TO_CHAR(RISIKO,'99999999999999999999999999990.99'))||'||' AS text_vd54 , 
    ROW_NUMBER() OVER ( ORDER BY mkbd_cd ) AS SEQNO, P_USER_ID, P_MENU_NAME
    FROM insistpro_rpt.lap_mkbd_vd54
    WHERE approved_stat='A'
    AND update_seq     = P_UPDATE_SEQ
    AND update_date    = P_UPDATE_DATE
    ORDER BY mkbd_cd;
  EXCEPTION
  WHEN NO_DATA_FOUND THEN
   NULL;
  WHEN OTHERS THEN
    V_ERROR_CD  := -40;
    V_ERROR_MSG := SUBSTR('INSERT INTO R_TXT VD54'|| SQLERRM(SQLCODE),1,200);
    RAISE V_ERR;
  END;
  
  
  SELECT COUNT(1) INTO V_CNT FROM lap_mkbd_vd54 WHERE  approved_stat='A' 
							  	    AND update_seq     = P_UPDATE_SEQ
    AND update_date    = P_UPDATE_DATE ;
    
    IF V_CNT=0 THEN
     INSERT INTO R_TXT
      (IDENTIFIER,TXT,SEQNO,USER_ID,MENU_NAME
      )
      SELECT '07' AS IDENTIFIER,'VD54.T||||||||||' TXT, ROWNUM,P_USER_ID,P_MENU_NAME FROM DUAL;
    END IF;
  
  --VD55
  BEGIN
    INSERT INTO R_TXT
      (IDENTIFIER,TXT,SEQNO,USER_ID,MENU_NAME
      )
   select '08' AS IDENTIFIER, TRIM(VD)||'.'||TRIM(MKBD_CD)||'|'||
							      TRIM(NAMA_EFEK)||'|'||TRIM(TO_CHAR(NILAI_EFEK,'9999999999999999990.99'))||'|'||
							      TRIM(NAMA_LINDUNG)||'|'||TRIM(TO_CHAR(NILAI_LINDUNG,'9999999999999999990.99'))||'|'||
							      TRIM(TO_CHAR(NILAI_TUTUP,'9999999999999999990.99'))||'|'||TRIM(TO_CHAR(NILAI_HAIRCUT,'9999999999999999990.99'))||'|'||
							      TRIM(TO_CHAR(NILAI_HAIRCUT_LINDUNG,'9999999999999999990.99'))||'|'||TRIM(TO_CHAR(PENGEMBALIAN,'9999999999999999990.99'))||'||'
								   AS text_vd55 , ROWNUM AS SEQNO, P_USER_ID, P_MENU_NAME
								   FROM insistpro_rpt.LAP_MKBD_VD55 where approved_stat='A' 
							  	    AND update_seq     = P_UPDATE_SEQ
    AND update_date    = P_UPDATE_DATE ;
  EXCEPTION
  WHEN NO_DATA_FOUND THEN
NULL;
  WHEN OTHERS THEN
    V_ERROR_CD  := -50;
    V_ERROR_MSG := SUBSTR('INSERT INTO R_TXT VD55'|| SQLERRM(SQLCODE),1,200);
    RAISE V_ERR;
  END;
  
  SELECT COUNT(1) INTO V_CNT FROM LAP_MKBD_VD55 WHERE  approved_stat='A' 
							  	    AND update_seq     = P_UPDATE_SEQ
    AND update_date    = P_UPDATE_DATE ;
    
    IF V_CNT=0 THEN
     INSERT INTO R_TXT
      (IDENTIFIER,TXT,SEQNO,USER_ID,MENU_NAME
      )
      SELECT '08' AS IDENTIFIER,'VD55.T||||||||||' TXT,ROWNUM, P_USER_ID,P_MENU_NAME FROM DUAL;
    END IF;
  
   --VD56A
  BEGIN
    INSERT INTO R_TXT
      (IDENTIFIER,TXT,SEQNO,USER_ID,MENU_NAME
      )
  SELECT '09' AS IDENTIFIER,VD||'.'||TRIM(A.MKBD_CD)||'|'||
								DECODE(B.VIS1,1,TRIM(TO_CHAR(A.C1,'9999999999999999990.99')),'')||'|' ||
								DECODE(B.VIS2,1,TRIM(TO_CHAR(A.C2,'9999999999999999990.99')),'')||'|'|| 
								DECODE(B.VIS3,1,TRIM(TO_CHAR(A.C3,'9999999999999999990.99')),'')||'|'|| 
								DECODE(B.VIS4,1,TRIM(TO_CHAR(A.C4,'9999999999999999990.99')),'')||'||||||'
								AS text_vd56a , ROW_NUMBER() OVER ( ORDER BY A.mkbd_cd ) AS SEQNO, P_USER_ID, P_MENU_NAME
								FROM insistpro_rpt.LAP_MKBD_VD56 a,IPNEXTG.form_mkbd B WHERE A.MKBD_CD =B.MKBD_CD  
								and b.source='VD56' AND A.MKBD_CD between 8 and 23
							  AND update_seq     = P_UPDATE_SEQ
                AND update_date    = P_UPDATE_DATE 
								and A.MKBD_CD <> 16 AND A.APPROVED_STAT ='A' order by a.mkbd_cd;
  EXCEPTION
  WHEN NO_DATA_FOUND THEN
    NULL;
  WHEN OTHERS THEN
    V_ERROR_CD  := -60;
    V_ERROR_MSG := SUBSTR('INSERT INTO R_TXT VD56A'|| SQLERRM(SQLCODE),1,200);
    RAISE V_ERR;
  END;
  
    
   --VD56B
  BEGIN
    INSERT INTO R_TXT
      (IDENTIFIER,TXT,SEQNO,USER_ID,MENU_NAME
      )
 SELECT '10' AS IDENTIFIER, VD||'.'||TRIM(A.MKBD_CD)||'.'||TRIM(A.NORUT)||'|'||TRIM(SUBSTR(A.DESCRIPTION,1,3))||'|'||
								TRIM(SUBSTR(A.MILIK,1,1))||'|'||TRIM(A.BANK_ACCT_CD)||'|'||TRIM(A.CURRENCY)||'|'||
								TRIM(TO_CHAR(A.C3,'9999999999999999990.99'))||'|' ||
								TRIM(TO_CHAR(A.C4,'9999999999999999990.99'))||'||||' 
								AS text_vd56b  , ROW_NUMBER() OVER ( ORDER BY A.NORUT) AS SEQNO, P_USER_ID, P_MENU_NAME
								FROM insistpro_rpt.LAP_MKBD_VD56 a,IPNEXTG.form_mkbd B WHERE A.MKBD_CD =B.MKBD_CD 
								 and b.source='VD56' AND A.MKBD_CD ='24' AND A.NORUT > 0
								   AND update_seq     = P_UPDATE_SEQ
                AND update_date    = P_UPDATE_DATE 
                AND A.APPROVED_STAT ='A' order by  A.NORUT;
  EXCEPTION
  WHEN NO_DATA_FOUND THEN
    NULL;
  WHEN OTHERS THEN
    V_ERROR_CD  := -70;
    V_ERROR_MSG := SUBSTR('INSERT INTO R_TXT VD56B'|| SQLERRM(SQLCODE),1,200);
    RAISE V_ERR;
  END;
  
  
   --VD56P
  BEGIN
    INSERT INTO R_TXT
      (IDENTIFIER,TXT,SEQNO,USER_ID,MENU_NAME
      )
      SELECT '11' AS IDENTIFIER,'VD56.P||||||||||',ROWNUM,P_USER_ID, P_MENU_NAME FROM DUAL;
      EXCEPTION
   WHEN OTHERS THEN
    V_ERROR_CD  := -75;
    V_ERROR_MSG := SUBSTR('INSERT INTO R_TXT VD56P'|| SQLERRM(SQLCODE),1,200);
    RAISE V_ERR;
  END;
  
   --VD57
  BEGIN
    INSERT INTO R_TXT
      (IDENTIFIER,TXT,SEQNO,USER_ID,MENU_NAME
      )
 SELECT '12' AS IDENTIFIER,VD||'.'||TRIM(A.MKBD_CD)||'|'||
								DECODE(B.VIS1,1,TRIM(TO_CHAR(A.C1,'9999999999999999990.99')),'')||'|'||
								DECODE(B.VIS2,1,TRIM(TO_CHAR(A.C2,'9999999999999999990.99')),'')||'|'||
								DECODE(B.VIS3,1,TRIM(TO_CHAR(A.C3,'9999999999999999990.99')),'')||'|'||
								DECODE(B.VIS4,1,TRIM(TO_CHAR(A.C4,'9999999999999999990.99')),'')||'||||||'
								AS text_vd57 ,  ROW_NUMBER() OVER ( ORDER BY  A.MKBD_CD) AS SEQNO, P_USER_ID, P_MENU_NAME
								FROM insistpro_rpt.LAP_MKBD_VD57 a,IPNEXTG.form_mkbd B WHERE A.MKBD_CD =B.MKBD_CD  and b.source='VD57' 
								AND A.APPROVED_STAT ='A' AND A.MKBD_CD NOT IN (7,27,37,38)  
							  AND update_seq     = P_UPDATE_SEQ
                AND update_date    = P_UPDATE_DATE  order by  A.MKBD_CD;
  EXCEPTION
  WHEN NO_DATA_FOUND THEN
    NULL;
  WHEN OTHERS THEN
    V_ERROR_CD  := -80;
    V_ERROR_MSG := SUBSTR('INSERT INTO R_TXT VD57'|| SQLERRM(SQLCODE),1,200);
    RAISE V_ERR;
  END;
  
  
   --VD57P
  BEGIN
    INSERT INTO R_TXT
      (IDENTIFIER,TXT,SEQNO,USER_ID,MENU_NAME
      )
      SELECT '13' AS IDENTIFIER,'VD57.P||||||||||',ROWNUM,P_USER_ID, P_MENU_NAME FROM DUAL;
      EXCEPTION
   WHEN OTHERS THEN
    V_ERROR_CD  := -85;
    V_ERROR_MSG := SUBSTR('INSERT INTO R_TXT VD57P'|| SQLERRM(SQLCODE),1,200);
    RAISE V_ERR;
  END;
  
   --VD58
  BEGIN
    INSERT INTO R_TXT
      (IDENTIFIER,TXT,SEQNO,USER_ID,MENU_NAME
      )
 SELECT '14' AS IDENTIFIER, VD||'.'||TRIM(A.MKBD_CD)||'||||'||
								DECODE(B.VIS1,1,TRIM(TO_CHAR(A.C1,'9999999999999999990.99')),'')||'||||||'
								AS text_vd58  , ROW_NUMBER() OVER ( ORDER BY  A.MKBD_CD)  AS SEQNO, P_USER_ID, P_MENU_NAME
								FROM insistpro_rpt.LAP_MKBD_VD58 a,IPNEXTG.form_mkbd B WHERE A.MKBD_CD =B.MKBD_CD  and b.source='VD58' 
								   AND update_seq     = P_UPDATE_SEQ
                AND update_date    = P_UPDATE_DATE
                AND A.APPROVED_STAT ='A' order by  A.MKBD_CD;
  EXCEPTION
  WHEN NO_DATA_FOUND THEN
    NULL;
  WHEN OTHERS THEN
    V_ERROR_CD  := -90;
    V_ERROR_MSG := SUBSTR('INSERT INTO R_TXT VD58'|| SQLERRM(SQLCODE),1,200);
    RAISE V_ERR;
  END;
    --VD59
  BEGIN
    INSERT INTO R_TXT
      (IDENTIFIER,TXT,SEQNO,USER_ID,MENU_NAME
      )
 SELECT '15' AS IDENTIFIER,VD||'.'||TRIM(A.MKBD_CD)||'||||'||
								 DECODE(B.VIS1,1,TRIM(TO_CHAR(A.C1,'9999999999999999990.99')),'')||'||' ||
								 DECODE(B.VIS2,1,TRIM(TO_CHAR(A.C2,'9999999999999999990.99')),'')||'||||' 
								 AS text_vd59 , ROW_NUMBER() OVER ( ORDER BY  A.MKBD_CD)  AS SEQNO, P_USER_ID, P_MENU_NAME
							     FROM insistpro_rpt.LAP_MKBD_VD59 a,IPNEXTG.form_mkbd B WHERE A.MKBD_CD =B.MKBD_CD 
								 and b.source='VD59' AND A.APPROVED_STAT ='A'
								    AND update_seq     = P_UPDATE_SEQ
                AND update_date    = P_UPDATE_DATE order by  A.mkbd_cd;
  EXCEPTION
  WHEN NO_DATA_FOUND THEN
    NULL;
  WHEN OTHERS THEN
    V_ERROR_CD  := -100;
    V_ERROR_MSG := SUBSTR('INSERT INTO R_TXT VD59'|| SQLERRM(SQLCODE),1,200);
    RAISE V_ERR;
  END;
  
    --VD510A
  BEGIN
    INSERT INTO R_TXT
      (IDENTIFIER,TXT,SEQNO,USER_ID,MENU_NAME
      )
 select '16' AS IDENTIFIER, 'VD510.A.'||TRIM(MKBD_CD)||'|'||TRIM(JENIS_CD)||'|'||TRIM(JENIS)||'|'||
								   TRIM(LAWAN)||'|'||TRIM(TO_CHAR(EXTENT_DT,'DD/MM/YYYY'))||'|'||
								    TRIM(TO_CHAR(DUE_DATE,'DD/MM/YYYY'))||'|'||
								    TRIM(TO_CHAR(REPO_VAL,'9999999999999999990.99'))||'|'||
								   TRIM(TO_CHAR(RETURN_VAL,'9999999999999999990.99'))||'|'||
								    TRIM(STK_CD)||'|'||
								    TRIM(TO_CHAR(SUM_QTY,'99999999999999999999999999990.99'))||'|'||
								  TRIM(TO_CHAR(RANKING,'99999999999999999999999999990.99'))
								AS text_vd510a, ROWNUM AS SEQNO, P_USER_ID, P_MENU_NAME
								FROM insistpro_rpt.LAP_MKBD_VD510A where approved_stat='A' 
								   AND update_seq     = P_UPDATE_SEQ
                AND update_date    = P_UPDATE_DATE;
  EXCEPTION
  WHEN NO_DATA_FOUND THEN
    NULL;
  WHEN OTHERS THEN
    V_ERROR_CD  := -110;
    V_ERROR_MSG := SUBSTR('INSERT INTO R_TXT VD510A'|| SQLERRM(SQLCODE),1,200);
    RAISE V_ERR;
  END;
  
   --VD510B
  BEGIN
    INSERT INTO R_TXT
      (IDENTIFIER,TXT,SEQNO,USER_ID,MENU_NAME
      )
 SELECT '17' AS IDENTIFIER, 'VD510.B.'||TRIM(MKBD_CD)||'|'||DECODE(MKBD_CD,'A','','B','','C','','T','',TRIM(JENIS_CD))||'|'||
							    TRIM(LAWAN)||'|'||TRIM(TO_CHAR(EXTENT_DT,'DD/MM/YYYY'))||'|'||
							    TRIM(TO_CHAR(DUE_DATE,'DD/MM/YYYY'))||'|'||
							    TRIM(TO_CHAR(REPO_VAL,'9999999999999999990.99'))||'|'||
							    TRIM(TO_CHAR(RETURN_VAL,'9999999999999999990.99'))||'|'||
							    TRIM(STK_CD)||'|'||
							    TRIM(TO_CHAR(SUM_QTY,'9999999999999999999999999990.99'))||'|'||
							    TRIM(TO_CHAR(MARKET_VAL,'9999999999999999999999999990.99'))||'|'||
							    TRIM(TO_CHAR(RANKING,'9999999999999999999999999990.99'))
							    AS text_vd510b, ROWNUM AS SEQNO, P_USER_ID, P_MENU_NAME
							    FROM insistpro_rpt.LAP_MKBD_VD510B where APPROVED_STAT ='A' 
							       AND update_seq     = P_UPDATE_SEQ
                AND update_date    = P_UPDATE_DATE;
  EXCEPTION
  WHEN NO_DATA_FOUND THEN
    NULL;
  WHEN OTHERS THEN
    V_ERROR_CD  := -120;
    V_ERROR_MSG := SUBSTR('INSERT INTO R_TXT VD510B'|| SQLERRM(SQLCODE),1,200);
    RAISE V_ERR;
  END;
  
  
  
   --VD510C
  BEGIN
    INSERT INTO R_TXT
      (IDENTIFIER,TXT,SEQNO,USER_ID,MENU_NAME
      )
 select '18' AS IDENTIFIER, 'VD510.C.'||TRIM(MKBD_CD)||'||'||DECODE(MKBD_CD,'A','','B','','C','','D','','E','','T','',TRIM(STK_CD))||'|'||
								   DECODE(MKBD_CD,'A','','B','','C','','D','','E','','T','', TRIM(AFILIASI))||'|'||
								   DECODE(MKBD_CD,'A','','B','','C','','D','','E','','T','', TRIM(TO_CHAR(QTY,'99999999999999999999999999990.99')))||'|'||
								   DECODE(MKBD_CD,'A','','B','','C','','D','','E','','T','', TRIM(TO_CHAR(BUY_PRICE,'99999999999999999999999999990.99')))||'|'||
								   DECODE(MKBD_CD,'A','','B','','C','','D','','E','','T','',  TRIM(TO_CHAR(PRICE,'99999999999999999999999999990.99')))||'|'||
								   TRIM(TO_CHAR(MARKET_VAL,'99999999999999999999999999990.99'))||'|'||
								   DECODE(MKBD_CD,'A','','B','','C','','D','','E','','T','',TRIM(GRP_EMITENT))||'|'||
								   DECODE(MKBD_CD,'A','','B','','C','','D','','E','','T','', TRIM(TO_CHAR(PERSEN_MARKET,'99999999999999999999999999990.99')))||'|'||
								   TRIM(TO_CHAR(RANKING,'99999999999999999999999999990.99'))
								   as text_vd510c, ROW_NUMBER() OVER ( ORDER BY  DECODE(substr(mkbd_cd,3),NULL,'Z','A')||SUBSTR(MKBD_CD,1,1)||TO_CHAR(to_number(nvl(substr(mkbd_cd,3),999)),'FM000')
									,mkbd_cd )  AS SEQNO, P_USER_ID, P_MENU_NAME
								   from  insistpro_rpt.LAP_MKBD_VD510C where
								    approved_stat='A'    AND update_seq     = P_UPDATE_SEQ
                AND update_date    = P_UPDATE_DATE
								    order by DECODE(substr(mkbd_cd,3),NULL,'Z','A')||SUBSTR(MKBD_CD,1,1)||TO_CHAR(to_number(nvl(substr(mkbd_cd,3),999)),'FM000')
									,mkbd_cd  ;
  EXCEPTION
  WHEN NO_DATA_FOUND THEN
    NULL;
  WHEN OTHERS THEN
    V_ERROR_CD  := -130;
    V_ERROR_MSG := SUBSTR('INSERT INTO R_TXT VD510C'|| SQLERRM(SQLCODE),1,200);
    RAISE V_ERR;
  END;
  
  
  
   --VD510D
  BEGIN
    INSERT INTO R_TXT
      (IDENTIFIER,TXT,SEQNO,USER_ID,MENU_NAME
      )
 select '19' AS IDENTIFIER,'VD510.D.'||TRIM(MKBD_CD)||'|'||DECODE(MKBD_CD,'A','','B','','T','',TRIM(SID))||'|'||
									DECODE(MKBD_CD,'A','','B','','T','',TRIM(TRX_TYPE))||'|'||
								   TRIM(TO_CHAR(END_BAL,'99999999999999999999999999990.99'))||'|'||
								   TRIM(TO_CHAR(STK_VAL,'99999999999999999999999999990.99'))||'|'||
								   DECODE(MKBD_CD,'A','','B','','T','',TRIM(TO_CHAR(RATIO,'99999999999999999999999999990.99')))||'|'||
								   TRIM(TO_CHAR(LEBIH_CLIENT,'99999999999999999999999999990.99'))||'|'||
								   TRIM(TO_CHAR(LEBIH_PORTO,'99999999999999999999999999990.99'))||'|||'
								   AS text_vd510d,  ROW_NUMBER() OVER ( ORDER BY  substr(mkbd_cd,1,1), 
								to_number(nvl(substr(mkbd_cd,3),999))) AS SEQNO, P_USER_ID, P_MENU_NAME
								from insistpro_rpt.LAP_MKBD_VD510D
								Where approved_stat='A'  AND update_seq     = P_UPDATE_SEQ
                AND update_date    = P_UPDATE_DATE
								Order By substr(mkbd_cd,1,1), 
								to_number(nvl(substr(mkbd_cd,3),999));
  EXCEPTION
  WHEN NO_DATA_FOUND THEN
    NULL;
  WHEN OTHERS THEN
    V_ERROR_CD  := -140;
    V_ERROR_MSG := SUBSTR('INSERT INTO R_TXT VD510D'|| SQLERRM(SQLCODE),1,200);
    RAISE V_ERR;
  END;
  
   --VD510E
  BEGIN
    INSERT INTO R_TXT
      (IDENTIFIER,TXT,SEQNO,USER_ID,MENU_NAME
      )
 select '20' AS IDENTIFIER, 'VD510.E.'||TRIM(MKBD_CD)||'||'||DECODE(MKBD_CD,'T','',TRIM(STK_CD))||'|'||
							      TRIM(TO_CHAR(QTY,'9999999999999999990.99'))||'|'||
							      TRIM(TO_CHAR(PRICE,'9999999999999999990.99'))||'|'||
							      TRIM(TO_CHAR(MARKET_VAL,'9999999999999999990.99'))||'|||||'
								  AS text_vd510e, ROWNUM AS SEQNO, P_USER_ID, P_MENU_NAME
								  from insistpro_rpt.LAP_MKBD_VD510E
								  Where approved_stat='A' AND update_seq     = P_UPDATE_SEQ
                AND update_date    = P_UPDATE_DATE;
  EXCEPTION
  WHEN NO_DATA_FOUND THEN
    NULL;
  WHEN OTHERS THEN
    V_ERROR_CD  := -150;
    V_ERROR_MSG := SUBSTR('INSERT INTO R_TXT VD510E'|| SQLERRM(SQLCODE),1,200);
    RAISE V_ERR;
  END;
  
  --VD510F
  BEGIN
    INSERT INTO R_TXT
      (IDENTIFIER,TXT,SEQNO,USER_ID,MENU_NAME
      )
select '21' AS IDENTIFIER, 'VD510.F.' || TRIM(MKBD_CD) || '|' ||
									DECODE(GRP,'D',TRIM(TO_CHAR(TGL_KONTRAK,'DD/MM/YYYY')),'') || '|' ||
									DECODE(GRP,'D',TRIM(JENIS_PENJAMINAN),'') || '|' ||
									DECODE(GRP,'D',TRIM(STK_NAME),'') || '|' ||
									DECODE(GRP,'D',TRIM(STATUS_PENJAMINAN),'') || '|' ||
									TRIM(TO_CHAR(NILAI_KOMITMENT,'999999999999999990.99')) || '|' ||
									CASE 
										WHEN GRP = 'D' OR HAIRCUT <> 0 THEN
											TRIM(TO_CHAR(HAIRCUT,'999999999999999990.99')) || '|'
										ELSE
											'|' 
									END ||
									CASE 
										WHEN GRP = 'D' OR UNSUBSCRIBE_AMT <> 0 THEN
											TRIM(TO_CHAR(UNSUBSCRIBE_AMT,'999999999999999990.99')) || '|'
										ELSE
											'|' 
									END ||
									CASE 
										WHEN GRP = 'D' OR BANK_GARANSI <> 0 THEN
											TRIM(TO_CHAR(BANK_GARANSI,'999999999999999990.99')) || '|'
										ELSE
											'|' 
									END ||
							    	TRIM(TO_CHAR(RANKING,'999999999999999990.99')) || '|' 
									AS text_vd510f, ROWNUM AS SEQNO, P_USER_ID, P_MENU_NAME
									from insistpro_rpt.LAP_MKBD_VD510F
									Where approved_stat='A' 
									AND update_seq     = P_UPDATE_SEQ
                AND update_date    = P_UPDATE_DATE ;
  EXCEPTION
  WHEN NO_DATA_FOUND THEN
    NULL;
  WHEN OTHERS THEN
    V_ERROR_CD  := -160;
    V_ERROR_MSG := SUBSTR('INSERT INTO R_TXT VD510F'|| SQLERRM(SQLCODE),1,200);
    RAISE V_ERR;
  END;
  
  
  --VD510G
  BEGIN
    INSERT INTO R_TXT
      (IDENTIFIER,TXT,SEQNO,USER_ID,MENU_NAME
      )
select '22' AS IDENTIFIER, 'VD510.G.'||TRIM(MKBD_CD)||'|'||
							    TRIM(TO_CHAR(CONTRACT_DT,'DD/MM/YYY'))||'|'||
							    TRIM(GUARANTEED)||'|'||
							    TRIM(AFILIASI)||'|'||
							    TRIM(RINCIAN)||'|'||
							    TRIM(JANGKA)||'|'||
							    TRIM(TO_CHAR(END_CONTRACT_DT,'DD/MM/YYYY'))||'|'||
							    TRIM(TO_CHAR(NILAI,'999999999999999990.99'))||'|'||
							    TRIM(TO_CHAR(RANKING,'999999999999999990.99'))||'||'
							    as text_vd510g, ROWNUM AS SEQNO, P_USER_ID, P_MENU_NAME
							    FROM insistpro_rpt.LAP_MKBD_VD510G Where approved_stat='A' 
							  	AND update_seq     = P_UPDATE_SEQ
                AND update_date    = P_UPDATE_DATE;
  EXCEPTION
  WHEN NO_DATA_FOUND THEN
    NULL;
  WHEN OTHERS THEN
    V_ERROR_CD  := -170;
    V_ERROR_MSG := SUBSTR('INSERT INTO R_TXT VD510G'|| SQLERRM(SQLCODE),1,200);
    RAISE V_ERR;
  END;
  
  
  --VD510H
  BEGIN
    INSERT INTO R_TXT
      (IDENTIFIER,TXT,SEQNO,USER_ID,MENU_NAME
      )
select '23' AS IDENTIFIER,'VD510.H.'||TRIM(MKBD_CD)||'|'||
								   TRIM(TO_CHAR(TGL_KOMITMEN,'DD/MM/YYYY'))||'|'||
								  TRIM(RINCIAN)||'|'||
								  TRIM(TO_CHAR(TGL_REALISASI,'DD/MM/YYYY'))||'|'||
								  TRIM(TO_CHAR(SUDAH_REAL,'9999999999999999990.99'))||'|'||
								  TRIM(TO_CHAR(BELUM_REAL,'9999999999999999990.99'))||'|'||
								  TRIM(TO_CHAR(RANKING,'9999999999999999990.99'))||'||||'
								  as text_vd510h, ROWNUM AS SEQNO, P_USER_ID, P_MENU_NAME
								  FROM insistpro_rpt.LAP_MKBD_VD510H Where approved_stat='A' 
							  	AND update_seq     = P_UPDATE_SEQ
                AND update_date    = P_UPDATE_DATE;
  EXCEPTION
  WHEN NO_DATA_FOUND THEN
    NULL;
  WHEN OTHERS THEN
    V_ERROR_CD  := -180;
    V_ERROR_MSG := SUBSTR('INSERT INTO R_TXT VD510H'|| SQLERRM(SQLCODE),1,200);
    RAISE V_ERR;
  END;
  
  
  --VD510I
  BEGIN
    INSERT INTO R_TXT
      (IDENTIFIER,TXT,SEQNO,USER_ID,MENU_NAME
      )
select '24' AS IDENTIFIER, 'VD510.I.'||TRIM(MKBD_CD)||'|'||
								   TRIM(JENIS_TRX)||'|'||
								   TRIM(TO_CHAR(TGL_TRX,'DD/MM/YYYY'))||'|'||
								  TRIM(CURRENCY_TYPE)||'|'||
								  TRIM(TO_CHAR(NILAI_RPH,'9999999999999999990.99'))||'|'||
								  TRIM(TO_CHAR(UNTUNG_RUGI,'9999999999999999990.99'))||'|'||
								  TRIM(TO_CHAR(RANKING,'9999999999999999990.99'))||'||||'
								  as text_vd510i, ROWNUM AS SEQNO, P_USER_ID, P_MENU_NAME
								  FROM insistpro_rpt.LAP_MKBD_VD510I Where approved_stat='A' 
							    AND update_seq     = P_UPDATE_SEQ
                AND update_date    = P_UPDATE_DATE;
  EXCEPTION
  WHEN NO_DATA_FOUND THEN
    NULL;
  WHEN OTHERS THEN
    V_ERROR_CD  := -190;
    V_ERROR_MSG := SUBSTR('INSERT INTO R_TXT VD510I'|| SQLERRM(SQLCODE),1,200);
    RAISE V_ERR;
  END;
  
  P_ERROR_CD  := 1 ;
  P_ERROR_MSG := '';
EXCEPTION
WHEN V_ERR THEN
  ROLLBACK;
  P_ERROR_MSG := V_ERROR_MSG;
  P_ERROR_CD  := V_ERROR_CD;
WHEN OTHERS THEN
  P_ERROR_CD  := -1 ;
  P_ERROR_MSG := SUBSTR(SQLERRM(SQLCODE),1,200);
  RAISE;
END SP_GET_TXT_MKBD;