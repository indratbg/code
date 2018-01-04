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
				<div style=\"float: left; width: 50%;\">
					<p><img src=\"".$baseurl."/images/yj.jpg\" width=\"220px\" ></p>
					".$model[0]->brch_addr_1."<br />".$model[0]->brch_addr_2."<br/>
					".$model[0]->brch_addr_3."<br/>
					Phone : ".$model[0]->brch_phone."&emsp;Fax : ".$model[0]->brch_fax."<br />
					<br />
					ATT :&emsp;".$model[0]->contact_pers."<br />
					&emsp;&emsp;&nbsp;&nbsp;&emsp;".$model[0]->def_addr_1."<br />
					&emsp;&emsp;&nbsp;&nbsp;&emsp;".$model[0]->def_addr_2."<br />
					&emsp;&emsp;&nbsp;&nbsp;&emsp;".$model[0]->def_addr_3."<br />
					ZIP &nbsp;:&emsp;".$model[0]->post_cd."<br />
				</div>
				<div style=\"float: right; width: 50%;\">
					<div style=\"border: 1.5px solid;background: #ECE8D8; border-radius: 0.5em; padding: -4px;\">
						<div style=\"text-align: center; font-size: 24px; padding: 10px; font-weight: bold;\">
							Trade Confirmation
						</div>
						<div style=\"border-top: 1.5px solid; background: #ffffff; border-radius: 0.7em; text-align: center; padding: 5px 7px 7px 7px;\">
							".$model[0]->brch_name." Branch
						</div>
					</div>
					No. {tc_id}<br />
					".($model[0]->client_title? ucwords(strtolower($model[0]->client_title)).'. ' : '').$model[0]->client_name."<br />
					Date &emsp;&emsp;&emsp; :&emsp;".DateTime::createFromFormat('Y-m-d h:i:s',$model[0]->contr_dt)->format('d/m/Y')."<br />
					Client Code :&emsp;".$model[0]->client_cd."<br />
					Phone &emsp;&emsp;&nbsp;&nbsp;:&emsp;".(($model[0]->phone_num && (trim($model[0]->phone_num) != 'NA'))?$model[0]->phone_num : '').($model[0]->phone2_1?', '.$model[0]->phone2_1 : '').($model[0]->hand_phone1?', '.$model[0]->hand_phone1 : '')."<br />";
			if($model[0]->fax_num){
				$tc = $tc."Fax &emsp;&emsp;&emsp;&nbsp;&nbsp; :&emsp;".$model[0]->fax_num."<br />";}
			if($model[0]->e_mail1){
				$tc = $tc."<font style=\"color: blue\">via e-mail</font><br />
					E-mail &emsp;&emsp;&nbsp;&nbsp;:&emsp;".$model[0]->e_mail1."<br />";}
			$tc = $tc."	
				</div>
			</div>
			<br style=\"clear: both;\" />
			<div>
					As instructed, we have executed the following transaction(s) for your account:
					<table id=\"tc-table\" class=\"table-condensed\" style=\"border-collapse: collapse; border: none;\">
						<tr style=\"background: #ECE8D8;border: 1.5px solid;\">
							<td><strong>Share</strong></td>
							<td><strong>L/F</strong></td>
							<td style=\"text-align: right;\"><strong>Lot</strong></td>
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
									<td>".$row->status."</td>
									<td style=\"text-align: right;\">".number_format($row->lot_size)."</td>
									<td style=\"text-align: right;\">".number_format($row->qty)."</td>
									<td style=\"text-align: right;\">".number_format($row->price)."</td>
									<td style=\"width: 5%\"></td>
									<td style=\"text-align: right; width: 16%\">".number_format($row->b_val)."</td>
									<td style=\"width: 5%\"></td>
									<td style=\"text-align: right; width: 16%\">".number_format($row->j_val)."</td>
								</tr>";
			}
			$tc = $tc."
							<tr style=\"background: #ECE8D8;border: 1.5px solid;\">
								<td colspan=\"5\">Total Value</td>
								<td style=\"text-align: right;\">Rp</td>
								<td style=\"text-align: right;\">".number_format($model[0]->sum_b_val)."</td>
								<td style=\"text-align: right;\">Rp</td>
								<td style=\"text-align: right;\">".number_format($model[0]->sum_j_val)."</td>
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
							<tr style=\"background: #ECE8D8;border: 1.5px solid;\">
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
								<td colspan=\"5\">Debt</td>
								<td style=\"text-align: right;\">Rp</td>
								<td style=\"text-align: right;\">".number_format($model[0]->sum_b_amt - $model[0]->sum_j_amt)."</td>
								<td style=\"text-align: right;\">Rp</td>
								<td style=\"text-align: right;\">".'0'."</td>
							</tr>";	
			}else{
				$tc = $tc."
							<tr style=\"border-bottom: 1.5px solid;\">
								<td colspan=\"5\">Credit</td>
								<td style=\"text-align: right;\">Rp</td>
								<td style=\"text-align: right;\">".'0'."</td>
								<td style=\"text-align: right;\">Rp</td>
								<td style=\"text-align: right;\">".number_format($model[0]->sum_j_amt - $model[0]->sum_b_amt)."</td>
							</tr>";
			}
			if (($model[0]->sum_b_t3 + $model[0]->sum_j_t3) > 0){
				$tc = $tc."
							<tr>
								<td colspan=\"5\">Settlement Date T+".$model[0]->max_3plus."&emsp;".DateTime::createFromFormat('Y-m-d h:i:s',$model[0]->due_t3)->format('d/m/Y')." (".substr($model[0]->mrkt_t3,0,2).")</td>
								<td style=\"text-align: right;\">Rp</td>
								<td style=\"text-align: right;\">".(($model[0]->sum_b_t3 > $model[0]->sum_j_t3)?number_format($model[0]->sum_b_t3 - $model[0]->sum_j_t3) : '0')."</td>
								<td style=\"text-align: right;\">Rp</td>
								<td style=\"text-align: right;\">".(($model[0]->sum_j_t3 > $model[0]->sum_b_t3)?number_format($model[0]->sum_j_t3 - $model[0]->sum_b_t3) : '0')."</td>
							</tr>";
			}
			if (($model[0]->sum_b_t2 + $model[0]->sum_j_t2) > 0){
				$tc = $tc."
							<tr>
								<td colspan=\"5\">Settlement Date T+2&emsp;".DateTime::createFromFormat('Y-m-d h:i:s',$model[0]->due_t2)->format('d/m/Y')." (".substr($model[0]->mrkt_t2,0,2).")</td>
								<td style=\"text-align: right;\">Rp</td>
								<td style=\"text-align: right;\">".(($model[0]->sum_b_t2 > $model[0]->sum_j_t2)?number_format($model[0]->sum_b_t2 - $model[0]->sum_j_t2) : '0')."</td>
								<td style=\"text-align: right;\">Rp</td>
								<td style=\"text-align: right;\">".(($model[0]->sum_j_t2 > $model[0]->sum_b_t2)?number_format($model[0]->sum_j_t2 - $model[0]->sum_b_t2) : '0')."</td>
							</tr>";
			}
			if (($model[0]->sum_b_t1 + $model[0]->sum_j_t1) > 0){
				$tc = $tc."
							<tr>
								<td colspan=\"5\">Settlement Date T+1&emsp;".DateTime::createFromFormat('Y-m-d h:i:s',$model[0]->due_t1)->format('d/m/Y')." (".substr($model[0]->mrkt_t1,0,2).")</td>
								<td style=\"text-align: right;\">Rp</td>
								<td style=\"text-align: right;\">".(($model[0]->sum_b_t1 > $model[0]->sum_j_t1)?number_format($model[0]->sum_b_t1 - $model[0]->sum_j_t1) : '0')."</td>
								<td style=\"text-align: right;\">Rp</td>
								<td style=\"text-align: right;\">".(($model[0]->sum_j_t1 > $model[0]->sum_b_t1)?number_format($model[0]->sum_j_t1 - $model[0]->sum_b_t1) : '0')."</td>
							</tr>";
			}
			if (($model[0]->sum_b_t0 + $model[0]->sum_j_t0) > 0){
				$tc = $tc."
							<tr>
								<td colspan=\"5\">Settlement Date T+0&emsp;".DateTime::createFromFormat('Y-m-d h:i:s',$model[0]->contr_dt)->format('d/m/Y')." (".substr($model[0]->mrkt_t0,0,2).")</td>
								<td style=\"text-align: right;\">Rp</td>
								<td style=\"text-align: right;\">".(($model[0]->sum_b_t0 > $model[0]->sum_j_t0)?number_format($model[0]->sum_b_t0 - $model[0]->sum_j_t0) : '0')."</td>
								<td style=\"text-align: right;\">Rp</td>
								<td style=\"text-align: right;\">".(($model[0]->sum_j_t0 > $model[0]->sum_b_t0)?number_format($model[0]->sum_j_t0 - $model[0]->sum_b_t0) : '0')."</td>
							</tr>";
			}
			$tc = $tc."
							<tr style=\"border-top: 1.5px solid;\"><td colspan=\"9\"></td></tr>
						
					</table>
			</div>
			<div>
				
					Any discrepancy should be reported within 1 (one) business day after the above transaction date,<br />
					or we will consider the above information correct. Thank you for your attention.<br />
					<br />
					Especially for customer's account at ".$model[0]->bank_rdi." :<br />
					* The latest payment of buying transaction from customer on
					".((($model[0]->sum_b_t3 + $model[0]->sum_j_t3) > 0)?'T+3 ('.substr($model[0]->mrkt_t3,0,2).')' : '').
					((($model[0]->sum_b_t2 + $model[0]->sum_j_t2) > 0)?'T+2 ('.substr($model[0]->mrkt_t2,0,2).')' : '').
					((($model[0]->sum_b_t1 + $model[0]->sum_j_t1) > 0)?'T+1 ('.substr($model[0]->mrkt_t1,0,2).')' : '').
					((($model[0]->sum_b_t0 + $model[0]->sum_j_t0) > 0)?'T+0 ('.substr($model[0]->mrkt_t0,0,2).')' : '')."
					at 11.30 am (in good fund)<br />
					* The latest payment of selling transaction to customer on
					".((($model[0]->sum_b_t3 + $model[0]->sum_j_t3) > 0)?'T+3 ('.substr($model[0]->mrkt_t3,0,2).')' : '').
					((($model[0]->sum_b_t2 + $model[0]->sum_j_t2) > 0)?'T+2 ('.substr($model[0]->mrkt_t2,0,2).')' : '').
					((($model[0]->sum_b_t1 + $model[0]->sum_j_t1) > 0)?'T+1 ('.substr($model[0]->mrkt_t1,0,2).')' : '').
					((($model[0]->sum_b_t0 + $model[0]->sum_j_t0) > 0)?'T+0 ('.substr($model[0]->mrkt_t0,0,2).')' : '')."
					at 5 pm
				
			</div>
			<div style=\"clear: both; \"><br /></div>
			<div>
				<div style=\"text-align: center; float: left; width: 55%;\">";
			if($model[0]->bank_rdi_acct){
						if($model[0]->sum_b_amt > $model[0]->sum_j_amt){
							$tc = $tc."
								<font style=\"text-decoration: underline;\">Please transfer the fund to Investor Account (in good fund at 11:30 AM)</font><br />";	
						}
						if($model[0]->sum_j_amt > $model[0]->sum_b_amt){
							$tc = $tc."
								<font style=\"text-decoration: underline;\">We will transfer to your Investor Account</font><br />";
						}
						$tc = $tc.
						$model[0]->rdi_name."<br />
						".$model[0]->bank_rdi." : ".$model[0]->bank_rdi_acct;
			}else{
				$tc = $tc."
						<font style=\"text-decoration: underline;\">The following is our payment bank details</font><br />
						".$model[0]->nama_prsh."<br />
						".$model[0]->bank_name." A/C : ".$model[0]->brch_acct_num;
			}
			$tc = $tc."
				</div>
				<div style=\"text-align: center; float: right; width: 45%;\">";
			if($model[0]->bank_rdi_acct){	
						if($model[0]->sum_j_amt > $model[0]->sum_b_amt){
							$tc = $tc."
								<font style=\"text-decoration: underline;\">Your Bank Account</font><br />
								".$model[0]->client_bank_name."<br />
								".$model[0]->client_bank." A/C : ".$model[0]->client_bank_acct;
						}
			}
			$tc = $tc."
				</div>
			</div>
			<div style=\"clear: both; \"><br /></div>
			<div>
				<div style=\"float: left; width: 60%;\">
					Equity Sales,<br />
					".$model[0]->rem_name."<br />
					<br /><br />
					NPWP : ".$model[0]->no_ijin1."<br />
					PKP &emsp;: ".$model[0]->no_ijin1."<br /><br />
					This is a computer generated advise. No signature is required.
				</div>
				<div style=\"float: right; width: 40%;\">
					Confirmed by,<br />
					".$model[0]->nama_prsh."
				</div>
			</div>
			<div style=\"clear: both; \"></div>
			";
		}else{
			$tc = "
			<h1>".$client_cd." : Data Not Found!</h1>";
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
				<div style=\"float: left; width: 50%;\">
					<h4>PT. LAUTANDHANA SECURINDO</h4>
					".$model[0]->brch_addr_1."<br />".$model[0]->brch_addr_2."<br/>
					".$model[0]->brch_addr_3."<br/>
					Phone : ".$model[0]->brch_phone."&emsp;Fax : ".$model[0]->brch_fax."<br />
					<br />
					ATT :&emsp;".$model[0]->contact_pers."<br />
					&emsp;&emsp;&nbsp;&nbsp;&emsp;".$model[0]->def_addr_1."<br />
					&emsp;&emsp;&nbsp;&nbsp;&emsp;".$model[0]->def_addr_2."<br />
					&emsp;&emsp;&nbsp;&nbsp;&emsp;".$model[0]->def_addr_3."<br />
					ZIP &nbsp;:&emsp;".$model[0]->post_cd."<br />
				</div>
				<div style=\"float: right; width: 50%;\">
					<h4>TRADE CONFIRMATION</h4>
					".$model[0]->brch_name." Branch<br />
					No. {tc_id}<br /><br />
					".($model[0]->client_title? ucwords(strtolower($model[0]->client_title)).'. ' : '').$model[0]->client_name."<br />
					Date &emsp;&emsp;&emsp; :&emsp;".DateTime::createFromFormat('Y-m-d h:i:s',$model[0]->contr_dt)->format('d/m/Y')."<br />
					Client Code :&emsp;".$model[0]->client_cd."<br />
					Phone &emsp;&emsp;&nbsp;&nbsp;:&emsp;".(($model[0]->phone_num && (trim($model[0]->phone_num) != 'NA'))?$model[0]->phone_num : '').($model[0]->phone2_1?', '.$model[0]->phone2_1 : '').($model[0]->hand_phone1?', '.$model[0]->hand_phone1 : '')."<br />";
			if($model[0]->fax_num){
				$tc = $tc."Fax &emsp;&emsp;&emsp;&nbsp;&nbsp; :&emsp;".$model[0]->fax_num."<br />";}
			if($model[0]->e_mail1){
				$tc = $tc."
					E-mail &emsp;&emsp;&nbsp;&nbsp;:&emsp;".$model[0]->e_mail1."<br />";}
			$tc = $tc."	
				</div>
			</div>
			<br style=\"clear: both;\" />
			<div>
					As instructed, we have executed the following transaction(s) for your account:
					<table id=\"tc-table\" class=\"table-condensed\" style=\"border-collapse: collapse; border: none;\">
						<tr style=\"border-top: 1.5px solid;border-bottom: 1.5px solid;\">
							<td><strong>Share</strong></td>
							<td><strong>L/F</strong></td>
							<td style=\"text-align: right;\"><strong>Lot</strong></td>
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
									<td>".$row->status."</td>
									<td style=\"text-align: right;\">".number_format($row->lot_size)."</td>
									<td style=\"text-align: right;\">".number_format($row->qty)."</td>
									<td style=\"text-align: right;\">".number_format($row->price)."</td>
									<td style=\"width: 5%\"></td>
									<td style=\"text-align: right; width: 16%\">".number_format($row->b_val)."</td>
									<td style=\"width: 5%\"></td>
									<td style=\"text-align: right; width: 16%\">".number_format($row->j_val)."</td>
								</tr>";
			}
			$tc = $tc."
							<tr style=\"border-top: 1.5px solid;border-bottom: 1.5px solid;\">
								<td colspan=\"5\">Total Value</td>
								<td style=\"text-align: right;\">Rp</td>
								<td style=\"text-align: right;\">".number_format($model[0]->sum_b_val)."</td>
								<td style=\"text-align: right;\">Rp</td>
								<td style=\"text-align: right;\">".number_format($model[0]->sum_j_val)."</td>
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
								<td colspan=\"5\">Debt</td>
								<td style=\"text-align: right;\">Rp</td>
								<td style=\"text-align: right;\">".number_format($model[0]->sum_b_amt - $model[0]->sum_j_amt)."</td>
								<td style=\"text-align: right;\">Rp</td>
								<td style=\"text-align: right;\">".'0'."</td>
							</tr>";	
			}else{
				$tc = $tc."
							<tr style=\"border-bottom: 1.5px solid;\">
								<td colspan=\"5\">Credit</td>
								<td style=\"text-align: right;\">Rp</td>
								<td style=\"text-align: right;\">".'0'."</td>
								<td style=\"text-align: right;\">Rp</td>
								<td style=\"text-align: right;\">".number_format($model[0]->sum_j_amt - $model[0]->sum_b_amt)."</td>
							</tr>";
			}
			if (($model[0]->sum_b_t3 + $model[0]->sum_j_t3) > 0){
				$tc = $tc."
							<tr>
								<td colspan=\"5\">Settlement Date T+".$model[0]->max_3plus."&emsp;".DateTime::createFromFormat('Y-m-d h:i:s',$model[0]->due_t3)->format('d/m/Y')." (".substr($model[0]->mrkt_t3,0,2).")</td>
								<td style=\"text-align: right;\">Rp</td>
								<td style=\"text-align: right;\">".(($model[0]->sum_b_t3 > $model[0]->sum_j_t3)?number_format($model[0]->sum_b_t3 - $model[0]->sum_j_t3) : '0')."</td>
								<td style=\"text-align: right;\">Rp</td>
								<td style=\"text-align: right;\">".(($model[0]->sum_j_t3 > $model[0]->sum_b_t3)?number_format($model[0]->sum_j_t3 - $model[0]->sum_b_t3) : '0')."</td>
							</tr>";
			}
			if (($model[0]->sum_b_t2 + $model[0]->sum_j_t2) > 0){
				$tc = $tc."
							<tr>
								<td colspan=\"5\">Settlement Date T+2&emsp;".DateTime::createFromFormat('Y-m-d h:i:s',$model[0]->due_t2)->format('d/m/Y')." (".substr($model[0]->mrkt_t2,0,2).")</td>
								<td style=\"text-align: right;\">Rp</td>
								<td style=\"text-align: right;\">".(($model[0]->sum_b_t2 > $model[0]->sum_j_t2)?number_format($model[0]->sum_b_t2 - $model[0]->sum_j_t2) : '0')."</td>
								<td style=\"text-align: right;\">Rp</td>
								<td style=\"text-align: right;\">".(($model[0]->sum_j_t2 > $model[0]->sum_b_t2)?number_format($model[0]->sum_j_t2 - $model[0]->sum_b_t2) : '0')."</td>
							</tr>";
			}
			if (($model[0]->sum_b_t1 + $model[0]->sum_j_t1) > 0){
				$tc = $tc."
							<tr>
								<td colspan=\"5\">Settlement Date T+1&emsp;".DateTime::createFromFormat('Y-m-d h:i:s',$model[0]->due_t1)->format('d/m/Y')." (".substr($model[0]->mrkt_t1,0,2).")</td>
								<td style=\"text-align: right;\">Rp</td>
								<td style=\"text-align: right;\">".(($model[0]->sum_b_t1 > $model[0]->sum_j_t1)?number_format($model[0]->sum_b_t1 - $model[0]->sum_j_t1) : '0')."</td>
								<td style=\"text-align: right;\">Rp</td>
								<td style=\"text-align: right;\">".(($model[0]->sum_j_t1 > $model[0]->sum_b_t1)?number_format($model[0]->sum_j_t1 - $model[0]->sum_b_t1) : '0')."</td>
							</tr>";
			}
			if (($model[0]->sum_b_t0 + $model[0]->sum_j_t0) > 0){
				$tc = $tc."
							<tr>
								<td colspan=\"5\">Settlement Date T+0&emsp;".DateTime::createFromFormat('Y-m-d h:i:s',$model[0]->contr_dt)->format('d/m/Y')." (".substr($model[0]->mrkt_t0,0,2).")</td>
								<td style=\"text-align: right;\">Rp</td>
								<td style=\"text-align: right;\">".(($model[0]->sum_b_t0 > $model[0]->sum_j_t0)?number_format($model[0]->sum_b_t0 - $model[0]->sum_j_t0) : '0')."</td>
								<td style=\"text-align: right;\">Rp</td>
								<td style=\"text-align: right;\">".(($model[0]->sum_j_t0 > $model[0]->sum_b_t0)?number_format($model[0]->sum_j_t0 - $model[0]->sum_b_t0) : '0')."</td>
							</tr>";
			}
			$tc = $tc."
							<tr style=\"border-top: 1.5px solid;\"><td colspan=\"9\"></td></tr>
						
					</table>
			</div>
			<div>
				
					Any discrepancy should be reported within 1 (one) business day after the above transaction date,<br />
					or we will consider the above information correct. Thank you for your attention.<br />
					<br />
					Especially for customer's account at ".$model[0]->bank_rdi." :<br />
					* The latest payment of buying transaction from customer on
					".((($model[0]->sum_b_t3 + $model[0]->sum_j_t3) > 0)?'T+3 ('.substr($model[0]->mrkt_t3,0,2).')' : '').
					((($model[0]->sum_b_t2 + $model[0]->sum_j_t2) > 0)?'T+2 ('.substr($model[0]->mrkt_t2,0,2).')' : '').
					((($model[0]->sum_b_t1 + $model[0]->sum_j_t1) > 0)?'T+1 ('.substr($model[0]->mrkt_t1,0,2).')' : '').
					((($model[0]->sum_b_t0 + $model[0]->sum_j_t0) > 0)?'T+0 ('.substr($model[0]->mrkt_t0,0,2).')' : '')."
					at 11.30 am (in good fund)<br />
					* The latest payment of selling transaction to customer on
					".((($model[0]->sum_b_t3 + $model[0]->sum_j_t3) > 0)?'T+3 ('.substr($model[0]->mrkt_t3,0,2).')' : '').
					((($model[0]->sum_b_t2 + $model[0]->sum_j_t2) > 0)?'T+2 ('.substr($model[0]->mrkt_t2,0,2).')' : '').
					((($model[0]->sum_b_t1 + $model[0]->sum_j_t1) > 0)?'T+1 ('.substr($model[0]->mrkt_t1,0,2).')' : '').
					((($model[0]->sum_b_t0 + $model[0]->sum_j_t0) > 0)?'T+0 ('.substr($model[0]->mrkt_t0,0,2).')' : '')."
					at 5 pm
				
			</div>
			<div style=\"clear: both; \"><br /></div>
			<div>
				<div style=\"text-align: center; float: left; width: 55%;\">";
			if($model[0]->bank_rdi_acct){
						if($model[0]->sum_b_amt > $model[0]->sum_j_amt){
							$tc = $tc."
								<font style=\"text-decoration: underline;\">Please transfer the fund to Investor Account (in good fund at 11:30 AM)</font><br />";	
						}
						if($model[0]->sum_j_amt > $model[0]->sum_b_amt){
							$tc = $tc."
								<font style=\"text-decoration: underline;\">We will transfer to your Investor Account</font><br />";
						}
						$tc = $tc.
						$model[0]->rdi_name."<br />
						".$model[0]->bank_rdi." : ".$model[0]->bank_rdi_acct;
			}else{
				$tc = $tc."
						<font style=\"text-decoration: underline;\">The following is our payment bank details</font><br />
						".$model[0]->nama_prsh."<br />
						".$model[0]->bank_name." A/C : ".$model[0]->brch_acct_num;
			}
			$tc = $tc."
				</div>
				<div style=\"text-align: center; float: right; width: 45%;\">";
			if($model[0]->bank_rdi_acct){	
						if($model[0]->sum_j_amt > $model[0]->sum_b_amt){
							$tc = $tc."
								<font style=\"text-decoration: underline;\">Your Bank Account</font><br />
								".$model[0]->client_bank_name."<br />
								".$model[0]->client_bank." A/C : ".$model[0]->client_bank_acct;
						}
			}
			$tc = $tc."
				</div>
			</div>
			<div style=\"clear: both; \"><br /></div>
			<div>
				<div style=\"float: left; width: 60%;\">
					Equity Sales,<br />
					".$model[0]->rem_name."<br />
					<br /><br />
					NPWP : ".$model[0]->no_ijin1."<br />
					PKP &emsp;: ".$model[0]->no_ijin1."<br /><br />
					This is a computer generated advise. No signature is required.
				</div>
				<div style=\"float: right; width: 40%;\">
					Confirmed by,<br />
					".$model[0]->nama_prsh."
				</div>
			</div>
			<div style=\"clear: both; \"></div>
			";
		}else{
			$tc = "
			<h1>".$client_cd." : Data Not Found!</h1>";
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
				<div style=\"float: left; width: 50%;\">
					<p><img src=\"".$baseurl."/images/yj.jpg\" width=\"220px\" ></p>
					".$model[0]->brch_addr_1."<br />".$model[0]->brch_addr_2."<br/>
					".$model[0]->brch_addr_3."<br/>
					Telp : ".$model[0]->brch_phone."&emsp;Fax : ".$model[0]->brch_fax."<br />
					<br />
					UP.&emsp;:&emsp;".$model[0]->contact_pers."<br />
					&emsp;&emsp;&nbsp;&nbsp;&nbsp;&emsp;".$model[0]->def_addr_1."<br />
					&emsp;&emsp;&nbsp;&nbsp;&nbsp;&emsp;".$model[0]->def_addr_2."<br />
					&emsp;&emsp;&nbsp;&nbsp;&nbsp;&emsp;".$model[0]->def_addr_3."<br />
					POS &nbsp;:&emsp;".$model[0]->post_cd."<br />
				</div>
				<div style=\"float: right; width: 50%;\">
					<div style=\"border: 1.5px solid;background: #ECE8D8; border-radius: 0.5em; padding: -4px;\">
						<div style=\"text-align: center; font-size: 24px; padding: 10px; font-weight: bold;\">
							Konfirmasi Transaksi
						</div>
						<div style=\"border-top: 1.5px solid; background: #ffffff; border-radius: 0.7em; text-align: center; padding: 5px 7px 7px 7px;\">
							Cabang ".$model[0]->brch_name."
						</div>
					</div>
					No. {tc_id}<br />
					".($model[0]->client_title? ucwords(strtolower($model[0]->client_title)).'. ' : '').$model[0]->client_name."<br />
					Tanggal &emsp;&emsp;&emsp; :&emsp;".DateTime::createFromFormat('Y-m-d h:i:s',$model[0]->contr_dt)->format('d/m/Y')."<br />
					Kode Nasabah :&emsp;".$model[0]->client_cd."<br />
					Telepon &emsp;&emsp;&nbsp;&nbsp;&nbsp; :&emsp;".(($model[0]->phone_num && (trim($model[0]->phone_num) != 'NA'))?$model[0]->phone_num : '').($model[0]->phone2_1?', '.$model[0]->phone2_1 : '').($model[0]->hand_phone1?', '.$model[0]->hand_phone1 : '')."<br />";
			if($model[0]->fax_num){
				$tc = $tc."Fax &emsp;&emsp;&emsp;&emsp;&emsp;&nbsp;&nbsp;:&emsp;".$model[0]->fax_num."<br />";}
			if($model[0]->e_mail1){
				$tc = $tc."<font style=\"color: blue\">via e-mail</font><br />
					E-mail &emsp;&emsp;&nbsp;&nbsp;&nbsp;&emsp; :&emsp;".$model[0]->e_mail1."<br />";}
			$tc = $tc."	
				</div>
			</div>
			<br style=\"clear: both;\" />
			<div>
					Sesuai instruksi, kami telah melakukan transaksi sebagai berikut :
					<table id=\"tc-table\" class=\"table-condensed\" style=\"border-collapse: collapse; border: none;\">
						<tr style=\"background: #ECE8D8;border: 1.5px solid;\">
							<td><strong>Saham</strong></td>
							<td><strong>L/F</strong></td>
							<td style=\"text-align: right;\"><strong>Lot</strong></td>
							<td style=\"text-align: right;\"><strong>Jumlah</strong></td>
							<td style=\"text-align: right;\"><strong>Harga</strong></td>
							<td colspan=\"2\" style=\"text-align: right;\"><strong>Transaksi Beli</strong></td>
							<td colspan=\"2\" style=\"text-align: right;\"><strong>Transaksi Jual</strong></td>
						</tr>
						";
			foreach ($model as $row){
				$tc = $tc."
								<tr>
									<td>".$row->stk_cd."</td>
									<td>".$row->status."</td>
									<td style=\"text-align: right;\">".number_format($row->lot_size,0,',','.')."</td>
									<td style=\"text-align: right;\">".number_format($row->qty,0,',','.')."</td>
									<td style=\"text-align: right;\">".number_format($row->price,2,',','.')."</td>
									<td style=\"width: 5%\"></td>
									<td style=\"text-align: right; width: 16%\">".number_format($row->b_val,0,',','.')."</td>
									<td style=\"width: 5%\"></td>
									<td style=\"text-align: right; width: 16%\">".number_format($row->j_val,0,',','.')."</td>
								</tr>";
			}
			$tc = $tc."
							<tr style=\"background: #ECE8D8;border: 1.5px solid;\">
								<td colspan=\"5\">Total Nilai Transaksi</td>
								<td style=\"text-align: right;\">Rp</td>
								<td style=\"text-align: right;\">".number_format($model[0]->sum_b_val,0,',','.')."</td>
								<td style=\"text-align: right;\">Rp</td>
								<td style=\"text-align: right;\">".number_format($model[0]->sum_j_val,0,',','.')."</td>
							</tr>
							<tr>
								<td colspan=\"5\">Komisi ".($model[0]->brok_perc/100)."%</td>
								<td style=\"text-align: right;\"></td>
								<td style=\"text-align: right;\">".number_format($model[0]->sum_b_comm,0,',','.')."</td>
								<td style=\"text-align: right;\"></td>
								<td style=\"text-align: right;\">".number_format($model[0]->sum_j_comm,0,',','.')."</td>
							</tr>
							<tr>
								<td colspan=\"5\">VAT</td>
								<td style=\"text-align: right;\"></td>
								<td style=\"text-align: right;\">".number_format($model[0]->sum_b_vat,0,',','.')."</td>
								<td style=\"text-align: right;\"></td>
								<td style=\"text-align: right;\">".number_format($model[0]->sum_j_vat,0,',','.')."</td>
							</tr>
							<tr>
								<td colspan=\"5\">Levy</td>
								<td style=\"text-align: right;\"></td>
								<td style=\"text-align: right;\">".number_format($model[0]->sum_b_levy,0,',','.')."</td>
								<td style=\"text-align: right;\"></td>
								<td style=\"text-align: right;\">".number_format($model[0]->sum_j_levy,0,',','.')."</td>
							</tr>";
			if ($model[0]->sum_j_pph != 0){
				$tc = $tc."
							<tr>
								<td colspan=\"5\">PPH ".($model[0]->pph_perc/100)."%</td>
								<td style=\"text-align: right;\"></td>
								<td style=\"text-align: right;\">".number_format($model[0]->sum_b_pph,0,',','.')."</td>
								<td style=\"text-align: right;\"></td>
								<td style=\"text-align: right;\">".number_format($model[0]->sum_j_pph,0,',','.')."</td>
							</tr>";
			}
			if (($model[0]->sum_b_whpph23 != 0) || ($model[0]->sum_j_whpph23 != 0)){
				$tc = $tc."
							<tr>
								<td colspan=\"5\">Uang Muka PPh 23 ".$model[0]->whpph23_perc."%</td>
								<td style=\"text-align: right;\"></td>
								<td style=\"text-align: right;\">".number_format($model[0]->sum_b_whpph23,0,',','.')."</td>
								<td style=\"text-align: right;\"></td>
								<td style=\"text-align: right;\">".number_format($model[0]->sum_j_whpph23,0,',','.')."</td>
							</tr>";
			}
			$tc = $tc."
							<tr style=\"background: #ECE8D8;border: 1.5px solid;\">
								<td colspan=\"5\">Nilai Net Transaksi</td>
								<td style=\"text-align: right;\">Rp</td>
								<td style=\"text-align: right;\">".number_format($model[0]->sum_b_amt,0,',','.')."</td>
								<td style=\"text-align: right;\">Rp</td>
								<td style=\"text-align: right;\">".number_format($model[0]->sum_j_amt,0,',','.')."</td>
							</tr>
							<tr><td colspan=\"9\"></td></tr>";
			if ($model[0]->sum_b_amt > $model[0]->sum_j_amt){
				$tc = $tc."
							<tr style=\"border-bottom: 1.5px solid;\">
								<td colspan=\"5\">Bayar</td>
								<td style=\"text-align: right;\">Rp</td>
								<td style=\"text-align: right;\">".number_format($model[0]->sum_b_amt - $model[0]->sum_j_amt,0,',','.')."</td>
								<td style=\"text-align: right;\">Rp</td>
								<td style=\"text-align: right;\">".'0'."</td>
							</tr>";	
			}else{
				$tc = $tc."
							<tr style=\"border-bottom: 1.5px solid;\">
								<td colspan=\"5\">Terima</td>
								<td style=\"text-align: right;\">Rp</td>
								<td style=\"text-align: right;\">".'0'."</td>
								<td style=\"text-align: right;\">Rp</td>
								<td style=\"text-align: right;\">".number_format($model[0]->sum_j_amt - $model[0]->sum_b_amt,0,',','.')."</td>
							</tr>";
			}
			if (($model[0]->sum_b_t3 + $model[0]->sum_j_t3) > 0){
				$tc = $tc."
							<tr>
								<td colspan=\"5\">Tanggal Jatuh Tempo T+".$model[0]->max_3plus."&emsp;".DateTime::createFromFormat('Y-m-d h:i:s',$model[0]->due_t3)->format('d/m/Y')." (".substr($model[0]->mrkt_t3,0,2).")</td>
								<td style=\"text-align: right;\">Rp</td>
								<td style=\"text-align: right;\">".(($model[0]->sum_b_t3 > $model[0]->sum_j_t3)?number_format($model[0]->sum_b_t3 - $model[0]->sum_j_t3,0,',','.') : '0')."</td>
								<td style=\"text-align: right;\">Rp</td>
								<td style=\"text-align: right;\">".(($model[0]->sum_j_t3 > $model[0]->sum_b_t3)?number_format($model[0]->sum_j_t3 - $model[0]->sum_b_t3,0,',','.') : '0')."</td>
							</tr>";
			}
			if (($model[0]->sum_b_t2 + $model[0]->sum_j_t2) > 0){
				$tc = $tc."
							<tr>
								<td colspan=\"5\">Tanggal Jatuh Tempo T+2&emsp;".DateTime::createFromFormat('Y-m-d h:i:s',$model[0]->due_t2)->format('d/m/Y')." (".substr($model[0]->mrkt_t2,0,2).")</td>
								<td style=\"text-align: right;\">Rp</td>
								<td style=\"text-align: right;\">".(($model[0]->sum_b_t2 > $model[0]->sum_j_t2)?number_format($model[0]->sum_b_t2 - $model[0]->sum_j_t2,0,',','.') : '0')."</td>
								<td style=\"text-align: right;\">Rp</td>
								<td style=\"text-align: right;\">".(($model[0]->sum_j_t2 > $model[0]->sum_b_t2)?number_format($model[0]->sum_j_t2 - $model[0]->sum_b_t2,0,',','.') : '0')."</td>
							</tr>";
			}
			if (($model[0]->sum_b_t1 + $model[0]->sum_j_t1) > 0){
				$tc = $tc."
							<tr>
								<td colspan=\"5\">Tanggal Jatuh Tempo T+1&emsp;".DateTime::createFromFormat('Y-m-d h:i:s',$model[0]->due_t1)->format('d/m/Y')." (".substr($model[0]->mrkt_t1,0,2).")</td>
								<td style=\"text-align: right;\">Rp</td>
								<td style=\"text-align: right;\">".(($model[0]->sum_b_t1 > $model[0]->sum_j_t1)?number_format($model[0]->sum_b_t1 - $model[0]->sum_j_t1,0,',','.') : '0')."</td>
								<td style=\"text-align: right;\">Rp</td>
								<td style=\"text-align: right;\">".(($model[0]->sum_j_t1 > $model[0]->sum_b_t1)?number_format($model[0]->sum_j_t1 - $model[0]->sum_b_t1,0,',','.') : '0')."</td>
							</tr>";
			}
			if (($model[0]->sum_b_t0 + $model[0]->sum_j_t0) > 0){
				$tc = $tc."
							<tr>
								<td colspan=\"5\">Tanggal Jatuh Tempo T+0&emsp;".DateTime::createFromFormat('Y-m-d h:i:s',$model[0]->contr_dt)->format('d/m/Y')." (".substr($model[0]->mrkt_t0,0,2).")</td>
								<td style=\"text-align: right;\">Rp</td>
								<td style=\"text-align: right;\">".(($model[0]->sum_b_t0 > $model[0]->sum_j_t0)?number_format($model[0]->sum_b_t0 - $model[0]->sum_j_t0,0,',','.') : '0')."</td>
								<td style=\"text-align: right;\">Rp</td>
								<td style=\"text-align: right;\">".(($model[0]->sum_j_t0 > $model[0]->sum_b_t0)?number_format($model[0]->sum_j_t0 - $model[0]->sum_b_t0,0,',','.') : '0')."</td>
							</tr>";
			}
			$tc = $tc."
							<tr style=\"border-top: 1.5px solid;\"><td colspan=\"9\"></td></tr>
						
					</table>
			</div>
			<div>
				
					Ketidak-cocokan dalam transaksi harus dilaporkan dalam kurun waktu 1 (satu) hari kerja setelah transaksi di atas,<br />
					atau kami akan menganggap informasi di atas adalah benar. Terima kasih atas perhatiannya.<br />
					<br />
					Khusus untuk nasabah ".$model[0]->bank_rdi." :<br />
					* Pembayaran terakhir untuk transaksi beli dari pelanggan pada
					".((($model[0]->sum_b_t3 + $model[0]->sum_j_t3) > 0)?'T+3 ('.substr($model[0]->mrkt_t3,0,2).')' : '').
					((($model[0]->sum_b_t2 + $model[0]->sum_j_t2) > 0)?'T+2 ('.substr($model[0]->mrkt_t2,0,2).')' : '').
					((($model[0]->sum_b_t1 + $model[0]->sum_j_t1) > 0)?'T+1 ('.substr($model[0]->mrkt_t1,0,2).')' : '').
					((($model[0]->sum_b_t0 + $model[0]->sum_j_t0) > 0)?'T+0 ('.substr($model[0]->mrkt_t0,0,2).')' : '')."
					jam 11.30 pagi (in good fund)<br />
					* Pembayaran terakhir untuk transaksi jual ke pelanggan pada
					".((($model[0]->sum_b_t3 + $model[0]->sum_j_t3) > 0)?'T+3 ('.substr($model[0]->mrkt_t3,0,2).')' : '').
					((($model[0]->sum_b_t2 + $model[0]->sum_j_t2) > 0)?'T+2 ('.substr($model[0]->mrkt_t2,0,2).')' : '').
					((($model[0]->sum_b_t1 + $model[0]->sum_j_t1) > 0)?'T+1 ('.substr($model[0]->mrkt_t1,0,2).')' : '').
					((($model[0]->sum_b_t0 + $model[0]->sum_j_t0) > 0)?'T+0 ('.substr($model[0]->mrkt_t0,0,2).')' : '')."
					jam 5 sore
				
			</div>
			<div style=\"clear: both; \"><br /></div>
			<div>
				<div style=\"text-align: center; float: left; width: 55%;\">";
			if($model[0]->bank_rdi_acct){
						if($model[0]->sum_b_amt > $model[0]->sum_j_amt){
							$tc = $tc."
								<font style=\"text-decoration: underline;\">Mohon mentransfer dana ke Rekening Dana nasabah<br />(efektif jam 11:30 pagi) :</font><br />";	
						}
						if($model[0]->sum_j_amt > $model[0]->sum_b_amt){
							$tc = $tc."
								<font style=\"text-decoration: underline;\">Kami akan mentransfer ke Rekening Dana anda :</font><br />";
						}
						$tc = $tc.
						$model[0]->rdi_name."<br />
						".$model[0]->bank_rdi." : ".$model[0]->bank_rdi_acct;
			}else{
				$tc = $tc."
						<font style=\"text-decoration: underline;\">Berikut ini adalah Rekening Bank kami :</font><br />
						".$model[0]->nama_prsh."<br />
						".$model[0]->bank_name." : ".$model[0]->brch_acct_num;
			}
			$tc = $tc."
				</div>
				<div style=\"text-align: center; float: right; width: 45%;\">";
			if($model[0]->bank_rdi_acct){	
						if($model[0]->sum_j_amt > $model[0]->sum_b_amt){
							$tc = $tc."
								<font style=\"text-decoration: underline;\">Rekening Bank anda :</font><br />
								".$model[0]->client_bank_name."<br />
								".$model[0]->client_bank." : ".$model[0]->client_bank_acct;
						}
			}
			$tc = $tc."
				</div>
			</div>
			<div style=\"clear: both; \"><br /></div>
			<div>
				<div style=\"float: left; width: 60%;\">
					Sales Ekuitas,<br />
					".$model[0]->rem_name."<br />
					<br /><br />
					NPWP : ".$model[0]->no_ijin1."<br />
					PKP &emsp;: ".$model[0]->no_ijin1."<br /><br />
					
				</div>
				<div style=\"float: right; width: 40%;\">
					Dikonfirmasi oleh,<br />
					".$model[0]->nama_prsh."
				</div>
			</div>
			<div style=\"clear: both; \">Dokumen ini dibuat berdasarkan sistem komputer. Tidak dibutuhkan penandatanganan.</div>
			";
		}else{
			$tc = "
			<h1>".$client_cd." : Data Tidak Ditemukan!</h1>";
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
				<div style=\"float: left; width: 50%;\">
					<h4>PT. LAUTANDHANA SECURINDO</h4>
					".$model[0]->brch_addr_1."<br />".$model[0]->brch_addr_2."<br/>
					".$model[0]->brch_addr_3."<br/>
					Telp : ".$model[0]->brch_phone."&emsp;Fax : ".$model[0]->brch_fax."<br />
					<br />
					UP.&emsp;:&emsp;".$model[0]->contact_pers."<br />
					&emsp;&emsp;&nbsp;&nbsp;&nbsp;&emsp;".$model[0]->def_addr_1."<br />
					&emsp;&emsp;&nbsp;&nbsp;&nbsp;&emsp;".$model[0]->def_addr_2."<br />
					&emsp;&emsp;&nbsp;&nbsp;&nbsp;&emsp;".$model[0]->def_addr_3."<br />
					POS &nbsp;:&emsp;".$model[0]->post_cd."<br />
				</div>
				<div style=\"float: right; width: 50%;\">
					<h4>KONFIRMASI TRANSAKSI</h4>
					<strong>Cabang ".$model[0]->brch_name."</strong><br />
					No. {tc_id}<br /><br />
					".($model[0]->client_title? ucwords(strtolower($model[0]->client_title)).'. ' : '').$model[0]->client_name."<br />
					Tanggal &emsp;&emsp;&emsp; :&emsp;".DateTime::createFromFormat('Y-m-d h:i:s',$model[0]->contr_dt)->format('d/m/Y')."<br />
					Kode Nasabah :&emsp;".$model[0]->client_cd."<br />
					Telepon &emsp;&emsp;&nbsp;&nbsp;&nbsp; :&emsp;".(($model[0]->phone_num && (trim($model[0]->phone_num) != 'NA'))?$model[0]->phone_num : '').($model[0]->phone2_1?', '.$model[0]->phone2_1 : '').($model[0]->hand_phone1?', '.$model[0]->hand_phone1 : '')."<br />";
			if($model[0]->fax_num){
				$tc = $tc."Fax &emsp;&emsp;&emsp;&emsp;&emsp;&nbsp;&nbsp;:&emsp;".$model[0]->fax_num."<br />";}
			if($model[0]->e_mail1){
				$tc = $tc."<font style=\"color: blue\">via e-mail</font><br />
					E-mail &emsp;&emsp;&nbsp;&nbsp;&nbsp;&emsp; :&emsp;".$model[0]->e_mail1."<br />";}
			$tc = $tc."	
				</div>
			</div>
			<br style=\"clear: both;\" />
			<div>
					Sesuai instruksi, kami telah melakukan transaksi sebagai berikut :
					<table id=\"tc-table\" class=\"table-condensed\" style=\"border-collapse: collapse; border: none;\">
						<tr style=\"border-top: 1.5px solid;border-bottom: 1.5px solid;\">
							<td><strong>Saham</strong></td>
							<td><strong>L/F</strong></td>
							<td style=\"text-align: right;\"><strong>Lot</strong></td>
							<td style=\"text-align: right;\"><strong>Jumlah</strong></td>
							<td style=\"text-align: right;\"><strong>Harga</strong></td>
							<td colspan=\"2\" style=\"text-align: right;\"><strong>Transaksi Beli</strong></td>
							<td colspan=\"2\" style=\"text-align: right;\"><strong>Transaksi Jual</strong></td>
						</tr>
						";
			foreach ($model as $row){
				$tc = $tc."
								<tr>
									<td>".$row->stk_cd."</td>
									<td>".$row->status."</td>
									<td style=\"text-align: right;\">".number_format($row->lot_size,0,',','.')."</td>
									<td style=\"text-align: right;\">".number_format($row->qty,0,',','.')."</td>
									<td style=\"text-align: right;\">".number_format($row->price,2,',','.')."</td>
									<td style=\"width: 5%\"></td>
									<td style=\"text-align: right; width: 16%\">".number_format($row->b_val,0,',','.')."</td>
									<td style=\"width: 5%\"></td>
									<td style=\"text-align: right; width: 16%\">".number_format($row->j_val,0,',','.')."</td>
								</tr>";
			}
			$tc = $tc."
							<tr style=\"border-top: 1.5px solid;border-bottom: 1.5px solid;\">
								<td colspan=\"5\">Total Nilai Transaksi</td>
								<td style=\"text-align: right;\">Rp</td>
								<td style=\"text-align: right;\">".number_format($model[0]->sum_b_val,0,',','.')."</td>
								<td style=\"text-align: right;\">Rp</td>
								<td style=\"text-align: right;\">".number_format($model[0]->sum_j_val,0,',','.')."</td>
							</tr>
							<tr>
								<td colspan=\"5\">Komisi ".($model[0]->brok_perc/100)."%</td>
								<td style=\"text-align: right;\"></td>
								<td style=\"text-align: right;\">".number_format($model[0]->sum_b_comm,0,',','.')."</td>
								<td style=\"text-align: right;\"></td>
								<td style=\"text-align: right;\">".number_format($model[0]->sum_j_comm,0,',','.')."</td>
							</tr>
							<tr>
								<td colspan=\"5\">VAT</td>
								<td style=\"text-align: right;\"></td>
								<td style=\"text-align: right;\">".number_format($model[0]->sum_b_vat,0,',','.')."</td>
								<td style=\"text-align: right;\"></td>
								<td style=\"text-align: right;\">".number_format($model[0]->sum_j_vat,0,',','.')."</td>
							</tr>
							<tr>
								<td colspan=\"5\">Levy</td>
								<td style=\"text-align: right;\"></td>
								<td style=\"text-align: right;\">".number_format($model[0]->sum_b_levy,0,',','.')."</td>
								<td style=\"text-align: right;\"></td>
								<td style=\"text-align: right;\">".number_format($model[0]->sum_j_levy,0,',','.')."</td>
							</tr>";
			if ($model[0]->sum_j_pph != 0){
				$tc = $tc."
							<tr>
								<td colspan=\"5\">PPH ".($model[0]->pph_perc/100)."%</td>
								<td style=\"text-align: right;\"></td>
								<td style=\"text-align: right;\">".number_format($model[0]->sum_b_pph,0,',','.')."</td>
								<td style=\"text-align: right;\"></td>
								<td style=\"text-align: right;\">".number_format($model[0]->sum_j_pph,0,',','.')."</td>
							</tr>";
			}
			if (($model[0]->sum_b_whpph23 != 0) || ($model[0]->sum_j_whpph23 != 0)){
				$tc = $tc."
							<tr>
								<td colspan=\"5\">Uang Muka PPh 23 ".$model[0]->whpph23_perc."%</td>
								<td style=\"text-align: right;\"></td>
								<td style=\"text-align: right;\">".number_format($model[0]->sum_b_whpph23,0,',','.')."</td>
								<td style=\"text-align: right;\"></td>
								<td style=\"text-align: right;\">".number_format($model[0]->sum_j_whpph23,0,',','.')."</td>
							</tr>";
			}
			$tc = $tc."
							<tr style=\"border-top: 1.5px solid;border-bottom: 1.5px solid;\">
								<td colspan=\"5\">Nilai Net Transaksi</td>
								<td style=\"text-align: right;\">Rp</td>
								<td style=\"text-align: right;\">".number_format($model[0]->sum_b_amt,0,',','.')."</td>
								<td style=\"text-align: right;\">Rp</td>
								<td style=\"text-align: right;\">".number_format($model[0]->sum_j_amt,0,',','.')."</td>
							</tr>
							<tr><td colspan=\"9\"></td></tr>";
			if ($model[0]->sum_b_amt > $model[0]->sum_j_amt){
				$tc = $tc."
							<tr style=\"border-bottom: 1.5px solid;\">
								<td colspan=\"5\">Bayar</td>
								<td style=\"text-align: right;\">Rp</td>
								<td style=\"text-align: right;\">".number_format($model[0]->sum_b_amt - $model[0]->sum_j_amt,0,',','.')."</td>
								<td style=\"text-align: right;\">Rp</td>
								<td style=\"text-align: right;\">".'0'."</td>
							</tr>";	
			}else{
				$tc = $tc."
							<tr style=\"border-bottom: 1.5px solid;\">
								<td colspan=\"5\">Terima</td>
								<td style=\"text-align: right;\">Rp</td>
								<td style=\"text-align: right;\">".'0'."</td>
								<td style=\"text-align: right;\">Rp</td>
								<td style=\"text-align: right;\">".number_format($model[0]->sum_j_amt - $model[0]->sum_b_amt,0,',','.')."</td>
							</tr>";
			}
			if (($model[0]->sum_b_t3 + $model[0]->sum_j_t3) > 0){
				$tc = $tc."
							<tr>
								<td colspan=\"5\">Tanggal Jatuh Tempo T+".$model[0]->max_3plus."&emsp;".DateTime::createFromFormat('Y-m-d h:i:s',$model[0]->due_t3)->format('d/m/Y')." (".substr($model[0]->mrkt_t3,0,2).")</td>
								<td style=\"text-align: right;\">Rp</td>
								<td style=\"text-align: right;\">".(($model[0]->sum_b_t3 > $model[0]->sum_j_t3)?number_format($model[0]->sum_b_t3 - $model[0]->sum_j_t3,0,',','.') : '0')."</td>
								<td style=\"text-align: right;\">Rp</td>
								<td style=\"text-align: right;\">".(($model[0]->sum_j_t3 > $model[0]->sum_b_t3)?number_format($model[0]->sum_j_t3 - $model[0]->sum_b_t3,0,',','.') : '0')."</td>
							</tr>";
			}
			if (($model[0]->sum_b_t2 + $model[0]->sum_j_t2) > 0){
				$tc = $tc."
							<tr>
								<td colspan=\"5\">Tanggal Jatuh Tempo T+2&emsp;".DateTime::createFromFormat('Y-m-d h:i:s',$model[0]->due_t2)->format('d/m/Y')." (".substr($model[0]->mrkt_t2,0,2).")</td>
								<td style=\"text-align: right;\">Rp</td>
								<td style=\"text-align: right;\">".(($model[0]->sum_b_t2 > $model[0]->sum_j_t2)?number_format($model[0]->sum_b_t2 - $model[0]->sum_j_t2,0,',','.') : '0')."</td>
								<td style=\"text-align: right;\">Rp</td>
								<td style=\"text-align: right;\">".(($model[0]->sum_j_t2 > $model[0]->sum_b_t2)?number_format($model[0]->sum_j_t2 - $model[0]->sum_b_t2,0,',','.') : '0')."</td>
							</tr>";
			}
			if (($model[0]->sum_b_t1 + $model[0]->sum_j_t1) > 0){
				$tc = $tc."
							<tr>
								<td colspan=\"5\">Tanggal Jatuh Tempo T+1&emsp;".DateTime::createFromFormat('Y-m-d h:i:s',$model[0]->due_t1)->format('d/m/Y')." (".substr($model[0]->mrkt_t1,0,2).")</td>
								<td style=\"text-align: right;\">Rp</td>
								<td style=\"text-align: right;\">".(($model[0]->sum_b_t1 > $model[0]->sum_j_t1)?number_format($model[0]->sum_b_t1 - $model[0]->sum_j_t1,0,',','.') : '0')."</td>
								<td style=\"text-align: right;\">Rp</td>
								<td style=\"text-align: right;\">".(($model[0]->sum_j_t1 > $model[0]->sum_b_t1)?number_format($model[0]->sum_j_t1 - $model[0]->sum_b_t1,0,',','.') : '0')."</td>
							</tr>";
			}
			if (($model[0]->sum_b_t0 + $model[0]->sum_j_t0) > 0){
				$tc = $tc."
							<tr>
								<td colspan=\"5\">Tanggal Jatuh Tempo T+0&emsp;".DateTime::createFromFormat('Y-m-d h:i:s',$model[0]->contr_dt)->format('d/m/Y')." (".substr($model[0]->mrkt_t0,0,2).")</td>
								<td style=\"text-align: right;\">Rp</td>
								<td style=\"text-align: right;\">".(($model[0]->sum_b_t0 > $model[0]->sum_j_t0)?number_format($model[0]->sum_b_t0 - $model[0]->sum_j_t0,0,',','.') : '0')."</td>
								<td style=\"text-align: right;\">Rp</td>
								<td style=\"text-align: right;\">".(($model[0]->sum_j_t0 > $model[0]->sum_b_t0)?number_format($model[0]->sum_j_t0 - $model[0]->sum_b_t0,0,',','.') : '0')."</td>
							</tr>";
			}
			$tc = $tc."
							<tr style=\"border-top: 1.5px solid;\"><td colspan=\"9\"></td></tr>
						
					</table>
			</div>
			<div>
				
					Ketidak-cocokan dalam transaksi harus dilaporkan dalam kurun waktu 1 (satu) hari kerja setelah transaksi di atas,<br />
					atau kami akan menganggap informasi di atas adalah benar. Terima kasih atas perhatiannya.<br />
					<br />
					Khusus untuk nasabah ".$model[0]->bank_rdi." :<br />
					* Pembayaran terakhir untuk transaksi beli dari pelanggan pada
					".((($model[0]->sum_b_t3 + $model[0]->sum_j_t3) > 0)?'T+3 ('.substr($model[0]->mrkt_t3,0,2).')' : '').
					((($model[0]->sum_b_t2 + $model[0]->sum_j_t2) > 0)?'T+2 ('.substr($model[0]->mrkt_t2,0,2).')' : '').
					((($model[0]->sum_b_t1 + $model[0]->sum_j_t1) > 0)?'T+1 ('.substr($model[0]->mrkt_t1,0,2).')' : '').
					((($model[0]->sum_b_t0 + $model[0]->sum_j_t0) > 0)?'T+0 ('.substr($model[0]->mrkt_t0,0,2).')' : '')."
					jam 11.30 pagi (in good fund)<br />
					* Pembayaran terakhir untuk transaksi jual ke pelanggan pada
					".((($model[0]->sum_b_t3 + $model[0]->sum_j_t3) > 0)?'T+3 ('.substr($model[0]->mrkt_t3,0,2).')' : '').
					((($model[0]->sum_b_t2 + $model[0]->sum_j_t2) > 0)?'T+2 ('.substr($model[0]->mrkt_t2,0,2).')' : '').
					((($model[0]->sum_b_t1 + $model[0]->sum_j_t1) > 0)?'T+1 ('.substr($model[0]->mrkt_t1,0,2).')' : '').
					((($model[0]->sum_b_t0 + $model[0]->sum_j_t0) > 0)?'T+0 ('.substr($model[0]->mrkt_t0,0,2).')' : '')."
					jam 5 sore
				
			</div>
			<div style=\"clear: both; \"><br /></div>
			<div>
				<div style=\"text-align: center; float: left; width: 55%;\">";
			if($model[0]->bank_rdi_acct){
						if($model[0]->sum_b_amt > $model[0]->sum_j_amt){
							$tc = $tc."
								<font style=\"text-decoration: underline;\">Mohon mentransfer dana ke Rekening Dana nasabah<br />(efektif jam 11:30 pagi) :</font><br />";	
						}
						if($model[0]->sum_j_amt > $model[0]->sum_b_amt){
							$tc = $tc."
								<font style=\"text-decoration: underline;\">Kami akan mentransfer ke Rekening Dana anda :</font><br />";
						}
						$tc = $tc.
						$model[0]->rdi_name."<br />
						".$model[0]->bank_rdi." : ".$model[0]->bank_rdi_acct;
			}else{
				$tc = $tc."
						<font style=\"text-decoration: underline;\">Berikut ini adalah Rekening Bank kami :</font><br />
						".$model[0]->nama_prsh."<br />
						".$model[0]->bank_name." : ".$model[0]->brch_acct_num;
			}
			$tc = $tc."
				</div>
				<div style=\"text-align: center; float: right; width: 45%;\">";
			if($model[0]->bank_rdi_acct){	
						if($model[0]->sum_j_amt > $model[0]->sum_b_amt){
							$tc = $tc."
								<font style=\"text-decoration: underline;\">Rekening Bank anda :</font><br />
								".$model[0]->client_bank_name."<br />
								".$model[0]->client_bank." : ".$model[0]->client_bank_acct;
						}
			}
			$tc = $tc."
				</div>
			</div>
			<div style=\"clear: both; \"><br /></div>
			<div>
				<div style=\"float: left; width: 60%;\">
					Sales Ekuitas,<br />
					".$model[0]->rem_name."<br />
					<br /><br />
					NPWP : ".$model[0]->no_ijin1."<br />
					PKP &emsp;: ".$model[0]->no_ijin1."<br /><br />
					
				</div>
				<div style=\"float: right; width: 40%;\">
					Dikonfirmasi oleh,<br />
					".$model[0]->nama_prsh."
				</div>
			</div>
			<div style=\"clear: both; \">Dokumen ini dibuat berdasarkan sistem komputer. Tidak dibutuhkan penandatanganan.</div>
			";
		}else{
			$tc = "
			<h1>".$client_cd." : Data Tidak Ditemukan!</h1>";
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
		$model= Rtradeconf::model()->findAll(array('condition'=>"client_cd = 'ABID001R' and userid = 'AS'"));
		$model2 = Rtradeconf::model()->findAll(array('condition'=>"client_cd = 'ABID001R' and userid = 'AS'"));
		$baseurl = Yii::app()->request->baseUrl;
		if($model){
			$tc = "
			<div>
				<div style=\"float: left; width: 50%;\">
					<h4>PT. LAUTANDHANA SECURINDO</h4>
					".$model[0]->brch_addr_1."<br />".$model[0]->brch_addr_2."<br/>
					".$model[0]->brch_addr_3."<br/>
					Phone : ".$model[0]->brch_phone."&emsp;Fax : ".$model[0]->brch_fax."<br />
					<br />
					ATT :&emsp;".$model[0]->contact_pers."<br />
					&emsp;&emsp;&nbsp;&nbsp;&emsp;".$model[0]->def_addr_1."<br />
					&emsp;&emsp;&nbsp;&nbsp;&emsp;".$model[0]->def_addr_2."<br />
					&emsp;&emsp;&nbsp;&nbsp;&emsp;".$model[0]->def_addr_3."<br />
					ZIP &nbsp;:&emsp;".$model[0]->post_cd."<br />
				</div>
				<div style=\"float: right; width: 50%;\">
					<h4>TRADE CONFIRMATION</h4>
					".$model[0]->brch_name." Branch<br />
					No. {tc_id}<br /><br />
					".($model[0]->client_title? ucwords(strtolower($model[0]->client_title)).'. ' : '').$model[0]->client_name."<br />
					Date &emsp;&emsp;&emsp; :&emsp;".DateTime::createFromFormat('Y-m-d h:i:s',$model[0]->contr_dt)->format('d/m/Y')."<br />
					Client Code :&emsp;".$model[0]->client_cd."<br />
					Phone &emsp;&emsp;&nbsp;&nbsp;:&emsp;".(($model[0]->phone_num && (trim($model[0]->phone_num) != 'NA'))?$model[0]->phone_num : '').($model[0]->phone2_1?', '.$model[0]->phone2_1 : '').($model[0]->hand_phone1?', '.$model[0]->hand_phone1 : '')."<br />";
			if($model[0]->fax_num){
				$tc = $tc."Fax &emsp;&emsp;&emsp;&nbsp;&nbsp; :&emsp;".$model[0]->fax_num."<br />";}
			if($model[0]->e_mail1){
				$tc = $tc."
					E-mail &emsp;&emsp;&nbsp;&nbsp;:&emsp;".$model[0]->e_mail1."<br />";}
			$tc = $tc."	
				</div>
			</div>
			<br style=\"clear: both;\" />
			<div>
					As instructed, we have executed the following transaction(s) for your account:
					<table id=\"tc-table\" class=\"table-condensed\" style=\"border-collapse: collapse; border: none;\">
						<tr style=\"border-top: 1.5px solid;border-bottom: 1.5px solid;\">
							<td><strong>Share</strong></td>
							<td><strong>L/F</strong></td>
							<td style=\"text-align: right;\"><strong>Lot</strong></td>
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
									<td>".$row->status."</td>
									<td style=\"text-align: right;\">".number_format($row->lot_size)."</td>
									<td style=\"text-align: right;\">".number_format($row->qty)."</td>
									<td style=\"text-align: right;\">".number_format($row->price)."</td>
									<td style=\"width: 5%\"></td>
									<td style=\"text-align: right; width: 16%\">".number_format($row->b_val)."</td>
									<td style=\"width: 5%\"></td>
									<td style=\"text-align: right; width: 16%\">".number_format($row->j_val)."</td>
								</tr>";
			}
			$tc = $tc."
							<tr style=\"border-top: 1.5px solid;border-bottom: 1.5px solid;\">
								<td colspan=\"5\">Total Value</td>
								<td style=\"text-align: right;\">Rp</td>
								<td style=\"text-align: right;\">".number_format($model[0]->sum_b_val)."</td>
								<td style=\"text-align: right;\">Rp</td>
								<td style=\"text-align: right;\">".number_format($model[0]->sum_j_val)."</td>
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
								<td colspan=\"5\">Debt</td>
								<td style=\"text-align: right;\">Rp</td>
								<td style=\"text-align: right;\">".number_format($model[0]->sum_b_amt - $model[0]->sum_j_amt)."</td>
								<td style=\"text-align: right;\">Rp</td>
								<td style=\"text-align: right;\">".'0'."</td>
							</tr>";	
			}else{
				$tc = $tc."
							<tr style=\"border-bottom: 1.5px solid;\">
								<td colspan=\"5\">Credit</td>
								<td style=\"text-align: right;\">Rp</td>
								<td style=\"text-align: right;\">".'0'."</td>
								<td style=\"text-align: right;\">Rp</td>
								<td style=\"text-align: right;\">".number_format($model[0]->sum_j_amt - $model[0]->sum_b_amt)."</td>
							</tr>";
			}
			if (($model[0]->sum_b_t3 + $model[0]->sum_j_t3) > 0){
				$tc = $tc."
							<tr>
								<td colspan=\"5\">Settlement Date T+".$model[0]->max_3plus."&emsp;".DateTime::createFromFormat('Y-m-d h:i:s',$model[0]->due_t3)->format('d/m/Y')." (".substr($model[0]->mrkt_t3,0,2).")</td>
								<td style=\"text-align: right;\">Rp</td>
								<td style=\"text-align: right;\">".(($model[0]->sum_b_t3 > $model[0]->sum_j_t3)?number_format($model[0]->sum_b_t3 - $model[0]->sum_j_t3) : '0')."</td>
								<td style=\"text-align: right;\">Rp</td>
								<td style=\"text-align: right;\">".(($model[0]->sum_j_t3 > $model[0]->sum_b_t3)?number_format($model[0]->sum_j_t3 - $model[0]->sum_b_t3) : '0')."</td>
							</tr>";
			}
			if (($model[0]->sum_b_t2 + $model[0]->sum_j_t2) > 0){
				$tc = $tc."
							<tr>
								<td colspan=\"5\">Settlement Date T+2&emsp;".DateTime::createFromFormat('Y-m-d h:i:s',$model[0]->due_t2)->format('d/m/Y')." (".substr($model[0]->mrkt_t2,0,2).")</td>
								<td style=\"text-align: right;\">Rp</td>
								<td style=\"text-align: right;\">".(($model[0]->sum_b_t2 > $model[0]->sum_j_t2)?number_format($model[0]->sum_b_t2 - $model[0]->sum_j_t2) : '0')."</td>
								<td style=\"text-align: right;\">Rp</td>
								<td style=\"text-align: right;\">".(($model[0]->sum_j_t2 > $model[0]->sum_b_t2)?number_format($model[0]->sum_j_t2 - $model[0]->sum_b_t2) : '0')."</td>
							</tr>";
			}
			if (($model[0]->sum_b_t1 + $model[0]->sum_j_t1) > 0){
				$tc = $tc."
							<tr>
								<td colspan=\"5\">Settlement Date T+1&emsp;".DateTime::createFromFormat('Y-m-d h:i:s',$model[0]->due_t1)->format('d/m/Y')." (".substr($model[0]->mrkt_t1,0,2).")</td>
								<td style=\"text-align: right;\">Rp</td>
								<td style=\"text-align: right;\">".(($model[0]->sum_b_t1 > $model[0]->sum_j_t1)?number_format($model[0]->sum_b_t1 - $model[0]->sum_j_t1) : '0')."</td>
								<td style=\"text-align: right;\">Rp</td>
								<td style=\"text-align: right;\">".(($model[0]->sum_j_t1 > $model[0]->sum_b_t1)?number_format($model[0]->sum_j_t1 - $model[0]->sum_b_t1) : '0')."</td>
							</tr>";
			}
			if (($model[0]->sum_b_t0 + $model[0]->sum_j_t0) > 0){
				$tc = $tc."
							<tr>
								<td colspan=\"5\">Settlement Date T+0&emsp;".DateTime::createFromFormat('Y-m-d h:i:s',$model[0]->contr_dt)->format('d/m/Y')." (".substr($model[0]->mrkt_t0,0,2).")</td>
								<td style=\"text-align: right;\">Rp</td>
								<td style=\"text-align: right;\">".(($model[0]->sum_b_t0 > $model[0]->sum_j_t0)?number_format($model[0]->sum_b_t0 - $model[0]->sum_j_t0) : '0')."</td>
								<td style=\"text-align: right;\">Rp</td>
								<td style=\"text-align: right;\">".(($model[0]->sum_j_t0 > $model[0]->sum_b_t0)?number_format($model[0]->sum_j_t0 - $model[0]->sum_b_t0) : '0')."</td>
							</tr>";
			}
			$tc = $tc."
							<tr style=\"border-top: 1.5px solid;\"><td colspan=\"9\"></td></tr>
						
					</table>
			</div>
			<div>
				
					Any discrepancy should be reported within 1 (one) business day after the above transaction date,<br />
					or we will consider the above information correct. Thank you for your attention.<br />
					<br />
					Especially for customer's account at ".$model[0]->bank_rdi." :<br />
					* The latest payment of buying transaction from customer on
					".((($model[0]->sum_b_t3 + $model[0]->sum_j_t3) > 0)?'T+3 ('.substr($model[0]->mrkt_t3,0,2).')' : '').
					((($model[0]->sum_b_t2 + $model[0]->sum_j_t2) > 0)?'T+2 ('.substr($model[0]->mrkt_t2,0,2).')' : '').
					((($model[0]->sum_b_t1 + $model[0]->sum_j_t1) > 0)?'T+1 ('.substr($model[0]->mrkt_t1,0,2).')' : '').
					((($model[0]->sum_b_t0 + $model[0]->sum_j_t0) > 0)?'T+0 ('.substr($model[0]->mrkt_t0,0,2).')' : '')."
					at 11.30 am (in good fund)<br />
					* The latest payment of selling transaction to customer on
					".((($model[0]->sum_b_t3 + $model[0]->sum_j_t3) > 0)?'T+3 ('.substr($model[0]->mrkt_t3,0,2).')' : '').
					((($model[0]->sum_b_t2 + $model[0]->sum_j_t2) > 0)?'T+2 ('.substr($model[0]->mrkt_t2,0,2).')' : '').
					((($model[0]->sum_b_t1 + $model[0]->sum_j_t1) > 0)?'T+1 ('.substr($model[0]->mrkt_t1,0,2).')' : '').
					((($model[0]->sum_b_t0 + $model[0]->sum_j_t0) > 0)?'T+0 ('.substr($model[0]->mrkt_t0,0,2).')' : '')."
					at 5 pm
				
			</div>
			<div style=\"clear: both; \"><br /></div>
			<div>
				<div style=\"text-align: center; float: left; width: 55%;\">";
			if($model[0]->bank_rdi_acct){
						if($model[0]->sum_b_amt > $model[0]->sum_j_amt){
							$tc = $tc."
								<font style=\"text-decoration: underline;\">Please transfer the fund to Investor Account (in good fund at 11:30 AM)</font><br />";	
						}
						if($model[0]->sum_j_amt > $model[0]->sum_b_amt){
							$tc = $tc."
								<font style=\"text-decoration: underline;\">We will transfer to your Investor Account</font><br />";
						}
						$tc = $tc.
						$model[0]->rdi_name."<br />
						".$model[0]->bank_rdi." : ".$model[0]->bank_rdi_acct;
			}else{
				$tc = $tc."
						<font style=\"text-decoration: underline;\">The following is our payment bank details</font><br />
						".$model[0]->nama_prsh."<br />
						".$model[0]->bank_name." A/C : ".$model[0]->brch_acct_num;
			}
			$tc = $tc."
				</div>
				<div style=\"text-align: center; float: right; width: 45%;\">";
			if($model[0]->bank_rdi_acct){	
						if($model[0]->sum_j_amt > $model[0]->sum_b_amt){
							$tc = $tc."
								<font style=\"text-decoration: underline;\">Your Bank Account</font><br />
								".$model[0]->client_bank_name."<br />
								".$model[0]->client_bank." A/C : ".$model[0]->client_bank_acct;
						}
			}
			$tc = $tc."
				</div>
			</div>
			<div style=\"clear: both; \"><br /></div>
			<div>
				<div style=\"float: left; width: 60%;\">
					Equity Sales,<br />
					".$model[0]->rem_name."<br />
					<br /><br />
					NPWP : ".$model[0]->no_ijin1."<br />
					PKP &emsp;: ".$model[0]->no_ijin1."<br /><br />
					This is a computer generated advise. No signature is required.
				</div>
				<div style=\"float: right; width: 40%;\">
					Confirmed by,<br />
					".$model[0]->nama_prsh."
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