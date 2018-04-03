create or replace PROCEDURE SP_TMP_TRX_SAHAM_PERDANA(
  P_BGN_YEAR DATE,
  P_END_YEAR DATE,
    P_USER_ID    VARCHAR2,
    P_RANDOM_VALUE NUMBER,
    P_ERROR_CD OUT NUMBER,
    P_ERROR_MSG OUT VARCHAR2 )
  IS
  V_ERR          EXCEPTION;
  V_ERROR_CODE   NUMBER;
  V_ERROR_MSG    VARCHAR2(200);
  V_RANDOM_VALUE NUMBER; 


    CURSOR CSR_SAHAM_PERDANA IS
    --PERDANA
    --berdasarkan jenis investor local/korporasi/perikatan lainnya
    SELECT semester,1 GRP_1, DECODE(client_type_1,'I',1,'C',2,3) grp_2, 0 grp_3, 
    DECODE(client_type_2,'L',1,2) no_urut, IPO_VALUE
    FROM
      (
        SELECT DECODE(SIGN(to_number(TO_CHAR(doc_dt,'mm')) - 6), 1, 2, 1) semester, b.client_type_1, b.client_type_2,
        SUM(a.total_share_qty * NVL(a.price,0)) ipo_value
        FROM t_stk_movement a, mst_client b
        WHERE a.client_cd = b.client_cd(+)
        AND a.doc_stat    = 2
        AND a.seqno       = 1
        AND upper(a.doc_rem) LIKE '%IPO %'
        AND a.doc_dt BETWEEN P_BGN_YEAR AND P_END_YEAR
        GROUP BY DECODE(SIGN(to_number(TO_CHAR(doc_dt,'mm')) - 6), 1, 2, 1), b.client_type_1, b.client_type_2
      )
    UNION ALL
    --BERSASRKAN JENIS PEKERJAAN PERORANGAN
    SELECT SEMESTER, 2 GRP_1, 1 GRP_2, DECODE(PRM_CD_2,'21',1,0) GRP_3, 
    DECODE(PRM_CD_2,'06',1,'05',2,'02',3,'04',4,'03',5,'07',6,'21',DECODE(CLIENT_TYPE_2,'L',1,2),'90',12,12) NO_URUT, IPO_VALUE
    FROM
      (
        SELECT DECODE(SIGN(TO_NUMBER(TO_CHAR(DOC_DT,'mm')) - 6), 1, 2, 1) SEMESTER,B.CLIENT_TYPE_1,
        CLIENT_TYPE_2, D.PRM_CD_2, SUM(a.TOTAL_SHARE_QTY * NVL(a.PRICE,0)) IPO_VALUE
        FROM T_STK_MOVEMENT a, MST_CLIENT B, MST_CLIENT_INDI C, (
            SELECT PRM_CD_2,PRM_DESC FROM MST_PARAMETER WHERE PRM_CD_1 = 'WORK'
          )
          D
        WHERE a.CLIENT_CD = B.CLIENT_CD(+)
        AND B.CIFS        = C.CIFS(+)
        AND C.OCCUP_CODE  = D.PRM_CD_2(+)
        AND a.DOC_STAT    = 2
        AND a.SEQNO       = 1
        AND UPPER(a.DOC_REM) LIKE '%IPO %'
        AND a.DOC_DT BETWEEN P_BGN_YEAR AND P_END_YEAR
        AND B.CLIENT_TYPE_1 = 'I'
        GROUP BY DECODE(SIGN(TO_NUMBER(TO_CHAR(DOC_DT,'mm')) - 6), 1, 2, 1), B.CLIENT_TYPE_1,CLIENT_TYPE_2,D.PRM_CD_2
      )
    UNION ALL
    --PERDANA BERDASARKAN JENIS PEKERJAAN BAGIAN PERUSAHAAN
    SELECT  semester,2 grp_1, 2 grp_2,0 GRP_3,3 no_urut, IPO_VALUE
    FROM
      (
        SELECT DECODE(SIGN(to_number(TO_CHAR(doc_dt,'mm')) - 6), 1, 2, 1) semester, b.client_type_1, 
        d.prm_desc biz_type,PRM_CD_2, SUM(a.total_share_qty * NVL(a.price,0)) ipo_value
        FROM t_stk_movement a, mst_client b, mst_cif c, (
            SELECT PRM_CD_2,PRM_DESC FROM mst_parameter WHERE prm_cd_1 = 'BIZTYP'
          )
          d
        WHERE a.client_cd        = b.client_cd(+)
        AND b.cifs               = c.cifs(+)
        AND NVL(c.biz_type,'OT') = d.prm_cd_2(+)
        AND a.doc_stat           = 2
        AND a.seqno              = 1
        AND upper(a.doc_rem) LIKE '%IPO %'
        AND a.doc_dt BETWEEN P_BGN_YEAR AND P_END_YEAR
        AND b.client_type_1                                 IN ('C','H')
        GROUP BY DECODE(SIGN(to_number(TO_CHAR(doc_dt,'mm')) - 6), 1, 2, 1), b.client_type_1, d.prm_desc,D.PRM_CD_2
      )
    UNION ALL
    --BERDASARKAN ARREA GEOGRAFIS
    SELECT DECODE(SIGN(TO_NUMBER(TO_CHAR(DOC_DT,'mm')) - 6), 1, 2, 1) SEMESTER,3 GRP_1,
    DECODE(B.CLIENT_TYPE_1,'I',1,2) GRP_2,0 GRP_3, DECODE(SUBSTR(UPPER(C.DEF_CITY),1,7),'JAKARTA',1,2 )NO_URUT,
    SUM(a.total_share_qty * NVL(a.price,0)) ipo_value
    FROM t_stk_movement a, mst_client b, mst_cif c
    WHERE a.client_cd = b.client_cd(+)
    AND b.cifs        = c.cifs(+)
    AND a.doc_stat    = 2
    AND a.seqno       = 1
    AND UPPER(a.DOC_REM) LIKE '%IPO %'
    AND a.DOC_DT BETWEEN P_BGN_YEAR AND P_END_YEAR
    GROUP BY DECODE(SIGN(TO_NUMBER(TO_CHAR(DOC_DT,'mm')) - 6), 1, 2, 1), B.CLIENT_TYPE_1 ,
    DECODE(SUBSTR(UPPER(C.DEF_CITY),1,7),'JAKARTA',1,2 );

  BEGIN
  

FOR REC IN CSR_SAHAM_PERDANA LOOP

BEGIN
  UPDATE R_TRX_NSB_PER_KATEGORI SET PERD_SAHAM=REC.IPO_VALUE 
  WHERE GRP_1=REC.GRP_1 
  AND GRP_2=REC.GRP_2
  AND GRP_3=REC.GRP_3 
  AND NO_URUT=REC.NO_URUT
  AND SEMESTER=REC.SEMESTER;
  EXCEPTION
  WHEN OTHERS THEN
    V_ERROR_CODE :=-29;
    V_ERROR_MSG :=SUBSTR('UPDATE R_TRX_NSB_PER_KATEGORI SAHAM PERDANA'||SQLERRM,1,200);
    RAISE V_ERR;
  END;
  
END LOOP;
    P_ERROR_CD  :=1;
    P_ERROR_MSG :='';
  EXCEPTION
  WHEN V_ERR THEN
    ROLLBACK;
    P_ERROR_CD  := V_ERROR_CODE;
    P_ERROR_MSG := V_ERROR_MSG;
  WHEN OTHERS THEN
    P_ERROR_CD  :=-1;
    P_ERROR_MSG :=SUBSTR(SQLCODE||' '||SQLERRM,1,200);
    RAISE;
  END SP_TMP_TRX_SAHAM_PERDANA;