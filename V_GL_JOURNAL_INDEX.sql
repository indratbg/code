
  CREATE OR REPLACE FORCE VIEW "IPNEXTG"."V_GL_JOURNAL_INDEX" ("JVCH_DATE", "REMARKS", "FOLDER_CD", "JVCH_NUM", "USER_ID", "BUDGET_CD") AS 
  select DISTINCT  H.jvch_date, H.remarks, H.folder_Cd, H.jvch_num,H.USER_ID,d.budget_cd
from T_JVCHH h, T_account_ledger d
where H.approved_Sts ='A'
and H.jvch_type = 'GL'
and substr(H.jvch_num,8,3) not in ( 'DPR','MFE')
and H.jvch_num = d.xn_doc_num;
 
