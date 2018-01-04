create or replace PROCEDURE SPR_PROFIT_LOSS_BRANCH(
    P_BGN_DATE      DATE,
    P_END_DATE      DATE,
    P_BGN_BRANCH    VARCHAR2,
    P_END_BRANCH    VARCHAR2,
    P_CRITERIA      VARCHAR2,
    P_BGN_MON       NUMBER,
    P_END_MON       NUMBER,
    P_BRANCH_FLG    VARCHAR2,
    P_FIXED_INCOME  VARCHAR2,
    P_USER_ID       VARCHAR2,
    P_GENERATE_DATE DATE,
    P_RANDOM_VALUE OUT NUMBER,
    P_ERROR_CD OUT NUMBER,
    P_ERROR_MSG OUT VARCHAR2 )
AS
-- 11jan2017 gl_acct_Cd utk komisi , dibuat variable, ambil dr mst_GLA_TRX

  V_ERR          EXCEPTION;
  V_ERROR_CD     NUMBER(5);
  V_ERROR_MSG    VARCHAR2(200);
  V_RANDOM_VALUE NUMBER(10);
  V_FIXED_INCOME R_PROFIT_LOSS_BRANCH.FIXED_INCOME%TYPE;
  V_BGN_BAL_DATE      DATE;
  V_END_DATE_LAST_MON DATE;
  V_BGN_DATE_LAST_MON DATE;
  V_BGN_DATE DATE;
  V_SQL VARCHAR2(500);
  V_STR VARCHAR2(500);
  V_GLA_KOMISI t_account_ledger.gl_acct_cd%type;
BEGIN
  V_RANDOM_VALUE := ABS(DBMS_RANDOM.RANDOM);
  
  IF P_FIXED_INCOME <> 'TOTAL' THEN
    V_FIXED_INCOME  := 'without Fixed Income';
  END IF;
  ----------------------SPECIFIED--------------------------------
  IF P_BRANCH_FLG='SPECIFIED' THEN

BEGIN
    SP_RPT_REMOVE_RAND('R_PROFIT_LOSS_BRANCH',V_RANDOM_VALUE,V_ERROR_MSG,V_ERROR_CD);
  EXCEPTION
  WHEN OTHERS THEN
    V_ERROR_CD  := -10;
    V_ERROR_MSG := SUBSTR('SP_RPT_REMOVE_RAND '||V_ERROR_MSG||SQLERRM(SQLCODE),1,200);
    RAISE V_err;
  END;

    begin
    select gl_a into V_GLA_KOMISI
    from MST_GLA_TRX
    where jur_type = 'COMM';
    EXCEPTION
     WHEN OTHERS THEN
    V_ERROR_CD  := -20;
    V_ERROR_MSG := SUBSTR(' RETRIEVE MST_GLA_TRX JUR TYPE -COMM- '||SQLERRM(SQLCODE),1,200);
    RAISE V_err;
  END;
    
INSERT INTO TMP_CTR_PL_BRANCH
SELECT trim(T_CONTRACTS.brch_cd) AS branch_cd,
              DECODE(TO_CHAR(contr_dt,'MM'), TO_CHAR(P_BGN_DATE,'MM'),1,0)                * commission comm01,
              DECODE(TO_CHAR(contr_dt,'MM'), TO_CHAR(add_months(P_BGN_DATE,1),'MM'),1,0)  * commission comm02,
              DECODE(TO_CHAR(contr_dt,'MM'), TO_CHAR(add_months(P_BGN_DATE,2),'MM'),1,0)  * commission comm03,
              DECODE(TO_CHAR(contr_dt,'MM'), TO_CHAR(add_months(P_BGN_DATE,3),'MM'),1,0)  * commission comm04,
              DECODE(TO_CHAR(contr_dt,'MM'), TO_CHAR(add_months(P_BGN_DATE,4),'MM'),1,0)  * commission comm05,
              DECODE(TO_CHAR(contr_dt,'MM'), TO_CHAR(add_months(P_BGN_DATE,5),'MM'),1,0)  * commission comm06,
              DECODE(TO_CHAR(contr_dt,'MM'), TO_CHAR(add_months(P_BGN_DATE,6),'MM'),1,0)  * commission comm07,
              DECODE(TO_CHAR(contr_dt,'MM'),TO_CHAR(add_months(P_BGN_DATE,7),'MM'),1,0)   * commission comm08,
              DECODE(TO_CHAR(contr_dt,'MM'), TO_CHAR(add_months(P_BGN_DATE,8),'MM'),1,0)  * commission comm09,
              DECODE(TO_CHAR(contr_dt,'MM'), TO_CHAR(add_months(P_BGN_DATE,9),'MM'),1,0)  * commission comm10,
              DECODE(TO_CHAR(contr_dt,'MM'), TO_CHAR(add_months(P_BGN_DATE,10),'MM'),1,0) * commission comm11,
              DECODE(TO_CHAR(contr_dt,'MM'), TO_CHAR(add_months(P_BGN_DATE,11),'MM'),1,0) * commission comm12,
              V_RANDOM_VALUE,
              P_USER_ID
            FROM T_CONTRACTS
            WHERE T_CONTRACTS.contr_dt BETWEEN P_BGN_DATE AND P_END_DATE
            AND (T_CONTRACTS.contr_stat             <> 'C')
            AND (SUBSTR(T_CONTRACTS.contr_num, 6, 1) = 'R');

INSERT INTO TMP_TAL_PL_BRANCH 
SELECT TRIM(gl_acct_cd)
            || TRIM(sl_acct_cd)                                                                                                  AS acct_cd,
            SUM(DECODE(TO_CHAR(doc_date,'MM'), TO_CHAR(P_BGN_DATE,'MM'),1,0)                * DECODE(db_cr_flg, 'D', 1, -1) * NVL(curr_val, 0)) AS Mon01,
            SUM(DECODE(TO_CHAR(doc_date,'MM'), TO_CHAR(add_months(P_BGN_DATE,1),'MM'),1,0)  * DECODE(db_cr_flg, 'D', 1, -1) * NVL(curr_val, 0)) AS Mon02,
            SUM(DECODE(TO_CHAR(doc_date,'MM'), TO_CHAR(add_months(P_BGN_DATE,2),'MM'),1,0)  * DECODE(db_cr_flg, 'D', 1, -1) * NVL(curr_val, 0)) AS Mon03,
            SUM(DECODE(TO_CHAR(doc_date,'MM'), TO_CHAR(add_months(P_BGN_DATE,3),'MM'),1,0)  * DECODE(db_cr_flg, 'D', 1, -1) * NVL(curr_val, 0)) AS Mon04,
            SUM(DECODE(TO_CHAR(doc_date,'MM'), TO_CHAR(add_months(P_BGN_DATE,4),'MM'),1,0)  * DECODE(db_cr_flg, 'D', 1, -1) * NVL(curr_val, 0)) AS Mon05,
            SUM(DECODE(TO_CHAR(doc_date,'MM'), TO_CHAR(add_months(P_BGN_DATE,5),'MM'),1,0)  * DECODE(db_cr_flg, 'D', 1, -1) * NVL(curr_val, 0)) AS Mon06,
            SUM(DECODE(TO_CHAR(doc_date,'MM'), TO_CHAR(add_months(P_BGN_DATE,6),'MM'),1,0)  * DECODE(db_cr_flg, 'D', 1, -1) * NVL(curr_val, 0)) AS Mon07,
            SUM(DECODE(TO_CHAR(doc_date,'MM'), TO_CHAR(add_months(P_BGN_DATE,7),'MM'),1,0)  * DECODE(db_cr_flg, 'D', 1, -1) * NVL(curr_val, 0)) AS Mon08,
            SUM(DECODE(TO_CHAR(doc_date,'MM'), TO_CHAR(add_months(P_BGN_DATE,8),'MM'),1,0)  * DECODE(db_cr_flg, 'D', 1, -1) * NVL(curr_val, 0)) AS Mon09,
            SUM(DECODE(TO_CHAR(doc_date,'MM'), TO_CHAR(add_months(P_BGN_DATE,9),'MM'),1,0)  * DECODE(db_cr_flg, 'D', 1, -1) * NVL(curr_val, 0)) AS Mon10,
            SUM(DECODE(TO_CHAR(doc_date,'MM'), TO_CHAR(add_months(P_BGN_DATE,10),'MM'),1,0) * DECODE(db_cr_flg, 'D', 1, -1) * NVL(curr_val, 0)) AS Mon11,
            SUM(DECODE(TO_CHAR(doc_date,'MM'), TO_CHAR(add_months(P_BGN_DATE,11),'MM'),1,0) * DECODE(db_cr_flg, 'D', 1, -1) * NVL(curr_val, 0)) AS Mon12,
            V_RANDOM_VALUE,
              P_USER_ID
          FROM T_ACCOUNT_LEDGER
          WHERE T_ACCOUNT_LEDGER.doc_date BETWEEN P_BGN_DATE AND P_END_DATE
          AND T_ACCOUNT_LEDGER.approved_sts = 'A'
          AND T_ACCOUNT_LEDGER.gl_acct_cd  IN
            ( SELECT DISTINCT gl_A_cd FROM V_LABARUGI_ACCT_APR2015
            )
          GROUP BY T_ACCOUNT_LEDGER.gl_acct_cd,
            T_ACCOUNT_LEDGER.sl_acct_cd;

    BEGIN
      INSERT
      INTO R_PROFIT_LOSS_BRANCH
        (
          GL_ACCT_GROUP ,
          GL_ACCT_GROUP_NAME ,
          BRANCH_CD ,
          BRANCH_NAME ,
          GL_ACCT_CD ,
          GL_ACCT_NAME ,
          SL_ACCT_CD ,
          SL_ACCT_NAME ,
          MON01 ,
          MON02 ,
          MON03 ,
          MON04 ,
          MON05 ,
          MON06 ,
          MON07 ,
          MON08 ,
          MON09 ,
          MON10 ,
          MON11 ,
          MON12 ,
          LINE_TOTAL,
          USER_ID ,
          RAND_VALUE ,
          GENERATE_DATE,
          BGN_DATE,
          END_DATE,
          CRITERIA,
          BGN_MON,
          END_MON,
          BRANCH_FLG,
          LR_FAKTOR
        )
      SELECT GL_ACCT_GROUP ,
        GL_ACCT_GROUP_NAME ,
        BRANCH_CD ,
        BRANCH_NAME ,
        GL_ACCT_CD ,
        GL_ACCT_NAME ,
        SL_ACCT_CD ,
        SL_ACCT_NAME ,
        MON01 ,
        MON02 ,
        MON03 ,
        MON04 ,
        MON05 ,
        MON06 ,
        MON07 ,
        MON08 ,
        MON09 ,
        MON10 ,
        MON11 ,
        MON12 ,
        NULL LINE_TOTAL,
        P_USER_ID ,
        V_RANDOM_VALUE ,
        P_GENERATE_DATE,
        P_BGN_DATE,
        P_END_DATE,
        P_CRITERIA,
        P_BGN_MON,
        P_END_MON,
        P_BRANCH_FLG,
        LR_FAKTOR
      FROM
        (SELECT '01'                AS gl_acct_group,
          'PENDAPATAN'              AS gl_acct_group_name,
          MST_BRANCH.brch_cd        AS branch_cd,
          MST_BRANCH.brch_name      AS branch_name,
          '6XXX'                    AS gl_acct_cd,
          'KOMISI PERDAGANGAN EFEK' AS gl_acct_name,
          '000000'                  AS sl_acct_cd,
          'KOMISI PERDAGANGAN EFEK' AS sl_acct_name,
          NVL(C.comm01, 0)          AS MON01,
          NVL(C.comm02, 0)          AS MON02,
          NVL(C.comm03, 0)          AS MON03,
          NVL(C.comm04, 0)          AS MON04,
          NVL(C.comm05, 0)          AS MON05,
          NVL(C.comm06, 0)          AS MON06,
          NVL(C.comm07, 0)          AS MON07,
          NVL(C.comm08, 0)          AS MON08,
          NVL(C.comm09, 0)          AS MON09,
          NVL(C.comm10, 0)          AS MON10,
          NVL(C.comm11, 0)          AS MON11,
          NVL(C.comm12, 0)          AS MON12,
          1 LR_FAKTOR
        FROM
          (SELECT branch_cd,
            ROUND(SUM(comm01), 0) AS comm01,
            ROUND(SUM(comm02), 0) AS comm02,
            ROUND(SUM(comm03), 0) AS comm03,
            ROUND(SUM(comm04), 0) AS comm04,
            ROUND(SUM(comm05), 0) AS comm05,
            ROUND(SUM(comm06), 0) AS comm06,
            ROUND(SUM(comm07), 0) AS comm07,
            ROUND(SUM(comm08), 0) AS comm08,
            ROUND(SUM(comm09), 0) AS comm09,
            ROUND(SUM(comm10), 0) AS comm10,
            ROUND(SUM(comm11), 0) AS comm11,
            ROUND(SUM(comm12), 0) AS comm12
          FROM
            (
            SELECT * FROM TMP_CTR_PL_BRANCH WHERE RAND_VALUE=V_RANDOM_VALUE AND USER_ID=P_USER_ID
            UNION ALL
            SELECT branch_Cd,
              (DECODE(TO_CHAR(doc_date,'MM'), TO_CHAR(P_BGN_DATE,'MM'),1,0)                * DECODE(db_cr_flg, 'D', 1, 1) * NVL(curr_val, 0)) AS Mon01,
              (DECODE(TO_CHAR(doc_date,'MM'), TO_CHAR(add_months(P_BGN_DATE,1),'MM'),1,0)  * DECODE(db_cr_flg, 'D', 1, 1) * NVL(curr_val, 0)) AS Mon02,
              (DECODE(TO_CHAR(doc_date,'MM'), TO_CHAR(add_months(P_BGN_DATE,2),'MM'),1,0)  * DECODE(db_cr_flg, 'D', 1, 1) * NVL(curr_val, 0)) AS Mon03,
              (DECODE(TO_CHAR(doc_date,'MM'), TO_CHAR(add_months(P_BGN_DATE,3),'MM'),1,0)  * DECODE(db_cr_flg, 'D', 1, 1) * NVL(curr_val, 0)) AS Mon04,
              (DECODE(TO_CHAR(doc_date,'MM'), TO_CHAR(add_months(P_BGN_DATE,4),'MM'),1,0)  * DECODE(db_cr_flg, 'D', 1, 1) * NVL(curr_val, 0)) AS Mon05,
              (DECODE(TO_CHAR(doc_date,'MM'), TO_CHAR(add_months(P_BGN_DATE,5),'MM'),1,0)  * DECODE(db_cr_flg, 'D', 1, 1) * NVL(curr_val, 0)) AS Mon06,
              (DECODE(TO_CHAR(doc_date,'MM'), TO_CHAR(add_months(P_BGN_DATE,6),'MM'),1,0)  * DECODE(db_cr_flg, 'D', 1,1) * NVL(curr_val, 0))  AS Mon07,
              (DECODE(TO_CHAR(doc_date,'MM'), TO_CHAR(add_months(P_BGN_DATE,7),'MM'),1,0)  * DECODE(db_cr_flg, 'D', 1,1) * NVL(curr_val, 0))  AS Mon08,
              (DECODE(TO_CHAR(doc_date,'MM'), TO_CHAR(add_months(P_BGN_DATE,8),'MM'),1,0)  * DECODE(db_cr_flg, 'D', 1, 1) * NVL(curr_val, 0)) AS Mon09,
              (DECODE(TO_CHAR(doc_date,'MM'), TO_CHAR(add_months(P_BGN_DATE,9),'MM'),1,0)  * DECODE(db_cr_flg, 'D', 1, 1) * NVL(curr_val, 0)) AS Mon10,
              (DECODE(TO_CHAR(doc_date,'MM'), TO_CHAR(add_months(P_BGN_DATE,10),'MM'),1,0) * DECODE(db_cr_flg, 'D', 1, 1) * NVL(curr_val, 0)) AS Mon11,
              (DECODE(TO_CHAR(doc_date,'MM'), TO_CHAR(add_months(P_BGN_DATE,11),'MM'),1,0) * DECODE(db_cr_flg, 'D', 1,1) * NVL(curr_val, 0))  AS Mon12,
              V_RANDOM_VALUE,
              P_USER_ID
            FROM
              (SELECT xn_doc_num ,
                curr_val,
                db_cr_flg,
                doc_date ,
                branch_cd
              FROM
                (SELECT SUBSTR(contr_num,1,6)
                  ||'0'
                  ||SUBSTR(contr_num,8,6) contr_num,
                  trim(T_CONTRACTS.brch_cd) AS branch_cd
                FROM T_CONTRACTS
                WHERE contr_dt BETWEEN P_BGN_DATE AND P_END_DATE
                AND SUBSTR(contr_num,6,1) = 'I'
                AND record_Source        IN ( 'IC','CG')
                AND contr_Stat           <> 'C'
                ) a,
                T_ACCOUNT_LEDGER b
              WHERE a.contr_num = b.xn_doc_num
              AND b.gl_Acct_cd  = V_GLA_KOMISI
              AND b.doc_Date BETWEEN P_BGN_DATE AND P_END_DATE
              AND b.approved_sts = 'A'
              )
            )
          GROUP BY branch_cd
          ) C,
          ( SELECT brch_cd ,BRCH_NAME, ACCT_PREFIX FROM mst_branch
          UNION
          SELECT 'ZI' BRCH_CD, 'FIXED INCOME' BRCH_NAME ,'90' ACCT_PREFIX FROM DUAL
          ) MST_BRANCH
        WHERE MST_BRANCH.brch_cd BETWEEN P_BGN_BRANCH AND P_END_BRANCH
        AND C.branch_cd(+) = MST_BRANCH.brch_cd
        AND ( c.comm01    <> 0
        OR c.comm02       <> 0
        OR c.comm03       <> 0
        OR c.comm04       <> 0
        OR c.comm05       <> 0
        OR c.comm06       <> 0
        OR c.comm07       <> 0
        OR c.comm08       <> 0
        OR c.comm09       <> 0
        OR c.comm10       <> 0
        OR c.comm11       <> 0
        OR c.comm12       <> 0)
        UNION
        SELECT v.gl_acct_group,
          v.gl_acct_group_name,
          MST_BRANCH.brch_cd         AS branch_cd,
          MST_BRANCH.brch_name       AS branch_name,
          v.gl_a                     AS gl_acct_cd,
          v.main_acct_name           AS gl_acct_name,
          TRIM(v.sl_a)               AS sl_acct_cd,
          v.acct_name                AS sl_acct_name,
          NVL(A.mon01, 0) * v.faktor AS MON01,
          NVL(A.mon02, 0) * v.faktor AS MON02,
          NVL(A.mon03, 0) * v.faktor AS MON03,
          NVL(A.mon04, 0) * v.faktor AS MON04,
          NVL(A.mon05, 0) * v.faktor AS MON05,
          NVL(A.mon06, 0) * v.faktor AS MON06,
          NVL(A.mon07, 0) * v.faktor AS MON07,
          NVL(A.mon08, 0) * v.faktor AS MON08,
          NVL(A.mon09, 0) * v.faktor AS MON09,
          NVL(A.mon10, 0) * v.faktor AS MON10,
          NVL(A.mon11, 0) * v.faktor AS MON11,
          NVL(A.mon12, 0) * v.faktor AS MON12,
          V.LR_FAKTOR
        FROM
          ( SELECT * FROM TMP_TAL_PL_BRANCH WHERE RAND_VALUE=V_RANDOM_VALUE AND USER_ID=P_USER_ID
          ) A,
          v_labarugi_acct_APR2015 v,
          ( SELECT brch_cd ,BRCH_NAME, ACCT_PREFIX FROM mst_branch
          UNION
          SELECT 'ZI' BRCH_CD, 'FIXED INCOME' BRCH_NAME ,'90' ACCT_PREFIX FROM DUAL
          ) MST_BRANCH
        WHERE MST_BRANCH.brch_cd BETWEEN P_BGN_BRANCH AND P_END_BRANCH
        AND MST_BRANCH.acct_prefix = v.acct_prefix
        AND A.acct_cd(+)           = v.acct_cd
        AND (a.mon01              <> 0
        OR a.mon02                <> 0
        OR a.mon03                <> 0
        OR a.mon04                <> 0
        OR a.mon05                <> 0
        OR a.mon06                <> 0
        OR a.mon07                <> 0
        OR a.mon08                <> 0
        OR a.mon09                <> 0
        OR a.mon10                <> 0
        OR a.mon11                <> 0
        OR a.mon12                <> 0)
        )
      ORDER BY branch_cd ASC,
        gl_acct_group ASC,
        gl_acct_cd ASC,
        sl_acct_cd ASC ;
    EXCEPTION
    WHEN OTHERS THEN
      V_ERROR_CD  := -40;
      V_ERROR_MSG := SUBSTR('INSERT INTO R_PROFIT_LOSS_BRANCH '||SQLERRM,1,200);
      RAISE V_err;
    END;
    
    --UPDATE LINE TOTAL
    V_SQL :='UPDATE R_PROFIT_LOSS_BRANCH SET LINE_TOTAL = ';
    V_STR :='';
        FOR I IN P_BGN_MON..P_END_MON LOOP
              IF I =1 THEN
                 V_STR := 'MON'||TO_CHAR(I,'FM00');
              ELSE
                  V_STR :=V_STR ||' + '||' MON' ||TO_CHAR(I,'FM00');
              END IF;
              
        END LOOP;

      V_SQL :=V_SQL||V_STR || ' WHERE RAND_VALUE ='''||V_RANDOM_VALUE||''' AND USER_ID = '''||P_USER_ID||''' ';

   BEGIN
    EXECUTE IMMEDIATE V_SQL;
  EXCEPTION
    WHEN OTHERS THEN
   --   RAISE_APPLICATION_ERROR(-20100,'EXECUTE IMMEDIATE UPDATE R_PROFIT_LOSS_BRANCH ' ||SQLERRM);
    V_ERROR_CD  := -7;
    --V_ERROR_MSG := SUBSTR('EXECUTE IMMEDIATE UPDATE R_PROFIT_LOSS_BRANCH ' ||V_SQL||' '||SQLERRM,1,200);
      V_ERROR_MSG :=V_SQL;
    RAISE V_err;
  END;
    
  END IF;
  ----------------------END SPECIFIED--------------------------------
  ----------------------ALL BRANCHES--------------------------------
  IF P_BRANCH_FLG = 'ALL BRANCHES' THEN


BEGIN
    SP_RPT_REMOVE_RAND('R_PROFIT_LOSS_BRANCH',V_RANDOM_VALUE,V_ERROR_MSG,V_ERROR_CD);
  EXCEPTION
  WHEN OTHERS THEN
    V_ERROR_CD  := -10;
    V_ERROR_MSG := SUBSTR('SP_RPT_REMOVE_RAND '||V_ERROR_MSG||SQLERRM(SQLCODE),1,200);
    RAISE V_err;
  END;


INSERT INTO TMP_TAL_PL_BRANCH
SELECT TRIM(T_ACCOUNT_LEDGER.GL_ACCT_CD)
            || SUBSTR(T_ACCOUNT_LEDGER.SL_ACCT_CD,3,4)                                                                                                          AS ACCT_CD,
            SUM(DECODE(TO_CHAR(T_ACCOUNT_LEDGER.DOC_DATE,'MM'), '01',1,0) * DECODE(T_ACCOUNT_LEDGER.DB_CR_FLG, 'D', 1, -1) * NVL(T_ACCOUNT_LEDGER.CURR_VAL, 0)) AS MON01,
            SUM(DECODE(TO_CHAR(T_ACCOUNT_LEDGER.DOC_DATE,'MM'), '02',1,0) * DECODE(T_ACCOUNT_LEDGER.DB_CR_FLG, 'D', 1, -1) * NVL(T_ACCOUNT_LEDGER.CURR_VAL, 0)) AS MON02,
            SUM(DECODE(TO_CHAR(T_ACCOUNT_LEDGER.DOC_DATE,'MM'), '03',1,0) * DECODE(T_ACCOUNT_LEDGER.DB_CR_FLG, 'D', 1, -1) * NVL(T_ACCOUNT_LEDGER.CURR_VAL, 0)) AS MON03,
            SUM(DECODE(TO_CHAR(T_ACCOUNT_LEDGER.DOC_DATE,'MM'), '04',1,0) * DECODE(T_ACCOUNT_LEDGER.DB_CR_FLG, 'D', 1, -1) * NVL(T_ACCOUNT_LEDGER.CURR_VAL, 0)) AS MON04,
            SUM(DECODE(TO_CHAR(T_ACCOUNT_LEDGER.DOC_DATE,'MM'), '05',1,0) * DECODE(T_ACCOUNT_LEDGER.DB_CR_FLG, 'D', 1, -1) * NVL(T_ACCOUNT_LEDGER.CURR_VAL, 0)) AS MON05,
            SUM(DECODE(TO_CHAR(T_ACCOUNT_LEDGER.DOC_DATE,'MM'), '06',1,0) * DECODE(T_ACCOUNT_LEDGER.DB_CR_FLG, 'D', 1, -1) * NVL(T_ACCOUNT_LEDGER.CURR_VAL, 0)) AS MON06,
            SUM(DECODE(TO_CHAR(T_ACCOUNT_LEDGER.DOC_DATE,'MM'), '07',1,0) * DECODE(T_ACCOUNT_LEDGER.DB_CR_FLG, 'D', 1, -1) * NVL(T_ACCOUNT_LEDGER.CURR_VAL, 0)) AS MON07,
            SUM(DECODE(TO_CHAR(T_ACCOUNT_LEDGER.DOC_DATE,'MM'), '08',1,0) * DECODE(T_ACCOUNT_LEDGER.DB_CR_FLG, 'D', 1, -1) * NVL(T_ACCOUNT_LEDGER.CURR_VAL, 0)) AS MON08,
            SUM(DECODE(TO_CHAR(T_ACCOUNT_LEDGER.DOC_DATE,'MM'), '09',1,0) * DECODE(T_ACCOUNT_LEDGER.DB_CR_FLG, 'D', 1, -1) * NVL(T_ACCOUNT_LEDGER.CURR_VAL, 0)) AS MON09,
            SUM(DECODE(TO_CHAR(T_ACCOUNT_LEDGER.DOC_DATE,'MM'), '10',1,0) * DECODE(T_ACCOUNT_LEDGER.DB_CR_FLG, 'D', 1, -1) * NVL(T_ACCOUNT_LEDGER.CURR_VAL, 0)) AS MON10,
            SUM(DECODE(TO_CHAR(T_ACCOUNT_LEDGER.DOC_DATE,'MM'), '11',1,0) * DECODE(T_ACCOUNT_LEDGER.DB_CR_FLG, 'D', 1, -1) * NVL(T_ACCOUNT_LEDGER.CURR_VAL, 0)) AS MON11,
            SUM(DECODE(TO_CHAR(T_ACCOUNT_LEDGER.DOC_DATE,'MM'), '12',1,0) * DECODE(T_ACCOUNT_LEDGER.DB_CR_FLG, 'D', 1, -1) * NVL(T_ACCOUNT_LEDGER.CURR_VAL, 0)) AS MON12,
  		V_RANDOM_VALUE,
  		P_USER_ID          
          FROM T_ACCOUNT_LEDGER
          WHERE T_ACCOUNT_LEDGER.DOC_DATE BETWEEN P_BGN_DATE AND P_END_DATE
          AND T_ACCOUNT_LEDGER.APPROVED_STS = 'A'
          AND T_ACCOUNT_LEDGER.GL_ACCT_CD    IN
            ( SELECT DISTINCT GL_A_CD FROM V_LABARUGI_ACCT_APR2013
            )
          AND (P_FIXED_INCOME                   = 'TOTAL'
          OR (NOT (T_ACCOUNT_LEDGER.GL_ACCT_CD IN ('5300','5600')
          AND T_ACCOUNT_LEDGER.SL_ACCT_CD LIKE '90%')))
          GROUP BY T_ACCOUNT_LEDGER.GL_ACCT_CD,
            SUBSTR(T_ACCOUNT_LEDGER.SL_ACCT_CD,3,4);


    BEGIN
      INSERT
      INTO R_PROFIT_LOSS_BRANCH
        (
          GL_ACCT_GROUP ,
          GL_ACCT_GROUP_NAME ,
          GL_ACCT_CD ,
          GL_ACCT_NAME ,
          SL_ACCT_CD ,
          SL_ACCT_NAME ,
          MON01 ,
          MON02 ,
          MON03 ,
          MON04 ,
          MON05 ,
          MON06 ,
          MON07 ,
          MON08 ,
          MON09 ,
          MON10 ,
          MON11 ,
          MON12 ,
          LINE_TOTAL ,
          USER_ID ,
          RAND_VALUE ,
          GENERATE_DATE ,
          BGN_DATE ,
          END_DATE ,
          CRITERIA ,
          BGN_MON ,
          END_MON ,
          BRANCH_FLG,
          FIXED_INCOME,
          LR_FAKTOR
        )
      SELECT GL_ACCT_GROUP ,
        GL_ACCT_GROUP_NAME ,
        GL_ACCT_CD ,
        GL_ACCT_NAME ,
        SL_ACCT_CD ,
        SL_ACCT_NAME ,
        MON01 ,
        MON02 ,
        MON03 ,
        MON04 ,
        MON05 ,
        MON06 ,
        MON07 ,
        MON08 ,
        MON09 ,
        MON10 ,
        MON11 ,
        MON12 ,
        0 LINE_TOTAL ,
        P_USER_ID ,
        V_RANDOM_VALUE ,
        P_GENERATE_DATE ,
        P_BGN_DATE ,
        P_END_DATE ,
        P_CRITERIA ,
        P_BGN_MON ,
        P_END_MON ,
        P_BRANCH_FLG,
        V_FIXED_INCOME,
        LR_FAKTOR
      FROM
        (SELECT '01'                AS GL_ACCT_GROUP,
          'PENDAPATAN'              AS GL_ACCT_GROUP_NAME,
          '6XXX'                    AS GL_ACCT_CD,
          'KOMISI PERDAGANGAN EFEK' AS GL_ACCT_NAME,
          '000000'                  AS SL_ACCT_CD,
          'KOMISI PERDAGANGAN EFEK' AS SL_ACCT_NAME,
          NVL(C.COMM01, 0)          AS MON01,
          NVL(C.COMM02, 0)          AS MON02,
          NVL(C.COMM03, 0)          AS MON03,
          NVL(C.COMM04, 0)          AS MON04,
          NVL(C.COMM05, 0)          AS MON05,
          NVL(C.COMM06, 0)          AS MON06,
          NVL(C.COMM07, 0)          AS MON07,
          NVL(C.COMM08, 0)          AS MON08,
          NVL(C.COMM09, 0)          AS MON09,
          NVL(C.COMM10, 0)          AS MON10,
          NVL(C.COMM11, 0)          AS MON11,
          NVL(C.COMM12, 0)          AS MON12,
          1 LR_FAKTOR
        FROM
          (SELECT ROUND(SUM(COMM01), 0) AS COMM01,
            ROUND(SUM(COMM02), 0)       AS COMM02,
            ROUND(SUM(COMM03), 0)       AS COMM03,
            ROUND(SUM(COMM04), 0)       AS COMM04,
            ROUND(SUM(COMM05), 0)       AS COMM05,
            ROUND(SUM(COMM06), 0)       AS COMM06,
            ROUND(SUM(COMM07), 0)       AS COMM07,
            ROUND(SUM(COMM08), 0)       AS COMM08,
            ROUND(SUM(COMM09), 0)       AS COMM09,
            ROUND(SUM(COMM10), 0)       AS COMM10,
            ROUND(SUM(COMM11), 0)       AS COMM11,
            ROUND(SUM(COMM12), 0)       AS COMM12
          FROM
            (SELECT DECODE(TO_CHAR(CONTR_DT,'MM'),TO_CHAR(P_BGN_DATE,'MM'),1,0)           * COMMISSION COMM01,
              DECODE(TO_CHAR(CONTR_DT,'MM'), TO_CHAR(ADD_MONTHS(P_BGN_DATE,1),'MM'),1,0)  * COMMISSION COMM02,
              DECODE(TO_CHAR(CONTR_DT,'MM'), TO_CHAR(ADD_MONTHS(P_BGN_DATE,2),'MM'),1,0)  * COMMISSION COMM03,
              DECODE(TO_CHAR(CONTR_DT,'MM'),TO_CHAR(ADD_MONTHS(P_BGN_DATE,3),'MM'),1,0)   * COMMISSION COMM04,
              DECODE(TO_CHAR(CONTR_DT,'MM'), TO_CHAR(ADD_MONTHS(P_BGN_DATE,4),'MM'),1,0)  * COMMISSION COMM05,
              DECODE(TO_CHAR(CONTR_DT,'MM'), TO_CHAR(ADD_MONTHS(P_BGN_DATE,5),'MM'),1,0)  * COMMISSION COMM06,
              DECODE(TO_CHAR(CONTR_DT,'MM'), TO_CHAR(ADD_MONTHS(P_BGN_DATE,6),'MM'),1,0)  * COMMISSION COMM07,
              DECODE(TO_CHAR(CONTR_DT,'MM'), TO_CHAR(ADD_MONTHS(P_BGN_DATE,7),'MM'),1,0)  * COMMISSION COMM08,
              DECODE(TO_CHAR(CONTR_DT,'MM'), TO_CHAR(ADD_MONTHS(P_BGN_DATE,8),'MM'),1,0)  * COMMISSION COMM09,
              DECODE(TO_CHAR(CONTR_DT,'MM'), TO_CHAR(ADD_MONTHS(P_BGN_DATE,9),'MM'),1,0)  * COMMISSION COMM10,
              DECODE(TO_CHAR(CONTR_DT,'MM'),TO_CHAR(ADD_MONTHS(P_BGN_DATE,10),'MM'),1,0)  * COMMISSION COMM11,
              DECODE(TO_CHAR(CONTR_DT,'MM'), TO_CHAR(ADD_MONTHS(P_BGN_DATE,11),'MM'),1,0) * COMMISSION COMM12
            FROM T_CONTRACTS
            WHERE T_CONTRACTS.CONTR_DT BETWEEN P_BGN_DATE AND P_END_DATE
            AND (T_CONTRACTS.CONTR_STAT          <> 'C')
            AND SUBSTR(T_CONTRACTS.CONTR_NUM,6,1) = 'R'
            UNION ALL
            SELECT (DECODE(TO_CHAR(DOC_DATE,'MM'),TO_CHAR(P_BGN_DATE,'MM'),1,0)            * DECODE(DB_CR_FLG, 'D', 1, 1) * NVL(CURR_VAL, 0)) AS MON01,
              (DECODE(TO_CHAR(DOC_DATE,'MM'), TO_CHAR(ADD_MONTHS(P_BGN_DATE,1),'MM'),1,0)  * DECODE(DB_CR_FLG, 'D', 1, 1) * NVL(CURR_VAL, 0)) AS MON02,
              (DECODE(TO_CHAR(DOC_DATE,'MM'),TO_CHAR(ADD_MONTHS(P_BGN_DATE,2),'MM'),1,0)   * DECODE(DB_CR_FLG, 'D', 1, 1) * NVL(CURR_VAL, 0)) AS MON03,
              (DECODE(TO_CHAR(DOC_DATE,'MM'), TO_CHAR(ADD_MONTHS(P_BGN_DATE,3),'MM'),1,0)  * DECODE(DB_CR_FLG, 'D', 1, 1) * NVL(CURR_VAL, 0)) AS MON04,
              (DECODE(TO_CHAR(DOC_DATE,'MM'), TO_CHAR(ADD_MONTHS(P_BGN_DATE,4),'MM'),1,0)  * DECODE(DB_CR_FLG, 'D', 1, 1) * NVL(CURR_VAL, 0)) AS MON05,
              (DECODE(TO_CHAR(DOC_DATE,'MM'),TO_CHAR(ADD_MONTHS(P_BGN_DATE,5),'MM'),1,0)   * DECODE(DB_CR_FLG, 'D', 1, 1) * NVL(CURR_VAL, 0)) AS MON06,
              (DECODE(TO_CHAR(DOC_DATE,'MM'), TO_CHAR(ADD_MONTHS(P_BGN_DATE,6),'MM'),1,0)  * DECODE(DB_CR_FLG, 'D', 1,1) * NVL(CURR_VAL, 0))  AS MON07,
              (DECODE(TO_CHAR(DOC_DATE,'MM'), TO_CHAR(ADD_MONTHS(P_BGN_DATE,7),'MM'),1,0)  * DECODE(DB_CR_FLG, 'D', 1,1) * NVL(CURR_VAL, 0))  AS MON08,
              (DECODE(TO_CHAR(DOC_DATE,'MM'), TO_CHAR(ADD_MONTHS(P_BGN_DATE,8),'MM'),1,0)  * DECODE(DB_CR_FLG, 'D', 1, 1) * NVL(CURR_VAL, 0)) AS MON09,
              (DECODE(TO_CHAR(DOC_DATE,'MM'),TO_CHAR(ADD_MONTHS(P_BGN_DATE,9),'MM'),1,0 )  * DECODE(DB_CR_FLG, 'D', 1, 1) * NVL(CURR_VAL, 0)) AS MON10,
              (DECODE(TO_CHAR(DOC_DATE,'MM'), TO_CHAR(ADD_MONTHS(P_BGN_DATE,10),'MM'),1,0) * DECODE(DB_CR_FLG, 'D', 1, 1) * NVL(CURR_VAL, 0)) AS MON11,
              (DECODE(TO_CHAR(DOC_DATE,'MM'), TO_CHAR(ADD_MONTHS(P_BGN_DATE,11),'MM'),1,0) * DECODE(DB_CR_FLG, 'D', 1,1) * NVL(CURR_VAL, 0))  AS MON12
            FROM
              (SELECT XN_DOC_NUM ,
                CURR_VAL,
                DB_CR_FLG,
                DOC_DATE
              FROM
                (SELECT SUBSTR(CONTR_NUM,1,6)
                  ||'0'
                  ||SUBSTR(CONTR_NUM,8,6) CONTR_NUM
                FROM T_CONTRACTS
                WHERE CONTR_DT BETWEEN P_BGN_DATE AND P_END_DATE
                AND SUBSTR(CONTR_NUM,6,1) = 'I'
                AND RECORD_SOURCE        IN ( 'IC','CG')
                AND CONTR_STAT           <> 'C'
                ) A,
                T_ACCOUNT_LEDGER B
              WHERE A.CONTR_NUM = B.XN_DOC_NUM
              AND B.GL_ACCT_CD  = V_GLA_KOMISI
              AND B.DOC_DATE BETWEEN P_BGN_DATE AND P_END_DATE
              AND B.APPROVED_STS = 'A'
              )
            )
          ) C
        UNION
        SELECT V.GL_ACCT_GROUP,
          V.GL_ACCT_GROUP_NAME,
          V.GL_A                     AS GL_ACCT_CD,
          V.MAIN_ACCT_NAME           AS GL_ACCT_NAME,
          TRIM(V.ACCT_CD_2)          AS SL_ACCT_CD,
          V.ACCT_NAME                AS SL_ACCT_NAME,
          NVL(A.MON01, 0) * V.FAKTOR AS MON01,
          NVL(A.MON02, 0) * V.FAKTOR AS MON02,
          NVL(A.MON03, 0) * V.FAKTOR AS MON03,
          NVL(A.MON04, 0) * V.FAKTOR AS MON04,
          NVL(A.MON05, 0) * V.FAKTOR AS MON05,
          NVL(A.MON06, 0) * V.FAKTOR AS MON06,
          NVL(A.MON07, 0) * V.FAKTOR AS MON07,
          NVL(A.MON08, 0) * V.FAKTOR AS MON08,
          NVL(A.MON09, 0) * V.FAKTOR AS MON09,
          NVL(A.MON10, 0) * V.FAKTOR AS MON10,
          NVL(A.MON11, 0) * V.FAKTOR AS MON11,
          NVL(A.MON12, 0) * V.FAKTOR AS MON12,
          V.LR_FAKTOR
        FROM
          (SELECT * FROM TMP_TAL_PL_BRANCH WHERE RAND_VALUE=V_RANDOM_VALUE AND USER_ID=P_USER_ID) A,
          (SELECT GL_ACCT_GROUP,
            GL_ACCT_GROUP_NAME,
            GL_A,
            MAIN_ACCT_NAME,
            ACCT_CD_2,
            ACCT_NAME,
            FAKTOR,
            LR_FAKTOR
          FROM V_LABARUGI_ACCT_APR2013
          WHERE GL_A LIKE '5%'
          AND ACCT_PREFIX = '10'
          UNION
          SELECT DISTINCT GL_ACCT_GROUP,
            GL_ACCT_GROUP_NAME,
            GL_A,
            MAIN_ACCT_NAME,
            ACCT_CD_2,
            MAIN_ACCT_NAME,
            FAKTOR,
            LR_FAKTOR
          FROM V_LABARUGI_ACCT_APR2013
          WHERE GL_A LIKE '6%'
          AND ACCT_PREFIX <> '00'
          AND FAKTOR      <> -0.5
          ) V
        WHERE A.ACCT_CD(+)= V.ACCT_CD_2
        AND (A.MON01     <> 0
        OR A.MON02       <> 0
        OR A.MON03       <> 0
        OR A.MON04       <> 0
        OR A.MON05       <> 0
        OR A.MON06       <> 0
        OR A.MON07       <> 0
        OR A.MON08       <> 0
        OR A.MON09       <> 0
        OR A.MON10       <> 0
        OR A.MON11       <> 0
        OR A.MON12       <> 0)
        )
      ORDER BY 1 ASC,
        2 ASC,
        3 ASC,
        4 ASC,
        5 ASC,
        7 ASC;
    EXCEPTION
    WHEN OTHERS THEN
      V_ERROR_CD  := -60;
      V_ERROR_MSG := SUBSTR('INSERT INTO R_PROFIT_LOSS_BRANCH '||SQLERRM(SQLCODE),1,200);
      RAISE V_err;
    END;

    --UPDATE LINE TOTAL
    V_SQL :='UPDATE R_PROFIT_LOSS_BRANCH SET LINE_TOTAL = ';
    V_STR :='';
        FOR I IN P_BGN_MON..P_END_MON LOOP
              IF I =1 THEN
                 V_STR := 'MON'||TO_CHAR(I,'FM00');
              ELSE
                  V_STR :=V_STR ||' + '||' MON' ||TO_CHAR(I,'FM00');
              END IF;
        END LOOP;
        
      V_SQL :=V_SQL||V_STR || ' WHERE RAND_VALUE ='''||V_RANDOM_VALUE||''' AND USER_ID = '''||P_USER_ID||''' ';

   BEGIN
    EXECUTE IMMEDIATE V_SQL;
  EXCEPTION
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR(-20100,'EXECUTE IMMEDIATE UPDATE R_PROFIT_LOSS_BRANCH ' ||SQLERRM);
  END;



  END IF;
  ----------------------END ALL BRANCHES--------------------------------
  --------------------EXPENSES-----------------------
  IF P_BRANCH_FLG ='EXPENSE' THEN

BEGIN
    SP_RPT_REMOVE_RAND('R_PROFIT_LOSS_BRANCH_EXP',V_RANDOM_VALUE,V_ERROR_MSG,V_ERROR_CD);
  EXCEPTION
  WHEN OTHERS THEN
    V_ERROR_CD  := -10;
    V_ERROR_MSG := SUBSTR('SP_RPT_REMOVE_RAND '||V_ERROR_MSG||SQLERRM(SQLCODE),1,200);
    RAISE V_err;
  END;

    ---BIND VARIABLE
    V_END_DATE_LAST_MON :=last_day(P_END_DATE  -TO_CHAR(P_END_DATE,'DD'));
    V_BGN_DATE_LAST_MON := V_END_DATE_LAST_MON - TO_CHAR(V_END_DATE_LAST_MON,'DD')+1;
    V_BGN_BAL_DATE      :=P_BGN_DATE;
    V_BGN_DATE          :=P_END_DATE- TO_CHAR(P_END_DATE,'DD')+1;
    ------------------------------------------------------------------------------------
    BEGIN
      INSERT
      INTO R_PROFIT_LOSS_BRANCH_EXP
        (
          BRANCH_SHORT ,
          BRANCH_NAME ,
          BRANCH_CD ,
          TGL_ACCT_CD ,
          TSL_ACCT_CD ,
          ACCT_NAME ,
          CURRENT_MON ,
          LAST_MON ,
          UPTO_CURR_MON ,
          USER_ID ,
          RAND_VALUE ,
          GENERATE_DATE ,
          AS_AT,
          MACCT_NAME
        )
      SELECT P.BRCH_CD BRANCH_SHORT,
        P.BRCH_NAME BRANCH_NAME,
        SUBSTR(M.SL_A,1,2) BRANCH_CD,
        TRIM(M.GL_A) TGL_ACCT_CD,
        TRIM(M.SL_A) TSL_ACCT_CD,
        M.ACCT_NAME,
        NVL(A1.DEB_CURR,0) - NVL(A1.CRE_CURR,0) CURRENT_MON,
        NVL(B1.DEB_LAST,0) - NVL(B1.CRE_LAST,0)LAST_MON,
        NVL(D1.DEB_OBAL,0) - NVL(D1.CRE_OBAL, 0) + NVL(C1.DEB_TODT,0) - NVL(C1.CRE_TODT, 0) + NVL(A1.DEB_CURR,0) - NVL(A1.CRE_CURR,0) UPTO_CURR_MON,
        P_USER_ID,
        V_RANDOM_VALUE,
        P_GENERATE_DATE,
        P_END_DATE,
        DECODE(SUBSTR(M.GL_A,1,2),53,'BIAYA UMUM / ADM',M2.ACCT_NAME) MACCT_NAME
      FROM
        (SELECT A.GL_ACCT_CD,
          A.SL_ACCT_CD,
          SUM(DECODE(A.DB_CR_FLG,'D',NVL(A.CURR_VAL,0),0)) DEB_CURR,
          SUM(DECODE(A.DB_CR_FLG,'C',NVL(A.CURR_VAL,0),0)) CRE_CURR
        FROM T_ACCOUNT_LEDGER A
        WHERE ( A.GL_ACCT_CD  like '52%' OR  A.GL_ACCT_CD  like '53%')
        AND A.DOC_DATE BETWEEN V_BGN_DATE AND P_END_DATE
        AND A.APPROVED_STS ='A'
        GROUP BY A.GL_ACCT_CD,
          A.SL_ACCT_CD
        ) A1,
        (SELECT B.GL_ACCT_CD,
          B.SL_ACCT_CD,
          SUM(DECODE(B.DB_CR_FLG,'D',NVL(B.CURR_VAL,0),0)) DEB_LAST,
          SUM(DECODE(B.DB_CR_FLG,'C',NVL(B.CURR_VAL,0),0)) CRE_LAST
        FROM T_ACCOUNT_LEDGER B
       WHERE ( b.GL_ACCT_CD  like '52%' OR  b.GL_ACCT_CD  like '53%')
        AND B.DOC_DATE BETWEEN V_BGN_DATE_LAST_MON AND V_END_DATE_LAST_MON
        AND B.APPROVED_STS ='A'
        GROUP BY B.GL_ACCT_CD,
          B.SL_ACCT_CD
        ) B1,
        (SELECT C.GL_ACCT_CD,
          C.SL_ACCT_CD,
          SUM(DECODE(C.DB_CR_FLG,'D',NVL(C.CURR_VAL,0),0)) DEB_TODT,
          SUM(DECODE(C.DB_CR_FLG,'C',NVL(C.CURR_VAL,0),0)) CRE_TODT
        FROM T_ACCOUNT_LEDGER C
       WHERE ( c.GL_ACCT_CD  like '52%' OR  c.GL_ACCT_CD  like '53%')
        AND C.DOC_DATE BETWEEN V_BGN_BAL_DATE AND (V_BGN_DATE -1)
        AND C.APPROVED_STS ='A'
        GROUP BY C.GL_ACCT_CD,
          C.SL_ACCT_CD
        ) C1,
        (SELECT D.GL_ACCT_CD,
          D.SL_ACCT_CD,
          D.DEB_OBAL,
          D.CRE_OBAL
        FROM T_DAY_TRS D
        WHERE D.TRS_DT = V_BGN_BAL_DATE
        AND (SUBSTR(D.GL_ACCT_CD,1,2) BETWEEN '52' AND '53')
        ) D1,
        MST_GL_ACCOUNT M,
        (SELECT GL_A,SL_A,ACCT_NAME FROM MST_GL_ACCOUNT WHERE SL_A='000000') M2,--04AUG2016
        ( SELECT BRCH_CD , BRCH_NAME , ACCT_PREFIX FROM MST_BRANCH WHERE APPROVED_STAT='A'
        UNION
        SELECT 'ZI' BRCH_CD , 'FIXED INCOME' BRCH_NAME , '90' ACCT_PREFIX FROM DUAL
        ) P
      WHERE M.GL_A=M2.GL_A(+) --04AUG2016
       AND ( m.GL_ACCT_CD  like '52%' OR  m.GL_ACCT_CD  like '53%')
      AND M.PRT_TYPE   <> 'S'
      AND M.GL_A        = A1.GL_ACCT_CD (+)
      AND M.SL_A        = A1.SL_ACCT_CD (+)
      AND M.GL_A        = B1.GL_ACCT_CD (+)
      AND M.SL_A        = B1.SL_ACCT_CD (+)
      AND M.GL_A        = C1.GL_ACCT_CD (+)
      AND M.SL_A        = C1.SL_ACCT_CD (+)
      AND M.GL_A        = D1.GL_ACCT_CD (+)
      AND M.SL_A        = D1.SL_ACCT_CD (+)
      AND P.ACCT_PREFIX = SUBSTR(TRIM(M.SL_A),1,2)
      ORDER BY M.GL_A,
        M.SL_A ;
    EXCEPTION
    WHEN OTHERS THEN
      V_ERROR_CD  := -70;
      V_ERROR_MSG := SUBSTR('INSERT INTO R_PROFIT_LOSS_BRANCH_EXP '||SQLERRM(SQLCODE),1,200);
      RAISE V_err;
    END;
  END IF;
--DELETE TABLE TEMP
DELETE FROM TMP_CTR_PL_BRANCH WHERE RAND_VALUE=V_RANDOM_VALUE AND USER_ID=P_USER_ID;
DELETE FROM TMP_TAL_PL_BRANCH WHERE RAND_VALUE=V_RANDOM_VALUE AND USER_ID=P_USER_ID;

  P_RANDOM_VALUE := v_random_value;
  P_ERROR_CD     := 1 ;
  P_ERROR_MSG    := '';
EXCEPTION
WHEN V_ERR THEN
  ROLLBACK;
  P_ERROR_MSG := V_ERROR_MSG;
  P_ERROR_CD  := V_ERROR_CD;
WHEN OTHERS THEN
  P_ERROR_CD  := -1 ;
  P_ERROR_MSG := SUBSTR(SQLERRM(SQLCODE),1,200);
  RAISE;
END SPR_PROFIT_LOSS_BRANCH;