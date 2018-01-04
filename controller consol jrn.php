<?php

class TconsoljrnController extends AAdminController
{
	/**
	 * @var string the default layout for the views. Defaults to '//layouts/column2', meaning
	 * using two-column layout. See 'protected/views/layouts/column2.php'.
	 */
	public $layout='//layouts/admin_column3';

	public function actionIndex()
	{
			$model=array();
			$success = false;
			$modelfilter=new Tconsoljrn;
			$cancel_reason = '';
			$valid = true;
			
			if(isset($_POST['scenario'])){
		$scenario = $_POST['scenario'];
				if($scenario == 'filter'){
			$modelfilter->attributes = $_POST['Tconsoljrn'];
					
if(DateTime::createFromFormat('d/m/Y',$modelfilter->rep_date))$modelfilter->rep_date=DateTime::createFromFormat('d/m/Y',$modelfilter->rep_date)->format('Y-m-d');
					$model=Tconsoljrn::model()->findAll(array('condition'=>"doc_date ='$modelfilter->rep_date' and approved_sts='A'",'order'=>'tal_id'));
					
					foreach($model as $row){
						if(DateTime::createFromFormat('Y-m-d H:i:s',$row->doc_date))$row->doc_date=DateTime::createFromFormat('Y-m-d H:i:s',$row->doc_date)->format('d/m/Y');
						$row->sl_acct_cd=trim($row->sl_acct_cd);
						$row->gl_acct_cd=trim($row->gl_acct_cd);
						$row->old_xn_doc_num=$row->xn_doc_num;
						$row->old_tal_id=$row->tal_id;
						$row->old_doc_date=$row->doc_date;
					}
if(DateTime::createFromFormat('Y-m-d',$modelfilter->rep_date))$modelfilter->rep_date=DateTime::createFromFormat('Y-m-d',$modelfilter->rep_date)->format('d/m/Y');
					if(count($model)==0){
						$modelfilter->addError('save_flg','Tidak ada data ditemukan');
					}
				}
				//proses
				else{
					$rowCount = $_POST['rowCount'];
					$x;
				
				$save_flag = false; //False if no record is saved
				
				if(isset($_POST['cancel_reason']))
				{
					if(!$_POST['cancel_reason'])
					{
						$valid = false;
						Yii::app()->user->setFlash('error', 'Cancel Reason Must be Filled');
					}
					else
					{
						$cancel_reason = $_POST['cancel_reason'];
					}
				}

					
					for($x=0;$x<$rowCount;$x++)
				{
					$model[$x] = new Tconsoljrn;
					$modelfilter->attributes = $_POST['Tconsoljrn'];
					$model[$x]->attributes = $_POST['Tconsoljrn'][$x+1];
					
					if(isset($_POST['Tconsoljrn'][$x+1]['save_flg']) && $_POST['Tconsoljrn'][$x+1]['save_flg'] == 'Y')
					{
						$save_flag = true;
						if(isset($_POST['Tconsoljrn'][$x+1]['cancel_flg']))
						{
							if($_POST['Tconsoljrn'][$x+1]['cancel_flg'] == 'Y')
							{
								//CANCEL
								$model[$x]->scenario = 'cancel';
								$model[$x]->cancel_reason = $_POST['cancel_reason'];
							}
							else 
							{
								//UPDATE
								$model[$x]->scenario = 'update';
							}
						}
						else 
						{
							//INSERT
							$model[$x]->scenario = 'insert';
						}
						$valid = $model[$x]->validate() && $valid;
					}
				}
				
					$valid = $valid && $save_flag;
					
					if($valid)
				{
					$success = true;
					$connection  = Yii::app()->db;
					$transaction = $connection->beginTransaction();
					$menuName = 'CONSOLIDATION JOURNAL ENTRY';
					$modelfilter->attributes = $_POST['Tconsoljrn'];
if(DateTime::createFromFormat('d/m/Y',$modelfilter->rep_date))$modelfilter->rep_date=DateTime::createFromFormat('d/m/Y',$modelfilter->rep_date)->format('Y-m-d');
					$tanggal=$modelfilter->rep_date;
					$sql="SELECT Get_Docnum_Jvch(to_date('$tanggal','yyyy-mm-dd'),'GL') as jvch_num from dual";
					$num=DAO::queryRowSql($sql);
					$jvch_num=$num['jvch_num'];
					$ip = Yii::app()->request->userHostAddress;
						if($ip=="::1")
						$ip = '127.0.0.1';
					
					$modelfilter->ip_address = $ip;
					$modelfilter->user_id =  Yii::app()->user->id;
					
					
					
					
					$recordSeq=1;
					for($x=0;$success && $x<$rowCount;$x++)
					{
						$model[$x]->curr_val = str_replace( ',', '', $model[$x]->curr_val );
						$model[$x]->user_id =$modelfilter->user_id;
						$model[$x]->ip_address=$modelfilter->ip_address;
					
						if($model[$x]->save_flg == 'Y')
						{
							if($model[$x]->cancel_flg == 'Y')
							{
								if($modelfilter->executeSpHeader(AConstant::INBOX_STAT_CAN,$menuName) > 0)$success = true;
									$model[$x]->update_date =$modelfilter->update_date;
							$model[$x]->update_seq= $modelfilter->update_seq;
								//CANCEL
						if($success && $model[$x]->executeSp(AConstant::INBOX_STAT_CAN,$model[$x]->old_doc_date,$model[$x]->old_xn_doc_num,$model[$x]->old_tal_id,$recordSeq) > 0)$success = true;
						else {
							$success = false;
						}
							}
							else if($model[$x]->old_xn_doc_num)
							{
								if($modelfilter->executeSpHeader(AConstant::INBOX_STAT_UPD,$menuName) > 0)$success = true;
									$model[$x]->update_date =$modelfilter->update_date;
						$model[$x]->update_seq= $modelfilter->update_seq;
								//UPDATE
							//$model[$x]->xn_doc_num=$jvch_num;
							if($success && $model[$x]->executeSp(AConstant::INBOX_STAT_UPD,$model[$x]->old_doc_date,$model[$x]->old_xn_doc_num,$model[$x]->old_tal_id,$recordSeq) > 0)$success = true;
							else {
								$success = false;
							}
							}			
							else 
							{ if($modelfilter->executeSpHeader(AConstant::INBOX_STAT_INS,$menuName) > 0)$success = true;
								$model[$x]->update_date =$modelfilter->update_date;
								$model[$x]->update_seq= $modelfilter->update_seq;
								//INSERT
								$model[$x]->xn_doc_num=$jvch_num;
						if($success && $model[$x]->executeSp(AConstant::INBOX_STAT_INS,$model[$x]->doc_date,$model[$x]->xn_doc_num,$model[$x]->tal_id,$recordSeq) > 0)$success = true;
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
				}//end valid
				if(DateTime::createFromFormat('Y-m-d',$modelfilter->rep_date))$modelfilter->rep_date=DateTime::createFromFormat('Y-m-d',$modelfilter->rep_date)->format('d/m/Y');	
				}
			
			
			}//end scenario
			else{
				$model =Tconsoljrn::model()->findAll("doc_date=trunc(sysdate)");
			}
						
			
			
			
			$this->render('index',array(
			'model'=>$model,
			'modelfilter'=>$modelfilter,
			'cancel_reason'=>$cancel_reason,
			
		));
			
			
	}

	public function actionAjxValidateCancel() //LO: The purpose of this 'empty' function is to check whether an user is authorized to perform cancellation
	{
		$resp = '';
		echo json_encode($resp);
	}



}
		