create or replace FUNCTION F_GET_CASHFLOW_CATEGORY(P_CLIENT_CD VARCHAR2) RETURN VARCHAR2 IS

V_CL_DESC VARCHAR2(30);
V_CL_TYPE1 VARCHAR2(1);
V_CL_TYPE3 VARCHAR2(1);
V_CUSTODIAN_CD MST_CLIENT.CUSTODIAN_CD%TYPE;
BEGIN

        v_cl_desc := 'C';
        
        BEGIN
        SELECT CLIENT_TYPE_1,CLIENT_TYPE_3,CUSTODIAN_CD 
        INTO V_CL_TYPE1,V_CL_TYPE3,V_CUSTODIAN_CD
        FROM 
           (SELECT CLIENT_CD,CLIENT_TYPE_1,CLIENT_TYPE_3,CUSTODIAN_CD FROM MST_CLIENT  WHERE APPROVED_STAT='A' 
            UNION
            SELECT BROKER_CD,'B' CL_TYPE_1,'R' CL_TYPE_3,NULL FROM MST_BROKER
            ) A,
            V_BROKER_SUBREK B
        where CLIENT_CD=B.BROKER_CLIENT_CD(+)
        and B.BROKER_CLIENT_CD is null
         AND A.CLIENT_CD=P_CLIENT_CD;
         EXCEPTION
         WHEN NO_DATA_FOUND then 
                v_cl_desc := 'O';
         END;
    
        IF V_CL_DESC = 'C' then
            IF V_CUSTODIAN_CD IS NOT NULL AND V_CL_TYPE1='C'  AND V_CL_TYPE3 <> 'M'  THEN
                V_CL_DESC :='IR';
            ELSIF V_CUSTODIAN_CD IS NOT NULL AND V_CL_TYPE1='C'  AND V_CL_TYPE3 = 'M' THEN
                V_CL_DESC := 'IM';
            ELSIF V_CL_TYPE1='B' THEN
                V_CL_DESC :='B';
            ELSIF V_CL_TYPE3 = 'T' THEN
                V_CL_DESC := 'T';
            ELSIF V_CL_TYPE3 = 'M' THEN
                V_CL_DESC :='RM';
            ELSE
                V_CL_DESC :='RR';
            
            END IF;
        ELSE
            begin 
            select decode(jur_type,'KPEI','K','B') into V_CL_DESC
            from mst_gla_trx
            where jur_type in ('KPEI','BROK')
            and gl_a = P_CLIENT_CD;
             EXCEPTION
             WHEN NO_DATA_FOUND then 
                    v_cl_desc := 'O';
             END;
             
             IF P_CLIENT_CD = '1461' or P_CLIENT_CD = '2461' then
                  v_cl_desc := 'F';
              END IF;
              
              IF P_CLIENT_CD = '1201' then
                  v_cl_desc := 'D';
              END IF;
              
        END IF;
        


RETURN V_CL_DESC;
EXCEPTION
WHEN NO_DATA_FOUND THEN
NULL;
WHEN OTHERS THEN
RAISE;
END F_GET_CASHFLOW_CATEGORY;