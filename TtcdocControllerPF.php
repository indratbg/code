<?php

class TtcdocController extends AAdminController
{
	public function genTCeng($client_cd, $tc_date, $rem_cd, $branch_code, $user_id){
		$model = Rtradeconf::model()->findAll(array('condition'=>"to_char(contr_dt,'YYYY-MM-DD HH24:MI:SS') = '$tc_date' and client_cd like '$client_cd' 
				and rem_cd like '$rem_cd' and branch_code like '$branch_code' and userid = '$user_id'",'order'=>'beli_jual, stk_cd'));
		$baseurl = Yii::app()->request->baseUrl;
		
		//var_dump($tc_date);
		//die();
		if($model){
			$tc = "
			<div>
				<div style=\"float: left; width: 60%;\">
					<h4>PT. DANASAKTI SECURITIES</h4>
					".$model[0]->brch_addr_1."<br />".$model[0]->brch_addr_2."<br/>
					".$model[0]->brch_addr_3."<br/>
					Telp : ".$model[0]->brch_phone."&emsp;Fax : ".$model[0]->brch_fax.($model[0]->dealing_phone?" Dealing : ".$model[0]->dealing_phone:'')."<br />
					NPWP&emsp;: &nbsp; ".$model[0]->no_ijin1."<br />
					<br />
					<table style='margin-left:-2%;line-height:1%;margin-top:-3%;' >
						<tr>
							<td width=\"40px\">ATT.</td>
							<td>: ".$model[0]->contact_pers."</td>
						</tr>
						<tr>
							<td></td>
							<td>&nbsp; ".$model[0]->def_addr_1."</td>
						</tr>
						<tr>
							<td></td>
							<td>&nbsp; ".$model[0]->def_addr_2."</td>
						</tr>
						<tr>
							<td></td>
							<td>&nbsp; ".$model[0]->def_addr_3."</td>
						</tr>
						<tr>
							<td>ZIP</td>
							<td>: ".$model[0]->post_cd."</td>
						</tr>
					</table>
					
				</div>
				<div style=\"float: right; width: 40%;\">
					
				<table style='margin-left:-5%;line-height:1%;' >
					<tr>
						<td colspan='3'><h4>TRADE CONFIRMATION</h4></td>
					</tr>
					<tr>
						<td width='100px' >Trade Date</td>
						<td  colspan='2' >: ".DateTime::createFromFormat('Y-m-d h:i:s',$model[0]->contr_dt)->format('d/m/Y')."</td>
					</tr>
					<tr>
						<td width='100px' >Settle Date</td>
						<td  colspan='2' >: ".DateTime::createFromFormat('Y-m-d h:i:s',$model[0]->due_dt_for_amt)->format('d/m/Y')."</td>
					</tr>
					<tr>
						<td width='100px' >Ref No.</td>
						<td  colspan='2' style='font-weight:bold'>: {tc_id}</td>
					</tr>
				</table>
				<br />
					
				<table style='margin-left:-5%;line-height:1%;' >
					<tr>
						<td colspan='2'>".($model[0]->client_title? ucwords(strtolower($model[0]->client_title)).'. ' : '').$model[0]->client_name."</td>
					</tr>
					<tr>
						<td>Client code</td>
						<td>: ".$model[0]->old_ic_num."&emsp; /".$model[0]->client_cd."</td>
					</tr>
					
					<tr>
						<td>Phone</td>
						<td>: ".(($model[0]->phone_num && (trim($model[0]->phone_num) != 'NA'))?$model[0]->phone_num : '').($model[0]->phone2_1?', '.$model[0]->phone2_1 : '').($model[0]->hand_phone1?', '.$model[0]->hand_phone1 : '');
						 	$tc=$tc." 
						</td>
					</tr>
					<tr>
						<td>Fax</td><td> : "; if($model[0]->fax_num){$tc = $tc.$model[0]->fax_num ; }$tc=$tc."</td>
					</tr>
					<tr>
						<td colspan='2'>";if($model[0]->e_mail1){$tc = $tc.$model[0]->e_mail1;}$tc = $tc."</td>
					</tr>
					<tr><td></td><td></td></tr>
				</table>
				
				
				";
				
			$tc = $tc."	
			
			</div>
			<br style=\"clear: both;\" />
			<div style=\"margin-top:-30px;\">
					As instructed, we have executed the following transaction(s) for your account:
					<table id=\"tc-table\" class=\"table-condensed\" style=\"border-collapse: collapse; border: none;\">
						<tr style=\"border-top: 1.5px solid;border-bottom: 1.5px solid;\">
							<td><strong>Share</strong></td>
							<td></td>
							<td></td>
							<td style=\"text-align: right;\"><strong>Quantity</strong></td>
							<td style=\"text-align: right;\"><strong>Price</strong></td>
							<td colspan=\"2\" style=\"text-align: right;\"><strong>Amount Buy</strong></td>
							<td colspan=\"2\" style=\"text-align: right;\"><strong>Amount Sell</strong></td>
						</tr>
						";
			foreach ($model as $row){
				$tc = $tc."
								<tr>
									<td>".$row->stk_cd."</td>
									<td colspan='2'>".$row->stk_name."</td>
									
									<td style=\"text-align: right;\">".number_format($row->qty)."</td>
									<td style=\"text-align: right;\">".number_format($row->price)."</td>
									<td style=\"width: 5%\"></td>
									<td style=\"text-align: right; width: 16%\">".number_format($row->b_val)."</td>
									<td style=\"width: 5%\"></td>
									<td style=\"text-align: right; width: 16%\">".number_format($row->j_val)."</td>
								</tr>";
			}
			$tc = $tc."
							<tr style=\"border-top: 1.5px solid;\">
								<td colspan=\"5\">Total Value</td>
								<td style=\"text-align: right;\"><strong>Rp</strong></td>
								<td style=\"text-align: right;font-weight:bold;\">".number_format($model[0]->sum_b_val)."</td>
								<td style=\"text-align: right;\"><strong>Rp</strong></td>
								<td style=\"text-align: right;font-weight:bold;\">".number_format($model[0]->sum_j_val)."</td>
							</tr>
							<tr>
								<td colspan=\"5\">Commission ".($model[0]->brok_perc/100)."%</td>
								<td style=\"text-align: right;\"></td>
								<td style=\"text-align: right;\">".number_format($model[0]->sum_b_comm)."</td>
								<td style=\"text-align: right;\"></td>
								<td style=\"text-align: right;\">".number_format($model[0]->sum_j_comm)."</td>
							</tr>
							<tr>
								<td colspan=\"5\">VAT</td>
								<td style=\"text-align: right;\"></td>
								<td style=\"text-align: right;\">".number_format($model[0]->sum_b_vat)."</td>
								<td style=\"text-align: right;\"></td>
								<td style=\"text-align: right;\">".number_format($model[0]->sum_j_vat)."</td>
							</tr>
							<tr>
								<td colspan=\"5\">Levy</td>
								<td style=\"text-align: right;\"></td>
								<td style=\"text-align: right;\">".number_format($model[0]->sum_b_levy)."</td>
								<td style=\"text-align: right;\"></td>
								<td style=\"text-align: right;\">".number_format($model[0]->sum_j_levy)."</td>
							</tr>";
			if ($model[0]->sum_j_pph != 0){
				$tc = $tc."
							<tr>
								<td colspan=\"5\">Sales Tax ".($model[0]->pph_perc/100)."%</td>
								<td style=\"text-align: right;\"></td>
								<td style=\"text-align: right;\">".number_format($model[0]->sum_b_pph)."</td>
								<td style=\"text-align: right;\"></td>
								<td style=\"text-align: right;\">".number_format($model[0]->sum_j_pph)."</td>
							</tr>";
			}
			if (($model[0]->sum_b_whpph23 != 0) || ($model[0]->sum_j_whpph23 != 0)){
				$tc = $tc."
							<tr>
								<td colspan=\"5\">Witholding Tax PPh 23 ".$model[0]->whpph23_perc."%</td>
								<td style=\"text-align: right;\"></td>
								<td style=\"text-align: right;\">".number_format($model[0]->sum_b_whpph23)."</td>
								<td style=\"text-align: right;\"></td>
								<td style=\"text-align: right;\">".number_format($model[0]->sum_j_whpph23)."</td>
							</tr>";
			}
			$tc = $tc."
							<tr style=\"border-top: 1.5px solid;border-bottom: 1.5px solid;\">
								<td colspan=\"5\">Total Net</td>
								<td style=\"text-align: right;\">Rp</td>
								<td style=\"text-align: right;\">".number_format($model[0]->sum_b_amt)."</td>
								<td style=\"text-align: right;\">Rp</td>
								<td style=\"text-align: right;\">".number_format($model[0]->sum_j_amt)."</td>
							</tr>
							<tr><td colspan=\"9\"></td></tr>";
			if ($model[0]->sum_b_amt > $model[0]->sum_j_amt){
				$tc = $tc."
							<tr style=\"border-bottom: 1.5px solid;\">
								<td colspan=\"5\"><strong>Payment due to us</strong></td>
								<td style=\"text-align: right;\"><strong>Rp</strong></td>
								<td style=\"text-align: right;font-weight:bold;\">".number_format($model[0]->sum_b_amt - $model[0]->sum_j_amt)."</td>
								<td style=\"text-align: right;\"></td>
								<td style=\"text-align: right;\"></td>
							</tr>";	
			}else{
				$tc = $tc."
							<tr style=\"border-bottom: 1.5px solid;\">
								<td colspan=\"5\"><strong>Payment due to you</strong></td>
								<td style=\"text-align: right;\"></td>
								<td style=\"text-align: right;font-weight:bold;\"></td>
								<td style=\"text-align: right;\"><strong>Rp</strong></td>
								<td style=\"text-align: right;font-weight:bold;\">".number_format($model[0]->sum_j_amt - $model[0]->sum_b_amt)."</td>
							</tr>";
			}
			/*
			if (($model[0]->sum_b_t3 + $model[0]->sum_j_t3) > 0){
				$tc = $tc."
							<tr>
								<td colspan=\"5\"><strong>Settlement Date T+".$model[0]->max_3plus."&emsp;".DateTime::createFromFormat('Y-m-d h:i:s',$model[0]->due_t3)->format('d/m/Y')." (".substr($model[0]->mrkt_t3,0,2).")</strong></td>
								<td style=\"text-align: right;\"><strong>Rp</strong></td>
								<td style=\"text-align: right;\"><strong>".(($model[0]->sum_b_t3 > $model[0]->sum_j_t3)?number_format($model[0]->sum_b_t3 - $model[0]->sum_j_t3) : '0')."</strong></td>
								<td style=\"text-align: right;\"></td>
								<td style=\"text-align: right;\"></td>
							</tr>";
			}
			if (($model[0]->sum_b_t2 + $model[0]->sum_j_t2) > 0){
				$tc = $tc."
							<tr>
								<td colspan=\"5\"><strong>Settlement Date T+2&emsp;".DateTime::createFromFormat('Y-m-d h:i:s',$model[0]->due_t2)->format('d/m/Y')." (".substr($model[0]->mrkt_t2,0,2).")</strong></td>
								<td style=\"text-align: right;\"><strong>Rp</strong></td>
								<td style=\"text-align: right;\"><strong>".(($model[0]->sum_b_t2 > $model[0]->sum_j_t2)?number_format($model[0]->sum_b_t2 - $model[0]->sum_j_t2) : '0')."</strong></td>
								<td style=\"text-align: right;\"></td>
								<td style=\"text-align: right;\"></td>
							</tr>";
			}
			if (($model[0]->sum_b_t1 + $model[0]->sum_j_t1) > 0){
				$tc = $tc."
							<tr>
								<td colspan=\"5\"><strong>Settlement Date T+1&emsp;".DateTime::createFromFormat('Y-m-d h:i:s',$model[0]->due_t1)->format('d/m/Y')." (".substr($model[0]->mrkt_t1,0,2).")</strong></td>
								<td style=\"text-align: right;\">Rp</td>
								<td style=\"text-align: right;\"><strong>".(($model[0]->sum_b_t1 > $model[0]->sum_j_t1)?number_format($model[0]->sum_b_t1 - $model[0]->sum_j_t1) : '0')."</strong></td>
								<td style=\"text-align: right;\"></td>
								<td style=\"text-align: right;\"></td>
							</tr>";
			}
			if (($model[0]->sum_b_t0 + $model[0]->sum_j_t0) > 0){
				$tc = $tc."
							<tr>
								<td colspan=\"5\">Settlement Date T+0&emsp;".DateTime::createFromFormat('Y-m-d h:i:s',$model[0]->contr_dt)->format('d/m/Y')." (".substr($model[0]->mrkt_t0,0,2).")</td>
								<td style=\"text-align: right;\"><strong>Rp</strong></td>
								<td style=\"text-align: right;\"><strong>".(($model[0]->sum_b_t0 > $model[0]->sum_j_t0)?number_format($model[0]->sum_b_t0 - $model[0]->sum_j_t0) : '0')."</strong></td>
								<td style=\"text-align: right;\"></td>
								<td style=\"text-align: right;\"></td>
							</tr>";
			}
			*/				
			$tc = $tc."
							<tr style=\"border-top: 1.5px solid;\"><td colspan=\"9\"></td></tr>
						
					</table>
			</div>
		
		
			<div style=\"clear: both; \"></div>
			<div>";
			$due_date = $model[0]->due_dt_for_amt;
			$sql = "Select GET_DUE_DATE(1, '$due_date') due_date from dual";
			$date = DAO::queryRowSql($sql);
			$due_date = $date['due_date'];
				//if($model[0]->bank_rdi_acct){
							if($model[0]->sum_b_amt > $model[0]->sum_j_amt){
								$tc = $tc."
									PLEASE TRANSFER THE FUND TO : CIMB NIAGA<br />
									<strong>INVESTOR ACCOUNT : ".$model[0]->client_name.", A/C ".$model[0]->bank_rdi_acct."<br />
									-->EFFECTIVE THE LATEST ON THE SETTLEMENT DATE (IN GOOD FUND AT 10:00 AM)</strong><br />
									PLEASE FAX THE TRANSFER SLIP TO 231-4880<br/>";	
							}
							if($model[0]->sum_j_amt > $model[0]->sum_b_amt){
								$tc = $tc."
									We will transfer to your Bank account for amount below :<br />"
									.DateTime::createFromFormat('Y-m-d H:i:s',$model[0]->due_dt_for_amt)->format('d/m/Y')."&emsp; if your bank account in CIMB NIAGA<br />"
								.DateTime::createFromFormat('Y-m-d H:i:s',$due_date)->format('d/m/Y')."&emsp; if your bank account in Other Bank <br /><br />";
							}
							
							
				//}
				/*
				else{
					$tc = $tc."
							<font style=\"text-decoration: underline;\">The following is our payment bank details</font><br />
							".$model[0]->nama_prsh."<br />
							".$model[0]->bank_name." A/C : ".$model[0]->brch_acct_num."<br/>";
				}
				*/
				$contract_dept = Sysparam::model()->find("param_id='TRADE CONFIRMATION' and param_Cd1='CON_DEPT'")->dstr1;
				$tc = $tc."
				- This statement will be considered correct if no discrepancies are reported within 24 hours.<br /><br />
				- This report is generated by system,for report sent by e-mail no signature required.<br />
			</div>
			<div style=\"clear: both; \"><br /><br /><br />
			
			<div>
				<div style=\"float: left; width: 30%;\">
					<p>Best Regards</p><br /><br />
					(".$contract_dept.")<br />
					Contract Dept 
					<br /><br />
					
				</div>
					<div style=\"float: left; width: 30%;\">
					<p>&emsp;</p><br /><br /> (".$model[0]->rem_name.")<br />
					Sales
					</div>
				<div style=\"float: right; width: 40%;\">
					<p align='center'>Reconfirmed By</p><br /><br />
					<p align='center'>(".$model[0]->client_name.")</p>
				</div>
			</div>
			
			<div style=\"float: left; width: 50%;\">
			<div style=\"float: left; width: 12%;\">
			<p align=\"justify\" style=\"padding-right:10px;font-size:8pt;line-height:120%\">Note :</p>
				</div>
				<div style=\"float: left; width: 88%;\">
					<p align=\"justify\" style=\"padding-right:10px;font-size:8pt;line-height:120%\">
							In connection with Rule No. V.D.10 concerning Know Your
							Customer (KYC) as issued by Capital Market and Financial
							Institution Supervisory Agency (Badan Pengawas Pasar Modal dan
							Lembaga Keuangan) ,you are kindly requested to<br /><br />
							immediately provide update on every changes and/or renewal of data
							and/or documents by contacting our Customer Relation Officer.
					</p>
				</div>
			</div>
			<div style=\"float: left; width: 50%;\">
				<div style=\"float: left; width: 3%;\">
				*
				</div>
				<div style=\"float: left; width: 97%;\">
				 <p align=\"justify\" style=\"font-size:8pt;line-height:120%;padding-right:30px;\">
					Sehubungan dengan Peraturan Badan Pengawas Pasar Modal dan
					Lembaga Keuangan No. V.D.10 tentang Prinsip Mengenal Nasabah
					(KYC), Anda dimohon dengan hormat untuk segera melakukan
					pengkinian data atas setiap perubahan dan/atau<br /><br />
					pembaharuan data dan/atau dokumen dengan menghubungi
					Customer Relation Officer kami.
				</p>
				</div>
			</div>
			<div style=\"clear: both; \"></div>
			";
		}else{
			$tc = "<h1>Data Not Found!</h1>";
		}
		
		return $tc;

	}

	public function genTCengmatrix($client_cd, $tc_date, $rem_cd, $branch_code, $user_id){
		$model = Rtradeconf::model()->findAll(array('condition'=>"to_char(contr_dt,'YYYY-MM-DD HH24:MI:SS') = '$tc_date' and client_cd like '$client_cd' 
				and rem_cd like '$rem_cd' and branch_code like '$branch_code' and userid = '$user_id'",'order'=>'beli_jual, stk_cd'));
		$baseurl = Yii::app()->request->baseUrl;
		if($model){
			$tc = "
			<div>
				<div style=\"float: left; width: 60%;\">
					<h4>PT. DANASAKTI SECURITIES</h4>
					".$model[0]->brch_addr_1."<br />".$model[0]->brch_addr_2."<br/>
					".$model[0]->brch_addr_3."<br/>
					Telp : ".$model[0]->brch_phone."&emsp;Fax : ".$model[0]->brch_fax.($model[0]->dealing_phone?" Dealing : ".$model[0]->dealing_phone:'')."<br />
					NPWP&emsp;: &nbsp; ".$model[0]->no_ijin1."<br />
					<br />
					<table style='margin-left:-2%;line-height:1%;margin-top:-3%;' >
						<tr>
							<td width=\"40px\">ATT.</td>
							<td>: ".$model[0]->contact_pers."</td>
						</tr>
						<tr>
							<td></td>
							<td>&nbsp; ".$model[0]->def_addr_1."</td>
						</tr>
						<tr>
							<td></td>
							<td>&nbsp; ".$model[0]->def_addr_2."</td>
						</tr>
						<tr>
							<td></td>
							<td>&nbsp; ".$model[0]->def_addr_3."</td>
						</tr>
						<tr>
							<td>ZIP</td>
							<td>: ".$model[0]->post_cd."</td>
						</tr>
					</table>
					
				</div>
				<div style=\"float: right; width: 40%;\">
					
				<table style='margin-left:-5%;line-height:1%;' >
					<tr>
						<td colspan='3'><h4>TRADE CONFIRMATION</h4></td>
					</tr>
					<tr>
						<td width='100px' >Trade Date</td>
						<td  colspan='2' >: ".DateTime::createFromFormat('Y-m-d h:i:s',$model[0]->contr_dt)->format('d/m/Y')."</td>
					</tr>
					<tr>
						<td width='100px' >Settle Date</td>
						<td  colspan='2' >: ".DateTime::createFromFormat('Y-m-d h:i:s',$model[0]->due_dt_for_amt)->format('d/m/Y')."</td>
					</tr>
					<tr>
						<td width='100px' >Ref No.</td>
						<td  colspan='2' style='font-weight:bold'>: {tc_id}</td>
					</tr>
				</table>
				<br />
					
				<table style='margin-left:-5%;line-height:1%;' >
					<tr>
						<td colspan='2'>".($model[0]->client_title? ucwords(strtolower($model[0]->client_title)).'. ' : '').$model[0]->client_name."</td>
					</tr>
					<tr>
						<td>Client code</td>
						<td>: ".$model[0]->old_ic_num."&emsp; /".$model[0]->client_cd."</td>
					</tr>
					
					<tr>
						<td>Phone</td>
						<td>: ".(($model[0]->phone_num && (trim($model[0]->phone_num) != 'NA'))?$model[0]->phone_num : '').($model[0]->phone2_1?', '.$model[0]->phone2_1 : '').($model[0]->hand_phone1?', '.$model[0]->hand_phone1 : '');
						 	$tc=$tc." 
						</td>
					</tr>
					<tr>
						<td>Fax</td><td> : "; if($model[0]->fax_num){$tc = $tc.$model[0]->fax_num ; }$tc=$tc."</td>
					</tr>
					<tr>
						<td colspan='2'>";if($model[0]->e_mail1){$tc = $tc.$model[0]->e_mail1;}$tc = $tc."</td>
					</tr>
					<tr><td></td><td></td></tr>
				</table>
				
				
				";
				
			$tc = $tc."	
			
			</div>
			<br style=\"clear: both;\" />
			<div style=\"margin-top:-30px;\">
					As instructed, we have executed the following transaction(s) for your account:
					<table id=\"tc-table\" class=\"table-condensed\" style=\"border-collapse: collapse; border: none;\">
						<tr style=\"border-top: 1.5px solid;border-bottom: 1.5px solid;\">
							<td><strong>Share</strong></td>
							<td></td>
							<td></td>
							<td style=\"text-align: right;\"><strong>Quantity</strong></td>
							<td style=\"text-align: right;\"><strong>Price</strong></td>
							<td colspan=\"2\" style=\"text-align: right;\"><strong>Amount Buy</strong></td>
							<td colspan=\"2\" style=\"text-align: right;\"><strong>Amount Sell</strong></td>
						</tr>
						";
			foreach ($model as $row){
				$tc = $tc."
								<tr>
									<td>".$row->stk_cd."</td>
									<td colspan='2'>".$row->stk_name."</td>
									
									<td style=\"text-align: right;\">".number_format($row->qty)."</td>
									<td style=\"text-align: right;\">".number_format($row->price)."</td>
									<td style=\"width: 5%\"></td>
									<td style=\"text-align: right; width: 16%\">".number_format($row->b_val)."</td>
									<td style=\"width: 5%\"></td>
									<td style=\"text-align: right; width: 16%\">".number_format($row->j_val)."</td>
								</tr>";
			}
			$tc = $tc."
							<tr style=\"border-top: 1.5px solid;\">
								<td colspan=\"5\">Total Value</td>
								<td style=\"text-align: right;\"><strong>Rp</strong></td>
								<td style=\"text-align: right;font-weight:bold;\">".number_format($model[0]->sum_b_val)."</td>
								<td style=\"text-align: right;\"><strong>Rp</strong></td>
								<td style=\"text-align: right;font-weight:bold;\">".number_format($model[0]->sum_j_val)."</td>
							</tr>
							<tr>
								<td colspan=\"5\">Commission ".($model[0]->brok_perc/100)."%</td>
								<td style=\"text-align: right;\"></td>
								<td style=\"text-align: right;\">".number_format($model[0]->sum_b_comm)."</td>
								<td style=\"text-align: right;\"></td>
								<td style=\"text-align: right;\">".number_format($model[0]->sum_j_comm)."</td>
							</tr>
							<tr>
								<td colspan=\"5\">VAT</td>
								<td style=\"text-align: right;\"></td>
								<td style=\"text-align: right;\">".number_format($model[0]->sum_b_vat)."</td>
								<td style=\"text-align: right;\"></td>
								<td style=\"text-align: right;\">".number_format($model[0]->sum_j_vat)."</td>
							</tr>
							<tr>
								<td colspan=\"5\">Levy</td>
								<td style=\"text-align: right;\"></td>
								<td style=\"text-align: right;\">".number_format($model[0]->sum_b_levy)."</td>
								<td style=\"text-align: right;\"></td>
								<td style=\"text-align: right;\">".number_format($model[0]->sum_j_levy)."</td>
							</tr>";
			if ($model[0]->sum_j_pph != 0){
				$tc = $tc."
							<tr>
								<td colspan=\"5\">Sales Tax ".($model[0]->pph_perc/100)."%</td>
								<td style=\"text-align: right;\"></td>
								<td style=\"text-align: right;\">".number_format($model[0]->sum_b_pph)."</td>
								<td style=\"text-align: right;\"></td>
								<td style=\"text-align: right;\">".number_format($model[0]->sum_j_pph)."</td>
							</tr>";
			}
			if (($model[0]->sum_b_whpph23 != 0) || ($model[0]->sum_j_whpph23 != 0)){
				$tc = $tc."
							<tr>
								<td colspan=\"5\">Witholding Tax PPh 23 ".$model[0]->whpph23_perc."%</td>
								<td style=\"text-align: right;\"></td>
								<td style=\"text-align: right;\">".number_format($model[0]->sum_b_whpph23)."</td>
								<td style=\"text-align: right;\"></td>
								<td style=\"text-align: right;\">".number_format($model[0]->sum_j_whpph23)."</td>
							</tr>";
			}
			$tc = $tc."
							<tr style=\"border-top: 1.5px solid;border-bottom: 1.5px solid;\">
								<td colspan=\"5\">Total Net</td>
								<td style=\"text-align: right;\">Rp</td>
								<td style=\"text-align: right;\">".number_format($model[0]->sum_b_amt)."</td>
								<td style=\"text-align: right;\">Rp</td>
								<td style=\"text-align: right;\">".number_format($model[0]->sum_j_amt)."</td>
							</tr>
							<tr><td colspan=\"9\"></td></tr>";
			if ($model[0]->sum_b_amt > $model[0]->sum_j_amt){
				$tc = $tc."
							<tr style=\"border-bottom: 1.5px solid;\">
								<td colspan=\"5\"><strong>Payment due to us</strong></td>
								<td style=\"text-align: right;\"><strong>Rp</strong></td>
								<td style=\"text-align: right;font-weight:bold;\">".number_format($model[0]->sum_b_amt - $model[0]->sum_j_amt)."</td>
								<td style=\"text-align: right;\"></td>
								<td style=\"text-align: right;\"></td>
							</tr>";	
			}else{
				$tc = $tc."
							<tr style=\"border-bottom: 1.5px solid;\">
								<td colspan=\"5\"><strong>Payment due to you</strong></td>
								<td style=\"text-align: right;\"></td>
								<td style=\"text-align: right;font-weight:bold;\"></td>
								<td style=\"text-align: right;\"><strong>Rp</strong></td>
								<td style=\"text-align: right;font-weight:bold;\">".number_format($model[0]->sum_j_amt - $model[0]->sum_b_amt)."</td>
							</tr>";
			}
			/*
			if (($model[0]->sum_b_t3 + $model[0]->sum_j_t3) > 0){
				$tc = $tc."
							<tr>
								<td colspan=\"5\"><strong>Settlement Date T+".$model[0]->max_3plus."&emsp;".DateTime::createFromFormat('Y-m-d h:i:s',$model[0]->due_t3)->format('d/m/Y')." (".substr($model[0]->mrkt_t3,0,2).")</strong></td>
								<td style=\"text-align: right;\"><strong>Rp</strong></td>
								<td style=\"text-align: right;\"><strong>".(($model[0]->sum_b_t3 > $model[0]->sum_j_t3)?number_format($model[0]->sum_b_t3 - $model[0]->sum_j_t3) : '0')."</strong></td>
								<td style=\"text-align: right;\"></td>
								<td style=\"text-align: right;\"></td>
							</tr>";
			}
			if (($model[0]->sum_b_t2 + $model[0]->sum_j_t2) > 0){
				$tc = $tc."
							<tr>
								<td colspan=\"5\"><strong>Settlement Date T+2&emsp;".DateTime::createFromFormat('Y-m-d h:i:s',$model[0]->due_t2)->format('d/m/Y')." (".substr($model[0]->mrkt_t2,0,2).")</strong></td>
								<td style=\"text-align: right;\"><strong>Rp</strong></td>
								<td style=\"text-align: right;\"><strong>".(($model[0]->sum_b_t2 > $model[0]->sum_j_t2)?number_format($model[0]->sum_b_t2 - $model[0]->sum_j_t2) : '0')."</strong></td>
								<td style=\"text-align: right;\"></td>
								<td style=\"text-align: right;\"></td>
							</tr>";
			}
			if (($model[0]->sum_b_t1 + $model[0]->sum_j_t1) > 0){
				$tc = $tc."
							<tr>
								<td colspan=\"5\"><strong>Settlement Date T+1&emsp;".DateTime::createFromFormat('Y-m-d h:i:s',$model[0]->due_t1)->format('d/m/Y')." (".substr($model[0]->mrkt_t1,0,2).")</strong></td>
								<td style=\"text-align: right;\">Rp</td>
								<td style=\"text-align: right;\"><strong>".(($model[0]->sum_b_t1 > $model[0]->sum_j_t1)?number_format($model[0]->sum_b_t1 - $model[0]->sum_j_t1) : '0')."</strong></td>
								<td style=\"text-align: right;\"></td>
								<td style=\"text-align: right;\"></td>
							</tr>";
			}
			if (($model[0]->sum_b_t0 + $model[0]->sum_j_t0) > 0){
				$tc = $tc."
							<tr>
								<td colspan=\"5\">Settlement Date T+0&emsp;".DateTime::createFromFormat('Y-m-d h:i:s',$model[0]->contr_dt)->format('d/m/Y')." (".substr($model[0]->mrkt_t0,0,2).")</td>
								<td style=\"text-align: right;\"><strong>Rp</strong></td>
								<td style=\"text-align: right;\"><strong>".(($model[0]->sum_b_t0 > $model[0]->sum_j_t0)?number_format($model[0]->sum_b_t0 - $model[0]->sum_j_t0) : '0')."</strong></td>
								<td style=\"text-align: right;\"></td>
								<td style=\"text-align: right;\"></td>
							</tr>";
			}
			*/				
			$tc = $tc."
							<tr style=\"border-top: 1.5px solid;\"><td colspan=\"9\"></td></tr>
						
					</table>
			</div>
		
		
			<div style=\"clear: both; \"></div>
			<div>";
			$due_date = $model[0]->due_dt_for_amt;
			$sql = "Select GET_DUE_DATE(1, '$due_date') due_date from dual";
			$date = DAO::queryRowSql($sql);
			$due_date = $date['due_date'];
				//if($model[0]->bank_rdi_acct){
							if($model[0]->sum_b_amt > $model[0]->sum_j_amt){
								$tc = $tc."
									PLEASE TRANSFER THE FUND TO : CIMB NIAGA<br />
									<strong>INVESTOR ACCOUNT : ".$model[0]->client_name.", A/C ".$model[0]->bank_rdi_acct."<br />
									-->EFFECTIVE THE LATEST ON THE SETTLEMENT DATE (IN GOOD FUND AT 10:00 AM)</strong><br />
									PLEASE FAX THE TRANSFER SLIP TO 231-4880<br/>";	
							}
							if($model[0]->sum_j_amt > $model[0]->sum_b_amt){
								$tc = $tc."
									We will transfer to your Bank account for amount below :<br />"
									.DateTime::createFromFormat('Y-m-d H:i:s',$model[0]->due_dt_for_amt)->format('d/m/Y')."&emsp; if your bank account in CIMB NIAGA<br />"
								.DateTime::createFromFormat('Y-m-d H:i:s',$due_date)->format('d/m/Y')."&emsp; if your bank account in Other Bank <br /><br />";
							}
							
							
				//}
				/*
				else{
					$tc = $tc."
							<font style=\"text-decoration: underline;\">The following is our payment bank details</font><br />
							".$model[0]->nama_prsh."<br />
							".$model[0]->bank_name." A/C : ".$model[0]->brch_acct_num."<br/>";
				}
				*/
				$contract_dept = Sysparam::model()->find("param_id='TRADE CONFIRMATION' and param_Cd1='CON_DEPT'")->dstr1;
				$tc = $tc."
				- This statement will be considered correct if no discrepancies are reported within 24 hours.<br /><br />
				- This report is generated by system,for report sent by e-mail no signature required.<br />
			</div>
			<div style=\"clear: both; \"><br /><br /><br />
			
			<div>
				<div style=\"float: left; width: 30%;\">
					<p>Best Regards</p><br /><br />
					(".$contract_dept.")<br />
					Contract Dept 
					<br /><br />
					
				</div>
					<div style=\"float: left; width: 30%;\">
					<p>&emsp;</p><br /><br /> (".$model[0]->rem_name.")<br />
					Sales
					</div>
				<div style=\"float: right; width: 40%;\">
					<p align='center'>Reconfirmed By</p><br /><br />
					<p align='center'>(".$model[0]->client_name.")</p>
				</div>
			</div>
			
			<div style=\"float: left; width: 50%;\">
			<div style=\"float: left; width: 12%;\">
			<p align=\"justify\" style=\"padding-right:10px;font-size:8pt;line-height:120%\">Note :</p>
				</div>
				<div style=\"float: left; width: 88%;\">
					<p align=\"justify\" style=\"padding-right:10px;font-size:8pt;line-height:120%\">
							In connection with Rule No. V.D.10 concerning Know Your
							Customer (KYC) as issued by Capital Market and Financial
							Institution Supervisory Agency (Badan Pengawas Pasar Modal dan
							Lembaga Keuangan) ,you are kindly requested to<br /><br />
							immediately provide update on every changes and/or renewal of data
							and/or documents by contacting our Customer Relation Officer.
					</p>
				</div>
			</div>
			<div style=\"float: left; width: 50%;\">
				<div style=\"float: left; width: 3%;\">
				*
				</div>
				<div style=\"float: left; width: 97%;\">
				 <p align=\"justify\" style=\"font-size:8pt;line-height:120%;padding-right:30px;\">
					Sehubungan dengan Peraturan Badan Pengawas Pasar Modal dan
					Lembaga Keuangan No. V.D.10 tentang Prinsip Mengenal Nasabah
					(KYC), Anda dimohon dengan hormat untuk segera melakukan
					pengkinian data atas setiap perubahan dan/atau<br /><br />
					pembaharuan data dan/atau dokumen dengan menghubungi
					Customer Relation Officer kami.
				</p>
				</div>
			</div>
			<div style=\"clear: both; \"></div>
			";
		}else{
			$tc = "<h1>Data Not Found!</h1>";
		}
		
		return $tc;

	}

	public function genTCind($client_cd, $tc_date, $rem_cd, $branch_code, $user_id){
		$model = Rtradeconf::model()->findAll(array('condition'=>"to_char(contr_dt,'YYYY-MM-DD HH24:MI:SS') = '$tc_date' and client_cd like '$client_cd' 
				and rem_cd like '$rem_cd' and branch_code like '$branch_code' and userid = '$user_id'",'order'=>'beli_jual, stk_cd'));
		$baseurl = Yii::app()->request->baseUrl;
		if($model){
			$tc = "
			<div>
				<div style=\"float: left; width: 60%;\">
					<h4>PT. DANASAKTI SECURITIES</h4>
					".$model[0]->brch_addr_1."<br />".$model[0]->brch_addr_2."<br/>
					".$model[0]->brch_addr_3."<br/>
					Telp : ".$model[0]->brch_phone."&emsp;Fax : ".$model[0]->brch_fax.($model[0]->dealing_phone?" Dealing : ".$model[0]->dealing_phone:'')."<br />
					NPWP&emsp;: &nbsp; ".$model[0]->no_ijin1."<br />
					<br />
					<table style='margin-left:-2%;line-height:1%;margin-top:-3%;' >
						<tr>
							<td width=\"40px\">ATT.</td>
							<td>: ".$model[0]->contact_pers."</td>
						</tr>
						<tr>
							<td></td>
							<td>&nbsp; ".$model[0]->def_addr_1."</td>
						</tr>
						<tr>
							<td></td>
							<td>&nbsp; ".$model[0]->def_addr_2."</td>
						</tr>
						<tr>
							<td></td>
							<td>&nbsp; ".$model[0]->def_addr_3."</td>
						</tr>
						<tr>
							<td>ZIP</td>
							<td>: ".$model[0]->post_cd."</td>
						</tr>
					</table>
					
				</div>
				<div style=\"float: right; width: 40%;\">
					
				<table style='margin-left:-5%;line-height:1%;' >
					<tr>
						<td colspan='3'><h4>TRADE CONFIRMATION</h4></td>
					</tr>
					<tr>
						<td width='100px' >Trade Date</td>
						<td  colspan='2' >: ".DateTime::createFromFormat('Y-m-d h:i:s',$model[0]->contr_dt)->format('d/m/Y')."</td>
					</tr>
					<tr>
						<td width='100px' >Settle Date</td>
						<td  colspan='2' >: ".DateTime::createFromFormat('Y-m-d h:i:s',$model[0]->due_dt_for_amt)->format('d/m/Y')."</td>
					</tr>
					<tr>
						<td width='100px' >Ref No.</td>
						<td  colspan='2' style='font-weight:bold'>: {tc_id}</td>
					</tr>
				</table>
				<br />
					
				<table style='margin-left:-5%;line-height:1%;' >
					<tr>
						<td colspan='2'>".($model[0]->client_title? ucwords(strtolower($model[0]->client_title)).'. ' : '').$model[0]->client_name."</td>
					</tr>
					<tr>
						<td>Client code</td>
						<td>: ".$model[0]->old_ic_num."&emsp; /".$model[0]->client_cd."</td>
					</tr>
					
					<tr>
						<td>Phone</td>
						<td>: ".(($model[0]->phone_num && (trim($model[0]->phone_num) != 'NA'))?$model[0]->phone_num : '').($model[0]->phone2_1?', '.$model[0]->phone2_1 : '').($model[0]->hand_phone1?', '.$model[0]->hand_phone1 : '');
						 	$tc=$tc." 
						</td>
					</tr>
					<tr>
						<td>Fax</td><td> : "; if($model[0]->fax_num){$tc = $tc.$model[0]->fax_num ; }$tc=$tc."</td>
					</tr>
					<tr>
						<td colspan='2'>";if($model[0]->e_mail1){$tc = $tc.$model[0]->e_mail1;}$tc = $tc."</td>
					</tr>
					<tr><td></td><td></td></tr>
				</table>
				
				
				";
				
			$tc = $tc."	
			
			</div>
			<br style=\"clear: both;\" />
			<div style=\"margin-top:-30px;\">
					As instructed, we have executed the following transaction(s) for your account:
					<table id=\"tc-table\" class=\"table-condensed\" style=\"border-collapse: collapse; border: none;\">
						<tr style=\"border-top: 1.5px solid;border-bottom: 1.5px solid;\">
							<td><strong>Share</strong></td>
							<td></td>
							<td></td>
							<td style=\"text-align: right;\"><strong>Quantity</strong></td>
							<td style=\"text-align: right;\"><strong>Price</strong></td>
							<td colspan=\"2\" style=\"text-align: right;\"><strong>Amount Buy</strong></td>
							<td colspan=\"2\" style=\"text-align: right;\"><strong>Amount Sell</strong></td>
						</tr>
						";
			foreach ($model as $row){
				$tc = $tc."
								<tr>
									<td>".$row->stk_cd."</td>
									<td colspan='2'>".$row->stk_name."</td>
									
									<td style=\"text-align: right;\">".number_format($row->qty)."</td>
									<td style=\"text-align: right;\">".number_format($row->price)."</td>
									<td style=\"width: 5%\"></td>
									<td style=\"text-align: right; width: 16%\">".number_format($row->b_val)."</td>
									<td style=\"width: 5%\"></td>
									<td style=\"text-align: right; width: 16%\">".number_format($row->j_val)."</td>
								</tr>";
			}
			$tc = $tc."
							<tr style=\"border-top: 1.5px solid;\">
								<td colspan=\"5\">Total Value</td>
								<td style=\"text-align: right;\"><strong>Rp</strong></td>
								<td style=\"text-align: right;font-weight:bold;\">".number_format($model[0]->sum_b_val)."</td>
								<td style=\"text-align: right;\"><strong>Rp</strong></td>
								<td style=\"text-align: right;font-weight:bold;\">".number_format($model[0]->sum_j_val)."</td>
							</tr>
							<tr>
								<td colspan=\"5\">Commission ".($model[0]->brok_perc/100)."%</td>
								<td style=\"text-align: right;\"></td>
								<td style=\"text-align: right;\">".number_format($model[0]->sum_b_comm)."</td>
								<td style=\"text-align: right;\"></td>
								<td style=\"text-align: right;\">".number_format($model[0]->sum_j_comm)."</td>
							</tr>
							<tr>
								<td colspan=\"5\">VAT</td>
								<td style=\"text-align: right;\"></td>
								<td style=\"text-align: right;\">".number_format($model[0]->sum_b_vat)."</td>
								<td style=\"text-align: right;\"></td>
								<td style=\"text-align: right;\">".number_format($model[0]->sum_j_vat)."</td>
							</tr>
							<tr>
								<td colspan=\"5\">Levy</td>
								<td style=\"text-align: right;\"></td>
								<td style=\"text-align: right;\">".number_format($model[0]->sum_b_levy)."</td>
								<td style=\"text-align: right;\"></td>
								<td style=\"text-align: right;\">".number_format($model[0]->sum_j_levy)."</td>
							</tr>";
			if ($model[0]->sum_j_pph != 0){
				$tc = $tc."
							<tr>
								<td colspan=\"5\">Sales Tax ".($model[0]->pph_perc/100)."%</td>
								<td style=\"text-align: right;\"></td>
								<td style=\"text-align: right;\">".number_format($model[0]->sum_b_pph)."</td>
								<td style=\"text-align: right;\"></td>
								<td style=\"text-align: right;\">".number_format($model[0]->sum_j_pph)."</td>
							</tr>";
			}
			if (($model[0]->sum_b_whpph23 != 0) || ($model[0]->sum_j_whpph23 != 0)){
				$tc = $tc."
							<tr>
								<td colspan=\"5\">Witholding Tax PPh 23 ".$model[0]->whpph23_perc."%</td>
								<td style=\"text-align: right;\"></td>
								<td style=\"text-align: right;\">".number_format($model[0]->sum_b_whpph23)."</td>
								<td style=\"text-align: right;\"></td>
								<td style=\"text-align: right;\">".number_format($model[0]->sum_j_whpph23)."</td>
							</tr>";
			}
			$tc = $tc."
							<tr style=\"border-top: 1.5px solid;border-bottom: 1.5px solid;\">
								<td colspan=\"5\">Total Net</td>
								<td style=\"text-align: right;\">Rp</td>
								<td style=\"text-align: right;\">".number_format($model[0]->sum_b_amt)."</td>
								<td style=\"text-align: right;\">Rp</td>
								<td style=\"text-align: right;\">".number_format($model[0]->sum_j_amt)."</td>
							</tr>
							<tr><td colspan=\"9\"></td></tr>";
			if ($model[0]->sum_b_amt > $model[0]->sum_j_amt){
				$tc = $tc."
							<tr style=\"border-bottom: 1.5px solid;\">
								<td colspan=\"5\"><strong>Payment due to us</strong></td>
								<td style=\"text-align: right;\"><strong>Rp</strong></td>
								<td style=\"text-align: right;font-weight:bold;\">".number_format($model[0]->sum_b_amt - $model[0]->sum_j_amt)."</td>
								<td style=\"text-align: right;\"></td>
								<td style=\"text-align: right;\"></td>
							</tr>";	
			}else{
				$tc = $tc."
							<tr style=\"border-bottom: 1.5px solid;\">
								<td colspan=\"5\"><strong>Payment due to you</strong></td>
								<td style=\"text-align: right;\"></td>
								<td style=\"text-align: right;font-weight:bold;\"></td>
								<td style=\"text-align: right;\"><strong>Rp</strong></td>
								<td style=\"text-align: right;font-weight:bold;\">".number_format($model[0]->sum_j_amt - $model[0]->sum_b_amt)."</td>
							</tr>";
			}
			/*
			if (($model[0]->sum_b_t3 + $model[0]->sum_j_t3) > 0){
				$tc = $tc."
							<tr>
								<td colspan=\"5\"><strong>Settlement Date T+".$model[0]->max_3plus."&emsp;".DateTime::createFromFormat('Y-m-d h:i:s',$model[0]->due_t3)->format('d/m/Y')." (".substr($model[0]->mrkt_t3,0,2).")</strong></td>
								<td style=\"text-align: right;\"><strong>Rp</strong></td>
								<td style=\"text-align: right;\"><strong>".(($model[0]->sum_b_t3 > $model[0]->sum_j_t3)?number_format($model[0]->sum_b_t3 - $model[0]->sum_j_t3) : '0')."</strong></td>
								<td style=\"text-align: right;\"></td>
								<td style=\"text-align: right;\"></td>
							</tr>";
			}
			if (($model[0]->sum_b_t2 + $model[0]->sum_j_t2) > 0){
				$tc = $tc."
							<tr>
								<td colspan=\"5\"><strong>Settlement Date T+2&emsp;".DateTime::createFromFormat('Y-m-d h:i:s',$model[0]->due_t2)->format('d/m/Y')." (".substr($model[0]->mrkt_t2,0,2).")</strong></td>
								<td style=\"text-align: right;\"><strong>Rp</strong></td>
								<td style=\"text-align: right;\"><strong>".(($model[0]->sum_b_t2 > $model[0]->sum_j_t2)?number_format($model[0]->sum_b_t2 - $model[0]->sum_j_t2) : '0')."</strong></td>
								<td style=\"text-align: right;\"></td>
								<td style=\"text-align: right;\"></td>
							</tr>";
			}
			if (($model[0]->sum_b_t1 + $model[0]->sum_j_t1) > 0){
				$tc = $tc."
							<tr>
								<td colspan=\"5\"><strong>Settlement Date T+1&emsp;".DateTime::createFromFormat('Y-m-d h:i:s',$model[0]->due_t1)->format('d/m/Y')." (".substr($model[0]->mrkt_t1,0,2).")</strong></td>
								<td style=\"text-align: right;\">Rp</td>
								<td style=\"text-align: right;\"><strong>".(($model[0]->sum_b_t1 > $model[0]->sum_j_t1)?number_format($model[0]->sum_b_t1 - $model[0]->sum_j_t1) : '0')."</strong></td>
								<td style=\"text-align: right;\"></td>
								<td style=\"text-align: right;\"></td>
							</tr>";
			}
			if (($model[0]->sum_b_t0 + $model[0]->sum_j_t0) > 0){
				$tc = $tc."
							<tr>
								<td colspan=\"5\">Settlement Date T+0&emsp;".DateTime::createFromFormat('Y-m-d h:i:s',$model[0]->contr_dt)->format('d/m/Y')." (".substr($model[0]->mrkt_t0,0,2).")</td>
								<td style=\"text-align: right;\"><strong>Rp</strong></td>
								<td style=\"text-align: right;\"><strong>".(($model[0]->sum_b_t0 > $model[0]->sum_j_t0)?number_format($model[0]->sum_b_t0 - $model[0]->sum_j_t0) : '0')."</strong></td>
								<td style=\"text-align: right;\"></td>
								<td style=\"text-align: right;\"></td>
							</tr>";
			}
			*/				
			$tc = $tc."
							<tr style=\"border-top: 1.5px solid;\"><td colspan=\"9\"></td></tr>
						
					</table>
			</div>
		
		
			<div style=\"clear: both; \"></div>
			<div>";
			$due_date = $model[0]->due_dt_for_amt;
			$sql = "Select GET_DUE_DATE(1, '$due_date') due_date from dual";
			$date = DAO::queryRowSql($sql);
			$due_date = $date['due_date'];
				//if($model[0]->bank_rdi_acct){
							if($model[0]->sum_b_amt > $model[0]->sum_j_amt){
								$tc = $tc."
									PLEASE TRANSFER THE FUND TO : CIMB NIAGA<br />
									<strong>INVESTOR ACCOUNT : ".$model[0]->client_name.", A/C ".$model[0]->bank_rdi_acct."<br />
									-->EFFECTIVE THE LATEST ON THE SETTLEMENT DATE (IN GOOD FUND AT 10:00 AM)</strong><br />
									PLEASE FAX THE TRANSFER SLIP TO 231-4880<br/>";	
							}
							if($model[0]->sum_j_amt > $model[0]->sum_b_amt){
								$tc = $tc."
									We will transfer to your Bank account for amount below :<br />"
									.DateTime::createFromFormat('Y-m-d H:i:s',$model[0]->due_dt_for_amt)->format('d/m/Y')."&emsp; if your bank account in CIMB NIAGA<br />"
								.DateTime::createFromFormat('Y-m-d H:i:s',$due_date)->format('d/m/Y')."&emsp; if your bank account in Other Bank <br /><br />";
							}
							
							
				//}
				/*
				else{
					$tc = $tc."
							<font style=\"text-decoration: underline;\">The following is our payment bank details</font><br />
							".$model[0]->nama_prsh."<br />
							".$model[0]->bank_name." A/C : ".$model[0]->brch_acct_num."<br/>";
				}
				*/
				$contract_dept = Sysparam::model()->find("param_id='TRADE CONFIRMATION' and param_Cd1='CON_DEPT'")->dstr1;
				$tc = $tc."
				- This statement will be considered correct if no discrepancies are reported within 24 hours.<br /><br />
				- This report is generated by system,for report sent by e-mail no signature required.<br />
			</div>
			<div style=\"clear: both; \"><br /><br /><br />
			
			<div>
				<div style=\"float: left; width: 30%;\">
					<p>Best Regards</p><br /><br />
					(".$contract_dept.")<br />
					Contract Dept 
					<br /><br />
					
				</div>
					<div style=\"float: left; width: 30%;\">
					<p>&emsp;</p><br /><br /> (".$model[0]->rem_name.")<br />
					Sales
					</div>
				<div style=\"float: right; width: 40%;\">
					<p align='center'>Reconfirmed By</p><br /><br />
					<p align='center'>(".$model[0]->client_name.")</p>
				</div>
			</div>
			
			<div style=\"float: left; width: 50%;\">
			<div style=\"float: left; width: 12%;\">
			<p align=\"justify\" style=\"padding-right:10px;font-size:8pt;line-height:120%\">Note :</p>
				</div>
				<div style=\"float: left; width: 88%;\">
					<p align=\"justify\" style=\"padding-right:10px;font-size:8pt;line-height:120%\">
							In connection with Rule No. V.D.10 concerning Know Your
							Customer (KYC) as issued by Capital Market and Financial
							Institution Supervisory Agency (Badan Pengawas Pasar Modal dan
							Lembaga Keuangan) ,you are kindly requested to<br /><br />
							immediately provide update on every changes and/or renewal of data
							and/or documents by contacting our Customer Relation Officer.
					</p>
				</div>
			</div>
			<div style=\"float: left; width: 50%;\">
				<div style=\"float: left; width: 3%;\">
				*
				</div>
				<div style=\"float: left; width: 97%;\">
				 <p align=\"justify\" style=\"font-size:8pt;line-height:120%;padding-right:30px;\">
					Sehubungan dengan Peraturan Badan Pengawas Pasar Modal dan
					Lembaga Keuangan No. V.D.10 tentang Prinsip Mengenal Nasabah
					(KYC), Anda dimohon dengan hormat untuk segera melakukan
					pengkinian data atas setiap perubahan dan/atau<br /><br />
					pembaharuan data dan/atau dokumen dengan menghubungi
					Customer Relation Officer kami.
				</p>
				</div>
			</div>
			<div style=\"clear: both; \"></div>
			";
		}else{
			$tc = "<h1>Data Not Found!</h1>";
		}
		
		return $tc;

	}

	public function genTCindmatrix($client_cd, $tc_date, $rem_cd, $branch_code, $user_id){
		$model = Rtradeconf::model()->findAll(array('condition'=>"to_char(contr_dt,'YYYY-MM-DD HH24:MI:SS') = '$tc_date' and client_cd like '$client_cd' 
				and rem_cd like '$rem_cd' and branch_code like '$branch_code' and userid = '$user_id'",'order'=>'beli_jual, stk_cd'));
		$baseurl = Yii::app()->request->baseUrl;
		if($model){
			$tc = "
			<div>
				<div style=\"float: left; width: 60%;\">
					<h4>PT. DANASAKTI SECURITIES</h4>
					".$model[0]->brch_addr_1."<br />".$model[0]->brch_addr_2."<br/>
					".$model[0]->brch_addr_3."<br/>
					Telp : ".$model[0]->brch_phone."&emsp;Fax : ".$model[0]->brch_fax.($model[0]->dealing_phone?" Dealing : ".$model[0]->dealing_phone:'')."<br />
					NPWP&emsp;: &nbsp; ".$model[0]->no_ijin1."<br />
					<br />
					<table style='margin-left:-2%;line-height:1%;margin-top:-3%;' >
						<tr>
							<td width=\"40px\">ATT.</td>
							<td>: ".$model[0]->contact_pers."</td>
						</tr>
						<tr>
							<td></td>
							<td>&nbsp; ".$model[0]->def_addr_1."</td>
						</tr>
						<tr>
							<td></td>
							<td>&nbsp; ".$model[0]->def_addr_2."</td>
						</tr>
						<tr>
							<td></td>
							<td>&nbsp; ".$model[0]->def_addr_3."</td>
						</tr>
						<tr>
							<td>ZIP</td>
							<td>: ".$model[0]->post_cd."</td>
						</tr>
					</table>
					
				</div>
				<div style=\"float: right; width: 40%;\">
					
				<table style='margin-left:-5%;line-height:1%;' >
					<tr>
						<td colspan='3'><h4>TRADE CONFIRMATION</h4></td>
					</tr>
					<tr>
						<td width='100px' >Trade Date</td>
						<td  colspan='2' >: ".DateTime::createFromFormat('Y-m-d h:i:s',$model[0]->contr_dt)->format('d/m/Y')."</td>
					</tr>
					<tr>
						<td width='100px' >Settle Date</td>
						<td  colspan='2' >: ".DateTime::createFromFormat('Y-m-d h:i:s',$model[0]->due_dt_for_amt)->format('d/m/Y')."</td>
					</tr>
					<tr>
						<td width='100px' >Ref No.</td>
						<td  colspan='2' style='font-weight:bold'>: {tc_id}</td>
					</tr>
				</table>
				<br />
					
				<table style='margin-left:-5%;line-height:1%;' >
					<tr>
						<td colspan='2'>".($model[0]->client_title? ucwords(strtolower($model[0]->client_title)).'. ' : '').$model[0]->client_name."</td>
					</tr>
					<tr>
						<td>Client code</td>
						<td>: ".$model[0]->old_ic_num."&emsp; /".$model[0]->client_cd."</td>
					</tr>
					
					<tr>
						<td>Phone</td>
						<td>: ".(($model[0]->phone_num && (trim($model[0]->phone_num) != 'NA'))?$model[0]->phone_num : '').($model[0]->phone2_1?', '.$model[0]->phone2_1 : '').($model[0]->hand_phone1?', '.$model[0]->hand_phone1 : '');
						 	$tc=$tc." 
						</td>
					</tr>
					<tr>
						<td>Fax</td><td> : "; if($model[0]->fax_num){$tc = $tc.$model[0]->fax_num ; }$tc=$tc."</td>
					</tr>
					<tr>
						<td colspan='2'>";if($model[0]->e_mail1){$tc = $tc.$model[0]->e_mail1;}$tc = $tc."</td>
					</tr>
					<tr><td></td><td></td></tr>
				</table>
				
				
				";
				
			$tc = $tc."	
			
			</div>
			<br style=\"clear: both;\" />
			<div style=\"margin-top:-30px;\">
					As instructed, we have executed the following transaction(s) for your account:
					<table id=\"tc-table\" class=\"table-condensed\" style=\"border-collapse: collapse; border: none;\">
						<tr style=\"border-top: 1.5px solid;border-bottom: 1.5px solid;\">
							<td><strong>Share</strong></td>
							<td></td>
							<td></td>
							<td style=\"text-align: right;\"><strong>Quantity</strong></td>
							<td style=\"text-align: right;\"><strong>Price</strong></td>
							<td colspan=\"2\" style=\"text-align: right;\"><strong>Amount Buy</strong></td>
							<td colspan=\"2\" style=\"text-align: right;\"><strong>Amount Sell</strong></td>
						</tr>
						";
			foreach ($model as $row){
				$tc = $tc."
								<tr>
									<td>".$row->stk_cd."</td>
									<td colspan='2'>".$row->stk_name."</td>
									
									<td style=\"text-align: right;\">".number_format($row->qty)."</td>
									<td style=\"text-align: right;\">".number_format($row->price)."</td>
									<td style=\"width: 5%\"></td>
									<td style=\"text-align: right; width: 16%\">".number_format($row->b_val)."</td>
									<td style=\"width: 5%\"></td>
									<td style=\"text-align: right; width: 16%\">".number_format($row->j_val)."</td>
								</tr>";
			}
			$tc = $tc."
							<tr style=\"border-top: 1.5px solid;\">
								<td colspan=\"5\">Total Value</td>
								<td style=\"text-align: right;\"><strong>Rp</strong></td>
								<td style=\"text-align: right;font-weight:bold;\">".number_format($model[0]->sum_b_val)."</td>
								<td style=\"text-align: right;\"><strong>Rp</strong></td>
								<td style=\"text-align: right;font-weight:bold;\">".number_format($model[0]->sum_j_val)."</td>
							</tr>
							<tr>
								<td colspan=\"5\">Commission ".($model[0]->brok_perc/100)."%</td>
								<td style=\"text-align: right;\"></td>
								<td style=\"text-align: right;\">".number_format($model[0]->sum_b_comm)."</td>
								<td style=\"text-align: right;\"></td>
								<td style=\"text-align: right;\">".number_format($model[0]->sum_j_comm)."</td>
							</tr>
							<tr>
								<td colspan=\"5\">VAT</td>
								<td style=\"text-align: right;\"></td>
								<td style=\"text-align: right;\">".number_format($model[0]->sum_b_vat)."</td>
								<td style=\"text-align: right;\"></td>
								<td style=\"text-align: right;\">".number_format($model[0]->sum_j_vat)."</td>
							</tr>
							<tr>
								<td colspan=\"5\">Levy</td>
								<td style=\"text-align: right;\"></td>
								<td style=\"text-align: right;\">".number_format($model[0]->sum_b_levy)."</td>
								<td style=\"text-align: right;\"></td>
								<td style=\"text-align: right;\">".number_format($model[0]->sum_j_levy)."</td>
							</tr>";
			if ($model[0]->sum_j_pph != 0){
				$tc = $tc."
							<tr>
								<td colspan=\"5\">Sales Tax ".($model[0]->pph_perc/100)."%</td>
								<td style=\"text-align: right;\"></td>
								<td style=\"text-align: right;\">".number_format($model[0]->sum_b_pph)."</td>
								<td style=\"text-align: right;\"></td>
								<td style=\"text-align: right;\">".number_format($model[0]->sum_j_pph)."</td>
							</tr>";
			}
			if (($model[0]->sum_b_whpph23 != 0) || ($model[0]->sum_j_whpph23 != 0)){
				$tc = $tc."
							<tr>
								<td colspan=\"5\">Witholding Tax PPh 23 ".$model[0]->whpph23_perc."%</td>
								<td style=\"text-align: right;\"></td>
								<td style=\"text-align: right;\">".number_format($model[0]->sum_b_whpph23)."</td>
								<td style=\"text-align: right;\"></td>
								<td style=\"text-align: right;\">".number_format($model[0]->sum_j_whpph23)."</td>
							</tr>";
			}
			$tc = $tc."
							<tr style=\"border-top: 1.5px solid;border-bottom: 1.5px solid;\">
								<td colspan=\"5\">Total Net</td>
								<td style=\"text-align: right;\">Rp</td>
								<td style=\"text-align: right;\">".number_format($model[0]->sum_b_amt)."</td>
								<td style=\"text-align: right;\">Rp</td>
								<td style=\"text-align: right;\">".number_format($model[0]->sum_j_amt)."</td>
							</tr>
							<tr><td colspan=\"9\"></td></tr>";
			if ($model[0]->sum_b_amt > $model[0]->sum_j_amt){
				$tc = $tc."
							<tr style=\"border-bottom: 1.5px solid;\">
								<td colspan=\"5\"><strong>Payment due to us</strong></td>
								<td style=\"text-align: right;\"><strong>Rp</strong></td>
								<td style=\"text-align: right;font-weight:bold;\">".number_format($model[0]->sum_b_amt - $model[0]->sum_j_amt)."</td>
								<td style=\"text-align: right;\"></td>
								<td style=\"text-align: right;\"></td>
							</tr>";	
			}else{
				$tc = $tc."
							<tr style=\"border-bottom: 1.5px solid;\">
								<td colspan=\"5\"><strong>Payment due to you</strong></td>
								<td style=\"text-align: right;\"></td>
								<td style=\"text-align: right;font-weight:bold;\"></td>
								<td style=\"text-align: right;\"><strong>Rp</strong></td>
								<td style=\"text-align: right;font-weight:bold;\">".number_format($model[0]->sum_j_amt - $model[0]->sum_b_amt)."</td>
							</tr>";
			}
			/*
			if (($model[0]->sum_b_t3 + $model[0]->sum_j_t3) > 0){
				$tc = $tc."
							<tr>
								<td colspan=\"5\"><strong>Settlement Date T+".$model[0]->max_3plus."&emsp;".DateTime::createFromFormat('Y-m-d h:i:s',$model[0]->due_t3)->format('d/m/Y')." (".substr($model[0]->mrkt_t3,0,2).")</strong></td>
								<td style=\"text-align: right;\"><strong>Rp</strong></td>
								<td style=\"text-align: right;\"><strong>".(($model[0]->sum_b_t3 > $model[0]->sum_j_t3)?number_format($model[0]->sum_b_t3 - $model[0]->sum_j_t3) : '0')."</strong></td>
								<td style=\"text-align: right;\"></td>
								<td style=\"text-align: right;\"></td>
							</tr>";
			}
			if (($model[0]->sum_b_t2 + $model[0]->sum_j_t2) > 0){
				$tc = $tc."
							<tr>
								<td colspan=\"5\"><strong>Settlement Date T+2&emsp;".DateTime::createFromFormat('Y-m-d h:i:s',$model[0]->due_t2)->format('d/m/Y')." (".substr($model[0]->mrkt_t2,0,2).")</strong></td>
								<td style=\"text-align: right;\"><strong>Rp</strong></td>
								<td style=\"text-align: right;\"><strong>".(($model[0]->sum_b_t2 > $model[0]->sum_j_t2)?number_format($model[0]->sum_b_t2 - $model[0]->sum_j_t2) : '0')."</strong></td>
								<td style=\"text-align: right;\"></td>
								<td style=\"text-align: right;\"></td>
							</tr>";
			}
			if (($model[0]->sum_b_t1 + $model[0]->sum_j_t1) > 0){
				$tc = $tc."
							<tr>
								<td colspan=\"5\"><strong>Settlement Date T+1&emsp;".DateTime::createFromFormat('Y-m-d h:i:s',$model[0]->due_t1)->format('d/m/Y')." (".substr($model[0]->mrkt_t1,0,2).")</strong></td>
								<td style=\"text-align: right;\">Rp</td>
								<td style=\"text-align: right;\"><strong>".(($model[0]->sum_b_t1 > $model[0]->sum_j_t1)?number_format($model[0]->sum_b_t1 - $model[0]->sum_j_t1) : '0')."</strong></td>
								<td style=\"text-align: right;\"></td>
								<td style=\"text-align: right;\"></td>
							</tr>";
			}
			if (($model[0]->sum_b_t0 + $model[0]->sum_j_t0) > 0){
				$tc = $tc."
							<tr>
								<td colspan=\"5\">Settlement Date T+0&emsp;".DateTime::createFromFormat('Y-m-d h:i:s',$model[0]->contr_dt)->format('d/m/Y')." (".substr($model[0]->mrkt_t0,0,2).")</td>
								<td style=\"text-align: right;\"><strong>Rp</strong></td>
								<td style=\"text-align: right;\"><strong>".(($model[0]->sum_b_t0 > $model[0]->sum_j_t0)?number_format($model[0]->sum_b_t0 - $model[0]->sum_j_t0) : '0')."</strong></td>
								<td style=\"text-align: right;\"></td>
								<td style=\"text-align: right;\"></td>
							</tr>";
			}
			*/				
			$tc = $tc."
							<tr style=\"border-top: 1.5px solid;\"><td colspan=\"9\"></td></tr>
						
					</table>
			</div>
		
		
			<div style=\"clear: both; \"></div>
			<div>";
			$due_date = $model[0]->due_dt_for_amt;
			$sql = "Select GET_DUE_DATE(1, '$due_date') due_date from dual";
			$date = DAO::queryRowSql($sql);
			$due_date = $date['due_date'];
				//if($model[0]->bank_rdi_acct){
							if($model[0]->sum_b_amt > $model[0]->sum_j_amt){
								$tc = $tc."
									PLEASE TRANSFER THE FUND TO : CIMB NIAGA<br />
									<strong>INVESTOR ACCOUNT : ".$model[0]->client_name.", A/C ".$model[0]->bank_rdi_acct."<br />
									-->EFFECTIVE THE LATEST ON THE SETTLEMENT DATE (IN GOOD FUND AT 10:00 AM)</strong><br />
									PLEASE FAX THE TRANSFER SLIP TO 231-4880<br/>";	
							}
							if($model[0]->sum_j_amt > $model[0]->sum_b_amt){
								$tc = $tc."
									We will transfer to your Bank account for amount below :<br />"
									.DateTime::createFromFormat('Y-m-d H:i:s',$model[0]->due_dt_for_amt)->format('d/m/Y')."&emsp; if your bank account in CIMB NIAGA<br />"
								.DateTime::createFromFormat('Y-m-d H:i:s',$due_date)->format('d/m/Y')."&emsp; if your bank account in Other Bank <br /><br />";
							}
							
							
				//}
				/*
				else{
					$tc = $tc."
							<font style=\"text-decoration: underline;\">The following is our payment bank details</font><br />
							".$model[0]->nama_prsh."<br />
							".$model[0]->bank_name." A/C : ".$model[0]->brch_acct_num."<br/>";
				}
				*/
				$contract_dept = Sysparam::model()->find("param_id='TRADE CONFIRMATION' and param_Cd1='CON_DEPT'")->dstr1;
				$tc = $tc."
				- This statement will be considered correct if no discrepancies are reported within 24 hours.<br /><br />
				- This report is generated by system,for report sent by e-mail no signature required.<br />
			</div>
			<div style=\"clear: both; \"><br /><br /><br />
			
			<div>
				<div style=\"float: left; width: 30%;\">
					<p>Best Regards</p><br /><br />
					(".$contract_dept.")<br />
					Contract Dept 
					<br /><br />
					
				</div>
					<div style=\"float: left; width: 30%;\">
					<p>&emsp;</p><br /><br /> (".$model[0]->rem_name.")<br />
					Sales
					</div>
				<div style=\"float: right; width: 40%;\">
					<p align='center'>Reconfirmed By</p><br /><br />
					<p align='center'>(".$model[0]->client_name.")</p>
				</div>
			</div>
			
			<div style=\"float: left; width: 50%;\">
			<div style=\"float: left; width: 12%;\">
			<p align=\"justify\" style=\"padding-right:10px;font-size:8pt;line-height:120%\">Note :</p>
				</div>
				<div style=\"float: left; width: 88%;\">
					<p align=\"justify\" style=\"padding-right:10px;font-size:8pt;line-height:120%\">
							In connection with Rule No. V.D.10 concerning Know Your
							Customer (KYC) as issued by Capital Market and Financial
							Institution Supervisory Agency (Badan Pengawas Pasar Modal dan
							Lembaga Keuangan) ,you are kindly requested to<br /><br />
							immediately provide update on every changes and/or renewal of data
							and/or documents by contacting our Customer Relation Officer.
					</p>
				</div>
			</div>
			<div style=\"float: left; width: 50%;\">
				<div style=\"float: left; width: 3%;\">
				*
				</div>
				<div style=\"float: left; width: 97%;\">
				 <p align=\"justify\" style=\"font-size:8pt;line-height:120%;padding-right:30px;\">
					Sehubungan dengan Peraturan Badan Pengawas Pasar Modal dan
					Lembaga Keuangan No. V.D.10 tentang Prinsip Mengenal Nasabah
					(KYC), Anda dimohon dengan hormat untuk segera melakukan
					pengkinian data atas setiap perubahan dan/atau<br /><br />
					pembaharuan data dan/atau dokumen dengan menghubungi
					Customer Relation Officer kami.
				</p>
				</div>
			</div>
			<div style=\"clear: both; \"></div>
			";
		}else{
			$tc = "<h1>Data Not Found!</h1>";
		}
		
		return $tc;

	}
		
	public function actionIndex()
	{
		//set_time_limit(3600);
		//ini_set('memory_limit','24M');
		$model = new Ttcdoc;
		$model->tc_date = date('d/m/Y');
		$model->client_type = 0;
		$model->tc_rev = 1;
		$isfirst = 1;
		
		$valid = false;
		
		if(isset($_POST['Ttcdoc']))
		{
			$model->attributes=$_POST['Ttcdoc'];
			$valid = $model->validate();
			$isfirst = 0;
			if($valid)
			{
				if($model->client_type == 0)
				{
					$client = Tcontracts::model()->findAll(array('select'=>'DISTINCT client_cd','condition'=>"contr_dt = TO_DATE('$model->tc_date','YYYY-MM-DD') AND contr_stat <> 'C'",'order'=>'client_cd'));
					if($client)
					{
						//$clientFrom = $client[0]->client_cd;
						//$clientTo = $client[count($client)-1]->client_cd;
						$model->beg_rem = '%';
						$model->end_rem = '_';
						$model->beg_branch = '%';
						$model->end_branch = '_';
						$model->beg_client = '%';
						$model->end_client = '_';
						$model->client_cd = '%';
						$model->generate_date = date('Y-m-d H:i:s');
						$valid  = true;
					}
					else
					{
						$valid = false;
						//$model->addError('client_cd','Client tidak ditemukan');
						$model->error_msg = 'Client tidak ditemukan!';
					}	
				}
				else
				{
					if($model->client_cd)
					{
						//$clientFrom = $clientTo = $model->client_cd;
						$model->beg_rem = '%';
						$model->end_rem = '_';
						$model->beg_branch = '%';
						$model->end_branch = '_';
						$model->beg_client = $model->client_cd;
						$model->end_client = $model->client_cd;
						$model->generate_date = date('Y-m-d H:i:s');
						$valid  = true;
					}
					else
					{
						$valid = false;
						//$model->addError('client_cd','Client tidak ditemukan');
						$model->error_msg = 'Client tidak ditemukan!';
					}
				}
				
				if($valid)
				{
					$transaction;
					$model->cre_by = Yii::app()->user->id;
					$ip = Yii::app()->request->userHostAddress;
					if($ip=="::1")
						$ip = '127.0.0.1';
					$model->ip_address = $ip;
					if($model->client_type == 0)$mode = 1;
					else
						$mode = 3;
					
					$id= '%';
					$menuName = 'GEN TRADE CONF';
					if($model->executeSprGenTc() > 0){
						$valid = true;
					}else{
						$valid = false;
					}
					
					if($valid && $model->executeSpManyHeader(AConstant::INBOX_STAT_INS,$menuName,$transaction) > 0){
						$valid = true;
					}else{
						$valid = false;
					}
					if($valid && $model->executeSp($mode,$id,$transaction) > 0)
					{
						$valid = true;
					}else{
						$valid = false;
					}
				
					if($valid){
						$transaction->commit();
						$success = false; 
						if($model->client_cd && $model->client_cd != '%'){
							$generatedtc = Ttcdoc::model()->findAll(array('condition'=>"to_char(tc_date,'YYYY-MM-DD') = '$model->tc_date'
							and tc_type = 'CONGEN' and client_cd = '$model->client_cd' and tc_status = -1"));
						}else{
							$generatedtc = Ttcdoc::model()->findAll(array('condition'=>"to_char(tc_date,'YYYY-MM-DD') = '$model->tc_date' 
							and tc_type = 'CONGEN' and tc_status = -1"));
						}
					
						if($generatedtc && isset($generatedtc)){
							$success = true;
							
							if($success){
								foreach($generatedtc as $tc){
									if($success){
										$tc_clob_eng = $this->genTCeng($tc->client_cd, $tc->tc_date, '%', '%', Yii::app()->user->id);
										$len_clob_eng = strlen($tc_clob_eng);
										$tc_clob_ind = $this->genTCind($tc->client_cd, $tc->tc_date, '%', '%', Yii::app()->user->id);
										$len_clob_ind = strlen($tc_clob_ind);
										$tc_matrix_eng = $this->genTCengmatrix($tc->client_cd, $tc->tc_date, '%', '%', Yii::app()->user->id);
										$len_matrix_eng = strlen($tc_matrix_eng);
										$tc_matrix_ind = $this->genTCindmatrix($tc->client_cd, $tc->tc_date, '%', '%', Yii::app()->user->id);
										$len_matrix_ind = strlen($tc_matrix_ind);
										$maxlen = $len_clob_eng;
										if($maxlen < $len_clob_ind){
											$maxlen = $len_clob_ind;
										}
										if($maxlen < $len_matrix_eng){
											$maxlen = $len_matrix_eng;
										}
										if($maxlen < $len_matrix_ind){
											$maxlen = $len_matrix_ind;
										}
										$nloop = ceil($maxlen / 20000);
										
										if($nloop == 1){
											if($model->executeSpGenTcClob($tc->tc_id, $tc->tc_rev, $tc_clob_eng, $tc_clob_ind, $tc_matrix_eng, $tc_matrix_ind,0) > 0){
												$success = $success && true;
											}else{
												$success = false;
											}
										}else{
											for($n = 1; $n <= $nloop; $n++){
												if($n == 1){
													
													if($model->executeSpGenTcClob($tc->tc_id, $tc->tc_rev, substr($tc_clob_eng,0,20000), substr($tc_clob_ind,0,20000), substr($tc_matrix_eng,0,20000), substr($tc_matrix_ind,0,20000),0) > 0){
														$success = $success && true;
													}else{
														$success = false;
													}
												}else{
													if($model->executeSpGenTcClob($tc->tc_id, $tc->tc_rev, substr($tc_clob_eng,20000*($n-1),20000), substr($tc_clob_ind,20000*($n-1),20000), substr($tc_matrix_eng,20000*($n-1),20000), substr($tc_matrix_ind,20000*($n-1),20000),1) > 0){
														$success = $success && true;
													}else{
														$success = false;
													}
												}
											}
										}
										
										
									}else{
										$valid = false;
										$success = false;
										break;
									}
								}
							}
						}else{
							
							$valid = false;
							$success = false;
							//$model->addError('','Generating TC failed!');
							$model->error_msg = 'Client tidak ditemukan!';
							//$transaction->rollback();
						}
						
						if($success){
							//$transaction->commit();
							$model->error_msg = 'Successfully create Trade Confirmation!';
							//Yii::app()->user->setFlash('success', 'Successfully create Trade Confirmation');
							//$this->redirect(array('/contracting/ttcdoc/index'));
						}else{
							$model->error_msg = 'Client tidak ditemukan!';
							$model->executeRejectGentradingref($menuName,'Generate trade confirmation failed!');
							//$transaction->rollback();
						}
						
					}else{
						$transaction->rollback();
					}
				}
			}
	
			if(DateTime::createFromFormat('Y-m-d',$model->tc_date))$model->tc_date=DateTime::createFromFormat('Y-m-d',$model->tc_date)->format('d/m/Y');
		}
		$msg = $model->error_msg;
		$this->render('index',array(
					'model'=>$model,
					'isfirst'=>$isfirst,
					'msg'=>$msg
				));
		//$this->redirect(array('/contracting/ttcdoc/index'));
		
	}

	public function actionTestgentc(){
		$this->layout = '//layouts/blankspace';
	//	$model= Rtradeconf::model()->findAll(array('condition'=>"client_cd = 'REZA003R' and userid = 'AS'"));
	//	$model = Rtradeconf::model()->findAll(array('condition'=>"client_cd = 'ABID001R' and userid = 'AS'"));
		$model = Rtradeconf::model()->findAll(array('condition'=>"client_cd = 'TITU001M' and userid = 'IN'"));//sell
		$baseurl = Yii::app()->request->baseUrl;
		if($model){
			$tc = "
			<div>
				<div style=\"float: left; width: 60%;\">
					<h4>PT. DANASAKTI SECURITIES</h4>
					".$model[0]->brch_addr_1."<br />".$model[0]->brch_addr_2."<br/>
					".$model[0]->brch_addr_3."<br/>
					Telp : ".$model[0]->brch_phone."&emsp;Fax : ".$model[0]->brch_fax.($model[0]->dealing_phone?" Dealing : ".$model[0]->dealing_phone:'')."<br />
					NPWP&emsp;: &nbsp; ".$model[0]->no_ijin1."<br />
					<br />
					<table style='margin-left:-2%;line-height:1%;margin-top:-3%;' >
						<tr>
							<td width=\"40px\">ATT.</td>
							<td>: ".$model[0]->contact_pers."</td>
						</tr>
						<tr>
							<td></td>
							<td>&nbsp; ".$model[0]->def_addr_1."</td>
						</tr>
						<tr>
							<td></td>
							<td>&nbsp; ".$model[0]->def_addr_2."</td>
						</tr>
						<tr>
							<td></td>
							<td>&nbsp; ".$model[0]->def_addr_3."</td>
						</tr>
						<tr>
							<td>ZIP</td>
							<td>: ".$model[0]->post_cd."</td>
						</tr>
					</table>
					
				</div>
				<div style=\"float: right; width: 40%;\">
					
				<table style='margin-left:-5%;line-height:1%;' >
					<tr>
						<td colspan='3'><h4>TRADE CONFIRMATION</h4></td>
					</tr>
					<tr>
						<td width='100px' >Trade Date</td>
						<td  colspan='2' >: ".DateTime::createFromFormat('Y-m-d h:i:s',$model[0]->contr_dt)->format('d/m/Y')."</td>
					</tr>
					<tr>
						<td width='100px' >Settle Date</td>
						<td  colspan='2' >: ".DateTime::createFromFormat('Y-m-d h:i:s',$model[0]->due_dt_for_amt)->format('d/m/Y')."</td>
					</tr>
					<tr>
						<td width='100px' >Ref No.</td>
						<td  colspan='2' style='font-weight:bold'>: {tc_id}</td>
					</tr>
				</table>
				<br />
					
				<table style='margin-left:-5%;line-height:1%;' >
					<tr>
						<td colspan='2'>".($model[0]->client_title? ucwords(strtolower($model[0]->client_title)).'. ' : '').$model[0]->client_name."</td>
					</tr>
					<tr>
						<td>Client code</td>
						<td>: ".$model[0]->old_ic_num."&emsp; /".$model[0]->client_cd."</td>
					</tr>
					
					<tr>
						<td>Phone</td>
						<td>: ".(($model[0]->phone_num && (trim($model[0]->phone_num) != 'NA'))?$model[0]->phone_num : '').($model[0]->phone2_1?', '.$model[0]->phone2_1 : '').($model[0]->hand_phone1?', '.$model[0]->hand_phone1 : '');
						 	$tc=$tc." 
						</td>
					</tr>
					<tr>
						<td>Fax</td><td> : "; if($model[0]->fax_num){$tc = $tc.$model[0]->fax_num ; }$tc=$tc."</td>
					</tr>
					<tr>
						<td colspan='2'>";if($model[0]->e_mail1){$tc = $tc.$model[0]->e_mail1;}$tc = $tc."</td>
					</tr>
					<tr><td></td><td></td></tr>
				</table>
				
				
				";
				
			$tc = $tc."	
			
			</div>
			<br style=\"clear: both;\" />
			<div style=\"margin-top:-30px;\">
					As instructed, we have executed the following transaction(s) for your account:
					<table id=\"tc-table\" class=\"table-condensed\" style=\"border-collapse: collapse; border: none;\">
						<tr style=\"border-top: 1.5px solid;border-bottom: 1.5px solid;\">
							<td><strong>Share</strong></td>
							<td></td>
							<td></td>
							<td style=\"text-align: right;\"><strong>Quantity</strong></td>
							<td style=\"text-align: right;\"><strong>Price</strong></td>
							<td colspan=\"2\" style=\"text-align: right;\"><strong>Amount Buy</strong></td>
							<td colspan=\"2\" style=\"text-align: right;\"><strong>Amount Sell</strong></td>
						</tr>
						";
			foreach ($model as $row){
				$tc = $tc."
								<tr>
									<td>".$row->stk_cd."</td>
									<td colspan='2'>".$row->stk_name."</td>
									
									<td style=\"text-align: right;\">".number_format($row->qty)."</td>
									<td style=\"text-align: right;\">".number_format($row->price)."</td>
									<td style=\"width: 5%\"></td>
									<td style=\"text-align: right; width: 16%\">".number_format($row->b_val)."</td>
									<td style=\"width: 5%\"></td>
									<td style=\"text-align: right; width: 16%\">".number_format($row->j_val)."</td>
								</tr>";
			}
			$tc = $tc."
							<tr style=\"border-top: 1.5px solid;\">
								<td colspan=\"5\">Total Value</td>
								<td style=\"text-align: right;\"><strong>Rp</strong></td>
								<td style=\"text-align: right;font-weight:bold;\">".number_format($model[0]->sum_b_val)."</td>
								<td style=\"text-align: right;\"><strong>Rp</strong></td>
								<td style=\"text-align: right;font-weight:bold;\">".number_format($model[0]->sum_j_val)."</td>
							</tr>
							<tr>
								<td colspan=\"5\">Commission ".($model[0]->brok_perc/100)."%</td>
								<td style=\"text-align: right;\"></td>
								<td style=\"text-align: right;\">".number_format($model[0]->sum_b_comm)."</td>
								<td style=\"text-align: right;\"></td>
								<td style=\"text-align: right;\">".number_format($model[0]->sum_j_comm)."</td>
							</tr>
							<tr>
								<td colspan=\"5\">VAT</td>
								<td style=\"text-align: right;\"></td>
								<td style=\"text-align: right;\">".number_format($model[0]->sum_b_vat)."</td>
								<td style=\"text-align: right;\"></td>
								<td style=\"text-align: right;\">".number_format($model[0]->sum_j_vat)."</td>
							</tr>
							<tr>
								<td colspan=\"5\">Levy</td>
								<td style=\"text-align: right;\"></td>
								<td style=\"text-align: right;\">".number_format($model[0]->sum_b_levy)."</td>
								<td style=\"text-align: right;\"></td>
								<td style=\"text-align: right;\">".number_format($model[0]->sum_j_levy)."</td>
							</tr>";
			if ($model[0]->sum_j_pph != 0){
				$tc = $tc."
							<tr>
								<td colspan=\"5\">Sales Tax ".($model[0]->pph_perc/100)."%</td>
								<td style=\"text-align: right;\"></td>
								<td style=\"text-align: right;\">".number_format($model[0]->sum_b_pph)."</td>
								<td style=\"text-align: right;\"></td>
								<td style=\"text-align: right;\">".number_format($model[0]->sum_j_pph)."</td>
							</tr>";
			}
			if (($model[0]->sum_b_whpph23 != 0) || ($model[0]->sum_j_whpph23 != 0)){
				$tc = $tc."
							<tr>
								<td colspan=\"5\">Witholding Tax PPh 23 ".$model[0]->whpph23_perc."%</td>
								<td style=\"text-align: right;\"></td>
								<td style=\"text-align: right;\">".number_format($model[0]->sum_b_whpph23)."</td>
								<td style=\"text-align: right;\"></td>
								<td style=\"text-align: right;\">".number_format($model[0]->sum_j_whpph23)."</td>
							</tr>";
			}
			$tc = $tc."
							<tr style=\"border-top: 1.5px solid;border-bottom: 1.5px solid;\">
								<td colspan=\"5\">Total Net</td>
								<td style=\"text-align: right;\">Rp</td>
								<td style=\"text-align: right;\">".number_format($model[0]->sum_b_amt)."</td>
								<td style=\"text-align: right;\">Rp</td>
								<td style=\"text-align: right;\">".number_format($model[0]->sum_j_amt)."</td>
							</tr>
							<tr><td colspan=\"9\"></td></tr>";
			if ($model[0]->sum_b_amt > $model[0]->sum_j_amt){
				$tc = $tc."
							<tr style=\"border-bottom: 1.5px solid;\">
								<td colspan=\"5\"><strong>Payment due to us</strong></td>
								<td style=\"text-align: right;\"><strong>Rp</strong></td>
								<td style=\"text-align: right;font-weight:bold;\">".number_format($model[0]->sum_b_amt - $model[0]->sum_j_amt)."</td>
								<td style=\"text-align: right;\"></td>
								<td style=\"text-align: right;\"></td>
							</tr>";	
			}else{
				$tc = $tc."
							<tr style=\"border-bottom: 1.5px solid;\">
								<td colspan=\"5\"><strong>Payment due to you</strong></td>
								<td style=\"text-align: right;\"></td>
								<td style=\"text-align: right;font-weight:bold;\"></td>
								<td style=\"text-align: right;\"><strong>Rp</strong></td>
								<td style=\"text-align: right;font-weight:bold;\">".number_format($model[0]->sum_j_amt - $model[0]->sum_b_amt)."</td>
							</tr>";
			}
			/*
			if (($model[0]->sum_b_t3 + $model[0]->sum_j_t3) > 0){
				$tc = $tc."
							<tr>
								<td colspan=\"5\"><strong>Settlement Date T+".$model[0]->max_3plus."&emsp;".DateTime::createFromFormat('Y-m-d h:i:s',$model[0]->due_t3)->format('d/m/Y')." (".substr($model[0]->mrkt_t3,0,2).")</strong></td>
								<td style=\"text-align: right;\"><strong>Rp</strong></td>
								<td style=\"text-align: right;\"><strong>".(($model[0]->sum_b_t3 > $model[0]->sum_j_t3)?number_format($model[0]->sum_b_t3 - $model[0]->sum_j_t3) : '0')."</strong></td>
								<td style=\"text-align: right;\"></td>
								<td style=\"text-align: right;\"></td>
							</tr>";
			}
			if (($model[0]->sum_b_t2 + $model[0]->sum_j_t2) > 0){
				$tc = $tc."
							<tr>
								<td colspan=\"5\"><strong>Settlement Date T+2&emsp;".DateTime::createFromFormat('Y-m-d h:i:s',$model[0]->due_t2)->format('d/m/Y')." (".substr($model[0]->mrkt_t2,0,2).")</strong></td>
								<td style=\"text-align: right;\"><strong>Rp</strong></td>
								<td style=\"text-align: right;\"><strong>".(($model[0]->sum_b_t2 > $model[0]->sum_j_t2)?number_format($model[0]->sum_b_t2 - $model[0]->sum_j_t2) : '0')."</strong></td>
								<td style=\"text-align: right;\"></td>
								<td style=\"text-align: right;\"></td>
							</tr>";
			}
			if (($model[0]->sum_b_t1 + $model[0]->sum_j_t1) > 0){
				$tc = $tc."
							<tr>
								<td colspan=\"5\"><strong>Settlement Date T+1&emsp;".DateTime::createFromFormat('Y-m-d h:i:s',$model[0]->due_t1)->format('d/m/Y')." (".substr($model[0]->mrkt_t1,0,2).")</strong></td>
								<td style=\"text-align: right;\">Rp</td>
								<td style=\"text-align: right;\"><strong>".(($model[0]->sum_b_t1 > $model[0]->sum_j_t1)?number_format($model[0]->sum_b_t1 - $model[0]->sum_j_t1) : '0')."</strong></td>
								<td style=\"text-align: right;\"></td>
								<td style=\"text-align: right;\"></td>
							</tr>";
			}
			if (($model[0]->sum_b_t0 + $model[0]->sum_j_t0) > 0){
				$tc = $tc."
							<tr>
								<td colspan=\"5\">Settlement Date T+0&emsp;".DateTime::createFromFormat('Y-m-d h:i:s',$model[0]->contr_dt)->format('d/m/Y')." (".substr($model[0]->mrkt_t0,0,2).")</td>
								<td style=\"text-align: right;\"><strong>Rp</strong></td>
								<td style=\"text-align: right;\"><strong>".(($model[0]->sum_b_t0 > $model[0]->sum_j_t0)?number_format($model[0]->sum_b_t0 - $model[0]->sum_j_t0) : '0')."</strong></td>
								<td style=\"text-align: right;\"></td>
								<td style=\"text-align: right;\"></td>
							</tr>";
			}
			*/				
			$tc = $tc."
							<tr style=\"border-top: 1.5px solid;\"><td colspan=\"9\"></td></tr>
						
					</table>
			</div>
		
		
			<div style=\"clear: both; \"></div>
			<div>";
			$due_date = $model[0]->due_dt_for_amt;
			$sql = "Select GET_DUE_DATE(1, '$due_date') due_date from dual";
			$date = DAO::queryRowSql($sql);
			$due_date = $date['due_date'];
				//if($model[0]->bank_rdi_acct){
							if($model[0]->sum_b_amt > $model[0]->sum_j_amt){
								$tc = $tc."
									PLEASE TRANSFER THE FUND TO : CIMB NIAGA<br />
									<strong>INVESTOR ACCOUNT : ".$model[0]->client_name.", A/C ".$model[0]->bank_rdi_acct."<br />
									-->EFFECTIVE THE LATEST ON THE SETTLEMENT DATE (IN GOOD FUND AT 10:00 AM)</strong><br />
									PLEASE FAX THE TRANSFER SLIP TO 231-4880<br/>";	
							}
							if($model[0]->sum_j_amt > $model[0]->sum_b_amt){
								$tc = $tc."
									We will transfer to your Bank account for amount below :<br />"
									.DateTime::createFromFormat('Y-m-d H:i:s',$model[0]->due_dt_for_amt)->format('d/m/Y')."&emsp; if your bank account in CIMB NIAGA<br />"
								.DateTime::createFromFormat('Y-m-d H:i:s',$due_date)->format('d/m/Y')."&emsp; if your bank account in Other Bank <br /><br />";
							}
							
							
				//}
				/*
				else{
					$tc = $tc."
							<font style=\"text-decoration: underline;\">The following is our payment bank details</font><br />
							".$model[0]->nama_prsh."<br />
							".$model[0]->bank_name." A/C : ".$model[0]->brch_acct_num."<br/>";
				}
				*/
				$contract_dept = Sysparam::model()->find("param_id='TRADE CONFIRMATION' and param_Cd1='CON_DEPT'")->dstr1;
				$tc = $tc."
				- This statement will be considered correct if no discrepancies are reported within 24 hours.<br /><br />
				- This report is generated by system,for report sent by e-mail no signature required.<br />
			</div>
			<div style=\"clear: both; \"><br /><br /><br />
			
			<div>
				<div style=\"float: left; width: 30%;\">
					<p>Best Regards</p><br /><br />
					(".$contract_dept.")<br />
					Contract Dept 
					<br /><br />
					
				</div>
					<div style=\"float: left; width: 30%;\">
					<p>&emsp;</p><br /><br /> (".$model[0]->rem_name.")<br />
					Sales
					</div>
				<div style=\"float: right; width: 40%;\">
					<p align='center'>Reconfirmed By</p><br /><br />
					<p align='center'>(".$model[0]->client_name.")</p>
				</div>
			</div>
			
			<div style=\"float: left; width: 50%;\">
			<div style=\"float: left; width: 12%;\">
			<p align=\"justify\" style=\"padding-right:10px;font-size:8pt;line-height:120%\">Note :</p>
				</div>
				<div style=\"float: left; width: 88%;\">
					<p align=\"justify\" style=\"padding-right:10px;font-size:8pt;line-height:120%\">
							In connection with Rule No. V.D.10 concerning Know Your
							Customer (KYC) as issued by Capital Market and Financial
							Institution Supervisory Agency (Badan Pengawas Pasar Modal dan
							Lembaga Keuangan) ,you are kindly requested to<br /><br />
							immediately provide update on every changes and/or renewal of data
							and/or documents by contacting our Customer Relation Officer.
					</p>
				</div>
			</div>
			<div style=\"float: left; width: 50%;\">
				<div style=\"float: left; width: 3%;\">
				*
				</div>
				<div style=\"float: left; width: 97%;\">
				 <p align=\"justify\" style=\"font-size:8pt;line-height:120%;padding-right:30px;\">
					Sehubungan dengan Peraturan Badan Pengawas Pasar Modal dan
					Lembaga Keuangan No. V.D.10 tentang Prinsip Mengenal Nasabah
					(KYC), Anda dimohon dengan hormat untuk segera melakukan
					pengkinian data atas setiap perubahan dan/atau<br /><br />
					pembaharuan data dan/atau dokumen dengan menghubungi
					Customer Relation Officer kami.
				</p>
				</div>
			</div>
			<div style=\"clear: both; \"></div>
			";
		}else{
			$tc = "<h1>Data Not Found!</h1>";
		}
		/*
		$this->render('tc',array(
			'model'=>$model,
		));
		*/
		
		
		
		// mPDF
        $mPDF1 = Yii::app()->ePdf->mpdf();
		
		// Password protection ([privilege],[user_password],[owner_password])
		//$mPDF1->SetProtection(array(), 'abc123', '');
		
		$muser = $model[0]->userid;
		$gendate = DateTime::createFromFormat('Y-m-d H:i:s',$model[0]->generate_date)->format('d/m/Y H:i:s');
		$footer = "<div style=\"font-style: italic;\"><div style=\"float: left; width: 33%; text-align:left;\">Prepared by : $muser</div>
		<div style=\"float:left; width: 33%; text-align: center;\">$gendate</div>
		<div style=\"float: right; width: 33%; text-align: right;\">Page {PAGENO} of {nbpg}</div></div>"; 
		
		$mPDF1->SetHTMLFooter($footer);
 
        // Load a stylesheet
        $stylesheet = file_get_contents(Yii::getPathOfAlias('webroot').'/css/screen.css');
        $mPDF1->WriteHTML($stylesheet,1);
		$stylesheet2 = file_get_contents(Yii::getPathOfAlias('webroot').'/css/main.css');
        $mPDF1->WriteHTML($stylesheet2,1);
		$stylesheet3 = file_get_contents(Yii::getPathOfAlias('webroot').'/themes/bootstrap/css/small-scale.css');
        $mPDF1->WriteHTML($stylesheet3,1);
		$stylesheet4 = file_get_contents(Yii::getPathOfAlias('webroot').'/assets/4cdb976a/bootstrap/css/bootstrap.min.css');
        $mPDF1->WriteHTML($stylesheet4,1);
        $stylesheet5 = file_get_contents(Yii::getPathOfAlias('webroot').'/assets/4cdb976a/css/bootstrap-yii.css');
        $mPDF1->WriteHTML($stylesheet5,1);
		$stylesheet6 = file_get_contents(Yii::getPathOfAlias('webroot').'/assets/4cdb976a/css/jquery-ui-bootstrap.css');
        $mPDF1->WriteHTML($stylesheet6,1);
		
		$mPDF1->AddPage('','','1','','off');
        $mPDF1->WriteHTML($tc);
		//$mPDF1->AddPage('','','1','','off');
		//$mPDF1->WriteHTML($tc);		
		
        $mPDF1->Output('attachments/testTC5.pdf','I');
		/*
		$mail = new YiiMailer();
		//$mail->clearLayout();//if layout is already set in config
		$mail->setFrom('andreas@saranasistemsolusindo.com', 'Andreas');
		$mail->setTo('andreas.ak92@gmail.com');
		$mail->setSubject('Test Send TC');
		$mail->setBody('This message is computer generated.');
		$mail->setAttachment(array('attachments/export.sql'=>'SQL_1.sql','attachments/export2.sql'=>'SQL_2.sql'));
		if ($mail->send()) {
            Yii::app()->user->setFlash('success','Mail has been sent');
            Yii::log("Mail sent");
        } else {
            Yii::app()->user->setFlash('error','Error while sending email: '.$mail->getError());
            Yii::log("Mail Error");
        }
		*/
		
	}
	
	public function actionIndexprint()
	{
		$model = new Ttcdoc;
		$model->tc_date = date('d/m/Y');
		$model->client_type = 0;
		$model->brch_type = 0;
		$model->rem_type = 0;
		$model->tc_rev = 1;
		
		$valid = false;
		
		if(isset($_POST['Ttcdoc']))
		{
			$model->attributes=$_POST['Ttcdoc'];

			if(DateTime::createFromFormat('Y-m-d',$model->tc_date))$model->tc_date=DateTime::createFromFormat('Y-m-d',$model->tc_date)->format('d/m/Y');
		}
				
		$this->render('indexprint',array(
			'model'=>$model,
		));
		
	}
	
	public function actionPrintEng($tc_date, $client_cd, $brch_cd, $rem_cd, $cl_type){		
		if($client_cd == '0'){
			$client_cd = '%';
		}
		if($brch_cd == '0'){
			$brch_cd = '%';
		}
		if($rem_cd == '0'){
			$rem_cd = '%';
		}
		if($cl_type==''){
			$cl_type='%';
		}
		
		
		$this->layout = '//layouts/blankspace';
		$model = DAO::queryAllSql("select rowid, cre_by, cre_dt from T_TC_DOC where tc_date = to_date('$tc_date','DD/MM/YYYY') AND
				client_cd like '$client_cd' AND SUBSTR(CLIENT_CD,-1) like  '$cl_type' and brch_cd like '$brch_cd' AND rem_cd like '$rem_cd' AND tc_status = 0 order by client_cd");
		$mPDF1 = Yii::app()->ePdf->mpdf();
		if($model && isset($model)){
			/*
			$muser = $model[0]['cre_by'];
			//var_dump($model);
			//die();
			$gendate = DateTime::createFromFormat('Y-m-d H:i:s',$model[0]['cre_dt'])->format('d/m/Y H:i:s');
			//$gendate = date('d/m/Y H:i:s');
			$footer = "<div style=\"font-style: italic;\"><div style=\"float: left; width: 33%; text-align:left;\">Prepared by : $muser</div>
			<div style=\"float:left; width: 33%; text-align: center;\">$gendate</div>
			<div style=\"float: right; width: 33%; text-align: right;\">Page {PAGENO} of {nbpg}</div></div>"; 
			
			$mPDF1->SetHTMLFooter($footer);
	 		*/
	        // Load a stylesheet
	        $stylesheet = file_get_contents(Yii::getPathOfAlias('webroot').'/css/screen.css');
	        $mPDF1->WriteHTML($stylesheet,1);
			$stylesheet2 = file_get_contents(Yii::getPathOfAlias('webroot').'/css/main.css');
	        $mPDF1->WriteHTML($stylesheet2,1);
			$stylesheet3 = file_get_contents(Yii::getPathOfAlias('webroot').'/themes/bootstrap/css/small-scale.css');
	        $mPDF1->WriteHTML($stylesheet3,1);
			$stylesheet4 = file_get_contents(Yii::getPathOfAlias('webroot').'/assets/4cdb976a/bootstrap/css/bootstrap.min.css');
	        $mPDF1->WriteHTML($stylesheet4,1);
	        $stylesheet5 = file_get_contents(Yii::getPathOfAlias('webroot').'/assets/4cdb976a/css/bootstrap-yii.css');
	        $mPDF1->WriteHTML($stylesheet5,1);
			$stylesheet6 = file_get_contents(Yii::getPathOfAlias('webroot').'/assets/4cdb976a/css/jquery-ui-bootstrap.css');
	        $mPDF1->WriteHTML($stylesheet6,1);
			
			foreach($model as $row){
				$rowid = $row['rowid'];
				$gettc = Ttcdoc::model()->find(array('condition'=>"rowid = '$rowid'"));
				$tc = $gettc->tc_matrix_eng;
				$muser = $row['cre_by'];
				//var_dump($model);
				//die();
				$gendate = DateTime::createFromFormat('Y-m-d H:i:s',$row['cre_dt'])->format('d/m/Y H:i:s');
				//$gendate = date('d/m/Y H:i:s');
				$footer = "<div><div style=\"float: left; width: 33%; text-align:left;\">Prepared by : $muser</div>
				<div style=\"float:left; width: 33%; text-align: center;\">$gendate</div>
				<div style=\"float: right; width: 33%; text-align: right;\">Page {PAGENO} of {nbpg}</div></div>"; 
				
				$mPDF1->AddPage('','','1','','off');
				$mPDF1->SetHTMLFooter($footer);
				
	        	$mPDF1->WriteHTML(stream_get_contents($tc));	
			}
		}else{
			$mPDF1->WriteHTML('<h2>No Data Found!</h2>');
		}
			
		$mPDF1->Output();
	}

	public function actionPrintInd($tc_date, $client_cd, $brch_cd, $rem_cd,$cl_type){		
		if($client_cd == '0'){
			$client_cd = '%';
		}
		if($brch_cd == '0'){
			$brch_cd = '%';
		}
		if($rem_cd == '0'){
			$rem_cd = '%';
		}
		if($cl_type==''){
			$cl_type='%';
		}
		$this->layout = '//layouts/blankspace';
		$model = DAO::queryAllSql("select rowid, cre_by, cre_dt from T_TC_DOC where tc_date = to_date('$tc_date','DD/MM/YYYY') AND
				client_cd like '$client_cd' AND  SUBSTR(CLIENT_CD,-1) like  '$cl_type' and brch_cd like '$brch_cd' AND rem_cd like '$rem_cd' AND tc_status = 0 order by client_cd");
		$mPDF1 = Yii::app()->ePdf->mpdf();
		if($model && isset($model)){
			/*
			$muser = $model[0]['cre_by'];
			$gendate = DateTime::createFromFormat('Y-m-d H:i:s',$model[0]['cre_dt'])->format('d/m/Y H:i:s');
			//$gendate = date('d/m/Y H:i:s');
			$footer = "<div style=\"font-style: italic;\"><div style=\"float: left; width: 33%; text-align:left;\">Disiapkan oleh : $muser</div>
			<div style=\"float:left; width: 33%; text-align: center;\">$gendate</div>
			<div style=\"float: right; width: 33%; text-align: right;\">Halaman {PAGENO}</div></div>"; 
			
			$mPDF1->SetHTMLFooter($footer);
			 * 
			 */
	 
	        // Load a stylesheet
	        $stylesheet = file_get_contents(Yii::getPathOfAlias('webroot').'/css/screen.css');
	        $mPDF1->WriteHTML($stylesheet,1);
			$stylesheet2 = file_get_contents(Yii::getPathOfAlias('webroot').'/css/main.css');
	        $mPDF1->WriteHTML($stylesheet2,1);
			$stylesheet3 = file_get_contents(Yii::getPathOfAlias('webroot').'/themes/bootstrap/css/small-scale.css');
	        $mPDF1->WriteHTML($stylesheet3,1);
			$stylesheet4 = file_get_contents(Yii::getPathOfAlias('webroot').'/assets/4cdb976a/bootstrap/css/bootstrap.min.css');
	        $mPDF1->WriteHTML($stylesheet4,1);
	        $stylesheet5 = file_get_contents(Yii::getPathOfAlias('webroot').'/assets/4cdb976a/css/bootstrap-yii.css');
	        $mPDF1->WriteHTML($stylesheet5,1);
			$stylesheet6 = file_get_contents(Yii::getPathOfAlias('webroot').'/assets/4cdb976a/css/jquery-ui-bootstrap.css');
	        $mPDF1->WriteHTML($stylesheet6,1);
			
			foreach($model as $row){
				$rowid = $row['rowid'];
				$gettc = Ttcdoc::model()->find(array('condition'=>"rowid = '$rowid'"));
				$tc = $gettc->tc_matrix_ind;
				
				$muser = $row['cre_by'];
				$gendate = DateTime::createFromFormat('Y-m-d H:i:s',$row['cre_dt'])->format('d/m/Y H:i:s');
				//$gendate = date('d/m/Y H:i:s');
				$footer = "<div><div style=\"float: left; width: 33%; text-align:left;\">Disiapkan oleh : $muser</div>
				<div style=\"float:left; width: 33%; text-align: center;\">$gendate</div>
				<div style=\"float: right; width: 33%; text-align: right;\">Halaman {PAGENO}</div></div>"; 
				
				$mPDF1->AddPage('','','1','','off');
				$mPDF1->SetHTMLFooter($footer);
				
	        	$mPDF1->WriteHTML(stream_get_contents($tc));	
			}
		}else{
			$mPDF1->WriteHTML('<h2>Data Tidak Ditemukan!</h2>');
		}
			
		$mPDF1->Output();
	}
	
	public function actionAjxGetClientList()
	{
		$resp['status']  = 'error';
		
		$client_cd = array();
		
		if(isset($_POST['tc_date']))
		{
			$tc_date = $_POST['tc_date'];
			$model = Tcontracts::model()->findAll(array('select'=>'DISTINCT client_cd','condition'=>"contr_dt = TO_DATE('$tc_date','DD/MM/YYYY') AND contr_stat <> 'C'",'order'=>'client_cd'));
			
			foreach($model as $row)
			{
				$client_cd[] = $row->client_cd;
			}
			$resp['status'] = 'success';
		}
		
		$resp['content'] = array('client_cd'=>$client_cd);
		echo json_encode($resp);
	}
	
	public function actionAjxGetClientList2()
	{
		$resp['status']  = 'error';
		
		$client_cd = array();
		
		if(isset($_POST['tc_date']))
		{
			$tc_date = $_POST['tc_date'];
			$model = Ttcdoc::model()->findAll(array('select'=>'DISTINCT client_cd','condition'=>"tc_date = TO_DATE('$tc_date','DD/MM/YYYY') AND tc_status = 0",'order'=>'client_cd'));
			
			foreach($model as $row)
			{
				$client_cd[] = $row->client_cd;
			}
			$resp['status'] = 'success';
		}
		
		$resp['content'] = array('client_cd'=>$client_cd);
		echo json_encode($resp);
	}
	
	public function actionAjxGetBrchList()
	{
		$resp['status']  = 'error';
		
		$brch_cd = array();
		
		if(isset($_POST['tc_date']))
		{
			$tc_date = $_POST['tc_date'];
			$model = Ttcdoc::model()->findAll(array('select'=>'DISTINCT brch_cd','condition'=>"tc_date = TO_DATE('$tc_date','DD/MM/YYYY') AND tc_status = 0",'order'=>'brch_cd'));
			
			foreach($model as $row)
			{
				$brch_cd[] = $row->brch_cd;
			}
			$resp['status'] = 'success';
		}
		
		$resp['content'] = array('brch_cd'=>$brch_cd);
		echo json_encode($resp);
	}
	
	public function actionAjxGetRemList()
	{
		$resp['status']  = 'error';
		
		$rem_cd = array();
		
		if(isset($_POST['tc_date']))
		{
			$tc_date = $_POST['tc_date'];
			$model = Ttcdoc::model()->findAll(array('select'=>'DISTINCT rem_cd','condition'=>"tc_date = TO_DATE('$tc_date','DD/MM/YYYY') AND tc_status = 0",'order'=>'rem_cd'));
			
			foreach($model as $row)
			{
				$rem_cd[] = $row->rem_cd;
			}
			$resp['status'] = 'success';
		}
		
		$resp['content'] = array('rem_cd'=>$rem_cd);
		echo json_encode($resp);
	}
}