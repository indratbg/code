create or replace PROCEDURE SPR_GENERATE_OTC_FEE(
    P_BGN_DT            DATE,
    P_END_DT            DATE,
    P_OTC_FEE           NUMBER,
    P_GL_OTC_CLIENT     VARCHAR2,
    P_SL_OTC_CLIENT     VARCHAR2,
    P_GL_OTC_CLIENT_NON VARCHAR2,
    P_SL_OTC_CLIENT_NON VARCHAR2,
    P_GL_OTC_REPO       VARCHAR2,
    P_SL_OTC_REPO       VARCHAR2,
    P_GL_BIAYA_YMH      VARCHAR2,
    P_SL_BIAYA_YMH      VARCHAR2,
    VP_USERID           VARCHAR2,
    VP_GENERATE_DATE    DATE,
    VO_RANDOM_VALUE OUT NUMBER,
    VO_ERRCD OUT NUMBER,
    VO_ERRMSG OUT VARCHAR2 )
IS
--[INDRA] 12JAN2018 UNION ALL DENGAN T_DAIL_OTC_JUR AMBIL YANG TIDAK KENA BIAYA KARENA USER BOLEH UBAH BIAYA TRANSFER
--06DEC2017 [INDRA] TAMBAH SYS PARAM
--23NOV2017[INDRA], JURNAL YANG NONCHARGEABLE KARENA BIAYA OTC SUDAH DIJURNAL HARIAN
  VL_RANDOM_VALUE NUMBER(10);
  VL_ERR          EXCEPTION;
  V_START_DATE DATE;
BEGIN

--06DEC2017 [INDRA]
BEGIN
  SELECT DDATE1 INTO V_START_DATE FROM MST_SYS_PARAM WHERE PARAM_ID = 'OTC_JOURNAL' AND PARAM_CD1='DAILY' AND PARAM_CD2='START';
  EXCEPTION
  WHEN OTHERS THEN
    VO_ERRCD  := -200;
    VO_ERRMSG := SUBSTR('SELECT START DATE FROM MST_SYS_PARAM '||SQLERRM,1,200);
    RAISE VL_ERR;
  END;

  VL_RANDOM_VALUE := ABS(DBMS_RANDOM.RANDOM);
  BEGIN
    SP_RPT_REMOVE_RAND('R_GENERATE_OTC_FEE',VL_RANDOM_VALUE,VO_ERRCD,VO_ERRMSG);
  EXCEPTION
  WHEN OTHERS THEN
    VO_ERRCD  := -2;
    VO_ERRMSG := SQLERRM(SQLCODE);
    RAISE VL_ERR;
  END;

  IF P_BGN_DT>= V_START_DATE THEN
      
             BEGIN   
                INSERT    INTO R_GENERATE_OTC_FEE
                (
                  CLIENT_CD, CLIENT_NAME,SUM_OTC_CLIENT,SUM_OTC_REPO_JUAL, SUM_OTC_REPO_BELI,JUR,CLOSED,RAND_VALUE,USER_ID,GENERATE_DATE, 
                  GL_OTC_CLIENT,SL_OTC_CLIENT,GL_OTC_CLIENT_NON,SL_OTC_CLIENT_NON, GL_OTC_REPO,SL_OTC_REPO,GL_BIAYA_YMH,SL_BIAYA_YMH
                )
                  SELECT    CLIENT_CD, CLIENT_NAME, OTC_CLIENT,
                  0 SUM_OTC_REPO_JUAL, 0 SUM_OTC_REPO_BELI, 'N' JUR, null CLOSED ,
                   VL_RANDOM_VALUE, VP_USERID, VP_GENERATE_DATE, P_GL_OTC_CLIENT,P_SL_OTC_CLIENT,P_GL_OTC_CLIENT_NON, P_SL_OTC_CLIENT_NON,
                        P_GL_OTC_REPO, P_SL_OTC_REPO, P_GL_BIAYA_YMH, P_SL_BIAYA_YMH
                  from(
                  --[INDRA]BGN 12JAN2018
                      SELECT A.CLIENT_CD,A.CLIENT_NAME,SUM_OTC OTC_CLIENT
                      FROM MST_CLIENT A
                      JOIN
                        (
                          SELECT client_cd,tidak_dijurnal, MAX(sum_otc)sum_otc
                          FROM t_daily_otc_jur
                          WHERE JUR_DATE BETWEEN P_BGN_DT  AND P_END_DT
                          AND TIDAK_DIJURNAL='Y'--YANG TIDAK DIKENAKAN BIAYA OTC
                          GROUP BY client_cd,tidak_dijurnal
                        )
                        B
                      ON A.CLIENT_CD     =B.CLIENT_CD
                      AND A.APPROVED_STAT='A'
                      UNION ALL
                      --[INDRA]END 12JAN2018
                      select client_cd,CLIENT_NAME,sum( decode(net_qty , 0,0, P_OTC_FEE)) OTC_CLIENT
                      from (
                          SELECT A.DOC_DT, A.CLIENT_CD, b.CLIENT_NAME, A.STK_CD, 
                          SUM(A.TOTAL_SHARE_QTY - A.WITHDRAWN_SHARE_QTY) AS NET_QTY
                          FROM IPNEXTG.T_STK_MOVEMENT A, IPNEXTG.MST_CLIENT B
                          WHERE A.SEQNO              = 1
                          AND A.CLIENT_CD            = B.CLIENT_CD
                          AND SUBSTR(A.DOC_NUM,5,3) IN ('RSN','WSN','JVS','JVB')
                          AND A.DOC_STAT             = '2'
                          AND A.DOC_DT BETWEEN P_BGN_DT  AND P_END_DT
                          AND A.BROKER IS NOT NULL
                          AND B.ACOPEN_FEE_FLG='N'  --YANG TIDAK DIKENAKAN BIAYA OTC
                          AND B.APPROVED_STAT='A' --12JAN2018
                          GROUP BY A.DOC_DT, A.CLIENT_CD, A.STK_CD, b.CLIENT_NAME
                            )
                     group by client_Cd, CLIENT_NAME
                 )
                  ORDER BY CLIENT_CD ;
               EXCEPTION
              WHEN OTHERS THEN
                VO_ERRCD  := -20;
                VO_ERRMSG := SUBSTR('INSERT INTO R_GENERATE_OTC_FEE '||SQLERRM,1,200);
                RAISE VL_ERR;
              END;

  ELSE

        BEGIN   
                INSERT    INTO R_GENERATE_OTC_FEE
                (
                  CLIENT_CD, CLIENT_NAME,SUM_OTC_CLIENT,SUM_OTC_REPO_JUAL, SUM_OTC_REPO_BELI,JUR,CLOSED,RAND_VALUE,USER_ID,GENERATE_DATE, 
                  GL_OTC_CLIENT,SL_OTC_CLIENT,GL_OTC_CLIENT_NON,SL_OTC_CLIENT_NON, GL_OTC_REPO,SL_OTC_REPO,GL_BIAYA_YMH,SL_BIAYA_YMH
                )

            SELECT client_cd, client_name, SUM(otc_client) sum_otc_client, 0 sum_otc_repo_jual, 0 sum_otc_repo_beli, jur, closed,
            VL_RANDOM_VALUE, VP_USERID, VP_GENERATE_DATE, P_GL_OTC_CLIENT,P_SL_OTC_CLIENT,P_GL_OTC_CLIENT_NON, P_SL_OTC_CLIENT_NON,
                        P_GL_OTC_REPO, P_SL_OTC_REPO, P_GL_BIAYA_YMH, P_SL_BIAYA_YMH
                FROM
                  (
                    SELECT x.DOC_DT, x.CLIENT_CD, x.STK_CD, x.withdraw_reason_cd, x.client_name, 
                    x.otc_client * DECODE(SIGN(rw_cnt),0,1, DECODE(SIGN(y.net_qty * x.doc_type),0,0,1,1,-1,0) * 
                    DECODE(x.doc_num,y.minr_doc_num,1,y.minw_doc_num,1,0) ) otc_client, DECODE(c.client_cd,NULL,jur,'N') jur ,
                    DECODE(c.client_cd,NULL,'','CLOSED') closed
                    FROM
                      (
                        SELECT a.DOC_DT, a.CLIENT_CD, a.STK_CD, a.doc_num,a.total_share_qty + a.withdrawn_share_qty AS qty,
                        a.withdraw_reason_cd, b.client_name, DECODE(LENGTH(trim(a.client_cd)),2,0,1) * P_OTC_FEE otc_client,
                        DECODE(SUBSTR(a.doc_num,5,3),'RSN',1,'WSN',-1,0) AS doc_type, b.acopen_fee_flg jur
                        FROM T_STK_MOVEMENT a, MST_CLIENT b
                        WHERE a.seqno              = 1
                        AND SUBSTR(a.DOC_NUM,5,3) IN ('RSN','WSN','JVB','JVS')
                        AND a.client_cd            = b.client_cd
                        AND a.doc_stat             = '2'
                        AND a.doc_dt BETWEEN P_BGN_DT  AND P_END_DT
                        AND a.broker IS NOT NULL
                      )
                      x, (
                        SELECT a.DOC_DT, a.CLIENT_CD, a.STK_CD, SUM(DECODE(SUBSTR(doc_num,5,1),'J',0,a.total_share_qty - a.withdrawn_share_qty)) AS net_qty,
                        MIN(DECODE(SUBSTR(doc_num,5,1),'R',doc_num,'_')) minr_doc_num, MIN(DECODE(SUBSTR(doc_num,5,1),'W',doc_num,'_')) minw_doc_num, 
                        SUM(DECODE(SUBSTR(doc_num,5,1),'R',1,0)) * SUM(DECODE(SUBSTR(doc_num,5,1),'W',1,0)) RW_cnt
                        FROM T_STK_MOVEMENT a
                        WHERE a.seqno              = 1
                        AND SUBSTR(a.DOC_NUM,5,3) IN ('RSN','WSN','JVS','JVB')
                        AND a.doc_stat             = '2'
                        AND a.doc_dt BETWEEN P_BGN_DT  AND P_END_DT
                        AND a.broker IS NOT NULL
                        GROUP BY a.DOC_DT, a.CLIENT_CD, a.STK_CD
                      )
                      y, (
                        SELECT client_cd
                        FROM T_CLIENT_CLOSING
                        WHERE TRUNC(cre_Dt) BETWEEN P_END_DT-32  AND P_END_DT
                        AND new_stat = 'C'
                      )
                      c
                    WHERE x.doc_dt  = y.doc_dt
                    AND x.client_cd = y.client_cd
                    AND x.stk_cd    = y.stk_cd
                    AND x.client_Cd = c.client_cd(+)
                  )
                GROUP BY client_cd, client_name,jur, closed
                ORDER BY client_cd;
                 EXCEPTION
              WHEN OTHERS THEN
                VO_ERRCD  := -25;
                VO_ERRMSG := SUBSTR('INSERT INTO R_GENERATE_OTC_FEE '||SQLERRM,1,200);
                RAISE VL_ERR;
              END;

  END IF; 
    
  
  VO_RANDOM_VALUE := VL_RANDOM_VALUE;
  VO_ERRCD        := 1;
  VO_ERRMSG       := '';
  
  COMMIT;
EXCEPTION
WHEN VL_ERR THEN
  ROLLBACK;
  VO_RANDOM_VALUE := 0;
  VO_ERRMSG       := SUBSTR(VO_ERRMSG,1,200);
WHEN OTHERS THEN
  ROLLBACK;
  VO_RANDOM_VALUE := 0;
  VO_ERRCD        := -1;
  VO_ERRMSG       := SUBSTR(SQLERRM(SQLCODE),1,200);
END SPR_GENERATE_OTC_FEE;