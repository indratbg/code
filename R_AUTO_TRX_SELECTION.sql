CREATE TABLE R_AUTO_TRX_SELECTION(

BRANCH_CODE VARCHAR2(3),
CLIENT_CD VARCHAR2(12),
BRCH VARCHAR2(3),
RDI_ACCT_NAME VARCHAR2(50),
BANK_ACCT_FMT VARCHAR2(30),
payrec_date DATE,
CURR_AMT NUMBER(18,2),
REMARKS VARCHAR2(50),
folder_cd VARCHAR2(8),
payee_name VARCHAR2(50),
payee_acct_num VARCHAR2(20),
payee_bank_cd VARCHAR2(3),
bank_name VARCHAR2(50) ,
bank_branch VARCHAR2(50),
trf_fee  NUMBER(18,2) ,
name_length NUMBER(10),
print_flg VARCHAR2(1),
USER_ID VARCHAR2(10),
RAND_VALUE NUMBER(10),
GENERATE_DATE DATE
)