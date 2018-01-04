<?php
//echo memory_get_usage();
class TbankmutationController extends AAdminController
{
	/**
	 * @var string the default layout for the views. Defaults to '//layouts/column2', meaning
	 * using two-column layout. See 'protected/views/layouts/column2.php'.
	 */
	public $layout='//layouts/admin_column3';
	
	public function actionAjxValidateBackDated()
	{ 
		$resp = '';
		echo json_decode($resp);
	}
	
	public function actionIndex()
	{
		$model= array();
		$modelReport = new Rptuplrekdanamutasi('LAP_REKENING_DANA_MUTASI','RPT_UPL_REK_DANA_MUTASI','Rpt_rek_dana_mutasi.rptdesign');
		$modelDummyRpt = new Tbankmutation;
		$modeldummy=new Tbankmutation();
		//$modeldummy->scenario='upload';
		//$model->scenario='post';
		$valid = true;
		$success = false;
		$import_type;
		$filename = '';
		$from_dt='';
		$to_dt='';
		$type='';
		$branch='';
		$url='';
		
		if(isset($_POST['scenario']))
		{ 
			if($_POST['scenario'] == 'import'){
				$modeldummy->scenario = 'upload';
			
				
				$modeldummy->attributes = $_POST['Tbankmutation'];
				
				if($modeldummy->validate()){
					
						$import_type = $modeldummy->import_type;
						$modeldummy->file_upload = CUploadedFile::getInstance($modeldummy,'file_upload');
						$path = FileUpload::getFilePath(FileUpload::T_BANK_MUTATION,'upload.txt' );
						$modeldummy->file_upload->saveAs($path);
						$filename = $modeldummy->file_upload;
						
						$lines = file($path);
						$sql1="select nvl(max(importseq),0) as importseq1 from t_bank_mutation
														where trunc(importdate) = trunc(sysdate)";
						$import=DAO::queryRowSql($sql1);
						$importseq=$import['importseq1'];	
						
						$bank_cd=Fundbank::model()->find("DEFAULT_FLG='Y'")->bank_cd;
						$success=FALSE;
						$importseq++;
						foreach ($lines as $line_num => $line) 
				{
				 $data= $line;								
				
				 if($modeldummy->validate()  && $modeldummy->executeSp($bank_cd, $importseq, $data)>0){
				 	$success =true;
				 }
				 else{
				 	$success=FALSE;
				 }
				
						//$importseq++;	
						}//end foreach
				//setelah di upload dan dibaca, delete file nya
				//unlink(FileUpload::getFilePath(FileUpload::T_BANK_MUTATION,$filename ));
					if($success){
						$modelfile = new Tbankmutationfile;
						$modelfile->filename = $filename;
						$modelfile->cre_dt = date('Y-m-d H:i:s');
						$modelfile->file_year =date('Y');
						$modelfile->save();
						
						Yii::app()->user->setFlash('success', 'Successfully upload '.$filename);
					$this->redirect(array('/finance/tbankmutation/index'));
					}
				
				}
				
		}
			else if($_POST['scenario'] =='filter'){
					$modeldummy->scenario='filter';
				$modeldummy->attributes = $_POST['Tbankmutation'];
				$bank_name = Fundbank::model()->find("default_flg ='Y'")->bank_name;
				if($modeldummy->validate()){
				
				$from_dt=$modeldummy->from_dt;
				$to_dt=$modeldummy->to_dt;
				$type=$modeldummy->type_mutasi;
				$branch=$modeldummy->branch;
		
				if(DateTime::createFromFormat('d/m/Y',$from_dt))$from_dt=DateTime::createFromFormat('d/m/Y',$from_dt)->format('Y-m-d');
				if(DateTime::createFromFormat('d/m/Y',$to_dt))$to_dt=DateTime::createFromFormat('d/m/Y',$to_dt)->format('Y-m-d');
				
				if($from_dt!='' && $to_dt !='' && $type!='' && $branch !=''){
				if($type =='I'){
						//echo "<script>alert('test')</script>";
						$sql ="select X.* from (SELECT DISTINCT a.TANGGALTimestamp, a.currency, a.InstructionFrom, a.RDN, c.branch_code, c.client_cd, c.client_name, 
						a.BEGINNINGBALANCE, a.TRANSACTIONVALUE, a.CLOSINGBALANCE , 
					 a.BANKREFERENCE, 'N' Jurnal, b.cnt , 
					a.tanggalefektif, a.bankid, a.transactiontype, 
					 decode(a.transactiontype,'NTAX','Tax','NINT','Interest','NKOR','Koreksi','Setoran') TYPETEXT ,
            '$bank_name' frombank,
					 
					a.remark, 'N' default_remark,a.typemutasi 
					FROM( SELECT NVL(bank_ref_num,'X') bank_ref_num, BANK_ACCT_NUM, doc_Date, 
					        sl_acct_cd, get_doc_date(1,doc_date) doc_date_min1 
						    FROM T_FUND_MOVEMENT a , MST_CLIENT_FLACCT b 
							WHERE doc_date BETWEEN '$from_dt' AND '$to_dt' 
							AND approved_sts <> 'C' 
							AND a.client_Cd = b.client_Cd) d, 
            
            (select  TANGGALTimestamp, currency, InstructionFrom, RDN,	BEGINNINGBALANCE, TRANSACTIONVALUE, CLOSINGBALANCE ,  BANKREFERENCE,
            tanggalefektif, bankid, transactiontype,remark, typemutasi 
            from T_BANK_MUTATION  
            where tanggalefektif between '$from_dt' AND '$to_dt' 
            and transactiontype in ('NINT','NTAX'))a, 
							( SELECT BANK_ACCT_NUM, MAX(client_cd) AS client_cd, COUNT(1) AS cnt 
								FROM 	MST_CLIENT_FLACCT 
								WHERE acct_stat <> 'C' 
							GROUP BY BANK_ACCT_NUM) b, 
							( SELECT client_cd, client_name, 
					DECODE(trim(rem_cd),'LOT','LO',DECODE(trim(MST_CLIENT.olt),'N',trim(branch_code),'LO')) branch_finan, 
							 branch_code 
							FROM MST_CLIENT ) c 
							
					WHERE a.TanggalEfektif BETWEEN '$from_dt' AND '$to_dt' 
				
					AND b.client_cd = c.client_cd 
					AND a.BANKREFERENCE = d.bank_ref_num(+) 
					AND  d.bank_ref_num IS NULL 
					AND a.rdn = b.BANK_ACCT_NUM 
					AND a.rdn = d.BANK_ACCT_NUM(+) 
					AND d.BANK_ACCT_NUM IS NULL 
					AND a.TanggalEfektif BETWEEN d.doc_date_min1(+) AND d.doc_date(+) 
					AND d.doc_date IS NULL 
					AND a.transactiontype = d.sl_acct_cd(+) 
					AND d.sl_acct_cd IS NULL 
					AND a.transactiontype <> '@IP@' 
					AND ('$branch' = 'All' 
					     OR  INSTR('$branch',trim(branch_finan)) > 0)) X
						 order by client_cd,tanggaltimestamp desc ";
						
						$model=Tbankmutation::model()->findAllBySql($sql);
					}
else{
					
			$sql="select X.* from (SELECT DISTINCT a.TANGGALTimestamp, a.currency, a.InstructionFrom, a.RDN, c.branch_code, c.client_cd, c.client_name, 
						a.BEGINNINGBALANCE, a.TRANSACTIONVALUE, a.CLOSINGBALANCE , 
					 a.BANKREFERENCE, 'N' Jurnal, b.cnt , 
					a.tanggalefektif, a.bankid, a.transactiontype, 
						 f.descrip TYPETEXT , 
					DECODE(a.InstructionFrom,'0000000000',DECODE(a.transactiontype,'NINT','$bank_name','XXX'),f.ip_bank_cd) frombank, 
					a.remark, 'N' default_remark,a.typemutasi 
					FROM( SELECT NVL(bank_ref_num,'X') bank_ref_num, BANK_ACCT_NUM, doc_Date, 
					        sl_acct_cd, 
					                                get_doc_date(1,doc_date) doc_date_min1 
						    FROM T_FUND_MOVEMENT a , MST_CLIENT_FLACCT b 
							WHERE doc_date BETWEEN '$from_dt' AND '$to_dt' 
							AND approved_sts <> 'C' 
							AND a.client_Cd = b.client_Cd) d, 
								(SELECT  TANGGALTimestamp, Currency, InstructionFrom, RDN,	BEGINNINGBALANCE, TRANSACTIONVALUE, CLOSINGBALANCE , BANKREFERENCE,
              	Tanggalefektif, bankid, transactiontype, remark, typemutasi FROM
              T_BANK_MUTATION WHERE TANGGALEFEKTIF BETWEEN '$from_dt' AND '$to_dt'  
                AND TRANSACTIONTYPE LIKE 'NTRF')  a,
							( SELECT BANK_ACCT_NUM, MAX(client_cd) AS client_cd, COUNT(1) AS cnt 
								FROM 	MST_CLIENT_FLACCT 
								WHERE acct_stat <> 'C' 
							GROUP BY BANK_ACCT_NUM) b, 
							( SELECT client_cd, client_name, 
					DECODE(trim(rem_cd),'LOT','LO',DECODE(trim(MST_CLIENT.olt),'N',trim(branch_code),'LO')) branch_finan, 
							 branch_code 
							FROM MST_CLIENT ) c, 
							( 
							SELECT t.rdi_trx_type, t.descrip, t.grp, f.ip_bank_cd, t.db_cr_flg 
							   FROM mst_rdi_trx_type t, MST_FUND_BANK f 
							   WHERE t.fund_bank_cd = f.bank_cd 
							   AND t.grp ='$type') f 
					WHERE a.TanggalEfektif BETWEEN '$from_dt' AND '$to_dt' 
					AND a.InstructionFrom NOT IN (SELECT REPLACE(REPLACE(bank_acct_cd,'-',''),'.','') 
					                                                               FROM MST_BANK_ACCT 
    																			    WHERE  bank_acct_cd <> 'X') 
					AND a.transactiontype LIKE f.rdi_trx_type 
					AND a.typemutasi = f.db_Cr_flg 
					AND b.client_cd = c.client_cd 
					AND a.BANKREFERENCE = d.bank_ref_num(+) 
					AND  d.bank_ref_num IS NULL 
					AND a.rdn = b.BANK_ACCT_NUM 
					AND a.rdn = d.BANK_ACCT_NUM(+) 
					AND d.BANK_ACCT_NUM IS NULL 
					AND a.TanggalEfektif BETWEEN d.doc_date_min1(+) AND d.doc_date(+) 
					AND d.doc_date IS NULL 
					AND a.transactiontype = d.sl_acct_cd(+) 
					AND d.sl_acct_cd IS NULL 
					AND a.transactiontype <> '@IP@' 
					AND ('$branch' = 'All' 
					     OR  INSTR('$branch',trim(branch_finan)) > 0)) X
					     where frombank like DECODE('$type','I','$bank_name','%')
					     order by client_cd,tanggaltimestamp desc ";								
			$model=Tbankmutation::model()->findAllBySql($sql);	
}
			}
			else if($from_dt!='' && $to_dt !='' && $type!=''){
					$branch ='All';			
					
					if($type =='I'){
						//echo "<script>alert('test')</script>";
						$sql ="select X.* from (SELECT DISTINCT a.TANGGALTimestamp, a.currency, a.InstructionFrom, a.RDN, c.branch_code, c.client_cd, c.client_name, 
						a.BEGINNINGBALANCE, a.TRANSACTIONVALUE, a.CLOSINGBALANCE , 
					 a.BANKREFERENCE, 'N' Jurnal, b.cnt , 
					a.tanggalefektif, a.bankid, a.transactiontype, 
					 decode(a.transactiontype,'NTAX','Tax','NINT','Interest','NKOR','Koreksi','Setoran') TYPETEXT ,
            '$bank_name' frombank,
					 
					a.remark, 'N' default_remark,a.typemutasi 
					FROM( SELECT NVL(bank_ref_num,'X') bank_ref_num, BANK_ACCT_NUM, doc_Date, 
					        sl_acct_cd, get_doc_date(1,doc_date) doc_date_min1 
						    FROM T_FUND_MOVEMENT a , MST_CLIENT_FLACCT b 
							WHERE doc_date BETWEEN '$from_dt' AND '$to_dt' 
							AND approved_sts <> 'C' 
							AND a.client_Cd = b.client_Cd) d, 
            
            (select  TANGGALTimestamp, currency, InstructionFrom, RDN,	BEGINNINGBALANCE, TRANSACTIONVALUE, CLOSINGBALANCE ,  BANKREFERENCE,
            tanggalefektif, bankid, transactiontype,remark, typemutasi 
            from T_BANK_MUTATION  
            where tanggalefektif between '$from_dt' AND '$to_dt' 
            and transactiontype in ('NINT','NTAX'))a, 
							( SELECT BANK_ACCT_NUM, MAX(client_cd) AS client_cd, COUNT(1) AS cnt 
								FROM 	MST_CLIENT_FLACCT 
								WHERE acct_stat <> 'C' 
							GROUP BY BANK_ACCT_NUM) b, 
							( SELECT client_cd, client_name, 
					DECODE(trim(rem_cd),'LOT','LO',DECODE(trim(MST_CLIENT.olt),'N',trim(branch_code),'LO')) branch_finan, 
							 branch_code 
							FROM MST_CLIENT ) c 
							
					WHERE a.TanggalEfektif BETWEEN '$from_dt' AND '$to_dt' 
				
					AND b.client_cd = c.client_cd 
					AND a.BANKREFERENCE = d.bank_ref_num(+) 
					AND  d.bank_ref_num IS NULL 
					AND a.rdn = b.BANK_ACCT_NUM 
					AND a.rdn = d.BANK_ACCT_NUM(+) 
					AND d.BANK_ACCT_NUM IS NULL 
					AND a.TanggalEfektif BETWEEN d.doc_date_min1(+) AND d.doc_date(+) 
					AND d.doc_date IS NULL 
					AND a.transactiontype = d.sl_acct_cd(+) 
					AND d.sl_acct_cd IS NULL 
					AND a.transactiontype <> '@IP@' 
					AND ('$branch' = 'All' 
					     OR  INSTR('$branch',trim(branch_finan)) > 0)) X
						 order by client_cd,tanggaltimestamp desc ";
						
						$model=Tbankmutation::model()->findAllBySql($sql);
					}
else{
	

			//echo "<script>alert('test')</script>";
		$sql="select X.* from (SELECT DISTINCT a.TANGGALTimestamp, a.currency, a.InstructionFrom, a.RDN, c.branch_code, c.client_cd, c.client_name, 
						a.BEGINNINGBALANCE, a.TRANSACTIONVALUE, a.CLOSINGBALANCE , 
					 a.BANKREFERENCE, 'N' Jurnal, b.cnt , 
					a.tanggalefektif, a.bankid, a.transactiontype, 
						 f.descrip TYPETEXT , 
						DECODE(a.InstructionFrom,'0000000000',DECODE(a.transactiontype,'NINT','$bank_name','XXX'),f.ip_bank_cd) frombank, 
					a.remark, 'N' default_remark,a.typemutasi 
					FROM( SELECT NVL(bank_ref_num,'X') bank_ref_num, BANK_ACCT_NUM, doc_Date, 
					        sl_acct_cd, 
					                                get_doc_date(1,doc_date) doc_date_min1 
						    FROM T_FUND_MOVEMENT a , MST_CLIENT_FLACCT b 
							WHERE doc_date BETWEEN '$from_dt' AND '$to_dt' 
							AND approved_sts <> 'C' 
							AND a.client_Cd = b.client_Cd) d, 
								(SELECT  TANGGALTimestamp, Currency, InstructionFrom, RDN,	BEGINNINGBALANCE, TRANSACTIONVALUE, CLOSINGBALANCE , BANKREFERENCE,
              	Tanggalefektif, bankid, transactiontype, remark, typemutasi FROM
              T_BANK_MUTATION WHERE TANGGALEFEKTIF BETWEEN '$from_dt' AND '$to_dt'  
                AND TRANSACTIONTYPE LIKE 'NTRF')  a, 
							( SELECT BANK_ACCT_NUM, MAX(client_cd) AS client_cd, COUNT(1) AS cnt 
								FROM 	MST_CLIENT_FLACCT 
								WHERE acct_stat <> 'C' 
							GROUP BY BANK_ACCT_NUM) b, 
							( SELECT client_cd, client_name, 
					DECODE(trim(rem_cd),'LOT','LO',DECODE(trim(MST_CLIENT.olt),'N',trim(branch_code),'LO')) branch_finan, 
							 branch_code 
							FROM MST_CLIENT ) c, 
							( 
							SELECT t.rdi_trx_type, t.descrip, t.grp, f.ip_bank_cd, t.db_cr_flg 
							   FROM mst_rdi_trx_type t, MST_FUND_BANK f 
							   WHERE t.fund_bank_cd = f.bank_cd 
							   AND t.grp ='$type') f 
					WHERE a.TanggalEfektif BETWEEN '$from_dt' AND '$to_dt' 
					AND a.InstructionFrom NOT IN (SELECT REPLACE(REPLACE(bank_acct_cd,'-',''),'.','') 
					                                                               FROM MST_BANK_ACCT 
    																			    WHERE  bank_acct_cd <> 'X') 
					AND a.transactiontype LIKE f.rdi_trx_type 
					AND a.typemutasi = f.db_Cr_flg 
					AND b.client_cd = c.client_cd 
					AND a.BANKREFERENCE = d.bank_ref_num(+) 
					AND  d.bank_ref_num IS NULL 
					AND a.rdn = b.BANK_ACCT_NUM 
					AND a.rdn = d.BANK_ACCT_NUM(+) 
					AND d.BANK_ACCT_NUM IS NULL 
					AND a.TanggalEfektif BETWEEN d.doc_date_min1(+) AND d.doc_date(+) 
					AND d.doc_date IS NULL 
					AND a.transactiontype = d.sl_acct_cd(+) 
					AND d.sl_acct_cd IS NULL 
					AND a.transactiontype <> '@IP@' 
					AND ('$branch' = 'All' 
					     OR  INSTR('$branch',trim(branch_finan)) > 0)) X
					     where frombank like DECODE('$type','I','$bank_name','%')
						 order by client_cd,tanggaltimestamp desc ";				
					
		$model=Tbankmutation::model()->findAllBySql($sql);
	}
				
			}
			else if($from_dt!='' && $to_dt !='' && $branch !=''){
					
				if($type =='I'){
						//echo "<script>alert('test')</script>";
						$sql ="select X.* from (SELECT DISTINCT a.TANGGALTimestamp, a.currency, a.InstructionFrom, a.RDN, c.branch_code, c.client_cd, c.client_name, 
						a.BEGINNINGBALANCE, a.TRANSACTIONVALUE, a.CLOSINGBALANCE , 
					 a.BANKREFERENCE, 'N' Jurnal, b.cnt , 
					a.tanggalefektif, a.bankid, a.transactiontype, 
					 decode(a.transactiontype,'NTAX','Tax','NINT','Interest','NKOR','Koreksi','Setoran') TYPETEXT ,
            '$bank_name' frombank,
					 
					a.remark, 'N' default_remark,a.typemutasi 
					FROM( SELECT NVL(bank_ref_num,'X') bank_ref_num, BANK_ACCT_NUM, doc_Date, 
					        sl_acct_cd, get_doc_date(1,doc_date) doc_date_min1 
						    FROM T_FUND_MOVEMENT a , MST_CLIENT_FLACCT b 
							WHERE doc_date BETWEEN '$from_dt' AND '$to_dt' 
							AND approved_sts <> 'C' 
							AND a.client_Cd = b.client_Cd) d, 
            
            (select  TANGGALTimestamp, currency, InstructionFrom, RDN,	BEGINNINGBALANCE, TRANSACTIONVALUE, CLOSINGBALANCE ,  BANKREFERENCE,
            tanggalefektif, bankid, transactiontype,remark, typemutasi 
            from T_BANK_MUTATION  
            where tanggalefektif between '$from_dt' AND '$to_dt' 
            and transactiontype in ('NINT','NTAX'))a, 
							( SELECT BANK_ACCT_NUM, MAX(client_cd) AS client_cd, COUNT(1) AS cnt 
								FROM 	MST_CLIENT_FLACCT 
								WHERE acct_stat <> 'C' 
							GROUP BY BANK_ACCT_NUM) b, 
							( SELECT client_cd, client_name, 
					DECODE(trim(rem_cd),'LOT','LO',DECODE(trim(MST_CLIENT.olt),'N',trim(branch_code),'LO')) branch_finan, 
							 branch_code 
							FROM MST_CLIENT ) c 
							
					WHERE a.TanggalEfektif BETWEEN '$from_dt' AND '$to_dt' 
				
					AND b.client_cd = c.client_cd 
					AND a.BANKREFERENCE = d.bank_ref_num(+) 
					AND  d.bank_ref_num IS NULL 
					AND a.rdn = b.BANK_ACCT_NUM 
					AND a.rdn = d.BANK_ACCT_NUM(+) 
					AND d.BANK_ACCT_NUM IS NULL 
					AND a.TanggalEfektif BETWEEN d.doc_date_min1(+) AND d.doc_date(+) 
					AND d.doc_date IS NULL 
					AND a.transactiontype = d.sl_acct_cd(+) 
					AND d.sl_acct_cd IS NULL 
					AND a.transactiontype <> '@IP@' 
					AND ('$branch' = 'All' 
					     OR  INSTR('$branch',trim(branch_finan)) > 0)) X
						 order by client_cd,tanggaltimestamp desc ";
						
						$model=Tbankmutation::model()->findAllBySql($sql);
					}
else{			
							
					$sql="select X.* from (SELECT DISTINCT a.TANGGALTimestamp, a.currency, a.InstructionFrom, a.RDN, c.branch_code, c.client_cd, c.client_name, 
						a.BEGINNINGBALANCE, a.TRANSACTIONVALUE, a.CLOSINGBALANCE , 
					 a.BANKREFERENCE, 'N' Jurnal, b.cnt , 
					a.tanggalefektif, a.bankid, a.transactiontype, 
						 f.descrip TYPETEXT , 
					DECODE(a.InstructionFrom,'0000000000',DECODE(a.transactiontype,'NINT','$bank_name','XXX'),f.ip_bank_cd) frombank, 
					a.remark, 'N' default_remark,a.typemutasi 
					FROM( SELECT NVL(bank_ref_num,'X') bank_ref_num, BANK_ACCT_NUM, doc_Date, 
					        sl_acct_cd, 
					                                get_doc_date(1,doc_date) doc_date_min1 
						    FROM T_FUND_MOVEMENT a , MST_CLIENT_FLACCT b 
							WHERE doc_date BETWEEN '$from_dt' AND '$to_dt' 
							AND approved_sts <> 'C' 
							AND a.client_Cd = b.client_Cd) d, 
							(SELECT  TANGGALTimestamp, Currency, InstructionFrom, RDN,	BEGINNINGBALANCE, TRANSACTIONVALUE, CLOSINGBALANCE , BANKREFERENCE,
              	Tanggalefektif, bankid, transactiontype, remark, typemutasi FROM
              T_BANK_MUTATION WHERE TANGGALEFEKTIF BETWEEN '$from_dt' AND '$to_dt'  
                AND TRANSACTIONTYPE LIKE 'NTRF')  a,
							( SELECT BANK_ACCT_NUM, MAX(client_cd) AS client_cd, COUNT(1) AS cnt 
								FROM 	MST_CLIENT_FLACCT 
								WHERE acct_stat <> 'C' 
							GROUP BY BANK_ACCT_NUM) b, 
							( SELECT client_cd, client_name, 
					DECODE(trim(rem_cd),'LOT','LO',DECODE(trim(MST_CLIENT.olt),'N',trim(branch_code),'LO')) branch_finan, 
							 branch_code 
							FROM MST_CLIENT ) c, 
							( 
							SELECT t.rdi_trx_type, t.descrip, t.grp, f.ip_bank_cd, t.db_cr_flg 
							   FROM mst_rdi_trx_type t, MST_FUND_BANK f 
							   WHERE t.fund_bank_cd = f.bank_cd 
							   ) f 
					WHERE a.TanggalEfektif BETWEEN '$from_dt' AND '$to_dt' 
					AND a.InstructionFrom NOT IN (SELECT REPLACE(REPLACE(bank_acct_cd,'-',''),'.','') 
					                                                               FROM MST_BANK_ACCT 
    																			    WHERE  bank_acct_cd <> 'X') 
					AND a.transactiontype LIKE f.rdi_trx_type 
					AND a.typemutasi = f.db_Cr_flg 
					AND b.client_cd = c.client_cd 
					AND a.BANKREFERENCE = d.bank_ref_num(+) 
					AND  d.bank_ref_num IS NULL 
					AND a.rdn = b.BANK_ACCT_NUM 
					AND a.rdn = d.BANK_ACCT_NUM(+) 
					AND d.BANK_ACCT_NUM IS NULL 
					AND a.TanggalEfektif BETWEEN d.doc_date_min1(+) AND d.doc_date(+) 
					AND d.doc_date IS NULL 
					AND a.transactiontype = d.sl_acct_cd(+) 
					AND d.sl_acct_cd IS NULL 
					AND a.transactiontype <> '@IP@' 
					AND ('$branch' = 'All' 
					     OR  INSTR('$branch',trim(branch_finan)) > 0)) X
					     where frombank like DECODE('$type','I','$bank_name','%')
					     order by client_cd,tanggaltimestamp desc ";				
					
		$model=Tbankmutation::model()->findAllBySql($sql);
				}
			}
			else if($from_dt!='' && $to_dt !=''){
					$branch='All';
			//	echo "<script>alert('test')</script>";
			
			
			if($type =='I'){
						//echo "<script>alert('test')</script>";
						$sql ="select X.* from (SELECT DISTINCT a.TANGGALTimestamp, a.currency, a.InstructionFrom, a.RDN, c.branch_code, c.client_cd, c.client_name, 
						a.BEGINNINGBALANCE, a.TRANSACTIONVALUE, a.CLOSINGBALANCE , 
					 a.BANKREFERENCE, 'N' Jurnal, b.cnt , 
					a.tanggalefektif, a.bankid, a.transactiontype, 
					 decode(a.transactiontype,'NTAX','Tax','NINT','Interest','NKOR','Koreksi','Setoran') TYPETEXT ,
            '$bank_name' frombank,
					 
					a.remark, 'N' default_remark,a.typemutasi 
					FROM( SELECT NVL(bank_ref_num,'X') bank_ref_num, BANK_ACCT_NUM, doc_Date, 
					        sl_acct_cd, get_doc_date(1,doc_date) doc_date_min1 
						    FROM T_FUND_MOVEMENT a , MST_CLIENT_FLACCT b 
							WHERE doc_date BETWEEN '$from_dt' AND '$to_dt' 
							AND approved_sts <> 'C' 
							AND a.client_Cd = b.client_Cd) d, 
            
            (select  TANGGALTimestamp, currency, InstructionFrom, RDN,	BEGINNINGBALANCE, TRANSACTIONVALUE, CLOSINGBALANCE ,  BANKREFERENCE,
            tanggalefektif, bankid, transactiontype,remark, typemutasi 
            from T_BANK_MUTATION  
            where tanggalefektif between '$from_dt' AND '$to_dt' 
            and transactiontype in ('NINT','NTAX'))a, 
							( SELECT BANK_ACCT_NUM, MAX(client_cd) AS client_cd, COUNT(1) AS cnt 
								FROM 	MST_CLIENT_FLACCT 
								WHERE acct_stat <> 'C' 
							GROUP BY BANK_ACCT_NUM) b, 
							( SELECT client_cd, client_name, 
					DECODE(trim(rem_cd),'LOT','LO',DECODE(trim(MST_CLIENT.olt),'N',trim(branch_code),'LO')) branch_finan, 
							 branch_code 
							FROM MST_CLIENT ) c 
							
					WHERE a.TanggalEfektif BETWEEN '$from_dt' AND '$to_dt' 
				
					AND b.client_cd = c.client_cd 
					AND a.BANKREFERENCE = d.bank_ref_num(+) 
					AND  d.bank_ref_num IS NULL 
					AND a.rdn = b.BANK_ACCT_NUM 
					AND a.rdn = d.BANK_ACCT_NUM(+) 
					AND d.BANK_ACCT_NUM IS NULL 
					AND a.TanggalEfektif BETWEEN d.doc_date_min1(+) AND d.doc_date(+) 
					AND d.doc_date IS NULL 
					AND a.transactiontype = d.sl_acct_cd(+) 
					AND d.sl_acct_cd IS NULL 
					AND a.transactiontype <> '@IP@' 
					AND ('$branch' = 'All' 
					     OR  INSTR('$branch',trim(branch_finan)) > 0)) X
						 order by client_cd,tanggaltimestamp desc ";
						
						$model=Tbankmutation::model()->findAllBySql($sql);
					}
else{
					$sql="select X.* from (SELECT DISTINCT a.TANGGALTimestamp, a.currency, a.InstructionFrom, a.RDN, c.branch_code, c.client_cd, c.client_name, 
						a.BEGINNINGBALANCE, a.TRANSACTIONVALUE, a.CLOSINGBALANCE , 
					 a.BANKREFERENCE, 'N' Jurnal, b.cnt , 
					a.tanggalefektif, a.bankid, a.transactiontype, 
						 f.descrip TYPETEXT , 
						DECODE(a.InstructionFrom,'0000000000',DECODE(a.transactiontype,'NINT','$bank_name','XXX'),f.ip_bank_cd) frombank, 
					a.remark, 'N' default_remark,a.typemutasi 
					FROM( SELECT NVL(bank_ref_num,'X') bank_ref_num, BANK_ACCT_NUM, doc_Date, 
					        sl_acct_cd, 
					                                get_doc_date(1,doc_date) doc_date_min1 
						    FROM T_FUND_MOVEMENT a , MST_CLIENT_FLACCT b 
							WHERE doc_date BETWEEN '$from_dt' AND '$to_dt' 
							AND approved_sts <> 'C' 
							AND a.client_Cd = b.client_Cd) d, 
								(SELECT  TANGGALTimestamp, Currency, InstructionFrom, RDN,	BEGINNINGBALANCE, TRANSACTIONVALUE, CLOSINGBALANCE , BANKREFERENCE,
              	Tanggalefektif, bankid, transactiontype, remark, typemutasi FROM
              T_BANK_MUTATION WHERE TANGGALEFEKTIF BETWEEN '$from_dt' AND '$to_dt'  
                AND TRANSACTIONTYPE LIKE 'NTRF')  a,
							( SELECT BANK_ACCT_NUM, MAX(client_cd) AS client_cd, COUNT(1) AS cnt 
								FROM 	MST_CLIENT_FLACCT 
								WHERE acct_stat <> 'C' 
							GROUP BY BANK_ACCT_NUM) b, 
							( SELECT client_cd, client_name, 
					DECODE(trim(rem_cd),'LOT','LO',DECODE(trim(MST_CLIENT.olt),'N',trim(branch_code),'LO')) branch_finan, 
							 branch_code 
							FROM MST_CLIENT ) c, 
							( 
							SELECT t.rdi_trx_type, t.descrip, t.grp, f.ip_bank_cd, t.db_cr_flg 
							   FROM mst_rdi_trx_type t, MST_FUND_BANK f 
							   WHERE t.fund_bank_cd = f.bank_cd 
							   ) f 
					WHERE a.TanggalEfektif BETWEEN '$from_dt' AND '$to_dt' 
					AND a.InstructionFrom NOT IN (SELECT REPLACE(REPLACE(bank_acct_cd,'-',''),'.','') 
					                                                               FROM MST_BANK_ACCT 
    																			    WHERE  bank_acct_cd <> 'X') 
					AND a.transactiontype LIKE f.rdi_trx_type 
					AND a.typemutasi = f.db_Cr_flg 
					AND b.client_cd = c.client_cd 
					AND a.BANKREFERENCE = d.bank_ref_num(+) 
					AND  d.bank_ref_num IS NULL 
					AND a.rdn = b.BANK_ACCT_NUM 
					AND a.rdn = d.BANK_ACCT_NUM(+) 
					AND d.BANK_ACCT_NUM IS NULL 
					AND a.TanggalEfektif BETWEEN d.doc_date_min1(+) AND d.doc_date(+) 
					AND d.doc_date IS NULL 
					AND a.transactiontype = d.sl_acct_cd(+) 
					AND d.sl_acct_cd IS NULL 
					AND a.transactiontype <> '@IP@' 
					AND ('$branch' = 'All' 
					     OR  INSTR('$branch',trim(branch_finan)) > 0))X
					      where frombank like DECODE('$type','I','$bank_name','%')
					      order by client_cd,tanggaltimestamp desc ";				
					
		$model=Tbankmutation::model()->findAllBySql($sql);
					}
				
			}
			
			else{
				
					$sql="select X.* from (SELECT DISTINCT a.TANGGALTimestamp, a.currency, a.InstructionFrom, a.RDN, c.branch_code, c.client_cd, c.client_name, 
						a.BEGINNINGBALANCE, a.TRANSACTIONVALUE, a.CLOSINGBALANCE , 
					 a.BANKREFERENCE, 'N' Jurnal, b.cnt , 
					a.tanggalefektif, a.bankid, a.transactiontype, 
						 f.descrip TYPETEXT , 
						DECODE(a.InstructionFrom,'0000000000',DECODE(a.transactiontype,'NINT','$bank_name','XXX'),f.ip_bank_cd) frombank, 
					a.remark, 'N' default_remark,a.typemutasi 
					FROM( SELECT NVL(bank_ref_num,'X') bank_ref_num, BANK_ACCT_NUM, doc_Date, 
					        sl_acct_cd, 
					                                get_doc_date(1,doc_date) doc_date_min1 
						    FROM T_FUND_MOVEMENT a , MST_CLIENT_FLACCT b 
							WHERE doc_date BETWEEN '$from_dt' AND '$to_dt' 
							AND approved_sts <> 'C' 
							AND a.client_Cd = b.client_Cd) d, 
								(SELECT  TANGGALTimestamp, Currency, InstructionFrom, RDN,	BEGINNINGBALANCE, TRANSACTIONVALUE, CLOSINGBALANCE , BANKREFERENCE,
              	Tanggalefektif, bankid, transactiontype, remark, typemutasi FROM
              T_BANK_MUTATION WHERE TANGGALEFEKTIF BETWEEN '$from_dt' AND '$to_dt'  
                AND TRANSACTIONTYPE LIKE 'NTRF')  a, 
							( SELECT BANK_ACCT_NUM, MAX(client_cd) AS client_cd, COUNT(1) AS cnt 
								FROM 	MST_CLIENT_FLACCT 
								WHERE acct_stat <> 'C' 
							GROUP BY BANK_ACCT_NUM) b, 
							( SELECT client_cd, client_name, 
					DECODE(trim(rem_cd),'LOT','LO',DECODE(trim(MST_CLIENT.olt),'N',trim(branch_code),'LO')) branch_finan, 
							 branch_code 
							FROM MST_CLIENT ) c, 
							( 
							SELECT t.rdi_trx_type, t.descrip, t.grp, f.ip_bank_cd, t.db_cr_flg 
							   FROM mst_rdi_trx_type t, MST_FUND_BANK f 
							   WHERE t.fund_bank_cd = f.bank_cd 
							   AND t.grp ='$type') f 
					WHERE a.TanggalEfektif BETWEEN '$from_dt' AND '$to_dt' 
					AND a.InstructionFrom NOT IN (SELECT REPLACE(REPLACE(bank_acct_cd,'-',''),'.','') 
					                                                               FROM MST_BANK_ACCT 
    																			    WHERE  bank_acct_cd <> 'X') 
					AND a.transactiontype LIKE f.rdi_trx_type 
					AND a.typemutasi = f.db_Cr_flg 
					AND b.client_cd = c.client_cd 
					AND a.BANKREFERENCE = d.bank_ref_num(+) 
					AND  d.bank_ref_num IS NULL 
					AND a.rdn = b.BANK_ACCT_NUM 
					AND a.rdn = d.BANK_ACCT_NUM(+) 
					AND d.BANK_ACCT_NUM IS NULL 
					AND a.TanggalEfektif BETWEEN d.doc_date_min1(+) AND d.doc_date(+) 
					AND d.doc_date IS NULL 
					AND a.transactiontype = d.sl_acct_cd(+) 
					AND d.sl_acct_cd IS NULL 
					AND a.transactiontype <> '@IP@' 
					AND ('$branch' = 'All' 
					     OR  INSTR('$branch',trim(branch_finan)) > 0))X
					     where frombank like DECODE('$type','I','$bank_name','%')
					     order by client_cd,tanggaltimestamp desc ";				
					
		$model=Tbankmutation::model()->findAllBySql($sql);
			}
				
			if(count($model)=='0'){
				Yii::app()->user->setFlash('danger', 'No Data Found');
			}
			
					foreach($model as $row)
					{
					$row->tgl_time =  $row->tanggaltimestamp;//Y-M-D H:I:S
					//if(DateTime::createFromFormat('Y-m-d H:i:s',$row->tanggaltimestamp))$row->tanggaltimestamp=DateTime::createFromFormat('Y-m-d H:i:s',$row->tanggaltimestamp)->format('d/m/Y H:i:s');
					if(DateTime::createFromFormat('Y-m-d H:i:s',$row->tanggaltimestamp))$row->tanggaltimestamp=DateTime::createFromFormat('Y-m-d H:i:s',$row->tanggaltimestamp)->format('d/m/Y H:i');
					
					}
					if(DateTime::createFromFormat('Y-m-d',$from_dt))$from_dt=DateTime::createFromFormat('Y-m-d',$from_dt)->format('d/m/Y');
					if(DateTime::createFromFormat('Y-m-d',$to_dt))$to_dt=DateTime::createFromFormat('Y-m-d',$to_dt)->format('d/m/Y');
				
			
			}//end validate
			}//end filter
			
			
		else if($_POST['scenario'] =='print'){
				
				
				$modeldummy->scenario='filter';
				$modeldummy->attributes = $_POST['Tbankmutation'];
				$bank_name = Fundbank::model()->find("default_flg ='Y'")->bank_name;
				if($modeldummy->validate()){
				
				$from_dt=$modeldummy->from_dt;
				$to_dt=$modeldummy->to_dt;
				$type=$modeldummy->type_mutasi;
				$branch=$modeldummy->branch;
		
				if(DateTime::createFromFormat('d/m/Y',$from_dt))$from_dt=DateTime::createFromFormat('d/m/Y',$from_dt)->format('Y-m-d');
				if(DateTime::createFromFormat('d/m/Y',$to_dt))$to_dt=DateTime::createFromFormat('d/m/Y',$to_dt)->format('Y-m-d');
				
				if($from_dt!='' && $to_dt !='' && $type!='' && $branch !=''){
				
					
			$sql="select X.* from (SELECT DISTINCT a.TANGGALTimestamp, a.currency, a.InstructionFrom, a.RDN, c.branch_code, c.client_cd, c.client_name, 
						a.BEGINNINGBALANCE, a.TRANSACTIONVALUE, a.CLOSINGBALANCE , 
					 a.BANKREFERENCE, 'N' Jurnal, b.cnt , 
					a.tanggalefektif, a.bankid, a.transactiontype, 
						 f.descrip TYPETEXT , 
						DECODE(a.InstructionFrom,'0000000000',DECODE(a.transactiontype,'NINT','$bank_name','XXX'),f.ip_bank_cd) frombank, 
					a.remark, 'N' default_remark,a.typemutasi 
					FROM( SELECT NVL(bank_ref_num,'X') bank_ref_num, BANK_ACCT_NUM, doc_Date, 
					        sl_acct_cd, 
					                                get_doc_date(1,doc_date) doc_date_min1 
						    FROM T_FUND_MOVEMENT a , MST_CLIENT_FLACCT b 
							WHERE doc_date BETWEEN '$from_dt' AND '$to_dt' 
							AND approved_sts <> 'C' 
							AND a.client_Cd = b.client_Cd) d, 
							T_BANK_MUTATION  a, 
							( SELECT BANK_ACCT_NUM, MAX(client_cd) AS client_cd, COUNT(1) AS cnt 
								FROM 	MST_CLIENT_FLACCT 
								WHERE acct_stat <> 'C' 
							GROUP BY BANK_ACCT_NUM) b, 
							( SELECT client_cd, client_name, 
					DECODE(trim(rem_cd),'LOT','LO',DECODE(trim(MST_CLIENT.olt),'N',trim(branch_code),'LO')) branch_finan, 
							 branch_code 
							FROM MST_CLIENT ) c, 
							( 
							SELECT t.rdi_trx_type, t.descrip, t.grp, f.ip_bank_cd, t.db_cr_flg 
							   FROM mst_rdi_trx_type t, MST_FUND_BANK f 
							   WHERE t.fund_bank_cd = f.bank_cd 
							   AND t.grp ='$type') f 
					WHERE a.TanggalEfektif BETWEEN '$from_dt' AND '$to_dt' 
					AND a.InstructionFrom NOT IN (SELECT REPLACE(REPLACE(bank_acct_cd,'-',''),'.','') 
					                                                               FROM MST_BANK_ACCT 
    																			    WHERE  bank_acct_cd <> 'X') 
					AND a.transactiontype LIKE f.rdi_trx_type 
					AND a.typemutasi = f.db_Cr_flg 
					AND b.client_cd = c.client_cd 
					AND a.BANKREFERENCE = d.bank_ref_num(+) 
					AND  d.bank_ref_num IS NULL 
					AND a.rdn = b.BANK_ACCT_NUM 
					AND a.rdn = d.BANK_ACCT_NUM(+) 
					AND d.BANK_ACCT_NUM IS NULL 
					AND a.TanggalEfektif BETWEEN d.doc_date_min1(+) AND d.doc_date(+) 
					AND d.doc_date IS NULL 
					AND a.transactiontype = d.sl_acct_cd(+) 
					AND d.sl_acct_cd IS NULL 
					AND a.transactiontype <> '@IP@' 
					AND ('$branch' = 'All' 
					     OR  INSTR('$branch',trim(branch_finan)) > 0)) X
					     where frombank like DECODE('$type','I','$bank_name','%')
					     order by client_cd,tanggaltimestamp desc ";								
			$model=Tbankmutation::model()->findAllBySql($sql);	

			}
			else if($from_dt!='' && $to_dt !='' && $type!=''){
					$branch ='All';			
			//echo "<script>alert('test')</script>";
		$sql="select X.* from (SELECT DISTINCT a.TANGGALTimestamp, a.currency, a.InstructionFrom, a.RDN, c.branch_code, c.client_cd, c.client_name, 
						a.BEGINNINGBALANCE, a.TRANSACTIONVALUE, a.CLOSINGBALANCE , 
					 a.BANKREFERENCE, 'N' Jurnal, b.cnt , 
					a.tanggalefektif, a.bankid, a.transactiontype, 
						 f.descrip TYPETEXT , 
						DECODE(a.InstructionFrom,'0000000000',DECODE(a.transactiontype,'NINT','$bank_name','XXX'),f.ip_bank_cd) frombank, 
					a.remark, 'N' default_remark,a.typemutasi 
					FROM( SELECT NVL(bank_ref_num,'X') bank_ref_num, BANK_ACCT_NUM, doc_Date, 
					        sl_acct_cd, 
					                                get_doc_date(1,doc_date) doc_date_min1 
						    FROM T_FUND_MOVEMENT a , MST_CLIENT_FLACCT b 
							WHERE doc_date BETWEEN '$from_dt' AND '$to_dt' 
							AND approved_sts <> 'C' 
							AND a.client_Cd = b.client_Cd) d, 
							T_BANK_MUTATION  a, 
							( SELECT BANK_ACCT_NUM, MAX(client_cd) AS client_cd, COUNT(1) AS cnt 
								FROM 	MST_CLIENT_FLACCT 
								WHERE acct_stat <> 'C' 
							GROUP BY BANK_ACCT_NUM) b, 
							( SELECT client_cd, client_name, 
					DECODE(trim(rem_cd),'LOT','LO',DECODE(trim(MST_CLIENT.olt),'N',trim(branch_code),'LO')) branch_finan, 
							 branch_code 
							FROM MST_CLIENT ) c, 
							( 
							SELECT t.rdi_trx_type, t.descrip, t.grp, f.ip_bank_cd, t.db_cr_flg 
							   FROM mst_rdi_trx_type t, MST_FUND_BANK f 
							   WHERE t.fund_bank_cd = f.bank_cd 
							   AND t.grp ='$type') f 
					WHERE a.TanggalEfektif BETWEEN '$from_dt' AND '$to_dt' 
					AND a.InstructionFrom NOT IN (SELECT REPLACE(REPLACE(bank_acct_cd,'-',''),'.','') 
					                                                               FROM MST_BANK_ACCT 
    																			    WHERE  bank_acct_cd <> 'X') 
					AND a.transactiontype LIKE f.rdi_trx_type 
					AND a.typemutasi = f.db_Cr_flg 
					AND b.client_cd = c.client_cd 
					AND a.BANKREFERENCE = d.bank_ref_num(+) 
					AND  d.bank_ref_num IS NULL 
					AND a.rdn = b.BANK_ACCT_NUM 
					AND a.rdn = d.BANK_ACCT_NUM(+) 
					AND d.BANK_ACCT_NUM IS NULL 
					AND a.TanggalEfektif BETWEEN d.doc_date_min1(+) AND d.doc_date(+) 
					AND d.doc_date IS NULL 
					AND a.transactiontype = d.sl_acct_cd(+) 
					AND d.sl_acct_cd IS NULL 
					AND a.transactiontype <> '@IP@' 
					AND ('$branch' = 'All' 
					     OR  INSTR('$branch',trim(branch_finan)) > 0)) X
					     where frombank like DECODE('$type','I','$bank_name','%')
						 order by client_cd,tanggaltimestamp desc  ";				
					
		$model=Tbankmutation::model()->findAllBySql($sql);
	
				
			}
			else if($from_dt!='' && $to_dt !='' && $branch !=''){
					
							
							
					$sql="select X.* from (SELECT DISTINCT a.TANGGALTimestamp, a.currency, a.InstructionFrom, a.RDN, c.branch_code, c.client_cd, c.client_name, 
						a.BEGINNINGBALANCE, a.TRANSACTIONVALUE, a.CLOSINGBALANCE , 
					 a.BANKREFERENCE, 'N' Jurnal, b.cnt , 
					a.tanggalefektif, a.bankid, a.transactiontype, 
						 f.descrip TYPETEXT , 
						DECODE(a.InstructionFrom,'0000000000',DECODE(a.transactiontype,'NINT','$bank_name','XXX'),f.ip_bank_cd) frombank, 
					a.remark, 'N' default_remark,a.typemutasi 
					FROM( SELECT NVL(bank_ref_num,'X') bank_ref_num, BANK_ACCT_NUM, doc_Date, 
					        sl_acct_cd, 
					                                get_doc_date(1,doc_date) doc_date_min1 
						    FROM T_FUND_MOVEMENT a , MST_CLIENT_FLACCT b 
							WHERE doc_date BETWEEN '$from_dt' AND '$to_dt' 
							AND approved_sts <> 'C' 
							AND a.client_Cd = b.client_Cd) d, 
							T_BANK_MUTATION  a, 
							( SELECT BANK_ACCT_NUM, MAX(client_cd) AS client_cd, COUNT(1) AS cnt 
								FROM 	MST_CLIENT_FLACCT 
								WHERE acct_stat <> 'C' 
							GROUP BY BANK_ACCT_NUM) b, 
							( SELECT client_cd, client_name, 
					DECODE(trim(rem_cd),'LOT','LO',DECODE(trim(MST_CLIENT.olt),'N',trim(branch_code),'LO')) branch_finan, 
							 branch_code 
							FROM MST_CLIENT ) c, 
							( 
							SELECT t.rdi_trx_type, t.descrip, t.grp, f.ip_bank_cd, t.db_cr_flg 
							   FROM mst_rdi_trx_type t, MST_FUND_BANK f 
							   WHERE t.fund_bank_cd = f.bank_cd 
							   ) f 
					WHERE a.TanggalEfektif BETWEEN '$from_dt' AND '$to_dt' 
					AND a.InstructionFrom NOT IN (SELECT REPLACE(REPLACE(bank_acct_cd,'-',''),'.','') 
					                                                               FROM MST_BANK_ACCT 
    																			    WHERE  bank_acct_cd <> 'X') 
					AND a.transactiontype LIKE f.rdi_trx_type 
					AND a.typemutasi = f.db_Cr_flg 
					AND b.client_cd = c.client_cd 
					AND a.BANKREFERENCE = d.bank_ref_num(+) 
					AND  d.bank_ref_num IS NULL 
					AND a.rdn = b.BANK_ACCT_NUM 
					AND a.rdn = d.BANK_ACCT_NUM(+) 
					AND d.BANK_ACCT_NUM IS NULL 
					AND a.TanggalEfektif BETWEEN d.doc_date_min1(+) AND d.doc_date(+) 
					AND d.doc_date IS NULL 
					AND a.transactiontype = d.sl_acct_cd(+) 
					AND d.sl_acct_cd IS NULL 
					AND a.transactiontype <> '@IP@' 
					AND ('$branch' = 'All' 
					     OR  INSTR('$branch',trim(branch_finan)) > 0)) X
					     where frombank like DECODE('$type','I','$bank_name','%')
					     order by client_cd,tanggaltimestamp desc ";				
					
		$model=Tbankmutation::model()->findAllBySql($sql);
				
			}
			else if($from_dt!='' && $to_dt !=''){
					$branch='All';
			
					$sql="select X.* from (SELECT DISTINCT a.TANGGALTimestamp, a.currency, a.InstructionFrom, a.RDN, c.branch_code, c.client_cd, c.client_name, 
						a.BEGINNINGBALANCE, a.TRANSACTIONVALUE, a.CLOSINGBALANCE , 
					 a.BANKREFERENCE, 'N' Jurnal, b.cnt , 
					a.tanggalefektif, a.bankid, a.transactiontype, 
						 f.descrip TYPETEXT , 
						DECODE(a.InstructionFrom,'0000000000',DECODE(a.transactiontype,'NINT','$bank_name','XXX'),f.ip_bank_cd) frombank, 
					a.remark, 'N' default_remark,a.typemutasi 
					FROM( SELECT NVL(bank_ref_num,'X') bank_ref_num, BANK_ACCT_NUM, doc_Date, 
					        sl_acct_cd, 
					                                get_doc_date(1,doc_date) doc_date_min1 
						    FROM T_FUND_MOVEMENT a , MST_CLIENT_FLACCT b 
							WHERE doc_date BETWEEN '$from_dt' AND '$to_dt' 
							AND approved_sts <> 'C' 
							AND a.client_Cd = b.client_Cd) d, 
							T_BANK_MUTATION  a, 
							( SELECT BANK_ACCT_NUM, MAX(client_cd) AS client_cd, COUNT(1) AS cnt 
								FROM 	MST_CLIENT_FLACCT 
								WHERE acct_stat <> 'C' 
							GROUP BY BANK_ACCT_NUM) b, 
							( SELECT client_cd, client_name, 
					DECODE(trim(rem_cd),'LOT','LO',DECODE(trim(MST_CLIENT.olt),'N',trim(branch_code),'LO')) branch_finan, 
							 branch_code 
							FROM MST_CLIENT ) c, 
							( 
							SELECT t.rdi_trx_type, t.descrip, t.grp, f.ip_bank_cd, t.db_cr_flg 
							   FROM mst_rdi_trx_type t, MST_FUND_BANK f 
							   WHERE t.fund_bank_cd = f.bank_cd 
							   ) f 
					WHERE a.TanggalEfektif BETWEEN '$from_dt' AND '$to_dt' 
					AND a.InstructionFrom NOT IN (SELECT REPLACE(REPLACE(bank_acct_cd,'-',''),'.','') 
					                                                               FROM MST_BANK_ACCT 
    																			    WHERE  bank_acct_cd <> 'X') 
					AND a.transactiontype LIKE f.rdi_trx_type 
					AND a.typemutasi = f.db_Cr_flg 
					AND b.client_cd = c.client_cd 
					AND a.BANKREFERENCE = d.bank_ref_num(+) 
					AND  d.bank_ref_num IS NULL 
					AND a.rdn = b.BANK_ACCT_NUM 
					AND a.rdn = d.BANK_ACCT_NUM(+) 
					AND d.BANK_ACCT_NUM IS NULL 
					AND a.TanggalEfektif BETWEEN d.doc_date_min1(+) AND d.doc_date(+) 
					AND d.doc_date IS NULL 
					AND a.transactiontype = d.sl_acct_cd(+) 
					AND d.sl_acct_cd IS NULL 
					AND a.transactiontype <> '@IP@' 
					AND ('$branch' = 'All' 
					     OR  INSTR('$branch',trim(branch_finan)) > 0))X
					      where frombank like DECODE('$type','I','$bank_name','%')
					      order by client_cd,tanggaltimestamp desc ";				
					
		$model=Tbankmutation::model()->findAllBySql($sql);
					
				
			}
			
			else{
					$sql="select X.* from (SELECT DISTINCT a.TANGGALTimestamp, a.currency, a.InstructionFrom, a.RDN, c.branch_code, c.client_cd, c.client_name, 
						a.BEGINNINGBALANCE, a.TRANSACTIONVALUE, a.CLOSINGBALANCE , 
					 a.BANKREFERENCE, 'N' Jurnal, b.cnt , 
					a.tanggalefektif, a.bankid, a.transactiontype, 
						 f.descrip TYPETEXT , 
						DECODE(a.InstructionFrom,'0000000000',DECODE(a.transactiontype,'NINT','$bank_name','XXX'),f.ip_bank_cd) frombank, 
					a.remark, 'N' default_remark,a.typemutasi 
					FROM( SELECT NVL(bank_ref_num,'X') bank_ref_num, BANK_ACCT_NUM, doc_Date, 
					        sl_acct_cd, 
					                                get_doc_date(1,doc_date) doc_date_min1 
						    FROM T_FUND_MOVEMENT a , MST_CLIENT_FLACCT b 
							WHERE doc_date BETWEEN '$from_dt' AND '$to_dt' 
							AND approved_sts <> 'C' 
							AND a.client_Cd = b.client_Cd) d, 
							T_BANK_MUTATION  a, 
							( SELECT BANK_ACCT_NUM, MAX(client_cd) AS client_cd, COUNT(1) AS cnt 
								FROM 	MST_CLIENT_FLACCT 
								WHERE acct_stat <> 'C' 
							GROUP BY BANK_ACCT_NUM) b, 
							( SELECT client_cd, client_name, 
					DECODE(trim(rem_cd),'LOT','LO',DECODE(trim(MST_CLIENT.olt),'N',trim(branch_code),'LO')) branch_finan, 
							 branch_code 
							FROM MST_CLIENT ) c, 
							( 
							SELECT t.rdi_trx_type, t.descrip, t.grp, f.ip_bank_cd, t.db_cr_flg 
							   FROM mst_rdi_trx_type t, MST_FUND_BANK f 
							   WHERE t.fund_bank_cd = f.bank_cd 
							   AND t.grp ='$type') f 
					WHERE a.TanggalEfektif BETWEEN '$from_dt' AND '$to_dt' 
					AND a.InstructionFrom NOT IN (SELECT REPLACE(REPLACE(bank_acct_cd,'-',''),'.','') 
					                                                               FROM MST_BANK_ACCT 
    																			    WHERE  bank_acct_cd <> 'X') 
					AND a.transactiontype LIKE f.rdi_trx_type 
					AND a.typemutasi = f.db_Cr_flg 
					AND b.client_cd = c.client_cd 
					AND a.BANKREFERENCE = d.bank_ref_num(+) 
					AND  d.bank_ref_num IS NULL 
					AND a.rdn = b.BANK_ACCT_NUM 
					AND a.rdn = d.BANK_ACCT_NUM(+) 
					AND d.BANK_ACCT_NUM IS NULL 
					AND a.TanggalEfektif BETWEEN d.doc_date_min1(+) AND d.doc_date(+) 
					AND d.doc_date IS NULL 
					AND a.transactiontype = d.sl_acct_cd(+) 
					AND d.sl_acct_cd IS NULL 
					AND a.transactiontype <> '@IP@' 
					AND ('$branch' = 'All' 
					     OR  INSTR('$branch',trim(branch_finan)) > 0))X
					     where frombank like DECODE('$type','I','$bank_name','%')
					     order by client_cd,tanggaltimestamp desc ";				
					
		$model=Tbankmutation::model()->findAllBySql($sql);
			}
				
				if(count($modelDummyRpt)==0){
					Yii::app()->user->setFlash('danger', 'No Data Found');
				}
			else{
					$user_id=Yii::app()->user->id;
							
			//	$sql="delete from insistpro_rpt.rpt_upl_rek_dana_mutasi where user_id= '$user_id'";		
			//	$exec=DAO::executeSql($sql);	
					
				$x=0;
				//$rand_value=array();
				$modelReport->vo_random_value = rand(1, 999999999);
				foreach($model as $row)
				{
					$modelReport->tanggaltimestamp = $row->tanggaltimestamp;
					$modelReport->frombank = $row->frombank;
					$modelReport->instructionfrom = $row->instructionfrom;
					$modelReport->rdn = $row->rdn;
					$modelReport->branch = trim($row->branch_code);
					$modelReport->client_cd = $row->client_cd;
					$modelReport->client_name = $row->client_name;		
					$modelReport->beginningbalance = $row->beginningbalance;
					$modelReport->transactionvalue = $row->transactionvalue;
					$modelReport->closingbalance = $row->closingbalance;
					$modelReport->journal = $row->typetext;	
					
					
					if($modelReport->validate() && $modelReport->executeRpt())
					{
						//$url = $modelReport->showReport();
					}	
					
					$rand_value[]=$modelReport->vo_random_value;
				$x++;		
				}
				//$modelReport->vo_random_value=1;
				$url = $modelReport->showReport();		
					
				
			}
				
			
			}//end validate	
			
			foreach($model as $row)
					{
				//	$row->tgl_time =  $row->tanggaltimestamp;//Y-M-D H:I:S
					//if(DateTime::createFromFormat('Y-m-d H:i:s',$row->tanggaltimestamp))$row->tanggaltimestamp=DateTime::createFromFormat('Y-m-d H:i:s',$row->tanggaltimestamp)->format('d/m/Y H:i:s');
					if(DateTime::createFromFormat('Y-m-d H:i:s',$row->tanggaltimestamp))$row->tanggaltimestamp=DateTime::createFromFormat('Y-m-d H:i:s',$row->tanggaltimestamp)->format('d/m/Y H:i');
					
					}
			
			
		}//end print
			//Journal
			else{
				
				//Membuat Jurnal
				$rowCount = $_POST['rowCount'];
				
				$x;
				$save_flag = false; //False if no record is saved

				$modeldummy->attributes = $_POST['Tbankmutation'];
				
				
				for($x=0;$x<$rowCount;$x++)
				{
					$model[$x] = new Tbankmutation;
					$model[$x]->attributes = $_POST['Tbankmutation'][$x+1];
					$ip = Yii::app()->request->userHostAddress;
					if($ip=="::1")
						$ip = '127.0.0.1';
					
					$model[$x]->ip_address = $ip;
				
					$model[$x]->user_id =  Yii::app()->user->id;
					if(isset($_POST['Tbankmutation'][$x+1]['save_flg']) && $_POST['Tbankmutation'][$x+1]['save_flg'] == 'Y')
					{
						$save_flag = true;
						
							//INSERT
							$model[$x]->scenario = 'insert';
						
						$valid = $model[$x]->validate() && $valid;		
						
						
						$authorizedBackDated = $_POST['authorizedBackDated'];
			
						
					if(!$authorizedBackDated)
					{
						$currMonth = date('Ym');
						$docMonth = DateTime::createFromFormat('Y-m-d H:i:s',$model[$x]->tanggalefektif)->format('Ym');
						
						if($docMonth < $currMonth)
						{
					
							Yii::app()->user->setFlash('danger', 'You are not authorized to journal last month date ');
							
							$valid = FALSE;
						}
					}
					
					
					$amt = $model[$x]->transactionvalue;
					$client_cd = $model[$x]->client_cd;
					$doc_date =  DateTime::createFromFormat('Y-m-d H:i:s',$model[$x]->tanggalefektif)->format('Y/m/d H:i:s');
					$bank_mvmt_date = DateTime::createFromFormat('Y-m-d H:i:s',$model[$x]->tgl_time)->format('Y/m/d H:i:s');
					$bankrefence = $model[$x]->bankreference;
					//cek masih ada belum diapprove
					$sql="SELECT * FROM (SELECT 
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
		        AND DA.FIELD_NAME = 'BANK_REF_NUM'
		        AND DA.RECORD_SEQ = DD.RECORD_SEQ) BANK_REF_NUM,
    (SELECT FIELD_VALUE FROM T_MANY_DETAIL DA 
		        WHERE DA.TABLE_NAME = 'T_FUND_MOVEMENT' 
		        AND DA.UPDATE_DATE = DD.UPDATE_DATE
		        AND DA.UPDATE_SEQ = DD.UPDATE_SEQ
		        AND DA.FIELD_NAME = 'BANK_MVMT_DATE'
		        AND DA.RECORD_SEQ = DD.RECORD_SEQ) BANK_MVMT_DATE,
		(SELECT FIELD_VALUE FROM T_MANY_DETAIL DA 
		        WHERE DA.TABLE_NAME = 'T_FUND_MOVEMENT' 
		        AND DA.UPDATE_DATE = DD.UPDATE_DATE
		        AND DA.UPDATE_SEQ = DD.UPDATE_SEQ
		        AND DA.FIELD_NAME = 'TRX_AMT'
		        AND DA.RECORD_SEQ = DD.RECORD_SEQ) TRX_AMT,HH.APPROVED_STATUS,HH.MENU_NAME
		
		
		FROM T_MANY_DETAIL DD, T_MANY_HEADER HH WHERE DD.TABLE_NAME = 'T_FUND_MOVEMENT' AND DD.UPDATE_DATE = HH.UPDATE_DATE
		                      AND DD.UPDATE_SEQ = HH.UPDATE_SEQ AND DD.RECORD_SEQ = 1 
		                      AND DD.FIELD_NAME = 'DOC_DATE' AND HH.APPROVED_STATUS = 'E')
		                      WHERE TRX_AMT='$amt' and client_cd= '$client_cd' and doc_date = '$doc_date'
		                      and bank_ref_num = '$bankrefence' and bank_mvmt_date='$bank_mvmt_date' ";
                     //transactionvalue, client_cd, tanggal efektif(Y-m-d H:i:s)
                 $cek =Tmanydetail::model()->findAllBySql($sql);
                 if(DateTime::createFromFormat('Y H:i-m-d',$model[$x]->tanggaltimestamp))$model[$x]->tanggaltimestamp=DateTime::createFromFormat('Y H:i-m-d',$model[$x]->tanggaltimestamp)->format('d/m/Y H:i');
                 if($cek){
                 	Yii::app()->user->setFlash('danger', 'Masih ada belum diapprove');	
					$valid = FALSE;
                 }   
					
					
					}	
				}
		
				$valid = $valid && $save_flag;	
				if($valid)
				{
					$success = true;
					$connection  = Yii::app()->db;
					$transaction = $connection->beginTransaction();
					$menuName = 'UPLOAD RDN MUTATION';
					
					
					for($x=0;$success && $x<$rowCount;$x++)
					{
						if($model[$x]->save_flg == 'Y')
						{
						//	if(DateTime::createFromFormat('Y H:i:s-m-d',$model[$x]->tanggaltimestamp))$model[$x]->tanggaltimestamp=DateTime::createFromFormat('Y H:i:s-m-d',$model[$x]->tanggaltimestamp)->format('Y-m-d H:i:s');
							if(DateTime::createFromFormat('Y-m-d H:i:s',$model[$x]->tanggalefektif))$model[$x]->tanggalefektif=DateTime::createFromFormat('Y-m-d H:i:s',$model[$x]->tanggalefektif)->format('Y-m-d');
							if(DateTime::createFromFormat('d/m/Y H:i',$model[$x]->tanggaltimestamp))$model[$x]->tanggaltimestamp=DateTime::createFromFormat('d/m/Y H:i',$model[$x]->tanggaltimestamp)->format('Y-m-d');
							//if(DateTime::createFromFormat('d/m/Y',$model[$x]->tanggaltimestamp))$model[$x]->tanggaltimestamp=DateTime::createFromFormat('d/m/Y',$model[$x]->tanggaltimestamp)->format('Y-m-d');
							if(DateTime::createFromFormat('Y H:i-m-d',$model[$x]->tanggaltimestamp))$model[$x]->tanggaltimestamp=DateTime::createFromFormat('Y H:i-m-d',$model[$x]->tanggaltimestamp)->format('Y-m-d');
							
							
							if($model[$x]->executeSpHeader(AConstant::INBOX_STAT_INS,$menuName) > 0)$success = true;
							
							if($model[$x]->typetext=='Setoran' || $model[$x]->typetext=='Koreksi' || $model[$x]->typetext=='Mutasi'){
						
									//INSERT Type Mutasi Setoran
								if($success && $model[$x]->executeSpInbox(AConstant::INBOX_STAT_INS,1) > 0)$success = true; 
								else {
									$success = false;
								}
							}
							else{
								//Insert Mutasi Interest
								if($success && $model[$x]->executeSpInbox(AConstant::INBOX_STAT_INS,1) > 0)$success = true;
								else {
									$success = false;
								}
							$model[$x]->approveMutasiBca();
							if($model[$x]->error_code < 0)
							Yii::app()->user->setFlash('error', 'Approve '.$model[$x]->update_seq.', Error  '.$model[$x]->error_code.':'.$model[$x]->error_msg);	
								else
							Yii::app()->user->setFlash('success', 'Successfully approve '.$model[$x]->update_seq);
							}	
						}
				
							
					}
	
					if($success)
					{
						//	echo "<script>alert('test')</script>";
						$transaction->commit();
						Yii::app()->user->setFlash('success', 'Data Successfully Saved');
					$this->redirect(array('index'));
					}
					else {
						$transaction->rollback();
					}
				}
			// $modeldummy=new Tbankmutation();
			// $modeldummy->from_dt=Date('d/m/Y');
			// $modeldummy->to_dt=Date('d/m/Y');
// 			
			}	
		}
		else{
			
			//$date_now = Date('Y-m-d');
			$branch='All';
			$bank_name = Fundbank::model()->find("default_flg ='Y'")->bank_name;
			
					$sql="select X.* from (SELECT DISTINCT a.TANGGALTimestamp, a.currency, a.InstructionFrom, a.RDN, c.branch_code, c.client_cd, c.client_name, 
						a.BEGINNINGBALANCE, a.TRANSACTIONVALUE, a.CLOSINGBALANCE , 
					 a.BANKREFERENCE, 'N' Jurnal, b.cnt , 
					a.tanggalefektif, a.bankid, a.transactiontype, 
						 f.descrip TYPETEXT , 
					DECODE(a.InstructionFrom,'0000000000',DECODE(a.transactiontype,'NINT','$bank_name','XXX'),f.ip_bank_cd) frombank, 
					a.remark, 'N' default_remark,a.typemutasi 
					FROM( SELECT NVL(bank_ref_num,'X') bank_ref_num, BANK_ACCT_NUM, doc_Date, 
					        sl_acct_cd, 
					                                get_doc_date(1,doc_date) doc_date_min1 
						    FROM T_FUND_MOVEMENT a , MST_CLIENT_FLACCT b 
							WHERE doc_date BETWEEN trunc(sysdate) AND trunc(sysdate)
							AND approved_sts <> 'C' 
							AND a.client_Cd = b.client_Cd) d, 
							T_BANK_MUTATION  a, 
							( SELECT BANK_ACCT_NUM, MAX(client_cd) AS client_cd, COUNT(1) AS cnt 
								FROM 	MST_CLIENT_FLACCT 
								WHERE acct_stat <> 'C' 
							GROUP BY BANK_ACCT_NUM) b, 
							( SELECT client_cd, client_name, 
					DECODE(trim(rem_cd),'LOT','LO',DECODE(trim(MST_CLIENT.olt),'N',trim(branch_code),'LO')) branch_finan, 
							 branch_code 
							FROM MST_CLIENT ) c, 
							( 
							SELECT t.rdi_trx_type, t.descrip, t.grp, f.ip_bank_cd, t.db_cr_flg 
							   FROM mst_rdi_trx_type t, MST_FUND_BANK f 
							   WHERE t.fund_bank_cd = f.bank_cd 
							     AND t.grp ='S') f 
					WHERE a.TanggalEfektif BETWEEN trunc(sysdate) AND trunc(sysdate)
					AND a.InstructionFrom NOT IN (SELECT REPLACE(REPLACE(bank_acct_cd,'-',''),'.','') 
					                                                               FROM MST_BANK_ACCT 
    																			    WHERE  bank_acct_cd <> 'X') 
					AND a.transactiontype LIKE f.rdi_trx_type 
					AND a.typemutasi = f.db_Cr_flg 
					AND b.client_cd = c.client_cd 
					AND a.BANKREFERENCE = d.bank_ref_num(+) 
					AND  d.bank_ref_num IS NULL 
					AND a.rdn = b.BANK_ACCT_NUM 
					AND a.rdn = d.BANK_ACCT_NUM(+) 
					AND d.BANK_ACCT_NUM IS NULL 
					AND a.TanggalEfektif BETWEEN d.doc_date_min1(+) AND d.doc_date(+) 
					AND d.doc_date IS NULL 
					AND a.transactiontype = d.sl_acct_cd(+) 
					AND d.sl_acct_cd IS NULL 
					AND a.transactiontype <> '@IP@' 
					AND ('$branch' = 'All' 
					     OR  INSTR('$branch',trim(branch_finan)) > 0))X
					     order by client_cd,tanggaltimestamp desc ";				
					
		$model=Tbankmutation::model()->findAllBySql($sql);
			
			$modeldummy=new Tbankmutation();
			$modeldummy->from_dt=Date('d/m/Y');
			$modeldummy->to_dt=Date('d/m/Y');
			$modeldummy->type_mutasi='S';
			foreach($model as $row){
			$row->tgl_time =  $row->tanggaltimestamp;//Y-M-D H:I:S
			//if(DateTime::createFromFormat('Y-m-d H:i:s',$row->tanggaltimestamp))$row->tanggaltimestamp=DateTime::createFromFormat('Y-m-d H:i:s',$row->tanggaltimestamp)->format('d/m/Y H:i:s');
			if(DateTime::createFromFormat('Y-m-d H:i:s',$row->tanggaltimestamp))$row->tanggaltimestamp=DateTime::createFromFormat('Y-m-d H:i:s',$row->tanggaltimestamp)->format('d/m H:i');
			}
					

		
		}
		
		$this->render('index',array(
			'model'=>$model,
			'modeldummy'=>$modeldummy,
			'from_dt'=>$from_dt,
			'to_dt'=>$to_dt,
			'type'=>$type,
			'branch'=>$branch,
			'url'=>$url,
			'modelReport'=>$modelReport
			
		));
	}


	
	
}
