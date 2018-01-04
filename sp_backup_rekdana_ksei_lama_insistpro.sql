create or replace 
procedure sp_backup_rekdana_ksei(
       vo_mssg_err out varchar2,
       vo_err_cd out number) is


vl_mssg_err varchar2(200);
vl_err_cd number(2);
vl_err EXCEPTION;

 begin
 begin
   insert into t_rek_dana_ksei_bak
   select SID, SUBREK, NAME, REK_DANA, bank_cd ,sysdate CREATE_DT from t_rek_dana_ksei;
   exception
   when others then
    vl_mssg_err := 'Gagal insert t_rek_dana_ksei_bak '||sqlerrm;
    vl_err_cd := -1;
    raise vl_err;

  end;

 begin
  insert into mst_client_flacct_bak
  select CLIENT_CD, BANK_CD, BANK_ACCT_NUM, ACCT_NAME,
   ACCT_STAT, BANK_SHORT_NAME, BANK_ACCT_FMT, CRE_DT,
   USER_ID, UPD_DT, UPD_USER_ID, sysdate BAK_DT from mst_client_flacct;

 exception
  when others then
   vl_mssg_err := 'Gagal insert mst_client_flacct_bak '||sqlerrm;
   vl_err_cd := -2;
   raise vl_err;
 end;


 Begin
  delete from t_rek_dana_ksei;

 exception
  when others then
   vl_mssg_err := 'Gagal delete T_REK_DANA_KSEI'||sqlerrm;
   vl_err_cd := -3;
   raise vl_err;

 end;


vl_err_cd := 1 ;
vl_mssg_err := '';

 EXCEPTION
  WHEN vl_err THEN
  ROLLBACK;
  when others then
   vl_err_cd := -4 ;
   vl_mssg_err := 'gagal';
   raise;
end sp_backup_rekdana_ksei;
