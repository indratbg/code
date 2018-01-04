
  CREATE OR REPLACE FORCE VIEW "IPNEXTG"."V_T_TC_DOC_INBOX" ("TC_ID", "TC_DATE", "TC_STATUS", "TC_REV", "CLIENT_CD", "CLIENT_NAME", "BRCH_CD", "REM_CD", "CRE_DT", "CRE_BY", "UPD_DT", "UPD_BY", "TC_TYPE", "TC_CLOB_IND", "TC_CLOB_ENG", "TC_MATRIX_IND", "TC_MATRIX_ENG", "UPDATE_DATE", "UPDATE_SEQ") AS 
  SELECT A."TC_ID",A."TC_DATE",A."TC_STATUS",A."TC_REV",A."CLIENT_CD",A."CLIENT_NAME",A."BRCH_CD",A."REM_CD",A."CRE_DT",A."CRE_BY",A."UPD_DT",A."UPD_BY",A."TC_TYPE",A."TC_CLOB_IND",A."TC_CLOB_ENG",A."TC_MATRIX_IND",A."TC_MATRIX_ENG",b.update_date, b.update_Seq FROM T_TC_DOC A,
(SELECT dd.record_seq, dd.upd_status,dd.update_date,dd.update_Seq,
		(SELECT TO_DATE(field_value,'YYYY/MM/DD HH24:MI:SS') FROM T_MANY_DETAIL da 
		        WHERE da.update_date = dd.update_date 
		        AND da.update_seq = dd.update_seq
		        AND da.table_name = 'T_TC_DOC'
		        AND da.field_name = 'TC_DATE'
		        AND da.record_seq = dd.record_seq) tc_date, 
		(SELECT field_value FROM T_MANY_DETAIL da 
		        WHERE da.update_date = dd.update_date 
		        AND da.update_seq = dd.update_seq
		        AND da.table_name = 'T_TC_DOC'
		        AND da.field_name = 'TC_ID'
		        AND da.record_seq = dd.record_seq) tc_id,
		(SELECT TO_NUMBER(field_value) FROM T_MANY_DETAIL da 
		        WHERE da.update_date = dd.update_date 
		        AND da.update_seq = dd.update_seq
		        AND da.table_name = 'T_TC_DOC'
		        AND da.field_name = 'TC_REV'
		        AND da.record_seq = dd.record_seq) tc_rev,
		(SELECT field_value FROM T_MANY_DETAIL da 
		        WHERE da.update_date = dd.update_date 
		        AND da.update_seq = dd.update_seq
		        AND da.table_name = 'T_TC_DOC'
		        AND da.field_name = 'CLIENT_CD'
		        AND da.record_seq = dd.record_seq) CLIENT_CD		
		FROM T_MANY_DETAIL dd ,T_MANY_HEADER X WHERE
      dd.update_seq=x.update_seq
      and dd.update_date=x.update_date
      and x.approved_status='E'
      and dd.table_name = 'T_TC_DOC' AND  dd.field_name IN ('TC_DATE')
) B
      WHERE  A.TC_DATE = B.TC_DATE
      AND A.CLIENT_CD = B.CLIENT_CD
      AND A.TC_ID= B.TC_ID
      AND A.TC_REV = B.TC_REV
      AND A.TC_STATUS='-1';
 
