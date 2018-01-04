<?php

class ProsesimportrekdanaController extends AAdminController
{
	
	public $layout='//layouts/admin_column3';
	
	
	public function actionIndex()
	{	$modelfail=Vfailimprekdana::model()->findAll();		
		$modelclient=Clientflacct::model()->findAll();
		$model = new Trekdanaksei();
		//$model->unsetAttributes();
		$cif = new Cif('search');
		$cif->unsetAttributes();
		$import_type;
		$filename = '';
		$valid = TRUE;
		$success = false;
		$cancel_reason = '';
		
		if(isset($_POST['scenario'])){
	
			if($_POST['scenario'] == 'import'){
				
			
			if(isset($_POST['Trekdanaksei']))
		{
			$model->attributes = $_POST['Trekdanaksei'];
			if($model->validate()){
				
			
			$import_type = $model->import_type;
		
			//buat ambil file yang di upload tanpa $_FILES
			$model->file_upload = CUploadedFile::getInstance($model,'file_upload');
			
			$path = FileUpload::getFilePath(FileUpload::IMPORT_REK_DANA,$model->file_upload );
			$model->file_upload->saveAs($path);
			$filename = $model->file_upload;
			
		
			
			if($import_type == AConstant::IMPORT_TYPE_PERTAMA)
			{
				
				//lakukan backup
				$model->executeBackup();
						/*		
					$query = "SELECT DFLG1  
							FROM mst_sys_param  
							WHERE  param_id = 'IMPORT_CLIENT_FLACCT' AND param_cd1 = 'UPDATE'
							AND DSTR1 = 'MST_CLIENT_FLACCT'";
							$res   = DAO::queryRowSql($query);
							
							if($res['dflg1']=='Y')
							{
								$ip = Yii::app()->request->userHostAddress;
								if($ip=="::1")
								$ip = '127.0.0.1';
								$model->ip_address = $ip;
								if( $model->executeInsert()>0){$success=TRUE;
							
								}
								else{
									
									$success=false;
								}
								
								}*/
							
			}
					$success=TRUE;
					$connection  = Yii::app()->db;
					$transaction = $connection->beginTransaction();	
					
			//insert data ke Trekdanaksei
			$lines = file($path);
			foreach ($lines as $line_num => $line) 
			{
				
				
				if($line_num!=0)
				{
					$pieces = explode('|',$line);
					
					$model->name = $pieces[4];
					$model->sid = $pieces[5];
					$model->subrek = $pieces[6];
					if(strlen($pieces[7])>10){
						$model->rek_dana = substr($pieces[7], 6);
					}
					else{
						$model->rek_dana = $pieces[7];
					}
					
					
					$model->bank_cd = $pieces[8];
					$model->create_dt = new CDbExpression("TO_DATE('".date('Y-m-d H:i:s')."','YYYY-MM-DD HH24:MI:SS')");
					$activity = trim($pieces[10]);
				
					if($activity!=='C')
					{
						if($model->save())
						{
							$model = new Trekdanaksei();
								$query = "SELECT DFLG1  
							FROM mst_sys_param  
							WHERE  param_id = 'IMPORT_CLIENT_FLACCT' AND param_cd1 = 'UPDATE'
							AND DSTR1 = 'MST_CLIENT_FLACCT'";
							$res   = DAO::queryRowSql($query);
							
							if($res['dflg1']=='Y')
							{
								$ip = Yii::app()->request->userHostAddress;
								if($ip=="::1")
								$ip = '127.0.0.1';
								$model->ip_address = $ip;
								if( $model->executeInsert()>0){$success=TRUE;
							
								}
								else{
									
									$success=false;
								}
								
								}
							//$model->unsetAttributes();
						}//end if model save
					}//pieces != C
				}//end if line!=0
			}//end foreach
			if($success){
				
			
				//setelah di upload dan dibaca, delete file nya
			unlink(FileUpload::getFilePath(FileUpload::IMPORT_REK_DANA,$filename ));
			$transaction->commit();
			Yii::app()->user->setFlash('success', 'Successfully upload '.$filename);
			$this->redirect(array('/master/import/index'));
			}
			else{
				
				$transaction->rollback();
				
			}
			
			
			}
			}//end if isset
				
			}//end import
			else{
				//echo "<script>alert('save')</script>";
				
				$rowCount = $_POST['rowCount'];
				$x;
				$save_flag = false; //False if no record is saved
				
				$ip = Yii::app()->request->userHostAddress;
				if($ip=="::1")
				$ip = '127.0.0.1';
			
			$modelfail[0]->ip_address = $ip;
			$modelfail[0]->upd_dt  = Yii::app()->datetime->getDateTimeNow();
			$modelfail[0]->upd_by  = Yii::app()->user->id;
			$modelfail[0]->user_id =  Yii::app()->user->id;
			$modelclient[0]->ip_address = $ip;
			$modelclient[0]->upd_dt  = Yii::app()->datetime->getDateTimeNow();
			$modelclient[0]->upd_by  = Yii::app()->user->id;
			$modelclient[0]->user_id =  Yii::app()->user->id;
			
			
			
					for($x=0;$x<$rowCount;$x++)
				{
					$modelfail[$x] = new Vfailimprekdana;
					
					$modelfail[$x]->attributes = $_POST['Vfailimprekdana'][$x+1];
					
					
					
					if(isset($_POST['Vfailimprekdana'][$x+1]['save_flg']) && $_POST['Vfailimprekdana'][$x+1]['save_flg'] == 'Y')
					{
						$save_flag = true;
						if(isset($_POST['Vfailimprekdana'][$x+1]['cancel_flg']))
						{
							if($_POST['Vfailimprekdana'][$x+1]['cancel_flg'] == 'Y')
							{
								//CANCEL
								$modelfail[$x]->scenario = 'cancel';
								$modelfail[$x]->cancel_reason = $_POST['cancel_reason'];  	
								
							}
							else 
							{
								//UPDATE
								$modelfail[$x]->scenario = 'update';
								
							}
						}
						else 
						{
							//INSERT
							
							$modelfail[$x]->scenario = 'insert';
						}
						$valid = $modelfail[$x]->validate() && $valid;		
					
					}	
						
				}
				
				$valid = $valid && $save_flag;
			
				if($valid)
				{ 
					$success = true;
					$connection  = Yii::app()->db;
					$transaction = $connection->beginTransaction();
					$menuName = 'IMPORT REKENING DANA';
					$modelfail[0]->update_date=Yii::app()->datetime->getDateTimeNow();
					
					
					
					for($x=0;$success && $x<$rowCount;$x++)
					{
						
						
						if($modelfail[$x]->save_flg == 'Y')
						{
							if($modelfail[$x]->executeSpHeader(AConstant::INBOX_STAT_UPD,$menuName) > 0)$success = true;
							
							 $modelfail[$x]->update_date=$modelfail[$x]->update_date;
						 $modelfail[$x]->update_seq=$modelfail[$x]->update_seq;
								
					
							if($modelfail[$x]->client_cd)
							{ //INSERT
								$modelfail[$x]->acct_stat='I';
								if( $success  && $modelfail[$x]-> executeSp(AConstant::INBOX_STAT_INS,$modelfail[$x]->client_cd, $modelfail[$x]->new_bank_acct,1) > 0)$success = true;
								else {
									$success = false;
								}	
								$client_cd=$modelfail[$x]->client_cd;
								$bank_acct_num=$modelfail[$x]->bank_acct;
								$modelclient[$x]= Clientflacct::model()->find("client_cd='$client_cd' and bank_acct_num='$bank_acct_num' ");
								//UPDATE
								 $modelclient[$x]->update_date=$modelfail[$x]->update_date;
								 $modelclient[$x]->update_seq=$modelfail[$x]->update_seq;
								$modelclient[$x]->acct_stat='C';
								$modelclient[$x]->client_cd=$modelfail[$x]->client_cd;
								$modelclient[$x]->bank_acct_num=$modelfail[$x]->bank_acct;
								
								if( $success && $modelclient[$x]->executeSpImport(AConstant::INBOX_STAT_UPD,$modelfail[$x]->client_cd, $modelfail[$x]->bank_acct,2) > 0)$success = true;
								else {
									$success = false;
								}
								
							}			

						}
					}
	
					if($success)
					{
						$transaction->commit();
						Yii::app()->user->setFlash('success', 'Data Successfully Saved');
						$this->redirect(array('index'));
					}
					else {
						$transaction->rollback();
					}
				}
			}

		}
		
		if(empty($model->import_type)) 
		{
			//supaya ada nilai default di checkbox nya
			$model->import_type = AConstant::IMPORT_TYPE_PERTAMA;
		}//end else
		
		$this->render('index',array(
			'model'=>$model,
			'cif'=>$cif,
			'modelfail'=>$modelfail,
			'modelclient'=>$modelclient
		));
	}
}
