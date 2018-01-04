<?php

class ListofjournalController extends AAdminController
{
	
	public $layout='//layouts/admin_column3';

	public function actionIndex()
	{
		$modeldetail=array();
		$model= new Rptlistofjournal('List_of_journal','R_LIST_OF_JOURNAL','LIST_OF_JOURNAL.RPTDESIGN');
		$model->jur_type_vch='VCH*';
		$model->jur_type_gl='GL*';
		$model->jur_status ='A';
		$model->client=0;
		$modelReport=array();
		if(isset($_POST['scenario'])){
			$scenario = $_POST['scenario'];
			
			if($scenario == 'filter'){
				
				$model->attributes = $_POST['Rptlistofjournal'];
				
				
				if(DateTime::createFromFormat('d/m/Y',$model->bgn_dt))$model->bgn_dt=DateTime::createFromFormat('d/m/Y',$model->bgn_dt)->format('Y-m-d');
				if(DateTime::createFromFormat('d/m/Y',$model->end_dt))$model->end_dt=DateTime::createFromFormat('d/m/Y',$model->end_dt)->format('Y-m-d');
				
				if($model->jur_type_vch =='VCH*' || $model->jur_type_int =='INT*' || $model->jur_type_trx == 'TRX*'){
					$bgn_client='';
					$end_client='';
				}
				
				
				if($model->client == 0){
						$bgn_client = '%';
						$end_client = '_';
					} 
				else{
					$bgn_client=$model->client_spec_from;
					$end_client=$model->client_spec_to;
				}
				
				if($model->jur_status =='A' || $model->jur_status =='C'){
				
				
				
				if($model->bgn_dt !='' && $model->end_dt !='' && $model->file_no_from !='' && $model->file_no_to !='' && ($model->jur_type_bond !='' || $model->jur_type_gl !='' || $model->jur_type_int !='' || $model->jur_type_trx !='' ||$model->jur_type_vch !='')
				 && $model->client !='' && $model->jur_num_from !='' && $model->jur_num_to !=''){
				
				$sql="select x.* from (SELECT jvch_date as jur_date,  NULL client_Cd,  remarks, folder_Cd, jvch_num as doc_num		
					 FROM T_JVCHH			
					WHERE jvch_date BETWEEN '$model->bgn_dt' AND '$model->end_dt'			
					AND folder_Cd BETWEEN '$model->file_no_from' AND '$model->file_no_to'			
					AND jvch_num BETWEEN '$model->jur_num_from' AND '$model->jur_num_to'			
					and jvch_type <> 'RE'			
					AND approved_sts = '$model->jur_status'			
					UNION ALL			
					SELECT payrec_date, client_cd,  remarks, folder_Cd, payrec_num			
					FROM T_PAYRECH			
					WHERE  INSTR('$model->jur_type_bond$model->jur_type_gl$model->jur_type_int$model->jur_type_trx$model->jur_type_vch','VCH') > 0			
					AND payrec_date BETWEEN '$model->bgn_dt' AND '$model->end_dt'			
					AND folder_Cd BETWEEN '$model->file_no_from' AND '$model->file_no_to'			
					AND payrec_num BETWEEN '$model->jur_num_from' AND '$model->jur_num_to'			
					AND (client_cd BETWEEN '$bgn_client' AND '$end_client' OR ( client_Cd IS NULL AND  '$bgn_client' IS NULL)) 			
					AND approved_sts = '$model->jur_status'		
					UNION ALL			
					SELECT contr_dt, client_cd, ledger_nar, NULL, xn_doc_num			
					FROM(SELECT contr_dt, client_cd,  NULL, DECODE(SUBSTR(contr_num,6,1),'I', SUBSTR(contr_num,1,6)||'0'||SUBSTR(contr_num, 8), contr_num) AS contr_num 			
								FROM T_CONTRACTS t
								WHERE INSTR('$model->jur_type_bond$model->jur_type_gl$model->jur_type_int$model->jur_type_trx$model->jur_type_vch','TRX') > 0
								AND t.contr_dt BETWEEN '$model->bgn_dt' AND '$model->end_dt'
								AND contr_num BETWEEN '$model->jur_num_from' AND '$model->jur_num_to'
								AND client_cd BETWEEN '$bgn_client' AND '$end_client'
								AND ( contr_stat = '$model->jur_status' OR (contr_stat <> 'C'  AND '$model->jur_status' ='A'))
								AND '$model->jur_status' <> 'E') a,
					T_ACCOUNT_LEDGER b			
					WHERE a.contr_num = b.xn_doc_num			
					AND b.tal_id = 1			
					UNION ALL			
					SELECT trx_date,'id : '||TO_CHAR(trx_id) sl_acct_cd, DECODE(trx_type,'B','Buy ','Sell ')||bond_cd||DECODE(trx_type,'B','FROM ','TO ')||lawan ledger_nar, NULL, doc_num			
					FROM t_bond_trx 			
					WHERE INSTR('$model->jur_type_bond$model->jur_type_gl$model->jur_type_int$model->jur_type_trx$model->jur_type_vch','BOND') > 0			
					AND trx_date BETWEEN '$model->bgn_dt' AND '$model->end_dt'			
					AND trx_id BETWEEN '$model->bond_trx_from' AND '$model->bond_trx_to'			
					AND approved_sts = '$model->jur_status'			
					AND doc_num BETWEEN '$model->jur_num_from' AND '$model->jur_num_to'			
					UNION ALL			
					SELECT dncn_date,  sl_acct_Cd,  ledger_nar, folder_Cd, dncn_num			
					FROM T_DNCNH			
					WHERE INSTR('$model->jur_type_bond$model->jur_type_gl$model->jur_type_int$model->jur_type_trx$model->jur_type_vch','INT') > 0			
					AND dncn_date BETWEEN '$model->bgn_dt' AND '$model->end_dt'			
					AND folder_Cd BETWEEN '$model->file_no_from' AND '$model->file_no_to'			
					AND dncn_num BETWEEN '$model->jur_num_from' AND '$model->jur_num_to'			
					AND (sl_acct_cd BETWEEN '$bgn_client' AND '$end_client' OR ( sl_acct_Cd IS NULL AND  '$bgn_client' IS NULL)) 			
					AND approved_sts = '$model->jur_status' )X order by jur_date desc, client_cd";
				
				
				$modeldetail= Tjvchh::model()->findAllBySql($sql);
				foreach ($modeldetail as $row){$row->save_flg ='Y';}

			}
			else if($model->bgn_dt !='' && $model->end_dt !='' && $model->file_no_from !='' && $model->file_no_to !='' && $model->jur_num_from !='' && $model->jur_num_to !='' ){
					
					
					$sql="select x.* from (SELECT jvch_date as jur_date,  NULL client_Cd,  remarks, folder_Cd, jvch_num as doc_num		
					 FROM T_JVCHH			
					WHERE jvch_date BETWEEN '$model->bgn_dt' AND '$model->end_dt'			
					AND folder_Cd BETWEEN '$model->file_no_from' AND '$model->file_no_to'			
					AND jvch_num BETWEEN '$model->jur_num_from' AND '$model->jur_num_to'			
					and jvch_type <> 'RE'			
					AND approved_sts = '$model->jur_status'			
					UNION ALL			
					SELECT payrec_date, client_cd,  remarks, folder_Cd, payrec_num			
					FROM T_PAYRECH			
					WHERE  INSTR('$model->jur_type_bond$model->jur_type_gl$model->jur_type_int$model->jur_type_trx$model->jur_type_vch','VCH') > 0			
					AND payrec_date BETWEEN '$model->bgn_dt' AND '$model->end_dt'			
					AND folder_Cd BETWEEN '$model->file_no_from' AND '$model->file_no_to'			
					AND payrec_num BETWEEN '$model->jur_num_from' AND '$model->jur_num_to'			
					AND (client_cd BETWEEN '$bgn_client' AND '$end_client' OR ( client_Cd IS NULL AND  '$bgn_client' IS NULL)) 			
					AND approved_sts = '$model->jur_status'		
					UNION ALL			
					SELECT contr_dt, client_cd, ledger_nar, NULL, xn_doc_num			
					FROM(SELECT contr_dt, client_cd,  NULL, DECODE(SUBSTR(contr_num,6,1),'I', SUBSTR(contr_num,1,6)||'0'||SUBSTR(contr_num, 8), contr_num) AS contr_num 			
								FROM T_CONTRACTS t
								WHERE INSTR('$model->jur_type_bond$model->jur_type_gl$model->jur_type_int$model->jur_type_trx$model->jur_type_vch','TRX') > 0
								AND t.contr_dt BETWEEN '$model->bgn_dt' AND '$model->end_dt'
								AND contr_num BETWEEN '$model->jur_num_from' AND '$model->jur_num_to'
								AND client_cd BETWEEN '$bgn_client' AND '$end_client'
								AND ( contr_stat = '$model->jur_status' OR (contr_stat <> 'C'  AND '$model->jur_status' ='A'))
								AND '$model->jur_status' <> 'E') a,
					T_ACCOUNT_LEDGER b			
					WHERE a.contr_num = b.xn_doc_num			
					AND b.tal_id = 1			
					UNION ALL			
					SELECT trx_date,'id : '||TO_CHAR(trx_id) sl_acct_cd, DECODE(trx_type,'B','Buy ','Sell ')||bond_cd||DECODE(trx_type,'B','FROM ','TO ')||lawan ledger_nar, NULL, doc_num			
					FROM t_bond_trx 			
					WHERE INSTR('$model->jur_type_bond$model->jur_type_gl$model->jur_type_int$model->jur_type_trx$model->jur_type_vch','BOND') > 0			
					AND trx_date BETWEEN '$model->bgn_dt' AND '$model->end_dt'			
					AND trx_id BETWEEN '$model->bond_trx_from' AND '$model->bond_trx_to'			
					AND approved_sts = '$model->jur_status'			
					AND doc_num BETWEEN '$model->jur_num_from' AND '$model->jur_num_to'			
					UNION ALL			
					SELECT dncn_date,  sl_acct_Cd,  ledger_nar, folder_Cd, dncn_num			
					FROM T_DNCNH			
					WHERE INSTR('$model->jur_type_bond$model->jur_type_gl$model->jur_type_int$model->jur_type_trx$model->jur_type_vch','INT') > 0			
					AND dncn_date BETWEEN '$model->bgn_dt' AND '$model->end_dt'			
					AND folder_Cd BETWEEN '$model->file_no_from' AND '$model->file_no_to'			
					AND dncn_num BETWEEN '$model->jur_num_from' AND '$model->jur_num_to'			
					AND (sl_acct_cd BETWEEN '$bgn_client' AND '$end_client' OR ( sl_acct_Cd IS NULL AND  '$bgn_client' IS NULL)) 			
					AND approved_sts = '$model->jur_status')X order by jur_date desc, client_cd ";
				
				
				$modeldetail= Tjvchh::model()->findAllBySql($sql);
				foreach ($modeldetail as $row){$row->save_flg ='Y';}
					
				}
				else if($model->bgn_dt !='' && $model->end_dt !=''  && $model->jur_num_from !='' && $model->jur_num_to !='' ){
				//	echo "<script>alert('test')</script>";
					
					$sql="select x.* from (SELECT jvch_date as jur_date,  NULL client_Cd,  remarks, folder_Cd, jvch_num as doc_num		
					 FROM T_JVCHH			
					WHERE jvch_date BETWEEN '$model->bgn_dt' AND '$model->end_dt'			
					AND folder_Cd BETWEEN '$model->file_no_from' AND '$model->file_no_to'			
					AND jvch_num BETWEEN '$model->jur_num_from' AND '$model->jur_num_to'			
					and jvch_type <> 'RE'			
					AND approved_sts = '$model->jur_status'			
					UNION ALL			
					SELECT payrec_date, client_cd,  remarks, folder_Cd, payrec_num			
					FROM T_PAYRECH			
					WHERE  INSTR('$model->jur_type_bond$model->jur_type_gl$model->jur_type_int$model->jur_type_trx$model->jur_type_vch','VCH') > 0			
					AND payrec_date BETWEEN '$model->bgn_dt' AND '$model->end_dt'			
						
					AND payrec_num BETWEEN '$model->jur_num_from' AND '$model->jur_num_to'			
					AND (client_cd BETWEEN '$bgn_client' AND '$end_client' OR ( client_Cd IS NULL AND  '$bgn_client' IS NULL)) 			
					AND approved_sts = '$model->jur_status'		
					UNION ALL			
					SELECT contr_dt, client_cd, ledger_nar, NULL, xn_doc_num			
					FROM(SELECT contr_dt, client_cd,  NULL, DECODE(SUBSTR(contr_num,6,1),'I', SUBSTR(contr_num,1,6)||'0'||SUBSTR(contr_num, 8), contr_num) AS contr_num 			
								FROM T_CONTRACTS t
								WHERE INSTR('$model->jur_type_bond$model->jur_type_gl$model->jur_type_int$model->jur_type_trx$model->jur_type_vch','TRX') > 0
								AND t.contr_dt BETWEEN '$model->bgn_dt' AND '$model->end_dt'
								AND contr_num BETWEEN '$model->jur_num_from' AND '$model->jur_num_to'
								AND client_cd BETWEEN '$bgn_client' AND '$end_client'
								AND ( contr_stat = '$model->jur_status' OR (contr_stat <> 'C'  AND '$model->jur_status' ='A'))
								AND '$model->jur_status' <> 'E') a,
					T_ACCOUNT_LEDGER b			
					WHERE a.contr_num = b.xn_doc_num			
					AND b.tal_id = 1			
					UNION ALL			
					SELECT trx_date,'id : '||TO_CHAR(trx_id) sl_acct_cd, DECODE(trx_type,'B','Buy ','Sell ')||bond_cd||DECODE(trx_type,'B','FROM ','TO ')||lawan ledger_nar, NULL, doc_num			
					FROM t_bond_trx 			
					WHERE INSTR('$model->jur_type_bond$model->jur_type_gl$model->jur_type_int$model->jur_type_trx$model->jur_type_vch','BOND') > 0			
								
					
					AND approved_sts = '$model->jur_status'			
					AND doc_num BETWEEN '$model->jur_num_from' AND '$model->jur_num_to'			
					UNION ALL			
					SELECT dncn_date,  sl_acct_Cd,  ledger_nar, folder_Cd, dncn_num			
					FROM T_DNCNH			
					WHERE INSTR('$model->jur_type_bond$model->jur_type_gl$model->jur_type_int$model->jur_type_trx$model->jur_type_vch','INT') > 0			
					AND dncn_date BETWEEN '$model->bgn_dt' AND '$model->end_dt'			
						
					AND dncn_num BETWEEN '$model->jur_num_from' AND '$model->jur_num_to'			
					AND (sl_acct_cd BETWEEN '$bgn_client' AND '$end_client' OR ( sl_acct_Cd IS NULL AND  '$bgn_client' IS NULL)) 			
					AND approved_sts = '$model->jur_status')X order by jur_date desc, client_cd ";
				
				
				$modeldetail= Tjvchh::model()->findAllBySql($sql);
				foreach ($modeldetail as $row){$row->save_flg ='Y';}
					
				}

					else if($model->bgn_dt !='' && $model->end_dt !=''  && $model->file_no_from !='' && $model->file_no_to !=''){
					
					//echo "<script>alert('test')</script>";
					$sql="select x.* from (SELECT jvch_date as jur_date,  NULL client_Cd,  remarks, folder_Cd, jvch_num as doc_num		
					 FROM T_JVCHH			
					WHERE jvch_date BETWEEN '$model->bgn_dt' AND '$model->end_dt'			
					AND folder_Cd BETWEEN '$model->file_no_from' AND '$model->file_no_to'			
							
					and jvch_type <> 'RE'			
					AND approved_sts = '$model->jur_status'			
					UNION ALL			
					SELECT payrec_date, client_cd,  remarks, folder_Cd, payrec_num			
					FROM T_PAYRECH			
					WHERE  INSTR('$model->jur_type_bond$model->jur_type_gl$model->jur_type_int$model->jur_type_trx$model->jur_type_vch','VCH') > 0			
					AND payrec_date BETWEEN '$model->bgn_dt' AND '$model->end_dt'			
					AND folder_Cd BETWEEN '$model->file_no_from' AND '$model->file_no_to'			
						
					AND (client_cd BETWEEN '$bgn_client' AND '$end_client' OR ( client_Cd IS NULL AND  '$bgn_client' IS NULL)) 			
					AND approved_sts = '$model->jur_status'		
					UNION ALL			
					SELECT contr_dt, client_cd, ledger_nar, NULL, xn_doc_num			
					FROM(SELECT contr_dt, client_cd,  NULL, DECODE(SUBSTR(contr_num,6,1),'I', SUBSTR(contr_num,1,6)||'0'||SUBSTR(contr_num, 8), contr_num) AS contr_num 			
								FROM T_CONTRACTS t
								WHERE INSTR('$model->jur_type_bond$model->jur_type_gl$model->jur_type_int$model->jur_type_trx$model->jur_type_vch','TRX') > 0
								AND t.contr_dt BETWEEN '$model->bgn_dt' AND '$model->end_dt'
								
								AND client_cd BETWEEN '$bgn_client' AND '$end_client'
								AND ( contr_stat = '$model->jur_status' OR (contr_stat <> 'C'  AND '$model->jur_status' ='A'))
								AND '$model->jur_status' <> 'E') a,
					T_ACCOUNT_LEDGER b			
					WHERE a.contr_num = b.xn_doc_num			
					AND b.tal_id = 1			
					UNION ALL			
					SELECT trx_date,'id : '||TO_CHAR(trx_id) sl_acct_cd, DECODE(trx_type,'B','Buy ','Sell ')||bond_cd||DECODE(trx_type,'B','FROM ','TO ')||lawan ledger_nar, NULL, doc_num			
					FROM t_bond_trx 			
					WHERE INSTR('$model->jur_type_bond$model->jur_type_gl$model->jur_type_int$model->jur_type_trx$model->jur_type_vch','BOND') > 0			
					AND trx_date BETWEEN '$model->bgn_dt' AND '$model->end_dt'			
							
					AND approved_sts = '$model->jur_status'			
					AND doc_num BETWEEN '$model->jur_num_from' AND '$model->jur_num_to'			
					UNION ALL			
					SELECT dncn_date,  sl_acct_Cd,  ledger_nar, folder_Cd, dncn_num			
					FROM T_DNCNH			
					WHERE INSTR('$model->jur_type_bond$model->jur_type_gl$model->jur_type_int$model->jur_type_trx$model->jur_type_vch','INT') > 0			
					AND dncn_date BETWEEN '$model->bgn_dt' AND '$model->end_dt'			
					AND folder_Cd BETWEEN '$model->file_no_from' AND '$model->file_no_to'			
							
					AND (sl_acct_cd BETWEEN '$bgn_client' AND '$end_client' OR ( sl_acct_Cd IS NULL AND  '$bgn_client' IS NULL)) 			
					AND approved_sts = '$model->jur_status' )X order by jur_date desc, client_cd";
				
				$modeldetail= Tjvchh::model()->findAllBySql($sql);
				foreach ($modeldetail as $row){$row->save_flg ='Y';}
					
				}else {
					
				$sql="select x.* from (SELECT jvch_date as jur_date,  NULL client_Cd,  remarks, folder_Cd, jvch_num as doc_num		
					 FROM T_JVCHH			
					WHERE jvch_date BETWEEN '$model->bgn_dt' AND '$model->end_dt'			
					and jvch_type <> 'RE'			
					AND approved_sts = '$model->jur_status'			
					UNION ALL			
					SELECT payrec_date, client_cd,  remarks, folder_Cd, payrec_num			
					FROM T_PAYRECH			
					WHERE  			
					payrec_date BETWEEN '$model->bgn_dt' AND '$model->end_dt'			
					AND approved_sts = '$model->jur_status'		
					UNION ALL			
					SELECT contr_dt, client_cd, ledger_nar, NULL, xn_doc_num			
					FROM(SELECT contr_dt, client_cd,  NULL, DECODE(SUBSTR(contr_num,6,1),'I', SUBSTR(contr_num,1,6)||'0'||SUBSTR(contr_num, 8), contr_num) AS contr_num 			
								FROM T_CONTRACTS t
								WHERE 
								t.contr_dt BETWEEN '$model->bgn_dt' AND '$model->end_dt'
								AND ( contr_stat = '$model->jur_status' OR (contr_stat <> 'C'  AND '$model->jur_status' ='A'))
								AND '$model->jur_status' <> 'E') a,
					T_ACCOUNT_LEDGER b			
					WHERE a.contr_num = b.xn_doc_num			
					AND b.tal_id = 1			
					UNION ALL			
					SELECT trx_date,'id : '||TO_CHAR(trx_id) sl_acct_cd, DECODE(trx_type,'B','Buy ','Sell ')||bond_cd||DECODE(trx_type,'B','FROM ','TO ')||lawan ledger_nar, NULL, doc_num			
					FROM t_bond_trx 			
					WHERE 			
					trx_date BETWEEN '$model->bgn_dt' AND '$model->end_dt'						
					AND approved_sts = '$model->jur_status'					
					UNION ALL			
					SELECT dncn_date,  sl_acct_Cd,  ledger_nar, folder_Cd, dncn_num			
					FROM T_DNCNH			
					WHERE 			
					 dncn_date BETWEEN '$model->bgn_dt' AND '$model->end_dt'					
					AND approved_sts = '$model->jur_status')X order by jur_date desc, client_cd";
				
				$modeldetail= Tjvchh::model()->findAllBySql($sql);
				foreach ($modeldetail as $row){$row->save_flg ='Y';}
			}

				}
			else{
				
			$sql=" SELECT * FROM (
SELECT NULL CLIENT_CD, 'Y' SAVE_FLG,
					(SELECT TO_DATE(FIELD_VALUE,'YYYY/MM/DD HH24:MI:SS') FROM T_MANY_DETAIL DA 
					        WHERE DA.TABLE_NAME = 'T_JVCHH' 
					        AND DA.UPDATE_DATE = DD.UPDATE_DATE
					        AND DA.UPDATE_SEQ = DD.UPDATE_SEQ
					        AND DA.FIELD_NAME = 'JVCH_DATE'
					        AND DA.RECORD_SEQ = DD.RECORD_SEQ) JUR_DATE, 
					(SELECT FIELD_VALUE FROM T_MANY_DETAIL DA 
					        WHERE DA.TABLE_NAME = 'T_JVCHH' 
					        AND DA.UPDATE_DATE = DD.UPDATE_DATE
					        AND DA.UPDATE_SEQ = DD.UPDATE_SEQ
					        AND DA.FIELD_NAME = 'FOLDER_CD'
					        AND DA.RECORD_SEQ = DD.RECORD_SEQ) FOLDER_CD,
					(SELECT FIELD_VALUE FROM T_MANY_DETAIL DA 
					        WHERE DA.TABLE_NAME = 'T_JVCHH' 
					        AND DA.UPDATE_DATE = DD.UPDATE_DATE
					        AND DA.UPDATE_SEQ = DD.UPDATE_SEQ
					        AND DA.FIELD_NAME = 'JVCH_NUM'
					        AND DA.RECORD_SEQ = DD.RECORD_SEQ) DOC_NUM,
					(SELECT FIELD_VALUE FROM T_MANY_DETAIL DA 
					        WHERE DA.TABLE_NAME = 'T_JVCHH' 
					        AND DA.UPDATE_DATE = DD.UPDATE_DATE
					        AND DA.UPDATE_SEQ = DD.UPDATE_SEQ
					        AND DA.FIELD_NAME = 'REMARKS'
					        AND DA.RECORD_SEQ = DD.RECORD_SEQ) REMARKS
					FROM T_MANY_DETAIL DD, T_MANY_HEADER HH WHERE DD.TABLE_NAME = 'T_JVCHH' AND DD.UPDATE_DATE = HH.UPDATE_DATE
					                      AND DD.UPDATE_SEQ = HH.UPDATE_SEQ AND  DD.RECORD_SEQ =1
					                     AND DD.FIELD_NAME = 'JVCH_DATE' AND HH.APPROVED_STATUS = 'E' ORDER BY HH.UPDATE_SEQ) A
                               
WHERE A.JUR_DATE BETWEEN  DECODE('$model->bgn_dt','','1000-01-01','$model->bgn_dt')
	 and DECODE('$model->end_dt','','2050-12-31','$model->end_dt')       
	 AND folder_Cd BETWEEN '$model->file_no_from' AND '$model->file_no_to'			                  
order by A.jur_date desc
";					
								
						
						$modeldetail= Tjvchh::model()->findAllBySql($sql);
						
						}
						}// end filter
				else if($scenario == 'print'){
						
					
					$rowCount = $_POST['rowCount'];	
					$success = false;
					$connection  = Yii::app()->dbrpt;
					$connection->enableParamLogging = false; //WT disable save data to log
					$transaction = $connection->beginTransaction();			
					$rand_value=abs(mt_rand());
					for($x=0;$x<$rowCount;$x++){
						$modelReport[$x] = new Rptlistofjournal('LIST_OF_JOURNAL','R_LIST_OF_JOURNAL','List_of_journal.rptdesign');	
						$modeldetail[$x] =  new Tjvchh;
						$model->attributes = $_POST['Rptlistofjournal'];				
						$modeldetail[$x]->attributes = $_POST['Tjvchh'][$x+1];
						$modelReport[0]->vo_random_value = $rand_value;
						$modelReport[0]->vp_userid = Yii::app()->user->id;
					if(DateTime::createFromFormat('d/m/Y',$model->bgn_dt))$model->bgn_dt=DateTime::createFromFormat('d/m/Y',$model->bgn_dt)->format('Y-m-d');
					if(DateTime::createFromFormat('d/m/Y',$model->end_dt))$model->end_dt=DateTime::createFromFormat('d/m/Y',$model->end_dt)->format('Y-m-d');			
				
						
						if(isset($_POST['Tjvchh'][$x+1]['save_flg']) && $_POST['Tjvchh'][$x+1]['save_flg'] == 'Y')
					{
						//echo "<script>alert('test')</script>";
						$modelReport[$x]->doc_num = $modeldetail[$x]->doc_num;
						$modelReport[$x]->jur_status = $model->jur_status;
						$modelReport[$x]->bgn_dt = $model->bgn_dt;
						$modelReport[$x]->end_dt = $model->end_dt;	
						$modelReport[$x]->file_no_from = $model->file_no_from;
						$modelReport[$x]->file_no_to = $model->file_no_to;
						$modelReport[$x]->vo_random_value = $rand_value;
						$modelReport[$x]->vp_userid = $modelReport[0]->vp_userid ;
						if($modelReport[$x]->validate() && $modelReport[$x]->executeReportGenSp()>0){
							$success = true;	
						}	
						else{
								$success =false;
							}
					}		
						
					}	
						if($success)
					{
						$transaction->commit();	
						//Yii::app()->user->setFlash('success', 'Data Successfully Saved');
						$this->redirect(array('Report','random_value'=>$modelReport[0]->vo_random_value, 'user_id'=>$modelReport[0]->vp_userid));
					}
					else {
						$transaction->rollback();
						Yii::app()->user->setFlash('danger', $modelReport[0]->vo_errmsg);
					}
					}//end print	
				}//end scenario
		else{
			//load first time
		}
		
		
		
		$this->render('index',array('model'=>$model,
									'modeldetail'=>$modeldetail,
									'modelReport'=>$modelReport));
	}


	public function actionReport($random_value,$user_id){
	
	
		$modelreport= new Rptlistofjournal('LIST_OF_JOURNAL','R_LIST_OF_JOURNAL','List_of_journal.rptdesign');
		$modelreport->vo_random_value = $random_value;
		$modelreport->vp_userid=$user_id;
		$url = $modelreport->showReport();
			
			$this->render('_report',array(
			'url'=>$url,
			'modelreport'=>$modelreport
			));
	}

}
?>