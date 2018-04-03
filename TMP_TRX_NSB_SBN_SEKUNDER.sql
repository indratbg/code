create or replace PROCEDURE SP_TMP_TRX_SBN_SEKUNDER_YJ(
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
        INSERT INTO TMP_TRX_NSB_SBN_SEKUNDER(SEMESTER,GRP_1,GRP_2,GRP_3,NO_URUT,TRX_VALUE,RAND_VALUE,USER_ID)
        SELECT SEMESTER,GRP_1,GRP_2,GRP_3,NO_URUT,trx_val, P_RANDOM_VALUE,P_USER_ID
        FROM
        (
          --BERDASARKAN JENIS INVESTOR
            SELECT DECODE(SIGN(to_number(TO_CHAR(trx_date,'mm')) - 6), 1, 2, 1) semester, 1 grp_1, 
            DECODE(b.client_type_1,'I',1,'C',2,'H',3) GRP_2, 0 GRP_3, DECODE(b.client_type_2,'L',1,2) no_urut, 
            SUM(cost) trx_val
            FROM
              (
                SELECT x.trx_date, x.approved_sts, x.lawan, x.lawan_type, x.bond_cd, x.cost, x.net_amount, y.sl_acct_cd
                FROM t_bond_trx x, mst_lawan_bond_trx y
                WHERE x.lawan      = y.lawan
                AND x.approved_sts = 'A'
                AND x.trx_date   BETWEEN P_BGN_YEAR AND P_END_YEAR
              )
              a, (
                SELECT CLIENT_CD,CLIENT_TYPE_1,CLIENT_TYPE_2
                FROM mst_client
                WHERE client_type_1 <> 'B'
              )
              b, mst_bond e
            WHERE a.sl_acct_cd  = b.client_cd
            AND a.bond_cd       = e.bond_cd
            AND e.bond_group_cd = '03'
            GROUP BY DECODE(SIGN(to_number(TO_CHAR(trx_date,'mm')) - 6), 1, 2, 1), b.client_type_1, b.client_type_2
            UNION ALL
            --BERDASARKAN JENIS PEKERJAAN
            --BAGIAN PERORANGAN
            SELECT SEMESTER,GRP_1,GRP_2,GRP_3,NO_URUT, SUM(TRX_VAL)TRX_VAL
            FROM(
                  select decode(sign(to_number(to_char(trx_date,'mm')) - 6), 1, 2, 1) semester,
                   2 GRP_1, 1 GRP_2, 0 GRP_3,
                    DECODE(PRM_CD_2,'01',1,'02',2,'03',3,'04',4,'05',5,'06',6,'07',7,'08',DECODE(CLIENT_TYPE_2,'L',10,11),'09',9,90) NO_URUT,
                  cost trx_val
                  from 
                  (
                    select x.trx_date, x.approved_sts, x.lawan, x.lawan_type, x.bond_cd, x.cost, x.net_amount, y.sl_acct_cd
                    from t_bond_trx x, mst_lawan_bond_trx y 
                    where x.lawan = y.lawan 
                    and x.approved_sts = 'A'
                    and x.trx_date BETWEEN P_BGN_YEAR AND P_END_YEAR
                  ) a, 
                  (
                    select CLIENT_CD,CIFS,CLIENT_TYPE_1,CLIENT_TYPE_2 from mst_client where client_type_1 <> 'B'
                  ) b, 
                  mst_client_indi c, 
                  (select PRM_CD_2 from mst_parameter where prm_cd_1 = 'WORK') d,
                  mst_bond e
                  where a.sl_acct_cd = b.client_cd
                  and b.cifs = c.cifs(+)
                  and c.occup_code = d.prm_cd_2(+)
                  and a.bond_cd = e.bond_cd
                  and b.client_type_1 = 'I'
                  and e.bond_group_cd = '03'
            )
            group by SEMESTER,GRP_1,GRP_2,GRP_3,NO_URUT

            UNION ALL
            --BAGIAN KORPORASI
            SELECT SEMESTER,GRP_1,GRP_2,GRP_3,NO_URUT,SUM(TRX_VAL)TRX_VAL
            FROM(
                  select decode(sign(to_number(to_char(trx_date,'mm')) - 6), 1, 2, 1) semester,
                   2 grp_1, DECODE(B.CLIENT_TYPE_1,'C',2,3) grp_2,0 GRP_3,
                          DECODE(PRM_CD_2,'IB',1,'FD',2,'CP',3, DECODE(B.CLIENT_TYPE_1,'C',4,1))no_urut, 
                  cost trx_val
                  from 
                  (
                    select x.trx_date, x.approved_sts, x.lawan, x.lawan_type, x.bond_cd, x.cost, x.net_amount, y.sl_acct_cd
                    from t_bond_trx x, mst_lawan_bond_trx y 
                    where x.lawan = y.lawan 
                    and x.approved_sts = 'A'
                    and x.trx_date BETWEEN P_BGN_YEAR AND P_END_YEAR
                  ) a, 
                  (
                    select  CLIENT_CD,CIFS,CLIENT_TYPE_1,CLIENT_TYPE_2 from mst_client where client_type_1 <> 'B'
                  ) b, 
                  mst_cif c, 
                  (select PRM_cD_2 from mst_parameter where prm_cd_1 = 'BIZTYP') d,
                  mst_bond e
                  where a.sl_acct_cd = b.client_cd
                  and b.cifs = c.cifs(+)
                  and nvl(c.biz_type,'OT') = d.prm_cd_2(+)
                  and a.bond_cd = e.bond_cd
                  and b.client_type_1 in ('C','H')
                  and e.bond_group_cd = '03'
            )
            group by  SEMESTER,GRP_1,GRP_2,GRP_3,NO_URUT
            UNION ALL
             --BERDASARKAN AREA GEOGRAFIS
            SELECT SEMESTER,GRP_1,GRP_2,GRP_3,NO_URUT,SUM(TRX_VAL)TRX_VAL
            FROM
            (
            select decode(sign(to_number(to_char(trx_date,'mm')) - 6), 1, 2, 1) semester,
              3 GRP_1, DECODE(B.CLIENT_TYPE_1,'I',1,2) GRP_2,0 GRP_3,
                    DECODE(SUBSTR(UPPER(C.DEF_CITY),1,7),'JAKARTA',1,2 )NO_URUT,
            cost trx_val
            from 
            (
              select x.trx_date, x.approved_sts, x.lawan, x.lawan_type, x.bond_cd, x.cost, x.net_amount, y.sl_acct_cd
              from t_bond_trx x, mst_lawan_bond_trx y 
              where x.lawan = y.lawan 
              and x.approved_sts = 'A'
              and x.trx_date >= '01jan2017'
              and x.trx_date <= '31dec2017'
            ) a, 
            (
              select CLIENT_CD,CIFS,CLIENT_TYPE_1,CLIENT_TYPE_2 from mst_client where client_type_1 <> 'B'
            ) b, 
            mst_cif c,
            mst_bond e
            where a.sl_acct_cd = b.client_cd
            and b.cifs = c.cifs(+)
            and a.bond_cd = e.bond_cd
            and e.bond_group_cd = '03'
            )
            group by SEMESTER,GRP_1,GRP_2,GRP_3,NO_URUT

        ) ;
        EXCEPTION
      WHEN OTHERS THEN
        V_ERROR_CODE :=-32;
        V_ERROR_MSG :=SUBSTR('INSERT INTO TMP_TRX_NSB_SBN_SEKUNDER'||SQLERRM,1,200);
        RAISE V_ERR;
      END;


    BEGIN
        UPDATE R_TRX_NSB_PER_KATEGORI R
        SET SEKU_OBLIGASI_KORP=(SELECT TRX_VALUE FROM TMP_TRX_NSB_SBN_SEKUNDER TMP WHERE RAND_VALUE=P_RANDOM_VALUE AND USER_ID=P_USER_ID
          AND TMP.SEMESTER= R.SEMESTER 
          AND TMP.GRP_1=R.GRP_1
          AND TMP.GRP_2 =R.GRP_2
          AND TMP.GRP_3=R.GRP_3
          AND TMP.NO_URUT = R.NO_URUT)
        WHERE EXISTS(SELECT 1 FROM TMP_TRX_NSB_SBN_SEKUNDER TMP WHERE RAND_VALUE=P_RANDOM_VALUE AND USER_ID=P_USER_ID
          AND TMP.SEMESTER= R.SEMESTER 
          AND TMP.GRP_1=R.GRP_1
          AND TMP.GRP_2 =R.GRP_2
          AND TMP.GRP_3=R.GRP_3
          AND TMP.NO_URUT = R.NO_URUT);
      EXCEPTION
      WHEN OTHERS THEN
        V_ERROR_CODE :=-34;
        V_ERROR_MSG  :=SUBSTR('UPDATE R_TRX_NSB_PER_KATEGORI SAHAM PERDANA'||SQLERRM,1,200);
        RAISE V_ERR;
      END;
     
      --DELETE TABLE TEMPORARY
    BEGIN
    DELETE FROM TMP_TRX_NSB_SBN_SEKUNDER WHERE RAND_VALUE=P_RANDOM_VALUE AND USER_ID=P_USER_ID;
     EXCEPTION
      WHEN OTHERS THEN
        V_ERROR_CODE :=-40;
        V_ERROR_MSG  :=SUBSTR('DELETE FROM TMP_TRX_NSB_SBN_SEKUNDER WHERE RAND_VALUE=P_RANDOM_VALUE'||SQLERRM,1,200);
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
  END SP_TMP_TRX_SBN_SEKUNDER_YJ;