create or replace 
FUNCTION "F_ASSET_NUM" (p_asset_type MST_FIXED_ASSET.asset_type%TYPE)
RETURN VARCHAR AS

ll_counter NUMBER;
as_tipe MST_FIXED_ASSET.asset_type%TYPE;
ls_asset_cd MST_FIXED_ASSET.asset_type%TYPE;

vl_err			EXCEPTION;
BEGIN
    as_tipe := SUBSTR(p_asset_type,1,1);
		SELECT MAX(TO_NUMBER(SUBSTR(t.asset_cd,2,6)))
		INTO   ll_counter	FROM MST_FIXED_ASSET t
		WHERE SUBSTR(t.asset_cd,1,1) = as_tipe;

		IF ll_counter = NULL OR ll_counter = 0 THEN
		ll_counter := 0;
		END IF;
      ll_counter :=ll_counter + 1;

    ls_asset_cd := as_tipe||LPAD(TRUNC(TO_CHAR(ll_counter, '000000')),6,'0') ;


      RETURN  ls_asset_cd;
	  EXCEPTION
     WHEN NO_DATA_FOUND THEN
       NULL;
     WHEN OTHERS THEN
       -- Consider logging the error and then re-raise
       RAISE;
END F_ASSET_NUM;
