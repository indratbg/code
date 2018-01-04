  CREATE OR REPLACE FORCE VIEW "IPNEXTG"."V_GENERATE_REPO_INTEREST" ("JVCH_DATE", "FOLDER_CD", "JVCH_NUM", "REMARKS") AS 
  select jvch_date, h.folder_Cd, jvch_num, remarks
from t_jvchh h, T_ACCOUNT_LEDGER d
where d.doc_date between sysdate - 40 and sysdate
and d.budget_cd = 'INTREPO'
and d.approved_sts = 'A'
and d.xn_doc_num = h.jvch_num
order by jvch_date desc;
 
