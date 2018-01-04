
--berdasarkan jam dan menit
declare
  my_job number;
begin
  dbms_job.submit(job => my_job, 
    what => 'SP_C_TES();',
    next_date =>  to_date('2017-12-07 11:39:00','yyyy-mm-dd hh24:mi:ss'),
    interval => '(trunc(SYSDATE)+1) + 11/24+39/1440');
end;
/
commit;


--tiap bulan

declare
  my_job number;
begin
  dbms_job.submit(job => my_job, 
    what => 'SP_C_TES();',
    next_date =>  to_date('2017-12-01 03:00:00','yyyy-mm-dd hh24:mi:ss'),
    interval => 'add_months(trunc(SYSDATE),1)-to_char(trunc(sysdate),''dd'')+1 + 3/24');
end;
/
commit;


--bikin jobs
declare
v_JobNo number(5);
begin
     dbms_job.submit(v_JobNo, 'IPNEXTG.SP_CA_JUR_SCHED;', TRUNC(SYSDATE) 
+ 11/24, 'trunc(SYSDATE +1) + 11/24');
     dbms_output.put_line('v_JobNo : ' || v_JobNo);
end;
/


--remove jobs
BEGIN
   DBMS_JOB.REMOVE(14144);
   COMMIT;
END; 

--merubah date selanjutnya untuk jobs yang sudah ada
DBMS_JOB.NEXT_DATE ( 
   job       IN  BINARY_INTEGER,
   next_date IN  DATE);
   
   
   --merubah jobs instance dan force optional
   DBMS_JOB.CHANGE ( 
   job       IN  BINARY_INTEGER,
   what      IN  VARCHAR2,
   next_date IN  DATE,
   interval  IN  VARCHAR2,
   instance  IN  BINARY_INTEGER DEFAULT NULL,
   force     IN  BOOLEAN DEFAULT FALSE);
   
   
   --merubah database yang dipanggil
   DBMS_JOB.WHAT ( 
   job       IN  BINARY_INTEGER,
   what      IN  VARCHAR2);
   