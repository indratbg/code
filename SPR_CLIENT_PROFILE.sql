create or replace PROCEDURE SPR_CLIENT_PROFILE(
    P_CLIENT_CD     VARCHAR2,
    P_USER_ID       VARCHAR2,
    P_GENERATE_DATE DATE,
    P_RANDOM_VALUE OUT NUMBER,
    P_ERROR_CD OUT NUMBER,
    P_ERROR_MSG OUT VARCHAR2)
IS
  V_ERROR_MSG    VARCHAR2(200) ;
  V_ERROR_CD     NUMBER(10) ;
  V_RANDOM_VALUE NUMBER(10) ;
  V_ERR          EXCEPTION; 
BEGIN

  v_random_value := ABS(dbms_random.random) ;
  
  BEGIN
    SP_RPT_REMOVE_RAND('R_CLIENT_PROFILE', V_RANDOM_VALUE, V_ERROR_MSG, V_ERROR_CD) ;
  EXCEPTION
  WHEN OTHERS THEN
    V_ERROR_CD  := - 10;
    V_ERROR_MSG := SUBSTR('SP_RPT_REMOVE_RAND '||V_ERROR_MSG||SQLERRM(SQLCODE), 1, 200) ;
    RAISE V_err;
  END;
  
  IF V_ERROR_CD  < 0 THEN
    V_ERROR_CD  := - 20;
    V_ERROR_MSG := SUBSTR('SP_RPT_REMOVE_RAND'||V_ERROR_MSG, 1, 200) ;
    RAISE V_ERR;
  END IF;
  
  BEGIN
     INSERT
         INTO R_CLIENT_PROFILE
        (
          STATUS, CL_DESC_2, CL_DESC_3, SUBREK001, SUBREK004, CLIENT_CD, SID, REM_CD, REM_NAME, RDI_NUM, CLIENT_TITLE, CIF_NAME, CIFS, SEX_DESC,
          MARITAL_DESC, NATIONALITY, CLIENT_BIRTH_DT, BIRTH_PLACE, RELIGION, IC_DESC, CLIENT_IC_NUM, IC_EXPIRY_DT, NPWP_NO,C_DEF_ADDR_1,C_DEF_ADDR_2, C_DEF_ADDR_3,
          DEF_ADDR_1, DEF_ADDR_2,DEF_ADDR_3,
          POST_CD, ID_ADDR, ID_KLURAHN, ID_RTRW, ID_KCAMATN, ID_KOTA, E_MAIL1, PHONE_NUM, HP_NUM, FAX_NUM, ACCT_OPEN_DT,CLOSED_DATE,BRANCH_CODE, BRCH_NAME, COMMISION, BANK_CD
          , BANK_NAME, BANK_ACCT_NUM, ACCT_NAME, DEFAULT_BANK, OCCUPATION, JOB_POSITION, EMERGENCY_NAME, EMERGENCY_ADDR1, EMERGENCY_ADDR2,
          EMERGENCY_ADDR3, EMERGENCY_HP, EMERGENCY_PHONE, EMERGENCY_POSTCD, EDUCATION, RESIDENCE, ANNUAL_INCOME, SOURCE_OF_FUNDS, ADDL_FUND, NET_ASSET
          , EMPR_NAME, EMPR_BIZ_TYPE, EMPR_ADDR_1, EMPR_ADDR_2, EMPR_ADDR_3, EMPR_POST_CD, EMPR_EMAIL, EMPR_PHONE, EMPR_FAX, SPOUSE_NAME, SPOUSE_OCCUP
          , SPOUSE_EMPR_NAME, SPOUSE_EMPR_ADDR1, SPOUSE_EMPR_ADDR2, SPOUSE_EMPR_ADDR3, SPOUSE_EMPR_POST_CD, OLD_IC_NUM, PURPOSE01, PURPOSE02,
          PURPOSE03, PURPOSE04, PURPOSE05, PURPOSE06, PURPOSE07, PURPOSE08, PURPOSE09, PURPOSE10, PURPOSE11, PURPOSE90, PURPOSE_LAINNYA, INST_TYPE_TXT,INDUSTRY,ACT_FIRST,
          ACT_FIRST_DT,ACT_LAST,ACT_LAST_DT, SIUP_NO, TDP_NO,BIZ_TYPE
          , OLT_STATUS, USER_ID, RAND_VALUE, GENERATE_DATE
        )
     SELECT   DECODE(A.SUSP_STAT, 'N', 'Active', 'C', 'Closed', 'Suspend') status, INITCAP(CL2.CL_DESC) CL_DESC_2, INITCAP(CL3.CL_DESC) CL_DESC_3, F_SUBREK(S.SUBREK001)
        SUBREK001, F_SUBREK(S.SUBREK004) SUBREK004, A.CLIENT_CD, F_SID(A.SID) SID, A.REM_CD, SALES.REM_NAME, RDI.BANK_ACCT_FMT RDI_NUM,
        CIF.CLIENT_TITLE, CIF.CIF_NAME, CIF.CIFS, GENDER.SEX_DESC, MARITL.MARITAL_DESC, INDI.NATIONALITY, CIF.CLIENT_BIRTH_DT, INDI.BIRTH_PLACE,
        RELI.RELIG_DESC RELIGION, IDTYPE.IC_DESC, CIF.CLIENT_IC_NUM, CIF.IC_EXPIRY_DT, F_FORMAT_NPWP(CIF.NPWP_NO) NPWP_NO, A.DEF_ADDR_1,A.DEF_ADDR_2,A.DEF_ADDR_3,
        CIF.DEF_ADDR_1,CIF.DEF_ADDR_2,CIF.DEF_ADDR_3, CIF.POST_CD, INDI.ID_ADDR, INDI.ID_KLURAHN, INDI.ID_RTRW, INDI.ID_KCAMATN, INDI.ID_KOTA, CIF.E_MAIL1, CIF.PHONE_NUM,
        CIF.HP_NUM, CIF.FAX_NUM, A.ACCT_OPEN_DT,A.CLOSED_DATE,MST_BRANCH.BRCH_CD, MST_BRANCH.BRCH_NAME, A.COMMISSION_PER / 100 COMMISION, CLIENT_BANK.BANK_CD, BANK.BANK_NAME,
        CLIENT_BANK.BANK_ACCT_NUM, CLIENT_BANK.ACCT_NAME, DECODE(A.BANK_ACCT_NUM, CLIENT_BANK.BANK_ACCT_NUM, 'Y', 'N') DEFAULT_BANK, INDI.OCCUPATION,
        INDI.JOB_POSITION, E.EMERGENCY_NAME, E.EMERGENCY_ADDR1, E.EMERGENCY_ADDR2, E.EMERGENCY_ADDR3, E.EMERGENCY_HP, E.EMERGENCY_PHONE,
        E.EMERGENCY_POSTCD, INDI.EDUCATION, INDI.RESIDENCE, CIF.ANNUAL_INCOME, CIF.SOURCE_OF_FUNDS, CIF.ADDL_FUND, CIF.NET_ASSET, INDI.EMPR_NAME,
        INDI.EMPR_BIZ_TYPE, INDI.EMPR_ADDR_1, INDI.EMPR_ADDR_2, INDI.EMPR_ADDR_3, INDI.EMPR_POST_CD, INDI.EMPR_EMAIL, INDI.EMPR_PHONE, INDI.EMPR_FAX,
        INDI.SPOUSE_NAME, INDI.SPOUSE_OCCUP, INDI.SPOUSE_EMPR_NAME, INDI.SPOUSE_EMPR_ADDR1, INDI.SPOUSE_EMPR_ADDR2, INDI.SPOUSE_EMPR_ADDR3,
        INDI.SPOUSE_EMPR_POST_CD, A.OLD_IC_NUM, CIF.PURPOSE01, CIF.PURPOSE02, CIF.PURPOSE03, CIF.PURPOSE04, CIF.PURPOSE05, CIF.PURPOSE06,
        CIF.PURPOSE07, CIF.PURPOSE08, CIF.PURPOSE09, CIF.PURPOSE10, CIF.PURPOSE11, CIF.PURPOSE90, CIF.PURPOSE_LAINNYA, CIF.INST_TYPE_TXT,INDUSTRY.INDUSTRY,
        cif.ACT_FIRST, cif.ACT_FIRST_DT,cif.ACT_LAST,cif.ACT_LAST_DT, cif.SIUP_NO,cif.TDP_NO,BIZTYP.BIZ_TYPE,
        CASE
          WHEN(A.OLT      = 'Y'
            AND a.rem_cd <> 'LOT')
            OR a.olt      = 'B'
          THEN 'Online with sales'
          WHEN a.olt = 'Y'
          THEN 'Online Trading'
          ELSE NULL
        END olt_status, P_USER_ID, V_RANDOM_VALUE, P_GENERATE_DATE
         FROM MST_CLIENT A, LST_TYPE1 CL1, LST_TYPE2 CL2, LST_TYPE3 CL3,(
           SELECT   prm_cd_2 relig_cd, prm_desc relig_desc
               FROM mst_parameter
              WHERE prm_cd_1    = 'RELIG'
              AND approved_stat = 'A'
        )
        reli,(
           SELECT   prm_cd_2 IC_TYPE, prm_desc IC_DESC
               FROM mst_parameter
              WHERE prm_cd_1    = 'IDTYPE'
              AND approved_stat = 'A'
        )
        IDTYPE,(
           SELECT   prm_cd_2 SEX_CD, prm_desc SEX_DESC
               FROM mst_parameter
              WHERE prm_cd_1    = 'GENDER'
              AND approved_stat = 'A'
        )
        GENDER,(
           SELECT   prm_cd_2 MARITAL_STATUS, prm_desc MARITAL_DESC
               FROM mst_parameter
              WHERE prm_cd_1    = 'MARITL'
              AND approved_stat = 'A'
        )
        MARITL,(
           SELECT   BANK_CD, BANK_NAME
               FROM MST_IP_BANK
              WHERE APPROVED_STAT = 'A'
        )
        BANK,
        (SELECT PRM_cD_2 INDUSTRY_CD, PRM_DESC INDUSTRY FROM MST_PARAMETER WHERE PRM_CD_1='INDUST')INDUSTRY,
        (select prm_cd_2 biz_cd,prm_desc biz_type from mst_parameter where prm_cd_1='BIZTYP')BIZTYP,
        MST_SALES SALES, MST_BRANCH, MST_CIF CIF, V_CLIENT_SUBREK14 s, MST_CLIENT_FLACCT RDI, MST_CLIENT_INDI INDI, MST_CLIENT_BANK CLIENT_BANK,
        MST_CLIENT_EMERGENCY E
        WHERE A.CLIENT_TYPE_1   = CL1.CL_TYPE1(+)
        AND A.CLIENT_TYPE_2     = CL2.CL_TYPE2(+)
        AND A.CLIENT_TYPE_3     = CL3.CL_TYPE3(+)
        AND A.RELIGION          = RELI.RELIG_CD(+)
        AND A.REM_CD            = SALES.REM_CD(+)
        AND TRIM(A.BRANCH_CODE) = MST_BRANCH.BRCH_CD(+)
        AND CIF.IC_TYPE         = IDTYPE.IC_TYPE(+)
        AND CIF.INDUSTRY_CD = INDUSTRY.INDUSTRY_CD(+)
        AND CIF.BIZ_TYPE = BIZTYP.biz_cd(+)
        AND A.APPROVED_STAT     = 'A'
        AND A.CIFS              = CIF.CIFS(+)
        AND A.CLIENT_CD         = S.CLIENT_CD(+)
        AND A.CLIENT_CD         = RDI.CLIENT_CD(+)
        AND A.CIFS              = INDI.CIFS(+)
        AND INDI.MARITAL_STATUS = MARITL.MARITAL_STATUS(+)
        AND RDI.ACCT_STAT(+)       = 'A'
        AND RDI.APPROVED_STAT(+)   = 'A'
        AND INDI.SEX_CODE       = GENDER.SEX_CD(+)
        AND A.CIFS              = CLIENT_BANK.CIFS(+)
        AND CLIENT_BANK.BANK_CD = BANK.BANK_CD(+)
        AND A.CIFS              = E.CIFS(+)
        AND A.CLIENT_CD         = P_CLIENT_CD;
  EXCEPTION
  WHEN OTHERS THEN
    V_ERROR_CD  := - 50;
    V_ERROR_MSG := SUBSTR('INSERT R_CLIENT_PROFILE '||SQLERRM(SQLCODE), 1, 200) ;
    RAISE V_err;
  END;
  
  ---INSERT CLIENT_CD WHICH USING CIFS
  BEGIN
    INSERT INTO R_CLIENT_PROFILE_CIFS
    (CLIENT_CD,CLIENT_TYPE_3,SUBREK001,STATUS, USER_ID,RAND_VALUE,GENERATE_DATE)
     SELECT A.CLIENT_CD, C.CL_DESC,F_SUBREK(B.SUBREK001)SUBREK001,DECODE(A.SUSP_STAT,'C','Closed',null) STATUS,P_USER_ID, V_RANDOM_VALUE, P_GENERATE_DATE FROM
     MST_CLIENT A, V_CLIENT_SUBREK14 B, LST_TYPE3 C
     WHERE A.CLIENT_CD=B.CLIENT_CD
     AND A.CLIENT_TYPE_3 = C.CL_TYPE3
     AND A.CIFS=(SELECT CIFS FROM R_CLIENT_PROFILE WHERE RAND_VALUE=V_RANDOM_VALUE AND USER_ID=P_USER_ID AND ROWNUM=1);
  EXCEPTION
  WHEN OTHERS THEN
    V_ERROR_CD  := - 55;
    V_ERROR_MSG := SUBSTR('INSERT R_CLIENT_PROFILE_CIFS '||SQLERRM(SQLCODE), 1, 200) ;
    RAISE V_err;
  END;
  
  
  
  
  P_RANDOM_VALUE := V_RANDOM_VALUE;
  P_ERROR_CD     := 1 ;
  P_ERROR_MSG    := '';
  
EXCEPTION
WHEN V_ERR THEN
  ROLLBACK;
  P_ERROR_MSG := V_ERROR_MSG;
  P_ERROR_CD  := V_ERROR_CD;
WHEN OTHERS THEN
  P_ERROR_CD  := - 1 ;
  P_ERROR_MSG := SUBSTR(SQLERRM(SQLCODE), 1, 200) ;
  RAISE;
END SPR_CLIENT_PROFILE;