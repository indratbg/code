--untuk isi doc ref di dev digunakan 'Y'
select dflg1 from mst_sys_param where param_id='GL_JOURNAL_ENTRY' and param_cd1='DOC_REF';

--untuk check dari branch yang sama, di dev digunakan 'Y'
select dflg1 from mst_sys_param where param_id='SYSTEM' and param_cd1='CHECK' AND PARAM_CD2='ACCTBRCH'