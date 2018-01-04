create or replace 
FUNCTION  "F_ASSET_NUM" (p_asset_type mst_fixed_asset.asset_type%TYPE)
RETURN varchar as

ll_counter number;
as_tipe mst_fixed_asset.asset_type%TYPE;
ls_asset_cd mst_fixed_asset.asset_type%TYPE;

vl_err			EXCEPTION;
BEGIN
    as_tipe := substr(p_asset_type,1,1);
/*	
	select max(to_number(substr(t.asset_cd,2,6)))
		into   ll_counter	from mst_fixed_asset t
		where substr(t.asset_cd,1,1) = as_tipe;
		  
		if ll_counter = null or ll_counter = 0 then 
		ll_counter := 0;
		end if;
      ll_counter :=ll_counter + 1;
*/

		SELECT NVL(MAX(TO_NUMBER(ASSET_NO)),0)+1 INTO   LL_COUNTER FROM
		(
		SELECT SUBSTR(T.ASSET_CD,2,6)ASSET_NO
		From Mst_Fixed_Asset T
		WHERE SUBSTR(T.ASSET_CD,1,1) = as_tipe
		UNION
		SELECT SUBSTR(FIELD_VALUE,2,6) ASSET_NO
		FROM T_TEMP_DETAIL A, T_TEMP_HEADER B WHERE
		A.UPDATE_SEQ=B.UPDATE_SEQ
		AND A.UPDATE_DATE=B.UPDATE_DATE
		AND A.TABLE_NAME='MST_FIXED_ASSET' 
		And A.Field_Name='ASSET_CD'
		AND SUBSTR(FIELD_VALUE,1,1)=as_tipe
		);

	  
	  
    ls_asset_cd := as_tipe||LPAD(trunc(to_char(ll_counter, '000000')),6,'0') ;
 
    
      RETURN  ls_asset_cd;
	  EXCEPTION
     WHEN NO_DATA_FOUND THEN
       Null;
     WHEN OTHERS THEN
       -- Consider logging the error and then re-raise
       RAISE;
END F_ASSET_NUM;