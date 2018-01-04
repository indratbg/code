CREATE OR REPLACE
PROCEDURE SPR_MAP_MKBD( P_DATE DATE,
    P_SOURCE        VARCHAR2,
    P_USER_ID       VARCHAR2,
    P_GENERATE_DATE DATE,
    P_RANDOM_VALUE OUT NUMBER,
    P_ERRCD OUT NUMBER,
    P_ERRMSG OUT VARCHAR2 )
IS
  V_RANDOM_VALUE NUMBER(10);
  V_ERR          EXCEPTION;
  V_ERR_CD       NUMBER(10);
  V_ERR_MSG      VARCHAR2(200);
  
BEGIN

  V_RANDOM_VALUE := ABS(DBMS_RANDOM.RANDOM);
  BEGIN
    SP_RPT_REMOVE_RAND('R_MST_MAP_MKBD',V_RANDOM_VALUE,V_ERR_CD,V_ERR_MSG);
  EXCEPTION
  WHEN OTHERS THEN
    V_ERR_CD  := -2;
    V_ERR_MSG := SUBSTR('SP_RPT_REMOVE_RAND'||V_ERR_MSG,1,200);
    RAISE V_ERR;
  END;
  
  BEGIN
    INSERT
    INTO R_MST_MAP_MKBD
      (
        VER_BGN_DT,
        VER_END_DT,
        GL_A,
        MKBD_CD,
        SOURCE,
        USER_ID,
        RAND_VALUE,
        GENERATE_DATE
      )
    SELECT VER_BGN_DT,
      VER_END_DT,
      GL_A,
      MKBD_CD,
      SOURCE,
      P_USER_ID,
      V_RANDOM_VALUE,
      P_GENERATE_DATE
    FROM MST_MAP_MKBD
    WHERE SOURCE     = P_SOURCE
	AND P_DATE BETWEEN VER_BGN_DT AND VER_END_DT
    AND APPROVED_STAT='A';
  EXCEPTION
  WHEN NO_DATA_FOUND THEN
    V_ERR_CD  := -100;
    V_ERR_MSG :='NO DATA FOUND';
    RAISE V_ERR;
  WHEN OTHERS THEN
    V_ERR_CD  := -3;
    V_ERR_MSG := SQLERRM(SQLCODE);
    RAISE V_ERR;
  END;
  
  P_RANDOM_VALUE := V_RANDOM_VALUE;
  P_ERRCD        := 1;
  P_ERRMSG       := '';
  
EXCEPTION
WHEN V_ERR THEN
  ROLLBACK;
  P_ERRCD  := V_ERR_CD;
  P_ERRMSG := V_ERR_MSG;
WHEN OTHERS THEN
  ROLLBACK;
  P_ERRCD  := -1;
  P_ERRMSG := SUBSTR(SQLERRM(SQLCODE),1,200);
END SPR_MAP_MKBD;