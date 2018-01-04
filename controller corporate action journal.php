<?php

class CorpactjournalController extends AAdminController
{
	
	public $layout='//layouts/admin_column3';
	
	public function actionIndex()
	{
		$cek_date = Sysparam::model()->find("param_id='CORP ACT' and param_cd1='START'")->ddate1;
		$cek_pape = Sysparam::model()->find("param_id = 'CORP_ACT' AND param_cd1 = 'PAPE' ")->dflg1;
		$sql="SELECT X.* FROM (SELECT a.STK_CD, a.CA_TYPE, a.CUM_DT, 		
					   a.X_DT, a.RECORDING_DT, a.DISTRIB_DT, 	
					     a.FROM_QTY, a.TO_QTY, a.rate,	
						 case when a.DISTRIB_DT < '$cek_date' or b.jur_match_dt is not null then 'Y' else 'N' end jurnal_cumdt, 
        		    case when a.DISTRIB_DT < '$cek_date' or c.jur_distrib_dt is not null then 'Y' else 'N' end jurnal_distribdt,
        		    case when a.distrib_dt < '$cek_date' or d.distrib_dt_journal is not null then 'Y' else 'N' end distrib_dt_journal
					FROM( SELECT 	
						STK_CD, CA_TYPE, CUM_DT, 
						   X_DT, RECORDING_DT, DISTRIB_DT, 
						   FROM_QTY, TO_QTY,rate,
						decode(ca_type,'SPLIT',x_dt,'REVERSE',x_dt,cum_dt) as match_dt
						FROM T_CORP_ACT
						WHERE (ca_type IN ('SPLIT','REVERSE','RIGHT','WARRANT','BONUS','STKDIV'))
						AND distrib_dt >= (TRUNC(SYSDATE) - 80)
						AND approved_stat = 'A' ) a,
					( SELECT DISTINCT DECODE(JUR_TYPE,'SPLITX',STK_CD,'REVERSEX',STK_CD,SUBSTR(STK_CD,1,4))stk_Cd, doc_dt AS jur_match_dt	
					FROM T_STK_MOVEMENT	
					WHERE doc_dt >= (TRUNC(SYSDATE) - 80) 	
					AND doc_stat = '2'	
					AND s_d_type IN ('S','R','H','B')	
					and jur_type in ('SPLITX','REVERSEX','HMETDC','STKDIVC','BONUSC')
					AND seqno = 1) b,	
						( SELECT DISTINCT DECODE(JUR_TYPE,'HMETDD',SUBSTR(STK_CD,1,4),STK_CD)stk_Cd, doc_dt AS jur_distrib_dt
					FROM T_STK_MOVEMENT	
					WHERE doc_dt >= (TRUNC(SYSDATE) - 80) 	
					AND doc_stat = '2'	
					AND s_d_type IN ('S','R','H','B')	
					and jur_type in ('SPLITD','REVERSED','HMETDD','STKDIVD','BONUSD')	
					AND seqno = 1) c,
					( SELECT DISTINCT stk_Cd, doc_dt AS distrib_dt_journal
					FROM T_STK_MOVEMENT	
					WHERE doc_dt >= (TRUNC(SYSDATE) - 80) 	
					AND doc_stat = '2'	
					AND s_d_type IN ('S','R','H','B')	
					and jur_type in ('SPLITN','REVERSEN','HMETDN','STKDIVN','BONUSN')	
					AND seqno = 1) d	
					WHERE a.stk_cd = b.stk_cd(+)	
					AND a.match_dt = b.jur_match_dt(+)	
					AND a.stk_cd = c.stk_cd(+)	
					AND a.distrib_dt = c.jur_distrib_dt(+) 
					 AND A.STK_CD = D.STK_CD(+)
					AND a.distrib_dt = d.distrib_dt_journal(+)
					order by a.CUM_DT desc)X ORDER BY cum_dt desc";
					
			$model=Tcorpact::model()->findAllBySql($sql);		
			$modeldummy = new Tcorpact;
			
			$date = Yii::app()->request->cookies['distrib_dt']?Yii::app()->request->cookies['distrib_dt']->value:NULL;
			if(DateTime::createFromFormat('Y-m-d',$date))$date=DateTime::createFromFormat('Y-m-d',$date)->format('d/m/Y');
			$modeldummy->distrib_dt = $date?$date:Date('d/m/Y',strtotime('-40 days'));	
			$modeldummy->ca_type_filter =  Yii::app()->request->cookies['ca_type']?Yii::app()->request->cookies['ca_type']->value:NULL;
		if(isset($_POST['Tcorpact'])){
				$modeldummy->attributes = $_POST['Tcorpact'];
				
				
	if(DateTime::createFromFormat('d/m/Y',$modeldummy->distrib_dt))$modeldummy->distrib_dt=DateTime::createFromFormat('d/m/Y',$modeldummy->distrib_dt)->format('Y-m-d');		
	Yii::app()->request->cookies['distrib_dt'] = new CHttpCookie('distrib_dt', $modeldummy->distrib_dt);
	Yii::app()->request->cookies['ca_type'] = new CHttpCookie('ca_type',$modeldummy->ca_type_filter);
	
			if($modeldummy->distrib_dt !=''){
					
						$sql="SELECT X.* FROM (SELECT a.STK_CD, a.CA_TYPE, a.CUM_DT, 		
					   a.X_DT, a.RECORDING_DT, a.DISTRIB_DT, 	
					     a.FROM_QTY, a.TO_QTY, a.rate,	
						 case when a.DISTRIB_DT < '$cek_date' or b.jur_match_dt is not null then 'Y' else 'N' end jurnal_cumdt, 
        		    case when a.DISTRIB_DT < '$cek_date' or c.jur_distrib_dt is not null then 'Y' else 'N' end jurnal_distribdt,
        		    case when a.distrib_dt < '$cek_date' or d.distrib_dt_journal is not null then 'Y' else 'N' end distrib_dt_journal 
					FROM( SELECT 	
						STK_CD, CA_TYPE, CUM_DT, 
						   X_DT, RECORDING_DT, DISTRIB_DT, 
						   FROM_QTY, TO_QTY,rate,
						decode(ca_type,'SPLIT',x_dt,'REVERSE',x_dt,cum_dt) as match_dt
						FROM T_CORP_ACT
						WHERE (ca_type IN ('SPLIT','REVERSE','RIGHT','WARRANT','BONUS','STKDIV'))
						AND distrib_dt >= to_date('$modeldummy->distrib_dt','yyyy-mm-dd')
						AND approved_stat = 'A' ) a,
					( SELECT DISTINCT DECODE(JUR_TYPE,'SPLITX',STK_CD,'REVERSEX',STK_CD,SUBSTR(STK_CD,1,4))stk_Cd, doc_dt AS jur_match_dt	
					FROM T_STK_MOVEMENT	
					WHERE doc_dt >= (to_date('$modeldummy->distrib_dt','yyyy-mm-dd') - 40) 	
					AND doc_stat = '2'	
					AND s_d_type IN ('S','R','H','B')	
					and jur_type in ('SPLITX','REVERSEX','HMETDC','STKDIVC','BONUSC')
					AND seqno = 1) b,	
						( SELECT DISTINCT DECODE(JUR_TYPE,'HMETDD',SUBSTR(STK_CD,1,4),STK_CD)stk_Cd, doc_dt AS jur_distrib_dt
					FROM T_STK_MOVEMENT	
					WHERE doc_dt >= (to_date('$modeldummy->distrib_dt','yyyy-mm-dd') - 40) 	
					AND doc_stat = '2'	
					AND s_d_type IN ('S','R','H','B')	
					and jur_type in ('SPLITD','REVERSED','HMETDD','STKDIVD','BONUSD')	
					AND seqno = 1) c,
					( SELECT DISTINCT stk_Cd, doc_dt AS distrib_dt_journal
					FROM T_STK_MOVEMENT	
					WHERE doc_dt >= (TRUNC(SYSDATE) - 80) 	
					AND doc_stat = '2'	
					AND s_d_type IN ('S','R','H','B')	
					and jur_type in ('SPLITN','REVERSEN','HMETDN','STKDIVN','BONUSN')	
					AND seqno = 1) d		
					WHERE a.stk_cd = b.stk_cd(+)	
					AND a.match_dt = b.jur_match_dt(+)	
					AND a.stk_cd = c.stk_cd(+)	
					AND a.distrib_dt = c.jur_distrib_dt(+)
					 AND A.STK_CD = D.STK_CD(+)
					AND a.distrib_dt = d.distrib_dt_journal(+) 
					order by a.CUM_DT desc)X
			          WHERE STK_CD LIKE '%$modeldummy->stk_cd_filter'
			          and ca_type like '%$modeldummy->ca_type_filter'
			         
			          ORDER BY cum_dt desc";
			          $model= Tcorpact::model()->findAllBySql($sql);		
					
				}	
			else if(($modeldummy->stk_cd !='' || $modeldummy->ca_type != '') && $modeldummy->distrib_dt !=''){
						$sql="SELECT X.* FROM (SELECT a.STK_CD, a.CA_TYPE, a.CUM_DT, 		
					   a.X_DT, a.RECORDING_DT, a.DISTRIB_DT, 	
					     a.FROM_QTY, a.TO_QTY, a.rate,	
						 case when a.DISTRIB_DT < '$cek_date' or b.jur_match_dt is not null then 'Y' else 'N' end jurnal_cumdt, 
        		    case when a.DISTRIB_DT < '$cek_date' or c.jur_distrib_dt is not null then 'Y' else 'N' end jurnal_distribdt,
        		    case when a.distrib_dt < '$cek_date' or d.distrib_dt_journal is not null then 'Y' else 'N' end distrib_dt_journal  
					FROM( SELECT 	
						STK_CD, CA_TYPE, CUM_DT, 
						   X_DT, RECORDING_DT, DISTRIB_DT, 
						   FROM_QTY, TO_QTY,rate,
						decode(ca_type,'SPLIT',x_dt,'REVERSE',x_dt,cum_dt) as match_dt
						FROM T_CORP_ACT
						WHERE (ca_type IN ('SPLIT','REVERSE','RIGHT','WARRANT','BONUS','STKDIV'))
						AND distrib_dt >= to_date('$modeldummy->distrib_dt','yyyy-mm-dd')
						AND approved_stat = 'A' ) a,
					( SELECT DISTINCT DECODE(JUR_TYPE,'SPLITX',STK_CD,'REVERSEX',STK_CD,SUBSTR(STK_CD,1,4))stk_Cd, doc_dt AS jur_match_dt	
					FROM T_STK_MOVEMENT	
					WHERE doc_dt >= to_date('$modeldummy->distrib_dt','yyyy-mm-dd') - 40) 	
					AND doc_stat = '2'	
					AND s_d_type IN ('S','R','H','B')	
					and jur_type in ('SPLITX','REVERSEX','HMETDC','STKDIVC','BONUSC')
					AND seqno = 1) b,	
						( SELECT DISTINCT DECODE(JUR_TYPE,'HMETDD',SUBSTR(STK_CD,1,4),STK_CD)stk_Cd, doc_dt AS jur_distrib_dt
					FROM T_STK_MOVEMENT	
					WHERE doc_dt >= (to_date('$modeldummy->distrib_dt','yyyy-mm-dd') - 40) 	
					AND doc_stat = '2'	
					AND s_d_type IN ('S','R','H','B')	
					and jur_type in ('SPLITD','REVERSED','HMETDD','STKDIVD','BONUSD')	
					AND seqno = 1) c,
					( SELECT DISTINCT stk_Cd, doc_dt AS distrib_dt_journal
					FROM T_STK_MOVEMENT	
					WHERE doc_dt >= (to_date('$modeldummy->distrib_dt','yyyy-mm-dd') - 40) 	
					AND doc_stat = '2'	
					AND s_d_type IN ('S','R','H','B')	
					and jur_type in ('SPLITN','REVERSEN','HMETDN','STKDIVN','BONUSN')	
					AND seqno = 1) d			
					WHERE a.stk_cd = b.stk_cd(+)	
					AND a.match_dt = b.jur_match_dt(+)	
					AND a.stk_cd = c.stk_cd(+)	
					AND a.distrib_dt = c.jur_distrib_dt(+) 
					 AND A.STK_CD = D.STK_CD(+)
					AND a.distrib_dt = d.distrib_dt_journal(+)
					order by a.CUM_DT desc)X
			          WHERE STK_CD LIKE '%$modeldummy->stk_cd_filter'
			          and ca_type like '%$modeldummy->ca_type_filter'
			         
			          ORDER BY cum_dt desc";
			          $model= Tcorpact::model()->findAllBySql($sql);		
					
				}						
		else{
				//echo "<script>alert('te')</script>";
					$sql="SELECT X.* FROM (SELECT a.STK_CD, a.CA_TYPE, a.CUM_DT, 		
					   a.X_DT, a.RECORDING_DT, a.DISTRIB_DT, 	
					     a.FROM_QTY, a.TO_QTY, a.rate,	
						 case when a.DISTRIB_DT < '$cek_date' or b.jur_match_dt is not null then 'Y' else 'N' end jurnal_cumdt, 
        		    case when a.DISTRIB_DT < '$cek_date' or c.jur_distrib_dt is not null then 'Y' else 'N' end jurnal_distribdt,
        		    case when a.distrib_dt < '$cek_date' or d.distrib_dt_journal is not null then 'Y' else 'N' end distrib_dt_journal   
					FROM( SELECT 	
						STK_CD, CA_TYPE, CUM_DT, 
						   X_DT, RECORDING_DT, DISTRIB_DT, 
						   FROM_QTY, TO_QTY,rate,
						decode(ca_type,'SPLIT',x_dt,'REVERSE',x_dt,cum_dt) as match_dt
						FROM T_CORP_ACT
						WHERE (ca_type IN ('SPLIT','REVERSE','RIGHT','WARRANT','BONUS','STKDIV'))
						
						AND approved_stat = 'A' ) a,
					( SELECT DISTINCT DECODE(JUR_TYPE,'SPLITX',STK_CD,'REVERSEX',STK_CD,SUBSTR(STK_CD,1,4))stk_Cd, doc_dt AS jur_match_dt	
					FROM T_STK_MOVEMENT	
					WHERE 
					doc_stat = '2'	
					AND s_d_type IN ('S','R','H','B')	
					and jur_type in ('SPLITX','REVERSEX','HMETDC','STKDIVC','BONUSC')
					AND seqno = 1) b,	
						( SELECT DISTINCT DECODE(JUR_TYPE,'HMETDD',SUBSTR(STK_CD,1,4),STK_CD)stk_Cd, doc_dt AS jur_distrib_dt
					FROM T_STK_MOVEMENT	
					WHERE
					doc_stat = '2'	
					AND s_d_type IN ('S','R','H','B')	
					and jur_type in ('SPLITD','REVERSED','HMETDD','STKDIVD','BONUSD')	
					AND seqno = 1) c,
					( SELECT DISTINCT stk_Cd, doc_dt AS distrib_dt_journal
					FROM T_STK_MOVEMENT	
					WHERE doc_stat = '2'	
					AND s_d_type IN ('S','R','H','B')	
					and jur_type in ('SPLITN','REVERSEN','HMETDN','STKDIVN','BONUSN')	
					AND seqno = 1) d	
					WHERE a.stk_cd = b.stk_cd(+)	
					AND a.match_dt = b.jur_match_dt(+)	
					AND a.stk_cd = c.stk_cd(+)	
					AND a.distrib_dt = c.jur_distrib_dt(+) 
					 AND A.STK_CD = D.STK_CD(+)
					AND a.distrib_dt = d.distrib_dt_journal(+)
					order by a.CUM_DT desc)X
			          WHERE STK_CD LIKE '%$modeldummy->stk_cd_filter'
			          and ca_type like '%$modeldummy->ca_type_filter'
			          ORDER BY cum_dt desc";
			         
			          $model= Tcorpact::model()->findAllBySql($sql);	
		}
	
		}//tcorpact
	
		
	
		foreach($model as $row){
			if(DateTime::createFromFormat('Y-m-d H:i:s',$row->cum_dt))$row->cum_dt = DateTime::createFromFormat('Y-m-d H:i:s',$row->cum_dt)->format('d/m/Y');
			if(DateTime::createFromFormat('Y-m-d H:i:s',$row->x_dt))$row->x_dt = DateTime::createFromFormat('Y-m-d H:i:s',$row->x_dt)->format('d/m/Y');
			if(DateTime::createFromFormat('Y-m-d H:i:s',$row->recording_dt))$row->recording_dt = DateTime::createFromFormat('Y-m-d H:i:s',$row->recording_dt)->format('d/m/Y');
			if(DateTime::createFromFormat('Y-m-d H:i:s',$row->distrib_dt))$row->distrib_dt = DateTime::createFromFormat('Y-m-d H:i:s',$row->distrib_dt)->format('d/m/Y');
		}
	if(DateTime::createFromFormat('Y-m-d',$modeldummy->distrib_dt))$modeldummy->distrib_dt=DateTime::createFromFormat('Y-m-d',$modeldummy->distrib_dt)->format('d/m/Y');	
		
		
		
		
		$this->render('index',
				array('model'=>$model,
						'modeldummy'=>$modeldummy,
						'cek_pape'=>$cek_pape
					));
	}
	
	
	
	public function actionParam($stk_cd,$ca_type,$cum_dt,$jurnal_cumdt,$distrib_dt,$x_dt,$from_qty,$to_qty,$recording_dt,$jurnal_distribdt,$rate){
		
	
		$model = new Tcorpact;
		$model->scenario ='report';
		$cekParam = Sysparam::model()->find(" param_id='CORP ACT JOURNAL' and param_cd1='INPUT' and param_cd2='TODAY'")->dflg1;
		$cek_pape = Sysparam::model()->find("param_id = 'CORP_ACT' AND param_cd1 = 'PAPE' ")->dflg1;
		$model->ca_type = $ca_type;
		if($model->ca_type == 'RIGHT'){
		$model->stk_cd = $stk_cd.'-R';
		}
		else if($model->ca_type=='WARRANT'){
		$model->stk_cd = $stk_cd.'-W';	
		}
		else{
		$model->stk_cd = $stk_cd;	
		}

		$model->cum_dt = $cum_dt;
		$model->jurnal_cumdt = $jurnal_cumdt;
		$model->distrib_dt = $distrib_dt;
		$model->x_dt =$x_dt;
		$model->from_qty = $from_qty;
		$model->to_qty = $to_qty;
		$model->recording_dt = $recording_dt;
		$model->jurnal_distribdt = $jurnal_distribdt;
		$model->rate = $rate;
		
		if($cek_pape=='Y')
		{
		
		if($model->jurnal_distribdt=='N' && ($model->ca_type =='SPLIT' || $model->ca_type =='REVERSE')){
			$model->today_dt =  $model->recording_dt;
		}
		else if(date('d/m/Y')< $model->distrib_dt && $model->jurnal_cumdt =='Y' && ($model->ca_type =='SPLIT' || $model->ca_type =='REVERSE')){
			$model->today_dt =  $model->cum_dt;
		}
		else {
			$model->today_dt =date('d/m/Y');	
		}
		}
		else{
				$model->today_dt =date('d/m/Y');
		}
		
			
			
			if(isset($_POST['scenario']))
			{
				$model->attributes = $_POST['Tcorpact'];
				
			/*
				if(($model->ca_type =='WARRANT' || $model->ca_type =='RIGHT' ) && strlen($model->stk_cd)<=4){
								$model->addError('stk_cd', "Tidak boleh sama dengan Stock Code pokok");
							}
							else {*/
			
				$this->redirect(array('Pilih','stk_cd'=>$model->stk_cd,'ca_type'=>$model->ca_type,'cum_dt'=>$model->cum_dt,'jurnal_cumdt'=>$model->jurnal_cumdt,'distrib_dt'=>$model->distrib_dt,'x_dt'=>$model->x_dt,'from_qty'=>$model->from_qty,'to_qty'=>$model->to_qty,'recording_dt'=>$model->recording_dt,'jurnal_distribdt'=>$model->jurnal_distribdt,'today_dt'=>$model->today_dt,'rate'=>$model->rate));	
				//}
					
				
			}
		$this->render('_form',array('model'=>$model,
									'cekParam'=>$cekParam));
	}
	

	public function actionPilih($stk_cd,$ca_type,$cum_dt,$jurnal_cumdt,$distrib_dt,$x_dt,$from_qty,$to_qty,$recording_dt,$jurnal_distribdt,$today_dt,$rate){

	$cek_pape = Sysparam::model()->find("param_id = 'CORP_ACT' AND param_cd1 = 'PAPE' ")->dflg1;
	$url = '';	
	$distrib_dt_bursa= $this->cek_date_bursa($distrib_dt, 'D');
	$recording_dt_bursa= $this->cek_date_bursa($recording_dt, 'R');		
	if(DateTime::createFromFormat('d/m/Y',$cum_dt))$cum_dt=DateTime::createFromFormat('d/m/Y',$cum_dt)->format('Y-m-d');						
	if(DateTime::createFromFormat('d/m/Y',$distrib_dt))$distrib_dt=DateTime::createFromFormat('d/m/Y',$distrib_dt)->format('Y-m-d');
	if(DateTime::createFromFormat('d/m/Y',$recording_dt))$recording_dt=DateTime::createFromFormat('d/m/Y',$recording_dt)->format('Y-m-d');
	if(DateTime::createFromFormat('d/m/Y',$x_dt))$x_dt=DateTime::createFromFormat('d/m/Y',$x_dt)->format('Y-m-d');
	if(DateTime::createFromFormat('d/m/Y',$today_dt))$today_dt=DateTime::createFromFormat('d/m/Y',$today_dt)->format('Y-m-d');
	
			//
			$cek =Tcontracts::model()->find("contr_dt = to_date('$cum_dt','yyyy-mm-dd') and contr_stat <> 'C' ");
			if($jurnal_cumdt =='N'){
				if($cek){
			$model = new Rptcorpactjournal('CORPORATE_ACTION_JOURNAL','R_CORP_ACT_JOURNAL','Corp_act_journal.rptdesign');
			$date=date_create($cum_dt);
			$date= date_format($date,"Y-m-01");
			$model->bgn_dt =$date;
			$model->stk_cd = $stk_cd;
			$model->ca_type = $ca_type;
			$model->cum_dt = $cum_dt;
			$model->recording_dt = $recording_dt;
			$model->today_dt = $today_dt;
			$model->distrib_dt = $distrib_dt;
			$model->rate = $rate;
			if($model->validate() && $model->executeRpt()>0){
				$url = $model->showReport();
			}
				
				}//end cek
			else
			{
			$date = DateTime::createFromFormat('Y-m-d',$cum_dt)->format('d/m');
			Yii::app()->user->setFlash('danger', "Report will be available after contract generation $date completed");
			$this->redirect(array('/custody/Corpactjournal/index'));
			}
			}//end jur cumdt N
			else//jika jur cum dt Y
			{
					$model = new Rptcorpactjournal('CORPORATE_ACTION_JOURNAL','R_CORP_ACT_JOURNAL','Corp_act_journal.rptdesign');
			$date=date_create($cum_dt);
			$date= date_format($date,"Y-m-01");
			$model->bgn_dt =$date;
			$model->stk_cd = $stk_cd;
			$model->ca_type = $ca_type;
			$model->cum_dt = $cum_dt;
			$model->recording_dt = $recording_dt;
			$model->today_dt = $today_dt;
			$model->rate = $rate;
			if($model->validate() && $model->executeRpt()>0){
				$url = $model->showReport();
			}
			}
			
			if(isset($_POST['scenario'])){
				$scenario= $_POST['scenario'];
			
				$model->scenario='jurnal';
				$model->attributes = $_POST['Rptcorpactjournal'];
				//if(DateTime::createFromFormat('d/m/Y',$model->today_dt))$model->today_dt=DateTime::createFromFormat('d/m/Y',$model->today_dt)->format('Y-m-d');
				$model->at_journal = $_POST['at_journal'];
				$date=date_create($cum_dt);
				$date= date_format($date,"Y-m-01");
				$model->bgn_dt =$date;
				$model->ca_type = $ca_type;
				$model->cum_dt = $cum_dt;
				$model->x_dt = $x_dt;
				$model->distrib_dt = $distrib_dt;
				$model->rate = $rate;
				$ip = Yii::app()->request->userHostAddress;
				if($ip=="::1")
					$ip = '127.0.0.1';
				$model->ip_address = $ip;
				$success=false;
				if($model->at_journal =='D'){
				$cek_date = $model->distrib_dt;	
				}
				else if($model->at_journal =='X'){
				$cek_date = $model->x_dt;	
				}
				else{
				$cek_date = $model->cum_dt;	
				}
				
			//CEK PENDING
			$sql="  SELECT * FROM (SELECT (SELECT TO_DATE(FIELD_VALUE,'YYYY/MM/DD HH24:MI:SS') FROM T_MANY_DETAIL DA 
					        WHERE DA.TABLE_NAME = 'T_STK_MOVEMENT' 
					        AND DA.UPDATE_DATE = DD.UPDATE_DATE
					        AND DA.UPDATE_SEQ = DD.UPDATE_SEQ
					        AND DA.FIELD_NAME = 'DOC_DT'
					        AND DA.RECORD_SEQ = DD.RECORD_SEQ) DOC_DT, 
					(SELECT FIELD_VALUE FROM T_MANY_DETAIL DA 
					        WHERE DA.TABLE_NAME = 'T_STK_MOVEMENT' 
					        AND DA.UPDATE_DATE = DD.UPDATE_DATE
					        AND DA.UPDATE_SEQ = DD.UPDATE_SEQ
					        AND DA.FIELD_NAME = 'STK_CD'
					        AND DA.RECORD_SEQ = DD.RECORD_SEQ) STK_CD,
					(SELECT FIELD_VALUE FROM T_MANY_DETAIL DA 
					        WHERE DA.TABLE_NAME = 'T_STK_MOVEMENT' 
					        AND DA.UPDATE_DATE = DD.UPDATE_DATE
					        AND DA.UPDATE_SEQ = DD.UPDATE_SEQ
					        AND DA.FIELD_NAME = 'JUR_TYPE'
					        AND DA.RECORD_SEQ = DD.RECORD_SEQ) JUR_TYPE
					FROM T_MANY_DETAIL DD, T_MANY_HEADER HH WHERE DD.TABLE_NAME = 'T_STK_MOVEMENT' AND DD.UPDATE_DATE = HH.UPDATE_DATE
					AND DD.UPDATE_SEQ = HH.UPDATE_SEQ AND DD.RECORD_SEQ =1 AND MENU_NAME ='CORPORATE ACTION JOURNAL'
					AND DD.FIELD_NAME = 'DOC_DT' AND HH.APPROVED_STATUS = 'E' ORDER BY HH.UPDATE_SEQ)
					WHERE STK_CD = '$model->stk_cd' and doc_dt = to_date('$cek_date','yyyy-mm-dd')";	
			$cek = Tstkmovement::model()->findAllBySql($sql);
			
			if($cek)
			{
				$model->addError('stk_cd','Masih ada belum diapprove');	
			}
			
			else 
			{
				
			if ($cek_pape=='Y')
			{
				if($model->validate() && $model->executeSp()>0)	$success=true;	
				else
				{
					$success=false;
				}		
			}
			else
			{	
				//UNTUK JOURNAL CORPORATE ACTION PAPE N		
				if($model->validate() && $model->executeSp2()>0)	$success=true;	
				else
				{
					$success=false;
				}	
			}
			
			
			if($success){
				Yii::app()->user->setFlash('success', 'Data Successfully Journal');
				$this->redirect(array('/custody/Corpactjournal/index'));
			}
			
			}//end cek inbox


			}//end scenario
				
		$this->render('_report',array('model'=>$model,
										'url'=>$url,
										'stk_cd'=>$stk_cd,
										'ca_type'=>$ca_type,
										'cum_dt'=>$cum_dt,
										'distrib_dt'=>$distrib_dt,
										'jurnal_cumdt'=>$jurnal_cumdt,
										'from_qty'=>$from_qty,
										'to_qty'=>$to_qty,
										'recording_dt'=>$recording_dt,
										'jurnal_distribdt'=>$jurnal_distribdt,
										'distrib_dt_bursa'=>$distrib_dt_bursa,
										'recording_dt_bursa'=>$recording_dt_bursa,
										'cek_pape'=>$cek_pape));
	}


	public function cek_date_bursa($date,$date_flg)
	{
	$date_bursa='';
	if($date_flg == 'D')
	{
		
			$distrib_date_bursa = DateTime::createFromFormat('d/m/Y',$date)->format('Y-m-d');	
			$distrib_date_bursa = date('Y-m-d',strtotime("$distrib_date_bursa -1 day"));
			
			
			$date_holiday = DateTime::createFromFormat('Y-m-d',$distrib_date_bursa)->format('D');
						
						if($date_holiday =='Sat'){
							$distrib_date_bursa = date('Y-m-d',strtotime("$distrib_date_bursa -1 day"));
						}
						else if($date_holiday == 'Sun'){
							$distrib_date_bursa = date('Y-m-d',strtotime("$distrib_date_bursa -2 day"));
						}
						else if($date_holiday == 'Mon'){
							$distrib_date_bursa = date('Y-m-d',strtotime("$distrib_date_bursa -3 day"));
						}
						
			
			$cek = Calendar::model()->find("tgl_libur = to_date('$distrib_date_bursa','yyyy-mm-dd')");
			
			while ($cek){
				
				$distrib_date_bursa = date('Y-m-d',strtotime("$distrib_date_bursa -1 day"));
				$date_holiday = DateTime::createFromFormat('Y-m-d',$distrib_date_bursa)->format('D');
			
			if($date_holiday =='Sat'){
				$distrib_date_bursa = date('Y-m-d',strtotime("$distrib_date_bursa -1 day"));
			}
			else if($date_holiday == 'Sun'){
				$distrib_date_bursa = date('Y-m-d',strtotime("$distrib_date_bursa -2 day"));
			}
			else if($date_holiday == 'Mon'){
				$distrib_date_bursa = date('Y-m-d',strtotime("$distrib_date_bursa -3 day"));
			}
				$cek = Calendar::model()->find("tgl_libur = to_date('$distrib_date_bursa','yyyy-mm-dd')");
			}
			$date_bursa=$distrib_date_bursa;
	}
	else if($date_flg == 'R')
	{
			$recording_date_bursa = DateTime::createFromFormat('d/m/Y',$date)->format('Y-m-d');	
			$recording_date_bursa = date('Y-m-d',strtotime("$recording_date_bursa +1 day"));
			
			$date_holiday = DateTime::createFromFormat('Y-m-d',$recording_date_bursa)->format('D');
						
						if($date_holiday =='Sat'){
							$recording_date_bursa = date('Y-m-d',strtotime("$recording_date_bursa +2 day"));
						}
						else if($date_holiday == 'Sun'){
							$recording_date_bursa = date('Y-m-d',strtotime("$recording_date_bursa +1 day"));
						}
						else if($date_holiday == 'Fri'){
							$recording_date_bursa = date('Y-m-d',strtotime("$recording_date_bursa +3 day"));
						}
			
			
			$cek = Calendar::model()->find("tgl_libur = to_date('$recording_date_bursa','yyyy-mm-dd')");
			
			while ($cek){
				
				$recording_date_bursa = date('Y-m-d',strtotime("$recording_date_bursa +1 day"));
				$date_holiday = DateTime::createFromFormat('Y-m-d',$recording_date_bursa)->format('D');
			
			if($date_holiday =='Sat'){
				$recording_date_bursa = date('Y-m-d',strtotime("$recording_date_bursa +2 day"));
			}
			else if($date_holiday == 'Sun'){
				$recording_date_bursa = date('Y-m-d',strtotime("$recording_date_bursa +1 day"));
			}
			else if($date_holiday == 'Fri'){
				$recording_date_bursa = date('Y-m-d',strtotime("$recording_date_bursa +3 day"));
			}
				$cek = Calendar::model()->find("tgl_libur = to_date('$recording_date_bursa','yyyy-mm-dd')");
			}
			$date_bursa = $recording_date_bursa;
	}
	
	if(DateTime::createFromFormat('d/m/Y',$date_bursa))$date_bursa=DateTime::createFromFormat('d/m/Y',$date_bursa)->format('Y-m-d');
	return $date_bursa;
			
	}

}
?>