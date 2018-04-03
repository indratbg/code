create or replace PROCEDURE SP_TMP_TRX_SAHAM_SEKUNDER(
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
  
  BEGIN
  
    BEGIN
    INSERT INTO TMP_TRX_NSB_SEKUNDER(SEMESTER,GRP_1,GRP_2,GRP_3,NO_URUT,TRX_VALUE,RAND_VALUE,USER_ID)
     SELECT SEMESTER,GRP_1,GRP_2,GRP_3,NO_URUT,TRX_VAL,P_RANDOM_VALUE,P_USER_ID
     FROM
     (
        --BERDASARKAN JENIS INVESTOR PERSEORANGAN.KORPORASI/PERIKATAN LAINNYA
        select decode(sign(to_number(to_char(contr_dt,'mm')) - 6), 1, 2, 1) semester,
        1 grp_1, decode(b.client_type_1,'I',1,'C',2,'H',3) GRP_2, 0 GRP_3,
        DECODE(client_type_2,'L',1,2) no_urut,
        sum(val) trx_val
        from t_contracts a, mst_client b
        where a.client_cd = b.client_cd(+)
        and a.contr_stat <> 'C'
        and a.contr_dt BETWEEN P_BGN_YEAR AND P_END_YEAR
        group by decode(sign(to_number(to_char(contr_dt,'mm')) - 6), 1, 2, 1), b.client_type_1, b.client_type_2

        UNION ALL
        -- BERDASARKAN JENIS PEKERJAAN (BAGIAN PERSEORANGAN)
        SELECT SEMESTER, GRP_1,GRP_2,GRP_3,NO_URUT, SUM(TRX_VAL)TRX_VAL 
        FROM 
        (
        select decode(sign(to_number(to_char(contr_dt,'mm')) - 6), 1, 2, 1) semester,
        2 GRP_1, 1 GRP_2, DECODE(PRM_CD_2,'21',1,'90',1,0) GRP_3, 
          DECODE(PRM_CD_2,'06',1,'05',2,'02',3,'04',4,'03',5,'07',6,'21',DECODE(CLIENT_TYPE_2,'L',1,2),'90',12,12) NO_URUT,
        val trx_val
        from t_contracts a, mst_client b, mst_client_indi c,
        (select PRM_CD_2 from mst_parameter where prm_cd_1 = 'WORK') d
        where a.client_cd = b.client_cd(+)
        and b.cifs = c.cifs(+)
        and c.occup_code = d.prm_cd_2(+)
        and a.contr_stat <> 'C'
        and a.contr_dt BETWEEN P_BGN_YEAR AND P_END_YEAR
        and b.client_type_1 = 'I'
        )GROUP BY SEMESTER, GRP_1,GRP_2,GRP_3,NO_URUT
        UNION ALL
        --BERDASARKAN JENIS PEKERJAAN (BAGIAN PERUSAHAAN DAN PERIKATAN LAINNYA)
        SELECT SEMESTER,GRP_1,GRP_2,GRP_3,NO_URUT,SUM(TRX_VAL) TRX_VAL
        FROM
        (
        select decode(sign(to_number(to_char(contr_dt,'mm')) - 6), 1, 2, 1) semester,
        2 grp_1, DECODE(B.CLIENT_TYPE_1,'C',2,3) grp_2,0 GRP_3,
        DECODE(PRM_CD_2,'IB',1,'FD',2,'CP',3,4)no_urut, 
        val trx_val
        from t_contracts a, mst_client b, mst_cif c,
        (select * from mst_parameter where prm_cd_1 = 'BIZTYP') d
        where a.client_cd = b.client_cd(+)
        and b.cifs = c.cifs(+)
        and nvl(c.biz_type,'OT') = d.prm_cd_2(+)
        and a.contr_stat <> 'C'
        and a.contr_dt BETWEEN P_BGN_YEAR AND P_END_YEAR
        and b.client_type_1 in ('C','H')
        )
        GROUP BY SEMESTER,GRP_1,GRP_2,GRP_3,NO_URUT
        UNION ALL

        --BERDASARKAN AREA GEOGRAFIS
        SELECT SEMESTER,GRP_1,GRP_2,GRP_3,NO_URUT, SUM(TRX_VAL)TRX_VAL
        FROM
        (
        select decode(sign(to_number(to_char(contr_dt,'mm')) - 6), 1, 2, 1) semester,
        3 GRP_1, DECODE(B.CLIENT_TYPE_1,'I',1,2) GRP_2,0 GRP_3,
        DECODE(SUBSTR(UPPER(C.DEF_CITY),1,7),'JAKARTA',1,2 )NO_URUT,
        val trx_val
        from t_contracts a, mst_client b, mst_cif c
        where a.client_cd = b.client_cd(+)
        and b.cifs = c.cifs(+)
        and a.contr_stat <> 'C'
        and a.contr_dt BETWEEN P_BGN_YEAR AND P_END_YEAR
        )
        GROUP BY SEMESTER,GRP_1,GRP_2,GRP_3,NO_URUT
        );
        EXCEPTION
      WHEN OTHERS THEN
        V_ERROR_CODE :=-32;
        V_ERROR_MSG :=SUBSTR('INSERT INTO TMP_TRX_NSB_SEKUNDER'||SQLERRM,1,200);
        RAISE V_ERR;
      END;


    BEGIN
        UPDATE R_TRX_NSB_PER_KATEGORI R
        SET PERD_SAHAM=(SELECT TRX_VALUE FROM TMP_TRX_NSB_SEKUNDER TMP WHERE RAND_VALUE=P_RANDOM_VALUE AND USER_ID=P_USER_ID
          AND TMP.SEMESTER= R.SEMESTER 
          AND TMP.GRP_1=R.GRP_1
          AND TMP.GRP_2 =R.GRP_2
          AND TMP.GRP_3=R.GRP_3
          AND TMP.NO_URUT = R.NO_URUT)
        WHERE EXISTS(SELECT 1 FROM TMP_TRX_NSB_SEKUNDER TMP WHERE RAND_VALUE=P_RANDOM_VALUE AND USER_ID=P_USER_ID
          AND TMP.SEMESTER= R.SEMESTER 
          AND TMP.GRP_1=R.GRP_1
          AND TMP.GRP_2 =R.GRP_2
          AND TMP.GRP_3=R.GRP_3
          AND TMP.NO_URUT = R.NO_URUT);
      EXCEPTION
      WHEN OTHERS THEN
        V_ERROR_CODE :=-34;
        V_ERROR_MSG  :=SUBSTR('UPDATE R_TRX_NSB_PER_KATEGORI SAHAM SEKUNDER'||SQLERRM,1,200);
        RAISE V_ERR;
      END;
     

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
  END SP_TMP_TRX_SAHAM_SEKUNDER;