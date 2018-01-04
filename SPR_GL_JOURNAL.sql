create or replace 
PROCEDURE  SPR_GL_JOURNAL(
						 p_bgn_dt date,
						 p_end_dt date,
						 p_status char,
						vp_doc_num 			DOCNUM_ARRAY,
            p_bgn_file_no varchar2,
            p_end_file_no varchar2,
						 vp_userid			VARCHAR2,
						 vp_generate_date 	DATE,
						 vo_random_value out NUMBER,
						 vo_errcd	 		OUT NUMBER,
						 vo_errmsg	 		OUT VARCHAR2
) IS
  vl_random_value	NUMBER(10);
  vl_err			EXCEPTION;
  v_errmsg varchar(200);
  v_errcd number(5);
BEGIN

       

   vl_random_value := abs(dbms_random.random);
    BEGIN
        SP_RPT_REMOVE_RAND('R_LIST_OF_JOURNAL', vl_random_value,vo_errcd,vo_errmsg);
    EXCEPTION
        WHEN OTHERS THEN
            v_errcd := -2;
            v_errmsg := SQLERRM(SQLCODE);
            RAISE vl_err;
    END;
    
    	FOR i IN 1..vp_doc_num.count LOOP
    
 
    
if p_status = 'A' or p_status = 'C' then
	BEGIN
	INSERT INTO R_LIST_OF_JOURNAL(SORTK,NORUT, DOC_DATE, XN_DOC_NUM, TAL_ID, GL_ACCT_CD,
				SL_ACCT_CD, DB_CR_FLG, CUR_VAL, LEDGER_NAR, USER_ID,
				CRE_DT,APPROVED_STATUS, APPROVED_BY, FOLDER_CD, ACCT_NAME,
				RPT_USER_ID, GENERATE_DATE, RAND_VALUE, RECORD_SOURCE,doc_num)
	 SELECT  h.sortk, h.norut, a.DOC_DATE, a.XN_DOC_NUM, a.TAL_ID,  TRIM(a.GL_ACCT_CD),  
         TRIM(a.SL_ACCT_CD), a.DB_CR_FLG, a.CURR_VAL, a.LEDGER_NAR, a.USER_ID,   			
         a.CRE_DT, h.APPROVED_STS, a.APPROVED_BY, a.FOLDER_CD, m.ACCT_NAME,
		 vp_userid, vp_generate_date ,vl_random_value, A.RECORD_SOURCE, decode(norut,2,a.xn_doc_num,a.reversal_jur) doc_num
    FROM			
	( SELECT b.norut,  sortk,  jvch_num sortk2, DECODE(norut, 1, jvch_num, reversal_jur) doc_num, approved_sts		
      FROM( 
      SELECT '04'||folder_Cd sortk,  jvch_num, reversal_jur, approved_sts			
			FROM T_JVCHH WHERE jvch_num = vp_doc_num(i) 
      -- jvch_date BETWEEN p_bgn_dt AND p_end_dt
		--	AND 
      --approved_sts = p_status
			UNION
			SELECT '03'||SUBSTR(payrec_type,1)||folder_cd, payrec_num, reversal_jur, approved_sts
			FROM T_PAYRECH
			WHERE  payrec_num = vp_doc_num(i)
      --payrec_date BETWEEN p_bgn_dt AND p_end_dt
			--AND
      --approved_sts = p_status
			UNION
			SELECT '01'||client_Cd||SUBSTR(contr_num,5,1)||stk_cd,
			  DECODE(SUBSTR(contr_num,6,1),'I', SUBSTR(contr_num,1,6)||'0'||SUBSTR(contr_num, 8), contr_num) AS contr_num, 
			  reversal_jur, approved_stat
			FROM T_CONTRACTS WHERE --contr_dt BETWEEN p_bgn_dt AND p_end_dt
			--AND
      ( contr_stat = p_status OR (contr_stat <> 'C'  AND p_status ='A'))
        AND  DECODE(SUBSTR(contr_num,6,1),'I', SUBSTR(contr_num,1,6)||'0'||SUBSTR(contr_num, 8), contr_num)=vp_doc_num(i)
			UNION
			SELECT '02'||trx_id_yymm||TO_CHAR(trx_seq_no,'99'), doc_num, reversal_doc_num, approved_sts
			FROM t_bond_trx WHERE  doc_num = vp_doc_num(i)
      --trx_date BETWEEN p_bgn_dt AND p_end_dt
			--AND 
      --approved_sts = p_status
			UNION
			SELECT   '05'||sl_acct_cd, dncn_num, reversal_jur, approved_sts
			FROM T_DNCNH WHERE  dncn_num=vp_doc_num(i)
      -- dncn_date BETWEEN p_bgn_dt AND p_end_dt
			--AND
      --approved_sts = p_status 
      ) a,
			( SELECT 1 norut FROM  dual
			  UNION
			  SELECT 2 norut FROM dual WHERE p_status = 'C' ) b
			  --WHERE  INSTR(vp_doc_num(i), a.jvch_num) > 0
			--ORDER BY doc_num, sortk, sortk2, norut
      ) h,
 	T_ACCOUNT_LEDGER a, MST_GL_ACCOUNT m  		
WHERE h.doc_num = a.xn_doc_num --AND a.DOC_DATE BETWEEN p_bgn_dt AND p_end_dt			
  AND  a.SL_ACCT_CD = m.SL_A AND a.GL_ACCT_CD = m.GL_A
ORDER BY doc_num , norut, a.TAL_ID;		
	
	 EXCEPTION
        WHEN OTHERS THEN
            v_errcd := -3;
            v_errmsg := 'INSERT R_LIST_OF_JOURNAL' ||substr(SQLERRM,1,200);
            RAISE vl_err;
    END;
	
	
	ELSE --UNTUK  BELUM DIAPPROVE
	
  
	BEGIN
	INSERT INTO R_LIST_OF_JOURNAL(SORTK,NORUT, DOC_DATE, XN_DOC_NUM, TAL_ID, GL_ACCT_CD,
				SL_ACCT_CD, DB_CR_FLG, CUR_VAL, LEDGER_NAR, USER_ID,
				CRE_DT,APPROVED_STATUS, APPROVED_BY, FOLDER_CD, ACCT_NAME,
				RPT_USER_ID, GENERATE_DATE, RAND_VALUE,RECORD_SOURCE)
				
	select NULL, A.NORUT, A.DOC_DATE, A.XN_DOC_NUM, A.TAL_ID, TRIM(A.GL_ACCT_CD),
	TRIM(A.SL_ACCT_CD), A.DB_CR_FLG, A.CURR_VAL, A.LEDGER_NAR, A.USER_ID,
	a.cre_dt, A.APPROVED_STATUS,A.APPROVED_BY, A.FOLDER_CD, M.ACCT_NAME, 
  vp_userid, vp_generate_date ,vl_random_value,RECORD_SOURCE
	from( SELECT NULL SORTK,
					(SELECT to_date(FIELD_VALUE,'yyyy/mm/dd hh24:mi:ss') FROM IPNEXTG.T_MANY_DETAIL DA 
					        WHERE DA.TABLE_NAME = 'T_ACCOUNT_LEDGER' 
					        AND DA.UPDATE_DATE = DD.UPDATE_DATE
					        AND DA.UPDATE_SEQ = DD.UPDATE_SEQ
					        AND DA.FIELD_NAME = 'DOC_DATE'
					        AND DA.RECORD_SEQ = DD.RECORD_SEQ)DOC_DATE, 
          (SELECT FIELD_VALUE FROM  IPNEXTG.T_MANY_DETAIL DA 
					        WHERE DA.TABLE_NAME = 'T_ACCOUNT_LEDGER' 
					        AND DA.UPDATE_DATE = DD.UPDATE_DATE
					        AND DA.UPDATE_SEQ = DD.UPDATE_SEQ
					        AND DA.FIELD_NAME = 'XN_DOC_NUM'
					        AND DA.RECORD_SEQ = DD.RECORD_SEQ) XN_DOC_NUM,
           (SELECT FIELD_VALUE FROM  IPNEXTG.T_MANY_DETAIL DA 
					        WHERE DA.TABLE_NAME = 'T_ACCOUNT_LEDGER' 
					        AND DA.UPDATE_DATE = DD.UPDATE_DATE
					        AND DA.UPDATE_SEQ = DD.UPDATE_SEQ
					        AND DA.FIELD_NAME = 'TAL_ID'
					        AND DA.RECORD_SEQ = DD.RECORD_SEQ) TAL_ID,
           (SELECT FIELD_VALUE FROM  IPNEXTG.T_MANY_DETAIL DA 
					        WHERE DA.TABLE_NAME = 'T_ACCOUNT_LEDGER' 
					        AND DA.UPDATE_DATE = DD.UPDATE_DATE
					        AND DA.UPDATE_SEQ = DD.UPDATE_SEQ
					        AND DA.FIELD_NAME = 'GL_ACCT_CD'
					        AND DA.RECORD_SEQ = DD.RECORD_SEQ) GL_ACCT_CD,
          (SELECT FIELD_VALUE FROM  IPNEXTG.T_MANY_DETAIL DA 
					        WHERE DA.TABLE_NAME = 'T_ACCOUNT_LEDGER' 
					        AND DA.UPDATE_DATE = DD.UPDATE_DATE
					        AND DA.UPDATE_SEQ = DD.UPDATE_SEQ
					        AND DA.FIELD_NAME = 'SL_ACCT_CD'
					        AND DA.RECORD_SEQ = DD.RECORD_SEQ) SL_ACCT_CD,
            (SELECT FIELD_VALUE FROM  IPNEXTG.T_MANY_DETAIL DA 
					        WHERE DA.TABLE_NAME = 'T_ACCOUNT_LEDGER' 
					        AND DA.UPDATE_DATE = DD.UPDATE_DATE
					        AND DA.UPDATE_SEQ = DD.UPDATE_SEQ
					        AND DA.FIELD_NAME = 'DB_CR_FLG'
					        AND DA.RECORD_SEQ = DD.RECORD_SEQ) DB_CR_FLG,
           (SELECT FIELD_VALUE FROM  IPNEXTG.T_MANY_DETAIL DA 
					        WHERE DA.TABLE_NAME = 'T_ACCOUNT_LEDGER' 
					        AND DA.UPDATE_DATE = DD.UPDATE_DATE
					        AND DA.UPDATE_SEQ = DD.UPDATE_SEQ
					        AND DA.FIELD_NAME = 'CURR_VAL'
					        AND DA.RECORD_SEQ = DD.RECORD_SEQ) CURR_VAL,
          (SELECT FIELD_VALUE FROM  IPNEXTG.T_MANY_DETAIL DA 
					        WHERE DA.TABLE_NAME = 'T_ACCOUNT_LEDGER' 
					        AND DA.UPDATE_DATE = DD.UPDATE_DATE
					        AND DA.UPDATE_SEQ = DD.UPDATE_SEQ
					        AND DA.FIELD_NAME = 'LEDGER_NAR'
					        AND DA.RECORD_SEQ = DD.RECORD_SEQ) LEDGER_NAR,
          (SELECT FIELD_VALUE FROM  IPNEXTG.T_MANY_DETAIL DA 
					        WHERE DA.TABLE_NAME = 'T_ACCOUNT_LEDGER' 
					        AND DA.UPDATE_DATE = DD.UPDATE_DATE
					        AND DA.UPDATE_SEQ = DD.UPDATE_SEQ
					        AND DA.FIELD_NAME = 'USER_ID'
					        AND DA.RECORD_SEQ = DD.RECORD_SEQ) USER_ID,
          (SELECT to_date(FIELD_VALUE,'yyyy/mm/dd hh24:mi:ss') FROM  IPNEXTG.T_MANY_DETAIL DA 
					        WHERE DA.TABLE_NAME = 'T_ACCOUNT_LEDGER' 
					        AND DA.UPDATE_DATE = DD.UPDATE_DATE
					        AND DA.UPDATE_SEQ = DD.UPDATE_SEQ
					        AND DA.FIELD_NAME = 'CRE_DT'
					        AND DA.RECORD_SEQ = DD.RECORD_SEQ) CRE_DT,      
                 'E' APPROVED_STATUS, ' ' APPROVED_BY,     
					(SELECT FIELD_VALUE FROM  IPNEXTG.T_MANY_DETAIL DA 
					        WHERE DA.TABLE_NAME = 'T_ACCOUNT_LEDGER' 
					        AND DA.UPDATE_DATE = DD.UPDATE_DATE
					        AND DA.UPDATE_SEQ = DD.UPDATE_SEQ
					        AND DA.FIELD_NAME = 'FOLDER_CD'
					        AND DA.RECORD_SEQ = DD.RECORD_SEQ) FOLDER_CD,
          (SELECT FIELD_VALUE FROM  IPNEXTG.T_MANY_DETAIL DA 
					        WHERE DA.TABLE_NAME = 'T_ACCOUNT_LEDGER' 
					        AND DA.UPDATE_DATE = DD.UPDATE_DATE
					        AND DA.UPDATE_SEQ = DD.UPDATE_SEQ
					        AND DA.FIELD_NAME = 'RECORD_SOURCE'
					        AND DA.RECORD_SEQ = DD.RECORD_SEQ) RECORD_SOURCE,
				 3 NORUT
					FROM IPNEXTG.T_MANY_DETAIL DD, IPNEXTG.T_MANY_HEADER HH 
          WHERE DD.TABLE_NAME = 'T_ACCOUNT_LEDGER' 
		AND HH.MENU_NAME IN ('GL JOURNAL ENTRY','UPLOAD MULTI JOURNAL','GENERATE OTC FEE JOURNAL','GENERATE REPO INTEREST JOURNAL')
          AND DD.UPDATE_DATE = HH.UPDATE_DATE
          AND DD.UPDATE_SEQ = HH.UPDATE_SEQ 
         AND DD.FIELD_NAME = 'DOC_DATE' AND HH.APPROVED_STATUS = 'E' 
         ORDER BY HH.UPDATE_SEQ ) A, ipnextg.mst_gl_account m
		 where trim(a.sl_acct_cd) = trim(m.sl_a) and trim(a.gl_acct_cd) = trim(m.gl_a)
     -- and doc_date between p_bgn_dt and p_end_dt
    --  and folder_cd between p_bgn_file_no AND p_end_file_no
      and xn_doc_num = vp_doc_num(i)
     order by FOLDER_CD;
	 EXCEPTION
        WHEN OTHERS THEN
            v_errcd := -4;
            v_errmsg := substr('INSERT R_LIST_OF_JOURNAL' ||SQLERRM,1,200);
            RAISE vl_err;
    END;		
	
	
	
	end if;
  	END LOOP;

    vo_random_value := vl_random_value;
    vo_errcd := 1;
    vo_errmsg := '';
  COMMIT;
EXCEPTION
	WHEN VL_ERR THEN
		vo_errcd := v_errcd;
        vo_errmsg := v_errmsg;
	  rollback;
    WHEN OTHERS THEN
        ROLLBACK;
        --vo_random_value := 0;
        vo_errcd := -1;
        vo_errmsg := SUBSTR(SQLERRM,1,200);
		raise;
END  SPR_GL_JOURNAL;