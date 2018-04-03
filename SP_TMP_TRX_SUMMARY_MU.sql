create or replace PROCEDURE SP_TMP_TRX_SUMMARY_MU(
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
    SP_RPT_REMOVE_RAND('R_TRX_NSB_SUMMARY',P_RANDOM_VALUE,V_ERROR_CODE,V_ERROR_MSG);
  EXCEPTION
  WHEN OTHERS THEN
    V_ERROR_CODE  := -2;
    V_ERROR_MSG := SUBSTR('SP_RPT_REMOVE_RAND '||SQLERRM(SQLCODE),1,200);
    RAISE V_err;
  END;
  
  IF V_ERROR_CODE<0 THEN
    V_ERROR_CODE  := -15;
    V_ERROR_MSG := 'CALL SP_RPT_REMOVE_RAND '||V_ERROR_MSG;
    RAISE V_err;
  END IF;


    BEGIN
      INSERT INTO R_TRX_NSB_SUMMARY(SEMESTER,NO_URUT,KETERANGAN,TRX_VALUE,RAND_VALUE,USER_ID)
      select semester,norut,decode(category,'Y','Transaksi Melalui Online Trading','Transaksi Melalui Remote Trading')category,
      TRX_VAL,P_RANDOM_VALUE,P_USER_ID
      FROM
          (
          select decode(sign(to_number(to_char(contr_dt,'mm')) - 6), 1, 2, 1) semester,5 norut,
          nvl(a.can_amd_flg,'N') category,
          --decode(nvl(a.can_amd_flg,'N'),'Y','Transaksi Melalui Online Trading','Transaksi Melalui Remote Trading') category,
          sum(val) trx_val
          from t_contracts a
          where a.contr_stat <> 'C'
          and a.contr_dt between P_BGN_YEAR AND P_END_YEAR
          group by decode(sign(to_number(to_char(contr_dt,'mm')) - 6), 1, 2, 1), nvl(a.can_amd_flg,'N')
          --decode(nvl(a.can_amd_flg,'N'),'Y','OLT','NON OLT')
          )
      UNION ALL
      SELECT 1 SEMESTER, 1 norut, 'Transaksi di Pasar Perdana' category,PERD_SAHAM,P_RANDOM_VALUE,P_USER_ID
      FROM R_TRX_NSB_PER_KATEGORI
      where RAND_VALUE=P_RANDOM_VALUE AND USER_ID=P_USER_ID
      AND TXT='TOTAL' AND GRP_1=1 AND GRP_2=99 AND GRP_3=99 AND SEMESTER=1
      UNION ALL
      SELECT 2 SEMESTER,1 norut, 'Transaksi di Pasar Perdana' category, seku_saham, P_RANDOM_VALUE,P_USER_ID
      FROM R_TRX_NSB_PER_KATEGORI
      where RAND_VALUE=P_RANDOM_VALUE AND USER_ID=P_USER_ID
      AND TXT='TOTAL' AND GRP_1=1 AND GRP_2=99 AND GRP_3=99 AND SEMESTER=1;
    EXCEPTION
    WHEN OTHERS THEN
        V_ERROR_CODE :=-32;
        V_ERROR_MSG :=SUBSTR('INSERT INTO R_TRX_NSB_SUMMARY'||SQLERRM,1,200);
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
  END SP_TMP_TRX_SUMMARY_MU;