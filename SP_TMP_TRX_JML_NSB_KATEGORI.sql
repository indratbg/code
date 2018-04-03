CREATE OR REPLACE PROCEDURE SP_TMP_TRX_JML_NSB_KATEGORI(
    P_BGN_YEAR     DATE,
    P_END_YEAR     DATE,
    P_USER_ID      VARCHAR2,
    P_RANDOM_VALUE NUMBER,
    P_ERROR_CD OUT NUMBER,
    P_ERROR_MSG OUT VARCHAR2 )
IS
  V_ERR          EXCEPTION;
  V_ERROR_CODE   NUMBER;
  V_ERROR_MSG    VARCHAR2(200);
  V_RANDOM_VALUE NUMBER;
  
  CURSOR CSR_SAHAM_PERDANA
  IS
    --BERDASARKAN JENIS INVESTOR PERSEORANGAN/KORPORASI
    SELECT SEMESTER,1 GRP_1,DECODE(CLIENT_TYPE_1,'I',1,'C',2,3) GRP_2, 0 GRP_3,
    DECODE(client_type_2,'L',1,2) no_urut, COUNT(*) client_cnt
    FROM
      (
        SELECT DISTINCT DECODE(SIGN(to_number(TO_CHAR(doc_dt,'mm')) - 6), 1, 2, 1) semester,
        a.client_cd, b.client_type_1, b.client_type_2
        FROM t_stk_movement a, mst_client b
        WHERE a.client_cd = b.client_cd(+)
        AND a.doc_stat    = 2
        AND a.seqno       = 1
        AND upper(a.doc_rem) LIKE '%IPO %'
        AND a.doc_dt BETWEEN P_BGN_YEAR AND P_END_YEAR
      UNION
      SELECT DISTINCT DECODE(SIGN(to_number(TO_CHAR(contr_dt,'mm')) - 6), 1, 2, 1) semester, 
      a.client_cd, b.client_type_1, b.client_type_2
      FROM t_contracts a, mst_client b
      WHERE a.client_cd = b.client_cd(+)
      AND a.contr_stat <> 'C'
      AND a.contr_dt BETWEEN P_BGN_YEAR AND P_END_YEAR
      )
    GROUP BY semester, client_Type_1, client_Type_2
    UNION ALL
    --berdasarkan jenis pekerjaan
    --PERDANA perorangan
    SELECT SEMESTER, GRP_1, GRP_2, GRP_3,NO_URUT, COUNT(CLIENT_CD) client_cnt
    FROM
      (
        SELECT DISTINCT DECODE(SIGN(TO_NUMBER(TO_CHAR(DOC_DT,'mm')) - 6), 1, 2, 1) SEMESTER, 
        2 GRP_1,1 GRP_2,DECODE(PRM_CD_2,'21',1,0) GRP_3, DECODE(PRM_CD_2,'06',1,'05',2,'02',3,'04',4,'03',5,'07',6,'21',DECODE(CLIENT_TYPE_2,'L',1,2),'90',12,12) NO_URUT, B.CLIENT_CD
        FROM T_STK_MOVEMENT a, MST_CLIENT B, MST_CLIENT_INDI C, (
            SELECT PRM_CD_2,PRM_DESC FROM mst_parameter WHERE prm_cd_1 = 'WORK'
          )
          d
        WHERE a.client_cd = b.client_cd(+)
        AND b.cifs        = c.cifs(+)
        AND c.occup_code  = d.prm_cd_2(+)
        AND a.doc_stat    = 2
        AND a.seqno       = 1
        AND UPPER(a.DOC_REM) LIKE '%IPO %'
        AND a.doc_dt BETWEEN P_BGN_YEAR AND P_END_YEAR
        AND b.client_type_1 = 'I'
        UNION
        --PASAR PERDANA korporasi
        SELECT DISTINCT DECODE(SIGN(TO_NUMBER(TO_CHAR(DOC_DT,'mm')) - 6), 1, 2, 1) SEMESTER, 
        2 GRP_1, 2 GRP_2,0 GRP_3,3 NO_URUT, b.client_cd
        FROM t_stk_movement a, mst_client b, mst_cif c, (
            SELECT * FROM mst_parameter WHERE prm_cd_1 = 'BIZTYP'
          )
          d
        WHERE a.client_cd        = b.client_cd(+)
        AND b.cifs               = c.cifs(+)
        AND NVL(c.biz_type,'OT') = d.prm_cd_2(+)
        AND a.doc_stat           = 2
        AND a.seqno              = 1
        AND upper(a.doc_rem) LIKE '%IPO %'
        AND a.doc_dt BETWEEN P_BGN_YEAR AND P_END_YEAR
        AND b.client_type_1 IN ('C','H')
        UNION
        -- SEKUNDER BERDASARKAN PEKERJAAN PERORANGAN
        SELECT DISTINCT DECODE(SIGN(TO_NUMBER(TO_CHAR(CONTR_DT,'mm')) - 6), 1, 2, 1) SEMESTER, 
        2 GRP_1,1 GRP_2,DECODE(PRM_CD_2,'21',1,0) GRP_3, DECODE(PRM_CD_2,'06',1,'05',2,'02',3,'04',4,'03',5,'07',6,'21',DECODE(CLIENT_TYPE_2,'L',1,2),'90',12,12) NO_URUT, B.CLIENT_CD
        FROM t_contracts a, mst_client b, mst_client_indi c, (
            SELECT * FROM mst_parameter WHERE prm_cd_1 = 'WORK'
          )
          d
        WHERE a.client_cd = b.client_cd(+)
        AND b.cifs        = c.cifs(+)
        AND c.occup_code  = d.prm_cd_2(+)
        AND a.contr_stat <> 'C'
        AND a.contr_dt BETWEEN P_BGN_YEAR AND P_END_YEAR
        AND b.client_type_1 = 'I'
        UNION
        --SEKUNDER KORPORASI
        SELECT DISTINCT DECODE(SIGN(TO_NUMBER(TO_CHAR(CONTR_DT,'mm')) - 6), 1, 2, 1) SEMESTER,
        2 GRP_1, 2 GRP_2,0 GRP_3,3 NO_URUT, b.client_cd
        FROM t_contracts a, mst_client b, mst_cif c, (
            SELECT * FROM mst_parameter WHERE prm_cd_1 = 'BIZTYP'
          )
          d
        WHERE a.client_cd        = b.client_cd(+)
        AND b.cifs               = c.cifs(+)
        AND NVL(c.biz_type,'OT') = d.prm_cd_2(+)
        AND a.contr_stat        <> 'C'
        AND a.contr_dt BETWEEN P_BGN_YEAR AND P_END_YEAR
        AND b.client_type_1 IN ('C','H')
      )
    GROUP BY SEMESTER, GRP_1, GRP_2, GRP_3,NO_URUT
    UNION ALL
    --BERDASARKAN AREA GEOGRAFIS
    --PERDANA
    SELECT SEMESTER, GRP_1,GRP_2,GRP_3,NO_URUT,COUNT(CLIENT_CD) CLIENT_CNT
    FROM
      (
        SELECT DISTINCT DECODE(SIGN(TO_NUMBER(TO_CHAR(DOC_DT,'mm')) - 6), 1, 2, 1) SEMESTER,
        3 GRP_1, DECODE(B.CLIENT_TYPE_1,'I',1,'C',2,'H',2) GRP_2, 0 GRP_3,
        DECODE(SUBSTR(UPPER(C.DEF_CITY),1,7),'JAKARTA',1,2 )NO_URUT, B.CLIENT_CD
        FROM t_stk_movement a, mst_client b, mst_cif c
        WHERE a.client_cd = b.client_cd(+)
        AND b.cifs        = c.cifs(+)
        AND a.doc_stat    = 2
        AND a.seqno       = 1
        AND upper(a.doc_rem) LIKE '%IPO %'
        AND a.doc_dt BETWEEN P_BGN_YEAR AND P_END_YEAR
        UNION
        SELECT DISTINCT DECODE(SIGN(TO_NUMBER(TO_CHAR(CONTR_DT,'mm')) - 6), 1, 2, 1) SEMESTER,
        3 GRP_1, DECODE(B.CLIENT_TYPE_1,'I',1,'C',2,'H',2) GRP_2, 0 GRP_3, 
        DECODE(SUBSTR(UPPER(C.DEF_CITY),1,7),'JAKARTA',1,2 )NO_URUT, B.CLIENT_CD
        FROM t_contracts a, mst_client b, mst_cif c
        WHERE a.client_cd = b.client_cd(+)
        AND b.cifs        = c.cifs(+)
        AND a.contr_stat <> 'C'
        AND a.contr_dt BETWEEN P_BGN_YEAR AND P_END_YEAR
      )
    GROUP BY SEMESTER, GRP_1,GRP_2,GRP_3,NO_URUT;
  BEGIN
  
    FOR REC IN CSR_SAHAM_PERDANA LOOP
    
      BEGIN
        UPDATE R_TRX_NSB_PER_KATEGORI
        SET JML_NASABAH=REC.client_cnt
        WHERE GRP_1    =REC.GRP_1
        AND GRP_2      =REC.GRP_2
        AND GRP_3      =REC.GRP_3
        AND NO_URUT    =REC.NO_URUT
        AND SEMESTER   =REC.SEMESTER;
      EXCEPTION
      WHEN OTHERS THEN
        V_ERROR_CODE :=-29;
        V_ERROR_MSG  :=SUBSTR('UPDATE R_TRX_NSB_PER_KATEGORI JUMLAH NASABAH PER KATEGORI'||SQLERRM,1,200);
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
  END SP_TMP_TRX_JML_NSB_KATEGORI;