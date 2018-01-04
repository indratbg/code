
  CREATE TABLE "INSISTPRO_RPT"."R_CORP_ACT_JOURNAL" 
   (	"CLIENT_CD" VARCHAR2(12 BYTE), 
	"CLIENT_NAME" VARCHAR2(50 BYTE), 
	"STK_CD" VARCHAR2(50 BYTE), 
	"CA_TYPE" VARCHAR2(8 BYTE), 
	"BAL_QTY" NUMBER, 
	"ON_CUSTODY" NUMBER, 
	"CLIENT_TYPE" VARCHAR2(1 BYTE), 
	"FROM_QTY" NUMBER(18,6), 
	"TO_QTY" NUMBER(18,6), 
	"RECV_QTY" NUMBER, 
	"END_QTY" NUMBER, 
	"WHDR_QTY" NUMBER, 
	"SPLIT_QTY" NUMBER, 
	"USER_ID" VARCHAR2(10 BYTE), 
	"GENERATE_DATE" DATE, 
	"RAND_VALUE" NUMBER(10,0), 
	"BRANCH_CODE" VARCHAR2(2 BYTE), 
	"RECORDING_DT" DATE, 
	"DISTRIB_DT" DATE, 
	"X_DT" DATE, 
	"CUM_DT" DATE
   ) PCTFREE 10 PCTUSED 40 INITRANS 1 MAXTRANS 255 NOCOMPRESS NOLOGGING
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1 BUFFER_POOL DEFAULT)
  TABLESPACE "INSISTPRO" ;
 