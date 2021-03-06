create or replace PROCEDURE SP_INSERT_TMP_OTC(
    p_instruction_type VARCHAR2,
    P_DUE_DT           DATE,
    p_menu_name        VARCHAR2,
    P_ERROR_CODE OUT NUMBER,
    P_ERROR_MSG OUT VARCHAR2 )
IS
  V_ERR        EXCEPTION;
  V_ERROR_CODE NUMBER(5);
  V_ERROR_MSG  VARCHAR2(200);
BEGIN
  IF p_menu_name = 'OTC' OR p_menu_name ='SECTRS' THEN
    BEGIN
      INSERT
      INTO TMP_OTC
        (
          COL1 , COL2 , COL3 , COL4 , COL5 , COL6 , COL7 , COL8 , COL9 , COL10 , COL11 , COL12 , COL13 , COL14 , COL15 , COL16
        )
      SELECT TO_CHAR( p_due_dt, 'yyyymmdd') ||DECODE( p_instruction_type, 'SECTRS', '_MOVE', trim(RW)) ||'_' ||client_cd ||'_' ||stk_cd externalReference, 
      instruction_type instructiontype, broker_cd AS participantCode, subrek001 AS participantAccount, DECODE( p_instruction_type, 'SECTRS',broker_cd, custodian_cd) AS counterpartCode, 
      'LOCAL' securityCodeType, STK_CD AS securityCode, TO_CHAR(qty) AS numberOfSecurities, TO_CHAR( p_due_dt, 'yyyymmdd') AS tradeDate, 'IDR' AS currencyCode , 
      DECODE( p_instruction_type, 'RVP',TO_CHAR(amount) , 'DVP',TO_CHAR( amount ),'') settlementAmount, TO_CHAR( p_due_dt, 'yyyymmdd') AS settlementDate,
      'NONEXCHG' AS purpose , '' AS tradingReference, sett_reason AS settlementReason, description
      FROM
        (
          SELECT settle_Date, client_Cd, stk_Cd, qty, subrek001, DECODE( p_instruction_type ,'SECTRS','DFOP', p_instruction_type ) instruction_type, broker_cd,
          t.to_client AS client2, DECODE( p_instruction_type ,'SECTRS', t.client_cd ||' Deliver ' || stk_Cd ||' to ' ||to_client, DECODE(trim( beli_jual),'W', 'DELIVER TO ', 'RECEIVE FROM ') ||CUSTODIAN_CD) AS description, 
          custodian_cd, trim(beli_jual) RW, amount, t.sett_reason
          FROM
            (
              SELECT t.settle_Date , t.client_Cd, t.to_client, t.custodian_cd , stk_Cd, beli_jual, v.subrek001,t.sett_reason, SUM(qty) AS qty, SUM(NVL( amount,0)) AS amount
              FROM T_STK_OTC t, v_client_subrek14 v
              WHERE settle_Date       = p_due_dt
              AND qty                <> 0
              AND instruction_type    = p_instruction_type
              AND p_instruction_type IN ('SECTRS', 'DFOP', 'DVP' , 'RFOP', 'RVP')
              AND xml_flg             = 'Y'
              AND t.client_cd         = v.client_cd (+)
              GROUP BY t.settle_Date , t.client_Cd, t.to_client, t.custodian_cd , stk_Cd, beli_jual, v.subrek001, t.sett_reason
            )
            t, v_broker_subrek
          UNION ALL
          SELECT t.settle_Date, to_client, stk_Cd, qty, subrek001, 'RFOP' instruction_type, broker_cd, t.client_cd, to_client ||' Recv ' ||stk_Cd ||' from ' ||t.client_cd AS description,
          custodian_cd, trim(beli_jual) RW, amount, sett_reason
          FROM
            (
              SELECT t.settle_Date , t.client_Cd, t.to_client, t.custodian_cd , stk_Cd, beli_jual, v.subrek001,t.sett_reason, SUM(qty) AS qty, SUM(NVL( amount,0)) AS amount
              FROM T_STK_OTC t, v_client_subrek14 v
              WHERE settle_Date      = p_due_dt
              AND qty               <> 0
              AND instruction_type   = p_instruction_type
              AND p_instruction_type = 'SECTRS'
              AND xml_flg            = 'Y'
              AND t.to_client        = v.client_cd (+)
              GROUP BY t.settle_Date , t.client_Cd, t.to_client, t.custodian_cd , stk_Cd, beli_jual, v.subrek001,t.sett_reason
            )
            t, v_broker_subrek
        );
    EXCEPTION
    WHEN OTHERS THEN
      V_ERROR_CODE :=-10;
      V_ERROR_MSG  :=SUBSTR( 'INSERT INTO TMP_OTC ' || SQLERRM,1,200);
      RAISE V_ERR;
    END;
  END IF;
  IF P_MENU_NAME = 'VCA' THEN
    BEGIN
      INSERT
      INTO TMP_OTC
        (
          COL1 , COL2 , COL3 , COL4 , COL5 , COL6 , COL7 , COL8 , COL9 , COL10 , COL11
        )
      SELECT TO_CHAR( settle_date, 'ddmmyyyy') ||'_EXE_' ||client_cd externalReference, 'EXE' corporateActionType, TO_CHAR( eff_dt, 'yyyymmdd') AS effectiveDate,
      'LOCAL' securityCodeType, STK_CD AS securityCode, broker_cd AS participantCode, subrek001 AS participantAccount, 'DEFAULT' AS optionName, 
      TO_CHAR(qty) AS optionQuantity, '' additionalProceedRequest , 'EXE ' ||client_name AS description
      FROM
        (
          SELECT t.settle_Date, t.client_Cd, m.client_name, t.stk_Cd, v.subrek001, qty, broker_Cd , doc_num, ca.eff_dt
          FROM T_STK_OTC t, MST_CLIENT m, v_client_subrek14 v, v_broker_subrek, (
              SELECT t.stk_Cd, eff_dt
              FROM
                (
                  SELECT stk_cd, Get_Doc_Date (1, pp_from_dt ) AS distrib_dt
                  FROM mst_counter m
                  WHERE ctr_type   IN ('RT', 'WR')
                  AND pp_from_dt   IS NOT NULL
                  AND approved_stat = 'A'
                )
                m, t_corp_act t
              WHERE m.stk_cd      = t.stk_Cd
              AND m.distrib_dt    = t.distrib_dt
              AND t.approved_stat = 'A'
            )
            ca
          WHERE settle_Date      = P_DUE_DT
          AND qty               <> 0
          AND instruction_type   = 'EXERCS'
          AND p_instruction_type = 'EXE' --
            -- 23NOV2016
          AND xml_flg     = 'Y'
          AND t.client_cd = m.client_cd
          AND t.client_cd = v.client_cd(+)
          AND t.stk_Cd    = ca.stk_cd
        );
    EXCEPTION
    WHEN OTHERS THEN
      V_ERROR_CODE :=-15;
      V_ERROR_MSG  :=SUBSTR( 'INSERT INTO TMP_VCA ' || SQLERRM,1,200);
      RAISE V_ERR;
    END;
  END IF;
  P_ERROR_CODE:=1;
  P_ERROR_MSG :='';
EXCEPTION
WHEN V_ERR THEN
  ROLLBACK;
  P_ERROR_CODE :=V_ERROR_CODE ;
  P_ERROR_MSG  := V_ERROR_MSG;
WHEN OTHERS THEN
  ROLLBACK;
  P_ERROR_CODE :=-1;
  P_ERROR_MSG  :=SUBSTR( SQLERRM(SQLCODE),1,200);
END SP_INSERT_TMP_OTC;