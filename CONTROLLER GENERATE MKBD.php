<?php

class GeneratemkbdreportController extends AAdminController
{
	
	public $layout='//layouts/admin_column3';
	public function actionIndex(){
		
		$notFound=0;	
		$urlvd51 ='';
		$urlvd52 ='';
		$urlvd53 ='';
		$urlvd54 ='';
		$urlvd55 ='';
		$urlvd56 ='';
		$urlvd57 ='';
		$urlvd58 ='';
		$urlvd59 ='';
		$urlvd510a ='';
		$urlvd510b ='';
		$urlvd510c ='';
		$urlvd510d ='';
		$urlvd510e ='';
		$urlvd510f ='';
		$urlvd510g ='';
		$urlvd510h ='';
		$urlvd510i ='';
		$label_header='';
		$urlprint='';
		$model = new Rptmkbdreport('Generate_MKBD_Report','LAP_MKBD_VD51','Report_VD51.rptdesign');
		
		$model->print_stat_a=0;
		//$model->type=0;
		$update_seq=Yii::app()->request->cookies['update_seq']?Yii::app()->request->cookies['update_seq']->value:NULL;
		$update_date=Yii::app()->request->cookies['update_date']?Yii::app()->request->cookies['update_date']->value:NULL;
		$mkbd_date=Yii::app()->request->cookies['mkbd_date']?Yii::app()->request->cookies['mkbd_date']->value:NULL;
		$date= Tmanyheader::model()->find("update_seq='$update_seq' and update_date = '$update_date' ");
		
		if($date){
			/*
			if($date->approved_status =='A'){
							$model->gen_dt = DateTime::createFromFormat('Y-m-d',$mkbd_date)->format('d/m/Y');
						}
						else{*/
			
				//$model->gen_dt = Date('d/m/Y');
				$model->gen_dt = DateTime::createFromFormat('Y-m-d',$mkbd_date)->format('d/m/Y');
	//	}
		}
		else{
				$model->gen_dt = Date('d/m/Y');
		}
		
		
		
		if(isset($_POST['scenario']))
	{
			
			$scenario = $_POST['scenario'];
			$model->attributes = $_POST['Rptmkbdreport'];
		if(DateTime::createFromFormat('d/m/Y',$model->gen_dt))$model->gen_dt=DateTime::createFromFormat('d/m/Y',$model->gen_dt)->format('Y-m-d');		
		if(DateTime::createFromFormat('d/m/Y',$model->price_dt))$model->price_dt=DateTime::createFromFormat('d/m/Y',$model->price_dt)->format('Y-m-d');
		if($scenario == 'generate')
		{ $model->scenario ='generate';			

	if($model->validate())
	{
			$menuName = 'MKBD REPORT';					
			$begin_dt = DateTime::createFromFormat('Y-m-d',$model->gen_dt)->format('Y-m-01');
			$cek = Tcloseprice::model()->find("stk_date='$model->gen_dt' and approved_stat='A'");
			
			$cek4 = Tcontracts::model()->find("contr_dt = to_date('$model->gen_dt','yyyy-mm-dd') and approved_stat='A' ");
			$cek5 = Tcontracts::model()->find("	contr_dt between to_date('$model->gen_dt','yyyy-mm-dd') -20 and to_date('$model->gen_dt','yyyy-mm-dd')		
														and contr_stat <> 'C'		
														and due_dt_for_amt <= to_date('$model->gen_dt','yyyy-mm-dd')		
														and nvl(sett_qty,0) < qty
														and approved_stat='A' ");
														
			$cek6 = Tbondtrx::model()->find("trx_date between  to_date('$model->gen_dt','yyyy-mm-dd') -20 and  to_date('$model->gen_dt','yyyy-mm-dd')			
														and approved_sts = 'A'			
														and value_dt <=  to_date('$model->gen_dt','yyyy-mm-dd')	
														and doc_num is not null		
														and nvl(settle_secu_flg,'N') = 'N'	");
			if($cek)
			{
				$msg1='';
				$msg2='';
				$msg3='';											
				if(!$cek4)
				{
					$msg1 = "Transaksi hari ini belum diproses <br />";
				}
				else if($cek5)
				{
					$msg2 = "Some BOND transaction have not settled yet <br />";
				}
			
				else if($cek6)
				{
					$msg3 = "Some BOND transaction have not settled yet <br />";
				}
				if($msg1 ||$msg2 ||$msg3)
				{
					Yii::app()->user->setFlash('info', $msg1. $msg2. $msg3);
				}
			}
		//-----------------------------------------------GENERATE-----------------------------------------------
		
		$ip = Yii::app()->request->userHostAddress;
			if($ip=="::1")
				$ip = '127.0.0.1';
		$model->ip_address =$ip;
		$success=false;
		$connection  = Yii::app()->dbrpt;
		$transaction = $connection->beginTransaction();
		/*
	if($model->vd51 || $model->vd52 || $model->vd53 ||$model->vd54 ||$model->vd55||$model->vd56 ||$model->vd57||$model->vd58 ||$model->vd59 ||
			$model->vd510a || $model->vd510b || $model->vd510c ||$model->vd510d ||$model->vd510e ||$model->vd510f ||$model->vd510g ||$model->vd510h ||$model->vd510i)
			{
			*/	
		$sql="SELECT * FROM (
		select TO_DATE(field_value,'YYYY/MM/DD HH24:MI:SS')MKBD_DATE from t_many_detail d, t_many_header h
		where d.update_date = h.update_date and d.update_seq=h.update_seq
		and h.menu_name='MKBD REPORT' AND FIELD_NAME='MKBD_DATE' AND H.APPROVED_STATUS='E')
		WHERE MKBD_DATE = '$model->gen_dt'";
		$cek=DAO::queryAllSql($sql);
		
		if($cek){
			$model->addError('gen_dt', "Masih ada yang belum di approve untuk tanggal $model->gen_dt ");
		}			
		else{
			
			
		if($model->executeSpHeader(AConstant::INBOX_STAT_INS, $menuName)>0)$success=TRUE;
		else{
			$success=FALSE;
		}
		if($success && $model->executeSpInbox(AConstant::INBOX_STAT_INS, 1)>0)$success=true;
		else{
			$success=false;
		}
		//------------EXECUTE SELECTED MKBD-----------------
	
		Yii::app()->request->cookies['mkbd_date'] = new CHttpCookie('mkbd_date', $model->gen_dt);
		Yii::app()->request->cookies['update_seq'] = new CHttpCookie('update_seq', $model->update_seq);
		Yii::app()->request->cookies['update_date'] = new CHttpCookie('update_date', $model->update_date);
		 
		//		if($model->vd510a){
					if($success && $model->executeRemoveMkbd('LAP_MKBD_VD510A')>0){
						 $success =true;
					 }
					else{
						 $success=false;
					}
						if($success && $model->executeVd('510A')>0)$success=TRUE;
						else{
							$success=false;
						}
		//		 }
		//		 if($model->vd510b){
					 if($success && $model->executeRemoveMkbd('LAP_MKBD_VD510B')>0){
						 $success =true;
					 }
					else{
						 $success=false;
					}
						if($success && $model->executeVd('510B')>0)$success=TRUE;
						else{
							$success=false;
						}
			//	 }
		//		 if($model->vd510c){
					 if($success && $model->executeRemoveMkbd('LAP_MKBD_VD510C')>0){
						 $success =true;
					 }
					else{
						 $success=false;
					}
						if($success && $model->executeVd('510C')>0)$success=TRUE;
						else{
							$success=false;
						}
	//			 }
		//		 if($model->vd510d){
					 if($success && $model->executeRemoveMkbd('LAP_MKBD_VD510D')>0){
						 $success =true;
					 }
					else{
						 $success=false;
					}
						if($success && $model->executeVd('510D')>0)$success=TRUE;
						else{
							$success=false;
						}
			//	 }
			//	 if($model->vd510e){
					 if($success && $model->executeRemoveMkbd('LAP_MKBD_VD510E')>0){
						 $success =true;
					 }
					else{
						 $success=false;
					}
						if($success && $model->executeVd('510E')>0)$success=TRUE;
						else{
							$success=false;
						}
		//		 }
		//		 if($model->vd510f){
					 if($success && $model->executeRemoveMkbd('LAP_MKBD_VD510F')>0){
						 $success =true;
					 }
					else{
						 $success=false;
					}
						if($success && $model->executeVd('510F')>0)$success=TRUE;
						else{
							$success=false;
						}
			//	 }
	//			 if($model->vd510g){
					 if($success && $model->executeRemoveMkbd('LAP_MKBD_VD510G')>0){
						 $success =true;
					 }
					else{
						 $success=false;
					}
						if($success && $model->executeVd('510G')>0)$success=TRUE;
						else{
							$success=false;
						}
		//		 }
		//		 if($model->vd510h){
					 if($success && $model->executeRemoveMkbd('LAP_MKBD_VD510H')>0){
						 $success =true;
					 }
					else{
						 $success=false;
					}
						if($success && $model->executeVd('510H')>0)$success=TRUE;
						else{
							$success=false;
						}
		//		 }
		//		 if($model->vd510i){
					 if($success && $model->executeRemoveMkbd('LAP_MKBD_VD510I')>0){
						 $success =true;
					 }
					else{
						 $success=false;
					}
						if($success && $model->executeVd('510I')>0)$success=TRUE;
						else{
							$success=false;
						}
				 
			//	 }
			//	if($model->vd54){
					if($success && $model->executeRemoveMkbd('LAP_MKBD_VD54')>0){
						 $success =true;
					 }
					else{
						 $success=false;
					}
						if($success && $model->executeVd('54')>0)$success=TRUE;
						else{
							$success=false;
						}
			//	 }
			//	if($model->vd55){
					if($success && $model->executeRemoveMkbd('LAP_MKBD_VD55')>0){
						 $success =true;
					 }
					else{
						 $success=false;
					}
						if($success && $model->executeVd('55')>0)$success=TRUE;
						else{
							$success=false;
						}
		//		 }
			//	if($model->vd56){
					if($success && $model->executeRemoveMkbd('LAP_MKBD_VD56')>0){
						 $success =true;
					 }
					else{
						 $success=false;
					}
						if($success && $model->executeVd('56')>0)$success=TRUE;
						else{
							$success=false;
						}
			//	 }
			//	if($model->vd57){
					if($success && $model->executeRemoveMkbd('LAP_MKBD_VD57')>0){
						 $success =true;
					 }
					else{
						 $success=false;
					}
						if($success && $model->executeVd('57')>0)$success=TRUE;
						else{
							$success=false;
						}
			//	 }
			//	if($model->vd51){
					 if($success && $model->executeRemoveMkbd('LAP_MKBD_VD51')>0){
						 $success =true;
					 }
					else{
						 $success=false;
					}
						if($success && $model->executeVd('51')>0)$success=TRUE;
						else{
							$success=false;
						}
			//	 }
			//	if($model->vd52){
					if($success && $model->executeRemoveMkbd('LAP_MKBD_VD52')>0){
						 $success =true;
					 }
					else{
						 $success=false;
					}
						if($success && $model->executeVd('52')>0)$success=TRUE;
						else{
							$success=false;
						}
			//	 }
			//	if($model->vd53){
					if($success && $model->executeRemoveMkbd('LAP_MKBD_VD53')>0){
						 $success =true;
					 }
					else{
						 $success=false;
					}
						if($success && $model->executeVd('53')>0)$success=TRUE;
						else{
							$success=false;
						}
			//	 }
			
		
			//	 if($model->vd58){
					 if($success && $model->executeRemoveMkbd('LAP_MKBD_VD58')>0){
						 $success =true;
					 }
					else{
						 $success=false;
					}
						if($success && $model->executeVd('58')>0)$success=TRUE;
						else{
							$success=false;
						}
		//		 }
		//		if($model->vd59){
					if($success && $model->executeRemoveMkbd('LAP_MKBD_VD59')>0){
						 $success =true;
					 }
					else{
						 $success=false;
					}
						if($success && $model->executeVd('59')>0)$success=TRUE;
						else{
							$success=false;
						}
		//		 }
		
		//CEK APAKAH SAMA TOTAL VD51 DAN VD52
		
		
		$vd51="SELECT C1 FROM INSISTPRO_RPT.LAP_MKBD_VD51 WHERE mkbd_cd =113 AND MKBD_DATE='$model->gen_dt' AND APPROVED_STAT='E' order by update_date desc";
		$vd51_c1 =DAO::queryRowSql($vd51);
		$vd52 = "SELECT C1 FROM INSISTPRO_RPT.LAP_MKBD_VD52 WHERE mkbd_cd =173 AND MKBD_DATE='$model->gen_dt' AND APPROVED_STAT='E' order by update_date desc";				 
		$vd52_c1=DAO::queryRowSql($vd52);
		$vd51c1 = round($vd51_c1['c1'],2);
		$vd52c1 = round($vd52_c1['c1'],2);
		
		$msg1='';
		$msg2='';
		if(($vd51c1 != $vd52c1) && ($vd51_c1 && $vd52_c1)){
			$msg1= 'Total MKBD VD51 tidak sama dengan MKBD VD52'."<br />";
		}
		$cek_mkbd_val = Tmanydetail::model()->find("update_seq = '$model->update_seq' and update_date = '$model->update_date' and table_name='LAP_MKBD_VD51' and field_name='NILAI_MKBD' ");
		//cek nilai MKBD
		if($model->vd59 && $cek_mkbd_val){
				$nilai = $cek_mkbd_val->field_value;
				if($nilai<=0)
				{
					$msg2 = 'Tidak memenuhi nilai minimum MKBD'."<br />";
				
					$log_mkbd = new Tmkbdlog;
					$log_mkbd->update_date = $model->update_date;
					$log_mkbd->update_seq = $model->update_seq;
					$log_mkbd->seqno = 1;
					$log_mkbd->cre_dt =date('Y-m-d H:i:s');
					$log_mkbd->user_id = Yii::app()->user->id;
					
				}
		}
		
		
		
		//CEK BARIS DAN KOLOM APAKAH ADA YANG NILAINYA  < 0
		$msgvd51 = '';
		$msgvd52 = '';
		$msgvd53 =  '';
		$msgvd54 =  '';
		$msgvd55 =  '';
		$msgvd56 =  '';
		$msgvd57 =  '';
		$msgvd58 =  '';
		$msgvd59 =  '';
		$msgvd510a =  '';
		$msgvd510b =  '';
		$msgvd510c =  '';
		$msgvd510d =  '';
		$msgvd510e =  '';
		$msgvd510f =  '';
		$msgvd510g =  '';
		$msgvd510h =  '';
		$msgvd510i =  '';
		//cek vd51
		$sql_vd51 = "select COUNT(1),MKBD_CD from INSISTPRO_RPT.LAP_MKBD_VD51 WHERE update_seq = '$model->update_seq' and update_date = '$model->update_date'
					 AND C1<0 GROUP BY MKBD_CD";
		$cek_vd51 = DAO::queryAllSql($sql_vd51);	
		
		if($cek_vd51)
		{	
			foreach($cek_vd51 as $row)
			{
				$msgvd51 =  $msgvd51.'VD 5-1 bernilai minus pada kolom B baris '.$row['mkbd_cd']."<br />";
			}
		}
		
		//cek vd52
		$sql_vd52 = "select COUNT(1),MKBD_CD from INSISTPRO_RPT.LAP_MKBD_VD52 WHERE update_seq = '$model->update_seq' and update_date = '$model->update_date' 
					 AND C1<0 GROUP BY MKBD_CD";
		$cek_vd52 = DAO::queryAllSql($sql_vd52);	
		
		if($cek_vd52)
		{	
			foreach($cek_vd52 as $row)
			{
				$msgvd52 = $msgvd52.'VD 5-2 bernilai minus pada kolom B baris '.$row['mkbd_cd']."<br />";	
			}
		}
		//cek vd53
		$sql_vd53 = "select COUNT(1),MKBD_CD from INSISTPRO_RPT.LAP_MKBD_VD53 WHERE update_seq = '$model->update_seq' and update_date = '$model->update_date' 
					 AND C1<0 GROUP BY MKBD_CD";
		$cek_vd53 = DAO::queryAllSql($sql_vd53);	
		if($cek_vd53)
		{	foreach($cek_vd53 as $row)
			{
				$msgvd53 = $msgvd53.'VD 5-3 bernilai minus pada kolom B baris '.$row['mkbd_cd']."<br />";	
			}
		}
		//cek vd54
		$sql_vd54 = "Select Count(1),Mkbd_Cd From INSISTPRO_RPT.LAP_MKBD_VD54 Where
				 	update_seq = '$model->update_seq' and update_date = '$model->update_date'
				 	And	(market_value<0 or nab<0 or risiko_persen<0 or batasan_mkbd<0 or risiko<0)
					 Group By Mkbd_Cd";
		$cek_vd54 = DAO::queryAllSql($sql_vd54);	
		if($cek_vd54)
		{	foreach($cek_vd54 as $row)
			{
				$msgvd54 = $msgvd54.'VD 5-4 bernilai minus pada baris '.$row['mkbd_cd']."<br />";		
			}
		}
		//cek vd55
		$sql_vd55 = "Select Count(1),Mkbd_Cd From INSISTPRO_RPT.LAP_MKBD_VD55 Where
				 	update_seq = '$model->update_seq' and update_date = '$model->update_date'
				 	And	(NILAI_EFEK<0 or NILAI_LINDUNG<0 or NILAI_TUTUP<0 or NILAI_HAIRCUT<0 or NILAI_HAIRCUT_LINDUNG<0 or PENGEMBALIAN<0)
					 Group By Mkbd_Cd";
		$cek_vd55 = DAO::queryAllSql($sql_vd55);	
		if($cek_vd55)
		{	foreach($cek_vd55 as $row)
			{
				$msgvd55 =$msgvd55.'VD 5-5 bernilai minus pada baris '.$row['mkbd_cd']."<br />";	
			}
		}

		//cek vd56
		$sql_vd56 = "Select Count(1),Mkbd_Cd From INSISTPRO_RPT.LAP_MKBD_VD56 Where
				 	update_seq = '$model->update_seq' and update_date = '$model->update_date'
				 	And	(c1<0 or c2<0 or c3<0 or c4<0)
					 Group By Mkbd_Cd";
		$cek_vd56 = DAO::queryAllSql($sql_vd56);	
		if($cek_vd56)
		{	foreach($cek_vd56 as $row)
			{
				$msgvd56 =$msgvd56. 'VD 5-6 bernilai minus pada baris '.$row['mkbd_cd']."<br />";	
			}
		}
		//cek vd57
		$sql_vd57 = "Select Count(1),Mkbd_Cd From INSISTPRO_RPT.LAP_MKBD_VD57 Where
				 	update_seq = '$model->update_seq' and update_date = '$model->update_date'
				 	And	(c1<0 or c2<0 or c3<0 or c4<0)
					 Group By Mkbd_Cd";
		$cek_vd57 = DAO::queryAllSql($sql_vd57);	
		if($cek_vd57)
		{	foreach($cek_vd57 as $row)
			{
				$msgvd57 =$msgvd57. 'VD 5-7 bernilai minus pada baris '.$row['mkbd_cd']."<br />";	
			}
		}
		//cek vd58
		$sql_vd58 = "Select Count(1),Mkbd_Cd From INSISTPRO_RPT.LAP_MKBD_VD58 Where
				 	update_seq = '$model->update_seq' and update_date = '$model->update_date'
				 	And	c1<0 
					 Group By Mkbd_Cd";
		$cek_vd58 = DAO::queryAllSql($sql_vd58);	
		if($cek_vd58)
		{	foreach($cek_vd58 as $row)
			{
				$msgvd58 = $msgvd58.'VD 5-8 bernilai minus pada baris '.$row['mkbd_cd']."<br />";	
			}
		}
		//cek vd59
		$sql_vd59 = "Select Count(1),Mkbd_Cd From INSISTPRO_RPT.LAP_MKBD_VD59 Where
				 	update_seq = '$model->update_seq' and update_date = '$model->update_date'
				 	And	(c1<0 or c2<0 )
					 Group By Mkbd_Cd";
		$cek_vd59 = DAO::queryAllSql($sql_vd59);	
		if($cek_vd59)
		{	foreach($cek_vd59 as $row)
			{
				$msgvd59 =$msgvd59.'VD 5-9 bernilai minus pada baris '.$row['mkbd_cd']."<br />";	
			}
		}
		//cek vd510A
		$sql_vd510a = "Select Count(1),Mkbd_Cd From INSISTPRO_RPT.LAP_MKBD_VD510a Where
				 	update_seq = '$model->update_seq' and update_date = '$model->update_date'
				 	And	(REPO_VAL<0 or RETURN_VAL<0 or SUM_QTY<0 or MARKET_VAL<0 or RANKING<0)
					 Group By Mkbd_Cd";
		$cek_vd510a = DAO::queryAllSql($sql_vd510a);	
		if($cek_vd510a)
		{	foreach($cek_vd510a as $row)
			{
				$msgvd510a = $msgvd510a. 'VD 5-10 A bernilai minus pada baris '.$row['mkbd_cd']."<br />";	
			}
		}
		//cek vd510B
		$sql_vd510b = "Select Count(1),Mkbd_Cd From INSISTPRO_RPT.LAP_MKBD_VD510b Where
				 	update_seq = '$model->update_seq' and update_date = '$model->update_date'
				 	And	(REPO_VAL<0 or RETURN_VAL<0 or SUM_QTY<0 or MARKET_VAL<0 or RANKING<0)
					 Group By Mkbd_Cd";
		$cek_vd510b = DAO::queryAllSql($sql_vd510b);	
		if($cek_vd510b)
		{	foreach($cek_vd510b as $row)
			{
				$msgvd510b = $msgvd510b.'VD 5-10 B bernilai minus pada baris '.$row['mkbd_cd']."<br />";	
			}
		}
		//cek vd510C
		$sql_vd510c = "Select Count(1),Mkbd_Cd From INSISTPRO_RPT.LAP_MKBD_VD510c Where
				 	update_seq = '$model->update_seq' and update_date = '$model->update_date'
				 	And	(BUY_PRICE<0 or PRICE<0 or MARKET_VAL<0 or PERSEN_MARKET<0 or RANKING<0)
					 Group By Mkbd_Cd";
		$cek_vd510c = DAO::queryAllSql($sql_vd510c);	
		if($cek_vd510c)
		{	foreach($cek_vd510b as $row)
			{
				$msgvd510c  =$msgvd510c.'VD 5-10 C bernilai minus pada baris '.$row['mkbd_cd']."<br />";	
			}
		}
		//cek vd510D
		$sql_vd510d = "Select Count(1),Mkbd_Cd From INSISTPRO_RPT.LAP_MKBD_VD510d Where
				 	update_seq = '$model->update_seq' and update_date = '$model->update_date'
				 	And	(end_bal<0 or stk_val<0 or ratio<0 or lebih_client<0 or lebih_porto<0)
					 Group By Mkbd_Cd";
		$cek_vd510d = DAO::queryAllSql($sql_vd510d);	
		if($cek_vd510d)
		{	foreach($cek_vd510d as $row)
			{
				$msgvd510d = $msgvd510d.'VD 5-10 D bernilai minus pada baris '.$row['mkbd_cd']."<br />";	
			}
		}
		//cek vd510E
		$sql_vd510e = "Select Count(1),Mkbd_Cd From INSISTPRO_RPT.LAP_MKBD_VD510e Where
				 	update_seq = '$model->update_seq' and update_date = '$model->update_date'
				 	And	(price<0 or market_val<0 )
					 Group By Mkbd_Cd";
		$cek_vd510e = DAO::queryAllSql($sql_vd510e);	
		if($cek_vd510e)
		{	foreach($cek_vd510e as $row)
			{
				$msgvd510e = $msgvd510e. 'VD 5-10 E bernilai minus pada baris '.$row['mkbd_cd']."<br />";	
			}
		}
		//cek vd510F
		$sql_vd510f = "Select Count(1),Mkbd_Cd From INSISTPRO_RPT.LAP_MKBD_VD510f Where
				 	update_seq = '$model->update_seq' and update_date = '$model->update_date'
				 	And	(nilai_komitment<0 or haircut<0 or unsubscribe_amt<0 or bank_garansi<0 or ranking<0)
					 Group By Mkbd_Cd";
		$cek_vd510f = DAO::queryAllSql($sql_vd510f);	
		if($cek_vd510f)
		{	foreach($cek_vd510f as $row)
			{
				$msgvd510f =$msgvd510f. 'VD 5-10 F bernilai minus pada baris '.$row['mkbd_cd']."<br />";	
			}
		}

		//cek vd510G
		$sql_vd510g = "Select Count(1),Mkbd_Cd From INSISTPRO_RPT.LAP_MKBD_VD510g Where
				 	update_seq = '$model->update_seq' and update_date = '$model->update_date'
				 	And	(NILAI<0 or RANKING<0 )
					 Group By Mkbd_Cd";
		$cek_vd510g = DAO::queryAllSql($sql_vd510g);	
		if($cek_vd510g)
		{	foreach($cek_vd510g as $row)
			{
				$msgvd51g =$msgvd51g.'VD 5-10 G bernilai minus pada baris '.$row['mkbd_cd']." <br />";	
			}
		}
		//cek vd510H
		$sql_vd510h = "Select Count(1),Mkbd_Cd From INSISTPRO_RPT.LAP_MKBD_VD510h Where
				 	update_seq = '$model->update_seq' and update_date = '$model->update_date'
				 	And	(SUDAH_REAL<0 or BELUM_REAL<0 and ranking<0 )
					 Group By Mkbd_Cd";
		$cek_vd510h = DAO::queryAllSql($sql_vd510h);	
		if($cek_vd510h)
		{	foreach($cek_vd510h as $row)
			{
				$msgvd510h = $msgvd510h.  'VD 5-10 H bernilai minus pada baris '.$row['mkbd_cd']."<br/>";	
			}
		}
		//cek vd510I
		$sql_vd510i = "Select Count(1),Mkbd_Cd From INSISTPRO_RPT.LAP_MKBD_VD510i Where
				 	update_seq = '$model->update_seq' and update_date = '$model->update_date'
				 	And	(NILAI_RPH<0 or UNTUNG_RUGI<0 and RANKING<0 )
					 Group By Mkbd_Cd";
		$cek_vd510i = DAO::queryAllSql($sql_vd510i);	
		if($cek_vd510i)
		{	foreach($cek_vd510i as $row)
			{
				$msgvd510i = $msgvd510i.'VD 5-10 I bernilai minus pada baris '.$row['mkbd_cd']."<br />";	
			}
		}
		
		
		//validasi untuk nilai total mkbd vd51 dan 52 serta total vd59
		/*
		if($msg1 !='' && $msg2 !=''){
			Yii::app()->user->setFlash('danger', $msg1."<br/>".$msg2);
		}		 
		else if($msg1 !=''){
					Yii::app()->user->setFlash('danger', $msg1);
		}
		else if($msg2){
					Yii::app()->user->setFlash('danger', $msg1);
		}
		*/
		
		if($msg1|| $msg2 || $msgvd51 ||$msgvd52 ||$msgvd53 ||$msgvd54 ||$msgvd55 ||$msgvd56 ||$msgvd57 ||$msgvd58 || $msgvd59||
			$msgvd510a ||$msgvd510b ||$msgvd510c ||$msgvd510d ||$msgvd510e ||$msgvd510f ||$msgvd510g ||$msgvd510h ||$msgvd510i)
		{
		Yii::app()->user->setFlash('danger', $msg1.$msg2
									.$msgvd51
									.$msgvd52
									.$msgvd53
									.$msgvd54
									.$msgvd55
									.$msgvd56
									.$msgvd57
									.$msgvd58
									.$msgvd58
									.$msgvd510a
									.$msgvd510b
									.$msgvd510c
									.$msgvd510d
									.$msgvd510e
									.$msgvd510f
									.$msgvd510g
									.$msgvd510h
									.$msgvd510i
									);
		}
		
				 
		 }//END CEK MASIH ADA BELUM APPROVE	
	//}
		
		//------------END EXECUTE SELECTED MKBD-----------------
		
		//-----------------------------------------------END GENERATE-----------------------------------------------
		
		if($success)
		{
			$date=$model->gen_dt;
			if(DateTime::createFromFormat('Y-m-d',$date))$date=DateTime::createFromFormat('Y-m-d',$date)->format('d M Y');
			$transaction->commit();
			Yii::app()->user->setFlash('success', 'Successfully Generate MKBD report at '.$date);
			$this->redirect(array('index'));
		}
		else 
		{
			$transaction->rollback();
		}
		
		
		
		
					
		
	}//end VALIDATE
	}//end scenario generate
	
	else if($scenario=='printreport' && $model->validate())
	{
		//cek apakah sudah pernah digenerate
		$sql="select * from (
				select to_date(field_value,'yyyy/mm/dd hh24:mi:ss') gen_date
				from t_many_detail d, t_many_header h
				where d.update_date= h.update_date
				and d.update_seq = h.update_seq
				and h.menu_name = 'MKBD REPORT'
				 and d.field_name='MKBD_DATE'
				and h.approved_status='A') where gen_date = to_date('$model->gen_dt','yyyy-mm-dd') ";
		$cek = DAO::queryRowSql($sql);
		
		if(!$cek){
			
			$date = DateTime::createFromFormat('Y-m-d',$model->gen_dt)->format('d M Y');
			$model->addError('gen_dt', "Report MKBD tanggal $date belum digenerate");
		}				
		else
		{
			
			
		
			$label_header = 'Report MKBD Approved';
			$model->print_stat_a =0;
		
			if($model->vd51){
			$modelvd51 = new Rptmkbdreport('Generate_MKBD_Report','LAP_MKBD_VD51','Report_VD51.rptdesign');
			
			$modelvd51->trx_date = $model->gen_dt;
			$modelvd51->vp_userid = $model->vp_userid;
			$modelvd51->approved_stat ='A';
			$urlvd51 = $modelvd51->showReport2();
			}
			if($model->vd52){
			$modelvd52 = new Rptmkbdreport('Generate_MKBD_Report','LAP_MKBD_VD52','Report_VD52.rptdesign');
			
			$modelvd52->trx_date = $model->gen_dt;
			$modelvd52->vp_userid = $model->vp_userid;
			$modelvd52->approved_stat ='A';
			$urlvd52 = $modelvd52->showReport2();
			}
			if($model->vd53){
			$modelvd53 = new Rptmkbdreport('Generate_MKBD_Report','LAP_MKBD_VD53','Report_VD53.rptdesign');
			$modelvd53->trx_date = $model->gen_dt;
			$modelvd53->vp_userid = $model->vp_userid;
			$modelvd53->approved_stat ='A';
			$urlvd53 = $modelvd53->showReport2();
			}
			if($model->vd54){
			$modelvd54 = new Rptmkbdreport('Generate_MKBD_Report','LAP_MKBD_VD54','Report_VD54.rptdesign');
			$modelvd54->trx_date = $model->gen_dt;
			$modelvd54->vp_userid = $model->vp_userid;
			$modelvd54->approved_stat ='A';
			$urlvd54 = $modelvd54->showReport2();
			}
			if($model->vd55){
			$modelvd55 = new Rptmkbdreport('Generate_MKBD_Report','LAP_MKBD_VD55','Report_VD55.rptdesign');
			$modelvd55->trx_date = $model->gen_dt;
			$modelvd55->vp_userid = $model->vp_userid;
			$modelvd55->approved_stat ='A';
			$urlvd55 = $modelvd55->showReport2();
			}
			if($model->vd56){
			$modelvd56 = new Rptmkbdreport('Generate_MKBD_Report','LAP_MKBD_VD56','Report_VD56.rptdesign');
			$modelvd56->trx_date = $model->gen_dt;
			$modelvd56->vp_userid = $model->vp_userid;
			$modelvd56->approved_stat ='A';
			$urlvd56 = $modelvd56->showReport2();
			}
			if($model->vd57){
			$modelvd57 = new Rptmkbdreport('Generate_MKBD_Report','LAP_MKBD_VD57','Report_VD57.rptdesign');
			$modelvd57->trx_date = $model->gen_dt;
			$modelvd57->vp_userid = $model->vp_userid;
			$modelvd57->approved_stat ='A';
			$urlvd57 = $modelvd57->showReport2();
			}
			if($model->vd58){
			$modelvd58 = new Rptmkbdreport('Generate_MKBD_Report','LAP_MKBD_VD58','Report_VD58.rptdesign');
			$modelvd58->trx_date = $model->gen_dt;
			$modelvd58->vp_userid = $model->vp_userid;
			$modelvd58->approved_stat ='A';
			$urlvd58 = $modelvd58->showReport2();
			}
			if($model->vd59){
			$modelvd59 = new Rptmkbdreport('Generate_MKBD_Report','LAP_MKBD_VD59','Report_VD59.rptdesign');
			$modelvd59->trx_date = $model->gen_dt;
			$modelvd59->vp_userid = $model->vp_userid;
			$modelvd59->approved_stat ='A';
			$urlvd59 = $modelvd59->showReport2();
			}
			if($model->vd510a){
			$modelvd510a = new Rptmkbdreport('Generate_MKBD_Report','LAP_MKBD_VD510A','Report_VD510A.rptdesign');
			$modelvd510a->trx_date = $model->gen_dt;
			$modelvd510a->vp_userid = $model->vp_userid;
			$modelvd510a->approved_stat ='A';
			$urlvd510a = $modelvd510a->showReport2();
			}
			if($model->vd510b){
			$modelvd510b = new Rptmkbdreport('Generate_MKBD_Report','LAP_MKBD_VD510B','Report_VD510B.rptdesign');
			$modelvd510b->trx_date = $model->gen_dt;
			$modelvd510b->vp_userid = $model->vp_userid;
			$modelvd510b->approved_stat ='A';
			$urlvd510b = $modelvd510b->showReport2();
			}
			if($model->vd510c){
			$modelvd510c = new Rptmkbdreport('Generate_MKBD_Report','LAP_MKBD_VD510C','Report_VD510C.rptdesign');
			$modelvd510c->trx_date = $model->gen_dt;
			$modelvd510c->vp_userid = $model->vp_userid;
			$modelvd510c->approved_stat ='A';
			$urlvd510c = $modelvd510c->showReport2();
			}
			if($model->vd510d){
			$modelvd510d = new Rptmkbdreport('Generate_MKBD_Report','LAP_MKBD_VD510D','Report_VD510D.rptdesign');
			$modelvd510d->trx_date = $model->gen_dt;
			$modelvd510d->vp_userid = $model->vp_userid;
			$modelvd510d->approved_stat ='A';
			$urlvd510d = $modelvd510d->showReport2();
			}
			if($model->vd510e){
			$modelvd510e = new Rptmkbdreport('Generate_MKBD_Report','LAP_MKBD_VD510E','Report_VD510E.rptdesign');
			$modelvd510e->trx_date = $model->gen_dt;
			$modelvd510e->vp_userid = $model->vp_userid;
			$modelvd510e->approved_stat ='A';
			$urlvd510e = $modelvd510e->showReport2();
			}
			if($model->vd510f){
			$modelvd510f = new Rptmkbdreport('Generate_MKBD_Report','LAP_MKBD_VD510F','Report_VD510F.rptdesign');
			$modelvd510f->trx_date = $model->gen_dt;
			$modelvd510f->vp_userid = $model->vp_userid;
			$modelvd510f->approved_stat ='A';
			$urlvd510f = $modelvd510f->showReport2();
			}
			if($model->vd510g){
			$modelvd510g = new Rptmkbdreport('Generate_MKBD_Report','LAP_MKBD_VD510G','Report_VD510G.rptdesign');
			$modelvd510g->trx_date = $model->gen_dt;
			$modelvd510g->vp_userid = $model->vp_userid;
			$modelvd510g->approved_stat ='A';
			$urlvd510g = $modelvd510g->showReport2();
			}
			if($model->vd510h){
			$modelvd510h = new Rptmkbdreport('Generate_MKBD_Report','LAP_MKBD_VD510H','Report_VD510H.rptdesign');
			$modelvd510h->trx_date = $model->gen_dt;
			$modelvd510h->vp_userid = $model->vp_userid;
			$modelvd510h->approved_stat ='A';
			$urlvd510h = $modelvd510h->showReport2();
			}
			if($model->vd510i){
			$modelvd510i = new Rptmkbdreport('Generate_MKBD_Report','LAP_MKBD_VD510I','Report_VD510I.rptdesign');
			$modelvd510i->trx_date = $model->gen_dt;
			$modelvd510i->vp_userid = $model->vp_userid;
			$modelvd510i->approved_stat ='A';
			$urlvd510i = $modelvd510i->showReport2();
			}
			}//end validasi sudah pernah generate apa belum
}
	
		else if($scenario =='save')//save to text file
		{
			$model->scenario = 'save';
			if($model->validate())
			{
					$user_id =  Yii::app()->user->id;
			/*
					//CEK APAKAH SAMA TOTAL VD51 DAN VD52
				$vd51="SELECT C1 FROM INSISTPRO_RPT.LAP_MKBD_VD51 WHERE  mkbd_cd =113 AND MKBD_DATE='$model->gen_dt' AND APPROVED_STAT='A' order by update_date desc";
				$vd51_c1 =DAO::queryRowSql($vd51);
				$vd52 = "SELECT C1 FROM INSISTPRO_RPT.LAP_MKBD_VD52 WHERE  mkbd_cd =173 AND MKBD_DATE='$model->gen_dt' AND APPROVED_STAT='A' order by update_date desc";				 
				$vd52_c1=DAO::queryRowSql($vd52);
				
				$vd59 = "SELECT C2 FROM INSISTPRO_RPT.LAP_MKBD_VD59 WHERE  mkbd_cd =104 AND MKBD_DATE='$model->gen_dt' AND APPROVED_STAT='A'";				 
				$vd59_c2=DAO::queryRowSql($vd59);
				
				$vd51c1 = round($vd51_c1['c1'],2);
				$vd52c1 = round($vd52_c1['c1'],2);
				
				if(($vd51c1 != $vd52c1) && ($vd51_c1 && $vd52_c1)){
					Yii::app()->user->setFlash('danger', 'Total MKBD VD51 tidak sama dengan MKBD VD52');
				}
				else if($vd59_c2['c2']<=0){
					
					Yii::app()->user->setFlash('danger', 'Tidak memenuhi nilai minimum MKBD');
				}
				else{
			 * 
			 */
			 	$sql = "SELECT c2 FROM INSISTPRO_RPT.LAP_MKBD_VD59 WHERE MKBD_CD='102' AND mkbd_date='$model->gen_dt' and approved_stat='A'";
			 	$c2 = DAO::queryRowSql($sql);
			 	$amount = $c2['c2'];
			 	if($model->executeSaveMKbd($model->gen_dt, $amount, $user_id)>0){
			 		
			 	}
			 
						$direktur = Company::model()->find()->contact_pers;
						$kode_AB =  Parameter::model()->find(" prm_cd_1 = 'AB' and prm_cd_2 ='000' ")->prm_desc;
						$kode_AB = substr($kode_AB, 0,2);
						
						
						$date =  DateTime::createFromFormat('Y-m-d',$model->gen_dt)->format('ymd');
						$date_AB =  DateTime::createFromFormat('Y-m-d',$model->gen_dt)->format('Ymd');
						
						$sql = "SELECT VD||'.'||TRIM(A.MKBD_CD)||'|'||DECODE(B.VIS1,1,TRIM(TO_CHAR(A.C1,'9999999999999999990.99')),'')||'|||||||||' AS text_vd51 
								FROM INSISTPRO_RPT.LAP_MKBD_VD51 a,IPNEXTG.form_mkbd B WHERE A.MKBD_CD =B.MKBD_CD  and b.source='VD51'  
								and A.MKBD_DATE = '$model->gen_dt' and A.APPROVED_STAT ='A'  order by a.mkbd_cd";
						$datavd51 = Lapmkbdvd51::model()->findAllBySql($sql);
						
						$sql2 = "SELECT VD||'.'||TRIM(A.MKBD_CD)||'|'||DECODE(B.VIS1,1,TRIM(TO_CHAR(A.C1,'9999999999999999990.99')),'')||'|||||||||' AS text_vd52 
								 FROM INSISTPRO_RPT.LAP_MKBD_VD52 a,IPNEXTG.form_mkbd B WHERE A.MKBD_CD =B.MKBD_CD  and b.source='VD52' 
								 and A.MKBD_DATE = '$model->gen_dt' and A.APPROVED_STAT ='A'  order by a.mkbd_cd";
						$datavd52 = Lapmkbdvd51::model()->findAllBySql($sql2);
						
						$sql3 ="SELECT VD||'.'||TRIM(A.MKBD_CD)||'|'||DECODE(B.VIS1,1,TRIM(TO_CHAR(A.C1,'9999999999999999990.99')),'')||'|||||||||' AS text_vd53 
								FROM insistpro_rpt.LAP_MKBD_VD53 a,IPNEXTG.form_mkbd B WHERE A.MKBD_CD =B.MKBD_CD  and b.source='VD53' 
							 and A.MKBD_DATE = '$model->gen_dt' and A.APPROVED_STAT ='A' order by a.mkbd_cd";
						$datavd53 = Lapmkbdvd51::model()->findAllBySql($sql3);
						
						$sql4 = "select VD||'.'||TRIM(MKBD_CD)||'|'||TRIM(REKS_TYPE)||'|'||TRIM(REKS_CD)||'|'||TRIM(AFILIASI)||'|'||
							    TRIM(TO_CHAR(MARKET_VALUE,'99999999999999999999999999990.99'))||'|' ||
							    TRIM(TO_CHAR(NAB,'99999999999999999999999999990.99'))||'||'||
							    TRIM(TO_CHAR(BATASAN_MKBD,'99999999999999999999999999990.99'))||'|'||
							    TRIM(TO_CHAR(RISIKO,'99999999999999999999999999990.99'))||'||'
							    AS text_vd54  from insistpro_rpt.lap_mkbd_vd54 where approved_stat='A' 
							    and mkbd_date ='$model->gen_dt' order by mkbd_cd";
						$datavd54 =Lapmkbdvd51::model()->findAllBySql($sql4);			
						
						
						$sqlvd55="select TRIM(VD)||'.'||TRIM(MKBD_CD)||'|'||
							      TRIM(NAMA_EFEK)||'|'||TRIM(TO_CHAR(NILAI_EFEK,'9999999999999999990.99'))||'|'||
							      TRIM(NAMA_LINDUNG)||'|'||TRIM(TO_CHAR(NILAI_LINDUNG,'9999999999999999990.99'))||'|'||
							      TRIM(TO_CHAR(NILAI_TUTUP,'9999999999999999990.99'))||'|'||TRIM(TO_CHAR(NILAI_HAIRCUT,'9999999999999999990.99'))||'|'||
							      TRIM(TO_CHAR(NILAI_HAIRCUT_LINDUNG,'9999999999999999990.99'))||'|'||TRIM(TO_CHAR(PENGEMBALIAN,'9999999999999999990.99'))||'||'
								   AS text_vd55
								   FROM insistpro_rpt.LAP_MKBD_VD55 where approved_stat='A' 
							  	   and mkbd_date ='$model->gen_dt' ";	
						$datavd55 =Lapmkbdvd51::model()->findAllBySql($sqlvd55);
						
						$sql5="SELECT VD||'.'||TRIM(A.MKBD_CD)||'|'||
								DECODE(B.VIS1,1,TRIM(TO_CHAR(A.C1,'9999999999999999990.99')),'')||'|' ||
								DECODE(B.VIS2,1,TRIM(TO_CHAR(A.C2,'9999999999999999990.99')),'')||'|'|| 
								DECODE(B.VIS3,1,TRIM(TO_CHAR(A.C3,'9999999999999999990.99')),'')||'|'|| 
								DECODE(B.VIS4,1,TRIM(TO_CHAR(A.C4,'9999999999999999990.99')),'')||'||||||'
								AS text_vd56a 
								FROM insistpro_rpt.LAP_MKBD_VD56 a,IPNEXTG.form_mkbd B WHERE A.MKBD_CD =B.MKBD_CD  
								and b.source='VD56' AND A.MKBD_CD between 8 and 23
								and A.mkbd_date ='$model->gen_dt' 
								and A.MKBD_CD <> 16 AND A.APPROVED_STAT ='A' order by a.mkbd_cd";
						$datavd56a = Lapmkbdvd51::model()->findAllBySql($sql5);			
						
						$sql6 ="SELECT VD||'.'||TRIM(A.MKBD_CD)||'.'||TRIM(A.NORUT)||'|'||TRIM(SUBSTR(A.DESCRIPTION,1,3))||'|'||
								TRIM(SUBSTR(A.MILIK,1,1))||'|'||TRIM(A.BANK_ACCT_CD)||'|'||TRIM(A.CURRENCY)||'|'||
								TRIM(TO_CHAR(A.C3,'9999999999999999990.99'))||'|' ||
								TRIM(TO_CHAR(A.C4,'9999999999999999990.99'))||'||||' 
								AS text_vd56b 
								FROM insistpro_rpt.LAP_MKBD_VD56 a,IPNEXTG.form_mkbd B WHERE A.MKBD_CD =B.MKBD_CD 
								 and b.source='VD56' AND A.MKBD_CD ='24' AND A.NORUT > 0
								AND A.APPROVED_STAT ='A'  and mkbd_date ='$model->gen_dt' order by  A.NORUT";
						$datavd56b = Lapmkbdvd51::model()->findAllBySql($sql6);	
						
						$sql7 ="SELECT VD||'.'||TRIM(A.MKBD_CD)||'|'||
								DECODE(B.VIS1,1,TRIM(TO_CHAR(A.C1,'9999999999999999990.99')),'')||'|'||
								DECODE(B.VIS2,1,TRIM(TO_CHAR(A.C2,'9999999999999999990.99')),'')||'|'||
								DECODE(B.VIS3,1,TRIM(TO_CHAR(A.C3,'9999999999999999990.99')),'')||'|'||
								DECODE(B.VIS4,1,TRIM(TO_CHAR(A.C4,'9999999999999999990.99')),'')||'||||||'
								AS text_vd57
								FROM insistpro_rpt.LAP_MKBD_VD57 a,IPNEXTG.form_mkbd B WHERE A.MKBD_CD =B.MKBD_CD  and b.source='VD57' 
								AND A.APPROVED_STAT ='A' AND A.MKBD_CD NOT IN (7,27,37,38)  
								and A.mkbd_date='$model->gen_dt' order by  A.MKBD_CD";
						$datavd57 = Lapmkbdvd51::model()->findAllBySql($sql7);	
						
						$sql8="SELECT VD||'.'||TRIM(A.MKBD_CD)||'||||'||
								DECODE(B.VIS1,1,TRIM(TO_CHAR(A.C1,'9999999999999999990.99')),'')||'||||||'
								AS text_vd58 
								FROM insistpro_rpt.LAP_MKBD_VD58 a,IPNEXTG.form_mkbd B WHERE A.MKBD_CD =B.MKBD_CD  and b.source='VD58' 
								AND A.APPROVED_STAT ='A' and A.mkbd_date='$model->gen_dt' order by  A.MKBD_CD";
						$datavd58 = Lapmkbdvd51::model()->findAllBySql($sql8);
						
						$sql9 = "SELECT VD||'.'||TRIM(A.MKBD_CD)||'||||'||
								 DECODE(B.VIS1,1,TRIM(TO_CHAR(A.C1,'9999999999999999990.99')),'')||'||' ||
								 DECODE(B.VIS2,1,TRIM(TO_CHAR(A.C2,'9999999999999999990.99')),'')||'||||' 
								 AS text_vd59
							     FROM insistpro_rpt.LAP_MKBD_VD59 a,IPNEXTG.form_mkbd B WHERE A.MKBD_CD =B.MKBD_CD 
								 and b.source='VD59' AND A.APPROVED_STAT ='A'
								 and A.mkbd_date='$model->gen_dt' order by  A.mkbd_cd";
						$datavd59 = Lapmkbdvd51::model()->findAllBySql($sql9);		 
								 
						$sql10a="select 'VD510.A.'||TRIM(MKBD_CD)||'|'||TRIM(JENIS_CD)||'|'||TRIM(JENIS)||'|'||
								   TRIM(LAWAN)||'|'||TRIM(TO_CHAR(EXTENT_DT,'DD/MM/YYYY'))||'|'||
								    TRIM(TO_CHAR(DUE_DATE,'DD/MM/YYYY'))||'|'||
								    TRIM(TO_CHAR(REPO_VAL,'9999999999999999990.99'))||'|'||
								   TRIM(TO_CHAR(RETURN_VAL,'9999999999999999990.99'))||'|'||
								    TRIM(STK_CD)||'|'||
								    TRIM(TO_CHAR(SUM_QTY,'99999999999999999999999999990.99'))||'|'||
								  TRIM(TO_CHAR(RANKING,'99999999999999999999999999990.99'))
								AS text_vd510a
								FROM insistpro_rpt.LAP_MKBD_VD510A where approved_stat='A' and rownum>4
								and mkbd_date='$model->gen_dt' ";		 
						$datavd10a = Lapmkbdvd51::model()->findAllBySql($sql10a);				 
								 
						$sql10b = "SELECT 'VD510.B.'||TRIM(MKBD_CD)||'|'||DECODE(MKBD_CD,'A','','B','','C','','T','',TRIM(JENIS_CD))||'|'||
							    TRIM(LAWAN)||'|'||TRIM(TO_CHAR(EXTENT_DT,'DD/MM/YYYY'))||'|'||
							    TRIM(TO_CHAR(DUE_DATE,'DD/MM/YYYY'))||'|'||
							    TRIM(TO_CHAR(REPO_VAL,'9999999999999999990.99'))||'|'||
							    TRIM(TO_CHAR(RETURN_VAL,'9999999999999999990.99'))||'|'||
							    TRIM(STK_CD)||'|'||
							    TRIM(TO_CHAR(SUM_QTY,'9999999999999999999999999990.99'))||'|'||
							    TRIM(TO_CHAR(MARKET_VAL,'9999999999999999999999999990.99'))||'|'||
							    TRIM(TO_CHAR(RANKING,'9999999999999999999999999990.99'))
							    AS text_vd510b
							    FROM insistpro_rpt.LAP_MKBD_VD510B where APPROVED_STAT ='A'
							     and mkbd_date='$model->gen_dt'";
						$datavd510b = Lapmkbdvd51::model()->findAllBySql($sql10b);
						
						$sql10c="select 'VD510.C.'||TRIM(MKBD_CD)||'||'||DECODE(MKBD_CD,'A','','B','','C','','D','','E','','T','',TRIM(STK_CD))||'|'||
								   DECODE(MKBD_CD,'A','','B','','C','','D','','E','','T','', TRIM(AFILIASI))||'|'||
								   DECODE(MKBD_CD,'A','','B','','C','','D','','E','','T','', TRIM(TO_CHAR(QTY,'99999999999999999999999999990.99')))||'|'||
								   DECODE(MKBD_CD,'A','','B','','C','','D','','E','','T','', TRIM(TO_CHAR(BUY_PRICE,'99999999999999999999999999990.99')))||'|'||
								   DECODE(MKBD_CD,'A','','B','','C','','D','','E','','T','',  TRIM(TO_CHAR(PRICE,'99999999999999999999999999990.99')))||'|'||
								   TRIM(TO_CHAR(MARKET_VAL,'99999999999999999999999999990.99'))||'|'||
								   DECODE(MKBD_CD,'A','','B','','C','','D','','E','','T','',TRIM(GRP_EMITENT))||'|'||
								   DECODE(MKBD_CD,'A','','B','','C','','D','','E','','T','', TRIM(TO_CHAR(PERSEN_MARKET,'99999999999999999999999999990.99')))||'|'||
								   TRIM(TO_CHAR(RANKING,'99999999999999999999999999990.99'))
								   as text_vd510c
								   from  insistpro_rpt.LAP_MKBD_VD510C where
								    approved_stat='A' and mkbd_date='$model->gen_dt'";
						$datavd510c = Lapmkbdvd51::model()->findAllBySql($sql10c);
						
						
						
						
						$sql10d =" select 'VD510.D.'||TRIM(MKBD_CD)||'|'||DECODE(MKBD_CD,'A','','B','','T','',TRIM(SID))||'|'||
									DECODE(MKBD_CD,'A','','B','','T','',TRIM(TRX_TYPE))||'|'||
								   TRIM(TO_CHAR(END_BAL,'99999999999999999999999999990.99'))||'|'||
								   TRIM(TO_CHAR(STK_VAL,'99999999999999999999999999990.99'))||'|'||
								   DECODE(MKBD_CD,'A','','B','','T','',TRIM(TO_CHAR(RATIO,'99999999999999999999999999990.99')))||'|'||
								   TRIM(TO_CHAR(LEBIH_CLIENT,'99999999999999999999999999990.99'))||'|'||
								   TRIM(TO_CHAR(LEBIH_PORTO,'99999999999999999999999999990.99'))||'|||'
								   AS text_vd510d
								from insistpro_rpt.LAP_MKBD_VD510D
								Where approved_stat='A' and mkbd_date='$model->gen_dt'
								Order By substr(mkbd_cd,1,1), 
								to_number(nvl(substr(mkbd_cd,3),999))";	
						$datavd510d = Lapmkbdvd51::model()->findAllBySql($sql10d);
						
						$sql10e ="select 'VD510.E.'||TRIM(MKBD_CD)||'||'||DECODE(MKBD_CD,'T','',TRIM(STK_CD))||'|'||
							      TRIM(TO_CHAR(QTY,'9999999999999999990.99'))||'|'||
							      TRIM(TO_CHAR(PRICE,'9999999999999999990.99'))||'|'||
							      TRIM(TO_CHAR(MARKET_VAL,'9999999999999999990.99'))||'|||||'
								  AS text_vd510e
								  from insistpro_rpt.LAP_MKBD_VD510E
								  Where approved_stat='A' and mkbd_date='$model->gen_dt'";
						$datavd510e = Lapmkbdvd51::model()->findAllBySql($sql10e);
						
						
						/*$sql10f = "select 'VD510.F.'||TRIM(MKBD_CD)||'||||||||||'
									AS text_vd510f
									from insistpro_rpt.LAP_MKBD_VD510F
									Where approved_stat='A' AND MKBD_CD IN('A','B','C','D','T')
									and mkbd_date='$model->gen_dt'";*/
						
						$sql10f = "select 'VD510.F.' || TRIM(MKBD_CD) || '|' ||
									DECODE(GRP,'D',TRIM(TO_CHAR(TGL_KONTRAK,'DD/MM/YYYY')),'') || '|' ||
									DECODE(GRP,'D',TRIM(JENIS_PENJAMINAN),'') || '|' ||
									DECODE(GRP,'D',TRIM(STK_NAME),'') || '|' ||
									DECODE(GRP,'D',TRIM(STATUS_PENJAMINAN),'') || '|' ||
									TRIM(TO_CHAR(NILAI_KOMITMENT,'999999999999999990.99')) || '|' ||
									CASE 
										WHEN GRP = 'D' OR HAIRCUT <> 0 THEN
											TRIM(TO_CHAR(HAIRCUT,'999999999999999990.99')) || '|'
										ELSE
											'|' 
									END ||
									CASE 
										WHEN GRP = 'D' OR UNSUBSCRIBE_AMT <> 0 THEN
											TRIM(TO_CHAR(UNSUBSCRIBE_AMT,'999999999999999990.99')) || '|'
										ELSE
											'|' 
									END ||
									CASE 
										WHEN GRP = 'D' OR BANK_GARANSI <> 0 THEN
											TRIM(TO_CHAR(BANK_GARANSI,'999999999999999990.99')) || '|'
										ELSE
											'|' 
									END ||
							    	TRIM(TO_CHAR(RANKING,'999999999999999990.99')) || '|' 
									AS text_vd510f
									from insistpro_rpt.LAP_MKBD_VD510F
									Where approved_stat='A' 
									and mkbd_date='$model->gen_dt'";			
									
						$datavd510f = Lapmkbdvd51::model()->findAllBySql($sql10f);
						
						
						$sql10g="select 'VD510.G.'||TRIM(MKBD_CD)||'|'||
							    TRIM(TO_CHAR(CONTRACT_DT,'DD/MM/YYY'))||'|'||
							    TRIM(GUARANTEED)||'|'||
							    TRIM(AFILIASI)||'|'||
							    TRIM(RINCIAN)||'|'||
							    TRIM(JANGKA)||'|'||
							    TRIM(TO_CHAR(END_CONTRACT_DT,'DD/MM/YYYY'))||'|'||
							    TRIM(TO_CHAR(NILAI,'999999999999999990.99'))||'|'||
							    TRIM(TO_CHAR(RANKING,'999999999999999990.99'))||'||'
							    as text_vd510g
							    FROM insistpro_rpt.LAP_MKBD_VD510G Where approved_stat='A' 
							   and mkbd_date='$model->gen_dt'";
						$datavd510g = Lapmkbdvd51::model()->findAllBySql($sql10g);	
						
						$sql10h="select 'VD510.H.'||TRIM(MKBD_CD)||'|'||
								   TRIM(TO_CHAR(TGL_KOMITMEN,'DD/MM/YYYY'))||'|'||
								  TRIM(RINCIAN)||'|'||
								  TRIM(TO_CHAR(TGL_REALISASI,'DD/MM/YYYY'))||'|'||
								  TRIM(TO_CHAR(SUDAH_REAL,'9999999999999999990.99'))||'|'||
								  TRIM(TO_CHAR(BELUM_REAL,'9999999999999999990.99'))||'|'||
								  TRIM(TO_CHAR(RANKING,'9999999999999999990.99'))||'||||'
								  as text_vd510h
								  FROM insistpro_rpt.LAP_MKBD_VD510H Where approved_stat='A' 
							    and mkbd_date='$model->gen_dt'";
		    			$datavd510h = Lapmkbdvd51::model()->findAllBySql($sql10h);	
						
						$sql10i="select 'VD510.I.'||TRIM(MKBD_CD)||'|'||
								   TRIM(JENIS_TRX)||'|'||
								   TRIM(TO_CHAR(TGL_TRX,'DD/MM/YYYY'))||'|'||
								  TRIM(CURRENCY_TYPE)||'|'||
								  TRIM(TO_CHAR(NILAI_RPH,'9999999999999999990.99'))||'|'||
								  TRIM(TO_CHAR(UNTUNG_RUGI,'9999999999999999990.99'))||'|'||
								  TRIM(TO_CHAR(RANKING,'9999999999999999990.99'))||'||||'
								  as text_vd510i
								  FROM insistpro_rpt.LAP_MKBD_VD510I Where approved_stat='A' 
							    and mkbd_date='$model->gen_dt'";
						$datavd510i = Lapmkbdvd51::model()->findAllBySql($sql10i);							
						
						$file = fopen("upload/mkbd_report/YJ$date.MKB","w");
						//WRITE FILE
						fwrite($file, "Kode AB|$kode_AB|||||||||\r\n");
						fwrite($file, "Tanggal|$date_AB|||||||||\r\n");
						fwrite($file, "Direktur|$direktur|||||||||\r\n");
						//WRITE VD51
						foreach($datavd51 as $row){
						fwrite($file, $row->text_vd51."\r\n");	
						}
						//WRITE VD52
						foreach($datavd52 as $row){
						fwrite($file, $row->text_vd52."\r\n");	
						}
						//WRITE VD53
						foreach($datavd53 as $row){
						fwrite($file, $row->text_vd53."\r\n");	
						}
						//WRITE VD54
						if($datavd54)
						{
							foreach($datavd54 as $row)
							{
							fwrite($file, $row->text_vd54."\r\n");	
							}
						}
						else{
							fwrite($file, "VD54.T||||||||||\r\n");	
						}
						
						//WRITE VD55
						if($datavd55)
						{
							foreach($datavd55 as $row)
							{
								fwrite($file, $row->text_vd55."\r\n");	
							}
						}
						else
						{
						fwrite($file, "VD55.T||||||||||\r\n");		
						}
						//WRITE VD56
						foreach($datavd56a as $row){
						fwrite($file, $row->text_vd56a."\r\n");	
						}
						foreach($datavd56b as $row){
						fwrite($file, $row->text_vd56b."\r\n");	
						}
						fwrite($file, "VD56.P||||||||||\r\n");
						//WRITE VD57
						foreach($datavd57 as $row){
						fwrite($file, $row->text_vd57."\r\n");	
						}
						fwrite($file, "VD57.P||||||||||\r\n");
						//WRITE VD58
						foreach($datavd58 as $row){
						fwrite($file, $row->text_vd58."\r\n");	
						}
						//WRITE VD59
						foreach($datavd59 as $row){
						fwrite($file, $row->text_vd59."\r\n");	
						}
						//WRITE VD510A
						if($datavd10a){
							foreach($datavd10a as $row){
							fwrite($file, $row->text_vd510a."\r\n");		
							}
						}
						else{
						fwrite($file, "VD510.A.A||||||||||\r\n");
						fwrite($file, "VD510.A.B||||||||||\r\n");
						fwrite($file, "VD510.A.C||||||||||\r\n");
						fwrite($file, "VD510.A.T||||||||||\r\n");	
						}
						
						//WRITE VD510B
						if($datavd510b)
						{
							foreach($datavd510b as $row)
							{
							fwrite($file, $row->text_vd510b."\r\n");	
							}
						}
						else 
						{
							fwrite($file, "VD510.B.A||||||||||\r\n");
							fwrite($file, "VD510.B.B||||||||||\r\n");
							fwrite($file, "VD510.B.C||||||||||\r\n");
							fwrite($file, "VD510.B.T||||||||||\r\n");	
						}
						
						//WRITE VD510C
						if($datavd510c)
						{
							foreach($datavd510c as $row)
							{
							fwrite($file, $row->text_vd510c."\r\n");	
							}	
						}
						else 
						{
							fwrite($file, "VD510.C.A||||||||||\r\n");
							fwrite($file, "VD510.C.B||||||||||\r\n");
							fwrite($file, "VD510.C.C||||||||||\r\n");
							fwrite($file, "VD510.C.D||||||||||\r\n");
							fwrite($file, "VD510.C.E||||||||||\r\n");
							fwrite($file, "VD510.C.T||||||||||\r\n");	
						}
						
						
						//WRITE VD510D
						if($datavd510d)
						{
							foreach($datavd510d as $row)
							{
							fwrite($file, $row->text_vd510d."\r\n");	
							}
						}
						else 
						{
							fwrite($file, "VD510.D.A||||||||||\r\n");
							fwrite($file, "VD510.D.B||||||||||\r\n");
							fwrite($file, "VD510.D.T||||||||||\r\n");
						}
						
						
						//WRITE VD510E
						if($datavd510e)
						{
							foreach($datavd510e as $row)
							{
							fwrite($file, $row->text_vd510e."\r\n");	
							}
						}
						else 
						{
							fwrite($file, "VD510.E.T||||||||||\r\n");	
						}
						
						
						//WRITE VD510F
						if($datavd510f){
						foreach($datavd510f as $row){
						fwrite($file, $row->text_vd510f."\r\n");	
						}
						}
						else{
							fwrite($file, "VD510.F.A||||||||||\r\n");
							fwrite($file, "VD510.F.B||||||||||\r\n");
							fwrite($file, "VD510.F.C||||||||||\r\n");
							fwrite($file, "VD510.F.D||||||||||\r\n");
							fwrite($file, "VD510.F.T||||||||||\r\n");
						}
						
						//WRITE VD510G
						if($datavd510g){
						foreach($datavd510g as $row){
						fwrite($file, $row->text_vd510g."\r\n");	
						}
						}
						else{
						fwrite($file,"VD510.G.T||||||||||\r\n");	
						}
						//WRITE VD510H
						
						if($datavd510h){
						foreach($datavd510h as $row){
						fwrite($file, $row->text_vd510h."\r\n");	
						}	
						}
						else
						{
							fwrite($file,"VD510.H.T||||||||||\r\n");
						}
						
						//WRITE VD510I
						if($datavd510i){
							foreach($datavd510i as $row){
							fwrite($file, $row->text_vd510i."\r\n");		
							}
						}
						else{
						fwrite($file,"VD510.I.T||||||||||\r\n");	
						}
						
						
						fclose($file);
						
						//DOWNLOAD FILE LTH
						$filename = "upload/mkbd_report/YJ$date.MKB";
						header("Cache-Control: public");
						header("Content-Description: File Transfer");
						header("Content-Length: ". filesize("$filename").";");
						header("Content-Disposition: attachment; filename=YJ$date.MKB");
						header("Content-Type: application/octet-stream; "); 
						header("Content-Transfer-Encoding: binary");
						ob_clean();
				        flush();
						readfile($filename);
						unlink("upload/mkbd_report/YJ$date.MKB");
						exit;
						//DELETE FILE AFTER DOWNLOAD	
					//}//end cek vd51 dan vd52	
			}//end validasi
		}

	else if($scenario =='print_e')//print report yang belum diappove
	{
		$user_id =  Yii::app()->user->id;
		$model->vp_userid = $user_id;
		$label_header = 'Report MKBD Not Approved';
		//validasi
		//cek apakah sudah pernah digenerate
		$sql="select * from (
				select to_date(field_value,'yyyy/mm/dd hh24:mi:ss') gen_date
				from t_many_detail d, t_many_header h
				where d.update_date= h.update_date
				and d.update_seq = h.update_seq
				and h.menu_name = 'MKBD REPORT'
				 and d.field_name='MKBD_DATE'
				and h.approved_status='E') where gen_date = to_date('$model->gen_dt','yyyy-mm-dd') ";
		$cek = DAO::queryRowSql($sql);
		
		if(!$cek){
			
			$date = DateTime::createFromFormat('Y-m-d',$model->gen_dt)->format('d M Y');
			$model->addError('gen_dt', "Report MKBD tanggal $date tidak ada yang belum diapprove");
		}	
		else {
			
				
		if($model->vd51){
			$modelvd51 = new Rptmkbdreport('Generate_MKBD_Report','LAP_MKBD_VD51','Report_VD51.rptdesign');
			$modelvd51->trx_date = $model->gen_dt;
			$modelvd51->vp_userid = $model->vp_userid;
			$modelvd51->approved_stat ='E';
			$urlvd51 = $modelvd51->showReport2();
			}
			if($model->vd52){
			$modelvd52 = new Rptmkbdreport('Generate_MKBD_Report','LAP_MKBD_VD52','Report_VD52.rptdesign');
			$modelvd52->trx_date = $model->gen_dt;
			$modelvd52->vp_userid = $model->vp_userid;
			$modelvd52->approved_stat ='E';
			$urlvd52 = $modelvd52->showReport2();
			}
			if($model->vd53){
			$modelvd53 = new Rptmkbdreport('Generate_MKBD_Report','LAP_MKBD_VD53','Report_VD53.rptdesign');
			$modelvd53->trx_date = $model->gen_dt;
			$modelvd53->vp_userid = $model->vp_userid;
			$modelvd53->approved_stat ='E';
			$urlvd53 = $modelvd53->showReport2();
			}
			if($model->vd54){
			$modelvd54 = new Rptmkbdreport('Generate_MKBD_Report','LAP_MKBD_VD54','Report_VD54.rptdesign');
			$modelvd54->trx_date = $model->gen_dt;
			$modelvd54->vp_userid = $model->vp_userid;
			$modelvd54->approved_stat ='E';
			$urlvd54 = $modelvd54->showReport2();
			}
			if($model->vd55){
			$modelvd55 = new Rptmkbdreport('Generate_MKBD_Report','LAP_MKBD_VD55','Report_VD55.rptdesign');
			$modelvd55->trx_date = $model->gen_dt;
			$modelvd55->vp_userid = $model->vp_userid;
			$modelvd55->approved_stat ='E';
			$urlvd55 = $modelvd55->showReport2();
			}
			if($model->vd56){
			$modelvd56 = new Rptmkbdreport('Generate_MKBD_Report','LAP_MKBD_VD56','Report_VD56.rptdesign');
			$modelvd56->trx_date = $model->gen_dt;
			$modelvd56->vp_userid = $model->vp_userid;
			$modelvd56->approved_stat ='E';
			$urlvd56 = $modelvd56->showReport2();
			}
			if($model->vd57){
			$modelvd57 = new Rptmkbdreport('Generate_MKBD_Report','LAP_MKBD_VD57','Report_VD57.rptdesign');
			$modelvd57->trx_date = $model->gen_dt;
			$modelvd57->vp_userid = $model->vp_userid;
			$modelvd57->approved_stat ='E';
			$urlvd57 = $modelvd57->showReport2();
			}
			if($model->vd58){
			$modelvd58 = new Rptmkbdreport('Generate_MKBD_Report','LAP_MKBD_VD58','Report_VD58.rptdesign');
			$modelvd58->trx_date = $model->gen_dt;
			$modelvd58->vp_userid = $model->vp_userid;
			$modelvd58->approved_stat ='E';
			$urlvd58 = $modelvd58->showReport2();
			}
			if($model->vd59){
			$modelvd59 = new Rptmkbdreport('Generate_MKBD_Report','LAP_MKBD_VD59','Report_VD59.rptdesign');
			$modelvd59->trx_date = $model->gen_dt;
			$modelvd59->vp_userid = $model->vp_userid;
			$modelvd59->approved_stat ='E';
			$urlvd59 = $modelvd59->showReport2();
			}
			if($model->vd510a){
			$modelvd510a = new Rptmkbdreport('Generate_MKBD_Report','LAP_MKBD_VD510A','Report_VD510A.rptdesign');
			$modelvd510a->trx_date = $model->gen_dt;
			$modelvd510a->vp_userid = $model->vp_userid;
			$modelvd510a->approved_stat ='E';
			$urlvd510a = $modelvd510a->showReport2();
			}
			if($model->vd510b){
			$modelvd510b = new Rptmkbdreport('Generate_MKBD_Report','LAP_MKBD_VD510B','Report_VD510B.rptdesign');
			$modelvd510b->trx_date = $model->gen_dt;
			$modelvd510b->vp_userid = $model->vp_userid;
			$modelvd510b->approved_stat ='E';
			$urlvd510b = $modelvd510b->showReport2();
			}
			if($model->vd510c){
			$modelvd510c = new Rptmkbdreport('Generate_MKBD_Report','LAP_MKBD_VD510C','Report_VD510C.rptdesign');
			$modelvd510c->trx_date = $model->gen_dt;
			$modelvd510c->vp_userid = $model->vp_userid;
			$modelvd510c->approved_stat ='E';
			$urlvd510c = $modelvd510c->showReport2();
			}
			if($model->vd510d){
			$modelvd510d = new Rptmkbdreport('Generate_MKBD_Report','LAP_MKBD_VD510D','Report_VD510D.rptdesign');
			$modelvd510d->trx_date = $model->gen_dt;
			$modelvd510d->vp_userid = $model->vp_userid;
			$modelvd510d->approved_stat ='E';
			$urlvd510d = $modelvd510d->showReport2();
			}
			if($model->vd510e){
			$modelvd510e = new Rptmkbdreport('Generate_MKBD_Report','LAP_MKBD_VD510E','Report_VD510E.rptdesign');
			$modelvd510e->trx_date = $model->gen_dt;
			$modelvd510e->vp_userid = $model->vp_userid;
			$modelvd510e->approved_stat ='E';
			$urlvd510e = $modelvd510e->showReport2();
			}
			if($model->vd510f){
			$modelvd510f = new Rptmkbdreport('Generate_MKBD_Report','LAP_MKBD_VD510F','Report_VD510F.rptdesign');
			$modelvd510f->trx_date = $model->gen_dt;
			$modelvd510f->vp_userid = $model->vp_userid;
			$modelvd510f->approved_stat ='E';
			$urlvd510f = $modelvd510f->showReport2();
			}
			if($model->vd510g){
			$modelvd510g = new Rptmkbdreport('Generate_MKBD_Report','LAP_MKBD_VD510G','Report_VD510G.rptdesign');
			$modelvd510g->trx_date = $model->gen_dt;
			$modelvd510g->vp_userid = $model->vp_userid;
			$modelvd510g->approved_stat ='E';
			$urlvd510g = $modelvd510g->showReport2();
			}
			if($model->vd510h){
			$modelvd510h = new Rptmkbdreport('Generate_MKBD_Report','LAP_MKBD_VD510H','Report_VD510H.rptdesign');
			$modelvd510h->trx_date = $model->gen_dt;
			$modelvd510h->vp_userid = $model->vp_userid;
			$modelvd510h->approved_stat ='E';
			$urlvd510h = $modelvd510h->showReport2();
			}
			if($model->vd510i){
			$modelvd510i = new Rptmkbdreport('Generate_MKBD_Report','LAP_MKBD_VD510I','Report_VD510I.rptdesign');
			$modelvd510i->trx_date = $model->gen_dt;
			$modelvd510i->vp_userid = $model->vp_userid;
			$modelvd510i->approved_stat ='E';
			$urlvd510i = $modelvd510i->showReport2();
			}
			}//end cek generate	
	
	}
		else if($scenario =='print')//cetak report mkbd
		{
			
		$modelprint = new Rptmkbdreport('Generate_MKBD_Report','LAP_MKBD_VD510I','All_mkbd.rptdesign');
		$modelprint->trx_date = $model->gen_dt;
		if($model->print_stat_a == 0){
		$modelprint->approved_stat = 'A';	
		}
		else{
			$modelprint->approved_stat = 'E';
		}
			
		
		$user_id =  Yii::app()->user->id;
		$modelprint->vp_userid = $user_id;
			
			if($model->r_1)
			{
			$modelprint->p_vd51 = 'Y';
			}
			else
			{
				$modelprint->p_vd51 = 'N';
			}
			if($model->r_2)
			{
			$modelprint->p_vd52 = 'Y';
			}
			else
			{
				$modelprint->p_vd52 = 'N';
			}
			if($model->r_3)
			{
			$modelprint->p_vd53 = 'Y';
			}
			else
			{
				$modelprint->p_vd53 = 'N';
			}
			if($model->r_4)
			{
			$modelprint->p_vd54 = 'Y';
			}
			else
			{
				$modelprint->p_vd54 = 'N';
			}
			if($model->r_5)
			{
			$modelprint->p_vd55 = 'Y';
			}
			else
			{
				$modelprint->p_vd55 = 'N';
			}
			if($model->r_6)
			{
				$modelprint->p_vd56 = 'Y';			
			}
			else
			{
				$modelprint->p_vd56 = 'N';
			}
			if($model->r_7)
			{
			$modelprint->p_vd57 = 'Y';
			}
			else
			{
				$modelprint->p_vd57 = 'N';
			}
			if($model->r_8)
			{
			$modelprint->p_vd58 = 'Y';
			}
			else
			{
				$modelprint->p_vd58 = 'N';
			}
			if($model->r_9)
			{
			$modelprint->p_vd59 = 'Y';
			}
			else
			{
				$modelprint->p_vd59 = 'N';
			}
			if($model->r_a)
			{
			$modelprint->p_vd510a = 'Y';
			}
			else
			{
				$modelprint->p_vd510a = 'N';
			}
			if($model->r_b)
			{
			$modelprint->p_vd510b = 'Y';
			}
			else
			{
				$modelprint->p_vd510b = 'N';
			}
			if($model->r_c)
			{
			$modelprint->p_vd510c = 'Y';
			}
			else
			{
				$modelprint->p_vd510c = 'N';
			}
			if($model->r_d)
			{
			$modelprint->p_vd510d = 'Y';
			}
			else
			{
				$modelprint->p_vd510d = 'N';
			}
			if($model->r_e)
			{
			$modelprint->p_vd510e = 'Y';
			}
			else
			{
				$modelprint->p_vd510e = 'N';
			}
			if($model->r_f)
			{
			$modelprint->p_vd510f = 'Y';
			}
			else
			{
				$modelprint->p_vd510f = 'N';
			}
			if($model->r_g)
			{
			$modelprint->p_vd510g = 'Y';
			}
			else
			{
				$modelprint->p_vd510g = 'N';
			}
			if($model->r_h)
			{
			$modelprint->p_vd510h = 'Y';
			}
			else
			{
				$modelprint->p_vd510h = 'N';
			}
			if($model->r_i)
			{
			$modelprint->p_vd510i = 'Y';
			}
			else
			{
				$modelprint->p_vd510i = 'N';
			}
			
			$urlprint = $modelprint->showReportMkbd();
			
		}


	}//end scenario
	if(DateTime::createFromFormat('Y-m-d',$model->gen_dt))$model->gen_dt=DateTime::createFromFormat('Y-m-d',$model->gen_dt)->format('d/m/Y');
		
		
		$this->render('index',array('model'=>$model,
									'notFound'=>$notFound,
									'urlvd51'=>$urlvd51,
									'urlvd52'=>$urlvd52,
									'urlvd53'=>$urlvd53,
									'urlvd54'=>$urlvd54,
									'urlvd55'=>$urlvd55,
									'urlvd56'=>$urlvd56,
									'urlvd57'=>$urlvd57,
									'urlvd58'=>$urlvd58,
									'urlvd59'=>$urlvd59,
									'urlvd510a'=>$urlvd510a,
									'urlvd510b'=>$urlvd510b,
									'urlvd510c'=>$urlvd510c,
									'urlvd510d'=>$urlvd510d,
									'urlvd510e'=>$urlvd510e,
									'urlvd510f'=>$urlvd510f,
									'urlvd510g'=>$urlvd510g,
									'urlvd510h'=>$urlvd510h,
									'urlvd510i'=>$urlvd510i,
									'label_header'=>$label_header,
									'urlprint'=>$urlprint
									));
	}
public function actionSave_Text_File()
	{
	
		$resp['status']='error';
		
		if(isset($_POST['tanggal']))
		{
			
			$tanggal=$_POST['tanggal'];
			$user_id=Yii::app()->user->id;
			if(DateTime::createFromFormat('d/m/Y',$tanggal))$tanggal=DateTime::createFromFormat('d/m/Y',$tanggal)->format('Y-m-d');
			$sql="SELECT COUNT(*) as count FROM insistpro_rpt.LAP_MKBD_VD51 WHERE APPROVED_STAT='A'";	
			$count=DAO::queryRowSql($sql);
			
				
			if($count['count']>0)
			{
				$resp['status']='success';	
			}
		}
		echo json_encode($resp);
	}
	public function actionCekdate(){
		$resp['status'] ='error';
		
		if(isset($_POST['tanggal']))
		{
			$tanggal=$_POST['tanggal'];
			if(DateTime::createFromFormat('d/m/Y',$tanggal))$tanggal=DateTime::createFromFormat('d/m/Y',$tanggal)->format('Y-m-d');
			
			//validation T_CLOSE_PRICE
		$cek =Tcloseprice::model()->find("stk_date = to_date('$tanggal','yyyy-mm-dd')");
		$price_dt= Tcloseprice::model()->find(array('select'=>'MAX(STK_DATE) stk_date',
				'condition'=>"stk_date between to_date('$tanggal','yyyy-mm-dd')-20 and to_date('$tanggal','yyyy-mm-dd')"));
		if(DateTime::createFromFormat('Y-m-d h:i:s',$price_dt->stk_date))$price_dt->stk_date = DateTime::createFromFormat('Y-m-d h:i:s',$price_dt->stk_date)->format('d/m/Y');
		
		if(!$cek){
			$resp['status'] = 'success';
			$resp['price_dt']=$price_dt->stk_date;
		}
		else 
		{
			$resp['status'] = 'error';
			$resp['price_dt']=$price_dt->stk_date;
			
		}
			
			
		}
	echo json_encode($resp);	
	}
	public function actionAjxValidateGenerate() //LO: The purpose of this 'empty' function is to check whether an user is authorized to perform cancellation
	{
		$resp = '';
		echo json_encode($resp);
	}
	
	
	}