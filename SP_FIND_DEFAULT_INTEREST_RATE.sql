create or replace PROCEDURE SP_FIND_DEFAULT_INTEREST_RATE(
    p_brch_cd mst_branch.brch_cd%type,
    p_client_type_3 mst_client.client_type_3%type,
    p_olt mst_client.olt%type,
    po_ar_rate OUT t_interest_rate.INT_ON_RECEIVABLE%type,
    po_ap_rate OUT t_interest_rate.INT_ON_PAYABLE%type,
    P_ERROR_CODE OUT NUMBER,
    P_ERROR_MSG OUT VARCHAR2)
IS
  /******************************************************************************
  NAME:       FIND_DEFAULT_INTEREST_RATE
  PURPOSE:
  REVISIONS:
  Ver        Date        Author           Description
  ---------  ----------  ---------------  ------------------------------------
  1.0        12/10/2011          1. Created this procedure.
  NOTES:
  Automatically available Auto Replace Keywords:
  Object Name:     FIND_DEFAULT_INTEREST_RATE
  Sysdate:         12/10/2011
  Date and Time:   12/10/2011, 11:40:25, and 12/10/2011 11:40:25
  Username:         (set in TOAD Options, Procedure Editor)
  Table Name:       (set in the New PL/SQL Object dialog)
  ******************************************************************************/
  v_prefix CHAR(1);
  v_client_cd mst_client.client_cd%type;
  v_nl CHAR(2);
  v_ar_rate t_interest_rate.INT_ON_RECEIVABLE%type;
  v_ap_rate t_interest_rate.INT_ON_PAYABLE%type;
  V_ERROR_CODE NUMBER(5);
  V_ERROR_MSG  VARCHAR2(200);
  V_ERR        EXCEPTION;
  
BEGIN

  v_nl                 := chr(10)||chr(13);
  
  IF p_client_type_3    = 'D' THEN
    v_prefix           := 'D';
  elsif p_client_type_3 = 'T' THEN
    v_prefix           := 'M';
  ELSE
    BEGIN
      SELECT margin_cd
      INTO v_prefix
      FROM lst_type3
      WHERE cl_type3 = p_client_type_3;
    EXCEPTION
    WHEN no_data_found THEN
      V_ERROR_CODE :=-10;
      V_ERROR_MSG  :=SUBSTR('Margin/ Regular LST_TYPE3 NOT FOUND '||p_client_type_3||v_nl||sqlerrm,1,200);
      RAISE V_ERR;
    WHEN OTHERS THEN
      V_ERROR_CODE :=-15;
      V_ERROR_MSG  :=SUBSTR('select Margin/ Regular LST_TYPE3 '||p_client_type_3||v_nl||sqlerrm,1,200);
      RAISE V_ERR;
    END;
  END IF;
  
  IF p_olt    = 'Y' THEN
    v_prefix := 'O';
  END IF;
  v_client_cd := trim(v_prefix)||'-'||p_brch_cd;
  BEGIN
    SELECT int_on_receivable, int_on_payable
    INTO v_ar_rate, v_ap_rate
    FROM t_interest_rate
    WHERE client_cd = v_client_cd
    AND eff_dt      =
      (
        SELECT MAX(eff_dt)
        FROM t_interest_rate
        WHERE client_Cd   = v_client_cd
        AND approved_stat = 'A'
      )
    AND approved_stat = 'A';
  EXCEPTION
  WHEN no_data_found THEN
    V_ERROR_CODE :=-20;
    V_ERROR_MSG  :=SUBSTR('DEFAULT INTEREST RATE NOT FOUND '||v_client_cd,1,200);
    RAISE V_ERR;
  WHEN OTHERS THEN
    V_ERROR_CODE :=-25;
    V_ERROR_MSG  :=SUBSTR('select T_INTEREST_RATE '||v_client_cd||v_nl||sqlerrm,1,200);
    RAISE V_ERR;
  END;
  
  po_ar_rate := v_ar_rate;
  po_ap_rate := v_ap_rate;
  
EXCEPTION
WHEN NO_DATA_FOUND THEN
  NULL;
WHEN V_ERR THEN
  P_ERROR_CODE:=V_ERROR_CODE;
  P_ERROR_MSG :=V_ERROR_MSG;
WHEN OTHERS THEN
  -- Consider logging the error and then re-raise
  P_ERROR_CODE:=-1;
  P_ERROR_MSG :=SUBSTR(sqlerrm,1,200);
  RAISE;
END SP_FIND_DEFAULT_INTEREST_RATE;