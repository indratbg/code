create or replace FUNCTION F_GET_OUTS_AR_CLIENT (P_CLIENT_CD VARCHAR2, P_DUE_DATE DATE) RETURN number AS 

V_OUTS_AMT NUMBER;
V_GL_A VARCHAR2(4);
V_FROM_DATE DATE;
BEGIN


SELECT MAX(TRS_DT) INTO V_FROM_DATE FROM T_DAY_TRS WHERE TRS_DT<=P_DUE_DATE;

select DSTR1 INTO V_GL_A
    from mst_sys_param
    where param_id = 'AGING_MKBD51_103'
    and param_cd1 = 'GL_ACCT';

SELECT NVL(SUM(END_BAL),0) INTO V_OUTS_AMT
FROM
  (
    SELECT SUM(DECODE(A.DB_CR_FLG,'D',CURR_VAL,-CURR_VAL)) END_BAL
    FROM t_account_ledger a
    WHERE a.doc_date BETWEEN V_FROM_DATE AND P_DUE_DATE
    AND DUE_DATE<TRUNC(SYSDATE)
    AND trim(a.gl_acct_cd) = V_GL_A
    AND a.approved_sts     = 'A'
    AND a.sl_acct_cd =P_CLIENT_CD
    UNION ALL
    SELECT SUM(NVL(b.deb_obal,0) - NVL(b.cre_obal,0)) beg_bal
    FROM t_day_trs b
    WHERE b.trs_dt         = V_FROM_DATE
    AND trim(b.gl_acct_cd) = V_GL_A
    AND b.sl_acct_cd =P_CLIENT_CD
  );

RETURN V_OUTS_AMT;

EXCEPTION
WHEN NO_DATA_FOUND THEN
NULL;
WHEN OTHERS THEN
RAISE;
END F_GET_OUTS_AR_CLIENT;