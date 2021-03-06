
  CREATE OR REPLACE FORCE VIEW "IPNEXTG"."V_FUND_MOVEMENT_INBOX" ("USER_ID", "UPDATE_DATE", "STATUS", "IP_ADDRESS", "DOC_DATE","CLIENT_CD","TRX_TYPE","TRX_AMT","UPDATE_SEQ","APPROVED_STATUS","MENU_NAME","APPROVED_DATE") AS 
  SELECT HH.USER_ID, HH.UPDATE_DATE, HH.STATUS, HH.IP_ADDRESS,
(SELECT FIELD_VALUE FROM T_MANY_DETAIL DA 
        WHERE DA.TABLE_NAME = 'T_FUND_MOVEMENT' 
        AND DA.UPDATE_DATE = DD.UPDATE_DATE
        AND DA.UPDATE_SEQ = DD.UPDATE_SEQ
        AND DA.FIELD_NAME = 'DOC_DATE'
        AND DA.RECORD_SEQ = DD.RECORD_SEQ) DOC_DATE, 
(SELECT FIELD_VALUE FROM T_MANY_DETAIL DA 
        WHERE DA.TABLE_NAME = 'T_FUND_MOVEMENT' 
        AND DA.UPDATE_DATE = DD.UPDATE_DATE
        AND DA.UPDATE_SEQ = DD.UPDATE_SEQ
        AND DA.FIELD_NAME = 'CLIENT_CD'
        AND DA.RECORD_SEQ = DD.RECORD_SEQ) CLIENT_CD,
(SELECT FIELD_VALUE FROM T_MANY_DETAIL DA 
        WHERE DA.TABLE_NAME = 'T_FUND_MOVEMENT' 
        AND DA.UPDATE_DATE = DD.UPDATE_DATE
        AND DA.UPDATE_SEQ = DD.UPDATE_SEQ
        AND DA.FIELD_NAME = 'TRX_TYPE'
        AND DA.RECORD_SEQ = DD.RECORD_SEQ) TRX_TYPE,
(SELECT FIELD_VALUE FROM T_MANY_DETAIL DA 
        WHERE DA.TABLE_NAME = 'T_FUND_MOVEMENT' 
        AND DA.UPDATE_DATE = DD.UPDATE_DATE
        AND DA.UPDATE_SEQ = DD.UPDATE_SEQ
        AND DA.FIELD_NAME = 'TRX_AMT'
        AND DA.RECORD_SEQ = DD.RECORD_SEQ) TRX_AMT,HH.UPDATE_SEQ,HH.APPROVED_STATUS,HH.MENU_NAME,HH.APPROVED_DATE

FROM T_MANY_DETAIL DD, T_MANY_HEADER HH WHERE DD.TABLE_NAME = 'T_FUND_MOVEMENT' AND DD.UPDATE_DATE = HH.UPDATE_DATE
                      AND DD.UPDATE_SEQ = HH.UPDATE_SEQ AND DD.RECORD_SEQ = 1 AND DD.FIELD_NAME = 'DOC_DATE' AND HH.APPROVED_STATUS = 'E' ORDER BY HH.UPDATE_SEQ;
 
