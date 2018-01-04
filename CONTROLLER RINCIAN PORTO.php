<?php

class RincianportoController extends AAdminController
{
	
	public $layout='//layouts/admin_column3';
	
	
		public function actionIndex()
	{
		$model=new Vlaprincianportoindex('search');
		$model->unsetAttributes();  // clear any default values
		
		$model->approved_stat = 'A';

		if(isset($_GET['Vlaprincianportoindex']))
			$model->attributes=$_GET['Vlaprincianportoindex'];

		$this->render('index',array(
			'model'=>$model,
		));
	}
	
	
	
	public function actionPrint(){
		
		
	}
	
	public function actionSaveText(){
		
		
	}
	
	
	public function actionGenerate(){

		$model=new Rptrincianporto('LAP_RINCIAN_PORTO','Lap_rincian_porto','Lap_rincian_porto.rptdesign');
		$url='';
		$model->date_now =Yii::app()->request->cookies['porto_date']?Yii::app()->request->cookies['porto_date']->value:$model->date_now = date('d/m/Y');;
		
		
		$success=false;
		if(isset($_POST['scenario']))
		{
			$scenario = $_POST['scenario'];
			$model->attributes = $_POST['Rptrincianporto'];
			if(DateTime::createFromFormat('d/m/Y',$model->date_now))$model->date_now=DateTime::createFromFormat('d/m/Y',$model->date_now)->format('Y-m-d');
			$ip = Yii::app()->request->userHostAddress;
			if($ip=="::1")
				$ip = '127.0.0.1';
			$model->ip_address =$ip;
			$model->broker = 'YJ';
			
			if($model->validate())
			{
				
				if($scenario == 'generate')//generate
				{
					
				Yii::app()->request->cookies['porto_date'] = new CHttpCookie('porto_date', DateTime::createFromFormat('Y-m-d',$model->date_now)->format('d/m/Y'));
				
			//cek pending report
			$sql="SELECT * FROM (SELECT 
				(SELECT to_date(FIELD_VALUE,'yyyy/mm/dd hh24:mi:ss') FROM T_MANY_DETAIL DA 
		        WHERE DA.TABLE_NAME = 'LAP_RINCIAN_PORTO' 
		        AND DA.UPDATE_DATE = DD.UPDATE_DATE
		        AND DA.UPDATE_SEQ = DD.UPDATE_SEQ
		        AND DA.FIELD_NAME = 'REPORT_DATE'
		        AND DA.RECORD_SEQ = DD.RECORD_SEQ) REPORT_DATE, 
				HH.APPROVED_STATUS,HH.MENU_NAME
				FROM T_MANY_DETAIL DD, T_MANY_HEADER HH WHERE DD.TABLE_NAME = 'LAP_RINCIAN_PORTO' AND DD.UPDATE_DATE = HH.UPDATE_DATE
		          AND DD.UPDATE_SEQ = HH.UPDATE_SEQ AND DD.RECORD_SEQ = 1 
		          AND DD.FIELD_NAME = 'REPORT_DATE' AND HH.APPROVED_STATUS = 'E')
          
          where REPORT_date = '$model->date_now'
          ";
		  
		  $cek=DAO::queryAllSql($sql);
		  if($cek){
		  		Yii::app()->user->setFlash('danger', 'Masih ada belum diapprove');	
			
		  }
		  else{
					$model->bgn_dt = DateTime::createFromFormat('Y-m-d',$model->date_now)->format('Y-m-01');	
					$cek = Tcontracts::model()->find("	contr_dt between to_date('$model->date_now','yyyy-mm-dd') -20 and to_date('$model->date_now','yyyy-mm-dd')		
														and contr_stat <> 'C'		
														and due_dt_for_amt <= to_date('$model->date_now','yyyy-mm-dd')		
														and nvl(sett_qty,0) < qty");
					
					$cek2 = Tbondtrx::model()->find("trx_date between  to_date('$model->date_now','yyyy-mm-dd') -20 and  to_date('$model->date_now','yyyy-mm-dd')			
														and approved_sts = 'A'			
														and value_dt <=  to_date('$model->date_now','yyyy-mm-dd')	
														and doc_num is not null		
														and nvl(settle_secu_flg,'N') = 'N'	");
														
					$cek3 = Sysparam::model()->find("param_id='RINCIAN PORTO' and param_cd1='START' ")->ddate1;		
					if(DateTime::createFromFormat('Y-m-d H:i:s',$cek3))$cek3 = DateTime::createFromFormat('Y-m-d H:i:s',$cek3)->format('Y-m-d');							
					if($cek){
						$date = DateTime::createFromFormat('Y-m-d',$model->date_now)->format('d M Y');
							Yii::app()->user->setFlash('danger', "Masih ada yang belum di settle pada tanggal ".$date);
					}
					else if($cek2){
						$date = DateTime::createFromFormat('Y-m-d',$model->date_now)->format('d M Y');
							Yii::app()->user->setFlash('danger', "Bond Transaction belum disettle, batal generate report pada tanggal ".$date);
					}
					else if($model->date_now < $cek3)
					{
							$date = DateTime::createFromFormat('Y-m-d',$model->date_now)->format('d M Y');
								Yii::app()->user->setFlash('danger', "Batal generate report pada tanggal ".$date.", gunakan system lama untuk tanggal tahun lalu");
					}
					else
					{
					//delete data lama di tanggal yang sama	
					$sql ="DELETE FROM insistpro_rpt.LAP_RINCIAN_PORTO WHERE report_date = '$model->date_now' ";
					$delete=DAO::executeSql($sql);
					
					if($model->validate() && $model->executeSpHeader(AConstant::INBOX_STAT_INS, 'LAPORAN RINCIAN PORTOFORLIO')>0){
						$success =TRUE;
					}
					else
					{
						$success =FALSE;
					}
					
					//memasukkan tanggal ke t_many_detail
					if($success && $model->executeSpIns(AConstant::INBOX_STAT_INS, 1)>0){
						$success=true;
					}
					else{
						
						$success=false;
					}
				
				
					//generate report ke tabel report
					if($success && $model->executeSpRpt()>0)
					{
						$success =TRUE;
					}
					else{
						$success = FALSE;
					}
					
					}
					
					
					if($success)
					{
					Yii::app()->user->setFlash('success', 'Successfully generate report ');
					}
					}//end validasi
				}
				else if($scenario =='print')//print
				{
					$model->trx_date = $model->date_now;
					$model->approved_stat = 'A';
					$url = $model->showReport2();	
					
				}//end print
				/*
				else if($scenario =='export')
								{
									
									$this->CreateExcel($model->date_now);
								}
								*/
				
			else//save to text file
			{
				
				//find data
				$jumlah_acct = Vlaprincianporto::model()->find("report_date ='$model->date_now' and approved_stat='A' ")->jumlah_acct;
				$sql="sELECT STK_CD||'|'||case when instr(price,'.')>1 then trim(to_char(PRICE,9999999999999999990.9999))
    			    else to_char(price) end||'|'||port001||'|'||port002||'|'||port004||'|'||
				      CLIENT001||'|'||client002||'|'||client004||'|'||SUBREK_QTY
					 AS TEXT
					from v_lap_rincian_porto where report_date='$model->date_now' and approved_stat='A' and rep_type=1 order by stk_cd ";
				$text =Vlaprincianporto::model()->findAllBySql($sql);
				$sql2="SELECT STK_CD||'|'||decode(substr(stk_cd,1,3),'IDN',trim(to_char(PRICE,9999999999999999990.9999)),PRICE)||'|'||port001||'|'||port002||'|'||
				decode(substr(stk_cd,1,3),'IDN',trim(to_char(PORT004,99999999999999999999999999990.9999)),port004)||'|'||
        		client001
					 AS TEXT2
					from v_lap_rincian_porto where report_date='$model->date_now' and approved_stat='A' and rep_type=2 order by stk_cd";
				$text2 =Vlaprincianporto::model()->findAllBySql($sql2);
				
				$nama_ab = Company::model()->find()->nama_prsh;
				$kode_ab = Parameter::model()->find(" PRM_CD_1 = 'AB' AND PRM_CD_2='000' AND APPROVED_STAT='A'")->prm_desc;
				$kode_ab = strtolower(substr($kode_ab, 0,2));
				$date = DateTime::createFromFormat('Y-m-d',$model->date_now)->format('Ymd');
				$file = fopen("upload/rincian_porto/YJ-$date.POR","w");
				fwrite($file, "LAPORAN RINCIAN PORTOFOLIO\r\n");
				fwrite($file, "$nama_ab\r\n");
				fwrite($file, "$kode_ab\r\n");
				fwrite($file, "$date\r\n");
				fwrite($file, "$jumlah_acct\r\n");
				
				foreach($text as $row)
				{
				fwrite($file, "$row->text\r\n");	
				}
				fwrite($file, "EFEK WARKAT DAN KUSTODIAN LAIN\r\n");
				foreach($text2 as $row)
				{
				fwrite($file, "$row->text2\r\n");	
				}
				fclose($file);
				
				//DOWNLOAD FILE LTH
				$filename = "upload/rincian_porto/YJ-$date.POR";
				header("Cache-Control: public");
				header("Content-Description: File Transfer");
				header("Content-Length: ". filesize("$filename").";");
				header("Content-Disposition: attachment; filename=YJ-$date.POR");
				header("Content-Type: application/octet-stream; "); 
				header("Content-Transfer-Encoding: binary");
				ob_clean();
		        flush();
				readfile($filename);
				unlink("upload/rincian_porto/YJ-$date.POR");
				exit;
				//DELETE FILE AFTER DOWNLOAD	
			}		
			}
		}
		if(DateTime::createFromFormat('Y-m-d',$model->date_now))$model->date_now=DateTime::createFromFormat('Y-m-d',$model->date_now)->format('d/m/Y');
		$this->render('_generate',array('model'=>$model,
									'url'=>$url));
	}
	
	public function actioncekDate(){
		$resp['status'] ='error';
			
		if(isset($_POST['tanggal']))
		{
			
			$tanggal=$_POST['tanggal'];
			$user_id=Yii::app()->user->id;
			if(DateTime::createFromFormat('d/m/Y',$tanggal))$tanggal=DateTime::createFromFormat('d/m/Y',$tanggal)->format('Y-m-d');
			$cek = Vlaprincianporto::model()->find("report_date = to_date('$tanggal','yyyy-mm-dd') and approved_stat='A' ");
				
				
			if($cek)
			{
				$resp['status']='success';	
			}
		}
		echo json_encode($resp);
	}
/*
 
public function CreateExcel($tanggal){
  //Yii::import('ext.phpexcel.XPHPExcel');    
      $objPHPExcel= XPHPExcel::createPHPExcel();
      $objPHPExcel->getProperties()->setCreator("SSS")
                             ->setLastModifiedBy("SSS")
                             ->setTitle("Laporan Rincian Portofolio")
                             ->setSubject("Office 2007 XLSX Test Document")
                             ->setDescription("Test document for Office 2007 XLSX, generated using PHP classes.")
                             ->setKeywords("office 2007 openxml php")
                             ->setCategory("Portofolio");
 //	$objPHPExcel->getDefaultStyle()->getFont()->setBold(TRUE);

 
 //get data from DB
$nama_ab = Company::model()->find()->nama_prsh;
$kode_ab = Parameter::model()->find(" PRM_CD_1 = 'AB' AND PRM_CD_2='000' AND APPROVED_STAT='A'")->prm_desc;
$kode_ab = substr($kode_ab, 0,2);
$date = DateTime::createFromFormat('Y-m-d',$tanggal)->format('d-M-Y');
$jumlah_acct = Vlaprincianporto::model()->find("report_date = to_date('$tanggal','yyyy-mm-dd') and approved_stat='A' ")->jumlah_acct;
 
 
// Add some data
 $objPHPExcel->getActiveSheet()->mergeCells('A1:J1');
 $objPHPExcel->getActiveSheet()->mergeCells('A2:C2');
 $objPHPExcel->getActiveSheet()->mergeCells('A3:C3');
 $objPHPExcel->getActiveSheet()->mergeCells('A4:C4');
 $objPHPExcel->getActiveSheet()->mergeCells('A5:C5');
 $objPHPExcel->getActiveSheet()->mergeCells('D2:J2');
 $objPHPExcel->getActiveSheet()->mergeCells('D3:J3');
 $objPHPExcel->getActiveSheet()->mergeCells('D4:J4');
 $objPHPExcel->getActiveSheet()->mergeCells('D5:J5');

$objPHPExcel->setActiveSheetIndex(0)
 			->setCellValue("A1", 'LAPORAN RINCIAN PORTOFOLIO')
			->setCellValue("A2", 'Nama Anggota Bursa Effek')
			->setCellValue("A3", 'Kode Anggota Bursa Efek')
			->setCellValue("A4", 'Tanggal Pelaporan')
			->setCellValue("A5", 'Jumlah on Account di KSEI')
			->setCellValue("D2", $nama_ab)
			->setCellValue("D3", $kode_ab)
			->setCellValue("D4", $date)
			->setCellValue("D5", $jumlah_acct)
			;
//$objPHPExcel->getActiveSheet()->getStyle('A1:J5')->getAlignment()->setVertical(PHPExcel_Style_Alignment::VERTICAL_TOP);
$objPHPExcel->getActiveSheet()->getStyle('A1:J5')->getAlignment()->setHorizontal(PHPExcel_Style_Alignment::HORIZONTAL_LEFT);
$objPHPExcel->getActiveSheet()->getStyle('A7:J7')->getAlignment()->setHorizontal(PHPExcel_Style_Alignment::HORIZONTAL_CENTER);
//$objPHPExcel->getActiveSheet()->getStyle('A7:J7')->getFont()->getBold(TRUE);
$styleArray = array(
	'font' => array(
		'bold' => true,
	));
	$objPHPExcel->getActiveSheet()->getStyle('A1:J8')->applyFromArray($styleArray);
	
	
			
 $objPHPExcel->getActiveSheet()->mergeCells('D7:E7');
 $objPHPExcel->getActiveSheet()->mergeCells('G7:H7');
 $objPHPExcel->setActiveSheetIndex(0)
 				->setCellValue("D7", 'Portofolio (Unit)')
				->setCellValue("G7", 'Nasabah (Unit)');
$objPHPExcel->setActiveSheetIndex(0)
 			->setCellValue("A8", 'No')
          	->setCellValue("B8", 'Stk Cd')
			->setCellValue("C8", 'Price')
			->setCellValue("D8", 'Rek 001')
			->setCellValue("E8", 'Rek 002')
			->setCellValue("F8", 'Rek 004')
			->setCellValue("G8", 'Rek 001')
			->setCellValue("H8", 'Rek 002')
			->setCellValue("I8", 'Rek 004')
			->setCellValue("J8", 'Sub account nasabah');

$data = Vlaprincianporto::model()->findAll(array('select'=>'*','condition'=>"approved_stat='A' and report_date=to_date('$tanggal','yyyy-mm-dd') and rep_type=1",'order'=>'stk_cd'));
$data2 = Vlaprincianporto::model()->findAll(array('select'=>'*','condition'=>"approved_stat='A' and report_date=to_date('$tanggal','yyyy-mm-dd') and rep_type=2",'order'=>'stk_cd'));
$x=9;
foreach($data as $row){
	//WRITE DATA
	$objPHPExcel->setActiveSheetIndex(0)->setCellValue("A$x", $x-7);
	$objPHPExcel->setActiveSheetIndex(0)->setCellValue("B$x", $row->stk_cd);
	$objPHPExcel->setActiveSheetIndex(0)->setCellValue("C$x", $row->price);
	$objPHPExcel->setActiveSheetIndex(0)->setCellValue("D$x", $row->port001);
	$objPHPExcel->setActiveSheetIndex(0)->setCellValue("E$x", $row->port002);
	$objPHPExcel->setActiveSheetIndex(0)->setCellValue("F$x", $row->port004);
	$objPHPExcel->setActiveSheetIndex(0)->setCellValue("G$x", $row->client001);
	$objPHPExcel->setActiveSheetIndex(0)->setCellValue("H$x", $row->client002);
	$objPHPExcel->setActiveSheetIndex(0)->setCellValue("I$x", $row->client004);
	$objPHPExcel->setActiveSheetIndex(0)->setCellValue("J$x", $row->subrek_qty);
$x++;	
}

$x = $x+1;
//SET HEADER SECOND TABLE
for($y=0;$y<5;$y++)
{
	$objPHPExcel->getActiveSheet()->getStyle("A$x:J$x")->applyFromArray($styleArray);
	$objPHPExcel->getActiveSheet()->getStyle("A$x:J$x")->getAlignment()->setHorizontal(PHPExcel_Style_Alignment::HORIZONTAL_LEFT);
	
	if($y ==0){
	$objPHPExcel->getActiveSheet()->mergeCells("A$x:J$x");
		$objPHPExcel->setActiveSheetIndex(0)->setCellValue("A$x", 'LAPORAN RINCIAN PORTOFOLIO');
	}
	else{
	$objPHPExcel->getActiveSheet()->mergeCells("A$x:C$x");	
	$objPHPExcel->getActiveSheet()->mergeCells("D$x:J$x");
	if($y==1)
	{
		$objPHPExcel->setActiveSheetIndex(0)->setCellValue("A$x", 'Nama Anggota Bursa Effek');
		$objPHPExcel->setActiveSheetIndex(0)->setCellValue("D$x", $nama_ab);
	}
	else if($y==2)
	{
		$objPHPExcel->setActiveSheetIndex(0)->setCellValue("A$x",  'Kode Anggota Bursa Efek');
		$objPHPExcel->setActiveSheetIndex(0)->setCellValue("D$x", $kode_ab);
	}
	else if($y==3)
	{
		$objPHPExcel->setActiveSheetIndex(0)->setCellValue("A$x",  'Tanggal Pelaporan');
		$objPHPExcel->setActiveSheetIndex(0)->setCellValue("D$x", $date);
	}
	else if($y==4)
	{
		$objPHPExcel->setActiveSheetIndex(0)->setCellValue("A$x",  'Jumlah on Account di KSEI');
		$objPHPExcel->setActiveSheetIndex(0)->setCellValue("D$x", $jumlah_acct);
	}
	
	}
$x++;	
}
$x=$x+1;

$objPHPExcel->getActiveSheet()->getStyle("A$x:J$x")->applyFromArray($styleArray);
$objPHPExcel->getActiveSheet()->getStyle("A$x:J$x")->getAlignment()->setHorizontal(PHPExcel_Style_Alignment::HORIZONTAL_CENTER);
 $objPHPExcel->getActiveSheet()->mergeCells("C$x:D$x");
 $objPHPExcel->getActiveSheet()->mergeCells("F$x:G$x");
 $objPHPExcel->setActiveSheetIndex(0)->setCellValue("C$x","Warkat");
 $objPHPExcel->setActiveSheetIndex(0)->setCellValue("F$x","Kustodian Lain");
 $x=$x+1;
 $objPHPExcel->getActiveSheet()->getStyle("A$x:J$x")->applyFromArray($styleArray);
$objPHPExcel->setActiveSheetIndex(0)
 			->setCellValue("A$x", 'No')
			->setCellValue("B$x", 'Stk Cd')
			->setCellValue("C$x", 'Price')
			->setCellValue("D$x", 'Portofolio')
			->setCellValue("E$x", 'Nasabah')
			->setCellValue("F$x", 'Portofolio')
			->setCellValue("G$x", 'Nasabah');
$x=$x+1;
$num = 1;
foreach($data2 as $row){
	
	
	if(substr($row->stk_cd,0,3) =='IDN'){
		//FORMAT NUMBER
		$objPHPExcel->getActiveSheet()->getStyle("C$x")->getNumberFormat()->setFormatCode('#,##0.0000');
		$objPHPExcel->getActiveSheet()->getStyle("G$x")->getNumberFormat()->setFormatCode('#,##0.0000');
	}
	//WRITE DATA
	$objPHPExcel->setActiveSheetIndex(0)->setCellValue("A$x", $num);
	$objPHPExcel->setActiveSheetIndex(0)->setCellValue("B$x", $row->stk_cd);
	$objPHPExcel->setActiveSheetIndex(0)->setCellValue("C$x", $row->price);
	$objPHPExcel->setActiveSheetIndex(0)->setCellValue("D$x", $row->port001);
	$objPHPExcel->setActiveSheetIndex(0)->setCellValue("E$x", $row->port002);
	$objPHPExcel->setActiveSheetIndex(0)->setCellValue("F$x", $row->client001);
	$objPHPExcel->setActiveSheetIndex(0)->setCellValue("G$x", $row->port004);
$x++;	
$num++;
}





// Rename worksheet
$objPHPExcel->getActiveSheet()->setTitle('Rincian Portofolio');
 
 
// Set active sheet index to the first sheet, so Excel opens this as the first sheet
$objPHPExcel->setActiveSheetIndex(0);
// Redirect output to a clientÃ¢â‚¬â„¢s web browser (Excel5)
header('Content-Type: application/vnd.ms-excel');
header('Content-Disposition: attachment;filename="RincianPortofolio.xls"');
header('Cache-Control: max-age=0');
// If you're serving to IE 9, then the following may be needed
header('Cache-Control: max-age=1');
 
// If you're serving to IE over SSL, then the following may be needed
header ('Expires: Mon, 26 Jul 1997 05:00:00 GMT'); // Date in the past
header ('Last-Modified: '.gmdate('D, d M Y H:i:s').' GMT'); // always modified
header ('Cache-Control: cache, must-revalidate'); // HTTP/1.1
header ('Pragma: public'); // HTTP/1.0
 
$objWriter = PHPExcel_IOFactory::createWriter($objPHPExcel, 'Excel5');
$objWriter->save('php://output');
      Yii::app()->end();
}*/


	
}
