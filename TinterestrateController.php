<?php

class TinterestrateController extends AAdminController
{
	/**
	 * @var string the default layout for the views. Defaults to '//layouts/column2', meaning
	 * using two-column layout. See 'protected/views/layouts/column2.php'.
	 */
	public $layout='//layouts/admin_column2';

	public function actionView($client_cd,$eff_dt)
	{
		$modelClient = Client::model()->findByPk($client_cd);
		$model=Tinterestrate::model()->findAll(array('select'=>'client_cd,eff_dt,int_on_receivable,int_on_payable','condition'=>"client_cd = trim('$client_cd') AND approved_stat = 'A'",'order'=>'eff_dt DESC'));
		
		$this->render('view',array(
			'model'=>$model,
			'modelClient'=>$modelClient,
		));
	}

	public function actionCreate()
	{
		$model=new Tinterestrate;

		if(isset($_POST['Tinterestrate']))
		{
			$model->attributes=$_POST['Tinterestrate'];
			if($model->save()){
            	Yii::app()->user->setFlash('success', 'Successfully create '.$model->client_cd);
				$this->redirect(array('view','id'=>$model->client_cd));
            }
		}

		$this->render('create',array(
			'model'=>$model,
		));
	}

	public function actionUpdate($client_cd,$eff_dt)
	{
		$model = array();
		$modelClient = Client::model()->findByPk($client_cd);
		$oldPkId = array();
		$oldModel = Tinterestrate::model()->findAll(array('select'=>'client_cd,eff_dt,int_on_receivable,int_on_payable','condition'=>"client_cd = trim('$client_cd') AND approved_stat = 'A'",'order'=>'eff_dt DESC'));
		//NEW ROW

		$valid = false;
		$success = false;
		
		if(isset($_POST['Client']))
		{
			$modelClient->attributes = $_POST['Client'];
			
			if(!empty($modelClient->tax_on_interest))
				$modelClient->tax_on_interest = 'Y';
			else {
				$modelClient->tax_on_interest = 'N';
			}
			
			/*if($modelClient->validate())*/$valid = true; 
			
			//Manually assign user_id, upd_dt, upd_by, and ip_address because $modelClient->validate() confilcts with another menu
			$ip = Yii::app()->request->userHostAddress;
			if($ip=="::1")
				$ip = '127.0.0.1';
			
			$modelClient->ip_address = $ip;
			$modelClient->upd_dt  = Yii::app()->datetime->getDateTimeNow();
			$modelClient->upd_by  = Yii::app()->user->id;
			$modelClient->user_id =  Yii::app()->user->id;
			
			$rowCount = $_POST['rowCnt'];
			$x=0;
				
			//BEGIN: reassign oldPkId
			for($x=0;$x<$rowCount;$x++)
			{
				if(isset($_POST['old_pk_id'.($x+1)]))
				{
					$oldPkId[$x]=$_POST['old_pk_id'.($x+1)];
				}
				else
				{
					$oldPkId[$x]='';
				}
			}
			//END
			
			if($rowCount > 0)
			{
				for($x=0;$x<$rowCount;$x++)
				{
					$model[$x] = new Tinterestrate;
					$model[$x]->attributes=$_POST['Tinterestrate'][$x+1];
					$model[$x]->client_cd = $modelClient->client_cd;
					$valid = $model[$x]->validate() && $valid;
				}
			}

			//validasi primary key tiap baris tidak boleh ada yang sama 
			for($x=0;$valid && $x < $rowCount;$x++)
			{
				for($y = $x+1;$valid && $y < $rowCount;$y++)
				{
					if($model[$x]->eff_dt == $model[$y]->eff_dt)
					{
						$model[$x]->addError('eff_dt','Effective Date antar baris harus berbeda');
						$valid = false;
					}
				}
			}
			
			if($valid)
			{
				$menuName = 'INTEREST RATE ENTRY';
				$connection  = Yii::app()->db;
				$transaction = $connection->beginTransaction();
				
				if($modelClient->executeSpHeader(AConstant::INBOX_STAT_UPD,$menuName) > 0)$success = true;
				
				if($success &&  $modelClient->executeSpInterest(AConstant::INBOX_STAT_UPD,$client_cd,1) > 0)$success = true;
				else {
					$success = false;
				}
				
				for($x=0,$y=0; $success && $x<$rowCount;$x++)
				{
					if($oldPkId[$x])
					{
						//UPDATE
						
						//cari old attribute
						$old_eff_dt = $oldModel[$oldPkId[$x]-1]->eff_dt;
						if($old_eff_dt)$old_eff_dt = DateTime::createFromFormat('Y-m-d G:i:s',$old_eff_dt)->format('Y-m-d');
						$old_int_on_receivable = $oldModel[$oldPkId[$x]-1]->int_on_receivable;
						$old_int_on_payable = $oldModel[$oldPkId[$x]-1]->int_on_payable;
						
						//UPDATE jika ada yang diubah
						if($old_eff_dt != $model[$x]->eff_dt || $old_int_on_receivable != $model[$x]->int_on_receivable || $old_int_on_payable != $model[$x]->int_on_payable)
						{
							if($success && $model[$x]->executeSp(AConstant::INBOX_STAT_UPD,$modelClient->client_cd,$old_eff_dt,$modelClient->update_date,$modelClient->update_seq,$y+1) > 0)
							{
								$success = true;
								$y++;
							}
							else {
								$success = false;
							}	
						}
						unset($oldModel[$oldPkId[$x]-1]);
					}
					else {
						//INSERT
						if($success && $model[$x]->executeSp(AConstant::INBOX_STAT_INS,$modelClient->client_cd,$model[$x]->eff_dt,$modelClient->update_date,$modelClient->update_seq,$y+1) > 0)
						{
							$success = true;
							$y++;
						}
						else {
							$success = false;
						}
					}	
				}

				//CANCEL
				foreach($oldModel as $row)
				{
					if($row->eff_dt)$row->eff_dt = DateTime::createFromFormat('Y-m-d G:i:s',$row->eff_dt)->format('Y-m-d');
					if($success && $row->executeSp(AConstant::INBOX_STAT_CAN,$modelClient->client_cd,$row->eff_dt,$modelClient->update_date,$modelClient->update_seq,$y+1) > 0)
					{
						$success = true;
						$y++;
					}
					else {
						$success = false;
						break;
					}
				}	
				
				if($success)
				{
					$transaction->commit();
					Yii::app()->user->setFlash('success', 'Successfully update Interest Rate');
					$this->redirect(array('/finance/tinterestrate/index'));
				}
				else {
					$transaction->rollback();
				}	
			}
			
			foreach($model as $row)
			{
				if($row->eff_dt)$row->eff_dt = DateTime::createFromFormat('Y-m-d',$row->eff_dt)->format('d/m/Y');
			}	
		}
		else {
			$model=Tinterestrate::model()->findAll(array('select'=>'client_cd,eff_dt,int_on_receivable,int_on_payable','condition'=>"client_cd = trim('$client_cd') AND approved_stat = 'A'",'order'=>'eff_dt DESC'));
		
			foreach($model as $row)
			{
				$row->eff_dt = DateTime::createFromFormat('Y-m-d G:i:s',$row->eff_dt)->format('d/m/Y');
			}
		
			$rowCount = count($model);
			for($x=0;$x<$rowCount;$x++)
			{
				$oldPkId[$x]=$x+1;
				$model[$x]->scenario = 'update';
			}
		}

		$this->render('update',array(
			'model'=>$model,
			'modelClient'=>$modelClient,
			'oldModel'=>$oldModel,
			'oldPkId'=>$oldPkId,
		));
	}

	public function actionDelete($id)
	{
		if(Yii::app()->request->isPostRequest)
		{
			$this->loadModel($id)->delete();

			if(!isset($_GET['ajax']))
				$this->redirect(isset($_POST['returnUrl']) ? $_POST['returnUrl'] : array('view'));
		}
		else
			throw new CHttpException(400,'Invalid request. Please do not repeat this request again.');
	}

	public function actionIndex()
	{
		$model = new Vinterestrate('search');
		$model->unsetAttributes();
		
		if(isset($_GET['Vinterestrate']))
			$model->attributes=$_GET['Vinterestrate'];

		$this->render('index',array(
			'model'=>$model,
		));
	}

	public function loadModel($client_cd,$eff_dt)
	{
		$model=Tinterestrate::model()->findByPk(array('client_cd'=>$client_cd,'eff_dt'=>$eff_dt));
		if($model===null)
			throw new CHttpException(404,'The requested page does not exist.');
		return $model;
	}
}
