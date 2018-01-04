create or replace FUNCTION F_APP_RUNNING_STS(
        P_MENU_NAME     VARCHAR2,
        P_RUNNING_CHECK VARCHAR2,
        P_DSTR1         VARCHAR2,
        P_DSTR2         VARCHAR2,
        P_DNUM1         NUMBER,
        P_DNUM2         NUMBER,
        P_DDATE1        DATE,
        P_DDATE2        DATE,
        P_STATUS        VARCHAR2)
    RETURN VARCHAR2
AS
    PRAGMA AUTONOMOUS_TRANSACTION;
    V_STATUS     VARCHAR2(1) ;
    V_CNT        NUMBER;
    V_DUMMY_DATE DATE := TO_DATE('01-01-1999', 'DD-MM-YYYY') ;
BEGIN

     SELECT     COUNT(1)
           INTO V_CNT
           FROM APP_RUNNING_STATUS
          WHERE MENU_NAME                 = P_MENU_NAME
            AND RUNNING_CHECK             = P_RUNNING_CHECK
            AND NVL(DSTR1, 'X')           = NVL(P_DSTR1, 'X')
            AND NVL(DSTR2, 'X')           = NVL(P_DSTR2, 'X')
            AND NVL(DNUM1, 0)             = NVL(P_DNUM1, 0)
            AND NVL(DNUM2, 0)             = NVL(P_DNUM2, 0)
            AND NVL(DDATE1, V_DUMMY_DATE) = NVL(P_DDATE1, V_DUMMY_DATE)
            AND NVL(DDATE2, V_DUMMY_DATE) = NVL(P_DDATE2, V_DUMMY_DATE)
            AND STATUS                    = P_STATUS;

    IF V_CNT      > 0 THEN
        V_STATUS := 'Y';

        RETURN V_STATUS;

    END IF;

IF P_STATUS = 'Y' THEN

     INSERT
           INTO APP_RUNNING_STATUS
            (
                MENU_NAME, RUNNING_CHECK, DSTR1, DSTR2, DNUM1, DNUM2, DDATE1, DDATE2, STATUS, BGN_TIMESTAMP
            )
            VALUES
            (
                P_MENU_NAME, P_RUNNING_CHECK, P_DSTR1, P_DSTR2, P_DNUM1, P_DNUM2, P_DDATE1, P_DDATE2, P_STATUS, SYSDATE
            ) ;

    V_STATUS := 'N';
    COMMIT;

ELSE

     DELETE
           FROM APP_RUNNING_STATUS
          WHERE MENU_NAME                 = P_MENU_NAME
            AND RUNNING_CHECK             = P_RUNNING_CHECK
            AND NVL(DSTR1, 'X')           = NVL(P_DSTR1, 'X')
            AND NVL(DSTR2, 'X')           = NVL(P_DSTR2, 'X')
            AND NVL(DNUM1, 0)             = NVL(P_DNUM1, 0)
            AND NVL(DNUM2, 0)             = NVL(P_DNUM2, 0)
            AND NVL(DDATE1, V_DUMMY_DATE) = NVL(P_DDATE1, V_DUMMY_DATE)
            AND NVL(DDATE2, V_DUMMY_DATE) = NVL(P_DDATE2, V_DUMMY_DATE)
            AND STATUS                    = 'Y';
    COMMIT;
    V_STATUS := 'N';

END IF;

RETURN V_STATUS;

EXCEPTION

WHEN NO_DATA_FOUND THEN
    NULL;

WHEN OTHERS THEN
    RAISE;
    ROLLBACK;

END F_APP_RUNNING_STS;